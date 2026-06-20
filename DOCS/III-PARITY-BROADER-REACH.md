# The Broader Reach of the Parity Theorems — What They Do and Do Not Imply

The parity wall is not a self-contained puzzle. This document asks, rigorously, how far its theorems reach across
computation and mathematics — and, just as importantly, where the reach *stops*. The temptation here is grandiosity;
the discipline is to separate what is **proven** from what is **evocative**. Every claim below is tagged.

**Tag legend.**
- **THEOREM (III)** — established by a gated, oracle-checked KAT in this repository.
- **CITED** — a published, standard result (named), used but not reproven.
- **INTERPRETATION** — a defensible reading of the proven facts, but a *reading*, not a theorem.
- **SPECULATION** — suggestive, unproven, flagged as such.

The honest meta-point first: the reach is **real and significant**, but it is the reach of a *rigorous core* (equivalences
and obstructions), wrapped in interpretations that should not be mistaken for the core. Where the grand phrasing
("universal speed limit," "impassable canyon," "laws of hardness," "math is jagged") appears, it is tagged
INTERPRETATION/SPECULATION, sitting on top of theorems — not as a theorem.

---

## Reach 1 — The verification frontier (the μ-calculus is the canonical specification logic)

**The rigorous core.**
- **CITED.** The modal μ-calculus subsumes the standard branching- and linear-time specification logics: CTL, CTL\*,
  LTL, PDL each translate into it (Emerson–Lei; Dam). It is *the* canonical logic in which one writes "this reactive
  system never deadlocks / always eventually responds / is safe." Model-checking a temporal specification **is**
  evaluating a μ-formula on the system's state graph.
- **THEOREM (III), `1853`.** Solving a parity game and evaluating the (alternating) parity μ-formula are the *same*
  computation — a 4th independent solver (naive Emerson–Lei nested fixpoint) equals the game oracle on every game.
- **THEOREM (III), `1861`.** CTL embeds in the μ-calculus concretely: `EF`, `EG`, `EU` computed by their μ/ν fixpoints
  equal their independent *path semantics* on every Kripke structure — and each is a *single* fixpoint (no μ/ν
  alternation), so it converges in `≤ n` iterations (**polynomial**). CTL lives in the *alternation-free* fragment.

**What this licenses (THEOREM-level).** The complexity boundary of full (alternating) μ-calculus model-checking is
*identical* to the parity wall (they are the same problem, `1853`). Branching-time verification (CTL and the
alternation-free fragment) is **below** the wall — polynomial. The *open frontier* of program/protocol verification is
exactly the **alternation** that full μ adds, and that frontier *is* parity. The parity wall is therefore not a
separate curiosity; it is the same boundary that bounds the worst-case cost of the most expressive standard
verification logic.

**Where the reach stops (correcting the over-statement).** It is INTERPRETATION, *not* theorem, to call this "the
universal speed limit for guaranteeing technology is safe." Three honest caveats: (i) most *deployed* verification uses
the alternation-free / one- or two-priority fragments, which are **polynomial** (`1857`, `1861`) — the wall does not
slow them; (ii) the general upper bound is **quasi-polynomial** (Calude 2017, CITED), feasible at real scale, not
"millions of years"; (iii) "safety" in practice is a *worst-case* statement about a *specification formalism*, not
about all of engineering. The accurate claim: **the parity wall is the worst-case complexity frontier of the
most expressive standard model-checking logic, reached precisely by fixpoint alternation.** That is a large, true
statement; the "universal speed limit for all safe technology" is the INTERPRETATION wrapped around it.

---

## Reach 2 — The logic↔cryptography characteristic firewall

**The rigorous core.**
- **THEOREM (III), `1851`+`1862`.** The *canonical* algebraic bridge from the lattice-logic Boolean-ring face
  (characteristic 2) to the post-quantum / zk crypto rings fails — and the load-bearing reason is the **characteristic**,
  uniform across the whole deployed stack, not a `3329` coincidence. A unital ring hom char-2→`ℤ_m` forces `2 = 0`,
  contradicting `2≠0` in odd `ℤ_m` (equivalently: `𝔽₂={0,1}` is not a subring of `ℤ_m`, since `1+1=0` in `𝔽₂` but `=2≠0`
  here). This is *one* obstruction, viewed several ways, and it is **target-specific**: it vanishes at char 2 (`2=0` in
  `𝔽₂` itself). Verified for ML-KEM `3329`, Falcon `12289`, ML-DSA `8380417`, the Mersenne primes `2³¹−1` and `2⁶¹−1`,
  the STARK Goldilocks prime `2⁶⁴−2³²+1`, and the RSA composite `61·53`. *Honest demotion (advisor-audited):* the
  separate "idempotency" point — the only additive idempotent of `ℤ_m` is `0`, so `∨↦+` collapses — is **generic**, not a
  crypto firewall: `a+a=a ⟹ a=0` in *every* additive group (including `𝔽₂`), so it carries no information about
  characteristic or crypto and the modulus-sweep is meaningless for it; it only explains why the *naive* map `∨↦+` is
  trivially wrong. The whole result rests on the **characteristic**, which is what makes it deep: even the *principled*
  Stone bridge fails for the same reason.

**What this licenses (THEOREM-level, scoped).** A *single canonical algebraic key* unifying III's lattice logics with
its post-quantum cryptography is provably empty: the logic side is char 2, the entire deployed crypto stack is odd
characteristic, and the two natural morphism classes that would bridge them are obstructed uniformly. The obstruction
is *structural* (it is the characteristic), so it cannot be patched by choosing a different prime.

