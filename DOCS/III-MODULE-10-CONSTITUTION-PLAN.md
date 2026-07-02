# Module 10 — the Constitution: file-by-file lean implementation plan
> **STATUS: HISTORICAL RECORD** — an executed campaign plan/ledger, kept immutable as evidence (reunification W6).

## Gate cleared

Written only because **Module 9 (the Proof Kernel) is verified fully + perfectly**: `b0gys3qz3`
`run_corpus PASS=392 FAIL=0`, `672_safety_type=99` (Trit+Hexad inductive typing with M3 `reach`
as the Hexad-constructor rule — a non-reachable Hexad term is ⊥, exhaustive over all 729, the
typed-count bound to `iii_hexad_reachable_count()`), the M2/M3/proof-layer regression set
(`666/667/671/636/639/647`) all `=99`; `run_xii 93/0`; build `FAIL=0`, `forge_check` green;
honest scope held (named `safety_type`, not a faked `kernel.iii`). No placeholder/deferral/flaw.

## Context

`DOCS/III-APOTHEOSIS.md` Module 10 — "The Constitution." `numera/constitution.iii` (851L) is
already a charter engine: a clause carries a textual statement, an LTL formula, an
**11-opcode admissibility-predicate bytecode**, a witness-production rule, dependencies, and an
effective epoch; `clause_id = Keccak256(textual)`; `cons_ratify` publishes a
`CLAUSE_RATIFICATION` witness; `cons_eval_predicate(slot, opv, ante, n_ante) -> u8` runs the
bytecode VM (5 boolean combinators `COP_TRUE/FALSE/AND/OR/NOT` over 6 witness-facet predicates
`COP_PRODUCER_EQ/OP_EQ/REVTAG_EQ/PHASE_GE/PILLAR_EQ/HAS_ANTE`) against a 68-byte op-view
(producer@0, op_id@32, phase@64, revtag@65, pillar@66), returning top-of-stack (1=accept,
0=reject; empty pred = open = 1). Gated by `632_constitution=99`, `655_constitution_preserver=99`.

