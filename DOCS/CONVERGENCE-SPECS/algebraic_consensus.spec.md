# 49 aether/algebraic_consensus.iii — Implementation Spec

## Verdict

**STUB (relative to the user-prioritized MAXIMAL intent).** The gospel candidate body (`L15566-16053`) is a *complete and largely correct deterministic HotStuff BFT* — four phases (prepare/pre-commit/commit/decide), threshold QCs, closed-form `leader = view mod n` rotation, the canonical HotStuff safety predicate, and witness-fragment publication. But it is **a reimplementation of HotStuff**, and the substrate already ships a pragmatic HotStuff (`STDLIB/iii/aether/hotstuff.iii`) that this module is explicitly dispatched to **surpass**. As an *algebraic consensus* it is a stub: it never realizes consensus as a sheaf-gluing / agreement-as-equalizer construction; "algebraic" in its name is unearned. This spec **redesigns** the module as the maximal algebraic consensus — decision = the **unique global section in the equalizer of the restriction maps** over the attesting sub-cover; quorum = the exact algebraic fact that the sheaf condition holds over ≥ `2f+1` opens; refusal (W28) below quorum because the equalizer is then uncertifiable. The gospel body also carries the systemic extern defects (keccak mis-sourced, `at_now` fiction, streaming-keccak param-spill, local-var-array traps) catalogued below.

> **Maximal-intent note (per dispatch + `feedback_path_a_maximal`, `feedback_no_practicality`):** the gospel candidate is preserved *conceptually* — its HotStuff safety/liveness reasoning is the soundness backbone — but the **realized object is the equalizer/sheaf construction**, not a vote-counter. HotStuff's pacemaker is retained as the *liveness layer* (rotating leader, view advance), while *safety and the decided value are algebraic*: a value commits iff the attesting replica-sections **glue** (pairwise-agree on overlaps), and the committed value **is** the canonical glued global section. This is strictly more than `hotstuff.iii`: HotStuff counts `2f+1` identical votes; the algebraic consensus computes the equalizer of `δ0, δ1` and emits the unique section in it, refusing when that equalizer is empty.

## Purpose

`aether/algebraic_consensus` is the **ontology of federation-wide agreement as a limit construction**. The federation peer set is a base topology; each replica's attestation over a proposed block is a *local section* over that replica's open set; the **decided value is the unique global section obtained by gluing the attesting family** — equivalently, the unique element of the **equalizer** of the two restriction maps `δ0, δ1 : ∏_i Sect(U_i) ⇉ ∏_{i<j} Sect(U_i ∩ U_j)`. Consensus *is* the sheaf condition: a family glues iff every pair agrees on its overlap, and it certifies a quorum iff the sub-cover that glues has size `≥ 2f+1`. Below quorum the equalizer is uncertifiable and the module **refuses** (W28) — never guesses, never partial-commits (M4/M5). Determinism (M2) is structural: the global section is `Keccak256` of a **canonically sorted** concatenation of attesting section ids, independent of attestation arrival order. Liveness is borrowed from HotStuff's rotating leader (`leader = view mod n`, no randomness — M2). **Hexad:** `kind_motion + kind_witness`. **Ring:** R-1. **K:** 1.00 (the network synchrony assumption is the sole non-determinism; protocol logic is total).

## Public API

All public functions `@export`. Status fns return negative-`i32` (W9, compared `==`/`!=` only — W11). Boolean returns are `u8` 0/1 (W10). Slot/index returns use the `ACONS_SENT = 0xFFFFFFFFu32` sentinel (W12). Every fn ≤ 4 params (W2): multi-field proposals/votes are passed as a pointer to a fixed-layout aggregate.

```
fn acons_init(cfg: *u8) -> i32 @export
fn acons_set_keypair(seed_pub: *u8) -> i32 @export
fn acons_current_view() -> u64 @export
fn acons_leader_for_view(view: u64) -> u32 @export
fn acons_propose(prop: *u8, out_block: *u8) -> i32 @export
fn acons_handle_prepare(block: *u8, block_len: u32) -> i32 @export
fn acons_handle_attest(att: *u8, att_len: u32) -> i32 @export
fn acons_glue_quorum(view: u64, out_global: *u8) -> i32 @export
fn acons_decide(cap: u64, view: u64, out_global: *u8) -> i32 @export
fn acons_verify_certificate(cert: *u8, cert_len: u32) -> u8 @export
fn acons_block_phase(block_slot: u32, out_phase: *u8) -> i32 @export
fn acons_decided_block(out_slot: *u32) -> i32 @export
fn acons_tick(elapsed_units: u64) -> i32 @export
fn acons_selftest() -> u64 @export
```

Return-status convention per fn:

- `acons_init` → `ACONS_OK` / `ACONS_E_NULL` / `ACONS_E_CONFIG` (bad `n`/`threshold`).
- `acons_set_keypair` → `ACONS_OK` / `ACONS_E_NULL`.
- `acons_current_view` → the `u64` view (sentinel-typed value; W12).
- `acons_leader_for_view` → node index `u32` (`view mod n`; `0u32` if `n==0`).
- `acons_propose` → `ACONS_OK` / `ACONS_E_NOT_INITED` / `ACONS_E_NULL` / `ACONS_E_NOT_LEADER`.
- `acons_handle_prepare` → `ACONS_OK` (accepted, local section registered) / `ACONS_E_BAD_BLOCK` (id mismatch) / `ACONS_E_UNSAFE` (safety predicate refused) / `ACONS_E_BAD_PROPOSER` (sig/leader mismatch) / `ACONS_E_FULL`.
- `acons_handle_attest` → `ACONS_OK` (attestation registered as a local section) / `ACONS_E_BAD_SIG` / `ACONS_E_DUP_ATTEST` / `ACONS_E_BAD_BLOCK` / `ACONS_E_FULL`.
- `acons_glue_quorum` → `ACONS_OK` (the attesting family over `view` glues **and** `|sub-cover| ≥ threshold`; `out_global` written) / `ACONS_E_NO_QUORUM` (sub-cover `< threshold`) / `ACONS_E_NO_GLUE` (≥ threshold sections but they disagree on an overlap → refuse). Writes `out_global` **only** on `ACONS_OK`.
- `acons_decide` → `ACONS_OK` (capability-gated commit of the glued global section; publishes a DECIDE witness fragment) / `ACONS_E_DENIED` (cap lacks `CAP_RIGHT_AMEND`) / `ACONS_E_NO_QUORUM` / `ACONS_E_NO_GLUE`. (M8: privileged state-advance requires an explicit capability.)
- `acons_verify_certificate` → `1u8` iff the certificate's `≥ threshold` Ed25519 signatures all verify against the recorded peer keys over the canonical phase tuple **and** the embedded global-section root recomputes byte-identically from the sorted signer-section ids; else `0u8` (W10, M10).
- `acons_block_phase` → `ACONS_OK` with highest formed phase in `*out_phase` / `ACONS_E_BAD_BLOCK`.
- `acons_decided_block` → `ACONS_OK` with decided slot / `ACONS_E_NO_DECISION`.
- `acons_tick` → `ACONS_OK` / `ACONS_E_TIMEOUT` (view advanced) / `ACONS_E_NOT_INITED`.

