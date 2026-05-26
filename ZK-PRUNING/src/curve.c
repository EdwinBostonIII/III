/* III ZK-PRUNING — elliptic curve E: y^2 = x^3 + 1 over Fp / Fp2,
 * distortion map and Tate pairing (Miller loop + final exponentiation).
 *
 * E(Fp) is supersingular with |E(Fp)| = p + 1 = 12·r, so a generator of
 * the order-r subgroup G1 is the cofactor multiple of any non-trivial
 * point.  We use base point (2, 3) — on the curve since 3^2 = 2^3 + 1.
 */
#include "iii/zk_curve.h"

/* ---- ζ: primitive cube root of unity in Fp2.
 * ζ = (-1 + sqrt(-3)) / 2.  Since p ≡ 11 mod 12, sqrt(-3) = sqrt(3)·u
 * with sqrt(3) ∈ Fp.  We compute sqrt(3) once as 3^((p+1)/4) (valid for
 * p ≡ 3 mod 4 since 3 is a QR — verified by quadratic reciprocity).
 * Then ζ.a = (p-1)/2  and  ζ.b = sqrt(3)·(p+1)/2  mod p.
 *
 * Cached after first computation. */
static int    s_zeta_init = 0;
static fp2_t  s_zeta;

fp2_t iiizk_zeta(void) {
    if (s_zeta_init) return s_zeta;
    fp_t inv2  = fp_inv(2);
    fp_t neg1h = fp_mul(fp_neg(1), inv2);              /* -1/2 */
    fp_t sqrt3 = fp_pow(3, (IIIZK_P + 1) / 4);         /* sqrt(3) in Fp */
    fp_t sqrt3h= fp_mul(sqrt3, inv2);                  /* sqrt(3)/2 */
    s_zeta = fp2_mk(neg1h, sqrt3h);
    /* sanity: ζ^3 = 1 (computed at startup test) */
    s_zeta_init = 1;
    return s_zeta;
}

/* ---------------- G1: E(Fp) ---------------- */

g1_t g1_zero(void)         { g1_t r = {0,0,1}; return r; }

int g1_eq(g1_t P, g1_t Q) {
    if (P.infinity || Q.infinity) return P.infinity == Q.infinity;
    return P.x == Q.x && P.y == Q.y;
}

int g1_on_curve(g1_t P) {
    if (P.infinity) return 1;
    fp_t lhs = fp_mul(P.y, P.y);
    fp_t rhs = fp_add(fp_mul(fp_mul(P.x, P.x), P.x), 1);
    return fp_eq(lhs, rhs);
}

g1_t g1_neg(g1_t P) {
    if (P.infinity) return P;
    g1_t r = { P.x, fp_neg(P.y), 0 };
    return r;
}

g1_t g1_dbl(g1_t P) {
    if (P.infinity || P.y == 0) return g1_zero();
    /* λ = 3x^2 / (2y) */
    fp_t num = fp_mul(3, fp_mul(P.x, P.x));
    fp_t den = fp_inv(fp_add(P.y, P.y));
    fp_t lam = fp_mul(num, den);
    fp_t x3  = fp_sub(fp_mul(lam, lam), fp_add(P.x, P.x));
    fp_t y3  = fp_sub(fp_mul(lam, fp_sub(P.x, x3)), P.y);
    g1_t r = { x3, y3, 0 };
    return r;
}

g1_t g1_add(g1_t P, g1_t Q) {
    if (P.infinity) return Q;
    if (Q.infinity) return P;
    if (P.x == Q.x) {
        if (P.y == Q.y) return g1_dbl(P);
        return g1_zero();
    }
    fp_t num = fp_sub(Q.y, P.y);
    fp_t den = fp_inv(fp_sub(Q.x, P.x));
    fp_t lam = fp_mul(num, den);
    fp_t x3  = fp_sub(fp_sub(fp_mul(lam, lam), P.x), Q.x);
    fp_t y3  = fp_sub(fp_mul(lam, fp_sub(P.x, x3)), P.y);
    g1_t r = { x3, y3, 0 };
    return r;
}

