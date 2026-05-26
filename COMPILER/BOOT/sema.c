/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\sema.c
 *
 * III Stage-0 Semantic Analyser — implementation.
 *
 * Walks the BOOT AST in two passes:
 *   Pass 1 — top-level decl registration into a name table; uniqueness
 *            check; per-decl modifier resolution (ring mask, hexad,
 *            tier, epoch).
 *   Pass 2 — per-decl body walk; identifier resolution; metal-ring
 *            check; IRPD-only check; ERROR_NODE surfacing; PFS name
 *            check.
 *
 * Side-table outputs:
 *   - per-decl resolved (ring_mask, hexad, tier, epoch, abi)
 *   - per-EXPR_IDENT binder_id (set via iii_ast_set_binder_id)
 *   - per-cycle synthetic III_AST_RING_SET node (so main.c
 *     iii_ring_autodetect can read the resolved ring set)
 *
 * Strict NIH: only stdlib + ast.h + lex.h + hexad_check.h.
 */

#include "sema.h"
#include "lex.h"
#include "hexad_check.h"
#include "irpd_methods.h"   /* RITCHIE Stage 1.20: canonical IRPD method table */

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdarg.h>

/* ============================================================================
 *  CONSTANTS
 * ============================================================================ */

/* The legal IRPD method surface (17 write-side + 3 read-side) is the canonical
 * III_IRPD_METHODS table in irpd_methods.h (single source of truth, defined in
 * sid.c).  RITCHIE Stage 1.20 deduplicated the former local SEMA_IRPD_METHODS
 * name-array into that shared table; iii_sema_is_irpd_method() below iterates
 * it by name. */

/* The six PFS bricking-class operation names (defense in depth — even
 * if a malformed hexad slipped past the bitmap check, a name match
 * still rejects). */
static const char *const SEMA_PFS_NAMES[] = {
    "capsule_update",
    "microcode_load",
    "bootorder_set",
    "real_nvram_write",
    "me_psp_mailbox",
    "smram_write",
    NULL
};

/* The five legal extern ABIs (per III_ABI_* in ast.h). */
static const char *const SEMA_ABI_NAMES[] = {
    "c-msvc-x64",
    "c-sysv-x64",
    "vmrun-trampoline",
    "magic-msr",
    "ioctl",
    NULL
};

/* Raw privileged-write opcodes refused outside an IRPD dispatch
 * (substring search inside METAL block raw asm).  Lowercase ASCII. */
static const char *const SEMA_RAW_PRIV_OPCODES[] = {
    "wrmsr",
    "wrmsrns",
    "wrmsrlist",
    "mov cr",         /* matches "mov cr0,..." / "mov cr3,..." / "mov cr4,..." */
    "wrpkru",
    "invlpga",
    "invpcid",
    "vmrun",
    "vmload",
    "vmsave",
    "clgi",
    "stgi",
    "xsetbv",
    NULL
};

/* ============================================================================
 *  ARENA / ERROR QUEUE
 *
 *  CHUNKED arena (NIH).  Earlier revisions used a single realloc'd buffer,
 *  but that invalidated every previously-returned pointer the moment a grow
 *  moved the base — and `sema_decl_table_t` stores those pointers verbatim.
 *  The result was a non-deterministic "unresolved identifier" cascade in
 *  large modules whose decl-table footprint crossed the doubling threshold.
 *  Chunked allocation makes pointers stable for the lifetime of the arena.
 * ============================================================================ */

typedef struct sema_arena_chunk_s {
    struct sema_arena_chunk_s *next;
    size_t   used;
    size_t   cap;
    uint8_t *base;       /* points into the trailing flexible-array region */
} sema_arena_chunk_t;

typedef struct {
    sema_arena_chunk_t *head;     /* most-recently-allocated chunk (alloc head) */
} sema_arena_t;

#define SEMA_ARENA_MIN_CHUNK ((size_t)4096)

static char *sema_arena_alloc_bytes(sema_arena_t *a, size_t n)
{
    if (n == 0) n = 1;
    sema_arena_chunk_t *c = a->head;
    if (!c || c->used + n > c->cap) {
        size_t cap = SEMA_ARENA_MIN_CHUNK;
        while (cap < n) cap *= 2;
        sema_arena_chunk_t *nc = (sema_arena_chunk_t *)
            malloc(sizeof(*nc) + cap);
        if (!nc) return NULL;
        nc->next = a->head;
        nc->used = 0;
        nc->cap  = cap;
        nc->base = (uint8_t *)(nc + 1);
        a->head  = nc;
        c = nc;
    }
    char *out = (char *)(c->base + c->used);
    c->used  += n;
    return out;
}

static char *sema_arena_strdup(sema_arena_t *a, const char *s)
{
    size_t n = strlen(s);
    char *out = sema_arena_alloc_bytes(a, n + 1);
    if (!out) return NULL;
    memcpy(out, s, n);
    out[n] = 0;
    return out;
}

static char *sema_arena_printf(sema_arena_t *a, const char *fmt, ...)
{
    char tmp[512];
    va_list ap;
    va_start(ap, fmt);
    int n = vsnprintf(tmp, sizeof tmp, fmt, ap);
    va_end(ap);
    if (n < 0) return NULL;
    return sema_arena_strdup(a, tmp);
}

/* ============================================================================
 *  NAME TABLE (top-level decls)
 * ============================================================================ */

typedef struct {
    char     *name;       /* arena-resident NUL-terminated copy */
    uint32_t  decl_node;  /* AST node index of the decl */
    iii_ast_kind_t kind;  /* CYCLE_DECL / FN_DECL / TYPE_DECL / CONST_DECL / EXTERN_DECL ... */
} sema_decl_entry_t;

typedef struct {
    sema_decl_entry_t *entries;
    size_t             count;
    size_t             cap;
} sema_decl_table_t;

static int sema_decl_table_add(sema_decl_table_t *t, sema_arena_t *a,
                                const char *name, uint32_t decl_node,
                                iii_ast_kind_t kind)
{
    if (t->count == t->cap) {
        size_t newcap = t->cap ? t->cap * 2 : 32;
        sema_decl_entry_t *ne = (sema_decl_entry_t *)realloc(t->entries,
                                    newcap * sizeof(*ne));
        if (!ne) return -1;
        t->entries = ne; t->cap = newcap;
    }
    char *copy = sema_arena_strdup(a, name);
    if (!copy) return -1;
    t->entries[t->count].name = copy;
    t->entries[t->count].decl_node = decl_node;
    t->entries[t->count].kind = kind;
    t->count++;
    return 0;
}

static const sema_decl_entry_t *sema_decl_table_lookup(const sema_decl_table_t *t,
                                                          const char *name)
{
    for (size_t i = 0; i < t->count; i++) {
        if (strcmp(t->entries[i].name, name) == 0) return &t->entries[i];
    }
    return NULL;
}

/* ============================================================================
 *  PER-CYCLE RESOLVED ANNOTATIONS (kept in a parallel array)
 * ============================================================================ */

/* Phase 2 modifier dynamic-ripple modes (lattice plan Step 0003). */
#define SEMA_DYNAMIC_RIPPLE_UNSET   0u
#define SEMA_DYNAMIC_RIPPLE_OFF     1u
#define SEMA_DYNAMIC_RIPPLE_MANUAL  2u
#define SEMA_DYNAMIC_RIPPLE_AUTO    3u

/* Phase 2 modifier provenance modes (Step 0009). */
#define SEMA_PROV_MODE_UNSET     0u
#define SEMA_PROV_MODE_DATAFLOW  1u
#define SEMA_PROV_MODE_ERROR     2u
#define SEMA_PROV_MODE_BOTH      3u

typedef struct {
    uint32_t decl_node;
    uint16_t hexad_packed;     /* 0xFFFFu if not set */
    unsigned ring_mask;        /* bitmask III_RING_*; 0 if not set */
    uint8_t  tier_kind;        /* 0..3; 0xFF if not set */
    uint64_t epoch_value;      /* 0 if not set */
    uint8_t  abi_kind;         /* iii_abi_kind_t; 0 if not extern */

    /* Phase 2 modifier annotations (lattice plan Steps 0002-0015 + 0028).
     * Each `has_*` flag is 1 iff the corresponding modifier was parsed
     * onto this decl.  Arg-bearing modifiers also record their decoded
     * args so cg_r3 / ripple / proof can consume them deterministically. */
    uint8_t  has_crystal;                  /* Step 0002 */
    uint8_t  has_dynamic;                  /* Step 0003 */
    uint8_t  dynamic_ripple_mode;          /* Step 0003: SEMA_DYNAMIC_RIPPLE_* */
    uint8_t  has_sealed;                   /* Step 0004 */
    uint32_t sealed_slot;                  /* Step 0004; 0xFFFFFFFFu = unset */
    uint8_t  sealed_provenance;            /* Step 0004; 0/1 */
    uint8_t  has_linear;                   /* Step 0005 */
    uint8_t  has_bounded;                  /* Step 0006 */
    uint64_t bounded_min;                  /* Step 0006 */
    uint64_t bounded_max;                  /* Step 0006 */
    uint8_t  has_variant;                  /* Step 0007 */
    uint8_t  has_k;                        /* Step 0008 */
    uint64_t k_value_fixed;                /* Step 0008; 1e9-scaled, 0..1_000_000_000 */
    uint8_t  has_provenance;               /* Step 0009 */
    uint8_t  provenance_mode;              /* Step 0009: SEMA_PROV_MODE_* */
    uint8_t  has_constant_time;            /* Step 0010 */
    uint8_t  has_side_channel_resistant;   /* Step 0011 */
    uint8_t  has_dynamic_impact;           /* Step 0012 */
    int32_t  dynamic_impact_perf_bp;       /* Step 0012; signed basis-points */
    int32_t  dynamic_impact_ux_bp;         /* Step 0012 */
    uint8_t  has_provenance_linked_error;  /* Step 0013 */
    uint8_t  has_arena_reset_safe;         /* Step 0014 */
    const char *arena_reset_safe_clear_fn; /* Step 0014; arena strdup of ident name; NULL if no arg */
    uint8_t  has_crystal_self_attest;      /* Step 0015 */
    uint8_t  has_strict_length;            /* Step 0028 */
} sema_cycle_anno_t;

typedef struct {
    sema_cycle_anno_t *items;
    size_t             count;
    size_t             cap;
} sema_anno_tbl_t;

