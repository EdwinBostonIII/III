# 45 aether/witness_compactor.iii — Implementation Spec

## Verdict
PARTIAL — the gospel candidate body is algorithmically near-complete (mark/expand/sweep are all present and the COMPACTION emission is well-formed) but it does NOT compile or link as-written: it imports the three streaming keccak primitives from the wrong file (`keccak.iii`, which does not export them), declares SEVEN function-local `var` arrays (Trap 7 — parse failure), depends on the fictional `witness_spine.iii::ws_lookup_id` and on six witness_hook accessors that the BUILT `witness_hook.iii` does not yet export, and codes the inner run-scan / post-run advance as fragile dual-`if` sentinels that read one slot past the scanned region. Every defect is closeable; none changes the algorithm.

## Purpose
`aether/witness_compactor.iii` IS the witness chain's selective-retention garbage compactor: it maintains a per-fragment retention bitmap, expands a caller's "live" marks over their transitive antecedent closure, then groups maximal runs of consecutive non-retained fragments and publishes one `COMPACTION` witness fragment per run whose `out_commit` is the Keccak256 fold of every fragment id in the run and whose `in_commit` is `Keccak256(run_start ‖ run_end)`. The original fragments are never removed (the chain is append-only, M5/M6); the `COMPACTION` fragment becomes the canonical handle by which subsequent chain-root verifications skip the compacted run, so the chain stays auditably verifiable while its *active* footprint stops growing without bound (Discipline One: witness chain compaction). Hexad: `kind_witness + kind_repair`. Ring: R-1. K: 1.00.

## Public API
All signatures SINGLE-LINE (Trap 1). All public fns return a status or sentinel-typed value (W12). Error codes are negative `i32` (W9); boolean returns are `u8` 0/1 (W10).

```
fn wc_init() -> i32 @export
fn wc_clear_marks() -> i32 @export
fn wc_mark_retain(frag_idx: u64) -> i32 @export
fn wc_is_retained(frag_idx: u64) -> u8 @export
fn wc_run_compaction() -> u32 @export
fn wc_selftest() -> u64 @export
```

- `wc_init` → `WCOMP_OK` (0) always; idempotent re-init of the bitmap + derived producer/opid identifiers.
- `wc_clear_marks` → `WCOMP_OK`; clears marks over `[0, wh_next_idx())`.
- `wc_mark_retain(frag_idx)` → `WCOMP_OK`, or `WCOMP_E_BAD` (-1) if `frag_idx >= WCOMP_MAX_FRAGS`. Marks the fragment then closes over its transitive antecedents.
- `wc_is_retained(frag_idx)` → `u8` 1 if retained, 0 otherwise (0 also for out-of-range — a non-error boolean query, W10).
- `wc_run_compaction` → `u32` count of `COMPACTION` fragments emitted (a sentinel-typed value: 0 = nothing to compact; never an error code — W12).
- `wc_selftest` → `u64`; 99 = pass, else the first failing checkpoint number (house idiom, cf. `wh_selftest`).

## Constant Namespace
PREFIX = `WCOMP_` . The gospel body uses `WC_`; **renamed to the dispatch-assigned `WCOMP_`** to remove all collision risk (grep of `STDLIB/` shows zero `WC_` *and* zero `WCOMP_` const/var symbols today — both are free, `WCOMP_` is the assigned one). Module-level consts (Trap 2 — every one is linker-global, so the prefix is mandatory):

| name | type | value |
|------|------|-------|
| `WCOMP_OK` | i32 | `0i32` |
| `WCOMP_E_BAD` | i32 | `-1i32` |
| `WCOMP_MAX_FRAGS` | u64 | `4194304u64`  (4 Mi fragments tracked — matches `witness_hook.iii::WH_MAX_FRAGMENTS = 1048576` headroom ×4; full gospel capacity, no down-scale) |
| `WCOMP_MAX_ANTE` | u32 | `32u32`  (inline antecedent cap; equals `witness_hook.iii::WH_MAX_ANTECEDENTS`) |
| `WCOMP_ID_BYTES` | u64 | `32u64`  (one identifier = 32 bytes, Keccak256 width) |
| `WCOMP_COMPACT_PHASE` | u8 | `9u8`  (phase tag stamped on the COMPACTION fragment — gospel literal) |
| `WCOMP_COMPACT_PILLAR` | u16 | `5u16`  (pillar tag — gospel literal) |
| `WCOMP_PRODUCER_LEN` | u64 | `25u64`  (byte length of `"aether::witness_compactor"`) |
| `WCOMP_OPID_LEN` | u64 | `34u64`  (byte length of `"aether::witness_compactor::compact"`) |

