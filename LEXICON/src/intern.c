#include "iii/intern.h"
#include "iii/fnv1a.h"
#include <stdlib.h>
#include <string.h>

#define INIT_CAP 4096u

static void grow(iii_intern_t *t) {
    size_t newcap = t->cap * 2;
    iii_intern_entry_t *ns = (iii_intern_entry_t *)calloc(newcap, sizeof(*ns));
    if (!ns) return;
    for (size_t i = 0; i < t->cap; i++) {
        if (t->slots[i].id == 0) continue;
        uint32_t h = t->slots[i].hash;
        size_t mask = newcap - 1;
        size_t idx = h & mask;
        while (ns[idx].id != 0) idx = (idx + 1) & mask;
        ns[idx] = t->slots[i];
    }
    free(t->slots);
    t->slots = ns; t->cap = newcap;
}

void iii_intern_init(iii_intern_t *t, iii_arena_t *arena) {
    t->cap = INIT_CAP;
    t->slots = (iii_intern_entry_t *)calloc(t->cap, sizeof(*t->slots));
    t->used = 0;
    t->strings_cap = 256;
    t->strings = (iii_intern_string_t *)calloc(t->strings_cap, sizeof(*t->strings));
    t->strings_count = 0;
    t->arena = arena;
}

void iii_intern_destroy(iii_intern_t *t) {
    free(t->slots); t->slots = NULL;
    free(t->strings); t->strings = NULL;
    t->cap = 0; t->used = 0; t->strings_cap = 0; t->strings_count = 0;
}

uint32_t iii_intern_put(iii_intern_t *t, const uint8_t *bytes, size_t len) {
    if (!bytes) return 0;   /* a NULL payload (arena OOM at the caller) interns as id 0, never deref'd */
    if (t->used * 4 >= t->cap * 3) grow(t);
    uint32_t h = iii_fnv1a32(bytes, len);
    if (h == 0) h = 1;
    size_t mask = t->cap - 1;
    size_t idx = h & mask;
    while (t->slots[idx].id != 0) {
        if (t->slots[idx].hash == h) {
            iii_intern_string_t *s = &t->strings[t->slots[idx].id - 1];
            if (s->len == len && memcmp(s->bytes, bytes, len) == 0)
                return t->slots[idx].id;
        }
        idx = (idx + 1) & mask;
    }
    if (t->strings_count >= t->strings_cap) {
        size_t nc = t->strings_cap * 2;
        iii_intern_string_t *ns = (iii_intern_string_t *)realloc(t->strings, nc * sizeof(*ns));
        if (!ns) return 0;
        t->strings = ns; t->strings_cap = nc;
    }
    uint8_t *copy = iii_arena_dup(t->arena, bytes, len);
    if (!copy) return 0;   /* arena OOM: fail the intern (id 0) rather than store a NULL bytes
                            * pointer that a later memcmp would dereference -- the load-exposed
                            * segfault root cause; mirrors the strings-realloc OOM path above. */
    uint32_t id = (uint32_t)(t->strings_count + 1);
    t->strings[t->strings_count].bytes = copy;
    t->strings[t->strings_count].len = len;
    t->strings_count++;
    t->slots[idx].hash = h;
    t->slots[idx].id = id;
    t->used++;
    return id;
}

const uint8_t *iii_intern_get(const iii_intern_t *t, uint32_t id, size_t *out_len) {
    if (id == 0 || id > t->strings_count) { if (out_len) *out_len = 0; return NULL; }
    if (out_len) *out_len = t->strings[id-1].len;
    return t->strings[id-1].bytes;
}
