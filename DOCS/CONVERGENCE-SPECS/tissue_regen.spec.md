# 43 aether/tissue_regen.iii — Implementation Spec

## Verdict
**PARTIAL** — the gospel's candidate `.iii` body is structurally close to house idiom and its real-substrate externs (`ident_from_bytes`/`ident_copy`/`wh_publish`/`wh_chain_root`) match the realized signatures exactly, BUT it (a) is built on **three fictional dependency surfaces that the gospel never defines anywhere** — `fs_scrub_block` (claimed `from "fs.iii"`; the real `fs.iii` is a POSIX-style cap-gated IO module with no scrubber), `bone_marrow.iii` (`bm_scrub`/`bm_recover`/`bm_verify_block`), and `quine_verifier.iii` (`qv_verify`); (b) uses **function-local `var` arrays** (Trap 7) that iiis-0 cannot compile; (c) uses the `&ARR[expr]` element-address form the realized exemplars avoid; and (d) leaves the M8 capability gate, M9 reversibility contract, and tier-2/3 verification semantics underspecified. The escalation skeleton (Tier 1 → 2 → 3, witnessed per step) is the correct maximal design and is retained; the gaps below close it.

## Purpose
`aether::tissue_regen` is the **three-tier corruption-recovery organ** of the substrate: when the immune scrubber (Module 42) detects damage exceeding the per-codeword Reed–Muller correction capacity of a block, the regenerator escalates deterministically — Tier 1 in-place Reed–Muller re-scrub, Tier 2 bone-marrow Reed–Solomon stripe reconstruction, Tier 3 source-seed recompilation via the quine verifier + pure code generator — and **witnesses every escalation step** (input damage assessment + output redundancy state) so the federation can trace exactly which redundancy mechanism repaired the system. Hexad: **kind_repair + kind_witness**. Ring: **R−1**. K: **1.00**.

## Public API
```
fn tr_init() -> i32 @export
fn tr_register_region(region_id: u32, file_id: u32, stripe_id: u32, module_id: *u8) -> i32 @export
fn tr_recover(cap_id: u64, region_id: u32, block_idx: u32, out_tier: *u32) -> i32 @export
```
Plus three exported observers/utilities added to satisfy M9 reversibility, M10 witness reproducibility, and the Phase-2 acceptance gate (all W12 status-returning):
```
fn tr_last_tier() -> u32 @export
fn tr_recover_count(tier: u32) -> u64 @export
fn tr_selftest() -> u64 @export
```

Return-status conventions:
- `tr_init`, `tr_register_region` → `i32`, `TR_OK` (0) / negative error (W9). `tr_register_region` returns `TR_E_BAD` (−1) for out-of-range `region_id`, `TR_E_NULL` (−2) for a null `module_id`.
- `tr_recover` → `i32` status (W9/W12): `TR_OK` (0) on a tier success **or** clean no-success, negative on a precondition failure (`TR_E_BAD` unknown/dead region, `TR_E_NULL` null `out_tier`, `TR_E_DENIED` capability check failed). The repairing tier (1/2/3, or **0 = no tier succeeded**) is written to `*out_tier`. **API CHANGE FROM GOSPEL:** the gospel returned the tier directly as `u32` with `0 = failure`, conflating "ran but couldn't repair" with "bad arguments." The realized form returns an `i32` status and writes the tier through `out_tier`, so a caller can distinguish *refusal* (negative, M5/M8) from *exhaustion* (`TR_OK`, `*out_tier == 0`). It also adds the leading `cap_id: u64` required by M8 (the destructive Tier-2/Tier-3 escalation is privileged). Param count = 4 (W2 OK).
- `tr_last_tier` → `u32` last repairing tier (0–3) for the most recent `tr_recover`.
- `tr_recover_count` → `u64` lifetime count of recoveries that succeeded at `tier` (tier ∈ {1,2,3}; any other → 0). Pure observer.
- `tr_selftest` → `u64`, `99u64` = pass, any other value = the failing checkpoint (house convention).

## Constant Namespace
PREFIX = `TREGEN_`  — **grep of `STDLIB/` returned no match** for `TREGEN_`, `aether_tissue_regen`, or any `tr_` function; **no collision**. (Note: the gospel body used the bare `TR_` prefix for its consts, e.g. `TR_OK`. Per Trap 2, module-level `const` is linker-global; `TR_` is short and collision-prone across a 68-module link. This spec adopts the dispatched **`TREGEN_`** prefix on every const. Functions keep the `tr_` prefix — function symbols are namespaced by the C-ABI export name and the gospel/exemplars use the short verb prefix; `tr_*` is unique per the grep.)

