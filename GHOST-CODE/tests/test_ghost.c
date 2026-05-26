#include "iii/ghost_code.h"
#include <stdio.h>
#include <string.h>

static int g_pass = 0, g_fail = 0;
#define TEST(c) do { if (c) { g_pass++; printf("  PASS %s\n", #c); } \
    else { g_fail++; printf("  FAIL %s @ %s:%d\n", #c, __FILE__, __LINE__); } } while (0)
#define SECTION(s) printf("\n[%s]\n", s)

static void test_gates(void) {
    SECTION("§2 gates");
    TEST(III_GATE_COUNT == 13u);
    TEST(strcmp(iii_gate_name(III_GATE_TYPE_CORRECTNESS), "type-correctness") == 0);
    TEST(strcmp(iii_gate_name(III_GATE_CONSTANT_TIME),    "constant-time")    == 0);

    iii_gate_set_t s;
    iii_gate_set_init(&s);
    /* Mark all 12 applicable */
    for (unsigned g = 1; g < III_GATE_COUNT; ++g) iii_gate_set_mark_applicable(&s, (iii_gate_t)g, true);
    TEST(!iii_gate_set_complete(&s));

    /* Pass them all */
    uint8_t cert[32]; memset(cert, 0xAB, 32);
    for (unsigned g = 1; g < III_GATE_COUNT; ++g) iii_gate_set_record_pass(&s, (iii_gate_t)g, cert);
    TEST(iii_gate_set_complete(&s));

    /* Compose */
    uint8_t proof[32];
    iii_gate_set_compose(&s, proof);
    bool any = false;
    for (unsigned i = 0; i < 32; ++i) if (proof[i]) { any = true; break; }
    TEST(any);
}

static void test_classify(void) {
    SECTION("§4 compromise classification");
    iii_gate_set_t s;
    iii_gate_set_init(&s);
    /* All 12 applicable, all pass → VERIFIED */
    for (unsigned g = 1; g < III_GATE_COUNT; ++g) {
        iii_gate_set_mark_applicable(&s, (iii_gate_t)g, true);
        iii_gate_set_record_pass(&s, (iii_gate_t)g, NULL);
    }
    TEST(iii_ghost_classify_compromise(&s) == III_VS_VERIFIED);

    /* Anchor invariant fails → GHOST */
    iii_gate_set_record_fail(&s, III_GATE_ANCHOR_INVARIANT);
    TEST(iii_ghost_classify_compromise(&s) == III_VS_GHOST);

    /* Re-pass anchor; only reversibility fails → COMPROMISE_LOW */
    iii_gate_set_record_pass(&s, III_GATE_ANCHOR_INVARIANT, NULL);
    iii_gate_set_record_fail(&s, III_GATE_REVERSIBILITY);
    TEST(iii_ghost_classify_compromise(&s) == III_VS_COMPROMISE_LOW);

    /* Two critical fail → COMPROMISE_MEDIUM (effect-soundness + cap-discipline are critical) */
    iii_gate_set_record_pass(&s, III_GATE_REVERSIBILITY, NULL);
    iii_gate_set_record_fail(&s, III_GATE_EFFECT_SOUNDNESS);
    iii_gate_set_record_fail(&s, III_GATE_CAP_DISCIPLINE);
    TEST(iii_ghost_classify_compromise(&s) == III_VS_COMPROMISE_MEDIUM);

    /* Three critical fail → COMPROMISE_HIGH */
    iii_gate_set_record_fail(&s, III_GATE_TRINITY_GATING);
    TEST(iii_ghost_classify_compromise(&s) == III_VS_COMPROMISE_HIGH);
}

static void test_runtime(void) {
    SECTION("runtime");
    iii_ghost_runtime_t *rt = iii_ghost_runtime_create();
    TEST(rt != NULL);

    uint8_t src[32]; memset(src, 0x11, 32);
    uint64_t id = iii_ghost_runtime_register(rt, "process_request", src, false);
    TEST(id == 1);
    TEST(iii_ghost_runtime_size(rt) == 1);

    iii_ghost_cycle_t *c = iii_ghost_runtime_lookup(rt, id);
    TEST(c != NULL);
    TEST(c->state == III_VS_GHOST);
    TEST(strcmp(c->name, "process_request") == 0);

    /* Should NOT emit code */
    TEST(!iii_ghost_runtime_should_emit_code(rt, id));

    /* Verified-by-construction */
    uint64_t id_vbc = iii_ghost_runtime_register(rt, "frozen_const", src, true);
    TEST(iii_ghost_runtime_lookup(rt, id_vbc)->state == III_VS_VERIFIED);
    TEST(iii_ghost_runtime_should_emit_code(rt, id_vbc));

    iii_ghost_runtime_destroy(rt);
}

static void test_transition(void) {
    SECTION("§3 ghost-to-verified transition");
    iii_ghost_runtime_t *rt = iii_ghost_runtime_create();
    uint8_t src[32]; memset(src, 0x22, 32);
    uint64_t id = iii_ghost_runtime_register(rt, "some_cycle", src, false);

    bool app[III_GATE_COUNT] = {0};
    for (unsigned g = 1; g < III_GATE_COUNT; ++g) app[g] = true;
    TEST(iii_ghost_runtime_set_applicable_gates(rt, id, app));

    /* Should fail to transition until all gates pass */
    TEST(!iii_ghost_runtime_transition(rt, id));

    uint8_t cert[32]; memset(cert, 0x33, 32);
    for (unsigned g = 1; g < III_GATE_COUNT; ++g) {
        TEST(iii_ghost_runtime_record_gate(rt, id, (iii_gate_t)g, true, cert));
    }
    TEST(iii_ghost_runtime_transition(rt, id));
    TEST(iii_ghost_runtime_lookup(rt, id)->state == III_VS_VERIFIED);
    TEST(iii_ghost_runtime_should_emit_code(rt, id));

    /* Closure root non-zero. */
    uint8_t croot[32];
    iii_ghost_runtime_closure_root(rt, croot);
    bool any = false;
    for (unsigned i = 0; i < 32; ++i) if (croot[i]) { any = true; break; }
    TEST(any);

    /* Revoke. */
    TEST(iii_ghost_runtime_revoke(rt, id));
    TEST(iii_ghost_runtime_lookup(rt, id)->state == III_VS_GHOST);

    iii_ghost_runtime_destroy(rt);
}

static void test_dispatch(void) {
    SECTION("§4.3 dispatch");
    iii_ghost_runtime_t *rt = iii_ghost_runtime_create();
    uint8_t src[32]; memset(src, 0x44, 32);
    uint64_t gid = iii_ghost_runtime_register(rt, "ghost", src, false);
    uint64_t vid = iii_ghost_runtime_register(rt, "verified", src, true);

    /* Ghost cycle → reject */
    TEST(iii_ghost_runtime_dispatch(rt, gid, NULL, 0) == III_DV_REJECT_GHOST_NOT_EXECUTABLE);

    /* Verified → dispatch normal */
    TEST(iii_ghost_runtime_dispatch(rt, vid, NULL, 0) == III_DV_DISPATCH_NORMAL);

    /* Compromise.MEDIUM cycle */
    uint8_t src2[32]; memset(src2, 0x55, 32);
    uint64_t mid = iii_ghost_runtime_register(rt, "compromise_med", src2, false);
    bool app[III_GATE_COUNT] = {0};
    for (unsigned g = 1; g < III_GATE_COUNT; ++g) app[g] = true;
    iii_ghost_runtime_set_applicable_gates(rt, mid, app);
    /* Pass all but two critical (effect-soundness + cap-discipline) */
    for (unsigned g = 1; g < III_GATE_COUNT; ++g) {
        if (g == III_GATE_EFFECT_SOUNDNESS || g == III_GATE_CAP_DISCIPLINE) continue;
        iii_ghost_runtime_record_gate(rt, mid, (iii_gate_t)g, true, NULL);
    }
    iii_ghost_runtime_record_gate(rt, mid, III_GATE_EFFECT_SOUNDNESS, false, NULL);
    iii_ghost_runtime_record_gate(rt, mid, III_GATE_CAP_DISCIPLINE,   false, NULL);
    TEST(iii_ghost_runtime_reclassify(rt, mid) == III_VS_COMPROMISE_MEDIUM);
    /* No cap → reject */
    TEST(iii_ghost_runtime_dispatch(rt, mid, NULL, 0) == III_DV_REJECT_NEEDS_CAP);

    iii_ghost_cap_grant_t cap = {0};
    cap.cap = III_CAP_EXECUTE_COMPROMISED_MEDIUM;
    TEST(iii_ghost_runtime_dispatch(rt, mid, &cap, 1) == III_DV_DISPATCH_COMPROMISE_MED);

    /* Compromise.HIGH cycle: needs cap with tier3+anchor+trinity */
    uint64_t hid = iii_ghost_runtime_register(rt, "comp_high", src2, false);
    iii_ghost_runtime_set_applicable_gates(rt, hid, app);
    for (unsigned g = 1; g < III_GATE_COUNT; ++g) iii_ghost_runtime_record_gate(rt, hid, (iii_gate_t)g, true, NULL);
    /* Now fail 3 critical */
    iii_ghost_runtime_record_gate(rt, hid, III_GATE_EFFECT_SOUNDNESS, false, NULL);
    iii_ghost_runtime_record_gate(rt, hid, III_GATE_CAP_DISCIPLINE,   false, NULL);
    iii_ghost_runtime_record_gate(rt, hid, III_GATE_TRINITY_GATING,   false, NULL);
    TEST(iii_ghost_runtime_reclassify(rt, hid) == III_VS_COMPROMISE_HIGH);

    iii_ghost_cap_grant_t hcap = {0};
    hcap.cap = III_CAP_EXECUTE_COMPROMISED_HIGH;
    /* Without tier3+anchor+trinity → reject NEEDS_CAP */
    TEST(iii_ghost_runtime_dispatch(rt, hid, &hcap, 1) == III_DV_REJECT_NEEDS_CAP);
    hcap.tier3_amended = true;
    hcap.anchor_cosigned = true;
    /* Still no trinity → reject NEEDS_TRINITY */
    TEST(iii_ghost_runtime_dispatch(rt, hid, &hcap, 1) == III_DV_REJECT_NEEDS_TRINITY);
    hcap.trinity_admitted = true;
    TEST(iii_ghost_runtime_dispatch(rt, hid, &hcap, 1) == III_DV_DISPATCH_COMPROMISE_HIGH);

    /* Compromise.LOW cycle: pass every gate EXCEPT reversibility → LOW.
     * RITCHIE Stage 1.15: LOW is auto-dispatchable WITHOUT any capability
     * (the inert cap-check whose both branches returned the same value was
     * removed). This test pins that contract: dispatch with NULL caps must
     * return DISPATCH_COMPROMISE_LOW, not REJECT_NEEDS_CAP. */
    uint8_t src3[32]; memset(src3, 0x77, 32);
    uint64_t lid = iii_ghost_runtime_register(rt, "compromise_low", src3, false);
    iii_ghost_runtime_set_applicable_gates(rt, lid, app);
    for (unsigned g = 1; g < III_GATE_COUNT; ++g) {
        if (g == III_GATE_REVERSIBILITY) continue;
        iii_ghost_runtime_record_gate(rt, lid, (iii_gate_t)g, true, NULL);
    }
    iii_ghost_runtime_record_gate(rt, lid, III_GATE_REVERSIBILITY, false, NULL);
    TEST(iii_ghost_runtime_reclassify(rt, lid) == III_VS_COMPROMISE_LOW);
    TEST(iii_ghost_runtime_dispatch(rt, lid, NULL, 0) == III_DV_DISPATCH_COMPROMISE_LOW);

    iii_ghost_runtime_destroy(rt);
}

static void test_propagation(void) {
    SECTION("§4.4 propagation");
    iii_ghost_runtime_t *rt = iii_ghost_runtime_create();
    uint8_t src[32]; memset(src, 0x66, 32);
    uint64_t v = iii_ghost_runtime_register(rt, "v", src, true);
    uint64_t g = iii_ghost_runtime_register(rt, "g", src, false);
    /* v calls g — v's tier should drop to ghost. */
    TEST(iii_ghost_runtime_register_call(rt, v, g));
    iii_ghost_runtime_propagate(rt);
    TEST(iii_ghost_runtime_lookup(rt, v)->state == III_VS_GHOST);
    iii_ghost_runtime_destroy(rt);
}

static void test_hexads(void) {
    SECTION("§6 hexads");
    iii_ghost_hexad_pillars_t p;
    iii_ghost_hexad_get_pillars(III_GH_VERIFICATION_GATE_FAIL, &p);
    TEST(p.classifies_compromise_medium);
    TEST(p.p[0] == 2 || p.p[1] == 2);  /* at least one NEG */

    iii_ghost_hexad_get_pillars(III_GH_GHOST_TO_VERIFIED, &p);
    TEST(p.admissible);
    /* All POS or ZERO */
    bool any_neg = false;
    for (unsigned i = 0; i < 6; ++i) if (p.p[i] == 2) any_neg = true;
    TEST(!any_neg);
}

static void test_witness_kinds(void) {
    SECTION("§7 witness kinds");
    TEST(iii_ghost_witness_for_gate(III_GATE_TYPE_CORRECTNESS) == III_GW_GATE_VERIFY_TYPE_CORRECTNESS);
    TEST(iii_ghost_witness_for_gate(III_GATE_CLOSURE_ROOT)     == III_GW_GATE_VERIFY_CLOSURE_ROOT);
}

int main(void) {
    test_gates();
    test_classify();
    test_runtime();
    test_transition();
    test_dispatch();
    test_propagation();
    test_hexads();
    test_witness_kinds();
    printf("\n=== %d passed, %d failed ===\n", g_pass, g_fail);
    return g_fail == 0 ? 0 : 1;
}
