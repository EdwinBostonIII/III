/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\acc.c
 *
 * III Stage-0 ACC implementation.
 *
 * Per CONSTITUTIONAL/include/acc.h.  Strict NIH (ADR-021); libc only.
 * Deterministic / reproducible (ADR-027).
 *
 * Compiled by iiis-0 (the III Stage-0 compiler).
 */

#include "acc.h"

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <string.h>

/* ---------------------------------------------------------------- *
 *  Globals                                                          *
 * ---------------------------------------------------------------- */

/* The 12 × u64 admitted bitmap.  Layout-identical to the runtime
 * g_xii_acc_admitted_z3_bitmap (see acc.h "Layout parity"). */
static uint64_t g_iii_acc_admitted_z3[III_ACC_Z3_BITMAP_WORDS] = { 0 };

/* Seal state. */
static int      g_iii_acc_sealed = 0;
static uint8_t  g_iii_acc_sealed_sha256[32] = { 0 };

/* Audit sink (off by default). */
static iii_acc_audit_fn g_iii_acc_audit_fn   = NULL;
static void            *g_iii_acc_audit_ctx  = NULL;
static uint16_t         g_iii_acc_audit_kind = 0u;

/* Z₃ addition LUT.  Index = a*3 + b, value = (a+b) mod 3.
 *           b=0  b=1  b=2
 *  a=0:      0    1    2
 *  a=1:      1    2    0
 *  a=2:      2    0    1
 */
const uint8_t g_iii_acc_z3_add_lut[9] = {
    0, 1, 2,
    1, 2, 0,
    2, 0, 1
};

/* ---------------------------------------------------------------- *
 *  Helpers — bit twiddling                                          *
 * ---------------------------------------------------------------- */

/* Mask off bits >= 729 in the high word.  729 - 64*11 = 25, so only
 * the low 25 bits of word[11] are meaningful. */
static inline uint64_t iii_acc_high_word_mask(void)
{
    return (1ull << (III_ACC_STATE_CARD - 64u * 11u)) - 1ull;
}

static inline uint8_t iii_acc_get_bit(uint32_t idx)
{
    return (uint8_t)((g_iii_acc_admitted_z3[idx >> 6] >> (idx & 63u)) & 1ull);
}

/* Set a bit; returns the prior value (0 or 1). */
static inline uint8_t iii_acc_set_bit_v(uint32_t idx, uint8_t v)
{
    const uint64_t mask  = 1ull << (idx & 63u);
    const uint64_t word  = g_iii_acc_admitted_z3[idx >> 6];
    const uint8_t  prior = (uint8_t)((word >> (idx & 63u)) & 1ull);
    if (v) g_iii_acc_admitted_z3[idx >> 6] = word |  mask;
    else   g_iii_acc_admitted_z3[idx >> 6] = word & ~mask;
    return prior;
}

static uint32_t iii_acc_popcount64(uint64_t x)
{
    /* Portable popcount — no compiler intrinsics, libc-only. */
    x = x - ((x >> 1) & 0x5555555555555555ull);
    x = (x & 0x3333333333333333ull) + ((x >> 2) & 0x3333333333333333ull);
    x = (x + (x >> 4)) & 0x0F0F0F0F0F0F0F0Full;
    return (uint32_t)((x * 0x0101010101010101ull) >> 56);
}

/* ---------------------------------------------------------------- *
 *  Init / mutation                                                  *
 * ---------------------------------------------------------------- */

void iii_acc_init_permissive(void)
{
    memset(g_iii_acc_admitted_z3, 0xFF, sizeof(g_iii_acc_admitted_z3));
    g_iii_acc_admitted_z3[11] = iii_acc_high_word_mask();
    g_iii_acc_sealed = 0;
    memset(g_iii_acc_sealed_sha256, 0, sizeof(g_iii_acc_sealed_sha256));
}

static void iii_acc_emit_audit(uint32_t idx, uint8_t prior, uint8_t new_bit)
{
    if (!g_iii_acc_audit_fn) return;
    if (prior == new_bit)    return;  /* delta log — no-ops elided */
    g_iii_acc_audit_fn((uint16_t)g_iii_acc_audit_kind,
                       (uint16_t)idx,
                       prior,
                       new_bit,
                       new_bit ? III_ACC_AUDIT_ADMIT : III_ACC_AUDIT_DENY,
                       g_iii_acc_audit_ctx);
}

iii_acc_status_t iii_acc_admit_index(uint32_t idx)
{
    if (idx >= III_ACC_STATE_CARD) return III_ACC_E_OUT_OF_RANGE;
    if (g_iii_acc_sealed)          return III_ACC_E_BITMAP_LOCKED;
    const uint8_t prior = iii_acc_set_bit_v(idx, 1);
    iii_acc_emit_audit(idx, prior, 1);
    return III_ACC_OK;
}

