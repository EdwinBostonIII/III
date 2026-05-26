/* iii_errors_tool — CLI lookup over the unified error catalogue. */
#include "iii/errors.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

static int print_one(const iii_error_info_t *e, void *u) {
    (void)u;
    printf("%-36s [%-8s %-12s sev=%s]\n",
           e->name, e->phase, e->subsystem,
           iii_error_severity_name(e->severity));
    return 0;
}

static int print_full(const iii_error_info_t *e, void *u) {
    (void)u;
    printf("%s\n", e->name);
    printf("  code        : %u\n", (unsigned)e->code);
    printf("  phase       : %s\n", e->phase);
    printf("  subsystem   : %s\n", e->subsystem);
    printf("  suffix      : %s\n", e->suffix);
    printf("  severity    : %s\n", iii_error_severity_name(e->severity));
    printf("  description : %s\n", e->description);
    printf("  remediation : %s\n", e->remediation);
    return 0;
}

static int cmd_lookup(const char *arg) {
    const iii_error_info_t *e = iii_error_lookup_by_name(arg);
    if (e == NULL) {
        /* Try numeric */
        char *end = NULL;
        unsigned long v = strtoul(arg, &end, 10);
        if (end != arg && *end == '\0') {
            e = iii_error_lookup((iii_error_code_t)v);
        }
    }
    if (e == NULL) {
        fprintf(stderr, "lookup: unknown code: %s\n", arg);
        return 2;
    }
    print_full(e, NULL);
    return 0;
}

static int cmd_list(void) {
    for (size_t i = 0; i < iii_error_catalog_len; ++i) {
        print_one(&iii_error_catalog[i], NULL);
    }
    return 0;
}

static int cmd_phase(const char *p) {
    size_t n = iii_error_iter_by_phase(p, print_one, NULL);
    if (n == 0) {
        fprintf(stderr, "phase: no entries for '%s'\n", p);
        return 2;
    }
    printf("(%zu entries)\n", n);
    return 0;
}

static int cmd_subsystem(const char *s) {
    size_t n = iii_error_iter_by_subsystem(s, print_one, NULL);
    if (n == 0) {
        fprintf(stderr, "subsystem: no entries for '%s'\n", s);
        return 2;
    }
    printf("(%zu entries)\n", n);
    return 0;
}

static int cmd_prefix(const char *p) {
    size_t n = iii_error_iter_by_prefix(p, print_one, NULL);
    if (n == 0) {
        fprintf(stderr, "prefix: no entries for '%s'\n", p);
        return 2;
    }
    printf("(%zu entries)\n", n);
    return 0;
}

static int cmd_count(void) {
    printf("total: %zu\n", iii_error_count_total());
    for (size_t p = 0; p < iii_phase_table_len; ++p) {
        size_t n = 0;
        for (size_t i = 0; i < iii_error_catalog_len; ++i) {
            if (strcmp(iii_error_catalog[i].phase, iii_phase_table[p].prefix) == 0) ++n;
        }
        printf("  %-8s %-20s %4zu\n", iii_phase_table[p].prefix,
               iii_phase_table[p].display, n);
    }
    return 0;
}

static void usage(void) {
    fprintf(stderr,
        "iii_errors_tool subcommands:\n"
        "  lookup <CODE|NUM>   show full info for one code\n"
        "  list                list every catalogued code\n"
        "  phase <PREFIX>      list codes for phase (e.g. LEX)\n"
        "  subsystem <NAME>    list codes for subsystem (e.g. ENC)\n"
        "  prefix <CODE-PFX>   list codes by code prefix (e.g. LEX-ENC)\n"
        "  count               show total + per-phase counts\n");
}

int main(int argc, char **argv) {
    if (argc < 2) { usage(); return 1; }
    if (strcmp(argv[1], "lookup") == 0    && argc == 3) return cmd_lookup(argv[2]);
    if (strcmp(argv[1], "list") == 0      && argc == 2) return cmd_list();
    if (strcmp(argv[1], "phase") == 0     && argc == 3) return cmd_phase(argv[2]);
    if (strcmp(argv[1], "subsystem") == 0 && argc == 3) return cmd_subsystem(argv[2]);
    if (strcmp(argv[1], "prefix") == 0    && argc == 3) return cmd_prefix(argv[2]);
    if (strcmp(argv[1], "count") == 0     && argc == 2) return cmd_count();
    usage();
    return 1;
}
