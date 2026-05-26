# 63 numera/synthesis_search.iii — Implementation Spec

## Verdict
PARTIAL — the gospel candidate body compiles structurally and has the right generate-and-verify skeleton, but it (a) declares all scratch buffers as **local arrays** (Trap 7 — unsupported inside fn bodies; every built numera module hoists these to module scope), (b) **emits no witness fragments** during `sy_search` despite the prose promising a `SYNTH_CANDIDATE` per attempt and a `SYNTH_BUDGET_EXHAUSTED` on exhaustion (M6/M10/W48 gap), (c) **never honors the spec's cost-vector budget** (hardcodes `SY_MAX_ITERATIONS_DEFAULT`, violating M19/W43 — the bound must come from the ratified spec), (d) **runs the loop to `max_iter` even after a hit** so `out_iterations` always reports the cap not the real cost (W14 + M19 cost-accuracy bug), and (e) never validates spec presence/ratification (`SY_E_SPEC_ABSENT` declared but dead; W33 gap).

## Purpose
`synthesis_search` IS the bounded, deterministic program-synthesis **search engine** of Layer 5: given a ratified specification id, it enumerates candidate programs in a fixed deterministic order, submits **every** candidate to the synthesis verifier (`sw_verify_candidate`), and returns the first admissible candidate or a witnessed budget-exhaustion. The candidate **generator is treated as an untrusted oracle** (M15) — its proposals carry no authority; only the verifier's transcript (Module 64) enters the witness chain (W38: no solver output bound without verifier check). Hexad: `kind_cognition`. Ring: **R0**. K_synth: per call (bounded by the spec cost vector).

## Public API
All signatures single-line (Trap 1). Every fn returns negative-`i32` status (W9/W12); booleans n/a.

```
fn sy_init() -> i32 @export
fn sy_set_candidate_generator(generator_module: *u8, generator_fn: *u8) -> i32 @export
fn sy_search(spec_id: *u8, out_candidate_id: *u8, out_iterations: *u32) -> i32 @export
fn sy_emit_candidate(candidate_id: *u8, encoding: *u8, encoding_len: u32, out_frag_id: *u8) -> i32 @export
fn sy_emit_budget_exhausted(spec_id: *u8, iterations: u32, out_frag_id: *u8) -> i32 @export
```

Return convention: `SY_OK = 0` on success; `sy_search` returns `SY_E_BUDGET_EXHAUSTED` (not an error per se — a witnessed terminal verdict) when the bounded enumeration finds no admissible candidate. All guard failures return the negative sentinel; callers compare with `== / !=` only (W11).

## Constant Namespace
**PREFIX = `SY_`** (authoritative). The briefing assigned `SYNSRCH_`, but the gospel candidate body and the cross-module synthesis layer (Modules 59/64) lock in `SY_`; changing it would desync the locked contract while gaining nothing (the prefix governs only module-local consts, never the exported fn names). **Grep result: neither `SY_` nor `SYNSRCH_` collides with any existing `STDLIB/` symbol** (0 matches for `SY_OK|SY_E_NULL|SY_MAX_ITERATIONS|SY_INITED|SY_GENERATOR` and 0 for `SYNSRCH_`). Decision: keep `SY_`; this divergence from the briefing prefix is intentional and noted.

| const | type | value |
|---|---|---|
| `SY_OK` | i32 | `0i32` |
| `SY_E_NULL` | i32 | `-1i32` |
| `SY_E_SPEC_ABSENT` | i32 | `-2i32` |
| `SY_E_BUDGET_EXHAUSTED` | i32 | `-3i32` |
| `SY_E_NO_GENERATOR` | i32 | `-4i32` |
| `SY_E_NOT_INITED` | i32 | `-5i32` |
| `SY_E_EMIT_FAILED` | i32 | `-6i32` (NEW — see Gap 1: a per-candidate witness emit failure must surface) |
| `SY_MAX_ITERATIONS_DEFAULT` | u32 | `1048576u32` (2^20 — the hard ceiling; W48 enforcement) |
| `SY_IDENT_BYTES` | u64 | `32u64` |
| `SY_SEED_BYTES` | u64 | `36u64` (32-byte spec addr ‖ 4-byte LE iter) |
| `SY_COST_ITER_OFF` | u64 | `0u64` (byte offset of the iteration-budget u32 dimension within the spec's 32-byte / 8×u32 cost vector — see Gap 3) |

Note (Trap 9): the prose intro spells the exhaustion code `SS_E_BUDGET_EXHAUSTED`; that is a prose typo — the body's `SY_E_BUDGET_EXHAUSTED` is correct (this module's namespace). No em-dash in any `/* */` comment; use ASCII `--`.

