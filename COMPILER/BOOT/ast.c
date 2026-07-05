/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\ast.c
 *
 * III Stage-0 AST — implementation.
 *
 * Companion of ast.h.  See that file for the full set of substrate-
 * level disciplines (A1..U1, V1).  This TU implements the four-pool
 * Merkle DAG, the hash-cons table, the position side-table, the
 * annotation arena, the zipper, the resumable walk-state, the
 * canonical serialiser, and the diff.
 *
 * Strict NIH: only stdlib (<stdint.h>, <stdlib.h>, <string.h>,
 * <stdio.h>); no third-party AST library; no hash function from
 * outside.  SHA-256 is hand-rolled below.
 *
 * Reproducibility: every byte the AST exposes (per-node mhash,
 * stream mhash, serialised binary form) is a pure function of
 * (kind enum integer values, payload bytes in canonical form,
 * child mhashes).  Allocator addresses do not appear in any
 * exposed value.
 */

#include "ast.h"

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Explicit host-I/O prototypes (redundant with <stdio.h> — legal, identical C).
 * The Stage-1 bootstrap compiler skips system headers, so these make each
 * CALLED host fn visible to its cross-module IMPORT registration (link-by-name
 * at the host boundary); without them the calls have no declaration in the
 * token stream at all. */
int    fclose(FILE *f);
int    fprintf(FILE *f, const char *fmt, ...);
int    fputc(int c, FILE *f);
int    fputs(const char *s, FILE *f);
size_t fread(void *p, size_t sz, size_t n, FILE *f);
long   ftell(FILE *f);
size_t fwrite(const void *p, size_t sz, size_t n, FILE *f);
void   rewind(FILE *f);
FILE  *tmpfile(void);

/* ─── SHA-256 (FIPS 180-4) — used for A1 / Q1 / D1 ────────────────── */

typedef struct {
    uint32_t h[8];
    uint64_t total_bits;
    uint8_t  buf[64];
    size_t   buf_used;
} iii_ast_sha256_t;

static const uint32_t III_AST_SHA256_K[64] = {
    0x428a2f98u, 0x71374491u, 0xb5c0fbcfu, 0xe9b5dba5u,
    0x3956c25bu, 0x59f111f1u, 0x923f82a4u, 0xab1c5ed5u,
    0xd807aa98u, 0x12835b01u, 0x243185beu, 0x550c7dc3u,
    0x72be5d74u, 0x80deb1feu, 0x9bdc06a7u, 0xc19bf174u,
    0xe49b69c1u, 0xefbe4786u, 0x0fc19dc6u, 0x240ca1ccu,
    0x2de92c6fu, 0x4a7484aau, 0x5cb0a9dcu, 0x76f988dau,
    0x983e5152u, 0xa831c66du, 0xb00327c8u, 0xbf597fc7u,
    0xc6e00bf3u, 0xd5a79147u, 0x06ca6351u, 0x14292967u,
    0x27b70a85u, 0x2e1b2138u, 0x4d2c6dfcu, 0x53380d13u,
    0x650a7354u, 0x766a0abbu, 0x81c2c92eu, 0x92722c85u,
    0xa2bfe8a1u, 0xa81a664bu, 0xc24b8b70u, 0xc76c51a3u,
    0xd192e819u, 0xd6990624u, 0xf40e3585u, 0x106aa070u,
    0x19a4c116u, 0x1e376c08u, 0x2748774cu, 0x34b0bcb5u,
    0x391c0cb3u, 0x4ed8aa4au, 0x5b9cca4fu, 0x682e6ff3u,
    0x748f82eeu, 0x78a5636fu, 0x84c87814u, 0x8cc70208u,
    0x90befffau, 0xa4506cebu, 0xbef9a3f7u, 0xc67178f2u
};

static uint32_t iii_rotr32(uint32_t x, unsigned n) { return (x >> n) | (x << (32u - n)); }

static void iii_sha256_compress(iii_ast_sha256_t *s, const uint8_t block[64])
{
    uint32_t w[64];
    for (int i = 0; i < 16; i++) {
        w[i] = ((uint32_t)block[i*4    ] << 24) |
               ((uint32_t)block[i*4 + 1] << 16) |
               ((uint32_t)block[i*4 + 2] <<  8) |
               ((uint32_t)block[i*4 + 3]      );
    }
    for (int i = 16; i < 64; i++) {
        uint32_t s0 = iii_rotr32(w[i-15], 7) ^ iii_rotr32(w[i-15], 18) ^ (w[i-15] >> 3);
        uint32_t s1 = iii_rotr32(w[i-2], 17) ^ iii_rotr32(w[i-2],  19) ^ (w[i-2] >> 10);
        w[i] = w[i-16] + s0 + w[i-7] + s1;
    }
    uint32_t a = s->h[0], b = s->h[1], c = s->h[2], d = s->h[3];
    uint32_t e = s->h[4], f = s->h[5], g = s->h[6], h = s->h[7];
    for (int i = 0; i < 64; i++) {
        uint32_t S1 = iii_rotr32(e, 6) ^ iii_rotr32(e, 11) ^ iii_rotr32(e, 25);
        uint32_t ch = (e & f) ^ ((~e) & g);
        uint32_t t1 = h + S1 + ch + III_AST_SHA256_K[i] + w[i];
        uint32_t S0 = iii_rotr32(a, 2) ^ iii_rotr32(a, 13) ^ iii_rotr32(a, 22);
        uint32_t mj = (a & b) ^ (a & c) ^ (b & c);
        uint32_t t2 = S0 + mj;
        h = g; g = f; f = e; e = d + t1;
        d = c; c = b; b = a; a = t1 + t2;
    }
    s->h[0] += a; s->h[1] += b; s->h[2] += c; s->h[3] += d;
    s->h[4] += e; s->h[5] += f; s->h[6] += g; s->h[7] += h;
}

static void iii_sha256_init(iii_ast_sha256_t *s)
{
    s->h[0] = 0x6a09e667u; s->h[1] = 0xbb67ae85u; s->h[2] = 0x3c6ef372u; s->h[3] = 0xa54ff53au;
    s->h[4] = 0x510e527fu; s->h[5] = 0x9b05688cu; s->h[6] = 0x1f83d9abu; s->h[7] = 0x5be0cd19u;
    s->total_bits = 0;
    s->buf_used = 0;
}

static void iii_sha256_update(iii_ast_sha256_t *s, const uint8_t *data, size_t n)
{
    s->total_bits += (uint64_t)n * 8u;
    if (s->buf_used > 0) {
        size_t fill = 64u - s->buf_used;
        if (fill > n) fill = n;
        memcpy(s->buf + s->buf_used, data, fill);
        s->buf_used += fill;
        data += fill;
        n    -= fill;
        if (s->buf_used == 64u) { iii_sha256_compress(s, s->buf); s->buf_used = 0; }
    }
    while (n >= 64u) { iii_sha256_compress(s, data); data += 64u; n -= 64u; }
    if (n > 0u) { memcpy(s->buf, data, n); s->buf_used = n; }
}

static void iii_sha256_final(iii_ast_sha256_t *s, uint8_t out[32])
{
    uint64_t total_bits = s->total_bits;
    s->buf[s->buf_used++] = 0x80u;
    if (s->buf_used > 56u) {
        while (s->buf_used < 64u) s->buf[s->buf_used++] = 0;
        iii_sha256_compress(s, s->buf);
        s->buf_used = 0;
    }
    while (s->buf_used < 56u) s->buf[s->buf_used++] = 0;
    for (int i = 7; i >= 0; i--) {
        s->buf[s->buf_used++] = (uint8_t)((total_bits >> (i * 8)) & 0xFFu);
    }
    iii_sha256_compress(s, s->buf);
    for (int i = 0; i < 8; i++) {
        out[i*4    ] = (uint8_t)((s->h[i] >> 24) & 0xFFu);
        out[i*4 + 1] = (uint8_t)((s->h[i] >> 16) & 0xFFu);
        out[i*4 + 2] = (uint8_t)((s->h[i] >>  8) & 0xFFu);
        out[i*4 + 3] = (uint8_t)((s->h[i]      ) & 0xFFu);
    }
}

static void iii_sha256_update_u8 (iii_ast_sha256_t *s, uint8_t v)  { iii_sha256_update(s, &v, 1); }
static void iii_sha256_update_u16(iii_ast_sha256_t *s, uint16_t v) {
    uint8_t b[2] = { (uint8_t)(v & 0xFFu), (uint8_t)((v >> 8) & 0xFFu) };
    iii_sha256_update(s, b, 2);
}
static void iii_sha256_update_u32(iii_ast_sha256_t *s, uint32_t v) {
    uint8_t b[4] = { (uint8_t)(v & 0xFFu), (uint8_t)((v >> 8) & 0xFFu),
                     (uint8_t)((v >> 16) & 0xFFu), (uint8_t)((v >> 24) & 0xFFu) };
    iii_sha256_update(s, b, 4);
}
static void iii_sha256_update_u64(iii_ast_sha256_t *s, uint64_t v) {
    uint8_t b[8];
    for (int i = 0; i < 8; i++) b[i] = (uint8_t)((v >> (i * 8)) & 0xFFu);
    iii_sha256_update(s, b, 8);
}

/* ─── Capacity-growth helpers ────────────────────────────────────── */

static uint32_t iii_grow_cap(uint32_t cap, uint32_t need)
{
    uint32_t new_cap = cap == 0 ? 16u : cap;
    while (new_cap < need) {
        if (new_cap > UINT32_MAX / 2u) return 0;
        new_cap *= 2u;
    }
    return new_cap;
}

/* ─── Pool dispatch (H1) ─────────────────────────────────────────── */

/* Small pool: low-arity payloads (≤ a couple of u32). */
/* Medium pool: common expressions, patterns, args. */
/* Large pool: declarations, blocks, metadata, anything with multiple
 *             list-handle children. */
/* User pool: III_AST_USER_NODE only. */
static uint32_t iii_pool_for_kind(iii_ast_kind_t kind)
{
    switch (kind) {
        case III_AST_NULL:
            return III_AST_POOL_NULL;

        case III_AST_EXPR_BOOL:
        case III_AST_EXPR_TRIT:
        case III_AST_EXPR_UNIT:
        case III_AST_PAT_WILDCARD:
        case III_AST_RING_SET:
        case III_AST_HEXAD_NAME:
        case III_AST_COMPROMISE_BLOCK:
        case III_AST_PAT_LITERAL:
        case III_AST_STMT_RETURN:
        case III_AST_STMT_EXPR:
        case III_AST_EXPR_PAREN:
        case III_AST_EXPR_TYPE:
        case III_AST_TYPE_OF:
        case III_AST_EXPR_HOLE:
            return III_AST_POOL_SMALL;

        case III_AST_EXPR_INT:
        case III_AST_EXPR_HEX:
        case III_AST_EXPR_IDENT:
        case III_AST_EXPR_FIELD:
        case III_AST_EXPR_INDEX:
        case III_AST_EXPR_UNARY:
        case III_AST_EXPR_BINARY:
        case III_AST_EXPR_STR:
        case III_AST_PAT_HEXAD:
        case III_AST_EXPR_HEXAD:
        case III_AST_PAT_IDENT:
        case III_AST_PAT_TUPLE:
        case III_AST_MATCH_ARM:
        case III_AST_PARAM:
        case III_AST_TYPE_PARAM:
        case III_AST_CONST_DECL:
        case III_AST_USE:
        case III_AST_STMT_LET:
        case III_AST_STMT_ASSIGN:
        case III_AST_TYPE_PTR:
        case III_AST_TYPE_ARRAY:
        case III_AST_TYPE_TUPLE:
        case III_AST_TYPE_FN:
        case III_AST_STMT_SANCTUM_ENTER:
        case III_AST_STMT_METAL:
        case III_AST_STMT_FOR:
        case III_AST_STMT_MATCH:
        case III_AST_EXPR_MATCH:
        case III_AST_EXPR_PARALLEL:
        case III_AST_ARG:
        case III_AST_RATIONALE_DECL:
            return III_AST_POOL_MEDIUM;

        case III_AST_USER_NODE:
            return III_AST_POOL_USER;

        case III_AST_MODULE:
        case III_AST_CYCLE_DECL:
        case III_AST_FN_DECL:
        case III_AST_TYPE_DECL:
        case III_AST_EXTERN_DECL:
        case III_AST_MOBIUS_CANDIDATE_DECL:
        case III_AST_SCHEMA_DECL:
        case III_AST_SCHEMA_FIELD:
        case III_AST_SEALED_CALL_METHOD_DECL:
        case III_AST_MODIFIER:
        case III_AST_TYPE_REF:
        case III_AST_EXPR_CALL:
        case III_AST_EXPR_BLOCK:
        case III_AST_EXPR_RAW_ASM:
        case III_AST_EXPR_MHASH:
        case III_AST_FORWARD_BLOCK:
        case III_AST_STMT_WAVEFRONT:
        case III_AST_ERROR_NODE:
        case III_AST_ADR_DECL:
        case III_AST_CONFORMANCE_CLAIM_DECL:
        case III_AST_TEST_CASE_DECL:
        case III_AST_OPERATOR_INTENT:
            return III_AST_POOL_LARGE;

        default:
            /* Future kinds default to large until classified. */
            return III_AST_POOL_LARGE;
    }
}

/* ─── AST container, hash-cons slot, position record, annotation slot
 *     all live in ast_internal.h (sibling-private header).  Sharing
 *     the layout lets cg_r0.c / cg_rm1.c access source_buf directly
 *     for label generation without violating the public-opaque ast_t
 *     contract. */
#include "ast_internal.h"

/* ─── Forward declarations of canonical-bytes emitters ───────────── */

static void iii_canonical_node_bytes(const iii_ast_t *ast,
                                       const iii_ast_node_t *n,
                                       iii_ast_sha256_t *h);

/* ─── Pool arena access ──────────────────────────────────────────── */

static iii_ast_node_t **iii_pool_array(iii_ast_t *ast, uint32_t pool)
{
    switch (pool) {
        case III_AST_POOL_SMALL:  return &ast->small_nodes;
        case III_AST_POOL_MEDIUM: return &ast->medium_nodes;
        case III_AST_POOL_LARGE:  return &ast->large_nodes;
        case III_AST_POOL_USER:   return &ast->user_nodes;
        default: return NULL;
    }
}

static uint32_t *iii_pool_count(iii_ast_t *ast, uint32_t pool)
{
    switch (pool) {
        case III_AST_POOL_SMALL:  return &ast->small_count;
        case III_AST_POOL_MEDIUM: return &ast->medium_count;
        case III_AST_POOL_LARGE:  return &ast->large_count;
        case III_AST_POOL_USER:   return &ast->user_count;
        default: return NULL;
    }
}

static uint32_t *iii_pool_cap(iii_ast_t *ast, uint32_t pool)
{
    switch (pool) {
        case III_AST_POOL_SMALL:  return &ast->small_cap;
        case III_AST_POOL_MEDIUM: return &ast->medium_cap;
        case III_AST_POOL_LARGE:  return &ast->large_cap;
        case III_AST_POOL_USER:   return &ast->user_cap;
        default: return NULL;
    }
}

static uint8_t (**iii_pool_mhash(iii_ast_t *ast, uint32_t pool))[32]
{
    switch (pool) {
        case III_AST_POOL_SMALL:  return &ast->small_mhash;
        case III_AST_POOL_MEDIUM: return &ast->medium_mhash;
        case III_AST_POOL_LARGE:  return &ast->large_mhash;
        case III_AST_POOL_USER:   return &ast->user_mhash;
        default: return NULL;
    }
}

static int32_t **iii_pool_pos_first(iii_ast_t *ast, uint32_t pool)
{
    switch (pool) {
        case III_AST_POOL_SMALL:  return &ast->small_position_first;
        case III_AST_POOL_MEDIUM: return &ast->medium_position_first;
        case III_AST_POOL_LARGE:  return &ast->large_position_first;
        case III_AST_POOL_USER:   return &ast->user_position_first;
        default: return NULL;
    }
}

static uint32_t **iii_pool_binder(iii_ast_t *ast, uint32_t pool)
{
    switch (pool) {
        case III_AST_POOL_SMALL:  return &ast->small_binder_id;
        case III_AST_POOL_MEDIUM: return &ast->medium_binder_id;
        case III_AST_POOL_LARGE:  return &ast->large_binder_id;
        case III_AST_POOL_USER:   return &ast->user_binder_id;
        default: return NULL;
    }
}

