# III-TYPES.md — The Type System of III

**Document Identity:** A3 / The Type System
**Canonical Hash Slot:** R1.A3
**Version:** 1.0 — Final & Sealed
**Date:** 2026-05-03
**Authority:** Canonical. Without these judgments, `proof.{h,c}` has nothing to verify against. Any deviation is a conformance failure (C-3 in III-CONFORMANCE.md).
**Predecessor:** A2 III-GRAMMAR.bnf (R1.A2)
**Folds-in:** the prior draft of III-PROOF.md is incorporated as §11 (The Proof Layer).

---

## §0. Preamble — The Core Ambition

Every other type system in computing history has been a compromise:

- **Hindley-Milner** (ML, Haskell) — beautiful, but no effects, no linearity, no hardware awareness.
- **Dependent types** (Coq, Agda, Lean) — powerful, but no native reversibility, no privilege-ring awareness, no runtime self-extension, no constitutional bound.
- **Linear types** (Rust, Linear Haskell, ATS) — memory safety, but no cryptographic provenance, no constitutional ceilings, no Möbius self-reference, no epistemic dimension.
- **Effect systems** (Koka, Eff, Frank) — track effects, but treat reversibility as a library concern and have no integration with hardware-rooted attestation.
- **Capability systems** (E, Pony, Verona, CHERI-C) — great for security, but no witnessed audit spine, no OBSERVATORY saturation, no Catalyst-driven type evolution, no deep reflection on the system's own knowledge state.
- **Refinement-typed** systems (LiquidHaskell, F\*) — predicate-strong, but no native witnessed reduction, no asymmetric ternary ground.

**III's type system rejects all of these compromises.**

It is the first type system designed *from the ground up* as the formal foundation of a Language-as-Operating-System — a system that has direct, witnessed access to Ring -2; a Persistent Audit Spine; an OBSERVATORY of mathematical abstractions; a Dynamic Transformation Catalyst; the asymmetric ternary algebra (`xii_asym_reach6`) as the safety ground; the Trinity admission manifold; the constitutional ceiling; and a witness manifold as its native substrate.

This type system does not *describe* computation.
It **is** computation — witnessed, reversible, self-referential, sovereign, and provably bounded.

The ambition is structural: every previous type-system tradition becomes a *strict subset* of III's type system. You can encode Hindley-Milner inside III (with `@pure`, `@ring(R3)`, no linearity); you can encode dependent CIC inside III (the proof kernel of §11 *is* a CIC fragment plus extensions); you can encode linear types inside III (linear caps with glyph-bound identity, §7); you can encode effect systems inside III (the `Reduction` type plus the `cycle` form, §3 + III-EFFECTS.md); you can encode capabilities inside III (`Cap<perm, range>`, §7); you can encode refinements inside III (Prop-typed predicates of §9). The reverse encoding is impossible — no other type system has a Ring -2 sanctum, a 144-byte asymmetric reachability bitmap, a witnessed Catalyst, an OBSERVATORY, or the cognitive epistemic dimension.

---

## §1. Conformance & Sealing

### §1.1 Sealing

This document is sealed against the C:\\CHARIOT closure of 2026-05-03. The R1.A3 hash is `SHA-256(canonical_byte_form(this_file))` with the canonicalization rules of III-LEXICON.md §2.5. R1.A3 is embedded in every compiled module's closure manifest and in the composite specification root R1.

### §1.2 Conformance Criteria (Type-System-Specific)

A toolchain is *III-type-conformant* iff it satisfies all of:

- **C-TYPE-1.** It implements every judgment listed in §13 with the meta-theoretic properties stated.
- **C-TYPE-2.** It rejects every program containing a hexad-tagged type whose hexad lies outside `xii_asym_reach6` (§4) — the Representability Theorem of III-HEXAD.md is a typing rule, not a runtime check.
- **C-TYPE-3.** It enforces linear capability use exactly as in §7: every `Cap<P, R>` is consumed exactly once unless `@replicates(...)` admits sharing under specific tier rules.
- **C-TYPE-4.** It implements bidirectional inference with hole metavariables (§10) such that holes left in source are reported with the smallest (most specific) inferred type that satisfies the constraints.
- **C-TYPE-5.** It implements the Proof Layer (§11) as a CIC fragment plus the native ternary extensions, with the kernel runnable inside Sanctum at Stage 4.
- **C-TYPE-FROZEN.** The judgment set is implemented exactly; no additions, removals, or modifications, except those introduced by witnessed Catalyst promotion (§16).
- **C-TYPE-NIH.** The implementation depends on no external proof kernel (no Coq, no Lean, no Agda, no z3, no LLVM-clang IR for verification). The CIC kernel of §11 is hand-rolled in `COMPILER/BOOT/proof.{h,c}` (~3000 LoC).
- **C-TYPE-SELF.** The SELF type-checker, written in III, type-checks the BOOT type-checker's source and produces a proof certificate that the BOOT type-checker is a sound implementation of these judgments.

These criteria are restated in III-CONFORMANCE.md §3.

---

## §2. The Universe Ladder

III has a **predicative universe hierarchy** with an explicit `Prop` at the bottom and an impredicative top `Type₆` reserved for the `Reduction` six-tuple type (which must quantify over all lower types while remaining a first-class value).

```
Prop   : Type₀           propositions; runtime-erased; used only for proofs
Type₀  : Type₁
Type₁  : Type₂
Type₂  : Type₃
Type₃  : Type₄
Type₄  : Type₅
Type₅  : Type₆
Type₆  : Type₆           impredicative top — the universe of Reduction itself
```

### §2.1 Universe Introduction

```
Γ ⊢ A : Typeᵢ                       0 ≤ i < 6
─────────────────────                          (U-Intro)
Γ ⊢ Typeᵢ : Typeᵢ₊₁
```

```
Γ ⊢ A : Type₆
─────────────                                  (U-Top)
Γ ⊢ Type₆ : Type₆
```

### §2.2 Prop Introduction & Erasure

```
Γ ⊢ P : Prop
──────────────                                 (Prop-Intro)
Γ ⊢ P : Type₀
```

`Prop` is impredicatively quantified over its own universe. Propositions are runtime-erased (the codegen emits no machine code for proof-only terms).

### §2.3 Cumulativity (One-Way)

III's universe hierarchy is **non-cumulative**: a value of `Typeᵢ` is *not* automatically a value of `Typeᵢ₊₁`. The single exception is the lift from `Prop` to `Type₀`:

