# III-SANDBOX.md — The Perfect Sandbox Architectural Mandate

**Document Identity:** SANDBOX / Architectural Mandate / Wave 10 / Items 86-90
**Status:** **DERIVATIVE — NOT part of the R1 sealed set, but architecturally binding on every Wave-10+ implementation.** This document specifies the **Perfect Sandbox**: an isolation primitive that admits any computation (III-native or legacy) with substrate-level guarantees of memory isolation, witnessed execution, reversibility, and causality preservation.
**Version:** 1.0 — 2026-05-03 (Wave 10.1)
**Sources:** All 15 R1-sealed specs; III-PORTABILITY.md; III-FOUNDERS-ANCHOR.md; III-OBSERVABILITY.md; III-LEGACY-INGESTION.md; III-POLYMORPHIC-DATA.md; III-CATALYST-EXT.md; Stateful Neumann §3.4 (general isolation discipline).
**Cluster integrated:** items 86 (sandbox primitive), 87 (isolation guarantees), 88 (state-snapshotting), 89 (sandbox-as-cycle-host), 90 (sandbox-witnessed-execution).
**Sibling Wave-10 doc:** III-GENESIS-VECTOR.md (item 177, polymorphic deployment installer).

---

## §0. Preamble — The Perfect Sandbox

A sandbox is a region of substrate-managed computation where:

- The hosted code (III-native or legacy) cannot access substrate-managed resources beyond its allotted capabilities.
- Every operation is witnessed.
- The state can be **snapshotted** at any point and restored later.
- Multiple snapshots can run in parallel as **counterfactual branches** (per III-CATALYST-EXT.md §2).
- The sandbox is **structurally reversible**: every state transition has an inverse, computable from the witness chain.

The "Perfect" qualifier means:

1. **Total isolation**: not even a single byte can leak between sandbox and substrate without going through the cap-mediated interface.
2. **Total observation**: every sandbox operation is in the audit chain.
3. **Total reproducibility**: snapshot + replay produces byte-identical results.
4. **Total reversibility**: rolling back a sandbox restores prior state byte-identically.
5. **Total decomposability**: a sandbox can host other sandboxes recursively.

This is the architectural primitive that enables:

- **Legacy OS hosting** (per III-LEGACY-INGESTION.md §8): each legacy OS is a sandbox.
- **Counterfactual replay** (per III-CATALYST-EXT.md §2): the replay runs in a sandbox.
- **Adversarial code execution**: malicious binaries run in a sandbox; their effect is contained.
- **Speculative execution**: speculative branches run in sandboxes; can be rolled back.
- **Genesis Vector deployment** (per III-GENESIS-VECTOR.md): the substrate's self-installation runs in a sandbox before committing.

This document specifies:

1. **§1** — The sandbox primitive (item 86)
2. **§2** — Sandbox isolation guarantees (item 87)
3. **§3** — Sandbox state-snapshotting (item 88)
4. **§4** — Sandbox-as-cycle-host (item 89)
5. **§5** — Sandbox-witnessed execution (item 90)
6. **§6** — Recursive sandbox composition
7. **§7** — Conformance criteria
8. **§8** — Final statement

---

## §1. The Sandbox Primitive (Item 86)

### §1.1 The mandate

The sandbox is a **first-class substrate type**:

```iii
schema Sandbox {
    sandbox_id: SandboxId,
    parent: Option<SandboxId>,                   // Recursive parent
    children: List<SandboxId>,
    state: SandboxState,                          // Running, Suspended, Snapshotted, Discarded
    
    memory_arena: SandboxMemoryArena,             // NPT-class isolated
    cap_grants: CapGrantSet,                      // Caps the sandbox holds
    cap_revocations: CapRevocationSet,             // Caps the sandbox is denied
    
    cpu_threads: List<SandboxThread>,
    file_descriptors: List<SandboxFd>,
    network_caps: List<SandboxNetworkCap>,
    
    audit_chain_tip: WitnessId,                   // The sandbox's audit chain tip
    snapshot_history: List<SandboxSnapshotId>,    // History of snapshots
    
    parent_capability: cap<sandbox<sandbox_id>>,  // Capability the parent holds over this sandbox
    self_capability: cap<self_sandbox>,            // The sandbox's own self-cap (limited operations)
}
```

