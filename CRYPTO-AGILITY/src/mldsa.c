/* FIPS 204 ML-DSA (Dilithium) reference implementation, hand-rolled.
 *
 * Parameters (level → k, l, eta, tau, beta, gamma1, gamma2, omega):
 *   ML-DSA-44: k=4, l=4, eta=2, tau=39, gamma1=2^17, gamma2=(q-1)/88, omega=80
 *   ML-DSA-65: k=6, l=5, eta=4, tau=49, gamma1=2^19, gamma2=(q-1)/32, omega=55
 *   ML-DSA-87: k=8, l=7, eta=2, tau=60, gamma1=2^19, gamma2=(q-1)/32, omega=75
 *
 * q = 8380417, n = 256, d = 13.
 */
#include "iii/mldsa.h"
#include "iii/sha3.h"
#include <string.h>

#define MLDSA_N 256
#define MLDSA_Q 8380417
#define MLDSA_D 13
#define MLDSA_SEEDBYTES 32
#define MLDSA_CRHBYTES  64
#define MLDSA_TR_BYTES  64

typedef struct { int32_t coeffs[MLDSA_N]; } poly;

typedef struct {
    int k, l, eta, tau, gamma1_log, gamma2_div, omega;
    int gamma1; /* = 1<<gamma1_log */
    int gamma2;
    int beta;   /* = tau*eta */
    int polyz_packed; /* bytes per poly z */
    int polyw1_packed;
    int polyeta_packed;
} mldsa_params;

static void mldsa_get_params(int level, mldsa_params *P) {
    memset(P, 0, sizeof *P);
    if (level == 2)        { P->k=4; P->l=4; P->eta=2; P->tau=39; P->gamma1_log=17; P->gamma2_div=88; P->omega=80; }
    else if (level == 3)   { P->k=6; P->l=5; P->eta=4; P->tau=49; P->gamma1_log=19; P->gamma2_div=32; P->omega=55; }
    else                   { P->k=8; P->l=7; P->eta=2; P->tau=60; P->gamma1_log=19; P->gamma2_div=32; P->omega=75; }
    P->gamma1 = 1 << P->gamma1_log;
    P->gamma2 = (MLDSA_Q - 1) / P->gamma2_div;
    P->beta   = P->tau * P->eta;
    P->polyz_packed   = (P->gamma1_log == 17) ? 576 : 640;
    P->polyw1_packed  = (P->gamma2_div == 88) ? 192 : 128;
    P->polyeta_packed = (P->eta == 2) ? 96 : 128;
}

/* ---- Modular reduction ---- */
static int32_t reduce32(int32_t a) {
    int32_t t = (a + (1<<22)) >> 23;
    return a - t * MLDSA_Q;
}
static int32_t caddq(int32_t a) { return a + ((a >> 31) & MLDSA_Q); }

/* ---- NTT (length-256 negacyclic over Z_q) ----
 * Compute zetas dynamically using primitive 512-th root of unity 1753 mod q. */
static int32_t Z[256];
static int Z_init = 0;
static int32_t pow_mod(int32_t base, uint32_t exp) {
    int64_t r = 1, b = base;
    while (exp) {
        if (exp & 1) r = (r * b) % MLDSA_Q;
        b = (b * b) % MLDSA_Q;
        exp >>= 1;
    }
    return (int32_t)r;
}
static void init_zetas(void) {
    if (Z_init) return;
    /* zetas[i] = zeta^brv(i) where brv = bit-reverse 8 bits */
    int32_t zeta = 1753;
    for (int i = 0; i < 256; i++) {
        unsigned br = 0, x = (unsigned)i;
        for (int b = 0; b < 8; b++) { br = (br << 1) | (x & 1); x >>= 1; }
        Z[i] = pow_mod(zeta, br);
    }
    Z_init = 1;
}

static void ntt(poly *p) {
    init_zetas();
    unsigned len, start, j, k = 0;
    for (len = 128; len > 0; len >>= 1) {
        for (start = 0; start < MLDSA_N; start = j + len) {
            int32_t z = Z[++k];
            for (j = start; j < start + len; j++) {
                int32_t t = (int32_t)(((int64_t)z * p->coeffs[j+len]) % MLDSA_Q);
                int32_t a = p->coeffs[j];
                p->coeffs[j+len] = (a - t) % MLDSA_Q;
                p->coeffs[j]     = (a + t) % MLDSA_Q;
            }
        }
    }
    for (j = 0; j < MLDSA_N; j++) p->coeffs[j] = caddq(p->coeffs[j]);
}

static void invntt(poly *p) {
    init_zetas();
    unsigned len, start, j, k = 256;
    for (len = 1; len < MLDSA_N; len <<= 1) {
        for (start = 0; start < MLDSA_N; start = j + len) {
            int32_t z = -Z[--k];
            for (j = start; j < start + len; j++) {
                int32_t t = p->coeffs[j];
                p->coeffs[j]     = (t + p->coeffs[j+len]) % MLDSA_Q;
                p->coeffs[j+len] = (int32_t)(((int64_t)z * (t - p->coeffs[j+len])) % MLDSA_Q);
            }
        }
    }
    /* multiply by 256^-1 mod q */
    int32_t f = pow_mod(MLDSA_N, MLDSA_Q - 2);
    for (j = 0; j < MLDSA_N; j++) {
        p->coeffs[j] = (int32_t)(((int64_t)f * p->coeffs[j]) % MLDSA_Q);
        p->coeffs[j] = caddq(p->coeffs[j]);
    }
}

