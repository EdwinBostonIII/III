/* §4.12 BLS12-381 accumulating reference (TDD-first, §4.4 discipline).
 *
 * Grown layer by layer, each validated STRUCTURALLY before the next:
 *   Fp  (6-limb Montgomery, seed-derived p)  -- proven (_bls_fp_probe, exit 99)
 *   Fp2 = Fp[u]/(u^2+1)
 *   ... Fp6, Fp12, G1, G2, optimal-Ate pairing to follow ...
 * Once the full stack validates (pairing bilinearity + order-r + non-degeneracy),
 * this code is lifted into ZK-PRUNING/src/{field,curve}.c (gospel §4.12) and
 * then ported to numera/zk_*.iii (§4.14).
 *
 * Exit 99 = every layer's structural checks pass.
 */
#include <stdint.h>
#include <stdio.h>
#include <string.h>
typedef unsigned __int128 u128;

/* ============================ Fp (proven) ============================ */
static const uint64_t P[6] = {
    0xb9feffffffffaaabULL, 0x1eabfffeb153ffffULL, 0x6730d2a0f6b0f624ULL,
    0x64774b84f38512bfULL, 0x4b1ba7b6434bacd7ULL, 0x1a0111ea397fe69aULL
};
typedef uint64_t fp[6];

static int cmp6(const uint64_t a[6], const uint64_t b[6]) {
    for (int i = 5; i >= 0; i--) { if (a[i] < b[i]) return -1; if (a[i] > b[i]) return 1; }
    return 0;
}
static uint64_t sub6(uint64_t a[6], const uint64_t b[6]) {
    u128 br = 0;
    for (int i = 0; i < 6; i++) { u128 t = (u128)a[i] - b[i] - (uint64_t)br; a[i] = (uint64_t)t; br = (t >> 64) ? 1 : 0; }
    return (uint64_t)br;
}
static uint64_t add6(uint64_t a[6], const uint64_t b[6]) {
    u128 c = 0;
    for (int i = 0; i < 6; i++) { u128 s = (u128)a[i] + b[i] + (uint64_t)c; a[i] = (uint64_t)s; c = s >> 64; }
    return (uint64_t)c;
}
static uint64_t N0INV; static uint64_t R2[6];
static void mont_init(void) {
    uint64_t inv = P[0];
    for (int i = 0; i < 7; i++) inv *= (uint64_t)2 - P[0] * inv;
    N0INV = (uint64_t)(0 - inv);
    uint64_t t[6] = {1,0,0,0,0,0};
    for (int k = 0; k < 768; k++) { uint64_t d[6]; memcpy(d,t,48); add6(t,d); if (cmp6(t,P)>=0) sub6(t,P); }
    memcpy(R2, t, 48);
}
static void mul6(const uint64_t a[6], const uint64_t b[6], uint64_t out[12]) {
    for (int i = 0; i < 12; i++) out[i] = 0;
    for (int i = 0; i < 6; i++) {
        u128 c = 0;
        for (int j = 0; j < 6; j++) { u128 s = (u128)a[i]*b[j] + out[i+j] + (uint64_t)c; out[i+j]=(uint64_t)s; c=s>>64; }
        out[i+6] = (uint64_t)(out[i+6] + (uint64_t)c);
    }
}
static void redc(uint64_t T[13], uint64_t out[6]) {
    T[12] = 0;
    for (int i = 0; i < 6; i++) {
        uint64_t m = (uint64_t)(T[i] * N0INV);
        u128 c = 0;
        for (int j = 0; j < 6; j++) { u128 s = (u128)m*P[j] + T[i+j] + (uint64_t)c; T[i+j]=(uint64_t)s; c=s>>64; }
        int k = i + 6;
        while (c) { u128 s = (u128)T[k] + (uint64_t)c; T[k]=(uint64_t)s; c=s>>64; k++; }
    }
    for (int i = 0; i < 6; i++) out[i] = T[6+i];
    if (T[12] || cmp6(out, P) >= 0) sub6(out, P);
}
static void fp_mul(const fp a, const fp b, fp out) { uint64_t T[13], pr[12]; mul6(a,b,pr); memcpy(T,pr,96); redc(T,out); }
static void fp_add(const fp a, const fp b, fp out) { memcpy(out,a,48); add6(out,(uint64_t*)b); if (cmp6(out,P)>=0) sub6(out,P); }
static void fp_sub(const fp a, const fp b, fp out) { memcpy(out,a,48); if (cmp6(a,b)<0) add6(out,P); sub6(out,(uint64_t*)b); }
static void fp_neg(const fp a, fp out) { fp z={0,0,0,0,0,0}; fp_sub(z,a,out); }
static void fp_set_ui(uint64_t v, fp out) { out[0]=v; for(int i=1;i<6;i++) out[i]=0; }
static void to_mont(const fp a, fp out)   { fp_mul(a, R2, out); }
static void from_mont(const fp a, fp out) { fp one={1,0,0,0,0,0}; fp_mul(a, one, out); }
static void fp_one_m(fp out) { fp o={1,0,0,0,0,0}; to_mont(o, out); }
static int fp_eq(const fp a, const fp b) { return cmp6(a,b)==0; }
static int fp_is_zero(const fp a) { for(int i=0;i<6;i++) if(a[i]) return 0; return 1; }
static void fp_pow(const fp base_m, const uint64_t *exp, int elimbs, fp out) {
    fp res; fp_one_m(res); fp b; memcpy(b, base_m, 48);
    for (int i = 0; i < elimbs; i++)
        for (int bit = 0; bit < 64; bit++) { if ((exp[i]>>bit)&1) fp_mul(res,b,res); fp_mul(b,b,b); }
    memcpy(out, res, 48);
}
static void fp_inv(const fp a_m, fp out) { uint64_t e[6]; memcpy(e,P,48); e[0]-=2; fp_pow(a_m, e, 6, out); }

