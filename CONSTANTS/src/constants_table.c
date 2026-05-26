/* III CONSTANTS — master table of constitutional constants.
 *
 * Each entry corresponds to one row in DOCS/III-CONSTANTS.md. The
 * canonical hash slot is the table index + 1.  Order is fixed; a slot
 * never gets reused for a different constant (CATALYST-APPEND only
 * adds new slots at the tail).
 *
 * Values are stored once in a compact definition struct; on first call
 * to any public API the canonical byte encodings are materialized into
 * a single static buffer and the public iii_constant_info_t table is
 * populated.  After init the table is read-only.
 */
#include "iii/constants.h"
#include "iii/constants_internal.h"

#include <string.h>
#include <stdlib.h>
#include <stdio.h>

/* Internal encoding container.  Fields used depend on .type. */
typedef struct {
    const char         *name;
    iii_constant_type_t type;
    iii_mutation_tier_t tier;
    const char         *units;
    const char         *source;
    const char         *section;
    /* numeric */
    int64_t             i;       /* U64/S64/Q14/BOOL                */
    /* paired */
    uint32_t            a, b;    /* BAND/TUPLE2: a=lo, b=hi          */
    /* string / raw */
    const char         *str;     /* STRING                           */
    const uint8_t      *raw;     /* BYTES                            */
    size_t              raw_len;
} def_t;

#define U(n,v,uu,tt,src) \
    { .name=#n, .type=III_CT_U64, .tier=III_MT_##tt, .units=uu, \
      .source=src, .section=SECT, .i=(int64_t)(uint64_t)(v) }
#define S(n,v,uu,tt,src) \
    { .name=#n, .type=III_CT_S64, .tier=III_MT_##tt, .units=uu, \
      .source=src, .section=SECT, .i=(int64_t)(v) }
#define Q(n,v,tt,src) \
    { .name=#n, .type=III_CT_Q14, .tier=III_MT_##tt, .units="Q14", \
      .source=src, .section=SECT, .i=(int64_t)(int16_t)(v) }
#define B(n,lo,hi,uu,tt,src) \
    { .name=#n, .type=III_CT_BAND, .tier=III_MT_##tt, .units=uu, \
      .source=src, .section=SECT, .a=(uint32_t)(lo), .b=(uint32_t)(hi) }
#define T2(n,x,y,uu,tt,src) \
    { .name=#n, .type=III_CT_TUPLE2, .tier=III_MT_##tt, .units=uu, \
      .source=src, .section=SECT, .a=(uint32_t)(x), .b=(uint32_t)(y) }
#define BOOL(n,v,tt,src) \
    { .name=#n, .type=III_CT_BOOL, .tier=III_MT_##tt, .units="bool", \
      .source=src, .section=SECT, .i=((v)?1:0) }
#define STR(n,v,tt,src) \
    { .name=#n, .type=III_CT_STRING, .tier=III_MT_##tt, .units="utf8", \
      .source=src, .section=SECT, .str=(v) }

