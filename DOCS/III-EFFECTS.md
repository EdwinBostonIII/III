# III-EFFECTS.md — The Effect System of III

**Document Identity:** A4 / The Effect System
**Canonical Hash Slot:** R1.A4
**Version:** 1.0 — Final & Sealed
**Date:** 2026-05-03
**Authority:** Canonical. This is the only effect discipline the SELF compiler may enforce.
**Predecessor:** A3 III-TYPES.md (R1.A3)

---

## §0. Preamble — Infinite Usefulness with Near-Zero Overhead

Most effect systems are one of three failures:

- **Nuisances** (Rust's borrow checker, Koka's algebraic effects, Haskell's IO-monad-everywhere) — they impose syntactic overhead on every line of effectful code, drowning the programmer in annotation noise.
- **Weak** (most languages — C, Go, Python, Java, JavaScript) — they don't actually prevent real harm; effect tracking is convention or runtime checks.
- **Expensive** (heavy runtime tracking — full taint propagation, reference monitor logging, OS-level audit) — they pay an order-of-magnitude cost on every operation.

**III's effect system is none of these.** It is designed under a single ruthless constraint:

> Every effect must be *infinitely useful when you need it*, *completely invisible when you don't*, and *near-zero overhead in all cases* — because the architecture has Ring -2 access, a Persistent Audit Spine, ERW memoization, SRPA hot-path specialization, and a Möbius Catalyst that can promote better effect decompositions at runtime.

This is not an effect *tracker*. It is an **effect algebra** that turns every privileged operation into a first-class, witnessed, reversible, mathematically-grounded value — while making the common case (pure code, hot paths, simple reads) literally free.

The mechanism: every privileged write reaches its target through the **IRPD** (Inverse-Recoverable Privileged Discipline). There are exactly 17 such writes; each has a derivable inverse, a hexad in `xii_asym_reach6`, a witness emission, and a phase-marshalling lowering. Beyond the 17 are three Compromise tiers; beyond *those* are the six PFS bricking-class operations whose hexads are unrepresentable — they have no syntactic form and no admissible type. The system *cannot* express them.

---

## §1. The 17 SE Kinds + 3 Compromise Tiers

These are the **only** side effects that can ever occur in III. They are not strings. They are not enums in the loose sense. They are **first-class types** in the `Reduction` six-tuple's `Forward` and `Inverse` components.

### §1.1 The 17 Privileged Write Kinds (IRPD-Only)

| # | SE Kind | IRPD Method | Ring(s) | Hexad Name | SID-Derived Inverse | Notes |
|---|---------|-------------|---------|------------|----------------------|-------|
| 1 | `MSR_WRITE` | `irpd.msr_write(idx, val)` | R-2, R-1 | `MSR_WRITE` | `irpd.msr_write(idx, prior_val)` | Most common; covers all model-specific registers. |
| 2 | `CR_WRITE` | `irpd.cr_write(idx, val)` | R-1 | `CR_WRITE` | `irpd.cr_write(idx, prior_val)` | CR3, CR4, CR8 (LAPIC TPR), CR0 bits. |
| 3 | `NPT_ENTRY_WRITE` | `irpd.npt_write(gpa, entry)` | R-1 | `NPT_ENTRY` | `irpd.npt_write(gpa, prior_entry)` | SLAT manipulation. |
| 4 | `VMCB_FIELD_WRITE` | `irpd.vmcb_field(field_id, val)` | R-1 | `VMCB_FIELD` | `irpd.vmcb_field(field_id, prior_val)` | SVM VMCB control or state-save. |
| 5 | `IOMMU_DTE_WORD` | `irpd.iommu_dte(bdf, word_idx, val)` | R-1 | `IOMMU_DTE` | `irpd.iommu_dte(bdf, word_idx, prior_val)` | Device table entry. |
| 6 | `AVIC_TBL_WRITE` | `irpd.avic_tbl(idx, val)` | R-1 | `AVIC_TBL` | `irpd.avic_tbl(idx, prior_val)` | Interrupt virtualization. |
| 7 | `MSRPM_BIT_SET` | `irpd.msrpm_bit(msr_idx, mode, bit_val)` | R-1 | `MSRPM_BIT` | `irpd.msrpm_bit(msr_idx, mode, prior_bit_val)` | MSR permission bitmap. |
| 8 | `IOPM_BIT_SET` | `irpd.iopm_bit(port, bit_val)` | R-1 | `IOPM_BIT` | `irpd.iopm_bit(port, prior_bit_val)` | I/O permission bitmap. |
| 9 | `PKRU_WRITE` | `irpd.pkru_write(val)` | R-1, R0 | `PKRU_WRITE` | `irpd.pkru_write(prior_val)` | Memory protection keys. |
| 10 | `XCR0_WRITE` | `irpd.xcr0_write(val)` | R-1 | `XCR0_WRITE` | `irpd.xcr0_write(prior_val)` | Extended control registers. |
| 11 | `CAP_ACQUIRE` | `irpd.cap_acquire(cap_id, perm, range)` | All | `CAP_ACQUIRE` | `irpd.cap_release(cap_id)` | Linear capability acquisition. |
| 12 | `CAP_RELEASE` | `irpd.cap_release(cap_id)` | All | `CAP_RELEASE` | `irpd.cap_acquire(cap_id, prior_perm, prior_range)` | Linear capability release. |
| 13 | `PAGE_ALLOC` | `irpd.page_alloc(class, size)` | R0 | `PAGE_ALLOC` | `irpd.page_free(addr, class)` | Typed allocation (NPT-class-aware). |
| 14 | `PAGE_FREE` | `irpd.page_free(addr, class)` | R0 | `PAGE_FREE` | `irpd.page_alloc(prior_class, prior_size, addr)` | Typed deallocation. |
| 15 | `DPC_ARM` | `irpd.dpc_arm(dpc_id, deadline)` | R0 | `DPC_ARM` | `irpd.dpc_cancel(dpc_id)` | Deferred procedure call arm. |
| 16 | `DPC_CANCEL` | `irpd.dpc_cancel(dpc_id)` | R0 | `DPC_CANCEL` | `irpd.dpc_arm(dpc_id, prior_deadline)` | Deferred procedure call cancel. |
| 17 | `NMI_INSTALL` | `irpd.nmi_install(handler_addr)` | R-1 | `NMI_INSTALL` | `irpd.nmi_remove(handler_addr)` | Non-maskable interrupt hook. |

**Total: 17 distinct privileged write kinds.** Every privileged write in the entire III substrate is an instance of exactly one of these 17 kinds. There are no other privileged writes in the language; the type system rejects any cycle whose `forward` body emits a privileged-write opcode (WRMSR, MOV CR3, WRPKRU, …) outside the IRPD discipline (`PARSE-IRPD-001 raw privileged write outside IRPD`).

### §1.2 The 3 Compromise Tiers

For operations whose effects cannot be fully reversed, III provides three tiered Compromise types:

| Tier | Inverse Type | Meaning | When It Appears |
|------|--------------|---------|-----------------|
| `COMPROMISE_LOW` | `Compromise<LOW>` | Hardware-locked MSR or one-way state set. The inverse exists but only restores a "best-known" prior state, not bit-exact. | `@irreversible` on safe hardware (e.g., `IA32_FEATURE_CONTROL` lock bit). |
| `COMPROMISE_MEDIUM` | `Compromise<MEDIUM>` | Operations that touch System Management Mode, AMD Platform Security Processor, or Intel Management Engine. The inverse is a *re-establishment* of equivalent posture, not a reversal. | `HWCR.SmmLock`, `IA32_SMM_MONITOR_CTL`, PSP/ME mailbox operations. |
| `COMPROMISE_HIGH` | `Compromise<HIGH>` | True bricking-class. The inverse is *unrepresentable* — there is no recovery cycle. | The six PFS operations: `capsule_update`, `microcode_load`, `bootorder_set`, `real_nvram_write`, `me_psp_mailbox`, `smram_write`. |

`Compromise<HIGH>` is the type *of nothing* — its hexad is outside `xii_asym_reach6`, so no value of this type can be constructed. The type exists for completeness in the lattice (see III-TYPES.md §6.0), but it is *uninhabited*. This means the six PFS operations are not merely refused at runtime; they have no syntactic form, no admissible type, and no way to be expressed as well-typed III source.

### §1.3 Proof of Unrepresentability

The six PFS operations have hexads with NEG in pillar positions 1–4 (per III-HEXAD.md §4 — Representability Theorem):

| Operation | Hexad (P1–P6) | NEG pillars |
|-----------|---------------|-------------|
| `capsule_update` | (NEG, NEG, NEG, NEG, ZERO, ZERO) | 1, 2, 3, 4 |
| `microcode_load` | (NEG, NEG, NEG, ZERO, ZERO, ZERO) | 1, 2, 3 |
| `bootorder_set` | (NEG, NEG, ZERO, NEG, ZERO, ZERO) | 1, 2, 4 |
| `real_nvram_write` | (NEG, ZERO, NEG, NEG, ZERO, ZERO) | 1, 3, 4 |
| `me_psp_mailbox` | (ZERO, NEG, NEG, NEG, ZERO, ZERO) | 2, 3, 4 |
| `smram_write` | (NEG, NEG, NEG, NEG, NEG, ZERO) | 1, 2, 3, 4, 5 |

Per III-HEXAD.md §3, any pillar-1..4 with NEG produces an unrepresentable hexad. The 144-byte reachability bitmap `xii_asym_reach6[H] = 00` for each. The Hexad-Tag rule of III-TYPES.md §4.1 fails to admit them. The type `u64 @safety(<bricking-hexad>)` is uninhabited. **Any III source attempting to write a cycle whose composed hexad falls outside the reachable set is a parse-time type error.** The six bricking operations are not "forbidden." They are **absent from the language**.

```iii
u64 @safety(UNREACHABLE)             -- this type does not exist; lex/parse/type-check rejects
```

This is the central guarantee of III: bricking is not refused; it is **structurally unspeakable**.

---

## §2. The IRPD Discipline — The Only Privileged Write Surface

### §2.1 The Iron Rule

> Every privileged write in III **must** go through `irpd.<method>(...)`. There is no other syntax.

### §2.2 Formal Judgment

```
Γ ⊢ e : Reduction(F, I, W, H, P, E)
Γ ⊢ F contains a privileged write
─────────────────────────────────────                                (IRPD-Only)
Γ ⊢ F's privileged write is encoded as `irpd.<method>(args)` for some method ∈ {17 SE kinds}
```

Any source that emits a raw `WRMSR`, `MOV CR3`, `WRPKRU`, `INVLPGA`, `INVPCID`, `WRMSRNS`, `WRMSRLIST`, etc., outside the IRPD discipline is **unparsable**. The grammar does not admit such forms (cf. III-GRAMMAR.bnf §7.5 — `metal_stmt` is the only path to raw assembly, and it carries `@admits_caps` constraints that prevent emitting privileged opcodes outside IRPD).

### §2.3 Automatic Behaviors Granted by IRPD

The single rule "every privileged write goes through `irpd.<method>(...)`" gives us all of:

1. **Automatic witness emission.** Every IRPD method call produces a 128-byte `XiiWitness` recording the operation, target, prior value, new value, predecessor mhash, and HMAC.
2. **Automatic inverse derivation (SID).** The compiler reads the IRPD method name and arguments at type-check time, looks up the SE-kind classifier, and emits the inverse Reduction (per III-CYCLES.md §3.2 — the 32-step SID plan).
3. **Automatic hexad checking.** Every IRPD method has a known hexad; composition is checked at type-check time against `xii_asym_reach6`.
4. **Automatic phase marshalling.** Every IRPD method has a ring-set; calls from a wrong ring fail to type-check.
5. **Automatic audit-spine append.** The witness produced by every IRPD method call is appended to the Persistent Audit Spine via the BCWL-indexed forward ring (III-CYCLES.md §4).
6. **Automatic Trinity admission.** The IRPD entry-point inserts the appropriate Trinity-Gate evaluation per III-TRINITY.md.

These are not opt-in features. They are emitted by the compiler for every IRPD call, automatically, with **no source-level overhead**. The programmer writes `irpd.msr_write(MSR_EFER, prior | EFER_SVME)`; the compiler emits the witness, the inverse, the hexad check, the phase marshalling, and the audit append.

### §2.4 IRPD Method Signatures

Each IRPD method is a phase-polymorphic function in `STDLIB/irpd.III`:

```iii
fn irpd.msr_write(idx: u32, val: u64) -> Witness @ring(R-2, R-1) @hexad(MSR_WRITE) @safety(MSR_WRITE)
fn irpd.cr_write(idx: u32, val: u64) -> Witness @ring(R-1) @hexad(CR_WRITE)
fn irpd.npt_write(gpa: u64, entry: u64) -> Witness @ring(R-1) @hexad(NPT_ENTRY)
fn irpd.vmcb_field(field_id: u32, val: u64) -> Witness @ring(R-1) @hexad(VMCB_FIELD)
fn irpd.iommu_dte(bdf: u32, word_idx: u32, val: u64) -> Witness @ring(R-1) @hexad(IOMMU_DTE)
fn irpd.avic_tbl(idx: u32, val: u64) -> Witness @ring(R-1) @hexad(AVIC_TBL)
fn irpd.msrpm_bit(msr_idx: u32, mode: u8, bit_val: u8) -> Witness @ring(R-1) @hexad(MSRPM_BIT)
fn irpd.iopm_bit(port: u16, bit_val: u8) -> Witness @ring(R-1) @hexad(IOPM_BIT)
fn irpd.pkru_write(val: u32) -> Witness @ring(R-1, R0) @hexad(PKRU_WRITE)
fn irpd.xcr0_write(val: u64) -> Witness @ring(R-1) @hexad(XCR0_WRITE)
fn irpd.cap_acquire(cap_id: u64, perm: u8, range: Range) -> (Witness, Cap<perm, range>) @ring(R-2, R-1, R0, R3) @hexad(CAP_ACQUIRE)
fn irpd.cap_release(cap_id: u64) -> Witness @ring(R-2, R-1, R0, R3) @hexad(CAP_RELEASE)
fn irpd.page_alloc(class: u8, size: u32) -> (Witness, Cap<read_write, dyn>) @ring(R0) @hexad(PAGE_ALLOC)
fn irpd.page_free(addr: u64, class: u8) -> Witness @ring(R0) @hexad(PAGE_FREE)
fn irpd.dpc_arm(dpc_id: u32, deadline: WitnessedTime) -> Witness @ring(R0) @hexad(DPC_ARM)
fn irpd.dpc_cancel(dpc_id: u32) -> Witness @ring(R0) @hexad(DPC_CANCEL)
fn irpd.nmi_install(handler_addr: u64) -> Witness @ring(R-1) @hexad(NMI_INSTALL)
```

Each also has a corresponding `irpd.<method>_read(...)` for the read side (which is `@pure` — reads do not mutate state and produce only a (read-witness, value) pair, optionally `@witness_elide` on hot paths).

---

## §3. Novel Invention 1 — Predictive Inverse Pre-Materialization (PIP)

### §3.1 The Problem

Computing inverses at runtime is expensive: for every IRPD call, the runtime must (a) look up the method's inverse-derivation rule, (b) capture the prior value, (c) construct the inverse-reduction record, (d) thread it into the inverse ring. On hot paths (e.g., a stage-7 sustained VMRUN loop), this overhead would dominate the cycle's actual work.

Storing inverses *eagerly* — for every potential IRPD call — wastes memory and produces stale inverses that the GC must trace.

### §3.2 The Solution — PIP

The compiler (and later the Catalyst) **predicts** which inverses will be needed and **pre-materializes** them into `pip_blobs` at compile time or via SRPA hot-path promotion at runtime.

A `pip_blob` is a compact representation of an inverse — three classes:

```iii
@pip_blob(STATIC_BYTES)             -- memcpy inverse: byte-for-byte restore from a captured prior buffer
@pip_blob(DYNAMIC_FN)               -- function pointer inverse: invoke a small function with captured args
@pip_blob(COMPOSED)                 -- multi-step inverse: a sequence of the above
```

### §3.3 Formal Judgment

```
Γ ⊢ c : cycle declaration
Γ ⊢ c.inverse classified by SID
Γ ⊢ blob_class = pip_classify(c.inverse) ∈ {STATIC_BYTES, DYNAMIC_FN, COMPOSED}
─────────────────────────────                                       (PIP)
Γ ⊢ c lowers to Reduction(..., pip_blob = blob_class)
```

The PIP blob is allocated alongside the cycle's forward code in the same module, with a stable mhash that the inverse ring references.

### §3.4 Runtime Behavior

When a cycle executes its `forward`:

1. The forward body emits its IRPD writes (each producing a witness).
2. The PIP blob is appended to the per-CPU inverse ring (a single CAS append with a 32-bit blob index).
3. On rollback (if requested), the inverse ring is walked backwards; each PIP blob is invoked in reverse order.

For `STATIC_BYTES` blobs (which dominate hot paths because most IRPD writes are register/MSR writes whose inverse is `irpd.method(idx, prior_val)` with a captured prior value), the rollback is a memcpy + a few register stores — sub-5 cycles per inverse.

### §3.5 Result

**Near-zero overhead** for the common case (hot paths are specialized to sub-5-cycle latency for both forward and inverse) while still having perfect reversibility for audit and rollback. The witness chain remains complete; only the inverse-derivation work is amortized.

---

## §4. Novel Invention 2 — Ghost Effects (Zero-Overhead Auditability)

### §4.1 The Problem

You want perfect auditability. But you don't want to pay for it on every pure computation. A `@pure fn hash(x: u64) -> mhash` should run at native speed; the witness emission would be wasteful.

But you also don't want a "trust me" — if asked, the system should be able to *reconstruct* what the witness chain *would have been* if the pure computation had emitted witnesses.

### §4.2 The Solution — Ghost Effects

A `@pure` cycle (or function) can be marked `@witness_elide`. The compiler **elides** runtime witness emission for the cycle, but the type system still records that a witness *would have been* emitted, and the OBSERVATORY records a *ghost summary* of the ungenerated witnesses.

```iii
fn pure_hash(x: u64) -> mhash @pure @witness_elide { ... }
```

### §4.3 Formal Judgment

```
Γ ⊢ c : cycle with @pure and @witness_elide
─────────────────────────────                                       (Ghost)
Γ ⊢ c : Reduction(F, I, Witness=Elided, H, P, E)
```

`Witness=Elided` is not a distinct kind — it is a tag on the witness slot meaning "the canonical witness can be reconstructed on demand from (F, I, H, P, E, the cycle's source closure root, and the input arguments)." The OBSERVATORY accumulates a coverage proof showing that the elided witnesses are, in aggregate, summarized by the cycle's per-execution-sample distribution (Welford-Hoeffding-bounded).

### §4.4 Reconstruction

If the operator asks to *audit* an elided cycle's behavior, the audit-spine drainer (`iii-attest --reconstruct-elided <cycle_mhash>`) re-runs the cycle in a sandboxed context with the recorded inputs and emits the canonical witness for inspection. This is bounded by the OBSERVATORY's per-cycle sample retention.

### §4.5 Result

Pure code runs at native speed (no witness CAS, no HMAC, no ring append). Auditability is still perfect — the moment the operator asks, the audit can reconstruct the witnesses.

---

## §5. Novel Invention 3 — Epistemic Effects (Effects That Know What They Don't Know)

### §5.1 The Problem

In any sufficiently expressive system, some effects depend on uncertain inputs (e.g., a Catalyst-promoted abstraction whose saturation hasn't quite reached the threshold; a federation-replicated value whose quorum is in a marginal state). Forcing such effects to commit unconditionally is unsafe; refusing them entirely is wasteful.

### §5.2 The Solution — Epistemic Effects

Effects can carry an `Uncertainty` annotation:

```iii
let r : Reduction(F, I, W, H, P, E) carrying Uncertainty<Domain, Confidence, OpenQuestions> = ...
```

### §5.3 Formal Judgment

```
Γ ⊢ effect e
Γ ⊢ uncertainty(e) = U : Uncertainty(D, C, Q)
─────────────────────────                                           (Epistemic-Effect)
Γ ⊢ e : Reduction(F, I, W, H, P, E) carrying U
```

### §5.4 Runtime Behavior

When a cycle's confidence `U.confidence < THRESHOLD` (default `0.85q`):

1. The Trinity Gate automatically escalates to full Layer-3 evaluation (per III-TRINITY.md §4 — Epistemic Trinity).
2. The cognitive layer (`reflect(uncertainty)`) is invoked, producing a structured uncertainty report.
3. If the cycle is high-impact (e.g., `@tier(constitutional)` or `@sanctum_only`), the cycle is automatically routed through `negotiate(...)` for human refinement.
4. If `Q` (open questions) is non-empty, the cycle emits a `propose(...)` to the operator surface listing the open questions and offering a deferred-execution path.

### §5.5 Result

The cognitive layer (`reflect`, `negotiate`, `propose`, `commit`) is **typed and effect-aware**. The system can downgrade or reject high-uncertainty effects before they execute; or force a `negotiate` step with the human. This is the type-system mechanism behind the "minimally deployed but extremely accurate when risk is real" governance discipline.

---

## §6. Novel Invention 4 — Möbius Effects (Self-Extending Effects)

### §6.1 The Problem

A static effect set is a static language. III is *self-extending*: it must admit new effect decompositions as the substrate evolves.

### §6.2 The Solution — Möbius Effects

Effects can be promoted by the Catalyst:

```iii
mobius_candidate better_decomposition(...) -> ... @candidate_for_promotion @hexad(...) {
    forward { ... }
}
```

If the Catalyst observes that a particular effect decomposition is hot and mathematically beneficial (per the saturation rules in III-CATALYST.md §2), it promotes a new, more efficient effect kind at runtime.

### §6.3 Formal Promotion

```
Γ ⊢ candidate : mobius_candidate(...)
Γ ⊢ observatory.saturated(candidate)             via Welford-Hoeffding
Γ ⊢ candidate.möbius_coherence ≥ floor
Γ ⊢ trinity_admit(candidate)
Γ ⊢ ceiling_admit(candidate.post_state)
Γ ⊢ admitted(candidate.hexad)                     possibly via Dynamic-Hexad
Γ ⊢ codegen_validation(candidate) = SAFE_APPROVED ∨ SAFE_FLAGGED
─────────────────────────────                                       (Möbius-Effect-Promote)
Γ ⊢ promote(candidate) → new SE kind in reserved band 0x01C7..0x01CF
```

The new SE kind is allocated, the grammar table updated, and a `XII_STEP_KIND_MNEME_CATALYST_PROMOTE` witness emitted. Future invocations of cycles that compose into this new kind are specialized via SRPA.

### §6.4 Result

The effect system itself improves over time, with **near-zero overhead** because the promotion is just a grammar table update + SRPA specialization. The new effect kind is immediately type-safe (its hexad is admitted; its inverse is SID-derived; its phase set is checked).

---

## §7. Zero-Overhead Wavefront Semantics

Every effectful block is a `wavefront { ... } until <terminator>` (III-GRAMMAR.bnf §7).

### §7.1 Compiler Magic

- **Single-node wavefronts** (one statement) are automatically inlined; no wavefront-machinery overhead.
- **Multi-node wavefronts** are automatically batched when the composed delta admits parallel execution (per ACC Wall-Y check in III-TRINITY.md §1.3 Layer 2).
- **Hot wavefronts** (identified by SRPA accumulator) are promoted to specialized machine code, with the composed inverse pre-materialized as a single PIP blob — sub-5-cycle latency for both forward and inverse.
- **Cold or high-uncertainty wavefronts** remain fully witnessed and reversible at the per-statement level.

### §7.2 Wavefront Terminators (Restated)

| Terminator | Semantics |
|---|---|
| `until quiescent` | All effects have committed; no pending side-state. |
| `until coherent(Q)` | The manifold's coherence has reached Q14 ≥ Q. |
| `until count(N)` | After exactly N composed effects. |

### §7.3 Result

You write high-level, concurrent, reversible code. The system makes it run at near-native speed on hot paths and perfectly auditable on cold paths — automatically.

---

## §8. The Complete Effect Algebra

### §8.1 Selected Judgments

| Judgment | Meaning | Novelty |
|---|---|---|
| `Γ ⊢ e : Reduction(F, I, W, H, P, E)` | `e` is a witnessed, reversible effect | Core |
| `Γ ⊢ e uses irpd.<method>` | Privileged write goes through IRPD only | Iron rule |
| `Γ ⊢ e : Reduction(..., pip_blob = B)` | Inverse pre-materialized | PIP (near-0 overhead) |
| `Γ ⊢ e : Reduction(..., epistemic = U)` | Effect carries uncertainty | Epistemic effects |
| `Γ ⊢ e : Reduction(..., ghost = true)` | Witness elided but type-level recorded | Ghost effects |
| `Γ ⊢ promote(e)` | Catalyst may promote better decomposition | Möbius self-extension |
| `Γ ⊢ wavefront { e₁; e₂ } until X` | Concurrent effect composition | Zero-overhead wavefront |
| `Γ ⊢ e @safety(UNREACHABLE)` | Unrepresentable (bricking) | Proof of impossibility |

### §8.2 Composition Algebra

Effects compose via the operators of III-LEXICON.md §6:

- `e₁ ⊕ e₂` — cycle composition (forwards left-to-right, inverses right-to-left, per III-TYPES.md §3.4).
- `e ⟲` — single-step inverse (III-TYPES.md §3.5).
- `e ⟲⟲` — full inverse replay (walks the entire inverse chain).
- `e ⟡` — explicit witness emit (forces emission for an otherwise-elided cycle).
- `e ↻` — replay a witness (re-execute from a captured witness; requires the witness's epoch to match current).

### §8.3 The Six Compromise Operations Have No Operator

There is no operator in III's frozen set that can compose into a `Compromise<HIGH>`. The reachability bitmap forbids it; the type system rejects it. The six PFS bricking operations are *systematically inexpressible*.

---

## §9. Why This Effect System Is Infinitely Useful and Makes All Others Obsolete

1. **Near-zero overhead on hot paths.** PIP + SRPA + ERW + wavefront specialization. Sub-5-cycle latency for hot cycles.
2. **Perfect auditability on cold paths.** Ghost effects + full witness emission. The audit spine never loses provenance.
3. **Perfect reversibility by construction.** Every effect carries its inverse. Rollback is type-directed, not library-based.
4. **Security that cannot be bypassed.** IRPD discipline + unrepresentable bricking hexads + Trinity-Gate admission.
5. **Self-improving over time.** Möbius effects + Catalyst promotion. The effect system learns from the substrate's own use.
6. **Cognitive integration.** Epistemic effects let the language reason about its own uncertainty. The cognitive layer is type-sound.
7. **Never a nuisance.** Pure code is free. Hot paths are specialized. You only pay for what you actually use.

No other effect system in computing history combines all seven properties.

---

## §10. Closure Identity Rule (R1.A4)

R1.A4 = `SHA-256(canonical_byte_form(this_file))`. Embedded in every compiled module's closure manifest and in the composite specification root R1.

---

## §11. Catalyst Extension Pathway

New SE kinds are allocated in the reserved band `XII_STEP_KIND_RESERVED_001..016`. Promotion follows the same Trinity-gated, codegen-validated, ring-gated, witness-emitting pathway as keyword promotion (III-CATALYST.md §2).

What may not be promoted:

1. Removing an existing SE kind (would invalidate prior witnesses).
2. Changing the inverse-derivation rule for an existing SE kind.
3. Promoting a Compromise tier above `MEDIUM` (the LOW/MEDIUM/HIGH set is constitutional).
4. Promoting any SE kind whose hexad is unreachable.

---

## §12. Conformance Criteria

- **C-EFF-1.** Every privileged write in a conformant III implementation goes through `irpd.<method>(...)`. C-16 in III-CONFORMANCE.md.
- **C-EFF-2.** The 17 SE kinds + 3 Compromise tiers are implemented exactly as specified. C-1 alignment.
- **C-EFF-3.** PIP blob classification produces sub-5-cycle hot-path latency on representative workloads.
- **C-EFF-4.** Ghost effects elide runtime witness emission while preserving audit-reconstructability.
- **C-EFF-5.** Epistemic effects automatically escalate Trinity-Gate when `U.confidence < 0.85q`.
- **C-EFF-6.** Möbius-promoted effect decompositions pass through the full Catalyst pipeline including codegen validation.
- **C-EFF-7.** The six PFS bricking operations are unrepresentable: no III source can produce a Compromise<HIGH> value. Verified by negative-test corpus.

---

## §13. Final Declaration

This is not an effect system. This is the **formal algebra of sovereign action** — the system in which every privileged operation is a witnessed, reversible, mathematically-grounded, self-improving, uncertainty-aware, constitutionally-bounded value, while the common case (pure computation, hot paths) runs at native speed with literally zero overhead.

**III-EFFECTS.md — the effect system that makes all others obsolete.**

*Sealed against the C:\\CHARIOT closure of 2026-05-03. R1.A4 = SHA-256(canonical_byte_form(this_file)).*
