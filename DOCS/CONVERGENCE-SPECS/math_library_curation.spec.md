# 67 numera/math_library_curation.iii — Implementation Spec

## Verdict
PARTIAL — the gospel candidate body is structurally near-complete and the slot-table/state-machine logic is sound, but it will FAIL to link/run as written: it externs a non-existent dependency symbol (`at_now`, which is really `at_current() -> u64`), declares three illegal function-local `[u8; N]` arrays (Trap 7), uses the W3/iiis-2-broken `&ARR[expr]` element-address form pervasively, uses the dispatch-forbidden `CR_` const prefix, and (maximal-intent gap) stores the operator capability but never verifies it — so the "operator ceremony, not automatic action" discipline (W39) is asserted in prose yet unenforced in code.

## Purpose
This module is the **admission ceremony** for the mathematical library: the single, operator-mediated gate through which a verified theorem carrier becomes a library entry. It IS a curation discipline — it opens a pending *ticket* binding a carrier to the proposing operator's capability and a timestamp, holds it pending, and only on explicit `curate_finalize` invokes `lib_admit` (Module 66) under all preconditions; every other path into the library is refused. It embodies M14 (mathematical-library discipline: dependency closure + provenance are checked by the admitted `lib_admit`), M5 (no bricking — tickets are reversible via cancel, library admission itself is append-only), and M8 (capability-mediated admission). **Hexad: kind_essence + kind_witness. Ring: R0. K: 1.00.**

## Public API
All five public functions return a negative-`i32` status (W9) or `MLCUR_OK = 0`; W12 holds (every public fn returns a status). Signatures are SINGLE-LINE (Trap 1):

```
fn curate_init() -> i32 @export
fn curate_propose(carrier_id: *u8, operator_capability: *u8, out_ticket: *u8) -> i32 @export
fn curate_finalize(ticket: *u8) -> i32 @export
fn curate_cancel(ticket: *u8) -> i32 @export
fn curate_query_ticket(ticket: *u8, out_state: *u8) -> i32 @export
```

Internal (non-`@export`) helper, single-line, ≤4 params, W9-typed sentinel return:

```
fn curate_find(ticket: *u8) -> i64
```

`curate_propose` takes 3 params (W2 ✓). `curate_find` returns an `i64` slot index or the `-1i64` sentinel; per Trap 3 / W11 callers compare it with `== -1i64` only, never `<`/`>=`. `curate_query_ticket` writes the 1-byte state (0=pending,1=finalized,2=cancelled,3=rejected) through `out_state` and returns status.

