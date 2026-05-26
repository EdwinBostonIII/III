# Architecture — III Perfection Charter POC

## Executive summary

A self-auditing substrate that makes the Perfection Charter executable. The
design goal is not "a system with no flaws" but **a system that maintains a
falsifiable proof of its own coherence**: each charter predicate is a bounded
total function paired with a falsifier, and the suite content-addresses its
result into a reproducible seal. If any predicate's good case fails, or any
predicate's bad case slips through, or the seal drifts, the audit goes red.

The single architectural conviction: **determinism is the load-bearing
non-functional requirement.** Every other property (bit-identity, seal
stability, confluence, self-audit) is either a form of determinism or depends on
it. So the architecture forbids the things that break determinism — floats,
ambient state, salted hashing, unbounded recursion — at the substrate level.

## Functional requirements

- **FR-1** Each predicate exposes `verify()` (good case) and `falsify()` (bad
  case must be caught). HOLDS = `verify ∧ falsify`.
  *Acceptance:* `run_audit.py` reports 15/15 holding. ✓
- **FR-2** The audit is deterministic within and across processes.
  *Acceptance:* run-1 seal == run-2 seal == fresh-process seal (`b6bc80d6…`). ✓
- **FR-3** The audit discriminates: corrupting the substrate turns it red.
  *Acceptance:* `selftest_mutation.py` PASS — 3 injected faults each caught, then
  GREEN with the original seal after restore. ✓
- **FR-4** No predicate is a stub; each falsifier drives a genuinely bad input.
  *Acceptance:* every `falsify()` exercises a distinct wrong implementation
  (corrupted op, divergent algorithm, lossy op, side channel, destructive
  resolver, non-confluent system, looping rewrite). ✓

## Non-functional requirements

| Category | Requirement | Target | How met |
|----------|-------------|--------|---------|
| Determinism | bit-identical output | 100% reproducible | hashlib over canonical bytes; seeded RNG; no float |
| Soundness | never assert a falsehood | 0 false positives | gap-aware totality; mutation test |
| Portability | runs anywhere | Python 3 stdlib only | no third-party deps |
| Auditability | self-checking | one command | `run_audit.py` exit code |
| Density | no bloat | minimal primitives | 9 focused modules, each one responsibility |

## Pattern

**Self-auditing modular monolith with a verified-value bus.** Modules are pure
and communicate only through content-addressed, gap-aware values recorded in a
witness commons — never through shared mutable state. This is what makes
non-interference (Π14) and gap-containment (C1) *structural* rather than
hoped-for: the only thing crossing a boundary is a verified value, so one module
cannot harm another, and a corruption attempt (the side-channel falsifier) is
detectable as a change that "shouldn't" have happened.

Rationale over alternatives: a layered/CRUD design would not express the
composition guarantees; an event-driven design would reintroduce ordering
nondeterminism that violates the prime NFR. The verified-value bus is the
minimal structure that delivers determinism + non-interference together.

## Components

| Component | Single responsibility | Depends on |
|-----------|------------------------|-----------|
| `mhash` | canonical, deterministic content addressing | (stdlib) |
| `trit` | total asymmetric-ternary algebra; the gap as a value | — |
| `hexad` | 6-pillar hexad + structural representability rule | `trit` |
| `gapval` | total + sound gap-aware arithmetic; contingent resolution | `mhash` |
| `reversible` | SID round-trip + gated admission of new ops | `mhash` |
| `rewrite` | confluent normalization + termination | `mhash` |
| `witnesscommons` | append-only hash-chained ledger (the commons) | `mhash` |
| `modules` | cross-module composition over the verified bus | `gapval`, `witnesscommons`, `mhash` |
| `charter` | predicate registry + self-audit; emits the seal | all of the above |

## Data flow

```
inputs ─► module (pure) ─► gap-aware value ─► mhash ─► witness ─► commons (append-only)
                                                                      │
   charter.run_audit ── verify()/falsify() per predicate ── seal ◄────┘
                                                              │
                                              run twice ─► identical (Π5/Π12)
```

## Decision log

- **ADR-1: Python + stdlib only.** Maximizes portability and determinism;
  arbitrary-precision ints sidestep float nondeterminism. *Consequence:* a real
  III build re-derives this over libc + `.iii`, not Python.
- **ADR-2: `hashlib` stands in for `sha256.iii`.** Hand-rolling SHA-256 in
  Python would add risk without demonstrating anything new at POC scale. The
  content-address *discipline* is what matters and is preserved.
- **ADR-3: every predicate requires a falsifier.** A predicate with no possible
  counterexample is not admitted (the charter's own rule). This is what turns
  "perfect" from a vibe into a checkable status.
- **ADR-4: scope is honest, not padded.** Π1 is scoped to the algebra; Π2 is
  by-construction; the kernel anchor A1 and unbuilt charter items are explicitly
  out of scope rather than faked.
- **ADR-5: integer-only, no ambient state.** Enforces the determinism NFR at the
  substrate level so Π5/Π6/Π7/Π12 are achievable rather than aspirational.

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| A predicate's falsifier is too weak (passes trivially) | false confidence | `selftest_mutation.py` proves the audit goes red under real corruption |
| Π1 mistaken for full soundness | overclaim | scope labelled "scoped"; A1 named as out-of-scope anchor |
| Python semantics differ from `.iii` | port gap | mapping table in README; determinism rules mirror III's |
| Seal nondeterminism via `hash()` | silent drift | only `hashlib` over canonical bytes is used; verified across processes |

## Roadmap to a real III port

1. Replace `mhash` with `numera/sha256.iii` (or `keccak256.iii`) — already exists.
2. Replace `trit`/`hexad` with the in-tree Hexad algebra; wire Π1 to the CIC
   kernel (`TYPES/src/cic.c`) so soundness leaves "scoped" status.
3. Replace `reversible` with the real SID 32-step plan.
4. Replace `rewrite` with the XII confluent rewriter.
5. Bind `charter` predicates to the existing conformance corpus, so the live
   `build_iiisN.sh` determinism gate *is* Π5/Π7 at full scale.
