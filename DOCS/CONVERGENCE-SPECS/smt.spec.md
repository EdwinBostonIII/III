# 16 numera/smt.iii — Implementation Spec

## Verdict
STUB — the gospel candidate is a partial scaffold dressed as a solver. The BV bit-blasting (`smt_bv_add_eq`, `smt_bv_add_ult`) is largely correct and matches the Module-15 SAT literal encoding, but the headline **Nelson-Oppen combination is entirely absent** (the prose promises shared-variable equality propagation to a fixed point; `smt_solve` solves the two theories independently with zero exchange). The LIA decision procedure is an admitted brute-force box scan (`513^n` worst case) that **blows the cost lattice (M19)** and is non-total in practice. There is a **fatal SAT-lifecycle ordering bug** (clauses are added before `sat_init`, then `smt_solve` calls `sat_init` which wipes them). The body contains **multiple Trap-3 `i64` ordering compares (SIGSEGV)**, **multiple Trap-7 local `var` arrays (parse failure)**, a **W2 5-parameter function**, a Trap-4 unmasked `u32`-in-`u64` shift, and **no witness/certificate (M6/M10/M12/M18)**. Maximal realization replaces brute-force LIA with an exact rational **Bland's-rule simplex + branch-and-bound**, fixes the SAT lifecycle by having SMT own a clause buffer it replays after sizing, implements true Nelson-Oppen equality propagation, and emits a recomputable witness plus an independent model checker.

## Purpose
`numera/smt.iii` IS the substrate's decision procedure for satisfiability modulo theories: a DPLL(T)-style combination over two convex theories — **LIA** (linear integer arithmetic, `sum_i c_i x_i <op> b`, `op in {<=, ==}` with `>=` encoded as negation) and **BV** (fixed-width unsigned bit vectors, bit-blasted to Module-15 CDCL SAT) — joined by **Nelson-Oppen** equality propagation over shared integer variables, run to a deterministic fixed point. It is the engine that discharges the constitutional admissibility predicates and capability bound checks of the substrate. Hexad kind: `kind_essence`. Ring: **R0**. K-vector: **0.99**.

## Public API
All public functions return a status `i32` (W9/W12: negative = error; `SMT_OK/SMT_SAT/SMT_UNSAT` otherwise) or a sentinel-typed handle/value. Every signature is single-line (Trap 1).

```
fn smt_init() -> i32 @export
fn smt_lia_new_var() -> u32 @export
fn smt_lia_add_le(coeffs: *i64, vars: *u32, n: u32, b: i64) -> i32 @export
fn smt_lia_add_ge(coeffs: *i64, vars: *u32, n: u32, b: i64) -> i32 @export
fn smt_lia_add_eq(coeffs: *i64, vars: *u32, n: u32, b: i64) -> i32 @export
fn smt_bv_new_var(width: u32) -> u32 @export
fn smt_bv_add_eq(a: u32, b: u32) -> i32 @export
fn smt_bv_add_ult(a: u32, b: u32) -> i32 @export
fn smt_share(lia_var: u32, bv_var: u32) -> i32 @export
fn smt_solve() -> i32 @export
fn smt_solve_cap(cap: *u8) -> i32 @export
fn smt_lia_value(var: u32) -> i64 @export
fn smt_bv_value(var: u32) -> u64 @export
fn smt_check_model() -> u8 @export
fn smt_witness(out_32: *u8) -> i32 @export
fn smt_selftest() -> u64 @export
```

Return-status convention per fn:
- `smt_init` → `SMT_OK` always (resets state; total).
- `smt_lia_new_var` / `smt_bv_new_var` → fresh 1-based handle `u32`, or `0u32` sentinel on exhaustion / bad width (W12 sentinel-typed; **not** a negative i32 because the type is an unsigned handle).
- `smt_lia_add_le/ge/eq`, `smt_bv_add_eq/ult`, `smt_share` → `SMT_OK` or negative (`SMT_E_TOO_BIG`, `SMT_E_BAD`).
- `smt_solve` / `smt_solve_cap` → `SMT_SAT` (1), `SMT_UNSAT` (2), or negative error. `smt_solve()` = `smt_solve_cap(SMT_NULL_CAP)` (witness suppressed). `smt_solve_cap` requires a capability for witness emission (M8).
- `smt_lia_value` → `i64` model value; `0i64` sentinel for bad/unsolved handle.
- `smt_bv_value` → `u64` model value; `0u64` sentinel for bad/unsolved handle.
- `smt_check_model` → `u8` (W10): `1u8` iff the recorded model satisfies every recorded constraint; else `0u8`.
- `smt_witness` → `SMT_OK` after writing the 32-byte solve witness to `out_32`; `SMT_E_BAD` if no solve has run.
- `smt_selftest` → `u64`: `0u64` iff all KAT vectors pass; else a bitmask of the failing vector indices.

## Constant Namespace
PREFIX = `SMT_`. Grep result: `grep -rn "SMT_" STDLIB/` → **0 matches**. No collision. (Also verified `numera_sat_arith` exports `sat_add_u64`/etc., NOT the `sat_init/sat_add_clause/sat_solve/sat_value` of Module-15, so the `sat_*` externs below are collision-free; and module name `numera_smt` is unused in the tree.)

Module-level constants (every one prefixed):

