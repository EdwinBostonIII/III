/* III TYPES — type representation, environment, factories, and the
 * implementations of every typing rule from §2..§9 of the spec.
 *
 * Bidirectional inference and the AST-driven driver live in checker.c;
 * the CIC kernel lives in cic.c.  This file owns:
 *
 *   - iii_type_t storage (arena-allocated)
 *   - the environment (bindings + linear-cap usage table)
 *   - universe rules            (§2.1, §2.4, §10.3)
 *   - hexad-tag introduction    (§4.1, §4.2)
 *   - ring/phase rules          (§5.1, §5.2)
 *   - tier/epoch rules          (§6.1, §6.2)
 *   - linear cap rules          (§7.1, §7.2, §7.4)
 *   - epistemic rules           (§8.1, §8.2, §8.3)
 *   - constitutional/Möbius     (§9.1, §9.2, §9.3)
 *   - Reduction six-tuple       (§3.1..§3.5)
 *
 * Every rule is callable as a stand-alone API for testing.
 */
#include "iii/types.h"
#include "iii/types_term.h"
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

/* ------------------------------------------------------------------ */
/* Universe utilities                                                  */
/* ------------------------------------------------------------------ */

const char *iii_universe_name(iii_universe_t u) {
    switch (u) {
    case III_U_PROP:  return "Prop";
    case III_U_TYPE0: return "Type_0";
    case III_U_TYPE1: return "Type_1";
    case III_U_TYPE2: return "Type_2";
    case III_U_TYPE3: return "Type_3";
    case III_U_TYPE4: return "Type_4";
    case III_U_TYPE5: return "Type_5";
    case III_U_TYPE6: return "Type_6";
    }
    return "?";
}

iii_universe_t iii_universe_succ(iii_universe_t u) {
    if (u == III_U_PROP)   return III_U_TYPE0;
    if (u == III_U_TYPE6)  return III_U_TYPE6;  /* §2.1 U-Top */
    return (iii_universe_t)((int)u + 1);
}

iii_universe_t iii_universe_pi(iii_universe_t i, iii_universe_t j) {
    /* §2.4 — predicative i,j<6: max(i,j); impredicative top: i or j == 6 → 6. */
    if (j == III_U_TYPE6 || i == III_U_TYPE6) return III_U_TYPE6;
    int li = i == III_U_PROP ? 0 : (int)i;
    int lj = j == III_U_PROP ? 0 : (int)j;
    int m = li > lj ? li : lj;
    return (iii_universe_t)m;
}

bool iii_universe_lift_allowed(iii_universe_t from, iii_universe_t to) {
    /* §2.3 — non-cumulative except the single Prop → Type_0 lift. */
    if (from == to) return true;
    if (from == III_U_PROP && to == III_U_TYPE0) return true;
    return false;
}

/* ------------------------------------------------------------------ */
/* Phase / Tier / Ring helpers                                         */
/* ------------------------------------------------------------------ */

const char *iii_ring_name(iii_ring_t r) {
    switch (r) {
    case III_RING_R_MINUS_2: return "R-2";
    case III_RING_R_MINUS_1: return "R-1";
    case III_RING_R0:        return "R0";
    case III_RING_R3:        return "R3";
    case III_RING__COUNT: break;
    }
    return "?";
}

bool iii_phase_set_valid(iii_phase_set_t s) {
    return s.mask != 0 && (s.mask & ~((1u << III_RING__COUNT) - 1u)) == 0;
}

bool iii_phase_set_eq(iii_phase_set_t a, iii_phase_set_t b) {
    return a.mask == b.mask;
}

bool iii_phase_marshal_exists(iii_ring_t from, iii_ring_t to) {
    /* §5.2 — must follow the lattice R3 → R0 → R-1 → R-2 (or stay in
     * place).  Direct R3 ↔ R-2 is forbidden, as are R3 ↔ R-1. */
    if (from == to) return true;
    /* Adjacency in the chain. */
    if (from == III_RING_R3        && to == III_RING_R0)        return true;
    if (from == III_RING_R0        && to == III_RING_R3)        return true;
    if (from == III_RING_R0        && to == III_RING_R_MINUS_1) return true;
    if (from == III_RING_R_MINUS_1 && to == III_RING_R0)        return true;
    if (from == III_RING_R_MINUS_1 && to == III_RING_R_MINUS_2) return true;
    if (from == III_RING_R_MINUS_2 && to == III_RING_R_MINUS_1) return true;
    return false;
}

const char *iii_tier_name(iii_tier_t t) {
    switch (t) {
    case III_TIER_TRANSIENT:      return "transient";
    case III_TIER_HOST_FILE:      return "host_file";
    case III_TIER_FEDERATION:     return "federation";
    case III_TIER_CONSTITUTIONAL: return "constitutional";
    case III_TIER__COUNT: break;
    }
    return "?";
}

iii_tier_t iii_tier_max(iii_tier_t a, iii_tier_t b) {
    return (int)a > (int)b ? a : b;
}

/* ------------------------------------------------------------------ */
/* Arena for env                                                       */
/* ------------------------------------------------------------------ */

#define IIIE_BLOCK 4096

typedef struct iiie_chunk {
    struct iiie_chunk *next;
    size_t cap, used;
    uint8_t data[1];
} iiie_chunk_t;

static void *iiie_alloc(iii_type_env_t *e, size_t bytes);

/* ------------------------------------------------------------------ */
/* Env                                                                 */
/* ------------------------------------------------------------------ */

