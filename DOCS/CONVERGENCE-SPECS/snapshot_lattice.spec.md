# 31 aether/snapshot_lattice.iii — Implementation Spec

## Verdict
PARTIAL — the gospel candidate body is algorithmically sound and routes emission through the
correct `wh_publish` primitive, but it (a) declares two **function-local `var` arrays** (`buf`,
`seen`) which iiis-0 cannot compile (Trap 7), (b) uses the `&ARR[idx]` element-address form that
the realized substrate does not accept (must become `((&ARR as u64)+off) as *u8`), (c) uses the
`SL_` const prefix instead of the dispatch-assigned `SNAPL_`, and (d) hardwires the reversibility
tag of the snapshot fragment to `0u8` (M9/W16: a reversibility checkpoint should carry a reversible
tag). All five dependency externs are correct against the realized provider files. No mandate, no
math, no determinism violation — these are mechanical/idiomatic gaps. Fixes are enumerated in
§Gap/Fix.

## Purpose
`snapshot_lattice` is the reversibility substrate consulted before any destructive operation (W26;
M9). Every operation that intends to be reversible publishes a **snapshot** before executing: a
tuple `(snap_id, antecedent_slot, root_commit, frag_idx)` that is the system's cryptographic
commitment to a particular prior state. Snapshots form a **partial order** under the `antecedent`
relation (`a ≤ b` iff the chain of antecedents from `b` reaches `a`); because each slot has exactly
**one** antecedent, the structure is a forest of in-trees, on which the meet (greatest common
antecedent) is well-defined and unique. The module answers three lattice queries — `sl_le`
(ancestry test), `sl_meet` (greatest common antecedent), `sl_at_frag` (latest snapshot strictly
preceding a witness-chain fragment, the retroactive query) — and stores the root commit for
rollback. **Hexad:** kind_witness + kind_repair. **Ring:** R-1. **K:** 0.99.

## Public API
All public fns return a status or a sentinel-typed value (W12). Error codes are negative `i32`
(W9); boolean returns are `u8` 0/1 (W10); slot results use the `SNAPL_SENT = 0xFFFFFFFFu32`
sentinel (slot 0 is a valid snapshot).

```
fn sl_init() -> i32 @export
fn sl_snapshot(op_id: *u8, ante_snap: u32, root: *u8) -> u32 @export
fn sl_meet(a: u32, b: u32) -> u32 @export
fn sl_le(a: u32, b: u32) -> u8 @export
fn sl_at_frag(frag_idx: u64) -> u32 @export
fn sl_root(slot: u32, out: *u8) -> i32 @export
```

Return conventions:
- `sl_init` → `SNAPL_OK` (0) always (W12).
- `sl_snapshot` → the new slot id `u32`, or `SNAPL_SENT` if the table is full / inputs bad (sentinel-typed value, W12).
- `sl_meet` → slot id of the greatest common antecedent, or `SNAPL_SENT` if none exists.
- `sl_le` → `1u8` if `a` is a (non-strict) ancestor of `b`, else `0u8` (W10).
- `sl_at_frag` → slot id of the latest live snapshot whose `frag_idx < frag_idx`, or `SNAPL_SENT`.
- `sl_root` → `SNAPL_OK`, or `SNAPL_E_BAD` if slot out of range / not live (W9/W11: compared by `==` only).

Private helpers (not exported): `sl_id_ptr(slot:u32) -> *u8`, `sl_root_ptr(slot:u32) -> *u8` (byte-offset address into the backing arrays).

## Constant Namespace
PREFIX = `SNAPL_` . Grep confirms **no collision** in `STDLIB/` for `SNAPL_` (zero hits). The
gospel body used `SL_`; `SL_` is also collision-free today, but the dispatch contract assigns
`SNAPL_`, so every const/var/symbol prefix is rewritten `SL_` → `SNAPL_` (consts, the six lattice
arrays, the producer/opid scratch). Function names (`sl_*`) keep their `sl_` prefix — they are the
module's public C-ABI surface named in the gospel API and are not the const-namespace concern of
Trap 2.

