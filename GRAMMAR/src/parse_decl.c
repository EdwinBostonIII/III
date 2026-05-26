/* III Grammar — §5 Item productions. */
#include "parse_internal.h"

static iii_ast_node_t *parse_cycle_decl   (iii_parser_t *p);
static iii_ast_node_t *parse_function_decl(iii_parser_t *p);
static iii_ast_node_t *parse_type_decl    (iii_parser_t *p);
static iii_ast_node_t *parse_mobius_decl  (iii_parser_t *p);
static iii_ast_node_t *parse_schema_decl  (iii_parser_t *p);
static iii_ast_node_t *parse_narrative_decl(iii_parser_t *p);
static iii_ast_node_t *parse_const_decl   (iii_parser_t *p);
static iii_ast_node_t *parse_extern_decl  (iii_parser_t *p);
static iii_ast_node_t *parse_doc_attached (iii_parser_t *p);

static int peek_kw(iii_parser_t *p, iii_kw_e k) { return tok_is_kw(peek(p, 0), p, k); }
static int peek_pn(iii_parser_t *p, iii_pn_e n) { return tok_is_pn(peek(p, 0), p, n); }

static const iii_pn_e ITEM_RECOVERY[] = { IIIPN_RBRACE, IIIPN_SEMI, IIIPN_COUNT };

iii_ast_node_t *iiip_parse_item(iii_parser_t *p) {
    const iii_token_t *t = peek(p, 0);
    if (!t || t->kind == IIIK_EOF) return NULL;

    if (t->kind == IIIK_DOC_COMMENT) return parse_doc_attached(p);
    if (peek_kw(p, IIIKW_CYCLE))             return parse_cycle_decl(p);
    if (peek_word(p, 0, "fn"))               return parse_function_decl(p);
    if (peek_word(p, 0, "type"))             return parse_type_decl(p);
    if (peek_kw(p, IIIKW_MOBIUS_CANDIDATE))  return parse_mobius_decl(p);
    if (peek_kw(p, IIIKW_SCHEMA))            return parse_schema_decl(p);
    if (peek_kw(p, IIIKW_NARRATIVE))         return parse_narrative_decl(p);
    if (peek_word(p, 0, "const"))            return parse_const_decl(p);
    if (peek_kw(p, IIIKW_EXTERN))            return parse_extern_decl(p);

    iiip_record_error(p, P_E_UNEXPECTED_TOKEN,
                      t->text_offset, t->text_offset + t->text_len,
                      t->line, t->col,
                      "expected item, got %s", iii_token_kind_name(t->kind));
    iii_ast_node_t *e = iiip_error_node(p);
    iiip_skip_to_recovery(p, ITEM_RECOVERY);
    /* Skip past the recovery point if it's a brace-closer. */
    if (peek_pn(p, IIIPN_RBRACE)) consume(p, NULL);
    return e;
}

static iii_ast_node_t *parse_doc_attached(iii_parser_t *p) {
    iii_token_t doc = *peek(p, 0);
    consume(p, NULL);
    /* Stash for the next item. */
    p->pending_doc_offset = doc.text_offset;
    iii_ast_node_t *d = iii_arena_node(p->arena, III_AST_DOC_ATTACHED);
    if (d) { iiip_node_span(d, &doc, &doc); d->doc_offset = doc.text_offset; }
    return d;
}

/* ---- 5.2 fn / 5.4 mobius_candidate share param_list machinery -------- */

static void parse_param_list(iii_parser_t *p, iii_ast_node_t *parent) {
    expect_punct(p, IIIPN_LPAREN);
    if (accept_pn(p, IIIPN_RPAREN)) return;
    do {
        iii_token_t id;
        iii_ast_node_t *prm = iii_arena_node(p->arena, III_AST_PARAM);
        if (!prm) break;
        if (expect_ident(p, &id)) {
            prm->interned_id = id.interned_id;
            iiip_node_span(prm, &id, &id);
        }
        if (expect_punct(p, IIIPN_COLON)) {
            iii_ast_node_t *ty = iiip_parse_type(p);
            if (ty) { iii_ast_add_child(p->arena, prm, ty); prm->span_end = ty->span_end; }
        }
        iii_ast_add_child(p->arena, parent, prm);
    } while (accept_pn(p, IIIPN_COMMA));
    expect_punct(p, IIIPN_RPAREN);
}

