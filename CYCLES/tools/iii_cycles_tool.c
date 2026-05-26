/* ============================================================================
 * III-CYCLES — iii_cycles_tool.c
 *
 * CLI for the cycle calculus.  Subcommands:
 *   info                       — module identity and step-kind band table
 *   bands                      — print all 20 step_kind bands and ranges
 *   se-kinds                   — print the 17 SE kinds
 *   sid-steps                  — print the 32 SID steps in order
 *   hash <file>                — SHA-256 of a file (R1.A5 helper)
 *   blake3 <file>              — BLAKE3 of a file
 *   demo                       — emit a 4-witness chain and print mhashes
 * ============================================================================
 */
#include "iii/cycles.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

void iii_sha256(const void *data, size_t len, uint8_t out[32]);
void iii_blake3(const uint8_t *data, size_t len, uint8_t out[32]);

static void hex(const uint8_t *b, size_t n) {
    for (size_t i = 0; i < n; ++i) printf("%02x", b[i]);
}

static int cmd_info(void) {
    printf("III-CYCLES (Doc-ID A5, R1.A5)\n");
    printf("  17 SE kinds, 32-step SID, 128-byte XiiWitness, BCWL\n");
    printf("  Catalyst rate cap: %u promotions per chronos-tick\n",
           XII_MNEME_CATALYST_PROMOTION_RATE_PER_TICK);
    printf("  R1.A5: ");
    hex(III_CYCLES_R1_A5, 32);
    printf("\n");
    return 0;
}

static int cmd_bands(void) {
    for (int b = 0; b < (int)III_BAND_COUNT; ++b) {
        if (b == III_BAND_UNKNOWN) continue;
        uint16_t lo = 0, hi = 0;
        iii_step_kind_band_range((iii_step_kind_band_t)b, &lo, &hi);
        if (lo == 0 && hi == 0 && b != 0) continue;
        printf("  0x%04x..0x%04x  %s\n", lo, hi,
               iii_step_kind_band_name((iii_step_kind_band_t)b));
    }
    return 0;
}

static int cmd_se_kinds(void) {
    for (int k = 1; k < (int)III_SE_COUNT; ++k) {
        printf("  0x%02x  %s\n", k, iii_se_kind_name((iii_se_kind_t)k));
    }
    return 0;
}

static int cmd_sid_steps(void) {
    for (int s = 1; s < (int)III_SID_STEP_COUNT; ++s) {
        printf("  %s\n", iii_sid_step_name((iii_sid_step_t)s));
    }
    return 0;
}

static int cmd_hash(const char *path, bool use_blake3) {
    FILE *f = fopen(path, "rb");
    if (!f) { fprintf(stderr, "cannot open %s\n", path); return 2; }
    fseek(f, 0, SEEK_END);
    long n = ftell(f);
    fseek(f, 0, SEEK_SET);
    uint8_t *buf = (uint8_t *)malloc((size_t)n);
    if (!buf) { fclose(f); return 2; }
    if (fread(buf, 1, (size_t)n, f) != (size_t)n) { free(buf); fclose(f); return 2; }
    fclose(f);
    uint8_t h[32];
    if (use_blake3) iii_blake3(buf, (size_t)n, h);
    else            iii_sha256(buf, (size_t)n, h);
    free(buf);
    hex(h, 32); printf("\n");
    return 0;
}

static int cmd_demo(void) {
    iii_witness_emitter_t *e = iii_witness_emitter_create(0);
    iii_witness_request_t r; memset(&r, 0, sizeof(r));
    r.plan_anchor_id = 0x42;
    r.hexad_packed = 1;
    r.cost_q14 = 100;
    iii_xii_witness_t w;
    for (unsigned i = 0; i < 4; ++i) {
        r.step_kind = (uint16_t)(0x0011 + i);
        iii_witness_emit(e, &r, &w);
        printf("  witness %u (step=%s):\n", i + 1,
               iii_step_kind_band_name(iii_step_kind_band(r.step_kind)));
        printf("    pred: "); hex(w.predecessor_mhash, 32); printf("\n");
        printf("    succ: "); hex(w.successor_mhash, 32);   printf("\n");
    }
    iii_witness_emitter_destroy(e);
    return 0;
}

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr,
            "usage: iii_cycles_tool <subcommand>\n"
            "  info | bands | se-kinds | sid-steps | demo\n"
            "  hash <file> | blake3 <file>\n");
        return 1;
    }
    if (strcmp(argv[1], "info")     == 0) return cmd_info();
    if (strcmp(argv[1], "bands")    == 0) return cmd_bands();
    if (strcmp(argv[1], "se-kinds") == 0) return cmd_se_kinds();
    if (strcmp(argv[1], "sid-steps")== 0) return cmd_sid_steps();
    if (strcmp(argv[1], "demo")     == 0) return cmd_demo();
    if (strcmp(argv[1], "hash")     == 0 && argc == 3) return cmd_hash(argv[2], false);
    if (strcmp(argv[1], "blake3")   == 0 && argc == 3) return cmd_hash(argv[2], true);
    fprintf(stderr, "unknown subcommand\n");
    return 1;
}