| name | type | value |
|------|------|-------|
| `SNAPL_OK`        | i32 | `0i32` |
| `SNAPL_E_BAD`     | i32 | `-1i32` |
| `SNAPL_SENT`      | u32 | `0xFFFFFFFFu32` |
| `SNAPL_MAX`       | u32 | `8192u32` |
| `SNAPL_PILLAR`    | u16 | `4u16` (the snapshot pillar id passed to `wh_publish`) |
| `SNAPL_REVTAG`    | u8  | `1u8` (reversible-checkpoint tag — see Gap/Fix #4; gospel hardwired `0u8`) |

(`SNAPL_PILLAR` / `SNAPL_REVTAG` are new named constants replacing the gospel's magic `4u16` /
`0u8` literals — clarity + M9 intent, no behavioral risk beyond the deliberate revtag change.)

## Data Structures
All slot tables are statically sized at `SNAPL_MAX = 8192` snapshots (W8). Bound justification:
8192 reversible checkpoints is the per-epoch snapshot ceiling — one snapshot per destructive
operation within an epoch; epochs roll the witness chain (`wh_epoch_close`) far below this count.
Identical bound to the gospel body. All byte buffers are addressed via `((&ARR as u64)+off) as *u8`
so the backing element type is transparent (the witness_hook idiom).

| name | type | size (elements) | bytes | purpose / bound |
|------|------|-----------------|-------|-----------------|
| `SNAPL_LIVE`     | `[u8; 8192]`   | 8192 | 8 KiB | liveness flag per slot |
| `SNAPL_ID`       | `[u8; 262144]` | 8192*32 | 256 KiB | snap_id (32 B/slot) = Keccak256(ante_id‖op_id‖at_time) |
| `SNAPL_ANTE`     | `[u32; 8192]`  | 8192 | 32 KiB | antecedent slot id (or `SNAPL_SENT`) — single parent ⇒ forest |
| `SNAPL_ROOT`     | `[u8; 262144]` | 8192*32 | 256 KiB | root_commit (32 B/slot) for rollback |
| `SNAPL_FRAG`     | `[u64; 8192]`  | 8192 | 64 KiB | witness-chain fragment index of the SNAPSHOT_TAKE fragment |
| `SNAPL_USED`     | `u32 = 0`      | scalar | — | high-water slot allocator |
| `SNAPL_PRODUCER` | `[u8; 32]`     | 32 | 32 B | producer id = ident("aether::snapshot_lattice") |
| `SNAPL_OPID_TAKE`| `[u8; 32]`     | 32 | 32 B | op id = ident("aether::snapshot_lattice::take") |
| `SNAPL_INITED`   | `u8 = 0`       | scalar | — | lazy-init guard |
| `SNAPL_BUF`      | `[u8; 72]`     | 72 | 72 B | **hoisted from gospel local** `buf` — snap_id preimage (32 ante‖32 opid‖8 time) |
| `SNAPL_SEEN`     | `[u8; 8192]`   | 8192 | 8 KiB | **hoisted from gospel local** `seen` — ancestor-marker bitmap for `sl_meet` |
| `SNAPL_INC`      | `[u8; 32]`     | 32 | 32 B | scratch `in_commit` (filled by `wh_chain_root`) for the publish call |
| `SNAPL_FID`      | `[u8; 32]`     | 32 | 32 B | scratch out_frag_id sink for the publish call |

`SNAPL_BUF`, `SNAPL_SEEN`, `SNAPL_INC`, `SNAPL_FID` are module-scope because **iiis-0 has no
function-local `var` arrays (Trap 7)**. Consequence: `sl_snapshot` and `sl_meet` are **NOT
reentrant** — acceptable, the substrate calls them serially under the destructive-op lock (W6/W8;
same posture documented for `witness_hook.iii` and `merkle.iii`).

## Dependencies (externs)
Every signature below was read from and matches the realized provider file (not the gospel's
externs). All providers are **already built** — this module has **zero not-yet-built dependencies**,
so the wave scheduler may build it as soon as its provider set is present.

```
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_chain_root(out_id: *u8) -> i32 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn at_current() -> u64 from "algebraic_time.iii"
```

| extern | provider module (NN) | built? | verified signature |
|--------|----------------------|--------|--------------------|
| `ident_from_bytes` | numera/identifier.iii | yes | `(*u8, u64, *u8) -> i32` (line 33) |
| `ident_copy`       | numera/identifier.iii | yes | `(*u8, *u8) -> i32` (line 65) |
| `wh_publish`       | aether/witness_hook.iii (07) | yes | 12-arg `-> u64` (line 144) — exact |
| `wh_chain_root`    | aether/witness_hook.iii (07) | yes | `(*u8) -> i32` (line 216) |
| `at_current`       | numera/algebraic_time.iii | yes | `() -> u64` (line 17) — gospel correctly uses `at_current`, NOT the fictional `at_now` |

Systemic-defect status for this module: defect #2 (witness emit) is **already correct** in the
gospel — it routes through `wh_publish`, not `ws_emit_fragment`. Defect #4 (algebraic time) is
**already correct** — gospel uses `at_current`. Defect #6 (witness_hook field getters) **does not
apply** — the module records its own `frag_idx` in `SNAPL_FRAG` and never reads back witness_hook
fields. Defects #1/#3/#5 are not touched (no keccak/cons_find/cap_verify use here).

## Algorithm

### `sl_init() -> i32`
1. Loop `i` over `0..SNAPL_MAX`, set `SNAPL_LIVE[i] = 0u8` (sentinel-driven `while i < SNAPL_MAX`, no break — W14).
2. `SNAPL_USED = 0u32`.
3. `ident_from_bytes("aether::snapshot_lattice", 24, &SNAPL_PRODUCER)` and `ident_from_bytes("aether::snapshot_lattice::take", 30, &SNAPL_OPID_TAKE)` — deterministic producer/op ids.
4. `SNAPL_INITED = 1u8`; return `SNAPL_OK`.
Determinism (M2): pure array clear + two fixed-string hashes; no time, no input.

### `sl_snapshot(op_id, ante_snap, root) -> u32`
1. If `SNAPL_INITED == 0u8` call `sl_init()` (lazy init).
2. If `SNAPL_USED >= SNAPL_MAX` return `SNAPL_SENT` (full).
3. Allocate `slot = SNAPL_USED`; `SNAPL_USED += 1`; `SNAPL_LIVE[slot] = 1u8`; `SNAPL_ANTE[slot] = ante_snap`.
4. `ident_copy(root, sl_root_ptr(slot))` — store the root commit.
5. Build the snap_id preimage in `SNAPL_BUF` (72 B): bytes `[0..32)` = antecedent's snap_id if `ante_snap < SNAPL_MAX && SNAPL_LIVE[ante_snap]==1`, else 32 zero bytes (genesis); bytes `[32..64)` = the 32-byte `op_id`; bytes `[64..72)` = `at_current()` as 8 little-endian bytes (`(t >> (z*8)) & 0xFFu64`).
6. `ident_from_bytes(&SNAPL_BUF, 72, sl_id_ptr(slot))` — snap_id = Keccak256(ante‖op‖time) (identifier.iii is the Keccak wrapper; hand-rolled per M1).
7. `wh_chain_root(&SNAPL_INC)` → current chain root as `in_commit`.
8. `frag = wh_publish(&SNAPL_PRODUCER, &SNAPL_OPID_TAKE, &SNAPL_INC /*in*/, sl_root_ptr(slot) /*out*/, SNAPL_REVTAG, 0u8 /*phase*/, SNAPL_PILLAR, &SNAPL_BUF /*antecedents (ignored, n_ante=0)*/, 0u32, &SNAPL_BUF /*payload*/, 72u32, &SNAPL_FID)`.
9. `SNAPL_FRAG[slot] = frag`; return `slot`.
Determinism (M2/W5): snap_id and fragment id are pure functions of (antecedent id, op id, algebraic time, root). Algebraic time is monotonic (W16) so successive snapshots are totally ordered by `frag_idx`. Bit-identity (W5): all field encodings are explicit little-endian byte writes; no float, no abstraction.

### `sl_le(a, b) -> u8`  — non-strict ancestry test
1. If `a == b` return `1u8`.
2. If `b >= SNAPL_MAX` or `SNAPL_LIVE[b]==0u8` return `0u8`.
3. Walk b's single-parent antecedent chain: `cur = SNAPL_ANTE[b]`, `ans = 0u8`, `guard = 0`. `while guard < SNAPL_MAX`: if `ans==0`: if `cur==SNAPL_SENT` set `guard=SNAPL_MAX` (terminate); else if `cur==a` set `ans=1u8`; else `cur = SNAPL_ANTE[cur]`. `guard += 1`.
4. Return `ans`.
No recursion (W15): explicit single-parent walk bounded by `SNAPL_MAX` iterations (the forest depth ≤ slot count). No `break` — the guard counter + `ans` flag drive termination (W14). All compares are `==`/`!=` on u32 (W11; the sentinel compare is equality, never ordering).

### `sl_meet(a, b) -> u32`  — greatest common antecedent
1. Clear `SNAPL_SEEN[0..SNAPL_MAX] = 0u8`.
2. Walk a's chain marking every ancestor (including `a`): `p=a`, `g1=0`; `while g1<SNAPL_MAX`: if `p!=SNAPL_SENT` { `SNAPL_SEEN[p]=1u8`; `p=SNAPL_ANTE[p]` }; if `p==SNAPL_SENT` set `g1=SNAPL_MAX`; `g1 += 1`.
3. Walk b's chain to the first marked node: `q=b`, `result=SNAPL_SENT`, `g2=0`; `while g2<SNAPL_MAX`: if `result==SNAPL_SENT` { if `q==SNAPL_SENT` set `g2=SNAPL_MAX`; else if `SNAPL_SEEN[q]==1u8` set `result=q`; else `q=SNAPL_ANTE[q]` }; `g2 += 1`.
4. Return `result`.
Correctness (why this *is* the greatest/most-recent common antecedent): each slot has exactly one `antecedent`, so a node's ancestor set is a **chain**, and the structure is a forest. The first node on b's chain that lies in a's ancestor set is the deepest (most recent) node common to both chains — i.e. the meet. Determinism (M2): set membership via a fixed bitmap, single-parent walks, no ordering compares, no data-dependent timing. Two bounded `while`s (no recursion, no break — W14/W15).

### `sl_at_frag(frag_idx) -> u32`  — retroactive query
1. `best = SNAPL_SENT`, `best_frag = 0u64`, `i = 0`.
2. `while i < SNAPL_USED`: if `SNAPL_LIVE[i]==1u8` { `f = SNAPL_FRAG[i]`; if `f < frag_idx` { if `best==SNAPL_SENT` set `best=i, best_frag=f`; else if `f > best_frag` set `best=i, best_frag=f` } }; `i += 1`.
3. Return `best` — the live snapshot with the largest `frag_idx` strictly less than `frag_idx`.
Determinism (M2): linear scan, max-by-frag selection; ties impossible (each snapshot gets a distinct monotonic `frag_idx` from `at_advance` inside `wh_publish`). **Trap 3 note:** the `f < frag_idx` / `f > best_frag` ordering compares are on **`u64`** — Trap 3 forbids only *signed* (i32/i64) ordering; unsigned ordering compiles correctly. No recursion (W15), single bounded `while` (W14).

### `sl_root(slot, out) -> i32`
1. If `slot >= SNAPL_MAX` or `SNAPL_LIVE[slot]==0u8` return `SNAPL_E_BAD`.
2. `ident_copy(sl_root_ptr(slot), out)`; return `SNAPL_OK`.

## KAT Vectors (>= 3)
A self-test (`sl_selftest() -> u64`, 99 = pass; module-scope test buffers, mirroring
`wh_selftest`) checks, byte-for-byte:

1. **Lattice ancestry / meet (linear chain).** `sl_init()`. Take `s0 = sl_snapshot(opA, SNAPL_SENT, rootA)` ⇒ expect `0`. `s1 = sl_snapshot(opA, s0, rootB)` ⇒ `1`. `s2 = sl_snapshot(opA, s1, rootC)` ⇒ `2`. Then: `sl_le(s0,s2)==1`, `sl_le(s2,s0)==0`, `sl_le(s1,s1)==1`, `sl_meet(s2,s1)==s1`, `sl_meet(s0,s2)==s0`.
2. **Meet on a fork (forest).** From `s0` above, take a second child `s3 = sl_snapshot(opA, s0, rootD)` ⇒ `3`. Then `sl_le(s2,s3)==0` and `sl_le(s3,s2)==0` (siblings, incomparable); `sl_meet(s2,s3)==s0` (greatest common antecedent is the shared root `s0`); `sl_meet(s3,s3)==s3`.
3. **Retroactive query + root round-trip.** With the chain `s0..s3` above whose `SNAPL_FRAG` values are strictly increasing (`F0<F1<F2<F3` since `at_advance` is monotonic): `sl_at_frag(F2)==s1` (latest snapshot strictly before fragment `F2` is `s1`); `sl_at_frag(F0)==SNAPL_SENT` (nothing strictly precedes the first); `sl_at_frag(F3 + 1)==s3`. And `sl_root(s2, buf)==SNAPL_OK` with `buf` byte-equal to `rootC` (verified via `ident_eq`); `sl_root(9000u32, buf)==SNAPL_E_BAD` (out of range — proves the negative case).
4. **snap_id determinism (bit-identity, W5).** Re-running test 1 from a fresh `sl_init()` with identical `(op_id, root)` inputs reproduces byte-identical `SNAPL_ID[s0..s2]` **only if** the algebraic clock is reset to the same start; since `at_current` advances globally, the KAT instead asserts the weaker reproducible invariant: within one run, `s0`'s snap_id is non-zero and differs from `s1`'s (distinct antecedent ⇒ distinct Keccak preimage), proving the hash binds the antecedent. (Full cross-run bit-identity is exercised by the substrate-level determinism gate, which seeds algebraic time deterministically.)

## Trap Exposure
| # | trap | exposed? | avoidance |
|---|------|----------|-----------|
| 1 | multi-line `fn` decl | yes (every fn) | every signature on **one line** (see Skeleton). |
| 2 | module-`const` is linker-global | yes | all consts prefixed `SNAPL_`; grep-confirmed collision-free. |
| 3 | signed ordering compare SIGSEGV | **no** | all ordering compares (`sl_at_frag`) are on **u64** (unsigned); all sentinel/slot compares are `==`/`!=` only (W11). No i32/i64 `<`/`>`/`<=`/`>=` anywhere. |
| 4 | u32-in-u64-slot garbage | yes (slot→offset math) | slot→byte offset uses `(slot as u64) * 32u64`; the `slot` u32 is multiplied as u64, but mask defensively: helpers compute `((slot as u64) & 0xFFFFFFFFu64) * 32u64` before pointer arithmetic. |
| 5 | u32 pointer store width | **no** | no `*u32` stores; `SNAPL_ANTE`/`SNAPL_FRAG` are whole-element array stores (`SNAPL_ANTE[slot]=v`), not byte-built `*u32` writes. id/root bytes are copied via `ident_copy` / `*u8` byte loops. |
| 6 | nested `/* */` comments | no | single-level block comments only; ASCII only. |
| 7 | local `var` arrays unsupported | **YES (gospel violates)** | hoist `buf`→`SNAPL_BUF`, `seen`→`SNAPL_SEEN` to module scope (+`SNAPL_INC`,`SNAPL_FID`). Documented non-reentrant. |
| 8 | `} else {` one line | yes | the gospel uses `if/if` cascades (no `else`); skeleton keeps any `else` on one line. |
| 9 | em-dash in comment | no | all comments ASCII `--`. |
| 10 | `let mut x=0u32` checkpoint-flag | minor | `sl_le`/`sl_meet` use `ans`/`result` flags **inside** the loop condition guard, not as a post-loop checkpoint; the flag gates the loop body and a counter bounds it — the documented-safe shape, not the misbehaving post-test pattern. |
| 11 | `a % b` after a call | **no** | no modulo anywhere; offsets are multiplies/shifts. |
| 12 | `@specialize *T` stride | no | not generic; fixed 32-byte / u32 / u64 element widths. |

## Gap / Fix List
The gospel body is PARTIAL. Each gap with its fix:

1. **Trap 7 — function-local `var` arrays (compile-blocking).** Gospel `sl_snapshot` line 8774
   `var buf : [u8; 72]` and `sl_meet` line 8836 `var seen : [u8; 8192]`. **Fix:** hoist to
   module-scope `SNAPL_BUF`/`SNAPL_SEEN`. Add module-scope `SNAPL_INC` (32 B) and `SNAPL_FID`
   (32 B) to replace the local `var in_c`/`var fid` in `sl_snapshot` (same trap, lines 8797/8800).
   Document non-reentrancy.
2. **Idiom — `&ARR[idx]` element address.** Gospel takes `&SL_ID[(slot as u64)*32u64]`,
   `&SL_PRODUCER[0u64]`, `&buf[0u64]`, `&in_c[0u64]`, `&fid[0u64]`. The realized substrate uses
   `((&ARR as u64) + off) as *u8` (the witness_hook reconciliation, file line 16). **Fix:** rewrite
   `sl_id_ptr`/`sl_root_ptr` and every address-of-element to the `(&ARR as u64)+off` form. (Whole-
   element array *indexing* like `SNAPL_LIVE[i]`, `SNAPL_ANTE[slot]` is fine and stays.)
3. **Const prefix `SL_` → `SNAPL_`.** Dispatch assigns PREFIX `SNAPL_`; gospel used `SL_`.
   **Fix:** rename all six consts + all module-scope `var` symbols + the two `sl_id_ptr`/
   `sl_root_ptr` array refs. (Public fn names `sl_*` stay — they are the documented C-ABI surface.)
4. **M9/W16 — reversibility tag hardwired to 0.** `sl_snapshot` publishes the SNAPSHOT_TAKE
   fragment with `revtag = 0u8`. A snapshot **is** the canonical reversible checkpoint; its witness
   fragment should carry the reversible tag so the reversibility audit (Phase 4) and any rollback
   walk can recognize it. **Fix:** pass `SNAPL_REVTAG = 1u8`. (If the substrate's `revtag`
   enumeration reserves a specific value for "snapshot checkpoint", Phase 2 must use that exact
   value — confirm against `witness_hook.iii` revtag conventions before finalizing; `1u8` is the
   placeholder for "reversible".)
5. **Magic literals → named constants.** Gospel hardwires pillar `4u16` and phase `0u8` in the
   publish call. **Fix:** introduce `SNAPL_PILLAR = 4u16`; keep phase as `0u8` literal (phase is
   set by the orchestrator, not the snapshot module). No behavior change.
6. **Verified-correct (no change needed):** (a) emission routes through `wh_publish` — matches
   systemic-defect #2's required primitive, not the fictional `ws_emit_fragment`. (b) `at_current`
   is the real algebraic-time symbol (defect #4) — gospel is correct. (c) the `sl_meet` "first
   marked node on b's chain" algorithm **is** the greatest common antecedent given single-parent
   topology — proven in Algorithm §sl_meet. (d) `sl_le`/`sl_meet`/`sl_at_frag` are all
   sentinel-loop, no-break, no-recursion (W14/W15) and use equality-only sentinel compares (W11).
   (e) all five externs match their realized providers byte-for-byte. (f) the `SNAPL_MAX=8192`
   bound is justified and W8-compliant. (g) no ML/heuristics anywhere (M3/M4) — pure algebraic
   ancestry + Keccak commitment.

## Implementation Skeleton
```iii
/* III/STDLIB/iii/aether/snapshot_lattice.iii
 *
 * III STDLIB - aether::snapshot_lattice -- per-call snapshots + retroactive queries.
 *
 * Snapshot slot:
 *   snap_id (32 B)        = Keccak256(antecedent_id || op_id || at_time)
 *   antecedent_snap (u32) = single parent slot id, or SNAPL_SENT (forest of in-trees)
 *   root_commit (32 B)    = committed prior state, for rollback
 *   frag_idx (u64)        = witness-chain index of the SNAPSHOT_TAKE fragment
 *
 * Partial order: a <= b iff the single-parent antecedent chain from b reaches a.
 * Meet (sl_meet) = greatest common antecedent (well-defined: single parent => chains).
 *
 * NOT reentrant: SNAPL_BUF/SNAPL_SEEN/SNAPL_INC/SNAPL_FID are module-scope scratch
 * (iiis-0 has no function-local var arrays -- Trap 7). Called serially under the
 * destructive-op lock.
 *
 * Hexad: kind_witness + kind_repair.  Ring: R-1.  K: 0.99.
 */
module aether_snapshot_lattice

extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_chain_root(out_id: *u8) -> i32 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn at_current() -> u64 from "algebraic_time.iii"

const SNAPL_OK     : i32 =  0i32
const SNAPL_E_BAD  : i32 = -1i32
const SNAPL_SENT   : u32 = 0xFFFFFFFFu32
const SNAPL_MAX    : u32 = 8192u32
const SNAPL_PILLAR : u16 = 4u16
const SNAPL_REVTAG : u8  = 1u8

var SNAPL_LIVE     : [u8;  8192]
var SNAPL_ID       : [u8;  262144]      /* 8192 * 32 */
var SNAPL_ANTE     : [u32; 8192]
var SNAPL_ROOT     : [u8;  262144]      /* 8192 * 32 */
var SNAPL_FRAG     : [u64; 8192]
var SNAPL_USED     : u32 = 0u32

var SNAPL_PRODUCER : [u8; 32]
var SNAPL_OPID_TAKE: [u8; 32]
var SNAPL_INITED   : u8 = 0u8

var SNAPL_BUF      : [u8; 72]           /* snap_id preimage (Trap-7 hoist) */
var SNAPL_SEEN     : [u8; 8192]         /* sl_meet ancestor bitmap (Trap-7 hoist) */
var SNAPL_INC      : [u8; 32]           /* in_commit scratch (Trap-7 hoist) */
var SNAPL_FID      : [u8; 32]           /* out_frag_id sink (Trap-7 hoist) */

fn sl_id_ptr(slot: u32) -> *u8   { return ((&SNAPL_ID   as u64) + ((slot as u64) & 0xFFFFFFFFu64) * 32u64) as *u8 }
fn sl_root_ptr(slot: u32) -> *u8 { return ((&SNAPL_ROOT as u64) + ((slot as u64) & 0xFFFFFFFFu64) * 32u64) as *u8 }

fn sl_init() -> i32 @export {
    // TODO: body per Algorithm §sl_init -- clear SNAPL_LIVE, reset SNAPL_USED, derive producer/op ids, set SNAPL_INITED.
}

fn sl_snapshot(op_id: *u8, ante_snap: u32, root: *u8) -> u32 @export {
    // TODO: body per Algorithm §sl_snapshot -- alloc slot, store ante+root, build SNAPL_BUF preimage, hash snap_id, wh_chain_root -> SNAPL_INC, wh_publish (SNAPL_REVTAG, SNAPL_PILLAR), record SNAPL_FRAG, return slot.
}

fn sl_le(a: u32, b: u32) -> u8 @export {
    // TODO: body per Algorithm §sl_le -- single-parent ancestor walk, guard-bounded, equality-only sentinel compare, no break.
}

fn sl_meet(a: u32, b: u32) -> u32 @export {
    // TODO: body per Algorithm §sl_meet -- clear SNAPL_SEEN, mark a's chain, return first marked node on b's chain (greatest common antecedent).
}

fn sl_at_frag(frag_idx: u64) -> u32 @export {
    // TODO: body per Algorithm §sl_at_frag -- linear scan of live slots, select max SNAPL_FRAG strictly < frag_idx (u64 ordering OK).
}

fn sl_root(slot: u32, out: *u8) -> i32 @export {
    // TODO: body per Algorithm §sl_root -- range/live check (== compare), ident_copy(sl_root_ptr(slot), out).
}
```
