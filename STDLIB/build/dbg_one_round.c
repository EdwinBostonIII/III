#include <stdio.h>
#include <stdint.h>
extern uint32_t round_one_t1(uint32_t h, uint32_t e, uint32_t f, uint32_t g, uint32_t k, uint32_t w);
extern uint32_t round_one_t2(uint32_t a, uint32_t b, uint32_t c);

static uint32_t rotr(uint32_t x, uint32_t n) { return (x >> n) | (x << (32 - n)); }

int main(void) {
    uint32_t a=0x6a09e667, b=0xbb67ae85, c=0x3c6ef372, d=0xa54ff53a;
    uint32_t e=0x510e527f, f=0x9b05688c, g=0x1f83d9ab, h=0x5be0cd19;
    uint32_t K0 = 0x428a2f98, W0 = 0x80000000;
    /* C reference */
    uint32_t s1 = rotr(e,6)^rotr(e,11)^rotr(e,25);
    uint32_t ch = (e&f)^((~e)&g);
    uint32_t t1c = h + s1 + ch + K0 + W0;
    uint32_t s0 = rotr(a,2)^rotr(a,13)^rotr(a,22);
    uint32_t mj = (a&b)^(a&c)^(b&c);
    uint32_t t2c = s0 + mj;
    /* iii */
    uint32_t t1i = round_one_t1(h, e, f, g, K0, W0);
    uint32_t t2i = round_one_t2(a, b, c);
    printf("t1: iii=0x%08X  c-ref=0x%08X  diff=0x%08X\n", t1i, t1c, t1i ^ t1c);
    printf("t2: iii=0x%08X  c-ref=0x%08X  diff=0x%08X\n", t2i, t2c, t2i ^ t2c);
    return 0;
}
