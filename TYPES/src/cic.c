/* III TYPES — CIC kernel + native ternary extension (§11).
 *
 * Hand-rolled, NIH.  No external proof system.
 *
 * Term representation: de Bruijn indices.  Substitution and lifting
 * are straightforward structural recursions.
 *
 * Reduction:
 *   β   (App (Lam _ _ b) a)        →  b[0 ↦ a]            (capture-avoiding via lifting)
 *   ζ   (Let _ _ v b)              →  b[0 ↦ v]
 *   δ   Const id (with definition) →  the definition
 *   ι   (Match (Ctor _ k args) m arms)  →  apply arms[k] to args
 *   η   (Lam _ A (App f (Var 0)))  →  f                    when 0 not free in f
 *
 * Conversion:  whnf both sides; structural compare; on Lam/Pi recurse;
 *              η-expand if one side is a Lam and the other isn't.
 *
 * Type-check: standard CIC rules; fixed seven-level universe; predicative
 * Pi for sorts < Type_6; impredicative for Type_6.
 *
 * Inductive types: seven built-ins (Bool, Trit, Hexad, Phase, Tier,
 * Epoch, List).  We declare their constructor signatures internally and
 * use a schematic ι rule.
 */
#include "iii/types_term.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

/* ------------------------------------------------------------------ */
/* Sort utilities                                                     */
/* ------------------------------------------------------------------ */

int iii_sort_level(iii_sort_t s) {
    if (s == III_SORT_PROP) return -1;
    return (int)s - 1;
}

iii_sort_t iii_sort_succ(iii_sort_t s) {
    switch (s) {
    case III_SORT_PROP:  return III_SORT_TYPE0;
    case III_SORT_TYPE0: return III_SORT_TYPE1;
    case III_SORT_TYPE1: return III_SORT_TYPE2;
    case III_SORT_TYPE2: return III_SORT_TYPE3;
    case III_SORT_TYPE3: return III_SORT_TYPE4;
    case III_SORT_TYPE4: return III_SORT_TYPE5;
    case III_SORT_TYPE5: return III_SORT_TYPE6;
    case III_SORT_TYPE6: return III_SORT_TYPE6;  /* §2.1 U-Top */
    }
    return III_SORT_TYPE6;
}

iii_sort_t iii_sort_pi(iii_sort_t dom, iii_sort_t cod) {
    if (cod == III_SORT_TYPE6) return III_SORT_TYPE6;
    int di = iii_sort_level(dom); if (di < 0) di = 0;
    int ci = iii_sort_level(cod); if (ci < 0) ci = 0;
    int m = di > ci ? di : ci;
    return (iii_sort_t)(m + 1);  /* +1 because TYPE0 = 1 in enum */
}

/* ------------------------------------------------------------------ */
/* Kernel structure                                                   */
/* ------------------------------------------------------------------ */

#define IIIK_DEF_CAP_INIT  64
#define IIIK_TERM_BLOCK    4096

typedef struct iiik_chunk {
    struct iiik_chunk *next;
    size_t cap, used;
    uint8_t data[1];
} iiik_chunk_t;

typedef struct {
    uint32_t id;
    iii_term_t *def;
    iii_term_t *ty;
} iiik_def_t;

struct iii_term_kernel {
    iiik_chunk_t *chunks;
    iiik_def_t   *defs;
    size_t        defs_count, defs_cap;
};

static void *iiik_alloc(iii_term_kernel_t *k, size_t bytes) {
    /* Align to 16. */
    bytes = (bytes + 15u) & ~(size_t)15u;
    if (!k->chunks || k->chunks->used + bytes > k->chunks->cap) {
        size_t cap = bytes > IIIK_TERM_BLOCK ? bytes : IIIK_TERM_BLOCK;
        iiik_chunk_t *c = (iiik_chunk_t*)calloc(1, sizeof *c + cap);
        if (!c) return NULL;
        c->cap = cap; c->used = 0; c->next = k->chunks; k->chunks = c;
    }
    void *p = k->chunks->data + k->chunks->used;
    k->chunks->used += bytes;
    return p;
}

iii_term_kernel_t *iii_term_kernel_create(void) {
    iii_term_kernel_t *k = (iii_term_kernel_t*)calloc(1, sizeof *k);
    if (!k) return NULL;
    k->defs_cap = IIIK_DEF_CAP_INIT;
    k->defs = (iiik_def_t*)calloc(k->defs_cap, sizeof *k->defs);
    if (!k->defs) { free(k); return NULL; }
    return k;
}

void iii_term_kernel_destroy(iii_term_kernel_t *k) {
    if (!k) return;
    iiik_chunk_t *c = k->chunks;
    while (c) { iiik_chunk_t *n = c->next; free(c); c = n; }
    free(k->defs);
    free(k);
}

/* ------------------------------------------------------------------ */
/* Term factories                                                     */
/* ------------------------------------------------------------------ */

static iii_term_t *iiik_new(iii_term_kernel_t *k, iii_term_kind_t kk) {
    iii_term_t *t = (iii_term_t*)iiik_alloc(k, sizeof *t);
    if (!t) return NULL;
    t->kind = kk;
    return t;
}

