# The Parity Wall — A Formal Map

This is the formal crystallization of the "parity games in P? / full μ-calculus in P?" investigation: every
mechanism, barrier, and equivalence brought up to the limit, stated precisely, with a **proof-status tag** on each.
The discipline is calibrated honesty — nothing is claimed beyond what is established.

**Proof-status legend**
- **PROVEN (III)** — a finite constructive theorem with a complete oracle-verified witness in a gated KAT.
- **VERIFIED (III)** — a ∀-statement (a known theorem) machine-checked on *every* sampled instance + the abstract result cited.
- **CITED** — a published theorem stated but not reproven here (and not needed to be).
- **OBSTRUCTED** — a *proven* impossibility / boundary (a negative result).
- **OPEN** — genuinely unknown (the wall itself).

---

## §0. Objects

- A **parity game** is `G = (V, V₀, V₁, E, pr)` with `V = V₀ ⊎ V₁` (the ownership partition), `E ⊆ V×V` total
  (every vertex has a successor), and `pr : V → ℕ` (priorities). A play is an infinite path; its **winner** is the
  player whose parity equals `max{ pr(v) : v occurs infinitely often }` (Even = parity 0).
- `W₀(G), W₁(G)` are the winning regions. A **positional** (memoryless) strategy fixes one out-edge per owned vertex.
- The **priority-graph** of `G` is `(V, E, pr)` — everything *except* ownership.
- III's reference decision procedure is the recursive **Zielonka** solver (`STDLIB/corpus/1839`), cross-validated
  byte-for-byte against two independent families (VJ strategy improvement `1841`, small progress measures `1843`)
  on ~29k games (`1845`). It is the **oracle** every theorem below is checked against.

---

## §1. The two pillars (the foundation, PROVEN / VERIFIED in III)

**T0 — Determinacy.** *For every parity game, `W₀` and `W₁` partition `V`.* — **VERIFIED (III)**, KAT `1849`
(`W₀|W₁ = V`, `W₀&W₁ = ∅` on every sampled game) + CITED (positional determinacy ⇒ determinacy).
*Significance:* this is what makes "the winner" well-defined and parity a **decision** problem at all — the precondition
for even asking whether it is in P.

**T1 — Positional determinacy.** *There is a single positional Even strategy `σ*` with `Even(σ*) = W₀`* (and dually
for Odd). — **VERIFIED (III)**, KAT `1849` (some `σ` over all `2^k` achieves `Even(σ) = W₀` on every sampled game)
+ CITED (Emerson–Jutla 1991 / Mostowski 1991).
*Significance:* the hinge of every **constructive** attack here — strategy improvement (`1840/1841/1842`) searches the
finite positional space *because* of T1, and the Gröbner encoding (`1847`) is literally "Even wins r ⟺ ∃ positional σ
winning from r." Remove T1 and those are invalid.

**T1′ — Positional determinacy is PARITY-SPECIFIC.** *Positional determinacy is not a generic property of ω-regular
games; it is special to parity.* — **PROVEN (III)**, KAT `1856`. Witness: a one-player generalized-Büchi objective
`GF(a) ∧ GF(b)` on `c→{a,b}, a→c, b→c` — every *positional* strategy fixes `σ(c)`, so its play visits only one of
`a,b` infinitely often and **loses**; the *alternating memory* strategy visits both and **wins**. *Significance:* T1
is a structural *gift* of parity, not a free lunch — change the objective slightly and the finite-strategy-space
premise of every constructive attack evaporates. The constructive side of the wall rests specifically on parity's
positional determinacy.

