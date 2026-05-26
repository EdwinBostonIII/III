#include "iii/federation.h"
#include <stdio.h>
#include <string.h>

static int g_pass = 0, g_fail = 0;
#define TEST(c) do { if (c) { g_pass++; printf("  PASS %s\n", #c); } \
    else { g_fail++; printf("  FAIL %s @ %s:%d\n", #c, __FILE__, __LINE__); } } while (0)
#define SECTION(s) printf("\n[%s]\n", s)

static void test_tiers(void) {
    SECTION("§1 tiers");
    TEST(iii_fed_outbound_rule_for(III_TIER_TRANSIENT)      == III_FOB_LOCAL_ONLY);
    TEST(iii_fed_outbound_rule_for(III_TIER_HOST_FILE)      == III_FOB_PEER_PULL);
    TEST(iii_fed_outbound_rule_for(III_TIER_FEDERATION)     == III_FOB_BROADCAST);
    TEST(iii_fed_outbound_rule_for(III_TIER_CONSTITUTIONAL) == III_FOB_FULL_QUORUM);

    iii_quorum_spec_t q1 = iii_fed_quorum_for_tier(III_TIER_HOST_FILE);
    TEST(q1.total_peers == 3 && q1.min_agree == 2);
    iii_quorum_spec_t q2 = iii_fed_quorum_for_tier(III_TIER_FEDERATION);
    TEST(q2.total_peers == 5 && q2.min_agree == 3);
    iii_quorum_spec_t q3 = iii_fed_quorum_for_tier(III_TIER_CONSTITUTIONAL);
    TEST(q3.unanimous);
}

static void test_min_tier(void) {
    SECTION("§2.1 min-tier");
    iii_fed_tier_t a[3] = { III_TIER_FEDERATION, III_TIER_HOST_FILE, III_TIER_CONSTITUTIONAL };
    TEST(iii_fed_min_tier(a, 3) == III_TIER_HOST_FILE);

    iii_fed_tier_t b[3] = { III_TIER_FEDERATION, III_TIER_TRANSIENT, III_TIER_CONSTITUTIONAL };
    TEST(iii_fed_min_tier(b, 3) == III_TIER_TRANSIENT);
}

static void test_outbound(void) {
    SECTION("§2 outbound");
    iii_fed_runtime_t *rt = iii_fed_runtime_create();
    /* Register 5 peers */
    uint8_t fp[32] = {0xAA};
    uint8_t pk[32] = {0xBB};
    for (unsigned i = 0; i < 5; ++i) {
        iii_fed_register_peer(rt, "peer", fp, pk);
    }
    TEST(iii_fed_peer_count(rt) == 5);
    TEST(iii_fed_live_peer_count(rt) == 5);

    /* Transient → reject */
    iii_fed_message_t msg;
    memset(&msg, 0, sizeof(msg));
    msg.declared_tier = III_TIER_TRANSIENT;
    iii_fed_outbound_result_t res;
    iii_fed_propose_outbound(rt, &msg, &res);
    TEST(res.status == III_FOB_REJECT_TIER0);
    TEST(res.effective_tier == III_TIER_TRANSIENT);

    /* Host_file with 3 live peers → ok */
    msg.declared_tier = III_TIER_HOST_FILE;
    iii_fed_propose_outbound(rt, &msg, &res);
    TEST(res.status == III_FOB_OK);

    /* Federation needs 5 live → ok */
    msg.declared_tier = III_TIER_FEDERATION;
    iii_fed_propose_outbound(rt, &msg, &res);
    TEST(res.status == III_FOB_OK);

    /* min-tier overrides declared */
    iii_fed_tier_t contributing[2] = { III_TIER_FEDERATION, III_TIER_TRANSIENT };
    msg.declared_tier = III_TIER_FEDERATION;
    msg.contributing_tiers = contributing;
    msg.contributing_count = 2;
    iii_fed_propose_outbound(rt, &msg, &res);
    TEST(res.status == III_FOB_REJECT_TIER0);

    iii_fed_runtime_destroy(rt);
}

static void test_quorum(void) {
    SECTION("§4 quorum");
    iii_fed_runtime_t *rt = iii_fed_runtime_create();
    uint8_t fp[32] = {0}, pk[32] = {0};
    uint64_t pid[5];
    for (unsigned i = 0; i < 5; ++i) pid[i] = iii_fed_register_peer(rt, "p", fp, pk);

    iii_quorum_spec_t spec = iii_fed_quorum_for_tier(III_TIER_FEDERATION);

    /* 5 votes, 3 agree, valid signatures → OK */
    iii_fed_vote_t votes[5];
    for (unsigned i = 0; i < 5; ++i) {
        memset(&votes[i], 0, sizeof(votes[i]));
        votes[i].peer_id = pid[i];
        votes[i].agree = (i < 3);
        memset(votes[i].signature, 0xCD, 64);  /* non-zero = valid in our model */
    }
    TEST(iii_fed_evaluate_quorum(rt, &spec, votes, 5) == III_FOB_OK);

    /* 5 votes, 2 agree → fail */
    votes[2].agree = false;
    TEST(iii_fed_evaluate_quorum(rt, &spec, votes, 5) == III_FOB_REJECT_QUORUM_FAIL);

    /* All-zero signature → reject */
    votes[2].agree = true;
    memset(votes[2].signature, 0, 64);
    TEST(iii_fed_evaluate_quorum(rt, &spec, votes, 5) == III_FOB_REJECT_SIGNATURE);

    /* Unanimous quorum: all 5 must agree */
    iii_quorum_spec_t un = iii_fed_quorum_for_tier(III_TIER_CONSTITUTIONAL);
    /* Restore valid signatures, all agree */
    for (unsigned i = 0; i < 5; ++i) {
        memset(votes[i].signature, 0xCD, 64);
        votes[i].agree = true;
    }
    TEST(iii_fed_evaluate_quorum(rt, &un, votes, 5) == III_FOB_OK);

    /* One disagrees → fail */
    votes[0].agree = false;
    TEST(iii_fed_evaluate_quorum(rt, &un, votes, 5) == III_FOB_REJECT_QUORUM_FAIL);

    iii_fed_runtime_destroy(rt);
}

static void test_fusion_tier(void) {
    SECTION("§3 fusion tier");
    bool requires;
    TEST(iii_fed_fusion_tier(III_TIER_FEDERATION, III_TIER_FEDERATION, &requires) == III_TIER_FEDERATION);
    TEST(!requires);

    TEST(iii_fed_fusion_tier(III_TIER_CONSTITUTIONAL, III_TIER_HOST_FILE, &requires) == III_TIER_HOST_FILE);
    TEST(requires);
}

static void test_peer_lifecycle(void) {
    SECTION("peer lifecycle");
    iii_fed_runtime_t *rt = iii_fed_runtime_create();
    uint8_t fp[32] = {0}, pk[32] = {0};
    uint64_t a = iii_fed_register_peer(rt, "alpha", fp, pk);
    TEST(a != 0);
    TEST(iii_fed_live_peer_count(rt) == 1);

    iii_fed_set_peer_live(rt, a, false);
    TEST(iii_fed_live_peer_count(rt) == 0);

    const iii_fed_peer_t *p = iii_fed_peer_lookup(rt, a);
    TEST(p && !p->live);

    iii_fed_runtime_destroy(rt);
}

int main(void) {
    test_tiers();
    test_min_tier();
    test_outbound();
    test_quorum();
    test_fusion_tier();
    test_peer_lifecycle();
    printf("\n=== %d passed, %d failed ===\n", g_pass, g_fail);
    return g_fail == 0 ? 0 : 1;
}