iii_acc_status_t iii_acc_deny_index(uint32_t idx)
{
    if (idx >= III_ACC_STATE_CARD) return III_ACC_E_OUT_OF_RANGE;
    if (g_iii_acc_sealed)          return III_ACC_E_BITMAP_LOCKED;
    const uint8_t prior = iii_acc_set_bit_v(idx, 0);
    iii_acc_emit_audit(idx, prior, 0);
    return III_ACC_OK;
}

int iii_acc_is_admitted_index(uint32_t idx)
{
    if (idx >= III_ACC_STATE_CARD) return 0;
    return (int)iii_acc_get_bit(idx);
}

/* ---------------------------------------------------------------- *
 *  Index ↔ state                                                    *
 * ---------------------------------------------------------------- */

iii_acc_status_t iii_acc_index_to_state(uint16_t idx, iii_acc_state_t *out)
{
    if (!out)                            return III_ACC_E_NULL;
    if ((uint32_t)idx >= III_ACC_STATE_CARD) return III_ACC_E_OUT_OF_RANGE;
    /* Inverse of iii_acc_state_to_z3_index: comp[5] is least
     * significant trit (because comp[0] is most significant). */
    uint32_t v = (uint32_t)idx;
    for (int i = III_ACC_COMP_COUNT - 1; i >= 0; i--) {
        out->comp[i] = v % 3u;
        v /= 3u;
    }
    return III_ACC_OK;
}

/* ---------------------------------------------------------------- *
 *  Admission queries                                                *
 * ---------------------------------------------------------------- */

int iii_acc_admit_state(const iii_acc_state_t *s)
{
    if (!s) return 0;
    return iii_acc_is_admitted_index(iii_acc_state_to_z3_index(s));
}

int iii_acc_admit_vector(const uint32_t comp[III_ACC_COMP_COUNT])
{
    if (!comp) return 0;
    iii_acc_state_t s;
    for (unsigned i = 0; i < III_ACC_COMP_COUNT; i++) s.comp[i] = comp[i];
    /* Documented invariant: must agree with admit_state. */
    return iii_acc_admit_state(&s);
}

int iii_acc_admitted(const iii_acc_state_t *s) { return iii_acc_admit_state(s); }

int iii_acc_compose_admitted(const iii_acc_state_t *a,
                             const iii_acc_state_t *b)
{
    if (!a || !b) return 0;
    iii_acc_state_t c;
    iii_acc_compose(&c, a, b);
    return iii_acc_admit_state(&c);
}

/* ---------------------------------------------------------------- *
 *  Diagnostics                                                      *
 * ---------------------------------------------------------------- */

uint32_t iii_acc_count_admitted(void)
{
    uint32_t n = 0;
    for (unsigned w = 0; w < III_ACC_Z3_BITMAP_WORDS - 1u; w++) {
        n += iii_acc_popcount64(g_iii_acc_admitted_z3[w]);
    }
    /* Mask the high word to the canonical 25 meaningful bits. */
    n += iii_acc_popcount64(g_iii_acc_admitted_z3[11] & iii_acc_high_word_mask());
    return n;
}

iii_acc_status_t iii_acc_canonical_bytes(uint8_t out[III_ACC_BITMAP_CANON_BYTES])
{
    if (!out) return III_ACC_E_NULL;
    /* Emit little-endian bytes from the 12 × u64 array, then truncate
     * to 92 bytes and mask the trailing 7 bits of byte 91 (the only
     * meaningful bit there is bit 0 = state index 728). */
    uint8_t raw[III_ACC_Z3_BITMAP_WORDS * 8u];
    for (unsigned w = 0; w < III_ACC_Z3_BITMAP_WORDS; w++) {
        const uint64_t v = g_iii_acc_admitted_z3[w];
        raw[w*8 + 0] = (uint8_t)(v       & 0xFFu);
        raw[w*8 + 1] = (uint8_t)(v >>  8 & 0xFFu);
        raw[w*8 + 2] = (uint8_t)(v >> 16 & 0xFFu);
        raw[w*8 + 3] = (uint8_t)(v >> 24 & 0xFFu);
        raw[w*8 + 4] = (uint8_t)(v >> 32 & 0xFFu);
        raw[w*8 + 5] = (uint8_t)(v >> 40 & 0xFFu);
        raw[w*8 + 6] = (uint8_t)(v >> 48 & 0xFFu);
        raw[w*8 + 7] = (uint8_t)(v >> 56 & 0xFFu);
    }
    memcpy(out, raw, III_ACC_BITMAP_CANON_BYTES);
    /* 729 mod 8 = 1; meaningful bit count in byte 91 is 1. */
    out[III_ACC_BITMAP_CANON_BYTES - 1u] &= 0x01u;
    return III_ACC_OK;
}

