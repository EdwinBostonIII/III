/* III EFFECTS — implementation (R1.A4 / DOCS/III-EFFECTS.md).
 *
 * Single TU implementation of the effect algebra:
 *
 *   §1 — 17 SE kinds + 3 Compromise tiers
 *   §2 — IRPD discipline (admissible-ring + SID-derived inverses)
 *   §3 — PIP (Predictive Inverse Pre-Materialization)
 *   §4 — Ghost effects (witness elision)
 *   §5 — Epistemic effects (uncertainty Q14 carriers)
 *   §6 — Möbius effects (self-extension via reserved-band promotion)
 *   §7 — Effect-set algebra (sort/eq/subset/union)
 *   §8 — Inference: AST -> iii_effect_set_t
 *
 * NIH discipline: only libc + libiii_lex + libiii_grammar + libiii_types.
 */
#include "iii/effects.h"

#include <iii/sha256.h>

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

/* ---------------------------------------------------------------------- */
/* §1.1 — SE kind table                                                   */
/* ---------------------------------------------------------------------- */

typedef struct {
    iii_se_kind_t   kind;
    const char     *name;        /* enum name */
    const char     *method;      /* IRPD method (text used in irpd.<m>(..)) */
    const char     *hexad_name;  /* hexad designator per §1.1 */
    uint8_t         rings;       /* bitmask over iii_ring_t */
    iii_se_kind_t   inverse;     /* SID-derived inverse SE kind */
    const char     *inv_method;  /* SID-derived inverse method (NULL = external) */
    iii_compromise_t default_tier;
    iii_pip_class_t  pip;
} iii_se_row_t;

#define R(r) (1u << (r))
#define ALL_RINGS (R(III_RING_R_MINUS_2) | R(III_RING_R_MINUS_1) | R(III_RING_R0) | R(III_RING_R3))

