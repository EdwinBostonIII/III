/* III Grammar — §8 Expression productions (precedence-climbing).
 *
 * Loose → tight:
 *  L0 cognitive (right):    ⟐⟐ ⟡⟡ ⟴⟴
 *  L1 catalyst (right):     ⊛ ⧄ ⧋ ⧇
 *  L2 federation (left):    ⟶ ⨁
 *  L3 ceiling/trinity (R):  ⟁ ⟐
 *  L4 phase/epoch (left):   ⟴ ring ; ⟵ '@epoch'(N)   (chained → error per §10.4)
 *  L5 cap/coherence (left): ⧈ acquire/release ; ⧗ Q14|coherence_expr
 *  L6 additive (left):      ⊕ ⧉ + -
 *  L7 multiplicative:       * / % ⧊
 *  L8 comparison (none):    == != < > ≤ ≥
 *  L10 materialise:         ⊗ glyph
 *  L11 unary postfix:       ⟡ ↻ ⟲⟲ ⟲
 *  L12 unary prefix:        - !
 *  L13 call/index/field:    () [] . ::
 *  Primary
 */
#include "parse_internal.h"

/* Forward declarations of the level functions. */
static iii_ast_node_t *parse_lvl0 (iii_parser_t *p);
static iii_ast_node_t *parse_lvl1 (iii_parser_t *p);
static iii_ast_node_t *parse_lvl2 (iii_parser_t *p);
static iii_ast_node_t *parse_lvl3 (iii_parser_t *p);
static iii_ast_node_t *parse_lvl4 (iii_parser_t *p);
static iii_ast_node_t *parse_lvl5 (iii_parser_t *p);
static iii_ast_node_t *parse_lvl6 (iii_parser_t *p);
static iii_ast_node_t *parse_lvl7 (iii_parser_t *p);
static iii_ast_node_t *parse_lvl8 (iii_parser_t *p);
static iii_ast_node_t *parse_lvl10(iii_parser_t *p);
static iii_ast_node_t *parse_lvl11(iii_parser_t *p);
static iii_ast_node_t *parse_lvl12(iii_parser_t *p);
static iii_ast_node_t *parse_lvl13(iii_parser_t *p);
static iii_ast_node_t *parse_primary(iii_parser_t *p);

/* ---- helpers --------------------------------------------------------- */

static iii_ast_node_t *make_infix(iii_parser_t *p,
                                  iii_ast_node_t *lhs,
                                  iii_ast_node_t *rhs,
                                  iii_op_e op,
                                  iii_ast_kind_t outer_lvl) {
    iii_ast_node_t *infix = iii_arena_node(p->arena, III_AST_INFIX_OP);
    if (!infix) return lhs;
    infix->op_id = (uint16_t)op;
    if (lhs) { infix->span_start = lhs->span_start;
        infix->line = lhs->line; infix->col = lhs->col; }
    if (rhs)   infix->span_end = rhs->span_end;
    if (lhs) iii_ast_add_child(p->arena, infix, lhs);
    if (rhs) iii_ast_add_child(p->arena, infix, rhs);
    iii_ast_node_t *outer = iii_arena_node(p->arena, outer_lvl);
    if (!outer) return infix;
    outer->span_start = infix->span_start; outer->span_end = infix->span_end;
    outer->line = infix->line; outer->col = infix->col;
    iii_ast_add_child(p->arena, outer, infix);
    return outer;
}

static int peek_is_op(iii_parser_t *p, iii_op_e o) {
    return tok_is_op(peek(p, 0), p, o);
}

/* ---- entrypoint ------------------------------------------------------ */

iii_ast_node_t *iiip_parse_expr(iii_parser_t *p) {
    return parse_lvl0(p);
}

/* ---- L0: cognitive (right-associative) ------------------------------ */
static iii_ast_node_t *parse_lvl0(iii_parser_t *p) {
    iii_ast_node_t *lhs = parse_lvl1(p);
    if (!lhs) return NULL;
    if (peek_is_op(p, IIIOP_NARRATIVE_REFLECT) ||
        peek_is_op(p, IIIOP_EXPLAIN_OP) ||
        peek_is_op(p, IIIOP_NEGOTIATE_OP)) {
        iii_op_e op = peek_is_op(p, IIIOP_NARRATIVE_REFLECT) ? IIIOP_NARRATIVE_REFLECT
                    : peek_is_op(p, IIIOP_EXPLAIN_OP)         ? IIIOP_EXPLAIN_OP
                    :                                           IIIOP_NEGOTIATE_OP;
        consume(p, NULL);
        iii_ast_node_t *rhs = parse_lvl0(p); /* right-assoc recursion */
        return make_infix(p, lhs, rhs, op, III_AST_EXPR_LVL_0);
    }
    return lhs;
}

/* ---- L1: catalyst (right-associative per §10.2) --------------------- */
static iii_ast_node_t *parse_lvl1(iii_parser_t *p) {
    iii_ast_node_t *lhs = parse_lvl2(p);
    if (!lhs) return NULL;
    if (peek_is_op(p, IIIOP_CATALYST_PROMOTE) ||
        peek_is_op(p, IIIOP_OBS_SATURATE)     ||
        peek_is_op(p, IIIOP_PROPOSE_OP)       ||
        peek_is_op(p, IIIOP_UNCERTAINTY_QUERY)) {
        iii_op_e op = peek_is_op(p, IIIOP_CATALYST_PROMOTE) ? IIIOP_CATALYST_PROMOTE
                    : peek_is_op(p, IIIOP_OBS_SATURATE)     ? IIIOP_OBS_SATURATE
                    : peek_is_op(p, IIIOP_PROPOSE_OP)       ? IIIOP_PROPOSE_OP
                    :                                         IIIOP_UNCERTAINTY_QUERY;
        consume(p, NULL);
        iii_ast_node_t *rhs = parse_lvl1(p);
        return make_infix(p, lhs, rhs, op, III_AST_EXPR_LVL_1);
    }
    return lhs;
}

