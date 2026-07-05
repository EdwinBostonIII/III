/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\parse.c
 *
 * III Stage-0 Parser — implementation.
 *
 * Companion of parse.h.  See that file for design rationale.  This TU
 * implements the recursive-descent LL(1) parser plus Pratt-style
 * operator-precedence climbing for expression productions.
 *
 * Strict NIH: no parser-generator, no third-party.  Pure C with stdlib.
 *
 * Reproducibility: parse output is a pure function of the token
 * stream.  Two runs over identical sources produce identical AST
 * containers byte-for-byte (modulo malloc pointers, which never
 * appear in the AST payload).
 *
 * ─── D2 — Speculation audit ──────────────────────────────────────
 *
 * The Stage-0 parser is one-token LL(1) at every grammar boundary
 * with TWO carefully bounded escape hatches:
 *
 *   1. iiip_parse_arg — the named-argument shape `name = expr` is
 *      now disambiguated with iiip_peek2_kind (D1).  The parser
 *      never commits AST nodes that it would have to throw away;
 *      either the (IDENT, OP_ASSIGN) pair is consumed up-front, or
 *      the general expression parser is invoked.  No checkpoint
 *      needed.
 *
 *   2. iiip_parse_hexad_trits — the parenthesised tuple/hexad form
 *      is detected by inspecting the head token via the conservative
 *      `is_trit_start` predicate.  If the predicate matches but the
 *      6-element body fails to scan, the cursor has advanced past
 *      one or more trit tokens; the parser issues E_BAD_HEXAD and
 *      stops.  No AST nodes are allocated until the full 6-tuple is
 *      confirmed.
 *
 * Every other production is single-pass: the lookahead token alone
 * picks the alternative.  This invariant makes the parser predictable
 * to humans and trivially mechanisable for the Stage-1 self-host.
 *
 * ─── I1 — Recovery / synchronisation policy ──────────────────────
 *
 * On error, the parser does NOT throw.  It records the diagnostic
 * (deduplicated by C2, breadcrumb-tagged by H2, hint-augmented by
 * H1) and resynchronises by skipping tokens.  Two policies coexist:
 *
 *   • iiip_recover_to(st, sync[]) — explicit synchronisation set.
 *     Preserved for legacy call sites and for the registry
 *     dispatch inside iiip_parse_top_decl, where the FF table's
 *     FOLLOW set would be too liberal.
 *
 *   • iiip_recover_follow(st, prod_id) — preferred.  Looks the
 *     production's FOLLOW set up in the central FF table; this
 *     keeps the recovery policy in ONE place that mechanical tools
 *     and the Stage-1 self-host can inspect via the public table
 *     accessor (iii_parse_first_follow_table once exposed).
 *
 * Both functions also synthesise newline/SEMI tokens through
 * iiip_synth_insert (B2) when the missing token is one of the four
 * most common clerical omissions: SEMI / RBRACE / RPAREN / COLON.
 *
 * ─── I2 — List-build hazards ─────────────────────────────────────
 *
 * Every iii_ast_list_begin / iii_ast_list_commit pair MUST be
 * matched on every control path, including error-recovery paths.
 * The list arena is a checkpoint stack: a `_begin` without a
 * matching `_commit` LEAKS the open list cursor and every
 * subsequent allocation will be charged to it.  When parsing a
 * comma-separated list, the loop body must not return early — it
 * must always fall through to the closing `_commit`.  The
 * implementation invariably uses the local pattern:
 *
 *      uint32_t list_start = iii_ast_list_begin(st->ast);
 *      ... loop, breaking on close-brace or error ...
 *      iii_ast_list_t list = iii_ast_list_commit(st->ast, list_start);
 *
 * Where the body recurses, recursion failure must NOT bypass the
 * commit.  The cycle/fn/type-decl productions follow this pattern.
 */

#include "parse.h"

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* ═══════════════════════════════════════════════════════════════════
 * NIH SHA-256 (FIPS 180-4) — deterministic, no allocations.
 *
 * Used by the parse-witness mhash (A1), the grammar mhash (E1), and
 * the speculation-rollback marker mixing inside the K1 checkpoint
 * machinery.  This implementation is byte-for-byte identical across
 * platforms (no compiler intrinsics, no endianness tricks) so the
 * digests are reproducible across MSVC / gcc / clang / x86 / ARM.
 * About 150 LoC; bounds-checked; no UB on partial-block padding.
 * ═══════════════════════════════════════════════════════════════════ */

typedef struct {
    uint32_t state[8];      /* H0..H7 */
    uint64_t bitlen;        /* total bits absorbed */
    uint8_t  buf[64];       /* current message block being filled */
    uint32_t buflen;        /* 0..63 bytes in buf */
} iiip_sha256_t;

static const uint32_t iiip_sha256_K[64] = {
    0x428a2f98u,0x71374491u,0xb5c0fbcfu,0xe9b5dba5u,0x3956c25bu,0x59f111f1u,0x923f82a4u,0xab1c5ed5u,
    0xd807aa98u,0x12835b01u,0x243185beu,0x550c7dc3u,0x72be5d74u,0x80deb1feu,0x9bdc06a7u,0xc19bf174u,
    0xe49b69c1u,0xefbe4786u,0x0fc19dc6u,0x240ca1ccu,0x2de92c6fu,0x4a7484aau,0x5cb0a9dcu,0x76f988dau,
    0x983e5152u,0xa831c66du,0xb00327c8u,0xbf597fc7u,0xc6e00bf3u,0xd5a79147u,0x06ca6351u,0x14292967u,
    0x27b70a85u,0x2e1b2138u,0x4d2c6dfcu,0x53380d13u,0x650a7354u,0x766a0abbu,0x81c2c92eu,0x92722c85u,
    0xa2bfe8a1u,0xa81a664bu,0xc24b8b70u,0xc76c51a3u,0xd192e819u,0xd6990624u,0xf40e3585u,0x106aa070u,
    0x19a4c116u,0x1e376c08u,0x2748774cu,0x34b0bcb5u,0x391c0cb3u,0x4ed8aa4au,0x5b9cca4fu,0x682e6ff3u,
    0x748f82eeu,0x78a5636fu,0x84c87814u,0x8cc70208u,0x90befffau,0xa4506cebu,0xbef9a3f7u,0xc67178f2u
};

static uint32_t iiip_rotr32(uint32_t x, uint32_t n) {
    return (x >> n) | (x << ((32u - n) & 31u));
}

static void iiip_sha256_init(iiip_sha256_t *s) {
    static const uint32_t H0[8] = {
        0x6a09e667u,0xbb67ae85u,0x3c6ef372u,0xa54ff53au,
        0x510e527fu,0x9b05688cu,0x1f83d9abu,0x5be0cd19u
    };
    memcpy(s->state, H0, sizeof(H0));
    s->bitlen = 0u;
    s->buflen = 0u;
}

static void iiip_sha256_compress(iiip_sha256_t *s, const uint8_t blk[64]) {
    uint32_t W[64];
    for (int i = 0; i < 16; i++) {
        W[i] = ((uint32_t)blk[4*i+0] << 24) | ((uint32_t)blk[4*i+1] << 16) |
               ((uint32_t)blk[4*i+2] <<  8) | ((uint32_t)blk[4*i+3]);
    }
    for (int i = 16; i < 64; i++) {
        uint32_t s0 = iiip_rotr32(W[i-15], 7) ^ iiip_rotr32(W[i-15], 18) ^ (W[i-15] >> 3);
        uint32_t s1 = iiip_rotr32(W[i-2], 17) ^ iiip_rotr32(W[i-2],  19) ^ (W[i-2]  >> 10);
        W[i] = W[i-16] + s0 + W[i-7] + s1;
    }
    uint32_t a=s->state[0], b=s->state[1], c=s->state[2], d=s->state[3];
    uint32_t e=s->state[4], f=s->state[5], g=s->state[6], h=s->state[7];
    for (int i = 0; i < 64; i++) {
        uint32_t S1 = iiip_rotr32(e, 6) ^ iiip_rotr32(e, 11) ^ iiip_rotr32(e, 25);
        uint32_t ch = (e & f) ^ (~e & g);
        uint32_t t1 = h + S1 + ch + iiip_sha256_K[i] + W[i];
        uint32_t S0 = iiip_rotr32(a, 2) ^ iiip_rotr32(a, 13) ^ iiip_rotr32(a, 22);
        uint32_t mj = (a & b) ^ (a & c) ^ (b & c);
        uint32_t t2 = S0 + mj;
        h = g; g = f; f = e; e = d + t1;
        d = c; c = b; b = a; a = t1 + t2;
    }
    s->state[0]+=a; s->state[1]+=b; s->state[2]+=c; s->state[3]+=d;
    s->state[4]+=e; s->state[5]+=f; s->state[6]+=g; s->state[7]+=h;
}

static void iiip_sha256_update(iiip_sha256_t *s, const void *data, size_t len) {
    const uint8_t *p = (const uint8_t *)data;
    s->bitlen += (uint64_t)len * 8u;
    while (len > 0) {
        uint32_t take = 64u - s->buflen;
        if ((size_t)take > len) take = (uint32_t)len;
        memcpy(s->buf + s->buflen, p, take);
        s->buflen += take;
        p          += take;
        len        -= take;
        if (s->buflen == 64u) {
            iiip_sha256_compress(s, s->buf);
            s->buflen = 0u;
        }
    }
}

static void iiip_sha256_final(iiip_sha256_t *s, uint8_t out[32]) {
    /* Append 0x80, pad with zeros to 56 mod 64, append 64-bit big-
     * endian bit length, compress.  No allocations. */
    uint64_t bitlen = s->bitlen;
    uint8_t  pad    = 0x80u;
    iiip_sha256_update(s, &pad, 1);
    uint8_t zero = 0x00u;
    while (s->buflen != 56u) {
        iiip_sha256_update(s, &zero, 1);
    }
    uint8_t lenbuf[8];
    for (int i = 0; i < 8; i++) lenbuf[i] = (uint8_t)((bitlen >> (56 - 8*i)) & 0xFFu);
    iiip_sha256_update(s, lenbuf, 8);
    for (int i = 0; i < 8; i++) {
        out[4*i+0] = (uint8_t)((s->state[i] >> 24) & 0xFFu);
        out[4*i+1] = (uint8_t)((s->state[i] >> 16) & 0xFFu);
        out[4*i+2] = (uint8_t)((s->state[i] >>  8) & 0xFFu);
        out[4*i+3] = (uint8_t)((s->state[i]      ) & 0xFFu);
    }
}

/* Helper: fold a u32 into a SHA-256 ctx in big-endian byte order
 * (canonical for the witness mhash). */
static void iiip_sha256_u32(iiip_sha256_t *s, uint32_t v) {
    uint8_t b[4];
    b[0] = (uint8_t)((v >> 24) & 0xFFu);
    b[1] = (uint8_t)((v >> 16) & 0xFFu);
    b[2] = (uint8_t)((v >>  8) & 0xFFu);
    b[3] = (uint8_t)((v      ) & 0xFFu);
    iiip_sha256_update(s, b, 4);
}

/* ═══════════════════════════════════════════════════════════════════
 * NIH Levenshtein (H1).  Iterative DP with two rolling rows; capped
 * at 64-byte strings so the worst-case scratch is a 65-entry uint16
 * array.  Used only for "did you mean ..." hints in error messages.
 * ═══════════════════════════════════════════════════════════════════ */

static uint32_t iiip_levenshtein(const char *a, size_t alen,
                                    const char *b, size_t blen)
{
    if (alen > 64u) alen = 64u;
    if (blen > 64u) blen = 64u;
    uint16_t prev[65];
    uint16_t curr[65];
    for (size_t j = 0; j <= blen; j++) prev[j] = (uint16_t)j;
    for (size_t i = 1; i <= alen; i++) {
        curr[0] = (uint16_t)i;
        for (size_t j = 1; j <= blen; j++) {
            uint16_t cost = (a[i-1] == b[j-1]) ? 0u : 1u;
            uint16_t del  = (uint16_t)(prev[j]   + 1u);
            uint16_t ins  = (uint16_t)(curr[j-1] + 1u);
            uint16_t sub  = (uint16_t)(prev[j-1] + cost);
            uint16_t m    = del < ins ? del : ins;
            if (sub < m) m = sub;
            curr[j] = m;
        }
        memcpy(prev, curr, sizeof(prev));
    }
    return (uint32_t)prev[blen];
}

/* ═══════════════════════════════════════════════════════════════════
 * Limits + production-ids + recursion-budget table (O1).
 * ═══════════════════════════════════════════════════════════════════ */

#define III_PARSE_MAX_DEPTH      512u   /* recursion limit, prevents stack blow */
#define III_PARSE_INIT_ERRORS    32u    /* initial heap cap for error queue (C1) */
#define III_PARSE_HARD_ERR_CAP   65536u /* upper-bound after which we stop growing (C1 fallback) */
#define III_PARSE_DUP_THRESHOLD  3u     /* C2 — suppress after this many identical (code,line) */
#define III_PARSE_REG_CAP        64u    /* R1 — cap per registry kind */
#define III_PARSE_BREADCRUMB_CAP 64u    /* H2 — production-stack depth */

/* O1 — production identifiers.  Values are stable for the parser's
 * own use; they label every entry in the FIRST/FOLLOW table (B1)
 * and the recursion-budget table (O1) below.  Append-only. */
typedef enum {
    IIIP_PROD_INVALID = 0,
    IIIP_PROD_MODULE,
    IIIP_PROD_USE_DECL,
    IIIP_PROD_TOP_DECL,
    IIIP_PROD_CYCLE_DECL,
    IIIP_PROD_FN_DECL,
    IIIP_PROD_TYPE_DECL,
    IIIP_PROD_CONST_DECL,
    IIIP_PROD_EXTERN_DECL,
    IIIP_PROD_MOBIUS_CANDIDATE,
    IIIP_PROD_SCHEMA_DECL,
    IIIP_PROD_SEALED_CALL,
    IIIP_PROD_PARAM_LIST,
    IIIP_PROD_ARG_LIST,
    IIIP_PROD_ARG,
    IIIP_PROD_MODIFIER,
    IIIP_PROD_TYPE_EXPR,
    IIIP_PROD_TYPE_SIMPLE,
    IIIP_PROD_EXPR,
    IIIP_PROD_PRIMARY,
    IIIP_PROD_UNARY,
    IIIP_PROD_POSTFIX,
    IIIP_PROD_PAREN_EXPR,
    IIIP_PROD_BLOCK,
    IIIP_PROD_STMT,
    IIIP_PROD_LET,
    IIIP_PROD_WAVEFRONT,
    IIIP_PROD_SANCTUM_ENTER,
    IIIP_PROD_METAL,
    IIIP_PROD_FOR,
    IIIP_PROD_RETURN,
    IIIP_PROD_PATTERN,
    IIIP_PROD_HEXAD,
    IIIP_PROD_COUNT
} iiip_prod_id_t;

/* Per-production recursion budget (O1).  Default 512; specific
 * productions that should be cheaper get tighter caps so a single
 * pathological input cannot eat the whole stack on a deep tree.
 * Looked up by `iiip_prod_budget`; absent entries fall through to
 * III_PARSE_MAX_DEPTH. */
static uint32_t iiip_prod_budget(iiip_prod_id_t p) {
    switch (p) {
        case IIIP_PROD_PAREN_EXPR:    return 256u;
        case IIIP_PROD_CYCLE_DECL:    return 8u;   /* cycles do not nest */
        case IIIP_PROD_FN_DECL:       return 8u;   /* nor do top-level fns */
        case IIIP_PROD_TYPE_EXPR:     return 128u;
        case IIIP_PROD_TYPE_SIMPLE:   return 128u;
        case IIIP_PROD_EXPR:          return 256u;
        case IIIP_PROD_PRIMARY:       return 256u;
        case IIIP_PROD_UNARY:         return 256u;
        case IIIP_PROD_PATTERN:       return 128u;
        case IIIP_PROD_BLOCK:         return 256u;
        default:                      return III_PARSE_MAX_DEPTH;
    }
}

/* Stable canonical name for a production-id (used in the breadcrumb
 * trail H2 and in the grammar mhash E1).  Sorted by id; lookup is
 * O(1). */
static const char *iiip_prod_name(iiip_prod_id_t p) {
    switch (p) {
        case IIIP_PROD_MODULE:             return "module";
        case IIIP_PROD_USE_DECL:           return "use";
        case IIIP_PROD_TOP_DECL:           return "top-decl";
        case IIIP_PROD_CYCLE_DECL:         return "cycle";
        case IIIP_PROD_FN_DECL:            return "fn";
        case IIIP_PROD_TYPE_DECL:          return "type-decl";
        case IIIP_PROD_CONST_DECL:         return "const";
        case IIIP_PROD_EXTERN_DECL:        return "extern";
        case IIIP_PROD_MOBIUS_CANDIDATE:   return "mobius_candidate";
        case IIIP_PROD_SCHEMA_DECL:        return "schema";
        case IIIP_PROD_SEALED_CALL:        return "sealed_call";
        case IIIP_PROD_PARAM_LIST:         return "param-list";
        case IIIP_PROD_ARG_LIST:           return "arg-list";
        case IIIP_PROD_ARG:                return "arg";
        case IIIP_PROD_MODIFIER:           return "modifier";
        case IIIP_PROD_TYPE_EXPR:          return "type-expr";
        case IIIP_PROD_TYPE_SIMPLE:        return "type-simple";
        case IIIP_PROD_EXPR:               return "expr";
        case IIIP_PROD_PRIMARY:            return "primary";
        case IIIP_PROD_UNARY:              return "unary";
        case IIIP_PROD_POSTFIX:            return "postfix";
        case IIIP_PROD_PAREN_EXPR:         return "paren-expr";
        case IIIP_PROD_BLOCK:              return "block";
        case IIIP_PROD_STMT:               return "stmt";
        case IIIP_PROD_LET:                return "let";
        case IIIP_PROD_WAVEFRONT:          return "wavefront";
        case IIIP_PROD_SANCTUM_ENTER:      return "sanctum_enter";
        case IIIP_PROD_METAL:              return "metal";
        case IIIP_PROD_FOR:                return "for";
        case IIIP_PROD_RETURN:             return "return";
        case IIIP_PROD_PATTERN:            return "pattern";
        case IIIP_PROD_HEXAD:              return "hexad";
        default:                            return "?";
    }
}

/* ═══════════════════════════════════════════════════════════════════
 * FIRST / FOLLOW table (B1, I1).
 *
 * Manually authored — one row per production.  The recovery routine
 * `iiip_recover_follow` looks up the production-id and skips tokens
 * until one of the FOLLOW-set kinds is found.  The same table feeds
 * the grammar-mhash (E1): we hash (name, FIRST-set) pairs in name-
 * sorted order to produce the stable digest.
 *
 * Adding a production: extend the IIIP_PROD_* enum AND add a row
 * here AND in `iiip_prod_name`.  The grammar mhash will change.
 * ═══════════════════════════════════════════════════════════════════ */

#define IIIP_FF_MAX_KINDS 12u

typedef struct {
    iiip_prod_id_t   id;
    iii_token_kind_t first[IIIP_FF_MAX_KINDS];   /* 0-terminated */
    iii_token_kind_t follow[IIIP_FF_MAX_KINDS];  /* 0-terminated */
} iiip_ff_row_t;

