/* ============================================================================
 * III-OBSERVABILITY — Always-Available System Information
 * Spec: III-OBSERVABILITY.md  (Wave 2.1)
 *
 * Per Stateful Neumann §3.4 / S15, the OBSERVATORY plane vanishes as a
 * separate subsystem and its functionality moves inline into the cycle
 * dispatcher.  This module owns:
 *
 *   §1 — the OBSERVATORY collapse: per-cycle saturation evaluation hooks
 *   §2 — the 12-family threshold library
 *   §3 — saturation predicates as first-class effects
 *   §4 — the State surface (always-available system info, O(1) reads)
 *   §5 — WLISHI live introspection
 *   §6 — system-wide health metrics
 *   §7 — operator query API
 * ============================================================================
 */
#ifndef III_OBSERVABILITY_H
#define III_OBSERVABILITY_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ----------------------------------------------------------------------------
 * Q14 fixed-point — Q14_ONE = 16384 = 1.0
 * ---------------------------------------------------------------------------- */
typedef uint32_t iii_q14_t;
#define III_Q14_ONE       16384u
#define III_Q14_FROM_F(x) ((iii_q14_t)((double)(x) * 16384.0 + 0.5))

iii_q14_t iii_q14_mul(iii_q14_t a, iii_q14_t b);
iii_q14_t iii_q14_div(iii_q14_t a, iii_q14_t b);
double    iii_q14_to_double(iii_q14_t x);
iii_q14_t iii_q14_from_double(double x);

/* ----------------------------------------------------------------------------
 * §2 — the 12 threshold families.
 * ---------------------------------------------------------------------------- */
typedef enum iii_threshold_family {
    III_TF_NONE                   = 0,
    III_TF_HOEFFDING              = 1,
    III_TF_MULTINOMIAL            = 2,
    III_TF_WILSON                 = 3,
    III_TF_POISSON                = 4,
    III_TF_COUPON                 = 5,
    III_TF_CMSKETCH               = 6,
    III_TF_ORDER_STAT             = 7,
    III_TF_NYQUIST                = 8,
    III_TF_EFFECTIVE_SAMPLE_SIZE  = 9,
    III_TF_HEAPS                  = 10,
    III_TF_RULE_OF_THREE          = 11,
    III_TF_MULTINOMIAL_DIRICHLET  = 12,
    III_TF_COUNT                  = 13
} iii_threshold_family_t;

const char *iii_threshold_family_name(iii_threshold_family_t f);

/* ----------------------------------------------------------------------------
 * Threshold descriptor.  Each family interprets the parameters its own way.
 * ---------------------------------------------------------------------------- */
typedef struct iii_threshold {
    iii_threshold_family_t family;
    double                 confidence;     /* 0..1 */
    uint32_t               n_min;
    uint32_t               k_categories;
    uint32_t               coupon_k;
    uint32_t               cm_width;
    uint32_t               cm_depth;
    double                 quantile;
    double                 sample_rate;
    double                 signal_band;
    uint32_t               ess_target;
    double                 heaps_alpha;
    double                 heaps_beta;
    double                 dirichlet_prior;
    double                 epsilon;        /* the half-width tolerance */
} iii_threshold_t;

/* Constructors for each family. */
iii_threshold_t iii_th_hoeffding(double confidence, uint32_t n_min);
iii_threshold_t iii_th_multinomial(double confidence, uint32_t n_min, uint32_t k);
iii_threshold_t iii_th_wilson(double confidence, uint32_t n_min);
iii_threshold_t iii_th_poisson(double confidence, uint32_t n_min);
iii_threshold_t iii_th_coupon_collector(uint32_t k, double confidence);
iii_threshold_t iii_th_cmsketch(uint32_t width, uint32_t depth, double confidence);
iii_threshold_t iii_th_order_stat(double quantile, double confidence, uint32_t n_min);
iii_threshold_t iii_th_nyquist(double sample_rate, double signal_band);
iii_threshold_t iii_th_effective_sample_size(uint32_t target);
iii_threshold_t iii_th_heaps(double alpha, double beta, uint32_t n_min);
iii_threshold_t iii_th_rule_of_three(double confidence);
iii_threshold_t iii_th_multinomial_dirichlet(double prior, double confidence);

/* ----------------------------------------------------------------------------
 * Accumulator — per-family running statistics.
 * ---------------------------------------------------------------------------- */
