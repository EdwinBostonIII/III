/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\hexad_check.c
 *
 * III Stage-0 Hexad Admission Bitmap — implementation.
 *
 * Mirrors TYPES/src/hexad.c byte-for-byte at the bitmap level so that
 * iii_hexad_bitmap_mhash() (this module) and iii_hexad_bitmap_hash()
 * (TYPES library) compute identical SHA-256 digests.  See hexad_check.h
 * "Bitmap parity contract" for the exact rule.
 *
 * Strict NIH per ADR-021: only stdlib.  Hand-rolled SHA-256 lives
 * statically inside this TU (FIPS 180-4); kept private so cross-TU
 * link order is irrelevant and ASSAN-style boundary fuzzing on the
 * bitmap stays self-contained.
 */

#include "hexad_check.h"

#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include <stdbool.h>

/* ============================================================================
 *  PRIVATE SHA-256 (FIPS 180-4 §6.2)
 *  Identical algorithm to main.c::iii_sha256_*; duplicated here to keep
 *  this TU self-contained (no inter-TU symbol coupling on a hot, leaf
 *  module that the entire pipeline depends on).
 * ============================================================================ */

typedef struct {
    uint32_t h[8];
    uint64_t bits;
    uint8_t  buf[64];
    size_t   buflen;
} hxc_sha_t;

static const uint32_t HXC_K[64] = {
    0x428a2f98u,0x71374491u,0xb5c0fbcfu,0xe9b5dba5u,0x3956c25bu,0x59f111f1u,0x923f82a4u,0xab1c5ed5u,
    0xd807aa98u,0x12835b01u,0x243185beu,0x550c7dc3u,0x72be5d74u,0x80deb1feu,0x9bdc06a7u,0xc19bf174u,
    0xe49b69c1u,0xefbe4786u,0x0fc19dc6u,0x240ca1ccu,0x2de92c6fu,0x4a7484aau,0x5cb0a9dcu,0x76f988dau,
    0x983e5152u,0xa831c66du,0xb00327c8u,0xbf597fc7u,0xc6e00bf3u,0xd5a79147u,0x06ca6351u,0x14292967u,
    0x27b70a85u,0x2e1b2138u,0x4d2c6dfcu,0x53380d13u,0x650a7354u,0x766a0abbu,0x81c2c92eu,0x92722c85u,
    0xa2bfe8a1u,0xa81a664bu,0xc24b8b70u,0xc76c51a3u,0xd192e819u,0xd6990624u,0xf40e3585u,0x106aa070u,
    0x19a4c116u,0x1e376c08u,0x2748774cu,0x34b0bcb5u,0x391c0cb3u,0x4ed8aa4au,0x5b9cca4fu,0x682e6ff3u,
    0x748f82eeu,0x78a5636fu,0x84c87814u,0x8cc70208u,0x90befffau,0xa4506cebu,0xbef9a3f7u,0xc67178f2u
};

static uint32_t hxc_rotr(uint32_t x, unsigned n) { return (x >> n) | (x << (32 - n)); }

static void hxc_sha_init(hxc_sha_t *c)
{
    c->h[0]=0x6a09e667u; c->h[1]=0xbb67ae85u; c->h[2]=0x3c6ef372u; c->h[3]=0xa54ff53au;
    c->h[4]=0x510e527fu; c->h[5]=0x9b05688cu; c->h[6]=0x1f83d9abu; c->h[7]=0x5be0cd19u;
    c->bits = 0; c->buflen = 0;
}

static void hxc_sha_block(hxc_sha_t *c, const uint8_t blk[64])
{
    uint32_t w[64];
    for (int i = 0; i < 16; i++) {
        w[i] = ((uint32_t)blk[i*4]<<24)|((uint32_t)blk[i*4+1]<<16)|
               ((uint32_t)blk[i*4+2]<<8)|((uint32_t)blk[i*4+3]);
    }
    for (int i = 16; i < 64; i++) {
        uint32_t s0 = hxc_rotr(w[i-15],7) ^ hxc_rotr(w[i-15],18) ^ (w[i-15] >> 3);
        uint32_t s1 = hxc_rotr(w[i-2],17) ^ hxc_rotr(w[i-2],19)  ^ (w[i-2]  >> 10);
        w[i] = w[i-16] + s0 + w[i-7] + s1;
    }
    uint32_t a=c->h[0],b=c->h[1],cc=c->h[2],d=c->h[3],e=c->h[4],f=c->h[5],g=c->h[6],h=c->h[7];
    for (int i = 0; i < 64; i++) {
        uint32_t S1 = hxc_rotr(e,6) ^ hxc_rotr(e,11) ^ hxc_rotr(e,25);
        uint32_t ch = (e & f) ^ (~e & g);
        uint32_t t1 = h + S1 + ch + HXC_K[i] + w[i];
        uint32_t S0 = hxc_rotr(a,2) ^ hxc_rotr(a,13) ^ hxc_rotr(a,22);
        uint32_t mj = (a & b) ^ (a & cc) ^ (b & cc);
        uint32_t t2 = S0 + mj;
        h = g; g = f; f = e; e = d + t1; d = cc; cc = b; b = a; a = t1 + t2;
    }
    c->h[0]+=a; c->h[1]+=b; c->h[2]+=cc; c->h[3]+=d;
    c->h[4]+=e; c->h[5]+=f; c->h[6]+=g;  c->h[7]+=h;
}

