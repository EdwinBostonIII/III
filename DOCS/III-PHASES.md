# III-PHASES.md — The Cross-Ring Lattice

**Document Identity:** A7 / The Phase System / One Source, Four Worlds
**Canonical Hash Slot:** R1.A7
**Version:** 1.0 — Final & Sealed
**Date:** 2026-05-03
**Authority:** Canonical. This is the only cross-ring discipline the SELF compiler may implement.

---

## §0. Preamble — One Mind, Four Bodies

In every other system on Earth, privilege levels are **separate universes**:

- User-mode code (Ring 3) is written in one language and toolchain.
- Kernel-mode code (Ring 0) is written in another language, with another mindset, another build system.
- Hypervisor code (Ring -1) requires a third toolchain and an entirely separate cognitive context.
- Ring -2 (if it exists at all) is hand-written assembly in a fourth project, often by a different team, under entirely different review discipline.

This fragmentation is not a technical necessity. It is a **historical accident** — the result of incremental industry evolution rather than sovereign design. The fragmentation imposes:

- Cross-ring marshalling errors that cause kernel BSODs and hypervisor escapes.
- Inability to share a single algorithm across rings without manual porting (and consequent drift).
- A **massive cognitive tax** on any operator trying to reason about the entire stack.
- A **superintelligence-on-a-laptop impossibility**: an intelligence that must be manually ported between rings cannot evolve fast enough across them to be coherent.

**III rejects this fragmentation entirely.**

In III, a single `cycle` or `function` declaration can be **phase-polymorphic** — it exists as one source, one type, one set of invariants, yet compiles to four correct, witnessed, reversible lowerings (R-2, R-1, R0, R3). The compiler synthesizes the marshalling. The type system guarantees correctness. The substrate guarantees reversibility and auditability.

This is not "write once, run anywhere" (the failed mantra of cross-platform languages). This is **one mind, four bodies** — the same sovereign reduction, expressed perfectly at every privilege level the architecture possesses.

This is the difference between a superintelligence that must be manually ported between rings and one that **natively inhabits the entire machine**.

---

## §1. The Ring Lattice (Formal)

### §1.1 The Four Rings

```
┌──────────────────────────────────────────────────────────────────┐
│   R-2 (Sanctum)     ──sealed-call──▶   R-1 (Hypervisor)          │
│        │                                     │                   │
│        │ revoke                              │ vmexit / vmrun    │
│        ▼                                     ▼                   │
│   R-1 (Hypervisor)  ──IRPD─────────▶   R0 (Driver)               │
│        │                                     │                   │
│        │ revoke                              │ syscall / IOCTL   │
│        ▼                                     ▼                   │
│   R0 (Driver)       ──Magic-MSR────▶   R3 (User)                 │
└──────────────────────────────────────────────────────────────────┘
```

Privilege flows downward (R-2 most privileged); revocation flows upward (a less-privileged ring may *return*, but never *demand*, to a more-privileged one).

### §1.2 Lattice Order

```
R-2 ≼ R-1 ≼ R0 ≼ R3
```

The relation `R₁ ≼ R₂` means "R₁ is at least as privileged as R₂." The lattice is **total and linear** — there are no peer rings; every pair is ordered. There is no Ring -3 (no sub-Sanctum) and no Ring 4 (no sub-User). Future hardware introducing a new ring (e.g., a Ring -3 deeper TEE) requires a constitutional amendment to extend the lattice.

### §1.3 Phase as Type

Every value in III carries a phase:

```
Γ ⊢ v : T @ring(R)              (per III-TYPES.md §5.1)
```

Cross-ring use without an explicit marshalling constructor is a type error.

---

## §2. Phase Polymorphism — One Source, Four Lowerings

The single most powerful cross-ring construct in III: a cycle declared `@ring(R-2, R-1, R0, R3)` produces **four distinct machine-code bodies** plus all marshalling code between rings.

