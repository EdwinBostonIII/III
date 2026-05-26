/* III Grammar — canonical AST serialization / mhash tests (§10.6). */
#include "test.h"

void run_canonical_tests(void) {

    TEST_CASE("canonical_idempotent") {
        const char *src =
            "module m\n"
            "fn id(x: u32) -> u32 { return x }\n";
        iiit_parse_t f1, f2;
        ASSERT_TRUE(iiit_parse(src, &f1));
        ASSERT_TRUE(iiit_parse(src, &f2));
        uint8_t h1[32], h2[32];
        iii_ast_mhash(f1.root, h1);
        iii_ast_mhash(f2.root, h2);
        ASSERT_MEM_EQ(h1, h2, 32);
        iiit_free(&f1);
        iiit_free(&f2);
    } END_TEST;

    TEST_CASE("canonical_differs_with_content") {
        iiit_parse_t f1, f2;
        ASSERT_TRUE(iiit_parse("module m\nfn a() -> u32 { return 1 }\n", &f1));
        ASSERT_TRUE(iiit_parse("module m\nfn a() -> u32 { return 2 }\n", &f2));
        uint8_t h1[32], h2[32];
        iii_ast_mhash(f1.root, h1);
        iii_ast_mhash(f2.root, h2);
        ASSERT_MEM_NE(h1, h2, 32);
        iiit_free(&f1);
        iiit_free(&f2);
    } END_TEST;

    TEST_CASE("canonical_independent_of_whitespace") {
        const char *src1 =
            "module m\n"
            "fn id(x: u32) -> u32 { return x }\n";
        const char *src2 =
            "module m\n\n"
            "fn id(x: u32) -> u32 {\n"
            "    return x\n"
            "}\n\n";
        iiit_parse_t f1, f2;
        ASSERT_TRUE(iiit_parse(src1, &f1));
        ASSERT_TRUE(iiit_parse(src2, &f2));
        uint8_t h1[32], h2[32];
        iii_ast_mhash(f1.root, h1);
        iii_ast_mhash(f2.root, h2);
        ASSERT_MEM_EQ(h1, h2, 32);
        iiit_free(&f1);
        iiit_free(&f2);
    } END_TEST;

    TEST_CASE("canonical_buffer_returned") {
        iiit_parse_t f;
        ASSERT_TRUE(iiit_parse("module m\n", &f));
        uint8_t *buf = NULL;
        size_t len = 0;
        int rc = iii_ast_canonical(f.root, &buf, &len);
        ASSERT_EQ(rc, 0);
        ASSERT_NOT_NULL(buf);
        ASSERT_TRUE(len > 0);
        free(buf);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("canonical_module_name_changes_hash") {
        iiit_parse_t f1, f2;
        ASSERT_TRUE(iiit_parse("module foo\n", &f1));
        ASSERT_TRUE(iiit_parse("module bar\n", &f2));
        uint8_t h1[32], h2[32];
        iii_ast_mhash(f1.root, h1);
        iii_ast_mhash(f2.root, h2);
        ASSERT_MEM_NE(h1, h2, 32);
        iiit_free(&f1);
        iiit_free(&f2);
    } END_TEST;

    TEST_CASE("canonical_hash_has_nonzero_bytes") {
        iiit_parse_t f;
        ASSERT_TRUE(iiit_parse("module m\n", &f));
        uint8_t h[32];
        iii_ast_mhash(f.root, h);
        int any_nonzero = 0;
        for (int i = 0; i < 32; i++) if (h[i]) { any_nonzero = 1; break; }
        ASSERT_TRUE(any_nonzero);
        iiit_free(&f);
    } END_TEST;
}
