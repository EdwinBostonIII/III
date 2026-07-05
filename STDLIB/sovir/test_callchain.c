/* test_callchain.c -- MEMBER-CHAIN reads and stores through embedded/union members, and the
 * struct-pointer element stride, at every rooting the seed uses:
 *   call()->u.a / call()->u.a = e     the seed's node accessor/constructor (iii_ast_get_mut(..)->u.break_.reserved = 0)
 *   ARR[i].u.a / ARR[i].u.a = e       global struct-array element chains (read + STORE twin)
 *   p[i].u.a  / p[i].u.a  = e         pointer-indexed element chains (read + STORE twin)
 *   p[i].k                            STRUCT-ptr element STRIDE: p[1] must advance sizeof(node_t), not the
 *                                     8-byte LPSZ default (index 0 masked it -- the classic sampled blindness)
 * Pre-fix reds this file pins: chain reads loaded 8 raw bytes at `u` + dangled `.a` (rc=8); chain stores
 * wrote 8 bytes at `u` clobbering both members (rc=2 probe); p[1] strode 8 over a 16B struct (wrong cell).
 * All four walkers (2 read + 2 store) + both stride sites now chain; single-hop emission byte-identical. */
typedef struct { int a; int b; } inner_t;
typedef struct { inner_t u; int k; } node_t;
static node_t POOL[4];
static node_t *get_mut(int i) { return &POOL[i]; }
int main(void) {
    get_mut(1)->u.a = 42;              /* call()->field.subfield = e  (call-rooted STORE, embedded hop) */
    get_mut(1)->k = 7;                 /* call()->field = e           (call-rooted STORE, single field) */
    get_mut(1)->u.b = get_mut(1)->u.a; /* call()->u.b store fed by the call()->u.a READ */
    POOL[2].u.b = 9;                   /* ARR[i].u.b = e : array-element chain STORE (must not clobber u.a) */
    POOL[2].u.a = 5;
    node_t *p = POOL;
    p[3].u.a = 11;                     /* p[i].u.a = e : pointer-indexed chain STORE at the STRUCT stride */
    p[3].k = 13;                       /* p[i].field = e : single-hop store at the STRUCT stride */
    int viaptr = p[1].u.b;             /* p[i].u.b : pointer-indexed chain READ */
    if (POOL[1].u.a == 42 && POOL[1].k == 7 && p[1].u.a == 42 && viaptr == 42
        && POOL[2].u.b == 9 && POOL[2].u.a == 5 && p[2].u.b == 9
        && POOL[3].u.a == 11 && POOL[3].k == 13) return 99;
    return 1;
}
