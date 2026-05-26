# 15 numera/sat.iii — Implementation Spec

## Verdict
PARTIAL — the gospel candidate `.iii` body is a near-complete, structurally-sound deterministic CDCL solver (two-watched-literals, 1UIP analysis, non-chronological backjump, clean state model), but it has (a) an M3-forbidden activity ("count-and-promote") decision heuristic that must be replaced by a fixed structural rule, (b) a real OOB-read SIGSEGV in the clause insertion-sort, (c) Trap-7 local `var` arrays, (d) multiple unchecked allocation-failure return paths that silently break soundness, and (e) under-sized learned-clause / scratch buffers vs. the worst case. Every gap is closable without changing the public API; the maximal-intent design below does so.

## Purpose
`numera::sat` IS a sovereign, fully-deterministic Boolean satisfiability oracle: given a CNF formula built incrementally over variables `1..NVAR`, it decides SAT/UNSAT and, on SAT, yields a total model — by conflict-driven clause learning with two-watched-literal unit propagation and one-UIP conflict analysis, with **no randomness, no restarts, no clause deletion, and no learned-from-data heuristic**. It is the decision core consumed by `numera/smt.iii` (Module 16) via bit-blasting. Hexad: `kind_essence`. Ring: **R0**. K-vector: **0.99** (allocation against fixed arenas may refuse on overflow — total + recoverable, never bricking).

## Public API
All public functions return either a status `i32` (W9: negative = error) or a sentinel-typed value documented per fn (W12). These four signatures are a **hard contract**: `numera/smt.iii` already declares them as externs (`extern @abi(c-msvc-x64) fn sat_init/sat_add_clause/sat_solve/sat_value ... from "sat.iii"`). They MUST appear verbatim.

```
fn sat_init(n_vars: u32) -> i32 @export
```
- Allocates/resets a solver over `n_vars` variables (numbered `1..n_vars`). Returns `SAT_OK`, or `SAT_E_TOO_BIG` if `n_vars > SAT_MAX_VARS`.

```
fn sat_add_clause(lits: *u32, n_lits: u32) -> i32 @export
```
- Adds the disjunction of `n_lits` literals (literal encoding below). Returns `SAT_OK` (including the tautology case, which is dropped), `SAT_E_NOT_INIT` if `sat_init` was not called, `SAT_E_TRIV_UNSAT` for the empty clause or a unit that contradicts an existing level-0 assignment, or `SAT_E_TOO_BIG` on capacity/length overflow. (W9/W12: negative status on error.)

```
fn sat_solve() -> i32 @export
```
- Runs CDCL to fixpoint. Returns `SAT_SAT`, `SAT_UNSAT`, `SAT_E_NOT_INIT`, or `SAT_E_TOO_BIG` (clause/lit/watch arena exhausted mid-search). (W9/W12.)

```
fn sat_value(var: u32) -> u8 @export
```
- After `SAT_SAT`: `0u8` (false), `1u8` (true), or `0xFFu8` (unknown / out-of-range / unconstrained). Sentinel-typed `u8` return (W10/W12).

```
fn sat_n_learned() -> u32 @export
```
- Count of live learned clauses. Sentinel-typed value (W12).

```
fn sat_n_decisions() -> u64 @export
```
- Total decisions taken in the last/ongoing solve. Sentinel-typed value (W12).

```
fn sat_n_conflicts() -> u64 @export
```
- Total conflicts analyzed in the last/ongoing solve. Sentinel-typed value (W12).

Private (non-`@export`) helpers — single-line signatures, all `≤4` params (W2):
```
fn sat_lit_var(lit: u32) -> u32
fn sat_lit_sign(lit: u32) -> u32
fn sat_lit_neg(lit: u32) -> u32
fn sat_mk_lit(v: u32, sign: u32) -> u32
fn sat_lit_value(lit: u32) -> u8
fn sat_watch_add(lit: u32, cl: u32) -> i32
fn sat_watch_remove(lit: u32, cl: u32) -> i32
fn sat_enqueue(lit: u32, reason: u32) -> i32
fn sat_propagate() -> u32
fn sat_analyze(conflict_cl: u32) -> i32
fn sat_undo_until(level: u32) -> i32
fn sat_record_learned() -> u32
fn sat_pick_branching_variable() -> u32
```

## Constant Namespace
PREFIX = `SAT_` . Grep result: `grep "const SAT_" STDLIB/` → **no matches**; `module numera_sat` → **no matches**; the four public fn names → **no matches**. The sibling `numera_sat_arith` module uses function-name prefix `sat_` but declares **no `SAT_` module-level constants** and exports only `sat_add_u*/sat_sub_u*/sat_mul_u*/sat_div_u*/popcount_*/min_*/max_*` — **no collision** with any name in this module. The `SAT_` const prefix is clear.

