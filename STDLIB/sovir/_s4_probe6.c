#include <stdlib.h>
/* probe6.c -- the FULL ast.c list_push sequence: realloc-from-NULL, grow twice (4->8->16),
 * then read back every slot.  gcc oracle 99.  30=push fail; 40+i = slot i corrupted. */
typedef struct { unsigned int *arena; unsigned int used; unsigned int cap; } A;
static A g;

static unsigned int grow_cap(unsigned int cap, unsigned int need) {
    unsigned int c = cap ? cap : 4;
    while (c < need) c = c * 2;
    return c;
}

static int push(A *ast, unsigned int v) {
    if (ast->used == ast->cap) {
        unsigned int nc = grow_cap(ast->cap, ast->cap + 1);
        unsigned int *p = (unsigned int *)realloc(ast->arena, (size_t)nc * sizeof(unsigned int));
        if (!p) return 0;
        ast->arena = p;
        ast->cap = nc;
    }
    ast->arena[ast->used++] = v;
    return 1;
}

int main(void) {
    unsigned int i;
    unsigned int r;
    unsigned int *a;
    for (i = 0; i < 9; i++) { if (!push(&g, 0x30000000u + i)) return 30; }
    a = g.arena;   /* read back through a LOCAL pointer (the dot-global indexed read is a SEPARATE known ccsv defect, pinned by probe4b) */
    for (i = 0; i < 9; i++) { r = a[i]; if (r != 0x30000000u + i) return (int)(40 + i); }
    return 99;
}
