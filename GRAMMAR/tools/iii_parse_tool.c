/* III Grammar CLI driver: lex → parse → dump/hash/errors/tokens. */
#include "iii/ast.h"
#include "iii/ast_print.h"
#include "iii/parser.h"
#include "iii/parse_arena.h"

#include <iii/lex.h>
#include <iii/token.h>
#include <iii/sha256.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <inttypes.h>

static int read_file(const char *path, uint8_t **out, size_t *out_len) {
    *out = NULL; *out_len = 0;
    FILE *f = fopen(path, "rb");
    if (!f) { fprintf(stderr, "cannot open: %s\n", path); return -1; }
    if (fseek(f, 0, SEEK_END) != 0) { fclose(f); return -1; }
    long sz = ftell(f);
    if (sz < 0) { fclose(f); return -1; }
    rewind(f);
    uint8_t *buf = (uint8_t*)malloc((size_t)sz + 1);
    if (!buf) { fclose(f); return -1; }
    size_t n = fread(buf, 1, (size_t)sz, f);
    fclose(f);
    buf[n] = 0;
    *out = buf;
    *out_len = n;
    return 0;
}

typedef struct {
    iii_lex_state_t *lex;
} intern_adapter_t;

static const char *intern_resolver(uint32_t id, size_t *out_len, void *ud) {
    intern_adapter_t *a = (intern_adapter_t*)ud;
    return iii_lex_intern_text(a->lex, id, out_len);
}

static void print_hex32(const uint8_t v[32], FILE *out) {
    static const char H[] = "0123456789abcdef";
    for (int i = 0; i < 32; i++) {
        fputc(H[(v[i] >> 4) & 0xF], out);
        fputc(H[v[i] & 0xF], out);
    }
    fputc('\n', out);
}

static int do_tokens(iii_lex_state_t *lex) {
    iii_token_t t;
    for (;;) {
        int r = iii_lex_next(lex, &t);
        if (r < 0) {
            const iii_lex_error_t *e = iii_lex_last_error(lex);
            if (e) fprintf(stderr, "lex error\n");
            else   fprintf(stderr, "lex error (unknown)\n");
            continue;
        }
        printf("%-18s @%u:%u  off=%u len=%u  id=%u  int=%" PRIu64 "  suf=%u  hex=0x%04x\n",
            iii_token_kind_name(t.kind),
            t.line, t.col,
            t.text_offset, t.text_len,
            t.interned_id,
            t.int_value,
            (unsigned)t.int_suffix,
            (unsigned)t.hexad_packed);
        if (r == 0 || t.kind == IIIK_EOF) break;
    }
    return 0;
}

static void dump_parse_errors(iii_parser_t *p) {
    size_t n = iii_parser_error_count(p);
    for (size_t i = 0; i < n; i++) {
        const iii_parse_error_t *e = iii_parser_error_at(p, i);
        if (!e) continue;
        fprintf(stderr, "parse-error[%zu] code=%d %u:%u span=%u..%u  %s\n",
            i, e->code, e->line, e->col, e->span_start, e->span_end, e->message);
    }
}

static int do_dump(iii_parser_t *p, iii_lex_state_t *lex) {
    iii_ast_node_t *root = iii_parse_module(p);
    dump_parse_errors(p);
    if (!root) {
        fprintf(stderr, "(no AST produced)\n");
        return 0;
    }
    size_t src_len = 0;
    const uint8_t *src = iii_parser_source(p, &src_len);
    intern_adapter_t a = { lex };
    iii_ast_dump(root, src, src_len, intern_resolver, &a, stdout);
    return 0;
}

static int do_hash(iii_parser_t *p) {
    iii_ast_node_t *root = iii_parse_module(p);
    dump_parse_errors(p);
    if (!root) {
        fprintf(stderr, "(no AST produced)\n");
        return 0;
    }
    uint8_t h[32];
    iii_ast_mhash(root, h);
    print_hex32(h, stdout);
    return 0;
}

