# Modules 14 + 15 — Memo & Synthesis: batch implementation plan

## Gate cleared

Written only because **M12 + M13 are verified**: `b3k68ug3s` `run_corpus PASS=397 FAIL=0`,
`676_cat_laws=99` + `677_cost_lattice_laws=99`, `620_category`/`615_cost_lattice` unchanged;
`run_xii 93/0`. No placeholder/deferral/flaw. (This turn has carried M7→M13, all gate-green.)

## Batch (≤3 cadence; two modules this turn)

M14 (Memo) + M15 (Synthesis). Scoped to **two** — the turn is already seven modules deep, so I
keep the batch completable with full rigor (the M12 identity-law near-miss shows a rushed API
assumption is the real risk at depth); M16 (Proof-carrying — already partly read this session)
leads the next batch. M14 + M15 co-fit: M15 synthesis *produces* memoized (M14) SovVals, and both
are "optimization/generation, never authority" layers that re-verify through the witness chain.

## Context + gap analysis (both modules complete + well-gated)

- **M14 `memo_lattice.iii` / `aether/memo_query.iii`** (gated `646/654/202/230/662`): a
  content-addressed result cache whose discipline is **soundness, not speed** — `ml_admit`
  verifies the producing chain before insert; `ml_lookup` returning OK means "present, not
  stale," **never trusted** (caller must `ws_lookup_id`); a **stale entry is invisible** to
  lookup; **`ml_revalidate` is the only path back to live** (no un-stale without a chain replay).
  `ml_selftest` (phases 1–3) exercises admit/hit/stale/reval. **Gap:** a *sharp, isolated*
  prove-the-negative for the two load-bearing safety properties — (a) a stale entry is invisible
  to `ml_lookup`, and (b) there is no un-stale except via `ml_revalidate`.
