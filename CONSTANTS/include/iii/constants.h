/* III CONSTANTS — Constitutional Constants Ledger (R1.D2 derivative).
 *
 * Public API for the constants module. Every constitutional constant
 * catalogued in DOCS/III-CONSTANTS.md is exposed here both as a typed
 * compile-time symbol and as a runtime ledger entry suitable for
 * canonical hashing.
 *
 * The ledger root produced by iii_constant_compute_ledger_root() is the
 * derivative root R1.D2 (constants ledger).
 */
#ifndef III_CONSTANTS_H
#define III_CONSTANTS_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ====================================================================
 * §A. Type tags & mutation tiers
 * ==================================================================== */

typedef enum {
    III_CT_U64    = 1,  /* unsigned 64-bit; 8 bytes LE */
    III_CT_S64    = 2,  /* signed 64-bit; 8 bytes LE   */
    III_CT_Q14    = 3,  /* signed 16-bit Q14; 2 bytes LE */
    III_CT_BAND   = 4,  /* (lo,hi) two u32 LE = 8 bytes  */
    III_CT_TUPLE2 = 5,  /* (a,b) two u32 LE = 8 bytes    */
    III_CT_BOOL   = 6,  /* 1 byte: 0/1 */
    III_CT_STRING = 7,  /* UTF-8 bytes (no NUL)          */
    III_CT_BYTES  = 8   /* opaque bytes                  */
} iii_constant_type_t;

typedef enum {
    III_MT_NEVER_MUTABLE      = 1,
    III_MT_R2_MAJOR_BUMP      = 2,
    III_MT_AMEND_APPLY        = 3,
    III_MT_CATALYST_APPEND    = 4,
    /* DERIVED and OPERATIONAL_TARGET are intentionally NOT mutable via any
     * validator path (the README matrix shows them as ✗ / ✗ / ✗):
     *   - DERIVED: computed from other constants; mutating the input mutates
     *     it, never the derived value directly.
     *   - OPERATIONAL_TARGET: a performance TARGET, not a constitutional
     *     invariant (e.g. III-CONSTANTS.md: the BCWL false-positive-rate
     *     target, the Layer 1/2/3 cycle-cost targets). Targets are aspirational
     *     and informational — they are neither Catalyst-promotable nor
     *     AMEND-APPLY-mutable; the ✗/✗/✗ row is correct, not a gap.
     * (RITCHIE Stage 1.21: the spec preserves the operational-target concept,
     * so the enum value is KEPT and documented rather than removed.) */
    III_MT_DERIVED            = 5,
    III_MT_OPERATIONAL_TARGET = 6,
    III_MT_OPERATOR_POLICY    = 7,
    III_MT_SCHEDULED          = 8,
    III_MT_SEALED_DEFAULT     = 9
} iii_mutation_tier_t;

/* Ledger entry. Pointers are to static storage with program lifetime. */
typedef struct {
    const char         *name;          /* canonical UPPER_SNAKE name      */
    const uint8_t      *value_bytes;   /* canonical encoding of value     */
    size_t              value_len;     /* bytes in value_bytes            */
    iii_constant_type_t type_tag;
    const char         *units;         /* short units string ("", "bytes", "Q14", ...) */
    iii_mutation_tier_t mutation_tier;
    uint32_t            hash_slot;     /* 1-based canonical slot index    */
    const char         *source;        /* spec citation, e.g. "LEX §4"   */
    const char         *section;       /* this ledger section, e.g. "§2" */
} iii_constant_info_t;

/* ====================================================================
 * §B. Lookup, enumeration, ledger root
 * ==================================================================== */

/* Total registered constants. */
size_t iii_constant_count(void);

/* Returns entry by hash_slot (1..N) or NULL. */
const iii_constant_info_t *iii_constant_at(uint32_t slot);

/* Linear lookup by exact name. NULL if not found. */
const iii_constant_info_t *iii_constant_lookup(const char *name);

/* Compute the canonical SHA-256 over all entries in slot order.
 * out must point to 32 bytes. This is the constants Merkle root R1.D2.
 *
 * Canonical encoding per entry:
 *   slot       (u32 LE)
 *   type_tag   (u8)
 *   tier       (u8)
 *   name_len   (u32 LE) | name bytes
 *   units_len  (u32 LE) | units bytes
 *   source_len (u32 LE) | source bytes
 *   section_len(u32 LE) | section bytes
 *   value_len  (u32 LE) | value bytes
 *   0xFF separator byte
 */
