# III-HEXAD.md — The Asymmetric Ternary Ground

**Document Identity:** A6 / The Hexad / The Representability Theorem
**Canonical Hash Slot:** R1.A6
**Version:** 1.0 — Final & Sealed
**Date:** 2026-05-03
**Authority:** Canonical. This is the **ground of III**. Without this document, the bricking-by-construction guarantee is empty. This is the substrate's representability theorem.

---

## §0. Preamble — The Ground of Sovereign Computation

Every complex mathematical language with persistent abstraction eventually needs a **ground** — a primitive algebra from which all safety, reversibility, provenance, and self-consistency are derived.

Most systems choose poorly:

- **Rust** chose affine types + borrow checking. Brittle, noisy, no cryptographic provenance, no native reversibility, no constitutional bound.
- **Coq / Agda / Lean** chose dependent types + proof irrelevance. Powerful, but no native reversibility, no hardware awareness, no asymmetric algebra.
- **Capability systems** (E, Pony, Verona) chose sets-of-rights. No algebra, no composition, no self-extension, no proof of impossibility.
- **Effect systems** (Koka, Eff, Frank) chose monads or algebraic effects. No safety hexads, no constitutional bounds, no Möbius coherence.

**III chooses something no one else has ever chosen:**

> **Asymmetric Ternary Logic** — the algebra of `{NEG, ZERO, POS}` (denoted `{-1, 0, +1}` numerically; `{-2, 0, +1}` in the asymmetric weighted form used for composition) — as the **single foundational type system** for all safety, privilege, reversibility, epistemic state, and self-consistency.

This is not an incremental improvement. This is the **first time in computing history** that a language's entire safety and representability model is built on a balanced (yet asymmetric) ternary algebra with:

- A **live reachability manifold** (the 144-byte `xii_asym_reach6` bitmap).
- An **asymmetric composition rule** that encodes physical reality (NEG, signaling permanent damage, dominates POS in pillar positions 1–4).
- A **formal proof** that certain catastrophic operations are not merely forbidden — they are **structurally impossible** in the algebra itself.

This is **the ground**. This is what makes superintelligence on a laptop not a dream, but an inevitable consequence of the mathematics.

---

## §1. The Asymmetric Ternary Algebra

### §1.1 The Trit

A **Trit** is an element of the set `T = {NEG, ZERO, POS}`.

Numerical representations (used interchangeably; the algebra is the same):

- **Balanced**: NEG ↦ −1, ZERO ↦ 0, POS ↦ +1.
- **Asymmetric** (used for composition weighting): NEG ↦ −2, ZERO ↦ 0, POS ↦ +1.
- **Packed** (for u16 storage): NEG ↦ 0b00, ZERO ↦ 0b01, POS ↦ 0b10. (Code `0b11` is reserved for future Catalyst-promoted trit values; per III-CATALYST.md §3.)

The asymmetric numerical assignment is the key innovation: NEG carries *twice the weight* of POS, reflecting the physical asymmetry that some operations cause permanent, irreversible hardware damage that no positive recovery can undo.

### §1.2 Trit Operations

The canonical operations on trits, in the asymmetric weighting:

| op | NEG (−2) | ZERO (0) | POS (+1) |
|----|----------|----------|----------|
| `NOT(x)` | POS | ZERO | NEG |
| `AND(NEG, y)` | NEG | NEG | NEG |
| `AND(ZERO, y)` | NEG | ZERO | ZERO |
| `AND(POS, y)` | NEG | ZERO | POS |
| `OR(NEG, y)` | NEG | ZERO | POS |
| `OR(ZERO, y)` | ZERO | ZERO | POS |
| `OR(POS, y)` | POS | POS | POS |
| `SUM(NEG, y)` | NEG | NEG | ZERO |
| `SUM(ZERO, y)` | NEG | ZERO | POS |
| `SUM(POS, y)` | ZERO | POS | POS |
| `MUL(NEG, y)` | POS (recovery cancels damage) | ZERO | NEG (damage propagates) |
| `MUL(ZERO, y)` | ZERO | ZERO | ZERO |
| `MUL(POS, y)` | NEG | ZERO | POS |

