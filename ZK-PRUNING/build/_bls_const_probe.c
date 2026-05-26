/* §4.12 BLS12-381 constant-derivation probe (TDD-first, §4.4 discipline).
 *
 * Derives the base-field prime p and the scalar-field order r from the
 * standard BLS12-381 seed  x = -0xd201000000010000  via the BLS12 family
 * parameterization, then CROSS-VALIDATES every 64-bit limb against the
 * canonical published BLS12-381 values.  Agreement proves both the
 * derivation formula AND the hardcoded reference limbs simultaneously
 * (neither can be wrong without the other also being wrong), giving a
 * transcription-risk-free foundation for the field/curve/pairing build.
 *
 *   r(x) = x^4 - x^2 + 1
 *   p(x) = (x-1)^2 / 3 * r(x) + x
 * with x = -|x|, |x| = 0xd201000000010000:
 *   r = |x|^4 - |x|^2 + 1
 *   p = (|x|+1)^2 / 3 * r - |x|
 *
 * Exit 99 = every limb of p and r matches canonical.  Other codes localise.
 */
#include <stdint.h>
#include <stdio.h>
typedef unsigned __int128 u128;

/* out[0..na+nb-1] = a[0..na-1] * b[0..nb-1]  (little-endian, schoolbook). */
static void mul_nm(const uint64_t *a, int na, const uint64_t *b, int nb, uint64_t *out) {
    for (int i = 0; i < na + nb; i++) out[i] = 0;
    for (int i = 0; i < na; i++) {
        u128 c = 0;
        for (int j = 0; j < nb; j++) {
            u128 s = (u128)a[i] * b[j] + out[i + j] + (uint64_t)c;
            out[i + j] = (uint64_t)s; c = s >> 64;
        }
        out[i + nb] = (uint64_t)(out[i + nb] + (uint64_t)c);
    }
}
/* a -= b (na limbs, b zero-extended to na); assumes a >= b. */
static void sub_n(uint64_t *a, const uint64_t *b, int na, int nb) {
    u128 br = 0;
    for (int i = 0; i < na; i++) {
        u128 bi = (i < nb) ? (u128)b[i] : 0;
        u128 t = (u128)a[i] - bi - (uint64_t)br;
        a[i] = (uint64_t)t; br = (t >> 64) ? 1 : 0;
    }
}
/* a += b (na limbs, b zero-extended). */
static void add_n(uint64_t *a, const uint64_t *b, int na, int nb) {
    u128 c = 0;
    for (int i = 0; i < na; i++) {
        u128 bi = (i < nb) ? (u128)b[i] : 0;
        u128 s = (u128)a[i] + bi + (uint64_t)c;
        a[i] = (uint64_t)s; c = s >> 64;
    }
}
/* a /= 3 exact (little-endian, n limbs). Remainder must be 0. */
static uint64_t div3(uint64_t *a, int n) {
    u128 rem = 0;
    for (int i = n - 1; i >= 0; i--) {
        u128 cur = (rem << 64) | a[i];
        a[i] = (uint64_t)(cur / 3);
        rem = cur % 3;
    }
    return (uint64_t)rem;
}
/* a *= s (small), in place (n limbs). */
static void mul_small(uint64_t *a, int n, uint64_t s) {
    u128 c = 0;
    for (int i = 0; i < n; i++) { u128 p = (u128)a[i] * s + c; a[i] = (uint64_t)p; c = p >> 64; }
}
/* dst[0..n-1] = src scaled by s, then accumulate into acc[0..n-1]. */
static void add_scaled(uint64_t *acc, const uint64_t *src, int n, uint64_t s) {
    uint64_t tmp[16];
    for (int i = 0; i < n; i++) tmp[i] = src[i];
    mul_small(tmp, n, s);
    add_n(acc, tmp, n, n);
}

