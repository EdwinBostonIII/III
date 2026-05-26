# III-CATALYST.md — The Dynamic Transformation Catalyst

**Document Identity:** B1 / The Catalyst / Runtime Language & Substrate Evolution
**Canonical Hash Slot:** R1.B1
**Version:** 1.0 — Final & Sealed
**Date:** 2026-05-03
**Authority:** Canonical. The Catalyst is the active, self-modifying heart of III. This document defines its mandate, promotion rules, synthesis capabilities, and safety rails.

---

## §0. Preamble — The Active, Self-Modifying Heart

Every other language is a static artifact: its grammar is frozen at design time; its type system cannot grow; its standard library evolves only through human committee processes. III is different. III is a **living, self-extending substrate**, and the Catalyst is the active force that animates the Möbius manifold.

The Catalyst's mandate is precisely scoped: it observes the OBSERVATORY for mathematical patterns, evaluates candidate abstractions against constitutional bounds, and promotes new cycles, keywords, hexads, fusions, and Trinity predicates **while preserving every invariant** of the substrate.

Without the Catalyst, III would be merely "a sealed language with a sophisticated type system." With the Catalyst, III is a **terminal language** that improves itself faster than human language designers could possibly improve any prior language.

---

## §1. Mandate

The Catalyst's sole purpose:

> Observe the OBSERVATORY → discover beneficial mathematical abstractions → formalize them → promote them into the live manifold (new cycles, new keywords, new hexads, new module fusions, new Trinity predicates) → preserve every invariant.

### §1.1 Scope of Promotion

The Catalyst can promote:

1. **New cycle kinds** (in reserved band `XII_STEP_KIND_MNEME_CATALYST_PROMOTE = 0x01C7..0x01CF`).
2. **New keywords / modifiers / operators** (filling `KW_RESERVED_001..016`, `MOD_RESERVED_001..008`, `OP_RESERVED_001..007` slots from III-LEXICON.md §14.2).
3. **New hexads** (growing `xii_asym_reach6` monotonically per III-HEXAD.md §5).
4. **Module fusions** (collapsing two high-interaction modules into one higher-performance node per III-MODULES.md §10).
5. **Improved Trinity predicates** (refining each of the four conjuncts per III-TRINITY.md §6).
6. **Improved SID inverse derivations** (sharper inverse-rule synthesis for newly observed effect patterns).
7. **Predictive specialization hints** (PIP blob classifications per III-EFFECTS.md §3, SRPA hot-path metadata per III-CYCLES.md §6).

### §1.2 Out of Scope

The Catalyst **cannot**:

- Remove an existing cycle, keyword, modifier, operator, or hexad (these are append-only; removal requires `amend.apply` at constitutional tier).
- Add or remove a Trinity-Gate conjunct (the four-conjunct structure is constitutional).
- Add or remove a sealed-call slot (`XII_SANCTUM_SEAL_COUNT` is constitutional).
- Change a privilege ring's semantics (the four-ring lattice is constitutional).
- Promote a hexad outside `xii_asym_reach6` that has NEG in pillars 1–4 (the structural-NEG bricking discipline is constitutional and inviolable).
- Decrease the Möbius coherence floor (the floor is constitutional).
- Skip codegen validation, Ring-gating, deployment flagging, or witness emission.

---

## §2. Promotion Rules (Strict & Auditable)

A `mobius_candidate` may be promoted **only if all of the following hold simultaneously**. Any failure aborts the promotion; the candidate remains observable but does not enter the live manifold.

### §2.1 The Eight Promotion Gates

