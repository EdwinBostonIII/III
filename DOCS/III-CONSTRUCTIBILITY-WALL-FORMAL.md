# THE CONSTRUCTIBILITY WALL — A Formal Map

The ninth wall (classical geometry / Galois theory), parity-grade. It is a **SETTLED** wall — problems open since
antiquity, *resolved* (negatively) — and it carries the program's sharpest cross-wall insight: **a wall is resolved
when someone finds the right invariant; the OPEN walls stay open partly because their natural invariants provably fail.**

**Proof-status legend** as the parity capstone. **Honesty invariant (math-olympiad #4):** the impossibilities are
theorems (Wantzel 1837); verifying the degree-3 irreducibility grounds the invariant that resolves them.

---

## 1. Object, ground truth, and the resolving invariant

Straightedge-and-compass constructions; a real number is **constructible** iff it lies in a tower of quadratic
extensions of `ℚ`. The **resolving invariant** (CITED, Wantzel 1837): `α` constructible `⟹ [ℚ(α):ℚ]` is a **power of 2**.
The **oracle** is exact rational arithmetic on minimal polynomials (`1879`).

---

## 2. The settled core — two millennia-old impossibilities (PROVEN, `1879`)

- **Doubling the cube** needs `2^{1/3}`, a root of `x³−2`. Rational-root theorem: candidates `p/q` with `p∣2, q∣1`; none
  is a root (`1,−1,8,−8` are never `2`), so `x³−2` is irreducible and `[ℚ(2^{1/3}):ℚ]=3`. Since `3` is **not a power of
  2**, `2^{1/3}` is not constructible — **the cube cannot be doubled.** Verified by exact integer evaluation.
- **Trisecting 60°** needs `cos 20°`, a root of `8x³−6x−1` (from `cos 3θ = 4cos³θ−3cosθ`, `cos 60°=½`). Candidates `p/q`
  with `p∣1, q∣8`; the homogenized test `8p³−6pq²−q³` is nonzero for all, so the cubic is irreducible and
  `[ℚ(cos20°):ℚ]=3` — not a power of 2 — so **60° cannot be trisected.** Verified.
- **Squaring the circle** is impossible too — `π` is transcendental (Lindemann 1882, CITED), so `√π ∉` any finite
  extension. And **Gauss–Wantzel**: a regular `n`-gon is constructible iff the odd part of `n` is a product of distinct
  Fermat primes (`3,5,17,257,65537`).

The island (the *positive* side): constructible numbers — anything of degree `2^k` (bisections, `√`, the regular 17-gon
via the Fermat prime 17). The boundary is exactly the **degree-power-of-2 invariant**.

---

## 3. Cross-wall position — resolution IS finding the right invariant

This is the wall that explains the others. Set it beside the OPEN walls:

| Wall | The deciding quantity | Status of "the right invariant" |
|---|---|---|
| **Constructibility** | field degree `[ℚ(α):ℚ]` | **FOUND** (Wantzel: `=2^k`) ⇒ wall **resolved** |
| Parity | control / who-chooses | cheap graph invariant **provably fails** (T2, `1848`) ⇒ **open** |
| Graph iso | higher-order structure | 1-WL **provably fails** on regular graphs (`1871`) ⇒ **open** |
| SAT | — | no invariant separates P from NP-complete (the grand question) ⇒ **open** |

The pattern (an **analogy/observation**, tagged — not a theorem): a wall *falls* when the right invariant is found that
exactly captures its essential quantity (Wantzel's degree for constructibility; sign of cycle-mean for one-player
parity, `1850`). A wall *stays open* when the natural cheap invariants are *proven not to* capture it — which is
precisely what the parity control-blindness barrier (`1848`) and the GI 1-WL boundary (`1871`) establish. So the
control-blindness and 1-WL **negative** results are not just obstacles; read against constructibility they are evidence
about *why* those walls resist: the cheap invariant that resolved geometry has no analogue that works there (yet). This
reframes the whole program's negative results as **measurements of how far the resolving invariant must reach.**

---

## 4. The ledger

| # | Statement | Status | KAT |
|---|---|---|---|
| Inv | constructible ⇒ `[ℚ(α):ℚ]` a power of 2 | CITED | Wantzel 1837 |
| Cube | `x³−2` irreducible (deg 3) ⇒ doubling the cube impossible | **PROVEN (III)** | `1879` |
| Tri | `8x³−6x−1` irreducible (deg 3) ⇒ trisecting 60° impossible | **PROVEN (III)** | `1879` |
| Circ | `π` transcendental ⇒ squaring the circle impossible | CITED | Lindemann 1882 |
| GW | regular `n`-gon constructible ⇔ odd part = product of distinct Fermat primes | CITED | Gauss–Wantzel |
| Core | the classical constructions | **SETTLED (resolved-negative)** | `1879` |

**Bottom line.** The constructibility wall is SETTLED — three antiquity-old problems proven impossible by one algebraic
invariant (degree a power of 2), two of them gated here by exact rational-root irreducibility (`1879`). Its lesson is
the program's deepest cross-wall reading: **resolving a wall is finding the invariant that captures its essential
quantity; the open walls (parity, GI) are open partly because their cheap invariants are *proven* not to** (`1848`,
`1871`). Nine walls; the negative results across them are now legible as a map of how far each wall's resolving
invariant must reach.
