/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\cg_r0_accessors.c
 *
 * NIH C accessor surface for cg_r0.iii (Stage-0 Ring 0 codegen).
 *
 * Mirrors the cg_rm1_accessors.c idiom: tiny wrappers for the libc
 * primitives the .iii dialect cannot express directly, plus a hand-rolled
 * FIPS 180-4 SHA-256 streaming context with snapshot-final, plus three
 * read-only lookup tables (IRP_MJ_* names, kernel-API min IRQL, IRQL
 * symbolic names) that the .iii body indexes by name slice from the
 * source buffer.
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

/* ─── fwrite wrapper ─────────────────────────────────────────────── */
int32_t iii_cg_r0_fwrite_c(uint64_t out_handle, uint64_t addr, uint64_t n)
{
    FILE *fp = (FILE *)(uintptr_t)out_handle;
    const void *p = (const void *)(uintptr_t)addr;
    if (!fp || !p) return 1;
    if (n == 0u) return 0;
    if (fwrite(p, 1u, (size_t)n, fp) != (size_t)n) return 1;
    return 0;
}

/* ─── Hand-rolled SHA-256 (FIPS 180-4) — NIH crypto ───────────────
 *
 * Identical algorithm to cg_rm1_accessors.c, separate file-static
 * state so the two codegens can run independently in the same process.
 * snapshot_c() preserves streaming state via stack save/restore. */

static uint32_t s_r0_state[8];
static uint32_t s_r0_bits_hi;
static uint32_t s_r0_bits_lo;
static uint32_t s_r0_len;
static uint8_t  s_r0_buf[64];

static const uint32_t s_r0_k256[64] = {
    0x428a2f98u,0x71374491u,0xb5c0fbcfu,0xe9b5dba5u,0x3956c25bu,0x59f111f1u,0x923f82a4u,0xab1c5ed5u,
    0xd807aa98u,0x12835b01u,0x243185beu,0x550c7dc3u,0x72be5d74u,0x80deb1feu,0x9bdc06a7u,0xc19bf174u,
    0xe49b69c1u,0xefbe4786u,0x0fc19dc6u,0x240ca1ccu,0x2de92c6fu,0x4a7484aau,0x5cb0a9dcu,0x76f988dau,
    0x983e5152u,0xa831c66du,0xb00327c8u,0xbf597fc7u,0xc6e00bf3u,0xd5a79147u,0x06ca6351u,0x14292967u,
    0x27b70a85u,0x2e1b2138u,0x4d2c6dfcu,0x53380d13u,0x650a7354u,0x766a0abbu,0x81c2c92eu,0x92722c85u,
    0xa2bfe8a1u,0xa81a664bu,0xc24b8b70u,0xc76c51a3u,0xd192e819u,0xd6990624u,0xf40e3585u,0x106aa070u,
    0x19a4c116u,0x1e376c08u,0x2748774cu,0x34b0bcb5u,0x391c0cb3u,0x4ed8aa4au,0x5b9cca4fu,0x682e6ff3u,
    0x748f82eeu,0x78a5636fu,0x84c87814u,0x8cc70208u,0x90befffau,0xa4506cebu,0xbef9a3f7u,0xc67178f2u,
};

static uint32_t r0_rotr32(uint32_t x, uint32_t n) { return (x >> n) | (x << (32u - n)); }

static void r0_sha_compress(void)
{
    uint32_t w[64];
    for (int i = 0; i < 16; i++) {
        w[i] = ((uint32_t)s_r0_buf[i*4 + 0] << 24) |
               ((uint32_t)s_r0_buf[i*4 + 1] << 16) |
               ((uint32_t)s_r0_buf[i*4 + 2] <<  8) |
               ((uint32_t)s_r0_buf[i*4 + 3]      );
    }
    for (int i = 16; i < 64; i++) {
        uint32_t s0 = r0_rotr32(w[i-15], 7) ^ r0_rotr32(w[i-15], 18) ^ (w[i-15] >> 3);
        uint32_t s1 = r0_rotr32(w[i-2], 17) ^ r0_rotr32(w[i-2], 19) ^ (w[i-2] >> 10);
        w[i] = w[i-16] + s0 + w[i-7] + s1;
    }
    uint32_t a = s_r0_state[0], b = s_r0_state[1], c = s_r0_state[2], d = s_r0_state[3];
    uint32_t e = s_r0_state[4], f = s_r0_state[5], g = s_r0_state[6], h = s_r0_state[7];
    for (int i = 0; i < 64; i++) {
        uint32_t S1 = r0_rotr32(e, 6) ^ r0_rotr32(e, 11) ^ r0_rotr32(e, 25);
        uint32_t ch = (e & f) ^ ((~e) & g);
        uint32_t t1 = h + S1 + ch + s_r0_k256[i] + w[i];
        uint32_t S0 = r0_rotr32(a, 2) ^ r0_rotr32(a, 13) ^ r0_rotr32(a, 22);
        uint32_t mj = (a & b) ^ (a & c) ^ (b & c);
        uint32_t t2 = S0 + mj;
        h = g; g = f; f = e; e = d + t1; d = c; c = b; b = a; a = t1 + t2;
    }
    s_r0_state[0] += a; s_r0_state[1] += b; s_r0_state[2] += c; s_r0_state[3] += d;
    s_r0_state[4] += e; s_r0_state[5] += f; s_r0_state[6] += g; s_r0_state[7] += h;
}

