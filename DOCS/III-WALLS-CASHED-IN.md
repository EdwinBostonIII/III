# Cashing In the Walls — Where III's Own Subsystems Sit

The ten-wall program (`III-WALLS-CROSS-SYNTHESIS.md`) is not only a map of hard problems "out there" — its value is that
**III's own subsystems sit on these walls**, and the wall-map tells each one *what is possible, what is provably not, and
what to do about it.* This is the asset cashed in: each wall becomes engineering guidance, with the same honest tags.

**Tag:** each row is **GATED** (a III KAT pins it), **DOCUMENTED** (established in III's build docs), or **GUIDANCE** (a
reasoned mapping — an engineering reading, not a theorem).

---

## 1. The mapping

| III subsystem | Sits on wall | What the wall says | Status |
|---|---|---|---|
| **XII canonicaliser** (`DOCS/III-XII.md`) | **Confluence** (OBSTRUCTED core) | Stay on the decidable **island**: keep XII *terminating* (well-founded weight order) + *confluent* (critical pairs join). Then confluence is *decidable* (Newman, `1868`); leave the island and it is *undecidable* (`1869`). | DOCUMENTED (XII Thm 9.4) + GATED (`1868`/`1869`) |
| **cg_r3 / sov_calc optimizer** | **Parity / μ-calculus** (verification face) + general-optimization intractability | III's *dataflow/fixpoint* analyses are **alternation-free μ** — single fixpoints, **poly** (`1861`); that is the island, and most real passes live there. *Verifying* a temporal property of the transformed program is full-μ = parity (`1853`), quasi-poly worst case. The *general optimal-rewrite / superoptimization* problem is a separate intractability (undecidable in general) — do not chase it; stay in the alternation-free dataflow island. | GUIDANCE + GATED (`1861`,`1853`) |
| **PQ crypto** (mlkem/ntt, `galois`, `fp256`) | **Characteristic firewall** (the M1 / `1862` boundary) | The char-2 logic substrate and the odd-characteristic crypto rings do **not** admit the canonical algebraic bridge (`1851`/`1862`) — uniform across the deployed stack (ML-KEM/Falcon/ML-DSA/Mersenne/Goldilocks/RSA). Do not seek a single algebraic key uniting III's logic and its PQ crypto; use *simulation* (the weave computes `ℤ_q` as circuits), not a morphism. | GATED (`1862`) |
| **SAT/Boolean reasoning** (weave, `bv_bits`) | **SAT / P-vs-NP** | Boolean satisfiability over III's bit-vectors is NP-complete in general; stay inside Schaefer's tractable islands (2-SAT/Horn/XOR, `1863`–`1865`) where decisions are *poly*. Recognize when a reasoning task leaves the island (mixed clauses) and budget for search. | GATED (`1863`–`1867`) |
| **`numera/groebner` (Buchberger)** | **SAT (algebraic face) + parity (Nullstellensatz)** | Gröbner cost = certificate degree = the open core (parity `1847`, proof-complexity for SAT). Expect *exponential* degree on hard instances (a poly-degree certificate would *be* a P-proof); use it where degrees stay low, not as a general solver. | GATED (`1847`) + CITED |
| **`markov_exact` / recurrent-class read-off** | **Parity (control-blindness)** | Any *statistic-only* read-off of a controlled system is control-blind and provably wrong on ownership-swap (`1848`). Honors Ax D3 ("no disposer reads a statistic") for exactly this reason — the control-blindness barrier is *why* the axiom is right. | GATED (`1848`) |
| **`sanctus`/`affine_audit` termination & bounds proofs** | **Independence (Goodstein) / halting (OBSTRUCTED)** | General termination is undecidable; III's affine-audit works because it proves a *restricted, decidable* fragment (typed-array bounds, affine indices). The Goodstein falsifier (`1880`) is the honest reminder: some true terminations are *unprovable* in a weak theory — keep the audit's claims inside what its proof system can reach. | GATED (`1880`) + DOCUMENTED |
| **`carto` / systems-map dedup** | **Graph isomorphism** | Structural-equivalence detection (are two subgraphs "the same"?) is GI-flavored; 1-WL-style invariants are *sound but incomplete* (`1871`) — they can miss real equivalences on regular/symmetric structure. Treat invariant-matches as *candidates*, confirm by an actual isomorphism check. | GATED (`1870`–`1872`) |

---

## 2. The three actionable lessons III takes from the walls

- **Stay on the island, by construction.** XII's termination+confluence, affine-audit's restricted fragment, and the
  Schaefer-class Boolean reasoning are all examples of the *same* discipline the walls teach: engineer your problem onto
  the decidable/tractable side of the boundary, and the property you want (confluence, termination, satisfiability)
  becomes *checkable* rather than an undecidable or intractable hope. The boundary KATs (`1869`, `1880`, `1867`) are the
  map of where that island ends.