> **API divergence from the gospel candidate (documented, all justified):**
> 1. **`hs_*` → `acons_*` function names.** The gospel uses `hs_*`, which **collides at the C-ABI symbol level** with the already-built pragmatic `STDLIB/iii/aether/hotstuff.iii` (`hs_init`, `hs_propose`, `hs_handle_vote`, `hs_verify_qc`, …). Two modules cannot export the same symbol into the aggregated lib. **All public functions are renamed `acons_*`.** (Trap 2 governs only module-scope `const`s for the *linker-global* hazard, but `@export` **function** names are equally global in the C-ABI link; the existing `hotstuff.iii` proves `hs_*` is taken.)
> 2. **`hs_init(n_nodes, my_index, threshold)` → `acons_init(cfg: *u8)`** — folds the three scalars behind one aggregate pointer. (The gospel's 3 scalars are W2-legal; the aggregate is adopted for forward extension — the `ACONS_Config` record also carries the peer-key table base and the view-timeout, which the gospel left as separate globals.)
> 3. **`hs_handle_prepare(block_id, parent_id, view, payload, payload_len)` = 5 params → `acons_handle_prepare(block: *u8, block_len: u32)`** — the gospel signature **violates W2 (≤4)**. The block fields are aggregated into the canonical on-wire block layout (below) behind a single `*u8`.
> 4. **`hs_handle_vote(block_id, view, phase, signer_node_id, signature)` = 5 params → `acons_handle_attest(att: *u8, att_len: u32)`** — also a **W2 violation** (5 params). Aggregated into the canonical attestation layout. Renamed *attest* because in the algebraic framing a vote **is** the publication of a local section, not a tally increment.
> 5. **New: `acons_glue_quorum`, `acons_decide`, `acons_verify_certificate`.** These realize the algebraic core the gospel lacks: the explicit equalizer/gluing computation, the capability-gated commit of the glued section, and the order-independent certificate verifier. `acons_decide` adds the **M8 capability gate** the gospel omitted entirely (the gospel advanced `HS_DECIDED_SLOT` with no capability check — an M8 gap, see Gap §).
> 6. **`hs_block_state` → `acons_block_phase`**, **`hs_decided_block` → `acons_decided_block`**, **`hs_current_view`/`hs_leader_for_view` → `acons_current_view`/`acons_leader_for_view`** (name-prefix only; signatures preserved). **`acons_tick`** is added (the gospel has no pacemaker timeout fn; liveness needs one — modelled on `hs_tick` in `hotstuff.iii`, driven by algebraic-time units not wall-clock ms, for M2).

## Constant Namespace

**PREFIX = `ACONS_`** (dispatch-assigned). **Grep result:** `^const ACONS_` and `^fn .*acons` across `STDLIB/` → **zero matches** (verified). No collision. (Cross-checked: the existing `hotstuff.iii` uses `HS_*` consts and `hs_*` fns; `aether_algebraic_consensus` must avoid `HS_*` for both consts **and** exported fns — hence the full `ACONS_*` rename.)

| const | type | value | meaning |
|---|---|---|---|
| `ACONS_OK` | `i32` | `0i32` | success |
| `ACONS_E_NULL` | `i32` | `-1i32` | null pointer arg |
| `ACONS_E_NOT_INITED` | `i32` | `-2i32` | `acons_init` not called |
| `ACONS_E_CONFIG` | `i32` | `-3i32` | bad `n_nodes`/`threshold` |
| `ACONS_E_NOT_LEADER` | `i32` | `-4i32` | propose by non-leader |
| `ACONS_E_BAD_BLOCK` | `i32` | `-5i32` | block id mismatch / unknown block |
| `ACONS_E_BAD_PROPOSER` | `i32` | `-6i32` | proposer sig invalid / not the view leader |
| `ACONS_E_UNSAFE` | `i32` | `-7i32` | HotStuff safety predicate refused the vote |
| `ACONS_E_BAD_SIG` | `i32` | `-8i32` | attestation signature invalid |
| `ACONS_E_DUP_ATTEST` | `i32` | `-9i32` | signer already attested this (block,phase) |
| `ACONS_E_NO_QUORUM` | `i32` | `-10i32` | attesting sub-cover `< threshold` (W28 refusal) |
| `ACONS_E_NO_GLUE` | `i32` | `-11i32` | `≥ threshold` sections but overlap-disagreement |
| `ACONS_E_DENIED` | `i32` | `-12i32` | capability lacks the required right |
| `ACONS_E_NO_DECISION` | `i32` | `-13i32` | no decided block yet |
| `ACONS_E_TIMEOUT` | `i32` | `-14i32` | pacemaker view timeout fired (informational) |
| `ACONS_E_FULL` | `i32` | `-15i32` | block / attestation table full |
| `ACONS_PHASE_PREPARE` | `u8` | `0u8` | phase ids |
| `ACONS_PHASE_PRECOMMIT` | `u8` | `1u8` | |
| `ACONS_PHASE_COMMIT` | `u8` | `2u8` | |
| `ACONS_PHASE_DECIDE` | `u8` | `3u8` | |
| `ACONS_N_PHASES` | `u32` | `4u32` | QC index stride |
| `ACONS_MAX_NODES` | `u32` | `256u32` | federation peer bound (matches gospel `HS_MAX_BLOCKS` regime; one section per node) |
| `ACONS_MAX_BLOCKS` | `u32` | `256u32` | live block bound (gospel `HS_MAX_BLOCKS`) |
| `ACONS_PAYLOAD_SZ` | `u32` | `256u32` | per-block payload bytes (gospel `HS_PAYLOAD_SZ`) |
| `ACONS_IDBYTES` | `u64` | `32u64` | identifier / section width |
| `ACONS_SIGBYTES` | `u64` | `64u64` | Ed25519 signature width |
| `ACONS_VIEW_TIMEOUT` | `u64` | `64u64` | algebraic-time units before pacemaker view advance |
| `ACONS_SENT` | `u32` | `0xFFFFFFFFu32` | absence/full sentinel |
| `ACONS_CAP_RIGHT_DECIDE` | `u64` | `0x4000u64` | required right for `acons_decide` (= `CAP_RIGHT_AMEND`; federation state-advance is an amendment) |

> **Bound justification (W8):** `ACONS_MAX_NODES = 256` bounds the cover to one local section per federation node — the federation peer table is constitutionally bounded; HotStuff threshold math (`f = (n-1)/3`, `threshold = 2f+1`) is exact over `u32`. The pairwise-overlap loop is therefore `O(n²) ≤ 256² = 65536` iterations, bounded (M19). `ACONS_PAYLOAD_SZ = 256` and `ACONS_MAX_BLOCKS = 256` match the gospel verbatim (no down-scaling, `feedback_no_practicality`).

## Data Structures

All slot tables are statically sized module-scope arrays (W8). **No local `var` arrays (Trap 7)** — every scratch buffer the gospel declared inside a fn body (`vb`, `cur`, `parent`, `in_c`, `out_c`, `fid`, `msg`, `sig`, `pl`, `nid`, `ante`) is hoisted to module scope with a unique `ACONS_*` name. Large byte buffers follow `witness_hook.iii`'s `[u64; bytes/8]` discipline only where they would otherwise exceed the small-code-model reach; here every buffer is small enough for plain `[u8; N]`.

| name | type | size (bytes) | bound justification (W8) |
|---|---|---|---|
| `ACONS_PEER_KEYS` | `[u8; 8192]` | 256×32 | one 32-byte Ed25519 pubkey per node (`ACONS_MAX_NODES`). |
| `ACONS_BLOCK_LIVE` | `[u8; 256]` | 256 | live flag per block slot. |
| `ACONS_BLOCK_ID` | `[u8; 8192]` | 256×32 | block id = `Keccak256(parent‖view_le‖payload)`. |
| `ACONS_BLOCK_PARENT` | `[u8; 8192]` | 256×32 | parent block id. |
| `ACONS_BLOCK_VIEW` | `[u64; 256]` | 256×8 | view number per block. |
| `ACONS_BLOCK_PAYLOAD` | `[u8; 65536]` | 256×256 | payload bytes (`ACONS_PAYLOAD_SZ`). |
| `ACONS_BLOCK_PL_LEN` | `[u32; 256]` | 256×4 | actual payload length per block. |
| `ACONS_BLOCK_USED` | `u32` | — | high-water block count. |
| `ACONS_SEC_LIVE` | `[u8; 1024]` | 256×4 | per `(block_slot,phase)` local-section liveness (the "open set has a section" flag); index `slot*4+phase`. |
| `ACONS_SEC_BITMAP` | `[u8; 4096]` | 1024×4 | per `(block,phase)`: 256-bit attestor bitmap (32 bytes each); which nodes have published a local section. |
| `ACONS_SEC_COUNT` | `[u32; 1024]` | 1024×4 | per `(block,phase)`: number of distinct local sections (sub-cover size). |
| `ACONS_SEC_ID` | `[u8; 1048576]` | 1024×32×32 | per `(block,phase)`: up to 256 attestor section ids (the value each node attests to over its open set), 32 bytes each. Indexed `(slot*4+phase)*256*32 + node*32`. |
| `ACONS_SEC_SIG` | `[u8; 2097152]` | 1024×32×64 | per `(block,phase)`: the Ed25519 signature backing each local section. Indexed `(slot*4+phase)*256*64 + node*64`. |
| `ACONS_N_NODES` | `u32` | — | federation size. |
| `ACONS_MY_INDEX` | `u32` | — | this replica's node index. |
| `ACONS_FAULT` | `u32` | — | `f = (n-1)/3`. |
| `ACONS_THRESHOLD` | `u32` | — | `2f+1` (quorum). |
| `ACONS_CURRENT_VIEW` | `u64` | — | pacemaker view. |
| `ACONS_LAST_VOTED_VIEW` | `u64` | — | HotStuff anti-double-vote. |
| `ACONS_LOCKED_VIEW` | `u64` | — | highest pre-commit QC view (lock). |
| `ACONS_LOCKED_SLOT` | `u32` | — | locked block slot (`ACONS_SENT` if none). |
| `ACONS_DECIDED_SLOT` | `u32` | — | highest decide slot (`ACONS_SENT` if none). |
| `ACONS_VIEW_TIMER` | `u64` | — | accumulated algebraic-time units this view. |
| `ACONS_INITED` | `u8` | — | init flag. |
| `ACONS_NODE_KEYS` | `[u8; 64]` | 64 | this node's `seed(32)‖pub(32)` (set via `acons_set_keypair`; the gospel punted signing through `ni_witness_sign` — this binds the key locally, matching `hotstuff.iii`'s `HS_NODE_KEYS`). |
| `ACONS_PRODUCER` | `[u8; 32]` | 32 | witness producer id. |
| `ACONS_OPID_PREPARE` … `ACONS_OPID_DECIDE` | `[u8; 32]` ×4 | 128 | per-phase op ids for `wh_publish`. |
| **scratch (hoisted, Trap 7):** | | | |
| `ACONS_IDS_BUF` | `[u8; 8192]` | 256×32 | sorted-concat of attesting section ids for the global-section hash; bounded by `ACONS_MAX_NODES`. |
| `ACONS_SWAP_BUF` | `[u8; 32]` | 32 | insertion-sort swap temp. |
| `ACONS_HASH_BUF` | `[u8; 296]` | 296 | block-id preimage `parent(32)‖view(8)‖payload(256)`. |
| `ACONS_VB` | `[u8; 8]` | 8 | u64→LE-bytes scratch. |
| `ACONS_PHASE_MSG` | `[u8; 41]` | 41 | canonical phase tuple `block_id(32)‖view(8)‖phase(1)`. |
| `ACONS_SIG_TMP` | `[u8; 64]` | 64 | signature scratch. |
| `ACONS_CMP_ID` | `[u8; 32]` | 32 | computed-block-id temp for the id-match guard. |
| `ACONS_CUR_ID` | `[u8; 32]` | 32 | parent-chain walk cursor (replaces gospel local `cur`). |
| `ACONS_IN_C` / `ACONS_OUT_C` / `ACONS_FRAG` | `[u8; 32]` ×3 | 96 | `wh_publish` in/out commit + frag-id sink. |
| `ACONS_CERT_BUF` | `[u8; 16484]` | 16484 | certificate scratch: header(36)+root(32)+ up to 256×(32 signer + 32 sec-id) = 36+32+16384. |
| `ACONS_ST_*` (selftest) | `[u8; 32]`/`[u8;64]` ×~14 | — | KAT scratch (seeds, pubkeys, blocks, attestations, certs). |

