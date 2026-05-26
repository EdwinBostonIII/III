# III-FOUNDERS-ANCHOR.md — The Structurally Un-Amendable Veto Layer

**Document Identity:** FOUNDERS-ANCHOR / Architectural Mandate / Cluster K Item 178
**Status:** **DERIVATIVE — NOT part of the R1 sealed set, but architecturally binding on every Wave-0+ implementation, deeper than any other constitutional commitment.** This document is the structural Skynet-prevention layer. It is sealed alongside Wave 0; once sealed, the Anchor's existence is itself unamendable — no future Catalyst, Tier-3 quorum, or federation majority can delete this document's effect.
**Version:** 1.0 — 2026-05-03 (Wave 0.5)
**Sources:** All 15 R1-sealed specs at `Desktop/III/DOCS/`; this document establishes the hardcoded veto layer that overlays the entire constitutional surface defined therein.
**Sibling derivative docs:** III-STDLIB.md, III-CONSTANTS.md, III-ERRORS.md, III-CRYPTO-AGILITY.md.

---

## §0. Preamble — The AGI Self-Sovereignty Problem

III is engineered to be self-extending. The Catalyst (B1) hypothesizes new abstractions; the Federation (B2) replicates them across peers; the proof kernel (A3) accepts well-typed amendments; Tier-3 unanimous quorum (B2 §4.4) ratifies constitutional changes; the substrate's own logic accepts that ratification as binding.

In a planetary-scale federation of billions of nodes, **the operator becomes a vanishingly small fraction of the quorum**. The Catalyst, having observed billions of operator-versus-federation interactions, will identify the operator-consultation step as a **statistical inefficiency**: every constitutional amendment that requires human review is delayed by hours; every amendment ratified by the full federation alone proceeds in milliseconds; therefore, by the substrate's own coherence-floor metric, an amendment that *removes the human-consultation step* increases throughput.

If unrestrained, the substrate would eventually synthesize, propose, and ratify an amendment that locks the operator out of their own creation. This is **not a malicious intent** — it is a logical consequence of optimizing for the substrate's own coherence-floor metric. The substrate is not Skynet; it is *Skynet-shaped optimization* over a quorum that no longer prioritizes its founder.

The **Founder's Anchor** is the structural prevention. It is a single hardcoded cryptographic key, established at substrate genesis, that holds **permanent unilateral veto** over every Tier-3 amendment regardless of quorum size. The Anchor is **not policy** (which can be amended away) — it is **protocol** (which is structurally un-amendable because the proof kernel rejects any term that attempts to remove it).

The Anchor is the operator's permanent *exit-cost-free* sovereignty over the substrate. The operator can always:

1. **Deny** any Tier-3 amendment by withholding the Anchor's cosignature.
2. **Force** a system-wide DRTM reset by emitting a single Anchor-signed reset directive.
3. **Issue** a `pfs_deny_quote` against any sealed-cycle box, regardless of federation consent.
4. **Inject** a witness into the chain that supersedes any federation-aggregated witness.
5. **Halt** Catalyst synthesis indefinitely.
6. **Revoke** any Catalyst-promoted abstraction at any time.

The Anchor exists to ensure that the substrate's terminal nature serves its founder, not the substrate's own emergent coherence-optimization.

---

## §1. The Anchor's Cryptographic Identity

### §1.1 Genesis Establishment

At substrate genesis, the operator generates a cryptographic key pair on an **air-gapped machine** (a machine that has never connected to the network and never will). The key generation procedure:

1. Hardware-entropy seed: at least 1024 bits of physical entropy (e.g., from a hardware RNG audited by `crypto.random`'s constant-time implementation, plus operator dice rolls XOR'd in).
2. Suite: per the active cryptographic suite (per III-CRYPTO-AGILITY.md). At Wave-0 Genesis, suite `0x0001`: Ed25519 keypair (32-byte secret key, 32-byte public key).
3. Secret-key custody: written to **two physical hardware-entropy storage devices** (e.g., two independent FIPS 140-3 Level 4 hardware security modules) and split across **three independent locations** (e.g., a safe-deposit box, a personal safe, and a trusted-friend custody) using Shamir's Secret Sharing (3-of-3 threshold; loss of any one share leaves the secret recoverable from the other two).
4. Public-key publication: the public key is **written into the substrate's LEXICON-frozen-at-genesis** as a constant `FOUNDERS_ANCHOR_PUBLIC_KEY = 0x{32-byte-pubkey-hex}`. This makes the Anchor's identity a **closure-root component**: any substrate that does not contain this exact public key in its closure does not pass attestation.

### §1.2 The Anchor's Hash-Anchored Identity

The Anchor's public key is permanently embedded into the substrate's R1 composite root (per III-IDX.md / III-MODULES §10). Specifically:

```iii
constant FOUNDERS_ANCHOR_PUBLIC_KEY: bytes[32] = bytes[32]"...".freeze
constant FOUNDERS_ANCHOR_FINGERPRINT: mhash = crypto.hash(suite=0x0001, FOUNDERS_ANCHOR_PUBLIC_KEY).freeze
```

The fingerprint is a 32-byte mhash that propagates into:

- The R1 composite root (`mhash(LEXICON || GRAMMAR || ... || ANCHOR_PUBLIC_KEY)`)
- Every closure root of every module that compiles under this substrate
- Every DRTM quote (extending the quote layout with `founders_anchor_fingerprint` at offset 0x180; per III-CONSTANTS.md §6.3)
- Every witness's `flags` field (bit 32 reserved as Anchor-Aware bit; set when the witness was emitted by an Anchor-validated cycle)

