/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\lex.h
 *
 * III Stage-0 Lexer — public interface.
 *
 * Purpose: convert an III source byte stream (UTF-8) into a flat
 * token stream that the recursive-descent parser (parse.c) consumes.
 * Token vocabulary is the union of:
 *   - identifiers              ([A-Za-z_][A-Za-z0-9_]*)
 *   - integer/hex/mhash literals (with optional integer-type suffix)
 *   - string literals          (plain "…", byte b"…", raw r"…", hex h"…")
 *   - reserved words           (~55 keywords + 8 modifier keywords)
 *   - operators and punctuation
 *   - the `@` introducer for modifiers (the modifier name is its own
 *     token kind so the parser does not strcmp every modifier site)
 *   - doc-comments — line form (three slashes) and block form
 *     (slash-asterisk-asterisk … asterisk-slash); attached as leading
 *     metadata on the next significant token
 *
 * Spec source: C:\CHARIOT\DOCS\TELOS-GRAMMAR.bnf (the lexical and
 *              syntactic spec inherited from the LOGOS predecessor;
 *              III renames identifiers but preserves the surface
 *              grammar and adds the deepening clauses below).
 *
 * File extension convention: III source files use the `.III` suffix.
 *
 * ─── Discipline (per ADR-021 NIH + ADR-027 §"NIH preservation") ────
 *
 *   - Pure NIH: only <stdint.h>, <stddef.h>, <stdbool.h>, <stdio.h>,
 *     <stdlib.h>, <string.h> on host side (Stage 0 is host-built;
 *     ADR-021 §Boundaries permits libc on the build host).
 *   - No flex/lex/yacc/regex; explicit hand-coded state machine.
 *   - Token positions tracked as (start_byte, end_byte, line, col) for
 *     error reporting and IDE integration.
 *   - Byte-precise: source is bytes, not chars; UTF-8 is opaque inside
 *     string literals; identifiers are restricted to ASCII.
 *   - Zero-copy for non-literal tokens (the source buffer is the
 *     witness); pre-decoded payloads stored eagerly for literal tokens.
 *   - Literal payloads larger than what fits in iii_token_t directly
 *     (string_payload, glyph payloads, future hex-string bytes) live in
 *     a stable chunk-list arena owned by the lex state; pointers
 *     remain valid for the lifetime of the state.  See `iii_lex_seal`
 *     for transferring payload ownership to a long-lived AST.
 *
 * ─── Determinism contract (D12) ────────────────────────────────────
 *
 *   `iii_lex_next` is a deterministic function of
 *   (`source_buf[0..source_len]`, number of prior calls, the keyword
 *   table populated via `iii_lex_register_keyword`).  No timestamp,
 *   RNG, allocator address, or environment variable may influence
 *   token kind, payloads, position fields, error codes, or order.
 *   Stage 2 reproducibility (sha256(logoss-1) == sha256(logoss-2))
 *   depends on this clause.
 *
 * ─── Termination contract (D13) ────────────────────────────────────
 *
 *   `iii_lex_next` runs in O(byte) amortised time per call.  For any
 *   byte sequence of length L with Σ string_lens = S, repeated calls
 *   reach `III_TOK_EOF` in finite time bounded by 2·(L + S) + 1
 *   inclusive of recovery advances after errors.
 *
 * ─── Recovery contract (D10) ───────────────────────────────────────
 *
 *   When `iii_lex_next` returns -1, the cursor advances by exactly
 *   one byte (skipping the offending byte) and the error is appended
 *   to the per-state error log accessible via `iii_lex_error_at`.
 *   The caller may continue to call `iii_lex_next`; lexing resumes
 *   at the new position.  EOF is reached by repeated calls.  This is
 *   how a single source file produces all its lex diagnostics in one
 *   pass instead of stopping at the first error.
 *
 * ─── Fuzz invariants (D14) ─────────────────────────────────────────
 *
 *   For any sequence of source bytes with `source_len ≤ 2^32`, no
 *   call into this module shall: panic; read out of bounds of
 *   `source_buf[0..source_len]`; loop infinitely; allocate without
 *   either succeeding or returning `III_LEX_E_OOM`; or produce a
 *   token whose `start_byte > end_byte` or whose `end_byte >
 *   source_len + 1`.  This is the lex.h-local statement of the III
 *   substrate's safety claim.
 *
 * ─── MHASH vs HEX_LITERAL boundary rule (D11) ──────────────────────
 *
 *   `0x` followed by exactly 64 hex digits → `III_TOK_MHASH_LITERAL`.
 *   `0x` followed by 1..16 hex digits → `III_TOK_HEX_LITERAL` (value
 *   in `int_value`).  `0x` followed by 17..63 or 65+ hex digits →
 *   `III_TOK_INVALID` with error `III_LEX_E_OVERLONG_INT` (17..63) or
 *   `III_LEX_E_OVERLONG_MHASH` (65+).  `0x` followed by 0 hex digits
 *   → error `III_LEX_E_BAD_HEX_PREFIX`.  The 64-digit case wins
 *   precedence over OVERLONG_INT at the boundary.
 *
 * ─── Glyph-literal payload reservation (D17) ───────────────────────
 *
 *   Future glyph literals (e.g. `g"…"` → 192-byte Glyph V3) follow
 *   the same arena convention as string literals: the token holds a
 *   `(payload_ptr, payload_len)` pair into the lex-state arena.
 *   No new fields are added to `iii_token_t` for this; the existing
 *   `string_payload` / `string_len` slots are reused with the kind
 *   discriminator selecting interpretation.  See D16 string-kind
 *   discriminators.
 *
 * ─── Hexad-literal composition (D18) ───────────────────────────────
 *
 *   Hexad source-text `(t,t,t,t,t,t)` is NOT a single lexical token.
 *   The lexer emits LPAREN, six trit/digit/keyword tokens with
 *   commas, and RPAREN; the parser composes them into a hexad node.
 *   This is deliberate: it lets hexads share grammar with tuples and
 *   pattern-matching syntax.
 *
 * ─── Incremental re-lex (D20) ──────────────────────────────────────
 *
 *   Stage-0 does not provide `iii_lex_invalidate_range`.  Editor /
 *   LSP integrations that need range invalidation must re-create the
 *   lex state over the full source.  Stage-1 self-host may add an
 *   incremental API if the operator prefers it; the Stage-0 contract
 *   is full-source re-lex on every edit.
 */