> **Reentrancy note (Trap 7 consequence):** hoisting scratch to module scope makes the hashing/sort/sign paths **non-reentrant** — acceptable per the trap catalog for serialized hashing/crypto (`identifier.iii`, `content_addr.iii`, `keccak256.iii`, `merkle.iii`, `hotstuff.iii` all do this). The module is a single-threaded deterministic consensus engine; no concurrent `acons_*` call is supported, documented in the header.

## Dependencies (externs)

Each declared `extern @abi(c-msvc-x64)`. **All externs verified against the real provider file** (per §3.5 — gospel externs are unreliable).

| extern signature | providing module | NN | status |
|---|---|---|---|
| `fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32` | `identifier.iii` | 01 | **BUILT** |
| `fn ident_eq(a: *u8, b: *u8) -> u8` | `identifier.iii` | 01 | **BUILT** |
| `fn ident_copy(src: *u8, dst: *u8) -> i32` | `identifier.iii` | 01 | **BUILT** |
| `fn ident_cmp(a: *u8, b: *u8) -> i32` | `identifier.iii` | 01 | **BUILT** (returns -1/0/1; compare `== 1i32`/`== -1i32` only — W11) |
| `fn keccak256_oneshot(msg_ptr: u64, msg_len: u64, out_ptr: u64) -> i32` | `keccak256.iii` | (Stage-4) | **BUILT** |
| `fn ed25519_sign(seed: *u8, pk: *u8, msg: *u8, msg_len: u64, sig_out: *u8) -> u8` | `crypt_ed25519.iii` | 02 | **BUILT** (5-arg seed form, returns `1u8` on success) |
| `fn ed25519_verify(pubkey: *u8, msg: *u8, msg_len: u64, sig: *u8) -> u8` | `crypt_ed25519.iii` | 02 | **BUILT** (4-arg, returns `1u8` valid) |
| `fn ed25519_pubkey(seed: *u8, out_pk: *u8) -> u8` | `crypt_ed25519.iii` | 02 | **BUILT** (selftest only) |
| `fn at_current() -> u64` | `algebraic_time.iii` | 03 | **BUILT** (monotonic clock; **`at_now` does NOT exist** — gospel defect 4) |
| `fn at_advance() -> u64` | `algebraic_time.iii` | 03 | **BUILT** |
| `fn cap_verify_rights(id: u64, required: u64) -> u8` | `capability.iii` | (Layer 2) | **BUILT** (`cap_verify` does NOT exist — gospel defect 5; `CAP_RIGHT_AMEND = 0x4000`) |
| `fn wh_publish(producer:*u8, opid:*u8, in_commit:*u8, out_commit:*u8, revtag:u8, phase:u8, pillar:u16, antecedents:*u8, n_ante:u32, payload:*u8, payload_len:u32, out_frag_id:*u8) -> u64` | `witness_hook.iii` | 07 | **BUILT** (`ws_emit_fragment` is fiction — gospel defect 2) |
| `fn wh_chain_root(out_id: *u8) -> i32` | `witness_hook.iii` | 07 | **BUILT** |
| `fn sh_check_glue(cover: *u8, parent_open: u32, out_global: *u8) -> u8` | `numera/sheaf.iii` | **10** | **NOT YET BUILT** (spec done: `DOCS/CONVERGENCE-SPECS/sheaf.spec.md`) |
| `fn sh_init() -> i32` | `numera/sheaf.iii` | **10** | **NOT YET BUILT** |
| `fn sh_add_open(open_id: *u8, parent_slot: u32) -> u32` | `numera/sheaf.iii` | **10** | **NOT YET BUILT** |
| `fn sh_add_section(presheaf_id: *u8, open_slot: u32, section_id: *u8) -> u32` | `numera/sheaf.iii` | **10** | **NOT YET BUILT** |
| `fn sh_add_intersection(a: u32, b: u32, inter: u32) -> u32` | `numera/sheaf.iii` | **10** | **NOT YET BUILT** |
| `fn sh_add_restriction(parent: u32, child: u32, transform_id: *u8) -> u32` | `numera/sheaf.iii` | **10** | **NOT YET BUILT** |

