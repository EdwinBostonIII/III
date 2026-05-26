/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\ast_internal.h
 *
 * III Stage-0 AST — PRIVATE container layout.
 *
 * Sibling-private to ast.c.  Included by other BOOT translation units
 * that need direct field access (currently cg_r0.c and cg_rm1.c which
 * walk the source-byte buffer for label generation, and ast.c itself
 * which is the canonical implementation).
 *
 * NOT a public API.  Outside BOOT, the AST is opaque (forward-declared
 * `struct iii_ast` in ast.h).  The fields below are subject to
 * Stage-1+ rearrangement; cross-module callers must use the public
 * accessors in ast.h.
 */

#ifndef III_BOOT_AST_INTERNAL_H
#define III_BOOT_AST_INTERNAL_H

#include "ast.h"

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Hash-cons slot (A2). */
typedef struct {
    uint8_t  mhash[32];
    uint32_t node_index;
} iii_ast_hashcons_slot_t;

/* Position record (B1/B2/P1). */
typedef struct {
    iii_ast_position_t pos;
    int32_t            next;
} iii_ast_position_record_t;

/* Annotation slot (L1). */
typedef struct {
    uint64_t    key_hash;
    uint32_t    node_index;
    uint32_t    blob_offset;
    uint32_t    blob_len;
    const char *phase;
    bool        used;
} iii_ast_annotation_slot_t;

/* The AST container. */
struct iii_ast {
    /* Source observation. */
    const uint8_t *source_buf;
    size_t         source_len;
    const char    *source_path;

    /* Witnesses (D1, R1). */
    uint8_t parser_version_mhash[32];
    uint8_t token_stream_mhash[32];
    uint8_t source_mhash[32];
    uint8_t grammar_mhash[32];
    uint8_t root_module_mhash[32];

    /* Per-pool node arenas (H1). */
    iii_ast_node_t *small_nodes;
    iii_ast_node_t *medium_nodes;
    iii_ast_node_t *large_nodes;
    iii_ast_node_t *user_nodes;
    uint32_t small_count, small_cap;
    uint32_t medium_count, medium_cap;
    uint32_t large_count, large_cap;
    uint32_t user_count, user_cap;

    /* Per-pool side-tables. */
    uint8_t  (*small_mhash)[32];
    uint8_t  (*medium_mhash)[32];
    uint8_t  (*large_mhash)[32];
    uint8_t  (*user_mhash)[32];
    int32_t  *small_position_first;
    int32_t  *medium_position_first;
    int32_t  *large_position_first;
    int32_t  *user_position_first;
    uint32_t *small_binder_id;
    uint32_t *medium_binder_id;
    uint32_t *large_binder_id;
    uint32_t *user_binder_id;
    uint32_t *small_doc_comment;
    uint32_t *medium_doc_comment;
    uint32_t *large_doc_comment;
    uint32_t *user_doc_comment;

    /* Position arena. */
    iii_ast_position_record_t *positions;
    uint32_t position_count;
    uint32_t position_cap;

    /* List arena. */
    uint32_t *list_arena;
    uint32_t  list_cap, list_used;

    /* String payloads. */
    const uint8_t **string_payloads;
    uint32_t        string_payload_count, string_payload_cap;

    /* Hash-cons table (A2). */
    iii_ast_hashcons_slot_t *hashcons;
    uint32_t hashcons_cap;
    uint32_t hashcons_count;

    /* Annotations (L1). */
    iii_ast_annotation_slot_t *annotations;
    uint32_t                  annotation_cap;
    uint32_t                  annotation_count;
    uint8_t                  *annotation_blobs;
    uint32_t                  annotation_blob_used;
    uint32_t                  annotation_blob_cap;

    /* Phase-name arena. */
    char     *phase_arena;
    uint32_t  phase_arena_used;
    uint32_t  phase_arena_cap;

    /* User-kind registry (C1). */
    iii_ast_user_kind_t *user_kinds;
    uint32_t             user_kind_cap;
    uint32_t             user_kind_count;

    /* Binder-id allocator (M1). */
    uint32_t next_binder_id;

    /* Hole-id allocator (N1). */
    uint32_t next_hole_id;

    /* Root. */
    uint32_t root_module;
};

#ifdef __cplusplus
}
#endif

#endif /* III_BOOT_AST_INTERNAL_H */
