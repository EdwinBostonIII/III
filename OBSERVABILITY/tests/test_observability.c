/* III-OBSERVABILITY tests */
#include "iii/observability.h"
#include <stdio.h>
#include <string.h>
#include <math.h>

static int g_pass = 0, g_fail = 0;
#define TEST(c) do { if (c) { g_pass++; printf("  PASS %s\n", #c); } \
    else { g_fail++; printf("  FAIL %s @ %s:%d\n", #c, __FILE__, __LINE__); } } while (0)
#define SECTION(s) printf("\n[%s]\n", s)

static void test_q14(void) {
    SECTION("Q14");
    TEST(III_Q14_ONE == 16384u);
    TEST(iii_q14_to_double(III_Q14_ONE) == 1.0);
    TEST(iii_q14_from_double(0.5) == III_Q14_ONE / 2u);
    iii_q14_t a = III_Q14_ONE;     /* 1.0 */
    iii_q14_t b = III_Q14_ONE / 2; /* 0.5 */
    TEST(iii_q14_mul(a, b) == b);  /* 1 * 0.5 = 0.5 */
    TEST(iii_q14_div(a, b) == III_Q14_ONE * 2u); /* 1 / 0.5 = 2 */
}

static void test_threshold_constructors(void) {
    SECTION("§2 threshold constructors");
    iii_threshold_t h = iii_th_hoeffding(0.95, 100);
    TEST(h.family == III_TF_HOEFFDING);
    TEST(h.confidence == 0.95);
    TEST(h.n_min == 100);

    iii_threshold_t m = iii_th_multinomial(0.95, 200, 4);
    TEST(m.family == III_TF_MULTINOMIAL);
    TEST(m.k_categories == 4);

    iii_threshold_t w = iii_th_wilson(0.99, 50);
    TEST(w.family == III_TF_WILSON);

    iii_threshold_t p = iii_th_poisson(0.95, 100);
    TEST(p.family == III_TF_POISSON);

    iii_threshold_t c = iii_th_coupon_collector(10, 0.95);
    TEST(c.family == III_TF_COUPON);
    TEST(c.coupon_k == 10);

    iii_threshold_t cm = iii_th_cmsketch(64, 4, 0.95);
    TEST(cm.family == III_TF_CMSKETCH);

    iii_threshold_t os = iii_th_order_stat(0.95, 0.95, 100);
    TEST(os.family == III_TF_ORDER_STAT);

    iii_threshold_t ny = iii_th_nyquist(48000.0, 20000.0);
    TEST(ny.family == III_TF_NYQUIST);

    iii_threshold_t ess = iii_th_effective_sample_size(500);
    TEST(ess.family == III_TF_EFFECTIVE_SAMPLE_SIZE);
    TEST(ess.ess_target == 500);

    iii_threshold_t hp = iii_th_heaps(40.0, 0.6, 100);
    TEST(hp.family == III_TF_HEAPS);

    iii_threshold_t r3 = iii_th_rule_of_three(0.95);
    TEST(r3.family == III_TF_RULE_OF_THREE);

    iii_threshold_t md = iii_th_multinomial_dirichlet(1.0, 0.95);
    TEST(md.family == III_TF_MULTINOMIAL_DIRICHLET);

    /* names */
    TEST(strcmp(iii_threshold_family_name(III_TF_HOEFFDING), "hoeffding") == 0);
    TEST(strcmp(iii_threshold_family_name(III_TF_MULTINOMIAL_DIRICHLET), "multinomial-dirichlet") == 0);
}

static void test_hoeffding(void) {
    SECTION("§2 Hoeffding");
    iii_threshold_t t = iii_th_hoeffding(0.95, 100);
    iii_accumulator_t a;
    iii_accumulator_init(&a, III_TF_HOEFFDING);
    /* With ε = 0.05, n must reach about 738 samples to satisfy the bound. */
    for (unsigned i = 0; i < 50; ++i) iii_accumulator_update_scalar(&a, 0.5);
    TEST(!iii_threshold_is_saturated(&t, &a));
    for (unsigned i = 0; i < 800; ++i) iii_accumulator_update_scalar(&a, 0.5);
    TEST(iii_threshold_is_saturated(&t, &a));
}

static void test_multinomial(void) {
    SECTION("§2 Multinomial");
    iii_threshold_t t = iii_th_multinomial(0.95, 100, 4);
    iii_accumulator_t a;
    iii_accumulator_init(&a, III_TF_MULTINOMIAL);
    for (unsigned i = 0; i < 80; ++i) iii_accumulator_update_category(&a, i % 4);
    TEST(!iii_threshold_is_saturated(&t, &a));
    for (unsigned i = 0; i < 100; ++i) iii_accumulator_update_category(&a, i % 4);
    TEST(iii_threshold_is_saturated(&t, &a));
}

static void test_wilson(void) {
    SECTION("§2 Wilson");
    iii_threshold_t t = iii_th_wilson(0.95, 50);
    t.epsilon = 0.10;
    iii_accumulator_t a;
    iii_accumulator_init(&a, III_TF_WILSON);
    for (unsigned i = 0; i < 1000; ++i) iii_accumulator_update_scalar(&a, (i % 2) ? 1.0 : 0.0);
    TEST(iii_threshold_is_saturated(&t, &a));
}

static void test_poisson(void) {
    SECTION("§2 Poisson");
    iii_threshold_t t = iii_th_poisson(0.95, 50);
    t.epsilon = 0.5;
    iii_accumulator_t a;
    iii_accumulator_init(&a, III_TF_POISSON);
    /* Mean λ = 100, so for n = 100 √n/λ = 0.1 ≤ 0.5 → saturated. */
    for (unsigned i = 0; i < 100; ++i) iii_accumulator_update_scalar(&a, 100.0);
    TEST(iii_threshold_is_saturated(&t, &a));
}

static void test_coupon(void) {
    SECTION("§2 Coupon");
    iii_threshold_t t = iii_th_coupon_collector(8, 0.95);
    iii_accumulator_t a;
    iii_accumulator_init(&a, III_TF_COUPON);
    /* bound = 8 * ln(8/0.05) ≈ 40.6 */
    for (unsigned i = 0; i < 50; ++i) iii_accumulator_update_event(&a);
    TEST(iii_threshold_is_saturated(&t, &a));
    for (unsigned j = 1; j < 50; ++j) {
        /* nothing — events already counted */
        (void)j;
    }
}

static void test_cmsketch(void) {
    SECTION("§2 CM-Sketch");
    iii_threshold_t t = iii_th_cmsketch(8, 4, 0.95);
    iii_accumulator_t a;
    iii_accumulator_init(&a, III_TF_CMSKETCH);
    /* Need n ≥ 8 * 4 = 32 */
    for (unsigned i = 0; i < 16; ++i) iii_accumulator_update_event(&a);
    TEST(!iii_threshold_is_saturated(&t, &a));
    for (unsigned i = 0; i < 32; ++i) iii_accumulator_update_event(&a);
    TEST(iii_threshold_is_saturated(&t, &a));
}

static void test_order_stat(void) {
    SECTION("§2 Order-stat");
    iii_threshold_t t = iii_th_order_stat(0.5, 0.95, 30);
    t.epsilon = 0.5;
    iii_accumulator_t a;
    iii_accumulator_init(&a, III_TF_ORDER_STAT);
    for (unsigned i = 0; i < 200; ++i) iii_accumulator_update_scalar(&a, (double)(i % 50));
    TEST(iii_threshold_is_saturated(&t, &a));
}

static void test_nyquist(void) {
    SECTION("§2 Nyquist");
    iii_threshold_t t = iii_th_nyquist(48000.0, 20000.0);
    iii_accumulator_t a;
    iii_accumulator_init(&a, III_TF_NYQUIST);
    TEST(iii_threshold_is_saturated(&t, &a));
    iii_threshold_t bad = iii_th_nyquist(20000.0, 20000.0);
    TEST(!iii_threshold_is_saturated(&bad, &a));
}

static void test_ess(void) {
    SECTION("§2 ESS");
    iii_threshold_t t = iii_th_effective_sample_size(50);
    iii_accumulator_t a;
    iii_accumulator_init(&a, III_TF_EFFECTIVE_SAMPLE_SIZE);
    for (unsigned i = 0; i < 100; ++i) iii_accumulator_update_weight(&a, 1.0);
    /* (Σw)² / Σ(w²) = 100²/100 = 100 ≥ 50 */
    TEST(iii_threshold_is_saturated(&t, &a));
}

static void test_heaps(void) {
    SECTION("§2 Heaps");
    iii_threshold_t t = iii_th_heaps(40.0, 0.6, 100);
    iii_accumulator_t a;
    iii_accumulator_init(&a, III_TF_HEAPS);
    /* For N = 1000, V_pred = 40 * 1000^0.6 ≈ 40 * 63.1 = 2520 */
    for (unsigned i = 0; i < 1000; ++i) iii_accumulator_update_event(&a);
    a.heaps_distinct = 2510;
    TEST(iii_threshold_is_saturated(&t, &a));
    a.heaps_distinct = 100;
    TEST(!iii_threshold_is_saturated(&t, &a));
}

static void test_rule_of_three(void) {
    SECTION("§2 Rule-of-three");
    iii_threshold_t t = iii_th_rule_of_three(0.95);
    iii_accumulator_t a;
    iii_accumulator_init(&a, III_TF_RULE_OF_THREE);
    /* bound = -ln(0.05)/3 ≈ 1.0 */
    for (unsigned i = 0; i < 5; ++i) iii_accumulator_update_event(&a);
    TEST(iii_threshold_is_saturated(&t, &a));
}

static void test_dirichlet(void) {
    SECTION("§2 Multinomial-Dirichlet");
    iii_threshold_t t = iii_th_multinomial_dirichlet(1.0, 0.95);
    t.k_categories = 4;
    iii_accumulator_t a;
    iii_accumulator_init(&a, III_TF_MULTINOMIAL_DIRICHLET);
    for (unsigned i = 0; i < 1000; ++i) iii_accumulator_update_category(&a, i % 4);
    TEST(iii_threshold_is_saturated(&t, &a));
}

static void test_composition(void) {
    SECTION("§2.4 composition");
    iii_threshold_t a = iii_th_hoeffding(0.95, 10);
    iii_threshold_t b = iii_th_rule_of_three(0.99);

    iii_threshold_composed_t *c = iii_th_compose(&a, &b, III_TC_AND);
    iii_accumulator_t aa, ab;
    iii_accumulator_init(&aa, III_TF_HOEFFDING);
    iii_accumulator_init(&ab, III_TF_RULE_OF_THREE);
    /* Drive both to saturation */
    for (unsigned i = 0; i < 5000; ++i) iii_accumulator_update_scalar(&aa, 0.5);
    for (unsigned i = 0; i < 5; ++i) iii_accumulator_update_event(&ab);
    TEST(iii_th_composed_is_saturated(c, &aa, &ab));
    iii_th_composed_destroy(c);

    iii_threshold_composed_t *c2 = iii_th_compose(&a, &b, III_TC_OR);
    iii_accumulator_t aa2, ab2;
    iii_accumulator_init(&aa2, III_TF_HOEFFDING);
    iii_accumulator_init(&ab2, III_TF_RULE_OF_THREE);
    /* Only b saturated */
    for (unsigned i = 0; i < 5; ++i) iii_accumulator_update_event(&ab2);
    TEST(iii_th_composed_is_saturated(c2, &aa2, &ab2));
    iii_th_composed_destroy(c2);
}

static void test_runtime(void) {
    SECTION("§1 OBSERVATORY collapse");
    iii_observability_t *o = iii_observability_create();
    TEST(o != NULL);

    iii_threshold_t t = iii_th_hoeffding(0.95, 10);
    t.epsilon = 0.30;
    uint32_t id = iii_observability_register_track(o, 0xABCD, t);
    TEST(id != 0);

    /* Drive observation; saturation should fire eventually */
    bool fired = false;
    for (unsigned i = 0; i < 200 && !fired; ++i) {
        fired = iii_observability_observe(o, id, 0.5);
    }
    TEST(fired);

    /* Pop the saturation event */
    iii_saturation_event_t e;
    TEST(iii_observability_pop_saturation(o, &e));
    TEST(e.cycle_kind == 0xABCD);
    TEST(e.family == III_TF_HOEFFDING);
    TEST(iii_observability_pending_saturations(o) == 0);

    iii_observability_destroy(o);
}

static void test_state(void) {
    SECTION("§4 State surface");
    iii_observability_t *o = iii_observability_create();
    iii_state_surface_t s;
    memset(&s, 0, sizeof(s));
    s.current_epoch = 42;
    s.federation_peer_count = 7;
    s.mobius_coherence_q14 = III_Q14_ONE;
    s.proof_kernel_invariants_held = true;
    s.jit_compilation_success_rate_q14 = III_Q14_ONE;
    iii_observability_set_state(o, &s);

    const iii_state_surface_t *cur = iii_observability_state(o);
    TEST(cur->current_epoch == 42);
    TEST(cur->federation_peer_count == 7);

    /* Health: with ideal state expect a high score. */
    iii_q14_t score = iii_observability_health_score(o);
    TEST(score > III_Q14_ONE / 2u);

    iii_observability_destroy(o);
}

static void test_query(void) {
    SECTION("§7 query");
    iii_observability_t *o = iii_observability_create();
    iii_state_surface_t s;
    memset(&s, 0, sizeof(s));
    s.audit_chain_height = 1000;
    iii_observability_set_state(o, &s);

    iii_query_t q = {0};
    q.kind = III_QUERY_CYCLES_IN_EPOCH;
    q.epoch_start = 1;
    q.epoch_end = 100;
    iii_query_result_t r;
    TEST(iii_observability_query(o, &q, &r) == III_QUERY_OK);
    TEST(r.scanned_witnesses == 1000);
    TEST(iii_observability_query_count(o) == 1);

    /* Too-large query without consent */
    s.audit_chain_height = XII_OBSERVABILITY_QUERY_MAX_WITNESSES + 1ull;
    iii_observability_set_state(o, &s);
    q.operator_consent_for_large_query = false;
    TEST(iii_observability_query(o, &q, &r) == III_QUERY_E_TOO_LARGE);
    /* With consent — ok */
    q.operator_consent_for_large_query = true;
    TEST(iii_observability_query(o, &q, &r) == III_QUERY_OK);

    iii_observability_destroy(o);
}

static void test_wlishi(void) {
    SECTION("§5 WLISHI parser");
    iii_wlishi_cmd_t c;
    TEST(iii_wlishi_parse("system.state.current_epoch", &c));
    TEST(c.kind == III_WLISHI_STATE_QUERY);
    TEST(strcmp(c.arg, "current_epoch") == 0);

    TEST(iii_wlishi_parse("system.health", &c));
    TEST(c.kind == III_WLISHI_HEALTH);

    TEST(iii_wlishi_parse("system.causal.explain abc123", &c));
    TEST(c.kind == III_WLISHI_CAUSAL_EXPLAIN);
    TEST(strcmp(c.arg, "abc123") == 0);

    TEST(!iii_wlishi_parse("nope.bad", &c));
}

int main(void) {
    test_q14();
    test_threshold_constructors();
    test_hoeffding();
    test_multinomial();
    test_wilson();
    test_poisson();
    test_coupon();
    test_cmsketch();
    test_order_stat();
    test_nyquist();
    test_ess();
    test_heaps();
    test_rule_of_three();
    test_dirichlet();
    test_composition();
    test_runtime();
    test_state();
    test_query();
    test_wlishi();
    printf("\n=== %d passed, %d failed ===\n", g_pass, g_fail);
    return g_fail == 0 ? 0 : 1;
}
