# III-MODULES.md — The Module & Complementarity System

**Document Identity:** A10 / The Module System / Safety-First Revision
**Canonical Hash Slot:** R1.A10
**Version:** 1.1 — Final & Sealed (Safety-First Revision)
**Date:** 2026-05-03
**Authority:** Canonical. This is the only module and name-resolution discipline the SELF compiler may implement.

---

## §0. Preamble — Radical Ambition with Radical Safety

In every other programming language and operating system on Earth, modules are **barriers**:

- Separate compilation units with manual import / export lists.
- ABI contracts that must be maintained by humans.
- Version numbers that drift.
- Name resolution that is essentially string lookup with caching.
- Inter-module calls slower than intra-module calls (call-site indirection, ABI marshalling, optimization barriers).
- The user must understand the architecture to get anything done.

**III destroys this model — but does so under a rigorous safety discipline.**

In III, modules are not files. Modules are **live, witnessed, self-complementing nodes in the Möbius manifold**. The entire substrate — every `.III` file, every cycle, every abstraction, every OBSERVATORY schema, every Catalyst promotion — is designed so that any two parts are **perfectly complementary**. The first file is as complementary to the 37th as it is to the last. The system automatically discovers, optimizes, and specializes the most efficient path between any two points.

But — and this is the safety-first revision over the prior draft — every dynamic change (module promotion, fusion, name-resolution decision, complementarity optimization) **must pass through codegen validation** and be **launched from Ring -2 if beneficial, or Ring -1 if not**. Every change emits an explicit deployment flag (`SAFE_APPROVED` / `SAFE_FLAGGED` / `UNSAFE_REJECTED`). Even a *semantically wrong* fix is **structurally safe** by construction (hexad-admitted, ceiling-admitted, Möbius-coherent, witnessed, reversible) and explicitly flagged so the operator can review.

This is the difference between a brilliant-but-potentially-unstable self-evolving system and a brilliant, self-evolving, **auditable, and safe** sovereign substrate.

---

## §1. Modules as Content-Addressed Witnessed Nodes

### §1.1 Module Declaration

```iii
module hv.msr_cmd
    @closure(0x7a3f…a1b2c3d4e5f6)         // SHA-256 of canonical source
    @ring(R-1, R0)
    @plan_anchor(HV_VMEXIT)
    @version("1.0")
```

### §1.2 The Module Identity Judgment

```
Γ ⊢ m : Module
Γ ⊢ closure_root(m) = SHA-256(canonical_source(m))
─────────────────────────────                                       (Module-Identity)
Γ ⊢ m is uniquely identified by its closure root
```

Every module's identity **is** its closure root. Two modules with the same closure root are *the same module* (even across federation peers, even across machines, even across decades). This eliminates:

- **Version drift** — two implementations claiming "version 1.0" but with different bodies are *different modules* with different closure roots.
- **ABI mismatches** — the closure root captures the entire canonical surface; an ABI change changes the root.
- **"Works on my machine"** — the closure root is computed identically on every machine; if your machine produces a different root, your source is non-canonical (and `iii-fmt` will repair it).

### §1.3 Module Manifest

Every compiled module produces a **closure manifest** — a JSON-like structure (canonicalized for hashing) listing:

- `closure_root` — the module's mhash.
- `canonical_source_mhash` — the source mhash (without included module bodies).
- `r1_specification_root` — the R1 mhash this module was compiled against.
- `r1_a1` through `r1_idx` — the per-spec R1 family hashes.
- `imports` — list of `(qualified_name, closure_pin)` pairs.
- `exports` — list of exported items with their per-item mhashes.
- `cycle_table_contributions` — list of `XII_STEP_KIND_*` allocations.
- `hexad_table_contributions` — list of dynamic-hexad reservations (if any).
- `proof_certificates` — list of per-cycle proof certificate mhashes.
- `signature` — Ed25519 signature over the manifest by the operator's signing key.

The manifest is appended to every binary artifact (R3 EXE/DLL, R0 .sys, R-1 .efi-blob, R-2 sealed-object) in a dedicated section (`.iii_manifest`).

---

## §2. Name Resolution as Mathematical Discovery (Not Lookup)

When you write:

```iii
use hv.msr_cmd.read_msr;
```

The compiler **does not perform string lookup**. Instead, it performs **mathematical discovery**:

1. Compute the closure root of the requested module path.
2. Ask the OBSERVATORY for all known modules with that closure root.
3. Select the one with the highest Möbius coherence × performance fingerprint (via SRPA).
4. If none exists, ask the Catalyst to discover or synthesize one.
5. Register the import as a witnessed `Reduction`.

### §2.1 The Name-Resolution Judgment

```
Γ ⊢ requested = "hv.msr_cmd.read_msr"
Γ ⊢ candidates = observatory.modules_with_closure(requested)
Γ ⊢ best = argmax(candidates, möbius_coherence × performance)
Γ ⊢ best exists ∧ best.closure_root verifies against the import's @closure pin (if present)
─────────────────────────────                                       (Name-Resolution)
Γ ⊢ read_msr : Cycle<...>          — resolved to best candidate
```

If the best candidate is not yet in the local manifold, the Catalyst can **pull it from federation** (via III-FEDERATION.md §1) or **synthesize it via mathematical abstraction** (a `mobius_candidate` whose body is generated from observed-pattern saturation in OBSERVATORY) — all witnessed.

### §2.2 Closure-Pin Discipline

When an import carries `@closure(mhash)`:

```iii
use crypto.sha256 @closure(0x7a3f…);
```

The resolver **refuses to load** any module whose canonical mhash differs from the pinned value. A drift produces `MOD-RES-001 closure mismatch`. This is the first-line defense against supply-chain compromise: a malicious replacement of a module body changes its closure root, which fails the pin.

### §2.3 Name Collision

If two modules in the local manifold have the same `qualified_name` but different closure roots (a *content-divergent* same-name pair), the resolver chooses the higher-coherence one and emits a warning. The operator can pin via `@closure` to disambiguate.

This is structurally different from C / Rust / Java module systems where same-name collisions are *errors*. In III they are **opportunities** — the system observes that two implementations of the same logical module exist and tracks them; the resolver picks the better one; the loser is preserved for fallback or audit.

---

## §3. Structured Transmission Between Modules (Low / Negative Overhead)

Cross-module calls are **first-class witnessed reductions** with automatic zero-copy when possible.

```iii
let result = hv.msr_cmd.read_msr(0xC000_0080);
```

### §3.1 Transmission Rules

**Rule 1 — Glyph-Bound Zero-Copy.** If the argument is a `Glyph` or `Cap<...>` with matching glyph identity, the compiler emits a **direct handoff** (no copy). The witness chain is continuous.

**Rule 2 — Predictive Specialization (PIP + SRPA).** Hot cross-module paths are automatically specialized into native cycles (sub-5-cycle latency). A well-specialized cross-module call can be **faster than a generic intra-module call** because the Catalyst and SRPA have *more* optimization surface across module boundaries (they can choose to inline, fuse, or specialize across what was historically a barrier).

**Rule 3 — Epistemic Transmission.** If the argument carries `Uncertainty<...>`, the receiving module inherits the epistemic state. High-uncertainty data triggers automatic `reflect` / `negotiate`.

**Rule 4 — Möbius Transmission.** Every cross-module call updates the global manifold coherence metric. The system prefers paths that **increase** coherence; if a cross-module path would decrease coherence below floor, the Catalyst proposes a fix (per §5).

**Rule 5 — Tier-Gated.** Outbound cross-module calls respect tier boundaries (per III-FEDERATION.md §1). A `@tier(transient)` call cannot transmit `@tier(constitutional)` data without explicit `amend.apply`.

**Result:** Structured transmission is **not overhead. It is an optimization opportunity.**

### §3.2 What This Means for Performance

A traditional cross-module call carries: indirection through a function-pointer table, ABI marshalling (register-saving, calling convention), optimization barrier, possibly a TLB miss on the call target's code page. ~30–80 cycles overhead in the best case.

An III specialized cross-module call: direct branch to inlined code (the Catalyst has fused the call at compile time), zero-copy glyph handoff, witness emission inlined as 2–3 instructions. **3–5 cycles total** on a hot path. The witness chain remains continuous; the caller-callee relationship is recorded in the predecessor mhash linkage.

---

## §4. The Complementarity Principle (The Heart of the Vision)

### §4.1 Definition

