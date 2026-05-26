/* Ed25519 RFC 8032 §7.1 known-answer test bisector. */
#include "iii/ed25519.h"
#include <stdio.h>
#include <string.h>

static int from_hex(const char *hex, uint8_t *out, size_t n) {
    for (size_t i = 0; i < n; ++i) {
        char a = hex[2*i], b = hex[2*i+1];
        unsigned ha = (a >= '0' && a <= '9') ? (unsigned)(a - '0')
                    : (a >= 'a' && a <= 'f') ? (unsigned)(a - 'a' + 10) : 99;
        unsigned hb = (b >= '0' && b <= '9') ? (unsigned)(b - '0')
                    : (b >= 'a' && b <= 'f') ? (unsigned)(b - 'a' + 10) : 99;
        if (ha > 15 || hb > 15) return 0;
        out[i] = (uint8_t)((ha << 4) | hb);
    }
    return 1;
}

static void hex_print(const char *label, const uint8_t *b, size_t n) {
    printf("%s: ", label);
    for (size_t i = 0; i < n; ++i) printf("%02x", b[i]);
    printf("\n");
}

int main(void) {
    /* RFC 8032 §7.1 test vector 3 (canonical S, msg = 0xaf82). */
    const char *sk_hex  = "c5aa8df43f9f837bedb7442f31dcb7b166d38535076f094b85ce3a2e0b4458f7";
    const char *pk_hex  = "fc51cd8e6218a1a38da47ed00230f0580816ed13ba3303ac5deb911548908025";
    const char *msg_hex = "af82";
    const char *sig_hex = "6291d657deec24024827e69c3abe01a30ce548a284743a445e3680d7db5ac3ac18ff9b538d16f290ae67f760984dc6594a7c15e9716ed28dc027beceea1ec40a";

    uint8_t sk[32], pk_expected[32], msg[2], sig_expected[64];
    if (!from_hex(sk_hex,  sk,           32)) { printf("hex decode failed\n"); return 1; }
    if (!from_hex(pk_hex,  pk_expected,  32)) { printf("hex decode failed\n"); return 1; }
    if (!from_hex(msg_hex, msg,           2)) { printf("hex decode failed\n"); return 1; }
    if (!from_hex(sig_hex, sig_expected, 64)) { printf("hex decode failed\n"); return 1; }

    /* Test 1: keygen */
    uint8_t pk[32];
    iii_ed25519_keygen(pk, sk);
    int pk_match = memcmp(pk, pk_expected, 32) == 0;
    hex_print("keygen pk    ", pk, 32);
    hex_print("expected pk  ", pk_expected, 32);
    printf("=> keygen %s\n\n", pk_match ? "OK" : "FAIL");

    /* Test 2: sign */
    uint8_t sig[64];
    iii_ed25519_sign(sig, msg, 2, pk_expected, sk);
    int sig_match = memcmp(sig, sig_expected, 64) == 0;
    hex_print("sign sig     ", sig, 64);
    hex_print("expected sig ", sig_expected, 64);
    printf("=> sign %s\n\n", sig_match ? "OK" : "FAIL");

    /* Test 3: verify the RFC vector itself */
    int verify_rfc = iii_ed25519_verify(sig_expected, msg, 2, pk_expected);
    printf("=> verify(rfc vector) returns %d (expected 0=ok)\n", verify_rfc);

    /* Test 4: verify our own signature */
    int verify_self = iii_ed25519_verify(sig, msg, 2, pk);
    printf("=> verify(self-signed) returns %d (expected 0=ok)\n", verify_self);

    if (!(pk_match && sig_match && verify_rfc == 0 && verify_self == 0)) return 1;

    /* RFC 8032 §7.1 Test 2 (1-byte msg = 0x72) */
    {
        uint8_t sk2[32], pk2[32], pk_g[32], msg2[1] = {0x72}, sig2[64], sig_g[64];
        from_hex("4ccd089b28ff96da9db6c346ec114e0f5b8a319f35aba624da8cf6ed4fb8a6fb", sk2, 32);
        from_hex("3d4017c3e843895a92b70aa74d1b7ebc9c982ccf2ec4968cc0cd55f12af4660c", pk2, 32);
        from_hex("92a009a9f0d4cab8720e820b5f642540a2b27b5416503f8fb3762223ebdb69da085ac1e43e15996e458f3613d0f11d8c387b2eaeb4302aeeb00d291612bb0c00", sig2, 64);
        iii_ed25519_keygen(pk_g, sk2);
        if (memcmp(pk_g, pk2, 32) != 0) { printf("Test 2 keygen FAIL\n"); return 1; }
        iii_ed25519_sign(sig_g, msg2, 1, pk2, sk2);
        if (memcmp(sig_g, sig2, 64) != 0) { printf("Test 2 sign FAIL\n"); return 1; }
        if (iii_ed25519_verify(sig2, msg2, 1, pk2) != 0) { printf("Test 2 verify FAIL\n"); return 1; }
        printf("=> Test 2 (1-byte msg) OK\n");
    }

    /* RFC 8032 §7.1 Test 1024 (1023-byte msg) — verify only */
    {
        const char *sk_h = "f5e5767cf153319517630f226876b86c8160cc583bc013744c6bf255f5cc0ee5";
        const char *pk_h = "278117fc144c72340f67d0f2316e8386ceffbf2b2428c9c51fef7c597f1d426e";
        uint8_t sk_b[32], pk_b[32];
        from_hex(sk_h, sk_b, 32);
        from_hex(pk_h, pk_b, 32);
        uint8_t pk_g[32];
        iii_ed25519_keygen(pk_g, sk_b);
        if (memcmp(pk_g, pk_b, 32) != 0) { printf("Test 1024 keygen FAIL\n"); return 1; }
        printf("=> Test 1024 (large msg) keygen OK\n");
    }

    return 0;
}