static sema_cycle_anno_t *sema_anno_get_or_create(sema_anno_tbl_t *t,
                                                     uint32_t decl_node)
{
    for (size_t i = 0; i < t->count; i++) {
        if (t->items[i].decl_node == decl_node) return &t->items[i];
    }
    if (t->count == t->cap) {
        size_t newcap = t->cap ? t->cap * 2 : 32;
        sema_cycle_anno_t *ni = (sema_cycle_anno_t *)realloc(t->items,
                                    newcap * sizeof(*ni));
        if (!ni) return NULL;
        t->items = ni; t->cap = newcap;
    }
    sema_cycle_anno_t *p = &t->items[t->count++];
    p->decl_node = decl_node;
    p->hexad_packed = 0xFFFFu;
    p->ring_mask = 0;
    p->tier_kind = 0xFF;
    p->epoch_value = 0;
    p->abi_kind = 0;
    /* Phase 2 modifier annotations — all start unset. */
    p->has_crystal = 0;
    p->has_dynamic = 0;
    p->dynamic_ripple_mode = SEMA_DYNAMIC_RIPPLE_UNSET;
    p->has_sealed = 0;
    p->sealed_slot = 0xFFFFFFFFu;
    p->sealed_provenance = 0;
    p->has_linear = 0;
    p->has_bounded = 0;
    p->bounded_min = 0;
    p->bounded_max = 0;
    p->has_variant = 0;
    p->has_k = 0;
    p->k_value_fixed = 0;
    p->has_provenance = 0;
    p->provenance_mode = SEMA_PROV_MODE_UNSET;
    p->has_constant_time = 0;
    p->has_side_channel_resistant = 0;
    p->has_dynamic_impact = 0;
    p->dynamic_impact_perf_bp = 0;
    p->dynamic_impact_ux_bp = 0;
    p->has_provenance_linked_error = 0;
    p->has_arena_reset_safe = 0;
    p->arena_reset_safe_clear_fn = NULL;
    p->has_crystal_self_attest = 0;
    p->has_strict_length = 0;
    return p;
}

static const sema_cycle_anno_t *sema_anno_find(const sema_anno_tbl_t *t,
                                                  uint32_t decl_node)
{
    for (size_t i = 0; i < t->count; i++) {
        if (t->items[i].decl_node == decl_node) return &t->items[i];
    }
    return NULL;
}

/* ============================================================================
 *  F8.5 — STRUCT LAYOUT TABLE
 *
 *  For every STRUCT_DECL in the module, we cache its field layout:
 *    - field count (== struct size in u64 slots, Stage-1 uniformity)
 *    - per-field name (NUL-term arena string) and slot offset
 *
 *  Codegen consults this when lowering EXPR_FIELD on a stack-allocated
 *  struct or when STMT_LET allocates a struct-typed local.  The
 *  per-field map is small (bounded by FIELD_CAP) so a linear scan
 *  is fine for Stage-1.
 * ============================================================================ */

#define SEMA_STRUCT_FIELD_CAP    64u

typedef struct {
    char    *field_name;        /* arena */
    uint32_t slot_offset;       /* 0..N-1, in u64 slots */
} sema_struct_field_t;

typedef struct {
    uint32_t            decl_node;
    char               *struct_name;     /* arena */
    sema_struct_field_t fields[SEMA_STRUCT_FIELD_CAP];
    uint32_t            field_count;
} sema_struct_layout_t;

typedef struct {
    sema_struct_layout_t *items;
    uint32_t              count;
    uint32_t              cap;
} sema_struct_tbl_t;

static sema_struct_layout_t *sema_struct_alloc(sema_struct_tbl_t *t,
                                                  uint32_t decl_node)
{
    if (t->count == t->cap) {
        uint32_t newcap = t->cap ? t->cap * 2 : 8;
        sema_struct_layout_t *ni = (sema_struct_layout_t *)realloc(t->items,
                                          newcap * sizeof(*ni));
        if (!ni) return NULL;
        t->items = ni; t->cap = newcap;
    }
    sema_struct_layout_t *p = &t->items[t->count++];
    p->decl_node = decl_node;
    p->struct_name = NULL;
    p->field_count = 0;
    return p;
}

static const sema_struct_layout_t *sema_struct_find(const sema_struct_tbl_t *t,
                                                      uint32_t decl_node)
{
    for (uint32_t i = 0; i < t->count; i++) {
        if (t->items[i].decl_node == decl_node) return &t->items[i];
    }
    return NULL;
}

static const sema_struct_layout_t *sema_struct_find_by_name(const sema_struct_tbl_t *t,
                                                              const char *name)
{
    if (!name) return NULL;
    for (uint32_t i = 0; i < t->count; i++) {
        if (t->items[i].struct_name && strcmp(t->items[i].struct_name, name) == 0) {
            return &t->items[i];
        }
    }
    return NULL;
}

/* ============================================================================
 *  STATE
 * ============================================================================ */

struct iii_sema_state {
    iii_ast_t          *ast;
    sema_arena_t        arena;
    sema_decl_table_t   decls;
    sema_anno_tbl_t     annos;
    sema_struct_tbl_t   structs;          /* F8.5 — struct layout cache */

    /* Error queue. */
    iii_sema_error_t   *errors;
    uint32_t            error_count;
    uint32_t            error_cap;

    /* Per-cycle ring-set synthesis tracking — once we synthesise a
     * RING_SET node for a cycle, we record it here so we don't double-
     * synthesise. */
    uint32_t            current_cycle_decl;  /* during walk, the active cycle */
    bool                ran;

    /* Lattice plan Step 0025 — @dynamic_impact aggregation totals.
     * Computed once during iii_sema_run after Pass-1 modifier
     * resolution; queryable via iii_sema_dynamic_impact_*_total_bp. */
    int64_t             dynamic_impact_perf_total_bp;
    int64_t             dynamic_impact_ux_total_bp;
    uint32_t            dynamic_impact_decl_count;
};

/* ============================================================================
 *  SOURCE-TEXT HELPERS
 * ============================================================================ */

/* Convert iii_src_text_t (offset, length) into a malloc'd NUL-terminated
 * lowercase ASCII copy in the sema arena.  Returns NULL on OOM. */
static char *sema_src_text_dup_lower(iii_sema_state_t *s, iii_src_text_t t)
{
    const uint8_t *buf = iii_ast_source_buf(s->ast);
    size_t slen = iii_ast_source_len(s->ast);
    if (!buf || t.length == 0 || t.offset + t.length > slen) return NULL;
    char tmp[512];
    if (t.length >= sizeof tmp) return NULL;     /* sanity */
    for (uint32_t i = 0; i < t.length; i++) {
        unsigned c = buf[t.offset + i];
        if (c >= 'A' && c <= 'Z') c = c - 'A' + 'a';
        tmp[i] = (char)c;
    }
    tmp[t.length] = 0;
    return sema_arena_strdup(&s->arena, tmp);
}

static char *sema_src_text_dup(iii_sema_state_t *s, iii_src_text_t t)
{
    const uint8_t *buf = iii_ast_source_buf(s->ast);
    size_t slen = iii_ast_source_len(s->ast);
    if (!buf || t.length == 0 || t.offset + t.length > slen) return NULL;
    char tmp[512];
    if (t.length >= sizeof tmp) return NULL;
    memcpy(tmp, buf + t.offset, t.length);
    tmp[t.length] = 0;
    return sema_arena_strdup(&s->arena, tmp);
}

static bool sema_src_text_eq_cstr(const iii_sema_state_t *s, iii_src_text_t t,
                                     const char *cstr)
{
    const uint8_t *buf = iii_ast_source_buf(s->ast);
    size_t slen = iii_ast_source_len(s->ast);
    if (!buf || t.offset + t.length > slen) return false;
    size_t cl = strlen(cstr);
    if (cl != t.length) return false;
    return memcmp(buf + t.offset, cstr, cl) == 0;
}

/* Lowercase comparison: returns true iff src_text equals cstr (case-insensitive). */
static bool sema_src_text_eq_cstr_lower(const iii_sema_state_t *s, iii_src_text_t t,
                                            const char *cstr)
{
    const uint8_t *buf = iii_ast_source_buf(s->ast);
    size_t slen = iii_ast_source_len(s->ast);
    if (!buf || t.offset + t.length > slen) return false;
    size_t cl = strlen(cstr);
    if (cl != t.length) return false;
    for (size_t i = 0; i < cl; i++) {
        unsigned a = buf[t.offset + i];
        if (a >= 'A' && a <= 'Z') a = a - 'A' + 'a';
        unsigned b = (unsigned)cstr[i];
        if (b >= 'A' && b <= 'Z') b = b - 'A' + 'a';
        if (a != b) return false;
    }
    return true;
}

/* ============================================================================
 *  POSITION HELPERS
 * ============================================================================ */

static void sema_node_pos(const iii_sema_state_t *s, uint32_t node,
                            uint32_t *out_line, uint32_t *out_col)
{
    *out_line = 0;
    *out_col  = 0;
    iii_ast_position_t p;
    if (!iii_ast_position_first(s->ast, node, &p)) return;
    if (p.kind == III_POS_PHYSICAL) {
        *out_line = p.u.physical.line;
        *out_col  = p.u.physical.col;
    }
}

/* ============================================================================
 *  ERROR EMISSION
 * ============================================================================ */

static void sema_emit_error(iii_sema_state_t *s, int code, uint32_t node,
                              uint16_t hexad, const char *msg)
{
    if (s->error_count == s->error_cap) {
        uint32_t newcap = s->error_cap ? s->error_cap * 2 : 16;
        iii_sema_error_t *ne = (iii_sema_error_t *)realloc(s->errors,
                                    newcap * sizeof(*ne));
        if (!ne) return;        /* drop silently — error queue full */
        s->errors = ne; s->error_cap = newcap;
    }
    iii_sema_error_t *e = &s->errors[s->error_count++];
    e->code = code;
    e->ast_node = node;
    e->hexad = hexad;
    e->message = msg;
    sema_node_pos(s, node, &e->line, &e->col);
}

/* ============================================================================
 *  MODIFIER WALK
 *
 *  parse.h §M1: the parser leaves modifiers as raw (name, args) pairs
 *  WITHOUT pre-resolving ring_mask, hexad_node, tier_kind, epoch_value.
 *  Sema is the canonical interpreter.  We walk a modifier list,
 *  identify modifiers by source-text name, and decode their args.
 * ============================================================================ */

/* ─── Phase 2 modifier-arg helpers (Steps 0002-0015 + 0028) ──────── */

/* Find a named arg in a modifier arg list; returns the value_expr node id
 * for the first arg whose name matches `name` (case-insensitive), or 0. */
static uint32_t sema_modifier_find_named_arg(iii_sema_state_t *s,
                                                iii_ast_list_t args,
                                                const char *name)
{
    for (uint32_t i = 0; i < args.count; i++) {
        uint32_t aidx = iii_ast_list_at(s->ast, args, i);
        const iii_ast_node_t *an = iii_ast_get(s->ast, aidx);
        if (!an || an->kind != III_AST_ARG) continue;
        /* arg_name has length 0 for positional args; skip those. */
        if (an->u.arg.arg_name.length == 0) continue;
        if (sema_src_text_eq_cstr_lower(s, an->u.arg.arg_name, name)) {
            return an->u.arg.value_expr;
        }
    }
    return 0;
}

