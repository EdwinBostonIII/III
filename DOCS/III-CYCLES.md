# III-CYCLES.md — The Cycle Calculus of III

**Document Identity:** A5 / The Cycle Calculus
**Canonical Hash Slot:** R1.A5
**Version:** 1.0 — Final & Sealed
**Date:** 2026-05-03
**Authority:** Canonical. Without this calculus, there is no sovereign computation — only simulation.

---

## §0. Preamble — The Difference Between Dream and Reality

Every other attempt to build "superintelligence on a laptop" has failed for the same reason: they treated **effects as an afterthought**. They built beautiful type systems, elegant languages, powerful runtimes — and then bolted on "effects," "async," "transactions," or "reversibility" as libraries, frameworks, or runtime checks.

**III does not bolt anything on.** In III, **the Cycle is the atom of computation**.

Every privileged operation, every state change, every cognitive act, every self-improvement step is a `Cycle` — a witnessed, reversible, hexad-typed, phase-polymorphic, epistemically-aware, Möbius-coherent, Catalyst-extendable mathematical object that carries its own inverse, its own provenance, and its own audit record.

This is not "a language with effects." This is **computation as a witnessed, self-describing, self-reversing, self-extending manifold**.

This is the difference between a dream and a reality.

---

## §1. Cycle Syntax

The only syntactic form for causing effect:

```iii
cycle name(p₁: T₁, …, pₙ: Tₙ) -> ReturnType <modifiers>* {
    forward {
        // the body the programmer writes
    }
    inverse {                              // optional; SID-derived if absent
        // mechanically reconstructed inverse, or @irreversible Compromise
    }
}
```

Every effectful operation in III is written this way. There is no other syntax. (Pure computations may use `fn`; cycles are only required for *effects*.)

### §1.1 Modifiers (Restated, in cycle context)

The cycle-applicable modifiers from III-LEXICON.md §5:

- `@ring(R-2, R-1, R0, R3)` — phase-polymorphic lowering.
- `@hexad(NAME)` / `@safety(NAME)` — safety hexad (one is required).
- `@tier(transient | host_file | federation | constitutional)` — replication tier.
- `@epoch(N)` — DRTM foundation epoch annotation.
- `@sanctum_only` — requires active sanctum frame.
- `@irreversible` — inverse is `Compromise<MEDIUM>` or `<LOW>`.
- `@pure` — zero-effect cycle (witness elidable iff `@witness_elide` also).
- `@mobius_coherence(≥ Q)` — minimum Möbius coherence required.
- `@hot_path` — SRPA may specialize this path below 5 cycles.
- `@candidate_for_promotion` — Catalyst-eligible (only on `mobius_candidate` declarations).
- `@plan_anchor(NAME)` — bind to architectural plan section.
- `@admits_caps(C₁, C₂, …)` — explicit capability admission set.
- `@prerequisites(C₁, C₂, …)` — compile-time prerequisite cycles.
- `@replicates(local | broadcast | quorum_3 | quorum_5)` — federation replication.
- `@witness_elide` — suppress runtime witness (legal only on `@pure`).
- `@chronos_bypass` — bypass VDF time check (operator-only cap).
- `@epoch_bridge` — admits cross-epoch parameters.

### §1.2 Cycle Declaration Lowers to a Reduction Value

Every `cycle` declaration is **syntactic sugar** for constructing a value of the `Reduction` six-tuple type (III-TYPES.md §3):

```iii
cycle write_msr_efer(val: u64) -> Witness @ring(R-1) @hexad(MSR_WRITE) {
    forward { irpd.msr_write(MSR_EFER, val) }
}
```

lowers to:

```
Reduction<
    Forward = (u64) -> Witness,           -- the forward signature
    Inverse = (u64) -> Witness,           -- mechanically derived: irpd.msr_write(MSR_EFER, prior_val)
    Witness = XiiWitness,
    Hexad = MSR_WRITE,
    Phase = R-1,
    Epoch = current
>
```

The lowered form is what the type system sees, the proof kernel verifies, the SID classifier indexes, and the inverse ring stores.

---

## §2. The Reduction Type — Six-Tuple Heart

