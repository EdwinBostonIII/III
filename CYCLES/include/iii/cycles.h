/* ============================================================================
 * III-CYCLES — The Cycle Calculus of III
 * Document: III-CYCLES.md  (Doc-ID A5, R1.A5)
 *
 * The Cycle is the atom of computation in III: a witnessed, reversible,
 * hexad-typed, phase-polymorphic, epistemically-aware mathematical object.
 *
 * This module owns:
 *   §2 — the Reduction six-tuple value (Cycle-Intro rule)
 *   §3 — SID (the 17 SE kinds + 32-step type-check classifier)
 *   §4 — XiiWitness emission (128-byte layout, 8-step protocol, BCWL)
 *   §5 — the live cycle table with 8 structural invariants
 *   §6 — self-modifying cycles (Catalyst promotion, rate cap)
 *   §7 — invocation, content-addressed dispatch, inverse replay
 *   §8 — wavefront composition
 * ============================================================================
 */
#ifndef III_CYCLES_H
#define III_CYCLES_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ----------------------------------------------------------------------------
 * §3.1 — The 17 SE kinds (the only privileged write classifications).
 * Every IRPD method invocation in a `forward` body is classified into
 * exactly one of these. Any other privileged operation is `PARSE-IRPD-001`.
 * ---------------------------------------------------------------------------- */

typedef enum iii_se_kind {
    III_SE_NONE             = 0x00,
    III_SE_MSR_WRITE        = 0x01,
    III_SE_CR_WRITE         = 0x02,
    III_SE_NPT_ENTRY_WRITE  = 0x03,
    III_SE_VMCB_FIELD_WRITE = 0x04,
    III_SE_IOMMU_DTE_WORD   = 0x05,
    III_SE_AVIC_TBL_WRITE   = 0x06,
    III_SE_MSRPM_BIT_SET    = 0x07,
    III_SE_IOPM_BIT_SET     = 0x08,
    III_SE_PKRU_WRITE       = 0x09,
    III_SE_XCR0_WRITE       = 0x0A,
    III_SE_CAP_ACQUIRE      = 0x0B,
    III_SE_CAP_RELEASE      = 0x0C,
    III_SE_PAGE_ALLOC       = 0x0D,
    III_SE_PAGE_FREE        = 0x0E,
    III_SE_DPC_ARM          = 0x0F,
    III_SE_DPC_CANCEL       = 0x10,
    III_SE_NMI_INSTALL      = 0x11,
    III_SE_COUNT            = 0x12  /* one past the last */
} iii_se_kind_t;

const char *iii_se_kind_name(iii_se_kind_t k);

/* §1.2 — Compromise tiers for explicitly-irreversible cycles. */
typedef enum iii_compromise_tier {
    III_COMPROMISE_NONE      = 0,
    III_COMPROMISE_LOW       = 1,
    III_COMPROMISE_MEDIUM    = 2,
    III_COMPROMISE_HIGH      = 3
} iii_compromise_tier_t;

const char *iii_compromise_tier_name(iii_compromise_tier_t t);

/* ----------------------------------------------------------------------------
 * §5.3 — Reserved step_kind bands (canonical allocation table).
 *
 * Defined as inclusive [start, end] ranges; band-name strings exposed for
 * tooling.  Total allocated: 512 slots. The spec's allocations are reproduced
 * exactly here; iii_step_kind_band() classifies a 16-bit step_kind into a
 * band for BCWL skip-list indexing.
 * ---------------------------------------------------------------------------- */

