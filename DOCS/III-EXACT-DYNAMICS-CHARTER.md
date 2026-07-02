# III — EXACT DYNAMICS CHARTER: the five-phase program, adjudicated before construction

**Input:** the five-phase proposal (time-symmetric dynamics · e-graph kinematic cache · exact constraint
resolution · infinite periodic ray-marching · algebraic CSG DAG) on top of the landed exact-sign substrate
(III-EXACT-SUBSTRATE-INTEGRATION, executed 2026-07-01: six-rung ladder, kfield Galois tower, verb_geom
e-class cache live at q23_sign).

**Method:** every phase claim went through `iii_adversarial_verify` BEFORE any construction — the same
discipline that caught the 19/39 overflow falsifier and the 2^38 perfect-square gestate case.  Verdicts
below are binding; `[LANDED …]` tags are appended as phases execute.

---

## Phase 1 — Time-symmetric, zero-dissipation dynamics

**Claim as stated:** multi-body elastic collisions in a mirrored QUADRIC chamber, millions of steps,
bit-exact reversal, via cyclotomic time-steps and quadric-gradient normals.

**VERDICT: REFUTED AS STATED — repaired core SURVIVES (high) and is buildable now.**

- ATTACK 1 (the unstated hypothesis): *"the state stays in a bounded-rank field."*  FALSE for curved
  boundaries and for ball–ball contacts: the contact time solves a QUADRATIC whose coefficients lie in the
  current field, so the position at the event acquires a NEW √Δ — one quadratic extension PER EVENT.
  After k events the state has algebraic degree up to 2^k: the i64 tower dies at rank 3, bigint towers at
  ~30 events, and "millions of steps" is unreachable by ANY exact representation of the naive state.
  This is the same SOSR/tower wall the substrate documents (III-SOSR-BARRIER-ANATOMY) — the proposal's
  quadric-chamber wording walks straight into it.
- THE CONSTRAINT THAT ACTUALLY BREAKS (creative-solve): *"collision events must inject √Δ into the
  state"* is an INHERITED assumption from curved boundaries.  For PLANAR walls the event map is
  FIELD-RATIONAL end to end: t* = (c − p·n)/(v·n) is degree-1 (a ratio, no root), and the reflection
  v' = v − 2((v·n)/(n·n))·n is rational in field elements — the √ never enters.  A polyhedral chamber with
  cyclotomic wall normals (15° facets from ℚ(√2,√3)) keeps the ENTIRE infinite orbit inside ℚ(√2,√3):
  rank 2 forever, exactly the kfield/kf tower domain.  The only load-bearing exact decisions are the
  event-ORDER comparisons (which wall first?) — flat Σ√ signs, i.e. the ladder — and those are precisely
  what verb_geom's e-class cache memoizes on periodic orbits (Phase 2 fuses in for free).
- ATTACK 2 (edges): simultaneous events (corner/edge hits) are EXACT TIES — the kernel CERTIFIES them
  (float engines cannot even detect them); v1 flags them honestly rather than composing reflections.
  Tangent passes (v·n = 0) are exact no-events.  Leaving-wall re-hits are excluded by the EXACT test
  num == 0 — no epsilon hack, the zero-certificate replaces it.
- ATTACK 3 (degenerate pass): a reversal KAT on a trivially periodic axis-aligned orbit would be vacuous.
  Teeth required: an irrational-angle orbit crossing many distinct walls, a wall-sequence PALINDROME
  check, AND a fixed-point twin that visibly fails (wrong wall choice on a Pell near-tie with gap
  ~1.1e-12 < 2⁻³²).
- ATTACK 4 (call-site preconditions): comparisons must clear denominators SIGN-PRESERVINGLY (multiply by
  positive quantities only — enforce den > 0 canonically); every field op runs the GUARDED kfield
  arithmetic (KF_OVF ⇒ organ abstains, never silently wrong).
