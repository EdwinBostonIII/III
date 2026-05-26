/* III Grammar — §7 Statement productions. */
#include "parse_internal.h"

/* Forward decls for local helpers. */
static iii_ast_node_t *parse_let_stmt    (iii_parser_t *p);
static iii_ast_node_t *parse_if_stmt     (iii_parser_t *p);
static iii_ast_node_t *parse_match_stmt  (iii_parser_t *p);
static iii_ast_node_t *parse_for_stmt    (iii_parser_t *p);
static iii_ast_node_t *parse_while_stmt  (iii_parser_t *p);
static iii_ast_node_t *parse_wavefront_stmt(iii_parser_t *p);
static iii_ast_node_t *parse_sanctum_stmt(iii_parser_t *p);
static iii_ast_node_t *parse_metal_stmt  (iii_parser_t *p);
static iii_ast_node_t *parse_return_stmt (iii_parser_t *p);
static iii_ast_node_t *parse_promote_stmt(iii_parser_t *p);
static iii_ast_node_t *parse_explain_stmt(iii_parser_t *p);
static iii_ast_node_t *parse_propose_stmt(iii_parser_t *p);
static iii_ast_node_t *parse_negotiate_stmt(iii_parser_t *p);
static iii_ast_node_t *parse_reflect_stmt(iii_parser_t *p);
static iii_ast_node_t *parse_commit_stmt (iii_parser_t *p);
static iii_ast_node_t *parse_reverse_stmt(iii_parser_t *p);
static iii_ast_node_t *parse_ask_stmt    (iii_parser_t *p);
static iii_ast_node_t *parse_block_stmt  (iii_parser_t *p);
static iii_ast_node_t *parse_assign_or_effect(iii_parser_t *p);

/* ---- helpers ------------------------------------------------------- */

static int peek_kw(iii_parser_t *p, iii_kw_e k) { return tok_is_kw(peek(p, 0), p, k); }
static int peek_pn(iii_parser_t *p, iii_pn_e n) { return tok_is_pn(peek(p, 0), p, n); }

/* The set of statement-recovery punctuators. */
static const iii_pn_e STMT_RECOVERY[] = { IIIPN_SEMI, IIIPN_RBRACE, IIIPN_COUNT };

/* ---- entrypoint ---------------------------------------------------- */

iii_ast_node_t *iiip_parse_stmt(iii_parser_t *p) {
    const iii_token_t *t = peek(p, 0);
    if (!t || t->kind == IIIK_EOF) return NULL;

    /* Doc-attached: a DOC_COMMENT mid-block is unusual but legal.  We
     * consume it and return a stmt-shaped DOC_ATTACHED node carrying the
     * doc text offset; the caller's reduction layer attaches it to the
     * next non-doc statement at AST canonicalisation time. */
    if (t->kind == IIIK_DOC_COMMENT) {
        iii_token_t doc = *t;
        consume(p, NULL);
        iii_ast_node_t *d = iii_arena_node(p->arena, III_AST_DOC_ATTACHED);
        if (d) { iiip_node_span(d, &doc, &doc); d->doc_offset = doc.text_offset; }
        return d;
    }

    /* Dispatch on first token. */
    if (peek_word(p, 0, "let"))            return parse_let_stmt(p);
    if (peek_word(p, 0, "if"))             return parse_if_stmt(p);
    if (peek_word(p, 0, "match"))          return parse_match_stmt(p);
    if (peek_word(p, 0, "for"))            return parse_for_stmt(p);
    if (peek_word(p, 0, "while"))          return parse_while_stmt(p);
    if (peek_kw(p, IIIKW_WAVEFRONT))       return parse_wavefront_stmt(p);
    if (peek_word(p, 0, "sanctum_enter"))  return parse_sanctum_stmt(p);
    if (peek_kw(p, IIIKW_METAL))           return parse_metal_stmt(p);
    if (peek_word(p, 0, "return"))         return parse_return_stmt(p);
    if (peek_kw(p, IIIKW_PROMOTE))         return parse_promote_stmt(p);
    if (peek_kw(p, IIIKW_EXPLAIN))         return parse_explain_stmt(p);
    if (peek_kw(p, IIIKW_PROPOSE))         return parse_propose_stmt(p);
    if (peek_kw(p, IIIKW_NEGOTIATE))       return parse_negotiate_stmt(p);
    if (peek_kw(p, IIIKW_REFLECT))         return parse_reflect_stmt(p);
    if (peek_kw(p, IIIKW_COMMIT))          return parse_commit_stmt(p);
    if (peek_kw(p, IIIKW_INVERSE) &&
        peek(p, 1) && tok_is_pn(peek(p, 1), p, IIIPN_DOT))
                                           return parse_reverse_stmt(p);
    if ((peek_kw(p, IIIKW_UNCERTAINTY) || peek_kw(p, IIIKW_NARRATIVE)) &&
        peek(p, 1) && tok_is_pn(peek(p, 1), p, IIIPN_DOT))
                                           return parse_ask_stmt(p);
    if (peek_pn(p, IIIPN_LBRACE))          return parse_block_stmt(p);
    return parse_assign_or_effect(p);
}

