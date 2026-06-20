# THE PRIMALITY / FACTORING WALL — A Formal Map

The sixth wall, parity-grade — and the one that **pays a debt**. Across the parity, SAT, GI, and lattice docs, a
load-bearing precedent is cited: *"NP∩coNP problems with a good upper bound have historically fallen to P (primality,
LP)."* Here that precedent stops being a bare citation and becomes a **gated asset** — and, uniquely, this one wall
instantiates **both outcomes** the precedent invokes: a twin that **fell to P** (primality) and a twin that **has not**
(factoring).

**Proof-status legend** as the parity capstone. **Honesty invariant (math-olympiad #4):** the island is a theorem
(primality ∈ P); the open twin's NP/self-reducibility facts do not put factoring in classical P and make no such claim.

---

## 1. Object and ground truth

Integers; the **primality** decision ("is n prime?") and the **factoring** problem ("find a nontrivial factor of n").
The **oracle**: brute trial division (`brute_prime`, `brute_smallest_factor`). The island solver (Miller–Rabin) and the
decision-only self-reduction are checked against it.

---

## 2. The twin that FELL — primality ∈ P (the domino, grounded)

- **VERIFIED (`1875`) + CITED (AKS 2002).** Deterministic Miller–Rabin with the fixed base set `{2,3,5,7}` is exact for
  all `n < 3.2·10⁹`; it agrees with brute trial division on every `n < 60 000` (primes and composites). Primality is in
  **P** — unconditionally (AKS 2002), and randomized-poly since the 1970s (Miller–Rabin / Solovay–Strassen).
- **Why it is *the* precedent.** Primality was long the textbook **NP∩coNP** problem with a *good upper bound*: Pratt
  certificates for "prime," a factor for "composite," and a randomized-poly test. It **fell to P**. This is exactly the
  domino the parity/GI cross-wall analogy cites — now a gated island, not a citation.
- **The honest temper (recurring across the program).** Primality fell from a **randomized-poly** upper bound; parity
  and GI sit at **quasi-polynomial** — strictly weaker. So the precedent is *suggestive, not decisive*: the problems
  that fell had stronger upper bounds than parity/GI have today.

---

## 3. The twin that has NOT — factoring (the open core, with a quantum twist)

- **VERIFIED (`1876`).** Factoring is in **NP** (a nontrivial factor is a poly-checkable witness) and is
  **self-reducible**: a binary search over the decision oracle "*does n have a factor in [2,k]?*" recovers the smallest
  prime factor in `O(log n)` oracle calls (the no→yes threshold *is* the smallest factor) — confirmed == brute on every
  composite `< 6000`.
- **The structural placement (CITED).** The decision form is in **NP∩coNP** (NP: a factor; coNP: the full prime
  factorization, checkable *because* primality ∈ P, §2). Factoring is **not known in P** (RSA security rests on its
  classical hardness) and **not NP-complete** unless NP=coNP.
- **The quantum cell (CITED, Shor 1994).** Factoring ∈ **BQP** — a *quantum* polynomial algorithm. So factoring has
  fallen, but only to **quantum** P; its **classical** core stays open. This is a kind of resolution no other wall here
  shows: parity, GI, and SAT have **no known quantum advantage**.

---

## 4. Cross-wall position — the wall that grounds the precedent and adds the quantum split

This wall does two things no other does:

1. **It grounds the precedent.** Every cross-wall sentence of the form "parity/GI sit near the NP∩coNP-with-good-bound
   coordinates from which problems fell to P" now points at a gated island (`1875`) and its still-open twin (`1876`),
   rather than a citation. The precedent is *instantiated*: one twin fell, the other did not, in the same number theory.
2. **It adds a quantum cell to the taxonomy.** The intermediate band (NP∩coNP, not NP-complete, classically open) splits
   by quantum status:
   - **quantum-cracked, classically open**: factoring, discrete log (BQP via Shor) — period-finding structure;
   - **no known quantum advantage**: parity, GI (no hidden-subgroup/period structure — `III-PARITY-RESIDUAL-HOPES.md`
     avenue N).
   So "intermediate candidate" is not monolithic: factoring is intermediate-and-quantum-easy; parity/GI are
   intermediate-and-quantum-hard. The eventual-classical-P question is genuinely different for the two sub-kinds.

| Problem | NP∩coNP? | classical status | quantum (BQP)? |
|---|---|---|---|
| **primality** | yes | **in P** (fell, AKS) | n/a (already P) |
| **factoring** | yes | **OPEN** | **yes** (Shor) |
| **parity** | yes (`1860`) | OPEN, quasi-poly | no known advantage |
| **GI** | yes (coAM) | OPEN, quasi-poly | no known advantage |

---

## 5. The ledger

| # | Statement | Status | KAT |
|---|---|---|---|
| Isl | primality ∈ P: deterministic Miller–Rabin {2,3,5,7} == brute | **VERIFIED (III)** + CITED (AKS) | `1875` |
| NP | factoring ∈ NP (poly-checkable factor witness) | **VERIFIED (III)** | `1876` |
| SR | factoring self-reducible (search ≤ decision, binary search) | **VERIFIED (III)** | `1876` |
| ∩ | factoring decision ∈ NP∩coNP (coNP via primality ∈ P) | CITED + (`1875`) | — |
| BQP | factoring ∈ BQP (quantum poly) | CITED | Shor 1994 |
| O | **factoring ∈ classical P?** | **OPEN** | the wall |

**Bottom line.** The primality/factoring wall is the precedent the whole cross-wall narrative leans on, made concrete:
primality is a **gated** domino that fell to P (`1875`), factoring its self-reducible NP∩coNP **open** twin (`1876`) that
fell only to *quantum* P. It grounds "good-upper-bound NP∩coNP problems fall to P" (honestly tempered — they fell from
*stronger* bounds than parity/GI have), and it splits the intermediate band by quantum status — a cell the other five
walls do not occupy. Six walls mapped; this one converts the load-bearing citation under all of them into an asset.