/* ---- L2: federation (left) ------------------------------------------ */
static iii_ast_node_t *parse_lvl2(iii_parser_t *p) {
    iii_ast_node_t *lhs = parse_lvl3(p);
    while (lhs && (peek_is_op(p, IIIOP_FED_REPLICATE) || peek_is_op(p, IIIOP_AMEND_APPLY))) {
        iii_op_e op = peek_is_op(p, IIIOP_FED_REPLICATE) ? IIIOP_FED_REPLICATE : IIIOP_AMEND_APPLY;
        consume(p, NULL);
        iii_ast_node_t *rhs = parse_lvl3(p);
        lhs = make_infix(p, lhs, rhs, op, III_AST_EXPR_LVL_2);
    }
    return lhs;
}

/* ---- L3: ceiling/trinity (right per §10.3) -------------------------- */
static iii_ast_node_t *parse_lvl3(iii_parser_t *p) {
    iii_ast_node_t *lhs = parse_lvl4(p);
    if (!lhs) return NULL;
    if (peek_is_op(p, IIIOP_CEILING_CHECK) || peek_is_op(p, IIIOP_TRINITY_GATE)) {
        iii_op_e op = peek_is_op(p, IIIOP_CEILING_CHECK) ? IIIOP_CEILING_CHECK : IIIOP_TRINITY_GATE;
        consume(p, NULL);
        iii_ast_node_t *rhs = parse_lvl3(p);
        return make_infix(p, lhs, rhs, op, III_AST_EXPR_LVL_3);
    }
    return lhs;
}

/* ---- L4: phase / epoch (left) ; chained → error (§10.4) ------------- */
static iii_ast_node_t *parse_lvl4(iii_parser_t *p) {
    iii_ast_node_t *lhs = parse_lvl5(p);
    int seen = 0;
    while (lhs && (peek_is_op(p, IIIOP_PHASE_CROSS) || peek_is_op(p, IIIOP_EPOCH_BRIDGE))) {
        if (seen) {
            const iii_token_t *t = peek(p, 0);
            iiip_record_error(p, P_E_UNEXPECTED_TOKEN,
                              t ? t->text_offset : 0,
                              t ? t->text_offset + t->text_len : 0,
                              t ? t->line : 0, t ? t->col : 0,
                              "PARSE-EXPR-003 chained phase cross / epoch bridge");
        }
        if (peek_is_op(p, IIIOP_PHASE_CROSS)) {
            iii_token_t op_tok = *peek(p, 0);
            consume(p, NULL);
            /* phase_op: '⟴' ring */
            iii_ast_node_t *rhs = iiip_parse_ring_set(p); /* parse a single ring; ring_set accepts that */
            iii_ast_node_t *pc = iii_arena_node(p->arena, III_AST_PHASE_CROSS);
            if (!pc) return lhs;
            pc->span_start = lhs ? lhs->span_start : op_tok.text_offset;
            pc->span_end   = rhs ? rhs->span_end : op_tok.text_offset + op_tok.text_len;
            pc->line = lhs ? lhs->line : op_tok.line;
            pc->col  = lhs ? lhs->col  : op_tok.col;
            if (lhs) iii_ast_add_child(p->arena, pc, lhs);
            if (rhs) iii_ast_add_child(p->arena, pc, rhs);
            iii_ast_node_t *outer = iii_arena_node(p->arena, III_AST_EXPR_LVL_4);
            if (outer) {
                outer->span_start = pc->span_start; outer->span_end = pc->span_end;
                outer->line = pc->line; outer->col = pc->col;
                iii_ast_add_child(p->arena, outer, pc);
                lhs = outer;
            } else lhs = pc;
        } else {
            iii_token_t op_tok = *peek(p, 0);
            consume(p, NULL); /* '⟵' */
            /* '@epoch' '(' INT_LIT ')' */
            iii_ast_node_t *eb = iii_arena_node(p->arena, III_AST_EPOCH_BRIDGE);
            if (!eb) return lhs;
            eb->span_start = lhs ? lhs->span_start : op_tok.text_offset;
            eb->line = lhs ? lhs->line : op_tok.line;
            eb->col  = lhs ? lhs->col  : op_tok.col;
            if (lhs) iii_ast_add_child(p->arena, eb, lhs);
            const iii_token_t *mt = peek(p, 0);
            if (mt && mt->kind == IIIK_MODIFIER &&
                mt->interned_id == p->mod_id[IIIMOD_EPOCH]) {
                consume(p, NULL);
                expect_punct(p, IIIPN_LPAREN);
                const iii_token_t *nt = peek(p, 0);
                if (nt && nt->kind == IIIK_INT_LIT) {
                    eb->int_value = nt->int_value;
                    eb->span_end  = nt->text_offset + nt->text_len;
                    consume(p, NULL);
                }
                expect_punct(p, IIIPN_RPAREN);
            } else {
                iiip_record_error(p, P_E_UNEXPECTED_TOKEN,
                                  mt ? mt->text_offset : 0,
                                  mt ? mt->text_offset + mt->text_len : 0,
                                  mt ? mt->line : 0, mt ? mt->col : 0,
                                  "expected '@epoch(N)' after '⟵'");
            }
            iii_ast_node_t *outer = iii_arena_node(p->arena, III_AST_EXPR_LVL_4);
            if (outer) {
                outer->span_start = eb->span_start; outer->span_end = eb->span_end;
                outer->line = eb->line; outer->col = eb->col;
                iii_ast_add_child(p->arena, outer, eb);
                lhs = outer;
            } else lhs = eb;
        }
        seen = 1;
    }
    return lhs;
}

