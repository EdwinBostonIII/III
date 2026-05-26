/* III-ABI test runner — small, hand-rolled assertions; no third-party
 * test framework.  Prints `=== N passed, M failed ===` at the end.
 *
 * We construct EXTERN_DECL / EXTERN_ITEM AST nodes manually for the
 * lowering tests because the upstream parser loses the body of
 * `extern @abi(c-msvc-x64) { … }` to error recovery (the multi-token
 * abi name `c-msvc-x64` lexes as IDENT '-' IDENT '-' IDENT, which the
 * BOOT parser is not yet equipped to re-glue — it skips to ';' or '}'
 * on the punct mismatch).  The validator recovers the abi name from
 * the original source bytes, so validation tests still parse real III.
 */
#include <iii/abi.h>
#include <iii/ast.h>
#include <iii/parser.h>
#include <iii/parse_arena.h>
#include <iii/lex.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int g_pass = 0, g_fail = 0;

#define CHECK(cond, msg) do {                                                 \
    if (cond) { g_pass++; printf("[ok  ] %s\n", msg); }                       \
    else      { g_fail++; printf("[FAIL] %s  (line %d)\n", msg, __LINE__); }  \
} while (0)

/* ------------------------------------------------------------------ */
/* Parse helper for VALIDATION tests (real III source).                */
/* ------------------------------------------------------------------ */

typedef struct fix {
    iii_lex_state_t *lex;
    iii_arena_t     *arena;
    iii_parser_t    *par;
    iii_ast_node_t  *root;
    uint8_t         *src;
    size_t           slen;
} fix_t;

static int parse_str(fix_t *f, const char *s) {
    memset(f, 0, sizeof *f);
    f->slen = strlen(s);
    f->src = (uint8_t *)malloc(f->slen + 1);
    if (!f->src) return -1;
    memcpy(f->src, s, f->slen + 1);
    f->lex = iii_lex_create(f->src, f->slen, "<test>");
    if (!f->lex) return -1;
    f->arena = iii_arena_create();
    if (!f->arena) return -1;
    f->par = iii_parser_create(f->lex, f->arena);
    if (!f->par) return -1;
    f->root = iii_parse_module(f->par);
    return f->root ? 0 : -1;
}

static void fix_free(fix_t *f) {
    if (f->par)   iii_parser_destroy(f->par);
    if (f->arena) iii_arena_destroy(f->arena);
    if (f->lex)   iii_lex_destroy(f->lex);
    free(f->src);
    memset(f, 0, sizeof *f);
}

static const iii_ast_node_t *find_extern(const iii_ast_node_t *m) {
    if (!m) return NULL;
    for (uint32_t i = 0; i < m->child_count; ++i) {
        if (m->children[i] && m->children[i]->kind == III_AST_EXTERN_DECL)
            return m->children[i];
    }
    return NULL;
}

/* ------------------------------------------------------------------ */
/* Hand-built AST helpers for LOWERING tests.                          */
/*                                                                     */
/* We hold owned heap nodes in a small registry so the test process    */
/* can free them at exit.                                              */
/* ------------------------------------------------------------------ */

static iii_ast_node_t **g_nodes;
static size_t           g_nodes_n, g_nodes_cap;

static iii_ast_node_t *mknode(iii_ast_kind_t k) {
    iii_ast_node_t *n = (iii_ast_node_t *)calloc(1, sizeof *n);
    n->kind = k;
    n->doc_offset = III_AST_NO_DOC;
    if (g_nodes_n == g_nodes_cap) {
        g_nodes_cap = g_nodes_cap ? g_nodes_cap * 2 : 32;
        g_nodes = (iii_ast_node_t **)realloc(g_nodes, g_nodes_cap * sizeof *g_nodes);
    }
    g_nodes[g_nodes_n++] = n;
    return n;
}

