/* III Grammar — §6 Type productions and supporting helpers.
 *
 * type ::= base_type type_modifier*
 *        | function_type
 *        | tuple_type
 *        | array_type
 */
#include "parse_internal.h"

/* Forward decls (file-local). */
static iii_ast_node_t *parse_base_type(iii_parser_t *p);
static iii_ast_node_t *parse_function_type(iii_parser_t *p);
static iii_ast_node_t *parse_tuple_type(iii_parser_t *p);
static iii_ast_node_t *parse_array_type(iii_parser_t *p);
static iii_ast_node_t *parse_primitive_or_named(iii_parser_t *p);

/* qualified_name production lives in parse_module.c; declared via
 * iiip_parse_qualified_name() in parse_internal.h.  This translation unit
 * intentionally does NOT redefine it (single canonical definition). */

/* ---- ring_set / ring -------------------------------------------------- */

static iii_ast_node_t *parse_one_ring(iii_parser_t *p) {
    /* `R-2` `R-1` `R0` `R3` — but `R-2`/`R-1` are tokenised as
     * IDENT('R') then PUNCT('-') then INT_LIT(2/1).  `R0`/`R3` are
     * a single IDENT.  Accept both shapes. */
    const iii_token_t *t = peek(p, 0);
    if (!t) return NULL;
    iii_ast_node_t *r = iii_arena_node(p->arena, III_AST_RING_SET);
    if (!r) return NULL;
    if (t->kind == IIIK_IDENT) {
        size_t slen; const char *s = iii_lex_intern_text(p->lex, t->interned_id, &slen);
        iii_token_t first = *t;
        consume(p, NULL);
        /* If text is just "R" check for following '-' INT */
        if (s && slen == 1 && s[0] == 'R') {
            const iii_token_t *t2 = peek(p, 0);
            if (t2 && t2->kind == IIIK_PUNCT &&
                t2->interned_id == p->pn_id[IIIPN_MINUS]) {
                consume(p, NULL);
                const iii_token_t *t3 = peek(p, 0);
                if (t3 && t3->kind == IIIK_INT_LIT) {
                    iii_token_t last = *t3;
                    r->int_value = (uint64_t)(-(int64_t)t3->int_value);
                    consume(p, NULL);
                    iiip_node_span(r, &first, &last);
                    return r;
                }
            }
        }
        /* "R0" / "R3" / generic IDENT */
        r->interned_id = first.interned_id;
        iiip_node_span(r, &first, &first);
        return r;
    }
    iiip_record_error(p, P_E_EXPECTED_IDENT,
                      t->text_offset, t->text_offset + t->text_len,
                      t->line, t->col, "expected ring name");
    return r;
}

iii_ast_node_t *iiip_parse_ring_set(iii_parser_t *p) {
    iii_ast_node_t *set = iii_arena_node(p->arena, III_AST_RING_SET);
    if (!set) return NULL;
    iii_ast_node_t *first = parse_one_ring(p);
    if (first) iii_ast_add_child(p->arena, set, first);
    while (accept_pn(p, IIIPN_COMMA)) {
        iii_ast_node_t *r = parse_one_ring(p);
        if (r) iii_ast_add_child(p->arena, set, r);
    }
    return set;
}

/* ---- tier_name -------------------------------------------------------- */

iii_ast_node_t *iiip_parse_tier_name(iii_parser_t *p) {
    iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_TIER_NAME);
    if (!n) return NULL;
    iii_token_t id;
    if (expect_ident(p, &id)) {
        n->interned_id = id.interned_id;
        iiip_node_span(n, &id, &id);
    }
    return n;
}

/* ---- replication_policy ---------------------------------------------- */

iii_ast_node_t *iiip_parse_replication(iii_parser_t *p) {
    iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_REPLICATION_POLICY);
    if (!n) return NULL;
    iii_token_t id;
    if (expect_ident(p, &id)) {
        n->interned_id = id.interned_id;
        iiip_node_span(n, &id, &id);
    }
    return n;
}

/* ---- range ::= INT_LIT '..' INT_LIT | MHASH '..' MHASH | IDENT ------- */

