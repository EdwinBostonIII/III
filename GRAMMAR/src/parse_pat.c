/* III Grammar — §9 Pattern productions. */
#include "parse_internal.h"

static iii_ast_node_t *parse_atom_pattern(iii_parser_t *p);

static int peek_is_literal(iii_parser_t *p) {
    const iii_token_t *t = peek(p, 0);
    if (!t) return 0;
    switch (t->kind) {
    case IIIK_INT_LIT: case IIIK_MHASH_LIT: case IIIK_TRIT_LIT:
    case IIIK_HEXAD_LIT: case IIIK_Q14_LIT: case IIIK_STRING_LIT:
    case IIIK_BYTE_STRING_LIT: case IIIK_RAW_STRING_LIT:
    case IIIK_HEX_STRING_LIT:
        return 1;
    case IIIK_IDENT:
        return peek_word(p, 0, "true") || peek_word(p, 0, "false");
    default:
        return 0;
    }
}

static iii_ast_node_t *make_literal_node(iii_parser_t *p) {
    const iii_token_t *t = peek(p, 0);
    iii_token_t copy = *t;
    iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_LITERAL);
    if (n) {
        n->interned_id    = copy.interned_id;
        n->int_value      = copy.int_value;
        memcpy(n->mhash_value, copy.mhash_value, 32);
        n->hexad_packed   = copy.hexad_packed;
        n->int_suffix     = copy.int_suffix;
        n->string_payload = copy.string_payload;
        n->string_len     = copy.string_len;
        n->op_id          = (uint16_t)copy.kind;
        iiip_node_span(n, &copy, &copy);
    }
    consume(p, NULL);
    return n;
}

/* trit_pattern ::= TRIT_LIT | '_' | IDENT('POS'|'ZERO'|'NEG') */
static iii_ast_node_t *parse_trit_pattern(iii_parser_t *p) {
    iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_TRIT_PATTERN);
    if (!n) return NULL;
    const iii_token_t *t = peek(p, 0);
    if (t && t->kind == IIIK_TRIT_LIT) {
        n->int_value = t->int_value;
        iiip_node_span(n, t, t);
        consume(p, NULL);
    } else if (t && t->kind == IIIK_PUNCT &&
               t->interned_id == p->pn_id[IIIPN_UNDER]) {
        iiip_node_span(n, t, t);
        consume(p, NULL);
    } else if (t && t->kind == IIIK_IDENT) {
        size_t nlen = 0;
        const char *ntxt = iii_lex_intern_text(p->lex, t->interned_id, &nlen);
        int matched = 0;
        if (ntxt) {
            if      (nlen == 3 && memcmp(ntxt, "POS",  3) == 0) { n->int_value =  1; matched = 1; }
            else if (nlen == 3 && memcmp(ntxt, "NEG",  3) == 0) { n->int_value = -1; matched = 1; }
            else if (nlen == 4 && memcmp(ntxt, "ZERO", 4) == 0) { n->int_value =  0; matched = 1; }
        }
        if (matched) {
            iiip_node_span(n, t, t);
            consume(p, NULL);
        } else {
            iiip_record_error(p, P_E_EXPECTED_PATTERN,
                              t->text_offset, t->text_offset + t->text_len,
                              t->line, t->col, "expected trit pattern");
        }
    } else {
        iiip_record_error(p, P_E_EXPECTED_PATTERN,
                          t ? t->text_offset : 0,
                          t ? t->text_offset + t->text_len : 0,
                          t ? t->line : 0, t ? t->col : 0,
                          "expected trit pattern");
    }
    return n;
}

/* hexad_pattern as a parenthesised 6-tuple of trit patterns. */
static iii_ast_node_t *parse_hexad_paren(iii_parser_t *p) {
    iii_token_t lp = *peek(p, 0);
    consume(p, NULL); /* '(' */
    iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_HEXAD_PATTERN);
    if (!n) return NULL;
    iiip_node_span(n, &lp, &lp);
    for (int i = 0; i < 6; i++) {
        iii_ast_node_t *tp = parse_trit_pattern(p);
        if (tp) iii_ast_add_child(p->arena, n, tp);
        if (i < 5) expect_punct(p, IIIPN_COMMA);
    }
    expect_punct(p, IIIPN_RPAREN);
    return n;
}