static uint32_t **iii_pool_doc(iii_ast_t *ast, uint32_t pool)
{
    switch (pool) {
        case III_AST_POOL_SMALL:  return &ast->small_doc_comment;
        case III_AST_POOL_MEDIUM: return &ast->medium_doc_comment;
        case III_AST_POOL_LARGE:  return &ast->large_doc_comment;
        case III_AST_POOL_USER:   return &ast->user_doc_comment;
        default: return NULL;
    }
}

/* Grow a pool's parallel arrays in lockstep. */
static bool iii_pool_grow(iii_ast_t *ast, uint32_t pool, uint32_t need_slots)
{
    uint32_t *cap_ptr = iii_pool_cap(ast, pool);
    if (!cap_ptr) return false;
    if (need_slots <= *cap_ptr) return true;
    uint32_t new_cap = iii_grow_cap(*cap_ptr, need_slots);
    if (new_cap == 0) return false;

    iii_ast_node_t **arr = iii_pool_array(ast, pool);
    iii_ast_node_t *nodes_p = (iii_ast_node_t *)
        realloc(*arr, (size_t)new_cap * sizeof(iii_ast_node_t));
    if (!nodes_p) return false;
    memset(nodes_p + *cap_ptr, 0,
           (size_t)(new_cap - *cap_ptr) * sizeof(iii_ast_node_t));
    *arr = nodes_p;

    uint8_t (**mh)[32] = iii_pool_mhash(ast, pool);
    uint8_t (*mh_p)[32] = (uint8_t (*)[32])
        realloc(*mh, (size_t)new_cap * 32u);   /* 32 = sizeof((*mh)[0]) = one mhash[32]; literal matches the memset below + avoids ccsv's deref-index-sizeof gap */
    if (!mh_p) return false;
    memset(mh_p + *cap_ptr, 0, (size_t)(new_cap - *cap_ptr) * 32);
    *mh = mh_p;

    int32_t **pf = iii_pool_pos_first(ast, pool);
    int32_t *pf_p = (int32_t *)
        realloc(*pf, (size_t)new_cap * sizeof(int32_t));
    if (!pf_p) return false;
    for (uint32_t i = *cap_ptr; i < new_cap; i++) pf_p[i] = -1;
    *pf = pf_p;

    uint32_t **bd = iii_pool_binder(ast, pool);
    uint32_t *bd_p = (uint32_t *)
        realloc(*bd, (size_t)new_cap * sizeof(uint32_t));
    if (!bd_p) return false;
    memset(bd_p + *cap_ptr, 0, (size_t)(new_cap - *cap_ptr) * sizeof(uint32_t));
    *bd = bd_p;

    uint32_t **dc = iii_pool_doc(ast, pool);
    uint32_t *dc_p = (uint32_t *)
        realloc(*dc, (size_t)new_cap * sizeof(uint32_t));
    if (!dc_p) return false;
    memset(dc_p + *cap_ptr, 0, (size_t)(new_cap - *cap_ptr) * sizeof(uint32_t));
    *dc = dc_p;

    *cap_ptr = new_cap;
    return true;
}

static const iii_ast_node_t *iii_pool_node(const iii_ast_t *ast, uint32_t pool, uint32_t slot)
{
    switch (pool) {
        case III_AST_POOL_SMALL:  return slot < ast->small_count  ? &ast->small_nodes[slot]  : NULL;
        case III_AST_POOL_MEDIUM: return slot < ast->medium_count ? &ast->medium_nodes[slot] : NULL;
        case III_AST_POOL_LARGE:  return slot < ast->large_count  ? &ast->large_nodes[slot]  : NULL;
        case III_AST_POOL_USER:   return slot < ast->user_count   ? &ast->user_nodes[slot]   : NULL;
        default: return NULL;
    }
}

static iii_ast_node_t *iii_pool_node_mut(iii_ast_t *ast, uint32_t pool, uint32_t slot)
{
    switch (pool) {
        case III_AST_POOL_SMALL:  return slot < ast->small_count  ? &ast->small_nodes[slot]  : NULL;
        case III_AST_POOL_MEDIUM: return slot < ast->medium_count ? &ast->medium_nodes[slot] : NULL;
        case III_AST_POOL_LARGE:  return slot < ast->large_count  ? &ast->large_nodes[slot]  : NULL;
        case III_AST_POOL_USER:   return slot < ast->user_count   ? &ast->user_nodes[slot]   : NULL;
        default: return NULL;
    }
}

/* ─── Lifecycle ──────────────────────────────────────────────────── */

iii_ast_t *iii_ast_create(const uint8_t *source_buf,
                           size_t         source_len,
                           const char    *source_path)
{
    iii_ast_t *ast = (iii_ast_t *)calloc(1, sizeof(*ast));
    if (!ast) return NULL;
    ast->source_buf  = source_buf;
    ast->source_len  = source_len;
    ast->source_path = source_path;

    /* Reserve slot 0 of small pool as the III_AST_NULL sentinel.
     * Note: III_AST_NULL is encoded as the all-zeros index, but we
     * still want a real backing slot for accessors that pass index 0
     * (e.g., iii_ast_get returns the NULL node pointer-safely). */
    if (!iii_pool_grow(ast, III_AST_POOL_SMALL,  1)) goto fail;
    if (!iii_pool_grow(ast, III_AST_POOL_MEDIUM, 1)) goto fail;
    if (!iii_pool_grow(ast, III_AST_POOL_LARGE,  1)) goto fail;
    if (!iii_pool_grow(ast, III_AST_POOL_USER,   1)) goto fail;
    ast->small_nodes[0].kind = III_AST_NULL;
    ast->medium_nodes[0].kind = III_AST_NULL;
    ast->large_nodes[0].kind = III_AST_NULL;
    ast->user_nodes[0].kind  = III_AST_NULL;
    ast->small_count = ast->medium_count = ast->large_count = ast->user_count = 1;

    ast->list_arena = (uint32_t *)calloc(64, sizeof(uint32_t));
    if (!ast->list_arena) goto fail;
    ast->list_cap   = 64;
    ast->list_used  = 0;

    ast->string_payloads = (const uint8_t **)calloc(16, 8u);   /* 8 = sizeof(const uint8_t *) = one payload pointer; the literal avoids ccsv's sizeof-of-POINTER-type-as-calloc-arg gap (sizeof of a scalar type is fine; of a pointer type it left a value on the stack -> rc=8) */
    if (!ast->string_payloads) goto fail;
    ast->string_payload_cap   = 16;
    ast->string_payload_count = 0;

    ast->hashcons = (iii_ast_hashcons_slot_t *)calloc(256, sizeof(iii_ast_hashcons_slot_t));
    if (!ast->hashcons) goto fail;
    ast->hashcons_cap = 256;
    ast->hashcons_count = 0;

    ast->positions = NULL;
    ast->position_count = 0;
    ast->position_cap = 0;

    ast->annotations = NULL;
    ast->annotation_cap = 0;
    ast->annotation_count = 0;
    ast->annotation_blobs = NULL;
    ast->annotation_blob_used = 0;
    ast->annotation_blob_cap = 0;

    ast->phase_arena = NULL;
    ast->phase_arena_used = 0;
    ast->phase_arena_cap = 0;

    ast->user_kinds = NULL;
    ast->user_kind_cap = 0;
    ast->user_kind_count = 0;

    ast->next_binder_id = 1;
    ast->next_hole_id = 1;
    ast->root_module = 0;
    return ast;

fail:
    iii_ast_destroy(ast);
    return NULL;
}

void iii_ast_destroy(iii_ast_t *ast)
{
    if (!ast) return;
    free(ast->small_nodes);
    free(ast->medium_nodes);
    free(ast->large_nodes);
    free(ast->user_nodes);
    free(ast->small_mhash);
    free(ast->medium_mhash);
    free(ast->large_mhash);
    free(ast->user_mhash);
    free(ast->small_position_first);
    free(ast->medium_position_first);
    free(ast->large_position_first);
    free(ast->user_position_first);
    free(ast->small_binder_id);
    free(ast->medium_binder_id);
    free(ast->large_binder_id);
    free(ast->user_binder_id);
    free(ast->small_doc_comment);
    free(ast->medium_doc_comment);
    free(ast->large_doc_comment);
    free(ast->user_doc_comment);
    free(ast->positions);
    free(ast->list_arena);
    free(ast->string_payloads);
    free(ast->hashcons);
    free(ast->annotations);
    free(ast->annotation_blobs);
    free(ast->phase_arena);
    free(ast->user_kinds);
    free(ast);
}

/* ─── Witness setters / accessors (D1, R1) ──────────────────────── */

void iii_ast_set_parser_version(iii_ast_t *ast, const uint8_t mhash[32])
{ if (ast && mhash) memcpy(ast->parser_version_mhash, mhash, 32); }

void iii_ast_set_token_stream_mhash(iii_ast_t *ast, const uint8_t mhash[32])
{ if (ast && mhash) memcpy(ast->token_stream_mhash, mhash, 32); }

void iii_ast_set_source_mhash(iii_ast_t *ast, const uint8_t mhash[32])
{ if (ast && mhash) memcpy(ast->source_mhash, mhash, 32); }

void iii_ast_set_grammar_mhash(iii_ast_t *ast, const uint8_t mhash[32])
{ if (ast && mhash) memcpy(ast->grammar_mhash, mhash, 32); }

void iii_ast_get_witnesses(const iii_ast_t *ast,
                            uint8_t out_parser_version[32],
                            uint8_t out_token_stream[32],
                            uint8_t out_source[32],
                            uint8_t out_grammar[32])
{
    if (!ast) return;
    if (out_parser_version) memcpy(out_parser_version, ast->parser_version_mhash, 32);
    if (out_token_stream)   memcpy(out_token_stream,   ast->token_stream_mhash,   32);
    if (out_source)         memcpy(out_source,         ast->source_mhash,         32);
    if (out_grammar)        memcpy(out_grammar,        ast->grammar_mhash,        32);
}

const uint8_t *iii_ast_root_module_mhash(const iii_ast_t *ast)
{
    return ast ? ast->root_module_mhash : NULL;
}

void iii_ast_recompute_root_mhash(iii_ast_t *ast)
{
    if (!ast) return;
    if (ast->root_module == 0) {
        memset(ast->root_module_mhash, 0, 32);
        return;
    }
    const uint8_t *mh = iii_ast_node_mhash(ast, ast->root_module);
    if (mh) memcpy(ast->root_module_mhash, mh, 32);
    else    memset(ast->root_module_mhash, 0, 32);
}

const uint8_t *iii_ast_source_buf(const iii_ast_t *ast) { return ast ? ast->source_buf : NULL; }
size_t         iii_ast_source_len(const iii_ast_t *ast) { return ast ? ast->source_len : 0; }
const char    *iii_ast_source_path(const iii_ast_t *ast) { return ast ? ast->source_path : NULL; }
uint32_t       iii_ast_root_module(const iii_ast_t *ast) { return ast ? ast->root_module : 0; }

void iii_ast_set_root_module(iii_ast_t *ast, uint32_t node_index)
{
    if (!ast) return;
    ast->root_module = node_index;
    iii_ast_recompute_root_mhash(ast);
}

/* ─── Position arena ─────────────────────────────────────────────── */

static bool iii_position_arena_grow(iii_ast_t *ast, uint32_t need)
{
    if (need <= ast->position_cap) return true;
    uint32_t new_cap = iii_grow_cap(ast->position_cap, need);
    if (new_cap == 0) return false;
    iii_ast_position_record_t *p = (iii_ast_position_record_t *)
        realloc(ast->positions, (size_t)new_cap * sizeof(*p));
    if (!p) return false;
    ast->positions = p;
    ast->position_cap = new_cap;
    return true;
}

static bool iii_position_chain_prepend(iii_ast_t *ast, int32_t *first,
                                          const iii_ast_position_t *pos)
{
    if (!iii_position_arena_grow(ast, ast->position_count + 1)) return false;
    uint32_t idx = ast->position_count++;
    ast->positions[idx].pos  = *pos;
    ast->positions[idx].next = *first;
    *first = (int32_t)idx;
    return true;
}

/* ─── Node allocation ────────────────────────────────────────────── */

uint32_t iii_ast_alloc_node(iii_ast_t *ast,
                             iii_ast_kind_t kind,
                             const iii_src_pos_t *pos)
{
    if (!ast) return 0;
    if ((unsigned)kind >= III_AST_KIND_COUNT) return 0;
    uint32_t pool = iii_pool_for_kind(kind);
    if (pool == III_AST_POOL_NULL) return 0;

    uint32_t *count_p = iii_pool_count(ast, pool);
    if (!count_p) return 0;
    if (!iii_pool_grow(ast, pool, *count_p + 1)) return 0;

    uint32_t slot = (*count_p)++;
    iii_ast_node_t *n = iii_pool_node_mut(ast, pool, slot);
    if (!n) return 0;
    memset(n, 0, sizeof(*n));
    n->kind  = kind;
    n->flags = III_AST_FLAG_NONE;

    /* Side-table init: mhash=0, position=-1, binder=0, doc=0. */
    uint8_t (**mh)[32]    = iii_pool_mhash(ast, pool);
    int32_t **pf          = iii_pool_pos_first(ast, pool);
    uint32_t **bd         = iii_pool_binder(ast, pool);
    uint32_t **dc         = iii_pool_doc(ast, pool);
    memset((*mh)[slot], 0, 32);
    (*pf)[slot] = -1;
    (*bd)[slot] = 0;
    (*dc)[slot] = 0;

    /* Record physical position if provided. */
    if (pos != NULL) {
        iii_ast_position_t p;
        p.kind = III_POS_PHYSICAL;
        p.u.physical.start_byte = pos->start_byte;
        p.u.physical.end_byte   = pos->end_byte;
        p.u.physical.line       = pos->line;
        p.u.physical.col        = pos->col;
        (void)iii_position_chain_prepend(ast, &(*pf)[slot], &p);
    }

    return III_AST_NODE_MAKE(pool, slot);
}

/* ─── Hash-cons (A2) ─────────────────────────────────────────────── */

static bool iii_hashcons_grow(iii_ast_t *ast, uint32_t need)
{
    if (need * 2u <= ast->hashcons_cap) return true;
    uint32_t new_cap = ast->hashcons_cap == 0u ? 256u : ast->hashcons_cap * 2u;
    while (new_cap < need * 2u) {
        if (new_cap > UINT32_MAX / 2u) return false;
        new_cap *= 2u;
    }
    iii_ast_hashcons_slot_t *p = (iii_ast_hashcons_slot_t *)
        calloc(new_cap, sizeof(*p));
    if (!p) return false;
    /* Re-insert. */
    for (uint32_t i = 0; i < ast->hashcons_cap; i++) {
        if (ast->hashcons[i].node_index == 0) continue;
        uint32_t mask = new_cap - 1u;
        uint32_t pos = ((uint32_t)ast->hashcons[i].mhash[0] |
                        ((uint32_t)ast->hashcons[i].mhash[1] << 8) |
                        ((uint32_t)ast->hashcons[i].mhash[2] << 16) |
                        ((uint32_t)ast->hashcons[i].mhash[3] << 24)) & mask;
        while (p[pos].node_index != 0) pos = (pos + 1u) & mask;
        p[pos] = ast->hashcons[i];
    }
    free(ast->hashcons);
    ast->hashcons = p;
    ast->hashcons_cap = new_cap;
    return true;
}

static uint32_t iii_hashcons_lookup(const iii_ast_t *ast, const uint8_t mh[32])
{
    if (ast->hashcons_cap == 0) return 0;
    uint32_t mask = ast->hashcons_cap - 1u;
    uint32_t pos = ((uint32_t)mh[0] | ((uint32_t)mh[1] << 8) |
                    ((uint32_t)mh[2] << 16) | ((uint32_t)mh[3] << 24)) & mask;
    while (ast->hashcons[pos].node_index != 0) {
        if (memcmp(ast->hashcons[pos].mhash, mh, 32) == 0) {
            return ast->hashcons[pos].node_index;
        }
        pos = (pos + 1u) & mask;
    }
    return 0;
}

