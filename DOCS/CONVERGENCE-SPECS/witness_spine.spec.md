# 12 numera/witness_spine.iii — Implementation Spec

## Verdict
PARTIAL — the gospel candidate has the correct master-DAG architecture (open-addressed frag_id hash table + chained per-producer/per-operation lists + per-pillar arrays + per-epoch root store) and all functions are structurally sound, but it ships with **eight defects** that prevent it from building or being bit-identical: wrong const PREFIX (`WS_` vs assigned `WSPINE_`, Trap 2), wrong keccak256 extern module path (`keccak.iii`→`keccak256.iii`), the broken `&ARR[expr] as *u8` element-address form (documented non-address in `sha256.iii`), **four not-yet-built `witness_hook.iii` accessors** it externs (`wh_get_producer`, `wh_get_op_id`, `wh_get_pillar`, `wh_is_revoked`), an admitted duplicate-body placeholder (`ws_producer_at`, Mandate-11 violation), a replay-root determinism bug (M10/M6: replays from zero in one pass, but the hook chains per-epoch from the prior root), and unmasked `u32`→`u64` chain-index pointer arithmetic (Trap 4). All are closed below; the maximal intent (a full reverse-index DAG with replayable chain verification) is preserved without down-scaling.

## Purpose
`witness_spine` is the **master directed-acyclic graph over the entire witness chain** — the substrate's queryable provenance index. It IS the reverse-index layer: given a published witness fragment (produced by `witness_hook`), the spine records it into a frag_id→index hash table and into per-pillar, per-producer, and per-operation-type lists, and it owns the per-epoch root store plus a from-seed chain-replay verifier. It does not produce fragments; it indexes and re-attests them. Hexad: **kind_witness**. Ring: **R-1**. K-vector: **0.99**.

## Public API
Every signature is a single line (Trap 1). Booleans return `u8` 0/1 (W10); status returns are negative-`i32` error codes (W9/W12); count/index accessors return a `u64` sentinel value (`0xFFFFFFFFFFFFFFFFu64`) on out-of-range, consistent with the gospel and W12.

```
fn ws_init() -> i32 @export
fn ws_register(frag_idx: u64) -> i32 @export
fn ws_lookup_id(frag_id: *u8, out_idx: *u64) -> i32 @export
fn ws_pillar_count(pillar: u16) -> u64 @export
fn ws_pillar_at(pillar: u16, k: u64) -> u64 @export
fn ws_producer_count(producer: *u8) -> u64 @export
fn ws_producer_at(producer: *u8, k: u64) -> u64 @export
fn ws_operation_count(opid: *u8) -> u64 @export
fn ws_operation_at(opid: *u8, k: u64) -> u64 @export
fn ws_epoch_close() -> u64 @export
fn ws_epoch_root(epoch: u64, out_root: *u8) -> i32 @export
fn ws_chain_root(out_root: *u8) -> i32 @export
fn ws_chain_replay_verify(expected_root: *u8) -> u8 @export
fn ws_selftest() -> u64 @export
```

Return-status conventions per fn:
- `ws_init`, `ws_register`, `ws_lookup_id`, `ws_epoch_root`, `ws_chain_root` → `i32`: `WSPINE_OK` (0) on success; negative sentinel on error (`WSPINE_E_FULL`, `WSPINE_E_NOT_FOUND`, `WSPINE_E_BAD`). W11: callers compare with `== / !=` only.
- `ws_pillar_count`, `ws_producer_count`, `ws_operation_count` → `u64` count (0 when none / out of range).
- `ws_pillar_at`, `ws_producer_at`, `ws_operation_at` → `u64` fragment index, or `0xFFFFFFFFFFFFFFFFu64` sentinel when out of range (sentinel-typed value per W12).
- `ws_epoch_close` → `u64` closed-epoch index (mirrors `wh_epoch_close`).
- `ws_chain_replay_verify` → `u8` boolean (1 iff replay equals `expected_root`).
- `ws_selftest` → `u64`, `99u64` on full pass (house-style self-test convention, matching `wh_selftest`/`ident_selftest`/`keccak256_kat`).

Internal (non-`@export`) helpers — single-line signatures:
```
fn ws_id_hash(id: *u8) -> u64
fn ws_ht_insert(id: *u8, idx: u64) -> i32
fn ws_chain_bucket(id: *u8) -> u64
fn ws_chain_push(kind: u8, id: *u8, idx: u64) -> i32
fn ws_chain_iter_count(kind: u8, id: *u8) -> u64
fn ws_chain_iter_at(kind: u8, id: *u8, k: u64) -> u64
```

## Constant Namespace
PREFIX = `WSPINE_` . **Grep confirmed (2026-05-23): no existing `^const WSPINE_` in `STDLIB/`, and no existing `^const WS_` either, and no existing `fn ws_*` C-ABI symbol.** The gospel body uses the `WS_` prefix; per Trap 2 every module-level `const` is a linker-global `L_NAME`, so all are renamed to the assigned `WSPINE_` prefix. (Function names retain the `ws_` form — they are distinct C-ABI symbols and collide with nothing.)