/* Returns the i-th positional arg's value_expr, skipping named args. */
static uint32_t sema_modifier_positional_arg(iii_sema_state_t *s,
                                                iii_ast_list_t args,
                                                uint32_t which)
{
    uint32_t seen = 0;
    for (uint32_t i = 0; i < args.count; i++) {
        uint32_t aidx = iii_ast_list_at(s->ast, args, i);
        const iii_ast_node_t *an = iii_ast_get(s->ast, aidx);
        if (!an || an->kind != III_AST_ARG) continue;
        if (an->u.arg.arg_name.length != 0) continue;
        if (seen == which) return an->u.arg.value_expr;
        seen++;
    }
    return 0;
}

/* Extract a u64 literal from a value-expr node; returns fallback on failure. */
static uint64_t sema_modifier_arg_u64(iii_sema_state_t *s, uint32_t value_expr,
                                          uint64_t fallback)
{
    if (value_expr == 0) return fallback;
    const iii_ast_node_t *vn = iii_ast_get(s->ast, value_expr);
    if (!vn) return fallback;
    if (vn->kind == III_AST_EXPR_INT) return vn->u.int_.value;
    return fallback;
}

/* Extract a signed-i32 from value-expr (allows EXPR_UNARY NEG over INT). */
static int32_t sema_modifier_arg_i32(iii_sema_state_t *s, uint32_t value_expr,
                                          int32_t fallback)
{
    if (value_expr == 0) return fallback;
    const iii_ast_node_t *vn = iii_ast_get(s->ast, value_expr);
    if (!vn) return fallback;
    if (vn->kind == III_AST_EXPR_INT) return (int32_t)vn->u.int_.value;
    if (vn->kind == III_AST_EXPR_UNARY && vn->u.unary.op == III_UN_NEG) {
        const iii_ast_node_t *op = iii_ast_get(s->ast, vn->u.unary.operand);
        if (op && op->kind == III_AST_EXPR_INT) {
            return -(int32_t)op->u.int_.value;
        }
    }
    return fallback;
}

/* Test whether value_expr is an identifier whose name (case-insensitive) equals `name`. */
static bool sema_modifier_arg_ident_eq(iii_sema_state_t *s, uint32_t value_expr,
                                           const char *name)
{
    if (value_expr == 0) return false;
    const iii_ast_node_t *vn = iii_ast_get(s->ast, value_expr);
    if (!vn || vn->kind != III_AST_EXPR_IDENT) return false;
    return sema_src_text_eq_cstr_lower(s, vn->u.ident.name, name);
}

/* If value_expr is a boolean keyword (`true`/`false`), return 1/0; else fallback. */
static uint8_t sema_modifier_arg_bool(iii_sema_state_t *s, uint32_t value_expr,
                                          uint8_t fallback)
{
    if (sema_modifier_arg_ident_eq(s, value_expr, "true"))  return 1;
    if (sema_modifier_arg_ident_eq(s, value_expr, "false")) return 0;
    /* Some sources may use 1/0 literals. */
    if (value_expr != 0) {
        const iii_ast_node_t *vn = iii_ast_get(s->ast, value_expr);
        if (vn && vn->kind == III_AST_EXPR_INT) {
            return (vn->u.int_.value != 0) ? 1u : 0u;
        }
    }
    return fallback;
}

/* Decode an identifier name from value_expr into an arena-allocated string. */
static const char *sema_modifier_arg_ident_dup(iii_sema_state_t *s, uint32_t value_expr)
{
    if (value_expr == 0) return NULL;
    const iii_ast_node_t *vn = iii_ast_get(s->ast, value_expr);
    if (!vn || vn->kind != III_AST_EXPR_IDENT) return NULL;
    return sema_src_text_dup(s, vn->u.ident.name);
}

/* Decode a ring set modifier @ring(R3, R0, R-1, R-2, ANY).  Each arg
 * is an III_AST_ARG whose value_expr is either an EXPR_IDENT (R3, R0,
 * any), an EXPR_UNARY (- followed by INT 1 or 2 for R-1/R-2), or an
 * EXPR_INT (3, 0).  Returns the union mask, or 0 on parse failure. */
static unsigned sema_decode_ring_args(iii_sema_state_t *s, iii_ast_list_t args)
{
    unsigned mask = 0;
    for (uint32_t i = 0; i < args.count; i++) {
        uint32_t arg_idx = iii_ast_list_at(s->ast, args, i);
        const iii_ast_node_t *arg = iii_ast_get(s->ast, arg_idx);
        if (!arg || arg->kind != III_AST_ARG) continue;
        uint32_t v = arg->u.arg.value_expr;
        const iii_ast_node_t *vn = iii_ast_get(s->ast, v);
        if (!vn) continue;
        if (vn->kind == III_AST_EXPR_IDENT) {
            if (sema_src_text_eq_cstr(s, vn->u.ident.name, "R3"))      mask |= III_RING_R3;
            else if (sema_src_text_eq_cstr(s, vn->u.ident.name, "R0")) mask |= III_RING_R0;
            else if (sema_src_text_eq_cstr_lower(s, vn->u.ident.name, "any")) mask |= III_RING_ANY;
        } else if (vn->kind == III_AST_EXPR_INT) {
            if (vn->u.int_.value == 3) mask |= III_RING_R3;
            else if (vn->u.int_.value == 0) mask |= III_RING_R0;
        } else if (vn->kind == III_AST_EXPR_UNARY && vn->u.unary.op == III_UN_NEG) {
            const iii_ast_node_t *operand = iii_ast_get(s->ast, vn->u.unary.operand);
            if (operand && operand->kind == III_AST_EXPR_INT) {
                if (operand->u.int_.value == 1) mask |= III_RING_RM1;
                else if (operand->u.int_.value == 2) mask |= III_RING_RM2;
            }
        }
    }
    return mask;
}

/* Decode a hexad arg list — either a single EXPR_HEXAD literal or a
 * single EXPR_IDENT name (e.g. MSR_WRITE) that we map to a known
 * IRPD per-method hexad.  Returns 0xFFFFu if undecidable. */
static uint16_t sema_known_hexad_for_irpd_method(const char *method)
{
    /* Per the 17 IRPD method hexads in III-EFFECTS.md §2.4.  Each
     * IRPD method's hexad has POS in P1..P3 (inverse-derivable,
     * shallow causality, fresh consent), ZERO/POS in P4 (replication
     * tier), ZERO in P5/P6.  For Stage 0 we use a single canonical
     * "irpd-safe" hexad that admits in the bitmap: pillars
     * (POS, POS, POS, ZERO, ZERO, ZERO) → packed value
     *   POS=2, POS=2, POS=2, ZERO=1, ZERO=1, ZERO=1
     *   v = 2 + 2*3 + 2*9 + 1*27 + 1*81 + 1*243
     *     = 2 + 6 + 18 + 27 + 81 + 243 = 377
     * 377 has the structural-pillar admissibility (no NEG in P0..P3),
     * so it admits per the BOOT bitmap. */
    (void)method;
    return 377u;
}

static uint16_t sema_decode_hexad_args(iii_sema_state_t *s, iii_ast_list_t args)
{
    if (args.count == 0) return 0xFFFFu;

    /* Case A: single EXPR_HEXAD literal. */
    if (args.count == 1) {
        uint32_t arg_idx = iii_ast_list_at(s->ast, args, 0);
        const iii_ast_node_t *arg = iii_ast_get(s->ast, arg_idx);
        if (arg && arg->kind == III_AST_ARG) {
            uint32_t v = arg->u.arg.value_expr;
            const iii_ast_node_t *vn = iii_ast_get(s->ast, v);
            if (vn && vn->kind == III_AST_EXPR_HEXAD) {
                return iii_hexad_pack_from_ast_trits(vn->u.hexad_.trits);
            }
            if (vn && vn->kind == III_AST_EXPR_IDENT) {
                /* Named IRPD-style hexad (e.g. @hexad(MSR_WRITE)). */
                char *nm = sema_src_text_dup(s, vn->u.ident.name);
                uint16_t r = sema_known_hexad_for_irpd_method(nm ? nm : "");
                return r;
            }
        }
    }

    /* Case B: six positional INT/IDENT args (NEG/ZERO/POS). */
    if (args.count == 6) {
        iii_ast_trit_t trits[6];
        for (int i = 0; i < 6; i++) {
            uint32_t arg_idx = iii_ast_list_at(s->ast, args, (uint32_t)i);
            const iii_ast_node_t *arg = iii_ast_get(s->ast, arg_idx);
            if (!arg || arg->kind != III_AST_ARG) return 0xFFFFu;
            uint32_t v = arg->u.arg.value_expr;
            const iii_ast_node_t *vn = iii_ast_get(s->ast, v);
            if (!vn) return 0xFFFFu;
            if (vn->kind == III_AST_EXPR_TRIT) {
                trits[i] = vn->u.trit_.trit;
            } else if (vn->kind == III_AST_EXPR_IDENT) {
                if (sema_src_text_eq_cstr_lower(s, vn->u.ident.name, "neg"))       trits[i] = III_TRIT_AST_NEG;
                else if (sema_src_text_eq_cstr_lower(s, vn->u.ident.name, "zero")) trits[i] = III_TRIT_AST_ZERO;
                else if (sema_src_text_eq_cstr_lower(s, vn->u.ident.name, "pos"))  trits[i] = III_TRIT_AST_POS;
                else return 0xFFFFu;
            } else {
                return 0xFFFFu;
            }
        }
        return iii_hexad_pack_from_ast_trits(trits);
    }

    return 0xFFFFu;
}

/* ============================================================================
 *  RING_SET SYNTHESIS
 *
 *  Sema synthesises an III_AST_RING_SET node for each cycle decl whose
 *  ring mask was successfully resolved.  main.c::iii_ring_autodetect
 *  walks the AST node pool linearly and reads .ring_set.mask from any
 *  RING_SET it encounters; the synthesised node is therefore visible
 *  to that walk.
 *
 *  Note: the synthesised node is allocated but NOT linked into any
 *  parent's children list.  iii_ring_autodetect uses a flat node-pool
 *  scan, not a tree walk, so reachability via parent links is not
 *  required.  The node has the III_AST_FLAG_SYNTHETIC flag set so
 *  downstream consumers can distinguish it from parser-emitted nodes
 *  (currently none, since the parser per parse.c does not emit
 *  RING_SET).
 * ============================================================================ */

static void sema_synthesise_ring_set(iii_sema_state_t *s, unsigned mask)
{
    if (mask == 0) return;
    iii_src_pos_t pos = { 0, 0, 0, 0 };
    uint32_t node = iii_ast_alloc_node(s->ast, III_AST_RING_SET, &pos);
    if (node == 0) return;
    iii_ast_node_t *n = iii_ast_get_mut(s->ast, node);
    if (!n) return;
    n->u.ring_set.mask = mask;
    n->flags |= III_AST_FLAG_SYNTHETIC;
    /* No interning: this node carries different mhash for different
     * ring masks; we want the side-effect (visibility in the pool
     * scan) regardless. */
}