typedef struct iiie_binding {
    uint32_t name_id;
    iii_type_t *ty;
    bool linear;
    bool used;
    uint32_t scope_depth;
} iiie_binding_t;

struct iii_type_env {
    iiie_chunk_t *chunks;

    iiie_binding_t *bindings;
    size_t bindings_count, bindings_cap;
    uint32_t scope_depth;

    iii_type_diagnostic_t *diags;
    size_t diags_count, diags_cap;

    iii_term_kernel_t *kernel;

    uint64_t  current_epoch;
    uint16_t  coherence_floor_q14;
    uint16_t  uncertainty_threshold_q14;

    /* Hole table */
    iii_type_t **holes;
    size_t       holes_count, holes_cap;
    uint32_t     next_hole_id;
};

static void *iiie_alloc(iii_type_env_t *e, size_t bytes) {
    bytes = (bytes + 15u) & ~(size_t)15u;
    if (!e->chunks || e->chunks->used + bytes > e->chunks->cap) {
        size_t cap = bytes > IIIE_BLOCK ? bytes : IIIE_BLOCK;
        iiie_chunk_t *c = (iiie_chunk_t*)calloc(1, sizeof *c + cap);
        if (!c) return NULL;
        c->cap = cap; c->used = 0; c->next = e->chunks; e->chunks = c;
    }
    void *p = e->chunks->data + e->chunks->used;
    e->chunks->used += bytes;
    return p;
}

iii_type_env_t *iii_type_env_create(void) {
    iii_type_env_t *e = (iii_type_env_t*)calloc(1, sizeof *e);
    if (!e) return NULL;
    e->bindings_cap = 64;
    e->bindings = (iiie_binding_t*)calloc(e->bindings_cap, sizeof *e->bindings);
    e->diags_cap = 32;
    e->diags = (iii_type_diagnostic_t*)calloc(e->diags_cap, sizeof *e->diags);
    e->kernel = iii_term_kernel_create();
    e->coherence_floor_q14 = 15073;       /* 0.92q in Q14 */
    e->uncertainty_threshold_q14 = 13927; /* 0.85q in Q14 */
    e->holes_cap = 16;
    e->holes = (iii_type_t**)calloc(e->holes_cap, sizeof *e->holes);
    if (!e->bindings || !e->diags || !e->kernel || !e->holes) {
        iii_type_env_destroy(e);
        return NULL;
    }
    return e;
}

void iii_type_env_destroy(iii_type_env_t *e) {
    if (!e) return;
    iiie_chunk_t *c = e->chunks;
    while (c) { iiie_chunk_t *n = c->next; free(c); c = n; }
    free(e->bindings);
    free(e->diags);
    free(e->holes);
    iii_term_kernel_destroy(e->kernel);
    free(e);
}

void iii_type_env_set_current_epoch(iii_type_env_t *e, uint64_t n) { e->current_epoch = n; }
void iii_type_env_set_coherence_floor(iii_type_env_t *e, uint16_t q) { e->coherence_floor_q14 = q; }
void iii_type_env_set_uncertainty_threshold(iii_type_env_t *e, uint16_t q) { e->uncertainty_threshold_q14 = q; }

iii_term_kernel_t *iii_type_env_kernel(iii_type_env_t *e) { return e->kernel; }

uint32_t iii_type_env_bind(iii_type_env_t *e, uint32_t name_id, iii_type_t *t) {
    if (e->bindings_count == e->bindings_cap) {
        size_t nc = e->bindings_cap * 2;
        iiie_binding_t *nb = (iiie_binding_t*)realloc(e->bindings, nc * sizeof *nb);
        if (!nb) return 0;
        e->bindings = nb; e->bindings_cap = nc;
    }
    e->bindings[e->bindings_count].name_id = name_id;
    e->bindings[e->bindings_count].ty = t;
    e->bindings[e->bindings_count].linear = false;
    e->bindings[e->bindings_count].used = false;
    e->bindings[e->bindings_count].scope_depth = e->scope_depth;
    return (uint32_t)e->bindings_count++;
}

uint32_t iii_type_env_bind_linear(iii_type_env_t *e, uint32_t name_id, iii_type_t *cap_ty) {
    uint32_t i = iii_type_env_bind(e, name_id, cap_ty);
    if (i || e->bindings_count) e->bindings[e->bindings_count - 1].linear = true;
    return i;
}

void iii_type_env_pop(iii_type_env_t *e) {
    if (e->bindings_count) e->bindings_count--;
}

iii_type_t *iii_type_env_lookup(iii_type_env_t *e, uint32_t name_id) {
    for (size_t i = e->bindings_count; i-- > 0; ) {
        if (e->bindings[i].name_id == name_id) return e->bindings[i].ty;
    }
    return NULL;
}

bool iii_type_env_use_linear(iii_type_env_t *e, uint32_t name_id) {
    for (size_t i = e->bindings_count; i-- > 0; ) {
        if (e->bindings[i].name_id == name_id) {
            if (!e->bindings[i].linear) return true;  /* non-linear: free use */
            if (e->bindings[i].used) {
                iii_type_env_emit(e, TYPE_LIN_001_USED_TWICE, NULL,
                                  "capability used twice");
                return false;
            }
            e->bindings[i].used = true;
            return true;
        }
    }
    return false;
}

int iii_type_env_check_linear_complete(iii_type_env_t *e) {
    int errs = 0;
    for (size_t i = 0; i < e->bindings_count; ++i) {
        if (e->bindings[i].linear && !e->bindings[i].used) {
            iii_type_env_emit(e, TYPE_LIN_002_DROPPED_UNUSED, NULL,
                              "capability dropped unused");
            errs++;
        }
    }
    return errs;
}

