#include <stdio.h>
#include <stdint.h>
extern uint32_t my_rotr(uint32_t x, uint32_t n);
int main(void) {
    /* expected: 0x9DA82799 for ROTR(0x6A09E667, 6) */
    uint32_t r = my_rotr(0x6A09E667u, 6u);
    printf("rotr(0x6A09E667, 6) = 0x%08X (expected 0x9DA82799)\n", r);
    /* expected: 0xFFFFFF for shift==0 special case (both branches contribute) */
    /* for n==0, (32-0)==32, x << 32 is undefined in C; in iii it's also undefined */
    uint32_t r2 = my_rotr(0xFFFFFFFFu, 1u);
    printf("rotr(0xFFFFFFFF, 1) = 0x%08X (expected 0xFFFFFFFF)\n", r2);
    uint32_t r3 = my_rotr(0xFFu, 4u);
    printf("rotr(0xFF, 4) = 0x%08X (expected 0xF000000F)\n", r3);
    return 0;
}