iii_ast_node_t *iiip_parse_range(iii_parser_t *p) {
    iii_ast_node_t *r = iii_arena_node(p->arena, III_AST_RANGE);
    if (!r) return NULL;
    const iii_token_t *t = peek(p, 0);
    if (!t) return r;
    if (t->kind == IIIK_INT_LIT || t->kind == IIIK_MHASH_LIT) {
        iii_token_t lo = *t;
        iii_ast_node_t *a = iii_arena_node(p->arena, III_AST_LITERAL);
        if (a) {
            a->int_value = lo.int_value;
            memcpy(a->mhash_value, lo.mhash_value, 32);
            iiip_node_span(a, &lo, &lo);
            iii_ast_add_child(p->arena, r, a);
        }
        consume(p, NULL);
        if (!expect_punct(p, IIIPN_DDOT)) return r;
        const iii_token_t *t2 = peek(p, 0);
        if (t2 && (t2->kind == IIIK_INT_LIT || t2->kind == IIIK_MHASH_LIT)) {
            iii_token_t hi = *t2;
            iii_ast_node_t *b = iii_arena_node(p->arena, III_AST_LITERAL);
            if (b) {
                b->int_value = hi.int_value;
                memcpy(b->mhash_value, hi.mhash_value, 32);
                iiip_node_span(b, &hi, &hi);
                iii_ast_add_child(p->arena, r, b);
            }
            consume(p, NULL);
            iiip_node_span(r, &lo, &hi);
        }
        return r;
    }
    if (t->kind == IIIK_IDENT) {
        iii_token_t id = *t;
        consume(p, NULL);
        r->interned_id = id.interned_id;
        iiip_node_span(r, &id, &id);
        return r;
    }
    iiip_record_error(p, P_E_UNEXPECTED_TOKEN,
                      t->text_offset, t->text_offset + t->text_len,
                      t->line, t->col, "expected range");
    return r;
}

/* ---- epoch_value ::= INT_LIT | 'current' ----------------------------- */

iii_ast_node_t *iiip_parse_epoch_value(iii_parser_t *p) {
    iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_EPOCH_VALUE);
    if (!n) return NULL;
    const iii_token_t *t = peek(p, 0);
    if (t && t->kind == IIIK_INT_LIT) {
        n->int_value = t->int_value;
        iiip_node_span(n, t, t);
        consume(p, NULL);
    } else if (peek_word(p, 0, "current")) {
        iii_token_t id = *t;
        consume(p, NULL);
        n->interned_id = id.interned_id;
        iiip_node_span(n, &id, &id);
    } else {
        iiip_record_error(p, P_E_UNEXPECTED_TOKEN,
                          t ? t->text_offset : 0,
                          t ? t->text_offset + t->text_len : 0,
                          t ? t->line : 0, t ? t->col : 0,
                          "expected epoch value (INT_LIT or 'current')");
    }
    return n;
}

/* ---- hexad_designator ------------------------------------------------- */

iii_ast_node_t *iiip_parse_hexad_designator(iii_parser_t *p) {
    iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_HEXAD_DESIGNATOR);
    if (!n) return NULL;
    const iii_token_t *t = peek(p, 0);
    if (t && t->kind == IIIK_HEXAD_LIT) {
        n->hexad_packed = t->hexad_packed;
        iiip_node_span(n, t, t);
        consume(p, NULL);
    } else if (t && t->kind == IIIK_IDENT) {
        iii_token_t id = *t;
        consume(p, NULL);
        n->interned_id = id.interned_id;
        iiip_node_span(n, &id, &id);
    } else {
        iiip_record_error(p, P_E_UNEXPECTED_TOKEN,
                          t ? t->text_offset : 0,
                          t ? t->text_offset + t->text_len : 0,
                          t ? t->line : 0, t ? t->col : 0,
                          "expected hexad designator (IDENT or HEXAD_LIT)");
    }
    return n;
}

/* ---- coherence_expr ::= '≥' Q14 | '≤' Q14 | Q14 ---------------------- */

iii_ast_node_t *iiip_parse_coherence_expr(iii_parser_t *p) {
    iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_COHERENCE_EXPR);
    if (!n) return NULL;
    const iii_token_t *t = peek(p, 0);
    iii_token_t first = t ? *t : (iii_token_t){0};
    if (t && t->kind == IIIK_PUNCT &&
        (t->interned_id == p->pn_id[IIIPN_LE] ||
         t->interned_id == p->pn_id[IIIPN_GE])) {
        n->op_id = (t->interned_id == p->pn_id[IIIPN_LE])
                   ? IIIPN_LE : IIIPN_GE;
        consume(p, NULL);
        t = peek(p, 0);
    }
    if (t && t->kind == IIIK_Q14_LIT) {
        n->int_value = t->int_value;
        iiip_node_span(n, &first, t);
        consume(p, NULL);
    } else {
        iiip_record_error(p, P_E_UNEXPECTED_TOKEN,
                          t ? t->text_offset : 0,
                          t ? t->text_offset + t->text_len : 0,
                          t ? t->line : 0, t ? t->col : 0,
                          "expected Q14 literal in coherence_expr");
    }
    return n;
}

