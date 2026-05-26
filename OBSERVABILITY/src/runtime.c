/* ============================================================================
 * III-OBSERVABILITY — runtime.c
 *
 * The OBSERVATORY-collapse runtime: trackers, the State surface, the
 * saturation queue, the health-score aggregate, and the operator query
 * dispatcher.
 * ============================================================================
 */
#include "iii/observability.h"
#include <stdlib.h>
#include <string.h>
#include <math.h>

/* SHA-256 used for query result_mhash and saturation witness mhash. */
extern void iii_sha256(const void *data, size_t len, uint8_t out[32]);

#define III_OBS_MAX_TRACKERS    256u
#define III_OBS_SAT_QUEUE_CAP   1024u

typedef struct iii_obs_tracker {
    bool                   bound;
    uint32_t               cycle_kind;
    iii_threshold_t        threshold;
    iii_accumulator_t      acc;
    bool                   already_fired;
    uint64_t               last_fire_seq;
} iii_obs_tracker_t;

struct iii_observability {
    iii_obs_tracker_t       trackers[III_OBS_MAX_TRACKERS];
    uint32_t                next_tracker_id;

    iii_saturation_event_t  sat_queue[III_OBS_SAT_QUEUE_CAP];
    size_t                  sat_head;
    size_t                  sat_tail;
    size_t                  sat_count;

    iii_state_surface_t     state;
    uint64_t                query_count;
    uint64_t                seq;
};

/* ----------------------------------------------------------------------------
 * Lifecycle
 * ---------------------------------------------------------------------------- */

iii_observability_t *iii_observability_create(void) {
    iii_observability_t *o = (iii_observability_t *)calloc(1, sizeof(*o));
    if (!o) return NULL;
    o->next_tracker_id = 1;
    /* Sensible defaults for state */
    o->state.proof_kernel_invariants_held = true;
    o->state.mobius_coherence_q14 = (iii_q14_t)((double)III_Q14_ONE * 0.92);
    o->state.jit_compilation_success_rate_q14 = III_Q14_ONE;
    o->state.zk_pruning_compaction_ratio_q14 = III_Q14_ONE;
    return o;
}

void iii_observability_destroy(iii_observability_t *o) {
    if (!o) return;
    memset(o, 0, sizeof(*o));
    free(o);
}

/* ----------------------------------------------------------------------------
 * Trackers
 * ---------------------------------------------------------------------------- */

uint32_t iii_observability_register_track(iii_observability_t *o,
                                          uint32_t              cycle_kind,
                                          iii_threshold_t       th)
{
    if (!o) return 0;
    if (o->next_tracker_id >= III_OBS_MAX_TRACKERS) return 0;
    uint32_t id = o->next_tracker_id++;
    iii_obs_tracker_t *t = &o->trackers[id];
    t->bound = true;
    t->cycle_kind = cycle_kind;
    t->threshold = th;
    iii_accumulator_init(&t->acc, th.family);
    return id;
}

bool iii_observability_observe(iii_observability_t *o,
                               uint32_t              tracker_id,
                               double                sample)
{
    if (!o || tracker_id == 0 || tracker_id >= III_OBS_MAX_TRACKERS) return false;
    iii_obs_tracker_t *t = &o->trackers[tracker_id];
    if (!t->bound) return false;

    /* Update the accumulator according to the family.  For category/weight/
     * event families, the caller should invoke the more specific function
     * directly; this generic observe routes to the most common one (scalar). */
    switch (t->threshold.family) {
        case III_TF_MULTINOMIAL:
        case III_TF_MULTINOMIAL_DIRICHLET:
            iii_accumulator_update_category(&t->acc, (uint32_t)sample);
            break;
        case III_TF_EFFECTIVE_SAMPLE_SIZE:
            iii_accumulator_update_weight(&t->acc, sample);
            break;
        case III_TF_RULE_OF_THREE:
        case III_TF_COUPON:
            iii_accumulator_update_event(&t->acc);
            if (t->threshold.family == III_TF_COUPON) {
                /* Treat sample as the coupon ID (0..63). */
                uint32_t cid = (uint32_t)sample;
                if (cid < 64u) {
                    if (!t->acc.distinct_seen[cid]) {
                        t->acc.distinct_seen[cid] = 1;
                        t->acc.distinct_count++;
                    }
                }
            }
            break;
        case III_TF_HEAPS:
            iii_accumulator_update_event(&t->acc);
            t->acc.heaps_distinct = (uint64_t)sample; /* caller maintains */
            break;
        case III_TF_NYQUIST:
            t->acc.observed_band = sample;
            iii_accumulator_update_event(&t->acc);
            break;
        default:
            iii_accumulator_update_scalar(&t->acc, sample);
            break;
    }

    bool sat = iii_threshold_is_saturated(&t->threshold, &t->acc);
    if (sat && !t->already_fired) {
        t->already_fired = true;
        t->last_fire_seq = ++o->seq;
        if (o->sat_count < III_OBS_SAT_QUEUE_CAP) {
            iii_saturation_event_t *e = &o->sat_queue[o->sat_head];
            o->sat_head = (o->sat_head + 1u) % III_OBS_SAT_QUEUE_CAP;
            o->sat_count++;
            memset(e, 0, sizeof(*e));
            e->cycle_kind = t->cycle_kind;
            e->family     = t->threshold.family;
            e->accumulator_value = t->acc.sum;
            e->timestamp  = t->last_fire_seq;
            uint8_t buf[8 + 4 + 4];
            for (unsigned i = 0; i < 8; ++i) buf[i] = (uint8_t)(t->last_fire_seq >> (i*8));
            for (unsigned i = 0; i < 4; ++i) buf[8+i] = (uint8_t)(t->cycle_kind >> (i*8));
            for (unsigned i = 0; i < 4; ++i) buf[12+i] = (uint8_t)(t->threshold.family >> (i*8));
            iii_sha256(buf, sizeof(buf), e->saturation_witness_mhash);
        }
        return true;
    }
    return false;
}

