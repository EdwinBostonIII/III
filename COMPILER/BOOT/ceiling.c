/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\ceiling.c
 *
 * III Stage-0 Ceiling Membership Ledger — implementation.
 *
 * 65,536-bit bitmap indexed by cycle_kind.  Default state: deny-all.
 * iii_ceil_admit_kind() flips bits to allow; iii_ceil_seal() freezes.
 *
 * Strict NIH: only stdlib.  Hand-rolled SHA-256 lives statically inside
 * this TU for the same self-containment reason as hexad_check.c.
 */

#include "ceiling.h"

#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include <stdbool.h>

/* ============================================================================
 *  PRIVATE SHA-256 (FIPS 180-4 §6.2)
 * ============================================================================ */

typedef struct {
    uint32_t h[8];
    uint64_t bits;
    uint8_t  buf[64];
    size_t   buflen;
} cl_sha_t;

static const uint32_t CL_K[64] = {
    0x428a2f98u,0x71374491u,0xb5c0fbcfu,0xe9b5dba5u,0x3956c25bu,0x59f111f1u,0x923f82a4u,0xab1c5ed5u,
    0xd807aa98u,0x12835b01u,0x243185beu,0x550c7dc3u,0x72be5d74u,0x80deb1feu,0x9bdc06a7u,0xc19bf174u,
    0xe49b69c1u,0xefbe4786u,0x0fc19dc6u,0x240ca1ccu,0x2de92c6fu,0x4a7484aau,0x5cb0a9dcu,0x76f988dau,
    0x983e5152u,0xa831c66du,0xb00327c8u,0xbf597fc7u,0xc6e00bf3u,0xd5a79147u,0x06ca6351u,0x14292967u,
    0x27b70a85u,0x2e1b2138u,0x4d2c6dfcu,0x53380d13u,0x650a7354u,0x766a0abbu,0x81c2c92eu,0x92722c85u,
    0xa2bfe8a1u,0xa81a664bu,0xc24b8b70u,0xc76c51a3u,0xd192e819u,0xd6990624u,0xf40e3585u,0x106aa070u,
    0x19a4c116u,0x1e376c08u,0x2748774cu,0x34b0bcb5u,0x391c0cb3u,0x4ed8aa4au,0x5b9cca4fu,0x682e6ff3u,
    0x748f82eeu,0x78a5636fu,0x84c87814u,0x8cc70208u,0x90befffau,0xa4506cebu,0xbef9a3f7u,0xc67178f2u
};
static uint32_t cl_rotr(uint32_t x, unsigned n) { return (x >> n) | (x << (32 - n)); }

static void cl_sha_init(cl_sha_t *c) {
    c->h[0]=0x6a09e667u; c->h[1]=0xbb67ae85u; c->h[2]=0x3c6ef372u; c->h[3]=0xa54ff53au;
    c->h[4]=0x510e527fu; c->h[5]=0x9b05688cu; c->h[6]=0x1f83d9abu; c->h[7]=0x5be0cd19u;
    c->bits = 0; c->buflen = 0;
}
static void cl_sha_block(cl_sha_t *c, const uint8_t blk[64]) {
    uint32_t w[64];
    for (int i = 0; i < 16; i++)
        w[i] = ((uint32_t)blk[i*4]<<24)|((uint32_t)blk[i*4+1]<<16)|
               ((uint32_t)blk[i*4+2]<<8)|((uint32_t)blk[i*4+3]);
    for (int i = 16; i < 64; i++) {
        uint32_t s0 = cl_rotr(w[i-15],7)^cl_rotr(w[i-15],18)^(w[i-15]>>3);
        uint32_t s1 = cl_rotr(w[i-2],17)^cl_rotr(w[i-2],19)^(w[i-2]>>10);
        w[i] = w[i-16] + s0 + w[i-7] + s1;
    }
    uint32_t a=c->h[0],b=c->h[1],cc=c->h[2],d=c->h[3],e=c->h[4],f=c->h[5],g=c->h[6],h=c->h[7];
    for (int i = 0; i < 64; i++) {
        uint32_t S1 = cl_rotr(e,6)^cl_rotr(e,11)^cl_rotr(e,25);
        uint32_t ch = (e&f)^(~e&g);
        uint32_t t1 = h + S1 + ch + CL_K[i] + w[i];
        uint32_t S0 = cl_rotr(a,2)^cl_rotr(a,13)^cl_rotr(a,22);
        uint32_t mj = (a&b)^(a&cc)^(b&cc);
        uint32_t t2 = S0 + mj;
        h=g; g=f; f=e; e=d+t1; d=cc; cc=b; b=a; a=t1+t2;
    }
    c->h[0]+=a; c->h[1]+=b; c->h[2]+=cc; c->h[3]+=d;
    c->h[4]+=e; c->h[5]+=f; c->h[6]+=g; c->h[7]+=h;
}
static void cl_sha_update(cl_sha_t *c, const void *data, size_t len) {
    const uint8_t *p = (const uint8_t *)data;
    c->bits += (uint64_t)len * 8;
    while (len) {
        size_t take = 64 - c->buflen;
        if (take > len) take = len;
        memcpy(c->buf + c->buflen, p, take);
        c->buflen += take; p += take; len -= take;
        if (c->buflen == 64) { cl_sha_block(c, c->buf); c->buflen = 0; }
    }
}
static void cl_sha_final(cl_sha_t *c, uint8_t out[32]) {
    uint64_t bits = c->bits;
    uint8_t pad = 0x80;
    cl_sha_update(c, &pad, 1);
    uint8_t zero = 0;
    while (c->buflen != 56) cl_sha_update(c, &zero, 1);
    uint8_t lenbe[8];
    for (int i = 0; i < 8; i++) lenbe[i] = (uint8_t)(bits >> (56 - 8*i));
    cl_sha_update(c, lenbe, 8);
    for (int i = 0; i < 8; i++) {
        out[i*4]   = (uint8_t)(c->h[i] >> 24);
        out[i*4+1] = (uint8_t)(c->h[i] >> 16);
        out[i*4+2] = (uint8_t)(c->h[i] >> 8);
        out[i*4+3] = (uint8_t)(c->h[i]);
    }
}

