/* III LEGACY-INGESTION CLI tool — parse a file, print summary. */
#include "iii/legacy.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static const char *fmt_str(iii_legacy_format_t f) {
    switch (f) {
        case III_LF_ELF: return "ELF";
        case III_LF_PE:  return "PE";
        case III_LF_MACHO: return "Mach-O";
        case III_LF_MACHO_FAT: return "Mach-O (Fat)";
        case III_LF_COFF: return "COFF";
        case III_LF_RAW:  return "RAW";
        default: return "UNKNOWN";
    }
}
static const char *arch_str(iii_legacy_arch_t a) {
    switch (a) {
        case III_LA_X86: return "x86";
        case III_LA_X86_64: return "x86_64";
        case III_LA_ARM: return "arm";
        case III_LA_ARM64: return "arm64";
        case III_LA_RISCV: return "riscv";
        case III_LA_POWERPC: return "powerpc";
        default: return "?";
    }
}
static const char *os_str(iii_legacy_os_t o) {
    switch (o) {
        case III_LOS_LINUX: return "linux";
        case III_LOS_WINDOWS: return "windows";
        case III_LOS_MACOS: return "macos";
        case III_LOS_BSD: return "bsd";
        case III_LOS_EMBEDDED: return "embedded";
        default: return "?";
    }
}
static const char *comp_str(iii_legacy_compromise_t c) {
    switch (c) {
        case III_LCT_NONE: return "none";
        case III_LCT_LOW: return "low";
        case III_LCT_MEDIUM: return "medium";
        case III_LCT_HIGH: return "high";
    }
    return "?";
}

int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "usage: iii_legacy_tool <file>\n");
        return 2;
    }
    FILE *f = fopen(argv[1], "rb");
    if (!f) { perror(argv[1]); return 1; }
    fseek(f, 0, SEEK_END);
    long sz = ftell(f);
    fseek(f, 0, SEEK_SET);
    if (sz <= 0) { fclose(f); fprintf(stderr, "empty\n"); return 1; }
    uint8_t *buf = malloc((size_t)sz);
    if (!buf) { fclose(f); return 1; }
    if (fread(buf, 1, (size_t)sz, f) != (size_t)sz) { fclose(f); free(buf); return 1; }
    fclose(f);

    iii_legacy_format_t fmt = iii_legacy_detect(buf, (size_t)sz);
    printf("file: %s (%ld bytes)\n", argv[1], sz);
    printf("format: %s\n", fmt_str(fmt));

    iii_legacy_module_t m;
    iii_legacy_status_t s = iii_legacy_parse_auto(buf, (size_t)sz, &m);
    if (s != III_LS_OK) {
        fprintf(stderr, "parse error: %s\n", iii_legacy_status_str(s));
        free(buf);
        return 3;
    }
    printf("arch: %s\n", arch_str(m.arch));
    printf("os: %s\n", os_str(m.os));
    printf("compromise: %s\n", comp_str(m.compromise));
    printf("sha256: ");
    for (int i = 0; i < 32; i++) printf("%02x", m.sha256[i]);
    printf("\n");

    iii_legacy_canonical_t canon;
    if (iii_legacy_normalize(&m, &canon) == III_LS_OK) {
        printf("canonical sections: %u\n", canon.section_count);
        for (uint32_t i = 0; i < canon.section_count && i < 16; i++) {
            printf("  [%u] %-24s vaddr=%016llx size=%llu flags=%c%c%c\n", i,
                   canon.sections[i].name,
                   (unsigned long long)canon.sections[i].vaddr,
                   (unsigned long long)canon.sections[i].vsize,
                   (canon.sections[i].flags & III_CANON_F_READ)  ? 'r':'-',
                   (canon.sections[i].flags & III_CANON_F_WRITE) ? 'w':'-',
                   (canon.sections[i].flags & III_CANON_F_EXEC)  ? 'x':'-');
        }
        iii_legacy_canonical_free(&canon);
    }
    iii_legacy_module_free(&m);
    free(buf);
    return 0;
}
