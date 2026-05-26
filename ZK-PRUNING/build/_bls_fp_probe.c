/* §4.12 BLS12-381 Fp Montgomery-field probe (TDD-first, §4.4 discipline).
 *
 * Builds the 6-limb (384-bit) Montgomery field over the seed-derived,
 * limb-cross-validated prime p (see _bls_const_probe.c).  Validates the
 * arithmetic STRUCTURALLY (no external vectors needed):
 *   (1) n0inv:  p[0]*n0inv + 1 == 0 (mod 2^64)
 *   (2) R^2 round-trip:  from_mont(to_mont(a)) == a
 *   (3) Montgomery one:   fp_mul(a, 1) == a  (1 in Montgomery form = R mod p)
 *   (4) Fermat:           a^(p-1) == 1   (the decisive field-correctness check)
 *   (5) inverse:          a * a^(p-2) == 1
 *   (6) field axioms:     (p-1)+1 == 0, a-a == 0
 * A wrong reduction, n0inv, or R^2 fails Fermat/inverse with overwhelming
 * probability.  Exit 99 = all pass.  This validated code is the reference
 * lifted into the real ZK-PRUNING field.c (and later numera/zk_field.iii).
 */
#include <stdint.h>
#include <stdio.h>
#include <string.h>
typedef unsigned __int128 u128;

/* p (little-endian), canonical BLS12-381 base field; proven by _bls_const_probe. */
static const uint64_t P[6] = {
    0xb9feffffffffaaabULL, 0x1eabfffeb153ffffULL, 0x6730d2a0f6b0f624ULL,
    0x64774b84f38512bfULL, 0x4b1ba7b6434bacd7ULL, 0x1a0111ea397fe69aULL
};

static int cmp6(const uint64_t a[6], const uint64_t b[6]) {
    for (int i = 5; i >= 0; i--) { if (a[i] < b[i]) return -1; if (a[i] > b[i]) return 1; }
    return 0;
}
/* a -= b (6 limbs), return borrow. */
static uint64_t sub6(uint64_t a[6], const uint64_t b[6]) {
    u128 br = 0;
    for (int i = 0; i < 6; i++) { u128 t = (u128)a[i] - b[i] - (uint64_t)br; a[i] = (uint64_t)t; br = (t >> 64) ? 1 : 0; }
    return (uint64_t)br;
}
/* a += b (6 limbs), return carry. */
static uint64_t add6(uint64_t a[6], const uint64_t b[6]) {
    u128 c = 0;
    for (int i = 0; i < 6; i++) { u128 s = (u128)a[i] + b[i] + (uint64_t)c; a[i] = (uint64_t)s; c = s >> 64; }
    return (uint64_t)c;
}

/* -------- Montgomery parameters -------- */
static uint64_t N0INV;       /* -p^-1 mod 2^64 */
static uint64_t R2[6];       /* 2^768 mod p */

static void mont_init(void) {
    /* n0inv = -p[0]^-1 mod 2^64 via Newton (p[0] odd). */
    uint64_t inv = P[0];
    for (int i = 0; i < 7; i++) inv *= (uint64_t)2 - P[0] * inv;   /* inv = p[0]^-1 mod 2^64 */
    N0INV = (uint64_t)(0 - inv);
    /* R2 = 2^768 mod p : start at 1, double 768 times mod p. */
    uint64_t t[6] = {1,0,0,0,0,0};
    for (int k = 0; k < 768; k++) {
        uint64_t dbl[6]; memcpy(dbl, t, sizeof dbl);
        add6(t, dbl);                       /* t = 2t (no carry out of 6 limbs: 2t < 2p < 2^384) */
        if (cmp6(t, P) >= 0) sub6(t, P);
    }
    memcpy(R2, t, sizeof R2);
}

/* 6x6 -> 12-limb product. */
static void mul6(const uint64_t a[6], const uint64_t b[6], uint64_t out[12]) {
    for (int i = 0; i < 12; i++) out[i] = 0;
    for (int i = 0; i < 6; i++) {
        u128 c = 0;
        for (int j = 0; j < 6; j++) {
            u128 s = (u128)a[i] * b[j] + out[i + j] + (uint64_t)c;
            out[i + j] = (uint64_t)s; c = s >> 64;
        }
        out[i + 6] = (uint64_t)(out[i + 6] + (uint64_t)c);
    }
}

/* SOS Montgomery reduction of a 12-limb T into 6-limb out = T * R^-1 mod p. */
static void redc(uint64_t T[13], uint64_t out[6]) {
    T[12] = 0;
    for (int i = 0; i < 6; i++) {
        uint64_t m = (uint64_t)(T[i] * N0INV);
        u128 c = 0;
        for (int j = 0; j < 6; j++) {
            u128 s = (u128)m * P[j] + T[i + j] + (uint64_t)c;
            T[i + j] = (uint64_t)s; c = s >> 64;
        }
        int k = i + 6;
        while (c) { u128 s = (u128)T[k] + (uint64_t)c; T[k] = (uint64_t)s; c = s >> 64; k++; }
    }
    for (int i = 0; i < 6; i++) out[i] = T[6 + i];
    if (T[12] || cmp6(out, P) >= 0) sub6(out, P);
}

