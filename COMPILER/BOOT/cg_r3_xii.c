/* COMPILER/BOOT/cg_r3_xii.c — XII extensions to cg_r3 codegen (implementation).
 *
 * Per DOCS/III-XII.md S14.4 + S26.13.
 *
 * NIH: libc + Win32 only.
 */

#include "cg_r3_xii.h"
#include <stdint.h>
#include <string.h>
#include <stdio.h>

/* AST kind constants for fusion-call nodes (sema.c also defines these). */
#define XII_K_FUSION_CALL  0x80
#define XII_K_DECL_FN      0x10

/* AST/sema externs (provided by sema.c and ast.c). */
extern int sema_has_annotation(uint64_t fn_node, int anno_kind);
extern uint32_t sema_get_anno_u32(uint64_t fn_node, int anno_kind, uint32_t default_val);
extern uint64_t ast_walk_find_kind(uint64_t fn_node, int kind);
extern uint64_t ast_get_field(uint64_t ast, uint64_t node, int field_id);
#define XII_FIELD_FN_BODY  0x01

/* CPU feature detection (provided by numera/cpufeat.iii). */
extern uint32_t cpufeat_feature_mask(void);
extern uint32_t cpufeat_auto_target(void);

#define XII_AUTO_TARGET 0xFFFFFFFFu

/* Emit-section writer (provided by emit.c). */
extern int emit_section_bytes(const char *section_name, const uint8_t *bytes, uint32_t len);
extern uint64_t emit_current_text_offset(void);

/* ------------------------------------------------------------------ */
/* xii_enabled_for                                                     */
/* ------------------------------------------------------------------ */

int
xii_enabled_for(uint64_t ast, uint64_t fn_node)
{
    if (sema_has_annotation(fn_node, XII_ANNO_LATTICE)) return 1;
    if (ast_walk_find_kind(fn_node, XII_K_FUSION_CALL) != 0) return 1;
    return 0;
}

/* ------------------------------------------------------------------ */
/* r3_compute_circ — 24-bit packed encoding                            */
/* ------------------------------------------------------------------ */

static uint32_t
k_bucket_from_k_max(uint32_t k_max)
{
    if (k_max <= 1) return 0;
    if (k_max <= 3) return 1;
    if (k_max <= 7) return 2;
    if (k_max <= 15) return 3;
    if (k_max <= 31) return 4;
    if (k_max <= 63) return 5;
    if (k_max <= 127) return 6;
    return 7;
}

/* Compute a cap_set_class from the function's annotated cap_required.
 * For simplicity here we hash the bitmask to a 4-bit class. */
static uint32_t
cap_classify(uint32_t cap_set)
{
    /* 16-class classifier: 1 bit per nibble of the cap_set. */
    return ((cap_set & 0xFFFFu) ^ ((cap_set >> 16) & 0xFFFFu)) & 0xFu;
}

uint32_t
r3_compute_circ(uint64_t ast, uint64_t fn_node)
{
    (void)ast;
    uint32_t target = sema_get_anno_u32(fn_node, XII_ANNO_DEPLOY_TARGET, XII_AUTO_TARGET);
    if (target == XII_AUTO_TARGET) target = cpufeat_auto_target();
    if (target > 6) target = 1;  /* default x86_avx2 if unknown */

    uint32_t hw_mask = cpufeat_feature_mask() & 0xFu;
    uint32_t k_max = sema_get_anno_u32(fn_node, 0x05 /* ANNO_K_MAX */, 16);
    uint32_t k_bucket = k_bucket_from_k_max(k_max);

    uint32_t cap_set = sema_get_anno_u32(fn_node, 0x06 /* ANNO_CAP_REQUIRED */, 0);
    uint32_t cap_class = cap_classify(cap_set);

    uint32_t hexad = sema_get_anno_u32(fn_node, 0x07 /* ANNO_HEXAD_KIND */, 1);
    uint32_t fusion_b = sema_get_anno_u32(fn_node, XII_ANNO_FUSION_BUDGET, 3);

    return  (target & 0x7u)
         | ((hw_mask & 0xFu) << 3)
         | ((k_bucket & 0x7u) << 7)
         | ((cap_class & 0xFu) << 10)
         | ((hexad & 0x7u) << 14)
         | ((fusion_b & 0x7u) << 17);
}

