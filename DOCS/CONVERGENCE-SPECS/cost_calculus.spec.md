# 23 numera/cost_calculus.iii — Implementation Spec

## Verdict
PARTIAL — the gospel candidate computes all six cost dimensions and is structurally close, but it has a hard W2 violation (5-param `cc_evaluate`), a Trap-2 linker collision (`CC_OK` clashes with `omnia/call_context.iii`), a Trap-7 function-local `var` array, two Trap-1 multi-line signatures (silent-corruption risk), multiple unchecked bounds that overflow `live_until[1024]` / read `CC_SIZE[]` out of range when `n > 1024` or any opcode/dep index is out of range, it discards `ma_simulate`'s return code, and it emits no witness. All are fixed below.

## Purpose
`cost_calculus` is the closed-form evaluator that maps an operation/dependency graph to a six-entry cost vector under the cost lattice: it runs the deterministic micro-architectural simulator (`ma_simulate`, Module 21) to obtain latency in cycles, then derives throughput (fixed-point, 3 decimal digits), peak register pressure (max simultaneously-live operands), i-cache footprint (Σ encoded sizes), d-cache footprint (Σ tagged memory deltas), and energy (Σ per-opcode energy) by exact integer polynomials over module-scope tables. It is the essence-kind cost oracle invoked by `cg_superopt` (Module 40) to rank candidate instruction sequences. **Hexad: kind_essence. Ring: R0. K-vector: 1.00 (pure deterministic evaluation; no allocation, no I/O).**

## Public API
All signatures SINGLE-LINE (Trap 1). Status returns are negative-`i32` error / `CCALC_OK==0` (W9/W12); the boolean-ish setters also return `i32` status, not `u8`, to match the gospel surface and `microarch_model` house style.

```
fn cc_init() -> i32 @export
fn cc_set_energy(opcode: u32, energy: u32) -> i32 @export
fn cc_set_size(opcode: u32, size: u32) -> i32 @export
fn cc_set_dcache(opcode: u32, dcache: u32) -> i32 @export
fn cc_evaluate(req: *u8, out_cost: *u64) -> i32 @export
fn cc_evaluate_witnessed(req: *u8, out_cost: *u64, wcap: u64) -> i32 @export
```

Return-status convention per fn:
- `cc_init` — always `CCALC_OK` (0). W12 satisfied by sentinel-typed status.
- `cc_set_energy` / `cc_set_size` / `cc_set_dcache` — `CCALC_OK` on success; `CCALC_E_OPCODE` (-1) if `opcode >= CCALC_MAX_OPCODE`. (W9 negative codes; W11 — callers compare `== CCALC_OK` / `!= CCALC_OK`, never ordering.)
- `cc_evaluate` — `CCALC_OK` and fills `out_cost[0..5]`; else a negative code (`CCALC_E_NULL`, `CCALC_E_NOPS`, `CCALC_E_NDEPS`, `CCALC_E_OPCODE`, `CCALC_E_DEPIDX`, `CCALC_E_SIM`) and leaves `out_cost` **fully zeroed** (no partial/garbage vector — M5).
- `cc_evaluate_witnessed` — as `cc_evaluate`, but additionally emits one witness fragment binding `(req-hash, out_cost-hash)` under capability `wcap`; `CCALC_E_CAP` (-7) if `wcap` is not a valid witness capability. The `wcap==0` path is rejected (no silent unwitnessed transition).

### W2 resolution — the request aggregate
`cc_evaluate` in the gospel takes **5 scalar params** (`ops, n, deps, dep_n, out_cost`), violating W2 (≤4). Fix: collapse the graph inputs into a caller-owned, by-pointer aggregate `*u8 req` (the W2-prescribed "pass an aggregate by pointer"). `out_cost` stays a separate out-param so callers reuse one request for several lattice orders. Layout (caller fills; little-endian; offsets in bytes):

```
req + 0   : u64  ops_ptr     (address of the u32 opcode array, length n)
req + 8   : u64  n           (operation count; low 32 bits significant)
req + 16  : u64  deps_ptr    (address of the u32 (consumer,producer) pair array)
req + 24  : u64  dep_n       (number of dependency PAIRS; low 32 bits significant)
```
`CCALC_REQ_BYTES = 32`. This makes the public signature 2 params + `cc_evaluate_witnessed` 3 params — both ≤4 (W2 ✓).

