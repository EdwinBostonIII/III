# 42 aether/immune_scrub.iii — Implementation Spec

## Verdict
PARTIAL — the gospel candidate body is algorithmically complete and the Hilbert d2xy core is correct, but it is **not paste-ready**: it carries function-local `var [..]` arrays (Trap 7), the W3-forbidden `&ARR[idx]` element-address idiom throughout, a one-parameter/no-parameter API drift in the doc header vs. the bodies, the assigned `ISCRUB_` prefix is not applied (body uses `IS_`), and its sole block-scrub dependency (`fs_scrub_block` from a Reed-Muller-refined `fs.iii`) is **not-yet-built** (the realized `aether/fs.iii` is a plain POSIX IO surface, not the gospel's RM-encoded filesystem). All gaps are mechanical/orderly; the maximal intent is fully realizable.

## Purpose
`aether::immune_scrub` is the substrate's deterministic memory-integrity sweep: it walks every block of every registered region in **Hilbert-curve (locality-preserving) order** and invokes the per-block Reed-Muller scrubber on each, so that spatially-correlated corruption (a thermal/power burst over one physical bank) surfaces in temporally-adjacent steps. It is a permutation generator + traversal driver, not an ECC engine — the codeword decode/correct lives behind `fs_scrub_block`. Each completed pass publishes an `IMMUNE_SCRUB_BASELINE`/`IS_SCRUB_PASS` witness fragment. **Hexad: kind_repair + kind_witness. Ring: R0. K: 0.99.**

## Public API
All public fns return a status (W12). `is_d2xy` and `is_init` use the negative-`i32` convention (W9); the registry/traversal fns return `u32` counts/ids with `0xFFFFFFFFu32` as the registration-full sentinel (W9 ordering compares avoided).

```
fn is_init() -> i32 @export
fn is_register_region(cap_id: u64, file_id: u32, n_blocks: u32) -> u32 @export
fn is_scrub_step(region_id: u32) -> u32 @export
fn is_run_full_pass(region_id: u32) -> u32 @export
fn is_region_count() -> u32 @export
fn is_d2xy(order: u32, d: u64, out_x: *u32, out_y: *u32) -> i32 @export
```

Return-status notes:
- `is_init` → `ISCRUB_OK (0i32)` always.
- `is_register_region` → region id `[0, ISCRUB_MAX_REGIONS)` on success, sentinel `0xFFFFFFFFu32` when the table is full (W8 bound) or the capability is denied. (Maximal-intent: `cap_id` added vs. the gospel's 2-arg form — see Gap/Fix #7. A Phase-2 fallback that keeps the gospel's `is_register_region(file_id, n_blocks)` is acceptable only if the convergence drops M8 at this layer; default is the 3-arg capability-gated form.)
- `is_scrub_step` → bit-errors corrected on the one block visited this step (`0u32` if the step landed on a hole `linear >= n_blocks`, on wrap, or on a dead/oob region).
- `is_run_full_pass` → total bit-errors corrected across the whole region; also publishes the pass witness.
- `is_region_count` → number of registered regions (`ISCRUB_USED`).
- `is_d2xy` → `ISCRUB_OK`; writes `*out_x`,`*out_y`. (Pure; the one fn safe to call with no side effects.)

## Constant Namespace
**PREFIX = `ISCRUB_`** . Grep result: `^const ISCRUB_` and `\bISCRUB_\b` → **zero matches** in `STDLIB/` (no collision). Independently, `^const IS_` → **zero matches** as well, but the dispatch assigns `ISCRUB_`, so every module-level const and `var` is renamed `IS_*` → `ISCRUB_*`.

| const | type | value | note |
|---|---|---|---|
| `ISCRUB_OK` | `i32` | `0i32` | success |
| `ISCRUB_E_BAD` | `i32` | `-1i32` | error (W9 negative) |
| `ISCRUB_MAX_REGIONS` | `u32` | `64u32` | W8 static table bound (justified below) |
| `ISCRUB_PILLAR` | `u16` | `4u16` | witness pillar id for the scrub pass (gospel uses 4u16) |
| `ISCRUB_PHASE` | `u8` | `8u8` | witness phase id (Phase Eight baseline; gospel uses 8u8) |

Rationale for promoting the gospel's literal `4u16`/`8u8` to named consts: M2/W5 bit-identity auditability — the witness pillar/phase that feed the fragment-id hash must be a single named source of truth.

## Data Structures
All module-scope (Trap 7: **no local `var` arrays**). The per-region SoA arrays are sized to `ISCRUB_MAX_REGIONS = 64`. **Bound justification (W8):** the gospel's Phase-Eight integration registers one region per filesystem subtree (constitutional source, KAT corpus, compiled-binary, witness-chain) — a single-digit count; 64 gives ~16× headroom for federated/multi-epoch subtrees while staying a trivially RIP-reachable static footprint. Byte buffers are declared `[u8; N]` (small; the 8-bytes-per-element iiis slot model is irrelevant at these sizes).

| name | type | size (elems) | purpose |
|---|---|---|---|
| `ISCRUB_LIVE` | `[u8; 64]` | 64 | per-region live flag (1 = registered) |
| `ISCRUB_FILE_ID` | `[u32; 64]` | 64 | fs file/subtree handle per region |
| `ISCRUB_N_BLOCKS` | `[u32; 64]` | 64 | block count per region |
| `ISCRUB_ORDER` | `[u32; 64]` | 64 | Hilbert order n (side = 2^n) per region |
| `ISCRUB_D_HEAD` | `[u64; 64]` | 64 | next Hilbert index `d` to visit (step cursor) |
| `ISCRUB_TOTAL_ERR` | `[u64; 64]` | 64 | lifetime bit-errors corrected per region |
| `ISCRUB_CAP_ID` | `[u64; 64]` | 64 | capability id bound at registration (maximal-intent; see Gap #7) |
| `ISCRUB_USED` | `u32` (scalar) | — | count of registered regions |
| `ISCRUB_INITED` | `u8` (scalar) | — | one-shot init guard |
| `ISCRUB_PRODUCER` | `[u8; 32]` | 32 | ident("aether::immune_scrub") — witness producer |
| `ISCRUB_OPID_PASS` | `[u8; 32]` | 32 | ident("aether::immune_scrub::pass") — witness opid |
| `ISCRUB_IN_C` | `[u8; 32]` | 32 | scratch: pass witness in-commit (hoisted from local) |
| `ISCRUB_OUT_C` | `[u8; 32]` | 32 | scratch: pass witness out-commit (hoisted from local) |
| `ISCRUB_PAYLOAD` | `[u8; 16]` | 16 | scratch: 4B region_id ‖ 4B total ‖ 8B lifetime-err |
| `ISCRUB_FRAG_ID` | `[u8; 32]` | 32 | scratch: wh_publish out_frag_id sink |
| `ISCRUB_DX` | `[u32; 1]` | 1 | scratch: d2xy x sink (replaces local `var xx`) |
| `ISCRUB_DY` | `[u32; 1]` | 1 | scratch: d2xy y sink (replaces local `var yy`) |

Reentrancy note: the scratch buffers (`ISCRUB_IN_C`…`ISCRUB_DY`) make `is_scrub_step` / `is_run_full_pass` **non-reentrant** — acceptable per the serialized-scrubber ontology (one sweep at a time; the substrate drives passes sequentially in Phase Eight). Flag carried to Gap list.

## Dependencies (externs)
All declared `extern @abi(c-msvc-x64) ... from "<file>"`.

| extern | from | provider NN | built? |
|---|---|---|---|
| `fn fs_scrub_block(file_id: u32, block_idx: u32) -> u32` | `"fs.iii"` | **41** (`aether/fs.iii` *Reed-Muller refinement*) | **NOT-YET-BUILT** ⚠ |
| `fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32` | `"identifier.iii"` | (built) numera/identifier.iii:33 | **BUILT** ✓ |
| `fn wh_publish(producer:*u8, opid:*u8, in_commit:*u8, out_commit:*u8, revtag:u8, phase:u8, pillar:u16, antecedents:*u8, n_ante:u32, payload:*u8, payload_len:u32, out_frag_id:*u8) -> u64` | `"witness_hook.iii"` | 07 aether/witness_hook.iii:144 | **BUILT** ✓ |
| `fn wh_chain_root(out_id: *u8) -> i32` | `"witness_hook.iii"` | 07 aether/witness_hook.iii:216 | **BUILT** ✓ |

**Verified signature matches (read from the real provider files):**
- `wh_publish` and `wh_chain_root` — gospel externs match `witness_hook.iii` **byte-for-byte** (same params, order, return). No §3.5 defect present here (the gospel body already routes through `wh_publish`, not the fictional `ws_emit_fragment`). ✓
- `ident_from_bytes` — matches `numera/identifier.iii` exactly. ✓

**The one blocking dependency — `fs_scrub_block`:** the realized `aether/fs.iii` (read in full) is a **capability-gated POSIX IO surface** (`fs_open/read/write/seek/size/delete` over `_open/_read/...`, gated by `cap_verify_rights`). It exports **no `fs_scrub_block`** and has **no Reed-Muller codeword layer**. The gospel (manifest line 669: "`aether/fs.iii` (refined to Reed Muller encoded blocks)"; narrative line 13835: "the Reed Muller encoded filesystem") intends `fs.iii` *Module 41* to grow an RM-encoded block layer whose `fs_scrub_block(file_id, block_idx) -> u32` decodes each codeword, majority-votes under the W22 distance bound, rewrites corrected codewords in place, and returns the count of bit-errors corrected. **That refinement is not realized.** Module 42's extern (file + signature) is correct *as the gospel specifies Module 41*, but the wave scheduler MUST build the Module-41 RM-scrub layer before Module 42 can link/run. This is the same family as the §3.5 "extern points at the wrong/unbuilt provider" class.

## Algorithm

### `is_init()` — one-shot registry clear + identity precompute
Zero `ISCRUB_LIVE[0..64)`, set `ISCRUB_USED = 0`. Compute the two witness identifiers once: `ident_from_bytes("aether::immune_scrub", 20, ISCRUB_PRODUCER)` and `ident_from_bytes("aether::immune_scrub::pass", 26, ISCRUB_OPID_PASS)` (Keccak256 ids — deterministic, M2). Set `ISCRUB_INITED = 1`. Determinism: pure array writes + fixed-string hashes; no time/entropy.

### `is_compute_order(n_blocks)` — private, ceil(log2)/2
Hand-rolled (M1) integer log: multiply `total *= 2`, count `bits`, until `total >= n_blocks` (sentinel loop, W14; no `break`). Hilbert order n covers `4^n = 2^(2n)` cells, so the smallest n with `4^n >= n_blocks` is `n = ceil(bits/2) = (bits + 1)/2`. No FP (M2). Edge cases: `n_blocks <= 1` → `bits = 0` → order 0 (1×1 grid, single cell d∈{0}); audited correct. **Could be replaced by `bitops_log2_floor64` from numera/bitops.iii** but the hand-rolled loop is self-contained and keeps the extern surface minimal — keep as-is (note in skeleton).

### `is_register_region(cap_id, file_id, n_blocks)`
Lazy-init (`if ISCRUB_INITED == 0u8 { is_init() }`). Maximal-intent capability gate (M8): require the scrub/repair right on `cap_id` via the fs/capability layer before admitting a region — Phase-2 binds the exact right-bit (see Gap #7); if the convergence elects the gospel's ungated 2-arg form, this check is omitted. Bound check `if ISCRUB_USED >= ISCRUB_MAX_REGIONS { return 0xFFFFFFFFu32 }` (W8, sentinel — equality/`>=` on **u32** is unsigned and safe; Trap 3 is signed-only). Allocate `r = ISCRUB_USED`, bump, populate `LIVE/FILE_ID/N_BLOCKS/CAP_ID`, set `ORDER = is_compute_order(n_blocks)`, zero `D_HEAD`/`TOTAL_ERR`. Return `r`. Deterministic: monotonic slot allocation.

### `is_d2xy(order, d, out_x, out_y)` — the canonical Hilbert decoder (M1, hand-rolled)
Explicit-stack-free iterative form (no recursion, W15). Locals `x=0,y=0,t=d,s=1`, `side = 1u32 << order`. Sentinel loop `while s < side` (W14):
1. `rx = ((t >> 1) & 1) as u32`
2. `ry = ((t ^ (rx as u64)) & 1) as u32` — canonical `ry = 1 & (t ^ rx)`.
3. Rotation: `if ry == 0u32 { if rx == 1u32 { x = s - 1u32 - x; y = s - 1u32 - y } let tmp = x; x = y; y = tmp }` (`} else {`/`{ }` all single-line per Trap 8).
4. Accumulate `x += s*rx`, `y += s*ry`; `t = t / 4u64`; `s = s*2u32`.

Write `*out_x = x`, `*out_y = y`; return `ISCRUB_OK`. **Determinism/bit-identity (M2/W5):** pure integer ops over fixed bit widths, identical permutation of `[0, 4^order)` on every CPU. **No `%` anywhere** (uses `/4` and bit-AND only) — Trap 11 not triggered. Audit of the math: matches the Wikipedia/“Hacker’s Delight” reference `d2xy`; verified by hand on order=1 and order=2 (see KATs). One subtlety flagged: `order = 0` → `side = 1` → loop body never runs → returns (0,0) for the single cell; correct.

### `is_scrub_step(region_id)` — advance exactly one *occupied* curve position
Guards: `if region_id >= ISCRUB_MAX_REGIONS { return 0u32 }`, `if ISCRUB_LIVE[region_id] == 0u8 { return 0u32 }` (unsigned compares, safe). `order = ISCRUB_ORDER[region_id]`, `max_d = 1u64 << (2*order)`. Sentinel loop on `done` (W14, no `break`): read `d = ISCRUB_D_HEAD[region_id]`; if `d >= max_d` reset cursor to 0 and finish (wrap → return 0). Else compute `is_d2xy(order, d, &ISCRUB_DX[0], &ISCRUB_DY[0])`, `linear = ISCRUB_DY[0]*side + ISCRUB_DX[0]`, advance `D_HEAD = d+1`; if `linear < ISCRUB_N_BLOCKS[region_id]` invoke `errs = fs_scrub_block(ISCRUB_FILE_ID[region_id], linear)`, accumulate into `TOTAL_ERR`, and finish. **The loop skips holes** (`linear >= n_blocks` — cells of the 2^n square outside the linear block range) without consuming a "real" step, so each *returned* step corresponds to one genuine block. Determinism: traversal order is the fixed Hilbert permutation; `fs_scrub_block` is itself deterministic (RM decode is algebraic, M2). Trap 4 note: `linear`, `ISCRUB_FILE_ID[..]` are `u32` used only as call args / compared, not as pointer-arithmetic indices, so no `as u64` masking needed here.

### `is_run_full_pass(region_id)` — complete one Hilbert sweep + publish witness
Guards as above. Reset `D_HEAD = 0`. `order`, `max_d = 1u64 << (2*order)`, `total = 0u32`. Sentinel loop `while d < max_d` (W14): d2xy → `linear` → `if linear < n_blocks { total += fs_scrub_block(file_id, linear) }`; `d += 1`. Accumulate `TOTAL_ERR += total`.
**Witness publication (M6/M10):** `wh_chain_root(ISCRUB_IN_C)` for the in-commit; build the 16-byte payload in `ISCRUB_PAYLOAD` little-endian: bytes 0–3 = region_id, 4–7 = total, 8–15 = `TOTAL_ERR[region_id]` (the 8-byte loop uses `(v >> (z*8)) & 0xFF` — Trap 11: `*` not `%`, and the shift is a constant stride, safe). `ident_from_bytes(ISCRUB_PAYLOAD, 16, ISCRUB_OUT_C)` for the out-commit. `wh_publish(ISCRUB_PRODUCER, ISCRUB_OPID_PASS, ISCRUB_IN_C, ISCRUB_OUT_C, 0u8 /*revtag*/, ISCRUB_PHASE, ISCRUB_PILLAR, ISCRUB_PAYLOAD /*antecedents, unused*/, 0u32 /*n_ante*/, ISCRUB_PAYLOAD, 16u32, ISCRUB_FRAG_ID)`. Return `total`. **M10 reproducibility:** out-commit and frag-id are pure functions of (region_id, total, lifetime-err) + the chain root, all recorded.

### `is_region_count()` → return `ISCRUB_USED`.

## KAT Vectors (>= 3)
Self-test convention: a `is_selftest() -> u64` returning `99u64` on full pass (matching the house `wh_selftest` idiom), returning a small distinct code at the first failing assertion.

1. **d2xy order-1 (4 cells) — the base Hilbert "U".** `order=1`: `is_d2xy(1, 0)→(0,0)`; `is_d2xy(1,1)→(0,1)`; `is_d2xy(1,2)→(1,1)`; `is_d2xy(1,3)→(1,0)`. (Canonical first-order Hilbert curve; verifies the rotation+swap branch for `d=0` and the accumulate for `d=1..3`.) Byte-checked on all four `(x,y)` pairs.
2. **d2xy order-2 (16 cells) — locality + permutation.** `is_d2xy(2, d)` for `d=0..15` must yield each of the 16 grid cells `(x,y)∈[0,4)^2` **exactly once** (it is a bijection), and **consecutive** d's must be 4-neighbors (|Δx|+|Δy| == 1). Spot anchors: `d=0→(0,0)`, `d=1→(1,0)`, `d=2→(1,1)`, `d=3→(0,1)`, `d=15→(3,0)`. Test asserts the full 16-entry table + the adjacency invariant (this is the locality-preserving property the module exists for).
3. **compute_order boundaries.** `is_compute_order(1)→0`, `(2)→1`, `(4)→1`, `(5)→2`, `(16)→2`, `(17)→3`. (4^order >= n_blocks with order minimal: 4^1=4>=4 but <5; 4^2=16>=16 but <17.) Byte-checked.
4. **Registration + count + full-pass over a stub fs.** With a Phase-2 test `fs_scrub_block` stub that returns a fixed deterministic schedule (e.g. `1` for even `block_idx`, `0` otherwise): `is_init()`; `r = is_register_region(cap, file=7, n_blocks=10)` ⇒ `r==0`; `is_region_count()==1`; `is_run_full_pass(0)` visits the 16 cells of order-2, of which exactly the 10 with `linear<10` call the stub, summing the even-indexed ones ⇒ a fixed expected total (5 if {0,2,4,6,8} are hit) and `ISCRUB_TOTAL_ERR[0]` equals that total; a second `is_run_full_pass(0)` doubles `TOTAL_ERR`. Asserts the count, the per-pass total, and the lifetime accumulation. Also asserts `wh_next_idx()` advanced by 1 per pass (witness published).
5. **scrub_step hole-skip + wrap.** Fresh region `n_blocks=3`, order=1 (4 cells, 1 hole at `linear==3`→`(1,0)` is linear 1*2+0... — compute exact hole from KAT-1 mapping): four successive `is_scrub_step` calls must each return a real-block result for the 3 in-range cells and the step that lands on the out-of-range cell skips internally so every returned step is a real block; the 4th conceptual position wraps `D_HEAD` back to 0. Asserts cursor wrap (`ISCRUB_D_HEAD[r]==0` after a full cycle).

(KATs 1–3 are pure and need no fs stub — they alone gate the Hilbert core. KATs 4–5 require the Phase-2 deterministic `fs_scrub_block` test double, since the real provider is not-yet-built.)

## Trap Exposure
- **Trap 1 (multi-line `fn`)** — EXPOSED by length of `wh_publish` *call* (not a decl). All six `fn` **signatures are single-line** (longest is `is_register_region(cap_id: u64, file_id: u32, n_blocks: u32) -> u32 @export`, well within one line). The multi-line `wh_publish` *extern* declaration and *call* are statements/expressions, not `fn` decls — Trap 1 governs declarations only; still, the skeleton writes the extern on continuation lines exactly as `witness_hook.iii`/`hotstuff.iii` do (proven to compile).
- **Trap 2 (const linker-global)** — EXPOSED. Mitigated: every const/var prefixed `ISCRUB_`; grep-confirmed unique.
- **Trap 3 (signed ordering SIGSEGV)** — NOT triggered. All ordering compares (`s < side`, `d >= max_d`, `d < max_d`, `region_id >= MAX`, `linear < n_blocks`, `total < n_blocks` in compute_order) are on **unsigned** `u32`/`u64`. The only `i32` values (`ISCRUB_OK/E_BAD`, `is_d2xy`/`is_init` returns) are compared with `==`/`!=` if at all.
- **Trap 4 (u32-in-u64-slot before ptr math)** — Mostly N/A: `linear`/`file_id` flow into call args, not pointer arithmetic. Element addresses use the `((&ARR as u64) + idx*stride) as *u8` form where `idx` is already `u64` or a small constant. **If** Phase-2 indexes any per-region `u32` into pointer math, mask `(x as u64) & 0xFFFFFFFFu64` first. Flagged.
- **Trap 5 (u32 store width)** — N/A: the byte-by-byte payload stores go through `*u8` pointers writing `... as u8` (single bytes), never a `*u32` store.
- **Trap 6 / Trap 9 (nested `/* */` / em-dash)** — Avoidance: header comment is a single non-nested block; **ASCII `--` only**, no `—`, no inner `*/`.
- **Trap 7 (local `var` arrays)** — **EXPOSED in the gospel body** (`var in_c/out_c/pl/fid : [u8;..]`, `var xx/yy : u32`). **Fix: every such buffer is hoisted to a module-scope `ISCRUB_*` array** (see Data Structures). Local scalars (`let mut x : u32`, etc.) are fine.
- **Trap 8 (`} else {` one line)** — Avoidance: no multi-line else; the d2xy rotation block keeps `{ }` openers inline.
- **Trap 10 (`let mut flag` checkpoint)** — MINOR exposure: `is_scrub_step` uses `let mut done : u8` as a loop flag. This is the *sentinel-loop* pattern (W14), not a misused checkpoint flag, and `done` drives the `while done == 0u8` condition directly — safe. (Audited against the known let-mut-flag bug: that bug is a flag that does NOT drive its own loop; here it does.)
- **Trap 11 (`% ` after call)** — NOT triggered. No modulo anywhere; Hilbert uses `/4` + bit-AND, payload uses `>> (z*8) & 0xFF`.
- **Trap 12 (`@specialize *T` stride)** — N/A: module is non-generic, no `@specialize`.
- **W3 element-address (house rule, beyond the 12)** — **EXPOSED in the gospel body** (`&IS_PRODUCER[0u64] as *u8`, `&IS_LIVE[i]`, `&pl[0u64]`, etc.). The built aether modules explicitly forbid `&GLOBAL[0]` (http_client.iii:40, net.iii:114) and use `(&ARR as u64) as *u8` / `((&ARR as u64)+off) as *u8` (hotstuff.iii:105,206-207). **Fix: rewrite every element-address to the `as u64`-cast form**; array element *writes/reads* via `ARR[i] = ...` indexing are fine (only the address-of-element idiom is the problem).

## Gap / Fix List
1. **`fs_scrub_block` provider not-yet-built (BLOCKING).** Realized `aether/fs.iii` is POSIX IO, not the gospel's RM-encoded fs. *Fix:* keep the extern `from "fs.iii"` with signature `(u32,u32)->u32` (correct per gospel Module 41), and mark Module 41's Reed-Muller refinement as a wave-ordering predecessor. Module 42 cannot link until then; KATs 4–5 use a deterministic test double. The decode/correct must honor **W22** (correction bounded by half min-distance; uncorrectable → reported, never silently miscorrected) — that is Module 41/43's contract, but Module 42 relies on `fs_scrub_block`'s return being the *true* corrected-error count.
2. **Trap 7 — function-local `var` arrays.** *Fix:* hoist `in_c,out_c,pl,fid → ISCRUB_IN_C/OUT_C/PAYLOAD/FRAG_ID`; `xx,yy → ISCRUB_DX[1]/ISCRUB_DY[1]`. (Makes the two traversal fns non-reentrant — acceptable, serialized scrubber.)
3. **W3 element-address idiom.** *Fix:* `&IS_X[k] as *u8` → `((&ISCRUB_X as u64) + k*stride) as *u8`; bare base `&IS_X[0u64] as *u8` → `(&ISCRUB_X as u64) as *u8`.
4. **Prefix not applied.** Gospel body uses `IS_`; dispatch assigns `ISCRUB_`. *Fix:* rename all consts/vars (and the witness id strings stay `"aether::immune_scrub"` — those are data, not symbols).
5. **API header/body mismatch in the gospel.** The doc-comment lists `is_scrub_step()` with **no** parameter, but the body is `is_scrub_step(region_id: u32)`; the comment lists `is_register_region(file_id, n_blocks)` (2-arg). *Fix:* canonical API is the **body** form (`is_scrub_step(region_id)`), and `is_register_region` is upgraded to the 3-arg capability form (#7); the header comment is corrected to match.
6. **Named witness pillar/phase.** Gospel inlines `4u16`/`8u8`. *Fix:* promote to `ISCRUB_PILLAR`/`ISCRUB_PHASE` for M2 auditability (single source feeding the frag-id hash).
7. **M8 capability mediation (maximal-intent upgrade).** Scrubbing is `kind_repair` — a privileged *mutating* action (it rewrites corrected codewords in place). The gospel's `is_register_region` takes no capability. *Fix (default, Path-A maximal):* add `cap_id: u64` to `is_register_region`, store it in `ISCRUB_CAP_ID[r]`, verify the scrub/repair right at registration (and optionally re-check at pass time). The exact right-bit + the verifier (`cap_verify_rights` from `capability.iii`, as `fs.iii` itself uses) is bound in Phase 2 once Module 41 fixes the per-block right semantics. *Note:* defense-in-depth — `fs_scrub_block` is the hard enforcement point at the fs layer; the registration gate prevents an uncapable caller from even enrolling a region. If the convergence rules M8 is satisfied solely at the fs layer, the 2-arg gospel form is a permitted fallback (documented).
8. **No `break`, no recursion — already clean.** Verified: all loops are sentinel/counter-driven (W14), no `break`, no self-call (W15). Locals per fn ≤ ~10 (W13 ≤20 ok); params ≤ 4 (W2 ok — the 3-arg `is_register_region` and 4-arg `is_d2xy` are within bound).
9. **Determinism/witness mandates — verified.** M2 (pure integer Hilbert permutation, no FP/entropy/time-read; algebraic time is advanced *inside* `wh_publish` via `at_advance`, not read here — correct, W17 monotonic). M6/M10 (every pass publishes a frag whose out-commit + id are recomputable from recorded payload). M3/M4 (no counting-to-adapt, no thresholds, no heuristics — the corrupt-block count is *recorded* for the context pillar to sample, never used to *change behavior* here; confirmed against narrative line 21882). M5 (no bricking — a hole/oob/dead region returns 0, never faults; cursor wrap is safe). M19 (cost bounded: `is_run_full_pass` is exactly `4^order` iterations, `4^order < 4 * n_blocks` by the order choice, i.e. O(n_blocks)).

**If COMPLETE (the parts that are):** the d2xy decoder, `is_compute_order`, the SoA registry layout, the witness-payload encoding, and the `wh_publish`/`wh_chain_root`/`ident_from_bytes` extern signatures are all correct and verified against the real providers — Phase 2 implements those verbatim (after the mechanical Trap-7/W3/prefix rewrites).

## Implementation Skeleton
```iii
/* III/STDLIB/iii/aether/immune_scrub.iii
 *
 * III STDLIB - aether::immune_scrub
 *
 * Deterministic Hilbert-curve memory scrubber. Each registered region is
 * walked in Hilbert (locality-preserving) order; per occupied block the
 * Reed-Muller block scrubber (fs_scrub_block) is invoked. A full pass
 * publishes an IS_SCRUB_PASS witness fragment.
 *
 * Public API:
 *   is_init() -> i32
 *   is_register_region(cap_id: u64, file_id: u32, n_blocks: u32) -> u32
 *     Register a region of n_blocks blocks under fs handle file_id, gated by
 *     cap_id. Returns region id, or 0xFFFFFFFF if full / denied.
 *   is_scrub_step(region_id: u32) -> u32
 *     Advance one occupied Hilbert position; returns bit-errors corrected.
 *   is_run_full_pass(region_id: u32) -> u32
 *     One complete Hilbert pass; returns total errors corrected; publishes witness.
 *   is_region_count() -> u32
 *   is_d2xy(order: u32, d: u64, out_x: *u32, out_y: *u32) -> i32
 *     Pure utility: the canonical Hilbert d2xy mapping.
 *
 * Hexad: kind_repair + kind_witness.  Ring: R0.  K: 0.99.
 * Discipline: W2, W3, W8, W13, W14, W15.  (ASCII -- only in comments.)
 */
module aether_immune_scrub

extern @abi(c-msvc-x64) fn fs_scrub_block(file_id: u32, block_idx: u32) -> u32 from "fs.iii"
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8,
              out_commit: *u8, revtag: u8, phase: u8, pillar: u16,
              antecedents: *u8, n_ante: u32,
              payload: *u8, payload_len: u32,
              out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_chain_root(out_id: *u8) -> i32 from "witness_hook.iii"

const ISCRUB_OK          : i32 =  0i32
const ISCRUB_E_BAD       : i32 = -1i32
const ISCRUB_MAX_REGIONS : u32 = 64u32
const ISCRUB_PILLAR      : u16 = 4u16
const ISCRUB_PHASE       : u8  = 8u8

var ISCRUB_LIVE      : [u8;  64]
var ISCRUB_FILE_ID   : [u32; 64]
var ISCRUB_N_BLOCKS  : [u32; 64]
var ISCRUB_ORDER     : [u32; 64]
var ISCRUB_D_HEAD    : [u64; 64]      // next Hilbert index to visit
var ISCRUB_TOTAL_ERR : [u64; 64]      // lifetime errors corrected
var ISCRUB_CAP_ID    : [u64; 64]      // capability bound at registration
var ISCRUB_USED      : u32 = 0u32
var ISCRUB_INITED    : u8  = 0u8

var ISCRUB_PRODUCER  : [u8; 32]
var ISCRUB_OPID_PASS : [u8; 32]

var ISCRUB_IN_C      : [u8; 32]       // pass witness scratch (hoisted; Trap 7)
var ISCRUB_OUT_C     : [u8; 32]
var ISCRUB_PAYLOAD   : [u8; 16]
var ISCRUB_FRAG_ID   : [u8; 32]
var ISCRUB_DX        : [u32; 1]       // d2xy x sink (replaces local var)
var ISCRUB_DY        : [u32; 1]       // d2xy y sink (replaces local var)

fn is_init() -> i32 @export {
    // TODO: body per Algorithm is_init -- zero ISCRUB_LIVE[0..MAX), ISCRUB_USED=0,
    //       ident_from_bytes for ISCRUB_PRODUCER / ISCRUB_OPID_PASS (base addr via
    //       (&ARR as u64) as *u8), set ISCRUB_INITED=1, return ISCRUB_OK.
}

fn is_compute_order(n_blocks: u32) -> u32 {
    // TODO: body per Algorithm is_compute_order -- sentinel loop total*=2/bits++ until
    //       total>=n_blocks; return (bits+1u32)/2u32.  No break (W14).
}

fn is_register_region(cap_id: u64, file_id: u32, n_blocks: u32) -> u32 @export {
    // TODO: body per Algorithm -- lazy is_init(); (M8) verify cap_id repair-right;
    //       if ISCRUB_USED>=ISCRUB_MAX_REGIONS return 0xFFFFFFFFu32; allocate r,
    //       populate LIVE/FILE_ID/N_BLOCKS/CAP_ID/ORDER/D_HEAD/TOTAL_ERR; return r.
}

fn is_d2xy(order: u32, d: u64, out_x: *u32, out_y: *u32) -> i32 @export {
    // TODO: body per Algorithm is_d2xy -- x=y=0,t=d,s=1,side=1u32<<order;
    //       while s<side { rx,ry; if ry==0 { if rx==1 {mirror} swap } x+=s*rx; y+=s*ry;
    //       t=t/4u64; s=s*2u32 }  *out_x=x; *out_y=y; return ISCRUB_OK.  No %, no break.
}

fn is_scrub_step(region_id: u32) -> u32 @export {
    // TODO: body per Algorithm is_scrub_step -- guards; order; max_d=1u64<<(2*order);
    //       sentinel loop on done: read D_HEAD; wrap if >=max_d; else d2xy into
    //       ISCRUB_DX/DY, linear=DY*side+DX, D_HEAD=d+1; if linear<N_BLOCKS call
    //       fs_scrub_block, accumulate TOTAL_ERR, done=1.  Return errs.
}

fn is_run_full_pass(region_id: u32) -> u32 @export {
    // TODO: body per Algorithm is_run_full_pass -- guards; D_HEAD=0; order; max_d;
    //       while d<max_d { d2xy; linear; if linear<N_BLOCKS total+=fs_scrub_block }
    //       TOTAL_ERR+=total; wh_chain_root(ISCRUB_IN_C); pack ISCRUB_PAYLOAD (region_id|
    //       total|TOTAL_ERR LE); ident_from_bytes->ISCRUB_OUT_C; wh_publish(... ISCRUB_PHASE,
    //       ISCRUB_PILLAR ... 16u32 ... ISCRUB_FRAG_ID); return total.
}

fn is_region_count() -> u32 @export {
    // TODO: return ISCRUB_USED.
}
```
