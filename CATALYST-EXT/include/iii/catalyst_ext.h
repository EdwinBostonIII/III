/* ============================================================================
 * III-CATALYST-EXT — Catalyst Extensions
 * Spec: III-CATALYST-EXT.md  (Wave 8, items 72-78)
 *
 * Causal-DAG-driven hypothesis synthesis, counterfactual replay,
 * composite-cycle promotion gates, rate-cap discipline, Möbius coherence
 * monitoring, Founder's Anchor restraint, JIT integration.
 * ============================================================================
 */
#ifndef III_CATALYST_EXT_H
#define III_CATALYST_EXT_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

/* Hexad arithmetic (Z_3^6 component-wise sum) lives in PERFORMANCE. */
#include "iii/performance.h"

#ifdef __cplusplus
extern "C" {
#endif

/* §1 — causal DAG */
#define III_CDAG_NODES_MAX  256u
#define III_CDAG_EDGES_MAX  4096u

typedef struct iii_cdag_node {
    uint16_t cycle_kind;
    uint64_t observed;
} iii_cdag_node_t;

typedef struct iii_cdag_edge {
    uint16_t from;
    uint16_t to;
    uint16_t confidence_q14;
    uint64_t frequency;
    uint32_t mean_latency_us;
} iii_cdag_edge_t;

typedef struct iii_cdag iii_cdag_t;

iii_cdag_t *iii_cdag_create(void);
void        iii_cdag_destroy(iii_cdag_t *d);

bool iii_cdag_observe(iii_cdag_t *d, uint16_t from, uint16_t to, uint32_t latency_us);
bool iii_cdag_get_edge(const iii_cdag_t *d, uint16_t from, uint16_t to, iii_cdag_edge_t *out);
size_t iii_cdag_edge_count(const iii_cdag_t *d);

/* §1.3 — synthesizer floor */
#define XII_CATALYST_SYNTHESIS_CONFIDENCE_FLOOR  ((uint16_t)13107u)  /* 0.80 q14 */

/* §3 — composite candidate.  composed_hexad is the real Z_3^6 sum of the
 * two source-cycle hexads; admit_slot is its packed 12-bit admit-bitmap
 * index (2 bits per pillar). */
typedef struct iii_composite_candidate {
    uint64_t            candidate_id;
    uint16_t            c1_kind;
    uint16_t            c2_kind;
    iii_hexad_z3_6_t    composed_hexad;          /* Z_3^6 component-wise sum */
    uint16_t            composed_hexad_admit;    /* 12-bit packed admit slot */
    uint16_t            derived_confidence_q14;
    uint8_t             forward_mhash[32];
    uint8_t             inverse_mhash[32];
    uint8_t             synthesis_witness_mhash[32];
} iii_composite_candidate_t;

/* §3.1 — promotion gates (8 of them — distinct from CATALYST's 8 different gates) */
typedef enum iii_cext_gate {
    III_CXG_ANCHOR_RESTRAINT       = 0,
    III_CXG_HEXAD_ADMIT            = 1,
    III_CXG_SID_INVERSE            = 2,
    III_CXG_COUNTERFACTUAL_REPLAY  = 3,
    III_CXG_COHERENCE_FLOOR        = 4,
    III_CXG_RATE_CAP               = 5,
    III_CXG_TRINITY                = 6,
    III_CXG_ANCHOR_COSIGNATURE     = 7,
    III_CXG_COUNT                  = 8
} iii_cext_gate_t;

const char *iii_cext_gate_name(iii_cext_gate_t g);

typedef struct iii_cext_gates {
    bool passed[III_CXG_COUNT];
} iii_cext_gates_t;

/* §4 rate-cap constants */
#define XII_MNEME_CATALYST_PROMOTION_PER_TICK_MAX   8u
#define XII_MNEME_CATALYST_PROMOTION_PER_EPOCH_MAX  1024u
#define XII_MNEME_COHERENCE_FLOOR_Q14               12288u  /* 0.75 q14 */

/* §2 counterfactual replay */
typedef enum iii_cext_replay_status {
    III_CXR_VERIFIED               = 0,
    III_CXR_FAILED_DIVERGENCE      = 1,
    III_CXR_FAILED_OUTPUT          = 2,
    III_CXR_FAILED_AUDIT_HASH      = 3
} iii_cext_replay_status_t;

const char *iii_cext_replay_status_name(iii_cext_replay_status_t s);

typedef struct iii_cext_replay_input {
    iii_composite_candidate_t candidate;
    uint64_t                  witness_range_start;   /* min cycle_seq */
    uint64_t                  witness_range_end;     /* max cycle_seq */
    /* Reference outputs the candidate is expected to produce.  Replay walks
     * the BCWL chain in [start, end], recomputes the audit hash, and compares
     * the rolled SHA-256 against expected_audit_hash. */
    uint8_t                   expected_audit_hash[32];
    uint8_t                   expected_output_hash[32];
    uint8_t                   expected_observability_hash[32];
    /* Optional: caller's measured divergence (Q14, scaled 1.0 = 16384). */
    uint16_t                  divergence_score_q14;
} iii_cext_replay_input_t;

typedef struct iii_cext_replay_result {
    iii_cext_replay_status_t  status;
    uint16_t                  divergence_score_q14;
    uint8_t                   witness_mhash[32];
    uint8_t                   computed_audit_hash[32];
    uint32_t                  visited_count;
} iii_cext_replay_result_t;

/* Walks the BCWL chain in [witness_range_start, witness_range_end] (inclusive
 * cycle_seq), re-derives the audit hash by SHA-256-rolling each witness's
 * canonical 128-byte encoding, and compares against expected_audit_hash.  If
 * `bcwl` is NULL or no witnesses are visited, returns III_CXR_FAILED_AUDIT_HASH.
 *
 * The output_hash and observability_hash are checked when non-zero in the
 * input; an all-zero expected hash skips that check (allows partial replay). */
struct iii_bcwl;
void iii_cext_counterfactual_replay(const struct iii_bcwl         *bcwl,
                                    const iii_cext_replay_input_t *in,
                                    iii_cext_replay_result_t      *out);

/* §6 — Anchor restraint check */
typedef struct iii_cext_anchor_check {
    bool modifies_anchor_pubkey;
    bool modifies_anchor_fingerprint;
    bool removes_amend_apply_anchor_requirement;
    bool disables_pfk_anchor_invariant;
    bool synthesizes_substitute_anchor;
    bool weakens_anchor_authority_semantically;
} iii_cext_anchor_check_t;

bool iii_cext_filter_for_anchor(const iii_cext_anchor_check_t *check);

/* §6.4 attack pattern detection */
typedef struct iii_cext_rejection_log {
    uint64_t total_rejections;
    uint64_t anchor_rejections;
} iii_cext_rejection_log_t;

bool iii_cext_anchor_attack_pattern(const iii_cext_rejection_log_t *log);

/* §3 — promotion request */
typedef struct iii_cext_promotion_request {
    iii_composite_candidate_t candidate;
    bool                      hexad_admissible;
    bool                      sid_inverse_derivable;
    iii_cext_replay_status_t  replay_status;
    uint16_t                  predicted_coherence_q14;
    bool                      trinity_admitted;
    bool                      anchor_cosigned;
    iii_cext_anchor_check_t   anchor_check;
    uint8_t                   tier;     /* 0..3 */
} iii_cext_promotion_request_t;

typedef struct iii_cext_promotion_outcome {
    iii_cext_gates_t gates;
    bool             promoted;
    uint8_t          promote_witness_mhash[32];
    uint8_t          rejection_witness_mhash[32];
    iii_cext_gate_t  failed_gate;
} iii_cext_promotion_outcome_t;

/* §7 — JIT */
typedef enum iii_cext_arch {
    III_CXA_X86_64    = 0,
    III_CXA_ARMV8     = 1,
    III_CXA_RISCV64   = 2
} iii_cext_arch_t;

const char *iii_cext_arch_name(iii_cext_arch_t a);

typedef struct iii_cext_jit_record {
    uint64_t       cycle_id;
    iii_cext_arch_t arch;
    uint32_t       machine_code_size;
    uint8_t        machine_code_mhash[32];
    bool           deoptimised;
} iii_cext_jit_record_t;

/* ----------------------------------------------------------------------------
 * Runtime
 * ---------------------------------------------------------------------------- */
typedef struct iii_cext_runtime iii_cext_runtime_t;

iii_cext_runtime_t *iii_cext_runtime_create(void);
void                iii_cext_runtime_destroy(iii_cext_runtime_t *rt);

/* §1 — synthesise a candidate from a high-confidence causal-DAG edge.
 *
 * The caller supplies the two source cycles' hexads (h_from, h_to); the
 * synthesizer composes them via Z_3^6 component-wise sum (HEXAD §1.2) and
 * derives the admit-slot bitmap.  Forward / inverse / synthesis witness
 * mhashes are computed from the canonical encoding of the composition. */
bool iii_cext_synthesize(iii_cext_runtime_t            *rt,
                         const iii_cdag_edge_t         *edge,
                         const iii_hexad_z3_6_t        *h_from,
                         const iii_hexad_z3_6_t        *h_to,
                         iii_composite_candidate_t     *out);

/* §3 — propose+validate a candidate's promotion */
void iii_cext_propose(iii_cext_runtime_t                  *rt,
                      const iii_cext_promotion_request_t  *req,
                      iii_cext_promotion_outcome_t        *out);

/* §4 — chronos tick */
void     iii_cext_runtime_tick(iii_cext_runtime_t *rt);
uint32_t iii_cext_promotions_this_tick(const iii_cext_runtime_t *rt);
uint64_t iii_cext_promotions_this_epoch(const iii_cext_runtime_t *rt);

/* §5 — coherence monitoring */
void iii_cext_record_coherence(iii_cext_runtime_t *rt, uint64_t cycle_id, uint16_t coherence_q14);
bool iii_cext_should_depromote(iii_cext_runtime_t *rt, uint64_t cycle_id);
bool iii_cext_depromote(iii_cext_runtime_t *rt, uint64_t cycle_id);

/* §6 — synthesis halt on anchor-attack alarm */
bool iii_cext_synthesis_halted(const iii_cext_runtime_t *rt);
void iii_cext_resume_synthesis(iii_cext_runtime_t *rt);
uint64_t iii_cext_anchor_alarm_count(const iii_cext_runtime_t *rt);

/* §7 — JIT compile + de-optimise */
bool iii_cext_jit_compile(iii_cext_runtime_t *rt,
                          uint64_t            cycle_id,
                          iii_cext_arch_t     arch,
                          uint32_t            code_size,
                          iii_cext_jit_record_t *out);
bool iii_cext_jit_deoptimize(iii_cext_runtime_t *rt, uint64_t cycle_id);
size_t iii_cext_jit_record_count(const iii_cext_runtime_t *rt);

/* §3 — operator audit */
typedef struct iii_cext_audit_summary {
    uint64_t total_proposals;
    uint64_t promotions;
    uint64_t rejections;
    uint64_t anchor_rejections;
    uint64_t replay_failures;
    uint64_t coherence_failures;
} iii_cext_audit_summary_t;

void iii_cext_audit(const iii_cext_runtime_t *rt, iii_cext_audit_summary_t *out);

#ifdef __cplusplus
}
#endif

#endif /* III_CATALYST_EXT_H */