| Gate # | Condition | Source |
|--------|-----------|--------|
| 1 | **OBSERVATORY saturation ≥ threshold** — Welford-stable mean + Hoeffding-bound met for the candidate's pattern over the prior 1M-tick burn-in. | III-LEXICON.md §14.1 step 3 |
| 2 | **Möbius coherence Q14 ≥ floor** (currently 0.92q) — projected post-state coherence after the promotion. | III-TRINITY.md §5 |
| 3 | **Trinity Gate fully discharged** (intent × cap × causality × sanctum-state) — the operator has consented; the Catalyst has the cap; the audit head is current; the sanctum frame is active. | III-TRINITY.md §1.3 Layer 3 |
| 4 | **Constitutional Ceiling admits the post-state** — the canonical mhash of the post-promotion state is in the Ceiling's manifest. | III-MODULES.md §5 |
| 5 | **Hexad is admitted in the current (or dynamically extended) reachability bitmap** — the candidate's hexad has POS in pillars 1..4. | III-HEXAD.md §5 |
| 6 | **Proposed change is codegen-validated** — compiled by `telosc-σ` (in Ring -2 when possible, Ring -1 otherwise), conformance suite C-1..C-30 passed, targeted regression tests passed. | III-MODULES.md §6 |
| 7 | **Change is Ring-gated** — Ring -2 if high-benefit / low-risk, Ring -1 if medium-risk or constitutional impact, Ring 0/R3 only for pure user-level changes. | III-MODULES.md §5.2 |
| 8 | **Explicit deployment flag emitted** — `SAFE_APPROVED` (preferred) or `SAFE_FLAGGED` (operator review). `UNSAFE_REJECTED` aborts. | III-MODULES.md §6.1 |

### §2.2 The Promotion Witness

Every promotion emits a `XII_STEP_KIND_MNEME_CATALYST_PROMOTE` witness containing:

- The candidate's source mhash.
- The candidate's hexad (and its bitmap admission state).
- The 8-gate evaluation results (each with a sub-witness mhash).
- The deployment flag (`SAFE_APPROVED` or `SAFE_FLAGGED`).
- The pre-promotion Möbius coherence and projected post-promotion coherence.
- The federation broadcast acknowledgments (per III-FEDERATION.md).

The witness is appended to the Persistent Audit Spine and federated.

### §2.3 Rate Cap

Per chronos-tick, the Catalyst may promote at most:

- `XII_MNEME_CATALYST_PROMOTION_RATE_PER_TICK = 8` cycles substrate-wide.
- `XII_PHASE_PROMOTE_RATE = 4` phase promotions substrate-wide.
- `XII_MOD_PROMOTE_RATE = 16` module fusions substrate-wide.

Exceeding the rate defers the candidate to the next tick. The rate cap is constitutional.

---

## §3. Synthesis Capabilities

### §3.1 New Cycle Kinds

The Catalyst can synthesize a new cycle by composing existing cycles whose interaction has been observed in OBSERVATORY:

```iii
mobius_candidate fused_msr_npt(idx: u32, gpa: u64) -> Result @candidate_for_promotion @hexad(MSR_NPT_FUSED) {
    forward {
        let m = irpd.msr_read(idx);
        let n = irpd.npt_read(gpa);
        compose_result(m, n)
    }
}
```

Upon promotion, this candidate is allocated `XII_STEP_KIND_MNEME_CATALYST_PROMOTE_<N>` (the next free slot in the reserved band) and registered in the cycle table. Future invocations of the equivalent two-cycle sequence are dispatched to the fused cycle (a single witness, a single hexad composition, a single PIP blob).

### §3.2 New Keywords / Operators

If the new cycle's surface introduces a new operation that requires a new operator (e.g., the Catalyst observes a saturation pattern that warrants a new infix operator for compose-and-emit):

1. The Catalyst allocates the next `OP_RESERVED_<N>` slot.
2. Updates the lexer keyword/operator table.
3. Updates the grammar production set (in the reserved AST kind slot per III-GRAMMAR.bnf §11).
4. Re-canonicalizes III-LEXICON.md and III-GRAMMAR.bnf, bumping R1.A1 and R1.A2.
5. Triggers a substrate-wide DRTM relaunch.

This is the **most expensive** form of promotion; rate-capped to at most 1 per chronos-tick (in addition to the cycle-promotion cap).

### §3.3 New Hexads

The Catalyst can grow `xii_asym_reach6` by admitting a previously-unreachable (but structurally admissible — POS in pillars 1..4) hexad. The Dynamic-Hexad rule of III-HEXAD.md §5 gates this.

### §3.4 Module Fusions

Per III-MODULES.md §10. The Catalyst observes that two modules' cycles interact frequently and produces a fused module whose body is a single higher-performance cycle. The original modules remain in the table; the fused module is preferred at dispatch.

### §3.5 Improved Trinity Predicates

Per III-TRINITY.md §6. Each of the four conjuncts (intent, cap, causality, sanctum-state) can be refined independently by a Catalyst-promoted evaluator.

