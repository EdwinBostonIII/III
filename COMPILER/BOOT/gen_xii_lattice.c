/* COMPILER/BOOT/gen_xii_lattice.c
 *
 * Generates xii_lattice.bin (sealed Lattice cells) per DOCS/III-XII.md S12.
 *
 * For each productive Horizon pattern (126) and each of 7 deployment targets,
 * generates the cell payload via xii_emit_gen (extern) and writes a 48-byte
 * cell record followed by the payload bytes.
 *
 * Output layout:
 *   header[16]: magic "XIILAT\0\0\0\0\0\0\0\0\0\0" + u32 cell_count + u32 reserved
 *   cells[N*48]: per-cell records (mhash + offset + size + flags)
 *   payloads[*]: per-cell byte sequences
 *
 * NIH: libc only.
 */

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_PRODUCTIVE 126
#define TARGET_COUNT   7
#define MAX_CELLS      (MAX_PRODUCTIVE * TARGET_COUNT)
#define CELL_BYTES     48
#define MAX_PAYLOAD    512

/* Externs from xii_horizon.iii / xii_emit_gen.iii. */
extern int xii_horizon_init(void);
extern uint8_t xii_horizon_is_productive(uint32_t id);
extern uint8_t xii_horizon_ct_kind(uint32_t id);
extern uint8_t xii_horizon_primary_op(uint32_t id);
extern uint32_t xii_emit_gen_produce(uint32_t horizon_id, uint32_t target, uint32_t expected_size, uint8_t *out);
extern int xii_emit_gen_cell_mhash(uint32_t horizon_id, uint32_t target, uint32_t size, uint8_t *payload_ptr, uint8_t *out_32);
extern uint32_t sha256_oneshot(const uint8_t *input, uint64_t len, uint8_t *out_32);

/* Derive per-horizon expected cell-size envelope by primary op + target.
 * Sizes are upper bounds per S26.10; the emitter is free to produce a
 * smaller payload, but never larger.
 *
 *   target 0..6 = x86_avx512, x86_avx2, x86_scalar_ct, arm64_neon,
 *                 arm64_sve2, riscv64_v, embedded_safe
 */
/* Prologue+epilogue byte counts per target, mirroring xii_emit_gen.iii
 * (_prologue_emit_len + _epilogue_emit_len) EXACTLY.  The cell payload is
 * prologue + body + epilogue, so the payload-size budget MUST include the
 * frame overhead -- otherwise xii_emit_gen_produce rejects the cell
 * (expected_size < prologue+epilogue).  The prior envelope omitted the frame
 * and dropped 127 of the 882 cells: the small-body functor ops (K17 LIFT,
 * F.COMPOSE/THEN/WITH/UNDER, body 16/24) fell below the wide frames on the
 * x86 (23B) and riscv64 (28B) targets. */
static uint32_t
target_pe_len(uint32_t target)
{
    switch (target) {
    case 0: case 1: case 2: return 23;   /* x86:     11 + 12 */
    case 3: case 4:         return 16;   /* arm64:    8 +  8 */
    case 5:                 return 28;   /* riscv64: 12 + 16 */
    case 6:                 return 6;    /* cortex-m: 4 +  2 */
    default:                return 0;
    }
}

static uint32_t
expected_cell_size(uint8_t primary_op, uint32_t target)
{
    /* Per-op kernel BODY budget (S26.10 envelope): heavy crypto needs more
     * body; structural functors need less. */
    uint32_t body;
    switch (primary_op) {
    case 0:   body = 32;  break;   /* K01 FORM        */
    case 4:   body = 48;  break;   /* K05 ACT         */
    case 6:   body = 64;  break;   /* K07 SEAL        */
    case 7:   body = 96;  break;   /* K08 PROVE       */
    case 8:   body = 32;  break;   /* K09 QUERY       */
    case 10:  body = 48;  break;   /* K11 GOVERN      */
    case 15:  body = 64;  break;   /* K16 LOOP        */
    case 16:  body = 16;  break;   /* K17 LIFT        */
    case 17:  body = 32;  break;   /* K18 REFLECT     */
    case 18:  body = 16;  break;   /* F.COMPOSE       */
    case 19:  body = 16;  break;   /* F.THEN          */
    case 20:  body = 24;  break;   /* F.WITH          */
    case 21:  body = 24;  break;   /* F.UNDER         */
    case 22:  body = 32;  break;   /* F.IF            */
    case 23:  body = 96;  break;   /* F.LOOP          */
    default:  body = 64;  break;
    }
    /* Wide-vector target gets a larger body; others use the base body. */
    if (target == 0)  { body = body + (body >> 1); }   /* AVX-512: +50%   */
    /* Payload budget = frame (prologue+epilogue) + kernel body, so every
     * (horizon, target) cell fits and the real kernel is never squeezed out. */
    return target_pe_len(target) + body;
}

/* Per-horizon prov_xform_id. CT class 0..8 maps to prov 0..8 in the 17-
 * slot transform space (S26.5). The remaining 9..16 are reserved for
 * runtime-witness transforms. */
static uint8_t
horizon_prov_xform_id(uint32_t h)
{
    uint8_t ct = xii_horizon_ct_kind(h);
    return ct;
}

static void
write_u32_le(uint8_t *out, uint32_t val)
{
    out[0] = (uint8_t)(val & 0xFF);
    out[1] = (uint8_t)((val >> 8) & 0xFF);
    out[2] = (uint8_t)((val >> 16) & 0xFF);
    out[3] = (uint8_t)((val >> 24) & 0xFF);
}

