#include <stdint.h>
int main() {
    int x = 10;
    x += 5;  if (x != 15) { return 1; }
    x -= 3;  if (x != 12) { return 2; }
    x *= 2;  if (x != 24) { return 3; }
    uint32_t m = 0xF0;
    m |= 0x0F;  if (m != 0xFF) { return 4; }
    m &= 0xF0;  if (m != 0xF0) { return 5; }
    m ^= 0xFF;  if (m != 0x0F) { return 6; }
    uint32_t s = 1;
    s <<= 4;  if (s != 16) { return 7; }
    s >>= 2;  if (s != 4) { return 8; }
    uint32_t w = 0xFFFFFFFF;
    w += 1;  if (w != 0) { return 9; }              /* width mask via emit_lset -> wraps to 0 */
    return 99;
}
