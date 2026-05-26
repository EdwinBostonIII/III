/* III ZK-PRUNING — Fp / Fp2 arithmetic.  See iii/zk_field.h for the
 * curve / field choice and overflow guarantees. */
#include "iii/zk_field.h"

/* ---------------- Fp ---------------- */

fp_t fp_from_u64(uint64_t x) { return x % IIIZK_P; }
int  fp_eq(fp_t x, fp_t y)   { return x == y; }

fp_t fp_add(fp_t x, fp_t y) {
    uint64_t s = x + y;
    if (s >= IIIZK_P) s -= IIIZK_P;
    return s;
}
fp_t fp_sub(fp_t x, fp_t y) {
    return (x >= y) ? (x - y) : (x + IIIZK_P - y);
}
fp_t fp_neg(fp_t x) { return x ? (IIIZK_P - x) : 0; }

fp_t fp_mul(fp_t x, fp_t y) {
    /* p^2 < 2^60, single 64-bit multiplication is exact. */
    return (uint64_t)(x * y) % IIIZK_P;
}

fp_t fp_pow(fp_t x, uint64_t e) {
    fp_t r = 1, b = x % IIIZK_P;
    while (e) {
        if (e & 1) r = fp_mul(r, b);
        b = fp_mul(b, b);
        e >>= 1;
    }
    return r;
}

fp_t fp_inv(fp_t x) {
    /* Fermat: x^(p-2) */
    return fp_pow(x, IIIZK_P - 2);
}

/* ---------------- Fr (scalar field) ----------------
 * r = IIIZK_R ≈ 2^26.4, so r^2 < 2^53 — single uint64 multiplication safe. */
fr_t fr_from_u64(uint64_t x) { return x % IIIZK_R; }
int  fr_eq(fr_t x, fr_t y)   { return x == y; }
fr_t fr_add(fr_t x, fr_t y) {
    uint64_t s = x + y; if (s >= IIIZK_R) s -= IIIZK_R; return s;
}
fr_t fr_sub(fr_t x, fr_t y) {
    return (x >= y) ? (x - y) : (x + IIIZK_R - y);
}
fr_t fr_neg(fr_t x) { return x ? (IIIZK_R - x) : 0; }
fr_t fr_mul(fr_t x, fr_t y) { return (x * y) % IIIZK_R; }
fr_t fr_pow(fr_t x, uint64_t e) {
    fr_t r = 1, b = x % IIIZK_R;
    while (e) { if (e & 1) r = fr_mul(r, b); b = fr_mul(b, b); e >>= 1; }
    return r;
}
fr_t fr_inv(fr_t x) { return fr_pow(x, IIIZK_R - 2); }

/* ---------------- Fp2 = Fp[u]/(u^2 + 1) ---------------- */

fp2_t fp2_zero(void)         { fp2_t r = {0,0}; return r; }
fp2_t fp2_one(void)          { fp2_t r = {1,0}; return r; }
fp2_t fp2_from_fp(fp_t x)    { fp2_t r = {x,0}; return r; }
fp2_t fp2_mk(fp_t a, fp_t b) { fp2_t r = {a,b}; return r; }

int fp2_eq(fp2_t x, fp2_t y)   { return x.a == y.a && x.b == y.b; }
int fp2_is_zero(fp2_t x)       { return x.a == 0 && x.b == 0; }

fp2_t fp2_add(fp2_t x, fp2_t y) {
    return fp2_mk(fp_add(x.a, y.a), fp_add(x.b, y.b));
}
fp2_t fp2_sub(fp2_t x, fp2_t y) {
    return fp2_mk(fp_sub(x.a, y.a), fp_sub(x.b, y.b));
}
fp2_t fp2_neg(fp2_t x) {
    return fp2_mk(fp_neg(x.a), fp_neg(x.b));
}

fp2_t fp2_mul(fp2_t x, fp2_t y) {
    /* (a + bu)(c + du) = (ac - bd) + (ad + bc)u, since u^2 = -1 */
    fp_t ac = fp_mul(x.a, y.a);
    fp_t bd = fp_mul(x.b, y.b);
    fp_t ad = fp_mul(x.a, y.b);
    fp_t bc = fp_mul(x.b, y.a);
    return fp2_mk(fp_sub(ac, bd), fp_add(ad, bc));
}

fp2_t fp2_mul_fp(fp2_t x, fp_t y) {
    return fp2_mk(fp_mul(x.a, y), fp_mul(x.b, y));
}

fp2_t fp2_inv(fp2_t x) {
    /* 1/(a + bu) = (a - bu) / (a^2 + b^2) */
    fp_t den = fp_add(fp_mul(x.a, x.a), fp_mul(x.b, x.b));
    fp_t inv = fp_inv(den);
    return fp2_mk(fp_mul(x.a, inv), fp_mul(fp_neg(x.b), inv));
}

fp2_t fp2_pow(fp2_t x, uint64_t e) {
    fp2_t r = fp2_one(), b = x;
    while (e) {
        if (e & 1) r = fp2_mul(r, b);
        b = fp2_mul(b, b);
        e >>= 1;
    }
    return r;
}

fp2_t fp2_frobenius(fp2_t x) {
    /* (a + bu)^p = a + b * u^p; since u^2 = -1 and p odd, u^p = u^((p-1)/2 * 2 + 1)
     * = (u^2)^((p-1)/2) * u = (-1)^((p-1)/2) * u.  Here p ≡ 3 mod 4 so
     * (p-1)/2 is odd, giving u^p = -u.  Hence (a + bu)^p = a - bu. */
    return fp2_mk(x.a, fp_neg(x.b));
}
