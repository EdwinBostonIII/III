/* COMPILER/BOOT/xii_ldil.c — Link-Time Lattice Inliner.
 *
 * Per DOCS/III-XII.md S16.2 + S26.12.
 *
 * Walks the .iii_xii_calls section (24-byte descriptors), looks up each
 * (horizon_id, circ_encoding) against the sealed Lattice, and replaces
 * the placeholder NOPs at the call site with the cell's byte payload.
 *
 * NIH: libc only (string.h for memcpy/memcmp; stdlib.h for size_t).
 *      SHA-256 verification via numera/sha256.iii (linked at build time).
 */

#include "xii_ldil.h"
#include <string.h>
#include <stdio.h>

/* External SHA-256 oneshot from numera/sha256.iii. */
extern uint32_t sha256_oneshot(const uint8_t *input, uint64_t len, uint8_t *out_32);

/* ------------------------------------------------------------------ */
/* Per-target NOP fill (mirrors numera/xii_nop_tables.iii)            */
/* ------------------------------------------------------------------ */

static uint32_t fill_x86(uint8_t *out, uint32_t count)
{
    uint32_t remaining = count;
    uint32_t off = 0;
    while (remaining >= 8) {
        out[off + 0] = 0x0F; out[off + 1] = 0x1F;
        out[off + 2] = 0x84; out[off + 3] = 0x00;
        out[off + 4] = 0x00; out[off + 5] = 0x00;
        out[off + 6] = 0x00; out[off + 7] = 0x00;
        off += 8; remaining -= 8;
    }
    while (remaining >= 4) {
        out[off + 0] = 0x0F; out[off + 1] = 0x1F;
        out[off + 2] = 0x40; out[off + 3] = 0x00;
        off += 4; remaining -= 4;
    }
    while (remaining >= 2) {
        out[off + 0] = 0x66; out[off + 1] = 0x90;
        off += 2; remaining -= 2;
    }
    if (remaining == 1) {
        out[off] = 0x90;
        off += 1;
    }
    return off;
}

static uint32_t fill_x86_scalar(uint8_t *out, uint32_t count)
{
    for (uint32_t i = 0; i < count; ++i) out[i] = 0x90;
    return count;
}

static uint32_t fill_arm64(uint8_t *out, uint32_t count)
{
    uint32_t aligned = count & 0xFFFFFFFCu;
    for (uint32_t i = 0; i < aligned; i += 4) {
        out[i + 0] = 0x1F; out[i + 1] = 0x20;
        out[i + 2] = 0x03; out[i + 3] = 0xD5;
    }
    return aligned;
}

static uint32_t fill_riscv(uint8_t *out, uint32_t count)
{
    uint32_t aligned = count & 0xFFFFFFFCu;
    for (uint32_t i = 0; i < aligned; i += 4) {
        out[i + 0] = 0x13; out[i + 1] = 0x00;
        out[i + 2] = 0x00; out[i + 3] = 0x00;
    }
    return aligned;
}

static uint32_t fill_cortex_m(uint8_t *out, uint32_t count)
{
    uint32_t aligned = count & 0xFFFFFFFEu;
    for (uint32_t i = 0; i < aligned; i += 2) {
        out[i + 0] = 0x00; out[i + 1] = 0xBF;
    }
    return aligned;
}

uint32_t xii_ldil_fill_nops(uint8_t *out, uint32_t count, uint32_t deployment_target)
{
    switch (deployment_target) {
        case 0: case 1: return fill_x86(out, count);
        case 2:         return fill_x86_scalar(out, count);
        case 3: case 4: return fill_arm64(out, count);
        case 5:         return fill_riscv(out, count);
        case 6:         return fill_cortex_m(out, count);
        default:        return 0;
    }
}

/* ------------------------------------------------------------------ */
/* Verify: recompute SHA-256 over inlined bytes; compare to cell_mhash.*/
/* ------------------------------------------------------------------ */

int xii_ldil_verify_one(const uint8_t *text_section, uint64_t offset,
                        const struct xii_lattice_cell *cell)
{
    uint8_t computed[32];
    sha256_oneshot(text_section + offset, cell->payload_size, computed);
    if (memcmp(computed, cell->cell_mhash, 32) != 0) {
        return XII_LDIL_E_CELL_MHASH_MISMATCH;
    }
    return XII_LDIL_OK;
}

/* ------------------------------------------------------------------ */
/* Inline one call site                                                */
/* ------------------------------------------------------------------ */

