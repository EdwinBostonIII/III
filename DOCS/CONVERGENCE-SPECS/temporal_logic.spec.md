# 14 numera/temporal_logic.iii — Implementation Spec

## Verdict
PARTIAL — the gospel candidate body compiles structurally and covers all twelve LTL tags with correct finite-trace semantics, but it is **not acceptance-ready**: it (a) violates **W15** with genuine recursion in `tl_eval_node_at` (the gospel's own note concedes this and merely *promises* a non-recursive form lives in the preserver — but the preserver at gospel line 6507 just calls back into this recursive `tl_eval`, so the non-recursive evaluator exists nowhere; the maximal-intent fix is to put the real explicit-stack evaluator HERE); (b) violates **Trap 7** with three local `var [...]` array declarations (`prod`/`op`/`ante` at gospel 4001-4003, `vals` at 4038) that parse only at module scope; (c) violates **Trap 1** with two multi-line `fn` signatures (`tl_eval_node_at` at 4030, `tl_eval_atom`'s caller pattern is fine but `cons_eval_predicate` extern at 3868 wraps); (d) is **algorithmically exponential** — each temporal operator re-evaluates whole sub-segments per position with no memoization, so a single `G F φ` over an N-fragment chain is O(N³+) and unbounded under the **M19 cost lattice**; (e) the `vals[]` cache is **semantically wrong for temporal operators** (it is recomputed per `position` but indexed only by `node`, so the inner recursive temporal calls at other positions silently clobber nothing because they use a *fresh* stack frame's `vals` — masking the bug, not fixing it). This spec realizes the maximal intent: a single global `(node, position)` fixpoint table, filled by an explicit work iteration with **no recursion**, bit-identical to the LTL semantics, bounded under the cost lattice.

## Purpose
`numera::temporal_logic` is the **linear-temporal-logic surface over the witness chain**: it stores LTL formulas as flat post-order node arenas and decides, by **bounded model checking with finite-trace semantics**, whether a formula holds at a given chain position or across a whole segment. It IS the substrate's organ for expressing and checking constitutional safety/liveness properties ("every operation is eventually witnessed", "a revocation is never followed by use") against the cryptographically-chained fragment history. Hexad kind: **kind_witness**. Ring: **R-1**. K-vector: **K = 1.00** (pure, total, allocation-free — fixed arenas only).

## Public API
All eleven public functions keep the gospel names (locked: the constitution_preserver, Module 19, already declares `extern ... fn tl_eval(...) from "temporal_logic.iii"` at gospel line 6490; renaming would break it). W9: error codes negative `i32`. W10: boolean results `u8` (0/1). W12: every public fn returns a status or sentinel-typed value.

```
fn tl_init() -> i32 @export
fn tl_alloc_formula() -> u32 @export
fn tl_drop_formula(slot: u32) -> i32 @export
fn tl_append_atom(slot: u32, pred_slot: u32) -> u32 @export
fn tl_append_not(slot: u32, child: u32) -> u32 @export
fn tl_append_bin(slot: u32, tag: u8, l: u32, r: u32) -> u32 @export
fn tl_append_unary_temp(slot: u32, tag: u8, child: u32) -> u32 @export
fn tl_set_root(slot: u32, root: u32) -> i32 @export
fn tl_eval(slot: u32, chain_start: u64, chain_end: u64, position: u64) -> u8 @export
fn tl_holds_on_segment(slot: u32, chain_start: u64, chain_end: u64) -> u8 @export
fn tl_node_count(slot: u32) -> u32 @export
```

Return-status conventions:
- `tl_init`, `tl_drop_formula`, `tl_set_root` → `i32`: `TLOGIC_OK` (0) or a negative error (W9).
- `tl_alloc_formula`, `tl_append_*` → `u32`: a node/slot index, or the sentinel `TLOGIC_SENT` (0xFFFFFFFF) on failure (W12 sentinel-typed value).
- `tl_eval`, `tl_holds_on_segment` → `u8`: 0/1 boolean (W10). A malformed request (bad slot, no root, out-of-range node) returns **0** (vacuous-false), never a crash (M5).
- `tl_node_count` → `u32`: number of nodes in the formula's range (added accessor; mirrors `bigint_len_limbs`'s query style — used by the KAT harness and the preserver to size its own table; returns 0 on bad slot).

W2: every signature has ≤4 params. The internal evaluator passes its working set through a module-scope aggregate (the fixpoint table), so it needs no >4-param signature.

