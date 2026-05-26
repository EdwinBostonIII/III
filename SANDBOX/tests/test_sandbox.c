#include "iii/sandbox.h"
#include <stdio.h>
#include <string.h>

static int g_pass = 0, g_fail = 0;
#define TEST(c) do { if (c) { g_pass++; printf("  PASS %s\n", #c); } \
    else { g_fail++; printf("  FAIL %s @ %s:%d\n", #c, __FILE__, __LINE__); } } while (0)
#define SECTION(s) printf("\n[%s]\n", s)

static void test_lifecycle(void) {
    SECTION("§1 lifecycle");
    iii_sandbox_runtime_t *rt = iii_sandbox_runtime_create();
    iii_sandbox_resource_limits_t lim = { .memory_bytes_max = 1<<20 };
    iii_sandbox_id_t id = iii_sandbox_create(rt, "test", 0, &lim);
    TEST(id != 0);
    const iii_sandbox_descriptor_t *s = iii_sandbox_lookup(rt, id);
    TEST(s != NULL);
    TEST(s->state == III_SBX_CREATED);

    TEST(iii_sandbox_run(rt, id) == III_SBX_OK);
    TEST(s->state == III_SBX_RUNNING);
    TEST(iii_sandbox_run(rt, id) == III_SBX_E_BAD_STATE);  /* already running */

    TEST(iii_sandbox_suspend(rt, id) == III_SBX_OK);
    TEST(s->state == III_SBX_SUSPENDED);

    TEST(iii_sandbox_resume(rt, id) == III_SBX_OK);
    TEST(s->state == III_SBX_RUNNING);

    TEST(iii_sandbox_terminate(rt, id) == III_SBX_OK);
    TEST(s->state == III_SBX_TERMINATED);

    TEST(iii_sandbox_discard(rt, id) == III_SBX_OK);
    TEST(s->state == III_SBX_DISCARDED);

    iii_sandbox_runtime_destroy(rt);
}

static void test_isolation(void) {
    SECTION("§2 isolation");
    iii_sandbox_runtime_t *rt = iii_sandbox_runtime_create();
    iii_sandbox_id_t id = iii_sandbox_create(rt, "iso", 0, NULL);
    const iii_sandbox_descriptor_t *s = iii_sandbox_lookup(rt, id);
    TEST(s->isolation.npt_class != 0);
    TEST(s->isolation.network_mediated);
    TEST(s->isolation.filesystem_virtualised);
    TEST(s->isolation.cap_boundary_sealed);
    iii_sandbox_runtime_destroy(rt);
}

static void test_recursion(void) {
    SECTION("§6 recursion");
    iii_sandbox_runtime_t *rt = iii_sandbox_runtime_create();
    iii_sandbox_id_t parent = iii_sandbox_create(rt, "p", 0, NULL);
    iii_sandbox_id_t cur = parent;
    /* Build a 16-deep chain. */
    for (unsigned i = 0; i < 16; ++i) {
        iii_sandbox_id_t next = iii_sandbox_create(rt, "child", cur, NULL);
        TEST(next != 0);
        cur = next;
    }
    /* 17th level should fail */
    TEST(iii_sandbox_create(rt, "too-deep", cur, NULL) == 0);

    iii_sandbox_runtime_destroy(rt);
}

static void test_snapshot(void) {
    SECTION("§3 snapshot/restore/fork");
    iii_sandbox_runtime_t *rt = iii_sandbox_runtime_create();
    iii_sandbox_id_t id = iii_sandbox_create(rt, "ss", 0, NULL);
    iii_sandbox_run(rt, id);
    uint8_t mem[32], cpu[32], cap[32], file[32], net[32];
    memset(mem,  0x11, 32);
    memset(cpu,  0x22, 32);
    memset(cap,  0x33, 32);
    memset(file, 0x44, 32);
    memset(net,  0x55, 32);
    iii_sandbox_snapshot_id_t sid = 0;
    TEST(iii_sandbox_snapshot(rt, id, mem, cpu, cap, file, net, &sid) == III_SBX_OK);
    TEST(sid == 1);

    /* Restore */
    TEST(iii_sandbox_restore(rt, id, sid) == III_SBX_OK);

    /* Fork */
    iii_sandbox_id_t forked = 0;
    TEST(iii_sandbox_fork(rt, id, sid, &forked) == III_SBX_OK);
    TEST(forked != 0 && forked != id);
    const iii_sandbox_descriptor_t *fs = iii_sandbox_lookup(rt, forked);
    TEST(fs->counterfactual);
    TEST(fs->forked_from == id);

    iii_sandbox_runtime_destroy(rt);
}

static void test_dispatch_and_anchor(void) {
    SECTION("§4 dispatch + anchor");
    iii_sandbox_runtime_t *rt = iii_sandbox_runtime_create();
    iii_sandbox_id_t parent = iii_sandbox_create(rt, "p", 0, NULL);
    iii_sandbox_id_t child  = iii_sandbox_create(rt, "c", parent, NULL);
    iii_sandbox_run(rt, parent);
    iii_sandbox_run(rt, child);

    uint8_t w1[32], w2[32];
    TEST(iii_sandbox_dispatch(rt, child, 0x0011, w1) == III_SBX_OK);
    TEST(iii_sandbox_dispatch(rt, child, 0x0012, w2) == III_SBX_OK);
    TEST(memcmp(w1, w2, 32) != 0);

    /* Anchor child's chain into parent. */
    TEST(iii_sandbox_anchor_audit(rt, child) == III_SBX_OK);

    /* Dispatch in non-running state fails. */
    iii_sandbox_suspend(rt, child);
    TEST(iii_sandbox_dispatch(rt, child, 0x0013, NULL) == III_SBX_E_BAD_STATE);

    iii_sandbox_runtime_destroy(rt);
}

static void test_compromise_propagation(void) {
    SECTION("§5.5 compromise propagation");
    iii_sandbox_runtime_t *rt = iii_sandbox_runtime_create();
    iii_sandbox_id_t parent = iii_sandbox_create(rt, "p", 0, NULL);
    iii_sandbox_id_t child  = iii_sandbox_create(rt, "c", parent, NULL);
    TEST(!iii_sandbox_lookup(rt, parent)->compromise_propagated);
    TEST(iii_sandbox_propagate_compromise(rt, child) == III_SBX_OK);
    TEST(iii_sandbox_lookup(rt, child)->compromise_propagated);
    TEST(iii_sandbox_lookup(rt, parent)->compromise_propagated);
    iii_sandbox_runtime_destroy(rt);
}

int main(void) {
    test_lifecycle();
    test_isolation();
    test_recursion();
    test_snapshot();
    test_dispatch_and_anchor();
    test_compromise_propagation();
    printf("\n=== %d passed, %d failed ===\n", g_pass, g_fail);
    return g_fail == 0 ? 0 : 1;
}
