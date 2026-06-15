# III "Develop-Up" Encapsulation Layer

**Status: COMPLETE.** 11 modules, 11 KATs (corpus 1575–1585), corpus 1172/0, zero defects across two
adversarial-review workflows (61 agents, 4.8M tokens). Commits `747e5c21` (10 slices) + `5deda261` (gateway).

**Extension (2026-06-15):** Slice 11 `aether/attest_box` adds a sixth superpower — REMOTE ATTESTATION:
the box's full disk image is content-addressed into a 32-byte state root and signed with the node's
deterministic Ed25519 identity key (gated by the capability ATTEST right, bit 11). A remote party verifies
offline — without trusting the host — that this node vouches the box is in exactly this state; a single
tampered block is detected as drift while the original signature stays cryptographically valid. KAT 1595
(toy-proof: valid-attest / cap-denied / tamper-drift / forged-sig / determinism).

## The thesis

Instead of rewriting all software natively in III ("develop down"), use III as an **invincible Ring-(-1)
foundational layer that ENCAPSULATES an unmodified legacy guest as an opaque mathematical object** and grants
it III's superpowers — reversibility, information-flow control, behavioral immunity, deterministic replay,
availability, zero-trust mediation — without the guest knowing or being modified. III is blind to what the
guest's bytes *mean*; it enforces *physics* on the guest's effects.

Every module **composes a named, pre-existing III organ** (it does not reimplement) and is proven by a
**behavioral toy-proof oracle** — a conjunction a trivial reimplementation provably cannot pass (recover an
*arbitrary* runtime pre-image after an adversarial overwrite; taint reaching a sink via a *non-obvious* path;
two traces differing *only* in structural fingerprint classified oppositely; a write that is *structurally
unrepresentable*; a cumulative cap a per-operation check misses; an *un-fakeable* lowest-common-ancestor;
byte-identical replay despite a *different* live world; a *forged* content-address pin rejected).

## The ten superpower slices + the gateway

| # | Module | Superpower | Composes (real organ) | KAT |
|---|--------|-----------|------------------------|-----|
| 1 | `aether/vbd` | reversibility / anti-ransomware rollback | `numera/reversible` | 1575 |
| 2 | `aether/flow_firewall` | provable information-flow control | `numera/taint_analysis` | 1576 |
| 3 | `aether/sentinel` | behavioral immunity (auto-rollback) | `numera/entropy_monitor` + `vbd` | 1577 |
| 4 | `aether/enclave` | enlightened-guest memory forcefield | `katabasis/vmexit` + `katabasis/svm_layout` | 1578 |
| 5 | `aether/sealed_box` | zero-trust capability gateway (4-bridge) | `aether/capability` + bridges 1–4 | 1579 |
| 6 | `aether/replay_box` | deterministic replay + divergence detect | `sanctus/observe` | 1580 |
| 7 | `aether/compute_box` | availability (resource-exhaustion immunity) | `aether/capability` + `omnia/sandbox_{ctor,quota,exec}` | 1581 |
| 8 | `aether/snapshot_box` | branching reversibility (snapshot forest) | `aether/snapshot_lattice` + `vbd` + `cad` | 1582 |
| 9 | `aether/sid_router` | universal reversibility (all exit kinds) | `katabasis/vmexit` + `numera/reversible` | 1584 |
| 10 | `aether/determinism_firewall` | canonical/provisional determinism membrane | `aether/reach_oracle` + `replay_box` | 1583 |
| 11 | `aether/attest_box` | remote attestation (offline-verifiable state vouch) | `node_identity` (Ed25519) + `cad` + `vbd` + `capability` | 1595 |
| ⋆ | `aether/develop_up` | **the encapsulation GATEWAY** (all 10 lifecycle slices in one) | all of the above + `capability` | 1585 |

### Security coverage

- **Confidentiality** — `flow_firewall` (no input-tainted byte egresses unencrypted).
- **Integrity** — `enclave` (host-state writes structurally unrepresentable via the hexad algebra) +
  `snapshot_box` (each checkpoint cad-bound, tamper-detectable).
- **Availability** — `compute_box` (append-only cumulative quota; a per-alloc check is evaded, the ledger
  is not).
- **Reversibility** — `vbd` (linear undo), `snapshot_box` (branching, restore-to-arbitrary-checkpoint with a
  lowest-common-ancestor `meet`), `sid_router` (every privileged exit kind, not just disk).
- **Determinism** — `replay_box` (record → byte-identical replay; divergence detector that raw `observe`
  lacks) + `determinism_firewall` (canonical admitted / provisional recorded-and-denied; forged pins
  rejected).
- **Zero-trust mediation** — `sealed_box` and `develop_up` (every privileged act verified against an
  attenuable, revocable, cascading-kill-switch capability — POLA, deny-by-default).

## The gateway lifecycle (`develop_up`)

```
du_encapsulate(guest_cap, mem_cap, cpu_cap)   admission (DISK+COMPUTE rights) -> open reversible disk,
                                              quota box, replay recording, sealed behavioral baseline
du_write(guest_cap, idx, val, cost)           cap-gated + quota-charged + reversibly-recorded write
du_checkpoint(ante)                           commit + branching snapshot (reopens the transactional session)
du_observe(activity) / du_guard()             feed behavioral cadence; verdict -> rollback or commit
du_restore(slot)                              restore the disk to any past snapshot
du_egress_safe / du_mem_allowed /             the four per-operation membranes
  du_reverse_route / du_ingress_admit
du_health()                                   aggregate: open + quota headroom
```

A composition subtlety the flagship KAT surfaced and drove to a fix: `vbd`/`reversible` is **transactional**
— `vbd_commit` (in `du_checkpoint`) and `sentinel_guard` (commit or rollback, in `du_guard`) **end** the
session, so the gateway reopens a fresh session at each transaction boundary. A structural facade would never
have caught this; only an end-to-end lifecycle KAT that writes *after* a checkpoint does.

## Honesty boundary (Mandate #21 — Physics Boundary Only)

A real bare-metal AMD-SVM boot of a live guest is **not verifiable in this environment** — the one
pre-authorized limit. Everything above is proven as **real III up to the metal edge that `cg_rm1` /
`katabasis/svm_layout` already codegen**. No stub pretends to cross that boundary; the claim is precise.
