#include <stdio.h>
#define MAX 1000
#define BASE 7
enum Color { RED, GREEN, BLUE };
enum { TEN = 10, ELEVEN, TWELVE };
typedef struct { int v; int w; } Pair;
Pair gpair;
int main() {
    Pair *pp;
    pp = &gpair;                    /* typedef pointer */
    pp->v = MAX;                    /* #define MAX */
    pp->w = BASE + TEN;             /* #define BASE + enum TEN */
    if (pp->v != 1000) { return 1; }
    if (pp->w != 17) { return 2; }  /* 7 + 10 */
    if (RED != 0) { return 3; }
    if (BLUE != 2) { return 4; }
    if (TWELVE != 12) { return 5; } /* 10, 11, 12 */
    return 99;
}
