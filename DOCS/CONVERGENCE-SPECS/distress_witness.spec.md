# 48 aether/distress_witness.iii — Implementation Spec

## Verdict
**PARTIAL** — the gospel candidate body is structurally sound and captures the maximal intent (seven distress kinds, comm-key-signed payload carrying the context snapshot, federation-correlation outbox, witness publication via `wh_publish`), but it does **not compile as written** and is **incomplete against the mandates**: it uses four function-local `var` arrays (Trap 7), the unsupported `&ARR[expr]` element-address idiom (house style is `((&ARR as u64)+off) as *u8`), declares the wrong const prefix (`DW_` — assigned prefix is `DWIT_`), omits the **M8 capability gate** entirely (signed emission must be capability-mediated), omits **M6/W6 antecedent chaining** (the new distress fragment does not cite the prior outbox fragment as an antecedent), hard-codes a 2-byte payload length field that silently truncates payloads ≥ 64 KiB, and signs with a placeholder buffer-overlap that double-writes the signature into the same `buf`. All gaps are closed below.

## Purpose
`aether::distress_witness` is the substrate's **signed distress producer**: when a constitutionally significant anomaly fires (Tier-2/Tier-3 recovery, triple-check disagreement, predicted quiescence, forbidden write, audit failure), it freezes the local context-awareness snapshot, signs `kind‖payload‖snapshot‖node_id` with the node's **communication key** (deliberately distinct from the witness/sheaf-attestation key so that compromise of one key never reveals the other — M-level key separation), publishes the result as a witness fragment through the universal `wh_publish` hook (W16/M6 in-transit signed; M6 hash-chained), and records the fragment id in a bounded federation outbox so peers can correlate the same event across the network.
- **Hexad:** `kind_witness` (it produces provenance; secondary `kind_passage` for the cross-node outbox).
- **Ring:** R−1 (substrate-internal witness producer; matches the gospel header and the `witness_hook`/`capability` siblings).
- **K-vector:** K = 1.00 (gospel header `Hexad: kind_witness. Ring: R-1. K: 1.00`).

## Public API
```
fn dw_init(comm_cap: u64) -> i32 @export
fn dw_produce(kind: u8, payload: *u8, payload_len: u32, args: *u8) -> u64 @export
fn dw_outbox_count() -> u32 @export
fn dw_outbox_at(idx: u32, out_frag_id: *u8) -> i32 @export
fn dw_last_frag_id(out_frag_id: *u8) -> i32 @export
fn dw_selftest() -> u64 @export
```

Return-status conventions (W9/W12):
- `dw_init` → `i32`: `DWIT_OK` (0) or negative error (`DWIT_E_CAP` if the supplied capability lacks `crypto_sign`+`attest` rights). W12-compliant status.
- `dw_produce` → `u64`: the published **fragment index** on success; the all-ones sentinel `0xFFFFFFFFFFFFFFFFu64` on any failure (uninit, bad kind, capability denied, payload too large, `wh_publish` full). This mirrors `wh_publish`'s own sentinel convention so callers test one value. (Sentinel-typed return per W12.)
- `dw_outbox_count` → `u32`: live outbox depth (saturating count; never an error path).
- `dw_outbox_at` / `dw_last_frag_id` → `i32`: `DWIT_OK` or `DWIT_E_BAD` (W9 negative). `out` must be a 32-byte buffer.
- `dw_selftest` → `u64`: `99u64` = pass; any other value = the failing assertion ordinal.

**W2 note:** `dw_produce` keeps 4 params by folding the per-call argument bundle (`comm_cap` + reserved future fields) behind `args: *u8` (a `DWIT_ARGS`-shaped aggregate, layout in Data Structures). The capability is read from `args[0..8]` (LE u64). This preserves the gospel's 4-arg shape while admitting the M8 capability without a 5th parameter. `out_frag_id` (the gospel's 4th param) is **not** dropped — it is written to `args[8..40]` on success, and also retrievable via `dw_last_frag_id`.

## Constant Namespace
**PREFIX = `DWIT_`** — grep of `STDLIB/` for both `DWIT_` and the gospel's `DW_` returned **no collisions** (clean). The gospel body's `DW_` prefix is **replaced** by `DWIT_` to match the assigned namespace and to leave headroom should a future `dw_*` data-warehouse-style module appear.

