/* Keyword recognition.  47 keywords (§4.1) + möbius (UTF-8 0xC3 0xB6).
 * We model this as a sorted-by-length-then-byte hash check via a perfect
 * lookup using a small open-addressed table on FNV-1a. */
#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include "iii/fnv1a.h"

typedef struct {
    const char *bytes;
    size_t len;
} kw_entry_t;

/* The 47 keywords, byte-exact (möbius is encoded as the precomposed UTF-8 form). */
static const kw_entry_t KW[] = {
    {"witness", 7},
    {"glyph", 5},
    {"cycle", 5},
    {"hexad", 5},
    {"cap", 3},
    {"phase", 5},
    {"sanctum", 7},
    {"drtm", 4},
    {"observatory", 11},
    {"catalyst", 8},
    {"m\xC3\xB6" "bius", 7},   /* möbius — 'm' 0xC3 0xB6 'b' 'i' 'u' 's' */
    {"trinity", 7},
    {"ceiling", 7},
    {"sid", 3},
    {"wavefront", 9},
    {"waac", 4},
    {"witness_stream", 14},
    {"glyph_stream", 12},
    {"narrative", 9},
    {"explain", 7},
    {"propose", 7},
    {"negotiate", 9},
    {"commit", 6},
    {"reflect", 7},
    {"uncertainty", 11},
    {"epoch", 5},
    {"vdf", 3},
    {"mhash", 5},
    {"closure", 7},
    {"anchor", 6},
    {"federation", 10},
    {"amend", 5},
    {"bricking", 8},
    {"irreversible", 12},
    {"pure", 4},
    {"metal", 5},
    {"extern", 6},
    {"self_host", 9},
    {"promote", 7},
    {"observe", 7},
    {"coherence", 9},
    {"inverse", 7},
    {"manifest", 8},
    {"glyph_bound", 11},
    {"mobius_candidate", 16},
    {"schema", 6},
    {"module", 6}
};

#define KW_COUNT (sizeof(KW)/sizeof(KW[0]))

/* Returns 1 if the bytes [s, s+len) are exactly one of the 47 keywords. */
int iii_lex_is_keyword(const uint8_t *s, size_t len) {
    for (size_t i = 0; i < KW_COUNT; i++) {
        if (KW[i].len == len && memcmp(KW[i].bytes, s, len) == 0) return 1;
    }
    return 0;
}

size_t iii_lex_keyword_count(void) { return KW_COUNT; }
const char *iii_lex_keyword_at(size_t i, size_t *out_len) {
    if (i >= KW_COUNT) { if (out_len) *out_len = 0; return NULL; }
    if (out_len) *out_len = KW[i].len;
    return KW[i].bytes;
}

/* Catalyst reserved slot prefixes (§14.2):
 *  KW_RESERVED_001..016, MOD_RESERVED_001..008, OP_RESERVED_001..007 */
int iii_lex_is_reserved_slot(const uint8_t *s, size_t len) {
    static const char *prefixes[] = { "KW_RESERVED_", "MOD_RESERVED_", "OP_RESERVED_" };
    static const size_t plens[] = { 12, 13, 12 };
    static const int maxn[] = { 16, 8, 7 };
    for (int k = 0; k < 3; k++) {
        if (len == plens[k] + 3 && memcmp(s, prefixes[k], plens[k]) == 0) {
            const uint8_t *d = s + plens[k];
            if (d[0] >= '0' && d[0] <= '9' && d[1] >= '0' && d[1] <= '9' && d[2] >= '0' && d[2] <= '9') {
                int n = (d[0]-'0')*100 + (d[1]-'0')*10 + (d[2]-'0');
                if (n >= 1 && n <= maxn[k]) return 1;
            }
        }
    }
    return 0;
}
