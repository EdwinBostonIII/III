/* ============================================================================
 * III-PHASES — iii_phases_tool.c
 *
 * Command-line tool for the PHASES module.
 *
 * Subcommands:
 *   info                          — print module identity and ring lattice
 *   constructor <src> <dst>       — print the cross-ring constructor for the pair
 *   chain <src> <dst>             — print the constructor chain
 *   hash <file>                   — compute SHA-256 of a file (R1.A7 helper)
 *   demo                          — register a phase-polymorphic cycle and dump
 * ============================================================================
 */
#include "iii/phases.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

/* Exposed by mhash.c */
void iii_phases_sha256(const void *data, size_t len, uint8_t out[32]);

static iii_phase_ring_t parse_ring(const char *s) {
    if (strcmp(s, "R-2") == 0 || strcmp(s, "Sanctum")    == 0) return III_RING_SANCTUM;
    if (strcmp(s, "R-1") == 0 || strcmp(s, "Hypervisor") == 0) return III_RING_HYPERVISOR;
    if (strcmp(s, "R0")  == 0 || strcmp(s, "Kernel")     == 0) return III_RING_KERNEL;
    if (strcmp(s, "R3")  == 0 || strcmp(s, "User")       == 0) return III_RING_USER;
    return III_RING_COUNT;
}

static void print_hex(const uint8_t *bytes, size_t n) {
    for (size_t i = 0; i < n; ++i) printf("%02x", bytes[i]);
}

static int cmd_info(void) {
    printf("III-PHASES (Doc-ID A7, R1.A7)\n");
    printf("  Ring lattice (most → least privileged): R-2 ≼ R-1 ≼ R0 ≼ R3\n");
    printf("  Cross-ring constructors: Magic-MSR, IOCTL, Sanctum-Gate, VMRUN, SYSRET\n");
    printf("  Promotion rate cap (per chronos-tick): %u\n", (unsigned)XII_PHASE_PROMOTE_RATE);
    printf("  R1.A7: ");
    print_hex(III_PHASES_R1_A7, 32);
    printf("\n");
    return 0;
}

static int cmd_constructor(const char *src_s, const char *dst_s) {
    iii_phase_ring_t src = parse_ring(src_s);
    iii_phase_ring_t dst = parse_ring(dst_s);
    if (src == III_RING_COUNT || dst == III_RING_COUNT) {
        fprintf(stderr, "invalid ring (use R-2 R-1 R0 R3)\n");
        return 2;
    }
    iii_phase_constructor_t c = iii_phase_constructor_for(src, dst);
    printf("%s ↔ %s : %s\n",
           iii_phase_ring_name(src),
           iii_phase_ring_name(dst),
           iii_phase_constructor_name(c));
    return 0;
}

static int cmd_chain(const char *src_s, const char *dst_s) {
    iii_phase_ring_t src = parse_ring(src_s);
    iii_phase_ring_t dst = parse_ring(dst_s);
    if (src == III_RING_COUNT || dst == III_RING_COUNT) {
        fprintf(stderr, "invalid ring\n");
        return 2;
    }
    printf("Path %s -> %s (length %u):\n",
           iii_phase_ring_name(src), iii_phase_ring_name(dst),
           iii_phase_chain_length(src, dst));
    iii_phase_ring_t walk = src;
    while (walk != dst) {
        iii_phase_ring_t next = iii_phase_next_hop(walk, dst);
        iii_phase_constructor_t c = iii_phase_constructor_for(walk, next);
        printf("  %-3s --[%s]--> %s\n",
               iii_phase_ring_name(walk),
               iii_phase_constructor_name(c),
               iii_phase_ring_name(next));
        if (walk == next) break;
        walk = next;
    }
    return 0;
}

static int cmd_hash(const char *path) {
    FILE *f = fopen(path, "rb");
    if (!f) {
        fprintf(stderr, "cannot open %s\n", path);
        return 2;
    }
    fseek(f, 0, SEEK_END);
    long n = ftell(f);
    if (n < 0) { fclose(f); return 2; }
    fseek(f, 0, SEEK_SET);

    uint8_t *buf = (uint8_t *)malloc((size_t)n);
    if (!buf) { fclose(f); return 2; }

    size_t read_n = fread(buf, 1, (size_t)n, f);
    fclose(f);
    if (read_n != (size_t)n) {
        free(buf);
        fprintf(stderr, "short read\n");
        return 2;
    }

    uint8_t hash[32];
    iii_phases_sha256(buf, (size_t)n, hash);
    free(buf);

    print_hex(hash, 32);
    printf("\n");
    return 0;
}

static int cmd_demo(void) {
    iii_phase_runtime_t *rt = iii_phase_runtime_create();
    if (!rt) { fprintf(stderr, "OOM\n"); return 1; }

    iii_phase_cycle_t *c = iii_phase_runtime_register_cycle(rt, "demo_read_msr",
                            III_PHASE_SET_ALL);
    iii_phase_cycle_add_body(c, III_RING_HYPERVISOR, 0x1234u, XII_STEP_KIND_IRPD_MSR_READ);
    int s = iii_phase_cycle_synthesize(c);
    iii_phase_cycle_seal(c);

    char setbuf[64];
    iii_phase_set_format(c->declared_phases, setbuf, sizeof(setbuf));
    printf("Cycle '%s' @ring%s\n", c->name, setbuf);
    printf("  synthesised %d lowerings\n", s);
    for (unsigned i = 0; i < c->lowering_count; ++i) {
        iii_phase_lowering_t *lw = &c->lowerings[i];
        printf("    %-3s : %s%s (step=%s)\n",
               iii_phase_ring_name(lw->ring),
               lw->explicit_body ? "explicit" : "synth",
               lw->synthesized   ? "" : "",
               iii_phase_step_kind_name(lw->step_kind));
    }

    iii_phase_runtime_destroy(rt);
    return 0;
}

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr,
            "usage: iii_phases_tool <subcommand>\n"
            "  info\n"
            "  constructor <src> <dst>\n"
            "  chain <src> <dst>\n"
            "  hash <file>\n"
            "  demo\n");
        return 1;
    }

    if (strcmp(argv[1], "info") == 0) return cmd_info();
    if (strcmp(argv[1], "constructor") == 0 && argc == 4) return cmd_constructor(argv[2], argv[3]);
    if (strcmp(argv[1], "chain") == 0 && argc == 4) return cmd_chain(argv[2], argv[3]);
    if (strcmp(argv[1], "hash") == 0 && argc == 3) return cmd_hash(argv[2]);
    if (strcmp(argv[1], "demo") == 0) return cmd_demo();

    fprintf(stderr, "unknown or malformed subcommand\n");
    return 1;
}
