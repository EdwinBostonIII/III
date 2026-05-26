/* III LEGACY-INGESTION — internal helpers (NIH). */
#ifndef III_LEGACY_INTERNAL_H
#define III_LEGACY_INTERNAL_H

#include <stdint.h>
#include <stddef.h>
#include <string.h>

/* Bounded LE readers (no UB on misalignment). Always write *out (zero on truncate). */
static inline int iii_le_read_u8(const uint8_t *b, size_t n, size_t off, uint8_t *out) {
    *out = 0;
    if (off + 1 > n) return 0;
    *out = b[off];
    return 1;
}
static inline int iii_le_read_u16(const uint8_t *b, size_t n, size_t off, uint16_t *out) {
    *out = 0;
    if (off + 2 > n) return 0;
    *out = (uint16_t)b[off] | ((uint16_t)b[off+1] << 8);
    return 1;
}
static inline int iii_le_read_u32(const uint8_t *b, size_t n, size_t off, uint32_t *out) {
    *out = 0;
    if (off + 4 > n) return 0;
    *out = (uint32_t)b[off] | ((uint32_t)b[off+1] << 8) |
           ((uint32_t)b[off+2] << 16) | ((uint32_t)b[off+3] << 24);
    return 1;
}
static inline int iii_le_read_u64(const uint8_t *b, size_t n, size_t off, uint64_t *out) {
    *out = 0;
    if (off + 8 > n) return 0;
    uint32_t lo = 0, hi = 0;
    iii_le_read_u32(b, n, off, &lo);
    iii_le_read_u32(b, n, off + 4, &hi);
    *out = (uint64_t)lo | ((uint64_t)hi << 32);
    return 1;
}
static inline int iii_be_read_u32(const uint8_t *b, size_t n, size_t off, uint32_t *out) {
    *out = 0;
    if (off + 4 > n) return 0;
    *out = ((uint32_t)b[off] << 24) | ((uint32_t)b[off+1] << 16) |
           ((uint32_t)b[off+2] << 8) | (uint32_t)b[off+3];
    return 1;
}

/* Copy <=cap-1 bytes from a NUL-terminated string in [b, n) at off. Always NUL-terminates. */
static inline void iii_copy_cstr(char *dst, size_t cap, const uint8_t *b, size_t n, size_t off) {
    size_t i = 0;
    if (cap == 0) return;
    while (off + i < n && i + 1 < cap && b[off + i] != 0) { dst[i] = (char)b[off + i]; i++; }
    dst[i] = 0;
}
/* Copy fixed-length name (may not be NUL-terminated). */
static inline void iii_copy_fixed(char *dst, size_t cap, const char *src, size_t srclen) {
    size_t i, m = (srclen < cap - 1) ? srclen : (cap - 1);
    for (i = 0; i < m && src[i] != 0; i++) dst[i] = src[i];
    dst[i] = 0;
}

#endif
