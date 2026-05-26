/* III Lexicon — main state machine.
 *
 * NIH-extreme: only libc.  Fully specified behavior per III-LEXICON.md.
 */
#include "iii/lex.h"
#include "iii/token.h"
#include "iii/errors.h"
#include "iii/utf8.h"
#include "iii/sha256.h"
#include "iii/intern.h"
#include "iii/arena.h"
#include "iii/nfc.h"
#include "lex_internal.h"

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdarg.h>
#include <assert.h>

/* ===== State ============================================================== */

typedef struct {
    const uint8_t *src;
    size_t len;
    size_t pos;
    uint32_t line;
    uint32_t col;
} cursor_t;

struct iii_lex_state {
    cursor_t c;
    const char *path;

    iii_arena_t arena;
    iii_intern_t intern;

    iii_lex_error_t *errors;
    size_t errs_len;
    size_t errs_cap;

    int has_peek;
    iii_token_t peek;
};

/* ===== Cursor helpers ===================================================== */

static int peek_cp(const cursor_t *c, uint32_t *out_cp, int *out_w) {
    if (c->pos >= c->len) { *out_cp = 0; *out_w = 0; return 0; }
    return iii_utf8_decode(c->src + c->pos, c->len - c->pos, out_cp, out_w);
}

static int peek_cp_at(const cursor_t *c, size_t off, uint32_t *out_cp, int *out_w) {
    if (c->pos + off >= c->len) { *out_cp = 0; *out_w = 0; return 0; }
    return iii_utf8_decode(c->src + c->pos + off, c->len - c->pos - off, out_cp, out_w);
}

static void advance(cursor_t *c, uint32_t cp, int w) {
    c->pos += (size_t)w;
    if (cp == 0x0A) { c->line++; c->col = 1; }
    else c->col++;
}

/* ===== Error reporting ==================================================== */

static void record_error(iii_lex_state_t *st, iii_lex_error_code_t code,
                         uint32_t off, uint32_t line, uint32_t col, const char *fmt, ...) {
    if (st->errs_len == st->errs_cap) {
        size_t nc = st->errs_cap ? st->errs_cap * 2 : 16;
        iii_lex_error_t *ne = (iii_lex_error_t *)realloc(st->errors, nc * sizeof(*ne));
        if (!ne) return;
        st->errors = ne; st->errs_cap = nc;
    }
    iii_lex_error_t *e = &st->errors[st->errs_len++];
    memset(e, 0, sizeof(*e));
    e->code = code; e->byte_offset = off; e->line = line; e->col = col;
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(e->message, sizeof(e->message), fmt, ap);
    va_end(ap);
}

/* ===== Char classification ================================================ */

static inline int is_ascii_alpha(uint32_t c) {
    return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z');
}
static inline int is_ascii_digit(uint32_t c) { return c >= '0' && c <= '9'; }
static inline int is_id_start(uint32_t c) { return is_ascii_alpha(c) || c == '_'; }
static inline int is_id_cont(uint32_t c) { return is_id_start(c) || is_ascii_digit(c); }
static inline int is_hex_digit(uint32_t c) {
    return is_ascii_digit(c) || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
}
static inline int hex_val(uint32_t c) {
    if (c >= '0' && c <= '9') return (int)(c - '0');
    if (c >= 'a' && c <= 'f') return (int)(c - 'a') + 10;
    if (c >= 'A' && c <= 'F') return (int)(c - 'A') + 10;
    return -1;
}
static inline int is_forbidden_ctrl(uint32_t cp) {
    if (cp == 0x00) return 1;
    if (cp == 0x07 || cp == 0x08 || cp == 0x0B || cp == 0x0C) return 1;
    if (cp == 0x1B) return 1;
    if (cp == 0x7F) return 1;
    if (cp >= 0x80 && cp <= 0x9F) return 1;
    if (cp == 0x200B || cp == 0x200C || cp == 0x200D || cp == 0x2060) return 1;
    if (cp == 0xFEFF) return 1;
    return 0;
}

/* ===== Whitespace + comments ============================================== */

/* Returns 1 if a doc comment was emitted; 0 if regular comment consumed; -1 EOF; -2 error. */
static int skip_one_ws_or_comment(iii_lex_state_t *st, iii_token_t *out_doc, int *out_emitted) {
    cursor_t *c = &st->c;
    *out_emitted = 0;
    if (c->pos >= c->len) return -1;
    uint32_t cp; int w;
    if (!peek_cp(c, &cp, &w)) {
        record_error(st, IIIE_ENC_006_INVALID_UTF8, (uint32_t)c->pos, c->line, c->col, "invalid UTF-8");
        c->pos += 1; c->col++;
        return -2;
    }
    if (cp == ' ' || cp == '\t' || cp == '\n') {
        advance(c, cp, w);
        return 0;
    }
    if (cp == 0x000B || cp == 0x000C || cp == 0x00A0 ||
        (cp >= 0x2000 && cp <= 0x200A) || cp == 0x202F || cp == 0x205F || cp == 0x3000) {
        record_error(st, IIIE_WS_001_FORBIDDEN_WS, (uint32_t)c->pos, c->line, c->col,
                     "forbidden whitespace codepoint U+%04X", cp);
        advance(c, cp, w);
        return -2;
    }
    if (cp != '/') return 1; /* not whitespace/comment */

    /* '/' lookahead */
    uint32_t cp2; int w2;
    peek_cp_at(c, (size_t)w, &cp2, &w2);
    if (cp2 == '/') {
        /* line comment or doc comment */
        uint32_t cp3; int w3;
        peek_cp_at(c, (size_t)(w + w2), &cp3, &w3);
        int is_doc = (cp3 == '/');
        size_t start = c->pos;
        uint32_t sline = c->line, scol = c->col;
        if (is_doc) {
            advance(c, cp, w); advance(c, cp2, w2); advance(c, cp3, w3);
        } else {
            advance(c, cp, w); advance(c, cp2, w2);
        }
        size_t body_start = c->pos;
        while (c->pos < c->len) {
            uint32_t k; int kw;
            if (!peek_cp(c, &k, &kw)) {
                record_error(st, IIIE_ENC_006_INVALID_UTF8, (uint32_t)c->pos, c->line, c->col, "invalid UTF-8");
                c->pos++; c->col++;
                continue;
            }
            if (k == '\n') break;
            advance(c, k, kw);
        }
        if (is_doc) {
            memset(out_doc, 0, sizeof(*out_doc));
            out_doc->kind = IIIK_DOC_COMMENT;
            out_doc->text_offset = (uint32_t)start;
            out_doc->text_len = (uint32_t)(c->pos - start);
            out_doc->line = sline;
            out_doc->col = scol;
            uint8_t *body = iii_arena_dup(&st->arena, c->src + body_start, c->pos - body_start);
            out_doc->string_payload = body;
            out_doc->string_len = c->pos - body_start;
            out_doc->interned_id = iii_intern_put(&st->intern,
                                                  c->src + start, c->pos - start);
            *out_emitted = 1;
        }
        return 0;
    }
    if (cp2 == '*') {
        uint32_t cp3; int w3;
        peek_cp_at(c, (size_t)(w + w2), &cp3, &w3);
        int is_doc = (cp3 == '*');
        /* Note: a '/' '*' '*' '/' sequence is empty doc per spec. */
        size_t start = c->pos;
        uint32_t sline = c->line, scol = c->col;
        size_t body_start;
        if (is_doc) {
            advance(c, cp, w); advance(c, cp2, w2); advance(c, cp3, w3);
            body_start = c->pos;
        } else {
            advance(c, cp, w); advance(c, cp2, w2);
            body_start = c->pos;
        }
        int depth = 1;
        size_t body_end = c->pos;
        while (depth > 0 && c->pos < c->len) {
            uint32_t k; int kw;
            if (!peek_cp(c, &k, &kw)) {
                record_error(st, IIIE_ENC_006_INVALID_UTF8, (uint32_t)c->pos, c->line, c->col, "invalid UTF-8");
                c->pos++; c->col++;
                continue;
            }
            uint32_t k2; int kw2;
            peek_cp_at(c, (size_t)kw, &k2, &kw2);
            if (k == '/' && k2 == '*') {
                advance(c, k, kw); advance(c, k2, kw2); depth++;
            } else if (k == '*' && k2 == '/') {
                body_end = c->pos;
                advance(c, k, kw); advance(c, k2, kw2); depth--;
            } else {
                advance(c, k, kw);
            }
        }
        if (depth != 0) {
            record_error(st, IIIE_CMT_001_UNTERMINATED_BLOCK, (uint32_t)start, sline, scol,
                         "unterminated block comment");
            return -2;
        }
        if (is_doc) {
            memset(out_doc, 0, sizeof(*out_doc));
            out_doc->kind = IIIK_DOC_COMMENT;
            out_doc->text_offset = (uint32_t)start;
            out_doc->text_len = (uint32_t)(c->pos - start);
            out_doc->line = sline;
            out_doc->col = scol;
            uint8_t *body = iii_arena_dup(&st->arena, c->src + body_start,
                                          body_end > body_start ? body_end - body_start : 0);
            out_doc->string_payload = body;
            out_doc->string_len = body_end > body_start ? body_end - body_start : 0;
            out_doc->interned_id = iii_intern_put(&st->intern,
                                                  c->src + start, c->pos - start);
            *out_emitted = 1;
        }
        return 0;
    }
    return 1; /* '/' but not a comment — pass through to operator/error handling */
}

