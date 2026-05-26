/* III Grammar — item / declaration tests (§5). */
#include "test.h"

void run_decl_tests(void) {

    TEST_CASE("cycle_decl_forward_only") {
        const char *src =
            "module m\n"
            "cycle do_thing(x: u32) -> u32 {\n"
            "  forward { return x }\n"
            "}\n";
        iiit_parse_t f;
        ASSERT_TRUE(iiit_parse(src, &f));
        ASSERT_NOT_NULL(f.root);
        const iii_ast_node_t *c = iiit_find_child(f.root, III_AST_CYCLE_DECL);
        ASSERT_NOT_NULL(c);
        ASSERT_TRUE(iiit_count_kind(c, III_AST_FORWARD_BLOCK) == 1u);
        ASSERT_TRUE(iiit_count_kind(c, III_AST_INVERSE_BLOCK) == 0u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("cycle_decl_forward_inverse") {
        const char *src =
            "module m\n"
            "cycle round_trip(x: u32) -> u32 {\n"
            "  forward { return x }\n"
            "  inverse { return x }\n"
            "}\n";
        iiit_parse_t f;
        ASSERT_TRUE(iiit_parse(src, &f));
        ASSERT_NOT_NULL(f.root);
        const iii_ast_node_t *c = iiit_find_child(f.root, III_AST_CYCLE_DECL);
        ASSERT_NOT_NULL(c);
        ASSERT_EQ(iiit_count_kind(c, III_AST_FORWARD_BLOCK), 1u);
        ASSERT_EQ(iiit_count_kind(c, III_AST_INVERSE_BLOCK), 1u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("cycle_decl_with_modifiers") {
        const char *src =
            "module m\n"
            "cycle pure_thing() -> u32 @pure @hot_path {\n"
            "  forward { return 0 }\n"
            "}\n";
        iiit_parse_t f;
        ASSERT_TRUE(iiit_parse(src, &f));
        ASSERT_NOT_NULL(f.root);
        const iii_ast_node_t *c = iiit_find_child(f.root, III_AST_CYCLE_DECL);
        ASSERT_NOT_NULL(c);
        /* Modifiers may be attached to the return type or the cycle itself. */
        ASSERT_TRUE(iiit_count_kind(c, III_AST_CYCLE_MODIFIER)
                  + iiit_count_kind(c, III_AST_TYPE_MODIFIER) >= 2u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("function_decl_simple") {
        const char *src =
            "module m\n"
            "fn add(a: u32, b: u32) -> u32 { return a }\n";
        iiit_parse_t f;
        ASSERT_TRUE(iiit_parse(src, &f));
        ASSERT_NOT_NULL(f.root);
        const iii_ast_node_t *fn = iiit_find_child(f.root, III_AST_FUNCTION_DECL);
        ASSERT_NOT_NULL(fn);
        ASSERT_TRUE(iiit_count_kind(fn, III_AST_PARAM) >= 2u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("function_decl_with_generics") {
        const char *src =
            "module m\n"
            "fn id<T>(x: T) -> T { return x }\n";
        iiit_parse_t f;
        ASSERT_TRUE(iiit_parse(src, &f));
        ASSERT_NOT_NULL(f.root);
        const iii_ast_node_t *fn = iiit_find_child(f.root, III_AST_FUNCTION_DECL);
        ASSERT_NOT_NULL(fn);
        ASSERT_TRUE(iiit_count_kind(fn, III_AST_GENERIC_PARAM) >= 1u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("type_decl_alias") {
        const char *src =
            "module m\n"
            "type MyInt = u32\n";
        iiit_parse_t f;
        ASSERT_TRUE(iiit_parse(src, &f));
        ASSERT_NOT_NULL(f.root);
        const iii_ast_node_t *td = iiit_find_child(f.root, III_AST_TYPE_DECL);
        ASSERT_NOT_NULL(td);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("mobius_candidate_decl") {
        const char *src =
            "module m\n"
            "mobius_candidate try_it(x: u32) -> u32 @hexad(POS,ZERO,POS,ZERO,ZERO,ZERO) {\n"
            "  forward { return x }\n"
            "}\n";
        iiit_parse_t f;
        ASSERT_TRUE(iiit_parse(src, &f));
        ASSERT_NOT_NULL(f.root);
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_MOBIUS_CANDIDATE_DECL) >= 1u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("schema_decl") {
        const char *src =
            "module m\n"
            "schema S = OBSERVATORY {\n"
            "  x: Welford,\n"
            "  y: Welford\n"
            "}\n";
        iiit_parse_t f;
        ASSERT_TRUE(iiit_parse(src, &f));
        ASSERT_NOT_NULL(f.root);
        const iii_ast_node_t *s = iiit_find_child(f.root, III_AST_SCHEMA_DECL);
        ASSERT_NOT_NULL(s);
        ASSERT_TRUE(iiit_count_kind(s, III_AST_SCHEMA_FIELD) >= 1u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("narrative_decl") {
        const char *src =
            "module m\n"
            "narrative {\n"
            "  core_identity: \"i am m\",\n"
            "  mission: \"compute\"\n"
            "}\n";
        iiit_parse_t f;
        ASSERT_TRUE(iiit_parse(src, &f));
        ASSERT_NOT_NULL(f.root);
        const iii_ast_node_t *n = iiit_find_child(f.root, III_AST_NARRATIVE_DECL);
        ASSERT_NOT_NULL(n);
        ASSERT_TRUE(iiit_count_kind(n, III_AST_NARRATIVE_FIELD) >= 2u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("const_decl") {
        const char *src =
            "module m\n"
            "const PI: u32 = 3\n";
        iiit_parse_t f;
        ASSERT_TRUE(iiit_parse(src, &f));
        ASSERT_NOT_NULL(f.root);
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_CONST_DECL) >= 1u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("extern_decl_multi_items") {
        const char *src =
            "module m\n"
            "extern @abi(c-msvc-x64) {\n"
            "  fn malloc(n: u64) -> *u8 ;\n"
            "  fn free(p: *u8) -> bool ;\n"
            "  type FILE = u64 ;\n"
            "}\n";
        iiit_parse_t f;
        ASSERT_TRUE(iiit_parse(src, &f));
        ASSERT_NOT_NULL(f.root);
        const iii_ast_node_t *e = iiit_find_child(f.root, III_AST_EXTERN_DECL);
        ASSERT_NOT_NULL(e);
        ASSERT_TRUE(iiit_count_kind(e, III_AST_EXTERN_ITEM) >= 1u);
        iiit_free(&f);
    } END_TEST;
}
