# 46 aether/context_awareness.iii — Implementation Spec

## Verdict
PARTIAL — the gospel candidate body is algorithmically near-complete and M3-clean (exact closed-form integer OLS, no observe-and-adapt), but it is **not buildable as written**: every module-level constant uses the `CA_` prefix, which collides with the already-built `numera/content_addr.iii` (`const CA_OK : i32 = 0i32`) under the linker-global-const trap (Trap 2). It also carries a fixed-point intercept/prediction unit bug, an unsealed underflow/overflow corner in the regression sums, and several W13/local-`var`-array trap exposures. All are mechanical fixes; the algorithm and intent are sound and maximal. Re-prefix to `CTXA_`, repair the listed defects, and it is complete.

## Purpose
`aether::context_awareness` is the substrate's analytic environmental accountant: it samples sixteen named pillar metrics into a context vector, computes a single fixed-point Coordinated Anomaly Detection (CAD) score as the sum of per-metric standardized squared positive deviations, maintains a 64-entry sliding window of those scores, fits an **exact closed-form ordinary-least-squares line** over the window, projects the score forward by a Quiescence drain horizon, and emits a `PREDICTIVE_QUIESCENCE` witness fragment when the projection crosses a constitutional threshold. It is a deterministic regression-and-projection pipeline, **not a learner** — there is no count-and-promote, no observe-and-adapt, no threshold-trained weights; the baseline (mu, sigma) is set explicitly by the Quiescence cycle, never inferred by this module. Hexad: `kind_witness + kind_motion`. Ring: R-1. K: 1.00.

## Public API
All signatures single-line (Trap 1). Return conventions per W9 (negative-`i32` errors), W10 (`u8` boolean), W12 (every public fn returns a status or sentinel-typed value).

```
fn ca_init() -> i32 @export
fn ca_set_metric(metric: u32, value: u64) -> i32 @export
fn ca_set_baseline(metric: u32, mu: u64, sigma: u64) -> i32 @export
fn ca_metric_at(metric: u32) -> u64 @export
fn ca_anomaly_score() -> u64 @export
fn ca_record_sample() -> u64 @export
fn ca_trend_coefficient(out_b: *i64) -> i32 @export
fn ca_predict(horizon: u32) -> u64 @export
fn ca_check_quiescence(threshold: u64, horizon: u32) -> u8 @export
```

Return-status notes:
- `ca_init` / `ca_set_metric` / `ca_set_baseline`: `CTXA_OK` (0) or `CTXA_E_BAD` (-1, bad metric index). W9/W12.
- `ca_metric_at`: sentinel-typed `u64` — returns `0u64` on out-of-range index (no separate error channel; documented). W12.
- `ca_anomaly_score` / `ca_record_sample` / `ca_predict`: sentinel-typed `u64` (the score / prediction; `0u64` when uninitialised or empty window). W12.
- `ca_trend_coefficient`: writes the fixed-point slope `b` (implicit denominator `2^16`) to `*out_b`; returns `CTXA_OK` or `CTXA_E_BAD` (uninitialised). W9/W12.
- `ca_check_quiescence`: `u8` (W10) — `1` iff projection ≥ threshold (and a witness was published), else `0`.

**9 public functions.** (`ca_deviation`, `ca_square_clamp`, `ca_add_clamp` are file-private helpers, not `@export`.)

## Constant Namespace
**PREFIX = `CTXA_`** (assigned). Grep confirms **zero** existing `CTXA_` symbols anywhere in the tree (`grep "^const CTXA" .` → no files). The gospel body's `CA_` prefix is **rejected**: `numera/content_addr.iii` already defines `const CA_OK : i32 = 0i32`, `const CA_E_NULL`, `const CA_BYTES`, and vars `CA_BUF/CA_A/CA_B/CA_C/CA_O/CA_O2`; `katabasis` corpus files also use `CA_*`. Under Trap 2 every module-scope const emits a linker-global `L_<NAME>`, so `CA_OK` here would duplicate `content_addr`'s `L_CA_OK` → multiple-definition link failure. Every const and module-scope var below is therefore `CTXA_`-prefixed.

| name | type | value | note |
|------|------|-------|------|
| `CTXA_OK`       | i32 | `0i32`        | success |
| `CTXA_E_BAD`    | i32 | `-1i32`       | bad metric index / uninitialised (W9) |
| `CTXA_N_METRICS`| u32 | `16u32`       | fixed metric count |
| `CTXA_WIN_SIZE` | u32 | `64u32`       | sliding-window length |
| `CTXA_FP_SHIFT` | u32 | `16u32`       | fixed-point shift |
| `CTXA_FP_ONE`   | u64 | `65536u64`    | `1 << 16` (also default sigma) |
| `CTXA_FP_ONE_I` | i64 | `65536i64`    | signed `1 << 16` for the regression/prediction math (avoids per-site literals) |
| `CTXA_DEV_MAX`  | u64 | `0xFFFFFFFFu64` | per-metric deviation clamp (square would overflow u64 above this) |
| `CTXA_U64_MAX`  | u64 | `0xFFFFFFFFFFFFFFFFu64` | saturating-add / square ceiling |
| `CTXA_SUM_T`    | u64 | `2016u64`     | Σt, t=0..63 = N(N-1)/2 — reference/KAT only |
| `CTXA_SUM_T2`   | u64 | `85344u64`    | Σt², t=0..63 = N(N-1)(2N-1)/6 — reference/KAT only |
| `CTXA_DET`      | u64 | `1397760u64`  | N·Σt² − (Σt)² for the full window — reference/KAT only |

