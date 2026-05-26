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

