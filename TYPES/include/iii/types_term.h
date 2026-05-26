/* III TYPES — CIC kernel term language (§11.1) and native-ternary
 * extensions (§11.2).
 *
 * The kernel implements a fragment of the Calculus of Inductive
 * Constructions:
 *   - Sorts: Prop, Type_0..Type_6
 *   - Pi types (dependent function), Lambda, App, Var (de Bruijn)
 *   - Sigma (dependent pair) for Reduction's existential structure
 *   - Inductive types (Trit, Hexad, List, Phase, Tier, Epoch, Bool)
 *   - Pattern matching
 *   - Beta / iota / delta / eta reduction
 *   - Conversion check up to βιδζη
 *   - Type-check `Γ ⊢ t : T`
 *
 * Native ternary primitives expose hexad ops as first-class kernel rules
 * to keep proof certificates compact (§11.2).
 */
#ifndef III_TYPES_TERM_H
#define III_TYPES_TERM_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include "types_hexad.h"
#include "types_errors.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct iii_arena iii_arena_t; /* lex-arena */

/* Sorts. */
typedef enum iii_sort {
    III_SORT_PROP   = 0,
    III_SORT_TYPE0  = 1,
    III_SORT_TYPE1  = 2,
    III_SORT_TYPE2  = 3,
    III_SORT_TYPE3  = 4,
    III_SORT_TYPE4  = 5,
    III_SORT_TYPE5  = 6,
    III_SORT_TYPE6  = 7
} iii_sort_t;

/* Convert sort to its universe level (Prop=-1, Type_i=i).  Returns -1 for Prop. */
int  iii_sort_level(iii_sort_t s);
/* The "type-of" rule for sorts: Prop:Type_0; Type_i:Type_{i+1}; Type_6:Type_6. */
iii_sort_t iii_sort_succ(iii_sort_t s);
/* Predicative Pi rule: max(i,j) for normal sorts; impredicative top: any with Type_6 → Type_6.
 * If either sort is Prop, treat its level as 0 for the predicative max. */
iii_sort_t iii_sort_pi(iii_sort_t dom, iii_sort_t cod);

/* Inductive references (built-ins at fixed indices 0..N-1; see iii_term_kernel_init). */
typedef enum iii_ind_id {
    III_IND_BOOL    = 0,
    III_IND_TRIT    = 1,
    III_IND_HEXAD   = 2,
    III_IND_PHASE   = 3,
    III_IND_TIER    = 4,
    III_IND_EPOCH   = 5,
    III_IND_LIST    = 6,
    III_IND__COUNT  = 7
} iii_ind_id_t;

/* Term constructors. */
typedef enum iii_term_kind {
    III_TM_SORT,
    III_TM_VAR,        /* de Bruijn index (≥ 0) */
    III_TM_CONST,      /* δ-reducible global constant by name id */
    III_TM_LAM,        /* λ x:A. body */
    III_TM_PI,         /* Π x:A. B */
    III_TM_APP,        /* f a */
    III_TM_LET,        /* let x:A := v in body  (ζ-reducible) */
    III_TM_IND,        /* reference to an inductive type */
    III_TM_CTOR,       /* a constructor of an inductive type */
    III_TM_MATCH,      /* match scrutinee in motive with arms */
    III_TM_NAT,        /* opaque natural literal (used for Epoch values) */
    III_TM_TRIT,       /* native ternary literal (asymmetric algebra) */
    III_TM_HEXAD       /* native packed hexad literal */
} iii_term_kind_t;

typedef struct iii_term iii_term_t;

struct iii_term {
    iii_term_kind_t kind;

    /* Sort */
    iii_sort_t sort;

    /* Var */
    int var_idx;

    /* Const */
    uint32_t const_id;

    /* Lam / Pi / Let */
    const char *binder_name;       /* informational; opt-in */
    iii_term_t *binder_type;       /* A */
    iii_term_t *binder_body;       /* body / B */
    iii_term_t *binder_value;      /* let-value */

    /* App */
    iii_term_t *app_fun;
    iii_term_t *app_arg;

    /* Inductive */
    iii_ind_id_t ind_id;

    /* Constructor */
    iii_ind_id_t ctor_ind;
    uint16_t     ctor_idx;
    iii_term_t **ctor_args;
    uint32_t     ctor_argc;

    /* Match */
    iii_term_t  *match_scrut;
    iii_term_t  *match_motive;
    iii_term_t **match_arms;       /* one per ctor of the inductive */
    uint32_t     match_arm_count;
    iii_ind_id_t match_ind;

    /* Literal payloads */
    uint64_t   nat_value;
    iii_trit_t trit_value;
    uint16_t   hexad_value;
};