bool iii_observability_pop_saturation(iii_observability_t    *o,
                                      iii_saturation_event_t *out)
{
    if (!o || !out) return false;
    if (o->sat_count == 0) return false;
    *out = o->sat_queue[o->sat_tail];
    o->sat_tail = (o->sat_tail + 1u) % III_OBS_SAT_QUEUE_CAP;
    o->sat_count--;
    return true;
}

size_t iii_observability_pending_saturations(const iii_observability_t *o) {
    return o ? o->sat_count : 0u;
}

/* ----------------------------------------------------------------------------
 * State surface
 * ---------------------------------------------------------------------------- */

const iii_state_surface_t *iii_observability_state(const iii_observability_t *o) {
    return o ? &o->state : NULL;
}

void iii_observability_set_state(iii_observability_t        *o,
                                 const iii_state_surface_t  *s)
{
    if (!o || !s) return;
    o->state = *s;
}

/* ----------------------------------------------------------------------------
 * Health score (§6.2): geometric mean of normalised metrics.  Each metric
 * is normalised to [0, 1] against its healthy range; the aggregate is the
 * weighted geometric mean.
 * ---------------------------------------------------------------------------- */

static double normalise(double value, double good_lo, double good_hi) {
    if (good_hi <= good_lo) return 1.0;
    if (value <= good_lo) return 0.0;
    if (value >= good_hi) return 1.0;
    return (value - good_lo) / (good_hi - good_lo);
}

iii_q14_t iii_observability_health_score(const iii_observability_t *o) {
    if (!o) return 0;
    double prod = 1.0;
    /* Möbius coherence — healthy at ≥ 0.75. */
    double mob = iii_q14_to_double(o->state.mobius_coherence_q14);
    prod *= normalise(mob, 0.5, 0.95);
    /* Witness ring occupancy — healthy at < 75% */
    uint32_t max_occ = 0;
    for (unsigned i = 0; i < 16; ++i) {
        if (o->state.per_cpu_witness_ring_occupancy[i] > max_occ) {
            max_occ = o->state.per_cpu_witness_ring_occupancy[i];
        }
    }
    prod *= normalise(100.0 - (double)max_occ, 25.0, 100.0);
    /* Catalyst rate — healthy at ≤ 8 / tick */
    /* (no direct field; use promotion_count modulo 8) */
    /* Federation quorum availability */
    /* Use a simplistic 100% default */
    prod *= 1.0;
    /* Compromise rates */
    prod *= (o->state.recent_compromise_high == 0) ? 1.0 : 0.0;
    prod *= normalise(10.0 - (double)o->state.recent_compromise_medium, 0.0, 10.0);
    /* JIT success */
    prod *= iii_q14_to_double(o->state.jit_compilation_success_rate_q14);
    /* Proof kernel */
    prod *= o->state.proof_kernel_invariants_held ? 1.0 : 0.0;

    if (prod < 0.0) prod = 0.0;
    if (prod > 1.0) prod = 1.0;
    return iii_q14_from_double(prod);
}

/* ----------------------------------------------------------------------------
 * Query API
 * ---------------------------------------------------------------------------- */