static void addch(iii_ast_node_t *p, iii_ast_node_t *c) {
    if (p->child_count == p->child_cap) {
        p->child_cap = p->child_cap ? p->child_cap * 2 : 4;
        p->children = (iii_ast_node_t **)realloc(p->children,
                          p->child_cap * sizeof *p->children);
    }
    p->children[p->child_count++] = c;
}

static iii_ast_node_t *mkname(iii_ast_kind_t k, const char *name) {
    iii_ast_node_t *n = mknode(k);
    n->string_payload = (const uint8_t *)name;
    n->string_len = strlen(name);
    return n;
}

/* type wrapper: III_AST_TYPE → child */
static iii_ast_node_t *mktype_prim(const char *prim) {
    iii_ast_node_t *t = mknode(III_AST_TYPE);
    addch(t, mkname(III_AST_PRIMITIVE_TYPE, prim));
    return t;
}

/* &T  →  III_AST_TYPE → III_AST_TYPE → PRIMITIVE_TYPE */
static iii_ast_node_t *mktype_ref_prim(const char *prim) {
    iii_ast_node_t *outer = mknode(III_AST_TYPE);
    addch(outer, mktype_prim(prim));
    return outer;
}

/* [T;N]  →  III_AST_ARRAY_TYPE (no III_AST_TYPE wrapper, matching
 * parse_extern_type's array branch). */
static iii_ast_node_t *mktype_array(const char *elem_prim, uint32_t n) {
    iii_ast_node_t *a = mknode(III_AST_ARRAY_TYPE);
    a->int_value = n;
    addch(a, mktype_prim(elem_prim));
    return a;
}

/* IDENT-named alias type → III_AST_TYPE → III_AST_BASE_TYPE */
static iii_ast_node_t *mktype_alias(const char *name) {
    iii_ast_node_t *t = mknode(III_AST_TYPE);
    addch(t, mkname(III_AST_BASE_TYPE, name));
    return t;
}

/* unit return: III_AST_TYPE → TUPLE_TYPE(0 children) */
static iii_ast_node_t *mktype_unit(void) {
    iii_ast_node_t *t = mknode(III_AST_TYPE);
    addch(t, mknode(III_AST_TUPLE_TYPE));
    return t;
}

static iii_ast_node_t *mkparam(const char *name, iii_ast_node_t *type) {
    iii_ast_node_t *p = mkname(III_AST_PARAM, name);
    addch(p, type);
    return p;
}

static iii_ast_node_t *mkfn(const char *name) {
    iii_ast_node_t *it = mkname(III_AST_EXTERN_ITEM, name);
    it->op_id = 0; /* fn */
    return it;
}

static iii_ast_node_t *mktypealias(const char *name, iii_ast_node_t *type) {
    iii_ast_node_t *it = mkname(III_AST_EXTERN_ITEM, name);
    it->op_id = 1; /* type */
    addch(it, type);
    return it;
}

static iii_ast_node_t *mkextern(void) {
    iii_ast_node_t *e = mknode(III_AST_EXTERN_DECL);
    e->op_id = 1; /* @abi present */
    return e;
}

static void free_all_nodes(void) {
    for (size_t i = 0; i < g_nodes_n; ++i) {
        free(g_nodes[i]->children);
        free(g_nodes[i]);
    }
    free(g_nodes);
    g_nodes = NULL;
    g_nodes_n = g_nodes_cap = 0;
}

/* ================================================================== */
/* Validation tests (use real parser + source bytes).                 */
/* ================================================================== */

static void test_validate_accept_ok(void) {
    const char *src =
        "module m @ring(R0)\n"
        "extern @abi(c-msvc-x64) {\n"
        "}\n";
    fix_t f; CHECK(parse_str(&f, src) == 0, "parse: valid c-msvc-x64 in R0");
    const iii_ast_node_t *e = find_extern(f.root);
    CHECK(e != NULL, "found extern_decl");
    iii_abi_diag_t d;
    int r = iii_abi_validate_extern(f.root, e, f.src, f.slen, &d);
    CHECK(r == IIIABI_OK, "validator accepts c-msvc-x64 / R0");
    fix_free(&f);
}

