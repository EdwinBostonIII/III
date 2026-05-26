# 79 aether/memo_compactor_coordination.iii — Implementation Spec

## Verdict
**STUB** — the gospel candidate body is a non-functional shell. `mcc_on_compaction` performs its two guards (init, null) and then *returns `MCC_OK` without doing anything*: the entire mandate — "iterate the memo lattice, find entries whose `chain_id` matches the retired chain, and invoke `ml_mark_stale` on each" — exists only as a `/* ... */` comment. It never calls `ml_mark_stale`, never enumerates anything, takes **no capability argument** (M8 violation), and **emits no witness fragment** for the coordination transition (M6/M17/W16 violation). The single declared extern (`ml_mark_stale`) is correct in name and signature but is **insufficient**: the realized memo_lattice (M58) exposes **no enumeration / chain-id accessor surface**, so the gospel's stated algorithm is *unimplementable* against the published M58 API. This spec realizes the maximal intent: a deterministic full-table coordination pass, capability-gated, witnessed by a coordination-summary fragment, driven by a minimal read-only accessor set that M58 must add in Phase 2 (the §3.5-defect-#6 "needed getters" pattern).

## Purpose
`memo_compactor_coordination` **IS** the deterministic bridge between witness compaction and the memoization lattice (M17 memoization sovereignty). When the witness compactor retires a chain segment, every memo entry whose *producing* chain segment was that segment becomes un-revalidatable from live witness data and MUST be marked stale (gospel L401, W50). This module embodies that coordination: on each retirement it enumerates the lattice exactly once, marks every dependent entry stale through the lattice's own reversible `ml_mark_stale` primitive, and emits one chained witness fragment recording the pass. It owns the *coordination decision*; the lattice owns the *storage*. **Hexad: `kind_repair + kind_motion`. Ring: R0. K-vector: 1.00.**

## Public API
All public fns return a negative-`i32` status (W9/W12), compared `==`/`!=` only (W11), or a sentinel-typed scalar (W12).

```
fn mcc_init() -> i32 @export
fn mcc_on_compaction(retired_chain_id: *u8, cap: u64) -> i32 @export
fn mcc_last_marked_count() -> u64 @export
```

Internal (non-`@export`) helper:

```
fn mcc_emit_pass(retired_chain_id: *u8, n_marked: u64) -> i32
```

Return-status convention per fn:
- `mcc_init` → `MCC_OK` (idempotent; never fails).
- `mcc_on_compaction` → `MCC_OK` | `MCC_E_NOT_INITED` | `MCC_E_NULL` | `MCC_E_DENIED` (capability gate failed) | `MCC_E_LATTICE` (a downstream `ml_*` accessor or `ml_mark_stale` returned a non-OK status; the pass surfaces it verbatim-classified — see Algorithm) | `MCC_E_WITNESS` (the coordination-summary `wh_publish` failed). On `MCC_OK` the pass completed and `mcc_last_marked_count()` holds the number of entries marked this pass (`0` is legitimate — no entry depended on the retired chain).
- `mcc_last_marked_count` → `u64` count of entries marked stale by the **most recent** `mcc_on_compaction` call (`0u64` before any call; W12 sentinel-typed scalar where `0` is a valid value). Pure read of module state; no side effect.

**API-shape change vs. gospel (load-bearing, M8):** the gospel's `mcc_on_compaction(retired_chain_id)` is widened to `mcc_on_compaction(retired_chain_id: *u8, cap: u64)`. Marking memo entries stale is a privileged amendment of substrate state; per M8 it requires an explicit capability argument carrying `CAP_RIGHT_AMEND`. 2 params — W2-clean. `mcc_last_marked_count` is added so the pass result is in-band checkable (KAT byte-assertable) without parsing the witness payload.

## Constant Namespace
**PREFIX = `MCC_`** (dispatched). Grep of `STDLIB/` for `\bMCC_` returned **no matches** — no collision. Every module-level `const`/`var` below is `MCC_`-prefixed so each emitted `L_MCC_*` linker global is unique (Trap 2).

