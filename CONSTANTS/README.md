# III CONSTANTS — Constitutional Constants Ledger (R1.D2)

Implementation of every constant catalogued in
[`DOCS/III-CONSTANTS.md`](../DOCS/III-CONSTANTS.md), the derivative
ledger that consolidates the constitutional-constants surface of all 15
R1-sealed specs plus the Cluster K (items 175–178) extensions.

## Layout

``
CONSTANTS/
  include/iii/
    constants.h               public API + every constant as a typed macro
    constants_internal.h      internal accessor shared between TUs
  src/
    constants_table.c         master ledger table (196 entries)
    constants_api.c           lookup, ledger root, validators
  tools/
    iii_constants_tool.c      CLI: dump | lookup | root | validate
  tests/
    test_constants.c          comprehensive test suite
  build/
    Makefile                  gcc build (Linux/MSYS/MinGW)
    build.bat                 gcc build (Windows cmd)
``

## Dependencies

* `LEXICON/build/libiii_lex.a` — for the SHA-256 implementation
  (`iii_sha256_*`). Pinned by build-time recompile against
  `LEXICON/include`.
* C11 toolchain with `-Wall -Wextra -Werror`.

## Build

``
cd CONSTANTS/build
build.bat            # Windows (MinGW gcc)
make                 # POSIX
``

Produces:

* `build/libiii_constants.a`
* `build/iii_constants_tool.exe`
* `build/iii_constants_test.exe`

## Test

``
build\iii_constants_test.exe
``

Last run: `=== 20911 passed, 0 failed ===`.

## Tool

``
iii_constants_tool dump
iii_constants_tool lookup <NAME>
iii_constants_tool root
iii_constants_tool validate <catalyst-append|amend-apply|r2-bump> <NAME> <NEW_VALUE>
``

`NEW_VALUE` formats:
* numeric (U64/S64/Q14): decimal or `0x` hex
* BAND/TUPLE2: `lo,hi`
* BOOL: `true`/`false`/`1`/`0`
* STRING: literal UTF-8
* BYTES: hex string

## Mutation paths

| Path | Validator |
|------|-----------|
| CATALYST-APPEND | `iii_constant_validate_catalyst_append` |
| AMEND-APPLY     | `iii_constant_validate_amend_apply`     |
| R2-MAJOR-BUMP   | `iii_constant_validate_r2_bump`         |

