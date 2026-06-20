# THE GRAPH-ISOMORPHISM WALL — A Formal Map

The fourth wall, parity-grade. GI is the *closest structural twin* of the parity wall — both quasi-polynomial,
NP-with-a-good-witness, and not believed NP-complete. Mapping it does not just add a wall; it reveals a **structural
isomorphism between two walls**, which is the highest-value cross-wall asset so far.

**Proof-status legend** as the parity capstone. **Honesty invariant (math-olympiad #4):** the islands and the refuted
cheap invariant say nothing about the open core (GI ∈ P?).

---

## 1. Object and ground truth

Two graphs `G, H` on `n` vertices are **isomorphic** if a vertex permutation `π` carries `G`'s edges exactly onto `H`'s.
The **oracle**: brute search over all `n!` permutations (`brute_iso` in the KATs, via `next_permutation`). The island
solver (color refinement) is checked against it.

---

## 2. The tractable island, and its sharp boundary

- **Color refinement / 1-WL is complete for trees (island, VERIFIED `1870`).** The 1-dimensional Weisfeiler–Leman
  algorithm recolors each vertex by `(its color, the multiset of neighbor colors)` to a fixpoint; two graphs are
  1-WL-equivalent iff their disjoint union's two halves carry the same color histogram. 1-WL is always **sound**
  (distinguishable ⇒ non-isomorphic) and, for **trees**, **complete**: 1-WL-equivalent ⟺ isomorphic — verified ==
  brute on 4000 random tree pairs. So GI for trees is **polynomial**.
- **The boundary (PROVEN `1871`).** 1-WL is **incomplete on general graphs**: `K₃,₃` and the triangular prism are both
  3-regular, 1-WL-**equivalent**, yet **non-isomorphic**. A graph invariant collapses exactly the distinction that
  matters — the GI twin of parity's **control-blindness barrier** (`1848`).
- **The fix costs more (VERIFIED `1872`).** A higher-order invariant escapes the blind spot: the **triangle count** (a
  2nd-order invariant, the kind 2-WL captures) separates `K₃,₃` (0 triangles) from the prism (2). You see what the cheap
  invariant cannot — by paying for more structure (`k`-WL, rising with `k`).

---

## 3. The structural core (NP, intermediate candidate) — VERIFIED + CITED

- **GI ∈ NP (VERIFIED `1872`).** An isomorphism (a permutation) is a poly-checkable YES-witness.
- **GI ∈ coAM (CITED, Goldwasser–Sipser).** Graph *non*-isomorphism has a 2-round interactive proof, so GI is **not
  NP-complete unless the polynomial hierarchy collapses** (Boppana–Håstad–Zachos).
- **GI ∈ quasi-polynomial (CITED, Babai 2016).** `n^{O((log n)^c)}` — the same standing as parity's Calude bound.
- **OPEN core: GI ∈ P?** Like parity, an open question with a quasi-poly upper bound and no NP-completeness.

---

## 4. The structural parallel between the GI wall and the parity wall (an analogy, not a reduction)

This is the asset that two mapped walls give that one cannot — a *correspondence of complexity profiles*. It is an
**analogy across tagged facts**, not a reduction: parity ∈ NP∩coNP, GI ∈ NP∩coAM (not even the same closure), and
neither is known to reduce to the other. Each row is a gated/cited fact; the parallel is the pattern they suggest.

| Feature | **Parity** | **Graph Isomorphism** |
|---|---|---|
| open core | parity ∈ P? | GI ∈ P? |
| upper bound | quasi-polynomial (Calude 2017) | quasi-polynomial (Babai 2016) |
| NP witness | positional strategy (`1860`) | the isomorphism (`1872`) |
| not NP-complete unless… | NP=coNP (∈ NP∩coNP) | PH collapses (∈ coAM) |
| cheap invariant that **fails** | control-free graph invariant (`1848`/T2) | 1-WL color refinement (`1871`) |
| the failure mode | blind to *control* | blind to *higher-order structure* |
| the fix, at cost | control-preservation (Class II) | `k`-WL, `k>1` (`1872`) |
| placement | in-P-vs-intermediate **OPEN** | in-P-vs-intermediate **OPEN** |

The two walls share **the same complexity-profile shape**: a quasi-poly intermediate candidate whose cheap invariant
collapses the essential distinction, escapable only by a costlier higher-dimensional method, with the open core being
whether that cost can be brought down to P. This is a structural **analogy** (each row a tagged fact), **not** a
reduction — there is no known map either way. Two *independent* quasi-poly intermediate candidates (parity, GI)
materially strengthen the picture of a **populated NP middle** (Ladner, CITED: the band is non-empty iff P≠NP). They sit
**near** — but at a *weaker* "good upper bound" (quasi-polynomial) than — the dominoes that fell to P (primality fell
from *randomized*-poly → AKS; LP from poly → ellipsoid). So the eventual-P precedent is *suggestive but tempered*:
parity and GI have weaker upper bounds than primality/LP ever did. Whether they follow the dominoes to P, or anchor the
intermediate band, is exactly their open cores.

---

## 5. The ledger

| # | Statement | Status | KAT |
|---|---|---|---|
| I | 1-WL complete for trees (== brute iso) | **VERIFIED (III)** | `1870` |
| Bd | 1-WL incomplete on regular graphs (K₃,₃ vs prism) | **PROVEN (III)** | `1871` |
| H | higher-order invariant escapes the blind spot (triangles 0 vs 2) | **VERIFIED (III)** | `1872` |
| N | GI ∈ NP (poly-checkable isomorphism witness) | **VERIFIED (III)** | `1872` |
| AM | GI ∈ coAM ⇒ not NP-complete unless PH collapses | CITED | Goldwasser–Sipser; BHZ |
| QP | GI ∈ quasi-polynomial | CITED | Babai 2016 |
| ∥ | structural **parallel** (analogy, not a reduction): GI wall parallels parity wall (quasi-poly intermediate, cheap-invariant-fails, costly-fix) | tagged correspondence (analogy) | `1848`,`1860`,`1871`,`1872` |
| O | **GI ∈ P?** | **OPEN** | the wall |

**Bottom line.** GI is the parity wall's structural twin (by *analogy*): an OPEN-core, quasi-polynomial,
intermediate-candidate wall whose tractable island (trees, 1-WL) is bounded by a sharp boundary (1-WL fails on regular
graphs) that *is* a graph invariant's blind spot — the same shape as parity's control-blindness. Four walls mapped, and
the third and fourth (confluence, GI) reveal the cross-wall structure most sharply: walls come in *kinds* (OPEN-core vs
OBSTRUCTED-core — an organizing lens, not proven structure), and walls of the same kind can be *structurally parallel*
(parity ∥ GI — an analogy across tagged complexity-profile facts, not a reduction). The template compounds.
