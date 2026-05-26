# III-GHOST-CODE.md — Ghost-Code-Until-Verified Discipline Architectural Mandate

**Document Identity:** GHOST-CODE / Architectural Mandate / Wave 4 / Items 63-71
**Status:** **DERIVATIVE — NOT part of the R1 sealed set, but architecturally binding on every Wave-4+ implementation.** This document specifies the ghost-code discipline: code that has been written but not yet *verified* against the R1-sealed semantic guarantees does not execute and does not enter the Reduction graph until verification completes.
**Version:** 1.0 — 2026-05-03 (Wave 4)
**Sources:** All 15 R1-sealed specs; III-PERFORMANCE.md; III-CRYPTO-AGILITY.md; III-FOUNDERS-ANCHOR.md; III-CYCLES (A5); III-MODULES (A10); III-CATALYST (B1).
**Cluster integrated:** items 63 (ghost-mode declarations), 64 (ghost-to-verified transition), 65 (SE compromise tier integration), 66 (verification gates), 67 (ghost-code emission ban), 68 (hexad classification), 69 (witness emission for transition), 70 (cap discipline for ghost-code consumers), 71 (closure-root impact).

---

## §0. Preamble — The Verification Window

Most software systems treat verification as a *pre-deployment* property: code is written, tested, possibly formally verified, and then deployed. Once deployed, the code is *trusted*; it can execute without further checks. Bugs and vulnerabilities are tolerated as the cost of operation.

III rejects this model. **Code is ghost until verified, and ghost code does not execute.** Specifically:

1. Code that lacks a complete proof certificate is **ghost**: it exists in the source, it can be observed by the substrate, but it cannot enter the Reduction graph or execute as a cycle.
2. Code that has a partial proof (e.g., proves termination but not totality, or proves type-correctness but not effect-soundness) is **partially ghost**: it can execute under restricted compromise tier (per III-CYCLES §5).
3. Code with a complete proof certificate transitions from ghost to **verified**: it enters the Reduction graph; it can execute at full tier; the transition itself is witnessed.
4. Code whose proof has been **revoked** (e.g., a proof kernel update found a counterexample) reverts to ghost; subsequent invocations cannot execute until re-verified.

This discipline is the architectural commitment that **III's Reduction graph contains only verified code**. The substrate's cryptographic identity (R1 composite root) is built upon the verified subset; ghost code is a separate region with its own audit chain extension.

This document specifies:

1. **§1** — The ghost-mode declaration syntax (item 63)
2. **§2** — The verification gate hierarchy (item 66)
3. **§3** — Ghost-to-verified transition (item 64)
4. **§4** — SE compromise tier integration for partially-verified code (item 65)
5. **§5** — Ghost-code emission ban (item 67)
6. **§6** — Hexad classification of ghost operations (item 68)
7. **§7** — Witness emission for transitions (item 69)
8. **§8** — Cap discipline for ghost-code consumers (item 70)
9. **§9** — Closure-root impact (item 71)
10. **§10** — Conformance criteria
11. **§11** — Final statement

---

## §1. The Ghost-Mode Declaration Syntax (Item 63)

### §1.1 The mandate

A cycle declaration may bear the `@ghost` modifier, declaring that the cycle's body is **ghost** until verification completes:

```iii
cycle process_request(req: Request) -> Response
    @ghost  // The body is ghost; no machine code is emitted; no execution.
    @ring(R0)
    @hexad(REQUEST_PROCESS)
{
    forward { /* Body declared but not yet verified. */ }
}
```

### §1.2 The implicit ghost

Code without an explicit `@ghost` annotation but lacking a proof certificate is **implicitly ghost**: the proof kernel does not yet have a verified proof; the cycle is in ghost state. This is the **default state** for newly written code.

### §1.3 The verified-by-construction class

Some cycles are **verified-by-construction** — their proof certificate is auto-derivable from their type (e.g., reading a `frozen` constant; identity reduction; pure functions over verified types). These bypass the ghost state and enter the Reduction graph immediately upon compile.

