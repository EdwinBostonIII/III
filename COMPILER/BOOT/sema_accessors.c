/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\sema_accessors.c
 *
 * III Stage-0 / Stage-1 sema-port C accessor surface.
 *
 * Purpose: provide the .iii Stage-0 dialect with the AST + hexad-bitmap
 * accessors required to express sema.c's behaviour as sema.iii.  The
 * .iii dialect cannot read C struct fields directly, cannot consume
 * out-parameter pointers, and cannot pass arrays by value, so every
 * access goes through one of these scalar-in / scalar-out wrappers.
 *
 * Strict NIH (ADR-021): only pulls in ast.h + hexad_check.h headers
 * already in the BOOT TU set.  No third-party deps.
 *
 * Windows LLP64 invariant: every .iii `u64` MUST map to `uint64_t`,
 * NEVER `unsigned long` (which is 32-bit on MSYS).  This file uses
 * uint64_t / int64_t exclusively for 64-bit ABI parameters.
 *
 * Naming convention: every wrapper is prefixed iii_ast_* (AST surface)
 * or iii_hexad_*_c (hexad surface).  The `_c` suffix marks wrappers
 * whose underlying C symbol has a name colliding with the .iii dialect's
 * direct extern (e.g. iii_hexad_check_init takes void in C and is named
 * the same; we expose a thin pass-through purely for symmetry with the
 * other hexad helpers, and so that the .iii TU references one consistent
 * wrapper namespace).
 */

#include <stddef.h>
#include <stdint.h>
#include <string.h>

#include "ast.h"
#include "hexad_check.h"

/* Defined in ast.c but not exported through ast.h.  Sema's metal-block
 * raw-asm scan needs to read the payload bytes directly. */
extern const uint8_t *iii_ast_string_payload_get(const iii_ast_t *ast, uint32_t idx);

/* The internal payload-fetch helpers — defined in ast.c, not declared
 * in ast.h; we re-declare the public iii_ast_get prototype only. */

/* ─── Generic node helpers ────────────────────────────────────────── */

uint32_t iii_ast_node_count_u32(const iii_ast_t *ast)
{
    if (!ast) return 0u;
    size_t n = iii_ast_node_count(ast);
    if (n > 0xFFFFFFFFu) return 0xFFFFFFFFu;
    return (uint32_t)n;
}

uint32_t iii_ast_source_len_u32(const iii_ast_t *ast)
{
    if (!ast) return 0u;
    size_t n = iii_ast_source_len(ast);
    if (n > 0xFFFFFFFFu) return 0xFFFFFFFFu;
    return (uint32_t)n;
}

/* iii_ast_position_first wrapper — splits the discriminated position
 * into two scalar-returning functions: line and column.  Returns 0 if
 * the node has no recorded position or the first record is synthetic
 * (sema only needs physical positions for diagnostics; synthetic
 * positions are surfaced by walking the source_node_index link from
 * the caller side, but sema treats them as "no position"). */
uint32_t iii_ast_pos_line(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    iii_ast_position_t p;
    if (!iii_ast_position_first(ast, node, &p)) return 0u;
    if (p.kind != III_POS_PHYSICAL) return 0u;
    return p.u.physical.line;
}

uint32_t iii_ast_pos_col(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    iii_ast_position_t p;
    if (!iii_ast_position_first(ast, node, &p)) return 0u;
    if (p.kind != III_POS_PHYSICAL) return 0u;
    return p.u.physical.col;
}

/* Sema's binder-id assignment (P2 sets the binder_id field on every
 * resolved IDENT node so that downstream codegen can dereference
 * locals without re-walking the symbol stack).  iii_ast_set_binder_id
 * is bool-returning in C; .iii dialect maps bool to u32 (1/0) and we
 * surface a u32 wrapper for explicitness. */
uint32_t iii_ast_set_binder_id_u32(iii_ast_t *ast, uint32_t node, uint32_t binder)
{
    if (!ast || node == 0) return 0u;
    return iii_ast_set_binder_id(ast, node, binder) ? 1u : 0u;
}

/* RING_SET synthesis: sema P1 may attach an inferred ring mask to a
 * decl that has no explicit @ring(...) modifier.  Allocates a fresh
 * RING_SET node, fills the mask, marks synthetic.  Returns the node
 * index, or 0 on allocator failure. */