iii_term_t *iii_tm_sort(iii_term_kernel_t *k, iii_sort_t s) {
    iii_term_t *t = iiik_new(k, III_TM_SORT); if (!t) return NULL;
    t->sort = s; return t;
}
iii_term_t *iii_tm_var(iii_term_kernel_t *k, int idx) {
    iii_term_t *t = iiik_new(k, III_TM_VAR); if (!t) return NULL;
    t->var_idx = idx; return t;
}
iii_term_t *iii_tm_const(iii_term_kernel_t *k, uint32_t id) {
    iii_term_t *t = iiik_new(k, III_TM_CONST); if (!t) return NULL;
    t->const_id = id; return t;
}
iii_term_t *iii_tm_lam(iii_term_kernel_t *k, const char *name, iii_term_t *A, iii_term_t *body) {
    iii_term_t *t = iiik_new(k, III_TM_LAM); if (!t) return NULL;
    t->binder_name = name; t->binder_type = A; t->binder_body = body; return t;
}
iii_term_t *iii_tm_pi(iii_term_kernel_t *k, const char *name, iii_term_t *A, iii_term_t *B) {
    iii_term_t *t = iiik_new(k, III_TM_PI); if (!t) return NULL;
    t->binder_name = name; t->binder_type = A; t->binder_body = B; return t;
}
iii_term_t *iii_tm_app(iii_term_kernel_t *k, iii_term_t *f, iii_term_t *a) {
    iii_term_t *t = iiik_new(k, III_TM_APP); if (!t) return NULL;
    t->app_fun = f; t->app_arg = a; return t;
}
iii_term_t *iii_tm_let(iii_term_kernel_t *k, const char *n, iii_term_t *A, iii_term_t *v, iii_term_t *body) {
    iii_term_t *t = iiik_new(k, III_TM_LET); if (!t) return NULL;
    t->binder_name = n; t->binder_type = A; t->binder_value = v; t->binder_body = body; return t;
}
iii_term_t *iii_tm_ind(iii_term_kernel_t *k, iii_ind_id_t i) {
    iii_term_t *t = iiik_new(k, III_TM_IND); if (!t) return NULL;
    t->ind_id = i; return t;
}
iii_term_t *iii_tm_ctor(iii_term_kernel_t *k, iii_ind_id_t i, uint16_t idx,
                        iii_term_t **args, uint32_t argc) {
    iii_term_t *t = iiik_new(k, III_TM_CTOR); if (!t) return NULL;
    t->ctor_ind = i; t->ctor_idx = idx; t->ctor_argc = argc;
    if (argc) {
        t->ctor_args = (iii_term_t**)iiik_alloc(k, argc * sizeof *t->ctor_args);
        if (!t->ctor_args) return NULL;
        memcpy(t->ctor_args, args, argc * sizeof *t->ctor_args);
    }
    return t;
}
iii_term_t *iii_tm_match(iii_term_kernel_t *k, iii_ind_id_t i,
                         iii_term_t *scrut, iii_term_t *motive,
                         iii_term_t **arms, uint32_t arm_count) {
    iii_term_t *t = iiik_new(k, III_TM_MATCH); if (!t) return NULL;
    t->match_ind = i; t->match_scrut = scrut; t->match_motive = motive;
    t->match_arm_count = arm_count;
    if (arm_count) {
        t->match_arms = (iii_term_t**)iiik_alloc(k, arm_count * sizeof *t->match_arms);
        if (!t->match_arms) return NULL;
        memcpy(t->match_arms, arms, arm_count * sizeof *t->match_arms);
    }
    return t;
}
iii_term_t *iii_tm_nat(iii_term_kernel_t *k, uint64_t v) {
    iii_term_t *t = iiik_new(k, III_TM_NAT); if (!t) return NULL;
    t->nat_value = v; return t;
}
iii_term_t *iii_tm_trit(iii_term_kernel_t *k, iii_trit_t v) {
    iii_term_t *t = iiik_new(k, III_TM_TRIT); if (!t) return NULL;
    t->trit_value = v; return t;
}
iii_term_t *iii_tm_hexad(iii_term_kernel_t *k, uint16_t v) {
    iii_term_t *t = iiik_new(k, III_TM_HEXAD); if (!t) return NULL;
    t->hexad_value = v; return t;
}

/* ------------------------------------------------------------------ */
/* δ environment                                                       */
/* ------------------------------------------------------------------ */

int iii_term_kernel_define(iii_term_kernel_t *k, uint32_t id,
                           iii_term_t *def, iii_term_t *ty) {
    if (k->defs_count == k->defs_cap) {
        size_t nc = k->defs_cap * 2;
        iiik_def_t *nd = (iiik_def_t*)realloc(k->defs, nc * sizeof *nd);
        if (!nd) return -1;
        k->defs = nd; k->defs_cap = nc;
    }
    k->defs[k->defs_count].id = id;
    k->defs[k->defs_count].def = def;
    k->defs[k->defs_count].ty = ty;
    k->defs_count++;
    return 0;
}

const iii_term_t *iii_term_kernel_lookup(const iii_term_kernel_t *k,
                                         uint32_t id, const iii_term_t **out_ty) {
    for (size_t i = 0; i < k->defs_count; ++i) {
        if (k->defs[i].id == id) {
            if (out_ty) *out_ty = k->defs[i].ty;
            return k->defs[i].def;
        }
    }
    return NULL;
}

/* ------------------------------------------------------------------ */
/* Lifting and substitution                                           */
/* ------------------------------------------------------------------ */