static int do_errors(iii_parser_t *p) {
    iii_ast_node_t *root = iii_parse_module(p);
    (void)root;
    size_t n = iii_parser_error_count(p);
    printf("error_count=%zu\n", n);
    for (size_t i = 0; i < n; i++) {
        const iii_parse_error_t *e = iii_parser_error_at(p, i);
        if (!e) continue;
        printf("[%zu] code=%d %u:%u span=%u..%u  %s\n",
            i, e->code, e->line, e->col, e->span_start, e->span_end, e->message);
    }
    return 0;
}

static int do_full(iii_parser_t *p, iii_lex_state_t *lex) {
    /* tokens phase requires a separate lex pass; we do it on a fresh
     * lex state created in main, see entry point. */
    (void)lex;
    iii_ast_node_t *root = iii_parse_module(p);
    printf("=== ERRORS ===\n");
    size_t n = iii_parser_error_count(p);
    printf("error_count=%zu\n", n);
    for (size_t i = 0; i < n; i++) {
        const iii_parse_error_t *e = iii_parser_error_at(p, i);
        if (!e) continue;
        printf("[%zu] code=%d %u:%u span=%u..%u  %s\n",
            i, e->code, e->line, e->col, e->span_start, e->span_end, e->message);
    }
    if (!root) {
        printf("(no AST produced)\n");
        return 0;
    }
    printf("=== TREE ===\n");
    size_t src_len = 0;
    const uint8_t *src = iii_parser_source(p, &src_len);
    intern_adapter_t a = { lex };
    iii_ast_dump(root, src, src_len, intern_resolver, &a, stdout);
    printf("=== HASH ===\n");
    uint8_t h[32];
    iii_ast_mhash(root, h);
    print_hex32(h, stdout);
    return 0;
}

static void usage(void) {
    fprintf(stderr,
        "usage: iii_parse_tool <verb> <file.III>\n"
        "  verbs: dump | hash | errors | tokens | full\n");
}

int main(int argc, char **argv) {
    if (argc < 3) { usage(); return 2; }
    const char *verb = argv[1];
    const char *path = argv[2];

    uint8_t *src = NULL;
    size_t   src_len = 0;
    if (read_file(path, &src, &src_len) != 0) return 1;

    int rc = 0;

    if (strcmp(verb, "tokens") == 0) {
        iii_lex_state_t *lex = iii_lex_create(src, src_len, path);
        if (!lex) { fprintf(stderr, "lex create failed\n"); free(src); return 1; }
        rc = do_tokens(lex);
        iii_lex_destroy(lex);
        free(src);
        return rc;
    }

    /* dump / hash / errors / full all need parser. */
    iii_lex_state_t *lex = iii_lex_create(src, src_len, path);
    if (!lex) { fprintf(stderr, "lex create failed\n"); free(src); return 1; }

    iii_arena_t *arena = iii_arena_create();
    if (!arena) {
        fprintf(stderr, "arena create failed\n");
        iii_lex_destroy(lex); free(src); return 1;
    }
    iii_parser_t *p = iii_parser_create(lex, arena);
    if (!p) {
        fprintf(stderr, "parser create failed\n");
        iii_arena_destroy(arena); iii_lex_destroy(lex); free(src); return 1;
    }

    if      (strcmp(verb, "dump")   == 0) rc = do_dump(p, lex);
    else if (strcmp(verb, "hash")   == 0) rc = do_hash(p);
    else if (strcmp(verb, "errors") == 0) rc = do_errors(p);
    else if (strcmp(verb, "full")   == 0) {
        /* tokens part: fresh lex on same source */
        iii_lex_state_t *lex2 = iii_lex_create(src, src_len, path);
        if (lex2) {
            printf("=== TOKENS ===\n");
            do_tokens(lex2);
            iii_lex_destroy(lex2);
        }
        rc = do_full(p, lex);
    }
    else { usage(); rc = 2; }

    iii_parser_destroy(p);
    iii_arena_destroy(arena);
    iii_lex_destroy(lex);
    free(src);
    return rc;
}
