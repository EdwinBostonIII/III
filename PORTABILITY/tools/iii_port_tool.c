/* iii_port_tool: archs | select <ARCH> | closure <FILE>... */
#include "iii/portability.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int read_file(const char *path, uint8_t **out, size_t *len) {
    FILE *f = fopen(path, "rb");
    if (!f) { perror(path); return -1; }
    fseek(f, 0, SEEK_END);
    long n = ftell(f);
    if (n < 0) { fclose(f); return -1; }
    fseek(f, 0, SEEK_SET);
    uint8_t *buf = (uint8_t *)malloc((size_t)n);
    if (!buf) { fclose(f); return -1; }
    if (n && fread(buf, 1, (size_t)n, f) != (size_t)n) {
        free(buf); fclose(f); return -1;
    }
    fclose(f);
    *out = buf; *len = (size_t)n;
    return 0;
}

static const char *basename_p(const char *p) {
    const char *b = p;
    for (const char *q = p; *q; ++q)
        if (*q == '/' || *q == '\\') b = q + 1;
    return b;
}

static int cmd_archs(void) {
    const iii_arch_t archs[] = { IIIARCH_X86_64, IIIARCH_ARMV8, IIIARCH_RISCV_H,
                                 IIIARCH_INTEL_VMX, IIIARCH_POWER9 };
    for (size_t i = 0; i < sizeof archs / sizeof archs[0]; ++i) {
        const iii_hal_t *h = iii_hal_select(archs[i]);
        printf("%-10s  binding=0x%02x  cpus=%u  numa=%u  opcodes=%zu\n",
               h->name, h->arch_binding, h->cpu_count(), h->numa_node_count(),
               h->opcode_count);
    }
    return 0;
}

static int cmd_select(int argc, char **argv) {
    if (argc < 1) { fprintf(stderr, "select: missing ARCH\n"); return 2; }
    iii_arch_t a;
    if (iii_arch_parse(argv[0], &a) != 0) {
        fprintf(stderr, "select: unknown arch '%s'\n", argv[0]);
        return 2;
    }
    const iii_hal_t *h = iii_hal_select(a);
    printf("arch:         %s\n", h->name);
    printf("binding:      0x%02x\n", h->arch_binding);
    printf("cpu_count:    %u\n", h->cpu_count());
    printf("numa_nodes:   %u\n", h->numa_node_count());
    printf("opcode_count: %zu\n", h->opcode_count);
    for (size_t i = 0; i < h->opcode_count; ++i) {
        printf("  %-12s ", h->opcodes[i].mnemonic);
        for (size_t j = 0; j < h->opcodes[i].len; ++j)
            printf("%02X ", h->opcodes[i].bytes[j]);
        printf("\n");
    }
    printf("intercept_map (closure-pinned):\n");
    for (int i = 0; i < IIIIC__COUNT; ++i)
        printf("  ic[%2d] = %u\n", i, h->intercept_map[i]);
    printf("npt_class_map (closure-pinned):\n");
    for (int i = 0; i < IIINPT__COUNT; ++i)
        printf("  cls[%d] = 0x%016llx\n", i,
               (unsigned long long)h->npt_class_map[i]);
    return 0;
}

static int cmd_closure(int argc, char **argv) {
    if (argc < 1) { fprintf(stderr, "closure: need at least one FILE\n"); return 2; }
    iii_module_t *mods = (iii_module_t *)calloc((size_t)argc, sizeof *mods);
    if (!mods) return 1;
    int rc = 0;
    for (int i = 0; i < argc; ++i) {
        uint8_t *buf; size_t n;
        if (read_file(argv[i], &buf, &n) != 0) { rc = 1; goto done; }
        mods[i].name  = basename_p(argv[i]);
        mods[i].bytes = buf;
        mods[i].len   = n;
    }
    uint8_t root[32];
    if (iii_closure_root_compute(mods, (size_t)argc, root) != 0) {
        fprintf(stderr, "closure: compute failed\n"); rc = 1; goto done;
    }
    for (int i = 0; i < 32; ++i) printf("%02x", root[i]);
    printf("\n");
done:
    for (int i = 0; i < argc; ++i) free((void *)mods[i].bytes);
    free(mods);
    return rc;
}

static int usage(void) {
    fprintf(stderr,
        "usage: iii_port_tool <command> [args...]\n"
        "  archs                       list supported architectures\n"
        "  select <ARCH>               dump HAL details for ARCH\n"
        "  closure <FILE>...           compute cross-arch closure root\n");
    return 2;
}

int main(int argc, char **argv) {
    if (argc < 2) return usage();
    const char *cmd = argv[1];
    if (!strcmp(cmd, "archs"))   return cmd_archs();
    if (!strcmp(cmd, "select"))  return cmd_select(argc - 2, argv + 2);
    if (!strcmp(cmd, "closure")) return cmd_closure(argc - 2, argv + 2);
    return usage();
}
