# III-QUOTIENT-WELD — making the quotient tools load-bearing

**Status legend:** `[PROVEN]` executed + gated · `[BUILD]` planned this campaign · `[OPEN]` genuine research frontier, not claimed solved.

## LANDED 2026-07-01 (gated, `run_sqrtsum_kats.sh` 7/0)  `[PROVEN]`

The first wall is walked through, not labelled. `sqrt_sum_sign.iii` gained **Tier 2.5 —
`sqrtsum_adaptive_sign`**: linear-independence of distinct squarefree surds decides exact zeros for
free, and a nonzero sum is separated by *adaptive interval doubling to the instance's true precision
`p ~ log(1/|E|)`* — the a-priori separation bound `M^(2ⁿ⁻¹)` is never computed. Executed numbers
(KAT `2126_adaptive_sign`, columns `n · p_used · p_sep · sign`):

```
6   8  474  +   generic n=6 → 59× fewer bits than the separation bound
6  16  760  +   n=6 with embedded cancellations → 47×
4   0   68  0   exact zero float cancels → resolved for FREE
3   8   47  −   distinct {6,10,15}, negative → correct
6  32 1332  +   n=6 large-radicand near-cancel → 41×
F: lazy3 escalated=1, adaptive p=64 → the CF-convergent 665857−470832√2: the SHIPPED lazy3
                 punts to its exponential Tier-3; adaptive resolves it and matches the oracle.
```

Every answer is identical to the exact oracle `ui_sqrt_sum_sign` (soundness is the gate, not an
afterthought). Soundness is *unconditional*: the precision cap is a performance knob — a capped case
falls to the exact engine, never fabricates a zero (advisor catch, fixed before landing). What this
is NOT: a solution to PosSLP. Worst-case precision is unchanged (`sep-bound TIGHT`,
`III-SOSR-BARRIER-ANATOMY`); the adversarial near-zero instances (field units on CF-convergents) still
cost ~2ⁿ bits. The win is **per-instance**: you pay the true cost of *this* input, and generic /
non-degenerate geometry (the robot-arm case) is cheap — the 2ⁿ orbit is never materialized.

Prior to this, the overflow falsifier (§2) killed the naïve i64 `kf_sign` path (19/39 silently
wrong) — that lesson is why Tier 2.5 uses bigint intervals and is gated against the oracle.

**The structural half — the symmetry quotient** (`2138_symmetry_quotient`, same gate, now 8/0). 2276's
quotient idea generalized past the triangle to REAL Euclidean geometry + the real adaptive engine: a
stream of triangle-perimeter comparisons `sign(perim A − perim B)` (each a 6-term Σ√ over integer
squared side-lengths) is decided in the sign-abstracted QUOTIENT. The similarity group (integer
scaling), vertex relabeling, and comparison-direction swap generate many different-looking queries
that share ONE shape; the exact-sign wall is touched ONCE per distinct shape, each instance's sign
reconstructed as `orientation_bit × representative`. Executed: **38 queries → 5 wall touches** (3
base orbits collapse 12→1 each; 2 controls stay distinct), sound against the INDEPENDENT
`ui_sqrt_sum_sign` oracle, both orientation bits exercised. This is the honest "50-joint arm" answer:
exploit the repeated/scaled structure real problems have — it does NOT beat PosSLP in general, it
collapses the instances that are the same predicate wearing different labels.

**The p-adic sieve — a wall face located, not crossed** (`2139_padic_barrier`, gate now 9/0). Verified
BEFORE building (`iii_adversarial_verify` → REFUTED, `iii_math_rigor` → DECORATIVE, advisor): a
factoring-free modular sieve for `sign/zero(Σaᵢ√bᵢ)` is **unsound**. Reducing mod `p` destroys the
perfect-square factor that carries the real proportionality — `√8 = 2√2`, but `8 ≡ 1 (mod 7)`, so
`root(8 mod 7)` loses the factor 2. Witness: `√2+√8−√18 = 0`, yet independent-root `F = 3+1−2 = 2 ≠ 0`
mod 7 — a false positive on a real zero (the discrete-log/index-map "fix" fails the *same* witness).
The KAT runs both arms and gates the boundary with teeth: the SOUND arm (squarefree-consistent roots)
matches the exact oracle on all cases incl commensurable zeros; the NAIVE arm false-positives on the
perfect-square zeros (mutating either arm reddens). The sound arm NEEDS the squarefree split
(factoring) — with which linear independence already decides zero/nonzero *exactly* — so it is
strictly redundant with Tier 2.5. Conclusion (new, extends the SOSR barrier map): **modular/p-adic
evaluation cannot escape squarefree-factoring for SOSR sign/zero.** Invoking the math-conscience here
is the tool working as asked — it caught an unsound idea before it shipped as a green KAT.

