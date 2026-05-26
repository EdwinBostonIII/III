/* III ZK-PRUNING — NIH Groth16-style SNARK.
 *
 * R1CS  ->  QAP  via Lagrange interpolation over the m-point domain
 *           D = {1, 2, ..., m}  ⊂  Fp  (small, distinct, easy to compute).
 * Setup samples α, β, γ, δ, x ∈ Fp from a 32-byte seed (SHA-256 PRG).
 * Prove samples r, s ∈ Fp from a 32-byte randomness.
 * Verify checks the textbook Groth16 equation
 *
 *   e(A, B)  =  e(α G1, β G2) · e( Σ_{i≤l} z_i · IC_i , γ G2 ) · e(C, δ G2).
 *
 * "Toy" parameters: small subgroup order r ≈ 2^26 and small R1CS sizes.
 * Algorithmic structure is identical to BLS12-381 production Groth16.
 */
#include "iii/zk_snark.h"
#include "iii/sha256.h"
#include <stdlib.h>
#include <string.h>

/* ---------------- helpers ---------------- */

static fr_t fp_from_seed(const uint8_t seed[32], uint32_t idx) {
    uint8_t buf[36], h[32];
    memcpy(buf, seed, 32);
    buf[32] = (uint8_t)(idx >> 24);
    buf[33] = (uint8_t)(idx >> 16);
    buf[34] = (uint8_t)(idx >> 8);
    buf[35] = (uint8_t)(idx);
    iii_sha256(buf, sizeof buf, h);
    uint64_t v = 0;
    for (int i = 0; i < 8; i++) v = (v << 8) | h[i];
    /* Reduce into [1, r-1] for non-zero scalars. */
    v %= (IIIZK_R - 1);
    return (fr_t)(v + 1);
}

static fr_t dot(const r1cs_term_t *t, uint32_t n, const fr_t *z) {
    fr_t s = 0;
    for (uint32_t i = 0; i < n; i++) s = fr_add(s, fr_mul(t[i].coeff, z[t[i].var]));
    return s;
}

/* ---------------- R1CS ---------------- */

void r1cs_init(r1cs_t *R, uint32_t num_vars, uint32_t num_pub) {
    R->num_vars = num_vars;
    R->num_pub  = num_pub;
    R->num_constraints = 0;
    R->cs = NULL;
}

void r1cs_add(r1cs_t *R,
              const r1cs_term_t *a, uint32_t na,
              const r1cs_term_t *b, uint32_t nb,
              const r1cs_term_t *c, uint32_t nc) {
    R->cs = realloc(R->cs, sizeof(r1cs_constraint_t) * (R->num_constraints + 1));
    r1cs_constraint_t *k = &R->cs[R->num_constraints++];
    k->na = na; k->nb = nb; k->nc = nc;
    k->a = malloc(sizeof(r1cs_term_t) * na);
    k->b = malloc(sizeof(r1cs_term_t) * nb);
    k->c = malloc(sizeof(r1cs_term_t) * nc);
    memcpy(k->a, a, sizeof(r1cs_term_t) * na);
    memcpy(k->b, b, sizeof(r1cs_term_t) * nb);
    memcpy(k->c, c, sizeof(r1cs_term_t) * nc);
}

void r1cs_free(r1cs_t *R) {
    for (uint32_t k = 0; k < R->num_constraints; k++) {
        free(R->cs[k].a); free(R->cs[k].b); free(R->cs[k].c);
    }
    free(R->cs);
    R->cs = NULL;
    R->num_constraints = 0;
}

int r1cs_satisfied(const r1cs_t *R, const fr_t *z) {
    for (uint32_t k = 0; k < R->num_constraints; k++) {
        fr_t a = dot(R->cs[k].a, R->cs[k].na, z);
        fr_t b = dot(R->cs[k].b, R->cs[k].nb, z);
        fr_t c = dot(R->cs[k].c, R->cs[k].nc, z);
        if (fr_mul(a, b) != c) return 0;
    }
    return 1;
}