### §1.2 The sandbox lifecycle

```iii
cycle sandbox_create(
    name: string,
    parent: Option<SandboxId>,
    initial_caps: CapGrantSet,
    resource_limits: ResourceLimits
) -> SandboxId
    @ring(R0)
    @hexad(SANDBOX_CREATE)
    @cap(sandbox<create>)

cycle sandbox_run(sandbox: SandboxId, code: Glyph) -> Witness
    @ring(R0)
    @hexad(SANDBOX_RUN)
    @cap(sandbox<run<sandbox_id>>)

cycle sandbox_suspend(sandbox: SandboxId) -> Witness
    @ring(R0)
    @hexad(SANDBOX_SUSPEND)
    @cap(sandbox<suspend<sandbox_id>>)

cycle sandbox_resume(sandbox: SandboxId) -> Witness
    @ring(R0)
    @hexad(SANDBOX_RESUME)
    @cap(sandbox<resume<sandbox_id>>)

cycle sandbox_terminate(sandbox: SandboxId, reason: TerminationReason) -> Witness
    @ring(R0)
    @hexad(SANDBOX_TERMINATE)
    @cap(sandbox<terminate<sandbox_id>>)

cycle sandbox_discard(sandbox: SandboxId) -> Witness
    @ring(R0)
    @hexad(SANDBOX_DISCARD)
    @cap(sandbox<discard<sandbox_id>>)
```

### §1.3 The sandbox state machine

```
[Created] → sandbox_run → [Running] → sandbox_suspend → [Suspended]
                ↓                                         ↓
             [snapshot] ←————————————————————————→ [snapshot]
                ↓                                         ↓
                ↓ ←———— sandbox_resume ————————————————— ↓
                ↓
          [Snapshotted]
                ↓
          sandbox_terminate
                ↓
            [Terminated] → sandbox_discard → [Discarded]
```

### §1.4 The closure-pinned sandbox source

The sandbox subsystem's source is closure-pinned. Modifying it (e.g., adding a new state, a new lifecycle action) requires Tier-3 + Anchor cosignature.

---

## §2. Sandbox Isolation Guarantees (Item 87)

### §2.1 The mandate

A sandbox guarantees:

1. **Memory isolation**: sandbox's memory is NPT-class `SANDBOX_MEMORY_<id>` and MPK-key `XII_MPK_SANDBOX_<id>`. Neither substrate code nor other sandboxes can read/write without explicit cap grants.
2. **CPU isolation**: sandbox's CPU threads are scheduled separately; substrate threads cannot execute sandbox code; sandbox threads cannot execute substrate code.
3. **Cap isolation**: sandbox holds only its granted caps; cannot escalate; cap-graph traversal stops at the sandbox boundary.
4. **Network isolation**: sandbox network access mediated through substrate's network layer (per III-SOVEREIGN-WEB.md §1); no direct adapter access.
5. **Filesystem isolation**: sandbox sees a virtualized FS view (per III-LEGACY-INGESTION.md §12); cannot access substrate-managed files.
6. **Audit chain isolation**: sandbox's witnesses chain into the sandbox's audit chain; not directly into the substrate's main chain. Cross-chain references are explicit and witnessed.

### §2.2 The NPT-class isolation

Every sandbox has:

- A unique NPT class trit (e.g., `SANDBOX_MEMORY_42` for sandbox 42).
- A unique MPK key (16 keys total; sandboxes share keys when not concurrent).
- A unique IOMMU context (for adapter access, per III-PORTABILITY.md §4).

These are programmed by the substrate at sandbox creation; the sandbox cannot reprogram them.

### §2.3 The cap boundary

Cap-graph traversal stops at the sandbox boundary:

- A sandbox-internal cap chain is fully traversable within the sandbox.
- A substrate-level cap chain is not visible to the sandbox.
- The sandbox's parent capability is held by the parent (or operator); the sandbox cannot ascend.

