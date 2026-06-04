# III — System-Wide Soundness Audit (adversarial, increment-3 class)

**Started:** 2026-06-04 · **Method:** hunt the *increment-3 class* of bug — **a verification check that
is sound under a narrow model but unsound under the broader rewrite/exec relation the code actually
exercises.** Each finding is verified by **probe** (III's own gate as oracle, no rigging), adversarially
reviewed, and fixed only when the fix is confirmed *per-rule* (no green-wash). In-session, no subagents.

The seed: the increment-3 conjecture engine's termination guard was a *reachability* check, sound for
atomic symbols but blind to the *subterm-edge family* a leaf-rule induces (`f(l,q)→f(r,q)`). Caught by
math-verification, fixed with a reduction order. The audit asks: *where else does a gate certify on a
narrow case (one sentinel / atomic / root-only) what only holds on the broad case (all instances /
contexts / subterms)?*

---

## FINDING #1 — `xii_termination` measure not context-closed — **FIXED (`2e41489`)**

**The hole.** The XII termination gate's tier-1 measure was `xii_canon_weight = w_self + max(child
weights) + 1` — **`max`-based, hence not context-closed**. The gate classifies each rule by its delta
on one *bare sentinel* redex and returns at the first decreasing tier. **R015** (loop-over-compose
distribute, `F.LOOP(F.COMPOSE(a,b),n) → F.COMPOSE(F.LOOP(a,n),F.LOOP(b,n))`) **decreases `canon_weight`**
(→ classified `DEC_W`) **yet increases `node_count` by 1**. In a context `C = F.COMPOSE(HeavyX, ·)` with
`w(HeavyX) ≥ w(redex)` the `max` **masks** the weight change and `node_count` rises → the lex triple
*increases* on that step. R015's certified decrease does not survive subterm rewriting; the gate
**over-certified** (the engine still terminates — R015 can't re-match — but the *certificate* was
unsound and would pass a genuinely non-terminating rule of the same profile).

**Verification (probe, III alone).** `xtm_class_of_rid(15) = 1 (DEC_W)`; `node_count` Δ = +1 (structural:
LHS `2+na+nb`, RHS `3+na+nb`). Adversarially confirmed by the reviewer.

**The fix.** Lex triple is now `(loopbody, node_count, penalty)` — **every tier additive ⇒ context-closed**,
so a certified decrease propagates to every context (a genuine reduction order under subterm rewriting).
Tier-1 `loopbody = Σ over FLOOP nodes of node_count(body)`: R015 moves a COMPOSE out of a loop body, a
strict decrease of 1 **at any count** (count-independent — sidesteps the count=1 edge case that sinks an
additive-weight interpretation). The non-context-closed `canon_weight` is removed.

**Confirmed per-rule (no green-wash).** `xtm_anomaly_count = 0`; 34 firing rules = **3 DEC_L** (loop
family R014/R015/R041, certified by loopbody) + **31 DEC_N** (collapse/branch-lift/trit, certified by
node_count) + 0 DEC_P + **0 INC_L/INC_N/STUCK**. No rule increases the new tier-1. `814` selftest=99
(R015 now `DEC_L`, loopbody↓ + node_count↑ locked in as a regression). `run_xii_antidrift` 8/8,
`run_xii_corpus` 92/0, `run_corpus` 780/0. Forge descent seals + XII manifest mhash unchanged.

---

## OPEN ITEM #2 — `xii_joinability` ground-instance vs MGU (analyzed; no witness; relocates to Step 3)

The joinability gate builds each witness by instantiating constrained children via `_xjn_inst` — a
**specific ground sentinel** (`make_basis(0,1)` for an unconstrained child), not a variable/MGU term.
Analysis:
- **NONJOIN detection is sound** — a ground instance that diverges is a real confluence violation. So
  the gate never *falsely* reports a violation, and a genuine violation on any tested instance is caught.
- **JOIN-certification on a ground instance** is sound **iff** (a) Step 3 (`cpe_enumerate`) enumerates
  *every* overlap with its child-constraints, and (b) genuinely-unconstrained children are
  *instantiation-inert* (no rule inspects their structure). **Guarded** children are representative —
  `_xjn_inst` instantiates the exact guard-firing form (kind 5→null, 16→trivial-lift, 9→noop-grant). So
  the residual question is whether an *unconstrained* child, if compound, could enable an overlap Step 3
  didn't enumerate.
- **Verdict:** not a confirmed hole (no witness, unlike R015) — the concern **relocates up the pipeline
  to Step-3 enumeration completeness**. Mitigations: route-S made associativity structural at the
  constructor (shrinking the critical-pair burden); `run_xii_antidrift` independently checks the
  manifest + structural confluence. Resolving it fully needs a dedicated enumeration-completeness
  analysis of `xii_critpair_enum` (does it cover all overlap positions?) + a compound-instantiation
  differential. **Logged as the next deep target, not green-washed and not over-claimed.**

## Targets remaining

- **`xii_critpair_enum` (Step 3) enumeration completeness** — where OPEN ITEM #2 truly lives.
- **`nous_search` / `nous_classify` (Search Trichotomy keystone).** "A budget-hit is never SATURATED."
- **`reversible` (SID round-trip / H9 trichotomy).**
- **`cad` content-address sealing** (collision/domain-separation).

*Sister: III-CONJECTURE-FACULTY-AND-CAPABILITY-PROOF.md (the increment-3 fix that seeded this lens).*
