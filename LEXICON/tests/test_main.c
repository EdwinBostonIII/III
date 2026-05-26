#include "test.h"

int iiit_pass = 0, iiit_fail = 0;
const char *iiit_current = "";

void iiit_run(const char *src, iiit_run_t *out) {
    out->n = 0; out->errs = 0;
    size_t len = strlen(src);
    iii_lex_state_t *st = iii_lex_create((const uint8_t *)src, len, "<test>");
    iii_token_t t;
    int r;
    while ((r = iii_lex_next(st, &t)) != 0) {
        if (r > 0 && out->n < (sizeof(out->toks)/sizeof(out->toks[0]))) {
            out->toks[out->n++] = t;
        }
    }
    out->errs = iii_lex_error_count(st);
    iii_lex_destroy(st);
}

int main(void) {
    printf("=== III Lexicon Test Suite ===\n");
    printf("[group] sha256\n");        run_test_sha256();
    printf("[group] utf8\n");          run_test_utf8();
    printf("[group] keywords\n");      run_test_keywords();
    printf("[group] literals\n");      run_test_literals();
    printf("[group] strings\n");       run_test_strings();
    printf("[group] operators\n");     run_test_operators();
    printf("[group] punct\n");         run_test_punct();
    printf("[group] comments\n");      run_test_comments();
    printf("[group] errors\n");        run_test_errors();
    printf("[group] canonical\n");     run_test_canonical();
    printf("[group] self\n");          run_test_self();
    printf("\n=== %d passed, %d failed ===\n", iiit_pass, iiit_fail);
    return iiit_fail == 0 ? 0 : 1;
}