size_t iii_type_env_diag_count(const iii_type_env_t *e) { return e->diags_count; }
const iii_type_diagnostic_t *iii_type_env_diag_at(const iii_type_env_t *e, size_t i) {
    return i < e->diags_count ? &e->diags[i] : NULL;
}

void iii_type_env_emit(iii_type_env_t *e, iii_type_err_code_t code,
                       const iii_ast_node_t *where, const char *fmt, ...) {
    if (e->diags_count == e->diags_cap) {
        size_t nc = e->diags_cap * 2;
        iii_type_diagnostic_t *nd = (iii_type_diagnostic_t*)realloc(e->diags, nc * sizeof *nd);
        if (!nd) return;
        e->diags = nd; e->diags_cap = nc;
    }
    iii_type_diagnostic_t *d = &e->diags[e->diags_count++];
    memset(d, 0, sizeof *d);
    d->code = code;
    if (where) {
        d->span_start = where->span_start;
        d->span_end   = where->span_end;
        d->line       = where->line;
        d->col        = where->col;
    }
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(d->message, sizeof d->message, fmt, ap);
    va_end(ap);
}

/* ------------------------------------------------------------------ */
/* Type factories                                                      */
/* ------------------------------------------------------------------ */

static iii_type_t *new_ty(iii_type_env_t *e, iii_type_kind_t k) {
    iii_type_t *t = (iii_type_t*)iiie_alloc(e, sizeof *t);
    if (!t) return NULL;
    t->kind = k;
    return t;
}

iii_universe_t iii_type_universe(const iii_type_t *t) {
    if (!t) return III_U_TYPE0;
    return t->univ;
}

iii_type_t *iii_ty_universe(iii_type_env_t *e, iii_universe_t u) {
    iii_type_t *t = new_ty(e, III_TY_UNIVERSE);
    if (!t) return NULL;
    t->univ = iii_universe_succ(u);  /* the type of `Type_i` is `Type_{i+1}` */
    return t;
}

static iii_universe_t prim_universe(iii_prim_id_t p) {
    switch (p) {
    case III_PRIM_HEXAD: case III_PRIM_TRIT: case III_PRIM_PHASE:
    case III_PRIM_TIER:  case III_PRIM_EPOCH:
        return III_U_TYPE0;     /* base */
    case III_PRIM_WITNESS: case III_PRIM_GLYPH: case III_PRIM_MHASH:
        return III_U_TYPE3;
    case III_PRIM_DOMAIN: case III_PRIM_QUESTION: case III_PRIM_RANGE:
        return III_U_TYPE3;
    default:
        return III_U_TYPE0;
    }
}

iii_type_t *iii_ty_prim(iii_type_env_t *e, iii_prim_id_t p) {
    iii_type_t *t = new_ty(e, III_TY_PRIM);
    if (!t) return NULL;
    t->prim = p;
    t->univ = prim_universe(p);
    return t;
}

iii_type_t *iii_ty_pi(iii_type_env_t *e, const char *name,
                      iii_type_t *dom, iii_type_t *cod) {
    iii_type_t *t = new_ty(e, III_TY_PI);
    if (!t) return NULL;
    t->binder_name = name;
    t->dom = dom; t->cod = cod;
    t->dependent = true;
    t->univ = iii_universe_pi(iii_type_universe(dom), iii_type_universe(cod));
    return t;
}

iii_type_t *iii_ty_fun(iii_type_env_t *e, iii_type_t *dom, iii_type_t *cod) {
    iii_type_t *t = new_ty(e, III_TY_FUN);
    if (!t) return NULL;
    t->dom = dom; t->cod = cod;
    t->dependent = false;
    t->univ = iii_universe_pi(iii_type_universe(dom), iii_type_universe(cod));
    return t;
}

iii_type_t *iii_ty_tuple(iii_type_env_t *e, iii_type_t **elts, uint32_t n) {
    iii_type_t *t = new_ty(e, III_TY_TUPLE);
    if (!t) return NULL;
    t->elements = (iii_type_t**)iiie_alloc(e, n * sizeof *elts);
    if (n && !t->elements) return NULL;
    if (n) memcpy(t->elements, elts, n * sizeof *elts);
    t->element_count = n;
    iii_universe_t u = III_U_TYPE0;
    for (uint32_t i = 0; i < n; ++i) {
        iii_universe_t ui = iii_type_universe(elts[i]);
        if ((int)ui > (int)u) u = ui;
    }
    t->univ = u;
    return t;
}

iii_type_t *iii_ty_named(iii_type_env_t *e, uint32_t name_id) {
    iii_type_t *t = new_ty(e, III_TY_NAMED);
    if (!t) return NULL;
    t->named_id = name_id;
    t->univ = III_U_TYPE0;
    return t;
}