Validator decision matrix (entry's `mutation_tier` ⇒ allowed path):

| Tier | catalyst-append | amend-apply | r2-bump |
|------|-----------------|-------------|---------|
| `CATALYST_APPEND`    | ✓ (no regress) | ✗ wrong-tier   | ✗ wrong-tier   |
| `AMEND_APPLY`        | ✗              | ✓              | ✗              |
| `R2_MAJOR_BUMP`      | ✗              | ✗              | ✓              |
| `SEALED_DEFAULT`     | ✗              | ✓              | ✗              |
| `SCHEDULED`          | ✗              | ✓              | ✗              |
| `OPERATOR_POLICY`    | ✗              | ✓              | ✗              |
| `DERIVED`            | ✗              | ✗              | ✗              |
| `OPERATIONAL_TARGET` | ✗              | ✗              | ✗              |
| `NEVER_MUTABLE`      | ✗ never        | ✗ founders     | ✗ founders     |

The `✗ / ✗ / ✗` rows for `DERIVED` and `OPERATIONAL_TARGET` are **intentional, not
gaps** (RITCHIE Stage 1.21): a `DERIVED` constant is computed from other
constants (mutate the input, never the derived value), and an
`OPERATIONAL_TARGET` is a performance *target*, not a constitutional invariant
— e.g. the BCWL false-positive-rate target and the Layer 1/2/3 cycle-cost
targets in `DOCS/III-CONSTANTS.md §3`. Targets are aspirational/informational
and are deliberately unreachable by any mutation path. The spec preserves the
operational-target concept, so the enum value is kept (see `constants.h`).

## R1.D2 ledger root

Computed by `iii_constant_compute_ledger_root()` over the canonical
slot-ordered serialization of every entry (slot \| type \| tier \|
length-prefixed name/units/source/section \| value \| 0xFF separator),
prefixed by the 16-byte `III-CONSTANTS-D2` domain separator.

Current value:

``
R1.D2 = 575b7722d9c24fadad5a83050eb164faafa13aa51fe491ea7f76db7c7670e9ce
``

## Full constant index (196 entries)

``
[0001] LEX_KEYWORD_COUNT                            U64     CATALYST_APPEND     §2 47 (0x2f)  (LEX §4, units=count)
[0002] LEX_KEYWORD_RESERVED_SLOTS                   U64     CATALYST_APPEND     §2 16 (0x10)  (LEX §4, units=count)
[0003] LEX_KEYWORD_MAX                              U64     CATALYST_APPEND     §2 63 (0x3f)  (LEX §4, units=count)
[0004] LEX_MODIFIER_COUNT                           U64     CATALYST_APPEND     §2 19 (0x13)  (LEX §5, units=count)
[0005] LEX_MODIFIER_RESERVED_SLOTS                  U64     CATALYST_APPEND     §2 8 (0x8)  (LEX §5, units=count)
[0006] LEX_MODIFIER_MAX                             U64     CATALYST_APPEND     §2 27 (0x1b)  (LEX §5, units=count)
[0007] LEX_OPERATOR_COUNT                           U64     CATALYST_APPEND     §2 23 (0x17)  (LEX §6, units=count)
[0008] LEX_OPERATOR_RESERVED_SLOTS                  U64     CATALYST_APPEND     §2 7 (0x7)  (LEX §6, units=count)
[0009] LEX_OPERATOR_MAX                             U64     CATALYST_APPEND     §2 30 (0x1e)  (LEX §6, units=count)
[0010] LEX_PUNCTUATOR_COUNT                         U64     AMEND_APPLY         §2 25 (0x19)  (LEX §7, units=count)
[0011] LEX_RESERVED_UNUSED_CHARS                    U64     CATALYST_APPEND     §2 5 (0x5)  (LEX §7.3, units=count)
[0012] LEX_LITERAL_TOKEN_KINDS                      U64     AMEND_APPLY         §2 9 (0x9)  (LEX §3.1, units=count)
[0013] LEX_COMMENT_KINDS                            U64     AMEND_APPLY         §2 3 (0x3)  (LEX §10, units=count)
[0014] LEX_WHITESPACE_CHARS                         U64     AMEND_APPLY         §2 3 (0x3)  (LEX §11, units=count)
[0015] LEX_IDENT_MAX_CODEPOINTS                     U64     AMEND_APPLY         §2 256 (0x100)  (LEX §8.3, units=codepoints)
[0016] LEX_SOURCE_MAX_BYTES                         U64     AMEND_APPLY         §2 16777216 (0x1000000)  (LEX §2.7, units=bytes)
[0017] LEX_SOURCE_EXTENSION                         STRING  AMEND_APPLY         §2 ".III"  (LEX §2.6, units=utf8)
[0018] LEX_MOBIUS_DIACRITIC                         U64     AMEND_APPLY         §2 246 (0xf6)  (LEX §4.3, units=U+)
[0019] LEX_BOM_FORBIDDEN                            BOOL    R2_MAJOR_BUMP       §2 true  (LEX §2.2, units=bool)
[0020] LEX_LINE_ENDING                              STRING  AMEND_APPLY         §2 "LF"  (LEX §2.3, units=utf8)
[0021] TYPE_UNIVERSE_COUNT                          U64     R2_MAJOR_BUMP       §3 7 (0x7)  (TYPES §2, units=count)
[0022] TYPE_IMPREDICATIVE_TOP_INDEX                 U64     R2_MAJOR_BUMP       §3 6 (0x6)  (TYPES §2.4, units=index)
[0023] TYPE_Q14_BITS_TOTAL                          U64     R2_MAJOR_BUMP       §3 16 (0x10)  (TYPES §6, units=bits)
[0024] TYPE_Q14_FRAC_BITS                           U64     R2_MAJOR_BUMP       §3 14 (0xe)  (TYPES §6, units=bits)
[0025] TYPE_MHASH_SIZE                              U64     AMEND_APPLY         §3 32 (0x20)  (TYPES §6, units=bytes)
[0026] TYPE_GLYPH_SIZE                              U64     AMEND_APPLY         §3 192 (0xc0)  (LEX §4.1.1, units=bytes)
[0027] TYPE_WITNESS_SIZE                            U64     AMEND_APPLY         §3 128 (0x80)  (CYCLES §4.1, units=bytes)
[0028] TYPE_HEXAD_PACK_BITS_USED                    U64     R2_MAJOR_BUMP       §3 12 (0xc)  (HEXAD §2.2, units=bits)
[0029] TYPE_HEXAD_PACK_BITS_RESERVED                U64     R2_MAJOR_BUMP       §3 4 (0x4)  (HEXAD §2.2, units=bits)
[0030] TYPE_TRIT_CARDINALITY                        U64     R2_MAJOR_BUMP       §3 3 (0x3)  (HEXAD §1.1, units=count)
[0031] TYPE_REDUCTION_ARITY                         U64     R2_MAJOR_BUMP       §3 6 (0x6)  (TYPES §3, units=count)
[0032] TYPE_COMPROMISE_TIERS                        U64     AMEND_APPLY         §3 3 (0x3)  (EFFECTS §1.2, units=count)
[0033] TYPE_PROOF_KERNEL_LOC_BUDGET                 U64     AMEND_APPLY         §3 3000 (0xbb8)  (TYPES §11, units=LoC)
[0034] EFFECT_SE_KIND_COUNT                         U64     CATALYST_APPEND     §4 17 (0x11)  (EFFECTS §1.1, units=count)
[0035] EFFECT_COMPROMISE_TIER_COUNT                 U64     AMEND_APPLY         §4 3 (0x3)  (EFFECTS §1.2, units=count)
[0036] EFFECT_PFS_BRICKING_OPS                      U64     NEVER_MUTABLE       §4 6 (0x6)  (EFFECTS §1.3, units=count)
[0037] EFFECT_WAVEFRONT_TERMINATORS                 U64     CATALYST_APPEND     §4 3 (0x3)  (EFFECTS §7, units=count)
[0038] CYCLE_WITNESS_BYTE_SIZE                      U64     AMEND_APPLY         §5 128 (0x80)  (CYCLES §4.1, units=bytes)
[0039] CYCLE_WITNESS_PRED_OFFSET                    U64     R2_MAJOR_BUMP       §5 0 (0x0)  (CYCLES §4.1, units=offset)
[0040] CYCLE_WITNESS_PRED_BYTES                     U64     R2_MAJOR_BUMP       §5 32 (0x20)  (CYCLES §4.1, units=bytes)
[0041] CYCLE_WITNESS_SUCC_OFFSET                    U64     R2_MAJOR_BUMP       §5 32 (0x20)  (CYCLES §4.1, units=offset)
[0042] CYCLE_WITNESS_SUCC_BYTES                     U64     R2_MAJOR_BUMP       §5 32 (0x20)  (CYCLES §4.1, units=bytes)
[0043] CYCLE_WITNESS_STEP_KIND_OFFSET               U64     R2_MAJOR_BUMP       §5 64 (0x40)  (CYCLES §4.1, units=offset)
[0044] CYCLE_WITNESS_STEP_KIND_BYTES                U64     R2_MAJOR_BUMP       §5 4 (0x4)  (CYCLES §4.1, units=bytes)
[0045] CYCLE_WITNESS_FLAGS_OFFSET                   U64     CATALYST_APPEND     §5 100 (0x64)  (STDLIB §5.6, units=offset)
[0046] CYCLE_WITNESS_FLAGS_BYTES                    U64     CATALYST_APPEND     §5 4 (0x4)  (STDLIB §5.6, units=bytes)
[0047] CYCLE_WITNESS_HEXAD_OFFSET                   U64     R2_MAJOR_BUMP       §5 104 (0x68)  (CYCLES §4.1, units=offset)
[0048] CYCLE_WITNESS_HEXAD_BYTES                    U64     R2_MAJOR_BUMP       §5 24 (0x18)  (CYCLES §4.1, units=bytes)
[0049] CYCLE_BCWL_BLOOM_BITS                        U64     AMEND_APPLY         §5 4096 (0x1000)  (CYCLES §4.3, units=bits)
[0050] CYCLE_BCWL_BUCKETS                           U64     AMEND_APPLY         §5 16 (0x10)  (CYCLES §4.3, units=count)
[0051] CYCLE_BCWL_FP_TARGET_PERCENT                 U64     AMEND_APPLY         §5 1 (0x1)  (STDLIB §14.3, units=percent)
[0052] CYCLE_STEP_KIND_TOTAL_SLOTS                  U64     R2_MAJOR_BUMP       §5 512 (0x200)  (CYCLES §5.3, units=count)
[0053] SK_RESERVED_BOOT                             BAND    AMEND_APPLY         §5 0x0000..0x000f (16 slots)  (CYCLES §5.3, units=range)
[0054] SK_IRPD_PRIV_WRITE                           BAND    AMEND_APPLY         §5 0x0010..0x002f (32 slots)  (CYCLES §5.3, units=range)
[0055] SK_IRPD_PRIV_READ                            BAND    AMEND_APPLY         §5 0x0030..0x004f (32 slots)  (CYCLES §5.3, units=range)
[0056] SK_CYCLE_LIFECYCLE                           BAND    AMEND_APPLY         §5 0x0050..0x006f (32 slots)  (CYCLES §5.3, units=range)
[0057] SK_WAVEFRONT                                 BAND    AMEND_APPLY         §5 0x0070..0x007f (16 slots)  (CYCLES §5.3, units=range)
[0058] SK_SANCTUM                                   BAND    AMEND_APPLY         §5 0x0080..0x009f (32 slots)  (CYCLES §5.3, units=range)
[0059] SK_TRINITY                                   BAND    AMEND_APPLY         §5 0x00a0..0x00bf (32 slots)  (CYCLES §5.3, units=range)
[0060] SK_CEILING                                   BAND    AMEND_APPLY         §5 0x00c0..0x00cf (16 slots)  (CYCLES §5.3, units=range)
[0061] SK_FEDERATION                                BAND    AMEND_APPLY         §5 0x00d0..0x00ef (32 slots)  (CYCLES §5.3, units=range)
[0062] SK_DRTM                                      BAND    AMEND_APPLY         §5 0x00f0..0x00ff (16 slots)  (CYCLES §5.3, units=range)
[0063] SK_VDF                                       BAND    AMEND_APPLY         §5 0x0100..0x010f (16 slots)  (CYCLES §5.3, units=range)
[0064] SK_OBSERVATORY                               BAND    AMEND_APPLY         §5 0x0110..0x012f (32 slots)  (CYCLES §5.3, units=range)
[0065] SK_CATALYST                                  BAND    AMEND_APPLY         §5 0x0130..0x014f (32 slots)  (CYCLES §5.3, units=range)
[0066] SK_NARRATIVE                                 BAND    AMEND_APPLY         §5 0x0150..0x015f (16 slots)  (CYCLES §5.3, units=range)
[0067] SK_COGNITIVE                                 BAND    AMEND_APPLY         §5 0x0160..0x017f (32 slots)  (CYCLES §5.3, units=range)
[0068] SK_PFS                                       BAND    AMEND_APPLY         §5 0x0180..0x018f (16 slots)  (CYCLES §5.3, units=range)
[0069] SK_FED_RESERVED                              BAND    CATALYST_APPEND     §5 0x0190..0x01af (32 slots)  (CYCLES §5.3, units=range)
[0070] SK_USER_RESERVED                             BAND    CATALYST_APPEND     §5 0x01b0..0x01c6 (23 slots)  (CYCLES §5.3, units=range)
[0071] SK_MNEME_PROMOTE                             BAND    CATALYST_APPEND     §5 0x01c7..0x01cf (9 slots)  (CYCLES §5.3, units=range)
[0072] SK_RESERVED_FUTURE                           BAND    CATALYST_APPEND     §5 0x01d0..0x01ff (48 slots)  (CYCLES §5.3, units=range)
[0073] HEXAD_PILLAR_COUNT                           U64     R2_MAJOR_BUMP       §6 6 (0x6)  (HEXAD §2, units=count)
[0074] HEXAD_PILLAR_1_NAME                          STRING  R2_MAJOR_BUMP       §6 "INVERSE_DERIVABILITY"  (HEXAD §2.1, units=utf8)
[0075] HEXAD_PILLAR_2_NAME                          STRING  R2_MAJOR_BUMP       §6 "CAUSALITY_DEPTH"  (HEXAD §2.1, units=utf8)
[0076] HEXAD_PILLAR_3_NAME                          STRING  R2_MAJOR_BUMP       §6 "CONSENT_RECENCY"  (HEXAD §2.1, units=utf8)
[0077] HEXAD_PILLAR_4_NAME                          STRING  R2_MAJOR_BUMP       §6 "REPLICATION_TIER"  (HEXAD §2.1, units=utf8)
[0078] HEXAD_PILLAR_5_NAME                          STRING  R2_MAJOR_BUMP       §6 "ADVERSARIALITY_CLASS"  (HEXAD §2.1, units=utf8)
[0079] HEXAD_PILLAR_6_NAME                          STRING  R2_MAJOR_BUMP       §6 "COHERENCE_IMPACT"  (HEXAD §2.1, units=utf8)
[0080] HEXAD_TRIT_NEG_ASYM                          S64     R2_MAJOR_BUMP       §6 -2  (HEXAD §1.1, units=trit-asym)
[0081] HEXAD_TRIT_NEG_BALANCED                      S64     R2_MAJOR_BUMP       §6 -1  (HEXAD §1.1, units=trit-bal)
[0082] HEXAD_TRIT_NEG_PACKED                        U64     R2_MAJOR_BUMP       §6 0 (0x0)  (HEXAD §1.1, units=bits)
[0083] HEXAD_TRIT_ZERO_PACKED                       U64     R2_MAJOR_BUMP       §6 1 (0x1)  (HEXAD §1.1, units=bits)
[0084] HEXAD_TRIT_POS_PACKED                        U64     R2_MAJOR_BUMP       §6 2 (0x2)  (HEXAD §1.1, units=bits)
[0085] HEXAD_RESERVED_TRIT_BITPATTERN               U64     CATALYST_APPEND     §6 3 (0x3)  (HEXAD §2.2, units=bits)
[0086] HEXAD_TOTAL_POSSIBLE                         U64     R2_MAJOR_BUMP       §6 729 (0x2d9)  (HEXAD §3.1, units=count)
[0087] HEXAD_ADMISSIBLE                             U64     R2_MAJOR_BUMP       §6 144 (0x90)  (STDLIB §6.5, units=count)
[0088] HEXAD_ASYM_REACH6_BYTES                      U64     CATALYST_APPEND     §6 144 (0x90)  (HEXAD §3.1, units=bytes)
[0089] HEXAD_REACH_CODE_BIT_HI                      U64     R2_MAJOR_BUMP       §6 7 (0x7)  (STDLIB §6.5, units=bit)
[0090] HEXAD_REACH_CODE_BIT_LO                      U64     R2_MAJOR_BUMP       §6 6 (0x6)  (STDLIB §6.5, units=bit)
[0091] HEXAD_METADATA_BIT_HI                        U64     CATALYST_APPEND     §6 5 (0x5)  (STDLIB §6.5, units=bit)
[0092] HEXAD_METADATA_BIT_LO                        U64     CATALYST_APPEND     §6 0 (0x0)  (STDLIB §6.5, units=bit)
[0093] HEXAD_REACH_CODE_COUNT                       U64     CATALYST_APPEND     §6 4 (0x4)  (HEXAD §3.1, units=count)
[0094] HEXAD_PFS_BRICKING_HEXADS                    U64     NEVER_MUTABLE       §6 6 (0x6)  (HEXAD §4.2, units=count)
[0095] HEXAD_BITMAP_MHASH_FUNC                      STRING  DERIVED             §6 "SHA-256"  (HEXAD §3.4, units=utf8)
[0096] PHASE_RING_COUNT                             U64     R2_MAJOR_BUMP       §7 4 (0x4)  (PHASES §1, units=count)
[0097] PHASE_RING_LATTICE_ORDER                     STRING  R2_MAJOR_BUMP       §7 "R-2<=R-1<=R0<=R3"  (PHASES §1, units=utf8)
[0098] PHASE_CROSS_RING_CONSTRUCTORS                U64     AMEND_APPLY         §7 5 (0x5)  (PHASES §3, units=count)
[0099] PHASE_MARSHALLING_RULES                      U64     AMEND_APPLY         §7 5 (0x5)  (PHASES §4, units=count)
[0100] XII_PHASE_PROMOTE_RATE                       U64     AMEND_APPLY         §7 4 (0x4)  (PHASES §5, units=per-tick)
[0101] PHASE_MAGIC_MSR_ADDRESS                      U64     AMEND_APPLY         §7 3221352704 (0xc001f100)  (PHASES §3.1, units=MSR)
[0102] SANCTUM_SEAL_COUNT                           U64     AMEND_APPLY         §8 10 (0xa)  (SANCTUM §1.1, units=slots)
[0103] SANCTUM_SLOT_INVALID                         U64     NEVER_MUTABLE       §8 0 (0x0)  (SANCTUM §1.1, units=slot)
[0104] SANCTUM_SLOT_DRTM_RELAUNCH                   U64     NEVER_MUTABLE       §8 1 (0x1)  (SANCTUM §1.1, units=slot)
[0105] SANCTUM_SLOT_PFS_VAR_SET                     U64     NEVER_MUTABLE       §8 2 (0x2)  (SANCTUM §1.1, units=slot)
[0106] SANCTUM_SLOT_PFS_DENY_QUOTE                  U64     NEVER_MUTABLE       §8 3 (0x3)  (SANCTUM §1.1, units=slot)
[0107] SANCTUM_SLOT_CRCC_KEY_EXPORT                 U64     NEVER_MUTABLE       §8 4 (0x4)  (SANCTUM §1.1, units=slot)
[0108] SANCTUM_SLOT_PHOENIX_EMERGENCY               U64     NEVER_MUTABLE       §8 5 (0x5)  (SANCTUM §1.1, units=slot)
[0109] SANCTUM_SLOT_CHRONOS_SET_EPOCH               U64     NEVER_MUTABLE       §8 6 (0x6)  (SANCTUM §1.1, units=slot)
[0110] SANCTUM_SLOT_COMPROMISE_QUOTE                U64     NEVER_MUTABLE       §8 7 (0x7)  (SANCTUM §1.1, units=slot)
[0111] SANCTUM_SLOT_PHOENIX_BOOKMARK                U64     NEVER_MUTABLE       §8 8 (0x8)  (SANCTUM §1.1, units=slot)
[0112] SANCTUM_SLOT_COMPILE_MODULE                  U64     NEVER_MUTABLE       §8 9 (0x9)  (SANCTUM §1.1, units=slot)
[0113] SANCTUM_GATE_HARDENING                       STRING  AMEND_APPLY         §8 "IBPB+VERW+SSBD+RSP-swap+GPR/FPR/XMM-save"  (SANCTUM §2.1, units=utf8)
[0114] DRTM_QUOTE_BYTE_SIZE                         U64     AMEND_APPLY         §8 312 (0x138)  (SANCTUM §4, units=bytes)
[0115] SANCTUM_PER_CPU_FRAME_SIZE                   U64     AMEND_APPLY         §8 160 (0xa0)  (STDLIB §8.8, units=bytes)
[0116] TRINITY_LAYER_COUNT                          U64     AMEND_APPLY         §9 3 (0x3)  (TRINITY §1, units=count)
[0117] TRINITY_GATE_CONJUNCTS                       U64     AMEND_APPLY         §9 4 (0x4)  (TRINITY §1.3, units=count)
[0118] TRINITY_SCBA_BYTES                           U64     AMEND_APPLY         §9 8192 (0x2000)  (TRINITY §1.1, units=bytes)
[0119] TRINITY_SCBA_BITS                            U64     AMEND_APPLY         §9 65536 (0x10000)  (TRINITY §1.1, units=bits)
[0120] TRINITY_SCBA_HASH_FN                         STRING  AMEND_APPLY         §9 "first16(BLAKE3(post_state))"  (TRINITY §1.1, units=utf8)
[0121] TRINITY_FAILURE_MODE_CODES                   U64     CATALYST_APPEND     §9 11 (0xb)  (TRINITY §2, units=count)
[0122] TRINITY_CONVERGENCE_PT_SIZE                  U64     AMEND_APPLY         §9 128 (0x80)  (STDLIB §9.5, units=bytes)
[0123] MODULE_CLOSURE_ROOT_HASH_FN                  STRING  AMEND_APPLY         §10 "SHA-256"  (MODULES §1, units=utf8)
[0124] MODULE_DEPLOY_FLAG_COUNT                     U64     AMEND_APPLY         §10 3 (0x3)  (MODULES §6.1, units=count)
[0125] XII_MOD_PROMOTE_RATE                         U64     AMEND_APPLY         §10 16 (0x10)  (MODULES §10, units=per-tick)
[0126] MODULE_TRANSMISSION_RULES                    U64     AMEND_APPLY         §10 5 (0x5)  (MODULES §3.1, units=count)
[0127] MODULE_FP_TOLERANCE_PERCENT                  U64     AMEND_APPLY         §10 5 (0x5)  (MODULES §4.1, units=percent)
[0128] XII_MNEME_CATALYST_PROMOTION_RATE_PER_TICK   U64     AMEND_APPLY         §11 8 (0x8)  (CATALYST §2.3, units=per-tick)
[0129] CATALYST_PROMOTION_GATE_COUNT                U64     AMEND_APPLY         §11 8 (0x8)  (CATALYST §2.1, units=count)
[0130] CATALYST_SYNTHESIS_CAP_COUNT                 U64     AMEND_APPLY         §11 7 (0x7)  (CATALYST §3, units=count)
[0131] CATALYST_INVIOLABLE_RAILS                    U64     NEVER_MUTABLE       §11 5 (0x5)  (CATALYST §4.1, units=count)
[0132] MOBIUS_COHERENCE_FLOOR_Q14                   Q14     AMEND_APPLY         §11 15073 (Q14 ≈ 0.91998)  (CATALYST §2.1, units=Q14)
[0133] CATALYST_BURN_IN_TICKS                       U64     AMEND_APPLY         §11 1048576 (0x100000)  (CATALYST §2.1, units=ticks)
[0134] CATALYST_OPERATOR_OVERRIDE_MECHS             U64     AMEND_APPLY         §11 4 (0x4)  (CATALYST §4.3, units=count)
[0135] FED_TIER_COUNT                               U64     AMEND_APPLY         §12 4 (0x4)  (FEDERATION §1, units=count)
[0136] FED_TIER1_QUORUM                             TUPLE2  AMEND_APPLY         §12 (3, 2)  (FEDERATION §4, units=(N,K))
[0137] FED_TIER2_QUORUM                             TUPLE2  AMEND_APPLY         §12 (5, 3)  (FEDERATION §4, units=(N,K))
[0138] FED_TIER3_QUORUM                             STRING  AMEND_APPLY         §12 "(N,N) unanimous"  (FEDERATION §4, units=utf8)
[0139] FED_REPLICATION_POLICY_VALUES                U64     CATALYST_APPEND     §12 4 (0x4)  (LEX §5.1, units=count)
[0140] FED_DISCOVERY_CADENCE_PER_TICK               U64     AMEND_APPLY         §12 1 (0x1)  (STDLIB §12.6, units=per-tick)
[0141] FED_AH_TRAILER_ACTIVE                        BOOL    AMEND_APPLY         §12 true  (FEDERATION §5, units=bool)
[0142] COG_PRIMITIVE_COUNT                          U64     CATALYST_APPEND     §13 7 (0x7)  (LEX §4.1.5, units=count)
[0143] EPISTEMIC_CONFIDENCE_THRESHOLD_Q14           Q14     AMEND_APPLY         §13 13926 (Q14 ≈ 0.84998)  (TYPES §8.3, units=Q14)
[0144] COG_EXPLAIN_LEVELS                           U64     CATALYST_APPEND     §13 5 (0x5)  (LEX §4.1.5, units=count)
[0145] COG_REFLECT_TARGETS                          U64     CATALYST_APPEND     §13 6 (0x6)  (LEX §4.1.5, units=count)
[0146] COG_NARRATIVE_DECL_PER_MODULE                U64     AMEND_APPLY         §13 1 (0x1)  (GRAMMAR §5.6, units=count)
[0147] CONF_CRITERION_COUNT                         U64     AMEND_APPLY         §14 30 (0x1e)  (CONFORMANCE §1-3, units=count)
[0148] CONF_CORE_LANG_CRITERIA                      U64     AMEND_APPLY         §14 15 (0xf)  (CONFORMANCE §1, units=count)
[0149] CONF_SUBSTRATE_RUNTIME_CRITERIA              U64     AMEND_APPLY         §14 10 (0xa)  (CONFORMANCE §2, units=count)
[0150] CONF_COGNITIVE_LAYER_CRITERIA                U64     AMEND_APPLY         §14 5 (0x5)  (CONFORMANCE §3, units=count)
[0151] ABI_LEGAL_NAME_COUNT                         U64     AMEND_APPLY         §15 1 (0x1)  (ABI §1.1, units=count)
[0152] ABI_LEGAL_NAME                               STRING  AMEND_APPLY         §15 "c-msvc-x64"  (ABI §1.1, units=utf8)
[0153] ABI_RESERVED_NAME_COUNT                      U64     CATALYST_APPEND     §15 4 (0x4)  (ABI §3, units=count)
[0154] ABI_EXTERN_INVERSE                           STRING  NEVER_MUTABLE       §15 "Compromise<MEDIUM>"  (ABI §1.2, units=utf8)
[0155] ABI_EXTERN_HEXAD                             STRING  AMEND_APPLY         §15 "EXTERN_C_CALL"  (ABI §1.2, units=utf8)
[0156] ABI_EXTERN_RING_R0                           U64     AMEND_APPLY         §15 0 (0x0)  (ABI §1.2, units=ring)
[0157] ABI_EXTERN_RING_R3                           U64     AMEND_APPLY         §15 3 (0x3)  (ABI §1.2, units=ring)
[0158] R1_SLOT_COUNT_SEALED                         U64     AMEND_APPLY         §16 15 (0xf)  (INDEX §1, units=count)
[0159] R1_COMPOSITE_HASH_FN                         STRING  AMEND_APPLY         §16 "SHA-256"  (INDEX §2, units=utf8)
[0160] R1_CONCATENATION_DISCIPLINE                  STRING  AMEND_APPLY         §16 "INDEX §1 order, big-endian, no separator"  (STDLIB §17.1, units=utf8)
[0161] R1_RESERVED_WAVE_SLOTS                       U64     SCHEDULED           §16 4 (0x4)  (STDLIB §20, units=count)
[0162] ZK_ROLLUP_COMPACTION_THRESHOLD               U64     AMEND_APPLY         §17.1 1048576 (0x100000)  (Item 175, units=witnesses)
[0163] ZK_PROOF_TARGET_BYTES                        U64     AMEND_APPLY         §17.1 256 (0x100)  (Item 175, units=bytes)
[0164] ZK_DECOMMITMENT_RETENTION                    U64     AMEND_APPLY         §17.1 1024 (0x400)  (Item 175, units=segments)
[0165] CRYPTO_SUITE_ID_WIDTH_BITS                   U64     R2_MAJOR_BUMP       §17.2 64 (0x40)  (Item 176, units=bits)
[0166] CRYPTO_SUITE_PRE_QUANTUM                     U64     SEALED_DEFAULT      §17.2 1 (0x1)  (Item 176, units=suite-id)
[0167] CRYPTO_SUITE_POST_QUANTUM_1                  U64     AMEND_APPLY         §17.2 256 (0x100)  (Item 176, units=suite-id)
[0168] CRYPTO_SUITE_POST_QUANTUM_2                  U64     AMEND_APPLY         §17.2 512 (0x200)  (Item 176, units=suite-id)
[0169] CRYPTO_SUITE_HYBRID                          U64     AMEND_APPLY         §17.2 768 (0x300)  (Item 176, units=suite-id)
[0170] CRYPTO_ACTIVE_SUITE_DRTM_OFFSET              U64     AMEND_APPLY         §17.2 352 (0x160)  (Item 176, units=offset)
[0171] GENESIS_INSTALLER_ABI                        STRING  AMEND_APPLY         §17.3 "c-msvc-x64"  (Item 177, units=utf8)
[0172] GENESIS_DISCOVERY_CADENCE_PER_TICK           U64     AMEND_APPLY         §17.3 1 (0x1)  (Item 177, units=per-tick)
[0173] FOUNDERS_ANCHOR_PUBKEY_SIZE_ED25519          U64     AMEND_APPLY         §17.4 32 (0x20)  (Item 178, units=bytes)
[0174] FOUNDERS_ANCHOR_COSIGNED_FLAG_BIT            U64     NEVER_MUTABLE       §17.4 8 (0x8)  (Item 178, units=bit)
[0175] FOUNDERS_ANCHOR_K_RECOMMENDED                U64     OPERATOR_POLICY     §17.4 3 (0x3)  (Item 178, units=count)
[0176] FOUNDERS_ANCHOR_N_RECOMMENDED                U64     OPERATOR_POLICY     §17.4 5 (0x5)  (Item 178, units=count)
[0177] FOUNDERS_ANCHOR_REJECTION_LAYERS             U64     NEVER_MUTABLE       §17.4 3 (0x3)  (Item 178, units=count)
[0178] FOUNDERS_ANCHOR_INVARIANT_COUNT              U64     NEVER_MUTABLE       §18 10 (0xa)  (§18 list, units=count)
[0179] FA_INV_PFS_BRICKING_UNREP                    STRING  NEVER_MUTABLE       §18 "6 PFS bricking-class hexads unrepresentable"  (HEXAD §4, units=utf8)
[0180] FA_INV_PUBKEY_SOVEREIGN_VETO                 STRING  NEVER_MUTABLE       §18 "founders_anchor_pubkey is Cap<sovereign_veto,FOUNDER>"  (FOUNDERS-ANCHOR §3, units=utf8)
[0181] FA_INV_TIER3_REQUIRES_COSIG                  STRING  NEVER_MUTABLE       §18 "every Tier-3 amend.apply requires Anchor cosig"  (FOUNDERS-ANCHOR §3, units=utf8)
[0182] FA_INV_REMOVE_ANCHOR_UNREP                   STRING  NEVER_MUTABLE       §18 "removing Anchor produces unrepresentable hexad"  (FOUNDERS-ANCHOR §3, units=utf8)
[0183] FA_INV_5_CATALYST_RAILS                      STRING  NEVER_MUTABLE       §18 "5 Catalyst inviolable safety rails"  (CATALYST §4.1, units=utf8)
[0184] FA_INV_3_PFS_REJECT_LAYERS                   STRING  NEVER_MUTABLE       §18 "3 PFS-bricking rejection layers"  (HEXAD §4.5, units=utf8)
[0185] FA_INV_32STEP_SID_TOTAL                      STRING  NEVER_MUTABLE       §18 "32-step SID plan total"  (CYCLES §3.2, units=utf8)
[0186] FA_INV_LAYER3_FULL_4CONJUNCT                 STRING  NEVER_MUTABLE       §18 "Layer 3 Trinity full 4-conjunct (no shortcut)"  (TRINITY §1.3, units=utf8)
[0187] FA_INV_WITNESS_CHAIN_CONTINUITY              STRING  NEVER_MUTABLE       §18 "witness chain continuity across rings/modules"  (C-17, units=utf8)
[0188] FA_INV_IRPD_ONLY_PRIV_WRITES                 STRING  NEVER_MUTABLE       §18 "IRPD-only privileged writes (no raw WRMSR/MOV CR3)"  (C-16, units=utf8)
[0189] CASCADE_RULE_COUNT                           U64     DERIVED             §19 7 (0x7)  (§19 table, units=count)
[0190] CASCADE_WITNESS_BYTE_SIZE                    STRING  AMEND_APPLY         §19 "R1.A5+R1.A8+R1.B1"  (§19, units=utf8)
[0191] CASCADE_MOBIUS_FLOOR                         STRING  AMEND_APPLY         §19 "R1.A9+R1.B1+R1.B3"  (§19, units=utf8)
[0192] CASCADE_MNEME_PROMOTION_RATE                 STRING  AMEND_APPLY         §19 "R1.B1"  (§19, units=utf8)
[0193] CASCADE_CRYPTO_SUITE                         STRING  AMEND_APPLY         §19 "R1.A1..R1.IDX (full)"  (§19, units=utf8)
[0194] CASCADE_SANCTUM_SLOT_COUNT                   STRING  AMEND_APPLY         §19 "R1.A8"  (§19, units=utf8)
[0195] CASCADE_UNIVERSE_LADDER_DEPTH                STRING  R2_MAJOR_BUMP       §19 "R1.A3+R1.B3 (R2-territory)"  (§19, units=utf8)
[0196] CASCADE_HEXAD_PILLAR_COUNT                   STRING  R2_MAJOR_BUMP       §19 "R1.A6+R1.A3+R1.B3 (R2-territory)"  (§19, units=utf8)
``

## Source provenance

Every row above carries its `(source, units)` tuple in parentheses.
`source` cites the originating sealed spec (LEX, TYPES, EFFECTS,
CYCLES, HEXAD, PHASES, SANCTUM, TRINITY, MODULES, CATALYST, FEDERATION,
ABI, CONFORMANCE, INDEX, STDLIB) and the Cluster K item numbers
(175–178). The ledger itself is **derivative** — it does not seal new
values; it catalogues what is already sealed.
