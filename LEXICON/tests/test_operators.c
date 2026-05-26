#include "test.h"

extern size_t iii_lex_operator_count(void);
extern int iii_lex_operator_at(size_t i, uint32_t *out_cp1, uint32_t *out_cp2);

static void encode(uint32_t cp, uint8_t *buf, int *w) {
    if (cp < 0x80) { buf[0] = (uint8_t)cp; *w = 1; }
    else if (cp < 0x800) { buf[0] = 0xC0|(cp>>6); buf[1] = 0x80|(cp&0x3F); *w = 2; }
    else if (cp < 0x10000) { buf[0] = 0xE0|(cp>>12); buf[1] = 0x80|((cp>>6)&0x3F); buf[2] = 0x80|(cp&0x3F); *w = 3; }
    else { buf[0] = 0xF0|(cp>>18); buf[1] = 0x80|((cp>>12)&0x3F); buf[2] = 0x80|((cp>>6)&0x3F); buf[3] = 0x80|(cp&0x3F); *w = 4; }
}

void run_test_operators(void) {
    {
        IIIT_BEGIN("all 23 operators lex as OPERATOR with correct id");
        size_t oc = iii_lex_operator_count();
        IIIT_ASSERT(oc == 23, "expected 23 ops got %zu", oc);
        for (size_t i = 0; i < oc; i++) {
            uint32_t cp1, cp2;
            int id = iii_lex_operator_at(i, &cp1, &cp2);
            uint8_t buf[16] = {0}; int w1, w2;
            encode(cp1, buf, &w1);
            int total = w1;
            if (cp2) { encode(cp2, buf + w1, &w2); total += w2; }
            char src[32]; memcpy(src, buf, total); src[total] = 0;
            iiit_run_t r; iiit_run(src, &r);
            IIIT_ASSERT(r.n == 1 && r.toks[0].kind == IIIK_OPERATOR,
                        "op id=%d failed: n=%zu kind=%s", id, r.n,
                        r.n ? iii_token_kind_name(r.toks[0].kind) : "(none)");
            IIIT_ASSERT((int)r.toks[0].int_value == id, "op id mismatch got %d expected %d",
                        (int)r.toks[0].int_value, id);
        }
        IIIT_OK();
    }
    {
        IIIT_BEGIN("⟲⟲ greedy double");
        iiit_run_t r;
        iiit_run("\xE2\x9F\xB2\xE2\x9F\xB2", &r); /* ⟲⟲ */
        IIIT_ASSERT(r.n == 1 && r.toks[0].int_value == 16, "expected op_id 16 got %llu",
                    (unsigned long long)r.toks[0].int_value);
        iiit_run("\xE2\x9F\xB2 \xE2\x9F\xB2", &r); /* ⟲ ⟲ */
        IIIT_ASSERT(r.n == 2, "expected 2 tokens got %zu", r.n);
        iiit_run("\xE2\x9F\xB2\xE2\x9F\xB2\xE2\x9F\xB2", &r); /* ⟲⟲⟲ */
        IIIT_ASSERT(r.n == 2 && r.toks[0].int_value == 16 && r.toks[1].int_value == 1,
                    "triple split got n=%zu", r.n);
        IIIT_OK();
    }
}
