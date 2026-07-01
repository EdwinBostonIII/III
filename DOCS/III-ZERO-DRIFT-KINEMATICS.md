# III — Exact Zero-Drift Mechanism Kinematics

**Artifacts:** `STDLIB/iii/aether/cyclotomic_se3.iii` (pure exact-field organ) + `STDLIB/iii/aether/q23_sign.iii` (Σ√ bridge)
+ `STDLIB/corpus/2152_mechanism.iii` (application gate).
**Gate:** `run_sqrtsum_kats.sh` → `PASS 2152_mechanism : exit 99`, suite `PASS=20 FAIL=0`.
**Dedup:** `2141`/`2142` now extern `cyclotomic_se3::q23_mul` (inline `mul4` removed) and both **still pass** — the organ is
load-bearing for existing proven gates. Delegated in `run_corpus.sh` skip-list.

## The problem

A CNC axis / robot joint / spacecraft attitude that rotates in float accumulates rounding error every increment. After
millions of steps the rotation matrix drifts **off SO(3)** (det ≠ 1, no longer orthonormal), so the tool / end-effector /
star-tracker points the wrong way — real, unavoidable float drift.

## The insight

A rotation by a **rational multiple of π is algebraic**. `15° = π/12` lives in the multiquadratic field ℚ(√2,√3):
`cos15 = (√6+√2)/4`, `sin15 = (√6−√2)/4`, basis {1,√2,√3,√6}. Composing rotations is **exact** multiplication in that
field, and the group relation `ζ²⁴ = 1` (24×15° = 360°) is an **algebraic identity**: 24 exact steps return **bit-for-bit**
to the identity — zero drift, forever — which float cannot represent at any precision.

**The unification:** a ℚ(√2,√3) element `a₀+a₁√2+a₂√3+a₃√6` has its **sign given by a 4-term Σ√** (radicands {1,2,3,6}),
so `q23_sign` routes through `sqrt_sum_sign::sqrtsum_lazy3` — the *same* engine behind the CSG kernel and the router.
That lets a mechanism **order** exact rotated coordinates ("which config reaches further? is this coordinate exactly 0?")
— a query `2141`/`2142` could not answer (they only checked *equality* to the identity). It also caught a real bug during
development: the reach arm flagged a swapped-sin rotation matrix (built `R_z(−θ)`) that closure/screw/non-commutativity
all missed — direction only shows up when you check an actual rotated *position*.

## Architecture (why two modules)

- `cyclotomic_se3.iii` — **pure** (i64 only, zero external deps): `q23_mul` (exact field product), `q23_reduce_flat`,
  `so3_*` (3×3 matrix ops), `so3_rot_z15/x15`, and the `mech_*` controller. Pure so the pure-math KATs `2141`/`2142`
  link it **without** dragging in the Σ√ engine (a cross-module `var CC` BSS collision otherwise — iii `var`s aren't
  module-namespaced).
- `q23_sign.iii` — the Σ√ **bridge** (composes `sqrt_sum_sign`), the only module that pulls the sign engine.

## Conscience: theorem-to-machine (six rungs)

1. **STATEMENT.** (a) For the SO(3) rotation `R(θ)` about a fixed axis with `θ=15°`, `cos15,sin15 ∈ ℚ(√2,√3)`; for all
   `k∈ℤ`, `R(15°)ᵏ = R(15k°)`, and `R(15°)²⁴ = R(360°) = I` exactly. (b) For `(a₀,a₁,a₂,a₃)∈ℤ⁴`,
   `sign(a₀+a₁√2+a₂√3+a₃√6) = sign(a₀√1+a₁√2+a₂√3+a₃√6)`, exact.
2. **HYPOTHESES.** (i) angle an integer multiple of 15° (cyclotomic/rational-π); (ii) exact ℚ(√2,√3) 4-tuple arithmetic;
   (iii) i64 no-overflow — holds because `R(15k°)` cycles through only **24 distinct exact matrices**, gcd-reduced to
   canonical small-coefficient form each step; (iv) denominator kept positive (for the sign).
