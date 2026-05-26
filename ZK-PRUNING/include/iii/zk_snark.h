/* III ZK-PRUNING — NIH Groth16-style SNARK on the toy supersingular curve.
 *
 * Pipeline:    R1CS  ->  QAP  ->  trusted setup (CRS)  ->  prove  ->  verify.
 *
 * R1CS variables: index 0 is the constant 1, then `num_pub` public inputs,
 * then private witnesses.  Each constraint is (a · z)(b · z) = (c · z).
 */
#ifndef III_ZK_SNARK_H
#define III_ZK_SNARK_H

#include "iii/zk_curve.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    uint32_t var;
    fr_t     coeff;
} r1cs_term_t;

typedef struct {
    r1cs_term_t *a; uint32_t na;
    r1cs_term_t *b; uint32_t nb;
    r1cs_term_t *c; uint32_t nc;
} r1cs_constraint_t;

typedef struct {
    uint32_t           num_vars;     /* total wires incl. constant */
    uint32_t           num_pub;      /* public inputs (excl. constant) */
    uint32_t           num_constraints;
    r1cs_constraint_t *cs;
} r1cs_t;

void r1cs_init(r1cs_t *R, uint32_t num_vars, uint32_t num_pub);
void r1cs_add(r1cs_t *R,
              const r1cs_term_t *a, uint32_t na,
              const r1cs_term_t *b, uint32_t nb,
              const r1cs_term_t *c, uint32_t nc);
void r1cs_free(r1cs_t *R);
int  r1cs_satisfied(const r1cs_t *R, const fr_t *z);

/* Trusted-setup CRS (Groth16-style; toy: discrete-log challenges in Fp,
 * commitments are scalar multiples on G1/G2 of the trapdoor evaluations). */
typedef struct {
    /* Proving key */
    g1_t  *A_g1;     /* size num_vars */
    g2_t  *B_g2;     /* size num_vars */
    g1_t  *B_g1;     /* size num_vars */
    g1_t  *L_g1;     /* size num_vars - num_pub - 1 (private wires) */
    g1_t  *H_g1;     /* size num_constraints (powers of x · t(x)/δ) */
    /* Verifying key */
    g1_t   alpha_g1;
    g1_t   beta_g1;     /* β·G1 — required for r,s blinding in the prover */
    g2_t   beta_g2;
    g2_t   gamma_g2;
    g1_t   delta_g1;    /* δ·G1 — required for r,s blinding in A and C */
    g2_t   delta_g2;
    g1_t  *IC;       /* size num_pub + 1 */
    /* sizes */
    uint32_t num_vars;
    uint32_t num_pub;
    uint32_t num_constraints;
    uint32_t domain_size;
} snark_crs_t;

typedef struct {
    g1_t A;
    g2_t B;
    g1_t C;
} snark_proof_t;

/* Setup: derive CRS from the R1CS.  Trapdoor scalars (α,β,γ,δ,x) are
 * generated from `seed` and IMMEDIATELY consumed; the CRS does not retain
 * them.  Caller must zero `seed` after calling. */
int snark_setup(const r1cs_t *R, const uint8_t seed[32], snark_crs_t *crs);
void snark_crs_free(snark_crs_t *crs);

/* Prove: witness z[0..num_vars).  rseed: 32-byte randomness for r,s. */
int snark_prove(const snark_crs_t *crs,
                const r1cs_t *R,
                const fr_t *z,
                const uint8_t rseed[32],
                snark_proof_t *out);

/* Verify: check Groth16 equation
 *   e(A, B) == e(α, β) · e(IC(public), γ) · e(C, δ).
 */
int snark_verify(const snark_crs_t *crs,
                 const fr_t *public_inputs, uint32_t num_pub,
                 const snark_proof_t *pi);

#ifdef __cplusplus
}
#endif
#endif