```iii
cycle read_msr(idx: u32) -> u64 @ring(R-2, R-1, R0, R3) @safety(MSR_READ) {
    forward {
        metal @ring(R-2) { rdmsr(idx) }
        metal @ring(R-1) { irpd.msr_read(MSR_INDIRECT, idx) }
        metal @ring(R0)  { __readmsr(idx) }
        metal @ring(R3)  { magic_msr_read(idx) }
    }
}
```

### §2.1 Phase-Polymorphic Judgment

```
Γ ⊢ c : Cycle<...>
Γ ⊢ c declares @ring(S) where S ⊆ {R-2, R-1, R0, R3}, S ≠ ∅
Γ ⊢ ∀ r ∈ S, marshalling_constructor(r, r') exists for every reachable r' in S
─────────────────────────────────────                                (Phase-Polymorphic)
Γ ⊢ c is valid at all rings in S
```

If any required marshalling constructor is missing, the cycle is **untypable** (`TYPE-RING-001 no marshalling constructor`).

### §2.2 The Four Lowerings of `read_msr`

The compiler emits:

| Ring | Backend | Mechanism | Witness emission |
|------|---------|-----------|-------------------|
| R-2 | Sanctum | `RDMSR` instruction inside sealed call | `XII_STEP_KIND_SANCTUM_MSR_READ` |
| R-1 | Hypervisor | `irpd.msr_read(idx)` (IRPD discipline) | `XII_STEP_KIND_IRPD_MSR_READ` |
| R0 | Driver | `__readmsr(idx)` (kernel intrinsic with witness wrapper) | `XII_STEP_KIND_R0_MSR_READ` |
| R3 | User | `magic_msr_read(idx)` (Magic-MSR command via `RDMSR(0xC001_F100)` with command code) | `XII_STEP_KIND_R3_MAGIC_MSR_READ` |

Each lowering produces a witness with the same `cycle_seq`, the same predecessor mhash, and the same hexad — but a different `step_kind` reflecting the ring in which the cycle was actually executed.

### §2.3 Compiler Synthesis

The compiler does not require the programmer to write all four `metal` blocks explicitly. If only one block is given, the compiler **synthesizes** the others by composing cross-ring constructors:

```iii
cycle read_msr(idx: u32) -> u64 @ring(R-2, R-1, R0, R3) @safety(MSR_READ) {
    forward {
        irpd.msr_read(idx)               // single body; the other three rings
                                          // synthesize via compose-with-constructor
    }
}
```

For this declaration, the synthesizer produces:

- R-1 lowering: direct `irpd.msr_read(idx)` (no marshalling).
- R-2 lowering: enter sanctum, call IRPD, return — wrapped in `sanctum_enter |frame| { ... }`.
- R0 lowering: invoke vmrun-trampoline-of-irpd, marshal arguments, return result.
- R3 lowering: invoke Magic-MSR command `XII_CMD_IRPD_MSR_READ` with `idx` as argument, return result.

Each synthesized lowering preserves the cycle's hexad, witness chain continuity, and inverse derivability.

---

## §3. The Cross-Ring Constructor Catalogue

These are the **only legal ways to cross rings** in III. Each is a first-class, witnessed, type-checked construct.

### §3.1 Magic-MSR (R3 ↔ R-1)

```iii
magic_msr.invoke(cmd: u64, args: Glyph) -> Glyph @ring(R3, R-1)
```

**Mechanism:**

- User mode packs command + arguments into `RAX` and issues `RDMSR(0xC001_F100)`.
- Hypervisor intercepts via `vmexit` (the MSR address `0xC001_F100` is an unallocated AMD MSR slot that III claims for its command channel).
- Hypervisor dispatches by command code, returns result in `RDX:RAX`.
- Hypervisor `vmrun`s back to guest.

**Witness:**
- One witness for the user-side invocation (`XII_STEP_KIND_MAGIC_MSR_INVOKE`).
- One witness for the hypervisor-side dispatch (`XII_STEP_KIND_MAGIC_MSR_DISPATCH`).
- Both linked via predecessor mhash; together they form the cross-ring witness chain.