#ifndef III_BOOT_LEX_H
#define III_BOOT_LEX_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ─── Token kinds ────────────────────────────────────────────────── */

/* STABILITY: integer values of these enumerators are referenced by
 * downstream tables (kind-name, parser-dispatch) and persisted in
 * test goldens and in serialized AST snapshots.  When adding new
 * token kinds, append IMMEDIATELY before `III_TOK_KIND_COUNT`.  Do
 * not reorder existing entries; do not remove entries; reuse of an
 * old integer for a new meaning is forbidden.  Stage-2 reproducibility
 * (D24) and the parser's per-kind dispatch tables (parse.c) both
 * depend on this discipline. */
typedef enum {
    /* Sentinels */
    III_TOK_INVALID = 0,
    III_TOK_EOF,

    /* Trivia (significant) */
    III_TOK_NEWLINE,           /* '\n' or '\r\n'; significant in some grammar productions */
    III_TOK_DOC_COMMENT,       /* line ('///') or block doc-comment; see leading_doc_comment_byte */

    /* Literals — base forms */
    III_TOK_IDENTIFIER,
    III_TOK_INT_LITERAL,
    III_TOK_HEX_LITERAL,
    III_TOK_MHASH_LITERAL,     /* 0x followed by exactly 64 hex digits */
    III_TOK_STRING_LITERAL,    /* "…" — UTF-8 opaque, escapes resolved */

    /* Literals — string discriminators (D16) */
    III_TOK_STRING_BYTE,       /* b"…" — payload is a byte array */
    III_TOK_STRING_RAW,        /* r"…" — payload is bytes verbatim, no escapes */
    III_TOK_STRING_HEX,        /* h"deadbeef" — payload is decoded bytes */

    /* Reserved words — module / decl */
    III_TOK_KW_MODULE,
    III_TOK_KW_USE,
    III_TOK_KW_AS,
    III_TOK_KW_CYCLE,
    III_TOK_KW_FN,
    III_TOK_KW_TYPE,
    III_TOK_KW_CONST,
    III_TOK_KW_EXTERN,
    III_TOK_KW_MOBIUS_CANDIDATE,
    III_TOK_KW_SCHEMA,
    III_TOK_KW_OBSERVATORY,
    III_TOK_KW_SEALED_CALL,
    III_TOK_KW_FROM,

    /* Reserved words — stmt */
    III_TOK_KW_LET,
    III_TOK_KW_MUT,
    III_TOK_KW_WAVEFRONT,
    III_TOK_KW_SANCTUM_ENTER,
    III_TOK_KW_METAL,
    III_TOK_KW_FOR,
    III_TOK_KW_IN,
    III_TOK_KW_WHERE,
    III_TOK_KW_MATCH,
    III_TOK_KW_IF,
    III_TOK_KW_RETURN,

    /* Reserved words — wavefront */
    III_TOK_KW_UNTIL,
    III_TOK_KW_QUIESCENT,
    III_TOK_KW_ON_ROLLBACK,

    /* Reserved words — cycle body */
    III_TOK_KW_FORWARD,
    III_TOK_KW_COMPROMISE,

    /* Reserved words — boolean */
    III_TOK_KW_TRUE,
    III_TOK_KW_FALSE,

    /* Reserved words — operators (textual) */
    III_TOK_KW_AND,
    III_TOK_KW_OR,
    III_TOK_KW_COMPOSE,

    /* Reserved words — special idents in modifier args */
    III_TOK_KW_CURRENT,
    III_TOK_KW_BUILD_TIME,
    III_TOK_KW_ANY,

    /* Trit-literal words.  The source-text keyword is `INVALID`; this
     * enumerator is named `..._TRIT_INVALID` (D23 rename) so it never
     * lexically competes with the `III_TOK_INVALID` sentinel. */
    III_TOK_KW_NEG,
    III_TOK_KW_ZERO,
    III_TOK_KW_POS,
    III_TOK_KW_TRIT_INVALID,   /* spelled INVALID in source */

    /* Modifier keywords (D4).  Emitted only immediately after an `@`
     * token, in place of the identifier the parser would otherwise
     * have to strcmp.  The source text is the lowercase modifier
     * name (e.g. `ring`, `tier`, `safety`).  Modifier names not in
     * this set fall back to III_TOK_IDENTIFIER. */
    III_TOK_MOD_RING,
    III_TOK_MOD_TIER,
    III_TOK_MOD_SAFETY,
    III_TOK_MOD_HEXAD,
    III_TOK_MOD_TRACK,
    III_TOK_MOD_CHRONOS,
    III_TOK_MOD_CAP,
    III_TOK_MOD_EPOCH,
    III_TOK_MOD_PLAN_ANCHOR,
    III_TOK_MOD_CLOSURE,
    III_TOK_MOD_VERSION,
    III_TOK_MOD_ABI,
    III_TOK_MOD_PURE,
    III_TOK_MOD_IRREVERSIBLE,
    III_TOK_MOD_SANCTUM_ONLY,
    III_TOK_MOD_SEAL_ID,

    /* Punctuation */
    III_TOK_LPAREN,            /* ( */
    III_TOK_RPAREN,            /* ) */
    III_TOK_LBRACE,            /* { */
    III_TOK_RBRACE,            /* } */
    III_TOK_LBRACKET,          /* [ */
    III_TOK_RBRACKET,          /* ] */
    III_TOK_COMMA,             /* , */
    III_TOK_SEMI,              /* ; */
    III_TOK_COLON,             /* : */
    III_TOK_DCOLON,            /* :: */
    III_TOK_DOT,               /* . */
    III_TOK_AT,                /* @ — introduces modifier */
    III_TOK_PIPE,              /* | — sanctum_enter |frame|, also binary-or */
    III_TOK_UNDERSCORE,        /* _ — wildcard pattern */
    III_TOK_ARROW,             /* -> */
    III_TOK_FAT_ARROW,         /* => */

    /* Operators */
    III_TOK_OP_PLUS,           /* + */
    III_TOK_OP_MINUS,          /* - */
    III_TOK_OP_STAR,           /* * */
    III_TOK_OP_SLASH,          /* / */
    III_TOK_OP_PERCENT,        /* % */
    III_TOK_OP_AMP,            /* & */
    III_TOK_OP_CARET,          /* ^ */
    III_TOK_OP_TILDE,          /* ~ */
    III_TOK_OP_BANG,           /* ! */
    III_TOK_OP_SHL,            /* << */
    III_TOK_OP_SHR,            /* >> */
    III_TOK_OP_EQ,             /* == */
    III_TOK_OP_NEQ,            /* != */
    III_TOK_OP_LT,             /* < */
    III_TOK_OP_LE,             /* <= */
    III_TOK_OP_GT,             /* > */
    III_TOK_OP_GE,             /* >= */
    III_TOK_OP_ASSIGN,         /* = */
    III_TOK_OP_COLON_EQ,       /* := (MNEME-style reduction assignment) */

    /* Phase-B grammar additions (F1-Fn).  STABILITY: append-only,
     * before KIND_COUNT.  Numeric values are persisted in goldens.
     * Note: III_TOK_KW_AS is NOT redeclared here because the original
     * stable block above already includes it (line 163). */
    III_TOK_KW_ELSE,           /* else (F1) */
    III_TOK_KW_WHILE,          /* while (F2) */
    III_TOK_OP_DOTDOT,         /* .. (F3, range) */
    III_TOK_KW_SIZEOF,         /* sizeof (F5) */
    III_TOK_KW_VAR,            /* var (F9, mutable global) */
    III_TOK_KW_STRUCT,         /* struct (F8) */
    III_TOK_KW_LOOP,           /* loop (iiis-2 — unbounded loop) */
    III_TOK_KW_BREAK,          /* break (iiis-2 — exit innermost loop) */
    III_TOK_KW_CONTINUE,       /* continue (iiis-2 — restart innermost loop) */

    /* Lattice-plan modifiers (Phase 2, append-only beyond III_TOK_MOD_SEAL_ID).
     * STABILITY: integer values are persisted in goldens; never reorder. */
    III_TOK_MOD_CRYSTAL,                  /* @crystal                  (Step 0002) */
    III_TOK_MOD_DYNAMIC,                  /* @dynamic(ripple=...)      (Step 0003) */
    III_TOK_MOD_SEALED,                   /* @sealed(slot,provenance)  (Step 0004) */
    III_TOK_MOD_LINEAR,                   /* @linear                   (Step 0005) */
    III_TOK_MOD_BOUNDED,                  /* @bounded(min,max)         (Step 0006) */
    III_TOK_MOD_VARIANT,                  /* @variant                  (Step 0007) */
    III_TOK_MOD_K,                        /* @k(value)                 (Step 0008) */
    III_TOK_MOD_PROVENANCE,               /* @provenance(mode)         (Step 0009) */
    III_TOK_MOD_CONSTANT_TIME,            /* @constant_time            (Step 0010) */
    III_TOK_MOD_SIDE_CHANNEL_RESISTANT,   /* @side_channel_resistant   (Step 0011) */
    III_TOK_MOD_DYNAMIC_IMPACT,           /* @dynamic_impact(perf,ux)  (Step 0012) */
    III_TOK_MOD_PROVENANCE_LINKED_ERROR,  /* @provenance_linked_error  (Step 0013) */
    III_TOK_MOD_ARENA_RESET_SAFE,         /* @arena_reset_safe(...)    (Step 0014) */
    III_TOK_MOD_CRYSTAL_SELF_ATTEST,      /* @crystal_self_attest      (Step 0015) */
    III_TOK_MOD_STRICT_LENGTH,            /* @strict_length            (Step 0028) */

    /* RITCHIE Stage 3.5: AT&T immediate-prefix '$', required for metal{}
     * inline-asm blocks (e.g. `vprold $16, ...`).  Append-only (value 128),
     * so all prior kind values persist unchanged in goldens. */
    III_TOK_DOLLAR,                       /* $  (asm immediate prefix) */

    /* Sentinel — must be last.  See STABILITY note above. */
    III_TOK_KIND_COUNT
} iii_token_kind_t;