Module-level constants (every one prefixed; none collides with existing STDLIB linker-global symbols):
```
const DWIT_OK            : i32 =  0i32
const DWIT_E_BAD         : i32 = -1i32
const DWIT_E_CAP         : i32 = -2i32
const DWIT_E_PAYLOAD     : i32 = -3i32
const DWIT_E_FULL        : i32 = -4i32

const DWIT_KIND_TIER2_RECOVERY      : u8 = 1u8
const DWIT_KIND_TIER3_RECOVERY      : u8 = 2u8
const DWIT_KIND_TC_DISAGREE_21      : u8 = 3u8
const DWIT_KIND_TC_DISAGREE_FATAL   : u8 = 4u8
const DWIT_KIND_PREDICTIVE_QUIESCENCE : u8 = 5u8
const DWIT_KIND_FORBIDDEN_WRITE     : u8 = 6u8
const DWIT_KIND_AUDIT_FAILURE       : u8 = 7u8
const DWIT_KIND_MIN                 : u8 = 1u8
const DWIT_KIND_MAX                 : u8 = 7u8

const DWIT_MAX_OUTBOX    : u32 = 4096u32
const DWIT_FRAG_BYTES    : u64 = 32u64       // identifier width
const DWIT_PAYLOAD_MAX   : u32 = 3968u32     // see DWIT_BUF bound below
const DWIT_SIG_BYTES     : u64 = 64u64       // Ed25519 detached sig
const DWIT_SNAP_BYTES    : u64 = 16u64       // 8B anomaly score + 8B entropy-monitor distance
const DWIT_HDR_BYTES     : u64 = 5u64        // 1B kind + 4B payload_len (LE u32 — widened from gospel's 2B)
const DWIT_PILLAR        : u16 = 7u16        // aether/federation pillar id (matches gospel call + witness_hook KAT)
const DWIT_PHASE         : u8  = 10u8        // distress phase tag (matches gospel call)
const DWIT_REVTAG        : u8  = 1u8         // reversible-emission tag (matches gospel call; W16)
const DWIT_REQUIRED_RIGHTS : u64 = 0x1800u64 // CAP_RIGHT_CRYPTO_SIGN(0x1000) | CAP_RIGHT_ATTEST(0x0800)
```
`DWIT_REQUIRED_RIGHTS` is the OR of the two real right-bits read from the built `aether/capability.iii` (`CAP_RIGHT_CRYPTO_SIGN = 0x1000u64`, `CAP_RIGHT_ATTEST = 0x0800u64`); it is not invented.

## Data Structures
All buffers are **module-scope** (Trap 7: iiis local `var` arrays parse only at module scope). Bounds justified per W8.

```
var DWIT_OUTBOX     : [u8;  131072]   // 4096 * 32 — federation-correlation fragment-id ring
var DWIT_OUT_COUNT  : u32  = 0u32     // live outbox depth (saturates at DWIT_MAX_OUTBOX)
var DWIT_OUT_HEAD   : u32  = 0u32     // ring write cursor (mod DWIT_MAX_OUTBOX)

var DWIT_PRODUCER   : [u8; 32]        // ident_from_bytes("aether::distress_witness")
var DWIT_OPID       : [u8; 32]        // ident_from_bytes("aether::distress_witness::produce")
var DWIT_COMM_CAP   : u64  = 0u64     // capability id captured at dw_init (CAP_RIGHT_CRYPTO_SIGN|ATTEST)
var DWIT_INITED     : u8   = 0u8

var DWIT_BUF        : [u8; 4096]      // distress-message assembly scratch (was gospel function-local `buf`)
var DWIT_SIG        : [u8; 64]        // Ed25519 detached signature scratch (was function-local `sig`)
var DWIT_IN_C       : [u8; 32]        // in_commit = wh_chain_root (was function-local `in_c`)
var DWIT_OUT_C      : [u8; 32]        // out_commit = ident_from_bytes(assembled msg) (was function-local `out_c`)
var DWIT_NODE_ID    : [u8; 32]        // node id sink for ni_node_id
var DWIT_LAST_FRAG  : [u8; 32]        // most-recently published fragment id (dw_last_frag_id + antecedent source)
var DWIT_HAVE_PREV  : u8   = 0u8      // 1 once at least one fragment has been published this run

var DWIT_T_PAY      : [u8; 64]        // self-test payload
var DWIT_T_FRAG     : [u8; 32]        // self-test frag-id sink
var DWIT_T_FRAG2    : [u8; 32]        // self-test second frag-id sink
var DWIT_T_ARGS     : [u8; 40]        // self-test args bundle (8B cap + 32B out_frag_id)
```

