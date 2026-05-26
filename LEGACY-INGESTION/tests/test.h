/* Tiny test framework. */
#ifndef IIIT_LEGACY_TEST_H
#define IIIT_LEGACY_TEST_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include "iii/legacy.h"

extern int iiit_pass;
extern int iiit_fail;

#define IIIT_BEGIN(name) do { printf("  [TEST] %-55s ", name); fflush(stdout); } while (0)
#define IIIT_OK()        do { printf("ok\n"); iiit_pass++; } while (0)
#define IIIT_FAIL(msg, ...) do { printf("FAIL\n    " msg "\n", ##__VA_ARGS__); iiit_fail++; return; } while (0)
#define IIIT_ASSERT(cond, msg, ...) do { if (!(cond)) { IIIT_FAIL(msg, ##__VA_ARGS__); } } while (0)

void run_test_detect(void);
void run_test_elf(void);
void run_test_pe(void);
void run_test_macho(void);
void run_test_macho_fat(void);
void run_test_coff(void);
void run_test_normalize(void);
void run_test_syscall(void);
void run_test_sandbox(void);

#endif
