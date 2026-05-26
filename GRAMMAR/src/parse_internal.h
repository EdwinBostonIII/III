/* III Grammar — internal parser state shared across parse_*.c files.
 *
 * NOT a public header.  Wave 2 production files (parse_module.c,
 * parse_decl.c, parse_type.c, parse_stmt.c, parse_expr.c, parse_pat.c,
 * parse_modifier.c) include this header but no client code does.
 *
 * Conventions:
 *   - peek(p, i) returns a pointer into the parser's ring buffer.
 *     The token is valid until the next consume() / peek() at i+1
 *     past the buffer's filled extent.  Newlines, whitespace and
 *     doc-comments are filtered at this level (doc-comments are
 *     captured as `pending_doc_offset` for attachment to the next
 *     item).  EOF is a sticky token: peeking past it always returns
 *     the same EOF token.
 *   - consume(p) advances the cursor by one and returns the token
 *     that *was* current (by value-copy).  After EOF, consume is a
 *     no-op that keeps returning EOF.
 *   - expect_*() consumes the token if it matches, otherwise records
 *     a P_E_EXPECTED_* error and returns false (without consuming).
 *   - accept_*() consumes-and-returns-true if the cursor matches,
 *     otherwise leaves the cursor untouched and returns false.
 *   - record_error() appends to the error log; the parser keeps
 *     parsing after recoverable errors (true synthesis is the job of
 *     the parser body in Wave 2 — this foundation only provides the
 *     primitive).
 *
 * Lookahead: the ring buffer is sized for IIIP_LOOKAHEAD tokens of
 * lookahead (≥ 4 — currently 8 to give expression-level disambiguation
 * room without any contortions).
 */
#ifndef III_PARSE_INTERNAL_H
#define III_PARSE_INTERNAL_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <string.h>
#include <stdarg.h>
#include <stdio.h>

#include "iii/ast.h"
#include "iii/parse_arena.h"
#include "iii/parser.h"
#include <iii/lex.h>
#include <iii/token.h>

/* ---- Cached interned-id tables ----------------------------------------- */

/* The 47 keywords (same order as LEXICON/src/keywords.c). */
typedef enum {
    IIIKW_WITNESS = 0,
    IIIKW_GLYPH,
    IIIKW_CYCLE,
    IIIKW_HEXAD,
    IIIKW_CAP,
    IIIKW_PHASE,
    IIIKW_SANCTUM,
    IIIKW_DRTM,
    IIIKW_OBSERVATORY,
    IIIKW_CATALYST,
    IIIKW_MOBIUS,            /* "möbius" — UTF-8 0xC3 0xB6 */
    IIIKW_TRINITY,
    IIIKW_CEILING,
    IIIKW_SID,
    IIIKW_WAVEFRONT,
    IIIKW_WAAC,
    IIIKW_WITNESS_STREAM,
    IIIKW_GLYPH_STREAM,
    IIIKW_NARRATIVE,
    IIIKW_EXPLAIN,
    IIIKW_PROPOSE,
    IIIKW_NEGOTIATE,
    IIIKW_COMMIT,
    IIIKW_REFLECT,
    IIIKW_UNCERTAINTY,
    IIIKW_EPOCH,
    IIIKW_VDF,
    IIIKW_MHASH,
    IIIKW_CLOSURE,
    IIIKW_ANCHOR,
    IIIKW_FEDERATION,
    IIIKW_AMEND,
    IIIKW_BRICKING,
    IIIKW_IRREVERSIBLE,
    IIIKW_PURE,
    IIIKW_METAL,
    IIIKW_EXTERN,
    IIIKW_SELF_HOST,
    IIIKW_PROMOTE,
    IIIKW_OBSERVE,
    IIIKW_COHERENCE,
    IIIKW_INVERSE,
    IIIKW_MANIFEST,
    IIIKW_GLYPH_BOUND,
    IIIKW_MOBIUS_CANDIDATE,
    IIIKW_SCHEMA,
    IIIKW_MODULE,
    IIIKW_COUNT
} iii_kw_e;

/* The 19 modifiers (same order as LEXICON/src/modifiers.c, IDs 1..19;
 * @safety is mapped to IIIMOD_HEXAD by the lexer). */
typedef enum {
    IIIMOD_RING = 0,
    IIIMOD_HEXAD,
    IIIMOD_TIER,
    IIIMOD_EPOCH,
    IIIMOD_CAP,
    IIIMOD_SANCTUM_ONLY,
    IIIMOD_IRREVERSIBLE,
    IIIMOD_PURE,
    IIIMOD_CLOSURE,
    IIIMOD_REPLICATES,
    IIIMOD_PLAN_ANCHOR,
    IIIMOD_ADMITS_CAPS,
    IIIMOD_PREREQUISITES,
    IIIMOD_CANDIDATE_FOR_PROMOTION,
    IIIMOD_MOBIUS_COHERENCE,
    IIIMOD_WITNESS_ELIDE,
    IIIMOD_HOT_PATH,
    IIIMOD_CHRONOS_BYPASS,
    IIIMOD_EPOCH_BRIDGE,
    IIIMOD_COUNT
} iii_mod_e;

