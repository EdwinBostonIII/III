/* III Grammar — §4 Module-level productions and entry point. */
#include "parse_internal.h"

static int peek_pn(iii_parser_t *p, iii_pn_e n) { return tok_is_pn(peek(p, 0), p, n); }

/* qualified_name ::= IDENT ('.' IDENT)* */
iii_ast_node_t *iiip_parse_qualified_name(iii_parser_t *p) {
    iii_token_t first;
    if (!expect_ident(p, &first)) return NULL;
    iii_ast_node_t *qn = iii_arena_node(p->arena, III_AST_QUALIFIED_NAME);
    if (!qn) return NULL;
    qn->interned_id = first.interned_id;
    iiip_node_span(qn, &first, &first);
    /* Append a child IDENT-named PARAM-shaped node per segment to preserve order. */
    {
        iii_ast_node_t *seg = iii_arena_node(p->arena, III_AST_PARAM);
        if (seg) {
            seg->interned_id = first.interned_id;
            iiip_node_span(seg, &first, &first);
            iii_ast_add_child(p->arena, qn, seg);
        }
    }
    while (peek_pn(p, IIIPN_DOT) &&
           peek(p, 1) && peek(p, 1)->kind == IIIK_IDENT) {
        consume(p, NULL); /* '.' */
        iii_token_t seg_tok;
        if (!expect_ident(p, &seg_tok)) break;
        iii_ast_node_t *seg = iii_arena_node(p->arena, III_AST_PARAM);
        if (seg) {
            seg->interned_id = seg_tok.interned_id;
            iiip_node_span(seg, &seg_tok, &seg_tok);
            iii_ast_add_child(p->arena, qn, seg);
            qn->span_end = seg->span_end;
        }
    }
    return qn;
}

/* ---- module_attr -------------------------------------------------- */

static iii_ast_node_t *parse_one_module_attr(iii_parser_t *p) {
    const iii_token_t *t = peek(p, 0);
    if (!t || t->kind != IIIK_MODIFIER) return NULL;
    iii_mod_e which = IIIMOD_COUNT;
    int is_version = 0;
    if      (t->interned_id == p->mod_id[IIIMOD_CLOSURE])     which = IIIMOD_CLOSURE;
    else if (t->interned_id == p->mod_id[IIIMOD_RING])        which = IIIMOD_RING;
    else if (t->interned_id == p->mod_id[IIIMOD_PLAN_ANCHOR]) which = IIIMOD_PLAN_ANCHOR;
    else if (t->interned_id == p->mod_id[IIIMOD_TIER])        which = IIIMOD_TIER;
    else if (t->interned_id == iiip_intern_text(p, "@version")) is_version = 1;
    else return NULL;
    iii_token_t mt = *t;
    consume(p, NULL);
    iii_ast_node_t *node = iii_arena_node(p->arena, III_AST_MODULE_ATTR);
    if (!node) return NULL;
    iiip_node_span(node, &mt, &mt);
    node->op_id = (uint16_t)(is_version ? IIIMOD_COUNT : which);
    node->interned_id = mt.interned_id;
    if (!expect_punct(p, IIIPN_LPAREN)) return node;
    if (is_version) {
        const iii_token_t *st = peek(p, 0);
        if (st && st->kind == IIIK_STRING_LIT) {
            node->string_payload = st->string_payload;
            node->string_len = st->string_len;
            consume(p, NULL);
        }
    } else if (which == IIIMOD_CLOSURE) {
        const iii_token_t *mh = peek(p, 0);
        if (mh && mh->kind == IIIK_MHASH_LIT) {
            memcpy(node->mhash_value, mh->mhash_value, 32);
            consume(p, NULL);
        }
    } else if (which == IIIMOD_RING) {
        iii_ast_node_t *rs = iiip_parse_ring_set(p);
        if (rs) iii_ast_add_child(p->arena, node, rs);
    } else if (which == IIIMOD_PLAN_ANCHOR) {
        iii_token_t id;
        if (expect_ident(p, &id)) node->interned_id = id.interned_id;
    } else if (which == IIIMOD_TIER) {
        iii_ast_node_t *tn = iiip_parse_tier_name(p);
        if (tn) iii_ast_add_child(p->arena, node, tn);
    }
    const iii_token_t *rp = peek(p, 0);
    if (rp) node->span_end = rp->text_offset + rp->text_len;
    expect_punct(p, IIIPN_RPAREN);
    return node;
}

/* ---- import_attr -------------------------------------------------- */

static iii_ast_node_t *parse_one_import_attr(iii_parser_t *p) {
    const iii_token_t *t = peek(p, 0);
    if (!t || t->kind != IIIK_MODIFIER) return NULL;
    iii_mod_e which;
    if      (t->interned_id == p->mod_id[IIIMOD_CLOSURE]) which = IIIMOD_CLOSURE;
    else if (t->interned_id == p->mod_id[IIIMOD_RING])    which = IIIMOD_RING;
    else if (t->interned_id == p->mod_id[IIIMOD_TIER])    which = IIIMOD_TIER;
    else return NULL;
    iii_token_t mt = *t;
    consume(p, NULL);
    iii_ast_node_t *node = iii_arena_node(p->arena, III_AST_IMPORT_ATTR);
    if (!node) return NULL;
    iiip_node_span(node, &mt, &mt);
    node->op_id = (uint16_t)which;
    node->interned_id = mt.interned_id;
    expect_punct(p, IIIPN_LPAREN);
    if (which == IIIMOD_CLOSURE) {
        const iii_token_t *mh = peek(p, 0);
        if (mh && mh->kind == IIIK_MHASH_LIT) {
            memcpy(node->mhash_value, mh->mhash_value, 32);
            consume(p, NULL);
        }
    } else if (which == IIIMOD_RING) {
        iii_ast_node_t *rs = iiip_parse_ring_set(p);
        if (rs) iii_ast_add_child(p->arena, node, rs);
    } else { /* TIER */
        iii_ast_node_t *tn = iiip_parse_tier_name(p);
        if (tn) iii_ast_add_child(p->arena, node, tn);
    }
    const iii_token_t *rp = peek(p, 0);
    if (rp) node->span_end = rp->text_offset + rp->text_len;
    expect_punct(p, IIIPN_RPAREN);
    return node;
}

