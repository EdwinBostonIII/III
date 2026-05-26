#include "iii/arena.h"
#include <stdlib.h>
#include <string.h>

#define DEFAULT_CHUNK 65536u

static iii_arena_chunk_t *new_chunk(size_t cap) {
    iii_arena_chunk_t *c = (iii_arena_chunk_t *)malloc(sizeof(*c) + cap);
    if (!c) return NULL;
    c->next = NULL; c->cap = cap; c->used = 0;
    return c;
}

void iii_arena_init(iii_arena_t *a) {
    a->head = NULL; a->chunk_size = DEFAULT_CHUNK;
}

void iii_arena_destroy(iii_arena_t *a) {
    iii_arena_chunk_t *c = a->head;
    while (c) { iii_arena_chunk_t *n = c->next; free(c); c = n; }
    a->head = NULL;
}

void *iii_arena_alloc(iii_arena_t *a, size_t bytes, size_t align) {
    if (align == 0) align = 1;
    iii_arena_chunk_t *c = a->head;
    if (c) {
        size_t base = (size_t)c->data + c->used;
        size_t pad = (align - (base % align)) % align;
        if (c->used + pad + bytes <= c->cap) {
            uint8_t *p = c->data + c->used + pad;
            c->used += pad + bytes;
            return p;
        }
    }
    size_t cs = a->chunk_size;
    if (bytes + align > cs) cs = bytes + align;
    iii_arena_chunk_t *nc = new_chunk(cs);
    if (!nc) return NULL;
    nc->next = a->head; a->head = nc;
    size_t base = (size_t)nc->data;
    size_t pad = (align - (base % align)) % align;
    uint8_t *p = nc->data + pad;
    nc->used = pad + bytes;
    return p;
}

uint8_t *iii_arena_dup(iii_arena_t *a, const uint8_t *src, size_t len) {
    uint8_t *p = (uint8_t *)iii_arena_alloc(a, len + 1, 1);
    if (!p) return NULL;
    memcpy(p, src, len);
    p[len] = 0;
    return p;
}
