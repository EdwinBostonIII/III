/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\lex.c
 *
 * III Stage-0 Lexer — implementation.
 *
 * Companion of lex.h.  See that file for the full public contract,
 * including determinism (D12), termination (D13), recovery (D10),
 * fuzz invariants (D14), and the MHASH/HEX boundary rule (D11).
 *
 * Strict NIH: only <stdint.h>, <stddef.h>, <stdbool.h>, <stdio.h>,
 * <stdlib.h>, <string.h>.  No flex/lex/yacc/regex.  SHA-256 (FIPS
 * 180-4) is hand-rolled below for the D1 token-mhash primitive.
 *
 * Reproducibility: every byte the lexer writes is a pure function of
 * (source, prior calls, registered keywords).  No clock, RNG, or
 * allocator-address leakage.  Stage 2 byte-equivalence depends on
 * this discipline.
 *
 * File extension convention: III source files use the `.III` suffix.
 */

#include "lex.h"

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* ─── SHA-256 (FIPS 180-4) ────────────────────────────────────────── */

/* Hand-rolled SHA-256.  Used by:
 *   - iii_token_mhash      (D1)
 *   - iii_lex_stream_mhash (D1)
 *   - iii_lex_arena_mhash  (D21)
 *
 * Deterministic, no allocations, no globals beyond the round-constant
 * table K below.  ~250 LOC including init/update/final and helpers. */

typedef struct {
    uint32_t h[8];
    uint64_t total_bits;
    uint8_t  buf[64];
    size_t   buf_used;
} iii_sha256_t;

static const uint32_t III_SHA256_K[64] = {
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

static void iii_sha256_compress(iii_sha256_t *s, const uint8_t block[64])
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
        uint32_t t1 = h + S1 + ch + III_SHA256_K[i] + w[i];
        uint32_t S0 = iii_rotr32(a, 2) ^ iii_rotr32(a, 13) ^ iii_rotr32(a, 22);
        uint32_t mj = (a & b) ^ (a & c) ^ (b & c);
        uint32_t t2 = S0 + mj;
        h = g; g = f; f = e; e = d + t1;
        d = c; c = b; b = a; a = t1 + t2;
    }
    s->h[0] += a; s->h[1] += b; s->h[2] += c; s->h[3] += d;
    s->h[4] += e; s->h[5] += f; s->h[6] += g; s->h[7] += h;
}

static void iii_sha256_init(iii_sha256_t *s)
{
    s->h[0] = 0x6a09e667u; s->h[1] = 0xbb67ae85u; s->h[2] = 0x3c6ef372u; s->h[3] = 0xa54ff53au;
    s->h[4] = 0x510e527fu; s->h[5] = 0x9b05688cu; s->h[6] = 0x1f83d9abu; s->h[7] = 0x5be0cd19u;
    s->total_bits = 0;
    s->buf_used = 0;
}

static void iii_sha256_update(iii_sha256_t *s, const uint8_t *data, size_t n)
{
    s->total_bits += (uint64_t)n * 8u;
    if (s->buf_used > 0) {
        size_t fill = 64u - s->buf_used;
        if (fill > n) fill = n;
        memcpy(s->buf + s->buf_used, data, fill);
        s->buf_used += fill;
        data += fill;
        n    -= fill;
        if (s->buf_used == 64u) {
            iii_sha256_compress(s, s->buf);
            s->buf_used = 0;
        }
    }
    while (n >= 64u) {
        iii_sha256_compress(s, data);
        data += 64u;
        n    -= 64u;
    }
    if (n > 0u) {
        memcpy(s->buf, data, n);
        s->buf_used = n;
    }
}

