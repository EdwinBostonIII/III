/* Canonicalization per §2.5 + R1 hash. */
#ifndef III_CANONICAL_H
#define III_CANONICAL_H

#include <stdint.h>
#include <stddef.h>
#include "errors.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Canonicalize: validates UTF-8, rejects BOM/CR/trailing-ws/forbidden-control,
 * verifies NFC over identifier chars, lowercases hex inside MHASH_LIT spans,
 * and re-encodes to canonical UTF-8 bytes.  For this implementation the lexer
 * input is already NFC ASCII for identifiers, so canonical bytes ≡ input
 * bytes after the rejection checks (we still copy to obtain ownership).
 *
 * Returns 0 on success: *out_canonical malloc'd, *out_len set.  Caller frees.
 * Returns -1 on error: err_out populated; *out_canonical = NULL.
 */
int iii_canonicalize(const uint8_t *src, size_t len,
                     uint8_t **out_canonical, size_t *out_len,
                     iii_lex_error_t *err_out);

/* Canonicalize then SHA-256.  Returns 0 ok, -1 on canonicalization failure. */
int iii_r1_hash(const uint8_t *src, size_t len, uint8_t out[32],
                iii_lex_error_t *err_out);

#ifdef __cplusplus
}
#endif
#endif
