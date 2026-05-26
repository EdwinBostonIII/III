/* III CONSTANTS — public API: lookup, ledger root, validators. */
#include "iii/constants.h"
#include "iii/constants_internal.h"
#include "iii/sha256.h"

#include <string.h>
#include <stdio.h>

/* ---------------- Lookup ---------------- */

const iii_constant_info_t *iii_constant_lookup(const char *name)
{
    if (!name) return NULL;
    size_t n;
    const iii_constant_info_t *t = iii__constants_table(&n);
    for (size_t i = 0; i < n; ++i) {
        if (strcmp(t[i].name, name) == 0) return &t[i];
    }
    return NULL;
}

/* ---------------- Ledger root (R1.D2) ----------------
 *
 * Canonical encoding per entry, hashed in slot order:
 *   slot       (u32 LE)
 *   type_tag   (u8)
 *   tier       (u8)
 *   name_len   (u32 LE) | name bytes
 *   units_len  (u32 LE) | units bytes
 *   source_len (u32 LE) | source bytes
 *   section_len(u32 LE) | section bytes
 *   value_len  (u32 LE) | value bytes
 *   0xFF separator
 */

static void put_u32_le(iii_sha256_ctx_t *c, uint32_t v)
{
    uint8_t b[4];
    b[0] = (uint8_t)(v & 0xFF);
    b[1] = (uint8_t)((v >> 8) & 0xFF);
    b[2] = (uint8_t)((v >> 16) & 0xFF);
    b[3] = (uint8_t)((v >> 24) & 0xFF);
    iii_sha256_update(c, b, 4);
}

static void put_u8(iii_sha256_ctx_t *c, uint8_t v)
{
    iii_sha256_update(c, &v, 1);
}

static void put_lp_str(iii_sha256_ctx_t *c, const char *s)
{
    size_t n = s ? strlen(s) : 0;
    put_u32_le(c, (uint32_t)n);
    if (n) iii_sha256_update(c, (const uint8_t *)s, n);
}

void iii_constant_compute_ledger_root(uint8_t out[32])
{
    size_t n;
    const iii_constant_info_t *t = iii__constants_table(&n);
    iii_sha256_ctx_t c;
    iii_sha256_init(&c);

    /* Domain separator: prefix the hash with a fixed magic so root
     * cannot be confused with other SHA-256 contexts. */
    static const uint8_t magic[16] = {
        'I','I','I','-','C','O','N','S','T','A','N','T','S','-','D','2'
    };
    iii_sha256_update(&c, magic, 16);
    put_u32_le(&c, (uint32_t)n);

    for (size_t i = 0; i < n; ++i) {
        const iii_constant_info_t *e = &t[i];
        put_u32_le(&c, e->hash_slot);
        put_u8(&c, (uint8_t)e->type_tag);
        put_u8(&c, (uint8_t)e->mutation_tier);
        put_lp_str(&c, e->name);
        put_lp_str(&c, e->units);
        put_lp_str(&c, e->source);
        put_lp_str(&c, e->section);
        put_u32_le(&c, (uint32_t)e->value_len);
        if (e->value_len) iii_sha256_update(&c, e->value_bytes, e->value_len);
        put_u8(&c, 0xFF);
    }
    iii_sha256_final(&c, out);
}

void iii_constant_compute_ledger_root_hex(char out[65])
{
    uint8_t h[32];
    iii_constant_compute_ledger_root(h);
    static const char hx[] = "0123456789abcdef";
    for (int i = 0; i < 32; ++i) {
        out[2*i]   = hx[(h[i] >> 4) & 0xF];
        out[2*i+1] = hx[h[i] & 0xF];
    }
    out[64] = '\0';
}

