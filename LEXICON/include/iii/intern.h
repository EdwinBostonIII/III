/* Open-addressed FNV-1a hash intern table. */
#ifndef III_INTERN_H
#define III_INTERN_H

#include <stdint.h>
#include <stddef.h>
#include "arena.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct iii_intern_entry {
    uint32_t hash;
    uint32_t id;        /* 0 = empty slot, real ids are +1 internally; user-visible id = stored value */
} iii_intern_entry_t;

typedef struct iii_intern_string {
    const uint8_t *bytes;
    size_t len;
} iii_intern_string_t;

typedef struct iii_intern {
    iii_intern_entry_t *slots;
    size_t cap;
    size_t used;
    iii_intern_string_t *strings; /* indexed by id-1 */
    size_t strings_cap;
    size_t strings_count;
    iii_arena_t *arena;           /* not owned */
} iii_intern_t;

void     iii_intern_init(iii_intern_t *t, iii_arena_t *arena);
void     iii_intern_destroy(iii_intern_t *t);
uint32_t iii_intern_put(iii_intern_t *t, const uint8_t *bytes, size_t len);
const uint8_t *iii_intern_get(const iii_intern_t *t, uint32_t id, size_t *out_len);

#ifdef __cplusplus
}
#endif
#endif
