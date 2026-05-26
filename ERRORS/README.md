# III ERRORS — Unified Error-Code Namespace

Implementation of `DOCS/III-ERRORS.md` (Wave 0.3). NIH C11; static catalogue; no runtime loading.

## Layout

```
ERRORS/
├── include/iii/
│   ├── errors.h           Public API
│   └── errors_codes.h     Auto-generated stable numeric IDs (one per code)
├── src/
│   ├── errors.c           Lookup / iter / severity-name implementation
│   └── errors_catalog.c   Auto-generated static catalogue (one entry per code)
├── tools/iii_errors_tool.c  CLI: lookup / list / phase / subsystem / prefix / count
├── tests/iii_errors_test.c  Invariant tests (count, resolve, dedup, roundtrip, phase iter)
├── scripts/extract.py     Re-generates catalog & code IDs from DOCS/III-ERRORS.md
└── build/                 Build artifacts
```

## Build

```
gcc -std=c11 -Wall -Wextra -Werror -O2 -IERRORS/include -ILEXICON/include \
    -c ERRORS/src/errors.c         -o ERRORS/build/errors.o
gcc -std=c11 -Wall -Wextra -Werror -O2 -IERRORS/include -ILEXICON/include \
    -c ERRORS/src/errors_catalog.c -o ERRORS/build/errors_catalog.o
ar rcs ERRORS/build/libiii_errors.a ERRORS/build/errors.o ERRORS/build/errors_catalog.o
gcc ... ERRORS/tools/iii_errors_tool.c ERRORS/build/libiii_errors.a -o ERRORS/build/iii_errors_tool.exe
gcc ... ERRORS/tests/iii_errors_test.c ERRORS/build/libiii_errors.a -o ERRORS/build/iii_errors_test.exe
```

Clean `-Werror` build.

## Tool

```
iii_errors_tool lookup    <CODE|NUM>
iii_errors_tool list
iii_errors_tool phase     <PREFIX>     # LEX, PARSE, TYPE, ...
iii_errors_tool subsystem <NAME>       # ENC, GATE, HEXAD, ...
iii_errors_tool prefix    <CODE-PFX>   # LEX-ENC, CAT-GATE, ...
iii_errors_tool count
```

## API (`include/iii/errors.h`)

| Function | Purpose |
|---|---|
| `iii_error_count_total()` | Number of catalogued codes (excludes `III_E_INVALID = 0`). |
| `iii_error_lookup(code)` | Numeric ID → entry pointer (NULL if invalid). |
| `iii_error_lookup_by_name(name)` | Canonical name → entry pointer. |
| `iii_error_iter_by_phase(phase, cb, user)` | Iterate all codes for a phase. |
| `iii_error_iter_by_subsystem(sub, cb, user)` | Iterate by subsystem. |
| `iii_error_iter_by_prefix(prefix, cb, user)` | Iterate by hyphen-bounded code prefix. |
| `iii_error_severity_name(s)` | Severity → `"INFO"` / `"WARN"` / `"ERROR"` / `"COMPROMISE"` / `"PANIC"` / `"CATASTROPHIC"`. |

Each `iii_error_info_t` exposes `{code, name, phase, subsystem, suffix, severity, description, remediation}`.

## Code-prefix index — 21 phase namespaces, 190 entries

> The phase table (`iii_phase_table_len = 21`) reserves a **SID** namespace
> (`compile_sid`) that carries **0 catalogued codes** — SID-related errors are
> emitted under the **TYPE** prefix (`TYPE-SID-*`, 44 TYPE codes). 20 of the 21
> phases have ≥1 code; SID is reserved-but-empty. (RITCHIE Stage 1.6 reconciliation.)

