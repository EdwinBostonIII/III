# 22 numera/cost_lattice.iii — Implementation Spec

## Verdict
PARTIAL — the gospel candidate implements the scalar dot-order half (`cl_init`, `cl_register_order`, `cl_dot`, `cl_compare`) but is **not a lattice**: it has neither `join` (least upper bound) nor `meet` (greatest lower bound), the two operations that define a lattice and that M19 boundedness rests on. It also carries a Trap-7 violation (four local `var [u64;6]` arrays inside `cl_init`), discards all four register-order statuses inside `cl_init` (W12), conflates "invalid slot" with "equal" in `cl_compare`, and lets `cl_dot` overflow u64 silently (breaks M15/M19 totality). This spec realizes the maximal intent: a total, bounded, deterministic cost lattice with crisp `compare` / `join` / `meet`, separated validity reporting, saturating dot for guaranteed boundedness, and explicit ⊥/⊤ elements.

## Purpose
`numera/cost_lattice.iii` IS the partial-order algebra over six-dimensional microarchitectural cost vectors `c = (latency, throughput, register_pressure, icache_footprint, dcache_footprint, energy)`. It carries a finite, immutable-once-registered set of named scalarizing orders (each a u64 weight vector `w`, inducing the total preorder `c ≤_w c' ⇔ w·c ≤ w·c'`) and the genuine product-lattice operations: component-wise `meet` (⊓ = per-dimension min, the greatest lower bound) and `join` (⊔ = per-dimension max, the least upper bound). It is the boundedness foundation (M19): every cost is comparable, every pair has a well-defined ⊓/⊔, and the scalar dot is saturating so no cost can escape the lattice by overflow. Hexad kind: `kind_essence`. Ring: R0. K-vector: 1.00 (pure — no allocation, no I/O, deterministic over fixed bit width).

## Public API
All public functions are single-line (Trap 1). Status convention: error/trichotomy codes are negative or {-1,0,1} `i32` constants compared by equality only (W9/W11); boolean predicates return `u8` 0/1 (W10); every public fn returns a status or sentinel-typed value (W12).

```
fn cl_init() -> i32 @export
fn cl_register_order(weights: *u64, out_slot: *u32) -> i32 @export
fn cl_order_live(slot: u32) -> u8 @export
fn cl_dot(weights: *u64, c: *u64) -> u64 @export
fn cl_dot_slot(slot: u32, c: *u64, out_dot: *u64) -> i32 @export
fn cl_compare(slot: u32, c: *u64, cp: *u64) -> i32 @export
fn cl_compare_checked(slot: u32, c: *u64, cp: *u64, out_ord: *i32) -> i32 @export
fn cl_join(c: *u64, cp: *u64, out: *u64) -> i32 @export
fn cl_meet(c: *u64, cp: *u64, out: *u64) -> i32 @export
fn cl_le_product(c: *u64, cp: *u64) -> u8 @export
fn cl_eq(c: *u64, cp: *u64) -> u8 @export
fn cl_bottom(out: *u64) -> i32 @export
fn cl_top(out: *u64) -> i32 @export
```

