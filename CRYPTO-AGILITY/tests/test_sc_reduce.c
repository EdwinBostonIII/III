/* sc_reduce focused test. */
#include <stdio.h>
#include <stdint.h>
#include <string.h>

extern void iii_ed25519_sc_reduce(uint8_t out[32], const uint8_t in[64]);

static void hex_print(const char *label, const uint8_t *b, size_t n) {
    printf("%s: ", label);
    for (size_t i = 0; i < n; ++i) printf("%02x", b[i]);
    printf("\n");
}

int main(void) {
    /* L = 2^252 + 27742317777372353535851937790883648493 */
    static const uint8_t L_bytes[32] = {
        0xed, 0xd3, 0xf5, 0x5c, 0x1a, 0x63, 0x12, 0x58,
        0xd6, 0x9c, 0xf7, 0xa2, 0xde, 0xf9, 0xde, 0x14,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x10
    };

    /* Test 1: input = L, padded to 64 bytes.  Expected output = 0. */
    uint8_t in[64] = {0};
    memcpy(in, L_bytes, 32);
    uint8_t out[32];
    iii_ed25519_sc_reduce(out, in);
    int ok1 = 1; for (int i = 0; i < 32; ++i) if (out[i]) ok1 = 0;
    hex_print("L mod L = ", out, 32);
    printf("  expected all zeros => %s\n\n", ok1 ? "OK" : "FAIL");

    /* Test 2: input = L + 5, padded.  Expected output = 5. */
    memset(in, 0, 64);
    memcpy(in, L_bytes, 32);
    /* Add 5 to byte 0. */
    unsigned carry = 5;
    for (int i = 0; i < 64 && carry; ++i) {
        unsigned s = (unsigned)in[i] + carry;
        in[i] = (uint8_t)(s & 0xFFu);
        carry = s >> 8;
    }
    iii_ed25519_sc_reduce(out, in);
    int ok2 = (out[0] == 5);
    for (int i = 1; i < 32; ++i) if (out[i]) ok2 = 0;
    hex_print("(L+5) mod L = ", out, 32);
    printf("  expected 05 00..00 => %s\n\n", ok2 ? "OK" : "FAIL");

    /* Test 3: input is large but < L, should pass through unchanged. */
    uint8_t small_in[64] = {0};
    small_in[0] = 0xAA; small_in[15] = 0x55;
    iii_ed25519_sc_reduce(out, small_in);
    int ok3 = (out[0] == 0xAA && out[15] == 0x55);
    hex_print("small mod L = ", out, 32);
    printf("  expected aa..00..55..00 => %s\n", ok3 ? "OK" : "FAIL");

    return (ok1 && ok2 && ok3) ? 0 : 1;
}
