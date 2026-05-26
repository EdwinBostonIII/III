/* Hand-rolled Ed25519 per RFC 8032. */
#ifndef III_ED25519_H
#define III_ED25519_H
#include <stdint.h>
#include <stddef.h>

void iii_ed25519_keygen(uint8_t pk[32], const uint8_t seed[32]);
void iii_ed25519_sign(uint8_t sig[64], const uint8_t *msg, size_t msglen,
                      const uint8_t pk[32], const uint8_t seed[32]);
int  iii_ed25519_verify(const uint8_t sig[64], const uint8_t *msg, size_t msglen,
                        const uint8_t pk[32]);

#endif
