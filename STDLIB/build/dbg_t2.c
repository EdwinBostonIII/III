#include <stdio.h>
#include <stdint.h>
extern uint32_t t2_three_arg(uint32_t a, uint32_t b, uint32_t c);
extern uint32_t t2_three_arg_via_locals(uint32_t a, uint32_t b, uint32_t c);
static uint32_t rotr(uint32_t x, uint32_t n) { return (x>>n)|(x<<(32-n)); }
int main(void) {
    /* round-2 inputs: a=0x7C08884D, b=0x6A09E667, c=0xBB67AE85 */
    uint32_t a=0x7C08884D, b=0x6A09E667, c=0xBB67AE85;
    uint32_t S0 = rotr(a,2)^rotr(a,13)^rotr(a,22);
    uint32_t mj = (a&b)^(a&c)^(b&c);
    uint32_t t2_c = S0 + mj;
    printf("c-ref t2 = 0x%08X\n", t2_c);
    printf("iii t2_three_arg = 0x%08X\n", t2_three_arg(a, b, c));
    printf("iii t2_three_arg_via_locals = 0x%08X\n", t2_three_arg_via_locals(a, b, c));
    /* round-1 inputs: a=0x6A09E667, b=0xBB67AE85, c=0x3C6EF372 */
    uint32_t a1=0x6A09E667, b1=0xBB67AE85, c1=0x3C6EF372;
    uint32_t S0r1 = rotr(a1,2)^rotr(a1,13)^rotr(a1,22);
    uint32_t mjr1 = (a1&b1)^(a1&c1)^(b1&c1);
    uint32_t t2r1_c = S0r1 + mjr1;
    printf("\nround-1 c-ref t2 = 0x%08X\n", t2r1_c);
    printf("round-1 iii t2_three_arg = 0x%08X\n", t2_three_arg(a1, b1, c1));
    return 0;
}