/* ─── Integer-literal type-suffix codes (D15) ────────────────────── */

/* Stable values; same append-only discipline as the token kind enum. */
typedef enum {
    III_INT_SUFFIX_NONE = 0,
    III_INT_SUFFIX_I8,
    III_INT_SUFFIX_I16,
    III_INT_SUFFIX_I32,
    III_INT_SUFFIX_I64,
    III_INT_SUFFIX_U8,
    III_INT_SUFFIX_U16,
    III_INT_SUFFIX_U32,
    III_INT_SUFFIX_U64,
    III_INT_SUFFIX_USIZE,
    III_INT_SUFFIX_ISIZE,
    III_INT_SUFFIX_COUNT
} iii_int_suffix_t;

/* ─── Token record ───────────────────────────────────────────────── */

/* All offsets are byte offsets into the source buffer (including trivia).
 * `line` is 1-based; `col` is 1-based byte column at the token's start
 * (counting bytes from the most recent newline).
 *
 * The raw text of the token is `source_buf[start_byte .. end_byte)`.
 * The lexer does NOT copy the text; the caller must keep `source_buf`
 * alive for the lifetime of any token it consults — UNLESS the lex
 * state has been sealed via `iii_lex_seal`, after which payloads
 * still in scope live in the heap block returned by seal.
 *
 * Logical position fields (D8) decouple the token from its physical
 * source location — useful when III source is generated by a tool.
 * `logical_path == NULL` means "same as the lex state's physical
 * source_path, with line==line and col==col"; otherwise the
 * generator-supplied logical position should be reported in errors.
 */