/* ===== Identifier scan ==================================================== */

/* Scan an ASCII identifier starting at current cursor (caller verified is_id_start).
 * Special-cases the precomposed möbius prefix. */
static void scan_identifier(iii_lex_state_t *st, size_t *out_end) {
    cursor_t *c = &st->c;
    /* Special: möbius prefix detection. Must be exactly bytes 'm' 0xC3 0xB6 'b' 'i' 'u' 's'. */
    if (c->pos + 7 <= c->len &&
        c->src[c->pos] == 'm' &&
        c->src[c->pos+1] == 0xC3 &&
        c->src[c->pos+2] == 0xB6 &&
        c->src[c->pos+3] == 'b' &&
        c->src[c->pos+4] == 'i' &&
        c->src[c->pos+5] == 'u' &&
        c->src[c->pos+6] == 's') {
        /* check no id_continue follows */
        if (c->pos + 7 == c->len || !is_id_cont(c->src[c->pos+7])) {
            /* consume 7 bytes: 'm' is 1 col, 'ö' is 1 col, 'b','i','u','s' = 4 cols. */
            c->pos += 7;
            c->col += 6;
            *out_end = c->pos;
            return;
        }
    }
    while (c->pos < c->len) {
        uint32_t cp; int w;
        if (!peek_cp(c, &cp, &w)) break;
        if (is_id_cont(cp)) { advance(c, cp, w); continue; }
        /* Reject decomposed-möbius pattern mid-identifier */
        if (cp == 0x0308) {
            record_error(st, IIIE_ENC_006_INVALID_UTF8, (uint32_t)c->pos, c->line, c->col,
                         "decomposed combining mark in identifier — use precomposed form");
            advance(c, cp, w);
            continue;
        }
        break;
    }
    *out_end = c->pos;
}

/* ===== Number scanning ==================================================== */

/* Parse digit string (radix 2/8/10/16) with underscore separators.
 * Returns 0 on ok with *out_value set, -1 on overflow.
 * Updates underscore_used flag. */
static int parse_radix_value(const uint8_t *p, size_t n, int radix, uint64_t *out_value, int *out_uscore) {
    uint64_t v = 0;
    int us = 0;
    for (size_t i = 0; i < n; i++) {
        uint8_t c = p[i];
        if (c == '_') { us = 1; continue; }
        int d;
        if (c >= '0' && c <= '9') d = c - '0';
        else if (c >= 'a' && c <= 'f') d = c - 'a' + 10;
        else if (c >= 'A' && c <= 'F') d = c - 'A' + 10;
        else return -1;
        if (d >= radix) return -1;
        if (v > (UINT64_MAX - (uint64_t)d) / (uint64_t)radix) return -1;
        v = v * (uint64_t)radix + (uint64_t)d;
    }
    *out_value = v;
    if (out_uscore) *out_uscore = us;
    return 0;
}

/* Parse the suffix bytes (e.g. "u8", "i64", "q14", "t", "tn"). Returns the
 * suffix enum or IIIS_NONE if unrecognized. */
static iii_int_suffix_t parse_suffix(const uint8_t *p, size_t n) {
    if (n == 0) return IIIS_NONE;
    if (n == 1) {
        if (p[0] == 'q') return IIIS_Q;
        if (p[0] == 't') return IIIS_T;
    }
    if (n == 2) {
        if (p[0] == 'u' && p[1] == '8') return IIIS_U8;
        if (p[0] == 'i' && p[1] == '8') return IIIS_I8;
        if (p[0] == 't' && p[1] == 'n') return IIIS_TN;
        if (p[0] == 't' && p[1] == 'z') return IIIS_TZ;
        if (p[0] == 't' && p[1] == 'p') return IIIS_TP;
    }
    if (n == 3) {
        if (p[0] == 'u' && p[1] == '1' && p[2] == '6') return IIIS_U16;
        if (p[0] == 'u' && p[1] == '3' && p[2] == '2') return IIIS_U32;
        if (p[0] == 'u' && p[1] == '6' && p[2] == '4') return IIIS_U64;
        if (p[0] == 'i' && p[1] == '1' && p[2] == '6') return IIIS_I16;
        if (p[0] == 'i' && p[1] == '3' && p[2] == '2') return IIIS_I32;
        if (p[0] == 'i' && p[1] == '6' && p[2] == '4') return IIIS_I64;
        if (p[0] == 'q' && p[1] == '1' && p[2] == '4') return IIIS_Q14;
    }
    return IIIS_NONE;
}

static int suffix_fits(iii_int_suffix_t s, uint64_t v) {
    switch (s) {
        case IIIS_U8: return v <= 0xFFu;
        case IIIS_U16: return v <= 0xFFFFu;
        case IIIS_U32: return v <= 0xFFFFFFFFu;
        case IIIS_U64: return 1;
        case IIIS_I8: return v <= 0x7Fu;
        case IIIS_I16: return v <= 0x7FFFu;
        case IIIS_I32: return v <= 0x7FFFFFFFu;
        case IIIS_I64: return v <= 0x7FFFFFFFFFFFFFFFull;
        default: return 1;
    }
}

/* ===== Hexad lookahead ==================================================== */

/* Forward decl */
static int try_scan_trit_for_hexad(iii_lex_state_t *st, int *out_value);

