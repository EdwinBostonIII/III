/* COMPILER/BOOT/xii_lattice_loader.h -- xii_lattice.bin -> struct xii_lattice_cell[]
 *
 * Bridges the on-disk Lattice produced by gen_xii_lattice.c to the in-memory
 * struct array consumed by xii_ldil_inline_all. Per S12 + S26.10.
 *
 * NIH: libc only.
 */

#ifndef XII_LATTICE_LOADER_H
#define XII_LATTICE_LOADER_H

#include "xii_ldil.h"
#include <stdint.h>
#include <stddef.h>

/* Error codes. */
#define XII_LL_OK              0
#define XII_LL_E_OPEN          1
#define XII_LL_E_HEADER        2
#define XII_LL_E_TRUNCATED     3
#define XII_LL_E_OOM           4
#define XII_LL_E_MHASH_VERIFY  5

/* Load a Lattice file into a freshly-allocated cell array + payload arena.
 *
 *   path           : path to xii_lattice.bin
 *   out_cells      : on success, *out_cells = malloc'd cell array;
 *                    caller must free with xii_lattice_loader_free()
 *   out_count      : *out_count = number of cells loaded
 *   out_arena      : *out_arena = malloc'd payload arena (cells' .payload
 *                    pointers reference into this); caller frees via
 *                    xii_lattice_loader_free()
 *
 * Returns 0 on success, XII_LL_E_* on error. On error, *out_cells and
 * *out_arena are set to NULL.
 *
 * If `verify_mhash` is non-zero, each cell's payload is re-SHA-256'd and
 * compared against the cell_mhash stored in the record. Mismatch returns
 * XII_LL_E_MHASH_VERIFY. */
int xii_lattice_load(const char *path,
                     struct xii_lattice_cell **out_cells,
                     size_t *out_count,
                     uint8_t **out_arena,
                     int verify_mhash);

/* Free what xii_lattice_load allocated. */
void xii_lattice_loader_free(struct xii_lattice_cell *cells, uint8_t *arena);

/* ------------------------------------------------------------------ */
/* Runtime store integration.                                          */
/*                                                                      */
/* Loads xii_lattice.bin AND populates the omnia/xii_lattice.iii in-   */
/* memory store (xii_lattice_alloc_cell + xii_lattice_lookup_set) so   */
/* runtime callers of xii_lattice_lookup get real cell references.    */
/*                                                                      */
/* Returns the number of cells installed on success, or a negative     */
/* XII_LL_E_* code on failure.  Path-resolution semantics:             */
/*   - If `explicit_path` is non-NULL, use it verbatim.                */
/*   - Else if env var XII_LATTICE_PATH is set, use that.              */
/*   - Else look in $REPO/COMPILED/xii_lattice.bin where $REPO is      */
/*     derived from argv0_dir + "/.." (two levels up from a           */
/*     COMPILED/iiis-2.exe layout).                                    */
/*                                                                      */
/* A missing file is NOT a failure: the loader returns 0 (no cells)    */
/* and the runtime continues with an empty lattice (LDIL lookups       */
/* return "no cell").  Other failures (truncated file, mhash           */
/* mismatch) return their XII_LL_E_* code.                             */
/* ------------------------------------------------------------------ */

int xii_lattice_load_into_store(const char *explicit_path, const char *argv0);

#endif /* XII_LATTICE_LOADER_H */
