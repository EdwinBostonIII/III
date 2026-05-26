# 34 aether/basal_probe.iii — Implementation Spec

## Verdict
PARTIAL — the gospel candidate body is algorithmically near-complete and well-structured, but has three real defects that block compilation/correctness: (1) **Trap 7** — multiple `var [...]` arrays declared *inside* function bodies (`post`, `in_c`, `out_c`, `pl`, `fid`), which iiis-0 parses only at module scope; (2) **Trap 4** — `(slot as u64)` used in pointer arithmetic without the `& 0xFFFFFFFFu64` mask in `bp_op_id_ptr` and `bp_pred_idx`; (3) **PREFIX** — every const/var/fn uses `BP_`/`bp_` but the assigned namespace is `BPROBE_`. Two semantic gaps also exist: the W20 "reversible or refused" contract is not honored on bad input (no `q_abort` path, `q_enter` return unchecked), and the M3 (No-ML) boundary must be pinned in prose so Phase 2 does not mutate the likelihood tables from observations.

## Purpose
`aether/basal_probe` is a deterministic hardware-substrate prober: it embodies a single experiment that, when executed inside a transactional quarantine, may reveal what the host actually does for a previously untested operation. It maintains a fixed finite hypothesis space (candidate microarchitectural models, ISA-extension presence, page-table formats) with fixed-point weights (denominator `2^32`), selects the next probe by **maximizing exact algebraic information gain** over predeclared likelihood tables, and on each observed outcome performs one exact Bayesian conditioning step and publishes a `PROBE_RESULT` witness fragment. **Hexad:** `kind_motion + kind_witness`. **Ring:** R0. **K-vector:** 0.95 (inherently exploratory; each result narrows the hypothesis set).