/* ---- L5: cap / coherence (left) ------------------------------------- */
static iii_ast_node_t *parse_lvl5(iii_parser_t *p) {
    iii_ast_node_t *lhs = parse_lvl6(p);
    while (lhs && (peek_is_op(p, IIIOP_CAP_ACQ_REL) || peek_is_op(p, IIIOP_MOBIUS_COHERENCE))) {
        if (peek_is_op(p, IIIOP_CAP_ACQ_REL)) {
            consume(p, NULL);
            iii_ast_node_t *cap = iii_arena_node(p->arena, III_AST_CAP_ACQUIRE_RELEASE);
            if (!cap) return lhs;
            cap->span_start = lhs->span_start; cap->line = lhs->line; cap->col = lhs->col;
            iii_ast_add_child(p->arena, cap, lhs);
            iii_token_t id;
            if (expect_ident(p, &id)) {
                cap->interned_id = id.interned_id;
                cap->span_end = id.text_offset + id.text_len;
            }
            iii_ast_node_t *outer = iii_arena_node(p->arena, III_AST_EXPR_LVL_5);
            if (outer) { outer->span_start = cap->span_start; outer->span_end = cap->span_end;
                outer->line = cap->line; outer->col = cap->col;
                iii_ast_add_child(p->arena, outer, cap); lhs = outer; }
            else lhs = cap;
        } else {
            consume(p, NULL); /* ⧗ */
            iii_ast_node_t *cq = iii_arena_node(p->arena, III_AST_COHERENCE_QUERY);
            if (!cq) return lhs;
            cq->span_start = lhs->span_start; cq->line = lhs->line; cq->col = lhs->col;
            iii_ast_add_child(p->arena, cq, lhs);
            const iii_token_t *t = peek(p, 0);
            if (t && t->kind == IIIK_Q14_LIT) {
                cq->int_value = t->int_value;
                cq->span_end = t->text_offset + t->text_len;
                consume(p, NULL);
            } else {
                iii_ast_node_t *ce = iiip_parse_coherence_expr(p);
                if (ce) { iii_ast_add_child(p->arena, cq, ce);
                    cq->span_end = ce->span_end; }
            }
            iii_ast_node_t *outer = iii_arena_node(p->arena, III_AST_EXPR_LVL_5);
            if (outer) { outer->span_start = cq->span_start; outer->span_end = cq->span_end;
                outer->line = cq->line; outer->col = cq->col;
                iii_ast_add_child(p->arena, outer, cq); lhs = outer; }
            else lhs = cq;
        }
    }
    return lhs;
}

/* ---- L6: additive (⊕ ⧉ + -) ---------------------------------------- */
static int peek_is_pn(iii_parser_t *p, iii_pn_e n) {
    return tok_is_pn(peek(p, 0), p, n);
}

static iii_ast_node_t *parse_lvl6(iii_parser_t *p) {
    iii_ast_node_t *lhs = parse_lvl7(p);
    while (lhs) {
        if (peek_is_op(p, IIIOP_CYCLE_COMPOSE) || peek_is_op(p, IIIOP_HEXAD_COMPOSE)) {
            iii_op_e op = peek_is_op(p, IIIOP_CYCLE_COMPOSE) ? IIIOP_CYCLE_COMPOSE : IIIOP_HEXAD_COMPOSE;
            consume(p, NULL);
            iii_ast_node_t *rhs = parse_lvl7(p);
            lhs = make_infix(p, lhs, rhs, op, III_AST_EXPR_LVL_6);
        } else if (peek_is_pn(p, IIIPN_MINUS)) {
            consume(p, NULL);
            iii_ast_node_t *rhs = parse_lvl7(p);
            /* Use IIIOP_COUNT sentinel for non-sovereign-op infix '+'/'-'; printer reads via punctuator id */
            iii_ast_node_t *infix = iii_arena_node(p->arena, III_AST_INFIX_OP);
            if (!infix) return lhs;
            infix->op_id = (uint16_t)IIIPN_MINUS; /* punct-id stashed */
            infix->span_start = lhs->span_start; infix->span_end = rhs ? rhs->span_end : lhs->span_end;
            infix->line = lhs->line; infix->col = lhs->col;
            iii_ast_add_child(p->arena, infix, lhs);
            if (rhs) iii_ast_add_child(p->arena, infix, rhs);
            iii_ast_node_t *outer = iii_arena_node(p->arena, III_AST_EXPR_LVL_6);
            if (outer) { outer->span_start = infix->span_start; outer->span_end = infix->span_end;
                outer->line = infix->line; outer->col = infix->col;
                iii_ast_add_child(p->arena, outer, infix); lhs = outer; }
            else lhs = infix;
        } else {
            /* '+' is not a tokenised punctuator in this lexicon — but we
             * accept IDENT-text "+" for completeness with any future
             * extension.  In practice only ⊕ / ⧉ / - apply here. */
            break;
        }
    }
    return lhs;
}

/* ---- L7: multiplicative (* / % ⧊) ----------------------------------- */
static iii_ast_node_t *parse_lvl7(iii_parser_t *p) {
    iii_ast_node_t *lhs = parse_lvl8(p);
    while (lhs && peek_is_op(p, IIIOP_VDF_SQUARING)) {
        consume(p, NULL);
        iii_ast_node_t *rhs = parse_lvl8(p);
        lhs = make_infix(p, lhs, rhs, IIIOP_VDF_SQUARING, III_AST_EXPR_LVL_7);
    }
    return lhs;
}

