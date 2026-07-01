# III — Exact-Sign Substrate: readiness, the weld, and the path to load-bearing

**Question answered:** are the TOOLS-QUOTIENT + aether exact-geometry modules cumulatively ready
to *improve* III; if not, what finishing touches, in what order; and how to integrate them so III
is unified, redundancy is eliminated, new theorems are born, and a leaner/more-capable III emerges.

**Method:** `/deep-think` battery + `iii_math_rigor` / `iii_adversarial_verify` conscience + live
verification against the WIP tree (not the docs). Every claim below is tagged `[VERIFIED]`
(checked this session), `[GATED]` (existing green KAT), `[BUILD]` (specified, not yet built), or
`[OPEN]`.

---

## EXECUTION RECORD (2026-07-01, same day as the verdict) — T2 + T1 LANDED

- **T2 THE WELD — LANDED, gate `2159_kf_weld` GREEN.**  `kfield.iii` + `exact_surd_value.iii` relocated to
  `STDLIB/iii/aether/` (nm-audited: defined-global ∩ every co-linked organ and `libiii_native.a` = ∅).  `kf_embed`
  built exactly as specified (𝔽₂ xor-basis on prime-parity vectors WITH provenance — `{√6,√10,√15}` embeds rank-2
  with the w=2 scaling; rank>3 ⇒ FAIL); per-op i64 magnitude guard (`kfg_mul/add/sub`, sticky `KF_OVF`) threaded
  through `kf_mul`/`kf_sign_rec`/`kf_point_addr`; `kf_multiquadratic_sign` = embed + guarded tower, ABSTAINS (2) on
  rank/envelope/self-distrust (tower-0 on a provably-nonzero vector is refused).  Wired into `sqrtsum_lazy3` after
  Tier-2 canon, before the bigint tiers.  Gate evidence: the 19/39 overflow family → **39/39 abstains, 0 wrong**;
  four Pell/CF near-ties (√2 665857/470832, √3 262087/151316, √6 470449/192060) **decided by the tower in pure i64**
  (`lazy_kf_count == 4`) where the shipped ladder escalated to bigint; rank-4 {2,3,5,7} abstain→adaptive fallback
  exercised; exact zeros 0 everywhere.  All four owner gates green: sqrtsum **28/0**, ripple **9/0**, lens **2/0**,
  bigcov **7/0**.
- **The eidos consumer rerouted:** `ripple_eidolon.re_cmp` now calls `sqrtsum_lazy3` (was: always the raw
  separation-bound oracle) — same answers by the differential gate, most edges now resolve at Tier 1 or in pure i64.
- **The quotient kit's own gates landed:** `2148_theorem_fuzzer` + `2149_universal_block` relocated into
  `STDLIB/corpus/` and registered in `run_sqrtsum_kats.sh` — the kit is no longer delete-to-undo staging.
- **New theorem GATED (was "born by T2"):** *on the bounded-rank multiquadratic domain, the Galois-tower sign ≡ the
  separation-bound sign* — `2159`'s differential arms are its teeth; mutating either engine reddens the gate.
- **T1 SEAL — LANDED with one adjudication.**  The T1 text below says "add the aether family to `build_stdlib.sh`
  MODULES"; execution REFUTED that mechanism against the live tree: (i) the coverage ratchet (`cov_gate_driver`,
  pins 5/2/14) walks `STDLIB/iii` + `STDLIB/corpus` regardless of MODULES, and the archive is the *coverage-gated
  core lib* — III's own convention (III-GLASS UI, unified-field, topo, `xii_proof`) keeps gate-owned organ families
  OUT of it ("Delegate, do not phantom-FAIL"); (ii) `run_corpus.sh`'s own text warns that adding gate-owned modules
  "would WORSEN the down-only coverage ratchets."  Landed instead by the algnum precedent: corpus skip-list
  delegation (`2148/2149/2155/2158/2159` registered), **sources reseal 791 modules `--verify` BIT-IDENTICAL**, and
  the whole family committed.  Census (committed reports): uncovered 75 / gate 10 / reach 157 — ALL inherited WIP
  debt (au_*/et_*/xii_proof_*/UI-cubics/lens-app exports; the weld organs contribute **zero**; `csg_union/intersect`
  covered this session in `2150`).  The burn-down remains the coverage-ledger campaign's, unchanged by this landing.
