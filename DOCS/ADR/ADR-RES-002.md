# ADR-RES-002 — Tiebreak Algorithm

## Status

FROZEN.

## Context

Two patterns may compute identical scores. The resolver must pick a winner deterministically without telemetry, clock, or randomness (HC-1 #4).

## Decision

Three-step procedure (FROZEN SPEC §2.6):

```
tiebreak(a_id, b_id):
    1. if pattern_id(a) < pattern_id(b): return a
       if pattern_id(a) > pattern_id(b): return b
    2. compare module_mhash byte-by-byte; lower-lexicographic wins.
    3. if both equal: return HARD_FAIL (RESOLUTION_E_AMBIGUOUS).
```

There is no fourth step. A persistent ambiguity is treated as registry corruption — emitted as an error, not silently resolved.

## Consequences

- Older patterns (lower pattern_id, registered first) win ties. This rewards stability.
- Identical pattern_id AND identical module_mhash means duplicate registration — a build defect, NOT a runtime ambiguity. The resolver emits 0xE101 (RESOLUTION_E_AMBIGUOUS) which mints a failure crystal and writes a fail-witness.
- The procedure is pure: no clock read, no random source, no telemetry access. Verified by §L.9 (Tiebreak Pure Lemma).

## Alternatives Refused

### Random Tiebreak

Refused per HC-1 #4 (no random source). Determinism violation.

### First-Registered Wins

Equivalent to "lower pattern_id wins" — pattern_ids are minted in registration order. Already encoded in step 1.

### Vote-Based Selection

Refused per HC-1 #11 (no vote). Voting is a governance primitive; governance is excluded.

### Operator Choice

Refused per HC-1 #11. Operator review is excluded.

## Audit

- §2.6 carries the verbatim algorithm.
- Corpus test 40 verifies the deterministic winner under tie.
- Corpus test 41 verifies hard-fail on duplicate registration.

## Lineage

Authored: step R0003 of §I. Closed.
