/* III ZK-PRUNING — comprehensive test suite. */
#include "iii/zk.h"
#include "iii/sha256.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int g_pass = 0, g_fail = 0;
#define CHECK(cond, name) do {                                    \
    if (cond) { g_pass++; printf("  ok    %s\n", name); }         \
    else      { g_fail++; printf("  FAIL  %s\n", name); }         \
} while (0)

/* ---------- Field tests ---------- */

static void test_fp(void) {
    puts("[Fp]");
    fp_t a = fp_from_u64(123456789);
    fp_t b = fp_from_u64(987654321);
    CHECK(fp_eq(fp_add(a, b), fp_add(b, a)), "fp_add commutative");
    CHECK(fp_eq(fp_mul(a, b), fp_mul(b, a)), "fp_mul commutative");
    fp_t inv = fp_inv(a);
    CHECK(fp_eq(fp_mul(a, inv), 1), "fp_inv roundtrip");
    CHECK(fp_eq(fp_pow(a, IIIZK_P - 1), 1), "Fermat little theorem");
    CHECK(fp_eq(fp_sub(a, a), 0), "fp_sub self = 0");
}

static void test_fr(void) {
    puts("[Fr]");
    fr_t a = fr_from_u64(42);
    fr_t b = fr_from_u64(IIIZK_R - 7);
    CHECK(fr_eq(fr_add(a, b), fr_add(b, a)), "fr_add commutative");
    fr_t inv = fr_inv(a);
    CHECK(fr_eq(fr_mul(a, inv), 1), "fr_inv roundtrip");
    CHECK(fr_eq(fr_pow(a, IIIZK_R - 1), 1), "Fermat in Fr");
}

static void test_fp2(void) {
    puts("[Fp2]");
    fp2_t a = fp2_mk(7, 11);
    fp2_t b = fp2_mk(IIIZK_P - 3, 5);
    fp2_t one = fp2_one();
    CHECK(fp2_eq(fp2_mul(a, one), a), "fp2 mul identity");
    CHECK(fp2_eq(fp2_mul(a, b), fp2_mul(b, a)), "fp2 mul commutative");
    fp2_t inv = fp2_inv(a);
    CHECK(fp2_eq(fp2_mul(a, inv), one), "fp2 inv roundtrip");
}

/* ---------- Curve / pairing tests ---------- */

static void test_curve(void) {
    puts("[Curve / pairing]");
    g1_t G = g1_generator();
    g2_t H = g2_generator();
    CHECK(g1_on_curve(G), "G1 generator on curve");
    CHECK(g2_on_curve(H), "G2 generator on curve");
    g1_t rG = g1_mul(G, IIIZK_R);
    CHECK(rG.infinity, "r·G == O (G has order r)");
    g2_t rH = g2_mul(H, IIIZK_R);
    CHECK(rH.infinity, "r·H == O");
    /* (G+H)+K == G+(H+K) for some random points */
    g1_t P = g1_mul(G, 5);
    g1_t Q = g1_mul(G, 7);
    g1_t R = g1_mul(G, 11);
    CHECK(g1_eq(g1_add(g1_add(P, Q), R), g1_add(P, g1_add(Q, R))), "G1 add associative");

    /* Pairing non-degeneracy and bilinearity. */
    fp2_t e = pairing(G, H);
    CHECK(!fp2_eq(e, fp2_one()), "pairing e(G,H) != 1");
    CHECK(fp2_eq(gt_pow(e, IIIZK_R), fp2_one()), "e(G,H)^r == 1");
    fp2_t lhs = pairing(g1_mul(G, 7), g2_mul(H, 11));
    fp2_t rhs = gt_pow(e, 77);
    CHECK(fp2_eq(lhs, rhs), "bilinearity e(7G,11H) = e(G,H)^77");
}

/* ---------- SNARK tests (x*x = y) ---------- */

static void build_xxy_circuit(r1cs_t *R) {
    /* vars: 0=1, 1=y(pub), 2=x(priv) */
    r1cs_init(R, 3, 1);
    r1cs_term_t a[1] = { {2, 1} };
    r1cs_term_t b[1] = { {2, 1} };
    r1cs_term_t c[1] = { {1, 1} };
    /* duplicate constraint so num_constraints >= 2 (QAP needs domain >=2). */
    r1cs_add(R, a, 1, b, 1, c, 1);
    r1cs_add(R, a, 1, b, 1, c, 1);
}