static void test_validate_r3_ok(void) {
    const char *src =
        "module m @ring(R3)\n"
        "extern @abi(c-msvc-x64) {\n"
        "}\n";
    fix_t f; parse_str(&f, src);
    const iii_ast_node_t *e = find_extern(f.root);
    iii_abi_diag_t d;
    int r = iii_abi_validate_extern(f.root, e, f.src, f.slen, &d);
    CHECK(r == IIIABI_OK, "validator accepts R3 module");
    fix_free(&f);
}

static void test_validate_bad_abi_name(void) {
    const char *src =
        "module m @ring(R0)\n"
        "extern @abi(c-sysv-x64) {\n"
        "}\n";
    fix_t f; parse_str(&f, src);
    const iii_ast_node_t *e = find_extern(f.root);
    iii_abi_diag_t d;
    int r = iii_abi_validate_extern(f.root, e, f.src, f.slen, &d);
    CHECK(r == IIIABI_E_BAD_ABI_NAME,
          "validator rejects c-sysv-x64 (BAD_ABI_NAME)");
    fix_free(&f);
}

static void test_validate_bad_abi_garbage(void) {
    const char *src =
        "module m @ring(R0)\n"
        "extern @abi(magic-msr) {\n"
        "}\n";
    fix_t f; parse_str(&f, src);
    const iii_ast_node_t *e = find_extern(f.root);
    iii_abi_diag_t d;
    int r = iii_abi_validate_extern(f.root, e, f.src, f.slen, &d);
    CHECK(r == IIIABI_E_BAD_ABI_NAME, "validator rejects magic-msr");
    fix_free(&f);
}

static void test_validate_no_ring(void) {
    const char *src =
        "module m\n"
        "extern @abi(c-msvc-x64) {\n"
        "}\n";
    fix_t f; parse_str(&f, src);
    const iii_ast_node_t *e = find_extern(f.root);
    iii_abi_diag_t d;
    int r = iii_abi_validate_extern(f.root, e, f.src, f.slen, &d);
    CHECK(r == IIIABI_E_NO_RING_ATTR,
          "validator rejects extern in module with no @ring");
    fix_free(&f);
}

static void test_validate_privileged_ring(void) {
    const char *src =
        "module m @ring(R-1)\n"
        "extern @abi(c-msvc-x64) {\n"
        "}\n";
    fix_t f; parse_str(&f, src);
    const iii_ast_node_t *e = find_extern(f.root);
    iii_abi_diag_t d;
    int r = iii_abi_validate_extern(f.root, e, f.src, f.slen, &d);
    CHECK(r == IIIABI_E_BAD_RING,
          "validator rejects extern in R-1 (TYPE-EXTERN-001)");
    fix_free(&f);
}

static void test_validate_missing_abi(void) {
    /* Build an EXTERN_DECL with op_id == 0 (no @abi clause), no
     * surrounding @abi(...) text in the source so extraction fails too. */
    iii_ast_node_t *e = mkextern();
    e->op_id = 0;
    iii_abi_diag_t d;
    /* module=NULL skips ring check; src=NULL exercises MISSING_ABI path. */
    int r = iii_abi_validate_extern(NULL, e, NULL, 0, &d);
    CHECK(r == IIIABI_E_MISSING_ABI, "validator rejects extern with no @abi");
    free_all_nodes();
}

/* ================================================================== */
/* Lowering tests (hand-built AST).                                   */
/* ================================================================== */

