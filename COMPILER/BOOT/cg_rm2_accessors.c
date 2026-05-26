/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\cg_rm2_accessors.c
 *
 * NIH C accessor surface for cg_rm2.iii.
 *
 * cg_rm2 is the SANCTUM-sealed Ring -2 codegen.  The .iii port expresses
 * its state and SHA-256 witness inline (per the emit.iii idiom), and
 * reaches FILE* / strlen via the small set of wrappers exposed here.
 *
 * Strict NIH per ADR-021: libc only.  No third-party deps.
 *
 * Windows LLP64 invariant — every parameter that maps to a .iii `u64`
 * is declared `uint64_t`, never `unsigned long` (which is 32-bit on
 * MinGW).  i32 maps to int32_t / i64 to int64_t.
 */

#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>

/* ─── fwrite wrapper ─────────────────────────────────────────────────
 * Returns 0 on success, 1 on short write / error.  Mirrors the
 * cg_emit_bytes IO branch in cg_rm2.c. */
int32_t iii_cg_rm2_fwrite_c(uint64_t out_handle, uint64_t addr, uint64_t n)
{
    FILE *fp = (FILE *)(uintptr_t)out_handle;
    const void *p = (const void *)(uintptr_t)addr;
    if (!fp || !p) return 1;
    if (n == 0u) return 0;
    if (fwrite(p, 1u, (size_t)n, fp) != (size_t)n) return 1;
    return 0;
}

/* ─── strlen wrapper ─────────────────────────────────────────────────
 * Used by cg_emit_str-equivalent in the .iii body. */
uint64_t iii_cg_rm2_strlen_c(uint64_t s)
{
    if (!s) return 0u;
    return (uint64_t)strlen((const char *)(uintptr_t)s);
}
