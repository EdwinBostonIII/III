# III — Exact Real Algebraic Numbers (sign · total order · decidable EQUALITY)

**Artifact:** `STDLIB/iii/aether/algnum.iii` (organ) + `STDLIB/corpus/2157_algnum.iii` (gate).
**Gate:** `run_sqrtsum_kats.sh` → `PASS 2157_algnum : exit 99`, suite `PASS=25 FAIL=0` (no regression).
**Delegated** in `run_corpus.sh` skip-list. **Resealed:** 784 modules, `--verify` BIT-IDENTICAL.
**Composes, reimplements nothing:** `sturm.iii` (face 6 — `root_count`/`poly_gcd`) + `sqrt_sum_sign.iii` (face 1 — `sqrtsum_lazy3`).

## The problem — the zero problem

The prior six faces all **produce** algebraic numbers: a CSG surface intersection, a collision time-of-impact, a
rotation angle, a Delaunay circumcentre, a Sturm-isolated root. To *use* them you must **compare** them — and above all
answer the two questions a float cannot: *is this value zero?* (is a constructed point **on** a curve) and *are these two
values equal?* (do two constructed points **coincide**). Deciding `α = β` by refining approximations to an epsilon is a
category error: any threshold **both misses** true equalities that differ below it **and fabricates** false ones above it.
This is the classical *zero problem*, which for algebraic numbers **is decidable** — and a float simply never decides it.

The smoking gun, made visible in this gate: with the equality decision removed, comparing `√2` to `√2` (presented via two
different polynomials) does not merely loop — it **fabricates an order**, printing `Z: 1 -1 -1` where the answer is `0 0 0`.

## The insight

An algebraic number's identity is *(a polynomial it satisfies, which of its real roots)*. Two are **EQUAL** iff they share
that root — decided exactly by **gcd**: a common root of `p` and `q` that lies in the overlap of the two isolating
intervals must, by isolation, equal each interval's unique root, hence `α = β`. Their **ORDER** is decided because ℚ is
dense: distinct reals have a rational strictly between them, and Sturm's `root_count` finds it by **dyadic bisection** in
finitely many steps. **SIGN** is order against 0. Nothing approximates a root — it is finitely many exact integer sign
evaluations. The number is the exact **cut** it makes in ℚ, computed, never sampled.

## The unification — face 1 wedded to face 6

For `α = √b` (root of `x²−b`), `sign(α − n/d)` is computable **two mathematically independent** exact ways: by **Sturm
refinement** of `α`'s isolating interval (this file, on the `sturm.iii` engine — face 6), and by the **sum-of-square-roots
separation-bound oracle** `sign(d·√b − n) = sqrtsum_lazy3([d,−n],[b,1])` (face 1, the substrate). They **must agree** for
every rational — two exact-sign faculties certifying one cut. The KAT's UNIFY arm gates that agreement over a fan of
rationals including the tight `99/70` (where `70·√2 = 98.995…` vs `99`), and MUT2 proves it is **not a tautology**:
breaking either oracle makes them disagree (`U: 1 1 1 1 1 0`, exit 40).

## Conscience: theorem-to-machine (six rungs)

1. **STATEMENT.** For `p,q ∈ ℤ[x]` and real algebraic `α` (unique root of `p` in `(l₁,h₁]`), `β` (unique root of `q` in
   `(l₂,h₂]`): the trichotomy `α<β / α=β / α>β` is decidable, with `α=β ⇔ gcd(p,q)` has a root in
   `(max(l₁,l₂), min(h₁,h₂)]`; and `#{distinct real roots of p in (a,b]} = V_p(a) − V_p(b)` (Sturm).
2. **HYPOTHESES.** (i) each interval isolates **exactly one** distinct real root (`root_count(box)=1`); (ii) exact integer
   arithmetic within the i64 envelope — dyadic denominator `2^depth`, homogenised eval forms `xn^i·xd^(deg−i)`, so
   `deg·depth ≲ 60`; (iii) the shared Sturm chain is **rebuilt for the current polynomial** before every query; (iv)
   denominators `> 0`; (v) for the Σ√ cross-check, `α = √b` exactly.
