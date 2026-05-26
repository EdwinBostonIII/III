#include <stdio.h>
#include <stdint.h>
extern uint32_t iso_get_k(uint32_t k);
extern uint32_t iso_setup_empty(void);
extern uint32_t iso_get_w(uint32_t idx);
int main(void) {
    printf("K[0]  = 0x%08X (expect 0x428a2f98)\n", iso_get_k(0));
    printf("K[1]  = 0x%08X (expect 0x71374491)\n", iso_get_k(1));
    printf("K[63] = 0x%08X (expect 0xc67178f2)\n", iso_get_k(63));
    iso_setup_empty();
    printf("W[0]  = 0x%08X (expect 0x80000000)\n", iso_get_w(0));
    printf("W[1]  = 0x%08X (expect 0x00000000)\n", iso_get_w(1));
    printf("W[15] = 0x%08X (expect 0x00000000)\n", iso_get_w(15));
    printf("W[16] = 0x%08X (expect 0x80000000)\n", iso_get_w(16));
    printf("W[17] = 0x%08X (expect 0x00000000)\n", iso_get_w(17));
    printf("W[18] = 0x%08X (expect 0x00205000)\n", iso_get_w(18));
    return 0;
}
