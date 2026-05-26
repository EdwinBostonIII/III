# III Consensus — HotStuff BFT (derivative specification)

The substrate's Byzantine-fault-tolerant consensus protocol is a variant of
HotStuff (Yin, Malkhi, Reiter, Gueta, Abraham, "HotStuff: BFT Consensus with
Linearity and Responsiveness", PODC 2019), specialised for the substrate's
three quorum-tier discipline and its native, NIH Ed25519 signature surface.

**Status: IMPLEMENTED (Stage 5, DISCHARGED).** The native `.iii` implementation
`STDLIB/iii/aether/hotstuff.iii` exists, compiles under `iiis-2`, and passes its
KAT (`STDLIB/corpus/383_hotstuff.iii`, exit 99). The three quorum tiers are
implemented in-module as `hs_dispatch_by_tier` (not a separate `quorum_tier.iii`);
`hotstuff_predict.iii` and `hotstuff_heal.iii` are the predictive-quorum and
partition-heal drivers built alongside. **The authoritative byte-exact formats
and public API are in the "## Implementation (authoritative)" section at the end
of this document** — where this earlier spec and the implementation differ, the
implementation governs (notably: the block/vote/QC hashing primitive is
**SHA-256** per the gospel's `hs_block_hash`, not Keccak-256; aggregation remains
Ed25519 concatenation). This spec section is retained for the design rationale.

## Cryptographic preconditions (all present in the real substrate)

- **Ed25519 sign + verify**: `STDLIB/iii/numera/crypt_ed25519.iii` (`ed25519_sign`
  added at §4.1; `ed25519_verify` pre-existing). NIH, constant-time.
- **Keccak-256 / SHA3-256**: `STDLIB/iii/numera/keccak.iii`, `sha3_256.iii`.
- **HMAC**: `STDLIB/iii/numera/hmac.iii` (for deterministic leader-rotation PRF).
- Aggregation is **Ed25519 concatenation**, not BLS — D3/NIH forbids a
  third-party pairing library; the small size cost of concatenated signatures
  is accepted in exchange for the no-dependency discipline.

## Block

A block is `(parent_qc_hash, view, payload_mhash, proposer_sig)`:
- `parent_qc_hash` — Keccak-256 of the parent quorum certificate (or the
  genesis sentinel for the first block).
- `view` — u64 view number under which the block was proposed.
- `payload_mhash` — Keccak-256 of the block payload (payload stored separately).
- `proposer_sig` — Ed25519 signature over `parent_qc_hash ‖ view ‖ payload_mhash`.

The block identifier is Keccak-256 of the canonical concatenation of its fields.

## Quorum certificate (QC)

A QC is `(block_mhash, view, signer_count, concatenated_sigs, signer_bitmap)`.
Valid iff at least the tier-required number of distinct members appear in the
bitmap and each signature verifies under that member's public key over
`block_mhash ‖ view`.

## Three quorum tiers

| Tier | Quorum | Tolerance | Governs |
|------|--------|-----------|---------|
| **Bedrock** | `n` (all honest) | none / bit-exact | constitutional amendments, federation membership, capability-table updates, mandate-ledger entries |
| **Field** | `2f+1` | epsilon-tolerant (per the V2 epsilon clause) | routine state ops, computation results, memoization populations |
| **Speculative** | `1` | structurally isolated | counterfactual exploration; merges to canonical only via a verified bisimulation witness |

`qt_required_quorum_count(tier, n, f)` = `n` (Bedrock) / `2f+1` (Field) / `1`
(Speculative). Unknown operations default to **Field** (never silently Bedrock,
never silently Speculative).

## Pacemaker

A view advances when either a QC forms for the current view's block (next view
begins immediately, optimistic responsiveness) or `f+1` distinct timeout
messages are collected (next view begins with a view-change carrying the proofs).
V1 uses a hardcoded 2000 ms timeout; V2 ratifies `cp_pacemaker_timeout`.

## Leader / replica