static const iii_se_row_t SE_TABLE[] = {
    { III_SE_NONE,             "III_SE_NONE",             "",            "NONE",
      0, III_SE_NONE, NULL, III_COMP_NONE, III_PIP_NONE },

    { III_SE_MSR_WRITE,        "III_SE_MSR_WRITE",        "msr_write",   "MSR_WRITE",
      R(III_RING_R_MINUS_2)|R(III_RING_R_MINUS_1),
      III_SE_MSR_WRITE, "msr_write", III_COMP_NONE, III_PIP_STATIC_BYTES },

    { III_SE_CR_WRITE,         "III_SE_CR_WRITE",         "cr_write",    "CR_WRITE",
      R(III_RING_R_MINUS_1),
      III_SE_CR_WRITE, "cr_write", III_COMP_NONE, III_PIP_STATIC_BYTES },

    { III_SE_NPT_ENTRY_WRITE,  "III_SE_NPT_ENTRY_WRITE",  "npt_write",   "NPT_ENTRY",
      R(III_RING_R_MINUS_1),
      III_SE_NPT_ENTRY_WRITE, "npt_write", III_COMP_NONE, III_PIP_STATIC_BYTES },

    { III_SE_VMCB_FIELD_WRITE, "III_SE_VMCB_FIELD_WRITE", "vmcb_field",  "VMCB_FIELD",
      R(III_RING_R_MINUS_1),
      III_SE_VMCB_FIELD_WRITE, "vmcb_field", III_COMP_NONE, III_PIP_STATIC_BYTES },

    { III_SE_IOMMU_DTE_WORD,   "III_SE_IOMMU_DTE_WORD",   "iommu_dte",   "IOMMU_DTE",
      R(III_RING_R_MINUS_1),
      III_SE_IOMMU_DTE_WORD, "iommu_dte", III_COMP_NONE, III_PIP_STATIC_BYTES },

    { III_SE_AVIC_TBL_WRITE,   "III_SE_AVIC_TBL_WRITE",   "avic_tbl",    "AVIC_TBL",
      R(III_RING_R_MINUS_1),
      III_SE_AVIC_TBL_WRITE, "avic_tbl", III_COMP_NONE, III_PIP_STATIC_BYTES },

    { III_SE_MSRPM_BIT_SET,    "III_SE_MSRPM_BIT_SET",    "msrpm_bit",   "MSRPM_BIT",
      R(III_RING_R_MINUS_1),
      III_SE_MSRPM_BIT_SET, "msrpm_bit", III_COMP_NONE, III_PIP_STATIC_BYTES },

    { III_SE_IOPM_BIT_SET,     "III_SE_IOPM_BIT_SET",     "iopm_bit",    "IOPM_BIT",
      R(III_RING_R_MINUS_1),
      III_SE_IOPM_BIT_SET, "iopm_bit", III_COMP_NONE, III_PIP_STATIC_BYTES },

    { III_SE_PKRU_WRITE,       "III_SE_PKRU_WRITE",       "pkru_write",  "PKRU_WRITE",
      R(III_RING_R_MINUS_1)|R(III_RING_R0),
      III_SE_PKRU_WRITE, "pkru_write", III_COMP_NONE, III_PIP_STATIC_BYTES },

    { III_SE_XCR0_WRITE,       "III_SE_XCR0_WRITE",       "xcr0_write",  "XCR0_WRITE",
      R(III_RING_R_MINUS_1),
      III_SE_XCR0_WRITE, "xcr0_write", III_COMP_NONE, III_PIP_STATIC_BYTES },

    { III_SE_CAP_ACQUIRE,      "III_SE_CAP_ACQUIRE",      "cap_acquire", "CAP_ACQUIRE",
      ALL_RINGS,
      III_SE_CAP_RELEASE, "cap_release", III_COMP_NONE, III_PIP_DYNAMIC_FN },

    { III_SE_CAP_RELEASE,      "III_SE_CAP_RELEASE",      "cap_release", "CAP_RELEASE",
      ALL_RINGS,
      III_SE_CAP_ACQUIRE, "cap_acquire", III_COMP_NONE, III_PIP_DYNAMIC_FN },

    { III_SE_PAGE_ALLOC,       "III_SE_PAGE_ALLOC",       "page_alloc",  "PAGE_ALLOC",
      R(III_RING_R0),
      III_SE_PAGE_FREE, "page_free", III_COMP_NONE, III_PIP_DYNAMIC_FN },

    { III_SE_PAGE_FREE,        "III_SE_PAGE_FREE",        "page_free",   "PAGE_FREE",
      R(III_RING_R0),
      III_SE_PAGE_ALLOC, "page_alloc", III_COMP_NONE, III_PIP_DYNAMIC_FN },

    { III_SE_DPC_ARM,          "III_SE_DPC_ARM",          "dpc_arm",     "DPC_ARM",
      R(III_RING_R0),
      III_SE_DPC_CANCEL, "dpc_cancel", III_COMP_NONE, III_PIP_DYNAMIC_FN },

    { III_SE_DPC_CANCEL,       "III_SE_DPC_CANCEL",       "dpc_cancel",  "DPC_CANCEL",
      R(III_RING_R0),
      III_SE_DPC_ARM, "dpc_arm", III_COMP_NONE, III_PIP_DYNAMIC_FN },

    /* §1.1 row 17: SID-derived inverse method is `nmi_remove` which is
     * not in the enumerated 17.  The forward kind is self-paired for
     * Möbius involution closure; the inverse method string is preserved. */
    { III_SE_NMI_INSTALL,      "III_SE_NMI_INSTALL",      "nmi_install", "NMI_INSTALL",
      R(III_RING_R_MINUS_1),
      III_SE_NMI_INSTALL, "nmi_remove", III_COMP_NONE, III_PIP_DYNAMIC_FN }
};
#define SE_TABLE_LEN (sizeof(SE_TABLE)/sizeof(SE_TABLE[0]))

static const iii_se_row_t *se_row(iii_se_kind_t k) {
    for (size_t i = 0; i < SE_TABLE_LEN; ++i)
        if (SE_TABLE[i].kind == k) return &SE_TABLE[i];
    return NULL;
}

const char *iii_se_kind_name(iii_se_kind_t k) {
    const iii_se_row_t *r = se_row(k);
    if (r) return r->name;
    if (k >= III_SE_RESERVED_BASE && k < III_SE_RESERVED__END)
        return "III_SE_PROMOTED";
    return "III_SE_UNKNOWN";
}