static void hxc_sha_update(hxc_sha_t *c, const void *data, size_t len)
{
    const uint8_t *p = (const uint8_t *)data;
    c->bits += (uint64_t)len * 8;
    while (len) {
        size_t take = 64 - c->buflen;
        if (take > len) take = len;
        memcpy(c->buf + c->buflen, p, take);
        c->buflen += take; p += take; len -= take;
        if (c->buflen == 64) { hxc_sha_block(c, c->buf); c->buflen = 0; }
    }
}

static void hxc_sha_final(hxc_sha_t *c, uint8_t out[32])
{
    uint64_t bits = c->bits;
    uint8_t pad = 0x80;
    hxc_sha_update(c, &pad, 1);
    uint8_t zero = 0;
    while (c->buflen != 56) hxc_sha_update(c, &zero, 1);
    uint8_t lenbe[8];
    for (int i = 0; i < 8; i++) lenbe[i] = (uint8_t)(bits >> (56 - 8*i));
    hxc_sha_update(c, lenbe, 8);
    for (int i = 0; i < 8; i++) {
        out[i*4]   = (uint8_t)(c->h[i] >> 24);
        out[i*4+1] = (uint8_t)(c->h[i] >> 16);
        out[i*4+2] = (uint8_t)(c->h[i] >> 8);
        out[i*4+3] = (uint8_t)(c->h[i]);
    }
}

/* ============================================================================
 *  THE BITMAP
 *  144 bytes; bit i (0..728) admitted iff (g_bitmap[i/8] >> (i%8)) & 1.
 *  Bits 729..1151 (the padding) are forced to zero for canonical-form
 *  hashing parity with the runtime.
 * ============================================================================ */

static uint8_t g_bitmap[III_HEXAD_BITMAP_BYTES];
static bool    g_bitmap_init = false;

/* ─── Helpers ──────────────────────────────────────────────────── */

static bool hxc_trit_valid(uint8_t t) {
    return t == III_HEXAD_TRIT_NEG || t == III_HEXAD_TRIT_ZERO || t == III_HEXAD_TRIT_POS;
}

/* Asymmetric trit composition (mirror of TYPES iii_trit_compose):
 *   ZERO is identity; NEG dominates; POS ⊙ POS = POS.  Inputs out of
 *   range yield III_HEXAD_TRIT_INVALID. */
static uint8_t hxc_trit_compose(uint8_t a, uint8_t b)
{
    if (!hxc_trit_valid(a) || !hxc_trit_valid(b)) return III_HEXAD_TRIT_INVALID;
    if (a == III_HEXAD_TRIT_ZERO) return b;
    if (b == III_HEXAD_TRIT_ZERO) return a;
    if (a == III_HEXAD_TRIT_NEG || b == III_HEXAD_TRIT_NEG) return III_HEXAD_TRIT_NEG;
    return III_HEXAD_TRIT_POS;
}

static uint8_t hxc_trit_neg(uint8_t a)
{
    switch (a) {
        case III_HEXAD_TRIT_NEG:  return III_HEXAD_TRIT_POS;
        case III_HEXAD_TRIT_POS:  return III_HEXAD_TRIT_NEG;
        case III_HEXAD_TRIT_ZERO: return III_HEXAD_TRIT_ZERO;
        default:                  return III_HEXAD_TRIT_INVALID;
    }
}

/* Pillar-position-aware composition operands (III-HEXAD.md §2.4, mirroring
 * HEXAD/src/hexad_algebra.c T_AND / T_OR).
 *   AND: NEG dominates; POS iff both POS; else ZERO.
 *   OR : POS dominates; NEG iff both NEG; else ZERO. */
