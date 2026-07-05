/* &p->embedded.ptrfield[i] falsifier (sema_aggregate_dynamic_impact's
 * `const sema_cycle_anno_t *a = &s->annos.items[i];`): address-of an indexed POINTER
 * field reached through an EMBEDDED-struct hop.  The &-chain walker summed offsets and
 * returned at the final field (address of the FIELD, not the element) leaving `[i]`
 * unconsumed -> desync (rc=8).  Correct: LOAD64(p+acc) + i*STSZ(pointee).
 * Distinct values at distinct indices pin the deref + stride. */
typedef struct { long v; int w; } anno_t;
typedef struct { anno_t *items; long count; } list_t;
typedef struct { long pad; list_t annos; } state_t;
static anno_t POOL[3];
static state_t s;
int main(void) {
    s.annos.items = POOL;
    s.annos.count = 3;
    state_t *p = &s;
    POOL[2].v = 41;
    const anno_t *a = &p->annos.items[2];
    if (a->v != 41) { return 1; }
    POOL[0].w = 9;
    const anno_t *b = &p->annos.items[0];
    if (b->w != 9) { return 1; }
    return 99;
}
