# III Perfection Charter — Proof of Concept

A small, runnable, **stdlib-only** substrate that embodies the *checkable*
predicates of the Perfection Charter and **audits itself**. It is the executable
answer to the question we worked through: *what does "mathematically perfect
baseline" mean, concretely, and how would you prove it?*

The thesis made runnable: **perfection is not gaplessness — it is a maintained,
falsifiable status.** Every predicate ships with a positive check (`verify`) and
a negative check (`falsify`, a deliberately-bad case that must be caught). A
predicate HOLDS only if the good case verifies *and* the bad case is rejected.
The audit content-addresses its own result into a reproducible seal.

## Run it

```
python run_audit.py            # base self-audit (19 predicates); exit 0 iff all hold
python selftest_mutation.py    # proves the base audit DISCRIMINATES (10 faults caught)
python run_ext_audit.py        # extended audit: base 19 + 5 extensions = 24
python selftest_ext_mutation.py# proves the 5 extension predicates discriminate
```

Requires only Python 3 (built with 3.14, standard library only).

## Verified result (this build)

```
base predicates    : 19 / 19
extended           : 24 / 24     (base + Π15..Π19)
base seal          : 16fe0950bc35faca77f3ae9f9e85e5d1bba0c417ef01b603c6beebbba78abe95
deterministic      : YES (identical within a run AND across separate processes)
MUTATION SELF-TESTS: PASS  (base: 10 injected faults caught; extension: 5 caught)
```

## The predicates

| ID | Predicate | What the POC actually demonstrates | Module |
|----|-----------|-------------------------------------|--------|
| Π1 | Soundness | a real proof kernel (Curry–Howard STLC) proves tautologies and **cannot inhabit `False`**; dropping the argument-check makes `False` provable — caught | `kernel.py` |
| Π2 | Decidable checking | type-checking is total + deterministic + structurally terminating; a checker with no well-founded measure fails to decide — caught | `kernel.py` |
| Π21 | Inductive + structural recursion | inductive `Nat` + a structural recursor that **strongly normalizes**; the type system rejects the non-terminating Ω — caught | `kernel.py` |
| Π22 | Strict positivity | strictly-positive inductives accepted; a non-positive `Bad = C(Bad→Bad)` (which would break normalization) is rejected — caught | `kernel.py` |
| Π3 | Confluence | two **different** reduction orders reach the same normal form (traces proven to differ); a non-confluent system is flagged | `rewrite.py` |
| Π4 | Strong normalization | a shrinking rewrite terminates; a growing one is caught at the step cap | `rewrite.py`, `charter.py` |
| Π5 | Determinism | a pure pipeline reproduces; a stateful one is caught | `charter.py` |
| Π6 | Bit-identity | two different fold algorithms produce byte-identical output; a divergent impl is caught | `charter.py` |
| Π7 | Seal stability | equal data hashes equally regardless of construction order; naive serialization drift is caught | `mhash.py` |
| Π20 | Hand-rolled SHA-256 fidelity | a from-scratch SHA-256 matches the reference on KATs and the canonical encoder; a corrupted round constant is caught | `sha256_nih.py` |
| Π8 | Conservative extension | resolving a contingent gap never moves a prior concrete sub-result; a destructive resolver is caught | `gapval.py` |
| Π9 | Reversibility (SID) | every cycle of ops round-trips to its origin; an info-losing op breaks it | `reversible.py` |
| Π10 | Gated evolution | the op registry admits bijections, refuses untagged-lossy ops, allows typed irreversibility | `reversible.py` |
| Π11 | Declared uncertainty | every result is a typed value; a gap is always a typed `Gap`, never silent | `gapval.py` |
| Π12 | Self-audit | the audit's own description hashes reproducibly; a nondeterministic seal is caught | `charter.py` |
| Π13 | Gap-totality | arithmetic is total + sound across gaps (div-by-zero → gap, never a crash or a lie) | `gapval.py` |
| Π14 | Non-malign composition | a module is unperturbed by data it doesn't depend on; a side-channel is caught | `modules.py` |
| C1 | Gap-containment | a gap stays at the edge that consumes it and never corrupts a third module | `modules.py` |
| REP | Representability | the catastrophic "bricking" hexads are structurally untypable; a naive check that would admit one is caught | `hexad.py` |

## Foundational extensions (Π15–Π19)

Five capabilities *uniquely enabled by the charter's full conjunction*, added
additively. All **24 predicates hold**; both mutation suites confirm they
discriminate. Earlier passes unified the substrate (one gap type, one ledger),
de-faked the base Π4/Π5/Π6, and filled the honesty gaps: real kernel soundness
(Π1/Π2), inductive recursion + strong normalization (Π21), strict positivity
(Π22), hand-rolled hash (Π20), deep behavioral seal (Π18). See `EXTENSIONS.md`
and `GAPS-FILLED.md` for detail.