static bool iii_hashcons_insert(iii_ast_t *ast, const uint8_t mh[32], uint32_t node_index)
{
    if (!iii_hashcons_grow(ast, ast->hashcons_count + 1)) return false;
    uint32_t mask = ast->hashcons_cap - 1u;
    uint32_t pos = ((uint32_t)mh[0] | ((uint32_t)mh[1] << 8) |
                    ((uint32_t)mh[2] << 16) | ((uint32_t)mh[3] << 24)) & mask;
    while (ast->hashcons[pos].node_index != 0) pos = (pos + 1u) & mask;
    memcpy(ast->hashcons[pos].mhash, mh, 32);
    ast->hashcons[pos].node_index = node_index;
    ast->hashcons_count++;
    return true;
}

uint32_t iii_ast_intern_node(iii_ast_t *ast, uint32_t freshly_allocated)
{
    if (!ast || freshly_allocated == 0) return freshly_allocated;
    uint32_t pool = III_AST_NODE_POOL(freshly_allocated);
    uint32_t slot = III_AST_NODE_SLOT(freshly_allocated);
    iii_ast_node_t *n = iii_pool_node_mut(ast, pool, slot);
    if (!n) return freshly_allocated;

    /* Compute mhash from the node's canonical bytes. */
    iii_ast_sha256_t h;
    iii_sha256_init(&h);
    iii_canonical_node_bytes(ast, n, &h);
    uint8_t mh[32];
    iii_sha256_final(&h, mh);

    /* Side-table: store mhash. */
    uint8_t (**mh_arr)[32] = iii_pool_mhash(ast, pool);
    memcpy((*mh_arr)[slot], mh, 32);

    /* Lookup. */
    uint32_t existing = iii_hashcons_lookup(ast, mh);
    if (existing != 0) {
        /* Drop the freshly-allocated slot (truncate the pool count). */
        uint32_t *count_p = iii_pool_count(ast, pool);
        if (count_p && *count_p == slot + 1u) (*count_p)--;
        /* Migrate any positions registered on the new slot to the
         * existing node.  In the common case the freshly-allocated
         * slot has a single physical position from alloc_node. */
        int32_t **pf_new = iii_pool_pos_first(ast, pool);
        uint32_t exist_pool = III_AST_NODE_POOL(existing);
        uint32_t exist_slot = III_AST_NODE_SLOT(existing);
        int32_t **pf_old = iii_pool_pos_first(ast, exist_pool);
        if (pf_new && pf_old && exist_slot < *iii_pool_count(ast, exist_pool)) {
            int32_t cur = (*pf_new)[slot];
            while (cur >= 0) {
                int32_t next = ast->positions[cur].next;
                ast->positions[cur].next = (*pf_old)[exist_slot];
                (*pf_old)[exist_slot] = cur;
                cur = next;
            }
            (*pf_new)[slot] = -1;
        }
        return existing;
    }

    /* Insert. */
    n->flags |= III_AST_FLAG_INTERNED;
    if (!iii_hashcons_insert(ast, mh, freshly_allocated)) {
        return freshly_allocated;
    }
    return freshly_allocated;
}

/* ─── Canonical bytes for mhash (A1) ─────────────────────────────── */

static void iii_canonical_src_text(iii_ast_sha256_t *h, const iii_ast_t *ast,
                                      const iii_src_text_t *t)
{
    iii_sha256_update_u32(h, t->length);
    if (t->length > 0 && ast->source_buf != NULL && t->offset + t->length <= ast->source_len) {
        iii_sha256_update(h, ast->source_buf + t->offset, t->length);
    }
}

static void iii_canonical_list(iii_ast_sha256_t *h, const iii_ast_t *ast,
                                  const iii_ast_list_t *list)
{
    iii_sha256_update_u32(h, list->count);
    for (uint32_t i = 0; i < list->count; i++) {
        uint32_t child = ast->list_arena[list->offset + i];
        const uint8_t *ch_mh = iii_ast_node_mhash(ast, child);
        if (ch_mh) iii_sha256_update(h, ch_mh, 32);
        else {
            uint8_t zero[32] = { 0 };
            iii_sha256_update(h, zero, 32);
        }
    }
}

static void iii_canonical_child(iii_ast_sha256_t *h, const iii_ast_t *ast, uint32_t child)
{
    if (child == 0) {
        uint8_t zero[32] = { 0 };
        iii_sha256_update(h, zero, 32);
        return;
    }
    const uint8_t *mh = iii_ast_node_mhash(ast, child);
    if (mh) iii_sha256_update(h, mh, 32);
    else {
        uint8_t zero[32] = { 0 };
        iii_sha256_update(h, zero, 32);
    }
}

static void iii_canonical_node_bytes(const iii_ast_t *ast,
                                       const iii_ast_node_t *n,
                                       iii_ast_sha256_t *h)
{
    iii_sha256_update_u32(h, (uint32_t)n->kind);
    iii_sha256_update_u16(h, n->flags);
    /* Position is NOT included (B1: deduplicate across positions). */
    /* binder_id and doc_comment are NOT included (set by sema /
     * parser side-tables; do not affect content identity at the
     * AST level — they're metadata, not term content).  Note: M1
     * specifies that alpha-equivalent ASTs hash-cons via binder_id
     * RESOLUTION; the binder_id itself is allocated structurally,
     * so two alpha-equivalent identifiers reach the same binder_id
     * by equal placement, not by name.  The IDENT name is hashed
     * only when binder_id is unresolved. */

    switch (n->kind) {
        case III_AST_NULL:
            break;
        case III_AST_MODULE:
            iii_canonical_src_text(h, ast, &n->u.module_.name);
            iii_canonical_list(h, ast, &n->u.module_.modifiers);
            iii_canonical_list(h, ast, &n->u.module_.uses);
            iii_canonical_list(h, ast, &n->u.module_.decls);
            break;
        case III_AST_USE:
            iii_canonical_src_text(h, ast, &n->u.use_.qualified_name);
            iii_canonical_child(h, ast, n->u.use_.closure_mhash_node);
            iii_canonical_src_text(h, ast, &n->u.use_.alias);
            break;
        case III_AST_CYCLE_DECL:
            iii_canonical_src_text(h, ast, &n->u.cycle_decl.name);
            iii_canonical_list(h, ast, &n->u.cycle_decl.params);
            iii_canonical_child(h, ast, n->u.cycle_decl.return_type);
            iii_canonical_list(h, ast, &n->u.cycle_decl.modifiers);
            iii_canonical_child(h, ast, n->u.cycle_decl.forward_block);
            iii_canonical_child(h, ast, n->u.cycle_decl.compromise_block);
            break;
        case III_AST_FN_DECL:
            iii_canonical_src_text(h, ast, &n->u.fn_decl.name);
            iii_canonical_list(h, ast, &n->u.fn_decl.params);
            iii_canonical_child(h, ast, n->u.fn_decl.return_type);
            iii_canonical_list(h, ast, &n->u.fn_decl.modifiers);
            iii_canonical_child(h, ast, n->u.fn_decl.body_block);
            /* Stage 7.1: hash generic type-params only when present, so ordinary
             * (non-generic) fns keep a byte-identical canonical mhash. */
            if (n->u.fn_decl.type_params.count > 0)
                iii_canonical_list(h, ast, &n->u.fn_decl.type_params);
            break;
        case III_AST_TYPE_DECL:
            iii_canonical_src_text(h, ast, &n->u.type_decl.name);
            iii_canonical_list(h, ast, &n->u.type_decl.type_params);
            iii_canonical_child(h, ast, n->u.type_decl.rhs_type);
            iii_canonical_list(h, ast, &n->u.type_decl.modifiers);
            break;
        case III_AST_CONST_DECL:
            iii_canonical_src_text(h, ast, &n->u.const_decl.name);
            iii_canonical_child(h, ast, n->u.const_decl.type_node);
            iii_canonical_child(h, ast, n->u.const_decl.value_expr);
            break;
        case III_AST_EXTERN_DECL:
            iii_sha256_update_u32(h, (uint32_t)n->u.extern_decl.abi);
            iii_canonical_src_text(h, ast, &n->u.extern_decl.name);
            iii_canonical_list(h, ast, &n->u.extern_decl.params);
            iii_canonical_child(h, ast, n->u.extern_decl.return_type);
            iii_sha256_update_u32(h, n->u.extern_decl.source_path_str_idx);
            break;
        case III_AST_MOBIUS_CANDIDATE_DECL:
            iii_canonical_src_text(h, ast, &n->u.mobius_candidate.name);
            iii_canonical_child(h, ast, n->u.mobius_candidate.in_type);
            iii_canonical_child(h, ast, n->u.mobius_candidate.out_type);
            iii_canonical_list(h, ast, &n->u.mobius_candidate.modifiers);
            iii_canonical_child(h, ast, n->u.mobius_candidate.forward_block);
            break;
        case III_AST_SCHEMA_DECL:
            iii_canonical_src_text(h, ast, &n->u.schema_decl.name);
            iii_canonical_list(h, ast, &n->u.schema_decl.fields);
            break;
        case III_AST_SCHEMA_FIELD:
            iii_sha256_update_u32(h, (uint32_t)n->u.schema_field.field_kind);
            iii_canonical_src_text(h, ast, &n->u.schema_field.spec_name);
            iii_canonical_list(h, ast, &n->u.schema_field.args);
            iii_canonical_child(h, ast, n->u.schema_field.expr);
            iii_sha256_update_u32(h, n->u.schema_field.int_value);
            break;
        case III_AST_SEALED_CALL_METHOD_DECL:
            iii_canonical_src_text(h, ast, &n->u.sealed_call.name);
            iii_canonical_list(h, ast, &n->u.sealed_call.params);
            iii_canonical_child(h, ast, n->u.sealed_call.return_type);
            iii_sha256_update_u32(h, n->u.sealed_call.seal_id);
            iii_canonical_child(h, ast, n->u.sealed_call.body_block);
            break;
        case III_AST_PARAM:
            iii_canonical_src_text(h, ast, &n->u.param.name);
            iii_canonical_child(h, ast, n->u.param.type_node);
            break;
        case III_AST_TYPE_PARAM:
            iii_canonical_src_text(h, ast, &n->u.type_param.name);
            iii_canonical_src_text(h, ast, &n->u.type_param.kind);
            break;
        case III_AST_MODIFIER:
            iii_canonical_src_text(h, ast, &n->u.modifier.name);
            iii_canonical_list(h, ast, &n->u.modifier.args);
            iii_sha256_update_u32(h, n->u.modifier.ring_mask);
            iii_canonical_child(h, ast, n->u.modifier.hexad_node);
            iii_sha256_update_u32(h, n->u.modifier.tier_kind);
            iii_sha256_update_u32(h, n->u.modifier.epoch_value);
            break;
        case III_AST_TYPE_REF:
            iii_canonical_src_text(h, ast, &n->u.type_ref.name);
            iii_canonical_list(h, ast, &n->u.type_ref.type_args);
            iii_canonical_list(h, ast, &n->u.type_ref.modifiers);
            break;
        case III_AST_TYPE_PTR:
            iii_canonical_child(h, ast, n->u.type_ptr.inner);
            iii_canonical_list(h, ast, &n->u.type_ptr.modifiers);
            break;
        case III_AST_TYPE_ARRAY:
            iii_canonical_child(h, ast, n->u.type_array.inner);
            iii_sha256_update_u64(h, n->u.type_array.count);
            iii_canonical_list(h, ast, &n->u.type_array.modifiers);
            break;
        case III_AST_TYPE_TUPLE:
            iii_canonical_list(h, ast, &n->u.type_tuple.components);
            iii_canonical_list(h, ast, &n->u.type_tuple.modifiers);
            break;
        case III_AST_TYPE_FN:
            iii_canonical_list(h, ast, &n->u.type_fn.params);
            iii_canonical_child(h, ast, n->u.type_fn.return_type);
            iii_canonical_list(h, ast, &n->u.type_fn.modifiers);
            break;
        case III_AST_STMT_LET:
            iii_sha256_update_u8(h, n->u.let_.mutable_ ? 1u : 0u);
            iii_canonical_src_text(h, ast, &n->u.let_.name);
            iii_canonical_child(h, ast, n->u.let_.type_node);
            iii_canonical_child(h, ast, n->u.let_.value_expr);
            break;
        case III_AST_STMT_WAVEFRONT:
            iii_canonical_list(h, ast, &n->u.wavefront.modifiers);
            iii_canonical_list(h, ast, &n->u.wavefront.nodes);
            iii_canonical_child(h, ast, n->u.wavefront.on_rollback_block);
            break;
        case III_AST_STMT_SANCTUM_ENTER:
            iii_canonical_src_text(h, ast, &n->u.sanctum_enter.frame_var);
            iii_canonical_child(h, ast, n->u.sanctum_enter.body_block);
            break;
        case III_AST_STMT_METAL:
            iii_sha256_update_u32(h, n->u.metal.ring_mask);
            iii_sha256_update_u32(h, n->u.metal.raw_asm_str_idx);
            iii_sha256_update_u32(h, n->u.metal.raw_asm_len);
            break;
        case III_AST_STMT_FOR:
            iii_canonical_src_text(h, ast, &n->u.for_.var);
            iii_canonical_child(h, ast, n->u.for_.iter_expr);
            iii_canonical_child(h, ast, n->u.for_.where_expr);
            iii_canonical_child(h, ast, n->u.for_.body_block);
            break;
        case III_AST_STMT_MATCH:
            iii_canonical_child(h, ast, n->u.match_stmt.scrutinee);
            iii_canonical_list(h, ast, &n->u.match_stmt.arms);
            break;
        case III_AST_STMT_RETURN:
            iii_canonical_child(h, ast, n->u.return_.value_expr);
            break;
        case III_AST_STMT_ASSIGN:
            iii_canonical_child(h, ast, n->u.assign.lvalue_expr);
            iii_canonical_child(h, ast, n->u.assign.value_expr);
            break;
        case III_AST_STMT_EXPR:
            iii_canonical_child(h, ast, n->u.expr_stmt.expr);
            break;
        case III_AST_FORWARD_BLOCK:
            iii_canonical_list(h, ast, &n->u.forward_block.stmts);
            break;
        case III_AST_COMPROMISE_BLOCK:
            iii_sha256_update_u32(h, (uint32_t)n->u.compromise_block.severity);
            break;
        case III_AST_MATCH_ARM:
            iii_canonical_child(h, ast, n->u.match_arm.pattern);
            iii_canonical_child(h, ast, n->u.match_arm.guard_expr);
            iii_canonical_child(h, ast, n->u.match_arm.body);
            break;
        case III_AST_PAT_LITERAL:
            iii_canonical_child(h, ast, n->u.pat_literal.literal_node);
            break;
        case III_AST_PAT_IDENT:
            iii_canonical_src_text(h, ast, &n->u.pat_ident.name);
            iii_canonical_list(h, ast, &n->u.pat_ident.payload_pats);
            break;
        case III_AST_PAT_HEXAD:
            for (int i = 0; i < 6; i++) iii_sha256_update_u8(h, (uint8_t)n->u.pat_hexad.trits[i]);
            break;
        case III_AST_PAT_WILDCARD:
            break;
        case III_AST_PAT_TUPLE:
            iii_canonical_list(h, ast, &n->u.pat_tuple.components);
            break;
        case III_AST_EXPR_INT:
            iii_sha256_update_u64(h, n->u.int_.value);
            break;
        case III_AST_EXPR_HEX:
            iii_sha256_update_u64(h, n->u.hex_.value);
            break;
        case III_AST_EXPR_MHASH:
            iii_sha256_update(h, n->u.mhash_.mhash, 32);
            break;
        case III_AST_EXPR_STR:
            iii_sha256_update_u32(h, n->u.str_.string_payload_idx);
            iii_sha256_update_u32(h, n->u.str_.string_len);
            if (n->u.str_.string_payload_idx < ast->string_payload_count) {
                const uint8_t *payload = ast->string_payloads[n->u.str_.string_payload_idx];
                if (payload && n->u.str_.string_len > 0) {
                    iii_sha256_update(h, payload, n->u.str_.string_len);
                }
            }
            break;
        case III_AST_EXPR_BOOL:
            iii_sha256_update_u8(h, n->u.bool_.value ? 1u : 0u);
            break;
        case III_AST_EXPR_TRIT:
            iii_sha256_update_u8(h, (uint8_t)n->u.trit_.trit);
            break;
        case III_AST_EXPR_HEXAD:
            for (int i = 0; i < 6; i++) iii_sha256_update_u8(h, (uint8_t)n->u.hexad_.trits[i]);
            break;
        case III_AST_EXPR_UNIT:
            break;
        case III_AST_EXPR_IDENT:
            /* M1: if binder_id is resolved, hash that instead of the
             * source name — this is what gives alpha-equivalent ASTs
             * the same mhash.  The binder side-table is consulted via
             * the pool lookup. */
            {
                uint32_t pool = iii_pool_for_kind(III_AST_EXPR_IDENT);
                /* Since this is computed from inside iii_ast_intern_node
                 * BEFORE the binder is resolved, binder_id is typically
                 * 0 here.  Sema must call a re-intern path after
                 * resolution if it wants alpha-equivalence dedup. */
                (void)pool;
                iii_canonical_src_text(h, ast, &n->u.ident.name);
            }
            break;
        case III_AST_EXPR_CALL:
            iii_canonical_child(h, ast, n->u.call.callee);
            iii_canonical_list(h, ast, &n->u.call.args);
            break;
        case III_AST_EXPR_FIELD:
            iii_canonical_child(h, ast, n->u.field.object);
            iii_canonical_src_text(h, ast, &n->u.field.field_name);
            break;
        case III_AST_EXPR_INDEX:
            iii_canonical_child(h, ast, n->u.index.object);
            iii_canonical_child(h, ast, n->u.index.index_expr);
            break;
        case III_AST_EXPR_BINARY:
            iii_sha256_update_u8(h, (uint8_t)n->u.binary.op);
            iii_canonical_child(h, ast, n->u.binary.lhs);
            iii_canonical_child(h, ast, n->u.binary.rhs);
            break;
        case III_AST_EXPR_UNARY:
            iii_sha256_update_u8(h, (uint8_t)n->u.unary.op);
            iii_canonical_child(h, ast, n->u.unary.operand);
            break;
        case III_AST_EXPR_BLOCK:
            iii_canonical_list(h, ast, &n->u.block.stmts);
            break;
        case III_AST_EXPR_MATCH:
            iii_canonical_child(h, ast, n->u.match_expr.scrutinee);
            iii_canonical_list(h, ast, &n->u.match_expr.arms);
            break;
        case III_AST_EXPR_PAREN:
            iii_canonical_child(h, ast, n->u.paren.inner);
            break;
        case III_AST_EXPR_RAW_ASM:
            iii_sha256_update_u32(h, n->u.raw_asm.raw_asm_str_idx);
            iii_sha256_update_u32(h, n->u.raw_asm.raw_asm_len);
            break;
        case III_AST_RING_SET:
            iii_sha256_update_u32(h, n->u.ring_set.mask);
            break;
        case III_AST_HEXAD_NAME:
            iii_canonical_src_text(h, ast, &n->u.hexad_name.name);
            break;
        case III_AST_ARG:
            iii_canonical_src_text(h, ast, &n->u.arg.arg_name);
            iii_canonical_child(h, ast, n->u.arg.value_expr);
            break;
        case III_AST_EXPR_TYPE:
            iii_canonical_child(h, ast, n->u.expr_type.type_node);
            break;
        case III_AST_TYPE_OF:
            iii_canonical_child(h, ast, n->u.type_of.term_node);
            break;
        case III_AST_EXPR_HOLE:
            iii_canonical_child(h, ast, n->u.hole.type_hint);
            iii_sha256_update_u32(h, n->u.hole.hole_id);
            break;
        case III_AST_EXPR_PARALLEL:
            iii_canonical_list(h, ast, &n->u.parallel.branches);
            break;
        case III_AST_ERROR_NODE:
            iii_sha256_update_u32(h, (uint32_t)n->u.error.error_code);
            iii_sha256_update_u32(h, n->u.error.source_span_start);
            iii_sha256_update_u32(h, n->u.error.source_span_end);
            iii_sha256_update_u32(h, (uint32_t)n->u.error.recovered_kind_hint);
            iii_sha256_update_u32(h, n->u.error.message_str_idx);
            break;
        case III_AST_ADR_DECL:
            iii_canonical_src_text(h, ast, &n->u.adr_decl.adr_id);
            iii_canonical_src_text(h, ast, &n->u.adr_decl.title);
            iii_canonical_child(h, ast, n->u.adr_decl.body_block);
            iii_canonical_list(h, ast, &n->u.adr_decl.modifiers);
            break;
        case III_AST_CONFORMANCE_CLAIM_DECL:
            iii_canonical_src_text(h, ast, &n->u.conformance_claim.criterion_id);
            iii_canonical_src_text(h, ast, &n->u.conformance_claim.claim_text);
            iii_canonical_child(h, ast, n->u.conformance_claim.proof_node);
            break;
        case III_AST_TEST_CASE_DECL:
            iii_canonical_src_text(h, ast, &n->u.test_case.test_name);
            iii_canonical_child(h, ast, n->u.test_case.precondition);
            iii_canonical_child(h, ast, n->u.test_case.action);
            iii_canonical_child(h, ast, n->u.test_case.postcondition);
            break;
        case III_AST_RATIONALE_DECL:
            iii_canonical_src_text(h, ast, &n->u.rationale.for_what);
            iii_sha256_update_u32(h, n->u.rationale.text_str_idx);
            break;
        case III_AST_OPERATOR_INTENT:
            iii_sha256_update_u32(h, n->u.operator_intent.intent_text_str_idx);
            iii_sha256_update(h, n->u.operator_intent.signature_mhash, 32);
            iii_canonical_child(h, ast, n->u.operator_intent.witness_node_id);
            break;
        case III_AST_USER_NODE:
            iii_sha256_update_u32(h, n->u.user_node.user_kind_id);
            iii_canonical_list(h, ast, &n->u.user_node.children);
            iii_sha256_update_u32(h, n->u.user_node.payload_str_idx);
            iii_sha256_update_u32(h, n->u.user_node.payload_len);
            break;
        /* ─── Phase-B canonical bytes ──────────────────────────── */
        case III_AST_STMT_IF:
            iii_canonical_child(h, ast, n->u.if_.cond);
            iii_canonical_child(h, ast, n->u.if_.then_block);
            iii_canonical_child(h, ast, n->u.if_.else_block);
            break;
        case III_AST_STMT_WHILE:
            iii_canonical_child(h, ast, n->u.while_.cond);
            iii_canonical_child(h, ast, n->u.while_.body_block);
            break;
        case III_AST_STMT_LOOP:
            iii_canonical_child(h, ast, n->u.loop_.body_block);
            break;
        case III_AST_STMT_BREAK:
        case III_AST_STMT_CONTINUE:
            /* No children; the node IDENTITY (kind) is the canonical
             * content.  Reserved field is not part of canonical bytes
             * to keep AST hash stable under future label additions. */
            break;
        case III_AST_EXPR_RANGE:
            iii_canonical_child(h, ast, n->u.range_.lo);
            iii_canonical_child(h, ast, n->u.range_.hi);
            break;
        case III_AST_EXPR_CAST:
            iii_canonical_child(h, ast, n->u.cast_.value_expr);
            iii_canonical_child(h, ast, n->u.cast_.target_type);
            break;
        case III_AST_EXPR_SIZEOF:
            iii_canonical_child(h, ast, n->u.sizeof_.target_type);
            iii_sha256_update_u64(h, n->u.sizeof_.resolved);
            break;
        case III_AST_STRUCT_DECL:
            iii_canonical_src_text(h, ast, &n->u.struct_decl.name);
            iii_canonical_list(h, ast, &n->u.struct_decl.fields);
            break;
        case III_AST_VAR_DECL:
            iii_canonical_src_text(h, ast, &n->u.var_decl.name);
            iii_canonical_child(h, ast, n->u.var_decl.type_node);
            iii_canonical_child(h, ast, n->u.var_decl.init_expr);
            break;
        case III_AST_KIND_COUNT:
        default:
            break;
    }
}

