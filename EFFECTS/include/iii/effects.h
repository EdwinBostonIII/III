/* III EFFECTS — public API.
 *
 * Implements DOCS/III-EFFECTS.md (R1.A4):
 *
 *   §1.1  17 SE (side-effect) kinds — IRPD-only.
 *   §1.2  3 Compromise tiers (LOW / MEDIUM / HIGH-uninhabited).
 *   §1.3  Proof of unrepresentability (delegates to TYPES hexad bitmap).
 *   §2    The IRPD discipline — admissible-ring tables + SID-derived inverses.
 *   §3    PIP — Predictive Inverse Pre-Materialization.
 *   §4    Ghost effects — witness elision with audit reconstructability.
 *   §5    Epistemic effects — uncertainty-band carriers.
 *   §6    Möbius effects — self-extending (dynamic SE-kind promotion).
 *   §7    Wavefront / effect-set algebra (union, subset, equality, sort).
 *   §8    Effect algebra judgments at the API surface.
 *
 * NIH discipline: only libc + libiii_lex + libiii_grammar + libiii_types.
 */
#ifndef III_EFFECTS_H
#define III_EFFECTS_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

#include <iii/types.h>
#include <iii/types_hexad.h>
#include <iii/ast.h>
#include <iii/parser.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ====================================================================== */
/* §1.1 — The 17 SE Kinds (IRPD-Only)                                     */
/* ====================================================================== */

typedef enum iii_se_kind {
    III_SE_NONE              = 0,   /* no privileged effect (pure code) */
    III_SE_MSR_WRITE         = 1,
    III_SE_CR_WRITE          = 2,
    III_SE_NPT_ENTRY_WRITE   = 3,
    III_SE_VMCB_FIELD_WRITE  = 4,
    III_SE_IOMMU_DTE_WORD    = 5,
    III_SE_AVIC_TBL_WRITE    = 6,
    III_SE_MSRPM_BIT_SET     = 7,
    III_SE_IOPM_BIT_SET      = 8,
    III_SE_PKRU_WRITE        = 9,
    III_SE_XCR0_WRITE        = 10,
    III_SE_CAP_ACQUIRE       = 11,
    III_SE_CAP_RELEASE       = 12,
    III_SE_PAGE_ALLOC        = 13,
    III_SE_PAGE_FREE         = 14,
    III_SE_DPC_ARM           = 15,
    III_SE_DPC_CANCEL        = 16,
    III_SE_NMI_INSTALL       = 17,
    III_SE_KIND__BUILTIN     = 18,    /* sentinel: end of frozen 17 + NONE */

    /* §6.3 — Möbius reserved promotion band 0x01C7..0x01CF (9 slots). */
    III_SE_RESERVED_0        = 0x01C7,
    III_SE_RESERVED_1        = 0x01C8,
    III_SE_RESERVED_2        = 0x01C9,
    III_SE_RESERVED_3        = 0x01CA,
    III_SE_RESERVED_4        = 0x01CB,
    III_SE_RESERVED_5        = 0x01CC,
    III_SE_RESERVED_6        = 0x01CD,
    III_SE_RESERVED_7        = 0x01CE,
    III_SE_RESERVED_8        = 0x01CF,
    III_SE_RESERVED__END     = 0x01D0
} iii_se_kind_t;

#define III_SE_BUILTIN_COUNT 17u
#define III_SE_RESERVED_BASE 0x01C7u
#define III_SE_RESERVED_SLOTS 9u

const char     *iii_se_kind_name(iii_se_kind_t k);
/* Look up SE kind from canonical IRPD method name (e.g. "msr_write"). */
iii_se_kind_t   iii_se_kind_from_method(const char *method, size_t len);
/* Canonical IRPD method-name string for a kind ("" for NONE/promoted). */
const char     *iii_se_kind_method(iii_se_kind_t k);