## Data Structures
All module-scope (W8); every scratch array is hoisted here, NOT declared inside fn bodies (Trap 7 — the decisive portability fix; matches `identifier.iii`/`content_addr.iii` house style). Fixed sizes, justified:

| name | type | size justification |
|---|---|---|
| `SY_INITED` | `u8` | init guard (W12 lifecycle). |
| `SY_GENERATOR_MODULE` | `[u8; 32]` | one 256-bit identifier — generator module id. |
| `SY_GENERATOR_FN` | `[u8; 32]` | one 256-bit identifier — generator fn id. |
| `SY_GENERATOR_SET` | `u8` | generator-configured flag. |
| `SY_SPEC_ADDR` | `[u8; 32]` | scratch: spec content address for the active search (was local `spec_addr`). |
| `SY_SEED` | `[u8; 36]` | scratch: candidate seed = addr ‖ LE32(iter) (was local `candidate_seed`; sized exactly `SY_SEED_BYTES`). |
| `SY_CAND_ID` | `[u8; 32]` | scratch: current candidate id (was local `cand_id`). |
| `SY_COSTVEC` | `[u8; 32]` | scratch: the spec's 8×u32 cost vector read for the budget (Gap 3). |
| `SY_PAYLOAD` | `[u8; 96]` | scratch: witness-fragment payload for `sy_emit_candidate`/`_budget_exhausted` (was local `payload`; 96 retained — header 8 + 32 id + 4 len, room for the V3 layout). |
| `SY_PRODUCER` | `[u8; 32]` | scratch: zero producer id for `ws_emit_fragment`. |
| `SY_OP` | `[u8; 32]` | scratch: zero op id. |
| `SY_IN_C` | `[u8; 32]` | scratch: in-commitment id. |
| `SY_OUT_C` | `[u8; 32]` | scratch: out-commitment id. |
| `SY_FRAG_SCRATCH` | `[u8; 32]` | scratch: discard fragment id when `sy_search` emits the per-attempt `SYNTH_CANDIDATE` internally (Gap 1). |

**Reentrancy note (Trap 7 consequence):** with module-scope scratch the engine is single-threaded / non-reentrant. Acceptable — synthesis search is a serialized R0 operation driven by one ratified spec at a time; the witness chain serializes attempts. Documented, not a defect.

## Dependencies (externs)
All `extern @abi(c-msvc-x64) ... from "<module>.iii"`. **Build-order critical:** three of four providers are not-yet-built.

| extern | from | provider NN | status |
|---|---|---|---|
| `ident_zero(out: *u8) -> i32` | `identifier.iii` | 01 | **BUILT** |
| `ident_copy(src: *u8, dst: *u8) -> i32` | `identifier.iii` | 01 | **BUILT** |
| `ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32` | `identifier.iii` | 01 | **BUILT** |
| `ws_emit_fragment(producer,op,in_commit,out_commit,payload,payload_len: u64,out_fid) -> i32` | `witness_spine.iii` | (witness layer) | **NOT BUILT** — only `aether/witness_hook.iii` (`wh_*`) exists today; `witness_spine.iii` providing `ws_emit_fragment`/`ws_lookup_fragment` is a separate not-yet-built module the whole synthesis layer (59/63/64) shares. Flag for scheduler. |
| `ss_content_address(spec_id: *u8, out: *u8) -> i32` | `synthesis_spec.iii` | **59** | **NOT BUILT** (parallel wave). |
| `sw_verify_candidate(spec_id: *u8, candidate_id: *u8) -> i32` | `synthesis_witness.iii` | **64** | **NOT BUILT** (parallel wave). |

