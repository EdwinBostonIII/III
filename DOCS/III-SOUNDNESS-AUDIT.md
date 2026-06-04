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

## FINDING #2 — nous SATURATED over-certified on e-graph capacity exhaustion — **FIXED**

The Search Trichotomy keystone (`nous_classify`) is correct *given* `saturated`: a budget-hit → GAP,
never SATURATED (selftest quadrants 1-4). But the soundness relocates to how `saturated` is computed —
and there is a hole. `nous_search_egraph`: `sat = (eg_saturate(budget) < budget)`. `eg_saturate` returns
`step < max_steps` iff a full pass produced **no union** (`changed==0`) — and it checks no overflow flag.
The code path:
- `eg_inst`: `eg_add` full → returns `EGRAPH_SENT`, sets `running=0` (node-table `EGRAPH_MAX_NODES`,
  inst-stack `EGRAPH_INST_STK`, or match-stack `EGRAPH_MFAIL` all bail the same way).
- `eg_apply_rule`: `if new_cl != EGRAPH_SENT { union; unions++ }` — a full-table instantiation counts
  **no union**.
- so when capacity is exhausted, every rule yields `unions==0` → `changed==0` → `eg_saturate` returns a
  **fixpoint** signal `step < max_steps` → `sat = TRUE` → **SATURATED**.

So a search that overflows the e-graph's internal capacity before a genuine fixpoint is **falsely
certified SATURATED** — an incomplete (GAP) result hardening as a *trusted, oracle-independent,
canonical* artifact (the canonical reproducibility key omits budget/weights). The keystone guards the
*step budget* + rejects wall-clock, but **not internal capacity**: a capacity-hit IS classified
SATURATED — the keystone's own spirit ("resource exhaustion is never a determined result") violated.
Same class as FINDING #1 and the bigint-64-slot exhaustion. **Reachable** for any problem with more
equalities than capacity.

**Fix (verified).** Per the reviewer's design — egraph *exposes the fact*, the nous keystone *decides*:
`egraph.iii` sets `EGRAPH_SAT_INCOMPLETE` whenever a matched rule's instantiation is blocked by a full
table (`eg_instantiate → SENT`) or the match-stack overflows (`EGRAPH_MFAIL`) *during* saturation, reset
at the top of each `eg_saturate`, exposed via `eg_sat_incomplete()`. `nous_search_egraph` then forces
`sat = 0` (→ GAP) when the flag is set. This extends the keystone from "a budget-hit is never SATURATED"
to "a **capacity**-hit is never SATURATED" — same fail-safe philosophy as the increment-3 reach-cap.

**Verified by a FORCING KAT (the deliverable — the existing corpus can't reach this path).**
`1107_egraph_saturate_capacity_gap`: fills the node table (`EGRAPH_MAX_NODES`) with a distinct f-chain
until `eg_add → SENT`, registers a productive rule `f(?0)→g(?0)` whose RHS nodes are blocked by the full
table, saturates → asserts outcome **GAP** (=99). **It bites:** linking the same KAT against a no-fix
`nous_search` flips it to **SATURATED** (exit 10) — proving the test exercises the path and the fix is
what produces the correct verdict. `eg_sat_incomplete()==1` at the e-graph level; `steps<budget` (the
old fixpoint-shaped signal) confirmed. build_stdlib 464/0.

## FINDING #3 — organ E (Forked Walk) ignored rev_record's capacity error — **FIXED**

The sweep's caller-audit found a caller-side instance in this session's own organ E. `reversible.iii`
correctly returns `REV_E_OOM_LOG` when the undo log is full (a *positive* — it signals the limit, never a
silent drop). But `forked_walk`'s `fw_explore`/`fw_commit` **ignored that return**: on a full log they
mutated `FW_CELL` without a recorded inverse, then `rev_rollback` replayed an EMPTY envelope → the cell
kept the speculative value, silently breaking the documented "a loser leaves the state byte-for-byte
unchanged" guarantee.

**Fix:** check `rev_record`; on any error, `rev_rollback` the empty envelope and REFUSE (return the
unchanged value / `FW_E_SLOT`) — an unrollbackable branch is not "searched". Same conservative fail-safe
as the reach-cap and capacity→GAP fixes. **Forcing regression** (KAT `1101` case 8): fill the rev log to
`REV_MAX_RECORDS`, then `fw_explore` must leave the cell unchanged. BITES: pre-fix the cell keeps 777.

## POSITIVES (the fail-safe done right — gates that correctly guard their cap)

- **`xii_critpair_enum`**: cross-checks the recorded count against an *independent* counter
  (`cpe_enumerate() == xro_count_overlaps()`) + verifies no table overflow (`n1 > CPE_MAX → fail`).
- **`reversible`**: `rev_record_quad` returns `REV_E_OOM_LOG` on a full log (an error, not a silent
  drop) — the hole was the *caller* (FINDING #3), not the gate.
- **`xii_admission`**: a composition of the (now-hardened) Step-4 joinability + Step-5 termination gates.

## THE UNIFYING ANTI-PATTERN (the audit's central finding)

FINDINGS #1, #2, and the seed increment-3 bug are **one class**:

> **A verifier signals success from a bounded proxy that conflates "succeeded within a limit" with
> "genuinely complete," and the internal resource bound is invisible to the verdict.**

- increment-3: a reachability cycle-check sound for atomic symbols, blind to the subterm-edge family.
- FINDING #1 (`xii_termination`): a `max`-based weight whose decrease doesn't survive a heavier sibling
  — a *narrow-redex* proxy for an *all-contexts* property.
- FINDING #2 (`nous_search`): `steps < budget` reads as a fixpoint, but a full-table "no-union" pass is
  capacity exhaustion — an *internal limit* invisible to the *completeness* verdict.
- Named cousins (already in memory): bigint 64-slot handle table; witness_hook 1M-frag cap.

**The fail-safe rule each fix applies:** when an internal bound is hit, the verdict must be the
*conservative* one (REJECT / GAP / not-certified), never the success-shaped default. Reframes the audit
from per-module reading to **hunting this one class**: grep every verifier/gate for a path where a
cap / table-full / stack-full / step-limit yields a non-error, success-shaped return.

## Targets remaining (hunt the anti-pattern)

- **`xii_critpair_enum` (Step 3) enumeration completeness** — where OPEN ITEM #2 truly lives.
- **`nous_search` / `nous_classify` (Search Trichotomy keystone).** "A budget-hit is never SATURATED."
- **`reversible` (SID round-trip / H9 trichotomy).**
- **`cad` content-address sealing** (collision/domain-separation).

*Sister: III-CONJECTURE-FACULTY-AND-CAPABILITY-PROOF.md (the increment-3 fix that seeded this lens).*
