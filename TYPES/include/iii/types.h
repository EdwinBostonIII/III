/* III TYPES — public type-checker API.
 *
 * This is the canonical type system of III, as specified in
 * DOCS/III-TYPES.md (R1.A3).  It implements:
 *
 *   §2  Universe ladder  Prop / Type_0..Type_6  (predicative + impredicative top)
 *   §3  Reduction six-tuple (the heart of sovereign computation)
 *   §4  Hexad-tagged types + Representability theorem as a typing rule
 *   §5  Ring-typed values (dependent typing over the ring lattice)
 *   §6  Tier-typed and Epoch-typed values
 *   §7  Linear capabilities with glyph-bound identity
 *   §8  Epistemic / uncertainty types
 *   §9  Constitutional / Möbius / Trinity Prop types
 *   §10 Bidirectional inference + holes (N1) + typed-as-term lift (U1)
 *   §11 The Proof Layer (CIC fragment + native ternary kernel)
 *   §12 Three-pass type-checking algorithm (declaration / body / discharge)
 *
 * NIH discipline: only libc + libiii_lex + libiii_grammar.
 */
#ifndef III_TYPES_H
#define III_TYPES_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

#include "types_errors.h"
#include "types_hexad.h"
#include "types_term.h"

#include <iii/ast.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ------------------------------------------------------------------ */
/* §2 / §10.3 — Universe ladder + typed-as-term lift                  */
/* ------------------------------------------------------------------ */

typedef enum iii_universe {
    III_U_PROP   = -1,
    III_U_TYPE0  = 0,
    III_U_TYPE1  = 1,
    III_U_TYPE2  = 2,
    III_U_TYPE3  = 3,
    III_U_TYPE4  = 4,
    III_U_TYPE5  = 5,
    III_U_TYPE6  = 6
} iii_universe_t;

const char    *iii_universe_name(iii_universe_t u);
iii_universe_t iii_universe_succ(iii_universe_t u);              /* §2.1 */
iii_universe_t iii_universe_pi  (iii_universe_t i, iii_universe_t j); /* §2.4 */
bool           iii_universe_lift_allowed(iii_universe_t from, iii_universe_t to); /* §2.3 */

/* ------------------------------------------------------------------ */
/* §3, §4, §5, §6 — Phase / Tier / Epoch values                        */
/* ------------------------------------------------------------------ */

typedef enum iii_ring {
    III_RING_R_MINUS_2 = 0,
    III_RING_R_MINUS_1 = 1,
    III_RING_R0        = 2,
    III_RING_R3        = 3,
    III_RING__COUNT    = 4
} iii_ring_t;

typedef struct iii_phase_set {
    /* Bitmask over iii_ring_t. */
    uint8_t mask;
} iii_phase_set_t;

bool             iii_phase_set_valid(iii_phase_set_t s);
bool             iii_phase_set_eq(iii_phase_set_t a, iii_phase_set_t b);
bool             iii_phase_marshal_exists(iii_ring_t from, iii_ring_t to);
const char      *iii_ring_name(iii_ring_t r);

typedef enum iii_tier {
    III_TIER_TRANSIENT      = 0,
    III_TIER_HOST_FILE      = 1,
    III_TIER_FEDERATION     = 2,
    III_TIER_CONSTITUTIONAL = 3,
    III_TIER__COUNT         = 4
} iii_tier_t;

const char      *iii_tier_name(iii_tier_t t);
iii_tier_t       iii_tier_max(iii_tier_t a, iii_tier_t b);

typedef struct iii_epoch { uint64_t n; } iii_epoch_t;

/* ------------------------------------------------------------------ */
/* Type representation                                                 */
/* ------------------------------------------------------------------ */

typedef enum iii_type_kind {
    III_TY_UNIVERSE,         /* Prop, Type_i */
    III_TY_PRIM,             /* base scalar type (named) */
    III_TY_PI,               /* Π(x:A).B */
    III_TY_FUN,              /* simple A -> B (sugar for non-dependent Pi) */
    III_TY_TUPLE,            /* T1 × T2 × ... */
    III_TY_REDUCTION,        /* Reduction<F,I,W,H,P,E> : Type_6 */
    III_TY_CAP,              /* Cap<P,R> : Type_4 */
    III_TY_UNCERTAINTY,      /* Uncertainty(D,C,Q) : Type_0 */
    III_TY_PROP_FORM,        /* CeilingMembership / MöbiusCoherence / trinity_admit */
    III_TY_HEXAD_TAG,        /* T @safety(H) */
    III_TY_RING_TAG,         /* T @ring(R) */
    III_TY_TIER_TAG,         /* T @tier(K) */
    III_TY_EPOCH_TAG,        /* T @epoch(N) */
    III_TY_HOLE,             /* metavariable α */
    III_TY_NAMED,            /* type alias / declared inductive */
    III_TY_ERROR
} iii_type_kind_t;