iii_se_kind_t iii_se_kind_from_method(const char *method, size_t len) {
    if (!method || len == 0) return III_SE_NONE;
    for (size_t i = 0; i < SE_TABLE_LEN; ++i) {
        const char *m = SE_TABLE[i].method;
        if (!m || !*m) continue;
        if (strlen(m) == len && memcmp(m, method, len) == 0)
            return SE_TABLE[i].kind;
    }
    return III_SE_NONE;
}

const char *iii_se_kind_method(iii_se_kind_t k) {
    const iii_se_row_t *r = se_row(k);
    return r ? r->method : "";
}

/* ---------------------------------------------------------------------- */
/* §1.2 — Compromise                                                       */
/* ---------------------------------------------------------------------- */

const char *iii_compromise_name(iii_compromise_t c) {
    switch (c) {
        case III_COMP_NONE:   return "NONE";
        case III_COMP_LOW:    return "LOW";
        case III_COMP_MEDIUM: return "MEDIUM";
        case III_COMP_HIGH:   return "HIGH";
        default:              return "UNKNOWN";
    }
}

iii_compromise_t iii_effect_compromise_join(iii_compromise_t a, iii_compromise_t b) {
    return (a > b) ? a : b;
}

bool iii_compromise_inhabited(iii_compromise_t c) {
    /* §1.2 / §1.3: HIGH is uninhabited (unrepresentable). */
    return c != III_COMP_HIGH;
}

/* ---------------------------------------------------------------------- */
/* §3 — PIP                                                                */
/* ---------------------------------------------------------------------- */

const char *iii_pip_class_name(iii_pip_class_t c) {
    switch (c) {
        case III_PIP_NONE:         return "NONE";
        case III_PIP_STATIC_BYTES: return "STATIC_BYTES";
        case III_PIP_DYNAMIC_FN:   return "DYNAMIC_FN";
        case III_PIP_COMPOSED:     return "COMPOSED";
        default:                   return "UNKNOWN";
    }
}

iii_pip_class_t iii_pip_classify(iii_se_kind_t k) {
    const iii_se_row_t *r = se_row(k);
    return r ? r->pip : III_PIP_NONE;
}

struct iii_pip_blob {
    iii_pip_class_t cls;
    /* STATIC_BYTES */
    uint8_t        *bytes;
    size_t          bytes_len;
    /* DYNAMIC_FN */
    iii_se_kind_t   dynfn_kind;
    /* COMPOSED */
    iii_pip_blob_t **inners;
    size_t          inner_count, inner_cap;
};

iii_pip_blob_t *iii_pip_blob_new_static(const uint8_t *prior, size_t len) {
    iii_pip_blob_t *b = (iii_pip_blob_t*)calloc(1, sizeof *b);
    if (!b) return NULL;
    b->cls = III_PIP_STATIC_BYTES;
    if (len > 0) {
        b->bytes = (uint8_t*)malloc(len);
        if (!b->bytes) { free(b); return NULL; }
        if (prior) memcpy(b->bytes, prior, len);
        else       memset(b->bytes, 0, len);
        b->bytes_len = len;
    }
    return b;
}

iii_pip_blob_t *iii_pip_blob_new_dynfn(iii_se_kind_t inverse_kind) {
    iii_pip_blob_t *b = (iii_pip_blob_t*)calloc(1, sizeof *b);
    if (!b) return NULL;
    b->cls = III_PIP_DYNAMIC_FN;
    b->dynfn_kind = inverse_kind;
    return b;
}

iii_pip_blob_t *iii_pip_blob_new_composed(void) {
    iii_pip_blob_t *b = (iii_pip_blob_t*)calloc(1, sizeof *b);
    if (!b) return NULL;
    b->cls = III_PIP_COMPOSED;
    return b;
}

int iii_pip_blob_compose_push(iii_pip_blob_t *outer, iii_pip_blob_t *inner) {
    if (!outer || !inner || outer->cls != III_PIP_COMPOSED) return -1;
    if (outer->inner_count == outer->inner_cap) {
        size_t nc = outer->inner_cap ? outer->inner_cap * 2 : 4;
        iii_pip_blob_t **n = (iii_pip_blob_t**)realloc(outer->inners, nc * sizeof *n);
        if (!n) return -1;
        outer->inners = n; outer->inner_cap = nc;
    }
    outer->inners[outer->inner_count++] = inner;
    return 0;
}