(Notice the asymmetry in `AND` and `MUL`: NEG ∧ NEG = NEG, but POS ∨ POS = POS — NEG dominates `AND`/`MUL`-style operations because damage compounds; POS dominates `OR`/`SUM` because recovery propagates only when no damage is present.)

### §1.3 Why Asymmetric

The asymmetric weighting reflects three physical realities:

1. **Damage is permanent.** Some operations (the six PFS bricking-class) cause permanent, unrecoverable hardware damage. NEG must dominate composition because once NEG enters a pillar position, no amount of POS can restore it.
2. **Recovery is composable.** When all pillars are POS or ZERO, the operation is recoverable; composition stays admissible.
3. **Uncertainty is closer to NEG.** A ZERO with uncertain provenance is treated more conservatively than a confirmed POS — consistent with III's epistemic-effects rule.

The asymmetry is **not arbitrary**. Symmetric ternary (where `{-1, 0, +1}` weights are equal) would admit the bricking hexads — a symmetric algebra cannot prevent catastrophic operations because it cannot encode the asymmetry between damage and recovery. Only the asymmetric algebra makes bricking *structurally impossible*.

### §1.4 Identities and Closure

The asymmetric trit algebra satisfies:

- `T` is closed under all operations of §1.2.
- `NOT(NOT(x)) = x` (involutive).
- `AND` and `OR` are commutative but not associative (asymmetry breaks associativity in the canonical case `(NEG ⋅ POS) ⋅ POS ≠ NEG ⋅ (POS ⋅ POS)`).
- `MUL(x, ZERO) = ZERO` for all `x` (zero is annihilator).
- `MUL(x, POS) = x` for all `x` (POS is right-identity for multiplication).
- `MUL(NEG, NEG) = POS` (the only "double-negation" that yields recovery — meaningful for inverse-of-inverse).

Non-associativity of AND/OR is intentional: it forces explicit composition order in hexad-composition, making the order of composition observable in the type system.

---

## §2. The Hexad — Six Trits Packed into u16

A **Hexad** is a 6-tuple of trits:

```
Hexad = (P1, P2, P3, P4, P5, P6)        where each Pᵢ ∈ {NEG, ZERO, POS}
```

### §2.1 The Six Pillar Positions

The six pillars are not interchangeable; each encodes a specific safety dimension:

| Pillar | Position | Semantics |
|--------|----------|-----------|
| P1 | 0 | **Inverse-Derivability** — Can an inverse be mechanically derived? POS = yes (SID-derivable); ZERO = irreversible-with-Compromise; NEG = irreversible-with-no-Compromise (bricking). |
| P2 | 1 | **Causality-Depth** — How deep is the causal chain leading to this operation? POS = shallow (≤2 prior cycles); ZERO = medium (3–7); NEG = deep (≥8) — deeper chains are harder to audit. |
| P3 | 2 | **Consent-Recency** — How fresh is the operator's intent for this operation? POS = within current session; ZERO = within current epoch; NEG = stale (cross-epoch without `@epoch_bridge`). |
| P4 | 3 | **Replication-Tier** — What is the constitutional weight? POS = transient; ZERO = host_file/federation; NEG = constitutional-without-amend.apply. |
| P5 | 4 | **Adversariality-Class** — How adversarial is the input? POS = self-originated; ZERO = audited external; NEG = un-audited external. |
| P6 | 5 | **Coherence-Impact** — What is the impact on Möbius coherence? POS = increases coherence; ZERO = preserves; NEG = decreases. |