static uint8_t hxc_trit_and(uint8_t a, uint8_t b)
{
    if (!hxc_trit_valid(a) || !hxc_trit_valid(b)) return III_HEXAD_TRIT_INVALID;
    if (a == III_HEXAD_TRIT_NEG || b == III_HEXAD_TRIT_NEG) return III_HEXAD_TRIT_NEG;
    if (a == III_HEXAD_TRIT_POS && b == III_HEXAD_TRIT_POS) return III_HEXAD_TRIT_POS;
    return III_HEXAD_TRIT_ZERO;
}
static uint8_t hxc_trit_or(uint8_t a, uint8_t b)
{
    if (!hxc_trit_valid(a) || !hxc_trit_valid(b)) return III_HEXAD_TRIT_INVALID;
    if (a == III_HEXAD_TRIT_POS || b == III_HEXAD_TRIT_POS) return III_HEXAD_TRIT_POS;
    if (a == III_HEXAD_TRIT_NEG && b == III_HEXAD_TRIT_NEG) return III_HEXAD_TRIT_NEG;
    return III_HEXAD_TRIT_ZERO;
}

/* ============================================================================
 *  PFS BRICKING TABLE
 *  Values per III-HEXAD §4.2 + III-EFFECTS §1.3 + TYPES/src/hexad.c.
 *  Pillars are listed P0..P5 LEFT-TO-RIGHT (P0 is the LSB at pack time).
 * ============================================================================ */

static const uint8_t HXC_BRICK_PILLARS[III_BRICK__COUNT][6] = {
    /* CAPSULE_UPDATE   (NEG, NEG, NEG, NEG, ZERO, ZERO) */
    { III_HEXAD_TRIT_NEG, III_HEXAD_TRIT_NEG, III_HEXAD_TRIT_NEG,
      III_HEXAD_TRIT_NEG, III_HEXAD_TRIT_ZERO, III_HEXAD_TRIT_ZERO },
    /* MICROCODE_LOAD   (NEG, NEG, NEG, ZERO, ZERO, ZERO) */
    { III_HEXAD_TRIT_NEG, III_HEXAD_TRIT_NEG, III_HEXAD_TRIT_NEG,
      III_HEXAD_TRIT_ZERO, III_HEXAD_TRIT_ZERO, III_HEXAD_TRIT_ZERO },
    /* BOOTORDER_SET    (NEG, NEG, ZERO, NEG, ZERO, ZERO) */
    { III_HEXAD_TRIT_NEG, III_HEXAD_TRIT_NEG, III_HEXAD_TRIT_ZERO,
      III_HEXAD_TRIT_NEG, III_HEXAD_TRIT_ZERO, III_HEXAD_TRIT_ZERO },
    /* REAL_NVRAM_WRITE (NEG, ZERO, NEG, NEG, ZERO, ZERO) */
    { III_HEXAD_TRIT_NEG, III_HEXAD_TRIT_ZERO, III_HEXAD_TRIT_NEG,
      III_HEXAD_TRIT_NEG, III_HEXAD_TRIT_ZERO, III_HEXAD_TRIT_ZERO },
    /* ME_PSP_MAILBOX   (ZERO, NEG, NEG, NEG, ZERO, ZERO) */
    { III_HEXAD_TRIT_ZERO, III_HEXAD_TRIT_NEG, III_HEXAD_TRIT_NEG,
      III_HEXAD_TRIT_NEG, III_HEXAD_TRIT_ZERO, III_HEXAD_TRIT_ZERO },
    /* SMRAM_WRITE      (NEG, NEG, NEG, NEG, NEG, ZERO) */
    { III_HEXAD_TRIT_NEG, III_HEXAD_TRIT_NEG, III_HEXAD_TRIT_NEG,
      III_HEXAD_TRIT_NEG, III_HEXAD_TRIT_NEG, III_HEXAD_TRIT_ZERO }
};

static const char *const HXC_BRICK_NAMES[III_BRICK__COUNT] = {
    "capsule_update",
    "microcode_load",
    "bootorder_set",
    "real_nvram_write",
    "me_psp_mailbox",
    "smram_write"
};

/* ============================================================================
 *  PUBLIC: pack / unpack
 * ============================================================================ */

uint16_t iii_hexad_pack_pillars(const uint8_t pillars[6])
{
    if (!pillars) return 0xFFFFu;
    uint16_t v = 0;
    uint16_t base = 1;
    for (int i = 0; i < 6; i++) {
        uint8_t t = pillars[i];
        if (!hxc_trit_valid(t)) return 0xFFFFu;
        v = (uint16_t)(v + (uint16_t)t * base);
        base = (uint16_t)(base * 3);
    }
    return v;
}

