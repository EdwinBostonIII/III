/* Hand-rolled AES-256 + GCM per FIPS 197 / SP 800-38D. */
#ifndef III_AES_H
#define III_AES_H
#include <stdint.h>
#include <stddef.h>

typedef struct { uint32_t rk[60]; } iii_aes256_key_t; /* 14 rounds + initial */

void iii_aes256_set_key(iii_aes256_key_t *k, const uint8_t key[32]);
void iii_aes256_encrypt(const iii_aes256_key_t *k, const uint8_t in[16], uint8_t out[16]);

/* AEAD interface: AES-256-GCM. */
int iii_aes256_gcm_seal(const uint8_t key[32], const uint8_t iv[12],
                        const uint8_t *aad, size_t aad_len,
                        const uint8_t *pt, size_t pt_len,
                        uint8_t *ct, uint8_t tag[16]);
int iii_aes256_gcm_open(const uint8_t key[32], const uint8_t iv[12],
                        const uint8_t *aad, size_t aad_len,
                        const uint8_t *ct, size_t ct_len,
                        const uint8_t tag[16], uint8_t *pt);

#endif
