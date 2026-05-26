/* ============================================================================
 * SANCTUM crypto — HMAC-SHA-256 and HKDF-SHA-256 wrappers.
 *
 * iii_sha256 is the canonical primitive from LEXICON/src/sha256.c (extern).
 * This file contains the SANCTUM-private HMAC and HKDF implementations,
 * structurally identical to CYCLES/src/crypto.c.  Any divergence in HMAC or
 * HKDF semantics MUST be reflected in both files; verify with diff:
 *
 *     diff CYCLES/src/crypto.c SANCTUM/src/crypto.c   # only header + BLAKE3
 *
 * SANCTUM does not need BLAKE3, so the BLAKE3 implementation lives only in
 * CYCLES/src/crypto.c.  HMAC and HKDF logic is identical.
 * ============================================================================
 */
#include "sanctum_internal.h"
#include "iii/sha256.h"
#include <string.h>

extern void iii_sha256(const void *data, size_t len, uint8_t out[32]);

void iii_hmac_sha256(const uint8_t *key, size_t key_len,
                     const uint8_t *msg, size_t msg_len,
                     uint8_t        out[32])
{
    uint8_t k[64];
    if (key_len > 64) {
        iii_sha256(key, key_len, k);
        memset(k + 32, 0, 32);
    } else {
        memcpy(k, key, key_len);
        memset(k + key_len, 0, 64 - key_len);
    }

    uint8_t ipad[64], opad[64];
    for (unsigned i = 0; i < 64; ++i) ipad[i] = k[i] ^ 0x36u;
    for (unsigned i = 0; i < 64; ++i) opad[i] = k[i] ^ 0x5Cu;

    iii_sha256_ctx_t ctx;
    iii_sha256_init(&ctx);
    iii_sha256_update(&ctx, ipad, 64);
    iii_sha256_update(&ctx, msg, msg_len);
    uint8_t inner[32];
    iii_sha256_final(&ctx, inner);

    uint8_t outer_buf[64 + 32];
    memcpy(outer_buf,      opad,  64);
    memcpy(outer_buf + 64, inner, 32);
    iii_sha256(outer_buf, sizeof(outer_buf), out);
}

void iii_hkdf_sha256(const uint8_t *ikm,  size_t ikm_len,
                     const uint8_t *salt, size_t salt_len,
                     const uint8_t *info, size_t info_len,
                     uint8_t       *okm,  size_t okm_len)
{
    uint8_t prk[32];
    uint8_t zsalt[32] = {0};
    if (!salt || salt_len == 0) {
        salt = zsalt;
        salt_len = 32;
    }
    iii_hmac_sha256(salt, salt_len, ikm, ikm_len, prk);

    uint8_t  t_prev[32];
    size_t   t_prev_len = 0;
    size_t   produced   = 0;
    uint8_t  counter    = 1;
    while (produced < okm_len) {
        uint8_t buf[32 + 256 + 1];
        size_t  blen = 0;
        if (t_prev_len > 0) {
            memcpy(buf + blen, t_prev, t_prev_len);
            blen += t_prev_len;
        }
        size_t inf = (info_len > 256u) ? 256u : info_len;
        if (inf > 0) {
            memcpy(buf + blen, info, inf);
            blen += inf;
        }
        buf[blen++] = counter;
        uint8_t t[32];
        iii_hmac_sha256(prk, 32, buf, blen, t);
        size_t take = ((okm_len - produced) < 32u) ? (okm_len - produced) : 32u;
        memcpy(okm + produced, t, take);
        produced += take;
        memcpy(t_prev, t, 32);
        t_prev_len = 32;
        counter++;
    }
}
