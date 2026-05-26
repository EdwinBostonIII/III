# ADR-RES-017 — parse.c Patch For Resolver Surface Syntax

## Status

FROZEN. Implementation diff for FROZEN SPEC step C0002.

## Context

The III bootstrap parser is `COMPILER/BOOT/parse.c` (3624 lines, recursive-descent over the III grammar). Adding the surface syntax for `resolve { ... }`, `intent { ... }`, `pattern { ... }`, `transform { ... }` requires four new productions plus AST node emission.

Per FROZEN SPEC C0001, the lexer reserves token IDs 125–128. This ADR specifies the parse.c diff needed to consume those tokens.

## Diff Specification

### 1. Recognise Statement-Level Block Forms

Locate `parse_primary_expr` or equivalent (search for token-dispatch on `III_TOK_KW_LET`). Add four new cases before the default fallthrough:

```c
case III_TOK_KW_RESOLVE:    return parse_resolve_expr(p);
case III_TOK_KW_INTENT:     return parse_intent_literal(p);
case III_TOK_KW_PATTERN:    return parse_pattern_decl(p);
case III_TOK_KW_TRANSFORM:  return parse_transform_expr(p);
```

### 2. Author Four Production Functions

Each follows the same shape: consume the keyword, expect `{`, parse comma-separated `key: value` pairs, expect `}`. AST emission uses existing helpers `iii_ast_alloc_node`, `iii_ast_set_kind`.

```c
static iii_ast_id parse_resolve_expr(iii_parse_state* p) {
    iii_token kw = iii_parse_consume(p, III_TOK_KW_RESOLVE);
    iii_token open = iii_parse_consume(p, III_TOK_LBRACE);
    iii_ast_id node = iii_ast_alloc_node(p->ast);
    iii_ast_set_kind(p->ast, node, K_EXPR_RESOLVE);
    iii_ast_set_span_start(p->ast, node, kw.span_start);
    /* Expect: pattern: <expr>, ctx: <expr> */
    iii_parse_expect_field(p, node, "pattern", parse_expr);
    iii_parse_consume(p, III_TOK_COMMA);
    iii_parse_expect_field(p, node, "ctx", parse_expr);
    iii_parse_consume(p, III_TOK_RBRACE);
    return node;
}

static iii_ast_id parse_intent_literal(iii_parse_state* p) {
    iii_token kw = iii_parse_consume(p, III_TOK_KW_INTENT);
    iii_parse_consume(p, III_TOK_LBRACE);
    iii_ast_id node = iii_ast_alloc_node(p->ast);
    iii_ast_set_kind(p->ast, node, K_EXPR_INTENT_LITERAL);
    /* Parse field list: goal_kind | partial_args | required_guarantees |
     *                   expected_hexad_kind | arena_intent | cap */
    iii_parse_field_list(p, node, INTENT_FIELD_TAGS, 6);
    iii_parse_consume(p, III_TOK_RBRACE);
    return node;
}

static iii_ast_id parse_pattern_decl(iii_parse_state* p) {
    iii_token kw = iii_parse_consume(p, III_TOK_KW_PATTERN);
    iii_token name = iii_parse_consume(p, III_TOK_IDENT);
    iii_parse_consume(p, III_TOK_LBRACE);
    iii_ast_id node = iii_ast_alloc_node(p->ast);
    iii_ast_set_kind(p->ast, node, K_DECL_PATTERN);
    iii_ast_set_decl_name(p->ast, node, name.span_start, name.span_len);
    iii_parse_field_list(p, node, PATTERN_FIELD_TAGS, 8);
    iii_parse_consume(p, III_TOK_RBRACE);
    return node;
}

static iii_ast_id parse_transform_expr(iii_parse_state* p) {
    iii_token kw = iii_parse_consume(p, III_TOK_KW_TRANSFORM);
    iii_parse_consume(p, III_TOK_LBRACE);
    iii_ast_id node = iii_ast_alloc_node(p->ast);
    iii_ast_set_kind(p->ast, node, K_EXPR_TRANSFORM);
    iii_parse_field_list(p, node, TRANSFORM_FIELD_TAGS, 4);
    iii_parse_consume(p, III_TOK_RBRACE);
    return node;
}
```

### 3. AST Kind Constants

Locate `iii_ast_kind` enum (in ast.c or ast.h). Add:

