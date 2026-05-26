# 02 STDLIB/iii/numera/tiebreak.iii — Implementation Spec

## Verdict
PARTIAL — the gospel candidate body is logically correct and trap-light, but (a) `tb_select_by_u64_then_ident` has a **two-line signature** (Trap 1 — silent-corruption or parse failure), (b) there is **no `tb_selftest()` KAT harness** (every sibling numera module ships one returning `99u64`; this is the Phase-2 acceptance gate), and (c) the canonical tie-break rule from the prose ("equal idents → lower memory address wins") is **enforced implicitly but undocumented** in the body. All three are closed below. No mandate is violated; the maximal intent (a complete, witness-clean, self-testing set of deterministic ordering primitives) is realizable as specified.

## Purpose
`numera::tiebreak` is the substrate's canonical **deterministic ordering arbiter**: wherever an algorithm must pick exactly one representative from a set of candidates that compare equal under their primary ordering, this module *is* the rule that makes that choice total and reproducible. The rule is fixed and public — primary key first (a `u64` cost/priority), then lexicographic 256-bit identifier, then (as a structural consequence of scanning ascending indices over a contiguous array) the lowest first-issued arena address. Hexad: **kind_essence**. Ring: **R0**. K-vector: **1.00** (pure, total, allocation-free — cannot fail except on null/empty input).

## Public API
All four are `@export`. Each returns a negative-`i32` status (W9) or, for `tb_compare_pair`, a sentinel-typed `i32` ordering in `{-1,0,1}` (W12). The `out_index` functions write the winning index through `*u64` and return `TB_OK`/error.

```iii
fn tb_min_ident(items: *u8, count: u64, out_index: *u64) -> i32 @export
fn tb_max_ident(items: *u8, count: u64, out_index: *u64) -> i32 @export
fn tb_compare_pair(a_val: u64, a_ident: *u8, b_val: u64, b_ident: *u8) -> i32 @export
fn tb_select_by_u64_then_ident(values: *u64, idents: *u8, count: u64, out_index: *u64) -> i32 @export
```

Plus the mandated self-test (house convention, returns `99u64` on full pass, else a numbered failure code):

```iii
fn tb_selftest() -> u64 @export
```

Return-status convention:
- `tb_min_ident` / `tb_max_ident` / `tb_select_by_u64_then_ident`: `TB_OK` (0) on success; `TB_E_NULL` (-2) if any required pointer is null; `TB_E_EMPTY` (-1) if `count == 0`. `out_index` is written **only** on `TB_OK`. (W12 satisfied — every public fn returns a status.)
- `tb_compare_pair`: total ordering result `-1i32`/`0i32`/`1i32`. This is a sentinel-typed value, not an error code; it has no null guard because both ident pointers are contractually non-null (it is a leaf comparator; callers pass interior pointers they already validated). Compared by `==`/`!=` only at every call site (W11).

