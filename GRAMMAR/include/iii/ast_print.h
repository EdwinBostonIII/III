/* III Grammar — AST printer / canonical serializer / mhash. */
#ifndef III_AST_PRINT_H
#define III_AST_PRINT_H

#include <stdio.h>
#include <stdint.h>
#include <stddef.h>
#include "ast.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef const char *(*iii_intern_resolver_fn)(uint32_t id, size_t *out_len, void *ud);

/* Pretty-print AST tree to FILE*. */
void iii_ast_dump(const iii_ast_node_t *root,
                  const uint8_t *source, size_t source_len,
                  iii_intern_resolver_fn intern_fn,
                  void *intern_ud,
                  FILE *out);

/* Canonical AST serialization to a byte buffer (for hashing).
 * Caller must free *out_buf with free().  Returns 0 on success, -1 on OOM. */
int  iii_ast_canonical(const iii_ast_node_t *root,
                       uint8_t **out_buf, size_t *out_len);

/* Compute the R1.A2-style hash of an AST: SHA-256 of canonical
 * serialization.  Writes 32 bytes to out. */
void iii_ast_mhash(const iii_ast_node_t *root, uint8_t out[32]);

#ifdef __cplusplus
}
#endif
#endif