/* ---------------- Mutation-path validators ----------------
 *
 * A constant whose tier == III_MT_NEVER_MUTABLE can never be mutated
 * by any path.  CATALYST_APPEND mutations must not regress (numeric
 * value must be ≥ current; BAND/TUPLE2 high must be ≥ current high;
 * STRING length must be ≥ current length).  AMEND_APPLY accepts
 * SEALED_DEFAULT and SCHEDULED tiers as well (those are tier-3
 * constitutional categories).  R2_MAJOR_BUMP requires R2_MAJOR_BUMP
 * tier exactly.
 */

static int compare_numeric(const iii_constant_info_t *e,
                           const uint8_t *nv, size_t nv_len,
                           int *new_ge_old)
{
    *new_ge_old = 0;
    if (e->type_tag == III_CT_U64 || e->type_tag == III_CT_S64) {
        if (nv_len != 8) return -1;
        uint64_t cur = 0, neu = 0;
        for (int k = 0; k < 8; ++k) {
            cur |= ((uint64_t)e->value_bytes[k]) << (8*k);
            neu |= ((uint64_t)nv[k]) << (8*k);
        }
        if (e->type_tag == III_CT_S64) {
            int64_t cs = (int64_t)cur, ns = (int64_t)neu;
            *new_ge_old = (ns >= cs);
        } else {
            *new_ge_old = (neu >= cur);
        }
        return 0;
    }
    if (e->type_tag == III_CT_Q14) {
        if (nv_len != 2) return -1;
        int16_t cur = (int16_t)((uint16_t)e->value_bytes[0]
                              | ((uint16_t)e->value_bytes[1] << 8));
        int16_t neu = (int16_t)((uint16_t)nv[0]
                              | ((uint16_t)nv[1] << 8));
        *new_ge_old = (neu >= cur);
        return 0;
    }
    if (e->type_tag == III_CT_BAND || e->type_tag == III_CT_TUPLE2) {
        if (nv_len != 8) return -1;
        uint32_t chi = (uint32_t)e->value_bytes[4]
                     | ((uint32_t)e->value_bytes[5] << 8)
                     | ((uint32_t)e->value_bytes[6] << 16)
                     | ((uint32_t)e->value_bytes[7] << 24);
        uint32_t nhi = (uint32_t)nv[4]
                     | ((uint32_t)nv[5] << 8)
                     | ((uint32_t)nv[6] << 16)
                     | ((uint32_t)nv[7] << 24);
        *new_ge_old = (nhi >= chi);
        return 0;
    }
    if (e->type_tag == III_CT_STRING || e->type_tag == III_CT_BYTES) {
        *new_ge_old = (nv_len >= e->value_len);
        return 0;
    }
    if (e->type_tag == III_CT_BOOL) {
        if (nv_len != 1) return -1;
        *new_ge_old = (nv[0] >= e->value_bytes[0]);
        return 0;
    }
    return -1;
}

iii_constant_validate_t iii_constant_validate_catalyst_append(
    const char *name, const uint8_t *new_value, size_t new_value_len)
{
    const iii_constant_info_t *e = iii_constant_lookup(name);
    if (!e) return III_CV_NOT_FOUND;
    if (e->mutation_tier == III_MT_NEVER_MUTABLE)
        return III_CV_NEVER_MUTABLE;
    if (e->mutation_tier != III_MT_CATALYST_APPEND)
        return III_CV_WRONG_TIER;
    if (!new_value && new_value_len) return III_CV_INVALID_VALUE;
    int ge = 0;
    if (compare_numeric(e, new_value, new_value_len, &ge) != 0)
        return III_CV_INVALID_VALUE;
    if (!ge) return III_CV_VALUE_REGRESS;
    return III_CV_OK;
}

/* Founder's Anchor invariants are NEVER_MUTABLE entries already; in
 * addition, several entries with non-NEVER tiers are *gated* on Anchor
 * cosignature.  Because amend_apply's validator role is to check
 * mutation-path eligibility (not signature presence), we accept the
 * anchored ones and merely flag NEVER entries as locked. */
