/* III ZK-PRUNING — finite-field arithmetic.
 *
 * Toy supersingular pairing-friendly setup chosen for tractability:
 *   p = 1073742203   (prime, p ≡ 11 mod 12)
 *   r = 89478517     (prime divisor of p+1, group order)
 *   E: y^2 = x^3 + 1 over Fp     (supersingular, |E(Fp)| = p+1)
 *   Embedding degree k = 2; Fp2 = Fp[u]/(u^2 + 1).
 *
 * All Fp values are stored reduced in [0, p).  p^2 < 2^60 so a single
 * uint64_t multiplication does not overflow.
 */
#ifndef III_ZK_FIELD_H
#define III_ZK_FIELD_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

#define IIIZK_P  ((uint64_t)1073742203ULL)
#define IIIZK_R  ((uint64_t)89478517ULL)
#define IIIZK_H  ((uint64_t)12ULL)

typedef uint64_t fp_t;
typedef uint64_t fr_t;                     /* scalar-field element mod r */

typedef struct { fp_t a, b; } fp2_t;       /* a + b*u, u^2 = -1 */

/* Fp */
fp_t fp_add(fp_t x, fp_t y);
fp_t fp_sub(fp_t x, fp_t y);
fp_t fp_neg(fp_t x);
fp_t fp_mul(fp_t x, fp_t y);
fp_t fp_pow(fp_t x, uint64_t e);
fp_t fp_inv(fp_t x);
fp_t fp_from_u64(uint64_t x);
int  fp_eq(fp_t x, fp_t y);

/* Fr (scalar field mod r) */
fr_t fr_add(fr_t x, fr_t y);
fr_t fr_sub(fr_t x, fr_t y);
fr_t fr_neg(fr_t x);
fr_t fr_mul(fr_t x, fr_t y);
fr_t fr_pow(fr_t x, uint64_t e);
fr_t fr_inv(fr_t x);
fr_t fr_from_u64(uint64_t x);
int  fr_eq(fr_t x, fr_t y);

/* Fp2 */
fp2_t fp2_zero(void);
fp2_t fp2_one(void);
fp2_t fp2_from_fp(fp_t x);
fp2_t fp2_mk(fp_t a, fp_t b);
fp2_t fp2_add(fp2_t x, fp2_t y);
fp2_t fp2_sub(fp2_t x, fp2_t y);
fp2_t fp2_neg(fp2_t x);
fp2_t fp2_mul(fp2_t x, fp2_t y);
fp2_t fp2_mul_fp(fp2_t x, fp_t y);
fp2_t fp2_inv(fp2_t x);
fp2_t fp2_pow(fp2_t x, uint64_t e);
fp2_t fp2_frobenius(fp2_t x);              /* x^p = (a, -b) */
int   fp2_eq(fp2_t x, fp2_t y);
int   fp2_is_zero(fp2_t x);

#ifdef __cplusplus
}
#endif
#endif