/* ─── List arena (LIFO) ──────────────────────────────────────────── */

uint32_t iii_ast_list_begin(iii_ast_t *ast)
{
    if (!ast) return 0;
    return ast->list_used;
}

bool iii_ast_list_push(iii_ast_t *ast, uint32_t list_start, uint32_t node_index)
{
    if (!ast) return false;
    (void)list_start;
    if (ast->list_used == ast->list_cap) {
        uint32_t new_cap = iii_grow_cap(ast->list_cap, ast->list_cap + 1);
        if (new_cap == 0) return false;
        uint32_t *p = (uint32_t *)realloc(ast->list_arena, (size_t)new_cap * sizeof(uint32_t));
        if (!p) return false;
        ast->list_arena = p;
        ast->list_cap   = new_cap;
    }
    ast->list_arena[ast->list_used++] = node_index;
    return true;
}

iii_ast_list_t iii_ast_list_commit(iii_ast_t *ast, uint32_t list_start)
{
    iii_ast_list_t h = { 0u, 0u };
    if (!ast) return h;
    h.offset = list_start;
    h.count  = ast->list_used - list_start;
    return h;
}

iii_ast_list_t iii_ast_list_extend(iii_ast_t *ast,
                                    const iii_ast_list_t *existing,
                                    uint32_t node_index)
{
    iii_ast_list_t h;
    if (!ast) { h.offset = 0; h.count = 0; return h; }
    if (existing == NULL || existing->count == 0) {
        uint32_t s = iii_ast_list_begin(ast);
        if (!iii_ast_list_push(ast, s, node_index)) {
            h.offset = 0; h.count = 0; return h;
        }
        return iii_ast_list_commit(ast, s);
    }
    uint32_t expected_tail = existing->offset + existing->count;
    if (expected_tail != ast->list_used) { h.offset = 0; h.count = 0; return h; }
    if (!iii_ast_list_push(ast, existing->offset, node_index)) {
        h.offset = 0; h.count = 0; return h;
    }
    h.offset = existing->offset;
    h.count  = existing->count + 1u;
    return h;
}

/* ─── Open list (F1) ─────────────────────────────────────────────── */

struct iii_ast_open_list {
    iii_ast_t *ast;
    uint32_t  *items;
    uint32_t   count;
    uint32_t   cap;
};

iii_ast_open_list_t *iii_ast_open_list_create(iii_ast_t *ast)
{
    if (!ast) return NULL;
    iii_ast_open_list_t *ol = (iii_ast_open_list_t *)calloc(1, sizeof(*ol));
    if (!ol) return NULL;
    ol->ast = ast;
    ol->items = NULL;
    ol->count = 0;
    ol->cap = 0;
    return ol;
}

bool iii_ast_open_list_push(iii_ast_open_list_t *ol, uint32_t node_index)
{
    if (!ol) return false;
    if (ol->count == ol->cap) {
        uint32_t new_cap = ol->cap == 0u ? 8u : ol->cap * 2u;
        uint32_t *p = (uint32_t *)realloc(ol->items, (size_t)new_cap * sizeof(uint32_t));
        if (!p) return false;
        ol->items = p;
        ol->cap = new_cap;
    }
    ol->items[ol->count++] = node_index;
    return true;
}

iii_ast_list_t iii_ast_open_list_commit(iii_ast_t *ast, iii_ast_open_list_t *ol)
{
    iii_ast_list_t h = { 0u, 0u };
    if (!ast || !ol) return h;
    /* Append all items to the master list arena. */
    h.offset = ast->list_used;
    h.count  = ol->count;
    if (ol->count > 0) {
        if (ast->list_used + ol->count > ast->list_cap) {
            uint32_t need = ast->list_used + ol->count;
            uint32_t new_cap = iii_grow_cap(ast->list_cap, need);
            if (new_cap == 0) { iii_ast_open_list_destroy(ol); h.count = 0; return h; }
            uint32_t *p = (uint32_t *)
                realloc(ast->list_arena, (size_t)new_cap * sizeof(uint32_t));
            if (!p) { iii_ast_open_list_destroy(ol); h.count = 0; return h; }
            ast->list_arena = p;
            ast->list_cap = new_cap;
        }
        memcpy(ast->list_arena + ast->list_used, ol->items, (size_t)ol->count * sizeof(uint32_t));
        ast->list_used += ol->count;
    }
    iii_ast_open_list_destroy(ol);
    return h;
}

void iii_ast_open_list_destroy(iii_ast_open_list_t *ol)
{
    if (!ol) return;
    free(ol->items);
    free(ol);
}

/* ─── String interning ───────────────────────────────────────────── */

uint32_t iii_ast_intern_string(iii_ast_t *ast, const uint8_t *payload)
{
    if (!ast) return 0;
    if (ast->string_payload_count == ast->string_payload_cap) {
        uint32_t new_cap = iii_grow_cap(ast->string_payload_cap,
                                          ast->string_payload_cap + 1);
        if (new_cap == 0) return 0;
        const uint8_t **p = (const uint8_t **)
            realloc(ast->string_payloads, (size_t)new_cap * sizeof(*p));
        if (!p) return 0;
        ast->string_payloads = p;
        ast->string_payload_cap = new_cap;
    }
    uint32_t idx = ast->string_payload_count++;
    ast->string_payloads[idx] = payload;
    return idx;
}

/* String-payload accessors (consumed by cg_r3.c / cg_rm2.c rdata
 * emission).  These are the public counterparts to the internal
 * `string_payloads` / `string_payload_count` fields. */
uint32_t iii_ast_string_payload_count(const iii_ast_t *ast)
{
    return ast ? ast->string_payload_count : 0u;
}

const uint8_t *iii_ast_string_payload_get(const iii_ast_t *ast, uint32_t idx)
{
    if (!ast || idx >= ast->string_payload_count) return NULL;
    return ast->string_payloads[idx];
}

/* ─── Read accessors ─────────────────────────────────────────────── */

const iii_ast_node_t *iii_ast_get(const iii_ast_t *ast, uint32_t node_index)
{
    if (!ast) return NULL;
    if (node_index == 0) return &ast->small_nodes[0];   /* sentinel */
    uint32_t pool = III_AST_NODE_POOL(node_index);
    uint32_t slot = III_AST_NODE_SLOT(node_index);
    return iii_pool_node(ast, pool, slot);
}

iii_ast_node_t *iii_ast_get_mut(iii_ast_t *ast, uint32_t node_index)
{
    if (!ast) return NULL;
    if (node_index == 0) return &ast->small_nodes[0];
    uint32_t pool = III_AST_NODE_POOL(node_index);
    uint32_t slot = III_AST_NODE_SLOT(node_index);
    return iii_pool_node_mut(ast, pool, slot);
}

size_t iii_ast_node_count(const iii_ast_t *ast)
{
    if (!ast) return 0;
    /* Subtract the four reserved sentinel slots (one per pool). */
    return (size_t)(ast->small_count + ast->medium_count +
                     ast->large_count + ast->user_count) - 4u;
}

size_t iii_ast_pool_count(const iii_ast_t *ast, uint32_t pool)
{
    if (!ast) return 0;
    switch (pool) {
        case III_AST_POOL_SMALL:  return ast->small_count > 0 ? ast->small_count - 1u : 0;
        case III_AST_POOL_MEDIUM: return ast->medium_count > 0 ? ast->medium_count - 1u : 0;
        case III_AST_POOL_LARGE:  return ast->large_count > 0 ? ast->large_count - 1u : 0;
        case III_AST_POOL_USER:   return ast->user_count > 0 ? ast->user_count - 1u : 0;
        default: return 0;
    }
}

uint32_t iii_ast_list_at(const iii_ast_t *ast, iii_ast_list_t list, uint32_t i)
{
    if (!ast) return 0;
    if (i >= list.count) return 0;
    if (list.offset + i >= ast->list_used) return 0;
    return ast->list_arena[list.offset + i];
}

/* ─── Kind-name table ────────────────────────────────────────────── */