uint32_t iii_ast_synth_ring_set(iii_ast_t *ast, uint32_t mask)
{
    if (!ast) return 0u;
    uint32_t n = iii_ast_alloc_node(ast, III_AST_RING_SET, (const iii_src_pos_t *)0);
    if (n == 0) return 0u;
    iii_ast_node_t *node = iii_ast_get_mut(ast, n);
    if (!node) return 0u;
    node->u.ring_set.mask = mask;
    node->flags |= III_AST_FLAG_SYNTHETIC;
    return n;
}

/* String-payload accessors.  Sema's metal-block raw-asm scan reads the
 * payload bytes directly to look for forbidden privileged opcodes
 * outside of the declared ring mask.  Expose pointer + count as scalars. */
uint64_t iii_ast_string_payload_addr_c(const iii_ast_t *ast, uint32_t idx)
{
    if (!ast) return 0u;
    const uint8_t *p = iii_ast_string_payload_get(ast, idx);
    return (uint64_t)(uintptr_t)p;
}

uint32_t iii_ast_string_payload_count_c(const iii_ast_t *ast)
{
    if (!ast) return 0u;
    extern uint32_t iii_ast_string_payload_count(const iii_ast_t *ast);
    return iii_ast_string_payload_count(ast);
}

/* ─── Decl: FN_DECL ───────────────────────────────────────────────── */

uint32_t iii_ast_fn_name_off(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_FN_DECL) return 0u;
    return n->u.fn_decl.name.offset;
}

uint32_t iii_ast_fn_name_len(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_FN_DECL) return 0u;
    return n->u.fn_decl.name.length;
}

uint32_t iii_ast_cycle_name_off(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_CYCLE_DECL) return 0u;
    return n->u.cycle_decl.name.offset;
}

uint32_t iii_ast_cycle_name_len(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_CYCLE_DECL) return 0u;
    return n->u.cycle_decl.name.length;
}

uint32_t iii_ast_fn_modifier_count(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_FN_DECL) return 0u;
    return n->u.fn_decl.modifiers.count;
}

uint32_t iii_ast_fn_modifier_at(const iii_ast_t *ast, uint32_t node, uint32_t i)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_FN_DECL) return 0u;
    return iii_ast_list_at(ast, n->u.fn_decl.modifiers, i);
}

/* Stage 7.1: generic-fn type-params (@specialize). Empty for ordinary fns. */
uint32_t iii_ast_fn_type_param_count(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_FN_DECL) return 0u;
    return n->u.fn_decl.type_params.count;
}

uint32_t iii_ast_fn_type_param_at(const iii_ast_t *ast, uint32_t node, uint32_t i)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_FN_DECL) return 0u;
    return iii_ast_list_at(ast, n->u.fn_decl.type_params, i);
}

/* Stage 7.1: a TYPE_PARAM node's name (e.g. "T"). */
uint32_t iii_ast_type_param_name_off(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_TYPE_PARAM) return 0u;
    return n->u.type_param.name.offset;
}

uint32_t iii_ast_type_param_name_len(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_TYPE_PARAM) return 0u;
    return n->u.type_param.name.length;
}

uint32_t iii_ast_fn_param_count(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_FN_DECL) return 0u;
    return n->u.fn_decl.params.count;
}

uint32_t iii_ast_fn_param_at(const iii_ast_t *ast, uint32_t node, uint32_t i)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_FN_DECL) return 0u;
    return iii_ast_list_at(ast, n->u.fn_decl.params, i);
}

uint32_t iii_ast_fn_body(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_FN_DECL) return 0u;
    return n->u.fn_decl.body_block;
}

uint32_t iii_ast_fn_return_type(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_FN_DECL) return 0u;
    return n->u.fn_decl.return_type;
}

/* ─── Decl: CYCLE_DECL params (modifiers/forward/compromise already in ast_accessors.c) ─── */

uint32_t iii_ast_cycle_param_count(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_CYCLE_DECL) return 0u;
    return n->u.cycle_decl.params.count;
}

uint32_t iii_ast_cycle_param_at(const iii_ast_t *ast, uint32_t node, uint32_t i)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_CYCLE_DECL) return 0u;
    return iii_ast_list_at(ast, n->u.cycle_decl.params, i);
}

/* ─── Decl: TYPE_DECL ─────────────────────────────────────────────── */

