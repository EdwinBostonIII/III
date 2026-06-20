# THE WALLS — A Cross-Wall Synthesis

This is the meta-asset: five hard problems, each pushed to its limit and mapped by the same discipline, then read
*together*. The value of mapping many walls is not the sum of the maps — it is the structure that only becomes visible
across them. That structure is laid out here, with the same calibrated honesty as each wall: the **method** is a
demonstrated template, the **taxonomy** is an organizing lens (not a proven theorem), the **parallels** are analogies
(not reductions), and the per-wall **facts** are gated KATs or cited theorems.

The five walls and their canonical documents:
- **Parity / μ-calculus** — `III-THE-PARITY-WALL-CAPSTONE.md` (KATs 1838–1862)
- **SAT / P-vs-NP** — `III-SAT-WALL-FORMAL.md` (KATs 1863–1867)
- **Confluence / rewriting** — `III-CONFLUENCE-WALL-FORMAL.md` (KATs 1868–1869)
- **Graph isomorphism** — `III-GI-WALL-FORMAL.md` (KATs 1870–1872)
- **Lattice representation** — `III-LATTICE-WALL-FORMAL.md` (KATs 1873–1874)
- **Primality / factoring** — `III-PRIMALITY-FACTORING-WALL-FORMAL.md` (KATs 1875–1876)
- **Communication complexity** — `III-COMMCOMPLEXITY-WALL-FORMAL.md` (KAT 1877)
- **Ramsey theory** — `III-RAMSEY-WALL-FORMAL.md` (KAT 1878)

---

## 1. The template (the method — DEMONSTRATED on five walls)

Every wall was mapped by the same six-step procedure. This is not a claim about the walls; it is the *instrument*, and
its reusability is the first asset:

1. **Oracle** — build a ground-truth decision procedure (brute search / a verified solver).
2. **Islands** — prove the restricted regimes that *are* tractable, each a gated KAT `== oracle`.
3. **Barriers** — cite the published lower bounds that kill whole *method families*.
4. **Residual hopes** — walk every avenue to cross the wall; close, cite, or mark OPEN-with-no-positive-result.
5. **Open/obstructed core** — locate the core exactly and tag it.
6. **Adversarial prose audit** — have a fresh reviewer attack the *connective prose* (where over-claims hide; rc=99
   cannot see them), and tighten every gated-fact / cited / analogy boundary.

That this template applied cleanly to five structurally different problems — two complexity classes (SAT, GI), an
infinite-game logic (parity), a rewriting theory (confluence), and a universal-algebra problem (lattice rep) — is the
demonstrated, reusable core.

---

## 2. The taxonomy (an ORGANIZING LENS, not proven structure)

Read across the five, the walls *sort* — and naming the sorts is a lens that makes each new wall faster to map. **Tag:
this taxonomy is a useful organizing lens; it is not a theorem about the space of all problems.**

- **Kinds of core (three top-level kinds; OPEN splits three ways — sharper than "OPEN vs OBSTRUCTED", licensed by gated
  facts).** The walls' cores are not one bucket. There are three top-level kinds — **OBSTRUCTED**, **CLIMBED**, and
  **OPEN** (itself three sub-kinds, by `1866`/`1860`):
  - **OBSTRUCTED** — the frontier is a *proven impossibility*: confluence (general-TRS confluence undecidable); and,
    from the grail ledger, Rice/halting, impredicative ordinal analysis.
  - **CLIMBED** — the lower bound is a *proven separation*: **communication complexity** (`D(EQ)=n+1` via a fooling set,
    `1877`). Proof that proven lower bounds *do* exist — just rare, problem-specific, and not yet the general ones the
    open walls need. (Even a climbed area keeps an open face: the log-rank conjecture.)
  - **OPEN ≡ the grand question** — the core *is* P vs NP: **SAT** is NP-complete (`1866`), so `SAT∈P ⟺ P=NP`. Solving
    this wall solves the field's central problem.
  - **OPEN, local placement** — in NP∩(co-low), *asymmetric*: **parity** (∈ NP∩coNP, `1860`) and **GI** (∈ NP∩coAM).
    *Not*-in-P would give P≠NP, but *in*-P collapses nothing (neither is NP-complete) — a placement question, strictly
    weaker than the grand one.
  - **OPEN, non-complexity** — not a complexity-class question at all: **FLRP** (lattice representability in universal
    algebra, independent of P vs NP).
  This four-way split is still a *lens*, not a theorem — but it is a sharper lens than a single OPEN bucket, and each
  assignment is anchored to a gated fact or citation.