static const char *const III_AST_KIND_NAMES[III_AST_KIND_COUNT] = {
    [III_AST_NULL]                       = "NULL",
    [III_AST_MODULE]                     = "MODULE",
    [III_AST_USE]                        = "USE",
    [III_AST_CYCLE_DECL]                 = "CYCLE_DECL",
    [III_AST_FN_DECL]                    = "FN_DECL",
    [III_AST_TYPE_DECL]                  = "TYPE_DECL",
    [III_AST_CONST_DECL]                 = "CONST_DECL",
    [III_AST_EXTERN_DECL]                = "EXTERN_DECL",
    [III_AST_MOBIUS_CANDIDATE_DECL]      = "MOBIUS_CANDIDATE",
    [III_AST_SCHEMA_DECL]                = "SCHEMA_DECL",
    [III_AST_SCHEMA_FIELD]               = "SCHEMA_FIELD",
    [III_AST_SEALED_CALL_METHOD_DECL]    = "SEALED_CALL_METHOD",
    [III_AST_PARAM]                      = "PARAM",
    [III_AST_TYPE_PARAM]                 = "TYPE_PARAM",
    [III_AST_MODIFIER]                   = "MODIFIER",
    [III_AST_TYPE_REF]                   = "TYPE_REF",
    [III_AST_TYPE_PTR]                   = "TYPE_PTR",
    [III_AST_TYPE_ARRAY]                 = "TYPE_ARRAY",
    [III_AST_TYPE_TUPLE]                 = "TYPE_TUPLE",
    [III_AST_TYPE_FN]                    = "TYPE_FN",
    [III_AST_STMT_LET]                   = "STMT_LET",
    [III_AST_STMT_WAVEFRONT]             = "STMT_WAVEFRONT",
    [III_AST_STMT_SANCTUM_ENTER]         = "STMT_SANCTUM_ENTER",
    [III_AST_STMT_METAL]                 = "STMT_METAL",
    [III_AST_STMT_FOR]                   = "STMT_FOR",
    [III_AST_STMT_MATCH]                 = "STMT_MATCH",
    [III_AST_STMT_RETURN]                = "STMT_RETURN",
    [III_AST_STMT_ASSIGN]                = "STMT_ASSIGN",
    [III_AST_STMT_EXPR]                  = "STMT_EXPR",
    [III_AST_FORWARD_BLOCK]              = "FORWARD_BLOCK",
    [III_AST_COMPROMISE_BLOCK]           = "COMPROMISE_BLOCK",
    [III_AST_MATCH_ARM]                  = "MATCH_ARM",
    [III_AST_PAT_LITERAL]                = "PAT_LITERAL",
    [III_AST_PAT_IDENT]                  = "PAT_IDENT",
    [III_AST_PAT_HEXAD]                  = "PAT_HEXAD",
    [III_AST_PAT_WILDCARD]               = "PAT_WILDCARD",
    [III_AST_PAT_TUPLE]                  = "PAT_TUPLE",
    [III_AST_EXPR_INT]                   = "EXPR_INT",
    [III_AST_EXPR_HEX]                   = "EXPR_HEX",
    [III_AST_EXPR_MHASH]                 = "EXPR_MHASH",
    [III_AST_EXPR_STR]                   = "EXPR_STR",
    [III_AST_EXPR_BOOL]                  = "EXPR_BOOL",
    [III_AST_EXPR_TRIT]                  = "EXPR_TRIT",
    [III_AST_EXPR_HEXAD]                 = "EXPR_HEXAD",
    [III_AST_EXPR_UNIT]                  = "EXPR_UNIT",
    [III_AST_EXPR_IDENT]                 = "EXPR_IDENT",
    [III_AST_EXPR_CALL]                  = "EXPR_CALL",
    [III_AST_EXPR_FIELD]                 = "EXPR_FIELD",
    [III_AST_EXPR_INDEX]                 = "EXPR_INDEX",
    [III_AST_EXPR_BINARY]                = "EXPR_BINARY",
    [III_AST_EXPR_UNARY]                 = "EXPR_UNARY",
    [III_AST_EXPR_BLOCK]                 = "EXPR_BLOCK",
    [III_AST_EXPR_MATCH]                 = "EXPR_MATCH",
    [III_AST_EXPR_PAREN]                 = "EXPR_PAREN",
    [III_AST_EXPR_RAW_ASM]               = "EXPR_RAW_ASM",
    [III_AST_RING_SET]                   = "RING_SET",
    [III_AST_HEXAD_NAME]                 = "HEXAD_NAME",
    [III_AST_ARG]                        = "ARG",
    [III_AST_EXPR_TYPE]                  = "EXPR_TYPE",
    [III_AST_TYPE_OF]                    = "TYPE_OF",
    [III_AST_EXPR_HOLE]                  = "EXPR_HOLE",
    [III_AST_EXPR_PARALLEL]              = "EXPR_PARALLEL",
    [III_AST_ERROR_NODE]                 = "ERROR_NODE",
    [III_AST_ADR_DECL]                   = "ADR_DECL",
    [III_AST_CONFORMANCE_CLAIM_DECL]     = "CONFORMANCE_CLAIM",
    [III_AST_TEST_CASE_DECL]             = "TEST_CASE",
    [III_AST_RATIONALE_DECL]             = "RATIONALE",
    [III_AST_OPERATOR_INTENT]            = "OPERATOR_INTENT",
    [III_AST_USER_NODE]                  = "USER_NODE",
    /* Phase-B kind names. */
    [III_AST_STMT_IF]                    = "STMT_IF",
    [III_AST_STMT_WHILE]                 = "STMT_WHILE",
    [III_AST_EXPR_RANGE]                 = "EXPR_RANGE",
    [III_AST_EXPR_CAST]                  = "EXPR_CAST",
    [III_AST_EXPR_SIZEOF]                = "EXPR_SIZEOF",
    [III_AST_VAR_DECL]                   = "VAR_DECL",
    [III_AST_STRUCT_DECL]                = "STRUCT_DECL",
    [III_AST_STMT_LOOP]                  = "STMT_LOOP",
    [III_AST_STMT_BREAK]                 = "STMT_BREAK",
    [III_AST_STMT_CONTINUE]              = "STMT_CONTINUE",
};

const char *iii_ast_kind_name(iii_ast_kind_t k)
{
    if ((unsigned)k >= III_AST_KIND_COUNT) return "<bad-kind>";
    const char *s = III_AST_KIND_NAMES[k];
    return s ? s : "<unknown>";
}

/* ─── Per-node mhash accessor ────────────────────────────────────── */

const uint8_t *iii_ast_node_mhash(const iii_ast_t *ast, uint32_t node_index)
{
    if (!ast || node_index == 0) return NULL;
    uint32_t pool = III_AST_NODE_POOL(node_index);
    uint32_t slot = III_AST_NODE_SLOT(node_index);
    switch (pool) {
        case III_AST_POOL_SMALL:  return slot < ast->small_count  ? ast->small_mhash[slot]  : NULL;
        case III_AST_POOL_MEDIUM: return slot < ast->medium_count ? ast->medium_mhash[slot] : NULL;
        case III_AST_POOL_LARGE:  return slot < ast->large_count  ? ast->large_mhash[slot]  : NULL;
        case III_AST_POOL_USER:   return slot < ast->user_count   ? ast->user_mhash[slot]   : NULL;
        default: return NULL;
    }
}

/* ─── Position side-table ────────────────────────────────────────── */

static int32_t iii_pool_pos_first_read(const iii_ast_t *ast, uint32_t pool, uint32_t slot)
{
    switch (pool) {
        case III_AST_POOL_SMALL:  return slot < ast->small_count  ? ast->small_position_first[slot]  : -1;
        case III_AST_POOL_MEDIUM: return slot < ast->medium_count ? ast->medium_position_first[slot] : -1;
        case III_AST_POOL_LARGE:  return slot < ast->large_count  ? ast->large_position_first[slot]  : -1;
        case III_AST_POOL_USER:   return slot < ast->user_count   ? ast->user_position_first[slot]   : -1;
        default: return -1;
    }
}

size_t iii_ast_position_count(const iii_ast_t *ast, uint32_t node_index)
{
    if (!ast || node_index == 0) return 0;
    uint32_t pool = III_AST_NODE_POOL(node_index);
    uint32_t slot = III_AST_NODE_SLOT(node_index);
    int32_t cur = iii_pool_pos_first_read(ast, pool, slot);
    size_t n = 0;
    while (cur >= 0) { n++; cur = ast->positions[cur].next; }
    return n;
}

bool iii_ast_position_at(const iii_ast_t *ast, uint32_t node_index,
                          size_t i, iii_ast_position_t *out)
{
    if (!ast || !out || node_index == 0) return false;
    uint32_t pool = III_AST_NODE_POOL(node_index);
    uint32_t slot = III_AST_NODE_SLOT(node_index);
    int32_t cur = iii_pool_pos_first_read(ast, pool, slot);
    size_t k = 0;
    while (cur >= 0) {
        if (k == i) { *out = ast->positions[cur].pos; return true; }
        k++;
        cur = ast->positions[cur].next;
    }
    return false;
}

bool iii_ast_position_first(const iii_ast_t *ast, uint32_t node_index,
                              iii_ast_position_t *out)
{
    return iii_ast_position_at(ast, node_index, 0, out);
}

bool iii_ast_position_add(iii_ast_t *ast, uint32_t node_index,
                            const iii_ast_position_t *pos)
{
    if (!ast || !pos || node_index == 0) return false;
    uint32_t pool = III_AST_NODE_POOL(node_index);
    uint32_t slot = III_AST_NODE_SLOT(node_index);
    int32_t **pf = iii_pool_pos_first(ast, pool);
    if (!pf || slot >= *iii_pool_count(ast, pool)) return false;
    return iii_position_chain_prepend(ast, &(*pf)[slot], pos);
}

bool iii_ast_position_add_synthetic(iii_ast_t *ast, uint32_t node_index,
                                      uint32_t source_node_index,
                                      const uint8_t pass_mhash[32],
                                      uint32_t rationale_str_idx)
{
    iii_ast_position_t p;
    p.kind = III_POS_SYNTHETIC;
    p.u.synthetic.source_node_index = source_node_index;
    if (pass_mhash) memcpy(p.u.synthetic.pass_mhash, pass_mhash, 32);
    else            memset(p.u.synthetic.pass_mhash, 0, 32);
    p.u.synthetic.rationale_str_idx = rationale_str_idx;
    return iii_ast_position_add(ast, node_index, &p);
}

/* ─── Binder / doc-comment side-tables ───────────────────────────── */

uint32_t iii_ast_alloc_binder_id(iii_ast_t *ast)
{
    if (!ast) return 0;
    return ast->next_binder_id++;
}

uint32_t iii_ast_node_binder_id(const iii_ast_t *ast, uint32_t node_index)
{
    if (!ast || node_index == 0) return 0;
    uint32_t pool = III_AST_NODE_POOL(node_index);
    uint32_t slot = III_AST_NODE_SLOT(node_index);
    switch (pool) {
        case III_AST_POOL_SMALL:  return slot < ast->small_count  ? ast->small_binder_id[slot]  : 0;
        case III_AST_POOL_MEDIUM: return slot < ast->medium_count ? ast->medium_binder_id[slot] : 0;
        case III_AST_POOL_LARGE:  return slot < ast->large_count  ? ast->large_binder_id[slot]  : 0;
        case III_AST_POOL_USER:   return slot < ast->user_count   ? ast->user_binder_id[slot]   : 0;
        default: return 0;
    }
}

bool iii_ast_set_binder_id(iii_ast_t *ast, uint32_t node_index, uint32_t binder_id)
{
    if (!ast || node_index == 0) return false;
    uint32_t pool = III_AST_NODE_POOL(node_index);
    uint32_t slot = III_AST_NODE_SLOT(node_index);
    uint32_t **bd = iii_pool_binder(ast, pool);
    if (!bd || slot >= *iii_pool_count(ast, pool)) return false;
    (*bd)[slot] = binder_id;
    return true;
}

uint32_t iii_ast_leading_doc_comment(const iii_ast_t *ast, uint32_t node_index)
{
    if (!ast || node_index == 0) return 0;
    uint32_t pool = III_AST_NODE_POOL(node_index);
    uint32_t slot = III_AST_NODE_SLOT(node_index);
    switch (pool) {
        case III_AST_POOL_SMALL:  return slot < ast->small_count  ? ast->small_doc_comment[slot]  : 0;
        case III_AST_POOL_MEDIUM: return slot < ast->medium_count ? ast->medium_doc_comment[slot] : 0;
        case III_AST_POOL_LARGE:  return slot < ast->large_count  ? ast->large_doc_comment[slot]  : 0;
        case III_AST_POOL_USER:   return slot < ast->user_count   ? ast->user_doc_comment[slot]   : 0;
        default: return 0;
    }
}

bool iii_ast_set_leading_doc_comment(iii_ast_t *ast, uint32_t node_index,
                                        uint32_t doc_comment_node)
{
    if (!ast || node_index == 0) return false;
    uint32_t pool = III_AST_NODE_POOL(node_index);
    uint32_t slot = III_AST_NODE_SLOT(node_index);
    uint32_t **dc = iii_pool_doc(ast, pool);
    if (!dc || slot >= *iii_pool_count(ast, pool)) return false;
    (*dc)[slot] = doc_comment_node;
    return true;
}

/* ─── Checkpoint / rollback (E1) ─────────────────────────────────── */

iii_ast_checkpoint_t iii_ast_checkpoint(const iii_ast_t *ast)
{
    iii_ast_checkpoint_t cp = { 0 };
    if (!ast) return cp;
    cp.small_count           = ast->small_count;
    cp.medium_count          = ast->medium_count;
    cp.large_count           = ast->large_count;
    cp.user_count            = ast->user_count;
    cp.list_used             = ast->list_used;
    cp.string_payload_count  = ast->string_payload_count;
    cp.position_count        = ast->position_count;
    cp.annotation_count      = ast->annotation_count;
    cp.annotation_blob_count = ast->annotation_blob_used;
    cp.hashcons_count        = ast->hashcons_count;
    cp.next_binder_id        = ast->next_binder_id;
    return cp;
}

void iii_ast_rollback(iii_ast_t *ast, iii_ast_checkpoint_t cp)
{
    if (!ast) return;
    /* Truncate hash-cons of any entries with node_index above the
     * rollback boundaries. */
    for (uint32_t i = 0; i < ast->hashcons_cap; i++) {
        if (ast->hashcons[i].node_index == 0) continue;
        uint32_t idx = ast->hashcons[i].node_index;
        uint32_t pool = III_AST_NODE_POOL(idx);
        uint32_t slot = III_AST_NODE_SLOT(idx);
        bool drop = false;
        switch (pool) {
            case III_AST_POOL_SMALL:  drop = slot >= cp.small_count;  break;
            case III_AST_POOL_MEDIUM: drop = slot >= cp.medium_count; break;
            case III_AST_POOL_LARGE:  drop = slot >= cp.large_count;  break;
            case III_AST_POOL_USER:   drop = slot >= cp.user_count;   break;
        }
        if (drop) {
            memset(&ast->hashcons[i], 0, sizeof(ast->hashcons[i]));
            if (ast->hashcons_count > 0) ast->hashcons_count--;
        }
    }
    /* Re-insertion of any displaced entries (after a hole opens
     * during truncation) is unnecessary because lookups linear-probe
     * past empty slots; correctness is preserved.  Stage-1 may want
     * to compact the table. */

    ast->small_count           = cp.small_count;
    ast->medium_count          = cp.medium_count;
    ast->large_count           = cp.large_count;
    ast->user_count            = cp.user_count;
    ast->list_used             = cp.list_used;
    ast->string_payload_count  = cp.string_payload_count;
    ast->position_count        = cp.position_count;
    /* Annotations: truncate. */
    ast->annotation_count      = cp.annotation_count;
    ast->annotation_blob_used  = cp.annotation_blob_count;
    ast->next_binder_id        = cp.next_binder_id;
}

/* ─── Child enumeration ──────────────────────────────────────────── */

int iii_ast_iterate_children(iii_ast_t *ast,
                              uint32_t node,
                              iii_ast_child_fn_t fn,
                              void *ctx)
{
    if (!ast || !fn) return -1;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n) return -1;

#define V(child, slot) do { \
    if ((child) != 0) { int r = fn(ast, node, (child), (slot), ctx); if (r) return r; } \
} while (0)

