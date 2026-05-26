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