/* ---- 7.x ----------------------------------------------------------- */

static iii_ast_node_t *parse_let_stmt(iii_parser_t *p) {
    iii_token_t kw = *peek(p, 0);
    consume(p, NULL); /* 'let' */
    iii_ast_node_t *node = iii_arena_node(p->arena, III_AST_LET_STMT);
    if (!node) return NULL;
    iiip_node_span(node, &kw, &kw);
    node->doc_offset = iiip_take_pending_doc(p);
    iii_token_t id;
    if (expect_ident(p, &id)) node->interned_id = id.interned_id;
    if (accept_pn(p, IIIPN_COLON)) {
        iii_ast_node_t *ty = iiip_parse_type(p);
        if (ty) iii_ast_add_child(p->arena, node, ty);
    }
    expect_punct(p, IIIPN_EQ);
    iii_ast_node_t *e = iiip_parse_expr(p);
    if (e) iii_ast_add_child(p->arena, node, e);
    const iii_token_t *semi = peek(p, 0);
    if (semi) node->span_end = semi->text_offset + semi->text_len;
    expect_punct(p, IIIPN_SEMI);
    return node;
}

/* place_expr := IDENT (. IDENT | [ expr ] | :: IDENT)*
 * We just parse a postfix expression and verify it is a "place" shape;
 * we don't enforce statically — semantic check downstream. */
static iii_ast_node_t *parse_place_expr(iii_parser_t *p) {
    iii_ast_node_t *e = iiip_parse_expr(p);
    if (!e) return NULL;
    iii_ast_node_t *pe = iii_arena_node(p->arena, III_AST_PLACE_EXPR);
    if (!pe) return e;
    pe->span_start = e->span_start; pe->span_end = e->span_end;
    pe->line = e->line; pe->col = e->col;
    iii_ast_add_child(p->arena, pe, e);
    return pe;
}

static iii_ast_node_t *parse_assign_or_effect(iii_parser_t *p) {
    /* Try to parse an expression; if next is '=', it's an assign;
     * otherwise it's an effect. */
    uint32_t span_start = peek(p, 0) ? peek(p, 0)->text_offset : 0;
    uint32_t line = peek(p, 0) ? peek(p, 0)->line : 0;
    uint32_t col  = peek(p, 0) ? peek(p, 0)->col  : 0;
    iii_ast_node_t *e = iiip_parse_expr(p);
    if (!e) {
        iiip_skip_to_recovery(p, STMT_RECOVERY);
        accept_pn(p, IIIPN_SEMI);
        return NULL;
    }
    if (peek_pn(p, IIIPN_EQ)) {
        consume(p, NULL);
        iii_ast_node_t *rhs = iiip_parse_expr(p);
        iii_ast_node_t *as = iii_arena_node(p->arena, III_AST_ASSIGN_STMT);
        if (!as) return e;
        as->span_start = span_start; as->line = line; as->col = col;
        iii_ast_node_t *pe = iii_arena_node(p->arena, III_AST_PLACE_EXPR);
        if (pe) {
            pe->span_start = e->span_start; pe->span_end = e->span_end;
            pe->line = e->line; pe->col = e->col;
            iii_ast_add_child(p->arena, pe, e);
            iii_ast_add_child(p->arena, as, pe);
        } else {
            iii_ast_add_child(p->arena, as, e);
        }
        if (rhs) iii_ast_add_child(p->arena, as, rhs);
        const iii_token_t *semi = peek(p, 0);
        if (semi) as->span_end = semi->text_offset + semi->text_len;
        expect_punct(p, IIIPN_SEMI);
        return as;
    }
    iii_ast_node_t *es = iii_arena_node(p->arena, III_AST_EFFECT_STMT);
    if (!es) return e;
    es->span_start = e->span_start; es->span_end = e->span_end;
    es->line = e->line; es->col = e->col;
    iii_ast_add_child(p->arena, es, e);
    const iii_token_t *semi = peek(p, 0);
    if (semi) es->span_end = semi->text_offset + semi->text_len;
    expect_punct(p, IIIPN_SEMI);
    (void)parse_place_expr; /* may go unused */
    return es;
}

