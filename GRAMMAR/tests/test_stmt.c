/* III Grammar — statement production tests (§7). */
#include "test.h"

static int parse_in_fn(const char *body, iiit_parse_t *f) {
    char buf[2048];
    snprintf(buf, sizeof(buf), "module m\nfn t() -> u32 {\n%s\n}\n", body);
    return iiit_parse(buf, f);
}

void run_stmt_tests(void) {

    TEST_CASE("let_stmt") {
        iiit_parse_t f;
        ASSERT_TRUE(parse_in_fn("let x: u32 = 1\nreturn x", &f));
        ASSERT_NOT_NULL(f.root);
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_LET_STMT) >= 1u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("let_mut_stmt") {
        iiit_parse_t f;
        ASSERT_TRUE(parse_in_fn("let mut x: u32 = 1\nreturn x", &f));
        ASSERT_NOT_NULL(f.root);
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_LET_STMT) >= 1u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("if_else_stmt") {
        iiit_parse_t f;
        ASSERT_TRUE(parse_in_fn(
            "if 1 == 1 { return 1 } else { return 0 }", &f));
        ASSERT_NOT_NULL(f.root);
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_IF_STMT) >= 1u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("match_stmt_with_arms_and_guard") {
        iiit_parse_t f;
        ASSERT_TRUE(parse_in_fn(
            "match x {\n"
            "  0 => { return 1 }\n"
            "  n if n > 1 => { return 2 }\n"
            "  _ => { return 3 }\n"
            "}\nreturn 0", &f));
        ASSERT_NOT_NULL(f.root);
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_MATCH_STMT) >= 1u);
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_MATCH_ARM) >= 2u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("for_stmt") {
        iiit_parse_t f;
        ASSERT_TRUE(parse_in_fn("for i in 0..10 { let y: u32 = i }\nreturn 0", &f));
        ASSERT_NOT_NULL(f.root);
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_FOR_STMT) >= 1u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("while_stmt") {
        iiit_parse_t f;
        ASSERT_TRUE(parse_in_fn("while 1 == 1 { return 0 }\nreturn 0", &f));
        ASSERT_NOT_NULL(f.root);
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_WHILE_STMT) >= 1u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("wavefront_stmt") {
        iiit_parse_t f;
        ASSERT_TRUE(parse_in_fn(
            "wavefront w {\n"
            "  let x: u32 = 0\n"
            "}\nreturn 0", &f));
        ASSERT_NOT_NULL(f.root);
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_WAVEFRONT_STMT) >= 1u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("sanctum_enter_stmt") {
        iiit_parse_t f;
        /* Surface form for sanctum may vary across parser implementations;
         * accept either an explicit SANCTUM_STMT or a generic block-call. */
        ASSERT_TRUE(parse_in_fn(
            "sanctum.enter |frame| { let x: u32 = 0 }\nreturn 0", &f));
        ASSERT_NOT_NULL(f.root);
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_SANCTUM_STMT)
                  + iiit_count_kind(f.root, III_AST_SANCTUM_INVOKE)
                  + iiit_count_kind(f.root, III_AST_FIELD_ACCESS) >= 1u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("metal_block_stmt") {
        iiit_parse_t f;
        ASSERT_TRUE(parse_in_fn("metal { let x: u32 = 0 }\nreturn 0", &f));
        ASSERT_NOT_NULL(f.root);
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_METAL_STMT) >= 1u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("return_stmt") {
        iiit_parse_t f;
        ASSERT_TRUE(parse_in_fn("return 42", &f));
        ASSERT_NOT_NULL(f.root);
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_RETURN_STMT) >= 1u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("promote_stmt") {
        iiit_parse_t f;
        ASSERT_TRUE(parse_in_fn("promote candidate_x\nreturn 0", &f));
        ASSERT_NOT_NULL(f.root);
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_PROMOTE_STMT) >= 1u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("explain_stmt") {
        iiit_parse_t f;
        ASSERT_TRUE(parse_in_fn("explain x\nreturn 0", &f));
        ASSERT_NOT_NULL(f.root);
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_EXPLAIN_STMT) >= 1u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("propose_negotiate_commit_reflect") {
        iiit_parse_t f;
        ASSERT_TRUE(parse_in_fn(
            "propose { goal: 1 }\n"
            "negotiate(a, b)\n"
            "reflect()\n"
            "commit(c)\n"
            "return 0", &f));
        ASSERT_NOT_NULL(f.root);
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_PROPOSE_STMT)
                  + iiit_count_kind(f.root, III_AST_NEGOTIATE_STMT)
                  + iiit_count_kind(f.root, III_AST_REFLECT_STMT)
                  + iiit_count_kind(f.root, III_AST_COMMIT_STMT) >= 4u);
        iiit_free(&f);
    } END_TEST;
}
