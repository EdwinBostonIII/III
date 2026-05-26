# 17 numera/egraph.iii — Implementation Spec

## Verdict
PARTIAL — the gospel candidate body is structurally substantial and most of the
union-find / hashcons / rebuild / extraction machinery is sound, but it is NOT
acceptance-ready: it (1) uses **recursion** in `eg_match_node` and
`eg_instantiate` (W15 violation, the gospel itself flags this as a deferred fix);
(2) declares **local `var` arrays** in seven functions (`buf`, `canon`, `out`,
`args`, `sym_buf`, `binds`, `class_cost`, `class_node`, `stack`) — Trap 7, will
not parse at module scope rules; (3) imports `keccak256_init/update/final`
`from "keccak.iii"` which is the **wrong source file** (they live in
`keccak256.iii`) **and are never called** (dead externs); (4) uses
**un-parenthesised address-of-index casts** (`&canon[0u32] as *u32`,
`&binds[0u32] as *u32`, etc.) which SIGSEGV via the parser-precedence trap pinned
in corpus 278; (5) has an **unbounded `eg_rebuild`** and an **unbounded
extraction fixpoint** (M19 / W14 — both loop `while changed` with no iteration
ceiling); (6) `eg_extract` declares two `[u32; 131072]` arrays as **function
locals** (~1 MiB of stack — guaranteed overflow) in addition to the Trap-7
problem. Every gap is closed below; the realized design is recursion-free,
bounded, deterministic, and reentrancy-documented.

## Purpose
`numera_egraph` is the equality-saturation engine: an **e-graph** — a forest of
equivalence classes (e-classes) of **e-nodes**, where an e-node is a function
symbol applied to a vector of child e-class ids. It is the algebraic-rewrite
substrate that `cg_superopt` (a not-yet-built downstream consumer) depends on:
register a corpus of rewrite rules, saturate a term under congruence closure,
then extract the minimum-cost equivalent term. Congruence is maintained by a
union-find over e-classes plus a hashcons over canonical `(symbol, child-classes)`
tuples; saturation alternates rule application (e-matching → union) with rebuild
(re-hash + congruence propagation). **Hexad: kind_essence. Ring: R0. K: 0.99.**

## Public API
All public functions return a status or a sentinel-typed value (W12). Error
codes are negative `i32` (W9); sentinel ids are `EGRAPH_SENT` (`0xFFFFFFFFu32`);
boolean-ish returns are `u8` 0/1 (W10). No function exceeds 4 params (W2); the
two multi-obligation operations pass an aggregate by pointer.

```
fn eg_init() -> i32 @export
fn eg_intern_symbol(sym_id: *u8) -> u32 @export
fn eg_find(a: u32) -> u32 @export
fn eg_add(sym_id: *u8, children: *u32, n: u32) -> u32 @export
fn eg_union(a: u32, b: u32) -> u32 @export
fn eg_rebuild() -> u32 @export
fn eg_register_rule(rule: *u32) -> u32 @export
fn eg_saturate(max_steps: u32) -> u32 @export
fn eg_extract(req: *u32, out_term: *u32, out_n: *u32) -> i32 @export
fn eg_class_count() -> u32 @export
fn eg_node_count() -> u32 @export
fn eg_selftest() -> u64 @export
```

Return-status conventions:
- `eg_init` → `EGRAPH_OK` (0) or never-fails; total.
- `eg_intern_symbol` → symbol slot id, or `EGRAPH_SENT` on table-full / bad ptr.
- `eg_find` → canonical class representative id (sentinel-typed value; W12).
- `eg_add` → the canonical e-class id of the node, or `EGRAPH_SENT` on
  arity-overflow / table-full / bad symbol.
- `eg_union` → the surviving representative id, or `EGRAPH_SENT` on bad input.
- `eg_rebuild` → number of congruence passes performed (>=1), bounded by
  `EGRAPH_MAX_PASSES`; sentinel-typed `u32`.
- `eg_register_rule` → rule id, or `EGRAPH_SENT` on rule-table / area overflow or
  malformed skeleton.
- `eg_saturate` → number of saturation steps actually performed (W12).
- `eg_extract` → `EGRAPH_OK`, or `EGRAPH_E_BAD` (no extractable term / cycle),
  or `EGRAPH_E_FULL` (output buffer / extraction stack overflow).
- `eg_class_count` / `eg_node_count` → live counts (diagnostics; sentinel-typed).
- `eg_selftest` → `99u64` on full KAT pass, else the failing KAT index (W12).

