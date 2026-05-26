/* III-MODULES implementation */
#include "iii/modules.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

extern void iii_sha256(const void *data, size_t len, uint8_t out[32]);

#define III_MOD_PROPOSAL_MAX  64u

typedef struct iii_proposal {
    iii_module_change_t change;
    iii_deploy_outcome_t outcome;
    bool                used;
} iii_proposal_t;

struct iii_module_runtime {
    iii_module_t      modules[III_MOD_MAX];
    unsigned          count;
    iii_mod_id_t      next_id;
    iii_proposal_t    proposals[III_MOD_PROPOSAL_MAX];
    uint64_t          witness_count;
};

const char *iii_deploy_flag_name(iii_deploy_flag_t f) {
    switch (f) {
        case III_DEPLOY_NONE:            return "none";
        case III_DEPLOY_SAFE_APPROVED:   return "SAFE_APPROVED";
        case III_DEPLOY_SAFE_FLAGGED:    return "SAFE_FLAGGED";
        case III_DEPLOY_UNSAFE_REJECTED: return "UNSAFE_REJECTED";
        default:                         return "unknown";
    }
}

const char *iii_validation_ring_name(iii_validation_ring_t r) {
    switch (r) {
        case III_VR_REJECT:     return "reject";
        case III_VR_KERNEL:     return "Ring 0";
        case III_VR_HYPERVISOR: return "Ring -1";
        case III_VR_SANCTUM:    return "Ring -2";
        default:                return "unknown";
    }
}

iii_validation_ring_t iii_modules_select_validation_ring(iii_level_t risk, iii_level_t benefit) {
    /* §5.2 decision tree:
     *   high benefit & low risk        -> Ring -2
     *   medium+ benefit & medium risk  -> Ring -1
     *   low risk & low+ benefit        -> Ring 0
     *   else                           -> reject */
    if (benefit == III_LVL_HIGH && risk == III_LVL_LOW)         return III_VR_SANCTUM;
    if (benefit >= III_LVL_MEDIUM && risk <= III_LVL_MEDIUM)    return III_VR_HYPERVISOR;
    if (risk == III_LVL_LOW)                                    return III_VR_KERNEL;
    return III_VR_REJECT;
}

const char *iii_resolve_status_name(iii_resolve_status_t s) {
    switch (s) {
        case III_RES_OK:               return "ok";
        case III_RES_NOT_FOUND:        return "not-found";
        case III_RES_CLOSURE_MISMATCH: return "MOD-RES-001 closure mismatch";
        case III_RES_AMBIGUOUS:        return "ambiguous";
        case III_RES_INVALID:          return "invalid";
        default:                       return "unknown";
    }
}

iii_module_runtime_t *iii_module_runtime_create(void) {
    return (iii_module_runtime_t *)calloc(1, sizeof(iii_module_runtime_t));
}
void iii_module_runtime_destroy(iii_module_runtime_t *rt) { if (rt) free(rt); }

size_t iii_module_runtime_count(const iii_module_runtime_t *rt) {
    return rt ? rt->count : 0u;
}

uint64_t iii_module_witness_count(const iii_module_runtime_t *rt) {
    return rt ? rt->witness_count : 0u;
}

static iii_module_t *find_mut(iii_module_runtime_t *rt, iii_mod_id_t id) {
    for (unsigned i = 0; i < rt->count; ++i) {
        if (rt->modules[i].module_id == id) return &rt->modules[i];
    }
    return NULL;
}

