/* III ZK-PRUNING — command-line tool.
 *
 * Subcommands:
 *   iii_zk_tool selfcheck            — run a built-in SNARK + STARK + prune demo.
 *   iii_zk_tool snark-demo           — Groth16 setup/prove/verify of x*x=y.
 *   iii_zk_tool stark-demo N C X0    — STARK over T(x)=x^2+c, trace length N.
 *   iii_zk_tool prune-demo N         — synthesize an N-witness window with one
 *                                      preserved entry, build sidecar + rollup,
 *                                      verify the rollup.
 */
#include "iii/zk.h"
#include "iii/sha256.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int do_snark_demo(void) {
    r1cs_t R; r1cs_init(&R, 3, 1);
    r1cs_term_t a[1] = { {2, 1} };
    r1cs_term_t b[1] = { {2, 1} };
    r1cs_term_t c[1] = { {1, 1} };
    r1cs_add(&R, a, 1, b, 1, c, 1);
    r1cs_add(&R, a, 1, b, 1, c, 1);

    fr_t z[3] = {1, 49, 7};
    if (!r1cs_satisfied(&R, z)) { puts("R1CS not satisfied"); return 1; }

    uint8_t seed[32]; for (int i=0;i<32;i++) seed[i] = (uint8_t)(0xA5 ^ i);
    snark_crs_t crs;
    if (snark_setup(&R, seed, &crs) != 0) { puts("setup failed"); return 1; }
    snark_proof_t pi;
    uint8_t rseed[32] = {0};
    if (snark_prove(&crs, &R, z, rseed, &pi) != 0) { puts("prove failed"); return 1; }
    fr_t pub[1] = {49};
    int v = snark_verify(&crs, pub, 1, &pi);
    printf("snark verify (x=7,y=49) = %d\n", v);
    snark_crs_free(&crs); r1cs_free(&R);
    return v ? 0 : 1;
}

static int do_stark_demo(uint32_t N, sf_t c, sf_t x0) {
    air_t air = {.trace_len = N, .c = c, .x0 = x0, .T = air_square_plus_c};
    sf_t v = x0; for (uint32_t i=0;i+1<N;i++) v = air.T(v, c); air.xN = v;
    stark_proof_t *pi = calloc(1, sizeof(*pi));
    if (stark_prove(&air, pi) != 0) { puts("prove failed"); free(pi); return 1; }
    int ok = stark_verify(&air, pi);
    printf("stark verify (N=%u, c=%u, x0=%u, xN=%u) = %d\n", N, c, x0, air.xN, ok);
    free(pi);
    return ok ? 0 : 1;
}

static int do_prune_demo(uint32_t N) {
    if (N < 2) N = 2;
    xii_witness_t *s = calloc(N, sizeof(*s));
    uint8_t z[32] = {0};
    for (uint32_t i = 0; i < N; i++) {
        uint16_t kind = (i == N/2) ? XII_CYCLE_KIND_AMENDMENT_T2
                                   : XII_CYCLE_KIND_NORMAL;
        s[i].cycle_kind[14] = (uint8_t)(kind >> 8);
        s[i].cycle_kind[15] = (uint8_t)kind;
        s[i].flags = i;
        uint8_t buf[2] = {(uint8_t)i, (uint8_t)(i>>8)};
        iii_sha256(buf, 2, s[i].payload_mhash);
    }
    /* link chain */
    uint8_t cur[32]; memcpy(cur, z, 32);
    for (uint32_t i=0;i<N;i++) {
        memcpy(s[i].predecessor_mhash, cur, 32);
        iiizk_witness_mhash(&s[i], cur);
    }

    iiizk_sidecar_t sc;
    if (iiizk_sidecar_build(s, N, z, &sc) != 0) { puts("sidecar build failed"); free(s); return 1; }

    xii_witness_t rw;
    uint8_t key[32] = {0};
    iiizk_rollup_witness(&sc, 0, key, &rw);
    int rv = iiizk_rollup_verify(&rw, &sc, s, N);
    printf("window=%u preserved=%u ratio_q14=%u rollup_verify=%d\n",
           sc.window_count, sc.preserved_count, sc.compaction_ratio_q14, rv);
    iiizk_sidecar_free(&sc);
    free(s);
    return rv == 0 ? 0 : 1;
}

static int do_selfcheck(void) {
    if (do_snark_demo() != 0) return 1;
    if (do_stark_demo(8, 7, 3) != 0) return 1;
    if (do_prune_demo(8) != 0) return 1;
    puts("selfcheck OK");
    return 0;
}

static void usage(void) {
    puts("iii_zk_tool {selfcheck|snark-demo|stark-demo N C X0|prune-demo N}");
}

int main(int argc, char **argv) {
    if (argc < 2) { usage(); return 1; }
    const char *cmd = argv[1];
    if (!strcmp(cmd, "selfcheck"))   return do_selfcheck();
    if (!strcmp(cmd, "snark-demo"))  return do_snark_demo();
    if (!strcmp(cmd, "stark-demo")) {
        uint32_t N  = (argc > 2) ? (uint32_t)strtoul(argv[2], NULL, 10) : 8;
        sf_t     c  = (argc > 3) ? (sf_t)strtoul(argv[3], NULL, 10) : 7;
        sf_t     x0 = (argc > 4) ? (sf_t)strtoul(argv[4], NULL, 10) : 3;
        return do_stark_demo(N, c, x0);
    }
    if (!strcmp(cmd, "prune-demo")) {
        uint32_t N = (argc > 2) ? (uint32_t)strtoul(argv[2], NULL, 10) : 8;
        return do_prune_demo(N);
    }
    usage(); return 1;
}
