/* III CONSTANTS — test suite.
 *
 * Coverage:
 *   - every entry is reachable by both slot and name lookup
 *   - canonical encoding lengths match each type-tag's contract
 *   - ledger root is deterministic across two computations
 *   - ledger root is non-zero
 *   - mutation-path validators accept the right tiers and reject others
 *   - sample positive/negative cases for each path
 */
#include "iii/constants.h"

#include <stdio.h>
#include <string.h>
#include <stdint.h>

static int g_pass = 0;
static int g_fail = 0;

#define CHECK(cond, fmt, ...) do {                                  \
    if (cond) { ++g_pass; }                                         \
    else { ++g_fail;                                                \
           fprintf(stderr, "FAIL %s:%d  " fmt "\n",                 \
                   __FILE__, __LINE__, ##__VA_ARGS__); }            \
} while (0)

static void enc_u64(uint64_t v, uint8_t out[8])
{
    for (int k = 0; k < 8; ++k) out[k] = (uint8_t)((v >> (8*k)) & 0xFF);
}

static void test_count_and_indexing(void)
{
    size_t n = iii_constant_count();
    CHECK(n > 0, "count must be > 0");
    CHECK(iii_constant_at(0) == NULL, "slot 0 must be NULL");
    CHECK(iii_constant_at((uint32_t)(n + 1)) == NULL, "out-of-range NULL");

    for (uint32_t i = 1; i <= (uint32_t)n; ++i) {
        const iii_constant_info_t *e = iii_constant_at(i);
        CHECK(e != NULL, "slot %u must resolve", i);
        if (!e) continue;
        CHECK(e->hash_slot == i, "slot index round-trip slot=%u name=%s",
              i, e->name);
        CHECK(e->name && e->name[0] != '\0', "name non-empty slot=%u", i);
        CHECK(e->units != NULL, "units non-null slot=%u", i);
        CHECK(e->source != NULL, "source non-null slot=%u", i);
        CHECK(e->section != NULL, "section non-null slot=%u", i);
        CHECK(e->value_bytes != NULL || e->value_len == 0,
              "value pointer slot=%u", i);
    }
}

static void test_lookup_each(void)
{
    size_t n = iii_constant_count();
    for (uint32_t i = 1; i <= (uint32_t)n; ++i) {
        const iii_constant_info_t *e = iii_constant_at(i);
        const iii_constant_info_t *l = iii_constant_lookup(e->name);
        CHECK(l == e, "lookup '%s' must return same pointer", e->name);
    }
    CHECK(iii_constant_lookup("__NO_SUCH_CONSTANT__") == NULL,
          "missing name returns NULL");
    CHECK(iii_constant_lookup(NULL) == NULL, "NULL name returns NULL");
}

static void test_encoding_lengths(void)
{
    size_t n = iii_constant_count();
    for (uint32_t i = 1; i <= (uint32_t)n; ++i) {
        const iii_constant_info_t *e = iii_constant_at(i);
        switch (e->type_tag) {
        case III_CT_U64: case III_CT_S64:
            CHECK(e->value_len == 8, "U64/S64 must be 8B name=%s", e->name);
            break;
        case III_CT_Q14:
            CHECK(e->value_len == 2, "Q14 must be 2B name=%s", e->name);
            break;
        case III_CT_BAND: case III_CT_TUPLE2:
            CHECK(e->value_len == 8, "BAND/TUPLE2 must be 8B name=%s", e->name);
            break;
        case III_CT_BOOL:
            CHECK(e->value_len == 1, "BOOL must be 1B name=%s", e->name);
            break;
        case III_CT_STRING:
            CHECK(e->value_len > 0, "STRING must be non-empty name=%s", e->name);
            break;
        case III_CT_BYTES:
            /* allowed any length */
            break;
        }
    }
}

static void test_known_values(void)
{
    /* Spot-check a handful of well-known constants. */
    const iii_constant_info_t *e;

    e = iii_constant_lookup("LEX_KEYWORD_COUNT");
    CHECK(e != NULL, "LEX_KEYWORD_COUNT exists");
    if (e) {
        uint64_t v = 0;
        for (int k = 0; k < 8; ++k) v |= ((uint64_t)e->value_bytes[k]) << (8*k);
        CHECK(v == 47, "LEX_KEYWORD_COUNT == 47, got %llu", (unsigned long long)v);
    }

    e = iii_constant_lookup("MOBIUS_COHERENCE_FLOOR_Q14");
    CHECK(e != NULL && e->type_tag == III_CT_Q14, "Mobius floor is Q14");
    if (e) {
        int16_t v = (int16_t)((uint16_t)e->value_bytes[0]
                            | ((uint16_t)e->value_bytes[1] << 8));
        CHECK(v == 15073, "Mobius floor == 15073, got %d", v);
    }

    e = iii_constant_lookup("SK_SANCTUM");
    CHECK(e != NULL && e->type_tag == III_CT_BAND, "SK_SANCTUM is BAND");
    if (e) {
        uint32_t lo = (uint32_t)e->value_bytes[0]
                    | ((uint32_t)e->value_bytes[1] << 8)
                    | ((uint32_t)e->value_bytes[2] << 16)
                    | ((uint32_t)e->value_bytes[3] << 24);
        uint32_t hi = (uint32_t)e->value_bytes[4]
                    | ((uint32_t)e->value_bytes[5] << 8)
                    | ((uint32_t)e->value_bytes[6] << 16)
                    | ((uint32_t)e->value_bytes[7] << 24);
        CHECK(lo == 0x0080 && hi == 0x009F, "SK_SANCTUM band 0x80..0x9F");
    }

    e = iii_constant_lookup("FED_TIER1_QUORUM");
    CHECK(e != NULL && e->type_tag == III_CT_TUPLE2, "tier1 tuple");

    e = iii_constant_lookup("LEX_BOM_FORBIDDEN");
    CHECK(e != NULL && e->type_tag == III_CT_BOOL && e->value_bytes[0] == 1,
          "BOM forbidden true");

    e = iii_constant_lookup("LEX_SOURCE_EXTENSION");
    CHECK(e != NULL && e->type_tag == III_CT_STRING
          && e->value_len == 4
          && memcmp(e->value_bytes, ".III", 4) == 0,
          "source ext .III");
}

static void test_ledger_determinism(void)
{
    uint8_t a[32], b[32];
    iii_constant_compute_ledger_root(a);
    iii_constant_compute_ledger_root(b);
    CHECK(memcmp(a, b, 32) == 0, "ledger root deterministic");

    int nonzero = 0;
    for (int i = 0; i < 32; ++i) if (a[i]) { nonzero = 1; break; }
    CHECK(nonzero, "ledger root must be non-zero");

    char hex[65];
    iii_constant_compute_ledger_root_hex(hex);
    CHECK(strlen(hex) == 64, "hex root is 64 chars");
}

static void test_validate_catalyst_append(void)
{
    /* Positive: LEX_KEYWORD_COUNT is CATALYST_APPEND; raise to 50. */
    uint8_t v[8]; enc_u64(50, v);
    CHECK(iii_constant_validate_catalyst_append("LEX_KEYWORD_COUNT", v, 8) == III_CV_OK,
          "append: 47 -> 50 OK");

    /* Negative: regression. */
    enc_u64(10, v);
    CHECK(iii_constant_validate_catalyst_append("LEX_KEYWORD_COUNT", v, 8) == III_CV_VALUE_REGRESS,
          "append: 47 -> 10 regress");

    /* Negative: wrong tier (LEX_PUNCTUATOR_COUNT is AMEND_APPLY). */
    enc_u64(99, v);
    CHECK(iii_constant_validate_catalyst_append("LEX_PUNCTUATOR_COUNT", v, 8) == III_CV_WRONG_TIER,
          "append on AMEND tier rejected");

    /* Negative: NEVER_MUTABLE entry. */
    enc_u64(7, v);
    CHECK(iii_constant_validate_catalyst_append("EFFECT_PFS_BRICKING_OPS", v, 8) == III_CV_NEVER_MUTABLE,
          "append on NEVER rejected");

    /* Negative: not found. */
    CHECK(iii_constant_validate_catalyst_append("__BOGUS__", v, 8) == III_CV_NOT_FOUND,
          "append: missing");

    /* Negative: invalid length. */
    CHECK(iii_constant_validate_catalyst_append("LEX_KEYWORD_COUNT", v, 3) == III_CV_INVALID_VALUE,
          "append: bad length");
}

static void test_validate_amend_apply(void)
{
    /* Positive: LEX_PUNCTUATOR_COUNT is AMEND_APPLY. */
    uint8_t v[8]; enc_u64(26, v);
    CHECK(iii_constant_validate_amend_apply("LEX_PUNCTUATOR_COUNT", v, 8) == III_CV_OK,
          "amend: punctuator->26 OK");

    /* Positive: amend can decrease too (unlike append). */
    enc_u64(20, v);
    CHECK(iii_constant_validate_amend_apply("LEX_PUNCTUATOR_COUNT", v, 8) == III_CV_OK,
          "amend: decrease OK");

    /* Negative: NEVER -> founders-locked. */
    enc_u64(0, v);
    CHECK(iii_constant_validate_amend_apply("SANCTUM_SLOT_INVALID", v, 8) == III_CV_FOUNDERS_LOCKED,
          "amend: NEVER locked");

    /* Negative: CATALYST_APPEND tier rejects amend path. */
    enc_u64(50, v);
    CHECK(iii_constant_validate_amend_apply("LEX_KEYWORD_COUNT", v, 8) == III_CV_WRONG_TIER,
          "amend: CATALYST tier rejected");

    /* Negative: R2 tier rejects amend. */
    enc_u64(8, v);
    CHECK(iii_constant_validate_amend_apply("TYPE_UNIVERSE_COUNT", v, 8) == III_CV_WRONG_TIER,
          "amend: R2 tier rejected");

    /* Positive: SEALED_DEFAULT accepted. */
    enc_u64(0x0001, v);
    CHECK(iii_constant_validate_amend_apply("CRYPTO_SUITE_PRE_QUANTUM", v, 8) == III_CV_OK,
          "amend: SEALED_DEFAULT accepted");

    /* Positive: SCHEDULED accepted. */
    enc_u64(5, v);
    CHECK(iii_constant_validate_amend_apply("R1_RESERVED_WAVE_SLOTS", v, 8) == III_CV_OK,
          "amend: SCHEDULED accepted");
}

static void test_validate_r2_bump(void)
{
    /* Positive: TYPE_UNIVERSE_COUNT is R2. */
    uint8_t v[8]; enc_u64(8, v);
    CHECK(iii_constant_validate_r2_bump("TYPE_UNIVERSE_COUNT", v, 8) == III_CV_OK,
          "r2: universe count OK");

    /* Negative: AMEND tier rejected. */
    enc_u64(26, v);
    CHECK(iii_constant_validate_r2_bump("LEX_PUNCTUATOR_COUNT", v, 8) == III_CV_WRONG_TIER,
          "r2: AMEND rejected");

    /* Negative: NEVER -> founders locked. */
    enc_u64(0, v);
    CHECK(iii_constant_validate_r2_bump("SANCTUM_SLOT_INVALID", v, 8) == III_CV_FOUNDERS_LOCKED,
          "r2: NEVER locked");

    /* Negative: CATALYST tier rejected. */
    enc_u64(50, v);
    CHECK(iii_constant_validate_r2_bump("LEX_KEYWORD_COUNT", v, 8) == III_CV_WRONG_TIER,
          "r2: CATALYST rejected");
}

static void test_string_helpers(void)
{
    CHECK(strcmp(iii_constant_validate_str(III_CV_OK), "OK") == 0, "OK str");
    CHECK(strcmp(iii_constant_type_str(III_CT_U64), "U64") == 0, "U64 str");
    CHECK(strcmp(iii_constant_tier_str(III_MT_NEVER_MUTABLE),
                 "NEVER_MUTABLE") == 0, "NEVER str");
}

static void test_unique_names_and_slots(void)
{
    size_t n = iii_constant_count();
    /* Quadratic but n is small. */
    for (size_t i = 0; i < n; ++i) {
        const iii_constant_info_t *a = iii_constant_at((uint32_t)(i+1));
        for (size_t j = i + 1; j < n; ++j) {
            const iii_constant_info_t *b = iii_constant_at((uint32_t)(j+1));
            if (strcmp(a->name, b->name) == 0) {
                ++g_fail;
                fprintf(stderr, "FAIL duplicate name '%s' slots %u and %u\n",
                        a->name, a->hash_slot, b->hash_slot);
            } else { ++g_pass; }
        }
    }
}

int main(void)
{
    test_count_and_indexing();
    test_lookup_each();
    test_encoding_lengths();
    test_known_values();
    test_ledger_determinism();
    test_validate_catalyst_append();
    test_validate_amend_apply();
    test_validate_r2_bump();
    test_string_helpers();
    test_unique_names_and_slots();

    char hex[65];
    iii_constant_compute_ledger_root_hex(hex);
    printf("registered=%zu  R1.D2=%s\n", iii_constant_count(), hex);
    printf("=== %d passed, %d failed ===\n", g_pass, g_fail);
    return g_fail == 0 ? 0 : 1;
}
