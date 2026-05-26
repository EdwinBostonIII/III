/* Hand-rolled SHA-256 per FIPS 180-4. */
#ifndef III_SHA256_H
#define III_SHA256_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct iii_sha256_ctx {
    uint32_t h[8];
    uint64_t bitlen;
    uint8_t  buf[64];
    size_t   buflen;
} iii_sha256_ctx_t;

void iii_sha256_init(iii_sha256_ctx_t *c);
void iii_sha256_update(iii_sha256_ctx_t *c, const void *data, size_t len);
void iii_sha256_final(iii_sha256_ctx_t *c, uint8_t out[32]);
void iii_sha256(const void *data, size_t len, uint8_t out[32]);

#ifdef __cplusplus
}
#endif
#endif
