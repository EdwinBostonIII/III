#include "test.h"
#include "iii/sha256.h"

static void hex_of(const uint8_t in[32], char out[65]) {
    static const char *h = "0123456789abcdef";
    for (int i = 0; i < 32; i++) { out[i*2]=h[in[i]>>4]; out[i*2+1]=h[in[i]&0xF]; }
    out[64] = 0;
}

static void test_sha256_known(void) {
    IIIT_BEGIN("sha256 empty");
    uint8_t h[32]; iii_sha256((const uint8_t *)"", 0, h);
    char hex[65]; hex_of(h, hex);
    IIIT_ASSERT(strcmp(hex, "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855") == 0, "got %s", hex);
    IIIT_OK();
}

static void test_sha256_abc(void) {
    IIIT_BEGIN("sha256 'abc'");
    uint8_t h[32]; iii_sha256((const uint8_t *)"abc", 3, h);
    char hex[65]; hex_of(h, hex);
    IIIT_ASSERT(strcmp(hex, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad") == 0, "got %s", hex);
    IIIT_OK();
}

static void test_sha256_long(void) {
    IIIT_BEGIN("sha256 'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq'");
    const char *s = "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq";
    uint8_t h[32]; iii_sha256((const uint8_t *)s, strlen(s), h);
    char hex[65]; hex_of(h, hex);
    IIIT_ASSERT(strcmp(hex, "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1") == 0, "got %s", hex);
    IIIT_OK();
}

void run_test_sha256(void) {
    test_sha256_known();
    test_sha256_abc();
    test_sha256_long();
}