static void parse_generic_params(iii_parser_t *p, iii_ast_node_t *parent) {
    if (!accept_pn(p, IIIPN_LT)) return;
    do {
        iii_token_t id;
        iii_ast_node_t *gp = iii_arena_node(p->arena, III_AST_GENERIC_PARAM);
        if (!gp) break;
        if (expect_ident(p, &id)) {
            gp->interned_id = id.interned_id;
            iiip_node_span(gp, &id, &id);
        }
        if (accept_pn(p, IIIPN_COLON)) {
            /* type_constraint: 'Hexad' | 'Phase' | 'Tier' | 'Epoch' | type */
            iii_ast_node_t *ty = iiip_parse_type(p);
            if (ty) { iii_ast_add_child(p->arena, gp, ty); gp->span_end = ty->span_end; }
        }
        iii_ast_add_child(p->arena, parent, gp);
    } while (accept_pn(p, IIIPN_COMMA));
    expect_punct(p, IIIPN_GT);
}

/* Forward {…} block, optional inverse {…}. */
static iii_ast_node_t *parse_forward_block(iii_parser_t *p) {
    iii_token_t kw = *peek(p, 0);
    if (!expect_word(p, "forward")) return NULL;
    iii_ast_node_t *fb = iii_arena_node(p->arena, III_AST_FORWARD_BLOCK);
    if (!fb) return NULL;
    iiip_node_span(fb, &kw, &kw);
    expect_punct(p, IIIPN_LBRACE);
    while (peek(p, 0) && peek(p, 0)->kind != IIIK_EOF && !peek_pn(p, IIIPN_RBRACE)) {
        unsigned bh = p->ring_head, bc = p->ring_count;
        iii_ast_node_t *st = iiip_parse_stmt(p);
        if (st) iii_ast_add_child(p->arena, fb, st);
        else if (bh == p->ring_head && bc == p->ring_count) consume(p, NULL);
    }
    const iii_token_t *rb = peek(p, 0);
    if (rb) fb->span_end = rb->text_offset + rb->text_len;
    expect_punct(p, IIIPN_RBRACE);
    return fb;
}

static iii_ast_node_t *parse_inverse_block(iii_parser_t *p) {
    iii_token_t kw = *peek(p, 0);
    consume(p, NULL); /* 'inverse' KW */
    iii_ast_node_t *ib = iii_arena_node(p->arena, III_AST_INVERSE_BLOCK);
    if (!ib) return NULL;
    iiip_node_span(ib, &kw, &kw);
    expect_punct(p, IIIPN_LBRACE);
    while (peek(p, 0) && peek(p, 0)->kind != IIIK_EOF && !peek_pn(p, IIIPN_RBRACE)) {
        unsigned bh = p->ring_head, bc = p->ring_count;
        iii_ast_node_t *st = iiip_parse_stmt(p);
        if (st) iii_ast_add_child(p->arena, ib, st);
        else if (bh == p->ring_head && bc == p->ring_count) consume(p, NULL);
    }
    const iii_token_t *rb = peek(p, 0);
    if (rb) ib->span_end = rb->text_offset + rb->text_len;
    expect_punct(p, IIIPN_RBRACE);
    return ib;
}

/* ---- 5.1 cycle ---------------------------------------------------- */

static iii_ast_node_t *parse_cycle_decl(iii_parser_t *p) {
    iii_token_t kw = *peek(p, 0);
    consume(p, NULL); /* 'cycle' */
    iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_CYCLE_DECL);
    if (!n) return NULL;
    iiip_node_span(n, &kw, &kw);
    n->doc_offset = iiip_take_pending_doc(p);
    iii_token_t id;
    if (expect_ident(p, &id)) n->interned_id = id.interned_id;
    parse_param_list(p, n);
    expect_punct(p, IIIPN_ARROW);
    iii_ast_node_t *ret = iiip_parse_type(p);
    if (ret) iii_ast_add_child(p->arena, n, ret);
    iiip_parse_modifiers(p, n, III_AST_CYCLE_MODIFIER);
    expect_punct(p, IIIPN_LBRACE);
    iii_ast_node_t *fb = parse_forward_block(p);
    if (fb) iii_ast_add_child(p->arena, n, fb);
    if (peek_kw(p, IIIKW_INVERSE)) {
        iii_ast_node_t *ib = parse_inverse_block(p);
        if (ib) iii_ast_add_child(p->arena, n, ib);
    }
    const iii_token_t *rb = peek(p, 0);
    if (rb) n->span_end = rb->text_offset + rb->text_len;
    expect_punct(p, IIIPN_RBRACE);
    return n;
}