static void fp_mul(const uint64_t a[6], const uint64_t b[6], uint64_t out[6]) {
    uint64_t T[13]; uint64_t prod[12];
    mul6(a, b, prod);
    memcpy(T, prod, sizeof prod);
    redc(T, out);
}
static void fp_add(const uint64_t a[6], const uint64_t b[6], uint64_t out[6]) {
    memcpy(out, a, 48); add6(out, b);
    if (cmp6(out, P) >= 0) sub6(out, P);
}
static void fp_sub(const uint64_t a[6], const uint64_t b[6], uint64_t out[6]) {
    memcpy(out, a, 48);
    if (cmp6(a, b) < 0) { add6(out, P); }
    sub6(out, b);
}
static void to_mont(const uint64_t a[6], uint64_t out[6])   { fp_mul(a, R2, out); }
static void from_mont(const uint64_t a[6], uint64_t out[6]) { uint64_t one[6] = {1,0,0,0,0,0}; fp_mul(a, one, out); }

/* Montgomery exponentiation: base in mont form, exp little-endian 6 limbs. */
static void fp_pow(const uint64_t base_m[6], const uint64_t exp[6], uint64_t out[6]) {
    uint64_t res[6]; to_mont((uint64_t[6]){1,0,0,0,0,0}, res);   /* 1 in mont form = R mod p */
    uint64_t b[6]; memcpy(b, base_m, 48);
    for (int i = 0; i < 6; i++) {
        for (int bit = 0; bit < 64; bit++) {
            if ((exp[i] >> bit) & 1) fp_mul(res, b, res);
            fp_mul(b, b, b);
        }
    }
    memcpy(out, res, 48);
}

static int is_one(const uint64_t a[6]) { return a[0]==1 && a[1]==0 && a[2]==0 && a[3]==0 && a[4]==0 && a[5]==0; }
static int is_zero(const uint64_t a[6]) { for (int i=0;i<6;i++) if (a[i]) return 0; return 1; }

int main(void) {
    mont_init();

    /* (1) n0inv */
    if ((uint64_t)(P[0] * N0INV + 1) != 0) { printf("FAIL n0inv\n"); return 1; }

    /* sample values */
    uint64_t a[6] = {0x0123456789abcdefULL, 0xfedcba9876543210ULL, 0x1111222233334444ULL,
                     0x5555666677778888ULL, 0x9999aaaabbbbccccULL, 0x0a0111ea397fe600ULL};
    if (cmp6(a, P) >= 0) sub6(a, P);

    /* (2) R^2 round-trip */
    uint64_t am[6], aback[6];
    to_mont(a, am); from_mont(am, aback);
    if (cmp6(aback, a) != 0) { printf("FAIL to/from mont roundtrip\n"); return 2; }

    /* (3) Montgomery one */
    uint64_t one_m[6]; to_mont((uint64_t[6]){1,0,0,0,0,0}, one_m);
    uint64_t t1[6]; fp_mul(am, one_m, t1);
    if (cmp6(t1, am) != 0) { printf("FAIL mont one\n"); return 3; }

    /* (4) Fermat: a^(p-1) == 1 */
    uint64_t pm1[6]; memcpy(pm1, P, 48); pm1[0] -= 1;       /* p-1 (p[0] odd) */
    uint64_t fe[6]; fp_pow(am, pm1, fe);
    uint64_t fe_n[6]; from_mont(fe, fe_n);
    if (!is_one(fe_n)) { printf("FAIL Fermat a^(p-1)!=1\n"); return 4; }

    /* (5) inverse: a * a^(p-2) == 1 */
    uint64_t pm2[6]; memcpy(pm2, P, 48); pm2[0] -= 2;
    uint64_t inv_m[6]; fp_pow(am, pm2, inv_m);
    uint64_t prod_m[6]; fp_mul(am, inv_m, prod_m);
    uint64_t prod_n[6]; from_mont(prod_m, prod_n);
    if (!is_one(prod_n)) { printf("FAIL inverse a*a^(p-2)!=1\n"); return 5; }

    /* (6) field axioms (plain form): (p-1)+1 == 0, a-a == 0 */
    uint64_t pm1p[6]; memcpy(pm1p, P, 48); pm1p[0]-=1;
    uint64_t sum[6]; fp_add(pm1p, (uint64_t[6]){1,0,0,0,0,0}, sum);
    if (!is_zero(sum)) { printf("FAIL (p-1)+1 != 0\n"); return 6; }
    uint64_t diff[6]; fp_sub(a, a, diff);
    if (!is_zero(diff)) { printf("FAIL a-a != 0\n"); return 7; }

    printf("BLS12-381 Fp: n0inv=%016llx ok; R2 roundtrip ok; Fermat ok; inverse ok; axioms ok.\n",
           (unsigned long long)N0INV);
    return 99;
}