**Bound justifications (W8):**
- `DWIT_OUTBOX` = 4096 fragment ids × 32 B = 131072 B. The 4096 bound matches the gospel and is the federation correlation horizon: peers correlate within a bounded recent window, and `wh_publish` is the durable append-only store, so the outbox is a *cache* of recent ids, not the system of record. Implemented as a **ring** (gospel's plain truncate-at-4096 silently stopped recording after 4096 distress events for the life of the process; the ring keeps the most-recent 4096, which is the correct bounded-cache semantics — flagged + fixed).
- `DWIT_BUF` = 4096 B caps one assembled distress message: `DWIT_HDR_BYTES(5) + payload(≤ DWIT_PAYLOAD_MAX) + DWIT_SNAP_BYTES(16) + 32 (node id) + 64 (sig)`. Solving `5 + P + 16 + 32 + 64 ≤ 4096` gives `DWIT_PAYLOAD_MAX = 3968`. `dw_produce` rejects `payload_len > DWIT_PAYLOAD_MAX` with the sentinel (no overflow possible — fixes the gospel's unchecked copy into a 4096 buffer).
- The remaining 32/64-byte buffers are single fixed-width crypto/identifier scratch.

**Reentrancy note (Trap 7):** the module-scope scratch (`DWIT_BUF`/`DWIT_SIG`/`DWIT_IN_C`/`DWIT_OUT_C`) makes `dw_produce` **non-reentrant**, which is correct and expected for serialized witness emission (the witness chain is strictly serialized through the single-writer `wh_publish`/`at_advance`). Documented in the header; no concurrent distress production is permitted by the substrate model.

## Dependencies (externs)
All declared `extern @abi(c-msvc-x64) fn ... from "<module>.iii"`. Signatures verified against the **real provider files**, not the gospel.

| Symbol | Signature | Provider (NN) | Built? |
|---|---|---|---|
| `ident_from_bytes` | `(input:*u8, in_len:u64, out:*u8) -> i32` | `numera/identifier.iii` (01) | **BUILT** ✓ |
| `ident_copy` | `(src:*u8, dst:*u8) -> i32` | `numera/identifier.iii` (01) | **BUILT** ✓ |
| `wh_publish` | `(producer:*u8, opid:*u8, in_commit:*u8, out_commit:*u8, revtag:u8, phase:u8, pillar:u16, antecedents:*u8, n_ante:u32, payload:*u8, payload_len:u32, out_frag_id:*u8) -> u64` | `aether/witness_hook.iii` (07) | **BUILT** ✓ |
| `wh_chain_root` | `(out_id:*u8) -> i32` | `aether/witness_hook.iii` (07) | **BUILT** ✓ |
| `cap_verify_rights` | `(id:u64, required:u64) -> u8` | `aether/capability.iii` (built) | **BUILT** ✓ |
| `ni_communication_sign` | `(msg:*u8, msg_len:u64, out_sig:*u8) -> i32` | `aether/node_identity.iii` (sibling) | **NOT-YET-BUILT** ✗ |
| `ni_node_id` | `(out_id:*u8) -> i32` | `aether/node_identity.iii` (sibling) | **NOT-YET-BUILT** ✗ |
| `ca_anomaly_score` | `() -> u64` | `aether/context_awareness.iii` (Layer 10 sibling) | **NOT-YET-BUILT** ✗ |
| `ca_metric_at` | `(metric:u32) -> u64` | `aether/context_awareness.iii` (Layer 10 sibling) | **NOT-YET-BUILT** ✗ |

**Not-yet-built deps for the wave scheduler:** `node_identity.iii` (`ni_communication_sign`, `ni_node_id`) and `context_awareness.iii` (`ca_anomaly_score`, `ca_metric_at`). Both are named in the same convergence gospel (the Turn-Eight checkpoint at gospel L15552 lists `context_awareness.iii` as a Layer-10 module and `node_identity.iii` as its key provider); they must land **before** module 48 links.

**Contract for the `node_identity.iii` author (so signing is correct end-to-end):** `ni_communication_sign` MUST wrap the real `ed25519_sign(seed:*u8, pk:*u8, msg:*u8, msg_len:u64, sig_out:*u8) -> u8` from `numera/crypt_ed25519.iii` using the **comm key** (distinct seed from the witness key), with the seed‖pub fold exactly as `aether/hotstuff.iii:206` does (`ed25519_sign((&KEYS) as *u8, ((&KEYS)+32) as *u8, msg, len, sig)`). It returns `i32` `0`=ok (not the `u8` of raw `ed25519_sign`), so this module gates on `== 0i32`.

**Systemic gospel defects corrected here (per briefing §3.5):**
1. **keccak:** not used directly (hashing is internal to `wh_publish`/`identifier`), so the `keccak.iii` vs `keccak256.iii` defect does not surface; no `keccak256_*` extern declared.
2. **witness emit:** the gospel already (correctly, post-reconciliation) uses `wh_publish` — confirmed real, kept.
3. **cons_find:** not used.
4. **algebraic time:** **not** declared as a dependency — time is advanced *only* inside `wh_publish` (`at_advance`, the single writer per `algebraic_time.iii` discipline). This module never calls `at_now`/`at_current`, so the `at_now`-fiction defect is structurally avoided.
5. **capability:** gospel used **no** capability symbol; corrected to the real `cap_verify_rights(id, required) -> u8` with the real right-bits.
6. **witness_hook accessors:** this module needs no fragment-field getters (it only publishes + records the returned id), so the missing-getter defect does not apply.
7. **ed25519 signing:** the gospel's `ni_communication_sign` indirection is retained (key-separation is a real requirement), and the underlying real `ed25519_sign` 5-arg/32-byte-seed signature is pinned in the provider contract above.

## Algorithm
Determinism (M2) holds because every input is sealed: the assembled message is a pure byte concatenation of caller payload + the *snapshotted* context metrics (read once, frozen into the buffer) + node id; the fragment id is `Keccak256` over those bytes (inside `wh_publish`); signing is deterministic Ed25519 (RFC 8032 — `r = SHA-512(prefix‖msg) mod L`, no randomness). No ML/heuristics (M3/M4): the distress *kind* is supplied by the caller (the firing pillar), never inferred; no counting/thresholding/observation occurs in this module. No recursion (W15): every loop is a `while` over a fixed counter; no call graph cycle. Bit-identity (W5): all multi-byte fields are written **little-endian byte-by-byte** through `*u8` (avoids Trap 5 u32-store-width), so the witnessed bytes are representation-stable across CPUs.

### `dw_init(comm_cap)`
1. Reset `DWIT_OUT_COUNT = 0`, `DWIT_OUT_HEAD = 0`, `DWIT_HAVE_PREV = 0u8`.
2. `ident_from_bytes("aether::distress_witness", 24, &DWIT_PRODUCER)` and `ident_from_bytes("aether::distress_witness::produce", 32, &DWIT_OPID)` — deriving the canonical producer/op ids (string-literal byte lengths are exact: 24 and 32).
3. **M8 gate:** `if cap_verify_rights(comm_cap, DWIT_REQUIRED_RIGHTS) != 1u8 { return DWIT_E_CAP }`. Only a capability carrying both `crypto_sign` and `attest` rights may arm the distress producer. Store `DWIT_COMM_CAP = comm_cap`.
4. `DWIT_INITED = 1u8`; return `DWIT_OK`.

### `dw_produce(kind, payload, payload_len, args)`
1. **Guards (early-return, Trap 10 — no mutated checkpoint flag):**
   - `if DWIT_INITED == 0u8 { return SENTINEL }` (no implicit self-init: the gospel's `if DW_INITED==0 { dw_init() }` cannot stand because `dw_init` now requires a capability; an uninitialized producer is a hard error).
   - `if (kind < DWIT_KIND_MIN) | (kind > DWIT_KIND_MAX) { return SENTINEL }` — comparing `u8` ordering is **safe** (the SIGSEGV trap is signed `i32`/`i64` only; `algebraic_time.iii` documents u-type ordering as safe). Equivalently expressible as a 7-way `==` cascade if a future iiis tightens u8 compares.
   - `if payload_len > DWIT_PAYLOAD_MAX { return SENTINEL }` (fixes the gospel buffer-overflow risk).
   - **Re-verify capability at use (M8 defense-in-depth, in case it was revoked since init):** `if cap_verify_rights(DWIT_COMM_CAP, DWIT_REQUIRED_RIGHTS) != 1u8 { return SENTINEL }`.
2. **Assemble the distress message into `DWIT_BUF`** (let `bp = (&DWIT_BUF as u64) as *u8`):
   - `bp[0] = kind`.
   - `bp[1..5] = payload_len` as **LE u32** (4 bytes — widened from the gospel's 2 bytes, which truncated any payload ≥ 64 KiB; with the 4096 cap 2 bytes would technically suffice, but the 4-byte field future-proofs the on-wire format and matches `wh_compute_frag_id`'s 4-byte length convention).
   - `off = DWIT_HDR_BYTES (5)`. Copy `payload[0..payload_len]` to `bp[off..]` byte-by-byte; `off += payload_len`.
   - **Context snapshot (frozen once):** `score = ca_anomaly_score()`, `em_dist = ca_metric_at(15)`. Write `score` then `em_dist` as two LE u64 (16 bytes total) at `bp[off..off+16]` byte-by-byte; `off += 16`. (Metric index 15 = the entropy-monitor distance, per the gospel.)
   - **Node id:** `ni_node_id(&DWIT_NODE_ID)`; copy 32 bytes to `bp[off..off+32]`; `off += 32`. (Copy via local sink then byte-copy — avoids passing an interior `bp+off` pointer that the gospel computed as `(bp as u64 + nid_off) as *u8`; the local-sink form is the realized house style and dodges any interior-pointer aliasing.)
3. **Sign the prefix (everything up to and incl. node id):** `if ni_communication_sign(bp, off, (&DWIT_SIG as u64) as *u8) != 0i32 { return SENTINEL }`. Then copy the 64 signature bytes to `bp[off..off+64]` byte-by-byte; `off += 64`. (Fixes the gospel's `sp`→`bp` overlap ambiguity by signing into a dedicated `DWIT_SIG` buffer, then appending.)
4. **Commitments for the witness fragment:**
   - `wh_chain_root(&DWIT_IN_C)` → in_commit = current chain head (M6 chaining).
   - `ident_from_bytes(bp, off, &DWIT_OUT_C)` → out_commit = `Keccak256(assembled message)`.
5. **Antecedent (M6 / W16 chaining across distress events):** if `DWIT_HAVE_PREV == 1u8`, pass `antecedents = &DWIT_LAST_FRAG`, `n_ante = 1u32` (cite the previous distress fragment); else `antecedents = &DWIT_OUT_C` (any valid 32-byte ptr), `n_ante = 0u32`. This makes the distress stream a hash-linked sub-chain so a peer can verify no distress fragment was dropped — the gospel passed `n_ante = 0` unconditionally, losing intra-stream linkage (flagged + fixed).
6. **Publish:** `frag_idx = wh_publish(&DWIT_PRODUCER, &DWIT_OPID, &DWIT_IN_C, &DWIT_OUT_C, DWIT_REVTAG, DWIT_PHASE, DWIT_PILLAR, antecedents, n_ante, bp, off as u32, out_frag_id_sink)` where `out_frag_id_sink = &DWIT_LAST_FRAG`. If `frag_idx == 0xFFFFFFFFFFFFFFFFu64` (hook full/uninit) return the sentinel without mutating outbox state.
7. **Record + publish outbox:** copy `DWIT_LAST_FRAG` into the args bundle `args[8..40]` (the gospel's `out_frag_id`), set `DWIT_HAVE_PREV = 1u8`, and `ident_copy(&DWIT_LAST_FRAG, ring_slot(DWIT_OUT_HEAD))`; advance the ring: `DWIT_OUT_HEAD = (DWIT_OUT_HEAD + 1) ` masked to `< DWIT_MAX_OUTBOX` via the explicit `if head == DWIT_MAX_OUTBOX { head = 0 }` reset (DWIT_MAX_OUTBOX = 4096 is a power of two, so `head & 0xFFFu32` is equivalent and avoids the modulo-after-call Trap 11; spec uses the byte-mask form). Saturate `DWIT_OUT_COUNT` at `DWIT_MAX_OUTBOX`.
8. Return `frag_idx`.

   *Explicit-stack / no-recursion note (W15):* there is no recursion anywhere; the only “stack” is the linear assembly cursor `off`, a single `u64` local.

### `dw_outbox_count()` → returns `DWIT_OUT_COUNT`.
### `dw_outbox_at(idx, out)` → `if idx >= DWIT_OUT_COUNT { return DWIT_E_BAD }` (u32 ordering — safe); compute the **ring read index** = `(DWIT_OUT_HEAD + DWIT_MAX_OUTBOX - DWIT_OUT_COUNT + idx) & 0xFFFu32` so `idx=0` is the oldest retained fragment; `ident_copy(ring_slot(read_idx), out)`; return `DWIT_OK`.
### `dw_last_frag_id(out)` → `if DWIT_HAVE_PREV == 0u8 { return DWIT_E_BAD }`; `ident_copy(&DWIT_LAST_FRAG, out)`; `DWIT_OK`.

### Internal helper
```
fn dwit_outbox_ptr(idx: u32) -> *u8 { return ((&DWIT_OUTBOX as u64) + (idx as u64) * 32u64) as *u8 }
```
Uses the `((&ARR as u64)+off) as *u8` form (house style; **not** the gospel's `&DWIT_OUTBOX[expr] as *u8`). The `(idx as u64)` is masked-safe because `idx < 4096` always (caller-bounded), but per Trap 4 the multiply is done in u64 after the widening cast, never on a raw u32 slot.

## KAT Vectors (≥ 3)
A self-test (`dw_selftest`, returns `99u64` on pass) wires a deterministic harness. Because two of the four runtime deps (`node_identity`, `context_awareness`) are not-yet-built, the **Phase-2 acceptance gate** runs `dw_selftest` only after those siblings land; until then these are the contract the self-test encodes byte-for-byte:

- **KAT-1 (init capability gate, negative + positive):** With a capability id carrying neither `crypto_sign` nor `attest`, `dw_init(bad_cap)` MUST return `DWIT_E_CAP (-2)`. With `cap_env_init()`'s root cap (all rights) — or a child attenuated to exactly `0x1800` — `dw_init(cap)` MUST return `DWIT_OK (0)`. *(Proves the M8 gate FAILS closed on insufficient rights — not merely passes on good rights.)*

- **KAT-2 (produce → outbox round-trip + monotone index):** After a successful `dw_init`, set `DWIT_T_PAY[0..64]` to a fixed pattern (`T_PAY[i] = (i*3+1) & 0xFF`). `idx0 = dw_produce(DWIT_KIND_TIER2_RECOVERY, &DWIT_T_PAY, 64u32, &DWIT_T_ARGS)` MUST equal the `wh_next_idx()` captured immediately before the call, and `dw_outbox_count()` MUST become 1. `dw_outbox_at(0, &DWIT_T_FRAG)` MUST return `DWIT_OK` and yield a **non-zero** 32-byte id equal to the id written into `DWIT_T_ARGS[8..40]` and to `dw_last_frag_id`. A second `dw_produce(DWIT_KIND_AUDIT_FAILURE, …)` MUST return `idx0 + 1` and leave `dw_outbox_count() == 2`, with the two fragment ids **distinct** (distinct kind ⇒ distinct assembled bytes ⇒ distinct `Keccak256`). *(Mirrors the `witness_hook` self-test pattern at `witness_hook.iii:277-305`.)*

- **KAT-3 (antecedent chaining, M6):** After KAT-2's two productions, the **second** fragment's recorded antecedent set MUST be the first fragment's id. Verified structurally: re-publishing with the same inputs but `DWIT_HAVE_PREV` forced to 0 vs 1 yields **different** fragment ids (because `wh_compute_frag_id` hashes `ante_count`+antecedents). The self-test asserts `frag_id(with_prev) != frag_id(without_prev)`. *(Proves the chaining is load-bearing, not cosmetic.)*

- **KAT-4 (payload bound, negative):** `dw_produce(DWIT_KIND_FORBIDDEN_WRITE, &DWIT_T_PAY, DWIT_PAYLOAD_MAX + 1u32, &DWIT_T_ARGS)` MUST return the sentinel `0xFFFFFFFFFFFFFFFFu64` and leave `dw_outbox_count()` unchanged. *(Proves the overflow guard FAILS the over-long input — Trap-7/buffer-bound negative case.)*

- **KAT-5 (bad kind, negative):** `dw_produce(0u8, …)` and `dw_produce(8u8, …)` MUST both return the sentinel and not touch the outbox. *(Proves the kind range guard.)*

*(No standard external test vector applies — this is a composition module; the underlying crypto KATs are RFC 8032 in `crypt_ed25519.iii` corpus 193-197 and Keccak256("abc") in `identifier.iii`/`keccak256.iii`.)*

## Trap Exposure
| Trap | Exposed? | Avoidance |
|---|---|---|
| **1** multi-line `fn` | Yes (all sigs) | Every signature is single-line (see Skeleton). |
| **2** const linker-global | Yes | All consts `DWIT_`-prefixed; grep-confirmed no collision with STDLIB or the gospel's `DW_`. |
| **3** signed-int ordering SIGSEGV | **Avoided** | No signed `i32`/`i64` ordering compares. Status compares use `== / !=`. `u8`/`u32` ordering (`idx >= count`, `kind > MAX`) is safe per `algebraic_time.iii` note. |
| **4** u32-in-u64-slot garbage | Yes (outbox indexing) | All pointer math widens to u64 *first* (`(idx as u64) * 32u64`); `idx` is caller-bounded `< 4096`. No raw-u32-slot `as u64` into pointer arithmetic. |
| **5** u32-pointer store width | Yes (LE field writes) | All multi-byte fields written **byte-by-byte through `*u8`** with explicit `>> / & 0xFF` extraction; never `p[0] = v_u32` through a `*u32`. |
| **6** nested `/* */` | N/A | No nested comments; ASCII only. |
| **7** local `var` arrays | **Yes — gospel violates** | All four gospel function-local arrays (`buf`/`sig`/`in_c`/`out_c`) moved to module scope (`DWIT_BUF`/`DWIT_SIG`/`DWIT_IN_C`/`DWIT_OUT_C`). Non-reentrancy documented + acceptable (serialized witness emission). |
| **8** `} else {` one line | Minor | No `else` needed in the algorithm (early-return + `if` cascade); if added, kept one-line. |
| **9** em-dash in comment | Yes (prose-heavy header) | Header/comments use ASCII `--` only; no `—`. |
| **10** `let mut`-flag checkpoint | Yes | Guards use **early return**, not a mutated `let mut ok` flag. |
| **11** modulo-after-call | **Yes — ring advance** | Ring wrap uses the power-of-two **byte-mask** `head & 0xFFFu32` (DWIT_MAX_OUTBOX = 4096), never `head % 4096` after a call. |
| **12** `@specialize *T` stride | N/A | Module is not generic; no `@specialize`. |

## Gap / Fix List
The gospel candidate is PARTIAL. Every defect and its fix:

1. **Trap 7 (compile-blocking):** `var buf : [u8; 4096]`, `var sig : [u8; 64]`, `var in_c`, `var out_c` are function-local arrays → unsupported. **Fix:** move all four to module scope (`DWIT_BUF`, `DWIT_SIG`, `DWIT_IN_C`, `DWIT_OUT_C`).
2. **Element-address idiom:** `(&DW_OUTBOX[(idx as u64) * 32u64]) as *u8` and `(bp as u64 + nid_off) as *u8` use the `&ARR[expr]`/raw-interior forms that no realized aether module uses. **Fix:** `((&DWIT_OUTBOX as u64) + (idx as u64)*32u64) as *u8`; node id via a local sink + byte-copy.
3. **Prefix:** gospel uses `DW_`; assigned prefix is `DWIT_`. **Fix:** rename all consts/vars/fns to `DWIT_`/`dw_`/`dwit_` (public fns stay `dw_*` per the gospel’s documented API names; internal helper `dwit_outbox_ptr`).
4. **M8 — no capability gate (mandate violation):** signed, attesting emission is a privileged action; the gospel takes no capability. **Fix:** `dw_init(comm_cap)` verifies `CAP_RIGHT_CRYPTO_SIGN|CAP_RIGHT_ATTEST` via the real `cap_verify_rights`; `dw_produce` re-verifies (revocation-safe).
5. **M6/W16 — no antecedent chaining:** gospel always passes `n_ante = 0`, so the distress stream is not hash-linked and a dropped distress fragment is undetectable. **Fix:** cite the previous distress fragment id as the single antecedent once `DWIT_HAVE_PREV` is set.
6. **Buffer overflow:** gospel copies `payload_len` bytes into a 4096 buffer with no bound check; a payload near/over 4096 corrupts adjacent module-scope memory. **Fix:** `DWIT_PAYLOAD_MAX = 3968` derived from the exact layout; reject over-long payloads with the sentinel (KAT-4).
7. **Truncated length field:** gospel writes `payload_len` in 2 bytes (max 65535) but types it `u32`. **Fix:** 4-byte LE u32 field (`DWIT_HDR_BYTES = 5`), matching `wh_compute_frag_id`’s 4-byte length convention.
8. **Outbox saturation bug:** gospel’s `if DW_OUT_COUNT < DW_MAX_OUTBOX { … COUNT++ }` **silently stops recording** after 4096 distress events for the entire process lifetime — the most recent (most relevant) distress fragments are dropped. **Fix:** ring buffer keeping the most-recent 4096 (`DWIT_OUT_HEAD` + power-of-two mask); `dw_outbox_at` re-bases to oldest-retained.
9. **Implicit re-init:** gospel’s `if DW_INITED==0 { dw_init() }` inside `dw_produce` cannot stand — `dw_init` now needs a capability arg. **Fix:** uninitialized `dw_produce` is a hard sentinel error; arming is explicit.
10. **W2 / out_frag_id placement:** to add `comm_cap` without exceeding 4 params, the per-call extras (cap + out id) are folded behind `args: *u8`. **Fix:** `dw_produce(kind, payload, payload_len, args)`; cap read from `args[0..8]`, frag id written to `args[8..40]`; `dw_last_frag_id` also exposes it. *(Alternative considered: drop `out_frag_id` and rely solely on `dw_last_frag_id` — rejected so callers keep a single-call write-through, matching the gospel’s ergonomics.)*
11. **§3.5 #7 signing contract:** pinned the real `ed25519_sign(seed,pk,msg,len,sig)->u8` (32-byte seed, 5 params) as the obligation on the not-yet-built `ni_communication_sign`, with the `hotstuff.iii:206` seed‖pub fold as the canonical pattern, so key-separation is preserved without inlining crypto here.
12. **`ca_` namespace caution (flag, not a fix here):** the not-yet-built `context_awareness.iii` exports `ca_anomaly_score`/`ca_metric_at`; the built `numera/content_addr.iii` already exports `ca_compute/ca_eq/ca_compose/ca_branch_key/ca_is_zero`. The specific names do **not** collide, but the `ca_` prefix is shared — the `context_awareness.iii` author must confirm no exact-name clash at link time. Surfaced for the wave scheduler.

**Mandate audit summary:** M1 (NIH — only libc-free III modules used) ✓; M2/W5 (deterministic, LE byte-exact) ✓; M3/M4 (caller supplies kind; no inference) ✓; M5 (no bricking — pure producer, all failures return refusal sentinels) ✓; M6/M10 (chained + recomputable from recorded bytes) ✓ after fix #5; M7 (R−1) ✓; M8 (capability) ✓ after fix #4; M9 (reversible — `DWIT_REVTAG=1`) ✓; W2 (≤4 params) ✓ after fix #10; W13 (`dw_produce` uses ~12 named locals, < 20) ✓; W14/W15 (sentinel `while` loops, no `break`, no recursion) ✓; W9/W10/W12 (negative i32 errors, u8 bools, status returns) ✓.

## Implementation Skeleton
```iii
/* III/STDLIB/iii/aether/distress_witness.iii -- Layer 11, Module 48 (gospel).
 *
 * Signed distress witness producer.  On a constitutionally significant
 * anomaly (Tier-2/3 recovery, triple-check disagreement, predicted
 * quiescence, forbidden write, audit failure) it freezes the local
 * context-awareness snapshot, signs kind||payload||snapshot||node_id with
 * the node COMMUNICATION key (separate from the witness key so one key's
 * compromise never reveals the other), publishes a witness fragment via
 * wh_publish (chained, signed-in-transit -- W16/M6), and records the frag
 * id in a bounded federation-correlation outbox ring.
 *
 * Distress kinds: TIER2_RECOVERY, TIER3_RECOVERY, TC_DISAGREE_21,
 *   TC_DISAGREE_FATAL, PREDICTIVE_QUIESCENCE, FORBIDDEN_WRITE, AUDIT_FAILURE.
 *
 * Public API:
 *   dw_init(comm_cap)                          -> i32   (M8 capability gate)
 *   dw_produce(kind, payload, payload_len, args) -> u64 (frag idx; sentinel on fail)
 *   dw_outbox_count()                          -> u32
 *   dw_outbox_at(idx, out_frag_id)             -> i32
 *   dw_last_frag_id(out_frag_id)               -> i32
 *
 * args bundle (W2 fold): args[0..8] = comm_cap (LE u64);
 *                        args[8..40] = out_frag_id sink (written on success).
 *
 * NON-REENTRANT: module-scope assembly scratch; witness emission is serialized.
 * Hexad: kind_witness (+ kind_passage).  Ring: R-1.  K: 1.00.
 * Discipline: W2, W5, W8, W9, W10, W12, W14, W15, W16.
 */
module aether_distress_witness

extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_chain_root(out_id: *u8) -> i32 from "witness_hook.iii"
// NOT-YET-BUILT (sibling node_identity.iii): ni_communication_sign MUST wrap
// ed25519_sign(seed,pk,msg,len,sig)->u8 over the comm key (hotstuff.iii:206 fold); returns 0=ok.
extern @abi(c-msvc-x64) fn ni_communication_sign(msg: *u8, msg_len: u64, out_sig: *u8) -> i32 from "node_identity.iii"
extern @abi(c-msvc-x64) fn ni_node_id(out_id: *u8) -> i32 from "node_identity.iii"
// NOT-YET-BUILT (Layer-10 sibling context_awareness.iii):
extern @abi(c-msvc-x64) fn ca_anomaly_score() -> u64 from "context_awareness.iii"
extern @abi(c-msvc-x64) fn ca_metric_at(metric: u32) -> u64 from "context_awareness.iii"

const DWIT_OK            : i32 =  0i32
const DWIT_E_BAD         : i32 = -1i32
const DWIT_E_CAP         : i32 = -2i32
const DWIT_E_PAYLOAD     : i32 = -3i32
const DWIT_E_FULL        : i32 = -4i32

const DWIT_KIND_TIER2_RECOVERY        : u8 = 1u8
const DWIT_KIND_TIER3_RECOVERY        : u8 = 2u8
const DWIT_KIND_TC_DISAGREE_21        : u8 = 3u8
const DWIT_KIND_TC_DISAGREE_FATAL     : u8 = 4u8
const DWIT_KIND_PREDICTIVE_QUIESCENCE : u8 = 5u8
const DWIT_KIND_FORBIDDEN_WRITE       : u8 = 6u8
const DWIT_KIND_AUDIT_FAILURE         : u8 = 7u8
const DWIT_KIND_MIN                   : u8 = 1u8
const DWIT_KIND_MAX                   : u8 = 7u8

const DWIT_MAX_OUTBOX      : u32 = 4096u32
const DWIT_PAYLOAD_MAX     : u32 = 3968u32
const DWIT_HDR_BYTES       : u64 = 5u64
const DWIT_PILLAR          : u16 = 7u16
const DWIT_PHASE           : u8  = 10u8
const DWIT_REVTAG          : u8  = 1u8
const DWIT_REQUIRED_RIGHTS : u64 = 0x1800u64   // CRYPTO_SIGN | ATTEST

var DWIT_OUTBOX     : [u8; 131072]   // 4096 * 32
var DWIT_OUT_COUNT  : u32 = 0u32
var DWIT_OUT_HEAD   : u32 = 0u32
var DWIT_PRODUCER   : [u8; 32]
var DWIT_OPID       : [u8; 32]
var DWIT_COMM_CAP   : u64 = 0u64
var DWIT_INITED     : u8  = 0u8
var DWIT_BUF        : [u8; 4096]
var DWIT_SIG        : [u8; 64]
var DWIT_IN_C       : [u8; 32]
var DWIT_OUT_C      : [u8; 32]
var DWIT_NODE_ID    : [u8; 32]
var DWIT_LAST_FRAG  : [u8; 32]
var DWIT_HAVE_PREV  : u8  = 0u8

var DWIT_T_PAY      : [u8; 64]
var DWIT_T_FRAG     : [u8; 32]
var DWIT_T_FRAG2    : [u8; 32]
var DWIT_T_ARGS     : [u8; 40]

fn dwit_outbox_ptr(idx: u32) -> *u8 { return ((&DWIT_OUTBOX as u64) + (idx as u64) * 32u64) as *u8 }

fn dw_init(comm_cap: u64) -> i32 @export {
    // TODO: body per Algorithm dw_init -- reset ring; derive producer/opid ids;
    //       cap_verify_rights(comm_cap, DWIT_REQUIRED_RIGHTS) gate (-> DWIT_E_CAP);
    //       store DWIT_COMM_CAP; set DWIT_INITED.
}

fn dw_produce(kind: u8, payload: *u8, payload_len: u32, args: *u8) -> u64 @export {
    // TODO: body per Algorithm dw_produce -- early-return guards (inited, kind range,
    //       payload bound, re-verify cap); assemble DWIT_BUF (kind, LE-u32 len, payload,
    //       16B snapshot, 32B node id) byte-by-byte; ni_communication_sign into DWIT_SIG,
    //       append; wh_chain_root -> DWIT_IN_C; ident_from_bytes -> DWIT_OUT_C;
    //       antecedent = DWIT_LAST_FRAG iff DWIT_HAVE_PREV; wh_publish; on success
    //       record into args[8..40] + outbox ring (head & 0xFFFu32) + saturate count;
    //       return frag_idx (or 0xFFFFFFFFFFFFFFFFu64 sentinel).
}

fn dw_outbox_count() -> u32 @export {
    // TODO: return DWIT_OUT_COUNT.
}

fn dw_outbox_at(idx: u32, out_frag_id: *u8) -> i32 @export {
    // TODO: bound idx < DWIT_OUT_COUNT (-> DWIT_E_BAD); re-base to oldest-retained
    //       read_idx = (DWIT_OUT_HEAD + DWIT_MAX_OUTBOX - DWIT_OUT_COUNT + idx) & 0xFFFu32;
    //       ident_copy(dwit_outbox_ptr(read_idx), out_frag_id); return DWIT_OK.
}

fn dw_last_frag_id(out_frag_id: *u8) -> i32 @export {
    // TODO: if DWIT_HAVE_PREV == 0u8 return DWIT_E_BAD; ident_copy(&DWIT_LAST_FRAG, out); DWIT_OK.
}

fn dw_selftest() -> u64 @export {
    // TODO: body per KAT-1..KAT-5 -- cap gate negative+positive, produce/outbox round-trip,
    //       monotone index, distinct ids, antecedent-changes-id, payload-bound negative,
    //       bad-kind negative.  Return 99u64 on pass else failing-assertion ordinal.
    //       (Runs in Phase 2 once node_identity.iii + context_awareness.iii land.)
}
```