| name | type | value | role |
|------|------|-------|------|
| `MCC_OK`            | `i32` | `0i32`  | success |
| `MCC_E_NULL`        | `i32` | `-1i32` | null `retired_chain_id` |
| `MCC_E_NOT_INITED`  | `i32` | `-2i32` | called before `mcc_init` |
| `MCC_E_DENIED`      | `i32` | `-3i32` | capability lacks `CAP_RIGHT_AMEND` |
| `MCC_E_LATTICE`     | `i32` | `-4i32` | a downstream `ml_*` call failed |
| `MCC_E_WITNESS`     | `i32` | `-5i32` | coordination-summary `wh_publish` failed |
| `MCC_SLOTS`         | `u64` | `65536u64` | lattice table size mirror (= `MEMOL_SLOTS`); scan bound |
| `MCC_KEY_BYTES`     | `u64` | `32u64` | content-address key width |
| `MCC_CAP_AMEND`     | `u64` | `0x4000u64` | required right (mirror of `CAP_RIGHT_AMEND`) |
| `MCC_PAYLOAD_TAG`   | `u8`  | `0xE3u8` | witness-fragment outer tag (tree-wide convention) |
| `MCC_EVT_COORD`     | `u8`  | `0x18u8` | sub-tag: MEMO_COMPACTION_COORD (see audit below) |
| `MCC_PAYLOAD_LEN`   | `u64` | `48u64` | summary payload byte length (tag+sub+chain_id+count) |

**Sub-tag `0x18` audit (authoritative gospel registry, L529–540):** the `0xE3`-prefixed witness sub-tag byte (`payload[1]`) is a tree-wide registry. The gospel allocates `0x03..0x17` (`0x0D/0x0E/0x0F` = MEMO_RECORD/MEMO_HIT/MEMO_STALE_MARK; `0x17` = **DUAL_READING_COMPLETE**), and explicitly states **`0x18` through `0xFE` are "reserved for V3 capability additions."** This module's coordination-summary fragment is a V3 addition → **`0x18` is the correct, registry-sanctioned choice** (named MEMO_COMPACTION_COORD here). Grep confirmed no other module uses `0x18` as a witness sub-tag (the `0x18u8` byte literals in `xii_curated_*`/`fe25519.iii` are machine-code/field bytes, not witness tags). **Cross-file note (not this module's defect):** the M58 spec assigns `MEMOL_EVT_REVAL = 0x17u8` claiming `0x17` "first unallocated" — that **collides** with `0x17 DUAL_READING_COMPLETE`. Flagged for the M58 implementer; out of scope here. The per-entry stale fragments emitted *inside* `ml_mark_stale` use `0x0F MEMO_STALE_MARK` (M58-owned, correct).

`MCC_CAP_AMEND`/`MCC_SLOTS`/`MCC_PAYLOAD_TAG` are **value mirrors** of constants owned by other modules (`CAP_RIGHT_AMEND=0x4000`, `MEMOL_SLOTS=65536`, the `0xE3` tag). They are duplicated as local consts (not imported) because module-level `const` is linker-global (Trap 2) — importing another module's const symbol is neither possible nor desirable; the mirror is the house pattern (cf. `fed_admit`'s local tier constants). Each mirror is annotated in-source with its source-of-truth so a future divergence is auditable.

## Data Structures
All module-scope (W6/W7 explicit lifecycle; W8 fixed sizes). No local `var` arrays (Trap 7).

| name | type | size | purpose / bound |
|------|------|------|-----------------|
| `MCC_INITED`        | `u8`        | scalar | init guard (0/1) |
| `MCC_LAST_COUNT`    | `u64`       | scalar | entries marked stale by the most recent pass |
| `MCC_SCR_KEY`       | `[u8; 32]`  | 32 | scratch for the per-match content-address key copied out of the lattice via `ml_slot_key`, then passed to `ml_mark_stale` |
| `MCC_SCR_PAYLOAD`   | `[u8; 48]`  | 48 | coordination-summary witness payload (`[0]=0xE3`, `[1]=0x18`, `[8..40]=retired_chain_id`, `[40..48]=n_marked LE u64`) |
| `MCC_SCR_PRODUCER`  | `[u8; 32]`  | 32 | `wh_publish` producer ident (zeroed = system producer) |
| `MCC_SCR_OPID`      | `[u8; 32]`  | 32 | `wh_publish` opid ident (zeroed) |
| `MCC_SCR_INC`       | `[u8; 32]`  | 32 | `wh_publish` in_commit = retired_chain_id (the antecedent being retired) |
| `MCC_SCR_OUTC`      | `[u8; 32]`  | 32 | `wh_publish` out_commit (zeroed; the pass has no single output commitment) |
| `MCC_SCR_FRAGID`    | `[u8; 32]`  | 32 | sink for the returned coordination fragment id |

**Bound justification (W8):** the only loop bound is `MCC_SLOTS = 65536`, identical to the lattice's static slot count — the scan visits every slot exactly once, so the bound is exact, not heuristic. All scratch buffers are fixed 32/48-byte regions. Total `.bss` footprint ≈ `48 + 6·32 + 16 ≈ 256` bytes — trivial, no allocation, no growth.

**Reentrancy:** the `MCC_SCR_*` scratch buffers are module-scope (Trap 7 forces this) → the module is **non-reentrant**. Acceptable: this is the single-threaded R0 substrate and `mcc_on_compaction` is invoked serially by the witness compactor (mirrors `witness_hook.iii` `WH_TMP16`/`WH_OUT_TMP` and `memo_lattice` `MEMOL_SCR_*` patterns). Noted under Trap Exposure.

