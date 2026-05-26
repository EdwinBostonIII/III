/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\ast.h
 *
 * III Stage-0 Abstract Syntax Tree — public types.
 *
 * Purpose: data structure that the recursive-descent parser (parse.c)
 * builds from the token stream produced by the lexer (lex.c) and that
 * the semantic analyser (sema.c), inverse derivation (sid.c), proof
 * checker (proof.c), hexad checker (hexad_check.c), ACC algebra (acc.c),
 * ceiling membership (ceiling.c), witness allocator (witness_alloc.c),
 * and code generators (cg_r3.c, cg_r0.c, cg_rm1.c, cg_rm2.c) consume.
 *
 * Spec source: C:\CHARIOT\DOCS\TELOS-GRAMMAR.bnf (the grammar inherited
 *              from the LOGOS predecessor; III renames identifiers and
 *              carries the deepening clauses below).
 *
 * ─── Substrate-level discipline (this header is not a generic AST) ──
 *
 *   The III AST is a Merkle DAG of content-addressed nodes — not a
 *   tree of heap-arena cells.  The substrate's atom is a witnessed
 *   Reduction; the AST is the syntactic projection of that atom.
 *   Concretely:
 *
 *   A1 — Per-node mhash.  Every node carries a 32-byte SHA-256 over
 *        (kind || payload || child mhashes), stored in a per-pool
 *        side-table.  Two nodes are equal iff their mhashes match.
 *   A2 — Hash-consing.  iii_ast_intern_node deduplicates by mhash;
 *        two parser visits to the same expression yield the same
 *        node index.
 *   A3 — DAG, not tree.  After A2, a node is reachable from
 *        root_module via at least one path and may be reachable via
 *        many.  Child-list entries are references, not children.
 *   B1 — Positions side-table.  iii_src_pos_t no longer lives on the
 *        node; it lives in iii_ast_t.positions[], a linked-list-per-
 *        node structure.  Hash-consing dedups regardless of
 *        position; each occurrence appends to its node's chain.
 *   B2 — Multi-position diagnostics.  Naturally enabled by B1.
 *   C1 — III_AST_USER_NODE for runtime-registered kinds.  Catalyst-
 *        promoted constructors get a stable user_kind_id and live in
 *        the user pool; the standard kind enum stays append-only.
 *   D1 — Witness fields on iii_ast_t (parser_version_mhash,
 *        token_stream_mhash, source_mhash, grammar_mhash).  Together
 *        with root_module_mhash they constitute the AST's witness.
 *   E1 — iii_ast_checkpoint / iii_ast_rollback.  All arenas are
 *        monotonic; rollback truncates counts.  Required for
 *        wavefront semantics on the parser itself.
 *   F1 — Heap-allocated open-list handles.  Multiple lists can be
 *        open concurrently (no LIFO discipline).  iii_ast_list_begin
 *        / push / commit retained for back-compat with strict-LIFO
 *        sites.
 *   G1 — leading_doc_comment_node side-table on every node.  Set by
 *        the parser when a III_TOK_DOC_COMMENT precedes a node.
 *   H1 — Per-kind storage pools.  Index encoding: high 4 bits of
 *        node_index select pool (small / medium / large / user);
 *        low 28 bits select slot.  Pools are kind-segregated for
 *        traversal locality.  The Stage-0 implementation uses the
 *        master node struct in every pool; per-pool sized struct
 *        types (with type-punning unions) are a Stage-1 optimization
 *        whose seam is the pool dispatch in iii_ast_get.
 *   I1 — Zipper traversal.  iii_ast_zipper_t is a stateful, persistable
 *        cursor.  No callback indirection; no untyped ctx.  Required
 *        for future incremental sema and IDE integration.
 *   J1 — iii_ast_diff.  After A2, diff is a recursive walk that
 *        descends only into subtrees whose mhashes differ.
 *   K1 — III_AST_ERROR_NODE.  Sema treats it as Bottom; codegen
 *        rejects; dump renders specially.  Lets the parser plant
 *        typed error nodes and continue producing structure.
 *   L1 — First-class annotation tables.  iii_ast_annotate(ast, phase,
 *        node, blob).  Phase-keyed; deterministic order; serializes
 *        with the AST.
 *   M1 — binder_id side-table.  Every binder (LET, PARAM, MATCH_ARM
 *        pattern, SCHEMA_FIELD) gets a structurally-allocated id;
 *        every IDENT carries an optional resolved binder_id.
 *        Alpha-equivalent ASTs hash-cons to the same DAG.
 *   N1 — III_AST_EXPR_HOLE.  A typed hole `?` whose type is inferred
 *        from context.  Catalyst-fillable.
 *   O1 — III_AST_EXPR_PARALLEL.  A wavefront-eligible tuple at
 *        expression scope.  The tracing JIT consumes this directly.
 *   P1 — Discriminated position: physical { byte/line/col } or
 *        synthetic { source_node, pass_mhash, rationale }.
 *        Synthetic nodes carry their cause.
 *   Q1 — iii_ast_serialize / iii_ast_deserialize.  Canonical binary
 *        form, version-tagged, content-hashed.  Federation can ship
 *        parsed code without the source bytes.
 *   R1 — grammar_mhash on iii_ast_t.  Sema asserts compatibility
 *        before consuming.
 *   S1 — First-class metadata kinds.  ADR_DECL, CONFORMANCE_CLAIM_DECL,
 *        TEST_CASE_DECL, RATIONALE_DECL.  Operator-relevant artifacts
 *        live inside the AST, not adjacent to it.
 *   T1 — III_AST_OPERATOR_INTENT.  Operator commands compile to
 *        typed reductions in the same AST as code; commands and
 *        code share the witness chain.
 *   U1 — EXPR_TYPE / TYPE_OF.  Lift a type into term position; lower
 *        a term to its type position.  Curry-Howard at AST scope; the
 *        proof kernel does not need a parallel AST.
 *   V1 — Coroutine walk state.  iii_ast_walk_state_t is heap-resident,
 *        steppable one node at a time, persistable to disk, resumable
 *        across processes.
 *
 * Implementation discipline (per ADR-021 NIH + ADR-027):
 *   - Index-based: all node-to-node references are uint32_t indices
 *     into the typed pools (H1).  Pointers do not appear in payloads.
 *   - List arena: child-collection nodes reference a uint32_t[] arena
 *     via (offset, count) handles.  The arena grows by doubling.
 *   - String-payload table: parser-interned pointers into the lexer's
 *     arena; AST nodes reference entries by index.
 *   - Pure NIH: only stdlib used; no external AST library.
 *   - Reproducibility: two runs over identical sources produce
 *     identical AST containers byte-for-byte (modulo malloc pointers,
 *     which never appear in the AST payload).  The hash-cons table's
 *     iteration order is not exposed; iii_ast_serialize emits a stable
 *     ordering.
 */