Collision check (grep `STDLIB/iii` for `const WC_`, ` WC_`, `WCOMP_`): **no matches** — namespace is clean.

## Data Structures
Every buffer is a fixed module-scope array (W8). **All seven gospel function-local `var` arrays are hoisted here (Trap 7 fix).** The module is non-reentrant by construction (serialized compaction over a single global chain) — acceptable, same posture as `witness_hook.iii` / `merkle.iii`; noted under Trap Exposure.

| name | type | bytes | bound justification |
|------|------|-------|---------------------|
| `WCOMP_RETAIN` | `[u8; 4194304]` | 4 MiB | one byte per fragment, bit-0 = retained; sized to `WCOMP_MAX_FRAGS` (W8). |
| `WCOMP_PRODUCER` | `[u8; 32]` | 32 | derived producer identifier `ident_from_bytes("aether::witness_compactor")`. |
| `WCOMP_OPID_COMPACT` | `[u8; 32]` | 32 | derived op identifier for the COMPACTION operation. |
| `WCOMP_INITED` | `u8 = 0u8` | 1 | one-time-init flag (lazy `wc_init` on first mark/sweep). |
| `WCOMP_ANTE_TMP` | `[u8; 32]` | 32 | scratch for one antecedent id read in the mark-expansion sweep (gospel local `aid`). |
| `WCOMP_RUN_SUM` | `[u8; 32]` | 32 | COMPACTION `out_commit` = Keccak256 fold of run fragment ids (gospel local `sum`). |
| `WCOMP_FID_TMP` | `[u8; 32]` | 32 | scratch for one fragment id during the fold (gospel local `fid`). |
| `WCOMP_IN_COMMIT` | `[u8; 32]` | 32 | COMPACTION `in_commit` = `Keccak256(run_start ‖ run_end)` (gospel local `ic`). |
| `WCOMP_INBUF` | `[u8; 16]` | 16 | LE-packed `run_start ‖ run_end` payload + in_commit preimage (gospel local `inbuf`); doubles as the 16-byte fragment payload. |
| `WCOMP_ANTES` | `[u8; 1024]` | 1024 | up to 32 inline antecedent ids ×32 bytes = `WCOMP_MAX_ANTE * WCOMP_ID_BYTES` (gospel local `antes`). |
| `WCOMP_OUT_FID` | `[u8; 32]` | 32 | sink for the emitted COMPACTION fragment id (gospel local `fid`/`fp` at publish). |

Self-test scratch (module scope, prefixed): `WCOMP_T_PROD : [u8; 32]`, `WCOMP_T_PAY : [u8; 32]`, `WCOMP_T_ANTE : [u8; 32]`.

No global pointer escapes (W1/W3): every `&WCOMP_*` address-of is taken only inside this file and passed as `*u8` to externs that copy out; no static address is retained across calls.

## Dependencies (externs)
All `extern @abi(c-msvc-x64)`. Provider NN and build status noted. **The gospel's keccak `from "keccak.iii"` clauses are WRONG and corrected here to `"keccak256.iii"`** (systemic defect #1). Resolution is by basename, so `identifier.iii` resolves although it physically lives in `numera/` (real path noted).