/* tuple_pattern (parenthesised heterogeneous patterns or unit) */
static iii_ast_node_t *parse_tuple_or_hexad(iii_parser_t *p) {
    /* Lookahead: a hexad pattern is exactly six trit-patterns; we cannot
     * fully distinguish without trying.  Heuristic: if the first
     * sub-token is TRIT_LIT or '_', treat as hexad pattern. */
    const iii_token_t *t1 = peek(p, 1);
    if (t1 && (t1->kind == IIIK_TRIT_LIT ||
               (t1->kind == IIIK_PUNCT &&
                t1->interned_id == p->pn_id[IIIPN_UNDER]))) {
        /* Could be either tuple of underscores or hexad — check for 6
         * trit/underscore tokens separated by commas. */
        unsigned i = 1, count = 0;
        for (;;) {
            const iii_token_t *a = peek(p, i);
            if (!a) break;
            int is_trit = (a->kind == IIIK_TRIT_LIT) ||
                          (a->kind == IIIK_PUNCT &&
                           a->interned_id == p->pn_id[IIIPN_UNDER]);
            if (!is_trit) break;
            count++;
            const iii_token_t *b = peek(p, i + 1);
            if (b && b->kind == IIIK_PUNCT &&
                b->interned_id == p->pn_id[IIIPN_COMMA]) {
                i += 2;
                continue;
            }
            break;
        }
        if (count == 6) return parse_hexad_paren(p);
    }
    /* Tuple pattern */
    iii_token_t lp = *peek(p, 0);
    consume(p, NULL);
    iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_TUPLE_PATTERN);
    if (!n) return NULL;
    iiip_node_span(n, &lp, &lp);
    if (accept_pn(p, IIIPN_RPAREN)) return n;
    iii_ast_node_t *p0 = iiip_parse_pattern(p);
    if (p0) iii_ast_add_child(p->arena, n, p0);
    while (accept_pn(p, IIIPN_COMMA)) {
        if (peek(p, 0) && peek(p, 0)->kind == IIIK_PUNCT &&
            peek(p, 0)->interned_id == p->pn_id[IIIPN_RPAREN]) break;
        iii_ast_node_t *pi = iiip_parse_pattern(p);
        if (pi) iii_ast_add_child(p->arena, n, pi);
    }
    expect_punct(p, IIIPN_RPAREN);
    return n;
}

/* record_pattern: qualified_name '{' record_pattern_field (',' ...)* '}' */
static iii_ast_node_t *parse_record_pattern_body(iii_parser_t *p,
                                                 iii_ast_node_t *qn) {
    iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_RECORD_PATTERN);
    if (!n) return NULL;
    n->span_start = qn ? qn->span_start : 0;
    n->line = qn ? qn->line : 0;
    n->col  = qn ? qn->col  : 0;
    if (qn) iii_ast_add_child(p->arena, n, qn);
    consume(p, NULL); /* '{' */
    do {
        iii_token_t fname;
        if (!expect_ident(p, &fname)) break;
        iii_ast_node_t *f = iii_arena_node(p->arena, III_AST_RECORD_PATTERN_FIELD);
        if (!f) break;
        f->interned_id = fname.interned_id;
        iiip_node_span(f, &fname, &fname);
        if (accept_pn(p, IIIPN_COLON)) {
            iii_ast_node_t *sub = iiip_parse_pattern(p);
            if (sub) iii_ast_add_child(p->arena, f, sub);
        }
        iii_ast_add_child(p->arena, n, f);
    } while (accept_pn(p, IIIPN_COMMA));
    expect_punct(p, IIIPN_RBRACE);
    return n;
}

