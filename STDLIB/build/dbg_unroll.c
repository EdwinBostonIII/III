#include <stdio.h>
#include <stdint.h>
extern uint32_t ru_init(void);
extern uint32_t ru_unrolled_2(uint32_t idx);
extern uint32_t ru_dbg(uint32_t idx);
static uint32_t rotr(uint32_t x, uint32_t n) { return (x>>n)|(x<<(32-n)); }
int main(void) {
    ru_init();
    uint32_t a_iii = ru_unrolled_2(0);
    /* C reference for round 2 a */
    uint32_t Hi[8] = {0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
                     0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19};
    uint32_t K[3] = {0x428a2f98, 0x71374491, 0xb5c0fbcf};
    uint32_t W[64]; for (int i = 0; i < 16; i++) W[i] = 0; W[0] = 0x80000000;
    for (int i = 16; i < 64; i++) {
        uint32_t s0 = rotr(W[i-15], 7) ^ rotr(W[i-15], 18) ^ (W[i-15] >> 3);
        uint32_t s1 = rotr(W[i-2], 17) ^ rotr(W[i-2], 19) ^ (W[i-2] >> 10);
        W[i] = W[i-16] + s0 + W[i-7] + s1;
    }
    uint32_t reg[8] = {Hi[0],Hi[1],Hi[2],Hi[3],Hi[4],Hi[5],Hi[6],Hi[7]};
    for (int k = 0; k < 2; k++) {
        uint32_t a=reg[0], b=reg[1], c=reg[2], d=reg[3], e=reg[4], f=reg[5], g=reg[6], h=reg[7];
        uint32_t S1 = rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25);
        uint32_t ch = (e & f) ^ ((~e) & g);
        uint32_t t1 = h + S1 + ch + K[k] + W[k];
        uint32_t S0 = rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22);
        uint32_t mj = (a & b) ^ (a & c) ^ (b & c);
        uint32_t t2 = S0 + mj;
        if (k == 1) {
            printf("c-ref round 1 (after r0): big_s1=0x%08X ch=0x%08X t1=0x%08X big_s0=0x%08X mj=0x%08X t2=0x%08X\n",
                S1, ch, t1, S0, mj, t2);
        }
        reg[7] = g; reg[6] = f; reg[5] = e; reg[4] = d + t1;
        reg[3] = c; reg[2] = b; reg[1] = a; reg[0] = t1 + t2;
    }
    printf("\nAfter round 0 (unrolled iii):\n");
    char *names = "abcdefgh";
    for (int i = 0; i < 8; i++) {
        printf("  %c=0x%08X\n", names[i], ru_dbg(i));
    }
    printf("\nIn round 1 (unrolled iii):\n");
    printf("  big_s1=0x%08X ch=0x%08X t1=0x%08X big_s0=0x%08X mj=0x%08X t2=0x%08X\n",
        ru_dbg(8), ru_dbg(9), ru_dbg(10), ru_dbg(11), ru_dbg(12), ru_dbg(13));
    
    printf("\nFinal a (round 2): iii=0x%08X  c=0x%08X\n", a_iii, reg[0]);
    return 0;
}