### §1.4 The verification-pending witness

When a cycle is in ghost state, the substrate may still emit a witness recording the ghost cycle's *existence*:

```iii
@ghost-state-witness {
    cycle_kind: GHOST_CYCLE_DECLARED,
    declaration_mhash: <hash of cycle source>,
    declaration_timestamp: <chronos>,
    expected_proof_obligations: [<prop1, prop2, ...>],
}
```

This allows the operator to audit which cycles are pending verification and which have been verified.

---

## §2. The Verification Gate Hierarchy (Item 66)

### §2.1 The gates

Verification proceeds through a **hierarchy of gates**. Each gate verifies a different class of property:

| Gate | Property Verified | Required for Transition |
|------|-------------------|-------------------------|
| Gate 1: Type-correctness | The cycle's body is well-typed per III-TYPES | Always |
| Gate 2: Hexad-admissibility | Every operation in the body has an admissible hexad per III-HEXAD | Always |
| Gate 3: Effect-soundness | The cycle's effects classify correctly per III-EFFECTS | Always |
| Gate 4: Termination | Forward and inverse always terminate | For non-`@compromise` cycles |
| Gate 5: Reversibility | Inverse correctly undoes forward (per III-CYCLES §5) | For non-`@irreversible` cycles |
| Gate 6: Witness-emission correctness | All required witnesses are emitted | Always |
| Gate 7: Cap discipline | Cap acquisition / release is correctly paired | For cap-bearing cycles |
| Gate 8: Trinity gating | Tier-3 operations correctly Trinity-gate | For Tier-3 cycles |
| Gate 9: Anchor-invariant preservation | Operation does not violate PFK-ANCHOR-INVARIANT | Always |
| Gate 10: Performance budget | Cycle hot-path meets §18.1 budget targets per III-PERFORMANCE.md | For hot-path cycles |
| Gate 11: Constant-time discipline | Cryptographic operations are constant-time | For crypto-touching cycles |
| Gate 12: Closure-root correctness | Cycle's source mhash is reproducible | Always |

### §2.2 Gate composition

Each gate produces a **partial proof certificate**. The complete proof certificate is the **composition** of all applicable gates. A cycle is fully verified only when every applicable gate has its partial certificate constructed.

### §2.3 The proof kernel as gate verifier

The proof kernel (per Stateful Neumann §4.1 / III-FOUNDERS-ANCHOR.md §10) verifies each gate. The kernel's source is closure-pinned; its rules are part of the substrate's R1 root. New gates can be added only via Tier-3 amendment + Anchor cosignature.

### §2.4 Per-gate witness

Each gate's verification emits a witness:

```
GATE_VERIFY_TYPE_CORRECTNESS
GATE_VERIFY_HEXAD_ADMISSIBILITY
GATE_VERIFY_EFFECT_SOUNDNESS
GATE_VERIFY_TERMINATION
GATE_VERIFY_REVERSIBILITY
GATE_VERIFY_WITNESS_EMISSION
GATE_VERIFY_CAP_DISCIPLINE
GATE_VERIFY_TRINITY_GATING
GATE_VERIFY_ANCHOR_INVARIANT
GATE_VERIFY_PERFORMANCE_BUDGET
GATE_VERIFY_CONSTANT_TIME
GATE_VERIFY_CLOSURE_ROOT
```

Each witness records the gate, the cycle being verified, and the partial certificate's mhash.

---

## §3. Ghost-to-Verified Transition (Item 64)

### §3.1 The mandate

When all applicable gates have produced their partial certificates, the cycle transitions from ghost to verified. The transition is itself a witnessed cycle:

```iii
cycle transition_ghost_to_verified(
    cycle_id: CycleId,
    proof_certificate: ProofCertificate
) -> Witness
    @ring(R0)
    @hexad(GHOST_TO_VERIFIED)
    @cap(verify<cycle_id>)
{
    forward {
        // 1. Verify proof_certificate is a complete certificate.
        // 2. Verify all required gates have partial certificates.
        // 3. Compose the certificates into the full proof.
        // 4. Mark the cycle as verified in the dispatch table.
        // 5. The cycle now becomes invocable.
    }
}
```