/* ============================ Fp2 = Fp[u]/(u^2+1) ============================ */
typedef struct { fp a, b; } fp2;   /* a + b*u, u^2 = -1 (all coords Montgomery) */

static void fp2_set(fp2 *r, const fp a, const fp b) { memcpy(r->a, a, 48); memcpy(r->b, b, 48); }
static void fp2_zero(fp2 *r) { fp z={0,0,0,0,0,0}; fp2_set(r, z, z); }
static void fp2_one(fp2 *r)  { fp o; fp_one_m(o); fp z={0,0,0,0,0,0}; fp2_set(r, o, z); }
static int  fp2_eq(const fp2 *x, const fp2 *y) { return fp_eq(x->a,y->a) && fp_eq(x->b,y->b); }
static int  fp2_is_zero(const fp2 *x) { return fp_is_zero(x->a) && fp_is_zero(x->b); }
static void fp2_add(const fp2 *x, const fp2 *y, fp2 *r) { fp_add(x->a,y->a,r->a); fp_add(x->b,y->b,r->b); }
static void fp2_sub(const fp2 *x, const fp2 *y, fp2 *r) { fp_sub(x->a,y->a,r->a); fp_sub(x->b,y->b,r->b); }
static void fp2_neg(const fp2 *x, fp2 *r) { fp_neg(x->a,r->a); fp_neg(x->b,r->b); }
static void fp2_conj(const fp2 *x, fp2 *r) { memcpy(r->a,x->a,48); fp_neg(x->b,r->b); }  /* frobenius: x^p */
static void fp2_mul(const fp2 *x, const fp2 *y, fp2 *r) {
    /* (a+bu)(c+du) = (ac-bd) + (ad+bc)u */
    fp ac, bd, ad, bc, t1, t2;
    fp_mul(x->a, y->a, ac); fp_mul(x->b, y->b, bd);
    fp_mul(x->a, y->b, ad); fp_mul(x->b, y->a, bc);
    fp_sub(ac, bd, t1); fp_add(ad, bc, t2);
    memcpy(r->a, t1, 48); memcpy(r->b, t2, 48);
}
static void fp2_sqr(const fp2 *x, fp2 *r) { fp2_mul(x, x, r); }
static void fp2_mul_fp(const fp2 *x, const fp y, fp2 *r) { fp_mul(x->a, y, r->a); fp_mul(x->b, y, r->b); }
static void fp2_inv(const fp2 *x, fp2 *r) {
    /* 1/(a+bu) = (a - bu)/(a^2 + b^2) */
    fp a2, b2, norm, ninv;
    fp_mul(x->a, x->a, a2); fp_mul(x->b, x->b, b2);
    fp_add(a2, b2, norm); fp_inv(norm, ninv);
    fp_mul(x->a, ninv, r->a);
    fp nb; fp_neg(x->b, nb); fp_mul(nb, ninv, r->b);
}
/* multiply by the cubic non-residue xi = (1 + u): (a+bu)(1+u) = (a-b) + (a+b)u */
static void fp2_mul_xi(const fp2 *x, fp2 *r) {
    fp t1, t2; fp_sub(x->a, x->b, t1); fp_add(x->a, x->b, t2);
    memcpy(r->a, t1, 48); memcpy(r->b, t2, 48);
}

