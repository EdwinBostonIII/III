/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\cg_rm1_accessors.c
 *
 * NIH C accessor surface for cg_rm1.iii.
 *
 * cg_rm1 is the Ring -1 (bare-metal hypervisor) codegen.  The .iii port
 * expresses its state and SHA-256 witness inline (per the cg_rm2.iii
 * idiom), and reaches FILE* / strlen via the small set of wrappers
 * exposed here.
 *
 * Strict NIH per ADR-021: libc only.  No third-party deps.
 *
 * Windows LLP64 invariant — every parameter that maps to a .iii `u64`
 * is declared `uint64_t`, never `unsigned long`.
 */

#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>

/* ─── fwrite wrapper (drives D9 SHA-256 inside the .iii) ──────────── */
int32_t iii_cg_rm1_fwrite_c(uint64_t out_handle, uint64_t addr, uint64_t n)
{
    FILE *fp = (FILE *)(uintptr_t)out_handle;
    const void *p = (const void *)(uintptr_t)addr;
    if (!fp || !p) return 1;
    if (n == 0u) return 0;
    if (fwrite(p, 1u, (size_t)n, fp) != (size_t)n) return 1;
    return 0;
}

/* ─── strlen wrapper ─────────────────────────────────────────────── */
uint64_t iii_cg_rm1_strlen_c(uint64_t s)
{
    if (!s) return 0u;
    return (uint64_t)strlen((const char *)(uintptr_t)s);
}

/* ─── Hand-rolled SHA-256 (FIPS 180-4) — NIH, libc-free crypto ─────
 *
 * Single global streaming context.  cg_rm1.iii streams the entire
 * emitted asm into this context and snapshots the digest at trailer
 * time.  Identical algorithm to cg_rm1.c's inline SHA-256, kept here
 * so the .iii port reaches a known-correct primitive while we close
 * the bootstrap gates.  No third-party dependencies. */
static uint32_t s_rm1_state[8];
static uint32_t s_rm1_bits_hi;
static uint32_t s_rm1_bits_lo;
static uint32_t s_rm1_len;
static uint8_t  s_rm1_buf[64];

static const uint32_t s_rm1_k256[64] = {
    0x428a2f98u,0x71374491u,0xb5c0fbcfu,0xe9b5dba5u,0x3956c25bu,0x59f111f1u,0x923f82a4u,0xab1c5ed5u,
    0xd807aa98u,0x12835b01u,0x243185beu,0x550c7dc3u,0x72be5d74u,0x80deb1feu,0x9bdc06a7u,0xc19bf174u,
    0xe49b69c1u,0xefbe4786u,0x0fc19dc6u,0x240ca1ccu,0x2de92c6fu,0x4a7484aau,0x5cb0a9dcu,0x76f988dau,
    0x983e5152u,0xa831c66du,0xb00327c8u,0xbf597fc7u,0xc6e00bf3u,0xd5a79147u,0x06ca6351u,0x14292967u,
    0x27b70a85u,0x2e1b2138u,0x4d2c6dfcu,0x53380d13u,0x650a7354u,0x766a0abbu,0x81c2c92eu,0x92722c85u,
    0xa2bfe8a1u,0xa81a664bu,0xc24b8b70u,0xc76c51a3u,0xd192e819u,0xd6990624u,0xf40e3585u,0x106aa070u,
    0x19a4c116u,0x1e376c08u,0x2748774cu,0x34b0bcb5u,0x391c0cb3u,0x4ed8aa4au,0x5b9cca4fu,0x682e6ff3u,
    0x748f82eeu,0x78a5636fu,0x84c87814u,0x8cc70208u,0x90befffau,0xa4506cebu,0xbef9a3f7u,0xc67178f2u,
};

static uint32_t rm1_rotr32(uint32_t x, uint32_t n) { return (x >> n) | (x << (32u - n)); }

static void rm1_sha_compress(void)
{
    uint32_t w[64];
    for (int i = 0; i < 16; i++) {
        w[i] = ((uint32_t)s_rm1_buf[i*4 + 0] << 24) |
               ((uint32_t)s_rm1_buf[i*4 + 1] << 16) |
               ((uint32_t)s_rm1_buf[i*4 + 2] <<  8) |
               ((uint32_t)s_rm1_buf[i*4 + 3]      );
    }
    for (int i = 16; i < 64; i++) {
        uint32_t s0 = rm1_rotr32(w[i-15], 7) ^ rm1_rotr32(w[i-15], 18) ^ (w[i-15] >> 3);
        uint32_t s1 = rm1_rotr32(w[i-2], 17) ^ rm1_rotr32(w[i-2], 19) ^ (w[i-2] >> 10);
        w[i] = w[i-16] + s0 + w[i-7] + s1;
    }
    uint32_t a = s_rm1_state[0], b = s_rm1_state[1], c = s_rm1_state[2], d = s_rm1_state[3];
    uint32_t e = s_rm1_state[4], f = s_rm1_state[5], g = s_rm1_state[6], h = s_rm1_state[7];
    for (int i = 0; i < 64; i++) {
        uint32_t S1 = rm1_rotr32(e, 6) ^ rm1_rotr32(e, 11) ^ rm1_rotr32(e, 25);
        uint32_t ch = (e & f) ^ ((~e) & g);
        uint32_t t1 = h + S1 + ch + s_rm1_k256[i] + w[i];
        uint32_t S0 = rm1_rotr32(a, 2) ^ rm1_rotr32(a, 13) ^ rm1_rotr32(a, 22);
        uint32_t mj = (a & b) ^ (a & c) ^ (b & c);
        uint32_t t2 = S0 + mj;
        h = g; g = f; f = e; e = d + t1; d = c; c = b; b = a; a = t1 + t2;
    }
    s_rm1_state[0] += a; s_rm1_state[1] += b; s_rm1_state[2] += c; s_rm1_state[3] += d;
    s_rm1_state[4] += e; s_rm1_state[5] += f; s_rm1_state[6] += g; s_rm1_state[7] += h;
}

