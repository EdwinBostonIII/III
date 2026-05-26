# ADR-RES-011 — Quality Gate Q7

## Status

FROZEN.

## Context

Existing Q1..Q6 cover lattice quality (corpus pass, mhash determinism, golden mhash, witness growth, K-floor, layered seal). Resolver determinism is a new orthogonal gate: it lints the resolver source for forbidden behaviour and replays the witness chain for byte-equality.

## Decision

`Q7 = bit 6 = 0x40u32`. `QUALITY_ALL_MASK = 0x7Fu32`.

`quality_check_q7_resolution()` returns 1 iff all four hold:
1. **Lint passed**: no FP, no clock, no random, no signed-i64 ordering compares, no unmasked u32→u64 ptr math, no u32 ptr stores in resolver source. Build-time check, observed via `g_resolver_lint_passed`.
2. **Witness replay byte-equal**: `resolver_replay_check_chain() == 1` — every OK witness reproducible bit-for-bit from recorded inputs.
3. **Registry sealed**: `pattern_registry_is_sealed() == 1`.
4. **Coefficient seal byte-equal**: `seal_resolver_verify() == 1`.

Failure of any of the four → Q7 = 0 → CI build fails.

## Consequences

- Resolver source is held to a stricter standard than other code: explicit lint rules enforce HC-7 (no FP), HC-12 (trap discipline), HC-1 (no telemetry).
- Determinism is verifiable without trusting the build pipeline alone.

## Alternatives Refused

### Subsume Into Q2 (mhash Determinism)

Refused: Q2 is whole-binary; Q7 is resolver-specific lint plus replay. Different concerns, different evidence.

### Add Q7 Without Replay (lint only)

Refused: lint catches authoring drift; replay catches behavioural drift. Both are needed.

### Make Q7 A Test-Suite Pass Rather Than A Mandate

Refused: tests can be skipped or disabled. A mandate (M22) wired to Q7 is the load-bearing artefact.

## Audit

- §1.2.7 carries the Q-gate framework.
- §Z.D.1 carries `quality_q7.iii` source.
- Corpus 46 verifies Q7 green.
- Corpus 47 verifies Q7 fails on injected corruption.

## Lineage

Authored: step R0011 of §I. Closed.
