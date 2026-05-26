/* III Grammar — AST node kinds and node structure.
 *
 * The enumerator values below are SEALED: every value comes verbatim
 * from III-GRAMMAR.bnf §11.  Gaps are intentional (Catalyst-reserved
 * slots).  Adding, removing, or renumbering any value alters R1.A2
 * and is forbidden outside a sealed major-version bump (§12, §13).
 *
 * NIH discipline: only libc.  No external deps.
 */
#ifndef III_AST_H
#define III_AST_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef enum iii_ast_kind {
    /* §4 — Module level */
    III_AST_MODULE                          = 0,
    III_AST_QUALIFIED_NAME                  = 1,
    III_AST_MODULE_ATTR                     = 2,
    III_AST_IMPORT                          = 3,
    III_AST_IMPORT_ATTR                     = 4,

    /* §5 — Items */
    III_AST_CYCLE_DECL                      = 10,
    III_AST_FORWARD_BLOCK                   = 11,
    III_AST_INVERSE_BLOCK                   = 12,
    III_AST_CYCLE_MODIFIER                  = 13,
    III_AST_FUNCTION_DECL                   = 14,
    III_AST_GENERIC_PARAM                   = 15,
    III_AST_FUNCTION_MODIFIER               = 16,
    III_AST_PARAM                           = 17,
    III_AST_TYPE_DECL                       = 18,
    III_AST_TYPE_MODIFIER                   = 19,
    III_AST_MOBIUS_CANDIDATE_DECL           = 20,
    III_AST_MOBIUS_CANDIDATE_MODIFIER       = 21,
    III_AST_SCHEMA_DECL                     = 22,
    III_AST_SCHEMA_FIELD                    = 23,
    III_AST_NARRATIVE_DECL                  = 24,
    III_AST_NARRATIVE_FIELD                 = 25,
    III_AST_CONST_DECL                      = 26,
    III_AST_EXTERN_DECL                     = 27,
    III_AST_EXTERN_ITEM                     = 28,
    III_AST_DOC_ATTACHED                    = 29,

    /* §6 — Types */
    III_AST_TYPE                            = 40,
    III_AST_BASE_TYPE                       = 41,
    III_AST_PRIMITIVE_TYPE                  = 42,
    III_AST_FUNCTION_TYPE                   = 43,
    III_AST_TUPLE_TYPE                      = 44,
    III_AST_ARRAY_TYPE                      = 45,
    III_AST_GENERIC_ARGS                    = 46,
    III_AST_HOLE                            = 47,
    III_AST_RING_SET                        = 48,
    III_AST_TIER_NAME                       = 49,
    III_AST_REPLICATION_POLICY              = 50,
    III_AST_RANGE                           = 51,
    III_AST_EPOCH_VALUE                     = 52,
    III_AST_HEXAD_DESIGNATOR                = 53,
    III_AST_COHERENCE_EXPR                  = 54,
    III_AST_COMPROMISE_TIER                 = 55,

    /* §7 — Statements */
    III_AST_LET_STMT                        = 70,
    III_AST_ASSIGN_STMT                     = 71,
    III_AST_PLACE_EXPR                      = 72,
    III_AST_IF_STMT                         = 73,
    III_AST_MATCH_STMT                      = 74,
    III_AST_MATCH_ARM                       = 75,
    III_AST_FOR_STMT                        = 76,
    III_AST_WHILE_STMT                      = 77,
    III_AST_WAVEFRONT_STMT                  = 78,
    III_AST_WAVEFRONT_MODIFIER              = 79,
    III_AST_WAVEFRONT_TERMINATOR            = 80,
    III_AST_SANCTUM_STMT                    = 81,
    III_AST_METAL_STMT                      = 82,
    III_AST_RETURN_STMT                     = 83,
    III_AST_PROMOTE_STMT                    = 84,
    III_AST_EXPLAIN_STMT                    = 85,
    III_AST_PROPOSE_STMT                    = 86,
    III_AST_PROPOSE_FIELD                   = 87,
    III_AST_NEGOTIATE_STMT                  = 88,
    III_AST_NEGOTIATE_ARG                   = 89,
    III_AST_REFLECT_STMT                    = 90,
    III_AST_COMMIT_STMT                     = 91,
    III_AST_COMMIT_ARG                      = 92,
    III_AST_REVERSE_STMT                    = 93,
    III_AST_ASK_STMT                        = 94,
    III_AST_EFFECT_STMT                     = 95,
    III_AST_BLOCK_STMT                      = 96,
    III_AST_BLOCK_EXPR                      = 97,

    /* §8 — Expressions */
    III_AST_EXPR_LVL_0                      = 110,
    III_AST_EXPR_LVL_1                      = 111,
    III_AST_EXPR_LVL_2                      = 112,
    III_AST_EXPR_LVL_3                      = 113,
    III_AST_EXPR_LVL_4                      = 114,
    III_AST_EXPR_LVL_5                      = 115,
    III_AST_EXPR_LVL_6                      = 116,
    III_AST_EXPR_LVL_7                      = 117,
    III_AST_EXPR_LVL_8                      = 118,
    III_AST_EXPR_LVL_10                     = 119,
    III_AST_EXPR_LVL_11                     = 120,
    III_AST_EXPR_LVL_12                     = 121,
    III_AST_EXPR_LVL_13                     = 122,
    III_AST_PRIMARY                         = 123,
    III_AST_LITERAL                         = 124,
    III_AST_TUPLE_LITERAL                   = 125,
    III_AST_RECORD_LITERAL                  = 126,
    III_AST_RECORD_FIELD                    = 127,
    III_AST_ARRAY_LITERAL                   = 128,
    III_AST_CYCLE_INVOKE                    = 129,
    III_AST_SANCTUM_INVOKE                  = 130,
    III_AST_IRPD_CALL                       = 131,
    III_AST_CALL                            = 132,
    III_AST_INDEX                           = 133,
    III_AST_FIELD_ACCESS                    = 134,
    III_AST_PATH                            = 135,
    III_AST_NAMED_ARG                       = 136,
    III_AST_PHASE_CROSS                     = 137,
    III_AST_EPOCH_BRIDGE                    = 138,
    III_AST_CAP_ACQUIRE_RELEASE             = 139,
    III_AST_COHERENCE_QUERY                 = 140,
    III_AST_GLYPH_MATERIALIZE               = 141,
    III_AST_WITNESS_EMIT                    = 142,
    III_AST_REPLAY                          = 143,
    III_AST_FULL_INVERSE_REPLAY             = 144,
    III_AST_INVERSE                         = 145,
    III_AST_PREFIX_OP                       = 146,
    III_AST_INFIX_OP                        = 147,

    /* §9 — Patterns */
    III_AST_LITERAL_PATTERN                 = 170,
    III_AST_IDENT_PATTERN                   = 171,
    III_AST_WILDCARD_PATTERN                = 172,
    III_AST_TUPLE_PATTERN                   = 173,
    III_AST_RECORD_PATTERN                  = 174,
    III_AST_RECORD_PATTERN_FIELD            = 175,
    III_AST_HEXAD_PATTERN                   = 176,
    III_AST_TRIT_PATTERN                    = 177,
    III_AST_RANGE_PATTERN                   = 178,
    III_AST_PATH_PATTERN                    = 179,
    III_AST_OR_PATTERN                      = 180,
    III_AST_GUARD_PATTERN                   = 181,

    /* Reserved — Catalyst-promoted (per §13) */
    III_AST_RESERVED_001                    = 200,
    III_AST_RESERVED_002                    = 201,
    III_AST_RESERVED_003                    = 202,
    III_AST_RESERVED_004                    = 203,
    III_AST_RESERVED_005                    = 204,
    III_AST_RESERVED_006                    = 205,
    III_AST_RESERVED_007                    = 206,
    III_AST_RESERVED_008                    = 207,
    III_AST_RESERVED_009                    = 208,
    III_AST_RESERVED_010                    = 209,
    III_AST_RESERVED_011                    = 210,
    III_AST_RESERVED_012                    = 211,
    III_AST_RESERVED_013                    = 212,
    III_AST_RESERVED_014                    = 213,
    III_AST_RESERVED_015                    = 214,
    III_AST_RESERVED_016                    = 215,
    III_AST_RESERVED_017                    = 216,
    III_AST_RESERVED_018                    = 217,
    III_AST_RESERVED_019                    = 218,
    III_AST_RESERVED_020                    = 219,
    III_AST_RESERVED_021                    = 220,
    III_AST_RESERVED_022                    = 221,
    III_AST_RESERVED_023                    = 222,
    III_AST_RESERVED_024                    = 223,
    III_AST_RESERVED_025                    = 224,
    III_AST_RESERVED_026                    = 225,
    III_AST_RESERVED_027                    = 226,
    III_AST_RESERVED_028                    = 227,
    III_AST_RESERVED_029                    = 228,
    III_AST_RESERVED_030                    = 229,
    III_AST_RESERVED_031                    = 230,
    III_AST_RESERVED_032                    = 231,

    /* Diagnostic */
    III_AST_ERROR                           = 240,
    III_AST_RECOVERY                        = 241,

    III_AST_KIND_COUNT                      = 256
} iii_ast_kind_t;