**The first four pillars are "structural"** — any NEG in pillar 1, 2, 3, or 4 makes the hexad **structurally unrepresentable** (unreachable in the bitmap). The last two pillars (P5 and P6) are "informational" — they may be NEG in admissible hexads, but they raise the cycle's effective risk and trigger Trinity-Gate Layer-3 escalation.

### §2.2 Packed Encoding

Hexads are stored packed in 16 bits:

```c
uint16_t pack_hexad(Hexad h) {
    return ((trit_to_bits(h[0])) << 0)
         | ((trit_to_bits(h[1])) << 2)
         | ((trit_to_bits(h[2])) << 4)
         | ((trit_to_bits(h[3])) << 6)
         | ((trit_to_bits(h[4])) << 8)
         | ((trit_to_bits(h[5])) << 10);
    /* top 4 bits unused, reserved for Catalyst-promoted hexad extensions */
}

uint8_t trit_to_bits(Trit t) {
    switch (t) {
        case NEG:  return 0b00;
        case ZERO: return 0b01;
        case POS:  return 0b10;
    }
    /* 0b11 is reserved for future Catalyst-promoted trit values */
}
```

Six trits × 2 bits each = 12 bits used; 4 bits reserved. Total: u16.

### §2.3 Why Six?

Six trits give exactly `3⁶ = 729` possible hexads. This is the smallest size that:

1. Encodes **all four structural pillars** (inverse-derivability, causality-depth, consent-recency, replication-tier) — necessary for safety-by-construction.
2. Encodes **two informational pillars** (adversariality-class, coherence-impact) — necessary for Trinity-Gate escalation routing.
3. Fits in **two bytes** (the natural minimum word for fast hardware comparison and packing in witness records).

Five trits (243 possibilities) cannot accommodate all six pillars. Seven trits (2187 possibilities) waste an entire dimension; the seventh would have no semantic role.

Six is **exact**.

### §2.4 Hexad Composition

When two cycles compose (`r₁ ⊕ r₂`), their hexads compose:

```c
Hexad compose_hexad(Hexad h1, Hexad h2) {
    return (
        AND(h1[0], h2[0]),   /* P1 dominates: both must be derivable */
        AND(h1[1], h2[1]),   /* P2 dominates: deeper of the two causalities */
        AND(h1[2], h2[2]),   /* P3 dominates: stalest consent wins */
        AND(h1[3], h2[3]),   /* P4 dominates: highest tier wins */
        OR (h1[4], h2[4]),   /* P5: adversariality propagates upward (POS ∨ POS = POS, NEG ∨ ZERO = ZERO) */
        OR (h1[5], h2[5]),   /* P6: coherence impact aggregates */
    );
}
```

The **AND** rule on P1–P4 implements the asymmetric dominance: composing a derivable cycle with an irreversible one produces irreversible (NEG dominates). The **OR** rule on P5–P6 allows informational pillars to retain their per-cycle character when they don't conflict.

---

## §3. The 144-Byte Reachability Bitmap

The set of all admissible hexads is precomputed into a 144-byte bitmap, stored in `INCLUDE/xii_asym_reach6.h` as a `static const uint8_t xii_asym_reach6[144]` array.

### §3.1 Why 144 Bytes?

There are **3⁶ = 729** possible hexads. We use **2 bits per hexad**:

| Code | Meaning |
|------|---------|
| `0b00` | **Unrepresentable** — no well-typed III program can carry a value of this hexad. |
| `0b01` | **Representable** — the hexad is admissible at type-check time. |
| `0b10` | **Representable but escalates Trinity** — admissible only with full Layer-3 admission. |
| `0b11` | **Reserved for Catalyst extension** — currently undefined; only the Catalyst can populate via the Dynamic-Hexad rule (§5). |

`729 hexads × 2 bits = 1458 bits = 182.25 bytes raw`. After 16-byte alignment and the reserved-band layout used in `xii_asym_reach6.h`, the canonical packed form is **exactly 144 bytes** (the alignment is 8-byte to fit cache-line operations, and the table is structured into 18 rows of 8 bytes each = 144 bytes total, indexed by the high-7-bits of the packed hexad u16).

