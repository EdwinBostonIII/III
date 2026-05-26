#include "iii/performance.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

static int g_pass = 0, g_fail = 0;
#define TEST(c) do { if (c) { g_pass++; printf("  PASS %s\n", #c); } \
    else { g_fail++; printf("  FAIL %s @ %s:%d\n", #c, __FILE__, __LINE__); } } while (0)
#define SECTION(s) printf("\n[%s]\n", s)

static void test_hw(void) {
    SECTION("§17 hw features + dispatch");
    iii_hwfeatures_t h = {0};
    h.sha_ni = true;
    h.avx512_bw = true;
    h.avx2 = true;
    iii_hw_override(&h);

    iii_dispatch_t d;
    iii_hw_dispatch_init(&d);
    TEST(d.sha256_path == III_PATH_SHA_NI);
    TEST(d.blake3_path == III_PATH_AVX512);
    TEST(d.hmac_simd_lanes == 8);

    /* Software fallback */
    memset(&h, 0, sizeof(h));
    iii_hw_override(&h);
    iii_hw_dispatch_init(&d);
    TEST(d.sha256_path == III_PATH_SOFTWARE);
    TEST(d.hmac_simd_lanes == 1);
}

static void test_scba(void) {
    SECTION("§3 SCBA");
    iii_scba_t s;
    iii_scba_clear(&s);
    TEST(!iii_scba_test(&s, 7));
    iii_scba_set(&s, 7);
    TEST(iii_scba_test(&s, 7));
    iii_scba_set(&s, 1023);
    TEST(iii_scba_test(&s, 1023));
    iii_scba_unset(&s, 7);
    TEST(!iii_scba_test(&s, 7));

    /* Cache-line alignment hint: at least 64 bytes within the words array */
    TEST(sizeof(iii_scba_t) >= 64);
}

static void test_ring(void) {
    SECTION("§6 ring (SPSC)");
    iii_ring_t *r = iii_ring_create(0, 1);
    TEST(r != NULL);
    TEST(iii_ring_capacity(r) == III_RING_CAP);
    TEST(iii_ring_occupancy(r) == 0);
    TEST(iii_ring_numa_node(r) == 1);

    iii_ring_slot_t slot;
    memset(slot.bytes, 0xAA, sizeof(slot.bytes));
    TEST(iii_ring_try_push(r, &slot));
    TEST(iii_ring_occupancy(r) == 1);

    iii_ring_slot_t out;
    TEST(iii_ring_try_pop(r, &out));
    TEST(out.bytes[0] == 0xAA);

    /* Batch */
    iii_ring_slot_t batch[8];
    for (unsigned i = 0; i < 8; ++i) memset(batch[i].bytes, (uint8_t)i, sizeof(batch[i].bytes));
    TEST(iii_ring_try_push_batch(r, batch, 8) == 8);
    TEST(iii_ring_occupancy(r) == 8);

    /* Saturation pct */
    TEST(iii_ring_occupancy_pct(r) < 75);
    TEST(!iii_ring_is_saturated(r));

    /* Drive to >75% */
    for (unsigned i = 0; i < III_RING_CAP - 8u; ++i) iii_ring_try_push(r, &slot);
    /* Note: push will fill until full; at occupancy 1024/1024 = 100%, saturated. */
    TEST(iii_ring_is_saturated(r));

    iii_ring_destroy(r);
}

static void test_mobius(void) {
    SECTION("§7 Möbius rolling sum");
    iii_mobius_t m;
    iii_mobius_init(&m);
    /* Drive 75% coherence */
    for (unsigned i = 0; i < 1000; ++i) {
        iii_mobius_update(&m, 75, 100);
    }
    uint16_t s = iii_mobius_sample(&m);
    TEST(s > 12000 && s < 12800);  /* roughly 0.75 q14 = 12288 */
}

static void test_hexad_compact(void) {
    SECTION("§8 hexad compact");
    iii_hexad_table_compact_t t;
    memset(&t, 0, sizeof(t));
    TEST(sizeof(t) == 32u);

    iii_hexad_compact_set_admit(&t, 0, true);
    iii_hexad_compact_set_admit(&t, 100, true);
    TEST(iii_hexad_compact_admit(&t, 0));
    TEST(!iii_hexad_compact_admit(&t, 1));
    TEST(iii_hexad_compact_admit(&t, 100));

    iii_hexad_compact_set_composition(&t, 0, 0x2A);
    TEST(iii_hexad_compact_composition(&t, 0) == 0x2A);
}

static void test_hexad_compose(void) {
    SECTION("§16 hexad compose");
    iii_hexad_z3_6_t a = { .component = {1, 2, 0, 0, 1, 2} };
    iii_hexad_z3_6_t b = { .component = {2, 2, 1, 0, 1, 1} };
    iii_hexad_z3_6_t out;
    iii_hexad_z3_6_t arr[2] = {a, b};
    iii_hexad_compose_scalar(arr, 2, &out);
    TEST(out.component[0] == 0);   /* (1+2)%3 */
    TEST(out.component[1] == 1);   /* (2+2)%3 */
    TEST(out.component[2] == 1);   /* (0+1)%3 */
    TEST(out.component[3] == 0);
    TEST(out.component[4] == 2);
    TEST(out.component[5] == 0);
}

static int handler_fn(void *args, void *user) {
    int *p = (int *)args;
    (void)user;
    *p = *p + 100;
    return 0;
}

static void test_dispatch(void) {
    SECTION("§9 cycle dispatch");
    iii_cycle_dispatch_t d;
    iii_cycle_dispatch_init(&d);
    TEST(iii_cycle_dispatch_register(&d, 5, handler_fn, NULL));

    int x = 1;
    TEST(iii_cycle_dispatch_invoke(&d, 5, &x) == 0);
    TEST(x == 101);

    /* Unbound */
    TEST(iii_cycle_dispatch_invoke(&d, 999, &x) == -3);
    /* Out-of-range */
    TEST(iii_cycle_dispatch_invoke(&d, 0xFFFF, &x) == -2);
}

static void test_arena(void) {
    SECTION("§10 arena");
    iii_arena_t *a = iii_arena_create(4096);
    TEST(a != NULL);
    TEST(iii_arena_capacity(a) == 4096);

    void *p1 = iii_arena_acquire(a, 100);
    void *p2 = iii_arena_acquire(a, 100);
    TEST(p1 != NULL && p2 != NULL && p1 != p2);
    TEST(iii_arena_used(a) >= 200);

    /* Bump-pointer reset */
    iii_arena_release(a);
    TEST(iii_arena_used(a) == 0);

    /* OOM */
    TEST(iii_arena_acquire(a, 100000) == NULL);

    iii_arena_destroy(a);
}

static void test_subkey(void) {
    SECTION("§13 subkey");
    iii_subkey_t s;
    memset(&s, 0, sizeof(s));
    uint8_t k[32]; memset(k, 0x44, 32);
    iii_subkey_install(&s, k, 7);
    TEST(s.epoch == 7);
    TEST(s.key[0] == 0x44);
    TEST(s.flags & 1u);

    iii_subkey_invalidate(&s);
    TEST(s.epoch == 0);
    TEST(s.key[0] == 0);

    /* 64-byte cache line alignment */
    TEST(sizeof(s) == 64);
}

static void test_perf(void) {
    SECTION("§18 perf budget");
    iii_perf_t p;
    iii_perf_init(&p);

    /* Within budget */
    iii_perf_record(&p, III_PERF_SCBA_TEST, 3);
    iii_perf_record(&p, III_PERF_HMAC,      400);
    TEST(iii_perf_average(&p, III_PERF_SCBA_TEST) == 3);
    TEST(iii_perf_within_budget(&p));

    /* Over budget */
    iii_perf_record(&p, III_PERF_SCBA_TEST, 100);   /* now avg = (3+100)/2 = 51 */
    TEST(!iii_perf_within_budget(&p));

    TEST(strcmp(iii_perf_stage_name(III_PERF_HMAC), "hmac") == 0);
}

static void test_prewarm(void) {
    SECTION("§5 prewarm");
    iii_prewarm_t pw = {0};
    for (unsigned i = 0; i < 90; ++i) iii_prewarm_record(&pw, true);
    for (unsigned i = 0; i < 10; ++i) iii_prewarm_record(&pw, false);
    uint16_t hr = iii_prewarm_hit_rate_q14(&pw);
    TEST(hr > 13900 && hr < 14800); /* 0.9 * 16384 = 14745 */
}

int main(void) {
    test_hw();
    test_scba();
    test_ring();
    test_mobius();
    test_hexad_compact();
    test_hexad_compose();
    test_dispatch();
    test_arena();
    test_subkey();
    test_perf();
    test_prewarm();
    printf("\n=== %d passed, %d failed ===\n", g_pass, g_fail);
    return g_fail == 0 ? 0 : 1;
}