**Bigint-coefficient adaptive tier** (`sqrtsum_adaptive_sign_big`, gated `2140`, gate now 11/0). The i64
adaptive tier extended to caller-owned BIGINT coefficient magnitudes — the render-scale case
`ui_sqrt_sum_sign_big` serves (glyph cross-products overflow i64), the one thing that reaches
`ui_arc_cover_full`'s hot path. Signed-bigint squarefree canonicalization (the zero-certificate) + bigint
adaptive interval, each iteration in its own sub-arena to bound the bump-allocator accumulation. Gated
identical to `ui_sqrt_sum_sign_big` on exact zeros with bigint coeffs + square-factor radicands, big
near-cancellations, and coefficients past i64.

**Exact cyclotomic rotation — the achievable slice of "exact Lie kinematics"** (`2141`, gated). A
rotation by a rational multiple of π is ALGEBRAIC; 15° = π/12 lives in the multiquadratic field
ℚ(√2,√3) (`cos15 = (√6+√2)/4`). Composing it 24 times returns **bit-for-bit to the identity** — zero
drift — because `ζ²⁴ = 1` is an algebraic identity float can't hold; a fixed-point loop drifts ~1% over
the same path. Teeth: exact-identity closure + non-vacuous quarter-turns (`(0,1)`,`(−1,0)`,`(0,−1)` at
6/12/18) + demonstrated fixed-point drift. Honest scope: only cyclotomic angles are exact; genuinely
transcendental angles have undecidable zero-tests (Richardson) — the existing `sqrtsum_pi_sign`
tristate answers UNKNOWN, never a false zero. This is the "arm returns to exact zero" made real for the
algebraic case, on the same ℚ(√)-substrate the exact-sign engine compares.

**Correction — the bigint-adaptive consumer was a stale comment, not a call site.** A grep for actual
calls to `ui_sqrt_sum_sign_big(` found only its definition, `sqrtsum_adaptive_sign_big`'s own capped
fallback, and the 2140 gate. `ui_exact_bigcov` *externs* it but never calls it (a dead extern left from
"Increment 3"); the live coverage hot path is `biground → ui_bigsign2` — exact 2-surd iterated squaring,
O(1), no separation bound, *optimal* for the ≤2-surd geometry rendering actually produces. So there is
**no sound rewire** of `adaptive_big` into `ui_arc_cover_full` — forcing it into the 2-surd squaring path
would be a regression, not a weld. Honest status: `adaptive_big` is a correct, gated, render-scale-ready
library primitive whose niche is 3+ *independent* surds at bigint scale — which the current glyph
geometry never generates, so it has no live consumer today. (The prior "reaches the hot path" framing
rested on the stale header comment; corrected here. The dead extern is cuttable plumbing.)

**Exact SE(3) screw motion** (`2142`, gate 12/0) — the exact rotation lifted to 3D rigid motion in
ℚ(√2,√3). Three exactly-checkable facts a float engine cannot hold, all gated: (A) `R_z(15°)²⁴ = I`
bit-exact (SO(3) closure); (B) `R_z·R_x ≠ R_x·R_z` exactly — **non-commutativity**, the property that
separates 3D rotation from 2D (so the demo is provably not a degenerate planar rotation); (C) a screw
`[rotate 15°, translate +T along z]` applied to a point 24× restores orientation exactly and lands it at
`start + 24T` along z, x/y bit-exact — an exact helical closure where fixed-point drifts. Same honest
scope: cyclotomic angles only; transcendental angles remain undecidable (Richardson).

