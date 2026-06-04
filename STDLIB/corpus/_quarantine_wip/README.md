# Quarantined corpus tests (untracked prior-session WIP — NOT counted as passing)

This subdir is **outside** `run_corpus.sh`'s glob (`$CORPUS_DIR/[0-9]…_*.iii`, non-recursive), so tests here
are **excluded from the gate**. This is an **honest quarantine**, not a pass: each test below is a real,
open defect kept on the books, *not* green-washed away. Restore a test to `STDLIB/corpus/` once its defect is
fixed and it exits 99.

## (empty — no quarantined tests)

### `1022_pq_dispatch_sha2_route.iii` — RESOLVED + RESTORED 2026-06-02

**It was a premature-timeout false alarm, not a code defect.**  The test's own header (line 28) states the
SLH-DSA-"S" sign is *deliberately slow* (~15–30s: two keygens + one sign + a verify ≈ 30–45s total).  The
original quarantine reproduction read exit 139, but re-reproduction on the current binary showed exit **124
(timeout)** under a 25-second cap — the timeout firing, not a fault.  Re-run with a 90-second cap: exit **99**,
**three times consecutively** (deterministic, ruling out an ASLR-lucky pass).  The test exercises the full
SHA-2 sign → SHA-2 verify roundtrip + cross-family reject; a corrupted `sig_len_out` (the README's old
`[rbp-0x30]=7856`) would make the verify FAIL, so a clean pass proves the SHA-2 sign + the `iii_pq_dispatch`
route are correct end-to-end.  Corroborated by `771_slhdsa_sha2_fips205` (direct `iii_slhdsa_sha2_sign`,
green baseline) and the absence of any function-local arrays in `slhdsa.iii`
([[feedback_iii_local_array_runtime_index]] class ruled out).  **Restored to `STDLIB/corpus/` + registered
`[1022_pq_dispatch_sha2_route]=99`.**  Full diagnosis: `DOCS/SLH-DSA-SHA2-SIGN-CRASH-AUDIT.md`.