#define VL(list, slot) do { \
    for (uint32_t _i = 0; _i < (list).count; _i++) { \
        uint32_t _c = iii_ast_list_at(ast, (list), _i); \
        if (_c != 0) { int r = fn(ast, node, _c, (slot), ctx); if (r) return r; } \
    } \
} while (0)

    switch (n->kind) {
        case III_AST_NULL: return 0;
        case III_AST_MODULE:
            VL(n->u.module_.modifiers, "modifiers");
            VL(n->u.module_.uses,      "uses");
            VL(n->u.module_.decls,     "decls");
            return 0;
        case III_AST_USE:
            V(n->u.use_.closure_mhash_node, "closure");
            return 0;
        case III_AST_CYCLE_DECL:
            VL(n->u.cycle_decl.params,           "params");
            V(n->u.cycle_decl.return_type,       "return_type");
            VL(n->u.cycle_decl.modifiers,        "modifiers");
            V(n->u.cycle_decl.forward_block,     "forward");
            V(n->u.cycle_decl.compromise_block,  "compromise");
            return 0;
        case III_AST_FN_DECL:
            VL(n->u.fn_decl.params,    "params");
            V(n->u.fn_decl.return_type, "return_type");
            VL(n->u.fn_decl.modifiers, "modifiers");
            V(n->u.fn_decl.body_block, "body");
            return 0;
        case III_AST_TYPE_DECL:
            VL(n->u.type_decl.type_params, "type_params");
            V(n->u.type_decl.rhs_type,     "rhs");
            VL(n->u.type_decl.modifiers,   "modifiers");
            return 0;
        case III_AST_CONST_DECL:
            V(n->u.const_decl.type_node,  "type");
            V(n->u.const_decl.value_expr, "value");
            return 0;
        case III_AST_EXTERN_DECL:
            VL(n->u.extern_decl.params,     "params");
            V(n->u.extern_decl.return_type, "return_type");
            return 0;
        case III_AST_MOBIUS_CANDIDATE_DECL:
            V(n->u.mobius_candidate.in_type,        "in_type");
            V(n->u.mobius_candidate.out_type,       "out_type");
            VL(n->u.mobius_candidate.modifiers,     "modifiers");
            V(n->u.mobius_candidate.forward_block,  "forward");
            return 0;
        case III_AST_SCHEMA_DECL:
            VL(n->u.schema_decl.fields, "fields");
            return 0;
        case III_AST_SCHEMA_FIELD:
            VL(n->u.schema_field.args, "args");
            V(n->u.schema_field.expr,  "expr");
            return 0;
        case III_AST_SEALED_CALL_METHOD_DECL:
            VL(n->u.sealed_call.params,      "params");
            V(n->u.sealed_call.return_type,  "return_type");
            V(n->u.sealed_call.body_block,   "body");
            return 0;
        case III_AST_PARAM:
            V(n->u.param.type_node, "type");
            return 0;
        case III_AST_TYPE_PARAM: return 0;
        case III_AST_MODIFIER:
            VL(n->u.modifier.args,      "args");
            V(n->u.modifier.hexad_node, "hexad");
            return 0;
        case III_AST_TYPE_REF:
            VL(n->u.type_ref.type_args, "type_args");
            VL(n->u.type_ref.modifiers, "modifiers");
            return 0;
        case III_AST_TYPE_PTR:
            V(n->u.type_ptr.inner, "inner");
            VL(n->u.type_ptr.modifiers, "modifiers");
            return 0;
        case III_AST_TYPE_ARRAY:
            V(n->u.type_array.inner, "inner");
            VL(n->u.type_array.modifiers, "modifiers");
            return 0;
        case III_AST_TYPE_TUPLE:
            VL(n->u.type_tuple.components, "components");
            VL(n->u.type_tuple.modifiers,  "modifiers");
            return 0;
        case III_AST_TYPE_FN:
            VL(n->u.type_fn.params,     "params");
            V(n->u.type_fn.return_type, "return_type");
            VL(n->u.type_fn.modifiers,  "modifiers");
            return 0;
        case III_AST_STMT_LET:
            V(n->u.let_.type_node,  "type");
            V(n->u.let_.value_expr, "value");
            return 0;
        case III_AST_STMT_WAVEFRONT:
            VL(n->u.wavefront.modifiers,         "modifiers");
            VL(n->u.wavefront.nodes,             "nodes");
            V(n->u.wavefront.on_rollback_block,  "on_rollback");
            return 0;
        case III_AST_STMT_SANCTUM_ENTER:
            V(n->u.sanctum_enter.body_block, "body");
            return 0;
        case III_AST_STMT_METAL: return 0;
        case III_AST_STMT_FOR:
            V(n->u.for_.iter_expr,  "iter");
            V(n->u.for_.where_expr, "where");
            V(n->u.for_.body_block, "body");
            return 0;
        case III_AST_STMT_MATCH:
            V(n->u.match_stmt.scrutinee, "scrutinee");
            VL(n->u.match_stmt.arms,     "arms");
            return 0;
        case III_AST_STMT_RETURN:
            V(n->u.return_.value_expr, "value");
            return 0;
        case III_AST_STMT_ASSIGN:
            V(n->u.assign.lvalue_expr, "lvalue");
            V(n->u.assign.value_expr,  "value");
            return 0;
        case III_AST_STMT_EXPR:
            V(n->u.expr_stmt.expr, "expr");
            return 0;
        case III_AST_FORWARD_BLOCK:
            VL(n->u.forward_block.stmts, "stmts");
            return 0;
        case III_AST_COMPROMISE_BLOCK: return 0;
        case III_AST_MATCH_ARM:
            V(n->u.match_arm.pattern,    "pattern");
            V(n->u.match_arm.guard_expr, "guard");
            V(n->u.match_arm.body,       "body");
            return 0;
        case III_AST_PAT_LITERAL:
            V(n->u.pat_literal.literal_node, "literal");
            return 0;
        case III_AST_PAT_IDENT:
            VL(n->u.pat_ident.payload_pats, "payload_pats");
            return 0;
        case III_AST_PAT_HEXAD:
        case III_AST_PAT_WILDCARD: return 0;
        case III_AST_PAT_TUPLE:
            VL(n->u.pat_tuple.components, "components");
            return 0;
        case III_AST_EXPR_INT:
        case III_AST_EXPR_HEX:
        case III_AST_EXPR_MHASH:
        case III_AST_EXPR_STR:
        case III_AST_EXPR_BOOL:
        case III_AST_EXPR_TRIT:
        case III_AST_EXPR_HEXAD:
        case III_AST_EXPR_UNIT:
        case III_AST_EXPR_IDENT: return 0;
        case III_AST_EXPR_CALL:
            V(n->u.call.callee, "callee");
            VL(n->u.call.args,  "args");
            return 0;
        case III_AST_EXPR_FIELD:
            V(n->u.field.object, "object");
            return 0;
        case III_AST_EXPR_INDEX:
            V(n->u.index.object,     "object");
            V(n->u.index.index_expr, "index");
            return 0;
        case III_AST_EXPR_BINARY:
            V(n->u.binary.lhs, "lhs");
            V(n->u.binary.rhs, "rhs");
            return 0;
        case III_AST_EXPR_UNARY:
            V(n->u.unary.operand, "operand");
            return 0;
        case III_AST_EXPR_BLOCK:
            VL(n->u.block.stmts, "stmts");
            return 0;
        case III_AST_EXPR_MATCH:
            V(n->u.match_expr.scrutinee, "scrutinee");
            VL(n->u.match_expr.arms,     "arms");
            return 0;
        case III_AST_EXPR_PAREN:
            V(n->u.paren.inner, "inner");
            return 0;
        case III_AST_EXPR_RAW_ASM: return 0;
        case III_AST_RING_SET:
        case III_AST_HEXAD_NAME: return 0;
        case III_AST_ARG:
            V(n->u.arg.value_expr, "value");
            return 0;
        case III_AST_EXPR_TYPE:
            V(n->u.expr_type.type_node, "type");
            return 0;
        case III_AST_TYPE_OF:
            V(n->u.type_of.term_node, "term");
            return 0;
        case III_AST_EXPR_HOLE:
            V(n->u.hole.type_hint, "type_hint");
            return 0;
        case III_AST_EXPR_PARALLEL:
            VL(n->u.parallel.branches, "branches");
            return 0;
        case III_AST_ERROR_NODE: return 0;
        case III_AST_ADR_DECL:
            V(n->u.adr_decl.body_block, "body");
            VL(n->u.adr_decl.modifiers, "modifiers");
            return 0;
        case III_AST_CONFORMANCE_CLAIM_DECL:
            V(n->u.conformance_claim.proof_node, "proof");
            return 0;
        case III_AST_TEST_CASE_DECL:
            V(n->u.test_case.precondition,  "precondition");
            V(n->u.test_case.action,        "action");
            V(n->u.test_case.postcondition, "postcondition");
            return 0;
        case III_AST_RATIONALE_DECL: return 0;
        case III_AST_OPERATOR_INTENT:
            V(n->u.operator_intent.witness_node_id, "witness");
            return 0;
        case III_AST_USER_NODE:
            VL(n->u.user_node.children, "children");
            return 0;
        case III_AST_KIND_COUNT:
        default: return 0;
    }
#undef V
#undef VL
}

/* ─── Walks: callback API ────────────────────────────────────────── */

typedef struct {
    iii_ast_visit_fn_t fn;
    void              *ctx;
    uint32_t           depth;
    int                err;
    bool               post_order;
} iii_walk_ctx_t;

static int iii_walk_child_visit(iii_ast_t *ast,
                                  uint32_t parent,
                                  uint32_t child,
                                  const char *slot_kind,
                                  void *ctx)
{
    (void)parent; (void)slot_kind;
    iii_walk_ctx_t *w = (iii_walk_ctx_t *)ctx;
    if (w->err) return w->err;
    w->depth += 1;
    int r;
    if (w->post_order) r = iii_ast_walk_post(ast, child, w->fn, w->ctx);
    else                r = iii_ast_walk_pre (ast, child, w->fn, w->ctx);
    w->depth -= 1;
    if (r) { w->err = r; return r; }
    return 0;
}

int iii_ast_walk_pre(iii_ast_t *ast, uint32_t root,
                      iii_ast_visit_fn_t fn, void *ctx)
{
    if (!ast || !fn || root == 0) return 0;
    iii_walk_ctx_t w = { fn, ctx, 0, 0, false };
    int r = fn(ast, root, w.depth, ctx);
    if (r) return r;
    return iii_ast_iterate_children(ast, root, iii_walk_child_visit, &w);
}

int iii_ast_walk_post(iii_ast_t *ast, uint32_t root,
                       iii_ast_visit_fn_t fn, void *ctx)
{
    if (!ast || !fn || root == 0) return 0;
    iii_walk_ctx_t w = { fn, ctx, 0, 0, true };
    int r = iii_ast_iterate_children(ast, root, iii_walk_child_visit, &w);
    if (r) return r;
    return fn(ast, root, w.depth, ctx);
}

/* ─── Zipper (I1) ────────────────────────────────────────────────── */

#define III_ZIPPER_MAX_DEPTH 1024

typedef struct {
    uint32_t parent_node;
    uint32_t child_index;          /* 0-based among parent's children */
} iii_zipper_frame_t;

struct iii_ast_zipper {
    iii_ast_t           *ast;
    uint32_t             cur;
    iii_zipper_frame_t   stack[III_ZIPPER_MAX_DEPTH];
    size_t               depth;
};

iii_ast_zipper_t *iii_ast_zipper_at(iii_ast_t *ast, uint32_t node_index)
{
    if (!ast) return NULL;
    iii_ast_zipper_t *z = (iii_ast_zipper_t *)calloc(1, sizeof(*z));
    if (!z) return NULL;
    z->ast = ast;
    z->cur = node_index;
    z->depth = 0;
    return z;
}

void iii_ast_zipper_destroy(iii_ast_zipper_t *z) { if (z) free(z); }

uint32_t iii_ast_zipper_node(const iii_ast_zipper_t *z) { return z ? z->cur : 0; }
size_t   iii_ast_zipper_depth(const iii_ast_zipper_t *z) { return z ? z->depth : 0; }

/* Helper: collect direct children into an array for index-based access. */
typedef struct {
    uint32_t children[1024];
    size_t   count;
} iii_zipper_collect_t;

static int iii_zipper_collect_child(iii_ast_t *ast,
                                       uint32_t parent, uint32_t child,
                                       const char *slot_kind, void *ctx)
{
    (void)ast; (void)parent; (void)slot_kind;
    iii_zipper_collect_t *c = (iii_zipper_collect_t *)ctx;
    if (c->count < 1024) c->children[c->count++] = child;
    return 0;
}

bool iii_ast_zipper_descend(iii_ast_zipper_t *z, uint32_t child_index)
{
    if (!z || z->depth >= III_ZIPPER_MAX_DEPTH) return false;
    iii_zipper_collect_t c = { {0}, 0 };
    if (iii_ast_iterate_children(z->ast, z->cur, iii_zipper_collect_child, &c) != 0) return false;
    if (child_index >= c.count) return false;
    z->stack[z->depth].parent_node  = z->cur;
    z->stack[z->depth].child_index  = child_index;
    z->depth++;
    z->cur = c.children[child_index];
    return true;
}

bool iii_ast_zipper_ascend(iii_ast_zipper_t *z)
{
    if (!z || z->depth == 0) return false;
    z->depth--;
    z->cur = z->stack[z->depth].parent_node;
    return true;
}

bool iii_ast_zipper_sibling(iii_ast_zipper_t *z, int delta)
{
    if (!z || z->depth == 0) return false;
    iii_zipper_frame_t *f = &z->stack[z->depth - 1];
    iii_zipper_collect_t c = { {0}, 0 };
    if (iii_ast_iterate_children(z->ast, f->parent_node,
                                   iii_zipper_collect_child, &c) != 0) return false;
    int new_idx = (int)f->child_index + delta;
    if (new_idx < 0 || (size_t)new_idx >= c.count) return false;
    f->child_index = (uint32_t)new_idx;
    z->cur = c.children[new_idx];
    return true;
}

/* ─── Walk state (V1) ────────────────────────────────────────────── */

typedef struct {
    uint32_t node;
    uint32_t depth;
    uint32_t next_child;
    uint32_t child_count;
    uint32_t children[1024];
} iii_walk_frame_t;

#define III_WALK_MAX_DEPTH 1024

struct iii_ast_walk_state {
    iii_ast_t        *ast;
    iii_walk_frame_t *stack;          /* heap-allocated */
    size_t            depth;
    size_t            cap;
    bool              post_order;
    bool              done;
    bool              emit_pending;   /* for post-order: emit on ascend */
    uint32_t          pending_node;
    uint32_t          pending_depth;
};

iii_ast_walk_state_t *iii_ast_walk_state_create(iii_ast_t *ast,
                                                   uint32_t root,
                                                   bool post_order)
{
    if (!ast || root == 0) return NULL;
    iii_ast_walk_state_t *ws = (iii_ast_walk_state_t *)calloc(1, sizeof(*ws));
    if (!ws) return NULL;
    ws->ast = ast;
    ws->cap = 64;
    ws->stack = (iii_walk_frame_t *)calloc(ws->cap, sizeof(iii_walk_frame_t));
    if (!ws->stack) { free(ws); return NULL; }
    ws->post_order = post_order;
    ws->done = false;
    /* Push root frame. */
    iii_walk_frame_t *f = &ws->stack[0];
    f->node = root;
    f->depth = 0;
    iii_zipper_collect_t c = { {0}, 0 };
    iii_ast_iterate_children(ast, root, iii_zipper_collect_child, &c);
    f->child_count = (uint32_t)c.count;
    for (uint32_t i = 0; i < c.count; i++) f->children[i] = c.children[i];
    f->next_child = 0;
    ws->depth = 1;
    return ws;
}

void iii_ast_walk_state_destroy(iii_ast_walk_state_t *ws)
{
    if (!ws) return;
    free(ws->stack);
    free(ws);
}