/* ====================================================================== */
/* §1.2 — Compromise Tiers                                                */
/* ====================================================================== */

typedef enum iii_compromise {
    III_COMP_NONE   = 0,   /* fully reversible (default for the 17 IRPDs) */
    III_COMP_LOW    = 1,   /* Compromise<LOW>    — best-known prior      */
    III_COMP_MEDIUM = 2,   /* Compromise<MEDIUM> — re-establish posture  */
    III_COMP_HIGH   = 3,   /* Compromise<HIGH>   — UNREACHABLE/uninhabited */
    III_COMP__COUNT = 4
} iii_compromise_t;

const char       *iii_compromise_name(iii_compromise_t c);
/* Monotone join (max).  Conformance C-EFF-2. */
iii_compromise_t  iii_effect_compromise_join(iii_compromise_t a,
                                             iii_compromise_t b);
/* C-EFF-7: HIGH cannot be constructed from a representable hexad. */
bool              iii_compromise_inhabited(iii_compromise_t c);

/* ====================================================================== */
/* §3 — PIP (Predictive Inverse Pre-Materialization) blob classes         */
/* ====================================================================== */

typedef enum iii_pip_class {
    III_PIP_NONE          = 0,   /* no inverse predicted (compromise/promoted) */
    III_PIP_STATIC_BYTES  = 1,   /* memcpy inverse (register/MSR restore)     */
    III_PIP_DYNAMIC_FN    = 2,   /* function-pointer inverse (paired methods) */
    III_PIP_COMPOSED      = 3    /* multi-step composed inverse               */
} iii_pip_class_t;

const char     *iii_pip_class_name(iii_pip_class_t c);
/* §3.3 — pip_classify per the SID-derived inverse for a given SE kind. */
iii_pip_class_t iii_pip_classify(iii_se_kind_t k);

/* A pre-materialized PIP blob.  STATIC_BYTES blobs carry a captured
 * prior-value buffer; DYNAMIC_FN blobs carry the inverse SE kind to
 * invoke; COMPOSED blobs carry an ordered list of sub-blobs. */
typedef struct iii_pip_blob iii_pip_blob_t;

iii_pip_blob_t *iii_pip_blob_new_static(const uint8_t *prior, size_t len);
iii_pip_blob_t *iii_pip_blob_new_dynfn (iii_se_kind_t inverse_kind);
iii_pip_blob_t *iii_pip_blob_new_composed(void);
int             iii_pip_blob_compose_push(iii_pip_blob_t *outer,
                                          iii_pip_blob_t *inner); /* takes ownership */
void            iii_pip_blob_destroy(iii_pip_blob_t *b);

iii_pip_class_t iii_pip_blob_class(const iii_pip_blob_t *b);
size_t          iii_pip_blob_size  (const iii_pip_blob_t *b);   /* bytes for STATIC_BYTES, count for COMPOSED */
const uint8_t  *iii_pip_blob_bytes (const iii_pip_blob_t *b);   /* STATIC_BYTES payload */
iii_se_kind_t   iii_pip_blob_dynfn_kind(const iii_pip_blob_t *b);

/* §3.4 — round-trip: classify+materialize an inverse, then reconstruct
 * the inverse SE kind from the blob.  For composed blobs returns the
 * outermost inner kind. */
iii_se_kind_t   iii_pip_blob_reconstruct_kind(const iii_pip_blob_t *b,
                                              iii_se_kind_t forward_kind);

/* ====================================================================== */
/* §5 — Epistemic effects: uncertainty carrier                            */
/* ====================================================================== */

#define III_CONFIDENCE_Q_DENOM     16384u  /* Q14 fixed-point denominator */
#define III_CONFIDENCE_Q_THRESHOLD 13926u  /* 0.85q  per §5.4 (default)   */

/* iii_epistemic_domain_t and iii_uncertainty_t are defined in
 * <iii/types.h> and re-used here without redefinition. */

