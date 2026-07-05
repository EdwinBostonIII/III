/* repro: NESTED-BRACE struct-local initializer -- the ast cluster's shape (zipper/walk_state/serialize):
 *   iii_zipper_collect_t c = { {0}, 0 };     (ast.c iii_ast_zipper_descend:2033)
 * The brace-init struct-local walker stores per-field scalars; an ARRAY field's nested { ... } brace
 * is not handled (and a nested EMBEDDED-struct brace { {1,2}, 3 } is the same class). */
typedef struct { unsigned int children[4]; unsigned int count; } collect_t;
typedef struct { int a; int b; } pair_t;
typedef struct { pair_t p; int tag; } wrap_t;
int main(void) {
    collect_t c = { {0}, 0 };            /* array-field zero sub-brace (the exact ast shape) */
    wrap_t w = { {1, 2}, 3 };            /* embedded-struct sub-brace with values */
    c.children[2] = 7; c.count = 1;
    if (c.children[0] == 0 && c.children[2] == 7 && c.count == 1
        && w.p.a == 1 && w.p.b == 2 && w.tag == 3) return 99;
    return 1;
}
