/* FIPS 204 ML-DSA (formerly Dilithium). Three parameter sets. */
#ifndef III_MLDSA_H
#define III_MLDSA_H
#include <stdint.h>
#include <stddef.h>

#define III_MLDSA44_PK_BYTES  1312
#define III_MLDSA44_SK_BYTES  2560
#define III_MLDSA44_SIG_BYTES 2420

#define III_MLDSA65_PK_BYTES  1952
#define III_MLDSA65_SK_BYTES  4032
#define III_MLDSA65_SIG_BYTES 3309

#define III_MLDSA87_PK_BYTES  2592
#define III_MLDSA87_SK_BYTES  4896
#define III_MLDSA87_SIG_BYTES 4627

/* level: 2 -> ML-DSA-44, 3 -> ML-DSA-65, 5 -> ML-DSA-87. */
int iii_mldsa_keygen(int level, const uint8_t seed[32], uint8_t *pk, uint8_t *sk);
int iii_mldsa_sign(int level, const uint8_t *sk,
                   const uint8_t *msg, size_t msglen,
                   uint8_t *sig, size_t *siglen);
int iii_mldsa_verify(int level, const uint8_t *pk,
                     const uint8_t *msg, size_t msglen,
                     const uint8_t *sig, size_t siglen);

#endif