static void poly_pointwise(poly *r, const poly *a, const poly *b) {
    for (int i = 0; i < MLDSA_N; i++)
        r->coeffs[i] = (int32_t)(((int64_t)a->coeffs[i] * b->coeffs[i]) % MLDSA_Q);
}
static void poly_add(poly *r, const poly *a, const poly *b) {
    for (int i = 0; i < MLDSA_N; i++) r->coeffs[i] = a->coeffs[i] + b->coeffs[i];
}
static void poly_sub(poly *r, const poly *a, const poly *b) {
    for (int i = 0; i < MLDSA_N; i++) r->coeffs[i] = a->coeffs[i] - b->coeffs[i];
}
static void poly_reduce(poly *p) {
    for (int i = 0; i < MLDSA_N; i++) p->coeffs[i] = reduce32(p->coeffs[i]);
}
static void poly_caddq(poly *p) { for (int i=0;i<MLDSA_N;i++) p->coeffs[i] = caddq(p->coeffs[i]); }

/* ---- Sampling ---- */
static void poly_uniform(poly *p, const uint8_t seed[32], uint16_t nonce) {
    uint8_t input[34]; memcpy(input, seed, 32);
    input[32] = (uint8_t)nonce; input[33] = (uint8_t)(nonce >> 8);
    iii_keccak_ctx_t c; iii_keccak_init(&c, 168, 0x1f);
    iii_keccak_absorb(&c, input, 34); iii_keccak_finalize(&c);
    int ctr = 0;
    uint8_t buf[168];
    while (ctr < MLDSA_N) {
        iii_keccak_squeeze(&c, buf, 168);
        for (int i = 0; i + 3 <= 168 && ctr < MLDSA_N; i += 3) {
            uint32_t t = (uint32_t)buf[i] | ((uint32_t)buf[i+1] << 8) | (((uint32_t)buf[i+2] & 0x7f) << 16);
            if (t < MLDSA_Q) p->coeffs[ctr++] = (int32_t)t;
        }
    }
}

static void poly_uniform_eta(poly *p, const uint8_t seed[64], uint16_t nonce, int eta) {
    uint8_t input[66]; memcpy(input, seed, 64);
    input[64] = (uint8_t)nonce; input[65] = (uint8_t)(nonce >> 8);
    iii_keccak_ctx_t c; iii_keccak_init(&c, 136, 0x1f);
    iii_keccak_absorb(&c, input, 66); iii_keccak_finalize(&c);
    int ctr = 0;
    uint8_t buf[136];
    while (ctr < MLDSA_N) {
        iii_keccak_squeeze(&c, buf, 136);
        for (int i = 0; i < 136 && ctr < MLDSA_N; i++) {
            int t0 = buf[i] & 0x0f;
            int t1 = buf[i] >> 4;
            if (eta == 2) {
                if (t0 < 15) { t0 = 2 - (t0 % 5); p->coeffs[ctr++] = t0; }
                if (ctr < MLDSA_N && t1 < 15) { t1 = 2 - (t1 % 5); p->coeffs[ctr++] = t1; }
            } else { /* eta == 4 */
                if (t0 < 9) { p->coeffs[ctr++] = 4 - t0; }
                if (ctr < MLDSA_N && t1 < 9) { p->coeffs[ctr++] = 4 - t1; }
            }
        }
    }
}

static void poly_uniform_gamma1(poly *p, const uint8_t seed[64], uint16_t nonce, int gamma1_log) {
    /* sample y in (-gamma1, gamma1] */
    uint8_t input[66]; memcpy(input, seed, 64);
    input[64] = (uint8_t)nonce; input[65] = (uint8_t)(nonce >> 8);
    int polysize = (gamma1_log == 17) ? 576 : 640; /* not actually needed here */
    (void)polysize;
    iii_keccak_ctx_t c; iii_keccak_init(&c, 136, 0x1f);
    iii_keccak_absorb(&c, input, 66); iii_keccak_finalize(&c);
    /* read enough bytes */
    int bytes_per = (gamma1_log == 17) ? 18 : 20;
    int total_bytes = MLDSA_N / 4 * bytes_per;
    uint8_t *buf = (uint8_t*)__builtin_alloca(total_bytes);
    iii_keccak_squeeze(&c, buf, total_bytes);
    int gamma1 = 1 << gamma1_log;
    for (int i = 0; i < MLDSA_N/4; i++) {
        if (gamma1_log == 17) {
            uint32_t v0 =  (uint32_t)buf[18*i+0]        | ((uint32_t)buf[18*i+1] << 8) | (((uint32_t)buf[18*i+2] & 0x03) << 16);
            uint32_t v1 = ((uint32_t)buf[18*i+2] >> 2)  | ((uint32_t)buf[18*i+3] << 6) | (((uint32_t)buf[18*i+4] & 0x0f) << 14);
            uint32_t v2 = ((uint32_t)buf[18*i+4] >> 4)  | ((uint32_t)buf[18*i+5] << 4) | (((uint32_t)buf[18*i+6] & 0x3f) << 12);
            uint32_t v3 = ((uint32_t)buf[18*i+6] >> 6)  | ((uint32_t)buf[18*i+7] << 2) | ((uint32_t)buf[18*i+8] << 10);
            v0 &= 0x3ffff; v1 &= 0x3ffff; v2 &= 0x3ffff; v3 &= 0x3ffff;
            p->coeffs[4*i+0] = gamma1 - (int32_t)v0;
            p->coeffs[4*i+1] = gamma1 - (int32_t)v1;
            p->coeffs[4*i+2] = gamma1 - (int32_t)v2;
            p->coeffs[4*i+3] = gamma1 - (int32_t)v3;
        } else {
            /* 20 bits each */
            uint32_t v0 =  (uint32_t)buf[20*i+0]        | ((uint32_t)buf[20*i+1] << 8) | (((uint32_t)buf[20*i+2] & 0x0f) << 16);
            uint32_t v1 = ((uint32_t)buf[20*i+2] >> 4)  | ((uint32_t)buf[20*i+3] << 4) | ((uint32_t)buf[20*i+4] << 12);
            uint32_t v2 =  (uint32_t)buf[20*i+5]        | ((uint32_t)buf[20*i+6] << 8) | (((uint32_t)buf[20*i+7] & 0x0f) << 16);
            uint32_t v3 = ((uint32_t)buf[20*i+7] >> 4)  | ((uint32_t)buf[20*i+8] << 4) | ((uint32_t)buf[20*i+9] << 12);
            v0 &= 0xfffff; v1 &= 0xfffff; v2 &= 0xfffff; v3 &= 0xfffff;
            p->coeffs[4*i+0] = gamma1 - (int32_t)v0;
            p->coeffs[4*i+1] = gamma1 - (int32_t)v1;
            p->coeffs[4*i+2] = gamma1 - (int32_t)v2;
            p->coeffs[4*i+3] = gamma1 - (int32_t)v3;
        }
    }
}

