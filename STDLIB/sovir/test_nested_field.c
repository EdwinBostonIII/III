/* test_nested_field.c -- nested struct field on a struct-array element, read+store, for BOTH a pointer field
 * (p->plocals[i].name.len) and an INLINE array field (p->ilocals[i].name.len) -- the seed symbol-table idiom
 * `cg->locals[i].name.length`.  Also re-checks single-subfield on the inline base (the fe==8 LOAD64 bug). */
typedef struct { unsigned int len; unsigned int off; } text_t;
typedef struct { text_t name; unsigned int slot; } local_t;
typedef struct { local_t *plocals; local_t ilocals[8]; unsigned int count; } cg_t;
static local_t storage[8];
int main(void){
    cg_t c; c.plocals = storage;  cg_t *cg = &c;
    cg->plocals[0].name.len = 5;  cg->plocals[0].name.off = 9;  cg->plocals[1].slot = 3;   /* pointer base: nested + single */
    cg->ilocals[2].name.len = 7;  cg->ilocals[2].slot = 4;                                  /* inline base: nested + single */
    if (cg->plocals[0].name.len != 5) return 1;
    if (cg->plocals[0].name.off != 9) return 2;
    if (cg->plocals[1].slot      != 3) return 3;
    if (cg->ilocals[2].name.len  != 7) return 4;
    if (cg->ilocals[2].slot      != 4) return 5;
    return 99;
}