#ifndef III_BOOT_AST_H
#define III_BOOT_AST_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ─── Node kinds ─────────────────────────────────────────────────── */

/* STABILITY: integer values of these enumerators are referenced by
 * downstream tables, persisted in serialised AST snapshots, and
 * encoded in the per-node mhash domain.  Append-only — see the
 * comment at the end. */
typedef enum {
    III_AST_NULL = 0,            /* reserved sentinel; node index 0 */

    /* Top-level structure */
    III_AST_MODULE,              /* file root */
    III_AST_USE,                 /* use directive */

    /* Top-level declarations */
    III_AST_CYCLE_DECL,
    III_AST_FN_DECL,
    III_AST_TYPE_DECL,
    III_AST_CONST_DECL,
    III_AST_EXTERN_DECL,
    III_AST_MOBIUS_CANDIDATE_DECL,
    III_AST_SCHEMA_DECL,
    III_AST_SCHEMA_FIELD,
    III_AST_SEALED_CALL_METHOD_DECL,

    /* Common decl substructure */
    III_AST_PARAM,
    III_AST_TYPE_PARAM,
    III_AST_MODIFIER,            /* @name(args...) */

    /* Type expressions */
    III_AST_TYPE_REF,
    III_AST_TYPE_PTR,
    III_AST_TYPE_ARRAY,
    III_AST_TYPE_TUPLE,
    III_AST_TYPE_FN,

    /* Statements */
    III_AST_STMT_LET,
    III_AST_STMT_WAVEFRONT,
    III_AST_STMT_SANCTUM_ENTER,
    III_AST_STMT_METAL,
    III_AST_STMT_FOR,
    III_AST_STMT_MATCH,
    III_AST_STMT_RETURN,
    III_AST_STMT_ASSIGN,
    III_AST_STMT_EXPR,

    /* Cycle body components */
    III_AST_FORWARD_BLOCK,
    III_AST_COMPROMISE_BLOCK,

    /* Match arms / patterns */
    III_AST_MATCH_ARM,
    III_AST_PAT_LITERAL,
    III_AST_PAT_IDENT,
    III_AST_PAT_HEXAD,
    III_AST_PAT_WILDCARD,
    III_AST_PAT_TUPLE,

    /* Expressions */
    III_AST_EXPR_INT,
    III_AST_EXPR_HEX,
    III_AST_EXPR_MHASH,
    III_AST_EXPR_STR,
    III_AST_EXPR_BOOL,
    III_AST_EXPR_TRIT,
    III_AST_EXPR_HEXAD,
    III_AST_EXPR_UNIT,
    III_AST_EXPR_IDENT,
    III_AST_EXPR_CALL,
    III_AST_EXPR_FIELD,
    III_AST_EXPR_INDEX,
    III_AST_EXPR_BINARY,
    III_AST_EXPR_UNARY,
    III_AST_EXPR_BLOCK,
    III_AST_EXPR_MATCH,
    III_AST_EXPR_PAREN,
    III_AST_EXPR_RAW_ASM,

    /* Modifier-name kinds (pre-resolved by parser when straightforward) */
    III_AST_RING_SET,
    III_AST_HEXAD_NAME,

    /* Argument record */
    III_AST_ARG,

    /* New: Curry-Howard AST kinds (U1) */
    III_AST_EXPR_TYPE,           /* lift a type into term position */
    III_AST_TYPE_OF,             /* lower a term to its type position */

    /* New: typed hole (N1) */
    III_AST_EXPR_HOLE,

    /* New: wavefront-eligible expression tuple (O1) */
    III_AST_EXPR_PARALLEL,

    /* New: typed error node — parser plants on recovery (K1) */
    III_AST_ERROR_NODE,

    /* New: first-class metadata declarations (S1) */
    III_AST_ADR_DECL,
    III_AST_CONFORMANCE_CLAIM_DECL,
    III_AST_TEST_CASE_DECL,
    III_AST_RATIONALE_DECL,

    /* New: operator commands as witnessed reductions (T1) */
    III_AST_OPERATOR_INTENT,

    /* New: runtime-registered constructor (C1) — Catalyst extension. */
    III_AST_USER_NODE,

    /* Phase-B grammar additions (Path A self-host).  STABILITY:
     * append-only, immediately before III_AST_USER_NODE would be
     * cleaner per H1 stability, but we must not insert into the
     * middle.  Append before KIND_COUNT instead. */
    III_AST_STMT_IF,             /* F1 — `if cond { … } else { … }` */
    III_AST_STMT_WHILE,          /* F2 — `while cond { … }` */
    III_AST_EXPR_RANGE,          /* F3 — `lo..hi` range expression */
    III_AST_EXPR_CAST,           /* F4 — `expr as T` */
    III_AST_EXPR_SIZEOF,         /* F5 — `sizeof T` */
    III_AST_VAR_DECL,            /* F9 — module-level mutable global */
    III_AST_STRUCT_DECL,         /* F8 — struct type declaration */
    III_AST_STMT_LOOP,           /* iiis-2 — `loop { body }` */
    III_AST_STMT_BREAK,          /* iiis-2 — `break` from innermost loop */
    III_AST_STMT_CONTINUE,       /* iiis-2 — `continue` to top of innermost loop */

    /* Sentinel — must be last.
     *
     * STABILITY: when adding new kinds, append IMMEDIATELY before
     * III_AST_KIND_COUNT.  Do not reorder; do not delete; do not
     * reuse an old integer for a new meaning.  The kind values are
     * referenced by downstream dispatch tables and embedded in
     * serialised ASTs and in per-node mhash inputs. */
    III_AST_KIND_COUNT
} iii_ast_kind_t;

/* ─── Binary / unary operator codes ──────────────────────────────── */

typedef enum {
    III_BIN_ADD = 1,
    III_BIN_SUB,
    III_BIN_MUL,
    III_BIN_DIV,
    III_BIN_MOD,
    III_BIN_AND,        /* bitwise & */
    III_BIN_OR,         /* bitwise | */
    III_BIN_XOR,        /* bitwise ^ */
    III_BIN_SHL,
    III_BIN_SHR,
    III_BIN_EQ,
    III_BIN_NEQ,
    III_BIN_LT,
    III_BIN_LE,
    III_BIN_GT,
    III_BIN_GE,
    III_BIN_LAND,       /* logical 'and' */
    III_BIN_LOR,        /* logical 'or' */
    III_BIN_IN,         /* 'in' */
    III_BIN_COMPOSE     /* 'compose' (cycle composition) */
} iii_binop_t;

