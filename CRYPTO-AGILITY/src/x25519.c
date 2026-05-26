/* Hand-rolled X25519 per RFC 7748. Field GF(2^255-19) using 64-bit limbs. */
#include "iii/curve25519.h"
#include <string.h>

/* Field representation: array of 5 uint64_t each holding 51 bits. */
typedef uint64_t fe25519[5];

static void fe_0(fe25519 h) { for (int i=0;i<5;i++) h[i]=0; }
static void fe_1(fe25519 h) { h[0]=1; h[1]=h[2]=h[3]=h[4]=0; }
static void fe_copy(fe25519 r, const fe25519 a) { for (int i=0;i<5;i++) r[i]=a[i]; }

static void fe_carry(fe25519 h) {
    uint64_t c;
    c = h[0] >> 51; h[0] &= 0x7ffffffffffffULL; h[1] += c;
    c = h[1] >> 51; h[1] &= 0x7ffffffffffffULL; h[2] += c;
    c = h[2] >> 51; h[2] &= 0x7ffffffffffffULL; h[3] += c;
    c = h[3] >> 51; h[3] &= 0x7ffffffffffffULL; h[4] += c;
    c = h[4] >> 51; h[4] &= 0x7ffffffffffffULL; h[0] += c * 19;
    c = h[0] >> 51; h[0] &= 0x7ffffffffffffULL; h[1] += c;
}

static void fe_add(fe25519 r, const fe25519 a, const fe25519 b) {
    for (int i=0;i<5;i++) r[i] = a[i] + b[i];
}

static void fe_sub(fe25519 r, const fe25519 a, const fe25519 b) {
    /* add 2*p to avoid underflow: 2p = 2*(2^255-19) = 2^256 - 38;
       per-limb add 2*0x7ffffffffffed... easier: add big constant */
    static const uint64_t two_p_minus[5] = {
        0xfffffffffffdaULL, 0xffffffffffffeULL, 0xffffffffffffeULL,
        0xffffffffffffeULL, 0xffffffffffffeULL
    };
    for (int i=0;i<5;i++) r[i] = a[i] + two_p_minus[i] - b[i];
}

static void fe_mul(fe25519 r, const fe25519 a, const fe25519 b) {
    __uint128_t c0,c1,c2,c3,c4;
    uint64_t b0=b[0], b1=b[1], b2=b[2], b3=b[3], b4=b[4];
    uint64_t a0=a[0], a1=a[1], a2=a[2], a3=a[3], a4=a[4];
    uint64_t b1_19 = b1*19, b2_19=b2*19, b3_19=b3*19, b4_19=b4*19;
    c0 = (__uint128_t)a0*b0 + (__uint128_t)a1*b4_19 + (__uint128_t)a2*b3_19 + (__uint128_t)a3*b2_19 + (__uint128_t)a4*b1_19;
    c1 = (__uint128_t)a0*b1 + (__uint128_t)a1*b0    + (__uint128_t)a2*b4_19 + (__uint128_t)a3*b3_19 + (__uint128_t)a4*b2_19;
    c2 = (__uint128_t)a0*b2 + (__uint128_t)a1*b1    + (__uint128_t)a2*b0    + (__uint128_t)a3*b4_19 + (__uint128_t)a4*b3_19;
    c3 = (__uint128_t)a0*b3 + (__uint128_t)a1*b2    + (__uint128_t)a2*b1    + (__uint128_t)a3*b0    + (__uint128_t)a4*b4_19;
    c4 = (__uint128_t)a0*b4 + (__uint128_t)a1*b3    + (__uint128_t)a2*b2    + (__uint128_t)a3*b1    + (__uint128_t)a4*b0;
    uint64_t t0,t1,t2,t3,t4;
    uint64_t car;
    t0 = (uint64_t)c0 & 0x7ffffffffffffULL; car = (uint64_t)(c0 >> 51); c1 += car;
    t1 = (uint64_t)c1 & 0x7ffffffffffffULL; car = (uint64_t)(c1 >> 51); c2 += car;
    t2 = (uint64_t)c2 & 0x7ffffffffffffULL; car = (uint64_t)(c2 >> 51); c3 += car;
    t3 = (uint64_t)c3 & 0x7ffffffffffffULL; car = (uint64_t)(c3 >> 51); c4 += car;
    t4 = (uint64_t)c4 & 0x7ffffffffffffULL; car = (uint64_t)(c4 >> 51); t0 += car * 19;
    car = t0 >> 51; t0 &= 0x7ffffffffffffULL; t1 += car;
    r[0]=t0; r[1]=t1; r[2]=t2; r[3]=t3; r[4]=t4;
}