uint32_t iii_ast_type_modifier_count(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_TYPE_DECL) return 0u;
    return n->u.type_decl.modifiers.count;
}

uint32_t iii_ast_type_modifier_at(const iii_ast_t *ast, uint32_t node, uint32_t i)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_TYPE_DECL) return 0u;
    return iii_ast_list_at(ast, n->u.type_decl.modifiers, i);
}

/* ─── Decl: MOBIUS_CANDIDATE_DECL ─────────────────────────────────── */

uint32_t iii_ast_mobius_modifier_count(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_MOBIUS_CANDIDATE_DECL) return 0u;
    return n->u.mobius_candidate.modifiers.count;
}

uint32_t iii_ast_mobius_modifier_at(const iii_ast_t *ast, uint32_t node, uint32_t i)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_MOBIUS_CANDIDATE_DECL) return 0u;
    return iii_ast_list_at(ast, n->u.mobius_candidate.modifiers, i);
}

uint32_t iii_ast_mobius_forward(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_MOBIUS_CANDIDATE_DECL) return 0u;
    return n->u.mobius_candidate.forward_block;
}

/* ─── Decl: EXTERN_DECL ───────────────────────────────────────────── */

uint32_t iii_ast_extern_abi(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_EXTERN_DECL) return 0u;
    return (uint32_t)n->u.extern_decl.abi;
}

uint32_t iii_ast_extern_param_count(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_EXTERN_DECL) return 0u;
    return n->u.extern_decl.params.count;
}

uint32_t iii_ast_extern_param_at(const iii_ast_t *ast, uint32_t node, uint32_t i)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_EXTERN_DECL) return 0u;
    return iii_ast_list_at(ast, n->u.extern_decl.params, i);
}

uint32_t iii_ast_extern_return_type(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_EXTERN_DECL) return 0u;
    return n->u.extern_decl.return_type;
}

/* ─── Decl: SEALED_CALL_METHOD_DECL ───────────────────────────────── */

uint32_t iii_ast_sealed_seal_id(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_SEALED_CALL_METHOD_DECL) return 0u;
    return n->u.sealed_call.seal_id;
}

uint32_t iii_ast_sealed_param_count(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_SEALED_CALL_METHOD_DECL) return 0u;
    return n->u.sealed_call.params.count;
}

uint32_t iii_ast_sealed_param_at(const iii_ast_t *ast, uint32_t node, uint32_t i)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_SEALED_CALL_METHOD_DECL) return 0u;
    return iii_ast_list_at(ast, n->u.sealed_call.params, i);
}

uint32_t iii_ast_sealed_body(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_SEALED_CALL_METHOD_DECL) return 0u;
    return n->u.sealed_call.body_block;
}

/* ─── Decl: STRUCT_DECL ───────────────────────────────────────────── */

uint32_t iii_ast_struct_field_count(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_STRUCT_DECL) return 0u;
    return n->u.struct_decl.fields.count;
}

uint32_t iii_ast_struct_field_at(const iii_ast_t *ast, uint32_t node, uint32_t i)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_STRUCT_DECL) return 0u;
    return iii_ast_list_at(ast, n->u.struct_decl.fields, i);
}

/* ─── Decl: VAR_DECL ──────────────────────────────────────────────── */

uint32_t iii_ast_var_init(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_VAR_DECL) return 0u;
    return n->u.var_decl.init_expr;
}

uint32_t iii_ast_var_type(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_VAR_DECL) return 0u;
    return n->u.var_decl.type_node;
}

/* ─── Decl: CONST_DECL ────────────────────────────────────────────── */

uint32_t iii_ast_const_value(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_CONST_DECL) return 0u;
    return n->u.const_decl.value_expr;
}

/* ─── Modifier ────────────────────────────────────────────────────── */

uint32_t iii_ast_modifier_arg_count(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_MODIFIER) return 0u;
    return n->u.modifier.args.count;
}

uint32_t iii_ast_modifier_arg_at(const iii_ast_t *ast, uint32_t node, uint32_t i)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_MODIFIER) return 0u;
    return iii_ast_list_at(ast, n->u.modifier.args, i);
}

uint32_t iii_ast_modifier_ring_mask(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_MODIFIER) return 0u;
    return n->u.modifier.ring_mask;
}