/* ---- 5.2 fn ------------------------------------------------------- */

static iii_ast_node_t *parse_function_decl(iii_parser_t *p) {
    iii_token_t kw = *peek(p, 0);
    consume(p, NULL); /* 'fn' */
    iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_FUNCTION_DECL);
    if (!n) return NULL;
    iiip_node_span(n, &kw, &kw);
    n->doc_offset = iiip_take_pending_doc(p);
    iii_token_t id;
    if (expect_ident(p, &id)) n->interned_id = id.interned_id;
    parse_generic_params(p, n);
    parse_param_list(p, n);
    expect_punct(p, IIIPN_ARROW);
    iii_ast_node_t *ret = iiip_parse_type(p);
    if (ret) iii_ast_add_child(p->arena, n, ret);
    iiip_parse_modifiers(p, n, III_AST_FUNCTION_MODIFIER);
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

/* ---- 5.3 type ----------------------------------------------------- */

static iii_ast_node_t *parse_type_decl(iii_parser_t *p) {
    iii_token_t kw = *peek(p, 0);
    consume(p, NULL); /* 'type' (IDENT) */
    iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_TYPE_DECL);
    if (!n) return NULL;
    iiip_node_span(n, &kw, &kw);
    n->doc_offset = iiip_take_pending_doc(p);
    iii_token_t id;
    if (expect_ident(p, &id)) n->interned_id = id.interned_id;
    parse_generic_params(p, n);
    expect_punct(p, IIIPN_EQ);
    iii_ast_node_t *rhs = iiip_parse_type(p);
    if (rhs) iii_ast_add_child(p->arena, n, rhs);
    iiip_parse_modifiers(p, n, III_AST_TYPE_MODIFIER);
    /* No semicolon; the next item starts wherever. */
    return n;
}

/* ---- 5.4 mobius_candidate ----------------------------------------- */

static iii_ast_node_t *parse_mobius_decl(iii_parser_t *p) {
    iii_token_t kw = *peek(p, 0);
    consume(p, NULL);
    iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_MOBIUS_CANDIDATE_DECL);
    if (!n) return NULL;
    iiip_node_span(n, &kw, &kw);
    n->doc_offset = iiip_take_pending_doc(p);
    iii_token_t id;
    if (expect_ident(p, &id)) n->interned_id = id.interned_id;
    parse_param_list(p, n);
    expect_punct(p, IIIPN_ARROW);
    iii_ast_node_t *ret = iiip_parse_type(p);
    if (ret) iii_ast_add_child(p->arena, n, ret);
    iiip_parse_modifiers(p, n, III_AST_MOBIUS_CANDIDATE_MODIFIER);
    expect_punct(p, IIIPN_LBRACE);
    iii_ast_node_t *fb = parse_forward_block(p);
    if (fb) iii_ast_add_child(p->arena, n, fb);
    const iii_token_t *rb = peek(p, 0);
    if (rb) n->span_end = rb->text_offset + rb->text_len;
    expect_punct(p, IIIPN_RBRACE);
    return n;
}

/* ---- 5.5 schema --------------------------------------------------- */