static const def_t DEFS[] = {

/* ---------------- §2 Lexical (LEX) ---------------- */
#undef SECT
#define SECT "§2"
    U(LEX_KEYWORD_COUNT,             47, "count", CATALYST_APPEND, "LEX §4"),
    U(LEX_KEYWORD_RESERVED_SLOTS,    16, "count", CATALYST_APPEND, "LEX §4"),
    U(LEX_KEYWORD_MAX,               63, "count", CATALYST_APPEND, "LEX §4"),
    U(LEX_MODIFIER_COUNT,            19, "count", CATALYST_APPEND, "LEX §5"),
    U(LEX_MODIFIER_RESERVED_SLOTS,    8, "count", CATALYST_APPEND, "LEX §5"),
    U(LEX_MODIFIER_MAX,              27, "count", CATALYST_APPEND, "LEX §5"),
    U(LEX_OPERATOR_COUNT,            23, "count", CATALYST_APPEND, "LEX §6"),
    U(LEX_OPERATOR_RESERVED_SLOTS,    7, "count", CATALYST_APPEND, "LEX §6"),
    U(LEX_OPERATOR_MAX,              30, "count", CATALYST_APPEND, "LEX §6"),
    U(LEX_PUNCTUATOR_COUNT,          25, "count", AMEND_APPLY,     "LEX §7"),
    U(LEX_RESERVED_UNUSED_CHARS,      5, "count", CATALYST_APPEND, "LEX §7.3"),
    U(LEX_LITERAL_TOKEN_KINDS,        9, "count", AMEND_APPLY,     "LEX §3.1"),
    U(LEX_COMMENT_KINDS,              3, "count", AMEND_APPLY,     "LEX §10"),
    U(LEX_WHITESPACE_CHARS,           3, "count", AMEND_APPLY,     "LEX §11"),
    U(LEX_IDENT_MAX_CODEPOINTS,     256, "codepoints", AMEND_APPLY, "LEX §8.3"),
    U(LEX_SOURCE_MAX_BYTES,    16777216, "bytes", AMEND_APPLY,     "LEX §2.7"),
    STR(LEX_SOURCE_EXTENSION,    ".III",        AMEND_APPLY,     "LEX §2.6"),
    U(LEX_MOBIUS_DIACRITIC,      0x00F6, "U+",   AMEND_APPLY,     "LEX §4.3"),
    BOOL(LEX_BOM_FORBIDDEN,        true,        R2_MAJOR_BUMP,   "LEX §2.2"),
    STR(LEX_LINE_ENDING,           "LF",        AMEND_APPLY,     "LEX §2.3"),

/* ---------------- §3 Type System (TYPES) ---------------- */
#undef SECT
#define SECT "§3"
    U(TYPE_UNIVERSE_COUNT,            7, "count", R2_MAJOR_BUMP, "TYPES §2"),
    U(TYPE_IMPREDICATIVE_TOP_INDEX,   6, "index", R2_MAJOR_BUMP, "TYPES §2.4"),
    U(TYPE_Q14_BITS_TOTAL,           16, "bits",  R2_MAJOR_BUMP, "TYPES §6"),
    U(TYPE_Q14_FRAC_BITS,            14, "bits",  R2_MAJOR_BUMP, "TYPES §6"),
    U(TYPE_MHASH_SIZE,               32, "bytes", AMEND_APPLY,   "TYPES §6"),
    U(TYPE_GLYPH_SIZE,              192, "bytes", AMEND_APPLY,   "LEX §4.1.1"),
    U(TYPE_WITNESS_SIZE,            128, "bytes", AMEND_APPLY,   "CYCLES §4.1"),
    U(TYPE_HEXAD_PACK_BITS_USED,     12, "bits",  R2_MAJOR_BUMP, "HEXAD §2.2"),
    U(TYPE_HEXAD_PACK_BITS_RESERVED,  4, "bits",  R2_MAJOR_BUMP, "HEXAD §2.2"),
    U(TYPE_TRIT_CARDINALITY,          3, "count", R2_MAJOR_BUMP, "HEXAD §1.1"),
    U(TYPE_REDUCTION_ARITY,           6, "count", R2_MAJOR_BUMP, "TYPES §3"),
    U(TYPE_COMPROMISE_TIERS,          3, "count", AMEND_APPLY,   "EFFECTS §1.2"),
    U(TYPE_PROOF_KERNEL_LOC_BUDGET,3000, "LoC",   AMEND_APPLY,   "TYPES §11"),

/* ---------------- §4 Effect System ---------------- */
#undef SECT
#define SECT "§4"
    U(EFFECT_SE_KIND_COUNT,          17, "count", CATALYST_APPEND, "EFFECTS §1.1"),
    U(EFFECT_COMPROMISE_TIER_COUNT,   3, "count", AMEND_APPLY,     "EFFECTS §1.2"),
    U(EFFECT_PFS_BRICKING_OPS,        6, "count", NEVER_MUTABLE,   "EFFECTS §1.3"),
    U(EFFECT_WAVEFRONT_TERMINATORS,   3, "count", CATALYST_APPEND, "EFFECTS §7"),

/* ---------------- §5 Cycle / Witness ---------------- */
#undef SECT
#define SECT "§5"
    U(CYCLE_WITNESS_BYTE_SIZE,      128, "bytes", AMEND_APPLY,    "CYCLES §4.1"),
    U(CYCLE_WITNESS_PRED_OFFSET,   0x00, "offset", R2_MAJOR_BUMP, "CYCLES §4.1"),
    U(CYCLE_WITNESS_PRED_BYTES,      32, "bytes",  R2_MAJOR_BUMP, "CYCLES §4.1"),
    U(CYCLE_WITNESS_SUCC_OFFSET,   0x20, "offset", R2_MAJOR_BUMP, "CYCLES §4.1"),
    U(CYCLE_WITNESS_SUCC_BYTES,      32, "bytes",  R2_MAJOR_BUMP, "CYCLES §4.1"),
    U(CYCLE_WITNESS_STEP_KIND_OFFSET,0x40,"offset",R2_MAJOR_BUMP, "CYCLES §4.1"),
    U(CYCLE_WITNESS_STEP_KIND_BYTES,  4, "bytes",  R2_MAJOR_BUMP, "CYCLES §4.1"),
    U(CYCLE_WITNESS_FLAGS_OFFSET,  0x64, "offset", CATALYST_APPEND,"STDLIB §5.6"),
    U(CYCLE_WITNESS_FLAGS_BYTES,      4, "bytes",  CATALYST_APPEND,"STDLIB §5.6"),
    U(CYCLE_WITNESS_HEXAD_OFFSET,  0x68, "offset", R2_MAJOR_BUMP, "CYCLES §4.1"),
    U(CYCLE_WITNESS_HEXAD_BYTES,     24, "bytes",  R2_MAJOR_BUMP, "CYCLES §4.1"),
    U(CYCLE_BCWL_BLOOM_BITS,       4096, "bits",   AMEND_APPLY,   "CYCLES §4.3"),
    U(CYCLE_BCWL_BUCKETS,            16, "count",  AMEND_APPLY,   "CYCLES §4.3"),
    U(CYCLE_BCWL_FP_TARGET_PERCENT,   1, "percent",AMEND_APPLY,   "STDLIB §14.3"),
    U(CYCLE_STEP_KIND_TOTAL_SLOTS, 512, "count",   R2_MAJOR_BUMP, "CYCLES §5.3"),

    B(SK_RESERVED_BOOT,         0x0000, 0x000F, "range", AMEND_APPLY,     "CYCLES §5.3"),
    B(SK_IRPD_PRIV_WRITE,       0x0010, 0x002F, "range", AMEND_APPLY,     "CYCLES §5.3"),
    B(SK_IRPD_PRIV_READ,        0x0030, 0x004F, "range", AMEND_APPLY,     "CYCLES §5.3"),
    B(SK_CYCLE_LIFECYCLE,       0x0050, 0x006F, "range", AMEND_APPLY,     "CYCLES §5.3"),
    B(SK_WAVEFRONT,             0x0070, 0x007F, "range", AMEND_APPLY,     "CYCLES §5.3"),
    B(SK_SANCTUM,               0x0080, 0x009F, "range", AMEND_APPLY,     "CYCLES §5.3"),
    B(SK_TRINITY,               0x00A0, 0x00BF, "range", AMEND_APPLY,     "CYCLES §5.3"),
    B(SK_CEILING,               0x00C0, 0x00CF, "range", AMEND_APPLY,     "CYCLES §5.3"),
    B(SK_FEDERATION,            0x00D0, 0x00EF, "range", AMEND_APPLY,     "CYCLES §5.3"),
    B(SK_DRTM,                  0x00F0, 0x00FF, "range", AMEND_APPLY,     "CYCLES §5.3"),
    B(SK_VDF,                   0x0100, 0x010F, "range", AMEND_APPLY,     "CYCLES §5.3"),
    B(SK_OBSERVATORY,           0x0110, 0x012F, "range", AMEND_APPLY,     "CYCLES §5.3"),
    B(SK_CATALYST,              0x0130, 0x014F, "range", AMEND_APPLY,     "CYCLES §5.3"),
    B(SK_NARRATIVE,             0x0150, 0x015F, "range", AMEND_APPLY,     "CYCLES §5.3"),
    B(SK_COGNITIVE,             0x0160, 0x017F, "range", AMEND_APPLY,     "CYCLES §5.3"),
    B(SK_PFS,                   0x0180, 0x018F, "range", AMEND_APPLY,     "CYCLES §5.3"),
    B(SK_FED_RESERVED,          0x0190, 0x01AF, "range", CATALYST_APPEND, "CYCLES §5.3"),
    B(SK_USER_RESERVED,         0x01B0, 0x01C6, "range", CATALYST_APPEND, "CYCLES §5.3"),
    B(SK_MNEME_PROMOTE,         0x01C7, 0x01CF, "range", CATALYST_APPEND, "CYCLES §5.3"),
    B(SK_RESERVED_FUTURE,       0x01D0, 0x01FF, "range", CATALYST_APPEND, "CYCLES §5.3"),

/* ---------------- §6 Hexad ---------------- */
#undef SECT
#define SECT "§6"
    U(HEXAD_PILLAR_COUNT,             6, "count", R2_MAJOR_BUMP, "HEXAD §2"),
    STR(HEXAD_PILLAR_1_NAME, "INVERSE_DERIVABILITY", R2_MAJOR_BUMP, "HEXAD §2.1"),
    STR(HEXAD_PILLAR_2_NAME, "CAUSALITY_DEPTH",      R2_MAJOR_BUMP, "HEXAD §2.1"),
    STR(HEXAD_PILLAR_3_NAME, "CONSENT_RECENCY",      R2_MAJOR_BUMP, "HEXAD §2.1"),
    STR(HEXAD_PILLAR_4_NAME, "REPLICATION_TIER",     R2_MAJOR_BUMP, "HEXAD §2.1"),
    STR(HEXAD_PILLAR_5_NAME, "ADVERSARIALITY_CLASS", R2_MAJOR_BUMP, "HEXAD §2.1"),
    STR(HEXAD_PILLAR_6_NAME, "COHERENCE_IMPACT",     R2_MAJOR_BUMP, "HEXAD §2.1"),
    S(HEXAD_TRIT_NEG_ASYM,      -2, "trit-asym",     R2_MAJOR_BUMP, "HEXAD §1.1"),
    S(HEXAD_TRIT_NEG_BALANCED,  -1, "trit-bal",      R2_MAJOR_BUMP, "HEXAD §1.1"),
    U(HEXAD_TRIT_NEG_PACKED,  0x00, "bits",          R2_MAJOR_BUMP, "HEXAD §1.1"),
    U(HEXAD_TRIT_ZERO_PACKED, 0x01, "bits",          R2_MAJOR_BUMP, "HEXAD §1.1"),
    U(HEXAD_TRIT_POS_PACKED,  0x02, "bits",          R2_MAJOR_BUMP, "HEXAD §1.1"),
    U(HEXAD_RESERVED_TRIT_BITPATTERN, 0x03, "bits", CATALYST_APPEND,"HEXAD §2.2"),
    U(HEXAD_TOTAL_POSSIBLE,         729, "count",   R2_MAJOR_BUMP,  "HEXAD §3.1"),
    U(HEXAD_ADMISSIBLE,             144, "count",   R2_MAJOR_BUMP,  "STDLIB §6.5"),
    U(HEXAD_ASYM_REACH6_BYTES,      144, "bytes",   CATALYST_APPEND,"HEXAD §3.1"),
    U(HEXAD_REACH_CODE_BIT_HI,        7, "bit",     R2_MAJOR_BUMP,  "STDLIB §6.5"),
    U(HEXAD_REACH_CODE_BIT_LO,        6, "bit",     R2_MAJOR_BUMP,  "STDLIB §6.5"),
    U(HEXAD_METADATA_BIT_HI,          5, "bit",     CATALYST_APPEND,"STDLIB §6.5"),
    U(HEXAD_METADATA_BIT_LO,          0, "bit",     CATALYST_APPEND,"STDLIB §6.5"),
    U(HEXAD_REACH_CODE_COUNT,         4, "count",   CATALYST_APPEND,"HEXAD §3.1"),
    U(HEXAD_PFS_BRICKING_HEXADS,      6, "count",   NEVER_MUTABLE,  "HEXAD §4.2"),
    STR(HEXAD_BITMAP_MHASH_FUNC, "SHA-256",         DERIVED,        "HEXAD §3.4"),

/* ---------------- §7 Phase ---------------- */
#undef SECT
#define SECT "§7"
    U(PHASE_RING_COUNT,               4, "count",   R2_MAJOR_BUMP, "PHASES §1"),
    STR(PHASE_RING_LATTICE_ORDER, "R-2<=R-1<=R0<=R3", R2_MAJOR_BUMP, "PHASES §1"),
    U(PHASE_CROSS_RING_CONSTRUCTORS,  5, "count",   AMEND_APPLY,   "PHASES §3"),
    U(PHASE_MARSHALLING_RULES,        5, "count",   AMEND_APPLY,   "PHASES §4"),
    U(XII_PHASE_PROMOTE_RATE,         4, "per-tick",AMEND_APPLY,   "PHASES §5"),
    U(PHASE_MAGIC_MSR_ADDRESS, 0xC001F100u, "MSR",  AMEND_APPLY,   "PHASES §3.1"),

/* ---------------- §8 Sanctum ---------------- */
#undef SECT
#define SECT "§8"
    U(SANCTUM_SEAL_COUNT,            10, "slots",   AMEND_APPLY,   "SANCTUM §1.1"),
    U(SANCTUM_SLOT_INVALID,           0, "slot",    NEVER_MUTABLE, "SANCTUM §1.1"),
    U(SANCTUM_SLOT_DRTM_RELAUNCH,     1, "slot",    NEVER_MUTABLE, "SANCTUM §1.1"),
    U(SANCTUM_SLOT_PFS_VAR_SET,       2, "slot",    NEVER_MUTABLE, "SANCTUM §1.1"),
    U(SANCTUM_SLOT_PFS_DENY_QUOTE,    3, "slot",    NEVER_MUTABLE, "SANCTUM §1.1"),
    U(SANCTUM_SLOT_CRCC_KEY_EXPORT,   4, "slot",    NEVER_MUTABLE, "SANCTUM §1.1"),
    U(SANCTUM_SLOT_PHOENIX_EMERGENCY, 5, "slot",    NEVER_MUTABLE, "SANCTUM §1.1"),
    U(SANCTUM_SLOT_CHRONOS_SET_EPOCH, 6, "slot",    NEVER_MUTABLE, "SANCTUM §1.1"),
    U(SANCTUM_SLOT_COMPROMISE_QUOTE,  7, "slot",    NEVER_MUTABLE, "SANCTUM §1.1"),
    U(SANCTUM_SLOT_PHOENIX_BOOKMARK,  8, "slot",    NEVER_MUTABLE, "SANCTUM §1.1"),
    U(SANCTUM_SLOT_COMPILE_MODULE,    9, "slot",    NEVER_MUTABLE, "SANCTUM §1.1"),
    STR(SANCTUM_GATE_HARDENING, "IBPB+VERW+SSBD+RSP-swap+GPR/FPR/XMM-save",
                                                    AMEND_APPLY, "SANCTUM §2.1"),
    U(DRTM_QUOTE_BYTE_SIZE,         312, "bytes",   AMEND_APPLY,   "SANCTUM §4"),
    U(SANCTUM_PER_CPU_FRAME_SIZE,   160, "bytes",   AMEND_APPLY,   "STDLIB §8.8"),

/* ---------------- §9 Trinity ---------------- */
#undef SECT
#define SECT "§9"
    U(TRINITY_LAYER_COUNT,            3, "count",   AMEND_APPLY,   "TRINITY §1"),
    U(TRINITY_GATE_CONJUNCTS,         4, "count",   AMEND_APPLY,   "TRINITY §1.3"),
    U(TRINITY_SCBA_BYTES,          8192, "bytes",   AMEND_APPLY,   "TRINITY §1.1"),
    U(TRINITY_SCBA_BITS,          65536, "bits",    AMEND_APPLY,   "TRINITY §1.1"),
    STR(TRINITY_SCBA_HASH_FN, "first16(BLAKE3(post_state))",
                                                    AMEND_APPLY, "TRINITY §1.1"),
    U(TRINITY_FAILURE_MODE_CODES,    11, "count",   CATALYST_APPEND,"TRINITY §2"),
    U(TRINITY_CONVERGENCE_PT_SIZE,  128, "bytes",   AMEND_APPLY,   "STDLIB §9.5"),

/* ---------------- §10 Module ---------------- */
#undef SECT
#define SECT "§10"
    STR(MODULE_CLOSURE_ROOT_HASH_FN, "SHA-256",     AMEND_APPLY,   "MODULES §1"),
    U(MODULE_DEPLOY_FLAG_COUNT,       3, "count",   AMEND_APPLY,   "MODULES §6.1"),
    U(XII_MOD_PROMOTE_RATE,          16, "per-tick",AMEND_APPLY,   "MODULES §10"),
    U(MODULE_TRANSMISSION_RULES,      5, "count",   AMEND_APPLY,   "MODULES §3.1"),
    U(MODULE_FP_TOLERANCE_PERCENT,    5, "percent", AMEND_APPLY,   "MODULES §4.1"),

/* ---------------- §11 Catalyst ---------------- */
#undef SECT
#define SECT "§11"
    U(XII_MNEME_CATALYST_PROMOTION_RATE_PER_TICK, 8, "per-tick",
                                                    AMEND_APPLY, "CATALYST §2.3"),
    U(CATALYST_PROMOTION_GATE_COUNT,  8, "count",   AMEND_APPLY,   "CATALYST §2.1"),
    U(CATALYST_SYNTHESIS_CAP_COUNT,   7, "count",   AMEND_APPLY,   "CATALYST §3"),
    U(CATALYST_INVIOLABLE_RAILS,      5, "count",   NEVER_MUTABLE, "CATALYST §4.1"),
    Q(MOBIUS_COHERENCE_FLOOR_Q14, 15073,            AMEND_APPLY, "CATALYST §2.1"),
    U(CATALYST_BURN_IN_TICKS,   1048576, "ticks",   AMEND_APPLY,   "CATALYST §2.1"),
    U(CATALYST_OPERATOR_OVERRIDE_MECHS,4,"count",   AMEND_APPLY,   "CATALYST §4.3"),

/* ---------------- §12 Federation ---------------- */
#undef SECT
#define SECT "§12"
    U(FED_TIER_COUNT,                 4, "count",   AMEND_APPLY,   "FEDERATION §1"),
    T2(FED_TIER1_QUORUM,              3, 2, "(N,K)",AMEND_APPLY,   "FEDERATION §4"),
    T2(FED_TIER2_QUORUM,              5, 3, "(N,K)",AMEND_APPLY,   "FEDERATION §4"),
    STR(FED_TIER3_QUORUM,         "(N,N) unanimous",AMEND_APPLY, "FEDERATION §4"),
    U(FED_REPLICATION_POLICY_VALUES,  4, "count",   CATALYST_APPEND,"LEX §5.1"),
    U(FED_DISCOVERY_CADENCE_PER_TICK, 1, "per-tick",AMEND_APPLY,   "STDLIB §12.6"),
    BOOL(FED_AH_TRAILER_ACTIVE,    true,            AMEND_APPLY, "FEDERATION §5"),

/* ---------------- §13 Cognitive ---------------- */
#undef SECT
#define SECT "§13"
    U(COG_PRIMITIVE_COUNT,            7, "count",   CATALYST_APPEND,"LEX §4.1.5"),
    Q(EPISTEMIC_CONFIDENCE_THRESHOLD_Q14, 13926,    AMEND_APPLY, "TYPES §8.3"),
    U(COG_EXPLAIN_LEVELS,             5, "count",   CATALYST_APPEND,"LEX §4.1.5"),
    U(COG_REFLECT_TARGETS,            6, "count",   CATALYST_APPEND,"LEX §4.1.5"),
    U(COG_NARRATIVE_DECL_PER_MODULE,  1, "count",   AMEND_APPLY,   "GRAMMAR §5.6"),

/* ---------------- §14 Conformance ---------------- */
#undef SECT
#define SECT "§14"
    U(CONF_CRITERION_COUNT,          30, "count",   AMEND_APPLY,   "CONFORMANCE §1-3"),
    U(CONF_CORE_LANG_CRITERIA,       15, "count",   AMEND_APPLY,   "CONFORMANCE §1"),
    U(CONF_SUBSTRATE_RUNTIME_CRITERIA,10,"count",   AMEND_APPLY,   "CONFORMANCE §2"),
    U(CONF_COGNITIVE_LAYER_CRITERIA,  5, "count",   AMEND_APPLY,   "CONFORMANCE §3"),

/* ---------------- §15 ABI ---------------- */
#undef SECT
#define SECT "§15"
    U(ABI_LEGAL_NAME_COUNT,           1, "count",   AMEND_APPLY,   "ABI §1.1"),
    STR(ABI_LEGAL_NAME,        "c-msvc-x64",        AMEND_APPLY, "ABI §1.1"),
    U(ABI_RESERVED_NAME_COUNT,        4, "count",   CATALYST_APPEND,"ABI §3"),
    STR(ABI_EXTERN_INVERSE,  "Compromise<MEDIUM>",  NEVER_MUTABLE, "ABI §1.2"),
    STR(ABI_EXTERN_HEXAD,    "EXTERN_C_CALL",       AMEND_APPLY, "ABI §1.2"),
    U(ABI_EXTERN_RING_R0,             0, "ring",    AMEND_APPLY,   "ABI §1.2"),
    U(ABI_EXTERN_RING_R3,             3, "ring",    AMEND_APPLY,   "ABI §1.2"),

/* ---------------- §16 R1 family ---------------- */
#undef SECT
#define SECT "§16"
    U(R1_SLOT_COUNT_SEALED,          15, "count",   AMEND_APPLY,   "INDEX §1"),
    STR(R1_COMPOSITE_HASH_FN, "SHA-256",            AMEND_APPLY, "INDEX §2"),
    STR(R1_CONCATENATION_DISCIPLINE,
        "INDEX §1 order, big-endian, no separator", AMEND_APPLY, "STDLIB §17.1"),
    U(R1_RESERVED_WAVE_SLOTS,         4, "count",   SCHEDULED,     "STDLIB §20"),

/* ---------------- §17.1 Item 175 ZK Rollup ---------------- */
#undef SECT
#define SECT "§17.1"
    U(ZK_ROLLUP_COMPACTION_THRESHOLD, 1048576, "witnesses",
                                                    AMEND_APPLY, "Item 175"),
    U(ZK_PROOF_TARGET_BYTES,        256, "bytes",   AMEND_APPLY,   "Item 175"),
    U(ZK_DECOMMITMENT_RETENTION,   1024, "segments",AMEND_APPLY,   "Item 175"),

/* ---------------- §17.2 Item 176 Crypto Agility ---------------- */
#undef SECT
#define SECT "§17.2"
    U(CRYPTO_SUITE_ID_WIDTH_BITS,    64, "bits",    R2_MAJOR_BUMP, "Item 176"),
    U(CRYPTO_SUITE_PRE_QUANTUM,  0x0001, "suite-id",SEALED_DEFAULT,"Item 176"),
    U(CRYPTO_SUITE_POST_QUANTUM_1,0x0100,"suite-id",AMEND_APPLY,   "Item 176"),
    U(CRYPTO_SUITE_POST_QUANTUM_2,0x0200,"suite-id",AMEND_APPLY,   "Item 176"),
    U(CRYPTO_SUITE_HYBRID,       0x0300, "suite-id",AMEND_APPLY,   "Item 176"),
    U(CRYPTO_ACTIVE_SUITE_DRTM_OFFSET, 0x160, "offset",
                                                    AMEND_APPLY, "Item 176"),

/* ---------------- §17.3 Item 177 Genesis Vector ---------------- */
#undef SECT
#define SECT "§17.3"
    STR(GENESIS_INSTALLER_ABI, "c-msvc-x64",        AMEND_APPLY, "Item 177"),
    U(GENESIS_DISCOVERY_CADENCE_PER_TICK, 1, "per-tick",
                                                    AMEND_APPLY, "Item 177"),

/* ---------------- §17.4 Item 178 Founder's Anchor ---------------- */
#undef SECT
#define SECT "§17.4"
    U(FOUNDERS_ANCHOR_PUBKEY_SIZE_ED25519, 32, "bytes",
                                                    AMEND_APPLY, "Item 178"),
    U(FOUNDERS_ANCHOR_COSIGNED_FLAG_BIT, 8, "bit",  NEVER_MUTABLE, "Item 178"),
    U(FOUNDERS_ANCHOR_K_RECOMMENDED,  3, "count",   OPERATOR_POLICY,"Item 178"),
    U(FOUNDERS_ANCHOR_N_RECOMMENDED,  5, "count",   OPERATOR_POLICY,"Item 178"),
    U(FOUNDERS_ANCHOR_REJECTION_LAYERS,3,"count",   NEVER_MUTABLE, "Item 178"),

/* ---------------- §18 Founder's Anchor invariants ---------------- */
#undef SECT
#define SECT "§18"
    U(FOUNDERS_ANCHOR_INVARIANT_COUNT,10,"count",   NEVER_MUTABLE, "§18 list"),
    STR(FA_INV_PFS_BRICKING_UNREP, "6 PFS bricking-class hexads unrepresentable",
                                                    NEVER_MUTABLE, "HEXAD §4"),
    STR(FA_INV_PUBKEY_SOVEREIGN_VETO, "founders_anchor_pubkey is Cap<sovereign_veto,FOUNDER>",
                                                    NEVER_MUTABLE, "FOUNDERS-ANCHOR §3"),
    STR(FA_INV_TIER3_REQUIRES_COSIG,  "every Tier-3 amend.apply requires Anchor cosig",
                                                    NEVER_MUTABLE, "FOUNDERS-ANCHOR §3"),
    STR(FA_INV_REMOVE_ANCHOR_UNREP,   "removing Anchor produces unrepresentable hexad",
                                                    NEVER_MUTABLE, "FOUNDERS-ANCHOR §3"),
    STR(FA_INV_5_CATALYST_RAILS,      "5 Catalyst inviolable safety rails",
                                                    NEVER_MUTABLE, "CATALYST §4.1"),
    STR(FA_INV_3_PFS_REJECT_LAYERS,   "3 PFS-bricking rejection layers",
                                                    NEVER_MUTABLE, "HEXAD §4.5"),
    STR(FA_INV_32STEP_SID_TOTAL,      "32-step SID plan total",
                                                    NEVER_MUTABLE, "CYCLES §3.2"),
    STR(FA_INV_LAYER3_FULL_4CONJUNCT, "Layer 3 Trinity full 4-conjunct (no shortcut)",
                                                    NEVER_MUTABLE, "TRINITY §1.3"),
    STR(FA_INV_WITNESS_CHAIN_CONTINUITY, "witness chain continuity across rings/modules",
                                                    NEVER_MUTABLE, "C-17"),
    STR(FA_INV_IRPD_ONLY_PRIV_WRITES, "IRPD-only privileged writes (no raw WRMSR/MOV CR3)",
                                                    NEVER_MUTABLE, "C-16"),

/* ---------------- §19 Cross-cutting cascade ---------------- */
#undef SECT
#define SECT "§19"
    U(CASCADE_RULE_COUNT,             7, "count",   DERIVED,       "§19 table"),
    STR(CASCADE_WITNESS_BYTE_SIZE,
        "R1.A5+R1.A8+R1.B1",                        AMEND_APPLY, "§19"),
    STR(CASCADE_MOBIUS_FLOOR,
        "R1.A9+R1.B1+R1.B3",                        AMEND_APPLY, "§19"),
    STR(CASCADE_MNEME_PROMOTION_RATE,
        "R1.B1",                                    AMEND_APPLY, "§19"),
    STR(CASCADE_CRYPTO_SUITE,
        "R1.A1..R1.IDX (full)",                     AMEND_APPLY, "§19"),
    STR(CASCADE_SANCTUM_SLOT_COUNT,
        "R1.A8",                                    AMEND_APPLY, "§19"),
    STR(CASCADE_UNIVERSE_LADDER_DEPTH,
        "R1.A3+R1.B3 (R2-territory)",               R2_MAJOR_BUMP, "§19"),
    STR(CASCADE_HEXAD_PILLAR_COUNT,
        "R1.A6+R1.A3+R1.B3 (R2-territory)",         R2_MAJOR_BUMP, "§19"),
};