/* SampleInBall: produce a polynomial with tau coefficients in {-1,+1}, others 0. */
static void challenge(poly *c, const uint8_t seed[32], int tau) {
    iii_keccak_ctx_t ctx; iii_keccak_init(&ctx, 136, 0x1f);
    iii_keccak_absorb(&ctx, seed, 32); iii_keccak_finalize(&ctx);
    uint8_t buf[136]; iii_keccak_squeeze(&ctx, buf, 8);
    uint64_t signs = 0;
    for (int i = 0; i < 8; i++) signs |= (uint64_t)buf[i] << (8*i);
    memset(c->coeffs, 0, sizeof c->coeffs);
    int pos = 8, blen = 8;
    for (int i = MLDSA_N - tau; i < MLDSA_N; i++) {
        int b;
        do {
            if (pos >= blen) { iii_keccak_squeeze(&ctx, buf, 136); pos = 0; blen = 136; }
            b = buf[pos++];
        } while (b > i);
        c->coeffs[i] = c->coeffs[b];
        c->coeffs[b] = (signs & 1) ? -1 : 1;
        signs >>= 1;
    }
}

/* ---- Decompose / Power2Round / norms ---- */
static int32_t power2round(int32_t a, int32_t *a0) {
    int32_t a1 = (a + (1 << (MLDSA_D-1)) - 1) >> MLDSA_D;
    *a0 = a - (a1 << MLDSA_D);
    return a1;
}

static int32_t decompose(int32_t a, int32_t *a0, int gamma2) {
    int32_t a1;
    a1 = (a + 127) >> 7;
    if (gamma2 == (MLDSA_Q-1)/32) {
        a1 = (a1 * 1025 + (1 << 21)) >> 22;
        a1 &= 15;
    } else { /* (q-1)/88 */
        a1 = (a1 * 11275 + (1 << 23)) >> 24;
        a1 ^= ((43 - a1) >> 31) & a1;
    }
    *a0 = a - a1 * 2 * gamma2;
    *a0 -= (((MLDSA_Q-1)/2 - *a0) >> 31) & MLDSA_Q;
    return a1;
}

static int32_t make_hint(int32_t a0, int32_t a1, int gamma2) {
    if (a0 > gamma2 || a0 < -gamma2 || (a0 == -gamma2 && a1 != 0)) return 1;
    return 0;
}

static int32_t use_hint(int32_t a, int32_t hint, int gamma2) {
    int32_t a0, a1;
    a1 = decompose(a, &a0, gamma2);
    if (hint == 0) return a1;
    if (gamma2 == (MLDSA_Q-1)/32) {
        if (a0 > 0) return (a1 + 1) & 15;
        else        return (a1 - 1) & 15;
    } else {
        if (a0 > 0) return (a1 == 43) ? 0 : a1 + 1;
        else        return (a1 == 0)  ? 43 : a1 - 1;
    }
}

static int poly_chknorm(const poly *p, int32_t bound) {
    if (bound > (MLDSA_Q-1)/8) return 1;
    for (int i = 0; i < MLDSA_N; i++) {
        int32_t t = p->coeffs[i];
        t -= (((MLDSA_Q-1)/2 - t) >> 31) & MLDSA_Q;
        t = t < 0 ? -t : t;
        if (t >= bound) return 1;
    }
    return 0;
}