iii_mod_id_t iii_module_register(iii_module_runtime_t *rt,
                                 const char            *qualified_name,
                                 const char            *version,
                                 const uint8_t         *canonical_source,
                                 size_t                 source_len,
                                 uint8_t                ring_set)
{
    if (!rt || !qualified_name || rt->count >= III_MOD_MAX) return 0;
    iii_module_t *m = &rt->modules[rt->count++];
    memset(m, 0, sizeof(*m));
    m->module_id = ++rt->next_id;
    /* Copy name */
    size_t i = 0;
    for (; i < sizeof(m->qualified_name) - 1u && qualified_name[i]; ++i) {
        m->qualified_name[i] = qualified_name[i];
    }
    m->qualified_name[i] = '\0';
    if (version) {
        size_t v = 0;
        for (; v < sizeof(m->version) - 1u && version[v]; ++v) m->version[v] = version[v];
        m->version[v] = '\0';
    }
    /* Closure root = SHA-256(canonical source). */
    if (canonical_source && source_len > 0) {
        iii_sha256(canonical_source, source_len, m->closure_root);
        memcpy(m->canonical_source_mhash, m->closure_root, 32);
    }
    m->ring_set = ring_set;
    m->coherence_q14 = 14000;     /* default healthy */
    m->performance_q14 = 16384;   /* tuned */
    rt->witness_count++;
    return m->module_id;
}

bool iii_module_add_import(iii_module_runtime_t *rt,
                           iii_mod_id_t          mid,
                           const char           *qualified_name,
                           const uint8_t         closure_pin[32])
{
    iii_module_t *m = find_mut(rt, mid);
    if (!m) return false;
    if (m->import_count >= III_MOD_MAX_IMPORTS) return false;
    iii_mod_import_t *imp = &m->imports[m->import_count++];
    size_t i = 0;
    for (; i < sizeof(imp->qualified_name) - 1u && qualified_name[i]; ++i) {
        imp->qualified_name[i] = qualified_name[i];
    }
    imp->qualified_name[i] = '\0';
    if (closure_pin) {
        memcpy(imp->closure_pin, closure_pin, 32);
        imp->pinned = true;
    } else {
        memset(imp->closure_pin, 0, 32);
        imp->pinned = false;
    }
    return true;
}

bool iii_module_add_export(iii_module_runtime_t *rt,
                           iii_mod_id_t          mid,
                           const char           *name,
                           const uint8_t         item_mhash[32])
{
    iii_module_t *m = find_mut(rt, mid);
    if (!m || !name || !item_mhash) return false;
    if (m->export_count >= III_MOD_MAX_EXPORTS) return false;
    iii_mod_export_t *e = &m->exports[m->export_count++];
    size_t i = 0;
    for (; i < sizeof(e->name) - 1u && name[i]; ++i) e->name[i] = name[i];
    e->name[i] = '\0';
    memcpy(e->item_mhash, item_mhash, 32);
    return true;
}

const iii_module_t *iii_module_lookup(const iii_module_runtime_t *rt, iii_mod_id_t mid) {
    if (!rt) return NULL;
    for (unsigned i = 0; i < rt->count; ++i) {
        if (rt->modules[i].module_id == mid) return &rt->modules[i];
    }
    return NULL;
}

const iii_module_t *iii_module_lookup_by_name(const iii_module_runtime_t *rt, const char *qn) {
    if (!rt || !qn) return NULL;
    /* Choose by max coherence × performance among non-superseded matches. */
    const iii_module_t *best = NULL;
    uint32_t best_score = 0;
    for (unsigned i = 0; i < rt->count; ++i) {
        const iii_module_t *m = &rt->modules[i];
        if (m->superseded) continue;
        if (strncmp(m->qualified_name, qn, sizeof(m->qualified_name)) == 0) {
            uint32_t score = ((uint32_t)m->coherence_q14 * (uint32_t)m->performance_q14) >> 14;
            if (score >= best_score) { best_score = score; best = m; }
        }
    }
    return best;
}

void iii_module_set_metrics(iii_module_runtime_t *rt,
                            iii_mod_id_t          mid,
                            uint16_t              coherence_q14,
                            uint16_t              performance_q14)
{
    iii_module_t *m = find_mut(rt, mid);
    if (!m) return;
    m->coherence_q14   = coherence_q14;
    m->performance_q14 = performance_q14;
}