W1/W3: every `&MCC_*` address-of-static is taken **only inside this file**; no module-scope pointer escapes. The only pointers handed to callees are these local scratch buffers and the caller's own `retired_chain_id`.

## Dependencies (externs)
All `@abi(c-msvc-x64)`.

| extern fn | from | module NN | built? |
|-----------|------|-----------|--------|
| `ml_mark_stale(key: *u8) -> i32` | `memo_lattice.iii` | **M58** | **NOT YET BUILT** ✖ |
| `ml_slot_count() -> u64` | `memo_lattice.iii` | **M58** | **NOT YET BUILT — NEW ACCESSOR (Phase 2 add to M58)** ✖ |
| `ml_slot_is_live(slot: u64) -> u8` | `memo_lattice.iii` | **M58** | **NOT YET BUILT — NEW ACCESSOR** ✖ |
| `ml_slot_chain_eq(slot: u64, chain_id: *u8) -> u8` | `memo_lattice.iii` | **M58** | **NOT YET BUILT — NEW ACCESSOR** ✖ |
| `ml_slot_key(slot: u64, out_key: *u8) -> i32` | `memo_lattice.iii` | **M58** | **NOT YET BUILT — NEW ACCESSOR** ✖ |
| `cap_verify_rights(id: u64, required: u64) -> u8` | `capability.iii` | M(cap) | **BUILT** ✔ |
| `wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64` | `aether/witness_hook.iii` | M07 | **BUILT** ✔ |

