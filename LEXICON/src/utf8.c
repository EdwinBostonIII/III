#include "iii/utf8.h"

int iii_utf8_decode(const uint8_t *p, size_t avail, uint32_t *out_cp, int *out_width) {
    if (avail == 0) { *out_width = 0; *out_cp = 0; return 0; }
    uint8_t b0 = p[0];
    if (b0 < 0x80) { *out_cp = b0; *out_width = 1; return 1; }
    if ((b0 & 0xE0) == 0xC0) {
        if (avail < 2) { *out_width = 1; return 0; }
        uint8_t b1 = p[1];
        if ((b1 & 0xC0) != 0x80) { *out_width = 1; return 0; }
        uint32_t cp = ((uint32_t)(b0 & 0x1F) << 6) | (b1 & 0x3F);
        if (cp < 0x80) { *out_width = 1; return 0; } /* overlong */
        *out_cp = cp; *out_width = 2; return 1;
    }
    if ((b0 & 0xF0) == 0xE0) {
        if (avail < 3) { *out_width = 1; return 0; }
        uint8_t b1 = p[1], b2 = p[2];
        if ((b1 & 0xC0) != 0x80 || (b2 & 0xC0) != 0x80) { *out_width = 1; return 0; }
        uint32_t cp = ((uint32_t)(b0 & 0x0F) << 12) | ((uint32_t)(b1 & 0x3F) << 6) | (b2 & 0x3F);
        if (cp < 0x800) { *out_width = 1; return 0; }
        if (cp >= 0xD800 && cp <= 0xDFFF) { *out_width = 1; return 0; } /* surrogate */
        *out_cp = cp; *out_width = 3; return 1;
    }
    if ((b0 & 0xF8) == 0xF0) {
        if (avail < 4) { *out_width = 1; return 0; }
        uint8_t b1 = p[1], b2 = p[2], b3 = p[3];
        if ((b1 & 0xC0) != 0x80 || (b2 & 0xC0) != 0x80 || (b3 & 0xC0) != 0x80) { *out_width = 1; return 0; }
        uint32_t cp = ((uint32_t)(b0 & 0x07) << 18) | ((uint32_t)(b1 & 0x3F) << 12)
                    | ((uint32_t)(b2 & 0x3F) << 6) | (b3 & 0x3F);
        if (cp < 0x10000 || cp > 0x10FFFF) { *out_width = 1; return 0; }
        *out_cp = cp; *out_width = 4; return 1;
    }
    *out_width = 1;
    return 0;
}

int iii_utf8_validate(const uint8_t *p, size_t len, size_t *err_offset) {
    size_t i = 0;
    while (i < len) {
        uint32_t cp; int w;
        if (!iii_utf8_decode(p + i, len - i, &cp, &w)) {
            if (err_offset) *err_offset = i;
            return -1;
        }
        i += (size_t)w;
    }
    return 0;
}

int iii_utf8_encode(uint32_t cp, uint8_t *buf) {
    if (cp < 0x80) { buf[0] = (uint8_t)cp; return 1; }
    if (cp < 0x800) {
        buf[0] = (uint8_t)(0xC0 | (cp >> 6));
        buf[1] = (uint8_t)(0x80 | (cp & 0x3F));
        return 2;
    }
    if (cp < 0x10000) {
        if (cp >= 0xD800 && cp <= 0xDFFF) return 0;
        buf[0] = (uint8_t)(0xE0 | (cp >> 12));
        buf[1] = (uint8_t)(0x80 | ((cp >> 6) & 0x3F));
        buf[2] = (uint8_t)(0x80 | (cp & 0x3F));
        return 3;
    }
    if (cp <= 0x10FFFF) {
        buf[0] = (uint8_t)(0xF0 | (cp >> 18));
        buf[1] = (uint8_t)(0x80 | ((cp >> 12) & 0x3F));
        buf[2] = (uint8_t)(0x80 | ((cp >> 6) & 0x3F));
        buf[3] = (uint8_t)(0x80 | (cp & 0x3F));
        return 4;
    }
    return 0;
}