## Constant Namespace
PREFIX = `TB_`  (the gospel header and candidate body both use `TB_`, not the dispatch-line literal `TIEBREAK_`; `TB_` is shorter, matches the file's own body, and — confirmed below — does not collide. **Adopt `TB_`.**)

Grep result: `grep -rn "TB_" STDLIB/` and `grep -rn "TIEBREAK_" STDLIB/` both return **zero matches**. No existing module declares `TB_OK`, `TB_E_EMPTY`, `TB_E_NULL`, or `TB_IDENT_BYTES`. No collision (Trap 2 clear). There is no pre-existing `tiebreak.iii`.

| name | type | value | role |
|---|---|---|---|
| `TB_OK` | `i32` | `0i32` | success status |
| `TB_E_EMPTY` | `i32` | `-1i32` | `count == 0` |
| `TB_E_NULL` | `i32` | `-2i32` | required pointer null |
| `TB_IDENT_BYTES` | `u64` | `32u64` | identifier stride (one Keccak256 id) |

(All four are module-scope `const`; per Trap 2 each emits a linker-global `L_TB_*` symbol — the `TB_` prefix keeps them unique tree-wide.)

## Data Structures
The four ordering primitives are **allocation-free and use only function-scope `let` locals** — no module-scope arena, no slot table (W6/W7/W8 vacuously satisfied; nothing to bound). All index/stride arithmetic is performed in `u64`.

The self-test requires fixed identifier vectors. Per Trap 7 (no local `var` arrays) these are declared at **module scope** with the `TB_` prefix and are used only by `tb_selftest` (serialized, single-threaded test — reentrancy not required, noted):

| name | type | size | bound justification |
|---|---|---|---|
| `TB_KAT_IDENTS` | `[u8; 96]` | 96 = 3 × 32 | three 32-byte identifiers for the min/max/select KATs |
| `TB_KAT_VALUES` | `[u64; 3]` | 3 | three `u64` primary keys paired with the idents above |
| `TB_KAT_OUT` | `[u64; 1]` | 1 | scratch `out_index` receiver for the KAT calls |

No other module-scope state. No global pointer escapes; address-of (`&TB_KAT_*`) is taken only inside `tb_selftest` within this file (W1/W3).

## Dependencies (externs)
```iii
extern @abi(c-msvc-x64) fn ident_cmp(a: *u8, b: *u8) -> i32 from "identifier.iii"
```
- **`ident_cmp`** — provided by **Module 01 `numera/identifier.iii`** (Layer 0). **Already built and present** in `STDLIB/iii/numera/identifier.iii:50`. Verified contract: returns exactly `-1i32` (a<b), `0i32` (equal), `1i32` (a>b) via a sentinel-flag byte-scan over 32 bytes — no signed-ordering trap on its side. This is the module's **only** dependency (M1/M14: dependency closure = {identifier} → {keccak256}).

**Not-yet-built dependencies: 0.** Module 02 can be scheduled immediately after Module 01 (already complete), so it is unblocked in the current wave.

## Algorithm

Determinism (M2) and bit-identity (W5) hold trivially across all five functions: every operation is integer compare / pointer arithmetic / byte compare over fixed widths; there is no allocation, no time/entropy source, no float, no data-dependent control beyond the inputs themselves. Identical inputs → identical scan order → identical winning index, on every CPU. No ML/heuristics (M3/M4): the winner is selected by an exact, fully specified lexicographic rule, never by counting, adapting, or thresholding. No recursion anywhere (W15) — all loops are flat sentinel-driven `while` scans (W14). Each is O(count) comparisons and bounded by `count` under the cost lattice (M19).

### `tb_min_ident(items, count, out_index) -> i32`
Hand-rolled **linear minimum scan** with lexicographic comparator.
1. Guard in this exact order (so a null `out_index` is reported before dereference): `if out_index == null → TB_E_NULL`; `if count == 0 → TB_E_EMPTY`; `if items == null → TB_E_NULL`.
2. `best = 0u64`; scan `i = 1 .. count`.
3. For each `i`: form `p_best = (items as u64 + best * TB_IDENT_BYTES) as *u8` and `p_i = (items as u64 + i * TB_IDENT_BYTES) as *u8` (all-`u64` arithmetic). `c = ident_cmp(p_i, p_best)`.
4. `if c == -1i32 { best = i }` — **strict** less-than only. On a tie (`c == 0i32`) `best` is *not* moved, so the **lower index — hence the lower memory address** in the contiguous `items` block — remains canonical. This is exactly the prose tie-break rule ("equal idents → lower memory address wins"); the implementation **must carry an explicit comment stating this** so the tie rule is not hidden (gospel discipline: "no hidden tie breaking").
5. `*out_index = best; return TB_OK`.

### `tb_max_ident(items, count, out_index) -> i32`
Identical structure to `tb_min_ident`, comparator inverted: `if c == 1i32 { best = i }` (strict greater-than). On a tie the lower index/address again wins — a deliberate asymmetry (max value, min address) that **must be documented** in-body for the same no-hidden-rule reason.

### `tb_compare_pair(a_val, a_ident, b_val, b_ident) -> i32`
Hand-rolled **lexicographic pair comparator** = primary `u64` key, then identifier.
1. `if a_val < b_val { return -1i32 }` — **unsigned** ordering compare on `u64`. (Trap 3 covers *signed* `i32`/`i64` only; the exemplar `identifier.iii:58-59` performs the same unsigned `<`/`>` on `u32` safely. SAFE.)
2. `if a_val > b_val { return 1i32 }`.
3. Else equal primary key → `return ident_cmp(a_ident, b_ident)` (forwards the secondary tie-break to the canonical identifier comparator; result already in `{-1,0,1}`).

### `tb_select_by_u64_then_ident(values, idents, count, out_index) -> i32`
Hand-rolled **linear minimum scan under the composite (value, ident) order**.
1. Guards (this order): `out_index` null → `TB_E_NULL`; `count == 0` → `TB_E_EMPTY`; `values` null → `TB_E_NULL`; `idents` null → `TB_E_NULL`.
2. `best = 0u64`; scan `i = 1 .. count`.
3. For each `i`: compute `p_best`/`p_i` ident pointers (as in `tb_min_ident`); load `v_best = values[best]`, `v_i = values[i]` (indexed loads through a `*u64` param — load-side, not the Trap-5 store case; SAFE). `c = tb_compare_pair(v_i, p_i, v_best, p_best)`.
4. `if c == -1i32 { best = i }` — strict; ties keep the lower index/address (same canonical rule; **document it**).
5. `*out_index = best; return TB_OK`.

**Param-spill discipline (CLAUDE.md known trap, Phase-2 binding rule):** before the `tb_compare_pair(...)` call inside the loop, assign each scalar/pointer argument to its own `let` local (`v_i`, `v_best`, `p_i`, `p_best` already are locals) so none is a single-use expression read from an uninitialized spill slot. The skeleton's local layout already satisfies this; Phase 2 must not "inline" any of the four arguments back into the call expression.

## KAT Vectors (>= 3)
Identifiers below are 32-byte little-significant-first byte arrays; only the bytes that drive the comparison are shown (remaining bytes = `0x00`). `ident_cmp` compares byte-0 first (per `identifier.iii`), so `0x01 < 0x02 < 0x03`. All vectors are checked byte-for-byte by `tb_selftest`.

Setup (written into `TB_KAT_IDENTS` / `TB_KAT_VALUES`):
- id0 = `{0x03, 0x00, …}` , value0 = `10u64`
- id1 = `{0x01, 0x00, …}` , value1 = `10u64`
- id2 = `{0x02, 0x00, …}` , value2 = `5u64`

| # | call | expected |
|---|---|---|
| K1 | `tb_min_ident(TB_KAT_IDENTS, 3, &out)` | `out == 1u64` (id1=0x01 is lexicographically smallest), return `TB_OK` |
| K2 | `tb_max_ident(TB_KAT_IDENTS, 3, &out)` | `out == 0u64` (id0=0x03 is largest), return `TB_OK` |
| K3 | `tb_compare_pair(10u64, id0, 10u64, id1)` | `1i32` (values tie at 10 → ident 0x03 > 0x01) |
| K4 | `tb_compare_pair(5u64, id2, 10u64, id0)` | `-1i32` (5 < 10, decided on primary key) |
| K5 | `tb_select_by_u64_then_ident(TB_KAT_VALUES, TB_KAT_IDENTS, 3, &out)` | `out == 2u64` (value2=5 is the unique minimum) |
| K6 | tie-break in select: set value2 = `10u64` so all three values equal, re-run K5 | `out == 1u64` (all values tie at 10 → smallest ident id1=0x01 wins) |
| K7 | `tb_min_ident(0 as *u8 → use a non-null items but) out_index = null` | returns `TB_E_NULL` (-2), `out` untouched — proves the null guard FIRES (negative-case proof per project rule) |
| K8 | `tb_min_ident(items, 0u64, &out)` | returns `TB_E_EMPTY` (-1), `out` untouched — proves the empty guard FIRES |

`tb_selftest` runs K1–K8 in sequence, returning a distinct failure code (`1u64`..`8u64`) at the first mismatch and `99u64` if all pass. (No external/standard crypto vector applies — this is a pure ordering module; the KATs are self-contained and exhaustive over the three rule branches plus both guards.)

## Trap Exposure
- **Trap 1 (multi-line `fn`) — EXPOSED in the gospel body; FIXED.** `tb_select_by_u64_then_ident` is split across two lines in the gospel (`… count: u64,` / `out_index: *u64) -> i32 @export {`). It **must be one physical line**: `fn tb_select_by_u64_then_ident(values: *u64, idents: *u8, count: u64, out_index: *u64) -> i32 @export {`. All other signatures are already single-line. Tree-wide grep found no two-line-signature precedent, confirming this is the required form.
- **Trap 2 (linker-global const) — handled.** `TB_` prefix; verified zero collisions in `STDLIB/`.
- **Trap 3 (signed-ordering SIGSEGV) — NOT exposed.** The only `<`/`>` operators are in `tb_compare_pair` on **`u64`** operands (unsigned). No `i32`/`i64` ordering compare exists; every status `i32` is tested with `== / !=` only (e.g. `c == -1i32`). Safe and confirmed against the `ident_cmp` exemplar idiom.
- **Trap 4 (u32-in-u64 garbage) — NOT exposed.** Every index and stride local (`best`, `i`, `count`, `TB_IDENT_BYTES`) is `u64`; pointer arithmetic `items as u64 + best * TB_IDENT_BYTES` is fully `u64`. No `u32`→`u64` widening feeds any pointer math.
- **Trap 5 (u32 pointer-store width) — NOT exposed.** The module performs **no `u32` stores through a pointer**. `values[i]`/`values[best]` are `u64` *loads*; `*out_index = best` writes a `u64` (full-width, intended). `TB_KAT_*` writes in the self-test are `u8`/`u64` literals into module-scope arrays.
- **Trap 6 / Trap 9 (nested / em-dash block comments) — avoidance noted.** Use only single-level `/* */` (or `//`) and **ASCII `--`** in all comments (the prose tie-break note will read "lower address wins -- earliest issuance", not an em-dash).
- **Trap 7 (local `var` array) — handled.** KAT buffers (`TB_KAT_IDENTS`, `TB_KAT_VALUES`, `TB_KAT_OUT`) declared at module scope; `tb_selftest` is serialized so non-reentrancy is acceptable (noted).
- **Trap 8 (`} else {`) — NOT exposed** (no `else` blocks; the body uses guard-`if`s with early `return`, the preferred shape).
- **Trap 10 (`let mut` checkpoint flag) — NOT exposed.** `best`/`i` are loop accumulators/counters, not boolean checkpoint flags. The guards use early `return` (Trap-10's recommended pattern), not a mutated success flag.
- **Trap 11 (`a % b` after a call) — NOT exposed.** No modulo anywhere.
- **Trap 12 (`@specialize *T` stride) — NOT exposed.** No generics; the element width (32-byte ident, 8-byte `u64`) is a concrete `const`, applied as explicit `u64` arithmetic.
- **Param-spill (CLAUDE.md, not in the 12 but live):** `tb_select_by_u64_then_ident` calls `tb_compare_pair` with four arguments; all four are pre-bound to `let` locals to defeat the single-use-param spill bug. Phase-2 binding rule recorded in the Algorithm section.

## Gap / Fix List
1. **(Trap 1) Two-line signature on `tb_select_by_u64_then_ident`.** *Fix:* collapse to a single physical line (see Trap Exposure / Public API). Load-bearing — leaving it split risks silently wrong stack-offset codegen for all four params, corrupting the very comparator the substrate relies on for canonicality.
2. **Missing `tb_selftest() -> u64` KAT harness.** Every numera sibling (`ident_selftest`, `at_selftest`, `ca_selftest`, …) ships one returning `99u64`; it is the Phase-2 acceptance gate. *Fix:* add `tb_selftest` running K1–K8 (Section "KAT Vectors"), including the two **negative-case** guard proofs (K7 `TB_E_NULL`, K8 `TB_E_EMPTY`) so the guards are shown to FIRE, not merely pass. Add the three module-scope KAT buffers (Trap 7).
3. **Undocumented tie-break rule in all three scans.** The body enforces "equal key → lower index/address wins" purely by using strict `==-1`/`==1` updates, but writes no comment — violating the module's own "no hidden tie breaking" discipline (M-level documentation intent). *Fix:* add an explicit ASCII-comment at each `if c == … { best = i }` line stating the strict-update rationale and the resulting lower-address canonicality. (Behavioral logic is already correct — comment-only change.)
4. **`tb_compare_pair` has no null guard (by design) — make the contract explicit.** It is a leaf comparator called with interior pointers the caller already validated; adding a guard would change its `{-1,0,1}` return type. *Fix (doc, not code):* state in the header comment that `a_ident`/`b_ident` MUST be non-null and that the public, guarded entry points are the `*_ident`/`*_select_*` functions. No code change; recorded so an auditor does not mistake the absent guard for an omission.
5. **Param-spill hardening of the `tb_compare_pair` call site.** *Fix:* keep all four arguments as named `let` locals (already true in the gospel body) and forbid inlining them in Phase 2 (rule recorded in Algorithm §).

Mandate audit summary: **no mandate violated.** M1 (only `identifier.iii`→`keccak256.iii`, hand-rolled scans), M2/W5 (pure integer/byte ops, bit-identical), M3/M4 (exact lexicographic rule, no learning/heuristics), M5 (read-only selection — cannot brick), M7 (R0 honored), M8 (no privileged action → no capability needed; pure leaf utility), M9 (selection is non-mutating, trivially reversible), M15 (compares are total over their bit width), M19 (O(count), bounded). M6/M10/M11/M12/M16–M18/M20 are N/A to a pure ordering primitive (no witness emission, no synthesis, no proof terms, no memoization, no self-reflection) — stated for completeness so the scheduler sees the closure is intentional, not overlooked.

## Implementation Skeleton
```iii
/* III/STDLIB/iii/numera/tiebreak.iii
 *
 * III STDLIB - numera::tiebreak
 *
 * Deterministic tie-breaking primitives. Used wherever an algorithm must
 * select one canonical candidate from a set of equivalent candidates.
 *
 * Canonical rule (public, never hidden):
 *   1. primary u64 key, ascending (smallest wins for *_min / *_select)
 *   2. then lexicographic 256-bit identifier (via ident_cmp)
 *   3. then lowest first-issued arena address -- realized structurally by
 *      scanning ascending indices over a contiguous block and updating
 *      best ONLY on a STRICT improvement, so on a tie the lower index
 *      (= lower address) stays canonical.
 *
 * Public API:
 *   tb_min_ident(items, count, out_index) -> i32
 *   tb_max_ident(items, count, out_index) -> i32
 *   tb_compare_pair(a_val, a_ident, b_val, b_ident) -> i32   // {-1,0,1}; idents MUST be non-null
 *   tb_select_by_u64_then_ident(values, idents, count, out_index) -> i32
 *   tb_selftest() -> u64                                     // 99 = pass
 *
 * Hexad: kind_essence.  Ring: R0.  K: 1.00.
 * NIH: depends only on identifier.iii.
 * Discipline: W2 (<=4 params), W13 (<=20 locals), W14 (sentinel loops),
 *   W9 (negative-i32 errors), W11 (i32 compared by == / != only).
 */

module numera_tiebreak

extern @abi(c-msvc-x64) fn ident_cmp(a: *u8, b: *u8) -> i32 from "identifier.iii"

const TB_OK          : i32 =  0i32
const TB_E_EMPTY     : i32 = -1i32
const TB_E_NULL      : i32 = -2i32
const TB_IDENT_BYTES : u64 = 32u64

var TB_KAT_IDENTS : [u8; 96]    /* 3 x 32-byte identifiers for the self-test */
var TB_KAT_VALUES : [u64; 3]    /* 3 primary u64 keys paired with TB_KAT_IDENTS */
var TB_KAT_OUT    : [u64; 1]    /* out_index receiver for the self-test calls  */

fn tb_min_ident(items: *u8, count: u64, out_index: *u64) -> i32 @export {
    // TODO: body per Algorithm §tb_min_ident -- null/empty guards (out_index,count,items),
    //       u64 linear min scan, ident_cmp, STRICT `if c == -1i32 { best = i }` (tie -> lower addr).
}

fn tb_max_ident(items: *u8, count: u64, out_index: *u64) -> i32 @export {
    // TODO: body per Algorithm §tb_max_ident -- as tb_min_ident, STRICT `if c == 1i32 { best = i }`.
}

fn tb_compare_pair(a_val: u64, a_ident: *u8, b_val: u64, b_ident: *u8) -> i32 @export {
    // TODO: body per Algorithm §tb_compare_pair -- unsigned u64 `<`/`>` on a_val/b_val,
    //       else return ident_cmp(a_ident, b_ident).  No null guard (leaf comparator).
}

fn tb_select_by_u64_then_ident(values: *u64, idents: *u8, count: u64, out_index: *u64) -> i32 @export {
    // TODO: body per Algorithm §tb_select_by_u64_then_ident -- null/empty guards
    //       (out_index,count,values,idents), u64 scan, load v_i/v_best, compute p_i/p_best,
    //       c = tb_compare_pair(v_i, p_i, v_best, p_best) [all four args bound to locals -- param-spill],
    //       STRICT `if c == -1i32 { best = i }`.
}

fn tb_selftest() -> u64 @export {
    // TODO: body per KAT Vectors §K1..K8 --
    //   load id0={0x03..} v=10, id1={0x01..} v=10, id2={0x02..} v=5 into TB_KAT_*;
    //   K1 min -> 1, K2 max -> 0, K3 compare_pair(10,id0,10,id1) -> 1,
    //   K4 compare_pair(5,id2,10,id0) -> -1, K5 select -> 2,
    //   K6 set value2=10 then select -> 1, K7 null out_index -> TB_E_NULL,
    //   K8 count==0 -> TB_E_EMPTY; return numbered failure 1..8 on mismatch, else 99u64.
}
```