**The apotheosis names the gaps (Depth-D1).** (a) **No paired falsifier:** *"a clause has no
paired negation — the VM verifies but does not falsify… `HOLDS = cons_eval_predicate(verify, w)
∧ cons_eval_predicate(falsify, w_bad)` — the clause must **catch** a constructed bad witness, not
merely pass a good one"* (the POC's whole discipline, the standing "prove the negative" rule).
(b) **LTL carried but unused** (`numera/temporal_logic.iii`'s `tl_eval` exists; the per-clause
`ltl` field isn't folded into the gate). (c) **`run_charter()`** — the build's terminal gate
fusing the positive corpus + `NNN_neg_*` + drift gates + closure meta-gate into one sealed
verdict vector; Pass-2 makes every prior module's falsifier a clause; the charter seal is the
behavioral quine-seal. Final falsifier: *"a guarantee with no clause; a clause with no falsifier;
a green build under any injected corruption; a seal that drifts without a ratified amendment →
red."* Key move: *"to judge — `cons_eval_predicate` + `run_charter` (Witness → Verdict)."*

## ADR-1 — Scope: the lean keystone is gap (a), the paired-falsifier *mechanism*, realized additively over two slots; the terminal-gate build (b)/(c) is deferred

- **Decision.** Module 10 = the paired-falsifier mechanism `HOLDS = verify(good) ∧
  falsify(bad)` as a new exported `cons_clause_holds(verify_slot, falsify_slot, good_opv,
  bad_opv) -> u8` that **reuses `cons_eval_predicate`**: it returns 1 iff the verify-predicate
  *accepts* the good op-view **and** the falsify-predicate *catches* (returns 1 on) the bad
  op-view. A "falsifiable clause" is thus a verify/falsify slot pair. This makes the standing
  "prove the negative" rule a first-class constitutional operation: a clause that cannot catch
  its bad witness **does not HOLD**. Exhaustively falsified by a KAT (`673_constitution_holds`).
- **Rejected — pack a second `falsify` bytecode into the `clause_payload` schema now.** Faithful,
  but it means a new slot table + arena + a `cons_ratify` schema change, risking the audited
  `632` KAT for no extra semantic power (two slots already express "two predicates, one over the
  good witness and one over the bad"). The packed field + a single-clause-carries-both API are a
  compound refinement for the full `run_charter` schema work.
- **Rejected — build `run_charter()` / fold LTL / fuse all suites / quine-seal now.** That is the
  apotheosis's Pass-2/Final *terminal-gate* — a systemwide build (every module's falsifier
  becomes a clause; `temporal_logic` folded; the positive corpus + `NNN_neg_*` + drift + closure
  meta-gate collapse into one sealed verdict). It is the natural culminating module-block, not a
  lean keystone; it lands as its own dedicated effort. The keystone *establishes the verb the
  charter needs* — a clause that judges Witness→Verdict **and catches the negative**.
- **Consequence.** After M10's keystone, the Constitution's clauses can *discriminate* (prove the
  negative), not merely verify — the precondition for every later module-falsifier-as-clause.
  Net: `PASS = 392 + 1`.

## ADR-2 — `cons_clause_holds` semantics (reuse the evaluator; no new VM)

`cons_clause_holds(verify_slot, falsify_slot, good_opv, bad_opv)`:
`a = cons_eval_predicate(verify_slot, good_opv, null, 0)`;
`b = cons_eval_predicate(falsify_slot, bad_opv, null, 0)`; return `1u8` iff `a == 1 ∧ b == 1`,
else `0u8`. (`verify` admits the legitimate; `falsify` is a *bad-case detector* — TRUE on the
constructed bad witness. A clause HOLDS iff both fire.) Antecedents are `null`/0 for the keystone
(the discriminating facets are producer/op/phase/pillar/revtag); antecedent-bearing clauses ride
the same `cons_eval_predicate` and are exercised by the full `run_charter`. W2: 4 params.

## Files (create / modify)

| Action | File | What |
|--------|------|------|
| **MODIFY** | `STDLIB/iii/numera/constitution.iii` | add `cons_clause_holds(verify_slot,falsify_slot,good_opv,bad_opv)->u8 @export` + `cons_holds_selftest()->u64 @export` (the paired-falsifier KAT) + its `CONS_H_*` scratch. **Additive**: no existing fn/const/schema touched, so `632`/`655` are untouched. |
| **CREATE** | `STDLIB/corpus/673_constitution_holds.iii` | corpus KAT wrapper (`extern cons_holds_selftest; main → it`). |
| **MODIFY** | `STDLIB/scripts/run_corpus.sh` | add `[673_constitution_holds]=99` (after `[672_safety_type]=99`). |
| **KEEP** | `constitution.iii`'s existing clause/ratify/eval API, `632`/`655` KATs, `temporal_logic.iii` | untouched; the keystone is purely additive. |
| **NO CHANGE** | `build_stdlib.sh` MODULES | `numera/constitution` already present (adding fns to an existing module). |

## Step 0 — Pre-flight (read-only)

0.1 `glob STDLIB/corpus/673_*.iii` → empty. 0.2 Read the **view-reading opcode KATs** in the
rest of `cons_selftest` (`constitution.iii` ~724–851) — they are the working bytecode templates
for the keystone KAT's verify/falsify predicates (the exact `[COP_PHASE_GE][v]` /
`[COP_REVTAG_EQ][v]` / `…[COP_NOT]` operand encodings + the verdict polarity). 0.3 Confirm the
`CONS_H_*` prefix is free (`grep CONS_H_ STDLIB/iii/numera/constitution.iii`). 0.4 Baseline:
`run_corpus FAIL=0`, `run_xii 93/0`.

## Step 1 — MODIFY `constitution.iii` (additive: the mechanism + its KAT)

`cons_clause_holds` per ADR-2 (single-line `fn`, equality-only `==`, monomorphic). Then
`cons_holds_selftest()->u64` (99=pass), standing up `at_init/wh_init/cons_init`, installing
predicates with the existing `cons_t_install_pred` + building op-views with `cons_t_opview`
(reusing the proven KAT builders), proving:
- **HOLDS (positive):** a real falsifiable clause — `verify` accepts the good view, `falsify`
  catches the bad view — returns `cons_clause_holds == 1`.