void iii_hexad_unpack_pillars(uint16_t packed, uint8_t out[6])
{
    if (!out) return;
    if (packed >= III_HEXAD_BITMAP_SLOTS) {
        for (int i = 0; i < 6; i++) out[i] = III_HEXAD_TRIT_INVALID;
        return;
    }
    for (int i = 0; i < 6; i++) {
        out[i] = (uint8_t)(packed % 3u);
        packed = (uint16_t)(packed / 3u);
    }
}

uint8_t iii_hexad_pillar(uint16_t packed, unsigned pillar_index)
{
    if (pillar_index >= 6 || packed >= III_HEXAD_BITMAP_SLOTS) {
        return III_HEXAD_TRIT_INVALID;
    }
    /* Trit at position p == (packed / 3^p) % 3 */
    uint16_t v = packed;
    for (unsigned i = 0; i < pillar_index; i++) v = (uint16_t)(v / 3u);
    return (uint8_t)(v % 3u);
}

/* ─── AST-trit ↔ pillar-trit bridge ─────────────────────────────── */

static uint8_t hxc_trit_from_ast(iii_ast_trit_t t)
{
    /* ast.h:  III_TRIT_AST_NEG=0, III_TRIT_AST_ZERO=1, III_TRIT_AST_POS=2,
     *         III_TRIT_AST_INVALID=3.
     * hexad:  III_HEXAD_TRIT_NEG=0,  III_HEXAD_TRIT_ZERO=1, III_HEXAD_TRIT_POS=2,
     *         III_HEXAD_TRIT_INVALID=3.
     * 1:1 by construction; we still validate to harden against future
     * AST-enum drift. */
    switch (t) {
        case III_TRIT_AST_NEG:     return III_HEXAD_TRIT_NEG;
        case III_TRIT_AST_ZERO:    return III_HEXAD_TRIT_ZERO;
        case III_TRIT_AST_POS:     return III_HEXAD_TRIT_POS;
        case III_TRIT_AST_INVALID: return III_HEXAD_TRIT_INVALID;
    }
    return III_HEXAD_TRIT_INVALID;
}

static iii_ast_trit_t hxc_trit_to_ast(uint8_t t)
{
    switch (t) {
        case III_HEXAD_TRIT_NEG:  return III_TRIT_AST_NEG;
        case III_HEXAD_TRIT_ZERO: return III_TRIT_AST_ZERO;
        case III_HEXAD_TRIT_POS:  return III_TRIT_AST_POS;
        default:                  return III_TRIT_AST_INVALID;
    }
}

uint16_t iii_hexad_pack_from_ast_trits(const iii_ast_trit_t trits[6])
{
    if (!trits) return 0xFFFFu;
    uint8_t pillars[6];
    for (int i = 0; i < 6; i++) {
        pillars[i] = hxc_trit_from_ast(trits[i]);
        if (pillars[i] == III_HEXAD_TRIT_INVALID) return 0xFFFFu;
    }
    return iii_hexad_pack_pillars(pillars);
}

void iii_hexad_unpack_to_ast_trits(uint16_t packed, iii_ast_trit_t out[6])
{
    if (!out) return;
    uint8_t pillars[6];
    iii_hexad_unpack_pillars(packed, pillars);
    for (int i = 0; i < 6; i++) out[i] = hxc_trit_to_ast(pillars[i]);
}

/* ============================================================================
 *  PUBLIC: composition
 * ============================================================================ */

uint16_t iii_hexad_compose_packed(uint16_t a, uint16_t b)
{
    if (a >= III_HEXAD_BITMAP_SLOTS || b >= III_HEXAD_BITMAP_SLOTS) return 0xFFFFu;
    uint8_t pa[6], pb[6], pc[6];
    iii_hexad_unpack_pillars(a, pa);
    iii_hexad_unpack_pillars(b, pb);
    /* §2.4 pillar-position-aware compose: AND on pillars 1..4 (idx 0..3),
     * OR on pillars 5..6 (idx 4..5).  Matches HEXAD/src iii_hexad_compose6;
     * the prior uniform hxc_trit_compose over all six was the spec defect. */
    for (int i = 0; i < 4; i++) {
        pc[i] = hxc_trit_and(pa[i], pb[i]);
        if (pc[i] == III_HEXAD_TRIT_INVALID) return 0xFFFFu;
    }
    for (int i = 4; i < 6; i++) {
        pc[i] = hxc_trit_or(pa[i], pb[i]);
        if (pc[i] == III_HEXAD_TRIT_INVALID) return 0xFFFFu;
    }
    return iii_hexad_pack_pillars(pc);
}

