/* FIPS 203 ML-KEM (Kyber) reference implementation.
 * Hand-rolled per NIST FIPS 203 (Aug 2024). Single source, parameter k in {2,3,4}.
 *
 * Public-key bytes per param: 384*k + 32
 * Secret-key bytes:           24*k*N/8 + ... (full sk includes pk + h(pk) + z) = 768*k + 96
 *   ML-KEM-512 (k=2): pk=800,  sk=1632
 *   ML-KEM-768 (k=3): pk=1184, sk=2400
 *   ML-KEM-1024(k=4): pk=1568, sk=3168
 *
 * eta1, du, dv per parameter set:
 *   k=2: eta1=3, eta2=2, du=10, dv=4
 *   k=3: eta1=2, eta2=2, du=10, dv=4
 *   k=4: eta1=2, eta2=2, du=11, dv=5
 */
#include "iii/mlkem.h"
#include "iii/sha3.h"
#include <string.h>

#define KYBER_N 256
#define KYBER_Q 3329

typedef struct { int16_t coeffs[KYBER_N]; } poly;

static int param_eta1(int k) { return (k == 2) ? 3 : 2; }
static int param_eta2(int k) { (void)k; return 2; }
static int param_du(int k)   { return (k == 4) ? 11 : 10; }
static int param_dv(int k)   { return (k == 4) ? 5  : 4; }

/* ---- Modular reduction helpers ---- */
static int16_t barrett_reduce(int16_t a) {
    /* 2^26/Q approximated; map to [0,Q). */
    int32_t v = ((int32_t)20159 * a + (1<<25)) >> 26;
    return (int16_t)(a - v * KYBER_Q);
}
static int16_t cmod(int32_t a) {
    int32_t r = a % KYBER_Q;
    if (r < 0) r += KYBER_Q;
    return (int16_t)r;
}

/* ---- NTT (length-256 negacyclic NTT mod 3329) ---- */
/* zetas — powers of the 256-th root 17 in bit-reversed order, in the
 * PLAIN (non-Montgomery) domain (zeta[i] = 17^bitrev7(i) mod q).  This
 * impl uses plain modular arithmetic (fqmul = a*b mod q, invntt scale =
 * 256^-1 = 3303); the previous table held the standard Kyber MONTGOMERY
 * zetas (zeta*2^16 mod q, e.g. 2285 = -1044), which a plain fqmul does
 * not divide by R -> every butterfly injected a spurious 2^16 factor and
 * NTT∘INTT was not the identity (corrupting all of ML-KEM).  These are
 * the same values divided by R (R^-1 = 169 mod 3329). */
static const int16_t zetas[128] = {
1, 1729, 2580, 3289, 2642, 630, 1897, 848,
1062, 1919, 193, 797, 2786, 3260, 569, 1746,
296, 2447, 1339, 1476, 3046, 56, 2240, 1333,
1426, 2094, 535, 2882, 2393, 2879, 1974, 821,
289, 331, 3253, 1756, 1197, 2304, 2277, 2055,
650, 1977, 2513, 632, 2865, 33, 1320, 1915,
2319, 1435, 807, 452, 1438, 2868, 1534, 2402,
2647, 2617, 1481, 648, 2474, 3110, 1227, 910,
17, 2761, 583, 2649, 1637, 723, 2288, 1100,
1409, 2662, 3281, 233, 756, 2156, 3015, 3050,
1703, 1651, 2789, 1789, 1847, 952, 1461, 2687,
939, 2308, 2437, 2388, 733, 2337, 268, 641,
1584, 2298, 2037, 3220, 375, 2549, 2090, 1645,
1063, 319, 2773, 757, 2099, 561, 2466, 2594,
2804, 1092, 403, 1026, 1143, 2150, 2775, 886,
1722, 1212, 1874, 1029, 2110, 2935, 885, 2154
};

static int16_t fqmul(int16_t a, int16_t b) {
    int32_t prod = (int32_t)a * b;
    return cmod(prod);
}

static void ntt(poly *p) {
    unsigned len, start, j, k = 1;
    int16_t zeta, t;
    for (len = 128; len >= 2; len >>= 1) {
        for (start = 0; start < KYBER_N; start = j + len) {
            zeta = zetas[k++];
            for (j = start; j < start + len; j++) {
                t = fqmul(zeta, p->coeffs[j + len]);
                p->coeffs[j + len] = barrett_reduce((int16_t)(p->coeffs[j] - t + KYBER_Q));
                p->coeffs[j]       = barrett_reduce((int16_t)(p->coeffs[j] + t));
            }
        }
    }
}

