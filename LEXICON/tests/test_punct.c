#include "test.h"

void run_test_punct(void) {
    iiit_run_t r;
    {
        IIIT_BEGIN("all single + multi punctuators");
        const char *cases[] = {
            "(",")","{","}","[","]","<",">",",",";",":","::",".","..","=","==","!=",
            "->","=>","|","_","?","&","\xE2\x89\xA4","\xE2\x89\xA5", NULL
        };
        for (int i = 0; cases[i]; i++) {
            iiit_run(cases[i], &r);
            IIIT_ASSERT(r.n == 1 && r.toks[0].kind == IIIK_PUNCT,
                        "punct '%s' n=%zu kind=%s", cases[i], r.n,
                        r.n ? iii_token_kind_name(r.toks[0].kind) : "(none)");
        }
        IIIT_OK();
    }
    {
        IIIT_BEGIN("$ raises LEX-PUNCT-001");
        iiit_run("$", &r);
        IIIT_ASSERT(r.errs >= 1, "expected error");
        IIIT_OK();
    }
    {
        IIIT_BEGIN("^ ~ ' ` raise LEX-PUNCT-002");
        const char *cases[] = {"^","~","'","`",NULL};
        for (int i = 0; cases[i]; i++) {
            iiit_run(cases[i], &r);
            IIIT_ASSERT(r.errs >= 1, "case '%s' should have error", cases[i]);
        }
        IIIT_OK();
    }
}
