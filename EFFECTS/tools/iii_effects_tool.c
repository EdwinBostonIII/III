/* III EFFECTS — CLI front-end. */
#include "iii/effects.h"
#include <iii/lex.h>
#include <iii/arena.h>
#include <iii/parser.h>
#include <iii/parse_arena.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int read_file(const char *path, uint8_t **out, size_t *outlen) {
    FILE *f = fopen(path, "rb");
    if (!f) return -1;
    fseek(f, 0, SEEK_END); long n = ftell(f); fseek(f, 0, SEEK_SET);
    if (n < 0) { fclose(f); return -1; }
    uint8_t *b = (uint8_t*)malloc((size_t)n + 1);
    if (!b) { fclose(f); return -1; }
    size_t r = fread(b, 1, (size_t)n, f);
    fclose(f);
    b[r] = 0; *out = b; *outlen = r;
    return 0;
}

typedef struct { int per_fn; size_t total; iii_compromise_t maxc; } dump_ud_t;

static void dump_cb(const char *name, size_t name_len,
                    iii_effect_set_t *set, void *ud) {
    dump_ud_t *d = (dump_ud_t*)ud;
    if (d->per_fn) {
        printf("fn %.*s :\n", (int)name_len, name);
        size_t n = iii_effect_set_size(set);
        if (n == 0) printf("    (pure)\n");
        for (size_t i = 0; i < n; ++i) {
            const iii_effect_t *e = iii_effect_set_at(set, i);
            printf("    [%zu] %s  pip=%s  comp=%s%s%s  witness=%u  @%u:%u\n",
                   i,
                   iii_se_kind_name(e->kind),
                   iii_pip_class_name(e->pip),
                   iii_compromise_name(e->compromise),
                   e->ghost  ? "  ghost" : "",
                   e->mobius ? "  mobius" : "",
                   iii_effect_runtime_witness(e),
                   e->site_line, e->site_col);
        }
    }
    iii_compromise_t mc = iii_effect_set_max_compromise(set);
    d->maxc = iii_effect_compromise_join(d->maxc, mc);
    d->total += iii_effect_set_size(set);
    iii_effect_set_destroy(set);
}

static int do_parse_and_walk(const char *path, int per_fn) {
    uint8_t *src = NULL; size_t src_len = 0;
    if (read_file(path, &src, &src_len)) {
        fprintf(stderr, "cannot read %s\n", path); return 2;
    }
    iii_lex_state_t *L = iii_lex_create(src, src_len, path);
    if (!L) { free(src); return 3; }
    iii_arena_t *A = iii_arena_create();
    if (!A) { iii_lex_destroy(L); free(src); return 3; }
    iii_parser_t *P = iii_parser_create(L, A);
    if (!P) { iii_arena_destroy(A); iii_lex_destroy(L); free(src); return 3; }
    iii_ast_node_t *root = iii_parse_module(P);
    iii_effect_env_t *E = iii_effect_env_create(P, NULL);

    dump_ud_t ud = { per_fn, 0, III_COMP_NONE };
    if (root) iii_effect_for_each_function(E, root, dump_cb, &ud);

    if (per_fn) {
        printf("---\ntotal effects: %zu  max-compromise: %s\n",
               ud.total, iii_compromise_name(ud.maxc));
    } else {
        printf("%s\n", iii_compromise_name(ud.maxc));
    }

    iii_effect_env_destroy(E);
    iii_parser_destroy(P);
    iii_arena_destroy(A);
    iii_lex_destroy(L);
    free(src);
    return 0;
}

static int cmd_infer(const char *path)      { return do_parse_and_walk(path, 1); }
static int cmd_compromise(const char *path) { return do_parse_and_walk(path, 0); }