3. **DISCHARGE (checked).** `q23_mul` — `cyclotomic_se3.iii`, consumed by `2141` (`iii_check_discharge`: lines 46–51) and
   `mech_rotate_z15`; closure test `so3_is_ident`; `q23_sign` — `q23_sign.iii:20` (`sqrtsum_lazy3`, checked); boundedness
   (iii) — the per-step `so3_reduce` + the 24-matrix cycle, empirically holding to 2400 steps in `2152`.
4. **REALIZATION.** `cyclotomic_se3.iii` + `q23_sign.iii` + `2152_mechanism.iii`. Runs: compile rc=0; `2152` exit 99;
   `run_sqrtsum_kats.sh` 20/0; `2141`/`2142` deduped onto `q23_mul`, re-gated 99. Observables:
   `C: 2400 1` · `R: 1 1` · `S: 1 24` · `D: 1 1 1084841445 -2972076`.
5. **FALSIFIER (teeth).** Mutate the sin sign / product table → closure breaks (`so3_is_ident=0`) → exit 10; mutate the
   reach ordering → exit 20; mutate the screw target → exit 30. **Demonstrated:** `mech_zpos 24→25` → **exit 30**.
6. **VERDICT: PROVEN-IN-CODE** within scope (cyclotomic, integer-multiple-of-15° angles). A transcendental angle has an
   undecidable zero-test (Richardson) — explicitly out of scope, never faked.

## Adversarial verdict — SURVIVES (high) within scope

- **Unstated hypothesis:** coefficient boundedness over 2400 steps (no i64 overflow). Holds: `R(15k°)` cycles through 24
  distinct exact matrices; gcd-reduction returns each to canonical small form. Verified empirically — overflow would break
  the 2400-step closure, which is exact.
- **Edge cases:** 0 steps → home; the 90° `x=0` is a **certified exact zero** (not float noise); negative/large step
  counts run through the same loop; no overflow (bounded).
- **Degenerate pass:** `mech_home()` is not vacuously 1 — the **negative arm** proves NOT-home at 5 and 12 steps;
  `so3_is_ident` checks all 9 entries exactly; `q23_sign` returns 0 only for a true zero.
- **Precondition at call site:** `q23_sign` radicands are `{1,2,3,6} > 0`; `MECH_DEN` stays positive (starts 1, ×4,
  gcd-reduced by `|g|`).

## Completion contract (all boxes, with evidence)

| Obligation | Evidence |
|---|---|
| POSITIVE | `2152` exit 99 |
| NEGATIVE | NOT-home at 5/12 steps (home not vacuous); fixed-point loop **drifts** at 240 steps |
| TEETH | `zpos 24→25` mutant → exit 30 |
| REALIZATION | organ is load-bearing for `2141`+`2142` (deduped) **and** `2152` — three consumers |
| DETERMINISM | pure integer, deterministic; gate-owned, delegated in `run_corpus` |
| CORPUS | `run_sqrtsum` 20/0; new test `2152`; `run_corpus` delegates it |
| BINARY | no codegen/metal change (pure `.iii`) — N/A |
| CALIBRATION | closure/screw/reach = gated-fact; cyclotomic-only scope stated; drift-contrast = the defeated failure mode |

## The observables

```
C: 2400 1                          # 2400 exact 15° steps (100 revolutions) → still BIT-EXACT home. Zero drift.
R: 1 1                             # 30° reach: x-sign(5√3)=+1; x-reach(5√3) > y-reach(5) proven by the Σ√ engine. (90° x is a certified exact 0.)
S: 1 24                            # SE(3) screw [rotate +15°, +1 z] × 24 → orientation home, z = 24 exactly.
D: 1 1 1084841445 -2972076         # R_z·R_x ≠ R_x·R_z (3D signature); the fixed-point float loop DRIFTED (fc≠2³⁰, fs≠0).
```

`unshatterable` (CSG) · `zero-loss` (routing) · **`zero-drift`** (kinematics) — three faces of the one exact substrate.