typedef enum iii_step_kind_band {
    III_BAND_RESERVED_BOOT          = 0,
    III_BAND_IRPD_PRIVILEGED_WRITE  = 1,
    III_BAND_IRPD_PRIVILEGED_READ   = 2,
    III_BAND_CYCLE_LIFECYCLE        = 3,
    III_BAND_WAVEFRONT              = 4,
    III_BAND_SANCTUM                = 5,
    III_BAND_TRINITY                = 6,
    III_BAND_CEILING                = 7,
    III_BAND_FEDERATION             = 8,
    III_BAND_DRTM                   = 9,
    III_BAND_VDF                    = 10,
    III_BAND_OBSERVATORY            = 11,
    III_BAND_CATALYST               = 12,
    III_BAND_NARRATIVE              = 13,
    III_BAND_COGNITIVE              = 14,
    III_BAND_PFS                    = 15,
    III_BAND_FEDERATION_RESERVED    = 16,
    III_BAND_USER_RESERVED          = 17,
    III_BAND_MNEME_CATALYST_PROMOTE = 18,
    III_BAND_RESERVED_FUTURE        = 19,
    III_BAND_UNKNOWN                = 20,
    III_BAND_COUNT                  = 21
} iii_step_kind_band_t;

iii_step_kind_band_t iii_step_kind_band(uint16_t step_kind);
const char          *iii_step_kind_band_name(iii_step_kind_band_t band);
void                 iii_step_kind_band_range(iii_step_kind_band_t band,
                                              uint16_t *out_lo,
                                              uint16_t *out_hi);

/* ----------------------------------------------------------------------------
 * §3 — SID (Side-effect Inverse Derivation), the type-level classifier.
 * The 32-step plan is enumerated here as named steps; iii_sid_run() executes
 * them sequentially against an iii_sid_input_t and produces an iii_sid_output_t
 * whose `failure_step` field is non-zero on rejection.
 * ---------------------------------------------------------------------------- */

typedef enum iii_sid_step {
    III_SID_NONE                       = 0,
    III_SID_WALK_AST                   = 1,
    III_SID_CLASSIFY_KINDS             = 2,
    III_SID_CAPTURE_PRIOR              = 3,
    III_SID_CONSTRUCT_INVERSE_RECORD   = 4,
    III_SID_VERIFY_ROUNDTRIP           = 5,
    III_SID_COMPOSE_HEXAD              = 6,
    III_SID_EMIT_INVERSE_REDUCTION     = 7,
    III_SID_REGISTER_TABLE             = 8,
    III_SID_THREAD_WITNESS             = 9,
    III_SID_PIP_CLASSIFY               = 10,
    III_SID_CHECK_COHERENCE            = 11,
    III_SID_TRINITY_DISCHARGE          = 12,
    III_SID_CEILING_MEMBERSHIP         = 13,
    III_SID_ALLOCATE_STEP_KIND         = 14,
    III_SID_BIND_PLAN_ANCHOR           = 15,
    III_SID_FEDERATION_TIER            = 16,
    III_SID_EPOCH_CONSISTENCY          = 17,
    III_SID_GLYPH_DRIFT                = 18,
    III_SID_EPISTEMIC_CLASSIFY         = 19,
    III_SID_GHOST_METADATA             = 20,
    III_SID_HOT_PATH_HINT              = 21,
    III_SID_EMIT_DESCRIPTOR            = 22,
    III_SID_OBSERVATORY_REGISTER       = 23,
    III_SID_VERIFY_NO_RAW_PRIVILEGED   = 24,
    III_SID_RING_MARSHAL_CHECK         = 25,
    III_SID_CAP_BALANCE                = 26,
    III_SID_EMIT_REPLAY_PLAN           = 27,
    III_SID_CONSTITUTIONAL_MANIFEST    = 28,
    III_SID_WAAC_CHECK                 = 29,
    III_SID_FINAL_REDUCTION            = 30,
    III_SID_RING_BIND                  = 31,
    III_SID_RETURN_TO_TYPECHECKER      = 32,
    III_SID_STEP_COUNT                 = 33   /* one past the last */
} iii_sid_step_t;

const char *iii_sid_step_name(iii_sid_step_t s);

