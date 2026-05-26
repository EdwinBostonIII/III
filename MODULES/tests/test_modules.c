#include "iii/modules.h"
#include <stdio.h>
#include <string.h>

static int g_pass = 0, g_fail = 0;
#define TEST(c) do { if (c) { g_pass++; printf("  PASS %s\n", #c); } \
    else { g_fail++; printf("  FAIL %s @ %s:%d\n", #c, __FILE__, __LINE__); } } while (0)
#define SECTION(s) printf("\n[%s]\n", s)

static void test_register(void) {
    SECTION("§1 register");
    iii_module_runtime_t *rt = iii_module_runtime_create();
    const uint8_t source[] = "module hv.msr_cmd { ... }";
    iii_mod_id_t a = iii_module_register(rt, "hv.msr_cmd", "1.0", source, sizeof(source) - 1, 0x06);
    TEST(a != 0);
    const iii_module_t *m = iii_module_lookup(rt, a);
    TEST(m != NULL);
    TEST(strcmp(m->qualified_name, "hv.msr_cmd") == 0);
    /* Closure root must be non-zero. */
    bool any = false;
    for (unsigned i = 0; i < 32; ++i) if (m->closure_root[i]) { any = true; break; }
    TEST(any);

    /* Different source → different closure root. */
    const uint8_t source2[] = "module hv.msr_cmd { other }";
    iii_mod_id_t b = iii_module_register(rt, "hv.msr_cmd", "1.0", source2, sizeof(source2) - 1, 0x06);
    const iii_module_t *m2 = iii_module_lookup(rt, b);
    TEST(memcmp(m->closure_root, m2->closure_root, 32) != 0);

    iii_module_runtime_destroy(rt);
}

static void test_resolve(void) {
    SECTION("§2 resolution");
    iii_module_runtime_t *rt = iii_module_runtime_create();
    const uint8_t src[] = "x";
    iii_mod_id_t mid = iii_module_register(rt, "crypto.sha256", "1.0", src, 1, 0x0F);
    iii_module_set_metrics(rt, mid, 14000, 16000);
    const iii_module_t *m = iii_module_lookup(rt, mid);

    iii_mod_id_t out = 0;
    TEST(iii_module_resolve(rt, "crypto.sha256", NULL, &out) == III_RES_OK);
    TEST(out == mid);

    /* Closure-pin match */
    TEST(iii_module_resolve(rt, "crypto.sha256", m->closure_root, &out) == III_RES_OK);

    /* Closure-pin mismatch */
    uint8_t bad[32]; memset(bad, 0xFF, 32);
    TEST(iii_module_resolve(rt, "crypto.sha256", bad, &out) == III_RES_CLOSURE_MISMATCH);

    /* Not found */
    TEST(iii_module_resolve(rt, "nope.nope", NULL, &out) == III_RES_NOT_FOUND);

    iii_module_runtime_destroy(rt);
}

static void test_import_export(void) {
    SECTION("§1 import/export/manifest");
    iii_module_runtime_t *rt = iii_module_runtime_create();
    const uint8_t src[] = "x";
    iii_mod_id_t a = iii_module_register(rt, "a", "1.0", src, 1, 0x06);
    iii_mod_id_t b = iii_module_register(rt, "b", "1.0", src, 1, 0x06);
    const iii_module_t *am = iii_module_lookup(rt, a);

    TEST(iii_module_add_import(rt, b, "a", am->closure_root));
    uint8_t hash[32]; memset(hash, 0xCD, 32);
    TEST(iii_module_add_export(rt, a, "fn1", hash));

    iii_module_manifest_t mf;
    iii_module_manifest_compute(am, &mf);
    bool any = false;
    for (unsigned i = 0; i < 32; ++i) if (mf.exports_mhash[i]) { any = true; break; }
    TEST(any);

    iii_module_runtime_destroy(rt);
}

static void test_ring_gating(void) {
    SECTION("§5 Ring-gated promotion");
    /* high benefit + low risk → R-2 */
    TEST(iii_modules_select_validation_ring(III_LVL_LOW,    III_LVL_HIGH)   == III_VR_SANCTUM);
    /* medium benefit + medium risk → R-1 */
    TEST(iii_modules_select_validation_ring(III_LVL_MEDIUM, III_LVL_MEDIUM) == III_VR_HYPERVISOR);
    /* low risk + low benefit → R0 */
    TEST(iii_modules_select_validation_ring(III_LVL_LOW,    III_LVL_LOW)    == III_VR_KERNEL);
    /* high risk + low benefit → reject */
    TEST(iii_modules_select_validation_ring(III_LVL_HIGH,   III_LVL_LOW)    == III_VR_REJECT);

    /* names */
    TEST(strcmp(iii_validation_ring_name(III_VR_SANCTUM), "Ring -2") == 0);
}

static void test_propose(void) {
    SECTION("§6 propose+deploy");
    iii_module_runtime_t *rt = iii_module_runtime_create();
    const uint8_t src[] = "x";
    iii_mod_id_t a = iii_module_register(rt, "a", "1.0", src, 1, 0x06);
    iii_mod_id_t b = iii_module_register(rt, "b", "1.0", src, 1, 0x06);

    iii_module_change_t ch = {0};
    ch.kind = III_CHANGE_FUSE;
    ch.primary = a;
    ch.secondary = b;
    ch.risk = III_LVL_LOW;
    ch.benefit = III_LVL_HIGH;
    ch.codegen_passed = true;
    ch.structural_invariants_held = true;
    ch.semantic_baseline_match = true;

    iii_deploy_outcome_t out;
    iii_module_propose_and_deploy(rt, &ch, &out);
    TEST(out.flag == III_DEPLOY_SAFE_APPROVED);
    TEST(out.ring == III_VR_SANCTUM);
    TEST(out.deployed);
    TEST(out.new_module_id != 0 && out.new_module_id != a && out.new_module_id != b);

    /* Codegen failed */
    ch.codegen_passed = false;
    iii_module_propose_and_deploy(rt, &ch, &out);
    TEST(out.flag == III_DEPLOY_UNSAFE_REJECTED);

    /* Semantic mismatch but structurally safe → SAFE_FLAGGED */
    ch.codegen_passed = true;
    ch.semantic_baseline_match = false;
    iii_module_propose_and_deploy(rt, &ch, &out);
    TEST(out.flag == III_DEPLOY_SAFE_FLAGGED);

    /* Reject for high risk + low benefit */
    ch.semantic_baseline_match = true;
    ch.risk = III_LVL_HIGH;
    ch.benefit = III_LVL_LOW;
    iii_module_propose_and_deploy(rt, &ch, &out);
    TEST(out.flag == III_DEPLOY_UNSAFE_REJECTED);

    iii_module_runtime_destroy(rt);
}

static void test_complementarity(void) {
    SECTION("§4 complementarity");
    iii_module_runtime_t *rt = iii_module_runtime_create();
    const uint8_t src[] = "x";
    iii_mod_id_t a = iii_module_register(rt, "a", "1.0", src, 1, 0x06);
    iii_mod_id_t b = iii_module_register(rt, "b", "1.0", src, 1, 0x06);
    iii_module_set_metrics(rt, a, 14000, 16000);
    iii_module_set_metrics(rt, b, 13500, 15800);

    /* Real Z_3^6 aggregate hexads.  ZERO=1 POS=2 NEG=0.
     * Admissible composition: pillars 0..3 must remain in {ZERO,POS}. */
    iii_hexad_z3_6_t h_a = { .component = {1, 1, 2, 1, 2, 1} };
    iii_hexad_z3_6_t h_b = { .component = {1, 2, 1, 2, 1, 2} };
    iii_module_set_hexad(rt, a, &h_a);
    iii_module_set_hexad(rt, b, &h_b);

    iii_complementarity_result_t r;
    iii_module_complementarity(rt, a, b, &r);
    /* Composed: (1+1)%3=2, (1+2)%3=0  ← NEG in pillar 1 → NOT admissible. */
    TEST(!r.complementary);

    /* Use hexads whose composition stays in {ZERO,POS} for pillars 0..3. */
    iii_hexad_z3_6_t h_c = { .component = {1, 1, 1, 1, 2, 1} };
    iii_hexad_z3_6_t h_d = { .component = {1, 1, 1, 1, 0, 0} };
    iii_module_set_hexad(rt, a, &h_c);
    iii_module_set_hexad(rt, b, &h_d);
    iii_module_complementarity(rt, a, b, &r);
    /* Composed: (1+1)%3=2, ..., (2+0)%3=2 (pillar 4 POS), (1+0)%3=1.
     * Pillars 0..3 = (2,2,2,2) — admissible.  Has POS in pillar 4. */
    TEST(r.complementary);
    TEST(r.coherence_path_q14 == 13500);

    /* Lower coherence below floor → not complementary */
    iii_module_set_metrics(rt, a, 5000, 16000);
    iii_module_complementarity(rt, a, b, &r);
    TEST(!r.complementary);

    /* Bricking-class composed hexad: choose sources whose Z_3 sum lands on
     * NEG (=0) in a structural pillar.  ZERO (=1) + POS (=2) = 0 mod 3. */
    iii_module_set_metrics(rt, a, 14000, 16000);
    iii_hexad_z3_6_t h_z = { .component = {1, 1, 1, 1, 1, 1} }; /* all ZERO */
    iii_hexad_z3_6_t h_p = { .component = {2, 1, 1, 1, 1, 1} }; /* POS in pillar 0 */
    iii_module_set_hexad(rt, a, &h_z);
    iii_module_set_hexad(rt, b, &h_p);
    iii_module_complementarity(rt, a, b, &r);
    /* Composed pillar 0 = (1+2)%3 = 0 (NEG in structural pillar) → unreachable. */
    TEST(!r.complementary);
    TEST(r.hexad_admissible == 0u);

    iii_module_runtime_destroy(rt);
}

static void test_tx(void) {
    SECTION("§3 transmission");
    iii_module_runtime_t *rt = iii_module_runtime_create();
    const uint8_t src[] = "x";
    iii_mod_id_t a = iii_module_register(rt, "a", "1.0", src, 1, 0x06);
    iii_mod_id_t b = iii_module_register(rt, "b", "1.0", src, 1, 0x06);
    iii_module_set_metrics(rt, a, 16383, 16383);
    iii_module_set_metrics(rt, b, 16383, 16383);

    iii_tx_record_t tx;
    TEST(iii_module_transmit(rt, a, b, &tx));
    TEST(tx.path == III_TX_PATH_FUSED);
    TEST(tx.cycle_overhead == 5);

    /* Lower coherence → specialized */
    iii_module_set_metrics(rt, a, 13000, 13000);
    TEST(iii_module_transmit(rt, a, b, &tx));
    TEST(tx.path == III_TX_PATH_SPECIALIZED);

    /* Lower further → generic */
    iii_module_set_metrics(rt, a, 4000, 4000);
    iii_module_set_metrics(rt, b, 4000, 4000);
    TEST(iii_module_transmit(rt, a, b, &tx));
    TEST(tx.path == III_TX_PATH_GENERIC);

    iii_module_runtime_destroy(rt);
}

int main(void) {
    test_register();
    test_resolve();
    test_import_export();
    test_ring_gating();
    test_propose();
    test_complementarity();
    test_tx();
    printf("\n=== %d passed, %d failed ===\n", g_pass, g_fail);
    return g_fail == 0 ? 0 : 1;
}
