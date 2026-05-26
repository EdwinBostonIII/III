/* III Grammar — modifier tests (§5.1 + §10.6 canonical sort). */
#include "test.h"

static int parse_one(const char *src, iiit_parse_t *f) {
    return iiit_parse(src, f);
}

void run_modifier_tests(void) {

    TEST_CASE("mod_ring") {
        iiit_parse_t f;
        ASSERT_TRUE(parse_one(
            "module m\nfn a() -> u32 @ring(R0) { return 0 }\n", &f));
        /* Modifier may attach to the function or the return type. */
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_FUNCTION_MODIFIER)
                  + iiit_count_kind(f.root, III_AST_TYPE_MODIFIER) >= 1u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("mod_hexad") {
        iiit_parse_t f;
        ASSERT_TRUE(parse_one(
            "module m\nfn a() -> u32 @hexad(POS,ZERO,POS,ZERO,ZERO,ZERO) { return 0 }\n", &f));
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_FUNCTION_MODIFIER)
                  + iiit_count_kind(f.root, III_AST_TYPE_MODIFIER) >= 1u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("mod_safety_alias_of_hexad") {
        iiit_parse_t f1, f2;
        ASSERT_TRUE(parse_one(
            "module m\nfn a() -> u32 @safety(POS,ZERO,POS,ZERO,ZERO,ZERO) { return 0 }\n", &f1));
        ASSERT_TRUE(parse_one(
            "module m\nfn a() -> u32 @hexad(POS,ZERO,POS,ZERO,ZERO,ZERO) { return 0 }\n", &f2));
        uint8_t h1[32], h2[32];
        iii_ast_mhash(f1.root, h1);
        iii_ast_mhash(f2.root, h2);
        /* @safety is an alias for @hexad — canonical hash must match. */
        ASSERT_MEM_EQ(h1, h2, 32);
        iiit_free(&f1);
        iiit_free(&f2);
    } END_TEST;

    TEST_CASE("mod_pure_irreversible") {
        iiit_parse_t f;
        ASSERT_TRUE(parse_one(
            "module m\ntype X = u32 @pure @irreversible\n", &f));
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_TYPE_MODIFIER) >= 2u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("mod_tier_epoch") {
        iiit_parse_t f;
        ASSERT_TRUE(parse_one(
            "module m\ntype X = u32 @tier(BLAZING) @epoch(42)\n", &f));
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_TYPE_MODIFIER) >= 2u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("mod_cap") {
        iiit_parse_t f;
        ASSERT_TRUE(parse_one(
            "module m\ntype X = u32 @cap(READ, 0..1024)\n", &f));
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_TYPE_MODIFIER) >= 1u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("mod_sanctum_only_witness_elide_hot_path") {
        iiit_parse_t f;
        ASSERT_TRUE(parse_one(
            "module m\nfn a() -> u32 @sanctum_only @witness_elide @hot_path { return 0 }\n", &f));
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_FUNCTION_MODIFIER)
                  + iiit_count_kind(f.root, III_AST_TYPE_MODIFIER) >= 3u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("mod_chronos_bypass_epoch_bridge") {
        iiit_parse_t f;
        ASSERT_TRUE(parse_one(
            "module m\nfn a() -> u32 @chronos_bypass @epoch_bridge { return 0 }\n", &f));
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_FUNCTION_MODIFIER)
                  + iiit_count_kind(f.root, III_AST_TYPE_MODIFIER) >= 2u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("mod_cycle_only_modifiers") {
        iiit_parse_t f;
        ASSERT_TRUE(parse_one(
            "module m\n"
            "cycle c() -> u32 @plan_anchor(plan_x) @admits_caps(R) @prerequisites(x,y)"
            " @replicates(EAGER) @candidate_for_promotion @mobius_coherence(STRICT) {\n"
            "  forward { return 0 }\n"
            "}\n", &f));
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_CYCLE_MODIFIER)
                  + iiit_count_kind(f.root, III_AST_TYPE_MODIFIER)
                  + iiit_count_kind(f.root, III_AST_FUNCTION_MODIFIER) >= 6u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("mod_canonical_sort_invariance") {
        /* Per §10.6: canonical AST serialization sorts modifiers
         * deterministically.  Two source orderings must produce the
         * same mhash. */
        iiit_parse_t f1, f2;
        ASSERT_TRUE(parse_one(
            "module m\nfn a() -> u32 @pure @hot_path @sanctum_only { return 0 }\n", &f1));
        ASSERT_TRUE(parse_one(
            "module m\nfn a() -> u32 @sanctum_only @hot_path @pure { return 0 }\n", &f2));
        uint8_t h1[32], h2[32];
        iii_ast_mhash(f1.root, h1);
        iii_ast_mhash(f2.root, h2);
        ASSERT_MEM_EQ(h1, h2, 32);
        iiit_free(&f1);
        iiit_free(&f2);
    } END_TEST;

    TEST_CASE("mod_canonical_sort_changes_with_content") {
        /* Different modifier contents must produce different hashes. */
        iiit_parse_t f1, f2;
        ASSERT_TRUE(parse_one(
            "module m\nfn a() -> u32 @pure { return 0 }\n", &f1));
        ASSERT_TRUE(parse_one(
            "module m\nfn a() -> u32 @hot_path { return 0 }\n", &f2));
        uint8_t h1[32], h2[32];
        iii_ast_mhash(f1.root, h1);
        iii_ast_mhash(f2.root, h2);
        ASSERT_MEM_NE(h1, h2, 32);
        iiit_free(&f1);
        iiit_free(&f2);
    } END_TEST;
}
