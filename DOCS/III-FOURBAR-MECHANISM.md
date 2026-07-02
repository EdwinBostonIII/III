# III-FOURBAR-MECHANISM — exact 4-bar linkage analysis oracle

**Status:** implemented and tested. Organ `STDLIB/iii/aether/fourbar.iii`, gate `STDLIB/corpus/2486_fourbar.iii`
(registered in `run_sqrtsum_kats.sh`, family-compiled like `collide`/`choreo`, not archived).

## What this is

A small library that answers the classical planar 4-bar linkage design questions **exactly** —
integer and rational arithmetic only, plus the existing exact-sign engines (`sqrt_sum_sign`, `sturm`)
for the two quantities that are genuinely irrational. No floating point anywhere.

A 4-bar has integer link lengths: crank `a`, coupler `b`, rocker `c`, ground `d`.
Everything below is standard mechanism-textbook math; the contribution is that each quantity is
delivered as an exact object (integer decision, reduced rational, or certified algebraic number)
instead of a float approximation.

## API (`fourbar.iii`)

| function | returns | method |
|---|---|---|
| `fbar_grashof(a,b,c,d)` | 0 non-Grashof / 1 crank-rocker / 2 double-crank / 3 double-rocker / 4 change-point | exact integer comparison `s+l` vs `p+q`, then position of the shortest link |
| `fbar_dc_cos_num/_den(a,b,c,d,ext)` | dead-centre (toggle) output cosine, reduced rational | law of cosines `(c²+d²−e²)/(2cd)`, `e = a+b` or `\|b−a\|` |
| `fbar_trans_cos_num/_den(a,b,c,d,hi)` | transmission-angle extreme cosine, reduced rational | `(b²+c²−e²)/(2bc)`, `e = d+a` or `\|d−a\|` |
| `fbar_assembles(a,b,c,d,ext)` | 0/1 | exact triangle inequalities on `(e,c,d)` |

## Worked example (the gated one): a=2, b=7, c=6, d=5

- Classification: **crank-rocker** (s+l = 9 < 11 = p+q, shortest is a side).
- Dead-centre output cosines: **−1/3** (extended, e=9) and **3/5** (folded, e=5). Exact rationals —
  these are the toggle positions an angle-sampling kernel can step over.
- Transmission-angle extremes: **3/7** (minimum quality bound) and **19/21**.
- Swing-angle cosine: cos φ₁cos φ₂ + sin φ₁sin φ₂ = −1/5 + √(128/225) = **(−3+8√2)/15** —
  irrational, an element of ℚ(√2). Its sign (+) and its bound (< 1) are decided by
  `ui_bsign1`, the exact sum-of-square-roots sign predicate. A float gives ≈ 0.5542 and cannot
  certify either fact; here both are exact integer decisions.
- Inverse design: *for which ground length d does the extended dead-centre put the rocker at 90°?*
  Condition: c²+d²−(a+b)² = 0 → d² = 45 → **d = 3√5** — irrational. A float CAD returns 6.708…
  and does not know the closed form. Here Sturm's theorem isolates it as the unique root of
  d²−45 in (6,7), with 0 roots in (0,6], and (3√5)² = 45 is checked as an integer identity.

## How it is tested (gate 2486, exit 99 = pass)

Five arms, each with a distinct failure exit (10–14). Verified 2026-07-02 by direct toolchain
(compile with in-tree `iiis-2.exe`, link `libiii_native.a`, run): standalone exit 99 and in-family
pass. Two deliberate-break checks were run and behaved correctly:

- **D-arm tooth:** mutating the bound check `sign(18−8√2)` → `sign(11−8√2)` reddens to exit 13
  (√128 ≈ 11.314 > 11, so the engine returns −1). Confirms the surd sign is computed, not assumed.
- **E-arm tooth:** moving the Sturm search interval (6,7] → (7,8] reddens to exit 14 (0 roots there).
  Confirms the root really is located, not asserted.

## Honest limits

- i64 envelope: link lengths are integers; the cosine formulas overflow past ~2³⁰-scale links
  (no bigint tier here — `sturm_big`/`rs_elim3_big` exist in-tree if that is ever needed).
- The swing-cosine surd path in the gate covers the ℚ(√2) case; a general linkage's swing cosine
  lives in ℚ(√m) for whatever m the sine product leaves — the gate's factor-extraction step
  (128 = 8²·2) is done for this instance, not by a general square-free-decomposition routine.
- Dead-centre/transmission formulas assume the standard non-degenerate configurations
  (`fbar_assembles` guards the triangle closures; degenerate e=0 folding is not modeled).
- This analyzes a linkage; it does not synthesize one from a motion spec (no Burmester theory).
