# The Universal Block — one kernel, four verbs, many faces

*Gated demonstrator: `2149_universal_block.iii` (exit 99). Runs in the isolated kit gate
(`build_and_run.ps1`, 5/5 GREEN). Depends only on `kfield.iii` + `coincidence` + `sha256`.*

## The thesis

The exact-geometry tools in this repo were never separate scopes. Triangle discovery, the
coincidence-fuzzer, the SE(3) screw, the quotient oracle, sum-of-square-roots sign, and now
kinematics are **one kernel** with different front-ends. The kernel is:

> a **point in a fixed multiquadratic field** `K = ℚ(√A,√B,√C)`, acted on by **four verbs**
> that `kfield` already provides.

| verb | what it is | kfield primitive | used by |
|---|---|---|---|
| **CONSTRUCT** | build a point by field arithmetic (multiply, add, scale, rotate, solve) | `kf_mul` (+ `fadd`/`fscale`/`reflect`) | every application |
| **IDENTIFY** | the Eidolon — content-address the canonical form | `kf_point_addr` (SHA-256) | fuzzer coincidence, FK∘IK proof |
| **DECIDE** | the exact sign / zero / order test | `kf_sign` (Galois tower, no separation bound) | reachability, orientation, equality |
| **QUOTIENT** | the Galois action `√d ↦ −√d` — the orbit generator | REFLECT (mask sign-flip, O(1)) | excenters (2277), elbow branches |

plus one guard — `kf_rat_in_field` — that reports honestly when a construction **leaves K**.

## The law that makes it one (not a facade)

Uniting the verbs is not a rename, because IDENTIFY and DECIDE are provably the **same relation**.
For two K-points `P, Q` sharing a common denominator:

```
kf_point_addr(P) == kf_point_addr(Q)   ⟺   kf_sign(Px − Qx) == 0  ∧  kf_sign(Py − Qy) == 0
```

Both sides are field equality on `K` (kfield is sound + complete on `K`). So "the Eidolon
coincides" and "the exact sign of the difference is zero" are two faces of one predicate. This
is **FACE 3** of the KAT, checked on a matched pair (both verbs agree *equal*) and a mismatched
pair (both agree *distinct*). *Obligation discovered adversarially:* the law needs a **common
denominator** and compares **numerators** — off-field / mixed-denominator points belong to the
wall, not the law.

## Kinematics is the kernel (FACE 1 + 2)

The newest front-end. Exact inverse kinematics of a planar 2-link arm (`L2=L3=2`) to target
`W=(3,0)`. Law of cosines gives `cosθ3 = 1/8` (rational) and `sinθ3 = 3√7/8` (a surd) — the joint
trig lives in `ℚ(√7)`. CONSTRUCT the forward kinematics from the solved trig; **the √7 cancels
and the wrist lands on (3,0) exactly**. Both verbs certify it: DECIDE (`kf_sign` of each
coordinate difference is 0) and IDENTIFY (the wrist Eidolon equals the target Eidolon).

- **QUOTIENT**: the *other* elbow solution is the Galois conjugate under `√7 ↦ −√7` — a pure sign
  flip, O(1), zero `kf_mul` — and it is a *genuinely distinct configuration* (checked: the two
  elbows differ) that reaches the *same* target. Proving one elbow branch proves the other for
  free, exactly as `σ_A` maps the incenter to an excenter in `2277`. Mutation-checked: replacing
  REFLECT with a no-op makes the distinctness tooth fire (exit 14).
- **FACE 2 — cross-application**: the *same* `coin_observe` engine the fuzzer (`2148`) uses to
  discover algebraic identities also flags the kinematics identity — both elbow wrists and the
  target are one Eidolon; a control configuration `(3,1)` does not collide. "Two different arm
  configurations reach the same point" is a proven theorem, by the identical IDENTIFY verb.

## The wall, stated with teeth (FACE 4)

Not overclaimed. Two honest limits:

1. **Field-exit.** `kf_rat_in_field` reports which reach-surds stay in `K = ℚ(√7,√2,√3)` and which
   leave it: `√7` and `√14 = √2·√7` stay; `√5`, `√11` leave. When a target's IK needs a surd
   outside `K`, the kernel **refuses** rather than hash a false address. This is the miniature of
   the real barrier: **general 6R inverse kinematics is degree-16 (Raghavan–Roth), generically not
   solvable in radicals, so not in any multiquadratic field.**
2. **Transcendental angle.** The joint *angle* is `arccos(algebraic)` — transcendental, not a field
   element. What is exact is the joint **cos/sin** and the wrist **position** (the decoupled,
   spherical-wrist sub-problem), where the closed form replaces the jittering Jacobian/Newton
   iteration. The exact win is the **discrete decisions** — reachable? which branch? at a
   singularity? — where `kf_sign` returns *exactly* 0 at full extension (`D2 = (L2+L3)²`), the value
   a float reach-test rounds to ±ε and mis-classifies.

## What is and isn't claimed

- **Claimed (gated):** the four verbs are one kernel; the IDENTIFY⟺DECIDE law; exact position
  kinematics for the decoupled sub-problem, *proven* (not approximated) by FK-coincidence; the
  elbow orbit as an O(1) Galois quotient; honest field-exit refusal.
- **Not claimed:** a new capability beyond `kfield` (this is an *architecture / unification*, proven
  by composition, not new arithmetic); exact transcendental joint angles; exact general 6R IK;
  soundness beyond kfield's i64 coefficient envelope (kept small here on purpose).
