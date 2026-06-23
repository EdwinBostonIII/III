#include <stdint.h>
static uint32_t rotr(uint32_t x, uint32_t n) { return (x >> n) | (x << (32 - n)); }
int main() {
    uint32_t x = 305419896;            /* 0x12345678 */
    uint32_t r = rotr(x, 8);           /* 32-bit rotate -> masked at the store */
    if (r != 2014458966) { return 1; } /* 0x78123456 */
    uint32_t y = 0;
    y = y - 1;                         /* unsigned underflow wrap -> 0xFFFFFFFF */
    if (y != 4294967295) { return 2; }
    uint32_t z = 4294967295;
    z = z + 1;                         /* unsigned overflow wrap -> 0 */
    if (z != 0) { return 3; }
    return 99;
}
