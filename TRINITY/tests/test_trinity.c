#include "iii/trinity.h"
#include <stdio.h>
#include <string.h>

static int g_pass = 0, g_fail = 0;
#define TEST(c) do { if (c) { g_pass++; printf("  PASS %s\n", #c); } \
    else { g_fail++; printf("  FAIL %s @ %s:%d\n", #c, __FILE__, __LINE__); } } while (0)
#define SECTION(s) printf("\n[%s]\n", s)

static void make_input(iii_trinity_input_t *in) {
    iii_trinity_input_init_defaults(in);
    in->intent_valid = true;
    in->cap_valid = true;
    in->causality_valid = true;
    in->sanctum_state_valid = true;
    in->intent_id = 0x1u;
    in->cap_id = 0x2u;
    in->causality_id = 0x3u;
    in->sanctum_frame_id = 0x4u;
    in->scba_bit = 42;
    in->composed_delta.pillars[0] = 1;
    in->composed_delta.pillars[1] = 1;
    in->composed_delta.pillars[2] = 2;
    in->composed_delta.pillars[3] = 1;
    in->composed_delta.pillars[4] = 2;
    in->composed_delta.pillars[5] = 1;
    in->projected_coherence_q14 = 16000;  /* ≥ floor */
    in->coherence_floor_q14 = III_TRINITY_DEFAULT_FLOOR_Q14;
}

static void test_layer_names(void) {
    SECTION("§1 layer names");
    TEST(strcmp(iii_trinity_layer_name(III_LAYER_SCBA), "Layer 1: SCBA") == 0);
    TEST(strcmp(iii_trinity_layer_name(III_LAYER_TRINITY), "Layer 3: Trinity") == 0);
    TEST(strcmp(iii_trinity_status_name(III_TRIN_INTENT_REJECT), "TRINITY_INTENT_REJECT") == 0);
}

static void test_scba(void) {
    SECTION("Layer 1 SCBA");
    iii_scba_bitarray_t s;
    iii_scba_init(&s);
    TEST(!iii_scba_bit_test(&s, 100));
    iii_scba_bit_set(&s, 100);
    TEST(iii_scba_bit_test(&s, 100));
    iii_scba_bit_set(&s, 65535);
    TEST(iii_scba_bit_test(&s, 65535));
}

static void test_acc(void) {
    SECTION("Layer 2 ACC");
    iii_acc_delta_t d = { .pillars = {1, 1, 2, 1, 2, 1} };
    TEST(iii_acc_wall_y_admit(&d));
    iii_acc_delta_t bad = { .pillars = {0, 1, 2, 1, 2, 1} };
    TEST(!iii_acc_wall_y_admit(&bad));
}

static void test_admit_layer1(void) {
    SECTION("Layer-1 fast path");
    iii_trinity_runtime_t *rt = iii_trinity_runtime_create();
    iii_trinity_runtime_set_risk(rt, 1000);  /* low risk → only Layer 1 needed */
    iii_trinity_runtime_scba_set(rt, 42);

    iii_trinity_input_t in;
    make_input(&in);

    iii_convergence_point_t cp;
    iii_trinity_status_t st = iii_trinity_admit(rt, &in, &cp);
    TEST(st == III_TRIN_OK);
    TEST(cp.admitting_layer == III_LAYER_SCBA);

    iii_trinity_runtime_destroy(rt);
}

static void test_admit_layer3(void) {
    SECTION("Layer-3 full path");
    iii_trinity_runtime_t *rt = iii_trinity_runtime_create();
    iii_trinity_runtime_set_risk(rt, 14000);  /* high risk → full Layer 3 */

    iii_trinity_input_t in;
    make_input(&in);

    iii_convergence_point_t cp;
    iii_trinity_status_t st = iii_trinity_admit(rt, &in, &cp);
    TEST(st == III_TRIN_OK);
    TEST(cp.admitting_layer == III_LAYER_TRINITY);
    TEST(cp.intent_passed && cp.cap_passed && cp.causality_passed && cp.sanctum_passed);

    /* Negative — bad intent */
    in.intent_valid = false;
    st = iii_trinity_admit(rt, &in, &cp);
    TEST(st == III_TRIN_INTENT_REJECT);
    in.intent_valid = true;

    /* Negative — bad coherence */
    in.projected_coherence_q14 = 1000;
    st = iii_trinity_admit(rt, &in, &cp);
    TEST(st == III_TRIN_MOBIUS_COHERENCE_FAIL);

    /* Negative — bad ACC delta */
    in.projected_coherence_q14 = 16000;
    in.composed_delta.pillars[0] = 0;
    st = iii_trinity_admit(rt, &in, &cp);
    TEST(st == III_TRIN_ACC_WALL_Y_REJECT);

    iii_trinity_runtime_destroy(rt);
}

static void test_predictive(void) {
    SECTION("§3 predictive cache");
    iii_trinity_runtime_t *rt = iii_trinity_runtime_create();
    iii_trinity_runtime_set_risk(rt, 14000);

    iii_trinity_input_t in;
    make_input(&in);

    iii_convergence_point_t cp;
    /* First call — populates cache */
    iii_trinity_status_t st = iii_trinity_predictive_admit(rt, &in, &cp);
    TEST(st == III_TRIN_OK);

    /* Lookup confirms cache hit */
    uint64_t before = iii_trinity_runtime_witness_count(rt);
    st = iii_trinity_predictive_admit(rt, &in, &cp);
    TEST(st == III_TRIN_OK);
    TEST(iii_trinity_runtime_witness_count(rt) > before);

    iii_trinity_runtime_destroy(rt);
}

static void test_epistemic(void) {
    SECTION("§4 epistemic escalation");
    iii_trinity_runtime_t *rt = iii_trinity_runtime_create();
    iii_trinity_runtime_set_risk(rt, 14000);

    iii_trinity_input_t in;
    make_input(&in);
    in.uncertainty_present = true;
    in.confidence_q14 = 8000;  /* below threshold 13927 */

    iii_convergence_point_t cp;
    iii_trinity_status_t st = iii_trinity_admit(rt, &in, &cp);
    TEST(st == III_TRIN_EPISTEMIC_LOW_CONFIDENCE);

    /* Operator-confirmed via the named operator-confirmation sentinel */
    in.intent_id = III_TRINITY_OPERATOR_CONFIRMATION_INTENT_ID;
    st = iii_trinity_admit(rt, &in, &cp);
    TEST(st == III_TRIN_OK);

    iii_trinity_runtime_destroy(rt);
}

static bool always_admit(uint64_t id, void *user) { (void)id; (void)user; return true; }
static bool never_admit(uint64_t id, void *user)  { (void)id; (void)user; return false; }

static void test_promote(void) {
    SECTION("§6 catalyst promotion");
    iii_trinity_runtime_t *rt = iii_trinity_runtime_create();
    iii_trinity_runtime_set_risk(rt, 14000);

    iii_trinity_input_t in;
    make_input(&in);
    in.intent_valid = false;  /* default would reject */

    iii_convergence_point_t cp;
    /* Without promotion → INTENT_REJECT */
    TEST(iii_trinity_admit(rt, &in, &cp) == III_TRIN_INTENT_REJECT);

    /* Promote a more permissive intent admitter */
    iii_trinity_runtime_promote_intent_admit(rt, always_admit, NULL);
    TEST(iii_trinity_admit(rt, &in, &cp) == III_TRIN_OK);

    /* Promote a stricter cap admitter */
    iii_trinity_runtime_promote_cap_admit(rt, never_admit, NULL);
    TEST(iii_trinity_admit(rt, &in, &cp) == III_TRIN_CAP_REJECT);

    iii_trinity_runtime_destroy(rt);
}

static void test_ghost(void) {
    SECTION("§7 ghost mode");
    iii_trinity_runtime_t *rt = iii_trinity_runtime_create();
    iii_trinity_runtime_set_risk(rt, 14000);

    iii_trinity_input_t in;
    make_input(&in);
    in.ghost = true;

    iii_convergence_point_t cp;
    TEST(iii_trinity_ghost_admit(rt, &in, &cp) == III_TRIN_OK);

    iii_trinity_runtime_destroy(rt);
}

static void test_dynamic_layer(void) {
    SECTION("§8 dynamic layer activation");
    iii_trinity_runtime_t *rt = iii_trinity_runtime_create();

    iii_trinity_runtime_set_risk(rt, 100);
    TEST(iii_trinity_runtime_min_layer(rt) == III_LAYER_SCBA);

    iii_trinity_runtime_set_risk(rt, 8000);
    TEST(iii_trinity_runtime_min_layer(rt) == III_LAYER_ACC);

    iii_trinity_runtime_set_risk(rt, 14000);
    TEST(iii_trinity_runtime_min_layer(rt) == III_LAYER_TRINITY);

    iii_trinity_runtime_destroy(rt);
}

int main(void) {
    test_layer_names();
    test_scba();
    test_acc();
    test_admit_layer1();
    test_admit_layer3();
    test_predictive();
    test_epistemic();
    test_promote();
    test_ghost();
    test_dynamic_layer();
    printf("\n=== %d passed, %d failed ===\n", g_pass, g_fail);
    return g_fail == 0 ? 0 : 1;
}
