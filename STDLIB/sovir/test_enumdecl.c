/* test_enumdecl.c -- behavioral KAT for fix #22: an ENUM / forward-typedef-name LOCAL declaration
 * (`kind_t x = e;` / `kind_t y;`) -- the seed's `iii_abi_kind_t abi = decl->u.extern_decl.abi;`
 * (sema_check_extern_abi) construct.  ccsv registered enum MEMBERS but not the typedef NAME as a type, so the
 * local decl mis-parsed as two expr-statements -> leading-DROP underflow.  Also exercises a REGISTERED struct
 * typedef local (`box_t bx`, used with `.field`) to prove the fix does NOT disturb the struct path.  main
 * returns 99 iff every value is correct (cross-checked vs gcc + sovereign-x86 + wasm by run_ccsv's cfeat). */

typedef enum { K0 = 0, K1 = 1, K2 = 2 } kind_t;
typedef struct { int a; kind_t k; } box_t;        /* registered struct typedef (stidx>=0) -> the struct path, untouched */

int classify(box_t *b) {
    kind_t x = b->k;          /* enum-typedef LOCAL with arrow init -- the fixed construct */
    kind_t hi;                /* enum-typedef LOCAL, no init -- the `T x ;` arm */
    hi = K2;
    if (x == K1) return 1;
    if (x == hi) return 2;
    return 0;
}

int main(void) {
    box_t bx;
    bx.a = 7; bx.k = K1;
    if (classify(&bx) != 1) return 1;     /* x==K1 */
    bx.k = K2;
    if (classify(&bx) != 2) return 2;     /* x==hi(K2) */
    bx.k = K0;
    if (classify(&bx) != 0) return 3;     /* neither */
    if (bx.a != 7) return 4;              /* the registered-struct field survived */
    return 99;
}
