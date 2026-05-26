/* iii_errors_test — verifies catalogue invariants. */
#include "iii/errors.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

static int g_pass = 0;
static int g_fail = 0;

#define CHECK(cond, msg) do {                                      \
    if (cond) { ++g_pass; }                                        \
    else { ++g_fail; fprintf(stderr,                               \
        "FAIL [%s:%d] %s\n", __FILE__, __LINE__, msg); }           \
} while (0)

static int count_cb(const iii_error_info_t *e, void *u) {
    (void)e; ++*(size_t *)u; return 0;
}

static int t_total_count(void) {
    size_t n = iii_error_count_total();
    CHECK(n == iii_error_catalog_len, "count==catalog_len");
    /* Spec has at least 174 enumerated codes + 13 renames = 187; we expect 190. */
    CHECK(n >= 187, "total >= 187 entries");
    return 0;
}

static int t_every_code_resolves(void) {
    for (size_t i = 0; i < iii_error_catalog_len; ++i) {
        iii_error_code_t code = iii_error_catalog[i].code;
        const iii_error_info_t *e = iii_error_lookup(code);
        CHECK(e != NULL, "lookup non-null");
        CHECK(e == &iii_error_catalog[i], "lookup identity");
        CHECK(e->name != NULL && e->name[0] != '\0', "name non-empty");
        CHECK(e->phase != NULL && e->phase[0] != '\0', "phase non-empty");
        CHECK(e->subsystem != NULL, "subsystem non-null");
        CHECK(e->description != NULL && e->description[0] != '\0', "desc non-empty");
        CHECK(e->remediation != NULL && e->remediation[0] != '\0', "remediation non-empty");
    }
    return 0;
}

static int t_invalid_code(void) {
    CHECK(iii_error_lookup(0) == NULL, "code 0 invalid");
    CHECK(iii_error_lookup((iii_error_code_t)(iii_error_catalog_len + 1)) == NULL,
          "code > max invalid");
    CHECK(iii_error_lookup_by_name("DOES-NOT-EXIST-999") == NULL, "bogus name -> NULL");
    CHECK(iii_error_lookup_by_name(NULL) == NULL, "NULL name -> NULL");
    return 0;
}

static int t_no_duplicate_codes(void) {
    for (size_t i = 0; i < iii_error_catalog_len; ++i) {
        for (size_t j = i + 1; j < iii_error_catalog_len; ++j) {
            if (strcmp(iii_error_catalog[i].name, iii_error_catalog[j].name) == 0) {
                ++g_fail;
                fprintf(stderr, "FAIL: duplicate code %s at %zu and %zu\n",
                        iii_error_catalog[i].name, i, j);
                return 1;
            }
        }
    }
    ++g_pass;
    return 0;
}

static int t_no_duplicate_ids(void) {
    for (size_t i = 0; i < iii_error_catalog_len; ++i) {
        if (iii_error_catalog[i].code != (iii_error_code_t)(i + 1)) {
            ++g_fail;
            fprintf(stderr, "FAIL: code id %u at index %zu not sequential\n",
                    (unsigned)iii_error_catalog[i].code, i);
            return 1;
        }
    }
    ++g_pass;
    return 0;
}

static int t_roundtrip(void) {
    for (size_t i = 0; i < iii_error_catalog_len; ++i) {
        const iii_error_info_t *byname = iii_error_lookup_by_name(iii_error_catalog[i].name);
        CHECK(byname == &iii_error_catalog[i], "name -> entry roundtrip");
        const iii_error_info_t *bycode = iii_error_lookup(byname->code);
        CHECK(bycode == byname, "code -> entry roundtrip");
    }
    return 0;
}

static int t_every_phase_enumerates(void) {
    size_t total_via_phases = 0;
    for (size_t p = 0; p < iii_phase_table_len; ++p) {
        size_t n = 0;
        size_t visited = iii_error_iter_by_phase(iii_phase_table[p].prefix, count_cb, &n);
        CHECK(visited == n, "iter return == cb count");
        total_via_phases += n;
        if (n == 0) {
            /* SID phase legitimately has no top-level codes (TYPE-SID-* live under TYPE).
             * Allow zero only for SID. */
            CHECK(strcmp(iii_phase_table[p].prefix, "SID") == 0,
                  "phase has at least one entry (except SID)");
        }
    }
    CHECK(total_via_phases == iii_error_catalog_len,
          "sum across phases == total catalog");
    return 0;
}