### §2.4 The leak prevention

The substrate verifies (at compile time and runtime) that:

- No sandbox-allocated memory address appears in substrate code.
- No substrate-allocated memory address appears in sandbox code (except via cap-mediated interface).
- No cap from one sandbox appears in another sandbox without explicit cap-graph routing.

### §2.5 The observability

Per III-OBSERVABILITY.md, the operator can query sandbox state:

```iii
> system.observe.sandboxes()
=> [
    { id: 1, name: "linux-vm", state: Running, parent: None, children: [3, 4] },
    { id: 2, name: "test-isolation", state: Snapshotted, parent: None, children: [] },
    { id: 3, name: "child-of-linux", state: Running, parent: Some(1), children: [] },
    ...
   ]
```

---

## §3. Sandbox State-Snapshotting (Item 88)

### §3.1 The mandate

A sandbox can be **snapshotted** at any moment; the snapshot captures the entire sandbox state (memory, CPU registers, file descriptors, network caps, audit chain tip). Snapshots can be:

- Restored later, returning the sandbox to its prior state.
- Replayed in parallel (multiple snapshots running simultaneously as counterfactual branches).
- Compared with each other (divergence analysis).

### §3.2 The snapshot mechanism

```iii
cycle sandbox_snapshot(sandbox: SandboxId) -> SandboxSnapshotId
    @ring(R0)
    @hexad(SANDBOX_SNAPSHOT)
    @cap(sandbox<snapshot<sandbox_id>>)
{
    forward {
        let snapshot = SandboxSnapshot {
            sandbox_id: sandbox,
            memory_image_mhash: snapshot_memory_to_mhash(sandbox),
            cpu_state_mhash: snapshot_cpu_state_to_mhash(sandbox),
            cap_state_mhash: snapshot_cap_state_to_mhash(sandbox),
            file_state_mhash: snapshot_file_state_to_mhash(sandbox),
            network_state_mhash: snapshot_network_state_to_mhash(sandbox),
            audit_chain_tip: sandbox.audit_chain_tip,
            timestamp: time.now(),
        }
        sandbox.snapshot_history.push(snapshot.id)
        return snapshot.id
    }
}
```

### §3.3 The snapshot storage

Snapshots are stored in **content-addressed sandbox snapshot storage**:

- Each snapshot is a Glyph V3 of form `SANDBOX_SNAPSHOT`.
- Each component (memory, CPU, caps, etc.) is a separate Glyph (hash-consed).
- Identical snapshots share storage.

### §3.4 The snapshot restoration

```iii
cycle sandbox_restore(sandbox: SandboxId, snapshot: SandboxSnapshotId) -> Witness
    @ring(R0)
    @hexad(SANDBOX_RESTORE)
    @cap(sandbox<restore<sandbox_id>>)
{
    forward {
        // 1. Atomically replace sandbox's memory with snapshot's memory image.
        // 2. Restore CPU registers.
        // 3. Restore cap state.
        // 4. Restore file descriptors.
        // 5. Restore network caps.
        // 6. Update audit chain to record the restore event.
    }
}
```

### §3.5 The counterfactual branching

Multiple snapshots can run in parallel:

```iii
cycle sandbox_fork(sandbox: SandboxId, snapshot: SandboxSnapshotId) -> SandboxId
    @ring(R0)
    @hexad(SANDBOX_FORK)
    @cap(sandbox<fork<sandbox_id>>)
{
    forward {
        // Create a new sandbox from the snapshot.
        // The new sandbox runs alongside the original.
        // Both sandboxes are witnessed independently.
        let new_sandbox_id = sandbox_create(
            name: format!("{}-fork-{}", sandbox.name, snapshot),
            parent: sandbox.parent,
            initial_caps: sandbox.cap_grants,
            resource_limits: sandbox.resource_limits
        )
        sandbox_restore(new_sandbox_id, snapshot)
        return new_sandbox_id
    }
}
```

### §3.6 The replay disambiguation

