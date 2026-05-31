# III Crypto Speedup Measurements

**Status:** measured, correctness-gated, harness-integrated (2026-05-30).
**Benches:** `STDLIB/corpus/990_bench_knuth_div.iii`, `991_bench_montgomery_modpow.iii`,
`992_bench_fe25519_mul.iii` — owned by `STDLIB/scripts/run_bench_corpus.sh`
(PASS=7), delegated (SKIP) by `run_corpus.sh`.

## Why this document exists

Three "now faster" performance claims in the capability description lived **only in
source comments**, with no measurement:

| # | Claim (source) | As written |
|---|----------------|-----------|
| 990 | `bigint_div.iii:12,417` | Knuth Algorithm-D division "~64× faster than the prior bit-serial" |
| 991 | `rsa.iii:388` | RSA-PSS "now Montgomery modpow, no per-step division" → "far faster than bit-serial" |
| 992 | `fe25519.iii:5` | X25519 field "~1000× faster: ~µs vs ~ms per mul" on the fixed 8-limb field |

This pass replaces each unmeasured magnitude with a **measured, reproducible
number**, produced by a bench that *first* gates correctness (a fast wrong answer
is a HARD failure) and *then* reports the cycle ratio.

## Shared methodology

- **Timer:** `bench_now()` = `lfence;rdtsc;lfence` (serializing), one operation per bracket.
- **Estimator:** MIN over `N_ITER` runs = the uncontended floor (removes
  preemption/interrupt noise; the true compute cost is the minimum, not the mean).
- **Ratio, not absolute cycles:** the deliverable is the *ratio* of two paths timed
  on the **same host in the same run**. Both scale with the TSC frequency, so the
  ratio is clock-invariant and reproducible across machines — unlike an absolute
  cycle budget, which `run_bench_corpus.sh` correctly treats as advisory.
- **Correctness first:** every bench proves the fast path equals an independent
  reference (the retained slow oracle, or a second independent implementation)
  bit-for-bit *before* timing.
- **NIH:** `arena`/`bigint`/`bigint_div`/`fe25519` + `omnia_bench` (rdtsc asm) +
  `kernel32` (stdout) only.

> Host note: numbers below are from the development host. The **ratios** are the
> portable result; absolute cycle counts vary with clock and microarchitecture.

---

## 990 — Knuth Algorithm-D division vs bit-serial oracle

`bigint_div_qr` (Knuth Algorithm D) vs the retained `bigint_div_qr_bitserial`
oracle, same operand pair, three widths. Correctness gated: `q,r` byte-identical
between the two dividers **and** `q·b + r == a` **and** `r < b`.

| Dividend / divisor | Knuth (cyc) | Bit-serial (cyc) | **Ratio** |
|--------------------|------------:|-----------------:|----------:|
| 256-bit / 128-bit  |       3,275 |          576,875 | **176×** |
| 512-bit / 256-bit  |       6,250 |        1,389,175 | **222×** |
| 1024-bit / 512-bit |      15,625 |        4,018,700 | **257×** |

**Verdict: VERIFIED — and the "~64×" comment was conservative.** Measured 176–257×,
growing with operand width exactly as the O(bits) vs O(m·n) theory predicts (bit-serial
does one shift-subtract per dividend bit; Knuth does ~m·n word operations). ~64× is the
small-operand corner of this curve.

---

## 991 — Montgomery modpow vs schoolbook + Knuth

`bigint_modpow` (odd modulus → `bigint_modpow_mont`, the real RSA entry point) vs a
reconstructed schoolbook square-and-multiply whose per-step reduction is
`bigint_mod` → **the current Knuth divider** (not bit-serial). This isolates the
*division-elimination* the claim is about ("no per-step division"). Operands:
Mersenne-prime moduli `2^p−1` (p∈{521,1279,2203}, all prime → `Z/m` is a field, no
zero-divisor collapse), full-width random base (a real RSA ciphertext is
modulus-sized). Correctness gated: the two independent modexp implementations must
agree bit-for-bit.

This bench first **found a regression**, then **drove its fix**. The arc:

**Before (original `mont_mul_bigint`):** Montgomery was ~2.5× SLOWER than schoolbook+Knuth.

| Modulus | Exponent | Montgomery (cyc) | Schoolbook+Knuth (cyc) | Ratio | Montgomery |
|---------|----------|-----------------:|-----------------------:|------:|-----------|
| 521-bit  | ~64-bit            |       9,053,125 |        3,841,675 | 0.42 | 2.4× SLOWER |
| 1279-bit | ~64-bit            |      42,565,925 |       16,378,300 | 0.38 | 2.6× SLOWER |
| 2203-bit | ~64-bit            |     126,076,400 |       47,146,500 | 0.37 | 2.7× SLOWER |

