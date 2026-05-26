/* iii_cg_pe_iiis1.c — iiis-1 partial-evaluator wrappers.
 *
 * Exposes Phase C.6 PE classification to .iii-callable surface.
 * Mirrors cg_r3.c's static cg_r3_pe_classify_intent_arg but accepts
 * the ast pointer directly (no iii_cg_r3_state_t needed).
 *
 * iiis-1 uses these wrappers to detect `resolve(set, intent_form(LIT), ctx)`
 * callsites and replace them with direct `leaq <dispatch_fn>(%rip), %rax`
 * loads — producing the bit-identical output cg_r3.c produces.
 *
 * Single source of truth: iii_compositions.def → iii_compositions.h.
 */

#include "ast.h"
#include "iii_compositions.h"
#include <stddef.h>
#include <stdint.h>
#include <string.h>

/* Forward declaration for mutual recursion with cross-fn case. */
static const char *classify_intent_bounded(const iii_ast_t *ast, uint32_t intent_arg_node, int depth);

/* iiis-2 cross-function PE: returns the dispatch_fp_name common to ALL
 * return statements of `fn_decl_node`'s body — or NULL if any return
 * is non-static, returns have divergent fn_names, or the fn body is
 * empty/missing.  Recursive (bounded by `depth` to avoid cycles).
 *
 * Mirrors the IIIS-2 architecture doc §2 design: "PE consults this at
 * every resolve() site that takes a non-literal intent arg."  Today's
 * iiis-1 PE only narrows direct-literal or let-bound-literal intents;
 * this lifts the analysis across function boundaries when the fn's
 * return is provably-literal-derived. */
static const char *fn_returns_static_intent(const iii_ast_t *ast,
                                             uint32_t fn_decl_node,
                                             int depth)
{
    if (!ast || fn_decl_node == 0 || depth <= 0) return NULL;
    const iii_ast_node_t *fn = iii_ast_get(ast, fn_decl_node);
    if (!fn || fn->kind != III_AST_FN_DECL) return NULL;
    uint32_t body_id = fn->u.fn_decl.body_block;
    if (body_id == 0) return NULL;
    const iii_ast_node_t *body = iii_ast_get(ast, body_id);
    if (!body) return NULL;
    if (body->kind != III_AST_EXPR_BLOCK && body->kind != III_AST_FORWARD_BLOCK) return NULL;

    iii_ast_list_t stmts = body->u.block.stmts;
    const char *common_fn = NULL;
    int returns_seen = 0;
    for (size_t i = 0; i < stmts.count; i++) {
        uint32_t stmt_id = iii_ast_list_at(ast, stmts, i);
        if (stmt_id == 0) continue;
        const iii_ast_node_t *stmt = iii_ast_get(ast, stmt_id);
        if (!stmt || stmt->kind != III_AST_STMT_RETURN) continue;
        uint32_t ret_val = stmt->u.return_.value_expr;
        if (ret_val == 0) return NULL;
        const char *fn_name = classify_intent_bounded(ast, ret_val, depth - 1);
        if (!fn_name) return NULL;
        if (common_fn == NULL) {
            common_fn = fn_name;
        } else if (strcmp(common_fn, fn_name) != 0) {
            return NULL;
        }
        returns_seen++;
    }
    return returns_seen > 0 ? common_fn : NULL;
}