typedef struct {
    iii_token_kind_t   kind;
    uint32_t           start_byte;    /* inclusive */
    uint32_t           end_byte;      /* exclusive */
    uint32_t           line;          /* 1-based physical */
    uint32_t           col;           /* 1-based physical byte col */

    /* Logical position remap (D8).  See iii_lex_set_logical_position. */
    uint32_t           logical_line;  /* 0 = same as physical */
    uint32_t           logical_col;   /* 0 = same as physical */
    const char        *logical_path;  /* NULL = same as physical */

    /* Pre-decoded payloads for literal tokens. */
    uint64_t           int_value;     /* INT/HEX */
    iii_int_suffix_t   int_suffix;    /* D15 — see iii_int_suffix_t */
    uint8_t            mhash[32];     /* MHASH; zero for others */
    uint32_t           string_len;    /* STRING* — bytes after escape decode */
    const uint8_t     *string_payload;/* in lex-state arena; valid until destroy/seal */

    /* Interned identifier ID (D3).  Non-zero iff kind == IDENTIFIER
     * (or one of the modifier keywords that fell back to identifier);
     * stable across the lex-state lifetime; caller can use it as a
     * symbol-table key without rehashing the source bytes. */
    uint32_t           interned_id;

    /* Doc-comment attached to this token (D19).  UINT32_MAX = none.
     * Otherwise this is the byte offset of the doc-comment token's
     * `start_byte`.  The doc-comment body's raw text is
     * source_buf[byte..end_byte_of_that_comment); the operator can
     * fetch it via iii_lex_token_at_byte. */
    uint32_t           leading_doc_comment_byte;
} iii_token_t;

