/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\emit_accessors.c
 *
 * NIH C accessor surface for emit.iii.
 *
 * iiis-0 has no built-in bindings for libc subprocess / file I/O / env
 * primitives, so the .iii port reaches them via a small set of stable
 * C wrappers exposed here.  Stable C ABI; .iii callers declare them
 * with `extern @abi(c-msvc-x64) fn iii_emit_X_c(...)`.
 *
 * Strict NIH per ADR-021: libc only.  No third-party deps.
 *
 * IMPORTANT — Windows LLP64 invariant: emit.iii declares every address
 * and length parameter as `u64` (64-bit).  On the MSYS toolchain
 * (LLP64), `long` / `unsigned long` are 32-bit, so using them here
 * would silently truncate the high half of every pointer the .iii
 * caller passes through registers (rcx/rdx/r8/r9).  Every parameter
 * that maps to a .iii `u64` is therefore declared `uint64_t` here, and
 * every .iii `i64` maps to `int64_t`.  Native libc primitives that
 * really need `size_t` are cast at the boundary.
 *
 * Determinism semantics mirror emit.c (D1..D6 forced env, etc.) — see
 * emit.h for the citation table.
 */

#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* ─── putenv ───────────────────────────────────────────────────────── */

/* The string passed to putenv must remain valid for the lifetime of
 * the env binding.  Callers (emit.iii) hold the storage in module-
 * scope `var` arrays whose addresses never move. */
int32_t iii_emit_putenv_c(uint64_t kv)
{
    if (!kv) return -1;
    return (int32_t)putenv((char *)(uintptr_t)kv);
}

/* ─── system ───────────────────────────────────────────────────────── */

int32_t iii_emit_system_c(uint64_t cmd)
{
    if (!cmd) return -1;
    return (int32_t)system((const char *)(uintptr_t)cmd);
}

/* ─── popen / fgets / pclose: capture first line ───────────────────── */

int64_t iii_emit_popen_first_line_c(uint64_t cmd, uint64_t out, uint64_t cap)
{
    const char *cmd_p = (const char *)(uintptr_t)cmd;
    char       *out_p = (char *)(uintptr_t)out;
    if (!cmd_p || !out_p || cap < 2u) return -1;
    FILE *p = popen(cmd_p, "r");
    if (!p) return -1;
    if (!fgets(out_p, (int)cap, p)) {
        pclose(p);
        out_p[0] = 0;
        return -2;
    }
    char drain[512];
    while (fgets(drain, sizeof drain, p)) { /* discard */ }
    pclose(p);
    return (int64_t)strlen(out_p);
}

/* ─── popen + substring scan ───────────────────────────────────────── */

int32_t iii_emit_popen_grep_c(uint64_t cmd, uint64_t needle)
{
    const char *cmd_p    = (const char *)(uintptr_t)cmd;
    const char *needle_p = (const char *)(uintptr_t)needle;
    if (!cmd_p || !needle_p) return -1;
    FILE *p = popen(cmd_p, "r");
    if (!p) return -1;
    char line[512];
    int  found = 0;
    while (fgets(line, sizeof line, p)) {
        if (!found && strstr(line, needle_p)) found = 1;
    }
    pclose(p);
    return (int32_t)found;
}

/* ─── file I/O ─────────────────────────────────────────────────────── */

int32_t iii_emit_write_file_c(uint64_t path, uint64_t data, uint64_t len)
{
    const char          *path_p = (const char *)(uintptr_t)path;
    const unsigned char *data_p = (const unsigned char *)(uintptr_t)data;
    if (!path_p || (!data_p && len)) return 1;
    FILE *f = fopen(path_p, "wb");
    if (!f) return 2;
    size_t w = fwrite(data_p, 1, (size_t)len, f);
    if (fclose(f) != 0) return 3;
    return (w == (size_t)len) ? 0 : 4;
}

/* Slurp entire file into a freshly-malloc'd buffer.  On success, stores
 * the buffer pointer (as u64) and length at the caller-provided
 * out-pointer addresses, returns 0.  Caller frees via iii_emit_free_c.
 * Nonzero on any failure. */
int32_t iii_emit_read_file_c(uint64_t path, uint64_t out_buf_addr, uint64_t out_len)
{
    const char *path_p     = (const char *)(uintptr_t)path;
    uint64_t   *out_addr_p = (uint64_t *)(uintptr_t)out_buf_addr;
    uint64_t   *out_len_p  = (uint64_t *)(uintptr_t)out_len;
    if (!path_p || !out_addr_p || !out_len_p) return 1;
    *out_addr_p = 0; *out_len_p = 0;
    FILE *f = fopen(path_p, "rb");
    if (!f) return 2;
    if (fseek(f, 0, SEEK_END) != 0) { fclose(f); return 3; }
    long sz = ftell(f);
    if (sz < 0) { fclose(f); return 4; }
    if (fseek(f, 0, SEEK_SET) != 0) { fclose(f); return 5; }
    unsigned char *buf = (unsigned char *)malloc((size_t)sz + 1u);
    if (!buf) { fclose(f); return 6; }
    size_t r = fread(buf, 1, (size_t)sz, f);
    fclose(f);
    if (r != (size_t)sz) { free(buf); return 7; }
    buf[sz] = 0;
    *out_addr_p = (uint64_t)(uintptr_t)buf;
    *out_len_p  = (uint64_t)sz;
    return 0;
}