## Constant Namespace
PREFIX = `CCALC_`  — grep of `STDLIB/` confirms **no existing `CCALC_` symbol** (zero matches). Note: the gospel candidate used prefix `CC_`, which **collides** with `STDLIB/iii/omnia/call_context.iii:43` (`const CC_OK : i32 = 0i32`) and `omnia/call_context.iii:37-38` (`CC_BYTES`, `CC_TABLE_CAP`) plus `numera/checked_crystal.iii:46-53` (`CC_OP_*`, `CC_ERR_*`). Per Trap 2 every module-level `const` emits a linker-global `L_<NAME>`; two `L_CC_OK` definitions fail the link. **Every `CC_` must be renamed `CCALC_`.**

Module-level constants (name : type = value):
```
CCALC_OK         : i32 =  0i32     -- success
CCALC_E_OPCODE   : i32 = -1i32     -- opcode >= MAX_OPCODE (setter or in ops[])
CCALC_E_NULL     : i32 = -2i32     -- req or out_cost or an embedded ptr is null
CCALC_E_NOPS     : i32 = -3i32     -- n == 0 or n > MAX_OPS
CCALC_E_NDEPS    : i32 = -4i32     -- dep_n > MAX_DEPS
CCALC_E_DEPIDX   : i32 = -5i32     -- a dep consumer/producer index >= n
CCALC_E_SIM      : i32 = -6i32     -- ma_simulate returned non-OK
CCALC_E_CAP      : i32 = -7i32     -- witness capability invalid (witnessed variant)
CCALC_MAX_OPCODE : u32 = 4096u32   -- table dimension (matches MA_MAX_OPCODE)
CCALC_MAX_OPS    : u32 = 1024u32   -- max ops per eval (matches MA_MAX_OPS; bounds scratch)
CCALC_MAX_DEPS   : u32 = 4096u32   -- max dep pairs (matches MA_MAX_DEPS)
CCALC_REQ_BYTES  : u64 = 32u64     -- request aggregate size
CCALC_DIM        : u64 = 6u64      -- cost-vector dimension
CCALC_TP_SCALE   : u64 = 1000u64   -- throughput fixed-point scale (3 decimal digits)
CCALC_U32_MASK   : u64 = 0xFFFFFFFFu64  -- Trap-4 mask for u32-in-u64-slot
```
All are `CCALC_`-prefixed; no collision. (`CCALC_TP_SCALE` replaces the bare `1000u64` literal so the 3-decimal-digit contract is named and auditable.)

## Data Structures
All module-scope (Trap 7 — **no function-local `var` arrays**). Justified bounds:

```
var CCALC_ENERGY     : [u32; 4096]   -- per-opcode energy; dim = CCALC_MAX_OPCODE
var CCALC_SIZE       : [u32; 4096]   -- per-opcode encoded byte size; dim = CCALC_MAX_OPCODE
var CCALC_DCACHE     : [u32; 4096]   -- per-opcode d-cache delta; dim = CCALC_MAX_OPCODE
var CCALC_LIVE_UNTIL : [u32; 1024]   -- last cycle/index each def stays live; dim = CCALC_MAX_OPS
var CCALC_CYCLES     : [u64; 1]      -- scratch out-cell for ma_simulate (avoids addr-of local)
```

Bound justifications (W8):
- `CCALC_ENERGY/SIZE/DCACHE` = 4096 entries: an opcode is a `u32` table index; the model caps opcodes at `CCALC_MAX_OPCODE` (= `MA_MAX_OPCODE` = 4096). Every access is preceded by a `< CCALC_MAX_OPCODE` validation pass, so the static dimension is a hard, checked bound.
- `CCALC_LIVE_UNTIL` = 1024 entries: register pressure indexes by operation position `i < n`; `cc_evaluate` rejects `n > CCALC_MAX_OPS` (= `MA_MAX_OPS` = 1024) up front, so `i` and every validated dep index stay in `[0,1024)`. **This closes the gospel overflow**: the candidate sized the local `var live_until : [u32; 1024]` but never checked `n <= 1024` before `while i < n { live_until[i] = i }`.
- `CCALC_CYCLES` = 1 cell: `ma_simulate` writes the total cycle count through `out_cycles: *u64`; using a fixed module cell avoids taking the address of a function-local (consistent with the no-local-array discipline) and avoids the param-spill division-after-call hazard (Trap 11) — the divisor is reloaded from this named cell, not from a call-clobbered local.

Reentrancy note: `CCALC_LIVE_UNTIL` and `CCALC_CYCLES` are serialized scratch; `cc_evaluate` is **not reentrant** (acceptable — `cg_superopt` evaluates candidates serially, single-threaded, on the deterministic path). The `CCALC_*` opcode tables are configured once via the setters and read-only during evaluation.

