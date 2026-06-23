#include <stdio.h>
#include "util.h"
int main() {
    struct Vec a;
    a.x = 3;
    a.y = 4;
    int d = vlen2(&a);                 /* 9 + 16 = 25 ; vlen2 + struct Vec come from util.h */
    if (d != 25) { return 1; }
    if (SCALE != 1000) { return 2; }   /* #define from the included header */
    return 99;
}