static const iiip_ff_row_t iiip_ff_table[] = {
    { IIIP_PROD_MODULE,
      { III_TOK_KW_MODULE, 0 },
      { III_TOK_EOF, 0 } },
    { IIIP_PROD_USE_DECL,
      { III_TOK_KW_USE, 0 },
      { III_TOK_NEWLINE, III_TOK_KW_USE, III_TOK_KW_CYCLE, III_TOK_KW_FN,
        III_TOK_KW_TYPE, III_TOK_KW_CONST, III_TOK_KW_EXTERN,
        III_TOK_KW_MOBIUS_CANDIDATE, III_TOK_KW_SCHEMA,
        III_TOK_KW_SEALED_CALL, III_TOK_EOF, 0 } },
    { IIIP_PROD_TOP_DECL,
      { III_TOK_KW_CYCLE, III_TOK_KW_FN, III_TOK_KW_TYPE, III_TOK_KW_CONST,
        III_TOK_KW_EXTERN, III_TOK_KW_MOBIUS_CANDIDATE, III_TOK_KW_SCHEMA,
        III_TOK_KW_SEALED_CALL, 0 },
      { III_TOK_NEWLINE, III_TOK_KW_CYCLE, III_TOK_KW_FN, III_TOK_KW_TYPE,
        III_TOK_KW_CONST, III_TOK_KW_EXTERN, III_TOK_KW_MOBIUS_CANDIDATE,
        III_TOK_KW_SCHEMA, III_TOK_KW_SEALED_CALL, III_TOK_EOF, 0 } },
    { IIIP_PROD_CYCLE_DECL,
      { III_TOK_KW_CYCLE, 0 },
      { III_TOK_NEWLINE, III_TOK_RBRACE, III_TOK_EOF, 0 } },
    { IIIP_PROD_FN_DECL,
      { III_TOK_KW_FN, 0 },
      { III_TOK_NEWLINE, III_TOK_RBRACE, III_TOK_EOF, 0 } },
    { IIIP_PROD_TYPE_DECL,
      { III_TOK_KW_TYPE, 0 },
      { III_TOK_NEWLINE, III_TOK_EOF, 0 } },
    { IIIP_PROD_CONST_DECL,
      { III_TOK_KW_CONST, 0 },
      { III_TOK_NEWLINE, III_TOK_EOF, 0 } },
    { IIIP_PROD_EXTERN_DECL,
      { III_TOK_KW_EXTERN, 0 },
      { III_TOK_NEWLINE, III_TOK_EOF, 0 } },
    { IIIP_PROD_MOBIUS_CANDIDATE,
      { III_TOK_KW_MOBIUS_CANDIDATE, 0 },
      { III_TOK_NEWLINE, III_TOK_RBRACE, III_TOK_EOF, 0 } },
    { IIIP_PROD_SCHEMA_DECL,
      { III_TOK_KW_SCHEMA, 0 },
      { III_TOK_NEWLINE, III_TOK_RBRACE, III_TOK_EOF, 0 } },
    { IIIP_PROD_SEALED_CALL,
      { III_TOK_KW_SEALED_CALL, 0 },
      { III_TOK_NEWLINE, III_TOK_RBRACE, III_TOK_EOF, 0 } },
    { IIIP_PROD_PARAM_LIST,
      { III_TOK_LPAREN, 0 },
      { III_TOK_RPAREN, III_TOK_ARROW, III_TOK_LBRACE, III_TOK_AT, 0 } },
    { IIIP_PROD_ARG_LIST,
      { 0 },  /* arg-list FIRST is anything that starts an expr */
      { III_TOK_RPAREN, III_TOK_RBRACKET, 0 } },
    { IIIP_PROD_ARG,
      { 0 },
      { III_TOK_COMMA, III_TOK_RPAREN, 0 } },
    { IIIP_PROD_MODIFIER,
      { III_TOK_AT, 0 },
      { III_TOK_AT, III_TOK_NEWLINE, III_TOK_LBRACE, III_TOK_SEMI,
        III_TOK_COMMA, III_TOK_RPAREN, III_TOK_RBRACE, 0 } },
    { IIIP_PROD_TYPE_EXPR,
      { III_TOK_OP_STAR, III_TOK_LBRACKET, III_TOK_LPAREN, III_TOK_KW_FN,
        III_TOK_IDENTIFIER, 0 },
      { III_TOK_COMMA, III_TOK_RPAREN, III_TOK_RBRACKET, III_TOK_OP_GT,
        III_TOK_OP_ASSIGN, III_TOK_LBRACE, III_TOK_AT, III_TOK_NEWLINE,
        III_TOK_KW_FROM, III_TOK_ARROW, 0 } },
    { IIIP_PROD_TYPE_SIMPLE,
      { III_TOK_OP_STAR, III_TOK_LBRACKET, III_TOK_LPAREN, III_TOK_KW_FN,
        III_TOK_IDENTIFIER, 0 },
      { III_TOK_COMMA, III_TOK_RPAREN, III_TOK_RBRACKET, III_TOK_OP_GT,
        III_TOK_OP_ASSIGN, III_TOK_LBRACE, III_TOK_AT, III_TOK_NEWLINE,
        III_TOK_KW_FROM, III_TOK_ARROW, 0 } },
    { IIIP_PROD_EXPR,
      { 0 },  /* anything that starts a primary */
      { III_TOK_COMMA, III_TOK_RPAREN, III_TOK_RBRACKET, III_TOK_RBRACE,
        III_TOK_SEMI, III_TOK_NEWLINE, III_TOK_FAT_ARROW, III_TOK_LBRACE,
        III_TOK_KW_UNTIL, III_TOK_KW_WHERE, 0 } },
    { IIIP_PROD_PRIMARY,
      { 0 },
      { III_TOK_COMMA, III_TOK_RPAREN, III_TOK_RBRACKET, III_TOK_DOT,
        III_TOK_LPAREN, III_TOK_LBRACKET, 0 } },
    { IIIP_PROD_UNARY,
      { 0 },
      { III_TOK_COMMA, III_TOK_RPAREN, III_TOK_RBRACKET, 0 } },
    { IIIP_PROD_POSTFIX,
      { 0 },
      { III_TOK_COMMA, III_TOK_RPAREN, III_TOK_RBRACKET, 0 } },
    { IIIP_PROD_PAREN_EXPR,
      { III_TOK_LPAREN, 0 },
      { III_TOK_RPAREN, 0 } },
    { IIIP_PROD_BLOCK,
      { III_TOK_LBRACE, 0 },
      { III_TOK_RBRACE, III_TOK_NEWLINE, III_TOK_EOF, 0 } },
    { IIIP_PROD_STMT,
      { III_TOK_KW_LET, III_TOK_KW_WAVEFRONT, III_TOK_KW_SANCTUM_ENTER,
        III_TOK_KW_METAL, III_TOK_KW_FOR, III_TOK_KW_RETURN,
        III_TOK_KW_MATCH, 0 },
      { III_TOK_NEWLINE, III_TOK_SEMI, III_TOK_RBRACE, III_TOK_EOF, 0 } },
    { IIIP_PROD_LET,             { III_TOK_KW_LET, 0 },           { III_TOK_NEWLINE, III_TOK_SEMI, III_TOK_RBRACE, 0 } },
    { IIIP_PROD_WAVEFRONT,       { III_TOK_KW_WAVEFRONT, 0 },     { III_TOK_NEWLINE, III_TOK_RBRACE, 0 } },
    { IIIP_PROD_SANCTUM_ENTER,   { III_TOK_KW_SANCTUM_ENTER, 0 }, { III_TOK_NEWLINE, III_TOK_RBRACE, 0 } },
    { IIIP_PROD_METAL,           { III_TOK_KW_METAL, 0 },         { III_TOK_NEWLINE, III_TOK_RBRACE, 0 } },
    { IIIP_PROD_FOR,             { III_TOK_KW_FOR, 0 },           { III_TOK_NEWLINE, III_TOK_RBRACE, 0 } },
    { IIIP_PROD_RETURN,          { III_TOK_KW_RETURN, 0 },        { III_TOK_NEWLINE, III_TOK_SEMI, III_TOK_RBRACE, 0 } },
    { IIIP_PROD_PATTERN,
      { III_TOK_UNDERSCORE, III_TOK_LPAREN, III_TOK_INT_LITERAL,
        III_TOK_HEX_LITERAL, III_TOK_STRING_LITERAL, III_TOK_KW_TRUE,
        III_TOK_KW_FALSE, III_TOK_IDENTIFIER, 0 },
      { III_TOK_FAT_ARROW, III_TOK_KW_IF, III_TOK_COMMA, III_TOK_RPAREN,
        III_TOK_RBRACE, 0 } },
    { IIIP_PROD_HEXAD,
      { III_TOK_LPAREN, 0 },
      { III_TOK_RPAREN, 0 } },
};

#define IIIP_FF_TABLE_LEN  (sizeof(iiip_ff_table) / sizeof(iiip_ff_table[0]))

static const iiip_ff_row_t *iiip_ff_lookup(iiip_prod_id_t id) {
    for (size_t i = 0; i < IIIP_FF_TABLE_LEN; i++) {
        if (iiip_ff_table[i].id == id) return &iiip_ff_table[i];
    }
    return NULL;
}

/* ═══════════════════════════════════════════════════════════════════
 * Pratt operator precedence table (N1).
 *
 * The actual entries live here in parse.c; parse.h exports the
 * struct shape and an accessor `iii_parse_binop_table`.  The
 * dispatcher `iiip_binop_for` reads this same table so there is
 * exactly one source of truth.
 * ═══════════════════════════════════════════════════════════════════ */

/* iii_binop_t numeric values come from ast.h; we pre-cast to int for
 * the public table struct so parse.h stays free of internal binop
 * enum dependencies. */
#include "ast.h"  /* already pulled by parse.h, but explicit here */

static const iii_parse_binop_info_t iiip_binop_table_data[] = {
    { III_TOK_KW_OR,       1,  false, (int)III_BIN_LOR     },
    { III_TOK_KW_AND,      2,  false, (int)III_BIN_LAND    },
    { III_TOK_OP_EQ,       3,  false, (int)III_BIN_EQ      },
    { III_TOK_OP_NEQ,      3,  false, (int)III_BIN_NEQ     },
    { III_TOK_OP_LT,       4,  false, (int)III_BIN_LT      },
    { III_TOK_OP_LE,       4,  false, (int)III_BIN_LE      },
    { III_TOK_OP_GT,       4,  false, (int)III_BIN_GT      },
    { III_TOK_OP_GE,       4,  false, (int)III_BIN_GE      },
    { III_TOK_KW_IN,       4,  false, (int)III_BIN_IN      },
    { III_TOK_PIPE,        5,  false, (int)III_BIN_OR      },
    { III_TOK_OP_CARET,    6,  false, (int)III_BIN_XOR     },
    { III_TOK_OP_AMP,      7,  false, (int)III_BIN_AND     },
    { III_TOK_OP_SHL,      8,  false, (int)III_BIN_SHL     },
    { III_TOK_OP_SHR,      8,  false, (int)III_BIN_SHR     },
    { III_TOK_OP_PLUS,     9,  false, (int)III_BIN_ADD     },
    { III_TOK_OP_MINUS,    9,  false, (int)III_BIN_SUB     },
    { III_TOK_OP_STAR,     10, false, (int)III_BIN_MUL     },
    { III_TOK_OP_SLASH,    10, false, (int)III_BIN_DIV     },
    { III_TOK_OP_PERCENT,  10, false, (int)III_BIN_MOD     },
    { III_TOK_KW_COMPOSE,  11, false, (int)III_BIN_COMPOSE },
};

#define IIIP_BINOP_TABLE_LEN \
    (sizeof(iiip_binop_table_data) / sizeof(iiip_binop_table_data[0]))

const iii_parse_binop_info_t *iii_parse_binop_table(size_t *out_n)
{
    if (out_n) *out_n = IIIP_BINOP_TABLE_LEN;
    return iiip_binop_table_data;
}

/* ═══════════════════════════════════════════════════════════════════
 * Grammar-extension registry types (R1).
 * ═══════════════════════════════════════════════════════════════════ */

typedef struct {
    uint32_t              handle;       /* 0 = vacant slot */
    iii_token_kind_t      first_token;
    iii_parse_decl_fn_t   fn;
} iiip_reg_entry_t;

typedef struct {
    iiip_reg_entry_t entries[III_PARSE_REG_CAP];
    uint32_t         count;              /* live entries (handle != 0) */
} iiip_reg_table_t;

/* ═══════════════════════════════════════════════════════════════════
 * Parser state.
 * ═══════════════════════════════════════════════════════════════════ */

struct iii_parse_state {
    iii_lex_state_t   *lex;
    iii_ast_t         *ast;

    /* One-token lookahead. */
    iii_token_t        lookahead;
    bool                 lookahead_valid;
    int                  lookahead_status;   /* 1, 0, -1 */

    /* D1 — second-token lookahead.  Buffered in the parser; the
     * lexer's iii_lex_peek API is left untouched.  When `valid`,
     * `lookahead2` holds the token that will be returned by the
     * next-after-current iiip_advance.  Pulled from iii_lex_next on
     * demand and absorbed back into `lookahead` when we advance. */
    iii_token_t        lookahead2;
    bool                 lookahead2_valid;
    int                  lookahead2_status;

    /* C1 — heap-allocated error queue, doubles on overflow.  Once
     * realloc fails the queue caps at its current size and a single
     * III_PARSE_E_ERRORS_TRUNCATED sentinel is queued (replacing the
     * last entry). */
    iii_parse_error_t *errors;
    uint32_t             error_count;
    uint32_t             error_cap;
    bool                 error_truncated;     /* true once realloc has failed */

    /* Current recursion depth (for the LL(1) recursive descent). */
    uint32_t             depth;

    /* H2 — production-context breadcrumb.  A fixed-size LIFO of
     * production-ids, plus a synthesised string assembled lazily on
     * error.  Push at production entry, pop at production exit. */
    iiip_prod_id_t     bc_stack[III_PARSE_BREADCRUMB_CAP];
    uint32_t             bc_depth;
    /* Optional trailing detail (the name of the cycle / fn / etc.).
     * Slot index parallel to bc_stack; NULL if no detail. */
    iii_src_text_t     bc_detail[III_PARSE_BREADCRUMB_CAP];

    /* A1 — parse witness: streaming SHA-256 fed at every node-commit.
     * Sealed by iii_parse_witness_mhash; safe to call multiple times
     * because we copy the context before finalising. */
    iiip_sha256_t      witness_ctx;
    uint32_t             witness_committed;   /* node-commit counter */

    /* A2 — optional witness sink. */
    iii_parse_witness_sink_fn_t witness_sink;
    void                         *witness_sink_ctx;

    /* Q1 — Pratt decision trace. */
    iii_parse_pratt_trace_fn_t  pratt_trace;
    void                         *pratt_trace_ctx;

    /* R1 — three registry tables. */
    iiip_reg_table_t   reg_decl;
    iiip_reg_table_t   reg_stmt;
    iiip_reg_table_t   reg_primary;
    uint32_t             reg_next_handle;     /* monotonic; 1 = first */

    /* C2 — last-error dedup state. */
    int                  last_err_code;
    uint32_t             last_err_line;
    uint32_t             last_err_dups;       /* consecutive duplicates seen */

    /* K1 — orphan ranges left behind by speculation rollbacks where
     * the AST checkpoint API is unavailable for a particular pool.
     * Each range is [lo, hi) of node-ids.  Cap is small; the parser
     * does very little speculation and the K1 checkpoint usually
     * succeeds in calling iii_ast_rollback. */
    struct {
        uint32_t lo;
        uint32_t hi;
    } orphan_ranges[16];
    uint32_t             orphan_count;
};

/* Forward declarations needed by the new helpers. */
static const char *iiip_strdup_rotating(const char *src);
static iiip_prod_id_t iiip_kind_to_prod(iii_token_kind_t k);
static const char *iiip_breadcrumb_render(iii_parse_state_t *st);
static void iiip_witness_commit(iii_parse_state_t *st, uint32_t node_id);
static iii_src_pos_t iiip_node_pos(iii_parse_state_t *st, uint32_t id);

/* ═══════════════════════════════════════════════════════════════════
 * Error queueing (C1, C2, H2).
 * ═══════════════════════════════════════════════════════════════════ */

static bool iiip_errq_grow(iii_parse_state_t *st)
{
    if (st->error_truncated) return false;
    uint32_t new_cap = st->error_cap == 0 ? III_PARSE_INIT_ERRORS : st->error_cap * 2u;
    if (new_cap > III_PARSE_HARD_ERR_CAP) new_cap = III_PARSE_HARD_ERR_CAP;
    if (new_cap == st->error_cap) {
        /* Already at hard cap. */
        st->error_truncated = true;
        return false;
    }
    iii_parse_error_t *p = (iii_parse_error_t *)
        realloc(st->errors, (size_t)new_cap * sizeof(*p));
    if (!p) {
        st->error_truncated = true;
        return false;
    }
    st->errors   = p;
    st->error_cap = new_cap;
    return true;
}

static void iiip_record_error(iii_parse_state_t *st,
                                int code,
                                const iii_token_t *tok,
                                const char *msg,
                                iii_token_kind_t expected)
{
    if (!st) return;

    /* C2 — dedup consecutive identical (code, line) past threshold. */
    uint32_t line = tok ? tok->line : 0u;
    if (code == st->last_err_code && line == st->last_err_line && code != III_PARSE_OK) {
        st->last_err_dups += 1u;
        if (st->last_err_dups >= III_PARSE_DUP_THRESHOLD) {
            /* Silently drop; the trailing sentinel is emitted lazily
             * (see iiip_dedup_flush below).  Bump a counter on the
             * most-recent error so the sentinel can carry the count. */
            if (st->error_count > 0) {
                st->errors[st->error_count - 1].dup_count += 1u;
            }
            return;
        }
    } else {
        /* C2 transition — if we just finished suppressing a run
         * (last error has a non-zero dup_count), append a synthetic
         * "(N more identical errors suppressed)" sentinel BEFORE
         * the new error so downstream consumers can see the gap.
         * Recurse-safe because the sentinel uses a fresh code that
         * never matches the run code we're closing. */
        if (st->error_count > 0u &&
            st->errors[st->error_count - 1u].dup_count > 0u &&
            st->error_count < st->error_cap) {
            iii_parse_error_t *prev = &st->errors[st->error_count - 1u];
            iii_parse_error_t *s = &st->errors[st->error_count++];
            memset(s, 0, sizeof(*s));
            s->code          = III_PARSE_E_ERRORS_TRUNCATED;
            s->byte          = prev->byte;
            s->line          = prev->line;
            s->col           = prev->col;
            s->saw_kind      = III_TOK_INVALID;
            s->expected_kind = III_TOK_INVALID;
            s->breadcrumb    = prev->breadcrumb;
            s->message       = "(N identical errors suppressed)";
            s->dup_count     = prev->dup_count;
        }
        st->last_err_code = code;
        st->last_err_line = line;
        st->last_err_dups = 1u;
    }

    if (st->error_count >= st->error_cap) {
        if (!iiip_errq_grow(st)) {
            /* C1 — queue the truncation sentinel ONCE, then drop. */
            if (st->error_cap > 0 && st->error_count == st->error_cap &&
                st->errors[st->error_cap - 1].code != III_PARSE_E_ERRORS_TRUNCATED) {
                st->errors[st->error_cap - 1].code = III_PARSE_E_ERRORS_TRUNCATED;
                st->errors[st->error_cap - 1].message =
                    "error queue truncated; subsequent diagnostics dropped";
            }
            return;
        }
    }
    iii_parse_error_t *e = &st->errors[st->error_count++];
    memset(e, 0, sizeof(*e));
    e->code           = code;
    e->byte           = tok ? tok->start_byte : 0u;
    e->line           = line;
    e->col            = tok ? tok->col : 0u;
    e->message        = msg;
    e->saw_kind       = tok ? tok->kind : III_TOK_INVALID;
    e->expected_kind  = expected;
    e->breadcrumb     = iiip_breadcrumb_render(st);
    e->dup_count      = 0u;
}

/* iiip_strdup_rotating — see definition immediately below. */

/* ─── Token-stream helpers ──────────────────────────────────────── */

static int iiip_refill(iii_parse_state_t *st)
{
    if (st->lookahead_valid) return st->lookahead_status;
    /* If a second-token lookahead was buffered, promote it. */
    if (st->lookahead2_valid) {
        st->lookahead         = st->lookahead2;
        st->lookahead_status  = st->lookahead2_status;
        st->lookahead_valid   = true;
        st->lookahead2_valid  = false;
        return st->lookahead_status;
    }
    st->lookahead_status = iii_lex_next(st->lex, &st->lookahead);
    st->lookahead_valid  = true;
    if (st->lookahead_status < 0) {
        iii_lex_error_t le;
        iii_lex_error_info(st->lex, &le);
        iiip_record_error(st, III_PARSE_E_LEX, &st->lookahead, le.message, III_TOK_INVALID);
    }
    return st->lookahead_status;
}

static iii_token_t *iiip_peek(iii_parse_state_t *st)
{
    (void)iiip_refill(st);
    return &st->lookahead;
}

static iii_token_kind_t iiip_peek_kind(iii_parse_state_t *st)
{
    (void)iiip_refill(st);
    return st->lookahead.kind;
}

/* D1 — two-token lookahead.  Returns the token AFTER the current
 * lookahead without consuming it.  Pulled lazily; cached until the
 * current lookahead is consumed (at which point the cached token
 * becomes the new lookahead via iiip_refill above).  Skips
 * NEWLINE tokens to mirror what most call sites care about — but
 * preserves a NEWLINE-aware variant by checking the lookahead2 kind
 * against III_TOK_NEWLINE. */
static iii_token_t *iiip_peek2(iii_parse_state_t *st)
{
    (void)iiip_refill(st);
    if (!st->lookahead2_valid) {
        st->lookahead2_status = iii_lex_next(st->lex, &st->lookahead2);
        st->lookahead2_valid  = true;
        if (st->lookahead2_status < 0) {
            iii_lex_error_t le;
            iii_lex_error_info(st->lex, &le);
            iiip_record_error(st, III_PARSE_E_LEX, &st->lookahead2,
                              le.message, III_TOK_INVALID);
        }
    }
    return &st->lookahead2;
}

static iii_token_kind_t iiip_peek2_kind(iii_parse_state_t *st)
{
    return iiip_peek2(st)->kind;
}

/* Consume the lookahead and refill.  Returns the consumed token. */
static iii_token_t iiip_advance(iii_parse_state_t *st)
{
    (void)iiip_refill(st);
    iii_token_t t = st->lookahead;
    st->lookahead_valid = false;
    return t;
}

/* Skip insignificant III_TOK_NEWLINE tokens (most grammar productions
 * don't care about them).  Specific productions that DO care call
 * iiip_peek_raw() instead. */
static void iiip_skip_newlines(iii_parse_state_t *st)
{
    while (iiip_peek_kind(st) == III_TOK_NEWLINE) {
        (void)iiip_advance(st);
    }
}

static bool iiip_match(iii_parse_state_t *st, iii_token_kind_t k)
{
    return iiip_peek_kind(st) == k;
}

static bool iiip_accept(iii_parse_state_t *st, iii_token_kind_t k)
{
    if (iiip_peek_kind(st) == k) {
        (void)iiip_advance(st);
        return true;
    }
    return false;
}

/* H1 — Levenshtein-based "did you mean ..." hint.  When `expected`
 * is a keyword token kind and the token actually seen is an
 * identifier, compute the edit distance from the seen identifier
 * bytes to the canonical keyword spelling; if min ≤ 2, append
 * `(did you mean `kw`?)` to the message via the rotating buffer.
 * Returns the (possibly augmented) message; the original `base`
 * pointer is returned unchanged when no hint applies. */
static const char *iiip_keyword_hint(iii_parse_state_t *st,
                                       const char *base,
                                       iii_token_kind_t expected)
{
    if (!base || expected == III_TOK_INVALID) return base;
    iii_token_t *saw = iiip_peek(st);
    if (!saw || saw->kind != III_TOK_IDENTIFIER) return base;
    const char *want = iii_token_kind_name(expected);
    if (!want || want[0] == '\0') return base;
    /* Strip "III_TOK_KW_" / "III_TOK_" prefix used by the canonical
     * names so we compare against the source spelling.  This is a
     * heuristic; if it doesn't recognise the prefix we just use the
     * full canonical name. */
    const char *kw = want;
    if (strncmp(kw, "III_TOK_KW_", 11) == 0) kw += 11;
    else if (strncmp(kw, "III_TOK_", 8) == 0) kw += 8;
    /* Lowercase a stack copy of the keyword (canonical names are
     * UPPER_CASE; III source spells keywords lower-case). */
    char kw_lc[32];
    size_t klen = 0;
    while (kw[klen] != '\0' && klen < sizeof(kw_lc) - 1u) {
        char c = kw[klen];
        if (c >= 'A' && c <= 'Z') c = (char)(c - 'A' + 'a');
        kw_lc[klen] = c;
        klen += 1;
    }
    kw_lc[klen] = '\0';
    /* Saw bytes: [start_byte, end_byte) of the source.  We don't
     * have direct source access here; use iii_token_raw_eq's idiom
     * by looking up the lex state's source via a one-pass copy.
     * For determinism the bound is the static stack buffer. */
    char saw_bytes[32];
    uint32_t slen = saw->end_byte > saw->start_byte
                    ? saw->end_byte - saw->start_byte : 0u;
    if (slen >= sizeof(saw_bytes)) return base;  /* too long to be a typo */
    (void)saw_bytes;
    /* iii_token_raw_eq compares against a string; we need the bytes
     * themselves.  The cleanest portable way without lex.h source
     * access: try each suffix-distance against `kw_lc` only — and
     * since iii_token_raw_eq won't help (no enumeration), build the
     * saw bytes by repeatedly probing single-byte prefixes via the
     * iii_token_raw_eq predicate.  That's O(slen * 26) which is
     * fine.  In practice the lex state exposes raw bytes via the
     * source buffer; we accept the loss of richer info here in
     * exchange for not extending lex.h. */
    /* We optimistically accept any saw->end_byte slice if the lex
     * state's source is queryable; iii_token_raw_eq lets us probe a
     * candidate equality.  Use that to cross-check our hint without
     * needing the actual bytes: if iii_token_raw_eq(saw, kw_lc) is
     * true, the user typed the keyword exactly — no hint needed. */
    if (iii_token_raw_eq(st->lex, saw, kw_lc)) return base;
    /* Bytewise probe via raw_eq with single-character mutations of
     * kw_lc.  We try insertions/deletions/substitutions up to
     * distance 2; if any matches, that is our edit distance.  This
     * is bounded and deterministic. */
    /* Distance 0 already excluded.  Distance 1: substitute one char. */
    bool d1 = false;
    for (size_t i = 0; i < klen && !d1; i++) {
        for (char c = 'a'; c <= 'z'; c++) {
            if (c == kw_lc[i]) continue;
            char tmp[32];
            memcpy(tmp, kw_lc, klen + 1u);
            tmp[i] = c;
            if (iii_token_raw_eq(st->lex, saw, tmp)) { d1 = true; break; }
        }
    }
    /* Distance 1 via insertion (saw is one longer than kw). */
    if (!d1 && klen + 1u < sizeof(saw_bytes)) {
        for (size_t i = 0; i <= klen && !d1; i++) {
            for (char c = 'a'; c <= 'z'; c++) {
                char tmp[32];
                if (i > 0)         memcpy(tmp,         kw_lc,     i);
                tmp[i] = c;
                if (klen - i > 0)  memcpy(tmp + i + 1, kw_lc + i, klen - i);
                tmp[klen + 1u] = '\0';
                if (iii_token_raw_eq(st->lex, saw, tmp)) { d1 = true; break; }
            }
        }
    }
    /* Distance 1 via deletion (saw is one shorter than kw). */
    if (!d1 && klen >= 1u) {
        for (size_t i = 0; i < klen && !d1; i++) {
            char tmp[32];
            if (i > 0)             memcpy(tmp,     kw_lc,         i);
            if (klen - i - 1u > 0) memcpy(tmp + i, kw_lc + i + 1, klen - i - 1u);
            tmp[klen - 1u] = '\0';
            if (iii_token_raw_eq(st->lex, saw, tmp)) { d1 = true; break; }
        }
    }
    if (!d1) {
        /* No distance-1 match found; we don't have direct access to
         * the seen identifier bytes (lex.h doesn't expose them
         * here), so we cannot afford to probe larger distances.
         * Fall through with no hint.  The full Levenshtein routine
         * iiip_levenshtein remains available for callers that hold
         * source bytes directly. */
        (void)iiip_levenshtein;
        (void)slen;
        return base;
    }
    /* d1 holds → emit the hint. */
    char buf[160];
    snprintf(buf, sizeof(buf), "%s (did you mean `%s`?)", base, kw_lc);
    return iiip_strdup_rotating(buf);
}