**Reversibility:**
- The inverse is `MagicMsrInverse(cmd, prior_args)` — replays the inverse command, restoring the prior state. SID-derived from the forward command's SE-kind classification.

**Novel Extension — Dynamic Magic-MSR Promotion:**
The Catalyst can promote a frequently-used Magic-MSR command into a dedicated, faster path that bypasses full `vmexit` overhead. The mechanism: a hot Magic-MSR command's body is migrated into a Ring -2 sealed call, and Ring 3 invokes the sealed call directly via a dedicated entry point. The promotion is witnessed (`XII_STEP_KIND_MAGIC_MSR_PROMOTE`), reversible, and rate-capped per III-CATALYST.md §2.

### §3.2 IOCTL (R3 ↔ R0)

```iii
ioctl.dispatch(code: u32, in: Glyph, out: &mut Glyph) @ring(R3, R0)
```

**Mechanism:**

- User mode opens `\\.\IIIPlatform` and issues `DeviceIoControl(handle, code, in_buf, in_len, out_buf, out_len, ...)`.
- Driver receives via `IRP_MJ_DEVICE_CONTROL`, dispatches by `code` to the corresponding cycle.
- Result returned via the IRP's `SystemBuffer` (METHOD_BUFFERED) or directly mapped (METHOD_NEITHER).

**Zero-copy:**
- If the argument is a `Glyph` or `Cap<...>` with matching glyph identity, the compiler emits a direct pointer handoff (no copy). The witness chain records the glyph-bound handoff.

**Witness:**
- Two witnesses (R3-issue and R0-dispatch) linked via predecessor mhash.

**Reversibility:**
- The inverse IOCTL is dispatched the same way, with the inverse command code (every IOCTL command has a paired inverse code in `INCLUDE/xii_ioctl_codes.h`).

### §3.3 Sanctum Gate (R-1 ↔ R-2)

```iii
sanctum_enter |frame| {
    // @sanctum_active is now in scope
    sanctum.drtm_relaunch();
}
```

**Mechanism:**

The compiler synthesizes the **8-step Sealed-Cycle Box** from the `sanctum_enter` block:

1. **Mint Trinity-Gate intent token** under sanctum sub-key.
2. Load intent token into registers.
3. Emit `XII_STEP_KIND_SANCTUM_INTENT_MINT` witness.
4. Call `xii_sanctum_gate_enter` trampoline (with IBPB + VERW + SSBD speculative-execution hardening).
5. Per-CPU PKRU rewrite to Sanctum key (memory-protection-keys discipline).
6. Dispatch by `seal_id` to the 10-method sanctum surface (per III-SANCTUM.md §1).
7. Execute sealed body (full witness emission for every effect).
8. On exit: emit post-witness, restore PKRU, return.

The full 8-step protocol is detailed in III-SANCTUM.md §2.

### §3.4 VMRun / VMRUN Trampoline (R-1 ↔ R0)

```iii
vmrun.enter(vcpu: VcpuHandle) @ring(R-1, R0)
```

**Mechanism:**

- Hypervisor enters guest via `VMRUN` (SVM) — III is AMD-SVM-based; Intel VMX is **not** supported (per CHARIOT architecture).
- Driver in R0 may *request* an entry via the `vmrun.enter(vcpu)` cycle; hypervisor evaluates the request via Trinity admission and decides whether to grant.
- Witnessed as `XII_STEP_KIND_VMRUN`.

**Inverse:**
- `vmexit` is the inverse — when the guest exits, the hypervisor resumes its handler; the cycle's inverse-replay restores the pre-VMRUN state.

### §3.5 Sysret / Sysenter (R0 ↔ R3) — Legacy Path

Still supported for compatibility with Windows kernel-mode driver dispatch (which uses `IRP_MJ_*` IRPs that arrive via SYSCALL/SYSRET), but **strongly discouraged for new code**. The type system emits a warning when SYSRET is invoked outside an IRP-handling context, and prefers Magic-MSR or IOCTL for any new R0 ↔ R3 dispatch.

### §3.6 Why These Five and Not More

