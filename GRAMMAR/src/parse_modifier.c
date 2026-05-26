/* III Grammar — modifier-set parsing.
 *
 * Parses zero or more @-prefixed modifiers and emits a flat sequence
 * of `mod_kind` nodes (CYCLE_MODIFIER / FUNCTION_MODIFIER /
 * TYPE_MODIFIER / MOBIUS_CANDIDATE_MODIFIER / WAVEFRONT_MODIFIER)
 * appended to `parent`.  The argument(s) of each modifier are added as
 * children of the modifier node.  The modifier id (IIIMOD_*) is stored
 * in `op_id` of the modifier node so the printer can canonicalise.
 *
 * Per §10.6, we accept any modifier order; canonicalisation is the
 * printer's job.  The lexer also accepts `@safety` as an alias for
 * `@hexad` (LEXICON §5.2).  We accept any of the 19 modifier ids
 * regardless of context — the ones that are not legal in a particular
 * context (e.g. `@phys` on a cycle) are rejected by the type system.
 *
 * `@safety` is not in the modifier table (the lexer maps its TEXT to
 * IIIMOD_HEXAD already).  We additionally accept the IDENT-bearing
 * non-canonical modifiers `@phys`, `@gpa`, `@uva`, `@version`, `@abi`
 * (only legal in their proper contexts) — these are tokenised by the
 * lexer as IIIK_MODIFIER but are not in the 19-modifier table; we
 * keep them as op_id = IIIMOD_COUNT (sentinel) and stash the modifier
 * text via `interned_id`.
 */
#include "parse_internal.h"

/* ---- Argument parsers (one per modifier shape) ----------------------- */

/* `( IDENT )` argument list — used by @plan_anchor, @gpa, @uva */
static void mod_arg_ident(iii_parser_t *p, iii_ast_node_t *m) {
    if (!expect_punct(p, IIIPN_LPAREN)) return;
    iii_token_t id;
    if (expect_ident(p, &id)) {
        iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_QUALIFIED_NAME);
        if (n) {
            n->interned_id = id.interned_id;
            iiip_node_span(n, &id, &id);
            iii_ast_add_child(p->arena, m, n);
        }
    }
    expect_punct(p, IIIPN_RPAREN);
}

/* `( STRING_LIT )` — used by @version */
static void mod_arg_string(iii_parser_t *p, iii_ast_node_t *m) {
    if (!expect_punct(p, IIIPN_LPAREN)) return;
    const iii_token_t *t = peek(p, 0);
    if (t && t->kind == IIIK_STRING_LIT) {
        iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_LITERAL);
        if (n) {
            n->interned_id    = t->interned_id;
            n->string_payload = t->string_payload;
            n->string_len     = t->string_len;
            iiip_node_span(n, t, t);
            iii_ast_add_child(p->arena, m, n);
        }
        consume(p, NULL);
    } else {
        iiip_record_error(p, P_E_BAD_MODIFIER_ARG,
                          t ? t->text_offset : 0,
                          t ? t->text_offset + t->text_len : 0,
                          t ? t->line : 0, t ? t->col : 0,
                          "expected string literal in modifier arg");
    }
    expect_punct(p, IIIPN_RPAREN);
}

/* `( MHASH_LIT )` — used by @closure */
static void mod_arg_mhash(iii_parser_t *p, iii_ast_node_t *m) {
    if (!expect_punct(p, IIIPN_LPAREN)) return;
    const iii_token_t *t = peek(p, 0);
    if (t && t->kind == IIIK_MHASH_LIT) {
        iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_LITERAL);
        if (n) {
            memcpy(n->mhash_value, t->mhash_value, 32);
            iiip_node_span(n, t, t);
            iii_ast_add_child(p->arena, m, n);
        }
        consume(p, NULL);
    } else {
        iiip_record_error(p, P_E_BAD_MODIFIER_ARG,
                          t ? t->text_offset : 0,
                          t ? t->text_offset + t->text_len : 0,
                          t ? t->line : 0, t ? t->col : 0,
                          "expected mhash literal in @closure arg");
    }
    expect_punct(p, IIIPN_RPAREN);
}

/* `( ring_set )` — @ring */
static void mod_arg_ring_set(iii_parser_t *p, iii_ast_node_t *m) {
    if (!expect_punct(p, IIIPN_LPAREN)) return;
    iii_ast_node_t *n = iiip_parse_ring_set(p);
    if (n) iii_ast_add_child(p->arena, m, n);
    expect_punct(p, IIIPN_RPAREN);
}

