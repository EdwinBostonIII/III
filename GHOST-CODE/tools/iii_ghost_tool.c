#include "iii/ghost_code.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

extern void iii_sha256(const void *data, size_t len, uint8_t out[32]);

static int cmd_info(void) {
    printf("III-GHOST-CODE (Wave 4)\n");
    printf("  Verification gates: %d\n", (int)III_GATE_COUNT - 1);
    printf("  Verification states: ghost / compromise.{low,medium,high} / verified\n");
    printf("  Caps: read_ghost_state, verify, execute_compromised<{low,medium,high}>\n");
    return 0;
}

static int cmd_gates(void) {
    for (unsigned g = 1; g < III_GATE_COUNT; ++g) {
        printf("  %2u  %s\n", g, iii_gate_name((iii_gate_t)g));
    }
    return 0;
}

static int cmd_states(void) {
    for (int s = 0; s <= III_VS_VERIFIED; ++s) {
        printf("  %d  %s\n", s, iii_verify_state_name((iii_verify_state_t)s));
    }
    return 0;
}

static int cmd_hash(const char *path) {
    FILE *f = fopen(path, "rb");
    if (!f) return 2;
    fseek(f, 0, SEEK_END);
    long n = ftell(f); fseek(f, 0, SEEK_SET);
    uint8_t *buf = malloc((size_t)n);
    fread(buf, 1, (size_t)n, f);
    fclose(f);
    uint8_t h[32];
    iii_sha256(buf, (size_t)n, h);
    free(buf);
    for (unsigned i = 0; i < 32; ++i) printf("%02x", h[i]);
    printf("\n");
    return 0;
}

int main(int argc, char **argv) {
    if (argc < 2) { fprintf(stderr, "usage: iii_ghost_tool info|gates|states|hash <file>\n"); return 1; }
    if (strcmp(argv[1], "info")   == 0) return cmd_info();
    if (strcmp(argv[1], "gates")  == 0) return cmd_gates();
    if (strcmp(argv[1], "states") == 0) return cmd_states();
    if (strcmp(argv[1], "hash") == 0 && argc == 3) return cmd_hash(argv[2]);
    return 1;
}