static int cmd_irpd(const char *kind_str) {
    iii_se_kind_t k = iii_se_kind_from_method(kind_str, strlen(kind_str));
    if (k == III_SE_NONE) {
        /* Try matching against enum names too. */
        for (iii_se_kind_t i = III_SE_NONE; i < III_SE_KIND__BUILTIN; ++i) {
            const char *n = iii_se_kind_name(i);
            if (n && strcmp(n, kind_str) == 0) { k = i; break; }
        }
    }
    if (k == III_SE_NONE) {
        fprintf(stderr, "unknown SE kind: %s\n", kind_str);
        fprintf(stderr, "known methods: ");
        for (iii_se_kind_t i = (iii_se_kind_t)1; i < III_SE_KIND__BUILTIN; ++i)
            fprintf(stderr, "%s ", iii_se_kind_method(i));
        fprintf(stderr, "\n");
        return 2;
    }
    printf("kind          : %s\n", iii_se_kind_name(k));
    printf("method        : irpd.%s(...)\n", iii_se_kind_method(k));
    printf("hexad         : %s\n", iii_irpd_hexad_name(k));
    printf("rings         :");
    uint8_t rs = iii_irpd_admissible_rings(k);
    static const char *RNAME[] = { "R-2", "R-1", "R0", "R3" };
    for (int r = 0; r < 4; ++r)
        if (rs & (1u << r)) printf(" %s", RNAME[r]);
    printf("\n");
    printf("inverse kind  : %s\n", iii_se_kind_name(iii_irpd_inverse_kind(k)));
    const char *im = iii_irpd_inverse_method(k);
    printf("inverse method: %s\n", im ? im : "(external)");
    printf("default tier  : %s\n", iii_compromise_name(iii_irpd_default_tier(k)));
    printf("PIP class     : %s\n", iii_pip_class_name(iii_pip_classify(k)));
    return 0;
}

static int cmd_kinds(void) {
    printf("# 17 SE kinds (IRPD-only):\n");
    for (iii_se_kind_t i = III_SE_MSR_WRITE; i < III_SE_KIND__BUILTIN; ++i)
        printf("  %2u %-26s irpd.%-12s -> %s\n",
               (unsigned)i, iii_se_kind_name(i),
               iii_se_kind_method(i),
               iii_se_kind_name(iii_irpd_inverse_kind(i)));
    printf("# 3 Compromise tiers:\n");
    for (iii_compromise_t c = III_COMP_LOW; c < III_COMP__COUNT; ++c)
        printf("  %s  inhabited=%s\n",
               iii_compromise_name(c),
               iii_compromise_inhabited(c) ? "yes" : "NO (uninhabited)");
    return 0;
}

static int cmd_hash(const char *path) {
    uint8_t out[32];
    int rc = iii_r1_a4_hash_file(path, out);
    if (rc) { fprintf(stderr, "hash failed (%d)\n", rc); return rc; }
    for (int i = 0; i < 32; ++i) printf("%02x", out[i]);
    printf("\n");
    return 0;
}

int main(int argc, char **argv) {
    if (argc < 2) {
        printf("usage: iii_effects_tool <cmd> [args]\n");
        printf("  infer       <FILE.III>     -- dump per-function effect set\n");
        printf("  irpd        <KIND|METHOD>  -- show IRPD admissibility/inverse\n");
        printf("  compromise  <FILE.III>     -- highest tier in module\n");
        printf("  kinds                      -- print 17 SE kinds + 3 tiers\n");
        printf("  --hash      <FILE>         -- R1.A4 SHA-256 of file\n");
        printf("  --module                   -- module name/version\n");
        return 0;
    }
    if (!strcmp(argv[1], "infer")      && argc > 2) return cmd_infer(argv[2]);
    if (!strcmp(argv[1], "irpd")       && argc > 2) return cmd_irpd(argv[2]);
    if (!strcmp(argv[1], "compromise") && argc > 2) return cmd_compromise(argv[2]);
    if (!strcmp(argv[1], "kinds"))                  return cmd_kinds();
    if (!strcmp(argv[1], "--hash") && argc > 2)     return cmd_hash(argv[2]);
    if (!strcmp(argv[1], "--module")) {
        printf("%s v%s\n", III_EFFECTS_MODULE_NAME, III_EFFECTS_MODULE_VERSION);
        return 0;
    }
    fprintf(stderr, "unknown command: %s\n", argv[1]);
    return 1;
}