/* ============================================================================
 *  THE LEDGER
 * ============================================================================ */

static uint8_t g_ceil_bitmap[III_CEIL_BYTES];
static bool    g_ceil_init   = false;
static bool    g_ceil_sealed = false;

void iii_ceil_init_denied(void)
{
    memset(g_ceil_bitmap, 0, sizeof g_ceil_bitmap);
    g_ceil_init = true;
    g_ceil_sealed = false;
}

int iii_ceil_admit_kind(uint16_t cycle_kind)
{
    if (g_ceil_sealed) return III_CEIL_E_SEALED;
    /* Lazy init: an admit before init_denied still works as
     * "admit one bit on a zeroed bitmap"; we simply ensure init flag
     * is true so canonical_bytes / mhash see a defined state. */
    g_ceil_init = true;
    g_ceil_bitmap[cycle_kind / 8u] |= (uint8_t)(1u << (cycle_kind % 8u));
    return III_CEIL_OK;
}

int iii_ceil_deny_kind(uint16_t cycle_kind)
{
    if (g_ceil_sealed) return III_CEIL_E_SEALED;
    g_ceil_init = true;
    g_ceil_bitmap[cycle_kind / 8u] &= (uint8_t)~(1u << (cycle_kind % 8u));
    return III_CEIL_OK;
}

bool iii_ceil_admitted_kind(uint16_t cycle_kind)
{
    if (!g_ceil_init) return false;
    return ((g_ceil_bitmap[cycle_kind / 8u] >> (cycle_kind % 8u)) & 1u) != 0u;
}

int iii_ceil_seal(void)
{
    /* Idempotent: re-sealing is OK (the bitmap is unchanged in the
     * locked window).  The second seal carries no new information. */
    g_ceil_sealed = true;
    return III_CEIL_OK;
}

bool iii_ceil_is_sealed(void) { return g_ceil_sealed; }

void iii_ceil_canonical_bytes(uint8_t out[III_CEIL_BYTES])
{
    if (!out) return;
    if (!g_ceil_init) memset(g_ceil_bitmap, 0, sizeof g_ceil_bitmap);
    memcpy(out, g_ceil_bitmap, III_CEIL_BYTES);
}

void iii_ceil_bitmap_mhash(uint8_t out[32])
{
    if (!out) return;
    if (!g_ceil_init) memset(g_ceil_bitmap, 0, sizeof g_ceil_bitmap);
    cl_sha_t c;
    cl_sha_init(&c);
    cl_sha_update(&c, g_ceil_bitmap, sizeof g_ceil_bitmap);
    cl_sha_final(&c, out);
}

uint32_t iii_ceil_count_admitted(void)
{
    if (!g_ceil_init) return 0;
    uint32_t n = 0;
    for (size_t i = 0; i < III_CEIL_BYTES; i++) {
        uint8_t b = g_ceil_bitmap[i];
        /* Brian Kernighan popcount per byte (max 8 iters per byte). */
        while (b) { n += b & 1u; b >>= 1; }
    }
    return n;
}