static void test_lower_int_int(void) {
    iii_ast_node_t *e = mkextern();
    iii_ast_node_t *fn = mkfn("add");
    addch(fn, mkparam("a", mktype_prim("i32")));
    addch(fn, mkparam("b", mktype_prim("i32")));
    addch(fn, mktype_prim("i32"));
    addch(e, fn);

    iii_abi_signature_t sig;
    int r = iii_abi_lower_signature(e, fn, &sig);
    CHECK(r == IIIABI_OK,                       "lower add(i32,i32)->i32");
    CHECK(sig.param_count == 2,                 "  param_count == 2");
    CHECK(sig.params[0].loc == IIIABI_LOC_RCX,  "  a -> rcx");
    CHECK(sig.params[1].loc == IIIABI_LOC_RDX,  "  b -> rdx");
    CHECK(sig.ret.loc == IIIABI_LOC_RAX,        "  ret -> rax");
    CHECK(sig.shadow_space == 32,               "  shadow == 32");
    CHECK(sig.total_stack == 32,                "  total_stack == 32");
    free_all_nodes();
}

static void test_lower_floats_first_four(void) {
    iii_ast_node_t *e = mkextern();
    iii_ast_node_t *fn = mkfn("fma4");
    addch(fn, mkparam("a", mktype_prim("f64")));
    addch(fn, mkparam("b", mktype_prim("f64")));
    addch(fn, mkparam("c", mktype_prim("f64")));
    addch(fn, mkparam("d", mktype_prim("f64")));
    addch(fn, mktype_prim("f64"));
    addch(e, fn);

    iii_abi_signature_t sig;
    iii_abi_lower_signature(e, fn, &sig);
    CHECK(sig.params[0].loc == IIIABI_LOC_XMM0, "fma4 a -> xmm0");
    CHECK(sig.params[1].loc == IIIABI_LOC_XMM1, "fma4 b -> xmm1");
    CHECK(sig.params[2].loc == IIIABI_LOC_XMM2, "fma4 c -> xmm2");
    CHECK(sig.params[3].loc == IIIABI_LOC_XMM3, "fma4 d -> xmm3");
    CHECK(sig.ret.loc == IIIABI_LOC_XMM0_RET,   "fma4 ret -> xmm0");
    free_all_nodes();
}

static void test_lower_six_ints_spill(void) {
    iii_ast_node_t *e = mkextern();
    iii_ast_node_t *fn = mkfn("six");
    static const char *PN[6] = {"a","b","c","d","e","f"};
    for (int i = 0; i < 6; ++i)
        addch(fn, mkparam(PN[i], mktype_prim("i64")));
    addch(fn, mktype_prim("i64"));
    addch(e, fn);

    iii_abi_signature_t sig;
    iii_abi_lower_signature(e, fn, &sig);
    CHECK(sig.params[3].loc == IIIABI_LOC_R9,    "six d -> r9");
    CHECK(sig.params[4].loc == IIIABI_LOC_STACK, "six e -> stack");
    CHECK(sig.params[5].loc == IIIABI_LOC_STACK, "six f -> stack");
    CHECK(sig.params[4].stack_offset == 0,       "  e at +0 above shadow");
    CHECK(sig.params[5].stack_offset == 8,       "  f at +8 above shadow");
    CHECK(sig.stack_arg_bytes == 16,             "  stack_args == 16");
    CHECK(sig.total_stack == 48,                 "  total_stack == 48");
    free_all_nodes();
}

static void test_lower_mixed_int_sse(void) {
    iii_ast_node_t *e = mkextern();
    iii_ast_node_t *fn = mkfn("mix");
    addch(fn, mkparam("a", mktype_prim("i32")));
    addch(fn, mkparam("b", mktype_prim("f64")));
    addch(fn, mkparam("c", mktype_prim("i32")));
    addch(fn, mkparam("d", mktype_prim("f64")));
    addch(fn, mktype_unit());
    addch(e, fn);

    iii_abi_signature_t sig;
    iii_abi_lower_signature(e, fn, &sig);
    CHECK(sig.params[0].loc == IIIABI_LOC_RCX,  "mix a (i32) -> rcx");
    CHECK(sig.params[1].loc == IIIABI_LOC_XMM1, "mix b (f64) -> xmm1");
    CHECK(sig.params[2].loc == IIIABI_LOC_R8,   "mix c (i32) -> r8");
    CHECK(sig.params[3].loc == IIIABI_LOC_XMM3, "mix d (f64) -> xmm3");
    free_all_nodes();
}