```c
#define K_EXPR_RESOLVE          1100u
#define K_EXPR_INTENT_LITERAL   1101u
#define K_DECL_PATTERN          1102u
#define K_EXPR_TRANSFORM        1103u
```

### 4. Field-Tag Tables

```c
static const iii_field_tag INTENT_FIELD_TAGS[] = {
    {"goal_kind",            FIELD_GOAL_KIND,            FIELD_TYPE_U8},
    {"partial_args",         FIELD_PARTIAL_ARGS,         FIELD_TYPE_ARRAY_U64},
    {"required_guarantees",  FIELD_REQUIRED_GUARANTEES,  FIELD_TYPE_U32},
    {"expected_hexad_kind",  FIELD_EXPECTED_HEXAD,       FIELD_TYPE_U8},
    {"arena_intent",         FIELD_ARENA_INTENT,         FIELD_TYPE_U64},
    {"cap",                  FIELD_CAP,                  FIELD_TYPE_U64}
};

static const iii_field_tag PATTERN_FIELD_TAGS[] = {
    {"activation_base",      PF_ACTIVATION_BASE,         FIELD_TYPE_U64},
    {"hexad_kind",           PF_HEXAD_KIND,              FIELD_TYPE_U8},
    {"ring",                 PF_RING,                    FIELD_TYPE_U8},
    {"k_value",              PF_K_VALUE,                 FIELD_TYPE_U64},
    {"guarantees_provided",  PF_GUARANTEES_PROVIDED,     FIELD_TYPE_U32},
    {"specialisation_of",    PF_SPECIALISATION_OF,       FIELD_TYPE_U64},
    {"predicate",            PF_PREDICATE_FN,            FIELD_TYPE_FN_REF},
    {"dispatch",             PF_DISPATCH_FN,             FIELD_TYPE_FN_REF}
};

static const iii_field_tag TRANSFORM_FIELD_TAGS[] = {
    {"src_form",             0u,                         FIELD_TYPE_U32},
    {"dst_form",             1u,                         FIELD_TYPE_U32},
    {"input",                2u,                         FIELD_TYPE_U64_EXPR},
    {"ctx",                  3u,                         FIELD_TYPE_U64_EXPR}
};
```

### 5. Lowering In sema.iii / sema.c

Locate the K_EXPR_CALL semantic check. Add cases for K_EXPR_RESOLVE, K_EXPR_INTENT_LITERAL, K_DECL_PATTERN, K_EXPR_TRANSFORM that:

1. Verify required fields present.
2. Bind extern symbols `iii_resolve` / `iii_transform` / `iii_pattern_register`.
3. Synthesise the corresponding extern call: `K_EXPR_RESOLVE` → call sequence to `resolve(pattern, intent, ctx)`.

### 6. Codegen Lowering In cg_r3.c

For K_EXPR_RESOLVE, K_EXPR_TRANSFORM, K_EXPR_INTENT_LITERAL: lower to a direct call to `resolve` / `transform` / `intent_form_lower` respectively. For K_DECL_PATTERN: emit at boot a `pattern_register` call sequence.

## Consequences

After this patch lands:
- Source code can write `intent { goal_kind: 1, ... }` directly.
- `resolve { pattern: ..., ctx: ... }` becomes a normal expression.
- Patterns can be declared at module scope.
- Transforms can be invoked inline.

Until this patch lands:
- All resolver runtime is fully accessible via `extern` declarations from .iii source (corpus 31..54 demonstrates this).
- The surface syntax is sugar; the underlying API is complete.

## Audit Path

Before merging the parse.c patch:
1. Author the patch.
2. Run all 30 baseline corpus tests — must all PASS unchanged.
3. Run the 24 resolution corpus tests — must all PASS unchanged.
4. Add corpus tests 55..58 exercising the new surface syntax.
5. Run full corpus — 58/58 PASS.
6. Re-seal `iiis-0.mhash` (will change due to parse.c modification).
7. Re-seal `SEAL_RESOLVER.mhash` (unchanged).
8. Commit.

## Lineage

Authored: step C0002 of §I, deferred during iiis-0 self-host work (Phase B Path A).
Unblocks: surface syntax for resolution primitives.
Dependencies: lex.iii keyword IDs already added (C0001 complete).

This ADR is the canonical reference for the C0002 implementation.
