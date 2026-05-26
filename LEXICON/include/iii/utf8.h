/* Hand-rolled UTF-8 decoder/validator per RFC 3629. */
#ifndef III_UTF8_H
#define III_UTF8_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Decode one codepoint at p (length len-(p-base)). Returns:
 *   on success: byte width 1..4 written to *out_width, codepoint to *out_cp.
 *   on failure: returns 0 and *out_width=1 (so caller can advance and report).
 * Validates: no overlong, no surrogates, cp <= 0x10FFFF, no truncation.
 */
int iii_utf8_decode(const uint8_t *p, size_t avail, uint32_t *out_cp, int *out_width);

/* Validate entire buffer; returns 0 on ok, -1 on error with *err_offset set. */
int iii_utf8_validate(const uint8_t *p, size_t len, size_t *err_offset);

/* Encode codepoint into buf (>=4 bytes). Returns width (1..4) or 0 on invalid cp. */
int iii_utf8_encode(uint32_t cp, uint8_t *buf);

#ifdef __cplusplus
}
#endif
#endif
