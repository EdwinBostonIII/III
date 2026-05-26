/* Hand-rolled Keccak-f[1600], SHA-3, SHAKE per FIPS 202. */
#include "iii/sha3.h"
#include <string.h>

static const uint64_t RC[24] = {
    0x0000000000000001ULL,0x0000000000008082ULL,0x800000000000808aULL,0x8000000080008000ULL,
    0x000000000000808bULL,0x0000000080000001ULL,0x8000000080008081ULL,0x8000000000008009ULL,
    0x000000000000008aULL,0x0000000000000088ULL,0x0000000080008009ULL,0x000000008000000aULL,
    0x000000008000808bULL,0x800000000000008bULL,0x8000000000008089ULL,0x8000000000008003ULL,
    0x8000000000008002ULL,0x8000000000000080ULL,0x000000000000800aULL,0x800000008000000aULL,
    0x8000000080008081ULL,0x8000000000008080ULL,0x0000000080000001ULL,0x8000000080008008ULL
};

static const unsigned R[25] = {
    0, 1, 62, 28, 27,
   36,44,  6, 55, 20,
    3,10, 43, 25, 39,
   41,45, 15, 21,  8,
   18, 2, 61, 56, 14
};

#define ROL64(x,n) (((x) << (n)) | ((x) >> (64 - (n))))

static void keccak_f1600(uint64_t s[25]) {
    for (int round = 0; round < 24; round++) {
        uint64_t C[5], D[5], B[25];
        for (int x = 0; x < 5; x++)
            C[x] = s[x] ^ s[x+5] ^ s[x+10] ^ s[x+15] ^ s[x+20];
        for (int x = 0; x < 5; x++)
            D[x] = C[(x+4)%5] ^ ROL64(C[(x+1)%5], 1);
        for (int i = 0; i < 25; i++) s[i] ^= D[i % 5];
        for (int x = 0; x < 5; x++)
            for (int y = 0; y < 5; y++) {
                int i = x + 5 * y;
                int ni = y + 5 * ((2*x + 3*y) % 5);
                B[ni] = (R[i] == 0) ? s[i] : ROL64(s[i], R[i]);
            }
        for (int x = 0; x < 5; x++)
            for (int y = 0; y < 5; y++) {
                int i = x + 5 * y;
                s[i] = B[i] ^ ((~B[((x+1)%5) + 5*y]) & B[((x+2)%5) + 5*y]);
            }
        s[0] ^= RC[round];
    }
}

void iii_keccak_init(iii_keccak_ctx_t *c, size_t rate, uint8_t delim) {
    memset(c, 0, sizeof *c);
    c->rate = rate;
    c->delim = delim;
}

static void absorb_byte(iii_keccak_ctx_t *c, uint8_t b) {
    size_t lane = c->pos / 8, off = c->pos % 8;
    c->s[lane] ^= ((uint64_t)b) << (8 * off);
    c->pos++;
    if (c->pos == c->rate) { keccak_f1600(c->s); c->pos = 0; }
}

void iii_keccak_absorb(iii_keccak_ctx_t *c, const uint8_t *in, size_t len) {
    for (size_t i = 0; i < len; i++) absorb_byte(c, in[i]);
}

void iii_keccak_finalize(iii_keccak_ctx_t *c) {
    /* pad: append delim, then zeros, then 0x80 in last byte of rate */
    size_t lane = c->pos / 8, off = c->pos % 8;
    c->s[lane] ^= ((uint64_t)c->delim) << (8 * off);
    size_t last = c->rate - 1;
    lane = last / 8; off = last % 8;
    c->s[lane] ^= ((uint64_t)0x80) << (8 * off);
    keccak_f1600(c->s);
    c->pos = 0;
    c->squeezing = 1;
}

void iii_keccak_squeeze(iii_keccak_ctx_t *c, uint8_t *out, size_t len) {
    if (!c->squeezing) iii_keccak_finalize(c);
    while (len) {
        if (c->pos == c->rate) { keccak_f1600(c->s); c->pos = 0; }
        size_t lane = c->pos / 8, off = c->pos % 8;
        size_t take = c->rate - c->pos;
        if (take > len) take = len;
        for (size_t i = 0; i < take; i++) {
            out[i] = (uint8_t)(c->s[lane] >> (8 * off));
            off++;
            if (off == 8) { off = 0; lane++; }
        }
        out += take;
        c->pos += take;
        len -= take;
    }
}

void iii_sha3_256(const uint8_t *in, size_t inlen, uint8_t out[32]) {
    iii_keccak_ctx_t c; iii_keccak_init(&c, 136, 0x06);
    iii_keccak_absorb(&c, in, inlen);
    iii_keccak_squeeze(&c, out, 32);
}
void iii_sha3_512(const uint8_t *in, size_t inlen, uint8_t out[64]) {
    iii_keccak_ctx_t c; iii_keccak_init(&c, 72, 0x06);
    iii_keccak_absorb(&c, in, inlen);
    iii_keccak_squeeze(&c, out, 64);
}
void iii_shake128(const uint8_t *in, size_t inlen, uint8_t *out, size_t outlen) {
    iii_keccak_ctx_t c; iii_keccak_init(&c, 168, 0x1f);
    iii_keccak_absorb(&c, in, inlen);
    iii_keccak_squeeze(&c, out, outlen);
}
void iii_shake256(const uint8_t *in, size_t inlen, uint8_t *out, size_t outlen) {
    iii_keccak_ctx_t c; iii_keccak_init(&c, 136, 0x1f);
    iii_keccak_absorb(&c, in, inlen);
    iii_keccak_squeeze(&c, out, outlen);
}
