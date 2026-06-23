#include <stdint.h>
static int mx(int a, int b) { return a > b ? a : b; }
int main() {
    int x = mx(3, 7);  if (x != 7) { return 1; }
    int y = mx(9, 2);  if (y != 9) { return 2; }
    int z = (x > y) ? 100 : 200;  if (z != 200) { return 3; }          /* 7>9 false -> 200 */
    int w = 5;
    int r = w == 5 ? (w > 3 ? 11 : 22) : 33;  if (r != 11) { return 4; } /* nested */
    int sgn = w > 0 ? 1 : (w < 0 ? 2 : 0);  if (sgn != 1) { return 5; }  /* right-assoc chain */
    uint32_t m = 0xFF; uint32_t v = (m & 0x10) ? 0xAAAA : 0xBBBB; if (v != 0xAAAA) { return 6; }
    return 99;
}