## Constant Namespace
**PREFIX = `MLCUR_`** (dispatch-assigned, overriding the gospel body's `CR_`). Grep result: `\bMLCUR_` matches **only** `DOCS/CONVERGENCE-BUILD-LEDGER.md` (this module's own dispatch row) — **no STDLIB symbol collision**. (The gospel's `CR_` is rejected: while no `.iii` `const CR_*` exists today, `STDLIB/src/stdlib.c:257` carries a `"CR_WRITE"` SE-kind string and `CR_` is too generic for a 68-module link; `MLCUR_` is collision-proof.)

Module-level constants (every `const NAME : T = V`):

```
const MLCUR_OK            : i32 =  0i32
const MLCUR_E_NULL        : i32 = -1i32
const MLCUR_E_FULL        : i32 = -2i32
const MLCUR_E_ABSENT      : i32 = -3i32
const MLCUR_E_BAD_STATE   : i32 = -4i32
const MLCUR_E_NOT_INITED  : i32 = -5i32

const MLCUR_SLOTS            : u64 = 1024u64
const MLCUR_IDENT_BYTES      : u64 = 32u64
const MLCUR_STATE_PENDING    : u8  = 0u8
const MLCUR_STATE_FINALIZED  : u8  = 1u8
const MLCUR_STATE_CANCELLED  : u8  = 2u8
const MLCUR_STATE_REJECTED   : u8  = 3u8
```

(Error codes are distinct negative `i32`; `MLCUR_E_NOT_INITED` ≠ the library's own codes, and they never cross modules — `lib_admit`'s negative result is returned verbatim from `curate_finalize`, which is acceptable since W11 mandates equality-only comparison so the exact value is opaque to the caller's control flow.)

## Data Structures
All slot tables are statically sized at `MLCUR_SLOTS = 1024` (W8). Bound justification: curation is an operator-paced ceremony; 1024 simultaneously-*pending* tickets is far beyond any plausible concurrent human admission backlog (finalized/cancelled/rejected tickets retain their slot only until the table fills, at which point `MLCUR_E_FULL` is returned — never bricking). 1024 matches the gospel and is two orders below the library's own 65536-entry capacity (Module 66), so curation can never be the binding constraint. All `[u8; N]` arrays here are small (≤ 32 KiB), well inside the small-code-model RIP-relative reach, so the `[u64; N/8]` byte-packing trick (needed only by witness_hook's multi-GiB arrays) is unnecessary.

```
var MLCUR_INITED        : u8  = 0u8

var MLCUR_TICKETS       : [u8; 32768]   // 1024 * 32 — derived ticket identifiers
var MLCUR_CARRIER_IDS   : [u8; 32768]   // 1024 * 32 — proposed carrier id per slot
var MLCUR_OPERATOR_CAPS : [u8; 32768]   // 1024 * 32 — proposing operator capability per slot
var MLCUR_STATES        : [u8; 1024]    // per-slot ceremony state
var MLCUR_LIVE          : [u8; 1024]    // 1 = slot occupied
var MLCUR_COUNT         : u64 = 0u64    // live-slot occupancy counter

// Module-scope scratch (NOT reentrant — see Trap 7). Curation is operator-serialized.
var MLCUR_SEED          : [u8; 96]      // carrier_id || operator_capability || time-bytes
var MLCUR_TIMEBUF       : [u8; 32]      // ident_encode_u64(at_current()) destination
var MLCUR_FRAGID        : [u8; 32]      // lib_admit out_frag_id sink (witness fragment id)
```

There are **no function-local `[u8; N]` declarations** (the gospel's `now_buf`/`seed`/`frag_id` are hoisted here — Trap 7). W1/W3: no address-of-static escapes this file; all `&MLCUR_*` are taken only inside this module and converted to byte pointers via the `((&ARR as u64)+off) as *u8` idiom.

## Dependencies (externs)
Each `extern @abi(c-msvc-x64) fn ... from "<module>.iii"`. SINGLE-LINE.

```
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_encode_u64(v: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn at_current() -> u64 from "algebraic_time.iii"
extern @abi(c-msvc-x64) fn lib_admit(carrier_id: *u8, curator_capability: *u8, out_frag_id: *u8) -> i32 from "math_library.iii"
```

| Extern | Provider module | NN | Built? |
|---|---|---|---|
| `ident_eq`, `ident_copy`, `ident_from_bytes`, `ident_encode_u64` | numera/identifier.iii | 01 | ✅ built (verified signatures at STDLIB/iii/numera/identifier.iii) |
| `at_current` | numera/algebraic_time.iii | 03 | ✅ built (verified at STDLIB/iii/numera/algebraic_time.iii) |
| `lib_admit` | numera/math_library.iii | **66** | ❌ **NOT YET BUILT** — parallel wave; schedule Module 66 before Module 67 |

**Wave-scheduler note: exactly ONE not-yet-built dependency — Module 66 (`math_library.iii`).** Module 66's gospel `lib_admit(carrier_id, curator_capability, out_frag_id) -> i32` matches the extern above exactly; no API drift expected. (Module 66 transitively pulls in theorem_carrier.iii / witness_spine.iii / constitution.iii — also not built — but those are *its* dependencies, not direct dependencies of this module.)

**Gospel-defect corrections vs. the candidate body's extern block:**
- Removed `ident_zero` (externed but never used in the body — dead import).
- **Removed `at_now(out: *u8) -> i32 from "algebraic_time.iii"` — that symbol DOES NOT EXIST.** Replaced with the real `at_current() -> u64`.
- **Added `ident_encode_u64`** (built, verified) to serialize the `u64` timestamp into 32 ID bytes for the ticket seed.
- (The briefing's systemic `extern keccak256_* from "keccak.iii"` defect does **not** apply — this module externs no keccak; identifier.iii owns all hashing.)

## Algorithm

Determinism (M2) & bit-identity (W5): every output (ticket id, finalize verdict) is a pure function of recorded inputs — `Keccak256(carrier_id || operator_capability || LE64(at_current()))` for the ticket id, and `lib_admit`'s own deterministic verdict for finalize. No floats, no ML/heuristics (M3/M4): the only "decision" is an exact `==` state check and the algebraic preconditions delegated to `lib_admit`. No recursion (W15): every loop is a flat `while` over `MLCUR_SLOTS` with an explicit `sentinel`/index — no call stack, no module-scope explicit stack needed (search is linear scan). All loops use the W14 sentinel pattern (a `u8` flag gates the body; the loop runs to `MLCUR_SLOTS`; **no `break`**).

**`curate_init()`** — Idempotent. If `MLCUR_INITED == 1u8` return `MLCUR_OK`. Else zero every `MLCUR_LIVE[i]` for `i` in `0..MLCUR_SLOTS` (W14 counter loop), set `MLCUR_COUNT = 0`, set `MLCUR_INITED = 1`, return `MLCUR_OK`. (States need not be zeroed — they are only read for `LIVE` slots.)

**`curate_find(ticket)`** — Linear scan `i` in `0..MLCUR_SLOTS` with `sentinel` flag and `found : i64 = -1i64`. While `sentinel == 0`: if `MLCUR_LIVE[i] == 1` and `ident_eq(((&MLCUR_TICKETS as u64)+ i*32u64) as *u8, ticket) == 1`, set `found = i as i64`, `sentinel = 1`. Return `found` (the `-1i64` sentinel = absent). Callers test `== -1i64` only (Trap 3 / W11).

**`curate_propose(carrier_id, operator_capability, out_ticket)`** — Guard: not-inited → `MLCUR_E_NOT_INITED`; any of the three pointers `== 0u64` → `MLCUR_E_NULL`. Find the first free slot via a W14 sentinel scan (`MLCUR_LIVE[i] == 0`); if none, `MLCUR_E_FULL`. Build the seed deterministically into module-scope `MLCUR_SEED[96]`: bytes `0..31` = `carrier_id[k]`, `32..63` = `operator_capability[k]` (one `while k < 32` copy loop). For the time slice: call `t = at_current()` (a `u64`), then `ident_encode_u64(t, ((&MLCUR_TIMEBUF as u64)) as *u8)` and copy `MLCUR_TIMEBUF[0..31]` into `MLCUR_SEED[64..95]` (the first 8 are the LE64 stamp, remaining 24 are deterministic zero — fully reproducible, M10). Derive the ticket id directly into the slot: `ident_from_bytes(((&MLCUR_SEED as u64)) as *u8, 96u64, ((&MLCUR_TICKETS as u64)+ s*32u64) as *u8)`. Copy it out: `ident_copy(slot-ticket-ptr, out_ticket)`. Record provenance: `ident_copy(carrier_id, ((&MLCUR_CARRIER_IDS as u64)+ s*32u64) as *u8)` and likewise `operator_capability` into `MLCUR_OPERATOR_CAPS`. Set `MLCUR_STATES[s] = MLCUR_STATE_PENDING`, `MLCUR_LIVE[s] = 1`, `MLCUR_COUNT += 1`. Return `MLCUR_OK`. Determinism: ticket id is `Keccak256` of recorded bytes; given identical `(carrier, cap)` at identical algebraic time, the id is bit-identical (M2/M10). M5: proposing is reversible (`curate_cancel`).

**`curate_finalize(ticket)`** — Guard not-inited / null. `slot = curate_find(ticket)`; if `slot == -1i64` → `MLCUR_E_ABSENT`. `s = slot as u64`. If `MLCUR_STATES[s] != MLCUR_STATE_PENDING` → `MLCUR_E_BAD_STATE` (a finalized/cancelled/rejected ticket cannot be re-finalized — the ceremony is one-shot). Invoke `admit = lib_admit(((&MLCUR_CARRIER_IDS as u64)+ s*32u64) as *u8, ((&MLCUR_OPERATOR_CAPS as u64)+ s*32u64) as *u8, ((&MLCUR_FRAGID as u64)) as *u8)`. **Compare `admit != 0i32`** (equality only, W11/Trap 3): on failure set `MLCUR_STATES[s] = MLCUR_STATE_REJECTED` and return `admit` verbatim (the library's own diagnostic — closure/verify/duplicate). On success set `MLCUR_STATES[s] = MLCUR_STATE_FINALIZED` and return `MLCUR_OK`. The witness fragment id lands in `MLCUR_FRAGID` (the library emits the chained witness per M6/M10; curation does not re-emit). M5: a rejected ticket leaves the library untouched.

**`curate_cancel(ticket)`** — Guard / find / `s`. If `MLCUR_STATES[s] != MLCUR_STATE_PENDING` → `MLCUR_E_BAD_STATE`. Set `MLCUR_STATES[s] = MLCUR_STATE_CANCELLED`; return `MLCUR_OK`. (Subsequent finalize hits the `!= PENDING` guard → `MLCUR_E_BAD_STATE`, satisfying "cancel makes finalize fail".)

**`curate_query_ticket(ticket, out_state)`** — Guard not-inited; `ticket`/`out_state` null → `MLCUR_E_NULL`. `slot = curate_find(ticket)`; `== -1i64` → `MLCUR_E_ABSENT`. Write `*out_state = MLCUR_STATES[slot as u64]`; return `MLCUR_OK`. `*out_state` is a single `u8` write (1 byte — no `u32`-store-width hazard, Trap 5).

## KAT Vectors (≥ 3)
A self-test `mlcur_selftest() -> u64` (99 = pass) drives these byte-checkable cases. Carrier/capability inputs are fixed 32-byte buffers. Because `lib_admit` (Module 66) is a dependency, the finalize-path KATs run against the real built `math_library.iii`; the lifecycle/state KATs (1–4) are dependency-light and check this module's own logic byte-for-byte.

1. **Init idempotence + empty query**: `curate_init()` == `MLCUR_OK`; `curate_init()` again == `MLCUR_OK`; `curate_query_ticket(&ANY_NONLIVE_ID, &st)` == `MLCUR_E_ABSENT`. (No slot live ⇒ find returns sentinel.)
2. **Propose → pending → query**: with `carrier = 0x11*32`, `cap = 0x22*32`, `curate_propose(&carrier,&cap,&tk)` == `MLCUR_OK`; `curate_query_ticket(&tk,&st)` == `MLCUR_OK` AND `st == 0u8` (PENDING). Then assert the ticket id is reproducible: re-derive `Keccak256(0x11..||0x22..||LE64(at_current_at_propose))` equals the returned `tk` byte-for-byte (M10). Re-deriving the *same* `tk` requires the same algebraic-time stamp, so the KAT pins `at_init(<fixed>)` before proposing.
3. **Cancel blocks finalize (state machine)**: after case 2, `curate_cancel(&tk)` == `MLCUR_OK`; `curate_query_ticket(&tk,&st)` ⇒ `st == 2u8` (CANCELLED); `curate_finalize(&tk)` == `MLCUR_E_BAD_STATE`; a second `curate_cancel(&tk)` == `MLCUR_E_BAD_STATE`.
4. **Absent / null discipline**: `curate_finalize(&UNKNOWN_ID)` == `MLCUR_E_ABSENT`; `curate_propose(&NULLPTR,&cap,&tk)` == `MLCUR_E_NULL`; calling any public fn before `curate_init` (fresh `MLCUR_INITED==0`) == `MLCUR_E_NOT_INITED`.
5. **Full-table refusal (W8/M5 no-brick)**: propose `MLCUR_SLOTS` (1024) distinct pending tickets (vary `carrier[0]`), each == `MLCUR_OK`; the 1025th `curate_propose` == `MLCUR_E_FULL` (refusal, not corruption); `MLCUR_COUNT == 1024u64`.
6. **Finalize happy path (integration, requires Module 66 built + a `tc_verify`-passing carrier with closed deps admitted)**: `curate_propose` then `curate_finalize(&tk)` == `MLCUR_OK`; `curate_query_ticket` ⇒ `st == 1u8` (FINALIZED); a second `curate_finalize(&tk)` == `MLCUR_E_BAD_STATE` (one-shot). A carrier that fails `lib_admit` ⇒ `curate_finalize` returns the negative `lib_admit` code AND `st == 3u8` (REJECTED).

## Trap Exposure
- **Trap 1 (multi-line `fn`)**: EXPOSED — `curate_propose` and the externs are long. AVOIDANCE: every signature/extern is on ONE physical line (see API & Dependencies).
- **Trap 2 (const linker-global)**: EXPOSED. AVOIDANCE: `MLCUR_` prefix on all 12 module-level consts; grep-confirmed no STDLIB collision; the gospel's generic `CR_` is replaced.
- **Trap 3 (signed-ordering SIGSEGV)**: EXPOSED — `curate_find` returns `i64`, and `admit : i32` is tested. AVOIDANCE: every signed compare is equality-only — `slot == -1i64`, `admit != 0i32`. No `<`/`<=`/`>`/`>=` on any signed value anywhere. (All loop counters are `u64`/`u32` unsigned, where ordering compares are safe — confirmed by algebraic_time.iii's own note.)
- **Trap 4 (u32-in-u64-slot before ptr math)**: LOW exposure — slot offsets are computed as `u64` (`s * 32u64`, `i * 32u64`) from the start; no `u32`-local is widened-then-used in pointer arithmetic. AVOIDANCE: keep all offset arithmetic in `u64`.
- **Trap 5 (u32 pointer-store width)**: NOT exposed — the only pointer store is `*out_state = …` (a single `u8`); all other writes go through `ident_copy`/`ident_from_bytes` (byte loops inside identifier.iii). AVOIDANCE: never store a `u32` through a `*u32` here.
- **Trap 6 (nested block comments)**: AVOID — use `//` line comments or single-level `/* */`; never nest.
- **Trap 7 (local `var`/`let` arrays)**: EXPOSED — the gospel body declares `let mut now_buf:[u8;32]`, `let mut seed:[u8;96]`, `let mut frag_id:[u8;32]` as function locals. **No built STDLIB module does this and it is unsupported.** AVOIDANCE: hoisted to module-scope `MLCUR_TIMEBUF`, `MLCUR_SEED`, `MLCUR_FRAGID`. Reentrancy note: this makes `curate_propose`/`curate_finalize` non-reentrant — acceptable, curation is operator-serialized (a single-writer ceremony, matching witness_hook.iii's documented serialized-scratch pattern).
- **Trap 8 (`} else {` one line)**: EXPOSED in `curate_finalize`'s admit-failure branch. AVOIDANCE: write `} else {` on one line if an else is used (the skeleton uses early-return guards, mostly avoiding `else` entirely — Trap 10 alignment).
- **Trap 9 (em-dash in comments)**: AVOID — all comments use ASCII `--`, never `—`.
- **Trap 10 (`let mut` checkpoint-flag)**: PARTIAL — the `sentinel : u8` loop flags are the W14 pattern, which is the *sanctioned* use (drives the loop body guard, not a post-hoc checkpoint). Guard/precondition results use early-return, not a mutated flag. AVOIDANCE: prefer early-return; reserve `let mut sentinel` strictly for the W14 scan.
- **Trap 11 (`a % b` after a call)**: NOT exposed — there is no modulo anywhere; slot addressing is `index * 32` (multiply, never `%`).
- **Trap 12 (`@specialize *T` stride)**: NOT exposed — no generics; all arrays are concrete `[u8; N]` and all element addressing is explicit `(&ARR as u64)+ idx*32u64` byte arithmetic.

**Plus the W3/iiis-2 address-of-element defect** (not in the 12-trap list but documented across STDLIB): the gospel's `&MLCUR_TICKETS[s*32u64]` / `&seed[0u64]` / `&now_buf[0u64]` forms are broken (`&GLOBAL[expr] as u64` does not yield a real address). AVOIDANCE: the canonical idiom from witness_hook.iii — `((&MLCUR_TICKETS as u64) + s * 32u64) as *u8` — used for every per-slot pointer and every scratch-buffer pointer.

## Gap / Fix List
Gospel-body defects, each with its fix (this is a PARTIAL body):

1. **Non-existent dependency `at_now` (CRITICAL — link failure).** Body: `extern … fn at_now(out: *u8) -> i32 from "algebraic_time.iii"` and `at_now(&now_buf[0u64])`. The module exports `at_current() -> u64` (verified), NOT `at_now`, and the shape differs (scalar return vs out-buffer). **Fix**: extern `at_current() -> u64`; replace the time-bytes step with `t = at_current()` then `ident_encode_u64(t, MLCUR_TIMEBUF)` and copy 32 bytes into the seed's `[64..95]` window.
2. **Three illegal function-local `[u8;N]` arrays (Trap 7 — parse/codegen failure).** `let mut now_buf:[u8;32]`, `let mut seed:[u8;96]`, `let mut frag_id:[u8;32]`. **Fix**: hoist to module-scope `MLCUR_TIMEBUF[32]`, `MLCUR_SEED[96]`, `MLCUR_FRAGID[32]`; note non-reentrancy.
3. **Pervasive W3/iiis-2 element-address `&ARR[expr]` (SIGSEGV / wild pointer).** Every `&CR_TICKETS[s*32u64]`, `&CR_CARRIER_IDS[…]`, `&CR_OPERATOR_CAPS[…]`, `&seed[0u64]`, `&now_buf[0u64]`, `&frag_id[0u64]`. **Fix**: rewrite each as `((&ARR as u64) + off) as *u8` (witness_hook.iii canonical idiom).
4. **Forbidden const prefix `CR_` (dispatch + collision risk).** **Fix**: rename all 11 consts (and the `var` table names) to `MLCUR_` / `MLCUR_*`; the dispatch ledger row 67 mandates `MLCUR_`.
5. **Dead extern `ident_zero` (unused import).** **Fix**: drop it from the extern block (not referenced by any path; keeping it adds a needless link edge).
6. **MAXIMAL-INTENT GAP — capability is stored but never verified (M8/W39 unenforced).** The header prose states "the reflection capability cannot finalize a ticket; W39 binds" and "every admission is an operator ceremony, not an automatic action," yet the body never checks `operator_capability` against any capability authority — it merely forwards it to `lib_admit` as the `curator_capability`. To *realize the maximal intent*, Phase 2 SHOULD gate `curate_propose` (and/or `curate_finalize`) on an explicit capability-rights check before opening/finalizing the ticket — i.e., verify the proposing capability carries an "admit/amend" right and is **not** the reflection capability (M13/M20 reflection-boundedness), refusing with a new `MLCUR_E_DENIED : i32 = -6i32` otherwise. This requires an extern into aether/capability.iii (`cap_verify_rights(id: u64, required: u64) -> u8`) — BUT note capability.iii keys on a `u64` cap-id while curation handles a 32-byte `*u8` capability identifier; reconciling the two representations is a design decision for Module 66/aether to settle first. **Recommendation**: flag for the wave owner; if the substrate's "capability" at this layer is the 32-byte identifier form (as the gospel signature implies), the verification must be delegated to whatever R0 authority owns capability semantics, not invented here. Until that reconciliation lands, the body's behavior (forward to `lib_admit`, which itself checks the `cp_library_admit` constitution clause) is the safe minimum — but it is NOT the full W39 ceremony the prose promises. **This gap is recorded, not silently closed.**
7. **Minor — `MLCUR_E_NOT_INITED` value vs. library codes.** No fix required: cross-module status values are compared by equality only (W11), so `curate_finalize` returning a raw `lib_admit` negative is safe; documented for clarity.

What is sound and retained verbatim (logic-level): the slot-table state machine, the one-shot PENDING→{FINALIZED|REJECTED} / PENDING→CANCELLED transitions, the linear-scan find, idempotent init, the `MLCUR_COUNT` occupancy bookkeeping, and the "finalize is the only admission path" discipline — all M5/M14-aligned and W14/W15-clean.

## Implementation Skeleton
Paste-ready structure. SINGLE-LINE signatures; NO bodies (Phase 2 writes those per Algorithm §).

```iii
/* III/STDLIB/iii/numera/math_library_curation.iii
 *
 * III STDLIB -- numera::math_library_curation
 *
 * The curation discipline: the operator-mediated admission ceremony for the
 * mathematical library.  Operators open a pending ticket binding a carrier to
 * their capability and a timestamp; curate_finalize is the ONLY path that
 * invokes lib_admit, and only when all preconditions hold.  Every other path
 * into the library is refused.
 *
 * Public API:
 *   curate_init() -> i32                                   -- idempotent init
 *   curate_propose(carrier_id, operator_capability, out_ticket) -> i32
 *   curate_finalize(ticket) -> i32                         -- invoke lib_admit
 *   curate_cancel(ticket) -> i32                           -- cancel pending
 *   curate_query_ticket(ticket, out_state) -> i32          -- 0/1/2/3 state
 *
 * Hexad: kind_essence + kind_witness.  Ring: R0.  K: 1.00.
 *
 * NIH: depends on identifier.iii, algebraic_time.iii, math_library.iii(66).
 *
 * Reconciliations vs. gospel (NOT scaling -- full capacity retained):
 *   - at_now(out) DOES NOT EXIST -> at_current() -> u64, serialized via
 *     ident_encode_u64 (the real algebraic_time.iii API).
 *   - function-local var arrays (now_buf/seed/frag_id) -> module-scope scratch
 *     (iiis local arrays are module-scope only; curation is serialized).
 *   - `&ARR[expr]` element-address -> ((&ARR as u64)+off) as *u8  (W3/iiis-2).
 *   - const prefix CR_ -> MLCUR_ (dispatch ledger row 67; collision-proof).
 *   - dead ident_zero import dropped.
 * Discipline: every admission is an operator ceremony; finalize is one-shot;
 * a cancelled/rejected/finalized ticket cannot be re-finalized.  Capability
 * verification (W39) is delegated to lib_admit's cp_library_admit clause until
 * the 32-byte-vs-u64 capability representation is reconciled at R0 (see spec
 * Gap #6 -- maximal-intent gap, flagged for the wave owner).
 */

module numera_math_library_curation

extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_encode_u64(v: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn at_current() -> u64 from "algebraic_time.iii"
extern @abi(c-msvc-x64) fn lib_admit(carrier_id: *u8, curator_capability: *u8, out_frag_id: *u8) -> i32 from "math_library.iii"

const MLCUR_OK            : i32 =  0i32
const MLCUR_E_NULL        : i32 = -1i32
const MLCUR_E_FULL        : i32 = -2i32
const MLCUR_E_ABSENT      : i32 = -3i32
const MLCUR_E_BAD_STATE   : i32 = -4i32
const MLCUR_E_NOT_INITED  : i32 = -5i32

const MLCUR_SLOTS            : u64 = 1024u64
const MLCUR_IDENT_BYTES      : u64 = 32u64
const MLCUR_STATE_PENDING    : u8  = 0u8
const MLCUR_STATE_FINALIZED  : u8  = 1u8
const MLCUR_STATE_CANCELLED  : u8  = 2u8
const MLCUR_STATE_REJECTED   : u8  = 3u8

var MLCUR_INITED        : u8  = 0u8

var MLCUR_TICKETS       : [u8; 32768]   // 1024 * 32
var MLCUR_CARRIER_IDS   : [u8; 32768]
var MLCUR_OPERATOR_CAPS : [u8; 32768]
var MLCUR_STATES        : [u8; 1024]
var MLCUR_LIVE          : [u8; 1024]
var MLCUR_COUNT         : u64 = 0u64

var MLCUR_SEED          : [u8; 96]      // carrier || cap || time-bytes (scratch, not reentrant)
var MLCUR_TIMEBUF       : [u8; 32]      // ident_encode_u64(at_current()) sink
var MLCUR_FRAGID        : [u8; 32]      // lib_admit out_frag_id sink

fn curate_init() -> i32 @export {
    // TODO: body per Algorithm curate_init -- idempotent; zero MLCUR_LIVE[0..SLOTS] (W14); MLCUR_COUNT=0; MLCUR_INITED=1.
}

fn curate_find(ticket: *u8) -> i64 {
    // TODO: body per Algorithm curate_find -- W14 sentinel scan; ident_eq on ((&MLCUR_TICKETS as u64)+i*32u64) as *u8; return i as i64 or -1i64.
}

fn curate_propose(carrier_id: *u8, operator_capability: *u8, out_ticket: *u8) -> i32 @export {
    // TODO: body per Algorithm curate_propose -- guards; W14 free-slot scan -> MLCUR_E_FULL; build MLCUR_SEED (carrier||cap||ident_encode_u64(at_current())); ident_from_bytes -> slot ticket; ident_copy out + provenance; STATE=PENDING; LIVE=1; COUNT++.
}

fn curate_finalize(ticket: *u8) -> i32 @export {
    // TODO: body per Algorithm curate_finalize -- guards; curate_find ==-1i64 -> ABSENT; STATE!=PENDING -> BAD_STATE; admit=lib_admit(slot carrier, slot cap, MLCUR_FRAGID); admit!=0i32 -> STATE=REJECTED,return admit; else STATE=FINALIZED,OK.
}

fn curate_cancel(ticket: *u8) -> i32 @export {
    // TODO: body per Algorithm curate_cancel -- guards; find; STATE!=PENDING -> BAD_STATE; STATE=CANCELLED; OK.
}

fn curate_query_ticket(ticket: *u8, out_state: *u8) -> i32 @export {
    // TODO: body per Algorithm curate_query_ticket -- guards; find ==-1i64 -> ABSENT; *out_state = MLCUR_STATES[slot as u64]; OK.
}

// Optional self-test (99 = pass) -- drives KAT Vectors 1-6.
fn mlcur_selftest() -> u64 @export {
    // TODO: per KAT Vectors -- lifecycle cases 1-5 (dependency-light) + finalize integration case 6 (needs Module 66).
}
```