void iii_constant_compute_ledger_root(uint8_t out[32]);

/* Hex form (lowercase, 64 chars + NUL) of the ledger root. */
void iii_constant_compute_ledger_root_hex(char out[65]);

/* ====================================================================
 * §C. Mutation-path validators
 * ==================================================================== */

typedef enum {
    III_CV_OK              = 0,
    III_CV_NOT_FOUND       = 1,
    III_CV_WRONG_TIER      = 2,
    III_CV_NEVER_MUTABLE   = 3,
    III_CV_VALUE_REGRESS   = 4, /* CATALYST-APPEND: new value < current */
    III_CV_INVALID_VALUE   = 5,
    III_CV_FOUNDERS_LOCKED = 6  /* protected by Founder's Anchor invariant */
} iii_constant_validate_t;

/* CATALYST-APPEND: only constants with tier == CATALYST_APPEND may be
 * mutated, and the new value must not regress (numeric ≥ current,
 * BAND/TUPLE high ≥ current high, string length ≥ current length).  */
iii_constant_validate_t iii_constant_validate_catalyst_append(
    const char *name,
    const uint8_t *new_value, size_t new_value_len);

/* AMEND-APPLY: constants with tier == AMEND_APPLY (or SEALED_DEFAULT,
 * SCHEDULED) may be amended via Tier-3 unanimous + Founder's Anchor
 * cosignature. NEVER_MUTABLE rejected. CATALYST_APPEND must use append
 * path. R2_MAJOR_BUMP must use the R2 path.                            */
iii_constant_validate_t iii_constant_validate_amend_apply(
    const char *name,
    const uint8_t *new_value, size_t new_value_len);

/* R2-MAJOR-BUMP: only constants with tier == R2_MAJOR_BUMP may be
 * mutated. NEVER_MUTABLE / Founder's Anchor invariants are still
 * rejected.                                                            */
iii_constant_validate_t iii_constant_validate_r2_bump(
    const char *name,
    const uint8_t *new_value, size_t new_value_len);

/* Human-readable reason string. */
const char *iii_constant_validate_str(iii_constant_validate_t v);
const char *iii_constant_type_str(iii_constant_type_t t);
const char *iii_constant_tier_str(iii_mutation_tier_t t);

/* ====================================================================
 * §D. Compile-time visible constants
 *
 * Every constitutional constant from III-CONSTANTS.md is exposed as a
 * macro or const so callers can use it at compile time.  The runtime
 * ledger above is derived from these same values.
 * ==================================================================== */

/* §2 Lexical */
#define III_C_LEX_KEYWORD_COUNT             47u
#define III_C_LEX_KEYWORD_RESERVED_SLOTS    16u
#define III_C_LEX_KEYWORD_MAX               63u
#define III_C_LEX_MODIFIER_COUNT            19u
#define III_C_LEX_MODIFIER_RESERVED_SLOTS    8u
#define III_C_LEX_MODIFIER_MAX              27u
#define III_C_LEX_OPERATOR_COUNT            23u
#define III_C_LEX_OPERATOR_RESERVED_SLOTS    7u
#define III_C_LEX_OPERATOR_MAX              30u
#define III_C_LEX_PUNCTUATOR_COUNT          25u
#define III_C_LEX_RESERVED_UNUSED_CHARS      5u
#define III_C_LEX_LITERAL_TOKEN_KINDS        9u
#define III_C_LEX_COMMENT_KINDS              3u
#define III_C_LEX_WHITESPACE_CHARS           3u
#define III_C_LEX_IDENT_MAX_CODEPOINTS     256u
#define III_C_LEX_SOURCE_MAX_BYTES   (1u << 24) /* 16 MiB                */
#define III_C_LEX_SOURCE_EXTENSION  ".III"
#define III_C_LEX_MOBIUS_DIACRITIC      0x00F6u /* precomposed ö         */
#define III_C_LEX_BOM_FORBIDDEN              true
#define III_C_LEX_LINE_ENDING        "LF"