static void test_snark(void) {
    puts("[SNARK]");
    r1cs_t R; build_xxy_circuit(&R);
    fr_t z[3] = {1, 49, 7};
    CHECK(r1cs_satisfied(&R, z), "R1CS satisfied for x=7,y=49");
    fr_t bad[3] = {1, 50, 7};
    CHECK(!r1cs_satisfied(&R, bad), "R1CS rejects bad witness");

    uint8_t seed[32]; for (int i=0;i<32;i++) seed[i] = (uint8_t)(0x55 ^ i);
    snark_crs_t crs;
    CHECK(snark_setup(&R, seed, &crs) == 0, "snark_setup");
    snark_proof_t pi;
    uint8_t rseed[32] = {0};
    CHECK(snark_prove(&crs, &R, z, rseed, &pi) == 0, "snark_prove");
    fr_t pub[1] = { 49 };
    CHECK(snark_verify(&crs, pub, 1, &pi) == 1, "snark_verify accepts");
    fr_t bad_pub[1] = { 48 };
    CHECK(snark_verify(&crs, bad_pub, 1, &pi) == 0, "snark_verify rejects tampered public");

    snark_proof_t tampered = pi;
    tampered.A = g1_add(tampered.A, g1_generator());
    CHECK(snark_verify(&crs, pub, 1, &tampered) == 0, "snark_verify rejects tampered A");

    snark_crs_free(&crs);
    r1cs_free(&R);
}

/* ---------- STARK tests ---------- */

static void test_stark(void) {
    puts("[STARK]");
    /* sf arithmetic */
    sf_t a = 12345, b = 67890;
    CHECK(sf_mul(a, sf_inv(a)) == 1, "sf_inv roundtrip");
    /* NTT roundtrip */
    sf_t buf[16], orig[16];
    for (int i=0;i<16;i++) buf[i] = orig[i] = (sf_t)((i*7 + 3) % 1000);
    sf_t w = sf_root_of_unity(16);
    ntt(buf, 16, w);
    intt(buf, 16, w);
    int eq = 1; for (int i=0;i<16;i++) if (buf[i] != orig[i]) { eq=0; break; }
    CHECK(eq, "NTT/INTT roundtrip");
    (void)a; (void)b;

    /* Merkle */
    sf_t leaves[8] = {1,2,3,4,5,6,7,8};
    merkle_t m; merkle_build(&m, leaves, 8);
    uint8_t root[32]; merkle_root(&m, root);
    uint8_t path[3][32];
    uint32_t plen = merkle_open(&m, 5, path);
    CHECK(merkle_verify(root, 8, 5, leaves[5], (const uint8_t (*)[32])path, plen), "merkle open/verify");
    CHECK(!merkle_verify(root, 8, 5, leaves[5] ^ 1, (const uint8_t (*)[32])path, plen), "merkle rejects bad leaf");
    merkle_free(&m);

    /* Prove/verify */
    air_t air = {.trace_len=8, .c=7, .x0=3, .T=air_square_plus_c};
    sf_t v = air.x0; for (int i=0;i+1<8;i++) v = air.T(v, air.c); air.xN = v;
    stark_proof_t pi;
    CHECK(stark_prove(&air, &pi) == 0, "stark_prove");
    CHECK(stark_verify(&air, &pi) == 1, "stark_verify accepts");
    pi.cp_q[0] ^= 1;
    CHECK(stark_verify(&air, &pi) == 0, "stark_verify rejects tampered cp_q");
}

/* ---------- Pruning tests ---------- */

static void mk_witness(xii_witness_t *w, const uint8_t pred[32], uint16_t kind, uint64_t flags) {
    memset(w, 0, sizeof(*w));
    memcpy(w->predecessor_mhash, pred, 32);
    w->cycle_kind[14] = (uint8_t)(kind >> 8);
    w->cycle_kind[15] = (uint8_t)kind;
    w->flags = flags;
    /* synthesize a payload mhash from kind+flags so witnesses differ */
    uint8_t buf[10] = {(uint8_t)kind, (uint8_t)(kind>>8), 0,0,0,0,0,0,0,0};
    for (int i=0;i<8;i++) buf[2+i] = (uint8_t)(flags >> (8*i));
    iii_sha256(buf, sizeof(buf), w->payload_mhash);
}