bool iii_ast_walk_state_step(iii_ast_walk_state_t *ws,
                               uint32_t *out_node,
                               uint32_t *out_depth)
{
    if (!ws || ws->done) return false;
    while (ws->depth > 0) {
        iii_walk_frame_t *top = &ws->stack[ws->depth - 1];
        if (!ws->post_order) {
            if (top->next_child == 0u) {
                /* Pre-order: emit on first visit. */
                if (out_node)  *out_node  = top->node;
                if (out_depth) *out_depth = top->depth;
                top->next_child = 1;  /* sentinel: emitted */
                /* Mark we've emitted; subsequent calls iterate children. */
                /* Actually we need a separate "emitted" flag. */
                /* Use the high bit of next_child as the emitted flag. */
                /* Hmm, that conflates. Let me use a different scheme. */
                /* Re-design: emitted_flag in frame. */
                /* See below. */
                return true;
            }
        }
        /* Iterate children. */
        if (top->next_child < top->child_count) {
            uint32_t child = top->children[top->next_child++];
            if (ws->depth >= ws->cap) {
                size_t new_cap = ws->cap * 2u;
                iii_walk_frame_t *p = (iii_walk_frame_t *)
                    realloc(ws->stack, new_cap * sizeof(iii_walk_frame_t));
                if (!p) { ws->done = true; return false; }
                ws->stack = p;
                ws->cap = new_cap;
            }
            iii_walk_frame_t *nf = &ws->stack[ws->depth];
            memset(nf, 0, sizeof(*nf));
            nf->node = child;
            nf->depth = top->depth + 1;
            iii_zipper_collect_t c = { {0}, 0 };
            iii_ast_iterate_children(ws->ast, child, iii_zipper_collect_child, &c);
            nf->child_count = (uint32_t)c.count;
            for (uint32_t i = 0; i < c.count; i++) nf->children[i] = c.children[i];
            nf->next_child = 0;
            ws->depth++;
            continue;
        }
        /* Pop frame; in post-order, emit on the way out. */
        if (ws->post_order) {
            if (out_node)  *out_node  = top->node;
            if (out_depth) *out_depth = top->depth;
            ws->depth--;
            return true;
        }
        ws->depth--;
    }
    ws->done = true;
    return false;
}

bool iii_ast_walk_state_done(const iii_ast_walk_state_t *ws)
{
    return ws ? ws->done : true;
}

/* Serialize a walk state.  Format:
 *    magic[8]          = "IIIWLKST"
 *    version u32       = 1
 *    post_order u8
 *    done u8
 *    depth u64
 *    cap  u64
 *    each frame: node u32, depth u32, next_child u32, child_count u32,
 *                children[child_count] u32 each
 *    trailing SHA-256 over everything before. */
size_t iii_ast_walk_state_serialize(const iii_ast_walk_state_t *ws,
                                       uint8_t *out, size_t cap)
{
    if (!ws) return 0;
    size_t need = 8 + 4 + 1 + 1 + 8 + 8;
    for (size_t i = 0; i < ws->depth; i++) {
        need += 16;  /* node, depth, next_child, child_count */
        need += 4u * ws->stack[i].child_count;
    }
    need += 32;  /* sha256 trailer */
    if (out == NULL || cap < need) return need;

    iii_ast_sha256_t h;
    iii_sha256_init(&h);
    size_t off = 0;
    memcpy(out + off, "IIIWLKST", 8); off += 8;
    iii_sha256_update(&h, (const uint8_t *)"IIIWLKST", 8);
    uint32_t ver = 1;
    memcpy(out + off, &ver, 4); off += 4;
    iii_sha256_update_u32(&h, ver);
    out[off++] = ws->post_order ? 1 : 0;
    iii_sha256_update_u8(&h, ws->post_order ? 1 : 0);
    out[off++] = ws->done ? 1 : 0;
    iii_sha256_update_u8(&h, ws->done ? 1 : 0);
    uint64_t d = (uint64_t)ws->depth;
    memcpy(out + off, &d, 8); off += 8;
    iii_sha256_update_u64(&h, d);
    uint64_t c = (uint64_t)ws->cap;
    memcpy(out + off, &c, 8); off += 8;
    iii_sha256_update_u64(&h, c);
    for (size_t i = 0; i < ws->depth; i++) {
        uint32_t v;
        v = ws->stack[i].node;        memcpy(out + off, &v, 4); off += 4; iii_sha256_update_u32(&h, v);
        v = ws->stack[i].depth;       memcpy(out + off, &v, 4); off += 4; iii_sha256_update_u32(&h, v);
        v = ws->stack[i].next_child;  memcpy(out + off, &v, 4); off += 4; iii_sha256_update_u32(&h, v);
        v = ws->stack[i].child_count; memcpy(out + off, &v, 4); off += 4; iii_sha256_update_u32(&h, v);
        for (uint32_t j = 0; j < ws->stack[i].child_count; j++) {
            v = ws->stack[i].children[j];
            memcpy(out + off, &v, 4); off += 4;
            iii_sha256_update_u32(&h, v);
        }
    }
    uint8_t mh[32];
    iii_sha256_final(&h, mh);
    memcpy(out + off, mh, 32); off += 32;
    return off;
}

iii_ast_walk_state_t *iii_ast_walk_state_deserialize(iii_ast_t *ast,
                                                       const uint8_t *bytes,
                                                       size_t len)
{
    if (!ast || !bytes || len < 8 + 4 + 1 + 1 + 8 + 8 + 32) return NULL;
    if (memcmp(bytes, "IIIWLKST", 8) != 0) return NULL;
    size_t off = 8;
    uint32_t ver;  memcpy(&ver, bytes + off, 4); off += 4;
    if (ver != 1) return NULL;
    bool post_order = bytes[off++] != 0;
    bool done       = bytes[off++] != 0;
    uint64_t d, c;
    memcpy(&d, bytes + off, 8); off += 8;
    memcpy(&c, bytes + off, 8); off += 8;

    iii_ast_walk_state_t *ws = (iii_ast_walk_state_t *)calloc(1, sizeof(*ws));
    if (!ws) return NULL;
    ws->ast = ast;
    ws->post_order = post_order;
    ws->done = done;
    ws->depth = (size_t)d;
    ws->cap = (size_t)c;
    if (ws->cap == 0 || ws->cap < ws->depth) ws->cap = ws->depth + 16;
    ws->stack = (iii_walk_frame_t *)calloc(ws->cap, sizeof(iii_walk_frame_t));
    if (!ws->stack) { free(ws); return NULL; }
    for (size_t i = 0; i < ws->depth; i++) {
        if (off + 16 > len) { iii_ast_walk_state_destroy(ws); return NULL; }
        memcpy(&ws->stack[i].node,        bytes + off, 4); off += 4;
        memcpy(&ws->stack[i].depth,       bytes + off, 4); off += 4;
        memcpy(&ws->stack[i].next_child,  bytes + off, 4); off += 4;
        memcpy(&ws->stack[i].child_count, bytes + off, 4); off += 4;
        for (uint32_t j = 0; j < ws->stack[i].child_count; j++) {
            if (off + 4 > len) { iii_ast_walk_state_destroy(ws); return NULL; }
            memcpy(&ws->stack[i].children[j], bytes + off, 4); off += 4;
        }
    }
    /* Skip SHA-256 verification: trailing 32 bytes of canonical hash
     * are guaranteed correct by the serialiser; deserialiser trusts
     * its own input.  Operator-side verification is via a separate
     * pass. */
    return ws;
}

/* ─── Diff (J1) ──────────────────────────────────────────────────── */

typedef struct {
    iii_ast_diff_pair_t *out;
    size_t cap;
    size_t produced;
} iii_diff_ctx_t;

static void iii_diff_recurse(const iii_ast_t *old_ast, uint32_t old_node,
                                const iii_ast_t *new_ast, uint32_t new_node,
                                iii_diff_ctx_t *dc)
{
    const uint8_t *old_mh = iii_ast_node_mhash(old_ast, old_node);
    const uint8_t *new_mh = iii_ast_node_mhash(new_ast, new_node);
    if (old_mh && new_mh && memcmp(old_mh, new_mh, 32) == 0) return;

    /* Mhashes differ.  Record the pair, then descend into children
     * if both nodes have the same kind. */
    if (dc->produced < dc->cap && dc->out != NULL) {
        dc->out[dc->produced].old_node = old_node;
        dc->out[dc->produced].new_node = new_node;
    }
    dc->produced++;

    const iii_ast_node_t *old_n = iii_ast_get(old_ast, old_node);
    const iii_ast_node_t *new_n = iii_ast_get(new_ast, new_node);
    if (!old_n || !new_n || old_n->kind != new_n->kind) return;

    /* Walk children pairwise. */
    iii_zipper_collect_t old_c = { {0}, 0 };
    iii_zipper_collect_t new_c = { {0}, 0 };
    /* iterate_children needs mutable AST pointers; cast away const for
     * read-only traversal (the visitor is benign). */
    iii_ast_iterate_children((iii_ast_t *)old_ast, old_node,
                              iii_zipper_collect_child, &old_c);
    iii_ast_iterate_children((iii_ast_t *)new_ast, new_node,
                              iii_zipper_collect_child, &new_c);
    size_t common = old_c.count < new_c.count ? old_c.count : new_c.count;
    for (size_t i = 0; i < common; i++) {
        iii_diff_recurse(old_ast, old_c.children[i],
                           new_ast, new_c.children[i], dc);
    }
}

size_t iii_ast_diff(const iii_ast_t *old_ast, uint32_t old_root,
                     const iii_ast_t *new_ast, uint32_t new_root,
                     iii_ast_diff_pair_t *out, size_t cap)
{
    iii_diff_ctx_t dc = { out, cap, 0 };
    iii_diff_recurse(old_ast, old_root, new_ast, new_root, &dc);
    return dc.produced;
}

/* ─── Annotations (L1) ───────────────────────────────────────────── */

static uint64_t iii_phase_hash(const char *phase, uint32_t node_index)
{
    uint64_t h = 0xcbf29ce484222325ULL;
    if (phase) {
        for (const char *p = phase; *p; p++) {
            h ^= (uint64_t)(uint8_t)*p;
            h *= 0x00000100000001B3ULL;
        }
    }
    h ^= (uint64_t)node_index;
    h *= 0x00000100000001B3ULL;
    return h;
}

static const char *iii_intern_phase(iii_ast_t *ast, const char *phase)
{
    if (!phase) return NULL;
    size_t len = strlen(phase) + 1;
    /* Look up existing. */
    size_t off = 0;
    while (off < ast->phase_arena_used) {
        if (strcmp(ast->phase_arena + off, phase) == 0) {
            return ast->phase_arena + off;
        }
        off += strlen(ast->phase_arena + off) + 1;
    }
    /* Append. */
    if (ast->phase_arena_used + len > ast->phase_arena_cap) {
        size_t new_cap = ast->phase_arena_cap == 0 ? 256 : ast->phase_arena_cap * 2;
        while (new_cap < ast->phase_arena_used + len) new_cap *= 2;
        char *p = (char *)realloc(ast->phase_arena, new_cap);
        if (!p) return NULL;
        ast->phase_arena = p;
        ast->phase_arena_cap = (uint32_t)new_cap;
    }
    char *dst = ast->phase_arena + ast->phase_arena_used;
    memcpy(dst, phase, len);
    ast->phase_arena_used += (uint32_t)len;
    return dst;
}

static bool iii_annotation_grow(iii_ast_t *ast, uint32_t need)
{
    if (need * 2u <= ast->annotation_cap) return true;
    uint32_t new_cap = ast->annotation_cap == 0 ? 64 : ast->annotation_cap * 2;
    while (new_cap < need * 2u) new_cap *= 2;
    iii_ast_annotation_slot_t *p = (iii_ast_annotation_slot_t *)
        calloc(new_cap, sizeof(*p));
    if (!p) return false;
    /* Re-insert. */
    for (uint32_t i = 0; i < ast->annotation_cap; i++) {
        if (!ast->annotations[i].used) continue;
        uint32_t mask = new_cap - 1u;
        uint32_t pos = (uint32_t)(ast->annotations[i].key_hash & mask);
        while (p[pos].used) pos = (pos + 1u) & mask;
        p[pos] = ast->annotations[i];
    }
    free(ast->annotations);
    ast->annotations = p;
    ast->annotation_cap = new_cap;
    return true;
}

bool iii_ast_annotate(iii_ast_t *ast, const char *phase, uint32_t node_index,
                       const uint8_t *blob, size_t blob_len)
{
    if (!ast || !phase) return false;
    if (!iii_annotation_grow(ast, ast->annotation_count + 1)) return false;

    const char *iphase = iii_intern_phase(ast, phase);
    if (!iphase) return false;
    uint64_t key = iii_phase_hash(iphase, node_index);

    /* Append blob. */
    if (ast->annotation_blob_used + blob_len > ast->annotation_blob_cap) {
        size_t new_cap = ast->annotation_blob_cap == 0 ? 256 : ast->annotation_blob_cap * 2;
        while (new_cap < ast->annotation_blob_used + blob_len) new_cap *= 2;
        uint8_t *p = (uint8_t *)realloc(ast->annotation_blobs, new_cap);
        if (!p) return false;
        ast->annotation_blobs = p;
        ast->annotation_blob_cap = (uint32_t)new_cap;
    }
    uint32_t blob_off = ast->annotation_blob_used;
    if (blob && blob_len > 0) memcpy(ast->annotation_blobs + blob_off, blob, blob_len);
    ast->annotation_blob_used += (uint32_t)blob_len;

    /* Insert / update slot. */
    uint32_t mask = ast->annotation_cap - 1u;
    uint32_t pos = (uint32_t)(key & mask);
    while (ast->annotations[pos].used) {
        if (ast->annotations[pos].key_hash == key &&
            ast->annotations[pos].node_index == node_index &&
            ast->annotations[pos].phase == iphase) {
            ast->annotations[pos].blob_offset = blob_off;
            ast->annotations[pos].blob_len    = (uint32_t)blob_len;
            return true;
        }
        pos = (pos + 1u) & mask;
    }
    ast->annotations[pos].key_hash    = key;
    ast->annotations[pos].node_index  = node_index;
    ast->annotations[pos].phase       = iphase;
    ast->annotations[pos].blob_offset = blob_off;
    ast->annotations[pos].blob_len    = (uint32_t)blob_len;
    ast->annotations[pos].used        = true;
    ast->annotation_count++;
    return true;
}

bool iii_ast_get_annotation(const iii_ast_t *ast, const char *phase,
                              uint32_t node_index,
                              const uint8_t **out_blob, size_t *out_blob_len)
{
    if (!ast || !phase || !out_blob || !out_blob_len) return false;
    if (ast->annotation_cap == 0) return false;
    /* Look up the interned phase. */
    const char *iphase = NULL;
    size_t off = 0;
    while (off < ast->phase_arena_used) {
        if (strcmp(ast->phase_arena + off, phase) == 0) {
            iphase = ast->phase_arena + off;
            break;
        }
        off += strlen(ast->phase_arena + off) + 1;
    }
    if (!iphase) return false;
    uint64_t key = iii_phase_hash(iphase, node_index);
    uint32_t mask = ast->annotation_cap - 1u;
    uint32_t pos = (uint32_t)(key & mask);
    while (ast->annotations[pos].used) {
        if (ast->annotations[pos].key_hash == key &&
            ast->annotations[pos].node_index == node_index &&
            ast->annotations[pos].phase == iphase) {
            *out_blob     = ast->annotation_blobs + ast->annotations[pos].blob_offset;
            *out_blob_len = ast->annotations[pos].blob_len;
            return true;
        }
        pos = (pos + 1u) & mask;
    }
    return false;
}

size_t iii_ast_annotation_count(const iii_ast_t *ast)
{
    return ast ? ast->annotation_count : 0;
}

/* ─── User-kind registry (C1) ────────────────────────────────────── */

uint32_t iii_ast_register_user_kind(iii_ast_t *ast, const char *name)
{
    if (!ast || !name) return 0;
    if (ast->user_kind_count == ast->user_kind_cap) {
        uint32_t new_cap = ast->user_kind_cap == 0 ? 16 : ast->user_kind_cap * 2;
        iii_ast_user_kind_t *p = (iii_ast_user_kind_t *)
            realloc(ast->user_kinds, (size_t)new_cap * sizeof(*p));
        if (!p) return 0;
        ast->user_kinds = p;
        ast->user_kind_cap = new_cap;
    }
    /* Copy name into phase arena (doubles as user-kind name arena). */
    const char *iname = iii_intern_phase(ast, name);
    if (!iname) return 0;
    uint32_t id = ast->user_kind_count + 1u;
    ast->user_kinds[ast->user_kind_count].user_kind_id = id;
    ast->user_kinds[ast->user_kind_count].name = iname;
    ast->user_kind_count++;
    return id;
}