/* ------------------------------------------------------------------ */
/* r3_pe_canonicalise — calls into omnia/xii_canonicalise.iii          */
/* ------------------------------------------------------------------ */

extern uint32_t xii_canonicalise(uint32_t term_ref);
extern uint32_t xii_term_arena_reset(void);
extern uint32_t xii_term_arena_used(void);

/* Build an XII term from the AST fn body. Returns term_ref. */
extern uint32_t r3_ast_to_xii_term(uint64_t ast, uint64_t body_node);

int
r3_pe_canonicalise(uint64_t ast, uint64_t fn_node)
{
    uint64_t body = ast_get_field(ast, fn_node, XII_FIELD_FN_BODY);
    if (body == 0) return XII_R3_OK;

    xii_term_arena_reset();
    uint32_t term = r3_ast_to_xii_term(ast, body);
    if (term == 0xFFFFFFFFu) return XII_R3_FAIL;

    uint32_t canon = xii_canonicalise(term);
    (void)canon;
    return XII_R3_OK;
}

/* ------------------------------------------------------------------ */
/* r3_emit_xii_call_site                                               */
/* ------------------------------------------------------------------ */

int
r3_emit_xii_call_site(uint64_t call_site_offset,
                      uint8_t horizon_id,
                      uint8_t static_circ_flag,
                      uint32_t circ_encoding,
                      uint16_t expected_size,
                      uint8_t ct_kind,
                      uint8_t prov_xform_id,
                      uint32_t deployment_target)
{
    uint8_t descriptor[24];
    for (int i = 0; i < 8; ++i) {
        descriptor[i] = (uint8_t)((call_site_offset >> (i * 8)) & 0xFF);
    }
    descriptor[8] = horizon_id;
    descriptor[9] = static_circ_flag;
    descriptor[10] = 0;
    descriptor[11] = 0;
    descriptor[12] = (uint8_t)(circ_encoding & 0xFF);
    descriptor[13] = (uint8_t)((circ_encoding >> 8) & 0xFF);
    descriptor[14] = (uint8_t)((circ_encoding >> 16) & 0xFF);
    descriptor[15] = (uint8_t)((circ_encoding >> 24) & 0xFF);
    descriptor[16] = (uint8_t)(expected_size & 0xFF);
    descriptor[17] = (uint8_t)((expected_size >> 8) & 0xFF);
    descriptor[18] = ct_kind;
    descriptor[19] = prov_xform_id;
    descriptor[20] = (uint8_t)(deployment_target & 0xFF);
    descriptor[21] = (uint8_t)((deployment_target >> 8) & 0xFF);
    descriptor[22] = (uint8_t)((deployment_target >> 16) & 0xFF);
    descriptor[23] = (uint8_t)((deployment_target >> 24) & 0xFF);

    return emit_section_bytes(".iii_xii_calls", descriptor, 24);
}

/* ------------------------------------------------------------------ */
/* r3_pe_lattice_emit — Horizon lookup + placeholder NOP emission     */
/* ------------------------------------------------------------------ */

extern uint8_t xii_horizon_is_productive(uint32_t horizon_id);
extern uint32_t xii_horizon_construct(uint32_t horizon_id);
extern uint8_t xii_horizon_ct_kind(uint32_t horizon_id);
extern uint32_t xii_horizon_k_cost(uint32_t horizon_id);
extern uint32_t xii_emit_gen_produce(uint32_t horizon_id, uint32_t target, uint32_t expected_size, uint8_t *out);