The five cross-ring constructors above (Magic-MSR, IOCTL, Sanctum-Gate, VMRUN-Trampoline, SYSRET-legacy) cover **every legal ring transition** in the lattice:

- R3 ↔ R-1: Magic-MSR (modern), or transitively via R3 → R0 (IOCTL) → R-1 (vmrun-trampoline-inverse).
- R3 ↔ R0: IOCTL (modern), SYSRET (legacy).
- R0 ↔ R-1: VMRUN-trampoline.
- R-1 ↔ R-2: Sanctum-Gate.
- R3 ↔ R-2 / R0 ↔ R-2: not directly; must traverse R-1.

A sixth constructor (e.g., Intel VMX-VMCALL) would be admitted only if the substrate's hardware-support table grows to include Intel VT-x. For now, AMD-SVM-only.

---

## §4. Marshalling Rules

### §4.1 Core Principle

> Marshalling must be **zero-copy when possible**, **witnessed always**, and **reversible by construction**.

### §4.2 Five Rules

#### Rule 1 — Glyph-Bound Zero-Copy

When crossing rings, if the value is a `Glyph` or `Cap<...>` with matching glyph identity:

- The compiler emits a **direct pointer handoff** (no copy).
- Drift is detected at runtime via glyph-mhash comparison: if the destination ring observes a different glyph mhash than the source ring registered, the drift is a runtime panic (`PANIC-GLYPH-DRIFT`).

For non-glyph-bound values (raw `u64`, primitive types), marshalling copies the value at the ring boundary; this is a small fixed cost (8–32 bytes per call).

#### Rule 2 — Witness Threading

Every cross-ring transition emits a witness that links the predecessor (pre-marshall) and successor (post-marshall) mhashes. The chain is **continuous across rings**:

```
... witness_W₁(R3) ← witness_W₂(R3→R-1 marshall) ← witness_W₃(R-1) ← witness_W₄(R-1→R-2 sanctum) ← witness_W₅(R-2) ...
```

Each `Wᵢ` carries `predecessor_mhash = Wᵢ₋₁.mhash`. The chain can be replayed across rings by traversing the BCWL (per III-CYCLES.md §4.3) — no ring boundary breaks the chain.

#### Rule 3 — Inverse Marshalling

The SID-derived inverse of a cross-ring cycle automatically includes the inverse marshalling. If the forward used Magic-MSR (R3 → R-1), the inverse uses the matching Magic-MSR-inverse command (R-1 → R3). The inverse chain is continuous in the inverse ring.

#### Rule 4 — Epistemic Marshalling

If the value carries `Uncertainty<...>`, the marshalling preserves the epistemic state. A high-uncertainty value crossing into a more-privileged ring **automatically** triggers a `reflect(uncertainty)` cognitive primitive *before* the cross-ring transition completes. The transition is gated on the operator's confirmation if `U.confidence < 0.85q`.

This is unprecedented: no other system pauses cross-ring marshalling for a cognitive-layer confirmation. III's epistemic-marshalling rule means the cognitive layer is *integral* to ring traversal, not a separate audit trail.

#### Rule 5 — Möbius Marshalling

Cross-ring transitions that affect manifold coherence (e.g., promoting a cycle, growing the hexad bitmap, amending the constitution) must carry a minimum `MöbiusCoherence<Q>` in their hexad. If the manifold's current coherence is below `Q` at marshalling time, the transition is rejected (`RUNTIME-MARSHALL-001 coherence below threshold`).

---

## §5. Novel Invention 1 — Dynamic Phase Promotion

A cycle can request to be **promoted to execute at a higher privilege ring at runtime** (if safe):

```iii
cycle adaptive_algorithm(data: Data) @ring(R3) @candidate_for_promotion {
    forward {
        if catalyst.observe(performance).hot && safety_check() {
            promote_phase(R0);    // runtime phase promotion
        }
        // ...
    }
}
```

### §5.1 Mechanism