- HONEST COST (not a wall): even the field-rational orbit's coefficient BIT-SIZE grows ~linearly per
  event (the orbit's genuine information content).  i64 state ⇒ a few dozen guarded events; hundreds-to-
  thousands need bigint rationals (LINEAR bits, perfectly feasible — unlike the exponential tower).
  v is rescaled to its primitive integer field-vector each bounce (a time-reparametrization: orbit
  geometry and wall sequence invariant) so only p grows.
- SCOPE LADDER: v1 (this charter) = polyhedral ℚ(√2,√3) chamber, K non-interacting balls, guarded i64,
  bit-exact reversal + palindrome + near-tie witness.  v2 = bigint rational state (hundreds→thousands of
  events).  Ball–ball / quadric walls = bounded-rank only (≤3 stacked events in i64 kf; lazy nested-radical
  state with adaptive sign = research arc, sign-zero certification cost grows with tower height) — [OPEN],
  never claimed.
- Conservation honesty: wall reflections conserve SPEED per ball (|v|² invariant), not momentum (walls
  push).  With primitive-v rescaling the gated invariants are: bit-exact state return, direction reversal
  (primitive(v_end) == −primitive(v₀)), and the event palindrome.

## Phase 2 — E-graph kinematic cache

**VERDICT: SURVIVES (high), with two honesty locks.**  This is EXACT MEMOIZATION (content-addressed,
deterministic — NOT statistical learning; no counts, no promotion).  Already live since the T3.b promotion
(gate 2152 `Q: 24 0 24`).  Locks: (1) the cache helps only EXACTLY-REVISITED values — periodic/cyclotomic
motion revisits, generic continuous motion does not; "the longer it runs the faster it gets" holds on the
revisit fraction only; (2) capacity honesty — SIGNC is finite (16384 classes) and unpackable values skip
the cache: full/skip ⇒ recompute, never wrong.  Execution: fused into Phase 1 (the billiard's event-order
comparisons route via the packable-value cache path where applicable) rather than built as an island.

## Phase 3 — Exact constraint resolution

**VERDICT: SURVIVES for ONE degree of freedom; multi-dof REFUTED as an immediate build.**
sturm.iii is UNIVARIATE: any 1-dof constraint (a linkage driven by one parameter) reduces to an integer
polynomial in t — Sturm counts and isolates ALL valid configurations exactly; tangency/singularity = the
squarefree-part/double-root test, decided exactly where a Newton/Jacobian solver jitters.  algnum makes
the isolated roots first-class (order/equality decidable).  Multi-dof systems need elimination
(resultants) to reach univariate — a real but separate construction (degree growth must be costed) —
charter [BUILD-next], not claimed now.  Falsifier for the v1 organ: a linkage at an EXACT double-root
singularity — Sturm reports "exactly one configuration, tangent"; the float twin oscillates or reports 0/2.

## Phase 4 — Infinite periodic ray-marching (lens Mode B)

**VERDICT: SURVIVES (high).**  The Phase-1 insight applies verbatim: lattice CELL WALLS ARE PLANES, so
cell-to-cell traversal is field-rational with NO accumulation; the in-cell quadric hit uses √Δ PER QUERY
(discarded after the pixel — never enters persistent state), so there is no tower.  The exact boundary
sign kills the two float failure modes: tunneling through a grazed cell wall and boundary-loop trapping.
Falsifier: a grazing ray whose float-DDA step order differs from the exact traversal (mis-stepped cell ⇒
wrong hit/miss), rendered evidence à la 2158.  Composes photon_route (lattice logic) + aether_lens
(quadric hits) — no new math.

## Phase 5 — Algebraic Boolean operations tree

**VERDICT: SURVIVES (high) — the one phase with no hidden wall.**  Membership/ray-cast through a CSG tree
is a per-query composition of EXACT signs — depth composes booleans, not arithmetic, so the 1000th
operation is literally as precise as the 1st (nothing accumulates).  csg_kernel already holds the leaf
predicates and the union/intersect/difference combinators (gated 2150); what's missing is only the TREE
OBJECT (node arena, arbitrary depth, leaves = quadrics) and the deep-drill gate.  Boundary CURVES as
first-class parametrized objects (quadric∩quadric = degree-4 space curves) are a separate algnum/sturm
increment — [BUILD-next], not needed for exact membership/ray-cast/drilling.

---

## Execution order (leverage × dependency)

1. **P1 billiard v1** — the crown demonstration; consumes kfield + ladder + (via packable comparisons)
   the e-class cache; new theorem gated: *polyhedral cyclotomic billiards are exactly time-reversible on
   the III substrate, with event order decided by the certified ladder.*
2. **P5 csg_tree** — smallest build, closes the CSG-DAG claim with the depth-independence gate.
3. **P4 lens Mode B** — lattice traversal + tunneling witness + render.
4. **P3 constraint v1** — univariate Sturm resolver + singularity witness.
5. **P2** — measured inside P1/2152 (no island build).
v2 arcs ([BUILD-next]): bigint billiard state · resultant elimination · boundary-curve objects · bigint
kfield tower (III-QUOTIENT-WELD Phase 2, domain now narrow).

---

# PROGRAM II (same day): the five-phase scale-up, adjudicated

## II-I  Deep-time ergodic N-body gas — **LANDED (gas.iii, gate 2169)**
The proposal's key insight VERIFIED: polyhedral (Minkowski) collision ENVELOPES keep pair events
field-rational — the contact is on an AXIS face, and the equal-mass elastic response IS the swap of that
axis's integer velocity components.  ATTACK-1 catches (binding): (a) the model is the HARD-CUBE gas, a
legitimate statistical-mechanics model class, NOT hard spheres (sphere contacts inject √Δ per event — the
tower); no isotropy claims transfer.  (b) The billiard's primitive-v rescaling is FORBIDDEN with
interactions (particles share one clock) — solved by integer velocities (swaps/negations never leave ℤ³)
and ONE shared ensemble denominator (linear growth).  (c) "Observe Poincaré recurrence" is not claimable
(recurrence times are astronomical); the constructive content IS the measure-preserving reversal, gated.
Gated: energy Σv² and per-axis momentum as INTEGER IDENTITIES at every event; ensemble involution
R∘F⁷∘R∘F⁷ == id bit-exact; two-pairs-same-instant CERTIFIED tie refused.  v2: bigint ensemble
(thousands of events), Maxwell-Boltzmann statistics ON the hard-cube model.

## II-II  4D swept-volume manufacturing leaves — SURVIVES scoped
A swept-SPHERE (ball-nose) leaf along integer/cyclotomic segments = the parabola-minimum membership
predicate (collide.iii's swept form; pure guarded integer arithmetic for integer configurations) — a new
csg_tree leaf KIND, depth-independent like every other leaf.  Spinning-profile/toroidal tools and
5-axis rotational sweeps = [BUILD-next] (surfaces of revolution swept = degree > 2).  Falsifier: a
tangent-graze toolpath where a snapshot-sampled twin leaves phantom material.

## II-III  E-graph C-space compiler — SURVIVES with the discreteness lock
Exact collision states over the DISCRETE cyclotomic configuration lattice, memoized by e-class; exact
lattice search plans over it.  HONESTY LOCK: "algebraically proves no path" holds for the DISCRETIZED
C-space only — a continuous-path guarantee needs swept-volume edges (II-II provides them for translation
steps; rotational sweep certification = [OPEN]).  Composes cyclotomic_se3 + collide + csg_tree +
lattice_shortest_path + the eidolon keys.  [BUILD-next].

## II-IV  Infinite periodic lattice optics — SURVIVES for reflection/TIR; refraction REFUTED for deep chains
Cell-boundary traversal is field-rational (planes — the Program-I insight verbatim).  NEW attack finding:
REFRACTION (Snell) injects √(1−(n₁/n₂)²sin²θ) — a NEW radical PER refraction event — the tower again.
Honest scope: reflective/TIR lattices unlimited (mirrors, total-internal-reflection traps, bandgap
skeletons); TIR onset is DECIDED exactly (a sign); refracted rays are bounded-rank (≤3 stacked) or
per-query.  [BUILD-next on the P4 base.]

## II-V  Dynamic Delaunay / ALE fluids — REFUTED as fluids; SURVIVES as kinematic exact remeshing
"Vertices from the physics step" of a FLUID are not algebraic (ODE flows leave every fixed field).  The
sound core: vertices on FIELD-RATIONAL kinematic paths; the flip TIME is a root of the incircle
polynomial in t (degree ≤ 4 for linear motion) — Sturm-isolated (composes P3), the flip CERTIFIED at its
exact instant; the no-tangle theorem = orientation predicates never lie.  3D escalation (orient3d/
insphere3d dets over the ladder) = [BUILD-next].

Execution order: II-I landed; II-II next (smallest, composes collide into csg_tree); then P4/II-IV base,
P3 (+II-V flip times), II-III last (largest composition).

---

# PROGRAM III (same day): the unbounded-substrate vectors, adjudicated

## VI  Rotational arc-sweeps — **LANDED (arc_sweep.iii + cspace upgrade, gate 2175, commit b6fa1837)**
The Weierstrass substitution u = tan(theta/2) makes the 15-degree tip arc vs a sphere a DEGREE-4 INTEGER
polynomial; root_count == 0 on a covering u-interval is the continuous clearance certificate.  Discharged:
the theta=180 singularity (EXACT R(180) = diag(-1,-1,1) chart: every arc lands in |u| <= 1) and the
irrational tan(k*7.5deg) endpoints (machine-derived /1000 covers, +-2 padding -- conservative supersets).
LESSON WITH TEETH: sturm's homogenized evaluation overflows i64 at denominator 1e5 x degree 4 -- the /1000
covers are not a compromise but the exact envelope; an apparent "stricter plan" (12 vs 10) was THIS
overflow's artifact and was reverted when the fix landed.  C-space rotation edges: endpoint-only -> fully
certified.  Tangency-inside-arc refuses (touch vs cross needs multiplicity work -- [BUILD-next]).

## V  Trans-envelope thermodynamics — SURVIVES scoped; [BUILD-next] with the spec fixed
Poincare-recurrence observation and Landauer verification are STRIPPED (astronomical times; information
accounting not gate-able).  The honest core: velocities STAY small integers (swaps/negations never grow
them) -- only positions/GDEN migrate to bigint (rank-1 pairs over one bigint denominator); event-time
comparisons are ui_bigsign2 1-surd queries (already in the kernel); per-event SUB-ARENAS with only the
final state persisted (the adaptive_big recipe); the demon gate compares |v| in i64 unchanged.  Teeth:
a scenario the i64 gas REFUSES (GS_E_OVER) at event k, continued by the bigint ensemble to >= 3k events
with the energy identity and the reversal involution intact.

## VII  Resultant elimination (algebraic closure of +) — SURVIVES scoped; [BUILD-next] with the spec fixed
gamma = alpha + beta via Res_x(f(x), g(gamma - x)): evaluate the resultant at deg(f)*deg(g)+1 integer
gamma-points as INTEGER Bareiss determinants (fraction-free; i64-guarded, bigint when needed), then
Lagrange-interpolate the INTEGER coefficients.  Teeth: derive the classical minimal polynomial of
cbrt(2) + sqrt(3) (x^6 - 9x^4 - 4x^3 + 27x^2 - 36x - 23) COEFFICIENT-FOR-COEFFICIENT, then Sturm-isolate
and algnum-bracket its two real roots.  Product/inverse and B-Rep intersection curves compose after.

## VIII  Bounded-rank refraction — SURVIVES scoped; [BUILD-next] with the spec fixed
Refraction closes over a DESIGNED direction-class pair: index ratio n1/n2 = sqrt2 maps the 45-degree class
{(+-1,+-1)-scaled} to the 30-degree class {(+-sqrt3,+-1)-scaled} and back -- a finite exact class map, each
transition CERTIFIED by the kernel identity (n1 sin theta1)^2 == (n2 sin theta2)^2 with the sign; TIR onset
is an exact sign.  March state: rank-1 Q(sqrt3) positions (linear den growth, guarded), the billiard/gas
pattern.  Teeth: the exact slab (45 in -> 30 inside -> 45 out with the EXACT lateral shift in Q(sqrt3));
a beyond-critical arm certified TIR; the class-map identity certified, not assumed.

STATE AT CLOSE: sqrtsum gate 37/0; organs landed this program: arc_sweep (+ cspace rotation upgrade).
V, VII, VIII are fully specified above with falsifiers -- the next session builds them in that order.

## V, VII, VIII — **LANDED** (the Program III close)
- **V gas_big.iii + 2176 (44de723b):** the ceiling removed in MAGNITUDE (i64 refuses at 2^61; bigint
  continues, involution exact AS RATIONALS) and DEPTH (200 events > the i64 organ's own 128 log ceiling).
  Findings with teeth: the i64 ensemble denominator is largely SELF-LIMITING (event slot = v*c*GDEN, gcd
  reclaims; 128+ events at 2^55 -- the charter's growth estimate corrected); the GLOBAL 64-slot bigint
  handle table + ui_bigsign2's undropped internals masqueraded as certified ties (own-arena sign calls);
  a pair-face sign error (tn = sgnf*d0 - S*DEN on BOTH faces) was caught by prove-positive-arms.
- **VII resultant.iii + 2177 (b282f016):** Res_x(f(x), g(t-x)) by interpolated Bareiss determinants with
  exactness-asserted Cramer recovery; DERIVED the classical minimal polynomials of cbrt2+sqrt3 and
  sqrt2+sqrt3 coefficient-for-coefficient; the derived object composes back through sturm.  Roots are
  closed under + on the substrate.  Products/inverses + the bigint determinant = next increments.
- **VIII refract.iii + 2178:** the designed 45<->30 class pair under n^2 = 1|2: every Snell transition a
  CERTIFIED integer identity (residue 0), the slab theorem exact (exit parallel; lateral shift
  (300+100sqrt3)/3), the critical angle an EXACT certified zero, TIR a strict positive.  Refraction without
  the tower -- by making the material obey the algebra.

STATE AT PROGRAM III CLOSE: sqrtsum gate 40/0.  Organs 2167-2178 all landed.  Charted next: bigint
determinants, products/inverses, arc-tangency multiplicity, rational-direction march v2, ensemble
compaction, multi-interface photonic lattices on the refract class algebra.