- **Don't fight a proven barrier.** The characteristic firewall (`1862`), the control-blindness barrier (`1848`), and
  the open cores (parity-in-P, P-vs-NP) are *constraints*: III should not spend effort seeking a single logic↔crypto
  algebraic key, a control-free optimizer read-off, or a general poly SAT/parity solver — each is provably or famously
  out of reach. The walls turn "we couldn't find X" into "X is provably/likely not there" — a budget-saver.
- **Use the right invariant; know when the cheap one fails.** Resolution often comes from the invariant that captures
  the essential quantity (constructibility's degree, `1879`). Where III faces an open wall, the gated *negative* results
  (`1848`, `1871`) say precisely which cheap invariants *won't* work — so effort goes to the structure-preserving
  (control-aware, higher-order) methods, not the control-blind shortcuts.

---

## 3. Production faculties built from the walls (BUILT + GATED — then CUT; read the banner)

> **SUPERSEDED — do not read this section as current state.** These 10 faculties were **CUT** in commit
> `65783306` as unused cash-in bloat (0 non-corpus consumers; the `crt` head-to-head proved wiring one
> *regressed* good code). They are **not present** in the tree (verified 0/10). This section records what was
> once *built*, not what *exists*. Current disposition: `III-WASTE-AUDIT-II.md` §1 (cut) / §8 (gray-zone).

The cash-in made concrete: ten new `STDLIB/iii/numera/` faculties, each an island of a wall turned into a production,
system-aware, independently-usable III capability — `@export` API, rich header (role / use-cases / invocation / impacts /
limitations), registered in `build_stdlib`, archived in `libiii_native.a`, and gated by a corpus KAT that cross-checks
it against an **independent** oracle (a different algorithm, or brute force). All ten gates green (corpus `1882`–`1891`).
No duplication — built only where III lacked the capability; primality was left to `rsa.iii`.

| Wall | Faculty | Core `@export` | Gate (independent cross-check) |
|---|---|---|---|
| Parity / μ-calc | `numera::parity_game` | `pg_solve_even`, `pg_winner` (Zielonka) | `1882` vs all-positional-strategy enumeration |
| SAT | `numera::sat_tractable` | `st_decide` (Schaefer classes), `stx_decide` (XOR) | `1883` vs brute `2ⁿ` per class |
| Confluence | `numera::confluence` | `cf_confluent`, `cf_unique_nf` (Newman) | `1884` vs Newman 3-way equivalence |
| Graph iso | `numera::graph_refine` | `gr_iso`, `gr_fingerprint_a` (1-WL + backtracking) | `1885` vs brute permutation iso |
| Diophantine / Hilbert-10 | `numera::diophantine` | `dio_solve`, `dio_mod_inverse` (ext. Euclid) | `1886` vs bounded brute + identities |
| Lattice / FLRP | `numera::con_lattice` | `cl_num_congruences`, `cl_is_distributive` | `1887` vs independent congruence enumeration |
| Constructibility | `numera::constructible` | `ctr_cubic_irreducible`, `ctr_ngon_constructible` | `1888` vs brute root-search + Gauss–Wantzel |
| Ramsey | `numera::ramsey` | `ram_has_mono_clique`, `ram_ramsey_33` | `1889` vs independent subset check |
| Comm. complexity | `numera::comm_lb` | `cml_rank_gf2`, `cml_lb` (rank lower bound) | `1890` vs independent GF(2) rank |
| Independence / Goodstein | `numera::goodstein` | `gst_terminates`, `gst_step_count` | `1891` vs G(1..3)/G(16) reference |

*Engineering note (harmony):* every faculty owns a tree-unique symbol prefix (module vars and non-`@export` fns become
global symbols); the `rm_` prefix collided with `forcefield/ripple_metric` and was renamed `ram_`. Each is sound +
complete on a *documented bounded domain* (e.g. ≤64-vertex arenas, ≤32-var CNF) — honest limits, not correctness gaps,
matching each wall's open/obstructed core.

**INTEGRATION STATUS (honest — advisor-audited).** All ten are **callable libraries**: any III module may `extern` and
call them, and the corpus gates do. **None is yet wired into an existing caller** — there is no dispatch from
`numera::sat` to `sat_tractable`, no migration of the modular-inverse sites to `diophantine`. Wiring them into live
paths is the explicit *next* step, and it is deferred here on purpose: the natural call sites are the 805-line CDCL
solver, the crypto modular-arithmetic path (`crt`/`modular`/`modular_mont`), and self-host code — all of which, per III's
triage discipline (`feedback_triage_selfhost_latent_separate`), require explicit sign-off before modification rather than
unilateral surgery. So the present, verified impact is *an available, gated library*; deeper wiring awaits that decision.

---

## 4. Bottom line

Each wall, pushed to its limit and gated, is an asset III spends: the confluence wall is the theory under XII's
guarantees, the characteristic firewall bounds III's logic↔crypto ambitions, the control-blindness barrier *justifies*
Ax D3, the parity/μ wall sets the optimizer's realistic ceiling, and the Goodstein falsifier marks where even *true*
properties outrun a weak proof system. The map is not decoration — it is III's own constraint-and-capability ledger,
each entry tagged GATED / DOCUMENTED / GUIDANCE, ready to be acted on.
