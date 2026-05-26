/* ============================================================================
 * III-CYCLES — test_cycles.c
 *
 * Tests every public-API surface, including:
 *   §3 SID 32-step plan over a known input
 *   §4 128-byte witness emission, layout, chain-head update
 *   §4.3 BCWL Bloom presence / step-kind walk / chain replay
 *   §4.4 HKDF-derived sub-key
 *   §5 cycle table register / lookup / invariants
 *   §5.3 step_kind band lookup
 *   §6 Catalyst supersedure + rate cap
 *   §8 wavefront composition + admit
 *   crypto: SHA-256 / HMAC / HKDF / BLAKE3 against test vectors
 * ============================================================================
 */
#include "iii/cycles.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>

void iii_sha256(const void *data, size_t len, uint8_t out[32]);
void iii_hmac_sha256(const uint8_t *key, size_t key_len,
                     const uint8_t *msg, size_t msg_len,
                     uint8_t        out[32]);
void iii_hkdf_sha256(const uint8_t *ikm,  size_t ikm_len,
                     const uint8_t *salt, size_t salt_len,
                     const uint8_t *info, size_t info_len,
                     uint8_t       *okm,  size_t okm_len);
void iii_blake3(const uint8_t *data, size_t len, uint8_t out[32]);

static int g_pass = 0, g_fail = 0;