/* ---- Pack/unpack ---- */
static void polyt1_pack(uint8_t *r, const poly *a) {
    for (int i = 0; i < MLDSA_N/4; i++) {
        uint32_t t0 = a->coeffs[4*i+0];
        uint32_t t1 = a->coeffs[4*i+1];
        uint32_t t2 = a->coeffs[4*i+2];
        uint32_t t3 = a->coeffs[4*i+3];
        r[5*i+0] = (uint8_t)(t0);
        r[5*i+1] = (uint8_t)((t0 >> 8) | (t1 << 2));
        r[5*i+2] = (uint8_t)((t1 >> 6) | (t2 << 4));
        r[5*i+3] = (uint8_t)((t2 >> 4) | (t3 << 6));
        r[5*i+4] = (uint8_t)(t3 >> 2);
    }
}
static void polyt1_unpack(poly *a, const uint8_t *r) {
    for (int i = 0; i < MLDSA_N/4; i++) {
        a->coeffs[4*i+0] = ((uint32_t)r[5*i+0]      | ((uint32_t)r[5*i+1] << 8)) & 0x3ff;
        a->coeffs[4*i+1] = (((uint32_t)r[5*i+1]>>2) | ((uint32_t)r[5*i+2] << 6)) & 0x3ff;
        a->coeffs[4*i+2] = (((uint32_t)r[5*i+2]>>4) | ((uint32_t)r[5*i+3] << 4)) & 0x3ff;
        a->coeffs[4*i+3] = (((uint32_t)r[5*i+3]>>6) | ((uint32_t)r[5*i+4] << 2)) & 0x3ff;
    }
}
static void polyt0_pack(uint8_t *r, const poly *a) {
    /* 13 bits per coeff, signed in (-2^12, 2^12]. Encode as 2^12 - x. */
    for (int i = 0; i < MLDSA_N/8; i++) {
        uint32_t t[8];
        for (int j = 0; j < 8; j++) t[j] = (1 << (MLDSA_D-1)) - a->coeffs[8*i+j];
        r[13*i+ 0] = (uint8_t)(t[0]);
        r[13*i+ 1] = (uint8_t)((t[0]>>8)  | (t[1]<<5));
        r[13*i+ 2] = (uint8_t)((t[1]>>3));
        r[13*i+ 3] = (uint8_t)((t[1]>>11) | (t[2]<<2));
        r[13*i+ 4] = (uint8_t)((t[2]>>6)  | (t[3]<<7));
        r[13*i+ 5] = (uint8_t)((t[3]>>1));
        r[13*i+ 6] = (uint8_t)((t[3]>>9)  | (t[4]<<4));
        r[13*i+ 7] = (uint8_t)((t[4]>>4));
        r[13*i+ 8] = (uint8_t)((t[4]>>12) | (t[5]<<1));
        r[13*i+ 9] = (uint8_t)((t[5]>>7)  | (t[6]<<6));
        r[13*i+10] = (uint8_t)((t[6]>>2));
        r[13*i+11] = (uint8_t)((t[6]>>10) | (t[7]<<3));
        r[13*i+12] = (uint8_t)((t[7]>>5));
    }
}
static void polyt0_unpack(poly *a, const uint8_t *r) {
    for (int i = 0; i < MLDSA_N/8; i++) {
        uint32_t t[8];
        t[0] =  (uint32_t)r[13*i+0]        | ((uint32_t)r[13*i+1] << 8);                t[0] &= 0x1fff;
        t[1] = ((uint32_t)r[13*i+1] >> 5)  | ((uint32_t)r[13*i+2] << 3) | ((uint32_t)r[13*i+3] << 11); t[1] &= 0x1fff;
        t[2] = ((uint32_t)r[13*i+3] >> 2)  | ((uint32_t)r[13*i+4] << 6);                t[2] &= 0x1fff;
        t[3] = ((uint32_t)r[13*i+4] >> 7)  | ((uint32_t)r[13*i+5] << 1) | ((uint32_t)r[13*i+6] << 9);  t[3] &= 0x1fff;
        t[4] = ((uint32_t)r[13*i+6] >> 4)  | ((uint32_t)r[13*i+7] << 4) | ((uint32_t)r[13*i+8] << 12); t[4] &= 0x1fff;
        t[5] = ((uint32_t)r[13*i+8] >> 1)  | ((uint32_t)r[13*i+9] << 7);                t[5] &= 0x1fff;
        t[6] = ((uint32_t)r[13*i+9] >> 6)  | ((uint32_t)r[13*i+10] << 2) | ((uint32_t)r[13*i+11] << 10); t[6] &= 0x1fff;
        t[7] = ((uint32_t)r[13*i+11] >> 3) | ((uint32_t)r[13*i+12] << 5); t[7] &= 0x1fff;
        for (int j = 0; j < 8; j++) a->coeffs[8*i+j] = (1 << (MLDSA_D-1)) - (int32_t)t[j];
    }
}
static void polyeta_pack(uint8_t *r, const poly *a, int eta) {
    if (eta == 2) {
        for (int i = 0; i < MLDSA_N/8; i++) {
            uint8_t t[8]; for (int j=0;j<8;j++) t[j] = (uint8_t)(eta - a->coeffs[8*i+j]);
            r[3*i+0] = (uint8_t)(t[0] | (t[1]<<3) | (t[2]<<6));
            r[3*i+1] = (uint8_t)((t[2]>>2) | (t[3]<<1) | (t[4]<<4) | (t[5]<<7));
            r[3*i+2] = (uint8_t)((t[5]>>1) | (t[6]<<2) | (t[7]<<5));
        }
    } else { /* eta = 4 */
        for (int i = 0; i < MLDSA_N/2; i++) {
            uint8_t t0 = (uint8_t)(eta - a->coeffs[2*i+0]);
            uint8_t t1 = (uint8_t)(eta - a->coeffs[2*i+1]);
            r[i] = (uint8_t)(t0 | (t1 << 4));
        }
    }
}
static void polyeta_unpack(poly *a, const uint8_t *r, int eta) {
    if (eta == 2) {
        for (int i = 0; i < MLDSA_N/8; i++) {
            int32_t t[8];
            t[0] = r[3*i+0] & 7;
            t[1] = (r[3*i+0] >> 3) & 7;
            t[2] = ((r[3*i+0] >> 6) | (r[3*i+1] << 2)) & 7;
            t[3] = (r[3*i+1] >> 1) & 7;
            t[4] = (r[3*i+1] >> 4) & 7;
            t[5] = ((r[3*i+1] >> 7) | (r[3*i+2] << 1)) & 7;
            t[6] = (r[3*i+2] >> 2) & 7;
            t[7] = (r[3*i+2] >> 5) & 7;
            for (int j=0;j<8;j++) a->coeffs[8*i+j] = eta - t[j];
        }
    } else {
        for (int i = 0; i < MLDSA_N/2; i++) {
            int32_t t0 = r[i] & 0x0f;
            int32_t t1 = r[i] >> 4;
            a->coeffs[2*i+0] = eta - t0;
            a->coeffs[2*i+1] = eta - t1;
        }
    }
}