iii_term_t *iii_term_lift(iii_term_kernel_t *k, iii_term_t *t, int cutoff, int delta) {
    if (!t) return NULL;
    switch (t->kind) {
    case III_TM_VAR:
        if (t->var_idx >= cutoff)
            return iii_tm_var(k, t->var_idx + delta);
        return t;
    case III_TM_SORT: case III_TM_CONST: case III_TM_IND:
    case III_TM_NAT: case III_TM_TRIT: case III_TM_HEXAD:
        return t;
    case III_TM_LAM: {
        iii_term_t *A = iii_term_lift(k, t->binder_type, cutoff, delta);
        iii_term_t *b = iii_term_lift(k, t->binder_body, cutoff + 1, delta);
        return iii_tm_lam(k, t->binder_name, A, b);
    }
    case III_TM_PI: {
        iii_term_t *A = iii_term_lift(k, t->binder_type, cutoff, delta);
        iii_term_t *B = iii_term_lift(k, t->binder_body, cutoff + 1, delta);
        return iii_tm_pi(k, t->binder_name, A, B);
    }
    case III_TM_LET: {
        iii_term_t *A = iii_term_lift(k, t->binder_type,  cutoff, delta);
        iii_term_t *V = iii_term_lift(k, t->binder_value, cutoff, delta);
        iii_term_t *B = iii_term_lift(k, t->binder_body,  cutoff + 1, delta);
        return iii_tm_let(k, t->binder_name, A, V, B);
    }
    case III_TM_APP: {
        iii_term_t *f = iii_term_lift(k, t->app_fun, cutoff, delta);
        iii_term_t *a = iii_term_lift(k, t->app_arg, cutoff, delta);
        return iii_tm_app(k, f, a);
    }
    case III_TM_CTOR: {
        iii_term_t **na = NULL;
        if (t->ctor_argc) {
            na = (iii_term_t**)iiik_alloc(k, t->ctor_argc * sizeof *na);
            for (uint32_t i = 0; i < t->ctor_argc; ++i)
                na[i] = iii_term_lift(k, t->ctor_args[i], cutoff, delta);
        }
        return iii_tm_ctor(k, t->ctor_ind, t->ctor_idx, na, t->ctor_argc);
    }
    case III_TM_MATCH: {
        iii_term_t *s = iii_term_lift(k, t->match_scrut,  cutoff, delta);
        iii_term_t *m = iii_term_lift(k, t->match_motive, cutoff, delta);
        iii_term_t **na = NULL;
        if (t->match_arm_count) {
            na = (iii_term_t**)iiik_alloc(k, t->match_arm_count * sizeof *na);
            for (uint32_t i = 0; i < t->match_arm_count; ++i)
                na[i] = iii_term_lift(k, t->match_arms[i], cutoff, delta);
        }
        return iii_tm_match(k, t->match_ind, s, m, na, t->match_arm_count);
    }
    }
    return t;
}

/* Capture-avoiding substitution: substitute term `a` for de Bruijn index 0 in `b`. */
static iii_term_t *subst_at(iii_term_kernel_t *k, iii_term_t *b, int depth, iii_term_t *a) {
    if (!b) return NULL;
    switch (b->kind) {
    case III_TM_VAR:
        if (b->var_idx == depth) return iii_term_lift(k, a, 0, depth);
        if (b->var_idx >  depth) return iii_tm_var(k, b->var_idx - 1);
        return b;
    case III_TM_SORT: case III_TM_CONST: case III_TM_IND:
    case III_TM_NAT: case III_TM_TRIT: case III_TM_HEXAD:
        return b;
    case III_TM_LAM: {
        iii_term_t *A = subst_at(k, b->binder_type, depth, a);
        iii_term_t *bo = subst_at(k, b->binder_body, depth + 1, a);
        return iii_tm_lam(k, b->binder_name, A, bo);
    }
    case III_TM_PI: {
        iii_term_t *A = subst_at(k, b->binder_type, depth, a);
        iii_term_t *B = subst_at(k, b->binder_body, depth + 1, a);
        return iii_tm_pi(k, b->binder_name, A, B);
    }
    case III_TM_LET: {
        iii_term_t *A = subst_at(k, b->binder_type,  depth, a);
        iii_term_t *V = subst_at(k, b->binder_value, depth, a);
        iii_term_t *B = subst_at(k, b->binder_body,  depth + 1, a);
        return iii_tm_let(k, b->binder_name, A, V, B);
    }
    case III_TM_APP: {
        iii_term_t *f = subst_at(k, b->app_fun, depth, a);
        iii_term_t *x = subst_at(k, b->app_arg, depth, a);
        return iii_tm_app(k, f, x);
    }
    case III_TM_CTOR: {
        iii_term_t **na = NULL;
        if (b->ctor_argc) {
            na = (iii_term_t**)iiik_alloc(k, b->ctor_argc * sizeof *na);
            for (uint32_t i = 0; i < b->ctor_argc; ++i)
                na[i] = subst_at(k, b->ctor_args[i], depth, a);
        }
        return iii_tm_ctor(k, b->ctor_ind, b->ctor_idx, na, b->ctor_argc);
    }
    case III_TM_MATCH: {
        iii_term_t *s = subst_at(k, b->match_scrut,  depth, a);
        iii_term_t *m = subst_at(k, b->match_motive, depth, a);
        iii_term_t **na = NULL;
        if (b->match_arm_count) {
            na = (iii_term_t**)iiik_alloc(k, b->match_arm_count * sizeof *na);
            for (uint32_t i = 0; i < b->match_arm_count; ++i)
                na[i] = subst_at(k, b->match_arms[i], depth, a);
        }
        return iii_tm_match(k, b->match_ind, s, m, na, b->match_arm_count);
    }
    }
    return b;
}

iii_term_t *iii_term_subst(iii_term_kernel_t *k, iii_term_t *body, iii_term_t *arg) {
    return subst_at(k, body, 0, arg);
}

/* ------------------------------------------------------------------ */
/* Reduction                                                          */
/* ------------------------------------------------------------------ */

