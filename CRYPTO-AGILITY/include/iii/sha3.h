/* Hand-rolled Keccak-f[1600], SHA3-256/512, SHAKE128/256 per FIPS 202. */
#ifndef III_SHA3_H
#define III_SHA3_H
#include <stdint.h>
#include <stddef.h>

typedef struct {
    uint64_t s[25];
    size_t   pos;       /* current byte index in rate region */
    size_t   rate;      /* rate in bytes */
    uint8_t  delim;     /* domain-separation byte */
    int      squeezing;
} iii_keccak_ctx_t;

void iii_keccak_init(iii_keccak_ctx_t *c, size_t rate, uint8_t delim);
void iii_keccak_absorb(iii_keccak_ctx_t *c, const uint8_t *in, size_t len);
void iii_keccak_finalize(iii_keccak_ctx_t *c);
void iii_keccak_squeeze(iii_keccak_ctx_t *c, uint8_t *out, size_t len);

void iii_sha3_256(const uint8_t *in, size_t inlen, uint8_t out[32]);
void iii_sha3_512(const uint8_t *in, size_t inlen, uint8_t out[64]);
void iii_shake128(const uint8_t *in, size_t inlen, uint8_t *out, size_t outlen);
void iii_shake256(const uint8_t *in, size_t inlen, uint8_t *out, size_t outlen);

#endif
