/* III TYPES — diagnostic codes, namespace TYPE-CHK-NNN.
 *
 * These codes are stable and form the unified type-checker error vocabulary
 * referenced by spec §4.2 (TYPE-HEXAD-002), §5.2 (TYPE-RING-001),
 * §6.2 (TYPE-EPOCH-001), §7.2 (TYPE-LIN-001/002), §10.2 (TYPE-HOLE-001),
 * §11 (PROOF-*), and the bidirectional/CIC additions.
 *
 * NIH discipline: only libc.
 */
#ifndef III_TYPES_ERRORS_H
#define III_TYPES_ERRORS_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef enum iii_type_err_code {
    TYPE_CHK_OK                          = 0,

    /* Universe (§2) */
    TYPE_CHK_001_UNIVERSE_OVERFLOW       = 1,   /* level > 6 requested */
    TYPE_CHK_002_UNIVERSE_INCONSISTENT   = 2,   /* type contains its own universe */
    TYPE_CHK_003_NON_CUMULATIVE          = 3,   /* implicit lift Type_i → Type_{i+1} */
    TYPE_CHK_004_PROP_LIFT_BAD           = 4,   /* Prop lift target ≠ Type_0 */

    /* Pi/Lambda (§2.4) */
    TYPE_CHK_010_PI_DOMAIN_NOT_TYPE      = 10,
    TYPE_CHK_011_PI_CODOMAIN_NOT_TYPE    = 11,
    TYPE_CHK_012_LAMBDA_NOT_PI           = 12,
    TYPE_CHK_013_APP_FUNCTION_NOT_PI     = 13,
    TYPE_CHK_014_APP_ARG_MISMATCH        = 14,

    /* Reduction (§3) */
    TYPE_CHK_020_REDUCTION_ARITY         = 20,  /* not a 6-tuple */
    TYPE_CHK_021_REDUCTION_FIELD_KIND    = 21,
    TYPE_CHK_022_REDUCTION_NOT_TRINITY   = 22,
    TYPE_CHK_023_REDUCTION_PROJ          = 23,  /* unknown projector name */
    TYPE_CHK_024_REDUCTION_COMPOSE_PHASE = 24,
    TYPE_CHK_025_REDUCTION_COMPOSE_EPOCH = 25,
    TYPE_CHK_026_REDUCTION_INVERSE       = 26,

    /* Hexad (§4) */
    TYPE_HEXAD_001_TAG_BAD_TYPE          = 30,
    TYPE_HEXAD_002_OUT_OF_REACH          = 31,  /* spec §4.2 */
    TYPE_HEXAD_003_COMPOSE_OUT_OF_REACH  = 32,
    TYPE_HEXAD_004_TAG_NOT_ERASABLE      = 33,
    TYPE_HEXAD_005_BRICKING              = 34,  /* one of the 6 PFS bricks */

    /* Ring/Phase (§5) */
    TYPE_RING_001_NO_MARSHAL             = 40,  /* spec §5.2 */
    TYPE_RING_002_BAD_PHASE_SET          = 41,
    TYPE_RING_003_EMPTY_PHASE_SET        = 42,
    TYPE_RING_004_IMPLICIT_RING_SUB      = 43,

    /* Tier/Epoch (§6) */
    TYPE_TIER_001_BAD_TIER               = 50,
    TYPE_TIER_002_DEMOTION               = 51,
    TYPE_EPOCH_001_CROSS_EPOCH_NO_BRIDGE = 55,  /* spec §6.2 */
    TYPE_EPOCH_002_BAD_EPOCH             = 56,

    /* Capability/Linear (§7) */
    TYPE_LIN_001_USED_TWICE              = 60,  /* spec §7.2 */
    TYPE_LIN_002_DROPPED_UNUSED          = 61,  /* spec §7.2 */
    TYPE_LIN_003_BAD_PERM                = 62,
    TYPE_LIN_004_NO_GLYPH                = 63,
    TYPE_LIN_005_REPLICATE_BAD_TIER      = 64,

    /* Epistemic (§8) */
    TYPE_EPI_001_BAD_CONFIDENCE          = 70,
    TYPE_EPI_002_THRESHOLD_NOT_MET       = 71,
    TYPE_EPI_003_OPEN_QUESTIONS          = 72,

    /* Constitutional / Möbius / Trinity (§9) */
    TYPE_CON_001_NOT_PROP                = 80,
    TYPE_CON_002_CEILING_DENIED          = 81,
    TYPE_MOB_001_COHERENCE_BELOW_FLOOR   = 82,
    TYPE_TRI_001_ADMIT_INCOMPLETE        = 83,

    /* Bidirectional / Holes (§10) */
    TYPE_BIDIR_001_CHECK_FAILED          = 90,
    TYPE_BIDIR_002_SYNTH_FAILED          = 91,
    TYPE_HOLE_001_UNINFERRED             = 92,  /* spec §10.2 */
    TYPE_HOLE_002_OCCURS_CHECK           = 93,
    TYPE_HOLE_003_CONFLICT               = 94,

    /* CIC kernel / Proof (§11) */
    TYPE_PROOF_001_VAR_UNBOUND           = 100,
    TYPE_PROOF_002_NOT_CONVERTIBLE       = 101,
    TYPE_PROOF_003_BAD_SORT              = 102,
    TYPE_PROOF_004_POSITIVITY            = 103,
    TYPE_PROOF_005_BAD_CERT              = 104,
    TYPE_PROOF_006_KERNEL_DIVERGED       = 105,
    TYPE_PROOF_007_BAD_INDUCTIVE         = 106,
    TYPE_PROOF_008_PATTERN_NONEXHAUSTIVE = 107,

    TYPE_CHK__COUNT                      = 110
} iii_type_err_code_t;

const char *iii_type_err_code_name(iii_type_err_code_t c);
const char *iii_type_err_code_message(iii_type_err_code_t c);

typedef struct iii_type_diagnostic {
    iii_type_err_code_t code;
    uint32_t span_start, span_end;
    uint32_t line, col;
    char message[256];
} iii_type_diagnostic_t;

#ifdef __cplusplus
}
#endif
#endif