(`CTXA_SUM_T/SUM_T2/DET` document the full-window closed form; the running code recomputes Σt, Σt² from the actual prefix length `n` so partial windows are exact — see Algorithm. They are retained as documented constants and KAT anchors, not as the live divisor, because `n < 64` before the window fills.)

The metric **slot indices** (0..15) are documented in the header comment, not as consts (they are positional and never appear as linker symbols). If Phase 2 prefers named slots, they MUST also be `CTXA_`-prefixed (e.g. `CTXA_M_PHASE_DEPTH`); flag if added.

## Data Structures
All module-scope (Trap 7: no local `var` arrays). Bounds are fixed and justified (W8).

| name | type | size (elems) | bytes | justification |
|------|------|-------------|-------|---------------|
| `CTXA_METRIC`     | `[u64; 16]` | 16 | 128  | one slot per metric; `CTXA_N_METRICS` fixed by the pillar taxonomy |
| `CTXA_BASE_MU`    | `[u64; 16]` | 16 | 128  | per-metric baseline mean, set by Quiescence |
| `CTXA_BASE_SIGMA` | `[u64; 16]` | 16 | 128  | per-metric tolerance σ; defaults to `CTXA_FP_ONE` to bar div-by-zero |
| `CTXA_WIN_SCORE`  | `[u64; 64]` | 64 | 512  | ring buffer of the last `CTXA_WIN_SIZE` anomaly scores |
| `CTXA_WIN_HEAD`   | `u32` (scalar) | — | 4 | next write index, mod 64 |
| `CTXA_WIN_FULL`   | `u8` (scalar)  | — | 1 | 1 once the ring has wrapped at least once |
| `CTXA_PRODUCER`   | `[u8; 32]`  | 32 | 32 | this module's producer identifier (Keccak256 of its name) |
| `CTXA_OPID_PREDICT`| `[u8; 32]` | 32 | 32 | op id for the predictive-quiescence operation |
| `CTXA_INITED`     | `u8` (scalar)  | — | 1 | one-shot init guard |
| `CTXA_INC`        | `[u8; 32]`  | 32 | 32 | module-scope `in_commit` scratch for `ca_check_quiescence` (replaces local `var in_c`) |
| `CTXA_OUTC`       | `[u8; 32]`  | 32 | 32 | module-scope `out_commit` scratch (replaces local `var out_c`) |
| `CTXA_PL`         | `[u8; 24]`  | 24 | 24 | module-scope witness payload scratch (replaces local `var pl`) |
| `CTXA_FID`        | `[u8; 32]`  | 32 | 32 | module-scope fragment-id out scratch (replaces local `var fid`) |

The four `CTXA_INC/OUTC/PL/FID` buffers are **new vs the gospel** — the gospel declares them as function-local `var` arrays inside `ca_check_quiescence`, which Trap 7 forbids (local `var [T; N]` parses only at module scope). Hoisting them is mandatory. `ca_check_quiescence` is non-reentrant as a result; acceptable — it is invoked serially from the orchestrator's single drain step (note in §Trap Exposure).

Total module-scope footprint ≈ 1.2 KiB — trivially within the small code model's RIP-relative reach.

## Dependencies (externs)
Linker resolves `from "<file>"` by **basename**, not path (confirmed: `aether/witness_hook.iii` itself declares `ident_from_bytes ... from "identifier.iii"` while the file physically lives at `numera/identifier.iii`). The gospel's `from` clauses are therefore correct as written.

```
extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_chain_root(out_id: *u8) -> i32 from "witness_hook.iii"
```

| extern | provider module (NN) | built? | verified against real file |
|--------|----------------------|--------|----------------------------|
| `ident_from_bytes` | Module 01 `numera/identifier.iii` (`module numera_identifier`) | **BUILT** | signature `(*u8,u64,*u8)->i32` matches exactly (identifier.iii:33) |
| `wh_publish` | Module 07 `aether/witness_hook.iii` (`module aether_witness_hook`) | **BUILT** | 12-param signature matches **byte-for-byte** (witness_hook.iii:144-148); returns fragment index (`u64`), `0xFFFF…FFFF` sentinel on failure |
| `wh_chain_root` | Module 07 `aether/witness_hook.iii` | **BUILT** | `(*u8)->i32` matches exactly (witness_hook.iii:216) |