static void iii_sha256_final(iii_sha256_t *s, uint8_t out[32])
{
    /* Append 0x80 then zero-pad until total_len mod 64 == 56, then
     * 8 bytes of total_bits big-endian. */
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

/* Helper: feed a little-endian fixed-width field. */
static void iii_sha256_update_u8 (iii_sha256_t *s, uint8_t  v) { iii_sha256_update(s, &v, 1); }
static void iii_sha256_update_u16(iii_sha256_t *s, uint16_t v) {
    uint8_t b[2] = { (uint8_t)(v & 0xFFu), (uint8_t)((v >> 8) & 0xFFu) };
    iii_sha256_update(s, b, 2);
}
static void iii_sha256_update_u32(iii_sha256_t *s, uint32_t v) {
    uint8_t b[4] = {
        (uint8_t)(v & 0xFFu), (uint8_t)((v >> 8) & 0xFFu),
        (uint8_t)((v >> 16) & 0xFFu), (uint8_t)((v >> 24) & 0xFFu)
    };
    iii_sha256_update(s, b, 4);
}
static void iii_sha256_update_u64(iii_sha256_t *s, uint64_t v) {
    uint8_t b[8];
    for (int i = 0; i < 8; i++) b[i] = (uint8_t)((v >> (i * 8)) & 0xFFu);
    iii_sha256_update(s, b, 8);
}

/* ─── Chunk-list arena (stable pointers) ─────────────────────────── */

#define III_CHUNK_BYTES (64u * 1024u)

typedef struct iii_chunk {
    struct iii_chunk *next;
    size_t            cap;
    size_t            used;
    uint8_t           data[];
} iii_chunk_t;

typedef struct {
    iii_chunk_t *head;
    size_t       total_bytes;
} iii_arena_t;

static iii_chunk_t *iii_chunk_new(size_t want_payload)
{
    size_t cap = III_CHUNK_BYTES;
    if (want_payload > cap) cap = want_payload;
    iii_chunk_t *c = (iii_chunk_t *)malloc(sizeof(iii_chunk_t) + cap);
    if (!c) return NULL;
    c->next = NULL;
    c->cap  = cap;
    c->used = 0;
    return c;
}

static uint8_t *iii_arena_alloc(iii_arena_t *a, size_t n)
{
    if (n == 0) {
        static const uint8_t empty_payload_sentinel[1] = { 0 };
        return (uint8_t *)empty_payload_sentinel;
    }
    if (a->head == NULL || (a->head->used + n) > a->head->cap) {
        iii_chunk_t *c = iii_chunk_new(n);
        if (!c) return NULL;
        c->next = a->head;
        a->head = c;
        a->total_bytes += c->cap;
    }
    uint8_t *p = a->head->data + a->head->used;
    a->head->used += n;
    return p;
}

static void iii_arena_destroy(iii_arena_t *a)
{
    iii_chunk_t *c = a->head;
    while (c != NULL) {
        iii_chunk_t *nx = c->next;
        free(c);
        c = nx;
    }
    a->head = NULL;
    a->total_bytes = 0;
}

/* ─── Identifier intern table (D3) ───────────────────────────────── */

/* Open-addressed hash table.  Key: (start_byte, length) into source.
 * Value: dense interned ID (1-based; 0 reserved for "not interned").
 * Capacity is a power of 2; load factor < 70% before rehash. */

typedef struct {
    uint32_t start_byte;
    uint32_t length;
    uint64_t hash;
    uint32_t id;        /* 0 = empty slot */
} iii_intern_slot_t;

typedef struct {
    iii_intern_slot_t *slots;
    size_t             cap;
    size_t             count;
    uint32_t           next_id;
} iii_intern_t;

static const uint64_t III_FNV_OFFSET = 0xcbf29ce484222325ULL;
static const uint64_t III_FNV_PRIME  = 0x00000100000001B3ULL;

static uint64_t iii_fnv1a_64_bytes(const uint8_t *bytes, size_t len)
{
    uint64_t h = III_FNV_OFFSET;
    for (size_t i = 0; i < len; i++) {
        h ^= (uint64_t)bytes[i];
        h *= III_FNV_PRIME;
    }
    return h;
}

static int iii_intern_init(iii_intern_t *t)
{
    t->cap = 1024u;
    t->count = 0u;
    t->next_id = 1u;
    t->slots = (iii_intern_slot_t *)calloc(t->cap, sizeof(iii_intern_slot_t));
    return t->slots ? 0 : -1;
}

static void iii_intern_destroy(iii_intern_t *t)
{
    if (t->slots) free(t->slots);
    t->slots = NULL;
    t->cap = 0;
    t->count = 0;
}

static int iii_intern_grow(iii_intern_t *t, const uint8_t *src)
{
    size_t new_cap = t->cap * 2u;
    iii_intern_slot_t *new_slots =
        (iii_intern_slot_t *)calloc(new_cap, sizeof(iii_intern_slot_t));
    if (!new_slots) return -1;
    for (size_t i = 0; i < t->cap; i++) {
        iii_intern_slot_t *s = &t->slots[i];
        if (s->id == 0u) continue;
        size_t mask = new_cap - 1u;
        size_t pos = (size_t)(s->hash & mask);
        while (new_slots[pos].id != 0u) {
            pos = (pos + 1u) & mask;
        }
        new_slots[pos] = *s;
    }
    free(t->slots);
    t->slots = new_slots;
    t->cap = new_cap;
    (void)src;  /* unused — re-hashing uses stored hash field */
    return 0;
}

/* Find or insert.  Returns the ID; 0 only if memory allocation
 * failed during a rehash. */
static uint32_t iii_intern_get(iii_intern_t *t, const uint8_t *src,
                                  uint32_t start, uint32_t length, uint64_t hash)
{
    if ((t->count + 1u) * 10u >= t->cap * 7u) {
        if (iii_intern_grow(t, src) != 0) return 0u;
    }
    size_t mask = t->cap - 1u;
    size_t pos = (size_t)(hash & mask);
    while (t->slots[pos].id != 0u) {
        if (t->slots[pos].hash == hash &&
            t->slots[pos].length == length &&
            memcmp(src + t->slots[pos].start_byte, src + start, length) == 0) {
            return t->slots[pos].id;
        }
        pos = (pos + 1u) & mask;
    }
    iii_intern_slot_t *s = &t->slots[pos];
    s->start_byte = start;
    s->length     = length;
    s->hash       = hash;
    s->id         = t->next_id++;
    t->count++;
    return s->id;
}

/* ─── Static keyword tables ──────────────────────────────────────── */

typedef struct {
    const char       *name;
    size_t            name_len;
    iii_token_kind_t  kind;
} iii_keyword_t;

static const iii_keyword_t III_KEYWORDS[] = {
    /* alphabetical by C string ordering (stability for review) */
    { "INVALID",            7,  III_TOK_KW_TRIT_INVALID },
    { "NEG",                3,  III_TOK_KW_NEG },
    { "OBSERVATORY",       11,  III_TOK_KW_OBSERVATORY },
    { "POS",                3,  III_TOK_KW_POS },
    { "ZERO",               4,  III_TOK_KW_ZERO },
    { "and",                3,  III_TOK_KW_AND },
    { "any",                3,  III_TOK_KW_ANY },
    { "as",                 2,  III_TOK_KW_AS },
    { "build_time",        10,  III_TOK_KW_BUILD_TIME },
    { "compose",            7,  III_TOK_KW_COMPOSE },
    { "compromise",        10,  III_TOK_KW_COMPROMISE },
    { "const",              5,  III_TOK_KW_CONST },
    { "current",            7,  III_TOK_KW_CURRENT },
    { "cycle",              5,  III_TOK_KW_CYCLE },
    { "else",               4,  III_TOK_KW_ELSE },               /* F1 */
    { "extern",             6,  III_TOK_KW_EXTERN },
    { "false",              5,  III_TOK_KW_FALSE },
    { "fn",                 2,  III_TOK_KW_FN },
    { "for",                3,  III_TOK_KW_FOR },
    { "forward",            7,  III_TOK_KW_FORWARD },
    { "from",               4,  III_TOK_KW_FROM },
    { "if",                 2,  III_TOK_KW_IF },
    { "in",                 2,  III_TOK_KW_IN },
    { "let",                3,  III_TOK_KW_LET },
    { "match",              5,  III_TOK_KW_MATCH },
    { "metal",              5,  III_TOK_KW_METAL },
    { "mobius_candidate",  16,  III_TOK_KW_MOBIUS_CANDIDATE },
    { "module",             6,  III_TOK_KW_MODULE },
    { "mut",                3,  III_TOK_KW_MUT },
    { "on_rollback",       11,  III_TOK_KW_ON_ROLLBACK },
    { "or",                 2,  III_TOK_KW_OR },
    { "quiescent",          9,  III_TOK_KW_QUIESCENT },
    { "return",             6,  III_TOK_KW_RETURN },
    { "sanctum_enter",     13,  III_TOK_KW_SANCTUM_ENTER },
    { "schema",             6,  III_TOK_KW_SCHEMA },
    { "sealed_call",       11,  III_TOK_KW_SEALED_CALL },
    { "sizeof",             6,  III_TOK_KW_SIZEOF },             /* F5 */
    { "struct",             6,  III_TOK_KW_STRUCT },             /* F8 */
    { "true",               4,  III_TOK_KW_TRUE },
    { "type",               4,  III_TOK_KW_TYPE },
    { "until",              5,  III_TOK_KW_UNTIL },
    { "use",                3,  III_TOK_KW_USE },
    { "var",                3,  III_TOK_KW_VAR },                /* F9 */
    { "wavefront",          9,  III_TOK_KW_WAVEFRONT },
    { "where",              5,  III_TOK_KW_WHERE },
    { "while",              5,  III_TOK_KW_WHILE },               /* F2 */
    /* iiis-2 control-flow keywords.  Append at end (table is sorted
     * but the lookup is linear scan with strncmp; ordering at the tail
     * is incidental, not semantic). */
    { "break",              5,  III_TOK_KW_BREAK },
    { "continue",           8,  III_TOK_KW_CONTINUE },
    { "loop",               4,  III_TOK_KW_LOOP }
};

#define III_KEYWORD_COUNT (sizeof(III_KEYWORDS) / sizeof(III_KEYWORDS[0]))

/* Modifier-keyword table (D4): names recognised immediately after `@`.
 * Alphabetical for binary search. */
static const iii_keyword_t III_MOD_KEYWORDS[] = {
    { "abi",                       3, III_TOK_MOD_ABI },
    { "arena_reset_safe",         16, III_TOK_MOD_ARENA_RESET_SAFE },           /* Step 0014 */
    { "bounded",                   7, III_TOK_MOD_BOUNDED },                    /* Step 0006 */
    { "cap",                       3, III_TOK_MOD_CAP },
    { "chronos",                   7, III_TOK_MOD_CHRONOS },
    { "closure",                   7, III_TOK_MOD_CLOSURE },
    { "constant_time",            13, III_TOK_MOD_CONSTANT_TIME },              /* Step 0010 */
    { "crystal",                   7, III_TOK_MOD_CRYSTAL },                    /* Step 0002 */
    { "crystal_self_attest",      19, III_TOK_MOD_CRYSTAL_SELF_ATTEST },        /* Step 0015 */
    { "dynamic",                   7, III_TOK_MOD_DYNAMIC },                    /* Step 0003 */
    { "dynamic_impact",           14, III_TOK_MOD_DYNAMIC_IMPACT },             /* Step 0012 */
    { "epoch",                     5, III_TOK_MOD_EPOCH },
    { "hexad",                     5, III_TOK_MOD_HEXAD },
    { "irreversible",             12, III_TOK_MOD_IRREVERSIBLE },
    { "k",                         1, III_TOK_MOD_K },                          /* Step 0008 */
    { "linear",                    6, III_TOK_MOD_LINEAR },                     /* Step 0005 */
    { "plan_anchor",              11, III_TOK_MOD_PLAN_ANCHOR },
    { "provenance",               10, III_TOK_MOD_PROVENANCE },                 /* Step 0009 */
    { "provenance_linked_error", 23, III_TOK_MOD_PROVENANCE_LINKED_ERROR },     /* Step 0013 */
    { "pure",                      4, III_TOK_MOD_PURE },
    { "ring",                      4, III_TOK_MOD_RING },
    { "safety",                    6, III_TOK_MOD_SAFETY },
    { "sanctum_only",             12, III_TOK_MOD_SANCTUM_ONLY },
    { "seal_id",                   7, III_TOK_MOD_SEAL_ID },
    { "sealed",                    6, III_TOK_MOD_SEALED },                     /* Step 0004 */
    { "side_channel_resistant",  22, III_TOK_MOD_SIDE_CHANNEL_RESISTANT },      /* Step 0011 */
    { "strict_length",            13, III_TOK_MOD_STRICT_LENGTH },              /* Step 0028 */
    { "tier",                      4, III_TOK_MOD_TIER },
    { "track",                     5, III_TOK_MOD_TRACK },
    { "variant",                   7, III_TOK_MOD_VARIANT },                    /* Step 0007 */
    { "version",                   7, III_TOK_MOD_VERSION }
};

#define III_MOD_KEYWORD_COUNT (sizeof(III_MOD_KEYWORDS) / sizeof(III_MOD_KEYWORDS[0]))

/* ─── Runtime-registered keyword table (D2) ──────────────────────── */

typedef struct {
    const char       *name;     /* points into lex-state arena */
    size_t            name_len;
    iii_token_kind_t  kind;
} iii_runtime_kw_t;

#define III_RUNTIME_KW_CAP_INIT 32u
#define III_RUNTIME_KW_CAP_MAX  4096u

/* ─── Token-kind name table ──────────────────────────────────────── */

static const char *const III_TOKEN_KIND_NAMES[III_TOK_KIND_COUNT] = {
    [III_TOK_INVALID]              = "INVALID",
    [III_TOK_EOF]                  = "EOF",
    [III_TOK_NEWLINE]              = "NEWLINE",
    [III_TOK_DOC_COMMENT]          = "DOC_COMMENT",
    [III_TOK_IDENTIFIER]           = "IDENTIFIER",
    [III_TOK_INT_LITERAL]          = "INT_LITERAL",
    [III_TOK_HEX_LITERAL]          = "HEX_LITERAL",
    [III_TOK_MHASH_LITERAL]        = "MHASH_LITERAL",
    [III_TOK_STRING_LITERAL]       = "STRING_LITERAL",
    [III_TOK_STRING_BYTE]          = "STRING_BYTE",
    [III_TOK_STRING_RAW]           = "STRING_RAW",
    [III_TOK_STRING_HEX]           = "STRING_HEX",
    [III_TOK_KW_MODULE]            = "module",
    [III_TOK_KW_USE]               = "use",
    [III_TOK_KW_AS]                = "as",
    [III_TOK_KW_CYCLE]             = "cycle",
    [III_TOK_KW_FN]                = "fn",
    [III_TOK_KW_TYPE]              = "type",
    [III_TOK_KW_CONST]             = "const",
    [III_TOK_KW_EXTERN]            = "extern",
    [III_TOK_KW_MOBIUS_CANDIDATE]  = "mobius_candidate",
    [III_TOK_KW_SCHEMA]            = "schema",
    [III_TOK_KW_OBSERVATORY]       = "OBSERVATORY",
    [III_TOK_KW_SEALED_CALL]       = "sealed_call",
    [III_TOK_KW_FROM]              = "from",
    [III_TOK_KW_LET]               = "let",
    [III_TOK_KW_MUT]               = "mut",
    [III_TOK_KW_WAVEFRONT]         = "wavefront",
    [III_TOK_KW_SANCTUM_ENTER]     = "sanctum_enter",
    [III_TOK_KW_METAL]             = "metal",
    [III_TOK_KW_FOR]               = "for",
    [III_TOK_KW_IN]                = "in",
    [III_TOK_KW_WHERE]             = "where",
    [III_TOK_KW_MATCH]             = "match",
    [III_TOK_KW_IF]                = "if",
    [III_TOK_KW_RETURN]            = "return",
    [III_TOK_KW_UNTIL]             = "until",
    [III_TOK_KW_QUIESCENT]         = "quiescent",
    [III_TOK_KW_ON_ROLLBACK]       = "on_rollback",
    [III_TOK_KW_FORWARD]           = "forward",
    [III_TOK_KW_COMPROMISE]        = "compromise",
    [III_TOK_KW_TRUE]              = "true",
    [III_TOK_KW_FALSE]             = "false",
    [III_TOK_KW_AND]               = "and",
    [III_TOK_KW_OR]                = "or",
    [III_TOK_KW_COMPOSE]           = "compose",
    [III_TOK_KW_CURRENT]           = "current",
    [III_TOK_KW_BUILD_TIME]        = "build_time",
    [III_TOK_KW_ANY]               = "any",
    [III_TOK_KW_NEG]               = "NEG",
    [III_TOK_KW_ZERO]              = "ZERO",
    [III_TOK_KW_POS]               = "POS",
    [III_TOK_KW_TRIT_INVALID]      = "INVALID",
    [III_TOK_MOD_RING]             = "@ring",
    [III_TOK_MOD_TIER]             = "@tier",
    [III_TOK_MOD_SAFETY]           = "@safety",
    [III_TOK_MOD_HEXAD]            = "@hexad",
    [III_TOK_MOD_TRACK]            = "@track",
    [III_TOK_MOD_CHRONOS]          = "@chronos",
    [III_TOK_MOD_CAP]              = "@cap",
    [III_TOK_MOD_EPOCH]            = "@epoch",
    [III_TOK_MOD_PLAN_ANCHOR]      = "@plan_anchor",
    [III_TOK_MOD_CLOSURE]          = "@closure",
    [III_TOK_MOD_VERSION]          = "@version",
    [III_TOK_MOD_ABI]              = "@abi",
    [III_TOK_MOD_PURE]             = "@pure",
    [III_TOK_MOD_IRREVERSIBLE]     = "@irreversible",
    [III_TOK_MOD_SANCTUM_ONLY]     = "@sanctum_only",
    [III_TOK_MOD_SEAL_ID]          = "@seal_id",
    [III_TOK_MOD_CRYSTAL]                  = "@crystal",                  /* Step 0002 */
    [III_TOK_MOD_DYNAMIC]                  = "@dynamic",                  /* Step 0003 */
    [III_TOK_MOD_SEALED]                   = "@sealed",                   /* Step 0004 */
    [III_TOK_MOD_LINEAR]                   = "@linear",                   /* Step 0005 */
    [III_TOK_MOD_BOUNDED]                  = "@bounded",                  /* Step 0006 */
    [III_TOK_MOD_VARIANT]                  = "@variant",                  /* Step 0007 */
    [III_TOK_MOD_K]                        = "@k",                        /* Step 0008 */
    [III_TOK_MOD_PROVENANCE]               = "@provenance",               /* Step 0009 */
    [III_TOK_MOD_CONSTANT_TIME]            = "@constant_time",            /* Step 0010 */
    [III_TOK_MOD_SIDE_CHANNEL_RESISTANT]   = "@side_channel_resistant",   /* Step 0011 */
    [III_TOK_MOD_DYNAMIC_IMPACT]           = "@dynamic_impact",           /* Step 0012 */
    [III_TOK_MOD_PROVENANCE_LINKED_ERROR]  = "@provenance_linked_error",  /* Step 0013 */
    [III_TOK_MOD_ARENA_RESET_SAFE]         = "@arena_reset_safe",         /* Step 0014 */
    [III_TOK_MOD_CRYSTAL_SELF_ATTEST]      = "@crystal_self_attest",      /* Step 0015 */
    [III_TOK_MOD_STRICT_LENGTH]            = "@strict_length",            /* Step 0028 */
    [III_TOK_LPAREN]               = "(",
    [III_TOK_RPAREN]               = ")",
    [III_TOK_LBRACE]               = "{",
    [III_TOK_RBRACE]               = "}",
    [III_TOK_LBRACKET]             = "[",
    [III_TOK_RBRACKET]             = "]",
    [III_TOK_COMMA]                = ",",
    [III_TOK_SEMI]                 = ";",
    [III_TOK_COLON]                = ":",
    [III_TOK_DCOLON]               = "::",
    [III_TOK_DOT]                  = ".",
    [III_TOK_AT]                   = "@",
    [III_TOK_PIPE]                 = "|",
    [III_TOK_UNDERSCORE]           = "_",
    [III_TOK_ARROW]                = "->",
    [III_TOK_FAT_ARROW]            = "=>",
    [III_TOK_OP_PLUS]              = "+",
    [III_TOK_OP_MINUS]             = "-",
    [III_TOK_OP_STAR]              = "*",
    [III_TOK_OP_SLASH]             = "/",
    [III_TOK_OP_PERCENT]           = "%",
    [III_TOK_OP_AMP]               = "&",
    [III_TOK_OP_CARET]             = "^",
    [III_TOK_DOLLAR]               = "$",
    [III_TOK_OP_TILDE]             = "~",
    [III_TOK_OP_BANG]              = "!",
    [III_TOK_OP_SHL]               = "<<",
    [III_TOK_OP_SHR]               = ">>",
    [III_TOK_OP_EQ]                = "==",
    [III_TOK_OP_NEQ]               = "!=",
    [III_TOK_OP_LT]                = "<",
    [III_TOK_OP_LE]                = "<=",
    [III_TOK_OP_GT]                = ">",
    [III_TOK_OP_GE]                = ">=",
    [III_TOK_OP_ASSIGN]            = "=",
    [III_TOK_OP_COLON_EQ]          = ":=",
    /* Phase-B token name strings (KW_AS already in the upper block). */
    [III_TOK_KW_ELSE]              = "else",
    [III_TOK_KW_WHILE]             = "while",
    [III_TOK_KW_LOOP]              = "loop",
    [III_TOK_KW_BREAK]             = "break",
    [III_TOK_KW_CONTINUE]          = "continue",
    [III_TOK_OP_DOTDOT]            = "..",
    [III_TOK_KW_SIZEOF]            = "sizeof",
    [III_TOK_KW_VAR]               = "var",
    [III_TOK_KW_STRUCT]            = "struct",
};

const char *iii_token_kind_name(iii_token_kind_t k)
{
    if ((unsigned)k >= III_TOK_KIND_COUNT) return "<unknown>";
    const char *s = III_TOKEN_KIND_NAMES[k];
    return s ? s : "<unknown>";
}

/* ─── Lex state ──────────────────────────────────────────────────── */

struct iii_lex_state {
    const uint8_t      *src;
    size_t              len;
    const char         *path;

    /* Current scan position. */
    size_t              pos;
    uint32_t            line;
    uint32_t            col;

    /* Logical position (D8). */
    const char         *logical_path;
    uint32_t            logical_line;
    uint32_t            logical_col;

    /* Peek cache. */
    bool                peek_valid;
    int                 peek_status;
    iii_token_t         peek_tok;

    /* Modifier-pending flag (D4): true between `@` and the next
     * non-trivia, non-newline token. */
    bool                modifier_pending;

    /* Doc-comment that should attach to the next significant token
     * (D19).  UINT32_MAX = no doc comment is pending.  Newlines do
     * not clear; only the attaching emission does. */
    uint32_t            pending_doc_comment_byte;

    /* Sealed flag (D22). */
    bool                sealed;

    /* Error log (D9 + D10). */
    iii_lex_error_t    *errors;
    size_t              errors_count;
    size_t              errors_cap;

    /* Line-start table (D5).  line_starts[i] = byte offset of the
     * start of physical line (i+1).  line_starts[0] is always 0. */
    uint32_t           *line_starts;
    size_t              line_starts_count;
    size_t              line_starts_cap;

    /* Token history (D7). */
    iii_token_t        *history;
    size_t              history_count;
    size_t              history_cap;

    /* Streaming SHA-256 over emitted tokens (D1). */
    iii_sha256_t        stream_sha;

    /* Identifier intern table (D3). */
    iii_intern_t        intern;

    /* Runtime keyword table (D2). */
    iii_runtime_kw_t   *runtime_kw;
    size_t              runtime_kw_count;
    size_t              runtime_kw_cap;

    /* Most recent error (mirrors errors[errors_count-1] for the
     * iii_lex_error_info convenience read). */
    iii_lex_error_t     err;

    /* String-literal payload arena. */
    iii_arena_t         arena;
};

/* ─── Source-position helpers ────────────────────────────────────── */

static bool iii_at_end(const iii_lex_state_t *st) { return st->pos >= st->len; }

static uint8_t iii_peek_byte(const iii_lex_state_t *st)
{
    if (st->pos >= st->len) return 0;
    return st->src[st->pos];
}

static uint8_t iii_peek_byte_at(const iii_lex_state_t *st, size_t off)
{
    if (st->pos + off >= st->len) return 0;
    return st->src[st->pos + off];
}

/* Append `byte` as a line-start if we're sitting at one. */
static void iii_record_line_start_at(iii_lex_state_t *st, size_t byte)
{
    if (st->line_starts_count == st->line_starts_cap) {
        size_t new_cap = (st->line_starts_cap == 0u) ? 64u : st->line_starts_cap * 2u;
        uint32_t *p = (uint32_t *)realloc(st->line_starts,
                                            new_cap * sizeof(*p));
        if (!p) return;  /* best-effort; locate falls back to linear scan */
        st->line_starts = p;
        st->line_starts_cap = new_cap;
    }
    st->line_starts[st->line_starts_count++] = (uint32_t)byte;
}

static void iii_advance(iii_lex_state_t *st)
{
    if (st->pos < st->len) {
        uint8_t b = st->src[st->pos];
        st->pos += 1;
        if (b == '\n') {
            st->line += 1;
            st->col = 1;
            iii_record_line_start_at(st, st->pos);
        } else {
            st->col += 1;
        }
    }
}

static int iii_record_error(iii_lex_state_t *st, int code, const char *msg)
{
    /* Dynamic error log (D9). */
    if (st->errors_count == st->errors_cap) {
        size_t new_cap = (st->errors_cap == 0u) ? 8u : st->errors_cap * 2u;
        iii_lex_error_t *p = (iii_lex_error_t *)realloc(st->errors,
                                                          new_cap * sizeof(*p));
        if (!p) {
            /* Even when we cannot grow the log, surface the error in
             * `st->err` so iii_lex_error_info reflects something. */
            st->err.code = code;
            st->err.byte = (uint32_t)st->pos;
            st->err.line = st->line;
            st->err.col  = st->col;
            st->err.message = msg;
            return -1;
        }
        st->errors = p;
        st->errors_cap = new_cap;
    }
    iii_lex_error_t *e = &st->errors[st->errors_count++];
    e->code = code;
    e->byte = (uint32_t)st->pos;
    e->line = st->line;
    e->col  = st->col;
    e->message = msg;
    st->err = *e;
    return -1;
}

/* ─── Character-class predicates (ASCII only) ────────────────────── */

static bool iii_is_alpha(uint8_t b)  { return (b >= 'A' && b <= 'Z') || (b >= 'a' && b <= 'z') || b == '_'; }
static bool iii_is_digit(uint8_t b)  { return b >= '0' && b <= '9'; }
static bool iii_is_alnum(uint8_t b)  { return iii_is_alpha(b) || iii_is_digit(b); }
static bool iii_is_hex(uint8_t b)    { return iii_is_digit(b) || (b >= 'a' && b <= 'f') || (b >= 'A' && b <= 'F'); }
static bool iii_is_inline_ws(uint8_t b) { return b == ' ' || b == '\t' || b == '\r'; }

static uint8_t iii_hex_value(uint8_t b)
{
    if (b >= '0' && b <= '9') return (uint8_t)(b - '0');
    if (b >= 'a' && b <= 'f') return (uint8_t)(b - 'a' + 10);
    return (uint8_t)(b - 'A' + 10);
}

/* ─── Trivia and doc-comment handling ────────────────────────────── */

/* Skip inline whitespace and NORMAL line/block comments.  Stops at:
 *   - end of source
 *   - newline (significant)
 *   - the start of a doc-comment (line form '///' or block form
 *     opened by slash-asterisk-asterisk) — left for
 *     iii_next_internal to emit
 *   - any non-trivia byte
 *
 * Returns true on a fatal error (unterminated block comment). */
static bool iii_skip_trivia(iii_lex_state_t *st)
{
    while (!iii_at_end(st)) {
        uint8_t b = iii_peek_byte(st);
        if (iii_is_inline_ws(b)) {
            iii_advance(st);
            continue;
        }
        if (b == '/' && iii_peek_byte_at(st, 1) == '/') {
            /* `///` (doc-comment line) — stop trivia, leave to caller. */
            if (iii_peek_byte_at(st, 2) == '/') return false;
            /* Plain line comment — consume to but not including '\n'. */
            iii_advance(st);
            iii_advance(st);
            while (!iii_at_end(st) && iii_peek_byte(st) != '\n') {
                iii_advance(st);
            }
            continue;
        }
        if (b == '/' && iii_peek_byte_at(st, 1) == '*') {
            /* slash-asterisk-asterisk (doc-comment block): stop
             * trivia, leave to caller for emission. */
            if (iii_peek_byte_at(st, 2) == '*') return false;
            iii_advance(st);
            iii_advance(st);
            /* Nested block-comment support: increment depth on each
             * inner slash-asterisk, decrement on each asterisk-slash.
             * Comment closes when depth returns to zero.  Without this,
             * an outer block comment that contains an inner block
             * comment terminates at the first inner close marker,
             * leaking the rest of the source into the token stream. */
            int depth = 1;
            bool closed = false;
            while (!iii_at_end(st)) {
                uint8_t c0 = iii_peek_byte(st);
                uint8_t c1 = iii_peek_byte_at(st, 1);
                if (c0 == '/' && c1 == '*') {
                    iii_advance(st);
                    iii_advance(st);
                    depth++;
                    continue;
                }
                if (c0 == '*' && c1 == '/') {
                    iii_advance(st);
                    iii_advance(st);
                    depth--;
                    if (depth == 0) { closed = true; break; }
                    continue;
                }
                iii_advance(st);
            }
            if (!closed) {
                (void)iii_record_error(st, III_LEX_E_UNTERMINATED_BLOCK_CMT,
                                         "unterminated block comment");
                return true;
            }
            continue;
        }
        break;
    }
    return false;
}

/* Scan a doc-comment.  Caller has confirmed the prefix is either three
 * consecutive slashes (line form) or slash-asterisk-asterisk (block form). */
static int iii_scan_doc_comment(iii_lex_state_t *st, iii_token_t *out)
{
    const size_t start = st->pos;
    const uint32_t start_line = st->line;
    const uint32_t start_col = st->col;
    /* Disambiguate line vs block by the second slash/asterisk. */
    bool is_line = (iii_peek_byte_at(st, 1) == '/');
    if (is_line) {
        iii_advance(st);  /* '/' */
        iii_advance(st);  /* '/' */
        iii_advance(st);  /* '/' */
        while (!iii_at_end(st) && iii_peek_byte(st) != '\n') {
            iii_advance(st);
        }
    } else {
        /* slash-asterisk-asterisk: block doc-comment. */
        iii_advance(st);  /* '/' */
        iii_advance(st);  /* '*' */
        iii_advance(st);  /* '*' */
        bool closed = false;
        while (!iii_at_end(st)) {
            uint8_t c0 = iii_peek_byte(st);
            uint8_t c1 = iii_peek_byte_at(st, 1);
            if (c0 == '*' && c1 == '/') {
                iii_advance(st);
                iii_advance(st);
                closed = true;
                break;
            }
            iii_advance(st);
        }
        if (!closed) {
            return iii_record_error(st, III_LEX_E_UNTERMINATED_BLOCK_CMT,
                                      "unterminated doc-comment block");
        }
    }
    out->kind       = III_TOK_DOC_COMMENT;
    out->start_byte = (uint32_t)start;
    out->end_byte   = (uint32_t)st->pos;
    out->line       = start_line;
    out->col        = start_col;
    /* Update pending so next significant token attaches. */
    st->pending_doc_comment_byte = (uint32_t)start;
    return 1;
}

/* ─── Identifier / keyword scan ──────────────────────────────────── */

/* Lookup against runtime keyword table (D2). */
static iii_token_kind_t iii_lookup_runtime_kw(const iii_lex_state_t *st,
                                                  const uint8_t *bytes, size_t len)
{
    for (size_t i = 0; i < st->runtime_kw_count; i++) {
        if (st->runtime_kw[i].name_len == len &&
            memcmp(st->runtime_kw[i].name, bytes, len) == 0) {
            return st->runtime_kw[i].kind;
        }
    }
    return III_TOK_INVALID;
}

static iii_token_kind_t iii_lookup_keyword(const uint8_t *bytes, size_t len)
{
    for (size_t i = 0; i < III_KEYWORD_COUNT; i++) {
        if (III_KEYWORDS[i].name_len == len &&
            memcmp(III_KEYWORDS[i].name, bytes, len) == 0) {
            return III_KEYWORDS[i].kind;
        }
    }
    return III_TOK_INVALID;
}

static iii_token_kind_t iii_lookup_modifier_kw(const uint8_t *bytes, size_t len)
{
    for (size_t i = 0; i < III_MOD_KEYWORD_COUNT; i++) {
        if (III_MOD_KEYWORDS[i].name_len == len &&
            memcmp(III_MOD_KEYWORDS[i].name, bytes, len) == 0) {
            return III_MOD_KEYWORDS[i].kind;
        }
    }
    return III_TOK_INVALID;
}

static int iii_scan_ident_or_keyword(iii_lex_state_t *st, iii_token_t *out)
{
    const size_t start = st->pos;
    const uint32_t start_line = st->line;
    const uint32_t start_col = st->col;
    while (!iii_at_end(st) && iii_is_alnum(iii_peek_byte(st))) {
        iii_advance(st);
    }
    const size_t end = st->pos;
    const size_t len = end - start;

    /* Single-char "_" is the wildcard punctuation. */
    if (len == 1 && st->src[start] == '_') {
        out->kind       = III_TOK_UNDERSCORE;
        out->start_byte = (uint32_t)start;
        out->end_byte   = (uint32_t)end;
        out->line       = start_line;
        out->col        = start_col;
        return 1;
    }

    /* Modifier-keyword resolution (D4): consumes the modifier_pending
     * flag iff a modifier name matches. */
    if (st->modifier_pending) {
        iii_token_kind_t mk = iii_lookup_modifier_kw(st->src + start, len);
        if (mk != III_TOK_INVALID) {
            out->kind       = mk;
            out->start_byte = (uint32_t)start;
            out->end_byte   = (uint32_t)end;
            out->line       = start_line;
            out->col        = start_col;
            return 1;
        }
        /* Modifier name not in the standard table — fall through to
         * regular keyword/identifier handling.  modifier_pending is
         * cleared by the caller (iii_next_internal). */
    }

    /* Standard keyword table. */
    iii_token_kind_t kw = iii_lookup_keyword(st->src + start, len);
    if (kw != III_TOK_INVALID) {
        out->kind       = kw;
        out->start_byte = (uint32_t)start;
        out->end_byte   = (uint32_t)end;
        out->line       = start_line;
        out->col        = start_col;
        return 1;
    }

    /* Runtime-registered keyword table. */
    iii_token_kind_t rkw = iii_lookup_runtime_kw(st, st->src + start, len);
    if (rkw != III_TOK_INVALID) {
        out->kind       = rkw;
        out->start_byte = (uint32_t)start;
        out->end_byte   = (uint32_t)end;
        out->line       = start_line;
        out->col        = start_col;
        return 1;
    }

    /* Plain identifier — intern and assign ID (D3). */
    uint64_t hash = iii_fnv1a_64_bytes(st->src + start, len);
    uint32_t id = iii_intern_get(&st->intern, st->src,
                                    (uint32_t)start, (uint32_t)len, hash);
    out->kind        = III_TOK_IDENTIFIER;
    out->start_byte  = (uint32_t)start;
    out->end_byte    = (uint32_t)end;
    out->line        = start_line;
    out->col         = start_col;
    out->interned_id = id;
    return 1;
}

/* ─── Number scan (int / hex / mhash) with suffix (D15) ──────────── */

/* Recognise an integer-type suffix immediately following a decimal or
 * hex integer.  Updates `*out_suffix` and consumes the suffix bytes
 * into st->pos.  Returns 0 on success (including no-suffix), -1 if a
 * suffix-shaped sequence is present but unrecognised. */
static int iii_scan_int_suffix(iii_lex_state_t *st, iii_int_suffix_t *out_suffix)
{
    *out_suffix = III_INT_SUFFIX_NONE;
    if (iii_at_end(st)) return 0;
    uint8_t b = iii_peek_byte(st);
    if (b != 'i' && b != 'u') return 0;
    /* Read the suffix as an alpha-numeric run. */
    size_t suf_start = st->pos;
    while (!iii_at_end(st) && iii_is_alnum(iii_peek_byte(st))) {
        iii_advance(st);
    }
    size_t suf_len = st->pos - suf_start;
    const uint8_t *s = st->src + suf_start;
    typedef struct { const char *n; size_t l; iii_int_suffix_t k; } ent_t;
    static const ent_t ENTS[] = {
        { "i8",     2, III_INT_SUFFIX_I8 },
        { "i16",    3, III_INT_SUFFIX_I16 },
        { "i32",    3, III_INT_SUFFIX_I32 },
        { "i64",    3, III_INT_SUFFIX_I64 },
        { "u8",     2, III_INT_SUFFIX_U8 },
        { "u16",    3, III_INT_SUFFIX_U16 },
        { "u32",    3, III_INT_SUFFIX_U32 },
        { "u64",    3, III_INT_SUFFIX_U64 },
        { "usize",  5, III_INT_SUFFIX_USIZE },
        { "isize",  5, III_INT_SUFFIX_ISIZE }
    };
    for (size_t i = 0; i < sizeof(ENTS)/sizeof(ENTS[0]); i++) {
        if (ENTS[i].l == suf_len && memcmp(ENTS[i].n, s, suf_len) == 0) {
            *out_suffix = ENTS[i].k;
            return 0;
        }
    }
    /* Unknown suffix.  Roll back so iii_record_error reports the
     * suffix's start position, then return -1. */
    st->pos = suf_start;
    /* Recompute line/col by counting from current — for Stage 0 we
     * accept the small inaccuracy of leaving line/col at the post-
     * advance values; the suffix span is on a single line by
     * construction (no newlines in identifier-bytes). */
    return iii_record_error(st, III_LEX_E_BAD_INT_SUFFIX,
                              "unknown integer-literal suffix");
}

static int iii_scan_number(iii_lex_state_t *st, iii_token_t *out)
{
    const size_t start = st->pos;
    const uint32_t start_line = st->line;
    const uint32_t start_col = st->col;
    const uint8_t b0 = iii_peek_byte(st);

    if (b0 == '0' && (iii_peek_byte_at(st, 1) == 'x' || iii_peek_byte_at(st, 1) == 'X')) {
        iii_advance(st);  /* '0' */
        iii_advance(st);  /* 'x' */
        const size_t hex_start = st->pos;
        /* Scan hex digits OR `_` separators.  Underscores are visual
         * digit-group separators (e.g., 0xFFFF_FFFFu64).  They count
         * toward neither the digit-length nor the value. */
        size_t hex_digit_count = 0;
        while (!iii_at_end(st)) {
            uint8_t c = iii_peek_byte(st);
            if (iii_is_hex(c)) {
                hex_digit_count++;
                iii_advance(st);
                continue;
            }
            if (c == '_') {
                iii_advance(st);
                continue;
            }
            break;
        }
        const size_t hex_end = st->pos;
        if (hex_digit_count == 0) {
            st->pos = start;
            return iii_record_error(st, III_LEX_E_BAD_HEX_PREFIX,
                                      "0x prefix not followed by hex digits");
        }
        if (hex_digit_count == 64) {
            /* Walk source bytes, copy 32 bytes into mhash, skipping `_`. */
            size_t mi = 0;
            uint8_t nibble = 0;
            bool have_hi = false;
            for (size_t i = hex_start; i < hex_end && mi < 32; i++) {
                uint8_t c = st->src[i];
                if (c == '_') continue;
                uint8_t v = iii_hex_value(c);
                if (!have_hi) {
                    nibble = v;
                    have_hi = true;
                } else {
                    out->mhash[mi++] = (uint8_t)((nibble << 4) | v);
                    have_hi = false;
                }
            }
            out->kind       = III_TOK_MHASH_LITERAL;
            out->int_value  = 0;
            out->int_suffix = III_INT_SUFFIX_NONE;
            out->start_byte = (uint32_t)start;
            out->end_byte   = (uint32_t)hex_end;
            out->line       = start_line;
            out->col        = start_col;
            return 1;
        }
        if (hex_digit_count > 64) {
            return iii_record_error(st, III_LEX_E_OVERLONG_MHASH,
                                      "0x literal exceeds 64 hex digits");
        }
        if (hex_digit_count > 16) {
            return iii_record_error(st, III_LEX_E_OVERLONG_INT,
                                      "hex integer 17..63 digits is neither u64 nor mhash");
        }
        uint64_t v = 0;
        for (size_t i = hex_start; i < hex_end; i++) {
            uint8_t c = st->src[i];
            if (c == '_') continue;
            v = (v << 4) | iii_hex_value(c);
        }
        iii_int_suffix_t suf = III_INT_SUFFIX_NONE;
        if (iii_scan_int_suffix(st, &suf) != 0) return -1;
        out->kind       = III_TOK_HEX_LITERAL;
        out->int_value  = v;
        out->int_suffix = suf;
        memset(out->mhash, 0, sizeof(out->mhash));
        out->start_byte = (uint32_t)start;
        out->end_byte   = (uint32_t)st->pos;
        out->line       = start_line;
        out->col        = start_col;
        return 1;
    }

    /* Decimal INT_LITERAL. */
    uint64_t v = 0;
    bool overflow = false;
    while (!iii_at_end(st) && iii_is_digit(iii_peek_byte(st))) {
        uint8_t d = (uint8_t)(iii_peek_byte(st) - '0');
        const uint64_t max_div_10 = (uint64_t)0xFFFFFFFFFFFFFFFFULL / 10ULL;
        const uint64_t max_mod_10 = (uint64_t)0xFFFFFFFFFFFFFFFFULL % 10ULL;
        if (v > max_div_10 || (v == max_div_10 && (uint64_t)d > max_mod_10)) overflow = true;
        v = v * 10ULL + (uint64_t)d;
        iii_advance(st);
    }
    if (overflow) {
        return iii_record_error(st, III_LEX_E_OVERLONG_INT,
                                  "integer literal exceeds 2^64 - 1");
    }
    iii_int_suffix_t suf = III_INT_SUFFIX_NONE;
    if (iii_scan_int_suffix(st, &suf) != 0) return -1;
    out->kind       = III_TOK_INT_LITERAL;
    out->int_value  = v;
    out->int_suffix = suf;
    memset(out->mhash, 0, sizeof(out->mhash));
    out->start_byte = (uint32_t)start;
    out->end_byte   = (uint32_t)st->pos;
    out->line       = start_line;
    out->col        = start_col;
    return 1;
}

/* ─── String scan ────────────────────────────────────────────────── */

/* Variants:
 *   "..."  → III_TOK_STRING_LITERAL — escapes resolved
 *   b"..." → III_TOK_STRING_BYTE    — escapes resolved (bytes)
 *   r"..." → III_TOK_STRING_RAW     — bytes verbatim, NO escapes
 *   h"..." → III_TOK_STRING_HEX     — pairs of hex decoded
 *
 * `prefix_byte` is 0 for plain "...", or 'b'/'r'/'h' for the
 * prefixed forms; the caller has consumed the prefix byte.  start
 * is the byte offset of the prefix (or the opening `"` for plain). */
static int iii_scan_string_inner(iii_lex_state_t *st, iii_token_t *out,
                                     uint8_t prefix_byte, size_t start,
                                     uint32_t start_line, uint32_t start_col)
{
    /* Pre-scan to determine decoded length. */
    iii_advance(st);  /* opening '"' */
    size_t scan = st->pos;
    size_t decoded_len = 0;
    bool resolve_escapes = (prefix_byte != 'r');
    bool hex_decode = (prefix_byte == 'h');

    if (hex_decode) {
        /* Count hex digits up to closing '"'.  Must be even number. */
        size_t hexc = 0;
        while (scan < st->len) {
            uint8_t b = st->src[scan];
            if (b == '"') break;
            if (!iii_is_hex(b)) {
                st->pos = scan;
                return iii_record_error(st, III_LEX_E_BAD_HEX_STRING,
                                          "h\"...\" body must be hex digits only");
            }
            hexc++;
            scan++;
        }
        if (scan >= st->len) {
            st->pos = scan;
            return iii_record_error(st, III_LEX_E_UNTERMINATED_STRING,
                                      "unterminated h-string");
        }
        if ((hexc & 1u) != 0u) {
            st->pos = scan;
            return iii_record_error(st, III_LEX_E_BAD_HEX_STRING,
                                      "h\"...\" body must have even-length hex");
        }
        decoded_len = hexc / 2u;
    } else if (!resolve_escapes) {
        /* Raw: scan to closing '"' verbatim. */
        while (scan < st->len) {
            uint8_t b = st->src[scan];
            if (b == '"') break;
            decoded_len += 1;
            scan += 1;
        }
        if (scan >= st->len) {
            st->pos = scan;
            return iii_record_error(st, III_LEX_E_UNTERMINATED_STRING,
                                      "unterminated raw string");
        }
    } else {
        /* Plain or byte: resolve escapes. */
        while (scan < st->len) {
            uint8_t b = st->src[scan];
            if (b == '"') break;
            if (b == '\\') {
                if (scan + 1 >= st->len) {
                    st->pos = scan;
                    return iii_record_error(st, III_LEX_E_UNTERMINATED_STRING,
                                              "unterminated string (escape at EOF)");
                }
                uint8_t e = st->src[scan + 1];
                if (e == 'n' || e == 'r' || e == 't' || e == '"' || e == '\\') {
                    decoded_len += 1;
                    scan += 2;
                    continue;
                }
                if (e == 'x') {
                    if (scan + 3 >= st->len ||
                        !iii_is_hex(st->src[scan + 2]) ||
                        !iii_is_hex(st->src[scan + 3])) {
                        st->pos = scan;
                        return iii_record_error(st, III_LEX_E_BAD_ESCAPE,
                                                  "\\x must be followed by exactly 2 hex digits");
                    }
                    decoded_len += 1;
                    scan += 4;
                    continue;
                }
                st->pos = scan;
                return iii_record_error(st, III_LEX_E_BAD_ESCAPE,
                                          "unknown escape sequence");
            }
            decoded_len += 1;
            scan += 1;
        }
        if (scan >= st->len) {
            st->pos = scan;
            return iii_record_error(st, III_LEX_E_UNTERMINATED_STRING,
                                      "unterminated string (missing closing quote)");
        }
    }

    /* +1: NUL-terminate each payload IN THE ARENA (2026-07-04, twin-parity seed fix, the
     * 58-charter sanctioned path).  cg_r3's .rodata emitter walks payloads by NUL; with no
     * terminator, two ADJACENT arena entries bleed together (L_str_0 printed "msvcrtmsvcrt"
     * for a two-extern module) -- zero-init only saved the non-adjacent cases.  The ported
     * .iii lexer terminates its payloads; this aligns the C seed byte-for-byte. */
    uint8_t *payload = iii_arena_alloc(&st->arena, decoded_len + 1u);
    if (payload == NULL) {
        return iii_record_error(st, III_LEX_E_OOM, "string-payload arena alloc failed");
    }
    size_t out_pos = 0;

    if (hex_decode) {
        size_t i = st->pos;
        while (st->src[i] != '"') {
            uint8_t hi = iii_hex_value(st->src[i]);
            uint8_t lo = iii_hex_value(st->src[i + 1]);
            payload[out_pos++] = (uint8_t)((hi << 4) | lo);
            iii_advance(st);
            iii_advance(st);
            i += 2;
        }
    } else if (!resolve_escapes) {
        while (st->pos < scan) {
            payload[out_pos++] = st->src[st->pos];
            iii_advance(st);
        }
    } else {
        while (st->pos < scan) {
            uint8_t b = st->src[st->pos];
            if (b == '\\') {
                uint8_t e = st->src[st->pos + 1];
                uint8_t v = 0;
                switch (e) {
                    case 'n':  v = '\n'; break;
                    case 'r':  v = '\r'; break;
                    case 't':  v = '\t'; break;
                    case '"':  v = '"';  break;
                    case '\\': v = '\\'; break;
                    case 'x': {
                        uint8_t hi = iii_hex_value(st->src[st->pos + 2]);
                        uint8_t lo = iii_hex_value(st->src[st->pos + 3]);
                        v = (uint8_t)((hi << 4) | lo);
                        payload[out_pos++] = v;
                        iii_advance(st); iii_advance(st);
                        iii_advance(st); iii_advance(st);
                        continue;
                    }
                    default:
                        return iii_record_error(st, III_LEX_E_BAD_ESCAPE,
                                                  "unknown escape sequence (post-scan)");
                }
                payload[out_pos++] = v;
                iii_advance(st);
                iii_advance(st);
                continue;
            }
            payload[out_pos++] = b;
            iii_advance(st);
        }
    }
    payload[out_pos] = 0;   /* the arena NUL terminator (alloc reserved +1 above) */
    /* Consume closing quote. */
    iii_advance(st);

    iii_token_kind_t kind = III_TOK_STRING_LITERAL;
    if      (prefix_byte == 'b') kind = III_TOK_STRING_BYTE;
    else if (prefix_byte == 'r') kind = III_TOK_STRING_RAW;
    else if (prefix_byte == 'h') kind = III_TOK_STRING_HEX;

    out->kind          = kind;
    out->start_byte    = (uint32_t)start;
    out->end_byte      = (uint32_t)st->pos;
    out->line          = start_line;
    out->col           = start_col;
    out->int_value     = 0;
    out->int_suffix    = III_INT_SUFFIX_NONE;
    memset(out->mhash, 0, sizeof(out->mhash));
    out->string_len    = (uint32_t)decoded_len;
    out->string_payload = payload;
    return 1;
}

static int iii_scan_string(iii_lex_state_t *st, iii_token_t *out)
{
    return iii_scan_string_inner(st, out, 0,
                                   st->pos, st->line, st->col);
}

static int iii_scan_prefixed_string(iii_lex_state_t *st, iii_token_t *out,
                                       uint8_t prefix_byte)
{
    const size_t start = st->pos;
    const uint32_t start_line = st->line;
    const uint32_t start_col = st->col;
    iii_advance(st);  /* prefix byte */
    return iii_scan_string_inner(st, out, prefix_byte, start, start_line, start_col);
}

/* Helper: record an INVALID_BYTE error and advance the cursor by one
 * byte (D10 recovery contract).  Defined here so the operator switch
 * in iii_next_internal can be a flat pattern of single-statement
 * cases — gcc 15's implicit-fallthrough analysis is sensitive to
 * brace blocks on case bodies and emits false positives when a case's
 * body opens a new scope to declare a local. */
static int iii_handle_invalid_byte(iii_lex_state_t *st, iii_token_t *out)
{
    int rc = iii_record_error(st, III_LEX_E_INVALID_BYTE,
                                "byte not recognised as start of any token");
    out->kind = III_TOK_INVALID;
    if (st->pos < st->len) iii_advance(st);
    return rc;
}

/* ─── Operator / punctuation emit helpers ────────────────────────── */

static int iii_emit_single(iii_lex_state_t *st, iii_token_t *out,
                            iii_token_kind_t kind)
{
    const size_t start = st->pos;
    const uint32_t start_line = st->line;
    const uint32_t start_col = st->col;
    iii_advance(st);
    out->kind       = kind;
    out->start_byte = (uint32_t)start;
    out->end_byte   = (uint32_t)st->pos;
    out->line       = start_line;
    out->col        = start_col;
    out->int_value  = 0;
    out->int_suffix = III_INT_SUFFIX_NONE;
    memset(out->mhash, 0, sizeof(out->mhash));
    out->string_len = 0;
    out->string_payload = NULL;
    return 1;
}

static int iii_emit_double(iii_lex_state_t *st, iii_token_t *out,
                            iii_token_kind_t kind)
{
    const size_t start = st->pos;
    const uint32_t start_line = st->line;
    const uint32_t start_col = st->col;
    iii_advance(st);
    iii_advance(st);
    out->kind       = kind;
    out->start_byte = (uint32_t)start;
    out->end_byte   = (uint32_t)st->pos;
    out->line       = start_line;
    out->col        = start_col;
    out->int_value  = 0;
    out->int_suffix = III_INT_SUFFIX_NONE;
    memset(out->mhash, 0, sizeof(out->mhash));
    out->string_len = 0;
    out->string_payload = NULL;
    return 1;
}

/* ─── Public API: lifecycle ──────────────────────────────────────── */

iii_lex_state_t *iii_lex_create(const uint8_t *source_buf,
                                 size_t         source_len,
                                 const char    *source_path)
{
    iii_lex_state_t *st = (iii_lex_state_t *)calloc(1, sizeof(*st));
    if (!st) return NULL;
    st->src         = source_buf;
    st->len         = source_len;
    st->path        = source_path;
    st->pos         = 0;
    st->line        = 1;
    st->col         = 1;
    st->logical_path = NULL;
    st->logical_line = 0;
    st->logical_col  = 0;
    st->peek_valid  = false;
    st->peek_status = 0;
    memset(&st->peek_tok, 0, sizeof(st->peek_tok));
    st->modifier_pending = false;
    st->pending_doc_comment_byte = III_TOK_NO_DOC_COMMENT;
    st->sealed = false;
    st->errors = NULL;
    st->errors_count = 0;
    st->errors_cap = 0;
    st->line_starts = NULL;
    st->line_starts_count = 0;
    st->line_starts_cap = 0;
    st->history = NULL;
    st->history_count = 0;
    st->history_cap = 0;
    iii_sha256_init(&st->stream_sha);
    if (iii_intern_init(&st->intern) != 0) {
        free(st);
        return NULL;
    }
    st->runtime_kw = NULL;
    st->runtime_kw_count = 0;
    st->runtime_kw_cap = 0;
    st->err.code    = III_LEX_OK;
    st->err.byte    = 0;
    st->err.line    = 0;
    st->err.col     = 0;
    st->err.message = NULL;
    st->arena.head  = NULL;
    st->arena.total_bytes = 0;
    /* Line 1 starts at byte 0. */
    iii_record_line_start_at(st, 0);
    return st;
}

void iii_lex_destroy(iii_lex_state_t *st)
{
    if (!st) return;
    if (!st->sealed) {
        iii_arena_destroy(&st->arena);
    }
    iii_intern_destroy(&st->intern);
    if (st->errors) free(st->errors);
    if (st->line_starts) free(st->line_starts);
    if (st->history) free(st->history);
    if (st->runtime_kw) free(st->runtime_kw);
    free(st);
}

/* ─── History recording (D7) ─────────────────────────────────────── */

static void iii_history_append(iii_lex_state_t *st, const iii_token_t *tok)
{
    if (st->history_count == st->history_cap) {
        size_t new_cap = (st->history_cap == 0u) ? 256u : st->history_cap * 2u;
        iii_token_t *p = (iii_token_t *)realloc(st->history,
                                                  new_cap * sizeof(*p));
        if (!p) return;  /* best-effort */
        st->history = p;
        st->history_cap = new_cap;
    }
    st->history[st->history_count++] = *tok;
}

/* ─── Canonical token serialisation for content-hash (D1) ────────── */

static void iii_token_canonical_update(iii_sha256_t *h, const iii_token_t *t)
{
    iii_sha256_update_u32(h, (uint32_t)t->kind);
    iii_sha256_update_u32(h, t->start_byte);
    iii_sha256_update_u32(h, t->end_byte);
    iii_sha256_update_u32(h, t->line);
    iii_sha256_update_u32(h, t->col);
    iii_sha256_update_u32(h, t->logical_line);
    iii_sha256_update_u32(h, t->logical_col);
    iii_sha256_update_u64(h, t->int_value);
    iii_sha256_update_u8 (h, (uint8_t)t->int_suffix);
    iii_sha256_update(h, t->mhash, 32);
    iii_sha256_update_u32(h, t->string_len);
    iii_sha256_update_u32(h, t->interned_id);
    iii_sha256_update_u32(h, t->leading_doc_comment_byte);
    if (t->logical_path != NULL) {
        size_t lp_len = strlen(t->logical_path);
        iii_sha256_update_u32(h, (uint32_t)lp_len);
        iii_sha256_update(h, (const uint8_t *)t->logical_path, lp_len);
    } else {
        iii_sha256_update_u32(h, 0u);
    }
    if (t->string_payload != NULL && t->string_len > 0u) {
        iii_sha256_update(h, t->string_payload, t->string_len);
    }
}

void iii_token_mhash(const iii_lex_state_t *st, const iii_token_t *tok,
                      uint8_t out_mhash[32])
{
    (void)st;
    if (!tok || !out_mhash) {
        if (out_mhash) memset(out_mhash, 0, 32);
        return;
    }
    iii_sha256_t h;
    iii_sha256_init(&h);
    iii_token_canonical_update(&h, tok);
    iii_sha256_final(&h, out_mhash);
}

void iii_lex_stream_mhash(const iii_lex_state_t *st, uint8_t out_mhash[32])
{
    if (!st || !out_mhash) {
        if (out_mhash) memset(out_mhash, 0, 32);
        return;
    }
    /* Snapshot: copy stream_sha and finalize the copy. */
    iii_sha256_t copy = st->stream_sha;
    iii_sha256_final(&copy, out_mhash);
}

/* ─── Internal next-token dispatch ───────────────────────────────── */

static int iii_next_internal(iii_lex_state_t *st, iii_token_t *out)
{
    if (!st || !out) {
        if (st) (void)iii_record_error(st, III_LEX_E_NULL_ARG,
                                          "NULL token output buffer");
        return -1;
    }
    if (st->sealed) {
        return iii_record_error(st, III_LEX_E_SEALED,
                                  "iii_lex_next called on sealed state");
    }
    /* Initialise out so error paths leave a well-formed record. */
    memset(out, 0, sizeof(*out));
    out->kind = III_TOK_INVALID;
    out->leading_doc_comment_byte = III_TOK_NO_DOC_COMMENT;

    /* Skip non-doc trivia.  An unterminated regular block comment is
     * a fatal error per scan_trivia (returns true → emit INVALID). */
    if (iii_skip_trivia(st)) {
        /* Recovery: advance one byte so subsequent calls can resume. */
        if (st->pos < st->len) iii_advance(st);
        return -1;
    }

    if (iii_at_end(st)) {
        out->kind       = III_TOK_EOF;
        out->start_byte = (uint32_t)st->pos;
        out->end_byte   = (uint32_t)st->pos;
        out->line       = st->line;
        out->col        = st->col;
        return 0;
    }

    uint8_t b = iii_peek_byte(st);

    /* Newline. */
    if (b == '\n') {
        return iii_emit_single(st, out, III_TOK_NEWLINE);
    }

    /* Doc-comment forms: triple-slash line form, or
     * slash-asterisk-asterisk block form. */
    if (b == '/' && iii_peek_byte_at(st, 1) == '/' && iii_peek_byte_at(st, 2) == '/') {
        return iii_scan_doc_comment(st, out);
    }
    if (b == '/' && iii_peek_byte_at(st, 1) == '*' && iii_peek_byte_at(st, 2) == '*') {
        return iii_scan_doc_comment(st, out);
    }

    /* String prefix forms (b" / r" / h"). */
    if ((b == 'b' || b == 'r' || b == 'h') && iii_peek_byte_at(st, 1) == '"') {
        return iii_scan_prefixed_string(st, out, b);
    }

    /* Identifier / keyword. */
    if (iii_is_alpha(b)) {
        return iii_scan_ident_or_keyword(st, out);
    }

    /* Numeric literal. */
    if (iii_is_digit(b)) {
        return iii_scan_number(st, out);
    }

    /* String literal. */
    if (b == '"') {
        return iii_scan_string(st, out);
    }

    /* Punctuation / operators. */
    switch (b) {
        case '(':  return iii_emit_single(st, out, III_TOK_LPAREN);
        case ')':  return iii_emit_single(st, out, III_TOK_RPAREN);
        case '{':  return iii_emit_single(st, out, III_TOK_LBRACE);
        case '}':  return iii_emit_single(st, out, III_TOK_RBRACE);
        case '[':  return iii_emit_single(st, out, III_TOK_LBRACKET);
        case ']':  return iii_emit_single(st, out, III_TOK_RBRACKET);
        case ',':  return iii_emit_single(st, out, III_TOK_COMMA);
        case ';':  return iii_emit_single(st, out, III_TOK_SEMI);
        case '@':  return iii_emit_single(st, out, III_TOK_AT);
        case '|':  return iii_emit_single(st, out, III_TOK_PIPE);
        case '~':  return iii_emit_single(st, out, III_TOK_OP_TILDE);
        case '+':  return iii_emit_single(st, out, III_TOK_OP_PLUS);
        case '*':  return iii_emit_single(st, out, III_TOK_OP_STAR);
        case '/':  return iii_emit_single(st, out, III_TOK_OP_SLASH);
        case '%':  return iii_emit_single(st, out, III_TOK_OP_PERCENT);
        case '&':  return iii_emit_single(st, out, III_TOK_OP_AMP);
        case '^':  return iii_emit_single(st, out, III_TOK_OP_CARET);
        case '$':  return iii_emit_single(st, out, III_TOK_DOLLAR);  /* metal{} asm immediate prefix (Stage 3.5) */
        case '.':
            if (iii_peek_byte_at(st, 1) == '.') return iii_emit_double(st, out, III_TOK_OP_DOTDOT);
            return iii_emit_single(st, out, III_TOK_DOT);

        case '-':
            if (iii_peek_byte_at(st, 1) == '>') return iii_emit_double(st, out, III_TOK_ARROW);
            return iii_emit_single(st, out, III_TOK_OP_MINUS);

        case '=':
            if (iii_peek_byte_at(st, 1) == '=') return iii_emit_double(st, out, III_TOK_OP_EQ);
            if (iii_peek_byte_at(st, 1) == '>') return iii_emit_double(st, out, III_TOK_FAT_ARROW);
            return iii_emit_single(st, out, III_TOK_OP_ASSIGN);

        case '!':
            if (iii_peek_byte_at(st, 1) == '=') return iii_emit_double(st, out, III_TOK_OP_NEQ);
            return iii_emit_single(st, out, III_TOK_OP_BANG);

        case '<':
            if (iii_peek_byte_at(st, 1) == '<') return iii_emit_double(st, out, III_TOK_OP_SHL);
            if (iii_peek_byte_at(st, 1) == '=') return iii_emit_double(st, out, III_TOK_OP_LE);
            return iii_emit_single(st, out, III_TOK_OP_LT);

        case '>':
            if (iii_peek_byte_at(st, 1) == '>') return iii_emit_double(st, out, III_TOK_OP_SHR);
            if (iii_peek_byte_at(st, 1) == '=') return iii_emit_double(st, out, III_TOK_OP_GE);
            return iii_emit_single(st, out, III_TOK_OP_GT);

        case ':':
            if (iii_peek_byte_at(st, 1) == ':') return iii_emit_double(st, out, III_TOK_DCOLON);
            if (iii_peek_byte_at(st, 1) == '=') return iii_emit_double(st, out, III_TOK_OP_COLON_EQ);
            return iii_emit_single(st, out, III_TOK_COLON);

        default:
            return iii_handle_invalid_byte(st, out);
    }
}

/* ─── Public API: token iteration ────────────────────────────────── */

/* Wrapper around iii_next_internal that:
 *   - sets logical position fields on the emitted token
 *   - applies / clears the modifier_pending and pending_doc_comment
 *   - records the token in history (D7)
 *   - updates the streaming SHA-256 (D1) */
static int iii_next_with_metadata(iii_lex_state_t *st, iii_token_t *out)
{
    int rc = iii_next_internal(st, out);

    /* Logical position copy (D8). */
    out->logical_line = st->logical_line;
    out->logical_col  = st->logical_col;
    out->logical_path = st->logical_path;

    /* Doc-comment attachment (D19) and modifier_pending tracking (D4). */
    if (rc == 1) {
        switch (out->kind) {
            case III_TOK_NEWLINE:
                /* Trivia-significant: preserve modifier_pending and
                 * pending doc comment across newlines. */
                break;
            case III_TOK_DOC_COMMENT:
                /* The doc-comment scanner already updated
                 * pending_doc_comment_byte to its start_byte. */
                out->leading_doc_comment_byte = III_TOK_NO_DOC_COMMENT;
                break;
            case III_TOK_AT:
                /* Arm modifier_pending so the next ident can resolve
                 * to a modifier keyword. */
                out->leading_doc_comment_byte = st->pending_doc_comment_byte;
                st->pending_doc_comment_byte = III_TOK_NO_DOC_COMMENT;
                st->modifier_pending = true;
                break;
            default:
                /* All other significant tokens consume the pending
                 * doc-comment and clear modifier_pending. */
                out->leading_doc_comment_byte = st->pending_doc_comment_byte;
                st->pending_doc_comment_byte = III_TOK_NO_DOC_COMMENT;
                st->modifier_pending = false;
                break;
        }
    } else {
        out->leading_doc_comment_byte = III_TOK_NO_DOC_COMMENT;
    }

    /* History (D7): include all emitted tokens except NEWLINE.
     * EOF and INVALID are kept so an editor "what is at byte X"
     * still binary-searches them. */
    if (out->kind != III_TOK_NEWLINE) {
        iii_history_append(st, out);
    }

    /* Stream content-hash (D1): every emission, including errors. */
    iii_token_canonical_update(&st->stream_sha, out);

    return rc;
}

int iii_lex_next(iii_lex_state_t *st, iii_token_t *out_token)
{
    if (!st || !out_token) {
        if (st) (void)iii_record_error(st, III_LEX_E_NULL_ARG, "NULL out_token");
        return -1;
    }
    if (st->peek_valid) {
        *out_token = st->peek_tok;
        st->peek_valid = false;
        return st->peek_status;
    }
    return iii_next_with_metadata(st, out_token);
}

int iii_lex_peek(iii_lex_state_t *st, iii_token_t *out_token)
{
    if (!st || !out_token) {
        if (st) (void)iii_record_error(st, III_LEX_E_NULL_ARG, "NULL out_token");
        return -1;
    }
    if (!st->peek_valid) {
        st->peek_status = iii_next_with_metadata(st, &st->peek_tok);
        st->peek_valid  = true;
    }
    *out_token = st->peek_tok;
    return st->peek_status;
}

/* ─── Public API: error log ──────────────────────────────────────── */

size_t iii_lex_error_count(const iii_lex_state_t *st)
{
    return st ? st->errors_count : 0u;
}

int iii_lex_error_at(const iii_lex_state_t *st, size_t i,
                      iii_lex_error_t *out_err)
{
    if (!st || !out_err) return 0;
    if (i >= st->errors_count) return 0;
    *out_err = st->errors[i];
    return 1;
}

void iii_lex_error_info(const iii_lex_state_t *st, iii_lex_error_t *out_err)
{
    if (!st || !out_err) return;
    if (st->errors_count > 0u) *out_err = st->errors[st->errors_count - 1u];
    else                       *out_err = st->err;
}

/* ─── Public API: accessors ──────────────────────────────────────── */

const char *iii_lex_source_path(const iii_lex_state_t *st)
{
    if (!st) return NULL;
    return st->path;
}

const uint8_t *iii_token_raw(const iii_lex_state_t *st, const iii_token_t *tok)
{
    if (!st || !tok) return NULL;
    if (tok->start_byte > st->len) return NULL;
    return st->src + tok->start_byte;
}

bool iii_token_raw_eq(const iii_lex_state_t *st, const iii_token_t *tok,
                       const char *literal)
{
    if (!st || !tok || !literal) return false;
    const size_t len = (size_t)(tok->end_byte - tok->start_byte);
    const size_t llen = strlen(literal);
    if (llen != len) return false;
    return memcmp(st->src + tok->start_byte, literal, len) == 0;
}

uint64_t iii_token_fnv1a_64(const iii_lex_state_t *st, const iii_token_t *tok)
{
    if (!st || !tok) return 0;
    const size_t len = (size_t)(tok->end_byte - tok->start_byte);
    return iii_fnv1a_64_bytes(st->src + tok->start_byte, len);
}

/* ─── Public API: position helpers ───────────────────────────────── */

int iii_lex_locate(const iii_lex_state_t *st, uint32_t byte,
                    uint32_t *out_line, uint32_t *out_col)
{
    if (!st || !out_line || !out_col) return 0;
    if (st->line_starts_count == 0u) return 0;
    if (byte > st->len) return 0;
    /* Binary search for the largest line_starts[i] <= byte. */
    size_t lo = 0u, hi = st->line_starts_count;
    while (lo + 1u < hi) {
        size_t mid = lo + (hi - lo) / 2u;
        if (st->line_starts[mid] <= byte) lo = mid;
        else                                hi = mid;
    }
    *out_line = (uint32_t)(lo + 1u);
    *out_col  = (uint32_t)(byte - st->line_starts[lo] + 1u);
    return 1;
}

void iii_token_span_union(const iii_token_t *a, const iii_token_t *b,
                           uint32_t *out_start, uint32_t *out_end)
{
    if (!out_start || !out_end) return;
    if (!a && !b) { *out_start = 0; *out_end = 0; return; }
    if (!a) { *out_start = b->start_byte; *out_end = b->end_byte; return; }
    if (!b) { *out_start = a->start_byte; *out_end = a->end_byte; return; }
    *out_start = (a->start_byte < b->start_byte) ? a->start_byte : b->start_byte;
    *out_end   = (a->end_byte   > b->end_byte)   ? a->end_byte   : b->end_byte;
}

int iii_lex_token_at_byte(const iii_lex_state_t *st, uint32_t byte,
                           size_t *out_token_idx)
{
    if (!st || !out_token_idx) return 0;
    if (st->history_count == 0u) return 0;
    /* Binary search for the largest history[i].start_byte <= byte. */
    size_t lo = 0u, hi = st->history_count;
    while (lo + 1u < hi) {
        size_t mid = lo + (hi - lo) / 2u;
        if (st->history[mid].start_byte <= byte) lo = mid;
        else                                       hi = mid;
    }
    /* Confirm `byte` is within the candidate's span. */
    if (st->history[lo].start_byte <= byte && byte < st->history[lo].end_byte) {
        *out_token_idx = lo;
        return 1;
    }
    return 0;
}

int iii_lex_token_history_at(const iii_lex_state_t *st, size_t i,
                              iii_token_t *out_token)
{
    if (!st || !out_token) return 0;
    if (i >= st->history_count) return 0;
    *out_token = st->history[i];
    return 1;
}

size_t iii_lex_token_count(const iii_lex_state_t *st)
{
    return st ? st->history_count : 0u;
}

void iii_lex_set_logical_position(iii_lex_state_t *st,
                                    const char *logical_path,
                                    uint32_t logical_line,
                                    uint32_t logical_col)
{
    if (!st) return;
    st->logical_path = logical_path;
    st->logical_line = logical_line;
    st->logical_col  = logical_col;
}

/* ─── Public API: keyword registration (D2) ──────────────────────── */

int iii_lex_register_keyword(iii_lex_state_t *st,
                              const char *name, size_t name_len,
                              iii_token_kind_t kind)
{
    if (!st || !name) return III_LEX_E_NULL_ARG;
    if (st->sealed) return III_LEX_E_SEALED;

    /* Reject duplicates against built-in, modifier, and runtime tables. */
    if (iii_lookup_keyword((const uint8_t *)name, name_len) != III_TOK_INVALID)
        return III_LEX_E_DUPLICATE_KEYWORD;
    if (iii_lookup_modifier_kw((const uint8_t *)name, name_len) != III_TOK_INVALID)
        return III_LEX_E_DUPLICATE_KEYWORD;
    if (iii_lookup_runtime_kw(st, (const uint8_t *)name, name_len) != III_TOK_INVALID)
        return III_LEX_E_DUPLICATE_KEYWORD;

    /* Capacity. */
    if (st->runtime_kw_count == st->runtime_kw_cap) {
        size_t new_cap = (st->runtime_kw_cap == 0u)
                          ? III_RUNTIME_KW_CAP_INIT
                          : st->runtime_kw_cap * 2u;
        if (new_cap > III_RUNTIME_KW_CAP_MAX) return III_LEX_E_KEYWORD_TABLE_FULL;
        iii_runtime_kw_t *p = (iii_runtime_kw_t *)realloc(st->runtime_kw,
                                                            new_cap * sizeof(*p));
        if (!p) return III_LEX_E_OOM;
        st->runtime_kw = p;
        st->runtime_kw_cap = new_cap;
    }

    /* Copy name into the lex-state arena for stable lifetime. */
    uint8_t *copy = iii_arena_alloc(&st->arena, name_len);
    if (!copy) return III_LEX_E_OOM;
    memcpy(copy, name, name_len);

    iii_runtime_kw_t *e = &st->runtime_kw[st->runtime_kw_count++];
    e->name     = (const char *)copy;
    e->name_len = name_len;
    e->kind     = kind;
    return III_LEX_OK;
}

/* ─── Public API: arena introspection (D21) ──────────────────────── */

size_t iii_lex_arena_bytes(const iii_lex_state_t *st)
{
    if (!st) return 0u;
    return st->arena.total_bytes;
}

void iii_lex_arena_mhash(const iii_lex_state_t *st, uint8_t out_mhash[32])
{
    if (!out_mhash) return;
    memset(out_mhash, 0, 32);
    if (!st) return;
    iii_sha256_t h;
    iii_sha256_init(&h);
    /* Walk chunks head-first.  Stage-2 reproducibility: the order in
     * which the lexer allocated payloads is itself a function of the
     * (deterministic) source bytes. */
    for (const iii_chunk_t *c = st->arena.head; c != NULL; c = c->next) {
        iii_sha256_update(&h, c->data, c->used);
    }
    iii_sha256_final(&h, out_mhash);
}

/* ─── Public API: seal (D22) ─────────────────────────────────────── */

size_t iii_lex_seal(iii_lex_state_t *st, void **out_owned_block)
{
    if (!st || !out_owned_block) return 0u;
    *out_owned_block = NULL;
    if (st->sealed) return 0u;

    /* Compute total used bytes; collect chunks in head-first order. */
    size_t total = 0u;
    size_t chunk_count = 0u;
    for (const iii_chunk_t *c = st->arena.head; c != NULL; c = c->next) {
        total += c->used;
        chunk_count++;
    }
    if (total == 0u) {
        st->sealed = true;
        return 0u;
    }

    uint8_t *block = (uint8_t *)malloc(total);
    if (!block) return 0u;

    /* Build per-chunk (src_data, dst_offset, used) map. */
    typedef struct { const uint8_t *src_data; size_t dst_off; size_t used; } map_t;
    map_t *map = (map_t *)malloc(chunk_count * sizeof(*map));
    if (!map) { free(block); return 0u; }

    /* Head-first means dst_off accumulates from the head's data
     * forward.  History tokens hold pointers into chunk->data; we
     * remap them by finding their containing chunk and its dst_off. */
    size_t off = 0u;
    size_t i = 0u;
    for (const iii_chunk_t *c = st->arena.head; c != NULL; c = c->next) {
        memcpy(block + off, c->data, c->used);
        map[i].src_data = c->data;
        map[i].dst_off  = off;
        map[i].used     = c->used;
        off += c->used;
        i++;
    }

    /* Remap string_payload pointers in the token history. */
    for (size_t t = 0u; t < st->history_count; t++) {
        const uint8_t *p = st->history[t].string_payload;
        if (p == NULL || st->history[t].string_len == 0u) continue;
        for (size_t j = 0u; j < chunk_count; j++) {
            if (p >= map[j].src_data && p < map[j].src_data + map[j].used) {
                size_t intra = (size_t)(p - map[j].src_data);
                st->history[t].string_payload = block + map[j].dst_off + intra;
                break;
            }
        }
    }

    /* Remap runtime keyword name pointers, which also live in the
     * arena. */
    for (size_t k = 0u; k < st->runtime_kw_count; k++) {
        const uint8_t *p = (const uint8_t *)st->runtime_kw[k].name;
        if (!p) continue;
        for (size_t j = 0u; j < chunk_count; j++) {
            if (p >= map[j].src_data && p < map[j].src_data + map[j].used) {
                size_t intra = (size_t)(p - map[j].src_data);
                st->runtime_kw[k].name =
                    (const char *)(block + map[j].dst_off + intra);
                break;
            }
        }
    }

    free(map);

    /* Free the original chunks; mark sealed.  Future iii_lex_next
     * calls will return III_LEX_E_SEALED. */
    iii_arena_destroy(&st->arena);
    st->sealed = true;

    *out_owned_block = block;
    return total;
}
