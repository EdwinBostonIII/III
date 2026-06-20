# THE SAT / P-vs-NP WALL — A Formal Map

The second wall, given the same PROVEN/VERIFIED/CITED/OBSTRUCTED/OPEN treatment as the parity wall (capstone:
`III-THE-PARITY-WALL-CAPSTONE.md`). Boolean satisfiability is the *defining* wall of complexity theory — its open core
is **P vs NP** itself. We map its tractable islands (each a gated KAT == a brute-force oracle), its sharp classification
boundary, its structural core, and its cross-wall position relative to parity.

**Proof-status legend** (as the parity capstone): **PROVEN (III)** · **VERIFIED (III)** · **CITED** · **OBSTRUCTED** ·
**OPEN**. The standing honesty invariant (math-olympiad #4): nothing here puts SAT in P or claims P=NP; every island is
a *restricted* tractable class, every barrier is cited, the open core is reached and faked by none.

---

## 1. Object and ground truth

A **CNF formula** over `n` Boolean variables is a conjunction of clauses, each clause a disjunction of literals
(a variable or its negation). It is **SAT** if some assignment satisfies every clause. The **oracle**: brute-force
enumeration of all `2^n` assignments (`satisfies`/`brute_sat` in the KATs). Every island solver below is checked
against it.

---

## 2. The tractable islands (Schaefer's six classes — each VERIFIED == oracle)

**Schaefer's dichotomy (CITED, 1978).** A Boolean constraint language is in P iff every constraint lies in one of six
classes — and is NP-complete otherwise. There is **no intermediate** complexity for Boolean CSP: a perfect P /
NP-complete cliff. All six islands are grounded in III:

| Island | Decided in P by | Status | KAT |
|---|---|---|---|
| **2-SAT** (bijunctive, ≤2 literals/clause) | implication graph + SCC (Aspvall–Plass–Tarjan) | **VERIFIED (III)** | `1863` |
| **Horn** (≤1 positive literal/clause) | unit-propagation least model (Dowling–Gallier) | **VERIFIED (III)** | `1864` |
| **affine / XOR** (parity constraints) | Gaussian elimination over GF(2) | **VERIFIED (III)** | `1865` |
| **dual-Horn** (≤1 negative literal/clause) | flip→Horn least model | **VERIFIED (III)** | `1867` |
| **0-valid** (all-false satisfies) | trivial (every clause has a negative literal) | **VERIFIED (III)** | `1867` |
| **1-valid** (all-true satisfies) | trivial (every clause has a positive literal) | **VERIFIED (III)** | `1867` |

**The boundary (PROVEN-illustrated, `1867`).** The 3-CNF `{(x₁∨x₂∨x₃), (¬x₁∨¬x₂∨¬x₃)}` (a not-all-equal constraint on
three variables) is in **none** of the six classes (≥2 positive ⇒ not Horn; ≥2 negative ⇒ not dual-Horn; a clause with no
negative ⇒ not 0-valid; no positive ⇒ not 1-valid; 3 literals ⇒ not bijunctive). *Not affine either, by a counting
argument:* it has exactly **6** satisfying assignments (all of `{0,1}³` except `000` and `111`), and `6` is not a power of
`2`, so its solution set cannot be an affine subspace of `𝔽₂³`. The KAT (`1867`) checks the five CNF-syntactic classes
mechanically; affine is closed by this one-line argument. It is the germ of NP-completeness (NAE-3SAT-shaped), decided
only by search — the SAT wall's *sharp edge*: one step outside the six islands and the problem is NP-complete.

---

## 3. The structural core (NP-complete, self-reducible) — VERIFIED + CITED

- **SAT ∈ NP (VERIFIED, `1866`).** A satisfying assignment is a poly-checkable YES-witness (one pass over the clauses).
- **SAT is self-reducible (VERIFIED, `1866`).** Search ≤ decision: from a SAT *decision* oracle, a full satisfying
  assignment is recovered with `n` queries (fix variables one at a time). The YES-witness is not only short but findable.
- **SAT is NP-complete (CITED, Cook–Levin 1971).** Every NP problem reduces to SAT in poly time — it is *the* hardest
  problem in NP. Thousands of problems are NP-complete by reduction *from* SAT.
- **The YES/NO asymmetry (CITED).** YES instances have short witnesses (assignments); NO instances (UNSAT) have **no
  known** short witness — a poly UNSAT certificate would put SAT in coNP, hence NP = coNP. Resolution refutations can be
  exponentially long (Haken 1985, the pigeonhole principle).

---

## 4. The open core, and the cited barriers

- **O — P vs NP.** Is SAT (equivalently, any NP-complete problem) in P? — **OPEN.** The defining open problem of computer
  science; a `$1M` Clay problem. Every island stops at its class boundary; general 3-SAT is the NP-complete core.
- **B-SAT1 — proof-complexity lower bounds (CITED).** Resolution requires exponential-size refutations for the pigeonhole
  principle (Haken); Nullstellensatz / polynomial-calculus degree lower bounds (Razborov; Buss et al.). The algebraic
  face (à la parity's `1847`) inherits high degree — a poly-size/-degree certificate system for all of UNSAT would
  collapse NP=coNP.
- **B-SAT2 — natural-proofs / relativization / algebrization barriers (CITED).** Razborov–Rudich (natural proofs),
  Baker–Gill–Solovay (relativization), Aaronson–Wigderson (algebrization): broad classes of proof *techniques* provably
  cannot resolve P vs NP. These are the SAT wall's analog of parity's universal-tree barrier (B1) — whole *method
  families* shown unable to climb.

---

## 5. The dichotomy and the four "islands" axes

Like parity's four axes, the SAT wall's tractability is a sharp boundary along structural axes — but, by Schaefer, the
boundary is a **cliff, not a slope** (P or NP-complete, nothing between *for Boolean CSP*):
- **clause width**: ≤2 literals (2-SAT, P) → 3 literals (NP-complete);
- **polarity**: ≤1 positive (Horn) or ≤1 negative (dual-Horn) per clause (P) → mixed (NP-complete);
- **algebraic form**: linear/affine (XOR, P) → nonlinear (NP-complete);
- **trivial-point**: 0-/1-valid (P) → neither (toward NP-complete).
Cross any axis out of Schaefer's six classes and you are at the NP-complete core.

---

## 6. Cross-wall position — SAT vs parity (the asset compounds)

This is where two mapped walls become *more* than the sum:

| | **SAT wall** | **Parity wall** |
|---|---|---|
| open core | **P vs NP** | parity ∈ P? (`O1`) |
| complexity status | **NP-complete** (the top of NP) | **∈ NP∩coNP** (`1860`) — *not* NP-complete unless NP=coNP; placement in-P-vs-intermediate is **OPEN** |
| witness symmetry | asymmetric (YES short, NO not known) | symmetric (both short — UP∩coUP) |
| tractable boundary | **sharp cliff** (Schaefer: P or NP-complete) | a *slope* of islands + open core |
| best general algorithm | exponential (none sub-exp known; ETH *conjectures* none exists) | **quasi-polynomial** (Calude 2017) |

**The extrapolation — stated honestly (the proven core is narrow; two reads sit on it).** What is **PROVEN (III)**: parity
∈ NP∩coNP (`1860`), hence *not* NP-complete unless NP=coNP — it cannot be the SAT-style complete top. What is **OPEN**:
*where* parity actually sits. Two defensible reads, and the honest map carries both:
- **(intermediate read)** Ladner's theorem (CITED, 1975) — *if* P≠NP, NP-intermediate problems exist (neither in P nor
  NP-complete). Parity is a *candidate*, alongside the still-open NP∩coNP problems **integer factoring** and **discrete
  log**.
- **(eventual-P read — suggestive but tempered)** Problems that were in NP∩coNP *with a good upper bound* have a track
  record of **falling to P**: **primality** (NP∩coNP via Pratt, *randomized*-poly via Miller–Rabin; → AKS 2002, in P) and
  **linear programming** (NP∩coNP via duality; → ellipsoid 1979, in P). Parity is NP∩coNP and quasi-polynomial — *near*
  this profile, but its upper bound (quasi-poly) is **weaker** than primality's (randomized-poly) or LP's (poly) ever was.
  So the precedent is real but **does not** make eventual-P the favored bet — only as defensible as "intermediate."

So the cross-wall asset is not "parity is the intermediate archetype" (that overstates an open placement). It is sharper:
**SAT is provably the complete top; parity is provably *not* there (NP∩coNP); and parity sits *near* — at a weaker
upper bound (quasi-poly) than — the coordinates (NP∩coNP + randomized-poly/poly) from which the dominoes (primality, LP)
fell to P.** That makes the parity wall the *more* interesting of the two: it is where the landscape's intermediate band
either gets populated (Ladner) or gets one fewer member, and which one is O1 itself. Two walls mapped, one open question
made precise — every claim tagged, both open cores untouched.

---

## 7. The ledger

| # | Statement | Status | KAT |
|---|---|---|---|
| I1 | 2-SAT ∈ P (implication graph) == oracle | **VERIFIED (III)** | `1863` |
| I2 | Horn-SAT ∈ P (least model) == oracle | **VERIFIED (III)** | `1864` |
| I3 | XOR-SAT ∈ P (Gaussian/GF(2)) == oracle | **VERIFIED (III)** | `1865` |
| I4 | dual-Horn ∈ P (flip→Horn) == oracle | **VERIFIED (III)** | `1867` |
| I5 | 0-valid / 1-valid ∈ P (trivial) == oracle | **VERIFIED (III)** | `1867` |
| S | non-Schaefer witness outside all six classes (the boundary) | **PROVEN (III)** | `1867` |
| N1 | SAT ∈ NP (poly YES-witness) | **VERIFIED (III)** | `1866` |
| N2 | SAT self-reducible (search ≤ decision) | **VERIFIED (III)** | `1866` |
| D | Schaefer dichotomy (P or NP-complete, no intermediate for Boolean CSP) | CITED | Schaefer 1978 |
| NC | SAT NP-complete | CITED | Cook–Levin 1971 |
| B-SAT1 | proof-complexity exponential lower bounds | CITED | Haken 1985 |
| B-SAT2 | natural-proofs / relativization / algebrization barriers | CITED | RR/BGS/AW |
| X | SAT NP-complete vs parity ∈ NP∩coNP (PROVEN, so not NP-complete unless NP=coNP); parity's placement (in-P vs Ladner-intermediate) is OPEN — primality/LP precedent points as much to eventual-P | PROVEN core + **OPEN** placement | `1860`,`1866` |
| O | **P vs NP?** | **OPEN** | the wall |

**Bottom line.** The SAT wall is the *complete* wall — its open core is P vs NP, its boundary is a sharp Schaefer cliff,
its hardness is NP-completeness (the top of NP). Set beside the parity wall (∈ NP∩coNP — proven *not* the complete top —
quasi-poly, witness-symmetric, with placement *open*), it reveals the landscape's true shape: a sharp P/NP-complete cliff
within Boolean CSP, and — across all of NP — a band that Ladner proves is populated iff P≠NP, where parity sits *near*
(at a weaker, quasi-poly upper bound than) the coordinates from which primality and LP fell to P. Two walls mapped, the
open question between them made precise — every claim tagged, both open cores untouched.
