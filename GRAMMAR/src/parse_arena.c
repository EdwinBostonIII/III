/* III Grammar — bump arena.
 *
 * Linked list of 64KB chunks; nodes and child arrays are bump-allocated
 * inside.  Nothing is freed until iii_arena_destroy().  Allocations
 * larger than the chunk size get their own oversized chunk.
 *
 * AST node child arrays: start cap = 4, geometric doubling on growth.
 * 16-byte alignment for node allocation.
 */
#include "iii/parse_arena.h"

#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#define IIIA_CHUNK_BYTES (64u * 1024u)
#define IIIA_NODE_ALIGN  16u
#define IIIA_CHILD_INIT  4u

typedef struct iii_chunk {
    struct iii_chunk *next;
    size_t            size;     /* total bytes in `mem` */
    size_t            used;     /* bytes consumed */
    uint8_t          *mem;
} iii_chunk_t;

struct iii_arena {
    iii_chunk_t *head;
    size_t       total_bytes;
};

static iii_chunk_t *new_chunk(size_t want) {
    size_t cap = (want > IIIA_CHUNK_BYTES) ? want : IIIA_CHUNK_BYTES;
    iii_chunk_t *c = (iii_chunk_t *)calloc(1, sizeof(*c));
    if (!c) return NULL;
    c->mem = (uint8_t *)calloc(1, cap);
    if (!c->mem) { free(c); return NULL; }
    c->size = cap;
    c->used = 0;
    c->next = NULL;
    return c;
}

iii_arena_t *iii_arena_create(void) {
    iii_arena_t *a = (iii_arena_t *)calloc(1, sizeof(*a));
    if (!a) return NULL;
    a->head = new_chunk(IIIA_CHUNK_BYTES);
    if (!a->head) { free(a); return NULL; }
    a->total_bytes = a->head->size;
    return a;
}

void iiip_arena_destroy_impl(iii_arena_t *a) {
    if (!a) return;
    iii_chunk_t *c = a->head;
    while (c) {
        iii_chunk_t *nx = c->next;
        free(c->mem);
        free(c);
        c = nx;
    }
    free(a);
}

static size_t align_up(size_t x, size_t a) {
    return (x + (a - 1)) & ~(a - 1);
}

void *iiip_arena_alloc_impl(iii_arena_t *a, size_t bytes, size_t align) {
    if (!a || bytes == 0) return NULL;
    if (align == 0) align = 1;

    iii_chunk_t *c = a->head;
    size_t off = align_up(c->used, align);
    if (off + bytes > c->size) {
        /* Grow: new chunk at the head of the list. */
        size_t want = bytes + (align - 1);
        iii_chunk_t *nc = new_chunk(want);
        if (!nc) return NULL;
        nc->next = a->head;
        a->head = nc;
        a->total_bytes += nc->size;
        c = nc;
        off = align_up(c->used, align);
    }
    void *p = c->mem + off;
    c->used = off + bytes;
    /* calloc on the chunk guarantees zero-init for first use; subsequent
     * bumps reuse memory that was zeroed at allocation but never written. */
    return p;
}

iii_ast_node_t *iii_arena_node(iii_arena_t *a, iii_ast_kind_t k) {
    iii_ast_node_t *n = (iii_ast_node_t *)iiip_arena_alloc_impl(
        a, sizeof(iii_ast_node_t), IIIA_NODE_ALIGN);
    if (!n) return NULL;
    /* Memory comes pre-zeroed from calloc-backed chunk on first use. */
    n->kind         = k;
    n->doc_offset   = (uint32_t)0xFFFFFFFFu; /* III_AST_NO_DOC */
    return n;
}

void iii_ast_add_child(iii_arena_t *a,
                       iii_ast_node_t *parent,
                       iii_ast_node_t *child) {
    if (!parent || !child) return;
    if (parent->child_count == parent->child_cap) {
        uint32_t newcap = parent->child_cap ? parent->child_cap * 2u
                                            : IIIA_CHILD_INIT;
        iii_ast_node_t **nb = (iii_ast_node_t **)iiip_arena_alloc_impl(
            a, (size_t)newcap * sizeof(iii_ast_node_t *), sizeof(void *));
        if (!nb) return;
        if (parent->child_count) {
            memcpy(nb, parent->children,
                   (size_t)parent->child_count * sizeof(iii_ast_node_t *));
        }
        parent->children = nb;
        parent->child_cap = newcap;
    }
    parent->children[parent->child_count++] = child;
}

size_t iii_arena_bytes(const iii_arena_t *a) {
    return a ? a->total_bytes : 0;
}
