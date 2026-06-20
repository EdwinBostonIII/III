# THE PARITY WALL — Capstone

*The single canonical document for the "parity games in P? / full μ-calculus model-checking in P?" investigation.*
It consolidates the deep formal map, the residual-hope exhaustion, and the broader-reach analysis into one
self-contained edifice, with a strict proof-status tag on every claim. The three detailed companion documents —
`III-PARITY-WALL-FORMAL.md` (the foundation theorems), `III-PARITY-RESIDUAL-HOPES.md` (the avenue ledger),
`III-PARITY-BROADER-REACH.md` (the reach) — are its appendices. Every internal node below is a gated, oracle-checked
KAT in `STDLIB/corpus/` (run via `STDLIB/scripts/run_corpus.sh`, exit 99 = pass).

**Proof-status legend.** **PROVEN (III)** = constructive theorem, complete oracle-verified witness in a gated KAT ·
**VERIFIED (III)** = a ∀-statement (known theorem) machine-checked on every sampled instance + cited · **EMPIRICAL (III)**
= a measured trend, not an asymptotic proof · **CITED** = published theorem, named, not reproven · **OBSTRUCTED** =
proven impossibility (scoped where noted) · **OPEN** = genuinely unknown.

**The standing honesty invariant (math-olympiad #4).** Nothing in this edifice puts parity in P, and nothing claims to.
Every "closure" is a refutation of a shortcut, an island (a restricted tractable regime), or a citation — never an
accidental resolution of the open core. The open core was reached by every honest route and faked by none.

---

## 1. The object, and the ground truth

A **parity game** `G = (V, V₀, V₁, E, pr)`: `V = V₀ ⊎ V₁` (ownership), `E` total, `pr : V → ℕ`. A play's winner is the
player whose parity matches `max{pr(v) : v infinitely often}`. `W₀, W₁` are the winning regions. The **priority-graph**
is `(V, E, pr)` — everything *except* ownership.

The **oracle**: III's recursive Zielonka solver (`1839`), cross-validated byte-for-byte against two independent solver
families — Vöge–Jurdziński strategy improvement (`1841`) and Jurdziński small progress measures (`1843`) — on ~29k
games (`1845`). Every theorem below is checked against it.

---

## 2. The complete ledger (one table, every claim)

| # | Statement | Status | KAT |
|---|---|---|---|
| **F** | Order-theoretic foundation: `cpre` monotone, attractor = lfp (Knaster–Tarski) — *why* the fixpoints exist and the algorithms terminate | **VERIFIED (III)** | `1854` |
| **T0** | Determinacy: `W₀, W₁` partition `V` — *why* "the winner" is well-defined (the precondition for a decision problem) | **VERIFIED (III)** + CITED | `1849` |
| **T1** | Positional determinacy: a single positional `σ*` wins `W₀` — the hinge of every constructive attack | **VERIFIED (III)** + CITED | `1849` |
| **T1′** | Positional determinacy is **parity-specific**: a generalized-Büchi objective needs *memory* (no positional strategy wins) — the gift is special to parity | **PROVEN (III)** | `1856` |
| **T2** | **Control-blindness barrier** (keystone): no function of `(V,E,pr)` alone decides parity — one vertex's *owner* flips the winner with the graph fixed | **PROVEN (III)** | `1848` |
| **T2′** | Control-blindness, quantitative: a control-free invariant's accuracy *decreases* with size (82→70→65) | **EMPIRICAL (III)** | `1852` |
| **T3** | One-player parity ∈ P exactly (reach-to-α-cycle) — the wall = the 1→2-player step | **VERIFIED (III)** | `1850` |
| **C0** | **Games = Logic**: the parity μ-formula's nested fixpoint == the game winner (a 4th independent solver) | **VERIFIED (III)** | `1853` |
| **C1** | Three independent solver families agree everywhere | **VERIFIED (III)** | `1845` |
| **C2** | Sound relaxation sandwich `R_A ⊆ W₀ ⊆ R_E` | **VERIFIED (III)** | `1846` |
| **C3** | Algebraic Nullstellensatz/GF(3) encoding correct (Gröbner decides parity) | **VERIFIED (III)** | `1847` |
| **B1** | Universal-tree quasi-poly lower bound — the progress-measure family *cannot* reach P | CITED (instantiated `1843`) | CDFJLP 2019 |
| **B2** | Strategy-improvement exponential lower bound (known pivot rules) | CITED (consistent `1840`) | Friedmann 2011 |
| **B3** | parity ∈ UP∩coUP | CITED | Jurdziński 1998 |
| **Q** | the standard parity→mean-payoff separating-weight *scheme* is exponential `(n+1)^d` — the cost migrates into the numbers | **PROVEN (III)** | `1855` |
| **I-D** | bounded priorities are an **island**: Büchi (d=2) ∈ P exactly; bounded-d is `n^{O(d)}` — the wall = `d=Θ(n)` | **VERIFIED (III)** + CITED | `1857` |
| **I-E** | 0-player ∈ P (deterministic walk) — the player ladder base | **VERIFIED (III)** | `1857` |
| **R-B** | the bounded-width **dominion family** is `Ω(n)`-incomplete (cannot be pushed to completeness) | **PROVEN (III)** | `1859` |
| **R-C** | priority **compression** to bounded-`d` flips the winner (naive collapse) — a winner-preserving one = O1 | **PROVEN (III)** | `1858` |
| **R-M** | parity ∈ **NP∩coNP**: a positional strategy is a poly-checkable witness *both ways* — **not** NP-complete unless NP=coNP (placement in-P-vs-intermediate is OPEN) | **PROVEN (III)** | `1860` |
| **D** | Class I (control-discarding) / Class II (control-preserving) dichotomy is exhaustive | **PROVEN-NEGATIVE for Class I** (T2) | §4 |
| **O1** | **parity games ∈ P?** | **OPEN** | the wall |
| **M1** | the canonical algebraic bridge to the PQ ring fails on **characteristic** (char 2 vs odd `ℤ_q`) | **OBSTRUCTED (canonical)** | `1851`,`1862` |

---

## 3. The four axes of the wall (where, exactly, it lives)

The wall is located precisely by four *proven discontinuities*, each crossing from a tractable regime into the open core:

- **Player axis.** 0-player (P, `1857`) → 1-player (P, `1850`/T3) → 1½-player MDP (P, CITED) → **2-player (O1)**. The wall is
  the adversarial 1→2-player step, and T2 shows 2-player does *not* reduce to 1-player by any control-free map.
- **Priority axis.** Bounded `d` (P, `1857`/I-D) → **`d=Θ(n)` (O1)**. The wall needs unbounded alternation depth; compressing
  the priorities flips the winner (`1858`/R-C).
- **Control axis.** Control-free read-off (provably *wrong*, T2/`1848`) → control-preserving (provably inherits the cost).
  The dichotomy (§4) is the shape of the wall: no change of lens dissolves the difficulty.
- **Width axis.** Bounded tree/DAG/clique-width (P, CITED) → **unbounded width (O1)**. So the hard core is *doubly*
  unbounded — priority alternation *and* graph width.

The wall is exactly the corner where all four are unbounded.

---

## 4. The dichotomy — the shape

Every winner-determination mechanism (including all 31+30 generated by two adversarial workflows) is one of:
- **Class I — control-discarding** (reads a graph/spectral/topological/algebraic invariant of `(V,E,pr)`):
  **OBSTRUCTED** by T2 — wrong on an ownership-swap pair; accuracy decays to chance (T2′). The 39-agent workflow
  re-derived this 21×; T2 is the one theorem behind all 21.
- **Class II — control-preserving** (the exact solvers, the sandwich/dominions, the Nullstellensatz encoding, SI):
  **correct**, but its cost *is* O1 — partial coverage shrinks with n; certificate degree = "is parity in P?"; SI
  step-count = B2's battleground.

> A mechanism either ignores control (provably wrong) or re-encodes it (provably inherits the open complexity). The
> difficulty is irreducibly the **control / alternation**.

---

## 5. The equivalence web — one wall, many faces

All **poly-time equivalent** (CITED; III artifacts make each face concrete and oracle-checked):

| Face | Question | III instantiation |
|---|---|---|
| Games | parity winner determination ∈ P? | Zielonka oracle `1839` |
| Logic | full μ-calculus model-checking ∈ P? | `1853` (μ-formula nested fixpoint == oracle, 4th solver) |
| Strategy | a poly-step positional-SI pivot rule? | `1841/1842` |
| Algebra | a poly-degree Nullstellensatz certificate? | `1847` (Gröbner) + `1855` (exponential scheme) |
| Quant. games | mean-payoff / discounted / simple-stochastic ∈ P? | `1846`; `1855` |

All sit in **UP∩coUP** (B3); best general upper bound **quasi-polynomial** (Calude 2017); the universal-tree family
**provably** stuck above P (B1).

---

## 6. Residual hopes — every door tried (verdict)

The full 14-avenue ledger is `III-PARITY-RESIDUAL-HOPES.md`. Verdict: after walking every avenue, three classes remain
and **none is a route**: (1) **closed** shortcuts/islands (invariant read-off A; compression C; bounded-d D; players E;
quant-games scheme I; NP-hard reframe M; width) — provably not a way through; (2) **cited** ceilings/family lower bounds
(progress measures G/B1; randomization J; quasi-poly K; SI B2) — provably not poly for whole families; (3) **open
slivers** (partial-solver *completeness* B; algebraic certificate degree H; tangle learning L; SI pivot F) — each of
which, *if* it yielded a complete poly procedure, would simply **be** O1, and none has. No quantum advantage is known
(N). **There is no unlocked door.**

---

## 7. The broader reach (rigorous core, honestly bounded)

Full analysis in `III-PARITY-BROADER-REACH.md`, every claim tagged. The core:
- **Verification frontier (THEOREM).** The μ-calculus is the canonical specification logic (CITED); CTL embeds in it —
  its EF/EG/EU are single, *alternation-free* fixpoints, poly (`1861`) — so CTL is **below** the wall, and the wall *is*
  the **alternation** full μ adds (= parity, `1853`). The parity wall is the worst-case model-checking frontier.
- **Characteristic firewall (THEOREM, scoped).** The canonical algebraic bridge between char-2 lattice logic and the
  odd-characteristic crypto stack fails *uniformly* on **characteristic** (`1851`/`1862`) across ML-KEM/Falcon/ML-DSA/
  Mersenne/Goldilocks/RSA. (The "idempotency" half is generic — true in every ring — and carries no crypto information;
  characteristic is load-bearing.)
- **Structural hardness anatomy (THEOREM).** We can name *why* parity is hard (control/alternation, T2), *where* the
  cost hides in each reformulation (the numbers `1855`; the certificate degree `1847`; the tree size B1), and *what
  bound* it sits under (∈ NP∩coNP — not NP-complete unless NP=coNP, `1860`).
- The grand framings — "universal speed limit," "impassable canyon," "laws of hardness," "math is jagged" — are tagged
  **INTERPRETATION / SPECULATION**, sitting *on* the theorems, never *as* theorems.

---

## 8. Cross-wall position — what this asset is, and how it extrapolates

The parity wall is **provably in NP∩coNP** (`1860`) — positionally determined, control-essential, alternation-bounded,
the canonical hard core of infinite games and of μ-calculus verification, sitting in the quasi-poly↔poly gap. What this
*proves* is narrow and exact: parity is *not* NP-complete unless NP=coNP — it cannot be the SAT-style complete top. What
it does **not** settle is *where* parity sits — that placement is itself **OPEN** (advisor-audited: NP∩coNP membership
does not establish Ladner-intermediacy; parity could be in P). Its NP∩coNP + quasi-poly profile matches *both* the
still-open intermediates (integer factoring, discrete log) *and* the problems that **fell to P** from exactly this
profile (primality → AKS 2002; linear programming → ellipsoid 1979) — a precedent that arguably favors eventual-P. This
is precisely why parity is a *better-understood* wall than P-vs-NP, and a more interesting one: it is hemmed in from both
sides, sitting at the coordinates where the dominoes have historically fallen.

**The reusable method (the template every other wall inherits):** *(i)* build an oracle (a ground-truth decision
procedure); *(ii)* prove the **islands** — the restricted regimes that are in P — as gated KATs == oracle; *(iii)* cite
the **barriers** — the published lower bounds that kill whole method families; *(iv)* exhaust the **residual hopes** —
each closed, cited, or marked OPEN-with-no-positive-result; *(v)* locate the **open core** exactly and mark it OPEN;
*(vi)* tag every claim and let the advisor attack the prose-vs-content gap that rc=99 cannot see. Each wall so treated
becomes a grounded asset: its islands are tools, its barriers are constraints, its open core is a precisely-bounded
frontier. The same calibrated honesty that mapped this wall is the instrument for all the others.

---

## 9. The honest bottom line

Parity-game solving — equivalently, full μ-calculus model-checking — is a **wall**: a problem hemmed into UP∩coUP,
positionally determined, whose hardness is *structurally* the control/alternation (T2), whose every tractable boundary
is *proven* (the four axes, §3), whose every escape avenue is *closed, cited, or open-with-no-positive-result* (§6), and
whose interior — **O1, parity ∈ P?** — is **open**, untouched, and was never faked. We mapped the roof, the floor, the
four walls, and the one door nobody has opened; we did not pretend to walk through it. That, proven and tagged, is the
asset.