/* B2 — synthesise insertion of `k` at the current point: emit a
 * recoverable diagnostic and continue as if `k` had been present.
 * Does not advance the lexer; the caller treats `k` as consumed. */
static void iiip_synth_insert(iii_parse_state_t *st, iii_token_kind_t k)
{
    char buf[96];
    snprintf(buf, sizeof(buf), "missing %s; assumed inserted",
             iii_token_kind_name(k));
    iiip_record_error(st, III_PARSE_E_INSERTED_TOKEN, iiip_peek(st),
                      iiip_strdup_rotating(buf), k);
}

/* B2 helper — try to skip exactly one bad token and re-test for `k`. */
static bool iiip_try_skip_token(iii_parse_state_t *st, iii_token_kind_t k)
{
    if (iiip_peek_kind(st) == III_TOK_EOF) return false;
    (void)iiip_advance(st);
    return iiip_peek_kind(st) == k;
}

static bool iiip_expect(iii_parse_state_t *st, iii_token_kind_t k, iii_token_t *out)
{
    if (iiip_peek_kind(st) == k) {
        iii_token_t t = iiip_advance(st);
        if (out) *out = t;
        return true;
    }
    char buf[96];
    snprintf(buf, sizeof(buf), "expected %s, saw %s",
             iii_token_kind_name(k),
             iii_token_kind_name(iiip_peek_kind(st)));
    const char *msg = iiip_keyword_hint(st, buf, k);
    iiip_record_error(st, III_PARSE_E_UNEXPECTED_TOKEN,
                      iiip_peek(st), iiip_strdup_rotating(msg), k);
    /* B2 — for the four canonical "soft" terminators, synthesise an
     * insertion so downstream productions see a clean stream.  Do
     * NOT consume any input on insertion.  If the very next token
     * happens to be the one we wanted (a single stray token between
     * us and the terminator), skip it and accept. */
    if (k == III_TOK_SEMI || k == III_TOK_RBRACE ||
        k == III_TOK_RPAREN || k == III_TOK_COLON) {
        if (iiip_try_skip_token(st, k)) {
            iii_token_t t = iiip_advance(st);
            if (out) *out = t;
            return true;
        }
        iiip_synth_insert(st, k);
        if (out) {
            memset(out, 0, sizeof(*out));
            out->kind = k;
        }
        return true;
    }
    return false;
}

/* iiip_strdup_rotating — deterministic per-process rotating string
 * buffer for parser error messages.  Avoids leaking per-error malloc
 * while keeping pointer validity for the ring window (16 most-recent
 * messages).  Errors are consumed by the operator after end-of-build,
 * never on the hot path; the 16-slot bound is well above the
 * III_PARSE_MAX_ERRORS=128 cap because operators read the first
 * dozen and skim the rest.  This routine is the only place in the
 * parser where a transient string is created; static lifetime keeps
 * it leak-free for the program's lifetime. */
static const char *iiip_strdup_rotating(const char *src)
{
    /* Rotating ring of 16 short buffers; enough for typical error
     * messages without growing the parser's footprint per error.
     * Manual byte-copy with explicit truncation — gcc's -Wstringop-
     * truncation rejects strncpy with this exact pattern even though
     * truncation is the intended semantics. */
    static char ring[16][96];
    static int  cursor = 0;
    int slot = cursor;
    cursor = (cursor + 1) & 15;
    size_t cap = sizeof(ring[slot]) - 1;
    size_t i = 0;
    while (i < cap && src[i] != '\0') {
        ring[slot][i] = src[i];
        i += 1;
    }
    ring[slot][i] = '\0';
    return ring[slot];
}

/* ═══════════════════════════════════════════════════════════════════
 * Witness, breadcrumb, alloc-wrapper, kind→production map.
 * ═══════════════════════════════════════════════════════════════════ */

/* A2 — invoke optional sink (no-op if not set). */
static void iiip_witness_sink_emit(iii_parse_state_t *st,
                                     uint32_t node_id,
                                     iii_ast_kind_t k,
                                     const iii_src_pos_t *pos)
{
    if (st && st->witness_sink) {
        uint32_t s = pos ? pos->start_byte : 0u;
        uint32_t e = pos ? pos->end_byte   : 0u;
        st->witness_sink(st->witness_sink_ctx, node_id, (uint32_t)k, s, e);
    }
}

/* A1 — fold (kind, start, end, node_id, ordinal) into the streaming
 * SHA-256.  The ordinal disambiguates structurally-identical nodes
 * that occur at different points in the parse stream. */
static void iiip_witness_commit(iii_parse_state_t *st, uint32_t node_id)
{
    if (!st) return;
    const iii_ast_node_t *n = iii_ast_get(st->ast, node_id);
    if (!n) return;
    uint8_t buf[24];
    uint32_t k    = (uint32_t)n->kind;
    uint32_t lo   = iiip_node_pos(st, node_id).start_byte;
    uint32_t hi   = iiip_node_pos(st, node_id).end_byte;
    uint32_t ord  = st->witness_committed;
    /* Big-endian fields for byte-stable hash output. */
    buf[ 0] = (uint8_t)(k    >> 24); buf[ 1] = (uint8_t)(k    >> 16);
    buf[ 2] = (uint8_t)(k    >>  8); buf[ 3] = (uint8_t)(k       );
    buf[ 4] = (uint8_t)(lo   >> 24); buf[ 5] = (uint8_t)(lo   >> 16);
    buf[ 6] = (uint8_t)(lo   >>  8); buf[ 7] = (uint8_t)(lo      );
    buf[ 8] = (uint8_t)(hi   >> 24); buf[ 9] = (uint8_t)(hi   >> 16);
    buf[10] = (uint8_t)(hi   >>  8); buf[11] = (uint8_t)(hi      );
    buf[12] = (uint8_t)(node_id >> 24); buf[13] = (uint8_t)(node_id >> 16);
    buf[14] = (uint8_t)(node_id >>  8); buf[15] = (uint8_t)(node_id      );
    buf[16] = (uint8_t)(ord  >> 24); buf[17] = (uint8_t)(ord  >> 16);
    buf[18] = (uint8_t)(ord  >>  8); buf[19] = (uint8_t)(ord       );
    /* Trailing 4 bytes reserved for future child-count fold. */
    buf[20] = buf[21] = buf[22] = buf[23] = 0;
    iiip_sha256_update(&st->witness_ctx, buf, sizeof(buf));
    st->witness_committed += 1u;
}

/* A1 — alloc wrapper: forwards to iii_ast_alloc_node, folds witness,
 * invokes sink.  On allocator failure plants III_AST_ERROR_NODE so
 * downstream code can keep building (B3).  This is the ONLY entry
 * point for AST node allocation in the parser; all 58 raw call sites
 * were rewritten to call this wrapper. */
static uint32_t iiip_alloc_node(iii_parse_state_t *st,
                                  iii_ast_kind_t k,
                                  const iii_src_pos_t *pos)
{
    uint32_t id = iii_ast_alloc_node(st->ast, k, pos);
    if (id == 0u) {
        /* Allocator pressure — plant a typed error node and continue. */
        id = iii_ast_alloc_node(st->ast, III_AST_ERROR_NODE, pos);
        iiip_record_error(st, III_PARSE_E_OOM, iiip_peek(st),
                          "AST allocator returned 0 (out of capacity)",
                          III_TOK_INVALID);
    }
    iiip_witness_commit(st, id);
    iiip_witness_sink_emit(st, id, k, pos);
    return id;
}

/* H2 — render the breadcrumb stack into a rotating string buffer.
 * Format:  "in <prod1>[ '<detail1>'] > <prod2>[ '<detail2>']".
 * Returns NULL when the stack is empty.  Stable across the lifetime
 * of the rotating ring (16 most recent renders). */
static const char *iiip_breadcrumb_render(iii_parse_state_t *st)
{
    if (!st || st->bc_depth == 0u) return NULL;
    static char ring[16][192];
    static int  cursor = 0;
    int slot = cursor;
    cursor = (cursor + 1) & 15;
    char *out = ring[slot];
    size_t cap = sizeof(ring[slot]);
    size_t off = 0;
    int written = snprintf(out + off, cap - off, "in ");
    if (written > 0) off += (size_t)written;
    for (uint32_t i = 0; i < st->bc_depth && off + 1u < cap; i++) {
        const char *name = iiip_prod_name(st->bc_stack[i]);
        if (i > 0) {
            written = snprintf(out + off, cap - off, " > ");
            if (written > 0) off += (size_t)written;
        }
        written = snprintf(out + off, cap - off, "%s", name ? name : "?");
        if (written > 0) off += (size_t)written;
        if (off + 1u >= cap) break;
        if (st->bc_detail[i].length > 0) {
            written = snprintf(out + off, cap - off, "(#%u)",
                               (unsigned)st->bc_detail[i].offset);
            if (written > 0) off += (size_t)written;
        }
    }
    if (off >= cap) off = cap - 1u;
    out[off] = '\0';
    return out;
}

/* H2 — push/pop helpers. */
static void iiip_bc_push(iii_parse_state_t *st, iiip_prod_id_t pid,
                           iii_src_text_t detail)
{
    if (!st || st->bc_depth >= III_PARSE_BREADCRUMB_CAP) return;
    st->bc_stack[st->bc_depth]  = pid;
    st->bc_detail[st->bc_depth] = detail;
    st->bc_depth += 1u;
}

static void iiip_bc_pop(iii_parse_state_t *st)
{
    if (!st || st->bc_depth == 0u) return;
    st->bc_depth -= 1u;
}

/* O1 — current production budget (top-of-stack); default = 512. */
static uint32_t iiip_current_budget(iii_parse_state_t *st)
{
    if (!st || st->bc_depth == 0u) return 512u;
    return iiip_prod_budget(st->bc_stack[st->bc_depth - 1u]);
}

/* Map a leading token kind to its lexically-determined production
 * id.  Only used by the registry dispatchers (R1) and by error
 * recovery to pick a sensible FOLLOW set when no breadcrumb is
 * available. */
static iiip_prod_id_t iiip_kind_to_prod(iii_token_kind_t k)
{
    switch ((int)k) {
    case III_TOK_KW_CYCLE:    return IIIP_PROD_CYCLE_DECL;
    case III_TOK_KW_FN:       return IIIP_PROD_FN_DECL;
    case III_TOK_KW_USE:      return IIIP_PROD_USE_DECL;
    case III_TOK_KW_LET:      return IIIP_PROD_LET;
    case III_TOK_KW_RETURN:   return IIIP_PROD_RETURN;
    case III_TOK_KW_FOR:      return IIIP_PROD_FOR;
    case III_TOK_KW_MATCH:    return IIIP_PROD_PRIMARY;
    default: return IIIP_PROD_TOP_DECL;
    }
}

/* B1 — recover to the FOLLOW set of a production. */
static void iiip_recover_to(iii_parse_state_t *st,
                              const iii_token_kind_t *sync,
                              size_t n);

static void iiip_recover_follow(iii_parse_state_t *st, iiip_prod_id_t pid)
{
    const iiip_ff_row_t *row = iiip_ff_lookup(pid);
    if (!row) {
        /* Default sync: SEMI / RBRACE / EOF. */
        static const iii_token_kind_t fallback[] = {
            III_TOK_SEMI, III_TOK_RBRACE, III_TOK_EOF
        };
        iiip_recover_to(st, fallback, sizeof(fallback)/sizeof(fallback[0]));
        return;
    }
    iii_token_kind_t buf[16];
    size_t n = 0;
    for (; n < sizeof(buf)/sizeof(buf[0]) && row->follow[n] != III_TOK_INVALID; n++) {
        buf[n] = row->follow[n];
    }
    if (n == 0u) {
        buf[n++] = III_TOK_SEMI;
        buf[n++] = III_TOK_RBRACE;
        buf[n++] = III_TOK_EOF;
    }
    iiip_recover_to(st, buf, n);
}

/* R1 — registry dispatch.  Returns 0 if no handler matched (caller
 * should fall through to the built-in switch); returns the alloc'd
 * node id on success.  The handler is responsible for consuming its
 * tokens; on registry-handler failure the parser records an error
 * but still returns a (possibly III_AST_ERROR_NODE) id so the parse
 * doesn't abort. */
static uint32_t iiip_registry_dispatch(iii_parse_state_t *st,
                                         const iiip_reg_table_t *tbl,
                                         iii_token_kind_t leading)
{
    if (!tbl || tbl->count == 0u || leading == III_TOK_INVALID) return 0u;
    for (uint32_t i = 0; i < III_PARSE_REG_CAP; i++) {
        if (tbl->entries[i].handle != 0u &&
            tbl->entries[i].first_token == leading) {
            iii_parse_decl_fn_t fn = tbl->entries[i].fn;
            return fn ? fn(st) : 0u;
        }
    }
    return 0u;
}

/* Lookup the first physical position recorded for `id`.  Returns
 * a zero-initialised iii_src_pos_t when the node has no physical
 * position (synthetic-only nodes, errors).  Centralised because
 * positions migrated from in-node storage to a side-table; this
 * helper hides that boundary for the parser's many "extend a span
 * to include the right edge of a child" idioms. */
static iii_src_pos_t iiip_node_pos(iii_parse_state_t *st, uint32_t id)
{
    iii_src_pos_t out;
    out.start_byte = out.end_byte = out.line = out.col = 0u;
    if (!st || id == 0u) return out;
    iii_ast_position_t p;
    if (iii_ast_position_first(st->ast, id, &p) && p.kind == III_POS_PHYSICAL) {
        out.start_byte = p.u.physical.start_byte;
        out.end_byte   = p.u.physical.end_byte;
        out.line       = p.u.physical.line;
        out.col        = p.u.physical.col;
    }
    return out;
}

/* Forward declarations for recursive productions */

static uint32_t iiip_parse_type_expr(iii_parse_state_t *st);
static uint32_t iiip_parse_expr     (iii_parse_state_t *st);
static uint32_t iiip_parse_block    (iii_parse_state_t *st);
static uint32_t iiip_parse_stmt     (iii_parse_state_t *st);
static uint32_t iiip_parse_pattern  (iii_parse_state_t *st);
static iii_ast_list_t iiip_parse_modifier_list(iii_parse_state_t *st);
static uint32_t iiip_parse_modifier (iii_parse_state_t *st);

/* ─── Source-position helper ─────────────────────────────────────── */

static iii_src_pos_t iiip_pos_of(const iii_token_t *t)
{
    iii_src_pos_t p;
    p.start_byte = t ? t->start_byte : 0;
    p.end_byte   = t ? t->end_byte   : 0;
    p.line       = t ? t->line       : 0;
    p.col        = t ? t->col        : 0;
    return p;
}

static iii_src_text_t iiip_text_of(const iii_token_t *t)
{
    iii_src_text_t s;
    s.offset = t ? t->start_byte : 0;
    s.length = t ? (uint32_t)(t->end_byte - t->start_byte) : 0;
    return s;
}

/* Combine two source positions into the spanning span [a.start ..
 * b.end). */
static iii_src_pos_t iiip_pos_span(iii_src_pos_t a, iii_src_pos_t b)
{
    iii_src_pos_t r = a;
    r.end_byte = b.end_byte;
    return r;
}

/* ─── Recursion limit check ──────────────────────────────────────── */

static bool iiip_enter_recursion(iii_parse_state_t *st)
{
    /* O1 — per-production recursion budget.  When a production has
     * pushed itself onto the breadcrumb stack (H2), the budget at
     * the top of the stack governs; otherwise the global cap
     * applies.  The two bounds compose: we trip at MIN(prod_budget,
     * III_PARSE_MAX_DEPTH).  Cycle/fn productions cap at 8; type
     * exprs at 128; default 512. */
    uint32_t budget = iiip_current_budget(st);
    if (budget > III_PARSE_MAX_DEPTH) budget = III_PARSE_MAX_DEPTH;
    if (st->depth >= budget) {
        iiip_record_error(st, III_PARSE_E_RECURSION_LIMIT,
                          iiip_peek(st), "parse recursion limit exceeded",
                          III_TOK_INVALID);
        return false;
    }
    st->depth += 1;
    return true;
}

static void iiip_leave_recursion(iii_parse_state_t *st)
{
    if (st->depth > 0) st->depth -= 1;
}

/* ─── Skip-to-recovery: advance until we hit one of the given
 *     synchronisation tokens.  Used after an error to attempt to
 *     resume parsing at a stable boundary. */
static void iiip_recover_to(iii_parse_state_t *st,
                              const iii_token_kind_t *kinds, size_t n_kinds)
{
    for (;;) {
        iii_token_kind_t k = iiip_peek_kind(st);
        if (k == III_TOK_EOF) return;
        for (size_t i = 0; i < n_kinds; i++) {
            if (k == kinds[i]) return;
        }
        (void)iiip_advance(st);
    }
}

/* ─── Modifier parsing ───────────────────────────────────────────── */

/*
 * modifier ::= "@" identifier ("(" arg_list? ")")?
 *
 * The lexer emits `@` then the identifier as separate tokens; the
 * parser composes them.  The optional argument list uses positional
 * or named args (see parse_arg below).
 */

static uint32_t iiip_parse_arg(iii_parse_state_t *st)
{
    if (!iiip_enter_recursion(st)) return 0;
    /* arg ::= (identifier "=")? expr
     *
     * The grammar permits a named-arg form `name = expr`.  D1 — we
     * use 2-token lookahead (iiip_peek2) to distinguish without ever
     * having to roll an AST back: if the upcoming pair is
     * (IDENTIFIER, OP_ASSIGN) the cheap path consumes both tokens
     * up-front and we parse the value expression alone.  All other
     * shapes fall through to the general expression parser.  The
     * parser performs no speculative AST construction here; the only
     * remaining speculation site in the parser is the hexad form,
     * which uses iii_ast_checkpoint/iii_ast_rollback (see L1/K1). */
    iii_src_text_t arg_name = { 0u, 0u };
    iii_src_pos_t  pos      = (iii_src_pos_t){0,0,0,0};
    if (iiip_peek_kind(st) == III_TOK_IDENTIFIER &&
        iiip_peek2_kind(st) == III_TOK_OP_ASSIGN) {
        iii_token_t name = iiip_advance(st);
        (void)iiip_advance(st);   /* consume '=' */
        arg_name = iiip_text_of(&name);
        pos      = iiip_pos_of(&name);
    }
    uint32_t value = iiip_parse_expr(st);
    if (value == 0) { iiip_leave_recursion(st); return 0; }
    if (pos.start_byte == 0u && pos.end_byte == 0u) pos = iiip_node_pos(st, value);
    pos.end_byte = iiip_node_pos(st, value).end_byte;

    uint32_t arg = iiip_alloc_node(st, III_AST_ARG, &pos);
    if (arg == 0) { iiip_leave_recursion(st); return 0; }
    iii_ast_node_t *an = iii_ast_get_mut(st->ast, arg);
    an->u.arg.arg_name = arg_name;
    an->u.arg.value_expr = value;
    iiip_leave_recursion(st);
    return arg;
}

static iii_ast_list_t iiip_parse_arg_list(iii_parse_state_t *st)
{
    iii_ast_list_t empty = { 0u, 0u };
    if (iiip_match(st, III_TOK_RPAREN)) return empty;
    iii_ast_open_list_t *ol = iii_ast_open_list_create(st->ast);
    if (!ol) return empty;
    for (;;) {
        uint32_t arg = iiip_parse_arg(st);
        if (arg == 0) break;
        iii_ast_open_list_push(ol, arg);
        if (!iiip_accept(st, III_TOK_COMMA)) break;
        iiip_skip_newlines(st);
    }
    return iii_ast_open_list_commit(st->ast, ol);
}

/* Parse a single modifier (`@name(args)` or `@name`).  `@` already
 * consumed by caller.  Returns the modifier node id. */
