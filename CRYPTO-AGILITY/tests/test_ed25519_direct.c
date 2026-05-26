#include "iii/ed25519.h"
#include <stdio.h>
#include <string.h>

int main(void) {
    uint8_t seed[32]; for (unsigned i = 0; i < 32; ++i) seed[i] = (uint8_t)(0x40 + i);
    uint8_t pk[32];
    iii_ed25519_keygen(pk, seed);
    printf("pk: ");
    for (unsigned i = 0; i < 32; ++i) printf("%02x", pk[i]);
    printf("\n");

    const uint8_t msg[] = "test";
    uint8_t sig[64];
    iii_ed25519_sign(sig, msg, sizeof(msg) - 1, pk, seed);
    printf("sig: ");
    for (unsigned i = 0; i < 32; ++i) printf("%02x", sig[i]);
    printf("...\n");

    int rc = iii_ed25519_verify(sig, msg, sizeof(msg) - 1, pk);
    printf("verify rc=%d (0=ok, -1=fail)\n", rc);

    return rc;
}
