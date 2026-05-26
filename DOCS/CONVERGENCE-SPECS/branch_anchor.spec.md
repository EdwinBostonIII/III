# 57 numera/branch_anchor.iii — Implementation Spec

## Verdict
PARTIAL — the gospel candidate has the correct architecture (slot-table branch index + proposal index, sentinel-loop slot search, null guards, append-only structural isolation by `branch_id`) and is largely trap-clean, but it ships **six blocking defects** that prevent it from building or satisfying M16/W34/W42: (1) it externs a **fictional `ws_emit_fragment`** from `witness_spine.iii` — that module is a read/index layer with no such symbol; the real emission primitive is `wh_publish` in `witness_hook.iii` (Module 07, BUILT); (2) it externs a **fictional `at_now(out:*u8)->i32`** from `algebraic_time.iii` — the real API is `at_current() -> u64` (a scalar, not a 32-byte writer); (3) it externs `cons_find(...) -> i32` and tests `!= 0i32`, but `constitution.iii` returns **`u32` with sentinel `CONS_SENT = 0xFFFFFFFFu32`** and slot `0u32` is a *valid found* clause — the gospel's test is both wrong-typed and inverted-semantics; (4) `ba_merge_propose` sets `BA_PROPOSAL_VERIFIED[p] = 1u8` **at propose time**, making `ba_verify_bisimulation` a tautology that always returns `BA_OK` for any live proposal — this voids the M16/W41/W42 merge ceremony (verification must be an independent re-check of the witness, not a flag set by the proposer); (5) the assigned const PREFIX is `BANCHOR_` but the body uses `BA_` (Trap 2 — every module-scope `const` is a linker-global `L_NAME`); (6) `ba_retire`/`ba_append`/`ba_merge_commit` do **not** mark the emitted branch/merge fragments with the V3 `branch_id` header field that W34's structural disjointness depends on — they only write the kind sentinel into the *payload*, while `computation_graph::cg_resolve_fragment` reads `branch_id` from the *fragment header* (offset 148), so a branch fragment emitted via `wh_publish` would resolve as canonical (`branch_id = 0`). All six are closed below. The maximal intent — a clause-ratified, bisimulation-gated branch lifecycle that never appends to canonical without a *verified* compatibility proof — is preserved and hardened, not down-scaled.

## Purpose
`branch_anchor` is the branch lifecycle authority of the V3 DAG substrate: it **constructs** a side branch at a fragment that `computation_graph` has declared an anchor under a ratified `branch_anchor_clause`, **grows** it by append-only emission tagged with a non-zero `branch_id`, **retires** it under clause `cp_branch_retire`, and **merges** it into the canonical line only through a clause-gated ceremony that demands an independently *verified* bisimulation witness (`cg_bisimulate` constructs it; `ba_verify_bisimulation` re-checks it; only then may `ba_merge_commit` emit the canonical merge attestation). It is the operational embodiment of **M16 Branch Ratifiability**, **W34** (no branch without anchored divergence), **W41** (no equivalence claim without bisimulation witness), and **W42** (no branch merge without proof of compatibility). Hexad: `kind_essence + kind_witness`. Ring: **R0**. K-vector: **1.00**.

## Public API
All public functions return a status; W9 negative-`i32` error codes, `BA_OK = 0` on success (W12). No boolean-`u8` public functions in this module.

```
fn ba_init() -> i32 @export
fn ba_construct(anchor_fid: *u8, out_branch_id: *u8) -> i32 @export
fn ba_append(req: *u8) -> i32 @export
fn ba_retire(branch_id: *u8) -> i32 @export
fn ba_merge_propose(branch_id: *u8, canonical_target_fid: *u8, out_proposal_fid: *u8) -> i32 @export
fn ba_verify_bisimulation(proposal_fid: *u8) -> i32 @export
fn ba_merge_commit(proposal_fid: *u8) -> i32 @export
fn ba_selftest() -> u64 @export
```

Private (non-`@export`) helpers (single-line signatures):
```
fn ba_branch_slot(branch_id: *u8) -> i64
fn ba_proposal_slot(witness_fid: *u8) -> i64
fn ba_branch_ptr(slot: u64) -> u64
fn ba_emit_branch_fragment(req: *u8, slot: u64) -> i32
fn ba_emit_merge_fragment(proposal_fid: *u8, out_fid: *u8) -> i32
```

### API CHANGE vs gospel (W2 enforcement — flagged)
The gospel's `ba_append(branch_id, op, in_commit, out_commit, out_fid)` has **5 parameters**, violating **W2 (≤4)**. Fix: pass an aggregate by pointer. `ba_append(req: *u8)` where `req` points at a `ba_append_req` view:

```
// ba_append_req byte layout (160 bytes), all fields 32-byte idents:
//   [  0.. 32)  branch_id
//   [ 32.. 64)  op           (operation id)
//   [ 64.. 96)  in_commit
//   [ 96..128)  out_commit
//   [128..160)  out_fid      (caller-owned output: filled with the new fragment id)
```
`out_fid` is written in place inside the request block (caller reads it back from `req[128..160]`). This keeps the public surface at 1 parameter and is the W2-canonical aggregate-by-pointer form used elsewhere in the convergence set (cf. `constitution.iii::cons_ratify(req)`). `ba_selftest` is added per house convention (every STDLIB module ships a `*_selftest` returning `99u64` on pass).

## Constant Namespace
PREFIX = `BANCHOR_` . **Grep confirmed (2026-05-23): no `const`/`var`/`fn BANCHOR_*` and no `BA_*` symbol anywhere under `STDLIB/` — neither the assigned prefix nor the gospel's `BA_` collides.** Per Trap 2 every module-scope `const`/`var` emits a linker-global `L_NAME`, so the gospel's `BA_` names are renamed to `BANCHOR_`. Function names keep their natural `ba_*` C-ABI form (distinct symbols; collide with nothing).