/* ---- compromise_tier ::= 'LOW' | 'MEDIUM' | 'HIGH' ------------------- */

iii_ast_node_t *iiip_parse_compromise_tier(iii_parser_t *p) {
    iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_COMPROMISE_TIER);
    if (!n) return NULL;
    iii_token_t id;
    if (expect_ident(p, &id)) {
        n->interned_id = id.interned_id;
        iiip_node_span(n, &id, &id);
    }
    return n;
}

/* ---- generic_args ::= '<' type (',' type)* '>' ----------------------- */

iii_ast_node_t *iiip_parse_generic_args(iii_parser_t *p) {
    if (!(peek(p, 0) && peek(p, 0)->kind == IIIK_PUNCT &&
          peek(p, 0)->interned_id == p->pn_id[IIIPN_LT])) return NULL;
    iii_token_t lt = *peek(p, 0);
    consume(p, NULL);
    iii_ast_node_t *ga = iii_arena_node(p->arena, III_AST_GENERIC_ARGS);
    if (!ga) return NULL;
    iiip_node_span(ga, &lt, &lt);
    do {
        iii_ast_node_t *t = iiip_parse_type(p);
        if (t) iii_ast_add_child(p->arena, ga, t);
    } while (accept_pn(p, IIIPN_COMMA));
    expect_punct(p, IIIPN_GT);
    return ga;
}

/* ---- type_list ::= type (',' type)* ---------------------------------- */

static void parse_type_list_into(iii_parser_t *p, iii_ast_node_t *parent) {
    do {
        iii_ast_node_t *t = iiip_parse_type(p);
        if (t) iii_ast_add_child(p->arena, parent, t);
    } while (accept_pn(p, IIIPN_COMMA));
}

/* ---- primitive_type / named base ------------------------------------- */

static int is_primitive_text(const char *s, size_t n) {
    static const char *PRIMS[] = {
        "bool","u8","u16","u32","u64","i8","i16","i32","i64",
        "f32","f64","string","mhash"
    };
    for (size_t i = 0; i < sizeof(PRIMS)/sizeof(PRIMS[0]); i++) {
        size_t l = strlen(PRIMS[i]);
        if (l == n && memcmp(s, PRIMS[i], n) == 0) return 1;
    }
    return 0;
}

static iii_ast_node_t *parse_primitive_or_named(iii_parser_t *p) {
    const iii_token_t *t = peek(p, 0);
    if (!t || t->kind != IIIK_IDENT) return NULL;
    size_t slen = 0;
    const char *s = iii_lex_intern_text(p->lex, t->interned_id, &slen);
    if (s && is_primitive_text(s, slen)) {
        iii_token_t id = *t;
        consume(p, NULL);
        iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_PRIMITIVE_TYPE);
        if (n) {
            n->interned_id = id.interned_id;
            iiip_node_span(n, &id, &id);
        }
        return n;
    }
    /* Else: qualified_name generic_args? */
    iii_ast_node_t *qn = iiip_parse_qualified_name(p);
    if (!qn) return NULL;
    iii_ast_node_t *base = iii_arena_node(p->arena, III_AST_BASE_TYPE);
    if (!base) return qn;
    base->span_start = qn->span_start;
    base->line = qn->line;
    base->col  = qn->col;
    base->span_end = qn->span_end;
    iii_ast_add_child(p->arena, base, qn);
    if (peek(p, 0) && peek(p, 0)->kind == IIIK_PUNCT &&
        peek(p, 0)->interned_id == p->pn_id[IIIPN_LT]) {
        iii_ast_node_t *ga = iiip_parse_generic_args(p);
        if (ga) {
            iii_ast_add_child(p->arena, base, ga);
            base->span_end = ga->span_end;
        }
    }
    return base;
}

/* ---- base_type -------------------------------------------------------- */

