/* Linked-chunk bump arena for string payloads. */
#ifndef III_ARENA_H
#define III_ARENA_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct iii_arena_chunk {
    struct iii_arena_chunk *next;
    size_t cap;
    size_t used;
    uint8_t data[1];
} iii_arena_chunk_t;

typedef struct iii_arena {
    iii_arena_chunk_t *head;
    size_t chunk_size;
} iii_arena_t;

void   iii_arena_init(iii_arena_t *a);
void   iii_arena_destroy(iii_arena_t *a);
void  *iii_arena_alloc(iii_arena_t *a, size_t bytes, size_t align);
uint8_t *iii_arena_dup(iii_arena_t *a, const uint8_t *src, size_t len);

#ifdef __cplusplus
}
#endif
#endif