/* ---- L8: comparison (non-associative) ------------------------------- */
static iii_ast_node_t *parse_lvl8(iii_parser_t *p) {
    iii_ast_node_t *lhs = parse_lvl10(p);
    if (!lhs) return NULL;
    iii_pn_e cmp = IIIPN_COUNT;
    if      (peek_is_pn(p, IIIPN_EQEQ)) cmp = IIIPN_EQEQ;
    else if (peek_is_pn(p, IIIPN_NEQ))  cmp = IIIPN_NEQ;
    else if (peek_is_pn(p, IIIPN_LT))   cmp = IIIPN_LT;
    else if (peek_is_pn(p, IIIPN_GT))   cmp = IIIPN_GT;
    else if (peek_is_pn(p, IIIPN_LE))   cmp = IIIPN_LE;
    else if (peek_is_pn(p, IIIPN_GE))   cmp = IIIPN_GE;
    if (cmp != IIIPN_COUNT) {
        consume(p, NULL);
        iii_ast_node_t *rhs = parse_lvl10(p);
        iii_ast_node_t *infix = iii_arena_node(p->arena, III_AST_INFIX_OP);
        if (!infix) return lhs;
        infix->op_id = (uint16_t)cmp;
        infix->span_start = lhs->span_start; infix->span_end = rhs ? rhs->span_end : lhs->span_end;
        infix->line = lhs->line; infix->col = lhs->col;
        iii_ast_add_child(p->arena, infix, lhs);
        if (rhs) iii_ast_add_child(p->arena, infix, rhs);
        /* Detect chained comparison (PARSE-EXPR-002). */
        const iii_token_t *t = peek(p, 0);
        if (t && t->kind == IIIK_PUNCT &&
            (t->interned_id == p->pn_id[IIIPN_EQEQ] ||
             t->interned_id == p->pn_id[IIIPN_NEQ]  ||
             t->interned_id == p->pn_id[IIIPN_LT]   ||
             t->interned_id == p->pn_id[IIIPN_GT]   ||
             t->interned_id == p->pn_id[IIIPN_LE]   ||
             t->interned_id == p->pn_id[IIIPN_GE])) {
            iiip_record_error(p, P_E_UNEXPECTED_TOKEN,
                              t->text_offset, t->text_offset + t->text_len,
                              t->line, t->col,
                              "PARSE-EXPR-002 chained comparisons");
        }
        iii_ast_node_t *outer = iii_arena_node(p->arena, III_AST_EXPR_LVL_8);
        if (outer) { outer->span_start = infix->span_start; outer->span_end = infix->span_end;
            outer->line = infix->line; outer->col = infix->col;
            iii_ast_add_child(p->arena, outer, infix); return outer; }
        return infix;
    }
    return lhs;
}

/* ---- L10: materialise (⊗ glyph) ------------------------------------ */
static iii_ast_node_t *parse_lvl10(iii_parser_t *p) {
    iii_ast_node_t *lhs = parse_lvl11(p);
    if (lhs && peek_is_op(p, IIIOP_GLYPH_MATERIALIZE)) {
        consume(p, NULL);
        /* expect 'glyph' keyword */
        if (!accept_kw(p, IIIKW_GLYPH)) {
            const iii_token_t *t = peek(p, 0);
            iiip_record_error(p, P_E_EXPECTED_KEYWORD,
                              t ? t->text_offset : 0,
                              t ? t->text_offset + t->text_len : 0,
                              t ? t->line : 0, t ? t->col : 0,
                              "expected 'glyph' after ⊗");
        }
        iii_ast_node_t *gm = iii_arena_node(p->arena, III_AST_GLYPH_MATERIALIZE);
        if (!gm) return lhs;
        gm->span_start = lhs->span_start; gm->line = lhs->line; gm->col = lhs->col;
        iii_ast_add_child(p->arena, gm, lhs);
        iii_ast_node_t *outer = iii_arena_node(p->arena, III_AST_EXPR_LVL_10);
        if (outer) { outer->span_start = gm->span_start; outer->span_end = gm->span_end;
            outer->line = gm->line; outer->col = gm->col;
            iii_ast_add_child(p->arena, outer, gm); return outer; }
        return gm;
    }
    return lhs;
}

/* ---- L11: postfix unary (⟡ ↻ ⟲⟲ ⟲) -------------------------------- */
static iii_ast_node_t *parse_lvl11(iii_parser_t *p) {
    iii_ast_node_t *lhs = parse_lvl12(p);
    while (lhs) {
        iii_ast_kind_t which;
        iii_op_e op;
        if      (peek_is_op(p, IIIOP_WITNESS_EMIT))        { which = III_AST_WITNESS_EMIT;        op = IIIOP_WITNESS_EMIT; }
        else if (peek_is_op(p, IIIOP_REPLAY))              { which = III_AST_REPLAY;              op = IIIOP_REPLAY; }
        else if (peek_is_op(p, IIIOP_FULL_INVERSE_REPLAY)) { which = III_AST_FULL_INVERSE_REPLAY; op = IIIOP_FULL_INVERSE_REPLAY; }
        else if (peek_is_op(p, IIIOP_INVERSE))             { which = III_AST_INVERSE;             op = IIIOP_INVERSE; }
        else break;
        iii_token_t op_tok = *peek(p, 0);
        consume(p, NULL);
        iii_ast_node_t *post = iii_arena_node(p->arena, which);
        if (!post) return lhs;
        post->op_id = (uint16_t)op;
        post->span_start = lhs->span_start; post->span_end = op_tok.text_offset + op_tok.text_len;
        post->line = lhs->line; post->col = lhs->col;
        iii_ast_add_child(p->arena, post, lhs);
        iii_ast_node_t *outer = iii_arena_node(p->arena, III_AST_EXPR_LVL_11);
        if (outer) { outer->span_start = post->span_start; outer->span_end = post->span_end;
            outer->line = post->line; outer->col = post->col;
            iii_ast_add_child(p->arena, outer, post); lhs = outer; }
        else lhs = post;
    }
    return lhs;
}

