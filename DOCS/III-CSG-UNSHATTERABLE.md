# III — The "Unshatterable" Quadric-CSG Kernel

**Artifact:** `STDLIB/iii/aether/csg_kernel.iii` (organ) + `STDLIB/corpus/2150_csg_kernel.iii` (gate).
**Gate:** `run_sqrtsum_kats.sh` → `PASS 2150_csg_kernel : exit 99`, suite `PASS=18 FAIL=0` (no regression on 2120–2147).
**Delegated** in `run_corpus.sh` (skip-list line ~1816) to its owning gate, exactly like 2143–2147.

## The problem, precisely

A float B-rep CAD kernel subtracts a cylinder from a sphere by **tessellating the intersection curve**. The
curve's vertices are irrational (nested radicals); float rounds them, so the sphere-mesh and the cylinder-mesh
disagree on whether a shared vertex is *on* the surface. Per Kettner–Mehlhorn–Näher–Schirra, mutually
**inconsistent float predicates yield combinatorially impossible topology** → the mesh tears into non-manifold
geometry ("vertices miss each other").

## The insight (what actually changed the design)

The tear is not caused by the curve being hard to *compute*; it is caused by the **predicates over its points
disagreeing**. So the cure is **exact predicates over exactly-represented points**. The prompt names tower-denesting
as the mechanism, but the *load-bearing* exactness is **incidence** — deciding `sign(Q(p)) = 0` when a point built on
one surface lies on another. That reduces to III's crown jewel, the exact sign of a sum of square roots.

We **compose** two already-gated organs — never reimplement (that would re-import the 64-slot-handle and i64-overflow
bugs those organs already fixed):

- `sqrt_sum_sign.iii :: sqrtsum_lazy3` — exact `sign(Σ aᵢ√bᵢ)`, certifying the on-surface zeros float cancels. [2121–2147]
- `exact_denest.iii  :: denest_r1`    — exact rank-1 tower denest: is `√(a+b√d) ∈ ℚ(√d)`? [2145]

### The reduction (membership / incidence)

A boundary point of sphere∩cylinder is `p = (x₀, s_y·√β, s_z·√γ)` with `x₀,β,γ` rational, `s_y,s_z ∈ {±1}`. For any
integer quadric `Q = qa·x² + qb·y² + qc·z² + qd·xy + qe·xz + qf·yz + qg·x + qh·y + qi·z + qj`:

```
Q(p) = [qa·x₀² + qb·β + qc·γ + qg·x₀ + qj]        (rational, radicand 1)
     + (qd·x₀ + qh)·s_y · √β
     + (qe·x₀ + qi)·s_z · √γ
     + qf·s_y·s_z       · √(βγ)
```

a **4-term Σ√** whose sign `sqrtsum_lazy3` decides exactly — returning `0` iff `p` lies **on** `Q`. `n≤4` sits far below
the `n≥6` arena/false-zero regime, so the substrate's one known soundness hole is structurally untouched.

## Honest claim (NOT "always manifold")

Exact predicates kill the **float-artifact** tear. They do **not** make a genuinely degenerate input manifold: a
cylinder internally tangent to the sphere pinches even in exact arithmetic. The guarantee is therefore:

1. Every predicate the boundary topology depends on is computed with **zero floating-point error**, so the kernel
   never *emits* a float-artifact non-manifold; and
2. A genuine degeneracy (tangency pinch) is **detected and flagged** (`csg_sphere_cyl_class` codes 3/4), never silently
   corrupted.

This is fully responsive: the prompt's failure mode ("vertices miss each other") *is* the float-artifact kind.

### Two advisor corrections folded in

- **Tangency is rational, not a denest.** ∇S ∥ ∇C forces the contact at `y=z=0` ⟹ `|a| = R ± r` — an *integer*
  equality (`csg_sphere_cyl_class`). Denest's genuine home is the **rank-1 triple-point corner coordinate**.
- **Corner coordinate is where denest earns its place.** For S∩C∩{plane z=x}, the corner solves a quadratic ⟹
  `x ∈ ℚ(√Δ)`, `Δ = 2a²+R²−r²`, and the corner's `y` satisfies `y² = p + q√Δ`, `p = 2r²−6a²−R²`, `q = 4a` — a depth-2
  nested radical `denest_r1` either **collapses** (special incidence; exact coord `x+y√Δ`) or certifies **genuine rank-2**.

## Conscience: theorem-to-machine (six rungs)