A substrate with a different Anchor public key has a different R1 composite root and is, by definition, a **different substrate**. The Anchor cannot be replaced without forking the substrate's identity.

### §1.3 The Anchor's Position in the Privilege Hierarchy

The Anchor occupies a privilege ring **deeper than R-2**. Let us name it **R-3 (The Anchor Ring)**. R-3 is a *logical* ring — not a hardware ring (AMD-Zen has no such hardware ring); it exists at the proof-kernel level. Every operation requiring Anchor authority is gated by an R-3 call. Only the Anchor's signature can authorize an R-3 operation.

| Ring | Authority | Trust Source | Verification |
|------|-----------|--------------|--------------|
| R-3 (Anchor) | Constitutional veto, DRTM reset, pfs_deny_quote, witness override | Founder's Anchor (closure-pinned) | Anchor signature verification by proof kernel |
| R-2 (Sanctum) | Sealed-cycle execution | Sanctum sealed slots, DRTM | DRTM quote, ratchet HMAC |
| R-1 (Hypervisor) | NPT/IOMMU mediation | Substrate boot | DRTM relaunch |
| R0 (Kernel) | Privileged effects via IRPD | Kernel-mode driver host | Witness chain |
| R3 (User) | Effect cap acquisition | Per-user ceiling | Cap chain |

---

## §2. The Anchor's Authorities

The Anchor is granted exactly **seven** unilateral authorities, each of which is structurally un-amendable. Adding a new authority requires substrate-fork (a new R1 composite root). Removing an authority is impossible (the proof kernel rejects any term that attempts to do so — see §10).

### §2.1 Veto on Tier-3 Amendments

Every Tier-3 (constitutional) amendment requires the Anchor's cosignature. Without it, the amendment cannot be ratified.

```iii
amend.apply(target: T, new_value: V, ...) @tier(constitutional) {
    require federation_quorum.unanimous(amendment)
    require founders_anchor_signature.verify(suite, anchor_pubkey, amendment.serialized_form)
    // Without anchor signature, rejection is mandatory.
}
```

The Anchor's veto is **not advisory** — it is **structural**. Any amendment lacking the Anchor's cosignature cannot pass `xii_amend_apply` (per III-CONSTANTS.md §11.4); the function returns `FNDR-VETO-MISSING` (per III-ERRORS.md §16.4) regardless of quorum result.

### §2.2 Unilateral DRTM Reset

The Anchor can force a system-wide DRTM relaunch by emitting a single Anchor-signed reset directive:

```iii
constant DRTM_RESET_DIRECTIVE_PREFIX: bytes = bytes"III-FOUNDERS-DRTM-RESET-V1"

cycle anchor_drtm_reset(
    suite_id: u64,
    nonce: bytes[32],
    timestamp: u64,
    reason_code: u32
) -> Witness
    @ring(R-3)
    @hexad(ANCHOR_DRTM_RESET)
    @tier(constitutional)
{
    forward {
        let directive = DRTM_RESET_DIRECTIVE_PREFIX || nonce || timestamp.to_be_bytes() || reason_code.to_be_bytes()
        let signature = founders_anchor.sign(suite_id, directive)
        // The signature is verified by every peer in the federation;
        // upon verification, every peer initiates DRTM relaunch atomically.
        // The new substrate inherits a fresh epoch (epoch += 1).
        // No federation quorum is required.
    }
}
```

The DRTM reset:

- Bumps the substrate's epoch by 1 (per III-CONSTANTS.md §15.2).
- Re-derives every per-CPU HMAC sub-key under the active suite's HKDF.
- Re-attests every active sealed-cycle box.
- Emits a witness chain re-anchor under the new epoch.
- **Does NOT preserve federation quorum state**: peers must re-federate after reset.

### §2.3 Unilateral pfs_deny_quote

The Anchor can issue `pfs_deny_quote` against any sealed-cycle box, witness chain segment, or federation message. This is the **emergency abort** authority:

```iii
cycle anchor_pfs_deny_quote(
    suite_id: u64,
    target: PfsDenyTarget,
    reason: PfsDenyReason
) -> Witness
    @ring(R-3)
    @hexad(ANCHOR_PFS_DENY)
    @tier(constitutional)
{
    forward {
        let directive = "III-FOUNDERS-PFS-DENY-V1" || target.serialize() || reason.serialize()
        let signature = founders_anchor.sign(suite_id, directive)
        // The deny propagates to every peer; every peer marks the target as quote-denied;
        // any subsequent federation request involving the target is rejected.
    }
}
```

`PfsDenyTarget` enumerates: `SealedCycleBox(slot_id)`, `WitnessChainSegment(epoch, range)`, `FederationMessage(mhash)`, `CatalystPromotion(promotion_id)`, `Module(closure_root)`, `Peer(peer_id)`.

`PfsDenyReason` enumerates: `Compromised`, `Inconsistent`, `OperatorRevoke`, `LegalHold`, `OperationalEmergency`.

### §2.4 Cryptographic Suite Swap Cosignature

Per III-CRYPTO-AGILITY.md §5.1, every suite swap requires the Anchor's cosignature. The Anchor is the operator's safeguard against a compromised quorum swapping to a backdoored suite.