When a snapshot is restored, the sandbox's audit chain receives a `SANDBOX_RESTORED` witness. Subsequent witnesses from the restored sandbox include a flag indicating they are from a **non-canonical replay**. Multiple replay branches each have unique sandbox-ids, so witnesses from different branches don't conflict.

---

## §4. Sandbox-as-Cycle-Host (Item 89)

### §4.1 The mandate

A sandbox can host III cycles. The sandbox acts as a **substrate-within-substrate**: it has its own dispatch table, its own audit chain, its own Möbius coherence metric, etc.

### §4.2 The sandboxed-cycle dispatch

```iii
cycle sandbox_dispatch_cycle(
    sandbox: SandboxId,
    cycle_kind: CycleKind,
    args: Glyph
) -> Witness
    @ring(R0)
    @hexad(SANDBOX_DISPATCH)
    @cap(sandbox<dispatch<sandbox_id>>)
{
    forward {
        // 1. Verify cycle_kind is in the sandbox's permitted dispatch table.
        // 2. Translate the call into a sandbox-internal cycle invocation.
        // 3. Sandbox runs the cycle within its own isolation.
        // 4. Return the result.
    }
}
```

### §4.3 The sandbox's own dispatch table

Each sandbox has its own dispatch table. The table:

- Inherits from the parent's dispatch table (read-only by default).
- Can be augmented with sandbox-specific cycles (Catalyst-promoted within the sandbox).
- Cannot be modified to bypass the parent's restrictions.

### §4.4 The sandbox's audit chain integration

Witnesses from sandboxed cycle invocations chain into the sandbox's local audit chain. The sandbox's audit chain tip is periodically anchored into the parent's audit chain via:

```
SANDBOX_AUDIT_ANCHOR_WITNESS {
    sandbox_id: SandboxId,
    sandbox_chain_tip_mhash: mhash,
    parent_chain_tip_mhash: mhash,
    anchor_timestamp: u64,
}
```

This creates a **two-level audit chain**: the parent's chain references the sandbox's chain via anchor witnesses. The substrate's R1 root incorporates both levels.

### §4.5 The recursive composition

A sandbox can create child sandboxes (per §1.1). Each child has its own audit chain anchored into the parent. Recursion proceeds without bound — limited only by resource constraints.

---

## §5. Sandbox-Witnessed Execution (Item 90)

### §5.1 The mandate

Every sandbox operation is **witnessed**. The witness chain captures:

- Sandbox creation, lifecycle transitions.
- Memory allocations and deallocations.
- CPU thread starts and stops.
- File operations (read, write, open, close).
- Network operations (send, receive).
- Cap acquisitions and releases.
- Snapshot creation and restoration.
- Sandboxed-cycle invocations.

### §5.2 The witness flag

Sandboxed-witness flags include:

```
WITNESS_FLAG_FROM_SANDBOX            // Bit 16
WITNESS_FLAG_SANDBOX_NESTED          // Bit 17 (recursive sandbox)
WITNESS_FLAG_SANDBOX_RESTORED        // Bit 18 (after a restore)
WITNESS_FLAG_SANDBOX_COUNTERFACTUAL  // Bit 19 (in a forked counterfactual branch)
```

### §5.3 The replay capability

The operator can replay any sandbox's execution:

```iii
> system.observe.sandbox_replay(sandbox: 1, epoch_range: ...)
=> [
    { event: CREATED, name: "linux-vm", parent: None },
    { event: MEMORY_ALLOC, base: 0x1000, size: 4096 },
    { event: SYSCALL_open, args: ("/etc/passwd", O_RDONLY), result: 3 },
    { event: SYSCALL_read, args: (3, <buffer>, 1024), result: 1024 },
    ...
   ]
```

### §5.4 The sandbox's witness chain compression

Sandbox witnesses are eligible for ZK-rollup compaction (per III-ZK-PRUNING.md). Sandbox-anchor witnesses (per §4.4) are in the preservation list — they are never compressed; they are the entry points to a sandbox's chain.

### §5.5 The compromise propagation

Compromise tiers propagate from sandbox to parent: a compromise.high event in a sandbox flags the sandbox's last anchor witness in the parent's chain. The operator audits the chain to identify which sandbox produced the compromise.