static void polyz_pack(uint8_t *r, const poly *a, int gamma1) {
    if (gamma1 == (1<<17)) {
        for (int i = 0; i < MLDSA_N/4; i++) {
            uint32_t t[4]; for (int j=0;j<4;j++) t[j] = gamma1 - a->coeffs[4*i+j];
            r[9*i+0] = (uint8_t)t[0];
            r[9*i+1] = (uint8_t)(t[0] >> 8);
            r[9*i+2] = (uint8_t)((t[0] >> 16) | (t[1] << 2));
            r[9*i+3] = (uint8_t)(t[1] >> 6);
            r[9*i+4] = (uint8_t)((t[1] >> 14) | (t[2] << 4));
            r[9*i+5] = (uint8_t)(t[2] >> 4);
            r[9*i+6] = (uint8_t)((t[2] >> 12) | (t[3] << 6));
            r[9*i+7] = (uint8_t)(t[3] >> 2);
            r[9*i+8] = (uint8_t)(t[3] >> 10);
        }
    } else { /* gamma1 = 2^19 */
        for (int i = 0; i < MLDSA_N/2; i++) {
            uint32_t t0 = gamma1 - a->coeffs[2*i+0];
            uint32_t t1 = gamma1 - a->coeffs[2*i+1];
            r[5*i+0] = (uint8_t)t0;
            r[5*i+1] = (uint8_t)(t0 >> 8);
            r[5*i+2] = (uint8_t)((t0 >> 16) | (t1 << 4));
            r[5*i+3] = (uint8_t)(t1 >> 4);
            r[5*i+4] = (uint8_t)(t1 >> 12);
        }
    }
}
static void polyz_unpack(poly *a, const uint8_t *r, int gamma1) {
    if (gamma1 == (1<<17)) {
        for (int i = 0; i < MLDSA_N/4; i++) {
            uint32_t t[4];
            t[0] =  (uint32_t)r[9*i+0]       | ((uint32_t)r[9*i+1] << 8) | (((uint32_t)r[9*i+2] & 0x03) << 16);
            t[1] = ((uint32_t)r[9*i+2] >> 2) | ((uint32_t)r[9*i+3] << 6) | (((uint32_t)r[9*i+4] & 0x0f) << 14);
            t[2] = ((uint32_t)r[9*i+4] >> 4) | ((uint32_t)r[9*i+5] << 4) | (((uint32_t)r[9*i+6] & 0x3f) << 12);
            t[3] = ((uint32_t)r[9*i+6] >> 6) | ((uint32_t)r[9*i+7] << 2) | ((uint32_t)r[9*i+8] << 10);
            for (int j=0;j<4;j++) { t[j] &= 0x3ffff; a->coeffs[4*i+j] = gamma1 - (int32_t)t[j]; }
        }
    } else {
        for (int i = 0; i < MLDSA_N/2; i++) {
            uint32_t t0 = (uint32_t)r[5*i+0] | ((uint32_t)r[5*i+1] << 8) | (((uint32_t)r[5*i+2] & 0x0f) << 16);
            uint32_t t1 = ((uint32_t)r[5*i+2] >> 4) | ((uint32_t)r[5*i+3] << 4) | ((uint32_t)r[5*i+4] << 12);
            t0 &= 0xfffff; t1 &= 0xfffff;
            a->coeffs[2*i+0] = gamma1 - (int32_t)t0;
            a->coeffs[2*i+1] = gamma1 - (int32_t)t1;
        }
    }
}

static void polyw1_pack(uint8_t *r, const poly *a, int gamma2_div) {
    if (gamma2_div == 32) {
        for (int i = 0; i < MLDSA_N/2; i++) r[i] = (uint8_t)(a->coeffs[2*i] | (a->coeffs[2*i+1] << 4));
    } else {
        for (int i = 0; i < MLDSA_N/4; i++) {
            uint32_t t0=a->coeffs[4*i], t1=a->coeffs[4*i+1], t2=a->coeffs[4*i+2], t3=a->coeffs[4*i+3];
            r[3*i+0] = (uint8_t)(t0 | (t1 << 6));
            r[3*i+1] = (uint8_t)((t1 >> 2) | (t2 << 4));
            r[3*i+2] = (uint8_t)((t2 >> 4) | (t3 << 2));
        }
    }
}