/* §4.1 hexad-tag introduction */
iii_type_t *iii_ty_hexad_tag(iii_type_env_t *e, iii_type_t *inner, iii_hexad_t h) {
    iii_universe_t u = iii_type_universe(inner);
    if ((int)u > (int)III_U_TYPE5) {
        iii_type_env_emit(e, TYPE_HEXAD_001_TAG_BAD_TYPE, NULL,
                          "hexad tag applied to type in %s (must be ≤ Type_5)",
                          iii_universe_name(u));
        return NULL;
    }
    if (!iii_hexad_admitted(&h)) {
        /* Check if it's one of the bricking presets, for nicer message. */
        for (int b = 0; b < (int)III_BRICK__COUNT; ++b) {
            iii_hexad_t bh = iii_hexad_brick((iii_brick_t)b);
            if (iii_hexad_eq(&bh, &h)) {
                iii_type_env_emit(e, TYPE_HEXAD_005_BRICKING, NULL,
                                  "untypable bricking operation: %s",
                                  iii_hexad_brick_name((iii_brick_t)b));
                return NULL;
            }
        }
        iii_type_env_emit(e, TYPE_HEXAD_002_OUT_OF_REACH, NULL,
                          "hexad outside reachable set (packed=%u)",
                          (unsigned)iii_hexad_pack(&h));
        return NULL;
    }
    iii_type_t *t = new_ty(e, III_TY_HEXAD_TAG);
    if (!t) return NULL;
    t->tag_inner = inner;
    t->tag_hexad = h;
    t->univ = u;
    return t;
}

/* §4.2 hexad compose */
iii_type_t *iii_ty_hexad_compose(iii_type_env_t *e, iii_type_t *t1, iii_type_t *t2) {
    if (!t1 || !t2 || t1->kind != III_TY_HEXAD_TAG || t2->kind != III_TY_HEXAD_TAG) {
        iii_type_env_emit(e, TYPE_HEXAD_001_TAG_BAD_TYPE, NULL,
                          "hexad compose requires two hexad-tagged types");
        return NULL;
    }
    iii_hexad_t h3 = iii_hexad_compose(&t1->tag_hexad, &t2->tag_hexad);
    if (!iii_hexad_admitted(&h3)) {
        iii_type_env_emit(e, TYPE_HEXAD_003_COMPOSE_OUT_OF_REACH, NULL,
                          "composed hexad %u outside reachable set",
                          (unsigned)iii_hexad_pack(&h3));
        return NULL;
    }
    /* Use max universe of inner types per spec rule. */
    iii_universe_t u = (int)iii_type_universe(t1->tag_inner) >
                       (int)iii_type_universe(t2->tag_inner)
                       ? iii_type_universe(t1->tag_inner)
                       : iii_type_universe(t2->tag_inner);
    iii_type_t *inner = new_ty(e, III_TY_TUPLE);
    inner->elements = (iii_type_t**)iiie_alloc(e, 2 * sizeof(iii_type_t*));
    inner->elements[0] = t1->tag_inner;
    inner->elements[1] = t2->tag_inner;
    inner->element_count = 2;
    inner->univ = u;
    return iii_ty_hexad_tag(e, inner, h3);
}

/* §5.1 ring tag */
iii_type_t *iii_ty_ring_tag(iii_type_env_t *e, iii_type_t *inner, iii_phase_set_t r) {
    if (r.mask == 0) {
        iii_type_env_emit(e, TYPE_RING_003_EMPTY_PHASE_SET, NULL,
                          "phase set must be non-empty");
        return NULL;
    }
    if (!iii_phase_set_valid(r)) {
        iii_type_env_emit(e, TYPE_RING_002_BAD_PHASE_SET, NULL,
                          "phase set has invalid ring (mask=0x%x)", r.mask);
        return NULL;
    }
    iii_type_t *t = new_ty(e, III_TY_RING_TAG);
    if (!t) return NULL;
    t->tag_inner = inner;
    t->tag_phase = r;
    t->univ = iii_type_universe(inner);
    return t;
}

/* §5.2 phase cross */
iii_type_t *iii_ty_phase_cross(iii_type_env_t *e, iii_type_t *v,
                               iii_phase_set_t target_set,
                               iii_ring_t from, iii_ring_t to) {
    if (!iii_phase_marshal_exists(from, to)) {
        iii_type_env_emit(e, TYPE_RING_001_NO_MARSHAL, NULL,
                          "no marshalling constructor between %s and %s",
                          iii_ring_name(from), iii_ring_name(to));
        return NULL;
    }
    /* The marshalled value's inner type stays the same; ring tag updates. */
    iii_type_t *inner = (v && v->kind == III_TY_RING_TAG) ? v->tag_inner : v;
    return iii_ty_ring_tag(e, inner, target_set);
}

/* §6.1 tier tag */
iii_type_t *iii_ty_tier_tag(iii_type_env_t *e, iii_type_t *inner, iii_tier_t k) {
    if ((int)k < 0 || k >= III_TIER__COUNT) {
        iii_type_env_emit(e, TYPE_TIER_001_BAD_TIER, NULL,
                          "invalid tier value %d", (int)k);
        return NULL;
    }
    iii_type_t *t = new_ty(e, III_TY_TIER_TAG);
    if (!t) return NULL;
    t->tag_inner = inner;
    t->tag_tier  = k;
    t->univ      = iii_type_universe(inner);
    return t;
}

/* §6.1 tier compose: max */
iii_type_t *iii_ty_tier_compose(iii_type_env_t *e, iii_type_t *a, iii_type_t *b) {
    if (!a || !b || a->kind != III_TY_TIER_TAG || b->kind != III_TY_TIER_TAG) {
        iii_type_env_emit(e, TYPE_TIER_001_BAD_TIER, NULL,
                          "tier compose requires tier-tagged operands");
        return NULL;
    }
    iii_tier_t k = iii_tier_max(a->tag_tier, b->tag_tier);
    return iii_ty_tier_tag(e, a->tag_inner, k);
}