/* §5.4 — does this carrier escalate to Trinity Layer-3? */
bool              iii_epistemic_escalates(iii_uncertainty_t u);
/* Compose two uncertainty carriers: take min confidence, sum questions,
 * keep dominant non-NONE domain. */
iii_uncertainty_t iii_epistemic_compose(iii_uncertainty_t a,
                                        iii_uncertainty_t b);

/* ====================================================================== */
/* §1, §2 — The Effect Row                                                */
/* ====================================================================== */

typedef struct iii_effect {
    iii_se_kind_t       kind;
    iii_compromise_t    compromise;
    iii_pip_class_t     pip;            /* SID-derived inverse class */
    bool                ghost;          /* §4 — witness elided      */
    bool                mobius;         /* §6 — mobius_candidate     */
    iii_uncertainty_t   uncertainty;    /* §5 — epistemic carrier    */
    iii_phase_set_t     ring_set;       /* admissible rings (per §2) */
    uint32_t            witness_ref;    /* synthetic mhash slot      */
    uint32_t            site_line;
    uint32_t            site_col;
} iii_effect_t;

/* Construct an effect row with admissible-ring set populated from the
 * IRPD table for `kind`; returns III_SE_NONE-shaped row for invalid. */
iii_effect_t      iii_effect_make(iii_se_kind_t kind);

bool              iii_effect_eq(const iii_effect_t *a, const iii_effect_t *b);
/* Canonical ordering for set sort: (kind, compromise, witness_ref). */
int               iii_effect_cmp(const iii_effect_t *a, const iii_effect_t *b);

/* §4 — runtime witness reference (0 if elided/ghost). */
uint32_t          iii_effect_runtime_witness(const iii_effect_t *e);

/* ====================================================================== */
/* §2 — IRPD discipline                                                   */
/* ====================================================================== */

/* Admissible-ring bitmask for a kind (over iii_ring_t indices). */
uint8_t           iii_irpd_admissible_rings(iii_se_kind_t k);
/* §2.2: rule (IRPD-Only) — admissible iff `at` is in the ring-set. */
bool              iii_irpd_admissible_at  (iii_se_kind_t k, iii_ring_t at);
/* SID-derived inverse method name (NULL if external-only). */
const char       *iii_irpd_inverse_method (iii_se_kind_t k);
/* SID-derived inverse SE kind (some are self-inverse, some paired). */
iii_se_kind_t     iii_irpd_inverse_kind   (iii_se_kind_t k);
/* Hexad designator name for the kind (per §1.1 column "Hexad Name"). */
const char       *iii_irpd_hexad_name     (iii_se_kind_t k);
/* Default compromise tier for the kind (NONE for the 17 reversible). */
iii_compromise_t  iii_irpd_default_tier   (iii_se_kind_t k);
/* C-EFF-1: validate an effect against the IRPD discipline at ring `at`. */
bool              iii_effect_check_irpd   (const iii_effect_t *e, iii_ring_t at);

/* ====================================================================== */
/* §6 — Möbius effects (self-extension)                                   */
/* ====================================================================== */

/* §6.3 — paired-effect involution: for paired kinds returns the partner;
 * for self-inverse kinds returns the same kind.  iii_effect_mobius_inverse
 * applied twice returns the original effect (Möbius round-trip). */
iii_effect_t      iii_effect_mobius_inverse(iii_effect_t e);

/* Catalyst extension state: pool of dynamically-promoted SE kinds in the
 * reserved band (§6.3, §11). */
typedef struct iii_effect_catalyst iii_effect_catalyst_t;

iii_effect_catalyst_t *iii_effect_catalyst_create(void);
void                   iii_effect_catalyst_destroy(iii_effect_catalyst_t *c);

/* §6 — promote a candidate effect: allocates a fresh SE kind in the
 * reserved band 0x01C7..0x01CF; returns the new kind, or III_SE_NONE on
 * exhaustion / failed admission.  `name` is borrowed as a UTF-8 label. */