/* ---- Vector helpers (k or l polys) ---- */
static void vec_ntt(poly *v, int n) { for (int i=0;i<n;i++) ntt(&v[i]); }
static void vec_invntt(poly *v, int n) { for (int i=0;i<n;i++) invntt(&v[i]); }
static void vec_reduce(poly *v, int n) { for (int i=0;i<n;i++) poly_reduce(&v[i]); }
static void vec_caddq(poly *v, int n) { for (int i=0;i<n;i++) poly_caddq(&v[i]); }
static void vec_add(poly *r, const poly *a, const poly *b, int n) { for (int i=0;i<n;i++) poly_add(&r[i],&a[i],&b[i]); }
static void vec_sub(poly *r, const poly *a, const poly *b, int n) { for (int i=0;i<n;i++) poly_sub(&r[i],&a[i],&b[i]); }

static void matrix_expand(poly *A /* k*l */, const uint8_t rho[32], int k, int l) {
    for (int i = 0; i < k; i++)
        for (int j = 0; j < l; j++) {
            uint16_t nonce = (uint16_t)((i << 8) | j);
            poly_uniform(&A[i*l + j], rho, nonce);
        }
}

static void matrix_mul(poly *t /* k */, const poly *A, const poly *s, int k, int l) {
    poly tmp;
    for (int i = 0; i < k; i++) {
        poly_pointwise(&t[i], &A[i*l + 0], &s[0]);
        for (int j = 1; j < l; j++) {
            poly_pointwise(&tmp, &A[i*l + j], &s[j]);
            poly_add(&t[i], &t[i], &tmp);
        }
    }
}

/* ---- ML-DSA keygen / sign / verify ---- */
int iii_mldsa_keygen(int level, const uint8_t seed[32], uint8_t *pk, uint8_t *sk) {
    mldsa_params P; mldsa_get_params(level, &P);
    /* derive rho || rhoprime || K = SHAKE-256(seed || k || l, 128) */
    uint8_t inp[34]; memcpy(inp, seed, 32); inp[32] = (uint8_t)P.k; inp[33] = (uint8_t)P.l;
    uint8_t buf[128]; iii_shake256(inp, 34, buf, 128);
    uint8_t rho[32], rhoprime[64], K[32];
    memcpy(rho, buf, 32); memcpy(rhoprime, buf+32, 64); memcpy(K, buf+96, 32);

    poly A[64]; /* up to 8*7 */
    matrix_expand(A, rho, P.k, P.l);

    poly s1[7], s2[8];
    for (int i = 0; i < P.l; i++) poly_uniform_eta(&s1[i], rhoprime, (uint16_t)i, P.eta);
    for (int i = 0; i < P.k; i++) poly_uniform_eta(&s2[i], rhoprime, (uint16_t)(i + P.l), P.eta);

    poly s1hat[7]; for (int i=0;i<P.l;i++) s1hat[i]=s1[i];
    vec_ntt(s1hat, P.l);
    poly t1v[8];
    matrix_mul(t1v, A, s1hat, P.k, P.l);
    vec_reduce(t1v, P.k); vec_invntt(t1v, P.k); vec_caddq(t1v, P.k);
    vec_add(t1v, t1v, s2, P.k);
    /* power2round */
    poly t1[8], t0[8];
    for (int i = 0; i < P.k; i++)
        for (int j = 0; j < MLDSA_N; j++)
            t1[i].coeffs[j] = power2round(t1v[i].coeffs[j], &t0[i].coeffs[j]);

    /* pack pk = rho || t1 */
    memcpy(pk, rho, 32);
    for (int i = 0; i < P.k; i++) polyt1_pack(pk + 32 + 320*i, &t1[i]);

    /* sk = rho || K || tr || s1 || s2 || t0 */
    uint8_t *p = sk;
    memcpy(p, rho, 32); p += 32;
    memcpy(p, K, 32); p += 32;
    /* tr = SHAKE-256(pk, 64) */
    size_t pk_bytes = 32 + 320*P.k;
    iii_shake256(pk, pk_bytes, p, 64); p += 64;
    for (int i = 0; i < P.l; i++) { polyeta_pack(p, &s1[i], P.eta); p += P.polyeta_packed; }
    for (int i = 0; i < P.k; i++) { polyeta_pack(p, &s2[i], P.eta); p += P.polyeta_packed; }
    for (int i = 0; i < P.k; i++) { polyt0_pack(p, &t0[i]); p += 416; }
    return 0;
}

static size_t mldsa_sig_bytes(const mldsa_params *P) {
    return 32 + P->l * P->polyz_packed + P->omega + P->k;
}

