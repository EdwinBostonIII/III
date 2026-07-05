/* WHOLE-MODULE behavioral de-risk for ast.c (the U78 post-zero campaign, module 2 of 6):
 * create an AST, alloc nodes across kinds, read back each node's canonical mhash --
 * exercising iii_ast_create's calloc chains, the node pools, hashcons, the canonical-bytes
 * SHA, and the (**mh_arr)[slot] pool-mhash side table.  Compiled by BOTH gcc and
 * ccsv->SVIR->interp; the hex streams must be IDENTICAL (else ast.c is
 * verify-passing-runtime-wrong).  Pure in-memory: no host-I/O paths (those trap 198
 * single-file by design). */
#include "ast.c"

static void hput(uint8_t b) {
    int hi = (b >> 4) & 0xF, lo = b & 0xF;
    putchar(hi < 10 ? ('0' + hi) : ('a' + hi - 10));
    putchar(lo < 10 ? ('0' + lo) : ('a' + lo - 10));
}
static void put32(const uint8_t *m) {
    int i = 0;
    while (i < 32) { hput(m[i]); i = i + 1; }
    putchar('\n');
}

int main(void) {
    iii_ast_t *ast = iii_ast_create(NULL, 0, NULL);
    if (!ast) { putchar('N'); putchar('\n'); return 1; }
    iii_src_pos_t pos = {0, 0, 0, 0};
    uint32_t a = iii_ast_alloc_node(ast, III_AST_EXPR_INT, &pos);
    uint32_t b = iii_ast_alloc_node(ast, III_AST_EXPR_IDENT, &pos);
    iii_src_pos_t pos2 = {7, 9, 1, 2};
    uint32_t c = iii_ast_alloc_node(ast, III_AST_EXPR_INT, &pos2);
    if (a == 0 || b == 0 || c == 0) { putchar('Z'); putchar('\n'); return 1; }
    const uint8_t *m1 = iii_ast_node_mhash(ast, a);
    const uint8_t *m2 = iii_ast_node_mhash(ast, b);
    const uint8_t *m3 = iii_ast_node_mhash(ast, c);
    if (!m1 || !m2 || !m3) { putchar('M'); putchar('\n'); return 1; }
    put32(m1);
    put32(m2);
    put32(m3);
    unsigned long n = (unsigned long)iii_ast_node_count(ast);
    putchar('0' + (int)(n % 10u));
    putchar('\n');
    return 0;
}
