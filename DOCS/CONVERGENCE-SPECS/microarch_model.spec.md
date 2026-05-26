# 21 numera/microarch_model.iii — Implementation Spec

## Verdict
PARTIAL — the gospel candidate is a working in-order-issue / out-of-order-complete cycle simulator with real hazard, port, ROB and retire modelling, but it has hard defects that must be closed before it is mandate-clean: (1) two `fn` definitions are written across two lines (Trap 1 — silent wrong codegen), (2) `ma_simulate` takes 5 parameters (W2 violation), (3) `port_busy_until` is a local `var` array (Trap 7 — unsupported), (4) the `while done == 0u8` loop has **no termination bound** so any malformed / cyclic dependency graph hangs forever (M5 No-Bricking + M19 Cost-Lattice-Boundedness violation), (5) dependency indices (`consumer`, `producer`) are never range-checked against `n` (M4 / M5), and (6) the synthesized cost carries no recomputable certificate (M10 / M12 gap for an artifact that steers `cg_superopt`'s code selection). The core algorithm is sound and is kept; the spec below realizes its maximal intent.

## Purpose
`numera::microarch_model` is a purely analytic, deterministic model of the host CPU pipeline: it *computes* the cycle cost of a candidate instruction sequence by simulating it through an in-order front-end (issue ≤ `ISSUE_WIDTH`/cycle), an out-of-order back-end (instructions execute on one of `EXEC_PORTS` ports once their dependency operands are ready, respecting per-opcode port masks and per-opcode latencies, under a finite reorder-buffer of `ROB_CAP` slots), and an in-program-order retire unit (≤ `RETIRE_WIDTH`/cycle). It is **not** a measured or sampled model — every parameter is set explicitly by the caller (typically from `aether/shape_negotiator.iii` classification IDs) and the simulation is a closed deterministic recurrence, so it is bit-identical across runs and CPUs (M2/M3/M4 — no learning, no sampling). It is consumed by `cg_superopt` (via `numera/cost_calculus.iii`) to assign exact costs to superoptimisation candidates.
Hexad kind: **kind_essence**.  Ring: **R0**.  K-vector: **0.99** (only failure mode is a malformed request → exact refusal, never a brick).

## Public API
All public functions are exported. Error codes are negative `i32` (W9); every public fn returns a status `i32` or a sentinel-typed value (W12). **Function names retain the `ma_` prefix because `numera/cost_calculus.iii` (Module 23) already declares `extern fn ma_simulate(...) from "microarch_model.iii"` — the exported symbol names are a frozen cross-module ABI contract.** (The *const* namespace is independent — see Constant Namespace.)

```
fn ma_init() -> i32 @export
fn ma_set_params(p: *u32) -> i32 @export
fn ma_set_latency(opcode: u32, cycles: u32) -> i32 @export
fn ma_set_port_mask(opcode: u32, mask: u32) -> i32 @export
fn ma_simulate(ops: *u32, n: u32, deps: *u32, dep_n: u32, out_cycles: *u64) -> i32 @export
fn ma_simulate_req(req: *u64) -> i32 @export
fn ma_trace_hash(out32: *u8) -> i32 @export
fn ma_last_cycles() -> u64 @export
fn ma_selftest() -> u64 @export
```

Return-status convention per fn:
- `ma_init` → `UARCH_OK` always (resets latency/port tables to identity defaults).
- `ma_set_params(p)` → reads a 4-word `*u32` aggregate `[issue_width, retire_width, rob_cap, exec_ports]`; `UARCH_E_BAD` if `exec_ports == 0` or `exec_ports > UARCH_MAX_PORTS` or `issue_width == 0` or `retire_width == 0` or `rob_cap == 0`; else `UARCH_OK`. (Aggregated to satisfy W2 — the gospel's 4 scalar params were legal but the aggregate is the house idiom and leaves head-room.)
- `ma_set_latency` / `ma_set_port_mask` → `UARCH_E_BAD` if `opcode >= UARCH_MAX_OPCODE`; else `UARCH_OK`. A latency of `0` is rejected (`UARCH_E_BAD`) — every op consumes ≥1 cycle (prevents a zero-length execution that breaks the start≠0 sentinel and the cost lattice's strict-positivity, M19).
- `ma_simulate` → **the frozen 5-arg ABI shim**. Packs its 5 args into the module-scope request word array and tail-calls `ma_simulate_req`. Returns its status verbatim. (Provided for Module 23 ABI compatibility; see Gap/Fix §W2.)
- `ma_simulate_req(req)` → **the canonical W2-clean entry** (1 pointer param). `req` points at a 5-word `*u64` aggregate `[ops_ptr, n, deps_ptr, dep_n, out_cycles_ptr]` (each field stored as a u64; the two pointers are the byte addresses, `n`/`dep_n` occupy the low 32 bits of their words). Returns: `UARCH_E_TOO_BIG` if `n > UARCH_MAX_OPS` or `dep_n > UARCH_MAX_DEPS`; `UARCH_E_BAD` if any dep's `consumer >= n` or `producer >= n` (range-check, M4/M5); `UARCH_E_NOPROG` if the simulation fails to retire all `n` ops within `UARCH_MAX_CYCLES` (cyclic/unsatisfiable dependency graph — exact refusal, never an infinite loop; M5/M19); else writes the total cycle count to `*out_cycles`, records it for `ma_last_cycles`/`ma_trace_hash`, and returns `UARCH_OK`.
- `ma_trace_hash(out32)` → writes a 32-byte deterministic digest of the **last** completed simulation's full trace (per-op ready/start/end/retire cycles plus the resolved parameter set) into `out32`; `UARCH_E_NOPROG` if no simulation has completed since `ma_init`/last reset. This is the M10/M12/M18 certificate: any cost claim is recomputable and the digest binds the exact inputs that produced it.
- `ma_last_cycles` → returns the last completed simulation's cycle count (sentinel `0u64` iff none completed; a real completed sim is always ≥1 cycle, so `0` is an unambiguous "none" sentinel).
- `ma_selftest` → returns `99u64` on full pass; a small non-99 code identifies the first failing KAT (house idiom, cf. `algebraic_time::at_selftest`).

## Constant Namespace
PREFIX = `UARCH_`  (assigned by dispatch). Grep result: **no collision** — `grep -r "\b(UARCH_|MA_)[A-Z_]+" STDLIB/` returns **0 matches**, and `microarch_model` is referenced by `STDLIB/` only as `cost_calculus.iii`'s extern (function name, not a const). The gospel candidate used a bare `MA_` const prefix; that is *also* collision-free, but the dispatch-assigned `UARCH_` is adopted for every module-level `const` and `var` below. **The exported function names stay `ma_*`** (ABI contract); only constants/statics are reprefixed.

Module-level consts (all `UARCH_`-prefixed → Trap 2 safe):

| name | type | value | meaning |
|------|------|-------|---------|
| `UARCH_OK`         | i32 | `0i32`     | success |
| `UARCH_E_BAD`      | i32 | `-1i32`    | malformed parameter / opcode / dep index |
| `UARCH_E_TOO_BIG`  | i32 | `-2i32`    | n or dep_n exceeds static bound |
| `UARCH_E_NOPROG`   | i32 | `-3i32`    | no forward progress within MAX_CYCLES, or no completed sim |
| `UARCH_MAX_OPS`    | u32 | `1024u32`  | max instructions per request (W8 bound) |
| `UARCH_MAX_DEPS`   | u32 | `4096u32`  | max dependency pairs per request (W8 bound) |
| `UARCH_MAX_OPCODE` | u32 | `4096u32`  | opcode table size (W8 bound) |
| `UARCH_MAX_PORTS`  | u32 | `16u32`    | max execution ports (mask is u32 → ≤32 ports anyway; 16 is the modelled cap) |
| `UARCH_MAX_CYCLES` | u64 | `1048576u64` | hard simulation watchdog: 1024 ops × 1024 max-latency = worst-case serial bound, rounded to 2²⁰ (M19/M5) |
| `UARCH_HASH_DOMAIN`| u64 | `0x55415243485F4D31u64` ("UARCH_M1") | domain-separation tag fed to mhash for `ma_trace_hash` |

(All four pipeline parameters are mutable `var`s with defaults, not `const`s — they are reconfigured by `ma_set_params`. See Data Structures.)

## Data Structures
Every buffer is a fixed-size module-scope array (W8). **No local `var` arrays** (Trap 7) — the candidate's `var port_busy_until : [u64; 16]` inside `ma_simulate` is hoisted to module scope as `UARCH_PORT_BUSY` below.

Mutable parameter state (module-scope `var` scalars, defaulted, single writer = `ma_set_params`; W6/W7 lifecycle):
- `UARCH_ISSUE_WIDTH : u32 = 4u32`
- `UARCH_RETIRE_WIDTH : u32 = 4u32`
- `UARCH_ROB_CAP : u32 = 224u32`
- `UARCH_EXEC_PORTS : u32 = 10u32`

Opcode tables (set by `ma_set_latency` / `ma_set_port_mask`; reset to defaults by `ma_init`):
- `UARCH_LATENCY : [u32; 4096]` — per-opcode execution latency in cycles. Bound = `UARCH_MAX_OPCODE` (opcode space the codegen enumerates; justified by `cg_superopt`'s fixed opcode universe).
- `UARCH_PORT_MASK : [u32; 4096]` — per-opcode bitmask of legal ports. Same bound/justification.

Per-instruction simulation state (indexed by op position `0..n`; bound = `UARCH_MAX_OPS`):
- `UARCH_ISSUED : [u8; 1024]` — 1 once the op has entered the ROB.
- `UARCH_STARTED : [u8; 1024]` — 1 once the op has been bound to a port and begun executing. **New** (replaces the candidate's fragile `START_CYCLE == 0` sentinel; explicit flag, Trap-clean).
- `UARCH_READY_CYCLE : [u64; 1024]` — cycle at which all source operands are available.
- `UARCH_START_CYCLE : [u64; 1024]` — cycle execution began.
- `UARCH_END_CYCLE : [u64; 1024]` — cycle execution finished (= start + latency − 1 … see Algorithm for the exact convention).
- `UARCH_RETIRED : [u8; 1024]` — 1 once committed in program order.

Back-end resource state (hoisted from the candidate's local var array — Trap 7 fix):
- `UARCH_PORT_BUSY : [u64; 16]` — per-port "busy-until" cycle. Bound = `UARCH_MAX_PORTS`.

Request marshalling buffer (so `ma_simulate` can hand a single pointer to `ma_simulate_req`, W2):
- `UARCH_REQ : [u64; 5]` — `[ops_ptr, n, deps_ptr, dep_n, out_cycles_ptr]`. Module-scope, single-threaded use (note: not reentrant — acceptable, the simulator is a serial analysis pass, mirrored on `sha256`-style serialized state in STDLIB).

Last-result / certificate state:
- `UARCH_LAST_CYCLES : u64 = 0u64` — last completed total cycle count (0 = none).
- `UARCH_HAS_RESULT : u8 = 0u8` — 1 once a sim has completed since reset; gates `ma_trace_hash` / `ma_last_cycles`.
- `UARCH_LAST_N : u32 = 0u32` — op count of the last completed sim (so `ma_trace_hash` knows how many per-op records to fold).

No address-of-static escapes this file (W1/W3); all `&UARCH_*` taken only inside `microarch_model.iii`.

## Dependencies (externs)
- `extern @abi(c-msvc-x64) fn mhash_begin() -> i32 from "mhash.iii"` — **built** (used by `scalar_provenance.iii`).
- `extern @abi(c-msvc-x64) fn mhash_domain(d: u64, dl: u64) -> i32 from "mhash.iii"` — **built**.
- `extern @abi(c-msvc-x64) fn mhash_payload(p: u64, pl: u64) -> i32 from "mhash.iii"` — **built**.
- `extern @abi(c-msvc-x64) fn mhash_final(out: u64) -> i32 from "mhash.iii"` — **built**.

`mhash.iii` is the only dependency, used solely by `ma_trace_hash` for the M10/M12 certificate. **All externs are already-built modules — 0 not-yet-built dependencies.** The core simulator (`ma_init`/`ma_set_*`/`ma_simulate`/`ma_simulate_req`) is fully self-contained (no externs), exactly as in the gospel candidate; the mhash dependency is additive for the certificate and can be compiled independently of the wave order.

(Note for the wave scheduler: this module is itself a dependency of Module 23 `numera/cost_calculus.iii`, which links `ma_simulate`. The 5-arg `ma_simulate` symbol is preserved precisely so Module 23 is unaffected.)

## Algorithm
Hand-rolled (M1) discrete-event cycle simulator; no library, no ML, no heuristics, no floating point. Determinism (M2) holds because every decision is a total integer comparison over fixed module-scope state, evaluated in a fixed scan order; bit-identity (W5) holds because all state is `u8`/`u32`/`u64` integers and the only "choice" (port selection) is "lowest free port index whose mask covers the opcode," a total deterministic function of the state. No recursion (W15) — every stage is a flat `while` loop driven by a counter/flag (W14, no `break`).

### `ma_init`
For `i in 0..UARCH_MAX_OPCODE`: `UARCH_LATENCY[i] = 1u32`, `UARCH_PORT_MASK[i] = 0xFFFFFFFFu32`. Reset `UARCH_HAS_RESULT = 0u8`, `UARCH_LAST_CYCLES = 0u64`, `UARCH_LAST_N = 0u32`. Pipeline params keep their declared defaults (a fresh `ma_set_params` overrides). Return `UARCH_OK`. (Single `while` on `i`; W14.)

### `ma_set_params(p)`
Read `iw = p[0]; rw = p[1]; rc = p[2]; ep = p[3]` (all `u32`, indexing a `*u32` — 4-byte stride, no `as u64` pointer math, Trap-4 clean). Reject (`UARCH_E_BAD`) if any of `iw`, `rw`, `rc`, `ep` is `0u32`, or `ep > UARCH_MAX_PORTS`. Else assign the four `UARCH_*` vars and return `UARCH_OK`.

### `ma_set_latency(opcode, cycles)` / `ma_set_port_mask(opcode, mask)`
Range-check `opcode < UARCH_MAX_OPCODE` (`else UARCH_E_BAD`). For latency, additionally reject `cycles == 0u32` (`UARCH_E_BAD`) — strict positivity (M19). Store; return `UARCH_OK`.

### `ma_simulate(ops, n, deps, dep_n, out_cycles)` (ABI shim)
`UARCH_REQ[0] = ops as u64; UARCH_REQ[1] = n as u64; UARCH_REQ[2] = deps as u64; UARCH_REQ[3] = dep_n as u64; UARCH_REQ[4] = out_cycles as u64`. Return `ma_simulate_req(&UARCH_REQ[0] as *u64)`. (Pointers cast through `u64` — the canonical address representation in STDLIB, cf. `bigint`'s `base: u64`.)

### `ma_simulate_req(req)` — the core recurrence
1. **Unmarshal & validate.** `ops = req[0] as *u32`; `n = (req[1] & 0xFFFFFFFFu64) as u32`; `deps = req[2] as *u32`; `dep_n = (req[3] & 0xFFFFFFFFu64) as u32`; `out_cycles = req[4] as *u64`. (Mask before narrowing — Trap 4.) If `n > UARCH_MAX_OPS` or `dep_n > UARCH_MAX_DEPS` → `UARCH_E_TOO_BIG`.
2. **Dependency range-check (M4/M5).** Scan `d in 0..dep_n`: `consumer = deps[d*2]`, `producer = deps[d*2 + 1]`. If `consumer >= n` or `producer >= n` → `UARCH_E_BAD`. (`d*2` and `d*2+1` are `u32` indices into a `*u32`; no modulo, Trap-11 clean. The scan is a single `while` with an `ok` flag driving the condition — W14.)
3. **Reset per-op state.** For `i in 0..n`: `ISSUED[i]=0; STARTED[i]=0; RETIRED[i]=0; READY_CYCLE[i]=0; START_CYCLE[i]=0; END_CYCLE[i]=0`. For `q in 0..UARCH_EXEC_PORTS`: `UARCH_PORT_BUSY[q]=0u64`.
4. **Event loop** (`cycle : u64 = 0`, `retired_count : u32 = 0`, `next_issue : u32 = 0`, `done : u8 = 0`). Loop `while done == 0u8` (W14, flag-driven), with a **bounded** watchdog (M19/M5): the loop condition is effectively `done == 0u8` and at the bottom, if `cycle >= UARCH_MAX_CYCLES` then set `done = 1u8` and mark a `noprog` flag. Each iteration runs three stages in fixed order:
   - **Issue stage.** First compute `in_flight` = count of `i` with `ISSUED[i]==1 && RETIRED[i]==0` (single scan). Then from `ii = next_issue` upward, while `issued_this_cycle < ISSUE_WIDTH` **and** `in_flight < ROB_CAP` **and** `ISSUED[ii]==0`: mark `ISSUED[ii]=1`; compute its ready cycle as `max(cycle, max over deps with consumer==ii and ISSUED[producer]==1 of END_CYCLE[producer] + 1)` (a consumer may issue before its producer has executed; its ready cycle is then bounded below by `cycle` and tightened as producers finish — but since issue is in program order and a producer always precedes its consumer in `ops`, the producer is already issued, so its `END_CYCLE` is known once the producer has started; if the producer has not yet started, `END_CYCLE` is `0` and the `+1` floor keeps the consumer waiting via the start-stage `READY_CYCLE <= cycle` gate which re-reads producer ends each cycle — see note). Advance `issued_this_cycle`, `in_flight`, `next_issue = ii+1`. The inner loop terminates by setting `ii = n` when either width or ROB cap is hit (flag-style; no `break`).
   - **Dispatch/execute stage.** For each `z in 0..n` with `ISSUED[z]==1 && STARTED[z]==0`: recompute its dynamic ready cycle from current producer `END_CYCLE`s (so a consumer issued early becomes ready exactly when its last producer finishes), and if `ready <= cycle`, find the lowest port index `port in 0..EXEC_PORTS` with `(PORT_MASK[opc] & (1u32<<port)) != 0` and `UARCH_PORT_BUSY[port] <= cycle`; if found, set `STARTED[z]=1`, `START_CYCLE[z]=cycle+1`, `END_CYCLE[z]=cycle + LATENCY[opc]` (so a 1-cycle op started at `cycle` ends at `cycle + 1`; `END_CYCLE >= 1`), and `UARCH_PORT_BUSY[port] = cycle + 1` (port occupied for the issue slot; pipelined 1-cycle reservation, matching the candidate). Port search is a flat `while` with a `chosen == UARCH_MAX_PORTS` guard (no `break`).
   - **Retire stage.** For `r in 0..n` while `retired_this_cycle < RETIRE_WIDTH`: if `ISSUED[r]==1 && RETIRED[r]==0 && END_CYCLE[r] <= cycle`, and all `q2 in 0..r` are `RETIRED` (in-order commit, computed with an `all_prior` flag driving the inner `while`), then `RETIRED[r]=1`, `retired_count++`, `retired_this_cycle++`.
   - **Advance / terminate.** If `retired_count == n` → `done=1`. Else if `cycle >= UARCH_MAX_CYCLES` → `done=1` with `noprog=1`. Else `cycle = cycle + 1u64`. (All `u64` ordering compares — **safe**, the iiis SIGSEGV trap is signed-`i64`/`i32` only; confirmed by `algebraic_time.iii` and `cost_lattice.iii` shipping `<`/`>` on u64.)
5. **Result.** If `noprog == 1u8` (graph had an unsatisfiable cycle, e.g. a dep with `consumer < producer` creating a wait-for-later or a self-loop the range-check missed) → `UARCH_E_NOPROG`. Else `*out_cycles = cycle`; `UARCH_LAST_CYCLES = cycle`; `UARCH_LAST_N = n`; `UARCH_HAS_RESULT = 1u8`; return `UARCH_OK`.

Determinism / bit-identity note: the ready-cycle recomputation in the dispatch stage (rather than trusting the issue-time snapshot) is what makes the result independent of *when* a consumer happened to be issued relative to its producer — the steady state is a fixed function of `(ops, deps, params, latency, port_mask)`. The explicit `UARCH_STARTED` flag removes the candidate's reliance on `START_CYCLE==0` meaning "unstarted" (which only worked because starts are always `cycle+1 >= 1`).

### `ma_trace_hash(out32)` — M10/M12/M18 certificate
If `UARCH_HAS_RESULT == 0u8` → `UARCH_E_NOPROG`. Else: `mhash_begin()`; `mhash_domain(UARCH_HASH_DOMAIN, 8u64)`; fold the resolved parameter set (issue/retire/rob/ports as four u32→8-byte LE payloads) and then, for `i in 0..UARCH_LAST_N`, the quad `(READY_CYCLE[i], START_CYCLE[i], END_CYCLE[i], RETIRED[i] as u64)` as LE bytes via `mhash_payload`; finally `mhash_final(out32 as u64)`. Output is the 32-byte trace digest. Because every folded value is the deterministic result of `ma_simulate_req`, the digest is byte-identically recomputable from the recorded inputs (M10), and it certifies the synthesized cost (M12) so `cg_superopt`'s downstream selection is auditable (M18). Bytes are stored LE through the same idiom as `witness.iii::witness_store_u64_le` (M1: hand-rolled, no library).

### `ma_last_cycles`
Return `UARCH_LAST_CYCLES` (0 ⇔ no completed sim).

### `ma_selftest`
Runs the KAT vectors below; returns `99u64` on all-pass, else the first failing case number.

## KAT Vectors (>= 3)
All vectors assume `ma_init()` then explicit `ma_set_params`/`ma_set_latency`/`ma_set_port_mask` as stated. Opcode `0` used unless noted; default latency 1, mask `0xFFFFFFFF`.

1. **Single independent op, latency 1.** Params `[issue=4, retire=4, rob=224, ports=10]`; `ops=[0]`, `n=1`, `dep_n=0`. → `out_cycles = 1u64`, returns `UARCH_OK`. (Issued at cycle 0, started cycle→ends at 1, retired at cycle 1.) `ma_last_cycles()==1`.

2. **Chain of 3 dependent ops, latency 2 each, 1 port.** `ma_set_latency(0,2)`; params `[issue=4, retire=4, rob=224, ports=1]`, `PORT_MASK[0]` covers port 0; `ops=[0,0,0]`, `n=3`; `deps=[1,0, 2,1]` (op1←op0, op2←op1), `dep_n=2`. → fully serial: op0 ends at 2, op1 ready at 2 ends at 4, op2 ready at 4 ends at 6 → `out_cycles = 6u64`, `UARCH_OK`.

3. **Three independent ops, latency 1, issue width 4, ≥3 ports.** params `[issue=4, retire=4, rob=224, ports=4]`; `ops=[0,0,0]`, `n=3`, `dep_n=0`. → all issue cycle 0, all start, all end at 1, all retire cycle 1 (in-order, retire width 4 ≥ 3) → `out_cycles = 1u64`, `UARCH_OK`.

4. **Port contention forces serialization.** params `[issue=4, retire=4, rob=224, ports=4]`; two ops both restricted to a single shared port: `ma_set_port_mask(0, 0x1u32)` (only port 0), `ma_set_latency(0,1)`; `ops=[0,0]`, `n=2`, `dep_n=0`. → op0 takes port 0 at cycle 0 (busy-until 1), op1 cannot start at cycle 0 (port busy), starts cycle 1 ends 2 → `out_cycles = 2u64`, `UARCH_OK`. (Distinguishes the port-contention model from pure dataflow.)

5. **Bound rejection.** `n = UARCH_MAX_OPS + 1` (1025) → `ma_simulate_req` returns `UARCH_E_TOO_BIG`, `*out_cycles` untouched. **Negative case proof** (per "prove the negative" memory): the bound guard must *fire* — assert the return is exactly `-2i32`.

6. **Malformed dep rejection.** `n=2`, `deps=[0,5]` (`producer=5 >= n=2`), `dep_n=1` → `UARCH_E_BAD`. **Negative case proof.**

7. **No-progress watchdog (cyclic dep).** `n=2`, `deps=[0,1, 1,0]` (op0←op1 and op1←op0, mutual), `dep_n=2`, all defaults. Both ops issue (range-check passes: indices < 2) but neither can ever satisfy its producer's `END_CYCLE` (each waits on the other) → the loop hits `UARCH_MAX_CYCLES` → returns `UARCH_E_NOPROG`, **does not hang**. **Negative case proof of the M5/M19 termination bound.**

8. **Trace-hash determinism.** Run KAT 2 to completion, call `ma_trace_hash(buf_a)`; re-run KAT 2 from a fresh `ma_init`, call `ma_trace_hash(buf_b)` → `buf_a == buf_b` byte-for-byte (M10). And `ma_trace_hash` before any sim → `UARCH_E_NOPROG`.

`ma_selftest` encodes KATs 1–8 and returns `99u64` iff all hold. (KAT 8's exact 32-byte digest is pinned at first green build as the golden vector — it is a hand-rolled mhash output, not a third-party constant, so there is no external standard to cite; the determinism property is the gate.)

## Trap Exposure
1. **Multi-line `fn` definitions — EXPOSED in the candidate, FIXED.** The gospel writes `ma_set_params(...)` and `ma_simulate(...)` across two lines. Every signature in the Implementation Skeleton is **single-line**. (`ma_simulate`'s 5-arg line is long but single-line and legal; the wrapped form is forbidden.)
2. **Module-level `const` is linker-global — AVOIDED.** Every const/var is `UARCH_`-prefixed; grep confirms 0 collisions with `STDLIB/`. Exported *function* names keep `ma_` by ABI necessity (function symbols are namespaced by the linker per the existing `ma_simulate` extern in Module 23 — they are the contract, not a collision).
3. **Signed-integer ordering compare SIGSEGV — NOT EXPOSED.** No `i64`/`i32` value is ever compared with `<`/`<=`/`>`/`>=`. All error codes are compared `==`/`!=`. All magnitude comparisons (`cycle`, `END_CYCLE`, `READY_CYCLE`, `PORT_BUSY`, counts) are on `u64`/`u32`, which are **safe** (verified: `algebraic_time.iii` and `cost_lattice.iii` ship u64 `<`/`>`).
4. **`u32`-in-`u64`-slot garbage — AVOIDED.** `n` and `dep_n` arrive as the low 32 bits of u64 request words and are masked `(req[k] & 0xFFFFFFFFu64) as u32` before use. The two pointer fields are full u64 addresses (no narrowing). No `u32` local is widened `as u64` and fed into pointer arithmetic: array indexing uses native `u32` indices on typed pointers (`ops[z]`, `deps[d*2]`) and on module-scope arrays (`UARCH_LATENCY[opc]`), so the compiler computes the stride; no manual `base + idx*stride` on a `*u8`.
5. **`u32` pointer store width — NOT EXPOSED for the model; HANDLED in the certificate.** The simulator never stores through a `*u32` (all model state is in typed module-scope arrays). `ma_trace_hash` writes the 32-byte digest only via `mhash_final(out32 as u64)` (mhash owns the store) — but the LE folding of u64 quads into the mhash payload is done byte-by-byte through the `witness_store_u64_le` idiom (shift+mask to `u8`), never a wide `*u32`/`*u64` store, so Trap 5 is structurally avoided.
6. **Nested `/* */` comments — AVOIDED.** No comment nests; inline notes use `//` or parentheses.
7. **Local `var` array — EXPOSED in the candidate, FIXED.** The candidate's `var port_busy_until : [u64; 16]` inside `ma_simulate` is hoisted to module-scope `UARCH_PORT_BUSY : [u64; 16]`. **Reentrancy note:** like `sha256`'s serialized state, the simulator is single-threaded/serial; `UARCH_PORT_BUSY`, the per-op arrays, and `UARCH_REQ` are reused across calls and zeroed at the top of each `ma_simulate_req`. Not reentrant — documented and acceptable for a serial analysis pass.
8. **`} else {` one line — AVOIDED.** The skeleton uses no `else` (cascade of guarded `if`s in the house style); if Phase 2 introduces any `else`, it must be `} else {` on one line.
9. **Em-dash in `/* */` — AVOIDED.** All comments use ASCII `--`.
10. **`let mut x = 0u32` checkpoint-flag — PARTIALLY EXPOSED, MITIGATED.** The event loop uses mutated flags (`done`, `all_prior`, `chosen`, `ok`, `noprog`) — unavoidable for a fixed-point simulator. Per the trap, where a flag is a *simple* pass/fail checkpoint (the dep range-check `ok`, the trace-hash precondition) an **early-return** pattern is used instead of a mutated flag. The loop-control flags (`done`, `all_prior`) **drive their own `while`/`if` condition** directly (per the iiis-1 insertion-sort lesson in memory: the flag must gate the condition, not a separate clobber), which is the established-safe form (cf. the gospel candidate's own `all_prior` usage, which is correct).
11. **`a % b` after a call — NOT EXPOSED.** No modulo anywhere. Dep indexing is `d*2` / `d*2+1` (multiply/add only). Port masking is `1u32 << port` and `& mask` (bit ops). No power-of-two or general modulo is computed.
12. **`@specialize *T` 8-byte stride — NOT EXPOSED.** No `@specialize`; no generic element-width pointer. All pointers are concretely typed (`*u32`, `*u64`, `*u8`), so the compiler's per-type stride is correct.

## Gap / Fix List
PARTIAL — gospel-body defects and their fixes:

- **G1 (Trap 1, silent corruption): two-line `fn` definitions.** `ma_set_params` and `ma_simulate` are wrapped. **Fix:** collapse each to a single line (done in skeleton). This is the highest-severity defect — it produces "close but wrong" cost numbers, which would silently mis-steer `cg_superopt`.
- **G2 (W2): `ma_simulate` has 5 parameters.** **Fix:** introduce `ma_simulate_req(req: *u64)` (1 param, W2-clean) as the canonical entry; retain the 5-arg `ma_simulate` only as a thin ABI shim that marshals into `UARCH_REQ` and calls the req form — because Module 23 (`cost_calculus.iii`) already links `ma_simulate`'s 5-arg symbol. The shim's body is two assignments + a tail call, so it has 0 locals beyond the params and is itself trap-clean. (Alternative considered: change Module 23's extern to the aggregate form — rejected to avoid editing a shared/other-owner module per the briefing's "do not edit shared files.")
- **G3 (Trap 7): local `var port_busy_until : [u64; 16]`.** **Fix:** hoist to `UARCH_PORT_BUSY` module-scope array, zeroed per call.
- **G4 (M5 No-Bricking + M19 Cost-Lattice-Boundedness): unbounded `while done == 0u8`.** A malformed/cyclic dependency graph (or a producer index greater than its consumer's so the consumer waits on a never-finishing future op) makes the candidate loop **forever** — an unrecoverable hang = a brick, and the cost is not lattice-bounded. **Fix:** add `UARCH_MAX_CYCLES` watchdog; on reaching it, terminate with `UARCH_E_NOPROG` (exact refusal). KAT 7 proves the bound fires.
- **G5 (M4/M5): no range-check on dependency indices.** `consumer`/`producer` are used directly as array indices (`MA_ISSUED[producer]`) with no `< n` check → out-of-bounds read into adjacent module state on a malformed request (silent wrong cost, or read past the 1024 bound). **Fix:** pre-scan validates every `consumer < n && producer < n`, else `UARCH_E_BAD`. KAT 6 proves it.
- **G6 (M10/M12/M18): synthesized cost carries no certificate.** `ma_simulate` returns a bare cycle count that `cg_superopt` trusts to choose emitted code — an unwitnessed synthesized artifact. **Fix:** add `ma_trace_hash` producing a deterministic, recomputable 32-byte digest of the full trace + resolved parameters (via the already-built `mhash.iii`), plus `ma_last_cycles`. KAT 8 proves recomputability.
- **G7 (robustness): fragile `START_CYCLE == 0` "unstarted" sentinel.** Works only because starts are always `cycle+1 >= 1`; brittle if the start convention ever changes. **Fix:** explicit `UARCH_STARTED : [u8;1024]` flag.
- **G8 (M19 strict positivity): `ma_set_latency` accepts 0 cycles.** A zero-latency op would end at `cycle` (start `cycle+1`, end `cycle+0`) breaking the `END_CYCLE <= cycle` retire gate and yielding a degenerate cost. **Fix:** reject `cycles == 0` with `UARCH_E_BAD`.
- **G9 (consumer-before-producer dataflow correctness):** the candidate snapshots `READY_CYCLE` at issue time from producers' *current* `END_CYCLE`, which is `0` if the producer hasn't started — making a consumer spuriously "ready" at cycle 0. **Fix:** recompute the dynamic ready cycle in the dispatch stage each cycle from live producer `END_CYCLE`s (a consumer is ready iff every producer has finished). This makes the steady state a true function of the inputs (M2) rather than of issue timing. (Reflected in Algorithm §4 dispatch stage.)

Mandate coverage statement for the *kept* design: **M6/M8 (witness continuity / capability gating) intentionally do not apply to the privileged-state sense** — this is a pure `kind_essence`/R0 analytic function that mutates only its own configuration tables and reads only caller-supplied buffers; it performs no substrate state transition, exactly like its R0 `kind_essence` siblings `cost_lattice.iii` and `algebraic_time.iii`, which also take no capability and emit no witness. The synthesis-verifiability obligation (M12) that *does* apply — because the output steers code selection — is discharged by `ma_trace_hash` (G6). M3/M4 are honored throughout: no counting-and-promoting, no sampling, no thresholds; every decision is an exact integer comparison. M2/W5 hold by integer-only state and fixed scan order. M19 is closed by G4. M11/M13/M14/M16/M17/M18/M20 are not in this module's surface (no proof terms, reflection, library entries, branch ratification, memo cache, or self-reasoning) — noted for completeness.

## Implementation Skeleton
```iii
/* C:\Users\Edwin Boston\OneDrive\Desktop\III\STDLIB\iii\numera\microarch_model.iii
 *
 * III STDLIB - numera::microarch_model
 *
 * Deterministic, purely analytic microarchitecture cost model. Simulates a
 * candidate instruction sequence through an in-order issue, out-of-order
 * complete, in-order retire pipeline with explicit hazard, port, ROB and
 * retire-width modelling. No measurement, no sampling, no learning -- every
 * parameter is set explicitly and the simulation is a closed integer
 * recurrence, bit-identical across runs and CPUs. Consumed by cg_superopt
 * (via numera/cost_calculus.iii) to assign exact costs to candidates.
 *
 * Pipeline: front-end issues up to ISSUE_WIDTH ops/cycle in program order
 * into a ROB of ROB_CAP slots; each op executes on the lowest-index free
 * port whose PORT_MASK covers its opcode once all its dep producers have
 * finished, taking LATENCY[opcode] cycles; the retire unit commits in
 * program order up to RETIRE_WIDTH/cycle. The loop is bounded by
 * UARCH_MAX_CYCLES (no-bricking: a cyclic dep graph refuses, never hangs).
 *
 * Public API:
 *   ma_init() -> i32
 *   ma_set_params(p: *u32) -> i32                       -- [iw, rw, rob, ports]
 *   ma_set_latency(opcode: u32, cycles: u32) -> i32
 *   ma_set_port_mask(opcode: u32, mask: u32) -> i32
 *   ma_simulate(ops, n, deps, dep_n, out_cycles) -> i32 -- frozen ABI shim
 *   ma_simulate_req(req: *u64) -> i32                   -- canonical (W2)
 *   ma_trace_hash(out32: *u8) -> i32                    -- M10/M12 certificate
 *   ma_last_cycles() -> u64
 *   ma_selftest() -> u64                                -- 99 = pass
 *
 * Hexad: kind_essence.  Ring: R0.  K: 0.99.
 * Discipline: <=4 fn params (aggregate via *u64 req); u64 ordering compares
 * only (signed-i32/i64 use == / != ); no local var arrays; no modulo;
 * no recursion; address-of-static taken only in this file.
 */

module numera_microarch_model

extern @abi(c-msvc-x64) fn mhash_begin() -> i32 from "mhash.iii"
extern @abi(c-msvc-x64) fn mhash_domain(d: u64, dl: u64) -> i32 from "mhash.iii"
extern @abi(c-msvc-x64) fn mhash_payload(p: u64, pl: u64) -> i32 from "mhash.iii"
extern @abi(c-msvc-x64) fn mhash_final(out: u64) -> i32 from "mhash.iii"

const UARCH_OK          : i32 =  0i32
const UARCH_E_BAD       : i32 = -1i32
const UARCH_E_TOO_BIG   : i32 = -2i32
const UARCH_E_NOPROG    : i32 = -3i32

const UARCH_MAX_OPS     : u32 = 1024u32
const UARCH_MAX_DEPS    : u32 = 4096u32
const UARCH_MAX_OPCODE  : u32 = 4096u32
const UARCH_MAX_PORTS   : u32 = 16u32
const UARCH_MAX_CYCLES  : u64 = 1048576u64
const UARCH_HASH_DOMAIN : u64 = 0x55415243485F4D31u64

var UARCH_ISSUE_WIDTH  : u32 = 4u32
var UARCH_RETIRE_WIDTH : u32 = 4u32
var UARCH_ROB_CAP      : u32 = 224u32
var UARCH_EXEC_PORTS   : u32 = 10u32

var UARCH_LATENCY      : [u32; 4096]
var UARCH_PORT_MASK    : [u32; 4096]

var UARCH_ISSUED       : [u8;  1024]
var UARCH_STARTED      : [u8;  1024]
var UARCH_READY_CYCLE  : [u64; 1024]
var UARCH_START_CYCLE  : [u64; 1024]
var UARCH_END_CYCLE    : [u64; 1024]
var UARCH_RETIRED      : [u8;  1024]

var UARCH_PORT_BUSY    : [u64; 16]
var UARCH_REQ          : [u64; 5]

var UARCH_LAST_CYCLES  : u64 = 0u64
var UARCH_HAS_RESULT   : u8  = 0u8
var UARCH_LAST_N       : u32 = 0u32

fn ma_init() -> i32 @export {
    // TODO: body per Algorithm "ma_init" -- set LATENCY[i]=1, PORT_MASK[i]=0xFFFFFFFF
    //       for i in 0..UARCH_MAX_OPCODE; reset HAS_RESULT/LAST_CYCLES/LAST_N.
    return UARCH_OK
}

fn ma_set_params(p: *u32) -> i32 @export {
    // TODO: body per Algorithm "ma_set_params" -- read p[0..3]; reject any 0 or
    //       exec_ports > UARCH_MAX_PORTS with UARCH_E_BAD; else assign the four vars.
    return UARCH_OK
}

fn ma_set_latency(opcode: u32, cycles: u32) -> i32 @export {
    // TODO: body per Algorithm -- range-check opcode < UARCH_MAX_OPCODE; reject
    //       cycles == 0u32 (UARCH_E_BAD); store; return UARCH_OK.
    return UARCH_OK
}

fn ma_set_port_mask(opcode: u32, mask: u32) -> i32 @export {
    // TODO: body per Algorithm -- range-check opcode < UARCH_MAX_OPCODE; store.
    return UARCH_OK
}

fn ma_simulate(ops: *u32, n: u32, deps: *u32, dep_n: u32, out_cycles: *u64) -> i32 @export {
    // TODO: ABI shim -- marshal the 5 args into UARCH_REQ[0..4] (pointers as u64,
    //       n/dep_n as u64) and return ma_simulate_req(&UARCH_REQ[0u32] as *u64).
    return UARCH_OK
}

fn ma_simulate_req(req: *u64) -> i32 @export {
    // TODO: body per Algorithm "ma_simulate_req":
    //   1. unmarshal (mask n/dep_n low 32 bits); bound-check -> UARCH_E_TOO_BIG.
    //   2. dep range-check (consumer<n && producer<n) -> UARCH_E_BAD (early return).
    //   3. reset per-op arrays for 0..n; reset UARCH_PORT_BUSY for 0..EXEC_PORTS.
    //   4. event loop while done==0u8 with UARCH_MAX_CYCLES watchdog:
    //        issue stage (in-order, ISSUE_WIDTH, ROB_CAP),
    //        dispatch stage (recompute dynamic ready; lowest free covering port),
    //        retire stage (in-order, RETIRE_WIDTH),
    //        advance/terminate (retired_count==n -> done; cycle>=MAX -> done,noprog).
    //   5. noprog -> UARCH_E_NOPROG; else *out_cycles=cycle; record LAST_*; UARCH_OK.
    return UARCH_OK
}

fn ma_trace_hash(out32: *u8) -> i32 @export {
    // TODO: body per Algorithm "ma_trace_hash":
    //   HAS_RESULT==0u8 -> UARCH_E_NOPROG (early return).
    //   mhash_begin; mhash_domain(UARCH_HASH_DOMAIN,8); fold params then per-op
    //   (READY,START,END,RETIRED) quads as LE bytes via mhash_payload;
    //   mhash_final(out32 as u64); return UARCH_OK.
    return UARCH_OK
}

fn ma_last_cycles() -> u64 @export {
    // TODO: return UARCH_LAST_CYCLES.
    return 0u64
}

fn ma_selftest() -> u64 @export {
    // TODO: run KAT 1..8 (see KAT Vectors); return 99u64 on all pass,
    //       else the first failing case number (1..8).
    return 99u64
}
```