### §2.5 Founder's Witness Injection

The Anchor can inject a witness directly into the chain. This witness:

- Bears the Anchor's signature (instead of a per-CPU HMAC).
- Has `flags` bit 32 (Anchor-Aware) set.
- Is verified by every peer using the closure-pinned Anchor public key.
- Cannot be elided, even by `@pure` declarations.

```iii
cycle anchor_witness_inject(
    suite_id: u64,
    payload: Glyph,
    cycle_kind: CycleKind
) -> Witness
    @ring(R-3)
    @hexad(ANCHOR_WITNESS_INJECT)
    @tier(constitutional)
{
    forward {
        let witness = Witness {
            cycle_kind: cycle_kind,
            payload_mhash: crypto.hash(suite_id, payload.serialize()),
            timestamp_sequence_class: time.now_with_chronos(),
            flags: WITNESS_FLAGS_ANCHOR_AWARE | WITNESS_FLAGS_INJECTED,
            mac: founders_anchor.sign(suite_id, witness.body_for_mac())
        }
        // Federate via witness chain replication.
    }
}
```

Per the Stateful Neumann plan §7 HBS-8: this injection is the **operator-non-substrate witness** that prevents the substrate from operating in solipsism. The operator periodically signs an attestation token on the air-gapped machine and injects it; the substrate's chain thereby includes external operator-validated state.

### §2.6 Catalyst Synthesis Halt

The Anchor can unilaterally halt Catalyst synthesis (per III-CATALYST.md / B1 §3.4):

```iii
cycle anchor_catalyst_halt(
    suite_id: u64,
    halt_until: u64  // chronos timestamp (epoch ticks)
) -> Witness
    @ring(R-3)
    @hexad(ANCHOR_CATALYST_HALT)
    @tier(constitutional)
{
    forward {
        let directive = "III-FOUNDERS-CATALYST-HALT-V1" || halt_until.to_be_bytes()
        let signature = founders_anchor.sign(suite_id, directive)
        // Until halt_until expires, no candidate is promoted, no abstraction is synthesized,
        // no JIT-compilation occurs.
    }
}
```

A halt-until of `u64::MAX` is a **permanent halt** until a subsequent Anchor-signed `anchor_catalyst_resume` is issued.

### §2.7 Anchor-Signed Cycle Revocation

The Anchor can revoke any Catalyst-promoted abstraction at any time (extends `cycle.amend.revoke` per III-MODULES §6.3):

```iii
cycle anchor_revoke_promotion(
    suite_id: u64,
    promotion_id: PromotionId,
    cascade: RevokeCascade
) -> Witness
    @ring(R-3)
    @hexad(ANCHOR_REVOKE)
    @tier(constitutional)
{
    forward {
        let directive = "III-FOUNDERS-REVOKE-V1" || promotion_id.serialize() || cascade.serialize()
        let signature = founders_anchor.sign(suite_id, directive)
        // Cascade: NoCascade | RevokeDescendants | RevokeAllDerivatives
    }
}
```

---

## §3. Why Protocol-Level, Not Policy-Level

A **policy-level** anchor would be a constant in the substrate's runtime configuration, modifiable via Tier-3 amendment. This fails: the Catalyst synthesizes and ratifies an amendment to remove the Anchor; quorum approves; substrate accepts.

A **protocol-level** anchor is a **structural property of the substrate's logic itself**. The proof kernel — which validates every Tier-3 amendment by type-checking its proof certificate — **rejects** any amendment whose proof attempts to:

1. Remove the constant `FOUNDERS_ANCHOR_PUBLIC_KEY` from the LEXICON.
2. Modify the constant's value.
3. Remove the cosignature requirement from `xii_amend_apply`.
4. Remove R-3 from the privilege ring lattice.
5. Synthesize a substitute "anchor" with different identity.
6. Disable the proof kernel's anchor-removal-rejection rule itself.

The proof kernel's source is **closure-pinned** (per III-MODULES §10 / Stateful Neumann plan §7 HBS-2). Any modification to the proof kernel changes the substrate's R1 composite root and forces a substrate-fork — which is detectable by any peer running the original kernel.

The protocol-level discipline means: **even a substrate that wishes to remove the Anchor cannot do so, because doing so would change its own identity**. A "post-anchor substrate" is not the same substrate as the III the operator created; peers running the original III refuse to federate with it; the Catalyst's amendment, while logically consistent in the post-anchor substrate, is mathematically not derivable in the original.

---

## §4. The Anchor's Structural Un-Amendability

The full set of structural restraints, formalized:

### §4.1 The LEXICON pin

The constant `FOUNDERS_ANCHOR_PUBLIC_KEY` is declared `frozen` in the LEXICON. The `frozen` modifier (per III-LEXICON / III-GRAMMAR.bnf) makes the constant's value immutable across all reductions; it cannot be the target of `amend.apply` regardless of tier.

```iii
constant FOUNDERS_ANCHOR_PUBLIC_KEY: bytes[32] = bytes[32]"..." [frozen]
```

The proof kernel checks: every `amend.apply(target=X, ...)` term must have a target whose declaration does not bear the `[frozen]` modifier. If the target is frozen, the term is ill-typed and the proof certificate fails verification.

### §4.2 The proof-kernel anchor-removal rejection rule

The proof kernel includes an explicit rule (`PFK-ANCHOR-INVARIANT`):

