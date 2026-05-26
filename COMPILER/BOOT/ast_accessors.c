/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\ast_accessors.c
 *
 * III Stage-0 ? flat AST accessor surface for .iii ports.
 *
 * The Stage-0 .iii dialect cannot read struct fields through a
 * pointer (no `p->f` syntax, no compound-payload local vars), so
 * every iii TU that needs to walk the AST or sema state must call
 * through wrapper functions that return scalar (uint32_t / uint64_t)
 * values.
 *
 * This file provides the minimal flat surface to walk an AST top
 * down ? node kind, decl name, list cardinalities, list-at, and
 * single-child accessors for the kinds traversed by proof.c's
 * defense-in-depth recursive ERROR_NODE walker.
 *
 * Each accessor:
 *   - returns 0 (or a clearly-empty value) when `ast` is NULL,
 *     `node` is 0 or out of range, or the kind does not have the
 *     requested field.
 *   - never aborts.
 *
 * Strict NIH: no allocation, no I/O, only ast.h.
 */

#include "ast.h"

#include <stddef.h>
#include <stdint.h>
#include <string.h>     /* memcmp for type_decl_for_name */



/* ??? Raw memory pokes (ASCII-clean read/write helpers) ??????????????? */

uint32_t iii_ast_load_u8(uint64_t ptr)
{
    if (!ptr) return 0;
    return (uint32_t)(*(const uint8_t *)(uintptr_t)ptr);
}

uint32_t iii_ast_store_u8(uint64_t ptr, uint32_t v)
{
    if (!ptr) return 0;
    *(uint8_t *)(uintptr_t)ptr = (uint8_t)(v & 0xFFu);
    return 0;
}

uint32_t iii_ast_store_u32(uint64_t ptr, uint32_t v)
{
    if (!ptr) return 0;
    *(uint32_t *)(uintptr_t)ptr = v;
    return 0;
}

/* ??? Source-buffer slice (returns pointer + length) ??????????????? */
/* Convenience: caller provides u32 offset and length, function returns
 * a u8 pointer into the source buffer or NULL if out of range. */
const uint8_t *iii_ast_source_slice(const iii_ast_t *ast,
                                     uint32_t offset, uint32_t length)
{
    if (!ast) return (const uint8_t *)0;
    const uint8_t *src = iii_ast_source_buf(ast);
    size_t slen = iii_ast_source_len(ast);
    if (!src) return (const uint8_t *)0;
    if ((size_t)offset + (size_t)length > slen) return (const uint8_t *)0;
    return src + offset;
}


/* iiis-2 — find a TYPE_DECL in the root module by name.  Returns the
 * TYPE_DECL's node id or 0 if no match.  Used by alias resolution at
 * codegen time.  O(N) over module decl count; v1.0 acceptable, future
 * stages may cache via a name-keyed table.  Source-buffer byte
 * compare uses memcmp directly. */
uint32_t iii_ast_type_decl_for_name(const iii_ast_t *ast,
                                    uint32_t name_offset, uint32_t name_length)
{
    if (!ast || name_length == 0) return 0;
    const uint8_t *src = iii_ast_source_buf(ast);
    if (!src) return 0;
    const iii_ast_node_t *mod =
        iii_ast_get(ast, iii_ast_root_module(ast));
    if (!mod || mod->kind != III_AST_MODULE) return 0;
    for (uint32_t i = 0; i < mod->u.module_.decls.count; i++) {
        uint32_t did = iii_ast_list_at(ast, mod->u.module_.decls, i);
        const iii_ast_node_t *d = iii_ast_get(ast, did);
        if (!d || d->kind != III_AST_TYPE_DECL) continue;
        if (d->u.type_decl.name.length != name_length) continue;
        if (memcmp(src + d->u.type_decl.name.offset,
                   src + name_offset, name_length) != 0)
            continue;
        return did;
    }
    return 0;
}

/* iiis-1 — EXPR_HEX u64 extraction.  Mirrors iii_ast_expr_int_u64
 * for hex literals (0xFFu64 etc.) so codegen's modifier-extract
 * helper can read u64 values uniformly regardless of literal form. */
uint64_t iii_ast_expr_hex_u64(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_EXPR_HEX) return 0u;
    return n->u.hex_.value;
}

/* Ident name. */
uint32_t iii_ast_ident_name_offset(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_EXPR_IDENT) return 0;
    return (uint32_t)n->u.ident.name.offset;
}

uint32_t iii_ast_ident_name_length(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_EXPR_IDENT) return 0;
    return (uint32_t)n->u.ident.name.length;
}

/* Field expr: object + field_name. */
uint32_t iii_ast_field_name_offset(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_EXPR_FIELD) return 0;
    return (uint32_t)n->u.field.field_name.offset;
}

uint32_t iii_ast_field_name_length(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_EXPR_FIELD) return 0;
    return (uint32_t)n->u.field.field_name.length;
}

/* For statement. */
uint32_t iii_ast_for_iter(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_STMT_FOR) return 0;
    return n->u.for_.iter_expr;
}

