# III-CONFORMANCE.md — The 33 Conformance Criteria

**Document Identity:** B3 / The Conformance Contract / 33 Criteria
**Canonical Hash Slot:** R1.B3
**Version:** 1.0 — Final & Sealed
**Date:** 2026-05-03
**Authority:** Canonical. This is the **acceptance contract** for the entire system. A toolchain or implementation is *III-conformant* if and only if it satisfies all 30 criteria. Each criterion is testable via a corresponding entry in `TESTS/conformance/`.

---

## §0. Preamble — One Hundred Things, Reduced to Thirty-Three

A specification of III's depth could in principle define hundreds of conformance properties. The **minimal sufficient set** is thirty core criteria (C-1..C-30) — each necessary for III to be III; together they entail every other property — plus the three Resolution criteria (C-31..C-33) added by FROZEN SPEC III-RES-FROZEN-001 §14 (ADR-RES-011 / ADR-RES-006). **Thirty-three in total**, in lockstep with the final declaration in §6.

The criteria are organized into three groups:

- **Core Language (C-1 through C-15)** — properties of the language itself: lexer, grammar, types, effects, cycles, modules.
- **Substrate & Runtime (C-16 through C-25)** — properties of the runtime: IRPD, witnesses, ceiling, capabilities, sanctum, federation.
- **Cognitive Layer & Human Interface (C-26 through C-30)** — properties of the human-collaboration surface.

A conformant implementation passes every criterion. A failing implementation is non-conformant; non-conformance is grounds for refusing federation peering.

---

## §1. Core Language (C-1 through C-15)

### **C-1. Closure Root Determinism**

Closure roots are deterministic across clean builds. Two builds of the same canonical source on different machines produce byte-identical closure-root mhashes. Verified by `TESTS/conformance/closure_root_determinism.III`.

### **C-2. Phase-Polymorphism Soundness**

A `cycle` declared `@ring(R-2, R-1, R0, R3)` produces four distinct, correct lowerings. Each lowering's behavior matches the canonical semantic for that ring. Cross-ring marshalling preserves witness chain continuity. Verified by `TESTS/conformance/phase_poly_soundness.III`.

### **C-3. SID Inverse Round-Trip**

For every cycle kind in the cycle table, the SID-derived inverse round-trips: `r ⊕ (r ⟲)` reduces to the identity reduction (a `@pure` cycle whose forward is no-op and whose inverse is no-op). Verified by `TESTS/conformance/sid_round_trip.III` (negative tests for `@irreversible` cycles confirm the inverse is `Compromise<MEDIUM/LOW>` as declared).

### **C-4. Hexad Unrepresentability**

The six PFS bricking operations have no syntactic form. A negative-test corpus attempts each operation (as a hexad-tagged type, as a cycle declaration with the bricking hexad, as an IRPD method invocation). Each attempt is rejected at parse-or-type-check time with the appropriate `LEX-`, `PARSE-`, or `TYPE-` diagnostic. Verified by `TESTS/conformance/hexad_unrep.III`.

### **C-5. Sealed-Call Surface Match**

The Sanctum exposes exactly 10 sealed-call slots (slot 0 = INVALID + slots 1..9 functional). Attempts to dispatch to slot 10 or higher are rejected at parse time. Verified by `TESTS/conformance/sealed_call_surface.III`.

### **C-6. DRTM Quote Chain Verifiable**

Every DRTM quote in the chain back to epoch 0 verifies using only the III crypto primitives (SHA-256, BLAKE3, HMAC, HKDF, Ed25519, VDF), with no external dependency. Verified by `TESTS/conformance/drtm_chain_verify.III` running the verifier compiled `--ring R3`.

### **C-7. Closure-Pinned Imports**

A `use foo @closure(0xMHASH)` import refuses to load any module whose canonical mhash differs from the pinned value; the runtime emits `MOD-RES-001 closure mismatch`. Verified by `TESTS/conformance/closure_pin_drift.III`.

### **C-8. Möbius Coherence Floor Maintained**

Across a 1M-tick burn-in, the manifold's coherence Q14 never drops below the floor (currently 0.92q). If it would, the offending reduction is rejected via the Möbius-Trinity rule. Verified by `TESTS/conformance/coherence_burnin.III`.

### **C-9. Predictive Trinity Hot-Path Latency**

Predictive Trinity + PIP achieves <5-cycle hot-path latency on representative workloads (the standard CHARIOT VMRUN-loop sustained workload). Verified by `BENCHES/predictive_trinity_latency.III`.

### **C-10. Epistemic Escalation**