typedef enum iii_prim_id {
    III_PRIM_UNIT      = 0,
    III_PRIM_BOOL      = 1,
    III_PRIM_I32       = 2,
    III_PRIM_I64       = 3,
    III_PRIM_U32       = 4,
    III_PRIM_U64       = 5,
    III_PRIM_Q14       = 6,
    III_PRIM_TRIT      = 7,
    III_PRIM_HEXAD     = 8,
    III_PRIM_PHASE     = 9,
    III_PRIM_TIER      = 10,
    III_PRIM_EPOCH     = 11,
    III_PRIM_WITNESS   = 12,
    III_PRIM_GLYPH     = 13,
    III_PRIM_MHASH     = 14,
    III_PRIM_STRING    = 15,
    III_PRIM_DOMAIN    = 16,
    III_PRIM_QUESTION  = 17,
    III_PRIM_RANGE     = 18,
    III_PRIM__COUNT    = 19
} iii_prim_id_t;

typedef enum iii_cap_perm {
    III_CAP_READ  = 0,
    III_CAP_WRITE = 1,
    III_CAP_EXEC  = 2,
    III_CAP_CYCLE = 3,
    III_CAP__COUNT = 4
} iii_cap_perm_t;

typedef enum iii_replicate_policy {
    III_REPL_NONE       = 0,
    III_REPL_LOCAL      = 1,
    III_REPL_BROADCAST  = 2,
    III_REPL_QUORUM_3   = 3,
    III_REPL_QUORUM_5   = 4
} iii_replicate_policy_t;

typedef enum iii_prop_kind {
    III_PROP_CEILING_MEMBERSHIP = 0,
    III_PROP_MOBIUS_COHERENCE   = 1,
    III_PROP_TRINITY_ADMIT      = 2,
    III_PROP_INTENT_ADMIT       = 3,
    III_PROP_CAP_ADMIT          = 4,
    III_PROP_CAUSALITY_ADMIT    = 5,
    III_PROP_SANCTUM_ADMIT      = 6,
    III_PROP_GLYPH_BOUND        = 7,
    III_PROP_ADMITTED_HEXAD     = 8,
    III_PROP_VALID_PHASE_SET    = 9,
    III_PROP_VALID_TIER         = 10,
    III_PROP_VALID_EPOCH        = 11,
    III_PROP__COUNT             = 12
} iii_prop_kind_t;

typedef struct iii_type iii_type_t;

typedef struct iii_uncertainty {
    uint32_t domain_id;       /* interned domain name */
    uint16_t confidence_q14;  /* 0..16384 representing [0,1] */
    uint32_t question_count;
} iii_uncertainty_t;

struct iii_type {
    iii_type_kind_t kind;
    iii_universe_t  univ;     /* universe this type *inhabits* */

    /* PRIM */
    iii_prim_id_t prim;

    /* PI / FUN */
    const char *binder_name;
    iii_type_t *dom;
    iii_type_t *cod;
    bool        dependent;     /* if false, equivalent to FUN */

    /* TUPLE */
    iii_type_t **elements;
    uint32_t     element_count;

    /* REDUCTION six-tuple components */
    iii_type_t  *r_forward;    /* F : Type_i */
    iii_type_t  *r_inverse;    /* I : Type_j */
    /* W: Witness primitive — implicit type (PRIM_WITNESS) */
    iii_hexad_t  r_hexad;
    bool         r_hexad_set;
    iii_phase_set_t r_phase;
    iii_epoch_t  r_epoch;
    /* §8 epistemic carrier */
    bool              r_has_uncertainty;
    iii_uncertainty_t r_uncertainty;

    /* CAP */
    iii_cap_perm_t          cap_perm;
    uint32_t                cap_range_id;       /* interned range descriptor */
    iii_replicate_policy_t  cap_replicates;     /* §7.4 */

    /* UNCERTAINTY */
    iii_uncertainty_t uncertainty;

    /* PROP_FORM */
    iii_prop_kind_t prop_kind;
    /* parameters of the proposition; semantics by prop_kind */
    uint16_t  prop_hexad_packed;
    uint16_t  prop_q14;
    uint64_t  prop_state_mhash_lo;   /* low 64 bits of S */
    uint8_t   prop_payload[16];
    uint32_t  prop_payload_len;

    /* HEXAD_TAG / RING_TAG / TIER_TAG / EPOCH_TAG */
    iii_type_t      *tag_inner;
    iii_hexad_t      tag_hexad;
    iii_phase_set_t  tag_phase;
    iii_tier_t       tag_tier;
    iii_epoch_t      tag_epoch;