uint32_t iii_ast_for_where(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_STMT_FOR) return 0;
    return n->u.for_.where_expr;
}

uint32_t iii_ast_for_body(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_STMT_FOR) return 0;
    return n->u.for_.body_block;
}

/* Match (statement and expression ? same shape). */
uint32_t iii_ast_match_stmt_scrutinee(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_STMT_MATCH) return 0;
    return n->u.match_stmt.scrutinee;
}

uint32_t iii_ast_match_stmt_arm_count(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_STMT_MATCH) return 0;
    return n->u.match_stmt.arms.count;
}

uint32_t iii_ast_match_stmt_arm_at(const iii_ast_t *ast, uint32_t node, uint32_t i)
{
    if (!ast || node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_STMT_MATCH) return 0;
    return iii_ast_list_at(ast, n->u.match_stmt.arms, i);
}

uint32_t iii_ast_match_expr_scrutinee(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_EXPR_MATCH) return 0;
    return n->u.match_expr.scrutinee;
}

uint32_t iii_ast_match_expr_arm_count(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_EXPR_MATCH) return 0;
    return n->u.match_expr.arms.count;
}

uint32_t iii_ast_match_expr_arm_at(const iii_ast_t *ast, uint32_t node, uint32_t i)
{
    if (!ast || node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_EXPR_MATCH) return 0;
    return iii_ast_list_at(ast, n->u.match_expr.arms, i);
}

uint32_t iii_ast_match_arm_guard(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_MATCH_ARM) return 0;
    return n->u.match_arm.guard_expr;
}

uint32_t iii_ast_match_arm_body(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_MATCH_ARM) return 0;
    return n->u.match_arm.body;
}

/* Wavefront. */
uint32_t iii_ast_wavefront_node_count(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_STMT_WAVEFRONT) return 0;
    return n->u.wavefront.nodes.count;
}

uint32_t iii_ast_wavefront_node_at(const iii_ast_t *ast, uint32_t node, uint32_t i)
{
    if (!ast || node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_STMT_WAVEFRONT) return 0;
    return iii_ast_list_at(ast, n->u.wavefront.nodes, i);
}

uint32_t iii_ast_wavefront_rollback(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_STMT_WAVEFRONT) return 0;
    return n->u.wavefront.on_rollback_block;
}

/* Sanctum-enter body. */
uint32_t iii_ast_sanctum_enter_body(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_STMT_SANCTUM_ENTER) return 0;
    return n->u.sanctum_enter.body_block;
}

/* Parallel branches. */
uint32_t iii_ast_parallel_branch_count(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_EXPR_PARALLEL) return 0;
    return n->u.parallel.branches.count;
}

uint32_t iii_ast_parallel_branch_at(const iii_ast_t *ast, uint32_t node, uint32_t i)
{
    if (!ast || node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_EXPR_PARALLEL) return 0;
    return iii_ast_list_at(ast, n->u.parallel.branches, i);
}

/* Root module + annotate (already exposed in ast.h directly; included
 * here for completeness/discoverability ? they are NOT redefined,
 * just listed in the comment for .iii ports). */


/* ??? LINK-port surface ???????????????????????????????????????????? */
/* Exposes: root module index, source-buffer base address, module use
 * list, use-decl payload (qualified_name offset/length, closure_mhash
 * node index), and EXPR_MHASH 32-byte payload address. */

uint32_t iii_ast_root_module_idx_c(const iii_ast_t *ast)
{
    if (!ast) return 0;
    return iii_ast_root_module(ast);
}

uint64_t iii_ast_source_buf_addr_c(const iii_ast_t *ast)
{
    if (!ast) return 0u;
    const uint8_t *src = iii_ast_source_buf(ast);
    return (uint64_t)(uintptr_t)src;
}

uint32_t iii_ast_module_use_count(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_MODULE) return 0;
    return n->u.module_.uses.count;
}

uint32_t iii_ast_module_use_at(const iii_ast_t *ast, uint32_t node, uint32_t i)
{
    if (!ast || node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_MODULE) return 0;
    if (i >= n->u.module_.uses.count) return 0;
    return iii_ast_list_at(ast, n->u.module_.uses, i);
}

uint32_t iii_ast_use_qname_offset(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_USE) return 0;
    return (uint32_t)n->u.use_.qualified_name.offset;
}

uint32_t iii_ast_use_qname_length(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_USE) return 0;
    return (uint32_t)n->u.use_.qualified_name.length;
}

uint32_t iii_ast_use_closure_mhash_node(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_USE) return 0;
    return n->u.use_.closure_mhash_node;
}

/* Returns the address of the 32-byte mhash payload buried in an
 * III_AST_EXPR_MHASH node, or 0 if `node` does not have that kind.
 * The returned address is stable for the lifetime of the AST. */
uint64_t iii_ast_expr_mhash_bytes_addr(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_EXPR_MHASH) return 0u;
    return (uint64_t)(uintptr_t)&n->u.mhash_.mhash[0];
}

