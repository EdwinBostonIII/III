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

