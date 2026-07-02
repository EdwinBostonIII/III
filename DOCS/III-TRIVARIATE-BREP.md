# III — Vector I: Trivariate Elimination, the Exact 3D B-Rep Edge, 3D Inertia Tensors, Inverse Design

Gates **2473, 2474, 2479, 2480**, runner `STDLIB/scripts/run_sqrtsum_kats.sh` (family tally at landing: **PASS=64 FAIL=0**).
Organs: `STDLIB/iii/aether/resultant.iii` (extended), `brep3.iii` (new), `inertia3.iii` (new).

## 1. rs_elim3 — trivariate Res_z with a certified bivariate output (gate 2473)

`rs_elim3(F, fdz, fdx, fdy, G, gdz, gdx, gdy, out)` eliminates z from two trivariate integer
grids (coefficient of `z^k x^i y^j` at `k*25+i*5+j`, degrees ≤ 4) and delivers
`R(x,y) = det Syl_z(F,G)` (out grid `a*33+b`; **canonical determinant sign, not lead-normalized**).

Pipeline: per 30-bit prime (16), the fixed-layout Sylvester determinant is evaluated at the
tensor nodes `(r,s) ∈ 0..Dx × 0..Dy`, two-stage Lagrange interpolation recovers the bivariate
residues, Garner CRT (through the **shared** `rs_crt_center` kernel — one CRT substrate with the
1D path) centers each coefficient, and `rs3_consist` re-checks every node mod every prime on the
**full delivered values** (limb-walk).

Soundness spine (each discharged in code, gated in 2473):
- **det∘eval = eval∘det**: evaluation is a ring homomorphism, det a polynomial in the entries —
  tensor nodes need only be distinct, never lead-tested. The classical degenerate-specialization
  hazard concerns the resultant of degree-dropped specialized polynomials, a matrix this pipeline
  never builds. Welded against 2193's node-skipping `rs_elim` at three slices (arm C).
- **Degree bounds** `Dx = gdz·fdx + fdz·gdx`, `Dy = gdz·fdy + fdz·gdy` (one entry per row).
- **Permanent bound** `‖R‖₁ ≤ Fnorm^gdz · Gnorm^fdz`, certified `bnd+2 ≤ 464 < bits(P)` before
  centered CRT is trusted.
- **Shadow completeness**: every common zero of F,G projects into `{R=0}` (both leads vanish ⇒
  zero first column; else Res specializes up to a nonzero lead power). The converse needs lead
  conditions — extraneous shadow points only where BOTH z-leads vanish (documented caveat).

`rs_elim3_big` delivers coefficients beyond i64 as raw sign/limb rows (≤ 8 limbs by the bound);
strict `rs_elim3` refuses instead. Gate arm E sits exactly one past the boundary (−2^63).

## 2. brep3 — the exact B-Rep edge verbs (gate 2474)

- `b3_zred`: one pseudo-Euclidean step `H = lg·F − lf·z^(fdz−gdz)·G` (an (F,G)-combination, so
  V(F,G) ⊆ V(F,H)). Ends in `dz(H)=1` (the edge is the graph of the **exact rational map**
  `z = −h0/h1` over its shadow, wherever h1 ≠ 0) or `dz(H)=0` (z-free consequence curve — the
  multi-sheet shape). Refuses out-of-grid rows (−3; wide-grid pseudo-division = charted v2).
  `hp` must not alias `fp`/`gp`.
- `b3_lift_c`: the denominator-cleared substitution `C = Σ_k F_k(−h0)^k h1^(fdz−k)` by direct
  grid algebra. **Weld A**: `rs_elim3(F,H) == C` (determinant engine vs substitution — two
  independent engines, one polynomial). **Weld B**: `C == h0 ⊗ R` (resultant multiplicativity
  `Res_z(F, lgF−lf·zG) = ±F|_{z=0}·Res_z(F,G)`). Three-way agreement kills shared-bug false passes.
- Slices (`b3_slice_x/_y`) feed sturm; `b3_slice_x_big` bridges `rs_elim3_big` raw rows into
  `sturm_big`'s `sturm2_in_*` rows — **bivariate-big → univariate-big → isolation with no i64
  anywhere** (gate Part 3).
- Worked shapes: sphere×paraboloid (irrational-height circle `z = (√17−1)/2`; fiber
  `(z²+z−4)²` via the second elimination axis; the complex-branch projection caveat pinned
  honestly) and sphere×cone (shadow arrives **squared** — the two-sheet multiplicity signature,
  welded as `4(s−2)²`; global fiber `z²−2` derived from BOTH surfaces identically; ±√2 isolated
  with exact sign-change brackets).

## 3. inertia3 — exact 3D moments and the inertia tensor in ℚ(√2,√3) (gate 2479)

Tetrahedra with q23 vertices (4-tuple `a+b√2+c√3+d√6` per coordinate over one den — the
`cyclotomic_se3` field, consumed, not duplicated). Monomial moments (total degree ≤ 2) by the
barycentric vertex formulas (`∫x² = V6(Sx²+Pxx)/120` etc.), **twin-derived** by divergence-theorem
face fluxes (outward normals, 2-simplex weights `i!j!/(i+j+2)!` over 120) — welded on an
irrational solid for all four moment shapes. The √2-tetra: volume `√2/3` exact, `∫x = 1/6`
**exactly rational from an irrational domain** (the 2187 anti-mesh story in 3D).