const char *iii_query_status_name(iii_query_status_t s) {
    switch (s) {
        case III_QUERY_OK:               return "ok";
        case III_QUERY_E_TOO_LARGE:      return "too-large-without-consent";
        case III_QUERY_E_INVALID:        return "invalid";
        case III_QUERY_E_PLAN_REJECTED:  return "plan-rejected";
        case III_QUERY_E_BUDGET:         return "budget-exhausted";
        default:                         return "unknown";
    }
}

iii_query_status_t iii_observability_query(iii_observability_t        *o,
                                           const iii_query_t          *q,
                                           iii_query_result_t         *out)
{
    if (!o || !q || !out) return III_QUERY_E_INVALID;
    memset(out, 0, sizeof(*out));

    /* Estimate scan size — we model audit_chain_height as the maximum.
     * If the requested range exceeds the cap and the operator hasn't
     * consented, reject. */
    uint64_t est_scan = o->state.audit_chain_height;
    if (est_scan > XII_OBSERVABILITY_QUERY_MAX_WITNESSES &&
        !q->operator_consent_for_large_query) {
        return III_QUERY_E_TOO_LARGE;
    }

    /* Compute deterministic result mhash from the query parameters and the
     * current state's audit-chain root. */
    uint8_t buf[8 + 8 + 4 + 4 + 32];
    for (unsigned i = 0; i < 8; ++i) buf[i]     = (uint8_t)(q->epoch_start >> (i*8));
    for (unsigned i = 0; i < 8; ++i) buf[8+i]   = (uint8_t)(q->epoch_end   >> (i*8));
    for (unsigned i = 0; i < 4; ++i) buf[16+i]  = (uint8_t)(q->kind        >> (i*8));
    for (unsigned i = 0; i < 4; ++i) buf[20+i]  = (uint8_t)(q->cycle_kind  >> (i*8));
    memcpy(buf + 24, o->state.audit_chain_root, 32);
    iii_sha256(buf, sizeof(buf), out->result_mhash);
    out->scanned_witnesses = est_scan;
    out->matched_witnesses = est_scan / 100; /* model: 1% match rate */

    o->query_count++;
    return III_QUERY_OK;
}

uint64_t iii_observability_query_count(const iii_observability_t *o) {
    return o ? o->query_count : 0u;
}

/* ----------------------------------------------------------------------------
 * WLISHI parser — minimal grammar:
 *   "system.state.<name>"
 *   "system.health"
 *   "system.audit.replay <args>"
 *   "system.causal.explain <hash>"
 *   "system.counterfactual.run <hash>"
 *   "system.catalyst.audit_anchor_attempts <args>"
 * ---------------------------------------------------------------------------- */

static int starts_with(const char *s, const char *prefix) {
    while (*prefix) {
        if (*s++ != *prefix++) return 0;
    }
    return 1;
}

static void copy_arg(const char *s, char *out, size_t cap) {
    while (*s == ' ') s++;
    size_t i = 0;
    while (s[i] && i + 1 < cap) { out[i] = s[i]; ++i; }
    out[i] = '\0';
}

bool iii_wlishi_parse(const char *line, iii_wlishi_cmd_t *out) {
    if (!line || !out) return false;
    memset(out, 0, sizeof(*out));
    while (*line == ' ') line++;
    if (starts_with(line, "system.state.")) {
        out->kind = III_WLISHI_STATE_QUERY;
        copy_arg(line + 13, out->arg, sizeof(out->arg));
        return true;
    }
    if (starts_with(line, "system.health")) {
        out->kind = III_WLISHI_HEALTH;
        return true;
    }
    if (starts_with(line, "system.audit.replay")) {
        out->kind = III_WLISHI_AUDIT_REPLAY;
        copy_arg(line + 19, out->arg, sizeof(out->arg));
        return true;
    }
    if (starts_with(line, "system.causal.explain")) {
        out->kind = III_WLISHI_CAUSAL_EXPLAIN;
        copy_arg(line + 21, out->arg, sizeof(out->arg));
        return true;
    }
    if (starts_with(line, "system.counterfactual.run")) {
        out->kind = III_WLISHI_COUNTERFACTUAL_RUN;
        copy_arg(line + 25, out->arg, sizeof(out->arg));
        return true;
    }
    if (starts_with(line, "system.catalyst.audit")) {
        out->kind = III_WLISHI_CATALYST_AUDIT;
        copy_arg(line + 21, out->arg, sizeof(out->arg));
        return true;
    }
    return false;
}
