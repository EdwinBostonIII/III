#include "iii/planetary.h"
#include <stdio.h>
#include <string.h>

static int g_pass = 0, g_fail = 0;
#define TEST(c) do { if (c) { g_pass++; printf("  PASS %s\n", #c); } \
    else { g_fail++; printf("  FAIL %s @ %s:%d\n", #c, __FILE__, __LINE__); } } while (0)
#define SECTION(s) printf("\n[%s]\n", s)

extern void iii_sha256(const void *data, size_t len, uint8_t out[32]);

static void make_admission(iii_pl_admission_cost_t *c, const uint8_t fp[32]) {
    memset(c, 0, sizeof(*c));
    c->drtm_attestation_valid = true;
    c->silicon_fingerprint_unique = true;
    c->pow_difficulty_bits = 0;
    c->pow_nonce = 0;
    /* compute admission_hash = sha256(fp || nonce); since difficulty=0, any hash works */
    uint8_t buf[36];
    memcpy(buf, fp, 32);
    memset(buf + 32, 0, 4);
    iii_sha256(buf, sizeof(buf), c->admission_hash);
}

static void test_admission(void) {
    SECTION("§4 Sybil admission");
    uint8_t fp[32]; memset(fp, 0xAB, 32);
    iii_pl_admission_cost_t c;
    make_admission(&c, fp);
    TEST(iii_pl_admission_check(&c, fp));

    /* Fail: drtm invalid */
    c.drtm_attestation_valid = false;
    TEST(!iii_pl_admission_check(&c, fp));

    /* Fail: PoW unmet — set difficulty=8 (one byte must be zero) */
    make_admission(&c, fp);
    c.pow_difficulty_bits = 8;
    if (c.admission_hash[0] != 0) TEST(!iii_pl_admission_check(&c, fp));
}

static void test_register(void) {
    SECTION("§1 register");
    iii_pl_runtime_t *rt = iii_pl_runtime_create();
    uint8_t fp[32]; memset(fp, 0xCC, 32);
    iii_pl_admission_cost_t c;
    make_admission(&c, fp);
    iii_pl_peer_id_t id = iii_pl_register_peer(rt, &c, fp, 1, 1, 1);
    TEST(id != 0);
    TEST(iii_pl_peer_count(rt) == 1);
    iii_pl_runtime_destroy(rt);
}

static void test_attacks(void) {
    SECTION("§2 attack detection");
    iii_pl_runtime_t *rt = iii_pl_runtime_create();
    uint8_t fp[32]; memset(fp, 0x11, 32);
    iii_pl_admission_cost_t c;
    make_admission(&c, fp);
    iii_pl_peer_id_t pid = iii_pl_register_peer(rt, &c, fp, 0, 0, 0);

    /* Burst emission */
    iii_pl_record_emission_rate(rt, pid, 100, 10000);
    /* Anchor attack */
    iii_pl_record_anchor_attack(rt, pid);
    iii_pl_record_anchor_attack(rt, pid);
    iii_pl_record_anchor_attack(rt, pid);
    /* Suite regression */
    iii_pl_record_active_suite(rt, pid, 0x01);
    /* Closure-root divergence */
    uint8_t bad[32]; memset(bad, 0xDD, 32);
    iii_pl_record_closure_root(rt, pid, bad);

    uint8_t consensus[32]; memset(consensus, 0xEE, 32);
    iii_pl_attack_signal_t sigs[8];
    size_t n = iii_pl_detect_attacks(rt, pid, consensus, 0x10, sigs, 8);
    TEST(n >= 4);

    /* Escalation */
    TEST(iii_pl_signal_escalation_needed(rt, pid, III_PS_HIGH));

    iii_pl_runtime_destroy(rt);
}

static void test_quarantine(void) {
    SECTION("§3 quarantine");
    iii_pl_runtime_t *rt = iii_pl_runtime_create();
    uint8_t fp[32]; memset(fp, 0x99, 32);
    iii_pl_admission_cost_t c;
    make_admission(&c, fp);
    iii_pl_peer_id_t pid = iii_pl_register_peer(rt, &c, fp, 0, 0, 0);

    TEST(iii_pl_quarantine(rt, pid) == III_PQ_OK);
    TEST(iii_pl_quarantine(rt, pid) == III_PQ_ALREADY);
    TEST(iii_pl_quarantined_count(rt) == 1);

    TEST(iii_pl_unquarantine(rt, pid) == III_PQ_OK);
    TEST(iii_pl_quarantined_count(rt) == 0);
    TEST(iii_pl_quarantine(rt, 9999) == III_PQ_NOT_FOUND);
    iii_pl_runtime_destroy(rt);
}

static void test_multipath(void) {
    SECTION("§5 multipath connectivity");
    iii_pl_routing_path_t paths[3];
    paths[0].length = 2; paths[0].hops[0] = 1; paths[0].hops[1] = 2;
    paths[1].length = 2; paths[1].hops[0] = 3; paths[1].hops[1] = 4;
    paths[2].length = 2; paths[2].hops[0] = 5; paths[2].hops[1] = 6;
    iii_pl_connectivity_t c;
    iii_pl_assess_connectivity(paths, 3, &c);
    TEST(c.satisfies_multipath);

    /* Overlapping paths */
    paths[1].hops[1] = 2;  /* shared with paths[0] */
    iii_pl_assess_connectivity(paths, 3, &c);
    TEST(!c.satisfies_multipath);
}

static void test_reconcile(void) {
    SECTION("§7 reconcile");
    uint8_t a[32]; memset(a, 0xAA, 32);
    uint8_t b[32]; memset(b, 0xBB, 32);
    TEST(iii_pl_reconcile(100, 100, a, a) == III_PR_IN_SYNC);
    TEST(iii_pl_reconcile( 50, 100, a, a) == III_PR_BEHIND);
    TEST(iii_pl_reconcile(100,  50, a, a) == III_PR_AHEAD);
    TEST(iii_pl_reconcile(100, 100, a, b) == III_PR_DIVERGED);
    TEST(iii_pl_reconcile(100, 5000, a, b) == III_PR_PARTITIONED);
}

static void test_partition_and_leader(void) {
    SECTION("§6 partition + §1.4 leader rotation");
    iii_pl_runtime_t *rt = iii_pl_runtime_create();
    uint8_t fp[32]; memset(fp, 0x77, 32);
    iii_pl_admission_cost_t c;
    for (unsigned i = 0; i < 8; ++i) {
        fp[31] = (uint8_t)i;
        make_admission(&c, fp);
        iii_pl_register_peer(rt, &c, fp, 0, 0, 0);
    }
    iii_pl_rotate_leaders(rt, 1);
    TEST(iii_pl_leader_count(rt, III_PL_CELL) > 0);

    iii_pl_set_partitioned(rt, true, 2);
    TEST(iii_pl_partition_state(rt)->partitioned);
    iii_pl_set_partitioned(rt, false, 0);
    TEST(!iii_pl_partition_state(rt)->partitioned);
    iii_pl_runtime_destroy(rt);
}

int main(void) {
    test_admission();
    test_register();
    test_attacks();
    test_quarantine();
    test_multipath();
    test_reconcile();
    test_partition_and_leader();
    printf("\n=== %d passed, %d failed ===\n", g_pass, g_fail);
    return g_fail == 0 ? 0 : 1;
}