/* Choose a Horizon pattern for the canonical-form term.
 *
 * RESERVED SELECTION SEAM (DOCS/XII-HORIZON-DISPATCH.md).  The real
 * dispatch is: r3_ast_to_xii_term -> xii_canonicalise -> full-tree
 * canonical mhash -> xii_chd_lookup_split (CHD MPHF over the 144 horizon
 * canonical-term mhashes) -> membership-verify vs the seeded hash ->
 * horizon_id (or fall back when the term matches no horizon pattern).
 *
 * That real path is gated, not "todo": (a) no full-tree canonical-term
 * hash primitive exists (xii_term_mhash is single-node only); (b) the
 * CHD MPHF is never seeded with the 144 real horizon mhashes in any
 * build/runtime path (only corpus tests seed synthetic keys); (c)
 * xii_chd_lookup_split is a pure MPHF needing a membership-verify
 * wrapper.  Crucially the BACK-END this would feed (r3_pe_lattice_emit
 * -> real curated/sealed Lattice cell bytes) is the sealed-sanctum
 * ceremony deferral (DOCS Curation-Remaining item 5), so a real
 * front-end here changes no emitted bytes until the sealed Lattice
 * lands.  Additionally there are ZERO @lattice-annotated functions in
 * the corpus, so r3_pe_lattice_emit (and this selector) is currently
 * unreached -- this deterministic (hexad,k) selection is observably
 * inert, not a behavioural placeholder masquerading as complete.
 *
 * Kept deterministic and content-stable so the seam is sealed-mhash
 * neutral until the ceremony-gated full pipeline is realised. */
static uint32_t
r3_select_horizon_for_term(uint64_t ast, uint64_t fn_node)
{
    uint32_t hexad = sema_get_anno_u32(fn_node, 0x07, 6);  /* COMPOSE default */
    uint32_t k = sema_get_anno_u32(fn_node, 0x05, 1);
    /* Deterministic mapping: pick a productive Horizon id by (hexad, k). */
    uint32_t base = (hexad - 1) * 18 + (k & 0xFu);
    /* Find the first productive pattern at or after `base`. */
    for (uint32_t i = 0; i < 144; ++i) {
        uint32_t id = (base + i) % 144;
        if (xii_horizon_is_productive(id) == 1) return id;
    }
    return 0;
}

int
r3_pe_lattice_emit(uint64_t ast, uint64_t fn_node, uint32_t circ_encoding)
{
    uint32_t horizon_id = r3_select_horizon_for_term(ast, fn_node);
    if (xii_horizon_is_productive(horizon_id) != 1) {
        fprintf(stderr, "XII-CANON-099: guard cell hit (id=%u)\n", horizon_id);
        return XII_R3_FAIL;
    }

    uint32_t target = circ_encoding & 0x7u;
    uint8_t ct_kind = xii_horizon_ct_kind(horizon_id);
    uint32_t k_cost = xii_horizon_k_cost(horizon_id);

    /* Conservative placeholder size: max 512 bytes per S26.12.1. */
    uint16_t expected_size = 256;
    if (k_cost > 100) expected_size = 512;

    /* Emit placeholder NOPs at current text offset. */
    uint64_t cs_off = emit_current_text_offset();
    uint8_t nop_buf[512];
    extern uint32_t xii_ldil_fill_nops(uint8_t *out, uint32_t count, uint32_t deployment_target);
    uint32_t filled = xii_ldil_fill_nops(nop_buf, expected_size, target);
    if (filled == 0) return XII_R3_FAIL;
    if (emit_section_bytes(".text", nop_buf, filled) != 0) return XII_R3_FAIL;

    /* prov_xform_id mirrors gen_xii_lattice's derivation: per-horizon
     * provenance transform id == ct_kind (CT class 0..8 maps into the
     * lower 9 slots of the 17-slot prov-xform space; the remaining 9..16
     * slots are reserved for runtime witness transforms). */
    uint8_t prov_xform_id = ct_kind;

    /* Record call-site descriptor for LDIL. */
    if (r3_emit_xii_call_site(cs_off, (uint8_t)horizon_id, 1, circ_encoding,
                              (uint16_t)filled, ct_kind, prov_xform_id, target) != 0) {
        return XII_R3_FAIL;
    }

    return XII_R3_OK;
}