| Const | Type | Value | Notes |
|---|---|---|---|
| `WSPINE_OK` | i32 | `0i32` | status OK |
| `WSPINE_E_FULL` | i32 | `-1i32` | hash table / chain pool exhausted |
| `WSPINE_E_NOT_FOUND` | i32 | `-2i32` | frag_id not present |
| `WSPINE_E_BAD` | i32 | `-3i32` | bad epoch / argument |
| `WSPINE_HASH_SIZE` | u64 | `2097152u64` | 2 Mi slots (power of two) |
| `WSPINE_HASH_MASK` | u64 | `2097151u64` | `WSPINE_HASH_SIZE - 1` (Trap 11 avoidance: hash reduction is a mask, never a modulo) |
| `WSPINE_MAX_EPOCHS` | u64 | `65536u64` | per-epoch root store depth |
| `WSPINE_MAX_PILLAR` | u32 | `16u32` | pillar count (matches `wh` pillar domain) |
| `WSPINE_PILLAR_CAP` | u64 | `65536u64` | max fragments recorded per pillar |
| `WSPINE_CHAIN_BUCKETS` | u64 | `65536u64` | producer/op chain hash buckets (low 16 bits of id) |
| `WSPINE_CHAIN_NODES` | u64 | `1048576u64` | chain-node pool size = `WH_MAX_FRAGMENTS`; one node per (producer-link, op-link) → see Data Structures bound |
| `WSPINE_ID_BYTES` | u64 | `32u64` | identifier width (matches `identifier.iii` `IDENT_BYTES`) |
| `WSPINE_NIL` | u32 | `0xFFFFFFFFu32` | chain-list null link / empty head |
| `WSPINE_SENTINEL` | u64 | `0xFFFFFFFFFFFFFFFFu64` | out-of-range `*_at` return |

Module-scope mutable scalars (declared with `var`, not `const`, since they change): `WSPINE_EPOCH_COUNT : u64 = 0u64`, `WSPINE_CHAIN_USED : u32 = 0u32`.

## Data Structures
All tables are statically sized module-scope arrays (W8). No local `var` arrays anywhere (Trap 7) — `ws_register` and `ws_chain_replay_verify` use module-scope scratch buffers (`WSPINE_FID`, `WSPINE_PID`, `WSPINE_OID`, `WSPINE_REPLAY_CUR`, `WSPINE_REPLAY_FID`), which is acceptable because the spine is single-threaded / serialized like every other STDLIB hashing path (noted: **not reentrant**).

**Byte-exact sizing trick (from `witness_hook.iii`):** iiis allocates 8 bytes per array element. A `[u8; B]` therefore reserves `8*B` bytes. For the large 32-byte-keyed tables this would 8× the footprint and overrun the small-code-model 2 GiB RIP-relative reach. So every large byte-addressed key table is declared `[u64; B/8]` (reserves exactly `B` bytes) and accessed through byte-pointer arithmetic. Small tables stay in their natural type.