static iii_ast_node_t *parse_base_type(iii_parser_t *p) {
    const iii_token_t *t = peek(p, 0);
    if (!t) return NULL;

    /* hole */
    if (t->kind == IIIK_PUNCT && t->interned_id == p->pn_id[IIIPN_QMARK]) {
        iii_token_t q = *t;
        consume(p, NULL);
        iii_ast_node_t *h = iii_arena_node(p->arena, III_AST_HOLE);
        if (h) iiip_node_span(h, &q, &q);
        return h;
    }
    if (t->kind != IIIK_IDENT) {
        iiip_record_error(p, P_E_EXPECTED_TYPE,
                          t->text_offset, t->text_offset + t->text_len,
                          t->line, t->col, "expected type");
        return iiip_error_node(p);
    }
    /* Identify built-in capitalised type names that take generic args. */
    size_t slen = 0;
    const char *s = iii_lex_intern_text(p->lex, t->interned_id, &slen);
    if (s) {
        iii_token_t first = *t;
        iii_ast_node_t *base = iii_arena_node(p->arena, III_AST_BASE_TYPE);
        #define MATCH(name) (slen == sizeof(name)-1 && memcmp(s, name, slen) == 0)

        if (MATCH("Cap")) {
            consume(p, NULL); base->interned_id = first.interned_id;
            iiip_node_span(base, &first, &first);
            if (expect_punct(p, IIIPN_LT)) {
                /* cap_perm */
                iii_token_t pm;
                if (expect_ident(p, &pm)) {
                    iii_ast_node_t *pn = iii_arena_node(p->arena, III_AST_QUALIFIED_NAME);
                    if (pn) { pn->interned_id = pm.interned_id;
                        iiip_node_span(pn, &pm, &pm);
                        iii_ast_add_child(p->arena, base, pn); }
                }
                if (accept_pn(p, IIIPN_COMMA)) {
                    iii_ast_node_t *r = iiip_parse_range(p);
                    if (r) iii_ast_add_child(p->arena, base, r);
                }
                expect_punct(p, IIIPN_GT);
            }
            return base;
        }
        if (MATCH("Cycle") || MATCH("Reduction") || MATCH("Uncertainty")) {
            consume(p, NULL); base->interned_id = first.interned_id;
            iiip_node_span(base, &first, &first);
            iii_ast_node_t *ga = iiip_parse_generic_args(p);
            if (ga) iii_ast_add_child(p->arena, base, ga);
            return base;
        }
        if (MATCH("Glyph") || MATCH("Witness") || MATCH("Hexad") ||
            MATCH("Phase") || MATCH("Epoch") || MATCH("WitnessedTime") ||
            MATCH("Trit")  || MATCH("TritAsym") || MATCH("Q14")) {
            consume(p, NULL); base->interned_id = first.interned_id;
            iiip_node_span(base, &first, &first);
            return base;
        }
        if (MATCH("CeilingMembership")) {
            consume(p, NULL); base->interned_id = first.interned_id;
            iiip_node_span(base, &first, &first);
            if (expect_punct(p, IIIPN_LT)) {
                iii_ast_node_t *ty = iiip_parse_type(p);
                if (ty) iii_ast_add_child(p->arena, base, ty);
                expect_punct(p, IIIPN_GT);
            }
            return base;
        }
        /* MöbiusCoherence — IDENTs are ASCII per LEXICON §8, so we
         * match the ASCII alias `MobiusCoherence`. */
        if (MATCH("MobiusCoherence")) {
            consume(p, NULL); base->interned_id = first.interned_id;
            iiip_node_span(base, &first, &first);
            if (expect_punct(p, IIIPN_LT)) {
                const iii_token_t *qt = peek(p, 0);
                if (qt && qt->kind == IIIK_Q14_LIT) {
                    iii_ast_node_t *q = iii_arena_node(p->arena, III_AST_LITERAL);
                    if (q) { q->int_value = qt->int_value;
                        iiip_node_span(q, qt, qt);
                        iii_ast_add_child(p->arena, base, q); }
                    consume(p, NULL);
                }
                expect_punct(p, IIIPN_GT);
            }
            return base;
        }
        if (MATCH("Compromise")) {
            consume(p, NULL); base->interned_id = first.interned_id;
            iiip_node_span(base, &first, &first);
            if (expect_punct(p, IIIPN_LT)) {
                iii_ast_node_t *ct = iiip_parse_compromise_tier(p);
                if (ct) iii_ast_add_child(p->arena, base, ct);
                expect_punct(p, IIIPN_GT);
            }
            return base;
        }
        #undef MATCH
    }
    /* Fallback: primitive-or-qualified-name. */
    return parse_primitive_or_named(p);
}

/* memmem isn't standard C11 portable; tiny fallback (unused). */

/* ---- function_type ::= 'fn' '(' type_list? ')' '->' type type_modifier* */