static int var_free_at(iii_term_t *t, int idx) {
    if (!t) return 0;
    switch (t->kind) {
    case III_TM_VAR: return t->var_idx == idx;
    case III_TM_LAM: case III_TM_PI:
        return var_free_at(t->binder_type, idx) ||
               var_free_at(t->binder_body, idx + 1);
    case III_TM_LET:
        return var_free_at(t->binder_type, idx) ||
               var_free_at(t->binder_value, idx) ||
               var_free_at(t->binder_body, idx + 1);
    case III_TM_APP:
        return var_free_at(t->app_fun, idx) || var_free_at(t->app_arg, idx);
    case III_TM_CTOR: {
        for (uint32_t i = 0; i < t->ctor_argc; ++i)
            if (var_free_at(t->ctor_args[i], idx)) return 1;
        return 0;
    }
    case III_TM_MATCH: {
        if (var_free_at(t->match_scrut, idx) || var_free_at(t->match_motive, idx))
            return 1;
        for (uint32_t i = 0; i < t->match_arm_count; ++i)
            if (var_free_at(t->match_arms[i], idx)) return 1;
        return 0;
    }
    default: return 0;
    }
}

iii_term_t *iii_term_whreduce(iii_term_kernel_t *k, iii_term_t *t) {
    if (!t) return NULL;
    switch (t->kind) {
    case III_TM_CONST: {
        const iii_term_t *def = iii_term_kernel_lookup(k, t->const_id, NULL);
        if (def) return (iii_term_t*)def;
        return NULL;
    }
    case III_TM_LET:
        /* ζ */
        return iii_term_subst(k, t->binder_body, t->binder_value);
    case III_TM_APP: {
        iii_term_t *f = iii_term_whreduce(k, t->app_fun);
        iii_term_t *fcur = f ? f : t->app_fun;
        if (fcur->kind == III_TM_LAM)
            return iii_term_subst(k, fcur->binder_body, t->app_arg); /* β */
        if (f) return iii_tm_app(k, f, t->app_arg);
        return NULL;
    }
    case III_TM_MATCH: {
        iii_term_t *s = iii_term_whreduce(k, t->match_scrut);
        iii_term_t *scur = s ? s : t->match_scrut;
        if (scur->kind == III_TM_CTOR &&
            scur->ctor_ind == t->match_ind &&
            scur->ctor_idx < t->match_arm_count) {
            /* ι: arms[k] applied to ctor_args. */
            iii_term_t *arm = t->match_arms[scur->ctor_idx];
            for (uint32_t i = 0; i < scur->ctor_argc; ++i)
                arm = iii_tm_app(k, arm, scur->ctor_args[i]);
            return arm;
        }
        if (s) return iii_tm_match(k, t->match_ind, s, t->match_motive,
                                   t->match_arms, t->match_arm_count);
        return NULL;
    }
    default: return NULL;
    }
}

iii_term_t *iii_term_normalize(iii_term_kernel_t *k, iii_term_t *t,
                               int max_steps, iii_type_err_code_t *err) {
    int budget = max_steps > 0 ? max_steps : 100000;
    iii_term_t *cur = t;
    while (budget-- > 0) {
        iii_term_t *n = iii_term_whreduce(k, cur);
        if (!n) break;
        cur = n;
    }
    if (budget <= 0) {
        if (err) *err = TYPE_PROOF_006_KERNEL_DIVERGED;
        return cur;
    }
    /* Push normalization into sub-terms structurally. */
    if (!cur) return NULL;
    switch (cur->kind) {
    case III_TM_LAM: {
        iii_term_t *A = iii_term_normalize(k, cur->binder_type, budget, err);
        iii_term_t *B = iii_term_normalize(k, cur->binder_body, budget, err);
        return iii_tm_lam(k, cur->binder_name, A, B);
    }
    case III_TM_PI: {
        iii_term_t *A = iii_term_normalize(k, cur->binder_type, budget, err);
        iii_term_t *B = iii_term_normalize(k, cur->binder_body, budget, err);
        return iii_tm_pi(k, cur->binder_name, A, B);
    }
    case III_TM_APP: {
        iii_term_t *f = iii_term_normalize(k, cur->app_fun, budget, err);
        iii_term_t *a = iii_term_normalize(k, cur->app_arg, budget, err);
        return iii_tm_app(k, f, a);
    }
    case III_TM_CTOR: {
        iii_term_t **na = NULL;
        if (cur->ctor_argc) {
            na = (iii_term_t**)iiik_alloc(k, cur->ctor_argc * sizeof *na);
            for (uint32_t i = 0; i < cur->ctor_argc; ++i)
                na[i] = iii_term_normalize(k, cur->ctor_args[i], budget, err);
        }
        return iii_tm_ctor(k, cur->ctor_ind, cur->ctor_idx, na, cur->ctor_argc);
    }
    case III_TM_MATCH: {
        iii_term_t *s = iii_term_normalize(k, cur->match_scrut, budget, err);
        iii_term_t *m = cur->match_motive;
        iii_term_t **na = NULL;
        if (cur->match_arm_count) {
            na = (iii_term_t**)iiik_alloc(k, cur->match_arm_count * sizeof *na);
            for (uint32_t i = 0; i < cur->match_arm_count; ++i)
                na[i] = iii_term_normalize(k, cur->match_arms[i], budget, err);
        }
        return iii_tm_match(k, cur->match_ind, s, m, na, cur->match_arm_count);
    }
    default: return cur;
    }
}

/* ------------------------------------------------------------------ */
/* Conversion (βιδζη)                                                  */
/* ------------------------------------------------------------------ */

static int convertible_rec(iii_term_kernel_t *k, iii_term_t *a, iii_term_t *b, int depth);

bool iii_term_eta_eq(iii_term_kernel_t *k, iii_term_t *a, iii_term_t *b) {
    /* η: λ x. (f x)  ≡  f   when 0 not free in f.  Compare as: a is
     * Lam(_, App(f, Var0)) and 0 not free in f, then f ≡ b (lifted). */
    if (a->kind != III_TM_LAM) return false;
    iii_term_t *body = iii_term_normalize(k, a->binder_body, 256, NULL);
    if (!body || body->kind != III_TM_APP) return false;
    if (body->app_arg->kind != III_TM_VAR || body->app_arg->var_idx != 0) return false;
    if (var_free_at(body->app_fun, 0)) return false;
    iii_term_t *f = iii_term_lift(k, body->app_fun, 1, -1);
    return convertible_rec(k, f, b, 0);
}

