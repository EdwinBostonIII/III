/* Hand-rolled SHA-384 / SHA-512 per FIPS 180-4. (SHA-256 lives in LEXICON.) */
#ifndef III_SHA2_H
#define III_SHA2_H
#include <stdint.h>
#include <stddef.h>

typedef struct {
    uint64_t h[8];
    uint64_t bitlen_hi, bitlen_lo;
    uint8_t  buf[128];
    size_t   buflen;
} iii_sha512_ctx_t;

void iii_sha512_init(iii_sha512_ctx_t *c);
void iii_sha512_update(iii_sha512_ctx_t *c, const uint8_t *data, size_t len);
void iii_sha512_final(iii_sha512_ctx_t *c, uint8_t out[64]);
void iii_sha512(const uint8_t *data, size_t len, uint8_t out[64]);

void iii_sha384_init(iii_sha512_ctx_t *c);
void iii_sha384_final(iii_sha512_ctx_t *c, uint8_t out[48]);
void iii_sha384(const uint8_t *data, size_t len, uint8_t out[48]);

#endif
