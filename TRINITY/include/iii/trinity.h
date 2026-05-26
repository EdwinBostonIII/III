/* ============================================================================
 * III-TRINITY — The Trinity Admission Manifold
 * Spec: III-TRINITY.md  (Doc-ID A9, R1.A9)
 *
 * Three-layer ceiling: SCBA bit-test → ACC Wall-Y composed-delta → full Trinity
 * (intent × cap × causality × sanctum-state).  Plus predictive caching
 * (item §3), epistemic escalation (§4), Möbius-coherence governance (§5),
 * Catalyst-promoted predicate refinement (§6), ghost mode (§7), and dynamic
 * layer activation (§8).
 * ============================================================================
 */
#ifndef III_TRINITY_H
#define III_TRINITY_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ----------------------------------------------------------------------------
 * §1 — three-layer ceiling
 * ---------------------------------------------------------------------------- */
typedef enum iii_trinity_layer {
    III_LAYER_NONE      = 0,
    III_LAYER_SCBA      = 1,    /* Layer 1: bit-test */
    III_LAYER_ACC       = 2,    /* Layer 2: composed-delta admit */
    III_LAYER_TRINITY   = 3     /* Layer 3: full 4-conjunct */
} iii_trinity_layer_t;

const char *iii_trinity_layer_name(iii_trinity_layer_t l);

/* ----------------------------------------------------------------------------
 * §2 — failure-mode error codes
 * ---------------------------------------------------------------------------- */
typedef enum iii_trinity_status {
    III_TRIN_OK                        = 0,
    III_TRIN_INTENT_REJECT             = 1,
    III_TRIN_CAP_REJECT                = 2,
    III_TRIN_CAUSALITY_REJECT          = 3,
    III_TRIN_SANCTUM_REJECT            = 4,
    III_TRIN_ACC_WALL_Y_REJECT         = 5,
    III_TRIN_SCBA_BIT_REJECT           = 6,
    III_TRIN_HEXAD_UNREPRESENTABLE     = 7,
    III_TRIN_MOBIUS_COHERENCE_FAIL     = 8,
    III_TRIN_CEILING_VIOLATION         = 9,
    III_TRIN_EPISTEMIC_LOW_CONFIDENCE  = 10,
    III_TRIN_WAAC_VIOLATION            = 11,
    III_TRIN_INVALID                   = 12
} iii_trinity_status_t;

const char *iii_trinity_status_name(iii_trinity_status_t s);

/* ----------------------------------------------------------------------------
 * §1.3 — convergence point: records which layer admitted, which conjuncts
 * contributed, and the witness mhashes.
 * ---------------------------------------------------------------------------- */
typedef struct iii_convergence_point {
    iii_trinity_layer_t  admitting_layer;
    bool                 intent_passed;
    bool                 cap_passed;
    bool                 causality_passed;
    bool                 sanctum_passed;
    uint16_t             coherence_q14;
    uint64_t             tuple_hash;        /* §3 cache key */
    uint8_t              convergence_mhash[32];
} iii_convergence_point_t;

/* ----------------------------------------------------------------------------
 * Layer-1 SCBA — 65,536-bit bitarray (8 KiB).
 *
 * The bit index for a reduction is the first 16 bits of BLAKE3 over the
 * canonical byte form of the reduction's post-state; we model the bitarray
 * here and let the caller supply the bit index.
 * ---------------------------------------------------------------------------- */
#define III_SCBA_BITS    65536u
#define III_SCBA_BYTES   (III_SCBA_BITS / 8u)

typedef struct iii_scba_bitarray {
    uint8_t bits[III_SCBA_BYTES];
} iii_scba_bitarray_t;

void iii_scba_init(iii_scba_bitarray_t *s);
void iii_scba_bit_set(iii_scba_bitarray_t *s, uint16_t bit);
void iii_scba_bit_clear(iii_scba_bitarray_t *s, uint16_t bit);
bool iii_scba_bit_test(const iii_scba_bitarray_t *s, uint16_t bit);

/* ----------------------------------------------------------------------------
 * Layer-2 ACC Wall-Y — composed delta admit.
 *
 * The composed delta is a Z₃⁶ tuple (six trits, each 0/1/2 = NEG/ZERO/POS).
 * Admit iff every pillar is in {ZERO, POS} and the bitmap-level admit-set
 * accepts the tuple.
 * ---------------------------------------------------------------------------- */
typedef struct iii_acc_delta {
    uint8_t pillars[6];   /* 0=NEG, 1=ZERO, 2=POS */
} iii_acc_delta_t;

bool iii_acc_wall_y_admit(const iii_acc_delta_t *delta);

/* ----------------------------------------------------------------------------
 * Layer-3 Trinity gate.
 * ---------------------------------------------------------------------------- */
typedef struct iii_trinity_input {
    /* Conjunct evidence — caller asserts these are valid via the bool fields */
    bool      intent_valid;
    bool      cap_valid;
    bool      causality_valid;
    bool      sanctum_state_valid;
    /* Identifying material that contributes to the convergence-point hash */
    uint64_t  intent_id;
    uint64_t  cap_id;
    uint64_t  causality_id;
    uint64_t  sanctum_frame_id;

    /* Hexad (composed delta) for ACC layer */
    iii_acc_delta_t        composed_delta;

    /* SCBA bit index for Layer 1 */
    uint16_t  scba_bit;

    /* Möbius coherence projection (post-state) */
    uint16_t  projected_coherence_q14;
    uint16_t  coherence_floor_q14;

    /* Epistemic uncertainty (§4) */
    bool      uncertainty_present;
    uint16_t  confidence_q14;
    uint16_t  confidence_threshold_q14;

    /* Ghost mode (§7) */
    bool      ghost;
} iii_trinity_input_t;

