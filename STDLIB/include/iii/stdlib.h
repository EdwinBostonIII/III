/* ============================================================================
 * III-STDLIB — Master Inventory & System Codex (programmatic access)
 * Spec: III-STDLIB.md  (Refinement Pass v2)
 *
 * Single point of authoritative truth about the III canonical inventory.
 * Every count is verified against the sealed specs.  This is the runtime
 * library that other III tools query for the "ground truth" of the language.
 * ============================================================================
 */
#ifndef III_STDLIB_H
#define III_STDLIB_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ----------------------------------------------------------------------------
 * Counts — sealed against the §17 R1 specification root.
 * ---------------------------------------------------------------------------- */
#define III_STDLIB_KEYWORD_COUNT       47u
#define III_STDLIB_MODIFIER_COUNT      19u
#define III_STDLIB_OPERATOR_COUNT      23u
#define III_STDLIB_PUNCTUATOR_COUNT    25u
#define III_STDLIB_LITERAL_FORM_COUNT   9u
#define III_STDLIB_SE_KIND_COUNT       17u
#define III_STDLIB_COMPROMISE_TIER_COUNT 3u
#define III_STDLIB_PHASE_COUNT          4u
#define III_STDLIB_SANCTUM_SLOT_COUNT  10u
#define III_STDLIB_TRINITY_LAYER_COUNT  3u
#define III_STDLIB_FEDERATION_TIER_COUNT 4u
#define III_STDLIB_CONFORMANCE_COUNT   30u

/* §17 — R1 family member count */
#define III_STDLIB_R1_FAMILY_COUNT     15u

/* Sealed sources — total bytes (approximate). */
#define III_STDLIB_SEALED_TOTAL_BYTES  (412u * 1024u)

/* ----------------------------------------------------------------------------
 * Categories
 * ---------------------------------------------------------------------------- */
typedef enum iii_kw_category {
    III_KW_FUNDAMENTAL    = 0,
    III_KW_ARCHITECTURAL  = 1,
    III_KW_CONCURRENCY    = 2,
    III_KW_QUERY          = 3,
    III_KW_COGNITIVE      = 4,
    III_KW_PROVENANCE     = 5,
    III_KW_CRYPTOGRAPHIC  = 6,
    III_KW_DISTRIBUTED    = 7,
    III_KW_GOVERNANCE     = 8,
    III_KW_SAFETY         = 9,
    III_KW_ESCAPE         = 10,
    III_KW_INTEROP        = 11,
    III_KW_META           = 12
} iii_kw_category_t;

const char *iii_kw_category_name(iii_kw_category_t c);

typedef struct iii_keyword {
    const char        *name;
    iii_kw_category_t  category;
    bool               ascii_only;
    const char        *bind_section;       /* e.g., "III-CYCLES.md §1" */
} iii_keyword_t;

const iii_keyword_t *iii_stdlib_keyword_at(unsigned i);
const iii_keyword_t *iii_stdlib_keyword_lookup(const char *name);

typedef struct iii_modifier {
    const char *name;       /* "@ring", "@hexad", ... */
    const char *form;       /* canonical form */
    const char *bind_sites; /* "type, fn, cycle, module, import, metal block" */
} iii_modifier_t;

const iii_modifier_t *iii_stdlib_modifier_at(unsigned i);
const iii_modifier_t *iii_stdlib_modifier_lookup(const char *name);

typedef struct iii_operator {
    const char *symbol;
    const char *codepoints;
    const char *name;
    uint8_t     precedence;
} iii_operator_t;

const iii_operator_t *iii_stdlib_operator_at(unsigned i);
const iii_operator_t *iii_stdlib_operator_lookup(const char *symbol);

typedef struct iii_punctuator {
    const char *symbol;
    const char *codepoints;
    const char *role;
} iii_punctuator_t;

const iii_punctuator_t *iii_stdlib_punctuator_at(unsigned i);

typedef struct iii_literal_form {
    const char *kind;       /* INT_LIT, MHASH_LIT, ... */
    const char *form;
    const char *type;
    const char *source;
} iii_literal_form_t;

const iii_literal_form_t *iii_stdlib_literal_form_at(unsigned i);