typedef struct iii_accumulator {
    iii_threshold_family_t family;
    /* Counts */
    uint64_t   n;
    double     sum;
    double     sum_sq;
    /* Multinomial / coupon */
    uint64_t   counts[16];     /* up to 16 categories */
    uint8_t    distinct_seen[64]; /* up to 64 coupon types */
    uint32_t   distinct_count;
    /* CM-sketch */
    uint32_t   cm_state[256];  /* width × depth ≤ 256 */
    /* Order-statistic */
    double     samples[256];
    uint32_t   sample_count;
    /* Nyquist - sample_rate, observed signal band */
    double     observed_band;
    /* ESS — sum w, sum w^2 */
    double     ess_sum_w;
    double     ess_sum_wsq;
    /* Heaps — distinct token count */
    uint64_t   heaps_distinct;
    /* Saturation flag */
    bool       saturated;
} iii_accumulator_t;

void iii_accumulator_init(iii_accumulator_t *a, iii_threshold_family_t f);
void iii_accumulator_update_scalar(iii_accumulator_t *a, double sample);
void iii_accumulator_update_int(iii_accumulator_t *a, uint64_t value);
void iii_accumulator_update_category(iii_accumulator_t *a, uint32_t cat);
void iii_accumulator_update_weight(iii_accumulator_t *a, double weight);
void iii_accumulator_update_event(iii_accumulator_t *a); /* for Poisson / RuleOfThree */

bool iii_threshold_is_saturated(const iii_threshold_t   *t,
                                const iii_accumulator_t *a);

/* Composition. */
typedef enum iii_threshold_combinator {
    III_TC_AND   = 0,
    III_TC_OR    = 1,
    III_TC_UNTIL = 2
} iii_threshold_combinator_t;

typedef struct iii_threshold_composed iii_threshold_composed_t;

iii_threshold_composed_t *iii_th_compose(const iii_threshold_t *a,
                                         const iii_threshold_t *b,
                                         iii_threshold_combinator_t op);

bool iii_th_composed_is_saturated(const iii_threshold_composed_t *c,
                                  const iii_accumulator_t        *acc_a,
                                  const iii_accumulator_t        *acc_b);

void iii_th_composed_destroy(iii_threshold_composed_t *c);

/* ----------------------------------------------------------------------------
 * §3 — saturation effect emission.
 * ---------------------------------------------------------------------------- */

#define III_OBS_FLAG_SATURATION_FIRED   (1u << 0)
#define III_OBS_FLAG_QUERY_INITIATED    (1u << 1)
#define III_OBS_FLAG_QUERY_COMPLETED    (1u << 2)
#define III_OBS_FLAG_BACKPRESSURE       (1u << 3)
#define III_OBS_FLAG_HEALTH_DEGRADED    (1u << 4)

typedef struct iii_saturation_event {
    uint32_t                 cycle_kind;      /* user-defined */
    iii_threshold_family_t   family;
    double                   accumulator_value;
    uint8_t                  saturation_witness_mhash[32];
    uint64_t                 timestamp;
} iii_saturation_event_t;

typedef struct iii_observability iii_observability_t;

iii_observability_t *iii_observability_create(void);
void                 iii_observability_destroy(iii_observability_t *o);

/* §1 — register a tracked cycle with @track(...).  Each call binds a
 * (cycle_kind, accumulator, threshold, on_saturation flag) tuple.  Returns
 * the assigned tracker ID (≥ 1) or 0 on failure. */
uint32_t iii_observability_register_track(iii_observability_t *o,
                                          uint32_t              cycle_kind,
                                          iii_threshold_t       th);

/* On every cycle invocation, the dispatcher calls this to update the
 * accumulator with the observed sample.  Returns true if saturation just
 * fired (the on_saturation handler should now be invoked). */
bool iii_observability_observe(iii_observability_t *o,
                               uint32_t              tracker_id,
                               double                sample);

/* Backpressure: pull the next pending saturation event from the queue. */
bool iii_observability_pop_saturation(iii_observability_t    *o,
                                      iii_saturation_event_t *out);

size_t iii_observability_pending_saturations(const iii_observability_t *o);

/* ----------------------------------------------------------------------------
 * §4 — the State surface.
 * ---------------------------------------------------------------------------- */

