/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\cg_r3_accessors.c
 *
 * NIH C accessor surface for the .iii port of cg_r3 (Ring 3 user-mode
 * codegen, MS x64 ABI).  Mirrors the cg_r0_accessors.c / cg_rm1_accessors.c
 * idiom: streaming SHA-256 (D9 witness), fwrite trampoline, plus
 * R3-specific opcode-table validator (D6) and volatile-register
 * classifier (D3).
 *
 * Strict NIH per ADR-021: libc only.  No third-party deps.
 *
 * Windows LLP64 invariant — every parameter that maps to a .iii `u64`
 * is declared `uint64_t`, never `unsigned long`.
 *
 * Symbol inventory (stable contract for cg_r3.iii):
 *   iii_cg_r3_fwrite_c       (out_handle, addr, n) -> i32
 *   iii_cg_r3_sha_init_c     ()
 *   iii_cg_r3_sha_update_c   (addr, n)
 *   iii_cg_r3_sha_snapshot_c (out32)
 *   iii_cg_r3_op_known_c     (addr, len) -> i32   (1 = mnemonic in 35-entry table)
 *   iii_cg_r3_is_volatile_c  (addr, len) -> i32   (1 = register volatile under MS x64 ABI)
 */

#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>

/* ─── fwrite trampoline ────────────────────────────────────────────── */
int32_t iii_cg_r3_fwrite_c(uint64_t out_handle, uint64_t addr, uint64_t n)
{
    if (!out_handle || !addr || !n) return 0;
    FILE *f = (FILE *)(uintptr_t)out_handle;
    const void *buf = (const void *)(uintptr_t)addr;
    size_t w = fwrite(buf, 1, (size_t)n, f);
    return (w == (size_t)n) ? 0 : -1;
}

/* ─── streaming SHA-256 (RFC 6234, NIST FIPS 180-4) ────────────────── */
typedef struct {
    uint32_t state[8];
    uint64_t bitlen;
    uint8_t  buf[64];
    uint32_t buflen;
} r3_sha256_t;

static r3_sha256_t G_R3_SHA;

static const uint32_t R3_SHA_K[64] = {
    0x428a2f98u,0x71374491u,0xb5c0fbcfu,0xe9b5dba5u,0x3956c25bu,0x59f111f1u,0x923f82a4u,0xab1c5ed5u,
    0xd807aa98u,0x12835b01u,0x243185beu,0x550c7dc3u,0x72be5d74u,0x80deb1feu,0x9bdc06a7u,0xc19bf174u,
    0xe49b69c1u,0xefbe4786u,0x0fc19dc6u,0x240ca1ccu,0x2de92c6fu,0x4a7484aau,0x5cb0a9dcu,0x76f988dau,
    0x983e5152u,0xa831c66du,0xb00327c8u,0xbf597fc7u,0xc6e00bf3u,0xd5a79147u,0x06ca6351u,0x14292967u,
    0x27b70a85u,0x2e1b2138u,0x4d2c6dfcu,0x53380d13u,0x650a7354u,0x766a0abbu,0x81c2c92eu,0x92722c85u,
    0xa2bfe8a1u,0xa81a664bu,0xc24b8b70u,0xc76c51a3u,0xd192e819u,0xd6990624u,0xf40e3585u,0x106aa070u,
    0x19a4c116u,0x1e376c08u,0x2748774cu,0x34b0bcb5u,0x391c0cb3u,0x4ed8aa4au,0x5b9cca4fu,0x682e6ff3u,
    0x748f82eeu,0x78a5636fu,0x84c87814u,0x8cc70208u,0x90befffau,0xa4506cebu,0xbef9a3f7u,0xc67178f2u
};

static uint32_t r3_rotr(uint32_t x, unsigned n) { return (x >> n) | (x << (32u - n)); }

static void r3_sha_compress(r3_sha256_t *s, const uint8_t blk[64])
{
    uint32_t w[64];
    for (int i = 0; i < 16; i++) {
        w[i] = ((uint32_t)blk[i*4]<<24) | ((uint32_t)blk[i*4+1]<<16) |
               ((uint32_t)blk[i*4+2]<<8) | (uint32_t)blk[i*4+3];
    }
    for (int i = 16; i < 64; i++) {
        uint32_t s0 = r3_rotr(w[i-15],7) ^ r3_rotr(w[i-15],18) ^ (w[i-15]>>3);
        uint32_t s1 = r3_rotr(w[i-2],17) ^ r3_rotr(w[i-2],19)  ^ (w[i-2]>>10);
        w[i] = w[i-16] + s0 + w[i-7] + s1;
    }
    uint32_t a=s->state[0],b=s->state[1],c=s->state[2],d=s->state[3];
    uint32_t e=s->state[4],f=s->state[5],g=s->state[6],h=s->state[7];
    for (int i = 0; i < 64; i++) {
        uint32_t S1 = r3_rotr(e,6) ^ r3_rotr(e,11) ^ r3_rotr(e,25);
        uint32_t ch = (e & f) ^ ((~e) & g);
        uint32_t t1 = h + S1 + ch + R3_SHA_K[i] + w[i];
        uint32_t S0 = r3_rotr(a,2) ^ r3_rotr(a,13) ^ r3_rotr(a,22);
        uint32_t mj = (a & b) ^ (a & c) ^ (b & c);
        uint32_t t2 = S0 + mj;
        h=g; g=f; f=e; e=d+t1; d=c; c=b; b=a; a=t1+t2;
    }
    s->state[0]+=a; s->state[1]+=b; s->state[2]+=c; s->state[3]+=d;
    s->state[4]+=e; s->state[5]+=f; s->state[6]+=g; s->state[7]+=h;
}

