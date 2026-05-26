/* III Grammar — type production tests (§6). */
#include "test.h"

static int parse_in_const(const char *type_text, iiit_parse_t *f) {
    char buf[1024];
    snprintf(buf, sizeof(buf), "module m\nconst X: %s = 0\n", type_text);
    return iiit_parse(buf, f);
}

void run_type_tests(void) {

    TEST_CASE("type_primitive_u32") {
        iiit_parse_t f;
        ASSERT_TRUE(parse_in_const("u32", &f));
        ASSERT_NOT_NULL(f.root);
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_PRIMITIVE_TYPE)
                  + iiit_count_kind(f.root, III_AST_BASE_TYPE) >= 1u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("type_function") {
        iiit_parse_t f;
        ASSERT_TRUE(parse_in_const("fn(u32, u64) -> bool", &f));
        ASSERT_NOT_NULL(f.root);
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_FUNCTION_TYPE) >= 1u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("type_tuple") {
        iiit_parse_t f;
        ASSERT_TRUE(parse_in_const("(u32, u64)", &f));
        ASSERT_NOT_NULL(f.root);
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_TUPLE_TYPE) >= 1u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("type_array") {
        iiit_parse_t f;
        ASSERT_TRUE(parse_in_const("[u32; 8]", &f));
        ASSERT_NOT_NULL(f.root);
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_ARRAY_TYPE) >= 1u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("type_generic_args") {
        iiit_parse_t f;
        ASSERT_TRUE(parse_in_const("Vec<u32>", &f));
        ASSERT_NOT_NULL(f.root);
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_GENERIC_ARGS) >= 1u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("type_cap_perm_range") {
        iiit_parse_t f;
        ASSERT_TRUE(parse_in_const("Cap<READ, 0..1024>", &f));
        ASSERT_NOT_NULL(f.root);
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_BASE_TYPE) >= 1u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("type_hexad") {
        iiit_parse_t f;
        ASSERT_TRUE(parse_in_const("Hexad", &f));
        ASSERT_NOT_NULL(f.root);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("type_phase") {
        iiit_parse_t f;
        ASSERT_TRUE(parse_in_const("Phase", &f));
        ASSERT_NOT_NULL(f.root);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("type_hole") {
        iiit_parse_t f;
        ASSERT_TRUE(parse_in_const("?", &f));
        ASSERT_NOT_NULL(f.root);
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_HOLE) >= 1u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("type_with_ring_modifier") {
        iiit_parse_t f;
        ASSERT_TRUE(parse_in_const("u32 @ring(R0)", &f));
        ASSERT_NOT_NULL(f.root);
        iiit_free(&f);
    } END_TEST;
}