/* ---- import ------------------------------------------------------- */

static iii_ast_node_t *parse_import(iii_parser_t *p) {
    iii_token_t kw = *peek(p, 0);
    consume(p, NULL); /* 'use' (IDENT) */
    iii_ast_node_t *imp = iii_arena_node(p->arena, III_AST_IMPORT);
    if (!imp) return NULL;
    iiip_node_span(imp, &kw, &kw);
    imp->doc_offset = iiip_take_pending_doc(p);
    iii_ast_node_t *qn = iiip_parse_qualified_name(p);
    if (qn) { iii_ast_add_child(p->arena, imp, qn); imp->span_end = qn->span_end; }
    while (peek(p, 0) && peek(p, 0)->kind == IIIK_MODIFIER) {
        iii_ast_node_t *a = parse_one_import_attr(p);
        if (!a) break;
        iii_ast_add_child(p->arena, imp, a);
        imp->span_end = a->span_end;
    }
    return imp;
}

/* ---- entry point -------------------------------------------------- */

static const iii_pn_e MODULE_RECOVERY[] = { IIIPN_RBRACE, IIIPN_COUNT };

/* Post-parse pass: for every node carrying an interned IDENT id (e.g.
 * MODULE name, QUALIFIED_NAME segments) but no string_payload yet,
 * resolve the literal text via the intern table and attach it.  This
 * makes the canonical hash sensitive to the actual textual identifier
 * (rather than just the per-parser intern id, which is non-stable
 * across distinct sources).  Modifier nodes already carry the
 * canonical interned id (so @safety/@hexad continue to share text). */
static void resolve_idents(iii_ast_node_t *n, iii_lex_state_t *lex) {
    if (!n) return;
    if (n->interned_id != 0u && n->string_payload == NULL) {
        size_t len = 0;
        const char *txt = iii_lex_intern_text(lex, n->interned_id, &len);
        if (txt && len > 0) {
            n->string_payload = (const uint8_t *)txt;
            n->string_len = (uint32_t)len;
        }
    }
    for (uint32_t i = 0; i < n->child_count; ++i) {
        resolve_idents(n->children[i], lex);
    }
}

iii_ast_node_t *iii_parse_module(iii_parser_t *p) {
    if (!p) return NULL;
    iii_ast_node_t *root = iii_arena_node(p->arena, III_AST_MODULE);
    if (!root) return NULL;

    /* Accept any leading doc comments. */
    while (peek(p, 0) && peek(p, 0)->kind == IIIK_DOC_COMMENT) {
        iii_token_t doc = *peek(p, 0);
        consume(p, NULL);
        p->pending_doc_offset = doc.text_offset;
    }

    /* 'module' qualified_name */
    if (!accept_kw(p, IIIKW_MODULE)) {
        const iii_token_t *t = peek(p, 0);
        iiip_record_error(p, P_E_EXPECTED_KEYWORD,
                          t ? t->text_offset : 0,
                          t ? t->text_offset + t->text_len : 0,
                          t ? t->line : 0, t ? t->col : 0,
                          "expected 'module' at start of file");
    } else {
        const iii_token_t *t = peek(p, 0);
        if (t) iiip_node_span(root, t, t);
    }
    root->doc_offset = iiip_take_pending_doc(p);
    iii_ast_node_t *qn = iiip_parse_qualified_name(p);
    if (qn) {
        root->interned_id = qn->interned_id;
        iii_ast_add_child(p->arena, root, qn);
        root->span_end = qn->span_end;
    }

    /* module_attr* */
    while (peek(p, 0) && peek(p, 0)->kind != IIIK_EOF) {
        const iii_token_t *t = peek(p, 0);
        if (t->kind == IIIK_DOC_COMMENT) {
            iii_token_t doc = *t;
            consume(p, NULL);
            p->pending_doc_offset = doc.text_offset;
            continue;
        }
        if (t->kind != IIIK_MODIFIER) break;
        iii_ast_node_t *a = parse_one_module_attr(p);
        if (!a) break;
        iii_ast_add_child(p->arena, root, a);
        root->span_end = a->span_end;
    }

    /* import* */
    while (peek_word(p, 0, "use")) {
        iii_ast_node_t *im = parse_import(p);
        if (!im) break;
        iii_ast_add_child(p->arena, root, im);
        root->span_end = im->span_end;
    }

    /* item* */
    while (peek(p, 0) && peek(p, 0)->kind != IIIK_EOF) {
        unsigned bh = p->ring_head, bc = p->ring_count;
        iii_ast_node_t *it = iiip_parse_item(p);
        if (it) {
            iii_ast_add_child(p->arena, root, it);
            root->span_end = it->span_end;
        }
        if (bh == p->ring_head && bc == p->ring_count) {
            /* No progress — recover. */
            iiip_skip_to_recovery(p, MODULE_RECOVERY);
            if (peek(p, 0) && peek(p, 0)->kind != IIIK_EOF) consume(p, NULL);
        }
    }

    resolve_idents(root, p->lex);
    return root;
}