typedef enum {
    III_UN_NEG = 1,     /* unary - */
    III_UN_NOT,         /* unary ! */
    III_UN_BNOT,        /* unary ~ */
    III_UN_DEREF,       /* F6 — unary *  (load via pointer) */
    III_UN_ADDR         /* F6 — unary &  (address of lvalue) */
} iii_unop_t;

/* ─── Trit codes ─────────────────────────────────────────────────── */

typedef enum {
    III_TRIT_AST_NEG = 0,
    III_TRIT_AST_ZERO = 1,
    III_TRIT_AST_POS = 2,
    III_TRIT_AST_INVALID = 3
} iii_ast_trit_t;

/* ─── Ring set bits (for @ring modifier) ─────────────────────────── */

#define III_RING_R3   0x01u
#define III_RING_R0   0x02u
#define III_RING_RM1  0x04u   /* R-1 */
#define III_RING_RM2  0x08u   /* R-2 */
#define III_RING_ANY  0x0Fu

/* ─── Pool encoding for node indices (H1) ────────────────────────── */

/* Top 4 bits of node_index select pool; low 28 bits select slot.
 * The all-zeros value 0 is reserved as the III_AST_NULL sentinel. */
#define III_AST_POOL_BITS    4u
#define III_AST_POOL_SHIFT   28u
#define III_AST_POOL_MASK    0xF0000000u
#define III_AST_SLOT_MASK    0x0FFFFFFFu

#define III_AST_POOL_NULL    0u   /* sentinel pool — only slot 0 (=NULL) */
#define III_AST_POOL_SMALL   1u   /* low-arity payloads */
#define III_AST_POOL_MEDIUM  2u   /* common expressions / patterns / args */
#define III_AST_POOL_LARGE   3u   /* declarations / blocks / metadata */
#define III_AST_POOL_USER    4u   /* C1: runtime-registered kinds */

#define III_AST_NODE_MAKE(pool, slot) \
    (((uint32_t)(pool) << III_AST_POOL_SHIFT) | ((uint32_t)(slot) & III_AST_SLOT_MASK))
#define III_AST_NODE_POOL(idx)   (((idx) >> III_AST_POOL_SHIFT) & 0xFu)
#define III_AST_NODE_SLOT(idx)   ((idx) & III_AST_SLOT_MASK)

/* ─── List handle (offset, count) into the list arena ────────────── */

typedef struct {
    uint32_t offset;   /* 0 == empty list */
    uint32_t count;
} iii_ast_list_t;

/* ─── Source-text reference (offset, length) ─────────────────────── */

typedef struct {
    uint32_t offset;
    uint32_t length;
} iii_src_text_t;

/* ─── Source position (used at alloc time; stored in side-table) ─── */

/* Plain physical position used by callers of iii_ast_alloc_node. */
typedef struct {
    uint32_t start_byte;
    uint32_t end_byte;
    uint32_t line;
    uint32_t col;
} iii_src_pos_t;

/* ─── Discriminated AST position (P1) ────────────────────────────── */

typedef enum {
    III_POS_PHYSICAL = 0,
    III_POS_SYNTHETIC = 1
} iii_pos_kind_t;

typedef struct {
    iii_pos_kind_t kind;
    union {
        struct {
            uint32_t start_byte;
            uint32_t end_byte;
            uint32_t line;
            uint32_t col;
        } physical;
        struct {
            uint32_t source_node_index;   /* the node this was synthesised from */
            uint8_t  pass_mhash[32];      /* the synthesising pass's identity */
            uint32_t rationale_str_idx;   /* string_payload index; 0 = none */
        } synthetic;
    } u;
} iii_ast_position_t;

/* ─── Per-kind payloads ──────────────────────────────────────────── */

/* All payloads are flat structs.  References are list-handles or
 * AST node indices (uint32_t).  Two semantically equal payloads
 * MUST serialise identically — the per-node mhash is computed over
 * a canonical byte representation. */

typedef struct {
    iii_src_text_t   name;
    iii_ast_list_t   modifiers;
    iii_ast_list_t   uses;
    iii_ast_list_t   decls;
} iii_module_payload_t;

typedef struct {
    iii_src_text_t   qualified_name;
    uint32_t         closure_mhash_node;
    iii_src_text_t   alias;
} iii_use_payload_t;

typedef struct {
    iii_src_text_t   name;
    iii_ast_list_t   params;
    uint32_t         return_type;
    iii_ast_list_t   modifiers;
    uint32_t         forward_block;
    uint32_t         compromise_block;
} iii_cycle_decl_payload_t;

typedef struct {
    iii_src_text_t   name;
    iii_ast_list_t   params;
    uint32_t         return_type;
    iii_ast_list_t   modifiers;
    uint32_t         body_block;
    iii_ast_list_t   type_params;   /* V1 Stage 7.1: generic-fn `<T[,U]>` for @specialize; empty for ordinary fns (node-offset 40) */
} iii_fn_decl_payload_t;

typedef struct {
    iii_src_text_t   name;
    iii_ast_list_t   type_params;
    uint32_t         rhs_type;
    iii_ast_list_t   modifiers;
} iii_type_decl_payload_t;

typedef struct {
    iii_src_text_t   name;
    uint32_t         type_node;
    uint32_t         value_expr;
} iii_const_decl_payload_t;

typedef enum {
    III_ABI_C_MSVC_X64 = 1,
    III_ABI_C_SYSV_X64,
    III_ABI_VMRUN_TRAMPOLINE,
    III_ABI_MAGIC_MSR,
    III_ABI_IOCTL
} iii_abi_kind_t;

typedef struct {
    iii_abi_kind_t   abi;
    iii_src_text_t   name;
    iii_ast_list_t   params;
    uint32_t         return_type;
    uint32_t         source_path_str_idx;
} iii_extern_decl_payload_t;

typedef struct {
    iii_src_text_t   name;
    uint32_t         in_type;
    uint32_t         out_type;
    iii_ast_list_t   modifiers;
    uint32_t         forward_block;
} iii_mobius_candidate_payload_t;

typedef struct {
    iii_src_text_t   name;
    iii_ast_list_t   fields;
} iii_schema_decl_payload_t;

typedef enum {
    III_SCH_F_ACCUMULATOR = 1,
    III_SCH_F_THRESHOLD,
    III_SCH_F_SAMPLE_SOURCE,
    III_SCH_F_MAX_RECORDS,
    III_SCH_F_PLAN_ANCHOR
} iii_schema_field_kind_t;

