# III — Exact Real Root Isolation (Sturm's Theorem)

**Artifact:** `STDLIB/iii/aether/sturm.iii` (organ) + `STDLIB/corpus/2156_sturm.iii` (gate).
**Gate:** `run_sqrtsum_kats.sh` → `PASS 2156_sturm : exit 99`, suite `PASS=24 FAIL=0` (no regression).
**Delegated** in `run_corpus.sh` skip-list. **Resealed:** 783 modules, `--verify` BIT-IDENTICAL.

## The problem

A float root-finder samples/iterates and **cannot know how many** real roots a polynomial has, nor separate roots
closer than its precision: it merges a cluster into one, misses a pair entirely, or hallucinates a spurious root from
rounding. Worst and simplest: a polynomial that dips below zero and back up inside `[a,b]` has the **same sign at `a`
and `b`**, so checking the endpoints (or any coarse sampling) finds **no root** — while there are two.

## The insight

The **number** of real roots in an interval is a topological invariant computable **exactly** from finitely many
integer **sign** evaluations — no approximation of a root is needed to *count* roots. Sturm's theorem: for squarefree
`p`, build the chain `p₀=p, p₁=p', p_{k+1} = −rem(p_{k−1},p_k)` down to a nonzero constant; then the number of distinct
real roots in `(a,b]` is `V(a) − V(b)`, where `V(x)` = sign changes in `(p₀(x),…,p_m(x))` skipping zeros. Bisect any
interval whose count exceeds 1 until every root sits alone. All exact.

## The correctness crux (and how it's *gated*)

The exact remainder has rational coefficients; an integer **pseudo-remainder** scales the result by `lc(p_k)^s` (`s`
eliminations). **If that factor is negative it flips signs and corrupts the count.** So each stored polynomial is made a
**positive multiple** of the true `−rem`: `S = −R · sign(lc)^s`, then content-reduced.

This correction is a **no-op for generic chains** (where the degree drops by 1 each step ⟹ `s=2`, even ⟹ `sign(lc)^s=+1`)
— so the first test suite never exercised it. A **defective chain** (a degree gap ⟹ an odd-step remainder) with a
negative leading coefficient is required. `x⁴+x−1` (no `x²`/`x³` term) is exactly such: its chain has `p₂ = −3x+4`
(`lc<0`) and the next step has 3 eliminations. **With the correction it counts 2 real roots; without it, 0.** The KAT's
DEFECTIVE arm gates it: **removing the sign correction reddens the gate (exit 60).** *(Found and closed preemptively —
the "untested load-bearing path" pattern.)*

## Conscience: theorem-to-machine (six rungs)

1. **STATEMENT.** For `p∈ℤ[x]` and `a<b`, `#{distinct real roots in (a,b]} = V(a) − V(b)` over the Sturm chain (which
   terminates at a multiple of `gcd(p,p')`, so the distinct count holds **even for non-squarefree `p`** — observed, not
   assumed: `(x−1)²(x−2)→2`, `(x−1)³→1`, both gated),
   with `p_{k+1}` realized as `S = −(lc(p_k)^s·rem(p_{k−1},p_k)) · sign(lc(p_k))^s`, content-reduced.
2. **HYPOTHESES.** (i) squarefree `p` (else `gcd(p,p')`); (ii) exact integer arithmetic; (iii) each stored poly a
   **positive** multiple of the true remainder (the sign correction); (iv) i64 envelope (degree ≤7, bounded coeffs/
   interval); (v) `V` skips zeros.
3. **DISCHARGE (checked).** chain — `sturm_build`; remainder+correction — `st_prem` (`sturm.iii:59`, cited at 121/229);
   count — `root_count` (`:165`); squarefree — `poly_gcd`. The correction (iii) is gated by the DEFECTIVE arm.
4. **REALIZATION.** `sturm.iii` + `2156_sturm.iii`. Runs: exit 99; `run_sqrtsum` 24/0. Observables:
   `W: 2 0 2` · `I: 4` · `Q: -1 1` · `D: 2`.
5. **FALSIFIER (teeth).** Witness assertion flip → exit 10; **removing the sign correction → DEFECTIVE arm exit 60**
   (demonstrated: `x⁴+x−1` counts 2 with the correction, 0 without); isolate/count/sqfree mutations → 30/20/50.
6. **VERDICT: VERIFIED-IN-CODE** within scope (squarefree, degree ≤7, i64 envelope; bigint tier noted).

## Adversarial verdict — SURVIVES (high) within scope

- **Unstated hypothesis (found & fixed):** the sign correction is a no-op for non-defective chains, so the initial suite
  left it *untested*. Now gated by `x⁴+x−1` (a defective chain), where the correction changes the count `2` vs `0`.
- **Edge cases:** a root landing exactly on a bisection midpoint `m` needs no guard — the half-open `(lo,m]`/`(m,hi]`
  convention places it in the left half, isolating normally as `[lo,m]`; zero remainders; degree gaps (the
  defective case, now tested); `x⁴+x+1` (0 real roots) correctly returns 0.
- **Degenerate pass:** non-squarefree input would miscount — scoped, with `poly_gcd` shown; the "positive at both ends,
  2 inside" witness proves the count is not endpoint-sampling.
- **Precondition:** homogenized sign eval needs `xd>0`; i64 envelope bounds every product.

## Completion contract (all boxes, with evidence)

| Obligation | Evidence |
|---|---|
| POSITIVE | `2156` exit 99 |
| NEGATIVE | `x⁴+x+1` → 0 roots (correctly); the positive-at-both-ends witness (naive sampling → 0, Sturm → 2) |
| TEETH | witness flip → exit 10; **sign-correction removal → exit 60** (the crux, gated by a defective-chain poly) |
| REALIZATION | `root_count`/`isolate_roots` consumers — the exact engine beneath every geometry root (CSG ∩, collision TOI) |
| DETERMINISM | reseal 783 modules, `--verify` BIT-IDENTICAL |
| CORPUS | `run_sqrtsum` 24/0; new test `2156`; `run_corpus` delegates it |
| BINARY | no codegen/metal change (pure `.iii`) — N/A |
| CALIBRATION | Sturm's theorem = cited; exactness = gated-fact; scope (squarefree, degree ≤7, i64, bigint tier) stated |

## The observables

```
W: 2 0 2     # (x-1)(x-2): V(0)=2, V(3)=0 -> root_count(0,3]=2. The polynomial is POSITIVE at both endpoints (p(0)=p(3)=2),
             #   so endpoint sampling / a coarse float finds NO root -- Sturm counts exactly 2. The float failure, killed.
I: 4         # (x-1)(x-2)(x-3)(x-4) isolated into 4 disjoint one-root rational intervals.
Q: -1 1      # gcd((x-1)^2(x-2), derivative) = [-1,1] = (x-1): the double root detected exactly (squarefree part).
D: 2         # x^4+x-1 (defective Sturm chain) counts 2 real roots -- the sign correction is load-bearing here (0 without it).
```

`unshatterable` (CSG) · `zero-loss` (routing) · `zero-drift` (kinematics) · `no-tunneling` (collision) ·
`robust predicates` (meshing) · **exact root isolation** (equation solving) — six faces of the one exact-sign substrate,
and the sixth is the engine *beneath* the others: every geometry root is a root of a polynomial, counted exactly here.