iii_constant_validate_t iii_constant_validate_amend_apply(
    const char *name, const uint8_t *new_value, size_t new_value_len)
{
    const iii_constant_info_t *e = iii_constant_lookup(name);
    if (!e) return III_CV_NOT_FOUND;
    if (e->mutation_tier == III_MT_NEVER_MUTABLE)
        return III_CV_FOUNDERS_LOCKED;
    if (e->mutation_tier != III_MT_AMEND_APPLY
        && e->mutation_tier != III_MT_SEALED_DEFAULT
        && e->mutation_tier != III_MT_SCHEDULED
        && e->mutation_tier != III_MT_OPERATOR_POLICY)
        return III_CV_WRONG_TIER;
    if (!new_value && new_value_len) return III_CV_INVALID_VALUE;
    /* AMEND-APPLY may set arbitrary new value, but length must match
     * the type's encoding rule. */
    int ge = 0;
    if (compare_numeric(e, new_value, new_value_len, &ge) != 0)
        return III_CV_INVALID_VALUE;
    return III_CV_OK;
}

iii_constant_validate_t iii_constant_validate_r2_bump(
    const char *name, const uint8_t *new_value, size_t new_value_len)
{
    const iii_constant_info_t *e = iii_constant_lookup(name);
    if (!e) return III_CV_NOT_FOUND;
    if (e->mutation_tier == III_MT_NEVER_MUTABLE)
        return III_CV_FOUNDERS_LOCKED;
    if (e->mutation_tier != III_MT_R2_MAJOR_BUMP)
        return III_CV_WRONG_TIER;
    if (!new_value && new_value_len) return III_CV_INVALID_VALUE;
    int ge = 0;
    if (compare_numeric(e, new_value, new_value_len, &ge) != 0)
        return III_CV_INVALID_VALUE;
    return III_CV_OK;
}

/* ---------------- String formatting ---------------- */

const char *iii_constant_validate_str(iii_constant_validate_t v)
{
    switch (v) {
    case III_CV_OK:              return "OK";
    case III_CV_NOT_FOUND:       return "NOT_FOUND";
    case III_CV_WRONG_TIER:      return "WRONG_TIER";
    case III_CV_NEVER_MUTABLE:   return "NEVER_MUTABLE";
    case III_CV_VALUE_REGRESS:   return "VALUE_REGRESS";
    case III_CV_INVALID_VALUE:   return "INVALID_VALUE";
    case III_CV_FOUNDERS_LOCKED: return "FOUNDERS_LOCKED";
    }
    return "?";
}

const char *iii_constant_type_str(iii_constant_type_t t)
{
    switch (t) {
    case III_CT_U64:    return "U64";
    case III_CT_S64:    return "S64";
    case III_CT_Q14:    return "Q14";
    case III_CT_BAND:   return "BAND";
    case III_CT_TUPLE2: return "TUPLE2";
    case III_CT_BOOL:   return "BOOL";
    case III_CT_STRING: return "STRING";
    case III_CT_BYTES:  return "BYTES";
    }
    return "?";
}

const char *iii_constant_tier_str(iii_mutation_tier_t t)
{
    switch (t) {
    case III_MT_NEVER_MUTABLE:      return "NEVER_MUTABLE";
    case III_MT_R2_MAJOR_BUMP:      return "R2_MAJOR_BUMP";
    case III_MT_AMEND_APPLY:        return "AMEND_APPLY";
    case III_MT_CATALYST_APPEND:    return "CATALYST_APPEND";
    case III_MT_DERIVED:            return "DERIVED";
    case III_MT_OPERATIONAL_TARGET: return "OPERATIONAL_TARGET";
    case III_MT_OPERATOR_POLICY:    return "OPERATOR_POLICY";
    case III_MT_SCHEDULED:          return "SCHEDULED";
    case III_MT_SEALED_DEFAULT:     return "SEALED_DEFAULT";
    }
    return "?";
}