/* `( hexad_designator )` — @hexad / @safety */
static void mod_arg_hexad(iii_parser_t *p, iii_ast_node_t *m) {
    if (!expect_punct(p, IIIPN_LPAREN)) return;
    iii_ast_node_t *n = iiip_parse_hexad_designator(p);
    if (n) iii_ast_add_child(p->arena, m, n);
    expect_punct(p, IIIPN_RPAREN);
}

/* `( tier_name )` — @tier */
static void mod_arg_tier(iii_parser_t *p, iii_ast_node_t *m) {
    if (!expect_punct(p, IIIPN_LPAREN)) return;
    iii_ast_node_t *n = iiip_parse_tier_name(p);
    if (n) iii_ast_add_child(p->arena, m, n);
    expect_punct(p, IIIPN_RPAREN);
}

/* `( epoch_value )` — @epoch */
static void mod_arg_epoch(iii_parser_t *p, iii_ast_node_t *m) {
    if (!expect_punct(p, IIIPN_LPAREN)) return;
    iii_ast_node_t *n = iiip_parse_epoch_value(p);
    if (n) iii_ast_add_child(p->arena, m, n);
    expect_punct(p, IIIPN_RPAREN);
}

/* `( cap_perm , range? )` — @cap */
static void mod_arg_cap(iii_parser_t *p, iii_ast_node_t *m) {
    if (!expect_punct(p, IIIPN_LPAREN)) return;
    iii_token_t id;
    if (expect_ident(p, &id)) {
        iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_QUALIFIED_NAME);
        if (n) {
            n->interned_id = id.interned_id;
            iiip_node_span(n, &id, &id);
            iii_ast_add_child(p->arena, m, n);
        }
    }
    if (accept_pn(p, IIIPN_COMMA)) {
        iii_ast_node_t *r = iiip_parse_range(p);
        if (r) iii_ast_add_child(p->arena, m, r);
    }
    expect_punct(p, IIIPN_RPAREN);
}

/* `( replication_policy )` — @replicates */
static void mod_arg_replicates(iii_parser_t *p, iii_ast_node_t *m) {
    if (!expect_punct(p, IIIPN_LPAREN)) return;
    iii_ast_node_t *n = iiip_parse_replication(p);
    if (n) iii_ast_add_child(p->arena, m, n);
    expect_punct(p, IIIPN_RPAREN);
}

/* `( IDENT (',' IDENT)* )` — @admits_caps, @prerequisites */
static void mod_arg_ident_list(iii_parser_t *p, iii_ast_node_t *m) {
    if (!expect_punct(p, IIIPN_LPAREN)) return;
    do {
        iii_token_t id;
        if (!expect_ident(p, &id)) break;
        iii_ast_node_t *n = iii_arena_node(p->arena, III_AST_QUALIFIED_NAME);
        if (n) {
            n->interned_id = id.interned_id;
            iiip_node_span(n, &id, &id);
            iii_ast_add_child(p->arena, m, n);
        }
    } while (accept_pn(p, IIIPN_COMMA));
    expect_punct(p, IIIPN_RPAREN);
}

/* `( coherence_expr )` — @mobius_coherence */
static void mod_arg_coherence(iii_parser_t *p, iii_ast_node_t *m) {
    if (!expect_punct(p, IIIPN_LPAREN)) return;
    iii_ast_node_t *n = iiip_parse_coherence_expr(p);
    if (n) iii_ast_add_child(p->arena, m, n);
    expect_punct(p, IIIPN_RPAREN);
}

/* ---- Single modifier dispatch ---------------------------------------- */

/* Try to consume one modifier.  Returns the new node (already filled
 * with op_id and arg children), or NULL if the cursor is not on a
 * modifier token. */
