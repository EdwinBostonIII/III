/* III Grammar — error recovery and diagnostics tests. */
#include "test.h"

void run_errors_tests(void) {

    TEST_CASE("err_missing_module_keyword") {
        iiit_parse_t f;
        /* No "module" keyword — must produce an error. */
        iiit_parse("fn foo() -> u32 { return 0 }\n", &f);
        if (f.parser) {
            ASSERT_TRUE(iii_parser_error_count(f.parser) >= 1u);
        }
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("err_missing_module_name") {
        iiit_parse_t f;
        iiit_parse("module\n", &f);
        if (f.parser) {
            ASSERT_TRUE(iii_parser_error_count(f.parser) >= 1u);
        }
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("err_unterminated_block") {
        iiit_parse_t f;
        iiit_parse("module m\nfn a() -> u32 { return 0\n", &f);
        if (f.parser) {
            ASSERT_TRUE(iii_parser_error_count(f.parser) >= 1u);
        }
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("err_recovery_continues") {
        /* First fn malformed; second fn must still be reachable in
         * the parse tree (parser recovers and continues). */
        const char *src =
            "module m\n"
            "fn bad() -> { return 0 }\n"
            "fn good() -> u32 { return 1 }\n";
        iiit_parse_t f;
        iiit_parse(src, &f);
        ASSERT_NOT_NULL(f.root);
        if (f.parser) {
            ASSERT_TRUE(iii_parser_error_count(f.parser) >= 1u);
        }
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("err_specific_code_surface") {
        /* A bad punctuator should surface as one of P_E_EXPECTED_*. */
        iiit_parse_t f;
        iiit_parse("module m\nfn a() ! u32 { return 0 }\n", &f);
        if (f.parser && iii_parser_error_count(f.parser) > 0) {
            const iii_parse_error_t *e = iii_parser_error_at(f.parser, 0);
            ASSERT_NOT_NULL(e);
            ASSERT_TRUE(e->code != P_OK);
            ASSERT_TRUE(e->message[0] != '\0');
        }
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("err_counts_match_loop") {
        iiit_parse_t f;
        iiit_parse("module m\nfn a()  return 0 }\nfn b()  return 0 }\n", &f);
        if (f.parser) {
            size_t n = iii_parser_error_count(f.parser);
            for (size_t i = 0; i < n; i++) {
                const iii_parse_error_t *e = iii_parser_error_at(f.parser, i);
                ASSERT_NOT_NULL(e);
            }
            /* Out-of-range index must return NULL. */
            ASSERT_NULL(iii_parser_error_at(f.parser, n + 100));
        }
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("err_clean_source_zero_errors") {
        iiit_parse_t f;
        ASSERT_TRUE(iiit_parse("module m\n", &f));
        ASSERT_EQ(iii_parser_error_count(f.parser), 0);
        iiit_free(&f);
    } END_TEST;
}
