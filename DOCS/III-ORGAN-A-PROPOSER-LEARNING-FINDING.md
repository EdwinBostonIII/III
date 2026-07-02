# Organ A — the Learned Proposer: a sealed negative finding + the real frontier
> **STATUS: HISTORICAL RECORD** — an executed campaign plan/ledger, kept immutable as evidence (reunification W6).

**Status: FINDING (a proven negative result + a reframe). Date: 2026-06-04.** Not a build — a
prove-the-negative that *saves* a build. Records why a genuinely-trained `nous` proposer over the
current reorderable set is **provably vacuous**, and where proposal-learning could actually matter.

---

## The question

`nous_charter` permits statistical learning on the propose-and-checked path; the user authorised
building a genuinely-trained `nous` proposer (deliberately crossing the standing no-statistical-
learning line for this scope). Before building the out-of-tree trainer (ADR-N8) → sealed weights →
in-tree consumption loop, the load-bearing premise had to be checked: **does the proposer's freedom
change the metric a trainer would optimise?**

## The finding — it is vacuous, on two independent legs

A trainer would optimise **gap-rate / step-count** by reordering the rules `nous_policy` ranks. Both
the cost and the freedom are structurally null:

**Leg 1 — Evaluation regime (what rule-order actually governs).** Rule order feeds
`xii_canonicalise → xii_rewrite_apply_one`, which fires the **first matching** rule at a node. A
"step" is a rewrite *apply*. The reorderable rules are exactly the `xcc_reorderable` ones —
**no non-joining overlap**, prominently the **LHS-disjoint trit block** (kinds 25–29 share no LHS
with any R-rule). Disjoint rules never co-match a node, so reordering them changes neither *which*
rule fires nor *how many* applies occur → **normal form and step-count are invariant.** The R-block's
*overlapping* rules (R038/R040 specialisations) carry the only order-sensitive decisions, and their
cascade order is **fixed** (proven; a free sort was caught RED historically).
- **Empirical proof:** `verify_nous_differential.sh` (the 3-way keystone gate) — **GREEN, 53/53**
  engine-exercising corpus tests produce identical verdicts under `active=0` (cascade),
  `active=1 mode 0` (nous-cascade), and `active=1 mode 2` (policy). Reordering changed **no** answer.

**Leg 2 — Search regime (what gap-rate actually measures).** `nous_train` counts
`SATURATED/GAP/REFUTED` — outcomes of `nous_search`, whose only implemented client is
`nous_search_egraph → eg_saturate` (**the e-graph**). The e-graph is *not* governed by
`nous_policy`'s rule ordering at all (and e-graph saturation is order-robust by construction). So
`nous_policy` weights **cannot move the gap rate** even in principle.

**Conclusion.** The metric is invariant under the only freedom a trainer has. **No corpus — M19 live
spines or otherwise — changes this.** ADR-N8's closure ("any weights are safe; a weak policy only
raises the gap rate") is in fact *stronger* than stated over the reorderable set: weights do not move
the gap rate **at all**. Building the trainer→seal→consume loop would build an elaborate machine
whose output is *mathematically guaranteed* not to beat baseline.

## The deeper theorem (why this was always going to be null)

**Confluence + termination are exactly the properties that make proposal-order irrelevant to the
result; disjointness makes it irrelevant to the cost.** A learned proposer over a *closed, confluent,
terminating* rule set is structurally inert — not a deficiency, a consequence of the engine being a
*deterministic universal evaluator* (XII's confluence is a theorem, III-APOTHEOSIS). Order is a
degree of freedom the system has already quotiented away.

## Where proposal-learning *can* matter — the real frontier: CONJECTURE

Proposal only buys capability where the search space is **open** — proposing terms that are **not yet
in the set**:
- the **auxiliary lemma** not derivable by the current rules (opens a stuck proof),
- the **completing rewrite** that restores confluence (Knuth–Bendix completion),
- the **generalisation** that makes an induction go through.

This is the one act the `nous` doc calls *"structurally beyond enumeration — the target is not in
its space."* It is a **new capability** (general term/rule proposal), categorically different from
reordering a fixed set. And it does **not** require ML to be revolutionary: a **deterministic
conjecture enumerator** (propose a bounded class of candidate generalisations/completions, each
**checked by the statistic-blind disposer**) is the principle-consistent form — the `propose→dispose`
faculty applied to an *open* space. ML-ranking of conjectures helps only at scale, and only with the
M19 trace corpus that does not yet exist.

## Decision

- **Do NOT build the reorder trainer.** It is provably null (this finding).
- The revolutionary direction is the **conjecture faculty** — a separate, larger capability. The
  honest, principle-consistent first form is **deterministic conjecture, disposer-checked**, not ML.
- This finding is the deliverable that the "genuinely-trained proposer" request actually warranted:
  a rigorous reason not to spend days on a guaranteed-null machine, and a precise map of where the
  real leverage is.

*Sister docs: III-BEYOND-DETERMINISM-CONTEMPLATION.md (the propose/dispose thesis), III-NOUS-
ARCHITECTURE.md (the faculty), III-ORGAN-{C,E}-*-PLAN.md (the built organs).*
