#include "test.h"

void run_test_comments(void) {
    iiit_run_t r;
    {
        IIIT_BEGIN("// line comment is silent");
        iiit_run("a // comment\nb", &r);
        IIIT_ASSERT(r.n == 2 && r.toks[0].kind == IIIK_IDENT && r.toks[1].kind == IIIK_IDENT,
                    "got n=%zu", r.n);
        IIIT_OK();
    }
    {
        IIIT_BEGIN("/* block */ silent");
        iiit_run("a /* ignored */ b", &r);
        IIIT_ASSERT(r.n == 2, "got n=%zu", r.n);
        IIIT_OK();
    }
    {
        IIIT_BEGIN("nested block comments");
        iiit_run("a /* outer /* inner */ still */ b", &r);
        IIIT_ASSERT(r.n == 2, "got n=%zu", r.n);
        IIIT_OK();
    }
    {
        IIIT_BEGIN("/// doc comment emitted");
        iiit_run("/// docs\nfn", &r);
        IIIT_ASSERT(r.n == 2 && r.toks[0].kind == IIIK_DOC_COMMENT, "n=%zu", r.n);
        IIIT_OK();
    }
    {
        IIIT_BEGIN("/** doc block */ emitted");
        iiit_run("/** doc */ x", &r);
        IIIT_ASSERT(r.n == 2 && r.toks[0].kind == IIIK_DOC_COMMENT, "n=%zu", r.n);
        IIIT_OK();
    }
    {
        IIIT_BEGIN("unterminated block comment errors");
        iiit_run("/* no end", &r);
        IIIT_ASSERT(r.errs >= 1, "expected error");
        IIIT_OK();
    }
}
