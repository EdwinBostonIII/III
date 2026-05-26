/* ============================================================================
 * III-CONFORMANCE — The 33 Conformance Criteria + Verifier
 * Spec: III-CONFORMANCE.md  (Doc-ID B3, R1.B3)
 *
 * Implements the conformance verifier: 33 criteria across four groups
 * (Core Language C-1..C-15, Substrate C-16..C-25, Cognitive C-26..C-30,
 * Resolution C-31..C-33).  C-31..C-33 were added by FROZEN SPEC
 * III-RES-FROZEN-001 §14 (ADR-RES-011 / ADR-RES-006); see III-CONFORMANCE.md
 * §7.  Tests can be plugged in at runtime; the verifier reports pass/fail/skip
 * with total compliance percentage.
 * ============================================================================
 */
#ifndef III_CONFORMANCE_H
#define III_CONFORMANCE_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

#define III_CONF_COUNT  33u

typedef enum iii_conf_group {
    III_CG_CORE_LANGUAGE = 0,    /* C-1..C-15  */
    III_CG_SUBSTRATE     = 1,    /* C-16..C-25 */
    III_CG_COGNITIVE     = 2,    /* C-26..C-30 */
    III_CG_RESOLUTION    = 3     /* C-31..C-33 (FROZEN SPEC III-RES-FROZEN-001) */
} iii_conf_group_t;

const char *iii_conf_group_name(iii_conf_group_t g);

typedef struct iii_conf_criterion {
    uint32_t          number;             /* 1..33 */
    iii_conf_group_t  group;
    const char       *code;               /* "C-1" */
    const char       *title;
    const char       *test_path;          /* "TESTS/conformance/closure_root_determinism.III" */
} iii_conf_criterion_t;

const iii_conf_criterion_t *iii_conf_criterion_at(unsigned idx);
const iii_conf_criterion_t *iii_conf_criterion_lookup(const char *code);

/* ----------------------------------------------------------------------------
 * Verifier
 * ---------------------------------------------------------------------------- */
typedef enum iii_conf_status {
    III_CR_NONE     = 0,
    III_CR_PASS     = 1,
    III_CR_FAIL     = 2,
    III_CR_SKIP     = 3
} iii_conf_status_t;

const char *iii_conf_status_name(iii_conf_status_t s);

typedef int (*iii_conf_test_fn)(void *user);

typedef struct iii_conf_verifier iii_conf_verifier_t;

iii_conf_verifier_t *iii_conf_verifier_create(void);
void                 iii_conf_verifier_destroy(iii_conf_verifier_t *v);

/* Bind a test function to a criterion.  Returns false if the criterion
 * doesn't exist or is already bound. */
bool iii_conf_bind_test(iii_conf_verifier_t *v,
                        const char           *code,
                        iii_conf_test_fn      fn,
                        void                 *user);

/* Run all bound criteria; unbound ones are SKIP. */
typedef struct iii_conf_result {
    iii_conf_status_t status[III_CONF_COUNT];
    unsigned          passed;
    unsigned          failed;
    unsigned          skipped;
    uint16_t          compliance_q14;     /* passed / (passed + failed) */
} iii_conf_result_t;

void iii_conf_run(iii_conf_verifier_t *v, iii_conf_result_t *out);

/* The verifier is closure-pinned: callers can record/verify a known mhash. */
void iii_conf_verifier_set_pin(iii_conf_verifier_t *v, const uint8_t pin[32]);
bool iii_conf_verifier_check_pin(const iii_conf_verifier_t *v, const uint8_t expected[32]);

/* ----------------------------------------------------------------------------
 * Pretty-print summary
 * ---------------------------------------------------------------------------- */
size_t iii_conf_format_result(const iii_conf_result_t *r, char *out, size_t cap);

#ifdef __cplusplus
}
#endif

#endif /* III_CONFORMANCE_H */
