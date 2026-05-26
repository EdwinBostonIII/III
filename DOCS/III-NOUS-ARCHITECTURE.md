# III — `nous`: the proposer faculty + the Search Trichotomy closure

**Status: BUILT + VERIFIED (2026-05-25).**  11 modules, 9 corpus KATs (800–808, all =99
against the live archive), 4 gate/boundary scripts + 1 umbrella runner.  Full build
PASS=368/FAIL=0; full corpus PASS=404/FAIL=0 (no regression); the keystone differential
gate GREEN (3-way), the propose-only gate GREEN.

---

## 1. The cell of III, and the one act

The smallest recurring unit of III is the **term**; the one act every organ performs is
**choosing the next term**.  Evaluation, proof, optimization, completion, composition —
each is a *walk through terms toward a normal form*, and the walk was blind enumeration.
Enumeration cannot **conjecture**: the auxiliary lemma not in the rule set, the completing
rewrite that restores confluence, the generalization that opens a stuck proof.  That leap
is structurally beyond enumeration because the target is not in its space.

`nous` (νοῦς, the faculty of intuitive grasp) is a single **faculty of proposal**: given a
term and a goal, it returns a short **ranked list of candidate next terms**.  It generates
nothing believed, asserts nothing, proves nothing — it ranks possibilities and hands the
ordered list to the deterministic engine, which checks each against the kernel /
constitution / cost lattice / confluence machinery exactly as if a blind enumerator
produced it.  Because everything in III is a term, one proposer is automatically a proposer
of rewrites, lemmas, completions, programs, and compositions — written once, reaching every
cell.

---

## 2. Why it is safe — the closure (stated exactly, as built)

III has two regimes; both are closed.

**2.1 Evaluation** — drive a held term to its normal form (`xii_canonicalise` →
`xii_rewrite_apply_one`).  Confluence fixes the unique normal form; termination bounds
steps **but the hard cap `XCN_MAX_REWRITE_STEPS = 4096` CAN bind** (MPO weights are
`k_cost × 1000`-scale, so there is no proof step-count ≤ 4096 under every order — A-1).
Therefore `xii_canonicalise` now **emits a typed GAP on cap-hit, never the truncated term
as a canonical form** (`XCN_GAPPED`, `xii_canonicalise_gapped()`).  `nous_eval_checked`
(nous_search) is the consumer contract: a gapped result is the semantically-equal but
non-canonical partial reduction — sound to use as-is, never an error, never a wrong value.

**2.2 Search** — find a term satisfying a predicate (e-graph saturation+extraction, proof
search, completion, SAT/SMT, later synthesis).  The **Search Trichotomy** (`nous_search`),
a typed outcome the engine cannot bypass:

| Outcome | Meaning | Oracle-dependence |
|---|---|---|
| **SATURATED** (0) | the search reached a state proving its result canonical (e-graph saturated ⇒ the equality set is complete) | independent |
| **GAP** (1) | budget spent before certification — a witnessed `unc_gap_root`, propagates only into gap-accepting contexts, never hardens | dependent |
| **REFUTED** (2) | a proof no answer exists (unsat / no representable term) | independent |

**The keystone safety property** lives in `nous_classify(saturated, has_answer)`:
SATURATED requires BOTH saturation AND an answer; a budget-hit (`saturated=0`) can NEVER be
SATURATED — it is GAP.  This is the wall against an oracle-dependent value escaping
disguised as a determined one.  *Cost-optimality of an extracted term is a SEPARATE
certificate* (B-4): `eg_extract` is a DP relaxation-to-fixpoint, optimal under the declared
linearization only if the DP reached fixpoint within its pass bound.

**Budget** = a sealed, deterministic, cost-denominated quantity (`nous_budget_make`):
step/node count or a `cl_dot` scalar.  **Wall-clock is rejected at construction** (it would
break replay); the budget is cad-sealed so tampering is detectable.

**Reproducibility key, split by outcome (B-5):**
- **canonical** (SATURATED / REFUTED) = `cad(input ‖ rule-set-ver ‖ cost-linearization-ver)`
  — **omits nous weights + budget**, so a certified result is true regardless of which nous
  found it; the certified commons accumulates *across* retrainings.
- **gap** (GAP) = `cad(input ‖ rule-set-ver ‖ costlin-ver ‖ weights-addr ‖ budget ‖ tiebreak)`
  — the full tuple; resumable gaps are version-pinned.

---

## 3. The cost linearization (P0.5)

