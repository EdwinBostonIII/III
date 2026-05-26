/* COMPILER/BOOT/cg_r3_xii_adapter.c
 *
 * Shims for cg_r3_xii.c's outer API.  Provides:
 *   - ast_walk_find_kind(node, kind): subtree search for a given AST kind.
 *   - ast_get_field(ast, node, field_id): structural field accessor.
 *   - cpufeat_feature_mask(): host CPU feature mask.
 *   - cpufeat_auto_target(): AUTO target resolution.
 *   - emit_section_bytes(): write bytes into a named section.
 *   - emit_current_text_offset(): current .text offset.
 *
 * sema_has_annotation / sema_get_anno_u32 / sema_emit_error /
 * ast_get_kind / ast_get_child / ast_get_child_count are provided by
 * sema_xii_adapter.c — both adapters share the g_xii_current_ast
 * global as the ambient sema handle.
 *
 * Compiled only when IIIS_XII_ENABLED is defined.  Linked alongside
 * cg_r3_xii.c and xii_ldil.c.
 *
 * NIH: libc only.
 */

#ifdef IIIS_XII_ENABLED

#include "ast.h"
#include "sema.h"
#include "cg_r3_xii.h"
#include "xii_ldil.h"
#include <stdint.h>
#include <stdio.h>
#include <string.h>

/* Ambient ast/sema handle set by sema_xii_adapter at the
 * sema_xii_check_function entry.  Both adapters consult it. */
extern uint64_t g_xii_current_ast;

#define XII_FIELD_FN_BODY  0x01

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

/* Recursive subtree walk: returns the first node index whose kind
 * matches `kind`, or 0 if none.  Walks via the same child-dispatch
 * logic as ast_get_child in sema_xii_adapter. */
static uint32_t
walk_find_kind_rec(const iii_ast_t *ast, uint32_t node, int kind)
{
    if (!ast || node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n) return 0;
    if ((int)n->kind == kind) return node;

    /* Recurse into known child-bearing kinds. */
    switch (n->kind) {
        case III_AST_FN_DECL:
            return walk_find_kind_rec(ast, n->u.fn_decl.body_block, kind);
        case III_AST_CYCLE_DECL: {
            uint32_t r = walk_find_kind_rec(ast, n->u.cycle_decl.forward_block, kind);
            if (r) return r;
            return walk_find_kind_rec(ast, n->u.cycle_decl.compromise_block, kind);
        }
        case III_AST_EXPR_BLOCK:
            for (uint32_t i = 0; i < n->u.block.stmts.count; ++i) {
                uint32_t child = iii_ast_list_at(ast, n->u.block.stmts, i);
                uint32_t r = walk_find_kind_rec(ast, child, kind);
                if (r) return r;
            }
            return 0;
        case III_AST_EXPR_BINARY: {
            uint32_t r = walk_find_kind_rec(ast, n->u.binary.lhs, kind);
            if (r) return r;
            return walk_find_kind_rec(ast, n->u.binary.rhs, kind);
        }
        case III_AST_EXPR_CALL: {
            uint32_t r = walk_find_kind_rec(ast, n->u.call.callee, kind);
            if (r) return r;
            for (uint32_t i = 0; i < n->u.call.args.count; ++i) {
                uint32_t a = iii_ast_list_at(ast, n->u.call.args, i);
                r = walk_find_kind_rec(ast, a, kind);
                if (r) return r;
            }
            return 0;
        }
        case III_AST_STMT_LET:
            return walk_find_kind_rec(ast, n->u.let_.value_expr, kind);
        case III_AST_STMT_RETURN:
            return walk_find_kind_rec(ast, n->u.return_.value_expr, kind);
        case III_AST_STMT_EXPR:
            return walk_find_kind_rec(ast, n->u.expr_stmt.expr, kind);
        case III_AST_STMT_ASSIGN: {
            uint32_t r = walk_find_kind_rec(ast, n->u.assign.lvalue_expr, kind);
            if (r) return r;
            return walk_find_kind_rec(ast, n->u.assign.value_expr, kind);
        }
        default:
            return 0;
    }
}

