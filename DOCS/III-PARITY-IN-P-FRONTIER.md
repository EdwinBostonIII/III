# III — "Parity Games in P? / full μ-calculus in P?" — Frontier Map

Status: **OPEN** (humanity-open; pre-registered B3 in the grail ledger). This file is the honest research
frontier of III's relentless attack on it — not a claim of resolution. Parity-game winner determination is
polynomial-time-equivalent to full modal μ-calculus model-checking; both sit in UP∩coUP; the SOTA is
quasi-polynomial (Calude et al. 2017), and a **proven** quasi-polynomial lower bound (Czerwiński–Daviaud–
Fijalkow–Jurdziński–Lazić–Parys, SODA 2019) blocks the entire universal-tree / separating-automaton family.

## Instruments built in III (all gated KATs, all validated)

| Artifact | What it is | KAT | Status |
|---|---|---|---|
| Zielonka solver | exact recursive parity solver (= full μ-calculus, 2nd algorithm beside 1838 nested-fixpoint) | 1839 | the **ground-truth oracle** |
| full μ-calculus | nested-fixpoint νX.μY.(…) decided; alternation proven necessary | 1838 | complete |
| greedy SI | region-size strategy improvement | 1840 | **incomplete** 77/80 (local optima) |
| **VJ SI** | Vöge–Jurdziński play-profile SI at vertex granularity + Odd best response | 1841 | **complete 80/80**, terminating (50k-game stress), ≤9 rounds random / ≤12 hill-climb-hard |
| **LRC-VJ** | single-switch SI, Cunningham least-recently-considered pivot (reuses 1841 valuation) | 1842 | complete 80/80, ≤18 single-switches (~21k games) |
| **SPM** | Jurdziński Small Progress Measures (lifting fixpoint; mixed-radix integer encoding) | 1843 | complete; **ZERO mismatches over ~28.8k games** vs oracle |

**Four solver families now in III, mutually cross-validated:** attractor-decomposition (Zielonka 1839), nested-fixpoint/μ-calculus (1838), strategy-improvement (VJ 1841 / LRC 1842), progress-measures (SPM 1843). Three independent algorithms agreeing on ~29k games is strong evidence the oracle and all three are correct.

**Cross-family complexity contrast (empirical, III's own random games):**
- SI iteration stays **flat**: VJ ≤12 rounds (n≤20), LRC ≤18 single-switches (n≤16).
- SPM lift count grows **super-linearly**: 26→82→213 (n=4→8), then ~208→432→672→992→**3552** (n=8→16) — ~17× while n doubles.
- So the progress-measure family *reaches* its high cost on ordinary instances (consistent with its n^{d/2} / universal-tree-barrier character), while strategy-improvement does **not** — empirical evidence (on III's games) that SI sits outside the barrier'd regime, exactly the workflow's intuition. Neither bears on P: SI is flat because random instances are easy; SPM's blowup is the *known* lower-bound family being reachable.
- **Decision stabilizes faster than strategy:** VJ-SI winner-region accuracy vs round cap = 58% (0 rounds) → 87% (1) → 98% (2) → 99.6% (3) → 100% (full) — the winner is decided in a handful of rounds though full strategy convergence takes longer.
- **Apparatus validated:** a CHAIN(k) family forces LRC to ~k switches (11 at k=12, monotone) — so the flat plateaus are random-instance easiness, not a blind counter.

Honest negative results en route (each genuine, each a ruled-out approach):
- two poly winner-predictors **refuted** by the oracle: max-reachable-priority 223/400 wrong, recurrent-cycle-priority 168/400 wrong — both ignore CONTROL (who picks the cycle).
- greedy SI has **local optima** (77/80) — region size discards the play profile.
- a first VJ cut collapsed the vertex-set to a priority-set → **non-termination** on repeated-priority games (found via the step-count probe; the "124" was timeout's kill code, not data). Fixed to vertex granularity.
- mean-payoff value-iteration SI failed 21/80 — exponential-magnitude weights, pseudo-poly iteration.

Empirical worst-case probe: a 120-restart × 260-mutation hill-climb maximizing VJ-SI rounds tops out at **~12 rounds for n up to 20** — local search does not find SI-hard instances (expected: Friedmann's families are precise binary-counter constructions, measure-zero under local mutation). **NOT** evidence of poly — only that random/local search misses the adversarial families. The decisive instrument still missing: a **Friedmann-style exponential SI lower-bound generator** (the named gap).

## The 38-agent adversarial candidate hunt (workflow parity-poly-hunt)

31 candidate poly-algorithms generated across 6 families; **11 KILLED** (cited theorem or explicit counterexample), **20 genuine-open survivors**. Every survivor's best outcome is a **conjecture to prove**, never "P solved".

### Killed (with the kill)
- **Schewe optimal-combination SI** — Friedmann 2011 exp lower bound targets this exact rule.
- **QPM-SI / RegisterIndex (Lehtinen) / memoized universal-tree decomposition / truncated SPM / SymmetricTwoSidedPruning / CYCLE-HOMOLOGY** — all separating-automaton/universal-tree objects → CDFJLP 2019 quasi-poly floor.
- **SmallProgressMeasures variants** — Jurdziński 2000 n^{d/2} codomain.
- **TPAD (top-priority attractor)** — explicit 2-vertex counterexample: returns the wrong winner on the priority-d vertex.
- **psolB fatal-attractor partial solver** — Huth–Kuo–Piterman / van Dijk: non-fatal tangles leave a residual; sound but incomplete.
- **fixed-k bounded-dominion detection** — explicit 4-cycle counterexample; minimal-dominion-size lower bound; k=n costs n^n.
- **Büchi/coBüchi priority-collapse** — explicit alternating self-loop family mislabels for every constant collapse depth.

### Survivors (genuine-open; the test queue, by priority)
9. **C1-TL** tangle learning + distinct-tangle potential — outside universal-tree regime; decisive probe = distinct-tangle count growth on van Dijk/Friedmann families.
9. **SSI** symmetric (primal–dual) strategy improvement (Schewe–Trivedi–Varghese) — two-sided coupling; no published exp LB transfers; sound by STV.
8. **C4-SI** tangle-guided symmetric SI · **FCS** Fearnley snare-closure (dual cheap kill: under-reporting or snare-chain blowup).
7. **LRC-VJ** single-switch VJ SI, Cunningham least-recently-considered pivot — no named LB transfers; sound (monotone). ← **building now (reuses validated 1841 valuation)**
6. **TRIPLE** composite SSI∘snare∘optimal · **DISCOUNT-HOMOTOPY** central-path to λ→1 · **TROPICAL-SPECTRAL** Howard PI in a lexicographic indicator semiring · **TWO-SIDED-GAP** spectral deflation.
5. **SOS** bounded-degree Lasserre certificate (off both horns; cost = unproven SOS degree) · **C2-PP** delayed-promotion priority promotion · **BTW** bounded tangle (sound partial-solver coverage floor).
4. **ENERGY-DISJ** big-M energy LP · **NMRL** credit-bounded non-monotone lift.
3–2. **ENERGY-VARWEIGHT** per-game weights · **ADAPTIVE-SPM** (= SPM-per-instance, widely believed false) · **DOMINION-PIT** (P_v undefined) · **C5-WIDTH** (bounded-width, known-true theorem).

### The meta-conclusion (honest)
A single invariant / poly algorithm across all parity games is not in hand and the priors say each survivor will blow up on the right adversarial family. The attack continues: build each survivor, validate correctness against the oracle (mismatch = bug), measure the load-bearing quantity, and — the critical-path instrument — a Friedmann-style hard-family generator to make the complexity probes decisive.
