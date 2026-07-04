# III MECH — the exact 4-bar mechanism workbench

`mech.exe` (source `STDLIB/iii/aether/mech.iii`, build `STDLIB/scripts/build_mech.sh`) is a
user-facing command-line tool for planar four-bar linkage analysis and synthesis in which every
computed quantity is **exact** — no floating point appears anywhere in the mathematics. Where a
floating CAD kernel blurs a dead-centre, misclassifies a change-point, or returns a coupler
position with silent error, `mech` returns an exact rational, an exact surd with a certified sign,
or a certified interval — or an explicit refusal.

It is an analysis/synthesis tool for the planar four-bar specifically. It is not a general
multi-loop mechanism solver; six-bar and higher linkages are out of scope.

## Build

```
bash STDLIB/scripts/build_mech.sh        # iiis-2 compiles each organ, one archive link -> mech.exe
```
Composes existing III organs: `fourbar` (rational kinematics), `sqrt_sum_sign` (surd-sign
certificates), `sturm` (real-root isolation), `cyclotomic_se3` + `q23_sign` + `verb_geom` (the exact
ℚ(√2,√3) sign engine), `ui_raster`/`ui_present`/`ui_win` (rendering). Only libc/kernel32/user32/gdi32
at the OS boundary.

Link naming: `a` = input crank, `b` = coupler, `c` = output rocker, `d` = ground. All lengths are
positive integers.

## Modes

### `mech <a> <b> <c> <d>` — exact analysis
Grashof classification (exact integer decision: crank-rocker / drag-link / double-rocker /
non-Grashof / change-point), both dead-centre (toggle) output-angle cosines and the two
transmission-angle extremes as **exact reduced rationals**, the worst transmission angle chosen by
exact cross-multiplication, and the rocker swing-angle cosine as an **exact surd** with a certified
sign and real-angle certificates. Closure and reachability are exact integer/sign decisions.

```
$ mech 2 7 6 5
class: GRASHOF CRANK-ROCKER (the short side link fully rotates)
dead-centre (extended, e=a+b):  cos(phi) = -1/3   [reachable]
dead-centre (folded,  e=|b-a|): cos(phi) = 3/5    [reachable]
transmission extremes: cos(mu) = 19/21 and 3/7
  worst |cos(mu)| = 19/21   -> no lock (|cos(mu)| < 1) -- exact
rocker swing between dead-centres:
  cos(swing) = (-3 + 8*sqrt(2))/15   (exact surd)   sign certificate: 1
```
The exactness matters at a toggle: `mech 3 4 5 6` (a change-point) reports the folded dead-centre
cosine as **exactly 1** and the transmission extreme as **exactly |cos μ| = 1 → TOGGLE LOCK** — a
float kernel computes 0.99999998 there and cannot decide. Impossible loops are refused with the
integer reason (`mech 1 2 3 10` → "longest 10 > sum of others 6").

### `mech design <a> <b> <c> [lo hi]` — exact inverse design
Derives the exact ground length `d` giving a perpendicular extended dead-centre
(`d² = (a+b)² − c²`): Sturm-isolates the root in the window and prints the exact closed form.
```
$ mech design 2 7 6
condition: d^2 = (a+b)^2 - c^2 = 45
Sturm-certified isolation: d in (6.7082, 6.7083]
exact: d = 3*sqrt(5)   (surd; s^2*r = 45 exactly)
```
Refuses impossible targets exactly (`mech design 2 3 9` → "no real ground exists (c ≥ a+b)").

### `mech sweep <a> <b> <c> <d>` — exact coupler sweep
The rocker joint B(θ) at the 24 crank angles θ = 15k° (the ζ₂₄ grid, where cos/sin live exactly in
ℚ(√2,√3)). B solves the circle pair |B−A|=b, |B−D|=c; its coordinates are roots of quadratics with
ℚ(√2,√3) coefficients. **No square root is taken symbolically** — each root is isolated by
bisection whose every probe is one exact `q23_sign` query, so the four-decimal intervals are
certified even though the roots generally live in degree-8 number fields. Per pose: reachability
(exact discriminant sign), both branch positions, and the transmission cosine as a certified
interval. Links 1..40 (keeps the discriminant certificates inside i64).

### `mech view <a> <b> <c> <d>` — render the cycle
Writes `mech_view.bmp` (800×600): the mechanism at every reachable pose (crank red, coupler green,
rocker blue) with both joint circuits traced. Every pixel comes from the same certified computation
as `sweep`.

### `mech show <a> <b> <c> <d> [frames]` — live window
A native window animating the mechanism through its reachable poses (ESC or `q` closes; optional
frame cap for unattended runs).

### `mech curve <a> <b> <c> <d> <un ud vn vd>` — certified coupler path
The path traced by a point fixed on the coupler link at parameter (u,v):
`P = A + u·(B−A) + v·perp(B−A)`, with `u = un/ud`, `v = vn/vd`. P is an affine combination of the
crank tip A (exact) and rocker joint B (certified interval), so each P coordinate is a **certified
interval** computed with outward integer rounding — guaranteed to contain the true point.
Anchors verified exact: `u=0` reproduces A, `u=1,v=0` reproduces B. Writes `mech_curve.bmp` (the
coupler curve over the faint mechanism). Links 1..40.