static iii_ast_node_t *parse_if_stmt(iii_parser_t *p) {
    iii_token_t kw = *peek(p, 0);
    consume(p, NULL); /* 'if' */
    iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_IF_STMT);
    if (!n) return NULL;
    iiip_node_span(n, &kw, &kw);
    iii_ast_node_t *cond = iiip_parse_expr(p);
    if (cond) iii_ast_add_child(p->arena, n, cond);
    iii_ast_node_t *then_blk = iiip_parse_block_expr(p);
    if (then_blk) {
        iii_ast_add_child(p->arena, n, then_blk);
        n->span_end = then_blk->span_end;
    }
    if (accept_word(p, "else")) {
        iii_ast_node_t *else_part;
        if (peek_word(p, 0, "if")) else_part = parse_if_stmt(p);
        else                       else_part = iiip_parse_block_expr(p);
        if (else_part) {
            iii_ast_add_child(p->arena, n, else_part);
            n->span_end = else_part->span_end;
        }
    }
    return n;
}

static iii_ast_node_t *parse_match_stmt(iii_parser_t *p) {
    iii_token_t kw = *peek(p, 0);
    consume(p, NULL); /* 'match' */
    iii_ast_node_t *m = iii_arena_node(p->arena, III_AST_MATCH_STMT);
    if (!m) return NULL;
    iiip_node_span(m, &kw, &kw);
    iii_ast_node_t *scrut = iiip_parse_expr(p);
    if (scrut) iii_ast_add_child(p->arena, m, scrut);
    expect_punct(p, IIIPN_LBRACE);
    while (peek(p, 0) && peek(p, 0)->kind != IIIK_EOF && !peek_pn(p, IIIPN_RBRACE)) {
        unsigned bh = p->ring_head, bc = p->ring_count;
        iii_ast_node_t *arm = iii_arena_node(p->arena, III_AST_MATCH_ARM);
        if (!arm) break;
        const iii_token_t *first = peek(p, 0);
        if (first) iiip_node_span(arm, first, first);
        iii_ast_node_t *pat = iiip_parse_pattern(p);
        if (pat) iii_ast_add_child(p->arena, arm, pat);
        if (accept_word(p, "if")) {
            iii_ast_node_t *guard = iiip_parse_expr(p);
            if (guard) iii_ast_add_child(p->arena, arm, guard);
        }
        expect_punct(p, IIIPN_FATARROW);
        iii_ast_node_t *body;
        if (peek_pn(p, IIIPN_LBRACE)) body = iiip_parse_block_expr(p);
        else                          body = iiip_parse_expr(p);
        if (body) { iii_ast_add_child(p->arena, arm, body); arm->span_end = body->span_end; }
        iii_ast_add_child(p->arena, m, arm);
        /* Comma is optional between match arms — block-bodied arms (the
         * common case) are self-terminating at their `}`, and adjacent
         * arms are separated only by whitespace.  We continue as long as
         * the cursor isn't at `}` / EOF (loop guard above). */
        accept_pn(p, IIIPN_COMMA);
        /* Safety: bail if no progress was made this iteration. */
        if (bh == p->ring_head && bc == p->ring_count) {
            consume(p, NULL);
        }
    }
    const iii_token_t *rb = peek(p, 0);
    if (rb) m->span_end = rb->text_offset + rb->text_len;
    expect_punct(p, IIIPN_RBRACE);
    return m;
}