## Dependencies (externs)
```
extern @abi(c-msvc-x64) fn ma_simulate(ops: *u32, n: u32, deps: *u32, dep_n: u32, out_cycles: *u64) -> i32 from "microarch_model.iii"
```
- **`microarch_model.iii` — Module 21 — NOT-YET-BUILT.** Provides `ma_simulate` (deterministic per-cycle in-order-issue / out-of-order-completion simulator). The extern signature here is collapsed to a **single line** even though Module 21's gospel body declares it across two lines (a Trap-1 defect in *that* module); the ABI symbol `ma_simulate` is unaffected by source line-wrapping, but my extern declaration must be single-line to compile. Wave scheduler: order Module 21 before Module 23.

Dependency-note reconciliation: the dispatch brief named `cost_lattice.iii` (Module 22) as the dependency, but the gospel candidate body depends **only** on `ma_simulate` from Module 21. Module 22 (`cost_lattice`, also NOT-YET-BUILT) is the *downstream consumer pair*: `cl_compare`/`cl_dot` take the `*u64 c` cost vector that `cc_evaluate` produces. `cost_calculus` does **not** call into `cost_lattice` (no extern needed); they meet at the 6-entry `*u64` cost-vector contract (latency, throughput, regpressure, icache, dcache, energy), which this spec and Module 22's header agree on byte-for-byte. No `cl_*` extern is declared.

Not-yet-built dependency count for the wave scheduler: **1** (Module 21 / `microarch_model.iii`). Module 22 is a sibling, not a build-order dependency of this module.

## Algorithm

### `cc_init() -> i32`
Set defaults so an unconfigured opcode is benign-but-nonzero: for `i in [0, CCALC_MAX_OPCODE)` set `CCALC_ENERGY[i]=1`, `CCALC_SIZE[i]=4`, `CCALC_DCACHE[i]=0`. Sentinel loop on `i < CCALC_MAX_OPCODE` (W14, no break). Hand-rolled fill (M1). Deterministic (M2): constant writes only. Return `CCALC_OK`.

### `cc_set_energy / cc_set_size / cc_set_dcache(opcode: u32, v: u32) -> i32`
Validate `opcode < CCALC_MAX_OPCODE` else return `CCALC_E_OPCODE`. Compare via `>=` on **`u32`** (unsigned ordering is legal; Trap 3 forbids only *signed* `i32`/`i64` ordering). Store `v` into the respective table at `[opcode]`. These are `u32`→`[u32;…]` writes (full-width array element store, not a `*u32`-pointer store), so Trap 5 (which is about writing through a `*u32` pointer) does not apply. Return `CCALC_OK`. Idempotent, deterministic.

### `cc_evaluate(req: *u8, out_cost: *u64) -> i32`  (NIH, all integer; M1/M2/M3/M4)
Explicit, no recursion (W15 — every loop is a sentinel `while`).

**Step 0 — zero the output (M5 no-garbage):** write `out_cost[0..CCALC_DIM)=0` before anything that can fail, so an early error never leaves a stale/partial cost vector.

**Step 1 — decode the request aggregate.** Reject `req == 0` or `out_cost == 0` → `CCALC_E_NULL`. Read the four u64 fields from `req` via a `*u8` byte-load helper (little-endian, same idiom as `bigint::big_load_u64_le` / `identifier.iii`):
```
ops_ptr  = load_u64_le(req, 0)
n_raw    = load_u64_le(req, 8)
deps_ptr = load_u64_le(req, 16)
dep_n_raw= load_u64_le(req, 24)
```
Reject `ops_ptr == 0` → `CCALC_E_NULL` (deps_ptr may be 0 only if `dep_n == 0`). Take `n = (n_raw & CCALC_U32_MASK)` and `dep_n = (dep_n_raw & CCALC_U32_MASK)` as u64, then derive `n32 = n as u32`, `depn32 = dep_n as u32`. The mask is the Trap-4 guard: the u64 count is narrowed and masked before it is ever used in pointer arithmetic.

**Step 2 — bound checks (closes the gospel overflow; M19 boundedness):**
- `n == 0u64` or `n > (CCALC_MAX_OPS as u64)` → `CCALC_E_NOPS`.
- `dep_n > (CCALC_MAX_DEPS as u64)` → `CCALC_E_NDEPS`.
- Validate every opcode: for `i in [0,n)`, `op = ops[i]` (typed `*u32`; index `i` masked `& CCALC_U32_MASK` before use — Trap 4); if `op >= CCALC_MAX_OPCODE` → `CCALC_E_OPCODE`. (This must precede any `CCALC_SIZE[op]` / `CCALC_ENERGY[op]` / `CCALC_DCACHE[op]` read — the gospel omitted it, so a stray opcode read past the 4096-entry table.)
- Validate every dep index: for `d in [0,dep_n)`, `consumer = deps[2d]`, `producer = deps[2d+1]` (indices `2d`,`2d+1` masked before pointer use — Trap 4); if `consumer >= n32` or `producer >= n32` → `CCALC_E_DEPIDX`. (The gospel indexed `live_until[producer]` with an unvalidated `producer`.)