### §3.2 The transition witness

```
GHOST_TO_VERIFIED_WITNESS {
    cycle_kind: GHOST_TO_VERIFIED,
    cycle_being_verified: CycleId,
    composing_gate_witnesses: [WitnessId; N],
    proof_certificate_mhash: mhash,
    transition_timestamp: u64,
}
```

The witness chains all gate witnesses together; replay verifies the complete proof.

### §3.3 The atomicity

The transition is atomic: either all gates produce their partial certificates *and* the composition succeeds, or the cycle remains ghost. There is no "half-verified" state — that is the territory of compromise tiers (§4).

### §3.4 The wavefront integration

Multiple ghost cycles can transition to verified within a single wavefront. The wavefront's composed delta admits the batch transition; the rollback discipline applies (if any cycle's verification fails, the entire wavefront rolls back, including verifications that succeeded).

---

## §4. SE Compromise Tier Integration (Item 65)

### §4.1 The mandate

Some cycles cannot pass all gates — they have inherent imperfections (e.g., `@irreversible` operations whose inverse is `compromise.medium`). These cycles **enter the Reduction graph at a compromised tier**:

| Compromise Tier | Verification State |
|-----------------|--------------------|
| Verified (pristine) | All applicable gates pass |
| Compromise.LOW | Most gates pass; specific exceptions documented (e.g., `@irreversible` annotation) |
| Compromise.MEDIUM | Multiple gates fail or are deferred; cycle executes only under Trinity-gated operator consent |
| Compromise.HIGH | Critical gates fail; cycle is dispatchable but every invocation triggers a `compromise.high` witness |
| Ghost | Cannot execute; the dispatch table refuses the call |

### §4.2 The compromise classification

The proof kernel classifies each cycle's compromise tier based on which gates pass:

```iii
fn classify_compromise(passed_gates: Set<Gate>, total_gates: Set<Gate>) -> CompromiseTier {
    let critical_failed = total_gates - passed_gates - DEFERRABLE_GATES
    when critical_failed.contains(GATE_ANCHOR_INVARIANT) -> Ghost  // Never admit anchor violators.
    when critical_failed.contains(GATE_TYPE_CORRECTNESS) -> Ghost  // Never admit ill-typed.
    when critical_failed.contains(GATE_HEXAD_ADMISSIBILITY) -> Ghost  // Never admit unreachable.
    when critical_failed.size() == 0 -> Verified
    when critical_failed.size() == 1 && critical_failed.contains(GATE_REVERSIBILITY) -> Compromise.LOW
    when critical_failed.size() <= 2 -> Compromise.MEDIUM
    -> Compromise.HIGH
}
```

### §4.3 The dispatch

Each cycle's compromise tier is recorded in the dispatch table (per III-PERFORMANCE.md §9). Invocation:

- **Verified**: dispatched immediately, full speed.
- **Compromise.LOW**: dispatched immediately, witness includes `compromise.low` flag.
- **Compromise.MEDIUM**: dispatched only if cap-holder also holds `cap<execute_compromised<medium>>`; witness includes `compromise.medium` flag.
- **Compromise.HIGH**: dispatched only if cap-holder also holds `cap<execute_compromised<high>>` AND Trinity-gate convergence point passes; witness includes `compromise.high` flag.
- **Ghost**: dispatched never; the call returns `GHOST-NOT-EXECUTABLE` error.

### §4.4 The propagation

Compromise tiers propagate through cycle composition: a verified cycle that calls a compromise.medium cycle inherits the compromise.medium tier. The composed cycle's compromise tier is the **maximum** of any constituent's tier.

This propagation is computed by the proof kernel during composition; the resulting compromise tier is part of the composed cycle's proof certificate.

---

## §5. Ghost-Code Emission Ban (Item 67)

### §5.1 The mandate

