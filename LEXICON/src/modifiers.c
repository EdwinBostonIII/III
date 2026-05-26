/* Modifier recognition.  19 modifiers (§5.1) + @safety synonym (§5.2). */
#include <stdint.h>
#include <stddef.h>
#include <string.h>

typedef struct {
    const char *bytes;
    size_t len;
    int canonical_id; /* @safety maps to @hexad's id */
} mod_entry_t;

/* Order chosen to match §5.1 numbering (1..19), with @safety appended as 20
 * but mapped to the @hexad canonical_id. */
static const mod_entry_t MOD[] = {
    {"@ring", 5, 1},
    {"@hexad", 6, 2},
    {"@tier", 5, 3},
    {"@epoch", 6, 4},
    {"@cap", 4, 5},
    {"@sanctum_only", 13, 6},
    {"@irreversible", 13, 7},
    {"@pure", 5, 8},
    {"@closure", 8, 9},
    {"@replicates", 11, 10},
    {"@plan_anchor", 12, 11},
    {"@admits_caps", 12, 12},
    {"@prerequisites", 14, 13},
    {"@candidate_for_promotion", 24, 14},
    {"@mobius_coherence", 17, 15},
    {"@witness_elide", 14, 16},
    {"@hot_path", 9, 17},
    {"@chronos_bypass", 15, 18},
    {"@epoch_bridge", 13, 19},
    {"@safety", 7, 2}        /* synonym for @hexad */
};

#define MOD_COUNT (sizeof(MOD)/sizeof(MOD[0]))

/* Look up a modifier given the bytes including the leading '@'.
 * Returns canonical_id (1..19) if matched, or 0 if not a modifier. */
int iii_lex_modifier_id(const uint8_t *s, size_t len) {
    for (size_t i = 0; i < MOD_COUNT; i++) {
        if (MOD[i].len == len && memcmp(MOD[i].bytes, s, len) == 0) return MOD[i].canonical_id;
    }
    return 0;
}

size_t iii_lex_modifier_count(void) { return MOD_COUNT; }
const char *iii_lex_modifier_at(size_t i, size_t *out_len, int *out_id) {
    if (i >= MOD_COUNT) { if (out_len) *out_len = 0; return NULL; }
    if (out_len) *out_len = MOD[i].len;
    if (out_id) *out_id = MOD[i].canonical_id;
    return MOD[i].bytes;
}
