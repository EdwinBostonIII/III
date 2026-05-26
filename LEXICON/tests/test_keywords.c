#include "test.h"

/* Check that every keyword and modifier is recognized. */

extern size_t iii_lex_keyword_count(void);
extern const char *iii_lex_keyword_at(size_t i, size_t *out_len);
extern size_t iii_lex_modifier_count(void);
extern const char *iii_lex_modifier_at(size_t i, size_t *out_len, int *out_id);

void run_test_keywords(void) {
    {
        IIIT_BEGIN("all 47 keywords lex as KEYWORD");
        size_t kc = iii_lex_keyword_count();
        IIIT_ASSERT(kc == 47, "expected 47 keywords got %zu", kc);
        for (size_t i = 0; i < kc; i++) {
            size_t L; const char *kw = iii_lex_keyword_at(i, &L);
            char buf[64]; memcpy(buf, kw, L); buf[L] = 0;
            iiit_run_t r; iiit_run(buf, &r);
            if (r.n != 1 || r.toks[0].kind != IIIK_KEYWORD) {
                IIIT_FAIL("keyword '%s' not recognized: n=%zu kind=%s",
                          buf, r.n, r.n ? iii_token_kind_name(r.toks[0].kind) : "(none)");
            }
            if (r.errs != 0) IIIT_FAIL("keyword '%s' produced errors", buf);
        }
        IIIT_OK();
    }
    {
        IIIT_BEGIN("möbius requires precomposed ö");
        iiit_run_t r;
        iiit_run("mobius", &r);
        IIIT_ASSERT(r.n == 1 && r.toks[0].kind == IIIK_IDENT, "ASCII 'mobius' must be IDENT");
        iiit_run("moebius", &r);
        IIIT_ASSERT(r.n == 1 && r.toks[0].kind == IIIK_IDENT, "ASCII 'moebius' must be IDENT");
        iiit_run("m\xC3\xB6" "bius", &r);
        IIIT_ASSERT(r.n == 1 && r.toks[0].kind == IIIK_KEYWORD, "möbius (precomposed) must be KEYWORD");
        IIIT_OK();
    }
    {
        IIIT_BEGIN("all 19 modifiers + @safety");
        size_t mc = iii_lex_modifier_count();
        IIIT_ASSERT(mc == 20, "expected 20 modifier surface forms got %zu", mc);
        for (size_t i = 0; i < mc; i++) {
            size_t L; int id; const char *m = iii_lex_modifier_at(i, &L, &id);
            char buf[64]; memcpy(buf, m, L); buf[L] = 0;
            iiit_run_t r; iiit_run(buf, &r);
            if (r.n != 1 || r.toks[0].kind != IIIK_MODIFIER) {
                IIIT_FAIL("modifier '%s' not recognized", buf);
            }
            if (r.errs != 0) IIIT_FAIL("modifier '%s' produced errors", buf);
            if ((int)r.toks[0].int_value != id) {
                IIIT_FAIL("modifier '%s' got id %d expected %d", buf, (int)r.toks[0].int_value, id);
            }
        }
        IIIT_OK();
    }
    {
        IIIT_BEGIN("@safety synonym maps to @hexad id");
        iiit_run_t a, b;
        iiit_run("@safety", &a);
        iiit_run("@hexad", &b);
        IIIT_ASSERT(a.toks[0].int_value == b.toks[0].int_value, "ids differ");
        IIIT_OK();
    }
    {
        IIIT_BEGIN("mobius_candidate vs mobius_candidate_2");
        iiit_run_t r;
        iiit_run("mobius_candidate", &r);
        IIIT_ASSERT(r.n == 1 && r.toks[0].kind == IIIK_KEYWORD, "should be KEYWORD");
        iiit_run("mobius_candidate_2", &r);
        IIIT_ASSERT(r.n == 1 && r.toks[0].kind == IIIK_IDENT, "should be IDENT");
        IIIT_OK();
    }
}
