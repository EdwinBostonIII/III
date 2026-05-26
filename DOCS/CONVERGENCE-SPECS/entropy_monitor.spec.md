# 24 numera/entropy_monitor.iii — Implementation Spec

## Verdict
PARTIAL — the candidate `.iii` body is a *real, mathematically-correct* deterministic decimation-in-time NTT over `GF(998244353)` (parameters, omega derivation, butterflies, and field arithmetic all verified correct), but it is **not buildable as written** (Trap 7: two local `var` arrays in `em_spectrum`), it uses the **wrong const prefix** (`EM_` instead of the dispatch-assigned `ENTROPY_`), it carries **multiple Trap-11 raw `%` modulos**, and it omits four mandate-level capabilities that the maximal intent requires: witness continuity (M6/M10), capability mediation of the baseline mutation (M8), an algebraic-time stamp (W16/W17), and an explicit cost bound (M19). It is **not** an ML/observe-and-adapt design — the analytic-accountant intent is honored (see M3/M4 note below) — so the fixes are mechanical + additive, not a redesign.

## Purpose
`numera::entropy_monitor` is the substrate's **deterministic spectral accountant** for per-hot-path execution-time signatures. It maintains, per registered path, a fixed-length circular buffer of the most-recent 64 timing samples and computes the **exact** finite-field number-theoretic transform (NTT) of that buffer over `GF(p)`, `p = 998244353`, primitive root `g = 3`, transform length `N = 64`. The NTT spectrum is an algebraic fingerprint; an explicitly-registered **baseline** spectrum is stored per path, and the module reports the exact in-field squared-Euclidean distance between a candidate spectrum and the baseline. It **computes** a closed-form measure over recorded inputs; it never *learns*, adapts, or auto-promotes a threshold (M3/M4). **Hexad:** `kind_witness + kind_essence`. **Ring:** R0. **K-vector:** 1.00.

## Public API
All public fns return a status `i32` (W9/W12: `ENTROPY_OK = 0`, errors negative) **except** the two value-returning probes, which return a full-register `u64` sentinel to dodge the sub-word-return-across-extern hazard (W16; the same hazard `bigint_eq_u64` documents). Every signature is **single-line** (Trap 1).

```
fn entropy_init() -> i32 @export
fn entropy_register_path(path_id: *u8) -> u32 @export
fn entropy_sample(path_slot: u32, time_value: u64) -> i32 @export
fn entropy_spectrum(path_slot: u32, out_spectrum: *u64) -> i32 @export
fn entropy_set_baseline(path_slot: u32, spectrum: *u64, cap: u64) -> i32 @export
fn entropy_distance(path_slot: u32, spectrum: *u64) -> u64 @export
fn entropy_witness(path_slot: u32, out_hash: *u8) -> i32 @export
fn entropy_selftest() -> u64 @export
```

Return-status notes:
- `entropy_init` → `ENTROPY_OK`.
- `entropy_register_path` → slot index `0..ENTROPY_MAX_PATHS-1`, or `0xFFFFFFFFu32` sentinel when the table is full (W12 sentinel-typed return; matches `big_alloc_slot` house pattern).
- `entropy_sample`, `entropy_spectrum`, `entropy_set_baseline`, `entropy_witness` → `ENTROPY_OK` / negative `i32`.
- `entropy_distance` → `u64` field element in `[0, p)`; returns `0u64` for invalid slot or unset baseline (caller distinguishes via `entropy_distance` only after confirming baseline-set, exactly as the candidate does). Full-register return (W16).
- `entropy_selftest` → `0u64` on all-KAT-pass, else a non-zero bitmask of failing KAT ids (full-register; house pattern matches `keccak256_kat`, `at_selftest`).

`entropy_set_baseline` gains a fourth parameter `cap` — a **capability token** (M8): baseline installation is a privileged state mutation (it redefines what "anomalous" means for a path) and MUST be capability-gated. `cap` is the caller's capability handle; the module checks `cap != 0u64` and folds it into the witness (see Algorithm). Still ≤4 params (W2). This is the one signature change from the candidate.

## Constant Namespace
**PREFIX = `ENTROPY_`** (dispatch-assigned). Grep result: `grep -rn "ENTROPY_" STDLIB/` → **no source collision** (zero hits in `STDLIB/iii/**`). The candidate's own `EM_` prefix is *also* collision-free in source (the only `EM_`-substring hits are `KEM_*` in `mlkem.iii` and binary `.exe` artifacts, neither a real symbol clash), but the dispatch assigns `ENTROPY_`, so **every const and every module-scope `var` is renamed `EM_* → ENTROPY_*`** (Trap 2: module-scope `const` *and* `var` both emit linker-global `L_<NAME>` symbols, so the rename must cover the `var`s too, not just the `const`s).