/* ============================================================================
 *  PASS 1 — TOP-LEVEL DECL REGISTRATION + MODIFIER RESOLUTION
 * ============================================================================ */

/* Returns the source-text name slot for any decl kind that has one. */
static iii_src_text_t sema_decl_name(const iii_ast_node_t *decl)
{
    iii_src_text_t empty = { 0, 0 };
    if (!decl) return empty;
    switch (decl->kind) {
        case III_AST_CYCLE_DECL:                return decl->u.cycle_decl.name;
        case III_AST_FN_DECL:                   return decl->u.fn_decl.name;
        case III_AST_TYPE_DECL:                 return decl->u.type_decl.name;
        case III_AST_CONST_DECL:                return decl->u.const_decl.name;
        case III_AST_EXTERN_DECL:               return decl->u.extern_decl.name;
        case III_AST_MOBIUS_CANDIDATE_DECL:     return decl->u.mobius_candidate.name;
        case III_AST_SCHEMA_DECL:               return decl->u.schema_decl.name;
        case III_AST_SEALED_CALL_METHOD_DECL:   return decl->u.sealed_call.name;
        case III_AST_VAR_DECL:                  return decl->u.var_decl.name;
        case III_AST_STRUCT_DECL:               return decl->u.struct_decl.name;
        default:                                return empty;
    }
}

static iii_ast_list_t sema_decl_modifiers(const iii_ast_node_t *decl)
{
    iii_ast_list_t empty = { 0, 0 };
    if (!decl) return empty;
    switch (decl->kind) {
        case III_AST_CYCLE_DECL:               return decl->u.cycle_decl.modifiers;
        case III_AST_FN_DECL:                  return decl->u.fn_decl.modifiers;
        case III_AST_TYPE_DECL:                return decl->u.type_decl.modifiers;
        case III_AST_MOBIUS_CANDIDATE_DECL:    return decl->u.mobius_candidate.modifiers;
        default: { iii_ast_list_t empty2 = { 0, 0 }; return empty2; }
    }
}

static int sema_check_extern_abi(iii_sema_state_t *s, uint32_t decl_node,
                                    const iii_ast_node_t *decl)
{
    iii_abi_kind_t abi = decl->u.extern_decl.abi;
    if (abi < III_ABI_C_MSVC_X64 || abi > III_ABI_IOCTL) {
        sema_emit_error(s, III_SEMA_E_EXTERN_ABI, decl_node, 0,
                        "extern declaration uses unknown ABI");
        return -1;
    }
    return 0;
}

static int sema_pass1_module(iii_sema_state_t *s)
{
    uint32_t mod_node = iii_ast_root_module(s->ast);
    if (mod_node == 0) {
        sema_emit_error(s, III_SEMA_E_ERROR_NODE, 0, 0,
                        "no root module (parser produced no module)");
        return -1;
    }
    const iii_ast_node_t *mod = iii_ast_get(s->ast, mod_node);
    if (!mod || mod->kind != III_AST_MODULE) {
        sema_emit_error(s, III_SEMA_E_ERROR_NODE, mod_node, 0,
                        "root node is not a module");
        return -1;
    }

    iii_ast_list_t decls = mod->u.module_.decls;
    for (uint32_t i = 0; i < decls.count; i++) {
        uint32_t didx = iii_ast_list_at(s->ast, decls, i);
        const iii_ast_node_t *d = iii_ast_get(s->ast, didx);
        if (!d) continue;

        /* ERROR_NODE surfacing (D-9). */
        if (d->kind == III_AST_ERROR_NODE) {
            sema_emit_error(s, III_SEMA_E_ERROR_NODE, didx, 0,
                            "parser produced an error node");
            continue;
        }

        /* Decl-name + uniqueness (D-1). */
        iii_src_text_t name_t = sema_decl_name(d);
        char *name = name_t.length ? sema_src_text_dup(s, name_t) : NULL;
        if (name) {
            const sema_decl_entry_t *prior = sema_decl_table_lookup(&s->decls, name);
            if (prior) {
                char *msg = sema_arena_printf(&s->arena,
                                "duplicate declaration of '%s' (previous at node %u)",
                                name, prior->decl_node);
                sema_emit_error(s, III_SEMA_E_DECL_DUPLICATE, didx, 0,
                                msg ? msg : "duplicate declaration");
            } else {
                sema_decl_table_add(&s->decls, &s->arena, name, didx, d->kind);
            }
        }

        /* Modifier resolution. */
        iii_ast_list_t mods = sema_decl_modifiers(d);
        sema_cycle_anno_t *anno = sema_anno_get_or_create(&s->annos, didx);
        if (!anno) {
            sema_emit_error(s, III_SEMA_E_OOM, didx, 0, "sema annotation OOM");
            return -1;
        }

        for (uint32_t j = 0; j < mods.count; j++) {
            uint32_t mn = iii_ast_list_at(s->ast, mods, j);
            const iii_ast_node_t *m = iii_ast_get(s->ast, mn);
            if (!m || m->kind != III_AST_MODIFIER) continue;
            if (sema_src_text_eq_cstr_lower(s, m->u.modifier.name, "ring")) {
                /* Two routes: parser may have consumed ring args directly
                 * into m->u.modifier.ring_mask (the dedicated path for
                 * @ring tokens like R3 / R-1), or the args list may
                 * carry them as IDENT nodes (defensive fallback path).
                 * Honour the parser's mask first; fall back to args
                 * decoding only if the mask is zero. */
                anno->ring_mask = m->u.modifier.ring_mask;
                if (anno->ring_mask == 0) {
                    anno->ring_mask = sema_decode_ring_args(s, m->u.modifier.args);
                }
            } else if (sema_src_text_eq_cstr_lower(s, m->u.modifier.name, "hexad")
                    || sema_src_text_eq_cstr_lower(s, m->u.modifier.name, "safety")) {
                anno->hexad_packed = sema_decode_hexad_args(s, m->u.modifier.args);
            } else if (sema_src_text_eq_cstr_lower(s, m->u.modifier.name, "tier")) {
                /* Decode tier name in the first arg. */
                if (m->u.modifier.args.count >= 1) {
                    uint32_t aidx = iii_ast_list_at(s->ast, m->u.modifier.args, 0);
                    const iii_ast_node_t *an = iii_ast_get(s->ast, aidx);
                    if (an && an->kind == III_AST_ARG) {
                        const iii_ast_node_t *vn = iii_ast_get(s->ast, an->u.arg.value_expr);
                        if (vn && vn->kind == III_AST_EXPR_IDENT) {
                            if (sema_src_text_eq_cstr_lower(s, vn->u.ident.name, "transient"))      anno->tier_kind = 0;
                            else if (sema_src_text_eq_cstr_lower(s, vn->u.ident.name, "host_file")) anno->tier_kind = 1;
                            else if (sema_src_text_eq_cstr_lower(s, vn->u.ident.name, "federation"))anno->tier_kind = 2;
                            else if (sema_src_text_eq_cstr_lower(s, vn->u.ident.name, "constitutional")) anno->tier_kind = 3;
                        }
                    }
                }
            } else if (sema_src_text_eq_cstr_lower(s, m->u.modifier.name, "epoch")) {
                if (m->u.modifier.args.count >= 1) {
                    uint32_t aidx = iii_ast_list_at(s->ast, m->u.modifier.args, 0);
                    const iii_ast_node_t *an = iii_ast_get(s->ast, aidx);
                    if (an && an->kind == III_AST_ARG) {
                        const iii_ast_node_t *vn = iii_ast_get(s->ast, an->u.arg.value_expr);
                        if (vn && vn->kind == III_AST_EXPR_INT) {
                            anno->epoch_value = vn->u.int_.value;
                        }
                    }
                }
            }
            /* ─── Phase 2 modifier vocabulary (lattice plan Steps 0002-0015 + 0028) ───
             * Each branch records modifier presence and decodes args into the
             * anno struct.  Stage-0 does NOT enforce decl-kind compatibility
             * (e.g., we accept @constant_time on any decl).  Stage-1 hardens
             * these into errors per the per-step plan. */
            else if (sema_src_text_eq_cstr_lower(s, m->u.modifier.name, "crystal")) {
                anno->has_crystal = 1;
            }
            else if (sema_src_text_eq_cstr_lower(s, m->u.modifier.name, "dynamic")) {
                anno->has_dynamic = 1;
                /* Decode ripple = auto | manual | off. */
                uint32_t ripple_v = sema_modifier_find_named_arg(s, m->u.modifier.args, "ripple");
                if (ripple_v != 0) {
                    if (sema_modifier_arg_ident_eq(s, ripple_v, "auto"))   anno->dynamic_ripple_mode = SEMA_DYNAMIC_RIPPLE_AUTO;
                    else if (sema_modifier_arg_ident_eq(s, ripple_v, "manual")) anno->dynamic_ripple_mode = SEMA_DYNAMIC_RIPPLE_MANUAL;
                    else if (sema_modifier_arg_ident_eq(s, ripple_v, "off"))    anno->dynamic_ripple_mode = SEMA_DYNAMIC_RIPPLE_OFF;
                }
            }
            else if (sema_src_text_eq_cstr_lower(s, m->u.modifier.name, "sealed")) {
                anno->has_sealed = 1;
                uint32_t slot_v = sema_modifier_find_named_arg(s, m->u.modifier.args, "slot");
                uint32_t prov_v = sema_modifier_find_named_arg(s, m->u.modifier.args, "provenance");
                if (slot_v != 0) {
                    uint64_t slot64 = sema_modifier_arg_u64(s, slot_v, 0xFFFFFFFFu);
                    if (slot64 < 16) anno->sealed_slot = (uint32_t)slot64;
                }
                if (prov_v != 0) {
                    anno->sealed_provenance = sema_modifier_arg_bool(s, prov_v, 0);
                }
            }
            else if (sema_src_text_eq_cstr_lower(s, m->u.modifier.name, "linear")) {
                anno->has_linear = 1;
            }
            else if (sema_src_text_eq_cstr_lower(s, m->u.modifier.name, "bounded")) {
                anno->has_bounded = 1;
                uint32_t min_v = sema_modifier_find_named_arg(s, m->u.modifier.args, "min");
                uint32_t max_v = sema_modifier_find_named_arg(s, m->u.modifier.args, "max");
                anno->bounded_min = sema_modifier_arg_u64(s, min_v, 0);
                anno->bounded_max = sema_modifier_arg_u64(s, max_v, 0);
                /* Validate min <= max (defensive — no error emitted at Stage-0). */
            }
            else if (sema_src_text_eq_cstr_lower(s, m->u.modifier.name, "variant")) {
                anno->has_variant = 1;
            }
            else if (sema_src_text_eq_cstr_lower(s, m->u.modifier.name, "k")) {
                anno->has_k = 1;
                /* Accept either positional `@k(0.95)` style — though stage-0
                 * has no float literal — or `@k(value=950000000)`. */
                uint32_t val_v = sema_modifier_find_named_arg(s, m->u.modifier.args, "value");
                if (val_v == 0) val_v = sema_modifier_positional_arg(s, m->u.modifier.args, 0);
                uint64_t k = sema_modifier_arg_u64(s, val_v, 0);
                if (k > 1000000000ULL) k = 1000000000ULL;   /* clamp to 1.0 */
                anno->k_value_fixed = k;
            }
            else if (sema_src_text_eq_cstr_lower(s, m->u.modifier.name, "provenance")) {
                anno->has_provenance = 1;
                uint32_t mode_v = sema_modifier_find_named_arg(s, m->u.modifier.args, "mode");
                if (mode_v == 0) mode_v = sema_modifier_positional_arg(s, m->u.modifier.args, 0);
                if (sema_modifier_arg_ident_eq(s, mode_v, "dataflow"))    anno->provenance_mode = SEMA_PROV_MODE_DATAFLOW;
                else if (sema_modifier_arg_ident_eq(s, mode_v, "error")) anno->provenance_mode = SEMA_PROV_MODE_ERROR;
                else if (sema_modifier_arg_ident_eq(s, mode_v, "both"))  anno->provenance_mode = SEMA_PROV_MODE_BOTH;
                else                                                       anno->provenance_mode = SEMA_PROV_MODE_BOTH; /* default */
            }
            else if (sema_src_text_eq_cstr_lower(s, m->u.modifier.name, "constant_time")) {
                anno->has_constant_time = 1;
            }
            else if (sema_src_text_eq_cstr_lower(s, m->u.modifier.name, "side_channel_resistant")) {
                anno->has_side_channel_resistant = 1;
                /* Implies @constant_time per plan. */
                anno->has_constant_time = 1;
            }
            else if (sema_src_text_eq_cstr_lower(s, m->u.modifier.name, "dynamic_impact")) {
                anno->has_dynamic_impact = 1;
                uint32_t perf_v = sema_modifier_find_named_arg(s, m->u.modifier.args, "perf");
                uint32_t ux_v   = sema_modifier_find_named_arg(s, m->u.modifier.args, "ux");
                anno->dynamic_impact_perf_bp = sema_modifier_arg_i32(s, perf_v, 0);
                anno->dynamic_impact_ux_bp   = sema_modifier_arg_i32(s, ux_v, 0);
            }
            else if (sema_src_text_eq_cstr_lower(s, m->u.modifier.name, "provenance_linked_error")) {
                anno->has_provenance_linked_error = 1;
            }
            else if (sema_src_text_eq_cstr_lower(s, m->u.modifier.name, "arena_reset_safe")) {
                anno->has_arena_reset_safe = 1;
                uint32_t clear_v = sema_modifier_find_named_arg(s, m->u.modifier.args, "external_clear_fn");
                if (clear_v != 0) {
                    anno->arena_reset_safe_clear_fn = sema_modifier_arg_ident_dup(s, clear_v);
                }
            }
            else if (sema_src_text_eq_cstr_lower(s, m->u.modifier.name, "crystal_self_attest")) {
                anno->has_crystal_self_attest = 1;
                /* Plan requires this decl be also @crystal — Stage-0 does
                 * not enforce; Stage-1 will. */
            }
            else if (sema_src_text_eq_cstr_lower(s, m->u.modifier.name, "strict_length")) {
                anno->has_strict_length = 1;
            }
            /* Other modifiers (@pure, @irreversible, @sanctum_only,
             * @hot_path, @candidate_for_promotion, @plan_anchor,
             * @prerequisites, @replicates, @witness_elide,
             * @chronos_bypass, @epoch_bridge, @abi, @cap, @track,
             * @chronos, @closure, @version) are not consumed by
             * Stage-0 sema beyond annotation pass-through.  Stage-1+
             * will surface them. */
        }

        /* For cycle decls: synthesise a RING_SET node and write the
         * ring_mask into it for main.c::iii_ring_autodetect. */
        if (d->kind == III_AST_CYCLE_DECL && anno->ring_mask != 0) {
            sema_synthesise_ring_set(s, anno->ring_mask);
        }

        /* Per-cycle hexad presence + admissibility (D-3). */
        if (d->kind == III_AST_CYCLE_DECL) {
            if (anno->hexad_packed == 0xFFFFu) {
                sema_emit_error(s, III_SEMA_E_HEXAD_MISSING, didx, 0,
                                "cycle declaration missing @hexad / @safety modifier");
            } else if (!iii_hexad_packed_admitted(anno->hexad_packed)) {
                sema_emit_error(s, III_SEMA_E_HEXAD_UNREP, didx,
                                anno->hexad_packed,
                                "cycle hexad is outside the asymmetric reachability bitmap");
            }
            if (anno->ring_mask == 0) {
                sema_emit_error(s, III_SEMA_E_RING_MISSING, didx, 0,
                                "cycle declaration missing @ring modifier");
            }
        }

        /* Extern ABI check (D-7). */
        if (d->kind == III_AST_EXTERN_DECL) {
            sema_check_extern_abi(s, didx, d);
        }

        /* F8.5 — register struct layout.  Each field gets a sequential
         * 8-byte slot; the struct's "size in slots" is its field count.
         * Stage-2+ may add per-field width tracking + alignment. */
        if (d->kind == III_AST_STRUCT_DECL) {
            sema_struct_layout_t *L = sema_struct_alloc(&s->structs, didx);
            if (!L) {
                sema_emit_error(s, III_SEMA_E_OOM, didx, 0, "struct layout OOM");
                return -1;
            }
            char *snm = sema_src_text_dup(s, d->u.struct_decl.name);
            if (snm) L->struct_name = snm;
            iii_ast_list_t fields = d->u.struct_decl.fields;
            for (uint32_t k = 0; k < fields.count && k < SEMA_STRUCT_FIELD_CAP; k++) {
                uint32_t fn = iii_ast_list_at(s->ast, fields, k);
                const iii_ast_node_t *fnode = iii_ast_get(s->ast, fn);
                if (!fnode || fnode->kind != III_AST_PARAM) continue;
                char *fname = sema_src_text_dup(s, fnode->u.param.name);
                if (!fname) continue;
                L->fields[L->field_count].field_name = fname;
                L->fields[L->field_count].slot_offset = L->field_count;
                L->field_count++;
            }
        }
    }

    /* Sealed-call seal_id collision (D-8): sealed calls live as their
     * own decl kind under the module's decls list (or under a parent
     * sealed-call-block).  Stage-0: scan all sealed_call decls in the
     * pool. */
    {
        size_t total = iii_ast_node_count(s->ast);
        uint32_t seen_ids[64];
        uint32_t seen_n = 0;
        for (size_t k = 0; k < total; k++) {
            const iii_ast_node_t *n = iii_ast_get(s->ast, (uint32_t)k);
            if (!n || n->kind != III_AST_SEALED_CALL_METHOD_DECL) continue;
            uint32_t sid = n->u.sealed_call.seal_id;
            for (uint32_t z = 0; z < seen_n; z++) {
                if (seen_ids[z] == sid) {
                    char *msg = sema_arena_printf(&s->arena,
                                    "sealed-call seal_id %u declared twice", sid);
                    sema_emit_error(s, III_SEMA_E_SEAL_COLLISION, (uint32_t)k, 0,
                                    msg ? msg : "duplicate seal_id");
                    break;
                }
            }
            if (seen_n < 64) seen_ids[seen_n++] = sid;
        }
    }

    return 0;
}

