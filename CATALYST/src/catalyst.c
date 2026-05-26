/* III-CATALYST implementation */
#include "iii/catalyst.h"
#include <stdlib.h>
#include <string.h>

extern void iii_sha256(const void *data, size_t len, uint8_t out[32]);

#define III_CAT_HISTORY_MAX  256u

typedef struct iii_cat_history_entry {
    uint8_t  witness_mhash[32];
    iii_cat_promotion_kind_t kind;
    bool     revoked;
} iii_cat_history_entry_t;

struct iii_catalyst {
    /* §2.3 — per-tick counters */
    uint32_t cycle_count;
    uint32_t phase_count;
    uint32_t module_count;
    uint32_t keyword_count;
    /* Effective rate caps (operator may lower these via constrain) */
    uint32_t cap_cycle;
    uint32_t cap_phase;
    uint32_t cap_module;
    uint32_t cap_keyword;
    bool     paused;

    /* Aggregate stats */
    uint64_t witness_count;
    uint64_t promotion_count;
    uint64_t revocation_count;
    uint64_t tick_count;

    /* History (for revoke). */
    iii_cat_history_entry_t history[III_CAT_HISTORY_MAX];
    unsigned history_count;
};

const char *iii_cat_promotion_kind_name(iii_cat_promotion_kind_t k) {
    switch (k) {
        case III_CAT_NONE:                return "none";
        case III_CAT_CYCLE:               return "cycle";
        case III_CAT_KEYWORD:             return "keyword";
        case III_CAT_HEXAD:               return "hexad";
        case III_CAT_MODULE_FUSION:       return "module-fusion";
        case III_CAT_TRINITY_REFINEMENT:  return "trinity-refinement";
        case III_CAT_SID_RULE:            return "sid-rule";
        case III_CAT_SPECIALIZATION_HINT: return "specialization-hint";
        case III_CAT_PHASE:               return "phase";
        default:                          return "unknown";
    }
}

const char *iii_cat_gate_name(iii_cat_gate_t g) {
    switch (g) {
        case III_CGATE_OBSERVATORY_SAT:  return "observatory-saturation";
        case III_CGATE_MOBIUS_COHERENCE: return "mobius-coherence";
        case III_CGATE_TRINITY:          return "trinity";
        case III_CGATE_CEILING:          return "ceiling";
        case III_CGATE_HEXAD_REACH:      return "hexad-reachability";
        case III_CGATE_CODEGEN:          return "codegen-validation";
        case III_CGATE_RING_GATING:      return "ring-gating";
        case III_CGATE_DEPLOY_FLAG:      return "deploy-flag";
        default:                         return "unknown";
    }
}

const char *iii_cat_deploy_flag_name(iii_cat_deploy_flag_t f) {
    switch (f) {
        case III_CAT_DF_SAFE_APPROVED:   return "SAFE_APPROVED";
        case III_CAT_DF_SAFE_FLAGGED:    return "SAFE_FLAGGED";
        case III_CAT_DF_UNSAFE_REJECTED: return "UNSAFE_REJECTED";
        default:                         return "none";
    }
}

const char *iii_cat_witness_kind_name(iii_cat_witness_kind_t k) {
    switch (k) {
        case III_CATW_MNEME_CATALYST_PROMOTE: return "MNEME_CATALYST_PROMOTE";
        case III_CATW_CATALYST_REJECT:        return "CATALYST_REJECT";
        case III_CATW_CATALYST_RATE_CAP:      return "CATALYST_RATE_CAP";
        case III_CATW_CATALYST_REVOKE:        return "CATALYST_REVOKE";
        case III_CATW_CATALYST_PAUSE:         return "CATALYST_PAUSE";
        case III_CATW_CATALYST_RESUME:        return "CATALYST_RESUME";
        case III_CATW_CATALYST_CONSTRAIN:     return "CATALYST_CONSTRAIN";
        default:                              return "unknown";
    }
}

bool iii_cat_gates_all_passed(const iii_cat_gates_t *g) {
    if (!g) return false;
    for (unsigned i = 0; i < III_CGATE_COUNT; ++i) {
        if (!g->passed[i]) return false;
    }
    return true;
}

unsigned iii_cat_gates_first_failure(const iii_cat_gates_t *g) {
    if (!g) return III_CGATE_COUNT;
    for (unsigned i = 0; i < III_CGATE_COUNT; ++i) {
        if (!g->passed[i]) return i;
    }
    return III_CGATE_COUNT;
}