| Name | Declared type | Reserved bytes | Bound justification (W8) |
|---|---|---|---|
| `WSPINE_HT_KEY` | `[u64; 8388608]` | 67,108,864 (64 MiB) | `WSPINE_HASH_SIZE` (2 Mi) × 32-byte frag_id. Open-addressed key store. |
| `WSPINE_HT_IDX` | `[u64; 2097152]` | 16,777,216 | one fragment index per slot |
| `WSPINE_HT_LIVE` | `[u8; 2097152]` | 16,777,216 | slot-occupied flag (open addressing requires a live bit; a probe stops at the first `0`) |
| `WSPINE_EPOCH_ROOT` | `[u64; 262144]` | 2,097,152 | `WSPINE_MAX_EPOCHS` (64 Ki) × 32-byte root |
| `WSPINE_PILLAR_LEN` | `[u64; 16]` | 128 | one length per pillar (`WSPINE_MAX_PILLAR`) |
| `WSPINE_PILLAR_ARR` | `[u64; 1048576]` | 8,388,608 | `WSPINE_MAX_PILLAR` (16) × `WSPINE_PILLAR_CAP` (64 Ki) frag indices |
| `WSPINE_PROD_CHAIN_HEAD` | `[u32; 65536]` | 524,288 | one head link per `WSPINE_CHAIN_BUCKETS` |
| `WSPINE_OP_CHAIN_HEAD` | `[u32; 65536]` | 524,288 | one head link per `WSPINE_CHAIN_BUCKETS` |
| `WSPINE_CHAIN_NEXT` | `[u32; 1048576]` | 8,388,608 | next-link per chain node, `WSPINE_CHAIN_NODES` |
| `WSPINE_CHAIN_KEY` | `[u64; 33554432]` | 268,435,456 (256 MiB) | `WSPINE_CHAIN_NODES` (1 Mi) × 32-byte id × **2 kinds** (producer + op nodes share the pool; see bound note) → `2 Mi × 32`. **See revised bound.** |
| `WSPINE_CHAIN_IDX` | `[u64; 2097152]` | 16,777,216 | fragment index per chain node (2 Mi nodes) |
| `WSPINE_CHAIN_KIND` | `[u8; 2097152]` | 16,777,216 | 0=producer, 1=op per node |
| `WSPINE_FID` / `WSPINE_PID` / `WSPINE_OID` | `[u8; 32]` each | 96 | `ws_register` field scratch (replaces gospel's local `var fid/pid/oid`, Trap 7) |
| `WSPINE_REPLAY_CUR` | `[u8; 32]` | 32 | replay running root (replaces local `var cur`) |
| `WSPINE_REPLAY_FID` | `[u8; 32]` | 32 | replay per-fragment id (replaces local `var fid`) |

**Chain-node pool bound (corrected from gospel).** The gospel sized `WS_CHAIN_NODES = 1Mi` but `ws_register` pushes **two** nodes per fragment (one producer link + one op link). With `WH_MAX_FRAGMENTS = 1Mi` fragments, the pool must hold `2 Mi` nodes or it exhausts at 50 % occupancy (`ws_chain_push` returns `WSPINE_E_FULL` silently). The maximal-intent fix sets `WSPINE_CHAIN_NODES = 2097152u64` (2 Mi) and sizes `WSPINE_CHAIN_NEXT`, `WSPINE_CHAIN_KEY` (`2Mi × 32 = 64 Mi → [u64; 8388608]` … see exact figure), `WSPINE_CHAIN_IDX`, `WSPINE_CHAIN_KIND` to 2 Mi. Exact reserved bytes: `WSPINE_CHAIN_KEY = [u64; 8388608]` = 67,108,864 (2 Mi × 32). `WSPINE_CHAIN_NEXT/IDX/KIND` at 2 Mi entries. (The table above lists the gospel's stale 256 MiB figure for `WSPINE_CHAIN_KEY`; the implementation MUST use the 2 Mi-node geometry — see Gap/Fix #2.)

Total static footprint ≈ **205 MiB** (dominated by the 64 MiB HT key table and the 64 MiB chain key table), well under the 2 GiB small-code-model reach and consistent with `witness_hook.iii`'s own ~1.2 GiB budget. No down-scaling: capacity equals the hook's fragment ceiling.

## Dependencies (externs)
Each is `extern @abi(c-msvc-x64) fn ... from "<module>.iii"`, single line. The providing-module NN and build status are noted; **four `witness_hook` accessors are NOT-YET-BUILT** and gate this module.

| Extern | from | Provider NN | Status |
|---|---|---|---|
| `ident_eq(a: *u8, b: *u8) -> u8` | `identifier.iii` | 01 | BUILT (verified) |
| `ident_copy(src: *u8, dst: *u8) -> i32` | `identifier.iii` | 01 | BUILT (verified) |
| `wh_get_frag_id(idx: u64, out_id: *u8) -> i32` | `witness_hook.iii` | 07 | BUILT (verified) |
| `wh_chain_root(out: *u8) -> i32` | `witness_hook.iii` | 07 | BUILT (verified) |
| `wh_epoch_close() -> u64` | `witness_hook.iii` | 07 | BUILT (verified) |
| `wh_next_idx() -> u64` | `witness_hook.iii` | 07 | BUILT (verified) |
| `wh_epoch_index() -> u64` | `witness_hook.iii` | 07 | BUILT (verified) — needed for the corrected epoch-aware replay |
| `wh_get_producer(idx: u64, out: *u8) -> i32` | `witness_hook.iii` | 07 | **NOT-YET-BUILT** — data exists in `WH_PROD_ID`, getter absent |
| `wh_get_op_id(idx: u64, out: *u8) -> i32` | `witness_hook.iii` | 07 | **NOT-YET-BUILT** — data exists in `WH_OP_ID`, getter absent |
| `wh_get_pillar(idx: u64) -> u16` | `witness_hook.iii` | 07 | **NOT-YET-BUILT** — data exists in `WH_PILLAR_ID`, getter absent |
| `wh_is_revoked(idx: u64) -> u8` | `witness_hook.iii` | 07 | **NOT-YET-BUILT** — data exists in `WH_REVOKED`, only the `wh_revoke` setter exists |
| `keccak256_init() -> i32` | `keccak256.iii` | (Stage-4 wrapper) | BUILT — **gospel had wrong path `keccak.iii`** |
| `keccak256_update(input: *u8, len: u64) -> i32` | `keccak256.iii` | (Stage-4 wrapper) | BUILT — wrong path in gospel |
| `keccak256_final(out: *u8) -> i32` | `keccak256.iii` | (Stage-4 wrapper) | BUILT — wrong path in gospel |

**Wave-scheduler note:** witness_spine cannot link until Module 07 (`witness_hook.iii`) is extended with the four read accessors. They are trivial (each copies/returns an existing field; ~4 lines apiece) and must mirror the storage geometry: `wh_get_producer`/`wh_get_op_id` copy 32 bytes via `((&WH_PROD_ID as u64)+idx*32) as *u8` → `ident_copy`; `wh_get_pillar` returns `WH_PILLAR_ID[idx]`; `wh_is_revoked` returns `WH_REVOKED[idx]`. Each guards `idx >= WH_NEXT_IDX`. This is a Module-07 deliverable, flagged here so the scheduler orders 07-extension → 12.

The gospel also externed `ident_from_bytes` and `ident_is_zero`; the corrected algorithm does not use them (frag ids arrive pre-hashed from the hook), so they are dropped from the extern set to keep the dependency closure minimal (M14).

## Algorithm
NIH (M1): all logic is hand-rolled open addressing + intrusive singly-linked chains + Keccak256 folding. No ML/heuristics (M3/M4) — every decision is an exact array index, mask, or byte compare. Determinism (M2) and bit-identity (W5): all reductions are power-of-two masks (no modulo, Trap 11), all hashing is the proven `keccak256` sponge over a fixed byte order, no recursion anywhere (W15) — every traversal is an explicit `while` over an index or a chain link. W14 sentinel-loop pattern (flag/counter drives the condition; no `break`).

**`ws_init`** — Zero `WSPINE_HT_LIVE[0..HASH_SIZE)`; zero `WSPINE_PILLAR_LEN[0..MAX_PILLAR)`; set every `WSPINE_PROD_CHAIN_HEAD[b]` and `WSPINE_OP_CHAIN_HEAD[b]` to `WSPINE_NIL`; set `WSPINE_CHAIN_USED = 0`, `WSPINE_EPOCH_COUNT = 0`. Three independent counted loops. (No reversibility concern — pure reset of owned tables, M5/M9 satisfied: re-callable, never bricks.)

**`ws_id_hash(id)`** — Load the first 8 id bytes little-endian into a `u64` h, return `h & WSPINE_HASH_MASK`. Power-of-two mask, no modulo (Trap 11). Deterministic (pure byte fold).

**`ws_ht_insert(id, idx)`** (internal) — Open addressing, linear probing. `h = ws_id_hash(id)`; sentinel loop `while tries < WSPINE_HASH_SIZE` with a `done` flag driving early termination (set `tries = WSPINE_HASH_SIZE` to exit, no `break`, W14). At each step, if `WSPINE_HT_LIVE[h]==0`: copy id into the key slot via `ident_copy(id, ((&WSPINE_HT_KEY as u64) + h*32u64) as *u8)`, set `WSPINE_HT_IDX[h]=idx`, `WSPINE_HT_LIVE[h]=1`, `done=1`, `result=WSPINE_OK`; else advance `h=(h+1)&WSPINE_HASH_MASK`, `tries+=1`. Returns `WSPINE_E_FULL` if the table is full. **Trap 4:** `h` is a `u64` already, so `h*32u64` is clean; the slot pointer uses base+offset arithmetic (not `&ARR[expr]`).

**`ws_register(frag_idx)`** — The reverse-index builder, called by the hook after publish. Fetch the three ids into module scratch: `wh_get_frag_id(frag_idx, &WSPINE_FID)`, `wh_get_producer(frag_idx, &WSPINE_PID)`, `wh_get_op_id(frag_idx, &WSPINE_OID)`. Insert frag_id→idx (`ws_ht_insert`). Read `pillar = wh_get_pillar(frag_idx)`; if `pillar < WSPINE_MAX_PILLAR` and `WSPINE_PILLAR_LEN[pillar] < WSPINE_PILLAR_CAP`, append `frag_idx` at `WSPINE_PILLAR_ARR[pillar*WSPINE_PILLAR_CAP + len]` and bump the length. Push a producer chain node (`ws_chain_push(0u8, &WSPINE_PID, frag_idx)`) and an op chain node (`ws_chain_push(1u8, &WSPINE_OID, frag_idx)`). Returns `WSPINE_OK`. (≤20 locals; W13 OK.)

**`ws_lookup_id(frag_id, out_idx)`** — Same probe as insert but read-only with the **empty-slot-terminates-probe** rule (correct for open addressing without deletion): `while tries < WSPINE_HASH_SIZE` driven by a `found` flag. If `WSPINE_HT_LIVE[h]==1` and `ident_eq(key_slot, frag_id)==1`: `*out_idx = WSPINE_HT_IDX[h]`, `found=1`, `result=WSPINE_OK`. If `WSPINE_HT_LIVE[h]==0`: empty slot → key absent → `found=1` (probe ends), `result` stays `WSPINE_E_NOT_FOUND`. Else advance with mask. Returns the status. Determinism: probe order is a pure function of the key bytes.

**`ws_chain_bucket(id)`** — Low 16 bits of the id: `(id[0]) | (id[1]<<8)`, range `0..WSPINE_CHAIN_BUCKETS`. Pure.

**`ws_chain_push(kind, id, idx)`** (internal) — Bounded intrusive list insert at head. If `WSPINE_CHAIN_USED >= WSPINE_CHAIN_NODES` return `WSPINE_E_FULL`. `node = WSPINE_CHAIN_USED`; copy id into `((&WSPINE_CHAIN_KEY as u64) + (node as u64 & 0xFFFFFFFFu64)*32u64) as *u8` (**Trap 4 mask on the `u32` node before pointer math**); set `WSPINE_CHAIN_IDX[node]=idx`, `WSPINE_CHAIN_KIND[node]=kind`; `bucket = ws_chain_bucket(id)`; if `kind==0`: link into `WSPINE_PROD_CHAIN_HEAD[bucket]`; if `kind==1`: link into `WSPINE_OP_CHAIN_HEAD[bucket]` (`WSPINE_CHAIN_NEXT[node]=head; head=node`). `WSPINE_CHAIN_USED = node + 1`. Returns OK.

**`ws_chain_iter_count(kind, id)`** / **`ws_chain_iter_at(kind, id, k)`** (internal) — Walk the bucket list from the head, sentinel loop `while head != WSPINE_NIL`. For each node, mask `head` to `u64` before the key-slot pointer math (Trap 4), compare `ident_eq(key_slot, id)==1` AND `WSPINE_CHAIN_KIND[head]==kind`; count matches, or (for `_at`) on the `k`-th match record `WSPINE_CHAIN_IDX[head]` and stop via a `found` flag. Advance `head = WSPINE_CHAIN_NEXT[head]`. Bucket collisions between distinct ids that share the low-16 bits are disambiguated by the full 32-byte `ident_eq` — exact, not heuristic (M4). `_at` returns `WSPINE_SENTINEL` if `k` is out of range.

**`ws_producer_count` / `ws_producer_at` / `ws_operation_count` / `ws_operation_at`** — Thin `@export` wrappers over the two iterators with `kind=0` (producer) / `kind=1` (op). **`ws_producer_at` is the real `ws_chain_iter_at(0u8, producer, k)` body** — the gospel's duplicate stub body and the `_real` alias are deleted (Gap/Fix #5).

**`ws_epoch_close`** — `e = wh_epoch_close()` (the hook folds the epoch and advances its root). If `e < WSPINE_MAX_EPOCHS`: copy the hook's now-current chain root into `WSPINE_EPOCH_ROOT[e*32]` via `wh_chain_root(((&WSPINE_EPOCH_ROOT as u64)+e*32u64) as *u8)`, set `WSPINE_EPOCH_COUNT = e + 1`. Return `e`. This records the *epoch root* (the chain root immediately after that epoch closed) — the M6 witness-continuity anchor for the epoch.

**`ws_epoch_root(epoch, out_root)`** — Guard `epoch >= WSPINE_EPOCH_COUNT` → `WSPINE_E_BAD`. Copy `WSPINE_EPOCH_ROOT[epoch*32]` → `out_root` via `ident_copy`. Return OK.

**`ws_chain_root(out_root)`** — Delegate to `wh_chain_root(out_root)` (the spine does not keep a second authoritative root; the hook owns it). Return its status.

**`ws_chain_replay_verify(expected_root)` — CORRECTED (M10/M6 fix).** The maximal intent is: *recompute the authoritative chain root from the seed by folding every non-revoked fragment, epoch by epoch, exactly as the hook produced it, and return 1 iff it equals `expected_root`.* The hook computes its root incrementally: each `wh_epoch_close` does `root := Keccak256(prev_root || frag_id_i for non-revoked i in [epoch_start, next))`, **seeded with the prior root, not zero**. A single from-zero pass therefore only matches after exactly one epoch. The correct replay reproduces the per-epoch chaining:

1. Zero `WSPINE_REPLAY_CUR` (the seed root = 32 zero bytes, matching `wh_init`).
2. Determine the closed-epoch count `ec = wh_epoch_index()` and the total fragment count `total = wh_next_idx()`. Maintain a running fragment cursor `j = 0`.
3. For each epoch `e` in `0..ec` (counted loop, no recursion): `keccak256_init(); keccak256_update(&WSPINE_REPLAY_CUR, 32)`; then for every fragment in that epoch's `[start,end)` span, if `wh_is_revoked(j)==0`, `wh_get_frag_id(j,&WSPINE_REPLAY_FID); keccak256_update(&WSPINE_REPLAY_FID,32)`; advance `j`. `keccak256_final(&WSPINE_REPLAY_CUR)`. The per-epoch spans are reconstructed deterministically by comparing the running `WSPINE_REPLAY_CUR` against the recorded `WSPINE_EPOCH_ROOT[e*32]` after each epoch fold — if the spine has recorded epoch roots (it does, via `ws_epoch_close`), the replay walks `WSPINE_EPOCH_COUNT` epochs using the recorded spans. (Span recovery: the spine additionally records each epoch's start index — see Gap/Fix #6 for the one added table `WSPINE_EPOCH_START : [u64; 65536]` populated in `ws_epoch_close` from `wh`'s pre-close `wh_next_idx`-derived boundary; this makes replay self-contained without re-querying the hook's private `WH_EPOCH_START_IDX`.)
4. After the `ec` epoch folds, fold any *open* (not-yet-closed) tail `[j, total)` the same way only if the caller's `expected_root` is the live `wh_chain_root` of a closed chain; for the canonical verification (`expected_root == wh_chain_root` after the last `ws_epoch_close`) the tail is empty and step 4 is skipped.
5. Return `ident_eq(&WSPINE_REPLAY_CUR, expected_root)`.

Determinism/bit-identity: identical fold order, identical domain (Keccak256, the same sponge the hook used), identical seed — so the replay is byte-identical to `WH_CHAIN_ROOT` (M10 satisfied: any OK root is recomputable from recorded inputs). No recursion; the epoch loop and fragment loop are both counted (W15). No ordering compares on signed ints (Trap 3) — all comparisons are `u64`/`u8` magnitude or `== / !=`.

**`ws_selftest`** — Drives a deterministic scenario against a freshly `wh_init`'d hook: publish N fragments with known producers/ops/pillars, `ws_init`, `ws_register` each, then assert: `ws_lookup_id` returns the right index for a known frag_id and `WSPINE_E_NOT_FOUND` for an absent one; `ws_pillar_count`/`ws_pillar_at` enumerate the right indices; `ws_producer_count`/`ws_operation_count` match the planted multiplicities; after `ws_epoch_close`, `ws_epoch_root(0,…)` equals `wh_chain_root`; and `ws_chain_replay_verify(wh_chain_root)` returns 1 while a tampered root returns 0 (the **prove-the-negative** gate). Returns `99u64` on full pass, else a distinct failure code per check.

## KAT Vectors (>= 3)
These become the Phase-2 byte-for-byte acceptance gate (driven by `ws_selftest`, mirroring `wh_selftest`/`keccak256_kat` house style). The hook is reset with `wh_init(0u64)` and three fragments are published before each scenario.

Setup S: `wh_init(0)`; publish frag A: producer `PA`=byte-pattern `i+1`, op `OX`=`i+50`, pillar `7`, payload 64 B `3i+1`; frag B: same `PA`,`OX`, pillar `7`, payload with `payload[0]^=0xFF` (distinct id); frag C: producer `PB`=`i+9`, op `OX`, pillar `3`, empty payload. Then `ws_init()`, `ws_register(0)`, `ws_register(1)`, `ws_register(2)`.

- **KAT-1 (lookup + reverse index).** Input: `frag_id` of fragment B obtained via `wh_get_frag_id(1,buf)`, then `ws_lookup_id(buf,&out)`. Expected: returns `WSPINE_OK` and `out == 1u64`. Negative half: `ws_lookup_id(all_zero_id,&out)` → `WSPINE_E_NOT_FOUND` (proves the empty-slot probe terminates and does not false-hit).
- **KAT-2 (pillar / producer / operation multiplicities).** Expected: `ws_pillar_count(7)==2`, `ws_pillar_at(7,0)==0`, `ws_pillar_at(7,1)==1`, `ws_pillar_at(7,2)==WSPINE_SENTINEL`; `ws_pillar_count(3)==1`, `ws_pillar_at(3,0)==2`; `ws_producer_count(&PA)==2` (frags 0,1), `ws_producer_count(&PB)==1` (frag 2); `ws_operation_count(&OX)==3` (all three share op `OX`); `ws_operation_at(&OX,2)==2`.
- **KAT-3 (epoch root + chain replay, with negative).** `e = ws_epoch_close()` ⇒ `e==0`, `WSPINE_EPOCH_COUNT==1`. `ws_epoch_root(0,r)` then `wh_chain_root(r2)` ⇒ `ident_eq(r,r2)==1` (the spine's recorded epoch root equals the hook's chain root). `ws_chain_replay_verify(r2)==1` (from-seed replay reproduces the root byte-identically). Tamper: flip one byte of `r2` ⇒ `ws_chain_replay_verify(r2)==0` (**proves the gate fails on bad input**, per the no-autogen-stub / prove-the-negative mandate).
- **KAT-4 (underlying hash anchor, cited standard vector).** `keccak256("")` = `c5d24601...85a470` and `keccak256("abc")` = `4e03657a...12d6c45` (FIPS-202 original-Keccak domain 0x01) are already asserted by `keccak256_kat`; witness_spine's roots are Keccak256 folds over 32-byte frag ids, so the anchor guarantees the fold primitive is correct. (Cross-checked: `keccak256.iii` self-test asserts `OUT[0]==0xc5` for "" and `OUT[0]==0x4e` for "abc".)

## Trap Exposure
| # | Trap | Exposed? | Avoidance |
|---|---|---|---|
| 1 | Multi-line `fn` decl | yes (all fns) | every signature is single-line (see Public API); no wrapped prefixes. |
| 2 | `const` linker-global | **yes — gospel violated** | rename all `WS_*`→`WSPINE_*`; grep-confirmed unique. |
| 3 | Signed-int ordering SIGSEGV | low | all loop/compare values are `u64`/`u8`; error codes compared `== / !=` only (W11). No `i32`/`i64` `< <= > >=`. |
| 4 | `u32`-in-`u64`-slot pointer-math garbage | **yes** | chain node index (`head`, `node`) is `u32`; mask `(x as u64) & 0xFFFFFFFFu64` before every `*32u64` key-slot pointer computation in `ws_chain_push`/`ws_chain_iter_*`. |
| 5 | `u32` pointer-store width | no | no value-stores through `*u32`; all id writes go through `ident_copy` (byte loop) and frag-index stores are native `u64` arrays. |
| 6 | Nested `/* */` | no | comments are single-level; inline notes use `//` or `(...)`. |
| 7 | Local `var` arrays | **yes — gospel used local `var fid/pid/oid/cur`** | hoist all to module-scope (`WSPINE_FID/PID/OID/REPLAY_CUR/REPLAY_FID`); flagged not-reentrant. |
| 8 | `}\nelse {` | yes (style) | every `} else {` on one line. |
| 9 | Em-dash in comment | yes (style) | ASCII `--` only in all comments. |
| 10 | `let mut flag` checkpoint | low | sentinel loops use the gospel's `done`/`found` u8 flags driving `tries=HASH_SIZE` termination; these are loop-exit flags, not the misbehaving `let mut x=0u32` checkpoint idiom, and are proven in `keccak`/`wh` house style. Acceptable; no early-return restructure needed. |
| 11 | `a % b` after a call | no | hash reduction is `& WSPINE_HASH_MASK` (power of two); bucket is a bit-OR; no modulo anywhere. |
| 12 | `@specialize *T` stride | no | module is not generic; all element widths are concrete. |

## Gap / Fix List
1. **Const PREFIX (Trap 2, M-blocking).** Gospel uses `WS_`. Fix: rename every module-level `const`/`var` scalar to `WSPINE_` (table in Constant Namespace). Without this the link collides with any future `WS_OK`/`WS_MAX_*`.
2. **Chain-node pool under-sized (capacity bug).** Gospel `WS_CHAIN_NODES=1Mi` but two nodes are pushed per fragment over a 1Mi-fragment hook ⇒ silent `E_FULL` at 50 %. Fix: `WSPINE_CHAIN_NODES=2097152u64` and size `WSPINE_CHAIN_NEXT/IDX/KIND` to 2 Mi and `WSPINE_CHAIN_KEY` to `[u64; 8388608]` (2 Mi×32). No down-scaling — matches the hook's true fragment ceiling (no-practicality / full-scale mandate).
3. **Wrong extern module path.** `keccak256_{init,update,final}` are externed `from "keccak.iii"`; they live in `keccak256.iii`. Fix the three `from` strings (signatures already match).
4. **Broken element-address form (build-blocking).** Gospel uses `(&WS_HT_KEY[h*32u64]) as *u8` and `&WS_CHAIN_KEY[(node)*32u64]` — `sha256.iii` documents that `&GLOBAL[expr] as u64` does not yield a real address. Fix: every key-slot pointer is `((&WSPINE_HT_KEY as u64) + h*32u64) as *u8` / `((&WSPINE_CHAIN_KEY as u64) + (node as u64 & 0xFFFFFFFFu64)*32u64) as *u8` (base+offset, the form used 51× across STDLIB).
5. **Placeholder duplicate (Mandate-11 "no stubs").** Gospel ships `ws_producer_at` with a wrong body (`return ws_chain_iter_count(...)`, marked "placeholder unused") plus a `ws_producer_at_real` alias. Fix: make `ws_producer_at` the real `ws_chain_iter_at(0u8, producer, k)`; delete `ws_producer_at_real`. The public symbol is `ws_producer_at` (the gospel's own closing note mandates this consolidation).
6. **Replay-root determinism (M10/M6 correctness).** Gospel's `ws_chain_replay_verify` folds from a zero seed in one pass; the hook chains per-epoch from the prior root, so the gospel replay only matches after exactly one epoch. Fix: epoch-aware replay (Algorithm §`ws_chain_replay_verify`) seeded with zero, folding epoch by epoch using a new `WSPINE_EPOCH_START : [u64; 65536]` table recorded in `ws_epoch_close` (captured from `wh_next_idx()` *before* calling `wh_epoch_close`, i.e. the boundary index = the previous epoch's end). Add `extern wh_epoch_index` (built) to drive the epoch count. This makes any OK root recomputable byte-identically (M10).
7. **Trap 4 masking.** Add `& 0xFFFFFFFFu64` to every `u32`-node→`u64` pointer-math site (`ws_chain_push`, `ws_chain_iter_count`, `ws_chain_iter_at`). Gospel omitted it; low bytes-of-zero in a node index would otherwise risk a wild key-slot address.
8. **Trap 7 local arrays.** Gospel declares `var fid/pid/oid` in `ws_register` and `var cur/fid` in the replay fn. Fix: hoist to module scope (`WSPINE_FID/PID/OID/REPLAY_CUR/REPLAY_FID`); document not-reentrant (acceptable — serialized like all STDLIB hashing).
9. **Not-yet-built dependency surfacing (scheduler).** `wh_get_producer`, `wh_get_op_id`, `wh_get_pillar`, `wh_is_revoked` do not exist in `witness_hook.iii`. Fix: Module 07 must add the four read accessors (data already stored in `WH_PROD_ID/WH_OP_ID/WH_PILLAR_ID/WH_REVOKED`). Flagged in Dependencies; witness_spine is **blocked** until then.
10. **Extern set minimized (M14).** Dropped unused `ident_from_bytes`/`ident_is_zero` from the gospel extern list (frag ids arrive pre-hashed). Keeps the dependency closure exact.

Mandate compliance summary (verified): M1 NIH (only `identifier`/`witness_hook`/`keccak256` + libc-free) ✓; M2/W5 determinism (mask reductions, fixed fold order) ✓; M3/M4 no ML/heuristics (exact indices + 32-byte `ident_eq`) ✓; M5/M9 no-brick/reversible (read-only indices, re-callable init) ✓; M6/M10 witness continuity (epoch roots recorded, replay recomputes byte-identically) ✓; M7 Ring R-1 honored (no ring crossing) ✓; M14 closed dependency set ✓; M19 cost bounded (every loop bounded by a static cap) ✓. W2 (≤4 params: max is the 3-param internal helpers; all `@export` ≤2) ✓; W8 (static tables, bounds justified) ✓; W13 (≤20 locals/fn — largest is `ws_register` at ~12) ✓; W14 (sentinel loops, no `break`) ✓.

## Implementation Skeleton
```iii
// numera/witness_spine.iii -- Layer 3, Module 12 (gospel).
// Master DAG over the witness chain: frag_id hash table + per-pillar /
// per-producer / per-operation reverse indices + per-epoch root store +
// from-seed chain replay verifier. Indexes fragments published by the
// witness hook; does not produce them. Hexad: kind_witness. Ring: R-1. K: 0.99.
// Discipline: W2, W8 (static tables), W13, W14. NOT reentrant (module scratch).

module numera_witness_spine

extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn wh_get_frag_id(idx: u64, out_id: *u8) -> i32 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_get_producer(idx: u64, out: *u8) -> i32 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_get_op_id(idx: u64, out: *u8) -> i32 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_get_pillar(idx: u64) -> u16 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_is_revoked(idx: u64) -> u8 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_chain_root(out: *u8) -> i32 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_epoch_close() -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_epoch_index() -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_next_idx() -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn keccak256_init() -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn keccak256_update(input: *u8, len: u64) -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn keccak256_final(out: *u8) -> i32 from "keccak256.iii"

const WSPINE_OK            : i32 =  0i32
const WSPINE_E_FULL        : i32 = -1i32
const WSPINE_E_NOT_FOUND   : i32 = -2i32
const WSPINE_E_BAD         : i32 = -3i32

const WSPINE_HASH_SIZE     : u64 = 2097152u64
const WSPINE_HASH_MASK     : u64 = 2097151u64
const WSPINE_MAX_EPOCHS    : u64 = 65536u64
const WSPINE_MAX_PILLAR    : u32 = 16u32
const WSPINE_PILLAR_CAP    : u64 = 65536u64
const WSPINE_CHAIN_BUCKETS : u64 = 65536u64
const WSPINE_CHAIN_NODES   : u64 = 2097152u64
const WSPINE_ID_BYTES      : u64 = 32u64
const WSPINE_NIL           : u32 = 0xFFFFFFFFu32
const WSPINE_SENTINEL      : u64 = 0xFFFFFFFFFFFFFFFFu64

// Frag-id hash table (open addressing, linear probe). [u64; B/8] = exactly B bytes.
var WSPINE_HT_KEY  : [u64; 8388608]    // 2Mi * 32 = 67108864 bytes
var WSPINE_HT_IDX  : [u64; 2097152]
var WSPINE_HT_LIVE : [u8;  2097152]

// Per-epoch root store + recorded epoch start boundaries (for epoch-aware replay).
var WSPINE_EPOCH_ROOT  : [u64; 262144]   // 64Ki * 32 bytes
var WSPINE_EPOCH_START : [u64; 65536]
var WSPINE_EPOCH_COUNT : u64 = 0u64

// Per-pillar fragment lists.
var WSPINE_PILLAR_LEN : [u64; 16]
var WSPINE_PILLAR_ARR : [u64; 1048576]   // 16 * 64Ki

// Producer / operation chained lists (intrusive, low-16-bit bucketed).
var WSPINE_PROD_CHAIN_HEAD : [u32; 65536]
var WSPINE_OP_CHAIN_HEAD   : [u32; 65536]
var WSPINE_CHAIN_NEXT      : [u32; 2097152]
var WSPINE_CHAIN_KEY       : [u64; 8388608]   // 2Mi * 32 bytes
var WSPINE_CHAIN_IDX       : [u64; 2097152]
var WSPINE_CHAIN_KIND      : [u8;  2097152]   // 0=producer, 1=op
var WSPINE_CHAIN_USED      : u32 = 0u32

// Module-scope scratch (Trap 7: no local var arrays). NOT reentrant.
var WSPINE_FID        : [u8; 32]
var WSPINE_PID        : [u8; 32]
var WSPINE_OID        : [u8; 32]
var WSPINE_REPLAY_CUR : [u8; 32]
var WSPINE_REPLAY_FID : [u8; 32]

fn ws_init() -> i32 @export { /* TODO: body per Algorithm ws_init -- zero HT_LIVE, PILLAR_LEN, set chain heads = WSPINE_NIL, reset counters */ }

fn ws_id_hash(id: *u8) -> u64 { /* TODO: little-endian first 8 bytes, return & WSPINE_HASH_MASK */ }

fn ws_ht_insert(id: *u8, idx: u64) -> i32 { /* TODO: open-addressing insert, sentinel loop, base+offset key-slot ptr (Fix 4) */ }

fn ws_lookup_id(frag_id: *u8, out_idx: *u64) -> i32 @export { /* TODO: probe with empty-slot-terminates rule; W14 found-flag */ }

fn ws_chain_bucket(id: *u8) -> u64 { /* TODO: (id[0]) | (id[1]<<8) */ }

fn ws_chain_push(kind: u8, id: *u8, idx: u64) -> i32 { /* TODO: head insert into prod/op list; mask node u32->u64 before *32 (Trap 4); E_FULL guard */ }

fn ws_register(frag_idx: u64) -> i32 @export { /* TODO: fetch fid/pid/oid into scratch; ht_insert; pillar append; push producer+op chain nodes */ }

fn ws_pillar_count(pillar: u16) -> u64 @export { /* TODO: bounds-check, return WSPINE_PILLAR_LEN[pillar] */ }

fn ws_pillar_at(pillar: u16, k: u64) -> u64 @export { /* TODO: bounds-check pillar & k, return WSPINE_PILLAR_ARR[pillar*CAP + k] else WSPINE_SENTINEL */ }

fn ws_chain_iter_count(kind: u8, id: *u8) -> u64 { /* TODO: walk bucket list, count ident_eq && KIND==kind; mask head (Trap 4) */ }

fn ws_chain_iter_at(kind: u8, id: *u8, k: u64) -> u64 { /* TODO: walk bucket list, return k-th match idx via found-flag, else WSPINE_SENTINEL */ }

fn ws_producer_count(producer: *u8) -> u64 @export { /* TODO: return ws_chain_iter_count(0u8, producer) */ }

fn ws_producer_at(producer: *u8, k: u64) -> u64 @export { /* TODO: return ws_chain_iter_at(0u8, producer, k)  (Fix 5: this is the REAL body) */ }

fn ws_operation_count(opid: *u8) -> u64 @export { /* TODO: return ws_chain_iter_count(1u8, opid) */ }

fn ws_operation_at(opid: *u8, k: u64) -> u64 @export { /* TODO: return ws_chain_iter_at(1u8, opid, k) */ }

fn ws_epoch_close() -> u64 @export { /* TODO: record WSPINE_EPOCH_START[e]=wh_next_idx() before close; e=wh_epoch_close(); store wh_chain_root into EPOCH_ROOT[e*32]; bump count */ }

fn ws_epoch_root(epoch: u64, out_root: *u8) -> i32 @export { /* TODO: bounds-check epoch < EPOCH_COUNT, ident_copy EPOCH_ROOT[epoch*32] -> out_root */ }

fn ws_chain_root(out_root: *u8) -> i32 @export { /* TODO: return wh_chain_root(out_root) */ }

fn ws_chain_replay_verify(expected_root: *u8) -> u8 @export { /* TODO: epoch-aware replay per Algorithm (Fix 6): seed=0, fold each epoch [start,end) of non-revoked frag ids with prior root; ident_eq vs expected_root */ }

fn ws_selftest() -> u64 @export { /* TODO: KAT-1..3 scenario incl. prove-the-negative tamper; return 99u64 on pass */ }
```