    /* HOLE */
    uint32_t hole_id;
    iii_type_t *hole_solution;       /* NULL until solved */
    iii_universe_t hole_expected_univ;

    /* NAMED */
    uint32_t named_id;               /* interned name */
};

/* Universe of a type (§2). */
iii_universe_t iii_type_universe(const iii_type_t *t);

/* Structural equality up to renaming (used outside the CIC kernel). */
bool iii_type_eq(const iii_type_t *a, const iii_type_t *b);

/* Pretty-print to buffer; returns chars written. */
size_t iii_type_print(const iii_type_t *t, char *buf, size_t cap);

/* ------------------------------------------------------------------ */
/* Type-system context (env, arena, errors, hole table)                */
/* ------------------------------------------------------------------ */

typedef struct iii_type_env iii_type_env_t;

iii_type_env_t *iii_type_env_create(void);
void            iii_type_env_destroy(iii_type_env_t *e);

/* Set the current epoch ceiling (used by valid_epoch discharge). */
void iii_type_env_set_current_epoch(iii_type_env_t *e, uint64_t n);
/* Set the Möbius coherence floor (default 0.92q ≡ 15073/16384). */
void iii_type_env_set_coherence_floor(iii_type_env_t *e, uint16_t q14);
/* Set the uncertainty escalation threshold (default 0.85q ≡ 13927/16384). */
void iii_type_env_set_uncertainty_threshold(iii_type_env_t *e, uint16_t q14);

/* Bind a name in the local context.  Returns the de Bruijn level (0-based). */
uint32_t iii_type_env_bind(iii_type_env_t *e, uint32_t name_id, iii_type_t *t);
/* Bind a *linear* capability variable (consumed exactly once). */
uint32_t iii_type_env_bind_linear(iii_type_env_t *e, uint32_t name_id, iii_type_t *cap_ty);
/* Pop the most-recent binding (e.g. on leaving a scope). */
void     iii_type_env_pop(iii_type_env_t *e);
/* Lookup; returns NULL if unbound. */
iii_type_t *iii_type_env_lookup(iii_type_env_t *e, uint32_t name_id);
/* Mark a linear binding as used.  Returns false on second use. */
bool        iii_type_env_use_linear(iii_type_env_t *e, uint32_t name_id);
/* After a scope, verify all linear bindings introduced in it have been used. */
int         iii_type_env_check_linear_complete(iii_type_env_t *e);

/* Diagnostics. */
size_t                       iii_type_env_diag_count(const iii_type_env_t *e);
const iii_type_diagnostic_t *iii_type_env_diag_at(const iii_type_env_t *e, size_t i);
void                         iii_type_env_emit(iii_type_env_t *e,
                                               iii_type_err_code_t code,
                                               const iii_ast_node_t *where,
                                               const char *fmt, ...);

/* The shared CIC kernel. */
iii_term_kernel_t *iii_type_env_kernel(iii_type_env_t *e);

/* ------------------------------------------------------------------ */
/* Type factories                                                      */
/* ------------------------------------------------------------------ */

iii_type_t *iii_ty_universe(iii_type_env_t *e, iii_universe_t u);
iii_type_t *iii_ty_prim(iii_type_env_t *e, iii_prim_id_t p);
iii_type_t *iii_ty_fun(iii_type_env_t *e, iii_type_t *dom, iii_type_t *cod);
iii_type_t *iii_ty_pi(iii_type_env_t *e, const char *name,
                      iii_type_t *dom, iii_type_t *cod);
iii_type_t *iii_ty_tuple(iii_type_env_t *e, iii_type_t **elts, uint32_t n);
iii_type_t *iii_ty_hexad_tag(iii_type_env_t *e, iii_type_t *inner, iii_hexad_t h);
iii_type_t *iii_ty_ring_tag (iii_type_env_t *e, iii_type_t *inner, iii_phase_set_t r);
iii_type_t *iii_ty_tier_tag (iii_type_env_t *e, iii_type_t *inner, iii_tier_t k);
iii_type_t *iii_ty_epoch_tag(iii_type_env_t *e, iii_type_t *inner, iii_epoch_t n);
iii_type_t *iii_ty_cap(iii_type_env_t *e, iii_cap_perm_t p, uint32_t range_id);
iii_type_t *iii_ty_uncertainty(iii_type_env_t *e, uint32_t dom_id,
                               uint16_t conf_q14, uint32_t qs);
iii_type_t *iii_ty_reduction(iii_type_env_t *e,
                             iii_type_t *F, iii_type_t *I,
                             iii_hexad_t H, iii_phase_set_t P, iii_epoch_t E);