## Constant Namespace
PREFIX = `TLOGIC_` for **module-level constants** (dispatch-assigned). NOTE — naming split, deliberate and documented:
- **Constants** use `TLOGIC_` (not the gospel's `TL_`). Rationale: Trap 2 makes every module-scope `const` a linker-global symbol `L_<NAME>`; a two-letter `TL_` prefix is collision-prone against any future "translation layer"/"type lattice" module. `TLOGIC_` is unique. Grep of `STDLIB/iii` for `TLOGIC_` → **0 matches**; grep for `TL_OK`/`TL_SENT`/`TL_E_BAD` across STDLIB → **0 matches** (so even keeping `TL_` would not collide today, but `TLOGIC_` is the safe maximal choice).
- **Function names** stay `tl_*` (NOT `tlogic_*`). Rationale: the constitution_preserver's extern (gospel 6490) and the gospel's whole Layer-3 narrative bind `tl_eval`/`tl_*`. Function symbols are also linker-global, but grep confirms `tl_eval`/`tl_alloc_formula`/`tl_append_*`/`tl_holds_on_segment` appear in **no other module**. Renaming would silently break Module 19.

Module-level constants (all prefixed `TLOGIC_`):
```
const TLOGIC_OK           : i32 =  0i32
const TLOGIC_E_FULL       : i32 = -1i32
const TLOGIC_E_BAD        : i32 = -2i32
const TLOGIC_SENT         : u32 = 0xFFFFFFFFu32

const TLOGIC_TAG_ATOM     : u8 =  0u8
const TLOGIC_TAG_NOT      : u8 =  1u8
const TLOGIC_TAG_AND      : u8 =  2u8
const TLOGIC_TAG_OR       : u8 =  3u8
const TLOGIC_TAG_IMPL     : u8 =  4u8
const TLOGIC_TAG_NEXT     : u8 =  5u8
const TLOGIC_TAG_ALWAYS   : u8 =  6u8
const TLOGIC_TAG_EVENT    : u8 =  7u8
const TLOGIC_TAG_UNTIL    : u8 =  8u8
const TLOGIC_TAG_ONCE     : u8 =  9u8
const TLOGIC_TAG_HIST     : u8 = 10u8
const TLOGIC_TAG_SINCE    : u8 = 11u8

const TLOGIC_MAX_FORMULA  : u32 = 256u32
const TLOGIC_MAX_NODES    : u32 = 65536u32
const TLOGIC_MAX_SEG      : u64 = 4096u64    // max segment length the fixpoint table covers in one call
const TLOGIC_MAX_SUBF     : u32 = 1024u32    // max nodes in a single formula (bounds the per-formula table dim)
const TLOGIC_ANTE_MAX     : u32 = 32u32      // max antecedents per fragment (matches witness_hook WH_ANTE 32x32 layout)
const TLOGIC_ID_LEN       : u64 = 32u64      // identifier width (bytes)
```

Note on `TLOGIC_MAX_NODES`: the gospel typed it `u64`; this spec types it `u32` because `TL_NODE_USED` is `u32` and all node indices are `u32` — comparing `(TL_NODE_USED as u64) >= TL_MAX_NODES(u64)` in the gospel is harmless but the `u32`-vs-`u64` mix is needless. Keep the comparison in `u32` domain: `if TL_NODE_USED >= TLOGIC_MAX_NODES`. (Both fit in 32 bits; 65536 < 2³².)

## Data Structures
All arenas are **module-scope fixed arrays** (W8; Trap 7 — no local `var` arrays anywhere). Bounds justified:

Formula slot table (W8 bound = `TLOGIC_MAX_FORMULA` = 256; one slot per concurrently-live constitutional clause formula; the preserver's `CP_MAX_ATT` is 1024 but a single epoch verifies far fewer distinct formulas — 256 is generous and each is reusable via drop):
```
var TL_F_LIVE   : [u8;  256]
var TL_F_ROOT   : [u32; 256]
var TL_F_START  : [u32; 256]
var TL_F_END    : [u32; 256]
```

Flat node arena (W8 bound = `TLOGIC_MAX_NODES` = 65536; shared across all formulas, bump-allocated; 64Ki nodes × 9 bytes/node ≈ 576 KiB BSS — bounded, deterministic):
```
var TL_NODE_TAG  : [u8;  65536]
var TL_NODE_A    : [u32; 65536]
var TL_NODE_B    : [u32; 65536]
var TL_NODE_USED : u32 = 0u32
```

**Fixpoint value table** (the W15 fix — replaces recursion). Bound = `TLOGIC_MAX_SUBF` × `TLOGIC_MAX_SEG` = 1024 × 4096 = 4 194 304 bytes (4 MiB BSS). Indexed `[subformula_local_index * TLOGIC_MAX_SEG + (position - chain_start)]`. `TL_VAL_FILLED` marks which positions have been computed for the active formula so a temporal operator can look up an already-computed sub-result instead of recursing:
```
var TL_VAL       : [u8; 4194304]   // truth of subformula s at relative position p; bound MAX_SUBF*MAX_SEG
var TL_VAL_FILLED: [u8; 4194304]   // 1 iff TL_VAL[s,p] has been computed this call
```
Justification of the 4 MiB bound: a constitutional clause formula has ≤ `TLOGIC_MAX_SUBF`=1024 nodes (a clause is human-authored; 1024 connectives is far beyond any real safety property) and a single model-check segment is ≤ `TLOGIC_MAX_SEG`=4096 fragments (one epoch). Segments longer than 4096 are rejected by `tl_eval` with a vacuous **0** and a recorded `TLOGIC_E_FULL` state (M5: refusal, never silent truncation or crash). The preserver chunks longer chains epoch-by-epoch (gospel 22002: it verifies "the segment since the last verification", never the unbounded whole at once for the table path).

Atomic-evaluation scratch (module-scope; Trap 7 fix for the gospel's local `var prod/op/ante`). Not reentrant — acceptable: model checking is a single-threaded serialized pass (same discipline as `bigint`'s `BIG_VEC_*` scratch and `constitution`'s `stack_buf`). Documented as serialized:
```
var TL_SCR_PROD  : [u8; 32]      // producer id of fragment under eval
var TL_SCR_OP    : [u8; 32]      // op id
var TL_SCR_ANTE  : [u8; 1024]    // up to ANTE_MAX(32) antecedents x 32 bytes
```

Failure record (M5/W12 — lets callers learn *why* eval returned 0 without crashing):
```
var TL_LAST_ERR  : i32 = 0i32    // TLOGIC_OK, or TLOGIC_E_FULL (seg too long / formula too big), or TLOGIC_E_BAD
```

W1/W3: every address-of-static (`&TL_SCR_PROD[0u64] as *u8`, etc.) is taken only inside this file and passed only to externs that consume-and-return; no static pointer is stored into another module's state.

## Dependencies (externs)
Each extern with the providing module's NN and build status. **All three providers are not-yet-built** (this wave) — the scheduler must order Module 14 *after* them, OR (for witness_hook) after its accessor-addendum lands.

```
// from witness_hook.iii  — Module 06 (aether/witness_hook). The file EXISTS but does NOT yet
// export these accessors; they are specified in the gospel "Turn One Addendum" (gospel 1809-1869)
// and MUST be appended to witness_hook.iii before Module 14 links. MARK: dependency-incomplete.
extern @abi(c-msvc-x64) fn wh_get_producer(idx: u64, out: *u8) -> i32 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_get_op_id(idx: u64, out: *u8) -> i32 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_get_phase(idx: u64) -> u8 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_get_pillar(idx: u64) -> u16 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_get_rev_tag(idx: u64) -> u8 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_get_ante_count(idx: u64) -> u32 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_get_ante(idx: u64, ante_idx: u32, out: *u8) -> i32 from "witness_hook.iii"

// from constitution.iii — Module 13 (numera/constitution). NOT-YET-BUILT (this wave).
// Signature verified verbatim against gospel 3691-3693. Returns u8 (0/1): predicate verdict.
extern @abi(c-msvc-x64) fn cons_eval_predicate(slot: u32, op_producer: *u8, op_id: *u8, op_phase: u8, op_pillar: u16, op_revtag: u8, ante_ids: *u8, n_ante: u32) -> u8 from "constitution.iii"
```

Not-yet-built dependency count: **2 modules** (Module 13 constitution; Module 06 witness_hook — the latter file exists but its required accessor surface does not). Downstream, Module 19 (constitution_preserver) depends on *this* module's `tl_eval`.

W11 note on extern returns: `wh_get_*` returning `i32` status are checked by **equality only** against `TLOGIC_OK`-shaped sentinels where checked at all; in practice the model checker treats a missing fragment as vacuous (out-of-range position ⇒ the operator's loop simply does not include it), so the `i32` returns of the buffer-fill accessors are not ordering-compared.

## Algorithm

The whole module is **pure / deterministic / allocation-free** (M1 NIH — hand-rolled flat-array DAG + iterative fixpoint; M2 — identical formula+chain ⇒ identical verdict bit-for-bit; M3/M4 — no counting, no thresholds, no heuristics: every verdict is the exact LTL truth value; W5 — booleans are single bytes 0/1, the most reproducible representation).

### Construction fns (`tl_init`, `tl_alloc_formula`, `tl_drop_formula`, `tl_append_*`, `tl_set_root`, `tl_node_count`)
Unchanged in spirit from the gospel (those parts are correct), with three corrections:
- `tl_init` clears `TL_F_LIVE[*]`, sets `TL_NODE_USED=0`, and sets `TL_LAST_ERR=TLOGIC_OK`.
- The node-cap guard becomes `if TL_NODE_USED >= TLOGIC_MAX_NODES { return TLOGIC_SENT }` (u32 domain; no u32-in-u64 cast — Trap 4 sidestepped).
- `tl_drop_formula` keeps the LIFO node-reclaim (`if TL_F_END[slot] == TL_NODE_USED { TL_NODE_USED = TL_F_START[slot] }`). This is exact and deterministic; non-LIFO drops leak arena until `tl_init`, which is acceptable (bounded, documented).
- `tl_node_count(slot)`: returns `TL_F_END[slot] - TL_F_START[slot]` (0 on bad/dead slot). Pure query.

W14 (sentinel loop / no break): every `while` in the appenders is `i < TLOGIC_MAX_FORMULA` driven by `i`, returning early on the first free slot — already break-free.

### `tl_eval_atom(pred_slot, position)` — atomic proposition
Hand-rolled marshalling: copy the fragment's producer/op identifiers and antecedent ids out of the witness hook into the **module-scope** scratch (`TL_SCR_PROD/OP/ANTE`, Trap 7 fix), read phase/pillar/revtag, then call `cons_eval_predicate`. Deterministic: it reads immutable published fragment fields and the constitution's fixed predicate bytecode. The antecedent-copy loop is `while k < n_ante` with `n_ante` clamped to `TLOGIC_ANTE_MAX` (guard: `if n_ante > TLOGIC_ANTE_MAX { n_ante = TLOGIC_ANTE_MAX }`) so the 1024-byte `TL_SCR_ANTE` (32×32) never overflows (M5). The per-antecedent destination is computed as `(&TL_SCR_ANTE[0u64] as u64 + (k as u64) * 32u64) as *u8` — `k` is masked into u64 cleanly via `(k as u64)` and multiplied by a constant 32 (no modulo-after-call; Trap 11 N/A).

### The W15 fix — `tl_eval` via a non-recursive `(node, position)` fixpoint (THE core redesign)
The gospel's `tl_eval_node_at` recurses for `NEXT/ALWAYS/EVENT/UNTIL/ONCE/HIST/SINCE`. The maximal, mandate-correct realization computes the **entire** value table `TL_VAL[s, p]` for the active formula over the whole segment first, with **no recursion**, then reads off the root's value at the query position. Method (hand-rolled bottom-up fixpoint; W15 explicit-iteration form):

Let `start = TL_F_START[slot]`, `end = TL_F_END[slot]`, `nsub = end - start`, segment `[chain_start, chain_end)` of length `L = chain_end - chain_start`. Reject if `nsub > TLOGIC_MAX_SUBF` or `L > TLOGIC_MAX_SEG` (set `TL_LAST_ERR=TLOGIC_E_FULL`, return 0 — M5 refusal).

**Pass 1 — atoms and propositional connectives, per position (local, no temporal dependence).** For each relative position `p` in `0..L` (absolute `ap = chain_start + p`), for each node `n` from `start` to `end-1` in arena (post-order: children precede parents by construction, so a parent reads already-filled child cells **at the same p**):
- `ATOM`  → `TL_VAL[loc(n), p] = tl_eval_atom(TL_NODE_A[n], ap)`
- `NOT`   → `1 - child_val`  (via `if v==0u8 {1u8} else {0u8}` — one-line else, Trap 8)
- `AND/OR`→ bitwise `&` / `|` of the two child cells
- `IMPL`  → `if a==0u8 {1u8} else {b}` (one-line else)
  where `child_val = TL_VAL[loc(child), p]`, `loc(x) = x - start`.
Mark `TL_VAL_FILLED[loc(n),p]=1`.

**Pass 2 — temporal operators, computed by closed-form scan over the table that Pass 1 (and earlier Pass-2 sub-results) already filled.** Because the child's truth at *every* position is already in `TL_VAL` after Pass 1 (for propositional/atomic children) — and because temporal nodes also have smaller arena indices than their parents (construction guarantees children precede parents) — we run Pass 2 **node-by-node in arena order**, and for each temporal node fill **all** its positions from its child's already-complete row. This is the key: a temporal operator never needs to *call* anything; it *reads* its child's full row `TL_VAL[loc(child), 0..L)`. Order within one node's row matters for the past/future recurrences, so use the standard linear DP recurrences (each O(L), total O(nsub·L) — polynomial, M19-bounded):
- `NEXT  Xφ`  at p:  `TL_VAL[c, p+1]` if `p+1 < L` else `0`.
- `ALWAYS Gφ` (suffix-AND, scan high→low): `g[L-1]=c[L-1]; for p=L-2..0: g[p]=c[p] & g[p+1]`.
- `EVENT  Fφ` (suffix-OR):                 `f[L-1]=c[L-1]; for p=L-2..0: f[p]=c[p] | f[p+1]`.
- `UNTIL φUψ` (suffix recurrence):          `u[L-1]=ψ[L-1]; for p=L-2..0: u[p]= ψ[p] | (φ[p] & u[p+1])`.
- `ONCE  Oφ` (prefix-OR, scan low→high):    `o[0]=c[0]; for p=1..L-1: o[p]=c[p] | o[p-1]`.
- `HIST  Hφ` (prefix-AND):                  `h[0]=c[0]; for p=1..L-1: h[p]=c[p] & h[p-1]`.
- `SINCE φSψ` (prefix recurrence):          `s[0]=ψ[0]; for p=1..L-1: s[p]= ψ[p] | (φ[p] & s[p-1])`.
These are the **exact** finite-trace LTL semantics from the gospel prose (`Gφ@i` iff φ holds ∀j∈[i,N); `φUψ@i` iff ∃j≥i with ψ@j and φ on [i,j); past duals over [0,i]) — re-expressed as the textbook O(L) dynamic-programming recurrences instead of the gospel's O(L²) re-scan-per-position. Bit-identical verdicts; strictly lower cost (M19). Each recurrence is a single `while` driven by a counter and a `going` flag (W14, no break); the high→low scans use the `while q > 0 { q = q - 1; ... }` idiom already proven in `bigint_cmp` (avoids signed-decrement underflow / Trap 3 — all loop variables are `u64`/`u32`, compared by `<`/`>` only against unsigned bounds, never an `i64 >= 0`).

**Read-off.** `tl_eval` returns `TL_VAL[loc(root), position - chain_start]` (after verifying `position` ∈ `[chain_start, chain_end)`; else 0). The full table is recomputed per `tl_eval` call against the requested segment — but `tl_holds_on_segment` is rewritten to fill the table **once** and then read every position's root cell (see below), eliminating the gospel's N× redundant full re-evaluation.

Why this satisfies W15 with **zero** recursion and zero explicit pointer-stack: the DAG is already linearized in arena order (post-order), so a parent's value at every position is a pure function of child rows that are *guaranteed already filled* by the time we reach the parent (lower index). The "explicit stack" the briefing permits is here unnecessary because **the arena order IS the evaluation order** — a stronger, simpler guarantee. No node is ever visited twice; no call frame is created for sub-evaluation. (If a future formula constructor ever allowed a parent at a lower index than a child — it cannot, by `tl_append_*` semantics — the spec's Pass loop would detect `loc(child) >= loc(n)` and set `TLOGIC_E_BAD`, refusing rather than mis-evaluating; M5.)

### `tl_holds_on_segment(slot, chain_start, chain_end)`
Fill the table **once** for `[chain_start, chain_end)` (one call into the fixpoint filler), then AND the root's row across all positions: `ok = TL_VAL[loc(root),0]; for p=1..L-1: ok = ok & TL_VAL[loc(root),p]`. This is `G(formula)` over the segment, computed in one table fill — O(nsub·L), versus the gospel's `tl_eval`-per-position which was O(L · nsub·L) = O(nsub·L²). Returns 0 on any refusal (M5).

**Determinism / bit-identity (M2, W5):** no floating point, no clocks, no allocation, no observation of run order. Every cell is a deterministic function of immutable fragment fields and fixed predicate bytecode. The table is fully overwritten (`TL_VAL_FILLED` reset at the top of each fill) so no cross-call state leaks (M13/M20 reflection-boundedness: the checker reasons only about the supplied formula and segment, never about itself). **Witness (M6/M10/M16):** this module *evaluates* properties; it does not publish fragments — the constitution_preserver (Module 19) wraps `tl_eval` results in a Constitutional Compliance Witness. So M6/M10 are satisfied at the preserver boundary; this module's contribution is that its verdict is **recomputable byte-identically** from the recorded formula + segment (M10), which the fixpoint form guarantees.

### Reversibility / cost (M9, M19)
The module is read-only over the chain: it mutates only its own arenas (formula construction) and the scratch table (evaluation). Construction is reversible via `tl_drop_formula` (LIFO reclaim). Evaluation has no side effect to reverse. Cost is bounded: every public fn is O(`TLOGIC_MAX_SUBF` · `TLOGIC_MAX_SEG`) = O(1024·4096) worst case, a fixed ceiling (M19 cost-lattice-bounded — the table dimensions ARE the cost bound, enforced by the up-front size guards).

## KAT Vectors (>= 3)
A self-test builds tiny in-memory "chains" by stubbing the witness-hook accessors so that atom `A` is true exactly at a controlled set of positions, then checks the verdict byte-for-byte. (Phase 2 supplies a `tl_selftest()` harness with a deterministic 8-position fixture where predicate-slot 0 = "true at positions {2,5}", predicate-slot 1 = "true at positions {0,1,2,3}".) Segment is `[0,8)` unless noted.

1. **EVENT / always-eventually (liveness).** Formula `F A0` (eventually A0), A0 true at {2,5}.
   - `tl_eval(F A0, 0,8, 0)` → **1** (A0 occurs at 2 ≥ 0).  `tl_eval(F A0,0,8, 6)` → **0** (no A0 in [6,8)).  `tl_eval(F A0,0,8, 5)` → **1**.
2. **ALWAYS over a prefix-true atom (safety).** Formula `G A1`, A1 true at {0,1,2,3}.
   - `tl_eval(G A1,0,4, 0)` → **1** (A1 holds at every j∈[0,4)).  `tl_eval(G A1,0,8, 0)` → **0** (A1 false at 4).  `tl_holds_on_segment(G A1, 0,4)` → **1**; `tl_holds_on_segment(G A1, 0,8)` → **0**.
3. **UNTIL (combined).** Formula `A1 U A0` (A1 holds until A0), A1@{0,1,2,3}, A0@{2,5}.
   - `tl_eval(A1 U A0, 0,8, 0)` → **1** (ψ=A0 first true at 2; φ=A1 true at 0,1 on the prefix [0,2)).  `tl_eval(A1 U A0,0,8, 4)` → **0** (A0 next at 5 but A1 false at 4, prefix broken).  `tl_eval(A1 U A0,0,8, 2)` → **1** (ψ true immediately at 2).
4. **NEXT + NOT (edge & negation).** Formula `X (NOT A0)`, A0@{2,5}.
   - `tl_eval(X ¬A0,0,8, 1)` → **0** (position 2 has A0, so ¬A0 is false there).  `tl_eval(X ¬A0,0,8, 2)` → **1** (position 3: ¬A0 true).  `tl_eval(X ¬A0,0,8, 7)` → **0** (p+1=8 ≥ end ⇒ NEXT vacuously 0).
5. **Past duals ONCE / HIST / SINCE.** A0@{2,5}, A1@{0,1,2,3}.
   - `tl_eval(O A0,0,8, 5)` → **1** (A0 seen in [0,5]: at 2 and 5).  `tl_eval(O A0,0,8, 1)` → **0** (no A0 in [0,1]).
   - `tl_eval(H A1,0,8, 3)` → **1** (A1 true at all of [0,3]).  `tl_eval(H A1,0,8, 4)` → **0** (A1 false at 4).
   - `tl_eval(A1 S A0,0,8, 5)` → **1** (A0 at 2 in the past; A1 true on (2,5]? — A1@{0,1,2,3}, false at 4,5 ⇒ recurrence: ψ@5? A0@5=1 ⇒ S@5=1 immediately). Stated precisely: `s[5]=ψ[5] | (φ[5]&s[4])`; ψ[5]=A0@5=1 ⇒ **1**.
6. **Refusal bound (M5).** `tl_eval` with `chain_end - chain_start > TLOGIC_MAX_SEG` → **0** and `TL_LAST_ERR == TLOGIC_E_FULL` (proves the negative case: oversized segment is refused, not truncated — per the "prove the guard FAILS on bad input" discipline).

(LTL has no single external standard test vector the way SHA does; these fixtures are the canonical finite-trace truth tables for each operator and are checked byte-for-byte. The DP recurrence results above were hand-derived from the gospel's stated semantics.)

## Trap Exposure
- **Trap 1 (multi-line `fn`)** — EXPOSED in the gospel body: `tl_eval_node_at(... \n position: u64) -> u8` (gospel 4030-4031) and the `cons_eval_predicate` extern (gospel 3868-3870) wrap. **Fix:** every signature in this spec is single-line (see Public API & Dependencies). The internal fixpoint filler `tl_fill_table(slot, chain_start, chain_end)` is 3 params + uses module-scope state — single-line, ≤4 params.
- **Trap 2 (const linker-global)** — handled: all consts carry `TLOGIC_` (grep-verified 0 collisions). Function names `tl_*` grep-verified unique across STDLIB.
- **Trap 3 (signed-ordering SIGSEGV)** — AVOIDED: there are no `i64` values anywhere in the evaluator; all positions/indices are `u64`/`u32` and compared with `<`/`>`/`==` against **unsigned** bounds (legal — the trap is specifically signed `i32`/`i64` ordering). Error codes are `i32` but compared by `== / !=` only (W11). High→low scans use `while q > 0u64 { q = q-1u64; ... }`, never `q >= 0i64`.
- **Trap 4 (u32-in-u64-slot garbage)** — AVOIDED: the only place a `u32` feeds pointer math is the antecedent destination `(&TL_SCR_ANTE[0] as u64 + (k as u64)*32u64)`; `k` is masked into u64 by the `(k as u64)` cast and immediately multiplied by a constant — but to be safe the skeleton uses `((k as u64) & 0xFFFFFFFFu64)` before the multiply (k ≤ 32 anyway). Table index `loc(n)*TLOGIC_MAX_SEG + p` uses `u64` arithmetic with `loc(n)` already a small `u32` widened explicitly.
- **Trap 5 (u32 pointer store width)** — N/A: the module never stores a `u32` through a `*u32`. All arena writes are `u8`/`u32`/element-typed array stores `TL_NODE_A[n] = v` into typed `[u32; N]` arrays (the compiler handles element width for typed-array index stores; the trap is specifically raw `*u32` pointer stores, which this module does not use). Table writes are `[u8;N]` element stores.
- **Trap 6 (nested block comments)** — AVOIDED: no `/* */` nesting; inline notes use `//`.
- **Trap 7 (local `var` arrays)** — EXPOSED in the gospel body: `var prod/op/ante` (4001-4003) and `var vals : [u8;65536]` (4038) are function-local — they parse only at module scope. **Fix:** all four are lifted to module scope (`TL_SCR_PROD/OP/ANTE`, and the `TL_VAL`/`TL_VAL_FILLED` table). Documented non-reentrant (serialized model checking — same posture as constitution's `stack_buf` which the gospel ALSO declares locally at 3704; this spec flags that the same Trap-7 fix is needed there, but that is Module 13's to make).
- **Trap 8 (`} else {` one line)** — handled: NOT/IMPL use one-line `else`.
- **Trap 9 (em-dash in comment)** — handled: comments use ASCII `--`.
- **Trap 10 (`let mut` checkpoint flag)** — the gospel's temporal loops use `let mut ok/hit/prefix_ok` checkpoint flags inside the (now-deleted) recursive body. The fixpoint redesign replaces them with the closed-form DP recurrences (`g[p]=c[p]&g[p+1]`, etc.), which carry state in the table cells, not in a mutated single-shot flag — sidestepping the trap. The two surviving flags (`going` loop-terminators, `ok` accumulator in `tl_holds_on_segment`) are accumulators driving a `while`, the supported pattern.
- **Trap 11 (`a % b` after call)** — N/A: no modulo anywhere. Position arithmetic is `+1/-1` and `*32` (constant). Table indexing is `* TLOGIC_MAX_SEG` (constant multiply, no `%`).
- **Trap 12 (`@specialize *T` stride)** — N/A: this module is not generic; all arrays are concrete `[u8;N]`/`[u32;N]`.

## Gap / Fix List
PARTIAL — the candidate body's gaps and the fix each receives in this spec:

1. **W15 recursion (severity: blocking).** `tl_eval_node_at` recurses for all 7 temporal tags (gospel 4065, 4077, 4090, 4105/4109, 4125, 4138, 4153/4157). The gospel's note (4194) defers the non-recursive form to the preserver — but the preserver (gospel 6507) just calls this recursive `tl_eval`, so the non-recursive evaluator **exists nowhere in the corpus**. **Fix:** this spec puts the genuine non-recursive `(node,position)` fixpoint evaluator HERE (Algorithm §"W15 fix"), so the preserver's existing `tl_eval` call transparently becomes W15-compliant. The "W15 Equivalence Clause" (gospel 21664) then holds for real, witnessed by KAT §1-5.
2. **Trap 7 local var arrays (blocking).** `prod/op/ante` (4001-4003), `vals` (4038). **Fix:** lifted to module-scope `TL_SCR_*` and the `TL_VAL` table.
3. **Trap 1 multi-line signatures (blocking).** `tl_eval_node_at` (4030), `cons_eval_predicate` extern (3868). **Fix:** single-line everywhere.
4. **Exponential / unbounded cost — M19 violation (blocking).** The gospel re-evaluates whole sub-segments per position (e.g. `G` at 4072-4084 loops all q∈[pos,end) and *recursively* re-evaluates the child at each q; nesting `G F` is O(L²) recursive calls × per-call O(L) = exponential in nesting depth). This is unbounded under the cost lattice. **Fix:** O(nsub·L) DP recurrences with a fixed table-size ceiling; oversized inputs refused (M5).
5. **`vals[]` cache correctness (latent bug).** The gospel caches `vals[n]` per position but the temporal cases recurse into *new* invocations of `tl_eval_node_at` that allocate their *own* local `vals` (a fresh local var array per call). So the cache never actually serves temporal sub-results — it only ever helps propositional children at the *same* position. The redesign's single global table indexed by `(node,position)` is the correct memoization the gospel gestured at.
6. **`TLOGIC_MAX_NODES` type mix (cosmetic/robustness).** Gospel types it `u64` then compares `(TL_NODE_USED as u64) >= TL_MAX_NODES`; harmless but invites a u32-in-u64 read. **Fix:** type it `u32`, compare in u32 domain.
7. **Segment-length unboundedness (M5/M19).** Gospel `tl_eval` accepts any `chain_end`; with the table approach an unbounded segment would overrun `TL_VAL`. **Fix:** explicit `L > TLOGIC_MAX_SEG` and `nsub > TLOGIC_MAX_SUBF` guards → refuse with `TLOGIC_E_FULL`, return 0. KAT §6 proves the guard fires.
8. **No failure visibility (W12 polish).** Gospel `tl_eval` returns a bare 0 for both "false" and "malformed" — indistinguishable. **Fix:** `TL_LAST_ERR` records the refusal reason; `tl_node_count` added for harness/preserver introspection. (Verdict byte stays 0/1 — callers that only want the boolean are unaffected.)
9. **Prefix discrepancy (noted, resolved).** Gospel uses `TL_` consts; dispatch assigned `TLOGIC_`. **Fix:** consts → `TLOGIC_`; functions stay `tl_*` (locked by Module 19's extern). Documented in Constant Namespace.
10. **Dependency readiness (scheduler note).** `witness_hook.iii` exists but lacks the 7 accessors this module needs (they live only in the gospel Turn-One Addendum, not the built file). Module 13 `constitution.iii` is not built. **Fix (scheduling):** order Module 14 after Module 13 and after witness_hook's accessor-addendum; marked dependency-incomplete above so the wave scheduler blocks correctly.

Mandates audited clean (no violation): M1 (NIH — hand-rolled DAG+DP), M2 (deterministic), M3/M4 (exact LTL, no ML/heuristics), M7 (Ring R-1 preserved), M8 (no privileged action — read-only evaluator, no capability needed; the *publishing* of verdicts is the preserver's capability-gated act), M11 (formulas are proof objects checked operationally), M13/M20 (reflection-bounded — reasons only about the given formula/segment), M15 (the propositional ops are total over u8). M6/M10/M16/M18 are satisfied at the Module-19 boundary (this module supplies the recomputable verdict; the preserver wraps it in a witness).

## Implementation Skeleton
Paste-ready structure (Phase 2 fills `// TODO` bodies per Algorithm §). SINGLE-LINE signatures. No full bodies.

```iii
/* III/STDLIB/iii/numera/temporal_logic.iii
 *
 * III STDLIB - numera::temporal_logic
 *
 * LTL formula representation and bounded model checking over the witness
 * chain. Twelve tags: ATOM, NOT, AND, OR, IMPL, NEXT(X), ALWAYS(G),
 * EVENT(F), UNTIL(U), ONCE(O), HIST(H), SINCE(S). Finite-trace semantics.
 *
 * Evaluation is NON-RECURSIVE (W15): a (node,position) fixpoint table is
 * filled bottom-up in arena order -- propositional pass per position, then
 * each temporal node by closed-form O(L) DP over its child's full row.
 * No recursion, no pointer stack: arena post-order IS the eval order.
 *
 * Hexad: kind_witness.  Ring: R-1.  K: 1.00.
 * Discipline: W2 (<=4 params), W8 (fixed pools), W13, W14 (no break),
 *   W15 (no recursion -- fixpoint table). Trap 7: all scratch is module
 *   scope; model checking is serialized / non-reentrant.
 */

module numera_temporal_logic

extern @abi(c-msvc-x64) fn wh_get_producer(idx: u64, out: *u8) -> i32 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_get_op_id(idx: u64, out: *u8) -> i32 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_get_phase(idx: u64) -> u8 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_get_pillar(idx: u64) -> u16 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_get_rev_tag(idx: u64) -> u8 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_get_ante_count(idx: u64) -> u32 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_get_ante(idx: u64, ante_idx: u32, out: *u8) -> i32 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn cons_eval_predicate(slot: u32, op_producer: *u8, op_id: *u8, op_phase: u8, op_pillar: u16, op_revtag: u8, ante_ids: *u8, n_ante: u32) -> u8 from "constitution.iii"

const TLOGIC_OK           : i32 =  0i32
const TLOGIC_E_FULL       : i32 = -1i32
const TLOGIC_E_BAD        : i32 = -2i32
const TLOGIC_SENT         : u32 = 0xFFFFFFFFu32

const TLOGIC_TAG_ATOM     : u8 =  0u8
const TLOGIC_TAG_NOT      : u8 =  1u8
const TLOGIC_TAG_AND      : u8 =  2u8
const TLOGIC_TAG_OR       : u8 =  3u8
const TLOGIC_TAG_IMPL     : u8 =  4u8
const TLOGIC_TAG_NEXT     : u8 =  5u8
const TLOGIC_TAG_ALWAYS   : u8 =  6u8
const TLOGIC_TAG_EVENT    : u8 =  7u8
const TLOGIC_TAG_UNTIL    : u8 =  8u8
const TLOGIC_TAG_ONCE     : u8 =  9u8
const TLOGIC_TAG_HIST     : u8 = 10u8
const TLOGIC_TAG_SINCE    : u8 = 11u8

const TLOGIC_MAX_FORMULA  : u32 = 256u32
const TLOGIC_MAX_NODES    : u32 = 65536u32
const TLOGIC_MAX_SEG      : u64 = 4096u64
const TLOGIC_MAX_SUBF     : u32 = 1024u32
const TLOGIC_ANTE_MAX     : u32 = 32u32
const TLOGIC_ID_LEN       : u64 = 32u64

var TL_F_LIVE   : [u8;  256]
var TL_F_ROOT   : [u32; 256]
var TL_F_START  : [u32; 256]
var TL_F_END    : [u32; 256]

var TL_NODE_TAG  : [u8;  65536]
var TL_NODE_A    : [u32; 65536]
var TL_NODE_B    : [u32; 65536]
var TL_NODE_USED : u32 = 0u32

/* (node-local, position) fixpoint table; dim = MAX_SUBF * MAX_SEG. */
var TL_VAL        : [u8; 4194304]
var TL_VAL_FILLED : [u8; 4194304]

/* Serialized atomic-eval scratch (Trap 7: module scope, non-reentrant). */
var TL_SCR_PROD  : [u8; 32]
var TL_SCR_OP    : [u8; 32]
var TL_SCR_ANTE  : [u8; 1024]

var TL_LAST_ERR  : i32 = 0i32

fn tl_init() -> i32 @export { /* TODO: clear LIVE[*], NODE_USED=0, LAST_ERR=OK -- Algorithm "Construction fns" */ return TLOGIC_OK }

fn tl_alloc_formula() -> u32 @export { /* TODO: first free slot; START=END=NODE_USED; ROOT=SENT -- Algorithm "Construction" */ return TLOGIC_SENT }

fn tl_drop_formula(slot: u32) -> i32 @export { /* TODO: clear LIVE; LIFO node reclaim if END==NODE_USED -- Algorithm "Construction" */ return TLOGIC_OK }

fn tl_append_atom(slot: u32, pred_slot: u32) -> u32 @export { /* TODO: append ATOM node (A=pred_slot,B=0); guard NODE_USED>=MAX_NODES -- Algorithm "Construction" */ return TLOGIC_SENT }

fn tl_append_not(slot: u32, child: u32) -> u32 @export { /* TODO: append NOT node (A=child) -- Algorithm "Construction" */ return TLOGIC_SENT }

fn tl_append_bin(slot: u32, tag: u8, l: u32, r: u32) -> u32 @export { /* TODO: append binary node (A=l,B=r) -- Algorithm "Construction" */ return TLOGIC_SENT }

fn tl_append_unary_temp(slot: u32, tag: u8, child: u32) -> u32 @export { /* TODO: append unary temporal node (A=child) -- Algorithm "Construction" */ return TLOGIC_SENT }

fn tl_set_root(slot: u32, root: u32) -> i32 @export { /* TODO: set ROOT[slot]=root; guard live -- Algorithm "Construction" */ return TLOGIC_OK }

fn tl_node_count(slot: u32) -> u32 @export { /* TODO: END[slot]-START[slot] or 0 on bad slot -- Algorithm "Construction" */ return 0u32 }

/* Atomic eval: marshal fragment fields from witness hook into module scratch, call cons_eval_predicate. */
fn tl_eval_atom(pred_slot: u32, position: u64) -> u8 { /* TODO: copy prod/op/ante (clamp n_ante<=ANTE_MAX); read phase/pillar/revtag; return cons_eval_predicate(...) -- Algorithm "tl_eval_atom" */ return 0u8 }

/* Fill TL_VAL[(node-START), p] for every node and every p in [0,L); non-recursive. Returns OK or E_FULL/E_BAD. */
fn tl_fill_table(slot: u32, chain_start: u64, chain_end: u64) -> i32 { /* TODO: size guards (nsub<=MAX_SUBF, L<=MAX_SEG); Pass 1 propositional per position; Pass 2 temporal DP recurrences (G/F/U suffix, O/H/S prefix, X shift) -- Algorithm "W15 fix" */ return TLOGIC_OK }

fn tl_eval(slot: u32, chain_start: u64, chain_end: u64, position: u64) -> u8 @export { /* TODO: guards; tl_fill_table; return TL_VAL[(ROOT-START), position-chain_start] -- Algorithm "Read-off" */ return 0u8 }

fn tl_holds_on_segment(slot: u32, chain_start: u64, chain_end: u64) -> u8 @export { /* TODO: tl_fill_table once; AND root row across [0,L) -- Algorithm "tl_holds_on_segment" */ return 1u8 }
```