| extern | from | provider NN | status |
|--------|------|-------------|--------|
| `fn wh_next_idx() -> u64` | `witness_hook.iii` | 07 | BUILT ✓ |
| `fn wh_get_frag_id(idx: u64, out_id: *u8) -> i32` | `witness_hook.iii` | 07 | BUILT ✓ |
| `fn wh_publish(...12 params...) -> u64` | `witness_hook.iii` | 07 | BUILT ✓ (signature verified line-for-line below) |
| `fn wh_get_ante_count(idx: u64) -> u32` | `witness_hook.iii` | 07 | **NOT-YET-EXPORTED** — accessor; Phase-2 trivial getter (defect #6). Body specified in gospel Turn-One drop (L1854). |
| `fn wh_get_ante(idx: u64, ante_idx: u32, out: *u8) -> i32` | `witness_hook.iii` | 07 | **NOT-YET-EXPORTED** — accessor; Phase-2 trivial getter (defect #6). Body specified in gospel Turn-One drop (L1859). |
| `fn keccak256_init() -> i32` | `keccak256.iii` *(gospel said keccak.iii — WRONG)* | 06 | BUILT ✓ |
| `fn keccak256_update(input: *u8, len: u64) -> i32` | `keccak256.iii` *(corrected)* | 06 | BUILT ✓ |
| `fn keccak256_final(out: *u8) -> i32` | `keccak256.iii` *(corrected)* | 06 | BUILT ✓ |
| `fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32` | `identifier.iii` *(real path `numera/identifier.iii`)* | 01 | BUILT ✓ |
| `fn ws_lookup_id(frag_id: *u8, out_idx: *u64) -> i32` | `witness_spine.iii` *(real path `numera/witness_spine.iii`)* | (spine) | **NOT-YET-BUILT** — the entire module is unimplemented. This is the frag-id→index reverse index that, per the gospel's own Layer-2 note (L1734 "the witness hook does not maintain a reverse index by frag_id directly; the spine does, layer 3"), is the spine's responsibility. NOT fiction (unlike `ws_emit_fragment`): it is a real planned export. Contract assumed: returns `0i32` and writes the index to `*out_idx` on hit; non-zero on miss. |

Notes:
- `ident_copy` (gospel `wc_init` does not actually call it) is **not** needed — the gospel body uses `ident_from_bytes` only. Dropped from the extern list to keep the surface minimal (the candidate listed `ident_copy` but never invokes it).
- `wh_publish`'s 12 parameters exceed W2 (≤4). This is an **accepted exception**: it is the real, immutable signature of the BUILT `witness_hook.iii` (its own header documents `wh_publish` as "the documented multi-field hook"); a downstream caller cannot refactor a built provider. No alternative aggregate-by-pointer form exists in the provider.

Verified `wh_publish` signature (from built `witness_hook.iii:144-148`):
```
fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 @export
```
Returns the new fragment index, or `0xFFFFFFFFFFFFFFFFu64` on failure (full / not-inited / too-many-antecedents / payload overflow). The compactor ignores the return except via `emitted` increment — acceptable, but see Gap #7 (it should check the failure sentinel).

## Algorithm

NIH (M1): the only algorithm used is Keccak256 folding (provided by `keccak256.iii`) and a fixed-point worklist over a bitmap. No third-party code, no ML/heuristics (M3/M4) — retention is decided purely by reachability over the antecedent DAG, not by counting, ageing, or thresholds. Determinism (M2) / bit-identity (W5): every output (`out_commit`, `in_commit`, the COMPACTION fragment id) is a pure function of the recorded fragment ids and the integer-LE encoding of `(run_start, run_end)`; identical chains compact bit-identically across runs and CPUs. No recursion (W15): the transitive closure uses an explicit iterated full-sweep worklist (a fixed-point over the `WCOMP_RETAIN` bitmap), not call-stack recursion.

### `wc_init()`
1. Loop `i` over `[0, WCOMP_MAX_FRAGS)`: `WCOMP_RETAIN[i] = 0u8`.
2. `ident_from_bytes("aether::witness_compactor", 25, &WCOMP_PRODUCER)`.
3. `ident_from_bytes("aether::witness_compactor::compact", 34, &WCOMP_OPID_COMPACT)`.
4. `WCOMP_INITED = 1u8`; return `WCOMP_OK`.
(The string-literal byte lengths are captured as `WCOMP_PRODUCER_LEN`/`WCOMP_OPID_LEN`; the literal `*u8` is materialized inline as in the gospel: `let p1 : *u8 = "..." as *u8`.)

### `wc_clear_marks()`
1. `n = wh_next_idx()`.
2. Loop `i` over `[0, n)`: `WCOMP_RETAIN[i] = 0u8`. Return `WCOMP_OK`. (Clears only the live region; the tail is already 0 from init.)

### `wc_mark_retain(frag_idx)`  — transitive antecedent closure (explicit worklist, W15)
1. If `WCOMP_INITED == 0u8` → `wc_init()`.
2. If `frag_idx >= WCOMP_MAX_FRAGS` → return `WCOMP_E_BAD`.
3. `WCOMP_RETAIN[frag_idx] = 1u8`.
4. `n = wh_next_idx()`. Fixed-point sweep: `changed = 1u8`; **while `changed == 1u8`** (W14 — the loop condition IS the flag): set `changed = 0u8`; for each `i` in `[0, n)` with `WCOMP_RETAIN[i] == 1u8`: read `cnt = wh_get_ante_count(i)`; for each `k` in `[0, cnt)`: `wh_get_ante(i, k, &WCOMP_ANTE_TMP)`; resolve `ws_lookup_id(&WCOMP_ANTE_TMP, &ai)`; gate on equality `== 0i32` (W11 — never `< 0`); if hit and `ai < WCOMP_MAX_FRAGS` and `WCOMP_RETAIN[ai] == 0u8`: set `WCOMP_RETAIN[ai] = 1u8` and `changed = 1u8`.
5. Return `WCOMP_OK`.
Termination (M19): the bitmap is monotone (a slot only ever 0→1) and bounded by `n ≤ WCOMP_MAX_FRAGS`; each sweep that sets `changed` flips ≥1 bit, so at most `n` sweeps run before a clean sweep exits. Worst-case cost `O(n² · maxante)` — large at full 4 Mi scale but **bounded and exact**, not a heuristic; retained verbatim per the no-down-scale discipline.

### `wc_is_retained(frag_idx)`
1. If `frag_idx >= WCOMP_MAX_FRAGS` → return `0u8` (non-error boolean miss).
2. Return `WCOMP_RETAIN[frag_idx]`.

### `wc_run_compaction()`  — sweep + COMPACTION emission
1. If `WCOMP_INITED == 0u8` → `wc_init()`.
2. `n = wh_next_idx()`; `emitted = 0u32`; `i = 0u64`.
3. **Outer while `i < n`** (W14): the body either advances `i` past a retained fragment or consumes a whole non-retained run, so `i` strictly increases every iteration (see Gap #5 for the clean, non-fragile control flow that replaces the gospel's dual-`if`):
   - If `WCOMP_RETAIN[i] == 1u8`: `i = i + 1u64` (skip retained); continue.
   - Else open a run: `run_start = i`; inner **while `i < n` AND `WCOMP_RETAIN[i] == 0u8`**: `i = i + 1u64`. Now `run_end = i` (half-open `[run_start, run_end)`).
   - Fold `out_commit`: `keccak256_init()`; for `j` in `[run_start, run_end)`: `wh_get_frag_id(j, &WCOMP_FID_TMP)`; `keccak256_update(&WCOMP_FID_TMP, 32)`; then `keccak256_final(&WCOMP_RUN_SUM)`.
   - Build `in_commit`: pack `WCOMP_INBUF[0..8] = LE(run_start)`, `WCOMP_INBUF[8..16] = LE(run_end)` via per-byte shifts `(v >> (z*8)) & 0xFF`; `ident_from_bytes(&WCOMP_INBUF, 16, &WCOMP_IN_COMMIT)`.
   - Inline antecedents: `nante = (run_end - run_start) as u32`; `nante_capped = min(nante, WCOMP_MAX_ANTE)`; for `q` in `[0, nante_capped)`: `wh_get_frag_id(run_start + q, &WCOMP_ANTES + q*32)` written via `((&WCOMP_ANTES as u64) + (q as u64)*32u64) as *u8` (no `*u32` store — Trap 5 N/A, copies are byte-wise inside `wh_get_frag_id`).
   - Publish: `r = wh_publish(&WCOMP_PRODUCER, &WCOMP_OPID_COMPACT, &WCOMP_IN_COMMIT, &WCOMP_RUN_SUM, 0u8, WCOMP_COMPACT_PHASE, WCOMP_COMPACT_PILLAR, &WCOMP_ANTES, nante_capped, &WCOMP_INBUF, 16u32, &WCOMP_OUT_FID)`.
   - If `r != 0xFFFFFFFFFFFFFFFFu64` → `emitted = emitted + 1u32` (Gap #7 fix: only count successful publishes).
4. Return `emitted`.

The COMPACTION fragment encodes the run as: `producer = aether::witness_compactor`, `opid = ...::compact`, `out_commit = Keccak256(fid[run_start] ‖ … ‖ fid[run_end-1])`, `in_commit = Keccak256(LE(run_start) ‖ LE(run_end))`, `payload = LE(run_start) ‖ LE(run_end)` (16 bytes, so the run bounds are recoverable for audit), `revtag = 0`, `phase = 9`, `pillar = 5`, antecedents = first ≤32 fragment ids of the run (the full set is implicit in the `out_commit` fold). M10/M12: the fragment is byte-reproducible from the recorded fids + bounds, and any verifier can recompute the fold to confirm the run was compacted faithfully (the certificate is the fragment itself).

## KAT Vectors (≥3)
A self-test (`wc_selftest`, 99 = pass) drives these against a freshly `wh_init`'d chain (the test publishes its own fragments through `wh_publish` so the chain content is deterministic). Each checkpoint returns its own number on failure.

1. **Empty/all-retained → no compaction.** After `wc_init()`, publish 3 fragments via `wh_publish`; `wc_mark_retain` each of indices 0,1,2; then `wc_run_compaction()` MUST return `0u32` (no non-retained run exists) and `wc_is_retained(0..2)` MUST each be `1u8`. → checkpoints 1–2.
2. **Single full run → exactly one COMPACTION fragment.** Re-init chain, publish 4 fragments (indices 0..3), mark none; `n0 = wh_next_idx()` (=4). `wc_run_compaction()` MUST return `1u32`; afterwards `wh_next_idx()` MUST equal `n0 + 1` (the one emitted COMPACTION fragment); read it back with `wh_get_payload(n0, …)` and assert payload = `LE(0) ‖ LE(4)` (16 bytes: `00 00 00 00 00 00 00 00  04 00 00 00 00 00 00 00`). → checkpoints 3–6.
3. **Split runs around a retained island → two COMPACTION fragments.** Re-init, publish 5 fragments (0..4); `wc_mark_retain(2)` (index 2 retained, no antecedents so closure adds nothing); `wc_run_compaction()` MUST return `2u32` (runs `[0,2)` and `[3,5)`); assert the two emitted COMPACTION payloads decode to `(0,2)` and `(3,5)` respectively. → checkpoints 7–9.
4. **Transitive closure marks an antecedent.** Re-init, publish fragment A (index 0, no antecedents); capture A's 32-byte fid via `wh_get_frag_id(0,…)`; publish fragment B (index 1) **with A's fid as its single antecedent** (`n_ante = 1`); `wc_mark_retain(1)`; then `wc_is_retained(0)` MUST be `1u8` (closure pulled in A through `ws_lookup_id`). → checkpoint 10. *(This checkpoint exercises the not-yet-built `ws_lookup_id`; under the stub-spine it is the acceptance gate that proves the reverse index resolves A's fid back to index 0 — it must FAIL if the spine returns a wrong/sentinel index, satisfying the "prove the negative case" discipline.)*
5. **Keccak fold determinism / out_commit reproducibility.** From KAT-2, independently recompute `Keccak256(fid0 ‖ fid1 ‖ fid2 ‖ fid3)` in the test and compare byte-for-byte to the COMPACTION fragment's stored `out_commit` (via `wh_get_out_commit` if exported, else recompute and compare to a recorded golden 32-byte vector). MUST match. → checkpoint 11. Keccak256 itself is anchored by `keccak256.iii::keccak256_kat` (NIST/standard vector) — this module relies on that, it does not re-derive a hash KAT.

`wc_selftest` returns `99u64` only if checkpoints 1–11 all pass.

## Trap Exposure
- **Trap 1 (multi-line `fn`)** — EXPOSED in spirit only; the gospel kept signatures single-line. The skeleton holds every signature on one line. The 12-param `wh_publish` **extern** is wrapped across lines in the gospel listing — the skeleton collapses it to ONE physical line (extern decls obey the same single-line rule).
- **Trap 2 (module-level const is linker-global)** — EXPOSED. Mitigated by the `WCOMP_` prefix on every const/var (and the gospel's `WC_` is renamed up to `WCOMP_`). Grep confirms no collision.
- **Trap 3 (signed-ordering compare SIGSEGV)** — EXPOSED at the `ws_lookup_id` gate. The gospel correctly uses `== 0i32` (equality), NOT `< 0`. Preserved. All other comparisons are on `u64`/`u32` (unsigned ordering is safe). No `i32`/`i64` ordering anywhere.
- **Trap 4 (u32-in-u64-slot garbage before pointer math)** — EXPOSED: `q`, `nante_capped`, `cnt`, `k`, `ante_idx` are `u32` used in pointer offsets (`+ (q as u64)*32`). Avoidance: every `u32→u64` widen that feeds pointer arithmetic is masked `(x as u64) & 0xFFFFFFFFu64`, OR the offset is built from a `u64` loop counter. Specifically `(antp as u64 + (q as u64)*32u64)` must mask `q`: `((q as u64) & 0xFFFFFFFFu64) * 32u64`. Flagged for Phase 2.
- **Trap 5 (u32 pointer store width)** — NOT EXPOSED. No `*u32` store occurs; all id/payload writes are byte-wise inside the externs (`wh_get_frag_id`, `ident_from_bytes`) or per-byte `WCOMP_INBUF[z] = (… ) as u8` through `[u8]`.
- **Trap 6 (nested block comments)** — avoided; only `//` and single-level `/* */`.
- **Trap 7 (local `var` arrays)** — **HEAVILY EXPOSED** in the gospel: `aid`,`sum`,`fid`(×2),`ic`,`inbuf`,`antes` are all function-local `var` arrays → parse failure. Avoidance: ALL seven hoisted to module scope as `WCOMP_ANTE_TMP / WCOMP_RUN_SUM / WCOMP_FID_TMP / WCOMP_IN_COMMIT / WCOMP_INBUF / WCOMP_ANTES / WCOMP_OUT_FID` (Data Structures table). Consequence: non-reentrant — acceptable (single serialized compactor; same posture as the BUILT exemplars).
- **Trap 8 (`} else {` one line)** — N/A; the algorithm is expressible with single-line `if`/no `else`, matching the gospel.
- **Trap 9 (em-dash in comment)** — avoided; ASCII `--` only in all comments.
- **Trap 10 (`let mut flag` checkpoint)** — EXPOSED: `changed` in `wc_mark_retain` is exactly a `let mut … = …` flag. Avoidance: it drives the `while changed == 1u8` condition DIRECTLY (the recommended form), is reset at the top of each sweep, and set inside; it is the loop's governing variable, not an after-the-fact checkpoint, so it is in the safe usage class.
- **Trap 11 (`a % b` after a call)** — NOT EXPOSED. No modulo anywhere; run grouping uses only `+`/comparison and `min` via `if`.
- **Trap 12 (`@specialize *T` stride)** — N/A; no generics. All element strides are the literal `32u64`.

## Gap / Fix List
1. **WRONG keccak provider (defect #1).** Gospel: `extern … keccak256_init/update/final from "keccak.iii"`. `keccak.iii` exports only `keccak_f1600/absorb/squeeze/...` — NOT the `keccak256_*` streaming API. **Fix:** change the `from` clause to `"keccak256.iii"` for all three (verified exports at `keccak256.iii:46/52/62`).
2. **`ws_lookup_id` is a not-yet-built dependency.** `numera/witness_spine.iii` does not exist in `STDLIB/`; it is on the gospel's remaining-to-implement list (L1778). It is NOT fiction (the gospel's Layer-2 note L1734 explicitly assigns frag-id→idx resolution to the spine). **Fix:** keep the extern as specified with contract `ws_lookup_id(frag_id, out_idx) -> i32` (0 = hit, writes idx; non-zero = miss); mark `witness_spine.iii` as a hard predecessor so the wave scheduler builds it first. The compactor cannot link until the spine exists.
3. **witness_hook accessors not yet exported (defect #6).** `wh_get_ante_count` and `wh_get_ante` are NOT in the BUILT `witness_hook.iii` (confirmed: 11 exports, none of the field getters). Their bodies ARE specified in the gospel's Turn-One drop (L1854-1869). **Fix:** declare both externs (done); list them as Phase-2 additions to `witness_hook.iii`. Phase 2 must export them there before this module links. (Same applies to the optional `wh_get_out_commit` used only in KAT-5; if not exported, KAT-5 recomputes against a recorded golden instead.)
4. **`identifier.iii` path.** Gospel `from "identifier.iii"` resolves by basename, but the file physically lives at `numera/identifier.iii` (not `aether/`). No code change; documented so the scheduler maps the dependency to NN 01. `ident_copy` listed by the gospel is never called — dropped.
5. **Fragile inner-loop control flow (W14 / one-past-end read).** Gospel inner run-scan (L14570-14573) uses two sequential `if`s: `if WC_RETAIN[i]==1 { i=n }` then `if WC_RETAIN[i]==0 { i=i+1 }`. After the first sets `i=n`, the second reads `WCOMP_RETAIN[n]` — one slot past the live region (in-bounds of the 4 Mi array so not a crash, but it reads a stale/foreign slot and the logic is brittle). The post-run advance (L14625) `if WC_RETAIN[i]==1 { i=i+1 }` has the same shape. **Fix:** replace with the clean form in Algorithm §wc_run_compaction: an outer `while i<n` whose body is `if retained { i+=1 } else { open run; inner while (i<n && retain[i]==0) i+=1 }`. The inner loop's compound condition is a single guarded `while` (no `break`, W14-clean) and never indexes `WCOMP_RETAIN[n]`.
6. **`wc_init` zeroes all 4 Mi bytes every call.** Correct and bounded, but `wc_mark_retain`/`wc_run_compaction` call `wc_init()` lazily when `WCOMP_INITED==0`, which would re-zero the whole bitmap mid-life if ever called after a manual clear. **Fix:** keep the `WCOMP_INITED` guard exactly as gospel (init runs at most once unless `wc_init` is called explicitly); document that callers use `wc_clear_marks` (live-region only) between compaction cycles, never `wc_init`.
7. **Unchecked `wh_publish` failure.** Gospel increments `emitted` unconditionally even though `wh_publish` can return `0xFFFFFFFFFFFFFFFFu64` (chain full / payload overflow). **Fix:** gate `emitted = emitted + 1u32` on `r != 0xFFFFFFFFFFFFFFFFu64` (Algorithm §wc_run_compaction). A failed publish must not be counted as an emitted COMPACTION fragment (correctness + M10).
8. **Trap-4 mask on antecedent offset.** `(antp as u64 + (q as u64)*32u64)` — `q` is `u32`; mask it `((q as u64) & 0xFFFFFFFFu64)` before the multiply (Phase-2 codegen safety).
9. **Missing self-test.** The gospel body ships NO `wc_selftest`; every BUILT exemplar (`wh_selftest`, `merkle`/`keccak256_kat`) has one and Phase-2 acceptance requires it. **Fix:** add `wc_selftest() -> u64` implementing KATs 1-5 (skeleton stub included). This is the only NEW public fn beyond the gospel's five.

If the above 9 are applied, the module is COMPLETE: the mark/expand fixed-point, the run-grouping sweep, the Keccak-fold `out_commit`, the `Keccak256(start‖end)` `in_commit`, the 16-byte run-bounds payload, and the ≤32 inline antecedents all match the gospel's maximal intent with no down-scaling (4 Mi capacity retained) and no mandate/law violations remaining.

## Implementation Skeleton

```iii
/* III/STDLIB/iii/aether/witness_compactor.iii
 *
 * III STDLIB - aether::witness_compactor -- selective-retention chain compaction.
 *
 * Maintains a per-fragment retention bitmap, expands caller marks over the
 * transitive antecedent closure, groups maximal runs of consecutive
 * non-retained fragments, and publishes one COMPACTION fragment per run
 * (out_commit = Keccak256 fold of the run's fragment ids; in_commit =
 * Keccak256(run_start || run_end); payload = LE(run_start) || LE(run_end)).
 * The original fragments are never removed -- the chain is append-only; the
 * COMPACTION fragment is the canonical skip handle for chain-root verification.
 *
 * Hexad: kind_witness + kind_repair.  Ring: R-1.  K: 1.00.
 * Discipline: W8 (bounded bitmap), W14 (sentinel loops, no break), W15 (no
 *   recursion -- closure via iterated fixed-point sweep), W9/W10/W12 status
 *   returns.  Non-reentrant (module-scope scratch; single serialized compactor).
 *
 * Reconciliations vs. gospel candidate (see witness_compactor.spec.md Gap list):
 *   - keccak256_init/update/final externed from "keccak256.iii" (gospel said
 *     "keccak.iii" -- WRONG; that file lacks the streaming wrapper).
 *   - all 7 function-local var arrays hoisted to module scope (Trap 7).
 *   - WC_ prefix renamed to assigned WCOMP_ (Trap 2 namespace).
 *   - inner run-scan rewritten as a clean compound-guard while (no one-past-end
 *     read; no break).
 *   - wh_publish failure sentinel checked before counting (Gap 7).
 *   - wc_selftest added (Gap 9).
 *   - ws_lookup_id from witness_spine.iii and wh_get_ante_count/wh_get_ante from
 *     witness_hook.iii are NOT-YET-BUILT predecessors (see Dependencies).
 */
module aether_witness_compactor

extern @abi(c-msvc-x64) fn wh_next_idx() -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_get_frag_id(idx: u64, out_id: *u8) -> i32 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_get_ante_count(idx: u64) -> u32 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_get_ante(idx: u64, ante_idx: u32, out: *u8) -> i32 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ws_lookup_id(frag_id: *u8, out_idx: *u64) -> i32 from "witness_spine.iii"
extern @abi(c-msvc-x64) fn keccak256_init() -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn keccak256_update(input: *u8, len: u64) -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn keccak256_final(out: *u8) -> i32 from "keccak256.iii"

const WCOMP_OK             : i32 =  0i32
const WCOMP_E_BAD          : i32 = -1i32
const WCOMP_MAX_FRAGS      : u64 = 4194304u64
const WCOMP_MAX_ANTE       : u32 = 32u32
const WCOMP_ID_BYTES       : u64 = 32u64
const WCOMP_COMPACT_PHASE  : u8  = 9u8
const WCOMP_COMPACT_PILLAR : u16 = 5u16
const WCOMP_PRODUCER_LEN   : u64 = 25u64
const WCOMP_OPID_LEN       : u64 = 34u64

var WCOMP_RETAIN       : [u8; 4194304]   /* 1 byte/fragment, bit 0 = retained (W8 bound = WCOMP_MAX_FRAGS) */
var WCOMP_PRODUCER     : [u8; 32]
var WCOMP_OPID_COMPACT : [u8; 32]
var WCOMP_INITED       : u8 = 0u8

/* hoisted-from-local scratch (Trap 7) -- non-reentrant */
var WCOMP_ANTE_TMP     : [u8; 32]        /* one antecedent id during mark expansion */
var WCOMP_RUN_SUM      : [u8; 32]        /* COMPACTION out_commit (Keccak fold) */
var WCOMP_FID_TMP      : [u8; 32]        /* one fragment id during the fold */
var WCOMP_IN_COMMIT    : [u8; 32]        /* COMPACTION in_commit = K256(start||end) */
var WCOMP_INBUF        : [u8; 16]        /* LE(run_start)||LE(run_end) = in_commit preimage AND payload */
var WCOMP_ANTES        : [u8; 1024]      /* <=32 inline antecedent ids * 32 bytes */
var WCOMP_OUT_FID      : [u8; 32]        /* emitted COMPACTION fragment id sink */

/* self-test scratch */
var WCOMP_T_PROD       : [u8; 32]
var WCOMP_T_PAY        : [u8; 32]
var WCOMP_T_ANTE       : [u8; 32]

fn wc_init() -> i32 @export {
    // TODO: body per Algorithm wc_init -- zero WCOMP_RETAIN[0..WCOMP_MAX_FRAGS),
    // derive WCOMP_PRODUCER / WCOMP_OPID_COMPACT via ident_from_bytes, set WCOMP_INITED=1
}

fn wc_clear_marks() -> i32 @export {
    // TODO: body per Algorithm wc_clear_marks -- zero WCOMP_RETAIN[0..wh_next_idx())
}

fn wc_mark_retain(frag_idx: u64) -> i32 @export {
    // TODO: body per Algorithm wc_mark_retain -- lazy init; range-check vs WCOMP_MAX_FRAGS;
    // mark; then iterated fixed-point sweep (while changed==1u8) over [0,n) expanding
    // transitive antecedents via wh_get_ante_count/wh_get_ante + ws_lookup_id (gate == 0i32);
    // mask q-style u32->u64 widens before pointer math (Trap 4); no recursion (W15)
}

fn wc_is_retained(frag_idx: u64) -> u8 @export {
    // TODO: body per Algorithm wc_is_retained -- range-guard returns 0u8; else WCOMP_RETAIN[frag_idx]
}

fn wc_run_compaction() -> u32 @export {
    // TODO: body per Algorithm wc_run_compaction -- lazy init; outer while i<n:
    //   retained -> i+=1; else open run, inner while (i<n && WCOMP_RETAIN[i]==0u8) i+=1;
    //   fold out_commit over [run_start,run_end); pack WCOMP_INBUF=LE(start)||LE(end);
    //   ident_from_bytes -> WCOMP_IN_COMMIT; copy <=32 fids to WCOMP_ANTES (mask offsets);
    //   wh_publish(...,WCOMP_COMPACT_PHASE,WCOMP_COMPACT_PILLAR,...,WCOMP_INBUF,16u32,WCOMP_OUT_FID);
    //   if r != 0xFFFFFFFFFFFFFFFFu64 { emitted += 1 }  (Gap 7); return emitted
}

fn wc_selftest() -> u64 @export {
    // TODO: body per KAT Vectors 1-5 -- wh_init a fresh chain, publish deterministic
    // fragments, exercise mark/closure/run-grouping, assert emitted counts + payload
    // (run bounds) + transitive closure (KAT-4, exercises ws_lookup_id) + out_commit
    // reproducibility (KAT-5); return 99u64 on full pass, else first failing checkpoint #
}
```