typedef struct {
    iii_schema_field_kind_t   field_kind;
    iii_src_text_t            spec_name;
    iii_ast_list_t            args;
    uint32_t                  expr;
    uint32_t                  int_value;
} iii_schema_field_payload_t;

typedef struct {
    iii_src_text_t   name;
    iii_ast_list_t   params;
    uint32_t         return_type;
    uint32_t         seal_id;
    uint32_t         body_block;
} iii_sealed_call_method_payload_t;

typedef struct {
    iii_src_text_t   name;
    uint32_t         type_node;
} iii_param_payload_t;

typedef struct {
    iii_src_text_t   name;
    iii_src_text_t   kind;
} iii_type_param_payload_t;

typedef struct {
    iii_src_text_t   name;
    iii_ast_list_t   args;
    uint32_t         ring_mask;
    uint32_t         hexad_node;
    uint32_t         tier_kind;
    uint32_t         epoch_value;
} iii_modifier_payload_t;

typedef struct {
    iii_src_text_t   name;
    iii_ast_list_t   type_args;
    iii_ast_list_t   modifiers;
} iii_type_ref_payload_t;

typedef struct { uint32_t inner; iii_ast_list_t modifiers; } iii_type_ptr_payload_t;
typedef struct { uint32_t inner; uint64_t count; iii_ast_list_t modifiers; } iii_type_array_payload_t;
typedef struct { iii_ast_list_t components; iii_ast_list_t modifiers; } iii_type_tuple_payload_t;
typedef struct { iii_ast_list_t params; uint32_t return_type; iii_ast_list_t modifiers; } iii_type_fn_payload_t;

typedef struct {
    bool             mutable_;
    iii_src_text_t   name;
    uint32_t         type_node;
    uint32_t         value_expr;
} iii_stmt_let_payload_t;

typedef struct {
    iii_ast_list_t   modifiers;
    iii_ast_list_t   nodes;
    uint32_t         on_rollback_block;
} iii_stmt_wavefront_payload_t;

typedef struct {
    iii_src_text_t   frame_var;
    uint32_t         body_block;
} iii_stmt_sanctum_enter_payload_t;

typedef struct {
    uint32_t         ring_mask;
    uint32_t         raw_asm_str_idx;
    uint32_t         raw_asm_len;
} iii_stmt_metal_payload_t;

typedef struct {
    iii_src_text_t   var;
    uint32_t         iter_expr;
    uint32_t         where_expr;
    uint32_t         body_block;
} iii_stmt_for_payload_t;

typedef struct {
    uint32_t         scrutinee;
    iii_ast_list_t   arms;
} iii_stmt_match_payload_t;

typedef struct { uint32_t value_expr; } iii_stmt_return_payload_t;
typedef struct { uint32_t lvalue_expr; uint32_t value_expr; } iii_stmt_assign_payload_t;
typedef struct { uint32_t expr; } iii_stmt_expr_payload_t;

typedef struct { iii_ast_list_t stmts; } iii_forward_block_payload_t;
typedef enum {
    III_COMPROMISE_NOTE = 1,
    III_COMPROMISE_LOW,
    III_COMPROMISE_MEDIUM,
    III_COMPROMISE_HIGH,
    III_COMPROMISE_CRITICAL
} iii_compromise_severity_t;
typedef struct { iii_compromise_severity_t severity; } iii_compromise_block_payload_t;

typedef struct {
    uint32_t         pattern;
    uint32_t         guard_expr;
    uint32_t         body;
} iii_match_arm_payload_t;

typedef struct { uint32_t literal_node; } iii_pat_literal_payload_t;
typedef struct {
    iii_src_text_t   name;
    iii_ast_list_t   payload_pats;
} iii_pat_ident_payload_t;
typedef struct { iii_ast_trit_t trits[6]; } iii_pat_hexad_payload_t;
/* PAT_WILDCARD has no payload. */
typedef struct { iii_ast_list_t components; } iii_pat_tuple_payload_t;

typedef struct { uint64_t value; } iii_expr_int_payload_t;
typedef struct { uint64_t value; } iii_expr_hex_payload_t;
typedef struct { uint8_t mhash[32]; } iii_expr_mhash_payload_t;
typedef struct { uint32_t string_payload_idx; uint32_t string_len; } iii_expr_str_payload_t;
typedef struct { bool value; } iii_expr_bool_payload_t;
typedef struct { iii_ast_trit_t trit; } iii_expr_trit_payload_t;
typedef struct { iii_ast_trit_t trits[6]; } iii_expr_hexad_payload_t;
/* EXPR_UNIT has no payload. */
typedef struct { iii_src_text_t name; } iii_expr_ident_payload_t;
typedef struct { uint32_t callee; iii_ast_list_t args; } iii_expr_call_payload_t;
typedef struct { uint32_t object; iii_src_text_t field_name; } iii_expr_field_payload_t;
typedef struct { uint32_t object; uint32_t index_expr; } iii_expr_index_payload_t;
typedef struct { iii_binop_t op; uint32_t lhs; uint32_t rhs; } iii_expr_binary_payload_t;
typedef struct { iii_unop_t op; uint32_t operand; } iii_expr_unary_payload_t;
typedef struct { iii_ast_list_t stmts; } iii_expr_block_payload_t;
typedef struct { uint32_t scrutinee; iii_ast_list_t arms; } iii_expr_match_payload_t;
typedef struct { uint32_t inner; } iii_expr_paren_payload_t;
typedef struct { uint32_t raw_asm_str_idx; uint32_t raw_asm_len; } iii_expr_raw_asm_payload_t;
typedef struct { uint32_t mask; } iii_ring_set_payload_t;
typedef struct { iii_src_text_t name; } iii_hexad_name_payload_t;

typedef struct {
    iii_src_text_t   arg_name;
    uint32_t         value_expr;
} iii_arg_payload_t;

/* ─── New payloads ───────────────────────────────────────────────── */

/* U1: type-as-term and term-as-type. */
typedef struct { uint32_t type_node; } iii_expr_type_payload_t;
typedef struct { uint32_t term_node; } iii_type_of_payload_t;

/* N1: typed hole.  The hole is a placeholder for a yet-unknown term;
 * Catalyst-fillable.  type_hint is 0 for "any". */
typedef struct {
    uint32_t type_hint;        /* type-expr node id; 0 = no hint */
    uint32_t hole_id;          /* unique within the AST; sema/Catalyst keys */
} iii_expr_hole_payload_t;