int xii_ldil_inline_one(uint8_t *text_section, size_t text_size,
                        const struct iii_xii_call_site *site,
                        const struct xii_lattice_cell *cell,
                        uint32_t deployment_target)
{
    /* Bounds check. */
    if (site->call_site_offset + site->expected_size > text_size) {
        return XII_LDIL_E_INTERNAL;
    }

    /* Verify cell mhash against curated payload (defense against
     * Lattice tamper). */
    uint8_t computed[32];
    sha256_oneshot(cell->payload, cell->payload_size, computed);
    if (memcmp(computed, cell->cell_mhash, 32) != 0) {
        return XII_LDIL_E_CELL_MHASH_MISMATCH;
    }

    /* Verify cell fits in placeholder. */
    if (cell->payload_size > site->expected_size) {
        return XII_LDIL_E_CELL_OVERSIZE;
    }

    /* Copy payload to placeholder offset. */
    memcpy(text_section + site->call_site_offset, cell->payload, cell->payload_size);

    /* NOP-pad the remainder. */
    uint32_t pad_count = site->expected_size - cell->payload_size;
    if (pad_count > 0) {
        xii_ldil_fill_nops(text_section + site->call_site_offset + cell->payload_size,
                           pad_count, deployment_target);
    }

    return XII_LDIL_OK;
}

/* ------------------------------------------------------------------ */
/* Inline all call sites                                               */
/* ------------------------------------------------------------------ */

int xii_ldil_inline_all(uint8_t *text_section, size_t text_size,
                        const uint8_t *calls_section, size_t calls_size,
                        const struct xii_lattice_cell *lattice, size_t lattice_count,
                        uint8_t *audit_section, size_t audit_capacity,
                        size_t *audit_used,
                        uint32_t deployment_target)
{
    const size_t SITE_BYTES = 24;
    const size_t AUDIT_BYTES = 64;

    if (calls_size % SITE_BYTES != 0) return -XII_LDIL_E_CALLS_CORRUPT;
    size_t n_sites = calls_size / SITE_BYTES;
    size_t audit_off = 0;
    int inlined = 0;

    for (size_t i = 0; i < n_sites; ++i) {
        struct iii_xii_call_site site;
        const uint8_t *p = calls_section + (i * SITE_BYTES);
        site.call_site_offset =
              (uint64_t)p[0] | ((uint64_t)p[1] << 8) | ((uint64_t)p[2] << 16) | ((uint64_t)p[3] << 24)
            | ((uint64_t)p[4] << 32) | ((uint64_t)p[5] << 40) | ((uint64_t)p[6] << 48) | ((uint64_t)p[7] << 56);
        site.horizon_id       = p[8];
        site.static_circ_flag = p[9];
        site.reserved_0       = (uint16_t)(p[10] | ((uint16_t)p[11] << 8));
        site.circ_encoding    = (uint32_t)p[12] | ((uint32_t)p[13] << 8) | ((uint32_t)p[14] << 16) | ((uint32_t)p[15] << 24);
        site.expected_size    = (uint16_t)(p[16] | ((uint16_t)p[17] << 8));
        site.ct_kind          = p[18];
        site.prov_xform_id    = p[19];
        site.deployment_target = (uint32_t)p[20] | ((uint32_t)p[21] << 8) | ((uint32_t)p[22] << 16) | ((uint32_t)p[23] << 24);

        /* Find the cell whose (horizon_id, target) matches this call-site.
         * Per-site deployment_target takes precedence over the global one
         * (a function may pin its own target via @deployment_target). If
         * the site advertises AUTO (0xFFFFFFFF), fall back to the global
         * target. The lattice may carry up to 7 cells per horizon (one
         * per target). */
        uint32_t want_target = (site.deployment_target == 0xFFFFFFFFu)
                                   ? deployment_target
                                   : site.deployment_target;
        const struct xii_lattice_cell *cell = NULL;
        for (size_t j = 0; j < lattice_count; ++j) {
            if ((uint32_t)lattice[j].horizon_id == (uint32_t)site.horizon_id
                && (uint32_t)lattice[j].target == want_target) {
                cell = &lattice[j];
                break;
            }
        }
        if (!cell) continue;
        int rc = xii_ldil_inline_one(text_section, text_size, &site, cell, want_target);
        if (rc != XII_LDIL_OK) return -rc;

        /* Write audit record. */
        if (audit_off + AUDIT_BYTES > audit_capacity) return -XII_LDIL_E_INTERNAL;
        uint8_t *ap = audit_section + audit_off;
        for (int b = 0; b < 8; ++b) ap[b] = (uint8_t)((site.call_site_offset >> (b * 8)) & 0xFF);
        ap[8] = site.horizon_id;
        ap[9] = site.ct_kind;
        ap[10] = site.prov_xform_id;
        ap[11] = 0;
        for (int b = 0; b < 4; ++b) ap[12 + b] = (uint8_t)((site.circ_encoding >> (b * 8)) & 0xFF);
        for (int b = 0; b < 4; ++b) ap[16 + b] = (uint8_t)((cell->payload_size >> (b * 8)) & 0xFF);
        uint32_t pad = site.expected_size - cell->payload_size;
        for (int b = 0; b < 4; ++b) ap[20 + b] = (uint8_t)((pad >> (b * 8)) & 0xFF);
        memcpy(ap + 24, cell->cell_mhash, 32);
        audit_off += AUDIT_BYTES;
        ++inlined;
    }

    if (audit_used) *audit_used = audit_off;
    return inlined;
}
