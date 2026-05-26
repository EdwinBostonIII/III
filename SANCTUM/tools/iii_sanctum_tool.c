/* III-SANCTUM CLI */
#include "iii/sanctum.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

void iii_sha256(const void *data, size_t len, uint8_t out[32]);

static void hex(const uint8_t *b, size_t n) { for (size_t i = 0; i < n; ++i) printf("%02x", b[i]); }

static int cmd_info(void) {
    printf("III-SANCTUM (Doc-ID A8, R1.A8)\n");
    printf("  Sealed-call slots: %u (slot 0 INVALID + slots 1..9 functional)\n",
           XII_SANCTUM_SEAL_COUNT);
    printf("  DRTM quote: %u bytes\n", III_DRTM_QUOTE_BYTES);
    printf("  Phantom NVRAM capacity: %u entries\n", III_PFS_ENTRIES_MAX);
    printf("  Phoenix bookmarks: %u\n", III_PHOENIX_MAX_BOOKMARKS);
    printf("  R1.A8: ");
    hex(III_SANCTUM_R1_A8, 32);
    printf("\n");
    return 0;
}

static int cmd_seals(void) {
    for (unsigned i = 0; i < XII_SANCTUM_SEAL_COUNT; ++i) {
        printf("  slot %u : %s\n", i, iii_sanctum_seal_name((iii_sanctum_seal_t)i));
    }
    return 0;
}

static int cmd_box_steps(void) {
    for (unsigned i = 1; i < (unsigned)III_BOX_STEP_COUNT; ++i) {
        printf("  %s\n", iii_sanctum_box_step_name((iii_sanctum_box_step_t)i));
    }
    return 0;
}

static int cmd_hash(const char *path) {
    FILE *f = fopen(path, "rb");
    if (!f) { fprintf(stderr, "cannot open %s\n", path); return 2; }
    fseek(f, 0, SEEK_END);
    long n = ftell(f);
    fseek(f, 0, SEEK_SET);
    uint8_t *buf = (uint8_t *)malloc((size_t)n);
    if (!buf || fread(buf, 1, (size_t)n, f) != (size_t)n) { free(buf); fclose(f); return 2; }
    fclose(f);
    uint8_t h[32];
    iii_sha256(buf, (size_t)n, h);
    free(buf);
    hex(h, 32); printf("\n");
    return 0;
}

static int cmd_demo(void) {
    iii_sanctum_runtime_t *rt = iii_sanctum_runtime_create();
    iii_drtm_quote_t q;
    iii_sanctum_drtm_relaunch(rt, false, &q);
    printf("DRTM relaunch executed. Epoch=%llu\n", (unsigned long long)q.epoch);
    printf("  silicon: "); hex(q.silicon_fingerprint, 16); printf("...\n");
    printf("  phantom-nvram: "); hex(q.phantom_nvram_mhash, 16); printf("...\n");
    iii_sanctum_runtime_destroy(rt);
    return 0;
}

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr,
            "usage: iii_sanctum_tool <subcommand>\n"
            "  info | seals | box-steps | demo | hash <file>\n");
        return 1;
    }
    if (strcmp(argv[1], "info") == 0)      return cmd_info();
    if (strcmp(argv[1], "seals") == 0)     return cmd_seals();
    if (strcmp(argv[1], "box-steps") == 0) return cmd_box_steps();
    if (strcmp(argv[1], "demo") == 0)      return cmd_demo();
    if (strcmp(argv[1], "hash") == 0 && argc == 3) return cmd_hash(argv[2]);
    fprintf(stderr, "unknown subcommand\n");
    return 1;
}
