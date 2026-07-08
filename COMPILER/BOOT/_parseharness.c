/* _parseharness.c -- WHOLE-MODULE behavioral de-risk for parse.c (Lambda-0 seed-sovereign frontier):
 * parse a real .iii snippet through the FULL front-end (lex -> ast -> parse) and print
 * "PARSE ok=<0|1> ec=<errcount> nd=<ndecl>".  gcc-built and ccsv->SVIR->interp-built outputs must be
 * IDENTICAL, else parse.c is verify-passing-runtime-wrong -- the exact class the interp-run linked
 * seed hit (iii_parse_module returns false on `module m`).
 *
 * Uses the PUBLIC headers (not #include of the .c) so lex/ast/parse link as SEPARATE objects -- their
 * per-TU static sha256 helpers don't collide, matching how the seed links.  gcc ref:
 *   gcc -I COMPILER/BOOT _parseharness.c lex.c ast.c parse.c
 * The sovereign side runs the SAME source through ccsv per-TU + svir_ld + interp. */
#include "lex.h"
#include "ast.h"
#include "parse.h"

int putchar(int c);

static void put_u(unsigned int v) {
    char buf[12]; int n = 0;
    if (v == 0) { putchar('0'); return; }
    while (v > 0) { buf[n] = (char)('0' + (v % 10)); n = n + 1; v = v / 10; }
    while (n > 0) { n = n - 1; putchar(buf[n]); }
}
static void put_s(const char *s) { int i = 0; while (s[i] != 0) { putchar(s[i]); i = i + 1; } }

int main(void) {
    const char *src = "module m\nfn f() -> u64 { return 7u64 }\n";
    unsigned long len = 0;
    while (src[len] != 0) len = len + 1;

    iii_lex_state_t *lex = iii_lex_create((const unsigned char *)src, len, "t.iii");
    if (!lex) { put_s("Lnull\n"); return 1; }
    iii_ast_t *ast = iii_ast_create((const unsigned char *)src, len, "t.iii");
    if (!ast) { put_s("Anull\n"); return 1; }
    iii_parse_state_t *p = iii_parse_create(lex, ast);
    if (!p) { put_s("Pnull\n"); return 1; }

    int ok = iii_parse_module(p);
    unsigned int ec = iii_parse_error_count(p);
    unsigned int nd = 0;
    const iii_ast_node_t *mod = iii_ast_get(ast, iii_ast_root_module(ast));
    if (mod) nd = mod->u.module_.decls.count;

    put_s("PARSE ok="); put_u((unsigned int)ok);
    put_s(" ec="); put_u(ec);
    put_s(" nd="); put_u(nd);
    putchar('\n');
    /* dump each error: code/line/col/saw_kind -- pinpoints what parse.c rejected */
    unsigned int ei = 0;
    while (ei < ec) {
        iii_parse_error_t e;
        iii_parse_error_at(p, ei, &e);
        put_s("  err["); put_u(ei); put_s("] code="); put_u((unsigned int)e.code);
        put_s(" line="); put_u(e.line); put_s(" col="); put_u(e.col);
        put_s(" saw="); put_u((unsigned int)e.saw_kind);
        putchar('\n');
        ei = ei + 1;
    }
    return 0;
}
