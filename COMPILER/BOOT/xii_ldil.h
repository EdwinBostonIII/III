/* COMPILER/BOOT/xii_ldil.h — Link-Time Lattice Inliner header.
 *
 * Per DOCS/III-XII.md S16.2 + S26.12.
 *
 * Sealed linker pass: walks the binary's .iii_xii_calls section, looks up
 * each (horizon_id, circ_encoding) against xii_lattice.bin, and inlines
 * the cell's byte payload directly at the call site.
 *
 * NIH: libc + Win32 only. No third-party deps.
 */

#ifndef XII_LDIL_H
#define XII_LDIL_H

#include <stdint.h>

/* Call-site descriptor in .iii_xii_calls (24 bytes per S26.12.1). */
struct iii_xii_call_site {
    uint64_t call_site_offset;
    uint8_t  horizon_id;
    uint8_t  static_circ_flag;
    uint16_t reserved_0;
    uint32_t circ_encoding;
    uint16_t expected_size;
    uint8_t  ct_kind;
    uint8_t  prov_xform_id;
    uint32_t deployment_target;
};

/* LDIL audit record in .iii_xii_ldil_audit (64 bytes per S26.12.2). */
struct iii_xii_ldil_audit_record {
    uint64_t text_offset;
    uint8_t  horizon_id;
    uint8_t  ct_kind;
    uint8_t  prov_xform_id;
    uint8_t  reserved_0;
    uint32_t circ_encoding;
    uint32_t payload_size;
    uint32_t nop_pad_size;
    uint8_t  expected_cell_mhash[32];
};

/* Lattice cell as accessed by LDIL. The 48-byte on-disk record (cf.
 * gen_xii_lattice.c) carries [mhash | offset | size | ct_kind |
 * prov_xform_id | flags | target | 4 reserved]. The loader populates a
 * struct per record and stores `horizon_id` separately (derived from
 * the position the cell was emitted for; carried in the on-disk record's
 * flags+target tuple via the loader's bookkeeping). The inliner needs
 * both `horizon_id` and `target` to find the right cell for a given
 * call-site, since multiple targets may share a horizon. */
struct xii_lattice_cell {
    uint8_t  cell_mhash[32];
    uint32_t payload_offset;
    uint32_t payload_size;
    uint8_t  ct_kind;
    uint8_t  prov_xform_id;
    uint8_t  flags;
    uint8_t  target;              /* deployment_target (0..6) */
    uint16_t horizon_id;          /* 0..143 */
    uint16_t reserved_1;
    const uint8_t *payload;
};

/* Error codes (per DOCS/III-ERRORS.md §N.5). */
#define XII_LDIL_OK                    0
#define XII_LDIL_E_CELL_MHASH_MISMATCH 1
#define XII_LDIL_E_CELL_OVERSIZE       2
#define XII_LDIL_E_CALLS_CORRUPT       3
#define XII_LDIL_E_INTERNAL            4

/* Main entry point: walk all call sites, inline payloads, write audit log.
 * Returns count of inlined cells on success, or negative error code. */
int xii_ldil_inline_all(uint8_t *text_section, size_t text_size,
                        const uint8_t *calls_section, size_t calls_size,
                        const struct xii_lattice_cell *lattice, size_t lattice_count,
                        uint8_t *audit_section, size_t audit_capacity,
                        size_t *audit_used,
                        uint32_t deployment_target);

/* Inline a single call site. */
int xii_ldil_inline_one(uint8_t *text_section, size_t text_size,
                        const struct iii_xii_call_site *site,
                        const struct xii_lattice_cell *cell,
                        uint32_t deployment_target);

/* Verify the inlined bytes at offset match the cell's expected mhash. */
int xii_ldil_verify_one(const uint8_t *text_section, uint64_t offset,
                        const struct xii_lattice_cell *cell);

/* Fill NOP padding at given offset for given target.
 * Returns number of bytes filled. */
uint32_t xii_ldil_fill_nops(uint8_t *out, uint32_t count, uint32_t deployment_target);

#endif /* XII_LDIL_H */
