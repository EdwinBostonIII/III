/* Hand-rolled ChaCha20 + Poly1305 AEAD per RFC 8439. */
#include "iii/chacha20.h"
#include <string.h>

#define ROL32(x,n) (((x) << (n)) | ((x) >> (32 - (n))))

static uint32_t load32_le(const uint8_t *p) {
    return (uint32_t)p[0] | ((uint32_t)p[1] << 8) | ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24);
}
static void store32_le(uint8_t *p, uint32_t v) {
    p[0]=(uint8_t)v; p[1]=(uint8_t)(v>>8); p[2]=(uint8_t)(v>>16); p[3]=(uint8_t)(v>>24);
}

#define QR(a,b,c,d) do { \
    a += b; d ^= a; d = ROL32(d,16); \
    c += d; b ^= c; b = ROL32(b,12); \
    a += b; d ^= a; d = ROL32(d, 8); \
    c += d; b ^= c; b = ROL32(b, 7); \
} while (0)

void iii_chacha20_block(const uint8_t key[32], const uint8_t nonce[12],
                        uint32_t counter, uint8_t out[64]) {
    uint32_t s[16];
    s[0]=0x61707865; s[1]=0x3320646e; s[2]=0x79622d32; s[3]=0x6b206574;
    for (int i = 0; i < 8; i++) s[4+i] = load32_le(key + 4*i);
    s[12] = counter;
    s[13] = load32_le(nonce + 0);
    s[14] = load32_le(nonce + 4);
    s[15] = load32_le(nonce + 8);
    uint32_t x[16]; memcpy(x, s, sizeof x);
    for (int i = 0; i < 10; i++) {
        QR(x[0],x[4],x[ 8],x[12]); QR(x[1],x[5],x[ 9],x[13]);
        QR(x[2],x[6],x[10],x[14]); QR(x[3],x[7],x[11],x[15]);
        QR(x[0],x[5],x[10],x[15]); QR(x[1],x[6],x[11],x[12]);
        QR(x[2],x[7],x[ 8],x[13]); QR(x[3],x[4],x[ 9],x[14]);
    }
    for (int i = 0; i < 16; i++) store32_le(out + 4*i, x[i] + s[i]);
}

void iii_chacha20_xor(const uint8_t key[32], const uint8_t nonce[12],
                      uint32_t counter, const uint8_t *in, uint8_t *out, size_t len) {
    uint8_t blk[64];
    while (len) {
        iii_chacha20_block(key, nonce, counter++, blk);
        size_t take = len < 64 ? len : 64;
        for (size_t i = 0; i < take; i++) out[i] = in[i] ^ blk[i];
        in += take; out += take; len -= take;
    }
}