Module-level constants (name : type = value):
```
const SAT_OK              : i32 =  0i32
const SAT_SAT             : i32 =  1i32
const SAT_UNSAT           : i32 =  2i32
const SAT_E_TRIV_UNSAT    : i32 = -1i32
const SAT_E_TOO_BIG       : i32 = -2i32
const SAT_E_NOT_INIT      : i32 = -3i32
const SAT_MAX_VARS        : u32 = 65536u32
const SAT_MAX_CLAUSES     : u32 = 262144u32
const SAT_MAX_LITS_BLOCK  : u32 = 2097152u32
const SAT_MAX_WATCH       : u32 = 16777216u32
const SAT_NULL_CL         : u32 = 0xFFFFFFFFu32
const SAT_MAX_CLAUSE_LEN  : u32 = 65537u32      // NEW: clause length bound = SAT_MAX_VARS+1; gates scratch/packed/OUT_LEARN
```
Note: the gospel spelled the trivial-UNSAT code `SAT_E_TRIV_UNSAT` in the body but `SAT_E_TRIVIAL_UNSAT` in the doc-comment prose. The **canonical name is `SAT_E_TRIV_UNSAT`** (matches every use site). `SAT_MAX_CLAUSE_LEN` is added by this spec (see Gap/Fix #3 and #5).

## Data Structures
All solver state is fixed module-scope arrays (W8); there are **no local `var` arrays** (Trap 7) — the gospel's two in-function `var` arrays are hoisted here. Bounds derive from `SAT_MAX_VARS = 65536`, so a variable index `1..65536` and the two-watch literal index `0..2*65537-1` are always in range.

Per-variable state (index `0..SAT_MAX_VARS`, i.e. `65537` entries; index 0 is the unused "no variable" slot):
```
var SAT_VAR_VAL    : [u8;  65537]   // 0=unassigned, 1=false, 2=true
var SAT_VAR_LEVEL  : [u32; 65537]   // decision level at assignment
var SAT_VAR_REASON : [u32; 65537]   // reason clause id, or SAT_NULL_CL for decision/level-0 unit
var SAT_VAR_POS    : [u32; 65537]   // trail index at assignment
```
> **REMOVED vs. gospel:** `var SAT_VAR_ACT : [u64; 65537]` is deleted (Gap/Fix #1): it existed only to feed the forbidden activity heuristic.

Assignment trail + propagation cursor (W8 bound: at most one assignment per variable ⇒ trail ≤ `SAT_MAX_VARS+1`):
```
var SAT_TRAIL      : [u32; 65537]
var SAT_TRAIL_LEN  : u32 = 0u32
var SAT_QHEAD      : u32 = 0u32
```
Decision-level boundaries (bound: at most one new level per decision, ≤ `SAT_MAX_VARS+1` levels):
```
var SAT_LEVEL_BASE : [u32; 65537]   // trail length when level i began
var SAT_LEVEL      : u32 = 0u32
```
Clause database — header arrays indexed by clause id `0..SAT_MAX_CLAUSES-1`, plus one packed literal block (bound justification: an instance is rejected past `SAT_MAX_CLAUSES` original+learned clauses and past `SAT_MAX_LITS_BLOCK` total literals):
```
var SAT_CL_LIVE    : [u8;  262144]
var SAT_CL_SIZE    : [u32; 262144]
var SAT_CL_OFF     : [u32; 262144]  // offset into SAT_LIT_BUF
var SAT_CL_LEARNED : [u8;  262144]
var SAT_CL_USED    : u32 = 0u32
var SAT_LIT_BUF    : [u32; 2097152]
var SAT_LIT_USED   : u32 = 0u32
```
Watch lists — one growable chunk per literal in a bump arena (bound: `2*(SAT_MAX_VARS+1) = 131074` literals; total watch slots capped at `SAT_MAX_WATCH`. Reallocation orphans the old chunk — accepted by design; the propagation loop is liveness-checked and `SAT_WATCH_USED` is the safety valve):
```
var SAT_WATCH_HEAD : [u32; 131074]
var SAT_WATCH_LEN  : [u32; 131074]
var SAT_WATCH_CAP  : [u32; 131074]
var SAT_WATCH_BUF  : [u32; 16777216]
var SAT_WATCH_USED : u32 = 0u32
```
Conflict-analysis scratch (bound: a learned clause has ≤ NVAR distinct variables ⇒ `SAT_MAX_CLAUSE_LEN = 65537` entries; **gospel's `[u32; 4096]` is the OOB risk fixed in #5**):
```
var SAT_SEEN       : [u8;  65537]
var SAT_OUT_LEARN  : [u32; 65537]   // was [u32; 4096] in gospel
var SAT_OUT_LEN    : u32 = 0u32
var SAT_OUT_BJ     : u32 = 0u32
```
Clause-canonicalisation scratch for `sat_add_clause` (hoisted from local `var`; bound `SAT_MAX_CLAUSE_LEN`; **non-reentrant — acceptable: the solver is single-threaded and `sat_add_clause` does not re-enter**):
```
var SAT_SCRATCH    : [u32; 65537]   // was local `var scratch : [u32; 4096]`
var SAT_PACKED     : [u32; 65537]   // was local `var packed  : [u32; 4096]`
```
Counters / status:
```
var SAT_NVAR       : u32 = 0u32
var SAT_DECISIONS  : u64 = 0u64
var SAT_CONFLICTS  : u64 = 0u64
var SAT_INITED     : u8  = 0u8
var SAT_ALLOC_FAIL : u8  = 0u8      // NEW: sticky flag set by sat_watch_add/sat_record_learned on arena exhaustion (Gap/Fix #4)
```
Total static footprint ≈ `SAT_WATCH_BUF` (64 MiB) + `SAT_LIT_BUF` (8 MiB) + clause headers (~3 MiB) + per-var/per-lit tables (~2 MiB) ≈ **~77 MiB BSS**. This is fixed and pre-reserved (no dynamic allocation, M5: cannot brick).

## Dependencies (externs)
**None.** This module is self-contained: it relies only on language primitives (fixed arrays, integer ops, pointer indexing of the `lits: *u32` argument). No `extern` declarations, no libc, no other STDLIB module. (M1 NIH satisfied trivially — everything is hand-rolled here.)

Reverse dependency (informational, for the wave scheduler): **Module 16 `numera/smt.iii` depends on this module** and is blocked until it is built. No module that this spec depends on is itself not-yet-built, because there are **zero dependencies**.

## Algorithm
Literal encoding (W5 bit-identity): variable `v ∈ 1..NVAR`; positive literal `lit = (v<<1)`, negative `lit = (v<<1)|1`. `var(lit)=lit>>1`, `sign(lit)=lit&1`, `neg(lit)=lit^1`. Value encoding per variable: `0` unassigned, `1` false, `2` true. All determinism rests on: fixed clause-storage order, fixed trail order, fixed watch-list traversal order, a **fixed structural decision rule**, and a deterministic 1UIP resolution — no floating point, no randomness, no address-dependent control flow ⇒ bit-identical across runs and CPUs (M2/W5).

**`sat_init(n_vars)`** — reject `n_vars > SAT_MAX_VARS` (`SAT_E_TOO_BIG`). Zero `SAT_VAR_*[0..n_vars]`, zero `SAT_WATCH_{HEAD,LEN,CAP}[0..2*(n_vars+1))`, reset trail/level/clause/lit/watch cursors and counters, `SAT_LEVEL_BASE[0]=0`, `SAT_ALLOC_FAIL=0`, `SAT_INITED=1`. Returns `SAT_OK`. Total, no recursion.

**`sat_add_clause(lits, n_lits)`** — guard `SAT_INITED`, `n_lits==0 → SAT_E_TRIV_UNSAT`, and **`n_lits > SAT_MAX_CLAUSE_LEN → SAT_E_TOO_BIG`** (NEW bound guard, Gap/Fix #3). Copy `lits[0..n_lits)` into `SAT_SCRATCH` (module-scope; Trap-7 fix). Canonicalise by **hand-rolled insertion sort** ascending (the trap-safe form in Gap/Fix #2 — the inner descent guards `q>0` *before* every `scratch[q-1]` read). Walk the sorted run into `SAT_PACKED`, dropping exact duplicates and detecting a tautology when a literal's negation is the immediately-preceding packed literal (valid because `lit` and `lit^1` are adjacent integers and the run is sorted). Tautology ⇒ drop, return `SAT_OK`. Otherwise append a clause header (`SAT_CL_USED`) + literal block (`SAT_LIT_USED`), each capacity-guarded (`SAT_E_TOO_BIG`). If `count==1`: enqueue the unit at level 0 with `reason=SAT_NULL_CL` when its variable is free; if already assigned to the opposite polarity return `SAT_E_TRIV_UNSAT`. Else install watches on `SAT_PACKED[0]` and `SAT_PACKED[1]` via `sat_watch_add`, **checking `SAT_ALLOC_FAIL`** (Gap/Fix #4). No recursion (W15); sentinel loops only (W14).

**`sat_propagate()`** — explicit BFS of the implication queue (no recursion, W15): while `SAT_QHEAD < SAT_TRAIL_LEN` and no conflict, pop `just_lit`, scan the watch list of `neg(just_lit)`. For each watched clause: skip-and-swap-remove if dead; else ensure the falsified literal sits in watch slot 1, read the other watch; if the other watch is true the clause is satisfied (advance); else scan literals `≥2` for a non-false replacement watch (relocate watch, swap-remove from this list); if none found and the other watch is unassigned, enqueue it (unit) with this clause as reason; if the other watch is false, record the conflict clause and terminate the scan by setting the loop index to the live length (W14 — counter-driven exit, **no `break`**). Returns `SAT_NULL_CL` (no conflict) or the conflicting clause id. Watch-list mutation uses swap-remove with a `len` counter so traversal order stays deterministic. M4: every decision here is exact (literal truth values), never a guess.

**`sat_analyze(conflict_cl)`** — hand-rolled **1UIP** resolution with no recursion: clear `SAT_SEEN[0..NVAR]`; set `SAT_OUT_LEN=1` (slot 0 reserved for the asserting literal). Maintain `counter` = number of seen, still-unresolved literals at the current decision level. Expand `current_cl` (initially the conflict clause): for each literal `q ≠ pivot` with an unseen variable at level `>0`, mark seen; if its level `≥ SAT_LEVEL` bump `counter`, else append `q` to `SAT_OUT_LEARN`. Then walk the trail backward to the next seen variable at the current level, make it the pivot, unseen it, decrement `counter`, and set `current_cl` to its reason. When `counter==0` the pivot is the UIP; `SAT_OUT_LEARN[0] = neg(pivot)`; done. Finally `SAT_OUT_BJ` = max decision level among `SAT_OUT_LEARN[1..]` (0 if the learned clause is a unit). **REMOVED:** the `SAT_VAR_ACT[v] += 1` accumulation (Gap/Fix #1 — forbidden M3 counting). All loops sentinel-driven (W14); compares are unsigned (`==`/`<` on `u32`) — never signed-ordering (Trap 3 N/A here).

**`sat_undo_until(level)`** — pop the trail down to `SAT_LEVEL_BASE[level+1]`, clearing each popped variable (`VAL=0`, `LEVEL=0`, `REASON=SAT_NULL_CL`), then set `SAT_TRAIL_LEN=SAT_QHEAD=target` and `SAT_LEVEL=level`. Early-return when `level >= SAT_LEVEL` **before** indexing `SAT_LEVEL_BASE` (Gap/Fix #6 cleanup — removes the dead `keep` local and the pre-guard array read). Reversibility (M9): backjumping fully restores prior state; combined with `sat_init` the solver is always recoverable (M5).

**`sat_record_learned()`** — append `SAT_OUT_LEARN[0..SAT_OUT_LEN)` as a learned clause (capacity-guarded; on overflow set `SAT_ALLOC_FAIL=1` and return `SAT_NULL_CL`, Gap/Fix #4). Watch the asserting literal (slot 0) and a literal at level `SAT_OUT_BJ` (found by scan; swapped into slot 1 in both `SAT_OUT_LEARN` and the stored block so the two-watch invariant holds after backjump), each via `sat_watch_add` with `SAT_ALLOC_FAIL` checked.

**`sat_pick_branching_variable()`** — **FIXED STRUCTURAL RULE (Gap/Fix #1):** return the smallest-index unassigned variable (`SAT_VAR_VAL[i]==0`), scanning `i = 1..NVAR`; return `0u32` if all assigned. This is a *static variable order* — total, exact, and a pure function of the current partial assignment; it carries **no accumulated state and learns nothing from the search trace** (M2/M3/M4). CDCL remains sound and complete under any fixed order; only search length, never the SAT/UNSAT verdict or the model, depends on it. This replaces the gospel's max-activity selection.

**`sat_solve()`** — guard `SAT_INITED`. Propagate once at level 0; a conflict there ⇒ `SAT_UNSAT`. Then the sentinel loop (W14, no recursion W15): propagate; on conflict, `SAT_CONFLICTS++`, and if `SAT_LEVEL==0` ⇒ `SAT_UNSAT`, else analyze → `sat_undo_until(SAT_OUT_BJ)` → `new_cl = sat_record_learned()` → **if `new_cl==SAT_NULL_CL` or `SAT_ALLOC_FAIL==1` ⇒ return `SAT_E_TOO_BIG`** (Gap/Fix #4) → enqueue the asserting literal `SAT_OUT_LEARN[0]` with reason `new_cl`. On no conflict, pick the branching variable; `0` ⇒ `SAT_SAT`; else open a new level (`SAT_LEVEL_BASE[SAT_LEVEL]=SAT_TRAIL_LEN`), enqueue the **positive** literal of that variable (fixed phase — deterministic), `SAT_DECISIONS++`. No restarts, no clause deletion, no randomness.

**`sat_value` / `sat_n_learned` / `sat_n_decisions` / `sat_n_conflicts`** — pure readers; `sat_value` maps internal `2→1` (true), `1→0` (false), `0/oob→0xFF`.

## KAT Vectors (≥3)
Each vector is `sat_init` → a sequence of `sat_add_clause` → `sat_solve` → assertions, checked byte-for-byte by the Phase-2 self-test. Literals use the encoding `pos(v)=2v`, `neg(v)=2v+1`. Determinism is asserted by running each instance twice and requiring identical verdict, model, and counters.

1. **Trivial SAT (single positive unit).** `sat_init(1)`; `sat_add_clause([pos(1)=2], 1)`; `sat_solve()` ⇒ `SAT_SAT`. `sat_value(1)==1u8`. `sat_n_decisions()==0u64` (unit forced at level 0; no decision needed). `sat_n_conflicts()==0u64`.

2. **Trivial UNSAT (contradictory units).** `sat_init(1)`; `sat_add_clause([pos(1)=2],1)` ⇒ `SAT_OK`; `sat_add_clause([neg(1)=3],1)` ⇒ `SAT_E_TRIV_UNSAT` (caller learns UNSAT at add-time). For the propagation path: `sat_init(1)`; add `[2]` then call `sat_solve()` after also adding `[3]` via a non-unit wrapper is not possible, so the canonical UNSAT-by-solve vector is #4 below.

3. **Forced chain SAT (unit propagation, no decision).** `sat_init(3)`; clauses `(¬1 ∨ 2)=[3,4]`, `(¬2 ∨ 3)=[5,6]`, `(1)=[2]`. `sat_solve()` ⇒ `SAT_SAT`; `sat_value(1)==1`, `sat_value(2)==1`, `sat_value(3)==1`; `sat_n_decisions()==0u64` (all forced from the level-0 unit `1`). Confirms the two-watch unit propagation and the no-decision fast path.

4. **UNSAT requiring conflict analysis + backjump.** The 4-clause contradiction over 2 vars: `(1∨2)=[2,4]`, `(1∨¬2)=[2,5]`, `(¬1∨2)=[3,4]`, `(¬1∨¬2)=[3,5]`. No units, so `sat_solve()` decides var 1 = true (smallest index, positive phase), propagates, hits a conflict, analyzes, backjumps to level 0, learns the unit `(¬1)`, then decides/propagates var 1 = false and derives the empty-style level-0 conflict ⇒ `SAT_UNSAT`. Assert `SAT_UNSAT`, `sat_n_conflicts() >= 1u64`, `sat_n_learned() >= 1u32`. Exercises `sat_analyze`, `sat_undo_until`, `sat_record_learned`, and the `SAT_LEVEL==0` UNSAT exit.

5. **Pigeonhole PHP(2,1) UNSAT (3 holes infeasible reduced form) — learning stress.** Encode "2 pigeons, 1 hole" : vars `x_{p,h}`, clauses "each pigeon in the hole" `(x_{1,1})`,`(x_{2,1})` plus "no two pigeons share the hole" `(¬x_{1,1} ∨ ¬x_{2,1})`. `sat_init(2)` with `x_{1,1}=1`, `x_{2,1}=2`; clauses `[2]`, `[4]`, `[3,5]`. Adding `[2]` and `[4]` forces both true at level 0; `[3,5]=(¬1∨¬2)` becomes a level-0 conflict on add/solve ⇒ `SAT_UNSAT`. Asserts level-0 conflict detection through `sat_propagate` returning non-null at the initial propagate.

6. **Determinism / reset reproducibility.** Run vector #4 twice with a `sat_init(2)` between runs; assert identical `(verdict, sat_n_conflicts, sat_n_learned, sat_n_decisions)` tuple both times (M2/M10 — the solve is a pure function of the clause sequence).

## Trap Exposure
- **Trap 1 (multi-line `fn`)** — EXPOSED (every fn). Avoidance: **every signature in the skeleton is single-line**; Phase 2 must keep them single-line.
- **Trap 2 (linker-global `const`)** — EXPOSED (12 module consts). Avoidance: all prefixed `SAT_`; grep confirmed no collision.
- **Trap 3 (signed-ordering SIGSEGV)** — NOT EXPOSED. Every compare in the algorithm is on `u32`/`u64`/`u8` (unsigned). `i32` values are only error-status sentinels compared with `==`/`!=` (e.g. `cmp == -1i32` is never used here; statuses are returned, not ordered). No `i64`/`i32` `<`/`>`/`<=`/`>=` anywhere.
- **Trap 4 (`u32`-in-`u64`-slot pointer math)** — LOW EXPOSURE. The only external pointer indexing is `lits[i]` (`lits: *u32`, `i: u32`) in `sat_add_clause`; all other indexing is `ARRAY[u32_expr]` on typed module arrays (compiler scales by element size). Avoidance: keep `lits[i]` as a typed-pointer index (matches the working `coeffs[i]`/`vars[i]` idiom in `smt.iii`); **if** Phase 2 lowers it to manual `base + i*4` math, mask `(i as u64) & 0xFFFFFFFFu64` first.
- **Trap 5 (`*u32` store width)** — NOT EXPOSED. The module never stores through a `*u32` *pointer*; all writes are `ARRAY[idx] = value` into typed `[u32; N]` module arrays (the input `lits` is read-only). No byte-wise store needed.
- **Trap 6 (nested `/* */`)** — AVOID by construction: header/comment blocks never nest; inline notes use `//`.
- **Trap 7 (local `var` arrays)** — **WAS VIOLATED** by the gospel (`var scratch`/`var packed` inside `sat_add_clause`). FIXED: hoisted to module scope as `SAT_SCRATCH`/`SAT_PACKED` (non-reentrant, acceptable — single-threaded solver, no re-entry). No local `var` arrays remain.
- **Trap 8 (`} else {` split)** — AVOID: this module uses the cascaded-`if` style (as the gospel body does); any `else` introduced in Phase 2 must be `} else {` on one line.
- **Trap 9 (em-dash in comment)** — AVOID: all comments use ASCII `--`, never `—`.
- **Trap 10 (`let mut x = 0u32` flag)** — LOW EXPOSURE. The body uses `let mut found/done/removed : u8` flags driving sentinel loops; these are `u8`, not the problematic `u32` checkpoint-flag pattern, and they drive the loop condition directly (W14). Acceptable; prefer early-return where a flag would otherwise be a single-shot checkpoint.
- **Trap 11 (`a % b` after a call)** — NOT EXPOSED. The algorithm contains **no modulo operation** (all watch/clause indexing is additive into bump arenas). Nothing to mask.
- **Trap 12 (`@specialize *T` stride)** — NOT EXPOSED. No `@specialize` / generic element-width code; all arrays are concretely typed.

## Gap / Fix List
PARTIAL — the following must be closed in Phase 2. Each is a concrete edit to the gospel body.

1. **M3/M4 — forbidden activity heuristic (CRITICAL, mandate).** The gospel accumulates `SAT_VAR_ACT[v] += 1u64` in `sat_analyze` and selects the max-activity variable in `sat_pick_branching_variable`. Counting appearances across the solve trace and promoting high-count variables is "count-and-promote / observe-and-adapt" — **forbidden by M3** (and a heuristic per M4), even though it is deterministic. **Fix:** delete `var SAT_VAR_ACT`; delete the `SAT_VAR_ACT[v] += 1u64` line in `sat_analyze`; rewrite `sat_pick_branching_variable` to return the smallest-index unassigned variable (static order). Also reconciles the gospel's own prose/code mismatch ("smallest index that appears in the most learned clauses" vs. the code's "max activity"). Completeness/soundness of CDCL is preserved under any fixed order.

2. **OOB-read SIGSEGV in the clause insertion-sort (CRITICAL, crash).** In `sat_add_clause` the inner descent is:
   `while q > 0u32 { if scratch[q-1] > scratch[q] { swap; q = q-1 } ; if scratch[q-1] <= scratch[q] { q = 0 } }`.
   When a swap drives `q` to `0`, control still falls into the second `if`, which reads `scratch[q - 1u32]` = `scratch[0u32 - 1u32]` = `scratch[0xFFFFFFFFu32]` → wild read past a `[u32; N]` array → SIGSEGV. This fires for any clause whose smallest literal is not already first (the common case). **Fix:** guard the second compare with `q`: restructure to a single flag-driven descent where **the `q>0` test gates every `scratch[q-1]` access**, e.g.
   `let mut moving : u8 = 1u8 ; while moving == 1u8 { if q == 0u32 { moving = 0u8 } ; if moving == 1u8 { if scratch[q-1] <= scratch[q] { moving = 0u8 } } ; if moving == 1u8 { swap(q-1,q) ; q = q - 1u32 } }`.
   (This is the canonical W14 sentinel form; matches the `feedback_iiis1_insort_active_flag` lesson — the flag drives the `while`, and no `scratch[q-1]` is ever read with `q==0`.)

3. **Missing input-length bound on `sat_add_clause` (W8/correctness).** The gospel copies `lits[0..n_lits)` into a `[u32; 4096]` scratch with **no `n_lits` bound check** → silent OOB write for clauses longer than the scratch. **Fix:** add `if n_lits > SAT_MAX_CLAUSE_LEN { return SAT_E_TOO_BIG }` before the copy, and size the scratch arrays to `SAT_MAX_CLAUSE_LEN` (see #5).

4. **Unchecked allocation-failure paths (soundness).** `sat_watch_add` and `sat_record_learned` can return `SAT_E_TOO_BIG`/`SAT_NULL_CL` on arena exhaustion, but every caller in the gospel **ignores the return** — a dropped watch silently breaks the two-watch invariant (missed propagations ⇒ possibly wrong SAT/UNSAT), and `sat_solve` enqueues with `reason = SAT_NULL_CL` (a corrupted "decision" reason) after a failed `sat_record_learned`. **Fix:** add a sticky `var SAT_ALLOC_FAIL : u8`; set it in `sat_watch_add` and `sat_record_learned` on overflow; in `sat_solve`, after `sat_record_learned` (and after each propagate that may have grown watches) check `if SAT_ALLOC_FAIL == 1u8 { return SAT_E_TOO_BIG }`, and check `if new_cl == SAT_NULL_CL { return SAT_E_TOO_BIG }` before enqueuing the asserting literal. This converts exhaustion into a clean, recoverable refusal (M5: no bricking).

5. **Under-sized learned-clause + canonicalisation buffers (correctness).** `SAT_OUT_LEARN`, `scratch`, and `packed` are `[u32; 4096]`, but a learned clause or input clause can have up to `NVAR` (= up to 65536) distinct variables. **Fix:** size `SAT_OUT_LEARN`, `SAT_SCRATCH`, `SAT_PACKED` to `[u32; 65537]` (= `SAT_MAX_CLAUSE_LEN`), justified by "≤ NVAR distinct vars per clause."

6. **Dead/ordered-wrong code in `sat_undo_until` (cleanup, latent).** `let mut keep` is assigned twice and never read; `SAT_LEVEL_BASE[level+1]` is read before the `level >= SAT_LEVEL` early-return. **Fix:** remove `keep`; put `if level >= SAT_LEVEL { return SAT_OK }` first, then read `target = SAT_LEVEL_BASE[level+1]`. Not a crash for valid backjump levels but must be cleaned for M2 clarity.

7. **W13 proximity (advisory).** `sat_analyze` (~16–18 distinct named locals) and `sat_propagate` (~13) sit near the 20-local cap. **Constraint for Phase 2:** do not introduce additional temporaries; reuse the documented locals. No change required to the gospel body, but the implementer must respect the cap.

8. **Const name reconciliation (cleanup).** Doc-comment says `SAT_E_TRIVIAL_UNSAT`; code uses `SAT_E_TRIV_UNSAT`. **Fix:** standardise on `SAT_E_TRIV_UNSAT` everywhere (the public-API contract above already does).

Mandates verified satisfied by construction (no change needed): **M1** (zero externs, all hand-rolled), **M2/W5** (pure deterministic after #1), **M5** (fixed BSS + error-on-overflow, recoverable via `sat_init`), **M8** (no privileged op ⇒ no capability arg, consistent with peer compute kernels `bitops`/`bigint`), **M9** (`sat_undo_until` + `sat_init` make state reversible), **M15** (all ops total over their bit width — masked where needed), **M19** (cost bounded by the fixed array sizes). **M6/M10/M16/M17/M18** (witness/memo/branch) are out of scope for this pure algebraic kernel — the gospel discipline header lists only `W1,W2,W8,W13,W14,W15`, deliberately omitting the witness laws; the *consumer* (smt → ... → ledger) carries the witness, not the SAT core.

## Implementation Skeleton
Structurally paste-ready. All signatures single-line (Trap 1). No fn bodies (Phase 2 writes those per Algorithm §). ASCII-only comments (Trap 9). No local `var` arrays (Trap 7).

```iii
/* III/STDLIB/iii/numera/sat.iii
 *
 * III STDLIB - numera::sat
 *
 * Deterministic CDCL SAT solver. Conflict-driven, clause learning,
 * non-chronological backjumping, two-watched literals, 1UIP conflict
 * analysis. No restarts; no randomness; no clause deletion; no
 * learned-from-data heuristic. Decision rule is a FIXED static order
 * (smallest unassigned variable, positive phase) -- M2/M3/M4 compliant.
 *
 * Public API:
 *   sat_init(n_vars: u32) -> i32
 *   sat_add_clause(lits: *u32, n_lits: u32) -> i32
 *   sat_solve() -> i32                 (SAT_SAT / SAT_UNSAT / negative)
 *   sat_value(var: u32) -> u8          (0 false, 1 true, 0xFF unknown)
 *   sat_n_learned() -> u32
 *   sat_n_decisions() -> u64
 *   sat_n_conflicts() -> u64
 *
 * Literal encoding: v in 1..NVAR; pos = (v<<1); neg = (v<<1)|1.
 * Value encoding:   0 = unassigned, 1 = false, 2 = true.
 *
 * Hexad: kind_essence.  Ring: R0.  K: 0.99.
 * Discipline: W1, W2, W8, W13, W14, W15 (no recursion).
 */

module numera_sat

const SAT_OK              : i32 =  0i32
const SAT_SAT             : i32 =  1i32
const SAT_UNSAT           : i32 =  2i32
const SAT_E_TRIV_UNSAT    : i32 = -1i32
const SAT_E_TOO_BIG       : i32 = -2i32
const SAT_E_NOT_INIT      : i32 = -3i32

const SAT_MAX_VARS        : u32 = 65536u32
const SAT_MAX_CLAUSES     : u32 = 262144u32
const SAT_MAX_LITS_BLOCK  : u32 = 2097152u32
const SAT_MAX_WATCH       : u32 = 16777216u32
const SAT_MAX_CLAUSE_LEN  : u32 = 65537u32
const SAT_NULL_CL         : u32 = 0xFFFFFFFFu32

/* Per-variable state (index 0 unused; 1..NVAR live). */
var SAT_VAR_VAL    : [u8;  65537]
var SAT_VAR_LEVEL  : [u32; 65537]
var SAT_VAR_REASON : [u32; 65537]
var SAT_VAR_POS    : [u32; 65537]

/* Assignment trail + propagation cursor. */
var SAT_TRAIL      : [u32; 65537]
var SAT_TRAIL_LEN  : u32 = 0u32
var SAT_QHEAD      : u32 = 0u32

/* Decision-level boundaries. */
var SAT_LEVEL_BASE : [u32; 65537]
var SAT_LEVEL      : u32 = 0u32

/* Clause database: headers + packed literal block. */
var SAT_CL_LIVE    : [u8;  262144]
var SAT_CL_SIZE    : [u32; 262144]
var SAT_CL_OFF     : [u32; 262144]
var SAT_CL_LEARNED : [u8;  262144]
var SAT_CL_USED    : u32 = 0u32
var SAT_LIT_BUF    : [u32; 2097152]
var SAT_LIT_USED   : u32 = 0u32

/* Watch lists: one growable chunk per literal in a bump arena. */
var SAT_WATCH_HEAD : [u32; 131074]
var SAT_WATCH_LEN  : [u32; 131074]
var SAT_WATCH_CAP  : [u32; 131074]
var SAT_WATCH_BUF  : [u32; 16777216]
var SAT_WATCH_USED : u32 = 0u32

/* Conflict-analysis scratch (learned clause built here). */
var SAT_SEEN       : [u8;  65537]
var SAT_OUT_LEARN  : [u32; 65537]
var SAT_OUT_LEN    : u32 = 0u32
var SAT_OUT_BJ     : u32 = 0u32

/* Clause-canonicalisation scratch (hoisted from local var; non-reentrant). */
var SAT_SCRATCH    : [u32; 65537]
var SAT_PACKED     : [u32; 65537]

/* Counters / status. */
var SAT_NVAR       : u32 = 0u32
var SAT_DECISIONS  : u64 = 0u64
var SAT_CONFLICTS  : u64 = 0u64
var SAT_INITED     : u8  = 0u8
var SAT_ALLOC_FAIL : u8  = 0u8

/* --- Literal helpers --- */
fn sat_lit_var(lit: u32) -> u32 { return lit >> 1u32 }
fn sat_lit_sign(lit: u32) -> u32 { return lit & 1u32 }
fn sat_lit_neg(lit: u32) -> u32 { return lit ^ 1u32 }
fn sat_mk_lit(v: u32, sign: u32) -> u32 { return (v << 1u32) | (sign & 1u32) }

fn sat_lit_value(lit: u32) -> u8 {
    // TODO: body per Algorithm (literal truth under current assignment).
}

/* --- Lifecycle --- */
fn sat_init(n_vars: u32) -> i32 @export {
    // TODO: body per Algorithm (reject > SAT_MAX_VARS; zero state; SAT_ALLOC_FAIL=0; SAT_INITED=1).
}

/* --- Watch-list management (sets SAT_ALLOC_FAIL on exhaustion; Gap/Fix #4) --- */
fn sat_watch_add(lit: u32, cl: u32) -> i32 {
    // TODO: body per Algorithm (append; realloc-by-doubling; bound by SAT_MAX_WATCH).
}

fn sat_watch_remove(lit: u32, cl: u32) -> i32 {
    // TODO: body per Algorithm (single swap-remove; sentinel loop).
}

/* --- Clause addition (Trap-7 scratch hoisted; #2 trap-safe sort; #3 bound) --- */
fn sat_add_clause(lits: *u32, n_lits: u32) -> i32 @export {
    // TODO: body per Algorithm (guard INITED; n_lits in [1, SAT_MAX_CLAUSE_LEN];
    //       copy->SAT_SCRATCH; trap-safe insertion sort; dedup+tautology->SAT_PACKED;
    //       append header/lits; unit-at-level-0 enqueue; else install 2 watches, check SAT_ALLOC_FAIL).
}

/* --- Enqueue + propagate (no recursion; W14 exits) --- */
fn sat_enqueue(lit: u32, reason: u32) -> i32 {
    // TODO: body per Algorithm (assign var, record level/reason/pos, push trail).
}

fn sat_propagate() -> u32 {
    // TODO: body per Algorithm (two-watch BFS; returns SAT_NULL_CL or conflicting clause id).
}

/* --- Conflict analysis (1UIP; activity accumulation REMOVED, Gap/Fix #1) --- */
fn sat_analyze(conflict_cl: u32) -> i32 {
    // TODO: body per Algorithm (counter-driven 1UIP; build SAT_OUT_LEARN; set SAT_OUT_BJ).
}

fn sat_undo_until(level: u32) -> i32 {
    // TODO: body per Algorithm (early-return level>=SAT_LEVEL first, then pop to LEVEL_BASE[level+1]; #6).
}

fn sat_record_learned() -> u32 {
    // TODO: body per Algorithm (append learned clause; watch UIP + backjump-level lit;
    //       set SAT_ALLOC_FAIL / return SAT_NULL_CL on overflow; Gap/Fix #4).
}

/* --- FIXED structural decision rule: smallest unassigned variable (Gap/Fix #1) --- */
fn sat_pick_branching_variable() -> u32 {
    // TODO: body per Algorithm (scan 1..NVAR for first SAT_VAR_VAL[i]==0; 0 if none).
}

/* --- Top-level solve --- */
fn sat_solve() -> i32 @export {
    // TODO: body per Algorithm (level-0 propagate; CDCL sentinel loop;
    //       check new_cl==SAT_NULL_CL and SAT_ALLOC_FAIL -> SAT_E_TOO_BIG; positive-phase decisions).
}

/* --- Readers --- */
fn sat_value(var: u32) -> u8 @export {
    // TODO: body per Algorithm (map 2->1, 1->0, 0/oob->0xFF).
}

fn sat_n_learned() -> u32 @export {
    // TODO: body per Algorithm (count live learned clauses).
}

fn sat_n_decisions() -> u64 @export { return SAT_DECISIONS }
fn sat_n_conflicts() -> u64 @export { return SAT_CONFLICTS }
```
