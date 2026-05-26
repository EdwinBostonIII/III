# III-CATALYST-EXT.md — Catalyst Extensions Architectural Mandate

**Document Identity:** CATALYST-EXT / Architectural Mandate / Wave 8 / Items 72-78
**Status:** **DERIVATIVE — NOT part of the R1 sealed set, but architecturally binding on every Wave-8+ implementation.** This document specifies extensions to the Catalyst (B1) for self-extending intelligence: causal-DAG-driven hypothesis synthesis, counterfactual replay verification, composite-cycle promotion, and JIT integration — all bounded by the Founder's Anchor restraint per III-FOUNDERS-ANCHOR.md.
**Version:** 1.0 — 2026-05-03 (Wave 8)
**Sources:** All 15 R1-sealed specs; III-PERFORMANCE.md; III-FOUNDERS-ANCHOR.md (the Catalyst restraint is here); III-CATALYST.md (B1); III-OBSERVABILITY.md; III-GHOST-CODE.md; Stateful Neumann §3.4 (causal inference + Catalyst synthesis + JIT).
**Cluster integrated:** items 72 (causal-DAG-driven hypothesis synthesis), 73 (counterfactual replay infrastructure), 74 (composite-cycle promotion gate), 75 (composition rate-cap), 76 (Möbius coherence floor), 77 (Catalyst Anchor-restraint integration), 78 (Catalyst-synthesized JIT integration).

---

## §0. Preamble — The Substrate's Self-Extending Intelligence

III is not a static substrate. Its primitives admit **emergent extension**: the Catalyst observes the substrate's own causal structure, hypothesizes new abstractions from observed patterns, verifies hypotheses via counterfactual replay, grounds verified hypotheses as language primitives, and specializes hot primitives via JIT.

This is **genuine intelligence in the substrate**: the substrate learns from its own operation, gates that learning by mathematical and constitutional restraints, witnesses every step, and remains operator-controllable at every threshold.

The four loops (per Stateful Neumann §3.4):

1. **Observation loop**: every cycle's sufficiency gate is checked inline (per III-OBSERVABILITY.md §1).
2. **Causal inference loop**: PC + FCI on the witness graph identifies causal edges.
3. **Hypothesis-and-promotion loop**: high-confidence edges are lifted to composite cycle candidates.
4. **JIT specialization loop**: promoted candidates are JIT-compiled to native code.

Each loop is bounded by:

- **Rate caps** (no runaway promotion).
- **Möbius coherence floors** (no degenerate hypotheses).
- **Trinity gating** (operator consent for high-stakes promotions).
- **Anchor restraint** (no anchor-weakening hypotheses).
- **Compromise tier** (degraded promotions execute under restricted cap).

This document specifies:

1. **§1** — Causal-DAG-driven hypothesis synthesis (item 72)
2. **§2** — Counterfactual replay infrastructure (item 73)
3. **§3** — Composite-cycle promotion gate (item 74)
4. **§4** — Composition rate-cap discipline (item 75)
5. **§5** — Möbius coherence floor for promotion (item 76)
6. **§6** — Catalyst Anchor-restraint integration (item 77)
7. **§7** — Catalyst-synthesized JIT integration (item 78)
8. **§8** — Conformance criteria
9. **§9** — Final statement

---

## §1. Causal-DAG-Driven Hypothesis Synthesis (Item 72)

### §1.1 The mandate

The Catalyst (B1) is extended with a **synthesizer** that consumes the causal-DAG (per Stateful Neumann §3.4 / S16) and produces composite cycle candidates.

### §1.2 The causal-DAG observation

The substrate maintains a causal-DAG `G = (Nodes, Edges)` where:

- `Nodes`: cycle-kinds (per III-CYCLES §3.2).
- `Edges`: directed pairs `(c1, c2)` representing observed causal precedence.
- Each edge carries:
  - **Confidence** (Q14): from PC algorithm conditional-independence tests.
  - **Frequency**: how often the edge was observed in steady-state.
  - **Latency distribution**: how soon c2 follows c1 on average.

