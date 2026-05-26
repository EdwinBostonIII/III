#include "test.h"
#include "iii/utf8.h"

void run_test_utf8(void) {
    {
        IIIT_BEGIN("utf8 ASCII roundtrip");
        uint32_t cp; int w;
        IIIT_ASSERT(iii_utf8_decode((const uint8_t *)"A", 1, &cp, &w) == 1 && cp == 'A' && w == 1, "ASCII decode");
        IIIT_OK();
    }
    {
        IIIT_BEGIN("utf8 ö (U+00F6)");
        uint32_t cp; int w;
        IIIT_ASSERT(iii_utf8_decode((const uint8_t *)"\xC3\xB6", 2, &cp, &w) == 1 && cp == 0xF6 && w == 2, "ö decode");
        IIIT_OK();
    }
    {
        IIIT_BEGIN("utf8 ⟲ (U+27F2)");
        uint32_t cp; int w;
        IIIT_ASSERT(iii_utf8_decode((const uint8_t *)"\xE2\x9F\xB2", 3, &cp, &w) == 1 && cp == 0x27F2 && w == 3, "⟲ decode");
        IIIT_OK();
    }
    {
        IIIT_BEGIN("utf8 reject overlong");
        uint32_t cp; int w;
        IIIT_ASSERT(iii_utf8_decode((const uint8_t *)"\xC0\x80", 2, &cp, &w) == 0, "overlong NUL");
        IIIT_OK();
    }
    {
        IIIT_BEGIN("utf8 reject surrogate");
        uint32_t cp; int w;
        IIIT_ASSERT(iii_utf8_decode((const uint8_t *)"\xED\xA0\x80", 3, &cp, &w) == 0, "surrogate U+D800");
        IIIT_OK();
    }
    {
        IIIT_BEGIN("utf8 4-byte (U+10437)");
        uint32_t cp; int w;
        IIIT_ASSERT(iii_utf8_decode((const uint8_t *)"\xF0\x90\x90\xB7", 4, &cp, &w) == 1 && cp == 0x10437 && w == 4, "4-byte decode");
        IIIT_OK();
    }
    {
        IIIT_BEGIN("utf8 encode roundtrip");
        uint8_t buf[4];
        int w = iii_utf8_encode(0x27F2, buf);
        IIIT_ASSERT(w == 3 && buf[0] == 0xE2 && buf[1] == 0x9F && buf[2] == 0xB2, "encode ⟲");
        IIIT_OK();
    }
}
