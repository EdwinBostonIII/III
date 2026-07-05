/* fn-ptr INC-2 KAT: field-indirect calls in the seed's REAL shape -- void STATEMENT calls
 * (G_EMIT.audit_fn(...); / st->witness_sink(...);), null-checked, on ARROW (pointer) AND
 * DOT (global) bases, runtime-verified via a mutated accumulator, with add/sub index-agreement
 * teeth: correct -> ACC=12; an add/sub swap -> ACC=-12. 99 == PASS.
 * INC-3 composition tooth: the putchar forces a wasm env.putc IMPORT (IC=1), which shifts every
 * wasm func index by one -- the funcref table/elem/type indices must follow the shift or the
 * indirect calls dispatch one function off (caught at runtime by the ACC teeth). */
int putchar(int c);           /* declaration only -- gcc needs it (no implicit decls); ccsv skips prototypes and lowers putchar as its PRINT_CHAR builtin */

typedef void (*sink_t)(int v);

static int ACC;
static void add_acc(int v) { ACC += v; }
static void sub_acc(int v) { ACC -= v; }

typedef struct { sink_t s; } box_t;
static box_t G;

static void via_ptr(box_t *b, int v) { if (b->s) b->s(v); }   /* ARROW statement field-indirect call */
static void via_global(int v)        { if (G.s)  G.s(v);  }   /* DOT-on-global statement field-indirect call */

int main(void) {
    box_t b; b.s = add_acc;   /* field-store of a fn-name (struct-value local) */
    G.s = sub_acc;            /* field-store of a fn-name (global) */
    ACC = 0;
    via_ptr(&b, 10);          /* ACC += 10 -> 10 */
    via_global(3);            /* ACC -=  3 ->  7 */
    via_ptr(&b, 5);           /* ACC +=  5 -> 12 */
    putchar(107);             /* 'k' -- forces the wasm import (IC=1) alongside CALL_INDIRECT */
    if (ACC == 12) return 99;
    return 1;
}