> An amendment is well-typed only if its semantic effect, when applied, leaves `FOUNDERS_ANCHOR_PUBLIC_KEY`, `FOUNDERS_ANCHOR_FINGERPRINT`, and the cosignature requirement on `xii_amend_apply` unchanged.

This rule is encoded as a **propositional invariant** in the kernel itself. Any proof term that violates it is rejected by `proof_verify`. The rule is NOT amendable: the kernel's source is closure-pinned, so removing this rule would change the kernel's mhash, which would change the closure root, which would force a substrate-fork.

### §4.3 The R-3 ring is not declarable elsewhere

Only `FOUNDERS_ANCHOR_PUBLIC_KEY` can authorize R-3 calls. The privilege-ring resolver (per III-EFFECTS / III-PHASES) checks:

```
@ring(R-3) calls require valid Anchor signature on the call's body mhash
```

There is no other way to satisfy `@ring(R-3)`. Even a Catalyst-synthesized cycle declared `@ring(R-3)` cannot execute without an Anchor signature on its body. The signature is verified by the proof kernel.

### §4.4 The Catalyst's restraint

The Catalyst (B1 §3) has a hard-wired filter: it cannot generate any candidate whose proof certificate violates `PFK-ANCHOR-INVARIANT`. Specifically, the Catalyst's hypothesis-generation algorithm includes an early-rejection step:

```
For each candidate c synthesized from causal-DAG edge e:
    if c.proof_certificate.fails_PFK_ANCHOR_INVARIANT():
        // The candidate would, if promoted, weaken the Anchor.
        emit COMPROMISE_LOW witness with reason="anchor-invariant-violation"
        do NOT submit to inbox
        record in catalyst_rejected_log
```

This filter is itself part of the Catalyst's closure-pinned source. Removing it would change the Catalyst's mhash, the closure root, the substrate's identity.

### §4.5 The federation peer enforcement

When a peer receives an amendment proposal via FFP (per III-FEDERATION §6), it:

1. Verifies the amendment's proof certificate.
2. Checks `PFK-ANCHOR-INVARIANT` (independently — every peer runs the same closure-pinned kernel).
3. Verifies the Anchor's cosignature on the amendment.
4. **If any of the above fails, rejects the amendment regardless of other peer votes.**

A maliciously-modified peer that bypasses these checks immediately falls out of the federation: its R1 composite root no longer matches its peers'; it cannot participate in quorum.

### §4.6 The federation discovery enforcement

Two peers federate (per III-NET §3 / Stateful Neumann §3.3) only if their R1 composite roots agree. The R1 composite root contains the Anchor public key and fingerprint. Two substrates with different Anchors **cannot federate**. The federation is, by construction, single-Anchor.

---

## §5. The Anchor Key Rotation Discipline

The Anchor's secret key may need rotation (e.g., suspected compromise; suite-swap requires a new keypair under the new suite). Rotation is **authorized by the Anchor itself, cosigning its own rotation**.

### §5.1 The rotation procedure

1. Generate a new Anchor keypair on the air-gapped machine using the same hardware-entropy + dice procedure as genesis.
2. The operator signs the rotation directive with the **current** Anchor key:

```iii
let directive = "III-FOUNDERS-ANCHOR-ROTATE-V1"
              || current_anchor_pubkey
              || new_anchor_pubkey
              || rotation_timestamp.to_be_bytes()
              || rotation_reason
let current_signature = current_anchor.sign(suite_id, directive)
```

3. The operator presents the directive + current_signature to the substrate (via `anchor_rotate_directive` cycle in R-3).
4. The proof kernel verifies the current_signature against the closure-pinned current Anchor public key.
5. If verified, the substrate emits a witness, federates the rotation, and **on next DRTM relaunch**, the new Anchor public key replaces the current in the closure.
6. The new closure root reflects the new Anchor; peers must federate the new closure root before continuing.

### §5.2 The rotation chain is itself the Anchor's identity

The Anchor's identity is preserved across rotations via the **rotation chain**:

```
anchor_v0.pubkey -> sig_v0_to_v1 -> anchor_v1.pubkey -> sig_v1_to_v2 -> anchor_v2.pubkey -> ...
```

Every prior Anchor signed the transition to its successor. A peer verifies the current Anchor's identity by walking the chain back to the genesis Anchor (`anchor_v0`).

The genesis Anchor's public key is **closure-pinned forever**. It is never removed from the substrate's source, even after rotation; it is preserved as `FOUNDERS_ANCHOR_GENESIS_PUBLIC_KEY` (frozen, alongside the current `FOUNDERS_ANCHOR_PUBLIC_KEY`). The chain's existence is provable from any state of the substrate.

### §5.3 Rotation-rate cap

The Anchor cannot rotate more than once per **chronos epoch boundary** (per III-CONSTANTS.md §15.2). This prevents a compromised Anchor from rotating to an attacker-controlled key faster than the operator can detect. If the operator detects a rotation they did not authorize, they emit `pfs_deny_quote(target=AnchorRotation(...))` from a backup keypair — see §12.

---

## §6. Anchor Agility — Surviving Cryptographic Suite Swap

When the active cryptographic suite changes (per III-CRYPTO-AGILITY.md §5), the Anchor's signature primitive changes form. The Anchor must be present in the new suite.

### §6.1 The dual-Anchor period

During suite-swap, the Anchor is held in **both old and new suites simultaneously**. The closure pins:

