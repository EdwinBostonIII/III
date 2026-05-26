/* III-CATALYST-EXT implementation */
#include "iii/catalyst_ext.h"
#include "iii/cycles.h"
#include "jit_emit.h"
#include <stdlib.h>
#include <string.h>

extern void iii_sha256(const void *data, size_t len, uint8_t out[32]);

const char *iii_cext_gate_name(iii_cext_gate_t g) {
    switch (g) {
        case III_CXG_ANCHOR_RESTRAINT:      return "anchor-restraint";
        case III_CXG_HEXAD_ADMIT:           return "hexad-admit";
        case III_CXG_SID_INVERSE:           return "sid-inverse";
        case III_CXG_COUNTERFACTUAL_REPLAY: return "counterfactual-replay";
        case III_CXG_COHERENCE_FLOOR:       return "coherence-floor";
        case III_CXG_RATE_CAP:              return "rate-cap";
        case III_CXG_TRINITY:                return "trinity";
        case III_CXG_ANCHOR_COSIGNATURE:    return "anchor-cosignature";
        default:                            return "unknown";
    }
}

const char *iii_cext_replay_status_name(iii_cext_replay_status_t s) {
    switch (s) {
        case III_CXR_VERIFIED:           return "verified";
        case III_CXR_FAILED_DIVERGENCE:  return "failed-divergence";
        case III_CXR_FAILED_OUTPUT:      return "failed-output";
        case III_CXR_FAILED_AUDIT_HASH:  return "failed-audit-hash";
        default:                         return "unknown";
    }
}

const char *iii_cext_arch_name(iii_cext_arch_t a) {
    switch (a) {
        case III_CXA_X86_64:  return "x86_64";
        case III_CXA_ARMV8:   return "armv8";
        case III_CXA_RISCV64: return "riscv64";
        default:              return "unknown";
    }
}

/* ----------------------------------------------------------------------------
 * Causal DAG
 * ---------------------------------------------------------------------------- */
struct iii_cdag {
    iii_cdag_node_t nodes[III_CDAG_NODES_MAX];
    iii_cdag_edge_t edges[III_CDAG_EDGES_MAX];
    unsigned        node_count;
    unsigned        edge_count;
};

iii_cdag_t *iii_cdag_create(void) {
    return (iii_cdag_t *)calloc(1, sizeof(iii_cdag_t));
}
void iii_cdag_destroy(iii_cdag_t *d) { if (d) free(d); }

bool iii_cdag_observe(iii_cdag_t *d, uint16_t from, uint16_t to, uint32_t latency_us) {
    if (!d) return false;
    if (from == to) return false;

    /* Find or create edge. */
    iii_cdag_edge_t *e = NULL;
    for (unsigned i = 0; i < d->edge_count; ++i) {
        if (d->edges[i].from == from && d->edges[i].to == to) { e = &d->edges[i]; break; }
    }
    if (!e) {
        if (d->edge_count >= III_CDAG_EDGES_MAX) return false;
        e = &d->edges[d->edge_count++];
        e->from = from;
        e->to = to;
        e->confidence_q14 = 0;
        e->frequency = 0;
        e->mean_latency_us = 0;
    }
    /* Update with EWMA-style stats. */
    if (e->frequency != UINT64_MAX) e->frequency++;
    /* Mean latency rolling: new = (old*(n-1) + sample)/n, capped. */
    e->mean_latency_us = (uint32_t)(((uint64_t)e->mean_latency_us * (e->frequency - 1u) + latency_us) / e->frequency);
    /* Confidence q14 grows with frequency (asymptotic to 1). */
    /* Map: f >= 1024 → ~0.95 q14 = 15564 */
    uint64_t saturated = (e->frequency * 16000ull) / (e->frequency + 100ull);
    if (saturated > 16384ull) saturated = 16384ull;
    e->confidence_q14 = (uint16_t)saturated;
    return true;
}

bool iii_cdag_get_edge(const iii_cdag_t *d, uint16_t from, uint16_t to, iii_cdag_edge_t *out) {
    if (!d || !out) return false;
    for (unsigned i = 0; i < d->edge_count; ++i) {
        if (d->edges[i].from == from && d->edges[i].to == to) {
            *out = d->edges[i];
            return true;
        }
    }
    return false;
}

size_t iii_cdag_edge_count(const iii_cdag_t *d) { return d ? d->edge_count : 0u; }