static void fe_sq(fe25519 r, const fe25519 a) { fe_mul(r, a, a); }

static void fe_mul_small(fe25519 r, const fe25519 a, uint32_t s) {
    __uint128_t c0,c1,c2,c3,c4;
    c0 = (__uint128_t)a[0]*s;
    c1 = (__uint128_t)a[1]*s;
    c2 = (__uint128_t)a[2]*s;
    c3 = (__uint128_t)a[3]*s;
    c4 = (__uint128_t)a[4]*s;
    uint64_t car;
    r[0] = (uint64_t)c0 & 0x7ffffffffffffULL; car = (uint64_t)(c0 >> 51); c1 += car;
    r[1] = (uint64_t)c1 & 0x7ffffffffffffULL; car = (uint64_t)(c1 >> 51); c2 += car;
    r[2] = (uint64_t)c2 & 0x7ffffffffffffULL; car = (uint64_t)(c2 >> 51); c3 += car;
    r[3] = (uint64_t)c3 & 0x7ffffffffffffULL; car = (uint64_t)(c3 >> 51); c4 += car;
    r[4] = (uint64_t)c4 & 0x7ffffffffffffULL; car = (uint64_t)(c4 >> 51); r[0] += car * 19;
    car = r[0] >> 51; r[0] &= 0x7ffffffffffffULL; r[1] += car;
}

static void fe_invert(fe25519 r, const fe25519 a) {
    /* Compute a^(p-2) = a^(2^255 - 21) via standard chain. */
    fe25519 t0,t1,t2,t3;
    int i;
    fe_sq(t0, a);
    fe_sq(t1, t0); fe_sq(t1, t1);
    fe_mul(t1, a, t1);
    fe_mul(t0, t0, t1);
    fe_sq(t2, t0);
    fe_mul(t1, t1, t2);
    fe_sq(t2, t1); for (i=1;i<5;i++) fe_sq(t2, t2);
    fe_mul(t1, t2, t1);
    fe_sq(t2, t1); for (i=1;i<10;i++) fe_sq(t2, t2);
    fe_mul(t2, t2, t1);
    fe_sq(t3, t2); for (i=1;i<20;i++) fe_sq(t3, t3);
    fe_mul(t2, t3, t2);
    fe_sq(t2, t2); for (i=1;i<10;i++) fe_sq(t2, t2);
    fe_mul(t1, t2, t1);
    fe_sq(t2, t1); for (i=1;i<50;i++) fe_sq(t2, t2);
    fe_mul(t2, t2, t1);
    fe_sq(t3, t2); for (i=1;i<100;i++) fe_sq(t3, t3);
    fe_mul(t2, t3, t2);
    fe_sq(t2, t2); for (i=1;i<50;i++) fe_sq(t2, t2);
    fe_mul(t1, t2, t1);
    fe_sq(t1, t1); for (i=1;i<5;i++) fe_sq(t1, t1);
    fe_mul(r, t1, t0);
}

static void fe_from_bytes(fe25519 r, const uint8_t s[32]) {
    uint64_t lo[4];
    for (int i = 0; i < 4; i++) {
        uint64_t v = 0;
        for (int j = 7; j >= 0; j--) v = (v << 8) | s[8*i + j];
        lo[i] = v;
    }
    r[0] = lo[0] & 0x7ffffffffffffULL;
    r[1] = (lo[0] >> 51 | lo[1] << 13) & 0x7ffffffffffffULL;
    r[2] = (lo[1] >> 38 | lo[2] << 26) & 0x7ffffffffffffULL;
    r[3] = (lo[2] >> 25 | lo[3] << 39) & 0x7ffffffffffffULL;
    r[4] = (lo[3] >> 12) & 0x7ffffffffffffULL; /* mask top bit */
    r[4] &= 0x7ffffffffffffULL >> 1; /* clear bit 255 (mask top) */
    /* Per RFC 7748: bit 255 is masked off when reading u-coordinate. */
}