uint32_t iii_ast_modifier_hexad_node(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_MODIFIER) return 0u;
    return n->u.modifier.hexad_node;
}

uint32_t iii_ast_modifier_tier_kind(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_MODIFIER) return 0u;
    return n->u.modifier.tier_kind;
}

uint32_t iii_ast_modifier_epoch_value(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_MODIFIER) return 0u;
    return n->u.modifier.epoch_value;
}

/* ─── Statements: LET / FOR / IF / WHILE / METAL / SANCTUM_ENTER ──── */

uint32_t iii_ast_let_name_off(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_STMT_LET) return 0u;
    return n->u.let_.name.offset;
}

uint32_t iii_ast_let_name_len(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_STMT_LET) return 0u;
    return n->u.let_.name.length;
}

uint32_t iii_ast_let_type(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_STMT_LET) return 0u;
    return n->u.let_.type_node;
}

uint32_t iii_ast_let_mutable(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_STMT_LET) return 0u;
    return n->u.let_.mutable_ ? 1u : 0u;
}

uint32_t iii_ast_for_var_off(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_STMT_FOR) return 0u;
    return n->u.for_.var.offset;
}

uint32_t iii_ast_for_var_len(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_STMT_FOR) return 0u;
    return n->u.for_.var.length;
}

uint32_t iii_ast_if_cond(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_STMT_IF) return 0u;
    return n->u.if_.cond;
}

uint32_t iii_ast_if_then(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_STMT_IF) return 0u;
    return n->u.if_.then_block;
}

uint32_t iii_ast_if_else(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_STMT_IF) return 0u;
    return n->u.if_.else_block;
}

uint32_t iii_ast_while_cond(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_STMT_WHILE) return 0u;
    return n->u.while_.cond;
}

uint32_t iii_ast_while_body(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_STMT_WHILE) return 0u;
    return n->u.while_.body_block;
}

/* iiis-2 — STMT_LOOP body accessor.  Returns the EXPR_BLOCK node id
 * for the loop body, or 0 if `node` is not a STMT_LOOP. */
uint32_t iii_ast_loop_body(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_STMT_LOOP) return 0u;
    return n->u.loop_.body_block;
}

uint32_t iii_ast_metal_ring_mask(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_STMT_METAL) return 0u;
    return n->u.metal.ring_mask;
}

uint32_t iii_ast_metal_asm_str_idx(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_STMT_METAL) return 0u;
    return n->u.metal.raw_asm_str_idx;
}

uint32_t iii_ast_metal_asm_len(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_STMT_METAL) return 0u;
    return n->u.metal.raw_asm_len;
}

uint32_t iii_ast_sanctum_enter_frame_off(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_STMT_SANCTUM_ENTER) return 0u;
    return n->u.sanctum_enter.frame_var.offset;
}

uint32_t iii_ast_sanctum_enter_frame_len(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_STMT_SANCTUM_ENTER) return 0u;
    return n->u.sanctum_enter.frame_var.length;
}

/* ─── Patterns ────────────────────────────────────────────────────── */

uint32_t iii_ast_match_arm_pattern(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_MATCH_ARM) return 0u;
    return n->u.match_arm.pattern;
}

uint32_t iii_ast_pat_ident_name_off(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_PAT_IDENT) return 0u;
    return n->u.pat_ident.name.offset;
}

uint32_t iii_ast_pat_ident_name_len(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_PAT_IDENT) return 0u;
    return n->u.pat_ident.name.length;
}

uint32_t iii_ast_pat_literal_node(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_PAT_LITERAL) return 0u;
    return n->u.pat_literal.literal_node;
}

uint32_t iii_ast_pat_hexad_trit_at(const iii_ast_t *ast, uint32_t node, uint32_t pillar)
{
    if (!ast || node == 0 || pillar >= 6u) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_PAT_HEXAD) return 0u;
    return (uint32_t)n->u.pat_hexad.trits[pillar];
}

/* ─── Param ───────────────────────────────────────────────────────── */

uint32_t iii_ast_param_name_off(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_PARAM) return 0u;
    return n->u.param.name.offset;
}

uint32_t iii_ast_param_name_len(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_PARAM) return 0u;
    return n->u.param.name.length;
}

uint32_t iii_ast_param_type(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_PARAM) return 0u;
    return n->u.param.type_node;
}

/* ─── Expressions: INT / TRIT / HEXAD / UNARY / RANGE / CAST ──────── */

