# ADR-RES-008 — No Governance

## Status

FROZEN.

## Context

The prior plan revision included a `omnia/governance.iii` subsystem with proposal acceptance, sandbox isolation, and operator-flag review. ADR-RES-004 establishes that there is no admission post-boot; therefore there is no governance to perform.

## Decision

`omnia/governance.iii` is a 24-line refusal stub containing only a comment block (FROZEN SPEC §Z.C.13). It exports zero symbols. No `gov_propose`, no `gov_sandbox_run`, no `gov_admit`. An attempt to call governance APIs is a link error.

## Consequences

- New patterns require:
  1. A new specification document with a new ID.
  2. Authoring of source files compliant with the new spec.
  3. Full corpus regression.
  4. Full mandate audit (M1..M22).
  5. Full quality gate (Q1..Q7).
  6. Full mhash re-seal (`iiis-0.mhash`, `SEAL_RESOLVER.mhash`, closure root).
  7. Tag of the new release.

This is not a runtime call. The "review" happens at the spec-authoring layer; the implementation is mechanical transcription thereafter.

## Alternatives Refused

### Multisig Governance

Refused per HC-1 #11.

### Time-Locked Admission

Refused: deferred admission is still admission. ADR-RES-004 #16 forbids future ADRs in this spec.

### Operator Approval Flag (`SAFE_APPROVED`)

Refused per HC-1 #11. Operator review is excluded.

### Read-Only Audit Subsystem

> "Keep governance.iii but make it audit-only — read patterns, never write."

Refused: any `governance` symbol in the source invites future evolution. The 24-line refusal stub is the load-bearing artefact of "governance does not exist."

## Audit

- §12 of FROZEN SPEC.
- §Z.C.13 carries the 24-line refusal stub verbatim.
- §V.P0024 verifies the stub exports zero symbols.

## Lineage

Authored: step R0008 of §I. Closed.