**Plumbing cut + the bigint tier made load-bearing** (gate now 13/0; bigcov gate 7/0). Two halves of one
step. (1) The dead `ui_sqrt_sum_sign_big` extern is removed from `ui_exact_bigcov` — the coverage path
rightly belongs to `ui_bigsign2`'s 2-surd squaring; bigcov gate unaffected. (2) `sqrtsum_adaptive_sign_big`
now has a real consumer: `traj_kinematics.iii:traj_len_sign` — the exact length comparison of two
gantry/waypoint trajectories (moves along lattice directions by bigint amounts). Its length is
`Σ (bigint amount)·√(small integer radicand)`; with ≥3 distinct squarefree directions it is a sum of 3+
INDEPENDENT surds at bigint scale — the tier's exact domain (which `ui_bigsign2`'s 2-surd squaring cannot
reach). Gated (`2143`) against the independent `ui_sqrt_sum_sign_big` oracle on a 3-surd bigint case and a
deep √2 Pell convergent (`X²−2Y²=1`, X,Y bigint, relative gap ~5×10⁻³⁹ — far below IEEE double epsilon,
which would call it equal). Correcting the prior note: the bigint tier is no longer unconsumed — this is a
real "which trajectory is exactly shorter" predicate. NB the KAT surfaced the 64-slot bigint handle-table
trap again: a leaked Pell loop exhausted the table → degenerate zero-handles → a spurious false-zero; the
fix is dropping every intermediate (the engines themselves are sound at deep Pell scale — verified).
HONEST boundary: smooth cyclotomic-screw arc-lengths are `√(ℚ(√2,√3)-element)` (nested radicals, NOT
integer radicands) — a separate future tower-denesting problem, not this consumer.

**High-end exact pathfinding on top of the primitive** (`lattice_shortest_path`, gate `2144`, gate now
14/0). Array-based (O(V²)) Dijkstra on a lattice graph whose edges are "move a bigint amount along a
lattice direction"; each node's tentative distance is a per-class bigint amount vector, and both the
min-extract and the relaxation compare EXACT Euclidean lengths via `traj_len_sign` → the bigint adaptive
tier. It returns the provably-shortest path — the *contribution* is exactness of the frontier order, where
a float solver errs on a Σ√ near-tie. Gated three ways: (a) the result exactly equals the brute-force min
over all source→target paths (algorithm correct — the check that catches a handle-leak, not just a wrong
length); (b) the winner is a path whose length is strictly shorter than a **Pell near-tie** (`X²−2Y²=1`,
X,Y bigint, rel gap ~10⁻³⁹ — float calls it equal); (c) the amounts are genuinely bigint (X > 2⁶⁴). This
turns `traj_kinematics` from a length primitive into an exact motion planner. Honest scope: exact
comparison is slower than float — this is for the cases where float-optimality is *wrong* (near-degenerate
Σ√ ties), not a float replacement; and the 64-slot bigint handle table bounds `nodes×classes`, so it is a
small-graph exact solver (every intermediate dropped so the search never exhausts the table).

## 0. The ask, de-hyped

The vision (oracle for a prover · Gröbner accelerator · exact Lie-group kinematics · break the
PosSLP wall) is the right *direction*. But the recurring failure mode on this project is prose that
describes a capability the code doesn't yet have (`DOCUMENTED≠VERIFIED`, `no-consumer=DEMO`). So this
doc is built around one rule: **every claim is either gated-and-executed, explicitly planned, or
explicitly open.** No fourth category.

## 1. What actually exists (read 2026-07-01, `df7ef796`)

Two *real* capabilities that have never been introduced to each other:

**Island A — the shipped general sign engine.** `STDLIB/iii/aether/sqrt_sum_sign.iii` decides
`sign(Σ aᵢ√bᵢ)` for arbitrary n, in tiers:
- Tier 1 — i64 interval (float-free), hardware speed when the value doesn't straddle 0.
- Tier 2 — radical canonicalization (structural zeros / single surd).
- Tier 3 — `ui_sqrt_sum_sign`: exact via a **separation bound**, precision `T = M^(2ⁿ−1)` — the
  PosSLP wall made concrete (exponential in n). Its own header: *"No III consumer calls it yet."*
