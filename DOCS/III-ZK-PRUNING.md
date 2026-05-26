# III-ZK-PRUNING.md — Audit-Chain Compression via Zero-Knowledge Rollups

**Document Identity:** ZK-PRUNING / Architectural Mandate / Cluster K Item 175
**Status:** **DERIVATIVE — NOT part of the R1 sealed set, but architecturally binding on every Wave-2+ implementation.** This document specifies the audit-chain compression mechanism that allows the substrate to operate at planetary scale without choking on its own audit trail.
**Version:** 1.0 — 2026-05-03 (Wave 2.2)
**Sources:** All 15 R1-sealed specs; III-CRYPTO-AGILITY.md; III-FOUNDERS-ANCHOR.md; III-OBSERVABILITY.md.
**Cluster K item:** 175 (Cryptographic Pruning via ZK-Rollups — The Storage Crisis).
**Sibling Wave-2 doc:** III-OBSERVABILITY.md (items 26-32, OBSERVATORY collapse).

---

## §0. Preamble — The Storage Crisis at Planetary Scale

III emits a 128-byte XiiWitness for every privileged effect. The witness chain is permanently appended to the audit chain (Persistent Audit Spine, PAS). At planetary scale:

- 1 billion peers × 100 K cycles/sec = 10¹⁴ cycles/sec.
- 10¹⁴ cycles/sec × 128 bytes = **1.28 × 10¹⁶ bytes/sec** = **1.28 PB/sec** of audit data.
- Per minute: ~76 PB.
- Per day: ~110 EB.
- Per week: ~770 EB ≈ **0.77 ZB**.

The substrate would consume **multiple zettabytes per week** at planetary scale. This is operationally infeasible: storage costs would exceed the global IT budget; replication bandwidth would saturate every network link.

The substrate **must compress its audit trail** without losing the cryptographic integrity property. The compression must:

1. **Preserve verifiability**: any peer can verify the entire compressed chain represents a valid audit chain back to genesis.
2. **Preserve auditability**: the operator can selectively decompress regions of the chain on demand.
3. **Preserve causality**: causal-DAG analysis (per Stateful Neumann §3.4 / S16) operates on either compressed or decompressed regions transparently.
4. **Preserve Anchor invariants**: per III-FOUNDERS-ANCHOR.md, every Anchor witness is preserved uncompressed (Anchor authority cannot be elided).
5. **Preserve compromise events**: any compromise.medium / compromise.high event is preserved uncompressed.
6. **Preserve constitutional amendments**: every Tier-3 amendment witness is preserved uncompressed.

The mechanism: **Zero-Knowledge SNARKs/STARKs** that compress a window of N witnesses into a single, tiny cryptographic proof verifying the window's chain validity, without retaining the raw witness bytes.

This document specifies:

1. **§1** — The ZK-Rollup architecture
2. **§2** — The window-compression protocol
3. **§3** — Hand-rolled NIH ZK-SNARK / ZK-STARK implementation (no external library)
4. **§4** — Decompression and selective replay
5. **§5** — The pinning discipline (what cannot be compressed)
6. **§6** — Federation propagation of compressed chains
7. **§7** — The compaction-cycle Catalyst integration
8. **§8** — Compaction effect on causal inference and observability
9. **§9** — Storage savings analysis
10. **§10** — Conformance criteria
11. **§11** — Final statement

---

## §1. The ZK-Rollup Architecture

### §1.1 The compression cycle kind

A new cycle kind is allocated:

```iii
constant XII_CYCLE_KIND_ZK_ROLLUP = 0x0240
```

This cycle's forward:

1. Selects a **window** of consecutive witnesses from the audit chain (typically 10⁶ to 10⁹ witnesses).
2. Computes a ZK proof that the window's chain is internally consistent (every witness's predecessor_mhash matches; every HMAC verifies; every flag combination is admissible; etc.).
3. Computes a ZK proof that the window's chain is valid relative to its predecessor (the first witness in the window correctly references the predecessor witness's mhash).
4. Emits a **rollup witness** containing:
   - The window's start and end mhash boundaries.
   - The ZK proof.
   - A summary of preserved-uncompressed witnesses within the window.
5. Marks the window's raw witnesses as **archive-eligible** (movable to cold storage) or **discardable** (deletable after federation propagation).

### §1.2 The rollup witness layout

The rollup witness extends the standard 128-byte XiiWitness:

