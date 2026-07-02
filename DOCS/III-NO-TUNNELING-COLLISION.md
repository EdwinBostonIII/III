# III — Exact No-Tunneling Collision Detection

**Artifact:** `STDLIB/iii/aether/collide.iii` (organ) + `STDLIB/corpus/2153_collision.iii` (gate).
**Gate:** `run_sqrtsum_kats.sh` → `PASS 2153_collision : exit 99`, suite `PASS=21 FAIL=0` (no regression).
**Delegated** in `run_corpus.sh` skip-list. **Resealed:** 779 modules, `--verify` BIT-IDENTICAL.

## The problem

A float physics/robotics engine tests collision by **sampling** — is the body inside the obstacle at `t₀`? at `t₁`? A
fast body passes **entirely through** a thin obstacle between two samples: it **tunnels**, and discrete sampling never
sees the contact. Shrinking the timestep only hides the bug — there is always a body fast enough / a wall thin enough.

## The insight (first principles)

Collision of a swept **point** with a quadric region is **not a sampling question — it is a sign question about a
quadratic**. For a segment `P(t) = P₀ + t·(P₁−P₀)`, `t∈[0,1]`, and a sphere `Q = |x|² − R²`:

```
Q(P(t)) = a·t² + b·t + c ,   a = |ΔW|²,  b = 2(W₀·ΔW),  c = |W₀|² − R²·D²     (P = W/D, ΔW = W₁−W₀)
```

`a = |ΔW|²` is a sum of real squares ⟹ `a ≥ 0` ⟹ the parabola opens **up**, so the segment **hits** (`Q≤0` somewhere on
[0,1]) iff its minimum on [0,1] is `≤ 0`:

| vertex `t* = −b/2a` | minimum at | hit condition |
|---|---|---|
| `t* ≤ 0` (b≥0) | `t=0` | `c ≤ 0` |
| `t* ≥ 1` (2a+b≤0) | `t=1` | `a+b+c ≤ 0` |
| `0 < t* < 1` | interior vertex | `4ac − b² ≤ 0` (negative discriminant) |

Every sign is an **exact `q23_sign`** decision (ℚ(√2,√3), a 4-term Σ√ over radicands {1,2,3,6}), so the predicate
**never samples and never misses an interior dip — tunneling is impossible** — and it **certifies** the exact grazing
case `4ac−b²=0` where a float engine flickers between hit and clear.

**Composition:** `cyclotomic_se3::q23_mul` (exact ℚ(√2,√3) product) + `q23_sign.iii::q23_sign`. This is the **second
consumer of `cyclotomic_se3`** — it collides the *exact rotated tool point* (`mech_apply`) against an obstacle:
**kinematics ⊗ geometry, one substrate.**

## Conscience: theorem-to-machine (six rungs)

1. **STATEMENT.** For `W₀,W₁ ∈ (ℤ[√2,√3])³` over common `D>0`, `ΔW=W₁−W₀`, `a=Σ|ΔWₖ|²`, `b=2ΣW₀ₖ·ΔWₖ`, `c=Σ|W₀ₖ|²−R²D²`:
   the segment `{(W₀+tΔW)/D : t∈[0,1]}` meets `{|x|²≤R²}` iff `min_{t∈[0,1]}(at²+bt+c) ≤ 0`. With `a≥0`:
   `HIT ⟺ [b≥0 ∧ c≤0] ∨ [2a+b≤0 ∧ a+b+c≤0] ∨ [b<0 ∧ 2a+b>0 ∧ 4ac−b²≤0]`.
