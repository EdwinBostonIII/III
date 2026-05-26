/* Internal cross-translation-unit declarations for lexer tables. */
#ifndef III_LEX_INTERNAL_H
#define III_LEX_INTERNAL_H

#include <stdint.h>
#include <stddef.h>

/* keywords.c */
int iii_lex_is_keyword(const uint8_t *s, size_t len);
size_t iii_lex_keyword_count(void);
const char *iii_lex_keyword_at(size_t i, size_t *out_len);
int iii_lex_is_reserved_slot(const uint8_t *s, size_t len);

/* modifiers.c */
int iii_lex_modifier_id(const uint8_t *s, size_t len);
size_t iii_lex_modifier_count(void);
const char *iii_lex_modifier_at(size_t i, size_t *out_len, int *out_id);

/* operators.c */
int iii_lex_operator_single(uint32_t cp);
int iii_lex_operator_double(uint32_t cp1, uint32_t cp2);
size_t iii_lex_operator_count(void);
int iii_lex_operator_at(size_t i, uint32_t *out_cp1, uint32_t *out_cp2);

/* punctuators.c */
int iii_lex_is_punct_start(uint32_t cp);
const char *iii_lex_punct_name_cp(uint32_t cp);
int iii_lex_is_reserved_dollar(uint32_t cp);
int iii_lex_is_reserved_pending(uint32_t cp);

#endif