static int try_scan_hexad(iii_lex_state_t *st, uint16_t *out_packed, size_t *out_end) {
    cursor_t saved = st->c;
    size_t saved_errs = st->errs_len;
    int trits[6];
    /* Consume '(' */
    uint32_t cp; int w;
    peek_cp(&st->c, &cp, &w);
    if (cp != '(') { st->c = saved; st->errs_len = saved_errs; return 0; }
    advance(&st->c, cp, w);
    for (int i = 0; i < 6; i++) {
        /* skip ws (no comments inside a literal) */
        while (st->c.pos < st->c.len) {
            uint32_t k; int kw;
            if (!peek_cp(&st->c, &k, &kw)) { st->c = saved; st->errs_len = saved_errs; return 0; }
            if (k == ' ' || k == '\t' || k == '\n') { advance(&st->c, k, kw); continue; }
            break;
        }
        if (!try_scan_trit_for_hexad(st, &trits[i])) { st->c = saved; st->errs_len = saved_errs; return 0; }
        /* skip ws */
        while (st->c.pos < st->c.len) {
            uint32_t k; int kw;
            if (!peek_cp(&st->c, &k, &kw)) { st->c = saved; st->errs_len = saved_errs; return 0; }
            if (k == ' ' || k == '\t' || k == '\n') { advance(&st->c, k, kw); continue; }
            break;
        }
        uint32_t k; int kw;
        if (!peek_cp(&st->c, &k, &kw)) { st->c = saved; st->errs_len = saved_errs; return 0; }
        if (i < 5) {
            if (k != ',') { st->c = saved; st->errs_len = saved_errs; return 0; }
            advance(&st->c, k, kw);
        } else {
            if (k != ')') { st->c = saved; st->errs_len = saved_errs; return 0; }
            advance(&st->c, k, kw);
        }
    }
    uint16_t packed = 0;
    for (int i = 0; i < 6; i++) packed |= (uint16_t)((trits[i] + 2) & 0x3) << (i * 2);
    *out_packed = packed;
    *out_end = st->c.pos;
    return 1;
}

/* Scan a single trit literal in any of the supported forms; on success set *out_value
 * to -1/0/+1 and advance cursor.  On failure return 0 (cursor may have advanced). */
static int try_scan_trit_for_hexad(iii_lex_state_t *st, int *out_value) {
    cursor_t before = st->c;
    if (st->c.pos >= st->c.len) return 0;
    uint32_t cp; int w; peek_cp(&st->c, &cp, &w);
    /* NEG/ZERO/POS — identifiers */
    if (is_id_start(cp)) {
        size_t start = st->c.pos;
        while (st->c.pos < st->c.len) {
            uint32_t k; int kw;
            if (!peek_cp(&st->c, &k, &kw)) break;
            if (!is_id_cont(k)) break;
            advance(&st->c, k, kw);
        }
        size_t L = st->c.pos - start;
        const uint8_t *p = st->c.src + start;
        if (L == 3 && memcmp(p, "NEG", 3) == 0) { *out_value = -1; return 1; }
        if (L == 3 && memcmp(p, "POS", 3) == 0) { *out_value = +1; return 1; }
        if (L == 4 && memcmp(p, "ZERO", 4) == 0) { *out_value = 0; return 1; }
        st->c = before; return 0;
    }
    /* -1t / +1t / 0t / 0tn / 0tz / 0tp */
    if (cp == '-' || cp == '+') {
        if (st->c.pos + 2 <= st->c.len && st->c.src[st->c.pos+1] == '1' &&
            st->c.pos + 3 <= st->c.len && st->c.src[st->c.pos+2] == 't') {
            /* must end with non-id-cont */
            uint32_t after = (st->c.pos + 3 < st->c.len) ? st->c.src[st->c.pos+3] : 0;
            if (after == 0 || !is_id_cont(after)) {
                *out_value = (cp == '-') ? -1 : +1;
                st->c.pos += 3;
                st->c.col += 3;
                return 1;
            }
        }
        st->c = before; return 0;
    }
    if (cp == '0') {
        if (st->c.pos + 2 <= st->c.len && st->c.src[st->c.pos+1] == 't') {
            if (st->c.pos + 3 <= st->c.len) {
                uint8_t s = st->c.src[st->c.pos+2];
                if (s == 'n' || s == 'z' || s == 'p') {
                    uint32_t after = (st->c.pos + 3 < st->c.len) ? st->c.src[st->c.pos+3] : 0;
                    if (after == 0 || !is_id_cont(after)) {
                        *out_value = (s == 'n') ? -1 : (s == 'z' ? 0 : +1);
                        st->c.pos += 3;
                        st->c.col += 3;
                        return 1;
                    }
                }
            }
            uint32_t after = (st->c.pos + 2 < st->c.len) ? st->c.src[st->c.pos+2] : 0;
            if (after == 0 || !is_id_cont(after)) {
                *out_value = 0;
                st->c.pos += 2;
                st->c.col += 2;
                return 1;
            }
        }
        st->c = before; return 0;
    }
    return 0;
}

/* ===== String scanners ==================================================== */

static int scan_hex_byte(iii_lex_state_t *st, uint8_t *out) {
    if (st->c.pos + 2 > st->c.len) return 0;
    int hi = hex_val(st->c.src[st->c.pos]);
    int lo = hex_val(st->c.src[st->c.pos+1]);
    if (hi < 0 || lo < 0) return 0;
    *out = (uint8_t)((hi << 4) | lo);
    st->c.pos += 2; st->c.col += 2;
    return 1;
}

static int scan_string_lit(iii_lex_state_t *st, iii_token_t *out) {
    /* Caller has not yet consumed the opening '"'. */
    cursor_t *c = &st->c;
    size_t start = c->pos;
    uint32_t sline = c->line, scol = c->col;
    advance(c, '"', 1);
    /* Build payload in a small dynamic buffer in arena. */
    size_t cap = 64, len = 0;
    uint8_t *buf = (uint8_t *)malloc(cap);
    while (c->pos < c->len) {
        uint32_t cp; int w;
        if (!peek_cp(c, &cp, &w)) {
            record_error(st, IIIE_ENC_006_INVALID_UTF8, (uint32_t)c->pos, c->line, c->col, "invalid UTF-8 in string");
            free(buf); return -1;
        }
        if (cp == '"') {
            advance(c, cp, w);
            uint8_t *payload = (uint8_t *)iii_arena_alloc(&st->arena, len + 1, 1);
            memcpy(payload, buf, len); payload[len] = 0;
            free(buf);
            out->kind = IIIK_STRING_LIT;
            out->text_offset = (uint32_t)start;
            out->text_len = (uint32_t)(c->pos - start);
            out->line = sline; out->col = scol;
            out->string_payload = payload; out->string_len = len;
            out->interned_id = iii_intern_put(&st->intern, payload, len);
            return 0;
        }
        if (cp == '\n') {
            record_error(st, IIIE_STR_001_UNESCAPED_NEWLINE, (uint32_t)c->pos, c->line, c->col,
                         "unescaped newline in string literal");
            free(buf); return -1;
        }
        if (cp != '\\' && is_forbidden_ctrl(cp)) {
            record_error(st, IIIE_ENC_008_RAW_FORBIDDEN_IN_STRING, (uint32_t)c->pos, c->line, c->col,
                         "raw forbidden codepoint inside string literal");
            free(buf); return -1;
        }
        if (cp == '\\') {
            advance(c, cp, w);
            uint32_t e; int ew;
            if (!peek_cp(c, &e, &ew)) {
                record_error(st, IIIE_STR_004_UNTERMINATED, (uint32_t)c->pos, c->line, c->col,
                             "unterminated escape");
                free(buf); return -1;
            }
            uint32_t emit_cp = 0; int do_emit_cp = 0; uint8_t emit_byte = 0; int do_emit_byte = 0;
            switch (e) {
                case '\\': emit_byte = '\\'; do_emit_byte = 1; advance(c, e, ew); break;
                case '"':  emit_byte = '"';  do_emit_byte = 1; advance(c, e, ew); break;
                case 'n':  emit_byte = '\n'; do_emit_byte = 1; advance(c, e, ew); break;
                case 't':  emit_byte = '\t'; do_emit_byte = 1; advance(c, e, ew); break;
                case 'r':  emit_byte = '\r'; do_emit_byte = 1; advance(c, e, ew); break;
                case '0':  emit_byte = '\0'; do_emit_byte = 1; advance(c, e, ew); break;
                case 'x': {
                    advance(c, e, ew);
                    uint8_t b;
                    if (!scan_hex_byte(st, &b) || b > 0x7F) {
                        record_error(st, IIIE_STR_003_INVALID_ESCAPE, (uint32_t)c->pos, c->line, c->col,
                                     "invalid \\x escape (must be 2 hex digits, value <= 0x7F)");
                        free(buf); return -1;
                    }
                    emit_byte = b; do_emit_byte = 1;
                    break;
                }
                case 'u': {
                    advance(c, e, ew);
                    uint32_t k; int kw;
                    if (!peek_cp(c, &k, &kw) || k != '{') {
                        record_error(st, IIIE_STR_003_INVALID_ESCAPE, (uint32_t)c->pos, c->line, c->col,
                                     "invalid \\u escape (expected '{')");
                        free(buf); return -1;
                    }
                    advance(c, k, kw);
                    uint32_t v = 0; int n = 0;
                    while (c->pos < c->len) {
                        uint32_t hk; int hkw;
                        peek_cp(c, &hk, &hkw);
                        if (hk == '}') { advance(c, hk, hkw); break; }
                        int d = hex_val(hk);
                        if (d < 0 || n >= 6) {
                            record_error(st, IIIE_STR_003_INVALID_ESCAPE, (uint32_t)c->pos, c->line, c->col,
                                         "invalid \\u{...} escape");
                            free(buf); return -1;
                        }
                        v = (v << 4) | (uint32_t)d;
                        n++; advance(c, hk, hkw);
                    }
                    if (n == 0 || v > 0x10FFFF || (v >= 0xD800 && v <= 0xDFFF)) {
                        record_error(st, IIIE_STR_003_INVALID_ESCAPE, (uint32_t)c->pos, c->line, c->col,
                                     "invalid \\u{...} codepoint");
                        free(buf); return -1;
                    }
                    emit_cp = v; do_emit_cp = 1;
                    break;
                }
                default:
                    record_error(st, IIIE_STR_003_INVALID_ESCAPE, (uint32_t)c->pos, c->line, c->col,
                                 "unknown escape \\%c", (int)e);
                    free(buf); return -1;
            }
            if (do_emit_byte) {
                if (len + 1 > cap) { cap *= 2; buf = (uint8_t *)realloc(buf, cap); }
                buf[len++] = emit_byte;
            }
            if (do_emit_cp) {
                uint8_t tmp[4]; int tw = iii_utf8_encode(emit_cp, tmp);
                if (len + (size_t)tw > cap) { while (len + (size_t)tw > cap) cap *= 2; buf = (uint8_t *)realloc(buf, cap); }
                for (int i = 0; i < tw; i++) buf[len++] = tmp[i];
            }
            continue;
        }
        /* literal codepoint */
        if (len + (size_t)w > cap) { while (len + (size_t)w > cap) cap *= 2; buf = (uint8_t *)realloc(buf, cap); }
        for (int i = 0; i < w; i++) buf[len++] = c->src[c->pos + i];
        advance(c, cp, w);
    }
    record_error(st, IIIE_STR_004_UNTERMINATED, (uint32_t)start, sline, scol, "unterminated string literal");
    free(buf); return -1;
}

