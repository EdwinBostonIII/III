/* ============================================================================
 * III-CYCLES — crypto.c
 *
 * HMAC-SHA-256, HKDF-SHA-256, and BLAKE3 — the cryptographic primitives the
 * witness-emission protocol calls for.  iii_sha256 is the canonical primitive
 * from LEXICON/src/sha256.c (extern); no local copy is maintained here.
 *
 *   HMAC      : RFC 2104
 *   HKDF      : RFC 5869
 *   BLAKE3    : the BLAKE3 spec (single-chunk variant, sufficient for
 *               witness-sized inputs ≤ 1024 bytes).
 * ============================================================================
 */
#include "cycles_internal.h"
#include <string.h>

#include "iii/sha256.h"

/* ============================================================================
 * HMAC-SHA-256 (RFC 2104) — built on the canonical iii_sha256_{init,update,final}
 * streaming API from LEXICON.
 * ============================================================================
 */

static uint32_t rotr32(uint32_t x, unsigned n) {
    return (x >> n) | (x << ((32u - n) & 31u));
}

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

    /* inner = SHA-256(ipad || msg) — streaming. */
    iii_sha256_ctx_t ctx;
    iii_sha256_init(&ctx);
    iii_sha256_update(&ctx, ipad, 64);
    iii_sha256_update(&ctx, msg, msg_len);
    uint8_t inner[32];
    iii_sha256_final(&ctx, inner);

    /* outer = SHA-256(opad || inner) */
    uint8_t outer_buf[64 + 32];
    memcpy(outer_buf,      opad,  64);
    memcpy(outer_buf + 64, inner, 32);
    iii_sha256(outer_buf, sizeof(outer_buf), out);
}

/* ============================================================================
 * HKDF-SHA-256 (RFC 5869)
 * ============================================================================
 */

