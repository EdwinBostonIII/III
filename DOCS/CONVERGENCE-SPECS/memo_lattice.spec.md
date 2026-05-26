# 58 numera/memo_lattice.iii — Implementation Spec

## Verdict
PARTIAL — the gospel candidate body is structurally near-complete and correct on the signed-compare trap (uses `== -1i64` sentinels throughout, never ordering), but it violates Trap 7 pervasively (every scratch buffer is a local `let mut [u8; N]` array, unsupported by iiis-0), carries a witness-continuity asymmetry (`ml_revalidate` emits no fragment while `ml_mark_stale` does), under-specifies the M17/W36 lookup contract (the returned hit is UNVERIFIED — caller MUST call `ws_verify_segment`), and uses the unassigned `ML_` prefix instead of the dispatched `MEMOL_`. All gaps are closeable without changing the public API shape.

## Purpose
The memoization lattice IS a content-addressed cache mapping a 32-byte key (a content address of an (operation, inputs) tuple, computed upstream by `content_addr.iii`) to an `(output_commitment, chain_id, K_memo)` triple. It is the substrate of M17 memoization sovereignty: it stores results but never *trusts* them — every admission verifies the producing witness-spine segment before insertion, and every consumer re-verifies the returned `chain_id` before use. Hexad: `kind_essence + kind_cognition`. Ring: **R0**. K-vector: **1.00** (per-entry `K_memo` ∈ 0..100 returned by lookup).

## Public API
All public fns return a negative-`i32` status (W9) or a sentinel-typed scalar (W12). `MEMOL_OK = 0i32`; all errors negative; compared by `==`/`!=` only (W11).

```
fn ml_init() -> i32 @export
fn ml_admit(key: *u8, out_commit: *u8, chain_id: *u8) -> i32 @export
fn ml_lookup(key: *u8, out_commit: *u8, out_chain_id: *u8, out_k_memo: *u8) -> i32 @export
fn ml_mark_stale(key: *u8) -> i32 @export
fn ml_revalidate(key: *u8) -> i32 @export
fn ml_size() -> u64 @export
```

Internal (non-`@export`) helpers — return a sentinel `i64` (W12; `-1i64` = none):

```
fn ml_hash_slot(key: *u8) -> u64
fn ml_slot_find(key: *u8) -> i64
fn ml_slot_alloc(key: *u8) -> i64
fn ml_emit_event(tag: u8, key: *u8, chain_id: *u8) -> i32
```

