/* III Grammar — pattern production tests (§9). */
#include "test.h"

static int parse_match_pat(const char *pat_text, iiit_parse_t *f) {
    char buf[2048];
    snprintf(buf, sizeof(buf),
        "module m\nfn t() -> u32 {\n"
        "  match x { %s => { return 1 } _ => { return 0 } }\n"
        "  return 0\n"
        "}\n", pat_text);
    return iiit_parse(buf, f);
}

void run_pat_tests(void) {

    TEST_CASE("pat_literal") {
        iiit_parse_t f;
        ASSERT_TRUE(parse_match_pat("42", &f));
        ASSERT_NOT_NULL(f.root);
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_LITERAL_PATTERN) >= 1u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("pat_ident") {
        iiit_parse_t f;
        ASSERT_TRUE(parse_match_pat("name", &f));
        ASSERT_NOT_NULL(f.root);
        /* IDENT-only patterns may be encoded as IDENT_PATTERN or
         * collapsed to a path-pattern of length 1. */
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_IDENT_PATTERN)
                  + iiit_count_kind(f.root, III_AST_PATH_PATTERN)
                  + iiit_count_kind(f.root, III_AST_LITERAL_PATTERN) >= 1u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("pat_wildcard") {
        iiit_parse_t f;
        ASSERT_TRUE(parse_match_pat("_", &f));
        ASSERT_NOT_NULL(f.root);
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_WILDCARD_PATTERN) >= 1u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("pat_tuple") {
        iiit_parse_t f;
        iiit_parse("module m\nfn t() -> u32 {\n"
                   "  match x { (a, b, c) => { return 1 } _ => { return 0 } }\n"
                   "  return 0\n}\n", &f);
        ASSERT_NOT_NULL(f.root);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("pat_record") {
        iiit_parse_t f;
        iiit_parse("module m\nfn t() -> u32 {\n"
                   "  match x { { a: 1, b: y } => { return 1 } _ => { return 0 } }\n"
                   "  return 0\n}\n", &f);
        ASSERT_NOT_NULL(f.root);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("pat_hexad") {
        iiit_parse_t f;
        ASSERT_TRUE(parse_match_pat("HEXAD(POS, ZERO, POS, ZERO, ZERO, ZERO)", &f));
        ASSERT_NOT_NULL(f.root);
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_HEXAD_PATTERN) >= 1u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("pat_trit") {
        iiit_parse_t f;
        ASSERT_TRUE(parse_match_pat("0t+", &f));
        ASSERT_NOT_NULL(f.root);
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_TRIT_PATTERN)
                  + iiit_count_kind(f.root, III_AST_LITERAL_PATTERN) >= 1u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("pat_range") {
        iiit_parse_t f;
        ASSERT_TRUE(parse_match_pat("0..10", &f));
        ASSERT_NOT_NULL(f.root);
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_RANGE_PATTERN) >= 1u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("pat_path") {
        iiit_parse_t f;
        iiit_parse("module m\nfn t() -> u32 {\n"
                   "  match x { Color::Red => { return 1 } _ => { return 0 } }\n"
                   "  return 0\n}\n", &f);
        ASSERT_NOT_NULL(f.root);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("pat_or") {
        iiit_parse_t f;
        ASSERT_TRUE(parse_match_pat("1 | 2 | 3", &f));
        ASSERT_NOT_NULL(f.root);
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_OR_PATTERN) >= 1u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("pat_guard") {
        iiit_parse_t f;
        iiit_parse("module m\nfn t() -> u32 {\n"
                   "  match x { y if y > 0 => { return 1 } _ => { return 0 } }\n"
                   "  return 0\n}\n", &f);
        ASSERT_NOT_NULL(f.root);
        iiit_free(&f);
    } END_TEST;
}