static int convertible_rec(iii_term_kernel_t *k, iii_term_t *a, iii_term_t *b, int depth) {
    if (depth > 4096) return 0;
    a = iii_term_normalize(k, a, 4096, NULL);
    b = iii_term_normalize(k, b, 4096, NULL);
    if (!a || !b) return 0;
    if (a == b) return 1;
    if (a->kind != b->kind) {
        /* η-expansion attempt either direction */
        if (a->kind == III_TM_LAM && iii_term_eta_eq(k, a, b)) return 1;
        if (b->kind == III_TM_LAM && iii_term_eta_eq(k, b, a)) return 1;
        return 0;
    }
    switch (a->kind) {
    case III_TM_SORT:  return a->sort == b->sort;
    case III_TM_VAR:   return a->var_idx == b->var_idx;
    case III_TM_CONST: return a->const_id == b->const_id;
    case III_TM_IND:   return a->ind_id == b->ind_id;
    case III_TM_NAT:   return a->nat_value == b->nat_value;
    case III_TM_TRIT:  return a->trit_value == b->trit_value;
    case III_TM_HEXAD: return a->hexad_value == b->hexad_value;
    case III_TM_LAM:
    case III_TM_PI:
        return convertible_rec(k, a->binder_type, b->binder_type, depth + 1) &&
               convertible_rec(k, a->binder_body, b->binder_body, depth + 1);
    case III_TM_LET:
        return convertible_rec(k, a->binder_type,  b->binder_type,  depth + 1) &&
               convertible_rec(k, a->binder_value, b->binder_value, depth + 1) &&
               convertible_rec(k, a->binder_body,  b->binder_body,  depth + 1);
    case III_TM_APP:
        return convertible_rec(k, a->app_fun, b->app_fun, depth + 1) &&
               convertible_rec(k, a->app_arg, b->app_arg, depth + 1);
    case III_TM_CTOR:
        if (a->ctor_ind != b->ctor_ind || a->ctor_idx != b->ctor_idx ||
            a->ctor_argc != b->ctor_argc) return 0;
        for (uint32_t i = 0; i < a->ctor_argc; ++i)
            if (!convertible_rec(k, a->ctor_args[i], b->ctor_args[i], depth + 1))
                return 0;
        return 1;
    case III_TM_MATCH:
        if (a->match_ind != b->match_ind || a->match_arm_count != b->match_arm_count)
            return 0;
        if (!convertible_rec(k, a->match_scrut,  b->match_scrut,  depth + 1)) return 0;
        if (!convertible_rec(k, a->match_motive, b->match_motive, depth + 1)) return 0;
        for (uint32_t i = 0; i < a->match_arm_count; ++i)
            if (!convertible_rec(k, a->match_arms[i], b->match_arms[i], depth + 1))
                return 0;
        return 1;
    }
    return 0;
}

bool iii_term_convertible(iii_term_kernel_t *k, iii_term_t *a, iii_term_t *b) {
    return convertible_rec(k, a, b, 0) != 0;
}

/* ------------------------------------------------------------------ */
/* Inductive type schemata                                             */
/* ------------------------------------------------------------------ */

typedef struct {
    iii_ind_id_t id;
    iii_sort_t   sort;       /* the universe the inductive lives in */
    uint16_t     ctor_count;
    uint16_t     ctor_arity[8];
    /* For simplicity we treat all constructor arguments as of type
     * `Self`-or-payload-primitive; the kernel uses positivity check
     * on user-defined inductives (always-pass for built-ins). */
} iii_ind_decl_t;

static const iii_ind_decl_t g_inductives[III_IND__COUNT] = {
    /* Bool : Type_0; ctors: false, true */
    { III_IND_BOOL,  III_SORT_TYPE0, 2, { 0, 0, 0, 0, 0, 0, 0, 0 } },
    /* Trit : Type_0; ctors: NEG, ZERO, POS */
    { III_IND_TRIT,  III_SORT_TYPE0, 3, { 0, 0, 0, 0, 0, 0, 0, 0 } },
    /* Hexad : Type_0; one ctor of arity 6 (six trits) */
    { III_IND_HEXAD, III_SORT_TYPE0, 1, { 6, 0, 0, 0, 0, 0, 0, 0 } },
    /* Phase : Type_0; ctors: R-2, R-1, R0, R3 */
    { III_IND_PHASE, III_SORT_TYPE0, 4, { 0, 0, 0, 0, 0, 0, 0, 0 } },
    /* Tier  : Type_0; ctors: transient, host_file, federation, constitutional */
    { III_IND_TIER,  III_SORT_TYPE0, 4, { 0, 0, 0, 0, 0, 0, 0, 0 } },
    /* Epoch : Type_0; one ctor wrapping a u64 (we treat as nat-literal) */
    { III_IND_EPOCH, III_SORT_TYPE0, 1, { 1, 0, 0, 0, 0, 0, 0, 0 } },
    /* List  : Type_0; ctors: nil, cons of arity 2 (head, tail) */
    { III_IND_LIST,  III_SORT_TYPE0, 2, { 0, 2, 0, 0, 0, 0, 0, 0 } },
};