void iii_hkdf_sha256(const uint8_t *ikm,  size_t ikm_len,
                     const uint8_t *salt, size_t salt_len,
                     const uint8_t *info, size_t info_len,
                     uint8_t       *okm,  size_t okm_len)
{
    uint8_t prk[32];
    uint8_t zsalt[32] = {0};
    if (salt == NULL || salt_len == 0) {
        salt = zsalt;
        salt_len = 32;
    }
    iii_hmac_sha256(salt, salt_len, ikm, ikm_len, prk);

    /* T(1) = HMAC(PRK, info || 0x01); T(i) = HMAC(PRK, T(i-1) || info || i) */
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

/* ============================================================================
 * BLAKE3 — single-chunk variant.
 *
 * Our use case (witness content hashes) is always ≤ 128 bytes — a single
 * chunk of one or two 64-byte blocks.  We implement only the single-chunk
 * path (CHUNK_START | CHUNK_END | ROOT flags on the final block).  This
 * matches the BLAKE3 reference for inputs ≤ 1024 bytes.
 * ============================================================================
 */

#define BLAKE3_CHUNK_START         (1u << 0)
#define BLAKE3_CHUNK_END           (1u << 1)
#define BLAKE3_PARENT              (1u << 2)
#define BLAKE3_ROOT                (1u << 3)

static const uint8_t blake3_msg_perm[16] = {
    2, 6, 3, 10, 7, 0, 4, 13, 1, 11, 12, 5, 9, 14, 15, 8
};

static const uint32_t blake3_iv[8] = {
    0x6a09e667u, 0xbb67ae85u, 0x3c6ef372u, 0xa54ff53au,
    0x510e527fu, 0x9b05688cu, 0x1f83d9abu, 0x5be0cd19u
};

static void blake3_g(uint32_t *s, unsigned a, unsigned b, unsigned c, unsigned d,
                     uint32_t mx, uint32_t my)
{
    s[a] = s[a] + s[b] + mx;
    s[d] = rotr32(s[d] ^ s[a], 16);
    s[c] = s[c] + s[d];
    s[b] = rotr32(s[b] ^ s[c], 12);
    s[a] = s[a] + s[b] + my;
    s[d] = rotr32(s[d] ^ s[a], 8);
    s[c] = s[c] + s[d];
    s[b] = rotr32(s[b] ^ s[c], 7);
}

static void blake3_round(uint32_t *s, const uint32_t *m) {
    blake3_g(s, 0, 4,  8, 12, m[0],  m[1]);
    blake3_g(s, 1, 5,  9, 13, m[2],  m[3]);
    blake3_g(s, 2, 6, 10, 14, m[4],  m[5]);
    blake3_g(s, 3, 7, 11, 15, m[6],  m[7]);
    blake3_g(s, 0, 5, 10, 15, m[8],  m[9]);
    blake3_g(s, 1, 6, 11, 12, m[10], m[11]);
    blake3_g(s, 2, 7,  8, 13, m[12], m[13]);
    blake3_g(s, 3, 4,  9, 14, m[14], m[15]);
}

static void blake3_permute(uint32_t m[16]) {
    uint32_t t[16];
    for (unsigned i = 0; i < 16; ++i) t[i] = m[blake3_msg_perm[i]];
    memcpy(m, t, sizeof(t));
}

/* Compress one 64-byte block.  Updates the chaining value `cv` in place
 * when full_output is false; if full_output is true, writes 64 bytes (full
 * extended state) to out_block. */
static void blake3_compress(const uint32_t  cv_in[8],
                            const uint8_t   block[64],
                            uint64_t        counter,
                            uint32_t        block_len,
                            uint32_t        flags,
                            uint32_t        cv_out[8])
{
    uint32_t s[16];
    s[0]  = cv_in[0];
    s[1]  = cv_in[1];
    s[2]  = cv_in[2];
    s[3]  = cv_in[3];
    s[4]  = cv_in[4];
    s[5]  = cv_in[5];
    s[6]  = cv_in[6];
    s[7]  = cv_in[7];
    s[8]  = blake3_iv[0];
    s[9]  = blake3_iv[1];
    s[10] = blake3_iv[2];
    s[11] = blake3_iv[3];
    s[12] = (uint32_t)(counter & 0xFFFFFFFFu);
    s[13] = (uint32_t)(counter >> 32);
    s[14] = block_len;
    s[15] = flags;

    uint32_t m[16];
    for (unsigned i = 0; i < 16; ++i) {
        m[i] = ((uint32_t)block[i*4])           |
               ((uint32_t)block[i*4 + 1] << 8)  |
               ((uint32_t)block[i*4 + 2] << 16) |
               ((uint32_t)block[i*4 + 3] << 24);
    }

    for (unsigned r = 0; r < 7; ++r) {
        blake3_round(s, m);
        if (r < 6) blake3_permute(m);
    }

    for (unsigned i = 0; i < 8; ++i) {
        cv_out[i] = s[i] ^ s[i + 8];
    }
}

void iii_blake3(const uint8_t *data, size_t len, uint8_t out[32]) {
    /* Single-chunk path: len ≤ 1024.  For our purposes (≤ 128-byte witness)
     * we always have at most two blocks. */
    uint32_t cv[8];
    memcpy(cv, blake3_iv, sizeof(cv));

    size_t        remaining = len;
    const uint8_t *p        = data;
    uint64_t       counter   = 0;
    bool           first     = true;

    while (remaining > 64) {
        uint32_t flags = 0;
        if (first) flags |= BLAKE3_CHUNK_START;
        first = false;
        uint32_t next_cv[8];
        blake3_compress(cv, p, counter, 64, flags, next_cv);
        memcpy(cv, next_cv, sizeof(cv));
        p         += 64;
        remaining -= 64;
        /* counter is the chunk counter, not the block counter — single-chunk
         * keeps it at 0. */
    }

    /* Final block. */
    uint8_t  last_block[64] = {0};
    uint32_t last_len = (uint32_t)remaining;
    if (remaining > 0) {
        memcpy(last_block, p, remaining);
    }

    uint32_t flags = BLAKE3_CHUNK_END | BLAKE3_ROOT;
    if (first) flags |= BLAKE3_CHUNK_START;

    uint32_t out_cv[8];
    blake3_compress(cv, last_block, counter, last_len, flags, out_cv);

    for (unsigned i = 0; i < 8; ++i) {
        out[i*4]     = (uint8_t)(out_cv[i]);
        out[i*4 + 1] = (uint8_t)(out_cv[i] >>  8);
        out[i*4 + 2] = (uint8_t)(out_cv[i] >> 16);
        out[i*4 + 3] = (uint8_t)(out_cv[i] >> 24);
    }
}