/* ---------------- QAP via Lagrange ----------------
 *
 *  Domain D = {1, 2, ..., m}.  For each var i:
 *      u_i(τ_k) = A[k][i],  v_i(τ_k) = B[k][i],  w_i(τ_k) = C[k][i]
 *
 *  Build a values table val[k] for the polynomial we want, then evaluate
 *  it at a target point x via barycentric Lagrange:
 *      P(x) = ( Σ_k val[k] · l_k / (x − τ_k) ) / ( Σ_k l_k / (x − τ_k) )
 *  where l_k = ∏_{j≠k} 1/(τ_k − τ_j).  Pre-compute l_k once.
 *
 *  Coefficient form (needed for h): use direct Lagrange basis
 *      P(X) = Σ_k val[k] · L_k(X),  L_k(X) = l_k · ∏_{j≠k} (X − τ_j).
 *  Build coefficient arrays of degree m-1.
 */

static fr_t *barycentric_weights(uint32_t m) {
    fr_t *w = malloc(sizeof(fr_t) * m);
    for (uint32_t k = 0; k < m; k++) {
        fr_t prod = 1;
        for (uint32_t j = 0; j < m; j++) {
            if (j == k) continue;
            prod = fr_mul(prod, fr_sub((fr_t)(k + 1), (fr_t)(j + 1)));
        }
        w[k] = fr_inv(prod);
    }
    return w;
}

/* Evaluate degree-(m-1) polynomial at x given values on D = {1..m}. */
static fr_t lagrange_eval(const fr_t *vals, const fr_t *bw, uint32_t m, fr_t x) {
    /* Direct (non-barycentric) form to handle x ∈ D safely. */
    fr_t result = 0;
    for (uint32_t k = 0; k < m; k++) {
        fr_t basis = bw[k];
        for (uint32_t j = 0; j < m; j++) {
            if (j == k) continue;
            basis = fr_mul(basis, fr_sub(x, (fr_t)(j + 1)));
        }
        result = fr_add(result, fr_mul(vals[k], basis));
    }
    return result;
}

/* Compute coefficient form of degree-(m-1) interpolant of vals on D = {1..m}.
 * Output coeffs[0..m-1] of size m. */
static void lagrange_coeffs(const fr_t *vals, const fr_t *bw, uint32_t m, fr_t *coeffs) {
    /* For each k, accumulate vals[k] * bw[k] * ∏_{j≠k} (X − τ_j) into coeffs.
     * Work polynomial buf of size m. */
    fr_t *buf = calloc(m, sizeof(fr_t));
    for (uint32_t i = 0; i < m; i++) coeffs[i] = 0;
    for (uint32_t k = 0; k < m; k++) {
        /* Build ∏_{j≠k} (X − τ_j) into buf. */
        memset(buf, 0, sizeof(fr_t) * m);
        buf[0] = 1;
        uint32_t deg = 0;
        for (uint32_t j = 0; j < m; j++) {
            if (j == k) continue;
            /* Multiply buf by (X − τ_j) */
            fr_t tj = (fr_t)(j + 1);
            for (uint32_t i = deg + 1; i > 0; i--) {
                buf[i] = fr_sub(buf[i - 1], fr_mul(buf[i], tj));
            }
            buf[0] = fr_neg(fr_mul(buf[0], tj));
            deg++;
        }
        /* Add vals[k] * bw[k] * buf into coeffs. */
        fr_t scale = fr_mul(vals[k], bw[k]);
        for (uint32_t i = 0; i < m; i++) {
            coeffs[i] = fr_add(coeffs[i], fr_mul(scale, buf[i]));
        }
    }
    free(buf);
}

/* Polynomial multiplication (schoolbook).  out has size la+lb-1. */
static void poly_mul(const fr_t *a, uint32_t la, const fr_t *b, uint32_t lb, fr_t *out) {
    uint32_t lo = la + lb - 1;
    for (uint32_t i = 0; i < lo; i++) out[i] = 0;
    for (uint32_t i = 0; i < la; i++)
        for (uint32_t j = 0; j < lb; j++)
            out[i + j] = fr_add(out[i + j], fr_mul(a[i], b[j]));
}

/* Compute t(X) = ∏_{k=1..m} (X − k).  Output size m+1. */
static void target_poly(uint32_t m, fr_t *t) {
    for (uint32_t i = 0; i <= m; i++) t[i] = 0;
    t[0] = 1;
    uint32_t deg = 0;
    for (uint32_t k = 1; k <= m; k++) {
        for (uint32_t i = deg + 1; i > 0; i--) {
            t[i] = fr_sub(t[i - 1], fr_mul(t[i], (fr_t)k));
        }
        t[0] = fr_neg(fr_mul(t[0], (fr_t)k));
        deg++;
    }
}

/* Polynomial long division: divide num (degree dn) by den (degree dd, monic
 * not required).  Quotient `q` has degree dn-dd; remainder discarded. */