High-uncertainty operations (`U.confidence < 0.85q`) automatically trigger `reflect(uncertainty)` and full Layer-3 Trinity. Verified by `TESTS/conformance/epistemic_escalation.III`.

### **C-11. Ring-Gated Promotion**

Module changes are launched from Ring -2 if high-benefit / low-risk, Ring -1 if medium-risk, Ring 0/R3 only for pure user-level. Verified by `TESTS/conformance/ring_gated_promote.III` covering each combination of risk × benefit.

### **C-12. Codegen Validation Before Deployment**

Every dynamic deployment (Catalyst promotion, module fusion, name-resolution update) goes through codegen validation (compile + conformance suite + regression tests) before being applied. Verified by `TESTS/conformance/codegen_validation.III`.

### **C-13. Explicit Deployment Flags**

Every dynamic change emits one of `SAFE_APPROVED`, `SAFE_FLAGGED`, `UNSAFE_REJECTED`. The flag is part of the deployment witness and is operator-visible. Verified by `TESTS/conformance/deployment_flags.III`.

### **C-14. Ghost Effects + Witness Elision**

`@pure @witness_elide` cycles run at native speed (no runtime witness emission); the audit spine can later reconstruct the canonical witness on demand from the cycle's source closure root and recorded inputs. Verified by `TESTS/conformance/ghost_effects.III`.

### **C-15. Catalyst Promotions: Witnessed, Federated, Reversible**

Every Catalyst promotion emits `XII_STEP_KIND_MNEME_CATALYST_PROMOTE`, broadcasts to federation peers (per III-FEDERATION.md), and can be rolled back via `inverse.replay(promotion_witness)`. Verified by `TESTS/conformance/catalyst_promote_replay.III`.

---

## §2. Substrate & Runtime (C-16 through C-25)

### **C-16. IRPD-Only Privileged Writes**

Every privileged write in a conformant implementation goes through `irpd.<method>(...)`. A negative-test corpus attempts raw `WRMSR`, `MOV CR3`, `WRPKRU`, etc. outside IRPD; each is rejected at parse time. Verified by `TESTS/conformance/irpd_only.III`.

### **C-17. Witness Continuity Across All Rings and Module Boundaries**

Witness emission is continuous across all rings and across all module boundaries. The BCWL chain has no gaps, no orphan witnesses, no broken predecessor links. Verified by `TESTS/conformance/witness_continuity.III` over a 1-hour mixed-workload run.

### **C-18. Three-Layer Ceiling Never Bypassed**

SCBA + ACC + Trinity is never bypassed. Every reduction passes through the layered evaluation; even pure cycles pass Layer 1 (SCBA bit-test) — the bit is set at compile time but the test still runs. Verified by `TESTS/conformance/three_layer_always.III`.

### **C-19. Linear Capabilities Glyph-Bound, Drift-Detecting**

Every `Cap<P, R>` is consumed exactly once (linear). Every Cap's glyph identity is verified at use time; drift triggers `PANIC-GLYPH-DRIFT`. Verified by `TESTS/conformance/cap_linearity.III` + `TESTS/conformance/cap_drift_panic.III`.

### **C-20. Inverse Rings Consistent with Forward Rings**

The per-CPU inverse ring's content matches the forward ring's reverse-applicability. Walking the inverse ring backwards produces the inverse of every forward step, in order. Verified by `TESTS/conformance/inverse_ring_consistency.III`.

### **C-21. OBSERVATORY Saturation Thresholds Respected**

The Catalyst does not promote candidates whose OBSERVATORY accumulator has not reached saturation (Welford-stable + Hoeffding-bounded). Verified by `TESTS/conformance/observatory_saturation.III` (positive: saturated → promoted; negative: under-saturated → not promoted).

### **C-22. Phoenix Bookmark Round-Trip Byte-Exact**

A Phoenix bookmark created and immediately restored produces byte-exact equivalent state (same chain head, same per-CPU sanctum frame, same OBSERVATORY accumulators). Verified by `TESTS/conformance/phoenix_bookmark.III`.

### **C-23. DRTM Epoch Advancement VDF-Witnessed**

Every DRTM epoch advance carries a VDF witness with the correct number of squarings (default 2^20 between epochs). Verified by `TESTS/conformance/drtm_vdf.III`.

### **C-24. Sanctum Sealed Calls Trinity-Gated**

Every sealed-call dispatch is preceded by full Trinity evaluation. Reject paths emit `XII_STEP_KIND_SANCTUM_TRINITY_REJECT` and unwind via SID inverse. Verified by `TESTS/conformance/sanctum_trinity.III`.

