/* III Grammar — minimal test harness.
 *
 * Modeled after LEXICON/tests/test.h.  Each test suite defines a
 * `void run_X_tests(void)` function which is called by test_main.c.
 * Inside a suite, individual tests use TEST_CASE(name) { ... } blocks
 * delimited by END_TEST.  ASSERT_* macros bump iiit_fail and `return`
 * out of the current test function on failure.
 *
 * NIH: only libc + the iii public API.
 */
#ifndef III_GRAMMAR_TEST_H
#define III_GRAMMAR_TEST_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stddef.h>

#include "iii/lex.h"
#include "iii/ast.h"
#include "iii/parse_arena.h"
#include "iii/parser.h"
#include "iii/ast_print.h"

extern int iiit_pass;
extern int iiit_fail;
extern const char *iiit_current;

#define TEST_CASE(name)                                                       \
    do {                                                                      \
        iiit_current = name;                                                  \
        printf("  [TEST] %-58s ", name);                                      \
        fflush(stdout);                                                       \
        int _iiit_failed_in_case = 0;                                         \
        do
#define END_TEST                                                              \
        while (0);                                                            \
        if (!_iiit_failed_in_case) { printf("ok\n"); iiit_pass++; }           \
    } while (0)

#define _IIIT_FAIL_IMPL(fmt, ...)                                             \
    do {                                                                      \
        if (!_iiit_failed_in_case) {                                          \
            printf("FAIL\n");                                                 \
            iiit_fail++;                                                      \
            _iiit_failed_in_case = 1;                                         \
        }                                                                     \
        printf("    %s:%d: " fmt "\n", __FILE__, __LINE__, ##__VA_ARGS__);    \
        break;                                                                \
    } while (0)

#define ASSERT_TRUE(cond)                                                     \
    do { if (!(cond)) _IIIT_FAIL_IMPL("ASSERT_TRUE failed: %s", #cond); } while (0)

#define ASSERT_FALSE(cond)                                                    \
    do { if ((cond)) _IIIT_FAIL_IMPL("ASSERT_FALSE failed: %s", #cond); } while (0)

#define ASSERT_EQ(a, b)                                                       \
    do {                                                                      \
        long long _aa = (long long)(a), _bb = (long long)(b);                 \
        if (_aa != _bb)                                                       \
            _IIIT_FAIL_IMPL("ASSERT_EQ failed: %s=%lld vs %s=%lld",           \
                            #a, _aa, #b, _bb);                                \
    } while (0)

#define ASSERT_STR_EQ(a, b)                                                   \
    do {                                                                      \
        const char *_aa = (a), *_bb = (b);                                    \
        if (!_aa || !_bb || strcmp(_aa, _bb) != 0)                            \
            _IIIT_FAIL_IMPL("ASSERT_STR_EQ failed: \"%s\" vs \"%s\"",         \
                            _aa ? _aa : "(null)", _bb ? _bb : "(null)");     \
    } while (0)

#define ASSERT_NULL(p)                                                        \
    do { if ((p) != NULL) _IIIT_FAIL_IMPL("ASSERT_NULL failed: %s", #p); } while (0)

#define ASSERT_NOT_NULL(p)                                                    \
    do { if ((p) == NULL) _IIIT_FAIL_IMPL("ASSERT_NOT_NULL failed: %s", #p); } while (0)

#define ASSERT_MEM_EQ(a, b, n)                                                \
    do {                                                                      \
        if (memcmp((a), (b), (n)) != 0)                                       \
            _IIIT_FAIL_IMPL("ASSERT_MEM_EQ failed (%zu bytes)", (size_t)(n)); \
    } while (0)

#define ASSERT_MEM_NE(a, b, n)                                                \
    do {                                                                      \
        if (memcmp((a), (b), (n)) == 0)                                       \
            _IIIT_FAIL_IMPL("ASSERT_MEM_NE failed (%zu bytes)", (size_t)(n)); \
    } while (0)

/* ---- Shared fixture: one-shot parse of a literal C string ------------- */

typedef struct {
    iii_lex_state_t *lex;
    iii_arena_t     *arena;
    iii_parser_t    *parser;
    iii_ast_node_t  *root;
    const char      *src;
    size_t           src_len;
} iiit_parse_t;

/* Parse `src` into a fresh fixture.  Returns 1 on success (root != NULL),
 * 0 on hard parser-create failure.  Caller must call iiit_free() when done. */
int  iiit_parse(const char *src, iiit_parse_t *out);

/* Release everything in `f`.  Safe on a partially-initialised fixture. */
void iiit_free(iiit_parse_t *f);

/* Resolver callback bridging iii_ast_dump → lex intern table. */
const char *iiit_intern_resolver(uint32_t id, size_t *out_len, void *ud);

/* Find the first child of `n` whose kind == k.  Returns NULL if none. */
const iii_ast_node_t *iiit_find_child(const iii_ast_node_t *n, iii_ast_kind_t k);

/* Recursively count nodes of a given kind in `n`. */
size_t iiit_count_kind(const iii_ast_node_t *n, iii_ast_kind_t k);

/* Recursively count error nodes (III_AST_ERROR or III_AST_RECOVERY). */
size_t iiit_count_error_nodes(const iii_ast_node_t *n);

/* Suite runner declarations. */
void run_module_tests(void);
void run_decl_tests(void);
void run_type_tests(void);
void run_stmt_tests(void);
void run_expr_tests(void);
void run_pat_tests(void);
void run_modifier_tests(void);
void run_canonical_tests(void);
void run_errors_tests(void);
void run_self_tests(void);

#endif