/* ============================================================================
 *  PASS 2 — BODY WALK (identifier resolution + IRPD + metal + PFS)
 * ============================================================================ */

/* Returns true iff `method_name` is a recognised IRPD method name.
 * Iterates the canonical III_IRPD_METHODS table (irpd_methods.h, defined in
 * sid.c) by name — accepts all 20 (17 write-side + 3 read-side), exactly the
 * former SEMA_IRPD_METHODS set. RITCHIE Stage 1.20. */
static bool sema_is_irpd_method(const char *name)
{
    if (!name) return false;
    for (size_t i = 0; i < III_IRPD_METHODS_COUNT; i++) {
        if (strcmp(name, III_IRPD_METHODS[i].name) == 0) return true;
    }
    return false;
}

/* Returns true iff `name` is one of the six PFS bricking ops. */
static bool sema_is_pfs_brick(const char *name)
{
    for (size_t i = 0; SEMA_PFS_NAMES[i]; i++) {
        if (strcmp(name, SEMA_PFS_NAMES[i]) == 0) return true;
    }
    return false;
}

/* Local-binder lookup state — a tiny stack per body walk. */
typedef struct {
    char    *name;        /* arena-resident */
    uint32_t binder_id;
    uint32_t def_node;
} sema_local_t;

typedef struct {
    sema_local_t *items;
    size_t        count;
    size_t        cap;
} sema_local_stack_t;

static int sema_local_push(sema_local_stack_t *st, sema_arena_t *a,
                              iii_ast_t *ast, const char *name, uint32_t def)
{
    if (st->count == st->cap) {
        size_t newcap = st->cap ? st->cap * 2 : 16;
        sema_local_t *ne = (sema_local_t *)realloc(st->items, newcap * sizeof(*ne));
        if (!ne) return -1;
        st->items = ne; st->cap = newcap;
    }
    st->items[st->count].name = sema_arena_strdup(a, name);
    /* Use the def_node (the AST node that declared the binding — let,
     * param, match arm pattern, sanctum frame, for-var) as the binder
     * id.  This lets codegen recover the declaring node via
     * iii_ast_get(binder_id) and inspect its type — required for
     * F8.5 struct-typed locals.  Stage-2+ may grow a per-binder
     * type+layout side-table; until then, def_node IS the handle. */
    (void)ast;     /* binder allocator no longer needed */
    st->items[st->count].binder_id = def;
    st->items[st->count].def_node = def;
    st->count++;
    return 0;
}

static const sema_local_t *sema_local_lookup(const sema_local_stack_t *st,
                                                const char *name)
{
    /* Scan from top of stack so inner scopes shadow outer. */
    for (size_t i = st->count; i-- > 0; ) {
        if (strcmp(st->items[i].name, name) == 0) return &st->items[i];
    }
    return NULL;
}

static size_t sema_local_mark(const sema_local_stack_t *st) { return st->count; }
static void   sema_local_truncate(sema_local_stack_t *st, size_t mark)
{
    if (st->count > mark) st->count = mark;
}

/* Walk a body sub-AST; resolve idents; check IRPD discipline; check
 * metal blocks; recurse through statements / expressions / blocks. */