static iii_ast_node_t *parse_one_modifier(iii_parser_t *p,
                                          iii_ast_kind_t mod_kind) {
    const iii_token_t *t = peek(p, 0);
    if (!t || t->kind != IIIK_MODIFIER) return NULL;

    iii_token_t mtok = *t;
    iii_ast_node_t *m = iii_arena_node(p->arena, mod_kind);
    if (!m) { consume(p, NULL); return NULL; }
    /* Default interned_id to the literal text id (overwritten with the
     * canonical id below for known modifiers, so aliases like @safety
     * canonicalize to @hexad). */
    m->interned_id = mtok.interned_id;
    iiip_node_span(m, &mtok, &mtok);

    /* Dispatch via the lexer's canonical_id (1..19), which folds aliases
     * (e.g. @safety → 2, identical to @hexad).  IIIMOD_* enum order
     * mirrors the §5.1 numbering, so `which = canonical_id - 1`. */
    int matched = 0;
    if (mtok.int_value >= 1 && mtok.int_value <= (int64_t)IIIMOD_COUNT) {
        iii_mod_e which = (iii_mod_e)(mtok.int_value - 1);
        m->op_id = (uint16_t)which;
        m->interned_id = p->mod_id[which];
        consume(p, NULL);
        matched = 1;
        switch (which) {
            case IIIMOD_RING:                     mod_arg_ring_set(p, m); break;
            case IIIMOD_HEXAD:                    mod_arg_hexad(p, m); break;
            case IIIMOD_TIER:                     mod_arg_tier(p, m); break;
            case IIIMOD_EPOCH:                    mod_arg_epoch(p, m); break;
            case IIIMOD_CAP:                      mod_arg_cap(p, m); break;
            case IIIMOD_CLOSURE:                  mod_arg_mhash(p, m); break;
            case IIIMOD_REPLICATES:               mod_arg_replicates(p, m); break;
            case IIIMOD_PLAN_ANCHOR:              mod_arg_ident(p, m); break;
            case IIIMOD_ADMITS_CAPS:              mod_arg_ident_list(p, m); break;
            case IIIMOD_PREREQUISITES:            mod_arg_ident_list(p, m); break;
            case IIIMOD_MOBIUS_COHERENCE:         mod_arg_coherence(p, m); break;
            case IIIMOD_SANCTUM_ONLY:
            case IIIMOD_IRREVERSIBLE:
            case IIIMOD_PURE:
            case IIIMOD_CANDIDATE_FOR_PROMOTION:
            case IIIMOD_WITNESS_ELIDE:
            case IIIMOD_HOT_PATH:
            case IIIMOD_CHRONOS_BYPASS:
            case IIIMOD_EPOCH_BRIDGE:
            case IIIMOD_COUNT:
            default: break;
        }
    }

    if (!matched) {
        /* Non-canonical modifier — accepted by the lexer but not in the
         * 19-modifier table.  Examples: @phys, @gpa(IDENT), @uva(IDENT),
         * @version("..."), @abi(c-msvc-x64).  We classify by text and
         * parse the appropriate argument shape; otherwise consume and
         * leave the node payload-free. */
        size_t slen = 0;
        const char *txt = iii_lex_intern_text(p->lex, mtok.interned_id, &slen);
        m->op_id = (uint16_t)IIIMOD_COUNT; /* sentinel "non-canonical" */
        consume(p, NULL);
        if (txt && slen > 0) {
            if (slen == 5 && memcmp(txt, "@phys", 5) == 0) {
                /* no args */
            } else if ((slen == 4 && memcmp(txt, "@gpa", 4) == 0) ||
                       (slen == 4 && memcmp(txt, "@uva", 4) == 0)) {
                mod_arg_ident(p, m);
            } else if (slen == 8 && memcmp(txt, "@version", 8) == 0) {
                mod_arg_string(p, m);
            } else if (slen == 4 && memcmp(txt, "@abi", 4) == 0) {
                mod_arg_ident(p, m);
            } else if (peek(p, 0) &&
                       peek(p, 0)->kind == IIIK_PUNCT &&
                       peek(p, 0)->interned_id == p->pn_id[IIIPN_LPAREN]) {
                /* Unknown modifier with parenthesised arg — swallow as
                 * a single qualified_name arg if possible, else skip. */
                consume(p, NULL);
                while (peek(p, 0) &&
                       peek(p, 0)->kind != IIIK_EOF &&
                       !(peek(p, 0)->kind == IIIK_PUNCT &&
                         peek(p, 0)->interned_id == p->pn_id[IIIPN_RPAREN])) {
                    consume(p, NULL);
                }
                accept_pn(p, IIIPN_RPAREN);
            }
        }
    }
    return m;
}

void iiip_parse_modifiers(iii_parser_t *p,
                          iii_ast_node_t *parent,
                          iii_ast_kind_t mod_kind) {
    for (;;) {
        const iii_token_t *t = peek(p, 0);
        if (!t || t->kind != IIIK_MODIFIER) return;
        iii_ast_node_t *m = parse_one_modifier(p, mod_kind);
        if (m) iii_ast_add_child(p->arena, parent, m);
        else   return;
    }
}