**NEW externs this spec adds** (to close gaps), both from already-listed not-yet-built providers — no new module dependency introduced:

| extern | from | provider NN | why |
|---|---|---|---|
| `ss_present(spec_id: *u8) -> u8` | `synthesis_spec.iii` | 59 | Gap 4 / W33: verify the spec slot exists & is ratified before searching. (Module 59's API exposes the slot table; expose a presence/ratified probe — if 59 names it differently, bind that name.) |
| `ss_get_cost_vector(spec_id: *u8, out: *u8) -> i32` | `synthesis_spec.iii` | 59 | Gap 3 / M19: read the ratified 32-byte cost vector so the budget is the spec's, not a hardcoded constant. (Module 59 has `ss_set_cost_vector`; it must expose the matching getter.) |

> Scheduler note: this module must wave **after** 59, 64, and `witness_spine`. Until they land, Phase 2 stubs the three externs to compile-and-link, but the KATs below require real 59/64.

> **Gospel-defect watch (systemic):** Module 59 (`synthesis_spec`) and Module 64 (`synthesis_witness`) both `extern keccak256_init/update/final from "keccak.iii"` in their gospel bodies — WRONG path/API. The built substrate uses `keccak256_oneshot from "keccak256.iii"` (see `identifier.iii`, `content_addr.iii`). **This module 63 does NOT call keccak directly** (it hashes only via `ident_from_bytes` and `ss_content_address`), so 63 itself is clean — but its dependency specs must be corrected when built.

## Algorithm

### `sy_init() -> i32`
Idempotent. If `SY_INITED==1` return `SY_OK`. Else `ident_zero` both generator id buffers, clear `SY_GENERATOR_SET=0`, set `SY_INITED=1`, return `SY_OK`. Deterministic; no inputs. (Unchanged from gospel; correct.)

### `sy_set_candidate_generator(generator_module, generator_fn) -> i32`
Guard `SY_INITED` (else `SY_E_NOT_INITED`); null-check both args via `(p as u64) == 0u64` (Trap 4-safe cast-then-equality). `ident_copy` each into `SY_GENERATOR_MODULE` / `SY_GENERATOR_FN`; set `SY_GENERATOR_SET=1`; return `SY_OK`. Deterministic copy. (Unchanged; correct.)

### `sy_search(spec_id, out_candidate_id, out_iterations) -> i32` — REWRITE
Hand-rolled **bounded deterministic enumeration** (NIH; no recursion — W15 — it is already a flat `while`, no explicit stack needed because enumeration is index-driven, not tree-structured). Steps:
1. Guard `SY_INITED` / three null args / `SY_GENERATOR_SET` (gospel order — correct).
2. **(Gap 4 / W33)** `if ss_present(spec_id) == 0u8 { return SY_E_SPEC_ABSENT }` — no search on an unratified/absent spec.
3. Compute the enumeration anchor: `ss_content_address(spec_id, &SY_SPEC_ADDR[0u64])` (deterministic; the spec's canonical Keccak256 — identical every run → bit-identical candidate stream, W5/M2).
4. **(Gap 3 / M19 / W43)** Read the ratified budget: `ss_get_cost_vector(spec_id, &SY_COSTVEC[0u64])`; decode the iteration dimension `budget = LE32(SY_COSTVEC[SY_COST_ITER_OFF..+4])`; clamp `max_iter = min(budget, SY_MAX_ITERATIONS_DEFAULT)` (a spec may not exceed the W48 hard ceiling). If `budget == 0u32` treat as `SY_MAX_ITERATIONS_DEFAULT` (a spec that set no budget falls back to the default ceiling, never unbounded). Clamp via `when`-cascade comparison of two u32 values (unsigned `<` is Trap-3-safe).
5. `iter = 0u32`, `result = SY_E_BUDGET_EXHAUSTED`, `sentinel = 0u8`.
6. **(Gap 2 / W14)** Loop: `while iter < max_iter && sentinel == 0u8 {` — the sentinel **drives** the loop (W14); on a hit the loop stops immediately so `out_iterations` reports the true cost (M19 accuracy). Per iteration:
   - Build `SY_SEED`: copy 32 bytes of `SY_SPEC_ADDR`, then write `iter` little-endian into bytes 32..35 via `(iter & 0xFFu32) as u8`, `((iter >> 8u32) & 0xFFu32) as u8`, `>>16`, `>>24` (W4 masks; u32 shift, byte store through u8 index — Trap 5-safe because the destination is a `[u8]` element, not a `*u32`).
   - `ident_from_bytes(&SY_SEED[0u64], SY_SEED_BYTES, &SY_CAND_ID[0u64])` → candidate id = Keccak256(addr‖iter). Deterministic, collision-resistant ordering.
   - **(Gap 1 / M6 / M10)** Emit the attempt to the chain BEFORE verdict: call the internal emit (same body as `sy_emit_candidate`) producing a `SYNTH_CANDIDATE` fragment for `SY_CAND_ID` into `SY_FRAG_SCRATCH`; if it fails, set `result = SY_E_EMIT_FAILED` and `sentinel = 1u8` (abort — an unwitnessed attempt is inadmissible).
   - `verify = sw_verify_candidate(spec_id, &SY_CAND_ID[0u64])`. On `verify == 0i32` (W11 equality): `ident_copy(&SY_CAND_ID[0u64], out_candidate_id)`, `result = SY_OK`, `sentinel = 1u8`.
   - `iter = iter + 1u32`.
7. `*out_iterations = iter` (now the true attempt count, not the cap).
8. **(Gap 2 / W48)** If `result == SY_E_BUDGET_EXHAUSTED` (the loop fell through without a hit), emit the terminal `SYNTH_BUDGET_EXHAUSTED` fragment (`sy_emit_budget_exhausted` body) so exhaustion is witnessed; ignore its frag id (best-effort terminal record — do not overwrite the verdict).
9. `return result`.

**Why this is exact, not ML/heuristic (M3/M4):** the *order* of candidates is a pure function of `(spec content address, iter)` — no counting, no adaptation, no threshold that changes future behavior based on past attempts. The *acceptance* is the verifier's exact algebraic check, never a "good enough" score. The generator module/fn (when a richer generator than the built-in hash-walk is plugged in) is an **oracle** (M15): it may use any internal strategy, but its output has zero authority until `sw_verify_candidate` ratifies it. Bit-identity (W5/M2): every byte of every candidate id and every emitted payload is a deterministic function of recorded inputs, recomputable byte-for-byte (M10).

**Bound (M19/W48):** `max_iter ≤ SY_MAX_ITERATIONS_DEFAULT = 2^20`; the loop is finite and the counter strictly increases by 1 each pass; termination is guaranteed even if the verifier always rejects.

### `sy_emit_candidate(candidate_id, encoding, encoding_len, out_frag_id) -> i32`
Guard init + three nulls. Build `SY_PAYLOAD`: `[0]=0xE3 [1]=0x06` (SYNTH_CANDIDATE tag), bytes 8..39 = `candidate_id`, bytes 40..43 = LE32(`encoding_len`) (W4 masks). Zero `SY_PRODUCER`/`SY_OP`; `ident_copy(candidate_id → SY_IN_C, SY_OUT_C)`. `return ws_emit_fragment(&SY_PRODUCER[0],&SY_OP[0],&SY_IN_C[0],&SY_OUT_C[0],&SY_PAYLOAD[0], 44u64, out_frag_id)`. **(Gap 7 — partial close):** the raw `encoding` bytes are not copied into the 44-byte payload; to honor M10 (the candidate must be recomputable from the witness) the payload commits the candidate **id** (= hash of its seed) and the encoding **length**; the full encoding is recoverable from the generator given `(spec_addr, iter)`. If the design requires the encoding bytes themselves in-chain, Phase 2 extends the payload to `8 + 32 + 4 + encoding_len` (cap 96 ⇒ `encoding_len ≤ 52`) or commits `ident_from_bytes(encoding)` as a 32-byte digest at offset 44. **Decision: commit the encoding digest** at bytes 44..75 (payload_len 76) so any reader can verify the recorded encoding without trusting the generator. (This is the maximal-intent close; flagged for Phase 2.)

### `sy_emit_budget_exhausted(spec_id, iterations, out_frag_id) -> i32`
Guard init + two nulls. `SY_PAYLOAD`: `[0]=0xE3 [1]=0x12` (SYNTH_BUDGET_EXHAUSTED tag), bytes 8..39 = `spec_id`, bytes 40..43 = LE32(`iterations`). Zero producer/op; `ident_copy(spec_id → SY_IN_C)`, `ident_zero(SY_OUT_C)` (no output state on exhaustion). `return ws_emit_fragment(..., 44u64, out_frag_id)`. Deterministic; the exhaustion verdict is now chained (W48).

## KAT Vectors (>= 3)
Driven by a `sy_selftest() -> u64` (99 = pass), using the built `identifier.iii` plus Phase-2 stubs/real 59 & 64. Byte-exact:

1. **Not-inited / no-generator guards (negative-case proof, no stub-pass):**
   - Fresh module (no `sy_init`): `sy_search(&spec, &cid, &it)` MUST return `SY_E_NOT_INITED` (`-5`). Prove the guard FAILS closed.
   - After `sy_init()` but before `sy_set_candidate_generator`: `sy_search` MUST return `SY_E_NO_GENERATOR` (`-4`).
   - `sy_search(0 as *u8, &cid, &it)` MUST return `SY_E_NULL` (`-1`).
   - `ss_present` returns 0 ⇒ `sy_search` MUST return `SY_E_SPEC_ABSENT` (`-2`).

2. **Deterministic candidate-stream identity (M2/W5):** with a fixed `SY_SPEC_ADDR` = Keccak256 of a known spec (e.g. all-zero spec ⇒ a fixed 32-byte address), the candidate id at `iter=0` MUST equal `Keccak256(addr ‖ 00 00 00 00)` and at `iter=1` `Keccak256(addr ‖ 01 00 00 00)`. Assert the first/last byte of each (computed once via the built `keccak256_oneshot` over the 36-byte seed) — two distinct iterations MUST yield two distinct ids, and re-running yields byte-identical ids. (Drives the LE32 seed encoding + Trap-4/5 byte-store correctness.)

3. **Accept on first hit + true iteration count (Gap 2/W14/M19):** with a stub verifier set to accept exactly at `iter == 3` (reject 0,1,2), `sy_search` MUST return `SY_OK`, `out_candidate_id` MUST equal the `iter=3` candidate id from KAT-2's formula, and `*out_iterations` MUST equal `4` (attempts 0,1,2,3 — i.e. it stopped, did NOT run to the cap). This is the regression that the gospel's "run-to-max_iter" bug would fail (it would report `max_iter`).

4. **Witnessed exhaustion (Gap 2/W48):** with a stub verifier that always rejects and a spec cost-vector iteration budget set to `5u32`, `sy_search` MUST return `SY_E_BUDGET_EXHAUSTED` (`-3`), `*out_iterations` MUST equal `5` (the spec budget, NOT the 2^20 default — proves Gap 3 honored), AND a `SYNTH_BUDGET_EXHAUSTED` fragment (tag bytes `E3 12`) MUST have been emitted (assert via a witness-spine lookup / emit-count probe).

5. **Emit payload byte-layout (M10):** `sy_emit_candidate(cid, enc, 0x01020304u32, &fid)` then read back the fragment payload: `[0]==0xE3`, `[1]==0x06`, bytes 8..39 == `cid`, bytes 40..43 == `04 03 02 01` (LE), and (per the encoding-digest decision) bytes 44..75 == `Keccak256(enc[0..encoding_len])`. Byte-for-byte.

## Trap Exposure
- **Trap 1 (multi-line `fn`):** EXPOSED-by-shape; all 5 signatures kept strictly single-line. ✔
- **Trap 2 (const linker-global):** EXPOSED; mitigated by unique `SY_` prefix (grep-confirmed 0 collisions). ✔
- **Trap 3 (signed-ordering SIGSEGV):** NOT exposed — every ordering compare is on **unsigned** `u32`/`u64` (`iter < max_iter`, `k < 32u64`, budget clamp). All `i32` uses are equality only (`verify == 0i32`, `result == SY_E_BUDGET_EXHAUSTED`). No `<`/`>`/`<=`/`>=` on any `i32`/`i64`. ✔
- **Trap 4 (u32-in-u64-slot pointer garbage):** Mildly exposed — `iter` is u32 used in byte stores, never in pointer arithmetic; all array indices are explicit `u64` (`k`, literal `0u64`). No `(u32 as u64) * stride` pointer math. ✔
- **Trap 5 (u32 pointer-store width):** NOT exposed — bytes are written to `[u8]` array elements (`SY_SEED[32u64] = (...) as u8`), never through a `*u32` pointer. ✔
- **Trap 6 (nested block comments):** Avoided — header uses one flat `/* ... */`; inline notes use `//`. ✔
- **Trap 7 (local `var`/array decls):** **PRIMARY exposure in the gospel body** — it declares `spec_addr`, `candidate_seed`, `cand_id`, `payload`, `producer/op/in_c/out_c` as fn-local arrays. **Fix: every one hoisted to a module-scope `SY_*` buffer** (matches `identifier.iii`/`content_addr.iii`). Reentrancy traded away — acceptable for a serialized R0 search engine (noted). ✔ (fixed)
- **Trap 8 (`} else {` split):** No `else` used (guard-and-return style); if Phase 2 adds one it stays one-line. ✔
- **Trap 9 (em-dash in comment):** Avoided — ASCII `--` only in all comments. ✔
- **Trap 10 (`let mut` flag misbehaves):** Mildly exposed — `sentinel`/`result` are mutated flags inside `sy_search`. Mitigated by making `sentinel` **drive the loop condition** (`while ... && sentinel == 0u8`) rather than only gating an inner `if` (this is also the Gap-2 fix). Verified by KAT-3 (true count) and KAT-4 (exhaustion). ✔
- **Trap 11 (modulo-after-call):** NOT exposed — no `%` operator anywhere; the LE32 split uses shifts+masks. ✔
- **Trap 12 (`@specialize *T` stride):** NOT exposed — module is not generic; all buffers are concrete `[u8; N]`. ✔

## Gap / Fix List
1. **No per-attempt witness emission (M6/M10, module's own discipline).** Gospel `sy_search` verifies but emits nothing; prose promises a `SYNTH_CANDIDATE` per attempt. **Fix:** inside the loop, emit `SYNTH_CANDIDATE` for each generated `SY_CAND_ID` (reuse `sy_emit_candidate` body) before recording the verdict; on emit failure abort with new `SY_E_EMIT_FAILED`.
2. **Loop runs to `max_iter` after a hit; `out_iterations` reports the cap, not the real cost (W14 + M19).** **Fix:** `while iter < max_iter && sentinel == 0u8` so the sentinel drives termination; report the true `iter`. (KAT-3.)
3. **Budget ignores the ratified spec cost vector (M19/W43 — cost beyond lattice).** Gospel hardcodes `SY_MAX_ITERATIONS_DEFAULT`. **Fix:** add extern `ss_get_cost_vector`; decode the iteration dimension; `max_iter = min(budget, DEFAULT)`; `budget==0 ⇒ DEFAULT`. (KAT-4.)
4. **No spec presence/ratification check (W33; `SY_E_SPEC_ABSENT` dead).** **Fix:** add extern `ss_present`; return `SY_E_SPEC_ABSENT` when absent/unratified. (KAT-1.)
5. **Wrong scratch-buffer scope (Trap 7) in all four fns.** **Fix:** hoist every local array to module scope (`SY_SPEC_ADDR`, `SY_SEED`, `SY_CAND_ID`, `SY_COSTVEC`, `SY_PAYLOAD`, `SY_PRODUCER/OP/IN_C/OUT_C`, `SY_FRAG_SCRATCH`); note non-reentrancy.
6. **Encoding bytes not committed in `sy_emit_candidate` (M10 weak).** **Fix:** commit `Keccak256(encoding[0..encoding_len])` at payload bytes 44..75 (payload_len 76) so a reader can verify the recorded candidate without trusting the generator. (KAT-5.)
7. **Prose-vs-body prefix typo** (`SS_E_BUDGET_EXHAUSTED` in prose vs `SY_E_BUDGET_EXHAUSTED` in body). **Fix:** body is authoritative; documented, no code change.
8. **Cross-layer dependency-API drift (flag for scheduler, not a 63 code change):** `witness_spine.iii` (provider of `ws_emit_fragment`/`ws_lookup_fragment`) is unbuilt and distinct from the existing `witness_hook.iii` (`wh_*`); Modules 59 & 64 carry the systemic `keccak256_init/update/final from "keccak.iii"` defect (must become `keccak256_oneshot from "keccak256.iii"` when built). Module 63 itself is clean of the keccak defect.

**Mandate verification (what holds in the fixed design):** M1 NIH (only `identifier`/`synthesis_spec`/`synthesis_witness`/`witness_spine`, all III-internal; hand-rolled LE32 + enumeration) ✔; M2/W5 bit-identity (candidate stream = pure fn of spec address + index) ✔; M3/M4 no ML/heuristics (generator is an authority-less oracle; acceptance is the exact verifier) ✔; M6/M10 witness continuity & reproducibility (now emits per-attempt + terminal fragments; all payload bytes recomputable) ✔; M7 Ring R0 preserved ✔; M12 verifiability (only verifier-ratified candidates returned; transcript in Module 64) ✔; M15 generator-as-oracle honored ✔; M19/W43/W48 bounded (`max_iter ≤ 2^20`, sourced from ratified cost vector, strictly-increasing counter) ✔; W2 (≤4 params: max 4) ✔; W9/W11/W12 (negative-i32 status, equality compares, every fn returns status) ✔; W13 (≤20 locals: `sy_search` ~9) ✔; W15 (no recursion: flat index loop) ✔.

## Implementation Skeleton
Paste-ready structure. SINGLE-LINE signatures. No fn bodies (Phase 2 writes them per Algorithm §). ASCII-only comments.

```iii
/* III/STDLIB/iii/numera/synthesis_search.iii -- Layer 5, Module 63.
 *
 * Bounded, deterministic program-synthesis search. Enumerates candidate
 * ids = Keccak256(spec_content_address || LE32(iter)) in fixed order,
 * submits EVERY candidate to the synthesis verifier (Module 64), emits a
 * SYNTH_CANDIDATE witness per attempt and a SYNTH_BUDGET_EXHAUSTED on
 * exhaustion. The generator is an authority-less oracle (M15); only the
 * verifier transcript enters the chain (W38). Bound = ratified spec cost
 * vector, clamped to SY_MAX_ITERATIONS_DEFAULT = 2^20 (M19/W48).
 *
 * Hexad: kind_cognition.  Ring: R0.  K_synth: per call (bounded).
 * NIH: identifier.iii, synthesis_spec.iii, synthesis_witness.iii,
 *      witness_spine.iii.  Non-reentrant (module-scope scratch; serialized
 *      R0 search) -- see Trap 7 note in the spec.
 */
module numera_synthesis_search

extern @abi(c-msvc-x64) fn ident_zero(out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ws_emit_fragment(producer: *u8, op: *u8, in_commit: *u8, out_commit: *u8, payload: *u8, payload_len: u64, out_fid: *u8) -> i32 from "witness_spine.iii"
extern @abi(c-msvc-x64) fn ss_content_address(spec_id: *u8, out: *u8) -> i32 from "synthesis_spec.iii"
extern @abi(c-msvc-x64) fn ss_present(spec_id: *u8) -> u8 from "synthesis_spec.iii"
extern @abi(c-msvc-x64) fn ss_get_cost_vector(spec_id: *u8, out: *u8) -> i32 from "synthesis_spec.iii"
extern @abi(c-msvc-x64) fn sw_verify_candidate(spec_id: *u8, candidate_id: *u8) -> i32 from "synthesis_witness.iii"

const SY_OK                     : i32 =  0i32
const SY_E_NULL                 : i32 = -1i32
const SY_E_SPEC_ABSENT          : i32 = -2i32
const SY_E_BUDGET_EXHAUSTED     : i32 = -3i32
const SY_E_NO_GENERATOR         : i32 = -4i32
const SY_E_NOT_INITED           : i32 = -5i32
const SY_E_EMIT_FAILED          : i32 = -6i32
const SY_MAX_ITERATIONS_DEFAULT : u32 = 1048576u32
const SY_IDENT_BYTES            : u64 = 32u64
const SY_SEED_BYTES             : u64 = 36u64
const SY_COST_ITER_OFF          : u64 = 0u64

var SY_INITED           : u8 = 0u8
var SY_GENERATOR_MODULE : [u8; 32]
var SY_GENERATOR_FN     : [u8; 32]
var SY_GENERATOR_SET    : u8 = 0u8
var SY_SPEC_ADDR        : [u8; 32]
var SY_SEED             : [u8; 36]
var SY_CAND_ID          : [u8; 32]
var SY_COSTVEC          : [u8; 32]
var SY_PAYLOAD          : [u8; 96]
var SY_PRODUCER         : [u8; 32]
var SY_OP               : [u8; 32]
var SY_IN_C             : [u8; 32]
var SY_OUT_C            : [u8; 32]
var SY_FRAG_SCRATCH     : [u8; 32]

fn sy_init() -> i32 @export {
    // TODO: body per Algorithm sy_init -- idempotent init, zero generator ids.
}

fn sy_set_candidate_generator(generator_module: *u8, generator_fn: *u8) -> i32 @export {
    // TODO: body per Algorithm -- guard inited + nulls; ident_copy both; set flag.
}

fn sy_search(spec_id: *u8, out_candidate_id: *u8, out_iterations: *u32) -> i32 @export {
    // TODO: body per Algorithm sy_search REWRITE --
    //  guards; ss_present (SY_E_SPEC_ABSENT); ss_content_address -> SY_SPEC_ADDR;
    //  ss_get_cost_vector -> SY_COSTVEC; decode LE32 budget; max_iter = min(budget, DEFAULT);
    //  while iter < max_iter && sentinel == 0u8 { build SY_SEED (addr || LE32 iter);
    //    ident_from_bytes -> SY_CAND_ID; emit SYNTH_CANDIDATE (SY_E_EMIT_FAILED on fail);
    //    sw_verify_candidate; on ==0i32 copy out + result=SY_OK + sentinel=1; iter+=1 }
    //  *out_iterations = iter; if result == SY_E_BUDGET_EXHAUSTED emit SYNTH_BUDGET_EXHAUSTED;
    //  return result.
}

fn sy_emit_candidate(candidate_id: *u8, encoding: *u8, encoding_len: u32, out_frag_id: *u8) -> i32 @export {
    // TODO: body per Algorithm -- SY_PAYLOAD [0]=0xE3 [1]=0x06; id at 8..39; LE32 len at 40..43;
    //  Keccak256(encoding[0..encoding_len]) at 44..75 (via ident_from_bytes); zero producer/op;
    //  ident_copy candidate_id -> in_c/out_c; ws_emit_fragment(..., 76u64, out_frag_id).
}

fn sy_emit_budget_exhausted(spec_id: *u8, iterations: u32, out_frag_id: *u8) -> i32 @export {
    // TODO: body per Algorithm -- SY_PAYLOAD [0]=0xE3 [1]=0x12; spec_id at 8..39; LE32 iterations
    //  at 40..43; zero producer/op; ident_copy spec_id -> in_c; ident_zero out_c;
    //  ws_emit_fragment(..., 44u64, out_frag_id).
}

fn sy_selftest() -> u64 @export {
    // TODO: KAT-1..5 per spec; 99u64 == pass. Requires real Modules 59 & 64 + witness_spine.
}
```
