/* COMPILER/BOOT/xii_lattice_loader.c — xii_lattice.bin reader.
 *
 * On-disk layout (per gen_xii_lattice.c):
 *   header[16] :
 *     [0..7]   "XIILAT\0\0"
 *     [8..11]  cell_count (LE u32)
 *     [12..15] payload_total_size (LE u32)
 *   cells[cell_count * 48] : 48-byte records
 *     [0..31]  payload mhash
 *     [32..35] payload_offset (LE u32; relative to start of payload area)
 *     [36..39] payload_size (LE u32)
 *     [40]     ct_kind
 *     [41]     prov_xform_id
 *     [42]     flags
 *     [43]     target
 *     [44..45] horizon_id (LE u16)
 *     [46..47] reserved
 *   payloads[payload_total_size]
 *
 * NIH: libc only. SHA-256 from numera/sha256.iii (linked).
 */

#ifdef IIIS_XII_ENABLED

#include "xii_lattice_loader.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern uint32_t sha256_oneshot(const uint8_t *input, uint64_t len, uint8_t *out_32);

#define CELL_BYTES 48
#define HDR_BYTES  16

static uint32_t
read_u32_le(const uint8_t *p)
{
    return (uint32_t)p[0]
         | ((uint32_t)p[1] << 8)
         | ((uint32_t)p[2] << 16)
         | ((uint32_t)p[3] << 24);
}

static uint16_t
read_u16_le(const uint8_t *p)
{
    return (uint16_t)((uint16_t)p[0] | ((uint16_t)p[1] << 8));
}

int
xii_lattice_load(const char *path,
                 struct xii_lattice_cell **out_cells,
                 size_t *out_count,
                 uint8_t **out_arena,
                 int verify_mhash)
{
    if (!out_cells || !out_count || !out_arena) { return XII_LL_E_HEADER; }
    *out_cells = NULL;
    *out_count = 0;
    *out_arena = NULL;

    FILE *f = fopen(path, "rb");
    if (!f) { return XII_LL_E_OPEN; }

    uint8_t hdr[HDR_BYTES];
    if (fread(hdr, 1, HDR_BYTES, f) != HDR_BYTES) {
        fclose(f); return XII_LL_E_HEADER;
    }
    if (memcmp(hdr, "XIILAT\0\0", 8) != 0) {
        fclose(f); return XII_LL_E_HEADER;
    }
    uint32_t cell_count    = read_u32_le(hdr + 8);
    uint32_t payload_total = read_u32_le(hdr + 12);

    if (cell_count == 0) {
        fclose(f);
        return XII_LL_OK;  /* empty lattice is legal */
    }

    uint8_t *records = (uint8_t *)malloc((size_t)cell_count * CELL_BYTES);
    if (!records) { fclose(f); return XII_LL_E_OOM; }
    if (fread(records, 1, (size_t)cell_count * CELL_BYTES, f)
        != (size_t)cell_count * CELL_BYTES) {
        free(records); fclose(f); return XII_LL_E_TRUNCATED;
    }

    uint8_t *arena = NULL;
    if (payload_total > 0) {
        arena = (uint8_t *)malloc(payload_total);
        if (!arena) {
            free(records); fclose(f); return XII_LL_E_OOM;
        }
        if (fread(arena, 1, payload_total, f) != payload_total) {
            free(arena); free(records); fclose(f);
            return XII_LL_E_TRUNCATED;
        }
    }
    fclose(f);

    struct xii_lattice_cell *cells =
        (struct xii_lattice_cell *)calloc(cell_count, sizeof(*cells));
    if (!cells) {
        free(arena); free(records);
        return XII_LL_E_OOM;
    }

    for (uint32_t i = 0; i < cell_count; ++i) {
        const uint8_t *rec = records + (i * CELL_BYTES);
        memcpy(cells[i].cell_mhash, rec, 32);
        cells[i].payload_offset = read_u32_le(rec + 32);
        cells[i].payload_size   = read_u32_le(rec + 36);
        cells[i].ct_kind        = rec[40];
        cells[i].prov_xform_id  = rec[41];
        cells[i].flags          = rec[42];
        cells[i].target         = rec[43];
        cells[i].horizon_id     = read_u16_le(rec + 44);
        cells[i].reserved_1     = 0;

        /* Bounds-check payload offset+size against arena. */
        if ((uint64_t)cells[i].payload_offset + (uint64_t)cells[i].payload_size
            > (uint64_t)payload_total) {
            free(cells); free(arena); free(records);
            return XII_LL_E_TRUNCATED;
        }
        cells[i].payload = (cells[i].payload_size == 0)
            ? NULL : (arena + cells[i].payload_offset);

        /* Optional integrity check. */
        if (verify_mhash && cells[i].payload_size > 0) {
            uint8_t recomputed[32];
            sha256_oneshot(cells[i].payload, cells[i].payload_size, recomputed);
            if (memcmp(recomputed, cells[i].cell_mhash, 32) != 0) {
                free(cells); free(arena); free(records);
                return XII_LL_E_MHASH_VERIFY;
            }
        }
    }

    free(records);

    *out_cells = cells;
    *out_count = cell_count;
    *out_arena = arena;
    return XII_LL_OK;
}

void
xii_lattice_loader_free(struct xii_lattice_cell *cells, uint8_t *arena)
{
    free(cells);
    free(arena);
}

/* ------------------------------------------------------------------ */
/* Runtime-store integration                                           */
/* ------------------------------------------------------------------ */