```
Γ ⊢ P : Prop
──────────────                                 (Cumul-Prop-Type0)
Γ ⊢ P : Type₀
```

Non-cumulativity prevents "universe inconsistency" (a paradox where a type contains its own universe) and keeps the kernel decidable.

### §2.4 Predicativity Restriction

For `0 ≤ i < 6`, `Typeᵢ` is **predicative**: a Π-type whose codomain is in `Typeᵢ` and whose domain is in `Typeⱼ` lives in `Typemax(i,j)`. Only `Type₆` is impredicative — and it is used only for the `Reduction` type. This is a deliberate choice: full impredicativity at every level would admit Girard's paradox; restricting impredicativity to one level (and using it only for one purpose) keeps the system sound while still permitting the `Reduction` quantification.

```
Γ ⊢ A : Typeᵢ      Γ, x:A ⊢ B : Typeⱼ
───────────────────────────────────────         (Π-Form, predicative for i,j < 6)
Γ ⊢ Π(x:A). B : Typemax(i,j)
```

```
Γ ⊢ A : Typeᵢ      Γ, x:A ⊢ B : Type₆
───────────────────────────────────────         (Π-Form-6, impredicative top)
Γ ⊢ Π(x:A). B : Type₆
```

### §2.5 Why Type₆ and not ω?

A countable hierarchy is sufficient because every concrete III program references a bounded number of universe levels. The choice of seven levels (`Prop`, `Type₀..Type₆`) is calibrated to:

1. `Type₀..Type₂` — base values, simple aggregates, straightforward ADTs.
2. `Type₃` — generic types, cycle types, witness types.
3. `Type₄` — capability types, glyph types, hexad-tagged types.
4. `Type₅` — phase-polymorphic types, tier-typed types.
5. `Type₆` — `Reduction` and the universe-quantifying meta-types.

