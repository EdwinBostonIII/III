#include "iii/conformance.h"
#include <stdio.h>
#include <string.h>

static int g_pass = 0, g_fail = 0;
#define TEST(c) do { if (c) { g_pass++; printf("  PASS %s\n", #c); } \
    else { g_fail++; printf("  FAIL %s @ %s:%d\n", #c, __FILE__, __LINE__); } } while (0)
#define SECTION(s) printf("\n[%s]\n", s)

static void test_criteria(void) {
    SECTION("criteria");
    TEST(III_CONF_COUNT == 33);
    /* Spot-check */
    TEST(strcmp(iii_conf_criterion_at(0)->code, "C-1") == 0);
    TEST(iii_conf_criterion_at(0)->group == III_CG_CORE_LANGUAGE);
    TEST(iii_conf_criterion_at(15)->group == III_CG_SUBSTRATE);
    TEST(iii_conf_criterion_at(25)->group == III_CG_COGNITIVE);
    TEST(strcmp(iii_conf_criterion_at(29)->code, "C-30") == 0);
    /* Resolution group C-31..C-33 (FROZEN SPEC III-RES-FROZEN-001 §14) */
    TEST(strcmp(iii_conf_criterion_at(30)->code, "C-31") == 0);
    TEST(iii_conf_criterion_at(30)->group == III_CG_RESOLUTION);
    TEST(strcmp(iii_conf_criterion_at(32)->code, "C-33") == 0);
    TEST(iii_conf_criterion_at(32)->group == III_CG_RESOLUTION);
    TEST(strcmp(iii_conf_criterion_at(30)->title, "Resolution Determinism") == 0);

    TEST(iii_conf_criterion_lookup("C-7") != NULL);
    TEST(strcmp(iii_conf_criterion_lookup("C-7")->title, "Closure-Pinned Imports") == 0);
    TEST(iii_conf_criterion_lookup("C-99") == NULL);
    TEST(iii_conf_criterion_lookup("C-31") != NULL);
    TEST(iii_conf_criterion_lookup("C-33") != NULL);

    /* Group counts */
    unsigned core = 0, sub = 0, cog = 0, res = 0;
    for (unsigned i = 0; i < III_CONF_COUNT; ++i) {
        const iii_conf_criterion_t *c = iii_conf_criterion_at(i);
        if (c->group == III_CG_CORE_LANGUAGE) core++;
        if (c->group == III_CG_SUBSTRATE)     sub++;
        if (c->group == III_CG_COGNITIVE)     cog++;
        if (c->group == III_CG_RESOLUTION)    res++;
    }
    TEST(core == 15);
    TEST(sub == 10);
    TEST(cog == 5);
    TEST(res == 3);
}

static int test_pass_fn(void *user) {
    (void)user; return 0;
}

static int test_fail_fn(void *user) {
    (void)user; return -1;
}

static void test_verifier(void) {
    SECTION("verifier");
    iii_conf_verifier_t *v = iii_conf_verifier_create();
    TEST(v != NULL);

    /* Bind half the tests to pass, a few to fail. */
    for (unsigned i = 1; i <= 20; ++i) {
        char code[8]; snprintf(code, sizeof(code), "C-%u", i);
        TEST(iii_conf_bind_test(v, code, test_pass_fn, NULL));
    }
    for (unsigned i = 21; i <= 23; ++i) {
        char code[8]; snprintf(code, sizeof(code), "C-%u", i);
        TEST(iii_conf_bind_test(v, code, test_fail_fn, NULL));
    }
    /* Cannot rebind */
    TEST(!iii_conf_bind_test(v, "C-1", test_pass_fn, NULL));

    iii_conf_result_t r;
    iii_conf_run(v, &r);
    TEST(r.passed == 20);
    TEST(r.failed == 3);
    TEST(r.skipped == 10);   /* 33 total - 23 bound (C-1..C-23) = 10 unbound */
    /* Compliance = 20 / (20 + 3) = 0.870 ≈ 14248 q14 */
    TEST(r.compliance_q14 > 14000 && r.compliance_q14 < 14500);

    char buf[256];
    iii_conf_format_result(&r, buf, sizeof(buf));
    TEST(strstr(buf, "passed=20") != NULL);

    iii_conf_verifier_destroy(v);
}

static void test_pin(void) {
    SECTION("verifier pin");
    iii_conf_verifier_t *v = iii_conf_verifier_create();
    uint8_t pin[32]; memset(pin, 0xAA, 32);
    iii_conf_verifier_set_pin(v, pin);
    TEST(iii_conf_verifier_check_pin(v, pin));
    pin[0] ^= 1;
    TEST(!iii_conf_verifier_check_pin(v, pin));
    iii_conf_verifier_destroy(v);
}

int main(void) {
    test_criteria();
    test_verifier();
    test_pin();
    printf("\n=== %d passed, %d failed ===\n", g_pass, g_fail);
    return g_fail == 0 ? 0 : 1;
}