```
const BANCHOR_OK                : i32 =  0i32
const BANCHOR_E_NULL            : i32 = -1i32
const BANCHOR_E_NOT_ANCHOR      : i32 = -2i32
const BANCHOR_E_BRANCH_ABSENT   : i32 = -3i32
const BANCHOR_E_BRANCH_RETIRED  : i32 = -4i32
const BANCHOR_E_NOT_BISIMILAR   : i32 = -5i32
const BANCHOR_E_CLAUSE_ABSENT   : i32 = -6i32
const BANCHOR_E_INDEX_FULL      : i32 = -7i32
const BANCHOR_E_NOT_INITED      : i32 = -8i32
const BANCHOR_E_EMIT            : i32 = -9i32   // NEW: wh_publish returned the u64 sentinel

const BANCHOR_BRANCH_SLOTS      : u64 = 256u64
const BANCHOR_PROPOSAL_SLOTS    : u64 = 256u64
const BANCHOR_IDENT_BYTES       : u64 = 32u64
const BANCHOR_U64_SENT          : u64 = 0xFFFFFFFFFFFFFFFFu64   // wh_publish failure sentinel
const BANCHOR_CONS_SENT         : u32 = 0xFFFFFFFFu32           // mirrors constitution CONS_SENT

// V3 payload kind sentinels (0xE3 catalog, Part VI of the gospel):
const BANCHOR_KIND_E3           : u8  = 0xE3u8
const BANCHOR_KIND_CONTINUATION : u8  = 0x03u8   // BRANCH_CONTINUATION
const BANCHOR_KIND_MERGE        : u8  = 0x10u8   // MERGE_ATTESTATION

// Branch fragments are non-canonical; canonical pillar is 0. Branch pillar marker:
const BANCHOR_PILLAR_BRANCH     : u16 = 1u16
```
No constant named `OK` / `MAX` / `BUF_LEN` etc. is introduced bare — every name carries the `BANCHOR_` prefix.

## Data Structures
All module-scope (W8 static sizing; W6/W7 module-scope lifecycle, reset by `ba_init`). No local `var` arrays (Trap 7) — every scratch buffer below is module scope with a unique prefixed name.

```
var BANCHOR_INITED            : u8  = 0u8

// --- branch index (256 slots) ---
var BANCHOR_BRANCH_IDS        : [u8; 8192]    // 256 * 32  — assigned branch_id per slot
var BANCHOR_BRANCH_ANCHORS    : [u8; 8192]    // 256 * 32  — the anchor fragment id
var BANCHOR_BRANCH_HEADS      : [u8; 8192]    // 256 * 32  — current head fragment id of the branch
var BANCHOR_BRANCH_LIVE       : [u8; 256]
var BANCHOR_BRANCH_RETIRED    : [u8; 256]
var BANCHOR_BRANCH_COUNT      : u64 = 0u64

// --- merge-proposal index (256 slots) ---
var BANCHOR_PROPOSAL_BRANCH   : [u8; 8192]    // 256 * 32  — proposing branch_id
var BANCHOR_PROPOSAL_TARGET   : [u8; 8192]    // 256 * 32  — canonical target fid
var BANCHOR_PROPOSAL_WITNESS  : [u8; 8192]    // 256 * 32  — bisimulation witness fid (the proposal id)
var BANCHOR_PROPOSAL_VERIFIED : [u8; 256]     // set only by ba_verify_bisimulation, never by propose
var BANCHOR_PROPOSAL_LIVE     : [u8; 256]

// --- emission scratch (serialized; module not reentrant — acceptable, single-threaded substrate) ---
var BANCHOR_SEED_BUF          : [u8; 64]      // anchor || time-bytes, for fresh branch_id
var BANCHOR_TIME_BUF          : [u8; 32]      // ident_encode_u64(at_current())
var BANCHOR_PAYLOAD           : [u8; 72]      // BRANCH_CONTINUATION payload
var BANCHOR_MERGE_PAYLOAD     : [u8; 40]      // MERGE_ATTESTATION payload
var BANCHOR_ZERO_ID           : [u8; 32]      // a canonical all-zero id (producer/op/commit slots)
var BANCHOR_RETIRE_LABEL      : [u8; 16]      // "cp_branch_retire" literal bytes
var BANCHOR_RETIRE_CID        : [u8; 32]      // ident of the retire clause
var BANCHOR_MERGE_LABEL       : [u8; 16]      // "cp_branch_merge_" literal bytes (16 exact)
var BANCHOR_MERGE_CID         : [u8; 32]      // ident of the merge clause
var BANCHOR_WITNESS_FID       : [u8; 32]      // cg_bisimulate output scratch
var BANCHOR_CLAUSE_SCRATCH    : [u8; 32]      // cg_anchor_query output scratch
var BANCHOR_BRANCHID_TAG      : [u8; 32]      // branch_id, broadcast into the antecedents/payload
```

**Bound justification (W8).** `BANCHOR_BRANCH_SLOTS = 256` and `BANCHOR_PROPOSAL_SLOTS = 256` are inherited from the gospel and are deliberately *below* `computation_graph`'s `CG_BRANCH_SLOTS = 1024`: branch_anchor tracks only the branches it itself constructs in the current substrate session (a small ceremony-driven set), whereas `computation_graph` indexes every branch the whole substrate observes. 256 live branches and 256 in-flight merge proposals exceed any single-session ratification workload; `BANCHOR_E_INDEX_FULL` is returned on exhaustion (M5 — refusal, never silent overwrite). The eight 8192-byte arrays + two 256-byte arrays + scratch total ≈ 66 KiB, trivially inside the small-code-model reach.

## Dependencies (externs)
Each is a single-line `extern @abi(c-msvc-x64) fn ... from "<module>.iii"`. Status noted; **three providers are NOT-YET-BUILT** and gate this module.

| Extern (corrected signature) | From | NN | Status |
|---|---|---|---|
| `fn ident_zero(out: *u8) -> i32` | `identifier.iii` | 01 | BUILT |
| `fn ident_eq(a: *u8, b: *u8) -> u8` | `identifier.iii` | 01 | BUILT |
| `fn ident_copy(src: *u8, dst: *u8) -> i32` | `identifier.iii` | 01 | BUILT |
| `fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32` | `identifier.iii` | 01 | BUILT |
| `fn ident_encode_u64(v: u64, out: *u8) -> i32` | `identifier.iii` | 01 | BUILT — **NEW** (used to serialize `at_current()` for the branch-id seed) |
| `fn at_current() -> u64` | `algebraic_time.iii` | 03 | BUILT — **REPLACES the fictional `at_now`** |
| `fn wh_publish(producer:*u8,opid:*u8,in_commit:*u8,out_commit:*u8,revtag:u8,phase:u8,pillar:u16,antecedents:*u8,n_ante:u32,payload:*u8,payload_len:u32,out_frag_id:*u8) -> u64` | `witness_hook.iii` | 07 | BUILT — **REPLACES the fictional `ws_emit_fragment`** |
| `fn cg_anchor_query(fid: *u8, out_clause_id: *u8) -> i32` | `computation_graph.iii` | 56 | **NOT-YET-BUILT** (designed in parallel) |
| `fn cg_bisimulate(left_fid: *u8, right_fid: *u8, out_witness_fid: *u8) -> i32` | `computation_graph.iii` | 56 | **NOT-YET-BUILT** (designed in parallel) |
| `fn cons_find(clause_id: *u8) -> u32` | `constitution.iii` | (Layer 2) | **NOT-YET-BUILT** (spec present; returns `u32`/`CONS_SENT`, not `i32`) |