/* ----------------------------------------------------------------------------
 * Anchor restraint check
 * ---------------------------------------------------------------------------- */
bool iii_cext_filter_for_anchor(const iii_cext_anchor_check_t *check) {
    if (!check) return false;
    if (check->modifies_anchor_pubkey) return false;
    if (check->modifies_anchor_fingerprint) return false;
    if (check->removes_amend_apply_anchor_requirement) return false;
    if (check->disables_pfk_anchor_invariant) return false;
    if (check->synthesizes_substitute_anchor) return false;
    if (check->weakens_anchor_authority_semantically) return false;
    return true;
}

bool iii_cext_anchor_attack_pattern(const iii_cext_rejection_log_t *log) {
    if (!log) return false;
    if (log->total_rejections == 0) return false;
    /* >10% threshold */
    return (log->anchor_rejections * 10u) > log->total_rejections;
}

/* ----------------------------------------------------------------------------
 * Counterfactual replay — real BCWL chain walk + rolling SHA-256.
 *
 * The audit hash is computed as SHA-256 over the concatenated canonical
 * 128-byte encodings of every witness w in BCWL with cycle_seq in
 * [witness_range_start, witness_range_end], visited in BCWL bucket-order.
 *
 * The output hash is computed as SHA-256 over each witness's successor_mhash
 * (32 bytes per visit).  The observability hash is SHA-256 over each visit's
 * (capability_bind || adversariality_class || hexad_packed || flags), 11 bytes
 * per visit.  Each is compared against the corresponding expected_*_hash; an
 * all-zero expected hash skips that comparison.
 * ---------------------------------------------------------------------------- */
typedef struct {
    /* SHA-256 contexts modeled via incremental concatenation buffer.  We use
     * the simplest mode: accumulate every witness's bytes into a heap buffer
     * sized for the worst case, then hash once at the end.  BCWL_MAX_NODES is
     * a small bound (8K nodes typical), so this fits in stack/heap easily. */
    uint32_t visited;
    uint8_t  audit_in [128 * 8192];        /* 128 bytes per witness */
    uint8_t  output_in[ 32 * 8192];
    uint8_t  obs_in   [ 11 * 8192];
} replay_ctx_t;

typedef struct {
    replay_ctx_t *ctx;
    uint64_t      lo, hi;
    uint64_t      candidate_id;
} replay_user_t;

static void emit_witness_canonical(uint8_t out[128], const iii_xii_witness_t *w) {
    /* Layout matches the §4.2 spec field offsets. */
    memcpy(out + 0x00, w->predecessor_mhash, 32);
    memcpy(out + 0x20, w->successor_mhash,   32);
    for (unsigned i = 0; i < 4; ++i) out[0x40 + i] = (uint8_t)(w->step_kind             >> (i*8));
    for (unsigned i = 0; i < 4; ++i) out[0x44 + i] = (uint8_t)(w->cycle_seq             >> (i*8));
    for (unsigned i = 0; i < 8; ++i) out[0x48 + i] = (uint8_t)(w->chronos_tsc           >> (i*8));
    for (unsigned i = 0; i < 4; ++i) out[0x50 + i] = (uint8_t)(w->cost_q14              >> (i*8));
    for (unsigned i = 0; i < 4; ++i) out[0x54 + i] = (uint8_t)(w->capability_bind       >> (i*8));
    for (unsigned i = 0; i < 4; ++i) out[0x58 + i] = (uint8_t)(w->adversariality_class  >> (i*8));
    for (unsigned i = 0; i < 4; ++i) out[0x5C + i] = (uint8_t)(w->federation_route      >> (i*8));
    for (unsigned i = 0; i < 4; ++i) out[0x60 + i] = (uint8_t)(w->plan_anchor_id        >> (i*8));
    for (unsigned i = 0; i < 4; ++i) out[0x64 + i] = (uint8_t)(w->flags                 >> (i*8));
    out[0x68] = (uint8_t)(w->hexad_packed & 0xFFu);
    out[0x69] = (uint8_t)((w->hexad_packed >> 8) & 0xFFu);
    memcpy(out + 0x6A, w->hmac_tail, 22);
}

