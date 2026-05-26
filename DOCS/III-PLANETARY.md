# III-PLANETARY.md — Planetary-Scale Federation and Counter-Defensive Architectural Mandate

**Document Identity:** PLANETARY / Architectural Mandate / Wave 9 / Items 79-85
**Status:** **DERIVATIVE — NOT part of the R1 sealed set, but architecturally binding on every Wave-9+ implementation.** This document specifies the architectural mandates for III's operation at planetary scale (billions of peers): federation tier scaling, Sybil resistance, eclipse-attack resistance, network-partition recovery, and counter-defensive measures against malicious peers.
**Version:** 1.0 — 2026-05-03 (Wave 9)
**Sources:** All 15 R1-sealed specs; III-PORTABILITY.md; III-FOUNDERS-ANCHOR.md; III-OBSERVABILITY.md; III-ZK-PRUNING.md; III-SOVEREIGN-WEB.md; III-CATALYST-EXT.md; Stateful Neumann §3.3 (federation), §1.3 / S20 (planetary scale).
**Cluster integrated:** items 79 (planetary tier), 80 (attacker-peer detection), 81 (peer isolation), 82 (Sybil resistance), 83 (eclipse-attack resistance), 84 (network-partition recovery), 85 (planetary witness chain reconciliation).

---

## §0. Preamble — III at Planetary Scale

The current federation architecture (per III-FEDERATION B2) admits up to ~thousands of peers. At planetary scale (billions of peers), naive broadcast and full-quorum consensus become infeasible. The substrate must:

1. **Hierarchically structure the federation** so that quorum and replication scale logarithmically.
2. **Resist Sybil attacks** (single attacker creating many fake peers).
3. **Resist eclipse attacks** (attacker isolating a victim peer's network view).
4. **Recover from partitions** (regional network failures).
5. **Detect and isolate malicious peers** (Byzantine peers attempting to corrupt the chain).
6. **Reconcile witness chains across regions** without requiring global synchrony.
7. **Preserve the Founder's Anchor invariance** even when ~billions of peers might collectively try to amend it away (per III-FOUNDERS-ANCHOR.md §0 — exactly the scenario the Anchor exists for).

This document specifies:

1. **§1** — Planetary federation tier (item 79)
2. **§2** — Counter-defensive: attacker-peer detection (item 80)
3. **§3** — Counter-defensive: peer isolation / quarantine (item 81)
4. **§4** — Sybil resistance (item 82)
5. **§5** — Eclipse-attack resistance (item 83)
6. **§6** — Federation network-partition recovery (item 84)
7. **§7** — Planetary witness chain reconciliation (item 85)
8. **§8** — Conformance criteria
9. **§9** — Final statement

---

## §1. Planetary Federation Tier (Item 79)

### §1.1 The mandate

The federation extends to a fifth tier beyond the four (transient, host_file, federation, constitutional) per III-FEDERATION B2 §3:

| Tier | Scale | Quorum |
|------|-------|--------|
| transient | local | 1 (the originating CPU) |
| host_file | local + 1 backup | 2-of-2 |
| federation | regional | quorum-3-2 |
| constitutional | substrate-wide | unanimous |
| **planetary** | **billion-peer** | **hierarchical quorum** |

### §1.2 The hierarchical structure

The planetary tier organizes peers into:

- **Cells**: ~1000 peers each. Each cell has a quorum-3-2 (3 of 5 cell-leader peers).
- **Districts**: ~1000 cells each (~1M peers). Each district has a quorum-3-2 (3 of 5 district-leader cells).
- **Regions**: ~1000 districts each (~1B peers). Each region has a quorum-3-2.
- **The substrate**: ~10 regions (~10B peers). Substrate-wide unanimity not required for planetary-tier operations; instead, **threshold consensus** of regions.

### §1.3 The hierarchical witness propagation

A planetary-tier witness:

1. Originates in a peer.
2. Propagates to its cell (via gossip).
3. Cell-leader propagates to district.
4. District-leader propagates to region.
5. Region-leader propagates substrate-wide.

The propagation is **hierarchical**: each level only sees its own quorum. Sub-regions can disagree on transient details; only constitutional consensus requires cross-region agreement.

### §1.4 The leadership rotation

Cell, district, and region leaders are rotated periodically:

- Per epoch boundary (chronos VDF tick).
- Per leader-attestation window (~24 hours real-time).
- Leadership selection is **determined by VDF output + closure-root mhash + peer-id** — i.e., randomly chosen from the eligible peer pool.

### §1.5 The Anchor's role at planetary scale

Per III-FOUNDERS-ANCHOR.md: even at planetary scale, the Founder's Anchor remains the **single closure-pinned veto authority**. Every constitutional amendment requires Anchor cosignature. The hierarchical federation does NOT dilute the Anchor's authority; it merely organizes peer interaction.

### §1.6 The closure-pinned hierarchy

The 4-level hierarchical structure is closure-pinned. Modifying it (e.g., adding a 5th level for trillion-peer) requires Tier-3 + Anchor cosignature.

---

## §2. Counter-Defensive: Attacker-Peer Detection (Item 80)

### §2.1 The mandate

The substrate detects malicious peer behavior through:

1. **Witness consistency checks**: a peer's witness chain must be internally consistent (predecessor mhashes match, MACs verify, hexads admissible, etc.).
2. **Cross-peer consistency**: replicated witnesses across peers must agree.
3. **Pattern detection**: anomalous behavior patterns (burst-emission, signature-validation-failures, anchor-attack proposals).
4. **Cryptographic agility regression**: peer attempts to use a deprecated cryptographic suite without operator approval.
5. **Closure-root divergence**: peer's closure root differs from the federation consensus.

### §2.2 The detection algorithms

```iii
fn detect_malicious_behavior(peer: PeerId) -> [AttackSignal] {
    let signals = []
    
    // Signal 1: Witness chain integrity violation.
    when peer.witness_chain.has_integrity_violations() -> {
        signals.push(AttackSignal {
            kind: WITNESS_INTEGRITY_VIOLATION,
            peer: peer,
            severity: HIGH,
            evidence: peer.witness_chain.violation_evidence(),
        })
    }
    
    // Signal 2: Burst-emission anomaly.
    when peer.recent_emission_rate() > peer.baseline_rate() * BURST_THRESHOLD_MULTIPLIER -> {
        signals.push(AttackSignal {
            kind: BURST_EMISSION,
            peer: peer,
            severity: MEDIUM,
        })
    }
    
    // Signal 3: Anchor-attack pattern.
    when peer.recent_amendments().filter(|a| a.targets_anchor()).count() > ANCHOR_ATTACK_THRESHOLD -> {
        signals.push(AttackSignal {
            kind: ANCHOR_ATTACK_PATTERN,
            peer: peer,
            severity: HIGH,
        })
    }
    
    // Signal 4: Cross-peer replication divergence.
    when cross_peer_divergence(peer) > DIVERGENCE_THRESHOLD -> {
        signals.push(AttackSignal {
            kind: CROSS_PEER_DIVERGENCE,
            peer: peer,
            severity: MEDIUM,
        })
    }
    
    // Signal 5: Suite regression.
    when peer.active_cryptographic_suite() < federation_consensus_suite() -> {
        signals.push(AttackSignal {
            kind: SUITE_REGRESSION,
            peer: peer,
            severity: HIGH,
        })
    }
    
    // Signal 6: Closure-root divergence.
    when peer.closure_root != federation_consensus_closure_root() -> {
        signals.push(AttackSignal {
            kind: CLOSURE_ROOT_DIVERGENCE,
            peer: peer,
            severity: HIGH,
        })
    }
    
    return signals
}
```

### §2.3 The witness emission

Each detected attack signal emits a witness:

```
ATTACK_SIGNAL_DETECTED_WITNESS {
    detector_peer: PeerId,
    target_peer: PeerId,
    attack_kind: AttackKind,
    severity: Severity,
    evidence_mhash: mhash,
    timestamp: u64,
}
```

### §2.4 The federation-wide signal aggregation

Multiple peers detect signals against the same target. The federation aggregates:

- If quorum-3-2 of cell-peers report attacks against a target → escalate to district level.
- If quorum-3-2 of district-leader cells report → escalate to region level.
- If quorum-3-2 of region leaders report → quarantine the target peer (per §3).

---

## §3. Counter-Defensive: Peer Isolation / Quarantine (Item 81)

### §3.1 The mandate

Detected attacker peers are **quarantined**: removed from the federation; their messages discarded; their witness chains marked compromise.high.

### §3.2 The quarantine cycle

```iii
cycle peer_quarantine(
    target: PeerId,
    reason: QuarantineReason,
    evidence: Evidence,
    quorum_attestation: QuorumAttestation
) -> Witness
    @ring(R0)
    @hexad(PEER_QUARANTINE)
    @cap(federation<quarantine>)
{
    forward {
        // 1. Verify the quorum attestation.
        // 2. Mark the peer as quarantined in the local peer table.
        // 3. Propagate the quarantine across the federation.
        // 4. Emit witness recording the quarantine.
        // 5. Drop any pending federation messages from the quarantined peer.
    }
}
```

### §3.3 The quarantine semantics

A quarantined peer:

- **Cannot federate**: its messages are dropped; its witnesses are not replicated.
- **Cannot vote**: its quorum-membership is reduced to zero (it's no longer counted in any quorum).
- **Witness chain marked compromise.high**: any historical witness from the quarantined peer is now flagged in the audit chain.
- **Cannot rotate Anchor**: quarantined peers cannot cosign Anchor rotations.

### §3.4 The unquarantine process

A quarantined peer can be unquarantined via:

- **Operator intervention**: the operator (with Anchor cosignature for tier ≥ federation) can unquarantine a peer.
- **Self-remediation**: the peer re-attests via DRTM relaunch + closure-root proof + signature update; the federation re-verifies; if all checks pass, the peer is unquarantined.

### §3.5 The asymmetric isolation

A quarantined peer can:

- **Receive** federation messages (so it can audit and remediate).
- **Send** error responses (acknowledging quarantine status).

But:

- **Cannot send** new witnesses.
- **Cannot participate** in consensus.

### §3.6 The witness chain integration

Quarantine and unquarantine events are **never compressed** (per III-ZK-PRUNING.md preservation list). They are forever auditable.

---

## §4. Sybil Resistance (Item 82)

### §4.1 The mandate

Sybil attacks (single attacker creating many fake peers) are resisted via:

1. **Computational cost**: each peer must complete a substantial proof-of-work or proof-of-stake before joining.
2. **Anchor identity**: each peer's identity is bound to its closure-pinned closure root; cloning a substrate identity is detectable.
3. **Cross-peer attestation**: existing peers must vouch for new peers (web of trust).
4. **Periodic re-attestation**: peers must periodically re-prove their identity.

### §4.2 The proof-of-something

Each new peer must complete one of:

- **Proof-of-Work**: compute a Wesolowski VDF over a peer-specific challenge (per III-CRYPTO-AGILITY.md §6.13).
- **Proof-of-Stake**: lock a substantial amount of substrate-recognized "stake" (e.g., a closure-pinned token) as collateral.
- **Proof-of-Operator-Vouch**: an existing peer's operator vouches for the new peer (signs a directive).

The choice depends on federation policy; it's closure-pinned.

### §4.3 The peer-vouching

Existing peers can vouch for new peers via:

```iii
cycle vouch_for_new_peer(new_peer_info: PeerInfo) -> Witness
    @ring(R0)
    @hexad(PEER_VOUCH)
    @cap(federation<vouch>)
```

Vouches are themselves witnessed; the operator can audit vouching patterns. Excessive vouching from a single operator can flag a Sybil attack (concentration anomaly).

### §4.4 The federation policy

The federation's Sybil-resistance policy (which proofs are accepted, what stakes, etc.) is closure-pinned at substrate genesis. Modifying requires Tier-3 + Anchor cosignature.

### §4.5 The detection

Sybil-attack patterns are detected via:

- **Concentration**: many new peers vouched by a single operator.
- **Identical fingerprints**: peers with similar silicon fingerprints.
- **Temporal clustering**: many new peers joining at the same time from the same network.

Detection emits compromise.high; quarantine follows per §3.

---

## §5. Eclipse-Attack Resistance (Item 83)

### §5.1 The mandate

Eclipse attacks (attacker isolates a victim peer's network view; victim sees only attacker-controlled "peers") are resisted via:

1. **Random peer selection**: each peer randomly selects which others to gossip with (random subset of cell members).
2. **Cross-region peering**: peers maintain connections to multiple regions, not just their local region.
3. **Cryptographic anchor**: the victim peer's closure root is verifiable independently; an attacker cannot forge the substrate identity.
4. **Periodic identity refresh**: peers periodically re-verify their network view.

### §5.2 The random peer selection

```iii
fn select_gossip_targets(local_peers: [PeerId], gossip_count: u32) -> [PeerId] {
    // VDF-output + closure-root + tick-time ⇒ deterministic but unpredictable selection.
    let seed = xor(VDF_OUTPUT, CLOSURE_ROOT, TICK_TIME)
    let prng = ChaCha20::from_seed(seed)
    return local_peers.random_subset(gossip_count, prng=prng)
}
```

### §5.3 The cross-region peering

Each peer maintains connections to peers in **N other regions** (default N = 3). This ensures:

- The victim peer hears constitutional amendments propagating from any region.
- Eclipse attacks cannot block the victim from receiving non-local consensus.

### §5.4 The identity refresh

Periodically (every 10 minutes default), each peer:

1. Queries a random subset of other peers for their closure-root attestations.
2. Verifies the attestations match the peer's own closure-root.
3. If a peer has conflicting closure-root, it is flagged.

### §5.5 The attack detection

Eclipse-attack patterns:

- All received peer-info messages claim closure roots that don't match the substrate consensus.
- Network-route traceroute shows all federation traffic going through one or two hops (eclipse vector).
- Peer-info attestation rate is too low (no responses from non-local peers).

Detection emits compromise.high; the operator is alerted; the substrate switches to **conservative mode** (refuses new federation operations until eclipse is cleared).

---

## §6. Federation Network-Partition Recovery (Item 84)

### §6.1 The mandate

Network partitions (regional failures, cross-region link disruptions) leave the federation in an inconsistent state. Recovery:

1. **Each region operates independently** during partition.
2. **No constitutional amendments** are committed during partition (Tier-3 requires unanimous quorum which cannot be achieved).
3. **Local cell + district + region operations continue** normally.
4. **Witness chains diverge** during partition: each region accumulates its own witnesses.
5. **Reconciliation** upon re-merge: the substrate aggregates per-region chains.

### §6.2 The partition detection

A partition is detected when:

- A peer's gossip-target list shrinks suddenly (eclipse-like, but at the cell level).
- Cross-region message latency spikes.
- Quorum messages are not arriving from a region.

### §6.3 The partition mode

Upon detection, the substrate transitions to **partition mode**:

- All Tier-1 (transient) and Tier-2 (host_file) operations continue.
- Federation operations continue within the local region.
- Constitutional operations are **deferred** (waiting for re-merge).
- A `PARTITION_DETECTED_WITNESS` is emitted.

### §6.4 The re-merge protocol

Upon re-merge:

1. All regions exchange chain-head mhashes.
2. Each region computes its **divergence point** with the other regions (where their chains last agreed).
3. Witnesses post-divergence are propagated cross-region.
4. Conflicting witnesses (same predecessor mhash, different content) are resolved per a closure-pinned rule (e.g., "earliest timestamp wins" or "majority-region wins").
5. A reconciliation witness is emitted documenting the merge.

### §6.5 The reconciliation rules

Per III-CYCLES (cycle ordering) and III-CATALYST §3 (composition), the reconciliation rules are closure-pinned:

```iii
const PARTITION_RECONCILIATION_RULES = {
    // For Tier-1 witnesses: each region's local witnesses are merged independently.
    tier_transient: AcceptAll,
    
    // For Tier-2 witnesses: deduplicate by mhash; conflicts emit compromise.low.
    tier_host_file: DeduplicateByMhash,
    
    // For Tier-3 witnesses: majority-region wins.
    tier_federation: MajorityRegionWins,
    
    // For Tier-4 witnesses: defer until unanimous quorum re-established.
    tier_constitutional: DeferUntilUnanimous,
}
```

---

## §7. Planetary Witness Chain Reconciliation (Item 85)

### §7.1 The mandate

At planetary scale, the **substrate-wide witness chain** is the union of per-region chains, reconciled at re-merge points. The substrate maintains:

- A **regional chain** per region (locally complete).
- A **federation chain** that aggregates per-region chains via reconciliation events.
- The federation chain's identity (R1 composite root) is **periodically computed** from the per-region chains (e.g., once per epoch).

### §7.2 The R1 composite root at planetary scale

```iii
fn compute_planetary_R1(per_region_R1s: [mhash; REGION_COUNT]) -> mhash {
    let merkle_root = merkle_hash_of(per_region_R1s.sorted_by_region_id())
    return merkle_root
}
```

The planetary R1 is a Merkle root over per-region R1s. Each peer in each region can independently verify the planetary R1 by walking the Merkle tree.

### §7.3 The reconciliation cadence

Reconciliation runs:

- Every chronos VDF tick (≈ 10s) for transient and host_file tiers.
- Every epoch boundary for federation tier.
- On unanimous quorum (with Anchor cosignature) for constitutional tier.

### §7.4 The reconciliation witness

```
PLANETARY_RECONCILIATION_WITNESS {
    epoch: u64,
    per_region_R1s: [mhash; REGION_COUNT],
    planetary_R1: mhash,
    timestamp: u64,
}
```

These witnesses are **never compressed** (preservation list).

### §7.5 The Anchor cosignature requirement

For constitutional amendments at planetary scale, the Anchor cosignature is required (per III-FOUNDERS-ANCHOR.md). The Anchor's cosignature on a planetary constitutional amendment:

- Is produced once on the operator's air-gapped machine.
- Propagates through the federation hierarchy (cell → district → region).
- Verified by every peer at every level.
- The R1 update reflects the cosigned amendment.

### §7.6 The closure-pinned reconciliation rule

The reconciliation rule (Merkle hash, sorting order, etc.) is closure-pinned. Modifying requires Tier-3 + Anchor cosignature.

---

## §8. Conformance Criteria

| Code | Criterion |
|------|-----------|
| C-PLAN-1 | The 5-tier hierarchy (transient, host_file, federation, constitutional, planetary) is implemented (per item 79) |
| C-PLAN-2 | Hierarchical structure: cells (~1000 peers), districts (~1000 cells), regions (~1000 districts) |
| C-PLAN-3 | Cell quorum-3-2 selects district leaders correctly |
| C-PLAN-4 | District quorum-3-2 selects region leaders correctly |
| C-PLAN-5 | Leadership rotation is deterministic from VDF output + closure root + epoch |
| C-PLAN-6 | Hierarchical structure is closure-pinned; modification requires Tier-3 + Anchor |
| C-PLAN-7 | Attacker-peer detection identifies all 6 attack patterns per §2.2 |
| C-PLAN-8 | Federation-wide signal aggregation escalates per quorum thresholds |
| C-PLAN-9 | Quarantine cycle correctly removes peer from federation |
| C-PLAN-10 | Quarantined peer cannot send witnesses; can receive |
| C-PLAN-11 | Quarantined peer's historical witnesses marked compromise.high |
| C-PLAN-12 | Sybil resistance: new peer must complete proof (PoW, PoS, or vouch) |
| C-PLAN-13 | Federation Sybil-resistance policy is closure-pinned |
| C-PLAN-14 | Eclipse attack detection identifies isolation patterns per §5.5 |
| C-PLAN-15 | Cross-region peering: each peer maintains connections to ≥3 other regions |
| C-PLAN-16 | Random peer selection is deterministic from VDF + closure root + tick time |
| C-PLAN-17 | Partition detection identifies network failures per §6.2 |
| C-PLAN-18 | Partition mode defers constitutional operations |
| C-PLAN-19 | Reconciliation rules apply per tier per §6.5 |
| C-PLAN-20 | Planetary R1 composite root computed via Merkle tree of per-region R1s |
| C-PLAN-21 | Constitutional amendments at planetary scale require Anchor cosignature |
| C-PLAN-22 | Reconciliation witnesses are in the preservation list of ZK-rollup compaction |

---

## §9. Final Statement

Planetary scale is the architectural commitment that III scales to billions of peers without losing its R1-sealed semantic guarantees. The hierarchical federation structure, the Sybil-resistance discipline, the eclipse-attack resistance, the partition recovery, and the planetary witness reconciliation enable the substrate to operate as a single coherent computational substrate at any scale.

Throughout, the Founder's Anchor remains the operator's single closure-pinned veto authority. No quorum, no federation, no peer collective can circumvent the Anchor. The hierarchical federation organizes peer interaction; it does not dilute Anchor authority.

Counter-defensive measures isolate malicious peers; reconciliation merges divergent chains; planetary R1 aggregates per-region identity; Anchor cosignature gates constitutional amendments at any scale.

This is the answer to items 79-85. Wave 9 is the realization that III's terminal nature includes **planetary-scale operation** — but the operator's structural sovereignty is preserved at every scale.

*Wave 9 deliverable. Sealed against the C:\\CHARIOT closure of 2026-05-03. Updated only via Catalyst-promoted append (new hierarchical levels, new attack patterns) or Tier-3 amendment (federation hierarchy structure).*
