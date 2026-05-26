/* Hand-rolled ChaCha20 + Poly1305 AEAD per RFC 8439. */
#ifndef III_CHACHA20_H
#define III_CHACHA20_H
#include <stdint.h>
#include <stddef.h>

void iii_chacha20_block(const uint8_t key[32], const uint8_t nonce[12],
                        uint32_t counter, uint8_t out[64]);
void iii_chacha20_xor(const uint8_t key[32], const uint8_t nonce[12],
                      uint32_t counter, const uint8_t *in, uint8_t *out, size_t len);

void iii_poly1305(const uint8_t key[32], const uint8_t *msg, size_t msglen,
                  uint8_t tag[16]);

int iii_chacha20_poly1305_seal(const uint8_t key[32], const uint8_t nonce[12],
                               const uint8_t *aad, size_t aad_len,
                               const uint8_t *pt, size_t pt_len,
                               uint8_t *ct, uint8_t tag[16]);
int iii_chacha20_poly1305_open(const uint8_t key[32], const uint8_t nonce[12],
                               const uint8_t *aad, size_t aad_len,
                               const uint8_t *ct, size_t ct_len,
                               const uint8_t tag[16], uint8_t *pt);

#endif
