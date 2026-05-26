/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\parse.h
 *
 * III Stage-0 Parser — public interface.
 *
 * Purpose: consume the token stream produced by iii_lex_next and
 * construct a iii_ast_t per the productions in TELOS-GRAMMAR.bnf.
 *
 * Algorithm:
 *   - Recursive-descent LL(1) parser for the structural productions
 *     (module / use / decl / stmt / type expressions).
 *   - Pratt-style operator-precedence climbing for expression
 *     productions, using a single precedence table.
 *
 * Design discipline (per ADR-021 NIH):
 *   - Pure NIH: no parser-generator, no third-party.
 *   - One-token lookahead via iii_lex_peek (the LL(1) predicate).
 *   - Errors recorded in parse state; the parser continues after
 *     recoverable syntax errors so multiple errors can be reported in
 *     one pass.
 *
 * Spec source: DOCS/TELOS-GRAMMAR.bnf (the EBNF grammar).
 */

#ifndef III_BOOT_PARSE_H
#define III_BOOT_PARSE_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#include "lex.h"
#include "ast.h"

#ifdef __cplusplus
extern "C" {
#endif

/* ─── Parser error record ────────────────────────────────────────── */

#define III_PARSE_OK                       0
#define III_PARSE_E_UNEXPECTED_TOKEN       1
#define III_PARSE_E_EXPECTED_IDENT         2
#define III_PARSE_E_EXPECTED_LITERAL       3
#define III_PARSE_E_EXPECTED_TYPE          4
#define III_PARSE_E_EXPECTED_EXPR          5
#define III_PARSE_E_EXPECTED_PATTERN       6
#define III_PARSE_E_BAD_MODIFIER           7
#define III_PARSE_E_BAD_HEXAD              8
#define III_PARSE_E_BAD_RING_SET           9
#define III_PARSE_E_LEX                    10  /* lexer error */
#define III_PARSE_E_OOM                    11
#define III_PARSE_E_RECURSION_LIMIT        12  /* exceeded depth bound */
#define III_PARSE_E_NULL_ARG               13
#define III_PARSE_E_UNEXPECTED_EOF         14
/* C1 — emitted when realloc of the dynamic error queue fails; the
 * queue then falls back to its current cap and subsequent errors are
 * dropped silently.  Numeric value 15. */
#define III_PARSE_E_ERRORS_TRUNCATED       15
/* B2 — emitted on synthesised insertion of a missing terminator.
 * Numeric value 16.  Treat as a recoverable diagnostic; the parser
 * continues with the inserted token assumed present. */
#define III_PARSE_E_INSERTED_TOKEN         16
/* R1 — registry full / handle exhausted.  Numeric value 17. */
#define III_PARSE_E_REGISTRY_FULL          17

typedef struct {
    int                code;
    uint32_t           byte;
    uint32_t           line;
    uint32_t           col;
    const char        *message;
    /* The token at which the error occurred. */
    iii_token_kind_t saw_kind;
    /* What was expected, if applicable. */
    iii_token_kind_t expected_kind;
    /* H2 — production-context breadcrumb (e.g. "module > cycle Foo >
     * param list").  Points into a per-state rotating buffer; valid
     * for the parser's lifetime.  May be NULL if no context was
     * active. */
    const char        *breadcrumb;
    /* C2 — number of additional consecutive identical errors that
     * were suppressed (>=0).  When this error is the trailing
     * "(N more identical errors suppressed)" sentinel, this field
     * carries N; otherwise zero. */
    uint32_t           dup_count;
} iii_parse_error_t;

/* ─── Parser state (opaque) ──────────────────────────────────────── */

struct iii_parse_state;
typedef struct iii_parse_state iii_parse_state_t;

/* ─── API ────────────────────────────────────────────────────────── */

/* Build a parser bound to the given lexer + AST.  `lex_state` and
 * `ast` must outlive the parser; the parser does not free them.  The
 * AST should be empty (only the III_AST_NULL sentinel at index 0)
 * when passed in.  Returns NULL on allocation failure. */
iii_parse_state_t *iii_parse_create(iii_lex_state_t *lex_state,
                                          iii_ast_t       *ast);

void iii_parse_destroy(iii_parse_state_t *st);

/* Parse the entire source as a single MODULE.  On success returns 1
 * and sets `ast->root_module` to the module node id.  On error returns
 * 0; consult iii_parse_error_info().  The parser does its best to
 * continue after recoverable errors, so multiple errors may be queued
 * (the first is returned by error_info; subsequent ones can be
 * iterated via iii_parse_error_count / iii_parse_error_at). */
int iii_parse_module(iii_parse_state_t *st);

/* First (most urgent) error info. */
void iii_parse_error_info(const iii_parse_state_t *st,
                              iii_parse_error_t *out_err);

/* Total number of errors recorded. */
uint32_t iii_parse_error_count(const iii_parse_state_t *st);

/* Read the i-th error (i < iii_parse_error_count). */
void iii_parse_error_at(const iii_parse_state_t *st,
                            uint32_t i,
                            iii_parse_error_t *out_err);

/* Translate a parse-error code to a stable .rdata string. */
const char *iii_parse_error_name(int code);

/* ─── Recovery contract (B3) ─────────────────────────────────────── */

/*
 * After a recoverable syntax error the parser performs FIRST/FOLLOW-
 * aware recovery (B1) and continues to produce structure.  The
 * following invariants hold across every recovery point:
 *
 *   - The lookahead is left at a synchronisation token belonging to
 *     either the FIRST set of the current production's siblings or
 *     the FOLLOW set of the failed production.  EOF is always a
 *     synchronisation token.
 *   - All AST nodes that were successfully committed before the
 *     error remain in the AST and remain reachable from their
 *     parents (the parent installs the partial child list it had at
 *     the moment of failure).
 *   - When `parse.h`'s `expect()` synthesises a missing terminator
 *     (B2: SEMI, RBRACE, RPAREN, COLON), the error code
 *     III_PARSE_E_INSERTED_TOKEN is queued and parsing continues as
 *     if the token had been present.
 *   - When the AST is unable to allocate a node, the production
 *     plants III_AST_ERROR_NODE (where ast.h supports it) so sema
 *     sees a typed Bottom rather than a NULL hole.  If ast.h is
 *     older than the K1 patch, the production returns 0; documented
 *     in parse.c at the relevant call site.
 *   - The parse witness mhash (A1) is updated for every committed
 *     node and for every speculation rollback (mixed in as a
 *     "speculation_rolled_back" marker), so the witness is a
 *     deterministic function of the token stream regardless of the
 *     recovery path taken.
 *   - Top-level decl recovery: even if every top-level decl errors,
 *     `iii_ast_root_module(ast)` returns the Module node containing
 *     the partial list of successfully-parsed decls.  The Module
 *     itself is 0 only if the `module` header was unparseable (P1).
 *
 * Items the recovery contract does NOT cover:
 *
 *   - Token-stream re-synchronisation across unbalanced braces in a
 *     metal {} block beyond the first EOF; the parser stops at EOF
 *     and queues UNEXPECTED_EOF.
 *   - Deep speculation rollback past a Pratt expression; the
 *     speculation checkpoint (K1) covers the parser's own state but
 *     does not undo lex-state advancement (the lexer's stream is
 *     monotonic by design, see lex.h D13).
 */

/* ─── Lossiness declaration (J1) ─────────────────────────────────── */

/*
 * STAGE-0 LOSSINESS NOTICE.  The Stage-0 parser is LOSSY: trivia
 * (whitespace, comments, NEWLINE tokens that the grammar discards,
 * doc-comments not consumed by the K1 leading-doc-comment hook) is
 * dropped from the AST.  Source-text round-trip
 * (parse → unparse → bytes-equal-input) is NOT preserved.
 *
 * TODO(post-K1): When lex.h gains a trivia-attachment API
 * (`iii_lex_trivia_for_token`), wire it through this parser so each
 * AST node carries leading + trailing trivia spans and round-trip
 * becomes lossless.  Tracked at SPEC.XII §J1.
 */

/* ─── Pratt operator table (N1) ──────────────────────────────────── */

/*
 * Public view of the parser's binary-operator precedence table.
 * Higher `prec` binds tighter; `prec == 0` means "not a binary
 * operator".  When `right_assoc` is true the operator is right-
 * associative (e.g. assignment, exponentiation if added later);
 * otherwise left-associative.  The `op` field is a `iii_binop_t`
 * code (defined by ast.h).  The table is exported so external
 * tooling — pretty-printers, linters, IDE highlighters, and the
 * Stage-1 self-hosting parser — can reproduce parse precedence
 * without duplicating the table.
 */
typedef struct {
    iii_token_kind_t token;       /* trigger token */
    int              prec;        /* >0 binds; 0 = not a binop */
    bool             right_assoc; /* true = right-assoc */
    int              op;          /* iii_binop_t value */
} iii_parse_binop_info_t;

/* Returns a pointer to the static table and writes the entry count
 * to `*out_n` (may be NULL).  The returned pointer is valid for the
 * program's lifetime and must not be modified. */
const iii_parse_binop_info_t *iii_parse_binop_table(size_t *out_n);

/* ─── Public sub-entry points (F1) ───────────────────────────────── */

/*
 * Thin public wrappers around the parser's internal recursive
 * productions.  These are useful for tools that want to parse a
 * fragment (e.g. a REPL evaluating a single expression, or a macro
 * system invoking the parser on a sub-token-stream).  Each wrapper
 * pushes its own production-context breadcrumb (H2) and maintains
 * the witness mhash exactly as the corresponding internal call site
 * would.  Returns the freshly-allocated AST node id on success, or
 * 0 on failure (consult `iii_parse_error_at`).
 */
uint32_t iii_parse_expression(iii_parse_state_t *st);
uint32_t iii_parse_type      (iii_parse_state_t *st);
uint32_t iii_parse_pattern   (iii_parse_state_t *st);
uint32_t iii_parse_decl      (iii_parse_state_t *st);

/* F2 — streaming decl-by-decl mode.  Parses exactly one top-level
 * declaration from the current lookahead position and writes its
 * AST node id to `*out_node`.  Returns 1 on success (decl produced),
 * 0 on clean EOF (no more decls; `*out_node` set to 0), and -1 on
 * error (`*out_node` set to 0; consult the error queue).  Useful
 * for streaming compilers that want to interleave parse with sema
 * one decl at a time.  Does NOT parse the leading `module` header
 * — call `iii_parse_module` for that, OR set up a synthesised
 * Module node yourself and feed this in a loop. */
int iii_parse_decl_next(iii_parse_state_t *st, uint32_t *out_node);

/* ─── Witness API (A1, A2, E1) ───────────────────────────────────── */

/*
 * Parse-witness mhash.  Returns the streaming SHA-256 of the
 * sequence of node-commit tuples
 *   (kind:u32, start:u32, end:u32, child_count:u32, child_ids:u32[])
 * folded in production-commit order, plus any speculation-rollback
 * markers (K1).  The digest is a deterministic function of the
 * token stream and the registered grammar extensions (R1); two runs
 * over identical sources with identical registries produce
 * byte-identical digests.  Once `iii_parse_module` returns, this
 * digest is the parse-side companion to the AST-side per-node mhash
 * (which the K1 / V1 ast.h patches will subsume in the future).
 *
 * `out` MUST point to a 32-byte buffer; the SHA-256 digest is
 * written in big-endian byte order (FIPS 180-4 §6.2.2).
 */
void iii_parse_witness_mhash(const iii_parse_state_t *st, uint8_t out[32]);

/* A2 — witness sink.  When set, the supplied callback is invoked
 * synchronously at every node-commit (immediately after the node id
 * has been folded into the witness mhash).  `kind` is an
 * `iii_ast_kind_t` value; `start`/`end` are source-byte offsets.
 * Off by default (NULL fn).  Pass fn = NULL to detach.  The sink
 * MUST NOT mutate the parser state; it is intended for tracing and
 * for incremental witness export. */
typedef void (*iii_parse_witness_sink_fn_t)(void     *ctx,
                                              uint32_t  node_id,
                                              uint32_t  kind,
                                              uint32_t  start,
                                              uint32_t  end);
void iii_parse_set_witness_sink(iii_parse_state_t           *st,
                                  iii_parse_witness_sink_fn_t  fn,
                                  void                        *ctx);

/* E1 — grammar mhash.  Streaming SHA-256 of the sorted list of
 * (production-name, first-token-set) pairs hard-coded into parse.c,
 * re-mixed with every entry currently present in the grammar-
 * extension registry (R1).  Deterministic; sort is by canonical
 * ASCII lexicographic order of the production name.  Two parsers
 * with identical built-in grammar and identical registry contents
 * produce byte-identical digests. */
void iii_parse_grammar_mhash(const iii_parse_state_t *st, uint8_t out[32]);

/* ─── Pratt decision trace (Q1) ──────────────────────────────────── */

/*
 * Optional trace callback fired once per precedence-climb decision
 * inside the Pratt expression loop.  `byte` is the source-byte
 * offset of the operator under consideration; `prec` is its
 * precedence (0 if not a binary operator); `min_prec` is the
 * climber's current minimum-precedence floor; `taken` is true if
 * the climber bound the operator and recursed, false if it
 * declined.  Off by default.  Pass fn = NULL to detach.
 */
typedef void (*iii_parse_pratt_trace_fn_t)(void *ctx,
                                              uint32_t byte,
                                              int      prec,
                                              int      min_prec,
                                              bool     taken);
void iii_parse_set_pratt_trace(iii_parse_state_t          *st,
                                 iii_parse_pratt_trace_fn_t  fn,
                                 void                       *ctx);

/* ─── Grammar-extension registry (R1) ────────────────────────────── */

/*
 * The grammar-extension registry is THE deepest extension point of
 * the III bootstrap parser.  It lets a host (Stage-1, a macro
 * system, a domain-specific embedding) install handlers for new
 * top-level declarations, statements, or primary expressions WITHOUT
 * forking the parser.  Each handler is keyed on a single first
 * token; when the parser's dispatcher sees that token, the
 * registered handler runs FIRST.  If the handler returns a non-zero
 * AST node id, it "wins" and the parser proceeds; if it returns 0,
 * the built-in dispatch path runs as if the handler had not been
 * registered.  This "first token + non-zero wins" semantics is
 * deliberately strict so that registry contents never silently mask
 * a built-in production: a misconfigured handler that returns 0 is
 * indistinguishable from no registration at all.
 *
 * Each successful registration returns a monotonic non-zero handle.
 * `iii_parse_unregister` removes the entry by handle.  Both
 * register and unregister update the grammar mhash (E1) so any
 * downstream witness reflects the active grammar surface.
 *
 * Implementation caps each kind at 64 entries; further attempts
 * return 0 and queue III_PARSE_E_REGISTRY_FULL.  The internal
 * tables are arrays; iteration order on dispatch is registration
 * order (deterministic).
 */
typedef uint32_t (*iii_parse_decl_fn_t)(iii_parse_state_t *st);

uint32_t iii_parse_register_decl_kind   (iii_parse_state_t   *st,
                                            iii_token_kind_t      first_token,
                                            iii_parse_decl_fn_t   fn);
uint32_t iii_parse_register_stmt_kind   (iii_parse_state_t   *st,
                                            iii_token_kind_t      first_token,
                                            iii_parse_decl_fn_t   fn);
uint32_t iii_parse_register_primary_kind(iii_parse_state_t   *st,
                                            iii_token_kind_t      first_token,
                                            iii_parse_decl_fn_t   fn);
bool     iii_parse_unregister           (iii_parse_state_t   *st,
                                            uint32_t              reg_handle);

/* ─── Modifier resolution discipline (M1) ────────────────────────── */

/*
 * The Stage-0 parser does NOT pre-resolve modifier semantics.
 * `@ring(...)`, `@tier(...)`, `@epoch(...)` and friends are stored
 * exclusively as their source-form `name`+`args` payload.  The
 * `ring_mask`, `tier_kind`, `epoch_value` fields on the modifier
 * AST node MAY be present (left for back-compat with older sema),
 * but the parser writes them as zero/INVALID and Sema is the
 * canonical interpreter.  This eliminates the modifier-resolution
 * dust source called out by the M1 deepening: any future change to
 * ring-set vocabulary, tier kinds, or epoch encoding affects only
 * sema, never the parser.
 */


#ifdef __cplusplus
}
#endif

#endif /* III_BOOT_PARSE_H */