iii_se_kind_t          iii_effect_promote_dynamic(iii_effect_catalyst_t *c,
                                                  const iii_effect_t *candidate,
                                                  const char *name);
/* Look up a promoted name. */
const char            *iii_effect_catalyst_name(const iii_effect_catalyst_t *c,
                                                iii_se_kind_t k);
size_t                 iii_effect_catalyst_count(const iii_effect_catalyst_t *c);

/* ====================================================================== */
/* §7 — Effect Set Algebra                                                */
/* ====================================================================== */

typedef struct iii_effect_set iii_effect_set_t;

iii_effect_set_t *iii_effect_set_create(void);
void              iii_effect_set_destroy(iii_effect_set_t *s);

size_t            iii_effect_set_size(const iii_effect_set_t *s);
const iii_effect_t *iii_effect_set_at(const iii_effect_set_t *s, size_t i);

int               iii_effect_set_add  (iii_effect_set_t *s, iii_effect_t e);
void              iii_effect_set_sort (iii_effect_set_t *s); /* canonical */
bool              iii_effect_set_contains(const iii_effect_set_t *s,
                                          const iii_effect_t *e);

/* Set algebra: equality after canonical sort; subset; union (allocates). */
bool              iii_effect_set_equal (const iii_effect_set_t *a,
                                        const iii_effect_set_t *b);
bool              iii_effect_set_subset(const iii_effect_set_t *a,
                                        const iii_effect_set_t *b); /* a ⊆ b */
iii_effect_set_t *iii_effect_set_union (const iii_effect_set_t *a,
                                        const iii_effect_set_t *b);

/* Highest compromise tier in the set (NONE if empty/all-NONE). */
iii_compromise_t  iii_effect_set_max_compromise(const iii_effect_set_t *s);

/* ====================================================================== */
/* Inference environment (binds AST -> effect-set inference)              */
/* ====================================================================== */

typedef struct iii_effect_env iii_effect_env_t;

/* Create an inference environment.  `parser` is BORROWED and used only
 * to resolve interned ids back to UTF-8 method names; pass NULL when
 * synthesising effects without a parsed AST. */
iii_effect_env_t *iii_effect_env_create(iii_parser_t *parser,
                                        iii_effect_catalyst_t *catalyst);
void              iii_effect_env_destroy(iii_effect_env_t *e);

/* §8 — `Γ ⊢ e : Reduction(...)` at the AST level: walk `node` and emit
 * one iii_effect_t per IRPD call site, modulated by the enclosing
 * cycle/function modifiers (@pure → ghost on @witness_elide; @irreversible
 * → COMPROMISE_LOW; @candidate_for_promotion → mobius; etc.). */
iii_effect_set_t *iii_effect_infer(iii_effect_env_t *e, iii_ast_node_t *node);

/* Per-function dump support: for a parsed module root, walk top-level
 * function/cycle decls, infer each, and invoke `cb(name, set, ud)`. */
typedef void (*iii_effect_per_fn_cb)(const char *name, size_t name_len,
                                     iii_effect_set_t *set, void *ud);
void              iii_effect_for_each_function(iii_effect_env_t *e,
                                               iii_ast_node_t *module_root,
                                               iii_effect_per_fn_cb cb,
                                               void *ud);

/* ====================================================================== */
/* §10 — Closure identity                                                 */
/* ====================================================================== */

/* R1.A4 = SHA-256 of canonical byte form of DOCS/III-EFFECTS.md.
 * Returns 0 on success, errno-like negative on failure to read file. */
int               iii_r1_a4_hash_file(const char *path, uint8_t out[32]);

#define III_EFFECTS_MODULE_NAME    "iii-effects"
#define III_EFFECTS_MODULE_VERSION "1.0.0"

#ifdef __cplusplus
}
#endif
#endif