**T2 — Control-Blindness Barrier (the keystone).** *No function of the priority-graph `(V,E,pr)` alone equals the
winning region.* — **PROVEN (III)**, KAT `1848`.
> *Witness.* `V={v,x,y}`, `pr=(0,1,2)`, `E={v→x, x→v, v→y, y→v}`. With `v∈V₀`: Even forces `v↔y` (max prio 2, even) ⇒
> `W₀ = {v,x,y}`. With `v∈V₁`: Odd forces `v↔x` (max prio 1, odd) ⇒ `W₀ = ∅`. Same `(V,E,pr)`; only the *owner* of `v`
> differs; `W₀` flips from all to none. ∎
*Significance:* this is the formal heart of the wall. It says **parity is irreducibly a function of CONTROL** (who
chooses at branching vertices), and it **refutes an entire class at one stroke** (see §4, Class I).

**T2′ — Control-blindness, quantitative (empirical).** *On this sample, a fixed control-free graph invariant's
per-vertex agreement with the true winner DECREASES monotonically with size.* — **EMPIRICAL (III)**, KAT `1852`: the
"max reachable-cycle priority" predictor scores **82% → 70% → 65%** (n=4→10→14), monotone decrease (one predictor,
three sizes, one seed). *Scope:* this shows a monotone *decrease*, **not** a proven limit of 1/2 (65% at n=14 could
asymptote above 50%). T2 carries the actual proof; T2′ is the accompanying empirical decay (consistent with — not a
reproduction of — the workflow referees' "signed zeta → ~50%" claim).

---

## §2. The constructive side (what III's solvers establish, VERIFIED in III)

- **Complete solvers, three families, agree.** Zielonka attractor decomposition (`1839`), Voge–Jurdziński strategy
  improvement (`1841`, with the corrected vertex-granularity valuation; LRC variant `1842`), Jurdziński small progress
  measures (`1843`) — pairwise identical on ~29k games (`1845`). **VERIFIED (III).** Three independent algorithms
  computing the same partition is the strongest available correctness evidence for the oracle.
- **Sound relaxation sandwich.** `R_A(G) ⊆ W₀(G) ⊆ R_E(G)`, where `R_E` = Even-controls-all winners and
  `R_A = V∖(Odd-controls-all winners)` (both one-player games, poly). — **VERIFIED (III)**, KAT `1846` (zero violations).
- **Sound bounded-dominion / combined partial solver.** Every decision provably correct; coverage 40→82% (width)
  but DECREASING with size (88→74%, n=8→16): the locally-certifiable fraction shrinks, the hard core scales with n.
  — **VERIFIED (III)**, KATs `1844/1846`.
- **Algebraic merge (Nullstellensatz over GF(3)).** "Even wins r ⟺ ∃σ, p(σ)=1" decided by III's own Gröbner engine
  (`numera/groebner`, KAT `638`); reduced basis `={1}` ⟺ infeasible ⟺ Even loses. Matches the oracle on every k≤2
  game. — **VERIFIED (III)**, KAT `1847`. *Binding limit:* III's 64-slot bigint handle table (not the variable cap),
  which corrupts Buchberger at k≥3 — so the certificate-**degree** growth (the interesting regime) is out of reach.

---

## §3. The cited barriers (the wall's two proven faces, CITED)

- **B1 — Universal-tree / separating-automaton lower bound.** Every `(n,d)`-universal tree has size `n^Ω(log d)`
  (quasi-polynomial); hence every progress-measure / separating-automaton / succinct-measure method is
  quasi-poly-bounded and **cannot be polynomial**. — **CITED** (Czerwiński–Daviaud–Fijalkow–Jurdziński–Lazić–Parys,
  SODA 2019). *Instantiated in III:* SPM lift count grows super-linearly even on random games (208→3552, n=8→16, `1843`).
- **B2 — Strategy-improvement exponential lower bound.** The standard SI pivot rules take `2^Ω(n)` steps on the
  Friedmann games. — **CITED** (Friedmann 2011; Fearnley/Friedmann for randomized rules). *Consistent in III:* the
  honest negative that greedy region-size SI has local optima (`1840`), motivating the VJ valuation.
- **B3 — Complexity ceiling.** Parity-game winner determination ∈ **UP ∩ coUP** (and reduces, in poly time, to
  mean-payoff / discounted / simple-stochastic games — all of the same standing). — **CITED** (Jurdziński 1998).

---

## §4. The structural dichotomy (the SHAPE of the wall)

Every proposed winner-determination mechanism — including all 31+30 generated by the two adversarial workflows —
falls into exactly one of two classes, and **neither escapes**:

- **Class I — control-discarding.** Reads a graph/spectral/topological/algebraic invariant of `(V,E,pr)` blind to
  ownership: persistent homology, Bass–Ihara zeta, parity-sheaf cohomology, Euler characteristic, Oseledets cocycle,
  averaged-policy "recurrent priority" (regret-matching / perturbed-leader), smoothed/entropic fixpoints in the
  zero-temperature limit. **OBSTRUCTED** by **T2** (§1): it cannot see control, so it is wrong on an ownership-swap
  pair — asymptotically a coin flip (the control-free signed zeta self-decays to ~50%). The 39-agent
  `parity-novel-invent` workflow killed 21 candidates this exact way; T2 is the single theorem behind all 21.
- **Class II — control-preserving.** Encodes the game faithfully: the exact solvers, the sound sandwich/dominions,
  the algebraic Nullstellensatz encoding, strategy improvement. **Correct**, but its *cost* is the open question:
  partial-solver coverage shrinks with n (§2); the Nullstellensatz certificate degree / Gröbner cost = "is parity in
  P?" restated; SI step-count = B2's battleground.

> **The dichotomy, as a sentence.** A mechanism either ignores control (and is *provably* wrong, T2) or re-encodes
> control (and *provably* inherits the open complexity). No change of mathematical lens — topology, spectra, zeta,
> algebra, message-passing, learning — dissolves the difficulty; it is irreducibly the **control/alternation**.

---

## §5. The equivalence web ("the door is one wall, with many faces")

The following are **polynomial-time equivalent** — a poly algorithm for any one is a poly algorithm for all. What
looks like many separate doors is one wall seen from different sides. — **CITED** equivalences; the III artifacts named
are *instantiations* that make each face concrete and oracle-checked.

| Face | Statement | III instantiation |
|---|---|---|
| Games | parity-game winner determination ∈ P? | Zielonka oracle `1839` |
| Logic | full modal μ-calculus model-checking ∈ P? | **`1853` VERIFIED**: the parity μ-formula's nested fixpoint (cpre, Emerson–Lei) == the game oracle on every game — a 4th independent solver |
| Strategy | ∃ a positional-SI pivot rule with poly-many steps? | VJ/LRC SI `1841/1842`, step counts |
| Algebra | ∃ a poly-degree Nullstellensatz certificate for the winning region? | Gröbner encoding `1847` |
| Quant. games | mean-payoff / discounted / simple-stochastic games ∈ P? | sandwich reductions `1846`; **`1855`**: the parity→mean-payoff reduction is real, and its **standard separating-weight scheme has exponential magnitude** `(n+1)^d` — the numbers are where the alternation hides |

All sit in **UP∩coUP** (B3), with the best general upper bound **quasi-polynomial** (Calude et al. 2017) and the
universal-tree family **provably** unable to reach P (B1).

---

## §6. The open core, and the proven-obstructed meta-grail

- **O1 — The wall itself.** Is parity-game winner determination in P (equivalently, all of §5)? — **OPEN.** Unmoved
  for 50+ years; a `$1M`-class question. Every Class-II mechanism here reaches it and stops; every Class-I mechanism
  is killed by T2 before reaching it.
- **M1 — The meta-grail (the canonical algebraic bridge across the lattice logics and the PQ ring).** — **OBSTRUCTED on
  CHARACTERISTIC** (proven negative, scoped). The De Morgan completion unifies the *lattice* logics
  (weave/Voice/logic6, KAT `1826`); the canonical bridge to the post-quantum ring `ℤ_q` provably fails (KAT `1851`, and
  generically across the deployed crypto stack, `1862`). The **load-bearing** reason is the **characteristic**: a unital
  ring hom char-2 → `ℤ_q` forces `2 = 0`, contradicting `2 ≠ 0` in odd `ℤ_q` (equivalently `𝔽₂` is not a subring of
  `ℤ_q`) — *target-specific*, and it vanishes at char 2. *(The separate idempotency point — only additive idempotent is
  `0`, so `∨↦+` collapses — is **generic**: it holds in every ring including `𝔽₂`, so it carries no crypto information;
  it only rules out the naive `∨↦+` map. The characteristic carries the result, and even the principled Stone bridge
  fails for it.)* *Scope:* this rules out the canonical morphism classes; it does **not** prove that *no* relation of any
  kind exists — the weave still **simulates** `ℤ_q` as char-2 circuits (a real, non-canonical relation). So the
  canonical "single algebraic key including PQ" is empty; a unification of a *different* kind is not ruled out.

---

## §7. The ledger — what is formally settled

| # | Statement | Status | Anchor |
|---|---|---|---|
| F | Order-theoretic foundation: cpre monotone, attractor = lfp (Knaster–Tarski) | **VERIFIED (III)** | `1854` |
| T0 | Determinacy (W₀,W₁ partition V) | **VERIFIED (III)** + CITED | `1849` |
| T1 | Positional determinacy (single σ wins W₀) | **VERIFIED (III)** + CITED | `1849` |
| T1′ | Positional determinacy is parity-SPECIFIC (gen-Büchi needs memory) | **PROVEN (III)** | `1856` |
| T2 | Control-blindness barrier (no graph invariant decides parity) | **PROVEN (III)** | `1848` |
| T2′ | Control-blindness, quantitative (graph-invariant accuracy decreases with size, this sample) | **EMPIRICAL (III)** | `1852` |
| T3 | One-player parity ∈ P, exactly (reach-to-α-cycle) — the wall = the 1→2-player step | **VERIFIED (III)** | `1850` |
| C0 | Games ⟺ Logic: μ-formula nested fixpoint == game winner | **VERIFIED (III)** | `1853` |
| C1 | Three solver families agree | **VERIFIED (III)** | `1845` |
| C2 | Relaxation-sandwich soundness | **VERIFIED (III)** | `1846` |
| C3 | Algebraic (Nullstellensatz/GF(3)) encoding correct | **VERIFIED (III)** | `1847` |
| B1 | Universal-tree quasi-poly lower bound | CITED (instantiated `1843`) | CDFJLP 2019 |
| B2 | SI exponential lower bound | CITED (consistent `1840`) | Friedmann 2011 |
| B3 | parity ∈ UP∩coUP | CITED | Jurdziński 1998 |
| Q | the standard parity→mean-payoff separating-weight *scheme* is exponential `(n+1)^d` | **PROVEN (III)** | `1855` |
| D | Class I / Class II dichotomy | **PROVEN-NEGATIVE for Class I** (T2) | §4 |
| O1 | parity games in P? | **OPEN** | the wall |
| M1 | the canonical algebraic bridge to the PQ ring fails on CHARACTERISTIC (char 2 vs odd `ℤ_q`; idempotency is a generic aside) | **OBSTRUCTED (canonical, on characteristic)** | `1851`,`1862`,`1826` |

**The honest one-line summary.** The "door" the field sees is one **wall** with many equivalent faces (§5); its
two known faces are *proven* unclimbable for whole method families (B1, B2); its shape is the **control/alternation**
dichotomy (§4), whose Class-I half is *proven* dead in III (T2); and its interior — whether the wall has a door at
all (O1) — is **open**, untouched, and was never faked. The meta-grail above it (M1): its two *canonical* algebraic
bridges are *proven* to fail (a unification of a different kind is not ruled out). We mapped the roof; we did not
pretend to fly through it.