- **M15 `synthesis_spec.iii` / `symbolic_regression.iii`** (gated `648/631`): the canonical spec
  language, **bounded** `SYNSPEC_SLOTS=128`, `SYNSPEC_MAX_CONSTRAINTS=32` (W8), **no statistical
  learning**. Error codes: `SYNSPEC_E_FULL=-2`, `SYNSPEC_E_TOO_MANY_CONSTRAINTS=-7`,
  `SYNSPEC_OK=0`. **Gap:** the W8 **bounds-refusal** (the 33rd constraint / 129th spec is
  *refused*, not silently truncated) + spec-id **determinism** (same spec built twice → same
  content-address/id) as an explicit falsifier (the apotheosis: "a spec exceeding 128/32 that
  isn't refused → red").

The apotheosis keystones proper — memo shared across federation (M19), synthesis as guided search
in the one category (M12) pruned by solvers (M11) and kernel-verified (M9) — are **cross-module
compounds** (M19/M12/M11/M9), deferred. The lean, additive, falsifiable keystone for each is
closing its discipline-gap (the M3/M11/M12/M13 additive-falsifier pattern).

## ADR — Corpus-only, additive; sharpen the discipline gaps; defer the cross-module compounds

Two corpus falsifiers, no module edits (the engines are complete): `678_memo_soundness.iii` and
`679_synthesis_bounds.iii`. Rejected: implementing federation-shared memo / category-search
synthesis now (cross-module compounds). Net `PASS = 397 + 2`; lib unchanged.

## Files

| Action | File | What |
|--------|------|------|
| **CREATE** | `STDLIB/corpus/678_memo_soundness.iii` | stale-invisibility + no-unstale-without-reval (prove-the-negative) over `ml_init/ml_admit/ml_lookup/ml_mark_stale/ml_revalidate`. |
| **CREATE** | `STDLIB/corpus/679_synthesis_bounds.iii` | the W8 bounds-refusal (33rd constraint → `E_TOO_MANY_CONSTRAINTS`; 129th spec → `E_FULL`) + spec-id determinism. |
| **MODIFY** | `STDLIB/scripts/run_corpus.sh` | add `[678_memo_soundness]=99` + `[679_synthesis_bounds]=99` (after `[677_cost_lattice_laws]=99`). |
| **NO CHANGE** | `memo_lattice`/`memo_query`/`synthesis_spec`, `build_stdlib.sh` MODULES | corpus-only batch. |

## Step 0 — Pre-flight (read-only — the construction templates)

0.1 `glob STDLIB/corpus/678_*.iii` + `679_*.iii` → empty (confirm free; the OneDrive sync has been
adding numbers — re-glob right before writing). 0.2 **Read `ml_st_phase1` (+ `ml_st_phase2/3`) in
`memo_lattice.iii`** — the exact `wh_init`/`ws_init` + key/commit/chain_id setup `ml_admit`
requires (it verifies the chain before insert), and the `ml_lookup` return-code for a stale entry
(`MEMOL_*`). This is mandatory: I will not assume the admit/chain contract (the read-before-assert
rule). 0.3 **Grep/read `synthesis_spec.iii`'s actual API** — the real `synspec_*` function names
for creating a spec + adding a constraint (the grep found the consts, not the fns), and `synspec`'s
init. 0.4 Baseline `run_corpus FAIL=0`, `run_xii 93/0`.

## Step 1 — `678_memo_soundness.iii`

`module corpus_678`; externs `ml_init/ml_admit/ml_lookup/ml_mark_stale/ml_revalidate` (+ whatever
chain bootstrap `ml_st_phase1` shows is required, e.g. `wh_init`/`ws_init` + a verifiable
chain_id); module-scope `[u8;32]` `MKEY/MCOMMIT/MCHAIN` + lookup-out sinks. `main()` (per the
Step-0.2 template):
- bootstrap (wh/ws init); `ml_init`; build a key + commit + a **verifiable** chain_id; `ml_admit`
  → OK; `ml_lookup(key)` → OK (present).
- **stale-invisibility (prove the negative):** `ml_mark_stale(key)`; `ml_lookup(key)` → **not
  OK** (the stale entry is invisible — the load-bearing safety property).
- **no un-stale without reval:** assert it's *still* invisible until `ml_revalidate(key)`; then
  `ml_lookup(key)` → OK again (revalidation is the only path back to live).
- distinct return code per check; `99` on pass.

## Step 2 — `679_synthesis_bounds.iii`

`module corpus_679`; externs `synspec_*` (init/create-spec/add-constraint per Step-0.3) + the
error consts inline (`SYNSPEC_OK=0`, `E_FULL=-2`, `E_TOO_MANY_CONSTRAINTS=-7`). `main()`:
- init; create a spec; add **32** constraints → all `OK`; the **33rd** → `E_TOO_MANY_CONSTRAINTS`
  (the W8 per-spec bound is *refused*, not truncated).
- create specs up to **128** (`SYNSPEC_SLOTS`) → all OK; the **129th** → `E_FULL` (the W8 slot
  bound is refused).
- **determinism:** build the *same* spec twice → identical spec-id / content-address (no
  statistical/nondeterministic step).
- `99` on pass. (Exact loop counts + the create/add signatures fixed by Step 0.3.)

## Step 3 — register + Step 4 — combined test (one gate)

Add both `[678_memo_soundness]=99` + `[679_synthesis_bounds]=99` to `run_corpus.sh`. Pinned
`COMPILED/iiis-2.exe`: (1) compile-only `678` + `679` → `rc=0`. (2) `build_stdlib.sh` → `FAIL=0`,
`forge_check` green (synced-state health). (3) `run_corpus.sh` → `FAIL=0`, both new `=99`,
`646_memo_lattice`/`654_memo_query`/`648_synthesis_spec`/`631_symbolic_regression` unchanged
(`PASS=399`). (4) `run_xii 93/0`. (5) Manual hand-check: the stale entry is genuinely invisible
(not just low-confidence), and the 33rd/129th refusals return the exact error codes.

**Single falsifier (batch):** `678 ≠ 99` or `679 ≠ 99`, or `646/654/648/631` changing, or
`run_xii` regressing → red, revert, diagnose before rebuild.

## Standards & mandates

NIH (libc + III); determinism (equality-only; M15 *proves* no-nondeterminism via the spec-id
determinism arm; M14 is the nothing-trusted re-check discipline); W2 (≤4 params); W8 (the very
bounds M15 asserts; `[u8;32]` module-scope scratch); W14/W15. Falsifiers + prove-the-negative
(stale-invisible; bounds-refused). Apotheosis: closes M14's stale-invisibility/re-check discipline
+ M15's W8 bounds-refusal/determinism gaps; the federation-shared-memo (M19) + category-search
synthesis (M12/M11/M9) cross-module compounds are deferred.

## Roadmap

1. Step 0: read `ml_st_phase1` + the `synspec_*` API (the construction templates).
2. Steps 1–3: two corpus discipline-falsifiers + register.
3. Step 4: one combined gate → `678`/`679 = 99`, `FAIL=0`, `run_xii 93/0`, no regression.
