/* III Grammar — module-level production tests (§4). */
#include "test.h"

void run_module_tests(void) {

    TEST_CASE("module_empty") {
        iiit_parse_t f;
        ASSERT_TRUE(iiit_parse("module foo\n", &f));
        ASSERT_NOT_NULL(f.root);
        ASSERT_EQ(f.root->kind, III_AST_MODULE);
        ASSERT_EQ(iii_parser_error_count(f.parser), 0);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("module_qualified_name_dotted") {
        iiit_parse_t f;
        ASSERT_TRUE(iiit_parse("module a.b.c\n", &f));
        ASSERT_NOT_NULL(f.root);
        ASSERT_EQ(f.root->kind, III_AST_MODULE);
        const iii_ast_node_t *qn = iiit_find_child(f.root, III_AST_QUALIFIED_NAME);
        ASSERT_NOT_NULL(qn);
        /* dotted name produces ≥3 IDENT-bearing children */
        ASSERT_TRUE(qn->child_count >= 3);
        ASSERT_EQ(iii_parser_error_count(f.parser), 0);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("module_with_closure_attr") {
        const char *src =
            "module m @closure(0x"
            "0000000000000000000000000000000000000000000000000000000000000000)\n";
        iiit_parse_t f;
        ASSERT_TRUE(iiit_parse(src, &f));
        ASSERT_NOT_NULL(f.root);
        ASSERT_EQ(f.root->kind, III_AST_MODULE);
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_MODULE_ATTR) >= 1);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("module_with_ring_attr") {
        iiit_parse_t f;
        ASSERT_TRUE(iiit_parse("module m @ring(R0)\n", &f));
        ASSERT_NOT_NULL(f.root);
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_MODULE_ATTR) >= 1);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("module_with_imports") {
        const char *src =
            "module m\n"
            "use std.io\n"
            "use core.cycle\n";
        iiit_parse_t f;
        ASSERT_TRUE(iiit_parse(src, &f));
        ASSERT_NOT_NULL(f.root);
        ASSERT_EQ(iiit_count_kind(f.root, III_AST_IMPORT), 2u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("module_import_with_attrs") {
        const char *src =
            "module m\n"
            "use std.io @ring(R0) @tier(BLAZING)\n";
        iiit_parse_t f;
        ASSERT_TRUE(iiit_parse(src, &f));
        ASSERT_NOT_NULL(f.root);
        ASSERT_EQ(iiit_count_kind(f.root, III_AST_IMPORT), 1u);
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_IMPORT_ATTR) >= 2);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("module_doc_attached") {
        const char *src =
            "module m\n"
            "/// a doc comment\n"
            "fn foo() -> u32 { return 0 }\n";
        iiit_parse_t f;
        ASSERT_TRUE(iiit_parse(src, &f));
        ASSERT_NOT_NULL(f.root);
        const iii_ast_node_t *fn = iiit_find_child(f.root, III_AST_FUNCTION_DECL);
        ASSERT_NOT_NULL(fn);
        ASSERT_TRUE(fn->doc_offset != III_AST_NO_DOC);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("module_multiple_items") {
        const char *src =
            "module m\n"
            "fn a() -> u32 { return 1 }\n"
            "fn b() -> u32 { return 2 }\n"
            "fn c() -> u32 { return 3 }\n";
        iiit_parse_t f;
        ASSERT_TRUE(iiit_parse(src, &f));
        ASSERT_NOT_NULL(f.root);
        ASSERT_EQ(iiit_count_kind(f.root, III_AST_FUNCTION_DECL), 3u);
        iiit_free(&f);
    } END_TEST;
}
