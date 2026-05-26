/* III Lexicon — public API. */
#ifndef III_LEX_H
#define III_LEX_H

#include <stdint.h>
#include <stddef.h>
#include "token.h"
#include "errors.h"
#include "canonical.h"
#include "sha256.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct iii_lex_state iii_lex_state_t;

/* Construct.  Borrows src for the lifetime of the state. */
iii_lex_state_t *iii_lex_create(const uint8_t *src, size_t len, const char *path);
void             iii_lex_destroy(iii_lex_state_t *st);

/* Pump: 1=token produced, 0=EOF (out->kind == IIIK_EOF), -1=error (recoverable, see error_count). */
int iii_lex_next(iii_lex_state_t *st, iii_token_t *out);
int iii_lex_peek(iii_lex_state_t *st, iii_token_t *out);

const iii_lex_error_t *iii_lex_last_error(const iii_lex_state_t *st);
size_t                 iii_lex_error_count(const iii_lex_state_t *st);
const iii_lex_error_t *iii_lex_error_at(const iii_lex_state_t *st, size_t i);

const char *iii_lex_intern_text(const iii_lex_state_t *st, uint32_t id, size_t *out_len);

/* Intern an arbitrary text into the lex state's intern table.  Returns the
 * interned id (creating it if absent).  Used by clients (e.g. the parser)
 * that need stable ids for keyword/modifier/operator/punctuator strings
 * without having to first feed them through the lexer.  Returns 0 only on
 * allocation failure. */
uint32_t iii_lex_intern(iii_lex_state_t *st, const char *text, size_t len);

/* Convenience: SHA-256 (re-exported for the tool). */
void iii_sha256_hex(const uint8_t in[32], char out[65]);

#ifdef __cplusplus
}
#endif
#endif