static int scan_byte_string_lit(iii_lex_state_t *st, iii_token_t *out) {
    cursor_t *c = &st->c;
    size_t start = c->pos;
    uint32_t sline = c->line, scol = c->col;
    advance(c, 'b', 1); /* consume 'b' */
    advance(c, '"', 1); /* consume '"' */
    size_t cap = 64, len = 0;
    uint8_t *buf = (uint8_t *)malloc(cap);
    while (c->pos < c->len) {
        uint8_t b = c->src[c->pos];
        if (b == '"') {
            advance(c, '"', 1);
            uint8_t *payload = (uint8_t *)iii_arena_alloc(&st->arena, len + 1, 1);
            memcpy(payload, buf, len); payload[len] = 0;
            free(buf);
            out->kind = IIIK_BYTE_STRING_LIT;
            out->text_offset = (uint32_t)start;
            out->text_len = (uint32_t)(c->pos - start);
            out->line = sline; out->col = scol;
            out->string_payload = payload; out->string_len = len;
            out->interned_id = iii_intern_put(&st->intern, payload, len);
            return 0;
        }
        if (b == '\n') {
            record_error(st, IIIE_STR_001_UNESCAPED_NEWLINE, (uint32_t)c->pos, c->line, c->col,
                         "unescaped newline in byte-string");
            free(buf); return -1;
        }
        if (b > 0x7E || b < 0x20) {
            record_error(st, IIIE_ENC_008_RAW_FORBIDDEN_IN_STRING, (uint32_t)c->pos, c->line, c->col,
                         "non-printable byte in byte-string");
            free(buf); return -1;
        }
        if (b == '\\') {
            advance(c, '\\', 1);
            if (c->pos >= c->len) { record_error(st, IIIE_STR_004_UNTERMINATED, (uint32_t)c->pos, c->line, c->col, "trailing backslash"); free(buf); return -1; }
            uint8_t e = c->src[c->pos];
            uint8_t emit = 0; int has = 1;
            switch (e) {
                case '\\': emit = '\\'; advance(c, '\\', 1); break;
                case '"':  emit = '"';  advance(c, '"', 1); break;
                case 'n':  emit = '\n'; advance(c, 'n', 1); break;
                case 't':  emit = '\t'; advance(c, 't', 1); break;
                case 'r':  emit = '\r'; advance(c, 'r', 1); break;
                case '0':  emit = 0;    advance(c, '0', 1); break;
                case 'x': {
                    advance(c, 'x', 1);
                    uint8_t bb;
                    if (!scan_hex_byte(st, &bb)) {
                        record_error(st, IIIE_STR_003_INVALID_ESCAPE, (uint32_t)c->pos, c->line, c->col, "bad \\x escape");
                        free(buf); return -1;
                    }
                    emit = bb; break;
                }
                default:
                    record_error(st, IIIE_STR_003_INVALID_ESCAPE, (uint32_t)c->pos, c->line, c->col,
                                 "unknown byte-string escape \\%c", (int)e);
                    free(buf); return -1;
            }
            if (has) {
                if (len + 1 > cap) { cap *= 2; buf = (uint8_t *)realloc(buf, cap); }
                buf[len++] = emit;
            }
            continue;
        }
        if (len + 1 > cap) { cap *= 2; buf = (uint8_t *)realloc(buf, cap); }
        buf[len++] = b;
        advance(c, b, 1);
    }
    record_error(st, IIIE_STR_004_UNTERMINATED, (uint32_t)start, sline, scol, "unterminated byte-string literal");
    free(buf); return -1;
}

static int scan_raw_string_lit(iii_lex_state_t *st, iii_token_t *out) {
    cursor_t *c = &st->c;
    size_t start = c->pos;
    uint32_t sline = c->line, scol = c->col;
    advance(c, 'r', 1); /* 'r' */
    int hashes = 0;
    while (c->pos < c->len && c->src[c->pos] == '#') { hashes++; advance(c, '#', 1); }
    if (c->pos >= c->len || c->src[c->pos] != '"') {
        record_error(st, IIIE_STR_004_UNTERMINATED, (uint32_t)start, sline, scol, "raw string missing opening quote");
        return -1;
    }
    advance(c, '"', 1);
    size_t body_start = c->pos;
    size_t body_end = (size_t)-1;
    while (c->pos < c->len) {
        uint8_t b = c->src[c->pos];
        if (b == 0x0D) {
            record_error(st, IIIE_ENC_002_CR, (uint32_t)c->pos, c->line, c->col, "CR forbidden in raw string");
            return -1;
        }
        if (b == '"') {
            int ok = 1;
            for (int i = 0; i < hashes; i++) {
                if (c->pos + 1 + (size_t)i >= c->len || c->src[c->pos + 1 + (size_t)i] != '#') { ok = 0; break; }
            }
            if (ok) {
                body_end = c->pos;
                advance(c, '"', 1);
                for (int i = 0; i < hashes; i++) advance(c, '#', 1);
                break;
            }
        }
        if (b == '\n') { advance(c, '\n', 1); continue; }
        /* Need to advance one codepoint */
        uint32_t cp; int w;
        if (!peek_cp(c, &cp, &w)) {
            record_error(st, IIIE_ENC_006_INVALID_UTF8, (uint32_t)c->pos, c->line, c->col, "invalid UTF-8 in raw string");
            return -1;
        }
        advance(c, cp, w);
    }
    if (body_end == (size_t)-1) {
        record_error(st, IIIE_STR_004_UNTERMINATED, (uint32_t)start, sline, scol, "unterminated raw string literal");
        return -1;
    }
    size_t blen = body_end - body_start;
    uint8_t *payload = (uint8_t *)iii_arena_alloc(&st->arena, blen + 1, 1);
    if (blen) memcpy(payload, c->src + body_start, blen);
    payload[blen] = 0;
    out->kind = IIIK_RAW_STRING_LIT;
    out->text_offset = (uint32_t)start;
    out->text_len = (uint32_t)(c->pos - start);
    out->line = sline; out->col = scol;
    out->string_payload = payload; out->string_len = blen;
    out->interned_id = iii_intern_put(&st->intern, payload, blen);
    return 0;
}