static void invntt(poly *p) {
    unsigned start, len, j, k = 127;
    int16_t t, zeta;
    const int16_t f = 1441; /* mont * (256^-1 mod q) — we use plain int math: 256^-1 mod 3329 = 3303; we'll handle final scale below */
    (void)f;
    for (len = 2; len <= 128; len <<= 1) {
        for (start = 0; start < KYBER_N; start = j + len) {
            zeta = zetas[k--];
            for (j = start; j < start + len; j++) {
                t = p->coeffs[j];
                p->coeffs[j]       = barrett_reduce((int16_t)(t + p->coeffs[j + len]));
                p->coeffs[j + len] = barrett_reduce((int16_t)(p->coeffs[j + len] - t + KYBER_Q));
                p->coeffs[j + len] = fqmul(zeta, p->coeffs[j + len]);
            }
        }
    }
    /* scale by 256^-1 mod 3329 = 3303 */
    for (j = 0; j < KYBER_N; j++)
        p->coeffs[j] = fqmul(p->coeffs[j], 3303);
}

/* basemul (degree-2 mod x^2 - zeta) */
static void basemul(int16_t r[2], const int16_t a[2], const int16_t b[2], int16_t zeta) {
    r[0] = (int16_t)((int32_t)fqmul(a[1], b[1]) * zeta % KYBER_Q);
    r[0] = (int16_t)((r[0] + fqmul(a[0], b[0])) % KYBER_Q);
    r[1] = fqmul(a[0], b[1]);
    r[1] = (int16_t)((r[1] + fqmul(a[1], b[0])) % KYBER_Q);
    if (r[0] < 0) r[0] += KYBER_Q;
    if (r[1] < 0) r[1] += KYBER_Q;
}

static void poly_basemul_acc(poly *r, const poly *a, const poly *b) {
    for (unsigned i = 0; i < KYBER_N/4; i++) {
        int16_t z = zetas[64 + i];
        basemul(&r->coeffs[4*i], &a->coeffs[4*i], &b->coeffs[4*i], z);
        int16_t tmp[2];
        basemul(tmp, &a->coeffs[4*i+2], &b->coeffs[4*i+2], (int16_t)(-z));
        r->coeffs[4*i+2] = tmp[0];
        r->coeffs[4*i+3] = tmp[1];
    }
}

/* ---- Polynomial sampling ---- */
static void poly_uniform(poly *p, const uint8_t seed[32], uint8_t i, uint8_t j) {
    uint8_t buf[32 + 2];
    memcpy(buf, seed, 32); buf[32] = i; buf[33] = j;
    /* Squeeze SHAKE-128 generating up to needed coefficients */
    iii_keccak_ctx_t c;
    iii_keccak_init(&c, 168, 0x1f);
    iii_keccak_absorb(&c, buf, 34);
    iii_keccak_finalize(&c);
    int ctr = 0;
    uint8_t out[168];
    while (ctr < KYBER_N) {
        iii_keccak_squeeze(&c, out, 168);
        for (unsigned k = 0; k < 168 && ctr < KYBER_N; k += 3) {
            uint16_t d1 = ((uint16_t)out[k] | ((uint16_t)out[k+1] << 8)) & 0x0fff;
            uint16_t d2 = ((uint16_t)out[k+1] >> 4) | ((uint16_t)out[k+2] << 4);
            if (d1 < KYBER_Q) p->coeffs[ctr++] = (int16_t)d1;
            if (ctr < KYBER_N && d2 < KYBER_Q) p->coeffs[ctr++] = (int16_t)d2;
        }
    }
}