- Real consumer that DOES exist: `verb_geom.iii` (the e-graph exact-value equivalence substrate)
  calls `sqrtsum_lazy3`, canonicalizing "up to 4 distinct surds" per class.

**Island B — the isolated quotient kit** (`TOOLS-QUOTIENT/`, wired into nothing):
- `kfield.iii` — exact arithmetic in `K = ℚ(√A,√B,√C)`, and `kf_sign`: the **Galois-tower** sign
  decision with **NO separation bound** — `sign(p+q√R) = sp` if `sp==sq`, else `sp·sign(p²−q²R)`,
  recursing down the tower. Depth = field rank. Pure rational arithmetic.
- `2276/2277/2274` — the quotient/orbit theorems (`[PROVEN]`, all exit-99): search in the
  sign-abstracted quotient and touch the wall once per *distinct shape* (6 wall-touches serve 60
  candidates); prove an identity for one orbit representative and the whole `(ℤ/2)ᵐ` Galois orbit
  follows by a sign-flip.

**The weld:** `kf_sign` is a *provably cheaper exact decider than Tier-3 on the bounded-rank
multiquadratic case* — no separation bound where Tier-3 pays `M^(2ⁿ−1)`. Not a duplicate; the
missing tier. Wiring B into A's ladder collapses two islands into one and gives Island A its first
real consumer via `verb_geom`.

## 2. The load-bearing constraint (falsified, not assumed)  `[PROVEN]`

`kfield` is **raw i64**. `kf_sign_rec` squares through the tower (`p²−q²R` per level), so
coefficients grow ~`c^(2ʳ)·R^(2ʳ⁻¹)`. The triangle KATs pass *only* because `A,B,C ≤ 13`, coeffs ≤ 4.

Falsifier (`scratchpad/probe_kf_overflow.iii`, built + run): rank-2 field, radicands ~2·10⁵, coeffs
~1.5·10⁵, forcing `sign(p)≠sign(q)` so the squaring branch fires. Result: **kf_sign disagreed with
the exact oracle `ui_sqrt_sum_sign` on 19 of 39 cases**; all small control cases agreed. So beyond a
tiny magnitude envelope, i64 `kf_sign` is **silently wrong** — the `self_graded_overflow_blind` trap.

Consequence for the claim: "no-separation-bound exact tier" is honest **only** under a magnitude
guard (fall back when out of envelope) or over bigint. Both are in the plan; neither is skipped.

## 3. Architecture — the tier ladder (target)

```
Tier 1  i64 interval               (shipped)  hardware speed, non-straddle
Tier 2  radical canonicalization   (shipped)  structural zero / single surd
Tier 3  MULTIQUADRATIC GALOIS TOWER (NEW)      bounded-rank exact sign, NO separation bound
          3a i64 tower   — in-envelope (magnitude guard passes)          [BUILD Phase 1]
          3b bigint tower — out-of-envelope, guard removed              [BUILD Phase 2]
Tier 4  separation-bound bigint    (was T3)   arbitrary n, last resort, exponential
```

Sign is invariant under positive scaling, so the bridge may clear denominators freely.

## 4. The bridge (the crux)  `[BUILD Phase 1]`

`kf_embed`: flat `Σ aᵢ√bᵢ` → the mask basis of `K`, or FAIL. The advisor's catch: this is **𝔽₂
linear algebra, not distinct-radicand counting** — `{√6,√10,√15}` looks rank-3 but is rank-2
(`√6·√10 = 2√15`).
1. Squarefree-collect terms → distinct squarefree radicands `dⱼ` with integer coeffs `cⱼ`.
2. Factor each `dⱼ`; build its prime-exponent-parity vector over 𝔽₂; Gaussian-eliminate → rank `r`.
   `r > 3` → FAIL (kfield is 3 generators / 8 masks; the caller escalates to Tier-4).
3. Choose `r` generators; express each `dⱼ` as a generator subset → mask `mⱼ`. Since
   `√dⱼ = (1/tⱼ)·e_{mⱼ}` with `tⱼ = √(∏g_{Sⱼ}/dⱼ)` an integer, scale the whole vector by `lcm(tⱼ)`
   (positive ⇒ sign-preserving) so every coefficient is an integer. Set `kf_radix(g₁,g₂,g₃)`.
4. Return the integer 8-vector. `kf_sign` decides.