Module-level constants:
```
const TREGEN_OK          : i32 =  0i32
const TREGEN_E_BAD       : i32 = -1i32   // unknown / dead region
const TREGEN_E_NULL      : i32 = -2i32   // null out_tier or module_id
const TREGEN_E_DENIED    : i32 = -3i32   // capability rights insufficient (M8/M5)
const TREGEN_MAX_REGIONS : u32 = 64u32   // W8 bound: matches immune_scrub IS_MAX_REGIONS (64); 1:1 region registry across the two organs
const TREGEN_BM_K        : u32 = 8u32    // bone-marrow stripe data-block count (RS(k=8); gospel's BM_K)
const TREGEN_ID_LEN      : u64 = 32u64   // canonical identifier length (numera::identifier = 256-bit)
const TREGEN_RIGHTS      : u64 = 0x0410u64 // CAP_RIGHT_AMEND(0x4000)? -- see Dependencies note; value = FS_DELETE|PERSIST_WRITE composite, finalized in skeleton
```
(`TREGEN_RIGHTS` is the required-rights mask for the destructive escalation; its exact bit value is pinned in the Dependencies section against the real `capability.iii` constants — `CAP_RIGHT_PERSIST_WRITE (0x0400) | CAP_RIGHT_AMEND (0x4000)` = `0x4400u64`. The placeholder above is corrected to `0x4400u64` in the skeleton.)

## Data Structures
All buffers are **module-scope** (Trap 7: iiis-0 has no function-local `var` arrays). Bounds justified per W8.

| Name | Type | Size | Bound justification |
|------|------|------|---------------------|
| `TREGEN_LIVE`      | `[u8; 64]`   | 64 | one liveness flag per region; W8 bound = `TREGEN_MAX_REGIONS` |
| `TREGEN_FILE_ID`   | `[u32; 64]`  | 64 | fs file id per region |
| `TREGEN_STRIPE_ID` | `[u32; 64]`  | 64 | bone-marrow stripe id per region |
| `TREGEN_MODULE_ID` | `[u8; 2048]` | 64×32 | one 32-byte module identifier per region (Tier-3 recompile target) |
| `TREGEN_PRODUCER`  | `[u8; 32]`   | 32 | producer id (this organ), hashed once in `tr_init` |
| `TREGEN_OPID_T1`   | `[u8; 32]`   | 32 | op id "tier1" |
| `TREGEN_OPID_T2`   | `[u8; 32]`   | 32 | op id "tier2" |
| `TREGEN_OPID_T3`   | `[u8; 32]`   | 32 | op id "tier3" |
| `TREGEN_CNT_T1`    | `u64`        | 1  | lifetime tier-1 successes (M-observable; NOT a learning signal — see M3 note) |
| `TREGEN_CNT_T2`    | `u64`        | 1  | lifetime tier-2 successes |
| `TREGEN_CNT_T3`    | `u64`        | 1  | lifetime tier-3 successes |
| `TREGEN_LAST_TIER` | `u32`        | 1  | tier of the most recent `tr_recover` |
| `TREGEN_INITED`    | `u8`         | 1  | one-time init guard |
| **scratch (hoisted from gospel function-locals — Trap 7 fix):** | | | |
| `TREGEN_IN_C`      | `[u8; 32]`   | 32 | witness `in_commit` (was `var in_c` in `tr_publish_tier`) |
| `TREGEN_OUT_C`     | `[u8; 32]`   | 32 | witness `out_commit` (was `var out_c`) |
| `TREGEN_PL`        | `[u8; 9]`    | 9  | witness payload: region_id(4) ‖ block_idx(4) ‖ ok(1) (was `var pl`) |
| `TREGEN_FID`       | `[u8; 32]`   | 32 | fragment-id sink (was `var fid`) |

**Reentrancy note:** the hoisted scratch makes `tr_publish_tier` / `tr_recover` non-reentrant (single-threaded scrub→regen pipeline; acceptable, matches `witness_hook.iii` and `merkle.iii` house practice). Flag for Phase-2: the scrub/regen organs run on one deterministic walker thread (M2); concurrent `tr_recover` is out of scope.

## Dependencies (externs)
Read the **real** provider file before declaring each extern (gospel externs are unreliable, §3.5).

**EXIST in the realized tree (verified):**
```
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"   // numera/identifier.iii (Module 01) — VERIFIED line 33
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"                          // VERIFIED line 65
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"  // aether/witness_hook.iii (Module 07) — VERIFIED signature byte-for-byte (lines 144-148)
extern @abi(c-msvc-x64) fn wh_chain_root(out_id: *u8) -> i32 from "witness_hook.iii"                            // VERIFIED line 216
extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"                // aether/capability.iii — VERIFIED; rights bits PERSIST_WRITE=0x0400, AMEND=0x4000
```
The gospel's `wh_publish`/`wh_chain_root`/`ident_*` externs were **correct** — no §3.5 defect on those. (Notably the gospel already routes fragment emission through `wh_publish`, not the fictional `ws_emit_fragment`; §3.5-2 does not apply.)