```
const SMT_OK            : i32 =  0i32
const SMT_SAT           : i32 =  1i32
const SMT_UNSAT         : i32 =  2i32
const SMT_UNKNOWN       : i32 =  3i32      // reserved; never returned by a total path (M2)
const SMT_E_TOO_BIG     : i32 = -1i32
const SMT_E_BAD         : i32 = -2i32
const SMT_E_NOCAP       : i32 = -3i32
const SMT_E_NOMODEL     : i32 = -4i32

const SMT_MAX_LIA_VARS  : u32 = 256u32
const SMT_MAX_LIA_CON    : u32 = 1024u32
const SMT_LIA_PACKED     : u32 = 16384u32
const SMT_MAX_BV_VARS    : u32 = 256u32
const SMT_BV_WIDTH_MAX    : u32 = 64u32
const SMT_BV_TOTAL_BITS   : u32 = 16384u32

// Simplex tableau bounds (rows = constraints+slacks, cols = vars+slacks+rhs).
const SMT_SX_MAX_ROWS    : u32 = 1280u32   // SMT_MAX_LIA_CON + headroom for B&B cuts
const SMT_SX_MAX_COLS    : u32 = 1600u32   // vars + one slack per row + rhs col
const SMT_SX_CELLS       : u32 = 2048000u32 // SX_MAX_ROWS * SX_MAX_COLS (rational pairs)

// Branch-and-bound explicit stack (W15, no recursion).
const SMT_BB_MAX_DEPTH   : u32 = 4096u32   // <= MAX_LIA_VARS * ceil(log2(2*BOX+1)); justified below

// Integrality box for B&B fallback bounds and witness canonicalization.
const SMT_LIA_BOX        : i64 = 1048576i64 // 2^20; box only bounds free vars, B&B not brute scan

// SMT-owned clause replay buffer bounds (BV bit-blast clauses buffered pre-sizing).
const SMT_CLBUF_MAX_LITS : u32 = 1048576u32
const SMT_CLBUF_MAX_CLS  : u32 = 262144u32

// SAT result/status mirror (Module-15 values; must match sat.iii exactly).
const SMT_SAT_OK         : i32 =  0i32
const SMT_SAT_SAT        : i32 =  1i32
const SMT_SAT_UNSAT      : i32 =  2i32

const SMT_NULL_CAP       : u64 = 0u64      // witness-suppressing sentinel capability
const SMT_NO_SHARE       : u32 = 0xFFFFFFFFu32

// Rational sign tags (avoid i64 ordering compares — Trap 3).
const SMT_NEG            : u8 = 0u8
const SMT_ZERO           : u8 = 1u8
const SMT_POS            : u8 = 2u8
```

`SMT_BB_MAX_DEPTH` justification: branch-and-bound branches one integer variable per node; with `<= 256` LIA vars each bounded to `[-2^20, 2^20]` the search tree depth is bounded by the number of variables that can still be split, but the **explicit DFS stack** stores at most one open right-branch per level, so `4096 = 16 * MAX_LIA_VARS` open frames is a safe over-bound; the node counter `SMT_BB_NODES` is hard-capped (see Algorithm) so termination is guaranteed regardless (M19).

## Data Structures
Every buffer is a fixed module-scope array (W8). No local `var` arrays anywhere (Trap 7) — all scratch is hoisted here with `SMT_`-prefixed names.

LIA constraint store (kept from gospel, corrected):
```
var SMT_LIA_NVAR    : u32 = 0u32
var SMT_LIA_NCON    : u32 = 0u32
var SMT_LIA_KIND    : [u8;  1024]   // 0 = sum<=b, 1 = sum==b  (>= encoded as negation at insert)
var SMT_LIA_OFF     : [u32; 1024]
var SMT_LIA_LEN     : [u32; 1024]
var SMT_LIA_BND     : [i64; 1024]
var SMT_LIA_COEFF   : [i64; 16384]
var SMT_LIA_VAR     : [u32; 16384]
var SMT_LIA_USED    : u32 = 0u32
var SMT_LIA_VAL     : [i64; 256]    // model values, 1-based var v stored at v-1
var SMT_LIA_SOLVED  : u8 = 0u8      // 1 iff LIA model is valid
```

BV store (kept, corrected — SMT owns SAT var numbering; bits are SAT vars 1..):
```
var SMT_BV_NVAR     : u32 = 0u32
var SMT_BV_WIDTH    : [u32; 256]
var SMT_BV_BIT0     : [u32; 256]    // first SAT var id of this BV (1-based into SAT)
var SMT_BV_SAT_NEXT : u32 = 0u32    // next free SAT var id; smt_init sets to 1
var SMT_BV_BIT_VAR  : [u32; 16384]  // bit-slot -> SAT var (identity map; kept for clarity)
var SMT_BV_SOLVED   : u8 = 0u8
```

SMT-owned clause replay buffer (NEW — fixes the SAT-lifecycle ordering bug). BV constraint adders append fully-encoded clauses HERE; `smt_solve` sizes SAT then replays:
```
var SMT_CLBUF_OFF   : [u32; 262144]   // SMT_CLBUF_MAX_CLS
var SMT_CLBUF_LEN   : [u32; 262144]
var SMT_CLBUF_NCL   : u32 = 0u32
var SMT_CLBUF_LIT   : [u32; 1048576]  // SMT_CLBUF_MAX_LITS, packed literals
var SMT_CLBUF_USED  : u32 = 0u32
```

Nelson-Oppen sharing map (NEW — the missing headline feature):
```
var SMT_SHARE_LIA   : [u32; 256]      // share entry i: LIA var (1-based) or SMT_NO_SHARE
var SMT_SHARE_BV    : [u32; 256]      // share entry i: BV var (1-based) or SMT_NO_SHARE
var SMT_SHARE_N     : u32 = 0u32
var SMT_NO_NEW_EQ   : u8 = 0u8        // fixed-point flag for the propagation loop (W14)
```

Exact rational simplex tableau (NEW — replaces brute force). Each cell is a reduced fraction num/den, den>0:
```
var SMT_SX_NUM      : [i64; 2048000]  // SMT_SX_CELLS
var SMT_SX_DEN      : [i64; 2048000]
var SMT_SX_NROWS    : u32 = 0u32
var SMT_SX_NCOLS    : u32 = 0u32
var SMT_SX_BASIS    : [u32; 1280]     // basic var index per row (SMT_SX_MAX_ROWS)
var SMT_SX_RHSNUM   : [i64; 1280]     // current rational assignment per structural var
var SMT_SX_RHSDEN   : [i64; 1280]
```

Branch-and-bound explicit DFS stack (NEW — W15 no recursion):
```
var SMT_BB_VAR      : [u32; 4096]     // SMT_BB_MAX_DEPTH; var to branch at this frame
var SMT_BB_LO       : [i64; 4096]     // pushed lower-bound cut
var SMT_BB_HI       : [i64; 4096]     // pushed upper-bound cut
var SMT_BB_SP       : u32 = 0u32      // stack pointer
var SMT_BB_NODES    : u64 = 0u64      // hard node cap counter (M19)
const SMT_BB_NODE_CAP : u64 = 16777216u64  // 2^24 node ceiling; refuse (SMT_E_TOO_BIG) past it (M5/M19)
```

Witness state (NEW — M6/M10):
```
var SMT_WIT_HASH    : [u8; 32]        // last solve witness (sha256 over canonical transcript)
var SMT_WIT_VALID   : u8 = 0u8
var SMT_WIT_SCRATCH : [u8; 65536]     // canonical-serialization scratch (module scope; Trap 7)
```