static iii_ast_node_t *parse_for_stmt(iii_parser_t *p) {
    iii_token_t kw = *peek(p, 0);
    consume(p, NULL); /* 'for' */
    iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_FOR_STMT);
    if (!n) return NULL;
    iiip_node_span(n, &kw, &kw);
    iii_token_t id;
    if (expect_ident(p, &id)) n->interned_id = id.interned_id;
    if (!expect_word(p, "in")) {
        iiip_skip_to_recovery(p, STMT_RECOVERY);
        return n;
    }
    iii_ast_node_t *iter = iiip_parse_expr(p);
    if (iter) iii_ast_add_child(p->arena, n, iter);
    if (accept_word(p, "where")) {
        iii_ast_node_t *w = iiip_parse_expr(p);
        if (w) iii_ast_add_child(p->arena, n, w);
    }
    iii_ast_node_t *blk = iiip_parse_block_expr(p);
    if (blk) { iii_ast_add_child(p->arena, n, blk); n->span_end = blk->span_end; }
    return n;
}

static iii_ast_node_t *parse_while_stmt(iii_parser_t *p) {
    iii_token_t kw = *peek(p, 0);
    consume(p, NULL); /* 'while' */
    iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_WHILE_STMT);
    if (!n) return NULL;
    iiip_node_span(n, &kw, &kw);
    iii_ast_node_t *cond = iiip_parse_expr(p);
    if (cond) iii_ast_add_child(p->arena, n, cond);
    iii_ast_node_t *blk = iiip_parse_block_expr(p);
    if (blk) { iii_ast_add_child(p->arena, n, blk); n->span_end = blk->span_end; }
    return n;
}

/* parse a parenthesised arg-list of `IDENT ':' expr` pairs with a fixed key set. */
static void parse_keyed_args(iii_parser_t *p, iii_ast_node_t *parent,
                             iii_ast_kind_t arg_kind) {
    do {
        iii_token_t key;
        if (!expect_ident(p, &key)) break;
        if (!expect_punct(p, IIIPN_COLON)) break;
        iii_ast_node_t *e = iiip_parse_expr(p);
        iii_ast_node_t *a = iii_arena_node(p->arena, arg_kind);
        if (a) {
            a->interned_id = key.interned_id;
            iiip_node_span(a, &key, &key);
            if (e) { iii_ast_add_child(p->arena, a, e); a->span_end = e->span_end; }
            iii_ast_add_child(p->arena, parent, a);
        }
    } while (accept_pn(p, IIIPN_COMMA));
}

/* wavefront_stmt: 'wavefront' wavefront_modifier* '{' statement_list '}'
 *                 'until' wavefront_terminator */