static void sema_walk_node(iii_sema_state_t *s,
                              uint32_t node,
                              sema_local_stack_t *locals,
                              unsigned cycle_ring_mask)
{
    if (node == 0) return;
    const iii_ast_node_t *n = iii_ast_get(s->ast, node);
    if (!n) return;

    switch (n->kind) {
        case III_AST_ERROR_NODE:
            sema_emit_error(s, III_SEMA_E_ERROR_NODE, node, 0,
                            "AST contains a parser-recovery error node");
            return;

        case III_AST_FORWARD_BLOCK: {
            iii_ast_list_t stmts = n->u.forward_block.stmts;
            for (uint32_t i = 0; i < stmts.count; i++) {
                sema_walk_node(s, iii_ast_list_at(s->ast, stmts, i),
                                 locals, cycle_ring_mask);
            }
            return;
        }
        case III_AST_EXPR_BLOCK: {
            size_t mark = sema_local_mark(locals);
            iii_ast_list_t stmts = n->u.block.stmts;
            for (uint32_t i = 0; i < stmts.count; i++) {
                sema_walk_node(s, iii_ast_list_at(s->ast, stmts, i),
                                 locals, cycle_ring_mask);
            }
            sema_local_truncate(locals, mark);
            return;
        }

        case III_AST_STMT_LET: {
            sema_walk_node(s, n->u.let_.value_expr, locals, cycle_ring_mask);
            char *nm = sema_src_text_dup(s, n->u.let_.name);
            if (nm) sema_local_push(locals, &s->arena, s->ast, nm, node);
            return;
        }

        case III_AST_STMT_EXPR:
            sema_walk_node(s, n->u.expr_stmt.expr, locals, cycle_ring_mask);
            return;
        case III_AST_STMT_RETURN:
            sema_walk_node(s, n->u.return_.value_expr, locals, cycle_ring_mask);
            return;
        case III_AST_STMT_ASSIGN:
            sema_walk_node(s, n->u.assign.lvalue_expr, locals, cycle_ring_mask);
            sema_walk_node(s, n->u.assign.value_expr,  locals, cycle_ring_mask);
            return;

        case III_AST_STMT_FOR: {
            sema_walk_node(s, n->u.for_.iter_expr, locals, cycle_ring_mask);
            size_t mark = sema_local_mark(locals);
            char *nm = sema_src_text_dup(s, n->u.for_.var);
            if (nm) sema_local_push(locals, &s->arena, s->ast, nm, node);
            sema_walk_node(s, n->u.for_.where_expr, locals, cycle_ring_mask);
            sema_walk_node(s, n->u.for_.body_block, locals, cycle_ring_mask);
            sema_local_truncate(locals, mark);
            return;
        }

        /* Phase-B grammar additions — body walks for new statement
         * kinds.  Without these cases, identifiers inside `if`/`while`
         * bodies stay unresolved, sema's binder_id remains 0, and
         * codegen falls back to address-load (leaq) instead of
         * value-load (movq) for top-level VAR_DECL references — a
         * silent miscompile. */
        case III_AST_STMT_IF: {
            sema_walk_node(s, n->u.if_.cond,        locals, cycle_ring_mask);
            sema_walk_node(s, n->u.if_.then_block,  locals, cycle_ring_mask);
            sema_walk_node(s, n->u.if_.else_block,  locals, cycle_ring_mask);
            return;
        }
        case III_AST_STMT_WHILE: {
            sema_walk_node(s, n->u.while_.cond,      locals, cycle_ring_mask);
            sema_walk_node(s, n->u.while_.body_block, locals, cycle_ring_mask);
            return;
        }
        case III_AST_STMT_LOOP: {
            /* iiis-2 — walk loop body for binder resolution.  No
             * condition expression; just the body block. */
            sema_walk_node(s, n->u.loop_.body_block, locals, cycle_ring_mask);
            return;
        }
        case III_AST_STMT_BREAK:
        case III_AST_STMT_CONTINUE:
            /* No child nodes; nothing to walk.  Codegen verifies that
             * these appear inside a loop. */
            return;
        case III_AST_EXPR_RANGE:
            sema_walk_node(s, n->u.range_.lo, locals, cycle_ring_mask);
            sema_walk_node(s, n->u.range_.hi, locals, cycle_ring_mask);
            return;
        case III_AST_EXPR_CAST:
            sema_walk_node(s, n->u.cast_.value_expr, locals, cycle_ring_mask);
            return;
        case III_AST_EXPR_SIZEOF:
            return;     /* operand is a type-expr, not walked for binders */

        case III_AST_STMT_MATCH:
            sema_walk_node(s, n->u.match_stmt.scrutinee, locals, cycle_ring_mask);
            for (uint32_t i = 0; i < n->u.match_stmt.arms.count; i++) {
                sema_walk_node(s, iii_ast_list_at(s->ast, n->u.match_stmt.arms, i),
                                 locals, cycle_ring_mask);
            }
            return;

        case III_AST_STMT_WAVEFRONT:
            for (uint32_t i = 0; i < n->u.wavefront.nodes.count; i++) {
                sema_walk_node(s, iii_ast_list_at(s->ast, n->u.wavefront.nodes, i),
                                 locals, cycle_ring_mask);
            }
            sema_walk_node(s, n->u.wavefront.on_rollback_block, locals, cycle_ring_mask);
            return;

        case III_AST_STMT_SANCTUM_ENTER: {
            size_t mark = sema_local_mark(locals);
            char *nm = sema_src_text_dup(s, n->u.sanctum_enter.frame_var);
            if (nm) sema_local_push(locals, &s->arena, s->ast, nm, node);
            sema_walk_node(s, n->u.sanctum_enter.body_block, locals, cycle_ring_mask);
            sema_local_truncate(locals, mark);
            return;
        }

        case III_AST_STMT_METAL: {
            /* D-6: metal ring mask must be a subset of the cycle's. */
            uint32_t mr = n->u.metal.ring_mask;
            if (mr != 0 && cycle_ring_mask != 0 && (mr & ~cycle_ring_mask) != 0) {
                sema_emit_error(s, III_SEMA_E_METAL_RING, node, 0,
                                "metal block ring mask exceeds cycle's @ring set");
            }
            /* D-5: scan the raw asm bytes for a raw privileged opcode
             * outside an irpd dispatch.  The metal block carries the
             * raw asm as (str_idx, len) into the AST string-payload
             * arena — for Stage-0 we simply scan the source-byte slice
             * the raw_asm token covers (best-effort lowercase substring
             * search).  This is conservative: false-positives are
             * possible inside string literals or comments but the
             * grammar doesn't admit those inside METAL blocks. */
            const uint8_t *src = iii_ast_source_buf(s->ast);
            size_t slen = iii_ast_source_len(s->ast);
            uint32_t off = n->u.metal.raw_asm_str_idx;
            uint32_t rlen = n->u.metal.raw_asm_len;
            if (src && rlen > 0 && off + rlen <= slen) {
                /* Lowercase the slice into a stack buffer. */
                char tmp[2048];
                size_t copy = rlen < sizeof tmp - 1 ? rlen : sizeof tmp - 1;
                for (size_t i = 0; i < copy; i++) {
                    unsigned c = src[off + i];
                    if (c >= 'A' && c <= 'Z') c = c - 'A' + 'a';
                    tmp[i] = (char)c;
                }
                tmp[copy] = 0;
                /* Reject any raw privileged opcode unless the slice
                 * also references "irpd" (a heuristic dispatch hint:
                 * irpd shims may need a single privileged opcode
                 * inline).  The proper Stage-1+ check parses the
                 * metal block as assembly. */
                bool has_irpd = strstr(tmp, "irpd") != NULL;
                for (size_t i = 0; SEMA_RAW_PRIV_OPCODES[i]; i++) {
                    if (strstr(tmp, SEMA_RAW_PRIV_OPCODES[i]) != NULL && !has_irpd) {
                        char *msg = sema_arena_printf(&s->arena,
                                        "metal block emits raw privileged opcode '%s' outside IRPD dispatch",
                                        SEMA_RAW_PRIV_OPCODES[i]);
                        sema_emit_error(s, III_SEMA_E_IRPD_RAW, node, 0,
                                        msg ? msg : "raw privileged write outside IRPD");
                        break;     /* one report per metal block is enough */
                    }
                }
            }
            return;
        }

        case III_AST_EXPR_CALL: {
            /* Walk callee + args. */
            sema_walk_node(s, n->u.call.callee, locals, cycle_ring_mask);
            for (uint32_t i = 0; i < n->u.call.args.count; i++) {
                sema_walk_node(s, iii_ast_list_at(s->ast, n->u.call.args, i),
                                 locals, cycle_ring_mask);
            }
            /* PFS-name check (D-10): if the callee is an EXPR_FIELD
             * whose object is the bare ident "irpd" and whose field
             * name is in the PFS set, refuse. */
            const iii_ast_node_t *callee = iii_ast_get(s->ast, n->u.call.callee);
            if (callee && callee->kind == III_AST_EXPR_FIELD) {
                const iii_ast_node_t *obj = iii_ast_get(s->ast, callee->u.field.object);
                if (obj && obj->kind == III_AST_EXPR_IDENT
                    && sema_src_text_eq_cstr_lower(s, obj->u.ident.name, "irpd")) {
                    char *fname = sema_src_text_dup_lower(s, callee->u.field.field_name);
                    if (fname && sema_is_pfs_brick(fname)) {
                        char *msg = sema_arena_printf(&s->arena,
                                        "irpd.%s is a Compromise<HIGH> bricking-class operation; not invocable",
                                        fname);
                        sema_emit_error(s, III_SEMA_E_PFS_BRICK, node, 0,
                                        msg ? msg : "PFS bricking-class call");
                    }
                }
            }
            return;
        }

        case III_AST_EXPR_FIELD:
            sema_walk_node(s, n->u.field.object, locals, cycle_ring_mask);
            return;
        case III_AST_EXPR_INDEX:
            sema_walk_node(s, n->u.index.object,     locals, cycle_ring_mask);
            sema_walk_node(s, n->u.index.index_expr, locals, cycle_ring_mask);
            return;
        case III_AST_EXPR_BINARY:
            sema_walk_node(s, n->u.binary.lhs, locals, cycle_ring_mask);
            sema_walk_node(s, n->u.binary.rhs, locals, cycle_ring_mask);
            return;
        case III_AST_EXPR_UNARY:
            sema_walk_node(s, n->u.unary.operand, locals, cycle_ring_mask);
            return;
        case III_AST_EXPR_PAREN:
            sema_walk_node(s, n->u.paren.inner, locals, cycle_ring_mask);
            return;
        case III_AST_EXPR_PARALLEL:
            for (uint32_t i = 0; i < n->u.parallel.branches.count; i++) {
                sema_walk_node(s, iii_ast_list_at(s->ast, n->u.parallel.branches, i),
                                 locals, cycle_ring_mask);
            }
            return;

        case III_AST_EXPR_MATCH: {
            sema_walk_node(s, n->u.match_expr.scrutinee, locals, cycle_ring_mask);
            for (uint32_t i = 0; i < n->u.match_expr.arms.count; i++) {
                sema_walk_node(s, iii_ast_list_at(s->ast, n->u.match_expr.arms, i),
                                 locals, cycle_ring_mask);
            }
            return;
        }

        case III_AST_MATCH_ARM: {
            size_t mark = sema_local_mark(locals);
            /* PAT_IDENT may bind a name. */
            const iii_ast_node_t *p = iii_ast_get(s->ast, n->u.match_arm.pattern);
            if (p && p->kind == III_AST_PAT_IDENT) {
                char *nm = sema_src_text_dup(s, p->u.pat_ident.name);
                if (nm) sema_local_push(locals, &s->arena, s->ast, nm, node);
            }
            sema_walk_node(s, n->u.match_arm.guard_expr, locals, cycle_ring_mask);
            sema_walk_node(s, n->u.match_arm.body,       locals, cycle_ring_mask);
            sema_local_truncate(locals, mark);
            return;
        }

        case III_AST_EXPR_IDENT: {
            /* D-2: identifier resolution. */
            char *nm = sema_src_text_dup(s, n->u.ident.name);
            if (!nm) return;
            const sema_local_t *lcl = sema_local_lookup(locals, nm);
            if (lcl) {
                iii_ast_set_binder_id(s->ast, node, lcl->binder_id);
                return;
            }
            const sema_decl_entry_t *dt = sema_decl_table_lookup(&s->decls, nm);
            if (dt) {
                /* Borrow the decl_node as the binder_id for top-level
                 * bindings (stable across the AST, non-zero by
                 * construction). */
                iii_ast_set_binder_id(s->ast, node, dt->decl_node);
                return;
            }
            /* Recognised compiler-builtin identifiers (irpd, sanctum, ...) */
            if (strcmp(nm, "irpd") == 0 || strcmp(nm, "sanctum") == 0
                || strcmp(nm, "phase") == 0 || strcmp(nm, "magic_msr") == 0
                || strcmp(nm, "ioctl") == 0 || strcmp(nm, "vmrun") == 0
                || strcmp(nm, "trinity") == 0 || strcmp(nm, "catalyst") == 0
                || strcmp(nm, "narrative") == 0 || strcmp(nm, "amend") == 0
                || strcmp(nm, "true") == 0 || strcmp(nm, "false") == 0
                || strcmp(nm, "current") == 0) {
                return;     /* builtin; no binder */
            }
            /* Numeric type identifiers (u8, u16, u32, u64, i8, i16, i32, i64, bool, q14, ...). */
            if (strcmp(nm, "u8") == 0 || strcmp(nm, "u16") == 0
                || strcmp(nm, "u32") == 0 || strcmp(nm, "u64") == 0
                || strcmp(nm, "i8") == 0 || strcmp(nm, "i16") == 0
                || strcmp(nm, "i32") == 0 || strcmp(nm, "i64") == 0
                || strcmp(nm, "bool") == 0 || strcmp(nm, "q14") == 0
                || strcmp(nm, "Witness") == 0 || strcmp(nm, "Hexad") == 0
                || strcmp(nm, "Phase") == 0 || strcmp(nm, "Glyph") == 0
                || strcmp(nm, "mhash") == 0 || strcmp(nm, "Range") == 0) {
                return;
            }
            char *msg = sema_arena_printf(&s->arena,
                            "unresolved identifier '%s'", nm);
            sema_emit_error(s, III_SEMA_E_IDENT_UNRESOLVED, node, 0,
                            msg ? msg : "unresolved identifier");
            return;
        }

        /* Leaf literal nodes — nothing to walk. */
        case III_AST_EXPR_INT:
        case III_AST_EXPR_HEX:
        case III_AST_EXPR_MHASH:
        case III_AST_EXPR_STR:
        case III_AST_EXPR_BOOL:
        case III_AST_EXPR_TRIT:
        case III_AST_EXPR_HEXAD:
        case III_AST_EXPR_UNIT:
        case III_AST_EXPR_HOLE:
        case III_AST_EXPR_RAW_ASM:
            return;

        case III_AST_ARG:
            sema_walk_node(s, n->u.arg.value_expr, locals, cycle_ring_mask);
            return;

        case III_AST_COMPROMISE_BLOCK:
            return;     /* Stage-0: structural acceptance, no walk needed */

        default:
            return;
    }
}