/* xii_lattice.iii @export entry points. */
extern int      xii_lattice_reset(void);
extern uint32_t xii_lattice_alloc_cell(const uint8_t *payload_ptr,
                                       uint32_t payload_size,
                                       uint8_t ct_kind,
                                       uint8_t prov_xform_id,
                                       uint8_t flags,
                                       const uint8_t *mhash_ptr);
extern int      xii_lattice_lookup_set(uint8_t horizon_id, uint32_t circ_slot, uint32_t cell_idx);
extern uint32_t xii_lattice_circ_to_slot(uint32_t circ);

/* Map a deployment_target (0..6) to a representative circ encoding so
 * the lookup table has at least one (horizon_id, slot) entry per
 * (horizon, target) tuple.  We use the target value directly as the
 * primary circ field; xii_lattice_circ_to_slot reduces it into the
 * 0..127 slot range expected by the lookup. */
static uint32_t
representative_circ_for_target(uint8_t target)
{
    return (uint32_t)(target & 0x7u);
}

/* Try several candidate paths and return the first one that opens. */
static FILE *
try_open_lattice(const char *explicit_path, const char *argv0,
                 char *resolved, size_t resolved_cap)
{
    /* Candidate 1: caller-provided explicit path. */
    if (explicit_path && explicit_path[0]) {
        FILE *f = fopen(explicit_path, "rb");
        if (f) {
            if (resolved) {
                size_t n = strlen(explicit_path);
                if (n + 1 > resolved_cap) n = resolved_cap - 1;
                memcpy(resolved, explicit_path, n);
                resolved[n] = '\0';
            }
            return f;
        }
    }

    /* Candidate 2: XII_LATTICE_PATH env. */
    const char *env_path = getenv("XII_LATTICE_PATH");
    if (env_path && env_path[0]) {
        FILE *f = fopen(env_path, "rb");
        if (f) {
            if (resolved) {
                size_t n = strlen(env_path);
                if (n + 1 > resolved_cap) n = resolved_cap - 1;
                memcpy(resolved, env_path, n);
                resolved[n] = '\0';
            }
            return f;
        }
    }

    /* Candidate 3: derived from argv0.  We expect a COMPILED/iiis-2.exe
     * layout, so xii_lattice.bin lives alongside the iiis-2 binary. */
    if (argv0 && argv0[0]) {
        char tmp[1024];
        size_t n = strlen(argv0);
        if (n >= sizeof(tmp)) n = sizeof(tmp) - 1;
        memcpy(tmp, argv0, n);
        tmp[n] = '\0';
        /* Strip the basename. */
        for (size_t i = n; i > 0; --i) {
            if (tmp[i - 1] == '/' || tmp[i - 1] == '\\') {
                tmp[i] = '\0';
                break;
            }
            tmp[i - 1] = '\0';
        }
        /* If we ate everything (no separator), use ".". */
        if (tmp[0] == '\0') { tmp[0] = '.'; tmp[1] = '/'; tmp[2] = '\0'; }
        char candidate[1280];
        snprintf(candidate, sizeof(candidate), "%sxii_lattice.bin", tmp);
        FILE *f = fopen(candidate, "rb");
        if (f) {
            if (resolved) {
                size_t cn = strlen(candidate);
                if (cn + 1 > resolved_cap) cn = resolved_cap - 1;
                memcpy(resolved, candidate, cn);
                resolved[cn] = '\0';
            }
            return f;
        }
    }

    /* Candidate 4: cwd. */
    {
        FILE *f = fopen("xii_lattice.bin", "rb");
        if (f) {
            if (resolved && resolved_cap > 16) {
                memcpy(resolved, "xii_lattice.bin", 16);
            }
            return f;
        }
    }

    /* Candidate 5: COMPILED/xii_lattice.bin from cwd. */
    {
        FILE *f = fopen("COMPILED/xii_lattice.bin", "rb");
        if (f) {
            if (resolved && resolved_cap > 26) {
                memcpy(resolved, "COMPILED/xii_lattice.bin", 25);
            }
            return f;
        }
    }

    return NULL;
}

int
xii_lattice_load_into_store(const char *explicit_path, const char *argv0)
{
    char resolved[1280] = {0};
    FILE *probe = try_open_lattice(explicit_path, argv0, resolved, sizeof(resolved));
    if (!probe) {
        /* No bin available -- pre-ceremony or freshly-built; not an error. */
        return 0;
    }
    fclose(probe);

    struct xii_lattice_cell *cells = NULL;
    size_t count = 0;
    uint8_t *arena = NULL;
    int rc = xii_lattice_load(resolved, &cells, &count, &arena, /*verify_mhash=*/1);
    if (rc != XII_LL_OK) {
        /* Real error -- truncated file or mhash mismatch.  Surface it. */
        return -rc;
    }
    if (count == 0) {
        xii_lattice_loader_free(cells, arena);
        return 0;
    }

    /* Wipe the runtime store and rebuild it from the loaded cells. */
    xii_lattice_reset();

    int installed = 0;
    for (size_t i = 0; i < count; ++i) {
        const struct xii_lattice_cell *c = &cells[i];
        uint32_t cell_idx = xii_lattice_alloc_cell(
            c->payload,
            c->payload_size,
            c->ct_kind,
            c->prov_xform_id,
            c->flags,
            c->cell_mhash);
        if (cell_idx == 0xFFFFFFFFu) { break; }

        /* Wire the (horizon_id, circ_slot) lookup for this cell's target. */
        uint32_t circ = representative_circ_for_target(c->target);
        uint32_t slot = xii_lattice_circ_to_slot(circ);
        xii_lattice_lookup_set((uint8_t)c->horizon_id, slot, cell_idx);

        ++installed;
    }

    xii_lattice_loader_free(cells, arena);
    return installed;
}

#endif /* IIIS_XII_ENABLED */
