# THE RAMSEY WALL — A Formal Map

The eighth wall (pure combinatorics), parity-grade. It extends the program's *reach* into a domain with no algorithm
to verify against — its island is a **complete exhaustive computation**, and its boundary is **combinatorial
explosion** rather than a complexity class or an undecidability reduction.

**Proof-status legend** as the parity capstone. **Honesty invariant (math-olympiad #4):** R(3,3)=6 is a theorem
re-established by exhaustion; the open core (R(5,5), …) is exactly what the explosion forbids exhausting.

---

## 1. Object and ground truth

The **Ramsey number** `R(k,k)` is the least `N` such that *every* 2-colouring of the edges of the complete graph `K_N`
contains a monochromatic `K_k`. The **oracle** is exhaustive enumeration of the `2^{C(N,2)}` colourings — which is the
ground truth *and* the wall: it is feasible only for tiny `N`.

---

## 2. The island — R(3,3) = 6 (PROVEN by exhaustion, `1878`)

Two-sided, both gated:
- **`R(3,3) > 5`** — exhibit a 2-colouring of `K₅` with **no** monochromatic triangle: the **pentagon** (red) +
  **pentagram** (blue). Verified: no triangle is monochromatic.
- **`R(3,3) ≤ 6`** — **exhaustively** check all `2¹⁵ = 32768` colourings of `K₆`: **every one** contains a
  monochromatic triangle (zero exceptions).
- Hence **`R(3,3) = 6`** — the smallest Ramsey number (the "party problem": among any 6 people, 3 mutual acquaintances
  or 3 mutual strangers). `R(4,4)=18` is also known (CITED); both are islands reachable by structured search.

---

## 3. The boundary and the open core — explosion

- **The boundary is COMBINATORIAL EXPLOSION.** Colourings of `K_N` number `2^{C(N,2)}`: `K₆` has `2¹⁵` (exhaustible),
  `K₁₈` has `2¹⁵³`, `K₄₃` has `2^{903}`. The island ends exactly where exhaustion stops being feasible. The "essential
  precondition" of this wall is **feasibility of exhaustion** — a boundary unlike any prior wall's (not players, clause
  structure, termination, depth, finiteness, or a complexity class — pure search-space size).
- **OPEN core.** `R(5,5)` is **OPEN** — known only to lie in `[43, 48]`; `R(6,6) ∈ [102,160]`; all larger diagonal
  Ramsey numbers open. Erdős's parable captures the wall: if aliens demanded `R(5,5)` we should marshal all computers to
  find it, but for `R(6,6)` we should attack the aliens — exhaustion is hopeless and no formula is known.

---

## 4. Cross-wall position — a new island flavor and a new boundary

This wall sharpens two cross-wall axes:
- **Island flavor.** Prior islands were *algorithms verified == oracle* (2-SAT solver, 1-WL, Miller–Rabin). Ramsey's
  island is a **complete exhaustive proof** (`R(3,3)=6` by checking *all* `2¹⁵` cases). Same template slot ("the
  tractable/decidable island"), different texture: the island *is* the finite computation, not an algorithm that beats
  it.
- **Boundary kind.** The "essential precondition" catalogue gains a seventh entry — *feasibility of exhaustion* — joining
  control/alternation, clause-structure, termination, structural-depth, finiteness, and (climbed) proof-existence. The
  wall is OPEN, but **open-by-explosion**, not open-by-complexity-class: there is no class question, only a number whose
  search space is astronomical and whose closed form is unknown.

---

## 5. The ledger

| # | Statement | Status | KAT |
|---|---|---|---|
| Isl | `R(3,3) = 6` (K₅ good colouring + all `2¹⁵` K₆ colourings have a mono triangle) | **PROVEN (III)** | `1878` |
| R44 | `R(4,4) = 18` | CITED | classical |
| Bd | explosion: `2^{C(N,2)}` colourings — exhaustion infeasible past tiny `N` | (structural) | — |
| O | **`R(5,5)`, `R(6,6)`, … unknown** | **OPEN** | the wall |

**Bottom line.** The Ramsey wall extends the program into pure combinatorics: its island is the *exhaustive* theorem
`R(3,3)=6` (`1878`), its boundary the bare combinatorial explosion `2^{C(N,2)}`, its core the famously open `R(5,5)`.
It adds an exhaustion-island flavor and an open-by-explosion boundary to the taxonomy — the template holds even where
there is no algorithm to race, only a finite computation that runs out of room. Eight walls, three kinds of core, and a
boundary catalogue that now spans seven distinct essential preconditions.
