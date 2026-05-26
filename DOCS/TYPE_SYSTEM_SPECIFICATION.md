# Type System Specification & Status

Authority for the substrate's type system: the CIC kernel, proof inheritance,
proof caching, the tactical library, and the effect-inference completion to seven
bits. Grounded in the **real** kernel at `TYPES/src/cic.c` + `TYPES/src/type_repr.c`
(not the idealized plan's hypothetical `.iii` modules).

## Status

The CIC kernel **exists** in C (`TYPES/src/cic.c`, with the reduction-composition
surface in `TYPES/src/type_repr.c`); per the RITCHIE audit it is sound for the V1
fragment (~888 LOC) but does not yet span full predicative CIC (Prop-irrelevance,
universe polymorphism, general guarded fixpoint, dependent MATCH elaboration,
coinduction are the deepening targets — forward-reference #25). This document is
the contract that deepening satisfies.

## CIC kernel surface

Canonical inductive types the kernel validates (constructors in parens):
`nat` (`zero`, `succ`), `list a` (`nil`, `cons`), `prod a b` (`pair`),
`sum a b` (`inl`, `inr`), `option a` (`none`, `some`), and the substrate's
distinguished `witness_chain` inductive (constructors per the fragment-kind
taxonomy in `sanctus/witness.iii`).

**Kind judgment:** a type `T` is admitted iff every constructor's argument types
are themselves admitted and no constructor references `T` in a non-strictly-positive
position. **Reduction:** beta (application), delta (definition unfolding), iota
(inductive eliminators). The deepening (#25) adds: Prop-irrelevance (Prop-typed
terms convertible up to definitional equality), universe polymorphism
(`iii_universe_t` as a use-site-instantiated variable), general guarded fixpoint
with positivity check, dependent MATCH (motive dependently typed), and coinduction
for the cycle calculus.

## Proof inheritance

When `f` extends parent `g`'s body (open-recursion pattern) and `g` is proven to
satisfy property `P` invariant under the extension, `f` inherits `g`'s proof if
(a) the extension preserves `P`'s antecedent (the witness-chain antecedent set,
W26) and (b) each additional case satisfies `P` independently. Decidable; on
admission the cache records the parent proof's master hash as the inherited
proof's antecedent.

## Proof caching

Cache key = Keccak-256 of the obligation's canonical serialisation `(function_id,
property_statement, hypothesis_set)`. Cache value = the proof term (when small
enough to inline) or a canonical reference to the proof's origin in the
math-library queue (once forward-reference #10's admission tactic lands).
Invalidation: when the source function's master hash changes (V2 `cp_proof_cache`).

## Tactical library (four V1 tactics)

| Tactic | id | Discharges by | Succeeds when |
|--------|----|---------------|----|
| `TAC_DECIDE` | 1 | finite case enumeration on a bounded type | every case's conclusion holds |
| `TAC_REFLECT` | 2 | computation (iota reduction) | obligation reduces to the `true` constructor |
| `TAC_INDUCT` | 3 | induction on a named inductive | base + step cases each discharge |
| `TAC_AUTO` | 4 | substrate term rewriting (the 44 XII rules, see `DOCS/XII_CONFLUENCE_SPECIFICATION.md`, plus admitted math-queue theorems) | obligation rewrites to `true` |

Dispatch is a table mapping tactic id → handler against the kernel's term
representation.

## Effect-inference completion to seven bits (forward-reference #27)

V1 four bits (forward-reference #18): `READ=0`, `WRITE=1`, `ALLOC=2`, `EMIT=3`.
The three Stage-8 additions: `CAP_PROMOTE=4` (transitions a capability to a higher
Ring), `RING_TRANSIT=5` (crosses a Ring boundary), `REFLECT=6` (reflects on own
structure). Wire format: the 7-bit bitmap packed into one byte, stored at the
witness-fragment-header reserved byte (final byte offset deferred to the real
header layout in `sanctus/witness.iii`). `@pure` ⇒ bits 1,2,3,4,5 zero (read +
reflect permitted); `@bijective` ⇒ same + the W26 antecedent-closure condition.

## Verification gate (forward-reference #25)

A corpus test asserts: the CIC kernel accepts the six canonical inductives with
byte-exact expected normal forms; the proof cache produces byte-equal keys for the
substrate's existing proof obligations; the tactical library dispatches all four
tactics to their handlers; the effect bitmap on a known function set matches the
expected seven-bit values. Run via `TYPES/build/iii_types_test.exe` +
`STDLIB/scripts/run_corpus.sh`.