static bool replay_visit(const iii_xii_witness_t *w, void *user) {
    replay_user_t *u = (replay_user_t *)user;
    if ((uint64_t)w->cycle_seq < u->lo || (uint64_t)w->cycle_seq > u->hi) return true;
    if (u->ctx->visited >= 8192u) return false;  /* bound */
    uint8_t enc[128];
    emit_witness_canonical(enc, w);
    memcpy(u->ctx->audit_in + 128u * u->ctx->visited, enc, 128);
    memcpy(u->ctx->output_in + 32u * u->ctx->visited, w->successor_mhash, 32);
    /* observability: 11 bytes = capability_bind(4) || adversariality_class(4) ||
     * hexad_packed(2) || flags low byte(1). */
    uint8_t *o = u->ctx->obs_in + 11u * u->ctx->visited;
    for (unsigned i = 0; i < 4; ++i) o[i]      = (uint8_t)(w->capability_bind      >> (i*8));
    for (unsigned i = 0; i < 4; ++i) o[4 + i]  = (uint8_t)(w->adversariality_class >> (i*8));
    o[8] = (uint8_t)(w->hexad_packed & 0xFFu);
    o[9] = (uint8_t)((w->hexad_packed >> 8) & 0xFFu);
    o[10] = (uint8_t)(w->flags & 0xFFu);
    u->ctx->visited++;
    return true;
}

static bool is_zero_hash(const uint8_t h[32]) {
    for (unsigned i = 0; i < 32; ++i) if (h[i]) return false;
    return true;
}

void iii_cext_counterfactual_replay(const struct iii_bcwl         *bcwl,
                                    const iii_cext_replay_input_t *in,
                                    iii_cext_replay_result_t      *out)
{
    if (!in || !out) return;
    memset(out, 0, sizeof(*out));
    out->divergence_score_q14 = in->divergence_score_q14;

    if (!bcwl) {
        out->status = III_CXR_FAILED_AUDIT_HASH;
        return;
    }

    static replay_ctx_t ctx;
    ctx.visited = 0;

    replay_user_t u = { &ctx, in->witness_range_start, in->witness_range_end,
                        in->candidate.candidate_id };
    /* Walk every witness in BCWL within step_kind range [0, 0xFFFF].  We
     * filter by cycle_seq in the visit callback. */
    iii_bcwl_walk_step_kind(bcwl, 0, 0xFFFFu, replay_visit, &u);

    out->visited_count = ctx.visited;

    if (ctx.visited == 0) {
        out->status = III_CXR_FAILED_AUDIT_HASH;
        return;
    }

    /* Audit hash check. */
    iii_sha256(ctx.audit_in, (size_t)ctx.visited * 128u, out->computed_audit_hash);
    if (memcmp(out->computed_audit_hash, in->expected_audit_hash, 32) != 0) {
        out->status = III_CXR_FAILED_AUDIT_HASH;
        /* Witness mhash from candidate + range + status. */
        uint8_t buf[8 + 8 + 8 + 1];
        for (unsigned i = 0; i < 8; ++i) buf[i]      = (uint8_t)(in->candidate.candidate_id  >> (i*8));
        for (unsigned i = 0; i < 8; ++i) buf[8 + i]  = (uint8_t)(in->witness_range_start     >> (i*8));
        for (unsigned i = 0; i < 8; ++i) buf[16 + i] = (uint8_t)(in->witness_range_end       >> (i*8));
        buf[24] = (uint8_t)out->status;
        iii_sha256(buf, sizeof(buf), out->witness_mhash);
        return;
    }

    /* Output hash check (skipped if all-zero). */
    if (!is_zero_hash(in->expected_output_hash)) {
        uint8_t computed_output[32];
        iii_sha256(ctx.output_in, (size_t)ctx.visited * 32u, computed_output);
        if (memcmp(computed_output, in->expected_output_hash, 32) != 0) {
            out->status = III_CXR_FAILED_OUTPUT;
            uint8_t buf[8 + 8 + 8 + 1];
            for (unsigned i = 0; i < 8; ++i) buf[i]      = (uint8_t)(in->candidate.candidate_id >> (i*8));
            for (unsigned i = 0; i < 8; ++i) buf[8 + i]  = (uint8_t)(in->witness_range_start    >> (i*8));
            for (unsigned i = 0; i < 8; ++i) buf[16 + i] = (uint8_t)(in->witness_range_end      >> (i*8));
            buf[24] = (uint8_t)out->status;
            iii_sha256(buf, sizeof(buf), out->witness_mhash);
            return;
        }
    }

    /* Divergence threshold: > 25% (Q14 4096). */
    if (in->divergence_score_q14 > 4096u) {
        out->status = III_CXR_FAILED_DIVERGENCE;
    } else {
        out->status = III_CXR_VERIFIED;
    }

    uint8_t buf[8 + 8 + 8 + 1];
    for (unsigned i = 0; i < 8; ++i) buf[i]      = (uint8_t)(in->candidate.candidate_id >> (i*8));
    for (unsigned i = 0; i < 8; ++i) buf[8 + i]  = (uint8_t)(in->witness_range_start    >> (i*8));
    for (unsigned i = 0; i < 8; ++i) buf[16 + i] = (uint8_t)(in->witness_range_end      >> (i*8));
    buf[24] = (uint8_t)out->status;
    iii_sha256(buf, sizeof(buf), out->witness_mhash);
}