Per-fn scratch hoisted from gospel locals (Trap 7 — these were illegal local `var` arrays):
```
var SMT_SCRATCH_CL  : [u32; 4]        // up to a 4-literal clause being assembled
var SMT_SX_PIVCOL_N : [i64; 1280]     // pivot-column working numerators
var SMT_SX_PIVCOL_D : [i64; 1280]
var SMT_BB_VALS     : [i64; 256]      // candidate integer assignment under test
```

## Dependencies (externs)
All `@abi(c-msvc-x64)`. Signatures verified against the Module-15 gospel body.

```
extern @abi(c-msvc-x64) fn sat_init(n_vars: u32) -> i32 from "sat.iii"
extern @abi(c-msvc-x64) fn sat_add_clause(lits: *u32, n_lits: u32) -> i32 from "sat.iii"
extern @abi(c-msvc-x64) fn sat_solve() -> i32 from "sat.iii"
extern @abi(c-msvc-x64) fn sat_value(var: u32) -> u8 from "sat.iii"
extern @abi(c-msvc-x64) fn sha256_oneshot(input: *u8, len: u64, out_32: *u8) -> u32 from "sha256.iii"
```

| Extern | Provider | NN | Built? |
|---|---|---|---|
| `sat_init`, `sat_add_clause`, `sat_solve`, `sat_value` | `numera/sat.iii` | **15** | **NOT YET BUILT** (designed in parallel; wave-order Module 15 before 16) |
| `sha256_oneshot` | `numera/sha256.iii` | (built) | yes — present in tree |

Notes that pin the SAT contract (Phase 2 must hold these or the BV theory silently corrupts):
- Literal encoding is `lit = (v<<1) | sign`, `sign=0` positive, `sign=1` negative. The BV clause encoders below use exactly this. **Bit-identical to sat.iii lines 4242-4245.**
- SAT variables are `1..n_vars`. SMT allocates BV bits as SAT vars starting at `1u32` (`SMT_BV_SAT_NEXT = 1` in `smt_init`).
- `sat_value(v)` returns `1u8` (true) / `0u8` (false) / `0xFFu8` (unknown). `smt_bv_value` treats `1u8` as bit-set; any other value as clear.
- `sat_add_clause` returns `SAT_E_NOT_INIT` if called before `sat_init`. **This is the root of the gospel's lifecycle bug** — hence SMT buffers clauses and replays *after* `sat_init` (see Algorithm `smt_solve`).
- `sat_solve()` returns `SAT_SAT=1` / `SAT_UNSAT=2`. `SMT_SAT/SMT_UNSAT` share these numeric values by construction (mirror constants `SMT_SAT_SAT`/`SMT_SAT_UNSAT` assert the agreement).

## Algorithm

### Determinism & bit-identity foundation (M2/W5)
No floating point anywhere. LIA arithmetic is exact `i64` rationals (num/den, den>0, gcd-reduced). All loops are bounded and traverse fixed index ranges in ascending order, so the operation sequence is a pure function of the recorded constraints (M2). Simplex uses **Bland's rule** (smallest-index entering/leaving variable) which is the canonical anti-cycling pivot rule and is fully order-deterministic — no heuristic, no activity scores (M3/M4). Branch-and-bound branches the **smallest-index** fractional variable and explores the floor branch before the ceil branch (fixed order), via an explicit stack (W15). The BV theory delegates to the deterministic Module-15 CDCL solver, whose decision rule is itself deterministic.

### `smt_init`
Zero all counters: `SMT_LIA_NVAR/NCON/USED = 0`, `SMT_BV_NVAR = 0`, `SMT_BV_SAT_NEXT = 1u32`, `SMT_CLBUF_NCL/USED = 0`, `SMT_SHARE_N = 0`, `SMT_LIA_SOLVED = SMT_BV_SOLVED = SMT_WIT_VALID = 0u8`, `SMT_BB_NODES = 0u64`. **Does NOT call `sat_init`** (var count is unknown until `smt_solve`). Returns `SMT_OK`. Reversible: re-`smt_init` fully restores the empty state (M5/M9).

### `smt_lia_new_var`
Bound check `SMT_LIA_NVAR < SMT_MAX_LIA_VARS` (unsigned `<`, safe — Trap 3 is about **signed** ordering). Set `SMT_LIA_VAL[v] = 0i64`, increment, return `v+1` (1-based). Sentinel `0u32` on exhaustion.

### `smt_lia_add_le` / `smt_lia_add_ge` / `smt_lia_add_eq`
These are the W2-compliant public entries (4 params each). The gospel's `smt_lia_add_internal(kind, coeffs, vars, n, b)` had **5 params (W2 violation)** — eliminate it. Instead pass the kind via a module-scope one-shot field `SMT_ADD_KIND` set immediately before a shared 4-param helper `smt_lia_store(coeffs, vars, n, b)`, OR (preferred, cleaner) inline the store in each of the three public fns (no shared 5-param helper). `add_ge` encodes `sum >= b` as `(-sum) <= (-b)`: negate every coefficient and the bound at insertion (so the store sees a `<=` row). Bound checks: `SMT_LIA_NCON < SMT_MAX_LIA_CON` and `SMT_LIA_USED + n <= SMT_LIA_PACKED` (unsigned). Append packed coeffs/vars; record `KIND/OFF/LEN/BND`. Return `SMT_OK` / `SMT_E_TOO_BIG`.

### `smt_bv_new_var`
Identical to gospel (correct): width in `1..64`, capacity check `SMT_BV_SAT_NEXT + width <= SMT_BV_TOTAL_BITS`, assign `BIT0 = SMT_BV_SAT_NEXT`, map `BIT_VAR`, advance `SMT_BV_SAT_NEXT`, return 1-based handle.

### `smt_bv_add_eq` (bit-blast a==b)
For each bit `i in 0..w`: emit two clauses `(¬a_i ∨ b_i)` and `(a_i ∨ ¬b_i)` where `a_i = BIT0[av]+i`, `b_i = BIT0[bv]+i`. **Encoding fix vs gospel:** instead of writing into a local `var cl : [u32;2]` (Trap 7), assemble into module-scope `SMT_SCRATCH_CL` and call a buffering helper `smt_clbuf_add(n)` that copies `SMT_SCRATCH_CL[0..n]` into `SMT_CLBUF_LIT` and records `SMT_CLBUF_OFF/LEN` (it does **not** call `sat_add_clause` yet). Literal form (identical to gospel, matches SAT): positive `= (x<<1)`, negative `= (x<<1)|1`.

