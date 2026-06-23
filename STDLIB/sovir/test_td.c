#include <stdio.h>
typedef struct { int x; int y; } Point;
union Box { int i; int j; };
struct Node { int v; int w; };
Point gp;
union Box gb;
struct Node gn;
int main() {
    gp.x = 100000;                 /* typedef struct field store */
    gp.y = 200000;
    gb.i = 777;                    /* union field store (i and j overlap at offset 0) */
    struct Node *pn;
    pn = &gn;                      /* pointer to a struct */
    pn->v = 42;                    /* p->f store */
    pn->w = 99;
    if (gp.x != 100000) { return 1; }
    if (gp.y != 200000) { return 2; }
    if (gb.j != 777) { return 3; } /* union: j reads i's value */
    if (pn->v != 42) { return 4; } /* p->f load */
    if (gn.w != 99) { return 5; }  /* pn->w wrote into gn.w */
    return 99;
}
