/* COMPILER/BOOT/xii_lattice.h — C-side bridge to omnia/xii_lattice.iii.
 *
 * Per DOCS/III-XII.md S12.
 *
 * NIH: libc only.
 */

#ifndef XII_LATTICE_H
#define XII_LATTICE_H

#include <stdint.h>

/* Reset the lattice store. */
extern int xii_lattice_reset(void);

/* Lattice capacity / usage. */
extern uint32_t xii_lattice_capacity(void);
extern uint32_t xii_lattice_used(void);

/* Allocate a cell with the given payload + metadata.
 * Returns cell_idx or 0xFFFFFFFF on overflow. */
extern uint32_t xii_lattice_alloc_cell(const uint8_t *payload_ptr,
                                       uint32_t payload_size,
                                       uint8_t ct_kind,
                                       uint8_t prov_xform_id,
                                       uint8_t flags,
                                       const uint8_t *mhash_ptr);

/* Cell accessors. */
extern uint64_t xii_lattice_cell_mhash_ptr(uint32_t cell_idx);
extern uint32_t xii_lattice_cell_payload_offset(uint32_t cell_idx);
extern uint32_t xii_lattice_cell_payload_size(uint32_t cell_idx);
extern uint64_t xii_lattice_cell_payload_ptr(uint32_t cell_idx);
extern uint8_t  xii_lattice_cell_ct_kind(uint32_t cell_idx);

/* Lookup table: (horizon_id, circ_slot) -> cell_idx. */
extern int      xii_lattice_lookup_set(uint8_t horizon_id, uint32_t circ_slot, uint32_t cell_idx);
extern uint32_t xii_lattice_lookup(uint8_t horizon_id, uint32_t circ_slot);
extern uint32_t xii_lattice_circ_to_slot(uint32_t circ);

#endif /* XII_LATTICE_H */
