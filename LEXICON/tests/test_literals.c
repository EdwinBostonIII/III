#include "test.h"

void run_test_literals(void) {
    iiit_run_t r;
    {
        IIIT_BEGIN("decimal int");
        iiit_run("42", &r);
        IIIT_ASSERT(r.n == 1 && r.toks[0].kind == IIIK_INT_LIT && r.toks[0].int_value == 42, "");
        IIIT_OK();
    }
    {
        IIIT_BEGIN("hex int");
        iiit_run("0x7a3f", &r);
        IIIT_ASSERT(r.n == 1 && r.toks[0].kind == IIIK_INT_LIT && r.toks[0].int_value == 0x7a3f, "");
        IIIT_OK();
    }
    {
        IIIT_BEGIN("binary / octal");
        iiit_run("0b1010", &r);
        IIIT_ASSERT(r.n == 1 && r.toks[0].kind == IIIK_INT_LIT && r.toks[0].int_value == 10, "");
        iiit_run("0o755", &r);
        IIIT_ASSERT(r.n == 1 && r.toks[0].kind == IIIK_INT_LIT && r.toks[0].int_value == 0755u, "");
        IIIT_OK();
    }
    {
        IIIT_BEGIN("underscore separators");
        iiit_run("1_000_000", &r);
        IIIT_ASSERT(r.n == 1 && r.toks[0].int_value == 1000000, "");
        IIIT_OK();
    }
    {
        IIIT_BEGIN("all integer suffixes");
        const char *cases[] = {
            "1u8","1u16","1u32","1u64","1i8","1i16","1i32","1i64", NULL
        };
        const iii_int_suffix_t suf[] = {
            IIIS_U8,IIIS_U16,IIIS_U32,IIIS_U64,IIIS_I8,IIIS_I16,IIIS_I32,IIIS_I64
        };
        for (int i = 0; cases[i]; i++) {
            iiit_run(cases[i], &r);
            IIIT_ASSERT(r.n == 1 && r.toks[0].kind == IIIK_INT_LIT && r.toks[0].int_suffix == suf[i],
                        "case '%s' kind=%s suf=%u", cases[i],
                        iii_token_kind_name(r.toks[0].kind), r.toks[0].int_suffix);
        }
        IIIT_OK();
    }
    {
        IIIT_BEGIN("MHASH literal (64 hex digits)");
        const char *m = "0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
        iiit_run(m, &r);
        IIIT_ASSERT(r.n == 1 && r.toks[0].kind == IIIK_MHASH_LIT, "got kind %s n=%zu",
                    r.n ? iii_token_kind_name(r.toks[0].kind) : "(none)", r.n);
        IIIT_ASSERT(r.toks[0].mhash_value[0] == 0x01 && r.toks[0].mhash_value[31] == 0xef, "mhash bytes wrong");
        IIIT_OK();
    }
    {
        IIIT_BEGIN("63 hex digits is INT_LIT");
        const char *m = "0x123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
        iiit_run(m, &r);
        /* 63 digits — won't fit in u64 but still INT_LIT (with overflow error). */
        IIIT_ASSERT(r.n == 1 && r.toks[0].kind == IIIK_INT_LIT, "kind=%s",
                    r.n ? iii_token_kind_name(r.toks[0].kind) : "(none)");
        IIIT_OK();
    }
    {
        IIIT_BEGIN("trit literal forms");
        const char *cases[] = {
            "NEG","ZERO","POS","-1t","0t","+1t","0tn","0tz","0tp", NULL
        };
        const long expected[] = { -1, 0, 1, -1, 0, 1, -1, 0, 1 };
        for (int i = 0; cases[i]; i++) {
            iiit_run(cases[i], &r);
            IIIT_ASSERT(r.n == 1 && r.toks[0].kind == IIIK_TRIT_LIT,
                        "case '%s' got n=%zu kind=%s", cases[i], r.n,
                        r.n ? iii_token_kind_name(r.toks[0].kind) : "(none)");
            IIIT_ASSERT((long)(int64_t)r.toks[0].int_value == expected[i],
                        "case '%s' got %ld expected %ld", cases[i], (long)(int64_t)r.toks[0].int_value, expected[i]);
        }
        IIIT_OK();
    }
    {
        IIIT_BEGIN("hexad literal lookahead");
        iiit_run("(POS, ZERO, POS, ZERO, ZERO, ZERO)", &r);
        IIIT_ASSERT(r.n == 1 && r.toks[0].kind == IIIK_HEXAD_LIT, "got n=%zu kind=%s", r.n,
                    r.n ? iii_token_kind_name(r.toks[0].kind) : "(none)");
        uint16_t expected = (1+2) | ((0+2)<<2) | ((1+2)<<4) | ((0+2)<<6) | ((0+2)<<8) | ((0+2)<<10);
        IIIT_ASSERT(r.toks[0].hexad_packed == expected, "packed got %u expected %u",
                    r.toks[0].hexad_packed, expected);
        IIIT_OK();
    }
    {
        IIIT_BEGIN("hexad lookahead failure leaves '(' PUNCT");
        iiit_run("(1, 2, 3)", &r);
        IIIT_ASSERT(r.n >= 2 && r.toks[0].kind == IIIK_PUNCT, "first must be (, got %s", iii_token_kind_name(r.toks[0].kind));
        IIIT_ASSERT(r.toks[1].kind == IIIK_INT_LIT, "second must be INT_LIT");
        IIIT_OK();
    }
    {
        IIIT_BEGIN("Q14 literal forms");
        iiit_run("0.92q", &r);
        IIIT_ASSERT(r.n == 1 && r.toks[0].kind == IIIK_Q14_LIT && r.toks[0].int_value == 15073,
                    "0.92q got %llu", (unsigned long long)r.toks[0].int_value);
        iiit_run("15073/16384q", &r);
        IIIT_ASSERT(r.n == 1 && r.toks[0].kind == IIIK_Q14_LIT && r.toks[0].int_value == 15073, "ratio form");
        iiit_run("1q", &r);
        IIIT_ASSERT(r.n == 1 && r.toks[0].kind == IIIK_Q14_LIT && r.toks[0].int_value == 16384, "1q");
        iiit_run("0q", &r);
        IIIT_ASSERT(r.n == 1 && r.toks[0].kind == IIIK_Q14_LIT && r.toks[0].int_value == 0, "0q");
        IIIT_OK();
    }
}
