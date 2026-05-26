# ADR-RES-004 — No Runtime Evolution

## Status

FROZEN.

## Spec

This ADR is part of FROZEN SPECIFICATION III-RES-FROZEN-001. It does not change. Implementation cannot deviate.

## Context

The user's master prose describes a "continuous self-evolution" loop in which the resolver itself is the primary target of an ongoing optimisation cycle: telemetry feeding selection, patterns being discovered at runtime, specialisations admitted post-deployment, JIT-promoted fast paths, background search.

The user's binding directive supersedes that prose:

> "i do not care for the evolution loop reliance. i want it to be perfect from the start"

> "produce what i asked please … the plan must be the 99% to the implementation's 1%"

The system must therefore be **complete and final at iiis-0 boot**. There is no asymptotic improvement. There is no observed-becomes-better. The system arrives correct, audited, frozen.

## Decision

This ADR formalises the sixteen no-evolution clauses of FROZEN SPEC §0.2:

1. No pattern admission post-boot. The pattern registry is built at startup by `pattern_registry_seal_global()`. The seal call is the LAST opportunity to register. Subsequent `pattern_register()` returns 0 and aborts the process.
2. No coefficient adjustment. The 33 activation coefficients are `const u64` declarations in `omnia/resolver.iii`. No `set_coefficient` API exists.
3. No telemetry-driven selection. `resolver_score(p, intent, ctx)` is a pure function of its three arguments. It has no access to past witness entries, no global counters, no time, no random source.
4. No tiebreak heuristic. Tiebreak is `pattern_id ascending → module_mhash ascending → hard fail`. There is no third comparator.
5. No background optimisation. No thread, no timer, no scheduler, no observer, no auto-improver runs in the resolver's process.
6. No JIT-discovered fast path. Every emitted byte sequence is in §7.4 of the spec. The encoder produces exactly those bytes, every time.
7. No specialisation inferred at runtime. Specialisation patterns are listed by name in §C and registered at boot. No inference algorithm exists in §B–§F.
8. No sandbox. Because there is no admission post-boot, there is nothing to sandbox.
9. No governance. Because there is no admission post-boot, there is nothing to govern.
10. No proposal. Because there is no admission post-boot, no proposal is ever made.
11. No operator review. Because there is no admission post-boot, no operator decision is taken.
12. No feature flag. The resolver-driven calling convention is in effect from iiis-0 boot. No `--resolver-codegen=off`. No transitional period.
13. No fallback. If `resolve()` returns an error crystal, the caller observes the error and reports it. The caller does not retry under different parameters; does not switch to a "legacy path".
14. No future patterns. The 67 concrete patterns and 16 meta-patterns are the entire population.
15. No future transforms. The 24 transform patterns are the entire population.
16. No future ADRs. The 16 ADRs RES-001..RES-016 (with RES-015 deleted) are the complete record.

## Enforcement

The above is enforced by code structure, not policy:

- `pattern_table.iii::pattern_register()` first instruction (post-P0005) is `if g_pattern_table_sealed == 1u8 { return 0u8 }`. The seal flag is set in `pattern_registry_seal_global()` and never cleared (no clearing API exists).
- `omnia/resolver.iii` source contains zero `f32`/`f64` types, zero calls to `GetTickCount64`/`time`/`clock`/`rand`, zero access to `witness_root_byte()` outside `proof_ripple_verify`. Verified by Q7 lint at every CI run.
- `omnia/governance.iii` is a 24-line refusal stub with no symbols. It exists solely so that `import omnia/governance` resolves to the void.
- The forbidden-vocabulary list of FROZEN SPEC §0.3 is grep-enforced at every CI run. Hits in `STDLIB/iii/omnia/*` or `STDLIB/iii/sanctus/quality_q7.iii` fail the build.

## Consequences

Latency is bounded by §5/§6/§7 specs. Performance neither improves nor degrades after deployment. Adding behaviour requires authoring a new specification document with a new ID, replacing this one. This document is closed.

The system is **provably optimal at deployment** rather than asymptotically optimal via runtime adaptation. Every decision is a deterministic, witnessed, byte-equal-on-replay function of frozen inputs.

## Alternatives Refused

### Sandboxed Evolution

> "Allow new patterns to enter through a sandboxed test harness; if they pass, admit at runtime."

Refused. Sandbox-then-admit is still admission. The Q7 determinism check would either:
(a) treat sandbox-admitted patterns as drift (failing Q7), or
(b) admit them silently into the witness chain (failing replay byte-equality).

Either fails I-1 (determinism) or I-8 (registry frozen).

### Operator-Flagged Admission

> "Require an operator to flag each admission `SAFE_APPROVED` per III-MODULES.md §1.3 — that's a human-in-the-loop, not pure machine-driven evolution."

Refused. Per HC-1 #11 (no operator review). The user's binding directive forbids review-based admission post-boot. Operator review is human-evolution, not machine-evolution, but it is still evolution.

### Heuristic-Driven Specialisation

> "Auto-promote a pattern to a specialisation when its predicate has fast-failed N times — purely algorithmic, no admission."

Refused. Fast-fail counts ARE telemetry. Per HC-1 #3 (no telemetry-driven selection), this is forbidden.

### Time-Locked Admission

> "Admit a pre-staged pattern only after a time delay — no runtime decision, just deferred boot."

Refused. Deferred boot is still boot. The seal occurs at one moment. No delayed seals.

## Audit

This ADR is referenced by FROZEN SPEC §16 closure lemma L.12 (No-Evolution Lemma): source in §B–§F contains no admission API, no learn/adapt/evolve token (per §0.3 forbidden vocabulary), no telemetry-driven branch. The 16 forbidden categories of §0.2 are excluded by absence. No evolution path exists.

The ADR is also referenced by:
- §0.6 HC-2 (no-evolution).
- §13 Mandate M22 audit (resolution determinism).
- §18 Acceptance criterion #14 (HC-1 invariant grep audit).

Verification: `grep -ri 'evolve\|adapt\|learn\|telemetry' STDLIB/iii/omnia/resolver.iii STDLIB/iii/omnia/unify.iii STDLIB/iii/omnia/pattern_table.iii STDLIB/iii/omnia/codegen_patterns.iii` returns empty (modulo string-literal exemptions in §H).

## Lineage

- Authored: step R0001 of §I.
- Derived from: user directive 2026-05-08 ("perfect from the start"), user directive 2026-05-08 ("99% to 1%").
- Supersedes: prior revision §12 governance section (excised).
- Superseded by: this ADR is closed. Any future change requires a new specification document with a new ID.