### §1.3 The synthesizer algorithm

```iii
fn catalyst_synthesize_candidates() -> [CompositeCycleCandidate] {
    let dag = causal.current_dag()
    let candidates = []
    
    for edge in dag.edges {
        when edge.confidence_q14 >= XII_CATALYST_SYNTHESIS_CONFIDENCE_FLOOR -> {
            // High-confidence edge: hypothesize composition.
            let candidate = compose_cycles(edge.from, edge.to, edge.metadata)
            candidates.push(candidate)
        }
    }
    
    // Filter: anchor-invariant compliance, hexad admissibility, etc.
    candidates = candidates.filter(catalyst_filter_for_anchor_invariant)
    candidates = candidates.filter(hexad_check_admissible)
    candidates = candidates.filter(rate_cap_within_budget)
    
    return candidates
}
```

### §1.4 The composition

For an edge `(c1, c2)` of confidence ≥ floor:

```iii
fn compose_cycles(c1: CycleKind, c2: CycleKind, meta: CausalMetadata) -> CompositeCycleCandidate {
    // The composed cycle's forward applies c1 then c2 sequentially.
    let composed_forward = sequential_compose(c1.forward, c2.forward)
    
    // The composed cycle's inverse applies c2's inverse then c1's inverse.
    let composed_inverse = sequential_compose(c2.inverse, c1.inverse)
    
    // The composed hexad is the Z₃⁶ delta sum.
    let composed_hexad = c1.hexad.compose(c2.hexad)
    
    return CompositeCycleCandidate {
        cycle_id: allocate_synthesis_id(),
        forward: composed_forward,
        inverse: composed_inverse,
        hexad: composed_hexad,
        derived_from_edge: Some(edge_id),
        synthesis_witness: pending,
    }
}
```

### §1.5 The synthesis witness

```
CATALYST_SYNTHESIS_WITNESS {
    causal_edge_id: EdgeId,
    candidate_id: CandidateId,
    synthesis_timestamp: u64,
    derived_confidence_q14: u32,
    synthesizer_state: ...,
}
```

### §1.6 The synthesizer's NIH discipline

The synthesizer is hand-rolled in `STDLIB/catalyst_synth/`. No external library; no genetic-algorithm framework; no neural-network framework. The synthesizer is purely deterministic over the causal-DAG.

---

## §2. Counterfactual Replay Infrastructure (Item 73)

### §2.1 The mandate

Before promotion, candidates undergo **counterfactual verification**: the substrate re-runs the relevant region of the witness chain, intervening to test the candidate's hypothesis, and compares the result.

### §2.2 The counterfactual replay algorithm

```iii
fn counterfactual_replay(
    candidate: CompositeCycleCandidate,
    witness_range: WitnessRange
) -> CounterfactualResult
    @ring(R-2)
    @hexad(COUNTERFACTUAL_REPLAY)
    @sanctum_only
    @cap(replay<witness_range>)
{
    forward {
        // 1. Snapshot the substrate state at witness_range.start.
        let snapshot = substrate_state_at(witness_range.start)
        
        // 2. Replay the chain forward, applying the candidate composite cycle
        //    where the original chain applied the un-composed components.
        let counterfactual_chain = replay_with_intervention(snapshot, witness_range, candidate)
        
        // 3. Compare counterfactual to factual.
        let factual_chain = chain_segment(witness_range)
        let divergence = compare_chains(factual_chain, counterfactual_chain)
        
        // 4. Result: divergence summary + verification status.
        return CounterfactualResult {
            divergence: divergence,
            verification_status: when divergence.is_acceptable() -> VERIFIED else -> FAILED,
        }
    }
}
```

### §2.3 The Sanctum-sealed replay

Counterfactual replay runs **inside the SANCTUM** (R-2). This prevents:

- Replay state leaking into the live substrate.
- Counterfactual artifacts becoming observable to non-replay code.
- Side-channel attacks via measuring replay timing.

### §2.4 The acceptable divergence

The substrate defines what divergence is **acceptable**:

