#include "iii/stdlib.h"
#include <stdio.h>
#include <string.h>

static int g_pass = 0, g_fail = 0;
#define TEST(c) do { if (c) { g_pass++; printf("  PASS %s\n", #c); } \
    else { g_fail++; printf("  FAIL %s @ %s:%d\n", #c, __FILE__, __LINE__); } } while (0)
#define SECTION(s) printf("\n[%s]\n", s)

static void test_counts(void) {
    SECTION("counts");
    TEST(III_STDLIB_KEYWORD_COUNT == 47);
    TEST(III_STDLIB_MODIFIER_COUNT == 19);
    TEST(III_STDLIB_OPERATOR_COUNT == 23);
    TEST(III_STDLIB_PUNCTUATOR_COUNT == 25);
    TEST(III_STDLIB_LITERAL_FORM_COUNT == 9);
    TEST(III_STDLIB_SE_KIND_COUNT == 17);
    TEST(III_STDLIB_PHASE_COUNT == 4);
    TEST(III_STDLIB_SANCTUM_SLOT_COUNT == 10);
    TEST(III_STDLIB_TRINITY_LAYER_COUNT == 3);
    TEST(III_STDLIB_FEDERATION_TIER_COUNT == 4);
    TEST(III_STDLIB_CONFORMANCE_COUNT == 30);
    TEST(III_STDLIB_R1_FAMILY_COUNT == 15);
}

static void test_self_check(void) {
    SECTION("self check");
    TEST(iii_stdlib_self_check());
}

static void test_keyword_lookup(void) {
    SECTION("keyword lookup");
    TEST(iii_stdlib_keyword_lookup("cycle") != NULL);
    TEST(strcmp(iii_stdlib_keyword_lookup("cycle")->bind_section, "III-CYCLES.md §1, §2") == 0);
    TEST(iii_stdlib_keyword_lookup("nope") == NULL);
    TEST(iii_stdlib_keyword_at(0) != NULL);
    TEST(strcmp(iii_stdlib_keyword_at(0)->name, "witness") == 0);
}

static void test_modifier_lookup(void) {
    SECTION("modifier lookup");
    TEST(iii_stdlib_modifier_lookup("@ring") != NULL);
    TEST(iii_stdlib_modifier_lookup("@nope") == NULL);
}

static void test_operator(void) {
    SECTION("operator");
    const iii_operator_t *o = iii_stdlib_operator_at(0);
    TEST(o != NULL);
    TEST(strcmp(o->name, "Inverse") == 0);
    TEST(o->precedence == 11);

    /* Lookup unicode char */
    TEST(iii_stdlib_operator_lookup("\xE2\x9F\xB2") != NULL);  /* U+27F2 */
}

static void test_se_kinds(void) {
    SECTION("SE kinds");
    TEST(iii_stdlib_se_kind_at(0)->code == 0x01);
    TEST(strcmp(iii_stdlib_se_kind_at(0)->name, "MSR_WRITE") == 0);
    TEST(iii_stdlib_se_kind_at(16)->code == 0x11);
    TEST(strcmp(iii_stdlib_se_kind_at(16)->name, "NMI_INSTALL") == 0);
}

static void test_phases(void) {
    SECTION("phases");
    TEST(strcmp(iii_stdlib_phase_at(0)->name, "R-2") == 0);
    TEST(strcmp(iii_stdlib_phase_at(0)->long_name, "Sanctum") == 0);
    TEST(iii_stdlib_phase_at(0)->privilege == 0);
    TEST(iii_stdlib_phase_at(3)->privilege == 3);
}

static void test_sanctum(void) {
    SECTION("sanctum slots");
    TEST(strcmp(iii_stdlib_sanctum_slot_at(0)->name, "INVALID") == 0);
    TEST(strcmp(iii_stdlib_sanctum_slot_at(1)->name, "drtm_relaunch") == 0);
    TEST(strcmp(iii_stdlib_sanctum_slot_at(9)->name, "compile_module") == 0);
}

static void test_trinity(void) {
    SECTION("trinity");
    TEST(iii_stdlib_trinity_layer_at(0)->layer == 1);
    TEST(strcmp(iii_stdlib_trinity_layer_at(0)->name, "SCBA") == 0);
    TEST(iii_stdlib_trinity_layer_at(2)->overhead_cycles_max == 300);
}

static void test_federation(void) {
    SECTION("federation");
    TEST(strcmp(iii_stdlib_federation_tier_at(0)->name, "transient") == 0);
    TEST(strcmp(iii_stdlib_federation_tier_at(3)->name, "constitutional") == 0);
}

static void test_conformance(void) {
    SECTION("conformance");
    TEST(strcmp(iii_stdlib_conformance_at(0)->code, "C-1") == 0);
    TEST(strcmp(iii_stdlib_conformance_at(29)->code, "C-30") == 0);
}

static void test_r1(void) {
    SECTION("R1 family");
    TEST(strcmp(iii_stdlib_r1_at(0)->slot, "R1.A1") == 0);
    TEST(iii_stdlib_r1_at(0)->bytes == 70934);
    TEST(strcmp(iii_stdlib_r1_at(14)->slot, "R1.IDX") == 0);
}

static void test_render(void) {
    SECTION("render");
    char buf[1024];
    size_t n = iii_stdlib_render(buf, sizeof(buf));
    TEST(n > 0);
    TEST(strstr(buf, "\"keywords\":47") != NULL);
}

int main(void) {
    test_counts();
    test_self_check();
    test_keyword_lookup();
    test_modifier_lookup();
    test_operator();
    test_se_kinds();
    test_phases();
    test_sanctum();
    test_trinity();
    test_federation();
    test_conformance();
    test_r1();
    test_render();
    printf("\n=== %d passed, %d failed ===\n", g_pass, g_fail);
    return g_fail == 0 ? 0 : 1;
}