static void test_lower_pointer(void) {
    iii_ast_node_t *e = mkextern();
    iii_ast_node_t *fn = mkfn("poke");
    addch(fn, mkparam("p", mktype_ref_prim("u8")));
    addch(fn, mktype_unit());
    addch(e, fn);

    iii_abi_signature_t sig;
    iii_abi_lower_signature(e, fn, &sig);
    CHECK(sig.params[0].type == IIIABI_T_PTR,  "poke p -> PTR");
    CHECK(sig.params[0].size == 8,             "  size 8");
    CHECK(sig.params[0].loc == IIIABI_LOC_RCX, "  -> rcx");
    free_all_nodes();
}

static void test_lower_array_alias_by_ref(void) {
    iii_ast_node_t *e = mkextern();
    addch(e, mktypealias("Sha256State", mktype_array("u8", 104)));
    iii_ast_node_t *fn = mkfn("init");
    addch(fn, mkparam("state", mktype_alias("Sha256State")));
    addch(fn, mktype_unit());
    addch(e, fn);

    iii_abi_signature_t sig;
    int r = iii_abi_lower_signature(e, fn, &sig);
    CHECK(r == IIIABI_OK,                          "lower alias [u8;104]");
    CHECK(sig.params[0].cls == IIIABI_CLS_MEMORY,  "  -> MEMORY class");
    CHECK(sig.params[0].by_hidden_ref == 1,        "  by hidden &");
    CHECK(sig.params[0].loc == IIIABI_LOC_RCX,     "  ptr in rcx");
    CHECK(sig.params[0].size == 104,               "  size 104");
    free_all_nodes();
}

static void test_lower_array_inline_8b(void) {
    iii_ast_node_t *e = mkextern();
    iii_ast_node_t *fn = mkfn("pack");
    addch(fn, mkparam("a", mktype_array("u8", 8)));
    addch(fn, mktype_prim("u64"));
    addch(e, fn);

    iii_abi_signature_t sig;
    iii_abi_lower_signature(e, fn, &sig);
    CHECK(sig.params[0].cls == IIIABI_CLS_INTEGER, "pack [u8;8] -> INTEGER");
    CHECK(sig.params[0].loc == IIIABI_LOC_RCX,     "  in rcx");
    CHECK(sig.params[0].by_hidden_ref == 0,        "  inline (not by ref)");
    CHECK(sig.ret.loc == IIIABI_LOC_RAX,           "  u64 ret -> rax");
    free_all_nodes();
}

static void test_lower_void_ret(void) {
    iii_ast_node_t *e = mkextern();
    iii_ast_node_t *fn = mkfn("nop");
    addch(fn, mktype_unit());
    addch(e, fn);

    iii_abi_signature_t sig;
    iii_abi_lower_signature(e, fn, &sig);
    CHECK(sig.ret.cls == IIIABI_CLS_VOID,    "nop ret = VOID");
    CHECK(sig.ret.loc == IIIABI_LOC_NONE,    "nop ret loc = none");
    CHECK(sig.param_count == 0,              "nop no params");
    CHECK(sig.total_stack == 32,             "nop total_stack = 32 (shadow)");
    free_all_nodes();
}