Ghost code does **not** produce machine code in the compiled binary. The compiler:

- Lexes, parses, type-checks ghost cycles.
- Produces the partial AST and ghost-state witness records.
- **Does not** emit machine code for ghost cycle bodies.
- **Does not** allocate cycle-dispatch table slots for ghost cycles.

### §5.2 The implementation

The codegen path (per III-COMPILER §5) checks each cycle's verification state:

```iii
fn emit_cycle(cycle: Cycle) -> Bytes {
    when cycle.is_ghost() -> {
        // Emit only the ghost-state metadata; no machine code.
        emit_ghost_metadata(cycle)
    }
    -> {
        // Standard codegen.
        emit_machine_code(cycle)
    }
}
```

### §5.3 The runtime impact

A binary with ghost cycles is **smaller** than a binary with all cycles verified — by the size of the omitted machine code. The dispatch table size is also smaller (no slots for ghost cycles).

### §5.4 The substrate's audit visibility

Ghost cycles are visible to the operator via:

```iii
> system.observe.ghost_cycles(epoch_range: ...)
=> [
    { cycle_id: ..., declaration_mhash: ..., expected_gates: [...], pending_gates: [...] },
    ...
   ]
```

The operator can audit which cycles are still ghost and what verification work is needed.

---

## §6. Hexad Classification of Ghost Operations (Item 68)

### §6.1 The mandate

Ghost cycles' operations classify under specific hexads that signal their unverified state:

```
@hexad(GHOST_DECLARE) — declaration of a ghost cycle
@hexad(GHOST_TO_VERIFIED) — transition to verified
@hexad(GHOST_INVOCATION_REJECTED) — attempt to invoke a ghost cycle
@hexad(VERIFICATION_GATE_PASS) — a gate's partial certificate constructed
@hexad(VERIFICATION_GATE_FAIL) — a gate's partial certificate rejected
@hexad(COMPROMISE_TIER_CLASSIFY) — compromise tier classification result
```

### §6.2 The reachability

Each ghost-related hexad has explicit P1..P6 pillar values:

- `GHOST_DECLARE`: P1=POS (declaration is constructive), P2=ZERO (no immediate effect), P3=ZERO (no rollback yet), P4=POS (verification path exists), P5=ZERO, P6=ZERO. Reachability: ✓ admissible.
- `GHOST_TO_VERIFIED`: P1=POS, P2=POS (transitions state), P3=ZERO, P4=POS (verified state achieved), P5=POS (state durability), P6=POS (audit trail). Reachability: ✓ admissible.
- `GHOST_INVOCATION_REJECTED`: P1=ZERO (no execution), P2=POS (rejection effect), P3=ZERO, P4=ZERO, P5=ZERO, P6=POS (logged). Reachability: ✓ admissible.
- `VERIFICATION_GATE_PASS`: pillars all POS. Reachability: ✓ admissible.
- `VERIFICATION_GATE_FAIL`: P1=NEG, P2=NEG, P3=POS (recovery via re-verification), P4=ZERO. **Reachability: NEG-pillar present → operation classified as compromise.medium**. Failed verification is observable but the failed-state cycle does not enter the Reduction graph (it remains ghost).

---

## §7. Witness Emission for Transitions (Item 69)

### §7.1 The mandate

Every ghost-state transition emits a witness:

| Transition | Witness Kind | Trigger |
|-----------|--------------|---------|
| Source declared | `GHOST_DECLARE` | Compiler observes `@ghost` annotation |
| Gate 1 (type) verified | `GATE_VERIFY_TYPE_CORRECTNESS` | Type-checker emits partial certificate |
| Gate 2 (hexad) verified | `GATE_VERIFY_HEXAD_ADMISSIBILITY` | Hexad-checker emits partial certificate |
| ... (per gate) | `GATE_VERIFY_<GATE_NAME>` | Each gate's verifier |
| All gates verified | `GHOST_TO_VERIFIED` | Proof-kernel composes certificates |
| Compromise classified | `COMPROMISE_TIER_CLASSIFY` | Proof-kernel determines tier |
| Cycle invoked from ghost | `GHOST_INVOCATION_REJECTED` | Dispatcher rejects ghost call |
| Verified cycle invoked | (standard cycle witness) | Normal dispatch |
| Verification revoked | `VERIFICATION_REVOKED` | Proof-kernel discovers counterexample |
| Cycle reverts to ghost | `VERIFIED_TO_GHOST` | Revocation propagates to dispatch |