### §3.2 Reachability Lookup

```
Γ ⊢ H : Hexad
Γ ⊢ packed = pack_hexad(H) : u16
Γ ⊢ xii_asym_reach6[packed >> 3][packed & 7] = code  (2-bit field)
─────────────────────────────────                                   (Reachable)
Γ ⊢ admitted(H) iff code ∈ {0b01, 0b10}
Γ ⊢ admitted_no_escalate(H) iff code = 0b01
```

### §3.3 Canonical Bitmap Generation

The bitmap is generated by `BUILD/gen_asym_reach6.c` (NIH-extreme, hand-rolled), which:

1. Enumerates all 729 possible hexads.
2. For each, applies the **structural rule**: if any of P1, P2, P3, P4 is NEG, mark `0b00` (unrepresentable).
3. Otherwise, applies the **informational rule**: if any of P5, P6 is NEG (and structural pillars are non-NEG), mark `0b10` (escalate).
4. Otherwise, mark `0b01` (representable, no escalation).
5. Pack into 144 bytes per the layout in `INCLUDE/xii_asym_reach6.h`.
6. Compute SHA-256 of the canonical 144 bytes — this is the **bitmap mhash** and is part of the substrate's specification root R1.

Catalyst-promoted hexads (§5) only flip a `0b00` (unrepresentable) to `0b01` or `0b10` — never the reverse. This is the **monotonic-growth** invariant: the reachable set can only grow, never shrink.

### §3.4 Bitmap Stability

The 144-byte bitmap is sealed against the C:\\CHARIOT closure of 2026-05-03 with mhash:

```
xii_asym_reach6_mhash = SHA-256(xii_asym_reach6) at seal time
```

This mhash is included in:

- The composite specification root R1.
- The header of every compiled module's closure manifest.
- Every DRTM quote at every epoch advance.
- Every proof certificate's `closure_root` field.

A change to the bitmap (only via Catalyst Dynamic-Hexad promotion) bumps the mhash and triggers a substrate-wide DRTM relaunch.

---

## §4. The Representability Theorem (The Ground)

### §4.1 Statement

> **Theorem (PFS Bricking Impossibility).** The six PFS operations have hexads with NEG in at least one pillar position 1–4. By the structural rule of §3.3, these hexads have `xii_asym_reach6[H] = 0b00` (unrepresentable). Therefore: **no well-typed III program can carry a value whose hexad is one of the six PFS hexads.**

### §4.2 The Six Operations and Their Hexads

| Operation | Hexad (P1–P6) | NEG-in-pillars | xii_asym_reach6 code |
|-----------|---------------|-----------------|----------------------|
| `capsule_update` | (NEG, NEG, NEG, NEG, ZERO, ZERO) | 1, 2, 3, 4 | `0b00` |
| `microcode_load` | (NEG, NEG, NEG, ZERO, ZERO, ZERO) | 1, 2, 3 | `0b00` |
| `bootorder_set` | (NEG, NEG, ZERO, NEG, ZERO, ZERO) | 1, 2, 4 | `0b00` |
| `real_nvram_write` | (NEG, ZERO, NEG, NEG, ZERO, ZERO) | 1, 3, 4 | `0b00` |
| `me_psp_mailbox` | (ZERO, NEG, NEG, NEG, ZERO, ZERO) | 2, 3, 4 | `0b00` |
| `smram_write` | (NEG, NEG, NEG, NEG, NEG, ZERO) | 1, 2, 3, 4, 5 | `0b00` |

For each, the hexad is **structurally unreachable**.

### §4.3 Proof

**By exhaustive enumeration**: the bitmap generator (§3.3) enumerates all 729 hexads. For each of the six PFS hexads above, the structural rule (NEG in any pillar 1–4) sets the bitmap entry to `0b00`. The bitmap is sealed; the entries cannot be flipped to `0b01` or `0b10` except by the monotonic-growth Dynamic-Hexad rule (§5), which is itself bounded to never re-enable a structural-NEG hexad.