static void parse_wavefront_modifiers(iii_parser_t *p, iii_ast_node_t *parent) {
    while (peek(p, 0) && peek(p, 0)->kind == IIIK_MODIFIER) {
        const iii_token_t *m = peek(p, 0);
        iii_mod_e which = IIIMOD_COUNT;
        if      (m->interned_id == p->mod_id[IIIMOD_HEXAD])            which = IIIMOD_HEXAD;
        else if (m->interned_id == p->mod_id[IIIMOD_MOBIUS_COHERENCE]) which = IIIMOD_MOBIUS_COHERENCE;
        else if (m->interned_id == p->mod_id[IIIMOD_ADMITS_CAPS])      which = IIIMOD_ADMITS_CAPS;
        else break;
        iii_token_t mt = *m;
        consume(p, NULL);
        iii_ast_node_t *mn = iii_arena_node(p->arena, III_AST_WAVEFRONT_MODIFIER);
        if (!mn) break;
        mn->op_id = (uint16_t)which;
        iiip_node_span(mn, &mt, &mt);
        if (expect_punct(p, IIIPN_LPAREN)) {
            iii_ast_node_t *arg = NULL;
            switch (which) {
            case IIIMOD_HEXAD:            arg = iiip_parse_hexad_designator(p); break;
            case IIIMOD_MOBIUS_COHERENCE: arg = iiip_parse_coherence_expr(p);   break;
            case IIIMOD_ADMITS_CAPS: {
                iii_ast_node_t *list = iii_arena_node(p->arena, III_AST_WAVEFRONT_MODIFIER);
                if (list) {
                    iiip_node_span(list, peek(p, 0), peek(p, 0));
                    iii_token_t cap;
                    if (expect_ident(p, &cap)) list->interned_id = cap.interned_id;
                    while (accept_pn(p, IIIPN_COMMA)) {
                        iii_token_t more;
                        if (!expect_ident(p, &more)) break;
                        iii_ast_node_t *c = iii_arena_node(p->arena, III_AST_PARAM);
                        if (c) { c->interned_id = more.interned_id; iiip_node_span(c, &more, &more);
                            iii_ast_add_child(p->arena, list, c); }
                    }
                }
                arg = list;
                break;
            }
            default: break;
            }
            if (arg) iii_ast_add_child(p->arena, mn, arg);
            const iii_token_t *rp = peek(p, 0);
            if (rp) mn->span_end = rp->text_offset + rp->text_len;
            expect_punct(p, IIIPN_RPAREN);
        }
        iii_ast_add_child(p->arena, parent, mn);
    }
}

static iii_ast_node_t *parse_wavefront_stmt(iii_parser_t *p) {
    iii_token_t kw = *peek(p, 0);
    consume(p, NULL); /* 'wavefront' */
    iii_ast_node_t *w = iii_arena_node(p->arena, III_AST_WAVEFRONT_STMT);
    if (!w) return NULL;
    iiip_node_span(w, &kw, &kw);
    parse_wavefront_modifiers(p, w);
    expect_punct(p, IIIPN_LBRACE);
    while (peek(p, 0) && peek(p, 0)->kind != IIIK_EOF && !peek_pn(p, IIIPN_RBRACE)) {
        unsigned bh = p->ring_head, bc = p->ring_count;
        iii_ast_node_t *st = iiip_parse_stmt(p);
        if (st) iii_ast_add_child(p->arena, w, st);
        else if (bh == p->ring_head && bc == p->ring_count) consume(p, NULL);
    }
    expect_punct(p, IIIPN_RBRACE);
    /* until terminator */
    if (!accept_word(p, "until")) {
        iiip_record_error(p, P_E_EXPECTED_KEYWORD,
                          peek(p, 0) ? peek(p, 0)->text_offset : 0,
                          peek(p, 0) ? peek(p, 0)->text_offset + peek(p, 0)->text_len : 0,
                          peek(p, 0) ? peek(p, 0)->line : 0,
                          peek(p, 0) ? peek(p, 0)->col  : 0,
                          "expected 'until' after wavefront block");
    }
    iii_ast_node_t *term = iii_arena_node(p->arena, III_AST_WAVEFRONT_TERMINATOR);
    if (term) {
        const iii_token_t *t0 = peek(p, 0);
        if (t0) iiip_node_span(term, t0, t0);
        if (accept_word(p, "quiescent")) {
            term->interned_id = iiip_intern_text(p, "quiescent");
        } else if (accept_word(p, "coherent")) {
            term->interned_id = iiip_intern_text(p, "coherent");
            expect_punct(p, IIIPN_LPAREN);
            iii_ast_node_t *ce = iiip_parse_coherence_expr(p);
            if (ce) iii_ast_add_child(p->arena, term, ce);
            const iii_token_t *rp = peek(p, 0);
            if (rp) term->span_end = rp->text_offset + rp->text_len;
            expect_punct(p, IIIPN_RPAREN);
        } else if (accept_word(p, "count")) {
            term->interned_id = iiip_intern_text(p, "count");
            expect_punct(p, IIIPN_LPAREN);
            const iii_token_t *nt = peek(p, 0);
            if (nt && nt->kind == IIIK_INT_LIT) { term->int_value = nt->int_value; consume(p, NULL); }
            const iii_token_t *rp = peek(p, 0);
            if (rp) term->span_end = rp->text_offset + rp->text_len;
            expect_punct(p, IIIPN_RPAREN);
        } else {
            iiip_record_error(p, P_E_UNEXPECTED_TOKEN,
                              t0 ? t0->text_offset : 0,
                              t0 ? t0->text_offset + t0->text_len : 0,
                              t0 ? t0->line : 0, t0 ? t0->col : 0,
                              "expected wavefront terminator");
        }
        iii_ast_add_child(p->arena, w, term);
        w->span_end = term->span_end;
    }
    return w;
}

