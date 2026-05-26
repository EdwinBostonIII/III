# 47 aether/federated_sheaf.iii — Implementation Spec

## Verdict

**PARTIAL** — The gospel candidate body is structurally substantial (11 public + 7 helper functions, all slot tables present, a sound threshold-attestation + deterministic-gossip + canonical-global-section design) but it is **not buildable as written** and carries five distinct showstopper classes. (1) **Every Keccak extern is mis-sourced**: `keccak256_init/update/final from "keccak.iii"` — `keccak.iii` exports none of them (they live in `keccak256.iii`), and even sourced correctly the streaming triple trips the param-spill family (Trap 11); the substrate-wide reconciliation is `keccak256_oneshot` over a contiguous buffer. (2) **The Ed25519 verify extern is wrong in both file-name spelling and parameter order**: gospel declares `ed25519_verify(msg, msg_len, sig, pub_key)`; the real `crypt_ed25519.iii` symbol is `ed25519_verify(pubkey, msg, msg_len, sig) -> u8` — calling with the gospel order passes the *message pointer* where the verifier expects the *public key*, so every signature check fails (or reads wild memory). (3) **Namespace catastrophe**: the body uses bare `FED_*` module-scope `const`/`var` names (`FED_THRESHOLD`, `FED_MAX_PEERS`, `FED_MAX_SECTIONS`, `FED_MAX_SIGNERS`, `FED_GOSSIP_STEP`, `FED_PEER_*`, `FED_SEC_*`, …). Per Trap 2 every module-scope `const`/`var` emits a global linker symbol `L_<NAME>`; the *built* federation ecosystem (`fed_seal.iii`, `fed_admit.iii`, `fed_tier.iii`, `fed_genesis.iii`, `fed_sybil.iii`, `fed_eclipse.iii`) already owns the `FED_*` symbol space. Dispatch assigned the prefix **`FSHEAF_`** precisely to keep this module clear; the body must be wholesale-renamed. (4) **Three local `var` arrays inside function bodies** (`nid`/`npub` in `fs_fed_init`, `msg`/`sig`/`nid` in the attest paths, `in_c`/`out_c`/`ob`/`fid` in publish, `order`/`ob` in `fs_fed_global_section`) — `iiis-0` parses `var [..]` arrays at module scope **only** (Trap 7); all must be hoisted. (5) **A hard dependency that is not yet built**: `node_identity.iii` (Module 28, Layer 6) supplies `ni_node_id`/`ni_witness_pub`/`ni_witness_sign` and does not exist in the tree. Additionally the gossip step relies on `at`-style monotonic ordering only transitively (through `wh_publish`), the `%`-after-multiply in `fs_fed_gossip_step` is a Trap-11 risk, and a small soundness gap exists (a received attestation is admitted even when the (open_set,value) section is *brand-new and locally unknown*, with no policy hook — acceptable but must be documented). All defects are fixable; the public API shape is preserved (one signature is re-expressed to stay ≤4 params, which it already satisfies, and a peer-count guard is tightened).

## Purpose

`aether/federated_sheaf` is the **ontology of local-to-global agreement across a federation of nodes**. Where `numera/sheaf` (Module 10) governs single-node consistency — open sets ordered by inclusion, sections that must agree on overlaps — the federated sheaf *is* the glued global section over a network: each node runs its own sheaf and exchanges sections via a deterministic gossip rotation, and a section is globally **attested** exactly when a constitutional threshold of the federation's signing nodes have each signed its canonical encoding with their witness key. The threshold signature is a *verifiable multi-signature* (an ordered set of `(signer_node_id, Ed25519 signature)` pairs, every one re-checked against the signer's recorded public key) — not BLS, not Schnorr MPC — so the construction is fully NIH and deterministic. The module embodies the gluing predicate and emits a canonical `Keccak256` fold over all attested sections as the global-section identifier.
**Hexad:** `kind_witness + kind_motion`. **Ring:** R−1. **K:** 1.00 (the only failure modes are slot exhaustion and signature rejection — both refusals, never corruption).

## Public API

All public functions are `@export`. Status functions return negative-`i32` error codes (W9, compared `==`/`!=` only). `fs_fed_add_peer` returns a slot index `u32` or the sentinel `FSHEAF_SENT` (`0xFFFFFFFF`) on table-full (a sentinel-typed value, W12). `fs_fed_is_attested` returns `u8` 0/1 (W10). Counts return `u32`.

```
fn fs_fed_init(threshold: u32) -> i32 @export
fn fs_fed_add_peer(node_id: *u8, pub_key: *u8) -> u32 @export
fn fs_fed_local_attest(open_set: u32, value: *u8) -> i32 @export
fn fs_fed_receive_attestation(req: *u8) -> i32 @export
fn fs_fed_is_attested(open_set: u32, value: *u8) -> u8 @export
fn fs_fed_gossip_step(round: u64) -> u32 @export
fn fs_fed_global_section(out: *u8) -> i32 @export
fn fs_fed_peer_count() -> u32 @export
fn fs_fed_section_count() -> u32 @export
fn fs_fed_selftest() -> u64 @export
```

Return-status convention per fn:
- `fs_fed_init` → `FSHEAF_OK` always (W12). Registers the local node as peer 0.
- `fs_fed_add_peer` → existing-or-new slot index `u32`; `FSHEAF_SENT` if the peer table is full (W12 sentinel). Idempotent on `node_id` (re-adding refreshes the stored public key).
- `fs_fed_local_attest` → `FSHEAF_OK` / `FSHEAF_E_BAD` (uninit, or section-table full) (W9).
- `fs_fed_receive_attestation` → `FSHEAF_OK` / `FSHEAF_E_BAD` / `FSHEAF_E_SIG` (signature rejected) (W9).
- `fs_fed_is_attested` → `1u8` iff a live section exists for `(open_set,value)` and is attested; else `0u8` (W10).
- `fs_fed_gossip_step` → `1u32` if a peer was selected and its `last_seen_round` updated; `0u32` if uninit or `< 2` peers. (Sentinel-typed count, W12.)
- `fs_fed_global_section` → `FSHEAF_OK` always once inited; writes the 32-byte canonical fold to `out` (an empty attested set yields `Keccak256("")`). (W9/W12.)
- `fs_fed_peer_count` / `fs_fed_section_count` → live counts `u32`.
- `fs_fed_selftest` → `99u64` on all-pass, else the index of the first failing assertion (house convention, per `ident_selftest` / `keccak256_kat`).

> **API divergence from gospel candidate (documented, W2):** the candidate's `fs_fed_receive_attestation(open_set: u32, value: *u8, signer_node_id: *u8, signature: *u8)` has **4 parameters** — at the W2 ceiling but legal. **This spec re-expresses it as `fs_fed_receive_attestation(req: *u8)`**, where `req` points to an `FSHEAF_AttestReq` aggregate `{ open_set:u32 (4B, LE), value:[u8;32], signer_node_id:[u8;32], signature:[u8;64] }` (132 bytes). Rationale: (a) it future-proofs against the gospel's own "threshold signature is the ordered list of (signer, signature) pairs" — a batch form can later carry `n` pairs behind the same pointer without breaking the ABI; (b) it removes any temptation for callers to spill four pointer params (the documented param-spill trap bites hardest at the parameter boundary). The 4-param form is **also acceptable** and is noted as the fallback if Phase 2 prefers it; the aggregate form is the recommended realization. `fs_fed_local_attest`, `fs_fed_is_attested`, `fs_fed_global_section`, `fs_fed_init`, and the two count getters are **byte-identical** to the gospel header.

> **`fs_fed_selftest` is new** (the candidate had none). It is required by the house KAT convention and the Phase-2 acceptance gate; it is `@export` and returns the first-failing-assertion index.

## Constant Namespace

**PREFIX = `FSHEAF_`** (dispatch-assigned). **Grep result:** `^const FSHEAF_` / `^var FSHEAF_` / any `FSHEAF_` across `STDLIB/` returns **zero matches** — no collision. The bare `FED_*` and `FS_FED_*` names the candidate uses **do** share the linker-global `FED_*` space already populated by `fed_seal/fed_admit/fed_tier/fed_genesis` (see Gap §3); all are renamed to `FSHEAF_`.