Return-status notes per fn:
- `cl_init` → `CL_OK` always (re-entrant: re-init re-seeds the four standard orders deterministically). Aggregates all four `cl_register_order` statuses; returns `CL_E_FULL` only if seeding ever fails (cannot under the static bound, but checked per W12).
- `cl_register_order` → `CL_OK` and writes `*out_slot`; `CL_E_FULL` if no free slot; `CL_E_BAD` on null `weights`/`out_slot`.
- `cl_order_live` → `u8` 1 if `slot < CL_MAX_ORDERS` and live, else 0 (W10).
- `cl_dot` → saturating `u64` dot (value-typed; `CL_DOT_SAT` = `0xFFFFFFFFFFFFFFFF` on saturation — a sentinel-typed value per W12). Pure helper kept `@export` for the dot-order use sites.
- `cl_dot_slot` → `CL_OK` writing `*out_dot`; `CL_E_BAD` on dead/out-of-range slot or null. The status-bearing wrapper so callers can distinguish a real dot value of `CL_DOT_SAT` from an invalid slot.
- `cl_compare` → trichotomy `{-1,0,1}` (`CL_LT`/`CL_EQ`/`CL_GT`) under order `slot`; **returns `CL_EQ` (0) for invalid slot to preserve the gospel's value shape** — but this is exactly the conflation bug, so `cl_compare_checked` is the sound form callers should prefer.
- `cl_compare_checked` → `CL_OK` and writes the trichotomy into `*out_ord`; `CL_E_BAD` on invalid slot/null. Separates "I could not compare" from "they are equal" (soundness).
- `cl_join` / `cl_meet` → `CL_OK` writing six u64s into `*out`; `CL_E_BAD` on any null. `out` may alias `c` or `cp` (in-place safe — see Algorithm).
- `cl_le_product` → `u8` 1 iff `c ⊑ cp` in the **product order** (component-wise ≤ on all six dims); else 0. This is the lattice's intrinsic partial order, distinct from any scalarizing `cl_compare`.
- `cl_eq` → `u8` 1 iff all six dims equal.
- `cl_bottom` → writes ⊥ = (0,0,0,0,0,0), the identity for `join`.
- `cl_top` → writes ⊤ = (MAX,…,MAX), the identity for `meet`. `CL_COST_MAX` per dim.