void iii_cg_r0_sha_init_c(void)
{
    s_r0_state[0] = 0x6a09e667u; s_r0_state[1] = 0xbb67ae85u;
    s_r0_state[2] = 0x3c6ef372u; s_r0_state[3] = 0xa54ff53au;
    s_r0_state[4] = 0x510e527fu; s_r0_state[5] = 0x9b05688cu;
    s_r0_state[6] = 0x1f83d9abu; s_r0_state[7] = 0x5be0cd19u;
    s_r0_bits_hi = 0u; s_r0_bits_lo = 0u; s_r0_len = 0u;
}

void iii_cg_r0_sha_update_c(uint64_t addr, uint64_t n)
{
    const uint8_t *p = (const uint8_t *)(uintptr_t)addr;
    uint32_t add_lo = (uint32_t)(n & 0xffffffffu) << 3;
    uint32_t add_hi = (uint32_t)(n >> 29);
    uint32_t new_lo = s_r0_bits_lo + add_lo;
    uint32_t carry = (new_lo < s_r0_bits_lo) ? 1u : 0u;
    s_r0_bits_lo = new_lo;
    s_r0_bits_hi += add_hi + carry;
    while (n > 0u) {
        uint64_t take = (uint64_t)(64u - s_r0_len);
        if (take > n) take = n;
        memcpy(&s_r0_buf[s_r0_len], p, (size_t)take);
        s_r0_len += (uint32_t)take;
        p += take;
        n -= take;
        if (s_r0_len == 64u) { r0_sha_compress(); s_r0_len = 0u; }
    }
}

void iii_cg_r0_sha_snapshot_c(uint64_t out32)
{
    uint32_t save_state[8];
    uint32_t save_bits_hi = s_r0_bits_hi;
    uint32_t save_bits_lo = s_r0_bits_lo;
    uint32_t save_len     = s_r0_len;
    uint8_t  save_buf[64];
    memcpy(save_state, s_r0_state, sizeof(save_state));
    memcpy(save_buf,   s_r0_buf,   sizeof(save_buf));

    s_r0_buf[s_r0_len++] = 0x80u;
    if (s_r0_len > 56u) {
        while (s_r0_len < 64u) s_r0_buf[s_r0_len++] = 0u;
        r0_sha_compress();
        s_r0_len = 0u;
    }
    while (s_r0_len < 56u) s_r0_buf[s_r0_len++] = 0u;
    s_r0_buf[56] = (uint8_t)((s_r0_bits_hi >> 24) & 0xffu);
    s_r0_buf[57] = (uint8_t)((s_r0_bits_hi >> 16) & 0xffu);
    s_r0_buf[58] = (uint8_t)((s_r0_bits_hi >>  8) & 0xffu);
    s_r0_buf[59] = (uint8_t)( s_r0_bits_hi        & 0xffu);
    s_r0_buf[60] = (uint8_t)((s_r0_bits_lo >> 24) & 0xffu);
    s_r0_buf[61] = (uint8_t)((s_r0_bits_lo >> 16) & 0xffu);
    s_r0_buf[62] = (uint8_t)((s_r0_bits_lo >>  8) & 0xffu);
    s_r0_buf[63] = (uint8_t)( s_r0_bits_lo        & 0xffu);
    r0_sha_compress();
    uint8_t *out = (uint8_t *)(uintptr_t)out32;
    for (int i = 0; i < 8; i++) {
        out[i*4 + 0] = (uint8_t)((s_r0_state[i] >> 24) & 0xffu);
        out[i*4 + 1] = (uint8_t)((s_r0_state[i] >> 16) & 0xffu);
        out[i*4 + 2] = (uint8_t)((s_r0_state[i] >>  8) & 0xffu);
        out[i*4 + 3] = (uint8_t)( s_r0_state[i]        & 0xffu);
    }

    memcpy(s_r0_state, save_state, sizeof(save_state));
    memcpy(s_r0_buf,   save_buf,   sizeof(save_buf));
    s_r0_bits_hi = save_bits_hi;
    s_r0_bits_lo = save_bits_lo;
    s_r0_len     = save_len;
}

/* ─── name-slice helpers (operate on source_buf+offset of length n) ── */

static int r0_str_eq(const uint8_t *a, uint64_t alen, const char *b)
{
    size_t bl = strlen(b);
    if ((size_t)alen != bl) return 0;
    return memcmp(a, b, bl) == 0;
}