/* ---- L12: prefix unary (- ! ⟲ ⟲⟲) -------------------------------- */
static iii_ast_node_t *parse_lvl12(iii_parser_t *p) {
    /* ⟲⟲ as prefix → III_AST_FULL_INVERSE_REPLAY (§10.2). */
    if (peek_is_op(p, IIIOP_FULL_INVERSE_REPLAY)) {
        iii_token_t op_tok = *peek(p, 0);
        consume(p, NULL);
        iii_ast_node_t *rhs = parse_lvl12(p);
        iii_ast_node_t *fr = iii_arena_node(p->arena, III_AST_FULL_INVERSE_REPLAY);
        if (!fr) return rhs;
        fr->op_id = (uint16_t)IIIOP_FULL_INVERSE_REPLAY;
        fr->span_start = op_tok.text_offset;
        fr->span_end = rhs ? rhs->span_end : op_tok.text_offset + op_tok.text_len;
        fr->line = op_tok.line; fr->col = op_tok.col;
        if (rhs) iii_ast_add_child(p->arena, fr, rhs);
        return fr;
    }
    /* ⟲ as prefix → III_AST_INVERSE. */
    if (peek_is_op(p, IIIOP_INVERSE)) {
        iii_token_t op_tok = *peek(p, 0);
        consume(p, NULL);
        iii_ast_node_t *rhs = parse_lvl12(p);
        iii_ast_node_t *inv = iii_arena_node(p->arena, III_AST_INVERSE);
        if (!inv) return rhs;
        inv->op_id = (uint16_t)IIIOP_INVERSE;
        inv->span_start = op_tok.text_offset;
        inv->span_end = rhs ? rhs->span_end : op_tok.text_offset + op_tok.text_len;
        inv->line = op_tok.line; inv->col = op_tok.col;
        if (rhs) iii_ast_add_child(p->arena, inv, rhs);
        return inv;
    }
    if (peek_is_pn(p, IIIPN_MINUS) ||
        (peek(p, 0) && peek(p, 0)->kind == IIIK_PUNCT &&
         peek_word(p, 0, "!"))) {
        iii_token_t op_tok = *peek(p, 0);
        consume(p, NULL);
        iii_ast_node_t *rhs = parse_lvl13(p);
        iii_ast_node_t *pre = iii_arena_node(p->arena, III_AST_PREFIX_OP);
        if (!pre) return rhs;
        pre->op_id = (uint16_t)IIIPN_MINUS;
        pre->span_start = op_tok.text_offset; pre->span_end = rhs ? rhs->span_end : op_tok.text_offset + op_tok.text_len;
        pre->line = op_tok.line; pre->col = op_tok.col;
        if (rhs) iii_ast_add_child(p->arena, pre, rhs);
        iii_ast_node_t *outer = iii_arena_node(p->arena, III_AST_EXPR_LVL_12);
        if (outer) { outer->span_start = pre->span_start; outer->span_end = pre->span_end;
            outer->line = pre->line; outer->col = pre->col;
            iii_ast_add_child(p->arena, outer, pre); return outer; }
        return pre;
    }
    return parse_lvl13(p);
}

/* ---- L13: call / index / field / path ------------------------------- */

/* arg ::= expr | IDENT ':' expr   — record where the IDENT followed by
 * ':' is a named-arg form.  We use peek(1) to disambiguate. */
static iii_ast_node_t *parse_arg(iii_parser_t *p) {
    const iii_token_t *t0 = peek(p, 0);
    const iii_token_t *t1 = peek(p, 1);
    if (t0 && t0->kind == IIIK_IDENT &&
        t1 && t1->kind == IIIK_PUNCT &&
        t1->interned_id == p->pn_id[IIIPN_COLON]) {
        iii_token_t name = *t0;
        consume(p, NULL); /* IDENT */
        consume(p, NULL); /* ':' */
        iii_ast_node_t *na = iii_arena_node(p->arena, III_AST_NAMED_ARG);
        if (!na) return iiip_parse_expr(p);
        na->interned_id = name.interned_id;
        iiip_node_span(na, &name, &name);
        iii_ast_node_t *e = iiip_parse_expr(p);
        if (e) { iii_ast_add_child(p->arena, na, e); na->span_end = e->span_end; }
        return na;
    }
    return iiip_parse_expr(p);
}

