/* III ERRORS — Unified error-code namespace.
 * Implements DOCS/III-ERRORS.md (Wave 0.3).
 * Public, stable C11 API. Catalogue is static (no runtime loading). */
#ifndef III_ERRORS_H
#define III_ERRORS_H

#include <stddef.h>
#include <stdint.h>
#include "iii/errors_codes.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
    III_SEV_INFO         = 0,
    III_SEV_WARN         = 1,
    III_SEV_ERROR        = 2,
    III_SEV_COMPROMISE   = 3,
    III_SEV_PANIC        = 4,
    III_SEV_CATASTROPHIC = 5
} iii_error_severity_t;

typedef struct {
    iii_error_code_t      code;
    const char           *name;        /* "LEX-ENC-001" */
    const char           *phase;       /* "LEX" */
    const char           *subsystem;   /* "ENC" */
    const char           *suffix;      /* "001" */
    iii_error_severity_t  severity;
    const char           *description;
    const char           *remediation;
} iii_error_info_t;

typedef struct {
    const char *prefix;   /* "LEX" */
    const char *display;  /* "compile_lex" */
} iii_phase_info_t;

/* Static catalogue — defined in src/errors_catalog.c */
extern const iii_error_info_t iii_error_catalog[];
extern const size_t           iii_error_catalog_len;
extern const iii_phase_info_t iii_phase_table[];
extern const size_t           iii_phase_table_len;

/* ---- API ---- */

/* Total number of registered error codes (excludes III_E_INVALID). */
size_t iii_error_count_total(void);

/* Lookup by numeric code; returns NULL if code is 0 or out of range. */
const iii_error_info_t *iii_error_lookup(iii_error_code_t code);

/* Lookup by canonical textual name (e.g., "LEX-ENC-001"); NULL if absent. */
const iii_error_info_t *iii_error_lookup_by_name(const char *name);

/* Iterate all errors whose phase prefix matches `phase` (e.g., "LEX").
 * `cb` is called once per matching entry. Returns count visited.
 * Iteration stops early if cb returns non-zero. */
size_t iii_error_iter_by_phase(const char *phase,
                               int (*cb)(const iii_error_info_t *, void *),
                               void *user);

/* Iterate all errors whose subsystem matches (e.g., "ENC", "GATE"). */
size_t iii_error_iter_by_subsystem(const char *subsystem,
                                   int (*cb)(const iii_error_info_t *, void *),
                                   void *user);

/* Iterate by code prefix (e.g., "LEX-ENC" matches LEX-ENC-*). */
size_t iii_error_iter_by_prefix(const char *prefix,
                                int (*cb)(const iii_error_info_t *, void *),
                                void *user);

/* Severity name → constant string. */
const char *iii_error_severity_name(iii_error_severity_t s);

#ifdef __cplusplus
}
#endif

#endif /* III_ERRORS_H */