| Name | Type | Value | Notes |
|---|---|---|---|
| `ENTROPY_OK` | `i32` | `0i32` | success |
| `ENTROPY_E_BAD` | `i32` | `-1i32` | invalid slot / dead path |
| `ENTROPY_E_CAP` | `i32` | `-2i32` | missing/zero capability (M8) |
| `ENTROPY_E_NOBASE` | `i32` | `-3i32` | baseline not set |
| `ENTROPY_E_RANGE` | `i32` | `-4i32` | caller-supplied `cap`/length out of range |
| `ENTROPY_PRIME` | `u64` | `998244353u64` | NTT prime `p`; `p-1 = 2^23·7·17` (verified) |
| `ENTROPY_GROOT` | `u64` | `3u64` | primitive root `g` |
| `ENTROPY_N` | `u32` | `64u32` | transform length `N = 2^6` |
| `ENTROPY_LOG2N` | `u32` | `6u32` | `log2(N)`; bit-reversal width (was an inline `6u32` literal) |
| `ENTROPY_MAX_PATHS` | `u32` | `256u32` | slot-table bound (W8; see Data Structures) |
| `ENTROPY_ID_LEN` | `u64` | `32u64` | path-id width in bytes (was inline `32`) |
| `ENTROPY_INVALID_SLOT` | `u32` | `0xFFFFFFFFu32` | register-full sentinel |

`ENTROPY_OMEGA` and `ENTROPY_INITED` are **module-scope `var`s, not `const`s** (computed at init), listed under Data Structures.

Avoidance note (Trap 2): the bare names `OK`, `PRIME`, `N`, `MAX_PATHS`, `BUF`, `BUF_LEN`, `LIVE`, `BASELINE`, `OMEGA`, `INITED` would each collide with sibling Layer-5 modules (`cost_lattice`, `microarch_model`, etc.). All are prefixed.

## Data Structures
All path state is held in **statically-sized module-scope arrays** (W8). Bound `ENTROPY_MAX_PATHS = 256` is justified: the substrate enumerates a fixed, small set of instrumented hot paths (one per dispatch-class kernel); 256 is the documented hot-path ceiling shared with the sibling `microarch_model` slot tables. No local `var` arrays anywhere (Trap 7) — the candidate's two local `var a:[u64;64]` / `var b:[u64;64]` in `em_spectrum` are **promoted to module scope** as `ENTROPY_SCRATCH_A` / `ENTROPY_SCRATCH_B`.

| Name | Type | Fixed size | Purpose / bound justification |
|---|---|---|---|
| `ENTROPY_LIVE` | `[u8; 256]` | 256 | per-slot liveness flag (0/1) |
| `ENTROPY_PATH_ID` | `[u8; 8192]` | 256·32 | per-slot 32-byte path identifier (flattened) |
| `ENTROPY_BUF` | `[u64; 16384]` | 256·64 | per-slot circular sample buffer (flattened, row-major: `slot*64 + idx`) |
| `ENTROPY_BUF_HEAD` | `[u32; 256]` | 256 | per-slot circular write head |
| `ENTROPY_BUF_LEN` | `[u32; 256]` | 256 | per-slot fill count (saturates at 64) |
| `ENTROPY_BASELINE` | `[u64; 16384]` | 256·64 | per-slot baseline spectrum (flattened) |
| `ENTROPY_BASE_SET` | `[u8; 256]` | 256 | per-slot baseline-installed flag (0/1) |
| `ENTROPY_SCRATCH_A` | `[u64; 64]` | 64 | NTT input/natural-order scratch (was local `var a`; **Trap 7 fix**) |
| `ENTROPY_SCRATCH_B` | `[u64; 64]` | 64 | NTT working/bit-reversed scratch (was local `var b`; **Trap 7 fix**) |
| `ENTROPY_WIT_BUF` | `[u8; 296]` | 296 | witness pre-image scratch: 32 (path_id) + 8 (time-stamp) + 256 (64×4-byte truncated spectrum). Serialized; non-reentrant — acceptable (see Trap-7 note) |
| `ENTROPY_OMEGA` | `u64` (scalar) | — | `var`, = primitive 64th root, computed in `entropy_init` = **922799308** (verified) |
| `ENTROPY_INITED` | `u8` (scalar) | — | `var`, init guard |