## Constant Namespace
PREFIX = `CL_` (the gospel's chosen prefix). **Collision check:** `grep` of `STDLIB/` for `CL_OK`, `CL_DIM`, `CL_MAX_ORDERS`, `CL_LIVE`, `CL_W`, `CL_E_FULL`, `CL_E_BAD` → **no matches**; `grep` for the dispatch-assigned `CLATTICE_` → **no matches**; `grep` for `module numera_cost_lattice` / `fn cl_` → **no matches** (module not yet built). Both prefixes are free. Keeping the gospel's `CL_`/`cl_` (Trap 2 satisfied — every module-scope const is `CL_`-prefixed, globally unique). If a future module claims `CL_`, migrate wholesale to `CLATTICE_` (noted here so the migration is mechanical).

Module-level constants (every `const NAME : T = V`, all `CL_`-prefixed):
```
const CL_OK        : i32 =  0i32
const CL_E_FULL    : i32 = -1i32
const CL_E_BAD     : i32 = -2i32

const CL_LT        : i32 = -1i32       // trichotomy: c <_w c'
const CL_EQ        : i32 =  0i32       // trichotomy: equal under w
const CL_GT        : i32 =  1i32       // trichotomy: c >_w c'

const CL_DIM        : u32 = 6u32       // fixed cost-vector arity
const CL_MAX_ORDERS : u32 = 64u32      // static order-table bound (W8)

const CL_COST_MAX  : u64 = 0xFFFFFFFFFFFFFFFFu64   // ⊤ per-dim value
const CL_DOT_SAT   : u64 = 0xFFFFFFFFFFFFFFFFu64   // saturated dot sentinel
```
Note: `CL_COST_MAX` and `CL_DOT_SAT` share the value `U64_MAX` but are named distinctly because they carry distinct meanings (a top-element coordinate vs. an arithmetic saturation marker); keeping both makes the source self-documenting and costs nothing (both fold to the same immediate).

## Data Structures
All module-scope, statically sized (W8); no local `var` arrays anywhere (Trap 7 — this is the fix for the candidate's `w0..w3`).
```
var CL_LIVE  : [u8;  64]    // CL_MAX_ORDERS live flags; index = slot
var CL_W     : [u64; 384]   // CL_MAX_ORDERS * CL_DIM weights, row-major: w[slot*6 + k]
```
Bound justification: `CL_MAX_ORDERS = 64` orders is the gospel's stated bound — four standard orders (server/realtime/lowpower/balanced) plus headroom for runtime-registered orders; 64 × 6 × 8 B = 18 KiB BSS, trivially static. Orders are immutable once registered (no per-order mutation API), so the table never needs compaction; `CL_LIVE` only ever transitions 0→1 (set at register, cleared only by `cl_init` re-seed). No reentrancy concern: the table is module global by design (a process-wide order registry); all reads after init are pure. The standard-order weight literals live as inline assignments into module-scope scratch rows (see Algorithm `cl_init`), **not** as local `var` arrays.

## Dependencies (externs)
**None.** This module is self-contained pure arithmetic over libc-free III primitives (M1 NIH satisfied with zero externs). It does not call `arena_*`, `ident_*`, `witness_spine`, or `scalar_*`. The gospel candidate also has no externs; confirmed correct — a Layer-5 essence primitive should sit at the bottom of the cost stack.

Downstream (modules that depend on THIS, for wave ordering — none externs `cl_*` today, so none block on my exact symbol names; listed for the scheduler):
- Module 23 `numera/cost_calculus.iii` — produces the six-dim cost vectors this lattice orders. **Not-yet-built.**
- Module 65 `numera/cost_lattice_synth.iii` — the V3 64-byte extended lattice; conceptually "extends" this base but re-implements its own vector ops (does not extern `cl_*`). **Not-yet-built.**
- Module 81 `aether/cost_overrun_handler.iii` — consumes `COST_OVERRUN` events that bound-checks against this lattice raise. **Not-yet-built.**

So: **0 not-yet-built dependencies of mine** (I extern nothing). 3 not-yet-built dependents.

## Algorithm
Determinism (M2) and bit-identity (W5): every operation is fixed-width integer arithmetic over u64/u32 with no floating point, no data-dependent control beyond bounded counted loops, and a fixed dimension `CL_DIM = 6`. Identical `(weights, c, c')` → identical bytes, every run, every CPU. No ML/heuristics (M3/M4): orders are explicit weight vectors; comparison is exact algebra; ⊓/⊔ are exact component extrema. No recursion (W15) — all loops are counted with an index < bound. NIH (M1): hand-rolled saturating multiply-add and component min/max; no library calls.

**`cl_init`** — Clear all `CL_LIVE[0..64)` to 0 with a counted loop. Then seed the four standard orders by writing their weight literals directly into the next free row of `CL_W` via `cl_register_order` (NOT into a local array): for each of the four orders, assign the six u64 weights into a module-scope scratch row `CL_W[free*6 + k]`-style through a tiny module-scope `var CL_SEED : [u64;6]` staging buffer (module scope satisfies Trap 7), call `cl_register_order(&CL_SEED[0], &slot)`, and **check the returned status** — accumulate into a flag; if any seed returns non-`CL_OK`, return `CL_E_FULL` (W12 — the candidate's silent discard is fixed). Standard weights (gospel-exact): server `(1,4,1,1,1,0)`, realtime `(8,1,1,2,2,0)`, lowpower `(2,1,1,1,1,8)`, balanced `(2,2,1,1,1,1)`. Order is deterministic → slots 0,1,2,3 always map to server,realtime,lowpower,balanced. Re-entrant: a second `cl_init` clears then re-seeds identically (M2). Loop discipline: W14 sentinel/counter form, no `break`.

**`cl_register_order`** — Null-check `weights`/`out_slot` (return `CL_E_BAD` if either is 0 — sound pointer null test compares the `as u64` address to `0u64`, NOT a 16-bit test, avoiding Trap-adjacent narrow compares). Linear scan slots `0..CL_MAX_ORDERS` for the first `CL_LIVE[i]==0`; on hit, copy the six weights `CL_W[i*6 + k] = weights[k]` (k counted 0..6), set `CL_LIVE[i]=1`, write `*out_slot=i`, return `CL_OK`. W14: drive the scan by a `found` sentinel flag so there is a single structured exit and no `break`; the "first free" decision is exact (lowest free index), hence deterministic. Indexing `i*CL_DIM + k`: `i` and `k` are u32, the product/sum is a u32 array index used directly (no `as u64` pointer math), so Trap 4 does not apply; nonetheless the index is bounded by `CL_MAX_ORDERS*CL_DIM = 384` = the array length, so no OOB.

**`cl_order_live`** — Return 0 if `slot >= CL_MAX_ORDERS` (unsigned compare on u32 — safe); else return `CL_LIVE[slot]`.

**`cl_dot`** — Saturating dot product (M15/M19 totality fix). `acc = 0`; for k in 0..6: compute `prod = w[k] * c[k]` with overflow detection (hand-rolled: `if w[k] != 0 && prod / w[k] != c[k]` → overflow); on any overflow, set `acc = CL_DOT_SAT` and stop accumulating (sentinel flag drives loop, W14); else `sum = acc + prod`, detect add-overflow (`if sum < acc` → wrapped) and saturate to `CL_DOT_SAT`. Return `acc`. The division `prod / w[k]` is guarded by `w[k] != 0` and is NOT a modulo-after-call (Trap 11 is about `%` after a call; this is `/` with no intervening call) — but to be safe the divisor `w[k]` is read into a local `wk` first and the division uses the local, so even the param-spill family cannot touch it. No `%` anywhere. Saturation guarantees the dot is bounded → M19.

**`cl_dot_slot`** — Validate `slot` via `cl_order_live`; null-check `c`/`out_dot`; on failure return `CL_E_BAD`. Else compute `w = &CL_W[slot*6]`, `*out_dot = cl_dot(w, c)`, return `CL_OK`. This is the status-bearing form so a genuine `CL_DOT_SAT` value is distinguishable from an invalid slot.

**`cl_compare`** — Gospel-shape trichotomy. If `slot >= CL_MAX_ORDERS` or `CL_LIVE[slot]==0` → return `CL_EQ` (0) (preserves the candidate's value contract; documented as the conflation hazard). Else `w = &CL_W[slot*6]`; `d1 = cl_dot(w,c)`; `d2 = cl_dot(w,cp)`; **both d1,d2 are u64 → the ordering compares `d1 < d2` and `d1 > d2` are UNSIGNED** (Trap 3 / W11 are about *signed* i64/i32 ordering; u64 ordering is safe and is the correct cost semantics). Return `CL_LT` / `CL_GT` / `CL_EQ`. Equality on saturated dots: if both saturate they compare `CL_EQ` (both "unboundedly expensive") — acceptable and deterministic.

**`cl_compare_checked`** — Sound form. Validate slot+nulls → `CL_E_BAD`. Else compute the same trichotomy, write it into `*out_ord`, return `CL_OK`. Callers needing to distinguish "incomparable/invalid" from "equal" use this.

**`cl_join`** (⊔, least upper bound under the product order) — Null-check `c`/`cp`/`out` → `CL_E_BAD`. For k in 0..6: `vc = c[k]`, `vd = cp[k]`; `out[k] = vc` then `if vd > vc { out[k] = vd }` (per-dimension max; unsigned u64 compare — safe). In-place/alias-safe because each `out[k]` is written after both inputs at index `k` are read into locals. Returns `CL_OK`. This is the genuine join: for the product order ⊑ (component-wise ≤), `max` per coordinate is the unique least upper bound.

**`cl_meet`** (⊓, greatest lower bound) — Same shape with `min`: `out[k] = vc` then `if vd < vc { out[k] = vd }`. Returns `CL_OK`. Per-coordinate `min` is the unique greatest lower bound of the product order.

**`cl_le_product`** — The product partial order test. Null-check → return 0 (a predicate; cannot return a negative status, so "invalid" maps to "not ≤"; callers needing the distinction null-check themselves). For k in 0..6: if `c[k] > cp[k]` set a `not_le` sentinel flag; loop runs all six (W14, no break). Return `1u8` if `not_le==0`, else `0u8`. Unsigned compares throughout. This order is reflexive, antisymmetric, transitive — and `cl_join`/`cl_meet` are its lub/glb, so `(cost vectors, ⊑, ⊔, ⊓, ⊥, ⊤)` is a bounded lattice (M19 names exactly this structure).

**`cl_eq`** — For k in 0..6: if `c[k] != cp[k]` set `neq` flag. Return `1u8` iff `neq==0`. Equality-only compares (W11-clean even though values are u64).

**`cl_bottom`** — Write `out[k]=0u64` for k in 0..6, return `CL_OK`. ⊥ is the `join` identity and the ⊑-least element.

**`cl_top`** — Write `out[k]=CL_COST_MAX` for k in 0..6, return `CL_OK`. ⊤ is the `meet` identity and the ⊑-greatest element.

Algebraic laws the implementation must satisfy (these are the M19/M15 contract and the KAT targets): `join`/`meet` are commutative, associative, idempotent, mutually absorbing; `cl_bottom` is the join-identity (`join(x,⊥)=x`); `cl_top` is the meet-identity (`meet(x,⊤)=x`); `cl_le_product(c,cp)=1 ⇔ cl_eq(cl_join(c,cp),cp)=1 ⇔ cl_eq(cl_meet(c,cp),c)=1` (the lattice consistency identity).

## KAT Vectors (≥3)
Cost vectors written as `(latency, throughput, regp, icache, dcache, energy)`. All checks are byte-for-byte on the six output u64s or on the exact i32/u8 return.

1. **Standard-order init + scalar compare (server).** `cl_init()`; then with order slot 0 (server `w=(1,4,1,1,1,0)`), `c=(10,2,0,0,0,0)` → `cl_dot(server,c)=10*1+2*4=18`; `cp=(2,3,0,0,0,0)` → `cl_dot=2+12=14`. `cl_compare(0,c,cp)` → `CL_GT (1)` (c costs 18 > 14). `cl_compare(0,cp,c)` → `CL_LT (-1)`. `cl_compare(0,c,c)` → `CL_EQ (0)`. Realtime slot 1 `w=(8,1,1,2,2,0)`: `cl_dot(1,c)=10*8+2=82`.

2. **Join / meet / product-order (the lattice core).** `a=(5,10,2,3,4,1)`, `b=(7,6,2,1,9,0)`. `cl_join(a,b,out)` → `out=(7,10,2,3,9,1)` (per-dim max). `cl_meet(a,b,out)` → `out=(5,6,2,1,4,0)` (per-dim min). `cl_le_product(a,b)` → `0` (a[1]=10 > b[1]=6). `cl_le_product(cl_meet(a,b), a)` → `1` (glb ⊑ a). `cl_le_product(a, cl_join(a,b))` → `1` (a ⊑ lub). `cl_eq(cl_join(a,b), b)` → `0`. Idempotence: `cl_join(a,a)` → `a`; `cl_meet(a,a)` → `a`.

3. **⊥/⊤ identities + dot saturation (boundedness, M19).** `cl_bottom(z)` → `z=(0,0,0,0,0,0)`; `cl_join(a,z)` → `a` (⊥ is join-identity); `cl_meet(a,z)` → `z` (since z⊑a). `cl_top(t)` → `t=(MAX,MAX,MAX,MAX,MAX,MAX)`; `cl_meet(a,t)` → `a` (⊤ is meet-identity); `cl_join(a,t)` → `t`. Saturation: with `w=(MAX,1,1,1,1,1)` registered and `c=(2,0,0,0,0,0)`, `MAX*2` overflows → `cl_dot=CL_DOT_SAT (0xFFFF...FF)`; `cl_dot_slot(slot,c,&d)` returns `CL_OK` with `d=CL_DOT_SAT`, while `cl_dot_slot(99,c,&d)` returns `CL_E_BAD` (slot-validity distinguished from a true saturated value — the conflation fix).

4. **Validity separation (soundness).** `cl_compare(99, a, b)` → `CL_EQ (0)` (gospel-shape conflation, documented). `cl_compare_checked(99, a, b, &ord)` → `CL_E_BAD` and `ord` untouched. `cl_compare_checked(0, a, a, &ord)` → `CL_OK`, `ord=CL_EQ`. `cl_order_live(0)` → `1` (after init); `cl_order_live(63)` → `0`; `cl_order_live(64)` → `0` (out of range).

## Trap Exposure
- **Trap 1 (multi-line `fn`)** — exposed (13 signatures). Avoidance: every signature is written single-line; verified in Skeleton.
- **Trap 2 (module-level `const` global)** — exposed (11 consts). Avoidance: every const `CL_`-prefixed; grep confirms `CL_*` and `CLATTICE_` both collision-free in `STDLIB/`.
- **Trap 3 (signed-ordering SIGSEGV)** — **NOT exposed.** Every ordering compare (`<`,`>`) is on **u64** (cost words / dot results), which is unsigned and safe. There is no `i64`/`i32` ordering compare anywhere; the only i32s are the constants `CL_OK/CL_LT/CL_EQ/CL_GT/CL_E_*`, used solely as return values and compared by equality (W11). Stated explicitly because a casual reader might think `d1 < d2` is risky — it is not, since `d1,d2:u64`.
- **Trap 4 (u32-in-u64-slot garbage)** — minimally exposed. Slot/dimension indices are u32 used directly as array subscripts (`CL_W[i*CL_DIM+k]`), not cast `as u64` for raw pointer arithmetic, so the garbage-high-bits path is not hit. Where `slot` reaches a row base, the index arithmetic stays in u32 and is bounded by the array length; if a future edit introduces `(slot as u64)` pointer math, mask `& 0xFFFFFFFFu64` first.
- **Trap 5 (u32 pointer store width)** — **NOT exposed.** All stores are u64 (`CL_W`, all `out[k]`) or u8 (`CL_LIVE[i]=…u8`, no narrowing from a u32 local). No `*u32` stores.
- **Trap 6 (nested block comments)** — avoided: no `/* */` nests; inline notes use `//`.
- **Trap 7 (local `var` arrays)** — **the candidate violates this** (`w0,w1,w2,w3 : [u64;6]` inside `cl_init`). Fix: a single module-scope staging buffer `var CL_SEED : [u64;6]` reused across the four seed writes (serialized, non-reentrant init — acceptable for one-shot init; noted). No other local arrays.
- **Trap 8 (`} else {` split)** — avoided: every `else` written `} else {` single-line; preferring guard-style early `if` returns reduces `else` count.
- **Trap 9 (em-dash in comment)** — avoided: ASCII `--` only in all comments.
- **Trap 10 (`let mut` checkpoint flag)** — touched by the `found`/`not_le`/`neq`/`overflow` sentinel flags W14 requires. Avoidance: where a clean early-return expresses the same logic (e.g. `cl_register_order` could `return CL_OK` on hit), prefer it; where the loop must complete (predicates `cl_le_product`/`cl_eq`, saturating `cl_dot`), the flag drives the loop condition itself (the iiis-1 insertion-sort lesson) rather than being a post-hoc mutated boolean. Spec'd per-fn in Algorithm.
- **Trap 11 (`a % b` after call)** — **NOT exposed.** No `%` anywhere in this module. The only division (`prod / wk` in saturating `cl_dot`) uses a local-copied divisor `wk` and has no intervening function call, so the quotient/stale-divisor param-spill family cannot apply.
- **Trap 12 (`@specialize *T` stride)** — **NOT exposed.** No `@specialize`; element width is fixed (u64 dims, u8 flags); `cl_dot`'s `c`/`weights` are concrete `*u64`, so `p[k]` correctly strides 8 bytes.

## Gap / Fix List
The candidate is PARTIAL. Gaps and fixes (each closed in this spec):

1. **Missing `join` and `meet` (the defining lattice ops).** A "cost lattice" with only `compare` is a comparator, not a lattice; M19 ("cost is bounded under the cost lattice") presupposes ⊓/⊔ and ⊥/⊤. **Fix:** add `cl_join` (per-dim max = lub), `cl_meet` (per-dim min = glb), `cl_le_product` (the intrinsic ⊑), `cl_eq`, `cl_bottom`, `cl_top` — the full bounded-lattice surface, with the consistency identity in the KATs.
2. **Trap-7 violation in `cl_init`** (`w0..w3 : [u64;6]` are local var arrays). **Fix:** module-scope `CL_SEED : [u64;6]` staging buffer, reused.
3. **W12 violation in `cl_init`** — the four `cl_register_order` return statuses are discarded. **Fix:** aggregate statuses; return `CL_E_FULL` if any seed fails.
4. **Soundness bug in `cl_compare`** — returns 0 (=`CL_EQ`) for an invalid/dead slot, indistinguishable from a true equality. **Fix:** keep `cl_compare`'s gospel value-shape (documented conflation) but add `cl_compare_checked` (writes ord via out-param, returns `CL_E_BAD` on invalid) as the sound form, and `cl_order_live` to pre-check.
5. **M15/M19 totality bug in `cl_dot`** — `acc + weights[k]*c[k]` can overflow u64 and wrap silently, making "cost" non-monotone and unbounded (a wrapped huge cost reads as tiny). **Fix:** hand-rolled saturating multiply-add to `CL_DOT_SAT`; add `cl_dot_slot` status wrapper so a genuine saturated value is distinguishable from an invalid slot.
6. **No null-pointer guards** on `cl_register_order`/`cl_compare`/`cl_dot` in the candidate. **Fix:** explicit `(p as u64) == 0u64` null checks on every public pointer param (64-bit compare, not the 16-bit-null hazard).
7. **No ⊥/⊤ elements** — M19 boundedness needs identified extreme elements. **Fix:** `cl_bottom`/`cl_top`.

Mandate posture after fixes: M1 (zero externs, hand-rolled) ✓; M2/W5 (fixed-width integer, no FP, counted loops) ✓; M3/M4 (explicit weights, exact algebra) ✓; M5 (no mutation of registered orders → no bricking) ✓; M7 (R0) ✓; M8 (no privileged action; pure compute, no capability needed) ✓; M9 (`join`/`meet`/`compare` are pure functions — trivially reversible by recomputation, no destructive state) ✓; M15 (saturating ops total over u64) ✓; M19 (bounded lattice with ⊓/⊔/⊥/⊤ and saturating dot — this module IS the M19 foundation) ✓. Witness (M6/M10): this is a pure essence primitive that emits no witness fragments itself; its outputs are byte-reproducible from inputs, so any caller's witness over `(weights, c, c', result)` is recomputable (M10). Noted: bound-overrun *fragment emission* lives in Module 65/81, not here — Module 22 only supplies the total order/lattice they bound against.

## Implementation Skeleton
```iii
/* III/STDLIB/iii/numera/cost_lattice.iii
 *
 * III STDLIB - numera::cost_lattice
 *
 * Bounded partial-order lattice over six-dim microarch cost vectors:
 *   c[0] latency  c[1] throughput  c[2] register pressure
 *   c[3] icache footprint  c[4] dcache footprint  c[5] energy
 *
 * Two layers:
 *   (1) scalarizing orders: a u64 weight vector w induces the total
 *       preorder c <=_w c' iff w.c <= w.c'  (dot, saturating).
 *   (2) the intrinsic product lattice: meet = per-dim min (glb),
 *       join = per-dim max (lub), bottom = 0-vector, top = MAX-vector.
 *
 * Standard orders seeded at init (slots 0..3):
 *   0 server    (1,4,1,1,1,0)
 *   1 realtime  (8,1,1,2,2,0)
 *   2 lowpower  (2,1,1,1,1,8)
 *   3 balanced  (2,2,1,1,1,1)
 *
 * Orders are immutable once registered. Pure: no externs, no alloc,
 * no FP, no recursion. M19 boundedness foundation.
 *
 * Hexad: kind_essence.  Ring: R0.  K: 1.00.
 */

module numera_cost_lattice

const CL_OK        : i32 =  0i32
const CL_E_FULL    : i32 = -1i32
const CL_E_BAD     : i32 = -2i32

const CL_LT        : i32 = -1i32
const CL_EQ        : i32 =  0i32
const CL_GT        : i32 =  1i32

const CL_DIM        : u32 = 6u32
const CL_MAX_ORDERS : u32 = 64u32

const CL_COST_MAX  : u64 = 0xFFFFFFFFFFFFFFFFu64
const CL_DOT_SAT   : u64 = 0xFFFFFFFFFFFFFFFFu64

var CL_LIVE  : [u8;  64]      // live flag per order slot
var CL_W     : [u64; 384]     // 64 * 6 weights, row-major w[slot*6 + k]
var CL_SEED  : [u64; 6]       // module-scope staging row for init (Trap 7 fix)

// --- order registry ---

fn cl_init() -> i32 @export {
    // TODO: body per Algorithm cl_init -- clear CL_LIVE; seed 4 standard
    // orders via CL_SEED + cl_register_order; aggregate statuses (W12).
}

fn cl_register_order(weights: *u64, out_slot: *u32) -> i32 @export {
    // TODO: body per Algorithm cl_register_order -- null-check; scan for
    // first free slot (found-flag, no break); copy 6 weights; set live.
}

fn cl_order_live(slot: u32) -> u8 @export {
    // TODO: body per Algorithm cl_order_live -- range-check then CL_LIVE.
}

// --- scalar dot order ---

fn cl_dot(weights: *u64, c: *u64) -> u64 @export {
    // TODO: body per Algorithm cl_dot -- saturating mul-add over 6 dims;
    // local-copied divisor for overflow check; return CL_DOT_SAT on ovf.
}

fn cl_dot_slot(slot: u32, c: *u64, out_dot: *u64) -> i32 @export {
    // TODO: body per Algorithm cl_dot_slot -- validate; *out_dot=cl_dot(w,c).
}

fn cl_compare(slot: u32, c: *u64, cp: *u64) -> i32 @export {
    // TODO: body per Algorithm cl_compare -- u64 dot trichotomy; invalid
    // slot -> CL_EQ (gospel shape; conflation documented).
}

fn cl_compare_checked(slot: u32, c: *u64, cp: *u64, out_ord: *i32) -> i32 @export {
    // TODO: body per Algorithm cl_compare_checked -- validate -> CL_E_BAD;
    // else write trichotomy to *out_ord, return CL_OK (sound form).
}

// --- intrinsic product lattice ---

fn cl_join(c: *u64, cp: *u64, out: *u64) -> i32 @export {
    // TODO: body per Algorithm cl_join -- per-dim max (lub); alias-safe.
}

fn cl_meet(c: *u64, cp: *u64, out: *u64) -> i32 @export {
    // TODO: body per Algorithm cl_meet -- per-dim min (glb); alias-safe.
}

fn cl_le_product(c: *u64, cp: *u64) -> u8 @export {
    // TODO: body per Algorithm cl_le_product -- component-wise <= ; not_le
    // sentinel drives the loop (W14), unsigned u64 compares.
}

fn cl_eq(c: *u64, cp: *u64) -> u8 @export {
    // TODO: body per Algorithm cl_eq -- component-wise == ; neq sentinel.
}

fn cl_bottom(out: *u64) -> i32 @export {
    // TODO: body per Algorithm cl_bottom -- write 6 zeros (join identity).
}

fn cl_top(out: *u64) -> i32 @export {
    // TODO: body per Algorithm cl_top -- write 6 * CL_COST_MAX (meet id).
}
```