/* §6.2 epoch tag */
iii_type_t *iii_ty_epoch_tag(iii_type_env_t *e, iii_type_t *inner, iii_epoch_t n) {
    if (n.n > e->current_epoch && e->current_epoch != 0) {
        iii_type_env_emit(e, TYPE_EPOCH_002_BAD_EPOCH, NULL,
                          "epoch %llu exceeds current %llu",
                          (unsigned long long)n.n,
                          (unsigned long long)e->current_epoch);
        return NULL;
    }
    iii_type_t *t = new_ty(e, III_TY_EPOCH_TAG);
    if (!t) return NULL;
    t->tag_inner = inner;
    t->tag_epoch = n;
    t->univ      = iii_type_universe(inner);
    return t;
}

/* §6.2 epoch bridge */
iii_type_t *iii_ty_epoch_bridge(iii_type_env_t *e,
                                iii_type_t *a, iii_type_t *b,
                                bool bridge_attribute_present) {
    if (!a || !b || a->kind != III_TY_EPOCH_TAG || b->kind != III_TY_EPOCH_TAG) {
        iii_type_env_emit(e, TYPE_EPOCH_002_BAD_EPOCH, NULL,
                          "epoch bridge requires two epoch-tagged operands");
        return NULL;
    }
    if (a->tag_epoch.n == b->tag_epoch.n) return iii_ty_epoch_tag(e, a->tag_inner, b->tag_epoch);
    if (!bridge_attribute_present) {
        iii_type_env_emit(e, TYPE_EPOCH_001_CROSS_EPOCH_NO_BRIDGE, NULL,
                          "cross-epoch %llu->%llu requires @epoch_bridge",
                          (unsigned long long)a->tag_epoch.n,
                          (unsigned long long)b->tag_epoch.n);
        return NULL;
    }
    return iii_ty_epoch_tag(e, a->tag_inner, b->tag_epoch);
}

/* §7.1 cap form */
iii_type_t *iii_ty_cap(iii_type_env_t *e, iii_cap_perm_t p, uint32_t range_id) {
    if ((int)p < 0 || p >= III_CAP__COUNT) {
        iii_type_env_emit(e, TYPE_LIN_003_BAD_PERM, NULL, "invalid permission %d", (int)p);
        return NULL;
    }
    iii_type_t *t = new_ty(e, III_TY_CAP);
    if (!t) return NULL;
    t->cap_perm     = p;
    t->cap_range_id = range_id;
    t->cap_replicates = III_REPL_NONE;
    t->univ = III_U_TYPE4;     /* §7.1 — Type_4 */
    return t;
}

/* §7.2 linear use — looks up the capability in the env and consumes it. */
iii_type_t *iii_ty_linear_use(iii_type_env_t *e, uint32_t cap_name_id) {
    iii_type_t *cap = iii_type_env_lookup(e, cap_name_id);
    if (!cap || cap->kind != III_TY_CAP) {
        iii_type_env_emit(e, TYPE_LIN_004_NO_GLYPH, NULL,
                          "no capability bound to id %u", cap_name_id);
        return NULL;
    }
    if (!iii_type_env_use_linear(e, cap_name_id)) {
        /* error already emitted */
        return NULL;
    }
    return iii_ty_prim(e, III_PRIM_UNIT);
}

/* §8.1 uncertainty */
iii_type_t *iii_ty_uncertainty(iii_type_env_t *e, uint32_t dom_id,
                               uint16_t conf_q14, uint32_t qs) {
    if (conf_q14 > 16384) {
        iii_type_env_emit(e, TYPE_EPI_001_BAD_CONFIDENCE, NULL,
                          "confidence %u out of [0, 16384]", conf_q14);
        return NULL;
    }
    iii_type_t *t = new_ty(e, III_TY_UNCERTAINTY);
    if (!t) return NULL;
    t->uncertainty.domain_id      = dom_id;
    t->uncertainty.confidence_q14 = conf_q14;
    t->uncertainty.question_count = qs;
    t->univ = III_U_TYPE0;
    return t;
}

iii_uncertainty_t iii_uncertainty_combine(iii_uncertainty_t a, iii_uncertainty_t b) {
    iii_uncertainty_t r = a;
    /* Multiplicative confidence (Q14 × Q14 → Q14). */
    uint32_t prod = (uint32_t)a.confidence_q14 * (uint32_t)b.confidence_q14;
    r.confidence_q14 = (uint16_t)(prod >> 14);
    r.question_count = a.question_count + b.question_count;
    /* Domain: unchanged from `a`. */
    return r;
}

/* §3 reduction */
iii_type_t *iii_ty_reduction(iii_type_env_t *e,
                             iii_type_t *F, iii_type_t *I,
                             iii_hexad_t H, iii_phase_set_t P, iii_epoch_t E_) {
    if (!F || !I) {
        iii_type_env_emit(e, TYPE_CHK_021_REDUCTION_FIELD_KIND, NULL,
                          "Reduction missing F or I component");
        return NULL;
    }
    iii_universe_t uF = iii_type_universe(F);
    iii_universe_t uI = iii_type_universe(I);
    if ((int)uF > (int)III_U_TYPE5 || (int)uI > (int)III_U_TYPE5) {
        iii_type_env_emit(e, TYPE_CHK_021_REDUCTION_FIELD_KIND, NULL,
                          "Reduction F/I universes must be ≤ Type_5");
        return NULL;
    }
    if (!iii_hexad_admitted(&H)) {
        iii_type_env_emit(e, TYPE_HEXAD_002_OUT_OF_REACH, NULL,
                          "Reduction hexad not admitted");
        return NULL;
    }
    if (!iii_phase_set_valid(P)) {
        iii_type_env_emit(e, TYPE_RING_002_BAD_PHASE_SET, NULL,
                          "Reduction phase set invalid");
        return NULL;
    }
    iii_type_t *t = new_ty(e, III_TY_REDUCTION);
    if (!t) return NULL;
    t->r_forward = F;
    t->r_inverse = I;
    t->r_hexad = H;
    t->r_hexad_set = true;
    t->r_phase = P;
    t->r_epoch = E_;
    t->univ = III_U_TYPE6;     /* §3.1 */
    return t;
}

