/* III ERRORS — runtime API over the static catalogue. */
#include "iii/errors.h"
#include <string.h>

size_t iii_error_count_total(void) {
    return iii_error_catalog_len;
}

const iii_error_info_t *iii_error_lookup(iii_error_code_t code) {
    if (code == 0u) return NULL;
    if ((size_t)code > iii_error_catalog_len) return NULL;
    return &iii_error_catalog[(size_t)code - 1u];
}

const iii_error_info_t *iii_error_lookup_by_name(const char *name) {
    if (name == NULL) return NULL;
    for (size_t i = 0; i < iii_error_catalog_len; ++i) {
        if (strcmp(iii_error_catalog[i].name, name) == 0) {
            return &iii_error_catalog[i];
        }
    }
    return NULL;
}

size_t iii_error_iter_by_phase(const char *phase,
                               int (*cb)(const iii_error_info_t *, void *),
                               void *user) {
    if (phase == NULL || cb == NULL) return 0;
    size_t n = 0;
    for (size_t i = 0; i < iii_error_catalog_len; ++i) {
        if (strcmp(iii_error_catalog[i].phase, phase) == 0) {
            ++n;
            if (cb(&iii_error_catalog[i], user) != 0) break;
        }
    }
    return n;
}

size_t iii_error_iter_by_subsystem(const char *subsystem,
                                   int (*cb)(const iii_error_info_t *, void *),
                                   void *user) {
    if (subsystem == NULL || cb == NULL) return 0;
    size_t n = 0;
    for (size_t i = 0; i < iii_error_catalog_len; ++i) {
        if (strcmp(iii_error_catalog[i].subsystem, subsystem) == 0) {
            ++n;
            if (cb(&iii_error_catalog[i], user) != 0) break;
        }
    }
    return n;
}

size_t iii_error_iter_by_prefix(const char *prefix,
                                int (*cb)(const iii_error_info_t *, void *),
                                void *user) {
    if (prefix == NULL || cb == NULL) return 0;
    size_t plen = strlen(prefix);
    size_t n = 0;
    for (size_t i = 0; i < iii_error_catalog_len; ++i) {
        const char *nm = iii_error_catalog[i].name;
        if (strncmp(nm, prefix, plen) == 0) {
            /* Require exact match or hyphen-bounded prefix to avoid e.g.
             * "LEX-EN" matching "LEX-ENC-001" only intentionally. */
            char next = nm[plen];
            if (next == '\0' || next == '-') {
                ++n;
                if (cb(&iii_error_catalog[i], user) != 0) break;
            }
        }
    }
    return n;
}

const char *iii_error_severity_name(iii_error_severity_t s) {
    switch (s) {
        case III_SEV_INFO:         return "INFO";
        case III_SEV_WARN:         return "WARN";
        case III_SEV_ERROR:        return "ERROR";
        case III_SEV_COMPROMISE:   return "COMPROMISE";
        case III_SEV_PANIC:        return "PANIC";
        case III_SEV_CATASTROPHIC: return "CATASTROPHIC";
    }
    return "UNKNOWN";
}