static int scan_hex_string_lit(iii_lex_state_t *st, iii_token_t *out) {
    cursor_t *c = &st->c;
    size_t start = c->pos;
    uint32_t sline = c->line, scol = c->col;
    advance(c, 'h', 1); advance(c, '"', 1);
    size_t cap = 64, len = 0;
    uint8_t *buf = (uint8_t *)malloc(cap);
    int nibble = -1;
    while (c->pos < c->len) {
        uint8_t b = c->src[c->pos];
        if (b == '"') {
            advance(c, '"', 1);
            if (nibble != -1) {
                record_error(st, IIIE_STR_002_ODD_HEX, (uint32_t)c->pos, c->line, c->col, "odd-length hex string");
                free(buf); return -1;
            }
            uint8_t *payload = (uint8_t *)iii_arena_alloc(&st->arena, len + 1, 1);
            memcpy(payload, buf, len); payload[len] = 0;
            free(buf);
            out->kind = IIIK_HEX_STRING_LIT;
            out->text_offset = (uint32_t)start;
            out->text_len = (uint32_t)(c->pos - start);
            out->line = sline; out->col = scol;
            out->string_payload = payload; out->string_len = len;
            out->interned_id = iii_intern_put(&st->intern, payload, len);
            return 0;
        }
        if (b == ' ' || b == '\t' || b == '\n') { advance(c, b, 1); continue; }
        int d = hex_val((uint32_t)b);
        if (d < 0) {
            record_error(st, IIIE_STR_003_INVALID_ESCAPE, (uint32_t)c->pos, c->line, c->col,
                         "invalid hex digit in hex-string");
            free(buf); return -1;
        }
        if (nibble < 0) nibble = d;
        else {
            if (len + 1 > cap) { cap *= 2; buf = (uint8_t *)realloc(buf, cap); }
            buf[len++] = (uint8_t)((nibble << 4) | d);
            nibble = -1;
        }
        advance(c, b, 1);
    }
    record_error(st, IIIE_STR_004_UNTERMINATED, (uint32_t)start, sline, scol, "unterminated hex string literal");
    free(buf); return -1;
}

/* ===== Number scanner ===================================================== */

