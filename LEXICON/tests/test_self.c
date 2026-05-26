#include "test.h"
#include "iii/canonical.h"
#include "iii/sha256.h"

#include <stdio.h>
#include <stdlib.h>

#ifndef LEXICON_PATH
#define LEXICON_PATH "C:\\Users\\Edwin Boston\\OneDrive\\Desktop\\III\\DOCS\\III-LEXICON.md"
#endif

static int read_all(const char *p, uint8_t **out, size_t *outlen) {
    FILE *f = fopen(p, "rb"); if (!f) return -1;
    fseek(f, 0, SEEK_END); long n = ftell(f); fseek(f, 0, SEEK_SET);
    uint8_t *b = (uint8_t *)malloc((size_t)n + 1);
    if (!b) { fclose(f); return -1; }
    fread(b, 1, (size_t)n, f); b[n] = 0;
    fclose(f);
    *out = b; *outlen = (size_t)n;
    return 0;
}

void run_test_self(void) {
    {
        IIIT_BEGIN("canonicalize III-LEXICON.md");
        uint8_t *src = NULL; size_t len = 0;
        if (read_all(LEXICON_PATH, &src, &len) != 0) { IIIT_FAIL("could not read %s", LEXICON_PATH); }
        iii_lex_error_t e; uint8_t *canon; size_t clen;
        int rc = iii_canonicalize(src, len, &canon, &clen, &e);
        IIIT_ASSERT(rc == 0, "canonicalize failed: %s @ +%u: %s",
                    iii_lex_error_code_name(e.code), e.byte_offset, e.message);
        free(canon); free(src);
        IIIT_OK();
    }
    {
        IIIT_BEGIN("R1.A1 hash printed");
        uint8_t *src = NULL; size_t len = 0;
        if (read_all(LEXICON_PATH, &src, &len) != 0) { IIIT_FAIL("could not read"); }
        uint8_t h[32]; iii_lex_error_t e;
        int rc = iii_r1_hash(src, len, h, &e);
        IIIT_ASSERT(rc == 0, "hash failed");
        char hex[65]; iii_sha256_hex(h, hex);
        printf("\n    R1.A1 = 0x%s\n  ", hex);
        free(src);
        IIIT_OK();
    }
    {
        IIIT_BEGIN("lex III-LEXICON.md (markdown — many errors expected)");
        uint8_t *src = NULL; size_t len = 0;
        if (read_all(LEXICON_PATH, &src, &len) != 0) { IIIT_FAIL("could not read"); }
        iii_lex_state_t *st = iii_lex_create(src, len, LEXICON_PATH);
        iii_token_t t;
        size_t n = 0;
        while (iii_lex_next(st, &t) != 0) {
            n++;
            if (n > 5000000) break; /* safety */
        }
        size_t errn = iii_lex_error_count(st);
        printf("\n    tokens=%zu errors=%zu (errors are EXPECTED — file is markdown, not III source)\n  ",
               n, errn);
        iii_lex_destroy(st);
        free(src);
        IIIT_ASSERT(n > 0, "must produce some tokens");
        IIIT_OK();
    }
}