/* ─── IRP_MJ_* table — WDK <wdm.h>, 28 entries ──────────────────── */
struct r0_irp_ent { const char *name; int mj; };
static const struct r0_irp_ent s_r0_irp[] = {
    { "IRP_MJ_CREATE",                    0x00 },
    { "IRP_MJ_CREATE_NAMED_PIPE",         0x01 },
    { "IRP_MJ_CLOSE",                     0x02 },
    { "IRP_MJ_READ",                      0x03 },
    { "IRP_MJ_WRITE",                     0x04 },
    { "IRP_MJ_QUERY_INFORMATION",         0x05 },
    { "IRP_MJ_SET_INFORMATION",           0x06 },
    { "IRP_MJ_QUERY_EA",                  0x07 },
    { "IRP_MJ_SET_EA",                    0x08 },
    { "IRP_MJ_FLUSH_BUFFERS",             0x09 },
    { "IRP_MJ_QUERY_VOLUME_INFORMATION",  0x0A },
    { "IRP_MJ_SET_VOLUME_INFORMATION",    0x0B },
    { "IRP_MJ_DIRECTORY_CONTROL",         0x0C },
    { "IRP_MJ_FILE_SYSTEM_CONTROL",       0x0D },
    { "IRP_MJ_DEVICE_CONTROL",            0x0E },
    { "IRP_MJ_INTERNAL_DEVICE_CONTROL",   0x0F },
    { "IRP_MJ_SHUTDOWN",                  0x10 },
    { "IRP_MJ_LOCK_CONTROL",              0x11 },
    { "IRP_MJ_CLEANUP",                   0x12 },
    { "IRP_MJ_CREATE_MAILSLOT",           0x13 },
    { "IRP_MJ_QUERY_SECURITY",            0x14 },
    { "IRP_MJ_SET_SECURITY",              0x15 },
    { "IRP_MJ_POWER",                     0x16 },
    { "IRP_MJ_SYSTEM_CONTROL",            0x17 },
    { "IRP_MJ_DEVICE_CHANGE",             0x18 },
    { "IRP_MJ_QUERY_QUOTA",               0x19 },
    { "IRP_MJ_SET_QUOTA",                 0x1A },
    { "IRP_MJ_PNP",                       0x1B },
};

int32_t iii_cg_r0_irp_mj_lookup_c(uint64_t addr, uint64_t len)
{
    const uint8_t *p = (const uint8_t *)(uintptr_t)addr;
    if (!p) return -1;
    for (size_t i = 0; i < sizeof(s_r0_irp)/sizeof(s_r0_irp[0]); i++) {
        if (r0_str_eq(p, len, s_r0_irp[i].name)) return s_r0_irp[i].mj;
    }
    return -1;
}

/* ─── kernel API → IRQL_REQUIRES_MAX (24 entries, WDK-derived) ──── */
struct r0_api_irql { const char *name; int irql; };
static const struct r0_api_irql s_r0_api[] = {
    { "ExAllocatePool2",            1 },  /* APC_LEVEL */
    { "ExFreePool",                 1 },
    { "ExAcquireFastMutex",         1 },
    { "ExReleaseFastMutex",         1 },
    { "KeAcquireSpinLock",          2 },  /* DISPATCH_LEVEL */
    { "KeReleaseSpinLock",          2 },
    { "KeWaitForSingleObject",      0 },  /* PASSIVE_LEVEL */
    { "ZwClose",                    0 },
    { "ZwOpenFile",                 0 },
    { "ZwReadFile",                 0 },
    { "ZwWriteFile",                0 },
    { "IoCreateDevice",             0 },
    { "IoDeleteDevice",             0 },
    { "IoCreateSymbolicLink",       0 },
    { "IoDeleteSymbolicLink",       0 },
    { "IoCompleteRequest",          2 },
    { "IoCallDriver",               2 },
    { "MmMapIoSpace",               1 },
    { "MmUnmapIoSpace",             1 },
    { "RtlCopyMemory",              31 }, /* HIGH_LEVEL — any */
    { "RtlZeroMemory",              31 },
    { "DbgPrint",                   31 },
    { "KeBugCheckEx",               31 },
    { "KeQuerySystemTime",          31 },
};

int32_t iii_cg_r0_api_min_irql_c(uint64_t addr, uint64_t len)
{
    const uint8_t *p = (const uint8_t *)(uintptr_t)addr;
    if (!p) return -1;
    for (size_t i = 0; i < sizeof(s_r0_api)/sizeof(s_r0_api[0]); i++) {
        if (r0_str_eq(p, len, s_r0_api[i].name)) return s_r0_api[i].irql;
    }
    return -1;
}

/* ─── IRQL symbolic name → numeric ────────────────────────────────── */
int32_t iii_cg_r0_irql_sym_c(uint64_t addr, uint64_t len)
{
    const uint8_t *p = (const uint8_t *)(uintptr_t)addr;
    if (!p) return -1;
    if (r0_str_eq(p, len, "PASSIVE_LEVEL"))  return 0;
    if (r0_str_eq(p, len, "APC_LEVEL"))      return 1;
    if (r0_str_eq(p, len, "DISPATCH_LEVEL")) return 2;
    if (r0_str_eq(p, len, "HIGH_LEVEL"))     return 31;
    return -1;
}
