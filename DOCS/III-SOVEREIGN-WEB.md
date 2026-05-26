# III-SOVEREIGN-WEB.md — Sovereign Web Protocol Architectural Mandate

**Document Identity:** SOVEREIGN-WEB / Architectural Mandate / Wave 7 / Items 54-62
**Status:** **DERIVATIVE — NOT part of the R1 sealed set, but architecturally binding on every Wave-7+ implementation.** This document specifies the architectural mandate for III's network protocol: the substrate's federation extension across the network without dependence on TCP/HTTP/REST or operator configuration, while preserving witnessed continuity, Anchor invariance, and Trinity-gated exposure.
**Version:** 1.0 — 2026-05-03 (Wave 7)
**Sources:** All 15 R1-sealed specs; III-PORTABILITY.md; III-FOUNDERS-ANCHOR.md; III-OBSERVABILITY.md; III-LEGACY-INGESTION.md; III-POLYMORPHIC-DATA.md; Stateful Neumann §3.3 (network coexistence).
**Cluster integrated:** items 54 (IOMMU-mediated transport), 55 (witness-tagged packets), 56 (peer discovery), 57 (Trinity-tier-gated outbound), 58 (witness-signature trailer RFC 4302 AH-style), 59 (cross-peer chain replication), 60 (federation-tier protocol layering), 61 (NDIS/equivalent coexistence), 62 (network-level cap discipline).

---

## §0. Preamble — Federation as Network Protocol

Conventional distributed systems federate over TCP/HTTP/REST. Each peer has an explicit endpoint configuration (hostname, port, certificate); messages are framed in HTTP; the protocol is firewall-able, port-blockable, network-administrator-controllable. Federation is *visible*; *configurable*; *interruptible* by anyone with network-management authority.

III rejects this model. **The federation IS the network protocol.** III's federation extends across the network using legitimate IP-layer extension fields (IP options, IPv6 extension headers, TCP/UDP options) — opaque to non-III observers, transparent between III peers, requiring zero explicit configuration.

The architecture (per Stateful Neumann §3.3 / S18):

1. III mediates the network adapter's DMA via IOMMU.
2. Outbound packets from III-originated cycles are augmented with a witness-signature trailer.
3. Inbound packets are inspected; witness-signed packets route to the federation layer; non-signed packets pass through to the host OS normally.
4. Two III machines on the same network discover each other transparently.
5. Their federation traffic looks like normal IP traffic with extra options to non-III observers; opaque to all packet sniffers.
6. III does not attack other systems; III does not exfiltrate; III's outbound payload tier is Trinity-gated.

This document specifies:

1. **§1** — IOMMU-mediated network transport (item 54)
2. **§2** — Witness-tagged packet formation (item 55)
3. **§3** — Witness-signature trailer (item 58)
4. **§4** — Federation peer discovery (item 56)
5. **§5** — Trinity-tier-gated outbound packets (item 57)
6. **§6** — Cross-peer witness chain replication (item 59)
7. **§7** — Federation-tier protocol layering (item 60)
8. **§8** — NDIS / equivalent coexistence (item 61)
9. **§9** — Network-level cap discipline (item 62)
10. **§10** — Conformance criteria
11. **§11** — Final statement

---

## §1. IOMMU-Mediated Network Transport (Item 54)

### §1.1 The mandate

III's network access flows through the IOMMU (per III-PORTABILITY.md §4). Specifically:

- Each network adapter's BDF is registered in the IOMMU device table.
- IOMMU IOPT (IO Page Table) maps the adapter's DMA range through a substrate-controlled buffer pool.
- Inbound DMA writes (received packets) land in the substrate's pool first; substrate inspects, then forwards to host OS or federation layer.
- Outbound DMA reads (transmit packets) come from the substrate's pool; substrate has already augmented with witness signatures (where applicable).

### §1.2 The buffer pool

The substrate allocates a NUMA-local, NPT-class `NETWORK_BUFFER_POOL` per network adapter:

- Size: configurable (default 64 MB per 10 Gbit adapter).
- Class trit: NETWORK_BUFFER_POOL (cannot be accessed except via mediated cycles).
- MPK key: dedicated per-adapter (isolation between adapters).

### §1.3 The intercept hooks

- **Inbound DMA write**: when the adapter writes a received packet to the buffer pool, the substrate's IOMMU fault-handler (or polled-mode handler for high-throughput adapters) is invoked. The handler inspects the packet's header.
- **Outbound DMA read**: before the adapter reads a transmit packet, the substrate has already augmented the packet (witness signature trailer) and placed it in the buffer pool.

### §1.4 The cross-architecture mapping

Per III-PORTABILITY.md §4, IOMMU-mediated transport works across:

- AMD-Zen IOMMU (AMD-Vi)
- Intel VT-d
- ARMv8 SMMU
- RISC-V IOMMU-RVI
- POWER9 IOMMU (PHB)

Each architecture has its specific IOMMU programming code; the substrate's network logic is architecture-agnostic.

### §1.5 The witness emission

Every IOMMU-mediated network event emits a witness:

```
NETWORK_INBOUND_PACKET_WITNESS
NETWORK_OUTBOUND_PACKET_WITNESS  
NETWORK_IOMMU_FAULT_WITNESS  // For DMA violations
```

These are typically high-frequency; eligible for ZK-rollup compaction (per III-ZK-PRUNING.md).

---

## §2. Witness-Tagged Packet Formation (Item 55)

### §2.1 The mandate

Outbound packets from III-originated cycles include a **witness signature trailer**:

```
Standard IP packet:
+---------------------+---------------------+----------------+
|   IP Header (20 B)  | Transport (TCP/UDP) | Payload        |
+---------------------+---------------------+----------------+

III witness-tagged packet (IPv4):
+---------------------+---------------------+----------------+----------------+
|   IP Header (20 B)  | IP Option (W-Sig)   | Transport      | Payload        |
+---------------------+---------------------+----------------+----------------+

III witness-tagged packet (IPv6):
+---------------------+---------------------+---------------------+----------------+
|   IPv6 Header (40 B)| Hop-by-Hop Ext Hdr  | Transport (TCP/UDP) | Payload        |
+---------------------+---------------------+---------------------+----------------+
   (with III-Witness option)
```

### §2.2 The IPv4 IP option

The III witness uses **IPv4 Option Type 0xCC** (reserved for experimental use, per RFC 4727).

```
Octet  0      1      2      3      4      5      ...
+------+------+------+------+------+------+------+
| 0xCC | Len  | Witness mhash[0..30]              |
+------+------+------+------+------+------+------+
```

Length: 35 bytes (option type 1 + length 1 + 32-byte witness mhash + 1 byte alignment).

Total IP option length: 36 bytes (per IPv4 option alignment requirements).

### §2.3 The IPv6 Hop-by-Hop extension header

The III witness uses **IPv6 Option Type 0xCC** with **Action 11** (Discard if option not recognized; per RFC 8200).

```
Octet  0      1      2      3      4      5      6      7      ...
+------+------+------+------+------+------+------+------+------+
| Next | Len  | Type | Len  | Witness mhash[0..30]              |
| 0    | 0    | 0xCC | 32   |                                   |
+------+------+------+------+------+------+------+------+------+
```

### §2.4 The witness mhash

The witness mhash references a witness in the substrate's audit chain. The witness body contains:

- The packet's source cycle (which III cycle generated this packet).
- The packet's destination peer (which III peer should consume).
- The packet's tier (which Trinity tier authorized this transmission).
- The packet's contents mhash.

### §2.5 The non-III observer view