#define TEST(c) do { if (c) { g_pass++; printf("  PASS %s\n", #c); } \
    else { g_fail++; printf("  FAIL %s @ %s:%d\n", #c, __FILE__, __LINE__); } } while (0)
#define SECTION(s) printf("\n[%s]\n", s)

static int hex_eq(const uint8_t hash[], size_t n, const char *hex) {
    static const char *digits = "0123456789abcdef";
    for (size_t i = 0; i < n; ++i) {
        if (hex[2*i + 0] != digits[hash[i] >> 4])  return 0;
        if (hex[2*i + 1] != digits[hash[i] & 0xF]) return 0;
    }
    return 1;
}

/* ----------------------------------------------------------------------------
 * Crypto
 * ---------------------------------------------------------------------------- */

static void test_crypto(void) {
    SECTION("crypto");

    uint8_t h[32];

    /* SHA-256 */
    iii_sha256("", 0, h);
    TEST(hex_eq(h, 32, "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"));
    iii_sha256("abc", 3, h);
    TEST(hex_eq(h, 32, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"));

    /* HMAC-SHA-256 (RFC 4231 case 1) */
    uint8_t key1[20];
    memset(key1, 0x0b, sizeof(key1));
    iii_hmac_sha256(key1, sizeof(key1), (const uint8_t *)"Hi There", 8, h);
    TEST(hex_eq(h, 32, "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7"));

    /* HKDF-SHA-256 (RFC 5869 test case 1, 42-byte output) */
    uint8_t ikm[22], salt[13], info[10];
    for (unsigned i = 0; i < 22; ++i) ikm[i]  = 0x0bu;
    for (unsigned i = 0; i < 13; ++i) salt[i] = (uint8_t)i;
    for (unsigned i = 0; i < 10; ++i) info[i] = (uint8_t)(0xf0u + i);
    uint8_t okm[42];
    iii_hkdf_sha256(ikm, 22, salt, 13, info, 10, okm, 42);
    TEST(hex_eq(okm, 42,
        "3cb25f25faacd57a90434f64d0362f2a"
        "2d2d0a90cf1a5a4c5db02d56ecc4c5bf"
        "34007208d5b887185865"));

    /* BLAKE3 (empty input — known vector from BLAKE3 spec) */
    iii_blake3((const uint8_t *)"", 0, h);
    TEST(hex_eq(h, 32, "af1349b9f5f9a1a6a0404dea36dcc9499bcb25c9adc112b7cc9a93cae41f3262"));
    /* BLAKE3 of "IETF" (4 bytes) */
    iii_blake3((const uint8_t *)"IETF", 4, h);
    TEST(hex_eq(h, 32, "83a2de1ee6f4e6ab686889248f4ec0cf4cc5709446a682ffd1cbb4d6165181e2"));
}

/* ----------------------------------------------------------------------------
 * §5.3 step_kind band lookup
 * ---------------------------------------------------------------------------- */

static void test_bands(void) {
    SECTION("§5.3 step_kind bands");
    TEST(iii_step_kind_band(0x0001) == III_BAND_RESERVED_BOOT);
    TEST(iii_step_kind_band(0x0011) == III_BAND_IRPD_PRIVILEGED_WRITE);
    TEST(iii_step_kind_band(0x0030) == III_BAND_IRPD_PRIVILEGED_READ);
    TEST(iii_step_kind_band(0x0080) == III_BAND_SANCTUM);
    TEST(iii_step_kind_band(0x0140) == III_BAND_CATALYST);
    TEST(iii_step_kind_band(0x01C8) == III_BAND_MNEME_CATALYST_PROMOTE);
    TEST(iii_step_kind_band(0x01D0) == III_BAND_RESERVED_FUTURE);
    TEST(iii_step_kind_band(0x0200) == III_BAND_UNKNOWN);

    uint16_t lo, hi;
    iii_step_kind_band_range(III_BAND_IRPD_PRIVILEGED_WRITE, &lo, &hi);
    TEST(lo == 0x0010 && hi == 0x002F);
    iii_step_kind_band_range(III_BAND_MNEME_CATALYST_PROMOTE, &lo, &hi);
    TEST(lo == 0x01C7 && hi == 0x01CF);
}

/* ----------------------------------------------------------------------------
 * §3 SID
 * ---------------------------------------------------------------------------- */

static void make_valid_input(iii_sid_input_t *in) {
    memset(in, 0, sizeof(*in));
    snprintf(in->cycle_name, sizeof(in->cycle_name), "%s", "write_msr_efer");
    in->call_count = 1;
    in->calls[0].kind = III_SE_MSR_WRITE;
    in->calls[0].arg_idx = 0xC0000080u; /* MSR_EFER */
    in->calls[0].arg_value = 0xD01u;
    in->calls[0].prior_value = 0xC00u;
    in->calls[0].prior_value_captured = true;
    in->calls[0].per_call_hexad = 0x0001u;

    in->declared_hexad = 0x0001u;
    in->coherence_q14  = 14000u;
    in->coherence_floor_q14 = 0u;
    in->trinity_discharged = true;
    in->ceiling_admitted   = true;
    in->plan_anchor_id     = 0xDEADBEEFu;
    in->phase_set          = 0x02; /* R-1 */
    in->cycle_epoch        = 1;
    in->current_epoch      = 1;
    in->federation_match   = true;
    in->glyphs_resolved    = true;
    in->cap_balanced       = true;
    in->ring_marshalling_available = true;
    in->roundtrip_ok       = true;
    in->constitutional_manifest_ok = true;
    in->waac_ok            = true;
}

static void test_sid(void) {
    SECTION("§3 SID");

    iii_sid_input_t  in;
    iii_sid_output_t out;

    make_valid_input(&in);
    iii_sid_run(&in, &out);
    TEST(out.ok);
    TEST(out.failed_at_step == III_SID_RETURN_TO_TYPECHECKER);
    TEST(out.composed_hexad == 0x0001u);
    TEST(out.pip_kind == III_PIP_STATIC_BYTES);
    TEST(out.allocated_step_kind == 0x0011); /* MSR_WRITE */
    TEST(out.inverse_replay_bitmap == 0x1u);

    /* Negative: raw privileged outside IRPD. */
    make_valid_input(&in);
    in.raw_privileged_outside_irpd = true;
    iii_sid_run(&in, &out);
    TEST(!out.ok);
    TEST(out.error == III_SID_E_PARSE_IRPD_001);

    /* Negative: unknown SE kind. */
    make_valid_input(&in);
    in.calls[0].kind = III_SE_NONE;
    iii_sid_run(&in, &out);
    TEST(!out.ok && out.error == III_SID_E_TYPE_SID_001);

    /* Negative: prior not captured. */
    make_valid_input(&in);
    in.calls[0].prior_value_captured = false;
    iii_sid_run(&in, &out);
    TEST(!out.ok && out.error == III_SID_E_TYPE_SID_002);

    /* Negative: roundtrip fail. */
    make_valid_input(&in);
    in.roundtrip_ok = false;
    iii_sid_run(&in, &out);
    TEST(!out.ok && out.error == III_SID_E_TYPE_SID_004);

    /* Negative: hexad inadmissible (zero bitmap). */
    make_valid_input(&in);
    in.calls[0].per_call_hexad = 0;
    in.declared_hexad = 0;
    iii_sid_run(&in, &out);
    TEST(!out.ok && out.error == III_SID_E_TYPE_HEXAD_002);

    /* Negative: hexad inadmissible (>6 bits). */
    make_valid_input(&in);
    in.calls[0].per_call_hexad = 0x00FF;
    iii_sid_run(&in, &out);
    TEST(!out.ok && out.error == III_SID_E_TYPE_HEXAD_002);

    /* Negative: coherence below floor. */
    make_valid_input(&in);
    in.coherence_q14 = 1000u;
    in.coherence_floor_q14 = 5000u;
    iii_sid_run(&in, &out);
    TEST(!out.ok && out.error == III_SID_E_TYPE_MOB_001);

    /* Negative: trinity undischarged. */
    make_valid_input(&in);
    in.trinity_discharged = false;
    iii_sid_run(&in, &out);
    TEST(!out.ok && out.error == III_SID_E_TYPE_TRIN_001);

    /* Negative: ceiling not admitted. */
    make_valid_input(&in);
    in.ceiling_admitted = false;
    iii_sid_run(&in, &out);
    TEST(!out.ok && out.error == III_SID_E_TYPE_CEIL_001);

    /* Negative: missing plan anchor. */
    make_valid_input(&in);
    in.plan_anchor_id = 0;
    iii_sid_run(&in, &out);
    TEST(!out.ok && out.error == III_SID_E_TYPE_PLAN_001);

    /* Negative: epoch newer than current without bridge. */
    make_valid_input(&in);
    in.cycle_epoch = 5;
    in.current_epoch = 1;
    iii_sid_run(&in, &out);
    TEST(!out.ok && out.error == III_SID_E_TYPE_EPOCH_001);

    /* Negative: ring marshalling unavailable. */
    make_valid_input(&in);
    in.ring_marshalling_available = false;
    iii_sid_run(&in, &out);
    TEST(!out.ok && out.error == III_SID_E_TYPE_RING_001);

    /* Negative: cap unbalanced. */
    make_valid_input(&in);
    in.cap_balanced = false;
    iii_sid_run(&in, &out);
    TEST(!out.ok && out.error == III_SID_E_TYPE_LIN_002);
}

/* ----------------------------------------------------------------------------
 * §4 witness emission
 * ---------------------------------------------------------------------------- */

static void test_witness(void) {
    SECTION("§4 witness");

    iii_witness_emitter_t *e = iii_witness_emitter_create(0);
    TEST(e != NULL);
    TEST(iii_witness_emitter_count(e) == 0u);

    iii_witness_request_t req = {0};
    req.step_kind = 0x0011;       /* MSR_WRITE */
    req.cost_q14  = 100;
    req.plan_anchor_id = 0x1001;
    req.hexad_packed = 0x0001;

    iii_xii_witness_t w1;
    iii_witness_emit(e, &req, &w1);
    TEST(w1.cycle_seq == 1);
    TEST(w1.step_kind == 0x0011);

    /* Predecessor is zero on the first emission. */
    uint8_t zero[32] = {0};
    TEST(memcmp(w1.predecessor_mhash, zero, 32) == 0);
    /* Successor must be non-zero. */
    TEST(memcmp(w1.successor_mhash, zero, 32) != 0);

    iii_xii_witness_t w2;
    iii_witness_emit(e, &req, &w2);
    TEST(w2.cycle_seq == 2);
    /* Chain link: predecessor of w2 == successor of w1. */
    TEST(memcmp(w2.predecessor_mhash, w1.successor_mhash, 32) == 0);
    TEST(memcmp(w2.successor_mhash, w1.successor_mhash, 32) != 0);

    /* Determinism: same inputs to a fresh emitter produce the same chain. */
    iii_witness_emitter_t *e2 = iii_witness_emitter_create(0);
    iii_xii_witness_t w1b, w2b;
    iii_witness_emit(e2, &req, &w1b);
    iii_witness_emit(e2, &req, &w2b);
    TEST(memcmp(w1.successor_mhash, w1b.successor_mhash, 32) == 0);
    TEST(memcmp(w2.successor_mhash, w2b.successor_mhash, 32) == 0);

    /* Different cpu_id → different chain (different sub-key derivation). */
    iii_witness_emitter_t *e3 = iii_witness_emitter_create(99);
    iii_xii_witness_t w1c;
    iii_witness_emit(e3, &req, &w1c);
    TEST(memcmp(w1.successor_mhash, w1c.successor_mhash, 32) != 0);

    /* Inverse emission. */
    iii_xii_witness_t inv;
    iii_witness_emit_inverse(e, &w2, 0x0021, &inv);
    TEST(inv.cycle_seq == 3);
    TEST(memcmp(inv.predecessor_mhash, w2.successor_mhash, 32) == 0);

    iii_witness_emitter_destroy(e);
    iii_witness_emitter_destroy(e2);
    iii_witness_emitter_destroy(e3);

    TEST(sizeof(iii_xii_witness_t) == 128);
}

/* ----------------------------------------------------------------------------
 * §4.3 BCWL
 * ---------------------------------------------------------------------------- */

static bool count_visit(const iii_xii_witness_t *w, void *user) {
    (void)w;
    (*(unsigned *)user)++;
    return true;
}

static void test_bcwl(void) {
    SECTION("§4.3 BCWL");

    iii_bcwl_t *b = iii_bcwl_create();
    TEST(b != NULL);
    TEST(iii_bcwl_count(b) == 0);

    iii_witness_emitter_t *e = iii_witness_emitter_create(0);

    /* Build a chain of 16 witnesses. */
    iii_xii_witness_t chain[16];
    iii_witness_request_t r = {0};
    r.plan_anchor_id = 0x42;
    for (unsigned i = 0; i < 16; ++i) {
        r.step_kind = (uint16_t)(0x0011 + (i % 4));    /* MSR/CR/NPT/VMCB */
        r.hexad_packed = 0x0001u << (i % 4);
        iii_witness_emit(e, &r, &chain[i]);
        iii_bcwl_insert(b, &chain[i]);
    }
    TEST(iii_bcwl_count(b) == 16);

    /* Bloom-filter presence. */
    TEST(iii_bcwl_contains(b, chain[0].successor_mhash));
    TEST(iii_bcwl_contains(b, chain[15].successor_mhash));
    uint8_t fake[32]; memset(fake, 0xFF, 32);
    TEST(!iii_bcwl_contains(b, fake));

    /* step_kind walk over MSR_WRITE only (0x0011). */
    unsigned msr_count = 0;
    iii_bcwl_walk_step_kind(b, 0x0011, 0x0011, count_visit, &msr_count);
    /* 16 witnesses, every 4th is MSR_WRITE → 4 expected. */
    TEST(msr_count == 4);

    /* Walk a range covering all four kinds. */
    unsigned all_count = 0;
    iii_bcwl_walk_step_kind(b, 0x0010, 0x0020, count_visit, &all_count);
    TEST(all_count == 16);

    /* Chain replay from chain[0]'s successor. */
    unsigned chain_count = 0;
    iii_bcwl_walk_chain(b, chain[0].successor_mhash, count_visit, &chain_count);
    /* Should walk chain[0], chain[1], ..., chain[15] = 16 total. */
    TEST(chain_count == 16);

    iii_bcwl_destroy(b);
    iii_witness_emitter_destroy(e);
}

/* ----------------------------------------------------------------------------
 * §4.4 sub-key derivation
 * ---------------------------------------------------------------------------- */

static void test_subkey(void) {
    SECTION("§4.4 sub-key");

    uint8_t master[32]; for (unsigned i = 0; i < 32; ++i) master[i] = (uint8_t)i;
    uint8_t k0[32], k1[32];
    iii_witness_derive_subkey(master, 0, 1, k0);
    iii_witness_derive_subkey(master, 1, 1, k1);
    TEST(memcmp(k0, k1, 32) != 0); /* different cpu_id → different sub-key */

    uint8_t k0e2[32];
    iii_witness_derive_subkey(master, 0, 2, k0e2);
    TEST(memcmp(k0, k0e2, 32) != 0); /* different epoch → different sub-key */

    /* Determinism. */
    uint8_t k0a[32]; iii_witness_derive_subkey(master, 0, 1, k0a);
    TEST(memcmp(k0, k0a, 32) == 0);
}

/* ----------------------------------------------------------------------------
 * §5 cycle table
 * ---------------------------------------------------------------------------- */

static void make_descriptor(iii_cycle_descriptor_t *d, const char *name, uint16_t step_kind) {
    memset(d, 0, sizeof(*d));
    snprintf(d->name, sizeof(d->name), "%s", name);
    d->step_kind        = step_kind;
    d->composed_hexad   = 0x0003u;
    d->phase_set        = 0x02u;
    d->plan_anchor_id   = 0x1001;
    d->coherence_q14    = 14000;
    d->pip_kind         = III_PIP_STATIC_BYTES;
}

static void test_cycle_table(void) {
    SECTION("§5 cycle table");

    iii_cycle_table_t *t = iii_cycle_table_create();
    iii_cycle_descriptor_t d;

    make_descriptor(&d, "c1", 0x0011);
    uint64_t id1 = iii_cycle_table_register(t, &d);
    TEST(id1 != 0);

    /* Duplicate step_kind rejected (inv 1). */
    make_descriptor(&d, "c2", 0x0011);
    TEST(iii_cycle_table_register(t, &d) == 0);

    make_descriptor(&d, "c2", 0x0012);
    uint64_t id2 = iii_cycle_table_register(t, &d);
    TEST(id2 != 0 && id2 != id1);

    TEST(iii_cycle_table_size(t) == 2);
    TEST(iii_cycle_table_invariants(t));

    /* Invalid: empty phase set. */
    make_descriptor(&d, "bad1", 0x0013);
    d.phase_set = 0;
    TEST(iii_cycle_table_register(t, &d) == 0);

    /* Invalid: bad hexad (>6 bits). */
    make_descriptor(&d, "bad2", 0x0013);
    d.composed_hexad = 0x00FF;
    TEST(iii_cycle_table_register(t, &d) == 0);

    /* Invalid: missing plan anchor. */
    make_descriptor(&d, "bad3", 0x0013);
    d.plan_anchor_id = 0;
    TEST(iii_cycle_table_register(t, &d) == 0);

    /* Lookups. */
    TEST(iii_cycle_table_lookup_by_id(t, id1) != NULL);
    TEST(iii_cycle_table_lookup_by_id(t, 9999) == NULL);

    iii_cycle_table_destroy(t);
}

/* ----------------------------------------------------------------------------
 * §6 Catalyst supersedure
 * ---------------------------------------------------------------------------- */

static void test_catalyst(void) {
    SECTION("§6 Catalyst");

    iii_cycle_table_t *t = iii_cycle_table_create();
    iii_cycle_descriptor_t d;
    make_descriptor(&d, "orig", 0x0014);
    d.candidate_for_promotion = true;
    uint64_t orig_id = iii_cycle_table_register(t, &d);

    iii_catalyst_promotion_t p;
    memset(&p, 0, sizeof(p));
    p.original_cycle_id = orig_id;
    make_descriptor(&p.replacement, "improved", 0); /* step_kind allocated by promote */
    p.trinity_admitted = true;
    p.codegen_validated = true;
    p.coherence_q14 = 14000;
    p.coherence_floor_q14 = 0;

    uint64_t new_id = 0;
    TEST(iii_cycle_table_promote(t, &p, &new_id) == III_CATALYST_OK);
    TEST(new_id != 0 && new_id != orig_id);

    /* Original should be marked superseded. */
    const iii_cycle_descriptor_t *o = iii_cycle_table_lookup_by_id(t, orig_id);
    TEST(o != NULL && o->superseded && o->superseded_by == new_id);

    /* Rate cap: promote 8 more — the 9th must be rate-capped. */
    iii_cycle_table_t *t2 = iii_cycle_table_create();
    uint64_t orig_ids[16];
    for (unsigned i = 0; i < 16; ++i) {
        make_descriptor(&d, "x", (uint16_t)(0x0015 + i));
        d.candidate_for_promotion = true;
        orig_ids[i] = iii_cycle_table_register(t2, &d);
    }
    unsigned ok = 0, capped = 0;
    for (unsigned i = 0; i < 16; ++i) {
        memset(&p, 0, sizeof(p));
        p.original_cycle_id = orig_ids[i];
        make_descriptor(&p.replacement, "rep", 0);
        p.trinity_admitted = true;
        p.codegen_validated = true;
        p.coherence_q14 = 14000;
        iii_catalyst_status_t s = iii_cycle_table_promote(t2, &p, NULL);
        if (s == III_CATALYST_OK)         ok++;
        else if (s == III_CATALYST_E_RATE_CAP) capped++;
    }
    TEST(ok == 8);
    TEST(capped >= 1);

    /* New tick resets the cap. */
    iii_cycle_table_tick(t2);
    TEST(iii_cycle_table_promotions_this_tick(t2) == 0);

    iii_cycle_table_destroy(t);
    iii_cycle_table_destroy(t2);
}

/* ----------------------------------------------------------------------------
 * §8 wavefront
 * ---------------------------------------------------------------------------- */

static void test_wavefront(void) {
    SECTION("§8 wavefront");

    iii_wavefront_t *w = iii_wavefront_begin(0x0001);
    TEST(w != NULL);
    TEST(iii_wavefront_add_effect(w, III_SE_MSR_WRITE,        0x0001));
    TEST(iii_wavefront_add_effect(w, III_SE_VMCB_FIELD_WRITE, 0x0002));
    TEST(iii_wavefront_add_effect(w, III_SE_NPT_ENTRY_WRITE,  0x0004));
    TEST(iii_wavefront_composed_hexad(w) == 0x0007);
    TEST(iii_wavefront_admit(w));

    iii_witness_emitter_t *e = iii_witness_emitter_create(0);
    size_t n = iii_wavefront_commit(w, e, III_WAVEFRONT_QUIESCENT);
    TEST(n == 4); /* 3 effects + 1 commit witness */

    /* Cannot commit twice. */
    TEST(iii_wavefront_commit(w, e, III_WAVEFRONT_QUIESCENT) == 0);

    iii_wavefront_end(w);

    /* Inadmissible composed hexad. */
    iii_wavefront_t *w2 = iii_wavefront_begin(0);
    iii_wavefront_add_effect(w2, III_SE_MSR_WRITE, 0x00FF); /* > 6 bits */
    TEST(!iii_wavefront_admit(w2));
    TEST(iii_wavefront_commit(w2, e, III_WAVEFRONT_QUIESCENT) == 0);
    iii_wavefront_end(w2);

    iii_witness_emitter_destroy(e);
}

/* ----------------------------------------------------------------------------
 * Names
 * ---------------------------------------------------------------------------- */

static void test_names(void) {
    SECTION("names");
    TEST(strcmp(iii_se_kind_name(III_SE_MSR_WRITE), "msr_write") == 0);
    TEST(strcmp(iii_compromise_tier_name(III_COMPROMISE_LOW), "low") == 0);
    TEST(strcmp(iii_pip_kind_name(III_PIP_STATIC_BYTES), "static-bytes") == 0);
    TEST(strcmp(iii_step_kind_band_name(III_BAND_SANCTUM), "SANCTUM") == 0);
    TEST(strcmp(iii_sid_step_name(III_SID_WALK_AST), "01-walk-ast") == 0);
    TEST(strcmp(iii_sid_error_name(III_SID_E_PARSE_IRPD_001), "PARSE-IRPD-001") == 0);
    TEST(strcmp(iii_catalyst_status_name(III_CATALYST_OK), "ok") == 0);
}

int main(void) {
    test_crypto();
    test_bands();
    test_sid();
    test_witness();
    test_bcwl();
    test_subkey();
    test_cycle_table();
    test_catalyst();
    test_wavefront();
    test_names();

    printf("\n=== %d passed, %d failed ===\n", g_pass, g_fail);
    return g_fail == 0 ? 0 : 1;
}