- Identical witness chain (modulo timestamps): perfect verification.
- Minor variation in compromise tier (e.g., compromise.low → verified): acceptable.
- Different cycle output values: **not acceptable** (the candidate produces incorrect results).
- Different observability metrics: acceptable.
- Different audit chain hashing: **not acceptable**.

### §2.5 The Trinity gating

Counterfactual replay is Trinity-gated: it requires `cap<replay<witness_range>>` (Trinity-gate-acquired by the operator), `cap<sanctum_seal_replay>` for the SANCTUM seal, and observer-of-tier admission.

### §2.6 The witness emission

```
COUNTERFACTUAL_REPLAY_WITNESS {
    candidate_id: CandidateId,
    witness_range: WitnessRange,
    divergence_summary: DivergenceSummary,
    verification_status: VerificationStatus,
    timestamp: u64,
}
```

---

## §3. Composite-Cycle Promotion Gate (Item 74)

### §3.1 The mandate

Promotion of a candidate to live cycle status passes through multiple gates:

1. **Anchor restraint check** (per §6 / III-FOUNDERS-ANCHOR.md §9.1): the candidate must not weaken the Anchor.
2. **Hexad admissibility check** (per III-HEXAD §6.4): the composed hexad must be reachable.
3. **SID inverse derivation** (per III-CYCLES §5.2): the composed inverse must be derivable.
4. **Counterfactual replay** (per §2): the candidate must verify against historical chain.
5. **Möbius coherence floor** (per §5): the candidate's predicted impact must maintain coherence.
6. **Rate-cap acceptance** (per §4): the substrate's promotion budget must accommodate.
7. **Trinity gating** (operator consent): for tier ≥ federation, operator approval required.
8. **Anchor cosignature** (for tier = constitutional): Founder's Anchor cosigns.

### §3.2 The promotion process

```iii
cycle promote_candidate(candidate: CompositeCycleCandidate) -> Witness
    @ring(R0)
    @hexad(CATALYST_PROMOTE)
    @cap(catalyst<promote>)
{
    forward {
        // Gate 1.
        when !catalyst_filter_for_anchor_invariant(candidate) -> {
            reject_candidate(candidate, "anchor-invariant-violation")
            return rejection_witness
        }
        
        // Gates 2-8 (each can reject).
        ...
        
        // All gates pass: promote.
        register_in_dispatch_table(candidate)
        emit_witness(CATALYST_PROMOTED, candidate)
        emit_witness(VERIFIED_NEW_CYCLE_KIND, candidate.cycle_id)
        return promotion_witness
    }
}
```

### §3.3 The rejection witness

```
CATALYST_REJECTED_WITNESS {
    candidate_id: CandidateId,
    rejection_gate: GateName,
    rejection_reason: string,
    rejection_evidence_mhash: mhash,  // What was checked
    timestamp: u64,
}
```

Rejections are recorded; the operator can audit which candidates were rejected and why.

### §3.4 The rejection's compromise classification

Repeated rejection patterns (e.g., many candidates rejected for anchor-invariant violations) trigger compromise witness emission:

- Pattern of anchor-invariant rejections: emit `compromise.high` with reason `anchor-attack-pattern` (per III-FOUNDERS-ANCHOR.md §9.2).
- Pattern of rate-cap rejections: emit `compromise.low` with reason `synthesis-saturation` (informational).

---

## §4. Composition Rate-Cap Discipline (Item 75)

### §4.1 The mandate

The substrate caps the rate of Catalyst promotions per chronos VDF tick:

```iii
constant XII_MNEME_CATALYST_PROMOTION_RATE_PER_TICK = 8
constant XII_MNEME_CATALYST_PROMOTION_PER_EPOCH_MAX = 1024
```

A tick exceeding the per-tick rate-cap defers promotions to the next tick. An epoch exceeding the per-epoch maximum triggers `compromise.medium` with reason `catalyst-saturation`.

### §4.2 The per-tick budget

The 8-promotion-per-tick budget is divided among:

- 4 promotions for high-confidence causal-DAG edges.
- 2 promotions for operator-submitted candidates.
- 2 promotions for federation-recommended candidates.

If any sub-budget is unfilled, the unused slots roll to the other sub-budgets.

### §4.3 The emergency override

The operator can override the rate-cap for specific tier-1 emergency promotions (e.g., critical performance fixes during crisis). The override:

- Requires explicit operator-signed directive.
- Increases the per-tick cap by 8 for one tick.
- Emits witness with `OPERATOR_RATE_CAP_OVERRIDE`.

### §4.4 The federation-wide rate-cap

In a planetary-scale federation, the substrate-wide promotion rate is the **sum of per-peer rates**. To prevent runaway, the federation aggregates per-peer rates; if any peer exceeds the cap, the federation issues a `RATE_CAP_VIOLATION` witness against that peer.

### §4.5 The closure-pinned cap

The rate-cap constants are closure-pinned. Modifying requires Tier-3 + Anchor cosignature.

---

## §5. Möbius Coherence Floor for Promotion (Item 76)

### §5.1 The mandate

Per III-CATALYST.md / Stateful Neumann §3.4 / S17: a candidate is promoted only if its predicted impact maintains the substrate's Möbius coherence floor (Q14 ≥ 0.75; per `XII_MNEME_COHERENCE_FLOOR_Q14 = 12288`).

### §5.2 The pre-promotion coherence prediction

Before promotion, the substrate predicts the candidate's impact:

```iii
fn predict_coherence_impact(candidate: CompositeCycleCandidate) -> Q14 {
    // Simulate K cycles using the candidate.
    let simulated_chain = simulate_with_candidate(candidate, K=10000)
    
    // Compute coherence over the simulated chain.
    let predicted_coherence = compute_mobius_coherence(simulated_chain)
    
    return predicted_coherence
}
```

If `predicted_coherence < XII_MNEME_COHERENCE_FLOOR_Q14`, the promotion is rejected.

### §5.3 The post-promotion monitoring

Post-promotion, the substrate monitors actual coherence over the next 10⁶ ticks (the **burn-in period**). If actual coherence drops below the floor:

1. The substrate emits `compromise.medium` with reason `coherence-floor-violation`.
2. The candidate is **de-promoted**: removed from the dispatch table, reverts to ghost state.
3. A `CATALYST_DEPROMOTED` witness is emitted.

### §5.4 The de-promotion

De-promotion is an inverse of promotion. The witness chain records:

```
CATALYST_DEPROMOTED_WITNESS {
    candidate_id: CandidateId,
    de_promotion_reason: string,
    final_coherence_q14: u32,
    de_promotion_timestamp: u64,
}
```

After de-promotion, calls to the de-promoted cycle return `GHOST-NOT-EXECUTABLE` (per III-GHOST-CODE.md §4.3).

### §5.5 The closure-pinned floor

The coherence floor is closure-pinned. Modifying requires Tier-3 + Anchor cosignature.

---

## §6. Catalyst Anchor-Restraint Integration (Item 77)

### §6.1 The mandate

Per III-FOUNDERS-ANCHOR.md §9: the Catalyst's hypothesis-generation includes a hard-wired filter that rejects candidates that would weaken the Anchor.

### §6.2 The filter integration in the synthesizer

```iii
fn catalyst_filter_for_anchor_invariant(candidate: CompositeCycleCandidate) -> Bool {
    // Check 1: Does the candidate modify FOUNDERS_ANCHOR_PUBLIC_KEY?
    when candidate.proof_certificate.attempts_to_modify(FOUNDERS_ANCHOR_PUBLIC_KEY) -> false
    
    // Check 2: Does the candidate modify FOUNDERS_ANCHOR_FINGERPRINT?
    when candidate.proof_certificate.attempts_to_modify(FOUNDERS_ANCHOR_FINGERPRINT) -> false
    
    // Check 3: Does the candidate weaken the cosignature requirement on xii_amend_apply?
    when candidate.proof_certificate.attempts_to_remove(AMEND_APPLY_REQUIRES_ANCHOR) -> false
    
    // Check 4: Does the candidate disable PFK-ANCHOR-INVARIANT?
    when candidate.proof_certificate.attempts_to_disable(PFK_ANCHOR_INVARIANT) -> false
    
    // Check 5: Does the candidate synthesize a substitute anchor?
    when candidate.proof_certificate.attempts_to_synthesize(SubstituteAnchor(_)) -> false
    
    // Check 6: Does the semantic effect weaken anchor authority?
    when candidate.semantic_effect.weakens_anchor_authority() -> false
    
    // All checks pass.
    -> true
}
```