**Where the reach stops (correcting the over-statement).** It is INTERPRETATION, *not* theorem, to call this "an
impassable canyon between Truth and Secrets" that means "you cannot build a bridge between logic and cryptography." The
KATs rule out **two specific morphism classes**, not *all* relationships: III's weave still **simulates** `ℤ_q` as
Boolean circuits (a real, non-canonical relation — char-2 hardware computes char-q arithmetic every day). The accurate
claim: **the canonical *algebraic-invariant* unification is generically obstructed by characteristic; non-canonical
relations (simulation, compilation) are unaffected and routinely exist.** The "canyon" is the right picture for the
*algebraic-key* hope specifically; it is SPECULATION to extend it to a metaphysical separation of logic and secrecy.

---

## Reach 3 — The anatomy of intractability (structural, not just empirical)

**The rigorous core.**
- **THEOREM (III), `1848`/`1852`.** Control-blindness: parity is irreducibly a function of *who chooses*; any
  ownership-blind invariant is wrong (and its accuracy decays with size). A whole class of methods is dead *for a
  reason*, not just empirically.
- **THEOREM (III), `1855`.** The mean-payoff reduction's standard weight scheme is `(n+1)^d` — the hardness migrates
  into *exponential-magnitude numbers*; it does not vanish.
- **THEOREM (III), `1860`.** Parity is NP∩coNP (poly-checkable strategy witnesses both ways) — so the hardness is
  **not** NP-hardness: it is *not* NP-complete unless NP=coNP. (Where it actually sits — in P, or Ladner-intermediate —
  is itself **OPEN**; the NP∩coNP+quasi-poly profile is *near* both the still-open factoring/discrete-log *and*
  primality/LP, which *fell to P* — though from stronger upper bounds (randomized-poly/poly) than parity's quasi-poly,
  so the eventual-P precedent is tempered, not favored.)
- **CITED.** The dichotomy is exhaustive (formal map §4): every mechanism either discards control (provably wrong) or
  re-encodes it (inherits the open cost).

**What this licenses (THEOREM-level).** For parity *specifically*, we have a *structural* account of hardness, not a
"supercomputers choke" empirical one: we can name *what* makes it hard (control/alternation, `1848`), *where* the cost
hides in each reformulation (the numbers, `1855`; the certificate degree, `1847`; the universal-tree size, B1), and
*what bound* it sits under (∈ NP∩coNP — not NP-complete unless NP=coNP, `1860`). This is a worked, gated example of
*isolating the source* of a hardness rather than observing it.

**Where the reach stops (correcting the over-statement).** It is INTERPRETATION, *not* theorem, to call these "the
exact mathematical laws of why things are hard in our universe." The results are about *parity* (and its poly-time
equivalents). They are a *template* — control-essentiality and characteristic firewalls are the *kind* of structural
obstruction one can prove — but "the laws of hardness" is a generalization the KATs do not establish. The honest claim:
**parity's hardness is structurally explained, not merely observed — and the method (isolate the essential feature,
prove the lens-changes can't dissolve it) is reusable.** That is the genuine, bounded reach.

---

## The cumulative picture — is mathematics "jagged"?

**INTERPRETATION / SPECULATION.** The cumulative artifacts do exhibit *sharp discontinuities*, each individually a
THEOREM (III):
- **a cliff in the player dimension** — 0-, 1-, 1½-player parity are in P; 2-player is the open wall (`1857`/`1850`/T3);
- **a cliff in the priority dimension** — bounded `d` is in P (`1857`); `d=Θ(n)` is the open wall;
- **a firewall in characteristic** — char-2 logic and odd-char crypto do not admit the canonical algebraic bridge
  (`1851`/`1862`);
- **a wall in information** — the winner cannot be read from the control-free reduct (`1848`).

That four independent, *proven* discontinuities cluster around one problem is real and striking. But "**mathematics is
jagged**" — a smooth landscape replaced by cliffs and incompatible regions — is an **INTERPRETATION** of these data
points, not a theorem we proved. Each cliff is local and proven; the global claim about the shape of all mathematics is
a philosophical reading. We state it as what it is: the evidence *is consistent with* a locally jagged landscape around
this problem; it does not *establish* that mathematics as a whole is jagged. (The honest scientist's version: "here are
four proven sharp edges; draw the picture, but label the picture an interpretation.")

---

## The honest bottom line

The reach is genuine and it is layered:

| Layer | Status | Content |
|---|---|---|
| Parity = full-μ model-checking | **THEOREM** `1853` + CITED | the wall bounds the most expressive standard verification logic |
| CTL ⊂ alternation-free μ ⊂ wall | **THEOREM** `1861` | branching-time verification is poly; the frontier is the alternation |
| Generic characteristic firewall | **THEOREM** `1851`/`1862` | the canonical logic↔crypto algebraic key is empty across the deployed stack |
| Structural hardness anatomy | **THEOREM** `1848`/`1855`/`1860` | *why* parity is hard, *where* the cost hides, *what class* it is in |
| "universal speed limit / impassable canyon / laws of hardness" | **INTERPRETATION** | defensible readings wrapped around the theorems |
| "mathematics is jagged" | **SPECULATION** | consistent with four proven cliffs; not itself proven |

The theorems reach *much* further than one logic game — into the foundations of verification, into a structural divide
between char-2 logic and odd-characteristic cryptography, and into a reusable method for *explaining* (not just
observing) intractability. They do **not** reach as far as the grandest phrasings suggest, and we have marked exactly
where the proven core ends and the interpretation begins. That boundary — drawn honestly — is itself the point: the
same calibrated honesty that mapped the wall maps its reach.