| Phase | Display | Count | Subsystems present |
|---|---|---:|---|
| `LEX-`     | compile_lex      | 28 | ENC, ID, INT, Q14, STR, OP, PUNCT, CMT, WS |
| `PARSE-`   | compile_parse    |  9 | CYCLE, MOB, IRPD, EXPR, DOC, EXTERN, SEAL |
| `TYPE-`    | compile_type     | 44 | HEXAD, MOD, RING, LIN, SAN, SEAL, SID, CYCLE, WIT, PIP, SRPA, OBS, MOB, TRIN, CEIL, PLAN, FED, EPOCH, EPI, GHOST, INV, WAAC, HOLE, NAR, EXTERN, IRPD |
| `PROOF-`   | compile_proof    |  7 | UNIV, POSITIVITY, CONV, NORM, CERT, EXT |
| `SID-`     | compile_sid      |  0 | (top-level reserved; SID errors live under `TYPE-SID-*`) |
| `CG-`      | compile_codegen  |  3 | EMIT, PHASE, LEGACY |
| `LINK-`    | compile_link     |  3 | CLOSURE, MANIFEST, CYCLE-TABLE |
| `RUN-`     | runtime_cycle    |  2 | CYCLE, DISPATCH |
| `TRIN-`    | runtime_trinity  | 11 | L1-SCBA, L2-ACC, L2-WAAC, L3-INTENT, L3-CAP, L3-CAUSALITY, L3-SANCTUM, L3-MOBIUS, L3-CEILING, L3-EPISTEMIC, ALL-HEXAD |
| `CAT-`     | runtime_catalyst | 12 | GATE (1–8), RATE, PHASE-RATE, MOD-RATE, PROMOTE-REVOKED |
| `SAN-`     | runtime_sanctum  |  5 | INVALID-DISPATCH, TRINITY-REJECT, FRAME-INVALID, PKRU-MISMATCH, DRTM-CHAIN |
| `FED-`     | runtime_fed      |  7 | OUTBOUND-REJECT-TIER0, OUTBOUND-TIER-MISMATCH, QUORUM-FAIL, PEER-VERIFY, PEER-DISCOVERY, AH-VERIFY, IOMMU-IOPT |
| `WIT-`     | runtime_witness  |  5 | HMAC, BLAKE3, CHAIN, BCWL, EPOCH |
| `MOD-`     | runtime_module   |  3 | RES (×2), PROMOTE-REJECT |
| `FNDR-`    | runtime_anchor   |  9 | VETO, COSIGN-MISSING, COSIGN-INVALID, ANCHOR-REMOVAL-ATTEMPT, DRTM, DENY, RESTORE, SHAMIR (×2) |
| `CONF-`    | audit_conform    | 16 | VERIFIER, R1-MISMATCH, CRITERION-FAIL-N, RENAME (×13) |
| `REPLAY-`  | audit_replay     |  2 | CHAIN, DECOMMIT |
| `CRYPTO-`  | runtime_crypto   |  8 | SUITE (×3), KYBER, DILITHIUM, SPHINCS, VDF, HKDF |
| `ZK-`      | runtime_zk       |  4 | ROLLUP (×4) |
| `GENESIS-` | runtime_genesis  |  4 | INSTALL, DRTM-SLIDE, LEGACY-DISGUISE, SECURE-BOOT |
| `PANIC-`   | panic            |  8 | GLYPH-DRIFT, IRPD-RAW, PKRU, WITNESS-CHAIN-BROKEN, HEXAD-UNREACHABLE, FOUNDERS-ANCHOR-CORRUPTION, DRTM-CEREMONY-FAIL, PROOF-KERNEL |
| **Total** |               | **190** | |

### Per-spec criterion namespace (§19 renaming)

The 13 per-spec criterion namespaces (`C-A1-*` … `C-C1-*`) are registered as informational
catalogue entries with codes `CONF-RENAME-A1`, `CONF-RENAME-A2`, …, `CONF-RENAME-C1`, mapping
each new prefix to its old per-spec form (`C-LEX-*`, `C-GRAM-*`, …, `C-ABI-*`) and to its
spec-of-origin (LEXICON, GRAMMAR, TYPES, EFFECTS, CYCLES, HEXAD, PHASES, SANCTUM, TRINITY,
MODULES, CATALYST, FEDERATION, ABI). The substrate-wide acceptance set `C-1..C-30` retains
its CONFORMANCE.md numbering and is not renamed.

## Tests

```
=== 2175 passed, 0 failed ===
```

Verified invariants:

1. `iii_error_count_total()` matches `iii_error_catalog_len`.
2. Total ≥ 187 (174 spec-enumerated + 13 renames).
3. Every `code` resolves via `iii_error_lookup` and identity matches the catalog slot.
4. Every entry has non-empty `name`, `phase`, `description`, `remediation`.
5. `iii_error_lookup(0)` and out-of-range codes return `NULL`.
6. No duplicate code names anywhere in the catalogue.
7. Numeric IDs are dense and sequential (1..N).
8. Name → entry → code → entry roundtrip is identity for every entry.
9. Sum of per-phase iteration counts equals total catalog size.
10. Every entry's `name` begins with its `phase` followed by `'-'`.
11. A spot-check list of 41 named codes from every section is present.
12. Every `PANIC-*` entry has `PANIC` or `CATASTROPHIC` severity (≥ 8 codes).
13. Hyphen-bounded prefix iteration counts match expected values
    (`LEX-ENC-*`=8, `CAT-GATE-*`=8, `PARSE-*`=9).

## Regenerating the catalogue

The catalogue is auto-generated from `DOCS/III-ERRORS.md` so spec drift
cannot leave the C source stale:

```
python ERRORS/scripts/extract.py
```

This rewrites `include/iii/errors_codes.h` and `src/errors_catalog.c`.

## Stats

- Files: **7** (2 headers, 2 C library sources, 1 tool, 1 test, 1 generator script)
- LOC:   **1035**
- Tests: **12 invariant tests, 2175 assertions, 0 failures**
- Catalogued error codes: **190** across **21** phase namespaces (SID reserved with 0 codes — see §Code-prefix index)