static iii_ast_node_t *parse_schema_field_type(iii_parser_t *p) {
    /* Try named families with parameter shapes; fall back to IDENT. */
    const iii_token_t *t = peek(p, 0);
    if (!t || t->kind != IIIK_IDENT) {
        iiip_record_error(p, P_E_EXPECTED_TYPE,
                          t ? t->text_offset : 0,
                          t ? t->text_offset + t->text_len : 0,
                          t ? t->line : 0, t ? t->col : 0,
                          "expected schema field type");
        return iiip_error_node(p);
    }
    iii_token_t name = *t;
    consume(p, NULL);
    iii_ast_node_t *fty = iii_arena_node(p->arena, III_AST_BASE_TYPE);
    if (!fty) return NULL;
    fty->interned_id = name.interned_id;
    iiip_node_span(fty, &name, &name);
    /* Parameterised forms have '(' next. */
    if (!peek_pn(p, IIIPN_LPAREN)) return fty;
    consume(p, NULL); /* '(' */
    do {
        iii_token_t key;
        if (!expect_ident(p, &key)) break;
        if (!expect_punct(p, IIIPN_COLON)) break;
        const iii_token_t *vt = peek(p, 0);
        iii_ast_node_t *kv = iii_arena_node(p->arena, III_AST_NAMED_ARG);
        if (kv) {
            kv->interned_id = key.interned_id;
            iiip_node_span(kv, &key, &key);
            if (vt && (vt->kind == IIIK_INT_LIT || vt->kind == IIIK_Q14_LIT)) {
                iii_ast_node_t *lit = iii_arena_node(p->arena, III_AST_LITERAL);
                if (lit) {
                    lit->op_id = (uint16_t)vt->kind;
                    lit->int_value = vt->int_value;
                    lit->int_suffix = vt->int_suffix;
                    iiip_node_span(lit, vt, vt);
                    iii_ast_add_child(p->arena, kv, lit);
                    kv->span_end = lit->span_end;
                }
                consume(p, NULL);
            }
            iii_ast_add_child(p->arena, fty, kv);
        }
    } while (accept_pn(p, IIIPN_COMMA));
    const iii_token_t *rp = peek(p, 0);
    if (rp) fty->span_end = rp->text_offset + rp->text_len;
    expect_punct(p, IIIPN_RPAREN);
    return fty;
}

static iii_ast_node_t *parse_schema_decl(iii_parser_t *p) {
    iii_token_t kw = *peek(p, 0);
    consume(p, NULL);
    iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_SCHEMA_DECL);
    if (!n) return NULL;
    iiip_node_span(n, &kw, &kw);
    n->doc_offset = iiip_take_pending_doc(p);
    iii_token_t id;
    if (expect_ident(p, &id)) n->interned_id = id.interned_id;
    expect_punct(p, IIIPN_EQ);
    /* Expect 'OBSERVATORY' (KEYWORD).  Per BNF §5.5 the terminal is
     * spelled uppercase ('OBSERVATORY'); the lexicon's lower-case
     * 'observatory' keyword is also accepted as a synonym. */
    if (!accept_kw(p, IIIKW_OBSERVATORY) && !accept_word(p, "OBSERVATORY")) {
        iiip_record_error(p, P_E_EXPECTED_KEYWORD,
                          peek(p, 0) ? peek(p, 0)->text_offset : 0,
                          peek(p, 0) ? peek(p, 0)->text_offset + peek(p, 0)->text_len : 0,
                          peek(p, 0) ? peek(p, 0)->line : 0,
                          peek(p, 0) ? peek(p, 0)->col  : 0,
                          "expected 'OBSERVATORY' in schema declaration");
    }
    expect_punct(p, IIIPN_LBRACE);
    do {
        iii_token_t fname;
        if (!expect_ident(p, &fname)) break;
        if (!expect_punct(p, IIIPN_COLON)) break;
        iii_ast_node_t *fty = parse_schema_field_type(p);
        iii_ast_node_t *f = iii_arena_node(p->arena, III_AST_SCHEMA_FIELD);
        if (f) {
            f->interned_id = fname.interned_id;
            iiip_node_span(f, &fname, &fname);
            if (fty) { iii_ast_add_child(p->arena, f, fty); f->span_end = fty->span_end; }
            iii_ast_add_child(p->arena, n, f);
        }
    } while (accept_pn(p, IIIPN_COMMA));
    const iii_token_t *rb = peek(p, 0);
    if (rb) n->span_end = rb->text_offset + rb->text_len;
    expect_punct(p, IIIPN_RBRACE);
    return n;
}

/* ---- 5.6 narrative ------------------------------------------------ */

