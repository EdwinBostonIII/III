# 62 numera/theorem_carrier.iii — Implementation Spec

## Verdict
PARTIAL — the gospel candidate is structurally coherent and the slot-table / emit logic is sound, but it **cannot compile as written** (local `var` arrays — Trap 7), it externs **two functions that do not exist where it says** (`keccak256_*` is in `keccak256.iii` not `keccak.iii`; `at_now` does not exist at all — `algebraic_time.iii` exports `at_current`/`at_advance` returning `u64`), it carries a self-admitted **`Placeholder` line** in the id-computation path, mis-sizes the timestamp store (32 B/slot for an 8-byte `u64`), violates **W2** (`tc_alloc` has 6 params), and is exposed to the **keccak param-spill trap** in `tc_alloc`. All gaps are closable; the algorithmic intent is correct and maximal.

## Purpose
`theorem_carrier` makes a theorem a first-class substrate artifact: a **carrier** bundles a statement, a *verified* proof-term id, a content-addressed carrier id, and a dependency closure (the carrier ids this carrier's proof cites via `PT_RULE_LIBRARY_CITE`). It is the enforcement point for **M18 (Theorem Carrier Discipline)** and **W35 (no theorem without a witnessed proof term)**: nothing is admitted (`THMC_LIVE=1`) unless `pt_verify` returns `PT_OK` and every declared dependency is already resident. Carriers are emitted to the witness spine as `THEOREM_PROPOSED` / `THEOREM_VERIFIED` fragments. **Hexad:** kind_essence + kind_witness + kind_cognition. **Ring:** R0. **K:** 1.00 (K_theorem 1.00 once admitted to the math library).

## Public API
All signatures single-line (Trap 1). All return a status `i32` (W9/W12); error codes are negative `i32`, success `THMC_OK = 0i32`.

```
fn tc_init() -> i32 @export
fn tc_alloc(req: *u8, out_carrier_id: *u8) -> i32 @export
fn tc_verify(carrier_id: *u8) -> i32 @export
fn tc_emit_proposed(carrier_id: *u8, out_frag_id: *u8) -> i32 @export
fn tc_emit_verified(carrier_id: *u8, out_frag_id: *u8) -> i32 @export
fn tc_get_statement(carrier_id: *u8, out_buf: *u8, out_cap: u32, out_len: *u32) -> i32 @export
fn tc_get_proof_term(carrier_id: *u8, out_term_id: *u8) -> i32 @export
fn tc_get_dependencies(carrier_id: *u8, out_buf: *u8, out_cap: u32, out_count: *u32) -> i32 @export
fn tc_kat() -> u64 @export
```

**W2 FIX — `tc_alloc` aggregate.** The gospel `tc_alloc(statement, statement_len, proof_term_id, dependency_carriers, dependency_count, out_carrier_id)` is **6 params → violates W2 (≤4)**. Replace the first five with a single caller-populated request record passed by pointer (`req: *u8`), keeping `out_carrier_id` out of the record (it is an output). This mirrors the merkle.iii precedent (`merkle_pack_*` aggregation to dodge the arg-count trap) and is the house-style fix.

`TC_ALLOC_REQ` layout (caller fills a 56-byte fixed header at the front of `req`, followed by the variable statement+deps region the header points into — see Data Structures):
- `req[0..7]`   `u64` statement_len
- `req[8..15]`  `u64` absolute pointer to statement bytes
- `req[16..23]` `u64` absolute pointer to proof_term_id (32 B)
- `req[24..31]` `u64` absolute pointer to dependency_carriers (dependency_count × 32 B)
- `req[32..39]` `u64` dependency_count
(remaining bytes reserved 0). All multi-byte fields little-endian, read byte-by-byte (Trap 4/5 safe). A convenience packer `tc_pack_alloc_req` is provided so callers never hand-assemble the record.

```
fn tc_pack_alloc_req(req_out: *u8, statement: *u8, statement_len: u32, ptids_and_deps: *u8) -> i32 @export
```
(`ptids_and_deps` points to a 16-byte mini-aggregate {proof_term_ptr:u64, dep_ptr:u64} immediately followed by a `u64` dep_count — keeps the packer itself at 4 params. Optional helper; Phase 2 may inline.)

Return convention per fn: `tc_init` → `THMC_OK`. `tc_alloc` → `THMC_OK` | `THMC_E_NOT_INITED` | `THMC_E_NULL` | `THMC_E_FULL` | `THMC_E_VERIFY_FAIL` | `THMC_E_DEP_ABSENT` | `THMC_E_DUP`. `tc_verify` → `THMC_OK` | `THMC_E_NOT_INITED` | `THMC_E_NULL` | `THMC_E_ABSENT` | `THMC_E_VERIFY_FAIL` | `THMC_E_DEP_ABSENT`. `tc_emit_*` → status of `ws_emit_fragment` or a negative `THMC_E_*`. Getters → `THMC_OK` | `THMC_E_*` (incl. `THMC_E_BUF_TOO_SMALL`). `tc_kat` → `99u64` on full pass, else a nonzero failure code (house KAT convention, cf. keccak256.iii).

## Constant Namespace
**PREFIX = `THMC_`** (dispatch-assigned; the gospel body used `TC_`). Grep result: `THMC_` → **0 occurrences** in `STDLIB/` (collision-free). `TC_` is also currently free in `STDLIB/`, but the dispatch mandates `THMC_`, so **every module-level const, every `var`, and every internal helper name is re-prefixed `THMC_` / `tc_*`** (the `tc_*` *function* names are kept because they are the gospel's public API surface consumed by math_library(66); only the **const/var** prefix changes to `THMC_`).

```
const THMC_OK              : i32 =  0i32
const THMC_E_NULL          : i32 = -1i32
const THMC_E_FULL          : i32 = -2i32
const THMC_E_ABSENT        : i32 = -3i32
const THMC_E_VERIFY_FAIL   : i32 = -4i32
const THMC_E_DEP_ABSENT    : i32 = -5i32
const THMC_E_BUF_TOO_SMALL : i32 = -6i32
const THMC_E_NOT_INITED    : i32 = -7i32
const THMC_E_DUP           : i32 = -8i32   // NEW: idempotent-admit guard (M5/M17)

const THMC_SLOTS           : u64 = 16384u64
const THMC_STATEMENT_BYTES : u64 = 1024u64
const THMC_MAX_DEPS        : u64 = 64u64
const THMC_ID_BYTES        : u64 = 32u64
const THMC_DEP_STRIDE      : u64 = 2048u64   // THMC_MAX_DEPS * 32  (precomputed; avoids `*` after call — Trap 11 hygiene)
const THMC_FRAG_TAG0       : u8  = 0xE3u8     // payload magic byte 0
const THMC_FRAG_PROPOSED   : u8  = 0x0Au8     // payload magic byte 1, PROPOSED
const THMC_FRAG_VERIFIED   : u8  = 0x0Bu8     // payload magic byte 1, VERIFIED
```

`PT_OK` is **not** redeclared here (it is owned by proof_term.iii / Trap 2). The verify check compares `pt_verify(...) != 0i32` against the literal `0i32`, never against an imported `PT_OK` symbol — avoids a cross-module const collision.

## Data Structures
All module-scope (Trap 7: no local `var` arrays). Slot table is statically sized at `THMC_SLOTS = 16384` (W8); bound justification: math-library admission is a curated, ratified act — 16 Ki distinct admitted theorems is generous for a sovereign substrate library and bounds BSS at the sizes below. Not reentrant (serialized admission ceremony — acceptable, noted).

| Name | Type | Size (bytes) | Justification |
|---|---|---|---|
| `THMC_INITED` | `u8` | 1 | init guard |
| `THMC_COUNT` | `u64` | 8 | live-carrier count |
| `THMC_CARRIER_IDS` | `[u8; 524288]` | 16384×32 | one 32-B id per slot |
| `THMC_PROOF_TERM_IDS` | `[u8; 524288]` | 16384×32 | one proof-term id per slot |
| `THMC_STATEMENT_LENS` | `[u32; 16384]` | 16384×4 | per-slot statement length |
| `THMC_STATEMENTS` | `[u8; 16777216]` | 16384×1024 | statement bytes (cap `THMC_STATEMENT_BYTES`) |
| `THMC_DEPENDENCY_COUNTS` | `[u32; 16384]` | 16384×4 | per-slot dep count (≤64) |
| `THMC_DEPENDENCIES` | `[u8; 33554432]` | 16384×64×32 | dep ids, stride `THMC_DEP_STRIDE` |
| `THMC_TIMESTAMPS` | `[u64; 16384]` | 16384×8 | **FIX**: algebraic-time stamp is a `u64`, not a 32-B id (gospel mis-sized this `[u8;524288]`) |
| `THMC_LIVE` | `[u8; 16384]` | 16384 | slot occupancy |
| `THMC_VERIFIED` | `[u8; 16384]` | 16384 | per-slot verified flag |
| `THMC_HASH_OUT` | `[u8; 32]` | 32 | **module-scope** scratch for keccak final (was local `var` — Trap 7) |
| `THMC_IDBUF` | `[u8; 1024]` | 1024 | **module-scope** contiguous preimage staging for the carrier-id hash (statement‖ptid‖deps) — used by the oneshot path (keccak param-spill fix); cap = `THMC_STATEMENT_BYTES`; if `statement_len + 32 + deps*32` exceeds 1024 the statement is hashed incrementally (see Algorithm) |
| `THMC_PAYLOAD` | `[u8; 2112]` | 64 + 64×32 | **module-scope** witness payload (was local `var [u8;2112]` — Trap 7); reused by both emit fns |
| `THMC_PRODUCER` | `[u8; 32]` | 32 | producer id for emits (module-scope; see M6 fix) |
| `THMC_OP_PROPOSED` | `[u8; 32]` | 32 | stable op-id = ident_from_bytes("tc_emit_proposed") (M6 fix; was `ident_zero`) |
| `THMC_OP_VERIFIED` | `[u8; 32]` | 32 | stable op-id = ident_from_bytes("tc_emit_verified") |
| `THMC_INC` | `[u8; 32]` | 32 | scratch in-commit id for emits |
| `THMC_OUTC` | `[u8; 32]` | 32 | scratch out-commit id for emits |
| `THMC_KAT_*` | small | <8 KB | KAT scratch (statement/dep/id/frag buffers) |

Total fixed BSS ≈ 67.7 MB (dominated by `THMC_STATEMENTS` 16 MB + `THMC_DEPENDENCIES` 32 MB + ids 1 MB). This is the maximal-intent footprint; do **not** down-scale `THMC_SLOTS` (per "no practicality / full gospel scale").

## Dependencies (externs)
All `extern @abi(c-msvc-x64)`. **Two gospel externs are corrected below** (path / existence).

| Extern (corrected) | From | Module NN | Built? |
|---|---|---|---|
| `fn ident_zero(out: *u8) -> i32` | `identifier.iii` | 01 | **built** ✓ (verified signature) |
| `fn ident_eq(a: *u8, b: *u8) -> u8` | `identifier.iii` | 01 | built ✓ |
| `fn ident_copy(src: *u8, dst: *u8) -> i32` | `identifier.iii` | 01 | built ✓ |
| `fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32` | `identifier.iii` | 01 | built ✓ |
| `fn keccak256_oneshot(msg_ptr: u64, msg_len: u64, out_ptr: u64) -> i32` | **`keccak256.iii`** | 04-wrapper | **built** ✓ — **CORRECTED from gospel's `keccak256_init/update/final from "keccak.iii"`** (those names do not exist in `keccak.iii`; the streaming trio lives in `keccak256.iii` and is param-spill-fragile — use the oneshot, exactly as identifier.iii does) |
| `fn pt_verify(term_id: *u8) -> i32` | `proof_term.iii` | **61** | **NOT-YET-BUILT** — wave-order before 62. Returns `PT_OK=0i32` on success; we test `!= 0i32`. |
| `fn ws_emit_fragment(producer: *u8, op: *u8, in_commit: *u8, out_commit: *u8, payload: *u8, payload_len: u64, out_fid: *u8) -> i32` | `witness_spine.iii` | **(Layer ≤4)** | **NOT-YET-BUILT** — wave-order before 62. (7-param extern; we only *call* it, we do not *define* it, so W2 does not apply to the call site — but note the 7 params for the scheduler.) |
| `fn at_advance() -> u64` | `algebraic_time.iii` | (Layer ≤4) | **built** ✓ — **CORRECTED from gospel's nonexistent `at_now(out:*u8)->i32`.** Real API: `at_current()->u64`, `at_advance()->u64`. We use `at_advance()` so each admission monotonically advances algebraic time (W17). |

**Not-yet-built deps: 2** → `proof_term.iii` (61) and `witness_spine.iii`. Schedule 62 in a wave strictly after both. (`identifier`, `keccak256`, `algebraic_time` are all built.)

## Algorithm
NIH (M1): the only algorithm here is **Keccak-256 content addressing** (hand-rolled, via `keccak256.iii`) + linear-scan associative slot lookup. No ML/heuristics (M3/M4): every decision is an exact equality (`ident_eq`, `pt_verify == 0`, slot-live flag). Determinism (M2) / bit-identity (W5): all buffers fixed-size and zero-initialized at `tc_init`; ids are pure functions of input bytes; no recursion (W15) — every traversal is a single `while` driven by a sentinel flag/counter (W14, no `break`).

**`tc_init`** — idempotent: if `THMC_INITED==1` return. Else zero `THMC_LIVE[i]`/`THMC_VERIFIED[i]` for `i in 0..THMC_SLOTS`, set `THMC_COUNT=0`, `THMC_INITED=1`. Also (one-time) compute the two stable op-ids: `ident_from_bytes("tc_emit_proposed", 16, &THMC_OP_PROPOSED)` and likewise `THMC_OP_VERIFIED`; zero `THMC_PRODUCER` once (the carrier subsystem's null-but-stable producer; see M6 note — a real producer id can be injected here by a capability holder in a later wave without changing the API).

**`tc_find_slot(carrier_id) -> i64`** (internal, not exported). Sentinel-scan `i in 0..THMC_SLOTS`: while `found_flag==0`, if `THMC_LIVE[i]==1` and `ident_eq(&THMC_CARRIER_IDS[i*32], carrier_id)==1`, set `found=i as i64`, `found_flag=1`. Loop counter `i` always advances (no `break`, W14). Returns `-1i64` if absent. **Trap 3 fix:** the absent sentinel is `-1i64`; all callers test `== -1i64` / `!= -1i64`, never `< 0`.

**`tc_alloc(req, out_carrier_id)`** —
1. Guard `THMC_INITED==1` else `THMC_E_NOT_INITED`. Read the five aggregate fields from `req` **byte-by-byte into u64 locals** (`statement_len`, `stmt_ptr`, `ptid_ptr`, `dep_ptr`, `dep_count`) — Trap 4/5 safe (no `as u64` of a u32 slot feeding pointer math; we build the u64 from 8 bytes). Null-check `stmt_ptr`, `ptid_ptr`, `out_carrier_id`, `req` → `THMC_E_NULL`.
2. **Verify proof term FIRST (W35 / M18 / fail-fast):** `if pt_verify(ptid_ptr as *u8) != 0i32 { return THMC_E_VERIFY_FAIL }`. (Gospel does this after slot-find; we hoist it so a bad proof never touches the table.)
3. **Verify dependency closure present:** sentinel-loop `d in 0..dep_count`; while `deps_ok==1`, `if tc_find_slot(&dep[d*32]) == -1i64 { deps_ok=0 }`. After loop, `if deps_ok==0 { return THMC_E_DEP_ABSENT }`. (`d*32` and the dep base are `u64` arithmetic on already-masked u64 locals.)
4. **Compute carrier id = Keccak256(statement ‖ proof_term_id ‖ dependency_ids)** via the **oneshot, param-spill-safe** path (the gospel's init/update×3/final is the exact pattern identifier.iii documents as clobbering param registers): stage the preimage contiguously into `THMC_IDBUF`. Common case `statement_len + 32 + dep_count*32 ≤ 1024`: copy statement bytes, then 32 ptid bytes, then `dep_count*32` dep bytes into `THMC_IDBUF`; call `keccak256_oneshot(&THMC_IDBUF as u64, total_len, &THMC_HASH_OUT as u64)`. Large case (statement_len near 1024 with deps): the staging buffer is sized for statement alone; for the rare overflow, hash by concatenating into `THMC_IDBUF` in **one** segment per region is impossible, so the maximal-correct form stages `proof_term_id‖deps` (≤ 32+2048 = 2080 B) — therefore size `THMC_IDBUF` at **2112 B** (reuse `THMC_PAYLOAD`'s sizing) and prepend the statement only up to its 1024-B cap; since `statement_len ≤ THMC_STATEMENT_BYTES (1024)` is itself an admission invariant (statements over 1024 B are rejected with `THMC_E_BUF_TOO_SMALL` at alloc — **NEW guard the gospel lacked**), the total preimage `≤ 1024 + 32 + 2048 = 3104` — **so `THMC_IDBUF` is sized 3104 B** and a single oneshot suffices. (Decision: enforce `statement_len ≤ 1024` and size `THMC_IDBUF=[u8;3104]`; one oneshot, fully deterministic, no streaming, no param-spill.)
   - **Delete the gospel `Placeholder` line** (`ident_from_bytes(statement,...,&THMC_CARRIER_IDS[s*32]) /* Placeholder */`) — it writes a wrong value that the subsequent copy overwrites; it is dead/misleading and is removed.
5. **Find a free slot** (separate sentinel-scan for `THMC_LIVE[i]==0`); `if slot==-1i64 { return THMC_E_FULL }`. `let s : u64 = slot as u64`.
6. **Idempotent-admit guard (NEW, M5/M17):** `if tc_find_slot(&THMC_HASH_OUT) != -1i64 { return THMC_E_DUP }` — re-admitting an identical (statement, proof, deps) carrier is refused rather than creating an orphaned duplicate-id slot. (Closes the gospel's silent double-insert.)
7. **Commit slot:** `ident_copy(&THMC_HASH_OUT, &THMC_CARRIER_IDS[s*32])`; `ident_copy(&THMC_CARRIER_IDS[s*32], out_carrier_id)`; `ident_copy(ptid_ptr as *u8, &THMC_PROOF_TERM_IDS[s*32])`. Store `THMC_STATEMENT_LENS[s]=statement_len_u32`; copy `statement_len` statement bytes into `THMC_STATEMENTS[s*1024 ..]`. Store `THMC_DEPENDENCY_COUNTS[s]=dep_count_u32`; copy `dep_count*32` dep bytes into `THMC_DEPENDENCIES[s*THMC_DEP_STRIDE ..]`. `THMC_TIMESTAMPS[s] = at_advance()` (u64 store, W17 monotonic). Set `THMC_LIVE[s]=1`, `THMC_VERIFIED[s]=1`, `THMC_COUNT += 1`. Return `THMC_OK`.

**`tc_verify(carrier_id)`** — guard inited + non-null; `slot=tc_find_slot`; `== -1i64 → THMC_E_ABSENT`. Re-run `pt_verify(&THMC_PROOF_TERM_IDS[s*32]) != 0i32 → THMC_E_VERIFY_FAIL`. Re-check each of `THMC_DEPENDENCY_COUNTS[s]` deps present (sentinel-loop, same as alloc). Set `THMC_VERIFIED[s]=1`; return `THMC_OK`. (Pure re-attestation; idempotent; reversible/no destructive state — M9.)

**`tc_emit_proposed(carrier_id, out_frag_id)`** — guards; `slot=tc_find_slot`; build `THMC_PAYLOAD`: `[0]=THMC_FRAG_TAG0`, `[1]=THMC_FRAG_PROPOSED`, bytes `[8..39]=carrier_id`, `[40..71]=THMC_PROOF_TERM_IDS[s*32..]` (sentinel-loop `k in 0..32`). `ident_copy(carrier_id, &THMC_INC)`; `ident_copy(&THMC_PROOF_TERM_IDS[s*32], &THMC_OUTC)`. Return `ws_emit_fragment(&THMC_PRODUCER, &THMC_OP_PROPOSED, &THMC_INC, &THMC_OUTC, &THMC_PAYLOAD, 72u64, out_frag_id)`. **M6 fix:** producer is the stable `THMC_PRODUCER` and op is the stable `THMC_OP_PROPOSED` (gospel zeroed *both* op and producer with `ident_zero`, erasing provenance — the op-id now distinguishes PROPOSED from VERIFIED in the spine so the fragment is self-describing and byte-recomputable, M10).

**`tc_emit_verified(carrier_id, out_frag_id)`** — guards; `slot=tc_find_slot`; `if THMC_VERIFIED[slot as u64]==0u8 { return THMC_E_VERIFY_FAIL }`. Build `THMC_PAYLOAD`: `[0]=THMC_FRAG_TAG0`, `[1]=THMC_FRAG_VERIFIED`, `[8..39]=carrier_id`, `[40..71]=proof_term_id`. Write `dc` as 4 little-endian bytes at `[72..75]` **via the masked-shift form already in the gospel** (`(dc & 0xFFu32) as u8`, `((dc>>8)&0xFF) as u8`, …) — that is Trap 5-safe (each store is a `u8`). Then copy `dc*32` dep id bytes starting at `[80]` (nested sentinel-loops `m in 0..dc`, `q in 0..32`). `plen = 80 + dc*32`. Emit with `&THMC_OP_VERIFIED`. Return the `ws_emit_fragment` status.

**Getters** (`tc_get_statement`, `tc_get_proof_term`, `tc_get_dependencies`) — guards + `tc_find_slot`; `tc_get_statement` checks `out_cap < len → THMC_E_BUF_TOO_SMALL` then copies `len` bytes and `*out_len=len`; `tc_get_proof_term` `ident_copy`s the stored proof-term id; `tc_get_dependencies` checks `out_cap < dc*32 → THMC_E_BUF_TOO_SMALL`, copies `dc*32` bytes, `*out_count=dc`. All copies are byte loops (Trap 5-safe). `dc`/`len` are read from u32 slots and used only as loop bounds (`while k < (len as u64)`), **not** as pointer-arithmetic multipliers without masking — and where `dc as u64` *does* feed `dc*32` for a copy length, mask `(dc as u64) & 0xFFFFFFFFu64` first (Trap 4).

## KAT Vectors (>= 3)
Self-test `tc_kat() -> u64`, returns `99u64` on full pass (house convention). Because `pt_verify`/`ws_emit_fragment` are external (and proof_term/witness_spine are not-yet-built), the KAT runs in **two tiers**:

**Tier A — standalone (no external proof needed), runs in this module's own selftest:**
1. **Carrier-id determinism / Keccak vector.** statement = `"abc"` (0x61 62 63), proof_term_id = 32 zero bytes, 0 deps. Expected `out_carrier_id = Keccak256(0x61 62 63 ‖ 00×32)`. Compute the same preimage independently in the KAT and `keccak256_oneshot` it into a reference; assert `ident_eq(out, ref)==1`. (Anchors on the proven `keccak256.iii` vector — `Keccak256("abc")` first byte 0x4e — by extension of the staged preimage.) Re-running `tc_alloc` with identical input must return `THMC_E_DUP` (idempotent-admit), proving the dup guard.
2. **Round-trip storage.** After alloc, `tc_get_statement(id,...)` returns `len==3` and bytes `0x61,0x62,0x63`; `tc_get_proof_term(id, out)` returns the 32-zero id; `tc_get_dependencies(id,...)` returns `count==0`.
3. **Dependency-absent rejection.** `tc_alloc` with `dep_count=1` and a dep id of 32 `0xAA` bytes that was never admitted must return `THMC_E_DEP_ABSENT` and leave `THMC_COUNT` unchanged (prove the *negative* case — guard FAILS on bad input, not merely passes on good).
4. **Buffer-too-small.** `tc_get_statement` with `out_cap=2` (< 3) returns `THMC_E_BUF_TOO_SMALL`; statement >1024 B at alloc returns `THMC_E_BUF_TOO_SMALL`.
5. **Not-inited.** Calling any API before `tc_init` returns `THMC_E_NOT_INITED` (run this branch first, before `tc_init`).

**Tier B — integration (gated on proof_term(61) + witness_spine wave), checked by the Phase-2 cross-module harness, not this selftest:** with a real verified proof term `P`, `tc_alloc` of a theorem citing an already-admitted carrier `C` succeeds and `tc_get_dependencies` returns `C`'s id; `tc_emit_proposed` then `tc_emit_verified` each return `THMC_OK` (ws status) and emit fragments whose payload bytes `[0..1]` are `E3 0A` / `E3 0B` respectively and `[8..39]` equal the carrier id — byte-for-byte (M10). A carrier whose proof fails `pt_verify` returns `THMC_E_VERIFY_FAIL` and is **not** admitted (W35 negative case).

## Trap Exposure
- **Trap 1 (multi-line fn):** every signature above is single-line. The 6-param `tc_alloc` is collapsed to 4 params (req+out) — also satisfies **W2**.
- **Trap 2 (const linker-global):** all consts/vars re-prefixed `THMC_`; grep confirms `THMC_`=0 collisions. `PT_OK` deliberately NOT imported (compared against `0i32` literal).
- **Trap 3 (signed ordering SIGSEGV):** slot indices use the `-1i64` sentinel with `==`/`!=` only. No `< 0` / `>=` on any `i64`/`i32`. (Gospel already complied; preserved.)
- **Trap 4 (u32-in-u64-slot garbage):** `dc`/`statement_len` from u32 slots are masked `& 0xFFFFFFFFu64` before any `*32` used as a copy/pointer length; aggregate fields are reassembled from 8 individual bytes, never `as u64` of a u32 slot.
- **Trap 5 (u32 pointer store width):** every write into the byte arrays (`THMC_STATEMENTS`, `THMC_DEPENDENCIES`, `THMC_PAYLOAD`, ids) is a `u8` store in a loop; the `dc` length header in `tc_emit_verified` is stored as four separate `u8` masked-shift bytes (gospel form, kept).
- **Trap 6 (nested block comments):** none. Single `/* */` header + `//` inline only.
- **Trap 7 (local var arrays):** **the gospel's blocker.** All four locals (`hash_out:[u8;32]`, `payload:[u8;72]`, `payload:[u8;2112]`, and the four `[u8;32]` producer/op/in_c/out_c) are **lifted to module scope** (`THMC_HASH_OUT`, `THMC_PAYLOAD`, `THMC_PRODUCER`, `THMC_OP_*`, `THMC_INC`, `THMC_OUTC`, `THMC_IDBUF`). Non-reentrancy noted (serialized admission — acceptable).
- **Trap 8 (`} else {` one line):** all if/else on one line in the skeleton.
- **Trap 9 (em-dash in comment):** ASCII `--` only; no U+2014 anywhere.
- **Trap 10 (`let mut x=0u32` flag):** slot/dep scans use a `u8` sentinel flag (`found`/`deps_ok`) that the loop body sets once; the loop counter — not the flag — drives the `while` bound, and the flag is `u8` not `u32`. Idempotent paths (`tc_init`, `tc_verify`) use the early-`return` pattern.
- **Trap 11 (`%`/`*` after call):** **no modulo anywhere.** Stride multiplies (`s*1024`, `s*THMC_DEP_STRIDE`, `m*32`) use the precomputed `THMC_DEP_STRIDE` const and occur on u64 locals; the only multiply that follows a call (`dep_count*32` after `tc_find_slot`) is recomputed from a freshly-masked local, not reused across the call — flag noted, mitigated by re-reading the local.
- **Trap 12 (`@specialize *T` stride):** N/A — this module is not generic; all element strides are concrete `32`/`1024`.

## Gap / Fix List
1. **Wrong keccak path (BLOCKER, systemic gospel defect).** Gospel: `extern keccak256_init/update/final from "keccak.iii"`. Those symbols do not exist in `keccak.iii` (which exports raw `keccak_state_zero/absorb/squeeze/f1600`). **Fix:** extern `keccak256_oneshot from "keccak256.iii"` and stage one contiguous preimage — the proven pattern from `identifier.iii` (which documents the param-spill clobber across `keccak256_init`).
2. **Nonexistent `at_now` (BLOCKER).** Gospel: `extern at_now(out:*u8)->i32 from "algebraic_time.iii"`. No such function. **Fix:** `extern at_advance()->u64`; store the `u64` in `THMC_TIMESTAMPS:[u64;16384]` (gospel mis-sized it `[u8;524288]`).
3. **Local `var` arrays (BLOCKER, Trap 7).** `hash_out`, both `payload`s, and the four `[u8;32]` emit scratch are local — won't parse. **Fix:** module-scope buffers (see Data Structures).
4. **Self-admitted `Placeholder` (STUB marker).** Line `ident_from_bytes(statement, statement_len, &TC_CARRIER_IDS[s*32]) /* Placeholder; real code finalizes Keccak */` writes a bogus id immediately overwritten. **Fix:** deleted; the oneshot over `THMC_IDBUF` is the real id computation.
5. **W2 violation.** `tc_alloc` = 6 params. **Fix:** `req:*u8` aggregate + `out_carrier_id` (4 → 2 params).
6. **Missing statement-length cap.** Gospel copies `statement_len` bytes into a 1024-B-per-slot store with no `len > 1024` guard → buffer overrun into the next slot. **Fix:** `if statement_len > THMC_STATEMENT_BYTES { return THMC_E_BUF_TOO_SMALL }` in `tc_alloc`.
7. **Silent duplicate admit (M5/M17).** Gospel never checks whether the computed id already exists before claiming a free slot → two live slots, identical id, second orphaned. **Fix:** `THMC_E_DUP` guard after id computation (idempotent admission).
8. **Provenance erasure (M6/M10).** `tc_emit_*` pass `ident_zero` for *both* producer and op → fragments carry no producer and PROPOSED/VERIFIED are indistinguishable by op-id. **Fix:** stable `THMC_PRODUCER` + distinct `THMC_OP_PROPOSED`/`THMC_OP_VERIFIED` (ident_from_bytes of the op name), so each fragment is self-describing and byte-recomputable.
9. **Verify-before-touch ordering.** Gospel finds the free slot, *then* `pt_verify`s. **Fix (fail-fast / W35 spirit):** `pt_verify` first, before any table mutation.
10. **Prefix.** Re-prefixed `TC_` → `THMC_` per dispatch (grep: `THMC_` collision-free). `tc_*` function names retained (public API consumed by math_library(66)).
11. **`PT_OK` not redeclared.** Comparing `pt_verify(...) != 0i32` against a literal avoids importing/duplicating proof_term's const (Trap 2 hygiene).

**Mandate posture:** M1 ✓ (only identifier/keccak256/algebraic_time/proof_term/witness_spine — all III, NIH). M2/W5 ✓ (fixed buffers, pure-fn ids, zeroed init). M3/M4 ✓ (no counting/learning; exact equality only). M5 ✓ (dup-guard + no destructive op; refusal over corruption). M6/M10 ✓ after fix #8. M7 ✓ (Ring R0 preserved). M8 — *note*: `tc_alloc` has no explicit capability arg; admission is gated by `pt_verify`+dependency-closure (proof-mediated rather than capability-token-mediated). This matches the gospel intent (proof IS the authority for a theorem) and Module 66 `cp_library_admit` is the capability-bearing ceremony layer above this; flagged as an intentional layering, not a violation. M9 ✓ (verify/get are reversible/read-only; alloc append-only). M11 ✓ (proof terms first-class; carrier binds statement↔proof). M14 ✓ (dependency closure stored + checked — provenance). M18/W35 ✓ (no admit without verified proof term + present deps — the module's reason to exist). M19 ✓ (every op is O(THMC_SLOTS) bounded, no unbounded loop). M20 ✓ (does not reason about its own verifier; `pt_verify` is external + audited per Module 61).

## Implementation Skeleton
```iii
/* III/STDLIB/iii/numera/theorem_carrier.iii
 *
 * III STDLIB - numera::theorem_carrier
 *
 * Theorems as first-class substrate artifacts. A carrier bundles a
 * statement, a VERIFIED proof-term id, a content-addressed carrier id,
 * and the dependency closure (carrier ids this proof cites). M18 binds:
 * no op cites a theorem without its carrier. W35 binds: no theorem
 * without a witnessed proof term -- tc_alloc refuses admission unless
 * pt_verify == 0 and every declared dependency is already resident.
 *
 * Public API: tc_init, tc_alloc, tc_verify, tc_emit_proposed,
 * tc_emit_verified, tc_get_statement, tc_get_proof_term,
 * tc_get_dependencies, tc_pack_alloc_req, tc_kat.
 *
 * Hexad: kind_essence + kind_witness + kind_cognition.  Ring: R0.
 * K: 1.00.  K_theorem: 1.00 once admitted to the library.
 * NIH: identifier.iii, keccak256.iii, proof_term.iii, witness_spine.iii,
 * algebraic_time.iii. Not reentrant (serialized admission ceremony).
 */
module numera_theorem_carrier

extern @abi(c-msvc-x64) fn ident_zero(out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn keccak256_oneshot(msg_ptr: u64, msg_len: u64, out_ptr: u64) -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn pt_verify(term_id: *u8) -> i32 from "proof_term.iii"
extern @abi(c-msvc-x64) fn ws_emit_fragment(producer: *u8, op: *u8, in_commit: *u8, out_commit: *u8, payload: *u8, payload_len: u64, out_fid: *u8) -> i32 from "witness_spine.iii"
extern @abi(c-msvc-x64) fn at_advance() -> u64 from "algebraic_time.iii"

const THMC_OK              : i32 =  0i32
const THMC_E_NULL          : i32 = -1i32
const THMC_E_FULL          : i32 = -2i32
const THMC_E_ABSENT        : i32 = -3i32
const THMC_E_VERIFY_FAIL   : i32 = -4i32
const THMC_E_DEP_ABSENT    : i32 = -5i32
const THMC_E_BUF_TOO_SMALL : i32 = -6i32
const THMC_E_NOT_INITED    : i32 = -7i32
const THMC_E_DUP           : i32 = -8i32

const THMC_SLOTS           : u64 = 16384u64
const THMC_STATEMENT_BYTES : u64 = 1024u64
const THMC_MAX_DEPS        : u64 = 64u64
const THMC_ID_BYTES        : u64 = 32u64
const THMC_DEP_STRIDE      : u64 = 2048u64
const THMC_FRAG_TAG0       : u8  = 0xE3u8
const THMC_FRAG_PROPOSED   : u8  = 0x0Au8
const THMC_FRAG_VERIFIED   : u8  = 0x0Bu8

var THMC_INITED            : u8  = 0u8
var THMC_COUNT             : u64 = 0u64

var THMC_CARRIER_IDS       : [u8; 524288]    // 16384 * 32
var THMC_PROOF_TERM_IDS    : [u8; 524288]
var THMC_STATEMENT_LENS    : [u32; 16384]
var THMC_STATEMENTS        : [u8; 16777216]  // 16384 * 1024
var THMC_DEPENDENCY_COUNTS : [u32; 16384]
var THMC_DEPENDENCIES      : [u8; 33554432]  // 16384 * 64 * 32
var THMC_TIMESTAMPS        : [u64; 16384]    // u64 algebraic-time stamp per slot
var THMC_LIVE              : [u8; 16384]
var THMC_VERIFIED          : [u8; 16384]

var THMC_HASH_OUT          : [u8; 32]        // keccak final scratch (was local -- Trap 7)
var THMC_IDBUF             : [u8; 3104]       // contiguous carrier-id preimage (1024+32+2048)
var THMC_PAYLOAD           : [u8; 2112]       // witness payload (64 + 64*32) (was local -- Trap 7)
var THMC_PRODUCER          : [u8; 32]        // stable producer id for emits (M6)
var THMC_OP_PROPOSED       : [u8; 32]        // stable op-id ident_from_bytes("tc_emit_proposed")
var THMC_OP_VERIFIED       : [u8; 32]        // stable op-id ident_from_bytes("tc_emit_verified")
var THMC_INC               : [u8; 32]        // in-commit scratch
var THMC_OUTC              : [u8; 32]        // out-commit scratch

var THMC_KAT_STMT          : [u8; 16]        // KAT scratch
var THMC_KAT_PTID          : [u8; 32]
var THMC_KAT_DEP           : [u8; 32]
var THMC_KAT_ID            : [u8; 32]
var THMC_KAT_REF           : [u8; 32]
var THMC_KAT_FRAG          : [u8; 32]
var THMC_KAT_OUT           : [u8; 1024]

fn tc_init() -> i32 @export { /* TODO: body per Algorithm tc_init (zero LIVE/VERIFIED, set op-ids + producer once, idempotent guard) */ }

fn tc_find_slot(carrier_id: *u8) -> i64 { /* TODO: sentinel-scan LIVE && ident_eq; return i as i64 or -1i64 (W14/Trap3) */ }

fn tc_alloc(req: *u8, out_carrier_id: *u8) -> i32 @export { /* TODO: read aggregate (byte-wise), pt_verify first, dep-closure check, statement_len<=1024 guard, oneshot id into THMC_HASH_OUT, dup-guard (THMC_E_DUP), claim free slot, commit, at_advance() timestamp */ }

fn tc_verify(carrier_id: *u8) -> i32 @export { /* TODO: find slot, re-pt_verify stored ptid, re-check deps present, set VERIFIED */ }

fn tc_emit_proposed(carrier_id: *u8, out_frag_id: *u8) -> i32 @export { /* TODO: build THMC_PAYLOAD (E3 0A || id || ptid, 72B), emit with THMC_PRODUCER/THMC_OP_PROPOSED */ }

fn tc_emit_verified(carrier_id: *u8, out_frag_id: *u8) -> i32 @export { /* TODO: require VERIFIED==1, build payload (E3 0B || id || ptid || dc(LE u8x4) || deps), plen=80+dc*32, emit with THMC_OP_VERIFIED */ }

fn tc_get_statement(carrier_id: *u8, out_buf: *u8, out_cap: u32, out_len: *u32) -> i32 @export { /* TODO: find slot, out_cap<len -> THMC_E_BUF_TOO_SMALL, copy len bytes, *out_len=len */ }

fn tc_get_proof_term(carrier_id: *u8, out_term_id: *u8) -> i32 @export { /* TODO: find slot, ident_copy stored ptid -> out_term_id */ }

fn tc_get_dependencies(carrier_id: *u8, out_buf: *u8, out_cap: u32, out_count: *u32) -> i32 @export { /* TODO: find slot, mask dc, out_cap<dc*32 -> THMC_E_BUF_TOO_SMALL, copy dc*32 bytes, *out_count=dc */ }

fn tc_pack_alloc_req(req_out: *u8, statement: *u8, statement_len: u32, ptids_and_deps: *u8) -> i32 @export { /* TODO: write LE aggregate header into req_out (statement_len, stmt ptr, ptid ptr, dep ptr, dep_count) */ }

fn tc_kat() -> u64 @export { /* TODO: Tier-A KATs 1-5 (not-inited, id determinism + dup, round-trip, dep-absent negative, buf-too-small); return 99u64 on pass */ }
```
