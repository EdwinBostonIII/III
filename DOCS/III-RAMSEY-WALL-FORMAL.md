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

## 3. The boundary and the open core

- **The boundary is METHODOLOGICAL, not search-size (advisor-corrected).** It is tempting to say the boundary is
  "feasibility of exhaustion" — but that is *false by the known island itself*: `R(4,4)=18` was **not** found by
  exhausting `2^{C(18,2)} = 2¹⁵³` colourings; it is Greenwood–Gleason's *counting* argument (upper bound) plus the
  Paley graph on 17 vertices (lower-bound *construction*). So the island extends **past** exhaustion-feasibility. The
  real boundary is the absence, at scale, of **both** a good construction (to push the lower bound) **and** a good
  counting argument (to pull the upper bound) — a methodological gap, not a search-space-size threshold.
- **OPEN core (the same kind as parity/SAT/GI/lattice).** `R(5,5)` is **OPEN** — known only to lie in `[43, 48]`;
  `R(6,6) ∈ [102,160]`; all larger diagonal Ramsey numbers open. Erdős's parable captures the difficulty: if aliens
  demanded `R(5,5)` we should marshal all computers, but for `R(6,6)` we should attack the aliens — neither construction
  nor counting is good enough at that scale.

---

## 4. Cross-wall position — a shared OPEN cell, one distinctive texture

Ramsey lands in the **same OPEN cell** as parity/SAT/GI/lattice/factoring — and that convergence is the point (it is
evidence of the template's universality, not a defect to be dressed up as a new cell). Its one genuinely distinctive
*texture* is the island flavor:
- **Island flavor (the real novelty).** Prior islands were *algorithms verified == oracle* (2-SAT solver, 1-WL,
  Miller–Rabin); Ramsey's gated island (`R(3,3)=6`) is a **complete exhaustive proof** — the island *is* the finite
  computation, not an algorithm that beats it. (Note: the *cited* island `R(4,4)=18` is **not** exhaustive — it is
  counting + construction — so even within this wall the island method is mixed; see §3.)
- **Not a new cell.** Earlier drafts called this "open-by-explosion"; that over-mints — the boundary is methodological
  (§3), and the core is plain OPEN. The honest reading: the template's island/boundary/core shape applies, and Ramsey is
  the *fifth* wall to land in the OPEN cell — repetition, not novelty, is the finding.

---

## 5. The ledger

| # | Statement | Status | KAT |
|---|---|---|---|
| Isl | `R(3,3) = 6` (K₅ good colouring + all `2¹⁵` K₆ colourings have a mono triangle) | **PROVEN (III)** | `1878` |
| R44 | `R(4,4) = 18` | CITED | classical |
| Bd | methodological: no good construction *and* no good counting at scale (exhaustion fails even sooner) | (structural) | — |
| O | **`R(5,5)`, `R(6,6)`, … unknown** | **OPEN** | the wall |

**Bottom line.** The Ramsey wall extends the program into pure combinatorics: its gated island is the *exhaustive*
theorem `R(3,3)=6` (`1878`); the cited island `R(4,4)=18` is *non*-exhaustive (counting + construction), so the boundary
is **methodological**, not search-size; its core is the famously open `R(5,5)`. Its one distinctive contribution is the
*exhaustive*-island flavor for the smallest case; otherwise it lands squarely in the **OPEN** cell shared with
parity/SAT/GI/lattice/factoring — and that shared landing, not a minted new cell, is what it adds: another confirmation
of the template's reach, now into a domain with no algorithm to race.