#define III_TOK_NO_DOC_COMMENT 0xFFFFFFFFu

/* ─── Lexer state (opaque to caller) ─────────────────────────────── */

struct iii_lex_state;
typedef struct iii_lex_state iii_lex_state_t;

/* Error info attached to a malformed token or unexpected byte. */
typedef struct {
    int                code;          /* one of III_LEX_E_*; III_LEX_OK = no error */
    uint32_t           byte;          /* offset of offending byte */
    uint32_t           line;
    uint32_t           col;
    const char        *message;       /* static string in .rdata */
} iii_lex_error_t;

/* Error codes.  Stable; append-only — see STABILITY note for token
 * kinds.  Stage-0 downstream code references these by name. */
#define III_LEX_OK                       0
#define III_LEX_E_UNTERMINATED_STRING    1
#define III_LEX_E_UNTERMINATED_BLOCK_CMT 2
#define III_LEX_E_BAD_HEX_DIGIT          3
#define III_LEX_E_BAD_ESCAPE             4
#define III_LEX_E_INVALID_BYTE           5
#define III_LEX_E_OVERLONG_INT           6   /* hex 17..63 digits, or decimal > 2^64-1 */
#define III_LEX_E_OVERLONG_MHASH         7   /* > 64 hex digits after 0x */
#define III_LEX_E_TRUNCATED_MHASH        8   /* reserved; current lexer reports OVERLONG_INT in this case */
#define III_LEX_E_OOM                    9   /* arena allocation failed */
#define III_LEX_E_NULL_ARG              10
#define III_LEX_E_BAD_HEX_PREFIX        11   /* 0x not followed by hex */
#define III_LEX_E_BAD_INT_SUFFIX        12   /* unknown integer suffix (D15) */
#define III_LEX_E_BAD_STRING_PREFIX     13   /* unknown string prefix (D16) */
#define III_LEX_E_BAD_HEX_STRING        14   /* h"…" with non-hex or odd-length payload */
#define III_LEX_E_DUPLICATE_KEYWORD     15   /* iii_lex_register_keyword on existing name */
#define III_LEX_E_KEYWORD_TABLE_FULL    16   /* register_keyword overflow */
#define III_LEX_E_SEALED                17   /* operation on a sealed state */