**Root cause:** `mont_mul_bigint`'s REDC did **three fresh bigint heap-handle
allocations per limb-step** (`bigint_mul_u64` + `bigint_add` + `bigint_shr_bits`) —
~3k allocations per multiply — while Knuth division runs **allocation-free on fixed
raw-limb arrays**. Montgomery's "no division" advantage was swamped by per-limb
allocation overhead. (The full-width run also exposed ~100 MB of scratch bump-alloc
over a 2203-bit exponent vs schoolbook's ~11 MB.)

**Exponent independence (the control that ruled out amortization):** at the *same*
modulus the ratio was identical at ~64-bit and full-width exponents (2203-bit: 0.37
at both), confirming the loss was a per-iteration cost, not the fixed conversion
overhead — so a longer (real-RSA) exponent could never fix it.

**The fix (applied this session):** `mont_mul_bigint` was rewritten as a **radix-2^32
CIOS** (Coarsely Integrated Operand Scanning) Montgomery multiply on fixed
module-global u32 scratch (`MM_N/MM_A/MM_B/MM_T` in `bigint_div.iii`) — interleaved
multiply-and-reduce, **zero per-step allocation, one output bigint**. Radix 2^32 (not
2^64) keeps every partial in u64 (`(2³²−1)² + 2(2³²−1) = 2⁶⁴−1`), the same
no-128-bit-mul idiom as Knuth and `fz_mul`. R = 2^(64·limbs) is unchanged, so the
result is **bit-identical** — RSA KAT 373, the 759 round-trip vs `bigint_mod` oracle
(incl. all-0xFF), and 146 all stay green.

**After (CIOS `mont_mul_bigint`):** Montgomery is now ~2.5× FASTER, a ~6.5× speedup on
the Montgomery path itself.

| Modulus | Exponent | Montgomery (cyc) | Schoolbook+Knuth (cyc) | Ratio | Montgomery |
|---------|----------|-----------------:|-----------------------:|------:|-----------|
| 521-bit  | ~64-bit            |   1,602,450 |  3,671,425 | 2.29 | **2.3× FASTER** |
| 1279-bit | ~64-bit            |   6,487,525 | 16,255,150 | 2.50 | **2.5× FASTER** |
| 2203-bit | ~64-bit            |  18,817,225 | 46,111,900 | 2.45 | **2.5× FASTER** |
| 1279-bit | full-width (~1279-bit) | 133,913,950 | 331,043,900 | 2.47 | **2.5× FASTER** |

(per-path speedup, old→new Montgomery: 521-bit 5.6×, 1279-bit 6.6×, 2203-bit 6.7×.)

**Verdict: VERIFIED.** The "Montgomery modpow, faster" claim is now **true against the
current best generic modexp** (schoolbook + Knuth, itself ~250× over bit-serial). The
ratio remains exponent-independent (2.50× at ~64-bit vs 2.47× at full-width 1279-bit),
so it holds for real RSA exponents. RSA modexp is now ~2.5× faster than it would be
with schoolbook+Knuth, and ~6.5× faster than the Montgomery path RSA previously used.
991 now asserts the speedup (advisory if it ever regresses), doubling as a guard.

---

## 992 — fe25519 `fz_mul` vs generic bigint field-mul

Fixed 8-limb `fz_mul` (GF(2^255−19), radix 2^32, allocation-free) vs a generic
arbitrary-precision field multiply `bigint_mul` then `bigint_mod p`. Same 256-bit
operands in both representations (4 random u64 words → 32-byte LE → `fz_decode`, and
the same words → 4-limb bigint). Correctness gated: `fz_mul → fz_freeze → fz_encode`,
rebuilt as a bigint, must equal `A·B mod (2^255−19)`.

| Path | Cycles/mul |
|------|-----------:|
| `fz_mul` (fixed 8-limb) | **1,800** |
| `bigint_mul + bigint_mod p` (generic) | **12,550** |
| **Ratio** | **~7×** |

**Verdict: the "~1000×" is CORRECTED to ~7× against the current baseline.** The
specialized fixed-limb field is ~7× faster than today's generic bigint field
multiply at 256-bit. The historical "~1000× / ~µs vs ~ms" referred to the **old
per-call-arena bigint path that fe25519 replaced** — that path did a region
alloc/free per field op (~ms) and **no longer exists**, so it cannot be timed today.
Against current `bigint_mul + bigint_mod` (which reuses arenas and reduces via Knuth),
the honest, reproducible speedup is **~7×**. The qualitative claim ("no per-call
arena → much faster") holds; the **1000× magnitude does not** against any baseline
that still exists.

---

## Summary: claims vs measured

| Capability | Claimed | Measured | Verdict |
|------------|---------|----------|---------|
| Knuth division (990) | "~64× over bit-serial" | **176–257×** | ✅ VERIFIED — conservative |
| Montgomery modpow (991) | "far faster, no per-step division" | was 2.5× slower → **now ~2.5× FASTER** | ✅ FIXED — bench found a regression; `mont_mul_bigint` rewritten as raw-limb CIOS this session (~6.5× on the Mont path); claim now true vs current best modexp |
| fe25519 `fz_mul` (992) | "~1000×, ~µs vs ~ms" | **~7×** over current generic bigint | ⚠️ CORRECTED — 1000× was vs the *deleted* per-call-arena path; ~7× vs current primitives |

**Net for the capability description:** Knuth division is verified and was understated.
Montgomery modpow was *measured to be a regression* (2.5× slower than Knuth-schoolbook),
which **drove an in-session fix** — `mont_mul_bigint` rewritten as an allocation-free
radix-2^32 CIOS — so it is now ~2.5× *faster* than schoolbook+Knuth and ~6.5× faster
than the path RSA previously used (RSA stays bit-exact: KAT 373/759/146 green). X25519
field-mul is ~7× over current bigint, not ~1000× (the 1000× was against a deleted path).
All are now backed by correctness-gated, harness-integrated, reproducible benchmarks —
and one of them turned a measurement into a real performance fix.