static int t_phase_membership_matches_name(void) {
    for (size_t i = 0; i < iii_error_catalog_len; ++i) {
        const iii_error_info_t *e = &iii_error_catalog[i];
        size_t plen = strlen(e->phase);
        CHECK(strncmp(e->name, e->phase, plen) == 0, "name starts with phase prefix");
        CHECK(e->name[plen] == '-', "phase prefix terminated by '-'");
    }
    return 0;
}

static int t_known_codes_present(void) {
    static const char *must_have[] = {
        "LEX-ENC-001", "LEX-ID-001", "LEX-Q14-001", "LEX-STR-004",
        "PARSE-CYCLE-001", "PARSE-SEAL-001",
        "TYPE-HEXAD-001", "TYPE-MOD-006", "TYPE-LIN-001", "TYPE-SAN-001",
        "TYPE-SEAL-002", "TYPE-SID-005", "TYPE-WAAC-001",
        "PROOF-UNIV-001", "PROOF-CERT-002",
        "CG-EMIT-001", "LINK-CLOSURE-001",
        "MOD-RES-001", "RUN-CYCLE-001",
        "TRIN-L1-SCBA-REJECT", "TRIN-L3-CEILING-VIOLATION", "TRIN-ALL-HEXAD-UNREP",
        "CAT-GATE-008", "CAT-PROMOTE-REVOKED",
        "SAN-DRTM-CHAIN-001",
        "FED-IOMMU-IOPT-001",
        "WIT-BCWL-001",
        "CONF-VERIFIER-001", "REPLAY-DECOMMIT-001",
        "FNDR-ANCHOR-REMOVAL-ATTEMPT", "FNDR-SHAMIR-002",
        "CRYPTO-DILITHIUM-001", "CRYPTO-VDF-001",
        "ZK-ROLLUP-004",
        "GENESIS-SECURE-BOOT-001",
        "PANIC-FOUNDERS-ANCHOR-CORRUPTION", "PANIC-PROOF-KERNEL-001",
        "CONF-RENAME-A1", "CONF-RENAME-C1",
        NULL
    };
    for (int i = 0; must_have[i]; ++i) {
        const iii_error_info_t *e = iii_error_lookup_by_name(must_have[i]);
        if (e == NULL) {
            ++g_fail;
            fprintf(stderr, "FAIL: missing required code %s\n", must_have[i]);
        } else {
            ++g_pass;
        }
    }
    return 0;
}

static int t_severity_names(void) {
    CHECK(strcmp(iii_error_severity_name(III_SEV_INFO), "INFO") == 0, "sev INFO");
    CHECK(strcmp(iii_error_severity_name(III_SEV_PANIC), "PANIC") == 0, "sev PANIC");
    CHECK(strcmp(iii_error_severity_name(III_SEV_CATASTROPHIC), "CATASTROPHIC") == 0, "sev CATASTROPHIC");
    return 0;
}

static int t_panic_phase_severity(void) {
    /* All PANIC-* codes must have severity PANIC or CATASTROPHIC. */
    size_t n = 0;
    for (size_t i = 0; i < iii_error_catalog_len; ++i) {
        if (strcmp(iii_error_catalog[i].phase, "PANIC") == 0) {
            ++n;
            CHECK(iii_error_catalog[i].severity == III_SEV_PANIC ||
                  iii_error_catalog[i].severity == III_SEV_CATASTROPHIC,
                  "PANIC-* has PANIC/CATASTROPHIC severity");
        }
    }
    CHECK(n >= 8, "at least 8 PANIC codes");
    return 0;
}

static int t_prefix_iteration(void) {
    size_t n = 0;
    iii_error_iter_by_prefix("LEX-ENC", count_cb, &n);
    CHECK(n == 8, "LEX-ENC-* count == 8");
    n = 0;
    iii_error_iter_by_prefix("CAT-GATE", count_cb, &n);
    CHECK(n == 8, "CAT-GATE-* count == 8");
    n = 0;
    iii_error_iter_by_prefix("PARSE", count_cb, &n);
    CHECK(n == 9, "PARSE-* count == 9");
    return 0;
}

int main(void) {
    t_total_count();
    t_every_code_resolves();
    t_invalid_code();
    t_no_duplicate_codes();
    t_no_duplicate_ids();
    t_roundtrip();
    t_every_phase_enumerates();
    t_phase_membership_matches_name();
    t_known_codes_present();
    t_severity_names();
    t_panic_phase_severity();
    t_prefix_iteration();

    printf("=== %d passed, %d failed ===\n", g_pass, g_fail);
    return g_fail == 0 ? 0 : 1;
}
