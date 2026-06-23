#include <stdint.h>
static uint8_t buf[8];
int main() {
    uint32_t x = 0x12345678;
    uint8_t b = (uint8_t)x;                       /* narrowing -> 0x78 */
    if (b != 0x78) { return 1; }
    uint32_t y = (uint32_t)x;                      /* no-op */
    if (y != 0x12345678) { return 2; }
    int v = 300;
    uint8_t w = (uint8_t)v;                        /* 300 & 0xFF = 44 */
    if (w != 44) { return 3; }
    buf[0] = 0xAB;
    uint32_t z = (uint32_t)buf[0];                 /* byte -> uint32 */
    if (z != 0xAB) { return 4; }
    uint32_t combined = ((uint32_t)buf[0] << 24);  /* ceiling.c pattern */
    if (combined != 0xAB000000) { return 5; }
    uint8_t *p = (uint8_t *)buf;                   /* pointer cast (no-op) */
    if (p[0] != 0xAB) { return 6; }
    return 99;
}