static void test_lower_synthetic_memory_ret(void) {
    iii_abi_signature_t sig;
    iii_abi_signature_init(&sig, "blob_make");
    iii_abi_signature_add_param(&sig, "x", IIIABI_T_I32, 0, IIIABI_T_VOID);
    iii_abi_signature_add_param(&sig, "y", IIIABI_T_I32, 0, IIIABI_T_VOID);
    sig.ret.type        = IIIABI_T_ARRAY;
    sig.ret.elem_count  = 16;
    sig.ret.elem_type   = IIIABI_T_U8;
    sig.ret.size        = 16;
    sig.ret.align       = 1;
    iii_abi_signature_finalize(&sig);
    CHECK(sig.hidden_ret_ptr == 1,             "synthetic: hidden_ret_ptr");
    CHECK(sig.ret.loc == IIIABI_LOC_HIDDEN_PTR,"  ret loc = HIDDEN_PTR");
    CHECK(sig.params[0].loc == IIIABI_LOC_RDX, "  x shifted to rdx");
    CHECK(sig.params[1].loc == IIIABI_LOC_R8,  "  y shifted to r8");
}

static void test_marshal_demo(void) {
    iii_abi_signature_t sig;
    iii_abi_signature_init(&sig, "memcpy");
    iii_abi_signature_add_param(&sig, "dst", IIIABI_T_PTR, 0, IIIABI_T_VOID);
    iii_abi_signature_add_param(&sig, "src", IIIABI_T_PTR, 0, IIIABI_T_VOID);
    iii_abi_signature_add_param(&sig, "n",   IIIABI_T_U64, 0, IIIABI_T_VOID);
    iii_abi_signature_set_return(&sig, IIIABI_T_PTR);
    iii_abi_signature_finalize(&sig);
    char buf[4096];
    size_t n = iii_abi_marshal_call(&sig, buf, sizeof buf);
    CHECK(n > 0,                                       "marshal: produced output");
    CHECK(strstr(buf, "EXTERN_C_CALL")     != NULL,    "marshal: hexad EXTERN_C_CALL present");
    CHECK(strstr(buf, "Compromise<MEDIUM>")!= NULL,    "marshal: inverse Compromise<MEDIUM>");
    CHECK(strstr(buf, "sub  rsp, 32")      != NULL,    "marshal: shadow-space sub");
    CHECK(strstr(buf, "rcx")               != NULL,    "marshal: rcx mentioned");
    CHECK(strstr(buf, "rdx")               != NULL,    "marshal: rdx mentioned");
    CHECK(strstr(buf, "r8")                != NULL,    "marshal: r8 mentioned");
    CHECK(strstr(buf, "call memcpy")       != NULL,    "marshal: call memcpy");
}

static void test_names_table(void) {
    CHECK(strcmp(iii_abi_kind_name(IIIABI_C_MSVC_X64),
                 "c-msvc-x64") == 0,                "name: c-msvc-x64");
    CHECK(strcmp(iii_abi_diag_name(IIIABI_E_BAD_ABI_NAME),
                 "BAD_ABI_NAME") == 0,              "name: diag");
    CHECK(iii_abi_type_name(IIIABI_T_F64)[0] == 'f',"name: f64");
    CHECK(iii_abi_class_name(IIIABI_CLS_SSE)[0] == 'S', "name: SSE");
    CHECK(iii_abi_loc_name(IIIABI_LOC_RAX)[0] == 'r', "name: rax");
}

int main(void) {
    test_validate_accept_ok();
    test_validate_r3_ok();
    test_validate_bad_abi_name();
    test_validate_bad_abi_garbage();
    test_validate_no_ring();
    test_validate_privileged_ring();
    test_validate_missing_abi();

    test_lower_int_int();
    test_lower_floats_first_four();
    test_lower_six_ints_spill();
    test_lower_mixed_int_sse();
    test_lower_pointer();
    test_lower_array_alias_by_ref();
    test_lower_array_inline_8b();
    test_lower_void_ret();
    test_lower_synthetic_memory_ret();

    test_marshal_demo();
    test_names_table();

    printf("\n=== %d passed, %d failed ===\n", g_pass, g_fail);
    return g_fail > 255 ? 255 : g_fail;
}