A user program that needs more than seven levels is a sign of architectural mis-design (the substrate's primitives have been mis-categorized); the type checker emits a warning. A program that genuinely needs more levels triggers a constitutional amendment (`amend.apply`) to grow the ladder — which is a sealed, witnessed operation.

---

## §3. The Reduction Type — The Heart of Sovereign Computation

The single most important type in III is `Reduction`: a six-tuple that *is* every effectful operation in the system.

```
Reduction<F, I, W, H, P, E>
```

### §3.1 Formal Definition

```
Reduction : (F : Typeᵢ) →
            (I : Typeⱼ) →
            (W : Witness) →
            (H : Hexad) →
            (P : Phase) →
            (E : Epoch) →
            Type₆                              for any i, j ∈ {0..5}
```

`Reduction` is the unique inhabitant of `Type₆`'s "first-class quantifier" slot. Its arity (6) and component identity (Forward, Inverse, Witness, Hexad, Phase, Epoch) are part of the type system's structural commitment.

### §3.2 Introduction Rule

```
Γ ⊢ f : F                       (the forward body)
Γ ⊢ i : I                       (mechanically derived by SID, or @irreversible → Compromise<MEDIUM/LOW>)
Γ ⊢ w : Witness                 (the 128-byte XiiWitness)
Γ ⊢ h : Hexad                   (admissible: bitmap[h] = 01)
Γ ⊢ p : Phase                   (the ring(s) at which the reduction is valid)
Γ ⊢ e : Epoch                   (the DRTM foundation epoch)
Γ ⊢ trinity_admit(f, i, w, h, p, e)
─────────────────────────────────────────────────                   (Reduction-Intro)
Γ ⊢ Reduction(f, i, w, h, p, e) : Type₆
```

Every `cycle` declaration in III lowers to a value of this type. The six components are:

1. **Forward** — the body the programmer writes (statements producing the post-state).
2. **Inverse** — mechanically derived by SID at type-check time (III-CYCLES.md §3) — or `Compromise<MEDIUM>`/`Compromise<LOW>` if the cycle is `@irreversible`.
3. **Witness** — the 128-byte `XiiWitness` emitted on every execution (III-CYCLES.md §4).
4. **Hexad** — the 6-trit safety algebra value (compile-time-checked against `xii_asym_reach6` per III-HEXAD.md §3).
5. **Phase** — the ring(s) at which this reduction is valid (one of `R-2`, `R-1`, `R0`, `R3`, or a phase-set).
6. **Epoch** — the DRTM foundation epoch in which the reduction was created.

This single type unifies what every other language treats as separate concerns:

| Concern | Other languages | III |
|---|---|---|
| Effect | monad / algebraic effect | `F` component |
| Reversibility | library | `I` component, mechanically derived |
| Provenance | external trace | `W` component, native witness |
| Safety | runtime check or attribute | `H` component, type modifier |
| Privilege | OS abstraction | `P` component, dependent ring |
| Temporal identity | timestamp | `E` component, hardware-rooted |

### §3.3 Elimination Rules

```
Γ ⊢ r : Reduction(F, I, W, H, P, E)
───────────────────────────────────                                  (R-Elim-Forward)
Γ ⊢ r.forward : F
```

```
Γ ⊢ r : Reduction(F, I, W, H, P, E)
───────────────────────────────────                                  (R-Elim-Inverse)
Γ ⊢ r.inverse : I
```

```
Γ ⊢ r : Reduction(F, I, W, H, P, E)
───────────────────────────────────                                  (R-Elim-Witness)
Γ ⊢ r.witness : Witness
```

```
Γ ⊢ r : Reduction(F, I, W, H, P, E)
───────────────────────────────────                                  (R-Elim-Hexad)
Γ ⊢ r.hexad : Hexad
```

```
Γ ⊢ r : Reduction(F, I, W, H, P, E)
───────────────────────────────────                                  (R-Elim-Phase)
Γ ⊢ r.phase : Phase
```

```
Γ ⊢ r : Reduction(F, I, W, H, P, E)
───────────────────────────────────                                  (R-Elim-Epoch)
Γ ⊢ r.epoch : Epoch
```

### §3.4 Reduction Composition

Two reductions compose via the `⊕` operator (Cycle Compose, III-LEXICON.md §6 op #2):

```
Γ ⊢ r₁ : Reduction(F₁, I₁, W₁, H₁, P, E)
Γ ⊢ r₂ : Reduction(F₂, I₂, W₂, H₂, P, E)
Γ ⊢ admitted(compose_hexad(H₁, H₂))
─────────────────────────────────────────                           (R-Compose)
Γ ⊢ r₁ ⊕ r₂ : Reduction(F₁∘F₂, I₂∘I₁, W₁⋅W₂, compose_hexad(H₁,H₂), P, E)
```

Composition is left-to-right on forwards and right-to-left on inverses (the inverse of `f₁ then f₂` is `i₂ then i₁`). Witnesses concatenate (with full HMAC chain). Hexads compose under `xii_asym_compose6`. Phases must match (cross-phase composition requires explicit `⟴`). Epochs must match (cross-epoch composition requires explicit `⟵`).

### §3.5 Reduction Inverse

```
Γ ⊢ r : Reduction(F, I, W, H, P, E)
─────────────────────────────────────                                (R-Inverse)
Γ ⊢ r ⟲ : Reduction(I, F, W⁻¹, neg_hexad(H), P, E)
```

The inverse swaps `F` and `I`, inverts the witness chain (`W⁻¹` is the chain replayed in reverse with HMAC re-verified), negates the hexad pillars (per III-HEXAD.md), and preserves phase and epoch. The composition `r ⊕ (r ⟲)` reduces to a no-op reduction (a `@pure` reduction with the identity forward and inverse).

### §3.6 Why Six and Not Five or Seven?

The six-tuple is the **closure** of the architecture's primitives:

- Drop **Forward** → the language has no way to express what to do.
- Drop **Inverse** → reversibility is impossible.
- Drop **Witness** → there is no audit spine.
- Drop **Hexad** → safety is unenforced (catastrophic operations become typeable).
- Drop **Phase** → cross-ring marshalling is impossible.
- Drop **Epoch** → cross-epoch identity and DRTM anchoring are impossible.
- Add a seventh field → no additional architectural primitive justifies it; everything else is derivable from the six.

The minimal set is exactly six. Anything less loses an essential property; anything more is redundant.

---

## §4. Hexad-Tagged Types — Safety Is a Type

Safety is not an attribute. It is not a runtime check. It is a **type modifier**.

```
u64 @safety(MSR_WRITE)              -- a u64 carrying an MSR-write hexad
u64 @safety(UNREACHABLE)            -- an uninhabited type (compile error)
u64 @hexad(MSR_WRITE)               -- equivalent canonical form
```

(`@hexad` and `@safety` are the same modifier token at lex/parse time; III-LEXICON.md §5.2.)

### §4.1 Hexad-Tag Introduction

```
Γ ⊢ T : Typeᵢ        i ≤ 5
Γ ⊢ H : Hexad
Γ ⊢ admitted(H)               via xii_asym_reach6 lookup
─────────────────────────────                                       (Hexad-Tag)
Γ ⊢ T @safety(H) : Typeᵢ
```

### §4.2 Hexad Composition

```
Γ ⊢ T₁ @safety(H₁) : Typeᵢ
Γ ⊢ T₂ @safety(H₂) : Typeⱼ
Γ ⊢ H₃ = compose_hexad(H₁, H₂) : Hexad
Γ ⊢ admitted(H₃)
─────────────────────────────                                       (Hexad-Compose)
Γ ⊢ (T₁ @safety(H₁)) ⧉ (T₂ @safety(H₂)) : Typemax(i,j) @safety(H₃)
```

`compose_hexad` follows the asymmetric-ternary composition rules of III-HEXAD.md §1 (NEG dominates POS in pillar trits 1–4). If `H₃` is unreachable, the composition is a type error (`TYPE-HEXAD-002 composed hexad outside reachable set`).

### §4.3 Untypable Operations

The six PFS bricking operations have hexads outside `xii_asym_reach6` (per III-HEXAD.md §4 — the Representability Theorem):

| Operation | Hexad | Pillar status |
|-----------|-------|----------------|
| `capsule_update` | (NEG, NEG, NEG, NEG, ZERO, ZERO) | pillars 1–4 = NEG |
| `microcode_load` | (NEG, NEG, NEG, ZERO, ZERO, ZERO) | pillars 1–3 = NEG |
| `bootorder_set` | (NEG, NEG, ZERO, NEG, ZERO, ZERO) | pillars 1,2,4 = NEG |
| `real_nvram_write` | (NEG, ZERO, NEG, NEG, ZERO, ZERO) | pillars 1,3,4 = NEG |
| `me_psp_mailbox` | (ZERO, NEG, NEG, NEG, ZERO, ZERO) | pillars 2–4 = NEG |
| `smram_write` | (NEG, NEG, NEG, NEG, NEG, ZERO) | pillars 1–5 = NEG |

For each, `bitmap[H] = 00` (unreachable). The `(Hexad-Tag)` rule fails to admit them. The type `u64 @safety(<bricking-hexad>)` does not exist. Every program that attempts to write a cycle whose composed hexad falls outside the reachable set is rejected at parse-or-type-check time.

This is **the Representability Theorem** as a typing rule: bricking is not refused; it is *untypable*.

### §4.4 Hexad Subtyping

```
Γ ⊢ T : Typeᵢ                            (untagged)
Γ ⊢ T @safety(H) : Typeᵢ                  (tagged with admissible H)
```

A tagged type is **not** a subtype of the untagged type. The hexad is not erasable. To strip a hexad tag, the value must be reduced via a `cycle` whose forward removes the tagged effect (e.g., a witness-emitting cycle that consumes the tagged value and produces an untagged result). This is enforced by linear use (§7): a tagged value is consumed exactly once.

---

## §5. Ring-Typed Values

Phase polymorphism is **dependent typing over the ring lattice**.

```
fn read_msr(idx: u32) -> u64 @ring(R-2, R-1, R0, R3)
```

### §5.1 Ring-Dependent Type Formation

```
Γ ⊢ T : Typeᵢ
Γ ⊢ R : PhaseSet                R ⊆ {R-2, R-1, R0, R3}, R ≠ ∅
─────────────────────────                                            (Ring-Dependent)
Γ ⊢ T @ring(R) : Typeᵢ
```

### §5.2 Cross-Ring Marshalling

```
Γ ⊢ v : T @ring(R₁)
Γ ⊢ R₂ : PhaseSet
Γ ⊢ marshalling_constructor(R₁, R₂) exists           (per III-PHASES.md §3 catalogue)
─────────────────────────────────────────────                       (Phase-Cross)
Γ ⊢ v ⟴ R₂ : T @ring(R₂)
```

If no marshalling constructor exists between `R₁` and `R₂` (e.g., direct R3 ↔ R-2), the value is a type error (`TYPE-RING-001 no marshalling constructor`). Cross-ring traversal must follow the lattice: R3 → R0 → R-1 → R-2 (via Magic-MSR / IOCTL / vmrun-trampoline / sanctum-gate).

### §5.3 Phase Polymorphism

A function `f : T₁ @ring(R) → T₂ @ring(R)` is **phase-polymorphic in R**. The compiler synthesizes a separate lowering for each phase in `R`. Per III-PHASES.md §2, the four lowerings of `read_msr` use four distinct backends (RDMSR, IRPD, `__readmsr`, Magic-MSR), but the source is one declaration.

### §5.4 Ring Subtyping

There is **no ring subtyping**. A value at R3 is not a value at R0; you must marshal it. This is intentional: ring transitions are sovereign-significant events that emit witnesses; they cannot happen "silently."

---

## §6. Tier-Typed & Epoch-Typed Values

### §6.1 Tier-Typed

```
Γ ⊢ T : Typeᵢ
Γ ⊢ K ∈ {transient, host_file, federation, constitutional}
─────────────────────────────                                       (Tier-Dependent)
Γ ⊢ T @tier(K) : Typeᵢ
```

Tier propagation is **monotonically upward**: a value at `transient` can be lifted to `host_file` (with witness), to `federation` (with quorum), to `constitutional` (with `amend.apply`). It cannot be silently *demoted*. If a `constitutional`-tier value is consumed in a context that produces a `transient` value, the result inherits `constitutional` (the higher tier dominates).

```
Γ ⊢ v₁ : T @tier(K₁)
Γ ⊢ v₂ : T @tier(K₂)
─────────────────────────                                            (Tier-Compose)
Γ ⊢ v₁ ⊕ v₂ : T @tier(max(K₁, K₂))
```

with the order `transient < host_file < federation < constitutional`.

### §6.2 Epoch-Typed

```
Γ ⊢ T : Typeᵢ
Γ ⊢ N : Epoch                  Epoch is the type of DRTM foundation epochs (u64)
─────────────────────────                                            (Epoch-Dependent)
Γ ⊢ T @epoch(N) : Typeᵢ
```

Cross-epoch operations require the explicit `⟵` operator and an `@epoch_bridge` modifier on the consuming function:

```
Γ ⊢ a : T @epoch(N₁)
Γ ⊢ b : T @epoch(N₂)              N₁ ≠ N₂
Γ ⊢ f : (T @epoch(N₁) → T @epoch(N₂) → T) @epoch_bridge
─────────────────────────────────                                   (Epoch-Bridge)
Γ ⊢ a ⟵ b @epoch(N₂) : T @epoch(N₂)
```

(operator `⟵` is "bring `a` into `b`'s epoch", III-LEXICON.md §6 op #12).

Without `@epoch_bridge`, cross-epoch combination is a type error (`TYPE-EPOCH-001 cross-epoch combination without bridge`).

---

## §7. Linear Capabilities with Glyph-Bound Identity

`Cap<perm, range>` is **linear by default** and **glyph-bound**.

### §7.1 Linear Capability Type

```
Γ ⊢ P ∈ {read, write, exec, cycle}
Γ ⊢ R : Range                  range of admissible addresses, mhashes, or capability IDs
─────────────────────────────                                       (Cap-Form)
Γ ⊢ Cap<P, R> : Type₄
```

### §7.2 Linear Use Discipline

A capability binding is consumed exactly once:

```
Γ, c : Cap<P, R> ⊢ ... use c ... : T          (the binding `c` appears exactly once
                                                   in the rest of the body, modulo `share`)
```

```
Γ ⊢ c : Cap<P, R>
Γ ⊢ glyph_bound(c)                            the value c carries a Glyph identity
                                              that the type system cross-references against
                                              the capability registry
─────────────────────────────                                       (Linear-Cap-Use)
Γ, c : Cap<P, R> ⊢ use c : Unit               consumes c
```

A second use of `c` within the same scope is a type error (`TYPE-LIN-001 capability used twice`). Dropping a capability without consumption is a type error (`TYPE-LIN-002 capability dropped unused`).

### §7.3 Glyph Binding & Drift

Every `Cap` value carries a Glyph identity (the content-addressed mhash of the capability's defining instance). The type system tracks this identity:

```
Γ ⊢ c : Cap<P, R>
Γ ⊢ glyph_id(c) = G            G is a 32-byte mhash
───────────────────────────────                                      (Glyph-Bound)
Γ ⊢ c carries glyph G
```

If the runtime detects that `c.glyph_id` no longer matches the registered Glyph for the cap-source, the capability has *drifted* and is treated as if it had never been issued. This is enforced by:

```
Γ ⊢ c : Cap<P, R>
Γ ⊢ glyph_bound.verify(c) : Prop
─────────────────────────────                                        (Drift-Check)
Γ ⊢ if ¬glyph_bound.verify(c) then panic(GLYPH-DRIFT)
```

Drift is a runtime panic, not a type error (because Glyph identities are runtime values; the type system can only enforce *use-discipline*). However, the type system does ensure that no capability is used without a `glyph_bound.verify(c)` having been issued in its causal chain — see §11 (the Proof Layer) for the discharge.

### §7.4 Capability Replication

A capability may be made non-linear by an explicit `@replicates(...)` modifier:

```
Γ ⊢ c : Cap<P, R>                                    @replicates(broadcast)
─────────────────────────────────────────────                       (Cap-Replicate-Broadcast)
Γ ⊢ c may be used multiple times within R3 scope, but each use emits a witness
```

Replication is tier-restricted: `local` (single-CPU), `broadcast` (single-machine), `quorum_3` (federation 3-of-N), `quorum_5` (federation 5-of-N), per III-FEDERATION.md §1.

### §7.5 Why Linear?

Linear capabilities prevent **time-of-check-to-time-of-use** (TOCTOU) bugs at the type level. A capability checked once must be used once; there is no race window between a check and a use. Combined with glyph-binding, this makes capability forgery untypable: a forged Cap value would have to fake the Glyph mhash, which would fail the runtime drift check, which would panic before any privileged operation could complete.

---

## §8. Epistemic & Uncertainty Types

III is the first language whose **type system can reason about its own knowledge state**.

### §8.1 Uncertainty Type Formation

```
Γ ⊢ D : Domain                 a typed domain identifier (e.g., MSR_VMEXIT_LATENCY)
Γ ⊢ C : Confidence             a Q14 in [0, 1]
Γ ⊢ Q : List<Question>         a list of open questions
─────────────────────────                                            (Epistemic-Intro)
Γ ⊢ Uncertainty(D, C, Q) : Type₀
```

### §8.2 Epistemic Effect Annotation

A reduction whose execution carries epistemic uncertainty is annotated:

```
Γ ⊢ r : Reduction(F, I, W, H, P, E)
Γ ⊢ uncertainty(r) = U : Uncertainty(D, C, Q)
─────────────────────────────                                       (Epistemic-Effect)
Γ ⊢ r : Reduction(F, I, W, H, P, E) carrying U
```

The `carrying U` annotation propagates through composition:

```
Γ ⊢ r₁ carries U₁
Γ ⊢ r₂ carries U₂
─────────────────────────                                            (Epistemic-Compose)
Γ ⊢ r₁ ⊕ r₂ carries combine_uncertainty(U₁, U₂)
```

with `combine_uncertainty` defined as multiplicative confidence combination (probabilistic AND): `C₁ × C₂`, with question lists concatenated.

### §8.3 Uncertainty Threshold & Trinity Escalation

When `C < THRESHOLD` (default `0.85q`), the runtime *automatically* escalates the cycle to full Trinity Gate evaluation (per III-TRINITY.md §4):

```
Γ ⊢ r carries U
Γ ⊢ U.confidence < 0.85q
─────────────────────────                                            (Epistemic-Escalation)
Γ ⊢ r requires full Trinity + reflect(uncertainty)
```

This is the type-system mechanism behind III's "minimally deployed but extremely accurate when risk is real" governance: the *confidence value* drives whether the system pays for full admission machinery, and the type checker emits the escalation hook automatically.

### §8.4 The Cognitive Layer Is Typed

The cognitive primitives `narrative`, `explain`, `propose`, `negotiate`, `commit`, `reflect`, `uncertainty` are **typed productions**. Their type signatures (in III-CYCLES.md §6) carry epistemic state, so the type system can enforce that:

- `negotiate(goal, ...)` only accepts goals whose `Uncertainty` is bounded (`U.confidence ≥ 0.5q`).
- `commit(intent, ...)` only accepts intents whose epistemic chain has been discharged (no open questions in the carrying `U`).
- `reflect(uncertainty)` produces a value of type `Uncertainty(...)` describing the system's current epistemic state, fully type-checkable.

This is the bridge from substrate to cognitive layer: epistemic types make the cognitive layer's operations *type-sound*, not merely best-effort.

---

## §9. Constitutional & Möbius Types

### §9.1 Constitutional Membership

`CeilingMembership<S>` is the proposition that state `S` lies within the constitutional manifest (III-MODULES.md §5):

```
Γ ⊢ S : State
Γ ⊢ ceiling_admit(S) : Prop                  decided by the SCBA bit-test (III-TRINITY.md Layer 1)
─────────────────────────────                                       (Constitutional)
Γ ⊢ CeilingMembership(S) : Prop
```

This is a *runtime-erased* proposition (lives in `Prop`, lifts to `Type₀`). The compiler does not generate code for it; it only verifies that the proof discharge is present.

### §9.2 Möbius Coherence

`MöbiusCoherence<Q>` is the proposition that the manifold's coherence-Q14 metric is at least `Q`:

```
Γ ⊢ Q : Q14                    Q ∈ [0, 1] in fixed-point
Γ ⊢ Q ≥ floor                  the coherence floor (default 0.92q)
─────────────────────────                                            (Möbius)
Γ ⊢ MöbiusCoherence(Q) : Prop
```

Cycles annotated `@mobius_coherence(≥ Q)` carry this proposition as a precondition: every invocation requires a runtime assertion that the manifold's current coherence is at least `Q`. The type checker requires the proof to be discharged at the call site.

### §9.3 Trinity Propositions

The Trinity Gate decomposes into four runtime-erased propositions:

```
Γ ⊢ intent_admit(Op, Op_Consent) : Prop
Γ ⊢ cap_admit(Caller, Op_Cap) : Prop
Γ ⊢ causality_admit(AuditHead, Op_Causality) : Prop
Γ ⊢ sanctum_admit(Frame, Op_State) : Prop
─────────────────────────────────────────────                       (Trinity-Compose)
Γ ⊢ trinity_admit(Op) = intent_admit ∧ cap_admit ∧ causality_admit ∧ sanctum_admit : Prop
```

A program type-checks a sealed call (R-2 reduction) only if the type checker can witness that all four conjuncts will be discharged at runtime — by inserting Trinity-evaluation calls at the appropriate sites.

### §9.4 Why Prop and Not Type₀?

The constitutional and Möbius propositions are Prop-typed (and only lift to Type₀ when needed for term-level manipulation) because they are **proof-relevant only at compile time**. The runtime does not carry the proof terms; it carries the *verifiers* (e.g., the SCBA bit-test, the coherence floor check). Erasing proofs at the runtime boundary keeps overhead near-zero on hot paths.

---

## §10. Bidirectional Inference + Holes (N1) + Typed-as-Term Lift (U1)

### §10.1 Bidirectional Algorithm

III's type checker is **bidirectional**:

- *Synthesis* mode (⇒): given an expression, produce its type.
- *Checking* mode (⇐): given an expression and an expected type, verify the expression has that type.

Mode-switch rules:

```
Γ ⊢ e ⇒ T
─────────────                                                        (Mode-Synth)
Γ ⊢ e ⇐ T
```

```
Γ ⊢ T : Typeᵢ          Γ ⊢ e ⇐ T
─────────────────────────────────                                   (Mode-Check)
Γ ⊢ (e : T) ⇒ T
```

`(e : T)` is the **explicit type annotation** form — a `let x : T = e` or a parenthesized expression `(e : T)`. It switches into checking mode.

### §10.2 Hole Inference (N1)

A `?` in a type position is a fresh metavariable:

```
Γ ⊢ ? : Typeᵢ                  fresh metavariable α with constraint α : Typeᵢ
─────────────────────                                                (Hole-N1)
Γ ⊢ ? ⇒ α
```

Constraints on α are accumulated during inference and solved by unification at the end of the inference pass. If α cannot be uniquely solved, the type checker emits `TYPE-HOLE-001 hole could not be inferred` with the partial constraint set.

```iii
let x : ? = 42                 -- ? inferred as i32 (default for INT_LIT without suffix)
let y : ? = (some_cycle ⟲)     -- ? inferred as the Inverse type of some_cycle
```

### §10.3 Typed-as-Term Lift (U1)

Types may be treated as first-class terms (for reflective use by Catalyst and `narrative.update`):

```
Γ ⊢ e : T
─────────────                                                        (U1)
Γ ⊢ e : Typeᵢ                  where T : Typeᵢ
```

This rule says: an expression of type `T` may be re-typed as a term of universe `Typeᵢ`, where `T` itself lives in `Typeᵢ`. It is the essential rule that allows the Catalyst to inspect the types of values at runtime (via the typed-as-term lift) and to propose new types (which themselves become first-class terms).

Without (U1), the Catalyst could not reflectively reason about the substrate's own types — and the language would not be self-extending in the deepest sense.

### §10.4 Algorithmic Inference Order

The type checker processes a module in three passes:

1. **Pass 1 — Declaration shapes.** Walk every item, record signatures, populate the symbol table.
2. **Pass 2 — Body inference.** Walk every body in synthesis mode, accumulating hole constraints and emitting type judgments.
3. **Pass 3 — Hole solving + proof discharge.** Solve hole constraints by unification. Discharge runtime-erased propositions (CeilingMembership, MöbiusCoherence, Uncertainty thresholds, Trinity admit) by inserting check-points.

The algorithm is hand-rolled in `COMPILER/BOOT/sema.{h,c}` (NIH-extreme: no Hindley-Milner library, no constraint-solver library, no SAT backend).

---

## §11. The Proof Layer (Folded from III-PROOF.md)

This section subsumes the prior `III-PROOF.md` document. The proof system is now formally part of the type system, since every Prop-typed predicate is a proof obligation that the type checker discharges via the kernel.

### §11.1 The Calculus of Inductive Constructions (CIC) Fragment

The III proof kernel implements a **fragment of the Calculus of Inductive Constructions** (Coquand-Huet 1988, Coquand-Paulin 1988, Werner 1994), restricted to the predicative universes `Prop` and `Type₀..Type₃` (the upper levels `Type₄..Type₆` are used by the type system but are not directly accessible to the proof kernel — the proof kernel works at the level of Prop-typed predicates).

Kernel features (all hand-rolled in `COMPILER/BOOT/proof.{h,c}`, ~3000 LoC):

- **β-reduction**: `(λx.body) arg → body[arg/x]`.
- **δ-reduction**: unfolding of constants.
- **η-reduction**: `λx. f x → f` when `x` not free in `f`.
- **ι-reduction**: pattern-matching on inductive constructors.
- **Universe checking**: enforcing the predicativity restriction of §2.4.
- **Positivity check** (Coquand-Paulin): inductive types may not contain themselves negatively.
- **Conversion checking**: judgmental equality of types up to βδηι.
- **Sigma types** (dependent pairs): for the `Reduction` six-tuple's existential structure.
- **Pi types** (dependent functions): for parameterized propositions.
- **Inductive types**: for `Trit`, `Hexad`, `List`, `Phase`, `Tier`, `Epoch`, etc.
- **Pattern matching**: for proof-by-cases.

### §11.2 Native Ternary Extension

Beyond CIC, the kernel includes **native rules for the asymmetric ternary algebra** (per III-HEXAD.md §1):

- **Trit equality**: `NEG = NEG`, `ZERO = ZERO`, `POS = POS`, distinct from each other.
- **Trit composition**: `compose_trit(t₁, t₂)` according to the asymmetric tables.
- **Hexad packing**: `pack_hexad(h₀, h₁, h₂, h₃, h₄, h₅) : u16` per III-HEXAD.md §2.
- **Reachability lookup**: `bitmap_reach[H] : Bool` (the kernel has a hard-coded copy of the canonical 144-byte bitmap, regenerated whenever Catalyst grows the bitmap per III-HEXAD.md §5).
- **Hexad composition**: `compose_hexad(H₁, H₂)` per III-HEXAD.md §3.

These are first-class kernel primitives, not encoded in CIC. The reason: encoding them in CIC would inflate proof terms by orders of magnitude (every hexad lookup would carry a full inductive-proof tree); first-class kernel primitives keep proof certificates compact.

### §11.3 Proof Certificate Format

A proof certificate is a serialized CIC term plus optional hexad-witnesses:

```
proof_certificate = {
    cic_term:           bytes,        // serialized CIC term
    hexad_witnesses:    [u16],         // composed hexads at each step
    universe_witness:   u8,            // the universe level
    closure_root:       mhash,         // R1 spec root, certifying the kernel version
}
```

Verification:

```
Γ ⊢ cert : ProofCertificate
Γ ⊢ verify(cert) : Bool                      = run the kernel on cert.cic_term
─────────────────────────────                                       (Proof-Verify)
Γ ⊢ if verify(cert) then proven(cert.proposition) else error
```

The verifier is a *cycle* itself (`cycle proof_verify(cert: ProofCert) -> Bool @safety(PURE)`). Verification IS computation; computation IS proof-normalization.

### §11.4 What Each Type Construct Verifies Against

| Type construct | Proof obligation discharged by |
|---|---|
| `T @safety(H)` | `Γ ⊢ admitted(H) : Prop` (hexad reachability, kernel native rule §11.2) |
| `T @ring(R)` | `Γ ⊢ valid_phase_set(R) : Prop` (R ⊆ {R-2,R-1,R0,R3} and R ≠ ∅) |
| `T @tier(K)` | `Γ ⊢ valid_tier(K) : Prop` (K ∈ the 4 tiers) |
| `T @epoch(N)` | `Γ ⊢ valid_epoch(N) : Prop` (N ≤ current_epoch) |
| `Cap<P, R>` linearly | `Γ ⊢ uses(c) = 1 : Prop` (linearity check) |
| `glyph_bound(c)` | runtime check; type system inserts check-points |
| `CeilingMembership<S>` | `Γ ⊢ scba_bit_test(S) = 1 : Prop` |
| `MöbiusCoherence<Q>` | `Γ ⊢ coherence ≥ Q : Prop` |
| `Uncertainty(D, C, Q)` | `Γ ⊢ confidence(D) = C ∧ open_questions(D) = Q : Prop` |
| `trinity_admit(...)` | conjunction of four Props, discharged at the call site |

Every Prop-typed proposition has a kernel-checkable proof certificate. Programs that compile produce certificates. The certificates are emitted into the witness chain and propagate to federated peers.

### §11.5 Why CIC and Not HOL or LF or Plain Lambda Calculus?

- **HOL** (Higher-Order Logic, Isabelle/HOL) — lacks dependent types; cannot express `Cap<P, R>` directly.
- **LF** (Logical Framework, Twelf) — under-strength; cannot express the 144-byte reachability bitmap natively.
- **Plain lambda calculus** — even simply-typed lambda calculus has no inductive types; `Trit` and `Hexad` would require Church encodings (impractical proof terms).

CIC is the natural choice: dependent types for `Cap`/`Reduction`, inductive types for `Trit`/`Hexad`/`Phase`/`Tier`/`Epoch`, predicative universes to keep the kernel decidable. Forty years of meta-theoretic study (Coq, Lean, Agda) have validated the approach.

The III kernel is *narrower* than full Coq — it does not include coinductive types, universe polymorphism (we use a fixed seven-level ladder), or the irrelevance of some equality proofs. These omissions keep the kernel small (~3000 LoC) and auditable.

### §11.6 Proof Kernel Soundness

The kernel is sound iff: for every certificate `cert` such that `verify(cert) = true`, the proposition `cert.proposition` is true in the standard model of CIC + the native ternary extension.

Soundness is proved meta-theoretically by:

1. CIC's soundness (Werner 1994).
2. The conservativity of the native ternary extension over CIC (proved in `DOCS/PROOF-EXT-CONSERVATIVITY.md`, sealed alongside this spec).

A bug in the kernel implementation breaks soundness; the kernel is therefore the most security-critical 3000 lines of code in III. It is hand-audited, reviewed by the operator (per the guarantee that the operator can read every line), and its closure root is part of the substrate's specification root R1.

### §11.7 Self-Application

After Stage 4 self-host, the SELF compiler's proof kernel verifies its own source as a III program — meaning the kernel proves its own correctness against the spec, in its own logic. This is a fixed-point: the kernel that verifies the spec is itself proven correct against the spec. Soundness is thereby self-attesting (modulo the kernel-implementation bug, which is the only remaining trust assumption).

---

## §12. Type-Checking Algorithm

The type checker operates in three passes per module (§10.4):

### §12.1 Pass 1 — Declaration Shapes

Walk every item in the AST. For each:

- `cycle_decl` → record signature `(params, return_type, modifiers)`.
- `function_decl` → same plus generic parameters.
- `type_decl` → record alias.
- `mobius_candidate_decl` → record signature, mark eligible.
- `schema_decl` → record schema fields.
- `narrative_decl` → record (one per module).
- `const_decl` → record name and type (delay value-evaluation to Pass 3).
- `extern_decl` → record extern items.

The output is the **module symbol table**.

### §12.2 Pass 2 — Body Inference

Walk every body in synthesis mode. For each statement, apply the appropriate rule from §3, §4, §5, §6, §7, §8, §9, §10. Accumulate hole constraints; emit Prop obligations.

### §12.3 Pass 3 — Hole Solving + Proof Discharge

1. Solve hole constraints by unification.
2. Discharge Prop obligations:
   - `admitted(H)` → check kernel bitmap.
   - `valid_phase_set(R)` → check enum.
   - `linear use of c` → walk the use-graph.
   - `glyph_bound(c)` → insert runtime check-point.
   - `CeilingMembership(S)` → insert SCBA bit-test.
   - `MöbiusCoherence(Q)` → insert coherence check.
   - `trinity_admit(Op)` → insert four-conjunct Trinity check.
3. Emit proof certificates for every cycle.
4. Compute the module's closure root (mhash of canonical AST + canonical proof certificate set).

If any obligation cannot be discharged, the type checker emits a precise diagnostic and refuses to compile.

### §12.4 NIH Discipline (Restated)

The type checker is hand-rolled in `COMPILER/BOOT/sema.{h,c}` plus the kernel in `COMPILER/BOOT/proof.{h,c}`. No Hindley-Milner library. No Z3. No external SMT backend. No external CIC kernel (Coq/Lean/Agda are absent). The unification algorithm is a hand-rolled occurs-check + first-order unification.

The SELF type checker (`SELF/sema.III` + `SELF/proof.III`) re-implements the algorithm in III, and at Stage 4 promotes the SELF kernel into the Sanctum (`seal_id 9`, `compile_module`).

---

## §13. The Complete Judgment Set

The complete judgment set of III's type system, indexed for cross-reference:

| Judgment | Meaning | Source rule |
|---|---|---|
| `Γ ⊢ e : T` | Expression `e` has type `T` | structural |
| `Γ ⊢ Typeᵢ : Typeᵢ₊₁` | Universe-Intro | §2.1 |
| `Γ ⊢ Type₆ : Type₆` | Universe-Top | §2.1 |
| `Γ ⊢ P : Prop` ⇒ `Γ ⊢ P : Type₀` | Prop lift | §2.2 |
| `Γ ⊢ Π(x:A).B : Typemax(i,j)` (i,j<6) | Pi predicative | §2.4 |
| `Γ ⊢ Π(x:A).B : Type₆` | Pi impredicative-top | §2.4 |
| `Γ ⊢ Reduction(...) : Type₆` | Six-tuple effect | §3.2 |
| `Γ ⊢ r.X : ...` for X ∈ {forward, inverse, witness, hexad, phase, epoch} | Six elimination rules | §3.3 |
| `Γ ⊢ r₁ ⊕ r₂ : Reduction(...)` | Reduction compose | §3.4 |
| `Γ ⊢ r ⟲ : Reduction(...)` | Reduction inverse | §3.5 |
| `Γ ⊢ T @safety(H) : Typeᵢ` | Hexad-Tag | §4.1 |
| `Γ ⊢ (T₁ @safety(H₁)) ⧉ (T₂ @safety(H₂)) : ...` | Hexad-Compose | §4.2 |
| `Γ ⊢ T @ring(R) : Typeᵢ` | Ring-Dependent | §5.1 |
| `Γ ⊢ v ⟴ R₂ : T @ring(R₂)` | Phase-Cross | §5.2 |
| `Γ ⊢ T @tier(K) : Typeᵢ` | Tier-Dependent | §6.1 |
| `Γ ⊢ T @epoch(N) : Typeᵢ` | Epoch-Dependent | §6.2 |
| `Γ ⊢ a ⟵ b @epoch(N₂) : T @epoch(N₂)` | Epoch-Bridge | §6.2 |
| `Γ ⊢ Cap<P, R> : Type₄` | Cap-Form | §7.1 |
| `Γ, c:Cap<P,R> ⊢ use c : Unit` | Linear-Cap-Use | §7.2 |
| `Γ ⊢ glyph_bound.verify(c) : Prop` | Drift-Check | §7.3 |
| `Γ ⊢ Uncertainty(D, C, Q) : Type₀` | Epistemic-Intro | §8.1 |
| `Γ ⊢ r carries U` | Epistemic-Effect | §8.2 |
| `Γ ⊢ r₁ ⊕ r₂ carries combine_uncertainty(U₁, U₂)` | Epistemic-Compose | §8.2 |
| `Γ ⊢ U.confidence < 0.85q` ⇒ Trinity escalation | Epistemic-Escalation | §8.3 |
| `Γ ⊢ CeilingMembership(S) : Prop` | Constitutional | §9.1 |
| `Γ ⊢ MöbiusCoherence(Q) : Prop` | Möbius | §9.2 |
| `Γ ⊢ trinity_admit(Op) : Prop` (4-conjunct) | Trinity-Compose | §9.3 |
| `Γ ⊢ e ⇒ T` synthesis ↔ `Γ ⊢ e ⇐ T` checking | Bidirectional | §10.1 |
| `Γ ⊢ ? ⇒ α` (fresh metavariable) | Hole-N1 | §10.2 |
| `Γ ⊢ e : T ⇒ Γ ⊢ e : Typeᵢ where T : Typeᵢ` | Typed-as-Term-Lift U1 | §10.3 |
| `Γ ⊢ verify(cert) : Bool` | Proof-Verify | §11.3 |

Total: 30+ explicit judgments, organized into seven groups (universe, reduction, hexad, ring/phase, tier/epoch, capability, epistemic/proof). The full meta-theory is auditable in `DOCS/PROOF-EXT-CONSERVATIVITY.md` and the kernel source.

---

## §14. Why This Is the Most Valuable Type System Ever Designed

1. **Every other type system is a strict subset.** Hindley-Milner, System F, dependent types (CIC), linear types (Linear F), effect systems (Eff), capability systems — all encodable as restricted subsets of III's type system. The reverse encoding is impossible: no other type system has the witness manifold, the ring lattice, the asymmetric ternary safety ground, the Catalyst extension pathway, the constitutional ceiling, or the epistemic dimension.

2. **Security is a type-level guarantee, not a runtime hope.** The six bricking operations are *untypable*. Linear capabilities are glyph-bound and drift-detecting. Ring transitions are non-implicit. Cross-epoch combinations require explicit `@epoch_bridge`. There is no "trust me, this is safe" in III: every safety property is enforced by the type system or rejected at parse time.

3. **Reversibility is not a library — it is a type.** Every `Reduction` carries its inverse. Rollback is a type-directed operation: `r ⟲` produces the inverse reduction, which is itself a value of type `Reduction(I, F, ...)`.

4. **The system can reason about its own knowledge.** `Uncertainty<D, C, Q>` types let the language and the cognitive layer query and discharge their own epistemic state. The cognitive primitives (`reflect`, `negotiate`, `commit`) are typed: their preconditions are confidence thresholds, and the type checker enforces them.

5. **The type system evolves with the language.** Catalyst-promoted abstractions can introduce new types (in reserved AST kind slots, see III-GRAMMAR.bnf §11) that are immediately checked against the existing judgments. The judgment set is *frozen*; only new instances are admitted, not new rules.

6. **The proof.{h,c} kernel finally has something worthy to verify.** Every judgment in this document is a theorem the kernel can discharge. Every Prop-typed predicate is a proof obligation. Every cycle's inverse is a proof of reversibility. The kernel is hand-rolled (~3000 LoC), readable, NIH-extreme, and self-applying.

7. **The substrate's safety is mathematically proven, not asserted.** The Representability Theorem of III-HEXAD.md is *encoded as a typing rule* — it is enforced at every program compilation, and the proof certificate is part of the program's closure manifest.

---

## §15. Closure Identity Rule (R1.A3)

The R1.A3 hash is `SHA-256(canonical_byte_form(this_file))` per III-LEXICON.md §2.5.

R1.A3 is embedded in:

- Every compiled module's closure manifest (III-MODULES.md §1).
- The DRTM quote chain at every epoch advance.
- The OBSERVATORY's type-system-root-of-trust schema.
- Every proof certificate emitted by the kernel (the `closure_root` field of `ProofCertificate` in §11.3).

Mutation discipline: any change to this document alters R1.A3, which alters the composite R1, which forces a substrate-wide DRTM relaunch. Changes proceed only via Catalyst promotion (§16), `amend.apply` at constitutional tier, or a sealed major version bump.

---

## §16. Catalyst Extension Pathway

Reserved type-system slots:

- **Type-modifier slots** (alongside `MOD_RESERVED_001..008` from III-LEXICON.md §14.2).
- **Universe slots**: a new universe `Type₇` may be allocated by Catalyst promotion if architectural growth demands it; this is a heavy operation (it changes the cumulativity restriction and triggers a major version bump).
- **Type-constructor slots**: new type formers (e.g., `Codata<...>`, `Linear<...>`) may be allocated; restricted to ones expressible in CIC plus the native ternary extension.
- **Judgment slots**: new judgment forms may be added if and only if they are *conservative extensions* of the existing system (provable by the kernel's conservativity checker).

All Catalyst promotions in the type system require:

1. OBSERVATORY saturation showing the new type construct is mathematically beneficial.
2. A conservativity proof certificate (the kernel verifies that the new judgment does not break any existing one).
3. Trinity-Gate admission at constitutional tier.
4. Full codegen-validation per III-MODULES.md §2.
5. Federation broadcast.
6. DRTM relaunch.

---

## §17. Conformance Criteria (Restated)

C-TYPE-1 through C-TYPE-SELF (§1.2). Cross-reference C-3 in III-CONFORMANCE.md.

---

## §18. Final Declaration

This is not an incremental type system.
This is **the formal foundation of sovereign computation**.

Computation is witnessed.
Effects are reversible by construction.
Safety is a type, not an attribute.
Privilege is a dependent parameter, not an OS abstraction.
Uncertainty is first-class, not a runtime annotation.
The language reflects on and extends its own types at runtime.
The compiler is part of the trust chain.
Bricking is not an error — it is *untypable*.

No other type system in computing history has ever attempted this. No other type system ever will — because no other system has a Ring -2 sanctum, a Persistent Audit Spine, an OBSERVATORY of mathematical schemas, a Möbius Catalyst, an asymmetric ternary safety ground, a witness manifold, an epistemic dimension, and a cognitive layer integrated at the type level.

**III-TYPES.md — the type system that makes all others obsolete.**
**The proof layer is integrated, not bolted on.**
**Sealed against the C:\\CHARIOT closure of 2026-05-03. R1.A3 = SHA-256(canonical_byte_form(this_file)).**

*All conformance criteria are restated in III-CONFORMANCE.md §3. All Catalyst extensions pass through the pathway in §16.*