/* ============================ Fp6 = Fp2[v]/(v^3 - xi), xi = 1+u ============================ */
typedef struct { fp2 c0, c1, c2; } fp6;   /* c0 + c1*v + c2*v^2 */

static void fp6_zero(fp6 *r) { fp2_zero(&r->c0); fp2_zero(&r->c1); fp2_zero(&r->c2); }
static void fp6_one(fp6 *r)  { fp2_one(&r->c0);  fp2_zero(&r->c1); fp2_zero(&r->c2); }
static int  fp6_eq(const fp6 *x, const fp6 *y) { return fp2_eq(&x->c0,&y->c0) && fp2_eq(&x->c1,&y->c1) && fp2_eq(&x->c2,&y->c2); }
static void fp6_add(const fp6 *x, const fp6 *y, fp6 *r) { fp2_add(&x->c0,&y->c0,&r->c0); fp2_add(&x->c1,&y->c1,&r->c1); fp2_add(&x->c2,&y->c2,&r->c2); }
static void fp6_sub(const fp6 *x, const fp6 *y, fp6 *r) { fp2_sub(&x->c0,&y->c0,&r->c0); fp2_sub(&x->c1,&y->c1,&r->c1); fp2_sub(&x->c2,&y->c2,&r->c2); }
static void fp6_mul(const fp6 *x, const fp6 *y, fp6 *out) {
    /* v^3 = xi.  Schoolbook:
     *   c0 = a0b0 + xi(a1b2 + a2b1)
     *   c1 = a0b1 + a1b0 + xi(a2b2)
     *   c2 = a0b2 + a1b1 + a2b0    */
    fp2 t, m, xt, c0, c1, c2;
    fp2_mul(&x->c1,&y->c2,&t); fp2_mul(&x->c2,&y->c1,&m); fp2_add(&t,&m,&t); fp2_mul_xi(&t,&xt);
    fp2_mul(&x->c0,&y->c0,&m); fp2_add(&m,&xt,&c0);
    fp2_mul(&x->c0,&y->c1,&t); fp2_mul(&x->c1,&y->c0,&m); fp2_add(&t,&m,&t);
    fp2_mul(&x->c2,&y->c2,&m); fp2_mul_xi(&m,&xt); fp2_add(&t,&xt,&c1);
    fp2_mul(&x->c0,&y->c2,&t); fp2_mul(&x->c1,&y->c1,&m); fp2_add(&t,&m,&t);
    fp2_mul(&x->c2,&y->c0,&m); fp2_add(&t,&m,&c2);
    out->c0=c0; out->c1=c1; out->c2=c2;
}
static void fp6_sqr(const fp6 *x, fp6 *r) { fp6_mul(x, x, r); }
static void fp6_inv(const fp6 *x, fp6 *r) {
    fp2 A,B,C,t,F,Fi;
    fp2_sqr(&x->c0,&A); fp2_mul(&x->c1,&x->c2,&t); fp2_mul_xi(&t,&t); fp2_sub(&A,&t,&A);     /* A=c0^2-xi c1 c2 */
    fp2_sqr(&x->c2,&B); fp2_mul_xi(&B,&B); fp2_mul(&x->c0,&x->c1,&t); fp2_sub(&B,&t,&B);      /* B=xi c2^2-c0 c1 */
    fp2_sqr(&x->c1,&C); fp2_mul(&x->c0,&x->c2,&t); fp2_sub(&C,&t,&C);                          /* C=c1^2-c0 c2 */
    fp2_mul(&x->c0,&A,&F);
    fp2_mul(&x->c2,&B,&t); fp2_mul_xi(&t,&t); fp2_add(&F,&t,&F);
    fp2_mul(&x->c1,&C,&t); fp2_mul_xi(&t,&t); fp2_add(&F,&t,&F);                               /* F=c0 A+xi c2 B+xi c1 C */
    fp2_inv(&F,&Fi);
    fp2_mul(&A,&Fi,&r->c0); fp2_mul(&B,&Fi,&r->c1); fp2_mul(&C,&Fi,&r->c2);
}
static void fp6_pow(const fp6 *base, const uint64_t *exp, int elimbs, fp6 *out) {
    fp6 res; fp6_one(&res); fp6 b; memcpy(&b, base, sizeof b);
    for (int i = 0; i < elimbs; i++)
        for (int bit = 0; bit < 64; bit++) { if ((exp[i]>>bit)&1) { fp6 t; fp6_mul(&res,&b,&t); res=t; } fp6 s; fp6_sqr(&b,&s); b=s; }
    *out = res;
}