/* The 23 operators (1..23 from LEXICON/src/operators.c, indexed 0..22). */
typedef enum {
    IIIOP_INVERSE = 0,           /* ⟲ */
    IIIOP_CYCLE_COMPOSE,         /* ⊕ */
    IIIOP_GLYPH_MATERIALIZE,     /* ⊗ */
    IIIOP_HEXAD_COMPOSE,         /* ⧉ */
    IIIOP_TRINITY_GATE,          /* ⟐ */
    IIIOP_REPLAY,                /* ↻ */
    IIIOP_WITNESS_EMIT,          /* ⟡ */
    IIIOP_CEILING_CHECK,         /* ⟁ */
    IIIOP_MOBIUS_COHERENCE,      /* ⧗ */
    IIIOP_PHASE_CROSS,           /* ⟴ */
    IIIOP_CAP_ACQ_REL,           /* ⧈ */
    IIIOP_EPOCH_BRIDGE,          /* ⟵ */
    IIIOP_VDF_SQUARING,          /* ⧊ */
    IIIOP_FED_REPLICATE,         /* ⟶ */
    IIIOP_AMEND_APPLY,           /* ⨁ */
    IIIOP_FULL_INVERSE_REPLAY,   /* ⟲⟲ */
    IIIOP_CATALYST_PROMOTE,      /* ⊛ */
    IIIOP_OBS_SATURATE,          /* ⧄ */
    IIIOP_NARRATIVE_REFLECT,     /* ⟐⟐ */
    IIIOP_UNCERTAINTY_QUERY,     /* ⧇ */
    IIIOP_EXPLAIN_OP,            /* ⟡⟡ */
    IIIOP_PROPOSE_OP,            /* ⧋ */
    IIIOP_NEGOTIATE_OP,          /* ⟴⟴ */
    IIIOP_COUNT
} iii_op_e;

/* All punctuator forms emitted by the lexer (single-byte ASCII +
 * multi-byte ASCII pairs + the two ≤/≥ codepoints). */
typedef enum {
    IIIPN_LPAREN = 0,    /* ( */
    IIIPN_RPAREN,        /* ) */
    IIIPN_LBRACE,        /* { */
    IIIPN_RBRACE,        /* } */
    IIIPN_LBRACK,        /* [ */
    IIIPN_RBRACK,        /* ] */
    IIIPN_LT,            /* < */
    IIIPN_GT,            /* > */
    IIIPN_COMMA,         /* , */
    IIIPN_SEMI,          /* ; */
    IIIPN_COLON,         /* : */
    IIIPN_DOT,           /* . */
    IIIPN_EQ,            /* = */
    IIIPN_PIPE,          /* | */
    IIIPN_UNDER,         /* _ */
    IIIPN_QMARK,         /* ? */
    IIIPN_AMP,           /* & */
    IIIPN_MINUS,         /* - */
    IIIPN_LE,            /* ≤ */
    IIIPN_GE,            /* ≥ */
    IIIPN_ARROW,         /* -> */
    IIIPN_DCOLON,        /* :: */
    IIIPN_DDOT,          /* .. */
    IIIPN_EQEQ,          /* == */
    IIIPN_FATARROW,      /* => */
    IIIPN_NEQ,           /* != */
    IIIPN_COUNT
} iii_pn_e;

/* ---- Parser state ------------------------------------------------------ */

#define IIIP_LOOKAHEAD 8u   /* must be >= 4 per contract */

typedef struct {
    iii_token_t tok;
    int         valid;      /* 1 = filled, 0 = empty */
} iii_tokslot_t;

struct iii_parser {
    iii_lex_state_t *lex;       /* not owned */
    iii_arena_t     *arena;     /* not owned */

    /* Source pointer cache (pulled at parser_create time from the lex
     * state by feeding it the empty input is not possible — instead we
     * accept that source is owned by the caller and mirror it via the
     * lex API.  The pointer/len are NULL/0 here; iii_parser_source()
     * returns the lex-borrowed source via iii_lex APIs.  We *do* cache
     * a copy here for the printer's convenience when callers pass it. */
    const uint8_t   *source;
    size_t           source_len;

    /* Ring buffer for lookahead.  head = next slot to read.  count =
     * number of valid tokens currently buffered. */
    iii_tokslot_t    ring[IIIP_LOOKAHEAD];
    unsigned         ring_head;
    unsigned         ring_count;
    int              hit_eof;     /* lex pump has produced EOF */