The tensor `I` shares the so3 layout (36 i64 + den), so `so3_mul` composes `R·I·Rᵀ` directly:
**gate arm F pins the transformation law `I(R·body) == R·I(body)·Rᵀ` at exact 15° — 36 cells,
cross-multiplied equal.** Also gated: simplicial additivity (midpoint split), the binomial
translation law (Steiner's engine) + `I_xx` translation-invariance, and product-guard refusals
(q23 products routed through `q23_mul` behind a |coord| < 2^29 guard). π-solids have no encoding
(green_moments' adjudicated honesty, inherited).

## 4. Inverse design — one-parameter quantifier elimination (gate 2480)

The 2193 impassability constant generalized to a design family: tool line `y = c` vs disc at
(10,4), r² = 8. `B(c) = Res_t(p, ∂p/∂t) = 4c² − 32c + 32`; **safe-for-ALL-t ⟺ B(c) > 0**.
Sturm isolates the boundary `4 ∓ 2√2`; the endpoints verified **exact zeros in ℚ(√2)** by q23
arithmetic (control `4+√2` rejected); inside witnessed unsafe (2 contact instants), outside
certified safe universally (0 roots in a beyond-Cauchy interval + positive value); a second
design constraint (`c ≥ 2`) decided by exact `q23_sign` composes the feasible set to
**exactly `(4+2√2, ∞)`**, witness c = 7. The engine answers "for which designs?" — not "does
this design?".

## 5. The unscripted adversary — gate 2481 (`2481_exact3_fuzz.iii`)

Every pinned KAT above checks the engines against constants its author derived; if author and
engine shared a wrong assumption, those pins would be green and worthless. Gate 2481 removes the
author: random inputs nobody chose, checked against **theorems** (planted-zero shadow
completeness — `F = (z−c)P + (x−a)Q + (y−b)S` vanishes at `(a,b,c)` for ANY draws, so
`R(a,b) == 0` is forced; verified mod three fresh primes disjoint from the pipeline's 16, sound
because `|R(a,b)| < q₁q₂q₃`), against a **checker-local textbook cofactor Sylvester** (different
algorithm, different primes, deliberately duplicated code — checker independence overrides the
reuse law for verification code), against **Sturm** (elimination-vs-root-counting trichotomy on
random contact families — two organs gated years apart forced to agree), and the full
**inertia3 theorem sweep** (twin/translation/covariance/additivity) on random q23 tetrahedra
*including degenerates* (the identities are polynomial; nothing is filtered).

The evergreen user channel: `EXACT3_SEED=<any> EXACT3_CASES=<n> ./exact3_fuzz.exe` — any seed,
any volume, no harness. Unset → deterministic gate default (seed 20260702, 250/family). Build:
`iiis-2 corpus/2481_exact3_fuzz.iii --compile-only + gcc with resultant/sturm/inertia3/
cyclotomic_se3 + libiii_native.a`. Measured: seeds {1, 31337, 987654321987, 271828182845904,
999999999999999999, 8675309×5000-cases = 75,000 checks in 70 s} — all zero violations, exit 99.
**Teeth (observed, not asserted)**: a one-character engine mutation (`rm`→`sm` in the trivariate
Horner) plus a flipped divergence face reddened it 236 violations / exit 7 with full repro data,
while the untouched elimination-vs-Sturm family correctly stayed green — the harness
discriminates, it does not merely fail. Refusals inside the generator envelope count as
violations: zero were observed across every run.

Independence, stated honestly: the checkers are independent **algorithms and organs**, not
independent authors — everything in this tree shares a lineage, and the no-third-party law
excludes external CAS cross-checks. What is machine-guaranteed: no expected value anywhere in
gate 2481 was authored by anyone; every expected value is forced by a theorem or by agreement
between independently-gated engines on inputs supplied at run time by whoever sets the seed.

## Envelopes and charted next

- rs_elim3: degrees ≤ 4 per variable, `Dx, Dy ≤ 32`, 464-bit coefficient window; charted v2 =
  wider grids + bivariate-big consumers beyond the slice.
- b3_zred: results must fit the degree-4 trivariate grid (constant/low-degree z-leads — the
  quadric workhorse); charted v2 = wide-grid pseudo-division and iterated PRS in z.
- inertia3: total degree ≤ 2 (the inertia tensor's need); charted v2 = higher moments (same
  two formula families extend), polytope assembly verbs above the gated additivity.
- Inverse design: one parameter; charted v2 = multi-parameter feasible regions via cascaded
  elimination + CAD-lite sign tables over `rs_elim3` shadows.

Calibration: every claim above is a gated-fact (2473/2474/2479/2480, family tally 64/0) except the explicitly
tagged caveats (shadow-converse lead conditions; complex-branch projection), which are the
honest boundaries of the construction, themselves pinned by gate arms.