static iii_ast_node_t *parse_function_type(iii_parser_t *p) {
    iii_token_t fn = *peek(p, 0);
    consume(p, NULL); /* 'fn' */
    iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_FUNCTION_TYPE);
    if (!n) return NULL;
    iiip_node_span(n, &fn, &fn);
    expect_punct(p, IIIPN_LPAREN);
    if (!(peek(p, 0) && peek(p, 0)->kind == IIIK_PUNCT &&
          peek(p, 0)->interned_id == p->pn_id[IIIPN_RPAREN])) {
        parse_type_list_into(p, n);
    }
    expect_punct(p, IIIPN_RPAREN);
    expect_punct(p, IIIPN_ARROW);
    iii_ast_node_t *ret = iiip_parse_type(p);
    if (ret) iii_ast_add_child(p->arena, n, ret);
    iiip_parse_modifiers(p, n, III_AST_TYPE_MODIFIER);
    return n;
}

/* ---- tuple_type ------------------------------------------------------- */

static iii_ast_node_t *parse_tuple_type(iii_parser_t *p) {
    iii_token_t lp = *peek(p, 0);
    consume(p, NULL); /* '(' */
    iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_TUPLE_TYPE);
    if (!n) return NULL;
    iiip_node_span(n, &lp, &lp);
    if (accept_pn(p, IIIPN_RPAREN)) return n; /* () unit */
    iii_ast_node_t *t0 = iiip_parse_type(p);
    if (t0) iii_ast_add_child(p->arena, n, t0);
    while (accept_pn(p, IIIPN_COMMA)) {
        if (peek(p, 0) && peek(p, 0)->kind == IIIK_PUNCT &&
            peek(p, 0)->interned_id == p->pn_id[IIIPN_RPAREN]) break; /* trailing comma */
        iii_ast_node_t *t = iiip_parse_type(p);
        if (t) iii_ast_add_child(p->arena, n, t);
    }
    expect_punct(p, IIIPN_RPAREN);
    return n;
}

/* ---- array_type ::= '[' type ';' INT_LIT ']' ------------------------- */

static iii_ast_node_t *parse_array_type(iii_parser_t *p) {
    iii_token_t lb = *peek(p, 0);
    consume(p, NULL); /* '[' */
    iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_ARRAY_TYPE);
    if (!n) return NULL;
    iiip_node_span(n, &lb, &lb);
    iii_ast_node_t *ty = iiip_parse_type(p);
    if (ty) iii_ast_add_child(p->arena, n, ty);
    if (expect_punct(p, IIIPN_SEMI)) {
        const iii_token_t *t = peek(p, 0);
        if (t && t->kind == IIIK_INT_LIT) {
            n->int_value = t->int_value;
            consume(p, NULL);
        } else {
            iiip_record_error(p, P_E_EXPECTED_TYPE,
                              t ? t->text_offset : 0,
                              t ? t->text_offset + t->text_len : 0,
                              t ? t->line : 0, t ? t->col : 0,
                              "expected INT_LIT in array type");
        }
    }
    expect_punct(p, IIIPN_RBRACK);
    return n;
}

/* ---- top: type ::= base_type type_modifier* | function | tuple | array */

iii_ast_node_t *iiip_parse_type(iii_parser_t *p) {
    const iii_token_t *t = peek(p, 0);
    if (!t) return NULL;
    iii_ast_node_t *outer = iii_arena_node(p->arena, III_AST_TYPE);
    if (!outer) return NULL;
    iiip_node_span(outer, t, t);

    if (t->kind == IIIK_IDENT) {
        size_t slen = 0;
        const char *s = iii_lex_intern_text(p->lex, t->interned_id, &slen);
        if (s && slen == 2 && memcmp(s, "fn", 2) == 0) {
            iii_ast_node_t *fn = parse_function_type(p);
            if (fn) iii_ast_add_child(p->arena, outer, fn);
            return outer;
        }
    }
    if (t->kind == IIIK_PUNCT) {
        if (t->interned_id == p->pn_id[IIIPN_LPAREN]) {
            iii_ast_node_t *tu = parse_tuple_type(p);
            if (tu) iii_ast_add_child(p->arena, outer, tu);
            return outer;
        }
        if (t->interned_id == p->pn_id[IIIPN_LBRACK]) {
            iii_ast_node_t *ar = parse_array_type(p);
            if (ar) iii_ast_add_child(p->arena, outer, ar);
            return outer;
        }
    }
    iii_ast_node_t *base = parse_base_type(p);
    if (base) iii_ast_add_child(p->arena, outer, base);
    iiip_parse_modifiers(p, outer, III_AST_TYPE_MODIFIER);
    return outer;
}
