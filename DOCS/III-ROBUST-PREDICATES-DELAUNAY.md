# III — Exact Robust Geometric Predicates + Delaunay

**Artifact:** `STDLIB/iii/aether/delaunay.iii` (organ) + `STDLIB/corpus/2154_delaunay.iii` (gate).
**Gate:** `run_sqrtsum_kats.sh` → `PASS 2154_delaunay : exit 99`, suite `PASS=22 FAIL=0` (no regression).
**Delegated** in `run_corpus.sh` skip-list. **Resealed:** 781 modules, `--verify` BIT-IDENTICAL.

## The problem — the canonical robustness disaster

Every triangulation / convex-hull / Voronoi / mesh algorithm is driven by two predicates: `orient2d(a,b,c)` (is `c`
left of, on, or right of line `a→b`?) and `incircle2d(a,b,c,d)` (is `d` inside the circumcircle of `a,b,c`?). In
floating point on near-degenerate inputs their signs are not merely wrong — they are **mutually inconsistent**
(Kettner–Mehlhorn, *"Classroom Examples of Robustness Problems in Geometric Computations"*): float can report `c` left
of `a→b` *and* right of `b→a`; three points pairwise "collinear" yet forming a triangle. Algorithms assume the predicate
is a **consistent** function of the true geometry (antisymmetry, transitivity); an inconsistent predicate makes them
build combinatorially **impossible topology** → invalid meshes, infinite loops, crashes.

## The insight

A predicate is the **sign of a determinant polynomial** in the coordinates. For integer/rational coordinates that sign
is computed **exactly** with integer arithmetic — and an exact sign is automatically **consistent** (a function of the
true value obeys antisymmetry and transitivity). So exact predicates are the whole cure: the mesh is provably valid
because every branch the algorithm took was the geometrically true branch.

## The float smoking gun (Cassini) — in code