All ordering compares in Steps 1–2 are on **unsigned** `u32`/`u64`, which is safe; no signed ordering (Trap 3 avoided).

**Step 3 — latency via the simulator (Trap 11 handling).** Call `ma_simulate(ops, n32, deps, depn32, &CCALC_CYCLES[0] as *u64)` and **capture its i32 return**; if `!= CCALC_OK` return `CCALC_E_SIM` (the gospel discarded this). Read `cycles = CCALC_CYCLES[0]` **from the named module cell after the call** — never reuse a pre-call local across the call boundary. `out_cost[0] = cycles` (= latency, the total cycle count).

**Step 4 — throughput (fixed-point, 3 decimal digits; M15 total).** If `cycles == 0u64` then `out_cost[1] = 0`. Else `out_cost[1] = (CCALC_TP_SCALE * n) / cycles`, where `n` is the operation count as u64 and `cycles` is the freshly-reloaded divisor from `CCALC_CYCLES[0]`. This is the only division; it is **after** the `ma_simulate` call, so to defeat the Trap-11 param-spill family the divisor is read from the module cell (Step 3) into a local immediately before the divide, and the dividend `CCALC_TP_SCALE * n` is computed into a local first; the `/` then operates on two settled locals, not on call-clobbered state. Truncating integer division is deterministic and bit-identical (W5). Division-by-zero is impossible (guarded by the `cycles == 0` branch).

**Step 5 — register pressure (max simultaneously-live operands; exact, M4 no-heuristic).** Hand-rolled live-span method:
- Initialize `CCALC_LIVE_UNTIL[i] = i` for `i in [0,n)` (each definition is at least live at its own index). `n <= CCALC_MAX_OPS` (Step 2) guarantees no overflow — this is the fix for the gospel's unchecked write.
- Extend by dependencies: for each validated `(consumer, producer)` pair, if `consumer > CCALC_LIVE_UNTIL[producer]` then `CCALC_LIVE_UNTIL[producer] = consumer` (a value stays live until its last consumer).
- Sweep the peak: for `k in [0,n)` count `live_here = #{ m in [0,k] : CCALC_LIVE_UNTIL[m] >= k }` (a value defined at `m<=k` and live until `>= k` occupies a register at point `k`); track `max_live = max(max_live, live_here)`. `out_cost[2] = max_live`.
- This is the gospel's intent with its dead `if m <= k` inner test (always true under `while m <= k`) **removed**. Complexity O(n²) with `n <= 1024` → ≤ ~1.05M iterations, a fixed bound (M19). All `while` loops are sentinel-driven (W14, W15). All compares here are unsigned (Trap 3 safe).

**Step 6 — i-cache footprint.** `out_cost[3] = Σ_{i in [0,n)} (CCALC_SIZE[ops[i]] as u64)`. Each `ops[i]` validated `< CCALC_MAX_OPCODE` in Step 2; index `i` masked before pointer use (Trap 4). Sentinel loop.

**Step 7 — d-cache footprint.** `out_cost[4] = Σ_{i in [0,n)} (CCALC_DCACHE[ops[i]] as u64)`. Same validation/masking.

**Step 8 — energy.** `out_cost[5] = Σ_{i in [0,n)} (CCALC_ENERGY[ops[i]] as u64)`. Same validation/masking.

Return `CCALC_OK`. Determinism (M2/W5): every step is integer arithmetic over fixed-width values reproduced byte-identically from `(ops, deps, CCALC_* tables)`; no FP, no time, no RNG, no observation/counting-to-promote (M3), no "good-enough" estimate (M4). Cost is bounded (M19) by `n<=1024`, `dep_n<=4096`. No allocation, no I/O — K=1.00.

### `cc_evaluate_witnessed(req: *u8, out_cost: *u64, wcap: u64) -> i32`  (M6/M10/M16/W16)
Reject `wcap == 0` → `CCALC_E_CAP` (no silent unwitnessed transition; M8 capability-mediated). Run the full `cc_evaluate` algorithm; on its non-OK result, propagate that code unchanged (no witness on failure). On `CCALC_OK`, emit one witness fragment binding the canonical hash of the decoded request `(ops bytes ‖ n ‖ deps bytes ‖ dep_n)` to the hash of the 48-byte `out_cost` vector, chained per the substrate's witness protocol under `wcap`. The fragment is recomputable byte-identically from recorded inputs (M10) because the evaluation is pure and deterministic; this anchors a cost claim that `cg_superopt` later ratifies (M16 branch ratifiability). Reversibility (W16): emission occurs only after the (pure, side-effect-free) cost is computed, so the operation is trivially reversible (drop the fragment) — nothing in the substrate state changed besides the appended witness. **Implementation note for Phase 2:** the witness/hash extern surface (e.g. a `witness_emit(...)`/`mhash(...)` from the witness layer) is not yet enumerated in this module's gospel; Phase 2 must bind it to the canonical witness module's exported API and add the corresponding `extern` + a not-yet-built marker if that module is unbuilt. The pure `cc_evaluate` path is fully specified and independent of this.

