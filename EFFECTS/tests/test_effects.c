/* III-EFFECTS standalone tests — exercises the API surface that doesn't
 * require AST / parser integration. */
#include "iii/effects.h"
#include <stdio.h>
#include <string.h>

static int g_pass = 0, g_fail = 0;
#define TEST(c) do { if (c) { g_pass++; printf("  PASS %s\n", #c); } \
    else { g_fail++; printf("  FAIL %s @ %s:%d\n", #c, __FILE__, __LINE__); } } while (0)
#define SECTION(s) printf("\n[%s]\n", s)

static void test_se_kinds(void) {
    SECTION("§1.1 SE kinds (17)");
    TEST(III_SE_BUILTIN_COUNT == 17u);
    /* Names use III_SE_<KIND> form per the source table */
    TEST(strcmp(iii_se_kind_name(III_SE_MSR_WRITE), "III_SE_MSR_WRITE") == 0);
    TEST(strcmp(iii_se_kind_name(III_SE_NMI_INSTALL), "III_SE_NMI_INSTALL") == 0);
    /* The NONE name */
    {
        const char *n = iii_se_kind_name(III_SE_NONE);
        TEST(n != NULL && n[0] != '\0');
    }

    /* Method round-trip */
    iii_se_kind_t k = iii_se_kind_from_method("msr_write", 9);
    TEST(k == III_SE_MSR_WRITE);
    TEST(iii_se_kind_from_method("nope", 4) == III_SE_NONE);
    TEST(strcmp(iii_se_kind_method(III_SE_MSR_WRITE), "msr_write") == 0);

    /* All 17 kinds must have non-empty names */
    for (int i = 1; i <= 17; ++i) {
        const char *n = iii_se_kind_name((iii_se_kind_t)i);
        if (!(n && n[0])) { g_fail++; printf("  FAIL kind %d empty name\n", i); }
        else g_pass++;
    }
}

static void test_compromise(void) {
    SECTION("§1.2 compromise tiers");
    TEST(strcmp(iii_compromise_name(III_COMP_NONE),   "NONE")   == 0);
    TEST(strcmp(iii_compromise_name(III_COMP_LOW),    "LOW")    == 0);
    TEST(strcmp(iii_compromise_name(III_COMP_MEDIUM), "MEDIUM") == 0);
    TEST(strcmp(iii_compromise_name(III_COMP_HIGH),   "HIGH")   == 0);

    TEST(iii_effect_compromise_join(III_COMP_LOW, III_COMP_MEDIUM) == III_COMP_MEDIUM);
    TEST(iii_effect_compromise_join(III_COMP_NONE, III_COMP_HIGH) == III_COMP_HIGH);

    /* C-EFF-7: HIGH not inhabited */
    TEST(iii_compromise_inhabited(III_COMP_NONE));
    TEST(iii_compromise_inhabited(III_COMP_LOW));
    TEST(iii_compromise_inhabited(III_COMP_MEDIUM));
    TEST(!iii_compromise_inhabited(III_COMP_HIGH));
}

static void test_pip_classes(void) {
    SECTION("§3 PIP classes");
    TEST(strcmp(iii_pip_class_name(III_PIP_STATIC_BYTES), "STATIC_BYTES") == 0);
    TEST(strcmp(iii_pip_class_name(III_PIP_DYNAMIC_FN),   "DYNAMIC_FN")   == 0);
    TEST(strcmp(iii_pip_class_name(III_PIP_COMPOSED),     "COMPOSED")     == 0);

    /* Classify each SE kind into a PIP class */
    TEST(iii_pip_classify(III_SE_MSR_WRITE) != III_PIP_NONE);
    TEST(iii_pip_classify(III_SE_PKRU_WRITE) != III_PIP_NONE);
}

static void test_pip_blobs(void) {
    SECTION("§3 PIP blobs");
    uint8_t prior[16]; for (unsigned i = 0; i < 16; ++i) prior[i] = (uint8_t)i;
    iii_pip_blob_t *s = iii_pip_blob_new_static(prior, 16);
    TEST(s != NULL);
    TEST(iii_pip_blob_class(s) == III_PIP_STATIC_BYTES);
    TEST(iii_pip_blob_size(s) == 16);
    TEST(memcmp(iii_pip_blob_bytes(s), prior, 16) == 0);
    iii_pip_blob_destroy(s);

    iii_pip_blob_t *d = iii_pip_blob_new_dynfn(III_SE_MSR_WRITE);
    TEST(iii_pip_blob_class(d) == III_PIP_DYNAMIC_FN);
    TEST(iii_pip_blob_dynfn_kind(d) == III_SE_MSR_WRITE);
    iii_pip_blob_destroy(d);

    iii_pip_blob_t *c = iii_pip_blob_new_composed();
    TEST(iii_pip_blob_class(c) == III_PIP_COMPOSED);
    iii_pip_blob_t *inner = iii_pip_blob_new_dynfn(III_SE_CR_WRITE);
    TEST(iii_pip_blob_compose_push(c, inner) == 0);
    TEST(iii_pip_blob_size(c) == 1);
    iii_pip_blob_destroy(c);
}

static void test_epistemic(void) {
    SECTION("§5 epistemic");
    iii_uncertainty_t certain = { .domain_id = 0, .confidence_q14 = III_CONFIDENCE_Q_DENOM, .question_count = 0 };
    iii_uncertainty_t doubted = { .domain_id = 0, .confidence_q14 = 8000, .question_count = 0 };
    iii_uncertainty_t open    = { .domain_id = 0, .confidence_q14 = III_CONFIDENCE_Q_DENOM, .question_count = 1 };

    TEST(!iii_epistemic_escalates(certain));
    TEST(iii_epistemic_escalates(doubted));
    TEST(iii_epistemic_escalates(open));

    iii_uncertainty_t merged = iii_epistemic_compose(certain, doubted);
    TEST(merged.confidence_q14 == 8000);
}

static void test_reserved_band(void) {
    SECTION("§6 reserved band");
    TEST(III_SE_RESERVED_BASE == 0x01C7u);
    TEST(III_SE_RESERVED_SLOTS == 9u);
    TEST(III_SE_RESERVED_8 - III_SE_RESERVED_BASE == 8u);
}

int main(void) {
    test_se_kinds();
    test_compromise();
    test_pip_classes();
    test_pip_blobs();
    test_epistemic();
    test_reserved_band();
    printf("\n=== %d passed, %d failed ===\n", g_pass, g_fail);
    return g_fail == 0 ? 0 : 1;
}