**NOT-YET-BUILT (parallel/unscheduled) — the wave scheduler must order these BEFORE Module 43:**
```
extern @abi(c-msvc-x64) fn is_scrub_block(file_id: u32, block_idx: u32) -> u32 from "immune_scrub.iii"   // Tier-1 RM re-scrub — SEE FICTION NOTE
extern @abi(c-msvc-x64) fn bm_recover(stripe_id: u32, lost_mask: u64) -> i32 from "bone_marrow.iii"      // Tier-2 RS reconstruct — MODULE DOES NOT EXIST IN GOSPEL
extern @abi(c-msvc-x64) fn bm_verify_block(stripe_id: u32, idx: u32) -> u8 from "bone_marrow.iii"        // Tier-2 post-recovery verify — DOES NOT EXIST
extern @abi(c-msvc-x64) fn qv_verify_module(module_id: *u8) -> u8 from "quine_verifier.iii"              // Tier-3 seed verify — DOES NOT EXIST
```

**FICTION / DEFECT FLAGS (the load-bearing finding of this audit):**
1. **`fs_scrub_block` is a gospel fiction.** Both Module 42 and Module 43 declare `extern fs_scrub_block ... from "fs.iii"`, but the realized `aether/fs.iii` is a POSIX-style capability-gated IO surface (`fs_open/read/write/close/seek/tell/size`); it has **no** Reed–Muller scrub function. The Tier-1 re-scrub primitive must live with the immune scrubber, not fs. **Re-route to `is_scrub_block` exported by Module 42 (`immune_scrub.iii`).** This requires Module 42 to expose a per-block scrub entry (it currently exposes `is_scrub_step`/`is_run_full_pass`, which walk the Hilbert curve, plus the same fictional `fs_scrub_block` extern). **Coordination item for Module 42's spec:** add `is_scrub_block(file_id, block_idx) -> u32` (errors-corrected count) as the shared RM primitive, and have BOTH organs call it; the actual Reed–Muller codeword decode belongs in a real provider (candidate: a new `numera/reed_muller.iii` or inside `immune_scrub.iii`). This is a **systemic gospel defect** in the Module 42/43 pair — neither compiles as written.
2. **`bone_marrow.iii` does not exist** anywhere in the gospel (no section header; 0 definitions). Module 43 invents `bm_scrub`/`bm_recover`/`bm_verify_block`. Tier 2 cannot be realized until a `bone_marrow.iii` (Reed–Solomon stripe redundancy, k=8 data + parity) is authored. Marked not-yet-built; **Phase-2 blocker**.
3. **`quine_verifier.iii` does not exist** anywhere in the gospel (0 definitions). Tier 3 (`qv_verify`) likewise has no provider, and the "recompile via cg_pure" target `cg_pure.iii` is **also absent**. Marked not-yet-built; **Phase-2 blocker**. (The gospel's `qv_verify()` took no args and verified an implicit global target; the realized form should take the `module_id` so the verify is scoped to the corrupted region — renamed `qv_verify_module(module_id)`.)
4. **Unused gospel extern `bm_scrub`** — declared but never called in the gospel body; dropped.

## Algorithm

### `tr_init() -> i32`
1. Zero `TREGEN_LIVE[0..64]`, zero `TREGEN_CNT_T1/T2/T3`, `TREGEN_LAST_TIER = 0`.
2. Hash the four fixed strings into their id buffers via `ident_from_bytes` (keccak256-256, deterministic — M2): producer `"aether::tissue_regen"` (len 20), op ids `"aether::tissue_regen::tier1|tier2|tier3"` (len 27 each).
3. `TREGEN_INITED = 1`; return `TREGEN_OK`. **Determinism (M2):** identifiers are pure keccak256 over fixed ASCII; bit-identical every run (W5).

### `tr_register_region(region_id, file_id, stripe_id, module_id) -> i32`
1. If `module_id == 0` (null) → `TREGEN_E_NULL`. (M5: never store a null target.)
2. If `region_id >= TREGEN_MAX_REGIONS` (u32 unsigned compare — Trap 3 does **not** apply) → `TREGEN_E_BAD`.
3. Store `file_id`, `stripe_id`; `ident_copy(module_id, &TREGEN_MODULE_ID[region_id*32])`; set `TREGEN_LIVE[region_id]=1`. Return `TREGEN_OK`. Idempotent re-registration overwrites (M9: reversible — the registry is data, not a destructive act).

### `tr_recover(cap_id, region_id, block_idx, out_tier) -> i32` — the escalation engine
**Preconditions (M5/M8 refusal before any destructive act):**
1. If `out_tier == 0` (null) → `TREGEN_E_NULL`.
2. If `region_id >= TREGEN_MAX_REGIONS` or `TREGEN_LIVE[region_id]==0` → set `*out_tier=0`, return `TREGEN_E_BAD`.
3. **M8 capability gate:** `if cap_verify_rights(cap_id, 0x4400u64) != 1u8` → set `*out_tier=0`, return `TREGEN_E_DENIED`. (Tier-2 RS reconstruction overwrites a stripe member and Tier-3 recompiles a module image — both are `PERSIST_WRITE | AMEND` privileged. Tier-1 re-scrub is in-place RM correction and is itself reversible, but the *escalation decision* is gated as a unit so a caller without amend rights cannot trigger any write-back.)

**Tier 1 — Reed–Muller in-place re-scrub (reversible, M9):**
4. `let first : u32 = is_scrub_block(TREGEN_FILE_ID[region_id], block_idx)` then `let second : u32 = is_scrub_block(...)`. RM majority-vote decode always writes back the voted codeword; the **stability test** is the failure detector: a block correctable within capacity (≤3 errors for RM(2,5)) yields `second == 0` (no residual errors on the re-pass). `first` is bound to a local (consumed in the witness payload via the recompute path, see M10) — assigning both to named locals also dodges Trap 11 (no `% ` after the call) and the param-spill family.
5. If `second == 0u32`: `tr_publish_tier(region_id, block_idx, T1, ok=1)`; `TREGEN_CNT_T1 += 1`; `TREGEN_LAST_TIER=1`; `*out_tier=1`; return `TREGEN_OK`.

**Tier 2 — bone-marrow Reed–Solomon stripe recovery (M9 — additive reconstruction):**
6. `let stripe : u32 = TREGEN_STRIPE_ID[region_id]`. Compute the in-stripe position with a **byte-mask, not modulo** (Trap 11): `let bm_idx : u32 = block_idx & (TREGEN_BM_K - 1u32)` — valid because `BM_K = 8` is a power of two (`& 7`). `let lost_mask : u64 = 1u64 << (bm_idx as u64)`.
7. `if bm_recover(stripe, lost_mask) == 0i32` (compare to the 0 success sentinel by equality — W11): then `if bm_verify_block(stripe, bm_idx) == 1u8` → publish T2 ok=1; `TREGEN_CNT_T2 += 1`; `TREGEN_LAST_TIER=2`; `*out_tier=2`; return `TREGEN_OK`. RS over GF(2^8) reconstructs the lost data symbol exactly from k surviving symbols (M15 algebraic determinism); the post-recovery `bm_verify_block` re-checks the RS syndrome = 0 (M12 verifiable artifact).

**Tier 3 — source-seed recompilation (M12 certificate; M5 abort-on-bad-seed):**
8. `if qv_verify_module(&TREGEN_MODULE_ID[region_id*32]) == 1u8`: the seed is authentic against the quine target (the recompile is then performed by the cg_pure pillar — out of this module's scope; this organ records the witness of the regeneration event). Publish T3 ok=1; `TREGEN_CNT_T3 += 1`; `TREGEN_LAST_TIER=3`; `*out_tier=3`; return `TREGEN_OK`. **M5:** if the seed itself fails verification, we do **not** recompile from a corrupt seed (that could brick) — fall through.
9. **Exhaustion:** publish T3 ok=0 (records the unrecoverable assessment for federation correlation — M16); `TREGEN_LAST_TIER=0`; `*out_tier=0`; return `TREGEN_OK` (clean "ran, no tier succeeded" — distinct from the negative refusal codes).

**No recursion (W15):** the three tiers are a straight-line `if` cascade with early return — no loop, no stack needed. **No `break` (W14):** none used. **M3 (no ML):** the tier choice is a fixed deterministic cascade keyed on exact algebraic success sentinels (`second==0`, `bm_recover==0`, `qv==1`); the `TREGEN_CNT_*` counters are **append-only observability metrics that never feed back into any decision** — they are read only by `tr_recover_count`, never compared to a threshold (explicitly NOT count-and-promote).

### `tr_publish_tier(region_id, block_idx, opid, ok) -> i32` (internal, W2 = 4 params)
1. `wh_chain_root(&TREGEN_IN_C)` — in_commit = current chain root (M6 chaining).
2. Build `TREGEN_PL` (9 bytes): little-endian `region_id`(4) ‖ `block_idx`(4) ‖ `ok`(1).
3. `ident_from_bytes(&TREGEN_PL, 9, &TREGEN_OUT_C)` — out_commit = keccak256 of the damage/result tuple (M10: recomputable byte-identically from the recorded payload).
4. `wh_publish(&TREGEN_PRODUCER, opid, &TREGEN_IN_C, &TREGEN_OUT_C, revtag=0, phase=8, pillar=4, antecedents=&TREGEN_PL, n_ante=0, payload=&TREGEN_PL, payload_len=9, &TREGEN_FID)`. The hook computes the fragment id (keccak256 over all fields), advances algebraic time exactly once (W17 monotone), appends to the log. **revtag=0** marks a non-reversible-flagged informational fragment (the repair event); this matches `immune_scrub`'s pass-witness convention. Return `TREGEN_OK`. **M10:** every OK witness is recomputable — producer/opid are fixed ids, in_commit is the chain root at publish time, out_commit and payload are pure functions of (region_id, block_idx, ok).

### `tr_last_tier`, `tr_recover_count`, `tr_selftest`
- `tr_last_tier` returns `TREGEN_LAST_TIER`.
- `tr_recover_count(tier)`: `if tier==1 return TREGEN_CNT_T1` … else `0`.
- `tr_selftest`: see KAT vectors; drives a stub-free path against test doubles for the not-yet-built deps (Phase-2 supplies real providers).

## KAT Vectors (>= 3)
The not-yet-built Tier-2/Tier-3 providers are exercised in Phase 2 via deterministic test doubles (`bm_recover`/`bm_verify_block`/`qv_verify_module`/`is_scrub_block` linked to fixed-return fakes). KATs assert byte-exact control flow + witness state.

1. **Identifier determinism (no external deps).** After `tr_init()`, `TREGEN_PRODUCER` = `keccak256("aether::tissue_regen")` (20 bytes in). Expected first 4 bytes are fixed by keccak256-256 of that exact ASCII; the KAT pins the full 32-byte digest (computed once by the Phase-2 author from the realized `keccak256_oneshot`) and checks `ident_from_bytes` reproduces it byte-for-byte across two runs (M2/M10). Also `TREGEN_OPID_T1 != TREGEN_OPID_T2 != TREGEN_OPID_T3` (distinct ids).

2. **Tier-1 success path + witness.** `wh_init(0)`; `tr_init()`; register region 0 (file_id=7, stripe_id=0, module_id=fixed 32B). Test double: `is_scrub_block` returns `5` on its 1st call, `0` on its 2nd (correctable). `cap_id` = a cap holding `0x4400`. Call `tr_recover(cap, 0, 0, &out)`. Expect: return `TREGEN_OK`, `out == 1`, `tr_last_tier()==1`, `tr_recover_count(1)==1`, `tr_recover_count(2)==0`, `wh_next_idx()==1` (exactly one fragment), `at_current()==1` (time advanced once).

3. **Tier-2 escalation.** `is_scrub_block` returns `4` on both calls (Tier-1 fails). `bm_recover` returns `0i32` (success), `bm_verify_block` returns `1u8`. Call with `block_idx=10` → `bm_idx = 10 & 7 = 2`, `lost_mask = 1<<2 = 4`. Expect: `TREGEN_OK`, `out==2`, `tr_last_tier()==2`, `tr_recover_count(2)==1`, one new fragment whose payload byte[8] (`ok`)==1 and bytes[0..4] little-endian == `0` (region_id), bytes[4..8] == `10` (block_idx).

4. **Capability refusal (M8/M5).** `cap_id` = a cap WITHOUT the `0x4400` rights (e.g. read-only). `tr_recover(cap, 0, 0, &out)` → expect return `TREGEN_E_DENIED`, `out==0`, **no** new fragment (`wh_next_idx()` unchanged), `at_current()` unchanged, `tr_recover_count(*)` all unchanged. (Proves the negative case: the gate FAILS closed, no witness, no time advance.)

5. **Exhaustion path.** Tier-1 fails (`is_scrub_block`→4,4), Tier-2 fails (`bm_recover`→ `-1i32`), Tier-3 fails (`qv_verify_module`→ `0u8`). Expect: return `TREGEN_OK`, `out==0`, `tr_last_tier()==0`, one fragment published with payload `ok`-byte==0 (the recorded unrecoverable assessment), all `tr_recover_count` still 0.

`tr_selftest()` chains KATs 2–5 and returns `99u64` on full pass, else the failing checkpoint number.

## Trap Exposure
- **Trap 1 (multi-line `fn`)** — EXPOSED (every signature). Avoidance: all signatures single-line, including the 4-param `tr_recover` and `tr_publish_tier`. The gospel's `tr_register_region`/`tr_publish_tier` were already 1-line in the body but the doc-comment wrapped them; the skeleton emits them single-line.
- **Trap 2 (const linker-global)** — EXPOSED. Avoidance: `TREGEN_` prefix on **every** const (gospel used the too-short `TR_`, a collision risk across 68 modules); grep-confirmed unique.
- **Trap 3 (signed ordering SIGSEGV)** — NOT EXPOSED. Every compare is on `u32`/`u64` (unsigned) or equality on `i32` sentinels (`== 0i32`, `== -1i32` via `bm_recover`). No `< / <= / >= / >` on any signed `i32`/`i64`. (The `region_id >= TREGEN_MAX_REGIONS` compare is u32-unsigned — safe.)
- **Trap 4 (u32-in-u64-slot garbage before ptr math)** — EXPOSED in `tr_module_ptr`/all id-buffer addressing. Avoidance: index expressions cast to `u64` and the array base is taken as `(&TREGEN_MODULE_ID as u64)` then offset is `(region_id as u64) * 32u64` — masking is unnecessary here because `region_id < 64` is already bounded and the multiply is in u64, but the skeleton uses the exemplar's `((&ARR as u64) + (idx as u64)*32u64) as *u8` form (see Trap below) which keeps all arithmetic in u64.
- **Trap 5 (u32 pointer store width)** — NOT EXPOSED. All multi-byte writes are byte-by-byte through `*u8` (`TREGEN_PL[k] = (...) as u8`), exactly as the gospel/exemplars do; no `*u32`-pointer stores.
- **Trap 6 (nested block comments)** — avoid; only `//` and non-nested `/* */`.
- **Trap 7 (local `var` arrays)** — **EXPOSED — primary gospel bug.** The gospel's `tr_publish_tier` declares `var in_c`/`var out_c`/`var pl`/`var fid` as function-locals; iiis-0 only parses `var` arrays at module scope. Avoidance: hoist all four to module-scope (`TREGEN_IN_C/OUT_C/PL/FID`), per `witness_hook.iii` (`WH_TMP16`…) and `merkle.iii` (`MK_HASH_BUF`). Documented non-reentrancy.
- **Trap 8 (`} else {` one line)** — the cascade uses early returns, minimal `else`; any `else` is single-line.
- **Trap 9 (em-dash in comment)** — use ASCII `--` only in all comments (this spec's skeleton comments are ASCII).
- **Trap 10 (`let mut` checkpoint flag)** — avoided: the tier cascade uses early-return, not a mutated success flag.
- **Trap 11 (`a % b` after a call returns quotient/stale divisor)** — **EXPOSED.** Tier-2 needs `block_idx mod BM_K`. `BM_K=8` is a power of two → use the byte-mask `block_idx & (TREGEN_BM_K - 1u32)` (`& 7u32`), never `%`. (The gospel already did `block_idx & 7u32` — correct; the spec keeps it and derives the mask from the named const.)
- **Trap 12 (`@specialize *T` stride)** — NOT EXPOSED (no generics).
- **`&ARR[expr]` element-address form** — the gospel uses `&TR_MODULE_ID[(r as u64)*32u64]` and `&in_c[0u64]`; the realized exemplars (`witness_hook.iii` reconciliation note, `merkle.iii`) deliberately use `((&ARR as u64)+off) as *u8` instead because the `&ARR[expr]` lvalue-address form is fragile in iiis. The skeleton adopts the exemplar form throughout.

## Gap / Fix List (PARTIAL)
1. **Fictional `fs_scrub_block` (CRITICAL).** Provider `fs.iii` has no scrubber. **Fix:** re-route Tier-1 to `is_scrub_block(file_id, block_idx)` exported by `immune_scrub.iii` (Module 42); coordinate with Module 42's spec to add that export (and to drop its own identical `fs_scrub_block` fiction). The underlying Reed–Muller codeword decode must be authored in a real provider (recommend `numera/reed_muller.iii` or inline in immune_scrub). **Wave order:** 42 (+ RM provider) before 43.
2. **Fictional `bone_marrow.iii` (CRITICAL).** No gospel section defines it. **Fix:** Phase 2 must author `aether/bone_marrow.iii` (Reed–Solomon GF(2^8), k=8 data symbols + parity, `bm_recover`/`bm_verify_block`) before Tier-2 is live. Externs declared here as not-yet-built.
3. **Fictional `quine_verifier.iii` + `cg_pure.iii` (CRITICAL).** No gospel sections. **Fix:** Phase 2 authors `quine_verifier.iii` (`qv_verify_module(module_id) -> u8`) and the Tier-3 recompile path lands in `cg_pure.iii`. Externs declared not-yet-built. Renamed `qv_verify` → `qv_verify_module` to scope verification to the corrupted region's seed (M12).
4. **M8 capability gate MISSING in gospel.** The gospel's `tr_recover` performs destructive Tier-2/Tier-3 escalation with **no capability argument** — a direct M8 violation. **Fix:** added `cap_id: u64` first param + `cap_verify_rights(cap_id, 0x4400u64)` gate (PERSIST_WRITE|AMEND); refuse with `TREGEN_E_DENIED` (M5 fail-closed). KAT 4 proves the negative case.
5. **Tier/error conflation in gospel return (M5).** Gospel returned `u32` tier with `0` overloaded for both "no tier succeeded" and (implicitly) bad args. **Fix:** `i32` status return + `out_tier` out-param; negative = refusal, `TREGEN_OK` + `*out_tier∈{0,1,2,3}` = ran.
6. **Trap 7 local `var` arrays.** Hoisted to module scope (see Data Structures).
7. **Const prefix too short (Trap 2).** `TR_` → `TREGEN_` on all consts.
8. **`&ARR[expr]` addressing fragility.** Switched to `((&ARR as u64)+off) as *u8` exemplar form.
9. **Unused extern `bm_scrub`.** Dropped (declared, never called).
10. **Null `module_id` unchecked in gospel `tr_register_region`.** Added `TREGEN_E_NULL` guard (M5).
11. **Witness payload provenance (M10/M16).** Gospel published `ok` but the audit pins the exact 9-byte payload layout and confirms out_commit = keccak256(payload) so every fragment is independently recomputable; tier identity carried by the distinct op-id, not the payload (correlatable across the federation — M16).
12. **No reversibility metadata for Tier 2/3 (M9).** Tier 2 (RS reconstruction) and Tier 3 (recompile) are *additive/regenerative*, not destructive overwrites of unique data — the original is recomputed, so the operation is information-preserving (M9 satisfied by construction). The witness records the pre-state chain root (in_commit) so the transition is anchored and ratifiable (M16). Documented; no code change needed beyond the witness already emitted.

**Mandate/law compliance summary:** M1 (NIH — all hand-rolled, only identifier/witness/cap/RS/RM substrate deps), M2 (deterministic — keccak ids, algebraic tier cascade, no FP), M3 (no ML — counters are inert observability, never thresholded), M4 (exact sentinels, no heuristics), M5 (fail-closed refusal, no bricking — bad seed never recompiled), M6/M10/M16 (witnessed, recomputable, anchored), M8 (cap-gated), M9 (regenerative/reversible), M12 (RS syndrome + quine verify are checkable certificates), M15 (RS over GF(2^8) total/deterministic). W2 (≤4 params all fns), W8 (64-region bound justified), W9/W10/W12 (neg-i32 errors, u8 bools, status returns), W11 (equality compares only), W14 (no break), W15 (no recursion), W17 (time monotone via hook).

## Implementation Skeleton
```iii
/* III/STDLIB/iii/aether/tissue_regen.iii
 *
 * III STDLIB - aether::tissue_regen
 *
 * Three-tier corruption recovery organ:
 *   Tier 1: Reed-Muller in-place re-scrub (is_scrub_block; reversible)
 *   Tier 2: bone-marrow Reed-Solomon stripe recovery (bm_recover)
 *   Tier 3: source-seed recompilation gate (qv_verify_module)
 * Every escalation step is witnessed via wh_publish (input damage
 * assessment + output redundancy state). Destructive escalation is
 * capability-gated (M8). Hexad: kind_repair + kind_witness. Ring R-1. K 1.00.
 *
 * NOTE: Tier-1 routes to immune_scrub::is_scrub_block (the gospel's
 * fs_scrub_block does not exist in the realized fs.iii). bone_marrow.iii
 * and quine_verifier.iii are NOT-YET-BUILT -- see tissue_regen.spec.md.
 */
module aether_tissue_regen

extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn cap_verify_rights(id: u64, required: u64) -> u8 from "capability.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_chain_root(out_id: *u8) -> i32 from "witness_hook.iii"
// NOT-YET-BUILT deps (wave scheduler: order these before Module 43):
extern @abi(c-msvc-x64) fn is_scrub_block(file_id: u32, block_idx: u32) -> u32 from "immune_scrub.iii"
extern @abi(c-msvc-x64) fn bm_recover(stripe_id: u32, lost_mask: u64) -> i32 from "bone_marrow.iii"
extern @abi(c-msvc-x64) fn bm_verify_block(stripe_id: u32, idx: u32) -> u8 from "bone_marrow.iii"
extern @abi(c-msvc-x64) fn qv_verify_module(module_id: *u8) -> u8 from "quine_verifier.iii"

const TREGEN_OK          : i32 =  0i32
const TREGEN_E_BAD       : i32 = -1i32
const TREGEN_E_NULL      : i32 = -2i32
const TREGEN_E_DENIED    : i32 = -3i32
const TREGEN_MAX_REGIONS : u32 = 64u32
const TREGEN_BM_K        : u32 = 8u32
const TREGEN_ID_LEN      : u64 = 32u64
const TREGEN_RIGHTS      : u64 = 0x4400u64   // CAP_RIGHT_PERSIST_WRITE(0x0400) | CAP_RIGHT_AMEND(0x4000)

var TREGEN_LIVE      : [u8;  64]
var TREGEN_FILE_ID   : [u32; 64]
var TREGEN_STRIPE_ID : [u32; 64]
var TREGEN_MODULE_ID : [u8;  2048]   // 64 * 32
var TREGEN_PRODUCER  : [u8; 32]
var TREGEN_OPID_T1   : [u8; 32]
var TREGEN_OPID_T2   : [u8; 32]
var TREGEN_OPID_T3   : [u8; 32]
var TREGEN_CNT_T1    : u64 = 0u64
var TREGEN_CNT_T2    : u64 = 0u64
var TREGEN_CNT_T3    : u64 = 0u64
var TREGEN_LAST_TIER : u32 = 0u32
var TREGEN_INITED    : u8 = 0u8
// hoisted scratch (Trap 7: no function-local var arrays)
var TREGEN_IN_C      : [u8; 32]
var TREGEN_OUT_C     : [u8; 32]
var TREGEN_PL        : [u8; 9]
var TREGEN_FID       : [u8; 32]

fn tr_module_ptr(r: u32) -> *u8 { return ((&TREGEN_MODULE_ID as u64) + (r as u64) * 32u64) as *u8 }

fn tr_init() -> i32 @export {
    // TODO: body per Algorithm tr_init -- zero LIVE[0..64], zero CNT_*, LAST_TIER=0,
    //       ident_from_bytes the producer + 3 op-ids, set INITED=1, return TREGEN_OK
}

fn tr_register_region(region_id: u32, file_id: u32, stripe_id: u32, module_id: *u8) -> i32 @export {
    // TODO: body per Algorithm tr_register_region -- null guard, range guard (u32),
    //       store file/stripe, ident_copy module_id -> tr_module_ptr, LIVE=1
}

fn tr_publish_tier(region_id: u32, block_idx: u32, opid: *u8, ok: u8) -> i32 {
    // TODO: body per Algorithm tr_publish_tier -- wh_chain_root -> TREGEN_IN_C,
    //       pack TREGEN_PL (region_id LE | block_idx LE | ok), ident_from_bytes -> TREGEN_OUT_C,
    //       wh_publish(PRODUCER, opid, IN_C, OUT_C, 0,8,4, PL,0, PL,9, FID)
}

fn tr_recover(cap_id: u64, region_id: u32, block_idx: u32, out_tier: *u32) -> i32 @export {
    // TODO: body per Algorithm tr_recover --
    //   precond: null out_tier -> E_NULL; range/LIVE -> E_BAD (set *out_tier=0);
    //            cap_verify_rights(cap_id, TREGEN_RIGHTS) != 1 -> E_DENIED (*out_tier=0)
    //   Tier1: is_scrub_block x2; if second==0 -> publish T1 ok=1, CNT_T1++, *out_tier=1, OK
    //   Tier2: bm_idx = block_idx & (TREGEN_BM_K - 1u32); lost = 1<<bm_idx;
    //          if bm_recover==0i32 && bm_verify_block==1u8 -> publish T2 ok=1, CNT_T2++, *out_tier=2, OK
    //   Tier3: if qv_verify_module(tr_module_ptr(region_id))==1u8 -> publish T3 ok=1, CNT_T3++, *out_tier=3, OK
    //   else: publish T3 ok=0; LAST_TIER=0; *out_tier=0; return TREGEN_OK
}

fn tr_last_tier() -> u32 @export {
    // TODO: return TREGEN_LAST_TIER
}

fn tr_recover_count(tier: u32) -> u64 @export {
    // TODO: tier==1 -> CNT_T1 ; ==2 -> CNT_T2 ; ==3 -> CNT_T3 ; else 0u64
}

// ---- self-test (99 = pass) ---- (Phase 2 links deterministic test doubles for the not-yet-built deps)
fn tr_selftest() -> u64 @export {
    // TODO: body per KAT Vectors 2-5 -- returns 99u64 on full pass, else failing checkpoint
}
```