bool iii_term_positivity_ok(iii_term_kernel_t *k, iii_term_t *ctor_arg_type, iii_ind_id_t self_id) {
    /* Positivity: `self_id` must not appear in the *negative* (left)
     * position of a Pi inside ctor_arg_type. */
    (void)k;
    if (!ctor_arg_type) return true;
    switch (ctor_arg_type->kind) {
    case III_TM_PI:
        /* In the domain, self_id must not appear at all. */
        if (ctor_arg_type->binder_type) {
            iii_term_t *d = ctor_arg_type->binder_type;
            /* DFS search for `Ind self_id` in d. */
            /* (Bounded depth.) */
            int sp = 0;
            iii_term_t *stk[64]; stk[sp++] = d;
            while (sp > 0) {
                iii_term_t *c = stk[--sp];
                if (!c) continue;
                if (c->kind == III_TM_IND && c->ind_id == self_id) return false;
                switch (c->kind) {
                case III_TM_LAM: case III_TM_PI:
                    if (sp + 2 < 64) {
                        stk[sp++] = c->binder_type;
                        stk[sp++] = c->binder_body;
                    }
                    break;
                case III_TM_LET:
                    if (sp + 3 < 64) {
                        stk[sp++] = c->binder_type;
                        stk[sp++] = c->binder_value;
                        stk[sp++] = c->binder_body;
                    }
                    break;
                case III_TM_APP:
                    if (sp + 2 < 64) {
                        stk[sp++] = c->app_fun;
                        stk[sp++] = c->app_arg;
                    }
                    break;
                default: break;
                }
            }
        }
        return iii_term_positivity_ok(k, ctor_arg_type->binder_body, self_id);
    default:
        return true;
    }
}

/* ------------------------------------------------------------------ */
/* Type-checking                                                       */
/* ------------------------------------------------------------------ */

static iii_term_t *typeof_rec(iii_term_kernel_t *k, iii_term_t **gamma, uint32_t depth,
                              iii_term_t *t, iii_type_err_code_t *err);

static int sort_of_type(iii_term_kernel_t *k, iii_term_t **gamma, uint32_t depth,
                        iii_term_t *T, iii_sort_t *out, iii_type_err_code_t *err) {
    iii_type_err_code_t e = TYPE_CHK_OK;
    iii_term_t *st = typeof_rec(k, gamma, depth, T, &e);
    if (!st) { if (err) *err = e ? e : TYPE_PROOF_003_BAD_SORT; return -1; }
    iii_term_t *stn = iii_term_normalize(k, st, 4096, NULL);
    if (!stn || stn->kind != III_TM_SORT) {
        if (err) *err = TYPE_PROOF_003_BAD_SORT;
        return -1;
    }
    *out = stn->sort;
    return 0;
}