static iii_ast_node_t *parse_narrative_decl(iii_parser_t *p) {
    iii_token_t kw = *peek(p, 0);
    consume(p, NULL);
    iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_NARRATIVE_DECL);
    if (!n) return NULL;
    iiip_node_span(n, &kw, &kw);
    n->doc_offset = iiip_take_pending_doc(p);
    expect_punct(p, IIIPN_LBRACE);
    do {
        iii_token_t key;
        if (!expect_ident(p, &key)) break;
        if (!expect_punct(p, IIIPN_COLON)) break;
        iii_ast_node_t *e = iiip_parse_expr(p);
        iii_ast_node_t *f = iii_arena_node(p->arena, III_AST_NARRATIVE_FIELD);
        if (f) {
            f->interned_id = key.interned_id;
            iiip_node_span(f, &key, &key);
            if (e) { iii_ast_add_child(p->arena, f, e); f->span_end = e->span_end; }
            iii_ast_add_child(p->arena, n, f);
        }
    } while (accept_pn(p, IIIPN_COMMA));
    const iii_token_t *rb = peek(p, 0);
    if (rb) n->span_end = rb->text_offset + rb->text_len;
    expect_punct(p, IIIPN_RBRACE);
    return n;
}

/* ---- 5.7 const ---------------------------------------------------- */

static iii_ast_node_t *parse_const_decl(iii_parser_t *p) {
    iii_token_t kw = *peek(p, 0);
    consume(p, NULL); /* 'const' */
    iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_CONST_DECL);
    if (!n) return NULL;
    iiip_node_span(n, &kw, &kw);
    n->doc_offset = iiip_take_pending_doc(p);
    iii_token_t id;
    if (expect_ident(p, &id)) n->interned_id = id.interned_id;
    expect_punct(p, IIIPN_COLON);
    iii_ast_node_t *ty = iiip_parse_type(p);
    if (ty) iii_ast_add_child(p->arena, n, ty);
    expect_punct(p, IIIPN_EQ);
    iii_ast_node_t *e = iiip_parse_expr(p);
    if (e) iii_ast_add_child(p->arena, n, e);
    iiip_parse_modifiers(p, n, III_AST_TYPE_MODIFIER);
    return n;
}

/* ---- 5.8 extern --------------------------------------------------- */

/* extern_type: i8/.../bool | '&' extern_type | '[' extern_type ';' INT_LIT ']' | IDENT
 * NOTE: the BNF '*' raw-pointer form is not lexable in current punctuator set;
 *       handled only via '&' and IDENT/primitive paths. */
static iii_ast_node_t *parse_extern_type(iii_parser_t *p) {
    if (accept_pn(p, IIIPN_AMP)) {
        iii_ast_node_t *inner = parse_extern_type(p);
        iii_ast_node_t *ref = iii_arena_node(p->arena, III_AST_TYPE);
        if (ref && inner) { iii_ast_add_child(p->arena, ref, inner);
            ref->span_start = inner->span_start; ref->span_end = inner->span_end; }
        return ref ? ref : inner;
    }
    if (accept_pn(p, IIIPN_LBRACK)) {
        iii_ast_node_t *inner = parse_extern_type(p);
        iii_ast_node_t *arr = iii_arena_node(p->arena, III_AST_ARRAY_TYPE);
        if (arr && inner) iii_ast_add_child(p->arena, arr, inner);
        if (accept_pn(p, IIIPN_SEMI)) {
            const iii_token_t *t = peek(p, 0);
            if (t && t->kind == IIIK_INT_LIT) {
                if (arr) arr->int_value = t->int_value;
                consume(p, NULL);
            }
        }
        const iii_token_t *rb = peek(p, 0);
        if (arr && rb) arr->span_end = rb->text_offset + rb->text_len;
        expect_punct(p, IIIPN_RBRACK);
        return arr ? arr : inner;
    }
    /* primitive or IDENT — defer to standard type parser. */
    return iiip_parse_type(p);
}