### `smt_bv_add_ult` (bit-blast a<b unsigned, Tseitin chain)
Same prefix-`gt` Tseitin construction as gospel (it is logically correct), with three corrections: (1) fresh helper vars are drawn from `SMT_BV_SAT_NEXT` with the capacity guard; (2) all `var c1..c6/unit` local arrays are replaced by `SMT_SCRATCH_CL` + `smt_clbuf_add` (Trap 7); (3) the final unit clause forcing `prev_gt` true is buffered, not sent to SAT directly. The bit-0 base case is `g_0 = (¬a_0 ∧ b_0)` (3 clauses); each `i>0` step Tseitin-encodes `g_i = (¬a_i ∧ b_i) ∨ ((a_i ↔ b_i) ∧ g_{i-1})` (6 clauses) exactly as the gospel lists them. Width mismatch → `SMT_E_BAD`.

### `smt_share`
Register a shared variable pair `(lia_var, bv_var)` for Nelson-Oppen exchange. Validate both handles in range; append to `SMT_SHARE_LIA/BV`; return `SMT_OK`. Bound: `SMT_SHARE_N < SMT_MAX_LIA_VARS`.

### LIA exact rational simplex + branch-and-bound (replaces `smt_lia_solve_brute`)
This is the maximal LIA decision procedure (the gospel itself names `smt_lia_solve_simplex` as the production path; we implement it now rather than defer). Hand-rolled (M1).

**Rational primitives** (NIH, no modulo-after-call — Trap 11): `smt_gcd(a,b)` via the **subtractive** Euclidean algorithm (repeated subtraction loop driven by an inequality on **unsigned** magnitudes after sign extraction, so no signed-`%` and no signed ordering on the originals); `smt_rat_reduce(idx)` divides num/den by gcd and forces den>0; `smt_rat_add`, `smt_rat_sub`, `smt_rat_mul` over (num,den) with reduce; `smt_rat_sign(num)` returns `SMT_NEG/SMT_ZERO/SMT_POS` by testing `num == 0i64` and the sign bit (`(num >> 63) & 1`) — **never** `num < 0i64` (Trap 3); `smt_rat_cmp(an,ad,bn,bd)` compares `a-b` by computing `s = smt_rat_sub(...)` then `smt_rat_sign` — all comparisons route through equality-tested sign tags, eliminating every Trap-3 `i64 <`/`>`/`<=`/`>=`.

**Phase-I/Phase-II simplex:** build the tableau with one slack per `<=` row; equalities become two rows (`<=` and `>=`-as-negation) OR a single equality row handled by Phase-I artificial variables. Run Phase-I (minimize sum of artificials) to find a feasible basis, then this is a **feasibility** query (SMT asks SAT/UNSAT, not optimization) so Phase-II is the feasibility test: if Phase-I optimum (sum of artificials) reduces to rational zero, the LIA relaxation is feasible; otherwise the LIA system is UNSAT over the rationals → **return `SMT_UNSAT`**. Pivot selection is Bland's rule (smallest index), guaranteeing termination with no cycling (M2/M19). The pivot inner loop is a fixed ascending scan over `SMT_SX_NCOLS`/`SMT_SX_NROWS`; the "ratio test" picks the leaving row by `smt_rat_cmp` of (rhs/pivot) ratios with smallest-index tie-break.

**Branch-and-bound for integrality:** after a feasible rational vertex is found, scan structural vars (ascending). For the smallest-index var whose value is non-integral, push a B&B frame: explore `x <= floor(val)` (add a temporary `<=` cut row, re-run simplex) before `x >= ceil(val)`; manage the open alternative on `SMT_BB_VAR/LO/HI` stack (W15, explicit DFS). A node where all structural vars are integral and feasible → copy the integer assignment into `SMT_LIA_VAL`, set `SMT_LIA_SOLVED=1`, return `SMT_SAT`. Each visited node increments `SMT_BB_NODES`; if it reaches `SMT_BB_NODE_CAP` the procedure **refuses** with `SMT_E_TOO_BIG` rather than diverging (M5/M19 — refusal, not bricking). Floor/ceil are computed by truncating the rational toward `-inf` using `smt_rat_sign` to branch the rounding (no `i64` ordering). Stack underflow with no integral node found → `SMT_UNSAT`.

Integrality of an integer-coefficient LIA system is decidable and B&B with rational simplex + Bland's rule is a sound and complete decision procedure for it within the node cap; the cap is the explicit cost-lattice bound (M19). This is total and deterministic (M2/M15).

### `smt_solve_cap` (the DPLL(T) + Nelson-Oppen driver) and `smt_solve`
`smt_solve()` ≡ `smt_solve_cap(SMT_NULL_CAP)`. Steps:

1. **Nelson-Oppen fixed-point loop** (W14 sentinel `SMT_NO_NEW_EQ`, no `break`):
   - Solve LIA via the simplex+B&B above. If `SMT_UNSAT` → goto step 4 with result UNSAT.
   - Size and solve BV: set `SMT_BV_SOLVED=0`; if `SMT_BV_NVAR > 0`: call `sat_init(SMT_BV_SAT_NEXT - 1u32)` **(now, after all clauses are buffered)**, then **replay** every buffered clause: for `c in 0..SMT_CLBUF_NCL`, `sat_add_clause(&SMT_CLBUF_LIT[SMT_CLBUF_OFF[c]], SMT_CLBUF_LEN[c])`; then `sat_solve()`. If `!= SMT_SAT_SAT` → result UNSAT, goto step 4.
   - **Equality exchange:** for each shared pair `(li, bi)`, read `smt_lia_value(li)` and the current BV value of `bi` from `sat_value`. Derive any new equalities implied by one theory's model not yet asserted in the other: if both models force two shared vars equal/disequal and the other theory has not been told, **inject** the equality as a fresh LIA `==` constraint (and/or a BV `==` clause buffered + replayed on the next iteration), set `SMT_NO_NEW_EQ=0u8`. Convex-theory completeness (Nelson-Oppen) guarantees that exchanging only **equalities between shared variables** suffices. No new equality this pass → `SMT_NO_NEW_EQ=1u8` and the loop ends.
   - The loop is bounded: each pass can only add equalities among the finite shared-var set (at most `O(SMT_SHARE_N^2)` distinct equalities), and equalities are monotonically accumulated, so the fixed point is reached in `<= SMT_SHARE_N^2 + 1` passes (M19 bound). A pass counter hard-caps this.