/* O1: parallel expression — a wavefront-eligible tuple of branches
 * that the evaluator may execute concurrently.  Sema confirms purity
 * across branches; the JIT consumes the annotation. */
typedef struct {
    iii_ast_list_t branches;   /* expr nodes */
} iii_expr_parallel_payload_t;

/* K1: typed error node.  Sema treats it as Bottom.  Codegen rejects.
 * Dump renders specially.  recovered_kind_hint is the kind the parser
 * was trying to construct when it gave up. */
typedef struct {
    int32_t        error_code;
    uint32_t       source_span_start;
    uint32_t       source_span_end;
    iii_ast_kind_t recovered_kind_hint;
    uint32_t       message_str_idx;       /* string_payload index */
} iii_error_node_payload_t;

/* S1: ADR / conformance / test-case / rationale declarations.
 * First-class metadata that participates in the witness chain. */
typedef struct {
    iii_src_text_t adr_id;        /* "ADR-027" */
    iii_src_text_t title;
    uint32_t       body_block;    /* III_AST_EXPR_BLOCK with statements */
    iii_ast_list_t modifiers;
} iii_adr_decl_payload_t;

typedef struct {
    iii_src_text_t criterion_id;  /* "C-26" */
    iii_src_text_t claim_text;
    uint32_t       proof_node;    /* optional proof reference */
} iii_conformance_claim_payload_t;

typedef struct {
    iii_src_text_t test_name;
    uint32_t       precondition;
    uint32_t       action;
    uint32_t       postcondition;
} iii_test_case_payload_t;

typedef struct {
    iii_src_text_t for_what;       /* what this rationalises */
    uint32_t       text_str_idx;   /* string_payload */
} iii_rationale_payload_t;

/* T1: operator intent.  Maps an operator command to a typed reduction
 * inside the AST.  signature_mhash is the operator's per-command
 * signature. */
typedef struct {
    uint32_t intent_text_str_idx;
    uint8_t  signature_mhash[32];
    uint32_t witness_node_id;     /* optional pointer to a Witness term */
} iii_operator_intent_payload_t;

/* ─── Phase-B payloads (Path A self-host) ───────────────────────── */

/* F1 — `if cond { then_block } else { else_block }`.  else_block is 0
 * for plain `if` without else.  The condition is any expression that
 * evaluates to non-zero (true) / zero (false). */
typedef struct {
    uint32_t cond;          /* expr node */
    uint32_t then_block;    /* III_AST_EXPR_BLOCK */
    uint32_t else_block;    /* III_AST_EXPR_BLOCK or STMT_IF (else if), or 0 */
} iii_stmt_if_payload_t;

/* F2 — `while cond { body_block }`.  Loops until cond evaluates to 0. */
typedef struct {
    uint32_t cond;          /* expr node */
    uint32_t body_block;    /* III_AST_EXPR_BLOCK */
} iii_stmt_while_payload_t;

/* iiis-2 — `loop { body_block }`.  Unbounded loop; exits via `break`
 * or via a return statement inside.  No condition at top. */
typedef struct {
    uint32_t body_block;    /* III_AST_EXPR_BLOCK */
} iii_stmt_loop_payload_t;

/* iiis-2 — `break`/`continue`.  No payload data; they're bare keyword
 * statements that target the innermost enclosing loop.  Stage-2+ may
 * extend with `break 'label` for nested-loop control. */
typedef struct {
    uint32_t reserved;      /* placeholder for future label_id */
} iii_stmt_break_payload_t;
typedef struct {
    uint32_t reserved;
} iii_stmt_continue_payload_t;

/* F3 — `lo .. hi` range expression.  Half-open per Stage-1 convention
 * (lo inclusive, hi exclusive).  Used as iter_expr in STMT_FOR. */
typedef struct {
    uint32_t lo;            /* expr node */
    uint32_t hi;            /* expr node */
} iii_expr_range_payload_t;

/* F4 — `expr as T` cast.  For Stage-1 the cast is mostly a width-
 * narrowing or widening; on u64-uniform targets it is often a no-op.
 * Sema and codegen consult target_type to decide. */
typedef struct {
    uint32_t value_expr;
    uint32_t target_type;   /* type-expr node */
} iii_expr_cast_payload_t;

/* F5 — `sizeof T`.  Compile-time integer constant equal to the byte
 * size of T (8 for u64, 1 for u8, etc.).  Sema computes the value;
 * codegen emits a literal. */
typedef struct {
    uint32_t target_type;   /* type-expr node */
    uint64_t resolved;      /* set by sema (Stage-1 simple type table) */
} iii_expr_sizeof_payload_t;

/* F8 — `struct Name { f1: T1, f2: T2, ... }`.  Stage-1 layout: fields
 * are 8-byte aligned, packed in declaration order, total size is the
 * field count * 8 (every field is u64-width on Stage-1).  Stage-2+
 * adds proper alignment + width. */
typedef struct {
    iii_src_text_t name;
    iii_ast_list_t fields;  /* III_AST_PARAM nodes (reused; name+type) */
} iii_struct_decl_payload_t;

/* F9 — `var X: T = init`.  Module-level mutable global.  init is a
 * constant initializer; richer initializers Stage-2+. */
typedef struct {
    iii_src_text_t name;
    uint32_t type_node;
    uint32_t init_expr;     /* literal initializer; 0 = zero-initialise */
} iii_var_decl_payload_t;

/* C1: user-registered constructor.  user_kind_id is allocated by
 * iii_ast_register_user_kind.  children may name child nodes; opaque
 * payload carries grammar-specific data. */
typedef struct {
    uint32_t       user_kind_id;
    iii_ast_list_t children;
    uint32_t       payload_str_idx;
    uint32_t       payload_len;
} iii_user_node_payload_t;

/* ─── Single AST node: header + tagged union ─────────────────────── */

/* NOTE on H1: every pool stores the same iii_ast_node_t struct in
 * Stage 0.  The pool encoding (top 4 bits of node_index) is real;
 * the storage segregation gives traversal locality.  Per-pool sized
 * struct types (small ≤16 B, medium ≤32 B, large ≤64 B) is a
 * Stage-1 optimization that touches only the pool dispatch in
 * iii_ast_get; callers do not see the change. */