g1_t g1_mul(g1_t P, uint64_t k) {
    g1_t r = g1_zero();
    g1_t b = P;
    while (k) {
        if (k & 1) r = g1_add(r, b);
        b = g1_dbl(b);
        k >>= 1;
    }
    return r;
}

g1_t g1_generator(void) {
    /* base point (5, 441986336) on E(Fp): y^2 = 126 = 5^3 + 1.  After
     * multiplication by cofactor h = 12 the result has order r. */
    g1_t base = { 5, 441986336ULL, 0 };
    return g1_mul(base, IIIZK_H);
}

/* ---------------- G2: ψ(G1) ⊂ E(Fp2) ---------------- */

g2_t g2_zero(void) { g2_t r; r.x = fp2_zero(); r.y = fp2_zero(); r.infinity = 1; return r; }

int g2_eq(g2_t P, g2_t Q) {
    if (P.infinity || Q.infinity) return P.infinity == Q.infinity;
    return fp2_eq(P.x, Q.x) && fp2_eq(P.y, Q.y);
}

int g2_on_curve(g2_t P) {
    if (P.infinity) return 1;
    fp2_t lhs = fp2_mul(P.y, P.y);
    fp2_t x2  = fp2_mul(P.x, P.x);
    fp2_t x3  = fp2_mul(x2, P.x);
    fp2_t rhs = fp2_add(x3, fp2_one());
    return fp2_eq(lhs, rhs);
}

g2_t g2_from_g1(g1_t P) {
    if (P.infinity) return g2_zero();
    g2_t r;
    r.x = fp2_mul_fp(iiizk_zeta(), P.x);   /* ζ·x */
    r.y = fp2_from_fp(P.y);
    r.infinity = 0;
    return r;
}

g2_t g2_neg(g2_t P) {
    if (P.infinity) return P;
    g2_t r = { P.x, fp2_neg(P.y), 0 };
    return r;
}

g2_t g2_dbl(g2_t P) {
    if (P.infinity || fp2_is_zero(P.y)) return g2_zero();
    fp2_t three = fp2_from_fp(3);
    fp2_t two   = fp2_from_fp(2);
    fp2_t num   = fp2_mul(three, fp2_mul(P.x, P.x));
    fp2_t den   = fp2_inv(fp2_mul(two, P.y));
    fp2_t lam   = fp2_mul(num, den);
    fp2_t x3    = fp2_sub(fp2_mul(lam, lam), fp2_mul(two, P.x));
    fp2_t y3    = fp2_sub(fp2_mul(lam, fp2_sub(P.x, x3)), P.y);
    g2_t r = { x3, y3, 0 };
    return r;
}

g2_t g2_add(g2_t P, g2_t Q) {
    if (P.infinity) return Q;
    if (Q.infinity) return P;
    if (fp2_eq(P.x, Q.x)) {
        if (fp2_eq(P.y, Q.y)) return g2_dbl(P);
        return g2_zero();
    }
    fp2_t num = fp2_sub(Q.y, P.y);
    fp2_t den = fp2_inv(fp2_sub(Q.x, P.x));
    fp2_t lam = fp2_mul(num, den);
    fp2_t x3  = fp2_sub(fp2_sub(fp2_mul(lam, lam), P.x), Q.x);
    fp2_t y3  = fp2_sub(fp2_mul(lam, fp2_sub(P.x, x3)), P.y);
    g2_t r = { x3, y3, 0 };
    return r;
}

g2_t g2_mul(g2_t P, uint64_t k) {
    g2_t r = g2_zero();
    g2_t b = P;
    while (k) {
        if (k & 1) r = g2_add(r, b);
        b = g2_dbl(b);
        k >>= 1;
    }
    return r;
}

g2_t g2_generator(void) { return g2_from_g1(g1_generator()); }