void iii_pip_blob_destroy(iii_pip_blob_t *b) {
    if (!b) return;
    free(b->bytes);
    for (size_t i = 0; i < b->inner_count; ++i) iii_pip_blob_destroy(b->inners[i]);
    free(b->inners);
    free(b);
}

iii_pip_class_t iii_pip_blob_class(const iii_pip_blob_t *b) { return b ? b->cls : III_PIP_NONE; }
size_t          iii_pip_blob_size (const iii_pip_blob_t *b) {
    if (!b) return 0;
    if (b->cls == III_PIP_COMPOSED) return b->inner_count;
    return b->bytes_len;
}
const uint8_t  *iii_pip_blob_bytes(const iii_pip_blob_t *b) { return b ? b->bytes : NULL; }
iii_se_kind_t   iii_pip_blob_dynfn_kind(const iii_pip_blob_t *b) {
    return b ? b->dynfn_kind : III_SE_NONE;
}

iii_se_kind_t iii_pip_blob_reconstruct_kind(const iii_pip_blob_t *b,
                                            iii_se_kind_t forward_kind) {
    if (!b) return III_SE_NONE;
    switch (b->cls) {
        case III_PIP_STATIC_BYTES:
            /* register/MSR restore: inverse SE kind = forward (self-inverse). */
            return forward_kind;
        case III_PIP_DYNAMIC_FN:
            return b->dynfn_kind;
        case III_PIP_COMPOSED:
            if (b->inner_count == 0) return III_SE_NONE;
            return iii_pip_blob_reconstruct_kind(b->inners[0], forward_kind);
        default: return III_SE_NONE;
    }
}

/* ---------------------------------------------------------------------- */
/* §5 — Epistemic                                                          */
/* ---------------------------------------------------------------------- */

bool iii_epistemic_escalates(iii_uncertainty_t u) {
    if (u.confidence_q14 < III_CONFIDENCE_Q_THRESHOLD) return true;
    if (u.question_count > 0) return true;
    return false;
}

iii_uncertainty_t iii_epistemic_compose(iii_uncertainty_t a, iii_uncertainty_t b) {
    iii_uncertainty_t r;
    r.confidence_q14 = a.confidence_q14 < b.confidence_q14 ? a.confidence_q14 : b.confidence_q14;
    r.question_count = (uint32_t)(a.question_count + b.question_count);
    r.domain_id = (a.domain_id != 0) ? a.domain_id : b.domain_id;
    return r;
}

/* ---------------------------------------------------------------------- */
/* §1, §2 — Effect row + IRPD discipline                                  */
/* ---------------------------------------------------------------------- */

uint8_t iii_irpd_admissible_rings(iii_se_kind_t k) {
    const iii_se_row_t *r = se_row(k);
    return r ? r->rings : 0;
}

bool iii_irpd_admissible_at(iii_se_kind_t k, iii_ring_t at) {
    return (iii_irpd_admissible_rings(k) & (1u << (unsigned)at)) != 0;
}

const char *iii_irpd_inverse_method(iii_se_kind_t k) {
    const iii_se_row_t *r = se_row(k);
    return r ? r->inv_method : NULL;
}

iii_se_kind_t iii_irpd_inverse_kind(iii_se_kind_t k) {
    const iii_se_row_t *r = se_row(k);
    return r ? r->inverse : III_SE_NONE;
}

const char *iii_irpd_hexad_name(iii_se_kind_t k) {
    const iii_se_row_t *r = se_row(k);
    return r ? r->hexad_name : "UNKNOWN";
}

iii_compromise_t iii_irpd_default_tier(iii_se_kind_t k) {
    const iii_se_row_t *r = se_row(k);
    return r ? r->default_tier : III_COMP_NONE;
}

iii_effect_t iii_effect_make(iii_se_kind_t kind) {
    iii_effect_t e;
    memset(&e, 0, sizeof e);
    e.kind = kind;
    e.compromise = iii_irpd_default_tier(kind);
    e.pip = iii_pip_classify(kind);
    e.ghost = false;
    e.mobius = false;
    e.uncertainty.confidence_q14 = III_CONFIDENCE_Q_DENOM; /* 1.0 = certain */
    e.ring_set.mask = iii_irpd_admissible_rings(kind);
    e.witness_ref = 0;
    return e;
}

