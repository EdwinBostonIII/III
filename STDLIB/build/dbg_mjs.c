#include <stdio.h>
#include <stdint.h>
extern uint32_t r_init(void);
extern uint32_t r_run_split_mj(uint32_t n, uint32_t idx);
static uint32_t rotr(uint32_t x, uint32_t n) { return (x>>n)|(x<<(32-n)); }
int main(void) {
    uint32_t H_init[8] = {0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
                     0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19};
    uint32_t K[5] = {0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b};
    uint32_t W[64]; for (int i = 0; i < 16; i++) W[i] = 0; W[0] = 0x80000000;
    for (int i = 16; i < 64; i++) {
        uint32_t s0 = rotr(W[i-15], 7) ^ rotr(W[i-15], 18) ^ (W[i-15] >> 3);
        uint32_t s1 = rotr(W[i-2], 17) ^ rotr(W[i-2], 19) ^ (W[i-2] >> 10);
        W[i] = W[i-16] + s0 + W[i-7] + s1;
    }
    char *names = "abcdefgh";
    for (int n = 1; n <= 4; n++) {
        uint32_t reg[8] = {H_init[0],H_init[1],H_init[2],H_init[3],H_init[4],H_init[5],H_init[6],H_init[7]};
        for (int k = 0; k < n; k++) {
            uint32_t a=reg[0], b=reg[1], c=reg[2], d=reg[3], e=reg[4], f=reg[5], g=reg[6], h=reg[7];
            uint32_t S1 = rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25);
            uint32_t ch = (e & f) ^ ((~e) & g);
            uint32_t t1 = h + S1 + ch + K[k] + W[k];
            uint32_t S0 = rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22);
            uint32_t mj = (a & b) ^ (a & c) ^ (b & c);
            uint32_t t2 = S0 + mj;
            reg[7] = g; reg[6] = f; reg[5] = e; reg[4] = d + t1;
            reg[3] = c; reg[2] = b; reg[1] = a; reg[0] = t1 + t2;
        }
        printf("After %d round(s) [split-mj]:\n", n);
        int all_ok = 1;
        for (int i = 0; i < 8; i++) {
            r_init();
            uint32_t iii_v = r_run_split_mj(n, i);
            uint32_t c_v = reg[i];
            if (iii_v != c_v) { all_ok = 0; printf("  %c DIFF: iii=0x%08X  c=0x%08X\n", names[i], iii_v, c_v); }
        }
        if (all_ok) printf("  ALL OK\n");
    }
    return 0;
}