static void cbd(poly *p, const uint8_t *buf, int eta) {
    /* Centered Binomial Distribution with parameter eta. Buf size = eta * N / 4. */
    if (eta == 2) {
        for (unsigned i = 0; i < KYBER_N/8; i++) {
            uint32_t t = (uint32_t)buf[4*i] | ((uint32_t)buf[4*i+1] << 8)
                       | ((uint32_t)buf[4*i+2] << 16) | ((uint32_t)buf[4*i+3] << 24);
            uint32_t d = t & 0x55555555u;
            d += (t >> 1) & 0x55555555u;
            for (unsigned j = 0; j < 8; j++) {
                int16_t a = (int16_t)((d >> (4*j)) & 0x3);
                int16_t b = (int16_t)((d >> (4*j + 2)) & 0x3);
                p->coeffs[8*i + j] = (int16_t)(a - b);
                if (p->coeffs[8*i+j] < 0) p->coeffs[8*i+j] += KYBER_Q;
            }
        }
    } else { /* eta == 3 */
        for (unsigned i = 0; i < KYBER_N/4; i++) {
            uint32_t t = (uint32_t)buf[3*i] | ((uint32_t)buf[3*i+1] << 8) | ((uint32_t)buf[3*i+2] << 16);
            uint32_t d = t & 0x00249249u;
            d += (t >> 1) & 0x00249249u;
            d += (t >> 2) & 0x00249249u;
            for (unsigned j = 0; j < 4; j++) {
                int16_t a = (int16_t)((d >> (6*j))     & 0x7);
                int16_t b = (int16_t)((d >> (6*j + 3)) & 0x7);
                p->coeffs[4*i + j] = (int16_t)(a - b);
                if (p->coeffs[4*i+j] < 0) p->coeffs[4*i+j] += KYBER_Q;
            }
        }
    }
}

static void poly_getnoise(poly *p, const uint8_t seed[32], uint8_t nonce, int eta) {
    uint8_t input[33]; memcpy(input, seed, 32); input[32] = nonce;
    uint8_t buf[3 * KYBER_N / 4]; /* enough for eta=3 */
    iii_shake256(input, 33, buf, (size_t)eta * KYBER_N / 4);
    cbd(p, buf, eta);
}

/* ---- Encode / decode ---- */
static void poly_tobytes(uint8_t r[384], const poly *p) {
    for (unsigned i = 0; i < KYBER_N/2; i++) {
        uint16_t t0 = (uint16_t)((p->coeffs[2*i]   + KYBER_Q) % KYBER_Q);
        uint16_t t1 = (uint16_t)((p->coeffs[2*i+1] + KYBER_Q) % KYBER_Q);
        r[3*i]   = (uint8_t)(t0);
        r[3*i+1] = (uint8_t)((t0 >> 8) | (t1 << 4));
        r[3*i+2] = (uint8_t)(t1 >> 4);
    }
}
static void poly_frombytes(poly *p, const uint8_t r[384]) {
    for (unsigned i = 0; i < KYBER_N/2; i++) {
        p->coeffs[2*i]   = (int16_t)((r[3*i] | ((uint16_t)r[3*i+1] << 8)) & 0xfff);
        p->coeffs[2*i+1] = (int16_t)((r[3*i+1] >> 4) | ((uint16_t)r[3*i+2] << 4));
    }
}

static void poly_compress_dv(uint8_t *r, const poly *p, int dv) {
    /* compress each coefficient to dv bits */
    int16_t t[8]; uint8_t buf;
    if (dv == 4) {
        for (unsigned i = 0; i < KYBER_N/2; i++) {
            for (int j = 0; j < 2; j++) {
                int32_t x = ((int32_t)p->coeffs[2*i+j] << 4) + KYBER_Q/2;
                t[j] = (int16_t)((x / KYBER_Q) & 0xf);
            }
            r[i] = (uint8_t)(t[0] | (t[1] << 4));
        }
    } else { /* dv == 5 */
        for (unsigned i = 0; i < KYBER_N/8; i++) {
            for (int j = 0; j < 8; j++) {
                int32_t x = ((int32_t)p->coeffs[8*i+j] << 5) + KYBER_Q/2;
                t[j] = (int16_t)((x / KYBER_Q) & 0x1f);
            }
            r[5*i  ] = (uint8_t)(t[0]      | (t[1] << 5));
            r[5*i+1] = (uint8_t)((t[1]>>3) | (t[2] << 2) | (t[3] << 7));
            r[5*i+2] = (uint8_t)((t[3]>>1) | (t[4] << 4));
            r[5*i+3] = (uint8_t)((t[4]>>4) | (t[5] << 1) | (t[6] << 6));
            r[5*i+4] = (uint8_t)((t[6]>>2) | (t[7] << 3));
            (void)buf;
        }
    }
}

