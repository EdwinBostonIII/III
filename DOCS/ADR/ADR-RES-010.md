# ADR-RES-010 — Mandate M22 (Resolution Determinism)

## Status

FROZEN.

## Context

The existing 21 mandates do not specifically cover the resolver's no-FP, bounded-recursion, no-telemetry contract. A 22nd mandate is required to make the contract auditable at runtime.

## Decision

`M22 = bit 21 = 0x00200000u32`. `MANDATE_ALL_MASK = 0x003FFFFFu32`.

Runtime check `mandate_check_m22()` returns 1 iff:
1. `quality_check_q7_resolution() == 1` (Q7 green).
2. `pattern_registry_is_sealed() == 1` (registry frozen).
3. `closure_includes_resolver_seal() == 1` (closure root absorbs SEAL_RESOLVER.mhash).

Wired into `mandate_audit()` via `mandate_audit_m22_contribution()`.

## Consequences

- Audit-time visibility of resolver health.
- Catches drift: any forbidden behaviour in resolver source, unsealed registry, or missing seal in closure trips M22.

## Alternatives Refused

### No New Mandate; Bundle Into M16 (Audit Trail)

Refused: M16 covers chain monotonicity, not selection determinism. Distinct concerns; distinct mandate.

### M22 As A Process-Time Bit Only

Refused: must be runtime-checkable for live audit. Process-time bits cover compile-time invariants; M22 covers a runtime invariant (registry sealed).

## Audit

- §13 mandate audit checklist includes M22.
- §Z.D.2 carries `mandate_m22.iii` source.
- Corpus 48 verifies M22 bit set on healthy run.

## Lineage

Authored: step R0010 of §I. Closed.