Return-status convention per fn:
- `ml_init` → `MEMOL_OK` (idempotent; never fails).
- `ml_admit` → `MEMOL_OK` | `MEMOL_E_NOT_INITED` | `MEMOL_E_NULL` | `MEMOL_E_CLAUSE_ABSENT` | `MEMOL_E_VERIFY_FAIL` | `MEMOL_E_DUPLICATE` | `MEMOL_E_FULL` (and propagates the emit status as `MEMOL_OK` on success — see Gap #4).
- `ml_lookup` → `MEMOL_OK` (result is UNVERIFIED; caller must verify `out_chain_id`) | `MEMOL_E_NOT_INITED` | `MEMOL_E_NULL` | `MEMOL_E_ABSENT` | `MEMOL_E_STALE`.
- `ml_mark_stale` → `MEMOL_OK` | `MEMOL_E_NOT_INITED` | `MEMOL_E_NULL` | `MEMOL_E_ABSENT`.
- `ml_revalidate` → `MEMOL_OK` | `MEMOL_E_NOT_INITED` | `MEMOL_E_NULL` | `MEMOL_E_ABSENT` | `MEMOL_E_VERIFY_FAIL`.
- `ml_size` → live+stale entry count as `u64` (W12 sentinel-typed scalar; `0u64` before init is a legitimate value).

## Constant Namespace
**PREFIX = `MEMOL_`** (dispatched). Grep of `STDLIB/` for both `\bMEMOL_` and `\bML_(OK|SLOTS|KEYS|INITED|COUNT|E_*)` returned **no matches** — neither prefix collides. The gospel body uses `ML_`; this spec **renames to `MEMOL_`** to honor the dispatch and to avoid future namespace pressure from any sibling `ml_*`-prefixed module. (Trap 2: every module-scope `const`/`var` below is `MEMOL_`-prefixed so the emitted `L_MEMOL_*` linker globals are unique.)

| name | type | value |
|------|------|-------|
| `MEMOL_OK` | `i32` | `0i32` |
| `MEMOL_E_NULL` | `i32` | `-1i32` |
| `MEMOL_E_ABSENT` | `i32` | `-2i32` |
| `MEMOL_E_STALE` | `i32` | `-3i32` |
| `MEMOL_E_DUPLICATE` | `i32` | `-4i32` |
| `MEMOL_E_FULL` | `i32` | `-5i32` |
| `MEMOL_E_CLAUSE_ABSENT` | `i32` | `-6i32` |
| `MEMOL_E_VERIFY_FAIL` | `i32` | `-7i32` |
| `MEMOL_E_NOT_INITED` | `i32` | `-8i32` |
| `MEMOL_SLOTS` | `u64` | `65536u64` |
| `MEMOL_SLOT_MASK` | `u64` | `0xFFFFu64` |
| `MEMOL_KEY_BYTES` | `u64` | `32u64` |
| `MEMOL_K_FULL` | `u8` | `100u8` |
| `MEMOL_K_STALE` | `u8` | `0u8` |
| `MEMOL_EVT_RECORD` | `u8` | `0x0Du8` |
| `MEMOL_EVT_HIT` | `u8` | `0x0Eu8` |
| `MEMOL_EVT_STALE` | `u8` | `0x0Fu8` |
| `MEMOL_EVT_REVAL` | `u8` | `0x17u8` |
| `MEMOL_PAYLOAD_TAG` | `u8` | `0xE3u8` |

`MEMOL_SLOT_MASK` is introduced (= `MEMOL_SLOTS - 1`, both literal) so the slot-wrap is an explicit power-of-two byte-mask (Trap 11 avoidance, never `% MEMOL_SLOTS`). `MEMOL_EVT_REVAL = 0x17u8` is a new sub-tag for the revalidation fragment that closes Gap #2. **Sub-tag collision audit:** the `0xE3`-prefixed witness-fragment sub-tag byte (`payload[1]`) is a tree-wide shared registry; a full grep of the gospel shows `0x03..0x16` already allocated (e.g. `0x0D/0x0E/0x0F` = this module's RECORD/HIT/STALE; `0x10` = branch_anchor M57 / cg_bisimulate M56; `0x11` = `cls_emit_overrun` M81; `0x12`=synthesis_witness, `0x13`=eq-sat, `0x14`=theorem_carrier, `0x15/0x16`=curry_howard). `0x17` is the first unallocated sub-tag — chosen to avoid the `0x11` collision with M81.

## Data Structures
All slot tables are statically sized at `MEMOL_SLOTS = 65536` (W8). **Bound justification:** the lattice is the R0 in-process memo cache; 65536 (2^16) live entries is the canonical capacity that lets the slot index be the low 16 bits of the key (`& 0xFFFFu64`) with open-addressed linear probing and a single power-of-two mask (no division). At 32 bytes/key × 3 ident tables + 3 status bytes/slot the footprint is `3·2 MiB + 3·64 KiB ≈ 6.19 MiB` of `.bss` — fixed, no allocation, no growth. Overflow returns `MEMOL_E_FULL` (M5: refusal, never silent eviction).

Trap 7 (no local `var` arrays): the candidate body declares scratch (`payload`, `producer`, `op`, `in_c`, `out_c`, `frag_id`, `admit_label`, `admit_clause`) as function-local arrays — **forbidden by iiis-0**. This spec hoists **all** of them to module scope with `MEMOL_`-prefixed names. The module is therefore **non-reentrant** (single-threaded R0 substrate — acceptable, matching `identifier.iii`'s `IDENT_PAIRBUF`/`IDENT_MSG` pattern; noted under Trap Exposure).

| name | type | size | purpose / bound |
|------|------|------|-----------------|
| `MEMOL_INITED` | `u8` | scalar | init guard |
| `MEMOL_COUNT` | `u64` | scalar | live+stale entry count |
| `MEMOL_KEYS` | `[u8; 2097152]` | 65536·32 | per-slot 32-byte key |
| `MEMOL_OUT_COMMITS` | `[u8; 2097152]` | 65536·32 | per-slot output commitment |
| `MEMOL_CHAIN_IDS` | `[u8; 2097152]` | 65536·32 | per-slot producing chain id |
| `MEMOL_LIVE` | `[u8; 65536]` | 65536 | slot occupancy flag (0/1) |
| `MEMOL_STALE` | `[u8; 65536]` | 65536 | slot stale flag (0/1) |
| `MEMOL_K_MEMO` | `[u8; 65536]` | 65536 | per-slot confidence 0..100 |
| `MEMOL_SCR_PAYLOAD` | `[u8; 72]` | 72 | witness-fragment payload scratch (max of 72/40) |
| `MEMOL_SCR_PRODUCER` | `[u8; 32]` | 32 | emit producer ident (zeroed) |
| `MEMOL_SCR_OP` | `[u8; 32]` | 32 | emit op ident (zeroed) |
| `MEMOL_SCR_INC` | `[u8; 32]` | 32 | emit input-commit ident |
| `MEMOL_SCR_OUTC` | `[u8; 32]` | 32 | emit output-commit ident |
| `MEMOL_SCR_FRAGID` | `[u8; 32]` | 32 | emit returned fragment id |
| `MEMOL_SCR_CLAUSE_LABEL` | `[u8; 13]` | 13 | ASCII `"cp_memo_admit"` bytes |
| `MEMOL_SCR_CLAUSE_ID` | `[u8; 32]` | 32 | ident of the admit clause |

W1/W3: every `address-of-static` (`&MEMOL_*[0u64]`) is taken **only inside this file**; no module-scope pointer escapes (the only pointers returned to callers are the caller's own out-params written by `ident_copy`).

## Dependencies (externs)
All `@abi(c-msvc-x64)`.

| extern fn | from | module NN | built? |
|-----------|------|-----------|--------|
| `ident_zero(out: *u8) -> i32` | `identifier.iii` | M01 | **BUILT** ✔ |
| `ident_eq(a: *u8, b: *u8) -> u8` | `identifier.iii` | M01 | **BUILT** ✔ |
| `ident_copy(src: *u8, dst: *u8) -> i32` | `identifier.iii` | M01 | **BUILT** ✔ |
| `ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32` | `identifier.iii` | M01 | **BUILT** ✔ |
| `ws_emit_fragment(producer: *u8, op: *u8, in_commit: *u8, out_commit: *u8, payload: *u8, payload_len: u64, out_fid: *u8) -> i32` | `witness_spine.iii` | M12 | **NOT YET BUILT** ✖ |
| `ws_verify_segment(chain_id: *u8) -> i32` | `witness_spine.iii` | M12 | **NOT YET BUILT** ✖ |
| `cons_find(clause_id: *u8) -> i32` | `constitution.iii` | M13 | **NOT YET BUILT** ✖ |

Verified extern signatures against built `identifier.iii` — all four match byte-for-byte (`ident_zero/eq/copy/from_bytes` lines 27/38/65/33). **Two not-yet-built providers** gate this module: `witness_spine.iii` (M12, Layer 3) and `constitution.iii` (M13, Layer 3). Both are earlier-layer than this Layer-4 module, so the wave scheduler must place them before M58.

Dependency-note reconciliation: the gospel prose NIH line claims a dependency on `content_addr.iii` and the dispatch flags `computation_graph.iii` (M56). **Neither is an extern of the candidate body** — keys arrive pre-computed (the caller content-addresses upstream), and bisimulation/branch logic lives in M56/M57, not here. They are conceptual neighbors, not link-time deps. **Net not-yet-built link deps = 2** (`witness_spine`, `constitution`).

**GOSPEL-DEFECT CHECK (keccak extern):** This module does **not** `extern keccak256_init/update/final from "keccak.iii"` — it never touches keccak directly; hashing is delegated to `ident_from_bytes` (which itself correctly uses `keccak256_oneshot`). Clean on the systemic `keccak.iii` mis-extern defect.

## Algorithm
Determinism (M2) / bit-identity (W5): every operation is integer-only, fixed-iteration over `MEMOL_SLOTS`, with no time/entropy/float input; identical lattice state + identical key → identical slot, identical status, identical emitted payload bytes. No ML (M3), no heuristic (M4): slot selection is exact open-addressing; eviction never happens (refuse-on-full, M5). No recursion (W15): every search is an explicit `while probe < MEMOL_SLOTS` counter loop with a sentinel flag.

**`ml_hash_slot(key)`** — Hand-rolled 16-bit prefix hash: `h = key[0] | (key[1] << 8)`, return `h & MEMOL_SLOT_MASK`. Because the key is itself a Keccak-256 content address (uniformly distributed), the low 16 bits are a sound bucket. Deterministic, branch-free.

**`ml_slot_find(key)`** — Linear probe from `start = ml_hash_slot(key)` for `probe` in `0..MEMOL_SLOTS`; slot `s = (start + probe) & MEMOL_SLOT_MASK`. Sentinel-flag loop (W14, no `break`): on a live slot whose key `ident_eq`s the target, record `found = s as i64` and set the sentinel; on the first **empty** slot, set the sentinel (empty terminates the probe run — open-addressing invariant). Returns slot index `i64` or `-1i64`. Compared via `== -1i64` only (Trap 3 / W11).

**`ml_slot_alloc(key)`** — Same probe walk; returns the first slot with `MEMOL_LIVE[s] == 0u8` as `i64`, else `-1i64`. (Note: alloc scans the whole table from `start`, so a full table correctly yields `-1i64` → `MEMOL_E_FULL`.)

**`ml_emit_event(tag, key, chain_id)`** — Extracted helper (closes the duplicated emit blocks; keeps each public fn under W13's 20-local limit). Zero `MEMOL_SCR_PAYLOAD[0..72]`; set `[0]=MEMOL_PAYLOAD_TAG (0xE3)`, `[1]=tag`; copy `key` into `[8..40]`; if `chain_id` non-null copy it into `[40..72]` (stale/reval events pass null → those bytes stay zero, payload_len 40). Zero `MEMOL_SCR_PRODUCER`/`MEMOL_SCR_OP`; `ident_copy(key → MEMOL_SCR_INC)`; for RECORD/HIT copy `out_commit`→`MEMOL_SCR_OUTC` else zero it. Call `ws_emit_fragment(&MEMOL_SCR_PRODUCER, &MEMOL_SCR_OP, &MEMOL_SCR_INC, &MEMOL_SCR_OUTC, &MEMOL_SCR_PAYLOAD, len, &MEMOL_SCR_FRAGID)` and return its status. The 7-param extern is called with all args by pointer; the helper itself takes **3 params** (W2) by hoisting `out_commit` selection into the table-write that precedes the call.

**`ml_init()`** — If `MEMOL_INITED == 1u8` return OK (idempotent, M5). Else zero `MEMOL_LIVE/STALE/K_MEMO[0..MEMOL_SLOTS]` in one counter loop, `MEMOL_COUNT = 0`, `MEMOL_INITED = 1`. (`MEMOL_KEYS` etc. need no zeroing — `MEMOL_LIVE` gates all reads.)

**`ml_admit(key, out_commit, chain_id)`** — (1) `MEMOL_INITED` guard → `E_NOT_INITED`. (2) Three null-pointer guards via `(p as u64) == 0u64` → `E_NULL`. (3) **Clause governance (M8/M12):** fill `MEMOL_SCR_CLAUSE_LABEL` with the 13 ASCII bytes of `"cp_memo_admit"`, `ident_from_bytes(label,13 → MEMOL_SCR_CLAUSE_ID)`, then `if cons_find(&MEMOL_SCR_CLAUSE_ID) != 0i32 { return E_CLAUSE_ABSENT }`. (4) **Chain verification (M17/W36):** `if ws_verify_segment(chain_id) != 0i32 { return E_VERIFY_FAIL }` — **admission is gated on a passing chain; an unverified result can never enter the lattice.** (5) Duplicate guard: `if ml_slot_find(key) != -1i64 { return E_DUPLICATE }`. (6) `slot = ml_slot_alloc(key)`; `if slot == -1i64 { return E_FULL }`. (7) Write the slot: `ident_copy` key/out_commit/chain_id into the three tables at `s*32`, set `LIVE=1, STALE=0, K_MEMO=MEMOL_K_FULL`, `MEMOL_COUNT += 1`. (8) `return ml_emit_event(MEMOL_EVT_RECORD, key, chain_id)` (witness continuity, M6/W16).

**`ml_lookup(key, out_commit, out_chain_id, out_k_memo)`** — (1) init guard; (2) four null guards (W2: exactly 4 params). (3) `slot = ml_slot_find(key)`; `if slot == -1i64 { return E_ABSENT }`. (4) `if MEMOL_STALE[s] == 1u8 { return E_STALE }` (W50: stale entries are never returned). (5) `ident_copy` the stored out_commit→`out_commit`, chain_id→`out_chain_id`; `*out_k_memo = MEMOL_K_MEMO[s]`. (6) `ml_emit_event(MEMOL_EVT_HIT, key, &MEMOL_CHAIN_IDS[s*32])`. (7) `return MEMOL_OK`. **M17/W36 CONTRACT (load-bearing):** the returned `(out_commit, out_chain_id)` is **UNVERIFIED**. `MEMOL_OK` means "found and not stale", *not* "trusted". The caller MUST call `ws_verify_segment(out_chain_id)` (or `cg_walk_segment` replay) and obtain `OK` before consuming `out_commit`. The lattice deliberately does not verify on the hot lookup path (that would be a per-read replay cost, violating M19's cost-bound intent); the verification obligation is the consumer's, enforced by contract and by the HIT witness fragment that records the lookup.

**`ml_mark_stale(key)`** — init+null guards; `slot = ml_slot_find(key)`; absent → `E_ABSENT`; set `MEMOL_STALE[s]=1`, `MEMOL_K_MEMO[s]=MEMOL_K_STALE`; `return ml_emit_event(MEMOL_EVT_STALE, key, 0 as *u8)`. The entry stays resident for forensics (M6) but is invisible to `ml_lookup`. Reversible (M9): `ml_revalidate` is the inverse.

**`ml_revalidate(key)`** — init+null guards; `slot = ml_slot_find(key)`; absent → `E_ABSENT`; **replay the producing chain:** `if ws_verify_segment(&MEMOL_CHAIN_IDS[s*32]) != 0i32 { return E_VERIFY_FAIL }` (W50: no un-stale without revalidation). On pass: `MEMOL_STALE[s]=0`, `MEMOL_K_MEMO[s]=MEMOL_K_FULL`, then **emit a REVAL fragment** `ml_emit_event(MEMOL_EVT_REVAL, key, &MEMOL_CHAIN_IDS[s*32])` and return its status (Gap #2 fix — restores witness symmetry with `mark_stale`).

**`ml_size()`** — `return MEMOL_COUNT` (live+stale; documented).

## KAT Vectors (>= 3)
A self-test (`ml_kat()`-style, gated behind the standard test harness) drives a deterministic key set. Let `K0 = 32 bytes 0x00..0x1F`, `K1 = 32 bytes all 0xAA`, `C0/C1` distinct commitments, `CH0/CH1` chain ids. The harness installs a stub `ws_verify_segment` returning `0` for `CH0/CH1` and a stub `cons_find` returning `0` for the `cp_memo_admit` clause.

1. **Empty-lattice absence.** `ml_init(); ml_lookup(K0, …)` → returns **`MEMOL_E_ABSENT` (-2i32)**; `ml_size()` → **`0u64`**. (Verifies the empty-slot probe terminator and that no slot reads occur before init writes.)
2. **Admit then hit, K_memo=100.** `ml_admit(K0, C0, CH0)` → **`MEMOL_OK`**; `ml_lookup(K0, &oc, &och, &km)` → **`MEMOL_OK`** with `oc == C0` (32 bytes), `och == CH0` (32 bytes), `km == 100u8`; `ml_size()` → **`1u64`**. Re-admit `ml_admit(K0, C0, CH0)` → **`MEMOL_E_DUPLICATE` (-4i32)**.
3. **Stale then revalidate.** After KAT 2: `ml_mark_stale(K0)` → **`MEMOL_OK`**; `ml_lookup(K0, …)` → **`MEMOL_E_STALE` (-3i32)** with `K_memo` slot now `0`; `ml_revalidate(K0)` → **`MEMOL_OK`**; subsequent `ml_lookup(K0, …)` → **`MEMOL_OK`** with `km == 100u8`. (Verifies W50 stale-invisibility and reversibility.)
4. **Negative gate — verify-fail blocks admission (proves the M17 guard FIRES).** With the stub `ws_verify_segment` forced to return `-1i32` for `CH1`: `ml_admit(K1, C1, CH1)` → **`MEMOL_E_VERIFY_FAIL` (-7i32)**, and `ml_lookup(K1, …)` → **`MEMOL_E_ABSENT`** (nothing was inserted). (Proves the chain-verification gate is not a no-op — an unverifiable result is refused, satisfying "prove the negative case".)
5. **Negative gate — clause-absent blocks admission.** With stub `cons_find` returning `-1i32` for the `cp_memo_admit` clause: `ml_admit(K0, C0, CH0)` → **`MEMOL_E_CLAUSE_ABSENT` (-6i32)**; `ml_size()` unchanged. (Proves M8 capability/clause governance gate fires.)
6. **Null-arg guards.** `ml_admit(0 as *u8, C0, CH0)` → **`MEMOL_E_NULL` (-1i32)**; `ml_lookup(K0, 0 as *u8, &och, &km)` → **`MEMOL_E_NULL`**.

## Trap Exposure
| # | Trap | Exposed? | Avoidance |
|---|------|----------|-----------|
| 1 | Multi-line `fn` decl | Yes (all 10 fns) | Every signature is single-line in the skeleton; reviewer greps `^fn .*[^){]$` to confirm none wrap. |
| 2 | `const` linker-global | Yes (19 consts) | All `MEMOL_`-prefixed; grep confirmed no `MEMOL_`/`ML_` collision in `STDLIB/`. Renamed from gospel's `ML_` to dispatched `MEMOL_`. |
| 3 | Signed-order SIGSEGV | Yes (`i64` slot sentinels) | **Only** `== -1i64` / `!= -1i64` used; the candidate body already complies — no `< / <= / > / >=` on `i64`/`i32` anywhere. Status codes compared `!= 0i32` / `== 0i32` only. |
| 4 | u32-in-u64-slot | No | No `u32` local is widened to `u64` for pointer math. Slot index `s = slot as u64` originates from an `i64`; `s * 32u64` is pure `u64`. |
| 5 | u32 pointer-store width | No | No `*u32` stores; all byte writes are through `*u8` (`payload[i] = …`, `ident_copy`). `*out_k_memo = …` is a single `u8` store. |
| 6 | Nested `/* */` | No | Header uses one block comment with no nesting; inline notes use `//` or `(...)`. |
| 7 | Local `var` arrays | **YES — primary defect** | Candidate declares `payload/producer/op/in_c/out_c/frag_id/admit_label/admit_clause` as function-local arrays (unsupported). **Fix:** all hoisted to module scope as `MEMOL_SCR_*` (see Data Structures). Renders the module non-reentrant — acceptable for the single-threaded R0 substrate (mirrors `identifier.iii`). |
| 8 | `} else {` one line | Yes (`ml_slot_find` has an `else`) | The single `else` (empty-slot terminator) is written `} else {` on one line in the skeleton. |
| 9 | Em-dash in comment | No | All comments use ASCII `--`; spec/skeleton contain no U+2014. |
| 10 | `let mut`=flag | Minor | The `sentinel : u8` probe flags are loop-exit gates, not checkpoint flags, and drive the `if sentinel == 0u8` guard directly (the safe shape). `ml_init`'s `MEMOL_INITED` is module-scope, not a local `let mut` flag. |
| 11 | `%` after call | No | Slot wrap is `& MEMOL_SLOT_MASK` (power-of-two byte-mask), never `% MEMOL_SLOTS`. No modulo anywhere. |
| 12 | `@specialize *T` stride | No | Not generic; no `@specialize`. All arrays are concrete `[u8; N]`/`[u64; N]` with explicit `*32u64` byte strides. |

## Gap / Fix List
The candidate is PARTIAL. Gaps, each with its fix:

1. **Trap 7 — local `var`/`let mut` arrays (BLOCKER).** Every emit block declares `payload`, `producer`, `op`, `in_c`, `out_c`, `frag_id` locally; `ml_admit` adds `admit_label[13]`, `admit_clause[32]`. iiis-0 parses `var [u8; N]` only at module scope → these will fail to compile (or mis-codegen). **Fix:** hoist all to the `MEMOL_SCR_*` module-scope buffers listed in Data Structures; document non-reentrancy.

2. **Witness-continuity asymmetry — `ml_revalidate` emits no fragment (M6/W16/W17).** `ml_mark_stale` emits `MEMO_STALE_MARK` but `ml_revalidate` mutates `STALE`/`K_MEMO` and returns OK **without** a fragment, breaking the chained-state-transition invariant (every state change witnesses). **Fix:** add `MEMOL_EVT_REVAL = 0x17u8` (the first free `0xE3`-prefixed sub-tag — `0x11` is taken by M81 `cls_emit_overrun`; full sub-tag audit in Constant Namespace) and emit a `MEMO_REVALIDATE` fragment on success (see Algorithm); return its status.

3. **M17/W36 lookup contract under-specified (DESIGN-CRITICAL).** The gospel prose says consumers verify, but `ml_lookup` returns `MEMOL_OK` for a found entry with no in-band signal that the result is unverified — a careless caller could consume `out_commit` without calling `ws_verify_segment`. **Fix:** make the contract explicit in the module doc-comment and this spec: **`MEMOL_OK` from `ml_lookup` = "present, not stale", NOT "trusted"; the caller MUST `ws_verify_segment(out_chain_id) == OK` before use.** The returned `out_chain_id` exists precisely to make this mandatory; the HIT fragment records the obligation. (No signature change — the chain_id out-param is the enforcement handle.)

4. **`ml_admit` return-value conflation (minor).** The candidate returns `ws_emit_fragment(...)` directly as `ml_admit`'s result; if emit returns a non-zero witness status the caller sees it as an admit failure **after** the entry is already inserted and counted — a torn state. **Fix:** the emit is the final step after a fully-consistent slot write; on a non-OK emit, the spec mandates the implementation treat emit failure as fatal-to-the-transition by emitting *before* incrementing `MEMOL_COUNT` is **not** possible (fragment needs the committed entry), so instead: keep emit last, but on emit-failure the entry+witness are inconsistent → the implementation must surface the emit status verbatim (it is already negative-`i32` per W9) and a higher layer (memo_query/compactor) treats a `< 0` admit as "entry present but unwitnessed → mark stale". Documented as the contract; no silent `MEMOL_OK` masking of an emit error.

5. **PREFIX mismatch (mechanical).** Gospel uses `ML_`; dispatch assigns `MEMOL_`. **Fix:** rename all consts/vars/internal-symbol references to `MEMOL_` (done throughout this spec). Public `fn ml_*` names are **kept** (the dispatch governs the *const* PREFIX, and `ml_*` matches the gospel's documented public API and the `cp_memo_admit`/`memo_query` ecosystem; renaming the exported fns would break M69 `memo_query.iii` and M79 callers).

6. **Vestigial prose dependency on `content_addr.iii` / M56.** The header NIH line lists `content_addr.iii`; the body never externs it (keys arrive pre-addressed). **Fix:** spec records it as a *conceptual* upstream (the caller content-addresses), not a link dep; **0 added not-yet-built link deps from this.** Net link deps stay at 2 (`witness_spine`, `constitution`).

7. **`ml_init` does not re-zero `MEMOL_STALE` correctness check (verified, not a gap).** Confirmed `ml_init` zeros `LIVE`/`STALE`/`K_MEMO`; since `LIVE` gates every read, residual `KEYS`/`OUT_COMMITS`/`CHAIN_IDS` bytes are unreachable — correct, no fix needed.

8. **Helper extraction for W13 headroom (refactor, not a defect).** Inlined emit blocks push `ml_admit` toward ~12 locals (within the 20 limit, but tight once buffers are hoisted). **Fix:** extract `ml_emit_event(tag, key, chain_id)` (3 params, W2) — reduces every emitting fn's local count and removes 3× code duplication. Behavior-preserving.

## Implementation Skeleton
```iii
/* III/STDLIB/iii/numera/memo_lattice.iii
 *
 * III STDLIB - numera::memo_lattice  (Layer 4, Module 58)
 *
 * Content-addressed cache of past computations. Keys are 32-byte
 * content addresses (computed upstream by content_addr.iii). Values
 * are (output_commitment, chain_id) pairs with a per-entry K_memo
 * confidence (u8 0..100).
 *
 * Hexad: kind_essence + kind_cognition.  Ring: R0.  K: 1.00.
 *
 * NIH: depends on identifier.iii (built), witness_spine.iii (M12),
 *      constitution.iii (M13). Keys are content-addressed by the
 *      caller; this module never hashes.
 *
 * M17 / W36 / W50 DISCIPLINE (load-bearing):
 *   - Admission verifies the producing chain (ws_verify_segment) BEFORE
 *     insertion -- an unverifiable result NEVER enters the lattice.
 *   - ml_lookup returning MEMOL_OK means "present, not stale", NOT
 *     "trusted": the caller MUST call ws_verify_segment(out_chain_id)
 *     and get OK before consuming out_commit. The lattice never
 *     propagates an unverified result.
 *   - A stale entry is invisible to lookup; ml_revalidate replays the
 *     chain before clearing the stale mark (no un-stale without reval).
 *
 * Non-reentrant: MEMOL_SCR_* scratch buffers are module-scope (Trap 7);
 * single-threaded R0 use only.
 */

module numera_memo_lattice

extern @abi(c-msvc-x64) fn ident_zero(out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ws_emit_fragment(producer: *u8, op: *u8, in_commit: *u8, out_commit: *u8, payload: *u8, payload_len: u64, out_fid: *u8) -> i32 from "witness_spine.iii"
extern @abi(c-msvc-x64) fn ws_verify_segment(chain_id: *u8) -> i32 from "witness_spine.iii"
extern @abi(c-msvc-x64) fn cons_find(clause_id: *u8) -> i32 from "constitution.iii"

const MEMOL_OK              : i32 =  0i32
const MEMOL_E_NULL          : i32 = -1i32
const MEMOL_E_ABSENT        : i32 = -2i32
const MEMOL_E_STALE         : i32 = -3i32
const MEMOL_E_DUPLICATE     : i32 = -4i32
const MEMOL_E_FULL          : i32 = -5i32
const MEMOL_E_CLAUSE_ABSENT : i32 = -6i32
const MEMOL_E_VERIFY_FAIL   : i32 = -7i32
const MEMOL_E_NOT_INITED    : i32 = -8i32

const MEMOL_SLOTS           : u64 = 65536u64
const MEMOL_SLOT_MASK       : u64 = 0xFFFFu64
const MEMOL_KEY_BYTES       : u64 = 32u64
const MEMOL_K_FULL          : u8  = 100u8
const MEMOL_K_STALE         : u8  = 0u8
const MEMOL_PAYLOAD_TAG     : u8  = 0xE3u8
const MEMOL_EVT_RECORD      : u8  = 0x0Du8
const MEMOL_EVT_HIT         : u8  = 0x0Eu8
const MEMOL_EVT_STALE       : u8  = 0x0Fu8
const MEMOL_EVT_REVAL       : u8  = 0x17u8

var MEMOL_INITED            : u8  = 0u8
var MEMOL_COUNT             : u64 = 0u64

var MEMOL_KEYS              : [u8; 2097152]   /* 65536 * 32 */
var MEMOL_OUT_COMMITS       : [u8; 2097152]
var MEMOL_CHAIN_IDS         : [u8; 2097152]
var MEMOL_LIVE              : [u8; 65536]
var MEMOL_STALE             : [u8; 65536]
var MEMOL_K_MEMO            : [u8; 65536]

var MEMOL_SCR_PAYLOAD       : [u8; 72]
var MEMOL_SCR_PRODUCER      : [u8; 32]
var MEMOL_SCR_OP            : [u8; 32]
var MEMOL_SCR_INC           : [u8; 32]
var MEMOL_SCR_OUTC          : [u8; 32]
var MEMOL_SCR_FRAGID        : [u8; 32]
var MEMOL_SCR_CLAUSE_LABEL  : [u8; 13]
var MEMOL_SCR_CLAUSE_ID     : [u8; 32]

fn ml_hash_slot(key: *u8) -> u64 {
    // TODO: body per Algorithm: h = key[0] | (key[1]<<8); return h & MEMOL_SLOT_MASK
}

fn ml_slot_find(key: *u8) -> i64 {
    // TODO: body per Algorithm: linear-probe find; sentinel-flag loop, no break; `} else {` one line; returns slot or -1i64
}

fn ml_slot_alloc(key: *u8) -> i64 {
    // TODO: body per Algorithm: linear-probe first-free; returns slot or -1i64
}

fn ml_emit_event(tag: u8, key: *u8, chain_id: *u8) -> i32 {
    // TODO: body per Algorithm: fill MEMOL_SCR_PAYLOAD (tag, key@8, chain_id@40 if non-null), zero/copy MEMOL_SCR_* idents, return ws_emit_fragment(...)
}

fn ml_init() -> i32 @export {
    // TODO: body per Algorithm: idempotent; zero LIVE/STALE/K_MEMO over MEMOL_SLOTS; COUNT=0; INITED=1
}

fn ml_admit(key: *u8, out_commit: *u8, chain_id: *u8) -> i32 @export {
    // TODO: body per Algorithm: init+3 null guards; clause-find (cp_memo_admit); ws_verify_segment gate; dup check; alloc; write slot; COUNT++; ml_emit_event(MEMOL_EVT_RECORD,...)
}

fn ml_lookup(key: *u8, out_commit: *u8, out_chain_id: *u8, out_k_memo: *u8) -> i32 @export {
    // TODO: body per Algorithm: init+4 null guards; find; STALE->E_STALE; copy out_commit/out_chain_id; *out_k_memo; ml_emit_event(MEMOL_EVT_HIT,...); return OK (UNVERIFIED -- caller must ws_verify_segment)
}

fn ml_mark_stale(key: *u8) -> i32 @export {
    // TODO: body per Algorithm: init+null guards; find; STALE=1; K_MEMO=MEMOL_K_STALE; ml_emit_event(MEMOL_EVT_STALE, key, 0 as *u8)
}

fn ml_revalidate(key: *u8) -> i32 @export {
    // TODO: body per Algorithm: init+null guards; find; ws_verify_segment(&MEMOL_CHAIN_IDS[s*32]) gate; STALE=0; K_MEMO=MEMOL_K_FULL; ml_emit_event(MEMOL_EVT_REVAL,...)
}

fn ml_size() -> u64 @export {
    // TODO: body per Algorithm: return MEMOL_COUNT
}
```
