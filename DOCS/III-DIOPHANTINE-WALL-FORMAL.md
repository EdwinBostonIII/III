# THE DIOPHANTINE WALL (Hilbert's 10th) — A Formal Map, and the Second Falsifier

The eleventh wall is the program's **second deliberate falsifier**. Where Goodstein (`1880`) strained the template's
**boundary**, Hilbert's 10th strains its **oracle** — the very first step ("build a ground-truth decider") is
*impossible* here. Two falsifiers, two distinct hidden assumptions exposed.

**Proof-status legend** as the parity capstone. **Honesty invariant (math-olympiad #4):** the linear island is gated;
the undecidability of the general problem is CITED (MRDP); the value is the falsifier verdict, not a claim to decide
Hilbert's 10th.

---

## 1. Object and the undecidability

**Hilbert's 10th problem:** decide whether a polynomial Diophantine equation `P(x₁,…,xₙ)=0` has an *integer* solution.
By the **MRDP theorem** (Matiyasevich 1970, on Davis–Putnam–Robinson) this is **undecidable** — no algorithm, hence **no
computable oracle**, for the general problem. Crucially, this is stronger than confluence's obstruction (`1868`): a
finite ARS still has a *per-instance* decidable oracle, but a general Diophantine equation cannot even be brute-forced
per instance — solutions can be astronomically large with *no computable bound*, so unbounded integer search has no
decidable cutoff.

---

## 2. The island, and the falsifier test

- **ISLAND — yes, gated (`1881`).** **Linear** Diophantine equations are decidable: `a·x + b·y = c` has an integer
  solution iff `gcd(a,b) ∣ c` (Bézout). Verified: the gcd-criterion agrees with a *bounded* brute search on 4000 random
  `(a,b,c)` — the bound `|a|+|b|+|c|+2` makes the search complete for the linear case (a Bézout solution lies within it).
  For the island, the oracle **exists** — which is exactly what the general problem lacks.
- **ORACLE — it BREAKS (the informative point).** The template's step 1 is "build a ground-truth decider." For the
  general Diophantine problem there is **none** — and not for lack of effort: MRDP *proves* no decider exists. So every
  later step (check islands == oracle) has nothing to check against. The template silently assumed a decidable oracle;
  here that assumption is false by theorem.
- **CORE — OBSTRUCTED (undecidable), with the no-oracle sharpening.** Like confluence, the core is a proven
  impossibility — but Hilbert's 10th sharpens it: confluence-of-finite-ARS is decidable per instance (oracle exists, just
  not uniformly); Hilbert's-10th has *no* per-instance decidable search bound. The obstruction reaches the oracle itself.

---

## 3. The two falsifiers together — the template's hidden assumptions, mapped

| Falsifier | Template step it breaks | The hidden assumption exposed |
|---|---|---|
| **Goodstein** (`1880`) | the **boundary** | "the boundary is a *computational* quantity" — actually proof-theoretic (PA vs `ε₀`) |
| **Hilbert's 10th** (`1881`) | the **oracle** | "a *decidable* ground-truth oracle exists" — false for undecidable problems (MRDP) |

Both still admit a **gated island** (small `G(m)` terminate; linear Diophantine decidable), so the *island* step is
robust across both probes. What the two falsifiers establish is **two of the template's boundary conditions** — (i) a
decidable oracle and (ii) a computational boundary — *not* the full domain of validity (two probes are two data points,
not an enumeration; a third assumption, a clean island/core split, is already strained by communication complexity's
open log-rank face). A method with even two *explicitly-found* boundary conditions (by probes designed to break it) is
more trustworthy than one tested only where it works.

---

## 4. The ledger

| # | Statement | Status | KAT |
|---|---|---|---|
| Isl | linear Diophantine decidable: `gcd(a,b)∣c` == bounded brute | **VERIFIED (III)** | `1881` |
| MRDP | general Diophantine solvability undecidable (no computable oracle) | CITED / OBSTRUCTED | Matiyasevich 1970 |
| Falsifier | the template's ORACLE step has no ground truth for the general core | (verdict) | `1881` |

**Bottom line.** Hilbert's 10th is the second falsifier: its linear island is gated (`1881`), but its general core is
*undecidable with no computable oracle at all* — breaking the template's **oracle** step, as Goodstein broke its
**boundary**. Together the two probes *name two of the method's boundary conditions* — a decidable oracle and a
computational boundary — without claiming to enumerate them (a third, a clean island/core split, is already strained by
communication complexity's open log-rank face). Eleven walls — the last two deliberately chosen to find, and to name,
*two* of the places the template stops.
