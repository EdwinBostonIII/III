/* Class B falsifier: STRUCT-TYPEDEF-POINTER-element local array with &-initializers
 * (grammar_mhash/parse_unregister's `iiip_reg_table_t *tables[3] = {&st->reg_decl,..};`)
 * + the hoist idiom `T *tbl = tables[t];` (grammar_mhash line 3728) with -> access
 * through the hoisted pointer.  Writes through the elements pin that the array holds
 * REAL addresses (aliasing g1/g2 observable). */
typedef struct { int a; int b; } box_t;
static box_t g1;
static box_t g2;
static box_t g3;
int main(void) {
    box_t *tables[3] = { &g1, &g2, &g3 };
    g2.a = 40;
    box_t *tbl = tables[1];
    tbl->b = 2;
    if (tbl->a != 40) { return 1; }
    if (g2.b != 2) { return 1; }
    box_t *t0 = tables[0];
    t0->a = 57;
    if (g1.a != 57) { return 1; }
    return 99;
}
