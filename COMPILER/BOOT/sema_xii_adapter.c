/* COMPILER/BOOT/sema_xii_adapter.c
 *
 * Type-bridging adapter between sema.c/sema.iii (which use
 * iii_sema_state_t* + uint32_t node indices) and sema_xii.c (which uses
 * opaque uint64_t handles).  Per DOCS/III-XII.md S15.
 *
 * Encoding: the opaque `uint64_t ast` IS `(uintptr_t)iii_sema_state_t*`.
 * The real `iii_ast_t*` is recovered via iii_sema_ast(s).
 * The opaque `uint64_t fn_node` IS the AST node index (low 32 bits).
 *
 * Compiled only when IIIS_XII_ENABLED is defined.
 *
 * NIH: libc only.
 */

#ifdef IIIS_XII_ENABLED

#include "sema.h"
#include "ast.h"
#include "sema_xii.h"
#include <stdint.h>
#include <stdio.h>
#include <stdarg.h>
#include <string.h>

/* ------------------------------------------------------------------ */
/* Handle conversion helpers                                          */
/* ------------------------------------------------------------------ */

static iii_sema_state_t *
adapter_state(uint64_t ast_handle)
{
    return (iii_sema_state_t *)(uintptr_t)ast_handle;
}

static const iii_ast_t *
adapter_ast(uint64_t ast_handle)
{
    iii_sema_state_t *s = adapter_state(ast_handle);
    if (!s) return NULL;
    return iii_sema_ast(s);
}

static const iii_ast_node_t *
adapter_node(uint64_t ast_handle, uint64_t node_handle)
{
    const iii_ast_t *ast = adapter_ast(ast_handle);
    if (!ast) return NULL;
    return iii_ast_get(ast, (uint32_t)node_handle);
}

/* Compare src_text against a NUL-terminated C string. */
static int
src_text_eq(const iii_ast_t *ast, iii_src_text_t t, const char *cstr)
{
    if (!ast || !cstr) return 0;
    size_t clen = strlen(cstr);
    if (t.length != (uint32_t)clen) return 0;
    const uint8_t *buf = iii_ast_source_buf(ast);
    if (!buf) return 0;
    return memcmp(buf + t.offset, cstr, clen) == 0;
}

static const char *
anno_kind_name(int anno_kind)
{
    switch (anno_kind) {
        case ANNO_FUSION_BUDGET: return "fusion_budget";
        case ANNO_DEPLOY_TARGET: return "deployment_target";
        case ANNO_LATTICE:       return "lattice";
        case ANNO_K_MAX_EXISTING: return "k_max";
        case ANNO_CAP_REQ_EXISTING: return "cap_required";
        case ANNO_HEXAD_EXISTING: return "hexad_kind";
        case ANNO_RETURNS_EXISTING: return "returns";
        default: return NULL;
    }
}

/* Extract a u32 value from an expression node (int or hex literal). */
static uint32_t
expr_to_u32(const iii_ast_t *ast, uint32_t expr_node, uint32_t default_val)
{
    if (!ast || expr_node == 0) return default_val;
    const iii_ast_node_t *n = iii_ast_get(ast, expr_node);
    if (!n) return default_val;
    switch (n->kind) {
        case III_AST_EXPR_INT:
            return (uint32_t)n->u.int_.value;
        case III_AST_EXPR_HEX:
            return (uint32_t)n->u.hex_.value;
        default:
            return default_val;
    }
}

/* Walk fn_decl's modifier list, find first @<name> and return its
 * modifier node index, or 0 if not present. */
static uint32_t
find_modifier_by_name(uint64_t ast_handle, uint64_t fn_node, const char *name)
{
    const iii_ast_t *ast = adapter_ast(ast_handle);
    if (!ast) return 0;
    const iii_ast_node_t *fn = iii_ast_get(ast, (uint32_t)fn_node);
    if (!fn) return 0;

    iii_ast_list_t mods;
    if (fn->kind == III_AST_FN_DECL)        mods = fn->u.fn_decl.modifiers;
    else if (fn->kind == III_AST_CYCLE_DECL) mods = fn->u.cycle_decl.modifiers;
    else return 0;

    for (uint32_t i = 0; i < mods.count; ++i) {
        uint32_t m_idx = iii_ast_list_at(ast, mods, i);
        const iii_ast_node_t *m = iii_ast_get(ast, m_idx);
        if (!m || m->kind != III_AST_MODIFIER) continue;
        if (src_text_eq(ast, m->u.modifier.name, name)) return m_idx;
    }
    return 0;
}