void iii_cg_rm1_sha_init_c(void)
{
    s_rm1_state[0] = 0x6a09e667u; s_rm1_state[1] = 0xbb67ae85u;
    s_rm1_state[2] = 0x3c6ef372u; s_rm1_state[3] = 0xa54ff53au;
    s_rm1_state[4] = 0x510e527fu; s_rm1_state[5] = 0x9b05688cu;
    s_rm1_state[6] = 0x1f83d9abu; s_rm1_state[7] = 0x5be0cd19u;
    s_rm1_bits_hi = 0u; s_rm1_bits_lo = 0u; s_rm1_len = 0u;
}

void iii_cg_rm1_sha_update_c(uint64_t addr, uint64_t n)
{
    const uint8_t *p = (const uint8_t *)(uintptr_t)addr;
    uint32_t add_lo = (uint32_t)(n & 0xffffffffu) << 3;
    uint32_t add_hi = (uint32_t)(n >> 29);
    uint32_t new_lo = s_rm1_bits_lo + add_lo;
    uint32_t carry = (new_lo < s_rm1_bits_lo) ? 1u : 0u;
    s_rm1_bits_lo = new_lo;
    s_rm1_bits_hi += add_hi + carry;
    while (n > 0u) {
        uint64_t take = (uint64_t)(64u - s_rm1_len);
        if (take > n) take = n;
        memcpy(&s_rm1_buf[s_rm1_len], p, (size_t)take);
        s_rm1_len += (uint32_t)take;
        p += take;
        n -= take;
        if (s_rm1_len == 64u) { rm1_sha_compress(); s_rm1_len = 0u; }
    }
}

/* Snapshot-final: leaves streaming state untouched so caller can keep updating. */
void iii_cg_rm1_sha_snapshot_c(uint64_t out32)
{
    uint32_t save_state[8];
    uint32_t save_bits_hi = s_rm1_bits_hi;
    uint32_t save_bits_lo = s_rm1_bits_lo;
    uint32_t save_len     = s_rm1_len;
    uint8_t  save_buf[64];
    memcpy(save_state, s_rm1_state, sizeof(save_state));
    memcpy(save_buf,   s_rm1_buf,   sizeof(save_buf));

    s_rm1_buf[s_rm1_len++] = 0x80u;
    if (s_rm1_len > 56u) {
        while (s_rm1_len < 64u) s_rm1_buf[s_rm1_len++] = 0u;
        rm1_sha_compress();
        s_rm1_len = 0u;
    }
    while (s_rm1_len < 56u) s_rm1_buf[s_rm1_len++] = 0u;
    s_rm1_buf[56] = (uint8_t)((s_rm1_bits_hi >> 24) & 0xffu);
    s_rm1_buf[57] = (uint8_t)((s_rm1_bits_hi >> 16) & 0xffu);
    s_rm1_buf[58] = (uint8_t)((s_rm1_bits_hi >>  8) & 0xffu);
    s_rm1_buf[59] = (uint8_t)( s_rm1_bits_hi        & 0xffu);
    s_rm1_buf[60] = (uint8_t)((s_rm1_bits_lo >> 24) & 0xffu);
    s_rm1_buf[61] = (uint8_t)((s_rm1_bits_lo >> 16) & 0xffu);
    s_rm1_buf[62] = (uint8_t)((s_rm1_bits_lo >>  8) & 0xffu);
    s_rm1_buf[63] = (uint8_t)( s_rm1_bits_lo        & 0xffu);
    rm1_sha_compress();
    uint8_t *out = (uint8_t *)(uintptr_t)out32;
    for (int i = 0; i < 8; i++) {
        out[i*4 + 0] = (uint8_t)((s_rm1_state[i] >> 24) & 0xffu);
        out[i*4 + 1] = (uint8_t)((s_rm1_state[i] >> 16) & 0xffu);
        out[i*4 + 2] = (uint8_t)((s_rm1_state[i] >>  8) & 0xffu);
        out[i*4 + 3] = (uint8_t)( s_rm1_state[i]        & 0xffu);
    }

    memcpy(s_rm1_state, save_state, sizeof(save_state));
    memcpy(s_rm1_buf,   save_buf,   sizeof(save_buf));
    s_rm1_bits_hi = save_bits_hi;
    s_rm1_bits_lo = save_bits_lo;
    s_rm1_len     = save_len;
}