/* ─── Lifecycle ──────────────────────────────────────────────────── */

/* Allocate and initialise a new lexer state over the given source.
 * `source_buf` must remain valid for the lifetime of the state (or
 * until `iii_lex_seal` is called).  The source's length is
 * `source_len` bytes; no NUL terminator is required.
 * `source_path` is a static or caller-owned string used in error
 * messages (may be NULL).  The lexer does not copy `source_path`; it
 * must outlive the state.
 *
 * Returns NULL on allocation failure. */
iii_lex_state_t *iii_lex_create(const uint8_t *source_buf,
                                 size_t         source_len,
                                 const char    *source_path);

/* Free the lexer state, its arena, line-table, error log, intern
 * table, token history, and any peek-cache.  After this call, any
 * `string_payload` pointer obtained from a token of this lexer is
 * invalid UNLESS the state was sealed first via iii_lex_seal — the
 * sealed payload block has independent lifetime.  The caller's
 * source buffer is NOT freed (the caller owns it). */
void iii_lex_destroy(iii_lex_state_t *st);

/* ─── Token iteration ────────────────────────────────────────────── */

/* Fetch the next token.  Returns:
 *    1 on success (out_token populated; not EOF).
 *    0 on clean EOF (out_token kind = III_TOK_EOF; not an error).
 *   -1 on lexer error (out_token kind = III_TOK_INVALID; consult
 *      iii_lex_error_at(N-1) for the just-recorded error).  Per the
 *      recovery contract, the cursor advances past the offending
 *      byte; subsequent calls resume scanning.
 *
 * Inline trivia (whitespace, normal comments) is silently skipped.
 * Newlines yield III_TOK_NEWLINE tokens.  Doc-comments yield
 * III_TOK_DOC_COMMENT tokens AND set the `leading_doc_comment_byte`
 * field of the next non-trivia token to the doc-comment's
 * start_byte (D19).
 *
 * After EOF, subsequent calls continue to return 0 with the EOF
 * token (idempotent at end of stream). */
int iii_lex_next(iii_lex_state_t *st, iii_token_t *out_token);

/* Peek the next token without consuming it.  Same return semantics
 * as iii_lex_next; on success, `out_token` is populated and the
 * next call to iii_lex_next yields the same token.  The peek is
 * cached inside the state until consumed. */
int iii_lex_peek(iii_lex_state_t *st, iii_token_t *out_token);

/* ─── Error log (D9 + D10) ───────────────────────────────────────── */

/* Number of errors recorded since iii_lex_create.  Per D10, every
 * call to iii_lex_next that returns -1 appends one entry. */
size_t iii_lex_error_count(const iii_lex_state_t *st);

/* Read the i-th error (0-based; valid range [0, iii_lex_error_count)).
 * Returns 1 on success, 0 if `i` is out of range. */
int iii_lex_error_at(const iii_lex_state_t *st, size_t i,
                      iii_lex_error_t *out_err);