typedef enum iii_sid_error {
    III_SID_OK                         = 0,
    III_SID_E_PARSE_IRPD_001           = 1,
    III_SID_E_TYPE_SID_001             = 2,
    III_SID_E_TYPE_SID_002             = 3,
    III_SID_E_TYPE_SID_003             = 4,
    III_SID_E_TYPE_SID_004             = 5,
    III_SID_E_TYPE_HEXAD_002           = 6,
    III_SID_E_TYPE_SID_005             = 7,
    III_SID_E_TYPE_CYCLE_001           = 8,
    III_SID_E_TYPE_WIT_001             = 9,
    III_SID_E_TYPE_PIP_001             = 10,
    III_SID_E_TYPE_MOB_001             = 11,
    III_SID_E_TYPE_TRIN_001            = 12,
    III_SID_E_TYPE_CEIL_001            = 13,
    III_SID_E_TYPE_WIT_002             = 14,
    III_SID_E_TYPE_PLAN_001            = 15,
    III_SID_E_TYPE_FED_001             = 16,
    III_SID_E_TYPE_EPOCH_001           = 17,
    III_SID_E_TYPE_LIN_003             = 18,
    III_SID_E_TYPE_EPI_001             = 19,
    III_SID_E_TYPE_GHOST_001           = 20,
    III_SID_E_TYPE_SRPA_001            = 21,
    III_SID_E_TYPE_CYCLE_002           = 22,
    III_SID_E_TYPE_OBS_001             = 23,
    III_SID_E_PARSE_IRPD_002           = 24,
    III_SID_E_TYPE_RING_001            = 25,
    III_SID_E_TYPE_LIN_002             = 26,
    III_SID_E_TYPE_INV_001             = 27,
    III_SID_E_TYPE_CEIL_002            = 28,
    III_SID_E_TYPE_WAAC_001            = 29,
    III_SID_E_TYPE_CYCLE_003           = 30,
    III_SID_E_TYPE_CYCLE_004           = 31,
    III_SID_E_TYPE_CYCLE_005           = 32
} iii_sid_error_t;

const char *iii_sid_error_name(iii_sid_error_t e);

/* SID input: every IRPD call observed in the forward body, plus the modifier
 * set the cycle declaration carries. */
#define III_SID_MAX_CALLS  64u

typedef struct iii_sid_call {
    iii_se_kind_t   kind;
    uint64_t        arg_idx;
    uint64_t        arg_value;
    uint64_t        prior_value;
    bool            prior_value_captured;
    uint16_t        per_call_hexad;
} iii_sid_call_t;

typedef struct iii_sid_input {
    char                        cycle_name[64];
    iii_sid_call_t              calls[III_SID_MAX_CALLS];
    unsigned                    call_count;

    /* Modifier flags (subset of the cycle-applicable modifiers from §1.1) */
    bool                        irreversible;
    iii_compromise_tier_t       compromise_tier;
    bool                        pure_;
    bool                        witness_elide;
    bool                        sanctum_only;
    bool                        candidate_for_promotion;
    bool                        hot_path;
    bool                        chronos_bypass;
    bool                        epoch_bridge;

    /* Hexad/coherence/Trinity preconditions */
    uint16_t                    declared_hexad;
    uint16_t                    composed_hexad;       /* set by run */
    uint16_t                    coherence_q14;
    uint16_t                    coherence_floor_q14;
    bool                        trinity_discharged;
    bool                        ceiling_admitted;
    bool                        constitutional_manifest_ok;
    bool                        waac_ok;

    /* Plan anchor + ring + epoch */
    uint32_t                    plan_anchor_id;       /* 0 = missing */
    uint8_t                     phase_set;            /* iii_phase_set_t-style bitmap */
    uint64_t                    cycle_epoch;
    uint64_t                    current_epoch;

    /* Federation */
    uint8_t                     federation_tier;      /* 0..3 */
    uint8_t                     declared_replicates;  /* 0..3 */
    bool                        federation_match;

    /* Glyph + capabilities */
    bool                        glyphs_resolved;
    bool                        cap_balanced;

    /* Ring marshalling availability — caller asserts true if every reachable
     * pair in phase_set has a constructor. */
    bool                        ring_marshalling_available;

    /* Round-trip simulation result */
    bool                        roundtrip_ok;

    /* Raw privileged write outside IRPD — set true if the caller observed any. */
    bool                        raw_privileged_outside_irpd;
} iii_sid_input_t;