/* multiply an Fp6 element by v: (c0+c1 v+c2 v^2)*v = xi*c2 + c0 v + c1 v^2 */
static void fp6_mul_by_v(const fp6 *x, fp6 *r) {
    fp2 t; fp2_mul_xi(&x->c2, &t);
    fp2 c1 = x->c0, c2 = x->c1;     /* snapshot for aliasing safety */
    r->c0 = t; r->c1 = c1; r->c2 = c2;
}

/* ============================ Fp12 = Fp6[w]/(w^2 - v) ============================ */
typedef struct { fp6 c0, c1; } fp12;   /* c0 + c1*w, w^2 = v */

static void fp12_one(fp12 *r) { fp6_one(&r->c0); fp6_zero(&r->c1); }
static int  fp12_eq(const fp12 *x, const fp12 *y) { return fp6_eq(&x->c0,&y->c0) && fp6_eq(&x->c1,&y->c1); }
static void fp12_mul(const fp12 *x, const fp12 *y, fp12 *out) {
    /* (a0+a1w)(b0+b1w) = (a0b0 + v a1b1) + (a0b1 + a1b0) w */
    fp6 a0b0, a1b1, vt, t1, t2, c0, c1;
    fp6_mul(&x->c0,&y->c0,&a0b0); fp6_mul(&x->c1,&y->c1,&a1b1);
    fp6_mul_by_v(&a1b1,&vt); fp6_add(&a0b0,&vt,&c0);
    fp6_mul(&x->c0,&y->c1,&t1); fp6_mul(&x->c1,&y->c0,&t2); fp6_add(&t1,&t2,&c1);
    out->c0=c0; out->c1=c1;
}
static void fp12_sqr(const fp12 *x, fp12 *r) { fp12_mul(x, x, r); }
static void fp12_inv(const fp12 *x, fp12 *r) {
    /* 1/(c0+c1w) = (c0 - c1 w)/(c0^2 - v c1^2) */
    fp6 c0s, c1s, vt, norm, ni, neg, nc1;
    fp6_sqr(&x->c0,&c0s); fp6_sqr(&x->c1,&c1s); fp6_mul_by_v(&c1s,&vt); fp6_sub(&c0s,&vt,&norm);
    fp6_inv(&norm,&ni);
    fp6_mul(&x->c0,&ni,&r->c0);
    fp6_zero(&neg); fp6_sub(&neg,&x->c1,&nc1); fp6_mul(&nc1,&ni,&r->c1);
}
static void fp12_pow(const fp12 *base, const uint64_t *exp, int elimbs, fp12 *out) {
    fp12 res; fp12_one(&res); fp12 b = *base;
    for (int i = 0; i < elimbs; i++)
        for (int bit = 0; bit < 64; bit++) { if ((exp[i]>>bit)&1) { fp12 t; fp12_mul(&res,&b,&t); res=t; } fp12 s; fp12_sqr(&b,&s); b=s; }
    *out = res;
}

