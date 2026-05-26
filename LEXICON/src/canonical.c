#include "iii/canonical.h"
#include "iii/utf8.h"
#include "iii/sha256.h"
#include "iii/nfc.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#define MAX_SIZE (16u * 1024u * 1024u)

static void seterr(iii_lex_error_t *e, iii_lex_error_code_t c, uint32_t off, uint32_t line, uint32_t col,
                   const char *msg) {
    if (!e) return;
    e->code = c; e->byte_offset = off; e->line = line; e->col = col;
    snprintf(e->message, sizeof(e->message), "%s", msg);
    e->suggestion[0] = 0;
}

static bool is_forbidden_ctrl(uint32_t cp) {
    if (cp == 0x00) return true;
    if (cp == 0x07 || cp == 0x08 || cp == 0x0B || cp == 0x0C) return true;
    if (cp == 0x1B) return true;
    if (cp == 0x7F) return true;
    if (cp >= 0x80 && cp <= 0x9F) return true;
    if (cp == 0x200B || cp == 0x200C || cp == 0x200D || cp == 0x2060) return true;
    if (cp == 0xFEFF) return true;
    return false;
}

int iii_canonicalize(const uint8_t *src, size_t len,
                     uint8_t **out_canonical, size_t *out_len,
                     iii_lex_error_t *err_out) {
    *out_canonical = NULL; *out_len = 0;
    if (err_out) memset(err_out, 0, sizeof(*err_out));

    if (len > MAX_SIZE) {
        seterr(err_out, IIIE_ENC_005_TOO_LARGE, (uint32_t)MAX_SIZE, 0, 0,
               "source exceeds 16 MiB limit — split into modules");
        return -1;
    }
    if (len >= 3 && src[0] == 0xEF && src[1] == 0xBB && src[2] == 0xBF) {
        seterr(err_out, IIIE_ENC_001_BOM, 0, 1, 1, "BOM forbidden — III source is BOM-less UTF-8");
        return -1;
    }

    /* Validate UTF-8 + reject CR + reject trailing whitespace + reject forbidden ctrl
     * + reject decomposed möbius. */
    uint32_t line = 1, col = 1;
    uint32_t prev_cp = 0;
    size_t i = 0;
    size_t line_last_nonws = 0; /* offset of last non-ws byte on current line, or 0 */
    bool line_has_content = false;
    while (i < len) {
        uint32_t cp; int w;
        if (!iii_utf8_decode(src + i, len - i, &cp, &w)) {
            seterr(err_out, IIIE_ENC_006_INVALID_UTF8, (uint32_t)i, line, col, "invalid UTF-8 byte sequence");
            return -1;
        }
        if (cp == 0x0D) {
            seterr(err_out, IIIE_ENC_002_CR, (uint32_t)i, line, col, "CR forbidden — III source is LF-only");
            return -1;
        }
        if (cp == 0x0A) {
            if (line_has_content) {
                /* Check trailing ws: bytes before LF that are space/tab. */
                if (i > 0 && (src[i-1] == 0x20 || src[i-1] == 0x09)) {
                    seterr(err_out, IIIE_ENC_003_TRAILING_WS, (uint32_t)(i-1), line, col,
                           "trailing whitespace at line");
                    return -1;
                }
            }
            line++; col = 1; line_has_content = false;
            (void)line_last_nonws;
            i += (size_t)w; prev_cp = cp; continue;
        }
        if (is_forbidden_ctrl(cp)) {
            /* For canonicalization, we still reject these everywhere — string
             * literals get a different code (LEX-ENC-008) handled by lexer.
             * Canonical-time we report ENC-007. */
            seterr(err_out, IIIE_ENC_007_FORBIDDEN_CTRL, (uint32_t)i, line, col,
                   "forbidden control codepoint");
            return -1;
        }
        /* NFC: reject decomposed mobius */
        if (iii_nfc_is_forbidden_combining(cp)) {
            if (iii_nfc_decomposed_is_lexicon(prev_cp, cp)) {
                seterr(err_out, IIIE_ENC_006_INVALID_UTF8, (uint32_t)i, line, col,
                       "decomposed möbius — use precomposed U+00F6");
                return -1;
            }
        }
        if (cp != 0x20 && cp != 0x09) line_has_content = true;
        col++;
        i += (size_t)w; prev_cp = cp;
    }
    /* trailing line without final LF */
    if (line_has_content && len > 0 && (src[len-1] == 0x20 || src[len-1] == 0x09)) {
        seterr(err_out, IIIE_ENC_003_TRAILING_WS, (uint32_t)(len-1), line, col,
               "trailing whitespace at end-of-file");
        return -1;
    }

    uint8_t *out = (uint8_t *)malloc(len ? len : 1);
    if (!out) {
        seterr(err_out, IIIE_ENC_005_TOO_LARGE, 0, 0, 0, "out of memory");
        return -1;
    }
    if (len) memcpy(out, src, len);
    *out_canonical = out; *out_len = len;
    return 0;
}

int iii_r1_hash(const uint8_t *src, size_t len, uint8_t out[32], iii_lex_error_t *err_out) {
    uint8_t *canon = NULL; size_t clen = 0;
    if (iii_canonicalize(src, len, &canon, &clen, err_out) != 0) return -1;
    iii_sha256(canon, clen, out);
    free(canon);
    return 0;
}
