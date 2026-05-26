#include <stdio.h>
#include <stdint.h>
extern uint32_t p_init_state(void);
extern uint32_t p_run_n_rounds(uint32_t n);

static uint32_t rotr(uint32_t x, uint32_t n) { return (x>>n) | (x<<(32-n)); }

int main(void) {
    /* C reference: known values for 'a' after each round on empty SHA-256 */
    /* Round 0: t1 = 0x7377ED68, t2 = 0x08909AE5, a_new = t1+t2 = 0x7C08884D */
    /* Let me compute it via C */
    uint32_t H[8] = {0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
                     0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19};
    uint32_t K[5] = {0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b};
    uint32_t W[64];
    /* Empty padded block schedule */
    for (int i = 0; i < 16; i++) W[i] = 0;
    W[0] = 0x80000000;
    for (int i = 16; i < 64; i++) {
        uint32_t s0 = rotr(W[i-15], 7) ^ rotr(W[i-15], 18) ^ (W[i-15] >> 3);
        uint32_t s1 = rotr(W[i-2], 17) ^ rotr(W[i-2], 19) ^ (W[i-2] >> 10);
        W[i] = W[i-16] + s0 + W[i-7] + s1;
    }
    uint32_t a=H[0], b=H[1], c=H[2], d=H[3], e=H[4], f=H[5], g=H[6], h=H[7];
    for (int n = 1; n <= 4; n++) {
        /* run n rounds in C */
        uint32_t la=H[0], lb=H[1], lc=H[2], ld=H[3], le=H[4], lf=H[5], lg=H[6], lh=H[7];
        for (int k = 0; k < n; k++) {
            uint32_t S1 = rotr(le, 6) ^ rotr(le, 11) ^ rotr(le, 25);
            uint32_t ch = (le & lf) ^ ((~le) & lg);
            uint32_t t1 = lh + S1 + ch + K[k] + W[k];
            uint32_t S0 = rotr(la, 2) ^ rotr(la, 13) ^ rotr(la, 22);
            uint32_t mj = (la & lb) ^ (la & lc) ^ (lb & lc);
            uint32_t t2 = S0 + mj;
            lh = lg; lg = lf; lf = le; le = ld + t1;
            ld = lc; lc = lb; lb = la; la = t1 + t2;
        }
        p_init_state();
        uint32_t iii_a = p_run_n_rounds(n);
        printf("n=%d: iii_a=0x%08X  c_a=0x%08X  %s\n", n, iii_a, la, iii_a == la ? "OK" : "DIFF");
    }
    return 0;
}
