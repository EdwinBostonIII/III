/* WHOLE-MODULE behavioral de-risk for lex.c (advisor + COMPLETION-PLAN milestone):
 * tokenize a real .iii snippet through the FULL lexer and print the stream-mhash (SHA-256 of
 * the canonical token stream).  Compiled by BOTH gcc and ccsv->SVIR->interp; the two hex outputs
 * must be IDENTICAL, else lex.c is verify-passing-runtime-wrong (a module-level bug the per-fn
 * structural floor cannot see).  lex.c is non-recursive + at structural-zero = the cheapest probe. */
#include "lex.c"

static void put_hex(uint8_t b) {
    int hi = (b >> 4) & 0xF, lo = b & 0xF;
    putchar(hi < 10 ? ('0' + hi) : ('a' + hi - 10));
    putchar(lo < 10 ? ('0' + lo) : ('a' + lo - 10));
}

int main(void) {
    const char *src = "fn main() -> u64 { return 42u64 }";
    size_t n = 0;
    while (src[n] != 0) n = n + 1;
    iii_lex_state_t *st = iii_lex_create((const uint8_t *)src, n, "t.iii");
    if (!st) { putchar('N'); putchar('\n'); return 1; }
    iii_token_t tok;
    int guard = 0;
    int rc = 0;
    do {
        rc = iii_lex_next(st, &tok);
        if (rc != 0) break;
        guard = guard + 1;
    } while (tok.kind != III_TOK_EOF && guard < 1000);
    uint8_t mh[32];
    iii_lex_stream_mhash(st, mh);
    int i = 0;
    while (i < 32) { put_hex(mh[i]); i = i + 1; }
    putchar('\n');
    return 0;
}