bool iii_effect_eq(const iii_effect_t *a, const iii_effect_t *b) {
    if (!a || !b) return a == b;
    return a->kind == b->kind &&
           a->compromise == b->compromise &&
           a->pip == b->pip &&
           a->ghost == b->ghost &&
           a->mobius == b->mobius &&
           a->uncertainty.confidence_q14 == b->uncertainty.confidence_q14 &&
           a->uncertainty.question_count == b->uncertainty.question_count &&
           a->uncertainty.domain_id == b->uncertainty.domain_id &&
           a->ring_set.mask == b->ring_set.mask &&
           a->witness_ref == b->witness_ref;
}

int iii_effect_cmp(const iii_effect_t *a, const iii_effect_t *b) {
    if (a->kind != b->kind) return (a->kind < b->kind) ? -1 : 1;
    if (a->compromise != b->compromise)
        return (a->compromise < b->compromise) ? -1 : 1;
    if (a->witness_ref != b->witness_ref)
        return (a->witness_ref < b->witness_ref) ? -1 : 1;
    return 0;
}

uint32_t iii_effect_runtime_witness(const iii_effect_t *e) {
    if (!e) return 0;
    /* §4.2 — Ghost effects elide the runtime witness. */
    if (e->ghost) return 0;
    return e->witness_ref;
}

bool iii_effect_check_irpd(const iii_effect_t *e, iii_ring_t at) {
    if (!e) return false;
    if (e->kind == III_SE_NONE) return true;
    /* HIGH is uninhabited per §1.2/§1.3 — no admissible IRPD. */
    if (e->compromise == III_COMP_HIGH) return false;
    if (!iii_irpd_admissible_at(e->kind, at)) return false;
    /* Möbius-promoted reserved kinds are admissible at every ring by
     * construction (the Catalyst only promotes admissible decompositions). */
    if (e->kind >= III_SE_RESERVED_BASE && e->kind < III_SE_RESERVED__END)
        return true;
    return true;
}

/* ---------------------------------------------------------------------- */
/* §6 — Möbius involution + Catalyst pool                                  */
/* ---------------------------------------------------------------------- */

iii_effect_t iii_effect_mobius_inverse(iii_effect_t e) {
    iii_se_kind_t inv = iii_irpd_inverse_kind(e.kind);
    iii_effect_t r = iii_effect_make(inv);
    r.compromise  = e.compromise;
    r.ghost       = e.ghost;
    r.mobius      = e.mobius;
    r.uncertainty = e.uncertainty;
    r.witness_ref = e.witness_ref;
    return r;
}

struct iii_effect_catalyst {
    iii_se_kind_t     kinds[III_SE_RESERVED_SLOTS];
    char             *names[III_SE_RESERVED_SLOTS];
    iii_effect_t      meta [III_SE_RESERVED_SLOTS];
    size_t            count;
};

iii_effect_catalyst_t *iii_effect_catalyst_create(void) {
    iii_effect_catalyst_t *c = (iii_effect_catalyst_t*)calloc(1, sizeof *c);
    return c;
}

void iii_effect_catalyst_destroy(iii_effect_catalyst_t *c) {
    if (!c) return;
    for (size_t i = 0; i < c->count; ++i) free(c->names[i]);
    free(c);
}

iii_se_kind_t iii_effect_promote_dynamic(iii_effect_catalyst_t *c,
                                         const iii_effect_t *candidate,
                                         const char *name) {
    if (!c || !candidate) return III_SE_NONE;
    /* §6.3 — full Catalyst pipeline gates: trinity_admit + ceiling_admit +
     * codegen_validation.  At the type-system layer we enforce the
     * representability prerequisites: no HIGH compromise, the candidate
     * must declare itself a mobius_candidate, and reserved-band capacity. */
    if (candidate->compromise == III_COMP_HIGH) return III_SE_NONE;
    if (!candidate->mobius) return III_SE_NONE;
    if (c->count >= III_SE_RESERVED_SLOTS) return III_SE_NONE;
    iii_se_kind_t k = (iii_se_kind_t)(III_SE_RESERVED_BASE + c->count);
    c->kinds[c->count] = k;
    c->meta [c->count] = *candidate;
    c->meta [c->count].kind = k;
    if (name) {
        size_t L = strlen(name);
        c->names[c->count] = (char*)malloc(L + 1);
        if (c->names[c->count]) memcpy(c->names[c->count], name, L + 1);
    } else {
        c->names[c->count] = NULL;
    }
    c->count++;
    return k;
}