2. If neither theory reported UNSAT at fixed point → result `SMT_SAT`.
3. Set `SMT_LIA_SOLVED`/`SMT_BV_SOLVED` per the satisfied theories.
4. **Witness (M6/M10):** if `cap != SMT_NULL_CAP` (capability present — M8), canonically serialize the transcript into `SMT_WIT_SCRATCH` — a fixed byte layout: result tag, then for each LIA constraint `(kind, len, bnd, [coeff,var]*)`, then BV var widths, then the full model (`SMT_LIA_VAL[0..NVAR]`, then each BV value) — and `sha256_oneshot(SMT_WIT_SCRATCH, used, SMT_WIT_HASH)`; set `SMT_WIT_VALID=1`. The witness is **recomputable byte-identically** from the recorded constraints+model (M10) because the serialization is a pure function of module state in fixed order. Without a capability the witness is suppressed (`SMT_WIT_VALID=0`), and the solve is otherwise unchanged (reversibility default, M9).
5. Return the result code.

### `smt_lia_value` / `smt_bv_value`
`smt_lia_value`: range-check 1-based `var`, return `SMT_LIA_VAL[var-1]`, else `0i64`. `smt_bv_value`: range-check, then `acc = OR over i in 0..w of (sat_value(BIT0[v]+i) == 1u8 ? 1<<i : 0)`. **Trap-4 fix:** the shift amount must be masked — compute `sh = (i as u64) & 0xFFFFFFFFu64` then `acc | (1u64 << sh)`. Sentinel `0u64` for bad/unsolved handle.

### `smt_check_model` (M12 verifiability — independent re-check)
Recompute, **without** the solver, that the recorded model satisfies every recorded constraint. For each LIA constraint: `sum = Σ coeff_i * SMT_LIA_VAL[var_i-1]`; `kind 0` requires `sum <= bnd`, `kind 1` requires `sum == bnd`. The `<=` test must avoid Trap 3 — compute `d = bnd - sum` and require `smt_rat_sign(d) != SMT_NEG` (i.e. tag `== SMT_ZERO` or `== SMT_POS`), the `==` test requires `sum - bnd == 0i64` (equality compare is safe). For each BV `==`/`ult` constraint: read the two BV values via `smt_bv_value` and check the relation using **unsigned** `==` / `<` (BV values are `u64`; unsigned ordering is NOT a Trap-3 case). Return `1u8` iff all pass. This is the checkable certificate side of M12/M18 — a SAT result is only accepted if `smt_check_model()==1u8`.

### `smt_witness`
If `SMT_WIT_VALID==0u8` → `SMT_E_BAD`. Else copy `SMT_WIT_HASH[0..32]` to `out_32` byte-by-byte and return `SMT_OK`.

### `smt_selftest`
Run the KAT vectors below in-process; return a bitmask of failures (`0u64` = all pass).

### No recursion (W15)
Simplex pivoting, B&B search, and Nelson-Oppen propagation are all **iterative with explicit module-scope stacks/worklists** (`SMT_BB_*`, the share array, the clause buffer). No function calls itself.

## KAT Vectors (>= 3)
Concrete `smt_init` → adds → `smt_solve` → value/`smt_check_model` triples, checked byte-for-byte by `smt_selftest`.

