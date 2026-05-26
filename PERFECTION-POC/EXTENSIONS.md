# Foundational Extensions (Π15–Π18)

Four capabilities added to the POC, each a falsifiable predicate, each built
**additively** on the untouched base charter. They were chosen because each is
*trivial-or-provable when the whole charter conjunction holds at once*, and
*heroic-or-impossible when it doesn't* — the honest version of "uniquely
possible with III."

## Run it

```
python run_ext_audit.py            # base 15 + 4 extensions = 19 predicates
python selftest_ext_mutation.py    # proves Π15–Π18 discriminate (go red under corruption)
```

## Verified result (this build)

```
predicates holding     : 20 / 20   (base 15 + Π15..Π19)
base seal (unchanged)  : YES        # Π8 conservative extension, at system-evolution scale
quine-seal             : a5a603d7…3b59   (commits to SOURCE and executed BYTECODE)
fixpoint verifies      : YES
EXTENSION MUTATION SELF-TEST: PASS  (5 injected faults caught, identical quine-seal after restore)
```

## The four capabilities

### Π15 — Negative knowledge (`negknow.py`)
A gap is not a null and not an error. It is a typed value carrying **why** it is
unknown and **what** caused it; operations on unknowns propagate a content-
addressed provenance DAG you can walk back to root causes. The live demo prints
`unknown because: essential (sensor_3 offline)`.
*Verify:* a derived gap is well-formed and reaches named root causes.
*Falsify:* a "silent" derived gap with no provenance is rejected.
*Elsewhere:* nulls / `Maybe`. *New here:* ignorance that **explains and audits
itself** as rigorously as knowledge.

### Π16 — Compute-with-holes (`holes.py`)
Evaluate a pipeline that still contains unresolved holes; get a **sound partial**
result. The guarantee: a node is Known *iff* all its transitive inputs are known
— otherwise a provenance gap. Resolving holes later is **conservative** (no prior
concrete value moves).
*Verify:* the soundness-of-partial invariant + conservative resolution over a
corpus. *Falsify:* a "guessing" evaluator that fabricates a concrete for a hole
is caught. *Elsewhere:* symbolic execution, incremental build. *New here:* a
**soundness-of-partial guarantee** with conservativity, not just recomputation.

### Π17 — Provable forgetting (`forgetting.py`)
Replace a witnessed value with a typed `redacted` gap, re-seal, and prove three
things at once: **integrity** (chain still verifies), **continuity** (witnesses
that didn't depend on it are byte-identical), **blast-radius** (witnesses that
did are now honest gaps pointing at the redaction — never silently wrong). The
demo: `redacted seq 2 -> downstream seq 3 now: unknown because: redacted`.
*Verify:* all three hold. *Falsify:* a naive delete (breaks integrity) **and** a
silent zero-redaction (leaves a dependent concrete) are both caught.
*Elsewhere:* append-only ledgers *cannot* forget; crypto-erasure deletes keys.
*New here:* **continuity-preserving, blast-radius-marked erasure with a proof.**

### Π18 — Quine-seal, now **behavioral** (`quineseal.py`)
The seal commits to the audit result, a hash of the auditor's own **source**,
*and* a hash of the auditor's executed **bytecode** (each predicate function's
`co_code`). So the artifact proves "the run that made this seal *is* the auditor
this seal describes" — a fixed point of (audit ∘ describe-self).
*Verify:* the fixpoint holds; the manifest includes the auditor's files; the
behavior manifest includes the predicate functions. *Falsify:* tampering either
source or behavior breaks the fixpoint.
**Why behavioral:** the original seal hashed only source files, so in-memory
monkeypatching (which leaves files untouched) was invisible to it. Hashing
bytecode closes that hole at the predicate level. **Gödel-safety:** this checks
an *instance* (this run ↔ these sources+behavior) — decidable and total; it never
attempts the forbidden self-consistency proof.

### Π19 — The Sovereign Value (`sovval.py`) — the deepening integration
One value type, `SovVal = { payload : Known | PGap ; hexad : 6-trit safety }`,
flows through every operation. Each `sv_op`: composes the payload via the unified
sound+precise arithmetic; composes the hexad (AND on structural pillars P1..P4,
OR on recovery pillars P5..P6, per III §4.7); **refuses** the op if the composed
hexad is unrepresentable (a bricking composition); and emits a witness. So
gap-totality, provenance, safety-typing, and witnessing become **intrinsic to the
value**, not per-module add-ons.
*Verify:* a safe op composes payload+hexad+witness and a gap rides the value
soundly. *Falsify:* a bricking composition is refused (and a guard-skipping op
would yield an illegal hexad — caught).

## The hardening + unification pass (fix failing features)

Building this exposed real weaknesses in the earlier POC, which the charter — run
against its own implementation — flagged. All fixed:

- **Unified the gap type.** There were *two* (`gapval.Gap` and `negknow.PGap`) —
  the very drift the charter forbids. Now there is one (`PGap`, with provenance);
  `gapval` delegates to it. **Unified the ledger** likewise (one `Witness`).
- **De-faked Π4/Π5/Π6.** Π4 now drives a real one-step reducer on the actual
  expression algebra with a well-founded measure (was a string toy). Π5 now tests
  determinism *under shuffled evaluation order* (was the same function twice). Π6
  now compares two genuinely independent algorithms — Horner vs power-series (was
  associativity of one fold).
- **Behavioral quine-seal** (Π18) closes the source-vs-behavior gap.
- **Precision** added to gap arithmetic (`0 · unknown = 0`, sound *and* precise).
- **Corpus non-degeneracy** asserted, so no predicate passes vacuously.

**An emergent insight from the hardening:** adding the precision rule *broke* Π16
— because `0 · hole` is now soundly `Known(0)` despite an unresolved hole, which
violated the naive invariant "Known iff no holes remain." That invariant was
wrong. The truer one — **"a Known partial result is stable under every resolution
of the remaining holes"** (soundness proper) — is what Π16 now checks, and it is
*compatible* with precision. The more precise engine forced the more honest
invariant into the open. The charter caught its own author, again.

## What is genuinely novel

In isolation, none of these primitives is unprecedented (reversible execution,
content-addressed code, symbolic execution, taint tracking, reflection all
exist). **The novelty is the enforced conjunction.** Provable forgetting (Π17)
is the clearest example: "append-only yet provably forgettable, with continuity
and blast-radius" is a contradiction-in-terms everywhere else, and it dissolves
only because typed gaps + provenance + content-addressing + conservativity all
hold simultaneously.

## The synergy is the point (Π14 / C1 at capability scale)

These are not four features; they are a dependency stack where each reuses the
ones beneath it — which is the charter's own "mutually beneficial connections"
criterion, demonstrated at the level of capabilities:

```
Π15 negative knowledge  (provenance gaps)
   └─► Π16 compute-with-holes      (partial computation over them)
          └─► Π17 provable forgetting   (redaction = holes applied to the chain)
                 └─► Π18 quine-seal      (seals all of it + its own source)
```

And because the extension touches **no base module**, the base 15 predicates and
their seal `b6bc80d6…683a` are unchanged — so the extension is *its own proof of
Π8 (conservative extension)*: adding four capabilities harmed nothing prior.

## Honest scope

This is a proof of concept at small scale, in Python, with `hashlib` standing in
for `sha256.iii`. It does not prove III itself perfect. The quine-seal proves an
instance, not global consistency. The capabilities are demonstrated on small
fixtures; a real III port wires them to the live `.iii` substrate per the roadmap
in `ARCHITECTURE.md`.