typedef enum iii_pip_kind {
    III_PIP_NONE        = 0,
    III_PIP_STATIC_BYTES = 1,
    III_PIP_DYNAMIC_FN   = 2,
    III_PIP_COMPOSED     = 3
} iii_pip_kind_t;

const char *iii_pip_kind_name(iii_pip_kind_t k);

typedef struct iii_sid_output {
    bool                        ok;
    iii_sid_step_t              failed_at_step;
    iii_sid_error_t             error;
    /* Filled even on partial completion */
    uint16_t                    composed_hexad;
    iii_pip_kind_t              pip_kind;
    uint16_t                    allocated_step_kind;  /* assigned in step 14 */
    uint32_t                    inverse_replay_bitmap; /* step 27 */
} iii_sid_output_t;

void iii_sid_run(const iii_sid_input_t *in, iii_sid_output_t *out);

/* ----------------------------------------------------------------------------
 * §4 — XiiWitness (128 bytes, byte-exact layout per §4.1).
 * ---------------------------------------------------------------------------- */

#define III_XII_WITNESS_BYTES   128u

typedef struct iii_xii_witness {
    uint8_t  predecessor_mhash[32];   /* 0x00 */
    uint8_t  successor_mhash[32];     /* 0x20 — zeroed during BLAKE3 input, filled with HMAC-SHA-256 on emit (per §4.2 step 5) */
    uint32_t step_kind;               /* 0x40 */
    uint32_t cycle_seq;               /* 0x44 */
    uint64_t chronos_tsc;             /* 0x48 */
    uint32_t cost_q14;                /* 0x50 */
    uint32_t capability_bind;         /* 0x54 */
    uint32_t adversariality_class;    /* 0x58 */
    uint32_t federation_route;        /* 0x5C */
    uint32_t plan_anchor_id;          /* 0x60 */
    uint32_t flags;                   /* 0x64 */
    uint16_t hexad_packed;            /* 0x68 */
    uint8_t  hmac_tail[22];           /* 0x6A — HMAC-SHA-256 tail bytes */
    /* 0x80 = 128 bytes total */
} iii_xii_witness_t;

#define III_XII_FLAG_IRREVERSIBLE     (1u << 0)
#define III_XII_FLAG_GHOST            (1u << 1)
#define III_XII_FLAG_HOT_PATH         (1u << 2)
#define III_XII_FLAG_SANCTUM_ACTIVE   (1u << 3)
#define III_XII_FLAG_PURE             (1u << 4)
#define III_XII_FLAG_FEDERATED        (1u << 5)
#define III_XII_FLAG_PROMOTION_TARGET (1u << 6)

/* ----------------------------------------------------------------------------
 * §4 — emission state.  One per logical CPU; contains the chain-head register,
 * forward + inverse rings, BCWL, HMAC sub-key, and chronos clock tap.
 * ---------------------------------------------------------------------------- */

typedef struct iii_witness_emitter iii_witness_emitter_t;

iii_witness_emitter_t *iii_witness_emitter_create(uint32_t cpu_id);
void iii_witness_emitter_destroy(iii_witness_emitter_t *e);

/* Set the per-CPU HMAC sub-key.  The runtime would derive this via HKDF from
 * the Sanctum master key; the API allows caller-provided keys for tests. */
void iii_witness_emitter_set_subkey(iii_witness_emitter_t *e,
                                    const uint8_t          subkey[32]);

