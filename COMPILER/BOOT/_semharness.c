/* _semharness.c -- Lambda-0 SEMA-stage behavioral localizer (the _parseharness successor).
 * Runs the seed's exact lex -> ast -> parse -> SEMA chain on a real .iii and prints
 *   "PARSE ok=<> ec=<> nd=<>"  then  "SEMA ok=<> ec=<>".
 * gcc-built and ccsv->SVIR->interp-built outputs must be IDENTICAL.  _parseharness proved parse
 * correct in isolation but never ran sema; this harness caught the corpus-parity 12-class:
 * ccsv miscompiled `structptr + N` with stride 1 (EV_PSZ from LPSZ only; the `TypedefName *p`
 * decl arm set LPT but not LPSZ), so sema's arena `nc->base = (uint8_t*)(nc+1)` overlapped the
 * chunk header -> every intern aliased -> "duplicate declaration of 'main'" + unresolved refs =
 * SEMA ok=0 ec=4 on the seed vs ok=1 ec=0 on gcc.  Fixed in ccsv.iii (struct-typedef pointers use
 * STSZ(struct) as the arithmetic stride); falsifier STDLIB/sovir/_s4_probe15.c.
 *
 * Build (gcc reference): the parse/sema chain + its sema-side deps.
 *   gcc -I COMPILER/BOOT _semharness.c lex.c ast.c parse.c sema.c acc.c hexad_check.c sid.c proof.c
 * Sovereign side: ccsv per-TU -> svir_ld -> svir_interp, same source. */
#include <stdio.h>
#include <stdlib.h>
#include "lex.h"
#include "ast.h"
#include "parse.h"
#include "sema.h"

static void put_u(unsigned int v) {
    char buf[12]; int n = 0;
    if (v == 0) { putchar('0'); return; }
    while (v > 0) { buf[n] = (char)('0' + (v % 10)); n = n + 1; v = v / 10; }
    while (n > 0) { n = n - 1; putchar(buf[n]); }
}
static void put_s(const char *s) { int i = 0; while (s[i] != 0) { putchar(s[i]); i = i + 1; } }

int main(int argc, char **argv) {
    if (argc < 2) { put_s("noarg\n"); return 2; }
    FILE *f = fopen(argv[1], "rb");
    if (!f) { put_s("noopen\n"); return 3; }
    fseek(f, 0, 2);
    long len = ftell(f);
    fseek(f, 0, 0);
    char *src = (char *)malloc((unsigned long)len + 1);
    long got = fread(src, 1, len, f);
    fclose(f);
    src[got] = 0;
    len = got;

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

    iii_sema_state_t *sema = iii_sema_create(ast);
    if (!sema) { put_s("Snull\n"); return 1; }
    int sok = iii_sema_run(sema);
    unsigned int sec = iii_sema_error_count(sema);
    put_s("SEMA ok="); put_u((unsigned int)sok);
    put_s(" ec="); put_u(sec);
    putchar('\n');
    return (ok && sok) ? 0 : 1;
}