typedef struct iii_ast_node {
    iii_ast_kind_t kind;
    uint16_t       flags;        /* per-kind / synthetic / error flags */
    uint16_t       reserved;
    union {
        iii_module_payload_t              module_;
        iii_use_payload_t                 use_;
        iii_cycle_decl_payload_t          cycle_decl;
        iii_fn_decl_payload_t             fn_decl;
        iii_type_decl_payload_t           type_decl;
        iii_const_decl_payload_t          const_decl;
        iii_extern_decl_payload_t         extern_decl;
        iii_mobius_candidate_payload_t    mobius_candidate;
        iii_schema_decl_payload_t         schema_decl;
        iii_schema_field_payload_t        schema_field;
        iii_sealed_call_method_payload_t  sealed_call;
        iii_param_payload_t               param;
        iii_type_param_payload_t          type_param;
        iii_modifier_payload_t            modifier;
        iii_type_ref_payload_t            type_ref;
        iii_type_ptr_payload_t            type_ptr;
        iii_type_array_payload_t          type_array;
        iii_type_tuple_payload_t          type_tuple;
        iii_type_fn_payload_t             type_fn;
        iii_stmt_let_payload_t            let_;
        iii_stmt_wavefront_payload_t      wavefront;
        iii_stmt_sanctum_enter_payload_t  sanctum_enter;
        iii_stmt_metal_payload_t          metal;
        iii_stmt_for_payload_t            for_;
        iii_stmt_match_payload_t          match_stmt;
        iii_stmt_return_payload_t         return_;
        iii_stmt_assign_payload_t         assign;
        iii_stmt_expr_payload_t           expr_stmt;
        iii_forward_block_payload_t       forward_block;
        iii_compromise_block_payload_t    compromise_block;
        iii_match_arm_payload_t           match_arm;
        iii_pat_literal_payload_t         pat_literal;
        iii_pat_ident_payload_t           pat_ident;
        iii_pat_hexad_payload_t           pat_hexad;
        iii_pat_tuple_payload_t           pat_tuple;
        iii_expr_int_payload_t            int_;
        iii_expr_hex_payload_t            hex_;
        iii_expr_mhash_payload_t          mhash_;
        iii_expr_str_payload_t            str_;
        iii_expr_bool_payload_t           bool_;
        iii_expr_trit_payload_t           trit_;
        iii_expr_hexad_payload_t          hexad_;
        iii_expr_ident_payload_t          ident;
        iii_expr_call_payload_t           call;
        iii_expr_field_payload_t          field;
        iii_expr_index_payload_t          index;
        iii_expr_binary_payload_t         binary;
        iii_expr_unary_payload_t          unary;
        iii_expr_block_payload_t          block;
        iii_expr_match_payload_t          match_expr;
        iii_expr_paren_payload_t          paren;
        iii_expr_raw_asm_payload_t        raw_asm;
        iii_ring_set_payload_t            ring_set;
        iii_hexad_name_payload_t          hexad_name;
        iii_arg_payload_t                 arg;
        iii_expr_type_payload_t           expr_type;
        iii_type_of_payload_t             type_of;
        iii_expr_hole_payload_t           hole;
        iii_expr_parallel_payload_t       parallel;
        iii_error_node_payload_t          error;
        iii_adr_decl_payload_t            adr_decl;
        iii_conformance_claim_payload_t   conformance_claim;
        iii_test_case_payload_t           test_case;
        iii_rationale_payload_t           rationale;
        iii_operator_intent_payload_t     operator_intent;
        iii_user_node_payload_t           user_node;

        /* Phase-B union slots. */
        iii_stmt_if_payload_t             if_;
        iii_stmt_while_payload_t          while_;
        iii_expr_range_payload_t          range_;
        iii_expr_cast_payload_t           cast_;
        iii_expr_sizeof_payload_t         sizeof_;
        iii_struct_decl_payload_t         struct_decl;
        iii_var_decl_payload_t            var_decl;
        iii_stmt_loop_payload_t           loop_;
        iii_stmt_break_payload_t          break_;
        iii_stmt_continue_payload_t       continue_;
    } u;
} iii_ast_node_t;

/* Node flag bits (the `flags` field). */
#define III_AST_FLAG_NONE       0x0000u
#define III_AST_FLAG_SYNTHETIC  0x0001u   /* synthesised by a later pass */
#define III_AST_FLAG_ERROR      0x0002u   /* recovered from a parse error */
#define III_AST_FLAG_INTERNED   0x0004u   /* set after iii_ast_intern_node */

/* ─── Annotation table (L1) ──────────────────────────────────────── */

typedef struct {
    const char *phase;        /* static or arena-resident; phase key */
    uint32_t    node_index;
    uint32_t    blob_offset;  /* into ast->annotation_blobs */
    uint32_t    blob_len;
} iii_ast_annotation_t;

/* ─── User kind registry (C1) ────────────────────────────────────── */

typedef struct {
    uint32_t    user_kind_id;
    const char *name;         /* arena-resident */
} iii_ast_user_kind_t;

/* ─── Open list (F1) ─────────────────────────────────────────────── */

/* A heap-allocated list builder.  Multiple lists may be open
 * simultaneously; commit copies into the AST's contiguous list arena. */
struct iii_ast_open_list;
typedef struct iii_ast_open_list iii_ast_open_list_t;

/* ─── Zipper (I1) ────────────────────────────────────────────────── */

struct iii_ast_zipper;
typedef struct iii_ast_zipper iii_ast_zipper_t;

/* ─── Walk state (V1) ────────────────────────────────────────────── */

struct iii_ast_walk_state;
typedef struct iii_ast_walk_state iii_ast_walk_state_t;

/* ─── Diff (J1) ──────────────────────────────────────────────────── */

typedef struct {
    uint32_t old_node;
    uint32_t new_node;
} iii_ast_diff_pair_t;

/* ─── Checkpoint (E1) ────────────────────────────────────────────── */

typedef struct {
    uint32_t small_count, medium_count, large_count, user_count;
    uint32_t list_used;
    uint32_t string_payload_count;
    uint32_t position_count;
    uint32_t annotation_count;
    uint32_t annotation_blob_count;
    uint32_t hashcons_count;
    uint32_t next_binder_id;
} iii_ast_checkpoint_t;

/* ─── AST container ─────────────────────────────────────────────── */

typedef struct iii_ast iii_ast_t;

/* ─── Lifecycle ──────────────────────────────────────────────────── */

iii_ast_t *iii_ast_create(const uint8_t *source_buf,
                           size_t         source_len,
                           const char    *source_path);

void iii_ast_destroy(iii_ast_t *ast);

/* ─── Witnesses (D1, R1) ─────────────────────────────────────────── */

/* The four witnesses establish the AST's identity:
 *   parser_version_mhash : SHA-256 of the parser's source bytes
 *   token_stream_mhash   : iii_lex_stream_mhash output
 *   source_mhash         : SHA-256 of source_buf
 *   grammar_mhash        : SHA-256 of the active grammar table (the
 *                          set of registered user kinds plus the
 *                          built-in kind enum's frozen prefix) */