/* §3.3 projections */
iii_type_t *iii_ty_reduction_proj(iii_type_env_t *e, iii_type_t *r, const char *name) {
    if (!r || r->kind != III_TY_REDUCTION) {
        iii_type_env_emit(e, TYPE_CHK_021_REDUCTION_FIELD_KIND, NULL,
                          "projection from non-Reduction value");
        return NULL;
    }
    if (!strcmp(name, "forward")) return r->r_forward;
    if (!strcmp(name, "inverse")) return r->r_inverse;
    if (!strcmp(name, "witness")) return iii_ty_prim(e, III_PRIM_WITNESS);
    if (!strcmp(name, "hexad"))   return iii_ty_prim(e, III_PRIM_HEXAD);
    if (!strcmp(name, "phase"))   return iii_ty_prim(e, III_PRIM_PHASE);
    if (!strcmp(name, "epoch"))   return iii_ty_prim(e, III_PRIM_EPOCH);
    iii_type_env_emit(e, TYPE_CHK_023_REDUCTION_PROJ, NULL,
                      "unknown Reduction projector '%s'", name);
    return NULL;
}

/* §3.4 compose */
iii_type_t *iii_ty_reduction_compose(iii_type_env_t *e, iii_type_t *r1, iii_type_t *r2) {
    if (!r1 || !r2 || r1->kind != III_TY_REDUCTION || r2->kind != III_TY_REDUCTION) {
        iii_type_env_emit(e, TYPE_CHK_021_REDUCTION_FIELD_KIND, NULL,
                          "Reduction compose: operands must be Reductions");
        return NULL;
    }
    if (!iii_phase_set_eq(r1->r_phase, r2->r_phase)) {
        iii_type_env_emit(e, TYPE_CHK_024_REDUCTION_COMPOSE_PHASE, NULL,
                          "Reduction compose: phase sets must match");
        return NULL;
    }
    if (r1->r_epoch.n != r2->r_epoch.n) {
        iii_type_env_emit(e, TYPE_CHK_025_REDUCTION_COMPOSE_EPOCH, NULL,
                          "Reduction compose: epochs must match");
        return NULL;
    }
    iii_hexad_t h3 = iii_hexad_compose(&r1->r_hexad, &r2->r_hexad);
    if (!iii_hexad_admitted(&h3)) {
        iii_type_env_emit(e, TYPE_HEXAD_003_COMPOSE_OUT_OF_REACH, NULL,
                          "Reduction compose: composed hexad unreachable");
        return NULL;
    }
    /* Forward: F1 ∘ F2 — represented as a tuple type for opacity. */
    iii_type_t *F[2] = { r1->r_forward, r2->r_forward };
    iii_type_t *I[2] = { r2->r_inverse, r1->r_inverse };
    iii_type_t *Fcomp = iii_ty_tuple(e, F, 2);
    iii_type_t *Icomp = iii_ty_tuple(e, I, 2);
    iii_type_t *out = iii_ty_reduction(e, Fcomp, Icomp, h3, r1->r_phase, r1->r_epoch);
    if (out && (r1->r_has_uncertainty || r2->r_has_uncertainty)) {
        out->r_has_uncertainty = true;
        out->r_uncertainty = iii_uncertainty_combine(
            r1->r_has_uncertainty ? r1->r_uncertainty
                                  : (iii_uncertainty_t){0, 16384, 0},
            r2->r_has_uncertainty ? r2->r_uncertainty
                                  : (iii_uncertainty_t){0, 16384, 0});
    }
    return out;
}

/* §3.5 inverse */
iii_type_t *iii_ty_reduction_inverse(iii_type_env_t *e, iii_type_t *r) {
    if (!r || r->kind != III_TY_REDUCTION) {
        iii_type_env_emit(e, TYPE_CHK_026_REDUCTION_INVERSE, NULL,
                          "inverse applied to non-Reduction");
        return NULL;
    }
    iii_hexad_t h2 = iii_hexad_neg(&r->r_hexad);
    return iii_ty_reduction(e, r->r_inverse, r->r_forward, h2, r->r_phase, r->r_epoch);
}

/* §9 propositions */
iii_type_t *iii_ty_prop(iii_type_env_t *e, iii_prop_kind_t pk) {
    iii_type_t *t = new_ty(e, III_TY_PROP_FORM);
    if (!t) return NULL;
    t->prop_kind = pk;
    t->univ = III_U_PROP;
    return t;
}

/* §10.2 hole */
iii_type_t *iii_ty_hole(iii_type_env_t *e, iii_universe_t expected) {
    iii_type_t *t = new_ty(e, III_TY_HOLE);
    if (!t) return NULL;
    t->hole_id = ++e->next_hole_id;
    t->hole_expected_univ = expected;
    t->univ = expected;
    if (e->holes_count == e->holes_cap) {
        size_t nc = e->holes_cap * 2;
        iii_type_t **nh = (iii_type_t**)realloc(e->holes, nc * sizeof *nh);
        if (!nh) return NULL;
        e->holes = nh; e->holes_cap = nc;
    }
    e->holes[e->holes_count++] = t;
    return t;
}

