# 04 numera/galois.iii — Implementation Spec

## Verdict
PARTIAL — the gospel candidate body is algorithmically near-complete and idiomatic for GF(2^8) and GF(2^128), but it contains **three correctness-breaking defects** (Trap-7 local `var` arrays in every gf128 routine, which additionally **clobber shared scratch across the gf128 call tree once hoisted**; unchecked NULL/OOM bigint-id propagation through Berlekamp–Massey and Lagrange that violates M5 no-bricking; and the bigint **64-slot live ceiling**, never accounted for, that silently bricks BM/Lagrange for modest `n`), plus several W-law / API-signature mismatches (multi-line `fn` headers, `lagrange_eval` named in body but `lagrange_interpolate` named in the API banner, a missing OOM error code, `b_scalar` leaked on one path). All are closeable without changing the public surface.

## Purpose
`numera/galois.iii` IS finite-field arithmetic as a pure algebraic essence: it embodies the three fields the substrate needs — GF(2^8) (AES byte field, reduction `0x11B`), GF(2^128) (GCM field, reduction `x^128+x^7+x^2+x+1`), and GF(p) for caller-supplied prime `p` over bigint — together with two coding-theory operations over GF(p): Berlekamp–Massey minimal-LFSR synthesis and Lagrange interpolation. It is a deterministic, side-effect-free leaf: identical inputs yield bit-identical outputs on every CPU.
- **Hexad kind:** `kind_essence` (per gospel header).
- **Ring:** R0.
- **K-vector:** K = 0.99 — every GF(p)/BM/Lagrange path can fail on bigint allocation (slot or arena exhaustion); GF(2^8) and GF(2^128) are total (K = 1.0 in isolation) but the module's aggregate K is 0.99.

## Public API
All signatures **single-line** (Trap 1). GF(2^8) returns the field element directly in the low byte of a `u32` (a value-typed sentinel domain: results are always in `0..=255`, W12 satisfied by totality — every input maps to a defined element). GF(2^128) and the bigint-id-returning functions follow W9/W12.

```
fn gf8_add(a: u32, b: u32) -> u32 @export
fn gf8_mul(a: u32, b: u32) -> u32 @export
fn gf8_pow(base: u32, exp: u32) -> u32 @export
fn gf8_inv(a: u32) -> u32 @export
fn gf128_add(a: *u8, b: *u8, out: *u8) -> i32 @export
fn gf128_mul(a: *u8, b: *u8, out: *u8) -> i32 @export
fn gf128_pow(base: *u8, exp: *u8, out: *u8) -> i32 @export
fn gf128_inv(a: *u8, out: *u8) -> i32 @export
fn gfp_add(arena: u64, a: u64, b: u64, p: u64) -> u64 @export
fn gfp_sub(arena: u64, a: u64, b: u64, p: u64) -> u64 @export
fn gfp_mul(arena: u64, a: u64, b: u64, p: u64) -> u64 @export
fn gfp_inv(arena: u64, a: u64, p: u64) -> u64 @export
fn gfp_pow(arena: u64, base: u64, exp: u64, p: u64) -> u64 @export
fn bm_decode(arena: u64, syndromes_ptr: u64, n: u64, p: u64, out_coeffs_ptr: u64) -> u64 @export
fn lagrange_eval(arena: u64, x_pts_ptr: u64, y_pts_ptr: u64, n: u64, p: u64, eval_at: u64) -> u64 @export
```

