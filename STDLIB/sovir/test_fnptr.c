/* fn-ptr INC-1 KAT: typedef'd fn-pointer (the seed's exact shape), fn-name-as-value (Edit B),
 * indirect call of a fn-ptr param (Edit A), AND the INDEX-SPACE-AGREEMENT teeth: add->14, sub->6;
 * a swap of add/sub's indices makes r1=6,r2=14 -> returns 1, not 99.  99 == PASS (all-4 standard). */
typedef int (*binop_t)(int, int);

static int add(int a, int b) { return a + b; }
static int sub(int a, int b) { return a - b; }

static int apply(binop_t f, int a, int b) { return f(a, b); }   /* f(a,b): indirect call of a fn-ptr PARAM (Edit A) */

int main(void) {
    binop_t g = add;                 /* g = add : fn-name-as-value (Edit B), 8-byte fn-ptr local */
    int r1 = apply(g, 10, 4);        /* -> add(10,4) = 14 */
    int r2 = apply(sub, 10, 4);      /* sub passed as a fn-name-value (Edit B) -> sub(10,4) = 6 */
    if (r1 == 14 && r2 == 6) return 99;
    return 1;
}
