/* iii_abi_tool — CLI for the III bootstrap ABI module.
 *
 *   iii_abi_tool validate     <file.iii>
 *   iii_abi_tool lower        <file.iii>
 *   iii_abi_tool marshal-demo
 */
#include <iii/abi.h>
#include <iii/ast.h>
#include <iii/parser.h>
#include <iii/parse_arena.h>
#include <iii/lex.h>
#include <iii/arena.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int read_file(const char *path, uint8_t **out, size_t *out_len) {
    FILE *f = fopen(path, "rb");
    if (!f) { fprintf(stderr, "cannot open %s\n", path); return 1; }
    fseek(f, 0, SEEK_END);
    long n = ftell(f);
    fseek(f, 0, SEEK_SET);
    if (n < 0) { fclose(f); return 1; }
    uint8_t *buf = (uint8_t *)malloc((size_t)n + 1);
    if (!buf) { fclose(f); return 1; }
    size_t rd = fread(buf, 1, (size_t)n, f);
    fclose(f);
    buf[rd] = 0;
    *out = buf;
    *out_len = rd;
    return 0;
}

static iii_ast_node_t *parse_one(const char *path,
                                 uint8_t **out_src, size_t *out_len,
                                 iii_lex_state_t **out_lex,
                                 iii_arena_t **out_arena,
                                 iii_parser_t **out_parser) {
    if (read_file(path, out_src, out_len) != 0) return NULL;
    iii_lex_state_t *lex = iii_lex_create(*out_src, *out_len, path);
    if (!lex) return NULL;
    iii_arena_t *arena = iii_arena_create();
    if (!arena) return NULL;
    iii_parser_t *p = iii_parser_create(lex, arena);
    if (!p) return NULL;
    iii_ast_node_t *root = iii_parse_module(p);
    *out_lex = lex;
    *out_arena = arena;
    *out_parser = p;
    return root;
}

static int cmd_validate(const char *path) {
    uint8_t *src; size_t slen;
    iii_lex_state_t *lex; iii_arena_t *arena; iii_parser_t *par;
    iii_ast_node_t *root = parse_one(path, &src, &slen, &lex, &arena, &par);
    if (!root) { fprintf(stderr, "parse failed: %s\n", path); return 2; }

    int found = 0, ok = 0, fail = 0;
    for (uint32_t i = 0; i < root->child_count; ++i) {
        const iii_ast_node_t *c = root->children[i];
        if (!c || c->kind != III_AST_EXTERN_DECL) continue;
        ++found;
        iii_abi_diag_t d;
        int r = iii_abi_validate_extern(root, c, src, slen, &d);
        if (r == IIIABI_OK) {
            printf("[OK]   extern @abi(c-msvc-x64) at %u:%u — %u item(s)\n",
                   c->line, c->col, c->child_count);
            ++ok;
        } else {
            printf("[FAIL] %s at %u:%u — %s\n",
                   iii_abi_diag_name(d.code),
                   d.line, d.col, d.message);
            ++fail;
        }
    }
    if (!found) {
        printf("[INFO] no extern declarations in %s\n", path);
    } else {
        printf("=== %d ok, %d failed (of %d) ===\n", ok, fail, found);
    }
    iii_parser_destroy(par);
    iii_arena_destroy(arena);
    iii_lex_destroy(lex);
    free(src);
    return fail == 0 ? 0 : 1;
}