uint64_t
ast_walk_find_kind(uint64_t fn_node, int kind)
{
    const iii_ast_t *ast = adapter_ast(g_xii_current_ast);
    if (!ast) return 0;
    return (uint64_t)walk_find_kind_rec(ast, (uint32_t)fn_node, kind);
}

/* Structural field accessor.  Currently only XII_FIELD_FN_BODY is
 * needed; returns the body_block index of a FN_DECL or
 * forward_block of a CYCLE_DECL. */
uint64_t
ast_get_field(uint64_t ast_handle, uint64_t node, int field_id)
{
    (void)ast_handle;
    const iii_ast_t *ast = adapter_ast(g_xii_current_ast);
    if (!ast) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, (uint32_t)node);
    if (!n) return 0;
    if (field_id == XII_FIELD_FN_BODY) {
        if (n->kind == III_AST_FN_DECL)        return (uint64_t)n->u.fn_decl.body_block;
        if (n->kind == III_AST_CYCLE_DECL)     return (uint64_t)n->u.cycle_decl.forward_block;
    }
    return 0;
}

/* CPU feature mask.  At bootstrap on the build host we assume the
 * full commodity-x86 feature set is available; targets distinguish
 * themselves via the per-function @deployment_target annotation.
 *
 * Bit layout (matches xii_horizon's expectation):
 *   bit 0: AVX2
 *   bit 1: AVX-512F
 *   bit 2: SHA-NI
 *   bit 3: CRC32 / PCLMUL */
uint32_t
cpufeat_feature_mask(void)
{
    return 0xFu;
}

/* AUTO target resolution: pick the highest-tier commodity target
 * available on the host.  Default = x86_avx2 (target id 1). */
uint32_t
cpufeat_auto_target(void)
{
    return 1u;
}

/* Section-bytes emitter and text-offset reader.  Real implementations
 * that route through the cg_r3.iii @exported helpers so XII output
 * actually lands in the .iii_xii_calls / .iii_xii_ldil_audit sections
 * of the assembled .o file.
 *
 * `r3_emit_xii_section_bytes` (defined in cg_r3.iii, @exported) emits
 * the AT-T directives `.section <name>` + `.byte 0xHH` per byte +
 * `.text` to return to the code section.  The assembler then packs
 * those bytes into the named section in the .o.  Post-link, the LDIL
 * pipeline consumes the section content.
 *
 * `emit_current_text_offset` returns a monotonically-increasing
 * synthetic counter so each call site has a unique identifier.  True
 * binary text offsets require assembler-level label resolution; the
 * counter approach is the simplest non-placeholder choice that lets
 * LDIL distinguish call sites in the same function.  Each invocation
 * of r3_pe_lattice_emit reads this once. */

extern int32_t r3_emit_xii_section_bytes(uint64_t name_ptr, uint64_t name_len,
                                         uint64_t bytes, uint64_t bytes_len);

static uint64_t g_xii_call_site_counter = 0;

int
emit_section_bytes(const char *section_name, const uint8_t *bytes, uint32_t len)
{
    if (!section_name || !bytes) return -1;
    size_t name_len = strlen(section_name);
    int32_t rc = r3_emit_xii_section_bytes(
        (uint64_t)(uintptr_t)section_name,
        (uint64_t)name_len,
        (uint64_t)(uintptr_t)bytes,
        (uint64_t)len);
    return (rc == 0) ? 0 : -1;
}

uint64_t
emit_current_text_offset(void)
{
    /* Bump the synthetic call-site counter.  Caller (r3_pe_lattice_emit)
     * uses the returned value as the descriptor's call_site_offset
     * field.  A future enhancement can replace this with a true binary
     * offset via assembler label resolution. */
    uint64_t v = g_xii_call_site_counter;
    g_xii_call_site_counter += 1;
    return v;
}