static iii_ast_node_t *parse_lvl13(iii_parser_t *p) {
    iii_ast_node_t *lhs = parse_primary(p);
    while (lhs) {
        const iii_token_t *t = peek(p, 0);
        if (!t || t->kind != IIIK_PUNCT) break;
        if (t->interned_id == p->pn_id[IIIPN_LPAREN]) {
            iii_token_t lp = *t;
            consume(p, NULL);
            iii_ast_node_t *call = iii_arena_node(p->arena, III_AST_CALL);
            if (!call) return lhs;
            call->span_start = lhs->span_start; call->line = lhs->line; call->col = lhs->col;
            iii_ast_add_child(p->arena, call, lhs);
            if (!(peek(p, 0) && peek(p, 0)->kind == IIIK_PUNCT &&
                  peek(p, 0)->interned_id == p->pn_id[IIIPN_RPAREN])) {
                iii_ast_node_t *a = parse_arg(p);
                if (a) iii_ast_add_child(p->arena, call, a);
                while (accept_pn(p, IIIPN_COMMA)) {
                    iii_ast_node_t *b = parse_arg(p);
                    if (b) iii_ast_add_child(p->arena, call, b);
                }
            }
            const iii_token_t *rp = peek(p, 0);
            if (rp) call->span_end = rp->text_offset + rp->text_len;
            else    call->span_end = lp.text_offset + lp.text_len;
            expect_punct(p, IIIPN_RPAREN);
            lhs = call;
        } else if (t->interned_id == p->pn_id[IIIPN_LBRACK]) {
            consume(p, NULL);
            iii_ast_node_t *idx = iii_arena_node(p->arena, III_AST_INDEX);
            if (!idx) return lhs;
            idx->span_start = lhs->span_start; idx->line = lhs->line; idx->col = lhs->col;
            iii_ast_add_child(p->arena, idx, lhs);
            iii_ast_node_t *e = iiip_parse_expr(p);
            if (e) iii_ast_add_child(p->arena, idx, e);
            const iii_token_t *rb = peek(p, 0);
            if (rb) idx->span_end = rb->text_offset + rb->text_len;
            expect_punct(p, IIIPN_RBRACK);
            lhs = idx;
        } else if (t->interned_id == p->pn_id[IIIPN_DOT]) {
            consume(p, NULL);
            iii_token_t id;
            if (!expect_ident(p, &id)) break;
            iii_ast_node_t *fa = iii_arena_node(p->arena, III_AST_FIELD_ACCESS);
            if (!fa) return lhs;
            fa->span_start = lhs->span_start; fa->line = lhs->line; fa->col = lhs->col;
            fa->span_end = id.text_offset + id.text_len;
            fa->interned_id = id.interned_id;
            iii_ast_add_child(p->arena, fa, lhs);
            lhs = fa;
        } else if (t->interned_id == p->pn_id[IIIPN_DCOLON]) {
            consume(p, NULL);
            iii_token_t id;
            if (!expect_ident(p, &id)) break;
            iii_ast_node_t *pa = iii_arena_node(p->arena, III_AST_PATH);
            if (!pa) return lhs;
            pa->span_start = lhs->span_start; pa->line = lhs->line; pa->col = lhs->col;
            pa->span_end = id.text_offset + id.text_len;
            pa->interned_id = id.interned_id;
            iii_ast_add_child(p->arena, pa, lhs);
            lhs = pa;
        } else {
            break;
        }
    }
    return lhs;
}

/* ---- Primary -------------------------------------------------------- */

iii_ast_node_t *iiip_parse_block_expr(iii_parser_t *p) {
    if (!(peek(p, 0) && peek(p, 0)->kind == IIIK_PUNCT &&
          peek(p, 0)->interned_id == p->pn_id[IIIPN_LBRACE])) return NULL;
    iii_token_t lb = *peek(p, 0);
    consume(p, NULL);
    iii_ast_node_t *blk = iii_arena_node(p->arena, III_AST_BLOCK_EXPR);
    if (!blk) return NULL;
    iiip_node_span(blk, &lb, &lb);
    while (peek(p, 0) && peek(p, 0)->kind != IIIK_EOF &&
           !(peek(p, 0)->kind == IIIK_PUNCT &&
             peek(p, 0)->interned_id == p->pn_id[IIIPN_RBRACE])) {
        unsigned before_head = p->ring_head;
        unsigned before_count = p->ring_count;
        iii_ast_node_t *st = iiip_parse_stmt(p);
        if (st) {
            iii_ast_add_child(p->arena, blk, st);
        } else {
            /* Avoid infinite loop on undecidable input. */
            if (before_head == p->ring_head && before_count == p->ring_count) {
                consume(p, NULL);
            }
        }
    }
    const iii_token_t *rb = peek(p, 0);
    if (rb) blk->span_end = rb->text_offset + rb->text_len;
    expect_punct(p, IIIPN_RBRACE);
    return blk;
}

static iii_ast_node_t *parse_literal_node(iii_parser_t *p) {
    const iii_token_t *t = peek(p, 0);
    iii_token_t copy = *t;
    iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_LITERAL);
    if (n) {
        n->op_id          = (uint16_t)copy.kind;
        n->interned_id    = copy.interned_id;
        n->int_value      = copy.int_value;
        memcpy(n->mhash_value, copy.mhash_value, 32);
        n->hexad_packed   = copy.hexad_packed;
        n->int_suffix     = copy.int_suffix;
        n->string_payload = copy.string_payload;
        n->string_len     = copy.string_len;
        iiip_node_span(n, &copy, &copy);
    }
    consume(p, NULL);
    return n;
}

static iii_ast_node_t *parse_paren_or_tuple(iii_parser_t *p) {
    iii_token_t lp = *peek(p, 0);
    consume(p, NULL); /* '(' */
    if (accept_pn(p, IIIPN_RPAREN)) {
        /* unit literal — represent as empty tuple_literal */
        iii_ast_node_t *t = iii_arena_node(p->arena, III_AST_TUPLE_LITERAL);
        if (t) iiip_node_span(t, &lp, &lp);
        return t;
    }
    iii_ast_node_t *first = iiip_parse_expr(p);
    if (peek(p, 0) && peek(p, 0)->kind == IIIK_PUNCT &&
        peek(p, 0)->interned_id == p->pn_id[IIIPN_COMMA]) {
        iii_ast_node_t *tup = iii_arena_node(p->arena, III_AST_TUPLE_LITERAL);
        if (!tup) { expect_punct(p, IIIPN_RPAREN); return first; }
        tup->span_start = lp.text_offset; tup->line = lp.line; tup->col = lp.col;
        if (first) iii_ast_add_child(p->arena, tup, first);
        while (accept_pn(p, IIIPN_COMMA)) {
            if (peek(p, 0) && peek(p, 0)->kind == IIIK_PUNCT &&
                peek(p, 0)->interned_id == p->pn_id[IIIPN_RPAREN]) break;
            iii_ast_node_t *e = iiip_parse_expr(p);
            if (e) iii_ast_add_child(p->arena, tup, e);
        }
        const iii_token_t *rp = peek(p, 0);
        if (rp) tup->span_end = rp->text_offset + rp->text_len;
        expect_punct(p, IIIPN_RPAREN);
        return tup;
    }
    expect_punct(p, IIIPN_RPAREN);
    return first;
}

