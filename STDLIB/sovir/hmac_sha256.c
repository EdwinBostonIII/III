#include <stdint.h>
/* HMAC-SHA256 (RFC 2104) -- a real keyed MAC composing the sovereign SHA-256.  Proves the SHA is REUSABLE and that
 * ccsv handles true byte buffers (uint8_t arrays + uint8_t* params, stride-1) flowing through functions. */
static const uint32_t K[64] = {
  0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
  0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
  0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
  0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
  0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
  0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
  0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
  0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2 };
static uint32_t H[8];
static uint8_t BUF[256];
static uint32_t W[64];
static uint32_t rotr(uint32_t x, uint32_t n) { return (x >> n) | (x << (32 - n)); }
static void sha256(uint8_t *msg, int len) {
    H[0]=0x6a09e667; H[1]=0xbb67ae85; H[2]=0x3c6ef372; H[3]=0xa54ff53a;
    H[4]=0x510e527f; H[5]=0x9b05688c; H[6]=0x1f83d9ab; H[7]=0x5be0cd19;
    int i;
    for (i = 0; i < len; i++) { BUF[i] = msg[i]; }
    BUF[len] = 0x80;
    int padded = len + 9;  int rem = padded % 64;  if (rem != 0) { padded = padded + 64 - rem; }
    for (i = len + 1; i < padded; i++) { BUF[i] = 0; }
    int bits = len * 8;
    BUF[padded-1] = bits & 255; BUF[padded-2] = (bits >> 8) & 255;
    BUF[padded-3] = (bits >> 16) & 255; BUF[padded-4] = (bits >> 24) & 255;
    int nblk = padded / 64;
    for (int blk = 0; blk < nblk; blk++) {
        int bs = blk * 64;
        for (int t = 0; t < 16; t++) {
            int o = bs + t*4;
            uint32_t b0 = BUF[o]; uint32_t b1 = BUF[o+1]; uint32_t b2 = BUF[o+2]; uint32_t b3 = BUF[o+3];
            W[t] = (b0 << 24) | (b1 << 16) | (b2 << 8) | b3;
        }
        for (int t = 16; t < 64; t++) {
            uint32_t x = W[t-15];  uint32_t s0 = rotr(x,7) ^ rotr(x,18) ^ (x >> 3);
            uint32_t y = W[t-2];   uint32_t s1 = rotr(y,17) ^ rotr(y,19) ^ (y >> 10);
            W[t] = W[t-16] + s0 + W[t-7] + s1;
        }
        uint32_t a=H[0]; uint32_t b=H[1]; uint32_t c=H[2]; uint32_t d=H[3];
        uint32_t e=H[4]; uint32_t f=H[5]; uint32_t g=H[6]; uint32_t hh=H[7];
        for (int t = 0; t < 64; t++) {
            uint32_t S1 = rotr(e,6) ^ rotr(e,11) ^ rotr(e,25);
            uint32_t ch = (e & f) ^ ((~e) & g);
            uint32_t t1 = hh + S1 + ch + K[t] + W[t];
            uint32_t S0 = rotr(a,2) ^ rotr(a,13) ^ rotr(a,22);
            uint32_t maj = (a & b) ^ (a & c) ^ (b & c);
            uint32_t t2 = S0 + maj;
            hh=g; g=f; f=e; e=d+t1; d=c; c=b; b=a; a=t1+t2;
        }
        H[0]=H[0]+a; H[1]=H[1]+b; H[2]=H[2]+c; H[3]=H[3]+d;
        H[4]=H[4]+e; H[5]=H[5]+f; H[6]=H[6]+g; H[7]=H[7]+hh;
    }
}
static uint8_t KEY[64];
static uint8_t INNER[256];
static uint8_t OUTER[96];
static uint8_t DIG[32];
static void hmac(uint8_t *key, int klen, uint8_t *msg, int mlen) {
    int i;
    for (i = 0; i < 64; i++) { KEY[i] = 0; }
    for (i = 0; i < klen; i++) { KEY[i] = key[i]; }
    for (i = 0; i < 64; i++) { INNER[i] = KEY[i] ^ 0x36; }
    for (i = 0; i < mlen; i++) { INNER[64+i] = msg[i]; }
    sha256(INNER, 64 + mlen);
    for (i = 0; i < 8; i++) {
        DIG[i*4] = (H[i] >> 24) & 255; DIG[i*4+1] = (H[i] >> 16) & 255;
        DIG[i*4+2] = (H[i] >> 8) & 255; DIG[i*4+3] = H[i] & 255;
    }
    for (i = 0; i < 64; i++) { OUTER[i] = KEY[i] ^ 0x5c; }
    for (i = 0; i < 32; i++) { OUTER[64+i] = DIG[i]; }
    sha256(OUTER, 96);
}
int main() {
    hmac("Jefe", 4, "what do ya want for nothing?", 28);     /* RFC 4231 test case 2 */
    if (H[0] != 0x5bdcc146) { return 1; }  if (H[1] != 0xbf60754e) { return 2; }
    if (H[2] != 0x6a042426) { return 3; }  if (H[3] != 0x089575c7) { return 4; }
    if (H[4] != 0x5a003f08) { return 5; }  if (H[5] != 0x9d273983) { return 6; }
    if (H[6] != 0x9dec58b9) { return 7; }  if (H[7] != 0x64ec3843) { return 8; }
    return 99;
}