/* ------------------------------------------------------------------ */
/* r3_ast_to_xii_term                                                  */
/*                                                                      */
/* AST -> XII-term mapper.  Recursively walks the function body AST    */
/* and produces an XII algebraic term using the basis kernels and      */
/* fusion operators from xii_term.iii.  The mapping is:                */
/*                                                                      */
/*   AST node kind            -> XII term                              */
/*   -------------------------+--------------------------------------- */
/*   EXPR_BLOCK (statements)  -> F.THEN-fold of statement terms        */
/*   STMT_LET                 -> F.COMPOSE(K02_BIND(name_hash), val)   */
/*   STMT_RETURN              -> F.COMPOSE(K03_CONVEY(0), value)       */
/*   STMT_EXPR                -> the underlying expression term         */
/*   STMT_ASSIGN              -> F.COMPOSE(K02_BIND(lval_hash), val)   */
/*   EXPR_BINARY              -> F.WITH(lhs, rhs)                       */
/*   EXPR_CALL                -> F.COMPOSE-fold: callee with each arg  */
/*   EXPR_MATCH               -> F.IF(scrutinee, arm1, arm2_fold)      */
/*   EXPR_INT / EXPR_HEX      -> K01_FORM(low 18 bits of value)        */
/*   EXPR_IDENT (var ref)     -> K02_BIND(name_hash)                   */
/*   (anything else)          -> K06_COMPOSE_NULL (empty form)         */
/*                                                                      */
/* Returns the term ref allocated in xii_term's arena, or              */
/* xii_term_make_null() when there's no recognisable content.  The     */
/* arena must already have been reset by the caller                    */
/* (r3_pe_canonicalise does this in cg_r3_xii.c).                      */
/* ------------------------------------------------------------------ */

extern uint32_t xii_term_make_basis(uint8_t kind, uint32_t sub);
extern uint32_t xii_term_make_fusion2(uint8_t kind, uint32_t a, uint32_t b);
extern uint32_t xii_term_make_if(uint32_t pred, uint32_t then_b, uint32_t else_b);
extern uint32_t xii_rewrite_null_form(void);

/* XII kind ids (mirrored from xii_term.iii). */
#define XAT_K01_FORM     0u
#define XAT_K02_BIND     1u
#define XAT_K03_CONVEY   2u
#define XAT_K06_COMPOSE  5u
#define XAT_FCOMPOSE    18u
#define XAT_FTHEN       19u
#define XAT_FWITH       20u
#define XAT_NULL_REF    0xFFFFFFFFu

/* FNV-1a hash of source-text slice, used as a deterministic 32-bit id
 * for variable/parameter names so distinct identifiers map to distinct
 * basis subforms. */
static uint32_t
hash_src_text(const iii_ast_t *ast, iii_src_text_t t)
{
    if (!ast || t.length == 0) return 0u;
    const uint8_t *buf = iii_ast_source_buf(ast);
    if (!buf) return 0u;
    uint32_t h = 0x811C9DC5u;
    for (uint32_t i = 0; i < t.length; ++i) {
        h ^= (uint32_t)buf[t.offset + i];
        h *= 0x01000193u;
    }
    /* K01_FORM subform width is 18 bits per S26.18; mask for safe fit. */
    return h & 0x3FFFFu;
}

static uint32_t
make_null_term(void)
{
    return xii_term_make_basis((uint8_t)XAT_K06_COMPOSE, xii_rewrite_null_form());
}

/* Forward declaration: mutual recursion via the helper. */
static uint32_t r3_ast_node_to_xii(const iii_ast_t *ast, uint32_t node);

static uint32_t
fold_then_stmts(const iii_ast_t *ast, iii_ast_list_t stmts)
{
    if (stmts.count == 0) return make_null_term();
    uint32_t acc = r3_ast_node_to_xii(ast, iii_ast_list_at(ast, stmts, 0));
    for (uint32_t i = 1; i < stmts.count; ++i) {
        uint32_t s = r3_ast_node_to_xii(ast, iii_ast_list_at(ast, stmts, i));
        uint32_t next = xii_term_make_fusion2((uint8_t)XAT_FTHEN, acc, s);
        if (next == XAT_NULL_REF) { return acc; }   /* arena full */
        acc = next;
    }
    return acc;
}