/* Core classifier (private, depth-bounded for cross-fn recursion). */
static const char *classify_intent_bounded(const iii_ast_t *ast,
                                            uint32_t intent_arg_node,
                                            int depth)
{
    if (!ast || intent_arg_node == 0 || depth <= 0) return NULL;

    const iii_ast_node_t *a = iii_ast_get(ast, intent_arg_node);
    if (!a) return NULL;

    /* EXPR_ARG unwrap. */
    if (a->kind == III_AST_ARG) {
        intent_arg_node = a->u.arg.value_expr;
        a = iii_ast_get(ast, intent_arg_node);
        if (!a) return NULL;
    }

    /* Find the constructor call: either inline EXPR_CALL or via let-binder. */
    const iii_ast_node_t *call_node = NULL;
    if (a->kind == III_AST_EXPR_CALL) {
        call_node = a;
    } else if (a->kind == III_AST_EXPR_IDENT) {
        uint32_t bid = iii_ast_node_binder_id(ast, intent_arg_node);
        const iii_ast_node_t *binder = bid ? iii_ast_get(ast, bid) : NULL;
        if (binder && binder->kind == III_AST_STMT_LET) {
            uint32_t init_id = binder->u.let_.value_expr;
            const iii_ast_node_t *init = init_id ? iii_ast_get(ast, init_id) : NULL;
            if (init && init->kind == III_AST_EXPR_CALL) {
                call_node = init;
            }
        }
    }
    if (!call_node) return NULL;

    /* Callee must be an IDENT (primitive constructor or user fn). */
    const iii_ast_node_t *callee = iii_ast_get(ast, call_node->u.call.callee);
    if (!callee || callee->kind != III_AST_EXPR_IDENT) return NULL;
    const uint8_t *src = iii_ast_source_buf(ast);
    if (!src) return NULL;
    iii_src_text_t cn = callee->u.ident.name;

    /* Case A: callee is a primitive constructor — look up by literal arg.
     * Only the three constructors intent_form/intent_convey/intent_act
     * trigger this — anything longer cannot be a primitive constructor,
     * so we don't even copy the name; case B handles user fns directly. */
    uint8_t expect_primitive = 0;
    if (cn.length < 24) {
        char buf[24];
        memcpy(buf, src + cn.offset, cn.length);
        buf[cn.length] = 0;
        if (strcmp(buf, "intent_form") == 0)        expect_primitive = 1;
        else if (strcmp(buf, "intent_convey") == 0) expect_primitive = 3;
        else if (strcmp(buf, "intent_act") == 0)    expect_primitive = 5;
    }

    if (expect_primitive != 0) {
        iii_ast_list_t cargs = call_node->u.call.args;
        if (cargs.count == 0) return NULL;
        uint32_t a0 = iii_ast_list_at(ast, cargs, 0);
        const iii_ast_node_t *a0n = a0 ? iii_ast_get(ast, a0) : NULL;
        if (!a0n || a0n->kind != III_AST_ARG) return NULL;
        const iii_ast_node_t *vexpr = iii_ast_get(ast, a0n->u.arg.value_expr);
        if (!vexpr || vexpr->kind != III_AST_EXPR_INT) return NULL;
        uint64_t literal = (uint64_t)vexpr->u.int_.value;

        for (size_t i = 0; i < III_COMPOSITION_TABLE_LEN; i++) {
            if (III_COMPOSITION_TABLE[i].primitive_id == expect_primitive &&
                III_COMPOSITION_TABLE[i].literal_form_id == literal) {
                return III_COMPOSITION_TABLE[i].dispatch_fp_name;
            }
        }
        return NULL;
    }

    /* Case B (iiis-2 cross-function PE): callee is a user FN_DECL.
     * Recursively classify the fn's return statements. */
    uint32_t callee_decl = iii_ast_node_binder_id(ast, call_node->u.call.callee);
    if (callee_decl) {
        const iii_ast_node_t *cdb = iii_ast_get(ast, callee_decl);
        if (cdb && cdb->kind == III_AST_FN_DECL) {
            return fn_returns_static_intent(ast, callee_decl, depth - 1);
        }
    }
    return NULL;
}

/* Classify the intent argument of a resolve() call.  Mirrors the
 * cg_r3.c static helper byte-for-byte for the iiis-1 single+multi-stmt
 * narrowing cases, AND extends with the iiis-2 cross-function PE
 * (Case B above): when the intent traces to a user FN_DECL whose body
 * provably returns a static intent.
 *
 * Returns the dispatch_fp_name (pointer into III_COMPOSITION_TABLE) on
 * hit; NULL on miss.  Recursion depth bounded at 8 levels for safety. */
const char *iii_cg_pe_classify_intent(const iii_ast_t *ast, uint32_t intent_arg_node)
{
    return classify_intent_bounded(ast, intent_arg_node, 8);
}

/* strlen wrapper for .iii consumers. */
uint32_t iii_cg_pe_name_len(const char *name)
{
    if (!name) return 0;
    return (uint32_t)strlen(name);
}

/* Read byte at offset from a C string.  Convenience for .iii loops
 * that emit byte-by-byte. */
uint32_t iii_cg_pe_name_byte(const char *name, uint32_t idx)
{
    if (!name) return 0;
    return (uint32_t)(unsigned char)name[idx];
}
