# Module 11 — the Decision Layer: lean implementation plan
> **STATUS: HISTORICAL RECORD** — an executed campaign plan/ledger, kept immutable as evidence (reunification W6).

## Gate cleared

Written only because **M10 (the Constitution) is verified**: `b286vdo17` `run_corpus PASS=393
FAIL=0`, `673_constitution_holds=99`, `632`/`655` unchanged, `run_xii 93/0`. No
placeholder/deferral/flaw.

## Batch sizing (per the new cadence)

Cadence: plan + implement up to **three** modules, then test once after all three; **plan fewer
if the upcoming module is 2–3× the average effort.** M11 is the **Decision Layer** —
`sat.iii` (661L) + **`smt.iii` (2107L)** + `egraph.iii` + `groebner.iii` — the heaviest subsystem
in the sequence, and its deepest keystone ("egraph **is** XII under a second strategy") genuinely
depends on M13's cost lattice (the apotheosis: "egraph min-cost extraction minimizes over *this*
lattice") and M12's coequalizer. So this batch is **M11 alone** (the 2–3× module); M12 + M13
(both lighter, and where the egraph=coequalizer + cost=extraction bindings co-land) are the next
batch.

## Context

The four organs are complete + gated: `sat` (CDCL — fixed static decision order, **no restarts /
no randomness / no learned heuristic**; `613_sat=99`, `637_sat_at_scale=99`), `smt` (DPLL(T) over
LIA exact-rational simplex + BV bit-blast, Nelson–Oppen; **`smt_check_model` re-verifies every
model**; `635_smt=99`), `egraph` (equality saturation + min-cost extraction; `614=99`), `groebner`
(`638=99`). The apotheosis: make them the kernel's (M9) + Constitution's (M10) **oracle** — every
result is a **re-checkable certificate**, never trusted ("solving is untrusted; the certificate is
sound"); and `egraph` *is* XII (M7) under equality-saturation, min-cost extraction over M13's
lattice. *Final falsifier:* "a solver result accepted without its certificate re-checking; a
non-deterministic solve; an egraph extraction that is not cost-minimal or contradicts an XII
normal form on an equality → red." Key move: *to decide — `smt_check_model`/`sat`/`groebner`
(Goal → Certificate); the illegal move's certificate is consumed without re-check.*

## ADR-1 — Scope: the lean keystone is the oracle re-check + determinism falsifier (clauses #1 + #2); egraph-as-XII (#3) lands with M13

- **Decision.** M11 = an additive corpus falsifier `674_decision_oracle.iii` proving the **oracle
  discipline** on the flagship procedure (SMT — the one with `smt_check_model`): (1) a satisfiable
  goal solves SAT and its model **re-checks** (`smt_check_model==1` — untrusted solve, sound
  certificate); (2) the **same goal solved twice yields the identical model** (the fixed static
  order / no-randomness property — the M19 "re-check, don't re-solve" guarantee); (3) **prove the
  negative** — an infeasible goal (`x==y ∧ x≠y`) is soundly `UNSAT`, never a fabricated SAT
  certificate. This closes apotheosis falsifier clauses #1 (re-check) and #2 (determinism).
- **Rejected — implement egraph-as-XII now.** It is the heaviest unification, and its falsifier
  ("an egraph extraction that is not cost-minimal") requires M13's cost lattice as the extraction
  target (the apotheosis says so explicitly). It cannot fully land before M13; it co-lands with
  the M12 (coequalizer = egraph class) + M13 (cost = extraction target) batch. Deferring it there
  is the apotheosis's own dependency order, not a down-scope.
- **Rejected — edit `sat`/`smt`/`egraph`/`groebner`.** They are complete + gated; the keystone is
  a *property proof* of the existing solvers (the discipline holds), so a corpus falsifier is the
  faithful, additive realization — no module surgery, the existing `613`/`635`/`614`/`638` stay
  untouched.
- **Consequence.** The Decision Layer is proven to be a sound, deterministic, re-checkable oracle
  (the precondition for M9/M10 consuming its certificates). Net: `PASS = 393 + 1`. No module
  changes ⇒ the lib is unchanged; only `run_corpus` registration + the new corpus file.

## Files (create / modify)

| Action | File | What |
|--------|------|------|
| **CREATE** | `STDLIB/corpus/674_decision_oracle.iii` | the oracle falsifier: SMT re-check + determinism + sound-UNSAT (`extern smt_init/smt_bv_new_var/smt_bv_add_eq/smt_bv_add_neq/smt_solve/smt_bv_value/smt_check_model from "smt.iii"`). |
| **MODIFY** | `STDLIB/scripts/run_corpus.sh` | add `[674_decision_oracle]=99` (after `[673_constitution_holds]=99`). |
| **NO CHANGE** | `sat`/`smt`/`egraph`/`groebner` + `build_stdlib.sh` MODULES | M11 is corpus-only (no module edit). |

## Step 0 — Pre-flight

0.1 `glob STDLIB/corpus/674_*.iii` → empty. 0.2 SMT API + verdict codes confirmed from
`aether/reversibility_audit.iii` (read this session): `smt_solve()` returns `SMT_SAT=1` /
`SMT_UNSAT=2`; `smt_bv_new_var(width)`, `smt_bv_add_eq/neq(a,b)`, `smt_bv_value(vr)->u64`,
`smt_check_model()->u8`. 0.3 Baseline `run_corpus FAIL=0`, `run_xii 93/0`.

## Step 1 — CREATE `674_decision_oracle.iii`

`module corpus_674`, the seven SMT externs, `const SMT_SAT:i32=1` / `SMT_UNSAT:i32=2`, then
`main()->u64`:
- **re-check:** `smt_init`; `x=bv_new_var(4)`; `y=bv_new_var(4)`; `bv_add_eq(x,y)`; assert
  `smt_solve()==SMT_SAT` (code 1) and `smt_check_model()==1` (code 2); capture `va=smt_bv_value(x)`.
- **determinism:** repeat the identical session; assert `==SMT_SAT` (3), `check_model==1` (4),
  capture `vb`; assert `va==vb` (5) — same goal ⇒ same model (no randomness).
- **prove the negative (sound UNSAT):** `smt_init`; `x`,`y=bv_new_var(4)`; `bv_add_eq(x,y)`;
  `bv_add_neq(x,y)`; assert `smt_solve()==SMT_UNSAT` (6) — an infeasible goal is `UNSAT`, never a
  fabricated SAT certificate.
- `return 99u64`.

Trap audit: single-line externs/fn; **equality-only** compares (`==`/`!=` on the i32 verdict, the
u8 check, the u64 model values — never `<`/`>`); no module-scope arrays needed (values are u64
locals captured before each `smt_init` reset); ≤4 params; no recursion.

## Step 2 — register + Step 3 — test (the combined gate)

Add `[674_decision_oracle]=99` to `run_corpus.sh`. Then, with the pinned `COMPILED/iiis-2.exe`:
(1) compile-only `674` → `rc=0`. (2) `build_stdlib.sh` → `FAIL=0` + `forge_check` green
(re-confirm the synced scripts are healthy; M11 adds no module, so the lib is unchanged). (3)
`run_corpus.sh` → `FAIL=0`, `674_decision_oracle=99`, regression set unchanged (esp.
`613_sat`/`635_smt`/`637_sat_at_scale`/`638_groebner`/`614_egraph` + the prior keystones
`670`–`673`). (4) `run_xii 93/0`. (5) Manual hand-check: the determinism arm re-solves the
identical instance and the negative arm is genuinely infeasible.

**Single falsifier:** `674 ≠ 99`, or any decision-procedure/keystone test changing, or `run_xii`
regressing → red.

## Standards & mandates

NIH (libc + III `smt`); determinism (equality-only verdicts; the KAT *proves* solve-determinism);
W2 (0-param `main`); W15 (no recursion). Falsifier present + prove-the-negative (sound UNSAT) +
the determinism arm. Apotheosis: realizes M11 clauses #1 (re-check) + #2 (determinism) — the
oracle discipline; egraph-as-XII (#3) deferred to the M12/M13 batch per its cost-lattice
dependency.

## Roadmap

1. Steps 0–2: the oracle falsifier + register.
2. Step 3: gate → `674=99`, `FAIL=0`, `run_xii 93/0`, no regression. Then the M12+M13 batch.