static uint32_t
fold_compose_args(const iii_ast_t *ast, uint32_t callee_term, iii_ast_list_t args)
{
    uint32_t acc = callee_term;
    for (uint32_t i = 0; i < args.count; ++i) {
        uint32_t arg_node = iii_ast_list_at(ast, args, i);
        const iii_ast_node_t *an = iii_ast_get(ast, arg_node);
        if (!an) continue;
        /* III_AST_ARG wraps the actual expression in `.value_expr`. */
        uint32_t expr_node = (an->kind == III_AST_ARG) ? an->u.arg.value_expr : arg_node;
        uint32_t arg_term = r3_ast_node_to_xii(ast, expr_node);
        uint32_t next = xii_term_make_fusion2((uint8_t)XAT_FCOMPOSE, acc, arg_term);
        if (next == XAT_NULL_REF) { return acc; }
        acc = next;
    }
    return acc;
}

static uint32_t
r3_ast_node_to_xii(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return make_null_term();
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n) return make_null_term();

    switch (n->kind) {
        case III_AST_EXPR_BLOCK:
            return fold_then_stmts(ast, n->u.block.stmts);

        case III_AST_STMT_LET: {
            uint32_t val = (n->u.let_.value_expr != 0)
                ? r3_ast_node_to_xii(ast, n->u.let_.value_expr)
                : make_null_term();
            uint32_t bind = xii_term_make_basis((uint8_t)XAT_K02_BIND,
                                                hash_src_text(ast, n->u.let_.name));
            return xii_term_make_fusion2((uint8_t)XAT_FCOMPOSE, bind, val);
        }

        case III_AST_STMT_RETURN: {
            uint32_t val = (n->u.return_.value_expr != 0)
                ? r3_ast_node_to_xii(ast, n->u.return_.value_expr)
                : make_null_term();
            uint32_t convey = xii_term_make_basis((uint8_t)XAT_K03_CONVEY, 0u);
            return xii_term_make_fusion2((uint8_t)XAT_FCOMPOSE, convey, val);
        }

        case III_AST_STMT_EXPR:
            return r3_ast_node_to_xii(ast, n->u.expr_stmt.expr);

        case III_AST_STMT_ASSIGN: {
            uint32_t val = r3_ast_node_to_xii(ast, n->u.assign.value_expr);
            /* Hash the lvalue's source text as the bind subform. */
            uint32_t lhash = 0u;
            const iii_ast_node_t *lv = iii_ast_get(ast, n->u.assign.lvalue_expr);
            if (lv && lv->kind == III_AST_EXPR_IDENT) {
                lhash = hash_src_text(ast, lv->u.ident.name);
            }
            uint32_t bind = xii_term_make_basis((uint8_t)XAT_K02_BIND, lhash);
            return xii_term_make_fusion2((uint8_t)XAT_FCOMPOSE, bind, val);
        }

        case III_AST_EXPR_BINARY: {
            uint32_t lhs = r3_ast_node_to_xii(ast, n->u.binary.lhs);
            uint32_t rhs = r3_ast_node_to_xii(ast, n->u.binary.rhs);
            return xii_term_make_fusion2((uint8_t)XAT_FWITH, lhs, rhs);
        }

        case III_AST_EXPR_CALL: {
            uint32_t callee = r3_ast_node_to_xii(ast, n->u.call.callee);
            return fold_compose_args(ast, callee, n->u.call.args);
        }

        case III_AST_EXPR_MATCH: {
            uint32_t scrut = r3_ast_node_to_xii(ast, n->u.match_expr.scrutinee);
            /* Fold arms via F.IF(scrut, arm0, F.IF(scrut, arm1, ...)).
             * Arms are MATCH_ARM nodes; the body is .body. */
            if (n->u.match_expr.arms.count == 0) { return scrut; }
            uint32_t else_acc = make_null_term();
            /* Build right-to-left: else_acc = arm[n-1].body, then for
             * i = n-2..0: else_acc = F.IF(scrut, arm[i].body, else_acc). */
            for (int32_t i = (int32_t)n->u.match_expr.arms.count - 1; i >= 0; --i) {
                uint32_t arm_idx = iii_ast_list_at(ast, n->u.match_expr.arms, (uint32_t)i);
                const iii_ast_node_t *arm = iii_ast_get(ast, arm_idx);
                if (!arm || arm->kind != III_AST_MATCH_ARM) continue;
                uint32_t body_term = r3_ast_node_to_xii(ast, arm->u.match_arm.body);
                if (i == (int32_t)n->u.match_expr.arms.count - 1) {
                    else_acc = body_term;
                } else {
                    else_acc = xii_term_make_if(scrut, body_term, else_acc);
                    if (else_acc == XAT_NULL_REF) return body_term;
                }
            }
            return else_acc;
        }

        case III_AST_EXPR_INT:
            return xii_term_make_basis((uint8_t)XAT_K01_FORM,
                                       (uint32_t)n->u.int_.value & 0x3FFFFu);

        case III_AST_EXPR_HEX:
            return xii_term_make_basis((uint8_t)XAT_K01_FORM,
                                       (uint32_t)n->u.hex_.value & 0x3FFFFu);

        case III_AST_EXPR_IDENT:
            return xii_term_make_basis((uint8_t)XAT_K02_BIND,
                                       hash_src_text(ast, n->u.ident.name));

        default:
            return make_null_term();
    }
}