void iii_ast_set_parser_version(iii_ast_t *ast, const uint8_t mhash[32]);
void iii_ast_set_token_stream_mhash(iii_ast_t *ast, const uint8_t mhash[32]);
void iii_ast_set_source_mhash(iii_ast_t *ast, const uint8_t mhash[32]);
void iii_ast_set_grammar_mhash(iii_ast_t *ast, const uint8_t mhash[32]);
void iii_ast_get_witnesses(const iii_ast_t *ast,
                            uint8_t out_parser_version[32],
                            uint8_t out_token_stream[32],
                            uint8_t out_source[32],
                            uint8_t out_grammar[32]);
const uint8_t *iii_ast_root_module_mhash(const iii_ast_t *ast);

/* Recompute root_module_mhash from the current root_module.  Called
 * automatically by iii_ast_intern_node; exposed here for callers
 * that constructed the AST without going through interning. */
void iii_ast_recompute_root_mhash(iii_ast_t *ast);

/* ─── Source observation accessors ───────────────────────────────── */

const uint8_t  *iii_ast_source_buf(const iii_ast_t *ast);
size_t          iii_ast_source_len(const iii_ast_t *ast);
const char     *iii_ast_source_path(const iii_ast_t *ast);
uint32_t        iii_ast_root_module(const iii_ast_t *ast);
void            iii_ast_set_root_module(iii_ast_t *ast, uint32_t node_index);

/* ─── Construction ───────────────────────────────────────────────── */

/* Allocate a freshly-typed node in the appropriate kind pool.  Pool
 * dispatch is by kind: small/medium/large for built-in kinds, user
 * for III_AST_USER_NODE.  Returns the encoded node index, or 0 on
 * OOM.  `pos` (if non-NULL) is recorded in the position side-table
 * (B1, P1: physical position only — synthetic positions are added
 * via iii_ast_position_add_synthetic). */
uint32_t iii_ast_alloc_node(iii_ast_t *ast,
                             iii_ast_kind_t kind,
                             const iii_src_pos_t *pos);

/* Hash-cons interning (A2).  After the caller has filled in the
 * payload of a freshly-allocated node, call iii_ast_intern_node to
 * compute its mhash (A1) and consult the hash-cons table.  If an
 * isomorphic node already exists, the freshly-allocated one is
 * dropped (slot reverts), the prior node's index is returned, and
 * the position from the new node's first position record (if any)
 * is appended to the existing node's chain.  Returns the canonical
 * (interned) node index. */
uint32_t iii_ast_intern_node(iii_ast_t *ast, uint32_t freshly_allocated);

/* ─── List arena (LIFO API for back-compat) ──────────────────────── */

uint32_t        iii_ast_list_begin(iii_ast_t *ast);
bool            iii_ast_list_push (iii_ast_t *ast, uint32_t list_start, uint32_t node_index);
iii_ast_list_t  iii_ast_list_commit(iii_ast_t *ast, uint32_t list_start);

/* The original extend wrapper (LIFO-only). */
iii_ast_list_t iii_ast_list_extend(iii_ast_t *ast,
                                    const iii_ast_list_t *existing,
                                    uint32_t node_index);

/* ─── Open list (F1) — concurrent non-LIFO list builders ─────────── */

iii_ast_open_list_t *iii_ast_open_list_create(iii_ast_t *ast);
bool                 iii_ast_open_list_push(iii_ast_open_list_t *ol, uint32_t node_index);
iii_ast_list_t       iii_ast_open_list_commit(iii_ast_t *ast, iii_ast_open_list_t *ol);
void                 iii_ast_open_list_destroy(iii_ast_open_list_t *ol);

/* ─── String interning ───────────────────────────────────────────── */

uint32_t iii_ast_intern_string(iii_ast_t *ast, const uint8_t *payload);

/* ─── Read API ───────────────────────────────────────────────────── */

const iii_ast_node_t *iii_ast_get(const iii_ast_t *ast, uint32_t node_index);
iii_ast_node_t       *iii_ast_get_mut(iii_ast_t *ast, uint32_t node_index);

/* Number of distinct nodes across all pools (excluding the NULL
 * sentinel).  After hash-consing, this is the count of distinct
 * subterms, not the count of source occurrences. */
size_t iii_ast_node_count(const iii_ast_t *ast);

/* Number of distinct nodes in a specific pool. */
size_t iii_ast_pool_count(const iii_ast_t *ast, uint32_t pool);

/* Read the i-th element of a list. */
uint32_t iii_ast_list_at(const iii_ast_t *ast, iii_ast_list_t list, uint32_t i);

/* Translate a kind to a stable .rdata string for diagnostics. */
const char *iii_ast_kind_name(iii_ast_kind_t k);

/* ─── Node mhash (A1) ────────────────────────────────────────────── */

const uint8_t *iii_ast_node_mhash(const iii_ast_t *ast, uint32_t node_index);

/* ─── Position side-table (B1, B2, P1) ───────────────────────────── */

size_t iii_ast_position_count(const iii_ast_t *ast, uint32_t node_index);
bool   iii_ast_position_at   (const iii_ast_t *ast, uint32_t node_index,
                               size_t i, iii_ast_position_t *out);
bool   iii_ast_position_first(const iii_ast_t *ast, uint32_t node_index,
                               iii_ast_position_t *out);

/* Add an additional position to a node (called automatically when
 * hash-consing dedups two occurrences). */
bool iii_ast_position_add(iii_ast_t *ast, uint32_t node_index,
                           const iii_ast_position_t *pos);

/* Add a synthetic position record (P1).  source_node_index is the
 * AST node from which this synthesis derives; pass_mhash identifies
 * the synthesising pass; rationale_str_idx (0 = none) is a
 * string_payload index pointing to a human-readable rationale. */
bool iii_ast_position_add_synthetic(iii_ast_t *ast, uint32_t node_index,
                                      uint32_t source_node_index,
                                      const uint8_t pass_mhash[32],
                                      uint32_t rationale_str_idx);

/* ─── Binder IDs (M1) ────────────────────────────────────────────── */

/* Allocate a fresh binder ID (sema's job).  Stable across re-parses
 * of the same source. */
uint32_t iii_ast_alloc_binder_id(iii_ast_t *ast);

/* Per-node binder_id side-table.  Set by sema during identifier
 * resolution; read by codegen.  0 = unresolved. */
uint32_t iii_ast_node_binder_id(const iii_ast_t *ast, uint32_t node_index);
bool     iii_ast_set_binder_id (iii_ast_t *ast, uint32_t node_index, uint32_t binder_id);

