/* FIPS 203 ML-KEM (formerly Kyber). Three parameter sets. */
#ifndef III_MLKEM_H
#define III_MLKEM_H
#include <stdint.h>
#include <stddef.h>

#define III_MLKEM_SS_BYTES 32

/* k=2 (ML-KEM-512) */
#define III_MLKEM512_PK_BYTES   800
#define III_MLKEM512_SK_BYTES  1632
#define III_MLKEM512_CT_BYTES   768

/* k=3 (ML-KEM-768) */
#define III_MLKEM768_PK_BYTES  1184
#define III_MLKEM768_SK_BYTES  2400
#define III_MLKEM768_CT_BYTES  1088

/* k=4 (ML-KEM-1024) */
#define III_MLKEM1024_PK_BYTES 1568
#define III_MLKEM1024_SK_BYTES 3168
#define III_MLKEM1024_CT_BYTES 1568

/* k must be 2, 3, or 4. RNG seed must be 64 bytes (d || z) per FIPS 203. */
int iii_mlkem_keygen(int k, const uint8_t seed[64], uint8_t *pk, uint8_t *sk);
int iii_mlkem_encaps(int k, const uint8_t *pk, const uint8_t coins[32],
                     uint8_t *ct, uint8_t ss[32]);
int iii_mlkem_decaps(int k, const uint8_t *sk, const uint8_t *ct, uint8_t ss[32]);

#endif