/* ---- Poly1305 (RFC 8439). 130-bit modular multiplication using 32-bit limbs. */
void iii_poly1305(const uint8_t key[32], const uint8_t *msg, size_t msglen, uint8_t tag[16]) {
    /* Clamp r */
    uint32_t r0,r1,r2,r3,r4;
    uint32_t s1,s2,s3,s4;
    uint32_t h0=0,h1=0,h2=0,h3=0,h4=0;
    uint8_t t[16];
    memcpy(t, key, 16);
    t[3] &= 15; t[7] &= 15; t[11] &= 15; t[15] &= 15;
    t[4] &= 252; t[8] &= 252; t[12] &= 252;
    /* r as 5 26-bit limbs */
    uint32_t r[4];
    r[0] = load32_le(t+0); r[1] = load32_le(t+4); r[2] = load32_le(t+8); r[3] = load32_le(t+12);
    r0 = r[0] & 0x3ffffff;
    r1 = ((r[0] >> 26) | (r[1] << 6)) & 0x3ffffff;
    r2 = ((r[1] >> 20) | (r[2] << 12)) & 0x3ffffff;
    r3 = ((r[2] >> 14) | (r[3] << 18)) & 0x3ffffff;
    r4 = (r[3] >> 8) & 0x3ffffff;
    s1 = r1 * 5; s2 = r2 * 5; s3 = r3 * 5; s4 = r4 * 5;

    while (msglen) {
        uint8_t blk[16] = {0};
        size_t take = msglen < 16 ? msglen : 16;
        memcpy(blk, msg, take);
        uint32_t hibit;
        if (take < 16) { blk[take] = 1; hibit = 0; } else hibit = (1u << 24);
        uint32_t b0 = load32_le(blk+0), b1=load32_le(blk+4), b2=load32_le(blk+8), b3=load32_le(blk+12);
        h0 += b0 & 0x3ffffff;
        h1 += ((b0 >> 26) | (b1 << 6)) & 0x3ffffff;
        h2 += ((b1 >> 20) | (b2 << 12)) & 0x3ffffff;
        h3 += ((b2 >> 14) | (b3 << 18)) & 0x3ffffff;
        h4 += (b3 >> 8) | hibit;

        uint64_t d0 = (uint64_t)h0*r0 + (uint64_t)h1*s4 + (uint64_t)h2*s3 + (uint64_t)h3*s2 + (uint64_t)h4*s1;
        uint64_t d1 = (uint64_t)h0*r1 + (uint64_t)h1*r0 + (uint64_t)h2*s4 + (uint64_t)h3*s3 + (uint64_t)h4*s2;
        uint64_t d2 = (uint64_t)h0*r2 + (uint64_t)h1*r1 + (uint64_t)h2*r0 + (uint64_t)h3*s4 + (uint64_t)h4*s3;
        uint64_t d3 = (uint64_t)h0*r3 + (uint64_t)h1*r2 + (uint64_t)h2*r1 + (uint64_t)h3*r0 + (uint64_t)h4*s4;
        uint64_t d4 = (uint64_t)h0*r4 + (uint64_t)h1*r3 + (uint64_t)h2*r2 + (uint64_t)h3*r1 + (uint64_t)h4*r0;

        uint32_t c;
        c = (uint32_t)(d0 >> 26); h0 = (uint32_t)d0 & 0x3ffffff; d1 += c;
        c = (uint32_t)(d1 >> 26); h1 = (uint32_t)d1 & 0x3ffffff; d2 += c;
        c = (uint32_t)(d2 >> 26); h2 = (uint32_t)d2 & 0x3ffffff; d3 += c;
        c = (uint32_t)(d3 >> 26); h3 = (uint32_t)d3 & 0x3ffffff; d4 += c;
        c = (uint32_t)(d4 >> 26); h4 = (uint32_t)d4 & 0x3ffffff;
        h0 += c * 5;
        c = h0 >> 26; h0 &= 0x3ffffff; h1 += c;

        msg += take; msglen -= take;
    }
    /* Final reduction */
    uint32_t c;
    c = h1 >> 26; h1 &= 0x3ffffff; h2 += c;
    c = h2 >> 26; h2 &= 0x3ffffff; h3 += c;
    c = h3 >> 26; h3 &= 0x3ffffff; h4 += c;
    c = h4 >> 26; h4 &= 0x3ffffff; h0 += c * 5;
    c = h0 >> 26; h0 &= 0x3ffffff; h1 += c;

    /* Compute h - p (p = 2^130 - 5) */
    uint32_t g0,g1,g2,g3,g4;
    g0 = h0 + 5; c = g0 >> 26; g0 &= 0x3ffffff;
    g1 = h1 + c; c = g1 >> 26; g1 &= 0x3ffffff;
    g2 = h2 + c; c = g2 >> 26; g2 &= 0x3ffffff;
    g3 = h3 + c; c = g3 >> 26; g3 &= 0x3ffffff;
    g4 = h4 + c - (1u << 26);

    uint32_t mask = (g4 >> 31) - 1; /* 0xffffffff if g4 >= 0 (no borrow) */
    g0 &= mask; g1 &= mask; g2 &= mask; g3 &= mask; g4 &= mask;
    mask = ~mask;
    h0 = (h0 & mask) | g0;
    h1 = (h1 & mask) | g1;
    h2 = (h2 & mask) | g2;
    h3 = (h3 & mask) | g3;
    h4 = (h4 & mask) | g4;

    /* Pack to 4 32-bit words */
    uint64_t f;
    uint32_t out0,out1,out2,out3;
    out0 = (h0      ) | (h1 << 26);
    out1 = (h1 >>  6) | (h2 << 20);
    out2 = (h2 >> 12) | (h3 << 14);
    out3 = (h3 >> 18) | (h4 <<  8);
    /* Add s */
    f = (uint64_t)out0 + load32_le(key+16); out0 = (uint32_t)f;
    f = (uint64_t)out1 + load32_le(key+20) + (f >> 32); out1 = (uint32_t)f;
    f = (uint64_t)out2 + load32_le(key+24) + (f >> 32); out2 = (uint32_t)f;
    f = (uint64_t)out3 + load32_le(key+28) + (f >> 32); out3 = (uint32_t)f;
    store32_le(tag+0, out0); store32_le(tag+4, out1);
    store32_le(tag+8, out2); store32_le(tag+12, out3);
}