/* sanctum_stmt: 'sanctum_enter' '|' IDENT '|' '{' statement_list '}' */
static iii_ast_node_t *parse_sanctum_stmt(iii_parser_t *p) {
    iii_token_t kw = *peek(p, 0);
    consume(p, NULL);
    iii_ast_node_t *s = iii_arena_node(p->arena, III_AST_SANCTUM_STMT);
    if (!s) return NULL;
    iiip_node_span(s, &kw, &kw);
    expect_punct(p, IIIPN_PIPE);
    iii_token_t fr;
    if (expect_ident(p, &fr)) s->interned_id = fr.interned_id;
    expect_punct(p, IIIPN_PIPE);
    expect_punct(p, IIIPN_LBRACE);
    while (peek(p, 0) && peek(p, 0)->kind != IIIK_EOF && !peek_pn(p, IIIPN_RBRACE)) {
        unsigned bh = p->ring_head, bc = p->ring_count;
        iii_ast_node_t *st = iiip_parse_stmt(p);
        if (st) iii_ast_add_child(p->arena, s, st);
        else if (bh == p->ring_head && bc == p->ring_count) consume(p, NULL);
    }
    const iii_token_t *rb = peek(p, 0);
    if (rb) s->span_end = rb->text_offset + rb->text_len;
    expect_punct(p, IIIPN_RBRACE);
    return s;
}

/* metal_stmt: 'metal' metal_modifier* '{' raw_asm '}'
 * raw_asm parsed permissively: every token until matching '}'. */
static iii_ast_node_t *parse_metal_stmt(iii_parser_t *p) {
    iii_token_t kw = *peek(p, 0);
    consume(p, NULL);
    iii_ast_node_t *m = iii_arena_node(p->arena, III_AST_METAL_STMT);
    if (!m) return NULL;
    iiip_node_span(m, &kw, &kw);
    /* Reuse modifier-set machinery for @ring/@admits_caps. */
    iiip_parse_modifiers(p, m, III_AST_WAVEFRONT_MODIFIER); /* reuse kind */
    expect_punct(p, IIIPN_LBRACE);
    int depth = 1;
    while (peek(p, 0) && peek(p, 0)->kind != IIIK_EOF && depth > 0) {
        if (peek_pn(p, IIIPN_LBRACE)) depth++;
        else if (peek_pn(p, IIIPN_RBRACE)) { depth--; if (depth == 0) break; }
        consume(p, NULL);
    }
    const iii_token_t *rb = peek(p, 0);
    if (rb) m->span_end = rb->text_offset + rb->text_len;
    expect_punct(p, IIIPN_RBRACE);
    return m;
}

static iii_ast_node_t *parse_return_stmt(iii_parser_t *p) {
    iii_token_t kw = *peek(p, 0);
    consume(p, NULL);
    iii_ast_node_t *r = iii_arena_node(p->arena, III_AST_RETURN_STMT);
    if (!r) return NULL;
    iiip_node_span(r, &kw, &kw);
    if (!peek_pn(p, IIIPN_SEMI)) {
        iii_ast_node_t *e = iiip_parse_expr(p);
        if (e) { iii_ast_add_child(p->arena, r, e); r->span_end = e->span_end; }
    }
    const iii_token_t *semi = peek(p, 0);
    if (semi) r->span_end = semi->text_offset + semi->text_len;
    expect_punct(p, IIIPN_SEMI);
    return r;
}