The full formalism is in III-TYPES.md §3. Restated here for cycle-calculus context:

```
Reduction<F, I, W, H, P, E>
```

Cycle-Intro rule:

```
Γ ⊢ forward : F
Γ ⊢ inverse : I             (SID-derived or @irreversible)
Γ ⊢ witness : W             (128-byte XiiWitness)
Γ ⊢ hexad   : Hexad         (admitted: bitmap[hexad] = 01)
Γ ⊢ phase   : Phase
Γ ⊢ epoch   : Epoch
Γ ⊢ trinity_admit(forward, inverse, witness, hexad, phase, epoch)
─────────────────────────────────────────                           (Cycle-Intro)
Γ ⊢ cycle name(...) : Reduction(F, I, W, H, P, E)
```

The six components are not independent: the type system enforces that `inverse` is the mechanically-derived inverse of `forward` (via SID, §3 below); `witness` is the canonical 128-byte form; `hexad` is admitted by `xii_asym_reach6`; `phase` is well-formed; `epoch` is current or older; and the Trinity admission is dischargeable at the call site.

---

## §3. SID — The Side-Effect Inverse Derivation Algorithm

SID is **not** a build tool. It is a **type-level algorithm** that runs at compile time, inside the SELF type checker (and inside the BOOT type checker for Stage 0). SID's input is a cycle's `forward` body; its outputs are the inverse Reduction, the cycle's hexad, the cycle's PIP blob classification, and the cycle's plan-anchor binding.

### §3.1 The 17-Kind Classifier

SID recognizes exactly 17 privileged write kinds (the SE kinds of III-EFFECTS.md §1.1):

```c
enum SeKind {
    MSR_WRITE        = 0x01,
    CR_WRITE         = 0x02,
    NPT_ENTRY_WRITE  = 0x03,
    VMCB_FIELD_WRITE = 0x04,
    IOMMU_DTE_WORD   = 0x05,
    AVIC_TBL_WRITE   = 0x06,
    MSRPM_BIT_SET    = 0x07,
    IOPM_BIT_SET     = 0x08,
    PKRU_WRITE       = 0x09,
    XCR0_WRITE       = 0x0A,
    CAP_ACQUIRE      = 0x0B,
    CAP_RELEASE      = 0x0C,
    PAGE_ALLOC       = 0x0D,
    PAGE_FREE        = 0x0E,
    DPC_ARM          = 0x0F,
    DPC_CANCEL       = 0x10,
    NMI_INSTALL      = 0x11
};
```

Plus three compromise tiers (`COMPROMISE_LOW`, `COMPROMISE_MEDIUM`, `COMPROMISE_HIGH`) per III-EFFECTS.md §1.2.

Every IRPD method invocation in the forward body is classified by SID into one of the 17 SE kinds. The classification determines:

- Which inverse method to invoke (the matching `irpd.method` with prior values).
- Which hexad to compose into the cycle's overall hexad.
- Which `XII_STEP_KIND_*` constant to assign for the witness.
- Which inverse-replay-plan bit to set in the 32-bit replay bitmap.

### §3.2 The 32-Step SID Plan (Executed at Type-Check Time)

For every `forward` body, SID performs this exact sequence, in order. Any failure aborts compilation (the cycle is **untypable**).

