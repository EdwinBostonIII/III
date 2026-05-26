/* III Grammar — bump arena for AST nodes and child arrays. */
#ifndef III_PARSE_ARENA_H
#define III_PARSE_ARENA_H

#include <stdint.h>
#include <stddef.h>
#include "ast.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct iii_arena iii_arena_t;

iii_arena_t *iii_arena_create(void);

/* Underlying implementations exported under a parser-private name to
 * avoid clashing with the lexicon's own iii_arena_alloc/destroy
 * symbols (which act on a different, lexicon-internal struct).  The
 * public spellings below are static inline wrappers around these. */
void  iiip_arena_destroy_impl(iii_arena_t *a);
void *iiip_arena_alloc_impl(iii_arena_t *a, size_t bytes, size_t align);

static inline void iii_arena_destroy(iii_arena_t *a) {
    iiip_arena_destroy_impl(a);
}

/* Allocate `bytes` of zeroed memory inside the arena, aligned to `align`
 * (must be a power of two).  Returns NULL on OOM. */
static inline void *iii_arena_alloc(iii_arena_t *a, size_t bytes, size_t align) {
    return iiip_arena_alloc_impl(a, bytes, align);
}

/* Allocate and zero a fresh AST node.  kind is set, doc_offset = NO_DOC.
 * Returns NULL on OOM. */
iii_ast_node_t *iii_arena_node(iii_arena_t *a, iii_ast_kind_t k);

/* Append `child` to `parent->children`, growing the array geometrically
 * (start 4, double).  Silently no-ops on OOM (caller can detect via
 * unchanged child_count). */
void         iii_ast_add_child(iii_arena_t *a,
                               iii_ast_node_t *parent,
                               iii_ast_node_t *child);

/* Total bytes allocated across all chunks (for diagnostics). */
size_t       iii_arena_bytes(const iii_arena_t *a);

#ifdef __cplusplus
}
#endif
#endif