#define III_TRINITY_DEFAULT_FLOOR_Q14            ((uint16_t)15073u)  /* 0.92 * 16384 */
#define III_TRINITY_DEFAULT_CONFIDENCE_Q14_THRESHOLD  ((uint16_t)13927u) /* 0.85 * 16384 */

/* Sentinel intent_id that encodes an explicit operator-confirmation, allowing
 * the epistemic-escalation soft-reject in iii_trinity_admit() to be overridden
 * (the operator has affirmatively confirmed an uncertain decision). The
 * mnemonic encodes "C0NF" (confirmation). Documented in III-TRINITY.md §4.
 * (RITCHIE Stage 1.11: promoted from a bare 0xC0FFEE0C0u literal at
 * trinity.c:302 to this named constant.) */
#define III_TRINITY_OPERATOR_CONFIRMATION_INTENT_ID  (0xC0FFEE0C0u)

void iii_trinity_input_init_defaults(iii_trinity_input_t *in);

/* ----------------------------------------------------------------------------
 * §3 — predictive trinity cache.  Maps tuple_hash → admit/deny/escalate.
 * ---------------------------------------------------------------------------- */
typedef enum iii_predictive_outcome {
    III_PRED_NONE     = 0,
    III_PRED_ADMIT    = 1,
    III_PRED_DENY     = 2,
    III_PRED_ESCALATE = 3
} iii_predictive_outcome_t;

typedef struct iii_trinity_runtime iii_trinity_runtime_t;

iii_trinity_runtime_t *iii_trinity_runtime_create(void);
void iii_trinity_runtime_destroy(iii_trinity_runtime_t *rt);

/* §1.1 — register a pre-approved post-state in the SCBA */
void iii_trinity_runtime_scba_set(iii_trinity_runtime_t *rt, uint16_t bit);
void iii_trinity_runtime_scba_clear(iii_trinity_runtime_t *rt, uint16_t bit);

/* §3 — record a tuple's outcome in the predictive cache */
void iii_trinity_runtime_cache(iii_trinity_runtime_t *rt,
                               uint64_t                tuple_hash,
                               iii_predictive_outcome_t outcome);

iii_predictive_outcome_t iii_trinity_runtime_lookup(const iii_trinity_runtime_t *rt,
                                                    uint64_t                       tuple_hash);

/* §6 — record a Catalyst-promoted predicate refinement */
typedef bool (*iii_trinity_conjunct_fn)(uint64_t id, void *user);

void iii_trinity_runtime_promote_intent_admit(iii_trinity_runtime_t   *rt,
                                              iii_trinity_conjunct_fn  fn,
                                              void                    *user);
void iii_trinity_runtime_promote_cap_admit(iii_trinity_runtime_t   *rt,
                                           iii_trinity_conjunct_fn  fn,
                                           void                    *user);
void iii_trinity_runtime_promote_causality_admit(iii_trinity_runtime_t   *rt,
                                                 iii_trinity_conjunct_fn  fn,
                                                 void                    *user);
void iii_trinity_runtime_promote_sanctum_admit(iii_trinity_runtime_t   *rt,
                                               iii_trinity_conjunct_fn  fn,
                                               void                    *user);

/* §8 — dynamic layer activation: the runtime tracks current risk-q14 and
 * exposes which layers are active.  The `iii_trinity_admit` call uses these
 * to short-circuit when only Layer 1 is active. */
void iii_trinity_runtime_set_risk(iii_trinity_runtime_t *rt, uint16_t risk_q14);
uint16_t iii_trinity_runtime_risk(const iii_trinity_runtime_t *rt);
iii_trinity_layer_t iii_trinity_runtime_min_layer(const iii_trinity_runtime_t *rt);

/* ----------------------------------------------------------------------------
 * §1 — the admission entry point.  Evaluates layers in order; returns the
 * status (OK or specific reject) and fills in the convergence point.
 * ---------------------------------------------------------------------------- */
iii_trinity_status_t iii_trinity_admit(iii_trinity_runtime_t       *rt,
                                       const iii_trinity_input_t   *in,
                                       iii_convergence_point_t     *out_cp);

/* §3 — the predictive admit fast path.  Looks up the tuple hash and either
 * returns OK/REJECT immediately or escalates to full admit. */
iii_trinity_status_t iii_trinity_predictive_admit(iii_trinity_runtime_t      *rt,
                                                  const iii_trinity_input_t   *in,
                                                  iii_convergence_point_t     *out_cp);

/* §7 — ghost-mode admit. Same evaluation; returns whether it would have
 * admitted but never commits any state.  Indistinguishable in semantics from
 * iii_trinity_admit when in->ghost is true. */
iii_trinity_status_t iii_trinity_ghost_admit(iii_trinity_runtime_t       *rt,
                                             const iii_trinity_input_t   *in,
                                             iii_convergence_point_t     *out_cp);

/* §6 — emit a TRINITY_PROMOTE witness when a predicate is upgraded. */
typedef enum iii_trinity_witness_kind {
    III_TRIN_W_NONE                  = 0,
    III_TRIN_W_TRINITY_REJECT        = 0x0AA0,
    III_TRIN_W_TRINITY_PROMOTE       = 0x0AA1,
    III_TRIN_W_GHOST_ADMIT           = 0x0AA2,
    III_TRIN_W_LAYER_ESCALATE        = 0x0AA3
} iii_trinity_witness_kind_t;

const char *iii_trinity_witness_kind_name(iii_trinity_witness_kind_t k);

uint64_t iii_trinity_runtime_witness_count(const iii_trinity_runtime_t *rt);

#ifdef __cplusplus
}
#endif

#endif /* III_TRINITY_H */