uint32_t
r3_ast_to_xii_term(uint64_t ast, uint64_t body_node)
{
    /* The "ast" handle here is the sema-state pointer (same convention as
     * the sema_xii_adapter shims); recover the raw iii_ast_t* via
     * iii_sema_ast.  This means r3_pe_canonicalise still pre-resets the
     * arena (in cg_r3_xii.c) and the recursive mapper just allocates. */
    const iii_ast_t *iast = adapter_ast(ast);
    if (!iast) {
        return xii_term_make_basis((uint8_t)XAT_K06_COMPOSE, xii_rewrite_null_form());
    }
    return r3_ast_node_to_xii(iast, (uint32_t)body_node);
}

#else  /* IIIS_XII_ENABLED -- stubs for iiis-1 link compatibility */

/* The cg_r3.iii XII gate is unreachable when IIIS_XII_ENABLED is off
 * (sema_xii_anno_has_in_ast always returns 0u8 via the sema-side
 * stub).  These stubs provide the linkage symbols cg_r3_xii.c
 * references so iiis-1's object set can still link.  Each is a no-op
 * returning a safe default. */

#include <stdint.h>

uint64_t
ast_walk_find_kind(uint64_t fn_node, int kind)
{
    (void)fn_node; (void)kind;
    return 0;
}

uint64_t
ast_get_field(uint64_t ast_handle, uint64_t node, int field_id)
{
    (void)ast_handle; (void)node; (void)field_id;
    return 0;
}

uint32_t
cpufeat_feature_mask(void)
{
    return 0u;
}

uint32_t
cpufeat_auto_target(void)
{
    return 0xFFFFFFFFu;
}

int
emit_section_bytes(const char *section_name, const uint8_t *bytes, uint32_t len)
{
    (void)section_name; (void)bytes; (void)len;
    return 0;
}

uint64_t
emit_current_text_offset(void)
{
    return 0;
}

extern uint32_t xii_term_make_basis(uint8_t kind, uint32_t sub);
extern uint32_t xii_rewrite_null_form(void);

uint32_t
r3_ast_to_xii_term(uint64_t ast, uint64_t body_node)
{
    (void)ast; (void)body_node;
    return xii_term_make_basis((uint8_t)5u /* K06_COMPOSE */, xii_rewrite_null_form());
}

#endif /* IIIS_XII_ENABLED */