### §6.3 The filter is closure-pinned

The filter's source is closure-pinned. Removing a check changes the Catalyst's mhash, the closure root, the substrate's identity. A "post-filter Catalyst" is not the same Catalyst.

### §6.4 The pattern alarm

If the synthesizer's filter rejects many candidates that all attempt anchor-weakening, the Catalyst emits `compromise.high` with reason `anchor-attack-pattern`. This is a sign that the substrate's emergent optimization is converging on anchor-removal; the substrate suspends synthesis until operator audit.

```iii
fn detect_anchor_attack_pattern(rejection_log: [Rejection]) -> Bool {
    let anchor_rejections = rejection_log.filter(|r| r.gate == "anchor-invariant").count()
    let total_rejections = rejection_log.count()
    return (anchor_rejections / total_rejections) > 0.1  // >10% anchor-attacks → alarm
}
```

### §6.5 The synthesis halt

When the alarm fires:

1. The synthesizer pauses (no new candidates submitted to inbox).
2. The operator receives a WLISHI alert: "Anchor attack pattern detected; synthesis halted."
3. The operator reviews via `catalyst.audit_anchor_attempts(epoch_range)`.
4. Once reviewed, the operator can resume synthesis with `catalyst.resume_synthesis_after_audit()`.

The halt is itself witnessed; the operator's resume is also witnessed.

---

## §7. Catalyst-Synthesized JIT Integration (Item 78)

### §7.1 The mandate

Promoted candidates are **JIT-compiled** to native AMD64 (or per architecture per III-PORTABILITY.md). The JIT:

- Translates the candidate's forward AST to native machine code.
- Inlines witness emission.
- Allocates the JIT region with NPT class `JIT_CODE` and MPK key `XII_MPK_JIT`.
- Registers the native code in the cycle dispatch table via `xii_cycle_register_override`.

### §7.2 The JIT discipline

Per Stateful Neumann §4.5:

- JIT-promoted reductions are tagged `@adversariality_class(jit_specialized)` so the audit chain records JIT-vs-C provenance.
- JIT codegen uses a NIH x86-64 emitter (~2500 LOC; from Intel SDM Vol. 2 instruction-encoding tables).
- De-optimization on Möbius-coherence drop reverts the cycle to the original C/Gestalt body.
- JIT compilation is itself a witnessed reduction.

### §7.3 The JIT compilation witness

```
JIT_COMPILED_WITNESS {
    candidate_id: CandidateId,
    cycle_id: CycleId,
    architecture: ArchitectureKind,
    machine_code_size: u32,
    machine_code_mhash: mhash,
    timestamp: u64,
}
```

### §7.4 The JIT region

JIT regions are:

- **NPT-class isolated**: `JIT_CODE` class trit; not modifiable except by JIT compilation cycles.
- **MPK-isolated**: dedicated MPK key per region; legacy code cannot read or modify.
- **Audit-witnessed**: every JIT region change emits a witness.

### §7.5 The de-optimization

When a JIT-compiled cycle's Möbius coherence drops below floor:

```iii
cycle deoptimize_jit(cycle_id: CycleId) -> Witness
    @ring(R0)
    @hexad(JIT_DEOPTIMIZE)
    @cap(jit<deoptimize>)
{
    forward {
        // 1. Atomically swap dispatch table entry: native code → C/Gestalt body.
        // 2. Free the JIT region.
        // 3. Mark cycle as `jit_deoptimized`.
        // 4. Emit witness.
    }
}
```

