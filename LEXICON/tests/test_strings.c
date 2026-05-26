#include "test.h"

void run_test_strings(void) {
    iiit_run_t r;
    {
        IIIT_BEGIN("regular string with escapes");
        iiit_run("\"hi\\n\\\"\\u{27F2}\"", &r);
        IIIT_ASSERT(r.n == 1 && r.toks[0].kind == IIIK_STRING_LIT, "");
        /* payload bytes: 'h','i','\n','"', then UTF-8 of U+27F2 = E2 9F B2 */
        const uint8_t expect[] = {'h','i','\n','"',0xE2,0x9F,0xB2};
        IIIT_ASSERT(r.toks[0].string_len == 7 && memcmp(r.toks[0].string_payload, expect, 7) == 0,
                    "payload mismatch (len=%zu)", r.toks[0].string_len);
        IIIT_OK();
    }
    {
        IIIT_BEGIN("byte string");
        iiit_run("b\"deadbeef\"", &r);
        IIIT_ASSERT(r.n == 1 && r.toks[0].kind == IIIK_BYTE_STRING_LIT, "");
        IIIT_ASSERT(r.toks[0].string_len == 8 && memcmp(r.toks[0].string_payload, "deadbeef", 8) == 0, "");
        IIIT_OK();
    }
    {
        IIIT_BEGIN("raw string r\"\\n\"");
        iiit_run("r\"\\n\"", &r);
        IIIT_ASSERT(r.n == 1 && r.toks[0].kind == IIIK_RAW_STRING_LIT, "");
        IIIT_ASSERT(r.toks[0].string_len == 2 && r.toks[0].string_payload[0] == '\\'
                    && r.toks[0].string_payload[1] == 'n', "raw payload mismatch");
        IIIT_OK();
    }
    {
        IIIT_BEGIN("raw string with hashes r#\"contains \\\"quotes\\\"\"#");
        iiit_run("r#\"contains \"quotes\"\"#", &r);
        IIIT_ASSERT(r.n == 1 && r.toks[0].kind == IIIK_RAW_STRING_LIT, "");
        IIIT_ASSERT(r.toks[0].string_len == 17, "len got %zu", r.toks[0].string_len);
        IIIT_OK();
    }
    {
        IIIT_BEGIN("hex string");
        iiit_run("h\"de ad be ef\"", &r);
        IIIT_ASSERT(r.n == 1 && r.toks[0].kind == IIIK_HEX_STRING_LIT, "");
        const uint8_t expect[] = {0xDE,0xAD,0xBE,0xEF};
        IIIT_ASSERT(r.toks[0].string_len == 4 && memcmp(r.toks[0].string_payload, expect, 4) == 0,
                    "decoded len=%zu", r.toks[0].string_len);
        IIIT_OK();
    }
    {
        IIIT_BEGIN("odd hex string error");
        iiit_run("h\"abc\"", &r);
        IIIT_ASSERT(r.errs >= 1, "expected odd-length error");
        IIIT_OK();
    }
}