    /* Pending doc-comment for attachment to the next item.
     * III_AST_NO_DOC = none. */
    uint32_t         pending_doc_offset;

    /* Error log. */
    iii_parse_error_t *errors;
    size_t             err_len;
    size_t             err_cap;

    /* Cached interned ids (looked up once at parser_create time). */
    uint32_t kw_id  [IIIKW_COUNT];
    uint32_t mod_id [IIIMOD_COUNT];
    uint32_t op_id  [IIIOP_COUNT];
    uint32_t pn_id  [IIIPN_COUNT];
};

/* ---- Cross-TU primitives (defined in parse_state.c) ------------------- */

/* Pump the lex state once and append to the ring buffer.  Returns 1 if a
 * non-filtered token was added, 0 on EOF, -1 on a hard lex failure
 * (which is also recorded as P_E_LEX_ERROR). */
int  iiip_pump(iii_parser_t *p);

/* Look at i-th token ahead (i=0 is current).  Auto-pumps as needed.
 * Returns NULL only if the requested slot would exceed IIIP_LOOKAHEAD. */
const iii_token_t *iiip_peek(iii_parser_t *p, unsigned i);

/* Advance one token and return what was current (by value-copy through
 * out_tok if non-NULL).  Returns 1 on success, 0 if at EOF. */
int  iiip_consume(iii_parser_t *p, iii_token_t *out_tok);

/* Append a parse error.  fmt/... is printf-style. */
void iiip_record_error(iii_parser_t *p, int code,
                       uint32_t span_start, uint32_t span_end,
                       uint32_t line, uint32_t col,
                       const char *fmt, ...);

/* Skip tokens until a recovery point is reached.  Recovery is any
 * punctuator from the IIIPN_* set listed in `recover_set` (terminated
 * by IIIPN_COUNT) at the current cursor position, or EOF.  Does NOT
 * consume the recovery token. */
void iiip_skip_to_recovery(iii_parser_t *p, const iii_pn_e *recover_set);

/* Defined in parse_kw_table.c — populates p->kw_id / mod_id / op_id /
 * pn_id by interning every keyword/modifier/operator/punctuator string
 * into the lex state's intern table.  Returns 0 on success, -1 on OOM. */
int  iiip_init_keyword_ids(iii_parser_t *p);

/* ---- Inline cursor helpers -------------------------------------------- */

static inline const iii_token_t *peek(iii_parser_t *p, unsigned i) {
    return iiip_peek(p, i);
}

static inline int consume(iii_parser_t *p, iii_token_t *out) {
    return iiip_consume(p, out);
}

static inline bool tok_is_kw(const iii_token_t *t,
                             const iii_parser_t *p, iii_kw_e k) {
    return t && t->kind == IIIK_KEYWORD && t->interned_id == p->kw_id[k];
}
static inline bool tok_is_mod(const iii_token_t *t,
                              const iii_parser_t *p, iii_mod_e m) {
    return t && t->kind == IIIK_MODIFIER && t->interned_id == p->mod_id[m];
}
static inline bool tok_is_op(const iii_token_t *t,
                             const iii_parser_t *p, iii_op_e o) {
    return t && t->kind == IIIK_OPERATOR && t->interned_id == p->op_id[o];
}
static inline bool tok_is_pn(const iii_token_t *t,
                             const iii_parser_t *p, iii_pn_e n) {
    return t && t->kind == IIIK_PUNCT && t->interned_id == p->pn_id[n];
}

static inline bool accept_kw(iii_parser_t *p, iii_kw_e k) {
    const iii_token_t *t = peek(p, 0);
    if (tok_is_kw(t, p, k)) { consume(p, NULL); return true; }
    return false;
}
static inline bool accept_pn(iii_parser_t *p, iii_pn_e n) {
    const iii_token_t *t = peek(p, 0);
    if (tok_is_pn(t, p, n)) { consume(p, NULL); return true; }
    return false;
}
static inline bool accept_op(iii_parser_t *p, iii_op_e o) {
    const iii_token_t *t = peek(p, 0);
    if (tok_is_op(t, p, o)) { consume(p, NULL); return true; }
    return false;
}
static inline bool accept_mod(iii_parser_t *p, iii_mod_e m) {
    const iii_token_t *t = peek(p, 0);
    if (tok_is_mod(t, p, m)) { consume(p, NULL); return true; }
    return false;
}

/* expect_*: consume on match; on mismatch, record a P_E_EXPECTED_*
 * error citing the cursor token and return false (without consuming). */
bool iiip_expect_kw   (iii_parser_t *p, iii_kw_e   k, const char *kw_text);
bool iiip_expect_pn   (iii_parser_t *p, iii_pn_e   n, const char *pn_text);
bool iiip_expect_op   (iii_parser_t *p, iii_op_e   o, const char *op_text);
bool iiip_expect_ident(iii_parser_t *p, iii_token_t *out);