- **T3.a THE ONE-KERNEL RECONCILIATION — LANDED.**  `ui_bsign1`/`ui_sign_bi_big` (i64-coeff 1–2-surd iterated
  squaring) and `ui_bigsign2` (bigint-coeff 2-surd) MOVED into `sqrt_sum_sign.iii` as the ladder's Tier 0;
  `ui_exact_bigsign.iii` DELETED; `ui_exact_big.iii` keeps only the coverage engine and consumes the kernel.
  `sqrtsum_lazy3` gained the low-surd SHAPE rung (any raw ≤2-surd query — any radicand magnitude, and any
  coefficient magnitude via the bad-screen path — decides by exact O(1) squaring; `lazy_biq_count`, gate 2159
  ARM 7), and `sqrtsum_adaptive_sign_big` gained the 2-class O(1) fast path.  ONE kernel, six ordered rungs:
  interval → canon → kfield tower → bi-quadratic squaring → adaptive → separation bound.  Consumers repointed
  at the symbol level (`ui_exact_bigcov`, `field_full`, `ui_exact_sym`); gates 28/0 · 7/0 · 9/0 · 2/0; reseal
  790 BIT-IDENTICAL.
- **T3.b THE CONSUMER PROMOTION — LANDED (gate 2152 arm QUOTIENT).**  `q23_sign` (the ℚ(√2,√3) bridge under
  the zero-drift mechanism and the collision organ) now routes through `verb_geom`'s e-class sign cache
  (`vg_sign`) — verb_geom stops being a 2125-only demo.  Executed evidence `Q: 24 0 24`: sweeping the
  24-periodic orbit touches the exact-sign wall once per DISTINCT configuration; the second full revolution
  generates ZERO new wall touches (24/24 class hits) — the symmetry-quotient thesis (2138) live at a real
  consumer, and IDENTIFY⟺DECIDE operating as a rule (same e-class ⟺ kernel-certified equal), exactly the
  promotion §3 called for.  Answers identical (vg_sign falls through to the ladder; unpackable values skip
  the cache).  2153 (collision) re-proved through the promoted route.

## 0. Verdict in one line

**The exact-sign SPINE is already shipped and load-bearing; the new FACES + the weld are the
increment.** The kernel `sqrt_sum_sign.iii` is already part of III and already consumed by a live,
gated, non-demo organ — `eidos/ripple_eidolon` (the exact real-order verb of the eidolon ripple:
`ui_sqrt_sum_sign(eidB−eidA) → {BELOW,REFLECT} → omnia/involution`, gated by `run_ripple_kats` /
`2133`). What is *not* yet landed: the new geometry FACE family (csg/sturm/delaunay/collide/routing/
kinematics/algnum/aether_lens — untracked, gated `25/0`, but only self-consumed by their KATs); the
kfield weld; and — the deeper redundancy — the fact that III runs **two parallel LIVE exact-sign
kernels** (`sqrt_sum_sign` general n-surd **and** `ui_exact_big`/`ui_exact_bigsign` specialized
1–2-surd, the latter carrying the UI/coverage path). So "ready to *improve* III": the kernel already
does; the faces + weld + kernel-reconciliation are three ordered finishing touches, of which the
weld is the safe, high-value prize.

---

## 1. Verified state (live tree, this session)

1. `[VERIFIED]` **Gated green NOW.** `run_sqrtsum_kats.sh` → `PASS=25 FAIL=0` (exit 0) on the WIP
   tree — 2120–2157, incl. the `algnum` capstone (`Z: 0 0 0`), the `aether_lens` sphere render,
   `sturm`, `delaunay`, `csg_kernel`, `collide`, `photon_route`, `cyclotomic_se3`. The readiness
   premise is real, not stale-doc.
2. `[VERIFIED]` **Internally unified on ONE kernel.** Every face `extern … from
   "sqrt_sum_sign.iii"` (the actual call graph): `csg_kernel · delaunay · algnum · aether_lens ·
   q23_sign · verb_geom → sqrtsum_lazy3`; `collide → cyclotomic_se3(q23_mul)+q23_sign`;
   `photon_route → traj_kinematics`; `algnum → sturm + sqrtsum`. This is not marketing — "seven
   faces, one substrate" is the extern DAG.
