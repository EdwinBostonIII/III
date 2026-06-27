/* test_sizeoffield.c -- behavioral gate for sizeof(p->arrayfield): the seed's token-init idiom
 * `memset(out->mhash, 0, sizeof(out->mhash))` (iii_emit_single/double/lex_create).  Verifies BOTH the
 * structural fix (no dangling-token DROP) AND the correct size (all 32 bytes cleared, not 1/8). */
#include <string.h>
typedef struct { int kind; unsigned char mhash[32]; int len; } tok_t;
static void clr(tok_t *o) {
    o->kind = 5;
    memset(o->mhash, 0, sizeof(o->mhash));
    o->len = 0;
}
int main(void) {
    tok_t t;
    int i;
    for (i = 0; i < 32; i++) t.mhash[i] = 9;
    t.kind = 1; t.len = 1;
    clr(&t);
    if (t.kind != 5) return 1;
    for (i = 0; i < 32; i++) { if (t.mhash[i] != 0) return 2; }   /* all 32 cleared => size was 32 */
    if (t.len != 0) return 3;
    return 99;
}