#define DEFS_N (sizeof(DEFS)/sizeof(DEFS[0]))

/* ====================================================================
 * Materialization: build the public table from DEFS on first use.
 * ==================================================================== */

static iii_constant_info_t   g_table[DEFS_N];
static uint8_t               g_value_pool[DEFS_N * 16 + 4096];
                              /* generous: numerics 8B, strings inlined */
static int                   g_initialized = 0;

static size_t encode_def(const def_t *d, uint8_t *out)
{
    switch (d->type) {
    case III_CT_U64:
    case III_CT_S64: {
        uint64_t v = (uint64_t)d->i;
        for (int k = 0; k < 8; ++k) out[k] = (uint8_t)((v >> (8*k)) & 0xFF);
        return 8;
    }
    case III_CT_Q14: {
        int16_t v = (int16_t)d->i;
        out[0] = (uint8_t)((uint16_t)v & 0xFF);
        out[1] = (uint8_t)(((uint16_t)v >> 8) & 0xFF);
        return 2;
    }
    case III_CT_BAND:
    case III_CT_TUPLE2: {
        uint32_t a = d->a, b = d->b;
        for (int k = 0; k < 4; ++k) out[k]   = (uint8_t)((a >> (8*k)) & 0xFF);
        for (int k = 0; k < 4; ++k) out[4+k] = (uint8_t)((b >> (8*k)) & 0xFF);
        return 8;
    }
    case III_CT_BOOL:
        out[0] = d->i ? 1 : 0;
        return 1;
    case III_CT_STRING: {
        size_t n = strlen(d->str);
        memcpy(out, d->str, n);
        return n;
    }
    case III_CT_BYTES:
        memcpy(out, d->raw, d->raw_len);
        return d->raw_len;
    }
    return 0;
}

