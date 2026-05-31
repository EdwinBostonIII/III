# ADR-RES-009 — Resolver Seal

## Status

FROZEN — **superseded by ADR-RES-009-A** (W5.3 / KEEP-1) for the coefficient-table encoding.
The two-seal architecture below stands; the frozen coefficient bytes were corrected (six rows
whose little-endian encoding did not decode to their documented magnitudes) and the seal reissued.
See `DOCS/ADR/ADR-RES-009-A.md`.

## Context

The resolver-specific data — 33 coefficients, 67 patterns, unification engine, codegen patterns, transform attrs, mhash domain strings — needs an independent seal. A combined seal with `iiis-0.mhash` would tightly couple resolver-only changes to compiler rebuild cycles.

## Decision

Two independent seals:

- `iiis-0.mhash` — toolchain seal; covers the compiler binary.
- `SEAL_RESOLVER.mhash` — resolver seal; covers the resolver-specific source artefacts.

Closure root incorporates both (FROZEN SPEC §15.1, §Z.D.3 source). Either drifting fails the build at every CI run.

`SEAL_RESOLVER.mhash` is computed by `seal_resolver_compute()` over:
1. The `RESOLVER_*` coefficient table (`COEFF_TABLE_BEGIN..END` in `omnia/resolver.iii`).
2. The 67 occupied registry slots (each 168 bytes, walked).
3. The unification engine bytecode (`UNIFY_BYTECODE_BEGIN..END` in `omnia/unify.iii`).
4. The 5 mhash domain strings (80 bytes total).

Domain: `"SEAL_RESOLVER\0\0\0"` (16 bytes, NUL-padded).

## Consequences

- A change to (e.g.) a transform_fn body re-seals `SEAL_RESOLVER.mhash` only.
- A change to (e.g.) `cg_r3.iii::r3_emit_handle` re-seals `iiis-0.mhash` (because it's compiled into the toolchain).
- Cross-coverage via closure root means tampering with either is detected.

## Alternatives Refused

### Single Combined Seal

Refused: tightly couples resolver-only changes to compiler rebuild cycle. Increases build friction.

### No Seal

Refused: tampering would be undetectable.

### Three Seals (compiler / runtime / data)

Refused: two seals suffice; three adds audit complexity without coverage gain.

## Audit

- §15 carries the two-seal architecture.
- §Z.D.3 carries `seal_resolver.iii` source.
- §V.G0006 verifies both seals stable across 3 consecutive builds.

## Lineage

Authored: step R0009 of §I. Closed.