static int scan_number(iii_lex_state_t *st, iii_token_t *out) {
    cursor_t *c = &st->c;
    size_t start = c->pos;
    uint32_t sline = c->line, scol = c->col;

    int radix = 10;
    int has_prefix = 0;
    if (c->src[c->pos] == '0' && c->pos + 1 < c->len) {
        uint8_t n = c->src[c->pos + 1];
        if (n == 'x' || n == 'X') { radix = 16; has_prefix = 1; advance(c, '0', 1); advance(c, n, 1); }
        else if (n == 'b' || n == 'B') { radix = 2; has_prefix = 1; advance(c, '0', 1); advance(c, n, 1); }
        else if (n == 'o' || n == 'O') { radix = 8; has_prefix = 1; advance(c, '0', 1); advance(c, n, 1); }
    }
    if (has_prefix && c->pos < c->len && c->src[c->pos] == '_') {
        record_error(st, IIIE_INT_001_USCORE_AFTER_PREFIX, (uint32_t)c->pos, c->line, c->col,
                     "underscore immediately after radix prefix");
    }
    size_t digits_start = c->pos;
    int saw_digit = 0;
    int has_underscore = 0;
    while (c->pos < c->len) {
        uint8_t b = c->src[c->pos];
        int ok;
        if (radix == 16) ok = (hex_val(b) >= 0);
        else if (radix == 2) ok = (b == '0' || b == '1');
        else if (radix == 8) ok = (b >= '0' && b <= '7');
        else ok = (b >= '0' && b <= '9');
        if (ok) { saw_digit = 1; advance(c, b, 1); continue; }
        if (b == '_') {
            has_underscore = 1;
            if (!saw_digit && !has_prefix) {
                record_error(st, IIIE_INT_002_USCORE_AT_START, (uint32_t)c->pos, c->line, c->col,
                             "underscore at start of integer literal");
            }
            advance(c, '_', 1); continue;
        }
        break;
    }
    size_t digits_end = c->pos;

    /* Q14 frac form: int.frac  (only for decimal) */
    int q14_frac = 0;
    size_t frac_start = 0, frac_end = 0;
    if (radix == 10 && c->pos < c->len && c->src[c->pos] == '.' &&
        c->pos + 1 < c->len && is_ascii_digit(c->src[c->pos + 1])) {
        advance(c, '.', 1);
        frac_start = c->pos;
        while (c->pos < c->len && (is_ascii_digit(c->src[c->pos]) || c->src[c->pos] == '_')) {
            advance(c, c->src[c->pos], 1);
        }
        frac_end = c->pos;
        q14_frac = 1;
    }

    /* Q14 ratio form: int/int  (only when followed by q/q14 suffix). */
    int q14_ratio = 0;
    size_t ratio_start = 0, ratio_end = 0;
    cursor_t before_ratio = *c;
    if (!q14_frac && radix == 10 && c->pos < c->len && c->src[c->pos] == '/' &&
        c->pos + 1 < c->len && is_ascii_digit(c->src[c->pos + 1])) {
        advance(c, '/', 1);
        ratio_start = c->pos;
        while (c->pos < c->len && (is_ascii_digit(c->src[c->pos]) || c->src[c->pos] == '_')) {
            advance(c, c->src[c->pos], 1);
        }
        ratio_end = c->pos;
        /* Need q or q14 suffix immediately after. */
        if (c->pos < c->len && c->src[c->pos] == 'q') {
            q14_ratio = 1;
        } else {
            /* rewind */
            *c = before_ratio;
        }
    }

    /* Suffix scan */
    if (c->pos < c->len && c->src[c->pos] == '_') {
        record_error(st, IIIE_INT_003_USCORE_BEFORE_SUFFIX, (uint32_t)c->pos, c->line, c->col,
                     "underscore immediately before suffix");
        while (c->pos < c->len && c->src[c->pos] == '_') advance(c, '_', 1);
    } else if (c->pos > 0 && c->pos < c->len && c->src[c->pos - 1] == '_'
               && is_ascii_alpha(c->src[c->pos])) {
        /* Trailing underscore in the digit/frac/ratio scan immediately followed by
         * a suffix-introducing alpha char.  Spec INT-003. */
        record_error(st, IIIE_INT_003_USCORE_BEFORE_SUFFIX, (uint32_t)(c->pos - 1), c->line, c->col,
                     "underscore immediately before suffix");
    }
    size_t suffix_start = c->pos;
    while (c->pos < c->len && (is_ascii_alpha(c->src[c->pos]) || is_ascii_digit(c->src[c->pos]))) {
        advance(c, c->src[c->pos], 1);
    }
    size_t suffix_end = c->pos;
    iii_int_suffix_t suf = parse_suffix(c->src + suffix_start, suffix_end - suffix_start);

    memset(out, 0, sizeof(*out));
    out->text_offset = (uint32_t)start;
    out->text_len = (uint32_t)(c->pos - start);
    out->line = sline; out->col = scol;

    /* Decide kind. */
    /* MHASH: hex with no underscore and exactly 64 hex digits in body. */
    if (radix == 16 && !has_underscore && (digits_end - digits_start) == 64 && suf == IIIS_NONE) {
        out->kind = IIIK_MHASH_LIT;
        for (int i = 0; i < 32; i++) {
            int hi = hex_val(c->src[digits_start + (size_t)(i * 2)]);
            int lo = hex_val(c->src[digits_start + (size_t)(i * 2 + 1)]);
            out->mhash_value[i] = (uint8_t)((hi << 4) | lo);
        }
        out->interned_id = iii_intern_put(&st->intern, c->src + start, c->pos - start);
        return 0;
    }

    /* Q14 forms */
    if (q14_frac) {
        /* compute rounded(value * 16384) */
        uint64_t whole = 0;
        if (parse_radix_value(c->src + digits_start, digits_end - digits_start, 10, &whole, NULL) != 0) {
            record_error(st, IIIE_INT_004_OVERFLOW, (uint32_t)start, sline, scol, "Q14 whole part too large");
        }
        /* Read frac as unsigned digits and divisor */
        uint64_t frac_num = 0, frac_div = 1;
        for (size_t i = frac_start; i < frac_end; i++) {
            uint8_t b = c->src[i];
            if (b == '_') continue;
            frac_num = frac_num * 10 + (uint64_t)(b - '0');
            frac_div *= 10;
        }
        /* value = whole + frac_num/frac_div ; q = round(value * 16384) */
        /* q = (whole*16384*frac_div + frac_num*16384 + frac_div/2) / frac_div */
        uint64_t numer = whole * 16384ull * frac_div + frac_num * 16384ull + frac_div / 2;
        uint64_t qv = numer / frac_div;
        if (qv > 0x7FFFu) {
            record_error(st, IIIE_Q14_001_OUT_OF_RANGE, (uint32_t)start, sline, scol,
                         "Q14 literal exceeds range");
        }
        out->kind = IIIK_Q14_LIT;
        out->int_value = qv & 0xFFFFu;
        out->int_suffix = (uint8_t)(suf == IIIS_Q14 ? IIIS_Q14 : IIIS_Q);
        if (suf != IIIS_Q && suf != IIIS_Q14) {
            record_error(st, IIIE_Q14_001_OUT_OF_RANGE, (uint32_t)start, sline, scol,
                         "Q14 literal requires q or q14 suffix");
        }
        out->interned_id = iii_intern_put(&st->intern, c->src + start, c->pos - start);
        return 0;
    }
    if (q14_ratio) {
        uint64_t num = 0, den = 0;
        parse_radix_value(c->src + digits_start, digits_end - digits_start, 10, &num, NULL);
        parse_radix_value(c->src + ratio_start, ratio_end - ratio_start, 10, &den, NULL);
        if (den == 0) {
            record_error(st, IIIE_Q14_001_OUT_OF_RANGE, (uint32_t)start, sline, scol, "Q14 ratio div-by-zero");
            out->kind = IIIK_Q14_LIT;
        } else {
            uint64_t qv = (num * 16384ull + den / 2) / den;
            if (qv > 0x7FFFu) {
                record_error(st, IIIE_Q14_001_OUT_OF_RANGE, (uint32_t)start, sline, scol,
                             "Q14 literal exceeds range");
            }
            out->kind = IIIK_Q14_LIT;
            out->int_value = qv & 0xFFFFu;
            out->int_suffix = (uint8_t)(suf == IIIS_Q14 ? IIIS_Q14 : IIIS_Q);
        }
        out->interned_id = iii_intern_put(&st->intern, c->src + start, c->pos - start);
        return 0;
    }
    if (suf == IIIS_Q || suf == IIIS_Q14) {
        uint64_t v = 0;
        if (parse_radix_value(c->src + digits_start, digits_end - digits_start, radix, &v, NULL) != 0) {
            record_error(st, IIIE_INT_004_OVERFLOW, (uint32_t)start, sline, scol, "Q14 base overflow");
        }
        uint64_t qv = v * 16384ull;
        if (qv > 0x7FFFu) {
            record_error(st, IIIE_Q14_001_OUT_OF_RANGE, (uint32_t)start, sline, scol, "Q14 literal exceeds range");
        }
        out->kind = IIIK_Q14_LIT;
        out->int_value = qv & 0xFFFFu;
        out->int_suffix = (uint8_t)suf;
        out->interned_id = iii_intern_put(&st->intern, c->src + start, c->pos - start);
        return 0;
    }

    /* Trit suffix */
    if (suf == IIIS_T || suf == IIIS_TN || suf == IIIS_TZ || suf == IIIS_TP) {
        out->kind = IIIK_TRIT_LIT;
        int64_t v;
        if (suf == IIIS_T) {
            /* numeric form: "0t" = ZERO, "1t" = POS.  Decimal digits only. */
            uint64_t u = 0;
            parse_radix_value(c->src + digits_start, digits_end - digits_start, radix, &u, NULL);
            if (u == 0) v = 0;
            else if (u == 1) v = 1;
            else { record_error(st, IIIE_INT_004_OVERFLOW, (uint32_t)start, sline, scol, "trit numeric form must be 0 or 1"); v = 0; }
        } else if (suf == IIIS_TN) v = -1;
        else if (suf == IIIS_TZ) v = 0;
        else v = 1;
        out->int_value = (uint64_t)v;
        out->int_suffix = (uint8_t)suf;
        out->interned_id = iii_intern_put(&st->intern, c->src + start, c->pos - start);
        return 0;
    }

    /* Plain integer */
    uint64_t v = 0;
    if (saw_digit && parse_radix_value(c->src + digits_start, digits_end - digits_start, radix, &v, NULL) != 0) {
        record_error(st, IIIE_INT_004_OVERFLOW, (uint32_t)start, sline, scol, "integer literal overflow");
    }
    if (suf != IIIS_NONE && !suffix_fits(suf, v)) {
        record_error(st, IIIE_INT_004_OVERFLOW, (uint32_t)start, sline, scol, "literal exceeds suffix range");
    }
    out->kind = IIIK_INT_LIT;
    out->int_value = v;
    out->int_suffix = (uint8_t)suf;
    out->interned_id = iii_intern_put(&st->intern, c->src + start, c->pos - start);
    return 0;
}

/* ===== Modifier scan (after seeing '@') =================================== */

static int scan_modifier(iii_lex_state_t *st, iii_token_t *out) {
    cursor_t *c = &st->c;
    size_t start = c->pos;
    uint32_t sline = c->line, scol = c->col;
    advance(c, '@', 1);
    while (c->pos < c->len) {
        uint8_t b = c->src[c->pos];
        if (is_ascii_alpha((uint32_t)b) || is_ascii_digit((uint32_t)b) || b == '_') {
            advance(c, b, 1);
        } else break;
    }
    size_t L = c->pos - start;
    int id = iii_lex_modifier_id(c->src + start, L);
    memset(out, 0, sizeof(*out));
    out->text_offset = (uint32_t)start;
    out->text_len = (uint32_t)L;
    out->line = sline; out->col = scol;
    out->kind = IIIK_MODIFIER;
    out->interned_id = iii_intern_put(&st->intern, c->src + start, L);
    if (id == 0) {
        record_error(st, IIIE_OP_001_NON_CANONICAL, (uint32_t)start, sline, scol,
                     "unrecognized modifier");
    }
    out->int_value = (uint64_t)(id > 0 ? id : 0);
    return 0;
}