### §7.2 The witness chain integration

These witnesses chain into the standard audit chain (per III-CYCLES §6) and are themselves rollupable (per III-ZK-PRUNING.md), with the discipline that gate witnesses are NOT in the preservation list (they can be compressed).

### §7.3 The replay capability

The operator can replay the verification history of any cycle:

```iii
> system.observe.verification_history(cycle_id: ...)
=> [
    { gate: TYPE_CORRECTNESS, status: PASS, timestamp: ..., certificate_mhash: ... },
    { gate: HEXAD_ADMISSIBILITY, status: PASS, timestamp: ..., certificate_mhash: ... },
    { gate: TERMINATION, status: FAIL, timestamp: ..., reason: "non-terminating-loop-suspected" },
    { gate: TERMINATION, status: PASS, timestamp: ..., certificate_mhash: ... },  // After re-verification
    { transition: GHOST_TO_VERIFIED, timestamp: ..., proof_mhash: ... },
   ]
```

---

## §8. Cap Discipline for Ghost-Code Consumers (Item 70)

### §8.1 The mandate

Code that consumes ghost cycles' results requires a **special capability**:

```iii
cap<read_ghost_state<cycle_id>>  // Read ghost cycle's declaration without executing.
cap<verify<cycle_id>>             // Submit verification for a ghost cycle.
cap<execute_compromised<tier>>    // Execute a compromise.<tier> cycle.
```

### §8.2 The cap propagation

A function that calls a ghost cycle must hold `cap<verify<...>>` (to upgrade) or `cap<read_ghost_state<...>>` (to query). Without these, the call is rejected at compile time.

A function that calls a compromise.high cycle must hold `cap<execute_compromised<high>>`. The cap must be obtained via Trinity-gated operator consent.

### §8.3 The cap-graph integration

Caps for ghost-code operations integrate with the standard cap discipline (per III-EFFECTS / III-NEXUS). The cap graph records:

- Who holds `cap<verify<X>>` (verifiers).
- Who holds `cap<read_ghost_state<X>>` (auditors).
- Who holds `cap<execute_compromised<tier>>` (operators of degraded code).

### §8.4 The constitutional cap discipline

The cap `cap<execute_compromised<HIGH>>` is itself **Tier-3 + Anchor-cosignature-required** to grant. The operator must explicitly authorize each grant of this cap; it is not granted by default.

---

## §9. Closure-Root Impact (Item 71)

### §9.1 The mandate

Ghost code is **part of the closure root** — its source mhash contributes to the closure-root composition — but its **machine code does not** contribute. This is the architectural boundary:

- Closure-root contribution: ghost cycle's source code (canonical-form, AST), so the operator can audit which ghost cycles exist.
- No closure-root contribution: ghost cycle's machine code (because there isn't any).

### §9.2 The transition's closure-root impact

When a ghost cycle transitions to verified, its machine code is generated and **enters the closure root**. The closure root changes; this is a **closure-root mutation**.

Closure-root mutations are gated by:

- Tier-1 (transient): no gate.
- Tier-2 (host_file): operator approval via `module_load_amend`.
- Tier-3 (federation): Tier-3 amendment + Anchor cosignature.
- Tier-4 (constitutional): same.

For most cycles (Tier-1 or Tier-2), the closure-root mutation is operator-routine. For Tier-3+ cycles (constitutional), the Anchor cosignature is required.

### §9.3 The federation discipline

Federation peers must agree on the closure root. When a peer transitions a ghost cycle to verified, the peer:

