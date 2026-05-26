#include <stdio.h>
#include <string.h>
#include "iii/zk_snark.h"
int main(void){
    /* Circuit: prove knowledge of x such that x*x = y, y is public.
     * Variables: z[0]=1, z[1]=y (public), z[2]=x (private).
     * Constraint: z[2] * z[2] = z[1]
     */
    r1cs_t R; r1cs_init(&R, 3, 1);
    r1cs_term_t a[1] = {{2, 1}};
    r1cs_term_t b[1] = {{2, 1}};
    r1cs_term_t c[1] = {{1, 1}};
    r1cs_add(&R, a, 1, b, 1, c, 1);
    /* Need at least 2 constraints for QAP polynomial division (deg m-2 ≥ 0).
     * Add a trivial duplicate to make m=2. */
    r1cs_add(&R, a, 1, b, 1, c, 1);

    fp_t z[3] = {1, 49, 7};
    printf("R1CS satisfied: %d\n", r1cs_satisfied(&R, z));

    snark_crs_t crs;
    uint8_t seed[32]; for (int i=0;i<32;i++) seed[i]=i+1;
    int rc = snark_setup(&R, seed, &crs);
    printf("setup rc=%d\n", rc);

    snark_proof_t pi;
    uint8_t rs[32]; for (int i=0;i<32;i++) rs[i]=0x42^i;
    rc = snark_prove(&crs, &R, z, rs, &pi);
    printf("prove rc=%d\n", rc);

    fp_t pub[1] = {49};
    int v = snark_verify(&crs, pub, 1, &pi);
    printf("verify=%d\n", v);

    /* tamper public input */
    pub[0] = 50;
    int vbad = snark_verify(&crs, pub, 1, &pi);
    printf("verify(bad pub)=%d\n", vbad);

    snark_crs_free(&crs);
    r1cs_free(&R);
    return 0;
}