uint32_t iii_emit_free_c(uint64_t addr)
{
    if (addr) free((void *)(uintptr_t)addr);
    return 0u;
}

/* ─── byte-level helpers (since iiis-0 lacks ptr deref of malloc'd memory) ── */

uint32_t iii_emit_buf_read_u8_c(uint64_t addr, uint64_t off)
{
    return (uint32_t)((const unsigned char *)(uintptr_t)addr)[off];
}

/* ─── snprintf-equivalent helpers ──────────────────────────────────── */

int64_t iii_emit_appstr_c(uint64_t dst, uint64_t off, uint64_t cap, uint64_t src)
{
    char       *dst_p = (char *)(uintptr_t)dst;
    const char *src_p = (const char *)(uintptr_t)src;
    if (!dst_p || !src_p) return -1;
    size_t n = strlen(src_p);
    if (off + (uint64_t)n + 1u > cap) return -1;
    memcpy(dst_p + off, src_p, n);
    dst_p[off + n] = 0;
    return (int64_t)(off + (uint64_t)n);
}

int64_t iii_emit_appch_c(uint64_t dst, uint64_t off, uint64_t cap, uint32_t ch)
{
    char *dst_p = (char *)(uintptr_t)dst;
    if (!dst_p) return -1;
    if (off + 2u > cap) return -1;
    dst_p[off]      = (char)(ch & 0xffu);
    dst_p[off + 1u] = 0;
    return (int64_t)(off + 1u);
}

int64_t iii_emit_apphex_c(uint64_t dst, uint64_t off, uint64_t cap, uint64_t v)
{
    static const char H[] = "0123456789abcdef";
    char *dst_p = (char *)(uintptr_t)dst;
    if (!dst_p) return -1;
    char tmp[17]; int n = 0;
    if (v == 0) { tmp[n++] = '0'; }
    else { while (v) { tmp[n++] = H[v & 0xfu]; v >>= 4; } }
    if (off + (uint64_t)n + 1u > cap) return -1;
    for (int i = 0; i < n; i++) dst_p[off + (uint64_t)i] = tmp[n - 1 - i];
    dst_p[off + (uint64_t)n] = 0;
    return (int64_t)(off + (uint64_t)n);
}

int32_t iii_emit_memcmp_c(uint64_t a, uint64_t b, uint64_t n)
{
    return (int32_t)memcmp((const void *)(uintptr_t)a,
                           (const void *)(uintptr_t)b,
                           (size_t)n);
}

uint32_t iii_emit_memcpy_c(uint64_t dst, uint64_t src, uint64_t n)
{
    memcpy((void *)(uintptr_t)dst, (const void *)(uintptr_t)src, (size_t)n);
    return 0u;
}

uint64_t iii_emit_strlen_c(uint64_t s)
{
    if (!s) return 0u;
    return (uint64_t)strlen((const char *)(uintptr_t)s);
}

int32_t iii_emit_strcmp_c(uint64_t a, uint64_t b)
{
    return (int32_t)strcmp((const char *)(uintptr_t)a,
                           (const char *)(uintptr_t)b);
}

uint32_t iii_emit_write_u8_c(uint64_t addr, uint32_t val)
{
    *(unsigned char *)(uintptr_t)addr = (unsigned char)(val & 0xffu);
    return 0u;
}

uint32_t iii_emit_write_u32_be_c(uint64_t addr, uint32_t val)
{
    unsigned char *p = (unsigned char *)(uintptr_t)addr;
    p[0] = (unsigned char)((val >> 24) & 0xffu);
    p[1] = (unsigned char)((val >> 16) & 0xffu);
    p[2] = (unsigned char)((val >>  8) & 0xffu);
    p[3] = (unsigned char)( val        & 0xffu);
    return 0u;
}

/* Pack 8 bytes (LE) into u64 — used to reassemble pointer-sized scalars
 * from the iii_emit_buf_read_u8_c byte stream where iiis-0 cannot do
 * multi-line OR-shift expressions. */
uint64_t iii_emit_pack8_c(uint32_t b0, uint32_t b1,
                          uint32_t b2, uint32_t b3,
                          uint32_t b4, uint32_t b5,
                          uint32_t b6, uint32_t b7)
{
    return ((uint64_t)(b0 & 0xffu))       |
           ((uint64_t)(b1 & 0xffu) <<  8) |
           ((uint64_t)(b2 & 0xffu) << 16) |
           ((uint64_t)(b3 & 0xffu) << 24) |
           ((uint64_t)(b4 & 0xffu) << 32) |
           ((uint64_t)(b5 & 0xffu) << 40) |
           ((uint64_t)(b6 & 0xffu) << 48) |
           ((uint64_t)(b7 & 0xffu) << 56);
}

uint32_t iii_emit_hexchar_c(uint32_t nibble)
{
    static const char H[] = "0123456789abcdef";
    return (uint32_t)(unsigned char)H[nibble & 0xfu];
}