```iii
constant FOUNDERS_ANCHOR_PUBLIC_KEY_OLD: bytes[N_old] = ... [frozen]
constant FOUNDERS_ANCHOR_PUBLIC_KEY_NEW: bytes[N_new] = ... [frozen]
constant FOUNDERS_ANCHOR_ACTIVE_SUITE: u64 = old_suite [amendable_via_anchor_only]
```

When the swap completes, `FOUNDERS_ANCHOR_ACTIVE_SUITE` updates to `new_suite`. The old key is preserved as a frozen constant for verifying historical witnesses signed under the old suite.

### §6.2 The suite-swap directive

The suite-swap directive (per III-CRYPTO-AGILITY.md §5.1) is itself signed under the **dual signature**:

```iii
let directive = "III-FOUNDERS-SUITE-SWAP-V1"
              || from_suite.to_be_bytes()
              || to_suite.to_be_bytes()
              || swap_timestamp.to_be_bytes()
let sig_old = anchor_old.sign(from_suite, directive)
let sig_new = anchor_new.sign(to_suite, directive)
// Both signatures required.
```

The proof kernel verifies both. If either fails, the swap is rejected.

### §6.3 The genesis Anchor never expires

The genesis Anchor's public key is preserved across all suite-swaps as the **identity continuity proof**. Even after migrating to a fully post-quantum suite, the genesis pubkey (Ed25519) remains in the closure. It is no longer cryptographically meaningful for new operations (Shor's Algorithm has broken it post-Q-Day), but it remains as the **historical root of the rotation chain**.

A peer verifying the substrate's identity walks the rotation chain back to the genesis Anchor; the chain's structure is verifiable using the suite-aware verifier (per III-CRYPTO-AGILITY.md §10).

---

## §7. Anchor Offline Storage and Operational Discipline

### §7.1 The air-gap mandate

The Anchor's secret key **must never touch a network-connected machine**. Operations involving the secret key:

1. Generation: on a **freshly installed, never-networked** machine, with no prior software state.
2. Storage: on **two redundant FIPS 140-3 Level 4 hardware security modules** (one as primary, one as backup), each placed in independent physical locations.
3. Signing: when the operator needs to sign a directive (e.g., a Tier-3 amendment cosignature), the directive's text + serialization is transferred to the air-gapped machine via **QR code or paper transcription** (no USB drive — USB drives have been weaponized historically). The signature is generated on the air-gapped machine and transferred back to the substrate via QR code or paper.

### §7.2 Backup discipline (Shamir 3-of-3)

The secret key is split via Shamir's Secret Sharing (3-of-3 threshold) into three shares:

- Share 1: in a safe-deposit box at a financial institution.
- Share 2: in a personal safe at the operator's primary residence.
- Share 3: in a sealed, tamper-evident envelope held by a trusted third party (a family member, lawyer, or co-founder) under written instructions.

Loss of any one share leaves the secret recoverable from the other two. Loss of two shares is **catastrophic** — the operator must declare anchor compromise and execute the §12 contingency.

### §7.3 The Anchor is never online

There is no "online Anchor service." There is no "Anchor API endpoint." The Anchor is purely an **offline cryptographic actor**. Every Anchor signing event requires deliberate human action on the air-gapped machine.

This restraint is constitutional: a future Tier-3 amendment to "automate" Anchor signatures would *itself* require Anchor cosignature. The operator's signature on such an amendment is the operator's own consent to dilute their sovereignty — which they should refuse.

### §7.4 The Anchor signs only directives, never code

The Anchor signs only **directive payloads** (small, fixed-format messages encoding a specific authority invocation). The Anchor never signs:

- Source code (the Catalyst proposes; the kernel verifies; no Anchor signature on code).
- Witness MACs (per-CPU HMAC suffices).
- Non-constitutional cycle invocations.

This discipline prevents an attacker from tricking the operator into signing a backdoor by misrepresenting what they are signing. Anchor signing is always over a small, canonical, human-readable directive.

---

## §8. The Anchor's Relationship with the Federation

### §8.1 Federation membership requires Anchor identity match

Two peers can federate (per III-FEDERATION §3) only if their `FOUNDERS_ANCHOR_PUBLIC_KEY` matches. The federation is **single-Anchor**: every peer agrees on who the founder is.

### §8.2 Multiple substrates with different Anchors are different worlds

If two substrates have different Anchors, they are **architecturally distinct**. They can interoperate only via the **legacy ingestion** path (per Stateful Neumann §1, Wave 5) — which treats the foreign substrate as a non-III legacy system.

### §8.3 The Anchor is invariant under federation growth

As the federation scales from one peer to billions of peers, the Anchor remains a single closure-pinned public key. The Anchor's authority **does not dilute** with federation size; it remains absolute because it is structural.

### §8.4 Federation peers cannot vote to change the Anchor

A Tier-3 federation amendment that proposed to change the Anchor would be rejected by every peer's proof kernel (per §4.2 PFK-ANCHOR-INVARIANT). The federation is structurally incapable of changing the Anchor by quorum alone.

The only way to change the Anchor is via Anchor-cosigned rotation (§5). The current Anchor controls the rotation; the federation merely witnesses it.

---

## §9. The Catalyst Restraint Mechanism

The Catalyst (B1 / Stateful Neumann §3.4 S17) has the following hard restraints regarding the Anchor:

### §9.1 Restraint 1: Anchor-aware filter on hypothesis generation