| Offset | Field | Size | Description |
|--------|-------|------|-------------|
| 0..32 | predecessor_mhash | 32 | Window's predecessor witness mhash |
| 32..40 | timestamp_sequence_class | 8 | Compaction completion time |
| 40..56 | cycle_kind | 16 | `XII_CYCLE_KIND_ZK_ROLLUP` |
| 56..88 | payload_mhash | 32 | mhash of the compressed window's body |
| 88..96 | flags | 8 | Bit 40 = ROLLUP_WITNESS, Bits 41..56 = ROLLUP_GENERATION (versioning), Bits 57..63 = COMPACTION_RATIO_Q14 |
| 96..128 | mac | 32 | Per-CPU HMAC over all preceding fields |
| **+128 (sidecar)** | **rollup_sidecar_mhash** | 32 | Hash of the sidecar segment containing the actual ZK proof + window metadata |

The **sidecar** holds:

- The ZK proof itself (~256-2048 bytes for SNARK; ~10-100 KB for STARK).
- The window's start and end witness mhashes.
- The list of preserved-uncompressed witness mhashes within the window (Anchor witnesses, compromise events, amendment witnesses).
- The compaction-time timestamp and the originating peer's identifier.
- The peer's signature over the entire sidecar (under the active suite).

Sidecars live in the per-CPU long-signature ring (per III-CRYPTO-AGILITY.md §12 "Witness layout impact") so that the witness chain itself remains 128 bytes per entry.

### §1.3 The rollup hierarchy

Rollups are themselves rollupable. A "Level 1 rollup" compresses 10⁶ witnesses into one rollup witness. A "Level 2 rollup" compresses 10³ Level-1 rollups (= 10⁹ original witnesses) into one Level-2 rollup. The hierarchy can extend indefinitely.

A peer verifying a Level-N rollup walks the proof tree at most N levels deep; each level's proof is verifiable in time roughly logarithmic in the underlying witness count.

---

## §2. The Window-Compression Protocol

### §2.1 Window selection

Compression operates over a window `[W_start, W_end]` selected per:

- **Time-based**: every chronos VDF tick (default ~10s), or every multiple thereof.
- **Count-based**: every N witnesses (default N = 10⁶).
- **Operator-triggered**: the operator can manually trigger compression via `system.zk.compact(window: ...)`.

### §2.2 The proof obligation

For window `[W_start, W_end]`, the ZK proof must establish:

1. **Internal chain consistency**: ∀ i ∈ [W_start, W_end-1], witness[i+1].predecessor_mhash = mhash(witness[i]).
2. **Internal HMAC consistency**: ∀ i ∈ [W_start, W_end], crypto.verify_mac(suite_id_at_i, sub_key_for_cpu_i, witness[i].body, witness[i].mac).
3. **Hexad consistency**: every witness's hexad is admissible per III-HEXAD §6.
4. **Flag consistency**: every witness's flag combination is admissible per III-CYCLES §6.
5. **Timestamp monotonicity**: witnesses within the same CPU's stream are time-ordered.
6. **Suite consistency**: every witness's `crypto_suite_id` matches a registered suite at the witness's epoch.
7. **Boundary consistency**: witness[W_start].predecessor_mhash = mhash(predecessor witness from outside window); the predecessor mhash is included in the proof's public input.

The proof is **succinct**: its size is poly-logarithmic in the window size; verification time is poly-logarithmic.

### §2.3 The preservation list

Witnesses that **cannot be compressed** (must be preserved uncompressed):

- Anchor witnesses (`flags & WITNESS_FLAGS_ANCHOR_AWARE != 0`).
- Compromise witnesses (`cycle_kind ∈ COMPROMISE_KINDS`).
- Amendment witnesses (`cycle_kind ∈ AMENDMENT_KINDS`).
- Federation-tier-constitutional witnesses.
- Suite-swap witnesses (`cycle_kind == XII_CYCLE_KIND_SUITE_SWAP`).
- DRTM-relaunch witnesses.
- Catalyst-promotion witnesses (with options for compaction at higher levels).
- The first witness of every epoch (epoch boundary anchor).

These are **enumerated** in the rollup sidecar by mhash, and the corresponding raw witnesses remain in the audit chain alongside the rollup witness. They remain queryable by `system.observe.witnesses_with_flag(...)`.

### §2.4 The compression-time witnessing

The compression cycle is itself witnessed:

```iii
cycle zk_rollup_compact(
    window_start: WitnessId,
    window_end: WitnessId,
    rollup_level: u8
) -> Witness
    @ring(R0)
    @hexad(ZK_ROLLUP_COMPACT)
    @track(
        accumulator: compaction_ratio_q14,
        threshold: hoeffding(0.95, 100),
        on_saturation: { /* log compaction efficiency */ }
    )
{
    forward {
        // 1. Read all witnesses in window.
        // 2. Identify preservation list.
        // 3. Construct the ZK proof.
        // 4. Compute the rollup witness body.
        // 5. Emit the rollup witness.
        // 6. Move raw witnesses to cold-storage tier (or discard, per operator config).
    }

    inverse {
        // The inverse decompresses the rollup back into raw witnesses.
        // Requires either the cold-storage archive or peer-replication-recovery.
        // If neither is available, the compaction is structurally @irreversible
        // (compromise.medium; this is operator-configured).
    }
}
```

Compaction emits a witness; the operator audits compaction events.

---

## §3. Hand-Rolled NIH ZK-SNARK / ZK-STARK Implementation

### §3.1 The mandate

Per the NIH discipline (per `feedback_iii_architect_standards.md` rule 2, III-FOUNDERS-ANCHOR.md, etc.), the substrate's ZK system is **hand-rolled from primary academic publications**. Forbidden:

- libsnark, libstark, libsnark-go.
- bellman, halo2, plonky2, plonky3, plonk.
- arkworks, ethsnarks, snarkjs.
- gnark, zokrates, circom.
- Any pre-existing implementation of any specific ZK protocol.

Required:

- Hand-rolled implementation from the original academic publication(s).
- Constant-time discipline for any witness/proof operations involving secret data (per III-PERFORMANCE.md §12).
- KAT corpus: deterministic test vectors covering every supported parameter set.
- Closure-pinned source: the ZK system's algorithm cannot be modified at runtime (per III-MODULES); modification requires Tier-3 + Anchor cosignature.

### §3.2 The choice: SNARK vs STARK

The substrate ships with **both** implementations:

#### §3.2.1 SNARK (Groth16-based, NIH from the 2016 Groth paper)

- **Pros**: constant-size proof (~256 bytes); fast verification (~1 ms).
- **Cons**: requires trusted setup ceremony (one-time per circuit family).
- **Use case**: pre-quantum suite; constrained verifier environment.

Implementation: `STDLIB/zk/groth16_nih.III` (~5000 LOC hand-rolled from Groth 2016 + Boneh-Lynn-Shacham). KAT corpus: 100+ test cases covering small to large circuits.

#### §3.2.2 STARK (FRI-based, NIH from the 2018 Ben-Sasson-Bentov-Horesh-Riabzev paper)

- **Pros**: no trusted setup; post-quantum secure (Reed-Solomon-based, hashing-based; no number-theoretic assumptions).
- **Cons**: larger proof (~10-100 KB); slightly slower verification (~10-100 ms).
- **Use case**: post-quantum suite; trust-minimized environment; planetary-federation-scale rollups.

Implementation: `STDLIB/zk/stark_nih.III` (~8000 LOC hand-rolled from Ben-Sasson et al. 2018). KAT corpus: 100+ test cases.

### §3.3 The circuit

The proof obligation (per §2.2) is encoded as an arithmetic circuit (for SNARK) or AIR (Algebraic Intermediate Representation, for STARK). The circuit:

- Takes the window of witnesses as private input (~128 bytes × N witnesses = 128 MB for N = 10⁶).
- Takes the predecessor mhash as public input.
- Takes the suite registry state as public input (suite_id → primitive registration).
- Takes the per-CPU sub-key derivation chain as public input (HKDF parameters).
- Outputs the window's start and end mhashes.

The circuit is hand-coded in arithmetic-circuit form for SNARK; in algebraic-intermediate-representation form for STARK. The circuit's source is closure-pinned; any modification changes the substrate's R1 root and forces a substrate-fork.

### §3.4 The post-quantum migration

The choice of SNARK vs STARK is **suite-aware**. Under the active cryptographic suite (per III-CRYPTO-AGILITY.md):

- Suite 0x0001 (pre-quantum): SNARK is the default.
- Suite 0x0100 (post-quantum): STARK is mandatory.
- Suite 0x0300 (hybrid): both SNARK and STARK proofs are computed for each rollup window; verification requires both pass.

The runtime dispatcher selects the active proof system based on the cycle's suite_id. The witness chain records which proof system was used per `flags` bit 35 (`ROLLUP_PROOF_SYSTEM`: 0 = SNARK, 1 = STARK).

