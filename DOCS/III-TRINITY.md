# III-TRINITY.md — The Trinity Admission Manifold

**Document Identity:** A9 / The Admission Manifold / Invisible, Precise, Sovereign Governance
**Canonical Hash Slot:** R1.A9
**Version:** 1.0 — Final & Sealed
**Date:** 2026-05-03
**Authority:** Canonical. This is the only admission discipline the SELF compiler may enforce.

---

## §0. Preamble — Invisible Presence, Surgical Precision

Most governance systems fail in one of two ways:

- **Overly intrusive.** They add constant overhead and cognitive load (Rust's borrow checker, complex effect systems, mandatory runtime-check decorators). The programmer pays a tax on every line of effectful code — even when the operation is trivially safe.
- **Overly weak.** They only catch problems after damage has occurred (most capability systems, traditional ACLs, after-the-fact audit logs). Prevention is left to "best practices."

**III rejects both failures.**

The Trinity Admission Manifold is designed to be:

- **Invisible system-wide.** It runs on every reduction, but with **near-zero overhead** in the common case (pure code, hot paths, low-risk operations). The 99% case pays one cycle (a single bit test) — invisible compared to the operation's actual work.
- **Minimally deployed.** Most cycles only trigger the **lightest possible check**. Full three-layer evaluation is reserved for high-risk, high-uncertainty, or constitutionally significant operations — exactly where the cost is justified.
- **Dynamically capable.** The manifold itself **evolves**. The Catalyst can promote better admission rules, pre-compute hot-path decisions, and even extend the Trinity predicate at runtime — making the governance system smarter over time.

This is not a gate. This is a **living, self-improving, epistemically-aware, Möbius-coherent admission manifold** that protects the entire sovereign substrate while staying out of the way until it is genuinely needed — at which point it becomes extraordinarily precise and powerful.

---

## §1. The Three-Layer Ceiling (Formal Structure)

Every `Reduction` in III is evaluated against a three-layer ceiling before it is allowed to commit. The layers are checked in order; any layer's pass admits the reduction without invoking the next layer (when the operation is admissible at the lower layer).

### §1.1 Layer 1 — SCBA Bit-Test (Lightweight Presence Check)

**SCBA = Sovereign Constitutional BitArray.** An 8-KiB bitarray (65,536 bits) where each bit represents a pre-approved state hash or operation class. Bit `i` is set ⇔ the i-th canonical post-state is admitted.

The hash function from operation to bit index: `bit_idx = first_16_bits(BLAKE3(canonical_form(reduction.post_state)))`. This gives `2^16 = 65,536` slots, with collisions handled by a secondary BCWL-style overflow lattice (per III-CYCLES.md §4.3).

**Judgment:**

```
Γ ⊢ r : Reduction(...)
Γ ⊢ post_state(r) : State
Γ ⊢ scba_bit_test(post_state(r)) == 1
─────────────────────────────────                                   (SCBA-Sufficient)
Γ ⊢ r is admitted (Layer 1 only)
```

**When sufficient (Layer 1 alone admits):**

- `@pure` cycles (zero-effect; the post-state is unchanged from pre-state, which is always SCBA-bit set).
- Low-risk, well-known hot paths pre-approved by SRPA (the most-frequent cycles in OBSERVATORY have their post-states pre-bit-set).
- Operations inside an active `waac` block that already passed full Trinity at the wavefront's commit boundary.

**Overhead: 1–2 cycles** (one bit test, branch-prediction-friendly, no memory load on cache hit).

### §1.2 Layer 2 — ACC Wall-Y Composed-Delta Admit

**ACC = Adversarial Capability Composition.** **Wall-Y** = the composed delta vector across all effects in a wavefront.

Layer 2 evaluates the **composed delta** of a wavefront (multiple cycles together) against the current state. The composed delta is computed by `acc_compose(w.effects)`, which produces a Z₃⁶-typed delta vector (one trit per safety dimension, summed across the wavefront's cycles using the asymmetric-ternary algebra of III-HEXAD.md §1.2).

**Judgment:**

```
Γ ⊢ w : wavefront (with N effects e₁, …, eₙ)
Γ ⊢ composed_delta = acc_compose(w.effects) : Hexad
Γ ⊢ wall_y_admit(current_state, composed_delta) == 1
─────────────────────────────────                                   (ACC-Sufficient)
Γ ⊢ w is admitted (Layer 2)
```

**When sufficient (Layer 2 alone admits, when Layer 1 didn't):**

- Multi-effect wavefronts that don't touch Ring -2.
- Operations with low epistemic uncertainty (`U.confidence ≥ 0.85q`).
- Cycles that have already passed SCBA but compose into a state that requires ACC-level verification.
- Any cycle whose composed hexad has all four structural pillars in POS (admissible without Layer 3 escalation).

**Overhead: ~15–40 cycles** (delta composition + lookup in a per-state ACC admission table).

### §1.3 Layer 3 — Trinity Gate (Full Evaluation)

**Trinity Gate = Intent × Capability × Causality × Sanctum-State.** The full four-conjunct admission predicate.

**Judgment:**

```
Γ ⊢ r : Reduction(...)
Γ ⊢ intent       = operator_consent(current_session)        : Prop
Γ ⊢ cap          = permission_cap(current_caller)            : Prop
Γ ⊢ causality    = current_audit_head_relation(r)            : Prop
Γ ⊢ sanctum_state = current_sanctum_frame(r)                : Prop
Γ ⊢ trinity_algebra_admit(intent, cap, causality, sanctum_state, r.hexad, r.post_state)
─────────────────────────────────                                   (Trinity-Required)
Γ ⊢ r is admitted (all three layers, Layer 3 dispositive)
```

The `trinity_algebra_admit` function is implemented in `STDLIB/trinity.III` and `BOOTSTRAP/trinity.{h,c}`. It evaluates each conjunct independently and returns a `XiiConvergencePoint` — a structure recording which layer admitted, which conjuncts contributed, and the witness mhashes of each conjunct's discharge.

**When required (Layer 3 always required):**

- Any operation touching Ring -2 (`@sanctum_only`).
- Constitutionally significant cycles (`@tier(constitutional)`).
- High-uncertainty operations (`Uncertainty.confidence < 0.85q` triggers automatic escalation).
- Catalyst promotions and grammar extensions.
- Any cycle whose composed hexad has a NEG pillar in positions 5 or 6 (informational pillars that warrant full evaluation; structural NEG in 1–4 is untypable per III-HEXAD.md §4).
- DRTM relaunches.
- Federation outbound at tier ≥ 2.

**Overhead: 80–300 cycles** (full predicate evaluation + four conjunct discharges + witness emission for the convergence point).

---

## §2. Failure-Mode Error Codes

Each layer's failure is reported with a precise code:

| Code | Meaning | Layer | Recovery action |
|------|---------|-------|-----------------|
| `TRINITY_INTENT_REJECT` | Operator consent missing or expired | Layer 3 | Re-authenticate (operator presents fresh consent) |
| `TRINITY_CAP_REJECT` | Insufficient or drifted capability | Layer 3 | Re-acquire cap (operator-authorized cap mint) |
| `TRINITY_CAUSALITY_REJECT` | Audit head too far behind or compromised | Layer 3 | Force audit replay; reset chain head |
| `TRINITY_SANCTUM_REJECT` | Sanctum frame inactive or invalid | Layer 3 | Re-enter sanctum via fresh `sanctum_enter` |
| `ACC_WALL_Y_REJECT` | Composed delta violates current state | Layer 2 | Rollback wavefront via inverse ring |
| `SCBA_BIT_REJECT` | Post-state not in pre-approved set | Layer 1 | Escalate to Layer 2 / 3 (the SCBA reject is informational; the cycle still proceeds to higher layers unless terminal) |
| `HEXAD_UNREPRESENTABLE` | Safety hexad outside reachable set | All layers | Compile-time error (untypable) |
| `MOBIUS_COHERENCE_FAIL` | Post-state drops manifold coherence below floor | Layer 3 | Reject + propose safer alternative via Catalyst |
| `CEILING_VIOLATION` | Post-state outside constitutional manifest | Layer 3 | Hard reject + emit `XII_STEP_KIND_COMPROMISE_QUOTE` |
| `EPISTEMIC_LOW_CONFIDENCE` | Uncertainty below 0.85q threshold | Layer 3 | Escalate + invoke `reflect(uncertainty)` |
| `WAAC_VIOLATION` | Wavefront-as-Capability constraint violated | Layer 2 / 3 | Rollback to last waac commit; re-acquire waac |

Every reject emits a `XII_STEP_KIND_TRINITY_REJECT` witness with the failed-conjunct details and the operator-actionable recovery hint.

---

## §3. Novel Invention 1 — Predictive Trinity (Invisible System-Wide Presence)

### §3.1 The Problem

Evaluating full Trinity on every reduction would destroy performance. A naive implementation that ran all four conjuncts of Layer 3 on every cycle invocation would impose 80–300 cycles per cycle invocation — making hot paths unviable.

### §3.2 The Solution — Predictive Trinity

The compiler + SRPA + PIP **pre-compute Trinity decisions for hot paths**.

```iii
@predictive_trinity(HOT_PATH)
cycle frequently_called(...) -> ... { ... }
```

At compile time (and via runtime SRPA promotion), the system:

1. **Records the most common (intent, cap, causality, sanctum_state) tuples** for this cycle in OBSERVATORY.
2. **Pre-evaluates Trinity** for those tuples — computes whether each tuple admits.
3. **Stores the pre-evaluation in a `pip_blob`** indexed by tuple-hash.

At runtime, the common case becomes a **single bit test (Layer 1 + cached Trinity result)** instead of full Trinity. The system pays the full Trinity cost only when the runtime tuple does *not* match a pre-evaluated tuple — which, for hot paths, is rare by definition.

### §3.3 The Predictive Trinity Lookup

```
Γ ⊢ r : cycle invocation
Γ ⊢ tuple_hash = hash(intent, cap, causality, sanctum_state)
Γ ⊢ predictive_trinity_pip[tuple_hash] = ADMIT | DENY | ESCALATE
─────────────────────────────                                       (Predictive-Trinity)
if predictive_trinity_pip[tuple_hash] = ADMIT:
    admit r at near-zero cost (Layer 1 path)
elif predictive_trinity_pip[tuple_hash] = DENY:
    reject r with TRINITY_<conjunct>_REJECT
elif predictive_trinity_pip[tuple_hash] = ESCALATE:
    fall through to Layer 2 / Layer 3 full evaluation
```

The cache is updated by a background SRPA tick: as new tuples are observed, they are added to the cache (with `ADMIT` / `DENY` / `ESCALATE` based on the full Trinity evaluation of the first observation).

### §3.4 Result

**Trinity is invisible on 99%+ of executions** while remaining fully active and accurate when needed. Hot paths pay 1–2 cycles for the bit test; cold paths or first-observation paths pay the full Layer 3 cost. The system does not lose any of Trinity's guarantees — every cycle is still gated by the conjuncts; the *evaluation* is just amortized.

---

## §4. Novel Invention 2 — Epistemic Trinity (High-Accuracy When It Matters)

When a cycle carries `Uncertainty<...>`, Trinity automatically **escalates**.

### §4.1 The Escalation Rule

```
Γ ⊢ r : Reduction(F, I, W, H, P, E) carrying Uncertainty(D, C, Q)
Γ ⊢ C < THRESHOLD                          (THRESHOLD = 0.85q by default)
─────────────────────────────                                       (Epistemic-Escalation)
Γ ⊢ r requires full Layer 3 + reflect(uncertainty)
```

The system can:

- **Downgrade** high-uncertainty operations: if the cycle's effect is non-essential, the system may proceed at a lower tier (e.g., transient instead of host_file) and emit a downgrade witness.
- **Reject** before execution: if the open questions in `Q` cannot be discharged by the cognitive layer, the cycle is refused.
- **Force a `negotiate` step**: invoke the cognitive primitive to refine the operation with the operator.
- **Force a `propose` step**: surface the operation to the Catalyst's proposal queue, deferring execution until OBSERVATORY saturates further.

### §4.2 The Cognitive Hand-Off

When epistemic escalation forces a `reflect`/`negotiate`/`propose`, the cycle's invocation is **paused** (its forward execution is held; its predecessor mhash is preserved). The cognitive primitive runs asynchronously (sub-second for `reflect`; up to operator-response-time for `negotiate`). When the cognitive primitive returns, the cycle resumes:

- If `reflect(uncertainty)` returns a higher-confidence state (the system has learned more from OBSERVATORY since the cycle was paused), the cycle re-evaluates Trinity with the updated confidence.
- If `negotiate` returns a refined goal, the cycle's forward is re-bound to the refined goal and re-admitted.
- If `propose` returns ACCEPT (the Catalyst promoted a better abstraction), the cycle is re-dispatched against the promoted abstraction.

This is unprecedented: **the cognitive layer participates in admission at the Trinity Gate**. Most systems treat cognitive output as advisory; III treats it as **gating**.

### §4.3 Result

**The system is minimally deployed but extremely accurate when risk is real.** Low-uncertainty operations (most operations) bypass the cognitive layer. High-uncertainty operations get the cognitive layer's full attention.

---

## §5. Novel Invention 3 — Möbius Trinity (Self-Consistency Governance)

Trinity can evaluate not just the current reduction, but its **effect on manifold coherence**.

### §5.1 The Möbius Rule

```
Γ ⊢ r : Reduction(...)
Γ ⊢ post_coherence = möbius.coherence_after(r) : Q14
Γ ⊢ post_coherence ≥ floor                    (default floor = 0.92q)
─────────────────────────────                                       (Möbius-Trinity)
Γ ⊢ r is manifold-safe
```

`möbius.coherence_after(r)` is a `@pure` query that simulates the reduction's effect on manifold coherence (without committing the reduction) and returns the projected post-coherence Q14. The simulation is:

- Apply the reduction abstractly to the cached coherence state.
- Compute the new coherence by re-running the coherence aggregator (Welford-bounded over recent witness chain segments).
- Return the projected value.

If `post_coherence < floor`, the reduction is rejected with `MOBIUS_COHERENCE_FAIL`. The Catalyst is invoked to propose an alternative cycle whose effect preserves coherence.

### §5.2 What This Prevents

This **prevents reductions that would damage the long-term self-consistency of the entire system** — even if they pass the other layers. A cycle that is intent-admitted, cap-admitted, causality-admitted, and sanctum-admitted but would (over many invocations) drive the manifold into incoherence is rejected.

### §5.3 The Coherence Floor Is Constitutional

The default coherence floor (0.92q) is a constitutional value. Changing it requires `amend.apply` at constitutional tier — the same level as adding a new sanctum sealed slot. This prevents drift in the floor from silently weakening the manifold's governance.

---

## §6. Novel Invention 4 — Catalyst Trinity (The Manifold Evolves)

The Catalyst can **promote improved Trinity predicates**.

### §6.1 The Mechanism

A `mobius_candidate` declared with the appropriate hexad can offer an enhanced Trinity-conjunct evaluator:

```iii
mobius_candidate better_intent_admit(
    op: Operation,
    consent: Consent
) -> Bool @candidate_for_promotion @hexad(GOVERNANCE_OBSERVED) {
    forward {
        // a more nuanced intent admission that considers
        // operator-history patterns from OBSERVATORY
        observatory.observe_pattern(intent_pattern_schema);
        // ... refined logic ...
    }
}
```

When this candidate saturates and the Catalyst promotes it, the `intent_admit` conjunct of Layer 3's Trinity evaluation **uses the new evaluator** for all future admissions. Old admissions remain admitted (the `XII_STEP_KIND_TRINITY_PROMOTE` witness records the predicate transition; replays under the old predicate continue to verify).

### §6.2 What This Gives Us

**Trinity is self-improving** — the governance system gets smarter over time. The Catalyst can refine each of the four conjuncts independently, and each refinement is:

- Witnessed (`XII_STEP_KIND_TRINITY_PROMOTE`).
- Federated (peers replicate the new predicate).
- Reversible (a bad refinement can be inverted).
- Bounded (rate-cap, coherence-floor, codegen-validation).

### §6.3 What May Not Be Promoted

- Removing a conjunct (the four-conjunct structure is constitutional).
- Reordering the layers (SCBA before ACC before Trinity is constitutional).
- Removing the SCBA fallback for `@pure` cycles.
- Promoting a predicate whose admit-set is *narrower* than the prior — Trinity can grow stricter only via `amend.apply` at constitutional tier.

---

## §7. Novel Invention 5 — Ghost Trinity (Audit-Only Mode)

For low-risk or audit-only paths, Trinity can run in **ghost mode**.

### §7.1 The Mechanism

```iii
cycle audit_path(...) @ghost_trinity {
    // Executes with full Trinity evaluation but only emits a ghost witness
    // No state change. No commit. The evaluation is recorded for audit.
}
```

A `@ghost_trinity` cycle:

- Runs all three layers (SCBA, ACC, Trinity) with full evaluation.
- Emits witnesses for each layer's outcome (admit / reject / escalate).
- **Does not commit** the reduction's state change.
- **Does not append** to the inverse ring (no rollback target).
- Returns a ghost-result type indicating what *would* have happened.

### §7.2 What This Enables

- **Simulation**: run a hypothetical sequence of cycles to see whether they would pass Trinity, without actually executing.
- **Testing**: regression tests can verify Trinity admission without disturbing live state.
- **High-volume audit trails**: federation peers can replay each other's witnessed cycles in ghost-Trinity mode to produce a fresh audit independently.

Ghost Trinity is the **dual** of Ghost Effects (III-EFFECTS.md §4): Ghost Effects are reductions that emit witnesses without effects; Ghost Trinity is admissions that evaluate without committing.

---

## §8. Dynamic Layer Activation (Runtime Intelligence)

The system can dynamically decide **which Trinity layers are active** based on the current risk profile:

| Risk profile | Active layers | Per-cycle cost |
|--------------|---------------|----------------|
| Low-risk system state (few open questions, high coherence, no constitutional changes pending) | Layer 1 only (SCBA) | 1–2 cycles |
| Medium-risk or multi-effect | Layer 1 + Layer 2 | 15–40 cycles |
| High-risk, high-uncertainty, or any Ring -2 entry | Full Layer 3 | 80–300 cycles |

### §8.1 Risk Profile Inference

The risk profile is itself a Q14-typed value computed by a meta-Trinity check on the substrate's current state:

```
risk_q14 = max(
    1.0q - möbius.coherence(),
    inverse(observatory.average_uncertainty()),
    constitutional_change_pending_indicator(),
    sanctum_active_indicator()
)
```

The decision "which layers are active" is made by a lightweight Trinity check on this `risk_q14` value — creating a **self-referential, stable governance loop**: the governance system governs *itself*, deciding how much governance to apply.

### §8.2 Stability of the Self-Reference

The self-referential loop is stable because:

1. The risk-q14 computation is `@pure` (no effects).
2. The "active layers" decision is a small lookup table indexed by risk-q14 quartile.
3. Layer-elevation (Layer 1 → Layer 2 → Layer 3) is monotonic during high-risk periods.
4. Layer-de-elevation (Layer 3 → Layer 2 → Layer 1) is gradual: the system stays at the higher layer for at least one chronos-tick after risk drops, preventing oscillation.

---

## §9. Why This Trinity Manifold Is Unprecedented

1. **Invisible system-wide.** Predictive Trinity + SRPA makes it near-zero cost on hot paths. The 99% case pays one cycle.
2. **Minimally deployed.** Most operations only pay for the layer they actually need.
3. **Extremely accurate when it matters.** Epistemic + Möbius + full Trinity for high-risk cases.
4. **Self-improving.** Catalyst can enhance the predicate over time.
5. **Crash-proof and unrepresentable failures.** Bad operations are rejected at the type level (via III-HEXAD.md's Representability Theorem) or by Layer 1/2 before they reach Layer 3.
6. **Seamlessly integrated with the cognitive layer.** High-uncertainty operations trigger `reflect`/`negotiate`/`propose` automatically.
7. **Zero-latency critical paths.** Hot Sanctum and constitutional operations are pre-approved (Predictive Trinity) or specialized (Sanctum specialization).

No other governance system in computing has ever achieved this combination of invisibility, precision, self-improvement, and sovereign grounding.

---

## §10. Closure Identity Rule (R1.A9)

R1.A9 = `SHA-256(canonical_byte_form(this_file))`. Embedded in every compiled module's closure manifest and in the composite specification root R1.

---

## §11. Catalyst Extension Pathway

Catalyst-promoted Trinity refinements are specified in §6 above. Reserved slots for new conjuncts (an unimaginable fifth conjunct beyond intent × cap × causality × sanctum) require `amend.apply` at constitutional tier — no Catalyst promotion can add a conjunct without constitutional consent.

---

## §12. Conformance Criteria

- **C-TRIN-1.** Three-layer ceiling is implemented exactly as in §1; layers run in order; later layers admit only if earlier layers do not terminate. C-18 in III-CONFORMANCE.md.
- **C-TRIN-2.** Predictive Trinity caches admit/deny decisions and achieves <5-cycle hot-path latency on representative workloads. C-9.
- **C-TRIN-3.** Epistemic escalation triggers automatically when `U.confidence < 0.85q`. C-10.
- **C-TRIN-4.** Möbius Trinity rejects reductions whose projected post-coherence falls below floor.
- **C-TRIN-5.** Catalyst Trinity promotions emit `XII_STEP_KIND_TRINITY_PROMOTE` witnesses; old admissions remain admitted under their predicate-version.
- **C-TRIN-6.** Ghost Trinity evaluates without committing; emits ghost witnesses.
- **C-TRIN-7.** Dynamic Layer Activation is stable (no oscillation under stable risk profile).

---

## §13. Final Declaration

Trinity is not a gate.
Trinity is not overhead.
Trinity is **the living constitution of the sovereign manifold** — invisible until it is needed, then extraordinarily precise, epistemically aware, and self-improving.

**III-TRINITY.md — the admission manifold that protects everything while staying out of the way.**

*Sealed. R1.A9 = SHA-256(canonical_byte_form(this_file)).*