static iii_ast_node_t *parse_extern_decl(iii_parser_t *p) {
    iii_token_t kw = *peek(p, 0);
    consume(p, NULL); /* 'extern' */
    iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_EXTERN_DECL);
    if (!n) return NULL;
    iiip_node_span(n, &kw, &kw);
    n->doc_offset = iiip_take_pending_doc(p);
    /* '@abi' '(' abi_name ')' */
    iii_token_t mt;
    const iii_token_t *mp = peek(p, 0);
    if (mp && mp->kind == IIIK_MODIFIER &&
        mp->interned_id == iiip_intern_text(p, "@abi")) {
        mt = *mp;
        consume(p, NULL);
        n->op_id = (uint16_t)mt.interned_id;
        expect_punct(p, IIIPN_LPAREN);
        iii_token_t name;
        if (peek(p, 0) && peek(p, 0)->kind == IIIK_IDENT) {
            name = *peek(p, 0);
            n->interned_id = name.interned_id;
            consume(p, NULL);
        }
        expect_punct(p, IIIPN_RPAREN);
    } else {
        iiip_record_error(p, P_E_EXPECTED_KEYWORD,
                          mp ? mp->text_offset : 0,
                          mp ? mp->text_offset + mp->text_len : 0,
                          mp ? mp->line : 0, mp ? mp->col : 0,
                          "expected '@abi(...)' after 'extern'");
    }
    expect_punct(p, IIIPN_LBRACE);
    while (peek(p, 0) && peek(p, 0)->kind != IIIK_EOF && !peek_pn(p, IIIPN_RBRACE)) {
        const iii_token_t *t = peek(p, 0);
        if (t->kind == IIIK_DOC_COMMENT) {
            iii_token_t doc = *t;
            consume(p, NULL);
            p->pending_doc_offset = doc.text_offset;
            continue;
        }
        if (peek_word(p, 0, "fn")) {
            iii_token_t fkw = *t;
            consume(p, NULL);
            iii_ast_node_t *it = iii_arena_node(p->arena, III_AST_EXTERN_ITEM);
            if (!it) break;
            iiip_node_span(it, &fkw, &fkw);
            it->op_id = 0; /* 0 = fn */
            it->doc_offset = iiip_take_pending_doc(p);
            iii_token_t fid;
            if (expect_ident(p, &fid)) it->interned_id = fid.interned_id;
            expect_punct(p, IIIPN_LPAREN);
            if (!peek_pn(p, IIIPN_RPAREN)) {
                do {
                    iii_token_t pid;
                    iii_ast_node_t *prm = iii_arena_node(p->arena, III_AST_PARAM);
                    if (!prm) break;
                    if (expect_ident(p, &pid)) {
                        prm->interned_id = pid.interned_id;
                        iiip_node_span(prm, &pid, &pid);
                    }
                    if (expect_punct(p, IIIPN_COLON)) {
                        iii_ast_node_t *ty = parse_extern_type(p);
                        if (ty) iii_ast_add_child(p->arena, prm, ty);
                    }
                    iii_ast_add_child(p->arena, it, prm);
                } while (accept_pn(p, IIIPN_COMMA));
            }
            expect_punct(p, IIIPN_RPAREN);
            expect_punct(p, IIIPN_ARROW);
            iii_ast_node_t *ret = parse_extern_type(p);
            if (ret) iii_ast_add_child(p->arena, it, ret);
            const iii_token_t *semi = peek(p, 0);
            if (semi) it->span_end = semi->text_offset + semi->text_len;
            expect_punct(p, IIIPN_SEMI);
            iii_ast_add_child(p->arena, n, it);
        } else if (peek_word(p, 0, "type")) {
            iii_token_t tkw = *t;
            consume(p, NULL);
            iii_ast_node_t *it = iii_arena_node(p->arena, III_AST_EXTERN_ITEM);
            if (!it) break;
            iiip_node_span(it, &tkw, &tkw);
            it->op_id = 1; /* 1 = type */
            it->doc_offset = iiip_take_pending_doc(p);
            iii_token_t tid;
            if (expect_ident(p, &tid)) it->interned_id = tid.interned_id;
            expect_punct(p, IIIPN_EQ);
            iii_ast_node_t *ty = parse_extern_type(p);
            if (ty) iii_ast_add_child(p->arena, it, ty);
            const iii_token_t *semi = peek(p, 0);
            if (semi) it->span_end = semi->text_offset + semi->text_len;
            expect_punct(p, IIIPN_SEMI);
            iii_ast_add_child(p->arena, n, it);
        } else {
            iiip_record_error(p, P_E_UNEXPECTED_TOKEN,
                              t->text_offset, t->text_offset + t->text_len,
                              t->line, t->col,
                              "expected 'fn' or 'type' in extern block");
            iiip_skip_to_recovery(p, ITEM_RECOVERY);
            if (peek_pn(p, IIIPN_SEMI)) consume(p, NULL);
        }
    }
    const iii_token_t *rb = peek(p, 0);
    if (rb) n->span_end = rb->text_offset + rb->text_len;
    expect_punct(p, IIIPN_RBRACE);
    return n;
}