Non-III observers see the IP option but cannot interpret it. The packet otherwise looks completely normal. Common firewalls allow IP options 0xCC by default (it's reserved for experimental use); adversarial firewalls may strip the option (in which case the packet falls back to a non-federated mode and the substrate emits compromise.low).

---

## §3. Witness-Signature Trailer (Item 58)

### §3.1 The mandate

Beyond the IP option header, III packets may include an **IPSec AH (Authentication Header) trailer** per RFC 4302:

```
+---------------------+---------------------+----------------+---------------------+
|   IP Header         | Transport           | Payload         | AH Trailer          |
+---------------------+---------------------+----------------+---------------------+
```

The AH trailer:

```
+----------+----------+----------+--------------------+
| Next Hdr | Length   | Reserved | SPI (32 bits)     |
+----------+----------+----------+--------------------+
| Sequence Number (32 bits)                          |
+--------------------+--------------------+------------+
| Authentication Data (variable; III-aware: 32 B HMAC)|
+--------------------+--------------------+------------+
```

The Authentication Data is **HMAC-SHA-256** (or HMAC-SHAKE-256 post-quantum) over:

```
authdata = HMAC(sub_key, packet_body || witness_mhash || source_peer_id || destination_peer_id || timestamp)
```

The sub_key is per-CPU (per III-CYCLES §4.4) for the substrate's cycle that originated the packet.

### §3.2 The cross-suite agility

Per III-CRYPTO-AGILITY.md, the AH algorithm is suite-aware. The packet includes a 1-byte suite-identifier byte in the SPI field:

```
SPI [31:24]: Suite ID (0x01 = pre-quantum, 0x10 = PQC, 0x30 = hybrid)
SPI [23:0]:  Per-peer security parameter index
```

### §3.3 The verification

At the destination:

1. The peer extracts the IP option (witness mhash) and AH trailer.
2. The peer looks up the witness in its local audit chain replica.
3. The peer verifies the AH HMAC under the suite identified in SPI.
4. If valid, the packet is routed to the substrate's federation layer.
5. If invalid, the packet is dropped; emit `NETWORK_INVALID_AH_WITNESS` (compromise.low).

### §3.4 The replay protection

The Sequence Number in AH provides replay protection: each packet's SeqNum is monotonically increasing per (source, destination) pair. Out-of-order packets within a small window are accepted; older packets are dropped.

### §3.5 The non-III observer view

To an attacker without the sub_key, the AH HMAC is indistinguishable from random bytes. The attacker cannot:

- Forge a witness-tagged packet (lacks the sub_key).
- Replay a captured packet (replay protection).
- Detect that the packet contains witness-tagged content (it looks like generic IPSec traffic).

---

## §4. Federation Peer Discovery (Item 56)

### §4.1 The mandate

Two III machines on the same network discover each other transparently:

- No explicit hostname configuration.
- No DNS entry.
- No port assignment.
- No certificate exchange.

The discovery mechanism: III machines emit periodic **discovery beacons** as witness-tagged broadcasts. Receiving III machines recognize the beacons and establish federation.

### §4.2 The beacon

Discovery beacons are UDP broadcasts on port 5353 (mDNS, common firewall pass-through) with a witness-tagged trailer:

```
+----------+---------------------+-------------------+-------------------+
| UDP Hdr  | mDNS-style payload  | III IP Option     | III AH Trailer    |
+----------+---------------------+-------------------+-------------------+
```

The mDNS-style payload contains a service-name `_iii-fed._udp` (registered placeholder per IANA application). Non-III observers see a normal mDNS broadcast.

### §4.3 The peer-info exchange

Upon recognition, III peers exchange a **peer-info** message:

```iii
schema PeerInfo {
    peer_id: PeerId,                    // Hashed from FOUNDERS_ANCHOR_PUBLIC_KEY + silicon_fingerprint
    closure_root: mhash,
    r1_composite_root: mhash,
    drtm_quote_chain_head: mhash,
    architecture: ArchitectureKind,
    active_cryptographic_suite: u64,
    federation_tier_max: TierLevel,     // Highest tier this peer admits
    timestamp: u64,
    signature: Signature,               // Under active suite
}
```

### §4.4 The closure-root match check

Peers verify their closure-roots match. Same closure root → same substrate identity; different closure root → different substrate (do not federate; per III-FOUNDERS-ANCHOR.md §8.4).

### §4.5 The architecture diversity

Federation admits cross-architecture peers (per III-PORTABILITY.md §12.4). A peer's architecture is recorded in its peer-info; the federation can analyze architecture distribution for resilience.

### §4.6 The discovery witness

```
PEER_DISCOVERED_WITNESS {
    peer_info: PeerInfo,
    discovery_method: BroadcastBeacon,
    timestamp: u64,
    federation_admitted: Bool,          // True if closure root matches
}
```

---

## §5. Trinity-Tier-Gated Outbound Packets (Item 57)

### §5.1 The mandate

Per Stateful Neumann §3.3 / §3.5: **outbound packet content is gated by the originating cycle's tier**:

| Tier | Federated to peers? | Trinity gate required? |
|------|---------------------|------------------------|
| transient | No | None |
| host_file | Optionally (configurable) | Operator quorum-3-2 if federated |
| federation | Yes | Trinity gate (cap-acquire-class) |
| constitutional | Yes (with Anchor cosignature) | Trinity gate + Founder's Anchor |

### §5.2 The tier-stamping

Each outbound packet's witness includes the tier:

```
NETWORK_OUTBOUND_PACKET_WITNESS {
    cycle_id: CycleId,
    cycle_tier: Tier,
    packet_mhash: mhash,
    destination_peer: PeerId,
    timestamp: u64,
}
```

### §5.3 The Trinity-gate enforcement

For tier ≥ federation, the substrate's Trinity gate (per III-TRINITY) evaluates the convergence point:

- SCBA membership: is the cycle's source admitted?
- ACC Wall-Y: does the cycle's composed delta type-check?
- Trinity Gate: is the operator-signed intent token valid?
- (For constitutional) Founder's Anchor cosignature on the outbound directive.

If any check fails, the packet does not leave the substrate; emit `NETWORK_OUTBOUND_DENIED_WITNESS`.

### §5.4 The tier-tagging in AH

The packet's AH trailer's SPI bits 23..16 record the tier (allows the destination peer to verify the tier without needing to look up the witness):

```
SPI [23:16]: Tier (1=transient, 2=host_file, 3=federation, 4=constitutional)
```

### §5.5 The destination peer's tier acceptance

A destination peer may decline packets at certain tiers. Each peer publishes its `federation_tier_max` in peer-info. Senders respect the maximum; they don't send packets at tiers above the destination's max.

---

## §6. Cross-Peer Witness Chain Replication (Item 59)

### §6.1 The mandate

Federation peers replicate parts of their witness chains across the federation. The replication is:

- **Tier-aware**: only witnesses at the destination's accepted tier are replicated.
- **ZK-rollup-aware**: rollup witnesses are replicated; raw witnesses inside rollups are replicated only if both peers preserve them.
- **Closure-root-aware**: peers with different closure roots do not replicate.
- **Compromise-aware**: compromise witnesses are always preserved (not compressed); replicated to ensure federation-wide observation.

### §6.2 The replication protocol

A new witness is replicated to N peers where N = `XII_FEDERATION_REPLICATION_FACTOR` (default = ⌈log₂ federation_size⌉; minimum 3). The replication uses anti-entropy (gossip) with the witness mhash as the key.

### §6.3 The convergence

Periodically (every chronos VDF tick = ~10s), peers exchange their **chain heads** (the latest BCWL-indexed commit). Disagreements trigger:

- The peer with the higher head (more recent witnesses) sends the witnesses to the lagging peer.
- Witnesses are verified at the receiver before being added to the local chain.

### §6.4 The federation-wide audit chain

Across the federation, the audit chain has multiple **regions** (per peer); each peer's region is its own emission history. Peers replicate cross-region witnesses to other peers per the replication factor.

A federation-wide query (`system.observe.federation_audit(...)`) requires:

- The originating peer's emission history (locally available).
- Replicated witnesses from other peers (queried via the federation peer protocol).

### §6.5 The immutability discipline

A witness, once committed to the audit chain, is immutable. Replication is **append-only**; witnesses are never modified or removed (except via ZK-rollup compaction of qualifying regions).

---

## §7. Federation-Tier Protocol Layering (Item 60)

### §7.1 The mandate

The federation protocol is **layered** by tier:

| Tier | Protocol Layer |
|------|----------------|
| transient | Per-cycle ephemeral witness propagation (UDP, no replication) |
| host_file | Single-peer-target witness propagation (operator-routed; UDP or TCP) |
| federation | Quorum-3-2 broadcast (anti-entropy gossip) |
| constitutional | Quorum-N-N unanimous (byzantine fault-tolerant consensus, minimum 5 peers) |

### §7.2 The tier-1 transient witnesses

Transient-tier witnesses are typically performance-counter updates, ephemeral measurements, JIT compilation events. They propagate to the originating peer's local ring only; not replicated.

### §7.3 The tier-2 host-file witnesses

Host-file-tier witnesses are typically file-system operations, persistent local state. They may be replicated to a configured "replica peer" (e.g., a backup machine) per operator setup.

### §7.4 The tier-3 federation witnesses

Federation-tier witnesses are typically peer-to-peer cycle invocations, federation-wide observability. They are broadcast via gossip; quorum-3-2 acceptance is required for finalization.

### §7.5 The tier-4 constitutional witnesses

Constitutional-tier witnesses (amendments, suite-swaps, anchor rotations) require:

- **Unanimous** quorum acceptance.
- **Founder's Anchor cosignature**.
- **Byzantine fault-tolerant consensus**: tolerates up to (N-1)/3 malicious peers.

### §7.6 The hand-rolled BFT consensus

The substrate's constitutional consensus uses a hand-rolled NIH BFT algorithm (e.g., HotStuff, derived from the 2018 paper by Yin et al.). Forbidden:

- Tendermint, Hyperledger Sawtooth, Hyperledger Fabric
- libBFT, libra-bft (Diem), MysticetiBFT

Required: hand-rolled implementation in `STDLIB/federation/bft_consensus.III` (~3000 LoC) with KAT corpus over synthetic byzantine scenarios.

---

## §8. NDIS / Equivalent Coexistence (Item 61)

### §8.1 The mandate

III's network mediation **does not break** the host OS's network stack. Windows's NDIS, Linux's network stack, macOS's network kit continue to function normally for non-III traffic.

### §8.2 The bypass discipline

For traffic that does not bear an III IP option:

- The IOMMU-mediated DMA passes through to the host OS.
- The host OS's network stack processes normally.
- No witness emission; no Trinity gating; no federation routing.

### §8.3 The III traffic isolation

For traffic that bears an III IP option:

- The packet is intercepted before the host OS sees it.
- The substrate processes via the federation layer.
- The host OS never observes the packet (preserves operating-system semantics).

### §8.4 The host OS's view

To the host OS, the III machine looks like a normal networked machine. The III federation traffic is invisible. Network administrators see normal IP traffic with infrequent option 0xCC entries — generally not blocked, but if blocked, the federation falls back to per-peer policies.

### §8.5 The latency impact

IOMMU mediation adds ~1-2 μs per packet (small constant overhead). On a 10 Gbit link with 1500-byte packets: ~67 packets/μs → ~6.7M packets/sec. The mediation can keep up.

---

## §9. Network-Level Cap Discipline (Item 62)

### §9.1 The mandate

Network operations require capabilities:

| Operation | Required cap |
|-----------|--------------|
| Outbound packet emission | `cap<network_send<destination_peer, tier>>` |
| Inbound packet acceptance | `cap<network_receive<source_peer, tier>>` |
| Federation peer registration | `cap<federation_peer<peer_kind>>` |
| Witness chain replication request | `cap<federation_replicate<peer, region>>` |
| Constitutional amendment broadcast | `cap<federation_constitutional_broadcast>` (Tier-3 + Anchor required to grant) |

### §9.2 The cap-graph integration

Network caps integrate with the standard cap discipline (per III-EFFECTS / III-NEXUS). The cap graph records per-peer authorization.

### §9.3 The cap-revocation

Operator can revoke any network cap at any time. Revocation:

- Atomically blocks future packet emission/acceptance.
- Emits witness recording the revocation.
- Doesn't rollback past traffic (already-sent packets remain in flight).

### §9.4 The cross-peer cap exchange

Peers may grant each other caps. A federation initialization includes:

- `cap<federation_peer<X>>` granted by each peer to its federation members.
- Per-tier caps granted per the federation's policies.

---

## §10. Conformance Criteria

| Code | Criterion |
|------|-----------|
| C-WEB-1 | Network DMA flows through IOMMU-mediated buffer pool (per item 54) |
| C-WEB-2 | Buffer pool is NPT-class isolated; not accessible outside mediated cycles |
| C-WEB-3 | IPv4 witness-option uses IP Option Type 0xCC per §2.2 |
| C-WEB-4 | IPv6 witness-option uses Hop-by-Hop Extension Header per §2.3 |
| C-WEB-5 | Witness mhash references a valid witness in the audit chain |
| C-WEB-6 | AH trailer includes 32-byte HMAC over packet + witness + peer IDs + timestamp |
| C-WEB-7 | AH SPI bits 31..24 record the active cryptographic suite |
| C-WEB-8 | AH SPI bits 23..16 record the originating cycle tier |
| C-WEB-9 | Replay protection rejects packets with old sequence numbers |
| C-WEB-10 | Federation peer discovery uses mDNS-style broadcast on UDP 5353 |
| C-WEB-11 | Peer-info verification: closure-root match, signature valid, drtm-chain-head verifiable |
| C-WEB-12 | Cross-architecture peers federate correctly per III-PORTABILITY.md §12.4 |
| C-WEB-13 | Outbound packet content is Trinity-tier-gated per §5 |
| C-WEB-14 | Constitutional-tier outbound requires Founder's Anchor cosignature |
| C-WEB-15 | Witness chain replication factor ≥ ⌈log₂(federation_size)⌉, minimum 3 |
| C-WEB-16 | Anti-entropy gossip converges within 60 seconds for healthy federations |
| C-WEB-17 | Constitutional consensus uses hand-rolled NIH BFT (HotStuff-derived); no external library |
| C-WEB-18 | BFT tolerates up to (N-1)/3 malicious peers |
| C-WEB-19 | Non-III traffic passes through host OS's network stack unmediated |
| C-WEB-20 | Network operations require corresponding caps; revocation is immediate |

---

## §11. Final Statement

The Sovereign Web Protocol is the architectural commitment that III's federation extends across the network as **a property of the substrate**, not a configurable application protocol. Two III machines discover each other transparently, federate via legitimate IP-layer extension fields, replicate witness chains via gossip, achieve Byzantine consensus on constitutional amendments, and remain opaque to non-III observers.

No firewall configuration. No DNS entry. No certificate exchange. No port assignment. The federation is a property of the substrate's identity (closure root + Anchor pubkey + cryptographic suite); peers with matching identity federate; peers with different identity remain in their own substrates.

The host OS continues to function normally. Non-III traffic flows through the host OS's network stack unmediated. III traffic is invisible to non-III observers; opaque to attackers; verifiable cryptographically by all federation members.

This is the answer to items 54-62. Wave 7 is the realization that III's network protocol is **the substrate's social fabric** — peers connect by being the same substrate, not by being configured to connect.

*Wave 7 deliverable. Sealed against the C:\\CHARIOT closure of 2026-05-03. Updated only via Catalyst-promoted append (new transport layers) or Tier-3 amendment (federation tier structure).*
