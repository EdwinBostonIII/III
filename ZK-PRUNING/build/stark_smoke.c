#include <stdio.h>
#include "iii/zk_stark.h"
int main(void){
    air_t air = {.trace_len=8, .c=7, .x0=3, .T=air_square_plus_c};
    /* compute xN */
    sf_t v=air.x0; for(int i=0;i+1<(int)air.trace_len;i++) v=air.T(v,air.c);
    air.xN=v;
    printf("xN=%u\n", air.xN);
    stark_proof_t pi;
    int rc = stark_prove(&air, &pi);
    printf("prove rc=%d fri_layers=%u final=%u\n", rc, pi.fri_layers, pi.fri_final);
    int v2 = stark_verify(&air, &pi);
    printf("verify=%d\n", v2);
    /* tamper */
    pi.cp_q[0] ^= 1;
    int v3 = stark_verify(&air, &pi);
    printf("verify(tampered cp)=%d\n", v3);
    return 0;
}