const char *iii_effect_catalyst_name(const iii_effect_catalyst_t *c,
                                     iii_se_kind_t k) {
    if (!c) return NULL;
    for (size_t i = 0; i < c->count; ++i)
        if (c->kinds[i] == k) return c->names[i];
    return NULL;
}

size_t iii_effect_catalyst_count(const iii_effect_catalyst_t *c) {
    return c ? c->count : 0;
}

/* ---------------------------------------------------------------------- */
/* §7 — Effect set                                                         */
/* ---------------------------------------------------------------------- */

struct iii_effect_set {
    iii_effect_t *items;
    size_t count, cap;
    bool sorted;
};

iii_effect_set_t *iii_effect_set_create(void) {
    iii_effect_set_t *s = (iii_effect_set_t*)calloc(1, sizeof *s);
    if (s) s->sorted = true;
    return s;
}

void iii_effect_set_destroy(iii_effect_set_t *s) {
    if (!s) return;
    free(s->items);
    free(s);
}

size_t iii_effect_set_size(const iii_effect_set_t *s) { return s ? s->count : 0; }
const iii_effect_t *iii_effect_set_at(const iii_effect_set_t *s, size_t i) {
    if (!s || i >= s->count) return NULL;
    return &s->items[i];
}

int iii_effect_set_add(iii_effect_set_t *s, iii_effect_t e) {
    if (!s) return -1;
    if (s->count == s->cap) {
        size_t nc = s->cap ? s->cap * 2 : 8;
        iii_effect_t *n = (iii_effect_t*)realloc(s->items, nc * sizeof *n);
        if (!n) return -1;
        s->items = n; s->cap = nc;
    }
    s->items[s->count++] = e;
    s->sorted = false;
    return 0;
}

static int eff_cmp_qsort(const void *a, const void *b) {
    return iii_effect_cmp((const iii_effect_t*)a, (const iii_effect_t*)b);
}

void iii_effect_set_sort(iii_effect_set_t *s) {
    if (!s || s->sorted) return;
    if (s->count > 1) qsort(s->items, s->count, sizeof(iii_effect_t), eff_cmp_qsort);
    s->sorted = true;
}

bool iii_effect_set_contains(const iii_effect_set_t *s, const iii_effect_t *e) {
    if (!s || !e) return false;
    for (size_t i = 0; i < s->count; ++i)
        if (iii_effect_eq(&s->items[i], e)) return true;
    return false;
}

bool iii_effect_set_equal(const iii_effect_set_t *a, const iii_effect_set_t *b) {
    if (!a || !b) return a == b;
    if (a->count != b->count) return false;
    /* Canonical equality: sort copies, compare element-wise. */
    iii_effect_t *ca = NULL, *cb = NULL;
    bool eq = true;
    if (a->count > 0) {
        ca = (iii_effect_t*)malloc(a->count * sizeof *ca);
        cb = (iii_effect_t*)malloc(b->count * sizeof *cb);
        if (!ca || !cb) { free(ca); free(cb); return false; }
        memcpy(ca, a->items, a->count * sizeof *ca);
        memcpy(cb, b->items, b->count * sizeof *cb);
        qsort(ca, a->count, sizeof *ca, eff_cmp_qsort);
        qsort(cb, b->count, sizeof *cb, eff_cmp_qsort);
        for (size_t i = 0; i < a->count; ++i) {
            if (!iii_effect_eq(&ca[i], &cb[i])) { eq = false; break; }
        }
    }
    free(ca); free(cb);
    return eq;
}

bool iii_effect_set_subset(const iii_effect_set_t *a, const iii_effect_set_t *b) {
    if (!a || !b) return false;
    for (size_t i = 0; i < a->count; ++i)
        if (!iii_effect_set_contains(b, &a->items[i])) return false;
    return true;
}