- **Prove-the-negative #1 (the named falsifier):** a clause whose `falsify` predicate **fails to
  catch** its bad witness (e.g. `falsify = [COP_FALSE]`, always 0) → `cons_clause_holds == 0`
  (the clause does not HOLD — "a falsify that passes its bad witness → red", caught here as
  not-holding).
- **Prove-the-negative #2:** a clause whose `verify` **rejects the good** witness (e.g. `verify =
  [COP_FALSE]`) → `cons_clause_holds == 0` (a clause that won't admit the legitimate).
- **Discrimination is real:** verify/falsify must read a *view facet* (phase/revtag/pillar), so
  the good and bad views yield different verdicts — not a vacuous `COP_TRUE` pair (a vacuous
  `falsify=COP_TRUE` would "catch" everything; assert that pairing a real `verify` with a bad
  view the `falsify` should *not* fire on returns 0, closing the vacuous-catcher hole).
- `return 99u64` (distinct code per failed check).

## Step 1f — In-file trap audit

Single-line `fn`s; `CONS_H_*` scratch is module-scope (no local `var` arrays); `&CONS_H_* as u64`
addresses; equality-only compares (verdicts/`u8`; the existing unsigned `slot < CONS_MAX_CLAUSES`
is house-accepted); monomorphic (no `||`/fn-pointer/`select`); ≤4 params; W14 (no new loops needed
beyond the builders' bounded ones); W15 no recursion; `CONS_H_` collision-checked.

## Step 2–3 — corpus + registration

`673_constitution_holds.iii`: `module corpus_673` / `extern cons_holds_selftest()->u64 from
"constitution.iii"` / `main → it`. Add `[673_constitution_holds]=99` to `run_corpus.sh`.

## Step 4 — Verify (the gate)

Pinned `COMPILED/iiis-2.exe`. (1) compile-only `constitution.iii` + `673` → `rc=0`. (2)
`build_stdlib.sh` → `FAIL=0`, `constitution` re-aggregated, `forge_check` green (watch the
OneDrive-sync hazard; re-seal per `forge_check.sh --print` only after re-verifying a drifted
katabasis artifact is legitimate). (3) `run_corpus.sh` → `FAIL=0`, `673_constitution_holds=99`,
**`632_constitution=99` + `655_constitution_preserver=99` unchanged** (the additive proof). (4)
`run_xii 93/0`. (5) Manual hand-check: the verify/falsify bytecodes read a view facet (real
discrimination), and the prove-the-negative arms truly return 0.

**Single falsifier:** `673 ≠ 99`, or `632`/`655` changing, or `run_xii` regressing → red, revert,
diagnose before any rebuild.

## Standards & mandates

NIH (libc + III; reuses `cons_eval_predicate`); determinism (equality-only verdicts; monomorphic
dispatch; no float/statistical); W2 (≤4 params), W8 (existing bounds), W14/W15. Falsifier present
+ prove-the-negative (a non-catching `falsify`, a too-strict `verify`, the vacuous-catcher hole).
K 1.00. Apotheosis: realizes M10 gap (a) — `HOLDS = verify ∧ falsify`, "the clause must catch a
constructed bad witness"; the LTL fold + `run_charter` terminal gate + union-of-all-module-
falsifiers + quine-seal are the deferred Pass-2/Final terminal-gate build.

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| wrong opcode operand encoding in KAT predicates | `673` fails to compile/behave | Step 0.2 reads the existing view-reading KATs as working templates |
| touching the clause schema breaks `632` | regression | additive only — `cons_clause_holds`/`cons_holds_selftest` are new; no schema/ratify/eval change |
| vacuous `falsify=COP_TRUE` falsely "holds" | weak keystone | the discrimination arm asserts a real `verify` + a view the `falsify` should not fire on returns 0 |
| OneDrive sync re-drifts forge-closure | build FATAL | documented re-seal flow; gate is the safety net |

## Roadmap

1. Steps 0–3: add the mechanism + KAT + corpus + register.
2. Step 4: gate → `673_constitution_holds=99`, `FAIL=0`, `632`/`655` unchanged, `run_xii 93/0`.