**Reentrancy note (Trap 7):** because `ENTROPY_SCRATCH_A/B` and `ENTROPY_WIT_BUF` are module-scope, `entropy_spectrum` and `entropy_witness` are **not reentrant** and must be called serially (single-threaded substrate hot-path accounting — the same serialization assumption `keccak256_*` and `mlkem`'s `KEM_*` scratch buffers rely on). Documented in the module header.

## Dependencies (externs)
```
extern @abi(c-msvc-x64) fn keccak256_oneshot(msg_ptr: u64, msg_len: u64, out_ptr: u64) -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn at_advance() -> u64 from "algebraic_time.iii"
```
- `keccak256.iii` — **already built** (Module set: numera; public `keccak256_oneshot` confirmed). Supplies the M6/M10 witness hash over the spectrum pre-image.
- `algebraic_time.iii` — **already built** (public `at_advance`, `at_current` confirmed). Supplies the monotonic algebraic-time stamp folded into the witness (W16/W17).

**Not-yet-built dependencies: 0.** Both externs resolve to built STDLIB modules, so the wave scheduler may build Module 24 immediately (no upstream block). The candidate body itself declares **no** externs; these two are *added* by this spec to satisfy M6/M10/W16. They are self-contained (no transitive not-yet-built closure).

## Algorithm
NIH (M1): every routine is hand-rolled; the only externs are the substrate's own keccak and algebraic-time. No floats anywhere (W5) — the entire pipeline is exact `u64` field arithmetic. No ML/heuristics (M3/M4): every output is a closed-form function of recorded inputs.

### Field arithmetic (private helpers — unchanged from candidate, verified correct)
- `entropy_addmod(a,b)`: `s = a+b; if s >= p { s-p } else { s }`. Total over `[0,p)`; `a,b<p<2^30` so `a+b` cannot overflow `u64`. (M15)
- `entropy_submod(a,b)`: `if a >= b { a-b } else { (a+p)-b }`. Total; no underflow.
- `entropy_mulmod(a,b)`: `(a*b) % p`. **Verified:** `(p-1)^2 = 996491786299899904 < 2^64`, so `a*b` never overflows; the result is exact. **Trap-11 note:** this is a raw `%` on a *non-power-of-two* modulus. It is **safe here** because `entropy_mulmod` performs **no function call** before the `%` (the param-spill stale-divisor family of Trap 11 only manifests when a call sits between the operand load and the `%`). To make this robust against future edits, the skeleton pins `a` and `b` to locals at function entry (single-use param → spill-forced) so the `%` divisor `ENTROPY_PRIME` is a module-const immediate, not a spilled register. Flagged for Phase-2 KAT: the `entropy_mulmod` KAT (below) is the guard.
- `entropy_powmod(base,exp)`: binary exponentiation, `while e > 0u64` sentinel loop (W14, no `break`); `r=1`, square-and-multiply. Used only at init (omega) and per-stage (`w_step`). Deterministic.

### `entropy_init() -> i32`
Sentinel `while i < ENTROPY_MAX_PATHS` loop zeroing `LIVE/BUF_HEAD/BUF_LEN/BASE_SET` for all 256 slots. Then `exp = (ENTROPY_PRIME - 1u64) / (ENTROPY_N as u64)` and `ENTROPY_OMEGA = entropy_powmod(ENTROPY_GROOT, exp)`. **Trap-11 on the `/`:** `(p-1)/N` is a compile-time-constant-divisor division with no preceding call → safe; result `15597568` (verified). Set `ENTROPY_INITED = 1u8`. Determinism (M2): omega is a pure function of the three compile-time constants, identical on every CPU; verified `ENTROPY_OMEGA = 922799308`, `omega^64 ≡ 1`, `omega^32 ≡ p-1 ≠ 1` (primitive). Cost is fixed (M19): exactly `256` zeroing iterations + one `log2((p-1)/N)≈24`-step powmod.

### `entropy_register_path(path_id: *u8) -> u32`
First-free-slot scan (`while i < ENTROPY_MAX_PATHS`, W14). On the first slot with `LIVE[i]==0u8`: copy 32 bytes of `path_id` into `ENTROPY_PATH_ID[i*32 .. +32]` via an inner `while k < ENTROPY_ID_LEN` byte loop (byte-wise `*u8` store — Trap 5 N/A since source is `u8`), set `LIVE=1`, reset `HEAD=0`, `LEN=0`, return `i`. Table full → return `ENTROPY_INVALID_SLOT`. The index expression `(i as u64) * 32u64 + k` uses `i as u64` *after* masking is unnecessary here because `i < 256` and is freshly produced by the loop counter (no `as u64` of an externally-supplied u32), but the skeleton still applies the `& 0xFFFFFFFFu64` mask on any `slot as u64` used in `ENTROPY_BUF`/`ENTROPY_BASELINE` pointer-index math originating from a *parameter* (Trap 4 — see `entropy_sample`/`entropy_spectrum`).

### `entropy_sample(path_slot: u32, time_value: u64) -> i32`
Guards: `if path_slot >= ENTROPY_MAX_PATHS { return ENTROPY_E_BAD }`; `if ENTROPY_LIVE[path_slot] == 0u8 { return ENTROPY_E_BAD }` (these are `u32`/`u8` ordering/equality compares — **not** the signed-ordering Trap 3; `>=` on `u32` is legal). `head = ENTROPY_BUF_HEAD[path_slot]`. Write `ENTROPY_BUF[base + head] = time_value % ENTROPY_PRIME` where `base = (path_slot as u64 & 0xFFFFFFFFu64) * (ENTROPY_N as u64)` (Trap 4 mask on `path_slot`). **Trap-11 on `time_value % ENTROPY_PRIME`:** raw `%`, non-pow2, **no preceding call** in this fn → safe; the skeleton pins `path_slot`/`time_value` to locals first. Advance head: `ENTROPY_BUF_HEAD[path_slot] = (head + 1u32) % ENTROPY_N`. **`% ENTROPY_N` where N=64 is a power of two → replace with byte-mask `(head + 1u32) & 63u32`** (Trap-11 canonical pow2 fix; eliminates the modulo entirely). Saturating fill: `if ENTROPY_BUF_LEN[path_slot] < ENTROPY_N { ... + 1u32 }`. W16/W17: time advances by *append*, monotone in arrival order; the buffer is a sliding window, fully reproducible from the recorded sample sequence.

### `entropy_spectrum(path_slot: u32, out_spectrum: *u64) -> i32` (decimation-in-time NTT)
Guards as above. **Trap-7 fix:** use module-scope `ENTROPY_SCRATCH_A` / `ENTROPY_SCRATCH_B` (NOT local `var`).
1. **Linearize the circular buffer in chronological order.** `len = ENTROPY_BUF_LEN[slot]`, `head = ENTROPY_BUF_HEAD[slot]`. For `i in 0..N`: if `i < len`, `idx = (head + ENTROPY_N - len + i) & 63u32` (**pow2 mask replaces `% ENTROPY_N`**, Trap 11), `SCRATCH_A[i] = ENTROPY_BUF[base + idx]`; else `SCRATCH_A[i] = 0u64` (zero-pad). The candidate's `if i < len {...} if i >= len {...}` two-`if` form is kept (no `else` needed; if an `else` is used it MUST be `} else {` one-line — Trap 8).
2. **Bit-reversal permutation (width `ENTROPY_LOG2N = 6`).** `entropy_bitrev(x)`: `while i < ENTROPY_LOG2N` sentinel loop, `r = (r<<1)|(v&1); v>>=1`. For `j in 0..N`: `SCRATCH_B[entropy_bitrev(j)] = SCRATCH_A[j]`.
3. **Iterative Cooley–Tukey butterflies over `GF(p)`.** Outer `while size <= ENTROPY_N` (size = 2,4,…,64), `half = size/2`, `w_step = entropy_powmod(ENTROPY_OMEGA, (ENTROPY_N / size) as u64)` (`/` constant-ish divisor, but `size` is a loop local — division by a *variable* with no call between → safe; not a `%`). Inner `while k < ENTROPY_N` (k += size), innermost `while q < half`: `u = SCRATCH_B[k+q]`, `v = entropy_mulmod(w, SCRATCH_B[k+q+half])`, `SCRATCH_B[k+q] = entropy_addmod(u,v)`, `SCRATCH_B[k+q+half] = entropy_submod(u,v)`, `w = entropy_mulmod(w, w_step)`. All three loops are sentinel/counter-driven (W14, no `break`). **No recursion (W15)** — this is the iterative form; no explicit stack needed because the butterfly schedule is index-arithmetic, not tree-recursive.
4. Copy `SCRATCH_B[0..N]` to `out_spectrum[0..N]` (`*u64` store of genuine `u64` values — Trap 5 N/A).
Determinism/bit-identity (M2/W5): every step is exact integer field arithmetic with a fixed schedule; identical buffer → identical 64 field elements, cross-CPU. Cost (M19): exactly `N·log2(N) = 384` butterflies + 64 bit-reversals + `log2(N)=6` `w_step` powmods — a fixed bound independent of data.

### `entropy_set_baseline(path_slot: u32, spectrum: *u64, cap: u64) -> i32`
**M8 capability gate (new):** `if cap == 0u64 { return ENTROPY_E_CAP }` *before* any state mutation — installing a baseline redefines the anomaly reference and is privileged. Guards: slot range + `LIVE`. **M5/reversibility:** baseline install is idempotent and overwrite-safe (re-installing restores from a fresh recorded spectrum); it never bricks (the prior baseline is simply replaced, and a path with no baseline is a defined state). Copy `spectrum[0..N]` into `ENTROPY_BASELINE[base..+N]`, set `ENTROPY_BASE_SET[slot] = 1u8`. **M6/M10 (new):** after install, fold the capability + new baseline into the witness chain by invoking `entropy_witness(path_slot, ...)` internally over `ENTROPY_WIT_BUF` (the OK witness is byte-recomputable from `(path_id, at-stamp, baseline-spectrum, cap)` — M10). Return `ENTROPY_OK`.

### `entropy_distance(path_slot: u32, spectrum: *u64) -> u64`
Guards: `if path_slot >= ENTROPY_MAX_PATHS { return 0u64 }`; `if ENTROPY_BASE_SET[path_slot] == 0u8 { return 0u64 }`. `acc = 0u64`; `while i < ENTROPY_N`: `b = ENTROPY_BASELINE[base + i]`, `d = entropy_submod(spectrum[i], b)`, `acc = entropy_addmod(acc, entropy_mulmod(d,d))`. Returns the **exact in-field squared-Euclidean distance** `Σ (s_i − b_i)^2 mod p` — a closed-form algebraic measure (M4: exact, not a "good-enough" guess; M3: no learning). Full-register `u64` return (W16). Bit-identical (M2): pure field arithmetic over recorded inputs. **M3 emphasis:** the module *reports* distance; it does **not** compare it to any internally-mutated threshold, count anomalies, or adapt — any thresholding/decision is the caller's (e.g. `context_awareness.iii`) responsibility, keeping this module a pure accountant.

### `entropy_witness(path_slot: u32, out_hash: *u8) -> i32` (new — M6/M10/W16)
Guards: slot range + `LIVE`. Build a deterministic pre-image in `ENTROPY_WIT_BUF`: bytes `0..32` = the path id (`ENTROPY_PATH_ID[slot*32..]`); bytes `32..40` = `at_advance()` rendered little-endian byte-by-byte through a `*u8` view (Trap 5: explicit byte stores, never an 8-byte `movq` of a u64-into-u32 — here the slot is `u8` so it is the safe LE-serialize idiom from `bigint::big_store_u64_le`); bytes `40..296` = the current spectrum truncated to its low 4 bytes per element, byte-serialized (compaction is exact + reproducible — the full spectrum is recomputable, M10). Call `keccak256_oneshot(&ENTROPY_WIT_BUF as u64, 296u64, out_hash as u64)`. The 32-byte digest is the witness fragment; it chains by hash (M6) and is byte-recomputable from recorded inputs (M10). **W16/W17:** the embedded `at_advance()` stamp makes the witness monotone in algebraic time. Returns `ENTROPY_OK`.

### `entropy_selftest() -> u64` (new — KAT carrier)
Runs the KAT vectors below; returns `0u64` on all-pass or a non-zero failing-bit mask (house pattern, full-register W16 return). This is the Phase-2 acceptance entry point.

## KAT Vectors (>= 3)
All verified against an independent bigint NTT reference (PowerShell `[bigint]`, this session). `omega = 922799308`.

1. **Init / omega derivation.** After `entropy_init()`: `ENTROPY_OMEGA == 922799308u64`, and (probe) `entropy_powmod(ENTROPY_OMEGA, 64u64) == 1u64` while `entropy_powmod(ENTROPY_OMEGA, 32u64) == 998244352u64` (= `p−1`, proving primitivity, not 1). KAT bit 0.

2. **Impulse → flat spectrum.** Register a path; `entropy_sample(slot, 5u64)` once (so the chronological buffer is `[5,0,0,…,0]`, 1 sample, 63 zero-pad); `entropy_spectrum(slot, out)` ⇒ `out[k] == 5u64` for **all** `k in 0..64`. (A single nonzero DC-aligned sample transforms to a constant spectrum.) KAT bit 1.

3. **Constant signal → single DC bin.** Fill the buffer with 64 samples each `7u64`; `entropy_spectrum` ⇒ `out[0] == 448u64` (`= 64·7 mod p`) and `out[k] == 0u64` for all `k in 1..64`. KAT bit 2.

4. **Delta-at-1 → geometric spectrum.** Buffer chronological `[0,1,0,…,0]` (achieved by sampling `0` then `1` then padding logic, or by direct two-sample sequence yielding window `[…,0,1]` then re-derive); `entropy_spectrum` ⇒ `out[1] == 922799308u64` (= ω) and `out[2] == 452798380u64` (= ω² mod p). KAT bit 3. *(This KAT specifically catches a wrong `w_step` / bit-reversal-width bug — the failure mode of a multi-line-fn or wrong-stride miscompile.)*

5. **mulmod guard (Trap 11).** `entropy_mulmod(998244352u64, 998244352u64) == 1u64` (`(p−1)^2 mod p = 1`); `entropy_mulmod(2u64, 998244352u64) == 998244351u64` (`= p−2`). Detects a stale-divisor / quotient-return regression in the raw `%`. KAT bit 4.

6. **Distance self-consistency.** `entropy_set_baseline(slot, S, cap=1)` with `S` = spectrum of constant-7 buffer, then `entropy_distance(slot, S) == 0u64` (identical ⇒ zero); and with `S'` = spectrum differing only in `out[0]` by `+1` (i.e. `449`), `entropy_distance(slot, S') == 1u64` (`Σ(d^2) = 1^2`). KAT bit 5.

7. **Capability refusal (M8 negative case — prove the gate FAILS on bad input).** `entropy_set_baseline(slot, S, 0u64) == ENTROPY_E_CAP` **and** `ENTROPY_BASE_SET[slot]` is unchanged (no mutation occurred). KAT bit 6. *(Per the substrate's "prove the negative case" discipline — the gate must demonstrably reject `cap == 0`, not merely accept `cap != 0`.)*

8. **Witness reproducibility (M10).** Two `entropy_witness(slot, h)` calls over the *same* recorded buffer + identical algebraic-time prefix yield byte-identical 32-byte digests; a one-sample change yields a different digest. KAT bit 7. *(Determinism of the keccak pre-image; the `at_advance` stamp is captured into the pre-image so equality holds only when the recorded inputs match.)*

## Trap Exposure
| # | Trap | Exposed? | Avoidance in this module |
|---|---|---|---|
| 1 | Multi-line `fn` decl | Yes (every fn) | **All 14 signatures are single-line**, including the new 4-param `entropy_set_baseline`. Verified in the skeleton. |
| 2 | Module-level `const`/`var` linker-global | Yes (12 consts + 11 vars) | Every const **and** every `var` carries the `ENTROPY_` prefix (the candidate's `EM_` worked too, but dispatch assigns `ENTROPY_`). Bare `OK/PRIME/N/BUF/OMEGA/...` would collide with sibling Layer-5 modules. |
| 3 | Signed-ordering compare SIGSEGV | **No** | All compares are on `u32`/`u64`/`u8` (unsigned), where `>=`/`<` are legal, or `==`/`!=` on the `i32` status. No `i32`/`i64` value is ever ordering-compared; error checks use `==`/`!=` only (W11). |
| 4 | `u32`-in-`u64`-slot garbage | Yes | Every `path_slot as u64` used in `ENTROPY_BUF`/`ENTROPY_BASELINE`/`ENTROPY_PATH_ID` index math is masked `(path_slot as u64) & 0xFFFFFFFFu64` before the multiply. (The candidate omitted the mask — **fixed**.) |
| 5 | `u32`-pointer store width | Partial | `out_spectrum`/`spectrum` are `*u64` storing genuine `u64` field elements → safe. The witness LE-serialization of the `u64` time-stamp + truncated spectrum into the `*u8` `ENTROPY_WIT_BUF` uses **byte-by-byte `*u8` stores** (the `big_store_u64_le` idiom), never a `*u32`/`*u64` store of a narrowed value. |
| 6 | Nested `/* */` | No | Header + inline comments use a single non-nested block per region and `//` lines; no `/* */` inside `/* */`. |
| 7 | Local `var` arrays | **Yes (candidate violates)** | Candidate's `var a:[u64;64]` and `var b:[u64;64]` inside `em_spectrum` are **illegal** (parse only at module scope). **Fixed:** promoted to module-scope `ENTROPY_SCRATCH_A`/`ENTROPY_SCRATCH_B` (+ `ENTROPY_WIT_BUF`). Non-reentrancy documented. |
| 8 | `} else {` one line | Yes (if used) | The spectrum zero-pad keeps the candidate's two-`if` form (no `else`); any `else` introduced in Phase 2 MUST be `} else {` single-line. |
| 9 | Em-dash in `/* */` | Yes (comments) | All comments use ASCII `--`, never `—` (U+2014). The header omega comment is ASCII-only. |
| 10 | `let mut` checkpoint-flag | No | No mutated boolean checkpoint flags; loops are counter-driven, guards are early-`return`. |
| 11 | `%` after call / non-pow2 | **Yes (4 sites)** | (a) `(head+1) % ENTROPY_N` and the buffer-`idx % ENTROPY_N` → **replaced with `& 63u32`** (N is pow2). (b) `time_value % ENTROPY_PRIME` and `(a*b) % ENTROPY_PRIME` in `entropy_mulmod` → non-pow2 but **no preceding call**; params pinned to locals at entry so the divisor is a const immediate. (c) `(p-1)/N` and `(N/size)` are `/` (not `%`) with no intervening call → safe. KAT #5 guards the mulmod. |
| 12 | `@specialize *T` stride | No | Module is not generic; all arrays are concrete `u64`/`u32`/`u8`. No type-param indexing. |

## Gap / Fix List
The candidate's NTT mathematics are **correct and verified** (parameters, omega, butterflies, field ops, distance). Gaps are buildability, naming, traps, and four mandate-level omissions. Each with its fix:

1. **[BLOCKER · Trap 7] Local `var a`/`var b` in `em_spectrum`** → promote to module-scope `ENTROPY_SCRATCH_A`/`ENTROPY_SCRATCH_B`; document non-reentrancy. *Without this the module does not compile.*
2. **[Trap 2 / dispatch] Wrong const prefix `EM_`** → rename every `const` **and** `var` to `ENTROPY_*` (both emit linker-global symbols). 12 consts + 11 vars + all call sites.
3. **[Trap 11] Two `% ENTROPY_N` modulos** (head advance, window index) → replace with `& 63u32` (pow2 mask). Two `% ENTROPY_PRIME` (sample store, `em_mulmod`) → keep but pin params to locals so divisor is a const immediate (no call sits before the `%`, so safe); guarded by KAT #5.
4. **[Trap 4] Unmasked `path_slot as u64`** in `BUF`/`BASELINE`/`PATH_ID` index arithmetic → add `& 0xFFFFFFFFu64` to every `slot as u64` derived from the parameter.
5. **[M8] No capability mediation on baseline install** → add `cap: u64` 4th param to `entropy_set_baseline`; refuse `cap == 0u64` with `ENTROPY_E_CAP` **before** mutation. KAT #7 proves the refusal (negative case).
6. **[M6/M10] No witness emission** → add `entropy_witness(path_slot, out_hash)` (keccak256 over `path_id ‖ at-stamp ‖ truncated-spectrum`); `entropy_set_baseline` folds the new baseline + cap into the witness on install. Byte-recomputable from recorded inputs. KAT #8.
7. **[W16/W17] No algebraic-time anchoring** → witness pre-image embeds `at_advance()`, making fragments monotone in algebraic time; extern `algebraic_time.iii`.
8. **[W16] Sub-word return hazard** → `entropy_distance` already returns `u64` (good, the candidate got this right — matches the `bigint_eq_u64` lesson); `entropy_selftest` likewise returns `u64`. Documented, not changed.
9. **[M19] Cost bound not stated** → spec pins exact operation counts (init: 256 + ~24-step powmod; spectrum: 384 butterflies + 64 bitrev + 6 powmods; distance: 64 field ops). All data-independent, bounded under the cost lattice.
10. **[M5] Reversibility/no-brick** → documented: baseline install is overwrite-idempotent; an unset baseline is a defined refusal state (`entropy_distance` returns 0 / callers gate on `ENTROPY_E_NOBASE`); no operation can render a slot unrecoverable. `entropy_init` re-zeroes all slots (full recovery).
11. **[M3/M4 audit — clean]** Confirmed **no** observational-learning smell: the module never increments a counter to cross a threshold, never adapts omega/baseline from observed traffic, never auto-promotes. Baseline is set only by an *explicit, capability-gated* call with a caller-supplied spectrum; distance is a pure closed-form measure. The decision (is this anomalous?) is left entirely to the caller. This is an analytic accountant, not a learner. **No fix needed — affirmed compliant.**
12. **[Naming clarity] Public fns renamed `em_* → entropy_*`** to match the `ENTROPY_` namespace and the module name `numera_entropy_monitor` (house convention: fn prefix tracks module, cf. `bigint_*`, `bitops_*`, `keccak256_*`).

## Implementation Skeleton
```iii
/* C:\Users\Edwin Boston\OneDrive\Desktop\III\STDLIB\iii\numera\entropy_monitor.iii
 *
 * III STDLIB - numera::entropy_monitor
 *
 * Per-hot-path timing buffer + deterministic finite-field NTT spectrum,
 * baseline registration (capability-gated), exact in-field distance, and
 * a keccak256 witness fragment over (path_id, algebraic-time, spectrum).
 *
 * Deterministic spectral ACCOUNTANT -- it computes exact closed-form
 * measures over recorded inputs. It does NOT learn, adapt, count-and-
 * promote, or threshold-trigger (M3/M4). Any anomaly DECISION is the
 * caller's; this module only reports algebraic distance.
 *
 * NTT parameters (all verified):
 *   prime p     = 998244353   (p-1 = 2^23 * 7 * 17)
 *   prim root g = 3
 *   length    N = 64 = 2^6
 *   omega = g^((p-1)/N) mod p = 922799308   (primitive 64th root)
 *
 * NOT REENTRANT: ENTROPY_SCRATCH_A/B and ENTROPY_WIT_BUF are module-scope
 * (Trap 7 forbids local var arrays). Call entropy_spectrum / entropy_witness
 * serially -- same serialization assumption as keccak256_* / mlkem KEM_*.
 *
 * Public API:
 *   entropy_init() -> i32
 *   entropy_register_path(path_id: *u8) -> u32
 *   entropy_sample(path_slot: u32, time_value: u64) -> i32
 *   entropy_spectrum(path_slot: u32, out_spectrum: *u64) -> i32
 *   entropy_set_baseline(path_slot: u32, spectrum: *u64, cap: u64) -> i32  -- M8 cap-gated
 *   entropy_distance(path_slot: u32, spectrum: *u64) -> u64
 *   entropy_witness(path_slot: u32, out_hash: *u8) -> i32                  -- M6/M10
 *   entropy_selftest() -> u64                                              -- KAT carrier
 *
 * Hexad: kind_witness + kind_essence.  Ring: R0.  K: 1.00.
 */

module numera_entropy_monitor

extern @abi(c-msvc-x64) fn keccak256_oneshot(msg_ptr: u64, msg_len: u64, out_ptr: u64) -> i32 from "keccak256.iii"
extern @abi(c-msvc-x64) fn at_advance() -> u64 from "algebraic_time.iii"

const ENTROPY_OK           : i32 =  0i32
const ENTROPY_E_BAD        : i32 = -1i32
const ENTROPY_E_CAP        : i32 = -2i32
const ENTROPY_E_NOBASE     : i32 = -3i32
const ENTROPY_E_RANGE      : i32 = -4i32

const ENTROPY_PRIME        : u64 = 998244353u64
const ENTROPY_GROOT        : u64 = 3u64
const ENTROPY_N            : u32 = 64u32
const ENTROPY_LOG2N        : u32 = 6u32
const ENTROPY_MAX_PATHS    : u32 = 256u32
const ENTROPY_ID_LEN       : u64 = 32u64
const ENTROPY_INVALID_SLOT : u32 = 0xFFFFFFFFu32

var ENTROPY_LIVE       : [u8;  256]
var ENTROPY_PATH_ID    : [u8;  8192]      // 256 * 32
var ENTROPY_BUF        : [u64; 16384]     // 256 * 64
var ENTROPY_BUF_HEAD   : [u32; 256]
var ENTROPY_BUF_LEN    : [u32; 256]
var ENTROPY_BASELINE   : [u64; 16384]     // 256 * 64
var ENTROPY_BASE_SET   : [u8;  256]
var ENTROPY_SCRATCH_A  : [u64; 64]        // NTT natural-order scratch (Trap-7 fix)
var ENTROPY_SCRATCH_B  : [u64; 64]        // NTT working scratch (Trap-7 fix)
var ENTROPY_WIT_BUF    : [u8;  296]       // 32 id + 8 at-stamp + 256 trunc-spectrum
var ENTROPY_OMEGA      : u64 = 0u64
var ENTROPY_INITED     : u8  = 0u8

// --- private helpers ---

fn entropy_path_id_ptr(slot: u32) -> *u8 {
    // TODO: body per Algorithm (register/witness): (&ENTROPY_PATH_ID[(slot as u64 & 0xFFFFFFFFu64) * ENTROPY_ID_LEN]) as *u8
}

fn entropy_mulmod(a: u64, b: u64) -> u64 {
    // TODO: pin a,b to locals; return (la * lb) % ENTROPY_PRIME  -- Trap 11: no call before %, divisor is const
}

fn entropy_addmod(a: u64, b: u64) -> u64 {
    // TODO: s = a+b; if s >= ENTROPY_PRIME { return s - ENTROPY_PRIME } ; return s
}

fn entropy_submod(a: u64, b: u64) -> u64 {
    // TODO: if a >= b { return a - b } ; return (a + ENTROPY_PRIME) - b
}

fn entropy_powmod(base: u64, exp: u64) -> u64 {
    // TODO: binary exponentiation; while e > 0u64 sentinel loop (W14); square-and-multiply via entropy_mulmod
}

fn entropy_bitrev(x: u32) -> u32 {
    // TODO: reverse low ENTROPY_LOG2N bits; while i < ENTROPY_LOG2N { r=(r<<1)|(v&1u32); v=v>>1u32 }
}

// --- public API ---

fn entropy_init() -> i32 @export {
    // TODO: body per Algorithm (entropy_init): zero LIVE/HEAD/LEN/BASE_SET for 256 slots; ENTROPY_OMEGA = entropy_powmod(ENTROPY_GROOT, (ENTROPY_PRIME - 1u64) / (ENTROPY_N as u64)); ENTROPY_INITED = 1u8
}

fn entropy_register_path(path_id: *u8) -> u32 @export {
    // TODO: body per Algorithm (entropy_register_path): first-free slot scan; copy ENTROPY_ID_LEN bytes; LIVE=1; HEAD=0; LEN=0; full -> ENTROPY_INVALID_SLOT
}

fn entropy_sample(path_slot: u32, time_value: u64) -> i32 @export {
    // TODO: body per Algorithm (entropy_sample): range+LIVE guards; base=(slot as u64 & 0xFFFFFFFFu64)*ENTROPY_N (Trap 4); BUF[base+head]=tv % ENTROPY_PRIME; HEAD=(head+1u32) & 63u32 (Trap-11 pow2 mask); saturating LEN
}

fn entropy_spectrum(path_slot: u32, out_spectrum: *u64) -> i32 @export {
    // TODO: body per Algorithm (entropy_spectrum): linearize circular buffer into ENTROPY_SCRATCH_A (idx = (head+ENTROPY_N-len+i) & 63u32, zero-pad); bit-reverse into ENTROPY_SCRATCH_B; iterative CT butterflies (size,half,w_step via entropy_powmod); copy SCRATCH_B -> out_spectrum. NO local var arrays (Trap 7). NO recursion (W15).
}

fn entropy_set_baseline(path_slot: u32, spectrum: *u64, cap: u64) -> i32 @export {
    // TODO: body per Algorithm (entropy_set_baseline): if cap == 0u64 { return ENTROPY_E_CAP } (M8, BEFORE mutation); range+LIVE guards; copy spectrum -> ENTROPY_BASELINE[base..]; BASE_SET=1; fold into entropy_witness (M6/M10)
}

fn entropy_distance(path_slot: u32, spectrum: *u64) -> u64 @export {
    // TODO: body per Algorithm (entropy_distance): range guard -> 0u64; BASE_SET guard -> 0u64; acc += entropy_mulmod(d,d) where d = entropy_submod(spectrum[i], baseline[i]); return acc (full-register u64, W16)
}

fn entropy_witness(path_slot: u32, out_hash: *u8) -> i32 @export {
    // TODO: body per Algorithm (entropy_witness): range+LIVE guards; ENTROPY_WIT_BUF[0..32]=path_id; [32..40]=at_advance() LE byte-by-byte (Trap 5); [40..296]=trunc-spectrum low-4-bytes byte-serialized; keccak256_oneshot(&ENTROPY_WIT_BUF as u64, 296u64, out_hash as u64); return ENTROPY_OK
}

fn entropy_selftest() -> u64 @export {
    // TODO: body per KAT Vectors 1-8: run each; OR a failing-bit into the result; return 0u64 on all-pass (full-register u64, W16)
}
```