static void poly1305_keygen(uint8_t poly_key[32], const uint8_t key[32], const uint8_t nonce[12]) {
    uint8_t blk[64];
    iii_chacha20_block(key, nonce, 0, blk);
    memcpy(poly_key, blk, 32);
}

static void aead_mac_data(uint8_t *mac_input, size_t *off, const uint8_t *data, size_t len) {
    memcpy(mac_input + *off, data, len);
    *off += len;
    while (*off % 16) mac_input[(*off)++] = 0;
}

int iii_chacha20_poly1305_seal(const uint8_t key[32], const uint8_t nonce[12],
                               const uint8_t *aad, size_t aad_len,
                               const uint8_t *pt, size_t pt_len,
                               uint8_t *ct, uint8_t tag[16]) {
    uint8_t pkey[32];
    poly1305_keygen(pkey, key, nonce);
    iii_chacha20_xor(key, nonce, 1, pt, ct, pt_len);
    /* Build mac input: aad || pad16 || ct || pad16 || aad_len(8 LE) || ct_len(8 LE) */
    size_t pad_a = (16 - (aad_len % 16)) % 16;
    size_t pad_c = (16 - (pt_len % 16)) % 16;
    size_t total = aad_len + pad_a + pt_len + pad_c + 16;
    uint8_t *buf = (uint8_t*)__builtin_alloca(total);
    size_t off = 0;
    aead_mac_data(buf, &off, aad, aad_len); /* pads */
    /* fix pad_a accounting since aead_mac_data pads to 16 */
    (void)pad_a;
    aead_mac_data(buf, &off, ct, pt_len);
    (void)pad_c;
    /* lengths */
    uint64_t a = aad_len, c = pt_len;
    for (int i = 0; i < 8; i++) buf[off++] = (uint8_t)(a >> (8*i));
    for (int i = 0; i < 8; i++) buf[off++] = (uint8_t)(c >> (8*i));
    iii_poly1305(pkey, buf, off, tag);
    return 0;
}

int iii_chacha20_poly1305_open(const uint8_t key[32], const uint8_t nonce[12],
                               const uint8_t *aad, size_t aad_len,
                               const uint8_t *ct, size_t ct_len,
                               const uint8_t tag[16], uint8_t *pt) {
    uint8_t pkey[32], expected[16];
    poly1305_keygen(pkey, key, nonce);
    size_t pad_a = (16 - (aad_len % 16)) % 16;
    size_t pad_c = (16 - (ct_len  % 16)) % 16;
    size_t total = aad_len + pad_a + ct_len + pad_c + 16;
    uint8_t *buf = (uint8_t*)__builtin_alloca(total);
    size_t off = 0;
    aead_mac_data(buf, &off, aad, aad_len);
    aead_mac_data(buf, &off, ct, ct_len);
    uint64_t a = aad_len, c = ct_len;
    for (int i = 0; i < 8; i++) buf[off++] = (uint8_t)(a >> (8*i));
    for (int i = 0; i < 8; i++) buf[off++] = (uint8_t)(c >> (8*i));
    iii_poly1305(pkey, buf, off, expected);
    uint8_t diff = 0;
    for (int i = 0; i < 16; i++) diff |= expected[i] ^ tag[i];
    if (diff) return -1;
    iii_chacha20_xor(key, nonce, 1, ct, pt, ct_len);
    return 0;
}