static void poly_decompress_dv(poly *p, const uint8_t *r, int dv) {
    if (dv == 4) {
        for (unsigned i = 0; i < KYBER_N/2; i++) {
            p->coeffs[2*i]   = (int16_t)(((uint32_t)(r[i] & 0xf) * KYBER_Q + 8) >> 4);
            p->coeffs[2*i+1] = (int16_t)(((uint32_t)(r[i] >> 4)  * KYBER_Q + 8) >> 4);
        }
    } else { /* dv = 5 */
        for (unsigned i = 0; i < KYBER_N/8; i++) {
            uint16_t t[8];
            t[0] = r[5*i]            & 0x1f;
            t[1] = ((r[5*i]   >> 5) | ((uint16_t)r[5*i+1] << 3)) & 0x1f;
            t[2] = (r[5*i+1]  >> 2) & 0x1f;
            t[3] = ((r[5*i+1] >> 7) | ((uint16_t)r[5*i+2] << 1)) & 0x1f;
            t[4] = ((r[5*i+2] >> 4) | ((uint16_t)r[5*i+3] << 4)) & 0x1f;
            t[5] =  (r[5*i+3] >> 1) & 0x1f;
            t[6] = ((r[5*i+3] >> 6) | ((uint16_t)r[5*i+4] << 2)) & 0x1f;
            t[7] =  (r[5*i+4] >> 3) & 0x1f;
            for (int j = 0; j < 8; j++)
                p->coeffs[8*i+j] = (int16_t)(((uint32_t)t[j] * KYBER_Q + 16) >> 5);
        }
    }
}

static void polyvec_compress_du(uint8_t *r, const poly *pv, int kvec, int du) {
    /* du=10 or 11 */
    if (du == 10) {
        for (int p = 0; p < kvec; p++) {
            const poly *pp = &pv[p];
            uint8_t *out = r + p * 320;
            for (unsigned i = 0; i < KYBER_N/4; i++) {
                uint16_t t[4];
                for (int j = 0; j < 4; j++) {
                    int32_t x = ((int32_t)pp->coeffs[4*i+j] << 10) + KYBER_Q/2;
                    t[j] = (uint16_t)((x / KYBER_Q) & 0x3ff);
                }
                out[5*i]   = (uint8_t)t[0];
                out[5*i+1] = (uint8_t)((t[0] >> 8) | (t[1] << 2));
                out[5*i+2] = (uint8_t)((t[1] >> 6) | (t[2] << 4));
                out[5*i+3] = (uint8_t)((t[2] >> 4) | (t[3] << 6));
                out[5*i+4] = (uint8_t)(t[3] >> 2);
            }
        }
    } else { /* du = 11 */
        for (int p = 0; p < kvec; p++) {
            const poly *pp = &pv[p];
            uint8_t *out = r + p * 352;
            for (unsigned i = 0; i < KYBER_N/8; i++) {
                uint16_t t[8];
                for (int j = 0; j < 8; j++) {
                    int32_t x = ((int32_t)pp->coeffs[8*i+j] << 11) + KYBER_Q/2;
                    t[j] = (uint16_t)((x / KYBER_Q) & 0x7ff);
                }
                out[11*i]    = (uint8_t)(t[0]);
                out[11*i+1]  = (uint8_t)((t[0]>>8) | (t[1] << 3));
                out[11*i+2]  = (uint8_t)((t[1]>>5) | (t[2] << 6));
                out[11*i+3]  = (uint8_t)(t[2]>>2);
                out[11*i+4]  = (uint8_t)((t[2]>>10)| (t[3] << 1));
                out[11*i+5]  = (uint8_t)((t[3]>>7) | (t[4] << 4));
                out[11*i+6]  = (uint8_t)((t[4]>>4) | (t[5] << 7));
                out[11*i+7]  = (uint8_t)(t[5]>>1);
                out[11*i+8]  = (uint8_t)((t[5]>>9) | (t[6] << 2));
                out[11*i+9]  = (uint8_t)((t[6]>>6) | (t[7] << 5));
                out[11*i+10] = (uint8_t)(t[7]>>3);
            }
        }
    }
}

