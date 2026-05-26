#include "iii/catalyst.h"
#include <stdio.h>
#include <string.h>

static int g_pass = 0, g_fail = 0;
#define TEST(c) do { if (c) { g_pass++; printf("  PASS %s\n", #c); } \
    else { g_fail++; printf("  FAIL %s @ %s:%d\n", #c, __FILE__, __LINE__); } } while (0)
#define SECTION(s) printf("\n[%s]\n", s)

static void make_request(iii_cat_promotion_request_t *r, iii_cat_promotion_kind_t kind) {
    memset(r, 0, sizeof(*r));
    r->kind = kind;
    memset(r->candidate_source_mhash, 0xAA, 32);
    r->candidate_hexad = 0x07; /* admissible */
    r->projected_coherence_q14 = 16000;
    r->coherence_floor_q14 = 15073;
    r->observatory_saturated = true;
    r->trinity_admitted = true;
    r->ceiling_admitted = true;
    r->hexad_reachable = true;
    r->codegen_passed = true;
    r->semantic_baseline_match = true;
    r->target_ring = III_CAT_VR_SANCTUM;
}

static void test_caps(void) {
    SECTION("§2.3 rate caps");
    iii_catalyst_t *c = iii_catalyst_create();
    TEST(iii_catalyst_rate_cap(c, III_CAT_CYCLE) == 8u);
    TEST(iii_catalyst_rate_cap(c, III_CAT_PHASE) == 4u);
    TEST(iii_catalyst_rate_cap(c, III_CAT_MODULE_FUSION) == 16u);
    TEST(iii_catalyst_rate_cap(c, III_CAT_KEYWORD) == 1u);
    iii_catalyst_destroy(c);
}

static void test_propose_success(void) {
    SECTION("§2 propose success");
    iii_catalyst_t *c = iii_catalyst_create();

    iii_cat_promotion_request_t req;
    make_request(&req, III_CAT_CYCLE);

    iii_cat_promotion_outcome_t out;
    iii_catalyst_propose(c, &req, &out);
    TEST(out.flag == III_CAT_DF_SAFE_APPROVED);
    TEST(out.promoted);
    TEST(iii_cat_gates_all_passed(&out.gates));

    /* Witness mhash non-zero */
    bool any = false;
    for (unsigned i = 0; i < 32; ++i) if (out.promote_witness_mhash[i]) { any = true; break; }
    TEST(any);

    /* Counter increments */
    TEST(iii_catalyst_cycle_count_this_tick(c) == 1);

    /* Semantic baseline mismatch → SAFE_FLAGGED */
    req.semantic_baseline_match = false;
    iii_catalyst_propose(c, &req, &out);
    TEST(out.flag == III_CAT_DF_SAFE_FLAGGED);

    iii_catalyst_destroy(c);
}

static void test_gate_failures(void) {
    SECTION("§2.1 gate failures");
    iii_catalyst_t *c = iii_catalyst_create();
    iii_cat_promotion_request_t req;
    iii_cat_promotion_outcome_t out;

    /* Trinity rejected */
    make_request(&req, III_CAT_CYCLE);
    req.trinity_admitted = false;
    iii_catalyst_propose(c, &req, &out);
    TEST(out.flag == III_CAT_DF_UNSAFE_REJECTED);
    TEST(!out.gates.passed[III_CGATE_TRINITY]);
    TEST(iii_cat_gates_first_failure(&out.gates) == III_CGATE_TRINITY);

    /* Hexad unreachable */
    make_request(&req, III_CAT_CYCLE);
    req.hexad_reachable = false;
    iii_catalyst_propose(c, &req, &out);
    TEST(out.flag == III_CAT_DF_UNSAFE_REJECTED);
    TEST(!out.gates.passed[III_CGATE_HEXAD_REACH]);

    /* Coherence below floor */
    make_request(&req, III_CAT_CYCLE);
    req.projected_coherence_q14 = 1000;
    iii_catalyst_propose(c, &req, &out);
    TEST(out.flag == III_CAT_DF_UNSAFE_REJECTED);
    TEST(!out.gates.passed[III_CGATE_MOBIUS_COHERENCE]);

    /* Observatory not saturated */
    make_request(&req, III_CAT_CYCLE);
    req.observatory_saturated = false;
    iii_catalyst_propose(c, &req, &out);
    TEST(out.flag == III_CAT_DF_UNSAFE_REJECTED);
    TEST(!out.gates.passed[III_CGATE_OBSERVATORY_SAT]);

    iii_catalyst_destroy(c);
}

static void test_rate_cap(void) {
    SECTION("§2.3 rate cap enforcement");
    iii_catalyst_t *c = iii_catalyst_create();
    iii_cat_promotion_request_t req;
    iii_cat_promotion_outcome_t out;
    make_request(&req, III_CAT_CYCLE);

    unsigned ok = 0, capped = 0;
    for (unsigned i = 0; i < 16; ++i) {
        iii_catalyst_propose(c, &req, &out);
        if (out.promoted) ok++;
        else if (out.flag == III_CAT_DF_UNSAFE_REJECTED) capped++;
    }
    TEST(ok == 8);
    TEST(capped >= 1);

    /* Tick resets the cap */
    iii_catalyst_tick(c);
    TEST(iii_catalyst_cycle_count_this_tick(c) == 0);
    iii_catalyst_propose(c, &req, &out);
    TEST(out.promoted);

    /* Module fusion has cap=16 */
    make_request(&req, III_CAT_MODULE_FUSION);
    ok = 0;
    for (unsigned i = 0; i < 32; ++i) {
        iii_catalyst_propose(c, &req, &out);
        if (out.promoted) ok++;
    }
    TEST(ok == 16);

    iii_catalyst_destroy(c);
}

static void test_pause_resume(void) {
    SECTION("§4.3 pause/resume");
    iii_catalyst_t *c = iii_catalyst_create();
    iii_cat_promotion_request_t req;
    iii_cat_promotion_outcome_t out;
    make_request(&req, III_CAT_CYCLE);

    iii_catalyst_pause(c);
    TEST(iii_catalyst_is_paused(c));
    iii_catalyst_propose(c, &req, &out);
    TEST(out.flag == III_CAT_DF_UNSAFE_REJECTED);
    TEST(!out.promoted);

    iii_catalyst_resume(c);
    TEST(!iii_catalyst_is_paused(c));
    iii_catalyst_propose(c, &req, &out);
    TEST(out.promoted);

    iii_catalyst_destroy(c);
}

static void test_revoke(void) {
    SECTION("§4.3 revoke");
    iii_catalyst_t *c = iii_catalyst_create();
    iii_cat_promotion_request_t req;
    iii_cat_promotion_outcome_t out;
    make_request(&req, III_CAT_CYCLE);
    iii_catalyst_propose(c, &req, &out);
    TEST(out.promoted);

    TEST(iii_catalyst_revoke(c, out.promote_witness_mhash));
    TEST(iii_catalyst_revocation_count(c) == 1);

    /* Cannot double-revoke */
    TEST(!iii_catalyst_revoke(c, out.promote_witness_mhash));
    iii_catalyst_destroy(c);
}

static void test_constrain(void) {
    SECTION("§4.3 constrain");
    iii_catalyst_t *c = iii_catalyst_create();
    iii_catalyst_constrain(c, III_CAT_CYCLE, 2);
    TEST(iii_catalyst_rate_cap(c, III_CAT_CYCLE) == 2u);

    iii_cat_promotion_request_t req;
    iii_cat_promotion_outcome_t out;
    make_request(&req, III_CAT_CYCLE);
    unsigned ok = 0;
    for (unsigned i = 0; i < 8; ++i) {
        iii_catalyst_propose(c, &req, &out);
        if (out.promoted) ok++;
    }
    TEST(ok == 2);

    iii_catalyst_destroy(c);
}

int main(void) {
    test_caps();
    test_propose_success();
    test_gate_failures();
    test_rate_cap();
    test_pause_resume();
    test_revoke();
    test_constrain();
    printf("\n=== %d passed, %d failed ===\n", g_pass, g_fail);
    return g_fail == 0 ? 0 : 1;
}