**API changes from the gospel body (with rationale):**
- `eg_register_rule(lhs,lhs_n,rhs,rhs_n)` (4 params) → `eg_register_rule(rule: *u32)`:
  a single packed descriptor `[lhs_n, rhs_n, lhs..., rhs...]` passed by pointer.
  This keeps W2 headroom and lets the rule carry its own framing (needed for the
  recursion-free instantiator's arity prepass). Still <=4 params either way; the
  aggregate form is cleaner and self-describing.
- `eg_extract(root, costs, sym_count, out_term, out_n)` was **5 params (W2
  violation)** → `eg_extract(req: *u32, out_term, out_n)` (3 params). `req` is a
  packed request `[root, sym_count, costs[0..sym_count-1]]` passed by pointer.
- `eg_saturate` / `eg_apply_rule` / `eg_match_node` / `eg_instantiate` /
  `eg_lookup` / `eg_ht_insert` / `eg_hash_key` / `eg_node_matches` /
  `eg_new_class` / `eg_sym_id_ptr` remain **private** (no `@export`) — they are
  internal mechanism. `eg_apply_rule`, `eg_match_node`, `eg_instantiate` are
  reformulated recursion-free (see Algorithm).
- Added `eg_class_count` / `eg_node_count` diagnostics (slot-leak / saturation
  introspection; same role as `bigint_live_count` in the bigint exemplar).
- Added `eg_selftest` returning `99u64` (house convention; cf.
  `identifier.iii::ident_selftest`) so the Phase-2 KAT gate is in-module.

## Constant Namespace
PREFIX = `EGRAPH_` . Grep of `STDLIB/` (`^const EG_` and the full `EGRAPH_*`
scratch-name set) returned **no collisions**; `numera/egraph.iii` does not yet
exist. NOTE: the gospel body used the bare `EG_` prefix on consts (`EG_OK`,
`EG_MAX_NODES`, …). Per Trap 2 (module-level `const` is linker-global), I keep a
distinct, longer prefix `EGRAPH_` to be unambiguous and future-proof against any
later module that might grab `EG_*`. Every const and every module-scope `var` is
`EGRAPH_`-prefixed.

| name | type | value |
|---|---|---|
| `EGRAPH_OK` | i32 | `0i32` |
| `EGRAPH_E_FULL` | i32 | `-1i32` |
| `EGRAPH_E_BAD` | i32 | `-2i32` |
| `EGRAPH_E_RULE` | i32 | `-3i32` |
| `EGRAPH_SENT` | u32 | `0xFFFFFFFFu32` |
| `EGRAPH_INF_COST` | u32 | `0xFFFFFFFFu32` |
| `EGRAPH_MAX_SYMS` | u32 | `4096u32` |
| `EGRAPH_MAX_NODES` | u32 | `131072u32` |
| `EGRAPH_MAX_CLASS` | u32 | `131072u32` |
| `EGRAPH_MAX_CHILDREN` | u32 | `8u32` |
| `EGRAPH_HT_SIZE` | u64 | `262144u64` |
| `EGRAPH_HT_MASK` | u64 | `262143u64` |
| `EGRAPH_MAX_RULES` | u32 | `256u32` |
| `EGRAPH_RULE_AREA` | u32 | `65536u32` |
| `EGRAPH_MAX_VARS` | u32 | `16u32` |
| `EGRAPH_MAX_PASSES` | u32 | `4096u32` |
| `EGRAPH_KEYBUF_CAP` | u64 | `64u64` |
| `EGRAPH_MATCH_STK` | u32 | `8192u32` |
| `EGRAPH_INST_STK` | u32 | `8192u32` |
| `EGRAPH_EXT_STK` | u32 | `131072u32` |
| `EGRAPH_SYMBYTES` | u64 | `32u64` |

Const-value bounds rationale:
- `EGRAPH_HT_SIZE = 2 * EGRAPH_MAX_NODES` rounded to a power of two (262144) so
  load factor <= 0.5 (open addressing stays fast and termination-bounded), and
  `EGRAPH_HT_MASK = EGRAPH_HT_SIZE - 1` permits **mask-not-modulo** wraparound
  (`& EGRAPH_HT_MASK`) — avoids Trap 11 (`%`-after-call).
- `EGRAPH_KEYBUF_CAP = 64` = 4 (symbol bytes) + 8 children * 4 (class-id bytes) =
  36 bytes max, rounded up; hash-key serialization never exceeds it.
- `EGRAPH_MAX_PASSES` / `EGRAPH_MATCH_STK` / `EGRAPH_INST_STK` / `EGRAPH_EXT_STK`
  bound the worklists (M19, W14) — see Data Structures.

## Data Structures
Every buffer is a **fixed module-scope `var` array** (W8; Trap 7 — the gospel's
in-function `var` arrays are all hoisted here). All scratch is `EGRAPH_`-prefixed
and collision-checked. The engine is a **single global e-graph instance**
(`@export` entry points operate on it); it is therefore **not reentrant** — this
is the same serialized-state model as `sha256.iii` / `identifier.iii`, and is
acceptable because saturation is a batch operation, not a concurrent service.
This non-reentrancy is called out explicitly per Trap 7's note.

Symbol table (a symbol = one 32-byte identifier):
| array | type | size | bound justification |
|---|---|---|---|
| `EGRAPH_SYM_LIVE` | `[u8; 4096]` | `EGRAPH_MAX_SYMS` | distinct function symbols; 4096 covers any realistic rewrite alphabet |
| `EGRAPH_SYM_ID` | `[u8; 131072]` | `EGRAPH_MAX_SYMS * 32` | 32 id-bytes per symbol |
| `EGRAPH_SYM_USED` | `u32` (scalar) | — | high-water mark |

E-nodes (symbol + up to 8 child e-class ids):
| array | type | size | bound justification |
|---|---|---|---|
| `EGRAPH_N_LIVE` | `[u8; 131072]` | `EGRAPH_MAX_NODES` | per-node liveness |
| `EGRAPH_N_SYM` | `[u32; 131072]` | `EGRAPH_MAX_NODES` | node symbol slot |
| `EGRAPH_N_NARGS` | `[u32; 131072]` | `EGRAPH_MAX_NODES` | node arity (0..8) |
| `EGRAPH_N_ARGS` | `[u32; 1048576]` | `EGRAPH_MAX_NODES * 8` | flat child-class table, stride 8 |
| `EGRAPH_N_ECLASS` | `[u32; 131072]` | `EGRAPH_MAX_NODES` | node → owning class |
| `EGRAPH_N_USED` | `u32` (scalar) | — | high-water mark |

E-classes (union-find):
| array | type | size | bound justification |
|---|---|---|---|
| `EGRAPH_CL_LIVE` | `[u8; 131072]` | `EGRAPH_MAX_CLASS` | per-class liveness |
| `EGRAPH_CL_PAR` | `[u32; 131072]` | `EGRAPH_MAX_CLASS` | union-find parent |
| `EGRAPH_CL_RANK` | `[u32; 131072]` | `EGRAPH_MAX_CLASS` | union-by-rank |
| `EGRAPH_CL_USED` | `u32` (scalar) | — | high-water mark |

Hashcons (open-addressed `(sym,args) → node`):
| array | type | size | bound justification |
|---|---|---|---|
| `EGRAPH_HT_LIVE` | `[u8; 262144]` | `EGRAPH_HT_SIZE` | slot occupancy |
| `EGRAPH_HT_NODE` | `[u32; 262144]` | `EGRAPH_HT_SIZE` | slot → node id |

Rewrite rules (flat preorder skeletons; positive entry = `(sym_slot<<1)` even
with arity in bits 16..23, variable = `((var_idx<<1)|1)` odd):
| array | type | size | bound justification |
|---|---|---|---|
| `EGRAPH_RULE_LIVE` | `[u8; 256]` | `EGRAPH_MAX_RULES` | per-rule liveness |
| `EGRAPH_RULE_LHS_OFF` | `[u32; 256]` | `EGRAPH_MAX_RULES` | LHS offset in BUF |
| `EGRAPH_RULE_LHS_LEN` | `[u32; 256]` | `EGRAPH_MAX_RULES` | LHS length |
| `EGRAPH_RULE_RHS_OFF` | `[u32; 256]` | `EGRAPH_MAX_RULES` | RHS offset in BUF |
| `EGRAPH_RULE_RHS_LEN` | `[u32; 256]` | `EGRAPH_MAX_RULES` | RHS length |
| `EGRAPH_RULE_BUF` | `[u32; 65536]` | `EGRAPH_RULE_AREA` | shared skeleton arena |
| `EGRAPH_RULE_USED` | `u32` (scalar) | — | BUF bump pointer |

Hoisted scratch (replaces all in-function `var` arrays — Trap 7):
| array | type | size | replaces / purpose |
|---|---|---|---|
| `EGRAPH_KEYBUF` | `[u8; 64]` | `EGRAPH_KEYBUF_CAP` | `eg_hash_key`'s `buf` (serialized key) |
| `EGRAPH_HASHOUT` | `[u8; 32]` | 32 | `eg_hash_key`'s `out` (digest) |
| `EGRAPH_CANON` | `[u32; 8]` | `EGRAPH_MAX_CHILDREN` | `eg_add` / `eg_rebuild` child canon |
| `EGRAPH_BINDS` | `[u32; 16]` | `EGRAPH_MAX_VARS` | active pattern-var bindings |
| `EGRAPH_SYMBUF` | `[u8; 32]` | 32 | `eg_instantiate`'s `sym_buf` |
| `EGRAPH_IARGS` | `[u32; 8]` | `EGRAPH_MAX_CHILDREN` | `eg_instantiate`'s `args` |
| `EGRAPH_CLASS_COST` | `[u32; 131072]` | `EGRAPH_MAX_CLASS` | `eg_extract` DP cost (was a 512 KiB stack local!) |
| `EGRAPH_CLASS_NODE` | `[u32; 131072]` | `EGRAPH_MAX_CLASS` | `eg_extract` DP best-node |

Explicit worklist stacks (W15 recursion elimination — see Algorithm):
| array | type | size | bound justification |
|---|---|---|---|
| `EGRAPH_M_POS` | `[u32; 8192]` | `EGRAPH_MATCH_STK` | match obligation: skeleton position |
| `EGRAPH_M_CLS` | `[u32; 8192]` | `EGRAPH_MATCH_STK` | match obligation: target e-class |
| `EGRAPH_M_CHOICE` | `[u32; 8192]` | `EGRAPH_MATCH_STK` | backtrack cursor (next class member to try) |
| `EGRAPH_M_BSAVE` | `[u32; 131072]` | `EGRAPH_MATCH_STK*16` | per-frame binding snapshot for backtracking |
| `EGRAPH_I_POS` | `[u32; 8192]` | `EGRAPH_INST_STK` | instantiate stack: skeleton position |
| `EGRAPH_I_ARITY` | `[u32; 8192]` | `EGRAPH_INST_STK` | instantiate stack: remaining children |
| `EGRAPH_I_ACC` | `[u32; 65536]` | `EGRAPH_INST_STK*8` | per-frame collected child class ids |
| `EGRAPH_EXT_STK` | `[u32; 131072]` | `EGRAPH_EXT_STK` | extraction emit stack (was `[u32;4096]` local) |

Bound justifications for the stacks: match/instantiate skeleton depth is bounded
by the rule-skeleton length (<= `EGRAPH_RULE_AREA`), and a single rule cannot
exceed a few hundred entries in practice; 8192 frames is >10x the largest legal
skeleton. `EGRAPH_M_BSAVE` is `MATCH_STK * MAX_VARS` so each frame can snapshot
all 16 bindings before a speculative child match (deterministic backtracking).
`EGRAPH_EXT_STK = EGRAPH_MAX_CLASS` because the worst-case emitted preorder
visits each class at most once per occurrence; extraction refuses (returns
`EGRAPH_E_FULL`) rather than overrun. All loops that push assert `sp <
<cap>` and set the terminating flag on overflow (W14, M19).

## Dependencies (externs)
```
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
```
- `identifier.iii` — **Layer 0, Module 01. BUILT** (present in
  `STDLIB/iii/numera/identifier.iii`). Verified signatures match exactly:
  `ident_from_bytes(*u8,u64,*u8)->i32`, `ident_eq(*u8,*u8)->u8`,
  `ident_copy(*u8,*u8)->i32`. Its transitive dependency `keccak256.iii` is also
  built. **No not-yet-built dependency.**

**REMOVED externs (gospel error):** the gospel imported
`keccak256_init/update/final from "keccak.iii"`. These functions do **not exist
in `keccak.iii`** (that module exports the raw Keccak-f permutation); they live
in `keccak256.iii`. Critically, **the gospel body never calls them** — they are
dead externs. Worse, `identifier.iii` documents that the streaming
`keccak256_init` path triggers the **param-spill trap** (Trap 11) and was
deliberately replaced by `keccak256_oneshot` over a contiguous buffer. My
`eg_hash_key` already serializes the whole key into one contiguous buffer
(`EGRAPH_KEYBUF`) and calls `ident_from_bytes` exactly once — so I **drop the
three keccak externs entirely** and depend only on `identifier.iii`. This both
fixes the wrong-source-file bug and dodges the param-spill trap by construction.

**Downstream (not a dependency, for the wave scheduler):** `cg_superopt` (the
superoptimizer) consumes this engine and is **not yet built**; it is not imported
by egraph and does not block egraph.

## Algorithm
NIH (M1): every algorithm is hand-rolled — union-find by rank with path
compression, open-addressed hashcons, bottom-up congruence rebuild, explicit-stack
e-matching with deterministic backtracking, and bottom-up min-cost DP extraction.
No ML / no heuristics (M3/M4): every decision is exact and structural. Determinism
(M2) and bit-identity (W5): all iteration is over dense slot ranges in **ascending
id order**; union picks the representative by **rank, then lower id on ties**
(made explicit — see `eg_union`), so the canonical forest is a pure function of
the operation sequence; the hash key is a fixed little-endian byte serialization
hashed by the deterministic `ident_from_bytes` (Keccak256). No recursion anywhere
(W15) — the two recursive gospel functions are reformulated with explicit stacks
below.

### `eg_init() -> i32`
Zero all `*_LIVE` arrays over `[0, MAX)`, wipe `EGRAPH_HT_LIVE` over
`[0, EGRAPH_HT_SIZE)`, clear `EGRAPH_RULE_LIVE`, reset every `*_USED` high-water
mark to 0. Total, deterministic, reversible (it *is* the reset).

### `eg_intern_symbol(sym_id: *u8) -> u32`
Linear scan `i` in `[0, EGRAPH_SYM_USED)`; for each live slot, `ident_eq` the
stored id against `sym_id`; first match (lowest id) wins → return it. On miss,
if `EGRAPH_SYM_USED >= EGRAPH_MAX_SYMS` return `EGRAPH_SENT`, else `ident_copy`
into the next slot, mark live, bump, return the new slot. Deterministic: scan
order is ascending. (Single-pass; the gospel did the `ident_eq` twice — kept to
one call per slot, stored in a local.)

### `eg_find(a: u32) -> u32`  (path-compressing find, iterative — already W15-clean)
Walk parents to the root (`while EGRAPH_CL_PAR[root] != root`), then a second
pass rewires every node on the path directly to `root`. No recursion. Total over
valid ids; `eg_find` of an out-of-range id is guarded by the callers (all ids it
sees are produced by `eg_new_class`).

### `eg_new_class() -> u32`  (private)
Bump-allocate a class: if full → `EGRAPH_SENT`; else set `PAR[c]=c`, `RANK[c]=0`,
live, bump, return `c`.

### `eg_hash_key(sym: u32, args: *u32, n: u32) -> u64`  (private)
Serialize into `EGRAPH_KEYBUF`: 4 LE bytes of `sym`, then for each child `i`
4 LE bytes of `eg_find(args[i])` (canonicalized). Call
`ident_from_bytes(&EGRAPH_KEYBUF[0u64], off, &EGRAPH_HASHOUT[0u64])` (ONE call,
contiguous buffer — param-spill-safe). Fold the first 8 digest bytes LE into a
`u64` and return `h & EGRAPH_HT_MASK` (**mask, not `%`** — Trap 11). All
address-of-index uses are parenthesised `(&ARR[idx])` (Trap 13).

### `eg_node_matches(node, sym, args, n) -> u8`  (private)
Reject on symbol or arity mismatch; else compare `eg_find` of each stored child
to `eg_find(args[i])` under a single-flag sentinel loop (W14). Returns `1u8`/`0u8`.

### `eg_lookup(sym, args, n) -> u32` / `eg_ht_insert(sym, args, n, node) -> i32`  (private)
Open-addressing with linear probing, wrap by `& EGRAPH_HT_MASK`. Terminate when
an empty slot is hit (lookup → miss) or a structurally-equal live node is found
(lookup → hit), or after `EGRAPH_HT_SIZE` probes (table full — bounded, M19).
The gospel called `eg_node_matches` twice per probe; collapse to one call into a
local. Sentinel-loop, no `break` (W14). Insert mirrors the probe and stores
`(LIVE=1, NODE=node)` at the first empty slot.

### `eg_add(sym_id: *u8, children: *u32, n: u32) -> u32`
1. `n > EGRAPH_MAX_CHILDREN` → `EGRAPH_SENT`.
2. `sym = eg_intern_symbol(sym_id)`; sentinel-guard.
3. Canonicalize: `EGRAPH_CANON[i] = eg_find(children[i])` for `i in [0,n)`.
4. `existing = eg_lookup(sym, (&EGRAPH_CANON[0u32]), n)`; if found return
   `eg_find(EGRAPH_N_ECLASS[existing])` (hashcons hit → existing class).
5. Else allocate node id (full-guard), fill `N_SYM/N_NARGS/N_ARGS` (stride-8,
   byte-offset arithmetic), `eg_new_class()` for it, store `N_ECLASS`, insert
   into hashcons, return the new class. Deterministic; congruence-correct because
   children are canonicalized before hashing.

### `eg_union(a: u32, b: u32) -> u32`
`ra=eg_find(a)`, `rb=eg_find(b)`; equal → return `ra`. Union by rank. **Tie-break
made deterministic (M2 fix):** when `RANK[ra] == RANK[rb]`, keep the **lower id**
as the surviving root (the gospel kept `ra` arbitrarily, which is id-order-stable
here but I pin it explicitly: `hi = min(ra,rb)`, `lo = max(ra,rb)` on equal rank;
on unequal rank the higher-rank root wins). Set `PAR[lo]=hi`; bump `RANK[hi]` on
equal rank. Return `hi`. Reversible-in-principle (union-find is the canonical
M5/M9 structure: no information is destroyed, classes only coarsen and a rebuild
can be recomputed from the node set).

### `eg_rebuild() -> u32`  (bounded congruence closure — M19/W14 fix)
Outer loop driven by `changed` flag AND a hard `passes < EGRAPH_MAX_PASSES`
ceiling (the gospel's `while changed` was unbounded — M19 violation). Each pass:
wipe `EGRAPH_HT_LIVE`; for each live node in ascending id order, canonicalize its
stored children in place (`EGRAPH_N_ARGS[...] = eg_find(...)`), look it up; if
absent, insert; if a *different* node already occupies the canonical slot, union
the two e-classes (deterministic representative), write the merged root back into
both nodes' `N_ECLASS`, set `changed`. Terminate when a full pass makes no union
(fixpoint) or the ceiling trips. Returns the pass count. Monotone: unions only
coarsen classes, so the fixpoint is reached in <= (#initial classes) passes,
well under the ceiling; the ceiling is a safety bound, not a heuristic cutoff.

### `eg_register_rule(rule: *u32) -> u32`
`rule[0]=lhs_n`, `rule[1]=rhs_n`, then `lhs_n` LHS entries, then `rhs_n` RHS
entries. Validate `lhs_n>=1`, total skeleton fits `EGRAPH_RULE_AREA`, and each
entry is well-formed (var idx `< EGRAPH_MAX_VARS`; concrete-symbol arity bits
`<= EGRAPH_MAX_CHILDREN`). Find the first free rule slot (ascending), copy LHS
then RHS into `EGRAPH_RULE_BUF` at the bump pointer, record offsets/lengths, mark
live, return rule id. Malformed → `EGRAPH_SENT`.

### `eg_match_node(...)` → recursion-free **`eg_match(rid, root_node) -> u8`**  (W15 FIX, private)
The gospel matcher recursed (a) down the skeleton and (b) over class members.
Reformulated as an **explicit DFS with deterministic backtracking** over an
obligation stack:
- An *obligation* is `(skel_pos, target_class)`: "match the skeleton subtree at
  `skel_pos` against some live node whose class is `target_class`."
- Stacks: `EGRAPH_M_POS[]`, `EGRAPH_M_CLS[]`, `EGRAPH_M_CHOICE[]` (the next
  candidate node id to try for this obligation), and `EGRAPH_M_BSAVE[]` (a
  snapshot of all `EGRAPH_MAX_VARS` bindings taken when the frame is pushed, so a
  failed branch restores bindings exactly — preserving determinism).
- Init: clear `EGRAPH_BINDS` to `EGRAPH_SENT`; push the root obligation
  `(0, eg_find(N_ECLASS[root_node]))` with choice cursor = `root_node` (the root
  is matched against the specific node, not the whole class).
- Loop (single sentinel flag `running`, no `break`; bounded by stack depth and
  by the dense node scan): pop the top obligation; read `entry = skel[pos]`.
  - **Variable entry** (`entry & 1 == 1`): `vi = entry>>1`. If `BINDS[vi]==SENT`
    bind `BINDS[vi]=target_class`, success for this obligation; else require
    `BINDS[vi]==target_class` (linear-pattern consistency). On success advance to
    sibling (pop frame, continue parent); on conflict, **backtrack**.
  - **Symbol entry** (even): find the next live node `>= choice cursor` whose
    `eg_find(N_ECLASS)==target_class` and whose `N_SYM==entry>>1` and
    `N_NARGS==arity`; if found, save the choice cursor (= node+1) for re-entry on
    backtrack, push child obligations `(child_skel_pos_k, eg_find(N_ARGS[node][k]))`
    for `k` in **descending** order so they pop in ascending order
    (determinism), and descend. The child skeleton positions are pre-computed by
    a **span walk** (skip-counting via the arity bits — no recursion) so each
    child's subtree start is known.
  - **Backtrack**: if no candidate node remains for an obligation, restore the
    binding snapshot from `EGRAPH_M_BSAVE` for this frame, pop it, and resume the
    parent's choice cursor at the next node. If the root obligation exhausts its
    candidates, the match fails (`running=0`, return `0u8`).
  - **Success**: when the obligation stack empties with the root satisfied,
    return `1u8` with `EGRAPH_BINDS` filled. **First match in node-id order** is
    the committed one — deterministic.
- This enumerates exactly the same match set as the recursive form, in a fixed
  order, with O(stack) memory bounded by `EGRAPH_MATCH_STK` (overflow →
  conservative match-fail, never UB).

### `eg_instantiate(...)` → recursion-free **`eg_instantiate(rid) -> u32`**  (W15 FIX, private)
The gospel instantiator recursed over the RHS skeleton. Reformulated with an
**explicit post-order build stack**:
- Frame = `(skel_pos, arity, children_collected)`; child class ids accumulate in
  `EGRAPH_I_ACC[frame*8 + k]`.
- Walk the RHS preorder with `EGRAPH_I_POS[]`/`EGRAPH_I_ARITY[]`: a **variable**
  entry resolves immediately to `EGRAPH_BINDS[var_idx]` and is handed to the
  parent frame's accumulator; a **symbol** entry (arity from bits 16..23) pushes
  a frame and descends to its first child. When a frame has collected all
  `arity` children, it copies the symbol's 32 id-bytes from `EGRAPH_SYM_ID` into
  `EGRAPH_SYMBUF`, copies the accumulated child classes into `EGRAPH_IARGS`,
  calls `eg_add(&EGRAPH_SYMBUF[0u64], &EGRAPH_IARGS[0u32], arity)`, pops, and
  hands the resulting class id up to its parent. When the root frame completes,
  its class id is the result. No recursion; bounded by `EGRAPH_INST_STK`.

### `eg_apply_rule(rid) -> u32`  (private, recursion-free)
For each live node in ascending id order: reset `EGRAPH_BINDS`; `eg_match(rid,
node)`; on success `eg_instantiate(rid)` → `new_cl`, `prev_cl =
eg_find(N_ECLASS[node])`, `eg_union(prev_cl, new_cl)`; count a union iff the
representative actually changed (compare merged vs both inputs). Returns the
number of new unions. (The gospel's double-increment when `merged != prev` AND
`merged != new` over-counts; fixed to count **one** union event per successful
non-trivial merge — exactness, M4.)

### `eg_saturate(max_steps: u32) -> u32`  (bounded — M19/W14)
Outer loop driven by `changed` flag AND `step < max_steps` (the gospel already
had the step bound — kept and made the only terminator besides fixpoint). Each
step: for each live rule in ascending id order, `eg_apply_rule`; if any rule
produced a union, set `changed`; then `eg_rebuild()` (restore congruence). Stop
at fixpoint (`changed==0`) or `step==max_steps`. Returns steps performed. Bounded
saturation = M19; termination is guaranteed because the e-graph is finite (node
count <= `EGRAPH_MAX_NODES`) and rules only add nodes / coarsen classes, so a
true fixpoint exists within finitely many steps; `max_steps` is the caller's cost
ceiling.

### `eg_extract(req: *u32, out_term: *u32, out_n: *u32) -> i32`  (bounded DP)
`req[0]=root`, `req[1]=sym_count`, `req[2..]=costs[]`. Two phases:
1. **Min-cost DP** over `EGRAPH_CLASS_COST` / `EGRAPH_CLASS_NODE` (module-scope —
   fixes the 512 KiB stack-local bug): init all live classes to `EGRAPH_INF_COST`
   / `EGRAPH_SENT`. Iterate-to-fixpoint with a `changed` flag **and** a
   `EGRAPH_MAX_PASSES` ceiling (M19 fix — gospel was unbounded): for each live
   node, `total = costs[sym]` (guard `sym < sym_count`) plus the current min cost
   of each child class; if all children are finite and `total <
   CLASS_COST[class]`, relax. The cost lattice is bounded below by 0 and strictly
   decreases on each relaxation, so the fixpoint is reached in <= #classes passes.
   Saturating add (clamp at `EGRAPH_INF_COST - 1`) prevents overflow wraparound
   (W4/M15 — exact bounded arithmetic).
2. **Preorder emit** via `EGRAPH_EXT_STK`: push `eg_find(root)`; while `sp>0`,
   pop class `cl`, read `nid = CLASS_NODE[cl]`; if `SENT` → `EGRAPH_E_BAD` (no
   representative / unreachable). Emit `N_SYM[nid]`, push children in descending
   order. On stack overflow (`sp >= EGRAPH_EXT_STK`) → `EGRAPH_E_FULL` (refuse,
   never overrun). Write `*out_n = emit`, return `EGRAPH_OK`. **Cycle safety:**
   because the DP only assigns a finite cost to a class via a node all of whose
   children already have finite (hence strictly smaller in the well-founded
   relaxation order) cost, the chosen `CLASS_NODE` graph is acyclic by
   construction, so the emit terminates (M5 — no infinite expansion). The output
   buffer length is the caller's responsibility; the emit count is returned so
   the caller can validate.

### `eg_class_count` / `eg_node_count`  (diagnostics)
Count live entries in `EGRAPH_CL_LIVE` / `EGRAPH_N_LIVE` over the high-water
range (ascending). Pure.

### `eg_selftest() -> u64`
In-module KAT harness (see KAT Vectors). Returns `99u64` on full pass, else the
1-based index of the first failing vector (W12). Uses only module-scope scratch.

## KAT Vectors (>= 3)
All vectors run after `eg_init()`. Symbols are interned from fixed 32-byte ids
(distinct first byte, rest zero, written into `EGRAPH_SYMBUF`-style module
scratch). "class(x)" denotes `eg_find` of the returned id.

1. **Congruence closure (the defining property).**
   Build `f(a)` and `f(b)` as e-nodes (symbols `f`,`a`,`b`; `a`,`b` arity 0).
   Initially `class(f(a)) != class(f(b))`. Then `eg_union(class(a), class(b))`
   and `eg_rebuild()`. Expected: `eg_rebuild()` returns >= 2 passes (one to merge
   `f(a)`,`f(b)`, one to confirm fixpoint) and **`eg_find(class(f(a))) ==
   eg_find(class(f(b)))`** — congruence propagated `a≡b ⟹ f(a)≡f(b)`. This is the
   byte-checkable heart of the engine.

2. **Hashcons identity (idempotent add).**
   `c1 = eg_add(f, [a])`; `c2 = eg_add(f, [a])` with identical children.
   Expected `c1 == c2` (same class, no new node) and `eg_node_count()` unchanged
   between the two adds (the second `eg_add` is a pure hashcons hit). Verifies
   the open-addressed hashcons + canonical key.

3. **Rewrite + saturate + extract (`x*2 → x<<1`, pick cheaper).**
   Symbols: `mul`,`shl`,`x`,`two`,`one`. Add term `mul(x, two)`. Register rule
   LHS `mul(?0, two)` → RHS `shl(?0, one)`. `eg_saturate(8)` then
   `eg_extract(req)` with `costs[mul]=10, costs[shl]=1, costs[x]=1,
   costs[two]=1, costs[one]=1`. Expected output preorder begins with the `shl`
   symbol slot (the cheaper equivalent) — i.e. `out_term[0] == slot(shl)`,
   `*out_n == 3` (`shl x one`). Verifies e-matching, instantiation, saturation
   fixpoint, and min-cost extraction end-to-end.

4. **Extraction refusal on empty graph (negative case — prove the guard fails).**
   After `eg_init()` only, `eg_extract` of an unmapped root class → returns
   `EGRAPH_E_BAD` (no `CLASS_NODE`), **not** `EGRAPH_OK`. Proves the bad-input
   gate actually triggers (per the "prove the negative case" discipline).

5. **Determinism / bit-identity replay.**
   Run vectors 1–3 twice from a fresh `eg_init()`; assert identical
   `eg_class_count()`, `eg_node_count()`, extracted `out_term` bytes, and
   `out_n`. Proves M2/W5 (cross-run bit-identity of the canonical forest and the
   extracted term).

`eg_selftest` returns `99u64` only if all of the above hold.

## Trap Exposure
The catalog has 12 traps; this module additionally touches the corpus-278
address-of-index precedence trap (documented in-tree, treated here as a 13th).

1. **Multi-line `fn` declarations** — EXPOSED (many functions). Avoidance: every
   signature in the skeleton is single-line; with the W2 fixes (`eg_register_rule`,
   `eg_extract` now take packed-pointer aggregates) no signature is long enough to
   tempt wrapping.
2. **Module-level `const` linker-global** — EXPOSED (21 consts). Avoidance:
   `EGRAPH_` prefix on **every** const and var; grep-confirmed collision-free.
   (Gospel used bare `EG_`; re-prefixed.)
3. **Signed-int ordering compare SIGSEGV** — LOW EXPOSURE. All ids/counts/costs
   are `u32`/`u64` (unsigned compares are fine). The only `i32` values are status
   codes, compared by `==`/`!=` only (W9/W11). No `i32`/`i64` `< <= > >=`.
4. **`u32`-in-`u64`-slot garbage before pointer math** — EXPOSED (every
   `EGRAPH_N_ARGS[(node as u64)*8u64 + (k as u64)]` and the stride-8 stores).
   Avoidance: mask `(x as u64) & 0xFFFFFFFFu64` on any `u32` promoted into an
   address/index expression; node/class ids are bump-allocated `< 2^31` so the
   high word is zero, but the mask is applied defensively at every promotion
   (matches `bigint.iii`'s `& 0xFFFFFFFFu64` discipline).
5. **`u32` pointer store width (`movq` clobber)** — EXPOSED. `eg_hash_key`
   serializes the key **byte-by-byte through `*u8`** (as the gospel already does,
   and as `bigint.iii::big_store_u64_le` does) rather than storing `u32` through a
   `*u32`. The `EGRAPH_N_ARGS[...] = canon[k]` stores are into a `[u32;...]`
   module array by index (not through a reconstructed `*u32`), which is the safe
   form; any place that builds a `*u32` view writes through indices, not raw
   `p[0]=v_u32`.
6. **Nested `/* */` comments** — AVOIDED. No nested block comments; only `//` and
   single-level `/* */`. (The gospel's header block is single-level.)
7. **Local `var` arrays unsupported** — EXPOSED (gospel had 9 in-function `var`
   arrays). Avoidance: **all hoisted to module scope** (`EGRAPH_KEYBUF`,
   `EGRAPH_HASHOUT`, `EGRAPH_CANON`, `EGRAPH_BINDS`, `EGRAPH_SYMBUF`,
   `EGRAPH_IARGS`, `EGRAPH_CLASS_COST`, `EGRAPH_CLASS_NODE`, the worklist stacks).
   Consequence documented: the engine is **non-reentrant** (single global e-graph
   instance) — acceptable for batch saturation, same model as `sha256.iii`.
8. **`} else {` must be one line** — EXPOSED (control flow). Avoidance: the
   skeleton uses the flag-guarded `if … if …` idiom from the exemplars (rarely
   needs `else`); where `else` is used it is written `} else {` on one line.
9. **Em-dash in `/* */` comment** — AVOIDED. All comments use ASCII `--`.
10. **`let mut x = 0u32` checkpoint-flag misbehaves** — LOW EXPOSURE. Loop
    termination uses dedicated `u8` flags driving the `while` condition (W14)
    and bounded counters, mirroring `bigint.iii::going`. Where a single
    completion check suffices, an early-return form is preferred.
11. **`a % b` after a call → quotient/stale-divisor** — EXPOSED conceptually
    (hash slot reduction). Avoidance: the hashcons size is a **power of two**, so
    slot reduction is `h & EGRAPH_HT_MASK` (mask, never `%`). No `%` appears
    anywhere in the module. (The gospel already used the mask — preserved.)
12. **`@specialize *T` stride defaults to 8** — NOT APPLICABLE. No generics; all
    arrays are concrete `[u32;…]`/`[u8;…]` with explicit byte-offset arithmetic
    (`*8u64` for the stride-8 `EGRAPH_N_ARGS` table, `*32u64` for symbol ids,
    `*4u64` for the key bytes). Layout is asserted by KAT 1–3 (which force node
    growth and child indexing).
13. **(corpus 278) Address-of-index precedence** — EXPOSED (the gospel has
    several **un-parenthesised** `&ARR[idx] as *T` casts:
    `&canon[0u32] as *u32`, `&binds[0u32] as *u32`, `&args[0u32] as *u32`,
    `&sym_buf[0u64] as *u8`, `&buf[0u64]`, `&out[0u64]`, `&nxt as *u32`,
    `&nxt2 as *u32`). The bare form parses as `&(ARR[idx] as *T)` → value-load →
    wild address → SIGSEGV. Avoidance: **every** address-of-index cast is
    parenthesised: `(&EGRAPH_CANON[0u32]) as *u32`,
    `(&EGRAPH_BINDS[0u32]) as *u32`, etc. — the form pinned correct by corpus 278.

## Gap / Fix List
PARTIAL — the gospel body is a strong skeleton but not acceptance-ready. Every
gap below is closed by this spec; Phase 2 implements against it.

1. **W15 recursion in `eg_match_node` and `eg_instantiate`** (gospel's own footer
   admits this is deferred). FIX: reformulated both as explicit worklist DFS —
   `eg_match` over `(skel_pos, target_class)` obligation stacks with binding
   snapshots for deterministic backtracking, and `eg_instantiate` over a
   post-order build stack with per-frame child accumulators. KAT 3 + KAT 5
   establish equivalence and determinism (the "KAT corpus establishing
   equivalence" the gospel calls for).
2. **Trap 7: nine in-function `var` arrays** (`buf`, `out`, `canon` ×2, `args`,
   `sym_buf`, `binds`, `class_cost`, `class_node`, `stack`). FIX: all hoisted to
   `EGRAPH_`-prefixed module-scope arrays; non-reentrancy documented.
3. **`eg_extract` two `[u32;131072]` stack locals (~1 MiB) + `[u32;4096]` stack
   local** → guaranteed stack overflow. FIX: `EGRAPH_CLASS_COST`,
   `EGRAPH_CLASS_NODE`, `EGRAPH_EXT_STK` at module scope.
4. **Wrong extern source + dead externs:** `keccak256_init/update/final from
   "keccak.iii"` — these are in `keccak256.iii`, are never called, and the
   streaming `keccak256_init` path is param-spill-buggy (Trap 11, per
   `identifier.iii`). FIX: drop all three externs; rely solely on
   `ident_from_bytes` over a contiguous buffer.
5. **M19 unbounded loops:** `eg_rebuild` (`while changed`) and `eg_extract`'s DP
   (`while changed`) had no iteration ceiling. FIX: both bounded by
   `EGRAPH_MAX_PASSES`; termination argued from monotone coarsening / strictly
   decreasing cost lattice (cost-lattice boundedness, M19).
6. **W2 param-count violations:** `eg_register_rule` (4 — at the limit, acceptable
   but repacked for self-framing) and `eg_extract` (**5 — over the limit**). FIX:
   both take a single packed `*u32` descriptor (`rule`, `req`).
7. **Trap 13 (corpus 278): un-parenthesised address-of-index casts** in 8 sites.
   FIX: parenthesise every `(&ARR[idx]) as *T`.
8. **M4 over-counting in `eg_apply_rule`:** double-increment of the union counter
   per merge. FIX: count exactly one union event per non-trivial merge.
9. **M2 union tie-break left implicit.** FIX: pinned to lower-id-wins on equal
   rank so the canonical forest is a deterministic function of the op sequence.
10. **Redundant double calls** (`ident_eq` in `eg_intern_symbol`, `eg_node_matches`
    in `eg_lookup`) — correctness-neutral but wasteful and a re-entrancy hazard if
    the callee had side effects. FIX: one call per probe into a local.
11. **Witness / capability posture (M6/M8/M10):** the engine is a pure in-memory
    algebraic structure at R0; it does not itself emit witness fragments or gate
    on capabilities — that is the consumer's (`cg_superopt`) responsibility, which
    wraps each accepted rewrite in a ratifiable, witnessed step (M16/M12). NOTE
    recorded so the wave scheduler/consumer knows egraph is the *mechanism* and
    the *certificate* is layered above it. Determinism (M2) + the
    `ident_from_bytes` (Keccak256) content-addressed hash key make every egraph
    state **byte-reproducible from the operation log** (M10-compatible).

What is verified-good in the gospel and retained: the union-find by rank + path
compression (`eg_find`/`eg_union` are already iterative/W15-clean), the open-
addressed hashcons probe structure, the canonical-children-before-hash rebuild
strategy, the flat-preorder skeleton encoding with arity-in-bits-16..23, the
min-cost DP + preorder-emit shape of extraction, and the power-of-two
mask-not-modulo slot reduction.

## Implementation Skeleton
```iii
/* III/STDLIB/iii/numera/egraph.iii
 *
 * III STDLIB - numera::egraph
 *
 * E-graphs with deterministic, bounded equality saturation and
 * minimum-cost extraction.  Single global instance (NOT reentrant):
 * all scratch + worklists are module-scope (Trap 7).  Congruence via
 * union-find + open-addressed hashcons; saturation = bounded rule
 * application + rebuild; extraction = bounded min-cost DP + preorder
 * emit.  No recursion (W15): the matcher and instantiator use explicit
 * worklist stacks.  No modulo (slot reduction is a power-of-two mask).
 *
 * Hexad: kind_essence.  Ring: R0.  K: 0.99.
 * Discipline: W2, W8, W13, W14, W15.
 */

module numera_egraph

extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_eq(a: *u8, b: *u8) -> u8 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"

const EGRAPH_OK           : i32 =  0i32
const EGRAPH_E_FULL       : i32 = -1i32
const EGRAPH_E_BAD        : i32 = -2i32
const EGRAPH_E_RULE       : i32 = -3i32
const EGRAPH_SENT         : u32 = 0xFFFFFFFFu32
const EGRAPH_INF_COST     : u32 = 0xFFFFFFFFu32

const EGRAPH_MAX_SYMS     : u32 = 4096u32
const EGRAPH_MAX_NODES    : u32 = 131072u32
const EGRAPH_MAX_CLASS    : u32 = 131072u32
const EGRAPH_MAX_CHILDREN : u32 = 8u32
const EGRAPH_HT_SIZE      : u64 = 262144u64
const EGRAPH_HT_MASK      : u64 = 262143u64
const EGRAPH_MAX_RULES    : u32 = 256u32
const EGRAPH_RULE_AREA    : u32 = 65536u32
const EGRAPH_MAX_VARS     : u32 = 16u32
const EGRAPH_MAX_PASSES   : u32 = 4096u32
const EGRAPH_KEYBUF_CAP   : u64 = 64u64
const EGRAPH_MATCH_STK    : u32 = 8192u32
const EGRAPH_INST_STK     : u32 = 8192u32
const EGRAPH_EXT_STK_CAP  : u32 = 131072u32
const EGRAPH_SYMBYTES     : u64 = 32u64

/* Symbol table: a symbol is a 32-byte identifier. */
var EGRAPH_SYM_LIVE  : [u8;  4096]
var EGRAPH_SYM_ID    : [u8;  131072]
var EGRAPH_SYM_USED  : u32 = 0u32

/* E-nodes: symbol slot + up to 8 child eclass ids (stride 8). */
var EGRAPH_N_LIVE    : [u8;  131072]
var EGRAPH_N_SYM     : [u32; 131072]
var EGRAPH_N_NARGS   : [u32; 131072]
var EGRAPH_N_ARGS    : [u32; 1048576]
var EGRAPH_N_ECLASS  : [u32; 131072]
var EGRAPH_N_USED    : u32 = 0u32

/* E-classes: union-find. */
var EGRAPH_CL_LIVE   : [u8;  131072]
var EGRAPH_CL_PAR    : [u32; 131072]
var EGRAPH_CL_RANK   : [u32; 131072]
var EGRAPH_CL_USED   : u32 = 0u32

/* Hashcons: (sym,args) -> node id, open addressing. */
var EGRAPH_HT_LIVE   : [u8;  262144]
var EGRAPH_HT_NODE   : [u32; 262144]

/* Rewrite rules: flat preorder skeletons in a shared arena. */
var EGRAPH_RULE_LIVE    : [u8;  256]
var EGRAPH_RULE_LHS_OFF : [u32; 256]
var EGRAPH_RULE_LHS_LEN : [u32; 256]
var EGRAPH_RULE_RHS_OFF : [u32; 256]
var EGRAPH_RULE_RHS_LEN : [u32; 256]
var EGRAPH_RULE_BUF     : [u32; 65536]
var EGRAPH_RULE_USED    : u32 = 0u32

/* Hoisted scratch (Trap 7 -- no in-function var arrays). */
var EGRAPH_KEYBUF    : [u8;  64]
var EGRAPH_HASHOUT   : [u8;  32]
var EGRAPH_CANON     : [u32; 8]
var EGRAPH_BINDS     : [u32; 16]
var EGRAPH_SYMBUF    : [u8;  32]
var EGRAPH_IARGS     : [u32; 8]
var EGRAPH_CLASS_COST : [u32; 131072]
var EGRAPH_CLASS_NODE : [u32; 131072]

/* Explicit worklist stacks (W15 recursion elimination). */
var EGRAPH_M_POS     : [u32; 8192]
var EGRAPH_M_CLS     : [u32; 8192]
var EGRAPH_M_CHOICE  : [u32; 8192]
var EGRAPH_M_BSAVE   : [u32; 131072]   /* MATCH_STK * MAX_VARS */
var EGRAPH_I_POS     : [u32; 8192]
var EGRAPH_I_ARITY   : [u32; 8192]
var EGRAPH_I_ACC     : [u32; 65536]    /* INST_STK * 8 */
var EGRAPH_EXT_STK   : [u32; 131072]

/* ---- private helpers ---- */
fn eg_sym_id_ptr(slot: u32) -> *u8 { /* TODO: (&EGRAPH_SYM_ID[(slot as u64)&0xFFFFFFFFu64 * 32u64]) as *u8 -- see Algorithm */ }
fn eg_new_class() -> u32 { /* TODO: bump-allocate a class; full -> EGRAPH_SENT (Algorithm) */ }
fn eg_hash_key(sym: u32, args: *u32, n: u32) -> u64 { /* TODO: serialize into EGRAPH_KEYBUF, ident_from_bytes once, fold 8 LE bytes, & EGRAPH_HT_MASK (Algorithm; Trap 5/11/13) */ }
fn eg_node_matches(node: u32, sym: u32, args: *u32, n: u32) -> u8 { /* TODO: sym/arity/child-eq under one sentinel flag (Algorithm; W14) */ }
fn eg_lookup(sym: u32, args: *u32, n: u32) -> u32 { /* TODO: open-addressing probe, mask wrap, bounded by EGRAPH_HT_SIZE (Algorithm) */ }
fn eg_ht_insert(sym: u32, args: *u32, n: u32, node: u32) -> i32 { /* TODO: probe to first empty, store (LIVE,NODE) (Algorithm) */ }
fn eg_match(rid: u32, root_node: u32) -> u8 { /* TODO: explicit-stack DFS over (skel_pos,class) obligations w/ binding snapshots; first match in id order; bounded by EGRAPH_MATCH_STK (Algorithm; W15) */ }
fn eg_instantiate(rid: u32) -> u32 { /* TODO: explicit post-order build stack; eg_add per completed frame; bounded by EGRAPH_INST_STK (Algorithm; W15) */ }
fn eg_apply_rule(rid: u32) -> u32 { /* TODO: for each live node match+instantiate+union; count one union per non-trivial merge (Algorithm; M4) */ }

/* ---- public API ---- */
fn eg_init() -> i32 @export { /* TODO: zero all *_LIVE, wipe HT, reset *_USED (Algorithm) */ }
fn eg_intern_symbol(sym_id: *u8) -> u32 @export { /* TODO: linear scan via ident_eq (one call/slot), else copy+bump; full -> EGRAPH_SENT (Algorithm) */ }
fn eg_find(a: u32) -> u32 @export { /* TODO: iterative path-compressing find (Algorithm; W15-clean) */ }
fn eg_add(sym_id: *u8, children: *u32, n: u32) -> u32 @export { /* TODO: intern sym, canon children, hashcons lookup-or-create, return class (Algorithm) */ }
fn eg_union(a: u32, b: u32) -> u32 @export { /* TODO: union by rank, lower-id-wins on tie (Algorithm; M2) */ }
fn eg_rebuild() -> u32 @export { /* TODO: bounded congruence closure; passes<EGRAPH_MAX_PASSES; return pass count (Algorithm; M19/W14) */ }
fn eg_register_rule(rule: *u32) -> u32 @export { /* TODO: parse [lhs_n,rhs_n,lhs...,rhs...], validate, copy into RULE_BUF, return rid (Algorithm) */ }
fn eg_saturate(max_steps: u32) -> u32 @export { /* TODO: bounded apply-all-rules + rebuild to fixpoint or max_steps; return steps (Algorithm; M19/W14) */ }
fn eg_extract(req: *u32, out_term: *u32, out_n: *u32) -> i32 @export { /* TODO: bounded min-cost DP into EGRAPH_CLASS_COST/NODE, then preorder emit via EGRAPH_EXT_STK; req=[root,sym_count,costs...] (Algorithm; M19) */ }
fn eg_class_count() -> u32 @export { /* TODO: count live EGRAPH_CL_LIVE (Algorithm) */ }
fn eg_node_count() -> u32 @export { /* TODO: count live EGRAPH_N_LIVE (Algorithm) */ }
fn eg_selftest() -> u64 @export { /* TODO: run KAT 1-5; 99u64 on pass else failing index (KAT Vectors; W12) */ }
```