### §3.5 Trusted setup (SNARK only)

For SNARK, the trusted setup is a **one-time ceremony** at substrate genesis:

- Operator generates the toxic waste and the proving/verifying keys on the air-gapped Anchor machine.
- The proving key is published into the substrate as a closure-pinned constant.
- The verifying key is similarly published.
- The toxic waste is **destroyed** (per established trusted-setup ceremony best practices).

The setup is **per circuit family** (one for the window-consistency circuit; one for the hierarchy-rollup circuit; etc.). Each setup is a separate ceremony.

For STARK: no trusted setup.

### §3.6 Performance targets

| Operation | SNARK | STARK |
|-----------|-------|-------|
| Prove (10⁶-witness window) | ~30 sec on AMD-Zen 5 | ~120 sec |
| Verify (rollup witness) | ~1 ms | ~50 ms |
| Proof size | 256 bytes | ~50 KB |
| Setup ceremony | One-time, ~1 hr | None |

Compaction frequency: per-tick (~10s) or operator-triggered. Prove time of 30-120s is acceptable for that frequency.

---

## §4. Decompression and Selective Replay

### §4.1 The mandate

The compaction is **reversible-by-archive**: if the cold-storage archive of the compressed window is available, the rollup can be decompressed back into raw witnesses. If the archive is unavailable, the compaction is **structurally @irreversible** (compromise.medium per III-CYCLES §5.2).

### §4.2 The cold-storage tier

The substrate supports three storage tiers for audit-chain witnesses:

1. **Hot tier**: in-memory or NVMe-resident witnesses (last 1-7 days).
2. **Warm tier**: on-disk archive (last 7-90 days).
3. **Cold tier**: tape, S3 Glacier, off-site archive (any age).

The rollup-compaction process **moves** raw witnesses from hot/warm to cold (or discards them, per operator configuration). The rollup witness itself remains in the hot tier.

### §4.3 The decompression cycle

```iii
cycle zk_rollup_decompress(
    rollup_witness_mhash: mhash
) -> [Witness]
    @ring(R0)
    @hexad(ZK_ROLLUP_DECOMPRESS)
    @cap(observe<audit_chain>)
{
    forward {
        // 1. Verify the rollup witness's signature.
        // 2. Locate the cold-storage archive corresponding to the window.
        // 3. Verify the archive's hash matches the rollup's window-hash.
        // 4. Return the raw witness sequence.
    }
}
```

### §4.4 Selective replay

The operator can replay a portion of the audit chain even if it has been compressed:

```iii
> system.audit.replay(epoch_range: 12..14, cycle_kind: REQUEST_PROCESS)
=> [Decompressing rollup 0xabc...]
   [Verifying ZK proof... ok]
   [Reconstructing 10000 witnesses...]
   [witness, witness, ...]
```

The decompression is itself witnessed (a `ZK_ROLLUP_DECOMPRESS` cycle invocation appears in the chain).

### §4.5 The discard contingency

If the operator configures **discard mode** (compaction discards raw witnesses without archive), then:

- The rollup is permanently un-decompressable to individual witnesses.
- The chain's *cryptographic verifiability* is preserved (the ZK proof still attests to the window's validity).
- Selective replay against the discarded window is impossible.
- The compaction is permanently @irreversible; emit `compromise.medium` with reason `audit-chain-discarded`.

Discard mode is **operator-controlled** and **Anchor-cosignature-required** for activation. Default is **archive mode** (preserve in cold tier).

---

## §5. The Pinning Discipline

### §5.1 What cannot be compressed (closure-pinned)

The preservation list (per §2.3) is **closure-pinned**. Modifying it (e.g., adding a new uncompressable witness class) requires Tier-3 amendment + Founder's Anchor cosignature. This protects against an attacker convincing the substrate to compress (and then discard) Anchor or compromise witnesses.

### §5.2 The proof kernel restraint

The proof kernel (per Stateful Neumann §4.1, III-FOUNDERS-ANCHOR.md §10) verifies that any rollup witness's preservation list correctly enumerates all preservation-required witnesses in its window. A rollup witness whose preservation list omits an Anchor witness fails verification — the proof certificate cannot be constructed.

### §5.3 The federation enforcement

Federation peers **independently verify** every rollup's preservation list. A peer that receives a rollup with an incomplete preservation list rejects the rollup and emits `compromise.high` against the originating peer.

---

## §6. Federation Propagation of Compressed Chains

### §6.1 The mandate