## KAT Vectors (>= 3)
Setup for all: `ma_init(); cc_init();` then (unless noted) leave default tables (`SIZE=4, ENERGY=1, DCACHE=0` per opcode) and default `ma` params (issue=4, retire=4, rob=224, ports=10, every `MA_LATENCY=1`, `MA_PORT_MASK=0xFFFFFFFF`). `out_cost` is a `[u64;6]`. The `req` aggregate is filled per the §Public API layout. Expected vectors are derived from the exact algorithm above composed with Module 21's published simulator.

**KAT-1 — single op, no deps (latency / throughput / footprints baseline).**
`ops = [7]` (opcode 7), `n = 1`, `deps = []`, `dep_n = 0`. With all latencies 1, one op issues at cycle 0, executes, retires → `cycles = 1`.
Expected `out_cost = [ 1, 1000, 1, 4, 0, 1 ]`:
- latency `=1`; throughput `=(1000*1)/1=1000`; regpressure: `LIVE_UNTIL[0]=0`, at `k=0` count `{m:LIVE_UNTIL[m]>=0}=1` → `1`; icache `=SIZE[7]=4`; dcache `=DCACHE[7]=0`; energy `=ENERGY[7]=1`.

**KAT-2 — linear dependency chain (register pressure + summed footprints, custom tables).**
Before eval: `cc_set_size(3,8); cc_set_dcache(3,2); cc_set_energy(3,5);` (opcode 3 customized; opcodes 1,2 keep defaults 4/0/1). `ops = [1, 2, 3]`, `n = 3`, `deps = [1,0, 2,1]` (op1 consumes op0; op2 consumes op1), `dep_n = 2`.
- Register pressure: init `LIVE_UNTIL=[0,1,2]`; dep(1,0)→`LIVE_UNTIL[0]=1`; dep(2,1)→`LIVE_UNTIL[1]=2`; now `LIVE_UNTIL=[1,2,2]`. Sweep: k=0 → `{m<=0:LU[m]>=0}` = {0} =1; k=1 → `{m<=1:LU[m]>=1}` = {LU[0]=1,LU[1]=2} =2; k=2 → `{m<=2:LU[m]>=2}` = {LU[1]=2,LU[2]=2} =2. `max_live = 2`.
- icache `= SIZE[1]+SIZE[2]+SIZE[3] = 4+4+8 = 16`; dcache `= 0+0+2 = 2`; energy `= 1+1+5 = 7`.
- latency from the in-order chain (each latency 1, fully serialized by deps): a 3-long dependent chain retires at `cycles = 3`; throughput `=(1000*3)/3 = 1000`.
Expected `out_cost = [ 3, 1000, 2, 16, 2, 7 ]`.  *(latency/throughput cells are co-validated against the Module-21 simulator KAT for the same `(ops,deps)`; the four table-derived cells 2/3/4/5 are independent of the simulator and must match exactly.)*