/* §3 Type system */
#define III_C_TYPE_UNIVERSE_COUNT            7u
#define III_C_TYPE_IMPREDICATIVE_TOP_INDEX   6u
#define III_C_TYPE_Q14_BITS_TOTAL           16u
#define III_C_TYPE_Q14_FRAC_BITS            14u
#define III_C_TYPE_MHASH_SIZE               32u  /* SHA-256              */
#define III_C_TYPE_GLYPH_SIZE              192u  /* XiiGlyph V3          */
#define III_C_TYPE_WITNESS_SIZE            128u  /* XiiWitness           */
#define III_C_TYPE_HEXAD_PACK_BITS_USED     12u
#define III_C_TYPE_HEXAD_PACK_BITS_RESERVED  4u
#define III_C_TYPE_TRIT_CARDINALITY          3u
#define III_C_TYPE_REDUCTION_ARITY           6u
#define III_C_TYPE_COMPROMISE_TIERS          3u
#define III_C_TYPE_PROOF_KERNEL_LOC_BUDGET 3000u

/* §4 Effect system */
#define III_C_EFFECT_SE_KIND_COUNT          17u
#define III_C_EFFECT_COMPROMISE_TIER_COUNT   3u
#define III_C_EFFECT_PFS_BRICKING_OPS        6u  /* NEVER MUTABLE        */
#define III_C_EFFECT_WAVEFRONT_TERMINATORS   3u

/* §5 Cycle / witness */
#define III_C_CYCLE_WITNESS_BYTE_SIZE      128u
#define III_C_CYCLE_WITNESS_PRED_OFFSET   0x00u
#define III_C_CYCLE_WITNESS_PRED_BYTES      32u
#define III_C_CYCLE_WITNESS_SUCC_OFFSET   0x20u
#define III_C_CYCLE_WITNESS_SUCC_BYTES      32u
#define III_C_CYCLE_WITNESS_STEP_KIND_OFFSET 0x40u
#define III_C_CYCLE_WITNESS_STEP_KIND_BYTES   4u
#define III_C_CYCLE_WITNESS_FLAGS_OFFSET  0x64u
#define III_C_CYCLE_WITNESS_FLAGS_BYTES      4u
#define III_C_CYCLE_WITNESS_HEXAD_OFFSET  0x68u
#define III_C_CYCLE_WITNESS_HEXAD_BYTES     24u
#define III_C_CYCLE_BCWL_BLOOM_BITS       4096u
#define III_C_CYCLE_BCWL_BUCKETS            16u
#define III_C_CYCLE_BCWL_FP_TARGET_PERCENT   1u
#define III_C_CYCLE_STEP_KIND_TOTAL_SLOTS  512u

/* Step-kind bands (lo, hi inclusive).  Names match XII_STEP_KIND_<>.   */
#define III_C_SK_RESERVED_BOOT_LO          0x0000u
#define III_C_SK_RESERVED_BOOT_HI          0x000Fu
#define III_C_SK_IRPD_PRIV_WRITE_LO        0x0010u
#define III_C_SK_IRPD_PRIV_WRITE_HI        0x002Fu
#define III_C_SK_IRPD_PRIV_READ_LO         0x0030u
#define III_C_SK_IRPD_PRIV_READ_HI         0x004Fu
#define III_C_SK_CYCLE_LIFECYCLE_LO        0x0050u
#define III_C_SK_CYCLE_LIFECYCLE_HI        0x006Fu
#define III_C_SK_WAVEFRONT_LO              0x0070u
#define III_C_SK_WAVEFRONT_HI              0x007Fu
#define III_C_SK_SANCTUM_LO                0x0080u
#define III_C_SK_SANCTUM_HI                0x009Fu
#define III_C_SK_TRINITY_LO                0x00A0u
#define III_C_SK_TRINITY_HI                0x00BFu
#define III_C_SK_CEILING_LO                0x00C0u
#define III_C_SK_CEILING_HI                0x00CFu
#define III_C_SK_FEDERATION_LO             0x00D0u
#define III_C_SK_FEDERATION_HI             0x00EFu
#define III_C_SK_DRTM_LO                   0x00F0u
#define III_C_SK_DRTM_HI                   0x00FFu
#define III_C_SK_VDF_LO                    0x0100u
#define III_C_SK_VDF_HI                    0x010Fu
#define III_C_SK_OBSERVATORY_LO            0x0110u
#define III_C_SK_OBSERVATORY_HI            0x012Fu
#define III_C_SK_CATALYST_LO               0x0130u
#define III_C_SK_CATALYST_HI               0x014Fu
#define III_C_SK_NARRATIVE_LO              0x0150u
#define III_C_SK_NARRATIVE_HI              0x015Fu
#define III_C_SK_COGNITIVE_LO              0x0160u
#define III_C_SK_COGNITIVE_HI              0x017Fu
#define III_C_SK_PFS_LO                    0x0180u
#define III_C_SK_PFS_HI                    0x018Fu
#define III_C_SK_FED_RESERVED_LO           0x0190u
#define III_C_SK_FED_RESERVED_HI           0x01AFu
#define III_C_SK_USER_RESERVED_LO          0x01B0u
#define III_C_SK_USER_RESERVED_HI          0x01C6u
#define III_C_SK_MNEME_PROMOTE_LO          0x01C7u
#define III_C_SK_MNEME_PROMOTE_HI          0x01CFu
#define III_C_SK_RESERVED_FUTURE_LO        0x01D0u
#define III_C_SK_RESERVED_FUTURE_HI        0x01FFu