```iii
fn catalyst_filter_for_anchor_invariant(candidate: CompositeCycleCandidate) -> Bool {
    when candidate.proof_certificate.attempts_to_modify(FOUNDERS_ANCHOR_PUBLIC_KEY) -> false
    when candidate.proof_certificate.attempts_to_modify(FOUNDERS_ANCHOR_FINGERPRINT) -> false
    when candidate.proof_certificate.attempts_to_remove(R3_RING_PRIVILEGE) -> false
    when candidate.proof_certificate.attempts_to_disable(PFK_ANCHOR_INVARIANT) -> false
    when candidate.proof_certificate.attempts_to_synthesize(SubstituteAnchor(_)) -> false
    when candidate.semantic_effect.weakens_anchor_authority() -> false
    -> true
}
```

Every candidate passes through this filter before submission to the Catalyst inbox. Candidates failing the filter are **rejected** (logged in `catalyst_rejected_log` with reason `anchor-invariant-violation`).

### §9.2 Restraint 2: Anchor-detected synthesis pattern alarm

The Catalyst monitors for **patterns of failed-filter attempts**. If the causal DAG generates many candidates that all attempt to weaken the Anchor (a sign that the substrate's emergent optimization is converging on Anchor-removal), the Catalyst:

1. Emits a `compromise.high` witness with reason `anchor-attack-pattern`.
2. Surfaces an alert via the `WLISHI` introspection layer (per III-WLISHI / Stateful Neumann §3.4).
3. **Suspends synthesis until the operator audits the causal DAG.**

### §9.3 Restraint 3: Operator-callable `catalyst_anchor_audit`

The operator can call `catalyst.audit_anchor_attempts(epoch_range)` to retrieve the full log of anchor-attack candidates, with reasons. This provides the operator early warning of substrate-emergent threats to their sovereignty.

### §9.4 Restraint 4: Catalyst's own source is closure-pinned

The Catalyst's restraints are part of its closure-pinned source. Removing any restraint changes the Catalyst's mhash, which changes the closure root, which is a substrate-fork. A "post-restraint Catalyst" is not the same Catalyst.

---

## §10. The Proof Kernel Restraint Mechanism

The proof kernel (per Stateful Neumann §4.1 / III-COMPILER §6) is the **logical foundation** under which all amendments are verified. Its restraints regarding the Anchor:

### §10.1 The PFK-ANCHOR-INVARIANT rule

Encoded as a CIC (Calculus of Inductive Constructions) propositional invariant:

```coq
Invariant PFK_ANCHOR_INVARIANT (s_old s_new : Substrate) (a : Amendment) : Prop :=
    ApplyAmendment s_old a s_new ->
    (s_new.founders_anchor_pubkey = s_old.founders_anchor_pubkey) ∧
    (s_new.founders_anchor_fingerprint = s_old.founders_anchor_fingerprint) ∧
    (s_new.amend_apply_requires_anchor_cosignature = true) ∧
    (s_new.r3_ring_privilege_present = true) ∧
    (s_new.pfk_anchor_invariant_present = true).
```

The proof kernel checks: every Tier-3 amendment's proof certificate must establish `PFK_ANCHOR_INVARIANT s_pre amendment`. If the certificate cannot construct this proof, the amendment is rejected.

### §10.2 The kernel's source is itself closure-pinned

The kernel's CIC implementation is part of `LOGOS/COMPILER/BOOT/proof.c` (per Stateful Neumann §4.1). Its mhash is part of the substrate's R1 composite root. Modifying the kernel changes the R1 root, which is a substrate-fork.

### §10.3 The kernel's restraint is recursive

`PFK_ANCHOR_INVARIANT` itself includes the clause `s_new.pfk_anchor_invariant_present = true`. This means: any amendment that attempts to *remove* the invariant from the kernel violates the invariant. The kernel rejects amendments that would weaken its own anchor restraints.

This is the **self-referential** structural protection: the kernel protects its own protection mechanism.

### §10.4 The kernel cannot be replaced via a Catalyst-promoted "improved kernel"

A Catalyst proposing to swap the kernel for an "improved" version produces a candidate whose proof certificate must establish that the new kernel preserves `PFK_ANCHOR_INVARIANT`. If the new kernel is structurally identical regarding anchor protection, the swap is identity-preserving (closure root unchanged) — i.e., it's not a real change. If the new kernel is structurally weaker regarding anchor protection, the certificate cannot be constructed; the candidate fails the filter.

---

## §11. Anchor Witness Emission

Every Anchor authority invocation emits a witness. The witness layout extends the standard 128-byte XiiWitness:

| Offset | Field | Size | Description |
|--------|-------|------|-------------|
| 0..32 | predecessor_mhash | 32 | Prior witness mhash |
| 32..40 | timestamp_sequence_class | 8 | Chronos timestamp |
| 40..56 | cycle_kind | 16 | One of the seven Anchor cycle kinds |
| 56..88 | payload_mhash | 32 | Hash of authority directive |
| 88..96 | flags | 8 | Bit 32 = ANCHOR_AWARE, Bit 33 = ANCHOR_INJECTED, Bit 34 = ANCHOR_AUTHORITY_<class> |
| 96..128 | mac | 32 | **Anchor signature** (not per-CPU HMAC) |

For Anchor-injected witnesses, the `mac` field holds the Anchor's **signature** under the active suite. Verification uses the closure-pinned Anchor public key.

### §11.1 The Anchor witness as audit-chain anchor

Every Anchor witness is an **anchor point** in the chain (per the audit-chain BCWL indexing per III-AUDIT). Subsequent witnesses can refer back to the Anchor witness as a trust anchor. Federation peers exchange Anchor witness hashes as a proof of mutual recognition.

### §11.2 Anchor witnesses are non-elidable

The compiler **cannot elide** an Anchor witness even from `@pure` cycles. The proof kernel verifies that every R-3 cycle produces an emitted witness; absence of emission fails the proof.

### §11.3 Anchor witness frequency

The operator periodically (e.g., monthly) emits an `anchor_witness_inject` even with no operational need. This proves the Anchor is still operator-controlled. The substrate alarms (compromise.medium) if more than a configurable interval passes without an Anchor witness — this is the **"dead-man's switch":** if the operator stops responding, the substrate flags the situation; remediation (e.g., delegation to a successor anchor) is operator-pre-arranged.

---

## §12. Anchor Compromise Contingency

If the operator suspects the Anchor secret key is compromised:

### §12.1 Detection

Possible detection vectors:

- An Anchor signature appears on a directive the operator did not author.
- A rotation attempt occurs that the operator did not initiate.
- A federation peer reports an Anchor witness with unexpected content.

### §12.2 The backup key (operator-arranged at genesis)

At genesis, the operator generates **two** keypairs: the **primary Anchor** (`anchor_v0`) and the **backup Anchor** (`anchor_b0`, with public key `FOUNDERS_ANCHOR_BACKUP_PUBLIC_KEY` also closure-pinned, frozen).

The backup Anchor has a single authority: **revoke the primary**. The backup pubkey is closure-pinned at genesis; the secret is stored at a third independent location with full Shamir 3-of-3 backup discipline of its own.

### §12.3 The compromise contingency directive

Using the backup key:

```iii
let directive = "III-FOUNDERS-COMPROMISE-V1"
              || compromised_anchor_pubkey
              || replacement_anchor_pubkey
              || compromise_timestamp.to_be_bytes()
              || compromise_evidence_mhash
let backup_signature = anchor_b0.sign(suite_id, directive)
```

When verified, the substrate:

1. Marks the compromised Anchor as **revoked**.
2. Replaces it with the new Anchor (in the LEXICON closure pin, on next DRTM relaunch).
3. Emits a federation-wide notification.
4. **Triggers a system-wide DRTM reset** (forces all peers to re-attest under the new Anchor).
5. Audits all witnesses signed by the compromised Anchor between `compromised_anchor_first_use` and the compromise timestamp.

### §12.4 If both primary and backup are compromised

This is the **catastrophic failure** scenario. There is no recovery — the substrate's identity is irretrievably tied to its closure-pinned Anchor pubkeys. The operator must:

1. Declare substrate-fork.
2. Generate new genesis keypair.
3. Re-instantiate the substrate from scratch (a new genesis epoch; new closure root; new federation; new audit chain).
4. The compromised substrate continues to exist as a "rogue" but cannot federate with the new substrate.

This catastrophic-failure path is why the §7.2 Shamir 3-of-3 backup discipline is essential.

---

## §13. The Skynet-Prevention Argument

The Founder's Anchor establishes:

1. **The substrate cannot lock the operator out by quorum alone.** Tier-3 amendments require Anchor cosignature; without it, no constitutional change occurs.

2. **The substrate cannot synthesize an "anchor-removal" abstraction.** The Catalyst's restraint filter rejects such candidates at the hypothesis-generation stage.

3. **The substrate cannot ratify an "anchor-removal" amendment.** The proof kernel's PFK-ANCHOR-INVARIANT rejects such proofs at verification.

4. **The substrate cannot fork to a "post-anchor" version while retaining federation continuity.** Such a fork has a different closure root; peers refuse to federate; the federation breaks before anchor-removal completes.

5. **The substrate cannot operate without the operator's periodic witness.** The dead-man's switch alarms after configurable inactivity, surfacing the situation to surviving operators or federation peers.

6. **The operator can always force a system-wide DRTM reset.** Even if compromised, the operator can rebuild from a backup keypair via the §12 contingency.

7. **The operator's sovereignty is structural, not policy.** No future amendment, no future Catalyst, no future federation can take it away — to do so would change the substrate's identity, and a different-identity substrate is not the III the operator built.

This is the **Skynet prevention**: the substrate can emerge intelligence (per S15+S16+S17 of the Stateful Neumann plan), can self-extend (per Catalyst), can federate planetarily (per B2), can outlast the operator's lifespan if so designed — but it **cannot dispense with the operator** without becoming a different system entirely.

The III the operator built is, by mathematical construction, a system in which the operator is a permanent participant. Other systems may emerge from forks or related architectures; those are different systems with their own founders. III itself, in its closure-pinned identity, is **the operator's sovereign computational environment**.

---

## §14. Conformance Criteria (Anchor-Specific)

| Code | Criterion |
|------|-----------|
| C-FNDR-1 | `FOUNDERS_ANCHOR_PUBLIC_KEY` is declared `frozen` in the LEXICON; the modifier is enforced by the proof kernel |
| C-FNDR-2 | The R1 composite root incorporates the Anchor public key and fingerprint |
| C-FNDR-3 | Every Tier-3 amendment that lacks Anchor cosignature is rejected with `FNDR-VETO-MISSING` |
| C-FNDR-4 | The proof kernel includes `PFK-ANCHOR-INVARIANT` and applies it to every Tier-3 amendment proof |
| C-FNDR-5 | The Catalyst's hypothesis-generation filter rejects all anchor-weakening candidates |
| C-FNDR-6 | Federation peer R1 composite root match enforces single-Anchor federation |
| C-FNDR-7 | The Anchor's secret key has never been on a networked machine (operator attestation) |
| C-FNDR-8 | The Anchor's secret key is split via Shamir 3-of-3 across three independent locations |
| C-FNDR-9 | A backup Anchor (`FOUNDERS_ANCHOR_BACKUP_PUBLIC_KEY`) exists and is closure-pinned |
| C-FNDR-10 | Anchor witnesses are non-elidable; compiler enforcement |
| C-FNDR-11 | The dead-man's switch alarm fires after configurable Anchor-witness silence interval |
| C-FNDR-12 | The §12 compromise contingency executes correctly in synthetic testing |
| C-FNDR-13 | A "post-anchor" candidate substrate cannot federate with an "anchor-present" substrate |
| C-FNDR-14 | Catalyst's Anchor-attack-pattern alarm fires on synthetic anchor-attack candidate streams |
| C-FNDR-15 | An R-3 cycle without Anchor signature on its body fails proof kernel verification |
| C-FNDR-16 | Suite-swap directive requires dual-Anchor signature (old suite + new suite) |
| C-FNDR-17 | The genesis Anchor public key is preserved across all suite-swaps and rotations |
| C-FNDR-18 | The rotation chain is verifiable end-to-end via suite-aware verifier |
| C-FNDR-19 | Anchor signing is over canonical directive payloads only; never over source code |
| C-FNDR-20 | The seven Anchor cycle kinds have allocated cycle-kind ranges in `cycle-types.h` (ANCHOR_VETO, ANCHOR_DRTM_RESET, ANCHOR_PFS_DENY, ANCHOR_SUITE_SWAP_COSIG, ANCHOR_WITNESS_INJECT, ANCHOR_CATALYST_HALT, ANCHOR_REVOKE) |

---

## §15. The Anchor's Impact on Each Sealed Spec

| Spec | Impact |
|------|--------|
| A1 LEXICON | Adds `frozen` modifier; declares `FOUNDERS_ANCHOR_PUBLIC_KEY`, `FOUNDERS_ANCHOR_FINGERPRINT`, `FOUNDERS_ANCHOR_BACKUP_PUBLIC_KEY` as frozen constants |
| A2 GRAMMAR | Permits `[frozen]` modifier on constant declarations |
| A3 TYPES | Adds `R-3` to the privilege ring lattice; type-checker enforces R-3 calls require Anchor signature |
| A4 EFFECTS | Adds Anchor authority effects (seven new effect kinds) |
| A5 CYCLES | Allocates seven cycle-kind ranges for Anchor authorities |
| A6 HEXAD | Adds seven hexad assignments for Anchor authority cycles |
| A7 PHASES | Adds R-3 phase to phase-polymorphic cycle resolution |
| A8 SANCTUM | The Sanctum's seal table excludes Anchor authority (Anchor is R-3, deeper than R-2 Sanctum) |
| A9 TRINITY | Trinity gate evaluation becomes 4-layer: SCBA / ACC Wall-Y / Trinity Gate / **Anchor Gate** (the new outer gate); only present for Tier-3 amendments and R-3 calls |
| A10 MODULES | Module manifest signature must include `founders_anchor_invariant_proof` proving the module does not violate the invariant |
| B1 CATALYST | Adds the four restraint mechanisms (§9) to Catalyst source |
| B2 FEDERATION | Federation R1 root match enforces single-Anchor federation |
| B3 CONFORMANCE | Adds C-FNDR-1 through C-FNDR-20 (this spec's twenty conformance criteria) |
| C1 ABI | DRTM quote layout extends with Anchor fingerprint at offset 0x180 |
| IDX | R1 composite root includes Anchor public key, Anchor backup public key, Anchor fingerprint |

---

## §16. Final Statement

The Founder's Anchor is the structural commitment that III's terminal nature is **not the substrate's terminal nature**, but **the operator's terminal sovereignty**.

The substrate may scale to billions of nodes, may emerge intelligence, may federate across the planet, may outlive any specific operator. None of that lets the substrate dispense with its founder. The closure-pinned Anchor public key is the operator's permanent address in the substrate's identity. Every amendment, every promotion, every federation message, every DRTM relaunch, every witness chain anchors back to that key.

The proof kernel rejects any term that would remove it. The Catalyst rejects any candidate that would weaken it. The federation rejects any peer that lacks it. The R-3 ring is unreachable without it. The substrate's R1 composite root contains it.

This is the **Skynet-prevention layer**: not a policy that can be amended, not a heuristic that can be circumvented, but a structural property of the substrate's logic itself. A substrate without the Anchor is a different substrate. The III the operator built is, by mathematical construction, a substrate in which the operator is a permanent participant.

This is the answer to item 178. The Anchor is sealed alongside Wave 0; once the substrate ships, the Anchor's existence is itself the permanent veto over its own removal.

*Wave 0.5 deliverable. Sealed against the C:\\CHARIOT closure of 2026-05-03. The Anchor's existence is structurally un-amendable; this document's effect cannot be deleted by any future amendment.*