1. Computes the new closure root including the verified cycle's machine code.
2. Federates the new closure root + the proof certificate.
3. Federation peers verify the proof certificate independently.
4. Each peer accepts or rejects the transition; only on quorum-acceptance does the federation's collective closure root advance.

This means **a peer cannot unilaterally promote ghost code to verified for the federation**. The federation collectively decides.

### §9.4 The Anchor's role

For constitutional cycles, the Anchor cosignature is required on the closure-root mutation. The Anchor's signature is itself a witness; it appears in the audit chain alongside the GHOST_TO_VERIFIED witness.

---

## §10. Conformance Criteria

| Code | Criterion |
|------|-----------|
| C-GHOST-1 | Cycles with `@ghost` annotation are not emitted as machine code (per item 67) |
| C-GHOST-2 | Implicitly-ghost cycles (no proof certificate) are not emitted as machine code |
| C-GHOST-3 | Verified-by-construction cycles (auto-derivable proofs) bypass ghost state |
| C-GHOST-4 | All 12 verification gates are implemented and verifiable |
| C-GHOST-5 | Each gate emits its partial certificate to the proof kernel |
| C-GHOST-6 | Composing all applicable partial certificates produces a complete proof |
| C-GHOST-7 | The transition `GHOST_TO_VERIFIED` is atomic; partial verification is not allowed |
| C-GHOST-8 | Compromise classification per §4.2 produces consistent results |
| C-GHOST-9 | Compromise tiers propagate through cycle composition (max-rule) |
| C-GHOST-10 | Ghost cycles are visible via `system.observe.ghost_cycles(...)` |
| C-GHOST-11 | Verification history is queryable via `system.observe.verification_history(...)` |
| C-GHOST-12 | Witnesses for verification gates and transitions are emitted per §7 |
| C-GHOST-13 | Ghost cycle invocation returns `GHOST-NOT-EXECUTABLE` error; not a crash |
| C-GHOST-14 | Compromise.medium cycle invocation requires `cap<execute_compromised<medium>>` |
| C-GHOST-15 | Compromise.high cycle invocation requires `cap<execute_compromised<high>>` + Trinity gate |
| C-GHOST-16 | Granting `cap<execute_compromised<HIGH>>` requires Tier-3 + Anchor cosignature |
| C-GHOST-17 | Ghost-cycle source mhash is part of the closure root |
| C-GHOST-18 | Verified-cycle machine code is part of the closure root |
| C-GHOST-19 | Federation peer closure-root mutation requires quorum + (for constitutional) Anchor cosignature |
| C-GHOST-20 | Verification revocation correctly reverts a verified cycle to ghost state |
| C-GHOST-21 | All `VERIFICATION_GATE_*` witnesses are queryable via `system.observe.verification_witnesses(...)` |
| C-GHOST-22 | Ghost-related hexads classify per §6.2 reachability rules |

---

## §11. Final Statement

Ghost-Code-Until-Verified is the architectural commitment that **III's executable Reduction graph contains only verified code**. The substrate's cryptographic identity (R1 root + closure root) is built on what has been proven; what has been written but not yet proven exists in source but does not run.

This discipline shifts the verification-vs-execution boundary into the substrate itself. The operator no longer needs to "trust the deployment process"; the deployment process *is* verification, and unverified code does not deploy.

Ghost cycles can be observed, audited, queried — but cannot execute. Verified cycles execute at full tier; partially-verified cycles execute under explicit compromise tier with cap-gated invocation; failed-verification cycles revert to ghost.

The Anchor's cosignature governs constitutional-tier transitions. The federation's quorum governs federation-wide transitions. The proof kernel governs everything.

This is the answer to items 63-71. Wave 4 is the realization that III's terminal nature requires that what runs in the substrate has been *categorically verified* — not just plausibly tested.

*Wave 4 deliverable. Sealed against the C:\\CHARIOT closure of 2026-05-03. Updated only via Catalyst-promoted append (new gates) or Tier-3 amendment (gate-hierarchy structure).*