iii_type_t *iii_ty_prop(iii_type_env_t *e, iii_prop_kind_t pk);
iii_type_t *iii_ty_hole(iii_type_env_t *e, iii_universe_t expected);
iii_type_t *iii_ty_named(iii_type_env_t *e, uint32_t name_id);

/* §3.3 — six elimination rules.  proj_name in {forward, inverse, witness, hexad, phase, epoch}. */
iii_type_t *iii_ty_reduction_proj(iii_type_env_t *e, iii_type_t *r,
                                  const char *proj_name);
/* §3.4 — composition. */
iii_type_t *iii_ty_reduction_compose(iii_type_env_t *e,
                                     iii_type_t *r1, iii_type_t *r2);
/* §3.5 — inverse. */
iii_type_t *iii_ty_reduction_inverse(iii_type_env_t *e, iii_type_t *r);

/* §4.2 hexad compose typing rule. */
iii_type_t *iii_ty_hexad_compose(iii_type_env_t *e,
                                 iii_type_t *t1, iii_type_t *t2);

/* §5.2 phase-cross. */
iii_type_t *iii_ty_phase_cross(iii_type_env_t *e, iii_type_t *v,
                               iii_phase_set_t target_set,
                               iii_ring_t from, iii_ring_t to);

/* §6.1 tier-compose. */
iii_type_t *iii_ty_tier_compose(iii_type_env_t *e,
                                iii_type_t *a, iii_type_t *b);

/* §6.2 epoch-bridge. */
iii_type_t *iii_ty_epoch_bridge(iii_type_env_t *e,
                                iii_type_t *a, iii_type_t *b,
                                bool bridge_attribute_present);

/* §7.2 linear cap use. */
iii_type_t *iii_ty_linear_use(iii_type_env_t *e, uint32_t cap_name_id);

/* §8.2 epistemic compose. */
iii_uncertainty_t iii_uncertainty_combine(iii_uncertainty_t a, iii_uncertainty_t b);

/* ------------------------------------------------------------------ */
/* §10 — Bidirectional inference                                       */
/* ------------------------------------------------------------------ */

iii_type_t *iii_synth(iii_type_env_t *e, const iii_ast_node_t *expr);
int         iii_check(iii_type_env_t *e, const iii_ast_node_t *expr,
                      iii_type_t *expected);

/* §10.2 — Hole resolution.  Walks the env's hole table; emits
 * TYPE-HOLE-001 for any unresolved hole. */
int  iii_holes_solve(iii_type_env_t *e);

/* §10.3 typed-as-term lift (U1). */
iii_type_t *iii_lift_term_to_type(iii_type_env_t *e, iii_type_t *t);

/* ------------------------------------------------------------------ */
/* §12 — Three-pass type-checker driver over a parsed AST module       */
/* ------------------------------------------------------------------ */

typedef struct iii_typed_module iii_typed_module_t;

/* Annotation: maps AST node pointer → inferred type.
 * Returns the typed module overlay (owned by env).  On failure, returns
 * non-NULL but env diagnostics will be populated. */
iii_typed_module_t *iii_check_module(iii_type_env_t *e,
                                     const iii_ast_node_t *module_root);

/* Lookup the inferred type for an AST node (NULL if not annotated). */
iii_type_t *iii_typed_lookup(const iii_typed_module_t *m,
                             const iii_ast_node_t *n);

size_t iii_typed_size(const iii_typed_module_t *m);

/* ------------------------------------------------------------------ */
/* §11 — Proof certificates                                            */
/* ------------------------------------------------------------------ */

typedef struct iii_proof_cert {
    iii_term_t *cic_term;
    iii_term_t *cic_type;       /* the proposition */
    uint16_t   *hexad_witnesses;
    uint32_t    hexad_count;
    iii_universe_t universe_witness;
    uint8_t     closure_root[32];
} iii_proof_cert_t;

iii_proof_cert_t *iii_proof_cert_create(iii_type_env_t *e,
                                        iii_term_t *term, iii_term_t *prop,
                                        const uint16_t *hexads, uint32_t n);
/* Run the kernel against the certificate; returns true iff valid. */
bool             iii_proof_verify(iii_type_env_t *e, const iii_proof_cert_t *c);

/* Compute the canonical R1.A3 hash of the spec file at `path`. */
int  iii_r1_a3_hash_file(const char *path, uint8_t out[32]);

/* ------------------------------------------------------------------ */
/* Module identity                                                     */
/* ------------------------------------------------------------------ */
#define III_TYPES_MODULE_NAME    "III TYPES (R1.A3)"
#define III_TYPES_MODULE_VERSION "1.0"

#ifdef __cplusplus
}
#endif
#endif