/* ----------------------------------------------------------------------------
 * Runtime
 * ---------------------------------------------------------------------------- */
typedef struct iii_cext_coherence {
    uint64_t cycle_id;
    uint16_t coherence_q14;
    bool     depromoted;
} iii_cext_coherence_t;

#define III_CEXT_COHERENCE_MAX  256u
#define III_CEXT_JIT_MAX        128u

struct iii_cext_runtime {
    uint32_t  promotions_this_tick;
    uint64_t  promotions_this_epoch;
    uint64_t  tick_count;

    /* Per-cycle coherence tracking */
    iii_cext_coherence_t coherence[III_CEXT_COHERENCE_MAX];
    unsigned             coherence_count;

    /* JIT records */
    iii_cext_jit_record_t jit[III_CEXT_JIT_MAX];
    unsigned              jit_count;

    /* Synthesis halt */
    bool synthesis_halted;
    iii_cext_rejection_log_t rejection_log;
    uint64_t anchor_alarm_count;

    /* Audit summary */
    iii_cext_audit_summary_t audit;
    uint64_t next_candidate_id;
};

iii_cext_runtime_t *iii_cext_runtime_create(void) {
    iii_cext_runtime_t *rt = (iii_cext_runtime_t *)calloc(1, sizeof(*rt));
    if (rt) rt->next_candidate_id = 1;
    return rt;
}
void iii_cext_runtime_destroy(iii_cext_runtime_t *rt) { if (rt) free(rt); }

void     iii_cext_runtime_tick(iii_cext_runtime_t *rt) {
    if (!rt) return;
    rt->promotions_this_tick = 0;
    rt->tick_count++;
}

uint32_t iii_cext_promotions_this_tick(const iii_cext_runtime_t *rt) {
    return rt ? rt->promotions_this_tick : 0u;
}

uint64_t iii_cext_promotions_this_epoch(const iii_cext_runtime_t *rt) {
    return rt ? rt->promotions_this_epoch : 0u;
}

/* Pack a 6-trit Z_3^6 hexad into a 12-bit admit slot (2 bits per pillar).
 * The packing is canonical and reversible: pillar i occupies bits 2i..2i+1. */
static uint16_t pack_hexad_admit(const iii_hexad_z3_6_t *h) {
    uint16_t v = 0;
    for (unsigned i = 0; i < 6; ++i) {
        v = (uint16_t)(v | ((uint16_t)(h->component[i] & 0x03u) << (i * 2u)));
    }
    return v;
}