typedef struct iii_state_surface {
    /* §4.1 fields */
    uint64_t  current_epoch;
    uint8_t   closure_root[32];
    uint8_t   r1_composite_root[32];
    uint64_t  drtm_quote_chain_length;
    uint8_t   anchor_pubkey[32];
    uint64_t  active_cryptographic_suite;
    uint32_t  federation_peer_count;
    uint64_t  audit_chain_height;
    uint8_t   audit_chain_root[32];
    uint32_t  catalyst_promotion_count;
    iii_q14_t mobius_coherence_q14;
    uint32_t  per_cpu_witness_ring_occupancy[16];   /* 0..100 percent */
    uint32_t  current_cycle_rate_per_sec;
    uint64_t  anchor_witness_silence_seconds;
    uint64_t  last_drtm_relaunch_timestamp;
    uint32_t  current_wavefront_size;
    bool      proof_kernel_invariants_held;
    uint32_t  pkru_register_per_cpu[16];
    uint32_t  jit_compiled_cycle_count;
    uint32_t  causal_dag_edge_count;
    uint32_t  pending_amendment_proposals;
    iii_q14_t zk_pruning_compaction_ratio_q14;
    uint32_t  recent_compromise_low;
    uint32_t  recent_compromise_medium;
    uint32_t  recent_compromise_high;
    uint32_t  jit_compilation_success_rate_q14;
    uint32_t  saturation_event_rate_per_sec;
} iii_state_surface_t;

const iii_state_surface_t *iii_observability_state(const iii_observability_t *o);

/* §4 — operator setters (modeling — in real systems these would be updated
 * by per-CPU counters from the dispatcher and other planes). */
void iii_observability_set_state(iii_observability_t        *o,
                                 const iii_state_surface_t  *s);

/* §6 — health-score aggregate (Q14 geometric mean of normalised metrics). */
iii_q14_t iii_observability_health_score(const iii_observability_t *o);

/* ----------------------------------------------------------------------------
 * §7 — query API.
 * ---------------------------------------------------------------------------- */
#define XII_OBSERVABILITY_QUERY_MAX_WITNESSES   1000000u

typedef enum iii_query_kind {
    III_QUERY_NONE                       = 0,
    III_QUERY_CYCLES_IN_EPOCH            = 1,
    III_QUERY_WITNESSES_WITH_FLAG        = 2,
    III_QUERY_SATURATION_EVENTS          = 3,
    III_QUERY_AMENDMENTS                 = 4,
    III_QUERY_CATALYST_PROMOTIONS        = 5,
    III_QUERY_FEDERATION_PEER_STATE      = 6,
    III_QUERY_ANCHOR_WITNESS_CHAIN       = 7
} iii_query_kind_t;

typedef struct iii_query {
    iii_query_kind_t kind;
    uint64_t         epoch_start;
    uint64_t         epoch_end;
    uint32_t         flag;
    uint32_t         cycle_kind;
    bool             operator_consent_for_large_query;
} iii_query_t;

typedef enum iii_query_status {
    III_QUERY_OK                 = 0,
    III_QUERY_E_TOO_LARGE        = 1,    /* exceeds XII_OBSERVABILITY_QUERY_MAX_WITNESSES */
    III_QUERY_E_INVALID          = 2,
    III_QUERY_E_PLAN_REJECTED    = 3,
    III_QUERY_E_BUDGET           = 4
} iii_query_status_t;

typedef struct iii_query_result {
    uint64_t scanned_witnesses;
    uint64_t matched_witnesses;
    uint8_t  result_mhash[32];
} iii_query_result_t;

iii_query_status_t iii_observability_query(iii_observability_t        *o,
                                           const iii_query_t          *q,
                                           iii_query_result_t         *out);

uint64_t iii_observability_query_count(const iii_observability_t *o);

/* ----------------------------------------------------------------------------
 * §5 — WLISHI command parsing (string commands → query results).
 * ---------------------------------------------------------------------------- */
typedef enum iii_wlishi_cmd_kind {
    III_WLISHI_NONE                        = 0,
    III_WLISHI_STATE_QUERY                 = 1,
    III_WLISHI_HEALTH                      = 2,
    III_WLISHI_AUDIT_REPLAY                = 3,
    III_WLISHI_CAUSAL_EXPLAIN              = 4,
    III_WLISHI_COUNTERFACTUAL_RUN          = 5,
    III_WLISHI_CATALYST_AUDIT              = 6
} iii_wlishi_cmd_kind_t;

typedef struct iii_wlishi_cmd {
    iii_wlishi_cmd_kind_t kind;
    char                  arg[256];
} iii_wlishi_cmd_t;

bool iii_wlishi_parse(const char *line, iii_wlishi_cmd_t *out);

const char *iii_query_status_name(iii_query_status_t s);

#ifdef __cplusplus
}
#endif

#endif /* III_OBSERVABILITY_H */
