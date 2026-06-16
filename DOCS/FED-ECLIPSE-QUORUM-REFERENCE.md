# fed_eclipse Quorum-Reference Derivation (Phase 14k Step 0190b)

## The gap

`aether/fed_eclipse` detects eclipse attacks by comparing a node's locally
computed peer-set fingerprint (`fed_eclipse_compute_my_fingerprint`, the XOR of
SHA-256(peer_id) over the admitted set) against a **reference** fingerprint — the
fingerprint a healthy consensus expects. `fed_eclipse_alarm()` fires when the
local fingerprint diverges from the reference by more than a threshold.

But the reference had **no production path to set it**. `fed_eclipse_set_reference_fingerprint`
was called only by unit-test 161; no genesis/bootstrap/admission code ever set a
meaningful reference. So `fed_eclipse_alarm()` was permanently fail-open
(`FECL_REFERENCE_SET == 0 → return 0`), and `fed_admit`'s planetary eclipse gate
(`FED_ADMIT_BIT_ECLIPSE_OK`) was granted unconditionally. The eclipse-detection
capability was **inert**.

## Why not a static genesis reference

The module docstring is explicit (lines 16–19): the reference is *"the consensus
expected fingerprint"* obtained by *"exchang[ing] fingerprints with peers it
trusts."* It is **not** the founding/genesis peer set: a genesis-static reference
would diverge from the local fingerprint on every legitimate membership change
(admit/evict) and false-alarm a healthy growing network. `fed_genesis` is a
*build-lineage* trust root (the closure_root descent chain), an unrelated concern.

## The design — additive, Byzantine-robust quorum derivation

The completing feature supplies the missing production path **without changing any
existing behavior**:

```
fed_eclipse_observe_reset()                      -> i32   clear the observation buffer
fed_eclipse_observe_peer_fingerprint(fp_32)      -> i32   record one trusted peer's reported fingerprint
fed_eclipse_observe_count()                      -> u32   number of observations
fed_eclipse_derive_reference_from_quorum(quorum) -> i32   set reference = the fp >= quorum peers agree on
```

Flow: a node collects the peer-set fingerprints reported by the peers it trusts
(over a sovereign-tier channel — the I/O layer), then derives the reference as the
fingerprint a **quorum** of them agree on. If some fingerprint reached the quorum,
it becomes the reference (`FECL_REFERENCE_SET = 1`) and the alarm goes live;
otherwise the reference stays unset and the alarm remains fail-open (no false
alarm on a split view).

### Security model
- **Threat:** an eclipse attacker isolates a node and feeds it a false peer view,
  so its local fingerprint diverges from what the honest network sees.
- **Defense:** the reference is the fingerprint ≥ `quorum` *trusted* peers agree
  on. With `quorum` chosen as a Byzantine quorum (≥ 2f+1 of ≤ 3f+1 trusted peers),
  **at most one** fingerprint can reach the quorum (two disjoint 2f+1 sets would
  exceed a 3f+1 population), so the derived reference is **unique** and an
  adversary controlling fewer than `quorum` of the observed peers **cannot dictate
  it**. If the local node is honest and not eclipsed, its computed fingerprint
  equals the quorum's; if eclipsed, it diverges → alarm.
- **Scope:** this is the admitting node's *own* eclipse self-detection
  (defense-in-depth). It does not replace PoW/sybil-signature/score/QC admission
  gating — those still apply independently.
- **Mandate 7 (no statistics/learning):** pure structural plurality — a fixed
  count compared against a fixed quorum. No observed-traffic adaptation.

### Why it cannot regress
The change is **purely additive**. `fed_eclipse_alarm`, `fed_eclipse_byte_divergence`,
`fed_eclipse_set_reference_fingerprint`, `fed_eclipse_compute_my_fingerprint`, and
`fed_admit`'s fail-open default are all **unchanged**. A node that has not derived
a quorum reference behaves exactly as before (fail-open). The new path only lets a
node set a *meaningful* reference. The existing tests (161 fed_eclipse_basic, 163
fed_admit_gates, 240 fed_e2e_admit_ceremony, 1455, 1457) exercise none of the new
symbols and stay green.

## The I/O layer (separate, thin)
Collecting the trusted peers' reported fingerprints over the network
(sovereign-tier channel) is a thin I/O layer that calls
`fed_eclipse_observe_peer_fingerprint` for each received report, then
`fed_eclipse_derive_reference_from_quorum`. The deterministic, security-critical
**derivation core** is complete and tested here; the transport is a distinct
concern (aether's `backend_remote`/`channel`/`net` layer), not a partial of this
feature.

## Verification
KAT **1623** (`fed_eclipse_quorum_reference`, EXIT=99) proves all arms:
1. `observe_reset` → count 0.
2. Byzantine majority: observe A,Z,A,Z,A; quorum 3 → A (count 3) wins, the
   sub-quorum adversary Z (count 2) is rejected.
3. **Alarm arm:** reference (A) live; empty local view (zeros) diverges in all 32
   bytes → alarm = 1.
4. **No-alarm arm:** quorum reference = ZERO; empty local view = zeros = reference
   → divergence 0 → alarm = 0 (no false alarm).
5. **NOQUORUM fail-open:** A,Z (1 each), quorum 2 → none reaches it → reference
   unset → divergence sentinel, alarm = 0.
6. `quorum == 0` → `FECL_E_BADARG`.