static iii_ast_node_t *parse_promote_stmt(iii_parser_t *p) {
    iii_token_t kw = *peek(p, 0);
    consume(p, NULL);
    iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_PROMOTE_STMT);
    if (!n) return NULL;
    iiip_node_span(n, &kw, &kw);
    expect_punct(p, IIIPN_LBRACE);
    while (peek(p, 0) && peek(p, 0)->kind != IIIK_EOF && !peek_pn(p, IIIPN_RBRACE)) {
        unsigned bh = p->ring_head, bc = p->ring_count;
        iii_ast_node_t *st = iiip_parse_stmt(p);
        if (st) iii_ast_add_child(p->arena, n, st);
        else if (bh == p->ring_head && bc == p->ring_count) consume(p, NULL);
    }
    const iii_token_t *rb = peek(p, 0);
    if (rb) n->span_end = rb->text_offset + rb->text_len;
    expect_punct(p, IIIPN_RBRACE);
    return n;
}

static iii_ast_node_t *parse_explain_stmt(iii_parser_t *p) {
    iii_token_t kw = *peek(p, 0);
    consume(p, NULL);
    iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_EXPLAIN_STMT);
    if (!n) return NULL;
    iiip_node_span(n, &kw, &kw);
    expect_punct(p, IIIPN_LPAREN);
    iii_ast_node_t *e = iiip_parse_expr(p);
    if (e) iii_ast_add_child(p->arena, n, e);
    if (accept_pn(p, IIIPN_COMMA)) {
        iii_token_t lvl;
        if (expect_ident(p, &lvl)) n->interned_id = lvl.interned_id;
    }
    expect_punct(p, IIIPN_RPAREN);
    const iii_token_t *semi = peek(p, 0);
    if (semi) n->span_end = semi->text_offset + semi->text_len;
    expect_punct(p, IIIPN_SEMI);
    return n;
}

static iii_ast_node_t *parse_propose_stmt(iii_parser_t *p) {
    iii_token_t kw = *peek(p, 0);
    consume(p, NULL);
    iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_PROPOSE_STMT);
    if (!n) return NULL;
    iiip_node_span(n, &kw, &kw);
    expect_punct(p, IIIPN_LBRACE);
    parse_keyed_args(p, n, III_AST_PROPOSE_FIELD);
    const iii_token_t *rb = peek(p, 0);
    if (rb) n->span_end = rb->text_offset + rb->text_len;
    expect_punct(p, IIIPN_RBRACE);
    return n;
}

static iii_ast_node_t *parse_negotiate_stmt(iii_parser_t *p) {
    iii_token_t kw = *peek(p, 0);
    consume(p, NULL);
    iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_NEGOTIATE_STMT);
    if (!n) return NULL;
    iiip_node_span(n, &kw, &kw);
    expect_punct(p, IIIPN_LPAREN);
    parse_keyed_args(p, n, III_AST_NEGOTIATE_ARG);
    expect_punct(p, IIIPN_RPAREN);
    const iii_token_t *semi = peek(p, 0);
    if (semi) n->span_end = semi->text_offset + semi->text_len;
    expect_punct(p, IIIPN_SEMI);
    return n;
}

static iii_ast_node_t *parse_reflect_stmt(iii_parser_t *p) {
    iii_token_t kw = *peek(p, 0);
    consume(p, NULL);
    iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_REFLECT_STMT);
    if (!n) return NULL;
    iiip_node_span(n, &kw, &kw);
    expect_punct(p, IIIPN_LPAREN);
    iii_token_t tgt;
    if (peek(p, 0) && (peek(p, 0)->kind == IIIK_IDENT || peek(p, 0)->kind == IIIK_KEYWORD)) {
        tgt = *peek(p, 0); consume(p, NULL);
        n->interned_id = tgt.interned_id;
    }
    expect_punct(p, IIIPN_RPAREN);
    const iii_token_t *semi = peek(p, 0);
    if (semi) n->span_end = semi->text_offset + semi->text_len;
    expect_punct(p, IIIPN_SEMI);
    return n;
}