static void poly_divmod(const fr_t *num, uint32_t ln,
                        const fr_t *den, uint32_t ld,
                        fr_t *q, uint32_t lq) {
    fr_t *rem = malloc(sizeof(fr_t) * ln);
    memcpy(rem, num, sizeof(fr_t) * ln);
    fr_t lead_inv = fr_inv(den[ld - 1]);
    for (uint32_t i = 0; i < lq; i++) q[i] = 0;
    for (int32_t i = (int32_t)ln - 1; i >= (int32_t)ld - 1; i--) {
        fr_t coef = fr_mul(rem[i], lead_inv);
        uint32_t qi = (uint32_t)(i - (int32_t)ld + 1);
        if (qi < lq) q[qi] = coef;
        for (uint32_t j = 0; j < ld; j++) {
            uint32_t idx = qi + j;
            rem[idx] = fr_sub(rem[idx], fr_mul(coef, den[j]));
        }
    }
    free(rem);
}

/* ---------------- Setup ---------------- */

int snark_setup(const r1cs_t *R, const uint8_t seed[32], snark_crs_t *crs) {
    uint32_t n = R->num_vars;
    uint32_t l = R->num_pub;       /* public-input count, excl. constant */
    uint32_t m = R->num_constraints;
    if (m == 0 || n == 0) return -1;

    /* Sample trapdoor scalars from seed. */
    fr_t alpha = fp_from_seed(seed, 1);
    fr_t beta  = fp_from_seed(seed, 2);
    fr_t gamma = fp_from_seed(seed, 3);
    fr_t delta = fp_from_seed(seed, 4);
    fr_t x     = fp_from_seed(seed, 5);

    /* Build values tables and evaluate u_i(x), v_i(x), w_i(x). */
    fr_t *bw  = barycentric_weights(m);
    fr_t *u_x = calloc(n, sizeof(fr_t));
    fr_t *v_x = calloc(n, sizeof(fr_t));
    fr_t *w_x = calloc(n, sizeof(fr_t));
    fr_t *vals= calloc(m, sizeof(fr_t));

    for (uint32_t i = 0; i < n; i++) {
        for (uint32_t k = 0; k < m; k++) vals[k] = 0;
        for (uint32_t k = 0; k < m; k++) {
            for (uint32_t t = 0; t < R->cs[k].na; t++)
                if (R->cs[k].a[t].var == i) vals[k] = fr_add(vals[k], R->cs[k].a[t].coeff);
        }
        u_x[i] = lagrange_eval(vals, bw, m, x);

        for (uint32_t k = 0; k < m; k++) vals[k] = 0;
        for (uint32_t k = 0; k < m; k++) {
            for (uint32_t t = 0; t < R->cs[k].nb; t++)
                if (R->cs[k].b[t].var == i) vals[k] = fr_add(vals[k], R->cs[k].b[t].coeff);
        }
        v_x[i] = lagrange_eval(vals, bw, m, x);

        for (uint32_t k = 0; k < m; k++) vals[k] = 0;
        for (uint32_t k = 0; k < m; k++) {
            for (uint32_t t = 0; t < R->cs[k].nc; t++)
                if (R->cs[k].c[t].var == i) vals[k] = fr_add(vals[k], R->cs[k].c[t].coeff);
        }
        w_x[i] = lagrange_eval(vals, bw, m, x);
    }
    free(bw); free(vals);

    /* Compute t(x) and the {x^k * t(x) / δ} powers in scalar form. */
    fr_t *tcoef = calloc(m + 1, sizeof(fr_t));
    target_poly(m, tcoef);
    fr_t tx = 0;
    {
        fr_t pw = 1;
        for (uint32_t k = 0; k <= m; k++) {
            tx = fr_add(tx, fr_mul(tcoef[k], pw));
            pw = fr_mul(pw, x);
        }
    }
    fr_t inv_delta = fr_inv(delta);
    fr_t inv_gamma = fr_inv(gamma);

    /* Allocate CRS arrays. */
    g1_t G = g1_generator();
    g2_t H = g2_generator();

    crs->num_vars        = n;
    crs->num_pub         = l;
    crs->num_constraints = m;
    crs->domain_size     = m;

    crs->A_g1 = malloc(sizeof(g1_t) * n);
    crs->B_g2 = malloc(sizeof(g2_t) * n);
    crs->B_g1 = malloc(sizeof(g1_t) * n);
    crs->L_g1 = malloc(sizeof(g1_t) * (n - l - 1));
    crs->H_g1 = malloc(sizeof(g1_t) * (m - 1));   /* h has degree m-2 ⇒ m-1 coeffs */
    crs->IC   = malloc(sizeof(g1_t) * (l + 1));

    for (uint32_t i = 0; i < n; i++) {
        crs->A_g1[i] = g1_mul(G, u_x[i]);
        crs->B_g2[i] = g2_mul(H, v_x[i]);
        crs->B_g1[i] = g1_mul(G, v_x[i]);
    }
    /* IC for public (i = 0..l): (β·u_i(x) + α·v_i(x) + w_i(x)) / γ · G */
    for (uint32_t i = 0; i <= l; i++) {
        fr_t s = fr_add(fr_add(fr_mul(beta, u_x[i]), fr_mul(alpha, v_x[i])), w_x[i]);
        s = fr_mul(s, inv_gamma);
        crs->IC[i] = g1_mul(G, s);
    }
    /* L for private (i = l+1..n-1): same numerator over δ · G */
    for (uint32_t i = l + 1; i < n; i++) {
        fr_t s = fr_add(fr_add(fr_mul(beta, u_x[i]), fr_mul(alpha, v_x[i])), w_x[i]);
        s = fr_mul(s, inv_delta);
        crs->L_g1[i - l - 1] = g1_mul(G, s);
    }
    /* H_g1[k] = (x^k * t(x) / δ) · G, k = 0..m-2 */
    {
        fr_t pw = 1;
        for (uint32_t k = 0; k < m - 1; k++) {
            fr_t s = fr_mul(fr_mul(pw, tx), inv_delta);
            crs->H_g1[k] = g1_mul(G, s);
            pw = fr_mul(pw, x);
        }
    }

    crs->alpha_g1 = g1_mul(G, alpha);
    crs->beta_g1  = g1_mul(G, beta);    /* β·G1 — needed by prover for blinding */
    crs->beta_g2  = g2_mul(H, beta);
    crs->gamma_g2 = g2_mul(H, gamma);
    crs->delta_g1 = g1_mul(G, delta);   /* δ·G1 — needed by prover for r,s blinding */
    crs->delta_g2 = g2_mul(H, delta);

    /* Wipe trapdoor scalars from local memory. */
    alpha = beta = gamma = delta = x = tx = inv_delta = inv_gamma = 0;
    (void)alpha; (void)beta; (void)gamma; (void)delta; (void)x;
    free(u_x); free(v_x); free(w_x); free(tcoef);
    return 0;
}

