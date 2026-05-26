# Gap-Filling Pass

Closing the honest "remaining scope" gaps named in the prior round. Each gap is
now a real, runnable, mutation-tested predicate. The base predicate set grew, so
the base seal was re-pinned (an intentional, audited DRIFT-driven reseal).

## Verified result (this build)

```
base predicates : 19 / 19     (Π1 upgraded; Π2, Π21, Π22, Π20 added)
extended        : 24 / 24     (base 19 + Π15..Π19)
base seal       : 16fe0950…be95   (re-pinned across the audited drifts)
quine-seal      : behavioral, over SOURCE + every package function's bytecode
mutation suites : base 10 faults caught · extension 5 faults caught · seals restore
```

## Gap 1 — Π1 was algebra-only → now real logical soundness (`kernel.py`)

A bidirectional **simply-typed λ-calculus** with products, sums, unit, and the
empty type `False`, read through **Curry–Howard**: a closed term of type `T` is a
proof of `T`. `False` has no introduction rule, so it is **uninhabited** — and
that *is* soundness.

- **Π1 verify:** the kernel accepts genuine proofs (`A→A`, `A∧B→A`, `A→A∨B`, `True`)
  and **no closed term type-checks at `False`**.
- **Π1 falsify:** the argument-type check in `app` is exactly what keeps `False`
  uninhabited. `infer_unsound` drops it, and then `(λx:False. x) unit` inhabits
  `False` — the sound kernel rejects it, the unsound one accepts it → caught.

Anchor **A1** moves from *trusted* to *demonstrated for this logic*. Honest
ceiling: it is propositional STLC, not full dependent CIC.

## Gap 2 — Π2 was "by construction" → now a real decidability check (`kernel.py`)

Type-checking is **total, deterministic, and structurally terminating** (each
recursive call is on a strict subterm, so the call count is bounded by the term's
node count).

- **Π2 verify:** over a corpus (well- and ill-typed), the checker returns the same
  verdict twice and within the structural call bound.
- **Π2 falsify:** a checker with no well-founded measure (`looping_infer`) only
  halts by exhausting fuel — it fails to *decide* a term the sound checker decides.

## Gap 3 — `hashlib` standin → hand-rolled SHA-256 (`sha256_nih.py`, Π20)

A from-scratch FIPS 180-4 SHA-256 over plain integer ops.

- **Π20 verify:** matches the reference on KATs (`""` and `"abc"`) **and** agrees
  with `hashlib` on the canonical encoder over a corpus — i.e. content-addressing
  is hash-agnostic and the earlier standin was faithful.
- **Π20 falsify:** corrupting one round constant diverges from the reference.

`hashlib` is now only an independent **oracle**, not a dependency — the NIH
discipline is satisfied at the foundation.

## Gap 4 — behavioral seal was predicate-level → now deep (`quineseal.py`, Π18)

`full_behavior_manifest()` hashes the bytecode of **every top-level function in
every package module**, not just predicate functions. So the quine-seal commits
to the executed behavior of the whole substrate; monkeypatching *any* helper
changes the seal.

- **Π18 verify:** the fixpoint holds and the manifest includes deep helpers
  (`negknow.well_formed`, `holes.evaluate_partial`, `kernel.infer`).
- **Π18 falsify:** tampering a deep helper's bytecode breaks the fixpoint.

*Honest residual:* this cannot detect a patch to a C-level builtin, and bytecode
is interpreter-version-specific (fine within a run — all the instance check needs).

## Why the base seal changed (and that's correct)

Adding Π2 and Π20 and upgrading Π1 changed the *verdict vector* the base seal is
computed over, so the seal moved from `b6bc80d6…` to `13758be0…`. This is not
drift-to-be-feared; it is the **DRIFT-driven reseal** workflow: a deliberate,
audited change to the predicate set re-pins the golden seal. Determinism still
holds (identical within a run and across processes); all predicates still hold;
both mutation suites still discriminate. The change was intended, and the gate
recorded it.

## Second pass — narrowing the STLC→CIC gap + refinements

The kernel was simply-typed (STLC). CIC's consistency rests on three pillars;
this pass demonstrates two of them, concretely.

- **Π21 — inductive types + structural recursion + strong normalization.** The
  kernel gains inductive `Nat` (`zero`/`succ`) and a structural recursor
  (`natrec`), plus a real **normal-order evaluator** (`shift`/`subst`/`step1`/
  `normalize`). *Verify:* `add` type-checks, `add 2 3` reduces to `5`, and every
  well-typed corpus term reaches a normal form. *Falsify:* the non-terminating
  Ω = `(λx. x x)(λx. x x)` is **rejected by the type checker** — so strong
  normalization is guaranteed *by typing*, and the rejection is load-bearing.
- **Π22 — strict positivity of inductive definitions.** A constructor argument
  may not mention the type being defined in a negative position. *Verify:* `Nat`
  is strictly positive. *Falsify:* `Bad = C (Bad → Bad)` is non-positive (it would
  encode general recursion and break normalization) and is rejected.

Remaining ceiling: **dependent Π-types** and **universe stratification** (the
third pillar). Full dependent CIC is the frontier the port to `TYPES/src/cic.c`
would reach.

### Refinements in the same pass
- **`mhash` is now pluggable** (`set_backend`). Π20 proves the hand-rolled
  SHA-256 can BE the backend with **identical content addresses** — so `hashlib`
  is retired from load-bearing to oracle, not just KAT-cross-checked.
- **`compose6` moved to `hexad.py`** (it is a hexad operation; cohesion).
- **Dead code removed** (`_pure_pipeline`).

All re-verified: base 19/19, extended 24/24, 10+5 mutation corruptions caught,
seals reproducible within and across processes.