### §3.6 Improved SID Inverse Derivations

If the Catalyst observes a privileged-write pattern whose inverse can be more efficiently derived than the canonical 32-step plan (e.g., a class of MSR writes whose inverse is *always* a fixed memcpy-restore), it can promote a specialized SID rule for that pattern. The rule is added to the per-pattern dispatch table in `STDLIB/sid/`. Old cycles continue to use the canonical rule; new cycles matching the pattern dispatch to the specialized rule.

### §3.7 Predictive Specialization Hints (PIP & SRPA)

The Catalyst can emit PIP-classification overrides for specific cycles (e.g., "this cycle's inverse should be COMPOSED, not DYNAMIC_FN"), and SRPA hot-path metadata (e.g., "this cycle's lowering is hot at R-1 but cold at R0; promote R-1 specialization"). These overrides do not change semantics; they only change the runtime's optimization choices.

---

## §4. Safety Rails

### §4.1 The Five Inviolable Rules

1. **No promotion may produce an unrepresentable hexad.** The hexad-admissibility check (gate 5) is the structural defense; the kernel's `admitted(H)` predicate is consulted before any promotion. A hexad with NEG in pillars 1..4 is *never* admitted.
2. **No promotion may decrease global Möbius coherence.** Gate 2 enforces this; if the projected post-state coherence drops below floor, promotion aborts.
3. **Every promotion is preceded by full codegen validation.** Gate 6. The candidate is compiled and the conformance suite is run.
4. **Every promotion is explicitly flagged upon deployment.** Gate 8. `SAFE_APPROVED` for clean changes, `SAFE_FLAGGED` for operator review, `UNSAFE_REJECTED` aborts.
5. **The Catalyst itself is a Reduction.** It can be rolled back via inverse ring (a bad promotion is reversible). The Catalyst's *own state* (its learned patterns, its proposal queue) is also a witnessed reduction graph and can be inverted.

### §4.2 The Constitutional Floor

The Catalyst's parameters (rate cap, coherence floor, saturation threshold, Hoeffding bounds, Welford stability epsilon) are **constitutional constants**. Changing them requires `amend.apply` at constitutional tier. The Catalyst cannot weaken its own gates.

### §4.3 The Operator Override

At any time, the operator can:

- **Pause the Catalyst** — `catalyst.pause()` halts all proposals and promotions until resumed.
- **Reject a pending proposal** — `catalyst.reject(proposal_mhash)` removes a proposal from the queue.
- **Revoke a promotion** — `inverse.replay(promotion_witness)` reverses a prior promotion. The cycle table re-establishes the prior dispatch target; the new cycle remains in the table for audit but is no longer preferred.
- **Constrain promotions** — `catalyst.constrain(domain, max_rate)` lowers the rate cap for a specific domain.

These overrides are themselves cycles (witnessed, reversible).

---

## §5. The Mechanism in One Sentence

> The Catalyst turns a static language into a living, self-improving sovereign substrate — **safely**: every change is observed, evaluated against eight gates, codegen-validated, ring-gated, witnessed, federated, and reversible.

---

## §6. Closure Identity Rule (R1.B1)

R1.B1 = `SHA-256(canonical_byte_form(this_file))`. Embedded in every compiled module's closure manifest and in the composite specification root R1.

---

## §7. Conformance Criteria

- **C-CAT-1.** All eight promotion gates (§2.1) are implemented and checked in order. C-15 in III-CONFORMANCE.md.
- **C-CAT-2.** Promotion rate caps (§2.3) are enforced per chronos-tick.
- **C-CAT-3.** Every promotion emits `XII_STEP_KIND_MNEME_CATALYST_PROMOTE` with the eight-gate sub-witnesses.
- **C-CAT-4.** The five inviolable rules (§4.1) are enforced; violations abort promotion.
- **C-CAT-5.** Operator overrides (§4.3) are first-class cycles, witnessed and reversible.

---

## §8. Final Declaration

The Catalyst is **the active, self-modifying force that animates the Möbius manifold** — bounded by eight gates, ring-gated, witnessed, federated, reversible. It turns III from a sealed language into a living substrate that improves itself faster than human language design ever could.

**III-CATALYST.md — the engine of self-extension under absolute safety discipline.**

*Sealed. R1.B1 = SHA-256(canonical_byte_form(this_file)).*