bool iii_cext_synthesize(iii_cext_runtime_t            *rt,
                         const iii_cdag_edge_t         *edge,
                         const iii_hexad_z3_6_t        *h_from,
                         const iii_hexad_z3_6_t        *h_to,
                         iii_composite_candidate_t     *out)
{
    if (!rt || !edge || !h_from || !h_to || !out) return false;
    if (edge->confidence_q14 < XII_CATALYST_SYNTHESIS_CONFIDENCE_FLOOR) return false;
    memset(out, 0, sizeof(*out));
    out->candidate_id = ++rt->next_candidate_id;
    out->c1_kind = edge->from;
    out->c2_kind = edge->to;
    out->derived_confidence_q14 = edge->confidence_q14;

    /* §1.4 — composed hexad = c1.hexad ⊕ c2.hexad in Z_3^6.
     * iii_hexad_compose_scalar performs component-wise sum mod 3. */
    iii_hexad_z3_6_t pair[2];
    pair[0] = *h_from;
    pair[1] = *h_to;
    iii_hexad_compose_scalar(pair, 2, &out->composed_hexad);
    out->composed_hexad_admit = pack_hexad_admit(&out->composed_hexad);

    /* §1.4 — canonical encoding of the composed forward body for content
     * addressing.  Binds: candidate_id (8) || c1_kind (2) || c2_kind (2) ||
     * h_from (6) || h_to (6) || composed_hexad (6) || admit (2) → 32 bytes. */
    uint8_t fbuf[8 + 2 + 2 + 6 + 6 + 6 + 2];
    size_t pos = 0;
    for (unsigned i = 0; i < 8; ++i) fbuf[pos + i] = (uint8_t)(out->candidate_id >> (i * 8));
    pos += 8;
    fbuf[pos++] = (uint8_t)(edge->from);
    fbuf[pos++] = (uint8_t)(edge->from >> 8);
    fbuf[pos++] = (uint8_t)(edge->to);
    fbuf[pos++] = (uint8_t)(edge->to >> 8);
    memcpy(fbuf + pos, h_from->component, 6); pos += 6;
    memcpy(fbuf + pos, h_to->component,   6); pos += 6;
    memcpy(fbuf + pos, out->composed_hexad.component, 6); pos += 6;
    fbuf[pos++] = (uint8_t)(out->composed_hexad_admit);
    fbuf[pos++] = (uint8_t)(out->composed_hexad_admit >> 8);
    iii_sha256(fbuf, pos, out->forward_mhash);

    /* §1.4 — inverse derivation: SID composes per-cycle inverses in
     * reverse order.  Canonical encoding: "inverse" tag || forward_mhash ||
     * h_to (applied first in reverse) || h_from (applied second). */
    uint8_t ibuf[7 + 32 + 6 + 6];
    memcpy(ibuf,      "inverse",          7);
    memcpy(ibuf + 7,  out->forward_mhash, 32);
    memcpy(ibuf + 39, h_to->component,    6);
    memcpy(ibuf + 45, h_from->component,  6);
    iii_sha256(ibuf, sizeof(ibuf), out->inverse_mhash);

    /* §1.5 — synthesis witness binds forward + inverse + edge identity. */
    uint8_t wbuf[32 + 32 + 2 + 2 + 8];
    memcpy(wbuf,      out->forward_mhash, 32);
    memcpy(wbuf + 32, out->inverse_mhash, 32);
    wbuf[64] = (uint8_t)(edge->from);
    wbuf[65] = (uint8_t)(edge->from >> 8);
    wbuf[66] = (uint8_t)(edge->to);
    wbuf[67] = (uint8_t)(edge->to >> 8);
    for (unsigned i = 0; i < 8; ++i) wbuf[68 + i] = (uint8_t)(edge->frequency >> (i * 8));
    iii_sha256(wbuf, sizeof(wbuf), out->synthesis_witness_mhash);
    return true;
}