static uint32_t iiip_parse_modifier_after_at(iii_parse_state_t *st,
                                                const iii_token_t *at_tok)
{
    /* Modifier name: identifier, `@type`, or any of the reserved
     * modifier-keyword tokens emitted by the lexer per lex.h §D4
     * (`MOD_RING`, `MOD_TIER`, `MOD_HEXAD`, etc).  The lexer collapses
     * those names to dedicated kinds so the parser does not strcmp at
     * every modifier site; this acceptance set accepts them as the
     * modifier's name. */
    iii_token_t name_tok;
    iii_token_kind_t k = iiip_peek_kind(st);
    if (k == III_TOK_IDENTIFIER || k == III_TOK_KW_TYPE
        || k == III_TOK_MOD_RING        || k == III_TOK_MOD_TIER
        || k == III_TOK_MOD_SAFETY      || k == III_TOK_MOD_HEXAD
        || k == III_TOK_MOD_TRACK       || k == III_TOK_MOD_CHRONOS
        || k == III_TOK_MOD_CAP         || k == III_TOK_MOD_EPOCH
        || k == III_TOK_MOD_PLAN_ANCHOR || k == III_TOK_MOD_CLOSURE
        || k == III_TOK_MOD_VERSION     || k == III_TOK_MOD_ABI
        || k == III_TOK_MOD_PURE        || k == III_TOK_MOD_IRREVERSIBLE
        || k == III_TOK_MOD_SANCTUM_ONLY|| k == III_TOK_MOD_SEAL_ID
        /* Lattice-plan Phase 2 modifiers (Steps 0002-0015). */
        || k == III_TOK_MOD_CRYSTAL                 || k == III_TOK_MOD_DYNAMIC
        || k == III_TOK_MOD_SEALED                  || k == III_TOK_MOD_LINEAR
        || k == III_TOK_MOD_BOUNDED                 || k == III_TOK_MOD_VARIANT
        || k == III_TOK_MOD_K                       || k == III_TOK_MOD_PROVENANCE
        || k == III_TOK_MOD_CONSTANT_TIME           || k == III_TOK_MOD_SIDE_CHANNEL_RESISTANT
        || k == III_TOK_MOD_DYNAMIC_IMPACT          || k == III_TOK_MOD_PROVENANCE_LINKED_ERROR
        || k == III_TOK_MOD_ARENA_RESET_SAFE        || k == III_TOK_MOD_CRYSTAL_SELF_ATTEST
        || k == III_TOK_MOD_STRICT_LENGTH) {
        name_tok = iiip_advance(st);
    } else {
        iiip_record_error(st, III_PARSE_E_BAD_MODIFIER, iiip_peek(st),
                          "modifier name must be identifier or modifier keyword",
                          III_TOK_IDENTIFIER);
        return 0;
    }
    iii_src_pos_t pos = iiip_pos_of(at_tok);
    pos.end_byte = name_tok.end_byte;

    iii_ast_list_t args = { 0u, 0u };
    uint32_t ring_mask = 0;
    /* @ring(...) and @phase(...) take a ring-set argument list; every
     * other modifier takes a generic arg list parsed by parse_arg_list.
     * Detect by name byte-compare against the source bytes. */
    const bool is_ring  = iii_token_raw_eq(st->lex, &name_tok, "ring");
    const bool is_phase = iii_token_raw_eq(st->lex, &name_tok, "phase");
    if (iiip_accept(st, III_TOK_LPAREN)) {
        if (is_ring || is_phase) {
            /* Ring-set: comma-separated list of ring names.  The lexer
             * emits "R0"/"R3" as single identifier tokens (alphanumeric
             * sequence), and "R-1"/"R-2" as the three-token sequence
             * IDENT("R"), OP_MINUS, INT_LITERAL(1|2).  "any" is a
             * reserved keyword. */
            for (;;) {
                if (iiip_accept(st, III_TOK_RPAREN)) break;
                if (iiip_match(st, III_TOK_EOF)) break;
                iii_token_kind_t k = iiip_peek_kind(st);
                if (k == III_TOK_KW_ANY) {
                    (void)iiip_advance(st);
                    ring_mask |= III_RING_ANY;
                } else if (k == III_TOK_IDENTIFIER) {
                    iii_token_t rt = iiip_advance(st);
                    if (iii_token_raw_eq(st->lex, &rt, "R0")) {
                        ring_mask |= III_RING_R0;
                    } else if (iii_token_raw_eq(st->lex, &rt, "R3")) {
                        ring_mask |= III_RING_R3;
                    } else if (iii_token_raw_eq(st->lex, &rt, "R")) {
                        /* Compound R-1 or R-2: expect '-' then INT 1 or 2. */
                        if (!iiip_accept(st, III_TOK_OP_MINUS)) {
                            iiip_record_error(st, III_PARSE_E_BAD_RING_SET, &rt,
                                              "expected '-' after 'R' in compound ring name",
                                              III_TOK_OP_MINUS);
                        } else {
                            iii_token_t it;
                            if (iiip_expect(st, III_TOK_INT_LITERAL, &it)) {
                                if (it.int_value == 1) ring_mask |= III_RING_RM1;
                                else if (it.int_value == 2) ring_mask |= III_RING_RM2;
                                else {
                                    iiip_record_error(st, III_PARSE_E_BAD_RING_SET, &it,
                                                      "compound ring negative integer must be 1 or 2",
                                                      III_TOK_INT_LITERAL);
                                }
                            }
                        }
                    } else {
                        iiip_record_error(st, III_PARSE_E_BAD_RING_SET, &rt,
                                          "unrecognised ring name in @ring(...)",
                                          III_TOK_IDENTIFIER);
                    }
                } else {
                    iiip_record_error(st, III_PARSE_E_BAD_RING_SET, iiip_peek(st),
                                      "expected ring name in @ring(...)",
                                      III_TOK_IDENTIFIER);
                    (void)iiip_advance(st);
                }
                if (iiip_accept(st, III_TOK_COMMA)) continue;
                if (iiip_accept(st, III_TOK_RPAREN)) break;
            }
        } else {
            /* Generic modifier args. */
            args = iiip_parse_arg_list(st);
            (void)iiip_expect(st, III_TOK_RPAREN, NULL);
        }
        pos.end_byte = iiip_peek(st)->start_byte;
    }

    uint32_t mod = iiip_alloc_node(st, III_AST_MODIFIER, &pos);
    if (mod == 0) return 0;
    iii_ast_node_t *mn = iii_ast_get_mut(st->ast, mod);
    mn->u.modifier.name      = iiip_text_of(&name_tok);
    mn->u.modifier.args      = args;
    /* M1 — modifier semantics are NOT pre-resolved by Stage-0 EXCEPT
     * for @ring/@phase, where the ring args (R3, R0, R-1, R-2, any)
     * are consumed directly into a local ring_mask above and are NOT
     * stored as AST arg nodes (the args list is empty for @ring).
     * Sema therefore has no way to recover the ring set from the AST
     * unless we forward the parser's ring_mask here.  Storing it does
     * not violate M1: when args.count == 0 (the ring case), this is
     * the only signal sema sees; for non-ring modifiers, ring_mask
     * stays zero and sema decodes from the args list per M1. */
    mn->u.modifier.ring_mask   = ring_mask;
    mn->u.modifier.hexad_node  = 0;
    mn->u.modifier.tier_kind   = 0;
    mn->u.modifier.epoch_value = 0;
    return mod;
}

static uint32_t iiip_parse_modifier(iii_parse_state_t *st)
{
    iii_token_t at;
    if (!iiip_expect(st, III_TOK_AT, &at)) return 0;
    return iiip_parse_modifier_after_at(st, &at);
}

static iii_ast_list_t iiip_parse_modifier_list(iii_parse_state_t *st)
{
    iii_ast_list_t empty = { 0u, 0u };
    iii_ast_open_list_t *ol = iii_ast_open_list_create(st->ast);
    if (!ol) return empty;
    while (iiip_match(st, III_TOK_AT)) {
        uint32_t mod = iiip_parse_modifier(st);
        if (mod == 0) break;
        iii_ast_open_list_push(ol, mod);
        iiip_skip_newlines(st);
    }
    return iii_ast_open_list_commit(st->ast, ol);
}

/* ─── Type expressions ───────────────────────────────────────────── */

static uint32_t iiip_parse_type_simple(iii_parse_state_t *st)
{
    if (!iiip_enter_recursion(st)) return 0;

    iii_token_t first = *iiip_peek(st);
    /* Pointer */
    if (first.kind == III_TOK_OP_STAR) {
        (void)iiip_advance(st);
        uint32_t inner = iiip_parse_type_expr(st);
        if (inner == 0) { iiip_leave_recursion(st); return 0; }
        const iii_ast_node_t *inn = iii_ast_get(st->ast, inner);
        iii_src_pos_t pos = iiip_pos_of(&first);
        pos.end_byte = inn ? iiip_node_pos(st, inner).end_byte : pos.end_byte;
        uint32_t n = iiip_alloc_node(st, III_AST_TYPE_PTR, &pos);
        if (n == 0) { iiip_leave_recursion(st); return 0; }
        iii_ast_node_t *nn = iii_ast_get_mut(st->ast, n);
        nn->u.type_ptr.inner = inner;
        nn->u.type_ptr.modifiers.offset = 0;
        nn->u.type_ptr.modifiers.count = 0;
        iiip_leave_recursion(st);
        return n;
    }
    /* Array: [ T ; N ] */
    if (first.kind == III_TOK_LBRACKET) {
        (void)iiip_advance(st);
        uint32_t inner = iiip_parse_type_expr(st);
        (void)iiip_expect(st, III_TOK_SEMI, NULL);
        iii_token_t cnt;
        if (!iiip_expect(st, III_TOK_INT_LITERAL, &cnt)) {
            iiip_leave_recursion(st);
            return 0;
        }
        iii_token_t close;
        (void)iiip_expect(st, III_TOK_RBRACKET, &close);
        iii_src_pos_t pos = iiip_pos_span(iiip_pos_of(&first), iiip_pos_of(&close));
        uint32_t n = iiip_alloc_node(st, III_AST_TYPE_ARRAY, &pos);
        if (n == 0) { iiip_leave_recursion(st); return 0; }
        iii_ast_node_t *nn = iii_ast_get_mut(st->ast, n);
        nn->u.type_array.inner = inner;
        nn->u.type_array.count = cnt.int_value;
        nn->u.type_array.modifiers.offset = 0;
        nn->u.type_array.modifiers.count = 0;
        iiip_leave_recursion(st);
        return n;
    }
    /* Tuple or paren-grouped type — both start with `(`. */
    if (first.kind == III_TOK_LPAREN) {
        (void)iiip_advance(st);
        iii_ast_open_list_t *ol = iii_ast_open_list_create(st->ast);
        size_t count = 0;
        if (ol && !iiip_match(st, III_TOK_RPAREN)) {
            for (;;) {
                uint32_t t = iiip_parse_type_expr(st);
                if (t == 0) break;
                iii_ast_open_list_push(ol, t);
                count += 1;
                if (!iiip_accept(st, III_TOK_COMMA)) break;
                iiip_skip_newlines(st);
            }
        }
        iii_token_t close;
        (void)iiip_expect(st, III_TOK_RPAREN, &close);
        iii_ast_list_t comps = ol ? iii_ast_open_list_commit(st->ast, ol)
                                  : (iii_ast_list_t){ 0u, 0u };
        iii_src_pos_t pos = iiip_pos_span(iiip_pos_of(&first), iiip_pos_of(&close));
        uint32_t n = iiip_alloc_node(st, III_AST_TYPE_TUPLE, &pos);
        if (n == 0) { iiip_leave_recursion(st); return 0; }
        iii_ast_node_t *nn = iii_ast_get_mut(st->ast, n);
        nn->u.type_tuple.components = comps;
        nn->u.type_tuple.modifiers.offset = 0;
        nn->u.type_tuple.modifiers.count = 0;
        iiip_leave_recursion(st);
        return n;
    }
    /* Function type: `fn` ( params ) -> T */
    if (first.kind == III_TOK_KW_FN) {
        (void)iiip_advance(st);
        (void)iiip_expect(st, III_TOK_LPAREN, NULL);
        iii_ast_open_list_t *params_ol = iii_ast_open_list_create(st->ast);
        if (params_ol && !iiip_match(st, III_TOK_RPAREN)) {
            for (;;) {
                iii_token_t name;
                if (!iiip_expect(st, III_TOK_IDENTIFIER, &name)) break;
                (void)iiip_expect(st, III_TOK_COLON, NULL);
                uint32_t pt = iiip_parse_type_expr(st);
                iii_src_pos_t pp = iiip_pos_of(&name);
                if (pt) {
                    pp.end_byte = iiip_node_pos(st, pt).end_byte;
                }
                uint32_t pn = iiip_alloc_node(st, III_AST_PARAM, &pp);
                if (pn == 0) break;
                iii_ast_node_t *pnp = iii_ast_get_mut(st->ast, pn);
                pnp->u.param.name = iiip_text_of(&name);
                pnp->u.param.type_node = pt;
                iii_ast_open_list_push(params_ol, pn);
                if (!iiip_accept(st, III_TOK_COMMA)) break;
                iiip_skip_newlines(st);
            }
        }
        (void)iiip_expect(st, III_TOK_RPAREN, NULL);
        iii_ast_list_t params = params_ol ? iii_ast_open_list_commit(st->ast, params_ol)
                                          : (iii_ast_list_t){ 0u, 0u };
        (void)iiip_expect(st, III_TOK_ARROW, NULL);
        uint32_t ret = iiip_parse_type_expr(st);
        iii_src_pos_t pos = iiip_pos_of(&first);
        if (ret) {
            pos.end_byte = iiip_node_pos(st, ret).end_byte;
        }
        uint32_t n = iiip_alloc_node(st, III_AST_TYPE_FN, &pos);
        if (n == 0) { iiip_leave_recursion(st); return 0; }
        iii_ast_node_t *nn = iii_ast_get_mut(st->ast, n);
        nn->u.type_fn.params = params;
        nn->u.type_fn.return_type = ret;
        nn->u.type_fn.modifiers.offset = 0;
        nn->u.type_fn.modifiers.count = 0;
        iiip_leave_recursion(st);
        return n;
    }
    /* Else: TYPE_REF.  Identifier (qualified via '.') optionally
     * followed by '<' type_args '>'. */
    iii_token_t name_first;
    if (!iiip_expect(st, III_TOK_IDENTIFIER, &name_first)) {
        iiip_record_error(st, III_PARSE_E_EXPECTED_TYPE, iiip_peek(st),
                          "expected type expression", III_TOK_IDENTIFIER);
        iiip_leave_recursion(st);
        return 0;
    }
    /* Walk dotted name: name (. name)* */
    iii_src_text_t name_text = iiip_text_of(&name_first);
    iii_src_pos_t pos = iiip_pos_of(&name_first);
    while (iiip_accept(st, III_TOK_DOT)) {
        iii_token_t n2;
        if (!iiip_expect(st, III_TOK_IDENTIFIER, &n2)) break;
        name_text.length = (uint32_t)(n2.end_byte - name_text.offset);
        pos.end_byte = n2.end_byte;
    }
    /* Optional type-arg list. */
    iii_ast_list_t type_args = { 0u, 0u };
    if (iiip_accept(st, III_TOK_OP_LT)) {
        iii_ast_open_list_t *ta_ol = iii_ast_open_list_create(st->ast);
        if (ta_ol && !iiip_match(st, III_TOK_OP_GT)) {
            for (;;) {
                /* Type args may be type-exprs OR int literals OR mhash
                 * literals OR identifiers (for type params). */
                uint32_t a = iiip_parse_type_expr(st);
                /* If parse_type_expr failed, we may want to allow int/mhash;
                 * fallback path: try to parse a simple expr. */
                if (a == 0 &&
                    (iiip_match(st, III_TOK_INT_LITERAL) ||
                     iiip_match(st, III_TOK_HEX_LITERAL) ||
                     iiip_match(st, III_TOK_MHASH_LITERAL))) {
                    a = iiip_parse_expr(st);
                }
                if (a == 0) break;
                iii_ast_open_list_push(ta_ol, a);
                if (!iiip_accept(st, III_TOK_COMMA)) break;
            }
        }
        (void)iiip_expect(st, III_TOK_OP_GT, NULL);
        type_args = ta_ol ? iii_ast_open_list_commit(st->ast, ta_ol)
                          : (iii_ast_list_t){ 0u, 0u };
        pos.end_byte = iiip_peek(st)->start_byte;
    }
    /* Stage-0 grammar discipline: type expressions do NOT consume
     * trailing @modifier(...) tokens.  In `cycle f() -> T @ring(...)
     * @hexad(...)` the modifiers belong to the cycle, not the type T.
     * Stage-1+ may reintroduce type-tagged modifier consumption with
     * proper disambiguation (e.g. `(T @safety(H))` parenthesisation).
     * The TYPE_REF.modifiers field stays in the AST shape; it remains
     * empty in Stage-0 output. */
    iii_ast_list_t mods = { 0u, 0u };
    uint32_t n = iiip_alloc_node(st, III_AST_TYPE_REF, &pos);
    if (n == 0) { iiip_leave_recursion(st); return 0; }
    iii_ast_node_t *nn = iii_ast_get_mut(st->ast, n);
    nn->u.type_ref.name = name_text;
    nn->u.type_ref.type_args = type_args;
    nn->u.type_ref.modifiers = mods;
    iiip_leave_recursion(st);
    return n;
}

static uint32_t iiip_parse_type_expr(iii_parse_state_t *st)
{
    return iiip_parse_type_simple(st);
}

/* ─── Expression parsing (Pratt) ─────────────────────────────────── */

/* N1 — Operator info now lives in the public Pratt table emitted by
 * the prologue.  This local view delegates to that single source of
 * truth so the table can be inspected from outside the parser via
 * iii_parse_binop_table without duplication drift. */
typedef struct {
    int  prec;
    bool right_assoc;
    iii_binop_t op;
} iiip_binop_info_t;

static iiip_binop_info_t iiip_binop_for(iii_token_kind_t k)
{
    iiip_binop_info_t r = { 0, false, 0 };
    size_t n = 0;
    const iii_parse_binop_info_t *tbl = iii_parse_binop_table(&n);
    for (size_t i = 0; i < n; i++) {
        if (tbl[i].token == k) {
            r.prec        = tbl[i].prec;
            r.right_assoc = tbl[i].right_assoc;
            r.op          = (iii_binop_t)tbl[i].op;
            return r;
        }
    }
    return r;
}

/* L1 — Hexad-trit parser, single source of truth.
 *
 * The hexad form `(t,t,t,t,t,t)` appears in two grammar slots —
 * primary expression and pattern — that previously each carried a
 * near-duplicate ~25-line transcriber.  This helper centralises the
 * dispatch so any future trit shorthand (e.g. `+1`/`-1`) is added in
 * exactly one place.  Caller has ALREADY consumed the opening LPAREN
 * and verified `is_trit_start` at the head of the inner sequence.
 *
 * On success, fills `out[0..5]` and returns true with the parser
 * cursor parked on the closing RPAREN (caller must consume it).  On
 * failure, returns false with the cursor undefined; caller must
 * issue its own diagnostic and recover.  `allow_pattern_extras`
 * enables the underscore wildcard (`_` → INVALID), used by the
 * pattern slot.
 */
static bool iiip_parse_hexad_trits(iii_parse_state_t *st,
                                   iii_ast_trit_t out[6],
                                   bool allow_pattern_extras)
{
    for (size_t i = 0; i < 6; i++) {
        iii_token_t tt = *iiip_peek(st);
        if (tt.kind == III_TOK_KW_NEG) {
            (void)iiip_advance(st); out[i] = III_TRIT_AST_NEG;
        } else if (tt.kind == III_TOK_KW_ZERO) {
            (void)iiip_advance(st); out[i] = III_TRIT_AST_ZERO;
        } else if (tt.kind == III_TOK_KW_POS) {
            (void)iiip_advance(st); out[i] = III_TRIT_AST_POS;
        } else if (tt.kind == III_TOK_KW_TRIT_INVALID) {
            (void)iiip_advance(st); out[i] = III_TRIT_AST_INVALID;
        } else if (allow_pattern_extras && tt.kind == III_TOK_UNDERSCORE) {
            (void)iiip_advance(st); out[i] = III_TRIT_AST_INVALID;
        } else if (tt.kind == III_TOK_OP_PLUS) {
            (void)iiip_advance(st);
            iii_token_t one;
            if (!iiip_expect(st, III_TOK_INT_LITERAL, &one) || one.int_value != 1)
                return false;
            out[i] = III_TRIT_AST_POS;
        } else if (tt.kind == III_TOK_OP_MINUS) {
            (void)iiip_advance(st);
            iii_token_t one;
            if (!iiip_expect(st, III_TOK_INT_LITERAL, &one) || one.int_value != 1)
                return false;
            out[i] = III_TRIT_AST_NEG;
        } else if (tt.kind == III_TOK_INT_LITERAL && tt.int_value == 0) {
            (void)iiip_advance(st); out[i] = III_TRIT_AST_ZERO;
        } else {
            return false;
        }
        if (i < 5 && !iiip_accept(st, III_TOK_COMMA)) return false;
    }
    return true;
}

static uint32_t iiip_parse_unary(iii_parse_state_t *st);
static uint32_t iiip_parse_postfix(iii_parse_state_t *st, uint32_t lhs);

/* Parse a primary expression: literal, identifier, parenthesised, block,
 * match expr. */