int
main(int argc, char **argv)
{
    if (argc < 2) {
        fprintf(stderr, "usage: %s <output_dir>\n", argv[0]);
        return 1;
    }
    const char *out_dir = argv[1];

    xii_horizon_init();

    /* Two-pass write: first determine all sizes, then emit. */
    uint32_t cell_count = 0;
    uint8_t cell_records[MAX_CELLS * CELL_BYTES];
    uint8_t *payload_arena = (uint8_t *)malloc(MAX_CELLS * MAX_PAYLOAD);
    if (!payload_arena) { fprintf(stderr, "OOM\n"); return 2; }
    uint32_t payload_offset = 0;

    for (uint32_t h = 0; h < 144; ++h) {
        if (xii_horizon_is_productive(h) != 1) continue;
        uint8_t primary = xii_horizon_primary_op(h);
        uint8_t prov_id = horizon_prov_xform_id(h);
        uint8_t ct_kind = xii_horizon_ct_kind(h);
        for (uint32_t t = 0; t < TARGET_COUNT; ++t) {
            uint8_t buf[MAX_PAYLOAD];
            uint32_t expected_size = expected_cell_size(primary, t);
            if (expected_size > MAX_PAYLOAD) { expected_size = MAX_PAYLOAD; }
            uint32_t size = xii_emit_gen_produce(h, t, expected_size, buf);
            if (size == 0 || size > MAX_PAYLOAD) {
                /* Every productive horizon x target MUST yield a cell (882
                 * total per S26.10).  A drop here means the size envelope or
                 * the kernel emitter regressed -- fail loudly rather than seal
                 * a short lattice. */
                fprintf(stderr, "[xii] FATAL: cell drop h=%u t=%u primary=%u expected=%u size=%u\n",
                        h, t, primary, expected_size, size);
                free(payload_arena);
                return 3;
            }

            uint8_t mhash[32];
            xii_emit_gen_cell_mhash(h, t, size, buf, mhash);

            /* Cell record (48 bytes per S26.10):
             *   [0..31]  payload mhash
             *   [32..35] payload_offset (LE u32)
             *   [36..39] payload_size (LE u32)
             *   [40]     ct_kind (0..8)
             *   [41]     prov_xform_id (0..16)
             *   [42]     flags: bit0=is_horizon, bit1=is_inlined_by_ldil,
             *                   bit2=is_ct_pinned (=1 iff ct_kind != 0)
             *   [43]     target (0..6)
             *   [44..45] horizon_id (LE u16; 0..143)
             *   [46..47] reserved (zero) */
            uint8_t *rec = &cell_records[cell_count * CELL_BYTES];
            memcpy(rec, mhash, 32);
            write_u32_le(rec + 32, payload_offset);
            write_u32_le(rec + 36, size);
            rec[40] = ct_kind;
            rec[41] = prov_id;
            uint8_t flags = 0x01 | 0x02;
            if (ct_kind != 0) { flags |= 0x04; }
            rec[42] = flags;
            rec[43] = (uint8_t)t;
            rec[44] = (uint8_t)(h & 0xFF);
            rec[45] = (uint8_t)((h >> 8) & 0xFF);
            rec[46] = 0; rec[47] = 0;

            /* Copy payload to arena. */
            memcpy(payload_arena + payload_offset, buf, size);
            payload_offset += size;
            cell_count++;
        }
    }

    /* Write the Lattice file. */
    char path[1024];
    snprintf(path, sizeof(path), "%s/COMPILED/xii_lattice.bin", out_dir);
    FILE *out = fopen(path, "wb");
    if (!out) { fprintf(stderr, "cannot write %s\n", path); free(payload_arena); return 2; }

    /* Header: magic + cell_count + payload_total_size. */
    uint8_t hdr[16];
    memcpy(hdr, "XIILAT\0\0", 8);
    write_u32_le(hdr + 8, cell_count);
    write_u32_le(hdr + 12, payload_offset);
    fwrite(hdr, 1, 16, out);

    /* Cell records. */
    fwrite(cell_records, 1, cell_count * CELL_BYTES, out);

    /* Payloads. */
    fwrite(payload_arena, 1, payload_offset, out);

    fclose(out);
    free(payload_arena);

    /* Compute and emit lattice mhash. */
    snprintf(path, sizeof(path), "%s/COMPILED/xii_lattice.bin", out_dir);
    FILE *rd = fopen(path, "rb");
    if (!rd) return 2;
    fseek(rd, 0, SEEK_END);
    long sz = ftell(rd);
    fseek(rd, 0, SEEK_SET);
    uint8_t *all = (uint8_t *)malloc(sz);
    fread(all, 1, sz, rd);
    fclose(rd);
    uint8_t mhash[32];
    sha256_oneshot(all, (uint64_t)sz, mhash);
    free(all);

    snprintf(path, sizeof(path), "%s/COMPILED/xii_lattice.mhash.golden", out_dir);
    FILE *gh = fopen(path, "wb");
    for (int i = 0; i < 32; ++i) fprintf(gh, "%02x", mhash[i]);
    fprintf(gh, "\n");
    fclose(gh);

    printf("[xii] lattice written: %u cells, %u bytes payload\n", cell_count, payload_offset);
    printf("[xii] lattice mhash: ");
    for (int i = 0; i < 32; ++i) printf("%02x", mhash[i]);
    printf("\n");
    return 0;
}