static iii_ast_node_t *parse_path_or_record_pattern(iii_parser_t *p) {
    iii_ast_node_t *qn = iiip_parse_qualified_name(p);
    if (!qn) return NULL;
    /* Tagged-variant: qualified_name '(' pattern (',' pattern)* ')' */
    if (peek(p, 0) && peek(p, 0)->kind == IIIK_PUNCT &&
        peek(p, 0)->interned_id == p->pn_id[IIIPN_LPAREN]) {
        consume(p, NULL);
        iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_PATH_PATTERN);
        if (!n) return qn;
        n->span_start = qn->span_start; n->line = qn->line; n->col = qn->col;
        iii_ast_add_child(p->arena, n, qn);
        if (!(peek(p, 0) && peek(p, 0)->kind == IIIK_PUNCT &&
              peek(p, 0)->interned_id == p->pn_id[IIIPN_RPAREN])) {
            iii_ast_node_t *sub = iiip_parse_pattern(p);
            if (sub) iii_ast_add_child(p->arena, n, sub);
            while (accept_pn(p, IIIPN_COMMA)) {
                iii_ast_node_t *q = iiip_parse_pattern(p);
                if (q) iii_ast_add_child(p->arena, n, q);
            }
        }
        expect_punct(p, IIIPN_RPAREN);
        return n;
    }
    /* Record pattern */
    if (peek(p, 0) && peek(p, 0)->kind == IIIK_PUNCT &&
        peek(p, 0)->interned_id == p->pn_id[IIIPN_LBRACE]) {
        return parse_record_pattern_body(p, qn);
    }
    /* Plain qualified_name → path pattern with no args, OR a single-IDENT
     * binding pattern.  Decide: if the qualified_name has exactly one
     * segment AND no children, it's an ident_pattern. */
    if (qn->child_count == 0) {
        iii_ast_node_t *ip = iii_arena_node(p->arena, III_AST_IDENT_PATTERN);
        if (!ip) return qn;
        ip->interned_id = qn->interned_id;
        ip->span_start = qn->span_start; ip->span_end = qn->span_end;
        ip->line = qn->line; ip->col = qn->col;
        /* IDENT '@' pattern (binder + nested) */
        if (peek(p, 0) && peek(p, 0)->kind == IIIK_MODIFIER) {
            /* '@' is consumed by the lexer as part of MODIFIER tokens;
             * we cannot represent IDENT '@' pattern here without lexer
             * support.  Skip per §10 — this is the only place '@' would
             * appear after IDENT, and the lexer's modifier-prefix rule
             * will already have consumed it.  Treat as plain binder. */
        }
        return ip;
    }
    iii_ast_node_t *pp = iii_arena_node(p->arena, III_AST_PATH_PATTERN);
    if (!pp) return qn;
    pp->span_start = qn->span_start; pp->span_end = qn->span_end;
    pp->line = qn->line; pp->col = qn->col;
    iii_ast_add_child(p->arena, pp, qn);
    return pp;
}

/* range_pattern: literal '..' literal | literal '..=' literal */
static iii_ast_node_t *try_range_pattern(iii_parser_t *p) {
    /* Build literal first, then check for '..'. */
    iii_ast_node_t *lo = make_literal_node(p);
    if (!lo) return NULL;
    if (peek(p, 0) && peek(p, 0)->kind == IIIK_PUNCT &&
        peek(p, 0)->interned_id == p->pn_id[IIIPN_DDOT]) {
        consume(p, NULL);
        /* Optional `=` from `..=` — represented as PUNCT EQ. */
        bool inclusive = false;
        if (peek(p, 0) && peek(p, 0)->kind == IIIK_PUNCT &&
            peek(p, 0)->interned_id == p->pn_id[IIIPN_EQ]) {
            consume(p, NULL);
            inclusive = true;
        }
        iii_ast_node_t *r = iii_arena_node(p->arena, III_AST_RANGE_PATTERN);
        if (!r) return lo;
        r->op_id = inclusive ? 1 : 0;
        r->span_start = lo->span_start; r->line = lo->line; r->col = lo->col;
        iii_ast_add_child(p->arena, r, lo);
        if (peek_is_literal(p)) {
            iii_ast_node_t *hi = make_literal_node(p);
            if (hi) { iii_ast_add_child(p->arena, r, hi);
                r->span_end = hi->span_end; }
        }
        return r;
    }
    /* Just a literal_pattern */
    iii_ast_node_t *lp = iii_arena_node(p->arena, III_AST_LITERAL_PATTERN);
    if (!lp) return lo;
    lp->span_start = lo->span_start; lp->span_end = lo->span_end;
    lp->line = lo->line; lp->col = lo->col;
    iii_ast_add_child(p->arena, lp, lo);
    return lp;
}