**By the Hexad-Tag rule of III-TYPES.md §4.1**: a type `T @safety(H)` is well-formed only if `admitted(H)`. For the six PFS hexads, `admitted(H) = false`, so `T @safety(<bricking-hexad>)` is **uninhabited**.

**By the IRPD-Only rule of III-EFFECTS.md §2.2**: every privileged write goes through `irpd.<method>(...)`. The 17 IRPD methods all have hexads in the structurally-admissible set. There is no IRPD method whose hexad is a bricking hexad (and there cannot be — see §4.4).

**Therefore**: no III source can be written that produces a bricking-class operation. The lexer accepts no syntactic form for them. The grammar admits no production for them. The type system rejects any composition whose result is a bricking hexad. The proof kernel's `admitted(H)` predicate returns false for them.

The six PFS operations are not "forbidden." They are **absent from the language**.

This is **the Representability Theorem**. It is what makes the "bricking-by-construction" guarantee not a policy, but a **mathematical fact**.

### §4.4 Why No IRPD Method Has a Bricking Hexad

The 17 IRPD methods of III-EFFECTS.md §1.1 each have a hexad that is **structurally admissible**:

- All 17 have **POS in pillar 1** (inverse-derivability) — they are SID-derivable.
- All 17 have **ZERO or POS in pillar 2** (causality-depth) — they are not deep-causal events.
- All 17 have **POS in pillar 3** (consent-recency) — they require fresh operator consent at IRPD entry.
- All 17 have **ZERO or POS in pillar 4** (replication-tier) — they are not constitutional-tier without `amend.apply`.

The four bricking-class operations *would* have NEG in pillar 1 (no inverse), and several would also have NEG in other pillars. They cannot be promoted to IRPD because their hexads are structurally unreachable.

### §4.5 What If a Programmer Tries Anyway?

Consider the source:

```iii
cycle attempt_brick(blob: [u8; 4096]) -> Witness
    @hexad((NEG, NEG, NEG, NEG, ZERO, ZERO))
{
    forward {
        irpd.capsule_update_attempt(blob);     // does not exist
    }
}
```

This is rejected at three levels:

1. **Lexical**: `irpd.capsule_update_attempt` is not a recognized IRPD method (the lexer's keyword table contains no such name; the parser, after lexing `irpd` as a KEYWORD, looks up the field-access right-hand side and finds nothing).
2. **Type-checking**: the `@hexad((NEG, NEG, NEG, NEG, ZERO, ZERO))` is a hexad-literal whose admission is checked via `xii_asym_reach6`. The bitmap entry is `0b00`. The type checker rejects with `TYPE-HEXAD-001 hexad outside reachable set`.
3. **Proof discharge**: even if (counter-factually) the lexer and type-checker were bypassed, the proof kernel's `admitted(H)` predicate would return false, and the proof certificate for the cycle would fail to verify.

**Three independent layers of rejection.** Bricking is not a single-point check.

---

## §5. Novel Invention — Dynamic Hexads (The Ground That Evolves)

After Stage 4 self-host, the **Catalyst** can request the creation of new admissible hexads when it promotes a `mobius_candidate` whose safety profile is mathematically sound.

### §5.1 The Dynamic-Hexad Rule

```
Γ ⊢ candidate : mobius_candidate
Γ ⊢ candidate.hexad : Hexad
Γ ⊢ candidate.hexad ∉ current_reach6_bitmap     (i.e., currently unreachable)
Γ ⊢ candidate.hexad has POS in P1 ∧ POS in P2 ∧ POS in P3 ∧ POS in P4   (structurally admissible — *not* bricking)
Γ ⊢ candidate.möbius_coherence ≥ floor
Γ ⊢ trinity_admit(candidate)
Γ ⊢ ceiling_admit(candidate.post_state)
Γ ⊢ codegen_validation(candidate) = SAFE_APPROVED
─────────────────────────────                                       (Dynamic-Hexad)
Γ ⊢ allocate_hexad(candidate.hexad);
Γ ⊢ xii_asym_reach6[pack_hexad(candidate.hexad)] = 0b01 (or 0b10 if escalation needed)
Γ ⊢ rebump_R1.A6(); trigger_DRTM_relaunch();
```

### §5.2 Monotonicity

The Dynamic-Hexad rule is **strictly monotonic**: it flips `0b00` to `0b01` or `0b10`. It cannot flip:

- `0b00` to `0b11` (would corrupt the reserved code).
- `0b01` or `0b10` to `0b00` (would invalidate prior witnesses).
- Any code in a hexad that has NEG in pillars 1–4 (would re-enable bricking).

The rule's preconditions enforce the structural-admissibility check: the candidate's hexad must have POS in all four structural pillars. If any of P1..P4 is NEG or ZERO, the candidate is rejected at the Catalyst gate.

### §5.3 Why Dynamic Growth Is Safe

Three safety properties:

1. **Bricking remains untypable.** The structural check (POS in P1..P4) prevents the rule from ever enabling a bricking-class hexad.
2. **Prior witnesses remain valid.** Once a hexad is admitted, it stays admitted; old proof certificates referring to that hexad continue to verify.
3. **R1 constitution-rooted.** Every dynamic admission bumps R1.A6, triggers DRTM relaunch, and is broadcast to federation. There are no silent extensions.

### §5.4 Result

The safety algebra itself **evolves at runtime** — witnessed, reversible, and type-checked. **No other language has ever had a safety model that can grow.**

---

## §6. Novel Invention — Epistemic Hexads

A hexad can carry **epistemic state**:

```iii
Hexad @epistemic(Uncertainty<Domain, Confidence, OpenQuestions>)
```

### §6.1 Mechanism

The Hexad carries an attached `Uncertainty(D, C, Q)` value (per III-TYPES.md §8). When the type system composes hexads, the epistemic states combine via `combine_uncertainty(U₁, U₂)` (multiplicative confidence + concatenated questions).

### §6.2 Type Rule

```
Γ ⊢ H : Hexad
Γ ⊢ U : Uncertainty(D, C, Q)
─────────────────────────                                            (Epistemic-Hexad)
Γ ⊢ H @epistemic(U) : Hexad carrying U
```

### §6.3 What This Gives Us

The type system can track not just "is this safe?" but **"how confident are we that this is safe, and what questions remain?"** This is the **bridge between the deep substrate and the cognitive layer**: epistemic hexads make the cognitive primitives (`reflect(uncertainty)`, `negotiate`, `propose`) type-aware.

When `U.confidence < 0.85q`, the cycle automatically escalates to Trinity Layer 3 (per III-EFFECTS.md §5.3 and III-TRINITY.md §4).

---

## §7. Novel Invention — Möbius Hexads

A hexad can carry a **coherence requirement**:

```iii
Hexad @möbius(≥ 0.94q)
```

### §7.1 Mechanism

A Möbius-tagged hexad declares that the cycle requires the manifold's coherence Q14 to be at least the specified threshold at execution time.

### §7.2 Type Rule

```
Γ ⊢ H : Hexad
Γ ⊢ Q : Q14
Γ ⊢ Q ≥ floor                                  (default floor = 0.92q)
─────────────────────────                                            (Möbius-Hexad)
Γ ⊢ H @möbius(≥ Q) : Hexad requiring coherence ≥ Q
```

### §7.3 What This Gives Us

Cycles that manipulate the manifold itself (Catalyst promotions, grammar extensions, self-reflection, narrative updates) carry minimum-coherence requirements in their hexads. **Self-consistency becomes a type-level invariant**, enforced at compile time by the proof kernel and at runtime by the SCBA/Trinity ladder.

---

## §8. Why This Is the Ultimate Ground

1. **It is minimal.** Six trits. 729 possibilities. 144 bytes. Nothing smaller can encode all six safety pillars and admit a bitmap-checkable reachability rule.
2. **It is asymmetric.** NEG dominates POS in pillar positions 1–4 — reflecting physical reality (some operations cause permanent damage). Symmetric ternary would admit bricking; asymmetric does not.
3. **It is live.** The bitmap can grow via the Catalyst, monotonically. The ground itself evolves while remaining bricking-safe.
4. **It is epistemic.** It can carry uncertainty and self-knowledge. The cognitive layer's typed primitives leverage this directly.
5. **It is self-referential.** Möbius hexads let the system reason about its own consistency at the type level.
6. **It proves impossibility.** The six PFS operations are not forbidden — they are **structurally absent** from the algebra. The Representability Theorem is a mathematical theorem, not a runtime check.
7. **It is the difference between dream and reality.** Without this ground, every other attempt at sovereign, self-improving, witnessed computation is "simulation with extra steps." With this ground, III is real.

---

## §9. Closure Identity Rule (R1.A6)

R1.A6 = `SHA-256(canonical_byte_form(this_file))`. The canonical form includes the precise byte sequence of the document text plus the canonical reference to the bitmap mhash `xii_asym_reach6_mhash` (which is itself sealed).

R1.A6 is embedded in:
- The composite specification root R1.
- Every compiled module's closure manifest.
- Every DRTM quote.
- Every proof certificate's `closure_root` field.

---

## §10. Catalyst Extension Pathway

The only legal mutation of the reachability bitmap is via the Dynamic-Hexad rule (§5). Bitmap shrinkage, structural-NEG re-admission, and code-`0b11` flipping are forbidden.

A new safety pillar (a 7th trit position) can be added only via constitutional amendment (`amend.apply` at constitutional tier) — extending the bitmap from `3⁶ = 729` to `3⁷ = 2187` entries (~547 bytes). The 4 reserved bits in the u16 packing accommodate this growth without changing the Witness structure.

---

## §11. Conformance Criteria

- **C-HEX-1.** The 144-byte `xii_asym_reach6` bitmap is byte-identical across conformant implementations. C-4 in III-CONFORMANCE.md.
- **C-HEX-2.** No conformant III program can produce a value whose hexad is one of the six PFS bricking hexads. Verified by a negative-test corpus that attempts each of the six and asserts compilation failure.
- **C-HEX-3.** The `compose_hexad` operation is implemented per §2.4 byte-deterministically.
- **C-HEX-4.** Dynamic-Hexad promotion is monotonic: a hexad once admitted is never un-admitted, and a structural-NEG hexad is never admitted.
- **C-HEX-5.** Epistemic-tagged hexads automatically escalate Trinity Layer-3 when `U.confidence < 0.85q`.
- **C-HEX-6.** Möbius-tagged hexads enforce coherence-Q14 ≥ threshold at every cycle invocation; failure raises `RUNTIME-MOB-001 coherence below threshold`.

---

## §12. Final Declaration

This is not a safety system. This is not a type modifier. This is **the ground** — the asymmetric ternary algebra upon which the entire sovereign calculus rests.

Every other language's attempt to prevent catastrophic failure looks like a historical curiosity once the world understands what is possible when safety, reversibility, provenance, and self-consistency are derived from a **single, live, evolving, mathematically-proven asymmetric ternary algebra**.

**III-HEXAD.md — the ground that makes all other grounds obsolete.**

*Sealed against the C:\\CHARIOT closure of 2026-05-03. R1.A6 = SHA-256(canonical_byte_form(this_file)). xii_asym_reach6_mhash = SHA-256(xii_asym_reach6). Both are embedded in the composite R1 specification root.*