When a peer compacts a window and emits a rollup, the rollup propagates to all federation peers via FFP (per III-FEDERATION §4). Each peer:

1. Verifies the rollup's signature.
2. Verifies the ZK proof.
3. Verifies the preservation list.
4. Updates its local audit chain to reflect the compaction.
5. Optionally moves the corresponding raw witnesses to cold storage (each peer chooses independently).

### §6.2 The convergence discipline

Different peers may choose different storage tiers (some hot-archive everything; others discard aggressively). The substrate's witnessed-chain identity is **only** the rollup chain — the storage of raw witnesses is a per-peer policy.

### §6.3 The cross-peer integrity

A peer can request raw-witness reconstruction from another peer that has them archived:

```iii
> system.federation.request_archive(peer: <peer_id>, rollup_mhash: <hash>)
=> [Peer responds with archive]
=> [Verify archive hash matches rollup; reconstruct.]
```

This is gated by federation tier (require quorum-3-2 for sensitive archives).

---

## §7. The Compaction-Cycle Catalyst Integration

### §7.1 The mandate

The Catalyst (per III-CATALYST.md / Stateful Neumann §3.4 S17) **monitors compaction efficiency** and may synthesize improvements:

- If a peer's compaction ratio is consistently sub-optimal (e.g., the average rollup-witness count > 95% of the original window count), the Catalyst hypothesizes a Better Rollup parameter set (different window size, different ZK circuit, etc.) and submits as a candidate.
- The candidate is gated by Tier-3 + Anchor cosignature (no auto-promotion of new ZK parameters).

### §7.2 The compaction efficiency telemetry

Each rollup's compaction ratio (Q14) is recorded in `flags` bits 57..63 (per §1.2). The substrate aggregates a moving average; if the substrate-wide average drops below `XII_ZK_COMPACTION_RATIO_THRESHOLD = 0.95` (Q14 = 15564), a `compromise.low` is emitted with reason `compaction-inefficiency`.

### §7.3 Hierarchy promotion

The Catalyst can synthesize **higher-level rollups** (Level 2, Level 3, ...) when storage pressure remains high after Level 1 compaction. Hierarchy promotion is gated by Tier-3 + Anchor cosignature.

---

## §8. Effect on Causal Inference and Observability

### §8.1 Causal inference operates on rollups

The PC algorithm and FCI (per Stateful Neumann §3.4 S16) operate on the witness chain at whatever granularity is available. When a window is compressed, the causal-DAG analysis treats the rollup witness as a **single node** representing the entire compressed window.

The substrate maintains a **causal-DAG metadata sidecar** per rollup that summarizes:

- The cycle-kind distribution within the window.
- The most-frequent causal edges that were observed within the window.
- The witness-graph diameter and average-degree statistics.

These summaries propagate to the parent causal-DAG when the rollup is promoted.

### §8.2 Decompression for causal-inference detail

If the operator wants causal-inference detail at the witness level, they decompress the rollup (per §4) and re-run the analysis. The causal-DAG metadata is recomputed; the result merges into the substrate-wide DAG.

### §8.3 OBSERVABILITY queries against rollups

Per III-OBSERVABILITY.md §7, the operator's `system.observe(...)` queries operate transparently on rollup or raw witnesses:

- Queries asking for individual witness mhashes that fall inside a rollup either:
  - Decompress the rollup if archive is available, then return the witness.
  - Return a "compressed-region" stub witness containing the rollup's mhash and the original witness's offset/index within the window.
- The operator can re-query with `decompress=true` to force decompression.

---

## §9. Storage Savings Analysis

### §9.1 Compaction ratio at planetary scale

Per §1, planetary-scale unbounded growth is ~0.77 ZB/week. With ZK-rollup compaction:

| Tier | Rollup size | Original window | Compaction ratio |
|------|-------------|------------------|------------------|
| Level 1 (10⁶ witnesses) | ~1 KB rollup + ~50 KB sidecar | ~128 MB | ~99.96% reduction |
| Level 2 (10⁹ witnesses) | ~50 KB rollup + ~50 KB sidecar | ~128 GB | ~99.99992% reduction |
| Level 3 (10¹² witnesses) | ~50 KB rollup + ~50 KB sidecar | ~128 TB | ~99.99999992% reduction |

### §9.2 Operational burden at planetary scale (after Level 2 compaction)

- Audit chain size at Level 2: 10⁹ witnesses → ~100 KB. **The audit chain becomes practically free to store and replicate.**
- Preservation list (Anchor + compromise + amendment): perhaps 0.1% of witnesses → ~10⁶ witnesses preserved per epoch. **Manageable in any normal storage system.**