int iii_mldsa_sign(int level, const uint8_t *sk,
                   const uint8_t *msg, size_t msglen,
                   uint8_t *sig, size_t *siglen) {
    mldsa_params P; mldsa_get_params(level, &P);
    const uint8_t *rho = sk;
    const uint8_t *K   = sk + 32;
    const uint8_t *tr  = sk + 64;
    const uint8_t *s1p = sk + 128;
    const uint8_t *s2p = s1p + P.l * P.polyeta_packed;
    const uint8_t *t0p = s2p + P.k * P.polyeta_packed;

    poly s1[7], s2[8], t0[8];
    for (int i=0;i<P.l;i++) polyeta_unpack(&s1[i], s1p + i*P.polyeta_packed, P.eta);
    for (int i=0;i<P.k;i++) polyeta_unpack(&s2[i], s2p + i*P.polyeta_packed, P.eta);
    for (int i=0;i<P.k;i++) polyt0_unpack(&t0[i], t0p + i*416);

    poly A[64]; matrix_expand(A, rho, P.k, P.l);

    poly s1hat[7]; for (int i=0;i<P.l;i++) s1hat[i]=s1[i]; vec_ntt(s1hat, P.l);
    poly s2hat[8]; for (int i=0;i<P.k;i++) s2hat[i]=s2[i]; vec_ntt(s2hat, P.k);
    poly t0hat[8]; for (int i=0;i<P.k;i++) t0hat[i]=t0[i]; vec_ntt(t0hat, P.k);

    /* mu = SHAKE-256(tr || msg, 64) */
    uint8_t mu[64];
    iii_keccak_ctx_t kc; iii_keccak_init(&kc, 136, 0x1f);
    iii_keccak_absorb(&kc, tr, 64);
    iii_keccak_absorb(&kc, msg, msglen);
    iii_keccak_finalize(&kc); iii_keccak_squeeze(&kc, mu, 64);

    /* rhoprime = SHAKE-256(K || mu, 64) */
    uint8_t rhoprime[64];
    iii_keccak_ctx_t kc2; iii_keccak_init(&kc2, 136, 0x1f);
    iii_keccak_absorb(&kc2, K, 32);
    iii_keccak_absorb(&kc2, mu, 64);
    iii_keccak_finalize(&kc2); iii_keccak_squeeze(&kc2, rhoprime, 64);

    uint16_t kappa = 0;
    poly y[7], z[7], h_poly[8], w[8], w1p[8], w0p[8];
    poly cp; uint8_t c_seed[32];

    while (1) {
        /* sample y */
        for (int i = 0; i < P.l; i++) {
            poly_uniform_gamma1(&y[i], rhoprime, (uint16_t)(kappa + i), P.gamma1_log);
        }
        kappa += (uint16_t)P.l;

        /* z = NTT(y); w = A*z */
        for (int i=0;i<P.l;i++) z[i]=y[i];
        vec_ntt(z, P.l);
        matrix_mul(w, A, z, P.k, P.l);
        vec_reduce(w, P.k); vec_invntt(w, P.k); vec_caddq(w, P.k);

        /* decompose */
        for (int i = 0; i < P.k; i++)
            for (int j = 0; j < MLDSA_N; j++)
                w1p[i].coeffs[j] = decompose(w[i].coeffs[j], &w0p[i].coeffs[j], P.gamma2);

        /* c_seed = SHAKE-256(mu || w1, 32) */
        iii_keccak_ctx_t kc3; iii_keccak_init(&kc3, 136, 0x1f);
        iii_keccak_absorb(&kc3, mu, 64);
        for (int i = 0; i < P.k; i++) {
            uint8_t pk_w1[192];
            polyw1_pack(pk_w1, &w1p[i], P.gamma2_div);
            iii_keccak_absorb(&kc3, pk_w1, P.polyw1_packed);
        }
        iii_keccak_finalize(&kc3); iii_keccak_squeeze(&kc3, c_seed, 32);

        challenge(&cp, c_seed, P.tau);
        poly chat = cp; ntt(&chat);

        /* z = y + c*s1 */
        poly cs1[7], cs2[8];
        for (int i = 0; i < P.l; i++) { poly_pointwise(&cs1[i], &chat, &s1hat[i]); invntt(&cs1[i]); }
        for (int i = 0; i < P.l; i++) poly_add(&z[i], &y[i], &cs1[i]);
        vec_reduce(z, P.l);
        if (poly_chknorm(&z[0], P.gamma1 - P.beta)) continue;
        int bad = 0;
        for (int i = 0; i < P.l; i++) if (poly_chknorm(&z[i], P.gamma1 - P.beta)) { bad=1; break; }
        if (bad) continue;

        /* r0 = w0 - c*s2 */
        for (int i = 0; i < P.k; i++) { poly_pointwise(&cs2[i], &chat, &s2hat[i]); invntt(&cs2[i]); }
        poly r0[8];
        for (int i = 0; i < P.k; i++) poly_sub(&r0[i], &w0p[i], &cs2[i]);
        vec_reduce(r0, P.k);
        bad = 0;
        for (int i = 0; i < P.k; i++) if (poly_chknorm(&r0[i], P.gamma2 - P.beta)) { bad=1; break; }
        if (bad) continue;

        /* h = MakeHint(-c*t0, w - c*s2 + c*t0) */
        poly ct0[8];
        for (int i = 0; i < P.k; i++) { poly_pointwise(&ct0[i], &chat, &t0hat[i]); invntt(&ct0[i]); }
        vec_reduce(ct0, P.k);
        bad = 0;
        for (int i = 0; i < P.k; i++) if (poly_chknorm(&ct0[i], P.gamma2)) { bad=1; break; }
        if (bad) continue;

        /* h = MakeHint(a0 = LowBits(w) - c*s2 + c*t0 = r0 + ct0,
         *              a1 = HighBits(w) = w1).  This matches verify's
         *              UseHint(h, A*z - c*t1*2^d) = UseHint(h, w - cs2 + ct0)
         *              recovering w1.  (Was: make_hint(-ct0, HighBits(w-cs2+ct0)),
         *              which is neither operand the reference MakeHint takes ->
         *              sign's hint disagreed with verify -> verify rejected.) */
        int hsum = 0;
        for (int i = 0; i < P.k; i++) {
            for (int j = 0; j < MLDSA_N; j++) {
                int32_t a0 = r0[i].coeffs[j] + ct0[i].coeffs[j];
                int32_t hbit = make_hint(a0, w1p[i].coeffs[j], P.gamma2);
                h_poly[i].coeffs[j] = hbit;
                hsum += hbit;
            }
        }
        if (hsum > P.omega) continue;

        /* pack signature: c_seed || z || h */
        uint8_t *p = sig;
        memcpy(p, c_seed, 32); p += 32;
        for (int i = 0; i < P.l; i++) { polyz_pack(p, &z[i], P.gamma1); p += P.polyz_packed; }
        memset(p, 0, P.omega + P.k);
        int idx = 0;
        for (int i = 0; i < P.k; i++) {
            for (int j = 0; j < MLDSA_N; j++) if (h_poly[i].coeffs[j]) p[idx++] = (uint8_t)j;
            p[P.omega + i] = (uint8_t)idx;
        }
        *siglen = mldsa_sig_bytes(&P);
        return 0;
    }
}