/* The kernel: arena-allocated term factory + δ environment. */
typedef struct iii_term_kernel iii_term_kernel_t;

iii_term_kernel_t *iii_term_kernel_create(void);
void               iii_term_kernel_destroy(iii_term_kernel_t *k);

/* Term factories (all arena-allocated inside the kernel). */
iii_term_t *iii_tm_sort(iii_term_kernel_t *k, iii_sort_t s);
iii_term_t *iii_tm_var(iii_term_kernel_t *k, int idx);
iii_term_t *iii_tm_const(iii_term_kernel_t *k, uint32_t id);
iii_term_t *iii_tm_lam(iii_term_kernel_t *k, const char *name, iii_term_t *A, iii_term_t *body);
iii_term_t *iii_tm_pi (iii_term_kernel_t *k, const char *name, iii_term_t *A, iii_term_t *B);
iii_term_t *iii_tm_app(iii_term_kernel_t *k, iii_term_t *f, iii_term_t *a);
iii_term_t *iii_tm_let(iii_term_kernel_t *k, const char *name, iii_term_t *A, iii_term_t *v, iii_term_t *body);
iii_term_t *iii_tm_ind(iii_term_kernel_t *k, iii_ind_id_t i);
iii_term_t *iii_tm_ctor(iii_term_kernel_t *k, iii_ind_id_t i, uint16_t idx,
                        iii_term_t **args, uint32_t argc);
iii_term_t *iii_tm_match(iii_term_kernel_t *k, iii_ind_id_t i,
                         iii_term_t *scrut, iii_term_t *motive,
                         iii_term_t **arms, uint32_t arm_count);
iii_term_t *iii_tm_nat(iii_term_kernel_t *k, uint64_t v);
iii_term_t *iii_tm_trit(iii_term_kernel_t *k, iii_trit_t t);
iii_term_t *iii_tm_hexad(iii_term_kernel_t *k, uint16_t packed);

/* δ environment: register a constant `id` with value `def` and type `ty`. */
int  iii_term_kernel_define(iii_term_kernel_t *k, uint32_t id,
                            iii_term_t *def, iii_term_t *ty);
const iii_term_t *iii_term_kernel_lookup(const iii_term_kernel_t *k,
                                         uint32_t id, const iii_term_t **out_ty);

/* Substitution: term[arg/0] (β step ingredient). */
iii_term_t *iii_term_subst(iii_term_kernel_t *k, iii_term_t *body, iii_term_t *arg);

/* Lifting (de Bruijn shift) over `cutoff` by `delta`. */
iii_term_t *iii_term_lift(iii_term_kernel_t *k, iii_term_t *t, int cutoff, int delta);

/* Reduction: weak-head reduce one β/δ/ζ/ι step.  Returns NULL if no step. */
iii_term_t *iii_term_whreduce(iii_term_kernel_t *k, iii_term_t *t);

/* Full normalization (NbE-style by repeated reduction).  Bounded steps. */
iii_term_t *iii_term_normalize(iii_term_kernel_t *k, iii_term_t *t,
                               int max_steps, iii_type_err_code_t *err);

/* Conversion check up to βιδζη.  Returns true iff convertible. */
bool        iii_term_convertible(iii_term_kernel_t *k,
                                 iii_term_t *a, iii_term_t *b);

/* η-equivalence wrapper used by conversion. */
bool        iii_term_eta_eq(iii_term_kernel_t *k,
                            iii_term_t *a, iii_term_t *b);

/* Type-check Γ ⊢ t : T.  Γ is an array of term-types (de Bruijn order;
 * index 0 is the innermost binder).  Returns 0 on success and writes
 * the inferred type into *out_ty (allocated in the kernel arena);
 * returns non-zero TYPE_PROOF_* code on failure. */
int  iii_term_typeof(iii_term_kernel_t *k, iii_term_t **gamma, uint32_t depth,
                     iii_term_t *t, iii_term_t **out_ty);

/* Verify `t : T` by inferring then checking convertibility. */
int  iii_term_check(iii_term_kernel_t *k, iii_term_t **gamma, uint32_t depth,
                    iii_term_t *t, iii_term_t *T);

/* Positivity check on an inductive declaration's constructors.  The
 * built-in inductives of III_IND_* are pre-checked. */
bool iii_term_positivity_ok(iii_term_kernel_t *k, iii_term_t *ctor_arg_type,
                            iii_ind_id_t self_id);

/* Pretty-print a term to a buffer (NUL-terminated).  Returns chars written. */
size_t iii_term_print(const iii_term_t *t, char *buf, size_t cap);

#ifdef __cplusplus
}
#endif
#endif