1. **STATEMENT.** (a) For integers `aᵢ` and `bᵢ≥0`, `sign(Σ aᵢ√bᵢ) ∈ {−1,0,+1}` is exact, `=0` iff the sum is `0`
   (separation-bound theorem). (b) For integers `a,b`, `d>0`, `denest_r1` returns `(x,y)` with `(x+y√d)²=a+b√d` iff
   `a+b√d` is a perfect square in `ℤ[√d]`. Composition: `sign(Q(p))` = predicate (a) on the 4-term reduction; sphere–cyl
   tangency ⟺ `|a|=R±r`; corner `√(p+q√Δ)` resolved by (b).
2. **HYPOTHESES.** (i) `x₀,β,γ` integer (rational-x boundary sample); (ii) `β,γ≥0`; (iii) i64 no-overflow envelope;
   (iv) denest envelope `|p|<2³⁰, |q|<2²⁰, Δ<2²⁰`; (v) `n≤4`.
3. **DISCHARGE (checked).** predicate (a) call — `csg_kernel.iii:70` `return sqrtsum_lazy3(&CSG_A,&CSG_B,4)` [`n=4`
   literal ⟹ (v)]; reduction coeffs — `csg_kernel.iii:63–69`; tangency — `csg_kernel.iii:79`
   `csg_sphere_cyl_class`; corner — `csg_corner_rank`→`denest_r1`, derivation `csg_sc_plane_corner`; envelope abstain
   witnessed by Arm F. (`iii_check_discharge` → DISCHARGED at lines 70 and 79.)
4. **REALIZATION.** `csg_kernel.iii` + `2150_csg_kernel.iii`. Runs: standalone `iiis-2 --compile-only` rc=0; `gcc` link
   rc=0; direct run **exit 99**; `run_sqrtsum_kats.sh` → `PASS 2150_csg_kernel : exit 99`, `PASS=18 FAIL=0`.
   *(`iii_run_kat` reports COMPILE_FAIL — its documented space-path quoting bug; a differential run on the already-green
   `2145_denest` reproduces the identical false COMPILE_FAIL, proving it is the tool, not the KAT. The authoritative
   multi-organ instrument is `run_sqrtsum_kats.sh`, which quotes paths and links the organ objects.)*
5. **FALSIFIER (teeth).** Mutate a reduction sign ⟹ Arm A/A'/C mismatch ⟹ exit 10. Short-circuit lazy3 past the exact
   tier ⟹ tier-coverage guard ⟹ exit 60. Break a tangency inequality ⟹ Arm D ⟹ exit 30. Corrupt the corner ⟹ Arm E
   squares-back fails ⟹ exit 40. A predicate that straddles like fixed precision ⟹ Arm B ⟹ exit 20. All are distinct
   REDs; the real run returns 99 (every arm green).
6. **VERDICT: VERIFIED-IN-CODE** (within the stated scope). The "unshatterable" claim is the scoped one (no float-artifact
   non-manifold; genuine degeneracies flagged) — explicitly **not** "always manifold".

## Adversarial verdict — SURVIVES (high) within scope

- **Unstated hypothesis:** the reduction needs **rational `x₀`**; a generic irrational curve point (rank ≥ 2) is *not*
  handled by lazy3 — that is the denest/tower path. Stated in the organ header; scope honored.
- **Edge cases:** `β=0`/`γ=0` → `√0` contributes 0 (handled, Arm B uses `γ=0`); `n≤4` structurally avoids the `n≥6`
  false-zero hole; denest out-of-envelope → honest abstain (Arm F).
- **Degenerate pass:** a spurious on-surface `0` cannot arise — lazy3 returns `0` only via canon (genuine cancellation)
  or the certified separation bound; Arms C/B prove non-incidences return definite `±1`; the tier-coverage guard proves
  the inputs traversed canon **and** the exact tier (not an i64 short-circuit).
- **Precondition at call site:** `bᵢ≥0` holds because the radicands are squared coordinates `y²,z² ≥ 0`.

## The observable ("float breaks, exact holds")

`2150` prints the exact `z=0` cross-section of a real sphere-minus-cylinder (a filled disk with a clean circular bite —
integer-classified, no float, no tear), then:

```
B: elo -344 ehi 641 exact 1     # fixed precision f=10 STRADDLES 0 (−344<0<641) → cannot decide sign(577−408√2);
                                #   sqrtsum_lazy3 adapts and returns the definite +1 (= sign(577²−2·408²) = +1)
E: 4+√19 = 4 1                  # triple-point corner y-coordinate COLLAPSES exactly to 4+√19 (verified: 4²+19·1²=35, 2·4·1=8)
```

The straddle *is* the tear: a fixed precision that brackets `0` must guess, and inconsistent guesses shatter the mesh.
The adaptive exact predicate never guesses.