#define expect_kw(p, k)        iiip_expect_kw   ((p), (k), #k)
#define expect_punct(p, n)     iiip_expect_pn   ((p), (n), #n)
#define expect_op(p, o)        iiip_expect_op   ((p), (o), #o)
#define expect_ident(p, out)   iiip_expect_ident((p), (out))

/* ---- Contextual-keyword helpers (Wave 2) ------------------------------ */

static inline uint32_t iiip_intern_text(iii_parser_t *p, const char *s) {
    return iii_lex_intern(p->lex, s, strlen(s));
}

/* Match an IDENT or KEYWORD token whose text equals `s`. */
static inline bool tok_is_word(iii_parser_t *p,
                               const iii_token_t *t, const char *s) {
    if (!t) return false;
    if (t->kind != IIIK_IDENT && t->kind != IIIK_KEYWORD) return false;
    return t->interned_id == iiip_intern_text(p, s);
}
static inline bool peek_word(iii_parser_t *p, unsigned i, const char *s) {
    return tok_is_word(p, peek(p, i), s);
}
static inline bool accept_word(iii_parser_t *p, const char *s) {
    if (peek_word(p, 0, s)) { consume(p, NULL); return true; }
    return false;
}
bool iiip_expect_word(iii_parser_t *p, const char *s);
#define expect_word(p, s) iiip_expect_word((p), (s))

/* Span-set helper for nodes built across multiple tokens. */
static inline void iiip_node_span(iii_ast_node_t *n,
                                  const iii_token_t *first,
                                  const iii_token_t *last) {
    if (!n) return;
    if (first) {
        n->span_start = first->text_offset;
        n->line       = first->line;
        n->col        = first->col;
    }
    if (last) {
        n->span_end = last->text_offset + last->text_len;
    } else if (first) {
        n->span_end = first->text_offset + first->text_len;
    }
}

/* Consume any pending doc-comment offset and return it (or III_AST_NO_DOC). */
static inline uint32_t iiip_take_pending_doc(iii_parser_t *p) {
    uint32_t d = p->pending_doc_offset;
    p->pending_doc_offset = III_AST_NO_DOC;
    return d;
}

/* ---- Wave 2 cross-TU forward declarations ----------------------------- */

iii_ast_node_t *iiip_parse_type     (iii_parser_t *p);
iii_ast_node_t *iiip_parse_expr     (iii_parser_t *p);
iii_ast_node_t *iiip_parse_block_expr(iii_parser_t *p);
iii_ast_node_t *iiip_parse_stmt     (iii_parser_t *p);
iii_ast_node_t *iiip_parse_pattern  (iii_parser_t *p);
iii_ast_node_t *iiip_parse_item     (iii_parser_t *p);
iii_ast_node_t *iiip_parse_qualified_name(iii_parser_t *p);

/* §6 helpers exported across files. */
iii_ast_node_t *iiip_parse_ring_set       (iii_parser_t *p);
iii_ast_node_t *iiip_parse_tier_name      (iii_parser_t *p);
iii_ast_node_t *iiip_parse_replication    (iii_parser_t *p);
iii_ast_node_t *iiip_parse_range          (iii_parser_t *p);
iii_ast_node_t *iiip_parse_epoch_value    (iii_parser_t *p);
iii_ast_node_t *iiip_parse_hexad_designator(iii_parser_t *p);
iii_ast_node_t *iiip_parse_coherence_expr (iii_parser_t *p);
iii_ast_node_t *iiip_parse_compromise_tier(iii_parser_t *p);
iii_ast_node_t *iiip_parse_generic_args   (iii_parser_t *p);

/* Modifier-set: parses zero or more modifiers and emits a flat
 * sequence of `mod_kind` nodes appended to `parent`. */
void iiip_parse_modifiers(iii_parser_t *p,
                          iii_ast_node_t *parent,
                          iii_ast_kind_t  mod_kind);

/* Allocate an arena node with a given kind.  Records the current peek
 * token's start as the node's initial span; the caller extends the span
 * to the last consumed token via iiip_node_finish(). */
static inline iii_ast_node_t *iiip_node(iii_parser_t *p, iii_ast_kind_t k) {
    iii_ast_node_t *n = iii_arena_node(p->arena, k);
    if (n) {
        const iii_token_t *t = peek(p, 0);
        if (t) iiip_node_span(n, t, t);
    }
    return n;
}

/* Allocate an III_AST_ERROR node spanning the current token. */
static inline iii_ast_node_t *iiip_error_node(iii_parser_t *p) {
    return iiip_node(p, III_AST_ERROR);
}

#endif
