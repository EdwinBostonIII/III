#include "iii/sovereign_web.h"
#include <stdio.h>
#include <string.h>

static int g_pass = 0, g_fail = 0;
#define TEST(c) do { if (c) { g_pass++; printf("  PASS %s\n", #c); } \
    else { g_fail++; printf("  FAIL %s @ %s:%d\n", #c, __FILE__, __LINE__); } } while (0)
#define SECTION(s) printf("\n[%s]\n", s)

static void test_witness_option(void) {
    SECTION("§2 witness option");
    uint8_t mh[32]; for (unsigned i = 0; i < 32; ++i) mh[i] = (uint8_t)i;
    iii_net_witness_option_t opt;
    iii_net_witness_option_build(mh, &opt);
    TEST(opt.option_type == III_WIT_IPV4_OPT_TYPE);
    TEST(opt.option_len == 35u);
    TEST(memcmp(opt.witness_mhash, mh, 32) == 0);
    TEST(iii_net_should_consume(&opt));

    iii_net_witness_option_t bad = {0};
    bad.option_type = 0x42;
    TEST(!iii_net_should_consume(&bad));
}

static void test_ah(void) {
    SECTION("§3 AH HMAC + verify");
    uint8_t key[32]; for (unsigned i = 0; i < 32; ++i) key[i] = (uint8_t)(i + 0x40);

    iii_net_packet_t pkt = {0};
    pkt.ipver = III_NET_IPV4;
    pkt.source_peer_id = 1;
    pkt.destination_peer_id = 2;
    pkt.timestamp = 0xDEADBEEF;
    for (unsigned i = 0; i < 32; ++i) pkt.body_mhash[i] = (uint8_t)(0x80 + i);

    const uint8_t body[16] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16};
    iii_net_ah_trailer_t ah;
    iii_net_ah_compute(key, III_SUITE_PRE_QUANTUM, &pkt, body, sizeof(body), 1, &ah);

    /* Must verify. */
    TEST(iii_net_ah_verify(key, &pkt, body, sizeof(body), &ah));

    /* Wrong key fails */
    uint8_t bad_key[32]; memset(bad_key, 0xFF, 32);
    TEST(!iii_net_ah_verify(bad_key, &pkt, body, sizeof(body), &ah));

    /* Tampered body fails */
    uint8_t tamper[16]; memcpy(tamper, body, 16); tamper[0]++;
    TEST(!iii_net_ah_verify(key, &pkt, tamper, sizeof(tamper), &ah));
}

static void test_replay(void) {
    SECTION("§3.4 replay protection");
    iii_net_replay_window_t w;
    iii_net_replay_init(&w, 1, 2);
    /* Forward sequence */
    TEST(iii_net_replay_admit(&w, 100));
    /* Re-emit same → reject */
    TEST(!iii_net_replay_admit(&w, 100));
    /* Out-of-window old → reject */
    TEST(!iii_net_replay_admit(&w, 0));
    /* Older but in-window → admit (and then reject duplicate) */
    TEST(iii_net_replay_admit(&w, 99));
    TEST(!iii_net_replay_admit(&w, 99));
    /* Newer → admit */
    TEST(iii_net_replay_admit(&w, 200));
}

static void test_outbound_inbound(void) {
    SECTION("§5/§1.5 outbound/inbound");
    iii_net_runtime_t *rt = iii_net_runtime_create(0);
    uint8_t key[32]; for (unsigned i = 0; i < 32; ++i) key[i] = (uint8_t)(0xA0 + i);
    uint64_t pid = iii_net_register_peer_v4(rt, 0x0A0A0A01u, 7777u, key);
    TEST(pid != 0);

    iii_net_packet_t pkt = {0};
    pkt.ipver = III_NET_IPV4;
    pkt.source_peer_id = 100;
    pkt.destination_peer_id = pid;
    pkt.tier = 2;
    pkt.timestamp = 1234;
    for (unsigned i = 0; i < 32; ++i) pkt.body_mhash[i] = (uint8_t)i;

    const uint8_t body[8] = {0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF, 0x11, 0x22};
    uint8_t outbuf[256];
    size_t outlen = 0;
    TEST(iii_net_outbound(rt, pid, &pkt, body, 8, III_SUITE_PRE_QUANTUM, 1,
                          outbuf, sizeof(outbuf), &outlen) == III_NET_OB_OK);
    TEST(outlen > 8);

    /* Tier-0 → reject */
    pkt.tier = 0;
    TEST(iii_net_outbound(rt, pid, &pkt, body, 8, III_SUITE_PRE_QUANTUM, 1,
                          outbuf, sizeof(outbuf), &outlen) == III_NET_OB_REJECT_TIER0);

    /* Inbound: register a "source" peer with the same key, then verify. */
    pkt.tier = 2;
    iii_net_witness_option_t opt;
    memcpy(&opt, outbuf, sizeof(opt));
    iii_net_ah_trailer_t ah;
    memcpy(&ah, outbuf + sizeof(opt) + 8, sizeof(ah));

    /* The runtime needs the source peer to verify; register it. */
    uint64_t src_pid = iii_net_register_peer_v4(rt, 0x0A0A0A02u, 7777u, key);
    iii_net_packet_t inbound_pkt = pkt;
    inbound_pkt.source_peer_id = pkt.source_peer_id;
    inbound_pkt.destination_peer_id = pkt.destination_peer_id;

    TEST(iii_net_inbound(rt, src_pid, &inbound_pkt, body, 8, &opt, &ah) == III_NET_IB_VALID);
    /* Replay → reject */
    TEST(iii_net_inbound(rt, src_pid, &inbound_pkt, body, 8, &opt, &ah) == III_NET_IB_REPLAY);

    iii_net_runtime_destroy(rt);
}

static void test_replicate(void) {
    SECTION("§6 cross-peer replication");
    iii_net_runtime_t *rt = iii_net_runtime_create(0);
    uint8_t key[32] = {0xAA};
    uint64_t pid = iii_net_register_peer_v4(rt, 0x0A0A0A03u, 7777u, key);
    TEST(iii_net_replicate(rt, pid, 100));
    TEST(iii_net_replicate(rt, pid, 200));
    TEST(!iii_net_replicate(rt, pid, 200));   /* same seq */
    TEST(!iii_net_replicate(rt, pid, 50));    /* old */
    iii_net_runtime_destroy(rt);
}

int main(void) {
    test_witness_option();
    test_ah();
    test_replay();
    test_outbound_inbound();
    test_replicate();
    printf("\n=== %d passed, %d failed ===\n", g_pass, g_fail);
    return g_fail == 0 ? 0 : 1;
}