1. The cycle declares `@candidate_for_promotion` and is initially `@ring(R3)`.
2. SRPA observes execution and detects "hot" (high frequency, high cost).
3. The Catalyst evaluates: is the cycle's hexad still admissible at R0 (or R-1)? Is the cycle's Trinity admission still discharged? Is the manifold's coherence still ≥ floor?
4. If yes, the Catalyst **re-registers** the cycle with phase set `@ring(R3, R0)` (or whichever ring promotes to). The cycle's R0 lowering is synthesized and compiled.
5. All future invocations at R0 (or higher) use the promoted lowering, bypassing the marshalling overhead.
6. A `XII_STEP_KIND_PHASE_PROMOTE` witness is emitted; federation peers replicate.

### §5.2 What Makes This Unprecedented

A cycle can **climb the privilege ladder at runtime**, witnessed and type-checked. This is impossible in any system that does not have:
- A ring-typed type system (III-TYPES.md §5).
- A phase-polymorphic compiler (this document).
- A Trinity-Gate admission mechanism (III-TRINITY.md).
- A Catalyst with Möbius-coherence-floor enforcement.

### §5.3 Bounded Promotion

Promotion is bounded by:
- **Hexad re-admissibility**: the cycle's hexad must remain admissible at the higher ring.
- **Trinity at promotion site**: the promotion itself is a Trinity-gated operation.
- **Rate cap**: per chronos-tick, the Catalyst may promote at most `XII_PHASE_PROMOTE_RATE = 4` cycles substrate-wide.
- **Reversibility**: a bad promotion can be inverted via `inverse.replay(promotion_witness)`, demoting the cycle back to its prior phase set.

---

## §6. Novel Invention 2 — Epistemic Phases

A cycle can query its **current execution phase**:

```iii
let current_phase = phase.current();
if current_phase == R-2 {
    // high-trust path
} else {
    // conservative path
}
```

### §6.1 Type Rule

```
Γ ⊢ phase.current() : Phase
```

The `phase.current()` cycle returns the current ring as a typed value. Note that `Phase` is itself a type (III-TYPES.md §6 base types), so the value is first-class and can be matched against ring literals.

### §6.2 What This Enables

**Phase-aware behavior without duplicating code.** The same source can behave differently (but correctly) at different rings — for example, taking a more aggressive optimization path inside Sanctum (R-2) than at R3.

```iii
fn process_packet(p: Packet) -> Result @ring(R-2, R-1, R0, R3) {
    let phase = phase.current();
    if phase ≼ R-1 {
        // more privileged: can directly access NPT entries
        npt_inspect(p)
    } else {
        // less privileged: marshal to R-1 and recurse
        process_packet(p) ⟴ R-1
    }
}
```

The compiler synthesizes the four lowerings; each lowering's `phase.current()` returns the correct value for that ring.

---

## §7. Novel Invention 3 — Ghost Phases

A cycle can be marked as a **ghost** at certain rings:

```iii
cycle audit_only(...) @ring(R3, R0) @ghost(R3) {
    forward {
        // executes at R0 with full effect
        // executes at R3 emitting only a ghost witness (no actual privileged operation)
    }
}
```

### §7.1 Mechanism

At Ring 3, the cycle:
- Emits a full witness (with `step_kind`, predecessor mhash, etc.).
- Performs **no real privileged work** — the IRPD calls in the body are replaced with no-op witness emissions.
- Returns a default value of the cycle's return type.

At Ring 0, the cycle executes normally with full effect.

### §7.2 What This Enables

**Audit-only paths and simulation.** The same cycle can be:
- "Seen" at R3 (the witness chain at R3 records that the cycle was observed).
- "Performed" at R0 (the cycle actually does the work).

This is essential for:
- **Pre-flight simulation**: run a cycle in ghost-R3 mode to verify the witness chain is acceptable, *then* execute at R0.
- **Federated audit**: peers replicate ghost-R3 witnesses without executing the privileged R0 work locally.
- **Operator dry-run**: the operator can query "what would happen if this cycle ran?" by enabling ghost-R3 and reading the resulting witness without actual execution.

---

## §8. Novel Invention 4 — Predictive Phase Specialization