static void fe_to_bytes(uint8_t s[32], const fe25519 h_in) {
    fe25519 h; fe_copy(h, h_in);
    fe_carry(h);
    /* full reduce: subtract p if h >= p */
    uint64_t t0=h[0]+19, t1=h[1], t2=h[2], t3=h[3], t4=h[4];
    uint64_t c;
    c = t0 >> 51; t0 &= 0x7ffffffffffffULL; t1 += c;
    c = t1 >> 51; t1 &= 0x7ffffffffffffULL; t2 += c;
    c = t2 >> 51; t2 &= 0x7ffffffffffffULL; t3 += c;
    c = t3 >> 51; t3 &= 0x7ffffffffffffULL; t4 += c;
    /* If t4 >= 2^51, then h was >= p, so we use t-2^255 = t with t4-=2^51 */
    if (t4 >> 51) {
        h[0]=t0; h[1]=t1; h[2]=t2; h[3]=t3; h[4]=t4 & 0x7ffffffffffffULL;
    }
    /* else leave h as-is */
    uint64_t o0 = h[0] | (h[1] << 51);
    uint64_t o1 = (h[1] >> 13) | (h[2] << 38);
    uint64_t o2 = (h[2] >> 26) | (h[3] << 25);
    uint64_t o3 = (h[3] >> 39) | (h[4] << 12);
    for (int i = 0; i < 8; i++) s[i]    = (uint8_t)(o0 >> (8*i));
    for (int i = 0; i < 8; i++) s[8+i]  = (uint8_t)(o1 >> (8*i));
    for (int i = 0; i < 8; i++) s[16+i] = (uint8_t)(o2 >> (8*i));
    for (int i = 0; i < 8; i++) s[24+i] = (uint8_t)(o3 >> (8*i));
}

static void fe_cswap(fe25519 a, fe25519 b, uint64_t swap) {
    uint64_t mask = 0 - swap;
    for (int i=0;i<5;i++) {
        uint64_t t = mask & (a[i] ^ b[i]);
        a[i] ^= t; b[i] ^= t;
    }
}

void iii_x25519_scalarmult(uint8_t out[32], const uint8_t scalar[32], const uint8_t point[32]) {
    uint8_t e[32];
    memcpy(e, scalar, 32);
    e[0] &= 248; e[31] &= 127; e[31] |= 64;

    fe25519 x1, x2, z2, x3, z3, tmp0, tmp1;
    fe_from_bytes(x1, point);
    fe_1(x2); fe_0(z2);
    fe_copy(x3, x1); fe_1(z3);
    uint64_t swap = 0;
    for (int t = 254; t >= 0; t--) {
        uint64_t b = (e[t / 8] >> (t & 7)) & 1;
        swap ^= b;
        fe_cswap(x2, x3, swap);
        fe_cswap(z2, z3, swap);
        swap = b;
        /* Montgomery ladder step */
        fe_sub(tmp0, x3, z3);
        fe_sub(tmp1, x2, z2);
        fe_add(x2, x2, z2);
        fe_add(z2, x3, z3);
        fe_mul(z3, tmp0, x2);
        fe_mul(z2, z2, tmp1);
        fe_sq(tmp0, tmp1);
        fe_sq(tmp1, x2);
        fe_add(x3, z3, z2);
        fe_sub(z2, z3, z2);
        fe_mul(x2, tmp1, tmp0);
        fe_sub(tmp1, tmp1, tmp0);
        fe_sq(z2, z2);
        fe_mul_small(z3, tmp1, 121665);
        fe_sq(x3, x3);
        fe_add(tmp0, tmp0, z3);
        fe_mul(z3, x1, z2);
        fe_mul(z2, tmp1, tmp0);
    }
    fe_cswap(x2, x3, swap);
    fe_cswap(z2, z3, swap);
    fe_invert(z2, z2);
    fe_mul(x2, x2, z2);
    fe_to_bytes(out, x2);
}

void iii_x25519_base(uint8_t out[32], const uint8_t scalar[32]) {
    uint8_t base[32] = {9};
    iii_x25519_scalarmult(out, scalar, base);
}
