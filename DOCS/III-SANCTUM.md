# III-SANCTUM.md — Ring -2 Discipline

**Document Identity:** A8 / The Sanctum / Ring -2 as a First-Class Sovereign Manifold
**Canonical Hash Slot:** R1.A8
**Version:** 1.0 — Final & Sealed
**Date:** 2026-05-03
**Authority:** Canonical. This is the only Ring -2 discipline the SELF compiler may enforce. Without this discipline, Sanctum is either a dangerous black box or a useless mausoleum; with it, Sanctum is the most powerful, data-rich, low-latency computational resource the machine possesses.

---

## §0. Preamble — The Strategic Decision That Changes Everything

Most sovereign systems eventually hit the same wall:

> "We need Ring -2 power, but we refuse to rewrite UEFI or risk bricking the machine. So we either leave Ring -2 as a scary black box… or we accept massive latency and manual marshalling for every Ring -2 access, making the layer almost useless."

**III makes a different choice.**

III **refuses to touch firmware**. There is no UEFI rewrite. There is no capsule update. There is no microcode load. There is no BootOrder write. There is no real-NVRAM write. There is no ME/PSP mailbox. There is no SMRAM write. The six PFS bricking-class operations are **structurally absent** from the language (per III-HEXAD.md §4 — the Representability Theorem).

Instead, III makes Ring -2 (the Sanctum) a **fully accessible, high-performance, pattern-recognizing, crash-proof, zero-latency extension of the language itself**.

The Sanctum is no longer a hidden implementation detail. It becomes a **live, queryable, pattern-matchable, data-rich manifold** that the language can:

- Extract data from at near-native speed.
- Run pattern recognition on directly (inside the sanctum frame).
- Navigate complex structures inside without crashes (type system + hexad algebra make crashes structurally impossible from a well-typed sealed call).
- Ingest, analyze, and transport data upward with full provenance (zero-copy upward, witnessed at every step).
- Execute no-latency critical paths that boost the entire system (SRPA-specialized hot paths sub-5 cycles).

This is only possible because **III is Language-as-Operating-System** — the same source that runs at R3 can, with proper `@sanctum_only` typing and `sanctum_enter` blocks, execute inside Ring -2 with full type safety, witness emission, reversibility, and Catalyst-driven optimization.

This is the difference between treating Ring -2 as a dangerous black box and treating it as **the most powerful, data-rich, low-latency computational resource the machine possesses**.

---

## §1. The 9+1 Sealed Methods (Enumerated with seal_ids)

The Sanctum exposes **exactly ten sealed call slots**, numbered 0 through 9. Slot 0 is the structural-guard `INVALID` (never callable). Slots 1 through 8 are the original nine sealed methods. Slot 9 is the Stage-4-self-host method `compile_module`. There are no other slots; an eleventh requires a header change and a constitutional amendment.

### §1.1 The 10 Slots