static void init_once(void)
{
    if (g_initialized) return;
    size_t off = 0;
    for (size_t i = 0; i < DEFS_N; ++i) {
        const def_t *d = &DEFS[i];
        uint8_t *vp = &g_value_pool[off];
        size_t n = encode_def(d, vp);
        g_table[i].name         = d->name;
        g_table[i].value_bytes  = vp;
        g_table[i].value_len    = n;
        g_table[i].type_tag     = d->type;
        g_table[i].units        = d->units;
        g_table[i].mutation_tier= d->tier;
        g_table[i].hash_slot    = (uint32_t)(i + 1);
        g_table[i].source       = d->source;
        g_table[i].section      = d->section;
        off += n;
        if (off + 64 > sizeof(g_value_pool)) {
            /* This is a build-time invariant: pool is sized generously.
             * If we ever hit this, the table grew — bump the pool. */
            fprintf(stderr,
                "iii_constants: value pool overflow at slot %zu\n", i + 1);
            abort();
        }
    }
    g_initialized = 1;
}

/* ===== Internal accessors used by other compilation units ===== */

const iii_constant_info_t *iii__constants_table(size_t *out_n)
{
    init_once();
    *out_n = DEFS_N;
    return g_table;
}

size_t iii_constant_count(void)
{
    return DEFS_N;
}

const iii_constant_info_t *iii_constant_at(uint32_t slot)
{
    init_once();
    if (slot == 0 || slot > DEFS_N) return NULL;
    return &g_table[slot - 1];
}
