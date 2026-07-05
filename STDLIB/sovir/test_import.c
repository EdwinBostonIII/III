/* IMPORTS (0x8A) POSITIVE arm: the module CONTAINS imports -- ext_pick (scalar), ext_peek
 * (struct-by-value sret, the census's iii_token_t-from-extern shape), and call()[i] on an
 * import -- but NO import call ever EXECUTES (guarded dead).  The module must BUILD and RUN
 * normally on every sovereign executor: verify=0-fail, interp=99, x86=99, wasm=99.
 * gcc has NO arm here: it cannot LINK a referenced-undefined extern single-file (same
 * documented reason as test_externtable.c).  The name 'seq_probe_q' is deliberate scanner
 * teeth: 'q'(0x71)/'s'(0x73) bytes in the import NAME must not read as PRINT_CHAR /
 * CALL_INDIRECT in any body walker (the phantom-IC / phantom-type class). */
typedef struct { long a; long b; } pair_t;   /* 16B: forces the sret path */
int seq_probe_q(int a, int b);
pair_t ext_peek(int i);
const unsigned char *ext_src(int i);
static long use(int x) {
    if (x > 0) { return 99; }
    int r = seq_probe_q(x, 7);          /* scalar import call */
    pair_t t = ext_peek(x);             /* sret-from-import: T x = ext() dest-first */
    long d = ext_peek(x).b;             /* import().field through the sret temp buffer */
    unsigned char c = ext_src(x)[3];    /* call()[i] on an import (the cg_r3 shape) */
    return r + t.a + d + (long)c;
}
int main(void) { return (int)use(5); }