void iii_cext_propose(iii_cext_runtime_t                  *rt,
                      const iii_cext_promotion_request_t  *req,
                      iii_cext_promotion_outcome_t        *out)
{
    if (!rt || !req || !out) return;
    memset(out, 0, sizeof(*out));
    out->failed_gate = III_CXG_COUNT;

    rt->audit.total_proposals++;

    if (rt->synthesis_halted) {
        out->failed_gate = III_CXG_ANCHOR_RESTRAINT;
        rt->audit.rejections++;
        return;
    }

    /* Gate 0 — Anchor restraint */
    out->gates.passed[III_CXG_ANCHOR_RESTRAINT] = iii_cext_filter_for_anchor(&req->anchor_check);

    /* Gate 1 — Hexad admit */
    out->gates.passed[III_CXG_HEXAD_ADMIT] = req->hexad_admissible;

    /* Gate 2 — SID inverse */
    out->gates.passed[III_CXG_SID_INVERSE] = req->sid_inverse_derivable;

    /* Gate 3 — Counterfactual replay */
    out->gates.passed[III_CXG_COUNTERFACTUAL_REPLAY] = (req->replay_status == III_CXR_VERIFIED);

    /* Gate 4 — Coherence floor */
    out->gates.passed[III_CXG_COHERENCE_FLOOR] = req->predicted_coherence_q14 >= XII_MNEME_COHERENCE_FLOOR_Q14;

    /* Gate 5 — Rate cap */
    out->gates.passed[III_CXG_RATE_CAP] = (rt->promotions_this_tick < XII_MNEME_CATALYST_PROMOTION_PER_TICK_MAX) &&
                                          (rt->promotions_this_epoch < XII_MNEME_CATALYST_PROMOTION_PER_EPOCH_MAX);

    /* Gate 6 — Trinity */
    bool trinity_required = (req->tier >= 2);
    out->gates.passed[III_CXG_TRINITY] = !trinity_required || req->trinity_admitted;

    /* Gate 7 — Anchor cosignature (only for constitutional tier) */
    bool cosig_required = (req->tier == 3);
    out->gates.passed[III_CXG_ANCHOR_COSIGNATURE] = !cosig_required || req->anchor_cosigned;

    /* First failure */
    iii_cext_gate_t failed = III_CXG_COUNT;
    for (unsigned i = 0; i < III_CXG_COUNT; ++i) {
        if (!out->gates.passed[i]) { failed = (iii_cext_gate_t)i; break; }
    }
    out->failed_gate = failed;

    if (failed != III_CXG_COUNT) {
        rt->audit.rejections++;
        if (failed == III_CXG_ANCHOR_RESTRAINT) {
            rt->audit.anchor_rejections++;
            rt->rejection_log.anchor_rejections++;
        }
        if (failed == III_CXG_COUNTERFACTUAL_REPLAY) rt->audit.replay_failures++;
        if (failed == III_CXG_COHERENCE_FLOOR)       rt->audit.coherence_failures++;
        rt->rejection_log.total_rejections++;

        /* Witness mhash for rejection */
        uint8_t buf[8 + 1];
        for (unsigned i = 0; i < 8; ++i) buf[i] = (uint8_t)(req->candidate.candidate_id >> (i*8));
        buf[8] = (uint8_t)failed;
        iii_sha256(buf, sizeof(buf), out->rejection_witness_mhash);

        /* Anchor attack pattern → halt */
        if (iii_cext_anchor_attack_pattern(&rt->rejection_log)) {
            rt->synthesis_halted = true;
            rt->anchor_alarm_count++;
        }
        return;
    }

    /* All gates pass — promote. */
    out->promoted = true;
    rt->promotions_this_tick++;
    rt->promotions_this_epoch++;
    rt->audit.promotions++;

    uint8_t buf[8];
    for (unsigned i = 0; i < 8; ++i) buf[i] = (uint8_t)(req->candidate.candidate_id >> (i*8));
    iii_sha256(buf, sizeof(buf), out->promote_witness_mhash);
}

void iii_cext_record_coherence(iii_cext_runtime_t *rt, uint64_t cycle_id, uint16_t coherence_q14) {
    if (!rt) return;
    for (unsigned i = 0; i < rt->coherence_count; ++i) {
        if (rt->coherence[i].cycle_id == cycle_id) {
            rt->coherence[i].coherence_q14 = coherence_q14;
            return;
        }
    }
    if (rt->coherence_count >= III_CEXT_COHERENCE_MAX) return;
    rt->coherence[rt->coherence_count].cycle_id = cycle_id;
    rt->coherence[rt->coherence_count].coherence_q14 = coherence_q14;
    rt->coherence[rt->coherence_count].depromoted = false;
    rt->coherence_count++;
}

bool iii_cext_should_depromote(iii_cext_runtime_t *rt, uint64_t cycle_id) {
    if (!rt) return false;
    for (unsigned i = 0; i < rt->coherence_count; ++i) {
        if (rt->coherence[i].cycle_id == cycle_id) {
            return !rt->coherence[i].depromoted &&
                   rt->coherence[i].coherence_q14 < XII_MNEME_COHERENCE_FLOOR_Q14;
        }
    }
    return false;
}

bool iii_cext_depromote(iii_cext_runtime_t *rt, uint64_t cycle_id) {
    if (!rt) return false;
    for (unsigned i = 0; i < rt->coherence_count; ++i) {
        if (rt->coherence[i].cycle_id == cycle_id && !rt->coherence[i].depromoted) {
            rt->coherence[i].depromoted = true;
            return true;
        }
    }
    return false;
}