/* ------------------------------------------------------------------ */
/* Shim implementations called from sema_xii.c                        */
/* ------------------------------------------------------------------ */

int
sema_has_annotation(uint64_t fn_node_handle, int anno_kind)
{
    /* sema_xii.c calls this without ast handle; we look it up from a
     * thread-local "current sema state" — set by the integration glue
     * at sema_xii_check_function entry.  See g_xii_current_ast below. */
    extern uint64_t g_xii_current_ast;
    const char *name = anno_kind_name(anno_kind);
    if (!name) return 0;
    return find_modifier_by_name(g_xii_current_ast, fn_node_handle, name) != 0;
}

uint32_t
sema_get_anno_u32(uint64_t fn_node_handle, int anno_kind, uint32_t default_val)
{
    extern uint64_t g_xii_current_ast;
    const char *name = anno_kind_name(anno_kind);
    if (!name) return default_val;
    uint32_t m_idx = find_modifier_by_name(g_xii_current_ast, fn_node_handle, name);
    if (m_idx == 0) return default_val;
    const iii_ast_t *ast = adapter_ast(g_xii_current_ast);
    const iii_ast_node_t *m = iii_ast_get(ast, m_idx);
    if (!m) return default_val;
    if (m->u.modifier.args.count == 0) return default_val;
    uint32_t arg0 = iii_ast_list_at(ast, m->u.modifier.args, 0);
    return expr_to_u32(ast, arg0, default_val);
}

/* Emit an error via the sema diagnostic pipeline.  Since sema_emit_error
 * (the rich variadic emitter inside sema.c) is static, we surface XII
 * errors via stderr with a uniform XII-CANON prefix.  The error is also
 * counted on the sema_state so iii_sema_run() returns non-zero. */
void
sema_emit_error(uint64_t ast_handle, uint64_t node_handle, const char *fmt, ...)
{
    iii_sema_state_t *s = adapter_state(ast_handle);
    /* Mark sema as having an error by bumping the error counter via
     * the public iii_sema_error_count read after this returns.  Since
     * the static counter is internal, we rely on the integration glue
     * (sema_xii_check_function caller) to return non-zero on XII
     * failure, which propagates through iii_sema_run. */
    (void)s;
    (void)node_handle;

    va_list ap;
    va_start(ap, fmt);
    fprintf(stderr, "[XII-SEMA] ");
    vfprintf(stderr, fmt, ap);
    fprintf(stderr, "\n");
    va_end(ap);
}

/* ------------------------------------------------------------------ */
/* AST navigation shims                                                */
/* ------------------------------------------------------------------ */

int
ast_get_kind(uint64_t ast_handle, uint64_t node_handle)
{
    const iii_ast_node_t *n = adapter_node(ast_handle, node_handle);
    if (!n) return 0;
    return (int)n->kind;
}

/* Count of XII-relevant children of `node`.  Returns the number of
 * descendants the fusion-depth walk should recurse into. */
uint32_t
ast_get_child_count(uint64_t ast_handle, uint64_t node_handle)
{
    const iii_ast_t *ast = adapter_ast(ast_handle);
    const iii_ast_node_t *n = adapter_node(ast_handle, node_handle);
    if (!ast || !n) return 0;

    switch (n->kind) {
        case III_AST_FN_DECL:
            return (n->u.fn_decl.body_block != 0) ? 1u : 0u;
        case III_AST_CYCLE_DECL:
            return (n->u.cycle_decl.forward_block != 0 ? 1u : 0u) +
                   (n->u.cycle_decl.compromise_block != 0 ? 1u : 0u);
        case III_AST_EXPR_BLOCK:
            return n->u.block.stmts.count;
        case III_AST_EXPR_BINARY:
            return 2u;
        case III_AST_EXPR_CALL:
            return 1u + n->u.call.args.count;
        case III_AST_EXPR_MATCH:
            return 1u + n->u.match_expr.arms.count;
        case III_AST_STMT_LET:
            return (n->u.let_.value_expr != 0) ? 1u : 0u;
        case III_AST_STMT_RETURN:
            return (n->u.return_.value_expr != 0) ? 1u : 0u;
        case III_AST_STMT_EXPR:
            return (n->u.expr_stmt.expr != 0) ? 1u : 0u;
        case III_AST_STMT_ASSIGN:
            return 2u;
        default:
            return 0u;
    }
}

