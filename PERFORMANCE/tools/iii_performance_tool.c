#include "iii/performance.h"
#include <stdio.h>
#include <string.h>

static int cmd_info(void) {
    printf("III-PERFORMANCE (Wave 1, items 10-25)\n");
    printf("  SCBA bits: %u\n", III_SCBA_BIT_COUNT);
    printf("  Witness ring capacity: %u\n", III_RING_CAP);
    printf("  Hexad slot count: %u\n", III_HEXAD_SLOT_COUNT);
    printf("  Cycle-dispatch table cap: %u\n", III_CYCLE_DISPATCH_CAP);
    return 0;
}

static int cmd_dispatch(void) {
    iii_dispatch_t d;
    iii_hw_dispatch_init(&d);
    printf("  sha256       : %s\n", iii_path_name(d.sha256_path));
    printf("  blake3       : %s\n", iii_path_name(d.blake3_path));
    printf("  shake256     : %s\n", iii_path_name(d.shake256_path));
    printf("  hmac         : %s (%u lanes)\n", iii_path_name(d.hmac_path), d.hmac_simd_lanes);
    printf("  hexad-compose: %s\n", iii_path_name(d.hexad_compose_path));
    return 0;
}

static int cmd_budget(void) {
    for (unsigned s = 0; s < III_PERF_STAGE_COUNT; ++s) {
        printf("  %-20s %5llu cycles\n",
               iii_perf_stage_name((iii_perf_stage_t)s),
               (unsigned long long)III_PERF_BUDGET_CYCLES[s]);
    }
    return 0;
}

int main(int argc, char **argv) {
    if (argc < 2) { fprintf(stderr, "usage: iii_performance_tool info|dispatch|budget\n"); return 1; }
    if (strcmp(argv[1], "info") == 0)     return cmd_info();
    if (strcmp(argv[1], "dispatch") == 0) return cmd_dispatch();
    if (strcmp(argv[1], "budget") == 0)   return cmd_budget();
    return 1;
}
