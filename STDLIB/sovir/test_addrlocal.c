#include <stdint.h>
static void inc(int *p) { *p = *p + 1; }
static int rd(int *p) { return *p; }
int main() {
    int x = 5;
    int *px = &x;                 /* &local -> x spills to memory */
    if (*px != 5) { return 1; }
    inc(&x);                      /* modify x through its address */
    if (x != 6) { return 2; }
    *px = 100;
    if (x != 100) { return 3; }
    if (rd(&x) != 100) { return 4; }
    uint8_t b = 0x80;
    uint8_t *pb = &b;
    if (*pb != 0x80) { return 5; }
    *pb = 0xFF;
    if (b != 0xFF) { return 6; }
    return 99;
}