3. `[VERIFIED]` **Outside the seal.** All aether files are untracked (`git ??`); TOOLS-QUOTIENT's
   own README: *"nothing here is wired into build_stdlib.sh, run_corpus.sh, or the seal — delete
   this folder to undo, with zero effect on the system."* By III's own definition, they are **not
   part of III** — a staging area.
4. `[VERIFIED]` **kfield is severed.** `kf_sign / kf_embed / multiquadratic` appear nowhere in
   STDLIB except a comment in `cyclotomic_se3.iii` and the `run_corpus` skip-list. The weld
   (`kf_embed` + dispatcher) is **not built**.
5. `[VERIFIED]` **The compiler bridge is a mirage.** `verb_geom` exports `vg_eclass / vg_sign` — an
   exact-value e-class substrate — but a caller grep finds **nothing live** consumes them (the
   `vg_` hits in `world_graph`/`sqrt_sum_sign` are substring false-positives). Worse: `verb_geom`
   consumes `STDLIB/iii/numera/egraph.iii`, while the **live compiler** `COMPILER/BOOT/cg_r3.iii`
   consumes a **different** e-graph — `ser_egraph.iii` (`seg_mul_plan`/`seg_div_plan`, the certified
   integer strength-reduction e-graph). **verb_geom is not attached to the compiler's e-graph at
   all.** The "improve III's optimizer" story is false as stated.
6. `[VERIFIED]` **Two parallel LIVE sign kernels — the real redundancy.** Sign-of-Σ√ is
   implemented independently in two shipped kernels, each with live consumers:
   - `sqrt_sum_sign.iii` (general n-surd, tiered) — live consumer `eidos/ripple_eidolon` +
     the aether faces.
   - `ui_exact_big.iii` (`ui_bsign1` 1-surd, `ui_sign_bi_big` 2-surd) + `ui_exact_bigsign.iii`
     (`ui_bigsign2` 2-surd bigint) — live consumers `field_full`, `ui_exact_bigcov`,
     `ui_exact_sym`, `ui_curve_render` (the UI/coverage path).
   Plus `kfield::kf_sign` (bounded-rank multiquadratic, **severed**) and `sturm`'s integer-PRS sign.
   The low-surd specializations are individually *optimal* (2-surd iterated squaring is O(1), no
   sep-bound) — but they are a **separate file/kernel** from the general engine, so the same
   predicate has two parallel homes. THIS is the redundancy the user's "eliminate redundancy" goal
   targets: not "delete a signer," but "the two live kernels should be one tiered ladder with the
   1–2-surd signers as its fast tiers."
7. `[VERIFIED]` **The kernel's live foothold (fixes the headline).** `ripple_eidolon.iii:39`
   *calls* `ui_sqrt_sum_sign((&RE_AC),(&RE_BC),n)` — not a dead extern — as the exact real-order
   verb of the eidolon ripple (`sign(eidB−eidA)` → `{BELOW,REFLECT}` → `omnia/involution`), gated by
   `run_ripple_kats` / `2133_ripple_eidolon`. So the exact-sign spine is *already* improving III in a
   core substrate (eidos); the weld's benefit is therefore realizable at an **existing** gated
   consumer, not hypothetical.

**Consequence.** "Cumulatively ready to improve III" decomposes into three truths with three
different answers: *proven* (yes, `25/0`), *spine load-bearing* (**yes** — eidos), *new faces landed
& the two live kernels reconciled* (no). The user's goals (unified / leaner / more-capable /
new-theorems) live in the third — and the weld (T2) is where they concentrate.

---

## 2. The three finishing touches, in dependency order

`T0` (evidence, **DONE**): confirm the gate is green on the WIP tree → `25/0`. ✅

### T2 — THE WELD (do this FIRST: highest value, self-gating, no seal risk)  `[BUILD]`
Collapse the two *general* sign engines into one ordered ladder inside `sqrt_sum_sign.iii`:

```
Tier 1  i64 interval            [GATED]  hardware speed, non-straddle
Tier 2  radical canon           [GATED]  structural zero / single surd
Tier 2.5 adaptive precision     [GATED]  per-instance log(1/|E|), not M^(2^n-1)
Tier 3  MULTIQUADRATIC TOWER     [BUILD]  bounded-rank exact sign, NO separation bound  ← kf_sign
Tier 4  separation-bound (oracle)[GATED]  arbitrary n, last resort, exponential
```