- **One internal shape, every wall.** A **tractable island**, a **sharp boundary** naming the island's essential
  precondition, and a **core** past it. Verified to hold on all five (the island and boundary are gated KATs in each).
- **The essential precondition is wall-specific** (§3) — the *template* is invariant, the *boundary* is not.

---

## 3. The essential-precondition catalogue (gated per wall)

The single structural quantity whose unboundedness/absence defines each wall's hard side — each established by that
wall's island+boundary KATs:

| Wall | Essential precondition (boundary) | Island (in P / decidable) | Boundary KAT |
|---|---|---|---|
| Parity | **control / alternation** | 0-/1-player, bounded-`d` (`1850`,`1857`) | the 1→2-player step, `d=Θ(n)` |
| SAT | **clause structure** | Schaefer's six classes (`1863`–`1867`) | 3-SAT (non-Schaefer, `1867`) |
| Confluence | **termination** | terminating ARS, Newman (`1868`) | non-terminating witness (`1869`) |
| Graph iso | **structural depth** | trees, 1-WL (`1870`) | regular graphs, 1-WL fails (`1871`) |
| Lattice rep | **finiteness** | `Con(V₄)=M₃`, `Π_n` (`1873`,`1874`) | finite-vs-infinite (Grätzer–Schmidt) |
| Comm. complexity | **proof-existence** (the LB is provable) | protocols / upper bounds | fooling set / rank (`1877`) |
| Ramsey | **feasibility of exhaustion** | small cases, `R(3,3)=6` (`1878`) | explosion `2^{C(N,2)}` |

Five walls, five distinct essential preconditions — control, clause-structure, termination, structural-depth,
finiteness. No two walls are hard "for the same reason," yet all five are mapped by the one template. That tension —
*invariant method, wall-specific obstruction* — is the synthesis's central observation (and a lens, not a theorem).

---

## 4. Cross-wall parallels (ANALOGIES, tagged — not reductions)

Some walls *rhyme*. These are analogies across tagged complexity-profile facts; none is a reduction or an isomorphism.

- **Parity ∥ GI (quasi-poly intermediate candidates).** Both are quasi-polynomial (Calude 2017 / Babai 2016), have a
  poly YES-witness, and are not believed NP-complete (parity ∈ NP∩coNP; GI ∈ NP∩coAM — *not the same closure*, hence
  *analogy not reduction*). Both have a **cheap invariant that fails** at the island boundary — parity's control-free
  invariant (`1848`), GI's 1-WL (`1871`) — escapable only by paying for more structure (control-preservation / `k`-WL).
  Two *independent* such problems strengthen the picture of a populated NP middle (Ladner, CITED). *Tempered note:* both
  sit at a **weaker** good-upper-bound (quasi-poly) than the NP∩coNP problems that *fell to P* (primality from
  randomized-poly; LP from poly), so the eventual-P precedent is suggestive, not favored. **This precedent is now
  grounded**, not merely cited: the primality/factoring wall instantiates *both* outcomes as gated KATs — primality fell
  to P (`1875`), factoring its self-reducible NP∩coNP twin stays open (`1876`).
- **The intermediate band splits by quantum status (CITED, analogy).** Within the classically-open NP∩coNP candidates,
  factoring and discrete log are **quantum-cracked** (BQP, Shor — period-finding structure), while parity and GI have
  **no known quantum advantage** (`III-PARITY-RESIDUAL-HOPES.md` avenue N). So "intermediate candidate" is not one cell:
  quantum-easy (factoring) vs quantum-hard (parity, GI) — a distinction the primality/factoring wall makes concrete.