/* ============================ validation ============================ */
int main(void) {
    mont_init();

    /* sample Fp value (reduced), in Montgomery form */
    fp a_pl = {0x0123456789abcdefULL,0xfedcba9876543210ULL,0x1111222233334444ULL,
               0x5555666677778888ULL,0x9999aaaabbbbccccULL,0x0a0111ea397fe600ULL};
    if (cmp6(a_pl,P)>=0) sub6(a_pl,P);
    fp am; to_mont(a_pl, am);
    fp pm1[1][6]; (void)pm1;
    /* Fp Fermat re-check (regression of the proven layer) */
    uint64_t e[6]; memcpy(e,P,48); e[0]-=1; fp fe; fp_pow(am,e,6,fe); fp fen; from_mont(fe,fen);
    if (!(fen[0]==1&&fen[1]==0&&fen[2]==0&&fen[3]==0&&fen[4]==0&&fen[5]==0)) { printf("FAIL Fp Fermat\n"); return 1; }

    /* Build two Fp2 sample values in Montgomery form. */
    fp c_pl = {0xdeadbeefcafef00dULL,0x0011223344556677ULL,0x8899aabbccddeeffULL,
               0x0f0e0d0c0b0a0908ULL,0x0706050403020100ULL,0x05a1b2c3d4e5f600ULL};
    if (cmp6(c_pl,P)>=0) sub6(c_pl,P);
    fp cm; to_mont(c_pl, cm);
    fp2 X, Y, one2;
    fp2_set(&X, am, cm);          /* X = a + c*u */
    fp2_set(&Y, cm, am);          /* Y = c + a*u */
    fp2_one(&one2);

    /* (1) identity + commutativity */
    fp2 t, s;
    fp2_mul(&X, &one2, &t); if (!fp2_eq(&t,&X)) { printf("FAIL fp2 mul identity\n"); return 2; }
    fp2 xy, yx; fp2_mul(&X,&Y,&xy); fp2_mul(&Y,&X,&yx);
    if (!fp2_eq(&xy,&yx)) { printf("FAIL fp2 mul commutative\n"); return 3; }

    /* (2) inverse roundtrip */
    fp2 xi2, chk; fp2_inv(&X,&xi2); fp2_mul(&X,&xi2,&chk);
    if (!fp2_eq(&chk,&one2)) { printf("FAIL fp2 inverse\n"); return 4; }

    /* (3) frobenius = conjugate; frob^2 = id */
    fp2 fr, fr2; fp2_conj(&X,&fr); fp2_conj(&fr,&fr2);
    if (!fp2_eq(&fr2,&X)) { printf("FAIL fp2 frob^2 != id\n"); return 5; }

    /* (4) norm a*conj(a) lies in Fp (u-component zero) */
    fp2 nrm; fp2_mul(&X,&fr,&nrm);
    if (!fp_is_zero(nrm.b)) { printf("FAIL fp2 norm not in Fp\n"); return 6; }

    /* (5) Fp2 Fermat: X^(p^2 - 1) == 1.  p^2-1 = (p-1)*(p+1); do X^(p-1) then ^(p+1). */
    /* Generic Fp2 exponentiation by a little-endian limb array. */
    /* X^(p^2-1): compute via X^(p-1) raised to (p+1).  Implement fp2_pow inline. */
    {
        /* fp2_pow(base, exp[elimbs]) */
        #define FP2POW(BASE, EXP, ELIMBS, OUT) do {                         \
            fp2 _res; fp2_one(&_res); fp2 _b; memcpy(&_b,&(BASE),sizeof(fp2)); \
            for (int _i=0;_i<(ELIMBS);_i++) for (int _bit=0;_bit<64;_bit++){  \
                if (((EXP)[_i]>>_bit)&1){ fp2 _tmp; fp2_mul(&_res,&_b,&_tmp); memcpy(&_res,&_tmp,sizeof(fp2)); } \
                fp2 _sq; fp2_sqr(&_b,&_sq); memcpy(&_b,&_sq,sizeof(fp2));      \
            } memcpy(&(OUT),&_res,sizeof(fp2)); } while(0)
        uint64_t pm1e[6]; memcpy(pm1e,P,48); pm1e[0]-=1;          /* p-1 */
        uint64_t pp1e[7]; for(int i=0;i<6;i++) pp1e[i]=P[i]; pp1e[0]+=1; pp1e[6]=0;  /* p+1 (p[0] even? p[0] odd so +1 no carry) */
        fp2 xpm1, xp2m1; FP2POW(X, pm1e, 6, xpm1); FP2POW(xpm1, pp1e, 7, xp2m1);
        if (!fp2_eq(&xp2m1,&one2)) { printf("FAIL fp2 Fermat X^(p^2-1)!=1\n"); return 7; }
        #undef FP2POW
    }
    (void)s; (void)nrm;

    /* ----- Fp6 layer ----- */
    {
        fp6 A6, B6, I6, one6; fp6_one(&one6);
        A6.c0 = X; A6.c1 = Y; A6.c2 = one2;
        B6.c0 = Y; B6.c1 = one2; B6.c2 = X;
        fp6 t1; fp6_mul(&A6, &one6, &t1); if (!fp6_eq(&t1,&A6)) { printf("FAIL fp6 identity\n"); return 8; }
        fp6 ab, ba; fp6_mul(&A6,&B6,&ab); fp6_mul(&B6,&A6,&ba);
        if (!fp6_eq(&ab,&ba)) { printf("FAIL fp6 commutative\n"); return 9; }
        fp6 abA, ba2, aBA; fp6_mul(&ab,&A6,&abA); fp6_mul(&B6,&A6,&ba2); fp6_mul(&A6,&ba2,&aBA);
        if (!fp6_eq(&abA,&aBA)) { printf("FAIL fp6 associative\n"); return 10; }
        fp6_inv(&A6,&I6); fp6 chk6; fp6_mul(&A6,&I6,&chk6);
        if (!fp6_eq(&chk6,&one6)) { printf("FAIL fp6 inverse\n"); return 11; }
        fp6 y = A6;
        for (int k = 0; k < 6; k++) { fp6 yp; fp6_pow(&y, P, 6, &yp); y = yp; }   /* y = A6^(p^6) */
        if (!fp6_eq(&y,&A6)) { printf("FAIL fp6 GF(p^6): x^(p^6)!=x\n"); return 12; }
    }

    /* ----- Fp12 layer ----- */
    {
        fp6 g0, g1, g2;
        g0.c0=X; g0.c1=Y; g0.c2=one2;
        g1.c0=Y; g1.c1=one2; g1.c2=X;
        g2.c0=one2; g2.c1=X; g2.c2=Y;
        fp12 A, B, one12; fp12_one(&one12);
        A.c0=g0; A.c1=g1; B.c0=g1; B.c1=g2;
        fp12 t1; fp12_mul(&A,&one12,&t1); if(!fp12_eq(&t1,&A)){printf("FAIL fp12 identity\n");return 13;}
        fp12 ab,ba; fp12_mul(&A,&B,&ab); fp12_mul(&B,&A,&ba); if(!fp12_eq(&ab,&ba)){printf("FAIL fp12 commutative\n");return 14;}
        fp12 abA,ba2,aBA; fp12_mul(&ab,&A,&abA); fp12_mul(&B,&A,&ba2); fp12_mul(&A,&ba2,&aBA); if(!fp12_eq(&abA,&aBA)){printf("FAIL fp12 associative\n");return 15;}
        fp12 iv,chk; fp12_inv(&A,&iv); fp12_mul(&A,&iv,&chk); if(!fp12_eq(&chk,&one12)){printf("FAIL fp12 inverse\n");return 16;}
        fp12 y=A; for(int k=0;k<12;k++){ fp12 yp; fp12_pow(&y,P,6,&yp); y=yp; } if(!fp12_eq(&y,&A)){printf("FAIL fp12 GF(p^12): x^(p^12)!=x\n");return 17;}
    }
    printf("BLS12-381 Fp ok; Fp2 ok; Fp6 ok; Fp12 ok (axioms + GF(p^12) x^(p^12)=x).\n");
    return 99;
}