**KAT-3 — error paths (M5 no-garbage + bound enforcement).**
(a) `out_cost` pre-filled with `[9,9,9,9,9,9]`; `req` with `n = 0` → returns `CCALC_E_NOPS` (-3) and `out_cost == [0,0,0,0,0,0]` (zeroed first).
(b) `ops = [4096]`, `n = 1`, `dep_n = 0` → returns `CCALC_E_OPCODE` (-1); `out_cost` all zero. (opcode `4096 == CCALC_MAX_OPCODE` is out of `[0,4096)`.)
(c) `ops = [0,0]`, `n = 2`, `deps = [0,2]` (producer index `2 >= n`), `dep_n = 1` → returns `CCALC_E_DEPIDX` (-5); `out_cost` all zero.
(d) `n = 1025` (`> CCALC_MAX_OPS`) → returns `CCALC_E_NOPS` (-3); `out_cost` all zero. (Proves the gospel's `live_until[1024]` overflow can no longer occur.)

**KAT-4 — throughput floor.** Construct an op stream where `ma_simulate` yields `cycles=0` only for the degenerate `n>0` simulator contract is impossible (any issued op costs ≥1 cycle), so this guard is exercised via the explicit `cycles == 0` branch with a stubbed `ma` returning 0: expected `out_cost[1] == 0` (no division-by-zero). Documents the defensive branch even though the real simulator never returns 0 for `n>=1`.

Each KAT is checked byte-for-byte on the 48-byte `out_cost` and on the returned `i32`.

## Trap Exposure
- **Trap 1 (multi-line `fn`)** — EXPOSED in the gospel: `cc_evaluate(... ,\n out_cost: *u64) -> i32` and the `ma_simulate` extern both wrap. **Avoidance:** every signature in this spec is single-line; the extern is single-line; the W2 aggregate refactor also shortens `cc_evaluate` so it fits one line comfortably.
- **Trap 2 (module-level `const` is linker-global)** — EXPOSED: gospel `CC_OK` collides with `omnia/call_context.iii` `CC_OK`. **Avoidance:** prefix every const with `CCALC_`; grep confirms `CCALC_` is collision-free.
- **Trap 3 (signed ordering SIGSEGV)** — NOT EXPOSED: every comparison is on `u32`/`u64` (unsigned ordering is legal). Error codes are negative `i32` but are only ever compared by equality (`== CCALC_OK`, `!= CCALC_OK`) per W11. **Avoidance:** no `<`/`<=`/`>`/`>=` on any `i32`/`i64` value anywhere.
- **Trap 4 (u32-in-u64-slot garbage in pointer math)** — EXPOSED: `ops[i]`, `deps[2d]`, `deps[2d+1]` use u32 indices/values and `n`/`dep_n` arrive in u64 slots. **Avoidance:** mask `(x as u64) & CCALC_U32_MASK` before any value enters pointer arithmetic; narrow `n`/`dep_n` to validated `u32` immediately after the masked load.
- **Trap 5 (`*u32` pointer store width)** — NOT EXPOSED for writes: the only stores are `out_cost[k] = <u64>` through a `*u64` (correct 8-byte width) and `CCALC_*[opcode] = <u32>` into a fixed `[u32;…]` module array (full-width element store, not a `*u32`-pointer store). **Avoidance:** no value-bearing write through a `*u32` pointer; the request decode is read-only.
- **Trap 6 (nested block comments)** — avoided: comments use `//` or single non-nested `/* */`; no nesting.
- **Trap 7 (function-local `var` array)** — EXPOSED in the gospel: `var live_until : [u32; 1024]` declared inside `cc_evaluate`. **Avoidance:** promoted to module scope as `CCALC_LIVE_UNTIL : [u32;1024]` (plus `CCALC_CYCLES : [u64;1]` for the sim out-cell). Non-reentrancy noted.
- **Trap 8 (`} else {` one line)** — the algorithm uses no `else` (all branches are guarded early-returns / independent `if`s, mirroring the gospel + exemplar `checked.iii` house style). If Phase 2 introduces an `else`, it must be one line.
- **Trap 9 (em-dash in comment)** — avoidance: all comments use ASCII `--`, never U+2014.
- **Trap 10 (`let mut x = 0u32` checkpoint-flag)** — avoidance: status is returned by early-return; no mutated boolean checkpoint flag drives control flow (loop counters are fine).
- **Trap 11 (`%` / `/` after a call → quotient/stale-divisor, param-spill)** — EXPOSED: the throughput `/cycles` divide follows the `ma_simulate` call. **Avoidance:** the divisor is read from the **module-scope** `CCALC_CYCLES[0]` cell (not a call-clobbered local) into a fresh local, and the dividend into a fresh local, immediately before the `/`; both operands are settled locals. There is **no `%`** anywhere (the only reduction is a division, and it operates on reloaded state). The `& CCALC_U32_MASK` count narrowing also uses a mask, not a modulo.
- **Trap 12 (`@specialize *T` 8-byte stride)** — NOT EXPOSED: the module is not generic; no `@specialize`. All element widths are concrete (`u32` tables, `u64` cost vector).

## Gap / Fix List
The gospel candidate is PARTIAL. Every defect and its fix:

1. **W2 violation — `cc_evaluate` has 5 params.** Fix: pass graph inputs via the by-pointer `req: *u8` aggregate (`CCALC_REQ_BYTES = 32`); signature becomes `cc_evaluate(req: *u8, out_cost: *u64)` (2 params). (See §Public API.)
2. **Trap 2 — `CC_OK` (and the whole `CC_` namespace) collides** with `omnia/call_context.iii` / `numera/checked_crystal.iii`. Fix: rename all to `CCALC_` (grep-verified collision-free).
3. **Trap 1 — multi-line signatures** (`cc_evaluate`, `ma_simulate` extern). Fix: single-line every signature.
4. **Trap 7 — function-local `var live_until : [u32;1024]`.** Fix: module-scope `CCALC_LIVE_UNTIL`; add `CCALC_CYCLES` cell for the sim out-param.
5. **Unchecked `n` → buffer overflow (M19/W8).** Gospel does `while i < n { live_until[i] = i }` with no `n <= 1024` guard; `n=1025` overflows. Fix: Step 2 rejects `n == 0` or `n > CCALC_MAX_OPS` with `CCALC_E_NOPS`.
6. **Unchecked opcode → OOB table read.** Gospel reads `CC_SIZE[ops[q]]` etc. without `ops[q] < 4096`. Fix: Step 2 validates every opcode → `CCALC_E_OPCODE`.
7. **Unchecked dep indices → OOB / wild write.** Gospel indexes `live_until[producer]` with an unvalidated `producer` (and `consumer`). Fix: Step 2 validates `consumer < n && producer < n` → `CCALC_E_DEPIDX`; also rejects `dep_n > CCALC_MAX_DEPS`.
8. **`ma_simulate` return code discarded (M2/M5).** Gospel ignores it, so a failed sim yields a garbage `cycles`. Fix: capture and propagate as `CCALC_E_SIM`; on any failure leave `out_cost` fully zeroed (Step 0).
9. **Trap 4 — u32 values/indices into pointer math** (`ops[q]`, `deps[d*2u32]`, u64 `n`/`dep_n`). Fix: `& CCALC_U32_MASK` narrowing before any pointer arithmetic.
10. **Trap 11 — division `/cycles` immediately after the `ma_simulate` call.** Fix: reload `cycles` from `CCALC_CYCLES[0]` into a settled local; compute dividend into a local; divide locals only. No `%` anywhere.
11. **Dead/confusing inner test in register pressure** (`if m <= k` inside `while m <= k`, always true). Fix: removed; Step 5 states the exact live-count form.
12. **Magic literal `1000u64`** for the throughput scale. Fix: named `CCALC_TP_SCALE`, documenting the "3 decimal digits" contract.
13. **No no-garbage guarantee on error (M5).** Fix: Step 0 zeroes `out_cost` before any fallible step; every error path returns with `out_cost == 0…0`.
14. **No witness for a decision-feeding evaluation (M6/M10/M16).** The pure `cc_evaluate` is a query (defensible at K=1.00), but the cost it produces drives `cg_superopt` ratification. Fix: add `cc_evaluate_witnessed` (capability-gated, M8) that binds `(req-hash → cost-hash)` into the witness chain, recomputable byte-identically (M10), reversible (W16). Phase-2 binds the witness extern and marks it not-yet-built if needed.
15. **`let mut i` style retained** — acceptable (loop counters, not Trap-10 checkpoint flags); no change required, noted for completeness.

Mandate scorecard after fixes: M1 ✓ (hand-rolled, libc/BOOT only), M2 ✓ (integer-only, reload-after-call), M3 ✓ (no counting-to-promote / observation), M4 ✓ (exact live-span, exact polynomials), M5 ✓ (zero-on-error, bound checks), M6/M10/M16 ✓ (witnessed variant), M8 ✓ (capability-gated witness), M15 ✓ (total ops over fixed widths), M19 ✓ (n≤1024, dep_n≤4096 bounded; O(n²) peak sweep fixed-bounded). Ring R0 ✓ (no privileged access in the pure path). K=1.00 preserved (no allocation/I/O on `cc_evaluate`).

## Implementation Skeleton
Paste-ready structure; SINGLE-LINE signatures; bodies are `// TODO` per the Algorithm section. No full fn bodies (Phase 2 writes those). All comments ASCII (no em-dash; Trap 9).

```iii
/* III/STDLIB/iii/numera/cost_calculus.iii
 *
 * III STDLIB - numera::cost_calculus
 *
 * Closed-form mapping from an operation/dependency graph to a six-entry
 * cost vector (latency, throughput, regpressure, icache, dcache, energy)
 * under the cost lattice.  Pure deterministic evaluation; runs the
 * micro-architectural simulator (Module 21) for latency, then exact
 * integer polynomials over per-opcode tables for the rest.
 *
 * Public API:
 *   cc_init() -> i32
 *   cc_set_energy(opcode: u32, energy: u32) -> i32
 *   cc_set_size(opcode: u32, size: u32) -> i32
 *   cc_set_dcache(opcode: u32, dcache: u32) -> i32
 *   cc_evaluate(req: *u8, out_cost: *u64) -> i32
 *   cc_evaluate_witnessed(req: *u8, out_cost: *u64, wcap: u64) -> i32
 *
 * req aggregate (W2; 32 bytes, little-endian):
 *   +0  u64 ops_ptr | +8  u64 n | +16 u64 deps_ptr | +24 u64 dep_n
 *
 * Hexad: kind_essence.  Ring: R0.  K: 1.00 (pure).
 * Not reentrant: CCALC_LIVE_UNTIL / CCALC_CYCLES are serialized scratch.
 */

module numera_cost_calculus

extern @abi(c-msvc-x64) fn ma_simulate(ops: *u32, n: u32, deps: *u32, dep_n: u32, out_cycles: *u64) -> i32 from "microarch_model.iii"

const CCALC_OK         : i32 =  0i32
const CCALC_E_OPCODE   : i32 = -1i32
const CCALC_E_NULL     : i32 = -2i32
const CCALC_E_NOPS     : i32 = -3i32
const CCALC_E_NDEPS    : i32 = -4i32
const CCALC_E_DEPIDX   : i32 = -5i32
const CCALC_E_SIM      : i32 = -6i32
const CCALC_E_CAP      : i32 = -7i32

const CCALC_MAX_OPCODE : u32 = 4096u32
const CCALC_MAX_OPS    : u32 = 1024u32
const CCALC_MAX_DEPS   : u32 = 4096u32
const CCALC_REQ_BYTES  : u64 = 32u64
const CCALC_DIM        : u64 = 6u64
const CCALC_TP_SCALE   : u64 = 1000u64
const CCALC_U32_MASK   : u64 = 0xFFFFFFFFu64

var CCALC_ENERGY     : [u32; 4096]
var CCALC_SIZE       : [u32; 4096]
var CCALC_DCACHE     : [u32; 4096]
var CCALC_LIVE_UNTIL : [u32; 1024]
var CCALC_CYCLES     : [u64; 1]

/* --- little-endian u64 load over the *u8 request aggregate (Trap 4/5 safe; read-only) --- */
fn cc_load_u64_le(base: *u8, off: u64) -> u64 {
    // TODO: body per Algorithm Step 1 -- 8 byte-loads, shift-assemble, no *u32 store
    return 0u64
}

fn cc_init() -> i32 @export {
    // TODO: body per Algorithm cc_init -- fill ENERGY=1, SIZE=4, DCACHE=0 over [0,CCALC_MAX_OPCODE)
    return CCALC_OK
}

fn cc_set_energy(opcode: u32, energy: u32) -> i32 @export {
    // TODO: body per Algorithm cc_set_* -- validate opcode < CCALC_MAX_OPCODE (unsigned), store
    return CCALC_OK
}

fn cc_set_size(opcode: u32, size: u32) -> i32 @export {
    // TODO: body per Algorithm cc_set_* -- validate, store CCALC_SIZE[opcode]
    return CCALC_OK
}

fn cc_set_dcache(opcode: u32, dcache: u32) -> i32 @export {
    // TODO: body per Algorithm cc_set_* -- validate, store CCALC_DCACHE[opcode]
    return CCALC_OK
}

fn cc_evaluate(req: *u8, out_cost: *u64) -> i32 @export {
    // TODO: body per Algorithm Steps 0-8:
    //  0 zero out_cost[0..6) (M5)
    //  1 decode req (ptrs + masked n/dep_n); null checks -> CCALC_E_NULL
    //  2 bounds: n in (0,MAX_OPS]; dep_n<=MAX_DEPS; every opcode<MAX_OPCODE;
    //    every dep consumer/producer < n  (Trap-4 mask all indices)
    //  3 ma_simulate(... , &CCALC_CYCLES[0]); check rc -> CCALC_E_SIM; cycles=CCALC_CYCLES[0]
    //  4 throughput: cycles==0 -> 0 else (CCALC_TP_SCALE*n)/cycles  (Trap-11 reload divisor)
    //  5 regpressure: CCALC_LIVE_UNTIL init=i; extend by deps; peak live-count sweep (O(n^2), n<=1024)
    //  6 icache = sum CCALC_SIZE[ops[i]]
    //  7 dcache = sum CCALC_DCACHE[ops[i]]
    //  8 energy = sum CCALC_ENERGY[ops[i]]
    return CCALC_OK
}

fn cc_evaluate_witnessed(req: *u8, out_cost: *u64, wcap: u64) -> i32 @export {
    // TODO: body per Algorithm cc_evaluate_witnessed:
    //  reject wcap==0 -> CCALC_E_CAP (M8); run cc_evaluate; on OK emit one witness
    //  fragment binding hash(req-graph) -> hash(out_cost[0..6)) under wcap (M6/M10/M16/W16).
    //  Phase 2: bind witness/hash extern (mark not-yet-built if unbuilt).
    return CCALC_OK
}
```
