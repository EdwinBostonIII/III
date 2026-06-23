#include <stdint.h>
/* ChaCha20 block function (RFC 8439) -- an ARX stream cipher: structurally unlike SHA, exercises void quarter-round
 * mutating state by index, rotate-LEFT, 32-bit add/xor.  A SECOND real crypto primitive via ccsv -> sovereign x86. */
static uint32_t S[16];
static uint32_t O[16];
static uint32_t rotl(uint32_t x, uint32_t n) { return (x << n) | (x >> (32 - n)); }
static void qr(int a, int b, int c, int d) {
    S[a] = S[a] + S[b];  S[d] = S[d] ^ S[a];  S[d] = rotl(S[d], 16);
    S[c] = S[c] + S[d];  S[b] = S[b] ^ S[c];  S[b] = rotl(S[b], 12);
    S[a] = S[a] + S[b];  S[d] = S[d] ^ S[a];  S[d] = rotl(S[d], 8);
    S[c] = S[c] + S[d];  S[b] = S[b] ^ S[c];  S[b] = rotl(S[b], 7);
}
int main() {
    S[0]=0x61707865; S[1]=0x3320646e; S[2]=0x79622d32; S[3]=0x6b206574;    /* "expand 32-byte k" */
    S[4]=0x03020100; S[5]=0x07060504; S[6]=0x0b0a0908; S[7]=0x0f0e0d0c;    /* key */
    S[8]=0x13121110; S[9]=0x17161514; S[10]=0x1b1a1918; S[11]=0x1f1e1d1c;
    S[12]=0x00000001;                                                      /* counter */
    S[13]=0x09000000; S[14]=0x4a000000; S[15]=0x00000000;                  /* nonce */
    for (int i = 0; i < 16; i++) { O[i] = S[i]; }
    for (int r = 0; r < 10; r++) {
        qr(0,4,8,12);  qr(1,5,9,13);  qr(2,6,10,14);  qr(3,7,11,15);       /* column round */
        qr(0,5,10,15); qr(1,6,11,12); qr(2,7,8,13);   qr(3,4,9,14);        /* diagonal round */
    }
    for (int i = 0; i < 16; i++) { S[i] = S[i] + O[i]; }
    if (S[0]  != 0xe4e7f110) { return 1; }   if (S[1]  != 0x15593bd1) { return 2; }
    if (S[2]  != 0x1fdd0f50) { return 3; }   if (S[3]  != 0xc47120a3) { return 4; }
    if (S[4]  != 0xc7f4d1c7) { return 5; }   if (S[5]  != 0x0368c033) { return 6; }
    if (S[6]  != 0x9aaa2204) { return 7; }   if (S[7]  != 0x4e6cd4c3) { return 8; }
    if (S[8]  != 0x466482d2) { return 9; }   if (S[9]  != 0x09aa9f07) { return 10; }
    if (S[10] != 0x05d7c214) { return 11; }  if (S[11] != 0xa2028bd9) { return 12; }
    if (S[12] != 0xd19c12b5) { return 13; }  if (S[13] != 0xb94e16de) { return 14; }
    if (S[14] != 0xe883d0cb) { return 15; }  if (S[15] != 0x4e3c50a2) { return 16; }
    return 99;
}