static iii_ast_node_t *parse_commit_stmt(iii_parser_t *p) {
    iii_token_t kw = *peek(p, 0);
    consume(p, NULL);
    iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_COMMIT_STMT);
    if (!n) return NULL;
    iiip_node_span(n, &kw, &kw);
    expect_punct(p, IIIPN_LPAREN);
    parse_keyed_args(p, n, III_AST_COMMIT_ARG);
    expect_punct(p, IIIPN_RPAREN);
    const iii_token_t *semi = peek(p, 0);
    if (semi) n->span_end = semi->text_offset + semi->text_len;
    expect_punct(p, IIIPN_SEMI);
    return n;
}

/* reverse_stmt: 'inverse' '.' 'replay' '(' expr (',' expr)? ')' ';' */
static iii_ast_node_t *parse_reverse_stmt(iii_parser_t *p) {
    iii_token_t kw = *peek(p, 0);
    consume(p, NULL);            /* 'inverse' */
    expect_punct(p, IIIPN_DOT);
    if (!expect_word(p, "replay")) {
        iiip_skip_to_recovery(p, STMT_RECOVERY);
        accept_pn(p, IIIPN_SEMI);
        return NULL;
    }
    iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_REVERSE_STMT);
    if (!n) return NULL;
    iiip_node_span(n, &kw, &kw);
    expect_punct(p, IIIPN_LPAREN);
    iii_ast_node_t *a = iiip_parse_expr(p);
    if (a) iii_ast_add_child(p->arena, n, a);
    if (accept_pn(p, IIIPN_COMMA)) {
        iii_ast_node_t *b = iiip_parse_expr(p);
        if (b) iii_ast_add_child(p->arena, n, b);
    }
    expect_punct(p, IIIPN_RPAREN);
    const iii_token_t *semi = peek(p, 0);
    if (semi) n->span_end = semi->text_offset + semi->text_len;
    expect_punct(p, IIIPN_SEMI);
    return n;
}

/* ask_stmt: 'uncertainty' '.' 'in' '(' expr ')' ';'
 *         | 'narrative'   '.' 'reflect' '(' expr ')' ';' */
static iii_ast_node_t *parse_ask_stmt(iii_parser_t *p) {
    iii_token_t kw = *peek(p, 0);
    int is_unc = peek_kw(p, IIIKW_UNCERTAINTY);
    consume(p, NULL);                /* uncertainty | narrative */
    expect_punct(p, IIIPN_DOT);
    const char *expected = is_unc ? "in" : "reflect";
    if (!expect_word(p, expected)) {
        iiip_skip_to_recovery(p, STMT_RECOVERY);
        accept_pn(p, IIIPN_SEMI);
        return NULL;
    }
    iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_ASK_STMT);
    if (!n) return NULL;
    iiip_node_span(n, &kw, &kw);
    n->interned_id = kw.interned_id; /* mark variant by introducer kw */
    expect_punct(p, IIIPN_LPAREN);
    iii_ast_node_t *e = iiip_parse_expr(p);
    if (e) iii_ast_add_child(p->arena, n, e);
    expect_punct(p, IIIPN_RPAREN);
    const iii_token_t *semi = peek(p, 0);
    if (semi) n->span_end = semi->text_offset + semi->text_len;
    expect_punct(p, IIIPN_SEMI);
    return n;
}

static iii_ast_node_t *parse_block_stmt(iii_parser_t *p) {
    iii_ast_node_t *be = iiip_parse_block_expr(p);
    if (!be) return NULL;
    iii_ast_node_t *bs = iii_arena_node(p->arena, III_AST_BLOCK_STMT);
    if (!bs) return be;
    bs->span_start = be->span_start; bs->span_end = be->span_end;
    bs->line = be->line; bs->col = be->col;
    iii_ast_add_child(p->arena, bs, be);
    /* optional trailing ';' */
    if (peek_pn(p, IIIPN_SEMI)) {
        const iii_token_t *semi = peek(p, 0);
        bs->span_end = semi->text_offset + semi->text_len;
        consume(p, NULL);
    }
    return bs;
}