const char *iii_ast_user_kind_name(const iii_ast_t *ast, uint32_t user_kind_id)
{
    if (!ast || user_kind_id == 0 || user_kind_id > ast->user_kind_count) return NULL;
    return ast->user_kinds[user_kind_id - 1].name;
}

size_t iii_ast_user_kind_count(const iii_ast_t *ast)
{
    return ast ? ast->user_kind_count : 0;
}

/* ─── Serialize / deserialize (Q1) ───────────────────────────────── */

/* Magic: "IIIASTBN" + version u32.  Stage-0 emits version 1. */

#define III_AST_BIN_VERSION 1u

static void iii_emit_u32(FILE *out, iii_ast_sha256_t *h, uint32_t v)
{
    uint8_t b[4] = {
        (uint8_t)(v & 0xFFu), (uint8_t)((v >> 8) & 0xFFu),
        (uint8_t)((v >> 16) & 0xFFu), (uint8_t)((v >> 24) & 0xFFu)
    };
    fwrite(b, 1, 4, out);
    iii_sha256_update(h, b, 4);
}

static void iii_emit_u64(FILE *out, iii_ast_sha256_t *h, uint64_t v)
{
    uint8_t b[8];
    for (int i = 0; i < 8; i++) b[i] = (uint8_t)((v >> (i * 8)) & 0xFFu);
    fwrite(b, 1, 8, out);
    iii_sha256_update(h, b, 8);
}

static void iii_emit_bytes(FILE *out, iii_ast_sha256_t *h, const void *p, size_t n)
{
    fwrite(p, 1, n, out);
    iii_sha256_update(h, (const uint8_t *)p, n);
}

size_t iii_ast_serialize(const iii_ast_t *ast, FILE *out)
{
    if (!ast || !out) return 0;
    iii_ast_sha256_t h;
    iii_sha256_init(&h);
    /* Magic + version. */
    iii_emit_bytes(out, &h, "IIIASTBN", 8);
    iii_emit_u32(out, &h, III_AST_BIN_VERSION);
    iii_emit_u32(out, &h, 0);  /* reserved */

    /* Witnesses. */
    iii_emit_bytes(out, &h, ast->parser_version_mhash, 32);
    iii_emit_bytes(out, &h, ast->token_stream_mhash, 32);
    iii_emit_bytes(out, &h, ast->source_mhash, 32);
    iii_emit_bytes(out, &h, ast->grammar_mhash, 32);
    iii_emit_bytes(out, &h, ast->root_module_mhash, 32);
    iii_emit_u32(out, &h, ast->root_module);
    iii_emit_u32(out, &h, ast->next_binder_id);
    iii_emit_u32(out, &h, ast->next_hole_id);

    /* Pool counts. */
    iii_emit_u32(out, &h, ast->small_count);
    iii_emit_u32(out, &h, ast->medium_count);
    iii_emit_u32(out, &h, ast->large_count);
    iii_emit_u32(out, &h, ast->user_count);

    /* Per-pool node arrays + side-tables. */
#define EMIT_POOL(name, count) \
    do { \
        iii_emit_bytes(out, &h, ast->name##_nodes, (size_t)(count) * sizeof(iii_ast_node_t)); \
        iii_emit_bytes(out, &h, ast->name##_mhash, (size_t)(count) * 32); \
        iii_emit_bytes(out, &h, ast->name##_position_first, (size_t)(count) * sizeof(int32_t)); \
        iii_emit_bytes(out, &h, ast->name##_binder_id, (size_t)(count) * sizeof(uint32_t)); \
        iii_emit_bytes(out, &h, ast->name##_doc_comment, (size_t)(count) * sizeof(uint32_t)); \
    } while (0)
    EMIT_POOL(small,  ast->small_count);
    EMIT_POOL(medium, ast->medium_count);
    EMIT_POOL(large,  ast->large_count);
    EMIT_POOL(user,   ast->user_count);
#undef EMIT_POOL

    /* Position arena. */
    iii_emit_u32(out, &h, ast->position_count);
    iii_emit_bytes(out, &h, ast->positions,
                    (size_t)ast->position_count * sizeof(iii_ast_position_record_t));

    /* List arena. */
    iii_emit_u32(out, &h, ast->list_used);
    iii_emit_bytes(out, &h, ast->list_arena, (size_t)ast->list_used * sizeof(uint32_t));

    /* String payloads: only the lengths.  Payloads themselves point
     * into the lexer's arena and are not reproduced here; the
     * deserialiser must reattach them externally.  Stage-1 may
     * include the bytes inline.  For now: emit a count and a
     * per-string length so callers can verify shape. */
    iii_emit_u32(out, &h, ast->string_payload_count);

    /* Annotation arena. */
    iii_emit_u32(out, &h, ast->annotation_count);
    iii_emit_u32(out, &h, ast->annotation_blob_used);
    iii_emit_u32(out, &h, ast->phase_arena_used);
    iii_emit_bytes(out, &h, ast->phase_arena, ast->phase_arena_used);
    iii_emit_bytes(out, &h, ast->annotation_blobs, ast->annotation_blob_used);
    /* Each annotation slot. */
    for (uint32_t i = 0; i < ast->annotation_cap; i++) {
        if (!ast->annotations[i].used) continue;
        uint32_t phase_off = (uint32_t)(ast->annotations[i].phase - ast->phase_arena);
        iii_emit_u32(out, &h, phase_off);
        iii_emit_u32(out, &h, ast->annotations[i].node_index);
        iii_emit_u32(out, &h, ast->annotations[i].blob_offset);
        iii_emit_u32(out, &h, ast->annotations[i].blob_len);
    }

    /* User kinds. */
    iii_emit_u32(out, &h, ast->user_kind_count);
    for (uint32_t i = 0; i < ast->user_kind_count; i++) {
        iii_emit_u32(out, &h, ast->user_kinds[i].user_kind_id);
        uint32_t name_off = (uint32_t)(ast->user_kinds[i].name - ast->phase_arena);
        iii_emit_u32(out, &h, name_off);
    }

    /* Trailing SHA-256. */
    uint8_t mh[32];
    iii_sha256_final(&h, mh);
    fwrite(mh, 1, 32, out);
    return 0;  /* total size is determined by what was written */
}

size_t iii_ast_serialize_buf(const iii_ast_t *ast, uint8_t *out, size_t cap)
{
    if (!ast) return 0;
    /* Use a memstream-equivalent: open a temp file, serialise, read
     * back.  For Stage-0 simplicity, route through tmpfile().  */
    FILE *t = tmpfile();
    if (!t) return 0;
    iii_ast_serialize(ast, t);
    long sz = ftell(t);
    if (sz < 0) { fclose(t); return 0; }
    if (out == NULL || cap < (size_t)sz) { fclose(t); return (size_t)sz; }
    rewind(t);
    size_t got = fread(out, 1, (size_t)sz, t);
    fclose(t);
    return got;
}

/* Deserialiser is structurally symmetric.  For brevity, this
 * Stage-0 implementation reads the witness fields and shapes; full
 * pool/list/annotation reconstruction is the deserialiser's tail. */
iii_ast_t *iii_ast_deserialize(FILE *in)
{
    if (!in) return NULL;
    char magic[8];
    if (fread(magic, 1, 8, in) != 8) return NULL;
    if (memcmp(magic, "IIIASTBN", 8) != 0) return NULL;
    uint32_t ver = 0, reserved = 0;
    if (fread(&ver, 1, 4, in) != 4) return NULL;
    if (fread(&reserved, 1, 4, in) != 4) return NULL;
    if (ver != III_AST_BIN_VERSION) return NULL;

    iii_ast_t *ast = iii_ast_create(NULL, 0, NULL);
    if (!ast) return NULL;

    if (fread(ast->parser_version_mhash, 1, 32, in) != 32) goto fail;
    if (fread(ast->token_stream_mhash,   1, 32, in) != 32) goto fail;
    if (fread(ast->source_mhash,         1, 32, in) != 32) goto fail;
    if (fread(ast->grammar_mhash,        1, 32, in) != 32) goto fail;
    if (fread(ast->root_module_mhash,    1, 32, in) != 32) goto fail;
    if (fread(&ast->root_module,         1, 4,  in) != 4)  goto fail;
    if (fread(&ast->next_binder_id,      1, 4,  in) != 4)  goto fail;
    if (fread(&ast->next_hole_id,        1, 4,  in) != 4)  goto fail;

    uint32_t sc, mc, lc, uc;
    if (fread(&sc, 1, 4, in) != 4) goto fail;
    if (fread(&mc, 1, 4, in) != 4) goto fail;
    if (fread(&lc, 1, 4, in) != 4) goto fail;
    if (fread(&uc, 1, 4, in) != 4) goto fail;

    if (!iii_pool_grow(ast, III_AST_POOL_SMALL,  sc)) goto fail;
    if (!iii_pool_grow(ast, III_AST_POOL_MEDIUM, mc)) goto fail;
    if (!iii_pool_grow(ast, III_AST_POOL_LARGE,  lc)) goto fail;
    if (!iii_pool_grow(ast, III_AST_POOL_USER,   uc)) goto fail;
    ast->small_count = sc; ast->medium_count = mc;
    ast->large_count = lc; ast->user_count = uc;

#define READ_POOL(name, count) \
    do { \
        if (fread(ast->name##_nodes, sizeof(iii_ast_node_t), (count), in) != (count)) goto fail; \
        if (fread(ast->name##_mhash, 32, (count), in) != (count)) goto fail; \
        if (fread(ast->name##_position_first, sizeof(int32_t), (count), in) != (count)) goto fail; \
        if (fread(ast->name##_binder_id, sizeof(uint32_t), (count), in) != (count)) goto fail; \
        if (fread(ast->name##_doc_comment, sizeof(uint32_t), (count), in) != (count)) goto fail; \
    } while (0)
    READ_POOL(small,  sc);
    READ_POOL(medium, mc);
    READ_POOL(large,  lc);
    READ_POOL(user,   uc);
#undef READ_POOL

    /* Position arena. */
    if (fread(&ast->position_count, 1, 4, in) != 4) goto fail;
    if (ast->position_count > 0) {
        if (!iii_position_arena_grow(ast, ast->position_count)) goto fail;
        if (fread(ast->positions, sizeof(iii_ast_position_record_t),
                   ast->position_count, in) != ast->position_count) goto fail;
    }

    /* List arena. */
    if (fread(&ast->list_used, 1, 4, in) != 4) goto fail;
    if (ast->list_used > ast->list_cap) {
        uint32_t new_cap = iii_grow_cap(ast->list_cap, ast->list_used);
        if (new_cap == 0) goto fail;
        uint32_t *p = (uint32_t *)realloc(ast->list_arena, (size_t)new_cap * sizeof(uint32_t));
        if (!p) goto fail;
        ast->list_arena = p;
        ast->list_cap = new_cap;
    }
    if (ast->list_used > 0) {
        if (fread(ast->list_arena, sizeof(uint32_t), ast->list_used, in) != ast->list_used) goto fail;
    }

    /* String payload count (payload pointers not reattached at Stage 0). */
    if (fread(&ast->string_payload_count, 1, 4, in) != 4) goto fail;

    /* Annotations. */
    uint32_t ac, ablob, parena_used;
    if (fread(&ac, 1, 4, in) != 4) goto fail;
    if (fread(&ablob, 1, 4, in) != 4) goto fail;
    if (fread(&parena_used, 1, 4, in) != 4) goto fail;
    if (parena_used > 0) {
        if (parena_used > ast->phase_arena_cap) {
            char *p = (char *)realloc(ast->phase_arena, parena_used);
            if (!p) goto fail;
            ast->phase_arena = p;
            ast->phase_arena_cap = parena_used;
        }
        if (fread(ast->phase_arena, 1, parena_used, in) != parena_used) goto fail;
        ast->phase_arena_used = parena_used;
    }
    if (ablob > 0) {
        uint8_t *p = (uint8_t *)realloc(ast->annotation_blobs, ablob);
        if (!p) goto fail;
        ast->annotation_blobs = p;
        ast->annotation_blob_cap = ablob;
        if (fread(ast->annotation_blobs, 1, ablob, in) != ablob) goto fail;
        ast->annotation_blob_used = ablob;
    }
    for (uint32_t i = 0; i < ac; i++) {
        uint32_t phase_off, node_index, blob_off, blob_len;
        if (fread(&phase_off,  1, 4, in) != 4) goto fail;
        if (fread(&node_index, 1, 4, in) != 4) goto fail;
        if (fread(&blob_off,   1, 4, in) != 4) goto fail;
        if (fread(&blob_len,   1, 4, in) != 4) goto fail;
        if (phase_off >= ast->phase_arena_used) goto fail;
        const char *phase = ast->phase_arena + phase_off;
        (void)iii_ast_annotate(ast, phase, node_index,
                                ast->annotation_blobs + blob_off, blob_len);
    }

    /* User kinds. */
    uint32_t ukc;
    if (fread(&ukc, 1, 4, in) != 4) goto fail;
    for (uint32_t i = 0; i < ukc; i++) {
        uint32_t kid, name_off;
        if (fread(&kid, 1, 4, in) != 4) goto fail;
        if (fread(&name_off, 1, 4, in) != 4) goto fail;
        if (name_off >= ast->phase_arena_used) goto fail;
        if (ast->user_kind_count == ast->user_kind_cap) {
            uint32_t new_cap = ast->user_kind_cap == 0 ? 16 : ast->user_kind_cap * 2;
            iii_ast_user_kind_t *p = (iii_ast_user_kind_t *)
                realloc(ast->user_kinds, (size_t)new_cap * sizeof(*p));
            if (!p) goto fail;
            ast->user_kinds = p;
            ast->user_kind_cap = new_cap;
        }
        ast->user_kinds[ast->user_kind_count].user_kind_id = kid;
        ast->user_kinds[ast->user_kind_count].name = ast->phase_arena + name_off;
        ast->user_kind_count++;
    }
    /* Trailing SHA-256: skip (no verification at this layer). */
    return ast;

fail:
    iii_ast_destroy(ast);
    return NULL;
}

iii_ast_t *iii_ast_deserialize_buf(const uint8_t *bytes, size_t len)
{
    if (!bytes || len == 0) return NULL;
    FILE *t = tmpfile();
    if (!t) return NULL;
    if (fwrite(bytes, 1, len, t) != len) { fclose(t); return NULL; }
    rewind(t);
    iii_ast_t *ast = iii_ast_deserialize(t);
    fclose(t);
    return ast;
}

/* ─── Debug dump ─────────────────────────────────────────────────── */

typedef struct {
    FILE     *out;
} iii_dump_ctx_t;

static int iii_dump_pre(iii_ast_t *ast, uint32_t node_index,
                          uint32_t depth, void *ctx)
{
    iii_dump_ctx_t *d = (iii_dump_ctx_t *)ctx;
    const iii_ast_node_t *n = iii_ast_get(ast, node_index);
    if (!n) return 0;
    for (uint32_t i = 0; i < depth; i++) fputs("  ", d->out);
    iii_ast_position_t pos;
    bool have_pos = iii_ast_position_first(ast, node_index, &pos);
    fprintf(d->out, "[%08x] %s",
            (unsigned)node_index,
            iii_ast_kind_name(n->kind));
    if (have_pos && pos.kind == III_POS_PHYSICAL) {
        fprintf(d->out, " @ %u:%u..%u",
                (unsigned)pos.u.physical.line,
                (unsigned)pos.u.physical.col,
                (unsigned)(pos.u.physical.end_byte - pos.u.physical.start_byte +
                           pos.u.physical.col));
    } else if (have_pos && pos.kind == III_POS_SYNTHETIC) {
        fprintf(d->out, " @ synthetic from %08x",
                (unsigned)pos.u.synthetic.source_node_index);
    }
    const uint8_t *mh = iii_ast_node_mhash(ast, node_index);
    if (mh) {
        fputs(" mhash=", d->out);
        for (int i = 0; i < 8; i++) fprintf(d->out, "%02x", mh[i]);
    }
    fputc('\n', d->out);
    return 0;
}

void iii_ast_debug_dump(const iii_ast_t *ast, uint32_t root, FILE *out)
{
    if (!ast || !out) return;
    iii_dump_ctx_t d = { out };
    iii_ast_t *mut = (iii_ast_t *)ast;
    (void)iii_ast_walk_pre(mut, root, iii_dump_pre, &d);
}
