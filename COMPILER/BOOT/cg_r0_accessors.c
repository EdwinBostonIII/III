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

