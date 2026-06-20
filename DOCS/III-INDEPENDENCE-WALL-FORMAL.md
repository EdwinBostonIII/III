# THE INDEPENDENCE WALL (Goodstein) — A Formal Map, and a Falsifier for the Template

The tenth wall is deliberately a **falsifier**, not a tenth confirmation: a problem chosen to make the program's
island/boundary/core template *strain or break*. The verdict is the most valuable kind — the template **partly
generalizes and partly breaks**, and the break is informative.

**Proof-status legend** as the parity capstone. **Honesty invariant (math-olympiad #4):** small cases terminating is a
gated fact; Goodstein's theorem and its independence are CITED; the value here is the *falsifier verdict*, stated plainly.

---

## 1. Object and the independence

The **Goodstein sequence** of `m`: start `v=m` at base `b=2`; each step write `v` in *hereditary* base `b` (every exponent
itself in hereditary base `b`), replace every `b` by `b+1`, then subtract 1; increment `b`. **Goodstein's theorem**
(1944): every such sequence reaches 0. **Kirby–Paris (1982, CITED):** this theorem is **true** (provable using
transfinite induction up to the ordinal `ε₀`) but **unprovable in Peano Arithmetic** — PA proves "`G(m)` terminates" for
each *fixed* `m`, yet not the *universal* "`∀m, G(m)` terminates."

---

## 2. The falsifier test — does island/boundary/core apply?

- **ISLAND — yes, gated (`1880`).** Small Goodstein sequences terminate: `G(1), G(2), G(3)` reach 0 in finitely many
  steps, computed exactly via the hereditary-base bump-and-subtract. The tractable island is real and verified.
- **BOUNDARY — it STRAINS (the informative break).** In every prior wall the boundary was a *computational/structural*
  quantity (control, clause-structure, termination, depth, finiteness, fooling-sets). Here the boundary is
  **proof-theoretic**: PA settles every *instance* but not the *universal*; the dividing line is *proof strength*
  (PA vs `ε₀`-induction). The template's "boundary" slot still has an occupant, but its **nature changes** — from "what
  makes computation hard" to "what proof strength is required." That shift is the template's first revealed limit: its
  "boundary" was implicitly computational, and independence forces it to mean something else.
- **CORE — a genuinely new, EARNED kind: INDEPENDENT.** The core is neither OPEN (the truth *is* settled — true), nor
  OBSTRUCTED (it is not an undecidable computation — every instance is decidable, and the universal is true), nor CLOSED
  *in the base theory* (PA cannot prove it). It is **INDEPENDENT**: truth settled by a stronger theory, provability
  relative to the base theory. This cell is *earned*, not minted — it is anchored to a genuine, named phenomenon
  (Kirby–Paris), unlike the over-minted "open-by-explosion."
- **Why exhaustion can't substitute for the proof (gated `1880`).** The values grow **unboundedly**: a taller-tower
  start, `16 = 2^{2^2}`, exceeds `2⁶⁴` within a couple of steps (overflow detected). So no fixed-width exhaustion tracks
  all sequences to 0; the universal genuinely needs a *proof*, and that proof needs strength beyond PA. (The famous
  `G(4)` also diverges, but only ~quadratically in the base, staying within `u64` for `~3·10⁹` steps — hence `16` to
  exhibit the growth quickly.)

---

## 3. The verdict — what the falsifier teaches

The template **does not fully break, and does not fully hold** — which is exactly the credible outcome:
- It **extends**: island (small cases) and core (a new INDEPENDENT cell) both apply and are gated/cited.
- It **strains**: the *boundary* concept, computational in all nine prior walls, becomes *proof-theoretic* here. The
  template silently assumed the boundary was about computational difficulty; independence shows that assumption was a
  hidden parameter, not a universal feature.

A template with a *found limit* is more trustworthy than one with only successes. The Goodstein wall earns the program a
fourth core kind (**INDEPENDENT**) *and* marks where the template's "boundary" slot stops being computational — a single
probe that both grew the taxonomy honestly and bounded the method's reach.

---

## 4. The ledger

| # | Statement | Status | KAT |
|---|---|---|---|
| Isl | `G(1),G(2),G(3)` terminate (hereditary-base computation reaches 0) | **VERIFIED (III)** | `1880` |
| Grow | Goodstein values are unbounded (`G(16)` exceeds `2⁶⁴` in a couple steps) | **VERIFIED (III)** | `1880` |
| Thm | every Goodstein sequence terminates | CITED | Goodstein 1944 |
| Ind | Goodstein's theorem is independent of PA (provable with `ε₀`-induction) | CITED | Kirby–Paris 1982 |
| Core | the universal statement | **INDEPENDENT** (true, unprovable in PA) | `1880` + CITED |

**Bottom line.** The independence wall is the program's falsifier: island/boundary/core *partly* applies — the island
is gated (`1880`), the core is a new **earned** kind (INDEPENDENT, anchored to Kirby–Paris), but the **boundary goes
proof-theoretic**, revealing that the template's boundary was implicitly a computational notion. Ten walls; the tenth is
the one that found a limit — which is worth more than a tenth success, and is the honest place to have arrived.