iii_catalyst_t *iii_catalyst_create(void) {
    iii_catalyst_t *c = (iii_catalyst_t *)calloc(1, sizeof(*c));
    if (!c) return NULL;
    c->cap_cycle   = XII_MNEME_CATALYST_PROMOTION_RATE_PER_TICK;
    c->cap_phase   = XII_PHASE_PROMOTE_RATE;
    c->cap_module  = XII_MOD_PROMOTE_RATE;
    c->cap_keyword = XII_KEYWORD_PROMOTE_RATE;
    return c;
}

void iii_catalyst_destroy(iii_catalyst_t *c) { if (c) free(c); }

void iii_catalyst_tick(iii_catalyst_t *c) {
    if (!c) return;
    c->cycle_count = 0;
    c->phase_count = 0;
    c->module_count = 0;
    c->keyword_count = 0;
    c->tick_count++;
}

uint32_t iii_catalyst_cycle_count_this_tick(const iii_catalyst_t *c)   { return c ? c->cycle_count   : 0u; }
uint32_t iii_catalyst_phase_count_this_tick(const iii_catalyst_t *c)   { return c ? c->phase_count   : 0u; }
uint32_t iii_catalyst_module_count_this_tick(const iii_catalyst_t *c)  { return c ? c->module_count  : 0u; }
uint32_t iii_catalyst_keyword_count_this_tick(const iii_catalyst_t *c) { return c ? c->keyword_count : 0u; }

uint64_t iii_catalyst_witness_count(const iii_catalyst_t *c)    { return c ? c->witness_count    : 0u; }
uint64_t iii_catalyst_promotion_count(const iii_catalyst_t *c)  { return c ? c->promotion_count  : 0u; }
uint64_t iii_catalyst_revocation_count(const iii_catalyst_t *c) { return c ? c->revocation_count : 0u; }

uint32_t iii_catalyst_rate_cap(const iii_catalyst_t *c, iii_cat_promotion_kind_t kind) {
    if (!c) return 0;
    switch (kind) {
        case III_CAT_CYCLE:               return c->cap_cycle;
        case III_CAT_PHASE:               return c->cap_phase;
        case III_CAT_MODULE_FUSION:       return c->cap_module;
        case III_CAT_KEYWORD:             return c->cap_keyword;
        default:                          return c->cap_cycle;
    }
}

bool iii_catalyst_pause(iii_catalyst_t *c) {
    if (!c) return false;
    c->paused = true;
    c->witness_count++;
    return true;
}

bool iii_catalyst_resume(iii_catalyst_t *c) {
    if (!c) return false;
    c->paused = false;
    c->witness_count++;
    return true;
}

bool iii_catalyst_is_paused(const iii_catalyst_t *c) { return c ? c->paused : false; }

bool iii_catalyst_constrain(iii_catalyst_t *c,
                            iii_cat_promotion_kind_t kind,
                            uint32_t                 max_rate)
{
    if (!c) return false;
    switch (kind) {
        case III_CAT_CYCLE:               c->cap_cycle   = max_rate; break;
        case III_CAT_PHASE:               c->cap_phase   = max_rate; break;
        case III_CAT_MODULE_FUSION:       c->cap_module  = max_rate; break;
        case III_CAT_KEYWORD:             c->cap_keyword = max_rate; break;
        default:                          c->cap_cycle   = max_rate; break;
    }
    c->witness_count++;
    return true;
}

bool iii_catalyst_revoke(iii_catalyst_t *c, const uint8_t mhash[32]) {
    if (!c || !mhash) return false;
    for (unsigned i = 0; i < c->history_count; ++i) {
        if (memcmp(c->history[i].witness_mhash, mhash, 32) == 0) {
            if (c->history[i].revoked) return false;
            c->history[i].revoked = true;
            c->revocation_count++;
            c->witness_count++;
            return true;
        }
    }
    return false;
}

bool iii_catalyst_reject(iii_catalyst_t *c, const uint8_t proposal_mhash[32]) {
    /* In this model, we don't queue proposals — propose is synchronous.  We
     * still allow operator to record a reject witness for audit. */
    (void)proposal_mhash;
    if (!c) return false;
    c->witness_count++;
    return true;
}

