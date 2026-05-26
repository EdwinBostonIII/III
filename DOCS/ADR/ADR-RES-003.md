# ADR-RES-003 — Unification Algorithm Choice

## Status

FROZEN.

## Context

The resolver dispatches to patterns whose binding sites must match the intent's partial args plus the call context. A unification algorithm is required.

Constraints:
- Bounded resource use (HC-1 #5: bounded latency).
- Deterministic.
- No backtracking (would introduce non-deterministic search).
- Sound (occurs check required).
- NIH (HC-3): no external library.

## Decision

**Bounded Robinson unification with explicit term-table representation and integrated occurs check**, implemented in `omnia/unify.iii` (FROZEN SPEC §6, §Z.C.5.full).

Limits:
- 256 terms per buffer (`UNIFY_MAX_TERMS`).
- 64 variables (`UNIFY_MAX_VARS`).
- 64 substitutions (`UNIFY_MAX_SUBSTS`).
- 16 recursion depth (`UNIFY_MAX_DEPTH`).
- 32 max arity (`UNIFY_MAX_ARITY`).
- 1024 args-pool entries (`UNIFY_MAX_ARGS_POOL`).

Total buffer size: 8720 bytes per resolve()-call; stack-allocated; no heap.

## Algorithm Pseudocode

```
unify(buf, a, b):
    a' := walk(a); b' := walk(b)
    if a' = b': return success
    if kind(a') = VAR: return occurs_check(a', b') ? fail : bind(a', b')
    if kind(b') = VAR: return occurs_check(b', a') ? fail : bind(b', a')
    if kind(a') ≠ kind(b'): return fail
    case kind(a'):
        CONST/CAP/HEXAD: return payload(a') = payload(b')
        STRUCT:
            if head(a') ≠ head(b'): return fail
            if arity(a') ≠ arity(b'): return fail
            for i in 0..arity:
                if unify(args(a')[i], args(b')[i]) = fail: return fail
            return success
```

## Termination Proof

Define `M(buf) = (unbound_vars(buf), Σ depth(t) for t referenced)`. Lex-order this pair.

Each step:
- VAR-bind: strictly decreases unbound_vars by 1.
- STRUCT-recurse: strictly decreases depth.
- CONST/CAP/HEXAD-compare: terminates immediately (no recursion).

Both components are non-negative integers; descent terminates. Recursion depth bounded by `UNIFY_MAX_DEPTH = 16` and arity bounded by `UNIFY_MAX_ARITY = 32`. Stack depth bounded.

QED. Verified by corpus 36 (depth limit hit).

## Complexity

Worst case: 256 terms × 32 arity × 16 depth = 131,072 elementary ops per unify call.

Per resolve() call:
- 4096 candidates evaluated.
- Predicate fast-fail eliminates ≥95%.
- Surviving ~5% × per-unify cost ≈ 4096 × 64 ≈ 262,144 ops typical.
- Worst case 4096 × 131,072 ≈ 5.4e8 ops (degenerate; corpus 36 gates).

## Consequences

- Deterministic results within bounds.
- 0 result on out-of-bounds — not crash.
- Predicate fast-fail keeps typical resolve() under 200 µs (§14.3).

## Alternatives Refused

### Martelli-Montanari Union-Find

Equivalent semantics, more complex, no measurable benefit at our bounds.

### Type-Class-Style Backtracking

Refused: introduces non-deterministic search; conflicts with I-1 (determinism).

### Ad-Hoc Pattern-Matching Language

Refused per HC-1 #14 (the 16 meta-patterns are the closed set).

### Higher-Order Unification

Refused: undecidable in general; bounded fragments are still complex. The first-order Robinson algorithm is sufficient for III's use cases.

## Audit

- §6 of FROZEN SPEC.
- §Z.C.5.full carries verbatim source.
- §L.6 (Bounded Recursion Lemma).
- Corpus tests 33–36.

## Lineage

Authored: step R0004 of §I. Closed.