/* §6 Hexad */
#define III_C_HEXAD_PILLAR_COUNT             6u
#define III_C_HEXAD_TRIT_NEG_ASYM           (-2)
#define III_C_HEXAD_TRIT_NEG_BALANCED       (-1)
#define III_C_HEXAD_TRIT_NEG_PACKED        0x00u   /* 0b00              */
#define III_C_HEXAD_TRIT_ZERO_PACKED       0x01u   /* 0b01              */
#define III_C_HEXAD_TRIT_POS_PACKED        0x02u   /* 0b10              */
#define III_C_HEXAD_RESERVED_TRIT_BITPATTERN 0x03u /* 0b11              */
#define III_C_HEXAD_TOTAL_POSSIBLE         729u    /* 3^6               */
#define III_C_HEXAD_ADMISSIBLE             144u    /* 2^4 * 3^2         */
#define III_C_HEXAD_ASYM_REACH6_BYTES      144u
#define III_C_HEXAD_REACH_CODE_BIT_HI        7u
#define III_C_HEXAD_REACH_CODE_BIT_LO        6u
#define III_C_HEXAD_METADATA_BIT_HI          5u
#define III_C_HEXAD_METADATA_BIT_LO          0u
#define III_C_HEXAD_REACH_CODE_COUNT         4u
#define III_C_HEXAD_PFS_BRICKING_HEXADS      6u   /* NEVER MUTABLE      */

/* §7 Phase */
#define III_C_PHASE_RING_COUNT               4u
#define III_C_PHASE_CROSS_RING_CTORS         5u
#define III_C_PHASE_MARSHALLING_RULES        5u
#define III_C_XII_PHASE_PROMOTE_RATE         4u   /* per chronos-tick   */
#define III_C_PHASE_MAGIC_MSR_ADDRESS  0xC001F100u

/* §8 Sanctum (slots NEVER MUTABLE) */
#define III_C_SANCTUM_SEAL_COUNT            10u
#define III_C_SANCTUM_SLOT_INVALID            0u
#define III_C_SANCTUM_SLOT_DRTM_RELAUNCH      1u
#define III_C_SANCTUM_SLOT_PFS_VAR_SET        2u
#define III_C_SANCTUM_SLOT_PFS_DENY_QUOTE     3u
#define III_C_SANCTUM_SLOT_CRCC_KEY_EXPORT    4u
#define III_C_SANCTUM_SLOT_PHOENIX_EMERGENCY  5u
#define III_C_SANCTUM_SLOT_CHRONOS_SET_EPOCH  6u
#define III_C_SANCTUM_SLOT_COMPROMISE_QUOTE   7u
#define III_C_SANCTUM_SLOT_PHOENIX_BOOKMARK   8u
#define III_C_SANCTUM_SLOT_COMPILE_MODULE     9u
#define III_C_DRTM_QUOTE_BYTE_SIZE          312u
#define III_C_SANCTUM_PER_CPU_FRAME_SIZE    160u

/* §9 Trinity */
#define III_C_TRINITY_LAYER_COUNT            3u
#define III_C_TRINITY_GATE_CONJUNCTS         4u
#define III_C_TRINITY_SCBA_BYTES          8192u   /* 8 KiB              */
#define III_C_TRINITY_SCBA_BITS          65536u
#define III_C_TRINITY_FAILURE_MODE_CODES    11u
#define III_C_TRINITY_CONVERGENCE_PT_SIZE  128u

/* §10 Module */
#define III_C_MODULE_DEPLOY_FLAG_COUNT       3u
#define III_C_XII_MOD_PROMOTE_RATE          16u   /* per chronos-tick   */
#define III_C_MODULE_TRANSMISSION_RULES      5u
#define III_C_MODULE_FP_TOLERANCE_PERCENT    5u