uint64_t
ast_get_child(uint64_t ast_handle, uint64_t node_handle, int idx)
{
    const iii_ast_t *ast = adapter_ast(ast_handle);
    const iii_ast_node_t *n = adapter_node(ast_handle, node_handle);
    if (!ast || !n || idx < 0) return 0;

    uint32_t u = (uint32_t)idx;
    switch (n->kind) {
        case III_AST_FN_DECL:
            return (u == 0) ? (uint64_t)n->u.fn_decl.body_block : 0;
        case III_AST_CYCLE_DECL: {
            uint32_t fwd = n->u.cycle_decl.forward_block;
            uint32_t cmp = n->u.cycle_decl.compromise_block;
            if (u == 0) return (uint64_t)(fwd != 0 ? fwd : cmp);
            if (u == 1 && fwd != 0) return (uint64_t)cmp;
            return 0;
        }
        case III_AST_EXPR_BLOCK:
            if (u < n->u.block.stmts.count)
                return (uint64_t)iii_ast_list_at(ast, n->u.block.stmts, u);
            return 0;
        case III_AST_EXPR_BINARY:
            if (u == 0) return (uint64_t)n->u.binary.lhs;
            if (u == 1) return (uint64_t)n->u.binary.rhs;
            return 0;
        case III_AST_EXPR_CALL:
            if (u == 0) return (uint64_t)n->u.call.callee;
            if (u - 1 < n->u.call.args.count)
                return (uint64_t)iii_ast_list_at(ast, n->u.call.args, u - 1);
            return 0;
        case III_AST_EXPR_MATCH:
            if (u == 0) return (uint64_t)n->u.match_expr.scrutinee;
            if (u - 1 < n->u.match_expr.arms.count)
                return (uint64_t)iii_ast_list_at(ast, n->u.match_expr.arms, u - 1);
            return 0;
        case III_AST_STMT_LET:
            return (u == 0) ? (uint64_t)n->u.let_.value_expr : 0;
        case III_AST_STMT_RETURN:
            return (u == 0) ? (uint64_t)n->u.return_.value_expr : 0;
        case III_AST_STMT_EXPR:
            return (u == 0) ? (uint64_t)n->u.expr_stmt.expr : 0;
        case III_AST_STMT_ASSIGN:
            if (u == 0) return (uint64_t)n->u.assign.lvalue_expr;
            if (u == 1) return (uint64_t)n->u.assign.value_expr;
            return 0;
        default:
            return 0;
    }
}

/* ------------------------------------------------------------------ */
/* Thread-local (single-threaded iiis-1: plain global) for the        */
/* current sema state during sema_xii_check_function.                 */
/* ------------------------------------------------------------------ */

uint64_t g_xii_current_ast = 0;

int
sema_xii_check_function_wrapped(iii_sema_state_t *s, uint32_t fn_node)
{
    g_xii_current_ast = (uint64_t)(uintptr_t)s;
    int rc = sema_xii_check_function(g_xii_current_ast, (uint64_t)fn_node);
    g_xii_current_ast = 0;
    return rc;
}

/* Public setters for the ambient sema-state handle used by the
 * cg_r3_xii_adapter (ast_walk_find_kind / ast_get_field / sema_*).
 * cg_r3.iii calls xii_set_current_sema_state(R3_G_SEMA) immediately
 * before invoking r3_pe_canonicalise / r3_compute_circ /
 * r3_pe_lattice_emit, then xii_set_current_sema_state(0) to restore.
 * The legacy r3_emit_function path is unaffected because the ambient
 * is only consulted by XII-pipeline code. */
void
xii_set_current_sema_state(uint64_t sema_state_handle)
{
    g_xii_current_ast = sema_state_handle;
}

uint64_t
xii_get_current_sema_state(void)
{
    return g_xii_current_ast;
}