**Verified extern signatures against the real provider files:**
- `cap_verify_rights(id: u64, required: u64) -> u8` — verified byte-for-byte against built `aether/capability.iii:148`. (§3.5 defect #5: the gospel's `cap_verify` is fiction; the real symbol is `cap_verify_rights` with a `u64` rights mask. `CAP_RIGHT_AMEND = 0x4000u64` is the real bit, `capability.iii:66`.)
- `wh_publish(...) -> u64` — verified byte-for-byte against built `aether/witness_hook.iii:144`. Returns the fragment **index** on success, or `0xFFFFFFFFFFFFFFFFu64` on failure. (§3.5 defect #2: the gospel's `ws_emit_fragment from "witness_spine.iii"` is fiction; `wh_publish` is the real, built emit primitive. This spec routes fragment emission through it.)
- `ml_mark_stale(key: *u8) -> i32` — matches the M58 spec public API (`memo_lattice.spec.md:16`). Status `0i32` = OK; negatives are M58 errors, compared `==`/`!=` only.

**NOT-YET-BUILT link deps = 1 provider (`memo_lattice.iii`, M58), contributing 5 externs (1 existing + 4 new accessors).** `capability.iii` and `witness_hook.iii` are BUILT. M58 is a Layer-4 module; this is Layer-9 → the wave scheduler already orders M58 before M79. The 4 new accessors are *additions to M58's surface* (no behavior change to M58's existing fns) and are listed below for the M58 implementer.

**Four new M58 accessors this module requires (Phase-2 addition to `memo_lattice.iii`) — the §3.5-defect-#6 "needed getters" pattern.** They are pure, read-only, W1-clean (no address-of-M58-static escapes; `ml_slot_key` copies into the *caller's* buffer, `ml_slot_chain_eq` compares the *caller's* chain_id against M58's internal array and returns only a `u8`):

```
fn ml_slot_count() -> u64 @export
    // returns MEMOL_SLOTS (65536u64); lets the coordinator bound its scan without
    // hard-coding the lattice geometry. Pure constant read.

fn ml_slot_is_live(slot: u64) -> u8 @export
    // 1u8 if slot < MEMOL_SLOTS && MEMOL_LIVE[slot]==1u8, else 0u8. Bounds-checked.

fn ml_slot_chain_eq(slot: u64, chain_id: *u8) -> u8 @export
    // 1u8 if slot is live AND ident_eq(&MEMOL_CHAIN_IDS[slot*32], chain_id)==1u8,
    // else 0u8. (null chain_id or out-of-range slot -> 0u8.) No pointer escapes M58.

fn ml_slot_key(slot: u64, out_key: *u8) -> i32 @export
    // if slot live: ident_copy(&MEMOL_KEYS[slot*32], out_key); return MEMOL_OK.
    // else return MEMOL_E_ABSENT. Copies INTO the caller's buffer (W1 clean).
```

Rationale for accessors over a single `ml_mark_stale_by_chain(chain_id)`: this module's ontology is **coordination** (kind_repair + kind_motion) — it must *own* the enumerate-decide-mark loop and witness the pass as a unit. Folding the scan into M58 would reduce M79 to a one-line passthrough (the very stub being replaced) and would split the witness boundary (M58 would emit per-entry `0x0F` fragments with no over-arching `0x18` coordination record). The accessor set keeps M58 a pure store while letting M79 be the coordinator. (Alternative recorded under Gap/Fix #6.)

**GOSPEL-DEFECT CHECK (keccak):** this module does **not** extern any `keccak256_*`/`keccak.iii` symbol — it never hashes directly; the only hashing is inside `wh_publish` (which correctly uses `keccak256.iii`). Clean on the systemic keccak mis-extern defect.

## Algorithm
Determinism (M2)/bit-identity (W5): every step is integer-only over a fixed `0..MCC_SLOTS` counter range with no time/entropy/float input. Identical lattice state + identical `retired_chain_id` → identical matched-slot set, visited in identical ascending-slot order → identical sequence of `ml_mark_stale(key)` calls → identical `MCC_LAST_COUNT` → identical coordination payload bytes → identical fragment id. No ML (M3): the match test is exact 32-byte identity (`ml_slot_chain_eq`), never a count/threshold/score. No heuristic (M4): every live slot is tested; none skipped. No recursion (W15): the scan is one explicit counter `while` loop with a sentinel continuation flag (W14, no `break`). Cost is bounded (M19): exactly `MCC_SLOTS` iterations, each O(1) plus at most one O(32) compare and one O(1) mark.

**`mcc_init()`** — If `MCC_INITED == 1u8` return `MCC_OK` (idempotent, M5). Else `MCC_LAST_COUNT = 0u64`, `MCC_INITED = 1u8`, return `MCC_OK`. (Init never touches the lattice — M58 has its own `ml_init`; the wave/boot orchestrator initializes both.)

**`mcc_on_compaction(retired_chain_id, cap)`** —
1. **Init guard:** `if MCC_INITED == 0u8 { return MCC_E_NOT_INITED }`.
2. **Null guard:** `if (retired_chain_id as u64) == 0u64 { return MCC_E_NULL }` (full 64-bit *equality* test — never an ordering compare; Trap 3 safe).
3. **Capability gate (M8):** `if cap_verify_rights(cap, MCC_CAP_AMEND) != 1u8 { return MCC_E_DENIED }` — a caller without `CAP_RIGHT_AMEND` cannot drive the marking pass. The gate fires **before** any lattice mutation (no partial pass on a denied cap).
4. **Bound:** `let n_slots : u64 = ml_slot_count()` (= 65536). Defensive: the loop also caps at `MCC_SLOTS` so a divergent provider value cannot unbound the scan.
5. **Scan (W14 sentinel-counter loop, no break, W15 no recursion):**
   - `let mut s : u64 = 0u64`, `let mut marked : u64 = 0u64`, `let mut err : i32 = MCC_OK`, `let mut going : u8 = 1u8`.
   - `while going == 1u8 {` … `}` where the body:
     - `if s >= n_slots { going = 0u8 }` (terminator — also `s >= MCC_SLOTS` guard).
     - `} else {` (one line, Trap 8) inside the still-going branch:
       - `if ml_slot_is_live(s) == 1u8 {` and within it `if ml_slot_chain_eq(s, retired_chain_id) == 1u8 {`:
         - `let krc : i32 = ml_slot_key(s, &MCC_SCR_KEY[0])` ; `if krc != MCC_OK { err = MCC_E_LATTICE; going = 0u8 }` (W11 equality compare).
         - else `let mrc : i32 = ml_mark_stale(&MCC_SCR_KEY[0])` ; `if mrc != MCC_OK { err = MCC_E_LATTICE; going = 0u8 } else { marked = marked + 1u64 }`.
       - `s = s + 1u64` (advance only while going; on the terminator branch `s` is not advanced, harmless).
   - The flag `going` drives the `while` condition directly (Trap 10 safe shape — not a checkpoint flag mutated then re-read out of band).
6. **Error short-circuit:** `if err != MCC_OK { return err }` — a downstream lattice failure aborts the pass and is surfaced verbatim-classified as `MCC_E_LATTICE` (W9 negative). Entries already marked before the failure remain stale (each mark is independently reversible via `ml_revalidate`; M5/M9 — no torn-state bricking, the lattice is monotone-consistent).
7. **Record + witness:** `MCC_LAST_COUNT = marked`; `let wrc : i32 = mcc_emit_pass(retired_chain_id, marked)`; `if wrc != MCC_OK { return MCC_E_WITNESS }`.
8. `return MCC_OK`.

**`mcc_emit_pass(retired_chain_id, n_marked)`** (internal, 2 params, W2) — builds and publishes the coordination-summary fragment (M6/M17/W16):
- Zero `MCC_SCR_PAYLOAD[0..48]`; set `[0] = MCC_PAYLOAD_TAG (0xE3)`, `[1] = MCC_EVT_COORD (0x18)`; copy the 32 `retired_chain_id` bytes into `[8..40]` (byte loop through `*u8`); write `n_marked` little-endian into `[40..48]` (8 byte-stores via `*u8`, Trap 5 safe — no `*u64`/`*u32` store).
- Zero `MCC_SCR_PRODUCER`, `MCC_SCR_OPID`, `MCC_SCR_OUTC` (system-originated, no producer/op/out identity — mirrors `wh_append_resolution`'s zero-ident pattern). `ident_copy(retired_chain_id → MCC_SCR_INC)` (the retired segment is the fragment's antecedent commitment).
- `let r : u64 = wh_publish(&MCC_SCR_PRODUCER[0], &MCC_SCR_OPID[0], &MCC_SCR_INC[0], &MCC_SCR_OUTC[0], 0u8, 0u8, 0u16, &MCC_SCR_PRODUCER[0], 0u32, &MCC_SCR_PAYLOAD[0], (MCC_PAYLOAD_LEN as u32), &MCC_SCR_FRAGID[0])` — `revtag=0`, `phase=0`, `pillar=0`, `n_ante=0` (the antecedents pointer is a zeroed buffer, unused since `n_ante=0`).
- `if r == 0xFFFFFFFFFFFFFFFFu64 { return MCC_E_WITNESS }` (compare to the documented sentinel by equality; never ordering — Trap 3 safe). Else `return MCC_OK`.

**`mcc_last_marked_count()`** — `return MCC_LAST_COUNT`. Pure read; lets a caller/KAT assert the pass result without parsing the witness payload.

**Idempotence (M5):** re-running `mcc_on_compaction` for an already-retired chain re-marks already-stale entries; `ml_mark_stale` on an already-stale entry is idempotent (re-sets STALE=1, same result per M58 spec) → safe, no bricking, a second pass simply re-witnesses the same count. **Reversibility (M9):** the module never deletes; each marked entry is restorable by `ml_revalidate` (M58-owned). The coordination fragment is append-only on the witness chain (M6).

## KAT Vectors (>= 3)
A self-test (`mcc_kat()`-style, gated behind the standard harness) drives a deterministic fixture. Setup: `ml_init(); mcc_init();` then admit three entries through the lattice with `wh_init(0u64)` and stubbed `ws_verify_segment`/`cons_find` returning OK (so admission succeeds): `ml_admit(KA, CA, CH0)`, `ml_admit(KB, CB, CH0)`, `ml_admit(KC, CC, CH1)` — two entries on chain `CH0`, one on `CH1`. Mint a cap `CAP_AMEND_CAP = cap_attenuate(cap_env_init(), CAP_RIGHT_AMEND, 0u64)` (a real cap carrying `0x4000`), and a cap `CAP_NO_AMEND = cap_attenuate(cap_env_init(), CAP_RIGHT_FS_READ, 0u64)` (lacks amend).

1. **Retire a chain with two dependents → both marked, count = 2, others untouched.** `mcc_on_compaction(CH0, CAP_AMEND_CAP)` → **`MCC_OK`**; `mcc_last_marked_count()` → **`2u64`**. Verify: `ml_lookup(KA, …)` → **`MEMOL_E_STALE`**, `ml_lookup(KB, …)` → **`MEMOL_E_STALE`**, `ml_lookup(KC, …)` → **`MEMOL_OK`** (KC on CH1 untouched). `wh_next_idx()` advanced by exactly **3** total since the admits (2 per-entry `0x0F` MEMO_STALE_MARK fragments emitted inside `ml_mark_stale` + 1 `0x18` coordination fragment from `mcc_emit_pass`). The coordination fragment's payload `[40..48]` decodes little-endian to **`2u64`** and `[8..40]` equals `CH0`.
2. **Retire a chain with no dependents → count = 0, OK, one witness fragment.** After KAT 1, with a fresh chain id `CH9` that no entry references: `mcc_on_compaction(CH9, CAP_AMEND_CAP)` → **`MCC_OK`**; `mcc_last_marked_count()` → **`0u64`**. No `ml_lookup` status changes; exactly **1** new witness fragment (the `0x18` summary, count `0`). (Proves an empty match-set is a valid, witnessed no-op — M6 holds even with zero marks.)
3. **Negative gate — capability lacking `CAP_RIGHT_AMEND` is refused, NO entry marked (proves the M8 gate FIRES).** Re-admit a fresh `ml_admit(KD, CD, CH2)`. `mcc_on_compaction(CH2, CAP_NO_AMEND)` → **`MCC_E_DENIED` (-3i32)**; `mcc_last_marked_count()` is **unchanged** from the prior pass; `ml_lookup(KD, …)` → **`MEMOL_OK`** (KD was NOT marked — the gate aborted before any scan). `wh_next_idx()` did **not** advance (no fragment emitted on a denied pass). (Proves the capability gate is not a no-op — an unprivileged caller cannot mark; satisfies "prove the negative case".)
4. **Negative gate — null `retired_chain_id` refused.** `mcc_on_compaction(0 as *u8, CAP_AMEND_CAP)` → **`MCC_E_NULL` (-1i32)**; no fragment; count unchanged.
5. **Not-inited gate.** Fresh process, *before* `mcc_init()`: `mcc_on_compaction(CH0, CAP_AMEND_CAP)` → **`MCC_E_NOT_INITED` (-2i32)**.
6. **Idempotence / reversibility.** After KAT 1: `mcc_on_compaction(CH0, CAP_AMEND_CAP)` again → **`MCC_OK`**, `mcc_last_marked_count()` → **`2u64`** (re-marks the two already-stale entries; idempotent), `ml_lookup(KA, …)` still **`MEMOL_E_STALE`**. Then `ml_revalidate(KA)` (with stubbed passing `ws_verify_segment`) → **`MEMOL_OK`** and a subsequent `ml_lookup(KA, …)` → **`MEMOL_OK`** (M9 reversibility — the mark is undoable; this module never bricks an entry).

## Trap Exposure
| # | Trap | Exposed? | Avoidance |
|---|------|----------|-----------|
| 1 | Multi-line `fn` decl | Yes (all 4 fns) | Every signature single-line in the skeleton; reviewer greps `^fn .*[^){]$` to confirm none wrap. |
| 2 | `const` linker-global | Yes (12 consts) | All `MCC_`-prefixed; grep confirmed no `MCC_` collision in `STDLIB/`. `MCC_CAP_AMEND`/`MCC_SLOTS`/`MCC_PAYLOAD_TAG` are local value-mirrors (annotated to their source-of-truth), never imported symbols. |
| 3 | Signed-order SIGSEGV | **Guard** | No `< / <= / > / >=` on any `i32`/`i64`. All status compares are `== MCC_OK` / `!= MCC_OK`. The `wh_publish` failure sentinel `0xFFFFFFFFFFFFFFFFu64` and the null `retired_chain_id` are tested by **equality** only. Loop bound `s >= n_slots` is on **`u64`** (the iiis SIGSEGV trap is signed-int only; `u64` ordering is safe — confirmed by `algebraic_time.iii:25` and `capability.iii:97`). |
| 4 | u32-in-u64-slot | No | The scan index `s` is a native `u64` counter; `s * 32u64` (inside M58's accessors) is pure `u64`. No `u32` local is widened for pointer math in this module. |
| 5 | u32 pointer-store width | **Guard** | The `n_marked` little-endian write into `MCC_SCR_PAYLOAD[40..48]` is **8 explicit `*u8` byte-stores** (`payload[40+i] = (n >> (i*8)) & 0xFF`), never a `*u64`/`*u32` store. Payload tag/sub-tag and chain_id copy are also `*u8` byte writes. |
| 6 | Nested `/* */` | No | Header is one block comment, no nesting; inline notes use `//` or `(...)`. |
| 7 | Local `var` arrays | **YES — addressed** | Gospel body has none yet, but the realized algorithm needs scratch (`key`, `payload`, emit idents). **All hoisted to module scope** as `MCC_SCR_*` (see Data Structures). Renders the module non-reentrant — acceptable for serial R0 compactor invocation (mirrors `witness_hook.iii`/`memo_lattice`). |
| 8 | `} else {` one line | Yes (scan terminator branch) | The single `} else {` (terminator vs. body) is written on one line in the skeleton. |
| 9 | Em-dash in comment | No | All comments use ASCII `--`; spec/skeleton contain no U+2014. |
| 10 | `let mut`=flag | **Guard** | The `going : u8` continuation flag drives the `while going == 1u8` condition **directly** (the safe shape), not a checkpoint mutated then re-read elsewhere. `err`/`marked` are accumulators, not checkpoint flags. `MCC_INITED` is module-scope, not a local `let mut`. |
| 11 | `%` after call | No | No modulo anywhere. The scan is `s < n_slots` with `s += 1`; no `% MCC_SLOTS`. |
| 12 | `@specialize *T` stride | No | Not generic; no `@specialize`. All buffers are concrete `[u8; N]` with explicit byte indexing. |

## Gap / Fix List
The candidate is a STUB. Every defect with its fix:

1. **`mcc_on_compaction` is a no-op (BLOCKER, the whole point).** The body guards then `return MCC_OK` — the "iterate the lattice and mark stale" algorithm exists only as a comment; `ml_mark_stale` is **never called**, nothing is enumerated. **Fix:** implement the deterministic full-table scan (Algorithm §5): for each live slot whose `chain_id == retired_chain_id`, copy the key and call `ml_mark_stale`. Accumulate `marked`.

2. **No enumeration surface on M58 (DESIGN-CRITICAL — the algorithm is unimplementable as written).** The gospel says "iterate over the memo lattice index finding entries whose chain_id matches," but M58's public API (`memo_lattice.spec.md`) exposes only key-addressed ops (`ml_lookup`/`ml_mark_stale`/`ml_revalidate`) and `ml_size` — **no slot enumeration, no chain-id read.** `ml_slot_find`/`ml_slot_alloc` are non-`@export` internal helpers. **Fix:** M58 must add four pure read-only accessors — `ml_slot_count`, `ml_slot_is_live`, `ml_slot_chain_eq`, `ml_slot_key` (signatures in Dependencies). This is the §3.5-defect-#6 "needed getters the built module does not yet export" pattern. Listed for the M58 implementer; **+0 new providers** (same `memo_lattice.iii`), **+4 externs**.

3. **No capability gate (M8 violation).** Marking memo entries stale is a privileged amendment of substrate state, yet the gospel `mcc_on_compaction(retired_chain_id)` takes no cap and performs no authorization. **Fix:** add `cap: u64` param (W2-clean at 2 params) and gate on `cap_verify_rights(cap, CAP_RIGHT_AMEND) == 1u8` → `MCC_E_DENIED` before any mutation (Algorithm §3). KAT 3 proves the gate fires.

4. **No witness fragment for the coordination transition (M6/M17/W16 violation).** The gospel returns OK without emitting anything. Per M6 every state transition must witness, and the *coordination pass* is itself a transition distinct from the per-entry `0x0F` marks. **Fix:** add `mcc_emit_pass` emitting one `0x18` MEMO_COMPACTION_COORD fragment via `wh_publish` (recording `retired_chain_id` as in_commit and `n_marked` in payload). On emit failure return `MCC_E_WITNESS`. (§3.5 defect #2: routed through the real `wh_publish`, not the fictional `ws_emit_fragment`.)

5. **Fictional/unverified externs avoided.** The gospel declares only `ml_mark_stale` (correct), but the realized design also needs cap + witness primitives. The naïve choices (`cap_verify`, `ws_emit_fragment`) are §3.5 fictions. **Fix:** verified the real symbols against provider files — `cap_verify_rights` (`capability.iii:148`) and `wh_publish` (`witness_hook.iii:144`) — and externed those exact signatures. No `keccak.iii`/`at_now`/`ed25519` externs needed (not in this module's path).

6. **Architecture alternative considered + rejected (recorded for review).** An alternative closes Gap #2 by having M58 expose a single `ml_mark_stale_by_chain(chain_id) -> i64` that scans internally. **Rejected** because (a) it reduces M79 to a one-line passthrough, contradicting its `kind_repair + kind_motion` coordination ontology; (b) it splits the witness boundary — M58 would emit only per-entry `0x0F` fragments with no over-arching coordination record, weakening the M17 audit trail; (c) the chosen accessor set keeps M58 a *pure store* and M79 the *coordinator*, which is the cleaner layering. If the M58 implementer strongly prefers the single-primitive form, M79 collapses to `marked = ml_mark_stale_by_chain(retired_chain_id)` plus the `mcc_emit_pass` witness — the public API of M79 is unchanged either way (the cap gate + summary fragment remain here). Documented so the wave scheduler/M58 owner can choose; this spec implements the accessor form.

7. **Verified-correct in the gospel body (not gaps):** the init-guard idempotence (`if MCC_INITED == 1u8 { return MCC_OK }`) is correct and kept; the null check uses `(p as u64) == 0u64` *equality* (Trap-3 safe) and is kept; the `MCC_` prefix matches the dispatch (no rename needed); the three error consts are kept and extended.

## Implementation Skeleton
```iii
/* III/STDLIB/iii/aether/memo_compactor_coordination.iii
 *
 * III STDLIB - aether::memo_compactor_coordination  (Layer 9, Module 79)
 *
 * The deterministic bridge between witness compaction and the
 * memoization lattice. When the compactor retires a chain segment,
 * every memo entry whose producing chain was that segment must be
 * marked stale (gospel L401, W50). This module enumerates the lattice
 * once per retirement, marks each dependent entry stale via the
 * lattice's reversible ml_mark_stale, and emits one chained witness
 * fragment (0x18 MEMO_COMPACTION_COORD) recording the pass.
 *
 * Hexad: kind_repair + kind_motion.  Ring: R0.  K: 1.00.
 *
 * M8: mcc_on_compaction is capability-gated (CAP_RIGHT_AMEND).
 * M6/M17: every pass emits a coordination-summary witness fragment.
 * M2/W5: the scan is a fixed 0..MCC_SLOTS counter loop; identical
 *        lattice state + retired_chain_id -> identical marks, bytes, id.
 * M5/M9: marking is idempotent and reversible (ml_revalidate); the
 *        module never deletes -- no bricking.
 *
 * NIH: depends on memo_lattice.iii (M58: ml_mark_stale + four NEW
 *      read-only accessors ml_slot_count/is_live/chain_eq/key that
 *      Phase 2 must add), capability.iii (cap_verify_rights, BUILT),
 *      witness_hook.iii (wh_publish, BUILT).
 *
 * Non-reentrant: MCC_SCR_* scratch buffers are module-scope (Trap 7);
 * serial R0 compactor invocation only.
 */

module aether_memo_compactor_coordination

extern @abi(c-msvc-x64) fn ml_mark_stale(key: *u8) -> i32 from "memo_lattice.iii"
extern @abi(c-msvc-x64) fn ml_slot_count() -> u64 from "memo_lattice.iii"
extern @abi(c-msvc-x64) fn ml_slot_is_live(slot: u64) -> u8 from "memo_lattice.iii"
extern @abi(c-msvc-x64) fn ml_slot_chain_eq(slot: u64, chain_id: *u8) -> u8 from "memo_lattice.iii"
extern @abi(c-msvc-x64) fn ml_slot_key(slot: u64, out_key: *u8) -> i32 from "memo_lattice.iii"
extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"

const MCC_OK            : i32 =  0i32
const MCC_E_NULL        : i32 = -1i32
const MCC_E_NOT_INITED  : i32 = -2i32
const MCC_E_DENIED      : i32 = -3i32
const MCC_E_LATTICE     : i32 = -4i32
const MCC_E_WITNESS     : i32 = -5i32

const MCC_SLOTS         : u64 = 65536u64        /* mirror of MEMOL_SLOTS (memo_lattice.iii) */
const MCC_KEY_BYTES     : u64 = 32u64
const MCC_CAP_AMEND     : u64 = 0x4000u64        /* mirror of CAP_RIGHT_AMEND (capability.iii) */
const MCC_PAYLOAD_TAG   : u8  = 0xE3u8           /* tree-wide witness outer tag */
const MCC_EVT_COORD     : u8  = 0x18u8           /* MEMO_COMPACTION_COORD (gospel V3 sub-tag range 0x18..0xFE) */
const MCC_PAYLOAD_LEN   : u64 = 48u64            /* tag + sub-tag + chain_id[32] + count[8] */

var MCC_INITED          : u8  = 0u8
var MCC_LAST_COUNT      : u64 = 0u64

var MCC_SCR_KEY         : [u8; 32]
var MCC_SCR_PAYLOAD     : [u8; 48]
var MCC_SCR_PRODUCER    : [u8; 32]
var MCC_SCR_OPID        : [u8; 32]
var MCC_SCR_INC         : [u8; 32]
var MCC_SCR_OUTC        : [u8; 32]
var MCC_SCR_FRAGID      : [u8; 32]

fn mcc_emit_pass(retired_chain_id: *u8, n_marked: u64) -> i32 {
    // TODO: body per Algorithm: zero MCC_SCR_PAYLOAD; [0]=0xE3 [1]=0x18; copy chain_id@8 (byte loop); n_marked LE @40 (8x *u8 stores); zero producer/opid/outc; ident_copy chain_id->MCC_SCR_INC; wh_publish(...); return MCC_E_WITNESS if r==0xFFFFFFFFFFFFFFFFu64 else MCC_OK
}

fn mcc_init() -> i32 @export {
    // TODO: body per Algorithm: idempotent; if MCC_INITED==1u8 return MCC_OK; MCC_LAST_COUNT=0; MCC_INITED=1; return MCC_OK
}

fn mcc_on_compaction(retired_chain_id: *u8, cap: u64) -> i32 @export {
    // TODO: body per Algorithm: init guard -> E_NOT_INITED; null guard (==0u64) -> E_NULL; cap_verify_rights(cap, MCC_CAP_AMEND)!=1u8 -> E_DENIED; n_slots=ml_slot_count(); sentinel-counter scan 0..min(n_slots,MCC_SLOTS) (no break, `} else {` one line): on live+chain_eq -> ml_slot_key then ml_mark_stale, marked++; on any ml_* !=MCC_OK set err & stop; if err!=MCC_OK return err; MCC_LAST_COUNT=marked; if mcc_emit_pass(...)!=MCC_OK return MCC_E_WITNESS; return MCC_OK
}

fn mcc_last_marked_count() -> u64 @export {
    // TODO: body per Algorithm: return MCC_LAST_COUNT
}
```