**Not-yet-built dependencies: 0.** All three externs resolve to already-realized modules with signatures verified against the real provider files. The §3.5 systemic gospel defects (keccak `init/update/final` mis-file, `ws_emit_fragment` fiction, `cons_find`, `at_now`, `cap_verify`, `ed25519_sign`) **do not apply** — this module touches none of those symbols. The gospel's externs here are, unusually, all correct; the multi-line `wh_publish` extern in the gospel body must be folded to a single physical line on transcription (Trap 1).

The header comment's "16th metric is the entropy monitor's NTT spectral distance (Module 24, EM_PATH_ANOMALY)" is a **data-flow contract**, not an extern: the orchestrator pushes that value via `ca_set_metric(15, …)`. This module does not call the entropy monitor directly, so Module 24's build state does not gate it.

## Algorithm
NIH (M1): every routine is hand-rolled integer arithmetic; the only imports are identifier hashing and the witness hook. No floating point anywhere (W5/M2). No recursion (W15) — all loops are bounded `while` with a counter (W14, no `break`). No ML/heuristics (M3/M4): the baseline is supplied externally; the trend is exact closed-form OLS; the trigger is an exact comparison.

**`ca_init`** — zero the 16 metric slots; set `CTXA_BASE_MU[i]=0`, `CTXA_BASE_SIGMA[i]=CTXA_FP_ONE` (σ=1 unit bars division by zero, Trap-11-adjacent). Zero the 64-slot score ring; `CTXA_WIN_HEAD=0`, `CTXA_WIN_FULL=0`. Derive `CTXA_PRODUCER = ident_from_bytes("aether::context_awareness", 25)` and `CTXA_OPID_PREDICT = ident_from_bytes("aether::context_awareness::predictive_quiescence", 48)`. Set `CTXA_INITED=1`. Returns `CTXA_OK`. (Verify the two string byte-lengths at implementation time — 25 and 48 must match the literal lengths exactly, else the producer/opid ids differ and witnesses fail M10 reproducibility.)

**`ca_set_metric(metric,value)`** — range-check `metric < CTXA_N_METRICS` (else `CTXA_E_BAD`); store `value`. Pure write.

**`ca_set_baseline(metric,mu,sigma)`** — range-check; store `mu`; store `sigma` if non-zero, else substitute `CTXA_FP_ONE`. The two `if sigma == / != 0` writes from the gospel are correct and trap-safe (no ordering compare).

**`ca_metric_at(metric)`** — range-check → `0u64` on OOR, else return the slot.

**`ca_deviation(metric)` (private)** — `x = METRIC[i]`, `mu = BASE_MU[i]`. **Positive-deviation clamp:** if `x <= mu` return `0` ("less activity than baseline is not an anomaly"). Else `delta = x - mu`; `scaled = delta * CTXA_FP_ONE`; return `scaled / sigma`. Determinism: integer truncating division, total over the bit width (σ ≥ 1 guaranteed). **Fix:** clamp the result to `CTXA_DEV_MAX` (`0xFFFFFFFF`) before returning, so the subsequent square cannot exceed `u64`; the gospel relies on `ca_square_clamp` alone, but a `delta*65536` that overflows `u64` *before* the divide (delta ≥ 2^48) would already be wrong — guard `delta` first: if `delta >= (CTXA_U64_MAX >> CTXA_FP_SHIFT)` treat as `CTXA_DEV_MAX`. (M15 totality.)

**`ca_square_clamp(d)` (private)** — if `d >= CTXA_DEV_MAX` return `CTXA_U64_MAX`; else `d*d`. Exact; `d < 2^32` ⇒ `d*d < 2^64`.

**`ca_add_clamp(a,b)` (private)** — `sum=a+b`; if `sum < a` (wrap detected) return `CTXA_U64_MAX`; else `sum`. Saturating add — deterministic, no UB. (Note: `sum < a` is an **unsigned** ordering compare — permitted; Trap 3 forbids only *signed* `i32/i64` ordering compares.)

**`ca_anomaly_score`** — accumulate `acc = Σ_{i=0..15} ca_add_clamp(acc, ca_square_clamp(ca_deviation(i)))`. The CAD score: a fixed-point sum of standardized squared positive deviations. Bit-identical: every operand is a deterministic function of `METRIC`/`BASE_*`. Returns the saturating `u64` sum.

**`ca_record_sample`** — lazy-init guard; `score = ca_anomaly_score()`; write into the ring at `CTXA_WIN_HEAD`; advance head `(+1) mod 64`; set `CTXA_WIN_FULL=1` when head wraps to 0. **Trap-11 note:** the `% CTXA_WIN_SIZE` follows the `ca_anomaly_score()` call — modulo-after-call is the param-spill family. `CTXA_WIN_SIZE = 64` is a power of two, so Phase 2 MUST replace `(CTXA_WIN_HEAD + 1u32) % CTXA_WIN_SIZE` with the byte-mask `(CTXA_WIN_HEAD + 1u32) & (CTXA_WIN_SIZE - 1u32)` (= `& 63u32`). Same mask substitution everywhere `% CTXA_WIN_SIZE` appears (index computation in trend/predict). Returns the score.

