/* III TYPES — CLI front-end. */
#include "iii/types.h"
#include "iii/types_term.h"
#include "iii/types_hexad.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int cmd_hash(const char *path) {
    uint8_t out[32];
    int rc = iii_r1_a3_hash_file(path, out);
    if (rc) { fprintf(stderr, "hash failed (%d)\n", rc); return rc; }
    for (int i = 0; i < 32; ++i) printf("%02x", out[i]);
    printf("\n");
    return 0;
}

static int cmd_bitmap_hash(void) {
    uint8_t out[32];
    iii_hexad_bitmap_hash(out);
    for (int i = 0; i < 32; ++i) printf("%02x", out[i]);
    printf("\n");
    return 0;
}

static int cmd_self_check(void) {
    /* Build a minimal synthetic AST and run the type-checker through
     * its three passes, dumping inferred types. */
    iii_type_env_t *e = iii_type_env_create();
    iii_ast_node_t lit = { .kind = III_AST_LITERAL, .int_value = 42 };
    iii_ast_node_t *kids[1] = { &lit };
    iii_ast_node_t mod = { .kind = III_AST_MODULE, .children = kids, .child_count = 1 };
    iii_typed_module_t *m = iii_check_module(e, &mod);
    printf("annotations=%zu diags=%zu\n",
           iii_typed_size(m), iii_type_env_diag_count(e));
    iii_type_t *t = iii_typed_lookup(m, &lit);
    if (t) {
        char buf[128]; iii_type_print(t, buf, sizeof buf);
        printf("literal : %s\n", buf);
    }
    free(m);
    iii_type_env_destroy(e);
    return 0;
}

int main(int argc, char **argv) {
    if (argc < 2) {
        printf("usage: iii_types_tool {--hash FILE | --bitmap-hash | --self-check | --module}\n");
        printf("module: %s v%s\n", III_TYPES_MODULE_NAME, III_TYPES_MODULE_VERSION);
        return 0;
    }
    if (!strcmp(argv[1], "--hash") && argc > 2)  return cmd_hash(argv[2]);
    if (!strcmp(argv[1], "--bitmap-hash"))       return cmd_bitmap_hash();
    if (!strcmp(argv[1], "--self-check"))        return cmd_self_check();
    if (!strcmp(argv[1], "--module")) {
        printf("%s v%s\n", III_TYPES_MODULE_NAME, III_TYPES_MODULE_VERSION); return 0;
    }
    fprintf(stderr, "unknown command\n"); return 1;
}
