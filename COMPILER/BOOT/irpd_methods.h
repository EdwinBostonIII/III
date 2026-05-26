/* ============================================================================
 * irpd_methods.h — Single source of truth for the IRPD privileged-operation
 *                  method surface (per III-EFFECTS.md §1.1).
 *
 * RITCHIE Convergence Stage 1.20: this header deduplicates two formerly-parallel
 * tables that could drift:
 *   - sid.c's  SID_METHOD_TABLE   (17 write-side {name, se_kind} entries)
 *   - sema.c's SEMA_IRPD_METHODS  (20 names = 17 write-side + 3 read-side)
 *
 * The canonical table `III_IRPD_METHODS` is DEFINED once (in sid.c, external
 * linkage) and consumed by both sid.c (name -> se_kind) and sema.c (name
 * membership validation).  The `is_write_side` flag distinguishes the 17
 * privileged-write methods (each carrying a real iii_sid_se_kind_t) from the 3
 * read-side methods (msr_read / cr_read / npt_read — accepted names with
 * kind == III_BOOT_SE_NONE, exactly as the old sid.c table returned for them).
 *
 * Strict NIH (ADR-021): only stdlib + III BOOT headers.
 * ============================================================================ */
#ifndef III_IRPD_METHODS_H
#define III_IRPD_METHODS_H

#include <stdbool.h>
#include <stddef.h>
#include "sid.h"   /* iii_sid_se_kind_t + III_BOOT_SE_* */

typedef struct {
    const char       *name;
    iii_sid_se_kind_t kind;          /* III_BOOT_SE_NONE for read-side rows */
    bool              is_write_side;  /* true for the 17 privileged-write methods */
} iii_irpd_method_t;

/* Defined in sid.c (one definition; external linkage). */
extern const iii_irpd_method_t III_IRPD_METHODS[];
extern const size_t            III_IRPD_METHODS_COUNT;

/* The 17 write-side methods are exactly III_BOOT_SE_MSR_WRITE..NMI_INSTALL
 * (enum values 1..17 == III_BOOT_SE__COUNT - 1). */
#define III_IRPD_WRITE_SIDE_COUNT  ((size_t)(III_BOOT_SE__COUNT - 1))

#endif /* III_IRPD_METHODS_H */