For consecutive Fibonacci numbers, `orient2d((0,0),(F₄₂,F₄₁),(F₄₁,F₄₀)) = F₄₂·F₄₀ − F₄₁² = (−1)⁴¹ = −1` **exactly**
(Cassini's identity). But both products are `≈2⁵⁴·⁶`, above the 53-bit double mantissa, and differ by only 1 — so they
round to the **same double**, and a float `orient` returns `0` (collinear, wrong) while this exact predicate returns `−1`
(CW). The KAT asserts `p₁−p₂ = −1`, `p₂ > 2⁵⁴`, and `orient2d = −1` — the failure made concrete, not asserted.

## The unification

`orient2d_surd` orients points in ℚ(√b) (a CSG intersection point, a rotated tool point): the determinant is
`A + B√b`, whose sign routes through `sqrt_sum_sign::sqrtsum_lazy3` — the **same** engine behind the CSG kernel, router,
kinematics and collision. The KAT gates it with a **genuine `B≠0` radical sign** (not a `B=0` rational in disguise):
`c=(0,−1+√2)` gives `det = √2−1 → +1`; `b=(1,1+√2), c=(2+√2,3)` gives `det = −1−3√2 → −1` with **both** `B`-groups
`(p1q2+q1p2)` and `(p3q4+q3p4)` active; plus the exact collinear `(0,0),(1,√2),(√2,2)` (`det = 2 − √2·√2 = 0`, where
float says CCW). Mutating any part of the `B` (radical-coefficient) formula reddens the gate (exit 50) — the fifth face
is *exercised*, not asserted.

## Conscience: theorem-to-machine (six rungs)

1. **STATEMENT.** For `a,b,c,d ∈ ℤ²`: `orient2d = sign((bx−ax)(cy−ay)−(by−ay)(cx−ax))` and `incircle2d = sign` of the
   3×3 determinant of rows `((p−d), |p−d|²)`, `p∈{a,b,c}`, computed exactly in ℤ, equal the true geometric sign — hence
   antisymmetric and matching the true in/out relation. Cassini: `F₄₂·F₄₀ − F₄₁² = (−1)⁴¹ = −1`. Surd: `sign(A+B√b) =
   sqrtsum_lazy3({A,B},{1,b},2)`.
2. **HYPOTHESES.** (i) integer/rational coords; (ii) i64 no-overflow — orient `|coord|<2³⁰`, incircle `|coord|<2¹⁵`
   (degree-4 det `<2⁶⁰`); (iii) incircle sign is relative to `abc` orientation (`circum_contains` normalizes); (iv) surd
   coord `= rp + sc·√b`.
3. **DISCHARGE (checked).** `orient2d` — `delaunay.iii:38`; `circum_contains` normalization — `:57`; surd sign — `:83`
   (`sqrtsum_lazy3`); envelope (ii) stated in header + KAT uses in-envelope coords.
4. **REALIZATION.** `delaunay.iii` + `2154_delaunay.iii`. Runs: compile rc=0; `2154` exit 99; `run_sqrtsum` 22/0.
   Observables: `F: -1 -1` · `S: 0`.
5. **FALSIFIER (teeth).** Mutate the determinant/sign → orient arm exit 10; the Cassini expectation → exit 20; incircle →
   30; flip → 40; surd → 50. **Demonstrated:** `Cassini −1 → +1` → **exit 20**.
6. **VERDICT: PROVEN-IN-CODE** within scope (2D, integer/algebraic coords, i64 envelope, bigint tier noted).

## Adversarial verdict — SURVIVES (high) within scope

- **Unstated hypothesis:** i64 no-overflow — the degree-4 incircle determinant overflows for `|coord|≥2¹⁵`. **Stated** in
  the organ header; the KAT uses tiny coords; large coords need the bigint tier (stated, not hidden).
- **Edge cases:** collinear `abc` fed to `incircle` is a degenerate circumcircle — a robust mesher never forms such a
  triangle (noted); duplicate points → `orient=0`; the Fibonacci degree-2 orient fits i64.
- **Degenerate pass:** the collinear arms (`(0,0),(1,1),(2,2)→0`; surd `→0`) prove `orient` returns `0` (not a false
  CCW); the **antisymmetry** check proves consistency (`orient(a,b,c) = −orient(b,a,c)`).
- **Precondition at call site:** `sqrtsum` radicands `{1,b}>0`; incircle convention normalized by orientation.

## Completion contract (all boxes, with evidence)

| Obligation | Evidence |
|---|---|
| POSITIVE | `2154` exit 99 |
| NEGATIVE | collinear → 0; incircle outside → −1; legal quad → no flip; antisymmetry consistency check |
| TEETH | `Cassini −1→+1` → exit 20; **`orient2d_surd` B-coefficient sign flip → exit 50** (the radical term is truly gated, both `B`-groups) |
| REALIZATION | first shipped robust-predicate consumer (orient/incircle + flip + surd bridge) |
| DETERMINISM | reseal 781 modules, `--verify` BIT-IDENTICAL |
| CORPUS | `run_sqrtsum` 22/0; new test `2154`; `run_corpus` delegates it |
| BINARY | no codegen/metal change (pure `.iii`) — N/A |
| CALIBRATION | predicate exactness = gated-fact; Kettner–Mehlhorn/Cassini = cited; scope (2D, i64 envelope, bigint tier) stated |

## The observables

```
F: -1 -1     # Cassini: F42·F40 − F41² = −1 exactly; orient2d = −1 (CW). A 53-bit double, unable to separate the two
             #   ~2^54.6 products differing by 1, returns 0 (collinear, WRONG). The Kettner–Mehlhorn robustness disaster, killed.
S: 1 0       # ℚ(√2) orientation via the Σ√ engine: det with c=(0,−1+√2) is √2−1 → +1 (a genuine B≠0 radical sign); and
             #   (0,0),(1,√2),(√2,2) is det = 2 − √2·√2 = 0 → certified EXACTLY collinear, where float says CCW.
```

`unshatterable` (CSG) · `zero-loss` (routing) · `zero-drift` (kinematics) · `no-tunneling` (collision) ·
**robust predicates** (meshing) — five faces of the one exact-sign substrate. The foundation all of computational
geometry stands on, made exact.