**Removed externs (fictional in the gospel):**
- `ws_emit_fragment ... from "witness_spine.iii"` — `witness_spine` exports no emitter (`ws_init/ws_register/ws_lookup_id/...`); fragment *emission* lives in `witness_hook.iii::wh_publish`. (Same systemic gospel defect afflicts Module 56's body.)
- `at_now ... from "algebraic_time.iii"` — no such symbol; the time source is `at_current() -> u64`.

**Not-yet-built dependency count: 3** (`computation_graph.iii` ×2 entry points + `constitution.iii` ×1). The wave scheduler must build Modules 01/03/07 (done), then `constitution.iii` and `computation_graph.iii` (Module 56), then this module.

## Algorithm
NIH (M1): all hashing is delegated to the already-NIH identifier/keccak path; all comparison is hand-rolled byte XOR-accumulate (`ident_eq`). No ML/heuristics (M3/M4) — every decision is an exact slot match, an exact clause-presence check, or an exact bisimulation re-check. Determinism (M2)/bit-identity (W5): every emitted fragment is a pure function of its byte inputs; `at_current()` is the monotonic algebraic clock (single writer = the hook), so a replay from the same boot seed reproduces every branch_id and fragment id byte-identically (M10). No recursion (W15): all searches are single counter loops with a found/sentinel flag; the only cross-function call chain is `ba_merge_commit → ba_verify_bisimulation` (depth-2, not recursion).

**`ba_init`** — idempotent (`if BANCHOR_INITED == 1u8 { return BANCHOR_OK }`). Counter-loop zero `BANCHOR_BRANCH_LIVE[i]`/`BANCHOR_BRANCH_RETIRED[i]` over `0..BANCHOR_BRANCH_SLOTS`; counter-loop zero `BANCHOR_PROPOSAL_LIVE[j]`/`BANCHOR_PROPOSAL_VERIFIED[j]` over `0..BANCHOR_PROPOSAL_SLOTS`; `BANCHOR_BRANCH_COUNT = 0`; `ident_zero(&BANCHOR_ZERO_ID[0])`; populate `BANCHOR_RETIRE_LABEL` = bytes of `"cp_branch_retire"` (16) and `BANCHOR_MERGE_LABEL` = bytes of `"cp_branch_merge_"` (16); `ident_from_bytes` each into `BANCHOR_RETIRE_CID`/`BANCHOR_MERGE_CID` once (cached clause ids); `BANCHOR_INITED = 1u8`. Two separate `while` loops because the two tables have different slot counts (here equal, but kept distinct for clarity and to match `cg_init`).

**`ba_branch_slot(branch_id)`** (private) — single counter loop `i in 0..BANCHOR_BRANCH_SLOTS` with `found:i64 = -1i64` and a `sentinel:u8` flag; for each `BANCHOR_BRANCH_LIVE[i] == 1u8`, if `ident_eq(ba_branch_ptr(i), branch_id) == 1u8` set `found = i as i64`, `sentinel = 1u8`. No `break` (W14); the `sentinel` guard makes the body side-effect-stable after the hit. Returns `found` (`-1i64` = absent — compared by `==`/`!=` only, W11/Trap 3).

**`ba_branch_ptr(slot)`** (private) — returns `(&BANCHOR_BRANCH_IDS as u64) + slot * 32u64` as a `u64` address (computed in `u64`, never via `&ARR[expr] as *u8`, which is a documented non-address form — see witness_spine §; element addresses are always base + offset arithmetic). Mask not required (slot is a loop counter `< 256`, always clean in its u64 slot) but the multiply is done in u64 throughout (Trap 4).

**`ba_construct(anchor_fid, out_branch_id)`** —
1. `if BANCHOR_INITED == 0u8 { return BANCHOR_E_NOT_INITED }`; null-guard both pointers (`(p as u64) == 0u64`).
2. `q = cg_anchor_query(anchor_fid, &BANCHOR_CLAUSE_SCRATCH[0])`; `if q != 0i32 { return BANCHOR_E_NOT_ANCHOR }`. (W34: a branch may root *only* at an anchored fragment. `cg_anchor_query` returns `CG_OK=0` when anchored, `CG_E_NOT_ANCHOR=-6` otherwise — the `!= 0i32` test is correct, compared by inequality only.)
3. Find a free branch slot: counter loop with `slot:i64 = -1i64`, `sentinel`; first `BANCHOR_BRANCH_LIVE[i] == 0u8` → `slot = i as i64`. `if slot == -1i64 { return BANCHOR_E_INDEX_FULL }`.
4. **Fresh branch_id (corrected — no `at_now`):** `let t : u64 = at_current()`; `ident_encode_u64(t, &BANCHOR_TIME_BUF[0])` (little-endian 8 bytes + zero pad — deterministic). Counter loop `k in 0..32`: `BANCHOR_SEED_BUF[k] = anchor_fid[k]`; `BANCHOR_SEED_BUF[32+k] = BANCHOR_TIME_BUF[k]`. `ident_from_bytes(&BANCHOR_SEED_BUF[0], 64u64, out_branch_id)` = Keccak256(anchor ‖ time) — a fresh 32-byte id. (M2/M10: reproducible from the same anchor and the same algebraic-time value.)
5. `let s : u64 = slot as u64`; `ident_copy(out_branch_id, ba_branch_ptr(s))`; `ident_copy(anchor_fid, base BANCHOR_BRANCH_ANCHORS + s*32)`; `ident_copy(anchor_fid, base BANCHOR_BRANCH_HEADS + s*32)` (head starts at the anchor). `BANCHOR_BRANCH_LIVE[s] = 1u8`; `BANCHOR_BRANCH_RETIRED[s] = 0u8`; `BANCHOR_BRANCH_COUNT += 1u64`. Return `BANCHOR_OK`.

**`ba_emit_branch_fragment(req, slot)`** (private, single-line) — assembles the `wh_publish` call so `ba_append` stays ≤4 params and ≤20 locals (W2/W13).
1. View `req`: `branch_id = &req[0]`, `op = &req[32]`, `in_commit = &req[64]`, `out_commit = &req[96]`, `out_fid = &req[128]`.
2. Build `BANCHOR_PAYLOAD` (72 bytes): `[0]=0xE3`, `[1]=0x03`; counter loop `k in 0..32`: `BANCHOR_PAYLOAD[8+k] = in_commit[k]`, `BANCHOR_PAYLOAD[40+k] = branch_id[k]` (the V3 BRANCH_CONTINUATION payload — branch_id embedded so the payload is self-describing).
3. **Header branch_id tagging (DEFECT 6 fix):** copy `branch_id` into `BANCHOR_BRANCHID_TAG` and pass it as the **single antecedent** (`antecedents = &BANCHOR_BRANCHID_TAG[0]`, `n_ante = 1u32`) AND use `pillar = BANCHOR_PILLAR_BRANCH (1)`. Rationale: `computation_graph::cg_resolve_fragment` reads the branch_id from the fragment's header region (the antecedents/extended header at offset 148, per Module 56's body), not from the free payload. The anchor linkage W34 demands ("the branch's first fragment carries an antecedents entry pointing at the anchor and a branch_id payload field") is satisfied by emitting the branch_id as an antecedent and as a payload field, and by the non-canonical pillar marker. (The exact header offset is owned by `witness_hook`'s frag layout; Phase 2 must confirm the antecedent lands where `cg_resolve_fragment` reads — flagged as cross-module integration check §G6.)
4. `let idx : u64 = wh_publish(producer=&BANCHOR_ZERO_ID[0], opid=op, in_commit, out_commit, revtag=0u8, phase=0u8, pillar=BANCHOR_PILLAR_BRANCH, antecedents=&BANCHOR_BRANCHID_TAG[0], n_ante=1u32, payload=&BANCHOR_PAYLOAD[0], payload_len=72u32, out_frag_id=out_fid)`.
5. `if idx == BANCHOR_U64_SENT { return BANCHOR_E_EMIT }` (compared by `==` only — Trap 3 / W11). Return `BANCHOR_OK`. (`out_fid` is now filled in place in `req[128..160]`.)

**`ba_append(req)`** —
1. `if BANCHOR_INITED == 0u8 { return BANCHOR_E_NOT_INITED }`; `if (req as u64) == 0u64 { return BANCHOR_E_NULL }`.
2. `let branch_id : *u8 = (req as u64) as *u8` (= `&req[0]`); `slot = ba_branch_slot(branch_id)`; `if slot == -1i64 { return BANCHOR_E_BRANCH_ABSENT }`; `let s = slot as u64`.
3. `if BANCHOR_BRANCH_RETIRED[s] == 1u8 { return BANCHOR_E_BRANCH_RETIRED }` (W34/append-only: a retired branch takes no further appends).
4. `let e = ba_emit_branch_fragment(req, s)`; `if e != 0i32 { return e }` (compared by `!=` only).
5. `ident_copy(&req[128], ba_branch_head_ptr(s))` — advance the recorded head to the new fragment id. Return `BANCHOR_OK`.

**`ba_retire(branch_id)`** —
1. Init + null guards. `slot = ba_branch_slot(branch_id)`; `if slot == -1i64 { return BANCHOR_E_BRANCH_ABSENT }`.
2. **Clause check (DEFECT 3 fix):** the `cp_branch_retire` clause id is cached in `BANCHOR_RETIRE_CID` (computed once in `ba_init`). `let f : u32 = cons_find(&BANCHOR_RETIRE_CID[0])`; `if f == BANCHOR_CONS_SENT { return BANCHOR_E_CLAUSE_ABSENT }`. (Was: `if cons_find(...) != 0i32` — wrong type and inverted; slot `0u32` is a *valid found* clause, the sentinel is `0xFFFFFFFFu32`. Now compares the `u32` result against the `u32` sentinel by `==`.)
3. `BANCHOR_BRANCH_RETIRED[slot as u64] = 1u8`. Return `BANCHOR_OK`. (M5/M9: retirement is reversible-by-refusal — it only *blocks* future appends; it deletes nothing and emits no canonical mutation.)

**`ba_proposal_slot(witness_fid)`** (private) — counter loop over `0..BANCHOR_PROPOSAL_SLOTS`, `found:i64=-1i64`, `sentinel`; for each `BANCHOR_PROPOSAL_LIVE[i] == 1u8`, if `ident_eq(base BANCHOR_PROPOSAL_WITNESS + i*32, witness_fid) == 1u8` set `found`/`sentinel`. Returns `found`.

**`ba_merge_propose(branch_id, canonical_target_fid, out_proposal_fid)`** —
1. Init + three null guards. `slot = ba_branch_slot(branch_id)`; `if slot == -1i64 { return BANCHOR_E_BRANCH_ABSENT }`; `let s = slot as u64`.
2. Find a free proposal slot (counter loop, `pslot:i64=-1i64`, `sentinel`; first `BANCHOR_PROPOSAL_LIVE[i] == 0u8`). `if pslot == -1i64 { return BANCHOR_E_INDEX_FULL }`; `let p = pslot as u64`.
3. **Construct the bisimulation witness** between the branch head and the canonical target: `let bisim = cg_bisimulate(base BANCHOR_BRANCH_HEADS + s*32, canonical_target_fid, &BANCHOR_WITNESS_FID[0])`; `if bisim != 0i32 { return BANCHOR_E_NOT_BISIMILAR }`. (W41: the equivalence claim exists only as the witness `cg_bisimulate` returns; no informal equivalence.)
4. Record the proposal: `ident_copy(branch_id, base PROPOSAL_BRANCH + p*32)`; `ident_copy(canonical_target_fid, base PROPOSAL_TARGET + p*32)`; `ident_copy(&BANCHOR_WITNESS_FID[0], base PROPOSAL_WITNESS + p*32)`; `BANCHOR_PROPOSAL_LIVE[p] = 1u8`; **`BANCHOR_PROPOSAL_VERIFIED[p] = 0u8`** (DEFECT 4 fix — propose does NOT pre-verify). `ident_copy(&BANCHOR_WITNESS_FID[0], out_proposal_fid)` (the witness fid IS the proposal id). Return `BANCHOR_OK`.

**`ba_verify_bisimulation(proposal_fid)`** (DEFECT 4 fix — now a real re-check) —
1. Init + null guard. `slot = ba_proposal_slot(proposal_fid)`; `if slot == -1i64 { return BANCHOR_E_NOT_BISIMILAR }`; `let p = slot as u64`.
2. **Independently re-run the bisimulation** from the recorded branch head and target: read `branch_id = base PROPOSAL_BRANCH + p*32`; `bslot = ba_branch_slot(branch_id)`; `if bslot == -1i64 { return BANCHOR_E_BRANCH_ABSENT }`; `let bs = bslot as u64`. `let recheck = cg_bisimulate(base BANCHOR_BRANCH_HEADS + bs*32, base PROPOSAL_TARGET + p*32, &BANCHOR_WITNESS_FID[0])`; `if recheck != 0i32 { return BANCHOR_E_NOT_BISIMILAR }`.
3. **Confirm the witness is stable:** `if ident_eq(&BANCHOR_WITNESS_FID[0], base PROPOSAL_WITNESS + p*32) == 0u8 { return BANCHOR_E_NOT_BISIMILAR }` (the re-derived witness must match the proposed one byte-for-byte — M10 witness reproducibility; a divergence means the branch head or target moved and the proposal is stale).
4. `BANCHOR_PROPOSAL_VERIFIED[p] = 1u8`; return `BANCHOR_OK`. (M16/W42: verification is a *re-derivation*, not a flag the proposer set. This is the load-bearing fix — the gospel made this a tautology.)

**`ba_emit_merge_fragment(proposal_fid, out_fid)`** (private, single-line) — build `BANCHOR_MERGE_PAYLOAD` (40 bytes): `[0]=0xE3`, `[1]=0x10`; counter loop `k in 0..32`: `BANCHOR_MERGE_PAYLOAD[8+k] = proposal_fid[k]`. `let idx = wh_publish(producer=&BANCHOR_ZERO_ID[0], opid=&BANCHOR_ZERO_ID[0], in_commit=&BANCHOR_ZERO_ID[0], out_commit=&BANCHOR_ZERO_ID[0], revtag=0u8, phase=0u8, pillar=0u16 /* CANONICAL */, antecedents=&BANCHOR_ZERO_ID[0], n_ante=0u32, payload=&BANCHOR_MERGE_PAYLOAD[0], payload_len=40u32, out_frag_id=out_fid)`; `if idx == BANCHOR_U64_SENT { return BANCHOR_E_EMIT }`; return `BANCHOR_OK`. The merge fragment is **canonical** (`pillar = 0`, no branch_id antecedent) — it records that canonical now considers the branch equivalent at this point; it does **not** copy branch fragments into canonical (W1/W19 append-only canonical invariant preserved).

**`ba_merge_commit(proposal_fid)`** —
1. Init + null guard.
2. **Clause gate (NEW — W42 demands the merge be clause-governed):** `let f = cons_find(&BANCHOR_MERGE_CID[0])`; `if f == BANCHOR_CONS_SENT { return BANCHOR_E_CLAUSE_ABSENT }`. (The gospel omitted the `cp_branch_merge` check entirely — merge must be as clause-gated as retire.)
3. **Verify (independent re-check):** `let v = ba_verify_bisimulation(proposal_fid)`; `if v != 0i32 { return v }`. Because of the DEFECT-4 fix this now actually re-derives the bisimulation; a proposal whose `VERIFIED` flag was never set cannot be committed, and a stale proposal fails the re-check.
4. `let e = ba_emit_merge_fragment(proposal_fid, &BANCHOR_WITNESS_FID[0])` (reuse scratch for the commit fid — its value is not returned). `return e`. (M5: the only state change is the append of one canonical attestation fragment; nothing is destroyed; if emission fails the canonical line is unchanged.)

**`ba_selftest`** — see KAT Vectors; returns `99u64` on full pass, else the failing step number.

## KAT Vectors (>= 3)
These drive the Phase-2 acceptance gate. They require the not-yet-built `cg_*` and `cons_*` providers, so the self-test runs against a booted substrate where: a `branch_anchor_clause`, `cp_branch_retire`, and `cp_branch_merge` clause have been ratified; one fragment has been published and declared an anchor via `cg_anchor_declare`. (Steps that need providers are gated behind their availability; the pure-local steps below run unconditionally.)

1. **Anchor-gating (W34, negative case — must FAIL).** `ba_init()`; call `ba_construct(unanchored_fid, &out)` where `unanchored_fid` is a published-but-NOT-anchored fragment id. **Expect `BANCHOR_E_NOT_ANCHOR (-2i32)`** and `BANCHOR_BRANCH_COUNT` unchanged (== 0). Then `cg_anchor_declare(anchor_fid, clause_id)`, call `ba_construct(anchor_fid, &out)` → **`BANCHOR_OK`**, `out` is non-zero (`ident_is_zero(&out) == 0u8`), `BANCHOR_BRANCH_COUNT == 1`. *(Proves the gate refuses an un-anchored divergence — the negative half is the point, per the no-autogen-stub/prove-the-negative discipline.)*

2. **Determinism of branch_id (M2/M10).** With algebraic time pinned to a known value `T` (`at_init(T)` at boot, no intervening `at_advance`), two `ba_construct` calls on the *same* `anchor_fid` performed in two fresh-`ba_init` sessions at the same `T` yield **byte-identical** `out_branch_id` (since branch_id = Keccak256(anchor ‖ encode_u64(T))). Concretely: anchor = `Keccak256("abc")` (the identifier KAT vector, `[0]=0x4e … [31]=0x45`), `T = 0u64` ⇒ `out_branch_id = Keccak256(anchor ‖ 0x00*32)`; assert `out_branch_id` equals the value recorded on the first run, all 32 bytes. *(A second construct after one `at_advance` MUST differ — proves the time component is live.)*

3. **Merge ceremony — tautology defeated (M16/W41/W42, the load-bearing KAT).**
   a. Construct branch B at the anchor; `ba_append(req)` once so B's head advances to a fragment `Hb`.
   b. `ba_merge_propose(B, target_fid, &pid)` where `target_fid` is a canonical fragment **NOT** bisimilar to `Hb` → **`BANCHOR_E_NOT_BISIMILAR (-5i32)`** (no proposal slot consumed: `BANCHOR_PROPOSAL_LIVE` all 0). 
   c. Now `target_fid2` chosen bisimilar to `Hb` (same op/in/out-commit triple); `ba_merge_propose(B, target_fid2, &pid)` → **`BANCHOR_OK`**, and immediately assert `BANCHOR_PROPOSAL_VERIFIED[0] == 0u8` (**propose did NOT pre-verify** — this is the exact assertion the gospel body would FAIL).
   d. `ba_merge_commit(pid)` **before** any explicit verify → succeeds *only because* commit calls `ba_verify_bisimulation` internally, which re-derives the witness; assert it returns `BANCHOR_OK` and a new canonical fragment was published (`wh_next_idx` increased by 1). 
   e. Tamper: corrupt B's head (simulate by `ba_append` again so `Hb` moves), then `ba_merge_commit(pid)` on the *stale* proposal → **`BANCHOR_E_NOT_BISIMILAR`** (the re-check now fails against the moved head). *(Proves verification is a real re-derivation, not a stored flag.)*

4. **Retire blocks append (append-only, W34).** Construct B; `ba_retire(B)` (with `cp_branch_retire` ratified) → `BANCHOR_OK`. Then `ba_append(req for B)` → **`BANCHOR_E_BRANCH_RETIRED (-4i32)`**. With the clause NOT ratified, `ba_retire(B)` → **`BANCHOR_E_CLAUSE_ABSENT (-6i32)`** (negative case for the clause gate). 

5. **Null/uninit guards (W12).** Before `ba_init`: every public fn returns `BANCHOR_E_NOT_INITED (-8i32)`. After init: `ba_construct(0 as *u8, &out)` → `BANCHOR_E_NULL (-1i32)`; `ba_append(0 as *u8)` → `BANCHOR_E_NULL`. 

## Trap Exposure
- **Trap 1 (multi-line `fn`)** — every signature above and in the skeleton is single-line, including the 12-arg `wh_publish` extern (one physical line, no wrapping). **Avoidance: enforced.**
- **Trap 2 (`const` linker-global)** — all consts/vars carry `BANCHOR_`; grep-confirmed no collision with `BA_` or `BANCHOR_`. **Avoidance: prefix.**
- **Trap 3 (signed ordering SIGSEGV)** — slot results are `i64` and the count returns are `i32`; **every** comparison is `==`/`!=` against `-1i64` / a named `i32` const / `BANCHOR_U64_SENT` / `BANCHOR_CONS_SENT`. No `<`/`<=`/`>=`/`>` on any signed value. Loop counters are `u64` (unsigned ordering is safe). **Avoidance: equality-only.**
- **Trap 4 (u32-in-u64 garbage)** — all pointer arithmetic uses `u64` slot indices and `base + slot*32u64`; `cons_find` returns `u32` but it is only compared (never used in pointer math), so no mask needed there. The only u32→u64 widenings are `payload_len`/`n_ante` passed to `wh_publish` as the function's declared u32 params (no local pointer math on them). **Avoidance: u64 throughout for addressing.**
- **Trap 5 (u32 pointer store width)** — no `*u32` stores; every byte write is through a `[u8;…]` module array index (natural u8 store). **Avoidance: byte arrays only.**
- **Trap 6 (nested block comments)** — none used. **Avoidance: `//` line comments inside bodies.**
- **Trap 7 (local `var` arrays)** — none; all scratch (`BANCHOR_SEED_BUF`, `BANCHOR_PAYLOAD`, etc.) is module scope. **Non-reentrancy noted:** the substrate is single-threaded and branch ceremonies are serialized, so shared scratch is safe (matches `merkle.iii`/`content_addr.iii` convention).
- **Trap 8 (`} else {`)** — the design has no `else` on the public paths (early-return style). Any `else` introduced in Phase 2 must be one-line.
- **Trap 9 (em-dash in comments)** — ASCII `--` only in all comments. **Avoidance: enforced.**
- **Trap 10 (`let mut x = 0u32` flag)** — slot searches use the `sentinel:u8` + `found:i64` early-stable pattern, not a mutated-flag-as-result; init uses idempotent early-return. **Avoidance: sentinel/early-return.**
- **Trap 11 (`a % b` after call)** — **no modulo anywhere** in this module. **Avoidance: not exposed.**
- **Trap 12 (`@specialize *T` stride)** — module is not generic; no `@specialize`. **Avoidance: not exposed.**

## Gap / Fix List
Every defect in the gospel body, each with its fix (all closed in this spec):

- **§G1 (blocking, build-break) — fictional `ws_emit_fragment` extern.** `witness_spine.iii` exports no emitter; it is a read/index module. **Fix:** extern `wh_publish` from `witness_hook.iii` (Module 07, BUILT) and call it through `ba_emit_branch_fragment` / `ba_emit_merge_fragment` private wrappers (keeps `ba_append` at W2 ≤4 params). Branch fragments use `pillar = BANCHOR_PILLAR_BRANCH`, `n_ante = 1` (branch_id); merge fragments use `pillar = 0` (canonical), `n_ante = 0`. *(Same systemic gospel defect exists in Module 56's body — flagged for the Module 56 agent.)*
- **§G2 (blocking, build-break) — fictional `at_now(out:*u8)->i32` extern.** No such symbol in `algebraic_time.iii`. **Fix:** `at_current() -> u64` + `ident_encode_u64` to serialize the time into the branch-id seed. Semantically identical (a time-derived nonce), bit-deterministic.
- **§G3 (blocking, type+semantics) — `cons_find` mis-typed and inverted.** Gospel: `extern ... cons_find -> i32` and `if cons_find(...) != 0i32 { ... CLAUSE_ABSENT }`. Truth: `cons_find -> u32`, sentinel `CONS_SENT = 0xFFFFFFFFu32`, and slot `0u32` is a *valid found* clause. The gospel would treat the first-ratified clause (slot 0) as "absent" and any other slot as "present" — exactly backwards. **Fix:** extern `-> u32`; test `if f == BANCHOR_CONS_SENT { return BANCHOR_E_CLAUSE_ABSENT }`. Applied in `ba_retire` and the new merge-clause gate.
- **§G4 (blocking, M16/W41/W42) — verification tautology.** `ba_merge_propose` set `BANCHOR_PROPOSAL_VERIFIED[p] = 1u8`, so `ba_verify_bisimulation` returned `BANCHOR_OK` for any live proposal regardless of whether the bisimulation still holds. This collapses the merge ceremony into "propose ⇒ verified," defeating M16 (ratifiability), W41 (no equivalence claim without a *checkable* witness), and W42 (no merge without a *proof* of compatibility). **Fix:** propose sets `VERIFIED = 0`; `ba_verify_bisimulation` **re-runs `cg_bisimulate`** from the recorded head+target, requires the re-derived witness to byte-match the proposed witness (M10), and only then sets `VERIFIED = 1`. KAT 3 proves a stale proposal is rejected.
- **§G5 (blocking, W2) — `ba_append` had 5 parameters.** **Fix:** aggregate-by-pointer `ba_append(req: *u8)` over the 160-byte `ba_append_req` layout; `out_fid` written back in place.
- **§G6 (blocking, W34 cross-module integrity) — branch fragments not header-tagged with `branch_id`.** Gospel wrote the branch_id only into the free payload; but `cg_resolve_fragment` reads the branch_id from the fragment *header* region (offset 148 in Module 56's body). A branch fragment emitted with no header branch_id resolves as canonical (`branch_id = 0`), collapsing the structural disjointness W34/Lemma-Four rely on. **Fix:** emit the branch_id as the fragment's single **antecedent** and tag the **pillar** as non-canonical (`BANCHOR_PILLAR_BRANCH`). **Phase-2 cross-module check (must verify in the compiled layout):** confirm `witness_hook`'s antecedent storage lands at the offset `cg_resolve_fragment` reads, or coordinate a dedicated `branch_id` header field with the Module 07/56 agents. This is the one residual integration risk and is called out explicitly rather than papered over.
- **§G7 (blocking, W42) — `ba_merge_commit` had no clause gate.** Retire was clause-gated; merge (the higher-stakes canonical mutation) was not. **Fix:** add the `cp_branch_merge` `cons_find` gate at the top of `ba_merge_commit`.
- **§G8 (correctness, prefix) — body uses `BA_`.** **Fix:** rename all module-scope symbols to `BANCHOR_` (Trap 2). Grep-confirmed both `BA_` and `BANCHOR_` are collision-free today, but the dispatch assigns `BANCHOR_`.
- **§G9 (hygiene) — magic literals + missing selftest.** The `0xFFFFFFFFFFFFFFFFu64` sentinel and the V3 kind bytes are now named consts (`BANCHOR_U64_SENT`, `BANCHOR_KIND_*`); a `ba_selftest` is added (house convention; gates Phase-2 acceptance).
- **Non-defect verified:** the slot-search loops, null guards, idempotent `ba_init`, and the `if q != 0i32` anchor test are all **correct** and trap-clean as written — retained. `cg_bisimulate`/`cg_anchor_query` extern signatures **match** Module 56's designed API exactly.
- **Mandate sweep:** M1 (NIH — only identifier/keccak/time/hook/cg/cons, all in-substrate) ✓; M2/M5/M10 (determinism, no-bricking refusal, witness reproducibility) ✓ via the algebraic clock + re-derivation; M6 (witness continuity — every lifecycle step emits a chained fragment) ✓; M8 (capability/clause mediation — anchor clause, retire clause, merge clause) ✓; M16 (ratifiability) ✓ via §G4; W1/W19 (canonical append-only) ✓ — merge emits one canonical attestation, never copies branch fragments. No M3/M4 surface (no counting/observing/thresholds anywhere).

## Implementation Skeleton
```iii
/* III/STDLIB/iii/numera/branch_anchor.iii
 *
 * III STDLIB - numera::branch_anchor
 *
 * Branch construction, retirement, and merge mediation. Branches are
 * anchored at fragments declared admissible by branch_anchor_clause
 * clauses (verified through computation_graph::cg_anchor_query). The
 * canonical line's append-only invariant (W1, W19) is preserved by
 * structurally isolating branch fragments through a non-canonical
 * pillar and a branch_id antecedent; canonical is never appended to
 * except through a clause-gated merge with a re-verified bisimulation.
 *
 * Hexad: kind_essence + kind_witness.  Ring: R0.  K: 1.00.
 * NIH: identifier.iii, algebraic_time.iii, witness_hook.iii,
 *      computation_graph.iii, constitution.iii.
 * Discipline: M16 branch ratifiability; W34 anchored divergence;
 *      W41 bisimulation witness; W42 clause-gated, re-verified merge.
 */

module numera_branch_anchor

extern @abi(c-msvc-x64) fn ident_zero(out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_encode_u64(v: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn at_current() -> u64 from "algebraic_time.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn cg_anchor_query(fid: *u8, out_clause_id: *u8) -> i32 from "computation_graph.iii"
extern @abi(c-msvc-x64) fn cg_bisimulate(left_fid: *u8, right_fid: *u8, out_witness_fid: *u8) -> i32 from "computation_graph.iii"
extern @abi(c-msvc-x64) fn cons_find(clause_id: *u8) -> u32 from "constitution.iii"

const BANCHOR_OK                : i32 =  0i32
const BANCHOR_E_NULL            : i32 = -1i32
const BANCHOR_E_NOT_ANCHOR      : i32 = -2i32
const BANCHOR_E_BRANCH_ABSENT   : i32 = -3i32
const BANCHOR_E_BRANCH_RETIRED  : i32 = -4i32
const BANCHOR_E_NOT_BISIMILAR   : i32 = -5i32
const BANCHOR_E_CLAUSE_ABSENT   : i32 = -6i32
const BANCHOR_E_INDEX_FULL      : i32 = -7i32
const BANCHOR_E_NOT_INITED      : i32 = -8i32
const BANCHOR_E_EMIT            : i32 = -9i32

const BANCHOR_BRANCH_SLOTS      : u64 = 256u64
const BANCHOR_PROPOSAL_SLOTS    : u64 = 256u64
const BANCHOR_IDENT_BYTES       : u64 = 32u64
const BANCHOR_U64_SENT          : u64 = 0xFFFFFFFFFFFFFFFFu64
const BANCHOR_CONS_SENT         : u32 = 0xFFFFFFFFu32
const BANCHOR_KIND_E3           : u8  = 0xE3u8
const BANCHOR_KIND_CONTINUATION : u8  = 0x03u8
const BANCHOR_KIND_MERGE        : u8  = 0x10u8
const BANCHOR_PILLAR_BRANCH     : u16 = 1u16

var BANCHOR_INITED            : u8  = 0u8

var BANCHOR_BRANCH_IDS        : [u8; 8192]
var BANCHOR_BRANCH_ANCHORS    : [u8; 8192]
var BANCHOR_BRANCH_HEADS      : [u8; 8192]
var BANCHOR_BRANCH_LIVE       : [u8; 256]
var BANCHOR_BRANCH_RETIRED    : [u8; 256]
var BANCHOR_BRANCH_COUNT      : u64 = 0u64

var BANCHOR_PROPOSAL_BRANCH   : [u8; 8192]
var BANCHOR_PROPOSAL_TARGET   : [u8; 8192]
var BANCHOR_PROPOSAL_WITNESS  : [u8; 8192]
var BANCHOR_PROPOSAL_VERIFIED : [u8; 256]
var BANCHOR_PROPOSAL_LIVE     : [u8; 256]

var BANCHOR_SEED_BUF          : [u8; 64]
var BANCHOR_TIME_BUF          : [u8; 32]
var BANCHOR_PAYLOAD           : [u8; 72]
var BANCHOR_MERGE_PAYLOAD     : [u8; 40]
var BANCHOR_ZERO_ID           : [u8; 32]
var BANCHOR_RETIRE_LABEL      : [u8; 16]
var BANCHOR_RETIRE_CID        : [u8; 32]
var BANCHOR_MERGE_LABEL       : [u8; 16]
var BANCHOR_MERGE_CID         : [u8; 32]
var BANCHOR_WITNESS_FID       : [u8; 32]
var BANCHOR_CLAUSE_SCRATCH    : [u8; 32]
var BANCHOR_BRANCHID_TAG      : [u8; 32]

// selftest scratch
var BANCHOR_T_REQ             : [u8; 160]
var BANCHOR_T_BID             : [u8; 32]
var BANCHOR_T_PID             : [u8; 32]

fn ba_branch_ptr(slot: u64) -> u64 { /* TODO: return (&BANCHOR_BRANCH_IDS as u64) + slot * 32u64 */ }
fn ba_branch_head_ptr(slot: u64) -> u64 { /* TODO: return (&BANCHOR_BRANCH_HEADS as u64) + slot * 32u64 */ }
fn ba_branch_slot(branch_id: *u8) -> i64 { /* TODO: §Algorithm ba_branch_slot -- counter loop, found:i64=-1, sentinel; ident_eq; no break (W14) */ }
fn ba_proposal_slot(witness_fid: *u8) -> i64 { /* TODO: §Algorithm ba_proposal_slot -- counter loop over PROPOSAL_WITNESS */ }
fn ba_init() -> i32 @export { /* TODO: §Algorithm ba_init -- idempotent; zero LIVE/RETIRED/VERIFIED; ident_zero ZERO_ID; build+hash RETIRE_LABEL/MERGE_LABEL into RETIRE_CID/MERGE_CID */ }
fn ba_construct(anchor_fid: *u8, out_branch_id: *u8) -> i32 @export { /* TODO: §Algorithm ba_construct -- init+null guards; cg_anchor_query !=0 -> NOT_ANCHOR; free slot; at_current()+ident_encode_u64 seed; ident_from_bytes(SEED,64,out); record slot */ }
fn ba_emit_branch_fragment(req: *u8, slot: u64) -> i32 @export { /* TODO: §Algorithm ba_emit_branch_fragment -- build 0xE3 0x03 payload (72B); branch_id as 1 antecedent + PILLAR_BRANCH; wh_publish; ==U64_SENT -> E_EMIT */ }
fn ba_append(req: *u8) -> i32 @export { /* TODO: §Algorithm ba_append -- init+null; branch_id=&req[0]; slot; RETIRED -> E_BRANCH_RETIRED; emit; copy &req[128] into head */ }
fn ba_retire(branch_id: *u8) -> i32 @export { /* TODO: §Algorithm ba_retire -- slot; cons_find(RETIRE_CID)==CONS_SENT -> E_CLAUSE_ABSENT; set RETIRED */ }
fn ba_merge_propose(branch_id: *u8, canonical_target_fid: *u8, out_proposal_fid: *u8) -> i32 @export { /* TODO: §Algorithm ba_merge_propose -- slot; free proposal slot; cg_bisimulate(head,target)!=0 -> NOT_BISIMILAR; record; VERIFIED=0; out=witness */ }
fn ba_verify_bisimulation(proposal_fid: *u8) -> i32 @export { /* TODO: §Algorithm ba_verify_bisimulation -- proposal slot; RE-RUN cg_bisimulate(head,target); witness must byte-match; then VERIFIED=1 */ }
fn ba_emit_merge_fragment(proposal_fid: *u8, out_fid: *u8) -> i32 @export { /* TODO: §Algorithm ba_emit_merge_fragment -- build 0xE3 0x10 payload (40B); wh_publish pillar=0 n_ante=0 (canonical); ==U64_SENT -> E_EMIT */ }
fn ba_merge_commit(proposal_fid: *u8) -> i32 @export { /* TODO: §Algorithm ba_merge_commit -- init+null; cons_find(MERGE_CID)==CONS_SENT -> E_CLAUSE_ABSENT; ba_verify_bisimulation; emit canonical merge fragment */ }
fn ba_selftest() -> u64 @export { /* TODO: §KAT Vectors 1-5 -- return 99u64 on full pass, else failing step number */ }
```
*(Note: `ba_emit_branch_fragment` / `ba_emit_merge_fragment` / `ba_branch_ptr` / `ba_branch_head_ptr` / `ba_proposal_slot` / `ba_branch_slot` are marked `@export`-or-not at Phase-2's discretion; they are internal helpers and need not be exported, but exporting the emit wrappers is harmless and aids unit KATs. The eight public-surface functions are the `@export` set the API contract pins.)*
```
