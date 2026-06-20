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

- **Two kinds of core.**
  - **OPEN-core** — the frontier is *unknown*: parity (parity∈P?), SAT (P vs NP), GI (GI∈P?), lattice (FLRP).
  - **OBSTRUCTED-core** — the frontier is a *proven impossibility*: confluence (general-TRS confluence undecidable);
    and, from the grail ledger, Rice/halting, impredicative ordinal analysis.
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
  randomized-poly; LP from poly), so the eventual-P precedent is suggestive, not favored.
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

| Wall | Core | Core status | Best general bound | Island (VERIFIED/PROVEN III) | KATs |
|---|---|---|---|---|---|
| Parity / μ-calc | parity ∈ P? | OPEN | quasi-poly | bounded-`d`/1-player; games=logic; control-blindness | 1848–1862 |
| SAT | P vs NP | OPEN | exponential (ETH conj.) | Schaefer six classes; NP/self-reducible | 1863–1867 |
| Confluence | decide confluence | OBSTRUCTED (undecidable) | — (decidable on island) | Newman (terminating ⇒ decidable) | 1868–1869 |
| Graph iso | GI ∈ P? | OPEN | quasi-poly | 1-WL complete for trees; higher-order fix | 1870–1872 |
| Lattice rep | FLRP | OPEN | — | `Con(V₄)=M₃`; `Π_n` is a lattice | 1873–1874 |

**The asset thesis.** Each wall, mapped to its limit, is a grounded, cashable asset: its islands are *tools* (poly
procedures verified in III), its barriers are *constraints* (what provably cannot work), its core is a *precisely
bounded frontier* (open or obstructed, never faked). Mapped *together*, the five become more: a demonstrated reusable
template (§1), a taxonomy that sorts new problems before you start (§2), a catalogue of the distinct *kinds* of
essential difficulty (§3), and a set of honest cross-wall analogies (§4) — all under one instrument of calibrated
honesty (§5). That collected structure — not any single wall — is the compounding return on pushing each wall to, and
proving, its limit.