/* §10.3 typed-as-term lift (U1) */
iii_type_t *iii_lift_term_to_type(iii_type_env_t *e, iii_type_t *t) {
    /* The lift: `e : T` becomes `e : Type_i` where T : Type_i.  We
     * return a fresh universe value at the appropriate level. */
    if (!t) return NULL;
    return iii_ty_universe(e, iii_type_universe(t));
}

/* Resolve all holes; emit TYPE-HOLE-001 for any unresolved. */
int iii_holes_solve(iii_type_env_t *e) {
    int unresolved = 0;
    for (size_t i = 0; i < e->holes_count; ++i) {
        iii_type_t *h = e->holes[i];
        if (h && !h->hole_solution) {
            iii_type_env_emit(e, TYPE_HOLE_001_UNINFERRED, NULL,
                              "hole %u (expected %s) could not be inferred",
                              h->hole_id, iii_universe_name(h->hole_expected_univ));
            unresolved++;
        }
    }
    return unresolved;
}

/* ------------------------------------------------------------------ */
/* Equality and printing                                               */
/* ------------------------------------------------------------------ */

bool iii_type_eq(const iii_type_t *a, const iii_type_t *b) {
    if (a == b) return true;
    if (!a || !b) return false;
    if (a->kind != b->kind) return false;
    switch (a->kind) {
    case III_TY_UNIVERSE: return a->univ == b->univ;
    case III_TY_PRIM:     return a->prim == b->prim;
    case III_TY_PI:
    case III_TY_FUN:
        return iii_type_eq(a->dom, b->dom) && iii_type_eq(a->cod, b->cod);
    case III_TY_TUPLE:
        if (a->element_count != b->element_count) return false;
        for (uint32_t i = 0; i < a->element_count; ++i)
            if (!iii_type_eq(a->elements[i], b->elements[i])) return false;
        return true;
    case III_TY_REDUCTION:
        return iii_type_eq(a->r_forward, b->r_forward) &&
               iii_type_eq(a->r_inverse, b->r_inverse) &&
               iii_hexad_eq(&a->r_hexad, &b->r_hexad) &&
               iii_phase_set_eq(a->r_phase, b->r_phase) &&
               a->r_epoch.n == b->r_epoch.n;
    case III_TY_CAP:
        return a->cap_perm == b->cap_perm && a->cap_range_id == b->cap_range_id;
    case III_TY_UNCERTAINTY:
        return a->uncertainty.domain_id == b->uncertainty.domain_id &&
               a->uncertainty.confidence_q14 == b->uncertainty.confidence_q14 &&
               a->uncertainty.question_count == b->uncertainty.question_count;
    case III_TY_PROP_FORM: return a->prop_kind == b->prop_kind;
    case III_TY_HEXAD_TAG:
        return iii_hexad_eq(&a->tag_hexad, &b->tag_hexad) &&
               iii_type_eq(a->tag_inner, b->tag_inner);
    case III_TY_RING_TAG:
        return iii_phase_set_eq(a->tag_phase, b->tag_phase) &&
               iii_type_eq(a->tag_inner, b->tag_inner);
    case III_TY_TIER_TAG:
        return a->tag_tier == b->tag_tier && iii_type_eq(a->tag_inner, b->tag_inner);
    case III_TY_EPOCH_TAG:
        return a->tag_epoch.n == b->tag_epoch.n && iii_type_eq(a->tag_inner, b->tag_inner);
    case III_TY_HOLE:    return a->hole_id == b->hole_id;
    case III_TY_NAMED:   return a->named_id == b->named_id;
    case III_TY_ERROR:   return true;
    }
    return false;
}

static const char *prim_name(iii_prim_id_t p) {
    switch (p) {
    case III_PRIM_UNIT:     return "Unit";
    case III_PRIM_BOOL:     return "Bool";
    case III_PRIM_I32:      return "i32";
    case III_PRIM_I64:      return "i64";
    case III_PRIM_U32:      return "u32";
    case III_PRIM_U64:      return "u64";
    case III_PRIM_Q14:      return "Q14";
    case III_PRIM_TRIT:     return "Trit";
    case III_PRIM_HEXAD:    return "Hexad";
    case III_PRIM_PHASE:    return "Phase";
    case III_PRIM_TIER:     return "Tier";
    case III_PRIM_EPOCH:    return "Epoch";
    case III_PRIM_WITNESS:  return "Witness";
    case III_PRIM_GLYPH:    return "Glyph";
    case III_PRIM_MHASH:    return "MHash";
    case III_PRIM_STRING:   return "String";
    case III_PRIM_DOMAIN:   return "Domain";
    case III_PRIM_QUESTION: return "Question";
    case III_PRIM_RANGE:    return "Range";
    case III_PRIM__COUNT: break;
    }
    return "?Prim";
}

