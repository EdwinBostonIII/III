# III-CONFORMANCE — The 33 Conformance Criteria

**Doc-ID:** B3 / R1.B3
**Spec:** `DOCS/III-CONFORMANCE.md`

The acceptance contract: 33 criteria split across four groups (Core Language
C-1..C-15, Substrate C-16..C-25, Cognitive Layer C-26..C-30, Resolution
C-31..C-33).  C-31..C-33 were added by FROZEN SPEC III-RES-FROZEN-001 §14
(ADR-RES-011 / ADR-RES-006).  A toolchain binds a test function to each
criterion; the verifier runs them and reports PASS / FAIL / SKIP per criterion
plus an aggregate compliance score.

The verifier is closure-pinned (set/check pin) per spec §4 — a different
verifier mhash is rejected.

## Test

```
$ ./build/iii_conformance_test
=== 52 passed, 0 failed ===
```

## Conformance

| Code | Status |
| --- | --- |
| 33 criteria enumerated      | ✅ C-1..C-33 with title + test path |
| Four groups                  | ✅ Core (15) / Substrate (10) / Cognitive (5) / Resolution (3) |
| Test binding + run            | ✅ unbound criteria report SKIP, others PASS/FAIL |
| Compliance Q14                | ✅ passed / (passed + failed) |
| Verifier pin (§4)             | ✅ set/check 32-byte mhash |
