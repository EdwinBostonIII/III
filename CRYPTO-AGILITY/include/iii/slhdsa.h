/* FIPS 205 SLH-DSA (formerly SPHINCS+). SHA-256 small parameter sets. */
#ifndef III_SLHDSA_H
#define III_SLHDSA_H
#include <stdint.h>
#include <stddef.h>

/* Parameter levels (SHA-256, 's' = small signatures, slow signing). */
typedef enum { III_SLH_128S = 1, III_SLH_192S = 2, III_SLH_256S = 3 } iii_slh_level_t;

void iii_slhdsa_sizes(iii_slh_level_t lv, size_t *pk, size_t *sk, size_t *sig);

int iii_slhdsa_keygen(iii_slh_level_t lv, const uint8_t *seed /*3*n bytes*/,
                      uint8_t *pk, uint8_t *sk);
int iii_slhdsa_sign(iii_slh_level_t lv, const uint8_t *sk,
                    const uint8_t *msg, size_t msglen,
                    uint8_t *sig, size_t *siglen);
int iii_slhdsa_verify(iii_slh_level_t lv, const uint8_t *pk,
                      const uint8_t *msg, size_t msglen,
                      const uint8_t *sig, size_t siglen);

#endif