| seal_id | Method | Purpose | Ring entry | @sanctum_only | Witness step_kind |
|---------|--------|---------|------------|---------------|-------------------|
| 0 | `INVALID` | Reserved — never callable; structural guard against off-by-one indexing. | — | — | `XII_STEP_KIND_SANCTUM_INVALID_REJECT` (emitted on any attempt to dispatch to slot 0) |
| 1 | `drtm_relaunch` | Perform full DRTM relaunch + new epoch. **The most powerful operation in III.** | R-1 | Yes | `XII_STEP_KIND_DRTM_RELAUNCH` |
| 2 | `pfs_var_set` | Set Phantom NVRAM variable (file-backed; never touches real NVRAM). | R-1 | Yes | `XII_STEP_KIND_PFS_VAR_SET` |
| 3 | `pfs_deny_quote` | Deny a DRTM quote (policy enforcement; future quote requests are rejected against the denied quote's chain). | R-1 | Yes | `XII_STEP_KIND_PFS_DENY_QUOTE` |
| 4 | `crcc_key_export` | Export a CRCC-derived key under the Sanctum sub-key. (CRCC = Cycle Root Closure Cryptographic key, the per-cycle derivation key for federated witness HMAC.) | R-1 | Yes | `XII_STEP_KIND_CRCC_KEY_EXPORT` |
| 5 | `phoenix_emergency` | Emergency Phoenix bookmark + state snapshot. (Phoenix = the rebirth-recovery checkpoint that survives a panicked unload.) | R-1 | Yes | `XII_STEP_KIND_PHOENIX_EMERGENCY` |
| 6 | `chronos_set_epoch` | Advance or set the witnessed-time epoch. (Chronos = the per-CPU TSC + VDF + chain-position tuple that defines "now" within the witness manifold.) | R-1 | Yes | `XII_STEP_KIND_CHRONOS_SET_EPOCH` |
| 7 | `compromise_quote` | Emit a compromise-class DRTM quote. (Used when the substrate detects an irreversible compromise and needs to broadcast an attested admission of it; tier-gated; constitutional.) | R-1 | Yes | `XII_STEP_KIND_COMPROMISE_QUOTE` |
| 8 | `phoenix_bookmark` | Create or restore a Phoenix bookmark (non-emergency). | R-1 | Yes | `XII_STEP_KIND_PHOENIX_BOOKMARK` |
| 9 | `compile_module` | Recompile a III module **inside** Sanctum (Stage 4 self-host). The compiler `telosc-σ` runs as a Ring -2 sealed call, producing a closure-rooted attested binary. | R-1 | Yes | `XII_STEP_KIND_SANCTUM_COMPILE_MODULE` |

**Total: 10 slots.** Adding an 11th requires:

1. A `mobius_candidate` declaring the new sealed-call body.
2. OBSERVATORY saturation showing the new sealed call is mathematically beneficial.
3. `amend.apply` at constitutional tier (`@tier(constitutional)`) — this is one of the rare invocations of constitutional amendment.
4. Federation-wide unanimous consent.
5. DRTM relaunch on every node.
6. A header bump in `INCLUDE/xii_sanctum_seals.h` (`XII_SANCTUM_SEAL_COUNT = 11`) and re-sealing of R1.A8.

### §1.2 The `@seal_id(N)` Annotation Rule

A function is dispatched to seal slot N by carrying the `@seal_id(N)` modifier:

```iii
fn drtm_relaunch_internal() @seal_id(1) @sanctum_only {
    // body of slot 1 — the actual DRTM relaunch
}
```

**Annotation rules:**

- `@seal_id(N)` is legal only on a `fn` (not a `cycle`) declared inside the special module `STDLIB/sanctum.III` — the only module that can register sealed-call bodies.
- `N` must be in `{0..9}` (inclusive). Higher values are rejected at parse time (`PARSE-SEAL-001 seal_id out of range`).
- `N = 0` is special: it is the structural-guard slot. The body is a fixed implementation that emits the `XII_STEP_KIND_SANCTUM_INVALID_REJECT` witness and returns a `Compromise<MEDIUM>` value. User code cannot register `@seal_id(0)`; the slot is bound at BOOT time.
- Each `seal_id(N)` for `N ∈ {1..9}` may be bound exactly once per closure root. Duplicate bindings are rejected with `TYPE-SEAL-002 seal_id collision`.

**The compiler enforces** that `@seal_id(N)` matches one of the ten defined slots. Adding an eleventh seal requires a header change (and is therefore witnessed and Trinity-gated).

---

## §2. `sanctum_enter |frame| { … }` Block Semantics

This is the **only syntactic form** that allows execution inside Ring -2. There is no other path; the type system rejects any other form of Ring -2 entry.

```iii
sanctum_enter |frame| {
    // @sanctum_active is now in scope
    sanctum.drtm_relaunch();
    phantom_nvram["XiiBootDecision"] = new_value;
    let key = sanctum.crcc_key_export();
}
```

### §2.1 Compiler-Generated Semantics — The 8-Step Sealed-Cycle Box

Every `sanctum_enter |frame| { ... }` block lowers to the 8-step **Sealed-Cycle Box**:

| Step | Action | Witness emitted |
|------|--------|------------------|
| 1 | **Mint Trinity-Gate intent token** under sanctum sub-key. The token is a 64-byte structure: 32 bytes of operator-consent mhash, 8 bytes of cap_id, 16 bytes of causality witness, 8 bytes of sanctum-frame ID. | (none yet) |
| 2 | Load the intent token into registers (`r10..r13`, per the Sanctum-Gate ABI). | (none yet) |
| 3 | Emit `XII_STEP_KIND_SANCTUM_INTENT_MINT` witness (records the intent token's mhash). | ✓ |
| 4 | Call `xii_sanctum_gate_enter` trampoline. The trampoline performs:<br>– `IBPB` (Indirect Branch Prediction Barrier): flushes branch-prediction history.<br>– `VERW`: invalidates speculative load-store buffers.<br>– `SSBD`: enables Speculative Store Bypass Disable.<br>– Rsp swap to per-CPU Sanctum stack.<br>– Save full GPR/FPR/XMM state to per-CPU save area.<br>This hardening prevents Spectre/Meltdown-class side-channel leaks across the sanctum boundary. | (none yet — still in trampoline) |
| 5 | **Per-CPU PKRU rewrite** to Sanctum key (the Memory Protection Keys discipline: only memory pages tagged with the Sanctum MPK are accessible from inside the sealed body). | (none yet) |
| 6 | **Dispatch by seal_id** — read the seal_id from the per-CPU dispatch register, look up the slot in the sanctum dispatch table (a 10-slot function pointer table), and call the slot's body. | `XII_STEP_KIND_SANCTUM_DISPATCH` |
| 7 | **Execute sealed body**. Every effect inside the body emits a full witness (per III-CYCLES.md §4). The frame binding `frame` is the per-CPU sanctum frame handle, which is passed to every IRPD call inside the body so that the call's witness records the frame_id. | one per body effect |
| 8 | **On exit**: emit post-witness, restore PKRU, restore GPR/FPR/XMM state, swap rsp back, return to the calling ring. | `XII_STEP_KIND_SANCTUM_EXIT` |

Each step is required; missing any step is a substrate-correctness bug (and is detected by the sealed-call audit at every chronos-tick).

### §2.2 Sanctum-Enter Judgment

```
Γ ⊢ block : StatementList
Γ ⊢ block requires @sanctum_active scope
Γ ⊢ trinity_admit(block) : Prop                                discharged at the entry site
─────────────────────────────                                       (Sanctum-Enter)
Γ ⊢ sanctum_enter |frame| { block } : Reduction<..., Phase=R-2>
```

The `frame` binding `IDENT` is **mandatory** even if unused (the grammar of III-GRAMMAR.bnf §7 requires it). For the unused-frame case, the binding is `_`:

```iii
sanctum_enter |_| {
    // body that does not reference the frame handle
}
```

### §2.3 Why the Trampoline Hardens

The four hardening steps inside the trampoline (IBPB, VERW, SSBD, RSP-swap, full GPR save) prevent:

- **Spectre v1/v2** — branch-target injection across the sanctum boundary, neutralized by IBPB.
- **MDS / RIDL** — speculative-load buffer leaks, neutralized by VERW.
- **SSB** — speculative-store-bypass leaks, neutralized by SSBD.
- **Stack-confusion attacks** — neutralized by the per-CPU Sanctum stack.
- **Register-leak attacks** — neutralized by the full GPR/FPR/XMM save.

This is **not optional**. The trampoline is hand-rolled in `BOOTSTRAP/sanctum_gate.S` (NIH-extreme: hand-written x86-64 assembly, no third-party speculation-mitigation library).

### §2.4 PKRU Discipline

The per-CPU PKRU rewrite at step 5 enforces that, while the sealed body executes, **only memory pages tagged with the Sanctum MPK key are accessible**. This means:

- The sealed body cannot accidentally read R3 user-mode memory (the MPK rewrite blocks it).
- The sealed body cannot accidentally read R0 driver memory (the MPK rewrite blocks it).
- The sealed body can only access Sanctum-tagged pages (Phantom NVRAM blob, sanctum frame, DRTM quote chain, etc.).

Step 8 restores the prior PKRU; the calling ring resumes its prior memory access discipline.

---

## §3. Trinity-Gate Prerequisites for Sealed Calls

Every sealed call is preceded by a full Trinity-Gate evaluation per III-TRINITY.md §1.3 Layer 3. The evaluation is:

```c
int xii_trinity_algebra_admit(
    uint8_t      seal_id,
    XiiIntent    operator_consent,        /* per-session, per-operator */
    XiiCap *     permission_cap,           /* the caller's capability binding */
    XiiWitness * causality_witness,        /* the current audit head */
    XiiSanctumFrame *current_sanctum_frame,
    /* out: */
    XiiConvergencePoint *out_convergence_point
);
```

If any of the four conjuncts (intent × cap × causality × sanctum-state) rejects, the call is **not dispatched**. An aborted-cycle witness is emitted (`XII_STEP_KIND_SANCTUM_TRINITY_REJECT`) and the frame unwinds via SID inverse — restoring any state mutations that occurred during the trampoline's pre-dispatch steps.

This is **non-negotiable**. Even `sanctum.drtm_relaunch()` — the most powerful operation in the substrate — is Trinity-gated.

---

## §4. DRTM-Relaunch — The Sovereign Reset

`drtm_relaunch()` is the **single most powerful sealed call**. It performs:

| Step | Action |
|------|--------|
| 1 | Perform a full Dynamic Root of Trust Measurement: hash all currently-mounted modules, the running cycle table, the current Phantom NVRAM state, the current OBSERVATORY schemas, the substrate's specification root R1, and the silicon fingerprint. |
| 2 | Generate a new epoch (increment the chronos epoch counter). |
| 3 | Re-anchor the Persistent Audit Spine (a new HMAC sub-key is derived for the new epoch; the new chain-head links to the prior epoch's last witness as its predecessor). |
| 4 | Re-derive all Sanctum sub-keys (HKDF from the new master sub-key with `info = "epoch=" || new_epoch`). |
| 5 | Emit a new DRTM quote — a 312-byte attested record containing: silicon fingerprint, R1 specification root, current cycle table mhash, hexad bitmap mhash, OBSERVATORY snapshot mhash, Phantom NVRAM mhash, federation member-list mhash, and the new epoch number. |
| 6 | Optionally promote the compiler — if the call carries `@promote_compiler`, the SELF compiler `telosc-σ` is migrated into the new Sanctum's sealed-call slot 9 (bound to the new closure root). |

### §4.1 Strategic Importance

Because III **refuses to rewrite UEFI**, `drtm_relaunch()` is **the only way to achieve a clean, attested, sovereign reset of the entire machine state — without ever touching firmware**.

It is the ultimate "I am the operating system and I can reboot myself into a new attested state" primitive. The relaunch:

- Does not write to real NVRAM.
- Does not load microcode.
- Does not change BootOrder.
- Does not modify SMRAM.
- Does not invoke ME/PSP.

It re-establishes trust *in software*, witnessed by the DRTM quote, federated to all peers, and binding for all subsequent operations in the new epoch.

### §4.2 What Survives a DRTM Relaunch

- The Phantom NVRAM file (signed, on the EFI System Partition).
- The cycle table (re-loaded from its closure-pinned form).
- The OBSERVATORY schemas (re-loaded with their accumulated saturation state).
- The federation peer list (re-loaded; peers re-attest each other in the new epoch).

### §4.3 What Does Not Survive

- Per-epoch HMAC sub-keys (rotated; old witnesses verify under their own epoch's keys).
- In-memory ERW caches (rebuilt from the persistent OBSERVATORY).
- Active sanctum frames (closed; per-CPU frames are re-established in the new epoch).
- The chronos VDF state (re-anchored at the new epoch's start; old VDF squarings remain witness-valid but the active count restarts).

### §4.4 What `drtm_relaunch` Does NOT Do

- It does **not** restart the host OS (Windows continues running normally; III is loaded as a driver and the relaunch is internal to the III substrate).
- It does **not** affect the user's running applications (R3 processes continue executing; their next Magic-MSR call enters the new Sanctum's sealed-call surface, which is the same `seal_id` set so the API is stable).
- It does **not** require user interaction (the operator's consent is present per Trinity admission of the relaunch invocation; no UI prompt is displayed during the relaunch).

---

## §5. The Sanctum as a Live Data Manifold (The Real Power)

This is where III becomes **truly unprecedented**. The Sanctum is not just 10 methods. It is a **rich, structured, queryable data manifold** containing:

| Data | Description |
|------|-------------|
| All Phantom NVRAM variables | Sealed key-value store, file-backed, per-key access controlled. |
| Current DRTM quote chain | Linked list of all DRTM quotes back to epoch 0 (the initial DRTM ceremony). |
| Phoenix bookmarks | Multiple generations of recovery checkpoints; can be restored individually. |
| Sanctum-data perturbation state | Per-allocation random padding for cache-side-channel resistance. |
| Per-CPU Sanctum frames | One frame per CPU, each carrying frame_id, save area, PKRU state. |
| Current epoch + VDF parameters | Chronos state: epoch counter, VDF squaring count, last-anchor witness. |
| Compiler closure root (after Stage 4) | The mhash of `telosc-σ`'s source — sealed as part of the Sanctum's stable identity. |
| Active policy | Denied quotes, approved capsule decisions (note: capsule *decisions*, not capsule *applications* — III decides whether to accept a hypothetical capsule for federation purposes, but never actually applies one). |

### §5.1 First-Class Access

III makes this entire manifold **first-class**:

```iii
sanctum_enter |frame| {
    let boot_decision = phantom_nvram["XiiBootDecision"];
    let current_epoch = drtm.epoch();
    let coherence = möbius.coherence();

    // Pattern recognition inside Sanctum
    let anomalies = sanctum.query_pattern(observatory.anomaly_detector);

    // Fast data extraction + upward transport
    let summary = explain(sanctum_state, detail = technical);
    narrative.update(summary);
}
```

Every line above is a first-class III statement with full type checking, witness emission, hexad admission, and Trinity dispatch. The "Sanctum as data" is not a side-channel; it is **typed program data** accessible through the cycle calculus.

### §5.2 Novel Invention 1 — Sanctum Pattern Recognition

The language can run **pattern-matching and anomaly detection directly inside Ring -2** on Sanctum state, then transport only the results upward (with full provenance).

```iii
sanctum_enter |frame| {
    // OBSERVATORY's anomaly detector is a Welford-bounded
    // time-series; queryable inside Sanctum
    let recent = witness_stream
        .where(w => w.adversariality_class == HIGH)
        .last(100);

    let anomaly_score = sanctum.classify(recent, observatory.anomaly_detector);

    // Branch on the result without ever leaving Sanctum
    if anomaly_score > 0.8q {
        sanctum.compromise_quote(anomaly_score, recent);
    }
}
```

**This enables no-latency critical-path decisions that would be impossible with round-trips to user mode.** A traditional system would have to: (1) extract Sanctum state to R0, (2) marshal R0 to R3, (3) run the classifier in user mode, (4) marshal result back to R0, (5) marshal R0 back to R-1, (6) re-enter Sanctum to act on the decision. That is *six* ring traversals. III does it in *zero* ring traversals — the entire decision happens inside Sanctum, with the result either acted upon directly or marshaled upward as a single witness with the conclusion.

### §5.3 Novel Invention 2 — Crash-Proof Address Navigation

All Sanctum memory accesses are typed through `Cap<...> @sanctum_only` with glyph-bound identity. **Invalid accesses are untypable**.

The discipline:

- Every Sanctum-resident data structure is exposed via a typed accessor cycle whose forward returns a `Cap<read | write, range> @sanctum_only`.
- The cap is glyph-bound: its glyph identity matches the registered glyph for the data structure. A drift (the data structure has been re-allocated or moved) is detected at runtime and panic-bailed before any pointer dereference.
- Out-of-range accesses are statically rejected: the type system enforces that every index expression `cap[i]` satisfies `i ∈ range`.
- Null-pointer dereferences are untypable: there is no null-pointer type in III; nullable values are expressed via `Option<T>` (an inductive type with a null variant that the type system requires the programmer to match).

The type system + hexad algebra make it **structurally impossible to crash the Sanctum from within a well-typed sealed call**. Every crash that *could* occur is rejected at type-check time.

### §5.4 Novel Invention 3 — Zero-Latency Upward Transportation

Data extracted inside `sanctum_enter` can be lifted into higher-ring types with a **single witnessed reduction**. No copying, no serialization — just a type-directed, zero-copy handoff with continuous witness chain.

```iii
sanctum_enter |frame| {
    let observation : Observation @ring(R-2) = sanctum.collect_observation();

    // Lift to R-1 in one witnessed reduction
    let observation_r1 : Observation @ring(R-1) = observation ⟴ R-1;

    // Lift further to R0 — still zero-copy if Glyph-bound
    let observation_r0 : Observation @ring(R0) = observation_r1 ⟴ R0;

    // Final lift to R3 — the witness chain is continuous all the way up
    let observation_r3 : Observation @ring(R3) = observation_r0 ⟴ R3;
}
```

For `Glyph`- or `Cap`-bound values, every `⟴` is a direct pointer handoff (per III-PHASES.md §4 Rule 1). The witness chain records each cross-ring transition with a continuous predecessor mhash. The result: **a value extracted from Sanctum can reach Ring 3 with zero copy and full audit**.

### §5.5 Novel Invention 4 — Predictive Sanctum Specialization (PIP + SRPA)

Hot sealed paths (e.g., frequent `pfs_var_set` or `phoenix_bookmark` from a specific cycle) are **automatically specialized by SRPA** into sub-5-cycle paths, while preserving full reversibility and auditability.

The mechanism:

1. SRPA observes that a given sealed call pattern is hot (high frequency, high cost from the marshalling overhead).
2. The Catalyst evaluates: can the sealed call's body be specialized? Are the inputs predictable? Is the inverse PIP-classifiable?
3. If yes, the Catalyst promotes a specialized lowering: the sealed body is JIT'd with the predicted inputs hard-coded; the marshalling is replaced with a fast-path pointer handoff; the inverse is pre-materialized as a STATIC_BYTES PIP blob.
4. Future calls dispatch to the specialized lowering, completing in 3–5 cycles total (vs. ~80 cycles for the canonical sanctum-gate-enter sequence).

The specialized lowering is still a sealed call — the trampoline still hardens, the PKRU still rewrites, the Trinity still admits. But the body itself is highly specialized, and the marshalling is reduced to a few register stores.

---

## §6. Why This Sanctum Discipline Is the Difference Between Dream and Reality

1. **Ring -2 becomes a first-class computational resource — not a black box.** Every operator can write III code that runs inside Sanctum, with full type safety and reversibility.
2. **Zero-latency critical paths.** Hot Sanctum operations run at native speed (sub-5 cycles after specialization), making Sanctum-resident logic competitive with R3 user-mode for hot paths *while remaining fully sealed*.
3. **Rich data extraction + pattern recognition.** The language can mine the Sanctum manifold directly — query DRTM quote chains, walk Phoenix bookmarks, classify witness sequences — all without leaving the seal.
4. **Crash-proof navigation.** The type system + hexads make invalid Sanctum accesses *impossible at compile time*. There are no Ring -2 NULL-deref panics.
5. **Seamless upward transportation.** Sanctum data flows into the rest of the system with full provenance, zero-copy when glyph-bound, witnessed continuously across rings.
6. **Self-hosting compiler in Ring -2.** After Stage 4, recompilation of any III module is a witnessed, attested Sanctum operation (`compile_module`, seal_id 9). The compiler's source is closure-pinned; recompiling produces a binary whose closure root is verifiable against the spec root R1.
7. **No firmware rewrite required.** Every property above is achieved purely through language design and the existing AMD-V SVM + Sanctum hardware features. The six PFS bricking-class operations are *structurally absent*.

**No other system in the world has ever made Ring -2 this accessible, this safe, this high-performance, and this data-rich — while refusing to touch firmware.**

---

## §7. Closure Identity Rule (R1.A8)

R1.A8 = `SHA-256(canonical_byte_form(this_file))`. Embedded in every compiled module's closure manifest, every DRTM quote, and the composite specification root R1.

---

## §8. Catalyst Extension Pathway

Adding a new sealed-call slot (an 11th method) requires **all** of:

1. A `mobius_candidate` declaring the method's body, with `@hexad(...)` admissibility and `@plan_anchor(SANCTUM_SEAL_<NEW_NAME>)`.
2. OBSERVATORY saturation showing the new sealed call is mathematically beneficial (Welford-stable, Hoeffding-bounded, chronos-tick-observed).
3. `amend.apply` at constitutional tier — this is one of the rare invocations of constitutional amendment.
4. Federation-wide *unanimous* consent (not just quorum).
5. DRTM relaunch on every node in the federation.
6. A header bump in `INCLUDE/xii_sanctum_seals.h` (`XII_SANCTUM_SEAL_COUNT = 11`) and re-sealing of R1.A8.

Removing a slot is **not** allowed. Reassigning an existing slot's body to a different operation is **not** allowed (it would invalidate every prior sealed-call witness in the chain).

---

## §9. Conformance Criteria

- **C-SAN-1.** Exactly 10 sealed-call slots are exposed (slot 0 INVALID + slots 1–9 functional). C-5 in III-CONFORMANCE.md.
- **C-SAN-2.** Every `sanctum_enter` block lowers to the 8-step Sealed-Cycle Box exactly as in §2.1, including IBPB+VERW+SSBD hardening.
- **C-SAN-3.** Every sealed call is preceded by a full Trinity-Gate evaluation (§3); rejection emits an aborted-cycle witness.
- **C-SAN-4.** `drtm_relaunch()` produces a 312-byte DRTM quote whose chain back to epoch 0 verifies against the OBSERVATORY's quote-chain schema.
- **C-SAN-5.** Sanctum memory accesses through `Cap<...> @sanctum_only` cannot cause crashes (verified by extensive negative-test corpus).
- **C-SAN-6.** Predictive Sanctum specialization (§5.5) achieves sub-5-cycle hot-path latency on representative workloads.
- **C-SAN-NIH.** The sanctum trampoline is hand-written x86-64 assembly with no third-party hardening library.

---

## §10. Final Declaration

The Sanctum is not a hidden implementation detail.
The Sanctum is not a dangerous black box.
The Sanctum is **a live, sovereign, pattern-rich, zero-latency computational manifold** — and III makes it a first-class citizen of the language.

**III-SANCTUM.md — the Ring -2 discipline that turns the most privileged layer into the most useful one.**

*Sealed against the C:\\CHARIOT closure of 2026-05-03. R1.A8 = SHA-256(canonical_byte_form(this_file)).*
