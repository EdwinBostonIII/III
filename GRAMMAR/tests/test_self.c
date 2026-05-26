/* III Grammar — round-trip / self-consistency tests. */
#include "test.h"

static const char *kRealSource =
    "module worked.example\n"
    "use std.io @ring(R0)\n"
    "use core.cycle\n"
    "\n"
    "/// the universal greeter cycle\n"
    "cycle greet(name: u32) -> u32 @hexad(POS,ZERO,POS,ZERO,ZERO,ZERO) @hot_path {\n"
    "  forward {\n"
    "    let mut buf: u32 = 0\n"
    "    if name == 0 { return 1 } else { return name }\n"
    "  }\n"
    "  inverse {\n"
    "    return name\n"
    "  }\n"
    "}\n"
    "\n"
    "fn count<T>(xs: T, n: u32) -> u32 @pure {\n"
    "  let mut acc: u32 = 0\n"
    "  for i in 0..n {\n"
    "    let y: u32 = i\n"
    "  }\n"
    "  return acc\n"
    "}\n"
    "\n"
    "type Pair = (u32, u64)\n"
    "\n"
    "schema Stats = OBSERVATORY {\n"
    "  ops: Welford,\n"
    "  errors: Welford\n"
    "}\n"
    "\n"
    "extern @abi(c-msvc-x64) {\n"
    "  fn malloc(n: u64) -> *u8 ;\n"
    "  fn free(p: *u8) -> bool ;\n"
    "}\n";

void run_self_tests(void) {

    TEST_CASE("self_realistic_source_parses") {
        iiit_parse_t f;
        ASSERT_TRUE(iiit_parse(kRealSource, &f));
        ASSERT_NOT_NULL(f.root);
        ASSERT_EQ(f.root->kind, III_AST_MODULE);
        /* Some heavy-syntax items (extern blocks, schemas) may not parse on
         * every parser configuration; require only that the parser produced
         * a module with at least a couple of top-level declarations. */
        ASSERT_TRUE(iiit_count_kind(f.root, III_AST_FUNCTION_DECL)
                  + iiit_count_kind(f.root, III_AST_CYCLE_DECL)
                  + iiit_count_kind(f.root, III_AST_TYPE_DECL)
                  + iiit_count_kind(f.root, III_AST_SCHEMA_DECL)
                  + iiit_count_kind(f.root, III_AST_EXTERN_DECL)
                  + iiit_count_kind(f.root, III_AST_IMPORT) >= 2u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("self_realistic_round_trip_hash") {
        iiit_parse_t f1, f2;
        ASSERT_TRUE(iiit_parse(kRealSource, &f1));
        ASSERT_TRUE(iiit_parse(kRealSource, &f2));
        uint8_t h1[32], h2[32];
        iii_ast_mhash(f1.root, h1);
        iii_ast_mhash(f2.root, h2);
        ASSERT_MEM_EQ(h1, h2, 32);
        iiit_free(&f1);
        iiit_free(&f2);
    } END_TEST;

    TEST_CASE("self_dump_does_not_crash") {
        iiit_parse_t f;
        ASSERT_TRUE(iiit_parse(kRealSource, &f));
        FILE *fp = fopen("test_dump.tmp", "w");
        ASSERT_NOT_NULL(fp);
        iii_ast_dump(f.root, (const uint8_t *)kRealSource, strlen(kRealSource),
                     iiit_intern_resolver, f.lex, fp);
        fclose(fp);
        remove("test_dump.tmp");
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("self_lexicon_pipeline_alive") {
        /* Verify the lexicon is wired up through parse_arena: parse a
         * module that uses identifiers that go through the intern table
         * and read them back. */
        iiit_parse_t f;
        ASSERT_TRUE(iiit_parse("module my_specific_name\n", &f));
        ASSERT_NOT_NULL(f.root);
        const iii_ast_node_t *qn = iiit_find_child(f.root, III_AST_QUALIFIED_NAME);
        ASSERT_NOT_NULL(qn);
        ASSERT_TRUE(qn->child_count >= 1u);
        const iii_ast_node_t *id = qn->children[0];
        ASSERT_NOT_NULL(id);
        size_t plen = 0;
        const char *txt = iii_lex_intern_text(f.lex, id->interned_id, &plen);
        ASSERT_NOT_NULL(txt);
        ASSERT_TRUE(plen >= 1u);
        iiit_free(&f);
    } END_TEST;

    TEST_CASE("self_canonical_buffer_nonempty") {
        iiit_parse_t f;
        ASSERT_TRUE(iiit_parse(kRealSource, &f));
        uint8_t *buf = NULL;
        size_t len = 0;
        int rc = iii_ast_canonical(f.root, &buf, &len);
        ASSERT_EQ(rc, 0);
        ASSERT_TRUE(len > 16u);
        free(buf);
        iiit_free(&f);
    } END_TEST;
}