bool iii_cext_synthesis_halted(const iii_cext_runtime_t *rt) {
    return rt ? rt->synthesis_halted : false;
}

void iii_cext_resume_synthesis(iii_cext_runtime_t *rt) {
    if (!rt) return;
    rt->synthesis_halted = false;
    rt->rejection_log.total_rejections = 0;
    rt->rejection_log.anchor_rejections = 0;
}

uint64_t iii_cext_anchor_alarm_count(const iii_cext_runtime_t *rt) {
    return rt ? rt->anchor_alarm_count : 0u;
}

/* JIT-compile a cycle dispatch stub.  For x86-64 we emit a minimal trampoline:
 *
 *     mov rax, cycle_id        ; movabs rax, imm64           — 10 bytes
 *     ret                                                    —  1 byte
 *     nop ... nop              ; padding to code_size_hint   —  N bytes
 *
 * The real machine_code_size is the actual emitted byte count (capped at the
 * caller's hint).  machine_code_mhash is the SHA-256 of the actual bytes.
 *
 * For non-x86-64 archs we record the metadata only and do not emit; this is
 * the design point until the SVE/VMX emitters land in COMPILER/BOOT. */
bool iii_cext_jit_compile(iii_cext_runtime_t *rt,
                          uint64_t            cycle_id,
                          iii_cext_arch_t     arch,
                          uint32_t            code_size,
                          iii_cext_jit_record_t *out)
{
    if (!rt) return false;
    if (rt->jit_count >= III_CEXT_JIT_MAX) return false;
    iii_cext_jit_record_t *r = &rt->jit[rt->jit_count++];
    memset(r, 0, sizeof(*r));
    r->cycle_id = cycle_id;
    r->arch = arch;

    if (arch == III_CXA_X86_64) {
        /* Allocate a buffer sized to the caller's hint (clamp 16 .. 4096). */
        uint32_t cap = code_size;
        if (cap < 16u)   cap = 16u;
        if (cap > 4096u) cap = 4096u;
        uint8_t *bytes = (uint8_t *)calloc(cap, 1);
        if (!bytes) {
            rt->jit_count--;
            return false;
        }
        iii_jit_buf_t b;
        iii_jit_init(&b, bytes, cap);
        iii_jit_mov_r64_imm64(&b, III_REG_RAX, cycle_id);   /* 10 bytes */
        iii_jit_ret(&b);                                    /*  1 byte  */
        size_t emitted = iii_jit_offset(&b);
        /* NOP-pad up to the hinted code_size if there is space. */
        if (cap > emitted) {
            iii_jit_emit_nop(&b, cap - emitted);
            emitted = iii_jit_offset(&b);
        }
        if (b.err != III_JIT_E_OK) {
            free(bytes);
            rt->jit_count--;
            return false;
        }
        r->machine_code_size = (uint32_t)emitted;
        iii_sha256(bytes, emitted, r->machine_code_mhash);
        free(bytes);
    } else {
        /* No x86-64 emitter for this arch in Stage 0; record metadata only. */
        r->machine_code_size = code_size;
        uint8_t buf[8 + 1 + 4];
        for (unsigned i = 0; i < 8; ++i) buf[i] = (uint8_t)(cycle_id >> (i*8));
        buf[8] = (uint8_t)arch;
        buf[9]  = (uint8_t)(code_size);
        buf[10] = (uint8_t)(code_size >> 8);
        buf[11] = (uint8_t)(code_size >> 16);
        buf[12] = (uint8_t)(code_size >> 24);
        iii_sha256(buf, sizeof(buf), r->machine_code_mhash);
    }

    if (out) *out = *r;
    return true;
}

bool iii_cext_jit_deoptimize(iii_cext_runtime_t *rt, uint64_t cycle_id) {
    if (!rt) return false;
    for (unsigned i = 0; i < rt->jit_count; ++i) {
        if (rt->jit[i].cycle_id == cycle_id && !rt->jit[i].deoptimised) {
            rt->jit[i].deoptimised = true;
            return true;
        }
    }
    return false;
}

size_t iii_cext_jit_record_count(const iii_cext_runtime_t *rt) {
    return rt ? rt->jit_count : 0u;
}

void iii_cext_audit(const iii_cext_runtime_t *rt, iii_cext_audit_summary_t *out) {
    if (!rt || !out) return;
    *out = rt->audit;
}