static void print_be(const char *name, const uint64_t *a, int n) {
    printf("%s = 0x", name);
    for (int i = n - 1; i >= 0; i--) printf("%016llx", (unsigned long long)a[i]);
    printf("\n");
}
static int bn_cmp(const uint64_t *a, const uint64_t *b, int n) {
    for (int i = n - 1; i >= 0; i--) { if (a[i] < b[i]) return -1; if (a[i] > b[i]) return 1; }
    return 0;
}
/* Q[0..ln-1] = N[0..ln-1] / D[0..ld-1], bit-by-bit (remainder discarded). */
static void bn_divmod(const uint64_t *N, int ln, const uint64_t *D, int ld, uint64_t *Q) {
    uint64_t rem[12]; uint64_t D12[12];
    for (int i = 0; i < 12; i++) { rem[i] = 0; D12[i] = (i < ld) ? D[i] : 0; }
    for (int i = 0; i < ln; i++) Q[i] = 0;
    for (int b = ln * 64 - 1; b >= 0; b--) {
        uint64_t carry = 0;                          /* rem <<= 1 */
        for (int i = 0; i < 12; i++) { uint64_t nc = rem[i] >> 63; rem[i] = (rem[i] << 1) | carry; carry = nc; }
        rem[0] |= (N[b / 64] >> (b % 64)) & 1;       /* bring down bit b */
        if (bn_cmp(rem, D12, 12) >= 0) {
            u128 br = 0;                             /* rem -= D */
            for (int i = 0; i < 12; i++) { u128 t = (u128)rem[i] - D12[i] - (uint64_t)br; rem[i] = (uint64_t)t; br = (t >> 64) ? 1 : 0; }
            Q[b / 64] |= (uint64_t)1 << (b % 64);
        }
    }
}

