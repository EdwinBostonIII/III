#include <stdio.h>
#include "iii/zk_curve.h"
int main(void){
    fp2_t z = iiizk_zeta();
    fp2_t z3 = fp2_pow(z, 3);
    printf("zeta = (%llu, %llu)\n", (unsigned long long)z.a, (unsigned long long)z.b);
    printf("zeta^3 = (%llu, %llu)\n", (unsigned long long)z3.a, (unsigned long long)z3.b);
    printf("zeta^3 == 1: %d\n", fp2_eq(z3, fp2_one()));

    g1_t G = g1_generator();
    printf("G on curve: %d  G=(%llu,%llu) inf=%d\n", g1_on_curve(G),
        (unsigned long long)G.x,(unsigned long long)G.y, G.infinity);
    g1_t rG = g1_mul(G, IIIZK_R);
    printf("r*G is infinity: %d\n", rG.infinity);

    g2_t H = g2_generator();
    printf("H on curve: %d\n", g2_on_curve(H));
    g2_t rH = g2_mul(H, IIIZK_R);
    printf("r*H is infinity: %d\n", rH.infinity);

    /* bilinearity: e(aG, bH) == e(G, H)^(ab) */
    fp2_t e1 = pairing(G, H);
    printf("e(G,H) = (%llu, %llu)\n", (unsigned long long)e1.a, (unsigned long long)e1.b);
    printf("e(G,H) != 1: %d\n", !fp2_eq(e1, fp2_one()));
    fp2_t er = fp2_pow(e1, IIIZK_R);
    printf("e(G,H)^r == 1: %d\n", fp2_eq(er, fp2_one()));

    g1_t aG = g1_mul(G, 7);
    g2_t bH = g2_mul(H, 11);
    fp2_t lhs = pairing(aG, bH);
    fp2_t rhs = fp2_pow(e1, 77);
    printf("bilinear: %d\n", fp2_eq(lhs, rhs));
    return 0;
}
