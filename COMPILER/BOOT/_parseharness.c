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

extern void *malloc(unsigned long);
extern int fopen(const char *, const char *);
extern long fread(void *, long, long, int);
extern int fclose(int);
extern int fseek(int, long, int);
extern long ftell(int);

int main(int argc, char **argv) {
    /* Read source from argv[1] via the SEED'S EXACT read path (fopen/fseek/ftell/rewind-via-fseek/
     * fread into a malloc'd heap buffer).  If multi-char parsing fails HERE but not with a static
     * literal, the read path (fread shim / heap position) is the culprit -- else it's the 19-TU env. */
    if (argc < 2) { put_s("noarg\n"); return 2; }
    int f = fopen(argv[1], "rb");
    if (!f) { put_s("noopen\n"); return 3; }
    fseek(f, 0, 2);
    long len = ftell(f);
    fseek(f, 0, 0);
    char *src = (char *)malloc((unsigned long)len + 1);
    long got = fread(src, 1, len, f);
    fclose(f);
    src[got] = 0;
    len = got;

    /* TOKEN-STREAM DUMP: an independent lex pass over the SAME source, printing each token's
     * kind + int_value.  gcc vs interp must be IDENTICAL -- if they diverge, the bug is lex (or the
     * token struct read); if identical, it's parse-logic reading a correct token wrong. */
    {
        iii_lex_state_t *lx2 = iii_lex_create((const unsigned char *)src, len, "t.iii");
        if (lx2) {
            iii_token_t tk; int g = 0; int rc = 1;
            put_s("TOKS");
            /* iii_lex_next: 1=success(not EOF), 0=clean EOF, -1=error */
            while (g < 64) {
                rc = iii_lex_next(lx2, &tk);
                if (rc < 0) { put_s(" LERR"); break; }
                put_s(" k="); put_u((unsigned int)tk.kind);
                if (tk.int_value != 0) { put_s("v"); put_u((unsigned int)tk.int_value); }
                if (rc == 0) break;   /* EOF token emitted, stop */
                g = g + 1;
            }
            putchar('\n');
        }
    }

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