/* ─── Doc-comment side-table (G1) ────────────────────────────────── */

uint32_t iii_ast_leading_doc_comment(const iii_ast_t *ast, uint32_t node_index);
bool     iii_ast_set_leading_doc_comment(iii_ast_t *ast, uint32_t node_index,
                                            uint32_t doc_comment_node);

/* ─── Checkpoint / rollback (E1) ─────────────────────────────────── */

iii_ast_checkpoint_t iii_ast_checkpoint(const iii_ast_t *ast);
void                 iii_ast_rollback (iii_ast_t *ast, iii_ast_checkpoint_t cp);

/* ─── Walks: callback API (back-compat) ──────────────────────────── */

typedef int (*iii_ast_visit_fn_t)(iii_ast_t *ast,
                                   uint32_t node_index,
                                   uint32_t depth,
                                   void *ctx);

int iii_ast_walk_pre(iii_ast_t *ast,
                      uint32_t root,
                      iii_ast_visit_fn_t fn,
                      void *ctx);

int iii_ast_walk_post(iii_ast_t *ast,
                       uint32_t root,
                       iii_ast_visit_fn_t fn,
                       void *ctx);

typedef int (*iii_ast_child_fn_t)(iii_ast_t *ast,
                                   uint32_t parent,
                                   uint32_t child,
                                   const char *slot_kind,
                                   void *ctx);
int iii_ast_iterate_children(iii_ast_t *ast,
                              uint32_t node,
                              iii_ast_child_fn_t fn,
                              void *ctx);

/* ─── Zipper (I1) ────────────────────────────────────────────────── */

iii_ast_zipper_t *iii_ast_zipper_at(iii_ast_t *ast, uint32_t node_index);
void              iii_ast_zipper_destroy(iii_ast_zipper_t *z);
uint32_t          iii_ast_zipper_node(const iii_ast_zipper_t *z);
size_t            iii_ast_zipper_depth(const iii_ast_zipper_t *z);

/* Descend into the i-th child of the current node (0-based).
 * Returns true on success; false if the index is out of range. */
bool iii_ast_zipper_descend(iii_ast_zipper_t *z, uint32_t child_index);

/* Ascend to the parent.  Returns true unless already at the root. */
bool iii_ast_zipper_ascend(iii_ast_zipper_t *z);

/* Move to a sibling (delta = +1 or -1).  Returns true on success. */
bool iii_ast_zipper_sibling(iii_ast_zipper_t *z, int delta);

/* ─── Walk state (V1) — coroutine-style traversal ────────────────── */

iii_ast_walk_state_t *iii_ast_walk_state_create(iii_ast_t *ast,
                                                   uint32_t root,
                                                   bool post_order);
void                  iii_ast_walk_state_destroy(iii_ast_walk_state_t *ws);

/* Step one node.  Returns true with *out_node populated; returns
 * false when the walk has finished. */
bool iii_ast_walk_state_step(iii_ast_walk_state_t *ws,
                              uint32_t *out_node,
                              uint32_t *out_depth);

bool iii_ast_walk_state_done(const iii_ast_walk_state_t *ws);

/* Persist a walk state to bytes; restore later (possibly in another
 * process operating on a deserialised AST).  Returns the byte size
 * written, or required, when out is NULL. */
size_t                iii_ast_walk_state_serialize(const iii_ast_walk_state_t *ws,
                                                     uint8_t *out, size_t cap);
iii_ast_walk_state_t *iii_ast_walk_state_deserialize(iii_ast_t *ast,
                                                       const uint8_t *bytes,
                                                       size_t len);

/* ─── Diff (J1) ──────────────────────────────────────────────────── */

/* Compare two ASTs by mhash.  Walks the trees in lockstep, recursing
 * only into subtrees whose mhashes differ.  Writes (old_node,
 * new_node) pairs into `out` (capacity `cap`); returns the total
 * number of differing pairs (which may exceed cap). */
size_t iii_ast_diff(const iii_ast_t *old_ast, uint32_t old_root,
                     const iii_ast_t *new_ast, uint32_t new_root,
                     iii_ast_diff_pair_t *out, size_t cap);

/* ─── Annotations (L1) ───────────────────────────────────────────── */

/* Phase-keyed annotation.  `phase` is a static or arena-resident
 * string ("sema/type", "sid/inverse_plan", "proof/cert_mhash",
 * "cg/stack_slot", etc.).  blob bytes are copied into the AST's
 * annotation arena; the original buffer may be freed.  Returns true
 * on success. */
bool iii_ast_annotate(iii_ast_t *ast,
                       const char *phase,
                       uint32_t node_index,
                       const uint8_t *blob, size_t blob_len);

/* Look up an annotation.  *out_blob points into the AST's annotation
 * arena; valid for the AST's lifetime (or until rollback past the
 * record).  Returns true on hit. */
bool iii_ast_get_annotation(const iii_ast_t *ast,
                              const char *phase,
                              uint32_t node_index,
                              const uint8_t **out_blob,
                              size_t *out_blob_len);

size_t iii_ast_annotation_count(const iii_ast_t *ast);

/* ─── User kinds (C1) ────────────────────────────────────────────── */

/* Register a runtime constructor.  Returns a stable user_kind_id
 * (≥1) or 0 on failure.  `name` is copied into the AST's arena. */
uint32_t    iii_ast_register_user_kind(iii_ast_t *ast, const char *name);
const char *iii_ast_user_kind_name(const iii_ast_t *ast, uint32_t user_kind_id);
size_t      iii_ast_user_kind_count(const iii_ast_t *ast);

/* ─── Serialize / deserialize (Q1) ───────────────────────────────── */

/* Canonical binary serialisation.  The output begins with a 16-byte
 * magic header ("IIIASTBIN" + version u32 + reserved u32) and ends
 * with a 32-byte SHA-256 trailer over everything before it.  Two
 * serialisations of identical ASTs produce identical bytes. */
size_t     iii_ast_serialize  (const iii_ast_t *ast, FILE *out);
iii_ast_t *iii_ast_deserialize(FILE *in);

size_t     iii_ast_serialize_buf  (const iii_ast_t *ast, uint8_t *out, size_t cap);
iii_ast_t *iii_ast_deserialize_buf(const uint8_t *bytes, size_t len);

/* ─── Debug ──────────────────────────────────────────────────────── */

void iii_ast_debug_dump(const iii_ast_t *ast, uint32_t root, FILE *out);

#ifdef __cplusplus
}
#endif

#endif /* III_BOOT_AST_H */