int main(void) {
    const uint64_t X = 0xd201000000010000ULL;   /* |seed| */

    /* r = X^4 - X^2 + 1 */
    uint64_t x2[4], x4[8];
    mul_nm(&X, 1, &X, 1, x2);                    /* X^2  (2 limbs; x2[2..3]=0) */
    mul_nm(x2, 2, x2, 2, x4);                    /* X^4  (4 limbs) */
    uint64_t r[6] = {0};
    for (int i = 0; i < 4; i++) r[i] = x4[i];
    sub_n(r, x2, 6, 2);                          /* -X^2 */
    uint64_t one = 1;
    add_n(r, &one, 6, 1);                        /* +1   -> r (255-bit, 4 limbs) */

    /* p = (X+1)^2 / 3 * r - X */
    uint64_t xp1 = X + 1;
    uint64_t sq[2];
    mul_nm(&xp1, 1, &xp1, 1, sq);                /* (X+1)^2 (2 limbs) */
    uint64_t rem3 = div3(sq, 2);                 /* /3 exact */
    uint64_t p[6];
    mul_nm(sq, 2, r, 4, p);                      /* sq3 * r (6 limbs) */
    sub_n(p, &X, 6, 1);                          /* -X -> p (381-bit, 6 limbs) */

    print_be("p", p, 6);
    print_be("r", r, 4);
    printf("(X+1)^2 mod 3 remainder = %llu (must be 0)\n", (unsigned long long)rem3);

    /* Canonical BLS12-381 limbs (little-endian). */
    const uint64_t P_REF[6] = {
        0xb9feffffffffaaabULL, 0x1eabfffeb153ffffULL, 0x6730d2a0f6b0f624ULL,
        0x64774b84f38512bfULL, 0x4b1ba7b6434bacd7ULL, 0x1a0111ea397fe69aULL
    };
    const uint64_t R_REF[4] = {
        0xffffffff00000001ULL, 0x53bda402fffe5bfeULL,
        0x3339d80809a1d805ULL, 0x73eda753299d7d48ULL
    };

    int fail = 0;
    for (int i = 0; i < 6; i++) if (p[i] != P_REF[i]) { printf("  p limb %d MISMATCH: got %016llx want %016llx\n", i, (unsigned long long)p[i], (unsigned long long)P_REF[i]); fail = 1; }
    for (int i = 0; i < 4; i++) if (r[i] != R_REF[i]) { printf("  r limb %d MISMATCH: got %016llx want %016llx\n", i, (unsigned long long)r[i], (unsigned long long)R_REF[i]); fail = 1; }
    if (rem3 != 0) fail = 1;

    /* G2 cofactor h2 = (x^8 - 4x^7 + 5x^6 - 4x^4 + 6x^3 - 4x^2 - 4x + 13)/9, x=-X.
     * With x=-X: h2*9 = X^8 + 4X^7 + 5X^6 - 4X^4 - 6X^3 - 4X^2 + 4X + 13. */
    {
        uint64_t X1b[12]={0}; X1b[0]=X;
        uint64_t X2b[12]={0}, X3b[12]={0}, X4b[12]={0}, X6b[12]={0}, X7b[12]={0}, X8b[12]={0};
        mul_nm(X1b,1,X1b,1,X2b);
        mul_nm(X2b,2,X1b,1,X3b);
        mul_nm(X2b,2,X2b,2,X4b);
        mul_nm(X3b,3,X3b,3,X6b);
        mul_nm(X6b,6,X1b,1,X7b);
        mul_nm(X4b,4,X4b,4,X8b);
        uint64_t one[12]={0}; one[0]=1;
        uint64_t pos[12]={0}, neg[12]={0};
        add_n(pos, X8b, 12, 12);
        add_scaled(pos, X7b, 12, 4);
        add_scaled(pos, X6b, 12, 5);
        add_scaled(pos, X1b, 12, 4);     /* +4X */
        add_scaled(pos, one, 12, 13);    /* +13 */
        add_scaled(neg, X4b, 12, 4);
        add_scaled(neg, X3b, 12, 6);
        add_scaled(neg, X2b, 12, 4);
        sub_n(pos, neg, 12, 12);          /* pos = h2 * 9 */
        uint64_t r9a = div3(pos, 12);
        uint64_t r9b = div3(pos, 12);     /* /9 = /3 /3 */
        printf("h2/9 remainder = (%llu,%llu) (must be 0,0)\n", (unsigned long long)r9a, (unsigned long long)r9b);
        printf("h2 = 0x"); for (int i=11;i>=0;i--) printf("%016llx",(unsigned long long)pos[i]); printf("\n");
        printf("h2 u32 LE limbs (paste into zk_field.iii ZK_H2):\n");
        int i = 0;
        while (i < 8) {
            printf("    ZK_H2[%d]=0x%08xu32 ZK_H2[%d]=0x%08xu32\n",
                   2*i, (unsigned)(pos[i] & 0xFFFFFFFF), 2*i+1, (unsigned)(pos[i] >> 32));
            i++;
        }
    }

    /* Final-exponentiation exponent E = (p^12 - 1)/r for the optimal-Ate pairing. */
    {
        uint64_t p2[80]={0}, p4[80]={0}, p8[80]={0}, p12[80]={0};
        mul_nm(p,6,p,6,p2);
        mul_nm(p2,12,p2,12,p4);
        mul_nm(p4,24,p4,24,p8);
        mul_nm(p8,48,p4,24,p12);
        uint64_t N[80]; for (int i=0;i<80;i++) N[i]=p12[i];
        uint64_t one[80]={0}; one[0]=1; sub_n(N, one, 80, 80);     /* N = p^12 - 1 */
        uint64_t E[80]={0};
        bn_divmod(N, 80, R_REF, 4, E);
        uint64_t chk[160]={0}; mul_nm(E,80,R_REF,4,chk);
        int eqN = 1;
        for (int i=0;i<80;i++) if (chk[i]!=N[i]) eqN=0;
        for (int i=80;i<84;i++) if (chk[i]!=0) eqN=0;
        printf("final-exp E*r == p^12-1 : %s\n", eqN ? "OK" : "MISMATCH!");
        int el = 80; while (el > 1 && E[el-1]==0) el--;
        printf("E significant: %d u64 (%d u32) limbs; ZK_FEXP[] for zk_field.iii:\n", el, el*2);
        int i = 0;
        while (i < el) {
            printf("    ZK_FEXP[%d]=0x%08xu32 ZK_FEXP[%d]=0x%08xu32\n",
                   2*i, (unsigned)(E[i] & 0xFFFFFFFF), 2*i+1, (unsigned)(E[i] >> 32));
            i++;
        }
    }

    if (!fail) { printf("ALL LIMBS MATCH canonical BLS12-381 p and r.\n"); return 99; }
    return 1;
}