**Two modules** (or any two nodes in the substrate) **are perfectly complementary** if there exists a witnessed reduction path between them whose:

1. **Composed hexad is admissible** (in `xii_asym_reach6`).
2. **Möbius coherence is non-decreasing** along the path.
3. **Performance fingerprint is within 5%** of the theoretical minimum given current hardware.

### §4.2 The Substrate Invariant

The entire system (every file, every cycle, every abstraction) is designed and continuously optimized so that **complementarity holds between any pair of nodes**:

- File 1 is as complementary to File 2 as it is to File 37 as it is to File 1,000.
- The system automatically discovers and specializes the best path between any two points.
- When complementarity would be violated, the Catalyst proposes a fix (a new abstraction, a new specialization, or a new module fusion).

This is enforced at the type level (the `Complementary<m1, m2>` Prop, computed by the proof kernel for any pair) and continuously improved at runtime (via the Catalyst's complementarity scanner).

### §4.3 What This Buys

- **Maximal coherence despite arbitrary complexity.** The substrate can grow to 10,000 modules and remain a single coherent manifold; complementarity is preserved.
- **Maximal user simplicity.** The user does not need to understand which module they are calling — they ask the frontend, the resolver picks the best path, and the call completes.
- **Maximal system efficiency.** The system works only as hard as physics demands; complementary paths are specialized, non-complementary paths are repaired before they bottleneck.

---

## §5. Ring-Gated Module Loading & Promotion (Safety-First)

### §5.1 The Core Safety Rule

**Any** module loading, name-resolution decision, fusion proposal, or complementarity optimization is **launched from a specific ring** based on its risk/benefit profile:

- **Ring -2 (Sanctum)** — if the change is **high-benefit / low-risk** (e.g., hot-path specialization of a well-understood cycle, fusion of two cycles whose interaction has been observed to be Möbius-coherent for ≥1M ticks).
- **Ring -1 (Hypervisor)** — if the change is **medium-risk** or involves constitutional / policy modules.
- **Ring 0 or R3** — only for **pure user-level modules with no system impact** (e.g., a R3 utility module's fusion).

### §5.2 The Ring-Gated Promotion Judgment

```
Γ ⊢ proposed_change : ModuleChange
Γ ⊢ risk = classify_risk(proposed_change) ∈ {LOW, MEDIUM, HIGH}
Γ ⊢ benefit = estimate_benefit(proposed_change) ∈ {LOW, MEDIUM, HIGH}
─────────────────────────────                                       (Ring-Gated)
if benefit ≥ HIGH ∧ risk ≤ LOW:
    launch from Ring -2 (sanctum_enter |frame| { apply(proposed_change) })
elif benefit ≥ MEDIUM ∧ risk ≤ MEDIUM:
    launch from Ring -1 (vmrun-trampoline + IRPD path)
elif risk ≤ LOW ∧ benefit ≥ LOW:
    launch from Ring 0 (driver-level apply)
else:
    reject_for_human_review;  emit XII_STEP_KIND_MOD_PROMOTE_REJECT
```

This ensures the most powerful and safest layer (Ring -2) handles the highest-value changes, while still allowing controlled evolution from Ring -1 when necessary, and rejecting changes that don't meet the risk/benefit bar.

---

## §6. Codegen-First Validation Before Any Deployment

### §6.1 The Core Safety Mechanism

Before any dynamic module change (fusion, promotion, new name resolution, complementarity optimization) is applied, the system **must**:

1. **Generate** the proposed change as a new III module (or a patch to an existing module).
2. **Compile** it via the SELF compiler (`telosc-σ` in Ring -2 when possible — using sealed-call slot 9 `compile_module` per III-SANCTUM.md §1).
3. **Run** the full conformance suite (C-1..C-30 from III-CONFORMANCE.md) plus targeted regression tests against the proposed change.
4. **Emit** a deployment flag:

   - `SAFE_APPROVED` — passed all checks; structurally safe; semantic behavior matches baseline expectation.
   - `SAFE_FLAGGED` — passed structural checks; semantic behavior **differs** from baseline (human review recommended); deployed with operator-visible flag.
   - `UNSAFE_REJECTED` — failed structural invariants (hexad unrepresentable, ceiling violation, coherence collapse, Trinity unadmissible); **never** deployed.

### §6.2 The "Always Safe" Guarantee

Even if the proposed fix is semantically wrong, it is **guaranteed** to be structurally safe:

- Hexad-admitted (`xii_asym_reach6` lookup passed).
- Ceiling-admitted (post-state in constitutional manifest).
- Möbius-coherent (post-state coherence ≥ floor).
- Fully witnessed and reversible.
- Structurally valid (no bricking, no invariant violation).

If it is *semantically* wrong, it is then **explicitly flagged** (`SAFE_FLAGGED`) so the operator knows to review it. If the operator rejects, the change is reversed via inverse ring (the deployment is itself a reversible reduction).

This is the **"iron out the rough spot before auto-proceeding" mechanism**: the system can attempt fixes aggressively, and even wrong fixes do not damage the substrate — they are only flagged and reversible.

### §6.3 Why Ring -2 Is Preferred for Validation

Codegen validation in Ring -2 has three advantages:

1. **Sealed compilation environment.** The `compile_module` sealed call runs in PKRU-isolated memory; no external code can perturb the compilation.
2. **Closure-rooted output.** The compiled artifact's manifest is sealed against R1; verification is straightforward.
3. **Low-latency feedback.** SRPA can specialize the recompile-and-verify path; sub-5-cycle dispatch from substrate to Sanctum compile.

For changes that don't merit Ring -2's overhead (a simple R3 utility-module fusion), Ring -1 validation is used instead — slightly slower but still sealed in IRPD-discipline.

---

## §7. Name Resolution (Still Mathematical, Now Safer)

Name resolution remains mathematical discovery via OBSERVATORY + Catalyst, but every decision is now:

1. **Proposed** as a `ModuleChange`.
2. **Validated** via codegen (Ring -2 or Ring -1).
3. **Flagged** upon deployment.

```iii
use hv.msr_cmd.read_msr;        // triggers safe, validated resolution
```

If the best candidate changes (e.g., a higher-coherence version appears in OBSERVATORY), the system **proposes** the update, **validates** it via codegen, and **only applies** it after the flag is reviewed (or auto-applies if `SAFE_APPROVED` and the change is low-risk).

---

## §8. Structured Transmission (Still Low/Negative Overhead, Now Gated)

Cross-module calls remain zero-copy + witnessed when possible, but:

- Hot, well-validated paths are specialized via SRPA + PIP (Ring -2 promoted when beneficial).
- Risky or unvalidated paths fall back to full witnessed marshalling from Ring -1.
- Every transmission carries an **epistemic flag** so high-uncertainty data triggers extra scrutiny.

---

## §9. Complementarity Principle (Still the Goal, Now Auditable)

The substrate still strives for perfect complementarity between every pair of nodes, but:

- Complementarity optimizations are now **proposed changes**, not automatic.
- Every proposal goes through codegen validation + Ring-gated deployment.
- The system maintains an **auditable log** (the Persistent Audit Spine) of all complementarity decisions and their flags.

This preserves the vision of a maximally coherent substrate while making every step **reviewable** and **safe**.

---

## §10. Dynamic Module Fusion (Möbius Module Evolution, Safety-First)

Modules can fuse at runtime when the Catalyst detects high complementarity:

```iii
mobius_candidate fuse_msr_npt(
    msr_idx: u32, npt_gpa: u64
) -> Result @candidate_for_promotion @hexad(MSR_NPT_FUSED) {
    forward {
        if catalyst.observe(interaction.msr_npt).hot {
            promote { fused_msr_npt_cycle(msr_idx, npt_gpa) };
        }
    }
}
```

When promoted (with codegen validation passing and ring-gated deployment), the two modules effectively become **one higher-performance node** in the manifold:

- The original modules **remain** in the table for auditability (per the append-only invariant of III-CYCLES.md §5.1 invariant 7).
- The fused version is **preferred** for execution; the resolver dispatches there.
- Both are **witnessed** at the fusion event; the rollback path (inverse) restores dispatch to the original modules.

This is how the system achieves **maximal efficiency despite complexity** — it continuously collapses high-interaction boundaries, *safely*.

---

## §11. User-Facing Simplicity (The Frontend That Hides Everything)

The user who knows nothing interacts with a single frontend:

```text
> "I need to read MSR 0xC000_0080 and also check the current NPT entry for address 0xdeadbeef"

III: "Resolved via hv.msr_cmd.read_msr (specialized) + hv.npt.query
     (fused with MSR for this workload). Validated SAFE_APPROVED.

     Result: 0x00000001 (MSR), 0x800000003fe00087 (NPT).

     Note: A higher-coherence fused version was proposed (msr_npt_v2,
     coherence Q14=0.97 vs current 0.94). Proposed change validated,
     flagged SAFE_APPROVED, ready for deployment.

     Deploy now? (y/n)"
```

Behind the scenes:

- **Name resolution** discovered the best modules.
- **Complementarity analysis** selected the fused path.
- **Predictive Trinity + PIP** made it near-zero overhead.
- **Codegen validation** verified the proposed update.
- **Ring-gating** chose the appropriate validation ring.
- **Full witness chain** was emitted for audit.
- The user saw only the result and the safe-approved deployment proposal.

**The system works only as hard as physics demands.** Everything else (discovery, optimization, fusion, witnessing, validation, flagging) happens in the background with near-zero cost on hot paths.

---

## §12. Why This Module System Humiliates Every Other Attempt

1. **Modules are not barriers** — they are opportunities for automatic optimization and fusion.
2. **Name resolution is mathematical discovery**, not string lookup.
3. **Inter-module calls can have negative overhead** via specialization.
4. **Perfect complementarity** is an invariant of the entire substrate.
5. **The user sees nothing** — they just ask and receive.
6. **The system improves itself** — Catalyst-driven fusion and promotion.
7. **Every file is complementary to every other file** — maximal coherence despite arbitrary complexity.
8. **Every dynamic change is safe by construction** — codegen-validated, Ring-gated, flagged.
9. **Even wrong fixes are reversible** — the deployment is a reduction with an inverse.
10. **No silent extensions** — every change emits a witness, federates, and has an explicit flag.

No other language or operating system has ever attempted this — and no other system ever will, because no other system has a witnessed manifold, an OBSERVATORY of mathematical abstractions, a Möbius Catalyst, a type system enforcing complementarity, codegen-validation as a deployment gate, ring-gated launch decision-making, and a constitutional ceiling.

---

## §13. Closure Identity Rule (R1.A10)

R1.A10 = `SHA-256(canonical_byte_form(this_file))`. Embedded in every compiled module's closure manifest and in the composite specification root R1.

---

## §14. Catalyst Extension Pathway

Module-system extensions (new module-attribute kinds, new fusion strategies, new complementarity metrics) follow the standard Catalyst pathway (III-CATALYST.md §2). Two restrictions:

1. The closure-root mechanism is constitutional (changes require `amend.apply`).
2. The Ring-gating decision tree (§5.2) is constitutional (changes require `amend.apply` because they affect substrate-wide trust assumptions).

---

## §15. Conformance Criteria

- **C-MOD-1.** Every module has a closure root computed deterministically. C-1 in III-CONFORMANCE.md.
- **C-MOD-2.** Closure-pinned imports are enforced; mismatch = runtime failure. C-7.
- **C-MOD-3.** Cross-module calls preserve witness chain continuity.
- **C-MOD-4.** Ring-gated promotion follows §5.2's decision tree exactly. C-11.
- **C-MOD-5.** Codegen validation runs before any dynamic deployment. C-12.
- **C-MOD-6.** Deployment flags (`SAFE_APPROVED` / `SAFE_FLAGGED` / `UNSAFE_REJECTED`) are emitted for every dynamic change. C-13.
- **C-MOD-7.** Module fusion preserves the original modules in the cycle table for auditability.
- **C-MOD-8.** Frontend can request operations without operator knowledge of underlying modules. C-28.

---

## §16. Final Declaration

Modules are still living nodes in a single sovereign manifold.
Name resolution is still mathematical discovery.
Complementarity is still the invariant.

But now every step of evolution is **validated by codegen**, **launched from Ring -2 when beneficial or Ring -1 when not**, and **explicitly flagged upon deployment** — so the system can improve itself aggressively while remaining **safe**, **auditable**, and **never scary**.

**III-MODULES.md (Safety-First Revision) — the module system that makes radical evolution safe.**

*Sealed against the C:\\CHARIOT closure of 2026-05-03. R1.A10 = SHA-256(canonical_byte_form(this_file)).*