/* Convenience: most-recent-error read.  Returns the entry at index
 * `count - 1` if any; otherwise an OK record. */
void iii_lex_error_info(const iii_lex_state_t *st,
                         iii_lex_error_t *out_err);

/* ─── Names / accessors ──────────────────────────────────────────── */

/* Translate a token kind to a stable .rdata string name (for error
 * messages, debug dumps).  Returns "<unknown>" if k is out of range. */
const char *iii_token_kind_name(iii_token_kind_t k);

/* Returns the source path passed to iii_lex_create, or NULL if none. */
const char *iii_lex_source_path(const iii_lex_state_t *st);

/* Return a pointer into the source buffer for the token's raw text.
 * The pointer is valid as long as the source buffer outlives the
 * token's reads.  The text length is `tok->end_byte - tok->start_byte`.
 * For string-kind tokens the raw text includes the surrounding
 * quotes (and prefix byte for b/r/h forms); the decoded payload is
 * in `tok->string_payload[0 .. tok->string_len)`. */
const uint8_t *iii_token_raw(const iii_lex_state_t *st,
                              const iii_token_t *tok);

/* Convenience: equality test of a token's raw text against a static
 * NUL-terminated ASCII string. */
bool iii_token_raw_eq(const iii_lex_state_t *st,
                       const iii_token_t *tok,
                       const char *literal);

/* FNV-1a-64 hash of the token's raw bytes.  Matches MNEME's
 * convention (CONSTITUTIONAL/mneme/grammar-table.h::xii_mneme_fnv1a_64).
 * Note: for IDENTIFIER tokens, prefer the precomputed
 * `tok->interned_id` over rehashing this on every parser visit. */
uint64_t iii_token_fnv1a_64(const iii_lex_state_t *st,
                             const iii_token_t *tok);

/* ─── Position helpers (D5, D6, D7, D8) ──────────────────────────── */

/* Reverse byte → (line, col) lookup (D5).  The lex state maintains
 * a line-start table built incrementally as iii_lex_next traverses
 * newlines; this function does an O(log N) binary search over it
 * (N = number of physical lines scanned so far).  Returns 1 on
 * success and writes `*out_line` and `*out_col` (1-based, byte col);
 * returns 0 if `byte` is past the end of source already scanned.
 * If the caller needs locations for a byte not yet scanned, it must
 * advance the lexer first (e.g., by exhausting iii_lex_next). */
int iii_lex_locate(const iii_lex_state_t *st, uint32_t byte,
                    uint32_t *out_line, uint32_t *out_col);

/* Span union (D6): combine two tokens' byte spans into the smallest
 * span covering both.  Useful for diagnostics that point at a
 * grammatical construct spanning multiple tokens. */
void iii_token_span_union(const iii_token_t *a, const iii_token_t *b,
                           uint32_t *out_start, uint32_t *out_end);

/* Reverse byte → token index (D7).  The lex state retains a history
 * of every emitted non-trivia token (excluding newlines); this
 * function binary-searches it.  Writes the 0-based history index
 * of the token whose [start_byte, end_byte) contains `byte`.
 * Returns 1 on hit, 0 on miss (gap or past end-of-history). */
int iii_lex_token_at_byte(const iii_lex_state_t *st, uint32_t byte,
                           size_t *out_token_idx);

/* Read the i-th historical token (0-based; valid range
 * [0, iii_lex_token_count)).  Returns 1 on success.  This is how
 * an editor / explainer looks up "the doc-comment associated with
 * the token at byte X" once it has the index from
 * iii_lex_token_at_byte. */
int iii_lex_token_history_at(const iii_lex_state_t *st, size_t i,
                              iii_token_t *out_token);

/* Number of tokens recorded in history. */
size_t iii_lex_token_count(const iii_lex_state_t *st);

/* Set logical position (D8).  Subsequent tokens emitted by
 * iii_lex_next will copy the current logical (line, col, path) into
 * the corresponding fields.  Pass `path = NULL`, `line = 0`,
 * `col = 0` to clear and revert to physical-only positions.  This
 * is how generated III source carries provenance back to its
 * generator's input — the generator inserts `iii_lex_set_logical_position`
 * calls between regions of generated source. */
