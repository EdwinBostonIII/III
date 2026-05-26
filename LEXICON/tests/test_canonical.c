#include "test.h"
#include "iii/canonical.h"

void run_test_canonical(void) {
    {
        IIIT_BEGIN("canonicalize identity (no transform needed)");
        const uint8_t s[] = "let x = 1\n";
        uint8_t *o; size_t ol; iii_lex_error_t e;
        int rc = iii_canonicalize(s, sizeof(s)-1, &o, &ol, &e);
        IIIT_ASSERT(rc == 0 && ol == sizeof(s)-1 && memcmp(o, s, ol) == 0, "rc=%d ol=%zu", rc, ol);
        free(o);
        IIIT_OK();
    }
    {
        IIIT_BEGIN("R1 hash deterministic");
        const uint8_t s[] = "abc\n";
        uint8_t h1[32], h2[32]; iii_lex_error_t e;
        int rc1 = iii_r1_hash(s, sizeof(s)-1, h1, &e);
        int rc2 = iii_r1_hash(s, sizeof(s)-1, h2, &e);
        IIIT_ASSERT(rc1 == 0 && rc2 == 0 && memcmp(h1, h2, 32) == 0, "");
        IIIT_OK();
    }
    {
        IIIT_BEGIN("decomposed möbius rejected by canonicalize");
        const uint8_t s[] = {'m','o',0xCC,0x88,'b','i','u','s','\n'};
        uint8_t *o; size_t ol; iii_lex_error_t e;
        int rc = iii_canonicalize(s, sizeof(s), &o, &ol, &e);
        IIIT_ASSERT(rc == -1 && e.code == IIIE_ENC_006_INVALID_UTF8, "rc=%d code=%d", rc, e.code);
        IIIT_OK();
    }
}
