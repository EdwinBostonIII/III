# THE WALL GEOMETRY — III as a Substrate That Flows Inward to One Center

*The organizing charter for the "walls eat the modules that grow them" program. Every claim is tagged
**GROUNDED** (true of III today, gated/measured), **DESIGN** (a chosen rule we will hold), or **ASPIRATION**
(a direction, not yet a fact). Nothing grand is asserted untagged.*

---

## 1. The center (the user's definition, recorded exactly)

**GROUNDED (partially built — KATABASIS Inc 1–14) + DESIGN.** The center is **one** most-primitive point *from which all
emerge*: the **KATABASIS** silicon-melting descent (III beneath the OS, Ring −1/−2 — driver/hypervisor) **⊕ XII** (the
canonical-form weave) **⊕ the self-hosting compiler fixpoint** (`iiis-2 == iiis-3`, with the *best parts* of
`cg_r3`/`cg_riii`/`iiis-2` layered in). It has *agnostic access to the silicon and its primitives* — the thing III
learned to "melt into."

This descent was deliberately **left unfinished**: at the point of layering the compiler's best parts into it, the user
refused to *dirty the perfect weave* with a pile of ad-hoc math primitives. That refusal is the origin of this entire
program — the search for the *clean* way to give the center its mathematics: full calculus → the parity wall → the grail
primitives → the eleven walls and their gated faculties. **The walls ARE the clean mathematical substrate the center was
waiting for.** They let the full calculus enter the system *as ordered, proven, wall-rooted structure* rather than as
loose primitives that would soil the weave.

So the center is **not a new thing to build** — it is the KATABASIS/XII/compiler fixpoint we already have in part. The
program is to *complete it cleanly* by making the rest of III flow inward to it through the walls.

---

## 2. The geometry (what "flows inward to the center" means concretely)

**DESIGN.** A directed structure — the carto systems graph, *re-rooted at the walls*:

```
   WALLS (roots: the organized mathematical periphery — 11 gated faculties)
     │   each module is assigned to its NEAREST wall by a PROVEN mathematical relation
     ▼
   wall-satellites (modules the wall organizes / absorbs, refactored to the wall standard)
     │   every edge is an EXPLICIT, traceable derivation (proof-carrying), not a heuristic ripple
     ▼
   inner organs (modules built outward-from-walls / inward-toward-center)
     │
     ▼
   THE CENTER  (KATABASIS ⊕ XII ⊕ compiler fixpoint — the clean weave)
```

- The **edges are proofs** (`proof_carrying`, `certified_morphism`, `theorem_carrier` already exist in III): a module's
  place in the geometry is *justified* by an explicit relation to its wall, not asserted.
- **Convergence to the center** = every wall→module→…→center derivation **provably preserves the central invariants**
  (the self-hosting seal `iiis-2==iiis-3`; the charter / K-floor). That is the precise, non-metaphorical meaning of
  "everything leads to the fixed center point." **GROUNDED** mechanism (III already gates the seal + charter); the
  *total* convergence is **ASPIRATION** until the geometry is actually built.

**Honest scope (GROUNDED).** The walls organize the **mathematical-substrate** of III. They do **not** organize the
whole system: the silicon/crypto primitives, the compiler trusted base, governance/charter, nous, and I/O are the
**center and its direct organs**, not wall-satellites. Forcing them onto walls would be procrustean. The geometry is
"periphery (walls) → … → center"; the center's own primitives are not eaten by walls — they *are* the destination.

---

## 3. The eleven walls as roots, and their primary clusters

**GROUNDED** (the faculties exist + gated, corpus 1882–1891) + **DESIGN** (the cluster assignments, to be proven per
module before any absorption):

| Wall (root faculty) | What it organizes | Primary cluster (candidate satellites, by mathematical kinship) |
|---|---|---|
| `numera::parity_game` | ω-regular / fixpoint verification | temporal_logic, kleene_fixpoint, pctl, bmc, kinduction, mc_certified |
| `numera::sat_tractable` | Boolean reasoning (tractable fragment) | sat, sat_arith, sat_at_scale, smt, bv_bits/bv_ring (the SAT face) |
| `numera::confluence` | rewriting / canonical form | xii_*, egraph, congruence_closure, rewrite_schedule, mem_rewrite, nous_completion |
| `numera::graph_refine` | structural equivalence / dedup | carto (dedup), weave_graph, computation_graph, proof_bisimulation |
| `numera::diophantine` | integer/modular linear algebra | crt, modular, modular_mont, barrett, ed_scalar_modl (the gcd/inverse face) |
| `numera::con_lattice` | finite-algebra quotient structure | logic6, trit, voice, interval_lattice, memo_lattice (the lattice face) |
| `numera::constructible` | field-degree / algebraic decidability | galois, gf_poly, field, fp256/fp384 (the minimal-poly/degree face) |
| `numera::ramsey` | forced combinatorial structure | (sparse — combinatorial detection; few satellites) |
| `numera::comm_lb` | rank / lower-bound certification | matrix_ring, infotheory (the rank/bound face) |
| `numera::goodstein` | ordinal descent / termination | loop_bounds_prover, safety_prover, sanctus (the termination face) |
| (Diophantine = Hilbert-10 island) | — | (folded into `diophantine`) |

