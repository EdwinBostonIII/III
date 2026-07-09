/* probe5.c -- the EXACT ast.c:1409 list_at READ shape: `ast->arena[list.offset + i]` -- pointer-
 * FIELD (at a NONZERO struct offset) indexed by an expression, through a param pointer, with a
 * by-value struct param supplying the index.  gcc oracle 99.  33 = wrong value read. */
typedef struct { unsigned int offset; unsigned int count; } L;
typedef struct { unsigned int f0; unsigned int f1; unsigned int *arena; unsigned int used; } A;
static unsigned int BUF[8];
static A g;

static unsigned int list_at(A *ast, L list, unsigned int i) {
    if (i >= list.count) return 0;
    return ast->arena[list.offset + i];
}

int main(void) {
    L l;
    unsigned int r;
    g.f0 = 7; g.f1 = 9; g.arena = BUF; g.used = 2;
    BUF[1] = 0x30000004u;
    l.offset = 1; l.count = 1;
    r = list_at(&g, l, 0);
    if (r == 0x30000004u) return 99;
    return 33;
}