static iii_ast_node_t *parse_array_literal(iii_parser_t *p) {
    iii_token_t lb = *peek(p, 0);
    consume(p, NULL); /* '[' */
    iii_ast_node_t *arr = iii_arena_node(p->arena, III_AST_ARRAY_LITERAL);
    if (!arr) return NULL;
    iiip_node_span(arr, &lb, &lb);
    if (accept_pn(p, IIIPN_RBRACK)) return arr;
    iii_ast_node_t *first = iiip_parse_expr(p);
    if (first) iii_ast_add_child(p->arena, arr, first);
    /* repeated form: [expr ';' INT_LIT] */
    if (accept_pn(p, IIIPN_SEMI)) {
        const iii_token_t *t = peek(p, 0);
        if (t && t->kind == IIIK_INT_LIT) {
            arr->int_value = t->int_value;
            consume(p, NULL);
        }
    } else {
        while (accept_pn(p, IIIPN_COMMA)) {
            if (peek(p, 0) && peek(p, 0)->kind == IIIK_PUNCT &&
                peek(p, 0)->interned_id == p->pn_id[IIIPN_RBRACK]) break;
            iii_ast_node_t *e = iiip_parse_expr(p);
            if (e) iii_ast_add_child(p->arena, arr, e);
        }
    }
    const iii_token_t *rb = peek(p, 0);
    if (rb) arr->span_end = rb->text_offset + rb->text_len;
    expect_punct(p, IIIPN_RBRACK);
    return arr;
}

/* record_literal: qualified_name '{' record_field (',' ...)* '}' */
static iii_ast_node_t *parse_record_literal_with(iii_parser_t *p, iii_ast_node_t *qn) {
    iii_token_t lb = *peek(p, 0);
    consume(p, NULL); /* '{' */
    iii_ast_node_t *rec = iii_arena_node(p->arena, III_AST_RECORD_LITERAL);
    if (!rec) return qn;
    rec->span_start = qn ? qn->span_start : lb.text_offset;
    rec->line = qn ? qn->line : lb.line; rec->col = qn ? qn->col : lb.col;
    if (qn) iii_ast_add_child(p->arena, rec, qn);
    do {
        iii_token_t fname;
        if (!expect_ident(p, &fname)) break;
        if (!expect_punct(p, IIIPN_COLON)) break;
        iii_ast_node_t *fv = iiip_parse_expr(p);
        iii_ast_node_t *f = iii_arena_node(p->arena, III_AST_RECORD_FIELD);
        if (f) {
            f->interned_id = fname.interned_id;
            iiip_node_span(f, &fname, &fname);
            if (fv) { iii_ast_add_child(p->arena, f, fv); f->span_end = fv->span_end; }
            iii_ast_add_child(p->arena, rec, f);
        }
    } while (accept_pn(p, IIIPN_COMMA));
    const iii_token_t *rb = peek(p, 0);
    if (rb) rec->span_end = rb->text_offset + rb->text_len;
    expect_punct(p, IIIPN_RBRACE);
    return rec;
}