static int cmd_lower(const char *path) {
    uint8_t *src; size_t slen;
    iii_lex_state_t *lex; iii_arena_t *arena; iii_parser_t *par;
    iii_ast_node_t *root = parse_one(path, &src, &slen, &lex, &arena, &par);
    if (!root) { fprintf(stderr, "parse failed: %s\n", path); return 2; }

    int n_fns = 0;
    for (uint32_t i = 0; i < root->child_count; ++i) {
        const iii_ast_node_t *c = root->children[i];
        if (!c || c->kind != III_AST_EXTERN_DECL) continue;
        for (uint32_t j = 0; j < c->child_count; ++j) {
            const iii_ast_node_t *it = c->children[j];
            if (!it || it->kind != III_AST_EXTERN_ITEM) continue;
            if (it->op_id != 0) continue;
            iii_abi_signature_t sig;
            int r = iii_abi_lower_signature(c, it, &sig);
            if (r != IIIABI_OK) {
                printf("[FAIL] lower %s (op_id=%u): %s\n",
                       it->string_payload ? (const char *)it->string_payload : "<?>",
                       (unsigned)it->op_id, iii_abi_diag_name(r));
                continue;
            }
            ++n_fns;
            printf("\n--- %s ---\n", sig.name);
            printf("  abi          = %s\n", iii_abi_kind_name(sig.abi));
            printf("  param_count  = %u\n", sig.param_count);
            printf("  shadow_space = %u\n", sig.shadow_space);
            printf("  stack_args   = %u\n", sig.stack_arg_bytes);
            printf("  total_stack  = %u\n", sig.total_stack);
            printf("  hidden_ret_p = %d\n", sig.hidden_ret_ptr);
            for (uint32_t k = 0; k < sig.param_count; ++k) {
                const iii_abi_param_t *p = &sig.params[k];
                printf("  param[%u]: %-12s %-6s class=%-7s loc=%-6s "
                       "size=%u align=%u%s\n",
                       k, p->name, iii_abi_type_name(p->type),
                       iii_abi_class_name(p->cls),
                       iii_abi_loc_name(p->loc),
                       p->size, p->align,
                       p->loc == IIIABI_LOC_STACK
                           ? "" : "");
                if (p->loc == IIIABI_LOC_STACK)
                    printf("            stack_offset=%d (rsp+%u)\n",
                           p->stack_offset,
                           (unsigned)(sig.shadow_space + (uint32_t)p->stack_offset));
            }
            printf("  return:    %-6s class=%-7s loc=%-6s size=%u\n",
                   iii_abi_type_name(sig.ret.type),
                   iii_abi_class_name(sig.ret.cls),
                   iii_abi_loc_name(sig.ret.loc),
                   sig.ret.size);
        }
    }
    printf("\n=== %d fn(s) lowered ===\n", n_fns);
    iii_parser_destroy(par);
    iii_arena_destroy(arena);
    iii_lex_destroy(lex);
    free(src);
    return 0;
}

static int cmd_marshal_demo(void) {
    iii_abi_signature_t sig;
    iii_abi_signature_init(&sig, "sha256_update");
    iii_abi_signature_add_param(&sig, "state",  IIIABI_T_PTR, 0, IIIABI_T_VOID);
    iii_abi_signature_add_param(&sig, "data",   IIIABI_T_PTR, 0, IIIABI_T_U8);
    iii_abi_signature_add_param(&sig, "len",    IIIABI_T_U32, 0, IIIABI_T_VOID);
    iii_abi_signature_set_return(&sig, IIIABI_T_VOID);
    iii_abi_signature_finalize(&sig);

    char buf[8192];
    iii_abi_marshal_call(&sig, buf, sizeof buf);
    fputs(buf, stdout);
    return 0;
}

static int usage(void) {
    fprintf(stderr,
        "usage:\n"
        "  iii_abi_tool validate     <file.iii>\n"
        "  iii_abi_tool lower        <file.iii>\n"
        "  iii_abi_tool marshal-demo\n");
    return 2;
}

int main(int argc, char **argv) {
    if (argc < 2) return usage();
    if (strcmp(argv[1], "validate") == 0 && argc == 3) return cmd_validate(argv[2]);
    if (strcmp(argv[1], "lower")    == 0 && argc == 3) return cmd_lower(argv[2]);
    if (strcmp(argv[1], "marshal-demo") == 0)         return cmd_marshal_demo();
    return usage();
}