3. **DISCHARGE (checked).** (i) `an_valid` (`algnum.iii`) — root_count over the box; the KAT asserts `==1` per register.
   (ii) stated envelope; the gate's witnesses separate at depth `≤ 14`, degree `≤ 3`. (iii) `an_build` rebuilds the chain
   before each `root_count` (`an_refine`/`an_valid`/`an_sign_vs_rat`); `an_gcd_equal` (`algnum.iii:109`, verified
   DISCHARGED) builds the gcd chain before its overlap count. (iv) `an_set` sets `D=1`, `an_refine` doubles it. (v)
   `an_sqrt_vs_rat` (`algnum.iii:187`, verified DISCHARGED) sets radicands `{b,1}`. Equality: `an_gcd_equal` (`:109`);
   order: `an_cmp` (`algnum.iii:136`, verified DISCHARGED).
4. **REALIZATION.** `algnum.iii` (`an_cmp`/`an_gcd_equal`/`an_refine`/`an_sign`/`an_sign_vs_rat`/`an_sqrt_vs_rat`/
   `an_set_iv`) + `2157_algnum.iii`. Runs: exit 99; `run_sqrtsum` 25/0. Observables: `Z: 0 0 0` · `N: -1 -1 1` ·
   `S: 1 -1 0` · `U: 1 -1 1 -1 -1 0` · `R: 0 -1 0`. The **REAL-CONSUMER (R) arm** feeds a genuine prior-face *product*:
   `sturm.iii`'s `isolate_roots` isolates root 3 of `(x−3)(x−5)` and of `(x−3)(x−7)` (bisected, dyadic denominators),
   `an_set_iv` loads those emitted intervals, and `an_cmp` decides them **EQUAL** by gcd, then orders a produced root 3
   before a produced root 5. At full strength it isolates the **irrational** `√2` (root of `x²−2`) via `isolate_roots`
   and decides that emitted interval **EQUAL** to a hand-authored `√2`-via-`x³−2x` (different polynomial, non-trivial
   gcd) — the exact thing floats cannot do — no hand-authored interval in the produced arm.
5. **FALSIFIER (teeth — three demonstrated).** **MUT1** — `an_gcd_equal` never reports equal (a refine-only impostor):
   the ZERO arm prints `Z: 1 -1 -1` and **reddens to exit 10** (equal numbers get a fabricated order). **MUT2** —
   `an_sqrt_vs_rat` sign flipped: the UNIFY arm prints `U: 1 1 1 1 1 0` and **reddens to exit 40** (the two-oracle
   cross-check is not a tautology). **MUT3** — `an_set_iv` mis-scales a loaded interval (hi by the wrong denominator):
   the R arm's `an_valid` check catches that the interval no longer isolates one root and **reddens to exit 50**. Also:
   witness flip → 10/20/30/40/50 per arm.
6. **VERDICT: PROVEN-IN-CODE** within scope. Three independent falsifiers redden real gates; three discharge sites
   verified against the live tree; determinism resealed BIT-IDENTICAL (784).

## Adversarial verdict — SURVIVES (high) within scope

- **Unstated hypothesis (found & discharged):** each interval must genuinely isolate one root — else "unique root" fails.
  Enforced by `an_valid` and asserted `==1` per register in the KAT (the ZERO arm).
- **The i64 refinement envelope (found preemptively):** the homogenised sign eval forms `xd^deg` with `xd=2^depth`, so
  refinement depth is bounded by `deg·depth ≲ 60`. Witnesses were **chosen to separate shallowly** (√2 vs ∛3 at depth ~5,
  √2 vs 99/70 at ~14, both degree ≤ 3); deeper/higher needs the bigint tier — stated, not hidden.
- **Degenerate pass (negative arm):** does it return EQUAL on distinct input? Only if gcd falsely finds a shared root — but
  gcd is exact integer Euclid; a **coprime** pair (√2 vs ∛3) takes the refine branch and returns `-1`, never `0`. The
  `poly_gcd` args are ordered by descending degree so `st_prem`'s `degA≥degB` precondition holds at the call site.