/* Sentinel value for "no doc-comment attached". */
#define III_AST_NO_DOC ((uint32_t)0xFFFFFFFFu)

typedef struct iii_ast_node iii_ast_node_t;

struct iii_ast_node {
    iii_ast_kind_t   kind;

    /* source span (byte offsets into source) */
    uint32_t span_start, span_end;
    uint32_t line, col;

    /* payload for leaf-ish nodes */
    uint32_t  interned_id;       /* IDENT, KEYWORD-bearing nodes */
    uint64_t  int_value;         /* INT/Q14/TRIT */
    uint8_t   mhash_value[32];   /* MHASH literal */
    uint16_t  hexad_packed;      /* HEXAD literal */
    uint8_t   int_suffix;        /* iii_int_suffix_t */
    uint16_t  op_id;             /* operator/punctuator/keyword/modifier id */
    const uint8_t *string_payload; /* string literal payload (borrowed) */
    size_t    string_len;

    /* doc-comment attachment (III_AST_NO_DOC = none) */
    uint32_t  doc_offset;

    /* children */
    iii_ast_node_t **children;
    uint32_t  child_count;
    uint32_t  child_cap;
};

/* Returns a stable, human-readable name for the AST kind.  Returns
 * "UNKNOWN" for any value outside the sealed enumerator. */
const char *iii_ast_kind_name(iii_ast_kind_t k);

#ifdef __cplusplus
}
#endif
#endif