static void polyvec_decompress_du(poly *pv, const uint8_t *r, int kvec, int du) {
    if (du == 10) {
        for (int p = 0; p < kvec; p++) {
            poly *pp = &pv[p];
            const uint8_t *in = r + p * 320;
            for (unsigned i = 0; i < KYBER_N/4; i++) {
                uint16_t t[4];
                t[0] =  (uint16_t)in[5*i]                    | (((uint16_t)in[5*i+1] & 0x3) << 8);
                t[1] = ((uint16_t)in[5*i+1] >> 2)            | (((uint16_t)in[5*i+2] & 0xf) << 6);
                t[2] = ((uint16_t)in[5*i+2] >> 4)            | (((uint16_t)in[5*i+3] & 0x3f)<< 4);
                t[3] = ((uint16_t)in[5*i+3] >> 6)            | (((uint16_t)in[5*i+4]      ) << 2);
                for (int j = 0; j < 4; j++)
                    pp->coeffs[4*i+j] = (int16_t)(((uint32_t)t[j] * KYBER_Q + 512) >> 10);
            }
        }
    } else {
        for (int p = 0; p < kvec; p++) {
            poly *pp = &pv[p];
            const uint8_t *in = r + p * 352;
            for (unsigned i = 0; i < KYBER_N/8; i++) {
                uint16_t t[8];
                t[0] =  (uint16_t)in[11*i]                    | (((uint16_t)in[11*i+1] & 0x07) << 8);
                t[1] = ((uint16_t)in[11*i+1] >> 3)            | (((uint16_t)in[11*i+2] & 0x3f) << 5);
                t[2] = ((uint16_t)in[11*i+2] >> 6)            | ((uint16_t)in[11*i+3] << 2)
                                                              | (((uint16_t)in[11*i+4] & 0x01) << 10);
                t[3] = ((uint16_t)in[11*i+4] >> 1)            | (((uint16_t)in[11*i+5] & 0x0f) << 7);
                t[4] = ((uint16_t)in[11*i+5] >> 4)            | (((uint16_t)in[11*i+6] & 0x7f) << 4);
                t[5] = ((uint16_t)in[11*i+6] >> 7)            | ((uint16_t)in[11*i+7] << 1)
                                                              | (((uint16_t)in[11*i+8] & 0x03) << 9);
                t[6] = ((uint16_t)in[11*i+8] >> 2)            | (((uint16_t)in[11*i+9] & 0x1f) << 6);
                t[7] = ((uint16_t)in[11*i+9] >> 5)            | ((uint16_t)in[11*i+10] << 3);
                for (int j = 0; j < 8; j++) {
                    t[j] &= 0x7ff;
                    pp->coeffs[8*i+j] = (int16_t)(((uint32_t)t[j] * KYBER_Q + 1024) >> 11);
                }
            }
        }
    }
}

static void poly_frommsg(poly *p, const uint8_t msg[32]) {
    for (unsigned i = 0; i < 32; i++) {
        for (int j = 0; j < 8; j++) {
            int16_t mask = -(int16_t)((msg[i] >> j) & 1);
            p->coeffs[8*i + j] = mask & ((KYBER_Q + 1) / 2);
        }
    }
}

static void poly_tomsg(uint8_t msg[32], const poly *p) {
    for (unsigned i = 0; i < 32; i++) {
        msg[i] = 0;
        for (int j = 0; j < 8; j++) {
            int32_t t = ((p->coeffs[8*i+j] + KYBER_Q) % KYBER_Q);
            t = ((t << 1) + KYBER_Q/2) / KYBER_Q;
            t &= 1;
            msg[i] |= (uint8_t)(t << j);
        }
    }
}

/* ---- Polyvec wrappers ---- */
static void polyvec_add(poly *r, const poly *a, const poly *b, int k) {
    for (int i = 0; i < k; i++)
        for (int j = 0; j < KYBER_N; j++) {
            int16_t v = (int16_t)((a[i].coeffs[j] + b[i].coeffs[j]) % KYBER_Q);
            if (v < 0) v += KYBER_Q;
            r[i].coeffs[j] = v;
        }
}

static void polyvec_ntt(poly *pv, int k) { for (int i=0;i<k;i++) ntt(&pv[i]); }
static void polyvec_invntt(poly *pv, int k) { for (int i=0;i<k;i++) invntt(&pv[i]); }
static void polyvec_tobytes(uint8_t *r, const poly *pv, int k) {
    for (int i = 0; i < k; i++) poly_tobytes(r + 384*i, &pv[i]);
}
static void polyvec_frombytes(poly *pv, const uint8_t *r, int k) {
    for (int i = 0; i < k; i++) poly_frombytes(&pv[i], r + 384*i);
}