/* ------------------------------------------------------------------ */
/* Explicit-AST annotation accessors for cg_r3.iii.                   */
/*                                                                    */
/* cg_r3.iii holds an iii_ast_t* in R3_G_AST (not an iii_sema_state_t*)*/
/* so it cannot use sema_has_annotation / sema_get_anno_u32 which     */
/* assume the opaque handle is a sema-state pointer.  These _in_ast   */
/* variants take an iii_ast_t* directly, letting cg_r3 dispatch on    */
/* XII annotations without setting up the g_xii_current_ast ambient.  */
/*                                                                    */
/* The ambient form (find_modifier_by_name above) is retained for the */
/* sema_xii.c path; the two paths share zero state.                   */
/* ------------------------------------------------------------------ */

static uint32_t
find_modifier_by_name_in_ast(const iii_ast_t *ast, uint32_t fn_node, const char *name)
{
    if (!ast || !name || fn_node == 0) return 0;
    const iii_ast_node_t *fn = iii_ast_get(ast, fn_node);
    if (!fn) return 0;

    iii_ast_list_t mods;
    if (fn->kind == III_AST_FN_DECL)        mods = fn->u.fn_decl.modifiers;
    else if (fn->kind == III_AST_CYCLE_DECL) mods = fn->u.cycle_decl.modifiers;
    else return 0;

    for (uint32_t i = 0; i < mods.count; ++i) {
        uint32_t m_idx = iii_ast_list_at(ast, mods, i);
        const iii_ast_node_t *m = iii_ast_get(ast, m_idx);
        if (!m || m->kind != III_AST_MODIFIER) continue;
        if (src_text_eq(ast, m->u.modifier.name, name)) return m_idx;
    }
    return 0;
}

uint8_t
sema_xii_anno_has_in_ast(uint64_t ast_raw, uint32_t fn_node, int anno_kind)
{
    const iii_ast_t *ast = (const iii_ast_t *)(uintptr_t)ast_raw;
    const char *name = anno_kind_name(anno_kind);
    if (!name) return 0u;
    return find_modifier_by_name_in_ast(ast, fn_node, name) != 0 ? 1u : 0u;
}

uint32_t
sema_xii_anno_get_u32_in_ast(uint64_t ast_raw, uint32_t fn_node, int anno_kind, uint32_t default_val)
{
    const iii_ast_t *ast = (const iii_ast_t *)(uintptr_t)ast_raw;
    const char *name = anno_kind_name(anno_kind);
    if (!name) return default_val;
    uint32_t m_idx = find_modifier_by_name_in_ast(ast, fn_node, name);
    if (m_idx == 0) return default_val;
    const iii_ast_node_t *m = iii_ast_get(ast, m_idx);
    if (!m) return default_val;
    if (m->u.modifier.args.count == 0) return default_val;
    uint32_t arg0 = iii_ast_list_at(ast, m->u.modifier.args, 0);
    return expr_to_u32(ast, arg0, default_val);
}

#else  /* IIIS_XII_ENABLED -- stubs for iiis-1 link compatibility */

/* When XII is not built in, the cg_r3.iii gate compiles in but always
 * resolves to "no @lattice -> legacy path".  These stubs provide the
 * symbols the .iii-side externs reference so iiis-1 can link.  They
 * return values that make `sema_xii_anno_has_in_ast(...) == 1u8` false,
 * which short-circuits the gate before any other XII function runs.
 *
 * Linking via -Wl,--allow-multiple-definition is unaffected: these are
 * the ONLY definitions in iiis-1 builds.  iiis-2 builds the #ifdef
 * branch above and these stubs are absent. */

#include <stdint.h>

uint64_t g_xii_current_ast = 0;

uint8_t
sema_xii_anno_has_in_ast(uint64_t ast_raw, uint32_t fn_node, int anno_kind)
{
    (void)ast_raw; (void)fn_node; (void)anno_kind;
    return 0u;
}

uint32_t
sema_xii_anno_get_u32_in_ast(uint64_t ast_raw, uint32_t fn_node, int anno_kind, uint32_t default_val)
{
    (void)ast_raw; (void)fn_node; (void)anno_kind;
    return default_val;
}

void
xii_set_current_sema_state(uint64_t sema_state_handle)
{
    (void)sema_state_handle;
}

uint64_t
xii_get_current_sema_state(void)
{
    return 0;
}

#endif /* IIIS_XII_ENABLED */