/* ===== Main next-token routine ============================================ */

static int next_token(iii_lex_state_t *st, iii_token_t *out) {
    cursor_t *c = &st->c;

    /* Skip whitespace and comments, possibly emitting DOC_COMMENT. */
    for (;;) {
        if (c->pos >= c->len) {
            memset(out, 0, sizeof(*out));
            out->kind = IIIK_EOF;
            out->text_offset = (uint32_t)c->pos;
            out->line = c->line; out->col = c->col;
            return 0;
        }
        iii_token_t doc;
        int emitted = 0;
        int r = skip_one_ws_or_comment(st, &doc, &emitted);
        if (r == 1) break;        /* not whitespace/comment — proceed to lex */
        if (r == -1) {
            memset(out, 0, sizeof(*out));
            out->kind = IIIK_EOF;
            out->text_offset = (uint32_t)c->pos;
            out->line = c->line; out->col = c->col;
            return 0;
        }
        if (emitted) { *out = doc; return 1; }
        /* r == 0 (consumed) or -2 (error already recorded), continue */
    }

    /* Now positioned at start of a token. */
    size_t start = c->pos;
    uint32_t sline = c->line, scol = c->col;
    uint32_t cp; int w;
    if (!peek_cp(c, &cp, &w)) {
        record_error(st, IIIE_ENC_006_INVALID_UTF8, (uint32_t)c->pos, c->line, c->col, "invalid UTF-8");
        c->pos++; c->col++;
        return -1;
    }

    /* Identifier-like / b" r" h" / keywords / NEG-ZERO-POS. */
    if (is_id_start(cp) || (cp == 'm' && c->pos + 1 < c->len && c->src[c->pos+1] == 0xC3)) {
        /* Check b"/r"/h" prefixed strings: the 'b','r','h' followed immediately by '"'
         * (or '#' for raw) and not by an id_continue. */
        if (cp == 'b' && c->pos + 1 < c->len && c->src[c->pos+1] == '"') {
            return scan_byte_string_lit(st, out) == 0 ? 1 : -1;
        }
        if (cp == 'r' && c->pos + 1 < c->len && (c->src[c->pos+1] == '"' || c->src[c->pos+1] == '#')) {
            return scan_raw_string_lit(st, out) == 0 ? 1 : -1;
        }
        if (cp == 'h' && c->pos + 1 < c->len && c->src[c->pos+1] == '"') {
            return scan_hex_string_lit(st, out) == 0 ? 1 : -1;
        }
        size_t end;
        scan_identifier(st, &end);
        size_t L = end - start;
        memset(out, 0, sizeof(*out));
        out->text_offset = (uint32_t)start;
        out->text_len = (uint32_t)L;
        out->line = sline; out->col = scol;
        /* Bare _: PUNCT */
        if (L == 1 && c->src[start] == '_') {
            out->kind = IIIK_PUNCT;
            out->interned_id = iii_intern_put(&st->intern, (const uint8_t *)"_", 1);
            return 1;
        }
        /* __ prefix: LEX-ID-003 */
        if (L >= 2 && c->src[start] == '_' && c->src[start+1] == '_') {
            record_error(st, IIIE_ID_003_RESERVED_DOUBLE_UNDERSCORE, (uint32_t)start, sline, scol,
                         "reserved double-underscore identifier");
        }
        /* Length check */
        if (L > 256) {
            record_error(st, IIIE_ID_002_IDENT_TOO_LONG, (uint32_t)start, sline, scol,
                         "identifier exceeds 256-codepoint limit");
        }
        /* NEG / ZERO / POS → TRIT_LIT */
        if (L == 3 && (memcmp(c->src + start, "NEG", 3) == 0 || memcmp(c->src + start, "POS", 3) == 0)) {
            out->kind = IIIK_TRIT_LIT;
            out->int_value = (memcmp(c->src + start, "NEG", 3) == 0) ? (uint64_t)(int64_t)-1 : 1u;
            out->interned_id = iii_intern_put(&st->intern, c->src + start, L);
            return 1;
        }
        if (L == 4 && memcmp(c->src + start, "ZERO", 4) == 0) {
            out->kind = IIIK_TRIT_LIT;
            out->int_value = 0;
            out->interned_id = iii_intern_put(&st->intern, c->src + start, L);
            return 1;
        }
        /* Keyword check */
        if (iii_lex_is_keyword(c->src + start, L)) {
            out->kind = IIIK_KEYWORD;
            out->interned_id = iii_intern_put(&st->intern, c->src + start, L);
            return 1;
        }
        /* Catalyst reserved slot */
        if (iii_lex_is_reserved_slot(c->src + start, L)) {
            record_error(st, IIIE_ID_005_RESERVED_CATALYST_SLOT, (uint32_t)start, sline, scol,
                         "reserved Catalyst slot name");
        }
        out->kind = IIIK_IDENT;
        out->interned_id = iii_intern_put(&st->intern, c->src + start, L);
        return 1;
    }

    /* Digit → number (might be MHASH/Q14/INT/TRIT) */
    if (is_ascii_digit(cp)) {
        int rc = scan_number(st, out);
        return (rc == 0) ? 1 : -1;
    }

    /* '"' → STRING_LIT */
    if (cp == '"') {
        return scan_string_lit(st, out) == 0 ? 1 : -1;
    }

    /* '@' → MODIFIER */
    if (cp == '@') {
        return scan_modifier(st, out) == 0 ? 1 : -1;
    }

    /* '(' — possible HEXAD lookahead */
    if (cp == '(') {
        uint16_t packed; size_t end;
        if (try_scan_hexad(st, &packed, &end)) {
            memset(out, 0, sizeof(*out));
            out->kind = IIIK_HEXAD_LIT;
            out->text_offset = (uint32_t)start;
            out->text_len = (uint32_t)(end - start);
            out->line = sline; out->col = scol;
            out->hexad_packed = packed;
            out->interned_id = iii_intern_put(&st->intern, c->src + start, end - start);
            return 1;
        }
        /* fallthrough: emit '(' PUNCT */
    }

    /* '+' or '-' — possibly trit literal -1t / +1t */
    if (cp == '+' || cp == '-') {
        if (c->pos + 3 <= c->len && c->src[c->pos+1] == '1' && c->src[c->pos+2] == 't') {
            uint32_t after = (c->pos + 3 < c->len) ? (uint32_t)c->src[c->pos+3] : 0;
            if (after == 0 || !is_id_cont(after)) {
                memset(out, 0, sizeof(*out));
                out->kind = IIIK_TRIT_LIT;
                out->text_offset = (uint32_t)start;
                out->text_len = 3;
                out->line = sline; out->col = scol;
                out->int_value = (cp == '-') ? (uint64_t)(int64_t)-1 : 1u;
                out->int_suffix = (uint8_t)IIIS_T;
                advance(c, cp, 1); advance(c, '1', 1); advance(c, 't', 1);
                out->interned_id = iii_intern_put(&st->intern, c->src + start, 3);
                return 1;
            }
        }
        /* Recognize as PUNCT */
        if (cp == '-' && c->pos + 1 < c->len && c->src[c->pos+1] == '>') {
            advance(c, '-', 1); advance(c, '>', 1);
            memset(out, 0, sizeof(*out));
            out->kind = IIIK_PUNCT;
            out->text_offset = (uint32_t)start; out->text_len = 2;
            out->line = sline; out->col = scol;
            out->interned_id = iii_intern_put(&st->intern, (const uint8_t *)"->", 2);
            return 1;
        }
        advance(c, cp, 1);
        memset(out, 0, sizeof(*out));
        out->kind = IIIK_PUNCT;
        out->text_offset = (uint32_t)start; out->text_len = 1;
        out->line = sline; out->col = scol;
        out->interned_id = iii_intern_put(&st->intern, c->src + start, 1);
        return 1;
    }

    /* Reserved: $ → LEX-PUNCT-001 */
    if (cp == '$') {
        record_error(st, IIIE_PUNCT_001_RESERVED_DOLLAR, (uint32_t)start, sline, scol,
                     "reserved character $ in user source");
        advance(c, cp, 1);
        return -1;
    }
    /* Reserved: ^ ~ ' ` → LEX-PUNCT-002 */
    if (cp == '^' || cp == '~' || cp == '\'' || cp == '`') {
        record_error(st, IIIE_PUNCT_002_RESERVED_PENDING, (uint32_t)start, sline, scol,
                     "reserved character — slot pending Catalyst promotion");
        advance(c, cp, 1);
        return -1;
    }

    /* Forbidden controls (outside strings) */
    if (is_forbidden_ctrl(cp)) {
        record_error(st, IIIE_ENC_007_FORBIDDEN_CTRL, (uint32_t)start, sline, scol,
                     "forbidden control codepoint U+%04X", cp);
        advance(c, cp, w);
        return -1;
    }

    /* Multi-char ASCII punctuators */
    /* Maximal munch: ::, .., ==, !=, ->, =>, then singletons */
    if (cp == ':' && c->pos + 1 < c->len && c->src[c->pos+1] == ':') {
        advance(c, ':', 1); advance(c, ':', 1);
        memset(out, 0, sizeof(*out));
        out->kind = IIIK_PUNCT;
        out->text_offset = (uint32_t)start; out->text_len = 2;
        out->line = sline; out->col = scol;
        out->interned_id = iii_intern_put(&st->intern, (const uint8_t *)"::", 2);
        return 1;
    }
    if (cp == '.' && c->pos + 1 < c->len && c->src[c->pos+1] == '.') {
        advance(c, '.', 1); advance(c, '.', 1);
        memset(out, 0, sizeof(*out));
        out->kind = IIIK_PUNCT;
        out->text_offset = (uint32_t)start; out->text_len = 2;
        out->line = sline; out->col = scol;
        out->interned_id = iii_intern_put(&st->intern, (const uint8_t *)"..", 2);
        return 1;
    }
    if (cp == '=' && c->pos + 1 < c->len && (c->src[c->pos+1] == '=' || c->src[c->pos+1] == '>')) {
        uint8_t n = c->src[c->pos+1];
        advance(c, '=', 1); advance(c, n, 1);
        memset(out, 0, sizeof(*out));
        out->kind = IIIK_PUNCT;
        out->text_offset = (uint32_t)start; out->text_len = 2;
        out->line = sline; out->col = scol;
        const uint8_t *txt = (n == '=') ? (const uint8_t *)"==" : (const uint8_t *)"=>";
        out->interned_id = iii_intern_put(&st->intern, txt, 2);
        return 1;
    }
    if (cp == '!') {
        if (c->pos + 1 < c->len && c->src[c->pos+1] == '=') {
            advance(c, '!', 1); advance(c, '=', 1);
            memset(out, 0, sizeof(*out));
            out->kind = IIIK_PUNCT;
            out->text_offset = (uint32_t)start; out->text_len = 2;
            out->line = sline; out->col = scol;
            out->interned_id = iii_intern_put(&st->intern, (const uint8_t *)"!=", 2);
            return 1;
        }
        record_error(st, IIIE_OP_001_NON_CANONICAL, (uint32_t)start, sline, scol,
                     "bare '!' is not a recognized token");
        advance(c, cp, w);
        return -1;
    }

    /* Single-codepoint punctuators */
    if (iii_lex_is_punct_start(cp)) {
        advance(c, cp, w);
        memset(out, 0, sizeof(*out));
        out->kind = IIIK_PUNCT;
        out->text_offset = (uint32_t)start; out->text_len = (uint32_t)w;
        out->line = sline; out->col = scol;
        out->interned_id = iii_intern_put(&st->intern, c->src + start, (size_t)w);
        return 1;
    }

    /* Operators (single or doubled per maximal munch). */
    int single_id = iii_lex_operator_single(cp);
    if (single_id != 0) {
        /* try double: peek next codepoint */
        uint32_t cp2; int w2;
        peek_cp_at(c, (size_t)w, &cp2, &w2);
        int dbl_id = (cp2 != 0) ? iii_lex_operator_double(cp, cp2) : 0;
        advance(c, cp, w);
        if (dbl_id != 0) advance(c, cp2, w2);
        memset(out, 0, sizeof(*out));
        out->kind = IIIK_OPERATOR;
        out->text_offset = (uint32_t)start;
        out->text_len = (uint32_t)(c->pos - start);
        out->line = sline; out->col = scol;
        out->interned_id = iii_intern_put(&st->intern, c->src + start, c->pos - start);
        out->int_value = (uint64_t)(dbl_id != 0 ? dbl_id : single_id);
        return 1;
    }

    /* Anything else: non-canonical / unrecognized */
    record_error(st, IIIE_OP_001_NON_CANONICAL, (uint32_t)start, sline, scol,
                 "non-canonical / unrecognized codepoint U+%04X", cp);
    advance(c, cp, w);
    return -1;
}