static const char *prop_name(iii_prop_kind_t p) {
    switch (p) {
    case III_PROP_CEILING_MEMBERSHIP: return "CeilingMembership";
    case III_PROP_MOBIUS_COHERENCE:   return "MobiusCoherence";
    case III_PROP_TRINITY_ADMIT:      return "trinity_admit";
    case III_PROP_INTENT_ADMIT:       return "intent_admit";
    case III_PROP_CAP_ADMIT:          return "cap_admit";
    case III_PROP_CAUSALITY_ADMIT:    return "causality_admit";
    case III_PROP_SANCTUM_ADMIT:      return "sanctum_admit";
    case III_PROP_GLYPH_BOUND:        return "glyph_bound";
    case III_PROP_ADMITTED_HEXAD:     return "admitted_hexad";
    case III_PROP_VALID_PHASE_SET:    return "valid_phase_set";
    case III_PROP_VALID_TIER:         return "valid_tier";
    case III_PROP_VALID_EPOCH:        return "valid_epoch";
    case III_PROP__COUNT: break;
    }
    return "?Prop";
}

static const char *cap_perm_name(iii_cap_perm_t p) {
    switch (p) {
    case III_CAP_READ:  return "read";
    case III_CAP_WRITE: return "write";
    case III_CAP_EXEC:  return "exec";
    case III_CAP_CYCLE: return "cycle";
    case III_CAP__COUNT: break;
    }
    return "?";
}

size_t iii_type_print(const iii_type_t *t, char *buf, size_t cap) {
    if (!t || !buf || cap == 0) return 0;
    int n = 0;
    switch (t->kind) {
    case III_TY_UNIVERSE:
        n = snprintf(buf, cap, "%s", iii_universe_name((iii_universe_t)((int)t->univ - 1)));
        break;
    case III_TY_PRIM:
        n = snprintf(buf, cap, "%s", prim_name(t->prim));
        break;
    case III_TY_PI:
        n  = snprintf(buf, cap, "(Π %s:", t->binder_name ? t->binder_name : "_");
        n += (int)iii_type_print(t->dom, buf + n, cap > (size_t)n ? cap - n : 0);
        n += snprintf(buf + n, cap > (size_t)n ? cap - n : 0, ". ");
        n += (int)iii_type_print(t->cod, buf + n, cap > (size_t)n ? cap - n : 0);
        n += snprintf(buf + n, cap > (size_t)n ? cap - n : 0, ")");
        break;
    case III_TY_FUN:
        n  = snprintf(buf, cap, "(");
        n += (int)iii_type_print(t->dom, buf + n, cap > (size_t)n ? cap - n : 0);
        n += snprintf(buf + n, cap > (size_t)n ? cap - n : 0, " -> ");
        n += (int)iii_type_print(t->cod, buf + n, cap > (size_t)n ? cap - n : 0);
        n += snprintf(buf + n, cap > (size_t)n ? cap - n : 0, ")");
        break;
    case III_TY_TUPLE:
        n = snprintf(buf, cap, "(");
        for (uint32_t i = 0; i < t->element_count; ++i) {
            if (i) n += snprintf(buf + n, cap > (size_t)n ? cap - n : 0, " * ");
            n += (int)iii_type_print(t->elements[i], buf + n, cap > (size_t)n ? cap - n : 0);
        }
        n += snprintf(buf + n, cap > (size_t)n ? cap - n : 0, ")");
        break;
    case III_TY_REDUCTION:
        n = snprintf(buf, cap, "Reduction<F,I,W,H=%u,P=0x%x,E=%llu>",
                     (unsigned)iii_hexad_pack(&t->r_hexad),
                     (unsigned)t->r_phase.mask,
                     (unsigned long long)t->r_epoch.n);
        break;
    case III_TY_CAP:
        n = snprintf(buf, cap, "Cap<%s,%u>", cap_perm_name(t->cap_perm), t->cap_range_id);
        break;
    case III_TY_UNCERTAINTY:
        n = snprintf(buf, cap, "Uncertainty(D=%u,C=%u/16384,Q=%u)",
                     t->uncertainty.domain_id,
                     (unsigned)t->uncertainty.confidence_q14,
                     t->uncertainty.question_count);
        break;
    case III_TY_PROP_FORM:
        n = snprintf(buf, cap, "%s : Prop", prop_name(t->prop_kind));
        break;
    case III_TY_HEXAD_TAG:
        n  = (int)iii_type_print(t->tag_inner, buf, cap);
        n += snprintf(buf + n, cap > (size_t)n ? cap - n : 0, " @safety(%u)",
                      (unsigned)iii_hexad_pack(&t->tag_hexad));
        break;
    case III_TY_RING_TAG:
        n  = (int)iii_type_print(t->tag_inner, buf, cap);
        n += snprintf(buf + n, cap > (size_t)n ? cap - n : 0, " @ring(0x%x)",
                      (unsigned)t->tag_phase.mask);
        break;
    case III_TY_TIER_TAG:
        n  = (int)iii_type_print(t->tag_inner, buf, cap);
        n += snprintf(buf + n, cap > (size_t)n ? cap - n : 0, " @tier(%s)",
                      iii_tier_name(t->tag_tier));
        break;
    case III_TY_EPOCH_TAG:
        n  = (int)iii_type_print(t->tag_inner, buf, cap);
        n += snprintf(buf + n, cap > (size_t)n ? cap - n : 0, " @epoch(%llu)",
                      (unsigned long long)t->tag_epoch.n);
        break;
    case III_TY_HOLE:
        n = snprintf(buf, cap, "?α%u:%s", t->hole_id, iii_universe_name(t->hole_expected_univ));
        break;
    case III_TY_NAMED:
        n = snprintf(buf, cap, "named_%u", t->named_id);
        break;
    case III_TY_ERROR:
        n = snprintf(buf, cap, "<error>");
        break;
    }
    if (n < 0) n = 0;
    return (size_t)n;
}
