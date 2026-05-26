/* Closure root: architecture-independent canonical hashing.
 * See iii/portability.h for the canonical byte-stream format. */
#include "iii/portability.h"
#include "iii/sha256.h"

#include <stdlib.h>
#include <string.h>

static const char K_PREFIX[] = "III/PORTABILITY/CLOSURE/v1\n";
#define K_PREFIX_LEN (sizeof K_PREFIX - 1)

static void put_be32(uint8_t *p, uint32_t v) {
    p[0] = (uint8_t)(v >> 24); p[1] = (uint8_t)(v >> 16);
    p[2] = (uint8_t)(v >>  8); p[3] = (uint8_t)v;
}
static void put_be64(uint8_t *p, uint64_t v) {
    for (int i = 0; i < 8; ++i) p[i] = (uint8_t)(v >> (56 - 8*i));
}

static int mod_cmp(const void *a, const void *b) {
    const iii_module_t *ma = a, *mb = b;
    return strcmp(ma->name ? ma->name : "", mb->name ? mb->name : "");
}

static iii_module_t *sorted_copy(const iii_module_t *modules, size_t n) {
    if (n == 0) return NULL;
    iii_module_t *c = malloc(n * sizeof(*c));
    if (!c) return NULL;
    memcpy(c, modules, n * sizeof(*c));
    qsort(c, n, sizeof(*c), mod_cmp);
    return c;
}

size_t iii_closure_canonical_serialize(const iii_module_t *modules, size_t n,
                                       uint8_t *buf, size_t cap) {
    /* Compute total length first. */
    size_t need = K_PREFIX_LEN + 4;
    for (size_t i = 0; i < n; ++i) {
        size_t nl = modules[i].name ? strlen(modules[i].name) : 0;
        need += 4 + nl + 8 + modules[i].len;
    }
    if (!buf || cap < need) return need;

    iii_module_t *sorted = sorted_copy(modules, n);
    if (n && !sorted) return 0;

    size_t off = 0;
    memcpy(buf + off, K_PREFIX, K_PREFIX_LEN); off += K_PREFIX_LEN;
    put_be32(buf + off, (uint32_t)n); off += 4;
    for (size_t i = 0; i < n; ++i) {
        const iii_module_t *m = &sorted[i];
        size_t nl = m->name ? strlen(m->name) : 0;
        put_be32(buf + off, (uint32_t)nl); off += 4;
        if (nl) { memcpy(buf + off, m->name, nl); off += nl; }
        put_be64(buf + off, (uint64_t)m->len); off += 8;
        if (m->len) { memcpy(buf + off, m->bytes, m->len); off += m->len; }
    }
    free(sorted);
    return off;
}

int iii_closure_root_compute(const iii_module_t *modules, size_t n,
                             uint8_t out[32]) {
    if (!out) return -1;
    iii_module_t *sorted = sorted_copy(modules, n);
    if (n && !sorted) return -2;

    iii_sha256_ctx_t ctx;
    iii_sha256_init(&ctx);
    iii_sha256_update(&ctx, (const uint8_t *)K_PREFIX, K_PREFIX_LEN);

    uint8_t hdr[8];
    put_be32(hdr, (uint32_t)n);
    iii_sha256_update(&ctx, hdr, 4);

    for (size_t i = 0; i < n; ++i) {
        const iii_module_t *m = &sorted[i];
        size_t nl = m->name ? strlen(m->name) : 0;
        put_be32(hdr, (uint32_t)nl);
        iii_sha256_update(&ctx, hdr, 4);
        if (nl) iii_sha256_update(&ctx, (const uint8_t *)m->name, nl);
        put_be64(hdr, (uint64_t)m->len);
        iii_sha256_update(&ctx, hdr, 8);
        if (m->len) iii_sha256_update(&ctx, m->bytes, m->len);
    }

    iii_sha256_final(&ctx, out);
    free(sorted);
    return 0;
}