**`ca_trend_coefficient(out_b)` — exact closed-form OLS slope.** Available count `n = WIN_FULL ? 64 : WIN_HEAD`. If `n < 2`, write `0` and return OK (a line needs ≥2 points). Map the oldest in-window sample to `t=0`, newest to `t=n-1`; sample `k` lives at ring index `(WIN_HEAD + WIN_SIZE − n + k) mod WIN_SIZE` (→ `& 63u32`). Accumulate in `i64`: `sum_y, sum_t, sum_t2, sum_ty`. Then `num = n·sum_ty − sum_t·sum_y`, `den = n·sum_t2 − sum_t·sum_t`. If `den == 0` write 0, return OK (compare-to-zero by equality only — Trap 3 safe). Else `b_fp = (num * CTXA_FP_ONE_I) / den` — the slope in `Q16.16` fixed point, signed truncating division toward zero. Write `*out_b = b_fp`. **Determinism/M2:** for fixed window contents the sums are exact integers (no overflow: `y ≤ 2^64−1` is clamped by the score, but `sum_ty` over 64 samples with `t ≤ 63` and `y` near `2^64` *can* overflow `i64`. **Gap fix:** the score domain must be bounded so `Σ t·y` fits `i64` — bound the per-sample score to `CTXA_DEV_MAX·16 ≈ 2^36` by construction (16 metrics × `(2^32)^2`-clamped square is the ceiling, but the realistic CAD score after clamping each `d<2^32` square and summing 16 of them is ≤ `16·(2^32) ≈ 2^36` only if each `d` is small; the saturating ceiling is `2^64`). To keep `sum_ty` inside `i64`, Phase 2 MUST either (a) right-shift each `y` by a fixed `CTXA_FP_SHIFT` before accumulation (consistently in trend AND predict, preserving the ratio), or (b) accumulate `sum_ty`/`sum_t2` with the same saturating discipline and document that a saturated window yields slope 0. Option (a) is preferred (keeps the slope meaningful). **This unit/overflow decision is the single largest correctness item — see Gap List.** No ML: `t` is the deterministic sample ordinal, never a learned feature.

**`ca_predict(horizon)` — line extrapolation.** `n` as above; if `n == 0` return 0. Recompute `sum_y, sum_t` over the same window mapping. Obtain `b_fp` via `ca_trend_coefficient(&b_fp)`. Intercept in fixed point: `a_fp = (sum_y·CTXA_FP_ONE_I − b_fp·sum_t) / n`. **Gospel unit bug (FIX):** the gospel writes `a_num = sum_y * 65536 − b_fp*sum_t`. Here `sum_y` is in *raw* units and `b_fp` is `Q16.16`; `sum_y·2^16` lifts raw→Q16.16, and `b_fp·sum_t` is already Q16.16 — units are consistent, so `a_fp` is correctly `Q16.16`. Then `t_pred = (n−1) + horizon`; `y_fp = a_fp + b_fp·t_pred` (both Q16.16). If `y_fp < 0` (equality-safe? **no** — this is a signed `< 0` ordering compare, **Trap 3 SIGSEGV**). **FIX:** replace `if y_fp < 0i64 { return 0u64 }` with a sign-bit test that uses no ordering compare: extract the sign via `((y_fp as u64) >> 63u64) & 1u64`; if that bit is 1 (negative) return `0u64`. Else return `(y_fp >> 16) as u64` (back to raw units). Deterministic exact extrapolation of the fitted line; bit-identical for fixed window.

**`ca_check_quiescence(threshold,horizon)` — exact trigger + witness.** Init guard → 0. `y_pred = ca_predict(horizon)`. If `y_pred < threshold` (**unsigned** `u64` ordering — permitted) return 0. Otherwise publish the `PREDICTIVE_QUIESCENCE` fragment: `wh_chain_root(&CTXA_INC)` for the in-commit; build the 24-byte payload `CTXA_PL` = `y_pred`(8 LE) ‖ `threshold`(8 LE) ‖ `horizon`(4 LE) ‖ `score_now`(low 4 LE), where `score_now = ca_anomaly_score()`; `ident_from_bytes(CTXA_PL, 24, &CTXA_OUTC)` for the out-commit; then `wh_publish(&CTXA_PRODUCER, &CTXA_OPID_PREDICT, &CTXA_INC, &CTXA_OUTC, revtag=0, phase=9, pillar=5, antecedents=&CTXA_PL, n_ante=0, payload=&CTXA_PL, payload_len=24, out_frag_id=&CTXA_FID)`. Return 1. **Determinism / M6 / M10:** the fragment id is `Keccak256` over the recorded fields; given the same `(y_pred, threshold, horizon, score_now)` the out-commit and fragment id recompute byte-identically. `pillar = 5u16` and `phase = 9u8` are within `WH_PILLAR_ID:[u16]` / `WH_PHASE_ID:[u8]` ranges (verified witness_hook.iii:55-56). `revtag = 0u8` ⇒ the fragment is reversible (W16/M9). **Payload-pointer-as-antecedents note:** the gospel passes `pp` for both `antecedents` and `payload` with `n_ante = 0`; with `n_ante = 0`, `wh_publish` never dereferences `antecedents` (witness_hook.iii:166 guards `if n_ante > 0`), so this is harmless — keep `n_ante = 0u32` and it is safe.

## KAT Vectors (>= 3)
A Phase-2 self-test checks these byte-for-byte. All values are exact integer arithmetic; no standard external vector applies (this is a substrate-internal analytic module), so the vectors are derived by hand from the closed form.

**KAT-1 — anomaly score, single metric, fixed point.**
`ca_init()`; `ca_set_baseline(0, mu=100, sigma=65536)` (σ = 1.0 in Q16.16); `ca_set_metric(0, 110)`. Then `ca_anomaly_score()`:
- `delta = 110 − 100 = 10`; `scaled = 10·65536 = 655360`; `d = 655360 / 65536 = 10`; `d² = 100`.
- All other 15 metrics: `x=0 ≤ mu=0` ⇒ deviation 0.
- **Expect `ca_anomaly_score() == 100u64`.**
Also assert the positive-deviation clamp: `ca_set_metric(0, 50)` (below mu) ⇒ **`ca_anomaly_score() == 0u64`** (proves the `x <= mu → 0` guard, the negative case).

**KAT-2 — flat window ⇒ zero slope, flat prediction.**
`ca_init()`; leave all baselines default (`mu=0`, σ=`FP_ONE`), all metrics `0`. Call `ca_record_sample()` 64 times (every score is `0`). Then:
- `ca_trend_coefficient(&b)` ⇒ **`b == 0i64`** (num = 0 since every `y=0`).
- `ca_predict(4)` ⇒ **`0u64`** (a = 0, b = 0).
- `ca_check_quiescence(threshold=1, horizon=4)` ⇒ **`0u8`** (0 < 1; no witness published — assert `wh` fragment count unchanged).

**KAT-3 — exact positive linear trend ⇒ exact slope + projection.**
`ca_init()`; default baselines. Drive a perfectly linear score sequence by setting one metric so that the recorded score equals `k` for `k = 0..63`: at step `k`, choose `mu=0, sigma=FP_ONE` and `metric0 = s_k` where `s_k` is the unique `u64` with `floor((s_k·65536)/65536)² = k` — simplest: pick scores `y_k = k` directly by injecting via a test shim, or analytically set `metric0` so `d_k = isqrt(k)` is exact for perfect squares. Cleanest deterministic form: feed `y_k = k` for `k=0..63` straight into `CTXA_WIN_SCORE` through `ca_record_sample` with a metric giving `d=√k` at the 8 perfect squares and asserting the slope on the full ramp. For a clean closed-form check, use `y_k = 2k` (achieved with the score-injection test path): then with `t=k`, the exact OLS slope is `b = 2` ⇒ `b_fp = 2·65536 = 131072`. **Expect `ca_trend_coefficient(&b)` ⇒ `b == 131072i64`.** Intercept `a = 0` ⇒ `a_fp = 0`; `ca_predict(0)` at `t=n−1=63` ⇒ `y = 2·63 = 126` ⇒ **`ca_predict(0) == 126u64`**; `ca_predict(4)` ⇒ `t_pred=67`, `y = 134` ⇒ **`ca_predict(4) == 134u64`**. Then **`ca_check_quiescence(threshold=130, horizon=4) == 1u8`** (134 ≥ 130) and a `PREDICTIVE_QUIESCENCE` fragment is published — assert the witness fragment count incremented by exactly 1 and re-derive its fragment id from the recorded payload to confirm M10 reproducibility.

**KAT-4 (sentinel / range) — defensive.**
`ca_set_metric(16, 1)` ⇒ **`CTXA_E_BAD`** (index == N_METRICS, out of range). `ca_metric_at(99)` ⇒ **`0u64`**. `ca_trend_coefficient` before any `ca_init` ⇒ **`CTXA_E_BAD`** (proves the init guard fails on the bad path, not just passes on the good one).

## Trap Exposure
| Trap | Exposed? | Avoidance |
|------|----------|-----------|
| 1 multi-line `fn` | YES (extern + risk) | Every `fn` signature single-line. The gospel's multi-line `wh_publish` **extern** and the wrapped fn prefixes MUST be folded to one physical line each on transcription. |
| 2 linker-global const | **YES (active failure)** | `CA_*` collides with `content_addr.iii`'s `CA_OK/CA_E_NULL/CA_BYTES`. **Re-prefix every const + module var to `CTXA_`.** Grep verified `CTXA_` is collision-free. |
| 3 signed ordering compare SIGSEGV | **YES** | `if y_fp < 0i64` in `ca_predict` is a signed ordering compare → replace with sign-bit test `((y_fp as u64) >> 63u64) & 1u64`. All other compares are either `==`/`!=` (den==0, init flags) or **unsigned** `u64` (`sum<a`, `y_pred<threshold`, `x<=mu`) which are permitted. Loop bounds `i < N`, `k < n` are `u32` unsigned — safe. |
| 4 u32-in-u64-slot garbage | Low | Ring indices are `u32` used in `% / &` then as array subscripts; the compiler subscript path is fine, but where an index is widened `as u64` for `(&ARR as u64)+off` pointer math, mask `& 0xFFFFFFFFu64` first. Element access here is via the `[idx]` subscript form, not raw pointer math, so exposure is minimal — still mask if Phase 2 lowers to `&ARR`-base arithmetic. |
| 5 u32 pointer store width | No | No `*u32` stores; payload bytes written through `*u8` (`CTXA_PL[z] = (… >> …) & 0xFF as u8`) — already byte-wise. |
| 6 nested `/* */` | YES (comments) | Header has multi-paragraph block comments — ensure no nested `/* */`; use `//` for any inline note inside a block. |
| 7 local `var` array | **YES (active)** | `ca_check_quiescence`'s local `var in_c/out_c/pl/fid` are forbidden. **Hoist to module scope** as `CTXA_INC/CTXA_OUTC/CTXA_PL/CTXA_FID`. Renders `ca_check_quiescence` non-reentrant — acceptable (serial drain-step caller). |
| 8 `} else {` one line | YES | The `n = (if WIN_FULL == 1u8 { WIN_SIZE } else { WIN_HEAD })` ternary and any `} else {` stay single-line. |
| 9 em-dash in comment | YES (comments) | Replace any `—` in the header/comments with ASCII `--`. |
| 10 `let mut` flag | Low | `CTXA_WIN_FULL` is a module-scope `u8` set once, not a `let mut` checkpoint flag; init/lazy-init use a module-scope guard. No fix needed, but avoid introducing `let mut … = 0u32` decision flags in Phase 2. |
| 11 `% ` after call | **YES** | `(CTXA_WIN_HEAD + 1u32) % CTXA_WIN_SIZE` follows `ca_anomaly_score()`; and the window-index `… % CTXA_WIN_SIZE` follows accumulation calls. `WIN_SIZE=64` is pow2 ⇒ replace **all** `% CTXA_WIN_SIZE` with `& (CTXA_WIN_SIZE − 1u32)` (= `& 63u32`). The `/ sigma` and `/ den` divisions are not moduli and are unavoidable; they are exact truncating divides, not the param-spill modulo case. |
| 12 `@specialize *T` stride | No | Module is not generic; no `@specialize`. |

## Gap / Fix List
The gospel body is a near-complete PARTIAL. Every defect with its fix:

1. **(BLOCKER, Trap 2) Const prefix collision.** All consts/vars use `CA_`; `numera/content_addr.iii` already exports `L_CA_OK` etc. → duplicate-symbol link failure. **Fix:** global rename `CA_*` → `CTXA_*` for all 8 consts and all module-scope vars (table in §Data Structures). Do NOT rename the `ca_*` *function* names (function symbols are distinct from `L_<const>` symbols, and grep confirms no `ca_*` fn collision in STDLIB) — keep the public API names exactly as the gospel/header advertise them.
2. **(BLOCKER, Trap 7) Local `var` arrays in `ca_check_quiescence`.** `var in_c/out_c/pl/fid : [u8;…]` are illegal locals. **Fix:** hoist to module-scope `CTXA_INC/CTXA_OUTC/CTXA_PL/CTXA_FID`; rewrite the body to reference them via `&CTXA_PL[0u64]` etc. Document non-reentrancy.
3. **(BLOCKER, Trap 3) Signed `< 0` in `ca_predict`.** `if y_fp < 0i64` SIGSEGVs iiis-0 codegen. **Fix:** `if (((y_fp as u64) >> 63u64) & 1u64) == 1u64 { return 0u64 }`.
4. **(CORRECTNESS, Trap 11) `% CTXA_WIN_SIZE` after calls.** Param-spill family can return a stale divisor. **Fix:** since 64 is pow2, use `& (CTXA_WIN_SIZE − 1u32)` at every site (record head advance + both window-index computations in trend/predict).
5. **(CORRECTNESS, M15/M2) Regression-sum overflow.** `sum_ty`/`sum_t2` accumulate `i64` over a window whose scores can saturate toward `2^64`; `Σ t·y` with `t≤63` overflows `i64` and silently corrupts the slope. **Fix:** before accumulation, right-shift each `y` by a fixed `CTXA_FP_SHIFT` *consistently in both `ca_trend_coefficient` and `ca_predict`* (preserving the slope ratio and intercept units), OR adopt saturating accumulation with a documented "saturated window ⇒ slope 0" rule. Prefer the consistent right-shift. Re-derive KAT-3 expectations against whichever is chosen. This is the one genuinely non-mechanical decision; flag for the implementer to lock the unit convention and pin it in a KAT.
6. **(CORRECTNESS, M15) Pre-divide overflow in `ca_deviation`.** `delta * CTXA_FP_ONE` overflows `u64` when `delta ≥ 2^48`. **Fix:** guard `if delta >= (CTXA_U64_MAX >> CTXA_FP_SHIFT) { return CTXA_DEV_MAX }` before the multiply; also clamp the divided result to `CTXA_DEV_MAX` so the downstream square is total.
7. **(ROBUSTNESS) Partial-window divisor.** The documented `CTXA_DET` is the full-N=64 determinant, but `ca_trend_coefficient` correctly recomputes `den` from the live `n`; ensure Phase 2 uses the recomputed `den`, not the constant, so partial windows (before fill) are exact. The const stays as documentation/KAT only. (No code change vs gospel — the gospel already recomputes; flagged so the implementer does not "optimize" it into the constant.)
8. **(M10/witness) Producer/opid string lengths.** `ident_from_bytes("…",25)` / `(…,48)` hardcode byte lengths. **Fix/verify:** assert the literals are exactly 25 and 48 bytes (count at implementation); a wrong length silently changes the producer/opid id and breaks witness reproducibility. Add a tiny KAT asserting `CTXA_PRODUCER` equals the known Keccak256 of the exact name bytes.
9. **(Trap 1) Multi-line externs/signatures.** The gospel's `wh_publish` extern and several fn headers wrap lines. **Fix:** every extern and every `fn` signature on one physical line.
10. **(Trap 6/9) Comment hygiene.** Audit the header block comment for any nested `/* */` or em-dash `—`; convert to `//`/ASCII `--`.

**M3 verdict (the dispatch's central concern): PASS — the trend logic is an analytic accountant, not a learner.** The OLS slope/intercept are exact closed-form functions of the window's recorded scores over the *fixed* ordinal axis `t=0..n−1`; there is no count-and-promote, no threshold that is *adjusted* by observed data, no weight updated across samples. The only "memory" is the raw score ring, which is replayed verbatim — not distilled into adapted parameters. The baseline `(mu, sigma)` is **set explicitly** by the Quiescence cycle (`ca_set_baseline`), never inferred inside this module; the header's "baseline recorded at end of each Quiescence cycle" describes the *caller's* action, and this module merely stores what it is told. The trigger `y_pred ≥ threshold` compares against a **constitutional** threshold passed in by the caller, not a learned one. No observe-and-adapt smell in the realized design. (One watch-item for Phase 2: do NOT add any auto-baseline-estimation helper that computes `mu/sigma` from `CTXA_WIN_SCORE` — that would convert the accountant into a learner and violate M3. If such a helper is ever wanted, it belongs in the Quiescence module as an explicit, witnessed, constitutional act, not here.)

## Implementation Skeleton
Structurally paste-ready. Single-line signatures (Trap 1). No fn bodies — Phase 2 writes those per Algorithm §. All consts/vars `CTXA_`-prefixed. `// TODO` markers reference the algorithm steps and the Gap/Fix items.

```iii
// III/STDLIB/iii/aether/context_awareness.iii
//
// III STDLIB - aether::context_awareness
// Coordinated anomaly detection + predictive quiescence.
// Analytic accountant (M3-clean): closed-form integer OLS, no learning.
//
// Sixteen metrics, slots 0..15 (positional; see spec for the named list).
// Sliding window: 64 most-recent anomaly scores. Exact OLS slope b (Q16.16);
// prediction y = a + b*(n-1+h). Witness: PREDICTIVE_QUIESCENCE on trigger.
//
// Hexad: kind_witness + kind_motion.  Ring: R-1.  K: 1.00.
// Discipline: W2, W8, W13, W14, W15.  PREFIX = CTXA_  (CA_ collides with content_addr.iii).

module aether_context_awareness

extern @abi(c-msvc-x64) fn ident_from_bytes(input: *u8, in_len: u64, out: *u8) -> i32 from "identifier.iii"
extern @abi(c-msvc-x64) fn wh_publish(producer: *u8, opid: *u8, in_commit: *u8, out_commit: *u8, revtag: u8, phase: u8, pillar: u16, antecedents: *u8, n_ante: u32, payload: *u8, payload_len: u32, out_frag_id: *u8) -> u64 from "witness_hook.iii"
extern @abi(c-msvc-x64) fn wh_chain_root(out_id: *u8) -> i32 from "witness_hook.iii"

const CTXA_OK        : i32 =  0i32
const CTXA_E_BAD     : i32 = -1i32

const CTXA_N_METRICS : u32 = 16u32
const CTXA_WIN_SIZE  : u32 = 64u32
const CTXA_FP_SHIFT  : u32 = 16u32
const CTXA_FP_ONE    : u64 = 65536u64
const CTXA_FP_ONE_I  : i64 = 65536i64
const CTXA_DEV_MAX   : u64 = 0xFFFFFFFFu64
const CTXA_U64_MAX   : u64 = 0xFFFFFFFFFFFFFFFFu64

// Full-window closed-form reference (t=0..63); KAT/doc anchors only --
// the live code recomputes Sum_t / Sum_t2 / den from the actual prefix n.
const CTXA_SUM_T     : u64 = 2016u64
const CTXA_SUM_T2    : u64 = 85344u64
const CTXA_DET       : u64 = 1397760u64

var CTXA_METRIC      : [u64; 16]
var CTXA_BASE_MU     : [u64; 16]
var CTXA_BASE_SIGMA  : [u64; 16]
var CTXA_WIN_SCORE   : [u64; 64]
var CTXA_WIN_HEAD    : u32 = 0u32
var CTXA_WIN_FULL    : u8  = 0u8

var CTXA_PRODUCER    : [u8; 32]
var CTXA_OPID_PREDICT: [u8; 32]
var CTXA_INITED      : u8  = 0u8

// Witness scratch hoisted from ca_check_quiescence (Trap 7: no local var arrays).
var CTXA_INC         : [u8; 32]
var CTXA_OUTC        : [u8; 32]
var CTXA_PL          : [u8; 24]
var CTXA_FID         : [u8; 32]

fn ca_init() -> i32 @export {
    // TODO: Algorithm ca_init -- zero metrics/baselines (sigma=CTXA_FP_ONE),
    // zero score ring, derive CTXA_PRODUCER/CTXA_OPID_PREDICT (verify 25/48
    // byte lengths, Gap 8), set CTXA_INITED. Return CTXA_OK.
}

fn ca_set_metric(metric: u32, value: u64) -> i32 @export {
    // TODO: range-check metric < CTXA_N_METRICS (else CTXA_E_BAD); store value.
}

fn ca_set_baseline(metric: u32, mu: u64, sigma: u64) -> i32 @export {
    // TODO: range-check; store mu; store sigma if !=0 else CTXA_FP_ONE.
}

fn ca_metric_at(metric: u32) -> u64 @export {
    // TODO: range-check -> 0u64 on OOR; else return CTXA_METRIC[metric].
}

fn ca_deviation(metric: u32) -> u64 {
    // TODO: x<=mu -> 0; guard delta pre-multiply overflow (Gap 6);
    // scaled=delta*CTXA_FP_ONE; clamp (scaled/sigma) to CTXA_DEV_MAX.
}

fn ca_square_clamp(d: u64) -> u64 {
    // TODO: d>=CTXA_DEV_MAX -> CTXA_U64_MAX; else d*d.
}

fn ca_add_clamp(a: u64, b: u64) -> u64 {
    // TODO: sum=a+b; if sum<a (unsigned wrap) -> CTXA_U64_MAX; else sum.
}

fn ca_anomaly_score() -> u64 @export {
    // TODO: acc = sum_{i<16} ca_add_clamp(acc, ca_square_clamp(ca_deviation(i))).
}

fn ca_record_sample() -> u64 @export {
    // TODO: lazy ca_init; score=ca_anomaly_score(); CTXA_WIN_SCORE[CTXA_WIN_HEAD]=score;
    // CTXA_WIN_HEAD=(CTXA_WIN_HEAD+1u32) & (CTXA_WIN_SIZE-1u32)  (Trap 11, Gap 4);
    // if head wrapped to 0 set CTXA_WIN_FULL=1. Return score.
}

fn ca_trend_coefficient(out_b: *i64) -> i32 @export {
    // TODO: n = WIN_FULL?WIN_SIZE:WIN_HEAD; n<2 -> *out_b=0, CTXA_OK.
    // Accumulate i64 sum_y/sum_t/sum_t2/sum_ty over k=0..n-1 with idx via & 63u32;
    // SHIFT y by CTXA_FP_SHIFT before accumulation (Gap 5 unit convention).
    // num=n*sum_ty - sum_t*sum_y; den=n*sum_t2 - sum_t*sum_t.
    // den==0 -> *out_b=0, CTXA_OK. Else *out_b=(num*CTXA_FP_ONE_I)/den.
}

fn ca_predict(horizon: u32) -> u64 @export {
    // TODO: n as above; n==0 -> 0. Recompute sum_y/sum_t (same SHIFT as trend, Gap 5).
    // b_fp via ca_trend_coefficient(&b_fp).
    // a_fp = (sum_y*CTXA_FP_ONE_I - b_fp*sum_t)/n.  t_pred=(n-1)+horizon.
    // y_fp = a_fp + b_fp*t_pred.
    // sign-bit test (Trap 3, Gap 3): if (((y_fp as u64)>>63u64)&1u64)==1u64 -> 0u64.
    // else return (y_fp >> 16i64) as u64.
}

fn ca_check_quiescence(threshold: u64, horizon: u32) -> u8 @export {
    // TODO: init guard -> 0. y_pred=ca_predict(horizon). if y_pred<threshold -> 0u8.
    // wh_chain_root(&CTXA_INC[0u64]); build CTXA_PL = y_pred|threshold|horizon|score_now;
    // ident_from_bytes(&CTXA_PL[0u64],24u64,&CTXA_OUTC[0u64]);
    // wh_publish(&CTXA_PRODUCER[0u64], &CTXA_OPID_PREDICT[0u64], &CTXA_INC[0u64],
    //   &CTXA_OUTC[0u64], 0u8, 9u8, 5u16, &CTXA_PL[0u64], 0u32,
    //   &CTXA_PL[0u64], 24u32, &CTXA_FID[0u64]);  return 1u8.
}
```