static iii_term_t *typeof_rec(iii_term_kernel_t *k, iii_term_t **gamma, uint32_t depth,
                              iii_term_t *t, iii_type_err_code_t *err) {
    if (!t) { if (err) *err = TYPE_PROOF_005_BAD_CERT; return NULL; }
    switch (t->kind) {
    case III_TM_SORT:
        return iii_tm_sort(k, iii_sort_succ(t->sort));
    case III_TM_VAR:
        if (t->var_idx < 0 || (uint32_t)t->var_idx >= depth) {
            if (err) *err = TYPE_PROOF_001_VAR_UNBOUND;
            return NULL;
        }
        /* Lift the bound type by var_idx+1 to bring it into current scope. */
        return iii_term_lift(k, gamma[depth - 1 - t->var_idx], 0, t->var_idx + 1);
    case III_TM_CONST: {
        const iii_term_t *ty = NULL;
        if (!iii_term_kernel_lookup(k, t->const_id, &ty) || !ty) {
            if (err) *err = TYPE_PROOF_001_VAR_UNBOUND;
            return NULL;
        }
        return (iii_term_t*)ty;
    }
    case III_TM_PI: {
        iii_sort_t s_dom, s_cod;
        if (sort_of_type(k, gamma, depth, t->binder_type, &s_dom, err) < 0) return NULL;
        if (depth + 1 > 256) { if (err) *err = TYPE_PROOF_006_KERNEL_DIVERGED; return NULL; }
        iii_term_t *ng[256];
        memcpy(ng, gamma, depth * sizeof *gamma);
        ng[depth] = t->binder_type;
        if (sort_of_type(k, ng, depth + 1, t->binder_body, &s_cod, err) < 0) return NULL;
        return iii_tm_sort(k, iii_sort_pi(s_dom, s_cod));
    }
    case III_TM_LAM: {
        iii_sort_t s_dom;
        if (sort_of_type(k, gamma, depth, t->binder_type, &s_dom, err) < 0) return NULL;
        (void)s_dom;
        if (depth + 1 > 256) { if (err) *err = TYPE_PROOF_006_KERNEL_DIVERGED; return NULL; }
        iii_term_t *ng[256];
        memcpy(ng, gamma, depth * sizeof *gamma);
        ng[depth] = t->binder_type;
        iii_type_err_code_t e2 = TYPE_CHK_OK;
        iii_term_t *body_ty = typeof_rec(k, ng, depth + 1, t->binder_body, &e2);
        if (!body_ty) { if (err) *err = e2; return NULL; }
        return iii_tm_pi(k, t->binder_name, t->binder_type, body_ty);
    }
    case III_TM_LET: {
        iii_sort_t s;
        if (sort_of_type(k, gamma, depth, t->binder_type, &s, err) < 0) return NULL;
        (void)s;
        iii_type_err_code_t e2 = TYPE_CHK_OK;
        iii_term_t *vt = typeof_rec(k, gamma, depth, t->binder_value, &e2);
        if (!vt) { if (err) *err = e2; return NULL; }
        if (!iii_term_convertible(k, vt, t->binder_type)) {
            if (err) *err = TYPE_PROOF_002_NOT_CONVERTIBLE;
            return NULL;
        }
        if (depth + 1 > 256) { if (err) *err = TYPE_PROOF_006_KERNEL_DIVERGED; return NULL; }
        iii_term_t *ng[256];
        memcpy(ng, gamma, depth * sizeof *gamma);
        ng[depth] = t->binder_type;
        iii_term_t *bt = typeof_rec(k, ng, depth + 1, t->binder_body, &e2);
        if (!bt) { if (err) *err = e2; return NULL; }
        /* Substitute the let-value into the body type to avoid leaking the binder. */
        return iii_term_subst(k, bt, t->binder_value);
    }
    case III_TM_APP: {
        iii_type_err_code_t e2 = TYPE_CHK_OK;
        iii_term_t *ft = typeof_rec(k, gamma, depth, t->app_fun, &e2);
        if (!ft) { if (err) *err = e2; return NULL; }
        iii_term_t *ftn = iii_term_normalize(k, ft, 4096, NULL);
        if (!ftn || ftn->kind != III_TM_PI) {
            if (err) *err = TYPE_CHK_013_APP_FUNCTION_NOT_PI;
            return NULL;
        }
        iii_term_t *at = typeof_rec(k, gamma, depth, t->app_arg, &e2);
        if (!at) { if (err) *err = e2; return NULL; }
        if (!iii_term_convertible(k, at, ftn->binder_type)) {
            if (err) *err = TYPE_CHK_014_APP_ARG_MISMATCH;
            return NULL;
        }
        return iii_term_subst(k, ftn->binder_body, t->app_arg);
    }
    case III_TM_IND: {
        if ((int)t->ind_id < 0 || t->ind_id >= III_IND__COUNT) {
            if (err) *err = TYPE_PROOF_007_BAD_INDUCTIVE;
            return NULL;
        }
        return iii_tm_sort(k, g_inductives[t->ind_id].sort);
    }
    case III_TM_CTOR: {
        if ((int)t->ctor_ind < 0 || t->ctor_ind >= III_IND__COUNT) {
            if (err) *err = TYPE_PROOF_007_BAD_INDUCTIVE;
            return NULL;
        }
        const iii_ind_decl_t *d = &g_inductives[t->ctor_ind];
        if (t->ctor_idx >= d->ctor_count || t->ctor_argc != d->ctor_arity[t->ctor_idx]) {
            if (err) *err = TYPE_PROOF_007_BAD_INDUCTIVE;
            return NULL;
        }
        /* H6 (mig2): a hexad built structurally from six CONCRETE trit literals
         * must be reachable; a bricking pattern is a TYPE ERROR -- the same rule
         * as the III_TM_HEXAD literal case, extended to the constructor path.  A
         * pillar that is not a concrete trit leaves the hexad open (not bricking),
         * so the gate fires only on a fully-concrete non-reachable hexad. */
        if (t->ctor_ind == III_IND_HEXAD) {
            uint16_t packed = 0u; uint16_t pw = 1u; int all_trit = 1;
            for (uint32_t hi = 0; hi < 6u; ++hi) {
                iii_term_t *an = iii_term_normalize(k, t->ctor_args[hi], 4096, NULL);
                if (!an || an->kind != III_TM_TRIT) { all_trit = 0; break; }
                packed = (uint16_t)(packed + (uint16_t)((uint16_t)an->trit_value * pw));
                pw = (uint16_t)(pw * 3u);
            }
            if (all_trit && !iii_hexad_packed_admitted(packed)) {
                if (err) *err = TYPE_HEXAD_005_BRICKING;
                return NULL;
            }
        }
        return iii_tm_ind(k, t->ctor_ind);
    }
    case III_TM_MATCH: {
        if ((int)t->match_ind < 0 || t->match_ind >= III_IND__COUNT) {
            if (err) *err = TYPE_PROOF_007_BAD_INDUCTIVE;
            return NULL;
        }
        const iii_ind_decl_t *d = &g_inductives[t->match_ind];
        if (t->match_arm_count != d->ctor_count) {
            if (err) *err = TYPE_PROOF_008_PATTERN_NONEXHAUSTIVE;
            return NULL;
        }
        iii_type_err_code_t e2 = TYPE_CHK_OK;
        iii_term_t *st_ty = typeof_rec(k, gamma, depth, t->match_scrut, &e2);
        if (!st_ty) { if (err) *err = e2; return NULL; }
        iii_term_t *stn = iii_term_normalize(k, st_ty, 4096, NULL);
        if (!stn || stn->kind != III_TM_IND || stn->ind_id != t->match_ind) {
            if (err) *err = TYPE_PROOF_007_BAD_INDUCTIVE;
            return NULL;
        }
        /* Motive: assumed to be a closed type (the result type).  Each arm
         * must have type motive (for non-recursive arities = 0) or
         * Pi(args).motive otherwise. */
        return t->match_motive;
    }
    case III_TM_NAT:
        return iii_tm_ind(k, III_IND_EPOCH);
    case III_TM_TRIT:
        return iii_tm_ind(k, III_IND_TRIT);
    case III_TM_HEXAD:
        /* H6 (mig2): a non-reachable hexad is BRICKING -- it is a TYPE ERROR, not
         * a value.  The 729-entry reachability bitmap admits all but the six PFS
         * bricking hexads (spec §4.3); this realizes the Representability Theorem
         * as a kernel typing rule, so M3 bricking is literally unsayable.  An
         * out-of-range packed value (>728) is rejected by the bounds check too. */
        if (!iii_hexad_packed_admitted(t->hexad_value)) {
            if (err) *err = TYPE_HEXAD_005_BRICKING;
            return NULL;
        }
        return iii_tm_ind(k, III_IND_HEXAD);
    }
    if (err) *err = TYPE_PROOF_005_BAD_CERT;
    return NULL;
}