## 5. The gate (soundness = `optimizer-must-match-replaced-path`)  `[BUILD Phase 1]`

A differential KAT: run the same adversarial corpus through the new dispatcher AND
`ui_sqrt_sum_sign`; **identical answer wherever the dispatcher does not abstain**, and it must NOT
abstain on the in-envelope bounded-rank cases (`prove-positive-arms`, not negative-only). Corpus
deliberately includes: (a) large-radicand overflow-prone inputs (the 19/39 falsifier set as
regression), (b) exact zeros that float cancels, (c) the rank-collapse `{√6,√10,√15}`.

## 6. The three walls — breakable vs open (honest map)

**Wall 1 — PosSLP / exponential rank.** Worst case `[OPEN]` — but the COMMON case is now bypassed (see LANDED at top: adaptive Tier 2.5, gated `2126`, pays `log(1/|E|)` not `M^(2ⁿ−1)`). In general (`unbounded ≤ PosSLP ∈ CH`; sep-bound is
tight — see `III-SOSR-BARRIER-ANATOMY`). NOT claimed solved. What IS real: (i) `[PROVEN 2138, 8/0]` the
*symmetry quotient* (38 real triangle-perimeter comparisons → 5 wall touches) — when the N surds are an orbit under a group action (repeated links of a robot
arm, relabelled instances of one theorem), pay the wall once per *distinct shape*, not per instance
(`2276` already proves 60→6). This doesn't beat PosSLP in general; it exploits structure real
problems have. (ii) `[BUILD 3b]` the bounded-rank tower sidesteps the *separation bound* entirely —
for fixed rank, exact sign in time polynomial in bit-size, vs `M^(2ⁿ−1)`. (iii) `[OPEN, invent]` a
p-adic / CRT *necessary-condition sieve*: if `Σaᵢ√bᵢ ≢ 0 (mod p)` for a prime where all `bᵢ` are
QRs, the sum is certified nonzero cheaply — a filter that defers the wall further (can't certify
zero; composes with the quotient).

**Wall 2 — the transcendental gap.** The honest answer is already partly shipped: `sqrtsum_pi_sign`
returns a **tristate** — decides the algebraic part exactly, returns UNKNOWN (never a false zero) on
a genuinely transcendental straddle. Richardson's theorem makes transcendental zero-testing
undecidable, so UNKNOWN is *correct*, not a cop-out. `[OPEN, invent]` For Lie groups: rotations by
*rational multiples of π* have **algebraic (cyclotomic)** sin/cos — those stay on an algebraic field
of higher degree and are in-scope for an exact engine (a real, bounded target). Genuinely
transcendental angles are honestly UNKNOWN.

**Wall 3 — hardware / economics.** Not a math wall. III's answer is the tier ladder itself: pay
float-speed on the 99.9% (Tier 1) and exact cost *only* on the near-zero straddle that float gets
wrong. III's niche is the decidable island where exactness is load-bearing (certified geometry,
proof-carrying computation, float-fooling detection) — not replacing IEEE for rendering.

## 7. Phases

- **Phase 1** `[BUILD]` — `kf_embed` + magnitude guard + `kf_multiquadratic_sign` dispatcher +
  differential gate. Sound by guard; gated by the KAT. Direction-independent foundation.
- **Phase 2** `[BUILD]` — bigint `kfield` (Tier 3b): remove the guard; the real separation-bound
  sidestep at arbitrary magnitude.
- **Phase 3** `[BUILD]` — wire the tier into `sqrtsum_lazy3`; prove `verb_geom` answers unchanged +
  corpus green; then the symmetry-quotient consumer (`2276` generalized past the triangle).
- **Research arc** `[OPEN]` — p-adic sieve (Wall 1), cyclotomic algebraic Lie (Wall 2). Attacked
  only after the foundation is gated; each with its own falsifier.

## 8. What this is NOT

Not a claim to have solved PosSLP or transcendental zero-testing. Not another isolated organ. The
deliverable is: the quotient kit becomes a *magnitude-safe, gated, consumed* library tier that makes
III's own exact-geometry path decide near-degenerate bounded-rank cases without the exponential
separation bound — with every step diffed against the existing exact oracle.