iii_effect_set_t *iii_effect_set_union(const iii_effect_set_t *a, const iii_effect_set_t *b) {
    iii_effect_set_t *u = iii_effect_set_create();
    if (!u) return NULL;
    if (a) for (size_t i = 0; i < a->count; ++i)
        if (!iii_effect_set_contains(u, &a->items[i])) iii_effect_set_add(u, a->items[i]);
    if (b) for (size_t i = 0; i < b->count; ++i)
        if (!iii_effect_set_contains(u, &b->items[i])) iii_effect_set_add(u, b->items[i]);
    iii_effect_set_sort(u);
    return u;
}

iii_compromise_t iii_effect_set_max_compromise(const iii_effect_set_t *s) {
    iii_compromise_t m = III_COMP_NONE;
    if (!s) return m;
    for (size_t i = 0; i < s->count; ++i)
        m = iii_effect_compromise_join(m, s->items[i].compromise);
    return m;
}

/* ---------------------------------------------------------------------- */
/* §8 — Inference                                                          */
/* ---------------------------------------------------------------------- */

struct iii_effect_env {
    iii_parser_t          *parser;
    iii_effect_catalyst_t *catalyst;
    /* Modifier flags inherited from the enclosing function/cycle. */
    bool   in_pure;
    bool   in_witness_elide;
    bool   in_irreversible;
    bool   in_mobius_candidate;
    bool   in_uncertain;
    iii_uncertainty_t  carrier;
    uint32_t next_witness;
};

iii_effect_env_t *iii_effect_env_create(iii_parser_t *parser,
                                        iii_effect_catalyst_t *catalyst) {
    iii_effect_env_t *e = (iii_effect_env_t*)calloc(1, sizeof *e);
    if (!e) return NULL;
    e->parser = parser;
    e->catalyst = catalyst;
    e->carrier.confidence_q14 = III_CONFIDENCE_Q_DENOM;
    e->next_witness = 1;
    return e;
}

void iii_effect_env_destroy(iii_effect_env_t *e) { free(e); }

/* Modifier name resolution.  Returns NULL when no parser is bound or the
 * id can't be resolved. */
static const char *resolve_intern(iii_effect_env_t *env, uint32_t id, size_t *outlen) {
    if (!env || !env->parser) { if (outlen) *outlen = 0; return NULL; }
    return iii_parser_intern(env->parser, id, outlen);
}

static bool name_is(const char *p, size_t len, const char *lit) {
    if (!p) return false;
    size_t L = strlen(lit);
    return len == L && memcmp(p, lit, L) == 0;
}

/* Apply enclosing modifiers to a fresh effect: ghost, compromise, mobius,
 * epistemic carrier — per §3..§6. */
static void apply_env_to_effect(iii_effect_env_t *env, iii_effect_t *e) {
    if (env->in_pure && env->in_witness_elide) e->ghost = true;
    if (env->in_irreversible) {
        e->compromise = iii_effect_compromise_join(e->compromise, III_COMP_LOW);
    }
    if (env->in_mobius_candidate) e->mobius = true;
    if (env->in_uncertain) e->uncertainty = env->carrier;
    e->pip = iii_pip_classify(e->kind);
}

/* Walk modifiers attached to a node, set env flags for the recursion. */
typedef struct { bool pure, elide, irrev, mobius; } mod_flags_t;

static mod_flags_t scan_modifiers(iii_effect_env_t *env, iii_ast_node_t *parent,
                                  iii_ast_kind_t mk) {
    mod_flags_t f = { false, false, false, false };
    if (!parent) return f;
    for (uint32_t i = 0; i < parent->child_count; ++i) {
        iii_ast_node_t *c = parent->children[i];
        if (!c || c->kind != mk) continue;
        size_t L = 0;
        const char *t = resolve_intern(env, c->interned_id, &L);
        if (!t) continue;
        if (name_is(t, L, "@pure"))                     f.pure = true;
        else if (name_is(t, L, "@witness_elide"))       f.elide = true;
        else if (name_is(t, L, "@irreversible"))        f.irrev = true;
        else if (name_is(t, L, "@candidate_for_promotion")) f.mobius = true;
    }
    return f;
}