static void chain_link(xii_witness_t *stream, uint32_t n, const uint8_t pred[32]) {
    uint8_t cur[32]; memcpy(cur, pred, 32);
    for (uint32_t i=0;i<n;i++) {
        memcpy(stream[i].predecessor_mhash, cur, 32);
        iiizk_witness_mhash(&stream[i], cur);
    }
}

static void test_pruning(void) {
    puts("[Pruning]");
    xii_witness_t w; uint8_t z[32] = {0};

    mk_witness(&w, z, XII_CYCLE_KIND_NORMAL, 0);
    CHECK(!iiizk_is_preserved(&w), "normal not preserved");

    mk_witness(&w, z, XII_CYCLE_KIND_NORMAL, WITNESS_FLAGS_ANCHOR_AWARE);
    CHECK(iiizk_is_preserved(&w), "anchor-aware preserved");

    mk_witness(&w, z, XII_CYCLE_KIND_AMENDMENT_T2, 0);
    CHECK(iiizk_is_preserved(&w), "amendment T2 preserved");

    mk_witness(&w, z, XII_CYCLE_KIND_COMPROMISE_HIGH, 0);
    CHECK(iiizk_is_preserved(&w), "compromise-high preserved");

    mk_witness(&w, z, XII_CYCLE_KIND_SUITE_SWAP, 0);
    CHECK(iiizk_is_preserved(&w), "suite-swap preserved");

    mk_witness(&w, z, XII_CYCLE_KIND_DRTM_RELAUNCH, 0);
    CHECK(iiizk_is_preserved(&w), "DRTM relaunch preserved");

    mk_witness(&w, z, XII_CYCLE_KIND_NORMAL, WITNESS_FLAGS_FIRST_OF_EPOCH);
    CHECK(iiizk_is_preserved(&w), "first-of-epoch preserved");

    /* Chain consistency */
    xii_witness_t s[5];
    for (int i=0;i<5;i++) mk_witness(&s[i], z, XII_CYCLE_KIND_NORMAL, (uint64_t)i);
    chain_link(s, 5, z);
    CHECK(iiizk_chain_consistent(s, 5, z), "chain consistent");
    s[2].flags ^= 1;       /* break */
    CHECK(!iiizk_chain_consistent(s, 5, z), "chain break detected");
    chain_link(s, 5, z);   /* restore */

    /* Sidecar build + determinism */
    /* Mark idx 1 as preserved via amendment kind. */
    mk_witness(&s[1], z, XII_CYCLE_KIND_AMENDMENT_T1, 0);
    chain_link(s, 5, z);
    iiizk_sidecar_t sc, sc2;
    CHECK(iiizk_sidecar_build(s, 5, z, &sc) == 0, "sidecar build");
    CHECK(sc.preserved_count == 1, "preserved_count == 1");
    CHECK(iiizk_sidecar_build(s, 5, z, &sc2) == 0, "sidecar build 2");
    CHECK(memcmp(sc.body_hash, sc2.body_hash, 32) == 0, "sidecar body deterministic");
    iiizk_sidecar_free(&sc2);

    /* Rollup witness + verify */
    xii_witness_t rw;
    uint8_t key[32]; for (int i=0;i<32;i++) key[i] = (uint8_t)i;
    iiizk_rollup_witness(&sc, 1234567ull, key, &rw);
    CHECK(iiizk_rollup_verify(&rw, &sc, s, 5) == 0, "rollup verify accepts");

    /* Tamper sidecar — drop a preserved entry. */
    iiizk_sidecar_t bad = sc;
    bad.preserved_mhashes = NULL;
    bad.preserved_count = 0;
    iiizk_sidecar_root(&bad, bad.body_hash);
    CHECK(iiizk_rollup_verify(&rw, &bad, s, 5) != 0, "rollup verify rejects body mismatch");

    /* Predecessor mismatch */
    uint8_t bad_pred[32]; memset(bad_pred, 0xAB, 32);
    CHECK(iiizk_sidecar_build(s, 5, bad_pred, &sc2) == -1, "sidecar rejects bad predecessor");

    iiizk_sidecar_free(&sc);
}

int main(void) {
    test_fp();
    test_fr();
    test_fp2();
    test_curve();
    test_snark();
    test_stark();
    test_pruning();
    printf("\n=== %d passed, %d failed ===\n", g_pass, g_fail);
    return g_fail ? 1 : 0;
}