void iii_lex_set_logical_position(iii_lex_state_t *st,
                                    const char *logical_path,
                                    uint32_t logical_line,
                                    uint32_t logical_col);

/* ─── Keyword and modifier extension (D2 + D4) ───────────────────── */

/* Register a new keyword at runtime (D2).  Used by S10 (Catalyst-
 * promoted grammar extensions) so the lexer recognises operator-
 * declared cycle names as keywords without recompiling the lexer.
 * The `name` bytes are copied into the lex state's arena and live
 * for the state's lifetime.  `kind` MUST be a non-keyword token
 * kind reserved for runtime use OR a value
 * `>= III_TOK_KIND_COUNT` (treated as opaque user kind by the lexer).
 *
 * Returns III_LEX_OK on success.  Returns III_LEX_E_DUPLICATE_KEYWORD
 * if `name` already maps to a kind, III_LEX_E_KEYWORD_TABLE_FULL if
 * the runtime keyword table is exhausted (capacity defined in the
 * implementation), III_LEX_E_OOM, III_LEX_E_NULL_ARG. */
int iii_lex_register_keyword(iii_lex_state_t *st,
                              const char *name, size_t name_len,
                              iii_token_kind_t kind);

/* ─── D1 — Tokens-as-Reductions: content-address ─────────────────── */

/* Compute the content-address of one token.  The hash domain is the
 * canonical byte serialisation
 *   (kind || start_byte || end_byte || line || col || logical_line ||
 *    logical_col || int_value || int_suffix || string_len ||
 *    mhash || (string_payload[0..string_len] if any) ||
 *    interned_id || leading_doc_comment_byte)
 * laid out little-endian, no padding.  The hash is SHA-256 (FIPS
 * 180-4).  Two semantically identical tokens — same kind, same
 * payload, same logical position — produce identical mhashes.
 *
 * This is the primitive that makes the lexer participate in the
 * substrate's witness chain: every parsed term traces back to a
 * content-addressed sequence of these token mhashes. */
void iii_token_mhash(const iii_lex_state_t *st, const iii_token_t *tok,
                      uint8_t out_mhash[32]);

/* Streaming content-hash of every token emitted since iii_lex_create
 * (in iii_lex_next order).  Updated incrementally on each emission.
 * Calling this is O(1); it returns the current accumulated hash.
 * After the EOF token has been emitted, the returned mhash is the
 * canonical fingerprint of the token stream the parser sees and is
 * suitable for inclusion in the closure root. */
void iii_lex_stream_mhash(const iii_lex_state_t *st,
                           uint8_t out_mhash[32]);

/* ─── Arena introspection (D21) ──────────────────────────────────── */

/* Total bytes allocated to the lex-state arena (sum of chunk
 * capacities; not used bytes).  Diagnostic only — operator memory
 * audit. */
size_t iii_lex_arena_bytes(const iii_lex_state_t *st);

/* SHA-256 of the arena's used payload bytes, in chunk-allocation
 * order.  Composes with iii_lex_stream_mhash (D1) for full-state
 * witness coverage of a lex run. */
void iii_lex_arena_mhash(const iii_lex_state_t *st,
                          uint8_t out_mhash[32]);

/* ─── Lifecycle: seal (D22) ──────────────────────────────────────── */

/* Transfer arena ownership out of the lex state.  After this call:
 *   - the lex state is "sealed": further iii_lex_next / register_*
 *     calls return III_LEX_E_SEALED;
 *   - all `string_payload` pointers in tokens already emitted remain
 *     valid for the lifetime of `*out_owned_block`;
 *   - the caller is responsible for `free(*out_owned_block)` once it
 *     no longer needs the payloads.
 * The returned block contains the concatenated chunk bytes with
 * pointers in tokens already adjusted to point into it.  Returns
 * the byte size of `*out_owned_block`, or 0 on failure (e.g. OOM).
 *
 * This is the primitive that lets a long-lived AST outlive the
 * lex state without copying token payloads at every parser visit. */
size_t iii_lex_seal(iii_lex_state_t *st, void **out_owned_block);

#ifdef __cplusplus
}
#endif

#endif /* III_BOOT_LEX_H */
