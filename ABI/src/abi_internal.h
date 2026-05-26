/* III-ABI internal helpers — type & name shared by validator,
 * lowerer, and tools.
 */
#ifndef III_ABI_INTERNAL_H
#define III_ABI_INTERNAL_H

#include <iii/abi.h>
#include <iii/ast.h>

#include <stddef.h>
#include <stdint.h>

/* Walk into an III_AST_TYPE wrapper down to its first non-TYPE child.
 * Counts how many AMP-introduced TYPE wrappers were stripped (each
 * indicates a `&` reference layer).  Returns the inner node.
 *
 * For arrays produced by parse_extern_type, the outer node is
 * III_AST_ARRAY_TYPE directly (not wrapped in III_AST_TYPE).
 */
const iii_ast_node_t *iiiabi_unwrap_type(const iii_ast_node_t *type_node,
                                         int *out_ref_depth);

/* Look up the textual name for an AST node that carries an interned
 * IDENT (string_payload is populated by parser's resolve_idents pass).
 * Writes up to cap-1 bytes into out (always 0-terminated).  Returns
 * the number of bytes written (excluding terminator).  Returns 0 if
 * no name is available. */
size_t iiiabi_node_text(const iii_ast_node_t *n, char *out, size_t cap);

/* Map a primitive name ("u8", "i32", "f64", ...) to a type kind.
 * Returns IIIABI_T_VOID for unknown / non-primitive names. */
iii_abi_type_kind_t iiiabi_type_from_name(const char *s, size_t n);

/* Size and alignment of a non-aggregate (or pointer) type, in bytes. */
uint32_t iiiabi_type_size(iii_abi_type_kind_t t);
uint32_t iiiabi_type_align(iii_abi_type_kind_t t);

/* Resolve an alias by IDENT inside `extern_decl`'s type-items.
 * Writes the resolved (non-alias) information into *out_type and the
 * array element count (if any) into *out_count + *out_elem.  Returns
 * 1 on success, 0 if not found or if the alias cycles. */
int iiiabi_resolve_alias(const iii_ast_node_t *extern_decl,
                         const char *alias_name, size_t alias_len,
                         iii_abi_type_kind_t *out_type,
                         uint32_t            *out_size,
                         uint32_t            *out_align,
                         uint32_t            *out_elem_count,
                         iii_abi_type_kind_t *out_elem_type);

/* Describe the param/return type of a parsed III_AST_TYPE / ARRAY_TYPE
 * subtree from an extern_item.  Returns IIIABI_OK on success or an
 * IIIABI_E_* code. */
int iiiabi_describe_type(const iii_ast_node_t *extern_decl,
                         const iii_ast_node_t *type_node,
                         iii_abi_param_t      *out_param);

/* Find the first III_AST_MODULE_ATTR child of `module` whose
 * interned-id resolves to "@ring".  Returns NULL if none. */
const iii_ast_node_t *iiiabi_find_ring_attr(const iii_ast_node_t *module);

/* Extract the ABI name (e.g. "c-msvc-x64") from the source bytes
 * spanning the extern_decl.  Looks for the first occurrence of "@abi("
 * inside the span and copies the contents up to the matching ')'.
 * Trims ASCII whitespace.  Returns the number of bytes written
 * (excluding terminator), or 0 if no @abi(...) was found. */
size_t iiiabi_extract_abi_name(const iii_ast_node_t *extern_decl,
                               const uint8_t *src, size_t src_len,
                               char *out, size_t cap);

/* snprintf-style helper that advances a write cursor inside an
 * out buffer, never overflowing.  Returns total bytes that would
 * have been written. */
size_t iiiabi_appendf(char *buf, size_t cap, size_t *pos,
                      const char *fmt, ...);

#endif /* III_ABI_INTERNAL_H */