The cost lattice is 6-dimensional — a PARTIAL order, so "minimal-cost" has a Pareto
frontier, not a unique minimum.  `nous_costlin` declares the canonical TOTAL order:
**lexicographic over the six facets, with the 32-byte content-address as the final
tiebreak**, versioned (`nous_costlin_version`) so the version enters both keys.
`nous_cost_compare` is the exact order; `nous_cost_scalar` is a bounded lex-packed
projection (each facet clamped to 10 bits, packed most-significant-first) for the e-graph
DP, faithful to the lex order for bounded costs.

---

## 4. The confluence-safety finding (the heart of P3, discovered by the differential gate)

The plan assumed the set R001–R044 + trit 101–105 was a free permutation under confluence.
**It is not.**  When the first policy free-sorted the R-rules into ascending order, the
3-way differential gate went RED on exactly **341_xii_R038 and 343_xii_R040** — the two
rules the cascade fires FIRST.  R038 and R040 are SPECIALIZATIONS that must fire before the
general rules they overlap (R037/R017 for R038, R030 for R040; see `xii_rewrite.iii`
apply_one).  The cascade order encodes a required PRIORITY.

The certified-reorderable structure, therefore, is:
- the **trit block** (kinds 25–29, LHS-disjoint from every R-rule ⇒ zero critical pairs)
  may move freely relative to the R-block;
- **within the R-block the proven cascade order is preserved** (ADR-N11: uncertified
  relative positions stay fixed).

`nous_policy` is a kind-aware BLOCK reorder honoring this: trit-block-first for a trit-kind
context, else the exact cascade order.  It returns a FULL PERMUTATION of all 49 certified
rules (never drops one) — confluence-safe by construction, and **proven** by the
differential gate (3-way GREEN).  The lesson generalizes: *the proposer's reorder freedom
is bounded by the actual confluence structure, and the gate — not assumption — is the
contract.*  A richer trained model may later reorder within a confluence-equivalence class,
but must keep the gate green.

---

## 5. The amendment (a Prime Directive, redrawn) — `nous_charter`

III forbids statistical learning.  The line is redrawn where the architects meant it:

> **Statistical learning is forbidden on any path that DECIDES or ASSERTS, and permitted
> ONLY on a path that PROPOSES and is CHECKED.**

