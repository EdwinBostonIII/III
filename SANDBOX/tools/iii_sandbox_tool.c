#include "iii/sandbox.h"
#include <stdio.h>
#include <string.h>

extern void iii_sha256(const void *data, size_t len, uint8_t out[32]);

static int cmd_info(void) {
    printf("III-SANDBOX (Wave 10.1, items 86-90)\n");
    printf("  Lifecycle states: Created Running Suspended Snapshotted Terminated Discarded\n");
    printf("  Max recursion depth: %u\n", XII_SANDBOX_MAX_RECURSION_DEPTH);
    printf("  Max sandboxes per runtime: %u\n", III_SANDBOX_MAX);
    printf("  Max snapshots per sandbox: %u\n", III_SANDBOX_MAX_SNAPSHOTS);
    return 0;
}

static int cmd_states(void) {
    for (int s = 0; s <= III_SBX_DISCARDED; ++s) {
        printf("  %d  %s\n", s, iii_sandbox_state_name((iii_sandbox_state_t)s));
    }
    return 0;
}

int main(int argc, char **argv) {
    if (argc < 2) { fprintf(stderr, "usage: iii_sandbox_tool info|states\n"); return 1; }
    if (strcmp(argv[1], "info") == 0)   return cmd_info();
    if (strcmp(argv[1], "states") == 0) return cmd_states();
    return 1;
}