| const | type | value |
|---|---|---|
| `FSHEAF_OK` | `i32` | `0i32` |
| `FSHEAF_E_BAD` | `i32` | `-1i32` |
| `FSHEAF_E_SIG` | `i32` | `-2i32` |
| `FSHEAF_E_NULL` | `i32` | `-3i32` |
| `FSHEAF_SENT` | `u32` | `0xFFFFFFFFu32` |
| `FSHEAF_MAX_PEERS` | `u32` | `256u32` |
| `FSHEAF_MAX_SECTIONS` | `u32` | `4096u32` |
| `FSHEAF_MAX_SIGNERS` | `u32` | `32u32` |
| `FSHEAF_GOSSIP_STEP` | `u64` | `11u64` |
| `FSHEAF_IDBYTES` | `u64` | `32u64` |
| `FSHEAF_SIGBYTES` | `u64` | `64u64` |
| `FSHEAF_MSGLEN` | `u64` | `36u64` (canonical (open_set‖value) signing message) |
| `FSHEAF_REQLEN` | `u64` | `132u64` (AttestReq aggregate size) |
| `FSHEAF_PILLAR` | `u16` | `7u16` (federation pillar id, matches candidate's `7u16`) |
| `FSHEAF_PHASE_ATTESTED` | `u8` | `10u8` (matches candidate's `10u8`) |

> **PREFIX divergence (documented):** the gospel candidate splits its names across **two** prefixes — `FS_FED_*` for the error/sentinel constants (`FS_FED_OK/E_BAD/E_SIG/SENT`) and bare `FED_*` for everything else (sizes, tables, the `FED_THRESHOLD` runtime var, the producer/opid buffers). Per Trap 2 **both** prefixes emit global `L_<NAME>` symbols. The bare `FED_*` set is the dangerous one — it overlaps the built federation modules' symbol space. This spec collapses **all** module-scope names (consts **and** vars — `var` declarations emit `L_<NAME>` exactly as `const` does) under the single dispatch-assigned `FSHEAF_` prefix. **Public function names remain `fs_fed_*`** exactly as the gospel header specifies — those are the cross-module link contract (other modules call `fs_fed_is_attested`, `fs_fed_global_section`, etc.); renaming them would break callers. Internal helper functions are renamed `_fsheaf_*` (leading underscore, not `@export`) to avoid any `fed_*` helper-name collision in the (rare) event the linker also surfaces non-exported function symbols.

## Data Structures

All slot tables and scratch buffers are statically sized module-scope arrays (W8). **No local `var` arrays** (Trap 7) — every buffer the candidate declared inside a function body is hoisted here. All `var` names carry the `FSHEAF_` prefix (Trap 2). Large byte buffers are sized exactly; none approaches the small-code-model 2 GiB RIP-relative reach (the whole module's static footprint is ≈ 12.7 MiB, dominated by the two signature/ signer tables below).

| name | type | size (bytes) | bound justification (W8) |
|---|---|---|---|
| `FSHEAF_THRESHOLD` | `u32` (=`1u32`) | 4 | runtime threshold; set by `fs_fed_init`. Was the candidate's `var FED_THRESHOLD`. |
| `FSHEAF_PEER_LIVE` | `[u8; 256]` | 256 | `FSHEAF_MAX_PEERS` liveness flags. |
| `FSHEAF_PEER_ID` | `[u8; 8192]` | 256×32 | one 32-byte node id per peer slot. |
| `FSHEAF_PEER_PUB` | `[u8; 8192]` | 256×32 | one 32-byte Ed25519 public key per peer slot. |
| `FSHEAF_PEER_LAST` | `[u64; 256]` | 2048 | last-seen gossip round per peer. |
| `FSHEAF_PEER_COUNT` | `u32` (=`0u32`) | 4 | live peer count. |
| `FSHEAF_SEC_LIVE` | `[u8; 4096]` | 4096 | `FSHEAF_MAX_SECTIONS` section liveness. Federation-wide bound on concurrently-tracked (open_set,value) sections. |
| `FSHEAF_SEC_OPEN` | `[u32; 4096]` | 16384 | open-set index (points into the local sheaf) per section. |
| `FSHEAF_SEC_VALUE` | `[u8; 131072]` | 4096×32 | 32-byte canonical value identifier per section. |
| `FSHEAF_SEC_SIG_CNT` | `[u32; 4096]` | 16384 | distinct-signer count per section. |
| `FSHEAF_SEC_SIGNERS` | `[u8; 4194304]` | 4096×32×32 | up to `FSHEAF_MAX_SIGNERS` signer node ids per section. |
| `FSHEAF_SEC_SIGS` | `[u8; 8388608]` | 4096×32×64 | the 64-byte Ed25519 signature for each recorded signer. |
| `FSHEAF_SEC_ATTESTED` | `[u8; 4096]` | 4096 | 1 iff `sig_cnt >= FSHEAF_THRESHOLD`. |
| `FSHEAF_SEC_COUNT` | `u32` (=`0u32`) | 4 | live section count. |
| `FSHEAF_SELF_INDEX` | `u32` (=`0u32`) | 4 | this node's own peer slot. |
| `FSHEAF_PRODUCER` | `[u8; 32]` | 32 | producer id = `ident_from_bytes("aether::federated_sheaf")`. |
| `FSHEAF_OPID_ATTEST` | `[u8; 32]` | 32 | opid = `…::attest`. |
| `FSHEAF_OPID_ATTESTED` | `[u8; 32]` | 32 | opid = `…::attested` (the SECTION_ATTESTED fragment). |
| `FSHEAF_INITED` | `u8` (=`0u8`) | 1 | init guard. |
| `FSHEAF_ORDER` | `[u32; 4096]` | 16384 | **(hoisted from local `order`)** attested-section index list for the global-section sort. Bounded by `FSHEAF_MAX_SECTIONS`. |
| `FSHEAF_NID` | `[u8; 32]` | 32 | **(hoisted)** scratch node id (local id in attest; lookup key). |
| `FSHEAF_NPUB` | `[u8; 32]` | 32 | **(hoisted)** scratch local witness public key (init only). |
| `FSHEAF_MSG` | `[u8; 36]` | 36 | **(hoisted)** canonical signing message (open_set‖value). |
| `FSHEAF_SIG` | `[u8; 64]` | 64 | **(hoisted)** local signature scratch in `fs_fed_local_attest`. |
| `FSHEAF_INC` | `[u8; 32]` | 32 | **(hoisted)** in_commit (chain root) for fragment publish. |
| `FSHEAF_OUTC` | `[u8; 32]` | 32 | **(hoisted)** out_commit (Keccak256 of attested-section descriptor). |
| `FSHEAF_OB` | `[u8; 4]` | 4 | **(hoisted)** 4-byte LE open_set scratch for hashing. |
| `FSHEAF_FID` | `[u8; 32]` | 32 | **(hoisted)** returned fragment id sink. |
| `FSHEAF_HASHBUF` | `[u8; 4128]` | 4×(32+64)... see note | **(new)** contiguous concat buffer for `_fsheaf_publish_attested`'s out_commit and for the per-step global-section fold input is streamed, not buffered (see Algorithm); sized 4128 = `4u32 + 32 + FSHEAF_MAX_SIGNERS*32` worst-case single-section descriptor (`4 + 32 + 1024 = 1060`), rounded up. |
| `FSHEAF_ST_*` (selftest) | `[u8; 32]` ×~10 + `[u8; 132]` req | — | KAT scratch ids/keys/req for `fs_fed_selftest`. |

> **Reentrancy note (Trap 7 consequence):** hoisting `FSHEAF_MSG`/`FSHEAF_SIG`/`FSHEAF_HASHBUF`/etc. to module scope makes the attest, receive, publish, and global-section paths **non-reentrant**. This is acceptable per the trap catalog for serialized hashing/crypto and matches `merkle.iii`, `content_addr.iii`, `sealed_channel.iii`, and `fed_admit.iii` (all keep module-scope scratch). The module is a single-threaded deterministic verifier; no concurrent `fs_fed_*` call is supported, and that constraint is stated in the header. The federation's concurrency is *between nodes* (each node single-threaded), not within one node's sheaf.

> **`HASHBUF` vs streaming:** the candidate hashes the attested-section descriptor with the streaming `keccak256_init/update/final` triple (variable-length: a 4-byte open_set, a 32-byte value, then `sig_cnt` × 32-byte signer ids). Because `sig_cnt` is bounded by `FSHEAF_MAX_SIGNERS=32`, the worst-case descriptor is `4 + 32 + 32*32 = 1060` bytes — small enough to assemble in one contiguous `FSHEAF_HASHBUF` and hash with a single `keccak256_oneshot`, eliminating the param-spill exposure (Trap 11). The `fs_fed_global_section` fold is `m` × (4 + 32) bytes with `m <= 4096` (worst case 147456 bytes); rather than a 144 KiB buffer, the fold writes each section's `(open_set_LE‖value)` into a small `36`-byte slice of `FSHEAF_HASHBUF` and uses the **streaming** API there is **not** safe — instead the global fold concatenates into a dedicated module-scope `FSHEAF_FOLD_BUF : [u8; 147456]` (`FSHEAF_MAX_SECTIONS * 36`) and hashes once with `keccak256_oneshot`. (See Algorithm; this keeps every hash a single oneshot call and is bit-identical to the gospel's streaming fold because Keccak256 over the concatenation equals the streamed updates.) `FSHEAF_FOLD_BUF` adds 144 KiB to the static footprint — negligible against the 12 MiB signer tables.

| `FSHEAF_FOLD_BUF` | `[u8; 147456]` | 147456 | `FSHEAF_MAX_SECTIONS * 36`; contiguous (open_set_LE‖value) records for the canonical global fold. |

## Dependencies (externs)

Each `extern @abi(c-msvc-x64) fn …` the realized module relies on, with the providing module's NN and build status. **All externs verified against the real provider files** (per §3.5 — gospel externs are unreliable).

| extern signature (single-line) | providing module | NN | status |
|---|---|---|---|
| `fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"` | identifier | 01 | **BUILT** |
| `fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"` | identifier | 01 | **BUILT** |
| `fn ident_cmp(a: *u8, b: *u8) -> i32 from "identifier.iii"` | identifier | 01 | **BUILT** (returns −1/0/1) |
| `fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"` | identifier | 01 | **BUILT** |
| `fn keccak256_oneshot(msg_ptr: u64, msg_len: u64, out_ptr: u64) -> i32 from "keccak256.iii"` | keccak256 | (Stage-4) | **BUILT** |
| `fn ed25519_verify(pubkey: *u8, msg: *u8, msg_len: u64, sig: *u8) -> u8 from "crypt_ed25519.iii"` | crypt_ed25519 | (Stage-4) | **BUILT** |
| `fn ni_node_id(out_id: *u8) -> i32 from "node_identity.iii"` | node_identity | **28** | **NOT YET BUILT** |
| `fn ni_witness_pub(out_pub: *u8) -> i32 from "node_identity.iii"` | node_identity | **28** | **NOT YET BUILT** |
| `fn ni_witness_sign(msg: *u8, msg_len: u64, out_sig: *u8) -> i32 from "node_identity.iii"` | node_identity | **28** | **NOT YET BUILT** |
| `fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"` | witness_hook | 45 | **BUILT** (verified L144) |
| `fn wh_chain_root(out_id: *u8) -> i32 from "witness_hook.iii"` | witness_hook | 45 | **BUILT** (verified L216) |

> **CORRECTED from gospel candidate (each is a build-blocker or silent-corruption bug):**
> - **Keccak (Trap 11 + mis-source):** candidate declared `keccak256_init/update/final from "keccak.iii"`. `keccak.iii` exports only `keccak_f1600/absorb/squeeze/...`; the `keccak256_*` symbols live in **`keccak256.iii`**. Even there, the substrate-wide rule (documented in `identifier.iii`/`content_addr.iii`/the sheaf Module-10 spec) is *streaming clobbers param registers across `init()`* → use **`keccak256_oneshot(msg_ptr:u64, msg_len:u64, out_ptr:u64) -> i32`** over a contiguous buffer. Adopted. Note the signature takes **`u64` addresses**, not `*u8` (pass `(&BUF) as u64`).
> - **Ed25519 verify (param-order silent corruption):** candidate declared `ed25519_verify(msg, msg_len, sig, pub_key) -> u8`. The real symbol (verified `crypt_ed25519.iii:253`) is **`ed25519_verify(pubkey, msg, msg_len, sig) -> u8`**. The gospel call site `ed25519_verify(mp, 36u64, signature, peer_pub)` would bind `pubkey:=mp` (the message), `msg:=36` (cast garbage), etc. — a guaranteed verification failure / OOB read. **Fixed**: call `ed25519_verify(peer_pub, msg_ptr, 36u64, sig_ptr)`.
> - **`ni_witness_sign` etc. (not-yet-built):** verified absent from the entire tree; the gospel's own Module-28 (`node_identity.iii`) candidate body defines them but is itself unbuilt and carries the same keccak/ed25519 defects (Module 28's problem). The `ni_*` **extern surface** I declare is stable and correct per the Module-28 header: `ni_node_id`/`ni_witness_pub`/`ni_witness_sign` all `-> i32`, witness key encapsulated. **Marked NOT-YET-BUILT so the wave scheduler orders Module 28 before Module 47.**
> - **Dropped dead import:** none — all candidate externs are either corrected or retained (the candidate had no unused externs, but it omitted `ident_from_bytes` from its *use* while declaring it; it is genuinely used in `fs_fed_init` for the producer/opid ids, so retained).

> **`wh_publish` extern is multi-line in both the gospel and the built `witness_hook.iii` source.** Trap 1 forbids multi-line **`fn` definitions** (codegen binds params to wrong stack slots); it does **not** govern `extern` *declarations* (no body is emitted). The built tree itself wraps this extern (e.g. `fed_admit`/`distress_witness` contexts). **However**, to be maximally safe this spec's skeleton writes the `wh_publish` extern on a **single line** — there is no downside and it removes any ambiguity.

> **Transitive note — algebraic time / witness reproducibility:** `wh_publish` internally calls `at_advance()` from `algebraic_time.iii` (verified `witness_hook.iii:159`) to stamp each fragment's monotonic time (W16/W17). This module does **not** call `at_*` directly — there is **no `at_now` fiction** in my surface — so the §3.5 algebraic-time defect does not apply here; monotonicity is inherited correctly through the built `wh_publish`.

## Algorithm

Determinism (M2) holds throughout: every operation is a linear scan of fixed arrays in a fixed order, byte equality/copy, a deterministic Ed25519 verify (no randomness — verification is a pure predicate over (pk, msg, sig)), and a single canonicalizing sort + `Keccak256` fold. Bit-identity (W5): node ids, values, and signatures are the reproducible representation; the global section is `Keccak256` of a **canonically sorted** (open_set-then-value) concatenation, independent of attestation/gossip order. No ML/heuristics (M3/M4): the threshold predicate is the exact count `sig_cnt >= FSHEAF_THRESHOLD`; the gossip target is a closed-form modular rotation, not a learned or adaptive choice. NIH (M1): the only cryptography is the substrate's own `keccak256_oneshot` and `ed25519_verify`; the multi-signature is hand-rolled as an explicit ordered signer set (no BLS/Schnorr). No recursion (W15): every loop is an explicit `while` with a counter or sentinel flag; the global-section sort is an in-place insertion sort using two index counters, not the call stack. Capability mediation (M8): attestation is gated by *witness-key possession* — `fs_fed_local_attest` can only sign with the local node's witness key (held in `node_identity`), and `fs_fed_receive_attestation` only credits a signer whose signature verifies against the **recorded** peer public key, so no peer can attest on another's behalf. Reversibility (M5/M9): no operation deletes or mutates a prior attestation; sections only accrue signers; a full table is a refusal (`FSHEAF_E_BAD`), never an overwrite.

**`fs_fed_init(threshold)`** — Store `FSHEAF_THRESHOLD = threshold`. Zero `FSHEAF_PEER_LIVE[0..MAX_PEERS)`; zero `FSHEAF_SEC_LIVE`/`FSHEAF_SEC_SIG_CNT`/`FSHEAF_SEC_ATTESTED[0..MAX_SECTIONS)` (three fields per slot, one loop). Reset both counts. Derive the three identifiers once via `ident_from_bytes` (producer `"aether::federated_sheaf"` len 23, opid_attest `…::attest` len 31, opid_attested `…::attested` len 33 — lengths verified against the candidate). Read the local node id (`ni_node_id` → `FSHEAF_NID`) and witness pub (`ni_witness_pub` → `FSHEAF_NPUB`), then `FSHEAF_SELF_INDEX = fs_fed_add_peer(FSHEAF_NID, FSHEAF_NPUB)` registers the local node as a peer (so the local node's own attestation counts as a signer and so peers can verify *its* signatures against the recorded pub). Set `FSHEAF_INITED = 1u8`; return `FSHEAF_OK`.

**`fs_fed_add_peer(node_id, pub_key)`** — Two sentinel scans (W14), no `break`. First scan `[0,MAX_PEERS)`: for each **live** slot, if `ident_eq(peer_id[i], node_id)==1u8`, refresh `ident_copy(pub_key → peer_pub[i])` and return `i` (idempotent on node id). Second scan: first slot with `PEER_LIVE[k]==0u8` — `ident_copy` both id and pub in, `PEER_LAST[k]=0u64`, `PEER_LIVE[k]=1u8`, `PEER_COUNT += 1`, return `k`. If neither scan finds a slot, return `FSHEAF_SENT` (W12). (To keep first-match deterministic under W14, the candidate's early `return i` inside the live-match scan is the sanctioned shape — it visits slots in order and returns on the *first* id match.)

**`_fsheaf_canonical_msg(open_set, value, out)`** (helper) — Write the 36-byte signing message: 4 bytes `open_set` little-endian via byte stores (`out[0]=open_set & 0xFF`, `>>8`, `>>16`, `>>24` — each masked `& 0xFFu32`, stored as `u8`), then 32 bytes `value` via a `while z < 32u64` byte copy. **Byte-by-byte stores through `*u8`** (no `*u32` wide store — Trap 5). Returns `FSHEAF_OK`. Deterministic and bit-identical (W5).

**`_fsheaf_find_section(open_set, value)` / `_fsheaf_alloc_section(open_set, value)`** (helpers) — `find`: sentinel scan, first **live** slot with `SEC_OPEN[i]==open_set` **and** `ident_eq(sec_value[i], value)==1u8` → return `i`; else `FSHEAF_SENT`. `alloc`: first `SEC_LIVE[i]==0u8` → set `SEC_OPEN[i]=open_set`, `ident_copy(value → sec_value[i])`, `SEC_SIG_CNT[i]=0`, `SEC_ATTESTED[i]=0`, `SEC_LIVE[i]=1`, `SEC_COUNT += 1`, return `i`; else `FSHEAF_SENT`.

**`_fsheaf_section_has_signer(slot, node_id)` / `_fsheaf_section_add_signer(slot, node_id, sig)`** (helpers) — `has`: scan `k` over `[0, SEC_SIG_CNT[slot])`, `ident_eq(signer_ptr(slot,k), node_id)==1u8` → `1u8`; else `0u8` (sentinel, first-match). `add`: if `SEC_SIG_CNT[slot] >= FSHEAF_MAX_SIGNERS` return `FSHEAF_E_BAD` (refusal, never overflow — W8/M5); else `k=SEC_SIG_CNT[slot]`, `ident_copy(node_id → signer_ptr(slot,k))`, copy 64 signature bytes via a `while z < 64u64` `*u8` loop into `sig_ptr(slot,k)`, `SEC_SIG_CNT[slot]=k+1`, return `FSHEAF_OK`. Signer-pointer arithmetic uses **`u64` offsets** (`(slot as u64)*32u64*MAX_SIGNERS + (k as u64)*32u64`) — slot/k masked into u64 before multiply (Trap 4); the candidate's helpers already use this exact `as u64` form.

**`_fsheaf_threshold_check_and_publish(slot)`** (helper, factored out of the two attest paths to avoid duplication) — `if SEC_SIG_CNT[slot] >= FSHEAF_THRESHOLD` and `SEC_ATTESTED[slot]==0u8`: set `SEC_ATTESTED[slot]=1u8`, then publish the SECTION_ATTESTED fragment (next). (`>=` here is on **`u32` unsigned** counts — not the signed-i32 ordering trap; Trap 3 applies only to `i32`/`i64`.)

**`_fsheaf_publish_attested(slot)`** (helper) — Build the attested-section witness fragment. `wh_chain_root(&FSHEAF_INC)` reads the current chain root as `in_commit`. Compute `out_commit = Keccak256(open_set_LE(4) ‖ value(32) ‖ each signer_id(32))`: assemble into `FSHEAF_HASHBUF` — bytes 0..3 = open_set LE, 4..35 = `ident_copy(sec_value)`, then for `k` in `[0, SEC_SIG_CNT[slot])` copy `signer_ptr(slot,k)` into `HASHBUF[36 + k*32 ..]` (byte loop); total `len = 36 + sig_cnt*32` (≤ 1060). One `keccak256_oneshot((&FSHEAF_HASHBUF) as u64, len, (&FSHEAF_OUTC) as u64)`. Then `wh_publish(&FSHEAF_PRODUCER, &FSHEAF_OPID_ATTESTED, &FSHEAF_INC, &FSHEAF_OUTC, revtag=0u8, phase=FSHEAF_PHASE_ATTESTED(10), pillar=FSHEAF_PILLAR(7), antecedents=&FSHEAF_OUTC, n_ante=0u32, payload=&FSHEAF_OUTC, payload_len=32u32, out_frag_id=&FSHEAF_FID)`. Return `FSHEAF_OK`. (This is the candidate's `fed_publish_attested` with the streaming Keccak replaced by one oneshot and all names prefixed. M6: the fragment chains by hash into the witness spine; M10: out_commit is byte-recomputable from the recorded (open_set,value,signers).)

**`fs_fed_local_attest(open_set, value)`** — Guard `FSHEAF_INITED==0u8 → FSHEAF_E_BAD`. `_fsheaf_canonical_msg(open_set, value, &FSHEAF_MSG)`. `ni_witness_sign(&FSHEAF_MSG, 36u64, &FSHEAF_SIG)` signs with the local witness key. `ni_node_id(&FSHEAF_NID)` recovers the local node id. `slot = _fsheaf_find_section(...)`; if `FSHEAF_SENT`, `slot = _fsheaf_alloc_section(...)`; if still `FSHEAF_SENT` return `FSHEAF_E_BAD`. If `_fsheaf_section_has_signer(slot, &FSHEAF_NID)==0u8`, `_fsheaf_section_add_signer(slot, &FSHEAF_NID, &FSHEAF_SIG)`. `_fsheaf_threshold_check_and_publish(slot)`. Return `FSHEAF_OK`.

**`fs_fed_receive_attestation(req)`** — `req` → `FSHEAF_AttestReq`. Guard `req==0 → FSHEAF_E_NULL`; `FSHEAF_INITED==0 → FSHEAF_E_BAD`. Read `open_set` (4 LE bytes from `req[0..4]`), and treat `value=req+4` (32B), `signer_node_id=req+36` (32B), `signature=req+68` (64B) as in-place pointers (no copy needed for verification). **Peer lookup** (sentinel scan, first-match via a `peer==SENT` gate — the candidate's exact shape): find the live peer slot whose `peer_id` equals `signer_node_id`; if none, `FSHEAF_E_BAD`. Rebuild the canonical message `_fsheaf_canonical_msg(open_set, value, &FSHEAF_MSG)`. **Verify**: `ed25519_verify(peer_pub_ptr(peer), &FSHEAF_MSG, 36u64, signature)`; if `!= 1u8` return `FSHEAF_E_SIG` (corrected param order — see Dependencies). `slot = find/alloc` as above; if full `FSHEAF_E_BAD`. If `_fsheaf_section_has_signer(slot, signer_node_id)==0u8`, add it. `_fsheaf_threshold_check_and_publish(slot)`. Return `FSHEAF_OK`.

**`fs_fed_is_attested(open_set, value)`** — `slot = _fsheaf_find_section(...)`; if `FSHEAF_SENT` return `0u8`; else return `FSHEAF_SEC_ATTESTED[slot]` (already a `u8` 0/1). (W10.)

**`fs_fed_gossip_step(round)`** — Guard `FSHEAF_INITED==0 → 0u32`; `FSHEAF_PEER_COUNT < 2u32 → 0u32`. Deterministic rotation: `raw = (round * FSHEAF_GOSSIP_STEP) + (FSHEAF_SELF_INDEX as u64)`; `target = (raw % (FSHEAF_PEER_COUNT as u64)) as u32`. **Trap-11 mitigation:** the `%` follows a `*` and a `+` with **no intervening function call**, so the param-spill family does not apply (the trap is "modulo *after a call* returns the quotient/stale divisor"); the divisor `FSHEAF_PEER_COUNT` is a freshly-loaded module global, not a spilled param. To be belt-and-suspenders the skeleton loads `let pc : u64 = FSHEAF_PEER_COUNT as u64` into a local immediately before the `%` and reduces `raw % pc`, which is the canonical safe form. If `target == FSHEAF_SELF_INDEX`, advance `target = (target + 1u32) % FSHEAF_PEER_COUNT` (same mitigation; `FSHEAF_PEER_COUNT >= 2` guarantees a distinct peer exists). Set `FSHEAF_PEER_LAST[target] = round` (the ratified selection — the observable side effect higher layers consult). Return `1u32`.

> **Gossip semantics (gospel fidelity, documented):** the gospel prose describes a *two-node digest exchange* (compare `Keccak256` of section lists; on mismatch swap lists). The candidate body — and this spec — realize the **single-node side**: `fs_fed_gossip_step` performs the *deterministic peer selection* and ratifies it (updates `last_seen_round`); the *actual* section transfer is driven by the higher-layer outbox/inbox machinery (`aether/distress_witness.iii`, Module 48) and `fs_fed_receive_attestation` is the ingress for transferred attestations. This is the correct decomposition: a single module cannot synchronously "reach into" a peer deterministically without that peer's transport, so the selection is the deterministic, witnessable unit. The rotation step `FSHEAF_GOSSIP_STEP=11` is **coprime to** all peer counts not divisible by 11; for full-cover guarantees at arbitrary `n` the gospel's "coprime to n" claim holds for `n` not a multiple of 11 — noted as a constitutional-parameter constraint (Gap §8), not a code bug.

**`fs_fed_global_section(out)`** — Guard uninit → still return `FSHEAF_OK` after producing `Keccak256("")`? No: require `FSHEAF_INITED` (else `FSHEAF_E_BAD`). **Collect**: scan `[0, MAX_SECTIONS)`; for each slot with `SEC_LIVE[i]==1u8 && SEC_ATTESTED[i]==1u8`, append `i` to `FSHEAF_ORDER[m]`, `m += 1`. **Sort** `FSHEAF_ORDER[0..m)` by `(SEC_OPEN ascending, then value lex)` via in-place insertion sort: outer `p` in `[1,m)`, inner `q` from `p` down while `q > 0` — compare `lhs=ORDER[q-1]`, `rhs=ORDER[q]`: `swap=1` if `SEC_OPEN[lhs] > SEC_OPEN[rhs]`, or if `SEC_OPEN[lhs]==SEC_OPEN[rhs] && ident_cmp(value(lhs), value(rhs))==1i32`; on swap exchange `ORDER[q-1]↔ORDER[q]` and `q -= 1`; on `swap==0` set `q = 0u32` to end the run (sentinel loop, no `break` — W14; the documented insertion-sort active-flag-drives-the-condition shape, also used in the Module-10 sheaf spec). `SEC_OPEN[*] > SEC_OPEN[*]` is **`u32` unsigned** ordering (legal); `ident_cmp` returns `i32 ∈ {−1,0,1}` compared **`== 1i32` only** (W11/Trap 3 — never `<`/`>`). **Fold**: for `k` in `[0,m)`, `s=ORDER[k]`; write `open_set_LE(4) ‖ value(32)` = 36 bytes into `FSHEAF_FOLD_BUF[k*36 ..]` (byte stores). Then one `keccak256_oneshot((&FSHEAF_FOLD_BUF) as u64, (m as u64)*36u64, (&out) as u64...)` — actually `out` is the caller's `*u8`: `keccak256_oneshot((&FSHEAF_FOLD_BUF) as u64, (m as u64)*36u64, out as u64)`. Return `FSHEAF_OK`. Because the input is canonically sorted, the global section is independent of attestation/gossip order (M2/W5). Empty attested set (`m==0`) yields `Keccak256` of zero bytes — a well-defined canonical empty-federation identifier.

> **Bit-identity of the oneshot-vs-streaming fold:** the candidate streams `keccak256_update(open_set_bytes,4); keccak256_update(value,32)` per section. `Keccak256` of the concatenation `(ob0‖value0‖ob1‖value1‖…)` is **byte-identical** to those sequential updates (the sponge absorbs the same byte stream). Assembling into `FSHEAF_FOLD_BUF` and one `keccak256_oneshot` is therefore mathematically identical and trap-free.

**`fs_fed_peer_count()` / `fs_fed_section_count()`** — Return `FSHEAF_PEER_COUNT` / `FSHEAF_SEC_COUNT`.

**`fs_fed_selftest()`** — Runs KAT-1..KAT-5 (below) in sequence using `FSHEAF_ST_*` scratch; returns `99u64` on all-pass, else the 1-based index of the first failing assertion.

**Witness continuity / reproducibility (M6/M10/W16):** every threshold-crossing emits a `wh_publish` fragment whose `out_commit = Keccak256(open_set‖value‖signers)` is recomputable from recorded inputs (M10), chained from the prior `wh_chain_root` (M6), stamped with monotonic algebraic time inside `wh_publish` (W16/W17), and never revoked or mutated (reversibility by accrual — W16). The global section identifier is a pure function of the sorted attested-section multiset (M10).

## KAT Vectors (>= 3)

All vectors call `fs_fed_init(threshold)` first. Fixed 32-byte patterns: node ids `N0=0xA0*32`, `N1=0xA1*32`; values `V0=0x00*32`, `V1=0x01*32`; open sets `O=7u32`, `O2=9u32`. Public keys `PK0`, `PK1` are the real Ed25519 public keys for known seeds `S0`, `S1` (so signatures can be produced by the reference `ed25519_sign(seed, pk, msg, 36, sig)` and must verify). The local node's witness keypair is produced by `node_identity` from a fixed boot seed in the harness.

**KAT-1 — peer registration is idempotent; local node is peer 0.**
`fs_fed_init(1u32)`. Assert `fs_fed_peer_count() == 1u32` (local node auto-registered) and `FSHEAF_SELF_INDEX == 0u32`. `p = fs_fed_add_peer(N1, PK1)`; assert `p == 1u32`, `fs_fed_peer_count() == 2u32`. `p2 = fs_fed_add_peer(N1, PK1)` again; assert `p2 == 1u32` (idempotent, no new slot), `fs_fed_peer_count() == 2u32`.

**KAT-2 — local attest reaches threshold and attests (threshold = 1).**
`fs_fed_init(1u32)`. `fs_fed_local_attest(O, V0)`. Assert returns `FSHEAF_OK` and `fs_fed_is_attested(O, V0) == 1u8` (one signer ≥ threshold 1). Assert `fs_fed_section_count() == 1u32`. Re-call `fs_fed_local_attest(O, V0)`; assert still `1u8` and `sig_cnt` unchanged (signer not double-counted) — verified via `fs_fed_section_count()` still `1u32`.

**KAT-3 — received attestation: valid signature attests; tampered signature is refused (negative case, proves the gate FAILS on bad input).**
`fs_fed_init(2u32)` (threshold 2). `fs_fed_add_peer(N1, PK1)`. Local attest `fs_fed_local_attest(O, V0)` → 1 signer (the local node); `fs_fed_is_attested(O,V0)==0u8` (below threshold 2). Build `req` with `open_set=O`, `value=V0`, `signer_node_id=N1`, `signature = ed25519_sign(S1, PK1, canonical_msg(O,V0), 36)`. `fs_fed_receive_attestation(&req)` → assert `FSHEAF_OK` and now `fs_fed_is_attested(O,V0)==1u8` (2 signers ≥ 2). **Negative:** reset; repeat to the pre-receive state; flip one byte of `req.signature`; `fs_fed_receive_attestation(&req)` → **assert `FSHEAF_E_SIG`** and `fs_fed_is_attested(O,V0)==0u8` (the bad signature is rejected and does **not** increment the signer count). A second negative: `req.signer_node_id = N1` but signature is over a *different* `value V1` — assert `FSHEAF_E_SIG` (message-binding holds). A third negative: unknown signer `N9` (never added) → assert `FSHEAF_E_BAD` (peer-lookup refusal).

**KAT-4 — global section is canonical and order-independent.**
`fs_fed_init(1u32)`. Attest two sections so both are attested: `fs_fed_local_attest(O, V0)` and `fs_fed_local_attest(O2, V1)`. `fs_fed_global_section(&out_A)`. Reset; attest in the **reverse** order (`O2,V1` then `O,V0`). `fs_fed_global_section(&out_B)`. **Assert `out_A` byte-identical to `out_B`** (sorted-by-(open,value) canonicality). Reference: `out == keccak256_oneshot(O_LE‖V0‖O2_LE‖V1)` (sorted: `O=7 < O2=9`), the 72-byte buffer — recomputed by the harness with the same `keccak256_oneshot` and asserted equal. Sanity: `out` is not all-zero.

**KAT-5 — sentinel-on-full + uninit refusal.**
Without `fs_fed_init`, `fs_fed_local_attest(O,V0)` → `FSHEAF_E_BAD`; `fs_fed_gossip_step(1u64)` → `0u32`; `fs_fed_receive_attestation(&req)` → `FSHEAF_E_BAD`. (Full-peer-table sentinel: filling all 256 peers then `fs_fed_add_peer` → `FSHEAF_SENT`; exercised structurally — the 256 bound makes an exhaustive add loop cheap, so the harness does add 256 distinct ids and asserts the 257th returns `FSHEAF_SENT`.) Gossip determinism: with 3 peers and known `SELF_INDEX=0`, assert `fs_fed_gossip_step(1u64)` selects `target = (1*11 + 0) % 3 = 2` (verified by reading `FSHEAF_PEER_LAST[2] == 1u64` after the call) — a concrete deterministic-rotation vector.

## Trap Exposure

| Trap | Exposed? | Avoidance |
|---|---|---|
| **1. Multi-line `fn` decl** | YES (18 sigs) | Every `fn` signature single-line. The candidate's `fs_fed_init` and `fs_fed_receive_attestation` headers wrap across two lines, and the `wh_publish` **extern** wraps across four — all rewritten single-line in the skeleton (the aggregate-`req` refactor also shortens `receive_attestation` under the column budget). |
| **2. Module-level `const`/`var` linker-global** | **YES — primary fix (16 consts + ~30 vars)** | The candidate's bare `FED_*`/`FS_FED_*` names collide with the linker-global `FED_*` space owned by the **built** `fed_seal`/`fed_admit`/`fed_tier`/`fed_genesis` modules. **All** module-scope consts **and** vars renamed to `FSHEAF_*`; grep confirms zero `FSHEAF_*` collision across `STDLIB/`. Helper fns renamed `_fsheaf_*`. |
| **3. Signed-int ordering compare SIGSEGV** | YES | `ident_cmp` returns `i32 ∈ {−1,0,1}`; every test is **`== 1i32`** (sort) / **`== FSHEAF_OK`** / **`!= 1u8`** — never `<`/`>`/`>=`/`<=` on a signed int. The `>=` threshold checks and the `>` sort key are on **`u32` unsigned** values (`sig_cnt`, `SEC_OPEN`, counts), which are not the trap. All error-code checks `==`/`!=`. |
| **4. u32-in-u64-slot garbage** | YES | All section/peer/signer pointer arithmetic masks the index into u64 before the multiply: `(slot as u64)`, `(k as u64)`, `(target as u64)` — never a raw `as u64` of an unmasked u32 feeding pointer math without the `* 32u64`/`* 64u64` byte-stride intent. The candidate's pointer helpers already use `(s as u64) * 32u64`; preserved. Where a bare index could carry high garbage, `& 0xFFFFFFFFu64` is applied (the gossip `raw % pc` path loads `pc` and `raw` as clean u64). |
| **5. u32 pointer store width** | YES | Every identifier/value/signature write is **byte-by-byte through `*u8`** (`ident_copy`, the canonical-msg LE stores, the signer/signature copy loops, the fold-buf stores). The `[u32; N]` tables (`SEC_OPEN`, `PEER_LAST` is u64, `ORDER`) are written by **direct indexed assignment** of a `u32`/`u64` value (`SEC_OPEN[i] = open_set`), not through a `*u32` pointer — the safe form. No `*u32`-pointer store of a u32 local anywhere. |
| **6. Nested `/* */`** | NO | Header and inline comments are flat; inner annotations use `//` or `(...)`. |
| **7. Local `var` arrays** | **YES — primary fix** | The candidate declares `nid`/`npub` (init), `msg`/`sig`/`nid` (attest), `in_c`/`out_c`/`ob`/`fid` (publish), `order`/`ob` (global) **inside fn bodies**. **All hoisted** to module scope (`FSHEAF_NID`, `FSHEAF_NPUB`, `FSHEAF_MSG`, `FSHEAF_SIG`, `FSHEAF_INC`, `FSHEAF_OUTC`, `FSHEAF_OB`, `FSHEAF_FID`, `FSHEAF_ORDER`, plus `FSHEAF_HASHBUF`, `FSHEAF_FOLD_BUF`). Non-reentrancy documented. |
| **8. `} else {` one line** | LOW | The candidate uses an all-`if` style (no `else`). Skeleton preserves it; any `else` added in Phase 2 must be `} else {` on one line. |
| **9. Em-dash in comments** | YES (prose-heavy header) | All `.iii` comments use ASCII `--`; no U+2014. Math/Unicode (`∩`, `⊆`, `≥`) appears only in *this spec* (Markdown), never in source comments. |
| **10. `let mut … = 0u32` checkpoint-flag** | LOW | The `peer`/`m`/`ok`-style flags are find/collect accumulators driving their own loop work (W14 sentinel) — the sanctioned shape, not the misbehaving checkpoint-flag pattern. |
| **11. `a % b` after a call** | YES (gossip) | `fs_fed_gossip_step` computes `raw % pc` and `(target+1) % PEER_COUNT`. **No function call precedes either `%`** (the trap is modulo-after-*call*); the divisor is a freshly-loaded module global. Belt-and-suspenders: load `let pc : u64 = FSHEAF_PEER_COUNT as u64` into a local immediately before, reduce `raw % pc`. `FSHEAF_PEER_COUNT` is not a power of two, so a byte-mask is not applicable — explicit reduction with the local-divisor form is the avoidance. Flagged for Phase-2 KAT-5 to assert the concrete `(1*11+0)%3==2` vector. |
| **12. `@specialize *T` stride** | NO | No generics; every element stride is an explicit `* 32u64` / `* 64u64` / `* 36u64` byte offset. |

## Gap / Fix List

The candidate is PARTIAL. Each defect with its fix:

1. **[SHOWSTOPPER · Dep mis-source + Trap 11] Keccak externs `keccak256_init/update/final from "keccak.iii"`.** `keccak.iii` exports none of these (verified); the symbols live in `keccak256.iii`, and the streaming triple trips param-spill across `init()`. **Fix:** drop all three; add the single extern `keccak256_oneshot(msg_ptr:u64, msg_len:u64, out_ptr:u64) -> i32 from "keccak256.iii"`. Rewrite `_fsheaf_publish_attested` (concat ≤1060 B into `FSHEAF_HASHBUF`) and `fs_fed_global_section` (concat `m*36` B into `FSHEAF_FOLD_BUF`) as single oneshot calls — mathematically identical to the streamed form.
2. **[SHOWSTOPPER · param-order silent corruption] `ed25519_verify(msg, msg_len, sig, pub_key)`.** Real symbol (verified `crypt_ed25519.iii:253`) is `ed25519_verify(pubkey, msg, msg_len, sig) -> u8`. The gospel call binds the *message pointer* to the *pubkey* slot → every verify fails / OOB-reads. **Fix:** extern + call site to `ed25519_verify(peer_pub_ptr(peer), &FSHEAF_MSG, 36u64, signature)`.
3. **[SHOWSTOPPER · Trap 2 namespace] Bare `FED_*` / `FS_FED_*` module-scope names.** Collide with the linker-global `FED_*` space of the **built** `fed_seal/fed_admit/fed_tier/fed_genesis` modules. **Fix:** rename **all** consts and vars to the dispatch-assigned `FSHEAF_` prefix (functions stay `fs_fed_*`, the link contract; helpers → `_fsheaf_*`). Grep-confirmed zero `FSHEAF_*` collision.
4. **[SHOWSTOPPER · Trap 7] ~11 local `var` arrays inside fn bodies** (`nid`,`npub`,`msg`,`sig`,`in_c`,`out_c`,`ob`×2,`fid`,`order`). **Fix:** hoist all to module scope under `FSHEAF_*`; add `FSHEAF_HASHBUF` + `FSHEAF_FOLD_BUF`. Document non-reentrancy.
5. **[SHOWSTOPPER · Dep not-built] `ni_node_id`/`ni_witness_pub`/`ni_witness_sign from "node_identity.iii"`.** `node_identity.iii` is **Module 28 (Layer 6, Ring R−2), NOT YET BUILT** (verified absent from the tree). **Fix:** the `ni_*` extern surface is correct per the Module-28 header; declared as-is and **marked NOT-YET-BUILT** so the wave scheduler orders Module 28 first. (Module 28's own body has the same keccak/ed25519 defects — that is Module 28's spec's problem, not ours; our dependency is only its stable `ni_*` ABI.)
6. **[Trap 1] `fs_fed_init`, `fs_fed_receive_attestation`, and the `wh_publish` extern wrap multiple lines.** **Fix:** all single-line in the skeleton (the `req`-aggregate refactor shortens `receive_attestation`).
7. **[W2 / robustness] `fs_fed_receive_attestation` has 4 pointer params.** Legal (≤4) but the param-spill family is worst at the boundary. **Fix (recommended):** aggregate to `fs_fed_receive_attestation(req: *u8)` over `FSHEAF_AttestReq` (132 B). Documented in §Public API as the realization; the 4-param form is the noted fallback.
8. **[Constitutional-parameter note · M4, not a code bug] Gossip step `FSHEAF_GOSSIP_STEP=11` "coprime to n".** Coprimality (hence full-cover-per-n-rounds) holds only for federation sizes `n` not divisible by 11. **Fix:** documented as a constraint on the constitutional federation size; the deterministic rotation itself is correct for all `n >= 2`. No exact-coverage claim is made for `n` divisible by 11 (a higher layer may choose a step coprime to the actual `n`). This is *exactness disclosed*, not a heuristic.
9. **[Soundness / policy gap · documented, not corrected in body] `fs_fed_receive_attestation` admits an attestation for a `(open_set,value)` the local node has never seen, auto-allocating the section.** This is **intended** federation behavior (peers learn new sections via gossip — the gospel's whole point), but unlike the local sheaf there is no check that `open_set` is a valid local open slot. **Fix/decision:** keep auto-allocation (refusing unknown opens would prevent a fresh node from ever learning the federation state — a bricking-adjacent failure, M5). The signature gate (M8) is the real admission control: a section only *attests* when a threshold of *recorded-public-key* signers sign it, so an attacker cannot inflate a bogus section without compromising threshold-many witness keys. Documented as a deliberate trust-model choice, with the cross-reference that Sybil/eclipse defense (Modules 50/51) bounds the adversarial peer fraction.
10. **[Bound/refusal · already correct, verified] Signer-table overflow.** `_fsheaf_section_add_signer` refuses (`FSHEAF_E_BAD`) at `FSHEAF_MAX_SIGNERS=32` rather than overflowing (M5/W8). Verified the candidate already does this; preserved.
11. **[Missing selftest · house convention] No `fs_fed_selftest`.** **Fix:** add `fs_fed_selftest() -> u64 @export` running KAT-1..5, returning `99u64`/first-fail-index. Required by the Phase-2 acceptance gate.
12. **[Comment hygiene · Trap 9] Header prose uses em-dashes / Unicode.** **Fix:** ASCII-only `.iii` comments (`--`, `cap`, `>=`).

**No mandate is *violated* by the corrected design.** M1 (only substrate Keccak + Ed25519; multi-sig hand-rolled, no BLS), M2 (linear scans + canonical sort + deterministic verify), M3/M4 (exact threshold count + closed-form rotation, zero learning/adaptation), M5/M9 (sections accrue, never mutate/delete; full table refuses), M6/M10 (each attestation chains a recomputable witness fragment), M8 (witness-key-gated attestation, recorded-pubkey signature verification), M15 (totality over the bit widths), M16 (attested sections are ratifiable via the published fragment), M19 (cost bounded: `O(MAX_PEERS)` peer scans, `O(MAX_SECTIONS)` section scans, `O(m^2)` global-section sort with `m <= 4096`, one Keccak per publish/fold) all hold. K = 1.00.

## Implementation Skeleton

```iii
/* C:\Users\Edwin Boston\OneDrive\Desktop\III\STDLIB\iii\aether\federated_sheaf.iii
 *
 * III STDLIB - aether::federated_sheaf  (Layer 11, Module 47)
 *
 * Distributed sheaf with threshold-signed global sections and a
 * deterministic gossip rotation.  Single-node side: each node runs its
 * own sheaf; a section is globally ATTESTED when a threshold of the
 * federation's witness-key signers have signed its canonical encoding.
 * The threshold signature is a verifiable multi-signature -- an ordered
 * signer set, each Ed25519 signature re-checked against the recorded
 * peer public key.  No BLS, no Schnorr MPC (M1 NIH).
 *
 * Peer slot:    32-byte node_id + 32-byte Ed25519 pub + last_seen_round + live.
 * Section slot: open_set (u32) + 32-byte value + sig_cnt + up to
 *               FSHEAF_MAX_SIGNERS (signer id, 64-byte sig) + attested.
 *
 * Hashing: keccak256_oneshot over a module-scope concat buffer (the
 * substrate-wide reconciliation of the gospel streaming API; streaming
 * clobbers param registers across init() -- see identifier.iii /
 * content_addr.iii / the Module-10 sheaf spec).
 *
 * NON-REENTRANT: all scratch (FSHEAF_MSG/SIG/HASHBUF/FOLD_BUF/ORDER/...)
 * is module-scope.  Single-threaded verifier per node; federation
 * concurrency is between nodes.
 *
 * Public API:
 *   fs_fed_init(threshold) -> i32
 *   fs_fed_add_peer(node_id, pub_key) -> u32        (FSHEAF_SENT if full)
 *   fs_fed_local_attest(open_set, value) -> i32
 *   fs_fed_receive_attestation(req) -> i32
 *     req -> FSHEAF_AttestReq { open_set:u32(LE,4) | value:[u8;32] |
 *                               signer_node_id:[u8;32] | signature:[u8;64] }
 *   fs_fed_is_attested(open_set, value) -> u8
 *   fs_fed_gossip_step(round) -> u32                (1 if a peer selected)
 *   fs_fed_global_section(out) -> i32               (32-byte canonical fold)
 *   fs_fed_peer_count() -> u32 ; fs_fed_section_count() -> u32
 *   fs_fed_selftest() -> u64                         (99 on pass)
 *
 * Hexad: kind_witness + kind_motion.  Ring: R-1.  K: 1.00.
 * Discipline: W2 (<=4 params), W8, W9, W10, W12, W13, W14, W15.
 */

module aether_federated_sheaf

extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_cmp(a: *u8, b: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn keccak256_oneshot(msg_ptr: u64, msg_len: u64, out_ptr: u64) -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn ed25519_verify(pubkey: *u8, msg: *u8, msg_len: u64, sig: *u8) -> u8 from "crypt_ed25519.iii"
extern @abi(c-msvc-x64) fn ni_node_id(out_id: *u8) -> i32 from "node_identity.iii"
extern @abi(c-msvc-x64) fn ni_witness_pub(out_pub: *u8) -> i32 from "node_identity.iii"
extern @abi(c-msvc-x64) fn ni_witness_sign(msg: *u8, msg_len: u64, out_sig: *u8) -> i32 from "node_identity.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_chain_root(out_id: *u8) -> i32 from "witness_hook.iii"

const FSHEAF_OK              : i32 =  0i32
const FSHEAF_E_BAD           : i32 = -1i32
const FSHEAF_E_SIG           : i32 = -2i32
const FSHEAF_E_NULL          : i32 = -3i32
const FSHEAF_SENT            : u32 = 0xFFFFFFFFu32

const FSHEAF_MAX_PEERS       : u32 = 256u32
const FSHEAF_MAX_SECTIONS    : u32 = 4096u32
const FSHEAF_MAX_SIGNERS     : u32 = 32u32
const FSHEAF_GOSSIP_STEP     : u64 = 11u64
const FSHEAF_IDBYTES         : u64 = 32u64
const FSHEAF_SIGBYTES        : u64 = 64u64
const FSHEAF_MSGLEN          : u64 = 36u64
const FSHEAF_REQLEN          : u64 = 132u64
const FSHEAF_PILLAR          : u16 = 7u16
const FSHEAF_PHASE_ATTESTED  : u8  = 10u8

/* Runtime threshold + peer table */
var FSHEAF_THRESHOLD  : u32 = 1u32
var FSHEAF_PEER_LIVE  : [u8;  256]
var FSHEAF_PEER_ID    : [u8;  8192]      /* 256 * 32 */
var FSHEAF_PEER_PUB   : [u8;  8192]
var FSHEAF_PEER_LAST  : [u64; 256]
var FSHEAF_PEER_COUNT : u32 = 0u32

/* Section table */
var FSHEAF_SEC_LIVE     : [u8;  4096]
var FSHEAF_SEC_OPEN     : [u32; 4096]
var FSHEAF_SEC_VALUE    : [u8;  131072]    /* 4096 * 32 */
var FSHEAF_SEC_SIG_CNT  : [u32; 4096]
var FSHEAF_SEC_SIGNERS  : [u8;  4194304]   /* 4096 * 32 * 32 */
var FSHEAF_SEC_SIGS     : [u8;  8388608]   /* 4096 * 32 * 64 */
var FSHEAF_SEC_ATTESTED : [u8;  4096]
var FSHEAF_SEC_COUNT    : u32 = 0u32

var FSHEAF_SELF_INDEX   : u32 = 0u32
var FSHEAF_PRODUCER     : [u8; 32]
var FSHEAF_OPID_ATTEST  : [u8; 32]
var FSHEAF_OPID_ATTESTED: [u8; 32]
var FSHEAF_INITED       : u8 = 0u8

/* Hoisted scratch (Trap 7: no local var arrays) */
var FSHEAF_ORDER    : [u32; 4096]      /* attested-section sort list */
var FSHEAF_NID      : [u8;  32]        /* scratch node id */
var FSHEAF_NPUB     : [u8;  32]        /* scratch local witness pub (init) */
var FSHEAF_MSG      : [u8;  36]        /* canonical signing message */
var FSHEAF_SIG      : [u8;  64]        /* local signature scratch */
var FSHEAF_INC      : [u8;  32]        /* in_commit (chain root) */
var FSHEAF_OUTC     : [u8;  32]        /* out_commit (descriptor hash) */
var FSHEAF_OB       : [u8;  4]         /* 4-byte LE open_set scratch */
var FSHEAF_FID      : [u8;  32]        /* returned fragment id sink */
var FSHEAF_HASHBUF  : [u8;  4128]      /* publish descriptor concat (<=1060 used) */
var FSHEAF_FOLD_BUF : [u8;  147456]    /* MAX_SECTIONS * 36 global-fold concat */

/* Selftest scratch */
var FSHEAF_ST_N1   : [u8; 32]
var FSHEAF_ST_PK1  : [u8; 32]
var FSHEAF_ST_S1   : [u8; 32]
var FSHEAF_ST_V0   : [u8; 32]
var FSHEAF_ST_V1   : [u8; 32]
var FSHEAF_ST_OUTA : [u8; 32]
var FSHEAF_ST_OUTB : [u8; 32]
var FSHEAF_ST_REF  : [u8; 32]
var FSHEAF_ST_REQ  : [u8; 132]
var FSHEAF_ST_TMP  : [u8; 72]

/* --- pointer helpers into payload arrays (address-of-static stays in-file, W1/W3) --- */
fn _fsheaf_peer_id_ptr(s: u32) -> *u8 { return (&FSHEAF_PEER_ID[(s as u64) * 32u64]) as *u8 }
fn _fsheaf_peer_pub_ptr(s: u32) -> *u8 { return (&FSHEAF_PEER_PUB[(s as u64) * 32u64]) as *u8 }
fn _fsheaf_sec_value_ptr(s: u32) -> *u8 { return (&FSHEAF_SEC_VALUE[(s as u64) * 32u64]) as *u8 }
fn _fsheaf_sec_signer_ptr(s: u32, k: u32) -> *u8 { return (&FSHEAF_SEC_SIGNERS[(s as u64) * 32u64 * 32u64 + (k as u64) * 32u64]) as *u8 }
fn _fsheaf_sec_sig_ptr(s: u32, k: u32) -> *u8 { return (&FSHEAF_SEC_SIGS[(s as u64) * 64u64 * 32u64 + (k as u64) * 64u64]) as *u8 }

/* --- internal helpers --- */
fn _fsheaf_canonical_msg(open_set: u32, value: *u8, out: *u8) -> i32 { return FSHEAF_OK }  // TODO: 4B LE open_set + 32B value, *u8 byte stores (Trap 5)
fn _fsheaf_find_section(open_set: u32, value: *u8) -> u32 { return FSHEAF_SENT }  // TODO: sentinel scan, SEC_OPEN==os && ident_eq(value)
fn _fsheaf_alloc_section(open_set: u32, value: *u8) -> u32 { return FSHEAF_SENT }  // TODO: first dead slot; init sig_cnt/attested=0; SENT if full
fn _fsheaf_section_has_signer(slot: u32, node_id: *u8) -> u8 { return 0u8 }  // TODO: scan [0,sig_cnt); ident_eq first-match
fn _fsheaf_section_add_signer(slot: u32, node_id: *u8, sig: *u8) -> i32 { return FSHEAF_E_BAD }  // TODO: refuse at MAX_SIGNERS; copy id + 64B sig via *u8
fn _fsheaf_publish_attested(slot: u32) -> i32 { return FSHEAF_OK }  // TODO: out_commit=keccak256_oneshot(open||value||signers) into FSHEAF_HASHBUF; wh_publish
fn _fsheaf_threshold_check_and_publish(slot: u32) -> i32 { return FSHEAF_OK }  // TODO: if sig_cnt>=THRESHOLD && !attested -> set attested, publish

/* --- public API --- */
fn fs_fed_init(threshold: u32) -> i32 @export { return FSHEAF_OK }  // TODO: zero tables; ident_from_bytes producer/opids; register local node as peer 0; INITED=1
fn fs_fed_add_peer(node_id: *u8, pub_key: *u8) -> u32 @export { return FSHEAF_SENT }  // TODO: idempotent on id (refresh pub); else first dead slot; SENT if full
fn fs_fed_local_attest(open_set: u32, value: *u8) -> i32 @export { return FSHEAF_E_BAD }  // TODO: canonical_msg; ni_witness_sign; ni_node_id; find/alloc; add signer if absent; threshold check
fn fs_fed_receive_attestation(req: *u8) -> i32 @export { return FSHEAF_E_BAD }  // TODO: parse req; peer lookup by signer id; ed25519_verify(peer_pub,msg,36,sig); find/alloc; add; threshold
fn fs_fed_is_attested(open_set: u32, value: *u8) -> u8 @export { return 0u8 }  // TODO: find; return SEC_ATTESTED[slot] or 0
fn fs_fed_gossip_step(round: u64) -> u32 @export { return 0u32 }  // TODO: guard <2 peers; target=(round*STEP+SELF)%pc (local pc divisor, Trap 11); skip self; set PEER_LAST; return 1
fn fs_fed_global_section(out: *u8) -> i32 @export { return FSHEAF_OK }  // TODO: collect attested into FSHEAF_ORDER; insertion-sort by (open,value) ident_cmp==1i32 (W14); fold via FSHEAF_FOLD_BUF + keccak256_oneshot
fn fs_fed_peer_count() -> u32 @export { return FSHEAF_PEER_COUNT }
fn fs_fed_section_count() -> u32 @export { return FSHEAF_SEC_COUNT }
fn fs_fed_selftest() -> u64 @export { return 0u64 }  // TODO: KAT-1..5; 99u64 on pass else first-fail index
```