1. **LIA SAT (integral feasible).** `x = lia_new_var()` (=1), `y = lia_new_var()` (=2). Add `1*x + 1*y <= 3` (`add_le`, coeffs `[1,1]`, vars `[1,2]`, b=3) and `1*x - 1*y == 1` (`add_eq`, coeffs `[1,-1]`, vars `[1,2]`, b=1). Expected: `smt_solve()==SMT_SAT`; the smallest-index B&B model is `x=1, y=0` (x−y=1, x+y=1≤3). Check `smt_lia_value(1)==1i64`, `smt_lia_value(2)==0i64`, `smt_check_model()==1u8`. Bit-identical across runs (Bland's rule + fixed branch order make the returned vertex deterministic).

2. **LIA UNSAT (rational-infeasible).** `x=lia_new_var()`. Add `1*x <= 2` and `1*x >= 5` (`add_ge`, coeffs `[1]`, vars `[1]`, b=5 → stored as `-x <= -5`). Expected: Phase-I detects infeasibility → `smt_solve()==SMT_UNSAT`. (No model; `smt_lia_value` returns sentinel `0`.)

3. **BV equality SAT.** `a=bv_new_var(4)` (=1), `b=bv_new_var(4)` (=2). `smt_bv_add_eq(a,b)`. Add `smt_bv_add_ult(a, b)` would be UNSAT with eq; so instead, second BV var `c=bv_new_var(4)` and `smt_bv_add_ult(a,c)`. Expected `smt_solve()==SMT_SAT` with `smt_bv_value(1) == smt_bv_value(2)` (eq enforced) and `smt_bv_value(1) < smt_bv_value(3)` unsigned (ult enforced). Concrete deterministic SAT model from Module-15's always-positive-first decision rule: all-true assignment is pruned by `ult`; the solver returns the lexicographically-first satisfying assignment — `smt_check_model()==1u8` is the byte-checked gate (the exact bit pattern is pinned once Module-15 lands; `smt_check_model` makes the KAT robust to any valid model).

4. **BV ult UNSAT.** `a=bv_new_var(2)`, `b=bv_new_var(2)`, `smt_bv_add_eq(a,b)` and `smt_bv_add_ult(a,b)`. `a==b ∧ a<b` is unsatisfiable → `smt_solve()==SMT_UNSAT`. (Proves the Tseitin ult chain actually constrains, not a no-op — the "prove the negative case" discipline.)

5. **Nelson-Oppen exchange.** `x=lia_new_var()`, `a=bv_new_var(8)`, `smt_share(x, a)`. Add LIA `1*x == 5` and BV `smt_bv_add_ult(a, b)` where `b=bv_new_var(8)` is pinned `==` a constant-5 var via eq-to-a-fresh-var trick. The shared equality forces `a`'s value to agree with `x=5`; expected `smt_solve()==SMT_SAT`, `smt_lia_value(1)==5i64`, `smt_bv_value(1)==5u64`, `smt_check_model()==1u8`. Conversely if LIA forces `x==5` but BV forces `a==6` via an eq constraint, the exchanged equality makes the combined system `SMT_UNSAT` (negative case).

6. **Witness reproducibility (M10).** After KAT 1 with a non-null capability, capture `smt_witness(h1)`; re-run identical KAT 1, capture `smt_witness(h2)`; assert `h1 == h2` byte-for-byte (32 bytes). With `SMT_NULL_CAP`, `smt_witness` returns `SMT_E_BAD` (suppressed).

## Trap Exposure
1. **Multi-line `fn` (Trap 1):** all 17 signatures above are single-line. AVOIDANCE: Phase 2 must keep each `fn ... {` on one physical line; the longest (`smt_lia_add_le(coeffs: *i64, vars: *u32, n: u32, b: i64) -> i32 @export`) fits well within a line.
2. **Module-level `const` linker-global (Trap 2):** every const is `SMT_`-prefixed; grep of `STDLIB/` shows **0 prior `SMT_` symbols**. No collision. AVOIDANCE: keep the prefix on every new const added in Phase 2.
3. **Signed-ordering SIGSEGV (Trap 3):** the gospel body is **heavily exposed** — `smt_lia_check` (`sum > BND`), `smt_lia_solve_brute` (`vals[j] > BOX`, `vals[j] <= BOX`), and any rational comparison. AVOIDANCE: **eliminate every `i64 </<=/>/>=`.** All magnitude decisions route through `smt_rat_sign(num)` (tests `== 0i64` and `(num>>63)&1`) and `smt_rat_cmp` (subtract then sign-tag, compared by `==`). Equality (`==`/`!=`) on `i64` is the only signed compare used. Unsigned `u32`/`u64` ordering (bounds, BV ult) is **not** a Trap-3 case and is allowed.
4. **`u32`-in-`u64`-slot garbage (Trap 4):** `smt_bv_value`'s `1u64 << (i as u64)` and any `BIT0[v]+i` used in addressing. AVOIDANCE: mask the shift amount `(i as u64) & 0xFFFFFFFFu64` before the shift; SAT var indices passed to `sat_value` are `u32` (no `as u64` pointer math on the SMT side).
5. **`u32` pointer store width (Trap 5):** SMT writes into `*u32` SAT-clause arrays only as **whole-array element stores into module-scope `[u32; N]`** (e.g. `SMT_CLBUF_LIT[i] = lit`), where the index type and element type are both u32 and the destination is a real u32 array — this is the normal indexed-store path, not the `*u32`-pointer-from-u32-local path the trap describes. The only `*u32` we *pass* is `&SMT_CLBUF_LIT[off]` to `sat_add_clause` (read-only on our side). AVOIDANCE: never build a clause through a `*u32` pointer aliasing a single u32 local; always index the typed module array.
6. **Nested `/* */` (Trap 6):** the gospel comments are single-level; keep them so. AVOIDANCE: use `//` for inline notes inside the long Tseitin comment blocks.
7. **Local `var` arrays (Trap 7):** the gospel **violates this repeatedly** — `var vals:[i64;256]` in `smt_lia_solve_brute`, `var cl:[u32;2]`, `var c1..c6:[u32;3/4]`, `var unit:[u32;1]`. AVOIDANCE: **every** scratch array is hoisted to module scope with a `SMT_`-prefixed name (`SMT_SCRATCH_CL`, `SMT_BB_VALS`, `SMT_SX_PIVCOL_N/D`, `SMT_WIT_SCRATCH`). NOTE: this makes those functions **non-reentrant** — acceptable because `smt_solve` is a single serialized entry point (no concurrent SMT solves); documented.
8. **`} else {` one line (Trap 8):** AVOIDANCE: Phase 2 writes every else on the same physical line as the closing brace.
9. **Em-dash in comments (Trap 9):** AVOIDANCE: all comments use ASCII `--`/`->`, never U+2014. (This spec's prose em-dashes do not appear in the `.iii`.)
10. **`let mut x=0u32` checkpoint-flag (Trap 10):** the gospel uses flags like `done`/`found`/`ok`/`carry`/`have_prev`. These drive `while`/`if` conditions and are fine, but to be safe the LIA feasibility and Nelson-Oppen fixed-point use **`while flag==0u8` sentinel** patterns (the flag drives the loop condition itself), not a post-hoc mutated checkpoint. AVOIDANCE: prefer early-return where a single boolean gate would otherwise be mutated.
11. **`a % b` after call (Trap 11):** the rational `smt_gcd` is the only place modulo would be natural. AVOIDANCE: use the **subtractive** Euclidean algorithm (loop of `smt_rat_sub`-style magnitude subtraction on unsigned magnitudes), **no `%`**. Floor/ceil in B&B are computed by truncation + sign-tag adjustment, not `%`. If any `/` is used for a rational reduce, the divisor is assigned to a local immediately before the divide (param-spill avoidance) and never follows a call in the same expression.
12. **`@specialize *T` stride (Trap 12):** **not applicable** — this module is not generic over element width; all arrays are concretely `[i64;N]` / `[u32;N]` / `[u8;N]`. No `@specialize`.

## Gap / Fix List
The candidate is a STUB. Every defect and its fix:

1. **Nelson-Oppen combination missing (headline feature absent).** `smt_solve` solves LIA and BV independently — no shared vars, no equality exchange, no fixed point. FIX: add `smt_share`, the `SMT_SHARE_*` map, and the fixed-point exchange loop in `smt_solve_cap` (Algorithm step 1). Bound passes by `SMT_SHARE_N^2+1` (M19).

2. **SAT lifecycle ordering bug (FATAL).** BV adders call `sat_add_clause` *before* any `sat_init`; `smt_init` never inits SAT; `smt_solve` calls `sat_init` (which **wipes** all SAT state) only at the end. Result: either every clause-add returns `SAT_E_NOT_INIT`, or clauses are erased before solving. FIX: SMT **owns** a clause buffer (`SMT_CLBUF_*`); BV adders buffer clauses; `smt_solve` calls `sat_init(SMT_BV_SAT_NEXT-1)` **first**, then replays the buffer, then `sat_solve`. Also fixes re-solve under Nelson-Oppen (each pass replays cleanly).

3. **Brute-force LIA blows M19 / non-total.** `smt_lia_solve_brute` enumerates `(2*256+1)^NVAR` points — astronomically unbounded, and the prose admits it. FIX: replace with exact rational **Bland's-rule simplex + branch-and-bound** (Algorithm), node-capped at `2^24` with refusal (`SMT_E_TOO_BIG`) past the cap (M5/M19). Delete `smt_lia_solve_brute` and `smt_lia_check` (the verifier role moves to `smt_check_model`).

4. **Trap-3 SIGSEGV compares.** `sum > SMT_LIA_BND[c]`, `vals[j] > SMT_LIA_BOX`, `vals[j] <= SMT_LIA_BOX`. FIX: route all magnitude comparisons through `smt_rat_sign`/`smt_rat_cmp` (equality-tagged), never signed ordering. (Trap Exposure §3.)

5. **Trap-7 local `var` arrays.** `var vals`, `var cl`, `var c1..c6`, `var unit`. FIX: hoist to module scope (`SMT_SCRATCH_CL`, `SMT_BB_VALS`, simplex scratch). Note non-reentrancy.

6. **W2 violation.** `smt_lia_add_internal` has 5 params. FIX: delete it; inline the store in the three 4-param public adders (or pass kind via a one-shot module field). 

7. **Trap-4 unmasked shift.** `1u64 << (i as u64)` in `smt_bv_value`. FIX: mask `(i as u64) & 0xFFFFFFFFu64`.

8. **No witness (M6/M10).** Solve emits nothing. FIX: `smt_witness` + canonical serialization + `sha256_oneshot`, capability-gated in `smt_solve_cap` (M8). Recomputable byte-identically (M10).

9. **No checkable certificate (M12/M18).** A SAT result was unverifiable. FIX: `smt_check_model` independently re-checks the model against all constraints; SAT is only accepted when it returns `1u8`. This is the Curry-Howard/synthesis-verifiable artifact (M11/M12).

10. **No `>=` public entry; `>=` only via manual negation by the caller.** FIX: add `smt_lia_add_ge` that negates coeffs+bound internally (one place, less error-prone).

11. **`smt_bv_add_ult` final unit clause and base-case interplay fragile** (the `have_prev`/`i>0` double-guard). FIX: the logic is preserved but the spec pins the exact clause set (base 3 clauses at i=0; 6 clauses at i>0; one final unit `(prev_gt)`), all buffered. KAT 4 proves it is not a no-op (negative case).

12. **`SMT_E_TOO_BIG`/`SMT_E_BAD` are the only error codes; SAT errors not surfaced.** FIX: add `SMT_E_NOCAP`, `SMT_E_NOMODEL`; map a negative `sat_*` return to `SMT_E_BAD` (don't silently treat as UNSAT).

13. **Mandate coverage added:** M2/M15 (Bland's rule determinism + total within cap), M5/M19 (node cap → refusal not divergence), M6/M10 (witness), M8 (capability-gated witness via `smt_solve_cap`), M11/M12/M18 (model checker as certificate), M9 (re-`smt_init` reversibility). M3/M4 satisfied (no scores/heuristics; Bland's rule is the canonical exact rule).

## Implementation Skeleton
Structurally paste-ready. SINGLE-LINE signatures. No fn bodies (Phase 2 writes those per Algorithm §).

```iii
// III/STDLIB/iii/numera/smt.iii
//
// III STDLIB - numera::smt
//
// Satisfiability modulo theories. DPLL(T) over two convex theories:
//   LIA: linear integer arithmetic, exact rational Bland's-rule simplex
//        plus branch-and-bound for integrality. Constraints sum c_i x_i
//        <op> b, op in {<=, >=, ==}; >= stored as negation of <=.
//   BV:  fixed-width unsigned bit vectors (1..64) bit-blasted to the
//        Module-15 CDCL SAT solver. SMT owns a clause buffer and replays
//        it into SAT after sizing (sat_init wipes state, so buffer first).
// Combination: Nelson-Oppen equality exchange over shared integer vars,
//        iterated to a deterministic fixed point.
// Witness: sha256 over the canonical (constraints + model) transcript,
//        capability-gated. smt_check_model re-verifies any SAT model.
//
// Hexad: kind_essence.  Ring: R0.  K: 0.99.
// Discipline: W2 (<=4 params), W8 (static tables), W13, W14 (sentinel
// loops, no break), W15 (no recursion; explicit B&B stack + worklists).
// Non-reentrant: module-scope scratch (Trap 7) -- single serialized solve.

module numera_smt

extern @abi(c-msvc-x64) fn sat_init(n_vars: u32) -> i32 from "sat.iii"
extern @abi(c-msvc-x64) fn sat_add_clause(lits: *u32, n_lits: u32) -> i32 from "sat.iii"
extern @abi(c-msvc-x64) fn sat_solve() -> i32 from "sat.iii"
extern @abi(c-msvc-x64) fn sat_value(var: u32) -> u8 from "sat.iii"
extern @abi(c-msvc-x64) fn sha256_oneshot(input: *u8, len: u64, out_32: *u8) -> u32 from "sha256.iii"

const SMT_OK            : i32 =  0i32
const SMT_SAT           : i32 =  1i32
const SMT_UNSAT         : i32 =  2i32
const SMT_UNKNOWN       : i32 =  3i32
const SMT_E_TOO_BIG     : i32 = -1i32
const SMT_E_BAD         : i32 = -2i32
const SMT_E_NOCAP       : i32 = -3i32
const SMT_E_NOMODEL     : i32 = -4i32

const SMT_MAX_LIA_VARS  : u32 = 256u32
const SMT_MAX_LIA_CON   : u32 = 1024u32
const SMT_LIA_PACKED    : u32 = 16384u32
const SMT_MAX_BV_VARS   : u32 = 256u32
const SMT_BV_WIDTH_MAX  : u32 = 64u32
const SMT_BV_TOTAL_BITS : u32 = 16384u32

const SMT_SX_MAX_ROWS   : u32 = 1280u32
const SMT_SX_MAX_COLS   : u32 = 1600u32
const SMT_SX_CELLS      : u32 = 2048000u32
const SMT_BB_MAX_DEPTH  : u32 = 4096u32
const SMT_LIA_BOX       : i64 = 1048576i64
const SMT_CLBUF_MAX_LITS: u32 = 1048576u32
const SMT_CLBUF_MAX_CLS : u32 = 262144u32
const SMT_SAT_OK        : i32 =  0i32
const SMT_SAT_SAT       : i32 =  1i32
const SMT_SAT_UNSAT     : i32 =  2i32
const SMT_NULL_CAP      : u64 = 0u64
const SMT_NO_SHARE      : u32 = 0xFFFFFFFFu32
const SMT_NEG           : u8 = 0u8
const SMT_ZERO          : u8 = 1u8
const SMT_POS           : u8 = 2u8
const SMT_BB_NODE_CAP   : u64 = 16777216u64

// --- LIA constraint store ---
var SMT_LIA_NVAR    : u32 = 0u32
var SMT_LIA_NCON    : u32 = 0u32
var SMT_LIA_KIND    : [u8;  1024]
var SMT_LIA_OFF     : [u32; 1024]
var SMT_LIA_LEN     : [u32; 1024]
var SMT_LIA_BND     : [i64; 1024]
var SMT_LIA_COEFF   : [i64; 16384]
var SMT_LIA_VAR     : [u32; 16384]
var SMT_LIA_USED    : u32 = 0u32
var SMT_LIA_VAL     : [i64; 256]
var SMT_LIA_SOLVED  : u8 = 0u8
var SMT_ADD_KIND    : u8 = 0u8

// --- BV store ---
var SMT_BV_NVAR     : u32 = 0u32
var SMT_BV_WIDTH    : [u32; 256]
var SMT_BV_BIT0     : [u32; 256]
var SMT_BV_SAT_NEXT : u32 = 0u32
var SMT_BV_BIT_VAR  : [u32; 16384]
var SMT_BV_SOLVED   : u8 = 0u8

// --- SMT-owned clause replay buffer (fixes SAT lifecycle ordering) ---
var SMT_CLBUF_OFF   : [u32; 262144]
var SMT_CLBUF_LEN   : [u32; 262144]
var SMT_CLBUF_NCL   : u32 = 0u32
var SMT_CLBUF_LIT   : [u32; 1048576]
var SMT_CLBUF_USED  : u32 = 0u32

// --- Nelson-Oppen sharing ---
var SMT_SHARE_LIA   : [u32; 256]
var SMT_SHARE_BV    : [u32; 256]
var SMT_SHARE_N     : u32 = 0u32
var SMT_NO_NEW_EQ   : u8 = 0u8

// --- Exact rational simplex tableau (num/den, den>0) ---
var SMT_SX_NUM      : [i64; 2048000]
var SMT_SX_DEN      : [i64; 2048000]
var SMT_SX_NROWS    : u32 = 0u32
var SMT_SX_NCOLS    : u32 = 0u32
var SMT_SX_BASIS    : [u32; 1280]
var SMT_SX_RHSNUM   : [i64; 1280]
var SMT_SX_RHSDEN   : [i64; 1280]

// --- Branch-and-bound explicit DFS stack (W15) ---
var SMT_BB_VAR      : [u32; 4096]
var SMT_BB_LO       : [i64; 4096]
var SMT_BB_HI       : [i64; 4096]
var SMT_BB_SP       : u32 = 0u32
var SMT_BB_NODES    : u64 = 0u64

// --- Witness ---
var SMT_WIT_HASH    : [u8; 32]
var SMT_WIT_VALID   : u8 = 0u8
var SMT_WIT_SCRATCH : [u8; 65536]

// --- Hoisted per-fn scratch (Trap 7: no local var arrays) ---
var SMT_SCRATCH_CL  : [u32; 4]
var SMT_SX_PIVCOL_N : [i64; 1280]
var SMT_SX_PIVCOL_D : [i64; 1280]
var SMT_BB_VALS     : [i64; 256]

// --- SAT literal encoding helpers (match sat.iii: lit = (v<<1)|sign) ---
fn smt_pos_lit(v: u32) -> u32 { return (v << 1u32) }                       // TODO: trivial
fn smt_neg_lit(v: u32) -> u32 { return (v << 1u32) | 1u32 }                // TODO: trivial

// --- Rational primitives (NIH; no signed ordering, no modulo-after-call) ---
fn smt_rat_sign(num: i64) -> u8 { return SMT_ZERO }                        // TODO: body per Algorithm (sign-bit + ==0)
fn smt_gcd(a: i64, b: i64) -> i64 { return 1i64 }                          // TODO: subtractive Euclid (Trap 11)
fn smt_rat_reduce(idx: u32) -> i32 { return SMT_OK }                       // TODO: divide by gcd, den>0
fn smt_rat_cmp(an: i64, ad: i64, bn: i64, bd: i64) -> i32 { return 0i32 }  // TODO: sub then sign-tag

// --- Clause buffering (replayed into SAT in smt_solve) ---
fn smt_clbuf_add(n: u32) -> i32 { return SMT_OK }                          // TODO: copy SMT_SCRATCH_CL[0..n] into buffer

// --- Public: lifecycle + construction ---
fn smt_init() -> i32 @export { return SMT_OK }                                                                    // TODO: body per Algorithm
fn smt_lia_new_var() -> u32 @export { return 0u32 }                                                               // TODO
fn smt_lia_add_le(coeffs: *i64, vars: *u32, n: u32, b: i64) -> i32 @export { return SMT_OK }                      // TODO: store kind 0
fn smt_lia_add_ge(coeffs: *i64, vars: *u32, n: u32, b: i64) -> i32 @export { return SMT_OK }                      // TODO: negate -> store kind 0
fn smt_lia_add_eq(coeffs: *i64, vars: *u32, n: u32, b: i64) -> i32 @export { return SMT_OK }                      // TODO: store kind 1
fn smt_bv_new_var(width: u32) -> u32 @export { return 0u32 }                                                      // TODO
fn smt_bv_add_eq(a: u32, b: u32) -> i32 @export { return SMT_OK }                                                 // TODO: bit-blast a==b, buffer clauses
fn smt_bv_add_ult(a: u32, b: u32) -> i32 @export { return SMT_OK }                                                // TODO: Tseitin ult chain, buffer clauses
fn smt_share(lia_var: u32, bv_var: u32) -> i32 @export { return SMT_OK }                                          // TODO: register shared pair

// --- LIA simplex + branch-and-bound (internal; no recursion) ---
fn smt_sx_build() -> i32 { return SMT_OK }                                  // TODO: build tableau (slacks/artificials)
fn smt_sx_pivot() -> i32 { return SMT_OK }                                  // TODO: one Bland pivot
fn smt_sx_phase1() -> i32 { return SMT_OK }                                  // TODO: feasibility; SMT_SAT/SMT_UNSAT
fn smt_lia_solve() -> i32 { return SMT_UNSAT }                               // TODO: simplex + B&B over explicit stack

// --- Public: solve + model + certificate + witness ---
fn smt_solve_cap(cap: *u8) -> i32 @export { return SMT_UNSAT }                                                    // TODO: NO fixed point + witness
fn smt_solve() -> i32 @export { return SMT_UNSAT }                                                                // TODO: smt_solve_cap(0)
fn smt_lia_value(var: u32) -> i64 @export { return 0i64 }                                                         // TODO
fn smt_bv_value(var: u32) -> u64 @export { return 0u64 }                                                          // TODO: mask shift (Trap 4)
fn smt_check_model() -> u8 @export { return 0u8 }                                                                 // TODO: independent re-check (M12)
fn smt_witness(out_32: *u8) -> i32 @export { return SMT_E_BAD }                                                   // TODO: copy SMT_WIT_HASH
fn smt_selftest() -> u64 @export { return 0u64 }                                                                  // TODO: run KAT vectors 1-6
```
```