void iii_module_set_hexad(iii_module_runtime_t   *rt,
                          iii_mod_id_t            mid,
                          const iii_hexad_z3_6_t *hexad)
{
    iii_module_t *m = find_mut(rt, mid);
    if (!m || !hexad) return;
    m->aggregate_hexad = *hexad;
}

/* HEXAD §4 — Reachability Theorem: a hexad whose pillar 1..4 contains NEG
 * (encoded as 0 in our Z_3 with 0=NEG, 1=ZERO, 2=POS) is unrepresentable
 * (xii_asym_reach6 rejection).  Pillars 5..6 admit NEG (ghost / observation).
 * The 6 PFS bricking forms are precisely those with a NEG in 1..4. */
static bool hexad_admissible_z3_6(const iii_hexad_z3_6_t *h) {
    if (!h) return false;
    /* Pillars 0..3 (the four structural pillars) must be ZERO or POS. */
    for (unsigned i = 0; i < 4; ++i) {
        if (h->component[i] == 0u /* NEG */) return false;
    }
    /* All-zero hexad is degenerate. */
    bool any_pos = false;
    for (unsigned i = 0; i < 6; ++i) {
        if (h->component[i] == 2u /* POS */) { any_pos = true; break; }
    }
    return any_pos;
}

iii_resolve_status_t iii_module_resolve(const iii_module_runtime_t *rt,
                                        const char                  *qualified_name,
                                        const uint8_t               *closure_pin_or_null,
                                        iii_mod_id_t                *out_mid)
{
    if (!rt || !qualified_name) return III_RES_INVALID;
    const iii_module_t *m = iii_module_lookup_by_name(rt, qualified_name);
    if (!m) return III_RES_NOT_FOUND;
    if (closure_pin_or_null) {
        if (memcmp(m->closure_root, closure_pin_or_null, 32) != 0) return III_RES_CLOSURE_MISMATCH;
    }
    if (out_mid) *out_mid = m->module_id;
    return III_RES_OK;
}

bool iii_module_transmit(iii_module_runtime_t *rt,
                         iii_mod_id_t           from,
                         iii_mod_id_t           to,
                         iii_tx_record_t       *out)
{
    iii_module_t *fm = find_mut(rt, from);
    iii_module_t *tm = find_mut(rt, to);
    if (!fm || !tm || !out) return false;
    memset(out, 0, sizeof(*out));
    out->from_module = from;
    out->to_module   = to;

    /* §3 — pick path based on metrics.  Hot+coherent → specialised; very hot
     * → fused; default → generic. */
    uint32_t fm_score = ((uint32_t)fm->coherence_q14 * (uint32_t)fm->performance_q14) >> 14;
    uint32_t tm_score = ((uint32_t)tm->coherence_q14 * (uint32_t)tm->performance_q14) >> 14;
    uint32_t avg = (fm_score + tm_score) / 2u;
    if (avg >= 16000) {
        out->path = III_TX_PATH_FUSED;
        out->cycle_overhead = 5;
    } else if (avg >= 12000) {
        out->path = III_TX_PATH_SPECIALIZED;
        out->cycle_overhead = 15;
    } else {
        out->path = III_TX_PATH_GENERIC;
        out->cycle_overhead = 60;
    }

    /* Witness: chain via SHA-256(from_mhash || to_mhash). */
    uint8_t buf[64 + 16];
    memcpy(buf,    fm->closure_root, 32);
    memcpy(buf+32, tm->closure_root, 32);
    for (unsigned i = 0; i < 8; ++i) buf[64 + i] = (uint8_t)(rt->witness_count >> (i*8));
    iii_sha256(buf, 72, out->successor_mhash);
    rt->witness_count++;
    return true;
}

