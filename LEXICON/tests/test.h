/* Tiny test framework. */
#ifndef IIIT_TEST_H
#define IIIT_TEST_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include "iii/lex.h"

extern int iiit_pass;
extern int iiit_fail;
extern const char *iiit_current;

#define IIIT_BEGIN(name) do { iiit_current = name; printf("  [TEST] %-50s ", name); fflush(stdout); } while (0)
#define IIIT_OK()        do { printf("ok\n"); iiit_pass++; } while (0)
#define IIIT_FAIL(msg, ...) do { printf("FAIL\n    " msg "\n", ##__VA_ARGS__); iiit_fail++; return; } while (0)

#define IIIT_ASSERT(cond, msg, ...) do { if (!(cond)) { IIIT_FAIL(msg, ##__VA_ARGS__); } } while (0)

/* Lex a buffer once and return number of tokens (excluding EOF) plus errors. */
typedef struct {
    iii_token_t toks[2048];
    size_t n;
    size_t errs;
} iiit_run_t;

void iiit_run(const char *src, iiit_run_t *out);

void run_test_sha256(void);
void run_test_utf8(void);
void run_test_keywords(void);
void run_test_literals(void);
void run_test_strings(void);
void run_test_operators(void);
void run_test_punct(void);
void run_test_comments(void);
void run_test_errors(void);
void run_test_canonical(void);
void run_test_self(void);

#endif
