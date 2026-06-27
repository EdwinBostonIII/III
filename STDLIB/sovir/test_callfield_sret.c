/* test_callfield_sret.c -- behavioral KAT for fix #21: a function returning a struct BY VALUE (sret, >8B)
 * immediately followed by `.field` (DOT).  The callee must write its struct to the hidden dest buffer the
 * caller supplies; the caller then loads .field from it.  main returns 99 iff every extracted field value is
 * correct (cross-checked vs gcc + sovereign-x86 + wasm by run_ccsv's cfeat). */

typedef struct { int a; int b; int c; } pos_t;            /* 12 bytes (real C, int=4) -> sret */
typedef struct { int lo; int hi; int mid; int top; } quad_t;  /* 16 bytes -> sret */

pos_t  mkpos(int x)  { pos_t p;  p.a = x;       p.b = x + 10;  p.c = x * 2;             return p; }
quad_t mkquad(int x) { quad_t q; q.lo = x;      q.hi = x + 100; q.mid = x + 50; q.top = x + 200; return q; }

int main(void) {
    int b   = mkpos(3).b;                 /* 3 + 10  = 13  */
    int c   = mkpos(5).c;                 /* 5 * 2   = 10  */
    int hi  = mkquad(7).hi;               /* 7 + 100 = 107 */
    int sum = mkpos(2).a + mkquad(1).top; /* 2 + 201 = 203 (sret .field inside a larger expression) */

    if (b   != 13)  return 1;
    if (c   != 10)  return 2;
    if (hi  != 107) return 3;
    if (sum != 203) return 4;
    return 99;
}