void snark_crs_free(snark_crs_t *crs) {
    free(crs->A_g1); free(crs->B_g2); free(crs->B_g1);
    free(crs->L_g1); free(crs->H_g1); free(crs->IC);
    memset(crs, 0, sizeof(*crs));
}

/* ---------------- Prover ---------------- */

int snark_prove(const snark_crs_t *crs, const r1cs_t *R, const fr_t *z,
                const uint8_t rseed[32], snark_proof_t *out) {
    uint32_t n = crs->num_vars;
    uint32_t l = crs->num_pub;
    uint32_t m = crs->num_constraints;
    if (!r1cs_satisfied(R, z)) return -1;

    fr_t r = fp_from_seed(rseed, 1);
    fr_t s = fp_from_seed(rseed, 2);

    /* Build U(X), V(X), W(X) coefficients via Lagrange. */
    fr_t *bw   = barycentric_weights(m);
    fr_t *valU = calloc(m, sizeof(fr_t));
    fr_t *valV = calloc(m, sizeof(fr_t));
    fr_t *valW = calloc(m, sizeof(fr_t));
    for (uint32_t k = 0; k < m; k++) {
        valU[k] = dot(R->cs[k].a, R->cs[k].na, z);
        valV[k] = dot(R->cs[k].b, R->cs[k].nb, z);
        valW[k] = dot(R->cs[k].c, R->cs[k].nc, z);
    }
    fr_t *Uc = calloc(m, sizeof(fr_t));
    fr_t *Vc = calloc(m, sizeof(fr_t));
    fr_t *Wc = calloc(m, sizeof(fr_t));
    lagrange_coeffs(valU, bw, m, Uc);
    lagrange_coeffs(valV, bw, m, Vc);
    lagrange_coeffs(valW, bw, m, Wc);
    free(valU); free(valV); free(valW); free(bw);

    /* UV (degree 2m-2) − W (degree m-1) = h(X) · t(X) (deg 2m-2 = (m-2)+m). */
    uint32_t lUV = 2 * m - 1;
    fr_t *UV = calloc(lUV, sizeof(fr_t));
    poly_mul(Uc, m, Vc, m, UV);
    for (uint32_t i = 0; i < m; i++) UV[i] = fr_sub(UV[i], Wc[i]);
    fr_t *tcoef = calloc(m + 1, sizeof(fr_t));
    target_poly(m, tcoef);
    fr_t *hcoef = calloc(m - 1, sizeof(fr_t));
    poly_divmod(UV, lUV, tcoef, m + 1, hcoef, m - 1);
    free(UV); free(tcoef); free(Uc); free(Vc); free(Wc);

    /* Groth16 prover with full r,s blinding (δ_g1 and β_g1 in CRS):
     *   A  = α·G + Σ z_i · A_g1[i] + r · δ_g1
     *   B  = β·H + Σ z_i · B_g2[i] + s · δ_g2
     *   B' = β·G + Σ z_i · B_g1[i] + s · δ_g1     (G1 mirror of B — uses v_i)
     *   C  = Σ_{i>l} z_i · L_i + Σ h_k · H_g1[k] + r · B' + s · A − r·s·δ_g1   */
    g1_t A = crs->alpha_g1;
    for (uint32_t i = 0; i < n; i++)
        A = g1_add(A, g1_mul(crs->A_g1[i], z[i]));
    A = g1_add(A, g1_mul(crs->delta_g1, r));

    g2_t B = crs->beta_g2;
    for (uint32_t i = 0; i < n; i++)
        B = g2_add(B, g2_mul(crs->B_g2[i], z[i]));
    B = g2_add(B, g2_mul(crs->delta_g2, s));

    g1_t Bp = crs->beta_g1;
    for (uint32_t i = 0; i < n; i++)
        Bp = g1_add(Bp, g1_mul(crs->B_g1[i], z[i]));   /* B_g1[i]=v_i*G: the G1 mirror of B
                                                          must use v_i, not u_i — else the
                                                          verification residual r*delta*(V-U)
                                                          breaks the pairing identity. */
    Bp = g1_add(Bp, g1_mul(crs->delta_g1, s));

    /* C = Σ_{i>l} z_i · L_i + Σ_k h_k · H_g1[k]
     *      + s · A
     *      + r · B'
     *      − r·s · δ_g1
     *
     * Standard Groth16: this delivers full statistical zero-knowledge. */
    g1_t C = g1_mul(g1_generator(), 0);   /* zero */
    C.infinity = 1;
    for (uint32_t i = l + 1; i < n; i++)
        C = g1_add(C, g1_mul(crs->L_g1[i - l - 1], z[i]));
    for (uint32_t k = 0; k + 1 < m; k++)
        C = g1_add(C, g1_mul(crs->H_g1[k], hcoef[k]));
    free(hcoef);
    /* Blinding contributions: r·B' + s·A − r·s·δ_g1 */
    C = g1_add(C, g1_mul(Bp, r));
    C = g1_add(C, g1_mul(A,  s));
    {
        fr_t rs = fr_mul(r, s);
        g1_t neg_rs_delta = g1_mul(crs->delta_g1, rs);
        neg_rs_delta = g1_neg(neg_rs_delta);
        C = g1_add(C, neg_rs_delta);
    }

    out->A = A; out->B = B; out->C = C;
    return 0;
}

/* ---------------- Verifier ---------------- */

int snark_verify(const snark_crs_t *crs,
                 const fr_t *public_inputs, uint32_t num_pub,
                 const snark_proof_t *pi) {
    if (num_pub != crs->num_pub) return 0;
    /* IC contribution: IC[0] + Σ public_i · IC[i+1] */
    g1_t acc = crs->IC[0];
    for (uint32_t i = 0; i < num_pub; i++)
        acc = g1_add(acc, g1_mul(crs->IC[i + 1], public_inputs[i]));

    fp2_t lhs = pairing(pi->A, pi->B);
    fp2_t r1  = pairing(crs->alpha_g1, crs->beta_g2);
    fp2_t r2  = pairing(acc, crs->gamma_g2);
    fp2_t r3  = pairing(pi->C, crs->delta_g2);
    fp2_t rhs = gt_mul(gt_mul(r1, r2), r3);
    return gt_eq(lhs, rhs);
}