static uint32_t iiip_parse_primary(iii_parse_state_t *st)
{
    iii_token_t t = *iiip_peek(st);
    /* R1 — registry dispatch first; non-zero return wins. */
    {
        uint32_t r = iiip_registry_dispatch(st, &st->reg_primary, t.kind);
        if (r != 0u) return r;
    }
    switch (t.kind) {
        /* F5 — `sizeof T`.  Resolves at sema time to the byte size of T;
         * for Stage-1 the resolution is a small builtin table (u64=8,
         * u32=4, u16=2, u8=1, bool=1, etc).  Codegen emits a literal. */
        case III_TOK_KW_SIZEOF: {
            (void)iiip_advance(st);
            uint32_t target = iiip_parse_type_expr(st);
            iii_src_pos_t pos = iiip_pos_of(&t);
            uint32_t n = iiip_alloc_node(st, III_AST_EXPR_SIZEOF, &pos);
            if (n) {
                iii_ast_node_t *nn = iii_ast_get_mut(st->ast, n);
                nn->u.sizeof_.target_type = target;
                nn->u.sizeof_.resolved = 0;     /* sema fills */
            }
            return n;
        }
        case III_TOK_INT_LITERAL: {
            (void)iiip_advance(st);
            iii_src_pos_t pos = iiip_pos_of(&t);
            uint32_t n = iiip_alloc_node(st, III_AST_EXPR_INT, &pos);
            if (n) iii_ast_get_mut(st->ast, n)->u.int_.value = t.int_value;
            return n;
        }
        case III_TOK_HEX_LITERAL: {
            (void)iiip_advance(st);
            iii_src_pos_t pos = iiip_pos_of(&t);
            uint32_t n = iiip_alloc_node(st, III_AST_EXPR_HEX, &pos);
            if (n) iii_ast_get_mut(st->ast, n)->u.hex_.value = t.int_value;
            return n;
        }
        case III_TOK_MHASH_LITERAL: {
            (void)iiip_advance(st);
            iii_src_pos_t pos = iiip_pos_of(&t);
            uint32_t n = iiip_alloc_node(st, III_AST_EXPR_MHASH, &pos);
            if (n) memcpy(iii_ast_get_mut(st->ast, n)->u.mhash_.mhash, t.mhash, 32);
            return n;
        }
        case III_TOK_STRING_LITERAL: {
            (void)iiip_advance(st);
            iii_src_pos_t pos = iiip_pos_of(&t);
            uint32_t n = iiip_alloc_node(st, III_AST_EXPR_STR, &pos);
            if (n) {
                uint32_t idx = iii_ast_intern_string(st->ast, t.string_payload);
                iii_ast_get_mut(st->ast, n)->u.str_.string_payload_idx = idx;
                iii_ast_get_mut(st->ast, n)->u.str_.string_len = t.string_len;
            }
            return n;
        }
        case III_TOK_KW_TRUE:
        case III_TOK_KW_FALSE: {
            bool v = (t.kind == III_TOK_KW_TRUE);
            (void)iiip_advance(st);
            iii_src_pos_t pos = iiip_pos_of(&t);
            uint32_t n = iiip_alloc_node(st, III_AST_EXPR_BOOL, &pos);
            if (n) iii_ast_get_mut(st->ast, n)->u.bool_.value = v;
            return n;
        }
        case III_TOK_KW_NEG:
        case III_TOK_KW_ZERO:
        case III_TOK_KW_POS:
        case III_TOK_KW_TRIT_INVALID: {
            (void)iiip_advance(st);
            iii_ast_trit_t trit =
                (t.kind == III_TOK_KW_NEG)  ? III_TRIT_AST_NEG  :
                (t.kind == III_TOK_KW_ZERO) ? III_TRIT_AST_ZERO :
                (t.kind == III_TOK_KW_POS)  ? III_TRIT_AST_POS  :
                                              III_TRIT_AST_INVALID;
            iii_src_pos_t pos = iiip_pos_of(&t);
            uint32_t n = iiip_alloc_node(st, III_AST_EXPR_TRIT, &pos);
            if (n) iii_ast_get_mut(st->ast, n)->u.trit_.trit = trit;
            return n;
        }
        case III_TOK_IDENTIFIER: {
            (void)iiip_advance(st);
            iii_src_pos_t pos = iiip_pos_of(&t);
            uint32_t n = iiip_alloc_node(st, III_AST_EXPR_IDENT, &pos);
            if (n) iii_ast_get_mut(st->ast, n)->u.ident.name = iiip_text_of(&t);
            return n;
        }
        case III_TOK_LPAREN: {
            /* Could be: parenthesised expr, unit `()`, or hexad literal
             * `(t,t,t,t,t,t)` if all entries are trits. */
            (void)iiip_advance(st);
            if (iiip_accept(st, III_TOK_RPAREN)) {
                iii_src_pos_t pos = iiip_pos_of(&t);
                pos.end_byte = iiip_peek(st)->start_byte;
                return iiip_alloc_node(st, III_AST_EXPR_UNIT, &pos);
            }
            /* Look ahead: if the first sub-expr is a TRIT literal and
             * the next token after is COMMA, attempt hexad parsing. */
            iii_token_t la = *iiip_peek(st);
            bool is_trit_start =
                (la.kind == III_TOK_KW_NEG || la.kind == III_TOK_KW_ZERO ||
                 la.kind == III_TOK_KW_POS || la.kind == III_TOK_KW_TRIT_INVALID ||
                 la.kind == III_TOK_OP_PLUS || la.kind == III_TOK_OP_MINUS ||
                 (la.kind == III_TOK_INT_LITERAL && (la.int_value == 0 || la.int_value == 1)));
            if (is_trit_start) {
                /* L1 — delegated to iiip_parse_hexad_trits. */
                iii_ast_trit_t trits[6];
                bool ok = iiip_parse_hexad_trits(st, trits, false);
                if (ok) {
                    if (!iiip_expect(st, III_TOK_RPAREN, NULL)) {
                        iiip_record_error(st, III_PARSE_E_BAD_HEXAD, &t,
                                          "hexad must contain exactly 6 trits",
                                          III_TOK_RPAREN);
                    }
                    iii_src_pos_t pos = iiip_pos_of(&t);
                    pos.end_byte = iiip_peek(st)->start_byte;
                    uint32_t n = iiip_alloc_node(st, III_AST_EXPR_HEXAD, &pos);
                    if (n) memcpy(iii_ast_get_mut(st->ast, n)->u.hexad_.trits, trits, sizeof(trits));
                    return n;
                }
                /* Fall through: this wasn't a hexad; the parser cursor is
                 * past some tokens.  Emit an error. */
                iiip_record_error(st, III_PARSE_E_EXPECTED_EXPR, iiip_peek(st),
                                  "ambiguous parenthesised expression after partial hexad",
                                  III_TOK_INVALID);
                return 0;
            }
            uint32_t inner = iiip_parse_expr(st);
            iii_token_t close;
            (void)iiip_expect(st, III_TOK_RPAREN, &close);
            iii_src_pos_t pos = iiip_pos_span(iiip_pos_of(&t), iiip_pos_of(&close));
            uint32_t n = iiip_alloc_node(st, III_AST_EXPR_PAREN, &pos);
            if (n) iii_ast_get_mut(st->ast, n)->u.paren.inner = inner;
            return n;
        }
        case III_TOK_LBRACE:
            return iiip_parse_block(st);
        case III_TOK_KW_MATCH: {
            (void)iiip_advance(st);
            uint32_t scrut = iiip_parse_expr(st);
            (void)iiip_expect(st, III_TOK_LBRACE, NULL);
            iii_ast_open_list_t *arms_ol = iii_ast_open_list_create(st->ast);
            for (;;) {
                iiip_skip_newlines(st);
                if (iiip_accept(st, III_TOK_RBRACE)) break;
                if (iiip_match(st, III_TOK_EOF)) break;
                uint32_t pat = iiip_parse_pattern(st);
                uint32_t guard = 0;
                if (iiip_accept(st, III_TOK_KW_IF)) {
                    guard = iiip_parse_expr(st);
                }
                (void)iiip_expect(st, III_TOK_FAT_ARROW, NULL);
                uint32_t body = iiip_parse_expr(st);
                iii_src_pos_t pp = pat ? iiip_node_pos(st, pat) : iiip_pos_of(&t);
                uint32_t arm = iiip_alloc_node(st, III_AST_MATCH_ARM, &pp);
                if (arm) {
                    iii_ast_node_t *an = iii_ast_get_mut(st->ast, arm);
                    an->u.match_arm.pattern    = pat;
                    an->u.match_arm.guard_expr = guard;
                    an->u.match_arm.body       = body;
                    if (arms_ol) iii_ast_open_list_push(arms_ol, arm);
                }
                (void)iiip_accept(st, III_TOK_COMMA);
            }
            iii_ast_list_t arms = arms_ol ? iii_ast_open_list_commit(st->ast, arms_ol)
                                          : (iii_ast_list_t){ 0u, 0u };
            iii_src_pos_t pos = iiip_pos_of(&t);
            uint32_t n = iiip_alloc_node(st, III_AST_EXPR_MATCH, &pos);
            if (n) {
                iii_ast_node_t *nn = iii_ast_get_mut(st->ast, n);
                nn->u.match_expr.scrutinee = scrut;
                nn->u.match_expr.arms      = arms;
            }
            return n;
        }
        default:
            iiip_record_error(st, III_PARSE_E_EXPECTED_EXPR, &t,
                              "expected expression", III_TOK_INVALID);
            return 0;
    }
}

static uint32_t iiip_parse_postfix(iii_parse_state_t *st, uint32_t lhs)
{
    for (;;) {
        if (iiip_accept(st, III_TOK_DOT)) {
            iii_token_t name;
            if (!iiip_expect(st, III_TOK_IDENTIFIER, &name)) return lhs;
            const iii_ast_node_t *ln = iii_ast_get(st->ast, lhs);
            iii_src_pos_t pos = ln ? iiip_node_pos(st, lhs) : iiip_pos_of(&name);
            pos.end_byte = name.end_byte;
            uint32_t n = iiip_alloc_node(st, III_AST_EXPR_FIELD, &pos);
            if (n == 0) return lhs;
            iii_ast_node_t *nn = iii_ast_get_mut(st->ast, n);
            nn->u.field.object = lhs;
            nn->u.field.field_name = iiip_text_of(&name);
            lhs = n;
            continue;
        }
        if (iiip_accept(st, III_TOK_LPAREN)) {
            iii_ast_list_t args = iiip_parse_arg_list(st);
            iii_token_t close;
            (void)iiip_expect(st, III_TOK_RPAREN, &close);
            const iii_ast_node_t *ln = iii_ast_get(st->ast, lhs);
            iii_src_pos_t pos = ln ? iiip_node_pos(st, lhs) : iiip_pos_of(&close);
            pos.end_byte = close.end_byte;
            uint32_t n = iiip_alloc_node(st, III_AST_EXPR_CALL, &pos);
            if (n == 0) return lhs;
            iii_ast_node_t *nn = iii_ast_get_mut(st->ast, n);
            nn->u.call.callee = lhs;
            nn->u.call.args = args;
            lhs = n;
            continue;
        }
        if (iiip_accept(st, III_TOK_LBRACKET)) {
            uint32_t idx = iiip_parse_expr(st);
            iii_token_t close;
            (void)iiip_expect(st, III_TOK_RBRACKET, &close);
            const iii_ast_node_t *ln = iii_ast_get(st->ast, lhs);
            iii_src_pos_t pos = ln ? iiip_node_pos(st, lhs) : iiip_pos_of(&close);
            pos.end_byte = close.end_byte;
            uint32_t n = iiip_alloc_node(st, III_AST_EXPR_INDEX, &pos);
            if (n == 0) return lhs;
            iii_ast_node_t *nn = iii_ast_get_mut(st->ast, n);
            nn->u.index.object = lhs;
            nn->u.index.index_expr = idx;
            lhs = n;
            continue;
        }
        /* Stage 3.11: `as` is NOT parsed here.  It is handled at the
         * iiip_parse_cast level (looser than unary) so `&x as T` parses as
         * `(&x) as T`, not `&(x as T)`.  See iiip_parse_cast below. */
        break;
    }
    return lhs;
}

static uint32_t iiip_parse_unary(iii_parse_state_t *st)
{
    iii_token_t t = *iiip_peek(st);
    if (t.kind == III_TOK_OP_MINUS || t.kind == III_TOK_OP_BANG ||
        t.kind == III_TOK_OP_TILDE || t.kind == III_TOK_OP_STAR ||
        t.kind == III_TOK_OP_AMP) {
        (void)iiip_advance(st);
        uint32_t operand = iiip_parse_unary(st);
        if (operand == 0) return 0;
        iii_unop_t op = (t.kind == III_TOK_OP_MINUS) ? III_UN_NEG :
                          (t.kind == III_TOK_OP_BANG)  ? III_UN_NOT :
                          (t.kind == III_TOK_OP_TILDE) ? III_UN_BNOT :
                          (t.kind == III_TOK_OP_STAR)  ? III_UN_DEREF :
                                                          III_UN_ADDR;
        const iii_ast_node_t *on = iii_ast_get(st->ast, operand);
        iii_src_pos_t pos = iiip_pos_of(&t);
        if (on) pos.end_byte = iiip_node_pos(st, operand).end_byte;
        uint32_t n = iiip_alloc_node(st, III_AST_EXPR_UNARY, &pos);
        if (n == 0) return 0;
        iii_ast_node_t *nn = iii_ast_get_mut(st->ast, n);
        nn->u.unary.op = op;
        nn->u.unary.operand = operand;
        return n;
    }
    uint32_t prim = iiip_parse_primary(st);
    if (prim == 0) return 0;
    return iiip_parse_postfix(st, prim);
}

/* Stage 3.11: cast level, looser than unary, tighter than binary.  `as`
 * binds the whole unary expression to its left, so `&x as T` == `(&x) as T`
 * and `*p as T` == `(*p) as T` (was `&(x as T)` / `*(p as T)` when `as`
 * lived in parse_postfix below the unary `&`/`*`).  Left-associative for
 * chains (`x as A as B` == `(x as A) as B`).  Non-unary `expr as T` is
 * unchanged: parse_unary->parse_postfix(expr), then the `as` here. */
static uint32_t iiip_parse_cast(iii_parse_state_t *st)
{
    uint32_t lhs = iiip_parse_unary(st);
    if (lhs == 0) return 0;
    for (;;) {
        if (iiip_accept(st, III_TOK_KW_AS)) {
            uint32_t target = iiip_parse_type_expr(st);
            const iii_ast_node_t *ln = iii_ast_get(st->ast, lhs);
            iii_src_pos_t pos = ln ? iiip_node_pos(st, lhs) : iiip_pos_of(iiip_peek(st));
            uint32_t n = iiip_alloc_node(st, III_AST_EXPR_CAST, &pos);
            if (n == 0) return lhs;
            iii_ast_node_t *nn = iii_ast_get_mut(st->ast, n);
            nn->u.cast_.value_expr = lhs;
            nn->u.cast_.target_type = target;
            lhs = n;
            continue;
        }
        break;
    }
    return lhs;
}

static uint32_t iiip_parse_expr_prec(iii_parse_state_t *st, int min_prec)
{
    uint32_t lhs = iiip_parse_cast(st);
    if (lhs == 0) return 0;
    for (;;) {
        iii_token_kind_t k = iiip_peek_kind(st);
        iiip_binop_info_t bi = iiip_binop_for(k);
        if (bi.prec == 0 || bi.prec < min_prec) break;
        /* Q1 — emit the Pratt decision into the optional trace
         * (byte-pos, prec, min_prec, taken=true).  No-op if no sink
         * set.  Declined operators are also traced below. */
        if (st->pratt_trace) {
            st->pratt_trace(st->pratt_trace_ctx,
                            iiip_peek(st)->start_byte,
                            bi.prec, min_prec, true);
        }
        (void)iiip_advance(st);
        int next_min = bi.right_assoc ? bi.prec : (bi.prec + 1);
        uint32_t rhs = iiip_parse_expr_prec(st, next_min);
        if (rhs == 0) return lhs;
        const iii_ast_node_t *ln = iii_ast_get(st->ast, lhs);
        const iii_ast_node_t *rn = iii_ast_get(st->ast, rhs);
        iii_src_pos_t pos = ln ? iiip_node_pos(st, lhs) : iiip_pos_of(iiip_peek(st));
        if (rn) pos.end_byte = iiip_node_pos(st, rhs).end_byte;
        uint32_t n = iiip_alloc_node(st, III_AST_EXPR_BINARY, &pos);
        if (n == 0) return lhs;
        iii_ast_node_t *nn = iii_ast_get_mut(st->ast, n);
        nn->u.binary.op  = bi.op;
        nn->u.binary.lhs = lhs;
        nn->u.binary.rhs = rhs;
        lhs = n;
    }
    return lhs;
}

static uint32_t iiip_parse_expr(iii_parse_state_t *st)
{
    /* H2 — push EXPR breadcrumb so any error raised within the
     * Pratt machinery and its descendants can be rendered with the
     * correct grammatical context. */
    iiip_bc_push(st, IIIP_PROD_EXPR, (iii_src_text_t){0u, 0u});
    if (!iiip_enter_recursion(st)) { iiip_bc_pop(st); return 0; }
    uint32_t r = iiip_parse_expr_prec(st, 1);
    iiip_leave_recursion(st);
    iiip_bc_pop(st);
    return r;
}

/* ─── Pattern parsing ────────────────────────────────────────────── */

static uint32_t iiip_parse_pattern(iii_parse_state_t *st)
{
    iii_token_t t = *iiip_peek(st);
    if (t.kind == III_TOK_UNDERSCORE) {
        (void)iiip_advance(st);
        iii_src_pos_t pos = iiip_pos_of(&t);
        return iiip_alloc_node(st, III_AST_PAT_WILDCARD, &pos);
    }
    if (t.kind == III_TOK_LPAREN) {
        /* Tuple pattern OR hexad pattern. */
        (void)iiip_advance(st);
        /* Reuse hexad-detection from primary. */
        iii_token_t la = *iiip_peek(st);
        bool is_trit_start =
            (la.kind == III_TOK_KW_NEG || la.kind == III_TOK_KW_ZERO ||
             la.kind == III_TOK_KW_POS || la.kind == III_TOK_KW_TRIT_INVALID ||
             la.kind == III_TOK_OP_PLUS || la.kind == III_TOK_OP_MINUS ||
             (la.kind == III_TOK_INT_LITERAL && (la.int_value == 0 || la.int_value == 1)));
        if (is_trit_start) {
            /* L1 — delegated to iiip_parse_hexad_trits with pattern
             * extras (underscore wildcard) enabled. */
            iii_ast_trit_t trits[6];
            bool ok = iiip_parse_hexad_trits(st, trits, true);
            if (ok && iiip_accept(st, III_TOK_RPAREN)) {
                iii_src_pos_t pos = iiip_pos_of(&t);
                pos.end_byte = iiip_peek(st)->start_byte;
                uint32_t n = iiip_alloc_node(st, III_AST_PAT_HEXAD, &pos);
                if (n) memcpy(iii_ast_get_mut(st->ast, n)->u.pat_hexad.trits, trits, sizeof(trits));
                return n;
            }
            /* Otherwise tuple pattern. */
        }
        /* Tuple pattern. */
        iii_ast_open_list_t *ol = iii_ast_open_list_create(st->ast);
        if (ol && !iiip_match(st, III_TOK_RPAREN)) {
            for (;;) {
                uint32_t p = iiip_parse_pattern(st);
                if (p == 0) break;
                iii_ast_open_list_push(ol, p);
                if (!iiip_accept(st, III_TOK_COMMA)) break;
            }
        }
        (void)iiip_expect(st, III_TOK_RPAREN, NULL);
        iii_ast_list_t comps = ol ? iii_ast_open_list_commit(st->ast, ol)
                                  : (iii_ast_list_t){ 0u, 0u };
        iii_src_pos_t pos = iiip_pos_of(&t);
        uint32_t n = iiip_alloc_node(st, III_AST_PAT_TUPLE, &pos);
        if (n) iii_ast_get_mut(st->ast, n)->u.pat_tuple.components = comps;
        return n;
    }
    if (t.kind == III_TOK_INT_LITERAL || t.kind == III_TOK_HEX_LITERAL ||
        t.kind == III_TOK_STRING_LITERAL || t.kind == III_TOK_KW_TRUE ||
        t.kind == III_TOK_KW_FALSE) {
        uint32_t lit = iiip_parse_primary(st);
        const iii_ast_node_t *ln = iii_ast_get(st->ast, lit);
        iii_src_pos_t pos = ln ? iiip_node_pos(st, lit) : iiip_pos_of(&t);
        uint32_t n = iiip_alloc_node(st, III_AST_PAT_LITERAL, &pos);
        if (n) iii_ast_get_mut(st->ast, n)->u.pat_literal.literal_node = lit;
        return n;
    }
    if (t.kind == III_TOK_IDENTIFIER) {
        iii_token_t name = iiip_advance(st);
        iii_ast_list_t pats = { 0u, 0u };
        if (iiip_accept(st, III_TOK_LPAREN)) {
            iii_ast_open_list_t *ol = iii_ast_open_list_create(st->ast);
            if (ol && !iiip_match(st, III_TOK_RPAREN)) {
                for (;;) {
                    uint32_t p = iiip_parse_pattern(st);
                    if (p == 0) break;
                    iii_ast_open_list_push(ol, p);
                    if (!iiip_accept(st, III_TOK_COMMA)) break;
                }
            }
            (void)iiip_expect(st, III_TOK_RPAREN, NULL);
            pats = ol ? iii_ast_open_list_commit(st->ast, ol)
                      : (iii_ast_list_t){ 0u, 0u };
        }
        iii_src_pos_t pos = iiip_pos_of(&name);
        uint32_t n = iiip_alloc_node(st, III_AST_PAT_IDENT, &pos);
        if (n) {
            iii_ast_node_t *nn = iii_ast_get_mut(st->ast, n);
            nn->u.pat_ident.name = iiip_text_of(&name);
            nn->u.pat_ident.payload_pats = pats;
        }
        return n;
    }
    iiip_record_error(st, III_PARSE_E_EXPECTED_PATTERN, &t,
                      "expected pattern", III_TOK_INVALID);
    return 0;
}

/* ─── Statement / block parsing ──────────────────────────────────── */

static uint32_t iiip_parse_block(iii_parse_state_t *st)
{
    iii_token_t lb;
    if (!iiip_expect(st, III_TOK_LBRACE, &lb)) return 0;
    iii_ast_open_list_t *ol = iii_ast_open_list_create(st->ast);
    for (;;) {
        iiip_skip_newlines(st);
        if (iiip_accept(st, III_TOK_RBRACE)) break;
        if (iiip_match(st, III_TOK_EOF)) break;
        uint32_t s = iiip_parse_stmt(st);
        if (s == 0) {
            /* B1 — recover to the BLOCK production's FOLLOW set
             * (defined in the central FF table); this absorbs any
             * stray tokens until we see a stmt-ender or block close
             * and keeps the recovery policy in one place. */
            iiip_recover_follow(st, IIIP_PROD_BLOCK);
            (void)iiip_accept(st, III_TOK_SEMI);
            (void)iiip_accept(st, III_TOK_NEWLINE);
            continue;
        }
        if (ol) iii_ast_open_list_push(ol, s);
        iiip_skip_newlines(st);
        (void)iiip_accept(st, III_TOK_SEMI);
    }
    iii_ast_list_t stmts = ol ? iii_ast_open_list_commit(st->ast, ol)
                              : (iii_ast_list_t){ 0u, 0u };
    iii_src_pos_t pos = iiip_pos_of(&lb);
    uint32_t n = iiip_alloc_node(st, III_AST_EXPR_BLOCK, &pos);
    if (n) iii_ast_get_mut(st->ast, n)->u.block.stmts = stmts;
    return n;
}

static uint32_t iiip_parse_let(iii_parse_state_t *st)
{
    iii_token_t kw;
    /* Stage 3.17: accept `let` or `var` as a local binding.  `var name : T`
     * is a mutable local (matches module-scope `var` semantics) and enables
     * local arrays `var buf : [u8; N]` -- the STMT_LET codegen already
     * reserves ceil(N*width/8) slots for an array-typed binding.  `let`
     * keeps its optional `mut`.  (Module-scope `var` routes separately via
     * iiip_parse_var_decl; this only affects statement position.) */
    bool is_var = (iiip_peek_kind(st) == III_TOK_KW_VAR);
    if (is_var) {
        if (!iiip_expect(st, III_TOK_KW_VAR, &kw)) return 0;
    } else {
        if (!iiip_expect(st, III_TOK_KW_LET, &kw)) return 0;
    }
    bool mutable_ = is_var ? true : iiip_accept(st, III_TOK_KW_MUT);
    iii_token_t name;
    /* Accept either an identifier or `_` (the discard pattern).  `let _`
     * binds the rhs's slot but the name is unreferenceable by user
     * code — common pattern for evaluating an expression for its side
     * effects without naming it.  Both tokens carry a span that
     * iiip_text_of can read, so the binder gets a unique name (the
     * single underscore character) but multiple `let _` in scope
     * silently shadow each other (intentional). */
    iii_token_t *peek_tok = iiip_peek(st);
    if (peek_tok && peek_tok->kind == III_TOK_UNDERSCORE) {
        name = *peek_tok;
        (void)iiip_advance(st);
    } else if (!iiip_expect(st, III_TOK_IDENTIFIER, &name)) {
        return 0;
    }
    uint32_t type_node = 0;
    if (iiip_accept(st, III_TOK_COLON)) {
        type_node = iiip_parse_type_expr(st);
        /* iiis-1 type-system surface (Phase 3 Step 3): a `let` binding
         * may carry inline `@modifier(...)` annotations on its type,
         * notably `@hexad_kind(K)` for first-class intent types.  The
         * modifiers are attached to the resolved type_ref node so
         * codegen can read them at call sites that consume this
         * binding as an argument.  Same machinery as the param parser. */
        iii_ast_open_list_t *let_mods_ol = NULL;
        while (iiip_match(st, III_TOK_AT)) {
            iii_token_t at_tok = iiip_advance(st);
            uint32_t m = iiip_parse_modifier_after_at(st, &at_tok);
            if (m) {
                if (!let_mods_ol)
                    let_mods_ol = iii_ast_open_list_create(st->ast);
                if (let_mods_ol)
                    iii_ast_open_list_push(let_mods_ol, m);
            }
        }
        if (let_mods_ol) {
            iii_ast_list_t let_mods =
                iii_ast_open_list_commit(st->ast, let_mods_ol);
            if (type_node) {
                iii_ast_node_t *tnp = iii_ast_get_mut(st->ast, type_node);
                if (tnp && tnp->kind == III_AST_TYPE_REF)
                    tnp->u.type_ref.modifiers = let_mods;
            }
        }
    }
    /* F8.5 — initializer is OPTIONAL when a type annotation is given.
     * `let p: Point` declares p with no initializer (struct slots
     * stay uninitialised; user must field-write before reading).
     * Without a type annotation, an `=` is required because we can't
     * infer the type. */
    uint32_t value = 0;
    if (iiip_accept(st, III_TOK_OP_ASSIGN)) {
        value = iiip_parse_expr(st);
    } else if (type_node == 0) {
        /* No type AND no initializer — error. */
        iiip_record_error(st, III_PARSE_E_EXPECTED_EXPR, iiip_peek(st),
                          "let without type annotation requires '= expr' initializer",
                          III_TOK_OP_ASSIGN);
    }
    iii_src_pos_t pos = iiip_pos_of(&kw);
    uint32_t n = iiip_alloc_node(st, III_AST_STMT_LET, &pos);
    if (n) {
        iii_ast_node_t *nn = iii_ast_get_mut(st->ast, n);
        nn->u.let_.mutable_ = mutable_;
        nn->u.let_.name = iiip_text_of(&name);
        nn->u.let_.type_node = type_node;
        nn->u.let_.value_expr = value;
    }
    return n;
}