- **Aliasing:** `an_cmp(r,r)` → identical intervals overlap, `gcd(p,p)=p` has the root → `0` (equal). Correct.

## Completion contract (all boxes, with evidence)

| Obligation | Evidence |
|---|---|
| POSITIVE | `2157` exit 99; `Z: 0 0 0` (√2 three ways decided EQUAL) · `N: -1 -1 1` · `S: 1 -1 0` · `U: 1 -1 1 -1 -1 0` · `R: 0 -1 0` |
| NEGATIVE | coprime √2 vs ∛3 → `-1` (not `0`) — no false equality; the "positive-at-both-representations" √2×3 witness proves equality is not endpoint-sampling |
| TEETH | **MUT1** equality-branch removed → `Z: 1 -1 -1`, exit 10; **MUT2** Σ√ oracle flipped → `U: 1 1 1 1 1 0`, exit 40; **MUT3** `an_set_iv` mis-scales a real isolate output → `an_valid` catches, exit 50 |
| REALIZATION | **VERIFIED, not narrated:** the **R arm** consumes a real prior-face *product* — `sturm.iii::isolate_roots`' emitted intervals, including the **irrational** `√2` — and decides them EQUAL/ordered; the **UNIFY arm** consumes face 1 (`sqrtsum_lazy3`). The geometric faces (CSG/collision/delaunay) already route their coordinates through the **Σ√ substrate** (they call `sqrtsum`); `isolate_roots` is the general root-isolation engine. A direct `algnum`-register emit from the geometric faces is the stated next integration |
| DETERMINISM | reseal 784 modules, `--verify` BIT-IDENTICAL |
| CORPUS | `run_sqrtsum` 25/0; new test `2157`; `run_corpus` delegates it |
| BINARY | no codegen/metal change (pure `.iii`) — N/A |
| CALIBRATION | Sturm's theorem + gcd-decidability = cited; exactness = gated-fact; scope (order structure only, i64 `deg·depth≲60`, degree ≤ 3 witnesses; algebraic arithmetic via resultants = stated future bigint tier) stated |

## The observables

```
Z: 0 0 0        # sqrt(2) presented THREE ways (root of x^2-2, of x^3-2x, of 2x^2-4), overlapping isolating intervals,
                #   decided EQUAL each pair by gcd-shared-root. The zero problem, decided -- NOT by refinement to epsilon.
N: -1 -1 1      # sqrt(2) < cbrt(3) (coprime -> refine to separate); sqrt(2) < 99/70 (near-miss rational); reversed -> +1.
S: 1 -1 0       # +sqrt(2) -> +1;  -sqrt(2) (root of x^2-2 in (-2,-1]) -> -1;  exact 0 (root of x in (-1,1]) -> 0.
U: 1 -1 1 -1 -1 0  # STURM sign(sqrt2 - n/d) == Sigma-sqrt sign(d*sqrt2 - n) over 7/5,3/2,41/29,99/70,17/12; and
                #   99/70 vs its OWN root -> exactly 0 (the half-open convention + exact rational-root detection).
R: 0 -1 0       # real prior-face PRODUCT: sturm.iii::isolate_roots emits root 3 of (x-3)(x-5) and of (x-3)(x-7) -> EQUAL by
                #   gcd (0); produced 3 < produced 5 (-1); and the IRRATIONAL sqrt(2) isolated from x^2-2 == sqrt(2) via x^3-2x (0).
```

`unshatterable` (CSG) · `zero-loss` (routing) · `zero-drift` (kinematics) · `no-tunneling` (collision) ·
`robust predicates` (meshing) · `exact root isolation` (equation solving) · **exact algebraic numbers** (comparison &
equality) — **seven faces of the one exact-sign substrate**, and the seventh is the **capstone**: the comparison layer
that makes algebraic outputs first-class, comparable, equality-decidable numbers — demonstrated on real `isolate_roots`
output including the irrational √2 (the engine, R arm) and on the Σ√ substrate every geometric coordinate already routes
through (face 1, UNIFY arm).