void iii_catalyst_propose(iii_catalyst_t                  *c,
                          const iii_cat_promotion_request_t *req,
                          iii_cat_promotion_outcome_t       *out)
{
    if (!c || !req || !out) return;
    memset(out, 0, sizeof(*out));

    if (c->paused) {
        out->flag = III_CAT_DF_UNSAFE_REJECTED;
        c->witness_count++;
        return;
    }

    /* Rate caps */
    uint32_t  current = 0;
    uint32_t  cap     = 0;
    switch (req->kind) {
        case III_CAT_CYCLE:               current = c->cycle_count;   cap = c->cap_cycle;   break;
        case III_CAT_PHASE:               current = c->phase_count;   cap = c->cap_phase;   break;
        case III_CAT_MODULE_FUSION:       current = c->module_count;  cap = c->cap_module;  break;
        case III_CAT_KEYWORD:             current = c->keyword_count; cap = c->cap_keyword; break;
        default:                          current = c->cycle_count;   cap = c->cap_cycle;   break;
    }
    if (current >= cap) {
        out->flag = III_CAT_DF_UNSAFE_REJECTED;   /* rate-capped */
        c->witness_count++;
        return;
    }

    /* §2.1 — eight gates */
    out->gates.passed[III_CGATE_OBSERVATORY_SAT]  = req->observatory_saturated;
    out->gates.passed[III_CGATE_MOBIUS_COHERENCE] = req->projected_coherence_q14 >= req->coherence_floor_q14;
    out->gates.passed[III_CGATE_TRINITY]          = req->trinity_admitted;
    out->gates.passed[III_CGATE_CEILING]          = req->ceiling_admitted;
    out->gates.passed[III_CGATE_HEXAD_REACH]      = req->hexad_reachable;
    out->gates.passed[III_CGATE_CODEGEN]          = req->codegen_passed;
    out->gates.passed[III_CGATE_RING_GATING]      = (req->target_ring != III_CAT_VR_REJECT);
    /* Deploy-flag gate: passes iff it would be SAFE_APPROVED or SAFE_FLAGGED
     * (we mark it after computing all the others) — for now mark passed. */
    out->gates.passed[III_CGATE_DEPLOY_FLAG]      = true;

    /* Sub-witness mhashes per gate: SHA-256(candidate_mhash || gate_index || passed) */
    for (unsigned i = 0; i < III_CGATE_COUNT; ++i) {
        uint8_t buf[32 + 1 + 1];
        memcpy(buf, req->candidate_source_mhash, 32);
        buf[32] = (uint8_t)i;
        buf[33] = out->gates.passed[i] ? 1u : 0u;
        iii_sha256(buf, sizeof(buf), out->gates.sub_witness[i]);
    }

    if (!iii_cat_gates_all_passed(&out->gates)) {
        out->flag = III_CAT_DF_UNSAFE_REJECTED;
        c->witness_count++;
        return;
    }

    out->flag = req->semantic_baseline_match ? III_CAT_DF_SAFE_APPROVED : III_CAT_DF_SAFE_FLAGGED;
    out->ring = req->target_ring;
    out->promoted = true;

    /* Increment per-category counter */
    switch (req->kind) {
        case III_CAT_CYCLE:               c->cycle_count++; break;
        case III_CAT_PHASE:               c->phase_count++; break;
        case III_CAT_MODULE_FUSION:       c->module_count++; break;
        case III_CAT_KEYWORD:             c->keyword_count++; break;
        default:                          c->cycle_count++; break;
    }

    /* Promote witness mhash */
    uint8_t buf[32 + 8 + 32 * III_CGATE_COUNT];
    memcpy(buf, req->candidate_source_mhash, 32);
    for (unsigned i = 0; i < 8; ++i) buf[32 + i] = (uint8_t)(c->witness_count >> (i * 8));
    for (unsigned i = 0; i < III_CGATE_COUNT; ++i) {
        memcpy(buf + 40 + i * 32, out->gates.sub_witness[i], 32);
    }
    iii_sha256(buf, sizeof(buf), out->promote_witness_mhash);

    if (c->history_count < III_CAT_HISTORY_MAX) {
        memcpy(c->history[c->history_count].witness_mhash, out->promote_witness_mhash, 32);
        c->history[c->history_count].kind = req->kind;
        c->history[c->history_count].revoked = false;
        c->history_count++;
    }
    c->promotion_count++;
    c->witness_count++;
}