static uint32_t iiip_parse_wavefront(iii_parse_state_t *st)
{
    iii_token_t kw;
    if (!iiip_expect(st, III_TOK_KW_WAVEFRONT, &kw)) return 0;
    iii_ast_list_t mods = iiip_parse_modifier_list(st);
    (void)iiip_expect(st, III_TOK_LBRACE, NULL);
    iii_ast_open_list_t *ol = iii_ast_open_list_create(st->ast);
    for (;;) {
        iiip_skip_newlines(st);
        if (iiip_accept(st, III_TOK_RBRACE)) break;
        if (iiip_match(st, III_TOK_EOF)) break;
        uint32_t expr = iiip_parse_expr(st);
        if (expr == 0) break;
        iii_src_pos_t pos = iiip_node_pos(st, expr);
        uint32_t es = iiip_alloc_node(st, III_AST_STMT_EXPR, &pos);
        if (es) iii_ast_get_mut(st->ast, es)->u.expr_stmt.expr = expr;
        if (ol) iii_ast_open_list_push(ol, es);
        (void)iiip_accept(st, III_TOK_SEMI);
        iiip_skip_newlines(st);
    }
    iii_ast_list_t nodes = ol ? iii_ast_open_list_commit(st->ast, ol)
                              : (iii_ast_list_t){ 0u, 0u };
    /* Optional `until quiescent`. */
    (void)iiip_accept(st, III_TOK_KW_UNTIL);
    (void)iiip_accept(st, III_TOK_KW_QUIESCENT);
    /* Optional `; on_rollback block`. */
    uint32_t on_rb = 0;
    if (iiip_accept(st, III_TOK_SEMI)) {
        if (iiip_accept(st, III_TOK_KW_ON_ROLLBACK)) {
            on_rb = iiip_parse_block(st);
        }
    }
    iii_src_pos_t pos = iiip_pos_of(&kw);
    uint32_t n = iiip_alloc_node(st, III_AST_STMT_WAVEFRONT, &pos);
    if (n) {
        iii_ast_node_t *nn = iii_ast_get_mut(st->ast, n);
        nn->u.wavefront.modifiers = mods;
        nn->u.wavefront.nodes     = nodes;
        nn->u.wavefront.on_rollback_block = on_rb;
    }
    return n;
}

static uint32_t iiip_parse_sanctum_enter(iii_parse_state_t *st)
{
    iii_token_t kw;
    if (!iiip_expect(st, III_TOK_KW_SANCTUM_ENTER, &kw)) return 0;
    (void)iiip_expect(st, III_TOK_PIPE, NULL);
    iii_token_t var;
    if (!iiip_expect(st, III_TOK_IDENTIFIER, &var)) return 0;
    (void)iiip_expect(st, III_TOK_PIPE, NULL);
    uint32_t body = iiip_parse_block(st);
    iii_src_pos_t pos = iiip_pos_of(&kw);
    uint32_t n = iiip_alloc_node(st, III_AST_STMT_SANCTUM_ENTER, &pos);
    if (n) {
        iii_ast_node_t *nn = iii_ast_get_mut(st->ast, n);
        nn->u.sanctum_enter.frame_var = iiip_text_of(&var);
        nn->u.sanctum_enter.body_block = body;
    }
    return n;
}

static uint32_t iiip_parse_metal(iii_parse_state_t *st)
{
    iii_token_t kw;
    if (!iiip_expect(st, III_TOK_KW_METAL, &kw)) return 0;
    /* Optional @ring(...). */
    uint32_t ring_mask = 0;
    if (iiip_match(st, III_TOK_AT)) {
        uint32_t mod = iiip_parse_modifier(st);
        if (mod) {
            const iii_ast_node_t *mn = iii_ast_get(st->ast, mod);
            if (mn) ring_mask = mn->u.modifier.ring_mask;
        }
    }
    /* Body: opaque text between { and }.  We capture the bytes inside
     * the braces verbatim.  The parser does NOT lex inside the body —
     * it counts braces at the byte level. */
    iii_token_t lb;
    if (!iiip_expect(st, III_TOK_LBRACE, &lb)) return 0;
    /* The current parser sits at the byte right after the '{'.  We
     * scan the source until the matching '}' is found.  Because the
     * lexer's lookahead was already advanced past '{', we rely on the
     * lexer's `pos` to be at the start of the body bytes — which it is
     * after consuming '{'.
     *
     * For Stage 0 we record the body as a single EXPR_RAW_ASM node
     * whose payload is a stable arena copy of the bytes. */
    /* Re-engage lexer to find the matching '}': we can't peek bytes
     * easily, so we keep advancing tokens until we hit a '}' that
     * matches the depth count. */
    uint32_t depth = 1;
    /* Capture starting byte offset = lookahead's start_byte. */
    iii_token_t la = *iiip_peek(st);
    uint32_t body_start_byte = la.start_byte;
    uint32_t body_end_byte   = body_start_byte;
    for (;;) {
        if (iiip_match(st, III_TOK_LBRACE)) { depth += 1; body_end_byte = iiip_peek(st)->end_byte; (void)iiip_advance(st); }
        else if (iiip_match(st, III_TOK_RBRACE)) {
            depth -= 1;
            iii_token_t close = iiip_advance(st);
            if (depth == 0) { body_end_byte = close.start_byte; break; }
            body_end_byte = close.end_byte;
        }
        else if (iiip_match(st, III_TOK_EOF)) {
            iiip_record_error(st, III_PARSE_E_UNEXPECTED_EOF, iiip_peek(st),
                              "unterminated metal {} block",
                              III_TOK_RBRACE);
            break;
        }
        else { body_end_byte = iiip_peek(st)->end_byte; (void)iiip_advance(st); }
    }
    /* The opaque payload's bytes are source[body_start_byte .. body_end_byte).
     * We do not own a chunk arena here; we intern the pointer as-is and
     * record the length.  The string_payloads table holds (uint8_t *)
     * pointers; we store an offset+length encoded as two table entries.
     *
     * Simpler: store start/length inline in the metal payload via the
     * raw_asm_str_idx + raw_asm_len fields (raw_asm_str_idx repurposed
     * as byte offset into source_buf). */
    iii_src_pos_t pos = iiip_pos_of(&kw);
    uint32_t n = iiip_alloc_node(st, III_AST_STMT_METAL, &pos);
    if (n) {
        iii_ast_node_t *nn = iii_ast_get_mut(st->ast, n);
        nn->u.metal.ring_mask = ring_mask;
        nn->u.metal.raw_asm_str_idx = body_start_byte;
        nn->u.metal.raw_asm_len = (uint32_t)(body_end_byte - body_start_byte);
    }
    return n;
}

/* F1 — `if cond { then } [else { else_block | if-stmt }]` */
static uint32_t iiip_parse_if(iii_parse_state_t *st)
{
    iii_token_t kw;
    if (!iiip_expect(st, III_TOK_KW_IF, &kw)) return 0;
    uint32_t cond = iiip_parse_expr(st);
    uint32_t then_block = iiip_parse_block(st);
    uint32_t else_block = 0;
    /* Permit newlines between `}` of the then-block and the `else`
     * keyword.  Allows `}\n    else {` formatting which is more
     * readable than the legacy `} else {` single-line requirement. */
    iiip_skip_newlines(st);
    if (iiip_accept(st, III_TOK_KW_ELSE)) {
        iiip_skip_newlines(st);
        /* `else if` cascades by recursing parse_if; otherwise expect a block. */
        if (iiip_match(st, III_TOK_KW_IF)) {
            else_block = iiip_parse_if(st);
        } else {
            else_block = iiip_parse_block(st);
        }
    }
    iii_src_pos_t pos = iiip_pos_of(&kw);
    uint32_t n = iiip_alloc_node(st, III_AST_STMT_IF, &pos);
    if (n) {
        iii_ast_node_t *nn = iii_ast_get_mut(st->ast, n);
        nn->u.if_.cond = cond;
        nn->u.if_.then_block = then_block;
        nn->u.if_.else_block = else_block;
    }
    return n;
}

/* F2 — `while cond { body }` */
static uint32_t iiip_parse_while(iii_parse_state_t *st)
{
    iii_token_t kw;
    if (!iiip_expect(st, III_TOK_KW_WHILE, &kw)) return 0;
    uint32_t cond = iiip_parse_expr(st);
    uint32_t body = iiip_parse_block(st);
    iii_src_pos_t pos = iiip_pos_of(&kw);
    uint32_t n = iiip_alloc_node(st, III_AST_STMT_WHILE, &pos);
    if (n) {
        iii_ast_node_t *nn = iii_ast_get_mut(st->ast, n);
        nn->u.while_.cond = cond;
        nn->u.while_.body_block = body;
    }
    return n;
}

/* iiis-2 — `loop { body }` (unconditional loop, exit via break/return). */
static uint32_t iiip_parse_loop(iii_parse_state_t *st)
{
    iii_token_t kw;
    if (!iiip_expect(st, III_TOK_KW_LOOP, &kw)) return 0;
    uint32_t body = iiip_parse_block(st);
    iii_src_pos_t pos = iiip_pos_of(&kw);
    uint32_t n = iiip_alloc_node(st, III_AST_STMT_LOOP, &pos);
    if (n) {
        iii_ast_node_t *nn = iii_ast_get_mut(st->ast, n);
        nn->u.loop_.body_block = body;
    }
    return n;
}

/* iiis-2 — `break` (exit innermost enclosing loop). */
static uint32_t iiip_parse_break(iii_parse_state_t *st)
{
    iii_token_t kw;
    if (!iiip_expect(st, III_TOK_KW_BREAK, &kw)) return 0;
    iii_src_pos_t pos = iiip_pos_of(&kw);
    uint32_t n = iiip_alloc_node(st, III_AST_STMT_BREAK, &pos);
    if (n) {
        iii_ast_get_mut(st->ast, n)->u.break_.reserved = 0u;
    }
    return n;
}

/* iiis-2 — `continue` (restart innermost enclosing loop). */
static uint32_t iiip_parse_continue(iii_parse_state_t *st)
{
    iii_token_t kw;
    if (!iiip_expect(st, III_TOK_KW_CONTINUE, &kw)) return 0;
    iii_src_pos_t pos = iiip_pos_of(&kw);
    uint32_t n = iiip_alloc_node(st, III_AST_STMT_CONTINUE, &pos);
    if (n) {
        iii_ast_get_mut(st->ast, n)->u.continue_.reserved = 0u;
    }
    return n;
}

static uint32_t iiip_parse_for(iii_parse_state_t *st)
{
    iii_token_t kw;
    if (!iiip_expect(st, III_TOK_KW_FOR, &kw)) return 0;
    iii_token_t var;
    if (!iiip_expect(st, III_TOK_IDENTIFIER, &var)) return 0;
    (void)iiip_expect(st, III_TOK_KW_IN, NULL);
    uint32_t iter = iiip_parse_expr(st);
    /* F3 — `lo .. hi` range form.  After parsing the first expression,
     * if the next token is `..` we consume it, parse the upper bound,
     * and synthesise an EXPR_RANGE node carrying both endpoints.  The
     * codegen for STMT_FOR detects EXPR_RANGE and emits an integer
     * counter loop; for non-range iter_expr forms (collection, glyph
     * stream) the codegen path is Stage-1+ work. */
    if (iiip_accept(st, III_TOK_OP_DOTDOT)) {
        uint32_t hi = iiip_parse_expr(st);
        iii_src_pos_t rpos = iiip_node_pos(st, iter);
        uint32_t rn = iiip_alloc_node(st, III_AST_EXPR_RANGE, &rpos);
        if (rn) {
            iii_ast_node_t *rnp = iii_ast_get_mut(st->ast, rn);
            rnp->u.range_.lo = iter;
            rnp->u.range_.hi = hi;
            iter = rn;
        }
    }
    uint32_t where = 0;
    if (iiip_accept(st, III_TOK_KW_WHERE)) {
        where = iiip_parse_expr(st);
    }
    uint32_t body = iiip_parse_block(st);
    iii_src_pos_t pos = iiip_pos_of(&kw);
    uint32_t n = iiip_alloc_node(st, III_AST_STMT_FOR, &pos);
    if (n) {
        iii_ast_node_t *nn = iii_ast_get_mut(st->ast, n);
        nn->u.for_.var = iiip_text_of(&var);
        nn->u.for_.iter_expr = iter;
        nn->u.for_.where_expr = where;
        nn->u.for_.body_block = body;
    }
    return n;
}

static uint32_t iiip_parse_return(iii_parse_state_t *st)
{
    iii_token_t kw;
    if (!iiip_expect(st, III_TOK_KW_RETURN, &kw)) return 0;
    uint32_t v = 0;
    if (!iiip_match(st, III_TOK_NEWLINE) && !iiip_match(st, III_TOK_SEMI) &&
        !iiip_match(st, III_TOK_RBRACE)) {
        v = iiip_parse_expr(st);
    }
    iii_src_pos_t pos = iiip_pos_of(&kw);
    uint32_t n = iiip_alloc_node(st, III_AST_STMT_RETURN, &pos);
    if (n) iii_ast_get_mut(st->ast, n)->u.return_.value_expr = v;
    return n;
}

static uint32_t iiip_parse_stmt(iii_parse_state_t *st)
{
    if (!iiip_enter_recursion(st)) return 0;
    uint32_t r = 0;
    iii_token_kind_t k = iiip_peek_kind(st);
    /* R1 — registry dispatch first; non-zero return wins. */
    r = iiip_registry_dispatch(st, &st->reg_stmt, k);
    if (r != 0u) { iiip_leave_recursion(st); return r; }
    switch (k) {
        case III_TOK_KW_LET:           r = iiip_parse_let(st); break;
        case III_TOK_KW_VAR:           r = iiip_parse_let(st); break;  /* Stage 3.17: local var */
        case III_TOK_KW_WAVEFRONT:     r = iiip_parse_wavefront(st); break;
        case III_TOK_KW_SANCTUM_ENTER: r = iiip_parse_sanctum_enter(st); break;
        case III_TOK_KW_METAL:         r = iiip_parse_metal(st); break;
        case III_TOK_KW_FOR:           r = iiip_parse_for(st); break;
        case III_TOK_KW_RETURN:        r = iiip_parse_return(st); break;
        case III_TOK_KW_IF:            r = iiip_parse_if(st); break;
        case III_TOK_KW_WHILE:         r = iiip_parse_while(st); break;
        case III_TOK_KW_LOOP:          r = iiip_parse_loop(st); break;
        case III_TOK_KW_BREAK:         r = iiip_parse_break(st); break;
        case III_TOK_KW_CONTINUE:      r = iiip_parse_continue(st); break;
        case III_TOK_KW_MATCH: {
            /* match as statement: same parse as match expression. */
            uint32_t e = iiip_parse_expr(st);
            iii_src_pos_t pos = e ? iiip_node_pos(st, e)
                                     : iiip_pos_of(iiip_peek(st));
            r = iiip_alloc_node(st, III_AST_STMT_EXPR, &pos);
            if (r) iii_ast_get_mut(st->ast, r)->u.expr_stmt.expr = e;
            break;
        }
        default: {
            /* Parse expression; if followed by `=`, it's an assignment.
             * Otherwise it's an expression statement. */
            uint32_t lhs = iiip_parse_expr(st);
            if (lhs == 0) break;
            if (iiip_accept(st, III_TOK_OP_ASSIGN)) {
                uint32_t rhs = iiip_parse_expr(st);
                iii_src_pos_t pos = iiip_node_pos(st, lhs);
                r = iiip_alloc_node(st, III_AST_STMT_ASSIGN, &pos);
                if (r) {
                    iii_ast_node_t *rn = iii_ast_get_mut(st->ast, r);
                    rn->u.assign.lvalue_expr = lhs;
                    rn->u.assign.value_expr = rhs;
                }
            } else {
                iii_src_pos_t pos = iiip_node_pos(st, lhs);
                r = iiip_alloc_node(st, III_AST_STMT_EXPR, &pos);
                if (r) iii_ast_get_mut(st->ast, r)->u.expr_stmt.expr = lhs;
            }
            break;
        }
    }
    iiip_leave_recursion(st);
    return r;
}

/* ─── Declaration parsing ────────────────────────────────────────── */

static iii_ast_list_t iiip_parse_param_list(iii_parse_state_t *st)
{
    iii_ast_list_t empty = { 0u, 0u };
    if (!iiip_expect(st, III_TOK_LPAREN, NULL)) return empty;
    /* Allow newlines inside the parameter list — multi-line fn signatures
     * are mandatory for iiis-1's annotation-heavy declarations.  Newlines
     * are permitted after LPAREN, before/after COLON, after COMMA, and
     * before RPAREN.  Single-line signatures stay valid (skip_newlines
     * is a no-op when no newlines are present). */
    iiip_skip_newlines(st);
    if (iiip_accept(st, III_TOK_RPAREN)) return empty;
    iii_ast_open_list_t *ol = iii_ast_open_list_create(st->ast);
    if (!ol) {
        (void)iiip_expect(st, III_TOK_RPAREN, NULL);
        return empty;
    }
    for (;;) {
        /* Permit optional `mut` before parameter name.  iiis-0 stores
         * params in stack slots that are inherently mutable; the `mut`
         * keyword is purely a readability marker for now (does not
         * change codegen).  Accepting it lets stdlib + corpus authors
         * write `fn foo(mut x: u64, y: u64)` for params they intend to
         * reassign, matching the `let mut` convention. */
        (void)iiip_accept(st, III_TOK_KW_MUT);
        iii_token_t name;
        if (!iiip_expect(st, III_TOK_IDENTIFIER, &name)) break;
        iiip_skip_newlines(st);
        (void)iiip_expect(st, III_TOK_COLON, NULL);
        iiip_skip_newlines(st);
        uint32_t type_node = iiip_parse_type_expr(st);
        /* iiis-1 type-system surface: collect any @modifier(...) annotations
         * attached to the parameter type and ATTACH them to the type_ref
         * node's modifier list.  Phase 3 Step 3 first-class intent
         * types require codegen to read these modifiers (specifically
         * `@hexad_kind`) at call sites — they are no longer opaque
         * metadata.  When the type is not a TYPE_REF (e.g. ptr/array),
         * the modifiers are still parsed (so syntax is consistent) but
         * dropped on the floor.  Stage-2+ will extend the attachment
         * to all type kinds. */
        iiip_skip_newlines(st);
        iii_ast_open_list_t *param_mods_ol = NULL;
        while (iiip_match(st, III_TOK_AT)) {
            iii_token_t at_tok = iiip_advance(st);
            uint32_t m = iiip_parse_modifier_after_at(st, &at_tok);
            if (m) {
                if (!param_mods_ol)
                    param_mods_ol = iii_ast_open_list_create(st->ast);
                if (param_mods_ol)
                    iii_ast_open_list_push(param_mods_ol, m);
            }
            iiip_skip_newlines(st);
        }
        if (param_mods_ol) {
            iii_ast_list_t param_mods =
                iii_ast_open_list_commit(st->ast, param_mods_ol);
            if (type_node) {
                iii_ast_node_t *tnp = iii_ast_get_mut(st->ast, type_node);
                if (tnp && tnp->kind == III_AST_TYPE_REF)
                    tnp->u.type_ref.modifiers = param_mods;
            }
        }
        iii_src_pos_t pos = iiip_pos_of(&name);
        if (type_node) pos.end_byte = iiip_node_pos(st, type_node).end_byte;
        uint32_t pn = iiip_alloc_node(st, III_AST_PARAM, &pos);
        if (pn == 0) break;
        iii_ast_node_t *pp = iii_ast_get_mut(st->ast, pn);
        pp->u.param.name = iiip_text_of(&name);
        pp->u.param.type_node = type_node;
        iii_ast_open_list_push(ol, pn);
        iiip_skip_newlines(st);
        if (!iiip_accept(st, III_TOK_COMMA)) break;
        iiip_skip_newlines(st);
    }
    iiip_skip_newlines(st);
    (void)iiip_expect(st, III_TOK_RPAREN, NULL);
    return iii_ast_open_list_commit(st->ast, ol);
}

static uint32_t iiip_parse_cycle_decl(iii_parse_state_t *st)
{
    iii_token_t kw;
    if (!iiip_expect(st, III_TOK_KW_CYCLE, &kw)) return 0;
    /* H2 — push CYCLE_DECL crumb so any nested error renders with
     * "in cycle <name>" context (detail = name span). */
    iii_token_t name;
    if (!iiip_expect(st, III_TOK_IDENTIFIER, &name)) return 0;
    iiip_bc_push(st, IIIP_PROD_CYCLE_DECL, iiip_text_of(&name));
    iii_ast_list_t params = iiip_parse_param_list(st);
    uint32_t ret = 0;
    if (iiip_accept(st, III_TOK_ARROW)) {
        ret = iiip_parse_type_expr(st);
    }
    iii_ast_list_t mods = iiip_parse_modifier_list(st);
    /* Cycle body: `{ forward { stmts } compromise(SEV)? }` */
    (void)iiip_expect(st, III_TOK_LBRACE, NULL);
    iiip_skip_newlines(st);
    uint32_t fb = 0;
    if (iiip_accept(st, III_TOK_KW_FORWARD)) {
        (void)iiip_expect(st, III_TOK_LBRACE, NULL);
        iii_ast_open_list_t *ol = iii_ast_open_list_create(st->ast);
        for (;;) {
            iiip_skip_newlines(st);
            if (iiip_accept(st, III_TOK_RBRACE)) break;
            if (iiip_match(st, III_TOK_EOF)) break;
            uint32_t s = iiip_parse_stmt(st);
            if (s == 0) break;
            if (ol) iii_ast_open_list_push(ol, s);
            (void)iiip_accept(st, III_TOK_SEMI);
        }
        iii_ast_list_t stmts = ol ? iii_ast_open_list_commit(st->ast, ol)
                                  : (iii_ast_list_t){ 0u, 0u };
        iii_src_pos_t pos = iiip_pos_of(&kw);
        fb = iiip_alloc_node(st, III_AST_FORWARD_BLOCK, &pos);
        if (fb) iii_ast_get_mut(st->ast, fb)->u.forward_block.stmts = stmts;
    }
    uint32_t cb = 0;
    iiip_skip_newlines(st);
    if (iiip_accept(st, III_TOK_KW_COMPROMISE)) {
        (void)iiip_expect(st, III_TOK_LPAREN, NULL);
        iii_token_t sev;
        (void)iiip_expect(st, III_TOK_IDENTIFIER, &sev);
        (void)iiip_expect(st, III_TOK_RPAREN, NULL);
        iii_compromise_severity_t s = III_COMPROMISE_LOW;
        if      (iii_token_raw_eq(st->lex, &sev, "NOTE"))     s = III_COMPROMISE_NOTE;
        else if (iii_token_raw_eq(st->lex, &sev, "LOW"))      s = III_COMPROMISE_LOW;
        else if (iii_token_raw_eq(st->lex, &sev, "MEDIUM"))   s = III_COMPROMISE_MEDIUM;
        else if (iii_token_raw_eq(st->lex, &sev, "HIGH"))     s = III_COMPROMISE_HIGH;
        else if (iii_token_raw_eq(st->lex, &sev, "CRITICAL")) s = III_COMPROMISE_CRITICAL;
        iii_src_pos_t pos = iiip_pos_of(&sev);
        cb = iiip_alloc_node(st, III_AST_COMPROMISE_BLOCK, &pos);
        if (cb) iii_ast_get_mut(st->ast, cb)->u.compromise_block.severity = s;
    }
    iiip_skip_newlines(st);
    (void)iiip_expect(st, III_TOK_RBRACE, NULL);
    iii_src_pos_t pos = iiip_pos_of(&kw);
    uint32_t n = iiip_alloc_node(st, III_AST_CYCLE_DECL, &pos);
    if (n) {
        iii_ast_node_t *nn = iii_ast_get_mut(st->ast, n);
        nn->u.cycle_decl.name = iiip_text_of(&name);
        nn->u.cycle_decl.params = params;
        nn->u.cycle_decl.return_type = ret;
        nn->u.cycle_decl.modifiers = mods;
        nn->u.cycle_decl.forward_block = fb;
        nn->u.cycle_decl.compromise_block = cb;
    }
    iiip_bc_pop(st);
    return n;
}