static void polyvec_pointwise_acc(poly *r, const poly *a, const poly *b, int k) {
    poly t;
    poly_basemul_acc(r, &a[0], &b[0]);
    for (int i = 1; i < k; i++) {
        poly_basemul_acc(&t, &a[i], &b[i]);
        for (int j = 0; j < KYBER_N; j++) {
            int16_t v = (int16_t)((r->coeffs[j] + t.coeffs[j]) % KYBER_Q);
            if (v < 0) v += KYBER_Q;
            r->coeffs[j] = v;
        }
    }
}

/* ---- K-PKE ---- */
static void gen_matrix(poly *A /* k*k */, const uint8_t rho[32], int k, int transposed) {
    for (int i = 0; i < k; i++)
        for (int j = 0; j < k; j++)
            poly_uniform(&A[i*k + j], rho,
                         (uint8_t)(transposed ? i : j),
                         (uint8_t)(transposed ? j : i));
}

static void kpke_keygen(uint8_t *pk, uint8_t *sk_pke,
                        const uint8_t seed[32], int k) {
    uint8_t buf[64], rho[32], sigma[32];
    /* G = SHA3-512(seed || k) */
    uint8_t input[33]; memcpy(input, seed, 32); input[32] = (uint8_t)k;
    iii_sha3_512(input, 33, buf);
    memcpy(rho, buf, 32); memcpy(sigma, buf+32, 32);

    poly A[16]; /* up to 4*4 */
    gen_matrix(A, rho, k, 0);

    poly s[4], e[4];
    int eta1 = param_eta1(k);
    for (int i = 0; i < k; i++) poly_getnoise(&s[i], sigma, (uint8_t)i, eta1);
    for (int i = 0; i < k; i++) poly_getnoise(&e[i], sigma, (uint8_t)(i+k), eta1);

    polyvec_ntt(s, k);
    polyvec_ntt(e, k);

    poly t[4];
    for (int i = 0; i < k; i++) {
        polyvec_pointwise_acc(&t[i], &A[i*k], s, k);
    }
    polyvec_add(t, t, e, k);

    polyvec_tobytes(pk, t, k);
    memcpy(pk + 384*k, rho, 32);
    polyvec_tobytes(sk_pke, s, k);
}

static void kpke_enc(uint8_t *ct, const uint8_t *pk,
                     const uint8_t msg[32], const uint8_t coins[32], int k) {
    poly t[4];
    polyvec_frombytes(t, pk, k);
    const uint8_t *rho = pk + 384*k;

    poly At[16];
    gen_matrix(At, rho, k, 1);

    poly r[4], e1[4], e2;
    int eta1 = param_eta1(k), eta2 = param_eta2(k);
    for (int i = 0; i < k; i++) poly_getnoise(&r[i],  coins, (uint8_t)i, eta1);
    for (int i = 0; i < k; i++) poly_getnoise(&e1[i], coins, (uint8_t)(i+k), eta2);
    poly_getnoise(&e2, coins, (uint8_t)(2*k), eta2);

    polyvec_ntt(r, k);

    poly u[4];
    for (int i = 0; i < k; i++) polyvec_pointwise_acc(&u[i], &At[i*k], r, k);
    polyvec_invntt(u, k);
    polyvec_add(u, u, e1, k);

    poly v;
    polyvec_pointwise_acc(&v, t, r, k);
    invntt(&v);
    /* v += e2 + Decompress(msg) */
    poly mp; poly_frommsg(&mp, msg);
    for (int j = 0; j < KYBER_N; j++) {
        int16_t s = (int16_t)((v.coeffs[j] + e2.coeffs[j] + mp.coeffs[j]) % KYBER_Q);
        if (s < 0) s += KYBER_Q;
        v.coeffs[j] = s;
    }

    int du = param_du(k), dv = param_dv(k);
    polyvec_compress_du(ct, u, k, du);
    poly_compress_dv(ct + (du == 10 ? 320 : 352)*k, &v, dv);
}

