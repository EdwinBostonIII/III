/* III Grammar — parser lifecycle, token ring buffer, error log,
 * expect_*() primitives.
 *
 * Newlines, whitespace and unknown error tokens are filtered by the
 * lexer itself.  At the parser level we additionally drop DOC_COMMENT
 * tokens after stashing the most recent one in pending_doc_offset
 * (cleared when consumed by an item — Wave 2 owns the consumption).
 */
#include "parse_internal.h"

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdarg.h>

#define ERR_INIT_CAP 16u

/* ---- Internal helpers ------------------------------------------------- */

static int err_grow(iii_parser_t *p) {
    size_t nc = p->err_cap ? p->err_cap * 2u : ERR_INIT_CAP;
    iii_parse_error_t *ne = (iii_parse_error_t *)realloc(
        p->errors, nc * sizeof(*ne));
    if (!ne) return -1;
    p->errors = ne;
    p->err_cap = nc;
    return 0;
}

/* Pull one raw token from the lex state. */
static int lex_pull_one(iii_parser_t *p, iii_token_t *out) {
    int rc = iii_lex_next(p->lex, out);
    if (rc < 0) {
        const iii_lex_error_t *e = iii_lex_last_error(p->lex);
        uint32_t off  = e ? e->byte_offset : 0;
        uint32_t line = e ? e->line        : 0;
        uint32_t col  = e ? e->col         : 0;
        const char *msg = e ? e->message   : "lex error";
        iiip_record_error(p, P_E_LEX_ERROR, off, off, line, col,
                          "lex: %s", msg);
        return -1;
    }
    return rc;  /* 1 = token, 0 = EOF */
}

/* Pump *one* non-filtered token into the ring buffer.  Returns:
 *   1 on successful append,
 *   0 if EOF reached (EOF token is also placed in the ring),
 *  -1 on hard lex failure (no token appended). */
int iiip_pump(iii_parser_t *p) {
    if (p->ring_count >= IIIP_LOOKAHEAD) return 1; /* already full */
    if (p->hit_eof) {
        /* Re-emit a sticky EOF if we're being asked for more. */
        unsigned slot = (p->ring_head + p->ring_count) % IIIP_LOOKAHEAD;
        memset(&p->ring[slot].tok, 0, sizeof(iii_token_t));
        p->ring[slot].tok.kind = IIIK_EOF;
        p->ring[slot].valid = 1;
        p->ring_count++;
        return 0;
    }

    for (;;) {
        iii_token_t t;
        int rc = lex_pull_one(p, &t);
        if (rc < 0) {
            /* Skip this raw token and try again — recoverable. */
            continue;
        }
        if (rc == 0 || t.kind == IIIK_EOF) {
            p->hit_eof = 1;
            unsigned slot = (p->ring_head + p->ring_count) % IIIP_LOOKAHEAD;
            memset(&p->ring[slot].tok, 0, sizeof(iii_token_t));
            p->ring[slot].tok.kind = IIIK_EOF;
            p->ring[slot].valid = 1;
            p->ring_count++;
            return 0;
        }
        if (t.kind == IIIK_DOC_COMMENT) {
            /* Stash for attachment, then drop. */
            p->pending_doc_offset = t.text_offset;
            continue;
        }
        unsigned slot = (p->ring_head + p->ring_count) % IIIP_LOOKAHEAD;
        p->ring[slot].tok = t;
        p->ring[slot].valid = 1;
        p->ring_count++;
        return 1;
    }
}

const iii_token_t *iiip_peek(iii_parser_t *p, unsigned i) {
    if (i >= IIIP_LOOKAHEAD) return NULL;
    while (p->ring_count <= i) {
        int rc = iiip_pump(p);
        if (rc < 0) continue;        /* recoverable lex error: skip */
        if (rc == 0 && p->ring_count <= i) {
            /* EOF was just appended; check again. */
            if (p->ring_count <= i) {
                /* Need more EOF padding. */
                if (iiip_pump(p) < 0) continue;
            }
        }
    }
    unsigned slot = (p->ring_head + i) % IIIP_LOOKAHEAD;
    return &p->ring[slot].tok;
}

int iiip_consume(iii_parser_t *p, iii_token_t *out_tok) {
    const iii_token_t *t = iiip_peek(p, 0);
    if (!t) return 0;
    if (out_tok) *out_tok = *t;
    if (t->kind == IIIK_EOF) {
        /* Sticky EOF: do not pop. */
        return 0;
    }
    p->ring[p->ring_head].valid = 0;
    p->ring_head = (p->ring_head + 1u) % IIIP_LOOKAHEAD;
    p->ring_count--;
    return 1;
}

/* ---- Error log -------------------------------------------------------- */

void iiip_record_error(iii_parser_t *p, int code,
                       uint32_t span_start, uint32_t span_end,
                       uint32_t line, uint32_t col,
                       const char *fmt, ...) {
    if (!p) return;
    if (p->err_len == p->err_cap) {
        if (err_grow(p) < 0) return;
    }
    iii_parse_error_t *e = &p->errors[p->err_len++];
    memset(e, 0, sizeof(*e));
    e->code       = code;
    e->span_start = span_start;
    e->span_end   = span_end;
    e->line       = line;
    e->col        = col;
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(e->message, sizeof(e->message), fmt, ap);
    va_end(ap);
}

