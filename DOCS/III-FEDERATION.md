# III-FEDERATION.md — Tier-Gated Outbound & Replication

**Document Identity:** B2 / The Federation Discipline
**Canonical Hash Slot:** R1.B2
**Version:** 1.0 — Final & Sealed
**Date:** 2026-05-03
**Authority:** Canonical. Integrated with III-MODULES.md.

---

## §0. Preamble — What Crosses, And What Does Not

A federated III substrate is a set of peer machines, each running its own III installation, each with its own DRTM-anchored silicon fingerprint, all sharing a witness chain and a closure-pinned set of modules.

The federation must answer one question at every cross-machine boundary: **what may leave this machine, and under what discipline?**

III's answer is **tier-gated outbound**: every value in III carries a `@tier(K)` annotation. Outbound federation messages are admitted only if their tier — the *minimum* tier across all modules involved in the message's creation — passes the per-tier outbound rule.

This is the discipline that prevents a `@tier(transient)` module from accidentally leaking `@tier(constitutional)` data, even though both may live in the same module's namespace.

---

## §1. Tier Model (Enforced)

Four tiers, totally ordered:

| Tier | Name | Mutation Rule | Outbound Rule |
|------|------|----------------|----------------|
| Tier₀ | `transient` | Unrestricted | **Local only** — never federated |
| Tier₁ | `host_file` | Requires `@quorum(3, 2)` (3 peers, 2 must agree) | **Peer pull** — federated on request |
| Tier₂ | `federation` | Requires `@quorum(5, 3)` (5 peers, 3 must agree) + `fragment_replicate` | **Broadcast** — automatically propagated to all peers |
| Tier₃ | `constitutional` | Only via `amend.apply` at constitutional tier | **Full quorum** — unanimous federation acceptance required |

The order is `transient < host_file < federation < constitutional`. A value at lower tier may be lifted to a higher tier (with the appropriate mutation rule); it may not be silently demoted.

---

## §2. Tier-Gated Outbound (The Safety Rule)

### §2.1 The Judgment

```
Γ ⊢ message m
Γ ⊢ min_tier = minimum_tier_of_modules_in(m)
Γ ⊢ outbound_allowed(min_tier)
─────────────────────────────                                       (Tier-Gated Outbound)
Γ ⊢ m may be sent to federation
```

`minimum_tier_of_modules_in(m)` walks every module that contributed a witness to `m`'s reduction chain and returns the **minimum** tier among them. This is the strictest discipline — even if 99 of 100 contributing modules are `@tier(federation)`, a single `@tier(transient)` participant lowers the message's effective tier to `transient`, and the message is **not** federated.

### §2.2 What This Prevents

- A `@tier(transient)` module **cannot** accidentally leak constitutional data: if a constitutional value enters a transient module's reduction chain, the message's min-tier becomes `transient` and the federation outbound is refused.
- A buggy module promoted to `@tier(federation)` cannot accidentally upgrade transient data: tier propagation is **monotonically downward** (the *minimum* tier wins for outbound).

### §2.3 The Outbound Decision Path

```
1. Compose the federation message m (cycle invocation, witness segment, promotion record, DRTM quote, etc.).
2. Walk the contributing modules; collect their declared @tier values.
3. Take the minimum.
4. Apply the outbound rule:
   - transient → reject (drop the federation message; emit XII_STEP_KIND_FED_OUTBOUND_REJECT_TIER0)
   - host_file → admit only on peer-pull request (lazy)
   - federation → admit broadcast (eager); apply quorum rules
   - constitutional → admit only with unanimous quorum + amend.apply
5. If admitted: emit XII_STEP_KIND_FED_OUTBOUND with the tier in the witness.
```

---

## §3. Integration with Modules

Module fusion (III-MODULES.md §10) and complementarity decisions respect tier boundaries:

- A Tier₃ module can only fuse with another Tier₃ module. (A fused module's tier is the minimum of its parts; if the parts span tiers, the fused module is at the lower tier and would lose constitutional privileges.)
- Cross-tier fusion **requires an explicit `amend.apply`** cycle at constitutional tier.

This rule preserves the **monotonicity of tier**: tiers can only be raised through explicit constitutional action, never accidentally compromised through opportunistic optimization.

---

## §4. Quorum Specifications

### §4.1 Quorum-3-2 (Tier₁ Mutation)

Three peers participate; two must agree. The agreement is signed by each peer's DRTM-rooted federation key. The quorum signature is appended to the witness.

### §4.2 Quorum-5-3 (Tier₂ Mutation)

Five peers participate; three must agree. Used for federation-tier broadcasts (e.g., a Catalyst-promoted cycle that becomes available substrate-wide).

### §4.3 Unanimous Quorum (Tier₃ Mutation)

All federation members must agree. Used for constitutional changes — adding a sealed-call slot, growing the universe ladder, modifying the rate caps, or any other change to constitutional constants.

### §4.4 Quorum Failure

If quorum fails (insufficient peers, dissenting peers, signature verification fails), the federation message is **dropped** and `XII_STEP_KIND_FED_QUORUM_FAIL` is emitted. The change is not applied; the substrate continues operating with the prior state.

---

## §5. Federation Transport (Network Coexistence)

The federation transport is layered over normal IP traffic with witness-signature trailers (RFC-4302 Authentication Header style). Two III machines on the same network discover each other via witness-tagged broadcast packets; non-III observers see only ordinary IP traffic.

The mechanism (handled in `STDLIB/federation/transport.III`):

1. III's IOMMU IOPT mediates the network adapter's DMA (per the existing CHARIOT/XII federation transport).
2. Outbound packets from III-originated processes are augmented with a witness-signature trailer.
3. Inbound packets are inspected pre-NDIS; witness-signed packets are routed to the federation layer; non-signed packets pass to Windows normally.
4. Discovery: two III machines on the same network see each other's witness-tagged packets and federate transparently.

The full transport spec is in CHARIOT's prior LOGOS plan §3.3 and is preserved verbatim in III's federation discipline.

---

## §6. Closure Identity Rule (R1.B2)

R1.B2 = `SHA-256(canonical_byte_form(this_file))`.

---

## §7. Conformance Criteria

- **C-FED-1.** Tier-gated outbound (§2) is enforced; messages with `min_tier = transient` are never federated.
- **C-FED-2.** Cross-tier fusion is rejected without explicit `amend.apply`.
- **C-FED-3.** Quorum signatures verify against DRTM-rooted federation keys.
- **C-FED-4.** Federation transport via IOMMU mediation does not disrupt non-III network traffic.
- **C-FED-5.** Unanimous-quorum constitutional changes broadcast successfully and trigger DRTM relaunch on all peers.

---

## §8. Final Declaration

Federation in III is **bounded by tier**, **gated by quorum**, **witnessed at every transition**, and **transparent on the wire**. No data leaves a machine without passing the tier gate; no machine accepts data without verifying its quorum signature.

**III-FEDERATION.md — the federation discipline that lets two III machines speak to each other safely, and that lets any peer audit the whole.**

*Sealed. R1.B2 = SHA-256(canonical_byte_form(this_file)).*