static iii_ast_node_t *parse_primary(iii_parser_t *p) {
    const iii_token_t *t = peek(p, 0);
    if (!t) return NULL;

    /* literals */
    switch (t->kind) {
    case IIIK_INT_LIT: case IIIK_MHASH_LIT: case IIIK_TRIT_LIT:
    case IIIK_HEXAD_LIT: case IIIK_Q14_LIT: case IIIK_STRING_LIT:
    case IIIK_BYTE_STRING_LIT: case IIIK_RAW_STRING_LIT:
    case IIIK_HEX_STRING_LIT:
        return parse_literal_node(p);
    default: break;
    }

    if (t->kind == IIIK_IDENT) {
        if (peek_word(p, 0, "true") || peek_word(p, 0, "false")) {
            return parse_literal_node(p);
        }
        /* cycle_invoke '(' IDENT (',' arg_list)? ')' */
        if (peek_word(p, 0, "cycle_invoke")) {
            iii_token_t kw = *t;
            consume(p, NULL);
            iii_ast_node_t *ci = iii_arena_node(p->arena, III_AST_CYCLE_INVOKE);
            if (!ci) return NULL;
            iiip_node_span(ci, &kw, &kw);
            expect_punct(p, IIIPN_LPAREN);
            iii_token_t id;
            if (expect_ident(p, &id)) ci->interned_id = id.interned_id;
            if (accept_pn(p, IIIPN_COMMA)) {
                iii_ast_node_t *a = parse_arg(p);
                if (a) iii_ast_add_child(p->arena, ci, a);
                while (accept_pn(p, IIIPN_COMMA)) {
                    iii_ast_node_t *b = parse_arg(p);
                    if (b) iii_ast_add_child(p->arena, ci, b);
                }
            }
            const iii_token_t *rp = peek(p, 0);
            if (rp) ci->span_end = rp->text_offset + rp->text_len;
            expect_punct(p, IIIPN_RPAREN);
            return ci;
        }
        /* irpd.<method>(args) */
        if (peek_word(p, 0, "irpd") &&
            peek(p, 1) && peek(p, 1)->kind == IIIK_PUNCT &&
            peek(p, 1)->interned_id == p->pn_id[IIIPN_DOT]) {
            iii_token_t kw = *t;
            consume(p, NULL); consume(p, NULL); /* irpd . */
            iii_token_t mid;
            if (!expect_ident(p, &mid)) return NULL;
            iii_ast_node_t *ic = iii_arena_node(p->arena, III_AST_IRPD_CALL);
            if (!ic) return NULL;
            iiip_node_span(ic, &kw, &mid);
            ic->interned_id = mid.interned_id;
            expect_punct(p, IIIPN_LPAREN);
            if (!(peek(p, 0) && peek(p, 0)->kind == IIIK_PUNCT &&
                  peek(p, 0)->interned_id == p->pn_id[IIIPN_RPAREN])) {
                iii_ast_node_t *a = parse_arg(p);
                if (a) iii_ast_add_child(p->arena, ic, a);
                while (accept_pn(p, IIIPN_COMMA)) {
                    iii_ast_node_t *b = parse_arg(p);
                    if (b) iii_ast_add_child(p->arena, ic, b);
                }
            }
            const iii_token_t *rp = peek(p, 0);
            if (rp) ic->span_end = rp->text_offset + rp->text_len;
            expect_punct(p, IIIPN_RPAREN);
            return ic;
        }
        /* Default: single-IDENT primary (an unqualified name).  We do
         * NOT eagerly consume `.` here — the L13 postfix loop produces
         * FIELD_ACCESS for `.` and PATH for `::`.  An IDENT-only QN
         * (no segment children) is the canonical form.
         *
         * If a `{ IDENT :` follows, this is a record literal (e.g.
         * `Point { x: 1 }`).  Bare `{` after a name in non-disambiguated
         * positions (e.g. `match x {` ) is NOT a record literal — gate
         * strictly on the `IDENT :` shape so we don't steal the body of
         * a control-flow construct. */
        iii_token_t name = *t;
        consume(p, NULL); /* IDENT */
        iii_ast_node_t *qn = iii_arena_node(p->arena, III_AST_QUALIFIED_NAME);
        if (!qn) return NULL;
        qn->interned_id = name.interned_id;
        iiip_node_span(qn, &name, &name);
        if (peek(p, 0) && peek(p, 0)->kind == IIIK_PUNCT &&
            peek(p, 0)->interned_id == p->pn_id[IIIPN_LBRACE] &&
            peek(p, 1) && peek(p, 1)->kind == IIIK_IDENT &&
            peek(p, 2) && peek(p, 2)->kind == IIIK_PUNCT &&
            peek(p, 2)->interned_id == p->pn_id[IIIPN_COLON]) {
            return parse_record_literal_with(p, qn);
        }
        return qn;
    }

    /* sanctum.<method>(args) */
    if (tok_is_kw(t, p, IIIKW_SANCTUM) &&
        peek(p, 1) && peek(p, 1)->kind == IIIK_PUNCT &&
        peek(p, 1)->interned_id == p->pn_id[IIIPN_DOT]) {
        iii_token_t kw = *t;
        consume(p, NULL); consume(p, NULL);
        iii_token_t mid;
        if (!expect_ident(p, &mid)) return NULL;
        iii_ast_node_t *si = iii_arena_node(p->arena, III_AST_SANCTUM_INVOKE);
        if (!si) return NULL;
        iiip_node_span(si, &kw, &mid);
        si->interned_id = mid.interned_id;
        expect_punct(p, IIIPN_LPAREN);
        if (!(peek(p, 0) && peek(p, 0)->kind == IIIK_PUNCT &&
              peek(p, 0)->interned_id == p->pn_id[IIIPN_RPAREN])) {
            iii_ast_node_t *a = parse_arg(p);
            if (a) iii_ast_add_child(p->arena, si, a);
            while (accept_pn(p, IIIPN_COMMA)) {
                iii_ast_node_t *b = parse_arg(p);
                if (b) iii_ast_add_child(p->arena, si, b);
            }
        }
        const iii_token_t *rp = peek(p, 0);
        if (rp) si->span_end = rp->text_offset + rp->text_len;
        expect_punct(p, IIIPN_RPAREN);
        return si;
    }

    /* Block expression */
    if (t->kind == IIIK_PUNCT && t->interned_id == p->pn_id[IIIPN_LBRACE]) {
        return iiip_parse_block_expr(p);
    }
    /* parenthesised expr / tuple */
    if (t->kind == IIIK_PUNCT && t->interned_id == p->pn_id[IIIPN_LPAREN]) {
        return parse_paren_or_tuple(p);
    }
    /* array literal */
    if (t->kind == IIIK_PUNCT && t->interned_id == p->pn_id[IIIPN_LBRACK]) {
        return parse_array_literal(p);
    }
    /* hole */
    if (t->kind == IIIK_PUNCT && t->interned_id == p->pn_id[IIIPN_QMARK]) {
        iii_token_t q = *t;
        consume(p, NULL);
        iii_ast_node_t *h = iii_arena_node(p->arena, III_AST_HOLE);
        if (h) iiip_node_span(h, &q, &q);
        return h;
    }
    iiip_record_error(p, P_E_EXPECTED_EXPR,
                      t->text_offset, t->text_offset + t->text_len,
                      t->line, t->col,
                      "expected expression, got %s",
                      iii_token_kind_name(t->kind));
    iii_ast_node_t *e = iiip_error_node(p);
    consume(p, NULL);
    return e;
}
