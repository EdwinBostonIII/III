#include <stdint.h>
/* P1 ABI PROOF (III-VERIFIABLE-ROOT-ARCHITECTURE Claim 1, "typed memory"): ccsv and gcc must agree on sizeof,
 * field offsets, and the EXACT BYTES of a serialized mixed-width struct -- a TRUE differential (not the old
 * size-agnostic ratio idiom), impossible while ccsv's storage model was i64-everything.  Also the only test that
 * exercises STORE16 + signed LOAD16_S / LOAD32_S. */
struct S { uint8_t a; uint32_t b; uint16_t c; uint64_t d; uint8_t e; };
int main() {
    if (sizeof(uint8_t)  != 1) { return 1; }
    if (sizeof(uint16_t) != 2) { return 2; }
    if (sizeof(uint32_t) != 4) { return 3; }
    if (sizeof(uint64_t) != 8) { return 4; }
    if (sizeof(int)      != 4) { return 5; }
    if (sizeof(char)     != 1) { return 6; }
    if (sizeof(struct S) != 32) { return 7; }       /* a@0 b@4 c@8 d@16 e@24, struct align 8 -> pad to 32 */

    struct S s;
    uint8_t *p = (uint8_t *)&s;
    int n = sizeof(struct S);
    for (int i = 0; i < n; i++) { p[i] = 0; }        /* zero, including padding */
    s.a = 0x11;
    s.b = 0x22334455;
    s.c = 0x6677;
    s.d = 0x8899aabbccddeeff;
    s.e = 0xa5;
    /* each field landed at its C-standard offset in little-endian order (the bytes-match-gcc proof) */
    if (p[0]  != 0x11) { return 10; }
    if (p[4]  != 0x55) { return 11; }   if (p[7]  != 0x22) { return 12; }   /* b @ 4..7 LE */
    if (p[8]  != 0x77) { return 13; }   if (p[9]  != 0x66) { return 14; }   /* c @ 8..9 LE */
    if (p[16] != 0xff) { return 15; }   if (p[23] != 0x88) { return 16; }   /* d @ 16..23 LE */
    if (p[24] != 0xa5) { return 17; }                                       /* e @ 24 */
    /* padding bytes must be zero -> offsets are exactly C's (no field overlap / wrong stride) */
    if (p[1]  != 0) { return 18; }   if (p[3]  != 0) { return 19; }         /* pad after a */
    if (p[10] != 0) { return 20; }   if (p[15] != 0) { return 21; }         /* pad after c */
    if (p[25] != 0) { return 22; }   if (p[31] != 0) { return 23; }         /* pad after e */

    /* signed narrowing round-trip: STORE16/STORE32 then signed reload preserves negatives */
    int16_t sa[2];  int neg = 0 - 1000;
    sa[0] = neg;  sa[1] = 30000;
    if (sa[0] != neg)   { return 30; }               /* LOAD16_S sign-extends 0xFC18 -> -1000 */
    if (sa[1] != 30000) { return 31; }
    int32_t la[2];  int big = 0 - 2000000000;
    la[0] = big;  la[1] = 2000000000;
    if (la[0] != big)        { return 32; }          /* LOAD32_S sign-extends -> -2000000000 */
    if (la[1] != 2000000000) { return 33; }

    return 99;
}