/* Atom: literal-pattern | wildcard | tuple/hexad | record/path | ident */
static iii_ast_node_t *parse_atom_pattern(iii_parser_t *p) {
    const iii_token_t *t = peek(p, 0);
    if (!t) return NULL;
    if (t->kind == IIIK_PUNCT &&
        t->interned_id == p->pn_id[IIIPN_UNDER]) {
        iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_WILDCARD_PATTERN);
        if (n) iiip_node_span(n, t, t);
        consume(p, NULL);
        return n;
    }
    if (t->kind == IIIK_PUNCT && t->interned_id == p->pn_id[IIIPN_LPAREN]) {
        return parse_tuple_or_hexad(p);
    }
    if (t->kind == IIIK_HEXAD_LIT) {
        iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_HEXAD_PATTERN);
        if (n) { n->hexad_packed = t->hexad_packed; iiip_node_span(n, t, t); }
        consume(p, NULL);
        return n;
    }
    if (peek_is_literal(p)) {
        return try_range_pattern(p);
    }
    if (t->kind == IIIK_IDENT) {
        /* `HEXAD(...)` shorthand.  The lexer eagerly fuses the
         * parenthesised six-trit form into a single HEXAD_LIT token,
         * so two cases must be handled:
         *   IDENT 'HEXAD' HEXAD_LIT          → packed value
         *   IDENT 'HEXAD' '(' trit-pat × 6 ')' → 6-child form */
        const iii_token_t *t1 = peek(p, 1);
        if (t1) {
            size_t nlen = 0;
            const char *ntxt = iii_lex_intern_text(p->lex, t->interned_id, &nlen);
            int is_hexad_kw = (ntxt && nlen == 5 && memcmp(ntxt, "HEXAD", 5) == 0);
            if (is_hexad_kw && t1->kind == IIIK_HEXAD_LIT) {
                consume(p, NULL); /* IDENT 'HEXAD' */
                iii_token_t hl = *peek(p, 0);
                iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_HEXAD_PATTERN);
                if (n) { n->hexad_packed = hl.hexad_packed; iiip_node_span(n, &hl, &hl); }
                consume(p, NULL); /* HEXAD_LIT */
                return n;
            }
            if (is_hexad_kw && t1->kind == IIIK_PUNCT &&
                t1->interned_id == p->pn_id[IIIPN_LPAREN]) {
                consume(p, NULL); /* IDENT 'HEXAD' */
                return parse_hexad_paren(p);
            }
        }
        return parse_path_or_record_pattern(p);
    }
    iiip_record_error(p, P_E_EXPECTED_PATTERN,
                      t->text_offset, t->text_offset + t->text_len,
                      t->line, t->col, "expected pattern");
    iii_ast_node_t *e = iiip_error_node(p);
    consume(p, NULL);
    return e;
}

iii_ast_node_t *iiip_parse_pattern(iii_parser_t *p) {
    iii_ast_node_t *first = parse_atom_pattern(p);
    if (!first) return NULL;

    /* or_pattern: pattern ('|' pattern)+ */
    if (peek(p, 0) && peek(p, 0)->kind == IIIK_PUNCT &&
        peek(p, 0)->interned_id == p->pn_id[IIIPN_PIPE]) {
        iii_ast_node_t *orn = iii_arena_node(p->arena, III_AST_OR_PATTERN);
        if (orn) {
            orn->span_start = first->span_start;
            orn->line = first->line; orn->col = first->col;
            iii_ast_add_child(p->arena, orn, first);
            while (accept_pn(p, IIIPN_PIPE)) {
                iii_ast_node_t *nx = parse_atom_pattern(p);
                if (nx) { iii_ast_add_child(p->arena, orn, nx);
                    orn->span_end = nx->span_end; }
            }
            first = orn;
        }
    }

    /* guard_pattern: pattern 'if' expr */
    if (peek_word(p, 0, "if")) {
        consume(p, NULL);
        iii_ast_node_t *gp = iii_arena_node(p->arena, III_AST_GUARD_PATTERN);
        if (!gp) return first;
        gp->span_start = first->span_start;
        gp->line = first->line; gp->col = first->col;
        iii_ast_add_child(p->arena, gp, first);
        iii_ast_node_t *cond = iiip_parse_expr(p);
        if (cond) { iii_ast_add_child(p->arena, gp, cond);
            gp->span_end = cond->span_end; }
        return gp;
    }
    return first;
}