Why first: it needs **no seal change** (the disjoint gate compiles organs directly via `iiis-2
--compile-only`), it is **self-gating** (the oracle `ui_sqrt_sum_sign` is ground truth), it
**eliminates the island redundancy**, and it hands all seven faces the cheaper bounded-rank tier
for free (they extern the kernel — no per-face edit). This is the Pareto move.

Exact Phase-1 spec (the "how exactly"):
- **Relocate** `kfield.iii` + `exact_surd_value.iii` → `STDLIB/iii/aether/` (keep organs *pure* —
  the iii `var`=global-symbol trap collides across modules; verify co-compilation is clean).
- **`kf_embed(a[], b[], n) → field-vector | FAIL`** = 𝔽₂ linear algebra, **not** distinct-radicand
  counting (`{√6,√10,√15}` is rank-2, not 3: `√6·√10 = 2√15`). Squarefree-collect → prime-exponent
  parity vectors over 𝔽₂ → Gaussian-eliminate → rank `r`. `r>3` ⇒ FAIL (escalate to Tier 4).
  Choose `r` generators, express each `dⱼ` as a generator subset (mask), scale by `lcm(tⱼ)`
  (positive ⇒ sign-preserving) to clear the integer factors. Return the integer 8-vector.
- **Magnitude guard.** `kf_sign` squares through the tower (`p²−q²R` per level), coeffs grow
  `~c^(2^r)·R^(2^r−1)`; raw i64 is **silently wrong out of envelope** (documented 19/39 falsifier).
  Guard every intermediate against i64; out-of-envelope ⇒ fall to Tier 4. (Bigint kfield = Phase 2,
  removes the guard — deferred.)
- **Differential gate** (`optimizer-must-match-replaced-path`): one adversarial corpus through the
  new dispatcher **and** `ui_sqrt_sum_sign`; identical wherever the dispatcher does not abstain, and
  it must **not** abstain on in-envelope bounded-rank cases (`prove-positive-arms`). Corpus MUST
  include: the 19/39 overflow set (regression), exact zeros float cancels, the rank-collapse
  `{√6,√10,√15}`. Add as `2159_kf_weld` to `run_sqrtsum_kats.sh`.

### T1 — LAND INTO THE SEAL (makes it "part of III")  `[BUILD]`
Add the aether family + relocated `kfield`/`exact_surd_value` to the `MODULES` array in
`build_stdlib.sh`; commit the untracked organs; keep the disjoint gate but register it in the
corpus skip-list convention; **reseal with `--verify` BIT-IDENTICAL** (the `algnum` doc already
demonstrates 784 modules bit-identical — the determinism bar). Necessary, high-blast-radius
(touches `SEAL.mhash`), low-intellectual-leverage. Do it *after* T2 so the thing you seal is
already the unified ladder, not two islands.

### T3 — MAKE IT LOAD-BEARING (the real "improve III"; honest + hard)  `[BUILD]/[OPEN]`
The substrate improves III only when a **live consumer's behavior changes and is gated.** The
honest target is **not** `cg_r3` — its e-graph is integer strength-reduction; exact Σ√ geometry has
no role there. The honest targets are the organs that already do exact geometry/UI/physics:
`ui_field · ui_exact · color3_quant` (Schrödinger colour-geometry) · the physics thread (2266–78) ·
`world_graph` / `aether_world`. Pick **one** and route its coincidence/orientation/ordering
decision through the unified kernel, replacing an ad-hoc or float path; prove the answer changes on
a float-blind witness; gate it. Candidate with least friction: promote `verb_geom`'s
`vg_eclass`/`vg_sign` from demo to the equality oracle of a real geometry consumer — the moment
something live calls it, the IDENTIFY⟺DECIDE law (below) becomes a rule, not a KAT.

---

## 3. New theorems (honest: two promoted, one genuinely new)

- **Promoted to load-bearing (T3):** the **IDENTIFY⟺DECIDE law** (`2149` FACE 3):
  `kf_point_addr(P)==kf_point_addr(Q) ⟺ kf_sign(Px−Qx)==0 ∧ kf_sign(Py−Qy)==0` (common denominator;
  numerator compare). Today a KAT in isolation; T3 makes it the **rule by which a live consumer
  merges/decides coincidence**. "The Eidolon coincides" and "the exact sign of the difference is
  zero" are one predicate — that identity stops being demonstrated and starts being *used*.