| ID | Capability | What's genuinely new |
|----|-----------|----------------------|
| Π15 | Negative knowledge | ignorance that explains + audits itself (provenance DAG) |
| Π16 | Compute-with-holes | a soundness-of-partial guarantee + conservative resolution |
| Π17 | Provable forgetting | continuity-preserving, blast-radius-marked erasure with a proof |
| Π18 | Quine-seal (behavioral) | a reflective fixpoint over source AND executed bytecode |
| Π19 | Sovereign Value | one type carrying payload(gap+provenance)+hexad+witness — properties intrinsic, not bolted-on |

## Honest boundary (what this is NOT)

This is a **proof of concept of the charter's mechanism**, at small scale, in
Python. It is *not* the III kernel and does not prove III itself perfect.

**Gaps since filled** (see `GAPS-FILLED.md`):
- ~~Π1 scoped to algebra~~ → **closed**: real logical soundness via a proof kernel
  (`kernel.py`); `False` is uninhabited as a *theorem*.
- ~~Π2 by-construction~~ → **closed**: a real decidability check.
- ~~kernel is just STLC~~ → **narrowed**: now has **inductive types + a structural
  recursor with strong normalization** (Π21) and **strict positivity** (Π22) —
  two of CIC's three consistency pillars, demonstrated. Anchor **A1** is
  *demonstrated for this logic*.
- ~~`hashlib` standin~~ → **closed**: SHA-256 is hand-rolled (`sha256_nih.py`),
  KAT-verified, and a proven drop-in `mhash` backend; `hashlib` is now only an oracle.
- ~~behavioral seal is predicate-level~~ → **closed**: Π18 seals every package
  function's bytecode. *Residual:* can't see C-level builtins; bytecode is
  interpreter-version-specific.

Still out of scope, deliberately (the honest ceiling):
- This is a small-scale Python POC; it does **not** prove III itself perfect.
- The kernel still lacks **dependent Π-types** and **universe stratification**
  (the third CIC pillar) — full dependent CIC is the remaining frontier.
- The unbuilt charter items (Wesolowski VDF, BLAKE3) remain absent — the POC only
  models predicates that are genuinely demonstrable.

## Mapping to real III

| POC module | Models the III component |
|------------|--------------------------|
| `trit.py`, `hexad.py` | the asymmetric-ternary Hexad algebra + Representability Theorem |
| `gapval.py` | the `Uncertainty` type + Kleene three-valued totality |
| `mhash.py` | `numera/sha256.iii` content addressing / `mhash` |
| `reversible.py` | SID (Side-effect Inverse Derivation) + Compromise tiers |
| `rewrite.py` | XII confluent rewriting + strong normalization |
| `witnesscommons.py` | the witness chain + `algebraic_time.iii` |
| `modules.py` | cross-module composition over the verified value bus |
| `kernel.py` | the CIC proof kernel (`TYPES/src/cic.c`) — STLC + inductive `Nat` + structural recursor + strict positivity |
| `sha256_nih.py` | the hand-rolled `numera/sha256.iii` |
| `charter.py` | the conformance corpus + the full predicate lattice |

## Layout

```
PERFECTION-POC/
  run_audit.py             # entry point: base self-audit (17)
  run_ext_audit.py         # entry point: extended audit (22)
  selftest_mutation.py     # meta-proof: base audit discriminates (8 faults)
  selftest_ext_mutation.py # meta-proof: extension predicates discriminate (5 faults)
  README.md
  ARCHITECTURE.md          # the condensed design record (/architect)
  EXTENSIONS.md            # the foundational extensions (Π15–Π19)
  GAPS-FILLED.md           # the gap-filling pass (Π1/Π2 kernel, Π20 hash, deep Π18)
  perfection_charter/
    __init__.py
    mhash.py               # content addressing (canonical, deterministic)
    trit.py                # asymmetric ternary algebra (the gap is a value)
    hexad.py               # 6-pillar hexad + representability
    gapval.py              # gap-aware, total, sound arithmetic
    reversible.py          # SID reversibility + gated admission
    rewrite.py             # confluence + strong normalization
    witnesscommons.py      # hash-chained witness commons
    modules.py             # non-malign composition + gap-containment
    kernel.py              # Π1/Π2 proof kernel (STLC + Curry–Howard)
    sha256_nih.py          # Π20 hand-rolled SHA-256 (FIPS 180-4)
    charter.py             # the base predicate registry + self-audit engine
    negknow.py             # Π15 negative knowledge (provenance gaps) -- THE unified gap type
    holes.py               # Π16 compute-with-holes (sound partial)
    forgetting.py          # Π17 provable forgetting (reversible redaction)
    quineseal.py           # Π18 quine-seal (source + DEEP bytecode behavioral fixpoint)
    sovval.py              # Π19 the Sovereign Value (payload + hexad + witness, unified)
    charter_ext.py         # the extension predicate registry + combined audit
```