/* ---------------- Tate pairing ---------------- *
 *
 * f_{r,P}(Q) computed by Miller's algorithm, then raised to (p^2-1)/r
 * = (p-1)·h.  Since vertical denominators v_T(Q) = X_Q − x_T live in
 * Fp2 (X_Q has an Fp2 component via the distortion ζ·x_Q'), we keep
 * them in the running product instead of using denominator elimination
 * — at this scale clarity beats speed.
 *
 * Line through T1, T2 evaluated at Q:
 *     l_{T1,T2}(Q) = Y_Q − y_{T1} − λ · (X_Q − x_{T1})
 * where λ is the slope (or tangent slope when T1=T2).
 * Vertical at T = T1+T2:   v_T(Q) = X_Q − x_T.
 */

/* Line/vertical evaluation helpers: T1, T2 in G1 (Fp), Q in G2 (Fp2). */
static fp2_t line_eval(g1_t T1, g1_t T2, g2_t Q, g1_t *T_out) {
    /* Compute λ and the resulting addition T = T1 + T2; return l(Q)/v(Q). */
    fp_t lam;
    if (T1.x == T2.x) {
        if (T1.y != T2.y || T1.y == 0) {
            /* T1 + T2 = O: line is the vertical at T1; its value at Q is X_Q − x_T1. */
            *T_out = g1_zero();
            return fp2_sub(Q.x, fp2_from_fp(T1.x));
        }
        /* doubling */
        fp_t num = fp_mul(3, fp_mul(T1.x, T1.x));
        fp_t den = fp_inv(fp_add(T1.y, T1.y));
        lam = fp_mul(num, den);
    } else {
        fp_t num = fp_sub(T2.y, T1.y);
        fp_t den = fp_inv(fp_sub(T2.x, T1.x));
        lam = fp_mul(num, den);
    }
    fp_t x3 = fp_sub(fp_sub(fp_mul(lam, lam), T1.x), T2.x);
    fp_t y3 = fp_sub(fp_mul(lam, fp_sub(T1.x, x3)), T1.y);
    g1_t T = { x3, y3, 0 };
    *T_out = T;

    /* l(Q) = Y_Q - y_T1 - λ * (X_Q - x_T1) */
    fp2_t XQ_minus_xT1 = fp2_sub(Q.x, fp2_from_fp(T1.x));
    fp2_t YQ_minus_yT1 = fp2_sub(Q.y, fp2_from_fp(T1.y));
    fp2_t lam_term     = fp2_mul_fp(XQ_minus_xT1, lam);
    fp2_t l            = fp2_sub(YQ_minus_yT1, lam_term);

    /* v(Q) = X_Q - x_T  (vertical at the resulting point) */
    fp2_t v = fp2_sub(Q.x, fp2_from_fp(x3));
    if (fp2_is_zero(v)) return l;            /* avoid div by 0 — caller skips */
    return fp2_mul(l, fp2_inv(v));
}

static fp2_t miller(g1_t P, g2_t Q, uint64_t r) {
    fp2_t f = fp2_one();
    g1_t  T = P;

    /* Find top bit. */
    int top = 63;
    while (top >= 0 && !((r >> top) & 1)) top--;

    for (int i = top - 1; i >= 0; i--) {
        f = fp2_mul(f, f);
        g1_t T2;
        fp2_t lv = line_eval(T, T, Q, &T2);
        f = fp2_mul(f, lv);
        T = T2;
        if ((r >> i) & 1) {
            g1_t T3;
            fp2_t lv2 = line_eval(T, P, Q, &T3);
            f = fp2_mul(f, lv2);
            T = T3;
        }
    }
    return f;
}

static fp2_t final_exp(fp2_t f) {
    /* Raise to (p^2 - 1)/r = (p - 1) * h. */
    fp2_t a = fp2_pow(f, IIIZK_P - 1);
    return fp2_pow(a, IIIZK_H);
}

fp2_t pairing(g1_t P, g2_t Q) {
    if (P.infinity || Q.infinity) return fp2_one();
    fp2_t f = miller(P, Q, IIIZK_R);
    return final_exp(f);
}

fp2_t gt_mul(fp2_t a, fp2_t b)         { return fp2_mul(a, b); }
fp2_t gt_pow(fp2_t a, uint64_t e)      { return fp2_pow(a, e); }
int   gt_eq(fp2_t a, fp2_t b)          { return fp2_eq(a, b); }