> **DROPPED / CORRECTED from gospel candidate externs:**
> - `keccak256_init/update/final from "keccak.iii"` — **WRONG source** (those live in `keccak256.iii`, and `keccak.iii` exports only f1600/absorb/squeeze). Worse, the streaming triple triggers the **param-spill trap (Trap 11)** across `init()`. **Replaced** by a single `keccak256_oneshot` over the module-scope concat buffer `ACONS_HASH_BUF`, exactly as `identifier.iii`/`content_addr.iii` do (gospel defect 1).
> - `ni_witness_sign from "node_identity.iii"` / `ni_node_id from "node_identity.iii"` — `node_identity.iii` is **not yet built** and indirects the signing through a separate module. **Replaced** by the real `ed25519_sign` over the locally-bound `ACONS_NODE_KEYS` (`seed‖pub`), matching `hotstuff.iii`'s `hs_set_keypair` discipline (the gospel itself admits "signing is a sealed call, not shown" — realized here, no placeholder; gospel defect 7).
> - `fs_fed_add_peer` / `fs_fed_lookup_peer_pub from "federated_sheaf.iii"` — `federated_sheaf.iii` is **not yet built**. The peer-key table is held **locally** in `ACONS_PEER_KEYS` (populated by `acons_init` from the `ACONS_Config` aggregate), removing the build-blocking dependency. (Integration with `federated_sheaf.iii`'s peer table is a future wiring point, not a hard import — noted for the scheduler.)
> - `ed25519_verify(msg, msg_len, sig, pub_key)` — gospel **arg order is wrong**; the real signature is `ed25519_verify(pubkey, msg, msg_len, sig)` (gospel defect 7).

**Not-yet-built deps the wave scheduler must order before Phase-2 build of this module:** `numera/sheaf.iii` (Module 10) — **one** hard dependency (6 of its `sh_*` symbols). All other deps are BUILT. (`federated_sheaf.iii` / `node_identity.iii` are *deliberately removed* as hard deps per the corrections above; they remain optional future integration.)

## Algorithm

Determinism (M2) holds throughout: every step is a linear scan of fixed arrays in fixed order, byte-equality tests, byte copies, one canonicalizing insertion sort, and `Keccak256`/`Ed25519` over fixed-layout buffers. No time-of-day, no randomness, no float, no data-dependent ordering beyond the canonical sort. Bit-identity (W5): the decided value (global section) is `Keccak256` of the **sorted** concatenation of attesting section ids — privileging no replica and independent of attestation order. No ML/heuristics (M3/M4): quorum is the **exact** predicate `sub-cover ≥ 2f+1 AND the family glues`, never a tuned threshold; refusal is algebraic, not a guess. NIH (M1): only the substrate's own Keccak256/Ed25519/sheaf. No recursion (W15): the safety-predicate parent-chain walk and the sort use explicit `while`-counter loops over module-scope cursors, not the call stack.

**`acons_init(cfg)`** — Read `ACONS_Config { n_nodes:u32, my_index:u32, threshold_override:u32, peer_keys:[u8;256*32] }` from `cfg`. Guard `cfg != null` (→ `E_NULL`), `n_nodes != 0 && n_nodes <= ACONS_MAX_NODES` (→ `E_CONFIG`). Compute `f = (n_nodes - 1)/3`; set `ACONS_THRESHOLD = 2f+1` (if `threshold_override != 0` and `>= 2f+1` use it, else the computed `2f+1` — never below the Byzantine bound). Copy the peer-key table into `ACONS_PEER_KEYS` with a `while i < n_nodes*32` byte loop. Zero `ACONS_BLOCK_LIVE[0..MAX_BLOCKS)` and `ACONS_SEC_LIVE[0..MAX_BLOCKS*4)` / `ACONS_SEC_COUNT` / the `ACONS_SEC_BITMAP` with independent counter loops. Set `ACONS_LOCKED_SLOT = ACONS_DECIDED_SLOT = ACONS_SENT`, views/timer to 0. Derive `ACONS_PRODUCER` and the four `ACONS_OPID_*` via `ident_from_bytes` over fixed ASCII strings (matching the gospel). `ACONS_INITED = 1`. Return `ACONS_OK`. (Note: `acons_init` does **not** call `sh_init` — the sheaf base is built lazily/by the caller; see `acons_glue_quorum`.)

**`acons_set_keypair(seed_pub)`** — Guard non-null; copy 64 bytes (`seed‖pub`) into `ACONS_NODE_KEYS`. Return `ACONS_OK`. (The bound `pub` must equal `ACONS_PEER_KEYS[my_index*32 .. +32]`; not enforced here — the leader's proposer-signature check at `acons_handle_prepare` rejects a mismatch downstream.)

**`acons_leader_for_view(view)`** — `if n==0 return 0u32; return (view mod n) as u32`. **Trap 11 (modulo-after-call):** `view mod n` is computed with **no preceding function call in the same expression chain** (both operands are already-materialized locals), and `n` is **not** a power of two in general — but the spill family is triggered by a *call* spilling the divisor; here the function does no call before the `%`, so it is safe. (Defensive alternative if Phase-2 disassembly shows drift: precompute `let nn:u64 = ACONS_N_NODES as u64` immediately, then `view % nn` — already the shape.)

**`acons_propose(prop, out_block)`** — `prop = ACONS_Propose { payload:[u8;256], payload_len:u32 }`. Guards: inited, non-null, `acons_leader_for_view(ACONS_CURRENT_VIEW) == ACONS_MY_INDEX` (→ `E_NOT_LEADER`). Canonical safe parent = the locked block's id (`ACONS_LOCKED_SLOT`), or the 32-byte zero id if `ACONS_LOCKED_SLOT == ACONS_SENT`. Build `ACONS_HASH_BUF = parent(32)‖view_le(8)‖payload(payload_len)`; `block_id = keccak256_oneshot(&ACONS_HASH_BUF, 40+payload_len, …)`. Allocate a block slot (next free `ACONS_BLOCK_LIVE[i]==0`; `E_FULL` if none), store id/parent/view/payload. Write the canonical on-wire block (layout below) into `out_block`, sign the proposer field over the canonical phase tuple `(block_id, view, PREPARE)` with `ed25519_sign(&ACONS_NODE_KEYS, &ACONS_NODE_KEYS+32, &ACONS_PHASE_MSG, 41, sig_field)`. Publish a PREPARE witness fragment via `wh_publish` (producer=`ACONS_PRODUCER`, opid=`ACONS_OPID_PREPARE`, in_commit=`wh_chain_root`, out_commit=`block_id`, phase=`10u8`, pillar=`7u16`, payload=block payload). Return `ACONS_OK`.

> **Canonical on-wire BLOCK layout (361 bytes):** `[0..32) block_id` · `[32..64) parent_id` · `[64..72) view_le` · `[72..76) payload_len_le` · `[76..332) payload(256)` · `[332..364) proposer_pubkey` … sig folded: actual layout `[0..32)id [32..64)parent [64..72)view [72..76)pl_len [76..332)payload [332..364)proposer_pk [364..428)proposer_sig` = **428 bytes**. (Single fixed layout; `acons_handle_prepare` parses it.)
>
> **Canonical ATTESTATION layout (140 bytes):** `[0..32) block_id` · `[32..40) view_le` · `[40..41) phase` · `[41..45) attestor_node_id_le` · `[45..77) section_id` (the value this node attests over its open set; for plain agreement this equals `block_id`, but the field is explicit so a replica can attest a *derived* section, enabling the equalizer over non-trivial restriction maps) · `[77..141) attestor_sig` over the canonical phase tuple `(block_id‖view‖phase)`. = **141 bytes**.

**`acons_handle_prepare(block, block_len)`** — Guards: inited, non-null, `block_len >= 428`. Parse parent/view/payload/pl_len; recompute `block_id` into `ACONS_CMP_ID` and require `ident_eq(parsed_id, ACONS_CMP_ID) == 1u8` (→ `E_BAD_BLOCK`). Verify the proposer signature: `ed25519_verify(proposer_pk, &ACONS_PHASE_MSG(block_id,view,PREPARE), 41, proposer_sig)` and require `ident_eq(proposer_pk, ACONS_PEER_KEYS[leader_for_view(view)*32]) == 1u8` (→ `E_BAD_PROPOSER`). Find-or-allocate the block slot. **HotStuff safety predicate** (`acons_safety_check`): vote-safe iff `(view > ACONS_LAST_VOTED_VIEW)` **and** (`ACONS_LOCKED_SLOT == SENT` **or** `view > ACONS_LOCKED_VIEW` **or** the block's parent chain reaches the locked block). The parent-chain walk uses `ACONS_CUR_ID` as the cursor and an `extends` flag driving a bounded `while guard < ACONS_BLOCK_USED` loop (no recursion W15, no `break` W14 — gospel shape preserved). If unsafe → `E_UNSAFE`. Else set `ACONS_LAST_VOTED_VIEW = view`, then **register this replica's own local section** for `(slot, PREPARE)` by signing the attestation and calling the internal `acons_register_section(slot, PREPARE, my_index, block_id_as_section, my_sig)` and publishing a HS_VOTE-equivalent attestation fragment. Return `ACONS_OK`.

**`acons_handle_attest(att, att_len)`** — Guards: inited, non-null, `att_len >= 141`. Parse `block_id, view, phase, attestor, section_id, sig`. Require `attestor < ACONS_N_NODES`. Verify `ed25519_verify(ACONS_PEER_KEYS[attestor*32], &ACONS_PHASE_MSG(block_id,view,phase), 41, sig) == 1u8` (→ `E_BAD_SIG`). Find the block slot by id (→ `E_BAD_BLOCK` if unknown). Compute `q = slot*4 + phase`. If `ACONS_SEC_LIVE[q]==0` initialize the `(block,phase)` section set (zero bitmap, count 0, live=1). Dedup: the attestor's bit in `ACONS_SEC_BITMAP[q*32 ..]` set ⇒ `E_DUP_ATTEST`. Else set the bit, store `section_id` into `ACONS_SEC_ID[(q*256+attestor)*32 ..]` and the sig into `ACONS_SEC_SIG`, increment `ACONS_SEC_COUNT[q]`. **No phase auto-advance here** (the algebraic core decouples *collecting sections* from *gluing them*; advancement is `acons_glue_quorum`/`acons_decide`). Return `ACONS_OK`.

**`acons_glue_quorum(view, out_global)`** — *The algebraic heart.* For the COMMIT-phase section set of the block at `view` (the block whose `ACONS_BLOCK_VIEW==view` and is live; resolved by a bounded scan), let `q = slot*4 + COMMIT` and `m = ACONS_SEC_COUNT[q]`:
1. **Quorum gate (exact, not heuristic):** if `m < ACONS_THRESHOLD` → **refuse** with `ACONS_E_NO_QUORUM` (W28; the equalizer over a sub-cover smaller than `2f+1` cannot be certified Byzantine-safe — an algebraic fact, M4). `out_global` untouched.
2. **Build the sheaf base for the attesting sub-cover** (M11/M14 — the gluing is a *proof object*, not a tally): for each attestor node `i` with its bit set, register an open set `U_i` (`sh_add_open(node_open_id_i, SENT)`), its local section `Sect(U_i) = section_id_i` (`sh_add_section(presheaf=block_id, U_i, section_id_i)`), and for each pair `i<j` an intersection `U_i ∩ U_j` with the two restriction maps to it (`sh_add_intersection`, `sh_add_restriction(U_i, inter, T)`, `sh_add_restriction(U_j, inter, T)` with `T` the canonical "identity-restriction" transform id). The cover description is packed into an `ACONS_CoverReq` (presheaf=block_id, n=m, slots[]=the m open slots) in `ACONS_CERT_BUF`.
3. **Glue = equalizer test:** call `sh_check_glue(&cover, parent_open, out_global)`. `sh_check_glue` returns `1u8` iff **every** `i<j` pair's restrictions to `U_i ∩ U_j` agree (the family is in the equalizer of `δ0, δ1`) **and** writes the canonical sorted-concat global section into `out_global`; on any overlap-disagreement or missing intersection it returns `0u8` and leaves `out_global` untouched (per `sheaf.spec.md`). If `0u8` → **refuse** with `ACONS_E_NO_GLUE`. If `1u8` → return `ACONS_OK` (the unique glued global section is now in `out_global`). 

   *Determinism/bit-identity:* because `sh_check_glue`'s global section is `Keccak256` of the **sorted** section ids (per `sheaf.spec.md`), the decided value is independent of attestation arrival order and of which honest replica computes it (M2/W5/M10).

   *Equivalence-to-HotStuff sanity:* in the plain-agreement case every attestor's `section_id == block_id`, so all overlaps trivially agree and the family glues iff `m ≥ threshold` — recovering exactly HotStuff's "≥2f+1 votes ⇒ QC" but as a *limit*, not a count. The construction additionally certifies the *non-trivial* case (replicas attesting derived sections that must agree on overlaps), which HotStuff cannot express.

**`acons_decide(cap, view, out_global)`** — Guards: inited. **M8 capability gate:** `if cap_verify_rights(cap, ACONS_CAP_RIGHT_DECIDE) != 1u8 return ACONS_E_DENIED`. Call `acons_glue_quorum(view, out_global)`; propagate `E_NO_QUORUM`/`E_NO_GLUE` (no commit on refusal — M5 no-brick, M9 reversible-or-refuse). On `ACONS_OK`: set `ACONS_DECIDED_SLOT = slot`, advance `ACONS_CURRENT_VIEW = ACONS_CURRENT_VIEW + 1`, reset `ACONS_VIEW_TIMER = 0`, and publish a DECIDE witness fragment (out_commit = the glued global section; antecedents = the committed block id) via `wh_publish`. Return `ACONS_OK`. (This is the one privileged, capability-gated, NOT-reversible-without-amend operation — M8/M9.)

**`acons_verify_certificate(cert, cert_len)`** — `cert = ACONS_Cert { block_id(32), view(8), phase(1), n_sigs(4), global_root(32), [signer_node_id(4)‖section_id(32)‖sig(64)] × n_sigs }`. Guards: non-null, `cert_len >= 77`, `n_sigs >= ACONS_THRESHOLD` (else `0u8` — sub-threshold certificate is invalid). For each entry: read `signer`, require `signer < n_nodes`; `ed25519_verify(ACONS_PEER_KEYS[signer*32], &ACONS_PHASE_MSG(block_id,view,phase), 41, sig)` must return `1u8`; copy `section_id` into `ACONS_IDS_BUF[k*32 ..]`. Count valid sigs in `ok_count` (sentinel-loop, W14). If `ok_count < ACONS_THRESHOLD` → `0u8`. **Recompute the global root:** insertion-sort the `n_sigs` section ids in `ACONS_IDS_BUF` by `ident_cmp` (`== 1i32` swap, W11/Trap 3, active-flag-drives-condition shape), then `keccak256_oneshot(&ACONS_IDS_BUF, n_sigs*32, &ACONS_SIG_TMP)`; require `ident_eq(&ACONS_SIG_TMP, global_root) == 1u8`. Return `1u8` iff both the signature quorum and the root recomputation pass (M10: the certificate is byte-recomputable from recorded inputs). Else `0u8`.

**`acons_block_phase(block_slot, out_phase)`** — Bounds+live guard (→ `E_BAD_BLOCK`). Scan `p` in `[0,4)`; `best = p` whenever the `(slot,p)` section set has `count >= threshold` AND glues (cheap proxy: for `acons_block_phase` we report the highest phase whose `ACONS_SEC_COUNT[slot*4+p] >= ACONS_THRESHOLD`; the *authoritative* glue test is `acons_glue_quorum`). `*out_phase = best`. Return `ACONS_OK` if any, else `E_BAD_BLOCK`.

**`acons_decided_block(out_slot)`** — `if ACONS_DECIDED_SLOT == ACONS_SENT return E_NO_DECISION; *out_slot = ACONS_DECIDED_SLOT; return ACONS_OK`.

**`acons_tick(elapsed_units)`** — Inited guard. `ACONS_VIEW_TIMER += elapsed_units`. If `ACONS_VIEW_TIMER >= ACONS_VIEW_TIMEOUT`: advance `ACONS_CURRENT_VIEW += 1`, reset timer, return `ACONS_E_TIMEOUT` (informational; the rotating leader gives liveness — in any `f+1` consecutive views at least one leader is honest). Else `ACONS_OK`. (Driven by **algebraic-time units** the caller derives from `at_current()`, not wall-clock ms — M2; the gospel/`hotstuff.iii` used ms which is non-reproducible across machines.)

**Witness continuity / reproducibility (M6/M10):** the decided global section is a pure function of the sorted multiset of attesting section ids; recomputable byte-identically by any verifier from the certificate (M10). Every phase transition (`PREPARE` propose, attestation, `DECIDE`) emits a `wh_publish` fragment chaining by `wh_chain_root` (M6, W16 — produced under reversibility, no input consumed). The certificate is the carried proof term (M11/M18: the QC travels with its witnessed, recomputable global-section root).

## KAT Vectors (>= 3)

`acons_selftest() -> u64` returns `99u64` on all-pass, else the index of the first failing assertion (house convention, per `hs_selftest`/`ident_selftest`). It builds a real `n=4` federation (quorum `2f+1 = 3`) from 4 distinct Ed25519 seeds via `ed25519_pubkey`, binds node 1's keypair, advances to view 1 (node 1 = leader), and exercises:

**KAT-1 — propose → handle_prepare round-trip + proposer-sig + bad-proposer rejection.**
Leader (node 1) `acons_propose(payload)` → `ACONS_OK`; the produced block's recomputed id equals the embedded id; `acons_handle_prepare(block, 428)` → `ACONS_OK`. **Negative:** flip one byte of `proposer_sig` → `acons_handle_prepare` returns `ACONS_E_BAD_PROPOSER` (proves the proposer signature gate FAILS on bad input, per `feedback_no_autogen_stub_prove_negative`). Flip one payload byte (id no longer matches) → `ACONS_E_BAD_BLOCK`.

**KAT-2 — quorum gluing succeeds at threshold; global section is attestation-order-independent.**
Register COMMIT-phase attestations from nodes 0,1,2 (each `section_id == block_id`, real Ed25519 sigs over `(block_id‖view‖COMMIT)`). `acons_glue_quorum(view, OUT_A)` → `ACONS_OK`, `OUT_A` written. Re-run with attestations registered in **reversed** order (2,1,0) into a fresh section set → `acons_glue_quorum(view, OUT_B)` → `ACONS_OK` and `ident_eq(OUT_A, OUT_B) == 1u8` (sorted-concat canonicality, M2/W5). Reference: `OUT_A == keccak256_oneshot(sort([block_id,block_id,block_id]), 96)` recomputed by the test.

**KAT-3 — sub-quorum refusal (proves the W28 gate FAILS-closed).**
Register only nodes 0,1 (count `2 < threshold 3`). `acons_glue_quorum(view, OUT)` → `ACONS_E_NO_QUORUM`; `OUT` pre-filled with poison `0xEE*32` is **unchanged** (proves refusal, not partial commit — the negative case the user mandates).

**KAT-4 — disagreement refusal (proves the equalizer/glue gate FAILS on overlap-disagreement).**
Register 3 attestations but node 2 attests a **different** `section_id` (`block_id ⊕ 0x01…`) with a valid sig over its own tuple. The pairwise overlap `(0,2)`/`(1,2)` restrictions disagree → `acons_glue_quorum` returns `ACONS_E_NO_GLUE`; `OUT` poison unchanged. (This is the case HotStuff *cannot* express — it would have counted 3 votes and formed a QC; the algebraic consensus refuses because the family is not in the equalizer.)

**KAT-5 — capability gate + decide + certificate round-trip.**
`acons_decide(bad_cap, view, OUT)` with a cap lacking `CAP_RIGHT_AMEND` → `ACONS_E_DENIED` (M8 gate FAILS-closed). With `CAP_ENV_ROOT` (all rights) and a 3-attestation glued set → `ACONS_OK`, `acons_decided_block` returns the slot, `acons_current_view` advanced by 1. Build the certificate from the 3 signers; `acons_verify_certificate(cert, len)` → `1u8`. **Negative:** tamper one signer's sig → `0u8`; drop to 2 signers → `0u8` (sub-threshold); corrupt `global_root` by one byte → `0u8` (root recomputation FAILS).

> All section-id / global-root reference values are recomputed inside the selftest with the same `keccak256_oneshot`, asserted byte-for-byte (these become the Phase-2 acceptance gate). Ed25519 is exercised with real keypairs (not fixtures), so the sign/verify path is genuinely covered.

## Trap Exposure

| Trap | Exposed? | Avoidance |
|---|---|---|
| **1. Multi-line `fn` decl** | YES (14 sigs) | Every signature single-line. The gospel's `hs_handle_prepare`/`hs_handle_vote`/`hs_publish_phase`/`wh_publish` externs wrap multiple lines — **all rewritten single-line** (the W2 aggregate refactor shortens the two 5-param ones under the column budget). |
| **2. Module-level `const` linker-global** | YES (35 consts) | All consts carry the `ACONS_` prefix; grep confirms zero collision. **Critically, also the `@export` function names** are renamed `hs_*`→`acons_*` to avoid the C-ABI symbol clash with the built `hotstuff.iii` (`hs_init`, `hs_verify_qc`, …). |
| **3. Signed-int ordering compare SIGSEGV** | YES | `ident_cmp` and the error codes are the only signed ints; every test is `== 1i32` / `== -1i32` / `== ACONS_OK` / `!= ACONS_OK` — **never `<`/`>`/`>=` on a signed int**. View/count/threshold/slot comparisons are all on `u64`/`u32` (unsigned ordering is safe). |
| **4. u32-in-u64-slot garbage** | YES | `attestor`/`signer`/`slot`/`node` `u32`s used in pointer math (`ACONS_SEC_ID[(q*256+node)*32 ..]`) are first widened and **masked** `(x as u64) & 0xFFFFFFFFu64` before the multiply, OR the multiply is done entirely in a `u64` index built from `u64` loop counters. The QC index `q = slot*4 + phase` is computed in `u32` then masked on widen. |
| **5. u32 pointer store width** | YES | All id/section/sig writes go byte-by-byte through `*u8` (`ident_copy`, explicit `while` byte loops). The `ACONS_BLOCK_VIEW[u64;..]`/`ACONS_SEC_COUNT[u32;..]`/`ACONS_BLOCK_PL_LEN[u32;..]` arrays are written by **direct indexed assignment** of the scalar (not via a `*u32`/`*u64` pointer) — the safe form. View/len LE-byte serialization writes through `*u8` into `ACONS_VB`/`ACONS_HASH_BUF`. |
| **6. Nested `/* */`** | NO | Header/inline comments flat; inner annotation uses `//` or `(...)`. |
| **7. Local `var` arrays** | **YES — primary fix** | The gospel declared `vb`, `cur`, `parent`, `in_c`, `out_c`, `fid`, `msg`, `sig`, `pl`, `nid`, `ante` **inside fn bodies** — unsupported. **All hoisted** to module scope (`ACONS_VB`, `ACONS_CUR_ID`, `ACONS_PHASE_MSG`, `ACONS_IN_C`/`ACONS_OUT_C`/`ACONS_FRAG`, `ACONS_SIG_TMP`, etc.). Non-reentrancy documented. |
| **8. `} else {` one line** | LOW | Skeleton uses the all-`if` / early-return style (gospel-like); any `else` Phase-2 introduces must be `} else {` one line. |
| **9. Em-dash in comments** | YES (prose-heavy header) | All `.iii` comments ASCII-only (`--`, `subset`, `cap`, `equalizer`); no U+2014. (The math symbols `∩`, `δ`, `⇉` appear only in *this Markdown spec*, never in source.) |
| **10. `let mut … = 0u32` checkpoint-flag** | LOW | `extends`/`ok_count`/`found` are accumulators that drive their own loop work directly (W14 sentinel), not the misbehaving checkpoint-flag shape. |
| **11. `a % b` after a call** | YES (`leader_for_view`) | `view % n` is computed with **no preceding call in the expression** (operands pre-materialized as `u64` locals); `n` is not pow2 so a byte-mask is not applicable, but the spill family needs a *call* to clobber the divisor — none precedes the `%`. Phase-2 must disassemble `acons_leader_for_view` and confirm the `div` uses the live `n`; if drift appears, the fix is already the shape (precompute `nn` into a local first). **Flagged for Phase-2 binary verification.** |
| **12. `@specialize *T` stride** | NO | No generics; every stride is an explicit `* 32u64` / `* 64u64` / `* 256u64` byte offset. |

## Gap / Fix List

The gospel candidate is a STUB w.r.t. the maximal algebraic intent. Each defect + fix:

1. **[MAXIMAL-INTENT MISS · the whole point] The candidate is HotStuff, not algebraic consensus.** It counts `≥ threshold` identical votes and forms a QC; it never constructs the sheaf base, never computes the equalizer of restriction maps, never emits a *glued global section* as the decided value. **Fix:** redesign around `acons_glue_quorum` (the equalizer/gluing computation over the attesting sub-cover via `sheaf.iii`) + `acons_verify_certificate` (order-independent sorted-concat root). Decision = the unique global section in the equalizer; quorum = the exact algebraic fact `|sub-cover| ≥ 2f+1 AND family glues`; refusal below quorum (W28). The HotStuff pacemaker is retained **only** as the liveness layer.
2. **[M8 GAP · no capability on state-advance] `hs_handle_vote` mutated `HS_DECIDED_SLOT` and advanced `HS_CURRENT_VIEW` with NO capability check.** Privileged federation state-advance with no `cap` argument violates M8. **Fix:** the commit is moved into `acons_decide(cap, …)` which gates on `cap_verify_rights(cap, CAP_RIGHT_AMEND)` (→ `E_DENIED`). Verified by KAT-5.
3. **[SHOWSTOPPER · Dep mis-source, defect 1] `keccak256_init/update/final from "keccak.iii"`.** Wrong module (they live in `keccak256.iii`) AND streaming triggers Trap 11. **Fix:** single `keccak256_oneshot` over `ACONS_HASH_BUF` (block id) and `ACONS_IDS_BUF` (global root).
4. **[SHOWSTOPPER · defect 4] `at_now` does not exist** — the gospel never called it, but `hotstuff.iii` used wall-clock ms (non-reproducible). **Fix:** the pacemaker uses `at_current()`/`at_advance()` algebraic-time units (M2); `acons_tick` takes `elapsed_units:u64`.
5. **[SHOWSTOPPER · defect 5] `cap_verify` does not exist.** **Fix:** `cap_verify_rights(id, required) -> u8` with `required = CAP_RIGHT_AMEND (0x4000)`.
6. **[SHOWSTOPPER · defect 7] `ed25519_verify` arg order wrong; signing indirected through unbuilt `node_identity.iii`.** **Fix:** real `ed25519_verify(pubkey, msg, msg_len, sig)` and `ed25519_sign(seed, pk, msg, msg_len, sig_out)` over locally-bound `ACONS_NODE_KEYS`. The gospel's "signing is a sealed call, not shown" punt is realized for real (no placeholder; per `feedback_no_placeholders`).
7. **[SHOWSTOPPER · Trap 7] ~11 local `var` arrays inside fn bodies.** **Fix:** all hoisted to module scope (see Data Structures); non-reentrancy documented.
8. **[SHOWSTOPPER · symbol clash] `hs_*` exported names collide with the built `hotstuff.iii`.** **Fix:** rename all public fns `acons_*` (and all consts `ACONS_*`).
9. **[W2 violation ×2] `hs_handle_prepare` (5 params) and `hs_handle_vote` (5 params).** **Fix:** aggregate behind the canonical block / attestation `*u8` layouts → `acons_handle_prepare(block, block_len)`, `acons_handle_attest(att, att_len)`.
10. **[Build-blocking dep removal] `federated_sheaf.iii` / `node_identity.iii` (both unbuilt) as hard imports.** **Fix:** peer-key table held locally (`ACONS_PEER_KEYS` from the `ACONS_Config` aggregate); signing local. Reduces hard deps to the single `numera/sheaf.iii` (which the dispatch already names). Federated-sheaf integration is a future wiring point, noted for the scheduler.
11. **[Trap 1] Multi-line externs/fn decls** (`hs_handle_prepare`, `hs_handle_vote`, `hs_publish_phase`, the `wh_publish` extern). **Fix:** single-line everywhere.
12. **[Comment hygiene · Trap 9] Header prose uses unicode/em-dash-prone math.** **Fix:** ASCII-only `.iii` comments.
13. **[Dead import] `ident_from_bytes`** — actually *used* in this design (producer/opid derivation), so **retained** (the gospel did use it; not dead here).
14. **[Witness-field getters · defect 6, deferred] `acons_verify_certificate` self-contains its inputs** and does not need `witness_hook.iii` fragment-field getters — so this module does **not** block on the deferred Phase-2 getters. (Noted: had the design verified by re-reading published fragments, it would need them; it does not.)

**Mandate compliance of the corrected design:** M1 (substrate-only Keccak/Ed25519/sheaf), M2 (sorted-concat global section, algebraic-time pacemaker, closed-form leader), M3/M4 (exact equalizer predicate + exact `2f+1` threshold, never learned/tuned), M5/M9 (refuse-don't-brick below quorum; commit is the one cap-gated amend), M6/M10 (every transition `wh_publish`'d; certificate byte-recomputable), M8 (`acons_decide` cap-gated), M11/M18 (the glued section is a proof object carried in the certificate), M15 (total over the bit width), M19 (`O(n²) ≤ 65536` overlap pairs, bounded), M16 (view-anchored, ratifiable via the certificate). **No mandate is violated by the corrected design.**

## Implementation Skeleton

```iii
/* C:\Users\Edwin Boston\OneDrive\Desktop\III\STDLIB\iii\aether\algebraic_consensus.iii
 *
 * III STDLIB - aether::algebraic_consensus  (Layer 11, Module 49)
 *
 * Federation agreement as a LIMIT construction.  The decided value is the
 * unique GLOBAL SECTION obtained by gluing the attesting replica-sections --
 * equivalently the unique element of the EQUALIZER of the two restriction
 * maps delta0, delta1 over the attesting sub-cover.  Consensus IS the sheaf
 * condition: a family glues iff every pair agrees on its overlap, and it
 * certifies a quorum iff the gluing sub-cover has size >= 2f+1.  Below quorum
 * the equalizer is uncertifiable and the module REFUSES (W28) -- never a
 * guess, never a partial commit.
 *
 * This SURPASSES the pragmatic HotStuff in aether/hotstuff.iii: HotStuff
 * counts 2f+1 identical votes; this computes the equalizer and emits the
 * unique glued section, refusing when the family is not in it.  HotStuff's
 * rotating leader (leader = view mod n, no randomness) is retained ONLY as
 * the liveness layer; safety and the decided value are algebraic.
 *
 * Canonical BLOCK (428 bytes): [0..32)id [32..64)parent [64..72)view_le
 *   [72..76)pl_len_le [76..332)payload [332..364)proposer_pk [364..428)sig.
 * Canonical ATTESTATION (141 bytes): [0..32)block_id [32..40)view_le
 *   [40..41)phase [41..45)attestor_le [45..77)section_id [77..141)sig.
 * Canonical CERTIFICATE: [0..32)block_id [32..40)view [40..41)phase
 *   [41..45)n_sigs_le [45..77)global_root then n_sigs *
 *   (4 signer_le || 32 section_id || 64 sig).
 *
 * Hashing: keccak256_oneshot over module-scope concat buffers (the
 * substrate-wide reconciliation; streaming clobbers param registers across
 * init() -- see identifier.iii / content_addr.iii).
 *
 * NON-REENTRANT: scratch buffers are module-scope.  Single-threaded
 * deterministic consensus engine only.
 *
 * Hexad: kind_motion + kind_witness.  Ring: R-1.  K: 1.00.
 * Discipline: W2 (<=4 params), W8, W9, W10, W11, W12, W13, W14, W15, W28.
 */

module aether_algebraic_consensus

extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_cmp(a: *u8, b: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn keccak256_oneshot(msg_ptr: u64, msg_len: u64, out_ptr: u64) -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn ed25519_sign(seed: *u8, pk: *u8, msg: *u8, msg_len: u64, sig_out: *u8) -> u8 from "crypt_ed25519.iii"
extern @abi(c-msvc-x64) fn ed25519_verify(pubkey: *u8, msg: *u8, msg_len: u64, sig: *u8) -> u8 from "crypt_ed25519.iii"
extern @abi(c-msvc-x64) fn ed25519_pubkey(seed: *u8, out_pk: *u8) -> u8 from "crypt_ed25519.iii"
extern @abi(c-msvc-x64) fn at_current() -> u64 from "algebraic_time.iii"
extern @abi(c-msvc-x64) fn at_advance() -> u64 from "algebraic_time.iii"
extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_chain_root(out_id: *u8) -> i32 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn sh_init() -> i32 from "sheaf.iii"
extern @abi(c-msvc-x64) fn sh_add_open(open_id: *u8, parent_slot: u32) -> u32 from "sheaf.iii"
extern @abi(c-msvc-x64) fn sh_add_section(presheaf_id: *u8, open_slot: u32, section_id: *u8) -> u32 from "sheaf.iii"
extern @abi(c-msvc-x64) fn sh_add_intersection(a: u32, b: u32, inter: u32) -> u32 from "sheaf.iii"
extern @abi(c-msvc-x64) fn sh_add_restriction(parent: u32, child: u32, transform_id: *u8) -> u32 from "sheaf.iii"
extern @abi(c-msvc-x64) fn sh_check_glue(cover: *u8, parent_open: u32, out_global: *u8) -> u8 from "sheaf.iii"

const ACONS_OK              : i32 =  0i32
const ACONS_E_NULL          : i32 = -1i32
const ACONS_E_NOT_INITED    : i32 = -2i32
const ACONS_E_CONFIG        : i32 = -3i32
const ACONS_E_NOT_LEADER    : i32 = -4i32
const ACONS_E_BAD_BLOCK     : i32 = -5i32
const ACONS_E_BAD_PROPOSER  : i32 = -6i32
const ACONS_E_UNSAFE        : i32 = -7i32
const ACONS_E_BAD_SIG       : i32 = -8i32
const ACONS_E_DUP_ATTEST    : i32 = -9i32
const ACONS_E_NO_QUORUM     : i32 = -10i32
const ACONS_E_NO_GLUE       : i32 = -11i32
const ACONS_E_DENIED        : i32 = -12i32
const ACONS_E_NO_DECISION   : i32 = -13i32
const ACONS_E_TIMEOUT       : i32 = -14i32
const ACONS_E_FULL          : i32 = -15i32

const ACONS_PHASE_PREPARE   : u8 = 0u8
const ACONS_PHASE_PRECOMMIT : u8 = 1u8
const ACONS_PHASE_COMMIT    : u8 = 2u8
const ACONS_PHASE_DECIDE    : u8 = 3u8
const ACONS_N_PHASES        : u32 = 4u32

const ACONS_MAX_NODES       : u32 = 256u32
const ACONS_MAX_BLOCKS      : u32 = 256u32
const ACONS_PAYLOAD_SZ      : u32 = 256u32
const ACONS_IDBYTES         : u64 = 32u64
const ACONS_SIGBYTES        : u64 = 64u64
const ACONS_VIEW_TIMEOUT    : u64 = 64u64
const ACONS_SENT            : u32 = 0xFFFFFFFFu32
const ACONS_CAP_RIGHT_DECIDE: u64 = 0x4000u64

var ACONS_PEER_KEYS    : [u8;  8192]
var ACONS_BLOCK_LIVE   : [u8;  256]
var ACONS_BLOCK_ID     : [u8;  8192]
var ACONS_BLOCK_PARENT : [u8;  8192]
var ACONS_BLOCK_VIEW   : [u64; 256]
var ACONS_BLOCK_PAYLOAD: [u8;  65536]
var ACONS_BLOCK_PL_LEN : [u32; 256]
var ACONS_BLOCK_USED   : u32 = 0u32

var ACONS_SEC_LIVE     : [u8;  1024]
var ACONS_SEC_BITMAP   : [u8;  4096]
var ACONS_SEC_COUNT    : [u32; 1024]
var ACONS_SEC_ID       : [u8;  1048576]
var ACONS_SEC_SIG      : [u8;  2097152]

var ACONS_N_NODES        : u32 = 0u32
var ACONS_MY_INDEX       : u32 = 0u32
var ACONS_FAULT          : u32 = 0u32
var ACONS_THRESHOLD      : u32 = 1u32
var ACONS_CURRENT_VIEW   : u64 = 0u64
var ACONS_LAST_VOTED_VIEW: u64 = 0u64
var ACONS_LOCKED_VIEW    : u64 = 0u64
var ACONS_LOCKED_SLOT    : u32 = 0xFFFFFFFFu32
var ACONS_DECIDED_SLOT   : u32 = 0xFFFFFFFFu32
var ACONS_VIEW_TIMER     : u64 = 0u64
var ACONS_INITED         : u8 = 0u8

var ACONS_NODE_KEYS      : [u8; 64]
var ACONS_PRODUCER       : [u8; 32]
var ACONS_OPID_PREPARE   : [u8; 32]
var ACONS_OPID_PRECOMMIT : [u8; 32]
var ACONS_OPID_COMMIT    : [u8; 32]
var ACONS_OPID_DECIDE    : [u8; 32]

/* Hoisted scratch (Trap 7: no local var arrays) */
var ACONS_IDS_BUF        : [u8; 8192]    /* ACONS_MAX_NODES * 32 sorted-concat */
var ACONS_SWAP_BUF       : [u8; 32]
var ACONS_HASH_BUF       : [u8; 296]     /* parent(32)||view(8)||payload(256) */
var ACONS_VB             : [u8; 8]
var ACONS_PHASE_MSG      : [u8; 41]      /* block_id(32)||view(8)||phase(1) */
var ACONS_SIG_TMP        : [u8; 64]
var ACONS_CMP_ID         : [u8; 32]
var ACONS_CUR_ID         : [u8; 32]
var ACONS_IN_C           : [u8; 32]
var ACONS_OUT_C          : [u8; 32]
var ACONS_FRAG           : [u8; 32]
var ACONS_CERT_BUF       : [u8; 16484]
var ACONS_NODE_OPEN_ID   : [u8; 32]      /* derived per-node open-set id scratch */

/* Selftest scratch */
var ACONS_ST_SEED  : [u8; 128]
var ACONS_ST_PK    : [u8; 128]
var ACONS_ST_KP    : [u8; 64]
var ACONS_ST_BLOCK : [u8; 428]
var ACONS_ST_ATT   : [u8; 141]
var ACONS_ST_OUTA  : [u8; 32]
var ACONS_ST_OUTB  : [u8; 32]
var ACONS_ST_REF   : [u8; 32]
var ACONS_ST_CERT  : [u8; 16484]
var ACONS_ST_PAY   : [u8; 256]
var ACONS_ST_PHASE : [u8; 1]
var ACONS_ST_SLOT  : [u32; 1]

/* --- internal pointer helpers (address-of-static stays in-file, W1/W3) --- */
fn acons_block_id_ptr(slot: u32) -> *u8 { return ((&ACONS_BLOCK_ID as u64) + (slot as u64) * 32u64) as *u8 }
fn acons_block_parent_ptr(slot: u32) -> *u8 { return ((&ACONS_BLOCK_PARENT as u64) + (slot as u64) * 32u64) as *u8 }
fn acons_block_payload_ptr(slot: u32) -> *u8 { return ((&ACONS_BLOCK_PAYLOAD as u64) + (slot as u64) * (ACONS_PAYLOAD_SZ as u64)) as *u8 }
fn acons_peer_key_ptr(node: u32) -> *u8 { return ((&ACONS_PEER_KEYS as u64) + (node as u64) * 32u64) as *u8 }
fn acons_qc_idx(slot: u32, phase: u8) -> u32 { return slot * 4u32 + (phase as u32) }
fn acons_sec_id_ptr(slot: u32, phase: u8, node: u32) -> *u8 { return ((&ACONS_SEC_ID as u64) + ((acons_qc_idx(slot, phase) as u64) * 256u64 + (node as u64)) * 32u64) as *u8 }
fn acons_sec_sig_ptr(slot: u32, phase: u8, node: u32) -> *u8 { return ((&ACONS_SEC_SIG as u64) + ((acons_qc_idx(slot, phase) as u64) * 256u64 + (node as u64)) * 64u64) as *u8 }

/* --- internal: serialize / hash / find / safety helpers --- */
fn acons_put_u64_le(buf: *u8, off: u64, v: u64) -> i32 { return ACONS_OK }  // TODO: 8 byte-stores via *u8
fn acons_read_u64_le(buf: *u8, off: u64) -> u64 { return 0u64 }  // TODO: 8-byte LE read
fn acons_read_u32_le(buf: *u8, off: u64) -> u32 { return 0u32 }  // TODO: 4-byte LE read
fn acons_compute_block_id(parent_id: *u8, view: u64, payload: *u8, pl_len: u32, out: *u8) -> i32 { return ACONS_OK }  // TODO: ACONS_HASH_BUF concat + keccak256_oneshot(40+pl_len)
fn acons_phase_msg(block_id: *u8, view: u64, phase: u8) -> i32 { return ACONS_OK }  // TODO: fill ACONS_PHASE_MSG 41 bytes
fn acons_find_block_by_id(block_id: *u8) -> u32 { return ACONS_SENT }  // TODO: sentinel scan over live blocks (W14)
fn acons_alloc_block(parent_id: *u8, view: u64, payload: *u8, pl_len: u32) -> u32 { return ACONS_SENT }  // TODO: first-free slot; E_FULL via SENT
fn acons_safety_check(slot: u32) -> u8 { return 0u8 }  // TODO: HotStuff predicate; parent-chain walk via ACONS_CUR_ID (no recursion W15, no break W14)
fn acons_register_section(slot: u32, phase: u8, node: u32, section_id: *u8, sig: *u8) -> i32 { return ACONS_OK }  // TODO: bitmap dedup, store id+sig, bump count
fn acons_leader_for_view(view: u64) -> u32 @export { return 0u32 }  // TODO: view % n (no call before %; Trap 11 flagged for Phase-2 disasm)

fn acons_init(cfg: *u8) -> i32 @export { return ACONS_E_CONFIG }  // TODO: parse ACONS_Config; f=(n-1)/3; threshold=2f+1; copy peer keys; zero tables; derive producer/opids
fn acons_set_keypair(seed_pub: *u8) -> i32 @export { return ACONS_E_NULL }  // TODO: copy 64 bytes seed||pub
fn acons_current_view() -> u64 @export { return ACONS_CURRENT_VIEW }

fn acons_propose(prop: *u8, out_block: *u8) -> i32 @export { return ACONS_E_NOT_INITED }  // TODO: leader guard; build+sign block; wh_publish PREPARE
fn acons_handle_prepare(block: *u8, block_len: u32) -> i32 @export { return ACONS_E_BAD_BLOCK }  // TODO: id recompute+match; proposer sig+leader; safety_check; register own section
fn acons_handle_attest(att: *u8, att_len: u32) -> i32 @export { return ACONS_E_BAD_BLOCK }  // TODO: verify sig; find block; register_section (dedup); NO auto-advance

fn acons_glue_quorum(view: u64, out_global: *u8) -> i32 @export { return ACONS_E_NO_QUORUM }  // TODO: count>=threshold else E_NO_QUORUM; build sheaf base; sh_check_glue -> E_NO_GLUE | OK
fn acons_decide(cap: u64, view: u64, out_global: *u8) -> i32 @export { return ACONS_E_DENIED }  // TODO: cap_verify_rights(cap, CAP_RIGHT_DECIDE); glue_quorum; commit+advance; wh_publish DECIDE
fn acons_verify_certificate(cert: *u8, cert_len: u32) -> u8 @export { return 0u8 }  // TODO: n_sigs>=threshold; verify each sig; recompute sorted-concat root; ident_eq

fn acons_block_phase(block_slot: u32, out_phase: *u8) -> i32 @export { return ACONS_E_BAD_BLOCK }  // TODO: highest phase with count>=threshold
fn acons_decided_block(out_slot: *u32) -> i32 @export { return ACONS_E_NO_DECISION }  // TODO: SENT guard; *out_slot
fn acons_tick(elapsed_units: u64) -> i32 @export { return ACONS_E_NOT_INITED }  // TODO: timer += units; >= VIEW_TIMEOUT -> view+1, E_TIMEOUT

fn acons_selftest() -> u64 @export { return 0u64 }  // TODO: KAT-1..5; 99u64 pass else first-failing index
```