- **Already gated, generalizes on landing:** the `algnum` **UNIFY** theorem (`2157`): Sturm-sign ≡
  Σ√ separation-bound sign over a rational fan — two mathematically independent exact faculties
  certifying one cut (`U: 1 -1 1 -1 -1 0`; MUT2 → exit 40 proves non-tautology).
- **Genuinely new, born by T2:** **on the bounded-rank multiquadratic domain, the Galois-tower sign
  ≡ the separation-bound sign.** The weld's differential gate *is* this theorem's teeth — mutating
  either engine reddens it. A third independent exact-sign faculty joins the agreement web.

---

## 4. Unified / leaner (honest framing)

- **Unified:** one kernel `sqrt_sum_sign.iii` with a four-tier ladder; every face and every future
  consumer routes exact-sign, exact-equality, and exact-order through it. `kfield`'s four verbs
  (CONSTRUCT/IDENTIFY/DECIDE/QUOTIENT) become the field-arithmetic front-end of that one kernel.
- **Leaner — precisely:** *not* "delete an engine." The concrete redundancy target is the **two
  parallel live kernels** (§1.6): fold `ui_exact_big`'s `ui_bsign1`/`ui_sign_bi_big` and
  `ui_exact_bigsign`'s `ui_bigsign2` into the one ladder **as its fast Tier-0/Tier-1** (they are
  *optimal* for n≤2 — iterated squaring, O(1) — so they become the ladder's low-surd fast path, not
  a separate file), and add `kf_sign` as Tier-3. Result: one kernel, four ordered tiers, every live
  consumer (eidos ripple, UI/coverage, aether faces, future callers) on it. Already-cut redundancy
  (regression-guarded): the p-adic sieve is proven unsound/redundant (`2139`); the dead
  `ui_sqrt_sum_sign_big` extern was removed. NB reconciling the two live kernels touches **shipped**
  UI code — higher risk than the weld — so sequence it *after* T2 (weld) proves the ladder against
  the oracle.

---

## 5. Kill-switches / honest limits (the corrections the battery forced)

- **Soundness lock (non-negotiable):** never wire `kf_sign` without the magnitude guard + the
  differential oracle gate incl. the 19/39 regression set. A silently-wrong exact sign is the worst
  possible outcome — it destroys the one property the whole substrate sells.
- **The optimizer payoff was a mirage** (`§1.5`): `verb_geom` ↔ `numera/egraph.iii` is a *different*
  e-graph than `cg_r3` ↔ `ser_egraph.iii`. Do not claim "faster compiler." Claim "exact geometry/UI
  organ, made load-bearing," which T3 must earn against a real consumer.
- **Bounded-rank is the design, not universal:** the win is real *where coordinates live in a fixed
  small field* (the aether faces are built in ℚ(√2,√3) etc. on purpose). Arbitrary-radicand inputs
  fall to Tier 4 — as designed. Scope is "bounded-rank faces," not "all of III."
- **Not solved:** PosSLP (worst-case exponential rank), transcendental zero-testing (Richardson),
  general degree-16 6R IK. All remain honestly `[OPEN]`; the tristate `UNKNOWN` path stays.

---

## 6. Recommended first action

**Relocation risk already retired this session:** `kfield.o` (21 defined globals) ∩ `sqrt_sum_sign.o`
(29) = **∅** — co-link is clean at the linker level (the precise test for the `var`=global-symbol
trap), and both organs compile on the current compiler (`rc=0`). So the concrete first build is not
a probe but the bridge itself:

1. Copy `kfield.iii` + `exact_surd_value.iii` → `STDLIB/iii/aether/`; re-run `run_sqrtsum_kats.sh`,
   expect `25/0` (behavior-preserving relocation).
2. Build **`kf_embed`** (𝔽₂-rank, §T2) + the magnitude guard + `kf_multiquadratic_sign` as Tier-3 of
   `sqrt_sum_sign.iii`.
3. Gate `2159_kf_weld` differentially against `ui_sqrt_sum_sign` — corpus MUST carry the 19/39
   overflow regression, the exact-zero-float-cancels set, and the rank-collapse `{√6,√10,√15}`.
4. Prove the benefit at the **existing** live consumer: re-gate `2133_ripple_eidolon` with the
   dispatcher active — same answers, kernel now decides bounded-rank cases without the sep-bound.

That is the whole safe, self-gating increment; T1 (seal) and the two-kernel reconciliation follow.
