/* III Grammar — populate parser's cached interned-id tables.
 *
 * At parser_create time we intern every keyword, modifier (with leading
 * '@'), operator (UTF-8 byte sequence), and punctuator string into the
 * lex state's intern table.  This guarantees that, regardless of what
 * the lexer has seen so far, p->kw_id[k] / p->mod_id[m] / p->op_id[o] /
 * p->pn_id[n] are valid stable ids.  Subsequent token-level identity
 * checks then reduce to a single uint32_t comparison.
 */
#include "parse_internal.h"

#include <stdint.h>
#include <string.h>

/* ---- UTF-8 encoder ---------------------------------------------------- */

/* Encode a codepoint into out (must hold at least 4 bytes).  Returns the
 * number of bytes written, or 0 for an invalid codepoint. */
static size_t utf8_encode(uint32_t cp, uint8_t out[4]) {
    if (cp < 0x80u) {
        out[0] = (uint8_t)cp;
        return 1;
    } else if (cp < 0x800u) {
        out[0] = (uint8_t)(0xC0u | (cp >> 6));
        out[1] = (uint8_t)(0x80u | (cp & 0x3Fu));
        return 2;
    } else if (cp < 0x10000u) {
        out[0] = (uint8_t)(0xE0u | (cp >> 12));
        out[1] = (uint8_t)(0x80u | ((cp >> 6) & 0x3Fu));
        out[2] = (uint8_t)(0x80u | (cp & 0x3Fu));
        return 3;
    } else if (cp < 0x110000u) {
        out[0] = (uint8_t)(0xF0u | (cp >> 18));
        out[1] = (uint8_t)(0x80u | ((cp >> 12) & 0x3Fu));
        out[2] = (uint8_t)(0x80u | ((cp >> 6) & 0x3Fu));
        out[3] = (uint8_t)(0x80u | (cp & 0x3Fu));
        return 4;
    }
    return 0;
}

/* ---- Tables ----------------------------------------------------------- */

/* Same order as the IIIKW_* enum (and LEXICON/src/keywords.c). */
static const char *KW_TEXT[IIIKW_COUNT] = {
    "witness", "glyph", "cycle", "hexad", "cap", "phase", "sanctum",
    "drtm", "observatory", "catalyst",
    "m\xC3\xB6" "bius",        /* möbius */
    "trinity", "ceiling", "sid", "wavefront", "waac",
    "witness_stream", "glyph_stream", "narrative", "explain", "propose",
    "negotiate", "commit", "reflect", "uncertainty", "epoch", "vdf",
    "mhash", "closure", "anchor", "federation", "amend", "bricking",
    "irreversible", "pure", "metal", "extern", "self_host", "promote",
    "observe", "coherence", "inverse", "manifest", "glyph_bound",
    "mobius_candidate", "schema", "module"
};

/* Same order as the IIIMOD_* enum.  '@' included. */
static const char *MOD_TEXT[IIIMOD_COUNT] = {
    "@ring", "@hexad", "@tier", "@epoch", "@cap",
    "@sanctum_only", "@irreversible", "@pure", "@closure", "@replicates",
    "@plan_anchor", "@admits_caps", "@prerequisites",
    "@candidate_for_promotion", "@mobius_coherence", "@witness_elide",
    "@hot_path", "@chronos_bypass", "@epoch_bridge"
};

/* Operator codepoints (cp1, cp2; cp2==0 means single-codepoint).
 * Same order as the IIIOP_* enum. */
typedef struct { uint32_t cp1, cp2; } op_cp_t;
static const op_cp_t OP_CP[IIIOP_COUNT] = {
    { 0x27F2, 0      }, /* ⟲ */
    { 0x2295, 0      }, /* ⊕ */
    { 0x2297, 0      }, /* ⊗ */
    { 0x29C9, 0      }, /* ⧉ */
    { 0x27D0, 0      }, /* ⟐ */
    { 0x21BB, 0      }, /* ↻ */
    { 0x27E1, 0      }, /* ⟡ */
    { 0x27C1, 0      }, /* ⟁ */
    { 0x29D7, 0      }, /* ⧗ */
    { 0x27F4, 0      }, /* ⟴ */
    { 0x29C8, 0      }, /* ⧈ */
    { 0x27F5, 0      }, /* ⟵ */
    { 0x29CA, 0      }, /* ⧊ */
    { 0x27F6, 0      }, /* ⟶ */
    { 0x2A01, 0      }, /* ⨁ */
    { 0x27F2, 0x27F2 }, /* ⟲⟲ */
    { 0x229B, 0      }, /* ⊛ */
    { 0x29C4, 0      }, /* ⧄ */
    { 0x27D0, 0x27D0 }, /* ⟐⟐ */
    { 0x29C7, 0      }, /* ⧇ */
    { 0x27E1, 0x27E1 }, /* ⟡⟡ */
    { 0x29CB, 0      }, /* ⧋ */
    { 0x27F4, 0x27F4 }  /* ⟴⟴ */
};

/* Punctuator interned-text table — must match the strings that
 * LEXICON/src/lex.c passes to iii_intern_put for IIIK_PUNCT tokens. */
static const char *PN_TEXT[IIIPN_COUNT] = {
    "(", ")", "{", "}", "[", "]",
    "<", ">", ",", ";", ":", ".",
    "=", "|", "_", "?", "&", "-",
    "\xE2\x89\xA4",   /* ≤ */
    "\xE2\x89\xA5",   /* ≥ */
    "->", "::", "..", "==", "=>", "!="
};

/* ---- Driver ----------------------------------------------------------- */

int iiip_init_keyword_ids(iii_parser_t *p) {
    /* Keywords. */
    for (size_t i = 0; i < (size_t)IIIKW_COUNT; i++) {
        const char *s = KW_TEXT[i];
        uint32_t id = iii_lex_intern(p->lex, s, strlen(s));
        if (id == 0) return -1;
        p->kw_id[i] = id;
    }
    /* Modifiers. */
    for (size_t i = 0; i < (size_t)IIIMOD_COUNT; i++) {
        const char *s = MOD_TEXT[i];
        uint32_t id = iii_lex_intern(p->lex, s, strlen(s));
        if (id == 0) return -1;
        p->mod_id[i] = id;
    }
    /* Operators — encode codepoint(s) to UTF-8. */
    for (size_t i = 0; i < (size_t)IIIOP_COUNT; i++) {
        uint8_t buf[8];
        size_t  n = utf8_encode(OP_CP[i].cp1, buf);
        if (n == 0) return -1;
        if (OP_CP[i].cp2) {
            size_t m = utf8_encode(OP_CP[i].cp2, buf + n);
            if (m == 0) return -1;
            n += m;
        }
        uint32_t id = iii_lex_intern(p->lex, (const char *)buf, n);
        if (id == 0) return -1;
        p->op_id[i] = id;
    }
    /* Punctuators. */
    for (size_t i = 0; i < (size_t)IIIPN_COUNT; i++) {
        const char *s = PN_TEXT[i];
        uint32_t id = iii_lex_intern(p->lex, s, strlen(s));
        if (id == 0) return -1;
        p->pn_id[i] = id;
    }
    return 0;
}