/* ---- Recovery --------------------------------------------------------- */

static bool in_set(iii_pn_e n, const iii_pn_e *set) {
    if (!set) return false;
    for (const iii_pn_e *s = set; *s != IIIPN_COUNT; s++) {
        if (*s == n) return true;
    }
    return false;
}

void iiip_skip_to_recovery(iii_parser_t *p, const iii_pn_e *recover_set) {
    for (;;) {
        const iii_token_t *t = iiip_peek(p, 0);
        if (!t || t->kind == IIIK_EOF) return;
        if (t->kind == IIIK_PUNCT) {
            for (size_t i = 0; i < (size_t)IIIPN_COUNT; i++) {
                if (t->interned_id == p->pn_id[i] &&
                    in_set((iii_pn_e)i, recover_set)) {
                    return;
                }
            }
        }
        iiip_consume(p, NULL);
    }
}

/* ---- expect_*() ------------------------------------------------------- */

static void expect_fail(iii_parser_t *p, int code, const char *what,
                        const iii_token_t *t) {
    uint32_t off  = t ? t->text_offset : 0;
    uint32_t end  = t ? t->text_offset + t->text_len : 0;
    uint32_t line = t ? t->line : 0;
    uint32_t col  = t ? t->col  : 0;
    const char *kn = t ? iii_token_kind_name(t->kind) : "<null>";
    iiip_record_error(p, code, off, end, line, col,
                      "expected %s, found %s", what, kn);
}

bool iiip_expect_kw(iii_parser_t *p, iii_kw_e k, const char *kw_text) {
    const iii_token_t *t = iiip_peek(p, 0);
    if (tok_is_kw(t, p, k)) { iiip_consume(p, NULL); return true; }
    expect_fail(p, P_E_EXPECTED_KEYWORD, kw_text, t);
    return false;
}

bool iiip_expect_pn(iii_parser_t *p, iii_pn_e n, const char *pn_text) {
    const iii_token_t *t = iiip_peek(p, 0);
    if (tok_is_pn(t, p, n)) { iiip_consume(p, NULL); return true; }
    expect_fail(p, P_E_EXPECTED_PUNCT, pn_text, t);
    return false;
}

bool iiip_expect_op(iii_parser_t *p, iii_op_e o, const char *op_text) {
    const iii_token_t *t = iiip_peek(p, 0);
    if (tok_is_op(t, p, o)) { iiip_consume(p, NULL); return true; }
    expect_fail(p, P_E_EXPECTED_OPERATOR, op_text, t);
    return false;
}

bool iiip_expect_word(iii_parser_t *p, const char *s) {
    const iii_token_t *t = iiip_peek(p, 0);
    uint32_t id = iiip_intern_text(p, s);
    if (t && (t->kind == IIIK_IDENT || t->kind == IIIK_KEYWORD) &&
        t->interned_id == id) {
        iiip_consume(p, NULL);
        return true;
    }
    expect_fail(p, P_E_EXPECTED_KEYWORD, s, t);
    return false;
}

bool iiip_expect_ident(iii_parser_t *p, iii_token_t *out) {
    const iii_token_t *t = iiip_peek(p, 0);
    if (t && t->kind == IIIK_IDENT) {
        if (out) *out = *t;
        iiip_consume(p, NULL);
        return true;
    }
    expect_fail(p, P_E_EXPECTED_IDENT, "identifier", t);
    return false;
}

/* ---- Lifecycle -------------------------------------------------------- */

iii_parser_t *iii_parser_create(iii_lex_state_t *lex, iii_arena_t *arena) {
    if (!lex || !arena) return NULL;
    iii_parser_t *p = (iii_parser_t *)calloc(1, sizeof(*p));
    if (!p) return NULL;
    p->lex   = lex;
    p->arena = arena;
    p->ring_head = 0;
    p->ring_count = 0;
    p->hit_eof = 0;
    p->pending_doc_offset = 0xFFFFFFFFu;
    p->errors  = NULL;
    p->err_len = 0;
    p->err_cap = 0;
    p->source     = NULL;
    p->source_len = 0;

    if (iiip_init_keyword_ids(p) < 0) {
        free(p);
        return NULL;
    }
    return p;
}

void iii_parser_destroy(iii_parser_t *p) {
    if (!p) return;
    free(p->errors);
    free(p);
}

size_t iii_parser_error_count(const iii_parser_t *p) {
    return p ? p->err_len : 0;
}

const iii_parse_error_t *iii_parser_error_at(const iii_parser_t *p, size_t i) {
    if (!p || i >= p->err_len) return NULL;
    return &p->errors[i];
}

const uint8_t *iii_parser_source(const iii_parser_t *p, size_t *out_len) {
    if (!p) { if (out_len) *out_len = 0; return NULL; }
    if (out_len) *out_len = p->source_len;
    return p->source;
}

const char *iii_parser_intern(const iii_parser_t *p, uint32_t id, size_t *out_len) {
    if (!p) { if (out_len) *out_len = 0; return NULL; }
    return iii_lex_intern_text(p->lex, id, out_len);
}