**Return-status conventions:**
- `gf8_*`: total, return the field element (low byte of `u32`). No error channel needed (every input is a valid GF(2^8) element after masking). W10 not applicable (no boolean returns).
- `gf128_*`: return `i32` status — `GF_OK` (0) on success, `GF_E_INV` (-1) when `gf128_inv` is called on zero (no inverse exists). W9 (negative `i32` errors), W11 (caller compares `== GF_OK` / `== GF_E_INV`, never ordering).
- `gfp_*`, `bm_decode`, `lagrange_eval`: return a bigint **id** (`u64`); the sentinel **`0u64` means failure** (matches `bigint.iii`'s `BIGINT_INVALID = 0u64` and the `field.iii` `FIELD_INVALID` convention). `bm_decode` returns the LFSR length `L` (a `u64` count, `0` = all-zero connection polynomial = no error) and writes coefficient ids into the caller's `out_coeffs_ptr` array. **W12 note:** `bm_decode`'s `u64` return is a count, not a status; failure is signalled by writing `0u64` (invalid id) into `out_coeffs_ptr[0]` — Phase 2 MUST set `out_coeffs_ptr[0] = 0u64` and return `0u64` on any inner OOM (see Gap G3).

## Constant Namespace
**PREFIX = `GF_`** for shared status codes (matches the gospel banner and the existing `GF8_`/`GF128_` sub-prefixes; all are under the `GF*` umbrella). Confirmed by grep over `STDLIB/iii/**/*.iii`: **no module declares any `GF_`, `GF8_`, `GF128_`, `GFP_`, `BM_`, or `LAGRANGE_` constant, and no `gf8_/gf128_/gfp_/bm_/lagrange_/galois_` function exists** anywhere in the tree — zero collision. (The assigned dispatch prefix `GALOIS_` is also collision-free and may be used instead; I retain the gospel's `GF_*` because the candidate body, the API banner, and the GF(2^8)/GF(2^128) value-domain comments are already written against it, and Mandate "edit-first / minimal-churn" favors keeping the established names. If the wave scheduler mandates `GALOIS_`, rename the three consts below and the references; there are exactly 6 reference sites.)

Module-level constants (all `Trap-2` prefixed, all single definitions):

| name | type | value | role |
|------|------|-------|------|
| `GF_OK` | `i32` | `0i32` | success status for `gf128_*` |
| `GF_E_INV` | `i32` | `-1i32` | not invertible (zero element) |
| `GF_E_OOM` | `i32` | `-2i32` | **ADDED** — allocation failure status (gospel omits; needed so a future `i32`-returning wrapper can distinguish OOM; currently informational, see Gap G7) |
| `GF8_POLY` | `u32` | `0x11Bu32` | GF(2^8) reduction polynomial `x^8+x^4+x^3+x+1` (documentation; the runtime reduction uses the masked low byte `0x1B`) |
| `GF128_R_LO` | `u64` | `0x87u64` | low byte of the GF(2^128) reduction `x^128+x^7+x^2+x+1` (`0b10000111`) |

**Bound consts ADDED for W8 / slot-ceiling enforcement** (see Data Structures):

| name | type | value | role |
|------|------|-------|------|
| `GF_BM_MAX_N` | `u64` | `16u64` | max syndrome count `n` for `bm_decode` (slot-ceiling bound, justified below) |
| `GF_LAG_MAX_N` | `u64` | `16u64` | max point count `n` for `lagrange_eval` |

## Data Structures
The gospel body uses **local `var [u8; 16]` arrays** inside `gf128_mul`, `gf128_pow`, and `gf128_inv`. **This is Trap-7 (local `var` array — parses only at module scope) and MUST be fixed.** All GF(2^128) scratch is hoisted to module scope with unique `GF128_`-prefixed names. Because `gf128_inv → gf128_pow → gf128_mul → gf128_add` is a **call chain**, each level needs its **own** non-overlapping buffers or it will clobber its caller's state. The buffer set below is sized so no two simultaneously-live frames share a buffer:

| name | type | size | justification (W8) |
|------|------|------|--------------------|
| `GF128_MUL_Z` | `[u8; 16]` | 16 B | `gf128_mul` accumulator `z`. One GF(2^128) element = 128 bits = 16 bytes (fixed by the field). |
| `GF128_MUL_V` | `[u8; 16]` | 16 B | `gf128_mul` shifting register `v`. |
| `GF128_POW_R` | `[u8; 16]` | 16 B | `gf128_pow` running result `r`. Distinct from MUL buffers because `pow` calls `mul`. |
| `GF128_POW_B` | `[u8; 16]` | 16 B | `gf128_pow` running base `b`. |
| `GF128_POW_T` | `[u8; 16]` | 16 B | `gf128_pow` mul-output temp `t`. |
| `GF128_INV_E` | `[u8; 16]` | 16 B | `gf128_inv` exponent `2^128−2`. Distinct from POW buffers because `inv` calls `pow`. |

Total 96 bytes of module BSS. **Reentrancy note (Trap 7):** these are module-scope singletons; `gf128_*` is therefore **NOT reentrant / NOT thread-safe** — acceptable per house style (cf. `crypt_ed25519.iii` `EDB_LHS/EDB_RHS`, `ecdsa_p256.iii` `ECDSA_RX`, serialized crypto). The non-overlap of MUL vs POW vs INV buffers guarantees correctness for the **nested** calls within a single logical operation. Document this in the module header.

`bm_decode` and `lagrange_eval` use **caller-supplied** arena arrays (`syndromes_ptr`, `out_coeffs_ptr`, `x_pts_ptr`, `y_pts_ptr`) cast to `*u64`; they hold bigint **ids** (`u64`), allocated by the caller inside `arena`. The module itself allocates two transient id-arrays via `arena_alloc1` in `bm_decode` (`b[]` auxiliary, `t[]` snapshot). **No `[u8;N]`/`[u64;N]` local arrays anywhere** — all scratch is either module-scope (gf128) or arena-backed (bm/lagrange). W8 satisfied.

**Slot-ceiling bound (critical, W8 + M5):** `bigint.iii` has a hard `BIGINT_SLOTS = 64` live-bigint ceiling (a 64-entry slot table). Each live bigint id consumes one slot until `bigint_drop`. `bm_decode` holds **`n` coefficient ids (`c[]`) + `n` auxiliary ids (`b[]`)** persistently, plus up to **`n` snapshot ids (`t[]`)** during a length-change step, plus a handful of transients (`d`, `term`, `b_scalar`, `b_inv`, `factor`). Peak live ≈ `3n + 6`. To stay under 64 with headroom for the caller's own syndrome ids: **`GF_BM_MAX_N = 16`** ⇒ peak ≈ 54 < 64. `lagrange_eval` holds `acc` + per-`i` (`num`,`den`,`den_inv`,`part1`,`term`) + the caller's `2n` point ids; peak ≈ `2n + 7`, so **`GF_LAG_MAX_N = 16`** ⇒ ≈ 39 < 64. Both functions **MUST guard `n > GF_*_MAX_N` and return failure** (Gap G2). These bounds are documented in the header as the operative limit until `bigint.iii` raises `BIGINT_SLOTS`.

## Dependencies (externs)
All from already-built modules (verified present and `@export`ed in-tree). **None are not-yet-built** — galois.iii is unblocked the moment its dependencies' wave completes; both providers (03 bigint, and bigint_div) are Layer-0/0.5 below this Layer-1 module.

| extern | provider module | NN | built? |
|--------|-----------------|-----|--------|
| `arena_alloc1(arena: u64, n: u64) -> u64` | `arena.iii` | (BOOT/runtime arena) | ✅ built |
| `bigint_new(arena: u64, cap: u64) -> u64` | `bigint.iii` | 03 | ✅ built |
| `bigint_from_u64(arena: u64, v: u64) -> u64` | `bigint.iii` | 03 | ✅ built |
| `bigint_copy(arena: u64, src: u64) -> u64` | `bigint.iii` | 03 | ✅ built |
| `bigint_drop(id: u64) -> i32` | `bigint.iii` | 03 | ✅ built |
| `bigint_eq(a: u64, b: u64) -> u8` | `bigint.iii` | 03 | ✅ built |
| `bigint_is_zero(id: u64) -> u8` | `bigint.iii` | 03 | ✅ built |
| `bigint_cmp(a: u64, b: u64) -> i32` | `bigint.iii` | 03 | ✅ built (returns −1/0/+1) |
| `bigint_add(arena: u64, a: u64, b: u64) -> u64` | `bigint.iii` | 03 | ✅ built |
| `bigint_sub(arena: u64, a: u64, b: u64) -> u64` | `bigint.iii` | 03 | ✅ built |
| `bigint_mul(arena: u64, a: u64, b: u64) -> u64` | `bigint.iii` | 03 | ✅ built |
| `bigint_mod(arena: u64, a: u64, m: u64) -> u64` | `bigint_div.iii` | (V1) | ✅ built |
| `bigint_modpow(arena: u64, base: u64, exp: u64, m: u64) -> u64` | `bigint_div.iii` | (V1) | ✅ built |
| `bigint_get_limb(id: u64, i: u64) -> u64` | `bigint.iii` | 03 | ✅ built |
| `bigint_set_limb(id: u64, i: u64, v: u64) -> i32` | `bigint.iii` | 03 | ✅ built |

**Param-name note:** `bigint.iii` declares `arena_alloc1(arena_id, n)` and `bigint_new(arena_id, cap_limbs)`; the extern in *this* module may use any local param names (`arena`, `cap`) — only the type signature and `from "..."` must match. No action needed; the gospel's names are fine.
**Unused-extern note:** the gospel imports `bigint_get_limb`/`bigint_set_limb` but never calls them. Keep them only if a Phase-2 algorithm uses them (none below does) — otherwise drop both to avoid dead externs. **Recommendation: drop them** (Gap G8).

## Algorithm
Determinism (M2) and bit-identity (W5) hold throughout because every routine is fixed-iteration integer/bit arithmetic with no floating point, no time/entropy/IO, no data-dependent control beyond exact integer tests, and identical bigint limb representations across runs (bigints are normalised LE). No ML/heuristics (M3/M4): every decision is an exact algebraic test (`== 1u32`, `bigint_is_zero`, `bigint_cmp == -1i32`). No recursion (W15): all routines are flat `while` loops; `gf128_pow`/`gf128_inv` and `gfp_inv` call helpers but never themselves (the BM/Lagrange double-loops are explicit nested `while`, not recursion).

**`gf8_add(a,b)`** — XOR in GF(2): `return (a ^ b) & 0xFFu32`. Total. (M15 algebraic-determinism: addition is total over the byte.)

**`gf8_mul(a,b)`** — Russian-peasant (NIH, hand-rolled, no table) over GF(2)[x]/`0x11B`. 8 fixed iterations: if `y&1`, `r ^= x`; then `x <<= 1` masked to 8 bits; if the pre-shift bit-7 was set, `x ^= 0x1B` (the low 8 bits of `0x11B` — the implicit `x^8` term is dropped by the mask). `y >>= 1`. Return `r & 0xFF`. Deterministic 8-step; no modulo-after-call (Trap 11 N/A). **Audit: correct** — verified `gf8_mul(0x57,0x83)=0xC1` (AES standard) below.

**`gf8_pow(base,exp)`** — square-and-multiply via `gf8_mul`. `while e > 0u32` (W14 sentinel; `e>0` on `u32` is an **unsigned** compare — Trap 3 is signed-only, so this is safe). Per bit: if `e&1`, `r = gf8_mul(r,b)`; `b = gf8_mul(b,b)`; `e >>= 1`. **Audit: correct.**

**`gf8_inv(a)`** — Fermat in GF(2^8): nonzero `a^254 = a^(−1)` (since the multiplicative group has order 255 and `a^255 = 1`). `if (a&0xFF)==0 return 0` (0 has no inverse; returning 0 is the documented convention, total). Else `return gf8_pow(a,254)`. NIH (no log/antilog table). **Audit: correct** (the gospel comment "extended Euclidean" in the banner is wrong — the body uses Fermat; align the banner comment to "Fermat a^254"). Deterministic.

**`gf128_add(a,b,out)`** — 16-byte XOR, `while i<16u64`. Returns `GF_OK`. Total. (Reused as the GF(2^128) field add inside mul/pow.)

**`gf128_mul(a,b,out)`** — bit-serial peasant over GF(2)[x]/(`x^128+x^7+x^2+x+1`). `z=0; v=a`; for each of 16 bytes of `b`, for each of 8 bits LSB-first: if bit set, `z ^= v` (via `gf128_add(z,v,z)`); shift `v` left one bit (`gf128_shl1`, returns the bit shifted out of position 127); if that MSB was 1, fold by XORing `GF128_R_LO` (`0x87`) into byte 0 (`v[0] ^= 0x87`). Output `z`. 128 fixed iterations. **Determinism:** exact bit ops. **Fix required:** `z`/`v` move from local `var [u8;16]` to module-scope `GF128_MUL_Z`/`GF128_MUL_V` (Trap 7). No recursion. Helpers `gf128_copy`, `gf128_zero`, `gf128_shl1` are private (no `@export`).

**`gf128_pow(base,exp,out)`** — square-and-multiply, exp 16-byte LE. `r=1` (byte 0 = 1), `b=base`; for each of 128 bits LSB-first: if set, `r = r*b` (into `t`, copy back); `b = b*b` (into `t`, copy back). Output `r`. **Fix:** `r/b/t` → module-scope `GF128_POW_R/_B/_T`, **distinct from the MUL buffers** so the nested `gf128_mul` does not corrupt `pow`'s state. **Audit:** logic correct.

**`gf128_inv(a,out)`** — Fermat: nonzero `a^(2^128−2) = a^(−1)`. Detect zero by OR-ing all 16 bytes; if zero `return GF_E_INV`. Build exponent `2^128−2` = `0xFE` then fifteen `0xFF` bytes (LE) and call `gf128_pow`. **Fix:** exponent buffer → module-scope `GF128_INV_E` (distinct from POW/MUL buffers, since `inv` calls `pow` which calls `mul`). **Audit:** exponent is correct (`2^128−1` is all-ones over 128 bits; subtract 1 ⇒ low byte `0xFE`, rest `0xFF`).

**`gfp_add(arena,a,b,p)`** — `s = a+b` (bigint); if `s==0` OOM ⇒ return `0`; `r = s mod p`; drop `s`; return `r`. **Trap 11 (modulo-after-call):** `bigint_mod` is a *function call*, not a `%` operator — the `a % b` trap applies only to the `%` infix operator, so this is safe. Determinism: bigint add+mod are exact.

**`gfp_sub(arena,a,b,p)`** — `c = bigint_cmp(a,b)` (−1/0/+1). If `c == -1i32` (W11 equality): `s = a+p`, `r = s − b`, drop `s`. If `c != -1i32`: `d = a−b`, `r = d mod p`, drop `d`. Each branch checks the intermediate `== 0u64` for OOM and returns `0`. **Audit:** the gospel's structure is correct (two `if`s on the equality of `c`, no ordering compare — Trap 3 / W11 satisfied). **Minor leak:** on the `c == -1i32` path, if `s != 0` but `bigint_sub` returns `0`, the gospel returns `r=0` *without dropping `s`* — Phase 2 must drop `s` before every early return (Gap G4).

**`gfp_mul(arena,a,b,p)`** — `prod = a*b`; OOM check; `r = prod mod p`; drop `prod`; return `r`. Safe.

**`gfp_inv(arena,a,p)`** — Fermat over GF(p): `a^(p−2) mod p`. `two = bigint_from_u64(2)`; `exp = p − 2`; drop `two`; `r = bigint_modpow(a, exp, p)`; drop `exp`; return `r`. OOM-checks `two==0` and `exp==0`. Precondition (documented): `p` prime, `0 < a < p`. **M4/M3:** no primality *heuristic* — primality is the caller's asserted precondition (exact, not guessed); the module performs no probabilistic test. Determinism: modpow is fixed-bit square-and-multiply.

**`gfp_pow(arena,base,exp,p)`** — thin wrapper over `bigint_modpow`. Total relative to its dependency.

**`lagrange_eval(arena, x_ptr, y_ptr, n, p, eval_at)`** — Lagrange interpolation over GF(p). `acc = 0`; for `i in 0..n`: build `num = Π_{j≠i}(eval_at − x_j)` and `den = Π_{j≠i}(x_i − x_j)` via `gfp_sub`/`gfp_mul` (inner `while j<n` with `if j!=i`, W14); then `term = y_i · num · den^{-1}`, `acc += term`; drop all transients each iteration. Return `acc`. **Explicit-stack form (W15):** two nested `while` loops, no recursion. **Determinism:** exact GF(p) ops; the inputs are bigint ids over normalised limbs. **Fixes:** (a) **bound `n > GF_LAG_MAX_N` ⇒ return 0** (slot ceiling, Gap G2); (b) **OOM guards** on every `bigint_from_u64`/`gfp_*` result inside the loop — currently the gospel checks `num==0`/`den==0`/`acc_id==0` *before* the loop but **not** the per-iteration `gfp_*` results, so an OOM mid-loop yields `bigint_drop(0)` and a wrong `acc` (Gap G3/G5); (c) **`den_inv` OOM**: if `den` is 0 (duplicate x-coordinates, a caller error) `gfp_inv` returns 0 and the result is silently wrong — document the precondition "x_i distinct mod p" and, on `den_inv==0`, drop transients and return 0.

**`bm_decode(arena, syn_ptr, n, p, out_ptr)`** — Berlekamp–Massey minimal-LFSR synthesis over GF(p) (NIH, the classic Massey iteration). Init `C(x)=B(x)=1`, `L=0`, `m=1`, `b_scalar=1`. For `k in 0..n`: discrepancy `d = s_k + Σ_{i=1..L} C_i·s_{k−i}` (mod p); if `d==0` then `m++`; else if `2L ≤ k`: snapshot `T=C`, update `C ← C − (d·b^{-1})·x^m·B`, then `B ← T`, `b_scalar ← d`, `L ← k+1−L`, `m ← 1`; else (`2L > k`): same `C` update, `B` unchanged, `m++`. Return `L`. **Explicit-stack form (W15):** outer `while k<n`, inner update `while j+m<n`, discrepancy `while i<=L` — all flat, no recursion. **Determinism:** exact. **Avoids `break` (W14):** uses the gospel's `if (2L<=k)` / `if (2L>k)` *equality-free split on the same predicate* — note these are `<=`/`>` **unsigned** `u64` ordering compares, which are **safe** (Trap 3 / W11 forbid *signed* ordering only). **Fixes:** (a) **bound `n > GF_BM_MAX_N` ⇒ write `out[0]=0` and return 0** (slot ceiling, Gap G2); (b) **`arena_alloc1` for `b[]`/`t[]` may return 0** — guard and bail to a clean failure (Gap G3); (c) **every per-iteration `gfp_*`/`bigint_copy`/`bigint_from_u64` must be OOM-checked**; on failure, the partial `c[]`/`b[]`/`t[]` ids must be dropped and `out[0]=0`/return 0 (M5: no half-built state escapes); (d) **`b_scalar` leak:** on the `2L≤k` path the gospel drops the *old* `b_scalar` then assigns a copy of `d`, but if an earlier OOM short-circuits, `b_scalar` can leak — centralize cleanup; (e) the gospel writes `c[ci]` and `b[bi]` with `bigint_from_u64` **without checking the return** — these are the first allocations that can fail and must be guarded.

**Mandate posture (M5–M20) for an R0 pure-algebra essence:** like the built exemplar `field.iii`, this module is a **deterministic computational leaf** with no capability-gated side effects, no persistent state mutation, and no self-reflection. Therefore:
- **M6/M10 (witness):** no state *transition* occurs — outputs are pure functions of inputs, so the "witness" is the input tuple itself plus the deterministic algorithm; any caller needing a witnessed transition wraps galois calls and records `(op, inputs, output)`, which is byte-reproducible by re-invocation (M10 holds by M2). Galois emits no fragments itself — correct for a leaf (cf. field.iii, bigint.iii emit none). Flag: **none** (consistent with house style).
- **M8 (capability):** no privileged action; arena access is via the caller-passed `arena` handle (an explicit resource argument, not ambient authority). Compliant.
- **M9/M5 (reversibility / no-bricking):** GF(2^8)/GF(2^128) ops are algebraically invertible (add is self-inverse; mul has `inv`); GF(p)/BM/Lagrange allocate but **never mutate caller inputs** and, once Gaps G2–G5 are closed, **fail cleanly (return 0 / `out[0]=0`) on exhaustion rather than corrupting state** — no path bricks the substrate. M5 is the central reason the OOM-propagation gaps are *mandate* violations, not mere style.
- **M14/M15/M19:** entries are total+deterministic over their bit width (M15); cost is bounded — `gf8_*` ≤ 8·(work), `gf128_*` ≤ 128·(16-byte work), `gfp_*` bounded by bigint op cost, `bm_decode` O(n²) bigint ops, `lagrange_eval` O(n²) — all bounded by the `n ≤ 16` cap (M19). No unbounded reflection (M13/M20: the module never reasons about itself).

## KAT Vectors (>= 3)
Byte-for-byte acceptance checks for the Phase-2 self-test. Standard vectors cited where they exist.

1. **GF(2^8) multiply (AES standard vector):** `gf8_mul(0x57u32, 0x83u32) == 0xC1u32`. (FIPS-197 / classic AES MixColumns example: `0x57 · 0x83 = 0xC1` in `GF(2^8)/0x11B`.) Also `gf8_mul(0x53u32, 0xCAu32) == 0x01u32` (0x53 and 0xCA are mutual inverses in AES's field).
2. **GF(2^8) inverse round-trip:** for `a = 0x53u32`, `gf8_inv(0x53u32) == 0xCAu32`, and `gf8_mul(0x53u32, gf8_inv(0x53u32)) == 0x01u32`. Edge: `gf8_inv(0u32) == 0u32` (documented zero convention). `gf8_pow(0x02u32, 0u32) == 0x01u32` (anything^0 = 1).
3. **GF(2^128) multiply (AES-GCM `GHASH` field, RFC 8452 / SP 800-38D):** with the GCM bit/byte convention used here (16-byte LE, low byte = constant term), `gf128_mul(one, x) == x` for `one = 01 00…00` (multiplicative identity), and the self-consistency vector `gf128_mul(a, gf128_inv(a)) == one` for `a = 02 00…00` (a ≠ 0). Acceptance also asserts `gf128_add(a, a, out) ⇒ out == 00…00` (characteristic 2).
   - *Note:* the canonical GHASH test constant (`H` from SP 800-38D Appendix B) uses the **bit-reflected** GCM convention; this module's storage is plain LE (low byte = constant term), so Phase 2 must either (i) use the reflected `H` and reflect inputs, or (ii) use the convention-independent self-consistency vectors above. The acceptance gate uses (ii) plus identity/inverse round-trips to stay convention-robust; if GHASH interop is later required, add a reflection wrapper (out of this module's scope).
4. **GF(p) field laws (p = 97, a small prime):** with `p = 97`, `a = 30`, `b = 75` as bigints — `gfp_add == 8` (105 mod 97), `gfp_sub(a,b) == 52` ((30−75) mod 97 = −45 mod 97 = 52), `gfp_mul == 24` (2250 mod 97 = 24), `gfp_inv(a=30, 97)` `r` satisfies `gfp_mul(30, r, 97) == 1`, and `gfp_pow(30, 96, 97) == 1` (Fermat: a^(p−1)=1). All compared by `bigint_eq` against `bigint_from_u64` of the expected value.
5. **Lagrange interpolation (p = 97):** points `(1,1),(2,4),(3,9)` lie on `y = x²`; `lagrange_eval(...,n=3, p=97, eval_at=5) == 25` and `eval_at=4 == 16`. (Degree-2 polynomial recovered exactly.)
6. **Berlekamp–Massey (p = 97):** syndrome sequence `1,1,2,3,5,8` (Fibonacci mod 97) is generated by the LFSR `C(x) = 1 − x − x²`; `bm_decode(...,n=6,p=97,out)` returns `L == 2` and `out[0]==1`, `out[1]== (−1 mod 97)=96`, `out[2]== (−1 mod 97)=96`. (Classic BM acceptance: the minimal recurrence of the Fibonacci sequence has length 2.)

## Trap Exposure
| # | Trap | Exposed? | Avoidance |
|---|------|----------|-----------|
| 1 | Multi-line `fn` decls | **YES (gospel violates)** | The gospel writes `gf128_pow`(line "exp is 16 byte…" comment is fine) but **`lagrange_eval` and `bm_decode` headers are split across two lines** (`fn lagrange_eval(arena: u64, …` continuing onto the next line; same for `bm_decode`). **MUST be reformatted to a single line each.** All signatures in the Skeleton below are single-line. |
| 2 | Module-`const` is linker-global | YES | All 7 consts are `GF_*`/`GF8_*`/`GF128_*`-prefixed; grep-confirmed zero collision across `STDLIB/iii/**`. |
| 3 | Signed ordering compare SIGSEGV | **Latent — must stay clean** | Every ordering compare in the module is on **unsigned** types (`u32` `e>0`, `u64` `i<n`, `j+m<n`, `2L<=k`, `i<=L`) — Trap 3 is **signed-only**, so these are safe. The only signed values are `i32` status/`bigint_cmp` results, compared **by equality only** (`c == -1i32`, `c != -1i32`) — W11/Trap-3 compliant. **Rule for Phase 2:** never introduce `< 0i32`/`>= 0i64` on the `i32` returns; compare to the exact sentinel. |
| 4 | `u32`-in-`u64`-slot garbage | Low | The pointer math is on `u64` indices (`xp[i]`, `c[ci]`, `b[bi]`) and `u64` byte offsets — no `u32`-local widened into pointer arithmetic. The `as u32` casts in gf128 (`a[i] as u32`) feed *bit ops*, never pointer math. Safe. **Rule:** if Phase 2 derives any index from a `u32`, mask `(x as u64) & 0xFFFFFFFFu64` first. |
| 5 | `u32` pointer-store width | **YES** | The gospel writes `out[i] = (av ^ bv) as u8` through `*u8` — that's a byte store, **safe**. But `v[0u64] = (lo ^ …) as u8` and `r[0u64]=1u8` are also `*u8` byte stores — safe. **No `*u32` stores** in the module. The id-arrays (`c[ci] = …`, `b[bi] = …`) are `*u64` stores of genuine `u64` ids (not u32-locals), so the 8-byte `movq` is *correct* there. Compliant — but Phase 2 must keep all gf128 byte writes through `*u8`. |
| 6 | Nested `/* */` comments | YES (doc-heavy) | The banner and the GF(2^128) explanation are large `/* */` blocks. **No nesting** — verified the gospel does not nest; Phase 2 must not embed `/* */` inside them (use `//` for inline notes). |
| 7 | Local `var` arrays | **YES — PRIMARY DEFECT** | `gf128_mul`/`gf128_pow`/`gf128_inv` declare `var z_buf:[u8;16]` etc. **locally** — forbidden. **Fix:** hoist all six to module scope (`GF128_MUL_Z/_V`, `GF128_POW_R/_B/_T`, `GF128_INV_E`), non-overlapping across the call chain. Documented non-reentrancy. |
| 8 | `} else {` one line | Low | The gospel uses the `if X {…} if !X {…}` split rather than `else` in the trap-prone spots (BM, gfp_sub) — **no `} else {` present**, so no exposure. If Phase 2 introduces an `else`, it must be `} else {` on one line. |
| 9 | Em-dash in `/* */` | YES (prose comments) | The banner prose must use ASCII `--`/`-`, never `—` (U+2014). **Audit Phase-2 output for em-dashes** in all comments (this spec's prose em-dashes are doc-only and never enter the `.iii`). |
| 10 | `let mut x=0u32` checkpoint-flag | Low | The module uses `let mut` for genuine accumulators (`r`, `x`, `y`, `acc_id`, `L`, `m`) that are read every iteration — not as a write-once checkpoint flag. The gf8 `high_bit`/`msb` are `let` (immutable per-iter), good. No misuse. |
| 11 | `a % b` after call returns quotient | **N/A (no `%` operator)** | The module performs modular reduction exclusively through the **`bigint_mod` function call**, never the `%` infix operator. The Trap-11 family is specific to the `%` operator's param-spill; function calls are unaffected. (The `bit / 64u64` / `bit % 64u64` pattern from `bigint_div.iii` does **not** appear in galois.) Zero exposure. |
| 12 | `@specialize *T` stride | **N/A** | No `@specialize` and no generic element-width pointer indexing. All pointers are concrete `*u8` (16-byte fields, byte-indexed) or `*u64` (id arrays, `u64`-indexed). Stride is always the concrete element size. |

## Gap / Fix List
PARTIAL — the following must be closed by Phase 2. Public API surface is unchanged by all fixes.

- **G1 — Trap 7, local `var` arrays (CORRECTNESS).** `gf128_mul`, `gf128_pow`, `gf128_inv` declare `[u8;16]` scratch locally. Fix: hoist to the six module-scope buffers in Data Structures; keep MUL/POW/INV buffer sets disjoint so the nested call chain doesn't self-clobber. (Without this the file does not even parse.)
- **G2 — Slot-ceiling bound, W8/M5 (CORRECTNESS/BRICKING).** `bm_decode`/`lagrange_eval` ignore `bigint.iii`'s 64-slot live ceiling. For `n` beyond ~18 the slot table exhausts mid-run, `bigint_from_u64` starts returning 0, and the result silently corrupts. Fix: add `GF_BM_MAX_N`/`GF_LAG_MAX_N` (=16) and guard `if n > GF_*_MAX_N { … return failure }` at function entry. Document the bound in the header as the operative limit until `BIGINT_SLOTS` is raised.
- **G3 — Unchecked allocation in BM init/aux (CORRECTNESS/M5).** `arena_alloc1(arena, n*8)` for `b[]`/`t[]` and the loop bodies' `bigint_from_u64(...)` are not OOM-checked. Fix: check `b_arr_id == 0`/`t_arr_id == 0` and every `bigint_from_u64`/`bigint_copy`/`gfp_*` result `== 0`; on failure, drop every already-allocated id in `c[]`/`b[]`/`t[]` and the transients, set `out[0]=0u64`, return `0u64`.
- **G4 — `gfp_sub` intermediate leak.** On the `c == -1i32` path, an OOM in `bigint_sub` returns 0 without dropping `s`. Fix: `bigint_drop(s)` before the early `return 0u64`. (Mirror for any other early-return that has a live intermediate.)
- **G5 — `lagrange_eval` per-iteration OOM (CORRECTNESS/M5).** Inner `gfp_sub`/`gfp_mul`/`gfp_inv` results (`nf`,`df`,`new_num`,`new_den`,`den_inv`,`part1`,`term`,`new_acc`) are used without `== 0` checks; an OOM produces `bigint_drop(0)` and a wrong accumulator. Fix: check each; on failure drop the live set (`acc_id`,`num`,`den`, plus whatever is allocated this iter) and return `0u64`. Also document/enforce the **distinct-x precondition** (if `den == 0`, `den_inv == 0` ⇒ fail clean).
- **G6 — API-banner vs body name mismatch.** The header banner advertises `lagrange_interpolate(...)` and `bm_decode(... ) -> id of connection polynomial`, but the body defines `lagrange_eval(...)` and `bm_decode` *writes coefficients via `out_coeffs_ptr` and returns `L`*. Fix: make the banner match the actual exported names/signatures (`lagrange_eval`, `bm_decode(...,out_coeffs_ptr) -> L`). The Skeleton banner below is corrected.
- **G7 — Missing `GF_E_OOM`.** Gospel references no OOM status code for the `i32`-returning gf128 family (they can't OOM, so this is informational), but a consistent error namespace wants it. Fix: add `const GF_E_OOM : i32 = -2i32` (declared, reserved for any future `i32`-returning bigint-backed wrapper; the current bigint-id functions signal OOM via `0u64`).
- **G8 — Dead externs.** `bigint_get_limb`/`bigint_set_limb` are imported but unused by every algorithm above. Fix: drop both externs (or, if Phase 2 adds a limb-level fast path, keep and use them). Leaving unused externs is harmless to codegen but fails the "no dead surface" discipline.
- **G9 — gf8_inv banner comment wrong.** Banner says "extended Euclidean over poly"; the body uses Fermat `a^254`. Fix: correct the comment to "Fermat: a^254 = a^(-1)".
- **G10 — Multi-line signatures (Trap 1).** `lagrange_eval` and `bm_decode` headers wrap onto a second line in the gospel. Fix: single-line each (done in Skeleton). This is the single most dangerous defect after G1 because it can *silently* miscompile parameter offsets.
- **G11 — `bm_decode` `2L<=k`/`2L>k` split is correct but document it.** The gospel deliberately avoids `else` (and `break`) by testing the same predicate twice; this is W14/W8-clean and intentional — keep it, but add a one-line comment so a future editor doesn't "simplify" it into a signed compare or a `break`.

## Implementation Skeleton
```iii
/* C:\Users\Edwin Boston\OneDrive\Desktop\III\STDLIB\iii\numera\galois.iii
 *
 * III STDLIB - numera::galois
 *
 * Finite field arithmetic over GF(2^8), GF(2^128), GF(p) for prime p,
 * plus Berlekamp-Massey LFSR synthesis and Lagrange interpolation over GF(p).
 *
 * GF(2^8) reduction polynomial: x^8 + x^4 + x^3 + x + 1 = 0x11B.
 * GF(2^128) reduction polynomial: x^128 + x^7 + x^2 + x + 1 (low byte 0x87).
 * GF(p): caller supplies prime p as a bigint id; a, base assumed < p.
 *
 * Public API:
 *   GF(2^8) (value-typed, total, result in low byte of u32):
 *     gf8_add(a, b)          XOR
 *     gf8_mul(a, b)          Russian-peasant with 0x1B reduction
 *     gf8_pow(base, exp)     square-and-multiply
 *     gf8_inv(a)             Fermat: a^254 = a^(-1); inv(0)=0
 *   GF(2^128) (16-byte LE, low byte = constant term; returns GF_OK/GF_E_INV):
 *     gf128_add / gf128_mul / gf128_pow / gf128_inv
 *   GF(p) (returns bigint id; 0u64 = failure):
 *     gfp_add / gfp_sub / gfp_mul / gfp_inv (Fermat a^(p-2)) / gfp_pow
 *   bm_decode(arena, syndromes_ptr, n, p, out_coeffs_ptr) -> L
 *     Massey iteration; writes C(x) coeff ids into out_coeffs_ptr; returns
 *     LFSR length L. out_coeffs_ptr[0]=0u64 and return 0 on failure.
 *     Requires n <= GF_BM_MAX_N (bigint 64-slot ceiling).
 *   lagrange_eval(arena, x_pts_ptr, y_pts_ptr, n, p, eval_at) -> bigint id
 *     Unique degree n-1 polynomial through (x_i,y_i) evaluated at eval_at.
 *     Requires distinct x_i mod p and n <= GF_LAG_MAX_N. 0u64 on failure.
 *
 * Hexad: kind_essence.  Ring: R0.  K: 0.99 (alloc may fail in GF(p)/BM/Lagrange).
 *
 * NIH: depends on bigint.iii, bigint_div.iii. No third-party code.
 *
 * Determinism: all paths are fixed-iteration integer/bit arithmetic; no FP,
 * no IO, no entropy; outputs are bit-identical cross-run/cross-CPU.
 *
 * NOT REENTRANT: gf128_* use module-scope scratch (serialized use only).
 *
 * Discipline: W2 (<=4 params via the 5/6-arg bm/lagrange aggregates are the
 * documented exception per gospel signature), W13 (<=20 locals),
 * W14 (sentinel loops, no break), W11 (i32 compared by equality only).
 */

module numera_galois

extern @abi(c-msvc-x64) fn arena_alloc1(arena: u64, n: u64) -> u64 from "arena.iii"
extern @abi(c-msvc-x64) fn bigint_new(arena: u64, cap: u64) -> u64 from "bigint.iii"
extern @abi(c-msvc-x64) fn bigint_from_u64(arena: u64, v: u64) -> u64 from "bigint.iii"
extern @abi(c-msvc-x64) fn bigint_copy(arena: u64, src: u64) -> u64 from "bigint.iii"
extern @abi(c-msvc-x64) fn bigint_drop(id: u64) -> i32 from "bigint.iii"
extern @abi(c-msvc-x64) fn bigint_eq(a: u64, b: u64) -> u8 from "bigint.iii"
extern @abi(c-msvc-x64) fn bigint_is_zero(id: u64) -> u8 from "bigint.iii"
extern @abi(c-msvc-x64) fn bigint_cmp(a: u64, b: u64) -> i32 from "bigint.iii"
extern @abi(c-msvc-x64) fn bigint_add(arena: u64, a: u64, b: u64) -> u64 from "bigint.iii"
extern @abi(c-msvc-x64) fn bigint_sub(arena: u64, a: u64, b: u64) -> u64 from "bigint.iii"
extern @abi(c-msvc-x64) fn bigint_mul(arena: u64, a: u64, b: u64) -> u64 from "bigint.iii"
extern @abi(c-msvc-x64) fn bigint_mod(arena: u64, a: u64, m: u64) -> u64 from "bigint_div.iii"
extern @abi(c-msvc-x64) fn bigint_modpow(arena: u64, base: u64, exp: u64, m: u64) -> u64 from "bigint_div.iii"

const GF_OK       : i32 =  0i32
const GF_E_INV    : i32 = -1i32        // not invertible (zero element)
const GF_E_OOM    : i32 = -2i32        // reserved: allocation failure (G7)

const GF8_POLY    : u32 = 0x11Bu32     // x^8 + x^4 + x^3 + x + 1 (doc; runtime folds 0x1B)
const GF128_R_LO  : u64 = 0x87u64      // low byte of x^128+x^7+x^2+x+1 = 0b10000111

const GF_BM_MAX_N  : u64 = 16u64       // bm_decode n cap: peak ~3n+6 live bigints < 64 slots
const GF_LAG_MAX_N : u64 = 16u64       // lagrange n cap: peak ~2n+7 live bigints < 64 slots

// ---- GF(2^128) module-scope scratch (Trap 7: no local var arrays). ----
// Disjoint sets across the inv -> pow -> mul -> add call chain. NOT reentrant.
var GF128_MUL_Z : [u8; 16]
var GF128_MUL_V : [u8; 16]
var GF128_POW_R : [u8; 16]
var GF128_POW_B : [u8; 16]
var GF128_POW_T : [u8; 16]
var GF128_INV_E : [u8; 16]

// ============ GF(2^8) ============

fn gf8_add(a: u32, b: u32) -> u32 @export {
    // TODO: body per Algorithm gf8_add — (a ^ b) & 0xFFu32
}

fn gf8_mul(a: u32, b: u32) -> u32 @export {
    // TODO: body per Algorithm gf8_mul — 8-step peasant, fold 0x1B on bit-7 carry
}

fn gf8_pow(base: u32, exp: u32) -> u32 @export {
    // TODO: body per Algorithm gf8_pow — square-and-multiply over u32 (exp>0 unsigned)
}

fn gf8_inv(a: u32) -> u32 @export {
    // TODO: body per Algorithm gf8_inv — if a&0xFF==0 return 0 else gf8_pow(a,254)
}

// ============ GF(2^128) ============ (16-byte LE, low byte = constant term)

fn gf128_copy(src: *u8, dst: *u8) -> i32 {
    // TODO: 16-byte copy (private helper)
}

fn gf128_zero(out: *u8) -> i32 {
    // TODO: zero 16 bytes (private helper)
}

fn gf128_shl1(v: *u8) -> u8 {
    // TODO: shift-left 1 bit across 16 bytes; return bit shifted out of pos 127
}

fn gf128_add(a: *u8, b: *u8, out: *u8) -> i32 @export {
    // TODO: body per Algorithm gf128_add — 16-byte XOR; return GF_OK
}

fn gf128_mul(a: *u8, b: *u8, out: *u8) -> i32 @export {
    // TODO: body per Algorithm gf128_mul — peasant over GF128_MUL_Z/_V; fold GF128_R_LO; return GF_OK
}

fn gf128_pow(base: *u8, exp: *u8, out: *u8) -> i32 @export {
    // TODO: body per Algorithm gf128_pow — square-and-multiply over GF128_POW_R/_B/_T; return GF_OK
}

fn gf128_inv(a: *u8, out: *u8) -> i32 @export {
    // TODO: body per Algorithm gf128_inv — zero-check -> GF_E_INV; exp 2^128-2 in GF128_INV_E; gf128_pow
}

// ============ GF(p) ============ (bigint ids; 0u64 = failure)

fn gfp_add(arena: u64, a: u64, b: u64, p: u64) -> u64 @export {
    // TODO: body per Algorithm gfp_add — s=a+b (OOM->0); r=bigint_mod(s,p); drop s
}

fn gfp_sub(arena: u64, a: u64, b: u64, p: u64) -> u64 @export {
    // TODO: body per Algorithm gfp_sub — cmp by equality (== -1i32); G4: drop intermediates on every early return
}

fn gfp_mul(arena: u64, a: u64, b: u64, p: u64) -> u64 @export {
    // TODO: body per Algorithm gfp_mul — prod=a*b (OOM->0); r=bigint_mod(prod,p); drop prod
}

fn gfp_inv(arena: u64, a: u64, p: u64) -> u64 @export {
    // TODO: body per Algorithm gfp_inv — exp=p-2; bigint_modpow(a,exp,p); OOM-guard two/exp
}

fn gfp_pow(arena: u64, base: u64, exp: u64, p: u64) -> u64 @export {
    // TODO: body per Algorithm gfp_pow — bigint_modpow(base,exp,p)
}

// ============ Lagrange interpolation over GF(p) ============

fn lagrange_eval(arena: u64, x_pts_ptr: u64, y_pts_ptr: u64, n: u64, p: u64, eval_at: u64) -> u64 @export {
    // TODO: body per Algorithm lagrange_eval
    //   G2: if n > GF_LAG_MAX_N return 0u64
    //   acc=0; for i: num=Prod(eval_at-x_j), den=Prod(x_i-x_j); term=y_i*num*inv(den); acc+=term
    //   G5: OOM-check every gfp_*/bigint_from_u64; on fail drop live set and return 0u64
    //   distinct-x precondition: den_inv==0 -> drop and return 0u64
}

// ============ Berlekamp-Massey over GF(p) ============

fn bm_decode(arena: u64, syndromes_ptr: u64, n: u64, p: u64, out_coeffs_ptr: u64) -> u64 @export {
    // TODO: body per Algorithm bm_decode
    //   G2: if n > GF_BM_MAX_N { out[0]=0u64; return 0u64 }
    //   init C=B=1, L=0, m=1, b_scalar=1 (G3: OOM-guard each alloc; arena_alloc1 b[]/t[] != 0)
    //   for k: d = s_k + Sum_{i=1..L} C_i*s_{k-i} (mod p)
    //     if d==0: m++
    //     else: if 2L<=k { snapshot T=C; C -= (d/b)*x^m*B; B=T; b_scalar=d; L=k+1-L; m=1 }
    //           if 2L>k  { C -= (d/b)*x^m*B; m++ }   // G11: same-predicate split, no else/break
    //   G3: on any inner OOM drop c[]/b[]/t[]+transients, out[0]=0u64, return 0u64
    //   cleanup b_scalar and b[] before return L  (G3d: no b_scalar leak)
}
```
