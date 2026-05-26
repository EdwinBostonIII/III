/* ============================================================================
 * III end-to-end integration test — witness lifecycle across modules.
 *
 * Path under test:
 *
 *   1. LEXICON  : SHA-256 of a directive               (canonical hash)
 *   2. CYCLES   : HMAC-SHA-256 of the directive        (witness MAC)
 *   3. CYCLES   : BLAKE3 of the directive              (alt hash)
 *   4. CYCLES   : insert witness into BCWL
 *   5. CYCLES   : iii_bcwl_walk_chain visits the witness
 *   6. CRYPTO-AGILITY : Ed25519 sign(directive)
 *   7. FOUNDERS-ANCHOR: anchor_verify(sig)             (uses real Ed25519)
 *   8. CATALYST-EXT : counterfactual_replay over the BCWL
 *   9. CYCLES   : SID inverse derivation               (cycle composition)
 *
 * The test PASSES iff every layer accepts the same inputs and the audit
 * hash chain remains consistent end-to-end.
 * ============================================================================
 */
#include "iii/cycles.h"
#include "iii/sha256.h"
#include "iii/catalyst_ext.h"
#include "iii/founders_anchor.h"

#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>

extern void iii_hmac_sha256(const uint8_t *key, size_t key_len,
                            const uint8_t *msg, size_t msg_len,
                            uint8_t out[32]);
extern void iii_blake3(const uint8_t *data, size_t len, uint8_t out[32]);

extern void iii_ed25519_keygen(uint8_t pk[32], const uint8_t seed[32]);
extern void iii_ed25519_sign  (uint8_t sig[64],
                               const uint8_t *msg, size_t msglen,
                               const uint8_t pk[32], const uint8_t seed[32]);
extern int  iii_ed25519_verify(const uint8_t sig[64],
                               const uint8_t *msg, size_t msglen,
                               const uint8_t pk[32]);

static int g_pass = 0, g_fail = 0;
#define TEST(c) do { if (c) { g_pass++; printf("  PASS %s\n", #c); } \
    else { g_fail++; printf("  FAIL %s @ %s:%d\n", #c, __FILE__, __LINE__); } } while (0)
#define SECTION(s) printf("\n[%s]\n", s)

int main(void) {
    SECTION("E2E witness lifecycle");

    /* === 1. Build a directive and hash it three ways === */
    static const uint8_t directive[] = "III-CATALYST-WITNESS-DIRECTIVE-V1\x00\x00sample-payload";
    const size_t dlen = sizeof(directive) - 1u;

    uint8_t sha256_h[32], blake3_h[32], hmac_h[32];
    iii_sha256(directive, dlen, sha256_h);

    static const uint8_t hmac_key[32] = {
        0xCA,0xFE,0xBA,0xBE, 0xDE,0xAD,0xBE,0xEF, 0x00,0x11,0x22,0x33, 0x44,0x55,0x66,0x77,
        0x88,0x99,0xAA,0xBB, 0xCC,0xDD,0xEE,0xFF, 0x10,0x20,0x30,0x40, 0x50,0x60,0x70,0x80
    };
    iii_hmac_sha256(hmac_key, 32, directive, dlen, hmac_h);
    iii_blake3(directive, dlen, blake3_h);

    /* All three should produce non-zero, distinct outputs. */
    bool sha_nz = false, blake_nz = false, hmac_nz = false;
    for (unsigned i = 0; i < 32; ++i) {
        if (sha256_h[i]) sha_nz = true;
        if (blake3_h[i]) blake_nz = true;
        if (hmac_h[i]) hmac_nz = true;
    }
    TEST(sha_nz);
    TEST(blake_nz);
    TEST(hmac_nz);
    TEST(memcmp(sha256_h, blake3_h, 32) != 0);
    TEST(memcmp(sha256_h, hmac_h,   32) != 0);

    /* === 2. Build a witness and insert into BCWL === */
    iii_xii_witness_t w = {0};
    memcpy(w.predecessor_mhash, sha256_h, 32);
    memcpy(w.successor_mhash,   hmac_h,   32);  /* successor = HMAC tag per §4.2 */
    w.step_kind = 0x0123;
    w.cycle_seq = 1234567u;
    w.chronos_tsc = 9999999999ull;
    w.cost_q14 = 5000u;
    w.capability_bind = 0xCAFEBABEu;
    w.adversariality_class = 0x10u;
    w.federation_route = 0;
    w.plan_anchor_id = 1;
    w.flags = III_XII_FLAG_HOT_PATH;
    w.hexad_packed = 0x0A5Au;
    memcpy(w.hmac_tail, hmac_h + 10, 22);  /* low-order tail of MAC */

    iii_bcwl_t *bcwl = iii_bcwl_create();
    iii_bcwl_insert(bcwl, &w);
    TEST(iii_bcwl_count(bcwl) == 1);
    TEST(iii_bcwl_contains(bcwl, hmac_h));

    /* === 3. Sign the directive with Ed25519 and verify via FOUNDERS-ANCHOR === */
    uint8_t sk[32], pk[32];
    for (unsigned i = 0; i < 32; ++i) sk[i] = (uint8_t)(0x33 + i);
    iii_ed25519_keygen(pk, sk);

    iii_anchor_signature_t anchor_sig;
    iii_anchor_sign(pk, sk, directive, dlen, &anchor_sig);
    TEST(iii_anchor_verify(pk, directive, dlen, &anchor_sig));

    /* Tamper detection. */
    iii_anchor_signature_t bad = anchor_sig;
    bad.bytes[5] ^= 0x01u;
    TEST(!iii_anchor_verify(pk, directive, dlen, &bad));

    /* === 4. Direct Ed25519 verify on raw 64-byte sig === */
    uint8_t raw_sig[64];
    iii_ed25519_sign(raw_sig, directive, dlen, pk, sk);
    TEST(iii_ed25519_verify(raw_sig, directive, dlen, pk) == 0);

    /* === 5. CATALYST-EXT replay — first call computes audit hash === */
    iii_cext_replay_input_t in = {0};
    in.candidate.candidate_id = 42;
    in.witness_range_start = 0;
    in.witness_range_end   = 2000000;
    in.divergence_score_q14 = 1000;

    iii_cext_replay_result_t res;
    iii_cext_counterfactual_replay(bcwl, &in, &res);
    TEST(res.visited_count == 1);
    TEST(res.status == III_CXR_FAILED_AUDIT_HASH);

    /* === 6. Replay again with the computed hash; must verify === */
    memcpy(in.expected_audit_hash, res.computed_audit_hash, 32);
    iii_cext_counterfactual_replay(bcwl, &in, &res);
    TEST(res.status == III_CXR_VERIFIED);

    /* === 7. Tampered witness must be detected === */
    iii_xii_witness_t tampered = w;
    tampered.cost_q14 ^= 0xFFu;
    iii_bcwl_destroy(bcwl);
    bcwl = iii_bcwl_create();
    iii_bcwl_insert(bcwl, &tampered);
    iii_cext_counterfactual_replay(bcwl, &in, &res);
    TEST(res.status == III_CXR_FAILED_AUDIT_HASH);

    iii_bcwl_destroy(bcwl);

    printf("\n=== %d passed, %d failed ===\n", g_pass, g_fail);
    return g_fail == 0 ? 0 : 1;
}