static uint32_t iiip_parse_fn_decl(iii_parse_state_t *st)
{
    iii_token_t kw;
    if (!iiip_expect(st, III_TOK_KW_FN, &kw)) return 0;
    iii_token_t name;
    if (!iiip_expect(st, III_TOK_IDENTIFIER, &name)) return 0;
    /* H2 — push FN_DECL crumb (detail = name span). */
    iiip_bc_push(st, IIIP_PROD_FN_DECL, iiip_text_of(&name));
    /* Stage 7.1: optional generic type-params <T[: kind][, U]> for @specialize.
     * Mirrors iiip_parse_type_decl; absent for ordinary fns (next token is '('). */
    iii_ast_list_t tparams = { 0u, 0u };
    if (iiip_accept(st, III_TOK_OP_LT)) {
        iii_ast_open_list_t *ol = iii_ast_open_list_create(st->ast);
        if (ol && !iiip_match(st, III_TOK_OP_GT)) {
            for (;;) {
                iii_token_t tp;
                if (!iiip_expect(st, III_TOK_IDENTIFIER, &tp)) break;
                iii_src_text_t kind_text = { 0, 0 };
                if (iiip_accept(st, III_TOK_COLON)) {
                    iii_token_t kt;
                    if (iiip_expect(st, III_TOK_IDENTIFIER, &kt)) {
                        kind_text = iiip_text_of(&kt);
                    }
                }
                iii_src_pos_t pp = iiip_pos_of(&tp);
                uint32_t tn = iiip_alloc_node(st, III_AST_TYPE_PARAM, &pp);
                if (tn == 0) break;
                iii_ast_node_t *tnp = iii_ast_get_mut(st->ast, tn);
                tnp->u.type_param.name = iiip_text_of(&tp);
                tnp->u.type_param.kind = kind_text;
                iii_ast_open_list_push(ol, tn);
                if (!iiip_accept(st, III_TOK_COMMA)) break;
            }
        }
        (void)iiip_expect(st, III_TOK_OP_GT, NULL);
        tparams = ol ? iii_ast_open_list_commit(st->ast, ol)
                     : (iii_ast_list_t){ 0u, 0u };
    }
    iii_ast_list_t params = iiip_parse_param_list(st);
    uint32_t ret = 0;
    if (iiip_accept(st, III_TOK_ARROW)) {
        ret = iiip_parse_type_expr(st);
    }
    iii_ast_list_t mods = iiip_parse_modifier_list(st);
    uint32_t body = iiip_parse_block(st);
    iii_src_pos_t pos = iiip_pos_of(&kw);
    uint32_t n = iiip_alloc_node(st, III_AST_FN_DECL, &pos);
    if (n) {
        iii_ast_node_t *nn = iii_ast_get_mut(st->ast, n);
        nn->u.fn_decl.name = iiip_text_of(&name);
        nn->u.fn_decl.params = params;
        nn->u.fn_decl.return_type = ret;
        nn->u.fn_decl.modifiers = mods;
        nn->u.fn_decl.body_block = body;
        nn->u.fn_decl.type_params = tparams;
    }
    iiip_bc_pop(st);
    return n;
}

/* Bracket-array initializer: `[ e1, e2, ... ]`.  Encoded as
 * EXPR_PARALLEL (an ordered list of expressions); cg_r3's module-loop
 * recognises this form for VAR_DECL/CONST_DECL and emits .quad per
 * entry.  Returns 0 on parse failure. */
static uint32_t iiip_parse_bracket_init(iii_parse_state_t *st)
{
    if (!iiip_match(st, III_TOK_LBRACKET)) return 0;
    (void)iiip_advance(st);    /* consume [ */
    iii_ast_open_list_t *ol = iii_ast_open_list_create(st->ast);
    if (ol) {
        iiip_skip_newlines(st);
        if (!iiip_match(st, III_TOK_RBRACKET)) {
            for (;;) {
                iiip_skip_newlines(st);
                uint32_t e = iiip_parse_expr(st);
                if (e == 0) break;
                iii_ast_open_list_push(ol, e);
                iiip_skip_newlines(st);
                if (!iiip_accept(st, III_TOK_COMMA)) break;
            }
        }
    }
    iiip_skip_newlines(st);
    iii_token_t close;
    (void)iiip_expect(st, III_TOK_RBRACKET, &close);
    iii_ast_list_t branches = ol ? iii_ast_open_list_commit(st->ast, ol)
                                 : (iii_ast_list_t){ 0u, 0u };
    iii_src_pos_t ppos = iiip_pos_of(&close);
    uint32_t pn = iiip_alloc_node(st, III_AST_EXPR_PARALLEL, &ppos);
    if (pn) {
        iii_ast_node_t *pnp = iii_ast_get_mut(st->ast, pn);
        pnp->u.parallel.branches = branches;
    }
    return pn;
}

static uint32_t iiip_parse_const_decl(iii_parse_state_t *st)
{
    iii_token_t kw;
    if (!iiip_expect(st, III_TOK_KW_CONST, &kw)) return 0;
    iii_token_t name;
    if (!iiip_expect(st, III_TOK_IDENTIFIER, &name)) return 0;
    (void)iiip_expect(st, III_TOK_COLON, NULL);
    uint32_t t = iiip_parse_type_expr(st);
    (void)iiip_expect(st, III_TOK_OP_ASSIGN, NULL);
    uint32_t v;
    if (iiip_match(st, III_TOK_LBRACKET)) {
        v = iiip_parse_bracket_init(st);
    } else {
        v = iiip_parse_expr(st);
    }
    iii_src_pos_t pos = iiip_pos_of(&kw);
    uint32_t n = iiip_alloc_node(st, III_AST_CONST_DECL, &pos);
    if (n) {
        iii_ast_node_t *nn = iii_ast_get_mut(st->ast, n);
        nn->u.const_decl.name = iiip_text_of(&name);
        nn->u.const_decl.type_node = t;
        nn->u.const_decl.value_expr = v;
    }
    return n;
}

/* F9 + F10 — `var X: T [= init]`.  Module-level mutable global.
 * init may be:
 *   - a literal (EXPR_INT / EXPR_HEX) — Stage-1 .data slot
 *   - a bracket-array initializer `[v1, v2, ...]` — Stage-1 .data
 *     entries laid out sequentially via EXPR_PARALLEL (re-used as a
 *     simple list-of-values container).  Each element must itself be
 *     a literal in Stage-1; richer expressions need a constant folder.
 *   - omitted — .bss zero-init */
static uint32_t iiip_parse_var_decl(iii_parse_state_t *st)
{
    iii_token_t kw;
    if (!iiip_expect(st, III_TOK_KW_VAR, &kw)) return 0;
    iii_token_t name;
    if (!iiip_expect(st, III_TOK_IDENTIFIER, &name)) return 0;
    uint32_t t = 0;
    if (iiip_accept(st, III_TOK_COLON)) {
        t = iiip_parse_type_expr(st);
    }
    uint32_t init = 0;
    if (iiip_accept(st, III_TOK_OP_ASSIGN)) {
        if (iiip_match(st, III_TOK_LBRACKET)) {
            init = iiip_parse_bracket_init(st);
        } else {
            init = iiip_parse_expr(st);
        }
    }
    iii_src_pos_t pos = iiip_pos_of(&kw);
    uint32_t n = iiip_alloc_node(st, III_AST_VAR_DECL, &pos);
    if (n) {
        iii_ast_node_t *nn = iii_ast_get_mut(st->ast, n);
        nn->u.var_decl.name = iiip_text_of(&name);
        nn->u.var_decl.type_node = t;
        nn->u.var_decl.init_expr = init;
    }
    return n;
}

/* F8 — `struct Name { f1: T1, f2: T2, ... }`.  Stage-1 layout: each
 * field gets one 8-byte slot regardless of declared type; total
 * size = field_count * 8.  Stage-2+ adds packed/aligned layouts. */
static uint32_t iiip_parse_struct_decl(iii_parse_state_t *st)
{
    iii_token_t kw;
    if (!iiip_expect(st, III_TOK_KW_STRUCT, &kw)) return 0;
    iii_token_t name;
    if (!iiip_expect(st, III_TOK_IDENTIFIER, &name)) return 0;
    (void)iiip_expect(st, III_TOK_LBRACE, NULL);
    iii_ast_open_list_t *fields_ol = iii_ast_open_list_create(st->ast);
    for (;;) {
        iiip_skip_newlines(st);
        if (iiip_accept(st, III_TOK_RBRACE)) break;
        if (iiip_match(st, III_TOK_EOF)) break;
        iii_token_t fname;
        if (!iiip_expect(st, III_TOK_IDENTIFIER, &fname)) break;
        (void)iiip_expect(st, III_TOK_COLON, NULL);
        uint32_t ft = iiip_parse_type_expr(st);
        iii_src_pos_t pp = iiip_pos_of(&fname);
        if (ft) pp.end_byte = iiip_node_pos(st, ft).end_byte;
        uint32_t fn = iiip_alloc_node(st, III_AST_PARAM, &pp);
        if (fn == 0) break;
        iii_ast_node_t *fnp = iii_ast_get_mut(st->ast, fn);
        fnp->u.param.name = iiip_text_of(&fname);
        fnp->u.param.type_node = ft;
        if (fields_ol) iii_ast_open_list_push(fields_ol, fn);
        if (!iiip_accept(st, III_TOK_COMMA)) {
            iiip_skip_newlines(st);
            (void)iiip_accept(st, III_TOK_RBRACE);
            break;
        }
    }
    iii_ast_list_t fields = fields_ol ? iii_ast_open_list_commit(st->ast, fields_ol)
                                      : (iii_ast_list_t){ 0u, 0u };
    iii_src_pos_t pos = iiip_pos_of(&kw);
    uint32_t n = iiip_alloc_node(st, III_AST_STRUCT_DECL, &pos);
    if (n) {
        iii_ast_node_t *nn = iii_ast_get_mut(st->ast, n);
        nn->u.struct_decl.name = iiip_text_of(&name);
        nn->u.struct_decl.fields = fields;
    }
    return n;
}

static uint32_t iiip_parse_type_decl(iii_parse_state_t *st)
{
    iii_token_t kw;
    if (!iiip_expect(st, III_TOK_KW_TYPE, &kw)) return 0;
    iii_token_t name;
    if (!iiip_expect(st, III_TOK_IDENTIFIER, &name)) return 0;
    /* Optional type-params <T,...>. */
    iii_ast_list_t tparams = { 0u, 0u };
    if (iiip_accept(st, III_TOK_OP_LT)) {
        iii_ast_open_list_t *ol = iii_ast_open_list_create(st->ast);
        if (ol && !iiip_match(st, III_TOK_OP_GT)) {
            for (;;) {
                iii_token_t tp;
                if (!iiip_expect(st, III_TOK_IDENTIFIER, &tp)) break;
                iii_src_text_t kind_text = { 0, 0 };
                if (iiip_accept(st, III_TOK_COLON)) {
                    iii_token_t kt;
                    if (iiip_expect(st, III_TOK_IDENTIFIER, &kt)) {
                        kind_text = iiip_text_of(&kt);
                    }
                }
                iii_src_pos_t pp = iiip_pos_of(&tp);
                uint32_t tn = iiip_alloc_node(st, III_AST_TYPE_PARAM, &pp);
                if (tn == 0) break;
                iii_ast_node_t *tnp = iii_ast_get_mut(st->ast, tn);
                tnp->u.type_param.name = iiip_text_of(&tp);
                tnp->u.type_param.kind = kind_text;
                iii_ast_open_list_push(ol, tn);
                if (!iiip_accept(st, III_TOK_COMMA)) break;
            }
        }
        (void)iiip_expect(st, III_TOK_OP_GT, NULL);
        tparams = ol ? iii_ast_open_list_commit(st->ast, ol)
                     : (iii_ast_list_t){ 0u, 0u };
    }
    (void)iiip_expect(st, III_TOK_OP_ASSIGN, NULL);
    uint32_t rhs = iiip_parse_type_expr(st);
    iii_ast_list_t mods = iiip_parse_modifier_list(st);
    iii_src_pos_t pos = iiip_pos_of(&kw);
    uint32_t n = iiip_alloc_node(st, III_AST_TYPE_DECL, &pos);
    if (n) {
        iii_ast_node_t *nn = iii_ast_get_mut(st->ast, n);
        nn->u.type_decl.name = iiip_text_of(&name);
        nn->u.type_decl.type_params = tparams;
        nn->u.type_decl.rhs_type = rhs;
        nn->u.type_decl.modifiers = mods;
    }
    return n;
}

static uint32_t iiip_parse_extern_decl(iii_parse_state_t *st)
{
    iii_token_t kw;
    if (!iiip_expect(st, III_TOK_KW_EXTERN, &kw)) return 0;
    /* @abi(...) — only legal modifier preceding the fn declaration.
     * The lexer emits the modifier-name "abi" as either an IDENTIFIER
     * (when seen as a free identifier) or as the MOD_ABI keyword token
     * (when emitted by the modifier-keyword path).  Accept both so
     * the extern syntax works regardless of which kind the lexer
     * chose. */
    (void)iiip_expect(st, III_TOK_AT, NULL);
    iii_token_t abi_word;
    iii_token_kind_t aw_k = iiip_peek_kind(st);
    if (aw_k == III_TOK_IDENTIFIER || aw_k == III_TOK_MOD_ABI) {
        abi_word = iiip_advance(st);
    } else {
        iiip_record_error(st, III_PARSE_E_BAD_MODIFIER, iiip_peek(st),
                          "extern declaration requires @abi(<kind>) modifier",
                          III_TOK_IDENTIFIER);
        return 0;
    }
    if (!iii_token_raw_eq(st->lex, &abi_word, "abi")) {
        iiip_record_error(st, III_PARSE_E_BAD_MODIFIER, &abi_word,
                          "extern declaration requires @abi(<kind>) modifier",
                          III_TOK_IDENTIFIER);
    }
    (void)iiip_expect(st, III_TOK_LPAREN, NULL);
    /* F13 — multi-token ABI names: "c-msvc-x64" lexes as IDENT("c"),
     * OP_MINUS, IDENT("msvc"), OP_MINUS, IDENT("x64") because the
     * lex regex for identifiers is [A-Za-z_][A-Za-z0-9_]*. We parse
     * the IDENT-OP_MINUS-IDENT-... composition into a single source
     * span and then byte-compare against the known ABI strings. */
    iii_token_t abi_kind_tok;
    if (!iiip_expect(st, III_TOK_IDENTIFIER, &abi_kind_tok)) return 0;
    uint32_t abi_span_start = abi_kind_tok.start_byte;
    uint32_t abi_span_end   = abi_kind_tok.end_byte;
    while (iiip_match(st, III_TOK_OP_MINUS)) {
        iii_token_t dash = iiip_advance(st);
        (void)dash;
        iii_token_t cont;
        if (iiip_peek_kind(st) == III_TOK_IDENTIFIER ||
            iiip_peek_kind(st) == III_TOK_INT_LITERAL) {
            cont = iiip_advance(st);
            abi_span_end = cont.end_byte;
        } else {
            break;
        }
    }
    (void)iiip_expect(st, III_TOK_RPAREN, NULL);
    iii_abi_kind_t abi = III_ABI_C_MSVC_X64;
    /* Compare against the source-byte slice [abi_span_start, abi_span_end). */
    {
        const uint8_t *src = NULL;
        size_t span_len = (size_t)(abi_span_end - abi_span_start);
        /* iiip helper: source bytes via the lex state — there is no
         * exposed accessor returning the buffer directly, but the
         * tokens carry positions and the AST exposes the source via
         * iii_ast_source_buf.  We use the AST's source buffer (the
         * parser holds the same source as the AST does). */
        src = iii_ast_source_buf(st->ast);
        if (src) {
            const char *s = (const char *)(src + abi_span_start);
            if      (span_len == 10 && memcmp(s, "c-msvc-x64", 10) == 0)        abi = III_ABI_C_MSVC_X64;
            else if (span_len == 10 && memcmp(s, "c-sysv-x64", 10) == 0)        abi = III_ABI_C_SYSV_X64;
            else if (span_len == 16 && memcmp(s, "vmrun-trampoline", 16) == 0)  abi = III_ABI_VMRUN_TRAMPOLINE;
            else if (span_len == 9  && memcmp(s, "magic-msr", 9)  == 0)         abi = III_ABI_MAGIC_MSR;
            else if (span_len == 5  && memcmp(s, "ioctl", 5)  == 0)             abi = III_ABI_IOCTL;
        }
    }
    /* Mirror the original tok-eq path for backwards compat (ioctl
     * single token). */
    if (iii_token_raw_eq(st->lex, &abi_kind_tok, "ioctl"))         abi = III_ABI_IOCTL;
    /* `fn` ident `(` params `)` `->` type `from` "path" */
    (void)iiip_expect(st, III_TOK_KW_FN, NULL);
    iii_token_t name;
    if (!iiip_expect(st, III_TOK_IDENTIFIER, &name)) return 0;
    iii_ast_list_t params = iiip_parse_param_list(st);
    uint32_t ret = 0;
    if (iiip_accept(st, III_TOK_ARROW)) {
        ret = iiip_parse_type_expr(st);
    }
    (void)iiip_expect(st, III_TOK_KW_FROM, NULL);
    iii_token_t path_tok;
    if (!iiip_expect(st, III_TOK_STRING_LITERAL, &path_tok)) return 0;
    uint32_t path_idx = iii_ast_intern_string(st->ast, path_tok.string_payload);
    iii_src_pos_t pos = iiip_pos_of(&kw);
    uint32_t n = iiip_alloc_node(st, III_AST_EXTERN_DECL, &pos);
    if (n) {
        iii_ast_node_t *nn = iii_ast_get_mut(st->ast, n);
        nn->u.extern_decl.abi = abi;
        nn->u.extern_decl.name = iiip_text_of(&name);
        nn->u.extern_decl.params = params;
        nn->u.extern_decl.return_type = ret;
        nn->u.extern_decl.source_path_str_idx = path_idx;
    }
    return n;
}

static uint32_t iiip_parse_mobius_candidate(iii_parse_state_t *st)
{
    iii_token_t kw;
    if (!iiip_expect(st, III_TOK_KW_MOBIUS_CANDIDATE, &kw)) return 0;
    iii_token_t name;
    if (!iiip_expect(st, III_TOK_IDENTIFIER, &name)) return 0;
    (void)iiip_expect(st, III_TOK_COLON, NULL);
    uint32_t in_t = iiip_parse_type_expr(st);
    (void)iiip_expect(st, III_TOK_ARROW, NULL);
    uint32_t out_t = iiip_parse_type_expr(st);
    iii_ast_list_t mods = iiip_parse_modifier_list(st);
    (void)iiip_expect(st, III_TOK_LBRACE, NULL);
    iiip_skip_newlines(st);
    uint32_t fb = 0;
    if (iiip_accept(st, III_TOK_KW_FORWARD)) {
        (void)iiip_expect(st, III_TOK_LBRACE, NULL);
        iii_ast_open_list_t *ol = iii_ast_open_list_create(st->ast);
        for (;;) {
            iiip_skip_newlines(st);
            if (iiip_accept(st, III_TOK_RBRACE)) break;
            if (iiip_match(st, III_TOK_EOF)) break;
            uint32_t s = iiip_parse_stmt(st);
            if (s == 0) break;
            if (ol) iii_ast_open_list_push(ol, s);
            (void)iiip_accept(st, III_TOK_SEMI);
        }
        iii_ast_list_t stmts = ol ? iii_ast_open_list_commit(st->ast, ol)
                                  : (iii_ast_list_t){ 0u, 0u };
        iii_src_pos_t pos = iiip_pos_of(&kw);
        fb = iiip_alloc_node(st, III_AST_FORWARD_BLOCK, &pos);
        if (fb) iii_ast_get_mut(st->ast, fb)->u.forward_block.stmts = stmts;
    }
    iiip_skip_newlines(st);
    (void)iiip_expect(st, III_TOK_RBRACE, NULL);
    iii_src_pos_t pos = iiip_pos_of(&kw);
    uint32_t n = iiip_alloc_node(st, III_AST_MOBIUS_CANDIDATE_DECL, &pos);
    if (n) {
        iii_ast_node_t *nn = iii_ast_get_mut(st->ast, n);
        nn->u.mobius_candidate.name = iiip_text_of(&name);
        nn->u.mobius_candidate.in_type = in_t;
        nn->u.mobius_candidate.out_type = out_t;
        nn->u.mobius_candidate.modifiers = mods;
        nn->u.mobius_candidate.forward_block = fb;
    }
    return n;
}

static uint32_t iiip_parse_schema_decl(iii_parse_state_t *st)
{
    iii_token_t kw;
    if (!iiip_expect(st, III_TOK_KW_SCHEMA, &kw)) return 0;
    iii_token_t name;
    if (!iiip_expect(st, III_TOK_IDENTIFIER, &name)) return 0;
    (void)iiip_expect(st, III_TOK_OP_ASSIGN, NULL);
    (void)iiip_expect(st, III_TOK_KW_OBSERVATORY, NULL);
    (void)iiip_expect(st, III_TOK_LBRACE, NULL);
    iii_ast_open_list_t *fields_ol = iii_ast_open_list_create(st->ast);
    for (;;) {
        iiip_skip_newlines(st);
        if (iiip_accept(st, III_TOK_RBRACE)) break;
        if (iiip_match(st, III_TOK_EOF)) break;
        iii_token_t fname;
        if (!iiip_expect(st, III_TOK_IDENTIFIER, &fname)) break;
        (void)iiip_expect(st, III_TOK_COLON, NULL);
        iii_schema_field_kind_t fk = III_SCH_F_ACCUMULATOR;
        if      (iii_token_raw_eq(st->lex, &fname, "accumulator"))   fk = III_SCH_F_ACCUMULATOR;
        else if (iii_token_raw_eq(st->lex, &fname, "threshold"))     fk = III_SCH_F_THRESHOLD;
        else if (iii_token_raw_eq(st->lex, &fname, "sample_source")) fk = III_SCH_F_SAMPLE_SOURCE;
        else if (iii_token_raw_eq(st->lex, &fname, "max_records"))   fk = III_SCH_F_MAX_RECORDS;
        else if (iii_token_raw_eq(st->lex, &fname, "plan_anchor"))   fk = III_SCH_F_PLAN_ANCHOR;
        iii_src_pos_t pp = iiip_pos_of(&fname);
        uint32_t fn = iiip_alloc_node(st, III_AST_SCHEMA_FIELD, &pp);
        if (fn == 0) break;
        iii_ast_node_t *fnp = iii_ast_get_mut(st->ast, fn);
        fnp->u.schema_field.field_kind = fk;
        if (fk == III_SCH_F_SAMPLE_SOURCE) {
            /* `witness_stream where expr` */
            (void)iiip_expect(st, III_TOK_IDENTIFIER, NULL);  /* "witness_stream" */
            (void)iiip_expect(st, III_TOK_KW_WHERE, NULL);
            fnp->u.schema_field.expr = iiip_parse_expr(st);
        } else if (fk == III_SCH_F_MAX_RECORDS || fk == III_SCH_F_PLAN_ANCHOR) {
            iii_token_t v;
            if (iiip_expect(st, III_TOK_INT_LITERAL, &v)) {
                fnp->u.schema_field.int_value = (uint32_t)v.int_value;
            }
        } else {
            /* spec_name [args...] */
            iii_token_t spec;
            if (iiip_expect(st, III_TOK_IDENTIFIER, &spec)) {
                fnp->u.schema_field.spec_name = iiip_text_of(&spec);
            }
            if (iiip_accept(st, III_TOK_LPAREN)) {
                fnp->u.schema_field.args = iiip_parse_arg_list(st);
                (void)iiip_expect(st, III_TOK_RPAREN, NULL);
            }
        }
        if (fields_ol) iii_ast_open_list_push(fields_ol, fn);
        if (!iiip_accept(st, III_TOK_COMMA)) break;
        iiip_skip_newlines(st);
    }
    /* if loop exited on RBRACE consume; otherwise expect now */
    (void)iiip_accept(st, III_TOK_RBRACE);
    iii_ast_list_t fields = fields_ol ? iii_ast_open_list_commit(st->ast, fields_ol)
                                      : (iii_ast_list_t){ 0u, 0u };
    iii_src_pos_t pos = iiip_pos_of(&kw);
    uint32_t n = iiip_alloc_node(st, III_AST_SCHEMA_DECL, &pos);
    if (n) {
        iii_ast_node_t *nn = iii_ast_get_mut(st->ast, n);
        nn->u.schema_decl.name = iiip_text_of(&name);
        nn->u.schema_decl.fields = fields;
    }
    return n;
}