### §9.3 Long-term planetary scaling

At 100 EB total storage budget, the substrate can sustain operation for **decades** at planetary scale with hierarchical rollups. Beyond decades, the operator can elect to:

- Discard mode for archive-old rollups (preserving cryptographic verifiability while losing replay capability for ancient regions).
- Catalyst-synthesized higher-level rollups (Level 4, Level 5, ...) for further compaction.

### §9.4 The economic argument

The substrate's audit-chain cost becomes O(log N) where N is the number of cycles ever executed. **A planetary substrate's audit chain fits on a single laptop's disk forever.** This is the core enabling property of III at planetary scale.

---

## §10. Conformance Criteria

| Code | Criterion |
|------|-----------|
| C-ZK-1 | The ZK-rollup cycle kind `XII_CYCLE_KIND_ZK_ROLLUP` is allocated and dispatched (per item 175) |
| C-ZK-2 | Hand-rolled SNARK (Groth16) implementation passes its KAT corpus |
| C-ZK-3 | Hand-rolled STARK implementation passes its KAT corpus |
| C-ZK-4 | The substrate ships **both** SNARK and STARK; suite-aware dispatch selects correctly |
| C-ZK-5 | No external ZK library is linked into BOOT or STDLIB |
| C-ZK-6 | Trusted setup ceremony for SNARK occurred before substrate genesis; toxic waste destroyed |
| C-ZK-7 | Proving key and verifying key for SNARK are closure-pinned in the LEXICON |
| C-ZK-8 | Rollup witness layout per §1.2; sidecar mhash referenced via offset 128 |
| C-ZK-9 | Rollup proof verification correctly establishes window-internal chain consistency |
| C-ZK-10 | Rollup proof verification correctly establishes window-boundary consistency to predecessor |
| C-ZK-11 | Preservation list correctly preserves Anchor, compromise, amendment, suite-swap, DRTM-relaunch, Catalyst-promotion, and epoch-boundary witnesses |
| C-ZK-12 | Preservation list is closure-pinned; modification requires Tier-3 + Anchor cosignature |
| C-ZK-13 | Proof kernel rejects rollup witnesses with incomplete preservation lists |
| C-ZK-14 | Federation peer independently verifies preservation list; rejects malformed rollups |
| C-ZK-15 | Compaction ratio is recorded in rollup witness `flags` bits 57..63 |
| C-ZK-16 | Compaction-inefficiency emits `compromise.low` when ratio < `XII_ZK_COMPACTION_RATIO_THRESHOLD` |
| C-ZK-17 | Rollup hierarchy works: Level 2 rollup correctly compresses Level 1 rollups |
| C-ZK-18 | Decompression cycle correctly reconstructs raw witnesses from cold-storage archive |
| C-ZK-19 | Discard mode emits `compromise.medium` with reason `audit-chain-discarded` |
| C-ZK-20 | OBSERVABILITY queries operate transparently on rollup or raw witnesses |
| C-ZK-21 | Causal-DAG metadata sidecar per rollup is correctly maintained |
| C-ZK-22 | Suite-swap to post-quantum mandates STARK proofs (verified by closure-pinned dispatch) |

---

## §11. Final Statement

ZK-rollup pruning is the architectural commitment that III's audit-chain growth is **logarithmic in the number of cycles ever executed**, not linear. The substrate compresses windows of 10⁶ witnesses into a single ~50-KB rollup whose cryptographic guarantee is identical to the underlying chain.

At planetary scale, this means the audit chain fits on a single laptop's disk forever. The substrate's witnessed continuity remains intact across decades of operation; the operator's ability to selectively replay history remains intact for any window where archive is preserved; the cryptographic identity of the substrate (R1 composite root + audit chain root) remains continuously verifiable.

The hand-rolled NIH SNARK + STARK implementations preserve the discipline that no external dependency can compromise the substrate. The closure-pinned circuits + preservation lists + proving keys preserve the discipline that no runtime modification can dilute the chain's integrity.

This is the answer to item 175. The substrate, at planetary scale, is **operationally tractable** because compression is built into its identity — not retrofitted as an afterthought.

*Wave 2.2 deliverable. Sealed against the C:\\CHARIOT closure of 2026-05-03. Updated only via Catalyst-promoted append (new rollup level) or Tier-3 amendment (new circuit / new ZK protocol).*
