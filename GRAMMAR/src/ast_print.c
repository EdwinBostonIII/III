/* III Grammar — pretty-printer for AST trees.
 *
 * Output is a human-friendly indented S-expression form.  Each node
 * prints its kind name, source span, payload (for leaf-bearing kinds),
 * and its children (recursively, +2 indent per level).
 *
 * NIH discipline: only libc.
 */
#include "iii/ast_print.h"
#include "iii/ast.h"

#include <stdio.h>
#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include <ctype.h>
#include <inttypes.h>

static void put_indent(FILE *out, unsigned depth) {
    for (unsigned i = 0; i < depth; i++) fputc(' ', out);
}

static void put_hex_byte(FILE *out, uint8_t b) {
    static const char H[] = "0123456789abcdef";
    fputc(H[(b >> 4) & 0xF], out);
    fputc(H[b & 0xF], out);
}

static void put_quoted_bytes(FILE *out, const uint8_t *p, size_t n) {
    fputc('"', out);
    for (size_t i = 0; i < n; i++) {
        uint8_t c = p[i];
        switch (c) {
            case '"':  fputs("\\\"", out); break;
            case '\\': fputs("\\\\", out); break;
            case '\n': fputs("\\n",  out); break;
            case '\r': fputs("\\r",  out); break;
            case '\t': fputs("\\t",  out); break;
            default:
                if (c >= 0x20 && c < 0x7F) {
                    fputc((char)c, out);
                } else {
                    fputs("\\x", out);
                    put_hex_byte(out, c);
                }
        }
    }
    fputc('"', out);
}

static void put_mhash(FILE *out, const uint8_t v[32]) {
    fputs("0x", out);
    for (int i = 0; i < 32; i++) put_hex_byte(out, v[i]);
}

/* Heuristic: which kinds carry which payloads in their "node-self" line. */
static int kind_has_ident(iii_ast_kind_t k) {
    switch (k) {
        case III_AST_QUALIFIED_NAME:
        case III_AST_MODULE_ATTR:
        case III_AST_IMPORT_ATTR:
        case III_AST_CYCLE_MODIFIER:
        case III_AST_FUNCTION_MODIFIER:
        case III_AST_TYPE_MODIFIER:
        case III_AST_MOBIUS_CANDIDATE_MODIFIER:
        case III_AST_WAVEFRONT_MODIFIER:
        case III_AST_PRIMITIVE_TYPE:
        case III_AST_TIER_NAME:
        case III_AST_HEXAD_DESIGNATOR:
        case III_AST_IDENT_PATTERN:
        case III_AST_RECORD_FIELD:
        case III_AST_RECORD_PATTERN_FIELD:
        case III_AST_NAMED_ARG:
        case III_AST_GENERIC_PARAM:
        case III_AST_PARAM:
        case III_AST_SCHEMA_FIELD:
        case III_AST_NARRATIVE_FIELD:
        case III_AST_PROPOSE_FIELD:
        case III_AST_NEGOTIATE_ARG:
        case III_AST_COMMIT_ARG:
        case III_AST_EXTERN_ITEM:
        case III_AST_PATH:
        case III_AST_PATH_PATTERN:
        case III_AST_FIELD_ACCESS:
        case III_AST_PREFIX_OP:
        case III_AST_INFIX_OP:
            return 1;
        default:
            return 0;
    }
}

static void dump_node(const iii_ast_node_t *n,
                      const uint8_t *source, size_t source_len,
                      iii_intern_resolver_fn intern_fn, void *intern_ud,
                      FILE *out, unsigned depth)
{
    if (!n) {
        put_indent(out, depth);
        fputs("(NULL)\n", out);
        return;
    }

    put_indent(out, depth);
    fputc('(', out);
    fputs(iii_ast_kind_name(n->kind), out);
    fprintf(out, " @%" PRIu32 "..%" PRIu32, n->span_start, n->span_end);

    /* Payload printing. */
    if (n->interned_id != 0 && kind_has_ident(n->kind)) {
        size_t L = 0;
        const char *s = intern_fn ? intern_fn(n->interned_id, &L, intern_ud) : NULL;
        if (s) {
            fputs(" name=", out);
            put_quoted_bytes(out, (const uint8_t*)s, L);
        } else {
            fprintf(out, " name#%" PRIu32, n->interned_id);
        }
    }

    if (n->op_id != 0) {
        fprintf(out, " op=%" PRIu16, n->op_id);
    }

    switch (n->kind) {
        case III_AST_LITERAL:
        case III_AST_LITERAL_PATTERN:
            fprintf(out, " int=%" PRIu64, n->int_value);
            if (n->int_suffix) fprintf(out, " suf=%u", (unsigned)n->int_suffix);
            if (n->hexad_packed) fprintf(out, " hexad=0x%04x", (unsigned)n->hexad_packed);
            /* Detect mhash payload (if any nonzero byte). */
            for (int i = 0; i < 32; i++) {
                if (n->mhash_value[i]) {
                    fputs(" mhash=", out);
                    put_mhash(out, n->mhash_value);
                    break;
                }
            }
            if (n->string_payload && n->string_len) {
                fputs(" str=", out);
                put_quoted_bytes(out, n->string_payload, n->string_len);
            }
            break;
        case III_AST_HEXAD_DESIGNATOR:
        case III_AST_HEXAD_PATTERN:
            fprintf(out, " hexad=0x%04x", (unsigned)n->hexad_packed);
            break;
        case III_AST_TRIT_PATTERN:
            fprintf(out, " trit=%" PRId64, (int64_t)n->int_value);
            break;
        case III_AST_DOC_ATTACHED:
            if (n->string_payload && n->string_len) {
                fputs(" doc=", out);
                put_quoted_bytes(out, n->string_payload, n->string_len);
            }
            break;
        default:
            if (n->string_payload && n->string_len) {
                fputs(" str=", out);
                put_quoted_bytes(out, n->string_payload, n->string_len);
            }
            break;
    }

    if (n->doc_offset != III_AST_NO_DOC) {
        fprintf(out, " doc_offset=%" PRIu32, n->doc_offset);
    }

    if (n->child_count == 0) {
        fputs(")\n", out);
        return;
    }

    fputc('\n', out);
    for (uint32_t i = 0; i < n->child_count; i++) {
        dump_node(n->children[i], source, source_len,
                  intern_fn, intern_ud, out, depth + 2);
    }
    put_indent(out, depth);
    fputs(")\n", out);
}

void iii_ast_dump(const iii_ast_node_t *root,
                  const uint8_t *source, size_t source_len,
                  iii_intern_resolver_fn intern_fn,
                  void *intern_ud,
                  FILE *out)
{
    if (!out) return;
    dump_node(root, source, source_len, intern_fn, intern_ud, out, 0);
}
