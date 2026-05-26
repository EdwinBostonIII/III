/* III ZK-PRUNING — elliptic curve E: y^2 = x^3 + 1 / Fp and pairing.
 *
 * G1 = E(Fp)[r].
 * G2 = ψ(E(Fp)[r]) ⊂ E(Fp2)[r] via distortion ψ(x,y) = (ζ·x, y),
 *      where ζ ∈ Fp2 is a primitive cube root of unity.
 * GT = subgroup of order r in Fp2*.
 *
 * Pairing: modified Tate pairing
 *   ê(P, Q) = f_{r,P}(ψ(Q)) ^ ((p^2 - 1)/r)
 * computed with Miller's algorithm.  Bilinear, non-degenerate.
 */
#ifndef III_ZK_CURVE_H
#define III_ZK_CURVE_H

#include "iii/zk_field.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct { fp_t x, y; int infinity; } g1_t;
typedef struct { fp2_t x, y; int infinity; } g2_t;

/* Distortion map cube root of unity ζ in Fp2. */
fp2_t iiizk_zeta(void);

/* G1 (points over Fp on y^2 = x^3 + 1) */
g1_t g1_zero(void);
g1_t g1_generator(void);                   /* fixed generator of order r */
int  g1_on_curve(g1_t P);
int  g1_eq(g1_t P, g1_t Q);
g1_t g1_neg(g1_t P);
g1_t g1_add(g1_t P, g1_t Q);
g1_t g1_dbl(g1_t P);
g1_t g1_mul(g1_t P, uint64_t k);

/* G2 — points over Fp2 on the same curve equation. */
g2_t g2_zero(void);
g2_t g2_from_g1(g1_t P);                   /* ψ(P) */
g2_t g2_generator(void);                   /* ψ(g1_generator()) */
int  g2_on_curve(g2_t P);
int  g2_eq(g2_t P, g2_t Q);
g2_t g2_neg(g2_t P);
g2_t g2_add(g2_t P, g2_t Q);
g2_t g2_dbl(g2_t P);
g2_t g2_mul(g2_t P, uint64_t k);

/* Pairing — output element of GT ⊂ Fp2*. */
fp2_t pairing(g1_t P, g2_t Q);
fp2_t gt_mul(fp2_t a, fp2_t b);
fp2_t gt_pow(fp2_t a, uint64_t e);
int   gt_eq(fp2_t a, fp2_t b);

#ifdef __cplusplus
}
#endif
#endif
