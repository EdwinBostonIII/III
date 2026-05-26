/* iii_lex_tool: tokenize a file, print stream + R1.A1 hash. */
#include "iii/lex.h"
#include "iii/canonical.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int read_file(const char *path, uint8_t **out, size_t *outlen) {
    FILE *f = fopen(path, "rb");
    if (!f) { perror(path); return -1; }
    fseek(f, 0, SEEK_END);
    long n = ftell(f);
    fseek(f, 0, SEEK_SET);
    uint8_t *b = (uint8_t *)malloc((size_t)n + 1);
    if (!b) { fclose(f); return -1; }
    size_t r = fread(b, 1, (size_t)n, f);
    fclose(f);
    if (r != (size_t)n) { free(b); return -1; }
    b[n] = 0;
    *out = b; *outlen = (size_t)n;
    return 0;
}

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "usage: %s <file.III> [--quiet]\n", argv[0]);
        return 2;
    }
    int quiet = (argc >= 3 && strcmp(argv[2], "--quiet") == 0);
    uint8_t *src = NULL; size_t len = 0;
    if (read_file(argv[1], &src, &len) != 0) return 1;

    /* R1 hash */
    iii_lex_error_t cerr;
    uint8_t r1[32];
    int rc = iii_r1_hash(src, len, r1, &cerr);
    if (rc != 0) {
        fprintf(stderr, "canonicalization failed: %s @ byte %u (%s)\n",
                iii_lex_error_code_name(cerr.code), cerr.byte_offset, cerr.message);
        free(src);
        return 3;
    }
    char hex[65]; iii_sha256_hex(r1, hex);

    /* Lex */
    iii_lex_state_t *st = iii_lex_create(src, len, argv[1]);
    iii_token_t tok;
    size_t tcount = 0;
    int r;
    while ((r = iii_lex_next(st, &tok)) != 0) {
        if (r < 0) continue; /* error already recorded; recover and continue */
        tcount++;
        if (!quiet) {
            printf("[L%u:C%u +%u] %-16s len=%u id=%u",
                   tok.line, tok.col, tok.text_offset,
                   iii_token_kind_name(tok.kind), tok.text_len, tok.interned_id);
            if (tok.kind == IIIK_INT_LIT) printf(" int=%llu suf=%s",
                                                 (unsigned long long)tok.int_value,
                                                 iii_int_suffix_name((iii_int_suffix_t)tok.int_suffix));
            if (tok.kind == IIIK_TRIT_LIT) printf(" trit=%lld", (long long)(int64_t)tok.int_value);
            if (tok.kind == IIIK_HEXAD_LIT) printf(" hexad=0x%04X", tok.hexad_packed);
            if (tok.kind == IIIK_Q14_LIT)  printf(" q14=%llu", (unsigned long long)tok.int_value);
            if (tok.kind == IIIK_MHASH_LIT) {
                char hh[65]; iii_sha256_hex(tok.mhash_value, hh);
                printf(" mhash=0x%s", hh);
            }
            if (tok.kind == IIIK_OPERATOR) printf(" op_id=%llu", (unsigned long long)tok.int_value);
            if (tok.kind == IIIK_MODIFIER) printf(" mod_id=%llu", (unsigned long long)tok.int_value);
            putchar('\n');
        }
    }
    size_t errn = iii_lex_error_count(st);
    fprintf(stdout, "\n# tokens=%zu  errors=%zu  bytes=%zu\n", tcount, errn, len);
    fprintf(stdout, "R1.A1 = 0x%s\n", hex);
    if (errn) {
        for (size_t i = 0; i < errn && i < 20; i++) {
            const iii_lex_error_t *e = iii_lex_error_at(st, i);
            fprintf(stderr, "  %s @L%u:C%u +%u: %s\n",
                    iii_lex_error_code_name(e->code), e->line, e->col, e->byte_offset, e->message);
        }
        if (errn > 20) fprintf(stderr, "  ... and %zu more errors\n", errn - 20);
    }
    iii_lex_destroy(st);
    free(src);
    return 0;
}