*The assignment is a hypothesis per module; §4 forbids touching any of them until the relation is **proven** and the
result is **superior**.*

---

## 4. The absorption standard (the user's mandate — non-negotiable)

**DESIGN (held absolutely).** "Walls eat modules" is **three operations of different risk; never bundled**:

- **(c) refactor-up** — bring a satellite to the wall's quality bar (system-aware header, gated == independent oracle,
  honest bounded domain, tree-unique prefix, no dangling). *Safe.*
- **(b) wire** — make the satellite *call* the wall faculty (earned dependence; the metric in §5). *The real value.*
- **(a) consolidate/delete** — only where a module *provably duplicates* a wall faculty, and only on **gated/byte
  equivalence proven first**. *Dangerous; gated; reversible.*

**Every touched module must come out EVERGREEN: full functionality, production quality, and SUPERIOR TO ITS FORMER SELF
IN ALL REGARDS** (capability, determinism, clarity, integration, limits-documented). If a change cannot be proven
superior in all regards, it is **not made** — "might as well not do it if it isn't clean, perfect, ordered, harmonious."
This standard is itself the safeguard: e.g. the **Ripple optimizer is load-bearing** — it can only be "eaten" by an
explicit wall-derivation that is *proven superior in all regards*, side-by-side, which is a bar high enough to forbid
casual replacement. Crypto / self-host / compiler-trusted-base absorptions get **separate explicit sign-off** each.

---

## 5. The metric (what makes this honest, not a metaphor)

**GROUNDED (measured today).** A wall is a *root* only when real modules depend on it. Earned-dependence =
**genuine (non-corpus) callers per wall**. Measured now:

```
parity_game 0 | sat_tractable 0 | confluence 0 | graph_refine 0 | diophantine 0
con_lattice 0 | constructible 0 | ramsey 0 | comm_lb 0 | goodstein 0
```

The walls are currently **leaves**, not roots — the program's whole job is to move these numbers up, one *proven,
superior* wiring at a time. "Perfect substrate" is operationalized as: **every math-substrate module reaches the center
through a wall, by a proven edge; and every wall has earned its callers.** Progress is countable.

---

## 6. Order of work (cleanest first; the pilot)

**DESIGN.** Per wall, in ascending risk: map the cluster (read-only, proven relations) → refactor-up the safest leaf
satellite → wire it (metric 0→1) → only then consider consolidation, gated. Start with **Confluence** (clearest
satellite structure; XII already documented on its island). First concrete target chosen in the pilot: the cleanest
non-core confluence relative, made evergreen-superior and wired to `numera::confluence`, gated — proving the pattern
before it touches anything load-bearing.

---

## 7. Honest limits and uncertainties (tagged ASPIRATION / open)

- **11 walls are not proven a complete basis.** Some modules will fit no wall; some may need a wall not yet built. The
  geometry covers the math-substrate, demonstrably not the whole system (§2).
- **"Perfect / total convergence" is ASPIRATION.** The real, bounded claim is *proven inward edges + earned dependence*,
  measured (§5) — not a metaphysical fixed point.
- **Ripple replacement is not authorized as replacement** — only as *added* explicit derivation that is *proven superior
  in all regards*, or it does not happen.
- **The center's completion** (layering the best compiler parts into KATABASIS cleanly) is the destination, not step 1;
  it proceeds only as the walls make the inward flow clean enough to not dirty the weave.

**Bottom line.** The vision is sound when stated as its grounded core: the walls are the *clean mathematical substrate*
the unfinished KATABASIS center was waiting for; the program makes III's math-substrate flow inward to that center by
**proven** edges, absorbing satellite modules **only** by making them evergreen and superior, measured by earned
dependence. That is buildable, countable, and reversible. The grandeur ("perfect," "fixed point," "everything") stays
tagged as the direction it names — the work is the proven edges, one superior absorption at a time.