2. **HYPOTHESES.** (i) `W₀,W₁` over the **same** denominator `D>0` (common-den — caller's responsibility); (ii) `a≥0`
   (guaranteed: sum of real squares); (iii) exact ℚ(√2,√3) arithmetic; (iv) `q23_sign` exact; (v) i64 no-overflow (small
   configs).
3. **DISCHARGE (checked).** coefficients — `collide.iii` `dot3`/`q23_mul` (lines 42, 85, 86); case-analysis signs —
   `q23_sign` (lines 65, 70, 77, 81, 89); (i) stated in the organ header, satisfied by the KAT (`D=1`); (iv) —
   `q23_sign.iii:20` → `sqrtsum_lazy3` (gated 2121+).
4. **REALIZATION.** `collide.iii` + `2153_collision.iii`. Runs: compile rc=0; `2153` exit 99; `run_sqrtsum` 21/0.
   Observables: `T: 1 1 1` (endpoints clear, segment HIT) · `M: 1 -1` (rotated-point √3 membership).
5. **FALSIFIER (teeth).** Mutate a case branch / the hit expectation → tunnel arm exit 10; tangent → exit 20; mechanism
   membership → exit 30. **Demonstrated:** `hit 1→0` → **exit 10**.
6. **VERDICT: VERIFIED-IN-CODE** within scope (sphere obstacle, swept point, conservative straight segment, i64 envelope).

## Adversarial verdict — SURVIVES (high) within scope

- **Unstated hypothesis:** `W₀` and `W₁` must share the denominator `D` (the predicate takes a single `D`). Feeding two
  different-denominator configs without common-den scaling would give wrong coefficients. **Stated** in the organ header;
  the KAT uses `D=1`, so it holds. A misusing caller is out of contract.
- **Edge cases:** `a=0` (zero-length segment) → handled as a point test `sign(c)`; endpoints exactly on the sphere → hit
  (`≤0`, touch); coordinates small → no i64 overflow; `dot3` scratch (`COL_T`) is disjoint from outputs.
- **Degenerate pass:** the **clear arms** (R²=4, R²=8 → no hit) prove it does **not** return HIT spuriously; HIT fires
  only when a genuine min-sign `≤ 0`.
- **Precondition at call site:** `q23_sign` radicands `{1,2,3,6} > 0`; `a≥0` guaranteed by the sum-of-squares form so the
  upward-parabola branch logic is valid; `D>0`.

## Completion contract (all boxes, with evidence)

| Obligation | Evidence |
|---|---|
| POSITIVE | `2153` exit 99 |
| NEGATIVE | clear segments (R²=4, R²=8) → no hit; the tunnel's endpoint-sampling says clear (`p0=p1=1`) — the defeated failure mode |
| TEETH | `hit 1→0` mutant → exit 10 |
| REALIZATION | 2nd consumer of `cyclotomic_se3`: the SWEEP arm feeds the mechanism's OWN common-denominator swept segment (between two consecutive exact configs) to `col_seg_hits_sphere` — the kinematics⊗geometry unification is **gated, not narrated** |
| DETERMINISM | reseal 779 modules, `--verify` BIT-IDENTICAL |
| CORPUS | `run_sqrtsum` 21/0; new test `2153`; `run_corpus` delegates it |
| BINARY | no codegen/metal change (pure `.iii`) — N/A |
| CALIBRATION | predicate exactness = gated-fact; scope (sphere, conservative segment, common-D, i64) stated |

## The observable

```
T: 1 1 1     # segment (−10,3,0)→(10,3,0), sphere R²=25: endpoint t=0 OUTSIDE (1), t=1 OUTSIDE (1) — float sampling says CLEAR —
             #   yet the exact swept predicate says HIT (1). 4ac−b² = −25600 < 0. Tunneling caught.
M: 1 -1      # the mechanism's exact rotated tool (5√3,5,0) vs an off-centre sphere: outside at R²=32 (416−240√3>0),
             #   inside at R²=33 (412−240√3<0). A genuine √3 decision resolved exactly by q23_sign.
W: 1 1 1 0   # THE UNIFICATION (gated, not narrated): the mechanism's OWN motion between two consecutive exact configs
             #   (0°→15°), tool radius 10. Both configs OUTSIDE sphere R²=99 (|P|²=100, endpoint-sampling clear), but the
             #   common-denominator swept CHORD dips to 50(1+cos15)=98.30 < 99 -> the tool's motion tunnels through ->
             #   col_seg_hits (fed the mechanism's own swept segment) says HIT; clear at R²=98. Kinematics ⊗ geometry, run.
```

`unshatterable` (CSG) · `zero-loss` (routing) · `zero-drift` (kinematics) · **`no-tunneling`** (collision) — four faces of
the one exact substrate, and the fourth *collides the third against the first*: kinematics ⊗ geometry.