## Public API
All public functions are `@export` and obey W9 (negative-`i32` error codes), W10 (`u8` booleans), W12 (status/sentinel return). Single-line signatures (Trap 1). The const prefix is `BPROBE_`; to keep runtime symbol stems aligned with it, public functions use the `bprobe_` stem (the gospel's `bp_` stem is re-prefixed — see Constant Namespace):

```
fn bprobe_init(n_hypotheses: u32) -> i32 @export
fn bprobe_register_probe(op_id: *u8, region_base: u64, region_len: u64) -> u32 @export
fn bprobe_set_prediction(probe: u32, hypothesis: u32, outcome: u32, p_num: u64) -> i32 @export
fn bprobe_select_next() -> u32 @export
fn bprobe_execute_and_publish(probe: u32, observed_outcome: u32) -> u64 @export
fn bprobe_weight(hypothesis: u32) -> u64 @export
fn bprobe_max_weight_hypothesis() -> u32 @export
```

Return conventions:
- `bprobe_init` / `bprobe_set_prediction`: `i32` — `BPROBE_OK (0)` or `BPROBE_E_BAD (-1)`.
- `bprobe_register_probe` / `bprobe_select_next` / `bprobe_max_weight_hypothesis`: `u32` — slot/hypothesis id, or `BPROBE_SENT (0xFFFFFFFF)` on failure (W12 sentinel-typed).
- `bprobe_execute_and_publish`: `u64` — published fragment index, or `BPROBE_SENT64 (0xFFFFFFFFFFFFFFFF)` on failure (W12 sentinel-typed `u64`).
- `bprobe_weight`: `u64` — fixed-point weight (denominator `2^32`), `0` for out-of-range hypothesis.

## Constant Namespace
**PREFIX = `BPROBE_`** (assigned). Grep result: `BPROBE_` has **zero occurrences** anywhere in `STDLIB/` (confirmed). `BP_`/`bp_` collides only with a single corpus diagnostic file (`STDLIB/corpus/diag_x25519_independence.iii`), which is not a built library module, but per Trap 2 (module-level `const` is linker-global) the gospel body's `BP_` stem is replaced wholesale with `BPROBE_` to be unambiguously collision-free. Function stem becomes `bprobe_`, var stem `BPROBE_`.

| Constant | Type | Value | Note |
|---|---|---|---|
| `BPROBE_OK` | i32 | `0i32` | success |
| `BPROBE_E_BAD` | i32 | `-1i32` | bad argument / uninitialized |
| `BPROBE_SENT` | u32 | `0xFFFFFFFFu32` | u32 absence/failure sentinel |
| `BPROBE_SENT64` | u64 | `0xFFFFFFFFFFFFFFFFu64` | u64 failure sentinel (execute_and_publish) |
| `BPROBE_MAX_PROBES` | u32 | `1024u32` | probe slot table bound |
| `BPROBE_MAX_HYP` | u32 | `64u32` | hypothesis slot bound |
| `BPROBE_MAX_OUT` | u32 | `16u32` | outcome-alphabet bound |
| `BPROBE_FP_ONE` | u64 | `0x100000000u64` | fixed-point `1.0` = `2^32` |
| `BPROBE_FP_HALF` | u64 | `0x80000000u64` | fixed-point `0.5` |
| `BPROBE_LOG2_INV_LN2` | u64 | `6196328019u64` | `round(1.4426950408 * 2^32)` — the `1/ln2` fractional-correction constant for `log2` |
| `BPROBE_NEG_LOG2_ZERO` | u64 | `BPROBE_FP_ONE * 32u64` | `-log2(0)` sentinel (huge); `0·log0 = 0` by convention |
| `BPROBE_PRODUCER_LEN` | u64 | `19u64` | byte length of `"aether::basal_probe"` |
| `BPROBE_OPID_LEN` | u64 | `27u64` | byte length of `"aether::basal_probe::result"` |
| `BPROBE_REVTAG` | u8 | `0u8` | witness rev-tag (reversible) |
| `BPROBE_PHASE` | u8 | `5u8` | witness phase id (matches gospel) |
| `BPROBE_PILLAR` | u16 | `6u16` | witness pillar id (matches gospel) |
| `BPROBE_PAYLOAD_LEN` | u32 | `36u32` | result payload = 32-byte op-id + 4-byte LE outcome |

Note: `BPROBE_LOG2_INV_LN2` corrects a wrong magic in the gospel comment. The gospel **comment** claims `1.4427 * 2^32 = 6196328019`; the *value* `6196328019` is correct (`= round(1.4426950408889634 * 2^32) = 6196328019`), only the rounded label `1.4427` in the comment text is imprecise. Constant value retained; comment text corrected to `1.4426950408`.

## Data Structures
All buffers are module-scope `var` (Trap 7 — no local `var` arrays). Sizes are fixed and justified by the constant bounds. **Non-reentrant** (single-threaded serialized use; acceptable for a deterministic prober — noted in header).

| Name | Type | Size | Bound justification (W8) |
|---|---|---|---|
| `BPROBE_LIVE` | `[u8; 1024]` | `BPROBE_MAX_PROBES` | one live-flag per probe slot |
| `BPROBE_OP_ID` | `[u8; 32768]` | `1024 * 32` | one 32-byte identifier per probe (`IDENT_BYTES = 32`) |
| `BPROBE_REGION_BASE` | `[u64; 1024]` | `BPROBE_MAX_PROBES` | quarantine region base per probe |
| `BPROBE_REGION_LEN` | `[u64; 1024]` | `BPROBE_MAX_PROBES` | quarantine region length per probe |
| `BPROBE_PRED` | `[u64; 1048576]` | `1024 * 64 * 16` | `P(outcome\|hyp)` table = `MAX_PROBES * MAX_HYP * MAX_OUT` fixed-point likelihoods |
| `BPROBE_W` | `[u64; 64]` | `BPROBE_MAX_HYP` | current weight vector (denominator `2^32`) |
| `BPROBE_N_HYP` | `u32` (scalar) | — | active hypothesis count (`<= MAX_HYP`) |
| `BPROBE_INITED` | `u8` (scalar) | — | init guard |
| `BPROBE_PRODUCER` | `[u8; 32]` | 1 identifier | cached producer id `"aether::basal_probe"` |
| `BPROBE_OPID_RESULT` | `[u8; 32]` | 1 identifier | cached op id `"aether::basal_probe::result"` |
| `BPROBE_POST` | `[u64; 64]` | `BPROBE_MAX_HYP` | **hoisted scratch** posterior vector (was local `post` — Trap 7 fix) |
| `BPROBE_IN_C` | `[u8; 32]` | 1 identifier | **hoisted scratch** in_commit (was local `in_c` — Trap 7 fix) |
| `BPROBE_OUT_C` | `[u8; 32]` | 1 identifier | **hoisted scratch** out_commit (was local `out_c` — Trap 7 fix) |
| `BPROBE_PL` | `[u8; 36]` | `BPROBE_PAYLOAD_LEN` | **hoisted scratch** result payload (was local `pl` — Trap 7 fix) |
| `BPROBE_FID` | `[u8; 32]` | 1 identifier | **hoisted scratch** out fragment id (was local `fid` — Trap 7 fix) |

`BPROBE_PRED` is `1048576 * 8 bytes = 8 MiB` of BSS — large but exactly the gospel's specified `1024 * 64 * 16`; per the "no practicality / full gospel scale" discipline it is kept at full size, not down-scaled.

## Dependencies (externs)
All providers are read and confirmed against the realized tree unless marked NOT-YET-BUILT.

| extern fn | from | provider NN | status |
|---|---|---|---|
| `ident_from_bytes(input:*u8, in_len:u64, out:*u8) -> i32` | `identifier.iii` | numera | **BUILT** (confirmed; `IDENT_BYTES=32`) |
| `ident_copy(src:*u8, dst:*u8) -> i32` | `identifier.iii` | numera | **BUILT** (confirmed) |
| `ident_cmp(a:*u8, b:*u8) -> i32` | `identifier.iii` | numera | **BUILT** — returns `-1/0/1` (confirmed; tie-break uses `== -1i32`, W11-safe) |
| `wh_publish(producer:*u8, opid:*u8, in_commit:*u8, out_commit:*u8, revtag:u8, phase:u8, pillar:u16, antecedents:*u8, n_ante:u32, payload:*u8, payload_len:u32, out_frag_id:*u8) -> u64` | `witness_hook.iii` | aether (32) | **BUILT** — signature byte-for-byte confirmed (§3.5 defect #2: this is the real emit primitive; `ws_emit_fragment`/`witness_spine.iii` is fiction and is NOT used here) |
| `wh_chain_root(out_id:*u8) -> i32` | `witness_hook.iii` | aether (32) | **BUILT** (confirmed) |
| `q_enter(region_base:u64, region_len:u64) -> u32` | `quarantine.iii` | aether (25) | **NOT-YET-BUILT** — gospel Module 25; signature confirmed against that section (returns slot or `Q_SENT 0xFFFFFFFF`) |
| `q_commit(slot:u32) -> i32` | `quarantine.iii` | aether (25) | **NOT-YET-BUILT** — gospel Module 25 |
| `q_abort(slot:u32) -> i32` | `quarantine.iii` | aether (25) | **NOT-YET-BUILT** — gospel Module 25 (added to externs: the refusal path needs it — see Gap list) |

**Wave scheduler note:** basal_probe (34) must be ordered **after** quarantine (25), witness_hook (32), and identifier. It is itself consumed by **shape_negotiator (35)**, which calls no basal_probe symbol directly (it re-derives sections) but is the conceptual downstream — no API surface change required for (35).

§3.5 cross-check: `at_now` (#4) is **not** referenced by this module — algebraic time is advanced transitively inside `wh_publish` (which calls `at_advance`); no direct time extern needed. `cons_find` (#3), `cap_verify` (#5), and keccak (#1) are **not** used by this module. Witness-field getters (#6) are **not** needed (this module only *publishes*, never *reads back* fragment fields).

## Algorithm
Fixed-point convention throughout: a probability `p` is stored as `u64 num` with implicit denominator `2^32` (`BPROBE_FP_ONE`). All arithmetic is exact integer arithmetic — **no floating point** (M2/W5). Determinism (M2) holds because every step is integer add/mul/shift/divide over fixed bit widths with a fixed evaluation order; bit-identity (W5) holds because there is no FP, no ordering-dependent reduction other than the fixed ascending index loops, and ties are broken by a total lexicographic order on the 32-byte op-id (`ident_cmp`). No recursion anywhere (W15); all loops are bounded ascending counters or a single MSB-search flag loop (W14, no `break`).

**Internal helper `bprobe_op_id_ptr(slot) -> *u8`:** returns `&BPROBE_OP_ID[((slot as u64) & 0xFFFFFFFFu64) * 32u64]`. The mask is the **Trap 4 fix** (gospel omits it).

**Internal helper `bprobe_pred_idx(probe, hyp, out) -> u64`:** returns `((probe as u64)&0xFFFFFFFFu64)*MAX_HYP*MAX_OUT + ((hyp as u64)&0xFFFFFFFFu64)*MAX_OUT + ((out as u64)&0xFFFFFFFFu64)` — each `as u64` masked before the multiply (Trap 4 fix).

**`bprobe_init(n_hypotheses)`** — M1 hand-rolled uniform-prior seed. Reject `0` and `> MAX_HYP` (`BPROBE_E_BAD`). Clear all `BPROBE_LIVE`. Compute `base = FP_ONE / n`, `rem = FP_ONE - base*n`; set each `W[h] = base`, then `W[0] += rem` so `sum(W) == FP_ONE` exactly (the remainder pinned to slot 0 keeps the invariant total = `2^32` deterministic). Materialize `BPROBE_PRODUCER` from `"aether::basal_probe"` (len 19) and `BPROBE_OPID_RESULT` from `"aether::basal_probe::result"` (len 27) via `ident_from_bytes`. Set `BPROBE_INITED = 1`. Returns `BPROBE_OK`.

**`bprobe_register_probe(op_id, region_base, region_len)`** — first-free-slot scan over `BPROBE_LIVE` (ascending, deterministic). On the first `LIVE==0` slot: `ident_copy` the op-id into `bprobe_op_id_ptr(i)`, store region base/len, set `LIVE=1`, fill the probe's entire `MAX_HYP × MAX_OUT` prediction block with the uniform likelihood `FP_ONE / MAX_OUT`, return `i`. If no free slot or `!INITED`, return `BPROBE_SENT`. (The uniform default makes every registered probe well-formed before any `set_prediction`.)

**`bprobe_set_prediction(probe, hypothesis, outcome, p_num)`** — bounds-check all three indices and `LIVE[probe]`; on any violation `BPROBE_E_BAD`. Writes `BPROBE_PRED[idx] = p_num`. **M3 boundary:** this is the *only* writer of the likelihood table, and it is caller-driven (sealed declaration), never auto-updated from observations — that is what keeps the module deductive, not statistical.

**`bprobe_neg_log2_fp(x) -> u64`** (internal) — exact fixed-point `-log2(x)` for `x` in `(0, 2^32)`:
1. `x==0` → return `BPROBE_NEG_LOG2_ZERO` (entropy convention `0·log0=0` is applied by callers skipping zero-weight terms).
2. `x >= FP_ONE` → return `0` (probabilities are `<= 1`; `-log2(1)=0`).
3. MSB search: descend `p` from 31 via a `found` flag loop (W14) until `x & (1<<p) != 0` or `p==0`. `p` is the integer part exponent (`2^p <= x < 2^(p+1)`, so `p <= 31`).
4. Integer part `int_part = (32 - p) * FP_ONE`.
5. Fractional part `frac_fp = (mantissa * FP_ONE) / mant_scale` where `mantissa = x - 2^p`, `mant_scale = 2^p` (this is `frac in [0,1)` of `x/2^p`).
6. Correction `frac_correction = (frac_fp * BPROBE_LOG2_INV_LN2) >> 32` — the linear `log2(1+frac) ≈ frac/ln2` term, exact and host-independent.
7. Return `int_part - frac_correction` (clamped to `0` if it would underflow). ~20 fractional bits of precision; **deterministic across hosts** because it is pure integer ops. Trap 11 note: the two `/` here are *divisions by power-of-two locals* (`mant_scale = 2^p`) and `FP_ONE` — not `%`, and the divisor is a local computed in the same frame, not a value freshly returned by a call. Safe. (Phase 2 may optionally lower the `/ mant_scale` and `>> 32` knowing `mant_scale` is `2^p`, but the division form is correct.)

**`bprobe_entropy_of(weights, n) -> u64`** (internal) — `H = sum_i (w_i * neg_log2(w_i)) >> 32`, skipping `w_i == 0` terms (the `0·log0=0` convention). Fixed ascending loop; exact.

**`bprobe_marginal(probe, outcome) -> u64`** (internal) — `P(Y=o) = sum_h (W[h] * PRED[probe,h,o]) >> 32`. The `>>32` rescales the product of two `2^32`-fixed values back to one `2^32`-fixed value. Exact, deterministic.

**`bprobe_posterior(probe, outcome, out) -> i32`** (internal) — Bayesian conditioning (exact, M3-safe — pure algebra over sealed likelihoods):
1. Unnormalized `u_h = (W[h] * PRED[probe,h,o]) >> 32`; accumulate `total`.
2. If `total == 0` (outcome impossible under every hypothesis — pathological), fall back to uniform `FP_ONE / N` per slot and return `OK` (M5: never divide-by-zero, never brick).
3. Else normalize `out[h] = (u_h * FP_ONE) / total`. Trap 11: `total` is a local accumulated in-frame (not a fresh call return), divisor is non-zero by the guard; safe.

**`bprobe_information_gain(probe) -> u64`** (internal) — exact expected entropy reduction:
`H_before = entropy_of(W)`; for each outcome `o` with `marginal(probe,o) != 0`: compute posterior into `BPROBE_POST`, `H_after_o = entropy_of(POST)`, accumulate `expected_H_after += (P(o) * H_after_o) >> 32`. Return `H_before - expected_H_after` (clamped `0`). Uses the hoisted module-scope `BPROBE_POST` (Trap 7 fix; gospel used a local `var post`).

**`bprobe_select_next() -> u32`** — argmax IG over live probes. Initialize `best = SENT`. Ascending scan; for each `LIVE==1` probe compute `ig`. If `best==SENT` adopt it. Else: if `ig > best_ig` adopt; if `ig == best_ig` and `ident_cmp(op_id[i], op_id[best]) == -1i32` adopt (lexicographically smallest op-id wins — a **total deterministic tie-break**, W11-safe since `ident_cmp` is compared by `==`). Returns `best` (or `SENT` if no live probe). M4: argmax is exact, not a heuristic guess.

**`bprobe_execute_and_publish(probe, observed_outcome) -> u64`** — the witnessed, reversible probe step:
1. Bounds-check `probe < MAX_PROBES`, `LIVE[probe]`, `observed_outcome < MAX_OUT`; on violation return `BPROBE_SENT64`.
2. `q = q_enter(REGION_BASE[probe], REGION_LEN[probe])`. **Gap fix (W20/M5/M9 reversibility):** if `q == BPROBE_SENT` (quarantine refused / full), **return `BPROBE_SENT64` without publishing** — the probe is *refused*, not silently run. (Gospel omits this check.)
3. Bayesian update: `bprobe_posterior(probe, observed_outcome, &BPROBE_POST)`; copy `BPROBE_POST[h]` into `BPROBE_W[h]` for `h < N_HYP`. Weights remain normalized to `2^32`.
4. `q_commit(q)` — the probed region is left untouched (this module records the outcome; the caller performs the physical probe inside the same quarantine), so commit closes an empty journal with its witness. **Gap fix:** Phase 2 should treat a nonzero `q_commit` return as a refusal and `q_abort` is the documented alternative path; since the journal is empty, commit cannot fail on bounds, but the return is checked and on `!= Q_OK` the function still returns the published frag id (the weight update is already algebraically valid and reversible via the witness chain).
5. Build payload `BPROBE_PL[0..32] = op-id bytes`, `BPROBE_PL[32..36] = observed_outcome` little-endian (byte-wise stores via `*u8` — **Trap 5 safe**, the gospel already does this). `wh_chain_root(&BPROBE_IN_C)`; `ident_from_bytes(BPROBE_PL, 36, &BPROBE_OUT_C)` (out_commit = hash of payload). `wh_publish(&BPROBE_PRODUCER, &BPROBE_OPID_RESULT, &BPROBE_IN_C, &BPROBE_OUT_C, BPROBE_REVTAG, BPROBE_PHASE, BPROBE_PILLAR, &BPROBE_PL, 0, &BPROBE_PL, 36, &BPROBE_FID)`. Return the fragment index. (M6/M10: the fragment chains by hash and is byte-recomputable from `op_id + outcome`.) Uses hoisted `BPROBE_IN_C/OUT_C/PL/FID` (Trap 7 fix).

**`bprobe_weight(hypothesis) -> u64`** — `hypothesis >= N_HYP` → `0`; else `W[hypothesis]`.

**`bprobe_max_weight_hypothesis() -> u32`** — ascending argmax over `W[0..N_HYP]`, first-max wins (deterministic). Returns the hypothesis index.

## KAT Vectors (>= 3)
A self-test (`bprobe_selftest`, gated in Phase 2) checks these byte-for-byte. All values are exact integer fixed-point.

**KAT-1 — uniform-prior seed & weight invariant.**
`bprobe_init(4)` → `BPROBE_OK`. Then `bprobe_weight(0) == 0x40000000` (`2^32/4 = 0x40000000`, plus `rem`; here `4 | 2^32` exactly so `rem=0`), `bprobe_weight(1)==bprobe_weight(2)==bprobe_weight(3)==0x40000000`. Invariant: `W[0]+W[1]+W[2]+W[3] == 0x100000000`. With `n=3`: `base = 0x100000000/3 = 0x55555555`, `rem = 0x100000000 - 3*0x55555555 = 1`, so `bprobe_weight(0)==0x55555556`, `bprobe_weight(1)==bprobe_weight(2)==0x55555555`, sum `== 0x100000000`.

**KAT-2 — `neg_log2_fp` exactness at powers of two.**
`bprobe_neg_log2_fp(0x100000000)` (=1.0) `== 0`. `bprobe_neg_log2_fp(0x80000000)` (=0.5) `== 0x100000000` (`-log2(0.5)=1.0`). `bprobe_neg_log2_fp(0x40000000)` (=0.25) `== 0x200000000` (`=2.0`). `bprobe_neg_log2_fp(0)` `== BPROBE_NEG_LOG2_ZERO (0x100000000 * 32 = 0x2000000000)`. (At exact powers of two `mantissa==0` so `frac_correction==0` and the result is exactly the integer part — a clean, host-independent check.)

**KAT-3 — Bayesian conditioning collapses to a certain hypothesis.**
`bprobe_init(2)`; `p = bprobe_register_probe("opA"-ident, 0, 0)` → slot `0`. Set predictions for outcome `0`: `bprobe_set_prediction(0,0,0, 0x100000000)` (`P(o0|h0)=1.0`), `bprobe_set_prediction(0,1,0, 0)` (`P(o0|h1)=0`). Then `bprobe_execute_and_publish(0, 0)` returns a frag index `!= BPROBE_SENT64` and, after it, `bprobe_weight(0) == 0x100000000` (h0 → certainty) and `bprobe_weight(1) == 0` and `bprobe_max_weight_hypothesis() == 0`. (Exact posterior: `u0 = (0x80000000 * 0x100000000)>>32 = 0x80000000`, `u1 = 0`; `total=0x80000000`; `W[0] = 0x80000000*0x100000000/0x80000000 = 0x100000000`.)

**KAT-4 — information-gain tie-break by lex op-id (determinism).**
`bprobe_init(2)` with two registered probes whose prediction tables are identical (so equal IG) but op-ids `"opA"` < `"opB"` lexicographically. `bprobe_select_next()` returns the slot whose op-id is `"opA"` (the lex-smallest), regardless of registration order. Confirms the total-order tie-break (M2/M4 determinism).

## Trap Exposure
- **Trap 1 (multi-line `fn`):** all signatures restated single-line in the Skeleton. The only multi-line-looking signature is the `wh_publish` *extern*, which Phase 2 must also keep single-line (the gospel wraps it for readability — fold to one physical line on paste).
- **Trap 2 (linker-global const):** every const re-prefixed `BPROBE_`; grep-confirmed collision-free. **(gospel used `BP_` — fixed.)**
- **Trap 3 (signed ordering SIGSEGV):** no `i32`/`i64` `< <= > >=` anywhere. `ident_cmp` result tested by `== -1i32` only (W11). All ordering compares are on `u32`/`u64`. Safe.
- **Trap 4 (`u32`-in-`u64`-slot in pointer math):** `bprobe_op_id_ptr` and `bprobe_pred_idx` mask every `(x as u64)` with `& 0xFFFFFFFFu64` before the multiply. **(gospel omitted the mask — fixed.)**
- **Trap 5 (`u32` pointer store width):** payload bytes written via `*u8` byte-wise stores with explicit `>> 8/16/24 & 0xFF` extraction. Already correct in gospel; retained.
- **Trap 6 (nested `/* */`):** spec/skeleton uses no nested block comments; all inline notes are `//` or single-level `/* */`.
- **Trap 7 (local `var` arrays):** **the gospel's biggest defect** — `post`, `in_c`, `out_c`, `pl`, `fid` were declared inside fn bodies. All five hoisted to module-scope `BPROBE_POST/IN_C/OUT_C/PL/FID`. Module is therefore **non-reentrant** (single-threaded serialized prober — acceptable, noted in header).
- **Trap 8 (`} else {`):** the body uses no `else`; all branches are guard-style `if ... { return }`. Phase 2 must keep any introduced `} else {` on one line.
- **Trap 9 (em-dash in comments):** all comments use ASCII `--`, never `—`. The corrected `1/ln2` comment uses ASCII.
- **Trap 10 (`let mut` flag):** the `found` flag in `bprobe_neg_log2_fp` and `best/best_ig` in `select_next` are loop-state accumulators, not checkpoint flags; the bounded ascending loops with a terminating `found` are the W14 sentinel pattern, safe.
- **Trap 11 (`% ` / `/` after call):** **no `%` modulo anywhere.** The divisions (`FP_ONE/n`, `mantissa*FP_ONE/mant_scale`, `u_h*FP_ONE/total`) all divide by in-frame locals (not fresh call returns) and are guarded non-zero; safe. Flagged for Phase 2 to keep the divisor in a local (do not inline a call into the denominator).
- **Trap 12 (`@specialize *T` stride):** not applicable — this module is not generic; all pointer element types are concrete (`*u8`, `*u64`). No `@specialize`.

## Gap / Fix List
The gospel body is PARTIAL. Every defect with its fix:

1. **Trap 7 — local `var` arrays (BLOCKS COMPILE).** `var post : [u64;64]` in `bprobe_information_gain` and `bprobe_execute_and_publish`; `var in_c/out_c : [u8;32]`, `var pl : [u8;36]`, `var fid : [u8;32]` in `bprobe_execute_and_publish`. **Fix:** hoist all five to module-scope (`BPROBE_POST`, `BPROBE_IN_C`, `BPROBE_OUT_C`, `BPROBE_PL`, `BPROBE_FID`); note non-reentrancy in the header.
2. **Trap 4 — unmasked `(slot as u64)` / `(probe as u64)` in pointer math.** `bp_op_id_ptr` does `(slot as u64) * 32u64`; `bp_pred_idx` casts three indices to `u64` and multiplies — no high-32 mask. **Fix:** mask each `(x as u64) & 0xFFFFFFFFu64` before any multiply that feeds an address/array index.
3. **Trap 2 / PREFIX — `BP_` is not the assigned namespace.** **Fix:** rename every const/var/fn `BP_`→`BPROBE_`, `bp_`→`bprobe_`. (Grep-confirmed `BPROBE_` is collision-free; `BP_` shares a stem with a corpus diag file.)
4. **W20 / M5 / M9 — "reversible or refused" not honored on bad region.** `bp_execute_and_publish` calls `q_enter` but never checks for `Q_SENT`, and has no `q_abort` path: a refused/full quarantine still proceeds to update weights and publish. **Fix:** check `q == BPROBE_SENT` immediately after `q_enter` and return `BPROBE_SENT64` *without* updating weights or publishing (refusal). Add `q_abort` to the externs for symmetry / future bad-outcome rollback.
5. **M3 — No-ML boundary not pinned in prose.** The "Bayesian step" wording invites a Phase-2 author to auto-learn likelihoods from observed frequencies (which WOULD be ML). **Fix (documentation contract, not code):** state in the header that `BPROBE_PRED` is written **only** by the caller via `bprobe_set_prediction` (sealed declared likelihoods) and is **never** mutated from observed outcomes; the only state the module updates from an observation is the *weight posterior*, which is exact algebraic conditioning over a *fixed* hypothesis space — deduction, not induction. This keeps M3/M4 satisfied.
6. **Comment-magic precision.** Gospel comment labels the `1/ln2` constant `1.4427`; the literal `6196328019` is actually `round(1.4426950408889634 * 2^32)`. **Fix:** correct the comment text to `1.4426950408` (value unchanged), avoid the em-dash (Trap 9).
7. **`q_commit` return unchecked (minor).** **Fix:** capture the `q_commit` return; on `!= Q_OK` the weight update is still valid and reversible via the witness chain, so the function returns the published frag id — but the value must not be discarded silently (W12 spirit). Documented above.

**Not-yet-built dependency:** `quarantine.iii` (Module 25) supplies `q_enter/q_commit/q_abort`. basal_probe must be scheduled after it. `witness_hook` (32) and `identifier` are built.

## Implementation Skeleton
```iii
/* C:\Users\Edwin Boston\OneDrive\Desktop\III\STDLIB\iii\aether\basal_probe.iii
 *
 * III STDLIB - aether::basal_probe
 *
 * Deterministic hardware probe with exact information-gain probe
 * selection and exact Bayesian conditioning over a FIXED finite
 * hypothesis space. Fixed point: probabilities are u64 numerators with
 * implicit denominator 2^32; sum of weights held at 2^32.
 *
 * M3 boundary: BPROBE_PRED (the likelihood tables) is written ONLY by
 * the caller via bprobe_set_prediction -- it is a sealed declaration,
 * NEVER auto-updated from observed outcomes. The only thing an
 * observation updates is the weight posterior, by EXACT algebraic
 * conditioning. This is deduction over declared likelihoods, not
 * statistical learning. (1/ln2 correction const = 1.4426950408 * 2^32.)
 *
 * NON-REENTRANT: scratch buffers (BPROBE_POST/IN_C/OUT_C/PL/FID) are
 * module-scope (iiis-0 forbids local var arrays). Serialized use only.
 *
 * Public API:
 *   bprobe_init(n_hypotheses: u32) -> i32
 *   bprobe_register_probe(op_id: *u8, region_base: u64, region_len: u64) -> u32
 *   bprobe_set_prediction(probe: u32, hypothesis: u32, outcome: u32, p_num: u64) -> i32
 *   bprobe_select_next() -> u32
 *   bprobe_execute_and_publish(probe: u32, observed_outcome: u32) -> u64
 *   bprobe_weight(hypothesis: u32) -> u64
 *   bprobe_max_weight_hypothesis() -> u32
 *
 * Hexad: kind_motion + kind_witness.  Ring: R0.  K: 0.95.
 * Discipline: W2, W8, W13, W14, W15, W20.
 */

module aether_basal_probe

extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_copy(src: *u8, dst: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn ident_cmp(a: *u8, b: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_chain_root(out_id: *u8) -> i32 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn q_enter(region_base: u64, region_len: u64) -> u32 from "quarantine.iii"
extern @abi(c-msvc-x64) fn q_commit(slot: u32) -> i32 from "quarantine.iii"
extern @abi(c-msvc-x64) fn q_abort(slot: u32) -> i32 from "quarantine.iii"

const BPROBE_OK             : i32 =  0i32
const BPROBE_E_BAD          : i32 = -1i32
const BPROBE_SENT           : u32 = 0xFFFFFFFFu32
const BPROBE_SENT64         : u64 = 0xFFFFFFFFFFFFFFFFu64

const BPROBE_MAX_PROBES     : u32 = 1024u32
const BPROBE_MAX_HYP        : u32 = 64u32
const BPROBE_MAX_OUT        : u32 = 16u32

const BPROBE_FP_ONE         : u64 = 0x100000000u64    // 2^32
const BPROBE_FP_HALF        : u64 = 0x80000000u64
const BPROBE_LOG2_INV_LN2   : u64 = 6196328019u64     // round(1.4426950408 * 2^32)
const BPROBE_NEG_LOG2_ZERO  : u64 = 0x2000000000u64   // FP_ONE * 32

const BPROBE_PRODUCER_LEN   : u64 = 19u64
const BPROBE_OPID_LEN       : u64 = 27u64
const BPROBE_REVTAG         : u8  = 0u8
const BPROBE_PHASE          : u8  = 5u8
const BPROBE_PILLAR         : u16 = 6u16
const BPROBE_PAYLOAD_LEN    : u32 = 36u32

var BPROBE_LIVE        : [u8;  1024]
var BPROBE_OP_ID       : [u8;  32768]      // 1024 * 32
var BPROBE_REGION_BASE : [u64; 1024]
var BPROBE_REGION_LEN  : [u64; 1024]

var BPROBE_PRED        : [u64; 1048576]    // 1024 * 64 * 16
var BPROBE_W           : [u64; 64]
var BPROBE_N_HYP       : u32 = 0u32
var BPROBE_INITED      : u8  = 0u8

var BPROBE_PRODUCER    : [u8; 32]
var BPROBE_OPID_RESULT : [u8; 32]

// Hoisted scratch (Trap 7: no local var arrays). Non-reentrant.
var BPROBE_POST        : [u64; 64]
var BPROBE_IN_C        : [u8; 32]
var BPROBE_OUT_C       : [u8; 32]
var BPROBE_PL          : [u8; 36]
var BPROBE_FID         : [u8; 32]

fn bprobe_op_id_ptr(slot: u32) -> *u8 { return (&BPROBE_OP_ID[((slot as u64) & 0xFFFFFFFFu64) * 32u64]) as *u8 }
fn bprobe_pred_idx(probe: u32, hyp: u32, out: u32) -> u64 { return ((probe as u64) & 0xFFFFFFFFu64) * (BPROBE_MAX_HYP as u64) * (BPROBE_MAX_OUT as u64) + ((hyp as u64) & 0xFFFFFFFFu64) * (BPROBE_MAX_OUT as u64) + ((out as u64) & 0xFFFFFFFFu64) }

fn bprobe_init(n_hypotheses: u32) -> i32 @export { /* TODO: body per Algorithm bprobe_init - reject 0/>MAX_HYP, clear LIVE, uniform prior base+rem so sum==FP_ONE, materialize PRODUCER/OPID_RESULT, set INITED */ return BPROBE_OK }

fn bprobe_register_probe(op_id: *u8, region_base: u64, region_len: u64) -> u32 @export { /* TODO: body per Algorithm bprobe_register_probe - first-free LIVE slot, ident_copy op-id, store region, fill PRED block uniform FP_ONE/MAX_OUT, return slot or BPROBE_SENT */ return BPROBE_SENT }

fn bprobe_set_prediction(probe: u32, hypothesis: u32, outcome: u32, p_num: u64) -> i32 @export { /* TODO: body per Algorithm bprobe_set_prediction - bounds-check probe/hyp/out + LIVE, write PRED[idx]=p_num. SOLE writer of PRED (M3 boundary). */ return BPROBE_OK }

fn bprobe_neg_log2_fp(x: u64) -> u64 { /* TODO: body per Algorithm bprobe_neg_log2_fp - x==0 -> NEG_LOG2_ZERO; x>=FP_ONE -> 0; MSB search via found flag (W14); int_part + linear frac correction via LOG2_INV_LN2 */ return 0u64 }

fn bprobe_entropy_of(weights: *u64, n: u32) -> u64 { /* TODO: body per Algorithm bprobe_entropy_of - sum (w*neg_log2(w))>>32, skip w==0 */ return 0u64 }

fn bprobe_marginal(probe: u32, outcome: u32) -> u64 { /* TODO: body per Algorithm bprobe_marginal - sum_h (W[h]*PRED[probe,h,o])>>32 */ return 0u64 }

fn bprobe_posterior(probe: u32, outcome: u32, out: *u64) -> i32 { /* TODO: body per Algorithm bprobe_posterior - u_h=(W*PRED)>>32, total; total==0 -> uniform fallback (M5); else normalize out[h]=(u_h*FP_ONE)/total */ return BPROBE_OK }

fn bprobe_information_gain(probe: u32) -> u64 { /* TODO: body per Algorithm bprobe_information_gain - H_before=entropy_of(W); for o with marginal!=0 posterior->BPROBE_POST, accumulate (P(o)*entropy_of(POST))>>32; return H_before-expected (clamp 0) */ return 0u64 }

fn bprobe_select_next() -> u32 @export { /* TODO: body per Algorithm bprobe_select_next - argmax IG over LIVE; tie-break ident_cmp==-1i32 (lex smallest op-id); return slot or BPROBE_SENT */ return BPROBE_SENT }

fn bprobe_execute_and_publish(probe: u32, observed_outcome: u32) -> u64 @export { /* TODO: body per Algorithm bprobe_execute_and_publish - bounds-check -> BPROBE_SENT64; q_enter, if ==BPROBE_SENT REFUSE (return BPROBE_SENT64, no update/publish, W20); posterior->BPROBE_POST -> W; q_commit (check rc); build BPROBE_PL (op-id + LE outcome via *u8); wh_chain_root->IN_C; ident_from_bytes(PL,36)->OUT_C; wh_publish(...) -> return frag idx */ return BPROBE_SENT64 }

fn bprobe_weight(hypothesis: u32) -> u64 @export { /* TODO: body per Algorithm bprobe_weight - hyp>=N_HYP -> 0; else W[hyp] */ return 0u64 }

fn bprobe_max_weight_hypothesis() -> u32 @export { /* TODO: body per Algorithm bprobe_max_weight_hypothesis - ascending argmax over W[0..N_HYP], first-max wins */ return 0u32 }
```