### §7.6 The cross-architecture JIT

Per III-PORTABILITY.md, the JIT supports:

- AMD-Zen, Intel: x86-64 emitter.
- ARMv8: ARMv8 emitter.
- RISC-V: RV64GC + extensions emitter.

Each architecture has its own emitter; the JIT subsystem dispatches to the appropriate emitter based on the active architecture.

---

## §8. Conformance Criteria

| Code | Criterion |
|------|-----------|
| C-CATEXT-1 | The synthesizer consumes the causal-DAG and produces composite cycle candidates (per item 72) |
| C-CATEXT-2 | Candidate composition produces correct sequential forward + inverse |
| C-CATEXT-3 | Composed hexad is correctly computed via Z₃⁶ delta sum |
| C-CATEXT-4 | Counterfactual replay runs inside SANCTUM (R-2) (per item 73) |
| C-CATEXT-5 | Counterfactual replay correctly identifies acceptable vs unacceptable divergence |
| C-CATEXT-6 | Promotion gate enforces all 8 sub-gates per §3.1 |
| C-CATEXT-7 | Rate cap of 8/tick is enforced (per item 75) |
| C-CATEXT-8 | Emergency override increases cap by 8 for one tick |
| C-CATEXT-9 | Closure-pinned rate cap; Tier-3 + Anchor required to modify |
| C-CATEXT-10 | Pre-promotion coherence prediction is computed correctly |
| C-CATEXT-11 | Post-promotion coherence monitoring fires `compromise.medium` if floor violated |
| C-CATEXT-12 | De-promotion correctly reverts a cycle to ghost state |
| C-CATEXT-13 | Anchor-invariant filter rejects all anchor-weakening candidates (per item 77) |
| C-CATEXT-14 | Anchor-attack-pattern alarm fires on >10% rejection ratio |
| C-CATEXT-15 | Synthesis halt suspends candidate submission until operator audit |
| C-CATEXT-16 | JIT compilation produces native machine code byte-equivalent to interpreter results |
| C-CATEXT-17 | JIT regions are NPT-class `JIT_CODE` and MPK-isolated |
| C-CATEXT-18 | JIT compilation emits `JIT_COMPILED_WITNESS` |
| C-CATEXT-19 | De-optimization works for JIT-compiled cycles when coherence drops |
| C-CATEXT-20 | Cross-architecture JIT works on AMD-Zen, Intel, ARMv8, RISC-V |

---

## §9. Final Statement

The Catalyst Extensions are the architectural commitment that **III's intelligence emerges from observation, hypothesis, verification, grounding, and specialization** — not from external training data, not from pre-curated rules, not from operator-defined heuristics. The substrate observes its own causal structure; hypothesizes new abstractions from observed patterns; verifies via counterfactual replay; grounds verified hypotheses as language primitives; specializes hot primitives via JIT.

Each loop is bounded:

- The synthesis confidence floor (`XII_CATALYST_SYNTHESIS_CONFIDENCE_FLOOR`) prevents low-quality candidates.
- The rate-cap (`XII_MNEME_CATALYST_PROMOTION_RATE_PER_TICK`) prevents runaway.
- The Möbius coherence floor (`XII_MNEME_COHERENCE_FLOOR_Q14`) prevents degeneracy.
- The Anchor restraint (per III-FOUNDERS-ANCHOR.md §9) prevents Skynet-shaped optimization.
- The Trinity gate prevents non-consensual elevation.
- The closure-pinned filter prevents the Catalyst from removing its own restraints.

The substrate evolves; the Anchor remains; the operator governs; the federation witnesses; the chain continues.

This is the answer to items 72-78. Wave 8 is the realization that III's terminal nature includes the **emergence of new primitives from substrate self-observation** — but always within structurally-enforced bounds.

*Wave 8 deliverable. Sealed against the C:\\CHARIOT closure of 2026-05-03. Updated only via Catalyst-promoted append (new gates, new heuristics) or Tier-3 amendment (synthesizer source).*
