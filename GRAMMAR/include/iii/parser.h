/* III Grammar — public parser API. */
#ifndef III_PARSER_H
#define III_PARSER_H

#include <stdint.h>
#include <stddef.h>
#include "ast.h"
#include "parse_arena.h"
#include <iii/lex.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct iii_parser iii_parser_t;

/* Parser diagnostic codes (P-*).  Stable. */
enum iii_parse_error_code {
    P_OK                       = 0,
    P_E_UNEXPECTED_TOKEN       = 1,
    P_E_EXPECTED_KEYWORD       = 2,
    P_E_EXPECTED_PUNCT         = 3,
    P_E_EXPECTED_OPERATOR      = 4,
    P_E_EXPECTED_IDENT         = 5,
    P_E_EXPECTED_TYPE          = 6,
    P_E_EXPECTED_EXPR          = 7,
    P_E_EXPECTED_PATTERN       = 8,
    P_E_BAD_MODIFIER_ARG       = 9,
    P_E_DUP_MODIFIER           = 10,
    P_E_LEX_ERROR              = 11,
    P_E_UNEXPECTED_EOF         = 12,
    P_E_HEXAD_OUT_OF_RANGE     = 13,
    P_E_OVERFLOW               = 14,
    P_E_OOM                    = 15
};

typedef struct iii_parse_error {
    int      code;            /* P-* codes; 0 = none */
    char     message[256];
    uint32_t span_start, span_end;
    uint32_t line, col;
} iii_parse_error_t;

iii_parser_t   *iii_parser_create(iii_lex_state_t *lex, iii_arena_t *arena);
void            iii_parser_destroy(iii_parser_t *p);

/* Parse a complete module.  Returns the root MODULE node, or NULL on
 * fatal error (out-of-memory or unrecoverable lex failure).  Recoverable
 * parse errors are reported via the error log; the returned tree may
 * contain III_AST_ERROR / III_AST_RECOVERY nodes. */
iii_ast_node_t *iii_parse_module(iii_parser_t *p);

size_t                   iii_parser_error_count(const iii_parser_t *p);
const iii_parse_error_t *iii_parser_error_at(const iii_parser_t *p, size_t i);

/* Source-byte access (passed through to lex state) for printers. */
const uint8_t *iii_parser_source(const iii_parser_t *p, size_t *out_len);

/* Resolve an interned id back to its byte representation.  The returned
 * pointer is owned by the lex state and is valid for its lifetime. */
const char    *iii_parser_intern(const iii_parser_t *p, uint32_t id, size_t *out_len);

#ifdef __cplusplus
}
#endif
#endif