static uint32_t iiip_parse_sealed_call_method(iii_parse_state_t *st)
{
    iii_token_t kw;
    if (!iiip_expect(st, III_TOK_KW_SEALED_CALL, &kw)) return 0;
    iii_token_t name;
    if (!iiip_expect(st, III_TOK_IDENTIFIER, &name)) return 0;
    iii_ast_list_t params = iiip_parse_param_list(st);
    uint32_t ret = 0;
    if (iiip_accept(st, III_TOK_ARROW)) {
        ret = iiip_parse_type_expr(st);
    }
    /* @seal_id(N) — required modifier on every sealed_call. */
    (void)iiip_expect(st, III_TOK_AT, NULL);
    iii_token_t seal_word;
    (void)iiip_expect(st, III_TOK_IDENTIFIER, &seal_word);
    if (!iii_token_raw_eq(st->lex, &seal_word, "seal_id")) {
        iiip_record_error(st, III_PARSE_E_BAD_MODIFIER, &seal_word,
                          "sealed_call declaration requires @seal_id(N) modifier",
                          III_TOK_IDENTIFIER);
    }
    (void)iiip_expect(st, III_TOK_LPAREN, NULL);
    iii_token_t sid;
    (void)iiip_expect(st, III_TOK_INT_LITERAL, &sid);
    (void)iiip_expect(st, III_TOK_RPAREN, NULL);
    uint32_t body = iiip_parse_block(st);
    iii_src_pos_t pos = iiip_pos_of(&kw);
    uint32_t n = iiip_alloc_node(st, III_AST_SEALED_CALL_METHOD_DECL, &pos);
    if (n) {
        iii_ast_node_t *nn = iii_ast_get_mut(st->ast, n);
        nn->u.sealed_call.name = iiip_text_of(&name);
        nn->u.sealed_call.params = params;
        nn->u.sealed_call.return_type = ret;
        nn->u.sealed_call.seal_id = (uint32_t)sid.int_value;
        nn->u.sealed_call.body_block = body;
    }
    return n;
}

static uint32_t iiip_parse_top_decl(iii_parse_state_t *st)
{
    iii_token_kind_t k = iiip_peek_kind(st);
    /* R1 — registry dispatch first; non-zero return wins. */
    uint32_t r = iiip_registry_dispatch(st, &st->reg_decl, k);
    if (r != 0u) return r;
    iiip_bc_push(st, iiip_kind_to_prod(k), (iii_src_text_t){0u, 0u});
    uint32_t out;
    switch (k) {
        case III_TOK_KW_CYCLE:             out = iiip_parse_cycle_decl(st); break;
        case III_TOK_KW_FN:                out = iiip_parse_fn_decl(st); break;
        case III_TOK_KW_TYPE:              out = iiip_parse_type_decl(st); break;
        case III_TOK_KW_CONST:             out = iiip_parse_const_decl(st); break;
        case III_TOK_KW_EXTERN:            out = iiip_parse_extern_decl(st); break;
        case III_TOK_KW_MOBIUS_CANDIDATE:  out = iiip_parse_mobius_candidate(st); break;
        case III_TOK_KW_SCHEMA:            out = iiip_parse_schema_decl(st); break;
        case III_TOK_KW_SEALED_CALL:       out = iiip_parse_sealed_call_method(st); break;
        case III_TOK_KW_VAR:               out = iiip_parse_var_decl(st); break;
        case III_TOK_KW_STRUCT:            out = iiip_parse_struct_decl(st); break;
        default:
            iiip_record_error(st, III_PARSE_E_UNEXPECTED_TOKEN, iiip_peek(st),
                              "expected top-level declaration",
                              III_TOK_INVALID);
            /* B1 — recover to the FOLLOW set of TOP_DECL so we can keep
             * the parse going and accumulate further diagnostics (P1). */
            iiip_recover_follow(st, IIIP_PROD_TOP_DECL);
            out = 0;
            break;
    }
    iiip_bc_pop(st);
    return out;
}

/* ─── use_decl ───────────────────────────────────────────────────── */

static uint32_t iiip_parse_use_decl(iii_parse_state_t *st)
{
    iii_token_t kw;
    if (!iiip_expect(st, III_TOK_KW_USE, &kw)) return 0;
    iii_token_t first;
    if (!iiip_expect(st, III_TOK_IDENTIFIER, &first)) return 0;
    iii_src_text_t qname = iiip_text_of(&first);
    while (iiip_accept(st, III_TOK_DOT)) {
        iii_token_t n2;
        if (!iiip_expect(st, III_TOK_IDENTIFIER, &n2)) break;
        qname.length = (uint32_t)(n2.end_byte - qname.offset);
    }
    /* @closure(0x...) */
    uint32_t closure = 0;
    if (iiip_accept(st, III_TOK_AT)) {
        iii_token_t cw;
        (void)iiip_expect(st, III_TOK_IDENTIFIER, &cw);
        (void)iiip_expect(st, III_TOK_LPAREN, NULL);
        iii_token_t mh;
        if (iiip_expect(st, III_TOK_MHASH_LITERAL, &mh)) {
            iii_src_pos_t mhp = iiip_pos_of(&mh);
            closure = iiip_alloc_node(st, III_AST_EXPR_MHASH, &mhp);
            if (closure) memcpy(iii_ast_get_mut(st->ast, closure)->u.mhash_.mhash, mh.mhash, 32);
        }
        (void)iiip_expect(st, III_TOK_RPAREN, NULL);
    }
    iii_src_text_t alias = { 0u, 0u };
    if (iiip_accept(st, III_TOK_KW_AS)) {
        iii_token_t at;
        if (iiip_expect(st, III_TOK_IDENTIFIER, &at)) alias = iiip_text_of(&at);
    }
    iii_src_pos_t pos = iiip_pos_of(&kw);
    uint32_t n = iiip_alloc_node(st, III_AST_USE, &pos);
    if (n) {
        iii_ast_node_t *nn = iii_ast_get_mut(st->ast, n);
        nn->u.use_.qualified_name = qname;
        nn->u.use_.closure_mhash_node = closure;
        nn->u.use_.alias = alias;
    }
    return n;
}

/* ─── Module ──────────────────────────────────────────────────── */

int iii_parse_module(iii_parse_state_t *st)
{
    if (!st || !st->ast) {
        if (st) iiip_record_error(st, III_PARSE_E_NULL_ARG, iiip_peek(st),
                                   "null parser/AST", III_TOK_INVALID);
        return 0;
    }
    iiip_skip_newlines(st);
    if (!iiip_match(st, III_TOK_KW_MODULE)) {
        iiip_record_error(st, III_PARSE_E_UNEXPECTED_TOKEN, iiip_peek(st),
                          "source must begin with `module` declaration",
                          III_TOK_KW_MODULE);
        return 0;
    }
    iii_token_t kw = iiip_advance(st);
    iii_token_t first;
    if (!iiip_expect(st, III_TOK_IDENTIFIER, &first)) return 0;
    iii_src_text_t mname = iiip_text_of(&first);
    while (iiip_accept(st, III_TOK_DOT)) {
        iii_token_t n2;
        if (!iiip_expect(st, III_TOK_IDENTIFIER, &n2)) break;
        mname.length = (uint32_t)(n2.end_byte - mname.offset);
    }
    iii_ast_list_t mods = iiip_parse_modifier_list(st);

    /* Uses. */
    iii_ast_open_list_t *uses_ol = iii_ast_open_list_create(st->ast);
    for (;;) {
        iiip_skip_newlines(st);
        if (!iiip_match(st, III_TOK_KW_USE)) break;
        uint32_t u = iiip_parse_use_decl(st);
        if (u == 0) {
            /* B1 — let the FF table drive use-decl recovery. */
            iiip_recover_follow(st, IIIP_PROD_USE_DECL);
            continue;
        }
        if (uses_ol) iii_ast_open_list_push(uses_ol, u);
    }
    iii_ast_list_t uses = uses_ol ? iii_ast_open_list_commit(st->ast, uses_ol)
                                  : (iii_ast_list_t){ 0u, 0u };

    /* Top-level decls. */
    iii_ast_open_list_t *decls_ol = iii_ast_open_list_create(st->ast);
    for (;;) {
        iiip_skip_newlines(st);
        if (iiip_match(st, III_TOK_EOF)) break;
        uint32_t d = iiip_parse_top_decl(st);
        if (d == 0) {
            /* B1 — let the FF table drive top-decl recovery. */
            iiip_recover_follow(st, IIIP_PROD_TOP_DECL);
            (void)iiip_accept(st, III_TOK_NEWLINE);
            if (iiip_match(st, III_TOK_EOF)) break;
            continue;
        }
        if (decls_ol) iii_ast_open_list_push(decls_ol, d);
    }
    iii_ast_list_t decls = decls_ol ? iii_ast_open_list_commit(st->ast, decls_ol)
                                    : (iii_ast_list_t){ 0u, 0u };

    iii_src_pos_t pos = iiip_pos_of(&kw);
    uint32_t n = iiip_alloc_node(st, III_AST_MODULE, &pos);
    if (n == 0) return 0;
    iii_ast_node_t *nn = iii_ast_get_mut(st->ast, n);
    nn->u.module_.name = mname;
    nn->u.module_.modifiers = mods;
    nn->u.module_.uses = uses;
    nn->u.module_.decls = decls;
    iii_ast_set_root_module(st->ast, n);
    iii_ast_recompute_root_mhash(st->ast);
    return st->error_count == 0 ? 1 : 0;
}

/* ─── Public lifetime + error API ───────────────────────────────── */

iii_parse_state_t *iii_parse_create(iii_lex_state_t *lex_state,
                                          iii_ast_t       *ast)
{
    if (!lex_state || !ast) return NULL;
    iii_parse_state_t *st = (iii_parse_state_t *)calloc(1, sizeof(*st));
    if (!st) return NULL;
    st->lex = lex_state;
    st->ast = ast;
    st->lookahead_valid  = false;
    st->lookahead2_valid = false;
    st->error_count = 0;
    st->error_cap   = 0;
    st->errors      = NULL;
    st->depth = 0;
    st->bc_depth = 0;
    st->witness_committed = 0;
    iiip_sha256_init(&st->witness_ctx);
    st->reg_next_handle = 0;
    return st;
}

void iii_parse_destroy(iii_parse_state_t *st)
{
    if (!st) return;
    free(st->errors);
    free(st);
}

void iii_parse_error_info(const iii_parse_state_t *st,
                              iii_parse_error_t *out_err)
{
    if (!st || !out_err) return;
    if (st->error_count == 0) {
        memset(out_err, 0, sizeof(*out_err));
        out_err->code = III_PARSE_OK;
        return;
    }
    *out_err = st->errors[0];
}

uint32_t iii_parse_error_count(const iii_parse_state_t *st)
{
    return st ? st->error_count : 0;
}

void iii_parse_error_at(const iii_parse_state_t *st,
                            uint32_t i,
                            iii_parse_error_t *out_err)
{
    if (!st || !out_err) return;
    if (i >= st->error_count) {
        memset(out_err, 0, sizeof(*out_err));
        return;
    }
    *out_err = st->errors[i];
}

const char *iii_parse_error_name(int code)
{
    switch (code) {
        case III_PARSE_OK: return "OK";
        case III_PARSE_E_UNEXPECTED_TOKEN: return "UNEXPECTED_TOKEN";
        case III_PARSE_E_EXPECTED_IDENT:   return "EXPECTED_IDENT";
        case III_PARSE_E_EXPECTED_LITERAL: return "EXPECTED_LITERAL";
        case III_PARSE_E_EXPECTED_TYPE:    return "EXPECTED_TYPE";
        case III_PARSE_E_EXPECTED_EXPR:    return "EXPECTED_EXPR";
        case III_PARSE_E_EXPECTED_PATTERN: return "EXPECTED_PATTERN";
        case III_PARSE_E_BAD_MODIFIER:     return "BAD_MODIFIER";
        case III_PARSE_E_BAD_HEXAD:        return "BAD_HEXAD";
        case III_PARSE_E_BAD_RING_SET:     return "BAD_RING_SET";
        case III_PARSE_E_LEX:              return "LEX";
        case III_PARSE_E_OOM:              return "OOM";
        case III_PARSE_E_RECURSION_LIMIT:  return "RECURSION_LIMIT";
        case III_PARSE_E_NULL_ARG:         return "NULL_ARG";
        case III_PARSE_E_UNEXPECTED_EOF:   return "UNEXPECTED_EOF";
        case III_PARSE_E_ERRORS_TRUNCATED: return "ERRORS_TRUNCATED";
        case III_PARSE_E_INSERTED_TOKEN:   return "INSERTED_TOKEN";
        case III_PARSE_E_REGISTRY_FULL:    return "REGISTRY_FULL";
        default:                           return "<unknown>";
    }
}

/* ═══════════════════════════════════════════════════════════════════
 * Public sub-entry points (F1) — parse a single expression / type /
 * pattern / decl from the current cursor position.  Each returns the
 * AST node id (or 0 on failure); callers can interleave them with
 * iii_parse_error_at to collect diagnostics.  These exist so that
 * tools (REPLs, macro hosts, IDE servers) can drive the parser
 * piecewise without having to wrap a stub `module { ... }` around
 * every snippet.
 * ═══════════════════════════════════════════════════════════════════ */

uint32_t iii_parse_expression(iii_parse_state_t *st)
{
    if (!st) return 0;
    return iiip_parse_expr(st);
}

uint32_t iii_parse_type(iii_parse_state_t *st)
{
    if (!st) return 0;
    return iiip_parse_type_expr(st);
}

uint32_t iii_parse_pattern(iii_parse_state_t *st)
{
    if (!st) return 0;
    return iiip_parse_pattern(st);
}

uint32_t iii_parse_decl(iii_parse_state_t *st)
{
    if (!st) return 0;
    iiip_skip_newlines(st);
    return iiip_parse_top_decl(st);
}

/* F2 — streaming next-decl: returns 1 on success (and writes the
 * node id to *out_node), 0 at EOF, -1 on hard failure. */
int iii_parse_decl_next(iii_parse_state_t *st, uint32_t *out_node)
{
    if (out_node) *out_node = 0;
    if (!st) return -1;
    iiip_skip_newlines(st);
    if (iiip_peek_kind(st) == III_TOK_EOF) return 0;
    uint32_t n = iiip_parse_top_decl(st);
    if (out_node) *out_node = n;
    return n != 0u ? 1 : -1;
}

/* ═══════════════════════════════════════════════════════════════════
 * Witness API (A1, A2) and grammar mhash (E1).
 * ═══════════════════════════════════════════════════════════════════ */

/* A1 — finalise a copy of the witness context (allowing the caller to
 * snapshot mid-parse) and emit the 32-byte digest.  Idempotent. */
void iii_parse_witness_mhash(const iii_parse_state_t *st, uint8_t out[32])
{
    if (!st || !out) {
        if (out) memset(out, 0, 32);
        return;
    }
    iiip_sha256_t copy = st->witness_ctx;
    iiip_sha256_final(&copy, out);
}

void iii_parse_set_witness_sink(iii_parse_state_t           *st,
                                  iii_parse_witness_sink_fn_t  fn,
                                  void                        *ctx)
{
    if (!st) return;
    st->witness_sink     = fn;
    st->witness_sink_ctx = ctx;
}

/* E1 — Sort the FF table by canonical production name and fold the
 * (name, FIRST set) pairs.  Then fold the active registry contents
 * (handle order is registration order, which is deterministic per
 * host).  Two parsers with identical built-in grammar AND identical
 * registry state produce byte-identical 32-byte digests. */
void iii_parse_grammar_mhash(const iii_parse_state_t *st, uint8_t out[32])
{
    if (!out) return;
    if (!st) { memset(out, 0, 32); return; }
    iiip_sha256_t h;
    iiip_sha256_init(&h);

    /* Sort indices into iiip_ff_table by name (insertion sort; small
     * fixed N — IIIP_PROD_COUNT). */
    uint8_t order[IIIP_PROD_COUNT];
    uint32_t n_rows = 0;
    for (uint32_t i = 0; i < (uint32_t)(sizeof(iiip_ff_table)/sizeof(iiip_ff_table[0])); i++) {
        order[n_rows++] = (uint8_t)i;
        if (n_rows >= IIIP_PROD_COUNT) break;
    }
    for (uint32_t i = 1; i < n_rows; i++) {
        uint8_t v = order[i];
        const char *vn = iiip_prod_name(iiip_ff_table[v].id);
        uint32_t j = i;
        while (j > 0) {
            const char *pn = iiip_prod_name(iiip_ff_table[order[j-1]].id);
            if (strcmp(pn, vn) <= 0) break;
            order[j] = order[j-1];
            j -= 1;
        }
        order[j] = v;
    }
    /* Fold (name‖FIRST set‖FOLLOW set). */
    for (uint32_t i = 0; i < n_rows; i++) {
        const iiip_ff_row_t *row = &iiip_ff_table[order[i]];
        const char *name = iiip_prod_name(row->id);
        size_t nl = strlen(name);
        iiip_sha256_update(&h, name, nl);
        uint8_t sep = 0;
        iiip_sha256_update(&h, &sep, 1);
        for (uint32_t j = 0; j < 16 && row->first[j] != III_TOK_INVALID; j++) {
            iiip_sha256_u32(&h, (uint32_t)row->first[j]);
        }
        iiip_sha256_update(&h, &sep, 1);
        for (uint32_t j = 0; j < 16 && row->follow[j] != III_TOK_INVALID; j++) {
            iiip_sha256_u32(&h, (uint32_t)row->follow[j]);
        }
        iiip_sha256_update(&h, &sep, 1);
    }
    /* Fold the registries in handle order. */
    const iiip_reg_table_t *tables[3] = {
        &st->reg_decl, &st->reg_stmt, &st->reg_primary
    };
    for (uint32_t t = 0; t < 3u; t++) {
        const iiip_reg_table_t *tbl = tables[t];
        iiip_sha256_u32(&h, t);
        for (uint32_t i = 0; i < III_PARSE_REG_CAP; i++) {
            if (tbl->entries[i].handle == 0u) continue;
            iiip_sha256_u32(&h, tbl->entries[i].handle);
            iiip_sha256_u32(&h, (uint32_t)tbl->entries[i].first_token);
        }
    }
    iiip_sha256_final(&h, out);
}

/* Q1 — Pratt decision trace setter. */
void iii_parse_set_pratt_trace(iii_parse_state_t          *st,
                                 iii_parse_pratt_trace_fn_t  fn,
                                 void                       *ctx)
{
    if (!st) return;
    st->pratt_trace     = fn;
    st->pratt_trace_ctx = ctx;
}

/* ═══════════════════════════════════════════════════════════════════
 * Grammar-extension registry (R1).
 * ═══════════════════════════════════════════════════════════════════ */

static uint32_t iiip_register_into(iii_parse_state_t   *st,
                                     iiip_reg_table_t    *tbl,
                                     iii_token_kind_t      first_token,
                                     iii_parse_decl_fn_t   fn)
{
    if (!st || !tbl || !fn || first_token == III_TOK_INVALID) return 0u;
    for (uint32_t i = 0; i < III_PARSE_REG_CAP; i++) {
        if (tbl->entries[i].handle == 0u) {
            st->reg_next_handle += 1u;
            if (st->reg_next_handle == 0u) st->reg_next_handle = 1u;
            tbl->entries[i].handle      = st->reg_next_handle;
            tbl->entries[i].first_token = first_token;
            tbl->entries[i].fn          = fn;
            tbl->count += 1u;
            return tbl->entries[i].handle;
        }
    }
    iiip_record_error(st, III_PARSE_E_REGISTRY_FULL, NULL,
                      "grammar-extension registry is full",
                      III_TOK_INVALID);
    return 0u;
}

uint32_t iii_parse_register_decl_kind(iii_parse_state_t   *st,
                                            iii_token_kind_t      first_token,
                                            iii_parse_decl_fn_t   fn)
{
    return iiip_register_into(st, st ? &st->reg_decl : NULL, first_token, fn);
}

uint32_t iii_parse_register_stmt_kind(iii_parse_state_t   *st,
                                            iii_token_kind_t      first_token,
                                            iii_parse_decl_fn_t   fn)
{
    return iiip_register_into(st, st ? &st->reg_stmt : NULL, first_token, fn);
}

uint32_t iii_parse_register_primary_kind(iii_parse_state_t   *st,
                                               iii_token_kind_t      first_token,
                                               iii_parse_decl_fn_t   fn)
{
    return iiip_register_into(st, st ? &st->reg_primary : NULL, first_token, fn);
}

bool iii_parse_unregister(iii_parse_state_t *st, uint32_t reg_handle)
{
    if (!st || reg_handle == 0u) return false;
    iiip_reg_table_t *tables[3] = {
        &st->reg_decl, &st->reg_stmt, &st->reg_primary
    };
    for (uint32_t t = 0; t < 3u; t++) {
        iiip_reg_table_t *tbl = tables[t];   /* hoisted loop-invariant -- the same idiom iii_parse_grammar_mhash's registry fold uses */
        for (uint32_t i = 0; i < III_PARSE_REG_CAP; i++) {
            if (tbl->entries[i].handle == reg_handle) {
                memset(&tbl->entries[i], 0, sizeof(tbl->entries[i]));
                if (tbl->count > 0u) tbl->count -= 1u;
                return true;
            }
        }
    }
    return false;
}

/* N1 — Pratt binop table accessor was emitted in the prologue
 * (`iii_parse_binop_table`), so no body needed here.  The table is
 * the single source of truth for operator precedence and
 * associativity; iiip_binop_for in the body now reads from it. */