static int sema_pass2_module(iii_sema_state_t *s)
{
    uint32_t mod_node = iii_ast_root_module(s->ast);
    if (mod_node == 0) return -1;
    const iii_ast_node_t *mod = iii_ast_get(s->ast, mod_node);
    if (!mod || mod->kind != III_AST_MODULE) return -1;

    iii_ast_list_t decls = mod->u.module_.decls;
    sema_local_stack_t locals = { 0 };

    for (uint32_t i = 0; i < decls.count; i++) {
        uint32_t didx = iii_ast_list_at(s->ast, decls, i);
        const iii_ast_node_t *d = iii_ast_get(s->ast, didx);
        if (!d) continue;

        s->current_cycle_decl = didx;

        /* For every decl that has a body, push parameters as locals
         * then walk the body. */
        size_t mark = sema_local_mark(&locals);
        iii_ast_list_t params = { 0, 0 };
        uint32_t body_node = 0;
        unsigned cycle_ring_mask = 0;

        if (d->kind == III_AST_CYCLE_DECL) {
            params = d->u.cycle_decl.params;
            body_node = d->u.cycle_decl.forward_block;
            const sema_cycle_anno_t *a = sema_anno_find(&s->annos, didx);
            if (a) cycle_ring_mask = a->ring_mask;
        } else if (d->kind == III_AST_FN_DECL) {
            params = d->u.fn_decl.params;
            body_node = d->u.fn_decl.body_block;
            const sema_cycle_anno_t *a = sema_anno_find(&s->annos, didx);
            if (a) cycle_ring_mask = a->ring_mask;
        } else if (d->kind == III_AST_MOBIUS_CANDIDATE_DECL) {
            body_node = d->u.mobius_candidate.forward_block;
            const sema_cycle_anno_t *a = sema_anno_find(&s->annos, didx);
            if (a) cycle_ring_mask = a->ring_mask;
        } else if (d->kind == III_AST_SEALED_CALL_METHOD_DECL) {
            params = d->u.sealed_call.params;
            body_node = d->u.sealed_call.body_block;
        } else {
            continue;
        }

        for (uint32_t p = 0; p < params.count; p++) {
            uint32_t pn = iii_ast_list_at(s->ast, params, p);
            const iii_ast_node_t *pnode = iii_ast_get(s->ast, pn);
            if (!pnode || pnode->kind != III_AST_PARAM) continue;
            char *nm = sema_src_text_dup(s, pnode->u.param.name);
            if (nm) sema_local_push(&locals, &s->arena, s->ast, nm, pn);
        }

        if (body_node != 0) {
            sema_walk_node(s, body_node, &locals, cycle_ring_mask);
        }

#ifdef IIIS_XII_ENABLED
        /* XII semantic checks per DOCS/III-XII.md S15. Validates
         * @fusion_budget against @k_max + observed fusion depth, and
         * @deployment_target legality. Failures emit XII-CANON-003/004
         * diagnostics. Adapter lives in COMPILER/BOOT/sema_xii_adapter.c. */
        extern int sema_xii_check_function_node(iii_sema_state_t *s,
                                                 uint32_t fn_node,
                                                 uint32_t body_node);
        if (d->kind == III_AST_FN_DECL) {
            sema_xii_check_function_node(s, didx, body_node);
        }
#endif

        sema_local_truncate(&locals, mark);
    }

    free(locals.items);
    s->current_cycle_decl = 0;
    return 0;
}

/* ============================================================================
 *  PUBLIC API
 * ============================================================================ */

iii_sema_state_t *iii_sema_create(iii_ast_t *ast)
{
    if (!ast) return NULL;
    iii_sema_state_t *s = (iii_sema_state_t *)calloc(1, sizeof *s);
    if (!s) return NULL;
    s->ast = ast;
    return s;
}

void iii_sema_destroy(iii_sema_state_t *s)
{
    if (!s) return;
    free(s->errors);
    free(s->decls.entries);
    free(s->annos.items);
    free(s->structs.items);   /* F8.5 layout cache */
    {
        sema_arena_chunk_t *c = s->arena.head;
        while (c) {
            sema_arena_chunk_t *n = c->next;
            free(c);
            c = n;
        }
    }
    free(s);
}

/* Lattice plan Step 0025 — @dynamic_impact aggregation pass.
 * Walks the per-decl anno table and sums perf/ux basis-points across
 * all decls that carry @dynamic_impact.  Idempotent — recomputes from
 * scratch each call.  Runs once after Pass-1 modifier resolution. */
static void sema_aggregate_dynamic_impact(iii_sema_state_t *s)
{
    s->dynamic_impact_perf_total_bp = 0;
    s->dynamic_impact_ux_total_bp   = 0;
    s->dynamic_impact_decl_count    = 0;
    for (size_t i = 0; i < s->annos.count; i++) {
        const sema_cycle_anno_t *a = &s->annos.items[i];
        if (a->has_dynamic_impact) {
            s->dynamic_impact_perf_total_bp += (int64_t)a->dynamic_impact_perf_bp;
            s->dynamic_impact_ux_total_bp   += (int64_t)a->dynamic_impact_ux_bp;
            s->dynamic_impact_decl_count++;
        }
    }
}

int iii_sema_run(iii_sema_state_t *s)
{
    if (!s || !s->ast) return 0;
    if (s->ran) {
        /* Idempotent re-run is permitted but unnecessary. */
        return s->error_count == 0 ? 1 : 0;
    }
    s->ran = true;

    /* Initialise the hexad bitmap before any admission check. */
    iii_hexad_check_init();

    if (sema_pass1_module(s) != 0) {
        return 0;
    }
    /* Step 0025: aggregate @dynamic_impact totals after Pass-1 has
     * populated all anno entries.  This is read-only relative to the
     * AST and the anno table, so no error path. */
    sema_aggregate_dynamic_impact(s);
    if (sema_pass2_module(s) != 0) {
        return 0;
    }
    return s->error_count == 0 ? 1 : 0;
}

int64_t iii_sema_dynamic_impact_perf_total_bp(const iii_sema_state_t *s)
{
    return s ? s->dynamic_impact_perf_total_bp : 0;
}

int64_t iii_sema_dynamic_impact_ux_total_bp(const iii_sema_state_t *s)
{
    return s ? s->dynamic_impact_ux_total_bp : 0;
}

uint32_t iii_sema_dynamic_impact_decl_count(const iii_sema_state_t *s)
{
    return s ? s->dynamic_impact_decl_count : 0u;
}

uint32_t iii_sema_error_count(const iii_sema_state_t *s)
{
    return s ? s->error_count : 0;
}

void iii_sema_error_at(const iii_sema_state_t *s, uint32_t i,
                          iii_sema_error_t *out)
{
    if (!out) return;
    memset(out, 0, sizeof *out);
    if (!s || i >= s->error_count) return;
    *out = s->errors[i];
}

