#include <stdint.h>
/* ccsv SEED-DDC : switch/case/default/break + fall-through, lowered to a nested-BLOCK ladder (no new SVIR ISA).
 * Exercises every switch semantic the seed (ast.c/cg_r3.c/parse.c) relies on. */
static int classify(int x) {
    int r = 0;
    switch (x) {
        case 1: r = 10; break;
        case 2: r = 20; break;
        case 3:                          /* fall-through: 3 and 4 share a body */
        case 4: r = 34; break;
        case 5:
            if (x == 5) { r = 50; }      /* break INSIDE a nested if (variable structured-control depth) */
            break;
        default: r = 99; break;
    }
    return r;
}
static int ch(char c) {
    switch (c) {                          /* char-literal cases + return-in-case (no break) */
        case 'a': return 1;
        case 'b': return 2;
        default: return 0;
    }
}
int main() {
    if (classify(1) != 10) { return 1; }
    if (classify(2) != 20) { return 2; }
    if (classify(3) != 34) { return 3; }  /* fall-through 3 -> 4 */
    if (classify(4) != 34) { return 4; }
    if (classify(5) != 50) { return 5; }  /* break inside the if */
    if (classify(7) != 99) { return 6; }  /* default */
    if (ch('a') != 1) { return 7; }
    if (ch('b') != 2) { return 8; }
    if (ch('z') != 0) { return 9; }       /* default */

    int acc = 0;                          /* fall-through accumulation INTO default */
    switch (2) {
        case 1: acc = acc + 1;            /* skipped */
        case 2: acc = acc + 2;            /* enters here, no break */
        case 3: acc = acc + 3;            /* falls through */
        default: acc = acc + 100;         /* falls through into default */
    }
    if (acc != 105) { return 10; }        /* 2 + 3 + 100 */

    int sum = 0;                          /* switch INSIDE a loop: break exits the switch, NOT the loop */
    for (int i = 0; i < 4; i++) {
        switch (i) {
            case 0: sum = sum + 1; break;
            case 2: sum = sum + 10; break;
            default: sum = sum + 100; break;
        }
    }
    if (sum != 211) { return 11; }        /* i=0:+1, i=1:+100, i=2:+10, i=3:+100 */
    return 99;
}