/* ===== Public API ========================================================= */

iii_lex_state_t *iii_lex_create(const uint8_t *src, size_t len, const char *path) {
    iii_lex_state_t *st = (iii_lex_state_t *)calloc(1, sizeof(*st));
    if (!st) return NULL;
    st->c.src = src; st->c.len = len; st->c.pos = 0;
    st->c.line = 1; st->c.col = 1;
    st->path = path;
    iii_arena_init(&st->arena);
    iii_intern_init(&st->intern, &st->arena);
    return st;
}

void iii_lex_destroy(iii_lex_state_t *st) {
    if (!st) return;
    iii_intern_destroy(&st->intern);
    iii_arena_destroy(&st->arena);
    free(st->errors);
    free(st);
}

int iii_lex_next(iii_lex_state_t *st, iii_token_t *out) {
    if (st->has_peek) {
        *out = st->peek;
        st->has_peek = 0;
        return out->kind == IIIK_EOF ? 0 : 1;
    }
    int r = next_token(st, out);
    if (r == -1) {
        /* Recover: try the next token. */
        if (out->kind == IIIK_INVALID && st->c.pos < st->c.len) {
            return -1;
        }
        return -1;
    }
    return out->kind == IIIK_EOF ? 0 : 1;
}

int iii_lex_peek(iii_lex_state_t *st, iii_token_t *out) {
    if (!st->has_peek) {
        int r = next_token(st, &st->peek);
        if (r == -1) return -1;
        st->has_peek = 1;
    }
    *out = st->peek;
    return st->peek.kind == IIIK_EOF ? 0 : 1;
}

const iii_lex_error_t *iii_lex_last_error(const iii_lex_state_t *st) {
    if (st->errs_len == 0) return NULL;
    return &st->errors[st->errs_len - 1];
}

size_t iii_lex_error_count(const iii_lex_state_t *st) { return st->errs_len; }

const iii_lex_error_t *iii_lex_error_at(const iii_lex_state_t *st, size_t i) {
    if (i >= st->errs_len) return NULL;
    return &st->errors[i];
}

const char *iii_lex_intern_text(const iii_lex_state_t *st, uint32_t id, size_t *out_len) {
    return (const char *)iii_intern_get(&st->intern, id, out_len);
}

uint32_t iii_lex_intern(iii_lex_state_t *st, const char *text, size_t len) {
    return iii_intern_put(&st->intern, (const uint8_t *)text, len);
}

void iii_sha256_hex(const uint8_t in[32], char out[65]) {
    static const char *h = "0123456789abcdef";
    for (int i = 0; i < 32; i++) {
        out[i*2]   = h[(in[i] >> 4) & 0xF];
        out[i*2+1] = h[in[i] & 0xF];
    }
    out[64] = 0;
}