/* §11 Catalyst */
#define III_C_XII_MNEME_CATALYST_PROMOTION_RATE_PER_TICK 8u
#define III_C_CATALYST_PROMOTION_GATE_COUNT  8u
#define III_C_CATALYST_SYNTHESIS_CAP_COUNT   7u
#define III_C_CATALYST_INVIOLABLE_RAILS      5u   /* NEVER MUTABLE      */
#define III_C_MOBIUS_COHERENCE_FLOOR_Q14 15073   /* 0.92 * 16384 ≈ 15073 */
#define III_C_CATALYST_BURN_IN_TICKS  (1u << 20)  /* 2^20 = 1048576     */
#define III_C_CATALYST_OPERATOR_OVERRIDE_MECHS 4u

/* §12 Federation */
#define III_C_FED_TIER_COUNT                 4u
#define III_C_FED_TIER1_QUORUM_N             3u
#define III_C_FED_TIER1_QUORUM_K             2u
#define III_C_FED_TIER2_QUORUM_N             5u
#define III_C_FED_TIER2_QUORUM_K             3u
#define III_C_FED_REPLICATION_POLICY_VALUES  4u
#define III_C_FED_DISCOVERY_CADENCE_PER_TICK 1u

/* §13 Cognitive */
#define III_C_COG_PRIMITIVE_COUNT            7u
#define III_C_EPISTEMIC_CONFIDENCE_THRESHOLD_Q14 13926 /* 0.85 * 16384 */
#define III_C_COG_EXPLAIN_LEVELS             5u
#define III_C_COG_REFLECT_TARGETS            6u
#define III_C_COG_NARRATIVE_DECL_PER_MODULE  1u

/* §14 Conformance */
#define III_C_CONF_CRITERION_COUNT          30u
#define III_C_CONF_CORE_LANG_CRITERIA       15u
#define III_C_CONF_SUBSTRATE_RUNTIME_CRITERIA 10u
#define III_C_CONF_COGNITIVE_LAYER_CRITERIA  5u

/* §15 ABI */
#define III_C_ABI_LEGAL_NAME_COUNT           1u
#define III_C_ABI_RESERVED_NAME_COUNT        4u
#define III_C_ABI_EXTERN_RING_R0             0u
#define III_C_ABI_EXTERN_RING_R3             3u

/* §16 R1 */
#define III_C_R1_SLOT_COUNT_SEALED          15u
#define III_C_R1_RESERVED_WAVE_SLOTS         4u

/* §17.1 Item 175 — ZK Rollup */
#define III_C_ZK_ROLLUP_COMPACTION_THRESHOLD 1048576u
#define III_C_ZK_PROOF_TARGET_BYTES          256u
#define III_C_ZK_DECOMMITMENT_RETENTION     1024u

/* §17.2 Item 176 — Crypto Agility */
#define III_C_CRYPTO_SUITE_ID_WIDTH_BITS     64u
#define III_C_CRYPTO_SUITE_PRE_QUANTUM   0x0001u
#define III_C_CRYPTO_SUITE_POST_QUANTUM_1 0x0100u
#define III_C_CRYPTO_SUITE_POST_QUANTUM_2 0x0200u
#define III_C_CRYPTO_SUITE_HYBRID         0x0300u
#define III_C_CRYPTO_ACTIVE_SUITE_DRTM_OFFSET 0x160u

/* §17.3 Item 177 — Genesis Vector */
#define III_C_GENESIS_DISCOVERY_CADENCE_PER_TICK 1u

/* §17.4 Item 178 — Founder's Anchor */
#define III_C_FOUNDERS_ANCHOR_PUBKEY_SIZE_ED25519 32u
#define III_C_FOUNDERS_ANCHOR_COSIGNED_FLAG_BIT    8u
#define III_C_FOUNDERS_ANCHOR_K_RECOMMENDED        3u
#define III_C_FOUNDERS_ANCHOR_N_RECOMMENDED        5u
#define III_C_FOUNDERS_ANCHOR_REJECTION_LAYERS     3u

/* §18 Founder's Anchor invariants count, §19 cascade rule count */
#define III_C_FOUNDERS_ANCHOR_INVARIANT_COUNT     10u
#define III_C_CASCADE_RULE_COUNT                   7u

#ifdef __cplusplus
}
#endif

#endif /* III_CONSTANTS_H */
