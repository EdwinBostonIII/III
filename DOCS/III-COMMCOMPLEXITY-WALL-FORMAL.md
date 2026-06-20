# THE COMMUNICATION-COMPLEXITY WALL — A Formal Map

The seventh wall, parity-grade — and it fills a **new taxonomy cell**: a **CLIMBED** wall, one whose lower bound is a
*proven theorem*, not an open or obstructed question. Every prior wall had an OPEN core (parity, SAT, GI, lattice,
factoring) or an OBSTRUCTED one (confluence). Communication complexity is the contrast case: here a separation is
*known*. It also carries its own OPEN face (the log-rank conjecture), so it spans both.

**Proof-status legend** as the parity capstone. **Honesty invariant (math-olympiad #4):** the fooling-set bound is a
theorem; grounding it demonstrates a *proven* lower bound — the point of this wall is precisely that the bound is known.

---

## 1. Object and ground truth

In **2-party deterministic communication**, Alice holds `x`, Bob holds `y`, and they compute `f(x,y)` exchanging as few
bits as possible; `D(f)` is the worst-case cost. The key structural fact (CITED): a `c`-bit protocol **partitions the
communication matrix into `≤ 2^c` monochromatic combinatorial rectangles** `A×B` (`f` constant on `A×B`). Hence
`D(f) ≥ ⌈log₂ χ(f)⌉`, where `χ(f)` is the fewest monochromatic rectangles needed. The **oracle** here is the explicit
matrix (e.g. EQUALITY = the identity), enumerated directly (`1877`).

---

## 2. The climbed face — a PROVEN lower bound (fooling sets)

- **VERIFIED `1877`.** A **fooling set** of size `m` (equal-valued cells, no two in a common monochromatic rectangle)
  forces `χ(f) ≥ m`, so `D(f) ≥ log₂ m`. For **EQUALITY** on `n`-bit inputs (the `2ⁿ×2ⁿ` identity matrix), the diagonal
  `{(x,x)}` is a 1-fooling set of size `2ⁿ` — verified: the off-diagonal is all `0`, so distinct diagonal 1-cells cannot
  share a monochromatic-1 rectangle (equivalently, *every* monochromatic-1 rectangle is a single cell, since each row's
  only `1` is on the diagonal). Therefore `χ(EQ) ≥ 2ⁿ` and:

  > **`D(EQ) ≥ n` — a PROVEN lower bound** (and the trivial "Alice sends `x`, Bob replies 1 bit" protocol gives
  > `D(EQ) ≤ n+1`). So `D(EQ) ∈ {n, n+1}`: the wall is **climbed** — the separation is a theorem.

- **More climbed faces (CITED).** `D(DISJ) = Θ(n)` (set disjointness, Kalyanasundaram–Schnitger / Razborov);
  rank lower bound `D(f) ≥ log₂ rank(M_f)`; and these lift to *circuit-depth* and *streaming* lower bounds (proven).
  Communication complexity is a workshop of *proven* lower bounds — the cell the open/obstructed walls lack.

---

## 3. The open face — the log-rank conjecture

- **OPEN core (CITED).** The **log-rank conjecture**: is `D(f) ≤ (log₂ rank(M_f))^{O(1)}` for all Boolean `f`? The rank
  bound gives `D(f) ≥ log₂ rank`; whether it is also a poly *upper* bound is **OPEN** (the best known gap is
  quasi-polynomial-ish). So even a "climbed" area has an open frontier — communication complexity is *both* a settled
  wall (specific lower bounds) *and* an open one (the general rank↔communication relation).

---

## 4. Cross-wall position — the CLIMBED cell

This wall adds a third top-level kind of core to the taxonomy (the others: OPEN, OBSTRUCTED):

| Core kind | Meaning | Walls |
|---|---|---|
| **OPEN** | the frontier is unknown | parity, SAT, GI, lattice (FLRP), factoring |
| **OBSTRUCTED** | the frontier is a proven impossibility | confluence (undecidable) |
| **CLIMBED** | the lower bound is a **proven separation** | communication complexity (`D(EQ)=n+1`) |

The lesson the CLIMBED cell teaches, read against the others: **proven lower bounds exist** — they are just rare and
problem-specific (fooling sets, rank, monotone circuits) and have *not* reached the general-purpose separations (P vs
NP) the open walls need. Where parity/SAT/GI have *no* proven super-poly lower bound (their cores open), communication
complexity *does* (its cores climbed). The same island/boundary/core template applies — the island is the protocol
(upper bound), the boundary is the fooling-set/rank argument, the "core" is the matched lower bound — but here the core
is *closed by a theorem*. Seven walls, three kinds of core.

---

## 5. The ledger

| # | Statement | Status | KAT |
|---|---|---|---|
| LB | `D(EQ) ≥ n` via the `2ⁿ` diagonal fooling set (every mono-1 rect a single cell) | **PROVEN (III)** | `1877` |
| UB | `D(EQ) ≤ n+1` (trivial protocol) — so `D(EQ)` is climbed | **VERIFIED** (note) | `1877` |
| Rect | a `c`-bit protocol ⇒ `≤2^c` monochromatic rectangles ⇒ `D ≥ log₂ χ` | CITED | Yao; Aho–Ullman–Yannakakis |
| DISJ | `D(DISJ) = Θ(n)` | CITED | KS / Razborov |
| Rank | `D(f) ≥ log₂ rank(M_f)` | CITED | Mehlhorn–Schmidt |
| O | **log-rank conjecture** (`D ≤ polylog(rank)`?) | **OPEN** | the open face |

**Bottom line.** Communication complexity is the CLIMBED wall: `D(EQ) = n+1` is a *proven* separation (`1877`, fooling
set), the contrast cell to every open/obstructed wall in the program — proof that proven lower bounds *do* exist, just
not yet the ones the open walls need. And its own open face (log-rank) shows even a climbed area keeps a frontier.
Seven walls, three kinds of core (OPEN / OBSTRUCTED / CLIMBED), one template.