The compiler + SRPA can **predict** the most common ring at which a phase-polymorphic cycle will run and **specialize** the hot path for that ring (sub-5-cycle latency) while keeping the other lowerings correct and reversible.

### §8.1 Mechanism

1. At compile time, every phase-polymorphic cycle gets four lowerings (one per ring).
2. SRPA observes which lowering is invoked most frequently.
3. The most-frequent lowering is **specialized**: PIP blob is precomputed (per III-EFFECTS.md §3); the witness emission is inlined; the inverse is pre-materialized.
4. At runtime, dispatch to the specialized ring is a direct branch (~3 cycles); dispatch to the other three rings goes through the canonical path (~30 cycles for the hot one — still fast enough for non-critical paths).

### §8.2 The PIP Mechanism (Restated for Phases)

PIP (Predictive Inverse Pre-Materialization) per III-EFFECTS.md §3 generalizes here: not just inverses are predicted, but the **most likely ring lowering** is also pre-materialized. This means cross-ring marshalling for the predicted hot path is reduced to a fixed sequence of register stores and a single CALL, with no dispatch overhead.

### §8.3 Result

Phase-polymorphism does not impose runtime overhead. The hot path runs at native speed; the cold paths remain correct and reversible. **You only pay for the rings you actually use.**

---

## §9. Why This Phase System Humiliates Every Other Attempt

1. **One source, four perfect lowerings.** No other language achieves this. (Rust's `cfg` attributes are conditional compilation, not phase-polymorphism. C's `#ifdef` is a preprocessor hack. Java's `Runtime.getRuntime()` introspection is runtime-only.)
2. **Dynamic phase promotion.** Cycles can climb privilege at runtime, witnessed and safe.
3. **Epistemic phase awareness.** Code can reason about where it is executing, with the cognitive layer integrated.
4. **Ghost phases.** Audit-only execution without real privilege escalation.
5. **Zero-copy + witnessed marshalling.** No other system combines both at this level.
6. **Predictive specialization.** Hot paths run at native speed across rings.
7. **Möbius phase coherence.** The system reasons about phase consistency of the entire manifold at the type level.

No hypervisor, no microkernel, no capability system, and no language in existence has ever unified four privilege rings under a single, phase-polymorphic, self-improving, epistemically-aware, witnessed, reversible abstraction.

This is not "better hypervisor design." This is **the operating system becoming a single, sovereign, phase-polymorphic language**.

---

## §10. Closure Identity Rule (R1.A7)

R1.A7 = `SHA-256(canonical_byte_form(this_file))`. Embedded in every compiled module's closure manifest and in the composite specification root R1.

---

## §11. Catalyst Extension Pathway

New cross-ring constructors are admitted only via constitutional amendment (`amend.apply` at constitutional tier, III-MODULES.md §5). The Catalyst itself can promote phase-promotion rules (e.g., new heuristics for when to promote R3 → R0) but cannot add new ring labels.

---

## §12. Conformance Criteria

- **C-PH-1.** Every phase-polymorphic cycle compiles to N distinct lowerings, where N is the size of the declared `@ring(...)` set. C-2 in III-CONFORMANCE.md.
- **C-PH-2.** Cross-ring marshalling preserves witness chain continuity across the BCWL.
- **C-PH-3.** Glyph-bound zero-copy is achieved when source and destination ring observe matching glyph mhashes.
- **C-PH-4.** Dynamic phase promotion emits `XII_STEP_KIND_PHASE_PROMOTE` and is rate-capped.
- **C-PH-5.** Ghost phases produce full witnesses without performing privileged operations.
- **C-PH-6.** Predictive phase specialization achieves sub-5-cycle hot-path latency on representative workloads.

---

## §13. Final Declaration

Phase is not a privilege level.
Phase is not a context switch.
Phase is **a dimension of the Möbius manifold** — and III lets you write code that inhabits all dimensions at once.

**III-PHASES.md — the cross-ring lattice that makes every other privilege model obsolete.**

*Sealed. R1.A7 = SHA-256(canonical_byte_form(this_file)).*