void iii_module_complementarity(const iii_module_runtime_t   *rt,
                                iii_mod_id_t                  a,
                                iii_mod_id_t                  b,
                                iii_complementarity_result_t *out)
{
    if (!rt || !out) return;
    memset(out, 0, sizeof(*out));
    const iii_module_t *am = iii_module_lookup(rt, a);
    const iii_module_t *bm = iii_module_lookup(rt, b);
    if (!am || !bm) return;

    /* §4.1 — composed hexad = a.aggregate_hexad ⊕ b.aggregate_hexad in Z_3^6.
     * Admissibility: composed pillars 0..3 must avoid NEG (HEXAD §4
     * Reachability Theorem), and at least one pillar must be POS. */
    iii_hexad_z3_6_t pair[2];
    pair[0] = am->aggregate_hexad;
    pair[1] = bm->aggregate_hexad;
    iii_hexad_z3_6_t composed;
    iii_hexad_compose_scalar(pair, 2, &composed);
    out->hexad_admissible = hexad_admissible_z3_6(&composed) ? 1u : 0u;

    /* Coherence path = min of the two. */
    uint16_t coh = (am->coherence_q14 < bm->coherence_q14) ? am->coherence_q14 : bm->coherence_q14;
    out->coherence_path_q14 = coh;
    out->performance_q14    = (uint16_t)(((uint32_t)am->performance_q14 + bm->performance_q14) / 2u);
    /* §4.1: complementary iff hexad admissible AND coherence ≥ floor AND
     * performance ≥ 95% optimal. */
    out->complementary = (out->hexad_admissible == 1)
                      && (out->coherence_path_q14 >= 12000u)
                      && (out->performance_q14 >= (uint16_t)(0.95 * 16384.0));
}

void iii_module_propose_and_deploy(iii_module_runtime_t      *rt,
                                   const iii_module_change_t *ch,
                                   iii_deploy_outcome_t      *out)
{
    if (!rt || !ch || !out) return;
    memset(out, 0, sizeof(*out));

    /* §5.2 — pick validation ring */
    out->ring = iii_modules_select_validation_ring(ch->risk, ch->benefit);
    if (out->ring == III_VR_REJECT) {
        out->flag = III_DEPLOY_UNSAFE_REJECTED;
        rt->witness_count++;
        return;
    }

    /* §6.1 — codegen + structural checks */
    if (!ch->structural_invariants_held) {
        out->flag = III_DEPLOY_UNSAFE_REJECTED;
        rt->witness_count++;
        return;
    }
    if (!ch->codegen_passed) {
        out->flag = III_DEPLOY_UNSAFE_REJECTED;
        rt->witness_count++;
        return;
    }
    /* §6.1 — semantic-baseline match */
    if (!ch->semantic_baseline_match) {
        out->flag = III_DEPLOY_SAFE_FLAGGED;
    } else {
        out->flag = III_DEPLOY_SAFE_APPROVED;
    }

    /* Apply the change.  For LOAD or RESOLUTION this is a no-op at the model
     * level (the runtime exposes the module already).  For SUPERSEDE, mark
     * primary superseded by secondary.  For FUSE, create a new fused module. */
    if (ch->kind == III_CHANGE_SUPERSEDE) {
        iii_module_t *p = find_mut(rt, ch->primary);
        if (p) {
            p->superseded = true;
            p->superseded_by = ch->secondary;
            out->new_module_id = ch->secondary;
        }
    } else if (ch->kind == III_CHANGE_FUSE) {
        iii_mod_id_t fused = iii_module_fuse(rt, ch->primary, ch->secondary);
        out->new_module_id = fused;
    } else {
        out->new_module_id = ch->primary;
    }
    out->deployed = true;

    /* Record proposal. */
    for (unsigned i = 0; i < III_MOD_PROPOSAL_MAX; ++i) {
        if (!rt->proposals[i].used) {
            rt->proposals[i].used    = true;
            rt->proposals[i].change  = *ch;
            rt->proposals[i].outcome = *out;
            break;
        }
    }
    rt->witness_count++;
}

