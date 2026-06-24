#include <stdint.h>
/* ccsv SEED-DDC : forward goto (the seed's dominant `goto fail` cleanup form, 53x in ast.c). */
static int alloc_chain(int a, int b, int c) {
    int acq = 0;
    if (a == 0) goto fail;
    acq = acq + 1;
    if (b == 0) goto fail;
    acq = acq + 10;
    if (c == 0) goto fail;
    acq = acq + 100;
    return acq;
fail:
    return 0 - acq;
}
static int multi(int x) {                 /* multiple forward labels + goto */
    int r = 0;
    if (x == 1) goto one;
    if (x == 2) goto two;
    r = 100;  goto done;
one:
    r = 1;  goto done;
two:
    r = 2;
done:
    return r;
}
int main() {
    if (alloc_chain(1, 1, 1) != 111) { return 1; }
    if (alloc_chain(0, 1, 1) != 0) { return 2; }
    if (alloc_chain(1, 0, 1) != (0 - 1)) { return 3; }
    if (alloc_chain(1, 1, 0) != (0 - 11)) { return 4; }
    if (multi(1) != 1) { return 5; }
    if (multi(2) != 2) { return 6; }
    if (multi(7) != 100) { return 7; }
    return 99;
}
