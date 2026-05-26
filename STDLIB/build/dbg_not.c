#include <stdio.h>
#include <stdint.h>
extern uint32_t test_not(uint32_t x);
extern uint32_t test_not_and(uint32_t x, uint32_t y);
extern uint32_t test_complex_and(uint32_t e, uint32_t f, uint32_t g);
int main(void) {
    printf("~0x510e527f = 0x%08X (expect 0xAEF1AD80)\n", test_not(0x510e527f));
    printf("(~0x510e527f) & 0x1f83d9ab = 0x%08X (expect 0x%08X)\n", 
        test_not_and(0x510e527f, 0x1f83d9ab),
        (~0x510e527f) & 0x1f83d9ab);
    /* SHA Ch(e,f,g) for e=0x510e527f f=0x9b05688c g=0x1f83d9ab */
    uint32_t e=0x510e527f, f=0x9b05688c, g=0x1f83d9ab;
    uint32_t expected = (e & f) ^ ((~e) & g);
    printf("Ch(e,f,g) = 0x%08X (expect 0x%08X)\n", test_complex_and(e,f,g), expected);
    return 0;
}
