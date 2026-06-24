#include <stdint.h>
/* ccsv SEED-DDC : do { body } while (cond) -- body-first loop (BLOCK LOOP body cond BR_IF 0), break via BRKT. */
int main() {
    int i = 0;  int sum = 0;
    do { sum = sum + i; i = i + 1; } while (i < 5);          /* 0+1+2+3+4 = 10 */
    if (sum != 10) { return 1; }
    int x = 0;
    do { x = x + 7; } while (0);                              /* runs once even if cond false */
    if (x != 7) { return 2; }
    int y = 0;
    do { y = y + 1; if (y == 3) { break; } } while (1);       /* break exits the do-while */
    if (y != 3) { return 3; }
    int z = 0;  int j = 0;
    do { int k = 0; do { z = z + 1; k = k + 1; } while (k < 2); j = j + 1; } while (j < 3);  /* 3*2 = 6 (nested) */
    if (z != 6) { return 4; }
    return 99;
}