iii_mod_id_t iii_module_fuse(iii_module_runtime_t *rt, iii_mod_id_t a, iii_mod_id_t b) {
    iii_module_t *am = find_mut(rt, a);
    iii_module_t *bm = find_mut(rt, b);
    if (!am || !bm) return 0;
    if (rt->count >= III_MOD_MAX) return 0;
    iii_module_t *f = &rt->modules[rt->count++];
    memset(f, 0, sizeof(*f));
    f->module_id = ++rt->next_id;
    /* Build "<a>+<b>" with explicit bounds. */
    size_t pos = 0;
    for (size_t i = 0; pos + 1 < sizeof(f->qualified_name) && am->qualified_name[i]; ++i, ++pos) {
        f->qualified_name[pos] = am->qualified_name[i];
    }
    if (pos + 1 < sizeof(f->qualified_name)) f->qualified_name[pos++] = '+';
    for (size_t i = 0; pos + 1 < sizeof(f->qualified_name) && bm->qualified_name[i]; ++i, ++pos) {
        f->qualified_name[pos] = bm->qualified_name[i];
    }
    f->qualified_name[pos] = '\0';
    /* Closure root = SHA-256(a||b) */
    uint8_t buf[64];
    memcpy(buf,    am->closure_root, 32);
    memcpy(buf+32, bm->closure_root, 32);
    iii_sha256(buf, 64, f->closure_root);
    memcpy(f->canonical_source_mhash, f->closure_root, 32);
    /* Combined ring set */
    f->ring_set = (uint8_t)(am->ring_set | bm->ring_set);
    /* Take max metrics as the fused expectation */
    f->coherence_q14   = (am->coherence_q14   > bm->coherence_q14)   ? am->coherence_q14   : bm->coherence_q14;
    f->performance_q14 = 16384;
    rt->witness_count++;
    return f->module_id;
}

size_t iii_module_proposals(const iii_module_runtime_t *rt,
                            iii_proposal_summary_t      *out_buf,
                            size_t                       cap)
{
    if (!rt || !out_buf) return 0;
    size_t n = 0;
    for (unsigned i = 0; i < III_MOD_PROPOSAL_MAX && n < cap; ++i) {
        if (!rt->proposals[i].used) continue;
        iii_proposal_summary_t *s = &out_buf[n++];
        s->kind      = rt->proposals[i].change.kind;
        s->primary   = rt->proposals[i].change.primary;
        s->secondary = rt->proposals[i].change.secondary;
        s->flag      = rt->proposals[i].outcome.flag;
        s->ring      = rt->proposals[i].outcome.ring;
        s->est_coherence_gain_q14 = 500;
    }
    return n;
}

void iii_module_manifest_compute(const iii_module_t *m, iii_module_manifest_t *out) {
    if (!m || !out) return;
    memset(out, 0, sizeof(*out));
    memcpy(out->closure_root,           m->closure_root,           32);
    memcpy(out->canonical_source_mhash, m->canonical_source_mhash, 32);
    memcpy(out->r1_root,                m->r1_specification_root,  32);

    /* imports_mhash = SHA-256 of concatenated (qualified_name || closure_pin) */
    uint8_t scratch[III_MOD_MAX_IMPORTS * (III_MOD_NAME_MAX + 32)];
    size_t  pos = 0;
    for (unsigned i = 0; i < m->import_count && pos + III_MOD_NAME_MAX + 32 <= sizeof(scratch); ++i) {
        memcpy(scratch + pos, m->imports[i].qualified_name, III_MOD_NAME_MAX);
        pos += III_MOD_NAME_MAX;
        memcpy(scratch + pos, m->imports[i].closure_pin, 32);
        pos += 32;
    }
    iii_sha256(scratch, pos, out->imports_mhash);

    pos = 0;
    for (unsigned i = 0; i < m->export_count && pos + III_MOD_NAME_MAX + 32 <= sizeof(scratch); ++i) {
        memcpy(scratch + pos, m->exports[i].name, III_MOD_NAME_MAX);
        pos += III_MOD_NAME_MAX;
        memcpy(scratch + pos, m->exports[i].item_mhash, 32);
        pos += 32;
    }
    iii_sha256(scratch, pos, out->exports_mhash);

    /* cycle_table / hexad_table / proof_certificates left as zeros — they
     * are provided externally in a real build. */
}