/* ----------------------------------------------------------------------------
 * SE kinds + Compromise tiers (mirror III-CYCLES + III-EFFECTS)
 * ---------------------------------------------------------------------------- */
typedef struct iii_se_kind_entry {
    uint8_t     code;
    const char *name;
    const char *description;
} iii_se_kind_entry_t;

const iii_se_kind_entry_t *iii_stdlib_se_kind_at(unsigned i);

typedef struct iii_compromise_tier_entry {
    const char *name;
    const char *description;
} iii_compromise_tier_entry_t;

const iii_compromise_tier_entry_t *iii_stdlib_compromise_tier_at(unsigned i);

/* ----------------------------------------------------------------------------
 * Phase / Sanctum / Trinity / Federation inventories
 * ---------------------------------------------------------------------------- */
typedef struct iii_phase_entry {
    const char *name;          /* "R-2", ... */
    const char *long_name;     /* "Sanctum", ... */
    int         privilege;     /* lower = more privileged */
} iii_phase_entry_t;

const iii_phase_entry_t *iii_stdlib_phase_at(unsigned i);

typedef struct iii_sanctum_slot_entry {
    uint8_t     slot;          /* 0..9 */
    const char *name;
    const char *purpose;
} iii_sanctum_slot_entry_t;

const iii_sanctum_slot_entry_t *iii_stdlib_sanctum_slot_at(unsigned i);

typedef struct iii_trinity_layer_entry {
    uint8_t     layer;         /* 1, 2, 3 */
    const char *name;
    const char *description;
    uint16_t    overhead_cycles_min;
    uint16_t    overhead_cycles_max;
} iii_trinity_layer_entry_t;

const iii_trinity_layer_entry_t *iii_stdlib_trinity_layer_at(unsigned i);

typedef struct iii_federation_tier_entry {
    const char *name;          /* "transient" ... */
    const char *outbound_rule; /* "Local only" / "Peer pull" / ... */
    const char *quorum;
} iii_federation_tier_entry_t;

const iii_federation_tier_entry_t *iii_stdlib_federation_tier_at(unsigned i);

/* ----------------------------------------------------------------------------
 * Conformance criteria (30)
 * ---------------------------------------------------------------------------- */
typedef struct iii_conformance_entry {
    const char *code;          /* "C-1", ... */
    const char *description;
} iii_conformance_entry_t;

const iii_conformance_entry_t *iii_stdlib_conformance_at(unsigned i);

/* ----------------------------------------------------------------------------
 * R1 family (15 sealed members)
 * ---------------------------------------------------------------------------- */
typedef struct iii_r1_family_entry {
    const char *slot;          /* "R1.A1", "R1.A2", ..., "R1.B3", "R1.C1" */
    const char *file_name;     /* "III-LEXICON.md", ... */
    size_t      bytes;         /* approximate size */
} iii_r1_family_entry_t;

const iii_r1_family_entry_t *iii_stdlib_r1_at(unsigned i);

/* ----------------------------------------------------------------------------
 * Symbol audit entries — see §18.1
 * ---------------------------------------------------------------------------- */
typedef enum iii_symbol_status {
    III_SYM_KEEP            = 0,
    III_SYM_KEEP_NOTE       = 1,
    III_SYM_REVIEW          = 2,
    III_SYM_FLAG            = 3,
    III_SYM_RESOLVED        = 4,
    III_SYM_OPEN            = 5,
    III_SYM_BY_DESIGN       = 6,
    III_SYM_CLARIFY         = 7
} iii_symbol_status_t;

const char *iii_symbol_status_name(iii_symbol_status_t s);

/* ----------------------------------------------------------------------------
 * Self-check: ensure sums match expected R1 totals.
 * ---------------------------------------------------------------------------- */
bool iii_stdlib_self_check(void);

/* ----------------------------------------------------------------------------
 * Tooling: render the entire inventory as JSON-ish to a buffer.
 * Returns total bytes that would have been written.
 * ---------------------------------------------------------------------------- */
size_t iii_stdlib_render(char *out, size_t cap);

#ifdef __cplusplus
}
#endif

#endif /* III_STDLIB_H */