---

## §6. Recursive Sandbox Composition

### §6.1 The discipline

Sandboxes compose recursively. A parent sandbox creates child sandboxes; children create grandchildren; etc. Each sandbox is fully isolated from its siblings; can communicate only through cap-mediated interfaces; can be snapshotted, restored, and forked independently.

### §6.2 The use cases

- **Legacy OS hosting**: each guest OS is a top-level sandbox. Per-process sub-sandboxes within the OS.
- **Counterfactual replay**: counterfactual branch is a forked sandbox. Multiple counterfactuals run concurrently.
- **Speculative execution**: speculative branch is a forked sandbox; rolled back if speculation fails.
- **Multi-tenancy**: each tenant's workload runs in a sandbox.
- **Genesis Vector deployment**: the substrate's self-install runs in a sandbox before committing (per III-GENESIS-VECTOR.md).

### §6.3 The cap-graph integration

Cap propagation from parent to child is explicit. Children inherit only the caps the parent grants; capability escalation is impossible.

### §6.4 The recursion limit

A configurable recursion limit (`XII_SANDBOX_MAX_RECURSION_DEPTH = 16`) prevents unbounded nesting. Exceeding the limit emits compromise.medium with reason `sandbox-recursion-exceeded`.

---

## §7. Conformance Criteria

| Code | Criterion |
|------|-----------|
| C-SAND-1 | Sandbox primitive is a first-class substrate type (per item 86) |
| C-SAND-2 | Sandbox lifecycle: created → running → suspended → snapshotted → terminated → discarded |
| C-SAND-3 | Memory isolation: sandbox's memory is NPT-class and MPK-key isolated (per item 87) |
| C-SAND-4 | CPU isolation: sandbox's CPU threads cannot execute substrate code |
| C-SAND-5 | Cap boundary: cap-graph traversal stops at sandbox boundary |
| C-SAND-6 | Network isolation: sandbox network access mediated through substrate's network layer |
| C-SAND-7 | Filesystem isolation: sandbox sees virtualized FS view |
| C-SAND-8 | Audit chain isolation: sandbox witnesses are anchored into parent via SANDBOX_AUDIT_ANCHOR |
| C-SAND-9 | Snapshot captures memory + CPU + caps + files + network state (per item 88) |
| C-SAND-10 | Snapshot storage uses content-addressed Glyph V3 |
| C-SAND-11 | Snapshot restoration is byte-identical (deterministic replay) |
| C-SAND-12 | Multiple counterfactual snapshots can run in parallel |
| C-SAND-13 | Sandbox-as-cycle-host: sandbox dispatches III cycles (per item 89) |
| C-SAND-14 | Sandbox's dispatch table inherits from parent (read-only by default) |
| C-SAND-15 | Recursive sandbox composition supports depth ≤ XII_SANDBOX_MAX_RECURSION_DEPTH |
| C-SAND-16 | Every sandbox operation is witnessed (per item 90) |
| C-SAND-17 | Witness flags identify sandbox-originated witnesses |
| C-SAND-18 | Sandbox replay correctly reconstructs sandbox execution |
| C-SAND-19 | Compromise tiers propagate from sandbox to parent |
| C-SAND-20 | Sandbox subsystem source is closure-pinned; modification requires Tier-3 + Anchor |

---

## §8. Final Statement

The Perfect Sandbox is the architectural commitment that **III's isolation primitive is total, witnessed, snapshot-able, and composable**. Every computation can be sandboxed; every sandbox is observable; every snapshot is restorable; every fork creates a counterfactual branch; every recursion is bounded.

This is the substrate's containment layer for legacy code, adversarial code, speculative execution, and counterfactual replay. The sandbox primitive is what makes III's terminal nature compatible with the existing world — it is the controlled environment where anything-not-yet-verified can run safely.

This is the answer to items 86-90. Wave 10.1 is the realization that III's terminal nature requires a **universal containment primitive** that admits any computation while preserving substrate identity.

*Wave 10.1 deliverable. Sealed against the C:\\CHARIOT closure of 2026-05-03.*