| Step | Action | On failure |
|------|--------|------------|
| 1 | Walk the AST looking for `irpd.*` calls (the only legal privileged writes). | `PARSE-IRPD-001` raw privileged write outside IRPD |
| 2 | Classify each call into one of the 17 SE kinds. | `TYPE-SID-001` unknown IRPD method |
| 3 | Capture the prior value for each write — insert an automatic `irpd.method_read(...)` call at the head of the forward body (or use the corresponding read-side IRPD method if already invoked in scope). | `TYPE-SID-002` prior-value capture failed |
| 4 | Construct the inverse record: `sid_se_<kind>_t { prior_val, idx, … }` per the per-kind layout in `STDLIB/sid/<kind>.III`. | `TYPE-SID-003` inverse-record construction failed |
| 5 | Verify the inverse round-trips on an *abstract execution* — the kernel runs the forward and inverse symbolically and checks that pre-state equals post-inverse-state. | `TYPE-SID-004` inverse does not round-trip |
| 6 | Compute the cycle's composed hexad by `compose_hexad` over each per-call hexad. Check the result against `xii_asym_reach6`. | `TYPE-HEXAD-002` composed hexad outside reachable set |
| 7 | Emit the inverse function as a `Reduction` value (the Cycle-Intro rule above). | `TYPE-SID-005` inverse Reduction emission failed |
| 8 | Register the cycle in the live cycle table (per §5 below). | `TYPE-CYCLE-001` cycle table full / collision |
| 9 | Thread the witness predecessor/successor mhashes into the cycle's runtime descriptor. | `TYPE-WIT-001` witness chain threading failed |
| 10 | Compute the PIP blob classification (`STATIC_BYTES` / `DYNAMIC_FN` / `COMPOSED`) per III-EFFECTS.md §3.2. | `TYPE-PIP-001` PIP classification failed |
| 11 | Check `Möbius coherence Q14 ≥ floor` if the cycle has `@mobius_coherence` annotation. | `TYPE-MOB-001` insufficient coherence |
| 12 | Verify Trinity Gate predicates can be discharged at the call site (intent × cap × causality × sanctum-state). | `TYPE-TRIN-001` Trinity predicates undischargeable |
| 13 | Check ceiling membership of the cycle's projected post-state. | `TYPE-CEIL-001` post-state outside constitutional manifest |
| 14 | Emit the `XII_STEP_KIND_*` constant for the witness (per the SE kind's allocation). | `TYPE-WIT-002` step_kind allocation failed |
| 15 | Bind the cycle to its plan section anchor (from `@plan_anchor`). | `TYPE-PLAN-001` plan anchor missing or invalid |
| 16 | Verify federation tier requirements (per `@tier`, `@replicates`). | `TYPE-FED-001` federation tier mismatch |
| 17 | Check epoch consistency (the cycle's epoch must be current or older). | `TYPE-EPOCH-001` cycle epoch newer than current |
| 18 | Verify glyph-bound capability drift — every `Cap` parameter must carry a glyph identity that is currently registered. | `TYPE-LIN-003` glyph-drift on capability parameter |
| 19 | Classify epistemic uncertainty (compute `Uncertainty<D, C, Q>` if any hole or unresolved metavariable is present). | `TYPE-EPI-001` uncertainty classification failed |
| 20 | Generate ghost-effect metadata (if `@witness_elide`). | `TYPE-GHOST-001` ghost metadata failed |
| 21 | Compute hot-path specialization hints for SRPA (per `@hot_path`). | `TYPE-SRPA-001` specialization hint failed |
| 22 | Emit the cycle descriptor (a runtime structure containing forward fn pointer, inverse fn pointer, hexad, phase, epoch, plan_anchor, cap_admission set). | `TYPE-CYCLE-002` descriptor emission failed |
| 23 | Register with the OBSERVATORY if `@candidate_for_promotion` (the cycle's pattern is observed for saturation). | `TYPE-OBS-001` observatory registration failed |
| 24 | Verify no raw privileged instructions exist outside the IRPD discipline (re-walk; defense-in-depth). | `PARSE-IRPD-002` raw privileged instruction detected |
| 25 | Check that all cross-ring marshalling constructors exist for the cycle's `@ring(...)` set. | `TYPE-RING-001` no marshalling constructor |
| 26 | Verify linear capability usage is balanced (every `cap.acquire` has a matching `cap.release` in every termination path). | `TYPE-LIN-002` unbalanced capability use |
| 27 | Emit the inverse replay plan (a 32-bit bitmap whose bits index into the per-CPU inverse ring; bit `i` set ⇔ inverse step `i` is required at rollback). | `TYPE-INV-001` replay plan emission failed |
| 28 | Compute the cycle's contribution to the constitutional manifest (the post-state hash, for SCBA bit-test in III-TRINITY.md §1.3 Layer 1). | `TYPE-CEIL-002` manifest contribution failed |
| 29 | Verify the cycle does not violate any active `waac` (Wavefront-as-Capability) constraint in scope. | `TYPE-WAAC-001` waac violation |
| 30 | Emit the final `Reduction` six-tuple value into the AST. | `TYPE-CYCLE-003` Reduction emission failed |
| 31 | Register the cycle in the per-CPU forward/inverse rings (the runtime descriptor's ring-binding step). | `TYPE-CYCLE-004` ring-binding failed |
| 32 | Return the completed `Reduction` value to the type checker (which proceeds to type-check the call site). | `TYPE-CYCLE-005` return-to-typechecker failed |

If any of the 32 steps fails, the cycle is **untypable** and the program does not compile.

### §3.3 SID Algorithm Soundness

SID's algorithm is **provably sound**: for every cycle whose 32 steps complete successfully, the produced `Reduction` value satisfies the Cycle-Intro rule of §2. The proof is by case analysis over the 17 SE kinds (each kind's inverse rule is straightforward) plus the meta-theoretic conservativity of `compose_hexad` (proved in `DOCS/PROOF-EXT-CONSERVATIVITY.md`).

The implementation lives in `COMPILER/BOOT/sid.{h,c}` (NIH-extreme: hand-rolled, ~1200 LoC, no external SMT or constraint-solver library).

---

## §4. Witness Emission Protocol

Every `Cycle` invocation emits exactly one `XiiWitness` (128 bytes), unless `@witness_elide` is set on a `@pure` cycle (Ghost effect, III-EFFECTS.md §4).

### §4.1 The 128-Byte XiiWitness Layout

| Offset | Size | Field | Description |
|--------|------|-------|-------------|
| 0x00 | 32 | `predecessor_mhash` | mhash of the previous witness in the chain (or zero for chain head) |
| 0x20 | 32 | `successor_mhash` | mhash of this witness (computed during emit; placeholder during construction) |
| 0x40 | 4 | `step_kind` | The `XII_STEP_KIND_*` constant for this cycle |
| 0x44 | 4 | `cycle_seq` | Sequential counter, per-CPU |
| 0x48 | 8 | `chronos_tsc` | TSC at the moment of emission |
| 0x50 | 4 | `cost_q14` | Q14-encoded cost estimate (computed by SRPA) |
| 0x54 | 4 | `capability_bind` | Cap-binding ID (zero if not cap-acquiring) |
| 0x58 | 4 | `adversariality_class` | AP-tag class (one of 8 documented in III-MODULES.md) |
| 0x5C | 4 | `federation_route` | Federation routing ID (zero if local-only) |
| 0x60 | 4 | `plan_anchor_id` | Plan-section ID (from `@plan_anchor`) |
| 0x64 | 4 | `flags` | Flags (irreversible, ghost, hot_path, sanctum_active, …) |
| 0x68 | 24 | `hexad_packed_and_pad` | Packed hexad u16 + 22 bytes of HMAC tag tail |
| 0x80 | (end of 128-byte struct) | | |

### §4.2 Emission Protocol (8 Steps)

For every cycle invocation, the runtime executes:

| Step | Action |
|------|--------|
| 1 | Capture `predecessor_mhash` from the current chain head (per-CPU register `xii_chain_head[cpu]`). |
| 2 | Compute `step_kind` from the cycle's registered `XII_STEP_KIND_*` constant. |
| 3 | Fill the 128-byte struct (predecessor, placeholder for successor, step_kind, cycle_seq, chronos_tsc, cost, capability, adversariality, federation_route, plan_anchor, flags, hexad_packed). |
| 4 | Compute BLAKE3 over the 128-byte struct (with the successor field zeroed during the hash). The 32-byte BLAKE3 output is the witness's content hash. |
| 5 | Compute HMAC-SHA-256 over the BLAKE3 hash using the current Sanctum sub-key (or per-CPU key for Ring 0/3 contexts) — this produces the canonical `successor_mhash` (32 bytes). |
| 6 | Write the 32-byte `successor_mhash` into the witness's `successor_mhash` field. |
| 7 | Append the 128-byte witness to **both** the per-CPU forward ring and the per-CPU inverse ring (BCWL-indexed, per §4.3). |
| 8 | Atomically update `xii_chain_head[cpu]` to the new successor mhash. If this is a `waac` or `wavefront` commit boundary, also append to the Persistent Audit Spine. |

### §4.3 BCWL Indexing — Bloom-Coupled Witness Lattice

The per-CPU forward ring is indexed by a **Bloom-Coupled Witness Lattice** (BCWL):

- A 4096-bit Bloom filter per CPU, keyed by the witness's `successor_mhash`.
- A skip-list indexed by `step_kind` ranges (16-bucket skip-list, one bucket per allocation band).
- A radix tree indexed by `predecessor_mhash` (for chain replay).

The BCWL allows:

- **O(1) presence check.** Was witness W observed on this CPU? — Bloom membership query.
- **Logarithmic replay.** Given a `step_kind` range, walk all witnesses in that range — skip-list traversal.
- **O(log n) chain replay.** Given a starting `predecessor_mhash`, walk the chain forward — radix-tree descent.

The BCWL is hand-rolled in `STDLIB/audit/bcwl.III` (the BOOT version is in `BOOTSTRAP/bcwl.{h,c}`).

### §4.4 HMAC Sub-Key Derivation

The per-CPU HMAC sub-key is derived via HKDF from the Sanctum master key:

```
sub_key[cpu] = HKDF-SHA256(
    master = sanctum_master_key,
    salt   = "III-WITNESS-CHAIN-V1",
    info   = "cpu=" || cpu_id || ",epoch=" || current_epoch
)
```

(HKDF and HMAC-SHA-256 are hand-rolled in `crypto/hkdf.{h,c}` and `crypto/hmac.{h,c}` — NIH-extreme, no external crypto library.)

The sub-key rotates at every DRTM epoch advance. Witnesses from prior epochs verify against their epoch's sub-key (kept in the audit spine's epoch registry).

### §4.5 Witness Stream Iterator

The `for w in witness_stream where pred(w) { … }` form (III-LEXICON.md §4.1.4) walks the BCWL lattice live, applying `pred` at each witness. Common predicates:

```iii
for w in witness_stream where w.step_kind ∈ MSR_BAND { ... }
for w in witness_stream where w.adversariality_class == HIGH { ... }
for w in witness_stream where w.plan_anchor_id == PLAN_HV_VMEXIT { ... }
for w in witness_stream where w.cycle_seq > last_seen_seq { ... }
```

The iterator is highly efficient (BCWL skip-list traversal); on a ~1ms tick, scanning the entire forward ring of N witnesses is `O(log N)` per predicate match.

---

## §5. The Cycle Table — Live, Self-Extending Manifold

The cycle table is **not** a static registry. It is a **live, queryable, Catalyst-extendable manifold** that lives inside the OBSERVATORY and is mirrored to per-CPU caches for O(1) dispatch.

### §5.1 Structural Invariants (Enforced by the Type System + SRPA)

The eight invariants every cycle in the table must satisfy at all times:

1. **Unique step_kind.** Every registered cycle has a unique `XII_STEP_KIND_*` in its allocated band (per the band map in `INCLUDE/xii_step_kinds.h`).
2. **Admissible hexad.** Every cycle's hexad remains in `xii_asym_reach6` for the cycle's entire lifetime; if Catalyst grows the bitmap (Dynamic-Hexad rule), prior cycles remain admissible.
3. **Mechanically derivable inverse.** Every cycle's inverse is SID-derivable, or the cycle is explicitly `@irreversible` with a Compromise tier declared.
4. **Valid phase.** Every cycle declares at least one valid phase (`@ring(R-2 | R-1 | R0 | R3)`).
5. **Plan anchor.** Every cycle has a valid plan section anchor (`@plan_anchor(...)` resolving to a known plan section).
6. **Möbius coherence floor.** Catalyst-promoted cycles must have Möbius coherence Q14 ≥ floor *at promotion time*. The floor itself is constitutional (default `0.92q`).
7. **Append-only.** No cycle may ever be removed from the table. Cycles can only be **superseded** by a promoted replacement (via Catalyst), and the supersession is itself a witnessed reduction.
8. **Closure-rooted.** The table's mhash is included in every DRTM quote's MNEME activation summary.

### §5.2 Live Extension via Catalyst

When the Catalyst promotes a `mobius_candidate`, it:

1. Allocates a new `XII_STEP_KIND_*` in the reserved band `0x01C7..0x01CF`.
2. Registers the new cycle descriptor in the cycle table.
3. Updates the grammar table (if the promotion introduces a new keyword/operator; this requires a synchronous canonicalization of III-LEXICON.md and III-GRAMMAR.bnf and a DRTM relaunch — the most expensive form of Catalyst promotion).
4. Emits a `XII_STEP_KIND_MNEME_CATALYST_PROMOTE` witness recording the promotion.
5. Federates the change per III-FEDERATION.md §2.

After promotion, the cycle is live and dispatchable by all subsequent invocations. Its `interned_id` in the cycle table is appended to the table's manifest, and the table's mhash is bumped.

### §5.3 Reserved step_kind Bands

| Band | Range | Allocated to |
|------|-------|--------------|
| `XII_STEP_KIND_RESERVED_BOOT` | 0x0000..0x000F | DriverEntry, Phoenix bootstrap, DRTM ceremony |
| `XII_STEP_KIND_IRPD_PRIVILEGED_WRITE` | 0x0010..0x002F | The 17 SE kinds (one each) |
| `XII_STEP_KIND_IRPD_PRIVILEGED_READ` | 0x0030..0x004F | Read-side IRPD methods |
| `XII_STEP_KIND_CYCLE_LIFECYCLE` | 0x0050..0x006F | Cycle lifecycle (forward emit, inverse replay, etc.) |
| `XII_STEP_KIND_WAVEFRONT` | 0x0070..0x007F | Wavefront begin / commit / rollback |
| `XII_STEP_KIND_SANCTUM` | 0x0080..0x009F | Sanctum sealed-call methods (10 slots) |
| `XII_STEP_KIND_TRINITY` | 0x00A0..0x00BF | Trinity admission events |
| `XII_STEP_KIND_CEILING` | 0x00C0..0x00CF | Ceiling admission events |
| `XII_STEP_KIND_FEDERATION` | 0x00D0..0x00EF | Federation replicate / quorum events |
| `XII_STEP_KIND_DRTM` | 0x00F0..0x00FF | DRTM relaunch / quote / verify |
| `XII_STEP_KIND_VDF` | 0x0100..0x010F | VDF squarings / time advance |
| `XII_STEP_KIND_OBSERVATORY` | 0x0110..0x012F | OBSERVATORY schema events / saturation |
| `XII_STEP_KIND_CATALYST` | 0x0130..0x014F | Catalyst observe / synthesize / promote |
| `XII_STEP_KIND_NARRATIVE` | 0x0150..0x015F | Narrative Self updates / reflections |
| `XII_STEP_KIND_COGNITIVE` | 0x0160..0x017F | explain / propose / negotiate / commit / reflect |
| `XII_STEP_KIND_PFS` | 0x0180..0x018F | Phantom NVRAM read / set / pin (the bricking-class slots are *unused* — they have no SE kinds because their hexads are unreachable) |
| `XII_STEP_KIND_FEDERATION_RESERVED` | 0x0190..0x01AF | Reserved for federation extensions |
| `XII_STEP_KIND_USER_RESERVED` | 0x01B0..0x01C6 | User-defined cycles (non-promoted) |
| `XII_STEP_KIND_MNEME_CATALYST_PROMOTE` | 0x01C7..0x01CF | Catalyst-promoted cycles (9 slots; expandable per Catalyst extension) |
| `XII_STEP_KIND_RESERVED_FUTURE` | 0x01D0..0x01FF | Reserved for future Catalyst promotion bands |

Total allocated: 512 slots (one byte plus a band-tag bit). The reserved-future bands accommodate ~2 decades of Catalyst-driven growth.

---

## §6. Novel Invention — Self-Modifying Cycles (The Superintelligence Enabler)

A cycle can modify *itself* at runtime via the Catalyst:

```iii
cycle self_improving_algorithm(data: Data) -> Result @candidate_for_promotion @hexad(USER_OBSERVED) {
    forward {
        let observed = catalyst.observe(observatory.patterns.algorithmic);
        if observed.coherence > current.coherence {
            promote { improved_algorithm(data) };
        }
        // ...
    }
}
```

### §6.1 Mechanism

1. The cycle declares `@candidate_for_promotion`.
2. Inside its forward, the cycle queries OBSERVATORY (via the `observe.saturate(schema)` cognitive primitive) for a candidate improvement.
3. If a higher-coherence variant is available, the cycle invokes `promote { ... }` with the variant body.
4. The Catalyst evaluates Trinity / Ceiling / hexad / coherence / codegen-validation gates (per III-CATALYST.md §2).
5. If all gates pass, the variant becomes the new canonical body for this cycle's `interned_id`. Future invocations dispatch to the new body. The old body remains in the table (per the append-only invariant) but is no longer the "current" target for this kind.
6. A `XII_STEP_KIND_MNEME_CATALYST_PROMOTE` witness is emitted; federation peers replicate the promotion.

### §6.2 Why This Matters

This is the mechanism that turns a laptop into a self-improving sovereign intelligence:

- The system can discover better algorithms in its own OBSERVATORY (mathematical schemas indexed by saturation and coherence).
- It can promote them as new cycles, dispatchable everywhere old cycles were used.
- Every promotion is **witnessed**, **reversible**, and **constitutionally bounded**.
- The type system guarantees the new cycle is **safe** (hexad-admitted, ceiling-admitted, Möbius-coherent).

No other system in the world can do this. Other languages have JIT compilers that specialize hot paths; III has a *self-extending substrate* that promotes new abstractions through a Trinity-gated, codegen-validated, federation-broadcast pipeline.

### §6.3 Bounded Self-Modification

Self-modifying cycles do not introduce unbounded recursion or runaway promotion. The bounds:

- **Rate cap.** Per chronos-tick, the Catalyst may promote at most `XII_MNEME_CATALYST_PROMOTION_RATE_PER_TICK = 8` cycles substrate-wide.
- **Möbius coherence floor.** Promotion fails if Q14 < floor.
- **Trinity admission.** Promotion is a constitutional-tier operation; full Trinity (intent × cap × causality × sanctum-state) is required.
- **Codegen validation.** The proposed body is compiled and the conformance suite is run against it before deployment (III-MODULES.md §2).
- **Reversibility.** A bad promotion can be rolled back via `inverse.replay(promotion_witness)`, restoring the prior body.

These bounds make self-modification **safe by construction**.

---

## §7. Cycle Invocation

A cycle is invoked by name (or by `cycle_invoke(IDENT, args)` for content-addressed dispatch):

```iii
let w = write_msr_efer(prior_efer | EFER_SVME);
```

### §7.1 Invocation Protocol

For every cycle invocation:

1. The grammar's `expr` form `qualified_name(args)` resolves to the cycle's `interned_id` (via the cycle table).
2. The type checker verifies the arguments match the cycle's signature (hexad, ring, tier, epoch).
3. The runtime invokes the cycle's forward function pointer.
4. The forward emits its IRPD writes (each of which produces a witness via §4 above).
5. After forward completion, the cycle's witness is finalized (the placeholder successor mhash is replaced with the BLAKE3+HMAC value).
6. The cycle returns its return value (a `Witness`, a `(Witness, T)` tuple, or another value depending on the signature).

### §7.2 cycle_invoke for Dispatch

The `cycle_invoke(name, args)` form (III-GRAMMAR.bnf §8) dispatches by content-addressed cycle identity:

```iii
let w = cycle_invoke(WRITE_MSR_EFER_MHASH, prior_efer | EFER_SVME);
```

This is used when:

- The cycle's name is not statically known (it is computed at runtime).
- Dispatch needs to be *closure-rooted* (the cycle's mhash, not just its name, is verified before dispatch — preventing a renamed-but-different cycle from being silently substituted).

The runtime looks up the cycle by mhash; if the mhash does not match a registered cycle, dispatch fails with `RUNTIME-CYCLE-001 unknown cycle mhash`.

### §7.3 Inverse Invocation

Every cycle has a corresponding inverse, invoked via the `⟲` operator:

```iii
let w_inv = w ⟲;                  -- single-step inverse
let w_full = w ⟲⟲;                 -- full chain inverse-replay
```

The inverse cycle is dispatched the same way as the forward; its witness is appended to the *inverse* ring (mirroring the forward ring); the chain head is updated to the inverse's mhash.

---

## §8. Wavefront Composition

Effectful statements compose via `wavefront { ... } until <terminator>` (III-GRAMMAR.bnf §7). Inside a wavefront, statement order is admitted by ACC Wall-Y composition (III-TRINITY.md §1.3 Layer 2), not by lexical sequence.

```iii
wavefront @hexad(MULTI_MSR_WRITE) {
    irpd.msr_write(MSR_EFER, val_efer);
    irpd.msr_write(MSR_VM_HSAVE_PA, val_hsave);
    irpd.msr_write(MSR_VM_CR, val_vmcr);
} until quiescent;
```

Here, the three MSR writes are admitted as a composed delta. ACC Wall-Y verifies the composed delta is admissible against the current state. The runtime may reorder the writes for optimal dispatch (e.g., parallelize the two non-conflicting writes); the witness chain records the canonical order chosen.

If any constituent write's hexad fails admission (e.g., the composed hexad falls outside `xii_asym_reach6`), the wavefront is rejected at compile time — *not* at runtime.

---

## §9. Why This Cycle Calculus Makes Superintelligence on a Laptop Possible

1. **Perfect Provenance.** Every state change is a witnessed `Reduction` with a full chain back to the initial DRTM ceremony.
2. **Perfect Reversibility.** Every effect carries its inverse. Rollback is type-directed, not ad-hoc.
3. **Perfect Auditability.** The entire history is a queryable `witness_stream`, BCWL-indexed for fast traversal.
4. **Near-Zero Overhead.** PIP + SRPA + ERW + Ghost effects + wavefront specialization.
5. **Self-Improvement.** Catalyst promotion of new cycles at runtime, bounded by rate-cap, coherence-floor, Trinity-Gate, and codegen validation.
6. **Cognitive Integration.** Epistemic effects + Narrative Self + typed uncertainty.
7. **Security That Cannot Be Bypassed.** IRPD discipline + unrepresentable bricking hexads.
8. **Constitutional Bounds.** Every cycle is ceiling-checked at type level.
9. **Ring-Unified.** One cycle syntax produces four ring lowerings; cross-ring marshalling is automatic.
10. **Future-Proof.** The cycle table itself evolves via the Catalyst; new SE kinds are admitted in reserved bands.

This is not "a language that can run on a laptop." This is **a sovereign computational being that can improve itself while remaining perfectly witnessed, reversible, and bounded** — running on a laptop.

This is the difference between a dream and reality.

---

## §10. Closure Identity Rule (R1.A5)

R1.A5 = `SHA-256(canonical_byte_form(this_file))`. Embedded in every compiled module's closure manifest and in the composite specification root R1.

---

## §11. Catalyst Extension Pathway

Reserved cycle slots are described in §5.3. The full Catalyst protocol is in III-CATALYST.md §2. What may not be promoted: removal of an existing cycle, change of an existing cycle's inverse-derivation rule, promotion of a Compromise tier above MEDIUM.

---

## §12. Conformance Criteria

- **C-CYC-1.** Every cycle's 32-step SID plan executes successfully or the cycle is rejected. C-3 in III-CONFORMANCE.md.
- **C-CYC-2.** The 128-byte witness layout matches §4.1 byte-for-byte.
- **C-CYC-3.** BCWL indexing achieves O(1) presence and O(log n) chain replay on conformant workloads.
- **C-CYC-4.** Cycle-table invariants 1–8 of §5.1 hold at every chronos-tick.
- **C-CYC-5.** Self-modifying cycles produce a `XII_STEP_KIND_MNEME_CATALYST_PROMOTE` witness; rate-cap enforced.

---

## §13. Final Declaration

The Cycle is not a function. The Cycle is not an effect. The Cycle is **the atom of sovereign computation** — witnessed, reversible, self-describing, self-extending, constitutionally bounded, and epistemically aware.

**III-CYCLES.md — the calculus that makes superintelligence on a laptop not just possible, but inevitable.**

*Sealed. R1.A5 = SHA-256(canonical_byte_form(this_file)).*