uint64_t iii_acc_bitmap_fingerprint(void)
{
    uint8_t buf[III_ACC_BITMAP_CANON_BYTES];
    (void)iii_acc_canonical_bytes(buf);
    /* FNV-1a 64-bit, deterministic, content-only. */
    uint64_t h = 0xcbf29ce484222325ull;
    for (unsigned i = 0; i < III_ACC_BITMAP_CANON_BYTES; i++) {
        h ^= (uint64_t)buf[i];
        h *= 0x100000001b3ull;
    }
    return h;
}

/* ---------------------------------------------------------------- *
 *  SHA-256 (minimal, portable, byte-oriented).                      *
 *                                                                   *
 *  Self-contained (ADR-021).  Operates on the canonical 92-byte    *
 *  serialized bitmap only — never on in-memory representations     *
 *  that include uninitialised pad bits.                            *
 * ---------------------------------------------------------------- */

static const uint32_t k_iii_sha256_k[64] = {
    0x428a2f98u,0x71374491u,0xb5c0fbcfu,0xe9b5dba5u,0x3956c25bu,0x59f111f1u,0x923f82a4u,0xab1c5ed5u,
    0xd807aa98u,0x12835b01u,0x243185beu,0x550c7dc3u,0x72be5d74u,0x80deb1feu,0x9bdc06a7u,0xc19bf174u,
    0xe49b69c1u,0xefbe4786u,0x0fc19dc6u,0x240ca1ccu,0x2de92c6fu,0x4a7484aau,0x5cb0a9dcu,0x76f988dau,
    0x983e5152u,0xa831c66du,0xb00327c8u,0xbf597fc7u,0xc6e00bf3u,0xd5a79147u,0x06ca6351u,0x14292967u,
    0x27b70a85u,0x2e1b2138u,0x4d2c6dfcu,0x53380d13u,0x650a7354u,0x766a0abbu,0x81c2c92eu,0x92722c85u,
    0xa2bfe8a1u,0xa81a664bu,0xc24b8b70u,0xc76c51a3u,0xd192e819u,0xd6990624u,0xf40e3585u,0x106aa070u,
    0x19a4c116u,0x1e376c08u,0x2748774cu,0x34b0bcb5u,0x391c0cb3u,0x4ed8aa4au,0x5b9cca4fu,0x682e6ff3u,
    0x748f82eeu,0x78a5636fu,0x84c87814u,0x8cc70208u,0x90befffau,0xa4506cebu,0xbef9a3f7u,0xc67178f2u
};

static inline uint32_t iii_sha256_rotr(uint32_t x, unsigned n) {
    return (x >> n) | (x << (32u - n));
}

static void iii_sha256_compress(uint32_t state[8], const uint8_t block[64])
{
    uint32_t w[64];
    for (unsigned i = 0; i < 16; i++) {
        w[i] = ((uint32_t)block[i*4 + 0] << 24)
             | ((uint32_t)block[i*4 + 1] << 16)
             | ((uint32_t)block[i*4 + 2] <<  8)
             | ((uint32_t)block[i*4 + 3]);
    }
    for (unsigned i = 16; i < 64; i++) {
        const uint32_t s0 = iii_sha256_rotr(w[i-15], 7) ^ iii_sha256_rotr(w[i-15],18) ^ (w[i-15] >> 3);
        const uint32_t s1 = iii_sha256_rotr(w[i- 2],17) ^ iii_sha256_rotr(w[i- 2],19) ^ (w[i- 2] >>10);
        w[i] = w[i-16] + s0 + w[i-7] + s1;
    }
    uint32_t a = state[0], b = state[1], c = state[2], d = state[3];
    uint32_t e = state[4], f = state[5], g = state[6], h = state[7];
    for (unsigned i = 0; i < 64; i++) {
        const uint32_t S1 = iii_sha256_rotr(e,6) ^ iii_sha256_rotr(e,11) ^ iii_sha256_rotr(e,25);
        const uint32_t ch = (e & f) ^ (~e & g);
        const uint32_t t1 = h + S1 + ch + k_iii_sha256_k[i] + w[i];
        const uint32_t S0 = iii_sha256_rotr(a,2) ^ iii_sha256_rotr(a,13) ^ iii_sha256_rotr(a,22);
        const uint32_t mj = (a & b) ^ (a & c) ^ (b & c);
        const uint32_t t2 = S0 + mj;
        h = g; g = f; f = e; e = d + t1;
        d = c; c = b; b = a; a = t1 + t2;
    }
    state[0]+=a; state[1]+=b; state[2]+=c; state[3]+=d;
    state[4]+=e; state[5]+=f; state[6]+=g; state[7]+=h;
}