int iii_term_typeof(iii_term_kernel_t *k, iii_term_t **gamma, uint32_t depth,
                    iii_term_t *t, iii_term_t **out_ty) {
    iii_type_err_code_t err = TYPE_CHK_OK;
    iii_term_t *r = typeof_rec(k, gamma, depth, t, &err);
    if (!r) return err ? (int)err : (int)TYPE_PROOF_005_BAD_CERT;
    if (out_ty) *out_ty = r;
    return 0;
}

int iii_term_check(iii_term_kernel_t *k, iii_term_t **gamma, uint32_t depth,
                   iii_term_t *t, iii_term_t *T) {
    iii_term_t *got = NULL;
    int rc = iii_term_typeof(k, gamma, depth, t, &got);
    if (rc) return rc;
    if (!iii_term_convertible(k, got, T)) return TYPE_PROOF_002_NOT_CONVERTIBLE;
    return 0;
}

/* ------------------------------------------------------------------ */
/* Pretty-printing                                                     */
/* ------------------------------------------------------------------ */

static const char *sort_name(iii_sort_t s) {
    switch (s) {
    case III_SORT_PROP:  return "Prop";
    case III_SORT_TYPE0: return "Type_0";
    case III_SORT_TYPE1: return "Type_1";
    case III_SORT_TYPE2: return "Type_2";
    case III_SORT_TYPE3: return "Type_3";
    case III_SORT_TYPE4: return "Type_4";
    case III_SORT_TYPE5: return "Type_5";
    case III_SORT_TYPE6: return "Type_6";
    }
    return "?";
}

static const char *ind_name(iii_ind_id_t i) {
    switch (i) {
    case III_IND_BOOL:  return "Bool";
    case III_IND_TRIT:  return "Trit";
    case III_IND_HEXAD: return "Hexad";
    case III_IND_PHASE: return "Phase";
    case III_IND_TIER:  return "Tier";
    case III_IND_EPOCH: return "Epoch";
    case III_IND_LIST:  return "List";
    case III_IND__COUNT: break;
    }
    return "?Ind";
}

size_t iii_term_print(const iii_term_t *t, char *buf, size_t cap) {
    if (!t || cap == 0) return 0;
    int n = 0;
    switch (t->kind) {
    case III_TM_SORT:  n = snprintf(buf, cap, "%s", sort_name(t->sort)); break;
    case III_TM_VAR:   n = snprintf(buf, cap, "#%d", t->var_idx); break;
    case III_TM_CONST: n = snprintf(buf, cap, "const_%u", t->const_id); break;
    case III_TM_LAM: {
        n  = snprintf(buf, cap, "(λ%s:", t->binder_name ? t->binder_name : "_");
        n += (int)iii_term_print(t->binder_type, buf + n, cap > (size_t)n ? cap - n : 0);
        n += snprintf(buf + n, cap > (size_t)n ? cap - n : 0, ". ");
        n += (int)iii_term_print(t->binder_body, buf + n, cap > (size_t)n ? cap - n : 0);
        n += snprintf(buf + n, cap > (size_t)n ? cap - n : 0, ")");
        break;
    }
    case III_TM_PI: {
        n  = snprintf(buf, cap, "(Π%s:", t->binder_name ? t->binder_name : "_");
        n += (int)iii_term_print(t->binder_type, buf + n, cap > (size_t)n ? cap - n : 0);
        n += snprintf(buf + n, cap > (size_t)n ? cap - n : 0, ". ");
        n += (int)iii_term_print(t->binder_body, buf + n, cap > (size_t)n ? cap - n : 0);
        n += snprintf(buf + n, cap > (size_t)n ? cap - n : 0, ")");
        break;
    }
    case III_TM_LET: {
        n  = snprintf(buf, cap, "(let %s:", t->binder_name ? t->binder_name : "_");
        n += (int)iii_term_print(t->binder_type, buf + n, cap > (size_t)n ? cap - n : 0);
        n += snprintf(buf + n, cap > (size_t)n ? cap - n : 0, " := ");
        n += (int)iii_term_print(t->binder_value, buf + n, cap > (size_t)n ? cap - n : 0);
        n += snprintf(buf + n, cap > (size_t)n ? cap - n : 0, " in ");
        n += (int)iii_term_print(t->binder_body, buf + n, cap > (size_t)n ? cap - n : 0);
        n += snprintf(buf + n, cap > (size_t)n ? cap - n : 0, ")");
        break;
    }
    case III_TM_APP: {
        n  = snprintf(buf, cap, "(");
        n += (int)iii_term_print(t->app_fun, buf + n, cap > (size_t)n ? cap - n : 0);
        n += snprintf(buf + n, cap > (size_t)n ? cap - n : 0, " ");
        n += (int)iii_term_print(t->app_arg, buf + n, cap > (size_t)n ? cap - n : 0);
        n += snprintf(buf + n, cap > (size_t)n ? cap - n : 0, ")");
        break;
    }
    case III_TM_IND:   n = snprintf(buf, cap, "%s", ind_name(t->ind_id)); break;
    case III_TM_CTOR:
        n = snprintf(buf, cap, "%s.c%u(%u)", ind_name(t->ctor_ind), t->ctor_idx, t->ctor_argc);
        break;
    case III_TM_MATCH:
        n = snprintf(buf, cap, "match[%s]/%u", ind_name(t->match_ind), t->match_arm_count);
        break;
    case III_TM_NAT:   n = snprintf(buf, cap, "%llu",  (unsigned long long)t->nat_value); break;
    case III_TM_TRIT:
        n = snprintf(buf, cap, "%s",
                     t->trit_value == III_TRIT_NEG  ? "NEG"  :
                     t->trit_value == III_TRIT_ZERO ? "ZERO" : "POS");
        break;
    case III_TM_HEXAD: n = snprintf(buf, cap, "Hexad(%u)", (unsigned)t->hexad_value); break;
    }
    if (n < 0) n = 0;
    return (size_t)n;
}