void iii_cg_r3_sha_init_c(void)
{
    G_R3_SHA.state[0]=0x6a09e667u; G_R3_SHA.state[1]=0xbb67ae85u;
    G_R3_SHA.state[2]=0x3c6ef372u; G_R3_SHA.state[3]=0xa54ff53au;
    G_R3_SHA.state[4]=0x510e527fu; G_R3_SHA.state[5]=0x9b05688cu;
    G_R3_SHA.state[6]=0x1f83d9abu; G_R3_SHA.state[7]=0x5be0cd19u;
    G_R3_SHA.bitlen = 0; G_R3_SHA.buflen = 0;
}

void iii_cg_r3_sha_update_c(uint64_t addr, uint64_t n)
{
    if (!addr || !n) return;
    const uint8_t *p = (const uint8_t *)(uintptr_t)addr;
    size_t len = (size_t)n;
    G_R3_SHA.bitlen += (uint64_t)len * 8u;
    while (len > 0) {
        uint32_t take = 64u - G_R3_SHA.buflen;
        if (take > len) take = (uint32_t)len;
        memcpy(G_R3_SHA.buf + G_R3_SHA.buflen, p, take);
        G_R3_SHA.buflen += take; p += take; len -= take;
        if (G_R3_SHA.buflen == 64u) {
            r3_sha_compress(&G_R3_SHA, G_R3_SHA.buf);
            G_R3_SHA.buflen = 0;
        }
    }
}

void iii_cg_r3_sha_snapshot_c(uint64_t out32)
{
    if (!out32) return;
    /* Take a copy so further updates may continue against the live sponge. */
    r3_sha256_t s = G_R3_SHA;
    uint64_t bl_bits = s.bitlen;
    /* append 0x80 */
    s.buf[s.buflen++] = 0x80u;
    if (s.buflen > 56u) {
        while (s.buflen < 64u) s.buf[s.buflen++] = 0;
        r3_sha_compress(&s, s.buf);
        s.buflen = 0;
    }
    while (s.buflen < 56u) s.buf[s.buflen++] = 0;
    /* big-endian length */
    for (int i = 0; i < 8; i++) {
        s.buf[56 + i] = (uint8_t)(bl_bits >> (56 - 8*i));
    }
    r3_sha_compress(&s, s.buf);
    uint8_t *out = (uint8_t *)(uintptr_t)out32;
    for (int i = 0; i < 8; i++) {
        out[i*4]   = (uint8_t)(s.state[i] >> 24);
        out[i*4+1] = (uint8_t)(s.state[i] >> 16);
        out[i*4+2] = (uint8_t)(s.state[i] >> 8);
        out[i*4+3] = (uint8_t)(s.state[i]);
    }
}

/* ─── op_lookup: validate mnemonic against the 35-entry op table.
 * Mirrors the table in cg_r3.c lines 245–290.  Returns 1 if known. */
static const char * const R3_OP_TABLE[] = {
    "movq","movabsq","movzbq","movzwq","movl","leaq","pushq","popq",
    "addq","subq","imulq","idivq","andq","orq","xorq","notq","negq",
    "shlq","shrq","cqto","cmpq","testq",
    "sete","setne","setl","setle","setg","setge","seta","setb","setae","setbe",
    "jmp","je","jne","jz","jnz","jl","jge",
    "callq","retq",
    NULL
};

int32_t iii_cg_r3_op_known_c(uint64_t addr, uint64_t len)
{
    if (!addr || !len || len > 16) return 0;
    const char *m = (const char *)(uintptr_t)addr;
    for (int i = 0; R3_OP_TABLE[i]; i++) {
        size_t mlen = strlen(R3_OP_TABLE[i]);
        if (mlen != (size_t)len) continue;
        if (memcmp(R3_OP_TABLE[i], m, mlen) == 0) return 1;
    }
    return 0;
}

/* ─── is_volatile: MS x64 ABI volatile-register set (RAX, RCX, RDX,
 * R8-R11, plus 32/16/8-bit aliases, plus xmm0-5).  Mirrors cg_r3.c
 * lines 227–241. */
static const char * const R3_VOL_TABLE[] = {
    "rax","rcx","rdx","r8","r9","r10","r11",
    "eax","ecx","edx","r8d","r9d","r10d","r11d",
    "ax","cx","dx","r8w","r9w","r10w","r11w",
    "al","cl","dl","r8b","r9b","r10b","r11b",
    "xmm0","xmm1","xmm2","xmm3","xmm4","xmm5",
    NULL
};

int32_t iii_cg_r3_is_volatile_c(uint64_t addr, uint64_t len)
{
    if (!addr || !len || len > 8) return 0;
    const char *r = (const char *)(uintptr_t)addr;
    for (int i = 0; R3_VOL_TABLE[i]; i++) {
        size_t rlen = strlen(R3_VOL_TABLE[i]);
        if (rlen != (size_t)len) continue;
        if (memcmp(R3_VOL_TABLE[i], r, rlen) == 0) return 1;
    }
    return 0;
}