int iii_mldsa_verify(int level, const uint8_t *pk,
                     const uint8_t *msg, size_t msglen,
                     const uint8_t *sig, size_t siglen) {
    mldsa_params P; mldsa_get_params(level, &P);
    if (siglen != mldsa_sig_bytes(&P)) return -1;

    const uint8_t *rho = pk;
    poly t1[8];
    for (int i = 0; i < P.k; i++) polyt1_unpack(&t1[i], pk + 32 + 320*i);

    /* unpack signature */
    const uint8_t *c_seed = sig;
    const uint8_t *zp = sig + 32;
    const uint8_t *hp = zp + P.l * P.polyz_packed;

    poly z[7];
    for (int i = 0; i < P.l; i++) polyz_unpack(&z[i], zp + i*P.polyz_packed, P.gamma1);
    for (int i = 0; i < P.l; i++) if (poly_chknorm(&z[i], P.gamma1 - P.beta)) return -1;

    poly h_poly[8];
    int idx = 0;
    for (int i = 0; i < P.k; i++) memset(h_poly[i].coeffs, 0, sizeof h_poly[i].coeffs);
    for (int i = 0; i < P.k; i++) {
        int cnt = hp[P.omega + i];
        if (cnt < idx || cnt > P.omega) return -1;
        for (int j = idx; j < cnt; j++) {
            if (j > idx && hp[j] <= hp[j-1]) return -1;
            h_poly[i].coeffs[hp[j]] = 1;
        }
        idx = cnt;
    }
    for (int j = idx; j < P.omega; j++) if (hp[j]) return -1;

    poly cp; challenge(&cp, c_seed, P.tau);
    poly chat = cp; ntt(&chat);

    poly A[64]; matrix_expand(A, rho, P.k, P.l);

    poly zhat[7]; for (int i=0;i<P.l;i++) zhat[i]=z[i]; vec_ntt(zhat, P.l);
    poly Az[8]; matrix_mul(Az, A, zhat, P.k, P.l);
    /* compute c * t1*2^d */
    poly t1hat[8];
    for (int i = 0; i < P.k; i++) {
        for (int j = 0; j < MLDSA_N; j++) t1hat[i].coeffs[j] = t1[i].coeffs[j] << MLDSA_D;
        ntt(&t1hat[i]);
    }
    poly ct1[8];
    for (int i = 0; i < P.k; i++) poly_pointwise(&ct1[i], &chat, &t1hat[i]);
    vec_sub(Az, Az, ct1, P.k);
    vec_reduce(Az, P.k); vec_invntt(Az, P.k); vec_caddq(Az, P.k);

    /* w1' = UseHint(h, Az) */
    poly w1p[8];
    for (int i = 0; i < P.k; i++)
        for (int j = 0; j < MLDSA_N; j++)
            w1p[i].coeffs[j] = use_hint(Az[i].coeffs[j], h_poly[i].coeffs[j], P.gamma2);

    /* Recompute c_seed' */
    uint8_t mu[64];
    iii_keccak_ctx_t kc; iii_keccak_init(&kc, 136, 0x1f);
    uint8_t tr[64];
    size_t pk_bytes = 32 + 320*P.k;
    iii_shake256(pk, pk_bytes, tr, 64);
    iii_keccak_absorb(&kc, tr, 64);
    iii_keccak_absorb(&kc, msg, msglen);
    iii_keccak_finalize(&kc); iii_keccak_squeeze(&kc, mu, 64);

    iii_keccak_ctx_t kc3; iii_keccak_init(&kc3, 136, 0x1f);
    iii_keccak_absorb(&kc3, mu, 64);
    for (int i = 0; i < P.k; i++) {
        uint8_t pkw1[192]; polyw1_pack(pkw1, &w1p[i], P.gamma2_div);
        iii_keccak_absorb(&kc3, pkw1, P.polyw1_packed);
    }
    iii_keccak_finalize(&kc3);
    uint8_t c_check[32]; iii_keccak_squeeze(&kc3, c_check, 32);
    int diff = 0;
    for (int i = 0; i < 32; i++) diff |= c_check[i] ^ c_seed[i];
    return diff == 0 ? 0 : -1;
}