/* iii_expr_int_payload_t.value is u64.  .iii dialect can't widen
 * scalar return to u64 portably across our wrappers, so split into
 * lo/hi u32 halves; sema reassembles via (hi << 32) | lo if the
 * value is needed (mostly sema only checks zero/non-zero for
 * compile-time fold gates, so lo alone suffices for those). */
uint32_t iii_ast_expr_int_lo(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_EXPR_INT) return 0u;
    return (uint32_t)(n->u.int_.value & 0xFFFFFFFFu);
}

uint32_t iii_ast_expr_int_hi(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_EXPR_INT) return 0u;
    return (uint32_t)((n->u.int_.value >> 32) & 0xFFFFFFFFu);
}

uint64_t iii_ast_expr_int_u64(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_EXPR_INT) return 0u;
    return n->u.int_.value;
}

uint32_t iii_ast_expr_trit_value(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_EXPR_TRIT) return 0u;
    return (uint32_t)n->u.trit_.trit;
}

uint32_t iii_ast_expr_hexad_trit_at(const iii_ast_t *ast, uint32_t node, uint32_t pillar)
{
    if (!ast || node == 0 || pillar >= 6u) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_EXPR_HEXAD) return 0u;
    return (uint32_t)n->u.hexad_.trits[pillar];
}

uint32_t iii_ast_unary_op(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_EXPR_UNARY) return 0u;
    return (uint32_t)n->u.unary.op;
}

uint32_t iii_ast_binary_op(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_EXPR_BINARY) return 0u;
    return (uint32_t)n->u.binary.op;
}

uint32_t iii_ast_range_lo(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_EXPR_RANGE) return 0u;
    return n->u.range_.lo;
}

uint32_t iii_ast_range_hi(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_EXPR_RANGE) return 0u;
    return n->u.range_.hi;
}

uint32_t iii_ast_cast_value(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_EXPR_CAST) return 0u;
    return n->u.cast_.value_expr;
}

uint32_t iii_ast_cast_target_type(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_EXPR_CAST) return 0u;
    return n->u.cast_.target_type;
}

/* ─── VAR_DECL / STRUCT_DECL name accessors (not in pf_decl_name_internal) ── */

uint32_t iii_ast_var_decl_name_off(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_VAR_DECL) return 0u;
    return n->u.var_decl.name.offset;
}

uint32_t iii_ast_var_decl_name_len(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_VAR_DECL) return 0u;
    return n->u.var_decl.name.length;
}

uint32_t iii_ast_struct_decl_name_off(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_STRUCT_DECL) return 0u;
    return n->u.struct_decl.name.offset;
}

uint32_t iii_ast_struct_decl_name_len(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_STRUCT_DECL) return 0u;
    return n->u.struct_decl.name.length;
}

/* ─── Hexad helpers (call into hexad_check.c via thin wrappers) ───── */

void iii_hexad_check_init_c(void)
{
    iii_hexad_check_init();
}

uint32_t iii_hexad_packed_admitted_c(uint32_t packed)
{
    if (packed > 0xFFFFu) return 0u;
    return iii_hexad_packed_admitted((uint16_t)packed) ? 1u : 0u;
}

/* Pack 6 individual trit pillars (each 0..2 = NEG/ZERO/POS, or 3 =
 * INVALID) into a single packed hexad u32 (range 0..728).  Returns
 * 0xFFFFFFFFu if any pillar is INVALID — sema treats that as a
 * type error and emits diagnostic SE_HEXAD_INVALID_TRIT.  Encodes
 * the same semantics as iii_hexad_pack_from_ast_trits without
 * exposing the array-pointer ABI that .iii cannot construct. */
uint32_t iii_hexad_pack_pillars_c(uint32_t p0, uint32_t p1, uint32_t p2,
                                    uint32_t p3, uint32_t p4, uint32_t p5)
{
    iii_ast_trit_t t[6];
    uint32_t pp[6] = { p0, p1, p2, p3, p4, p5 };
    for (unsigned i = 0; i < 6; ++i) {
        if (pp[i] > (uint32_t)III_TRIT_AST_POS) return 0xFFFFFFFFu;
        t[i] = (iii_ast_trit_t)pp[i];
    }
    return (uint32_t)iii_hexad_pack_from_ast_trits(t);
}
