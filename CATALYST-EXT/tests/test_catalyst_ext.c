#include "iii/catalyst_ext.h"
#include "iii/cycles.h"
#include <stdio.h>
#include <string.h>

static int g_pass = 0, g_fail = 0;
#define TEST(c) do { if (c) { g_pass++; printf("  PASS %s\n", #c); } \
    else { g_fail++; printf("  FAIL %s @ %s:%d\n", #c, __FILE__, __LINE__); } } while (0)
#define SECTION(s) printf("\n[%s]\n", s)

static void test_cdag(void) {
    SECTION("§1 causal DAG");
    iii_cdag_t *d = iii_cdag_create();
    /* Drive enough observations to push confidence above floor. */
    for (unsigned i = 0; i < 2000; ++i) iii_cdag_observe(d, 0x10, 0x20, 50);
    iii_cdag_edge_t e;
    TEST(iii_cdag_get_edge(d, 0x10, 0x20, &e));
    TEST(e.confidence_q14 >= XII_CATALYST_SYNTHESIS_CONFIDENCE_FLOOR);
    TEST(e.frequency == 2000);
    iii_cdag_destroy(d);
}

static void test_anchor_filter(void) {
    SECTION("§6 anchor restraint");
    iii_cext_anchor_check_t ok = {0};
    TEST(iii_cext_filter_for_anchor(&ok));
    iii_cext_anchor_check_t bad = {0};
    bad.modifies_anchor_pubkey = true;
    TEST(!iii_cext_filter_for_anchor(&bad));

    iii_cext_anchor_check_t bad2 = {0};
    bad2.synthesizes_substitute_anchor = true;
    TEST(!iii_cext_filter_for_anchor(&bad2));

    iii_cext_rejection_log_t log = { .total_rejections = 100, .anchor_rejections = 15 };
    TEST(iii_cext_anchor_attack_pattern(&log));

    log.anchor_rejections = 5;
    TEST(!iii_cext_anchor_attack_pattern(&log));
}

static void test_replay(void) {
    SECTION("§2 counterfactual replay (real BCWL chain walk)");
    iii_bcwl_t *b = iii_bcwl_create();
    /* Insert 3 witnesses with cycle_seq in our target range. */
    iii_xii_witness_t w[3] = {0};
    for (unsigned i = 0; i < 3; ++i) {
        memset(w[i].predecessor_mhash, (int)(0x10 + i), 32);
        memset(w[i].successor_mhash,   (int)(0x20 + i), 32);
        w[i].step_kind = (uint16_t)(0x100 + i);
        w[i].cycle_seq = (uint32_t)(1500 + i);
        w[i].chronos_tsc = 1000 + i * 100;
        w[i].cost_q14 = 5000;
        w[i].capability_bind = 0xCAFE;
        w[i].adversariality_class = 0;
        w[i].federation_route = 0;
        w[i].plan_anchor_id = 1;
        w[i].flags = III_XII_FLAG_HOT_PATH;
        w[i].hexad_packed = 0x0DA1;
        for (unsigned j = 0; j < 22; ++j) w[i].hmac_tail[j] = (uint8_t)(0x40 + i + j);
        iii_bcwl_insert(b, &w[i]);
    }

    /* First call: compute the audit hash by running replay with all-zero
     * expected hashes (will FAIL_AUDIT_HASH since SHA-256(empty) != all-zero). */
    iii_cext_replay_input_t in = {0};
    in.candidate.candidate_id = 42;
    in.witness_range_start = 1000;
    in.witness_range_end   = 2000;
    in.divergence_score_q14 = 1000;
    iii_cext_replay_result_t res;
    iii_cext_counterfactual_replay(b, &in, &res);
    TEST(res.visited_count == 3);
    TEST(res.status == III_CXR_FAILED_AUDIT_HASH);

    /* Second call: feed back the computed audit hash, replay should verify. */
    memcpy(in.expected_audit_hash, res.computed_audit_hash, 32);
    iii_cext_counterfactual_replay(b, &in, &res);
    TEST(res.status == III_CXR_VERIFIED);

    /* Tamper one bit -> FAILED_AUDIT_HASH. */
    in.expected_audit_hash[0] ^= 0x01u;
    iii_cext_counterfactual_replay(b, &in, &res);
    TEST(res.status == III_CXR_FAILED_AUDIT_HASH);
    in.expected_audit_hash[0] ^= 0x01u;

    /* Divergence threshold. */
    in.divergence_score_q14 = 8000;
    iii_cext_counterfactual_replay(b, &in, &res);
    TEST(res.status == III_CXR_FAILED_DIVERGENCE);

    /* No bcwl -> FAILED_AUDIT_HASH. */
    in.divergence_score_q14 = 0;
    iii_cext_counterfactual_replay(NULL, &in, &res);
    TEST(res.status == III_CXR_FAILED_AUDIT_HASH);

    /* Empty range (no witnesses) -> FAILED_AUDIT_HASH. */
    in.witness_range_start = 5000;
    in.witness_range_end   = 6000;
    iii_cext_counterfactual_replay(b, &in, &res);
    TEST(res.status == III_CXR_FAILED_AUDIT_HASH);
    TEST(res.visited_count == 0);

    iii_bcwl_destroy(b);
}

static void test_synthesis(void) {
    SECTION("§1 synthesis");
    iii_cext_runtime_t *rt = iii_cext_runtime_create();
    iii_cdag_edge_t edge = { .from = 0x10, .to = 0x20, .confidence_q14 = 14000, .frequency = 5000, .mean_latency_us = 30 };

    /* Real Z_3^6 hexads: source cycles' safety pillars. */
    iii_hexad_z3_6_t h_from = { .component = {1, 2, 0, 1, 2, 0} };
    iii_hexad_z3_6_t h_to   = { .component = {2, 0, 1, 2, 0, 1} };

    iii_composite_candidate_t cand;
    TEST(iii_cext_synthesize(rt, &edge, &h_from, &h_to, &cand));
    TEST(cand.candidate_id != 0);
    TEST(cand.c1_kind == 0x10 && cand.c2_kind == 0x20);

    /* Composed hexad = (1+2)%3, (2+0)%3, (0+1)%3, (1+2)%3, (2+0)%3, (0+1)%3
     *               = (0, 2, 1, 0, 2, 1) */
    TEST(cand.composed_hexad.component[0] == 0);
    TEST(cand.composed_hexad.component[1] == 2);
    TEST(cand.composed_hexad.component[2] == 1);
    TEST(cand.composed_hexad.component[3] == 0);
    TEST(cand.composed_hexad.component[4] == 2);
    TEST(cand.composed_hexad.component[5] == 1);

    /* Packed admit slot: pillars (0,2,1,0,2,1) with 2 bits each:
     * pillar 0 = 00 (bits 1..0)
     * pillar 1 = 10 (bits 3..2)
     * pillar 2 = 01 (bits 5..4)
     * pillar 3 = 00 (bits 7..6)
     * pillar 4 = 10 (bits 9..8)
     * pillar 5 = 01 (bits 11..10)
     * = 0b011000010100_1000 → 0x0628_8 ... actually just verify it's nonzero
     * and matches the pack function. */
    uint16_t expected = (uint16_t)((0u<<0) | (2u<<2) | (1u<<4) | (0u<<6) | (2u<<8) | (1u<<10));
    TEST(cand.composed_hexad_admit == expected);

    /* Forward / inverse / synthesis witness mhashes are all bound to inputs. */
    bool any_f = false;
    for (unsigned i = 0; i < 32; ++i) if (cand.forward_mhash[i]) { any_f = true; break; }
    TEST(any_f);
    bool any_i = false;
    for (unsigned i = 0; i < 32; ++i) if (cand.inverse_mhash[i]) { any_i = true; break; }
    TEST(any_i);
    /* Inverse must differ from forward (different canonical encoding). */
    TEST(memcmp(cand.forward_mhash, cand.inverse_mhash, 32) != 0);

    /* Determinism: same inputs → same forward_mhash on a fresh runtime. */
    iii_cext_runtime_t *rt2 = iii_cext_runtime_create();
    iii_composite_candidate_t cand2;
    iii_cext_synthesize(rt2, &edge, &h_from, &h_to, &cand2);
    TEST(memcmp(cand.forward_mhash, cand2.forward_mhash, 32) == 0);
    iii_cext_runtime_destroy(rt2);

    /* Swapping h_from and h_to changes the forward hash (composition is
     * commutative on the hexad but the mhash binds order via the encoded
     * h_from || h_to ordering). */
    iii_cext_runtime_t *rt3 = iii_cext_runtime_create();
    iii_composite_candidate_t cand3;
    iii_cext_synthesize(rt3, &edge, &h_to, &h_from, &cand3);
    TEST(memcmp(cand.forward_mhash, cand3.forward_mhash, 32) != 0);
    iii_cext_runtime_destroy(rt3);

    /* Below confidence floor → fail */
    edge.confidence_q14 = 1000;
    TEST(!iii_cext_synthesize(rt, &edge, &h_from, &h_to, &cand));

    /* NULL hexads → fail */
    edge.confidence_q14 = 14000;
    TEST(!iii_cext_synthesize(rt, &edge, NULL, &h_to, &cand));
    TEST(!iii_cext_synthesize(rt, &edge, &h_from, NULL, &cand));

    iii_cext_runtime_destroy(rt);
}

static void test_propose(void) {
    SECTION("§3 propose+gates");
    iii_cext_runtime_t *rt = iii_cext_runtime_create();
    iii_cext_promotion_request_t req = {0};
    req.candidate.candidate_id = 1;
    req.hexad_admissible = true;
    req.sid_inverse_derivable = true;
    req.replay_status = III_CXR_VERIFIED;
    req.predicted_coherence_q14 = 14000;
    req.trinity_admitted = true;
    req.anchor_cosigned = true;
    req.tier = 3;

    iii_cext_promotion_outcome_t out;
    iii_cext_propose(rt, &req, &out);
    TEST(out.promoted);
    TEST(out.failed_gate == III_CXG_COUNT);

    /* Anchor attack */
    req.anchor_check.modifies_anchor_pubkey = true;
    req.candidate.candidate_id = 2;
    iii_cext_propose(rt, &req, &out);
    TEST(!out.promoted);
    TEST(out.failed_gate == III_CXG_ANCHOR_RESTRAINT);

    iii_cext_runtime_destroy(rt);
}

static void test_rate_cap(void) {
    SECTION("§4 rate cap");
    iii_cext_runtime_t *rt = iii_cext_runtime_create();
    iii_cext_promotion_request_t req = {0};
    req.hexad_admissible = true;
    req.sid_inverse_derivable = true;
    req.replay_status = III_CXR_VERIFIED;
    req.predicted_coherence_q14 = 14000;
    req.tier = 1;

    unsigned ok = 0;
    for (unsigned i = 0; i < 16; ++i) {
        req.candidate.candidate_id = (uint64_t)(i + 1u);
        iii_cext_promotion_outcome_t out;
        iii_cext_propose(rt, &req, &out);
        if (out.promoted) ok++;
    }
    TEST(ok == XII_MNEME_CATALYST_PROMOTION_PER_TICK_MAX);

    iii_cext_runtime_tick(rt);
    TEST(iii_cext_promotions_this_tick(rt) == 0);

    iii_cext_runtime_destroy(rt);
}

static void test_coherence_monitoring(void) {
    SECTION("§5 coherence monitoring");
    iii_cext_runtime_t *rt = iii_cext_runtime_create();
    iii_cext_record_coherence(rt, 100, 14000);
    TEST(!iii_cext_should_depromote(rt, 100));

    iii_cext_record_coherence(rt, 100, 8000);
    TEST(iii_cext_should_depromote(rt, 100));

    TEST(iii_cext_depromote(rt, 100));
    TEST(!iii_cext_should_depromote(rt, 100)); /* already depromoted */

    iii_cext_runtime_destroy(rt);
}

static void test_synthesis_halt(void) {
    SECTION("§6 synthesis halt on attack");
    iii_cext_runtime_t *rt = iii_cext_runtime_create();
    iii_cext_promotion_request_t req = {0};
    req.hexad_admissible = true;
    req.sid_inverse_derivable = true;
    req.replay_status = III_CXR_VERIFIED;
    req.predicted_coherence_q14 = 14000;
    req.tier = 1;
    req.anchor_check.modifies_anchor_pubkey = true;

    /* Submit many anchor-violating candidates */
    for (unsigned i = 0; i < 20; ++i) {
        req.candidate.candidate_id = (uint64_t)(i + 1u);
        iii_cext_promotion_outcome_t out;
        iii_cext_propose(rt, &req, &out);
    }
    TEST(iii_cext_synthesis_halted(rt));
    TEST(iii_cext_anchor_alarm_count(rt) > 0);

    iii_cext_resume_synthesis(rt);
    TEST(!iii_cext_synthesis_halted(rt));

    iii_cext_runtime_destroy(rt);
}

static void test_jit(void) {
    SECTION("§7 JIT (real x86-64 emit)");
    iii_cext_runtime_t *rt = iii_cext_runtime_create();
    iii_cext_jit_record_t r;
    TEST(iii_cext_jit_compile(rt, 100, III_CXA_X86_64, 256, &r));
    TEST(r.cycle_id == 100);
    TEST(r.machine_code_size == 256);
    TEST(iii_cext_jit_record_count(rt) == 1);

    /* Determinism: same (cycle_id, arch, size) must give same mhash. */
    iii_cext_jit_record_t r2;
    iii_cext_runtime_t *rt2 = iii_cext_runtime_create();
    TEST(iii_cext_jit_compile(rt2, 100, III_CXA_X86_64, 256, &r2));
    TEST(memcmp(r.machine_code_mhash, r2.machine_code_mhash, 32) == 0);
    iii_cext_runtime_destroy(rt2);

    /* Different cycle_id must produce different mhash (since the movabs
     * imm64 differs in the emitted bytes, not just metadata). */
    iii_cext_jit_record_t r3;
    iii_cext_runtime_t *rt3 = iii_cext_runtime_create();
    TEST(iii_cext_jit_compile(rt3, 200, III_CXA_X86_64, 256, &r3));
    TEST(memcmp(r.machine_code_mhash, r3.machine_code_mhash, 32) != 0);
    iii_cext_runtime_destroy(rt3);

    /* Non-x86-64 arch records metadata only (different code path). */
    iii_cext_jit_record_t r_arm;
    iii_cext_runtime_t *rt_arm = iii_cext_runtime_create();
    TEST(iii_cext_jit_compile(rt_arm, 100, III_CXA_ARMV8, 256, &r_arm));
    TEST(r_arm.machine_code_size == 256);
    iii_cext_runtime_destroy(rt_arm);

    TEST(iii_cext_jit_deoptimize(rt, 100));
    TEST(!iii_cext_jit_deoptimize(rt, 100));   /* already deopt */

    iii_cext_runtime_destroy(rt);
}

int main(void) {
    test_cdag();
    test_anchor_filter();
    test_replay();
    test_synthesis();
    test_propose();
    test_rate_cap();
    test_coherence_monitoring();
    test_synthesis_halt();
    test_jit();
    printf("\n=== %d passed, %d failed ===\n", g_pass, g_fail);
    return g_fail == 0 ? 0 : 1;
}