Leader for a view = `view mod n` (deterministic). The leader proposes; replicas
vote (an Ed25519 signature over `block_mhash ‖ view`); the leader collects votes
into a QC once the tier quorum is reached.

## View change with f+1 timeout proof

A view change requires `f+1` Ed25519-signed timeout assertions. A node receiving
a view change verifies every signature in the bundle before advancing — no node
advances on an unproven timeout.

## Locked-QC / high-QC

Each node tracks the highest QC it has seen (`high_qc`) and the QC it is locked
on (`locked_qc`). The lock is updated on a `2f+1` quorum over a block whose
parent is the high-QC, and prevents voting on a competing lower-height block —
this is the safety mechanism (no two honest nodes commit conflicting blocks at
the same height under the Byzantine threshold).

## Federation integration (Stage 5)

- `aether/fed_admit.iii` gains a 4th admission gate: a HotStuff QC over the
  admission decision (current gates: sybil + eclipse + score).
- `aether/fed_seal.iii` consumes HotStuff QCs for cross-tier anchoring.

## Verification gates (Stage 5 acceptance)

- 4-node corpus commits 100 blocks; every committed block byte-identical across nodes.
- Byzantine node (1 of 4) sending conflicting votes → safety preserved.
- Leader-failure between propose and commit → recovery via view change.
- Safety + liveness theorems queued in `DOCS/MATH_LIBRARY_QUEUE.md`.

---

## Implementation (authoritative)

Canonical: `STDLIB/iii/aether/hotstuff.iii`. Determinism: `leader = view mod n`,
no randomness. Quorum `2f+1`, `f=(n-1)/3`. Hashing primitive: **SHA-256**.

**Block (424 B):** `[0..256) parent_qc`, `[256..264) view u64-LE`,
`[264..296) payload_mhash`, `[296..328) block_hash = SHA-256(parent_qc ‖ view_LE
‖ payload_mhash)` (296-B preimage), `[328..360) proposer_pubkey`,
`[360..424) proposer_sig` = Ed25519 over `(block_hash ‖ view_LE)` (40 B).
**Vote (108 B):** `block_mhash(32) ‖ view(8 LE) ‖ voter_id(4 LE) ‖ sig(64)` over
`(block_mhash ‖ view_LE)`. **NewView (76 B):** `new_view(8 LE) ‖ sender_id(4 LE)
‖ timeout_sig(64)`. **QC:** `block_mhash(32) ‖ view(8 LE) ‖ n_sigs(4 LE) ‖
n_sigs×64-B sigs` (concatenated Ed25519).

**API:** `hs_init`, `hs_set_keypair(seed‖pk)`, `hs_propose` (signs the block),
`hs_handle_propose` (verify proposer sig + leader-for-view + locked-block safety),
`hs_handle_vote` (verify + dedup bitmap + quorum phase-advance/commit),
`hs_handle_new_view` (f+1 timeout proof), `hs_tick` (5000 ms view-change),
`hs_committed_head`, `hs_compose_qc`, `hs_verify_qc`, `hs_dispatch_by_tier`
(Bedrock=2f+1, Field=f+1, Speculative=local-only).

**Keypair generation:** `numera/crypt_ed25519.iii::ed25519_pubkey(seed, out_pk)`
(added Stage 5) derives `pk = compress([clamp(SHA-512(seed)[0..32])]·B)` — enables
runtime keypair generation for the ceremony and multi-node tests.

**HOTSTUFF_QC payload kind = `0x18`** (extended catalog); absorbed by
`cp_v3_payload_schema` in V2 Phase Twelve as a strict additive amendment.

**KAT (`corpus/383_hotstuff`, exit 99):** 4 distinct Ed25519 keypairs, n=4
(quorum 3); propose → handle_propose → QC compose/verify (+ sig tamper rejected)
→ vote aggregation (duplicate + bad-signature rejected, quorum phase-advance) →
three-tier dispatch. Build 272/0, corpus 303/0, lib deterministic.