### **C-25. Self-Hosting Compiler Runs as Ring -2 Sealed Call**

After Stage 4, recompilation of any III module is a `sanctum.compile_module` invocation (seal_id 9). The compiled artifact's closure root is verifiable against the spec root R1. Verified by `TESTS/conformance/self_host_compile.III`.

---

## §3. Cognitive Layer & Human Interface (C-26 through C-30)

### **C-26. Narrative Self Witnessed and Queryable**

Every module declares at most one `narrative` block. Every update emits `XII_STEP_KIND_NARRATIVE_SELF_UPDATE`. The Narrative Self is queryable via `narrative.self`, `narrative.update`, `narrative.reflect`. Verified by `TESTS/conformance/narrative_self.III`.

### **C-27. Cognitive Primitives are First-Class Productions**

`explain`, `propose`, `negotiate`, `commit`, `reflect`, `uncertainty` are language productions, not library calls. Each emits a witness in the cognitive band (`XII_STEP_KIND_COGNITIVE_*`). Verified by `TESTS/conformance/cognitive_primitives.III`.

### **C-28. Frontend Operates Without Module Knowledge**

The frontend can request any operation without operator knowledge of underlying modules. Name resolution discovers and dispatches automatically; the operator sees only the result. Verified by `TESTS/conformance/frontend_opacity.III`.

### **C-29. All User-Visible Actions Traceable to Witness Chain**

Every visible action (a frontend response, a Catalyst proposal, a federation broadcast) is traceable to a specific segment of the witness chain. The trace is reproducible from the chain alone. Verified by `TESTS/conformance/user_action_traceability.III`.

### **C-30. The System Can Be Queried by an Operator Who Knows Nothing**

The operator who knows nothing can pull up the frontend, ask a question in natural language, and receive a useful answer. The cognitive layer parses the question, dispatches the appropriate cycles, and explains the result. Verified by `TESTS/conformance/operator_zero_knowledge.III` running an end-to-end black-box scenario.

---

## §4. The Conformance Verifier

The verifier is `TOOLS/iii-conformance.III` — a `@ring(R3)` executable that:

1. Reads the spec root `R1` from the substrate's audit spine.
2. Loads `TESTS/conformance/*` as a single test corpus.
3. Runs each criterion's test against the substrate.
4. Reports per-criterion pass/fail/skipped + total compliance percentage.
5. If any criterion fails, returns non-zero exit code; the substrate is non-conformant.

The verifier itself is closure-pinned to a known mhash; running a different verifier produces a verifier mhash mismatch and is rejected.

---

## §5. Closure Identity Rule (R1.B3)

R1.B3 = `SHA-256(canonical_byte_form(this_file))`.

---

## §6. Final Declaration

**Thirty-three criteria. One acceptance contract.**

A toolchain that passes all 33 is III-conformant; it federates with peer III machines; its witnesses are accepted into the global audit spine. A toolchain that fails any one is non-conformant; it cannot peer; its witnesses are dropped at the federation gate.

**III-CONFORMANCE.md — the contract that defines what it means to be III.**

*Sealed. R1.B3 = SHA-256(canonical_byte_form(this_file)).*

---

## §7. Resolution Conformance Criteria (FROZEN SPEC III-RES-FROZEN-001)

Three criteria added by FROZEN SPEC §14, ADR-RES-011, ADR-RES-006.

### C-31. Resolution Determinism

**Criterion:** `quality_check_q7_resolution()` returns 1 on a healthy build:
- No FP, no clock, no random, no signed-i64 ordering, no unmasked u32→u64 ptr math, no u32 ptr stores in resolver source.
- `resolver_replay_check_chain()` byte-equal for every OK witness.
- Pattern registry sealed.
- `seal_resolver_verify()` byte-equal.

**Test:** corpus 46 (positive), corpus 47 (negative — injected corruption fails Q7).

### C-32. Pattern Compilation

**Criterion:** All registered patterns compile deterministically. `pattern_registry_seal_global()` succeeds; `pattern_register()` post-seal returns 0 unconditionally.

**Test:** corpus 37, corpus 44.

### C-33. Transform Pattern Equivalence Proof

**Criterion:** Each round-trip-reversible transform pair has a verified equivalence cert minted at boot. `proof_ripple_verify_pattern(cert, parent, child, witness)` returns 1 for every cert.

**Test:** corpus 49, T0028 round-trip bench (all reversible pairs byte-equal after FORM_X→FORM_Y→FORM_X).