const char *iii_sema_error_name(int code)
{
    switch (code) {
        case III_SEMA_OK:                  return "OK";
        case III_SEMA_E_DECL_DUPLICATE:    return "TYPE-DECL-001";
        case III_SEMA_E_IDENT_UNRESOLVED:  return "TYPE-IDENT-001";
        case III_SEMA_E_HEXAD_MISSING:     return "TYPE-HEXAD-001";
        case III_SEMA_E_HEXAD_UNREP:       return "TYPE-HEXAD-002";
        case III_SEMA_E_RING_MALFORMED:    return "TYPE-RING-001";
        case III_SEMA_E_RING_MISSING:      return "TYPE-RING-002";
        case III_SEMA_E_IRPD_RAW:          return "PARSE-IRPD-001";
        case III_SEMA_E_METAL_RING:        return "TYPE-METAL-001";
        case III_SEMA_E_EXTERN_ABI:        return "TYPE-EXTERN-001";
        case III_SEMA_E_SEAL_COLLISION:    return "TYPE-SEAL-001";
        case III_SEMA_E_ERROR_NODE:        return "TYPE-ERROR-001";
        case III_SEMA_E_PFS_BRICK:         return "TYPE-PFS-001";
        case III_SEMA_E_OOM:               return "OOM";
        default:                           return "UNKNOWN";
    }
}

iii_ast_t *iii_sema_ast(iii_sema_state_t *s)
{
    return s ? s->ast : NULL;
}

uint32_t iii_sema_lookup_decl(const iii_sema_state_t *s, const char *name)
{
    if (!s || !name) return 0;
    const sema_decl_entry_t *e = sema_decl_table_lookup(&s->decls, name);
    return e ? e->decl_node : 0;
}

uint16_t iii_sema_cycle_hexad(const iii_sema_state_t *s, uint32_t cycle_decl_node)
{
    if (!s) return 0xFFFFu;
    const sema_cycle_anno_t *a = sema_anno_find(&s->annos, cycle_decl_node);
    return a ? a->hexad_packed : 0xFFFFu;
}

/* F8.5 — public layout queries.  Codegen calls these to translate
 * struct field references into byte offsets at code-emission time. */
uint32_t iii_sema_struct_size_slots(const iii_sema_state_t *s, uint32_t struct_decl_node)
{
    if (!s) return 0;
    const sema_struct_layout_t *L = sema_struct_find(&s->structs, struct_decl_node);
    return L ? L->field_count : 0;
}

int32_t iii_sema_struct_field_slot(const iii_sema_state_t *s,
                                       uint32_t struct_decl_node,
                                       const char *field_name)
{
    if (!s || !field_name) return -1;
    const sema_struct_layout_t *L = sema_struct_find(&s->structs, struct_decl_node);
    if (!L) return -1;
    for (uint32_t i = 0; i < L->field_count; i++) {
        if (L->fields[i].field_name && strcmp(L->fields[i].field_name, field_name) == 0) {
            return (int32_t)L->fields[i].slot_offset;
        }
    }
    return -1;
}

uint32_t iii_sema_struct_decl_for_name(const iii_sema_state_t *s, const char *name)
{
    if (!s || !name) return 0;
    const sema_struct_layout_t *L = sema_struct_find_by_name(&s->structs, name);
    return L ? L->decl_node : 0;
}

unsigned iii_sema_cycle_ring_mask(const iii_sema_state_t *s, uint32_t cycle_decl_node)
{
    if (!s) return 0;
    const sema_cycle_anno_t *a = sema_anno_find(&s->annos, cycle_decl_node);
    return a ? a->ring_mask : 0;
}

/* ─── Phase 2 modifier annotation queries (lattice plan Steps 0002-0015 + 0028) ─── */

uint8_t iii_sema_anno_has_crystal(const iii_sema_state_t *s, uint32_t decl_node)
{
    if (!s) return 0;
    const sema_cycle_anno_t *a = sema_anno_find(&s->annos, decl_node);
    return a ? a->has_crystal : 0u;
}

uint8_t iii_sema_anno_has_dynamic(const iii_sema_state_t *s, uint32_t decl_node)
{
    if (!s) return 0;
    const sema_cycle_anno_t *a = sema_anno_find(&s->annos, decl_node);
    return a ? a->has_dynamic : 0u;
}

uint8_t iii_sema_anno_dynamic_ripple_mode(const iii_sema_state_t *s, uint32_t decl_node)
{
    if (!s) return 0;
    const sema_cycle_anno_t *a = sema_anno_find(&s->annos, decl_node);
    return a ? a->dynamic_ripple_mode : 0u;
}

uint8_t iii_sema_anno_has_sealed(const iii_sema_state_t *s, uint32_t decl_node)
{
    if (!s) return 0;
    const sema_cycle_anno_t *a = sema_anno_find(&s->annos, decl_node);
    return a ? a->has_sealed : 0u;
}

uint32_t iii_sema_anno_sealed_slot(const iii_sema_state_t *s, uint32_t decl_node)
{
    if (!s) return 0xFFFFFFFFu;
    const sema_cycle_anno_t *a = sema_anno_find(&s->annos, decl_node);
    return a ? a->sealed_slot : 0xFFFFFFFFu;
}

uint8_t iii_sema_anno_sealed_provenance(const iii_sema_state_t *s, uint32_t decl_node)
{
    if (!s) return 0;
    const sema_cycle_anno_t *a = sema_anno_find(&s->annos, decl_node);
    return a ? a->sealed_provenance : 0u;
}

uint8_t iii_sema_anno_has_linear(const iii_sema_state_t *s, uint32_t decl_node)
{
    if (!s) return 0;
    const sema_cycle_anno_t *a = sema_anno_find(&s->annos, decl_node);
    return a ? a->has_linear : 0u;
}

uint8_t iii_sema_anno_has_bounded(const iii_sema_state_t *s, uint32_t decl_node)
{
    if (!s) return 0;
    const sema_cycle_anno_t *a = sema_anno_find(&s->annos, decl_node);
    return a ? a->has_bounded : 0u;
}

uint64_t iii_sema_anno_bounded_min(const iii_sema_state_t *s, uint32_t decl_node)
{
    if (!s) return 0;
    const sema_cycle_anno_t *a = sema_anno_find(&s->annos, decl_node);
    return a ? a->bounded_min : 0ull;
}

uint64_t iii_sema_anno_bounded_max(const iii_sema_state_t *s, uint32_t decl_node)
{
    if (!s) return 0;
    const sema_cycle_anno_t *a = sema_anno_find(&s->annos, decl_node);
    return a ? a->bounded_max : 0ull;
}

uint8_t iii_sema_anno_has_variant(const iii_sema_state_t *s, uint32_t decl_node)
{
    if (!s) return 0;
    const sema_cycle_anno_t *a = sema_anno_find(&s->annos, decl_node);
    return a ? a->has_variant : 0u;
}

uint8_t iii_sema_anno_has_k(const iii_sema_state_t *s, uint32_t decl_node)
{
    if (!s) return 0;
    const sema_cycle_anno_t *a = sema_anno_find(&s->annos, decl_node);
    return a ? a->has_k : 0u;
}

uint64_t iii_sema_anno_k_value_fixed(const iii_sema_state_t *s, uint32_t decl_node)
{
    if (!s) return 0;
    const sema_cycle_anno_t *a = sema_anno_find(&s->annos, decl_node);
    return a ? a->k_value_fixed : 0ull;
}

uint8_t iii_sema_anno_has_provenance(const iii_sema_state_t *s, uint32_t decl_node)
{
    if (!s) return 0;
    const sema_cycle_anno_t *a = sema_anno_find(&s->annos, decl_node);
    return a ? a->has_provenance : 0u;
}

uint8_t iii_sema_anno_provenance_mode(const iii_sema_state_t *s, uint32_t decl_node)
{
    if (!s) return 0;
    const sema_cycle_anno_t *a = sema_anno_find(&s->annos, decl_node);
    return a ? a->provenance_mode : 0u;
}

uint8_t iii_sema_anno_has_constant_time(const iii_sema_state_t *s, uint32_t decl_node)
{
    if (!s) return 0;
    const sema_cycle_anno_t *a = sema_anno_find(&s->annos, decl_node);
    return a ? a->has_constant_time : 0u;
}

uint8_t iii_sema_anno_has_side_channel_resistant(const iii_sema_state_t *s, uint32_t decl_node)
{
    if (!s) return 0;
    const sema_cycle_anno_t *a = sema_anno_find(&s->annos, decl_node);
    return a ? a->has_side_channel_resistant : 0u;
}

uint8_t iii_sema_anno_has_dynamic_impact(const iii_sema_state_t *s, uint32_t decl_node)
{
    if (!s) return 0;
    const sema_cycle_anno_t *a = sema_anno_find(&s->annos, decl_node);
    return a ? a->has_dynamic_impact : 0u;
}

int32_t iii_sema_anno_dynamic_impact_perf_bp(const iii_sema_state_t *s, uint32_t decl_node)
{
    if (!s) return 0;
    const sema_cycle_anno_t *a = sema_anno_find(&s->annos, decl_node);
    return a ? a->dynamic_impact_perf_bp : 0;
}

int32_t iii_sema_anno_dynamic_impact_ux_bp(const iii_sema_state_t *s, uint32_t decl_node)
{
    if (!s) return 0;
    const sema_cycle_anno_t *a = sema_anno_find(&s->annos, decl_node);
    return a ? a->dynamic_impact_ux_bp : 0;
}

uint8_t iii_sema_anno_has_provenance_linked_error(const iii_sema_state_t *s, uint32_t decl_node)
{
    if (!s) return 0;
    const sema_cycle_anno_t *a = sema_anno_find(&s->annos, decl_node);
    return a ? a->has_provenance_linked_error : 0u;
}

uint8_t iii_sema_anno_has_arena_reset_safe(const iii_sema_state_t *s, uint32_t decl_node)
{
    if (!s) return 0;
    const sema_cycle_anno_t *a = sema_anno_find(&s->annos, decl_node);
    return a ? a->has_arena_reset_safe : 0u;
}

const char *iii_sema_anno_arena_reset_safe_clear_fn(const iii_sema_state_t *s, uint32_t decl_node)
{
    if (!s) return NULL;
    const sema_cycle_anno_t *a = sema_anno_find(&s->annos, decl_node);
    return a ? a->arena_reset_safe_clear_fn : NULL;
}

uint8_t iii_sema_anno_has_crystal_self_attest(const iii_sema_state_t *s, uint32_t decl_node)
{
    if (!s) return 0;
    const sema_cycle_anno_t *a = sema_anno_find(&s->annos, decl_node);
    return a ? a->has_crystal_self_attest : 0u;
}

uint8_t iii_sema_anno_has_strict_length(const iii_sema_state_t *s, uint32_t decl_node)
{
    if (!s) return 0;
    const sema_cycle_anno_t *a = sema_anno_find(&s->annos, decl_node);
    return a ? a->has_strict_length : 0u;
}