/* ─── cg_r3 port — type-shape readers ─────────────────────────────
 * Stage-0 cg_r3 needs to know the byte-size of TYPE_REF leaf names
 * (u8/i8/bool/u16/i16/u32/i32/u64/i64) and the inner-node id of
 * TYPE_ARRAY for nested element sizing.  These mirror the cg_r3.c
 * `type_ref_byte_size` / `array_elem_byte_size` walks.  All accessors
 * are defensive: they return 0 / null on shape mismatch. */
uint32_t iii_ast_type_ref_name_off(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_TYPE_REF) return 0u;
    return n->u.type_ref.name.offset;
}
uint32_t iii_ast_type_ref_name_len(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_TYPE_REF) return 0u;
    return n->u.type_ref.name.length;
}
uint32_t iii_ast_type_array_inner(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_TYPE_ARRAY) return 0u;
    return n->u.type_array.inner;
}
uint64_t iii_ast_type_array_count(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_TYPE_ARRAY) return 0u;
    return n->u.type_array.count;
}
uint32_t iii_ast_type_ptr_inner(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_TYPE_PTR) return 0u;
    return n->u.type_ptr.inner;
}

/* ─── cg_r3 port — top-level decl accessors for emit_module ────────
 * CONST_DECL / VAR_DECL / EXPR_PARALLEL field readers used by the
 * data-section emission pass and the parallel-array initializer
 * unpack.  All defensive on shape mismatch. */
uint32_t iii_ast_const_decl_name_off(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_CONST_DECL) return 0u;
    return n->u.const_decl.name.offset;
}
uint32_t iii_ast_const_decl_name_len(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_CONST_DECL) return 0u;
    return n->u.const_decl.name.length;
}
uint32_t iii_ast_const_decl_type(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_CONST_DECL) return 0u;
    return n->u.const_decl.type_node;
}
uint32_t iii_ast_const_decl_value(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_CONST_DECL) return 0u;
    return n->u.const_decl.value_expr;
}
uint32_t iii_ast_var_decl_type(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_VAR_DECL) return 0u;
    return n->u.var_decl.type_node;
}
uint32_t iii_ast_var_decl_init(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_VAR_DECL) return 0u;
    return n->u.var_decl.init_expr;
}

/* ─── cg_r3 port — cast / sizeof readers ───────────────────────── */
uint32_t iii_ast_sizeof_target_type(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_EXPR_SIZEOF) return 0u;
    return n->u.sizeof_.target_type;
}
uint64_t iii_ast_sizeof_resolved(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0u;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_EXPR_SIZEOF) return 0u;
    return n->u.sizeof_.resolved;
}

/* ─── cg_rm2 port — unique AST accessors not present elsewhere ─────
 * Most generic AST readers needed by cg_rm2 are already supplied by
 * sema_accessors.c (using the _off / _len naming convention).  These
 * are the leftover gaps:
 *   - hex literal value (split u64)
 *   - bool literal value
 *   - string literal payload idx + length
 *   - raw_asm payload idx + length
 *   - sealed_call name (offset+length)
 *   - mhash byte-by-byte read (byte addr also already exposed)
 * Pure read accessors; opaque pointers; defensive on kind. */

uint32_t iii_ast_hex_value_lo(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_EXPR_HEX) return 0;
    return (uint32_t)(n->u.hex_.value & 0xFFFFFFFFu);
}
uint32_t iii_ast_hex_value_hi(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_EXPR_HEX) return 0;
    return (uint32_t)((n->u.hex_.value >> 32) & 0xFFFFFFFFu);
}
uint32_t iii_ast_bool_value(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_EXPR_BOOL) return 0;
    return n->u.bool_.value ? 1u : 0u;
}
uint32_t iii_ast_str_payload_idx(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_EXPR_STR) return 0;
    return (uint32_t)n->u.str_.string_payload_idx;
}
uint32_t iii_ast_str_string_len(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_EXPR_STR) return 0;
    return (uint32_t)n->u.str_.string_len;
}
uint32_t iii_ast_raw_asm_str_idx(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_EXPR_RAW_ASM) return 0;
    return n->u.raw_asm.raw_asm_str_idx;
}
uint32_t iii_ast_raw_asm_len(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_EXPR_RAW_ASM) return 0;
    return n->u.raw_asm.raw_asm_len;
}
uint32_t iii_ast_mhash_byte_at(const iii_ast_t *ast, uint32_t node, uint32_t i)
{
    if (!ast || node == 0 || i >= 32u) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_EXPR_MHASH) return 0;
    return (uint32_t)n->u.mhash_.mhash[i];
}
uint32_t iii_ast_sealed_call_name_off(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_SEALED_CALL_METHOD_DECL) return 0;
    return (uint32_t)n->u.sealed_call.name.offset;
}
uint32_t iii_ast_sealed_call_name_len(const iii_ast_t *ast, uint32_t node)
{
    if (!ast || node == 0) return 0;
    const iii_ast_node_t *n = iii_ast_get(ast, node);
    if (!n || n->kind != III_AST_SEALED_CALL_METHOD_DECL) return 0;
    return (uint32_t)n->u.sealed_call.name.length;
}
