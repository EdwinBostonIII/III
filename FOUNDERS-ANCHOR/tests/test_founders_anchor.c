#include "iii/founders_anchor.h"
#include <stdio.h>
#include <string.h>

extern void iii_ed25519_keygen(uint8_t pk[32], const uint8_t seed[32]);

/* Fixed test seed for the Founder Anchor.  Sign tests derive pk via keygen. */
static void make_anchor_keypair(uint8_t pk[32], uint8_t sk[32]) {
    for (unsigned i = 0; i < 32; ++i) sk[i] = (uint8_t)(0x11 + i);
    iii_ed25519_keygen(pk, sk);
}

static int g_pass = 0, g_fail = 0;
#define TEST(c) do { if (c) { g_pass++; printf("  PASS %s\n", #c); } \
    else { g_fail++; printf("  FAIL %s @ %s:%d\n", #c, __FILE__, __LINE__); } } while (0)
#define SECTION(s) printf("\n[%s]\n", s)

static void test_identity(void) {
    SECTION("§1 identity");
    iii_anchor_identity_t id;
    memset(&id, 0, sizeof(id));
    memcpy(id.public_key, III_FOUNDERS_ANCHOR_PUBLIC_KEY_DEFAULT, 32);
    iii_anchor_compute_fingerprint(id.public_key, id.fingerprint);
    bool any = false;
    for (unsigned i = 0; i < 32; ++i) if (id.fingerprint[i]) { any = true; break; }
    TEST(any);
}

static void test_sign_verify(void) {
    SECTION("§2 sign/verify");
    uint8_t pk[32], sk[32]; make_anchor_keypair(pk, sk);
    const uint8_t directive[] = "III-FOUNDERS-DRTM-RESET-V1...";
    iii_anchor_signature_t sig;
    iii_anchor_sign(pk, sk, directive, sizeof(directive)-1, &sig);
    TEST(iii_anchor_verify(pk, directive, sizeof(directive)-1, &sig));

    /* Tampered signature */
    iii_anchor_signature_t bad = sig;
    bad.bytes[0] ^= 1;
    TEST(!iii_anchor_verify(pk, directive, sizeof(directive)-1, &bad));
}

static void test_amend(void) {
    SECTION("§2.1 tier-3 amendment");
    uint8_t pk[32], sk[32]; make_anchor_keypair(pk, sk);
    iii_anchor_identity_t id;
    memset(&id, 0, sizeof(id));
    memcpy(id.public_key, pk, 32);

    iii_anchor_amendment_t am;
    memset(&am, 0, sizeof(am));
    memset(am.target_mhash,    0xAA, 32);
    memset(am.new_value_mhash, 0xBB, 32);
    am.federation_quorum_count = 100;
    am.federation_unanimous = true;

    /* No signature → reject */
    TEST(iii_anchor_amend_apply(&id, &am) == III_AMEND_REJECT_FNDR_VETO_MISSING);

    /* Sign properly */
    uint8_t directive[64];
    memcpy(directive, am.target_mhash, 32);
    memcpy(directive+32, am.new_value_mhash, 32);
    iii_anchor_sign(pk, sk, directive, sizeof(directive), &am.anchor_signature);
    TEST(iii_anchor_amend_apply(&id, &am) == III_AMEND_OK);

    /* No quorum → reject */
    am.federation_unanimous = false;
    TEST(iii_anchor_amend_apply(&id, &am) == III_AMEND_REJECT_NO_QUORUM);
}

static void test_drtm_reset(void) {
    SECTION("§2.2 drtm reset");
    uint8_t pk[32], sk[32]; make_anchor_keypair(pk, sk);
    iii_anchor_identity_t id; memset(&id, 0, sizeof(id));
    memcpy(id.public_key, pk, 32);

    iii_anchor_drtm_reset_t rst;
    memset(&rst, 0, sizeof(rst));
    memset(rst.nonce, 0xCD, 32);
    rst.timestamp = 1000;
    rst.reason_code = 42;

    /* Reconstruct directive */
    uint8_t directive[26 + 32 + 8 + 4];
    memcpy(directive, "III-FOUNDERS-DRTM-RESET-V1", 26);
    memcpy(directive + 26, rst.nonce, 32);
    for (unsigned i = 0; i < 8; ++i) directive[58 + i] = (uint8_t)(rst.timestamp >> (i*8));
    for (unsigned i = 0; i < 4; ++i) directive[66 + i] = (uint8_t)(rst.reason_code >> (i*8));
    iii_anchor_sign(pk, sk, directive, sizeof(directive), &rst.signature);
    TEST(iii_anchor_drtm_reset_verify(&id, &rst));
}

static void test_pfs_deny(void) {
    SECTION("§2.3 pfs_deny");
    uint8_t pk[32], sk[32]; make_anchor_keypair(pk, sk);
    iii_anchor_identity_t id; memset(&id, 0, sizeof(id));
    memcpy(id.public_key, pk, 32);

    iii_anchor_pfs_deny_t deny;
    memset(&deny, 0, sizeof(deny));
    deny.target_kind = III_PFS_DT_PEER;
    deny.target_id = 0x1234;
    deny.reason = III_PFS_DR_COMPROMISED;

    uint8_t directive[24 + 1 + 8 + 1];
    memcpy(directive, "III-FOUNDERS-PFS-DENY-V1", 24);
    directive[24] = (uint8_t)deny.target_kind;
    for (unsigned i = 0; i < 8; ++i) directive[25 + i] = (uint8_t)(deny.target_id >> (i*8));
    directive[33] = (uint8_t)deny.reason;
    iii_anchor_sign(pk, sk, directive, sizeof(directive), &deny.signature);
    TEST(iii_anchor_pfs_deny_verify(&id, &deny));
}

static void test_invariant(void) {
    SECTION("§4 invariant check");
    iii_anchor_invariant_check_t ok = {0};
    TEST(iii_anchor_invariant_holds(&ok));
    iii_anchor_invariant_check_t bad = {0};
    bad.attempts_modify_pubkey = true;
    TEST(!iii_anchor_invariant_holds(&bad));
}

static void test_shamir(void) {
    SECTION("§6 Shamir 2-of-3");
    uint8_t secret[32]; for (unsigned i = 0; i < 32; ++i) secret[i] = (uint8_t)(0xA0 + i);
    iii_anchor_share_t shares[5];
    TEST(iii_anchor_shamir_split(secret, 3, 2, shares, 5));

    /* Reconstruct from shares 1+2. */
    uint8_t out[32];
    iii_anchor_share_t pick[2] = { shares[0], shares[1] };
    TEST(iii_anchor_shamir_reconstruct(pick, 2, out));
    TEST(memcmp(out, secret, 32) == 0);

    /* From shares 1+3 */
    pick[1] = shares[2];
    TEST(iii_anchor_shamir_reconstruct(pick, 2, out));
    TEST(memcmp(out, secret, 32) == 0);

    /* From shares 2+3 */
    pick[0] = shares[1]; pick[1] = shares[2];
    TEST(iii_anchor_shamir_reconstruct(pick, 2, out));
    TEST(memcmp(out, secret, 32) == 0);

    /* Insufficient (1 share) — for threshold-2 we need 2 to reconstruct.
     * With only 1 share we'd get garbage. */
    iii_anchor_share_t one[1] = { shares[0] };
    iii_anchor_shamir_reconstruct(one, 1, out);
    TEST(memcmp(out, secret, 32) != 0);
}

static void test_runtime_halt(void) {
    SECTION("§2.6 catalyst halt runtime");
    uint8_t pk[32], sk[32]; make_anchor_keypair(pk, sk);
    iii_anchor_identity_t id; memset(&id, 0, sizeof(id));
    memcpy(id.public_key, pk, 32);

    iii_anchor_runtime_t *rt = iii_anchor_runtime_create(&id);
    TEST(!iii_anchor_runtime_is_catalyst_halted(rt, 1000));

    iii_anchor_catalyst_halt_t halt;
    memset(&halt, 0, sizeof(halt));
    halt.halt_until = UINT64_MAX;
    uint8_t directive[31 + 8];
    memcpy(directive, "III-FOUNDERS-CATALYST-HALT-V1", 29);
    for (unsigned i = 0; i < 8; ++i) directive[29 + i] = (uint8_t)(halt.halt_until >> (i*8));
    iii_anchor_sign(pk, sk, directive, 29 + 8, &halt.signature);
    TEST(iii_anchor_runtime_apply_halt(rt, &halt));
    TEST(iii_anchor_runtime_is_catalyst_halted(rt, 1000));
    TEST(iii_anchor_runtime_is_catalyst_halted(rt, UINT64_MAX - 1));

    /* Resume */
    iii_anchor_signature_t resume_sig;
    iii_anchor_sign(pk, sk, (const uint8_t *)"III-FOUNDERS-CATALYST-RESUME-V1", 31, &resume_sig);
    TEST(iii_anchor_runtime_resume(rt, &resume_sig));
    TEST(!iii_anchor_runtime_is_catalyst_halted(rt, 1000));

    iii_anchor_runtime_destroy(rt);
}

int main(void) {
    test_identity();
    test_sign_verify();
    test_amend();
    test_drtm_reset();
    test_pfs_deny();
    test_invariant();
    test_shamir();
    test_runtime_halt();
    printf("\n=== %d passed, %d failed ===\n", g_pass, g_fail);
    return g_fail == 0 ? 0 : 1;
}
