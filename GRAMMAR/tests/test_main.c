/* III Grammar — test runner. */
#include "test.h"

int iiit_pass = 0, iiit_fail = 0;
const char *iiit_current = "";

int iiit_parse(const char *src, iiit_parse_t *out) {
    memset(out, 0, sizeof(*out));
    out->src = src;
    out->src_len = strlen(src);
    out->lex = iii_lex_create((const uint8_t *)src, out->src_len, "<test>");
    if (!out->lex) return 0;
    out->arena = iii_arena_create();
    if (!out->arena) { iii_lex_destroy(out->lex); out->lex = NULL; return 0; }
    out->parser = iii_parser_create(out->lex, out->arena);
    if (!out->parser) {
        iii_arena_destroy(out->arena); out->arena = NULL;
        iii_lex_destroy(out->lex);     out->lex = NULL;
        return 0;
    }
    out->root = iii_parse_module(out->parser);
    return out->root != NULL;
}

void iiit_free(iiit_parse_t *f) {
    if (!f) return;
    if (f->parser) { iii_parser_destroy(f->parser); f->parser = NULL; }
    if (f->arena)  { iii_arena_destroy(f->arena);   f->arena  = NULL; }
    if (f->lex)    { iii_lex_destroy(f->lex);       f->lex    = NULL; }
    f->root = NULL;
}

const char *iiit_intern_resolver(uint32_t id, size_t *out_len, void *ud) {
    iii_lex_state_t *lex = (iii_lex_state_t *)ud;
    return iii_lex_intern_text(lex, id, out_len);
}

const iii_ast_node_t *iiit_find_child(const iii_ast_node_t *n, iii_ast_kind_t k) {
    if (!n) return NULL;
    for (uint32_t i = 0; i < n->child_count; i++) {
        if (n->children[i] && n->children[i]->kind == k) return n->children[i];
    }
    return NULL;
}

size_t iiit_count_kind(const iii_ast_node_t *n, iii_ast_kind_t k) {
    if (!n) return 0;
    size_t c = (n->kind == k) ? 1 : 0;
    for (uint32_t i = 0; i < n->child_count; i++) c += iiit_count_kind(n->children[i], k);
    return c;
}

size_t iiit_count_error_nodes(const iii_ast_node_t *n) {
    if (!n) return 0;
    size_t c = (n->kind == III_AST_ERROR || n->kind == III_AST_RECOVERY) ? 1 : 0;
    for (uint32_t i = 0; i < n->child_count; i++) c += iiit_count_error_nodes(n->children[i]);
    return c;
}

int main(void) {
    printf("=== III Grammar Test Suite ===\n");
    printf("[group] module\n");      run_module_tests();
    printf("[group] decl\n");        run_decl_tests();
    printf("[group] type\n");        run_type_tests();
    printf("[group] stmt\n");        run_stmt_tests();
    printf("[group] expr\n");        run_expr_tests();
    printf("[group] pat\n");         run_pat_tests();
    printf("[group] modifier\n");    run_modifier_tests();
    printf("[group] canonical\n");   run_canonical_tests();
    printf("[group] errors\n");      run_errors_tests();
    printf("[group] self\n");        run_self_tests();
    printf("\n=== %d passed, %d failed ===\n", iiit_pass, iiit_fail);
    return iiit_fail == 0 ? 0 : 1;
}
