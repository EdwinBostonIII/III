#include "iii/observability.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

extern void iii_sha256(const void *data, size_t len, uint8_t out[32]);

static int cmd_info(void) {
    printf("III-OBSERVABILITY (Wave 2.1)\n");
    printf("  12 threshold families: hoeffding, multinomial, wilson, poisson,\n");
    printf("    coupon-collector, cm-sketch, order-stat, nyquist, ess, heaps,\n");
    printf("    rule-of-three, multinomial-dirichlet\n");
    printf("  Query cap: %u witnesses\n", XII_OBSERVABILITY_QUERY_MAX_WITNESSES);
    return 0;
}

static int cmd_thresholds(void) {
    for (int f = 1; f < (int)III_TF_COUNT; ++f) {
        printf("  %u  %s\n", f, iii_threshold_family_name((iii_threshold_family_t)f));
    }
    return 0;
}

static int cmd_hash(const char *path) {
    FILE *f = fopen(path, "rb");
    if (!f) return 2;
    fseek(f, 0, SEEK_END);
    long n = ftell(f); fseek(f, 0, SEEK_SET);
    uint8_t *buf = (uint8_t *)malloc((size_t)n);
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
    if (argc < 2) { fprintf(stderr, "usage: iii_observability_tool info|thresholds|hash <file>\n"); return 1; }
    if (strcmp(argv[1], "info") == 0) return cmd_info();
    if (strcmp(argv[1], "thresholds") == 0) return cmd_thresholds();
    if (strcmp(argv[1], "hash") == 0 && argc == 3) return cmd_hash(argv[2]);
    return 1;
}