### `mech synth <d> <lim> <k1 x1n x1d y1n y1d> <k2 x2n x2d y2n y2d>` — exact path synthesis
Given a ground length, a search bound, and two precision points (rational (x,y) at ζ₂₄ crank angles
k1,k2) the coupler must pass through, searches every mechanism (a,b,c in 1..lim; u,v over a rational
grid) and reports each whose **certified coupler box contains both targets**. Containment is an
exact integer comparison on the certified interval — no floating-point tolerance; a real solution
is never pruned by a float, and every reported mechanism provably passes through the targets.
Coordinates may be negative. Reports the exact count searched (caps the shown list at 16 with an
explicit "(showing first N)").

```
$ mech synth 3 3  2 4836 10000 25866 10000  4 5101 10000 29873 10000
  SOLUTION: a=1 b=3 c=3 d=3  u=1/2 v=1/2
searched 270 candidates; 1 exact solution(s)
```
Verified by plant-and-recover: targets computed from a known mechanism are searched, and that
mechanism is recovered uniquely; a target perturbed off the real curve returns 0; a grid excluding
the answer returns 0.

### `mech gen <a> <b> <c> <d> <un ud vn vd>` — emit a coupler curve as a target file
Prints the mechanism's coupler curve as target lines `k xn 10000 yn 10000` (the certified box
midpoint per reachable ζ₂₄ pose) to stdout. Redirect to a file to build a target curve from a
prototype mechanism: `mech gen 1 3 3 3 1 2 1 2 > ref.curve`.

### `mech fit <d> <lim> <curve-file> <tn td>` — fit a WHOLE target curve
Reads a target curve (lines `k xn xd yn yd`, k a ζ₂₄ crank-angle index, target (xn/xd, yn/yd);
`#` comments allowed) and finds every mechanism (a,b,c in 1..lim; u,v grid; ground d) whose
certified coupler box is **L∞ within τ = tn/td** of the target at *every* sampled angle. The test is
exact and sound — the whole certified box must lie inside [target−τ, target+τ] (integer comparison,
no float), so a reported mechanism's true coupler point is guaranteed within τ of the entire target
curve. Timing is prescribed: each target point is tied to its crank angle, and a candidate that
cannot reach a target angle fails (it can't trace a point it can't reach).
```
$ mech gen 1 3 3 3 1 2 1 2 > ref.curve       # 24-point target
$ mech fit 3 3 ref.curve 5 10000
target curve: 24 points
  FIT: a=1 b=3 c=3 d=3  u=1/2 v=1/2
searched 270 candidates; 1 fit the whole curve within tol
```
Verified: gen→fit round-trip recovers the source mechanism uniquely; a tolerance below the certified
box half-width returns 0 (τ is load-bearing); a target point moved off the curve returns 0. A
whole-curve match is far more constraining than two points: matching all ~24 points is a strong
condition, so when the target is itself a mechanism's curve, the source is typically the *only* tight
fit (measured: over a 640-candidate grid at τ = 0.05, only the source mechanism fits its own curve).
Approximate synthesis — fitting a target whose exact mechanism is outside the grid — is supported,
but a *full* ζ₂₄ loop is a very demanding target: matching all 24 points simultaneously is so strong
that no ≤6-link mechanism fits a specific 7-link mechanism's whole curve even at τ = 0.3 (measured,
2160 candidates). Fewer target points is a strictly weaker constraint (the matches are a superset),
which is why the two-point `synth` mode finds solutions where a full curve does not; provide only the
`k` lines you care about and unlisted angles are unconstrained. Note that whether *distinct*
alternative mechanisms actually appear still depends on the target's geometry and τ — the target
points must be reachable by the grid's link lengths at all, and near-neighbours only surface once τ
exceeds the spread between candidate curves. The tool reports exactly what fits and, when nothing
does, says so. Runtime ≈ (curve points) × the per-candidate cost, with early-out on the first missed
angle.

## Guarantees and honest limits

- **Exact:** no floating point in any computation. Rationals are reduced; surds carry a certified
  sign; intervals are outward-rounded certified enclosures; decisions (Grashof, closure,
  reachability, toggle-lock) are exact integer/sign tests.
- **Envelopes:** analysis/design links 1..150; sweep/view/show/curve/synth links 1..40 (keeps every
  intermediate, including discriminant certificates, inside the i64 exact envelope). Out-of-envelope
  input is refused, never silently truncated.
- **synth cost:** an exhaustive exact search, so runtime scales with the grid. A fast path derives
  the rocker joint's x-coordinate from the exact radical line (verified to enclose the trusted
  twin-quadratic result); it applies per-pose where the crank tip is not directly above the ground
  pivot (`d − Ax ≠ 0`, the common crank-rocker geometry), and falls back to the trusted slow path
  otherwise. A ~270-candidate search runs in ~1.3 s; a wide search spanning many reachable
  candidates is a longer — but always correct — run. The fast path's coupler box is a ~4×10⁻⁴
  certified enclosure (vs ~10⁻⁴ for the slow path): still exact, a slightly coarser match tolerance.
- **Scope:** planar four-bar only; single coupler point; ζ₂₄ (15°) crank-angle grid. Curved-input
  and multi-loop mechanisms are not modelled.

## Exit codes
`0` report/render written (including honest refusals) · `2` usage error · `3` out of envelope.
