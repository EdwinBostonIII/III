#include <stdint.h>
#include <stdio.h>
static uint32_t addsq(uint32_t a, uint32_t b) { return a*a + b*b; }   /* static fn + uint32_t params */
int main() {
    int sum = 0;
    for (int i = 0; i < 8; i++) { sum = sum + i; }      /* for loop + ++ */
    if (sum != 28) { return 1; }                         /* 0+..+7 */
    uint32_t h = 0xDEADBEEF;                              /* hex literal + uint32_t typedef */
    if (h != 3735928559) { return 2; }
    uint32_t r = addsq(3, 4);                            /* static fn call */
    if (r != 25) { return 3; }
    int k;
    for (k = 10; k > 0; k--) { }                         /* for with -- */
    if (k != 0) { return 4; }
    return 99;
}