static void kpke_dec(uint8_t msg[32], const uint8_t *sk_pke,
                     const uint8_t *ct, int k) {
    int du = param_du(k), dv = param_dv(k);
    poly u[4], v;
    polyvec_decompress_du(u, ct, k, du);
    poly_decompress_dv(&v, ct + (du == 10 ? 320 : 352)*k, dv);

    poly s[4];
    polyvec_frombytes(s, sk_pke, k);

    polyvec_ntt(u, k);
    poly mp;
    polyvec_pointwise_acc(&mp, s, u, k);
    invntt(&mp);
    /* mp = v - mp */
    for (int j = 0; j < KYBER_N; j++) {
        int16_t s2 = (int16_t)((v.coeffs[j] - mp.coeffs[j]) % KYBER_Q);
        if (s2 < 0) s2 += KYBER_Q;
        mp.coeffs[j] = s2;
    }
    poly_tomsg(msg, &mp);
}

/* ---- ML-KEM (Fujisaki-Okamoto wrapper) ---- */
int iii_mlkem_keygen(int k, const uint8_t seed[64], uint8_t *pk, uint8_t *sk) {
    if (k < 2 || k > 4) return -1;
    const uint8_t *d = seed;
    const uint8_t *z = seed + 32;
    size_t pk_bytes = 384*k + 32;
    size_t sk_pke = 384*k;
    kpke_keygen(pk, sk, d, k);
    /* sk = sk_pke || pk || H(pk) || z */
    memcpy(sk + sk_pke, pk, pk_bytes);
    iii_sha3_256(pk, pk_bytes, sk + sk_pke + pk_bytes);
    memcpy(sk + sk_pke + pk_bytes + 32, z, 32);
    return 0;
}

static size_t ct_bytes_for(int k) {
    int du = param_du(k), dv = param_dv(k);
    return (du == 10 ? 320 : 352)*k + (dv == 4 ? 128 : 160);
}

int iii_mlkem_encaps(int k, const uint8_t *pk, const uint8_t coins[32],
                     uint8_t *ct, uint8_t ss[32]) {
    if (k < 2 || k > 4) return -1;
    size_t pk_bytes = 384*k + 32;
    /* m = coins (treat as already-randomized message) */
    /* (K, r) = G(m || H(pk)) */
    uint8_t hpk[32]; iii_sha3_256(pk, pk_bytes, hpk);
    uint8_t buf[64]; memcpy(buf, coins, 32); memcpy(buf+32, hpk, 32);
    uint8_t Kr[64]; iii_sha3_512(buf, 64, Kr);
    kpke_enc(ct, pk, coins, Kr + 32, k);
    /* SS = K (FIPS 203 final spec uses K directly without further KDF when implicit-rejection-aware).
     * Per FIPS 203 §6.4, K is the shared secret. */
    memcpy(ss, Kr, 32);
    return 0;
}

int iii_mlkem_decaps(int k, const uint8_t *sk, const uint8_t *ct, uint8_t ss[32]) {
    if (k < 2 || k > 4) return -1;
    size_t pk_bytes = 384*k + 32;
    size_t sk_pke = 384*k;
    const uint8_t *pk = sk + sk_pke;
    const uint8_t *hpk = sk + sk_pke + pk_bytes;
    const uint8_t *z = sk + sk_pke + pk_bytes + 32;
    size_t ctlen = ct_bytes_for(k);

    uint8_t m_prime[32];
    kpke_dec(m_prime, sk, ct, k);

    uint8_t buf[64]; memcpy(buf, m_prime, 32); memcpy(buf+32, hpk, 32);
    uint8_t Kr[64]; iii_sha3_512(buf, 64, Kr);

    /* Re-encrypt and compare */
    uint8_t ct_check[1568];
    kpke_enc(ct_check, pk, m_prime, Kr + 32, k);
    uint8_t diff = 0;
    for (size_t i = 0; i < ctlen; i++) diff |= ct[i] ^ ct_check[i];
    if (diff == 0) {
        memcpy(ss, Kr, 32);
    } else {
        /* implicit reject: SS = SHAKE-256(z || ct, 32) */
        iii_keccak_ctx_t c;
        iii_keccak_init(&c, 136, 0x1f);
        iii_keccak_absorb(&c, z, 32);
        iii_keccak_absorb(&c, ct, ctlen);
        iii_keccak_squeeze(&c, ss, 32);
    }
    return 0;
}