/* Recursive walk: find IRPD calls and add to set. */
static void infer_walk(iii_effect_env_t *env, iii_ast_node_t *n,
                       iii_effect_set_t *out) {
    if (!n) return;
    if (n->kind == III_AST_IRPD_CALL) {
        size_t L = 0;
        const char *m = resolve_intern(env, n->interned_id, &L);
        iii_se_kind_t k = (m && L > 0) ? iii_se_kind_from_method(m, L) : III_SE_NONE;
        iii_effect_t e = iii_effect_make(k);
        e.site_line = n->line;
        e.site_col  = n->col;
        e.witness_ref = env->next_witness++;
        apply_env_to_effect(env, &e);
        iii_effect_set_add(out, e);
        /* don't recurse into args (no further IRPD calls expected, but
         * guard explicitly to keep the witness ordering tight). */
    }
    for (uint32_t i = 0; i < n->child_count; ++i)
        infer_walk(env, n->children[i], out);
}

iii_effect_set_t *iii_effect_infer(iii_effect_env_t *env, iii_ast_node_t *node) {
    iii_effect_set_t *s = iii_effect_set_create();
    if (!s || !env) return s;

    /* For function/cycle/mobius_candidate roots, capture modifiers first. */
    bool save_pure = env->in_pure, save_elide = env->in_witness_elide;
    bool save_irrev = env->in_irreversible, save_mob = env->in_mobius_candidate;
    if (node) {
        mod_flags_t f = { false, false, false, false };
        switch (node->kind) {
            case III_AST_FUNCTION_DECL:
                f = scan_modifiers(env, node, III_AST_FUNCTION_MODIFIER); break;
            case III_AST_CYCLE_DECL:
                f = scan_modifiers(env, node, III_AST_CYCLE_MODIFIER); break;
            case III_AST_MOBIUS_CANDIDATE_DECL:
                f = scan_modifiers(env, node, III_AST_MOBIUS_CANDIDATE_MODIFIER);
                f.mobius = true;
                break;
            default: break;
        }
        env->in_pure            = env->in_pure || f.pure;
        env->in_witness_elide   = env->in_witness_elide || f.elide;
        env->in_irreversible    = env->in_irreversible || f.irrev;
        env->in_mobius_candidate = env->in_mobius_candidate || f.mobius;
    }
    infer_walk(env, node, s);
    env->in_pure = save_pure; env->in_witness_elide = save_elide;
    env->in_irreversible = save_irrev; env->in_mobius_candidate = save_mob;
    iii_effect_set_sort(s);
    return s;
}

void iii_effect_for_each_function(iii_effect_env_t *env,
                                  iii_ast_node_t *root,
                                  iii_effect_per_fn_cb cb,
                                  void *ud) {
    if (!env || !root || !cb) return;
    if (root->kind != III_AST_MODULE) {
        if (root->kind == III_AST_FUNCTION_DECL ||
            root->kind == III_AST_CYCLE_DECL    ||
            root->kind == III_AST_MOBIUS_CANDIDATE_DECL) {
            iii_effect_set_t *s = iii_effect_infer(env, root);
            size_t L = 0;
            const char *nm = resolve_intern(env, root->interned_id, &L);
            cb(nm ? nm : "<anon>", nm ? L : 6, s, ud);
        }
        return;
    }
    for (uint32_t i = 0; i < root->child_count; ++i) {
        iii_ast_node_t *c = root->children[i];
        if (!c) continue;
        if (c->kind != III_AST_FUNCTION_DECL &&
            c->kind != III_AST_CYCLE_DECL    &&
            c->kind != III_AST_MOBIUS_CANDIDATE_DECL) continue;
        iii_effect_set_t *s = iii_effect_infer(env, c);
        size_t L = 0;
        const char *nm = resolve_intern(env, c->interned_id, &L);
        cb(nm ? nm : "<anon>", nm ? L : 6, s, ud);
    }
}

/* ---------------------------------------------------------------------- */
/* §10 — R1.A4 hash                                                        */
/* ---------------------------------------------------------------------- */

int iii_r1_a4_hash_file(const char *path, uint8_t out[32]) {
    if (!path || !out) return -1;
    FILE *f = fopen(path, "rb");
    if (!f) return -2;
    iii_sha256_ctx_t ctx;
    iii_sha256_init(&ctx);
    uint8_t buf[4096];
    size_t n;
    while ((n = fread(buf, 1, sizeof buf, f)) > 0)
        iii_sha256_update(&ctx, buf, n);
    int err = ferror(f);
    fclose(f);
    if (err) return -3;
    iii_sha256_final(&ctx, out);
    return 0;
}