uint16_t iii_hexad_neg_packed(uint16_t packed)
{
    if (packed >= III_HEXAD_BITMAP_SLOTS) return 0xFFFFu;
    uint8_t p[6];
    iii_hexad_unpack_pillars(packed, p);
    for (int i = 0; i < 6; i++) p[i] = hxc_trit_neg(p[i]);
    return iii_hexad_pack_pillars(p);
}

uint16_t iii_hexad_active_neg_packed(uint16_t packed)
{
    if (packed >= III_HEXAD_BITMAP_SLOTS) return 0xFFFFu;
    uint8_t p[6];
    iii_hexad_unpack_pillars(packed, p);
    /* §3.5 of TYPES: flip pillars 1..4; preserve 0 and 5. */
    for (int i = 1; i <= 4; i++) p[i] = hxc_trit_neg(p[i]);
    return iii_hexad_pack_pillars(p);
}

/* ============================================================================
 *  PUBLIC: PFS table
 * ============================================================================ */

uint16_t iii_hexad_brick_packed(iii_brick_t which)
{
    if ((unsigned)which >= III_BRICK__COUNT) return 0xFFFFu;
    return iii_hexad_pack_pillars(HXC_BRICK_PILLARS[(unsigned)which]);
}

const char *iii_hexad_brick_name(iii_brick_t which)
{
    if ((unsigned)which >= III_BRICK__COUNT) return "unknown";
    return HXC_BRICK_NAMES[(unsigned)which];
}

/* ============================================================================
 *  BITMAP INIT
 *  Mirror of TYPES/src/hexad.c::bitmap_init — all bits set, then pad
 *  cleared, then six bricking hexads cleared.
 * ============================================================================ */

void iii_hexad_check_init(void)
{
    if (g_bitmap_init) return;
    /* Default: every hexad in the canonical [0,728] range admitted. */
    memset(g_bitmap, 0xFF, sizeof g_bitmap);
    /* Clear bits past 728 (pad).  These bits live in bytes 91..143 high
     * portions; we walk individually for byte-canonical parity with
     * TYPES/src/hexad.c. */
    for (uint32_t i = III_HEXAD_BITMAP_SLOTS; i < (uint32_t)III_HEXAD_BITMAP_BYTES * 8u; i++) {
        g_bitmap[i / 8u] = (uint8_t)(g_bitmap[i / 8u] & ~(1u << (i % 8u)));
    }
    /* Clear the six bricking hexads. */
    for (unsigned b = 0; b < III_BRICK__COUNT; b++) {
        uint16_t p = iii_hexad_pack_pillars(HXC_BRICK_PILLARS[b]);
        if (p < III_HEXAD_BITMAP_SLOTS) {
            g_bitmap[p / 8u] = (uint8_t)(g_bitmap[p / 8u] & ~(1u << (p % 8u)));
        }
    }
    g_bitmap_init = true;
}

bool iii_hexad_check_is_init(void) { return g_bitmap_init; }

/* ============================================================================
 *  PUBLIC: admission
 * ============================================================================ */

bool iii_hexad_packed_admitted(uint16_t packed)
{
    if (!g_bitmap_init) iii_hexad_check_init();
    if (packed >= III_HEXAD_BITMAP_SLOTS) return false;
    return ((g_bitmap[packed / 8u] >> (packed % 8u)) & 1u) != 0u;
}

bool iii_hexad_pillars_admitted(const uint8_t pillars[6])
{
    uint16_t p = iii_hexad_pack_pillars(pillars);
    if (p == 0xFFFFu) return false;
    return iii_hexad_packed_admitted(p);
}

/* ============================================================================
 *  PUBLIC: introspection
 * ============================================================================ */

void iii_hexad_canonical_bytes(uint8_t out[III_HEXAD_BITMAP_BYTES])
{
    if (!out) return;
    if (!g_bitmap_init) iii_hexad_check_init();
    memcpy(out, g_bitmap, III_HEXAD_BITMAP_BYTES);
}

void iii_hexad_bitmap_mhash(uint8_t out[32])
{
    if (!out) return;
    if (!g_bitmap_init) iii_hexad_check_init();
    hxc_sha_t c;
    hxc_sha_init(&c);
    hxc_sha_update(&c, g_bitmap, sizeof g_bitmap);
    hxc_sha_final(&c, out);
}

uint32_t iii_hexad_count_admitted(void)
{
    if (!g_bitmap_init) iii_hexad_check_init();
    uint32_t n = 0;
    for (uint16_t i = 0; i < III_HEXAD_BITMAP_SLOTS; i++) {
        if ((g_bitmap[i / 8u] >> (i % 8u)) & 1u) n++;
    }
    return n;
}