/* Issue one witness — the 8-step §4.2 protocol. */
typedef struct iii_witness_request {
    uint16_t step_kind;
    uint64_t chronos_tsc;
    uint32_t cost_q14;
    uint32_t capability_bind;
    uint32_t adversariality_class;
    uint32_t federation_route;
    uint32_t plan_anchor_id;
    uint32_t flags;
    uint16_t hexad_packed;
} iii_witness_request_t;

void iii_witness_emit(iii_witness_emitter_t       *e,
                      const iii_witness_request_t *req,
                      iii_xii_witness_t           *out);

uint64_t iii_witness_emitter_count(const iii_witness_emitter_t *e);

/* §7.3 — append an inverse witness paired with a forward; the inverse is
 * threaded into the *inverse* ring and the chain head is updated. */
void iii_witness_emit_inverse(iii_witness_emitter_t       *e,
                              const iii_xii_witness_t     *forward,
                              uint16_t                     inverse_step_kind,
                              iii_xii_witness_t           *out);

/* §4.4 — HKDF-SHA-256 sub-key derivation. */
void iii_witness_derive_subkey(const uint8_t  master[32],
                               uint32_t       cpu_id,
                               uint64_t       epoch,
                               uint8_t        out_subkey[32]);

/* ----------------------------------------------------------------------------
 * §4.3 — BCWL: Bloom-Coupled Witness Lattice.
 * ---------------------------------------------------------------------------- */

typedef struct iii_bcwl iii_bcwl_t;

iii_bcwl_t *iii_bcwl_create(void);
void iii_bcwl_destroy(iii_bcwl_t *b);

void  iii_bcwl_insert(iii_bcwl_t *b, const iii_xii_witness_t *w);
bool  iii_bcwl_contains(const iii_bcwl_t *b, const uint8_t successor_mhash[32]);
size_t iii_bcwl_count(const iii_bcwl_t *b);

/* Walk all witnesses whose step_kind falls in [lo, hi].  Returns the number
 * visited; pre-empts via the predicate's return value (false stops the scan). */
typedef bool (*iii_bcwl_visit_fn)(const iii_xii_witness_t *w, void *user);
size_t iii_bcwl_walk_step_kind(const iii_bcwl_t *b,
                               uint16_t lo, uint16_t hi,
                               iii_bcwl_visit_fn visit, void *user);

/* Walk the chain forward from the witness whose successor_mhash equals
 * `start`.  Returns 0 if not present. */
size_t iii_bcwl_walk_chain(const iii_bcwl_t *b,
                           const uint8_t start[32],
                           iii_bcwl_visit_fn visit, void *user);

/* ----------------------------------------------------------------------------
 * §5 — the live cycle table.
 * ---------------------------------------------------------------------------- */

typedef struct iii_cycle_descriptor {
    uint64_t                cycle_id;
    uint8_t                 mhash[32];                /* content-addressed identity */
    char                    name[64];
    uint16_t                step_kind;                /* unique, per §5.1 inv. 1 */
    uint16_t                composed_hexad;
    uint8_t                 phase_set;
    uint64_t                epoch;
    uint32_t                plan_anchor_id;
    bool                    irreversible;
    iii_compromise_tier_t   compromise_tier;
    iii_pip_kind_t          pip_kind;
    uint32_t                inverse_replay_bitmap;
    uint16_t                coherence_q14;
    bool                    candidate_for_promotion;
    bool                    superseded;
    uint64_t                superseded_by;            /* cycle_id of replacement */
} iii_cycle_descriptor_t;

typedef struct iii_cycle_table iii_cycle_table_t;

iii_cycle_table_t *iii_cycle_table_create(void);
void iii_cycle_table_destroy(iii_cycle_table_t *t);

/* Register a new descriptor.  Returns the assigned cycle_id (≥ 1) or 0 on
 * collision/violation of the 8 invariants of §5.1. */
uint64_t iii_cycle_table_register(iii_cycle_table_t            *t,
                                  const iii_cycle_descriptor_t *d);

const iii_cycle_descriptor_t *iii_cycle_table_lookup_by_id(const iii_cycle_table_t *t,
                                                          uint64_t cycle_id);
