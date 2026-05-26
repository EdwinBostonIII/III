/* III-SANCTUM tests */
#include "iii/sanctum.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

static int g_pass = 0, g_fail = 0;
#define TEST(c) do { if (c) { g_pass++; printf("  PASS %s\n", #c); } \
    else { g_fail++; printf("  FAIL %s @ %s:%d\n", #c, __FILE__, __LINE__); } } while (0)
#define SECTION(s) printf("\n[%s]\n", s)

/* Simple body for tests */
static int body_ok(iii_sanctum_runtime_t *rt, const void *in, void *out, void *user) {
    (void)rt; (void)in; (void)out; (void)user;
    return 0;
}

static int body_fail(iii_sanctum_runtime_t *rt, const void *in, void *out, void *user) {
    (void)rt; (void)in; (void)out; (void)user;
    return -1;
}

static void make_request(iii_sanctum_call_request_t *r, iii_sanctum_seal_t seal) {
    memset(r, 0, sizeof(*r));
    r->seal = seal;
    r->intent_valid = true;
    r->cap_valid = true;
    r->causality_valid = true;
    r->sanctum_state_valid = true;
    /* Some intent fields */
    memset(r->intent.operator_consent_mhash, 0xAA, 32);
    r->intent.cap_id = 1;
    r->intent.sanctum_frame_id = 1;
}

static void test_seals_enum(void) {
    SECTION("§1 seal enumeration");
    TEST(XII_SANCTUM_SEAL_COUNT == 10u);
    TEST(III_SEAL_INVALID == 0);
    TEST(III_SEAL_DRTM_RELAUNCH == 1);
    TEST(III_SEAL_COMPILE_MODULE == 9);
    TEST(strcmp(iii_sanctum_seal_name(III_SEAL_INVALID),    "INVALID") == 0);
    TEST(strcmp(iii_sanctum_seal_name(III_SEAL_DRTM_RELAUNCH), "drtm_relaunch") == 0);
    TEST(strcmp(iii_sanctum_seal_name(III_SEAL_COMPILE_MODULE), "compile_module") == 0);
}

static void test_box_steps(void) {
    SECTION("§2 box steps");
    TEST(III_BOX_STEP_COUNT == 9u);
    TEST(strcmp(iii_sanctum_box_step_name(III_BOX_STEP_TRAMPOLINE), "04-trampoline") == 0);
}

static void test_trinity(void) {
    SECTION("§3 Trinity admit");
    iii_trinity_admit_in_t  in;
    iii_trinity_admit_out_t out;
    memset(&in, 0, sizeof(in));
    in.intent_valid = true;
    in.cap_valid = true;
    in.causality_valid = true;
    in.sanctum_state_valid = true;
    iii_trinity_admit(&in, &out);
    TEST(out.admitted);
    TEST(out.convergence_point != 0);

    /* Negative — any rejected conjunct */
    in.cap_valid = false;
    iii_trinity_admit(&in, &out);
    TEST(!out.admitted);
    TEST(out.rejected_cap);
}

static void test_bind_dispatch(void) {
    SECTION("§2 bind + dispatch");
    iii_sanctum_runtime_t *rt = iii_sanctum_runtime_create();
    TEST(rt != NULL);

    /* Cannot bind slot 0 */
    TEST(!iii_sanctum_runtime_bind_seal(rt, III_SEAL_INVALID, body_ok, NULL));

    /* Bind slot 1 (DRTM relaunch) — body just succeeds */
    TEST(iii_sanctum_runtime_bind_seal(rt, III_SEAL_DRTM_RELAUNCH, body_ok, NULL));

    /* Cannot rebind */
    TEST(!iii_sanctum_runtime_bind_seal(rt, III_SEAL_DRTM_RELAUNCH, body_ok, NULL));

    /* Dispatch with valid Trinity */
    iii_sanctum_call_request_t req;
    iii_sanctum_call_trace_t   trace;
    make_request(&req, III_SEAL_DRTM_RELAUNCH);
    TEST(iii_sanctum_call(rt, &req, &trace) == III_SANCTUM_OK);
    TEST(trace.executed[III_BOX_STEP_INTENT_MINT]);
    TEST(trace.executed[III_BOX_STEP_TRAMPOLINE]);
    TEST(trace.executed[III_BOX_STEP_PKRU_REWRITE]);
    TEST(trace.executed[III_BOX_STEP_DISPATCH]);
    TEST(trace.executed[III_BOX_STEP_BODY]);
    TEST(trace.executed[III_BOX_STEP_EXIT]);
    TEST(trace.hardening.ibpb_executed);
    TEST(trace.hardening.verw_executed);
    TEST(trace.hardening.ssbd_executed);
    TEST(trace.hardening.rsp_swapped);
    TEST(trace.hardening.gpr_saved);
    TEST(trace.trinity.admitted);

    /* Dispatch to slot 0 → rejected */
    make_request(&req, III_SEAL_INVALID);
    TEST(iii_sanctum_call(rt, &req, &trace) == III_SANCTUM_E_INVALID_SEAL);

    /* Dispatch to unbound slot → rejected */
    make_request(&req, III_SEAL_PFS_VAR_SET);
    TEST(iii_sanctum_call(rt, &req, &trace) == III_SANCTUM_E_NOT_BOUND);

    /* Trinity reject */
    iii_sanctum_runtime_bind_seal(rt, III_SEAL_PFS_VAR_SET, body_ok, NULL);
    make_request(&req, III_SEAL_PFS_VAR_SET);
    req.cap_valid = false;
    TEST(iii_sanctum_call(rt, &req, &trace) == III_SANCTUM_E_TRINITY_REJECT);
    TEST(trace.executed[III_BOX_STEP_INTENT_MINT]); /* steps 1-3 still ran */
    TEST(!trace.executed[III_BOX_STEP_TRAMPOLINE]); /* step 4 onward did not */

    /* Body failure */
    iii_sanctum_runtime_bind_seal(rt, III_SEAL_PFS_DENY_QUOTE, body_fail, NULL);
    make_request(&req, III_SEAL_PFS_DENY_QUOTE);
    TEST(iii_sanctum_call(rt, &req, &trace) == III_SANCTUM_E_BODY_FAILED);

    iii_sanctum_runtime_destroy(rt);
}

static void test_drtm(void) {
    SECTION("§4 DRTM relaunch");
    iii_sanctum_runtime_t *rt = iii_sanctum_runtime_create();

    iii_drtm_quote_t q1, q2;
    TEST(iii_sanctum_drtm_relaunch(rt, false, &q1) == III_SANCTUM_OK);
    TEST(q1.epoch == 1);
    TEST(iii_sanctum_runtime_epoch(rt) == 1);
    TEST(iii_sanctum_runtime_quote_count(rt) == 1);

    TEST(iii_sanctum_drtm_relaunch(rt, false, &q2) == III_SANCTUM_OK);
    TEST(q2.epoch == 2);
    /* q2 chains to q1 */
    uint8_t zero[32] = {0};
    TEST(memcmp(q1.prior_quote_mhash, zero, 32) == 0); /* first quote — no prior */
    TEST(memcmp(q2.prior_quote_mhash, zero, 32) != 0); /* second has prior */

    /* Quote layout sanity */
    TEST(sizeof(iii_drtm_quote_t) == III_DRTM_QUOTE_BYTES);

    iii_sanctum_runtime_destroy(rt);
}

static void test_pfs(void) {
    SECTION("§5 phantom NVRAM");
    iii_sanctum_runtime_t *rt = iii_sanctum_runtime_create();

    uint8_t v1[] = "hello";
    TEST(iii_sanctum_pfs_set(rt, "k1", v1, sizeof(v1)) == III_SANCTUM_OK);
    TEST(iii_sanctum_runtime_pfs_count(rt) == 1);

    uint8_t out[64]; size_t n;
    TEST(iii_sanctum_pfs_get(rt, "k1", out, sizeof(out), &n) == III_SANCTUM_OK);
    TEST(n == sizeof(v1));
    TEST(memcmp(out, v1, n) == 0);

    /* Update */
    uint8_t v2[] = "world!";
    TEST(iii_sanctum_pfs_set(rt, "k1", v2, sizeof(v2)) == III_SANCTUM_OK);
    TEST(iii_sanctum_runtime_pfs_count(rt) == 1); /* same key */

    TEST(iii_sanctum_pfs_get(rt, "k1", out, sizeof(out), &n) == III_SANCTUM_OK);
    TEST(memcmp(out, v2, n) == 0);

    /* Deny */
    TEST(iii_sanctum_pfs_deny(rt, "k1") == III_SANCTUM_OK);
    TEST(iii_sanctum_pfs_get(rt, "k1", out, sizeof(out), &n) == III_SANCTUM_E_PFS_DENIED);
    TEST(iii_sanctum_pfs_set(rt, "k1", v1, sizeof(v1)) == III_SANCTUM_E_PFS_DENIED);

    /* Not found */
    TEST(iii_sanctum_pfs_get(rt, "nope", out, sizeof(out), &n) == III_SANCTUM_E_PFS_NOT_FOUND);

    iii_sanctum_runtime_destroy(rt);
}

static void test_phoenix(void) {
    SECTION("§5 Phoenix bookmarks");
    iii_sanctum_runtime_t *rt = iii_sanctum_runtime_create();
    uint8_t payload[] = "session-state-snapshot";
    uint64_t id = 0;
    TEST(iii_sanctum_phoenix_save(rt, false, payload, sizeof(payload), &id) == III_SANCTUM_OK);
    TEST(id == 1);
    TEST(iii_sanctum_runtime_phoenix_count(rt) == 1);

    iii_phoenix_bookmark_t b;
    TEST(iii_sanctum_phoenix_restore(rt, id, &b) == III_SANCTUM_OK);
    TEST(b.bookmark_id == id);
    TEST(b.payload_len == sizeof(payload));
    TEST(!b.emergency);
    TEST(memcmp(b.payload, payload, sizeof(payload)) == 0);

    /* Emergency */
    uint64_t id2 = 0;
    TEST(iii_sanctum_phoenix_save(rt, true, payload, sizeof(payload), &id2) == III_SANCTUM_OK);
    iii_sanctum_phoenix_restore(rt, id2, &b);
    TEST(b.emergency);

    iii_sanctum_runtime_destroy(rt);
}

static void test_crcc(void) {
    SECTION("§1 slot 4 CRCC");
    iii_sanctum_runtime_t *rt = iii_sanctum_runtime_create();
    uint8_t k1[32], k2[32], k1b[32];
    TEST(iii_sanctum_crcc_export(rt, 1, k1) == III_SANCTUM_OK);
    TEST(iii_sanctum_crcc_export(rt, 2, k2) == III_SANCTUM_OK);
    TEST(memcmp(k1, k2, 32) != 0);
    TEST(iii_sanctum_crcc_export(rt, 1, k1b) == III_SANCTUM_OK);
    TEST(memcmp(k1, k1b, 32) == 0);
    iii_sanctum_runtime_destroy(rt);
}

static void test_chronos(void) {
    SECTION("§1 slot 6 chronos");
    iii_sanctum_runtime_t *rt = iii_sanctum_runtime_create();
    TEST(iii_sanctum_runtime_epoch(rt) == 0);
    TEST(iii_sanctum_chronos_advance(rt) == III_SANCTUM_OK);
    TEST(iii_sanctum_runtime_epoch(rt) == 1);
    iii_sanctum_runtime_destroy(rt);
}

static void test_compromise_quote(void) {
    SECTION("§1 slot 7 compromise quote");
    iii_sanctum_runtime_t *rt = iii_sanctum_runtime_create();
    uint8_t evidence[] = "anomaly-window-N";
    iii_drtm_quote_t q;
    TEST(iii_sanctum_compromise_quote(rt, 2, evidence, sizeof(evidence), &q) == III_SANCTUM_OK);
    TEST(q.pad[0] == 2);
    TEST(iii_sanctum_compromise_quote(rt, 0, evidence, sizeof(evidence), &q) == III_SANCTUM_E_INVALID);
    TEST(iii_sanctum_compromise_quote(rt, 4, evidence, sizeof(evidence), &q) == III_SANCTUM_E_INVALID);
    iii_sanctum_runtime_destroy(rt);
}

static void test_specialize(void) {
    SECTION("§5.5 specialise");
    iii_sanctum_runtime_t *rt = iii_sanctum_runtime_create();
    iii_sanctum_runtime_bind_seal(rt, III_SEAL_PFS_VAR_SET, body_ok, NULL);
    TEST(iii_sanctum_specialize(rt, III_SEAL_INVALID) == III_SANCTUM_E_INVALID_SEAL);
    TEST(iii_sanctum_specialize(rt, III_SEAL_DRTM_RELAUNCH) == III_SANCTUM_E_NOT_BOUND);
    TEST(iii_sanctum_specialize(rt, III_SEAL_PFS_VAR_SET) == III_SANCTUM_OK);
    TEST(iii_sanctum_is_specialized(rt, III_SEAL_PFS_VAR_SET));

    iii_sanctum_call_request_t req;
    iii_sanctum_call_trace_t   trace;
    make_request(&req, III_SEAL_PFS_VAR_SET);
    iii_sanctum_call(rt, &req, &trace);
    TEST(trace.specialized_path);

    TEST(iii_sanctum_despecialize(rt, III_SEAL_PFS_VAR_SET) == III_SANCTUM_OK);
    TEST(!iii_sanctum_is_specialized(rt, III_SEAL_PFS_VAR_SET));
    iii_sanctum_runtime_destroy(rt);
}

int main(void) {
    test_seals_enum();
    test_box_steps();
    test_trinity();
    test_bind_dispatch();
    test_drtm();
    test_pfs();
    test_phoenix();
    test_crcc();
    test_chronos();
    test_compromise_quote();
    test_specialize();
    printf("\n=== %d passed, %d failed ===\n", g_pass, g_fail);
    return g_fail == 0 ? 0 : 1;
}