static void iii_sha256(const uint8_t *msg, size_t len, uint8_t out[32])
{
    uint32_t state[8] = {
        0x6a09e667u,0xbb67ae85u,0x3c6ef372u,0xa54ff53au,
        0x510e527fu,0x9b05688cu,0x1f83d9abu,0x5be0cd19u
    };
    /* For the canonical 92-byte input the padded length is fixed: one
     * 64-byte block + a final 64-byte block containing the tail, the
     * 0x80 sentinel, zero padding, and the 64-bit big-endian length.
     * We implement the general case anyway. */
    uint8_t block[64];
    size_t off = 0;
    while (len - off >= 64u) {
        iii_sha256_compress(state, msg + off);
        off += 64u;
    }
    const size_t rem = len - off;
    memset(block, 0, sizeof(block));
    memcpy(block, msg + off, rem);
    block[rem] = 0x80u;
    if (rem >= 56u) {
        iii_sha256_compress(state, block);
        memset(block, 0, sizeof(block));
    }
    const uint64_t bit_len = (uint64_t)len * 8ull;
    block[56] = (uint8_t)(bit_len >> 56);
    block[57] = (uint8_t)(bit_len >> 48);
    block[58] = (uint8_t)(bit_len >> 40);
    block[59] = (uint8_t)(bit_len >> 32);
    block[60] = (uint8_t)(bit_len >> 24);
    block[61] = (uint8_t)(bit_len >> 16);
    block[62] = (uint8_t)(bit_len >>  8);
    block[63] = (uint8_t)(bit_len      );
    iii_sha256_compress(state, block);
    for (unsigned i = 0; i < 8; i++) {
        out[i*4 + 0] = (uint8_t)(state[i] >> 24);
        out[i*4 + 1] = (uint8_t)(state[i] >> 16);
        out[i*4 + 2] = (uint8_t)(state[i] >>  8);
        out[i*4 + 3] = (uint8_t)(state[i]      );
    }
}

iii_acc_status_t iii_acc_bitmap_sha256(uint8_t out[32])
{
    if (!out) return III_ACC_E_NULL;
    uint8_t canon[III_ACC_BITMAP_CANON_BYTES];
    (void)iii_acc_canonical_bytes(canon);
    iii_sha256(canon, sizeof(canon), out);
    return III_ACC_OK;
}

/* ---------------------------------------------------------------- *
 *  Audit hook                                                       *
 * ---------------------------------------------------------------- */

void iii_acc_set_audit_cycle_kind(uint16_t cycle_kind)
{
    g_iii_acc_audit_kind = cycle_kind;
}

void iii_acc_set_audit_sink(iii_acc_audit_fn fn, void *ctx)
{
    g_iii_acc_audit_fn  = fn;
    g_iii_acc_audit_ctx = ctx;
}

/* ---------------------------------------------------------------- *
 *  Seal / self-check                                                *
 * ---------------------------------------------------------------- */

iii_acc_status_t iii_acc_seal(void)
{
    if (g_iii_acc_sealed) {
        /* Idempotent: re-record (which will of course match). */
        uint8_t cur[32];
        (void)iii_acc_bitmap_sha256(cur);
        if (memcmp(cur, g_iii_acc_sealed_sha256, 32) != 0) {
            /* Should be unreachable while sealed; defensive. */
            return III_ACC_E_BITMAP_LOCKED;
        }
        return III_ACC_OK;
    }
    (void)iii_acc_bitmap_sha256(g_iii_acc_sealed_sha256);
    g_iii_acc_sealed = 1;
    return III_ACC_OK;
}

int iii_acc_is_sealed(void) { return g_iii_acc_sealed; }

iii_acc_status_t iii_acc_self_check(void)
{
    if (!g_iii_acc_sealed) return III_ACC_E_NOT_SEALED;
    uint8_t cur[32];
    (void)iii_acc_bitmap_sha256(cur);
    return (memcmp(cur, g_iii_acc_sealed_sha256, 32) == 0)
                ? III_ACC_OK
                : III_ACC_E_SELF_CHECK_FAIL;
}

/* ---------------------------------------------------------------- *
 *  Hexad decode                                                     *
 * ---------------------------------------------------------------- */

void iii_acc_state_from_hexad(uint16_t hexad, iii_acc_state_t *out)
{
    if (!out) return;
    for (unsigned i = 0; i < III_ACC_COMP_COUNT; i++) {
        const uint8_t code = (uint8_t)((hexad >> (i * 2u)) & 3u);
        switch (code) {
            case 0: out->comp[i] = 2u; break;  /* NEG  → 2 */
            case 1: out->comp[i] = 0u; break;  /* ZERO → 0 */
            case 2: out->comp[i] = 1u; break;  /* POS  → 1 */
            default: out->comp[i] = 0u; break; /* INVALID → 0 */
        }
    }
}