const iii_cycle_descriptor_t *iii_cycle_table_lookup_by_mhash(const iii_cycle_table_t *t,
                                                              const uint8_t mhash[32]);

size_t iii_cycle_table_size(const iii_cycle_table_t *t);

/* §5.1 invariant verification: returns true iff all eight invariants hold. */
bool iii_cycle_table_invariants(const iii_cycle_table_t *t);

/* §5.2 — Catalyst supersedure.  The original is marked superseded; the
 * replacement gets a new cycle_id; both remain in the table (append-only,
 * inv. 7). Returns the new cycle_id, or 0 on rejection. */
typedef enum iii_catalyst_status {
    III_CATALYST_OK                  = 0,
    III_CATALYST_E_RATE_CAP          = 1,
    III_CATALYST_E_COHERENCE         = 2,
    III_CATALYST_E_TRINITY           = 3,
    III_CATALYST_E_NOT_CANDIDATE     = 4,
    III_CATALYST_E_VALIDATION        = 5,
    III_CATALYST_E_NOT_FOUND         = 6,
    III_CATALYST_E_INVARIANT         = 7
} iii_catalyst_status_t;

const char *iii_catalyst_status_name(iii_catalyst_status_t s);

/* §6.3 — rate cap. */
#define XII_MNEME_CATALYST_PROMOTION_RATE_PER_TICK   8u

typedef struct iii_catalyst_promotion {
    uint64_t                original_cycle_id;
    iii_cycle_descriptor_t  replacement;
    bool                    trinity_admitted;
    bool                    codegen_validated;
    uint16_t                coherence_q14;
    uint16_t                coherence_floor_q14;
} iii_catalyst_promotion_t;

iii_catalyst_status_t iii_cycle_table_promote(iii_cycle_table_t              *t,
                                              const iii_catalyst_promotion_t *p,
                                              uint64_t                       *out_new_cycle_id);

/* Per-tick reset for the rate cap. */
void iii_cycle_table_tick(iii_cycle_table_t *t);
uint32_t iii_cycle_table_promotions_this_tick(const iii_cycle_table_t *t);

/* ----------------------------------------------------------------------------
 * §8 — wavefront composition.
 *
 * A wavefront accumulates a set of side-effects whose composed hexad is
 * verified for admissibility before any of them are emitted.  ACC Wall-Y
 * composition (the union over per-effect hexads) must remain in
 * `xii_asym_reach6` (modeled here as a flag the caller sets externally).
 * ---------------------------------------------------------------------------- */

typedef enum iii_wavefront_terminator {
    III_WAVEFRONT_QUIESCENT  = 0,
    III_WAVEFRONT_BARRIER    = 1,
    III_WAVEFRONT_TIMEOUT    = 2,
    III_WAVEFRONT_OPERATOR   = 3
} iii_wavefront_terminator_t;

typedef struct iii_wavefront iii_wavefront_t;

iii_wavefront_t *iii_wavefront_begin(uint16_t declared_hexad);
void iii_wavefront_end(iii_wavefront_t *w);

bool iii_wavefront_add_effect(iii_wavefront_t *w, iii_se_kind_t kind, uint16_t per_kind_hexad);
uint16_t iii_wavefront_composed_hexad(const iii_wavefront_t *w);
bool iii_wavefront_admit(const iii_wavefront_t *w);

/* On commit, the runtime emits witnesses for each constituent effect; we
 * surface a count so callers can verify. */
size_t iii_wavefront_commit(iii_wavefront_t *w,
                            iii_witness_emitter_t *e,
                            iii_wavefront_terminator_t terminator);

/* ----------------------------------------------------------------------------
 * §10 — Closure identity (R1.A5).
 * ---------------------------------------------------------------------------- */
extern const uint8_t III_CYCLES_R1_A5[32];

#ifdef __cplusplus
}
#endif

#endif /* III_CYCLES_H */