Installed as a self-falsifying constitutional clause (`nous_charter`, mirroring
`h2_charter`'s mig6 pattern — verify ∧ falsify + terminal-gate `run_charter` + a canary):
- **verify** — the closure certifies only what is earned (a genuinely-saturated search is
  SATURATED; a saturated-no-answer is REFUTED).
- **falsify** — the gate catches every escape (a budget-hit is never certified; a
  wall-clock budget is refused).
- The canary ("a budget-hit IS SATURATED", which `nous_classify` makes false) drives
  `run_charter` RED, proving the gate is a real falsifier.

The **operational proof of the keystone** is the BUILD-TIME differential gate (§7), not a
runtime predicate ("removing the proposer changes an output" is a counterfactual no runtime
clause can express).

---

## 6. The layers (11 modules, all `nous/`)

| Module | Role | Phase |
|---|---|---|
| `nous_features` | integer features of a term (kind/depth/size); xii_term-only (acyclic) | P3 |
| `nous_costlin` | the cost linearization (lex + content-addr tiebreak, versioned) | P0.5 |
| `nous_value` | the faculty as a sealed value (weights-addr cad, version, cost-bound) | P3 |
| `nous_policy` | the deterministic integer ranker (confluence-safe BLOCK reorder) | P3 |
| `nous_socket` | the universal proposer socket (modes 0 cascade / 1 ascending-probe / 2 policy); kill switch | P0/P3 |
| `nous_search` | the Search Trichotomy closure + budget + the two keys + eval-gap fallback | P1 |
| `nous_charter` | the constitutional amendment as a self-falsifying clause | P2 |
| `nous_completion` | confluence-completion acceleration (SATURATED/GAP/REFUTED over critical pairs) | P4 |
| `nous_commons` | the cumulative certified commons (idempotent deposit, re-verified lookup, gap-resume) | P5 |
| `nous_train` | the in-tree training harness (sealed-weights load, poison wall, gap-rate dial) | P6 |
| `nous_synth` | the synthesis Tetrachotomy (CANONICAL/PROVISIONAL/GAP/REFUTED + federation wall) — design-ahead, M15 | P7 |

**Engine touches** (`omnia/`), byte-identical at `nous_active=0`:
- `xii_rewrite.iii` — the socket guard in `apply_one` (inert ⇒ the fixed cascade); the
  ranked path `xrw_apply_ranked`; and `apply_specific` completed to dispatch the trit rules
  101–105 (so the ranked path can fire EVERY rule the cascade can — additive; existing
  callers only ever pass 1–40).
- `xii_canonicalise.iii` — the A-1 cap-gap (`_canon_walk_cap`, `XCN_GAPPED`,
  `xii_canonicalise_capped`/`_gapped`).

The chain `nous_socket → nous_policy → nous_features → xii_term` is **acyclic** (features
is xii_term-only — it uses a structural node-count, not `xii_canon_weight`, precisely to
avoid closing a cycle through xii_canonicalise → xii_rewrite → nous_socket).

---

## 7. The gates (the evidence standard)

- **`scripts/verify_nous_differential.sh` — THE KEYSTONE PROOF (C-14), 3-way.**  Every
  engine-exercising corpus test must produce identical verdicts under (a0) `active=0`, (a1)
  `active=1` cascade-order ranker [byte-identical], (a2) `active=1` real policy [same NF by
  confluence].  Mechanism: copy the live archive, ar-replace the engine + proposer-chain
  objects + nous_socket at each (active,mode); never mutates the live archive.  GREEN on 50
  tests (the full XII per-rule corpus + 670_xii_trit + 800 + 804).
- **`scripts/verify_nous_propose_only.sh` — D-18, conservative syntactic.**  (1) no nous
  symbol in the trust root (`TYPES/src`, `COMPILER/BOOT`); (2) `nous_rank` is called only
  from the allowlisted socket `omnia/xii_rewrite.iii`.  The PROOF is the differential gate.
- **`scripts/run_nous_corpus.sh` — the umbrella runner.**  9 KATs (=99 against the live
  archive) + both gates.  `run_corpus.sh` delegates the 800–808 block here.
- **`scripts/nous_export_spines.sh` / `nous_import_weights.sh`** — the ADR-N8 out-of-tree
  file-dump boundary (export certified spines; quarantine + content-address imported
  weights).

---

## 8. Decision log (ADRs)

- **N1** nous is a first-class sealed value (weights content-addressed/versioned).
- **N2** deterministic integer policy first; a trained model is a gap-rate-measured drop-in
  — a weak policy is correctness-safe (only more GAPs).
- **N3** socket, not surgery: carve inert (= the fixed cascade), prove byte-identical, swap.
- **N4** the amendment is a falsifiable clause, not an exception.
- **N5** budget is a sealed cost-lattice quantity, never wall-clock.
- **N6** integrate at M13 (the checker is complete; synthesis M15 deferred).
- **N7** Tetrachotomy + provisional tier design-ahead; correctness and canonicality kept
  split forever; provisional walled off from federation-as-canonical (default-deny).
- **N8** the trainer is out-of-tree; the artifact depends only on sealed integer weights.
- **N9** a sealed, versioned cost linearization makes "optimal" well-typed.
- **N10** the differential gate is the operational proof of the keystone.
- **N11** the socket reorders only confluence-certified relative orders; the R-rule cascade
  priorities (R038/R040 first) are NOT free — only the trit/R block boundary is (§4).

---

## 9. Cross-cutting guardrails (gate-enforced)

trust-root isolation (no kernel→nous edge) · propose-only (every output checked; proven by
the differential gate) · determinism (integer-only; ties by content-address/rule-id; budget
never wall-clock; no u64 `/`,`%` with a bit-63-reachable dividend) · cost-gated engagement
(`nous_should_engage` keeps the policy off the per-eval-step hot path) · reversibility
(every search witnessed) · version-pinning (a rule extension forces retrain+reseal) ·
kill switch (`nous_active()=0` reverts to proven byte-identical behavior, no rebuild) ·
no regress (`nous_kernel`, the P3b machine-code kernel, would be invoked directly, never
re-evaluated through the nous-guided engine — deferred behind a flag).

---

## 10. Deferred / design-ahead

- **`nous_kernel.iii` (P3b)** — the forward pass as a sealed curated machine-code kernel via
  `xii_emit_gen_override`.  Deferred behind a flag until the integer policy is proven.
- **`nous_synth` generation (M15)** — `nous_generate` (constrained decoding + proof-carrying
  emission) is stubbed (returns GAP); the Tetrachotomy DECISION LOGIC is built + tested now.
- **`omnia/sovval.iii` `SV_STATUS_PROVISIONAL`** — the coordinated M5 touch (the user's
  module); nous_synth carries its own status tags until that coordination lands.
- **`xii_critpairs` dynamic critical-pair enumeration (B-8)** — the live wiring is M14's
  first new-rule-family use; `nous_completion`'s M13 KAT is explicitly synthetic.
- **The out-of-tree trainer** — a float/expert-iteration trainer outside libc+BOOT; not part
  of the III artifact (the closure makes any weights safe).