- **The graph-invariant blind-spot motif.** Parity's control-blindness (`1848`, no `(V,E,pr)`-invariant decides parity)
  and GI's 1-WL incompleteness (`1871`, no color histogram decides GI) are the *same shape of obstruction* — an
  invariant collapsing exactly the distinction that matters — in two different theories. Analogy, gated on both ends.
- **OPEN vs OBSTRUCTED is a real divide.** Confluence's core is *proven* undecidable; the other four are *open*. The
  lesson a problem-mapper takes: first ask which kind of core you face — it changes whether "residual hopes" can be
  *closed* (OPEN-core: maybe; OBSTRUCTED-core: the impossibility is the closure).

---

## 5. The unifying instrument — calibrated honesty, and where it bit

The single method that made all five maps trustworthy is the **proof-status tag** plus the **adversarial prose audit**.
The recurring lesson, banked across the program: *over-claims live in the connective/cross-wall prose, never in the
gated KATs.* Every over-claim a reviewer caught — "all invariants," "decays toward 1/2," "forces," idempotency-as-
firewall, "intermediate archetype," "structural isomorphism," a DOCUMENTED-vs-VERIFIED slip — was a *sentence*, never a
KAT. The discipline that fixes the whole class: before committing any cross-wall sentence, ask *is this a gated fact, a
cited theorem, or an analogy?* — and if analogy, say "analogy." This synthesis is written under that rule; its taxonomy
is tagged a lens, its parallels tagged analogies, its facts anchored to KATs or citations.

---

## 6. The complete cross-wall ledger

| Wall | Core | Core *kind* | Best general bound | Island (VERIFIED/PROVEN III) | KATs |
|---|---|---|---|---|---|
| Parity / μ-calc | parity ∈ P? | OPEN — local placement (NP∩coNP) | quasi-poly | bounded-`d`/1-player; games=logic; control-blindness | 1848–1862 |
| SAT | P vs NP | OPEN — *is* the grand question (NP-complete) | exponential (ETH conj.) | Schaefer six classes; NP/self-reducible | 1863–1867 |
| Confluence | decide confluence | OBSTRUCTED (undecidable) | — (decidable on island) | Newman (terminating ⇒ decidable) | 1868–1869 |
| Graph iso | GI ∈ P? | OPEN — local placement (NP∩coAM) | quasi-poly | 1-WL complete for trees; higher-order fix | 1870–1872 |
| Lattice rep | FLRP | OPEN — non-complexity (universal algebra) | — | `Con(V₄)=M₃`; `Π_n` is a lattice | 1873–1874 |
| Primality/factoring | factoring ∈ classical P? | OPEN — local placement, **quantum-cracked** (Shor) | sub-exp (NFS) | primality ∈ P (fell); factoring NP/self-reducible | 1875–1876 |
| Communication complexity | log-rank conjecture | **CLIMBED** (D(EQ)=n+1 proven) + open face | — | EQ fooling-set proven lower bound | 1877 |
| Ramsey theory | R(5,5), … | OPEN — open-by-explosion (combinatorics) | — | `R(3,3)=6` by exhaustion | 1878 |

**The asset thesis.** Each wall, mapped to its limit, is a grounded, cashable asset: its islands are *tools* (poly
procedures verified in III), its barriers are *constraints* (what provably cannot work), its core is a *precisely
bounded frontier* (open or obstructed, never faked). Mapped *together*, the five become more: a demonstrated reusable
template (§1), a taxonomy that sorts new problems before you start (§2), a catalogue of the distinct *kinds* of
essential difficulty (§3), and a set of honest cross-wall analogies (§4) — all under one instrument of calibrated
honesty (§5). That collected structure — not any single wall — is the compounding return on pushing each wall to, and
proving, its limit.
