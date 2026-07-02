# III REUNIFICATION PLAN — the whole-tree, file-by-file perfection program

> **For agentic workers:** execute wave by wave, entry by entry, in order. Every entry is a checkbox.
> An entry is DONE only when its gate command has produced its expected output (real run, real exit code).
> Steps use checkbox (`- [ ]`) syntax for tracking. No entry may be skipped, deferred, or "noted for later."

**Date cut:** 2026-07-01 (drift-delta verified against commit `9cfb9cf8`)
**Goal:** every file in the III tree reaches its perfected disposition — refactored, simplified, fixed, unified, or removed — with a gate proving each step, until the whole tree is one clean, self-verifying substrate with zero litter, zero islands, zero breached ratchets, and zero unadjudicated files.
**Architecture:** this plan COMPILES the census (`DOCS/III-PERFECTION-LEDGER.md`, completeness-proven 2026-07-01) into an ordered execution program, then extends it where the census stopped: the DOCS tree (277 files, explicitly out of ledger scope), the post-ledger arrivals, the corpus numbering ceremony, the sibling top-level dirs at per-file grain, and the anti-regrowth ratchet. Census facts are imported, not re-derived; every judgment that the census did not make is made here, per file.
**Tech stack:** in-tree `iiis-2` compiler · `build_stdlib.sh` spine gate · family KAT runners · seal chain (`seal_sources.sh`/`SEAL.mhash`) · git. Nothing third-party. No Python anywhere in any build, gate, or judgment path — every `.py` this plan names, it names for removal or quarantine.

## THE SUPREME STANDARD (binding on every entry below)

Sooner make 10,000 production-ready implementations of groundbreaking invention than make even the
slightest concession, deferral, or cut corner. Concretely, in this plan's terms:

1. **No deferral verbs.** No entry may resolve to "later," "next audit," "recommend," or "consider."
   Every entry resolves to an action executed and gated, or a KEEP with its live gate named.
2. **DOCUMENTED ≠ VERIFIED.** A claim in a commit message, header, or doc is evidence of intent, not fact.
   Gates are re-run; exit codes are read (8-bit — `$?` is `code & 0xFF`; suspect the measurement first).
3. **The weave is the one primitive.** Fix the substrate, not the consumer. Author nothing III already
   discovers; wire existing faculty before minting new modules.
4. **Every destructive op re-verifies references immediately before it fires.** The tree grows DURING
   work (proven twice on 2026-07-01); a morning grep does not authorize an afternoon delete.
5. **Behavior-preserving means byte-matching where the tree pins bytes** (seed identity, seals,
   golden outputs). A refactor that moves a seal re-runs the seal ceremony in the same step.

## STATE OF THE TREE AT PLAN CUT (drift-delta vs the ledger)

Verified live on 2026-07-01 after ledger commit `de032c60`:

| # | Fact | Consequence for this plan |
|---|---|---|
| D1 | Purge executed (`4a715dae`+`4c42cbb2`): all ~240 ledger DELETE verdicts done, zero misses. | W1 handles only REGROWTH (new litter since), not the ledger's list. |
| D2 | Studio S2 closed (`de032c60`): studio family + SEAL.mhash + 2169_studio_kernel committed. | No S2 work remains; SEAL.mhash is COMMITTED-PINNED (verify in W0). |
| D3 | **The 12 merge pairs EXECUTED** (`1d21c3f6`, 726→713 modules) + execution record (`9cfb9cf8`); commit claims corpus 713/0 + subsystem 23/23 green. | W0 re-verifies the claim (real run), then the plan treats merged modules as the canonical files. 19 corpus retargets landed with it. |
| D4 | Charter increments landed post-ledger: `resultant.iii` + `refract.iii` (aether) + KATs 2177–2184; function-growth in sturm/lattice_march/gas_big/compute_box. | 2 new modules + 8 new KATs need plan rows (W4b/W5) — the ledger never judged them. |
| D5 | **Sibling session live right now**: uncommitted M on merge-adjacent corpus KATs, `build_stdlib.sh`, `libiii_native.a`, `_cov_*.txt` — S1 ratchet work appears in flight. | LAW L6 (sibling protocol) governs W0; do not touch files with uncommitted sibling edits; re-status before every wave. |
| D6 | **43 duplicate corpus numbers** (not just the flagged 2169): 128, 200–209, 262–265, 267, 269, 299, 394, 395, 711, 713, 714, 1050–1054, 1247, 1400–1410, 2012, 2132, 2169. Functionally green (name-keyed EXPECTED) but unique-numbering is violated at scale. | W5 runs ONE renumbering ceremony over all 43 (not piecemeal). |
| D7 | Root litter REGREW post-purge: 145 `_gate_*.log` + 17 `_*.o.s`/`_*.s.s` probes + 5 report `.txt` + 2 `aether_lens*.bmp` + `_emergence_report.txt` + `_numera_audit_findings.txt`. | W1 purges + adds the gitignore/hygiene ratchet so regrowth becomes impossible, not just cleaned. |
| D8 | **7 Python files at root** (`pg_iter/pg_probe/pg_quot_core/pg_sandwich.py`, `softmu_conv/hard/probe.py`, 630 lines) + `pg_RESULTS.md` + `gs3_counter.c` + `win.txt` — parity-games/soft-mu experiment scratch; gs3/win.txt are sibling in-flight. | W1 adjudicates each by name (results→DOCS, .py→delete, sibling files→sibling protocol). |
| D9 | `STDLIB/scripts` Python now down to exactly 2 (`fips205_slhdsa_sha2_ref.py`, `fips205_slhdsa_shake_ref.py`) — the quarantine-pending pair. | W2 executes the quarantine decision. |
| D10 | S1 ratchets still breached (uncovered/gates/dark vs pins 5/2/14; `xii_proof_set_rid` etc. still on the dark list). `build_stdlib.sh` full run FAILS until restored. | W0's centerpiece. |
| D11 | DOCS/ = 277 files; ledger covered it only at dir level ("later index-consolidation pass"). | W6 is fresh per-file judgment — no import available. |
| D12 | TOOLS-QUOTIENT/ still exists (6 files) with its ledger adjudication unexecuted; `STDLIB/build/sovir/` untracked ccsv probe outputs. | W1/W7 rows. |

## VERDICT RUBRIC (every file below carries exactly one)

- **KEEP** — clears the ledger §0 bar; no action; its live gate is named on the row.
- **KEEP-CORE** — same, plus: load-bearing; any future change requires its named gate + seal step.
- **KEEP-LABEL** — keep, but one header/label edit is owed (honesty labels: MODEL-TIER, GENERATED, NON-STANDARD, app-surface). The edit is the action.
- **POLISH** — comment/name/header hygiene only; zero behavior change; corpus green is the gate.
- **SIMPLIFY** — reduce internal complexity, no exported-behavior change; gate = its KATs + seal cascade.
- **REFACTOR** — structural change (split/trim/reorder); gate = full family gates + corpus.
- **FIX** — a named defect or a named missing tooth (gate/falsifier/consumer); the fix is specified on the row.
- **MERGE→X** — absorb into X; includes retargeting every corpus/caller reference in the SAME step; delete source file at the end of the step.
- **DELETE** — remove; row lists the reference re-verify command that must return zero hits immediately before.
- **RELOCATE→X** — move (content preserved), update all referents.
- **RENUMBER→N** — corpus file gets number N; runner EXPECTED lines updated in the same step.
- **QUARANTINE** — move out of the sealed tree to the designated attic; never ships.
- **SIBLING-OWNED** — carries uncommitted edits from the live sibling session; frozen for this plan until `git status` shows it clean; then its printed verdict applies.
- **GENERATED** — machine-produced data; verdict applies to its generator + drift gate, never hand-edits.

## EXECUTION LAWS (bind every wave)

- **L1 — Gate discipline.** A wave closes only on: `bash STDLIB/scripts/build_stdlib.sh` → `FAIL = 0` line present (grep it — a FAIL line masks a stale lib), then `bash STDLIB/scripts/run_corpus.sh` → `PASS=<n> FAIL=0`, plus the wave's named family gates. Timeout per KAT: 25s; `BB_MAX_NODES=128` where applicable.
- **L2 — Atomic merge law.** A MERGE/RENUMBER/RELOCATE and all its referent updates (corpus externs, runner EXPECTED lines, MODULES list, callers) land in ONE commit; the tree is never left half-retargeted.
- **L3 — Seal cascade law.** Any edit to a sealed source re-runs `seal_sources.sh` in the same step; a KAT strengthening that feeds a seal recipe moves the seal — re-pin deliberately, never incidentally.
- **L4 — No-Python law.** No `.py` may be created, invoked, or depended on by any step. Judgment is manual (Read + judgment), evidence layers are shell one-liners.
- **L5 — Fresh-reference law.** Every DELETE/MERGE re-runs its reference grep immediately before firing. The grep command is on the row. Zero hits or the step aborts.
- **L6 — Sibling protocol.** Before each wave: `git status --short`. Any file with uncommitted changes not made by THIS plan's execution is SIBLING-OWNED: skip its rows, log the skip in the wave's execution record, re-adjudicate at the next wave boundary. Never `git checkout --` a live file; never commit a sibling's half-work.
- **L7 — Ratchet law.** Coverage pins (`coverage_pin.txt`=5, `coverage_gate_pin.txt`=2, `coverage_reach_pin.txt`=14, `self_model_pin.txt`=0, `theorem_floor.txt`=0) move DOWN only. Restoring S1 means covering/trimming surface, never raising a pin.
- **L8 — Anti-regrowth ratchet.** W1 installs the hygiene gate; from then on every wave's exit includes it. Litter found by the gate fails the wave — clean it as part of the wave, not "after."
- **L9 — Execution record law.** Each executed wave appends an EXECUTION RECORD to this file: commits, gate outputs (real numbers), deviations, sibling skips. The ledger keeps its own records for census-era actions; this plan's records live here.
- **L10 — Learning law.** Any defect found while executing a row (a trap, a false assumption) is recorded in the wave's execution record AND, if it generalizes, as a new law here — the plan is append-only-improving, like the tree.
- **L11 — New-arrival protocol.** The tree grows DURING this plan (proven three times: arc_sweep mid-ledger; sturm_big + the Turing charter b603493f mid-plan, which pre-adjudicates increments 2185–2193 — more arrivals are COMING). Every wave opens with a 60-second arrival sweep: `git log --oneline <last-recorded>..HEAD` + `git status --short` on the wave's directories. Each new file gets the arrival template before the wave's own rows run: (1) fresh verdict row appended to this plan's owning section, (2) family-runner/EXPECTED registration check, (3) census cross-ref (does it collide with or supersede an existing organ? name the check). An arrival is never silently absorbed into "KEEP by default."

## WAVE TOPOLOGY (dependency-first; each wave gates the next)

| wave | scope | files | exit gate |
|---|---|---|---|
| **W0** | Baseline: verify D3 merge gates, S1 ratchet restoration, sibling adjudication, SEAL verify | ~30 touched | build_stdlib FULL green (ratchets pass) + corpus FAIL=0 |
| **W1** | Root + STDLIB-top regrowth purge, root .py adjudication, hygiene ratchet install | ~180 | hygiene gate green + corpus FAIL=0 (no build impact expected) |
| **W2** | STDLIB/scripts 60 files: FIPS quarantine, S8 ownership manifest, stale-note fix, runner polish | 60 | all family runners + build green |
| **W3** | COMPILER/BOOT 366 + SANCTUM_WRAP 1 + COMPILED 30: frozen-seed rows, stage1_corpus log trim, seed gates | 397 | seed_text_identity_gate + build_iiis2 --check-corpus green |
| **W4a** | numera 309 file-by-file | 309 | corpus + subsystem_test_gate green |
| **W4b** | aether 132 + omnia 155 file-by-file (incl. post-ledger arrivals, ui_exact split, xii_proof split, tp_ sweep KAT, self_atlas swap) | 287 | corpus + sqrtsum + aether-lens + ui + field gates green |
| **W4c** | verba 46 + nous 28 + sanctus 29 + forcefield 25 + eidos 25 file-by-file | 153 | corpus + ripple + topo gates green |
| **W4d** | katabasis 22 + intent 5 + memoria 5 + tempora 6 + sovir 77 + sovtc 54 + independence 12 | 181 | corpus + sovir runners + subsystem gate green |
| **W5** | corpus 1776 + corpus_reject 7 + corpus-litter + THE RENUMBERING CEREMONY (43 numbers) + new-KAT rows | 1783 | run_corpus FAIL=0 with zero duplicate numbers |
| **W6** | DOCS 277 file-by-file (fresh judgment; the ledger never did this) | 277 | doc-link integrity check + INDEX regenerated |
| **W7** | KATABASIS-DEPLOY 130 + R2-GENESIS 15 + FOUNDERS-ANCHOR 7 + TOOLS-QUOTIENT 6 + root build/ + BUILD-ARTIFACTS.md | ~206 | per-dir gates named on rows |
| **W8** | FINALE: ratchet re-pin (down only), whole-plan completeness gate (mechanical name-diff plan vs live glob), final full-gate sweep, execution-record close | — | every gate in this table green in one uninterrupted sweep |

Total files adjudicated by this plan: **~3,850** (every live file in the tree at cut, by name, exactly once — W8 proves it mechanically, the same way the ledger proved its census).

---

# WAVE 0 — BASELINE: make the tree green, absorb the in-flight state

**Goal:** end W0 with: merge-commit claims re-verified by real runs; S1 ratchets restored (the ONLY currently-red build gate); sibling work adjudicated; a full `build_stdlib.sh && run_corpus.sh` green baseline every later wave stands on.
**Why first:** every later wave's exit gate depends on a green spine; today the spine FAILS on ratchets (D10). Nothing else is trustworthy until this is.

### W0.1 — Re-verify the D3 merge execution (trust nothing, re-run)

- [ ] **W0.1.1** Run the two claimed-green gates for real:
  ```bash
  cd "/c/Users/Edwin Boston/OneDrive/Desktop/III"
  bash STDLIB/scripts/run_corpus.sh 2>&1 | tail -5        # expect: PASS=713-era count, FAIL=0
  bash STDLIB/scripts/subsystem_test_gate.sh 2>&1 | tail -3  # expect: 23/23 (or current denominator), 0 fail
  ```
  Expected: `FAIL=0` on both. If corpus fails on a merge-touched KAT (100, 384, 884, 885, 941, 1091, 1203, 1225, 1254, 1255, 1289, 1309, 1310, 1331, 1421–1423, 1509, 1604, 1605, 1741, 45): the retarget was incomplete — read the KAT's extern lines, point them at the absorbed module's exports, re-run. Do NOT revert the merge.
- [ ] **W0.1.2** Verify each of the 12 absorbed modules exports the absorbed surface (spot-verify one export per merge; all 12 rows):

  | merged file | must now export (grep to confirm) | absorbed from |
  |---|---|---|
  | `STDLIB/iii/numera/conjecture_probe.iii` | both `goldbach`-side and `collatz`-side probe entries | goldbach.iii + collatz.iii |
  | `STDLIB/iii/numera/bmc.iii` | k-induction entries (`ki_`/`kinduct` names) | kinduction.iii |
  | `STDLIB/iii/numera/pareto_extraction.iii` | frontier entries | pareto_frontier.iii |
  | `STDLIB/iii/numera/erasure_store.iii` | cas/compression-mode entries | cas_blob.iii |
  | `STDLIB/iii/numera/self_engine.iii` | omega-loop entries | omega_engine.iii |
  | `STDLIB/iii/sanctus/mandate.iii` | M22 clause entries | mandate_m22.iii |
  | `STDLIB/iii/sanctus/quality.iii` | Q7 entries | quality_q7.iii |
  | `STDLIB/iii/forcefield/sovereign_optimizer.iii` | synthesizer compose entries | ripple_synthesizer.iii |
  | `STDLIB/iii/forcefield/scythe_census.iii` | scythe-driver entries | daemon_scythe.iii |
  | `STDLIB/iii/omnia/xii_semantic_verify.iii` | rule/fusion/iflift verify entry points (3) | xii_{rule,fusion,iflift}_verify.iii |
  | `STDLIB/iii/aether/hotstuff_unified.iii` | predict/quorum-preform entries | hotstuff_predict.iii |
  | `STDLIB/iii/aether/compute_box.iii` | R042 sort-meter tier (`xsm_`-successor names) | xii_sort_meter.iii |

  For each: `grep -n "export" <file> | head` + confirm the absorbed capability is present and its corpus KAT (from the D3 retarget list) externs THIS file. Zero placeholder absorptions tolerated — an "absorbed" module whose merged half is a stub is a supreme-standard breach: implement fully or restore the pair.
- [ ] **W0.1.3** Confirm the 12 deleted sources are gone and unreferenced:
  ```bash
  for m in goldbach collatz kinduction pareto_frontier cas_blob omega_engine mandate_m22 quality_q7 ripple_synthesizer daemon_scythe xii_rule_verify xii_fusion_verify xii_iflift_verify hotstuff_predict xii_sort_meter; do
    ls STDLIB/iii/*/$m.iii 2>/dev/null && echo "STILL PRESENT: $m";
    grep -rl "from \"$m.iii\"" STDLIB/corpus STDLIB/iii COMPILER/BOOT 2>/dev/null | grep -v Binary && echo "DANGLING REF: $m";
  done   # expect: no output
  ```

### W0.2 — S1: restore the coverage ratchets (the red gate)

The ratchet computer is `STDLIB/scripts/cov_gate_driver.iii` (via build_stdlib); current reports at repo root (`_cov_report.txt` uncovered, `_cov_gate_report.txt` under-proven gates, `_cov_reach_report.txt` dark surface). Pins: 5 / 2 / 14. Ledger names the offending export families; the fix per family is COVER (add the KAT) or TRIM (de-export debug surface). Sub-entries, each independently gate-able:

- [ ] **W0.2.1 — xii_proof tamper hooks off the dark list via the SPLIT the tree itself prescribes** (`build_stdlib.sh` documents it; ledger §9): split `STDLIB/iii/omnia/xii_proof.iii` (236) into the proof-gadget API (stays `xii_proof.iii`) + `xii_proof_tamper.iii` (test hooks `xii_proof_set_rid`, `xii_proof_flip_ahash`, `xii_proof_set_pos`); update the 2 standalone KATs that call the hooks to extern the tamper module; add ONE positive corpus KAT driving `xii_proof_prove`→`xii_proof_check` green-path; then admit `xii_proof.iii` to MODULES. Gate: build + corpus + the new KAT green; dark-list entries for xii_proof_* gone from `_cov_reach_report.txt`.
- [ ] **W0.2.2 — ui_exact debug surface**: TRIM (de-export `ui_bigc_round_i64dbg` and sibling `*_dbg` exports — internal-only; make them non-exported functions) + COVER the load-bearing uncovered exports (`ui_cub_*`, `ui_cubic_*`, `ui_tcmp_q`, `ui_arc_cover2d_sym`) with one arc/cubic sweep KAT that drives each through a golden coverage table. The full SPLIT of ui_exact happens in W4b; W0 does only the ratchet-relevant trim/cover so the pin passes without moving.
- [ ] **W0.2.3 — aether_lens window surface**: mark `frame_*`/`lens_*` window-pump exports app-surface (the reach ratchet's documented app-exclusion mechanism — same as ui_win's precedent) and COVER the two headless-computable ones (`frame_px`, `lens_t_cmp_fast`) in the aether-lens family gate.
- [ ] **W0.2.4 — ui_win input ring**: `ui_key/ui_getchar/ui_mdown/...` → one headless input-ring KAT (inject synthetic events into the ring, assert drain order) or app-surface marking, per whichever the ratchet's mechanism already supports. Consistency rule: same treatment as W0.2.3.
- [ ] **W0.2.5 — au_*/et_* island exports** (holographic-conformance + eidos-lazy-real families flagged by ledger §16.1): each uncovered export either gains a KAT arm in its existing family gate or is de-exported. No new gate scripts — extend existing runners.
- [ ] **W0.2.6 — sweep the remainder to ≤ pins**: after .1–.5, regenerate reports (full `build_stdlib.sh` run), read the residual lists, and cover/trim each named export the same way until `uncovered ≤ 5`, `gates ≤ 2`, `dark ≤ 14`. Every residual export is adjudicated by name in this row's execution record — no bulk waiver.
- [ ] **W0.2.7** Gate: `bash STDLIB/scripts/build_stdlib.sh 2>&1 | grep -E "FAIL = 0|ratchet|RATCHET"` → build green WITH ratchets passing; commit W0.2 as one commit (or per-sub-entry commits, each green).

### W0.3 — Sibling adjudication + baseline close

- [ ] **W0.3.1** `git status --short` — enumerate remaining uncommitted paths. For each: if touched by W0.1/W0.2 work, commit with this wave; if sibling-owned (not this plan's edits — e.g. `gs3_counter.c`, `win.txt`, `STDLIB/build/sovir/`), record as SIBLING-OWNED in the execution record and leave untouched.
- [ ] **W0.3.2** Verify SEAL state: `git ls-files --error-unmatch SEAL.mhash STDLIB/iii/SEAL.mhash` (expect both tracked) + `bash STDLIB/scripts/seal_sources.sh --verify 2>/dev/null || bash STDLIB/scripts/seal_sources.sh` — if W0.2 edits moved seals, re-pin deliberately in the W0 commit (L3).
- [ ] **W0.3.3** BASELINE GATE (the W0 exit): full `build_stdlib.sh` → `FAIL = 0` + ratchets green; `run_corpus.sh` → `FAIL=0`; `subsystem_test_gate.sh` green; append W0 EXECUTION RECORD here (commits, real gate numbers, sibling skips).

---

## W0 EXECUTION RECORD (2026-07-02)

- **W0.1 merge verification:** all 15 deleted sources gone; all 12 absorptions verified live (export surfaces present; conjecture_probe = the model merge). Inert-frozen note: `stage1_corpus/46+47_q7_gate_*` still name quality_q7.iii — extern strings are part of the byte-pinned seed-parity goldens; link-inert; left frozen deliberately.
- **W0.2 S1 RATCHETS RESTORED (the red gate is green):** uncovered **85 → 3** (pin 5; residual = the sibling charter's in-flight surface g2_mom/pc_sxg/rs_prod_big2), gate-outcomes **10 → 0** (pin 2), dark **205 → 10** (pin 14). Instruments: five new coverage KATs (2450 au organ spine on hand-assembled SVIR — module format `[nfunc][params,nres,blen u16][body]`, loop = `41 …51 body 50 44`; 2451 causal law witnesses; 2452 xii_proof roundtrip through all three tamper hooks; 2453 GLASS seam incl. exact power-basis pins; 2454 seraphyte closed-loop pair) + arms in 2103/2104/2127/2129/2134/2155/2182 + three dead-export deletions (round_i64dbg, view_demo, ui_quit) + **the APP-SURFACE-MODULE designation built into sanctus/corpus_coverage** (per-module raw-text marker; v3-dark-only exemption; v1 untouched; falsifier arm added to 1464: marker-present → excluded+counted, marker-stripped → flagged) applied to 16 app modules.
- **DEVIATION (L10):** W0.2.1's planned xii_proof SPLIT replaced by refutation of its premise — the tamper hooks' documented purpose (tamper-then-recheck) IS a coverable negative arm; 2452 drives both outcomes through all three hooks; both modules ADMITTED to MODULES; the stale exclusion note rewritten in place.
- **L10 learnings:** (a) the gate-outcome v2 metric keys on op‖literal at DIRECT call-site comparisons — let-bound results register nothing; (b) `*/` inside a header comment (ui_sym_*/ui_sel_*) reproduced the known early-close trap; (c) alpha lives in color>>24 for all AA fills; (d) the ratchet caught its own new getter (cov_n_appsurface) — covered with designation teeth in 1464.
- **L11 arrivals absorbed:** sturm_big+2185, rs_*_big2+2186, green_moments+2187, gas_deep+2188, shadow+2189, photon3+2190, graze+2191/2192, rs_elim+2193; the sibling ADOPTED this plan's 2155 frame arm into commit c254ca2e. sqrtsum family 56/0.
- Gates run: build_stdlib FULL green ×2 (FAIL=0 + all three ratchets), fast_check 245x = 5/5 + 146x = 10/10, run_sqrtsum 56/0. Full corpus sweep: launched (record on completion).

## W1 EXECUTION RECORD (2026-07-02)

- Root regrowth purged: 145 `_gate_*.log` + 17 probe `.o.s/.s.s` + 2 bmps + 7 root `.py` (pg_*/softmu_*) + 2 report scratch files — all L5-verified reference-free first. Harvests preserved: the numera call-graph audit → plan W4a.16 (verbatim); softmu conclusions → one paragraph in the relocated parity doc.
- Relocations (git mv): pg_RESULTS.md → DOCS/III-PARITY-GAMES-RESULTS.md · R1-SUBSYSTEMS.md → DOCS/ · BUILD-ARTIFACTS.md → DOCS/ · run_all_corpora.sh → STDLIB/scripts/ (then REWRITTEN: the 2026-05-08 relic assumed repo-root residence and chained 3 corpora; now derives root correctly, chains ALL 13 runners, with completeness teeth vs run_corpus citations).
- Outputs untracked + gitignored: `_cov_*.txt` ×3, `_emergence_report.txt` (+ root patterns `/_gate_*.log`).
- **Hygiene ratchet installed** in fast_check.sh (root + STDLIB-top litter scan, fips-quarantine-aware allowlist) — observed "clean" on first live run.
- SIBLING-OWNED left standing: gs3_counter.c, win.txt, STDLIB/build/sovir/ probe outputs.

## W2 EXECUTION RECORD (2026-07-02)

- FIPS quarantine executed: both generators + both (consumer-less, verified) vector .json → `corpus/_quarantine_wip/fips205/` with README; `scripts/*.py` count = 0.
- **Seraphyte 5→2 unification:** seraphyte_emit_rule.sh = THE one emitter (descriptors subk/2sh/2ss, the 2ss port VERBATIM from the original so the idempotence guard matches the LANDED rule names — the draft's `2sub` naming would have double-emitted; caught before any run); seraphyte_add_rule.sh = the one autonomous-add driver; four pair scripts deleted (zero external callers verified). Idempotence proven live: all three descriptors no-op on the landed rules. LATENT TRAP FIXED: the old emitter instantiated the subk schema under ANY name argument.
- S8: `corpus_families.txt` manifest + run_corpus preamble teeth (dispatch-cited runner must be manifest-declared AND exist) + run_all_corpora completeness teeth. Stale "volatile ser WIP" note struck in run_topo_kats.sh + run_corpus.sh (comment + SKIP reason) with the true decoupling rationale.
- S7: both orphaned APOTHEOSIS comments (C.11, C.14) struck from the MODULES list with tombstones.
- Remaining W2 rows (runner KEEP rows) verified no-change by the family runs.

---

# WAVE 1 — ROOT + STDLIB-TOP REGROWTH PURGE + THE HYGIENE RATCHET

**Goal:** repo root and STDLIB top contain exactly the load-bearing files; litter regrowth becomes STRUCTURALLY impossible (gate, not discipline).
**Standing law for every DELETE below (L5):** run the row's grep immediately before `rm`; zero hits or abort.

### W1.1 — Root litter regrowth (all regenerable session outputs; none referenced by any gate)

- [ ] **W1.1.1 DELETE 145 files `_gate_*.log`** — session gate logs from the merge-execution session.
  Verify: `grep -rl "_gate_" STDLIB/scripts COMPILER/BOOT --include="*.sh" | xargs grep -l "_gate_.*\.log" 2>/dev/null` → expect only writers (`> _gate_x.log`), no readers. Then `rm -f _gate_*.log`.
- [ ] **W1.1.2 DELETE 17 probe artifacts `_*.o.s` / `_*.s.s`** (`_ag.o.s, _agc.o.s, _agprobe.o.s, _gc.o.s, _hs.o.s, _k.o.s, _k1401.o.s..._k1405.o.s, _os.o.s, _rp.o.s, _tg.o.s, _ctrl.s.s, _dup.s.s, _probe_bigint.s.s`) — compiled probe leftovers, regenerable.
- [ ] **W1.1.3 DELETE 5 report snapshots** `_cov_gate_report.txt, _cov_reach_report.txt, _cov_report.txt` (regenerated by every build — but FIRST confirm `build_stdlib.sh`/`cov_gate_driver` write-paths point at root; if the build WRITES them at root, they are outputs: gitignore instead of delete, and the hygiene gate excludes them) + `_emergence_report.txt, _numera_audit_findings.txt` (session scratch; any live finding inside is either already in the ledger or gets a row in W4a — read both before deleting, harvest into W4a rows).
- [ ] **W1.1.4 DELETE 2 root bitmaps** `aether_lens.bmp, aether_lens_exact.bmp` — demo outputs, regenerable by the lens gate.
- [ ] **W1.1.5** `pg_iter.py, pg_probe.py, pg_quot_core.py, pg_sandwich.py` (418 loc) — **DELETE** after harvesting: the parity-games arc's live conclusions belong to `DOCS/` (see W1.2.1). No-Python law; the experiment's evidence value is its RESULTS, not its scripts.
- [ ] **W1.1.6** `softmu_conv.py, softmu_hard.py, softmu_probe.py` (208 loc) — **DELETE** after confirming their findings are recorded (read each header; if a result is not in any DOC, write the 5-line summary into the parity/walls doc chosen in W1.2.1 — the finding survives, the Python does not).
- [ ] **W1.1.7** `gs3_counter.c` (3 loc) + `win.txt` (1 line) — **SIBLING-OWNED** (ledger execution record explicitly left these to the sibling session). If still present AND untouched at W5 boundary: gs3_counter.c is a 3-line scratch counter → DELETE; win.txt content is one line → read it; if it is a session note, DELETE; if it records a result, fold into its arc's DOC.

### W1.2 — Root non-litter adjudication (each by name)

- [ ] **W1.2.1** `pg_RESULTS.md` — **RELOCATE→ `DOCS/III-PARITY-GAMES-RESULTS.md`**; then update the parity-arc memory pointer set: it is the durable record of the pg_* experiments (D8). Cross-link from `DOCS/III-COMMCOMPLEXITY-WALL-FORMAL.md` sibling walls docs if they cite the arc.
- [ ] **W1.2.2** `R1-SUBSYSTEMS.md` — read; if it duplicates `reference` content already in DOCS (subsystem map), MERGE its unique rows into `DOCS/III-SYSTEMS-MAP.md` and delete; if unique, RELOCATE→`DOCS/R1-SUBSYSTEMS.md`. Root keeps zero loose .md except README-class files.
- [ ] **W1.2.3** `BUILD-ARTIFACTS.md` — same treatment: RELOCATE→`DOCS/` (it documents the build-output contract) unless it is the root README for artifacts, in which case keep — decide by reading; record which.
- [ ] **W1.2.4** `run_all_corpora.sh` — read; if it merely chains the family runners, RELOCATE→`STDLIB/scripts/run_all_corpora.sh` beside its peers and update any invoker; root keeps no orphan scripts.
- [ ] **W1.2.5** `SEAL.mhash` (root) — verified committed-pinned in W0.3.2; KEEP (the closure seal). Row exists so the file is named exactly once.
- [ ] **W1.2.6** `build/` (root, 48 files) — untracked output dir: confirm zero tracked files inside (`git ls-files build/ | wc -l` → 0), keep `build/_msvcddc/` only if the MSVC-DDC re-verification is still pending per its README/state — else empty the dir; gitignore `build/` (it stays as the designated demo-output sink).
- [ ] **W1.2.7** `COMPILED/` (30) — KEEP-CRITICAL (deployed compiler lineage every gate pins) — per-file rows in W3.
- [ ] **W1.2.8** `STDLIB/build/sovir/` (untracked ccsv probe outputs `_cp*.{iii,o,o.s,exe,err,log}`) — build outputs INSIDE the build tree: correct location, wrong tracking noise → ensure `.gitignore` covers `STDLIB/build/` untracked outputs (it should already; verify why these show as `??` — likely a missing `sovir/` pattern) and clean stale ones with the build's own `--clean`.

### W1.3 — STDLIB top-level (regrowth check against ledger §15a's already-executed purge)

- [ ] **W1.3.1** `ls STDLIB | grep "^_"` — expect only `_quarantine_wip` (the designated anchor). Any other `_*` entry is regrowth: DELETE by the same L5 protocol, and record WHICH session pattern produced it (feeds the hygiene gate patterns).
- [ ] **W1.3.2** `STDLIB/README.md` + `STDLIB/III-STDLIB-NATIVE-DESIGN.md` — KEEP (the design charter; ledger kept both). Verify III-STDLIB-NATIVE-DESIGN.md's module counts reference the POST-merge tree (713); if stale, one-line count refresh (POLISH).

### W1.4 — THE HYGIENE RATCHET (litter becomes a build failure, not a habit)

- [ ] **W1.4.1** Extend `.gitignore` with the regrowth patterns (root-anchored): `/_gate_*.log`, `/_*.o.s`, `/_*.s.s`, `/_cov_*.txt`, `/*.bmp`, `/*.exe`, `/*.png`, `/*.gif`, `/aether_lens*.bmp`, `/build/`, `STDLIB/build/sovir/_*` — verify each pattern against `git status` before/after (no tracked-file shadowing: `git ls-files -ci --exclude-standard` must stay empty).
- [ ] **W1.4.2** Add a `hygiene` step INSIDE `fast_check.sh` (wire into the EXISTING gate, no new island script): a POSIX-sh block that fails if `ls` finds litter-pattern files at root or `STDLIB/` top outside the allowlist (README.md, III-STDLIB-NATIVE-DESIGN.md, SEAL.mhash, the named dirs, `_quarantine_wip`). Emit the offending names. Gate: seed a fake `_gate_x.log`, run `fast_check.sh`, expect FAIL naming it; remove, expect green. (This is the L8 ratchet's teeth — a gate that has never failed is not yet a gate.)
- [ ] **W1.4.3** W1 exit: `git status --short` clean except SIBLING-OWNED rows; `fast_check.sh` green including the new hygiene step; corpus untouched (no .iii changed this wave — confirm `git diff --stat HEAD -- STDLIB/iii` empty); append W1 EXECUTION RECORD.

---

# WAVE 2 — STDLIB/scripts: the gate spine, perfected (59 live files + 1 arriving from W1)

**Goal:** every script is a named, load-bearing gate; the two remaining `.py` leave the sealed tree; the S8 double-encoded corpus ownership becomes ONE manifest; the seraphyte rule-family scripts unify; the stale volatility note dies.
**Evidence base:** live listing 2026-07-01 (59 files, 8,500 lines total); `run_corpus.sh` SKIP structure read at lines 1784–1830; seraphyte pair diffs read; cartographer gate verified already-native (carto.c + carto_gate.iii, zero `.py` in `build_stdlib.sh`).

### W2.1 — The two spine giants

- [ ] **`build_stdlib.sh` (1935) — KEEP-CORE + POLISH (S7):** sweep the MODULES-list comments to match the post-merge reality: delete the orphaned "tournament quorum optimizer" (C.11) comment, re-seat the "unified_cost_manifold" (C.8) comment off `aether/bone_marrow`, and re-verify every comment names the module line that follows it (`grep -n -A1 "^# " STDLIB/scripts/build_stdlib.sh | less` sweep). Comment-only edit; gate: full build green (proves no accidental line damage).
- [ ] **`run_corpus.sh` (2003) — KEEP-CORE + FIX (stale note) + REFACTOR (S8 manifest):**
  1. FIX line ~1829: the topo SKIP reason "depends on volatile ser_antiunify/ser_petri WIP" is FALSE since 2026-06-27 (both are LIB, c41/c16, stable). Rewrite to the true reason: "links the archive directly so core-gate stays decoupled from ser_* signature churn — same discipline as the UI app KATs." Same fix in `run_topo_kats.sh:4-5`.
  2. REFACTOR (S8): extract the nine family SKIP patterns into `STDLIB/scripts/corpus_families.txt` (format: `glob_pattern|owner_runner`, one line per family, comments allowed). `run_corpus.sh` builds its SKIP dispatch by reading the manifest; each family runner gains a 3-line manifest self-check (its member enumeration must match its manifest line or it fails loudly). ONE source of ownership truth; adding a KAT to a family becomes a one-line manifest edit.
  Gate: `run_corpus.sh` → identical PASS/SKIP/FAIL counts before vs after (byte-log diff of the RESULTS summary), then every family runner green.

### W2.2 — Family runners (13) — KEEP-CORE all; rows for completeness + one FIX each where named

| file | loc | verdict / action | gate |
|---|---|---|---|
| run_xii_corpus.sh | 108 | KEEP-CORE (own EXPECTED table) | itself green |
| run_xii_antidrift.sh | 116 | KEEP-CORE (curated-payload drift teeth) | itself green |
| run_ui_kats.sh | 48 | KEEP-CORE | itself |
| run_field_kats.sh | 42 | KEEP-CORE | itself |
| run_bigcov_kats.sh | 60 | KEEP-CORE | itself |
| run_sqrtsum_kats.sh | 99 | KEEP-CORE (46/0 as of 2184) | itself |
| run_aether_lens_kats.sh | 50 | KEEP-CORE | itself |
| run_ripple_kats.sh | 45 | KEEP-CORE | itself |
| run_topo_kats.sh | 43 | KEEP-CORE + FIX header note (W2.1.1) | itself |
| run_bench_corpus.sh | 264 | KEEP-CORE (perf witness chain) | itself |
| run_autogenesis_corpus.sh | 43 | KEEP-CORE | itself |
| run_nous_corpus.sh | 53 | KEEP-CORE | itself |
| run_all_corpora.sh | (root, arrives via W1.2.4) | RELOCATE here; verify it chains ALL runners incl. sqrtsum/lens/topo (post-2184 list); add manifest-check so a new family cannot be forgotten | one full chained run green |

### W2.3 — Seraphyte chain (9) — REFACTOR (UNIFY the rule family), keep the loop

The three rules (subk · 2shift · 2sub) are one spine instantiated three times; the tree itself says so (`seraphyte_emit_2sub.sh` header: "proving the emitter is a rule-FAMILY producer"). Unify:

- [ ] **`seraphyte_emit_rule.sh` (149) — KEEP-CORE, becomes THE one emitter:** absorb the 2shift/2sub emitters as descriptor entries (shape, op, extractor count, target regs) in one descriptor table at the top; arm-source generation branches on descriptor, not on script identity. Idempotence guards preserved per rule (`cgopt_mul_2sh_admit` / `_2sub_` / subk greps).
- [ ] **`seraphyte_emit_2shift.sh` (167) + `seraphyte_emit_2sub.sh` (176) — MERGE→seraphyte_emit_rule.sh**, then DELETE both. Pre-delete grep: `grep -rl "emit_2shift\|emit_2sub" STDLIB/scripts COMPILER/BOOT DOCS` → update `seraphyte_reseal_driver.sh` + goldtest callers to `seraphyte_emit_rule.sh <rule>` form first.
- [ ] **`seraphyte_add_2shift.sh` (129) + `seraphyte_add_2sub.sh` (123) — MERGE→ one `seraphyte_add_rule.sh`** parameterized by rule name (workdir `_add<rule>`, MULS vector per rule from a case block, everything else shared), then DELETE both. The MULS vectors move verbatim (10/6/12/20 for 2sh; 14/28/30/56/60/1022 for 2sub).
- [ ] **`seraphyte_reseal_driver.sh` (245) — KEEP-CORE + update invocations** to the unified pair.
- [ ] **`seraphyte_confluence_goldtest.sh` (82) + `seraphyte_synth_goldtest.sh` (74) — KEEP** (the teeth) + update invocations.
- [ ] **`pcc_synthesize.sh` (70) — KEEP** (proof-carrying synthesis entry; distinct role).
- Gate for the whole W2.3 block: both goldtests green + reseal driver full loop green + `bash seraphyte_emit_rule.sh 2shift` twice (second run must print the idempotent no-op line) + build + corpus green (compiler-adjacent scripts touched ⇒ full spine).

### W2.4 — Build/master gates + verifiers + negatives + pins (rows for every remaining file)

| file | loc | verdict | action / gate |
|---|---|---|---|
| fast_check.sh | 108 | KEEP-CORE | gains the W1.4.2 hygiene step; itself green |
| seal_sources.sh | 166 | KEEP-CORE | L3's instrument; no change |
| audit_sovereign.sh | 73 | KEEP-CORE | no change |
| reject_conformance.sh | 48 | KEEP-CORE | no change |
| subsystem_test_gate.sh | 114 | KEEP-CORE | no change |
| affine_audit_gate.sh | 68 | KEEP-CORE | no change |
| cg_optrules_bind_gate.sh | 153 | KEEP-CORE | no change |
| onelang_realtree_gate.sh | 42 | KEEP-CORE | no change |
| onelang_gate.iii | 124 | KEEP-CORE (native gate organ) | no change |
| cov_gate_driver.iii | 52 | KEEP-CORE (the ratchet computer) | no change |
| build_studio.sh | 43 | KEEP-CORE | no change |
| ripple_apply.sh | 92 | KEEP-CORE | no change |
| ripple_extract.sh | 79 | KEEP-CORE | no change |
| test_cap_flow_static_negative.sh | 72 | KEEP (negative teeth) | no change |
| test_cross_fn_pe_negative.sh | 83 | KEEP | no change |
| test_intent_kind_static_negative.sh | 63 | KEEP | no change |
| test_k_floor_static_negative.sh | 62 | KEEP | no change |
| test_module_const_scope.sh | 53 | KEEP | no change |
| test_return_kind_static_negative.sh | 59 | KEEP | no change |
| test_type_alias_multihop_negative.sh | 66 | KEEP | no change |
| verify_autogenesis_propose_only.sh | 60 | KEEP | no change |
| verify_h2_one_address.sh | 81 | KEEP | no change |
| verify_nous_differential.sh | 106 | KEEP | no change |
| verify_nous_propose_only.sh | 63 | KEEP | no change |
| verify_reach_remote.sh | 49 | KEEP-LABEL | header already labels live-remote need; verify label present, else add |
| verify_sha256_dedup.sh | 47 | KEEP | no change |
| nous_export_spines.sh | 35 | KEEP | no change |
| nous_import_weights.sh | 26 | KEEP | no change |
| coverage_pin.txt / coverage_gate_pin.txt / coverage_reach_pin.txt | 0 | KEEP-CORE (ratchet pins; L7) | W8 re-pins downward |
| self_model_pin.txt / theorem_floor.txt | 0 | KEEP-CORE (down-only floors) | W8 |

- [ ] **W2.4.1 — Python exit (D9):** `fips205_slhdsa_sha2_ref.py` (67) + `fips205_slhdsa_shake_ref.py` (222) — **QUARANTINE→ `STDLIB/corpus/_quarantine_wip/fips205/`** (the tree's designated quarantine anchor) with a 3-line README: offline FIPS-205 reference-vector generators; their committed outputs are the `_fips205_*.json` vectors. FIRST check the vector consumer path: `grep -rn "_fips205" STDLIB/corpus/*.iii STDLIB/iii/numera/slhdsa.iii` — if any KAT opens the .json by path, vectors stay where the KAT reads them (only the generators move). After the move: `grep -rn "\.py" STDLIB/scripts/` → **zero hits** = the scripts dir is Python-free. Gate: slhdsa KATs green.
- [ ] **W2.4.2 — W2 exit:** all 13 family runners green + full spine (L1) + `ls STDLIB/scripts/*.py 2>/dev/null | wc -l` → 0 + append W2 EXECUTION RECORD.

---

# WAVE 3 — COMPILER/BOOT (134 top + 4 subdirs) + SANCTUM_WRAP (1) + COMPILED (30)

**Goal:** the compiler province is confirmed frozen-perfect: seed identity gated, no litter, every artifact adjudicated. This wave is mostly verification — the purge already executed §13g's 19 deletes (verified live: zero `.py`, zero `_*`, zero `.log` in BOOT top; stage1_corpus logs already trimmed 289→232).
**Standing rule:** the C seed is KEEP-FROZEN — byte-equivalence maintenance only; the .iii compiler is KEEP-CORE — changes only through the fixpoint discipline (`iiis-2 == iiis-3`).

### W3.1 — The self-hosted compiler, 27 .iii — KEEP-CORE each (the crown)

`ast.iii 4457 · parse.iii 4027 · cg_r3.iii 3848 · lex.iii 2447 · sema.iii 2140 · link.iii 1557 · cg_r0.iii 1579 · main.iii 1290 · sid.iii 1229 · emit.iii 1104 · proof.iii 1050 · jit_emit.iii 982 · witness_alloc.iii 930 · emit_sanctum.iii 887 · hexad_check.iii 619 · acc.iii 542 · ceiling.iii 306 · cg_r3_xii_adapter.iii 261 · iii_cg_pe_iiis1.iii 236 · lex_rt.iii 189 · cg_sha.iii 187 · cg_opt_rules.iii 185 · cg_typeclass.iii 179 · cg_r3_xii.iii 170 · sema_xii_adapter.iii 147 · xii_ldil.iii 113 · cg_rm1.iii 31 + cg_rm2.iii 31 (verified facades, NOT stubs — the thinness IS the R-1↔R-2 unification).`
- [ ] **W3.1.1** No content action (sizes are the uniformity exception the criteria allow: they ARE the compiler). Gate row: `bash COMPILER/BOOT/build_iiis2.sh --check-corpus` green + fixpoint `iiis-2 == iiis-3` mhash equality (`diff COMPILED/iiis-2.exe.mhash COMPILED/iiis-3.exe.mhash` after a fixpoint build — expect the documented equality discipline, not necessarily byte-equal files if the discipline pins differently: follow `build_iiis3.sh`'s own check).

### W3.2 — The C seed (iiis-0), 21 .c + 21 .h — KEEP-FROZEN each

All 42 named in ledger §13b (lex.c 2025 … rm2_driver.c 21; ast.h 1193 … iii_compositions.h 299 GENERATED). No edits, ever, except byte-equivalence maintenance driven by `seed_text_identity_gate.sh`.
- [ ] **W3.2.1** Gate row: `bash COMPILER/BOOT/seed_text_identity_gate.sh` green + `bash COMPILER/BOOT/trusted_base_check.sh` green. Any drift = stop, root-cause (seal-drift class defects are known-fixed; a new one is a finding, not a re-pin).

### W3.3 — Hand asm (5) + XII C tools (8) + .defs (7) + seals/flags (7) + docs (2) — KEEP each

.s: `bench_helpers.s 224 · cpuid_helper.s 37 · resolver_hot.s 174 · resolver_unit.s 718 · resolver_unit_avx512.s 665`. XII tools: `gen_trinity_certs.c 188 · gen_xii_anchor_keypair.c 88 · gen_xii_horizons.c 102 · gen_xii_lattice.c 235 · gen_xii_manifest.c 457 · gen_xii_r1.c 105 · sign_xii_manifest.c 111 · verify_xii_manifest.c 50`. .defs (drift-gated single sources): `iii_bar_layout.def 38 · iii_census.def 45 · iii_compositions.def 335 · iii_cycle_family.def 41 · iii_ring_lattice.def 37 · iii_svm_layout.def 24 · iii_vmexit.def 36`. Seals/flags: `iiis-1.mhash · iiis-2.mhash · iiis-3.mhash · xii_manifest.bin · xii_manifest.mhash.golden · xii_manifest.mhash.presig · xii_anchor_signed.flag`. Docs: `STAGE1-PORT-INDEX.md 123 · lex_port_audit.md 182`.
- [ ] **W3.3.1** Gate row: the six `gen_*.sh` drift gates green (run via build_stdlib's def-drift steps) + `bash COMPILER/BOOT/build_xii.sh` green + `seal_xii_final.sh --verify`-equivalent check per its own usage line.

### W3.4 — Gates & build scripts (27) + compiler-side KATs/fixtures (8) — KEEP each

All 27 gate scripts named in ledger §13d (`build_iiis0.sh … verify_step.sh`) and 8 fixtures in §13e (`affine_audit.iii 653 · affine_audit_kat.iii 41 · affine_audit_sound.iii 98 · cgsha_kat.iii 52 · forge_keccak_driver.iii 66 · rm_match_sample.iii 14 · rm_str_sample.iii 11 · rm2_sample.iii 42`).
- [ ] **W3.4.1** POLISH sweep: `grep -l "TODO\|FIXME\|XXX" COMPILER/BOOT/*.sh` — adjudicate each hit (a live TODO in a gate script is a deferral; resolve or strike). Expected: zero or few; each named in the execution record.

### W3.5 — Subdirs

| entry | files | verdict / action |
|---|---|---|
| ceremonies/ | 13 `.cert` | KEEP (the Ω-ceremony seal chain) — no action |
| opt/ | production_gate.sh · soundness_falsifier.sh · universality_gate.sh | KEEP all 3 — no action |
| cg_r0_gate/ | gprobe.iii · rmain.iii · rprobe.iii | KEEP all 3 (r0 gate fixtures) — no action |
| stage1_corpus/ | 232 (60 .iii sources · 82 golden .s · 32 .witness.json · 57 .exe · 1 .sh) | KEEP-CRITICAL sources+goldens+witnesses+runner. **ADJUDICATE the 57 .exe:** `git ls-files COMPILER/BOOT/stage1_corpus/*.exe \| wc -l` — if tracked: untrack + gitignore (witness.json/mhash pin the bytes; committed exes are redundant binary mass); if untracked: they are gate outputs in place — leave, add to hygiene-gate allowlist. Record which. |

### W3.6 — SANCTUM_WRAP + COMPILED per-file

- [ ] **`COMPILER/SANCTUM_WRAP/iiis_sanctum_compile.c` (7.6KB) — KEEP-CORE** (the sanctum-compile wrapper; its exe is pinned in COMPILED). Gate: its build path in the sanctum gate scripts.
- [ ] **COMPILED/ 30 rows — KEEP-CRITICAL all**, each named: `iiis-0.exe(+.mhash,+.witness.json) · iiis-1.exe(+.mhash,+.witness.json) · iiis-2.exe(+.mhash,+.witness.json,+.xii_witness.json,+.emitgen-baseline,+.emitgen-baseline.mhash) · iiis-3.exe(+.mhash,+.witness.json) · iiis-2.mhash · iiis-3.mhash · iiis_sanctum_compile.exe · gen_trinity_certs.exe · gen_xii_anchor_keypair.exe · gen_xii_horizons.exe · gen_xii_lattice.exe · gen_xii_manifest.exe · gen_xii_r1.exe · sign_xii_manifest.exe · verify_xii_manifest.exe · xii_horizons.mhash.golden · xii_lattice.bin · xii_lattice.mhash.golden`.
  Two adjudication rows inside:
  1. `gen_xii_horizons.exe.run` — read it (`file` + head): if a run-log artifact, DELETE; if a required runner stamp, KEEP-LABEL with one comment line in the producing script saying so.
  2. The dual mhash pairs (`iiis-2.exe.mhash` vs `iiis-2.mhash`, same for -3): verify both are produced/consumed by the build scripts (`grep -rn "iiis-2.mhash\|iiis-2.exe.mhash" COMPILER/BOOT/*.sh STDLIB/scripts/*.sh | head`) — each must have a consumer; an unconsumed seal file is litter → DELETE the unconsumed one; both consumed → KEEP both, record the two roles.
- [ ] **W3.7 — W3 exit:** seed identity + trusted base + build_iiis2 --check-corpus + def-drift gates all green in one sweep; append W3 EXECUTION RECORD.

---

# WAVE 4a — STDLIB/iii/numera: 309 files, every one

**Evidence base:** live `wc -l` listing 2026-07-01 (309 files, 97,986 loc); ledger §8b verdicts imported; five census-hole modules fresh-read and fresh-verdicted (see W4a.14); merge products verified live (bmc carries MODEL-TIER label; conjecture_probe exports both absorbed surfaces).
**CENSUS CORRIGENDUM (recorded here, executed as W4a.14):** the ledger's §17 completeness gate matched module names anywhere in the file, so five numera modules whose only mention was an APPENDIX-A extern-subject were never verdicted: `certified_morphism, combinator, cpufeat, synthesis_spec, temporal_logic`. This plan's W8 completeness gate is strict-form (name must appear in a verdict row of §2–§11-equivalent sections). A one-line corrigendum is owed to the ledger's §17 (action row W4a.14.6).

### W4a.1 — Kernel & proof substrate (20) — KEEP-CORE all; gate: corpus + seal chain

`typecheck 3502 (c289 — THE CIC kernel) · ccl 1471 (trusted-base reducer, seal-gated) · proof_term 1535 · theorem_commons 199 · theorem_carrier 746 · k0_referee 164 · golden_shift 150 · curry_howard 315 · induct 104 · safety_type 116 · congruence_closure 311 · congruence 228 (the global merge ring — distinct, labeled) · proof_replay 115 · proof_replay_cache 92 · proof_parallel 95 · proof_stark 134 · proof_jit 100 · proof_carrying 701 · quine_verifier 325 (W25) · translation_validation 82.`
No content actions. The three theorem stores (carrier=artifact format, commons=session registry, nous/theorem_grow=persistent DAG) are layered, not duplicated — labels verified present per ledger.

### W4a.2 — Deciders & solvers (12) — KEEP-CORE all; gate: corpus (egraph additionally live in cg_r3 via seg_*)

`sat 805 · sat_at_scale 851 · smt 2229 · bv_bits 1012 (c329, widest-consumed module in III) · bv_ring 713 · bv_commons 204 · egraph 2036 (c82, live in the compiler) · egraph_stochastic 87 · mcmc_egraph 162 · relational_ematch 171 · egraph_hw_ematch 113 · groebner 1464.`
No content actions.

### W4a.3 — Arithmetic + platform core (29) — KEEP-CORE all; gate: corpus

`scalar 330 · checked 93 · modular 128 · sat_arith 122 · fixed 224 · fixed_extra 192 · q128 271 · q128_f64 212 · bigint 1016 (c240; 64-slot handle table + bump-arena semantics are DOCUMENTED constraints, not bugs) · bigint_div 1129 (Knuth) · bigint_karatsuba 195 · ntt_bigint 307 · endian 152 · bitops 132 · hex 102 · barrett 186 · modular_mont 167 · field 214 · field_crystal 122 · checked_crystal 174 · scalar_provenance 141 · crt 172 · trit 143 · uncertainty 363 · logic6 156 · voice 112 · tense 63 · quine6 114 · cpufeat 174.`
- [ ] **W4a.3.1 `cpufeat` (census-hole repair) — KEEP-CORE, fresh verdict:** native CPUID/XGETBV via `COMPILER/BOOT/cpuid_helper.s`, replaced the kernel32 `IsProcessorFeaturePresent` umbilical — a sovereignty organ that bottoms on silicon. Gated (corpus 149_cpufeat_dispatch + 150_cpufeat_only; consumer sha256_dispatch). No content action; the repair is its ROW existing.

### W4a.4 — NIH crypto suite (48) — KEEP all (KAT/vector-gated); one label row

`sha256 494 · sha256_ni 494 · sha256_dispatch 107 · sha512 430 · sha3_256 42 · sha3_512 40 · shake128 41 · shake256 39 · keccak 445 · keccak256 257 · keccak_sponge 114 · blake2s 534 · hmac 164 · hkdf 194 · pbkdf2 214 · drbg 188 · aes 501 · aes_gcm 629 · aes_siv 252 · chacha20 364 · poly1305 466 · chacha20_poly1305 168 · xchacha20_poly1305 68 · x25519 185 · fe25519 551 · ed_scalar_modl 213 · crypt_ed25519 303 · fp256 273 · fn256 278 · ec256 238 · ecdsa_p256 239 · fp384 228 · fn384 222 · ec384 220 · ecdsa_p384 193 · rsa 968 · mldsa 1260 · mlkem 709 · pq_params 229 · pq_dispatch 136 · ntt_ctx 107 · siphash 126 · murmur3 62 · adler32 56 · crc32 122 · xoshiro 249 · weave_blocks 115 · slhdsa 957.`
- [ ] **W4a.4.1 `slhdsa` — KEEP-LABEL:** verify the E-SLH-2 NON-STANDARD (not FIPS-205 wire-interoperable) declaration is the header's FIRST content line (`sed -n '3,6p' STDLIB/iii/numera/slhdsa.iii`); if buried, hoist it. Cross-ref: its offline reference generators quarantined by W2.4.1. Gate: slhdsa KATs green (comment-only edit).

### W4a.5 — ZK stack (12) — KEEP all; gate: corpus + sovir zk runners

`zk_field 1588 · zk_air 1233 · zk_stark 522 · zk_snark 400 · zk_stark_seal 107 · zk_prune 339 · zk_rev 121 · zk_ext2 73 · zk_ext4 48 · ntt 349 · ntt_fri_organ 137 · merkle 466.`
No content actions (PERM/trace-LDT holes fixed and gated in prior campaigns; the gates stand).

### W4a.6 — Weave / invention program (11) — KEEP all + one FIX + one hole repair

`invent 1309 (c88) · present 440 · primweb 245 · weave 99 · weave_graph 785 · weave_self 361 · weave_interfile 179 · weave_forge 58 · gx_bridge 65 · symbolic_regression 1658 · synthesis_spec 770.`
- [ ] **W4a.6.1 `symbolic_regression` — FIX (thinnest gate-to-mass in numera: 1658 loc, 2 live corpus refs):** add TWO falsifier KATs: (a) wrong-form rejection — data generated from `x²+3x` must NOT admit a form family excluding it while a matching form is in the basis (assert the engine returns the true form, and that a deliberately-excluded-basis run returns NO-FIT rather than a force-fit); (b) overfit refusal — pure-noise table must return NO-FIT, never an N-term interpolation. Numbers assigned by the W5 ceremony; registered in run_corpus EXPECTED. Gate: both KATs green + existing 2 stay green.
- [ ] **W4a.6.2 `synthesis_spec` (census-hole repair) — KEEP, fresh verdict:** the canonical synthesis-problem spec language (signature + algebraic constraints + 8-D cost budget + verifier ref; Keccak256 content-addressed). Gated (corpus 648_synthesis_spec, 679_synthesis_bounds). Verify its declared consumers exist live: `grep -rln "synthesis_spec" STDLIB/iii --include="*.iii" | grep -v synthesis_spec.iii` must name ≥1 organ (expect nous/algo_synth chain); if zero, it is an island → wire its spec type into `algo_synth` as the input format (spec'd: algo_synth's entry takes the encoded spec, not ad-hoc params) in THIS wave.

### W4a.7 — Cost / microarch stack (9) — KEEP 7 + THE MERGE THAT FIRES NOW + 1 verified

`cost_lattice 662 · cost_calculus 625 · microarch_model 557 · costed_cat 210 · entropy_monitor 436 · tiebreak 214 · algebraic_time 55` — KEEP all 7, no action. `pareto_extraction 274` — KEEP (absorbed frontier; verified by W0.1.2).
- [ ] **W4a.7.1 `cost_lattice_synth` (525) — MERGE→cost_lattice (the ledger's own trigger FIRED):** ledger flagged "if still k0 at next audit, MERGE"; this plan IS that audit and the live grep (2026-07-01) shows zero organ callers (only GENERATED-data mentions in world_graph/self_atlas_data + its own 2 corpus KATs). Execute: move the V3 extended-vector synthesis into `cost_lattice.iii` as its synthesis section (exports keep their names — no caller churn by construction since there are no callers); retarget its 2 corpus KATs' `from "cost_lattice_synth.iii"` externs to `cost_lattice.iii`; L5 pre-delete grep `grep -rln "cost_lattice_synth" STDLIB COMPILER --include="*.iii"` → only the 2 retargeted KATs + generated-data files (regenerate those in W4b's self_atlas_data step); delete the file; remove its MODULES line from build_stdlib.sh. Gate: build + corpus green; L2 one commit.

### W4a.8 — Verified-algorithms shelf (31) — KEEP all; two merge products verified

`dijkstra 135 · binary_search 101 · kmp 146 · levenshtein 121 · lcs 166 · lis 148 · fenwick 124 · segment_tree 138 · knapsack 121 · coin_change 105 · inversion_count 122 · sieve 119 · gray_code 108 · catalan 92 · rms 116 · matrix_ring 160 · ring_opt 111 · huffman 328 · elias 150 · lzss 233 · lzh 163 · bitio 158 · galois 964 · gf_poly 250 · rscode 475 · rscode_ec 253 · hamming_secded 204 · shamir 296 · threshold_vault 236.`
- `erasure_store 439` — KEEP; absorbed cas_blob's compression-mode tier (verified W0.1.2).
- `conjecture_probe 173` — KEEP; the goldbach+collatz unification, live-verified: honest header ("one epistemic artifact, two famous instances"), both `goldbach_*` and `collatz_*` export families present (9 exports). Model row for what a merge should look like.

### W4a.9 — Optimizer-model stack (33) — KEEP all + THE LABEL SWEEP

`ssa 119 · gvn 137 · dce 117 · sccp 158 · dominators 129 · liveness 111 · reg_alloc 240 · isel 117 · list_schedule 129 · rewrite_schedule 141 · loop_optimizer 115 · loop_pipeline 107 · bce 157 · branch_elim 101 · vectorizer 105 · align_domain 108 · interval_lattice 155 · widening 129 · kleene_fixpoint 162 · reduced_product 134 · value_range_prover 116 · loop_bounds_prover 77 · safety_prover 320 · range_check 102 · taint_analysis 140 · ptr_provenance 179 · mem_rewrite 235 · tso 295 · heaplet 259 · sep_logic 285 · csl 220 · affine_check 111 · bmc 194.`
- [ ] **W4a.9.1 — MODEL-TIER label sweep:** `bmc.iii` already opens with the label ("this is the didactic verified model; III's LIVE verification membrane is the ser_* family") — verified live. Sweep the other 32: `for f in ssa gvn dce sccp ...; do grep -L "MODEL-TIER" STDLIB/iii/numera/$f.iii; done` — every file the grep names gains the same two-line label (adapted: "III's REAL optimizer is XII + cg_r3"). Exemptions by evidence, not mercy: interval_lattice (k32) + taint_analysis (k25) + affine_check (the `--affine-audit` organ) + heaplet (k18) have REAL consumers — their label instead reads "model-tier origin, live consumers: <names>". Gate: corpus green (comment-only), execution record lists every file labeled.

### W4a.10 — Autonomy / self-optimization (13) — KEEP all; merge product verified

`algo_synth 141 · isa_macro_synth 48 · ast_hunter 72 · conjecture_refute 138 · verified_search 175 · verified_ripple 129 · optimality_cert 142 · contract_gate 124 · rev_invoke 92 · reversible 753 · sov_isa 2624 (the descent optimizer) · sov_pipeline 110 (labeled: the all-faculties-one-path prover) · self_engine 328` — self_engine absorbed omega_engine (verified W0.1.2): one autonomous conjecture→prove→verify capstone per layer, capstone-sprawl closed.

### W4a.11 — Constitutional / harmony organs (34) — KEEP all + 2 hole repairs

`constitution 1174 · constitution_preserver 388 · h1_charter 191 · h2_charter 215 · h3_charter 178 · h4_charter 209 · h5_charter 211 · h6_charter 159 · h7_charter 269 · h8_charter 213 · h9_charter 264 · h10_charter 301 · h11_charter 265 · h12_charter 223 · h13_charter 265 · h9_mig2_tie 109 · charter_terminal 282 (folds all 13) · math_library 664 · math_library_curation 468 · founders_anchor 460 · constants 683 · reflection_constrained 583 · reflection_governance 493 · witness_spine 538 · branch_anchor 666 · computation_graph 758 · memo_lattice 693 · identifier 153 (k135) · cad 393 (KEEP-CORE, c62 k147) · category 1034 · sheaf 662 · bft_quorum 96.`
- [ ] **W4a.11.1 `temporal_logic` 694 (census-hole repair) — KEEP, fresh verdict:** LTL (12 tags, finite-trace, NON-RECURSIVE W15 fixpoint table) + bounded MC **over the witness chain** — the LIVE temporal layer on real III history, complementary to model-tier bmc. Gated (644_temporal_logic + 1510_temporal_logic_trace_oob). Action: add the cross-label pair — temporal_logic's header names bmc as the didactic sibling; bmc's label (already present) is verified to name the ser_*/temporal_logic live tier. Gate: corpus green.
- [ ] **W4a.11.2 `certified_morphism` 103 (census-hole repair) — KEEP, fresh verdict:** proof-gated morphism admission — fuses category.iii (admits any arrow) with theorem_commons/CIC so an arrow enters ONLY with a kernel-checked proof. A genuine cross-module weld, gated (1240_certified_morphism). Action: verify category.iii's header cross-references it as the proof-gated admission path (`grep -n "certified_morphism" STDLIB/iii/numera/category.iii`); if absent, add the one-line pointer so the unproven path is never mistaken for the only path. Gate: corpus green.

### W4a.12 — Phase III/IV micro-organs + HDL (23) — KEEP all; gate: corpus

`cegar_refine 101 · evidence_calculus 92 · quantize_sensor 52 · sample_beacon 93 · distribution 91 · infer_exact 46 · markov_exact 48 · mc_certified 64 · belief_sheaf 97 · bayes_exact 42 · measure_status 36 · dp_exact 50 · infotheory 55 · approx_struct 53 · rand_algo 76 · pctl 29 · causal_scm 43 · aeu 112 · aeu_kernel 105 · hdl 379 · hdl_gate_db 287 · hdl_optimize 248 · hdl_compiler 177.`
No content actions.

### W4a.13 — Seraphyte organ cluster (30) — KEEP all; pair adjudicated NOT-sprawl

`ser_kvalue 134 · ser_energy 108 · ser_real 78 · ser_membrane 106 · ser_commit 66 · ser_discover 93 · ser_optimize 90 · ser_immune 101 · ser_diff 95 · ser_memo 102 · ser_isub 155 · ser_autopoiesis 110 · ser_petri 201 · ser_cegis 89 · ser_antiunify 1236 · ser_absint 194 · ser_cascade 75 · ser_cascade2 118 · ser_regalloc 75 · ser_egraph 559 · ser_intent 154 · ser_tgraph 196 · ser_kinduct 252 · ser_causal 549 · ser_tdriver 69 · ser_kinduct_sym 692 · ser_eidos 92 · ser_pipeline 329 · ser_fsm 87 · ser_protocol 85.`
Fresh adjudication recorded: `ser_cascade`/`ser_cascade2` is LAYERED, not sprawl — cascade = one-proof→many-site registry collapse; cascade2 = rewrite-to-saturation with gated termination+confluence theorems (corpus 2023), explicitly built on cascade, both consumed by ser_pipeline. KEEP both; headers already state the relationship. The stale "volatile WIP" note about ser_antiunify/ser_petri dies in W2.1.

### W4a.14 — XII support (4) + the corrigendum

`xii_ldil 1108 · xii_nop_tables 140 · xii_subforms 346` — KEEP all, no action.
- [ ] **W4a.14.1 `combinator` 502 (census-hole repair) — KEEP-CORE, fresh verdict:** Path C brick 1 — bracket abstraction (λ→SKI) + purely first-order SKI reduction, NO substitution anywhere, so XII's first-order engine is universally sufficient (H4 One Engine). Gated (853_combinator_ski + 854_combinator_data). Load-bearing for the standing Path-C program (F6 campaign names Path-C as a remaining leg). No content action.
- [ ] **W4a.14.6 — Ledger corrigendum:** append one line to `DOCS/III-PERFECTION-LEDGER.md` §17: "CORRIGENDUM (reunification plan, 2026-07-01): the name-presence gate also matched APPENDIX-A extern-subjects; five numera modules (certified_morphism, combinator, cpufeat, synthesis_spec, temporal_logic) were never verdicted in §8b — fresh-verdicted KEEP in III-REUNIFICATION-PLAN W4a; strict-form gate adopted there (W8)."

### W4a.16 — HARVESTED (W1.1.3): the numera call-graph audit — untested exports the token ratchet cannot see

Preserved verbatim from `_numera_audit_findings.txt` (root scratch, deleted after this harvest; methodology: gap = not named in any corpus KAT AND not called by the module's selftest AND not called by any tested module):
- `q128`: q128_mul · q128_sub · q128_cmp · q128_shr · q128_or · q128_and (only add_shift + to_f64 tested)
- `field`: fp_div (49 tests cover add/sub/mul/pow/inv, never div)
- `modular`: mod_u32_add · mod_u32_sub · mod_u64_sub · mod_u64_pow (mod_u64_add excluded — transitively tested)
- `checked`: checked_u64_unwrap_or · checked_u64_drop (KAT mints a handle, never reads/drops it)
- `fixed`: fix_to_u32_round · fix_frac · fix_eq · fix_lt
- `proof_term`: pt_to_program (only in comments + a sink var)
- `memo_lattice`: ml_slot_count · ml_slot_is_live · ml_slot_chain_eq · ml_slot_key
- `synthesis_spec`: ss_propose · ss_ratify (witness-publish pair, not in ss_selftest)
- `proof_carrying`: pc_coeff_leaf · pc_cert_chain_root
- `cad`: cad_branch_key · `identifier`: ident_encode_seq · `egraph`: eg_class_count (zero refs anywhere)
- `ntt`: ntt_set · ntt_get · ntt_set_b (public staging API; selftest stages via NTT_W directly)

- [ ] **W4a.16.1** For each family above: extend the module's EXISTING selftest/KAT with arms driving the named exports (known-answer where arithmetic: q128_mul on a pinned product, fp_div on a pinned quotient + div-by-inverse identity, mod_u64_pow vs square-and-multiply reference, fix_* on pinned fixtures, ntt staging roundtrip set→get; structural where stateful: checked unwrap_or/drop lifecycle, ml_slot_* on a built lattice, eg_class_count after known merges, cad_branch_key determinism, ident_encode_seq roundtrip, ss_propose/ratify on a fixture spec, pc_coeff_leaf vs pc_poly_leaf agreement, pt_to_program on a 2-step term). Gate: corpus green; the execution record lists each export → its new arm.

### W4a.15 — W4a exit

- [ ] Full spine (L1) green + `run_nous_corpus.sh`/`run_autogenesis_corpus.sh` green (numera-adjacent families) + seal cascade if any sealed source was touched (L3) + append W4a EXECUTION RECORD (must list: merge W4a.7.1 commit, label-sweep file list, falsifier KAT numbers, corrigendum line).

---

# WAVE 4b-i — STDLIB/iii/aether: 132 files, every one

**Evidence base:** live `wc -l` 2026-07-01/02 (132 files, 36,403 loc). **LIVE-GROWTH EVENT recorded at authoring:** `sturm_big.iii` (418, commit `ade94379`, KAT 2185) landed between this plan's first inventory and this section; `arc_sweep.iii` shrank ~230→80 in the same era (commit `b6fa1837` — the sweep now composes the landed engines). Count closure: 141 (ledger) − 11 scaffolds − 2 merge-deletes + resultant + refract + sturm_big = 132 ✓. The Turing charter (`b603493f`) pre-adjudicates increments 2185–2193: L11 governs the arrivals.

### W4b-i.1 — Core IO / capability substrate (8) — KEEP-CORE all; gate: corpus

`capability 292 · fs 386 · net 189 · handle 136 · tcp 139 · inet 131 · inet6 260 · witness_hook 489 (the provenance chokepoint).` No content actions.

### W4b-i.2 — The Reach (7) — KEEP all; gate: corpus

`backend_memo 114 · reach_store 179 · backend_ipc 182 · backend_loopback 166 · backend_remote 223 · reach_core 214 · reach_oracle 100.` Uniform, layered, integrity at reach_core only — the family the rest of the tree should match. No actions.

### W4b-i.3 — Develop-up sealed-box layer (12) — KEEP all; one absorb verified

`vbd 77 · flow_firewall 64 · sentinel 111 · enclave 101 · replay_box 79 · snapshot_box 109 · sid_router 86 · attest_box 99 · determinism_firewall 102 · sealed_box 71 · develop_up 201 · compute_box 101` — compute_box absorbed the 35-line sort-meter tier (W0.1.2-verified; its KAT 1741 retargeted). No further actions.

### W4b-i.4 — Federation / consensus (10) — KEEP all; one absorb verified

`fed_tier 113 · fed_sybil 340 · fed_eclipse 321 · fed_admit 193 · fed_genesis 309 · fed_seal 268 · hotstuff 872 · pq_quorum 101 · node_identity 418 · hotstuff_unified 217` — absorbed predict (W0.1.2-verified; KAT 384 retargeted). Three-modules-for-one-protocol closed at two: core + unified pacemaker.

### W4b-i.5 — Sovereign wire + legacy interop (9) — KEEP all

`babel_wire 302 · cap_handshake 312 · sealed_channel 282 · idoc 233 · pattern_set_federation 287 · http_client 741 · http_server 721 · http 163 · cap_zkp 89.` KEEP-LABEL standing: the sovereign path is babel_wire; http* is the labeled legacy-interop surface. Verify the label line exists in http.iii's header; add if absent (one line).

### W4b-i.6 — Constitutional enforcement organs (19) — KEEP all; one verify-trim

`quarantine 640 · firmware_quarantine 355 · reversibility_audit 554 · snapshot_lattice 383 · triple_check 368 · distress_witness 396 · witness_compactor 337 · memo_compactor_coordination 267 · cost_overrun_handler 551 · branch_governance 420 · bisimulation_witness 308 · context_awareness 631 · memo_query 587 · manifest 394 · bone_marrow 825 · basal_probe 607 · shape_negotiator 442 · cap_forge 701` — consumption-by-design (anomaly-time chokepoints); basal_probe + shape_negotiator exports covered-or-trimmed by W0.2 (verify on the W0 record).
- [ ] **W4b-i.6.1 `topology_atlas` 654 — VERIFY-TRIM (decision procedure, both outcomes specified):** live evidence shows it now CONSUMES `numera::dijkstra` via extern (lines 37–41, "CONSUMED verified routing" header). Check for a remaining superseded internal routing path: `grep -n "fn ta_.*route\|fn ta_dij\|relax\|frontier" STDLIB/iii/aether/topology_atlas.iii`. If none: record TRIM-DONE (the ledger's REFACTOR was executed by the consumption rewrite) — KEEP. If an internal implementation remains: delete it, route all internal callers through the extern, gate: corpus + its c9 KATs green.

### W4b-i.7 — Probability / perception (3) — KEEP all

`percept_infer 40 · perception_membrane 72 · provisional_universe 72.` No actions.

### W4b-i.8 — Exact-geometry organ family (26) — KEEP all + 4 fresh rows

`sqrt_sum_sign 926 (KEEP-CORE, THE ladder) · q23_sign 29 · kfield 556 (tier-gated; i64 small-env unsoundness labeled) · verb_geom 128 · exact_denest 83 · exact_surd_value 111 · algnum 219 · sturm 278 (grew +36: root_mult certificates, gated 2181) · delaunay 84 · csg_kernel 116 · csg_tree 121 · cyclotomic_se3 174 · collide 106 · photon_route 108 · traj_kinematics 191 · lattice_march 312 (grew +133: lm2_* rational-direction march v2, gated 2182) · constraint 71 · billiard 259 · gas 343 · gas_big 537 (grew +214: g2_compact ensemble compaction, gated 2183; denominator self-limiting + own-arena sign calls) · cspace 248 (committed + gated — the ledger FIX closed) · wb_kernel 39.`
- [ ] **W4b-i.8.1 `resultant` 622 (post-ledger arrival) — fresh verdict KEEP-CORE:** resultant elimination — γ=α+β's defining polynomial as Res_x(f(x), g(t−x)) evaluated at m·n+1 integer points, determinant via the modular-CRT engine; roots closed under + (and ·, ⁻¹, rational scaling via rs_prod/rs_inv/rs_primitive, commit 8bf7c3aa). Gated: 2177/2179/2180 in run_sqrtsum_kats (registration verified live: 8 matches). Feeds sturm/algnum — the closure the capstone face needed. No content action.
- [ ] **W4b-i.8.2 `refract` 265 (post-ledger arrival) — fresh verdict KEEP:** bounded-rank refraction — Snell² as integer identity over a construction-closed direction set (no new radicals ever); multi-interface optics rf_stack/rf_chan (2184). Gated 2178/2184. No content action.
- [ ] **W4b-i.8.3 `sturm_big` 418 (LIVE arrival, `ade94379`) — fresh verdict KEEP:** bigint PRS — Sturm past the i64 chain wall (Turing charter V-I.1), gated 2185. L11 template completed at authoring: runner registration verified; census cross-ref: complements (not supersedes) sturm — i64 fast path stays, bigint escape tier new. Verify sturm.iii's header cross-references the escape tier (one line if absent).
- [ ] **W4b-i.8.4 `arc_sweep` 80 (shrank ~230→80, `b6fa1837`) — re-verdict KEEP after verify:** the rotational no-collision certificate now composes the landed engines instead of carrying its own machinery. Verify: KAT 2175 green in the family run + `grep -c "extern" STDLIB/iii/aether/arc_sweep.iii` shows it consuming sturm/resultant exports (composition, not amputation). Record the composition edge in the execution record.

### W4b-i.9 — AETHER-LENS render family (6) — KEEP all

`aether_lens 440 (KEEP-CORE) · aether_lens_frame 332 · aether_lens_view 92 · aether_lens_win 94 · aether_world 1002 (workbench app) · world_graph 1760.`
- [ ] **W4b-i.9.1 `world_graph` — GENERATED discipline:** regenerate via its producing path AFTER W4a.7.1 (cost_lattice_synth merge) so the extern-edge graph reflects the post-merge tree; verify header carries GENERATED + the producer's name; hand-edits forbidden. Gate: aether_world compile + its KATs.
- Window-pump exports app-surfaced/covered by W0.2.3 (verify on record).

### W4b-i.10 — GLASS UI engine + fonts (14) — KEEP all + THE SPLIT

`ui_raster 128 (KEEP-CORE) · ui_exact_big 70 · ui_exact_sym 147 · ui_exact_bigcov 293 · ui_field 442 (KEEP-CORE) · ui_win 138 (KEEP-CORE; input ring covered/app-surfaced per W0.2.4) · ui_font 85 · ui_font_data 8 · ui_vfont 55 · ui_vfont_data 10 · ui_present 56 · ui_egraph 280 · ui_egraph_app 8 (labeled shim).`
- [ ] **W4b-i.10.1 `ui_exact` 1331 — REFACTOR (SPLIT), evidence-based boundary:** the cubic CROSSING tier (degree-3 algebraic crossings, discriminant machinery — lines ~1200 to EOF, per live read "EXACT CUBIC BEZIER…") moves to `ui_exact_cubic.iii`. The cubic AREA function (`ui_cubic_area_s`, line ~426) STAYS: it participates in the lcm-60 one-unit summation identity with line/quad areas — splitting it would break the invariant that segments of any type sum in one unit. Externs/callers updated (studio, gates 2080–2102 KATs unaffected by name — exports keep names); MODULES gains the new line adjacent to ui_exact. Gate: run_ui_kats + run_bigcov_kats + corpus + build green; L2 one commit. (W0.2.2 already de-exported the `*_dbg` surface; this completes the family-size restoration.)

### W4b-i.11 — Unique ungated capabilities (3) — FIX all three (they carry value nothing else has)

- [ ] **`ui_morphic` 116 — FIX:** gate the SVIR write-back (a KAT that opens a fixture SVIR source, drives one direct-manipulation constant edit headlessly, asserts the byte-diff is exactly the constant) + wire as a studio workspace entry (`ws_` shim consuming the existing studio loop — edit-first: extend ws_forge's file-open path rather than minting a new workspace if the fit is natural; decide by reading ws_forge at execution, both options specified). KAT number from W5 ceremony.
- [ ] **`ui_destiny` 143 — FIX:** gate the time-scrub (KAT: build a 3-step field history, scrub to step 1, assert field state equals the recorded step exactly) + studio wiring per the same edit-first rule.
- [ ] **`ui_topo` 161 — KEEP:** gates 2088–2093 exist; its runner's stale dependency note dies in W2.1. Verify the topo family runs green post-W2.

### W4b-i.12 — Field/fractal falsifier demos (5) — THE §2m MERGE, executed

- [ ] **MERGE `field_dim` 58 + `field_full` 219 → `field_run` 156** (argv-selected modes: `dim`, `full`, default run); DELETE both sources after L5 grep (`grep -rln "field_dim\|field_full" STDLIB COMPILER --include="*.sh" --include="*.iii"`). KEEP `fractal_dim 142` + `mandel_run 190` (the two falsifiers — Shishikura dim-2 among them). Register all three survivors as compile+run-headless smoke entries appended to `run_field_kats.sh` (the EXISTING field-family gate — no new runner). Gate: run_field_kats green including the three new entries; L2 one commit.

### W4b-i.13 — III-STUDIO family (10) — KEEP all (S2 closed; committed + gated 2169)

`iii_studio 206 · studio_theme 110 · studio_trig 47 · studio_sample 15 (the renamed live-compile fixture) · ws_home 162 · ws_console 279 · ws_forge 316 · ws_lens 94 · ws_zoom 162 · ws_bench 345.` No actions beyond W4b-i.11's workspace wiring landing here.

### W4b-i.14 — W4b-i exit

- [ ] run_sqrtsum (46/0-era count +2185) + run_aether_lens + run_ui + run_bigcov + run_field + run_topo + full spine green; seal cascade for touched sealed sources; append EXECUTION RECORD (split commit, demo-merge commit, morphic/destiny KAT numbers, trim verdict, arrival rows).

---

# WAVE 4b-ii — STDLIB/iii/omnia: 155 files, every one

**Evidence base:** live `wc -l` (155 files, 32,977 loc; 157 − 3 verify-missiles + xii_semantic_verify = 155 ✓); xii_semantic_verify read (3 strikes + honest-scope header — a model merge); self_atlas_data provenance defect confirmed live (header names the DELETED gen_self_atlas.py).

### W4b-ii.1 — Containers & primitives (22) — KEEP-CORE all

`vec 484 · map 490 · set 65 · queue 313 · pq 264 · list 201 · lru 366 · iter 185 · fold 108 · zip 61 · option 89 · result 151 · either 53 · crystal 360 · crystal_deps 312 · crystal_edges 125 · async 352 · bound 65 · caindex 99 · bench 70 · arena_slot_witness 80 · spec_probe 22 (labeled canary).` No actions.

### W4b-ii.2 — XII engine core (14) + curated payloads (4) — KEEP-CORE all

`xii_term 464 (c387, highest fan-in in III) · xii_rewrite 1288 (the 40 sealed rules) · xii_canonicalise 218 · xii_basis 238 · xii_horizon 829 · xii_horizon_reach 60 · xii_hj 171 · xii_savings 198 · xii_circ 283 · xii_chd 316 · xii_lattice 224 · xii_emit_gen 443 · xii_kernel_emit 375 · xii_isub 81` + `xii_curated_payloads 69 · xii_curated_embedded 50 · xii_curated_riscv 48 · xii_curated_extended 195` (data, antidrift-gated). No actions; gate: run_xii_corpus + run_xii_antidrift.

### W4b-ii.3 — mig4 lowering + confluence certificate (22) — KEEP all; merge product verified

`xii_rule_patterns 302 · xii_rule_overlap 167 · xii_critpair_enum 137 · xii_joinability 361 · xii_termination 305 · xii_admission 117 · xii_lower_compose 162 · xii_lower_decide 116 · xii_lower_iterate 125 · xii_lower_program 148 · xii_lower_then 121 · xii_lower_with 105 · xii_lower_under 106 · xii_mig4_seal 212 · xii_strategy_det 97 · xii_discharge 190 · xii_conf_cert 247 · xii_cap_preserve 59 · xii_cost_monotone 63 · xii_denote 129 · xii_morphism 101.`
- `xii_semantic_verify 319` — the 3-missile unification, live-verified: STRIKE 1 (rule-by-rule vs independent authority, apply_one names the specific rule), STRIKE 2 (identity-null fusion family vs monoid authority), STRIKE 3 (priority null-collapse by evidence); honest-scope note for the structural families. KEEP. Its 3 KATs (884/885/1331) retargeted (W0.1-verified).
- [ ] **W4b-ii.3.1 `resolution_init` 199 — SIBLING-OWNED adjudication:** the working tree carries an uncommitted edit with NO committed diff since the ledger. At execution: `git diff -- STDLIB/iii/omnia/resolution_init.iii` — if it registers xii_semantic_verify (or other merge boot-wiring), it belongs to the merge era: verify + commit with this wave; if unrelated sibling work: L6 skip + record.

### W4b-ii.4 — The proof pair (2) — the W0.2.1 split, verified here

`xii_proof 236 → gadget API (admitted to MODULES) + xii_proof_tamper (new, test hooks) · xii_proof_check 180.` W4b-ii verifies the split landed with: positive KAT green, tamper KATs green, dark-list clean of xii_proof_*, MODULES line present. (Row here so the omnia census stays 1:1; the labor is W0.2.1's.)

### W4b-ii.5 — Inverse substrate / master-logic (15) — KEEP all

`isub 167 · involution 89 · unravel 127 · assimilate 165 · ingest 64 · enmesh 178 · canon_enmesh 134 · law_web 123 · master_logic 115 · reverse_search 176 · exec_cert 59 · event_substrate 226 · parity_game 164 · ripple 426 · ripple_field 179.`
- [ ] **W4b-ii.5.1 — leaf-collision caveat made durable:** three subsystems own a `ripple.iii` (omnia/forcefield/eidos) and two own `resolver_replay.iii`; .o namespacing handles linkage but per-leaf metrics stay ambiguous. Action: one header line in each of the five files naming its siblings ("leaf-name shared with X/Y — do not add a fourth/third"). Comment-only; gate: corpus green.

### W4b-ii.6 — Resolution calculus (26) — KEEP all

`resolver 1174 · resolver_memo 244 · resolver_replay 52 · proof_resolve 135 · resolution_init 199 (row W4b-ii.3.1) · resolution_meta_dispatch 30 (labeled BSS-split shim) · call_context 319 · pattern_table 254 · unify 367 · governance 566 · self_reformatter 387 · ai_resolve 127 · babel 127 · babel_intent 185 (verify DORMANT label present — one line if absent) · mini_crystal 196 · jit_fuse 252 · jit_swap 118 · hw_offload 244 · layered_seal 139 · dynamic_record 106 · dynamic_impact 142 · prespec 2027 (GENERATED; verify gen_compositions.sh drift gate green) · sovval 304 · sov_morphism 302 · proof_bisimulation 61 · proof_ripple_resolution 287.`

### W4b-ii.7 — Transform category (30) — KEEP the organ + THE COVERAGE FIX

`transform 173 · transform_patterns 204 · codegen_dispatch 118 · codegen_patterns 119 · tp_planner 373 · tp_morphism 182` + the 24 codecs `tp_raw_hex 111 · tp_iii_hex 16 · tp_pe_hex 16 · tp_iii_to_md 51 · tp_iii_to_latex 51 · tp_iii_to_c99 98 · tp_x86_disasm 74 · tp_x86_assemble 68 · tp_iii_to_asm 120 · tp_asm_to_pe 83 · tp_iii_to_babel_json 104 · tp_babel_json_to_iii 111 · tp_iii_to_ast_bin 49 · tp_ast_bin_to_iii 49 · tp_babel_text 65 · tp_babel_text_back 57 · tp_babel_json_cbor 83 · tp_babel_cbor_json 81 · tp_ripple_dot 89 · tp_ripple_md 147 · tp_ast_dot 89 · tp_c99hdr_to_iii 129 · tp_ast_to_babel_json 87 · tp_babel_json_to_ast 20.`
- [ ] **W4b-ii.7.1 — the route-sweep KAT (closes 16 c0 registrations at once):** ONE corpus KAT that (1) queries codegen_dispatch for every registered arrow, (2) drives each through tp_planner on a canonical fixture (a 20-line .iii module embedded in the KAT), (3) compares each output against a golden (hash-pinned in the KAT — byte goldens for text codecs, structural assertions for binary), (4) FAILS if the registered-arrow count differs from the manifest count (a new codec cannot arrive unproven). Prove the positive arm: corrupt one golden locally at authoring → KAT must FAIL → restore. Number from W5; registered in EXPECTED. Gate: the KAT + corpus green.

### W4b-ii.8 — Hexad (7) + observability/sandbox (7) — KEEP all

`hexad 67 · hexad_algebra 167 · hexad_pfs 68 · hexad_reach 160 · hexad_epistemic 60 · hexad_mobius 115 · hexad_dynamic 101 · obs_log 144 · obs_metric 130 · obs_trace 171 · obs_observatory 109 · sandbox_ctor 180 · sandbox_exec 135 · sandbox_quota 121.` No actions.

### W4b-ii.9 — Self-model (6) — THE PROVENANCE FIX

`self_atlas 560 · self_atlas_lens 271 · self_cartographer 238 · self_emit 263 · self_report 126.`
- [ ] **W4b-ii.9.1 `self_atlas_data` 2068 — FIX (broken provenance, upgraded from the ledger's source-swap):** the header names `STDLIB/scripts/gen_self_atlas.py` as its generator — that file was DELETED in the purge; the tree holds generated data pointing at a ghost. Execute: regenerate via the native path (`self_cartographer` → `self_emit`) AFTER W4a.7.1 lands (so the data reflects the post-merge tree); replace the header's provenance line with the native generator invocation; add the drift check to the subsystem gate (regenerated-vs-committed compare — the same discipline as the .def drift gates). Gate: regen diff empty post-commit + self_atlas KATs (c60) green.

### W4b-ii.10 — W4b-ii exit

- [ ] run_xii_corpus + run_xii_antidrift + full spine green; append EXECUTION RECORD (route-sweep KAT number + golden-corruption falsification note, provenance-fix commit, leaf-caveat file list, resolution_init adjudication).

---

# WAVE 4c — verba 46 · nous 28 · sanctus 29 · forcefield 25 · eidos 25 (153 files, every one)

**Evidence base:** live listings 2026-07-02; three decisive live checks run at authoring: ripple_dyn consumer grep (pleroma = REAL consumer → attrition NOT fired), orchestrate caller grep (cli/sealed_channel/xii_register_all hits → island flag may already be closed; precision check specified), costlin-in-compose grep (ZERO hits → ADR-6 unwired, decision fires here).

### W4c.1 — verba (46) — KEEP all + one FIX

**KEEP-CORE:** `builder 201 · intent 536 · glyph_core 175 · pattern 223 · rune 268 · string 176 · parse 167 · format 181.`
**KEEP (codec/parse shelf, 19):** `json 1237 (the one JSON) · uri 504 · csv 248 · ini 327 · semver 325 · leb128 174 · base32 184 · base64 240 · path 234 · html_escape 185 · normalise 524 · normalise_ascii 136 · regex 432 (Brzozowski, no backtracking) · glob 168 · markup 400 · timing_safe 29 (tiny by design: constant-time compare) · ulid 149 · uuid 84 · ast_intent 164.`
**KEEP (Glyph V3, 16 — the H3 one-serialization):** `glyph_u8 56 · glyph_u32 55 · glyph_u64 56 · glyph_i64 57 · glyph_f64 59 · glyph_bytes 88 · glyph_str 122 · glyph_crystal 111 · glyph_vec 140 · glyph_map 161 · glyph_set 176 · glyph_enum 135 · glyph_record 124 · glyph_witness 136 · glyph_proof 124 · glyph_recursive 134.`
**KEEP (HIP NL surface):** `hip 660 · nl_lex 1020.`
- [ ] **W4c.1.1 `nl_parse` 1011 — FIX (thinnest gate in verba):** add role-tagger falsifier KATs: (a) fixture sentences with hand-verified thematic-role vectors — assert EXACT vector match (a mis-tag fails); (b) a structurally ambiguous fixture must return its AMBIGUOUS marker, never a silent single guess; (c) a non-parse (word salad) must reject. Numbers from W5; EXPECTED-registered. Gate: 3 new + 4 existing green.

### W4c.2 — nous (28) — KEEP all + THE ADR-6 DECISION

**Proposer chain (13):** `nous_socket 224 · nous_policy 189 · nous_features 112 · nous_lattice 100 · nous_value 84 · nous_train 133 (ADR-N8 trainer-out-of-tree) · nous_synth 161 · nous_search 331 · nous_commons 230 · nous_charter 232 · nous_completion 502 (Knuth-Bendix) · nous_behavioral_key 167 · nous_costlin 144.`
**Conjecture tier (4):** `nous_conjecture 176 · nous_conjecture_term 251 · nous_conjecture_gen 79 · nous_conjecture_lemma 130.`
**Campaign/autogenesis (11):** `beam_search 125 · lemma_forge 169 · search_market 128 · pac_certify 37 · perceptual_proposer 83 · bayes_search 81 · gap_conjecture 233 · harmony_synth 228 · refactor_propose 181 · optimize_self 135 · theorem_grow 199.`
- [ ] **W4c.2.1 — ADR-6 (costlin ⇄ eidos/compose) — WIRE OR STRIKE, decided by one read:** live grep confirms compose.iii consults costlin NOWHERE. At execution, read `eidos/compose.iii`'s candidate-ordering site. **Branch WIRE (default):** add the extern to nous_costlin's linear-cost evaluation and swap the Composer's comparator to consult it (one extern block + one comparator change), so the ADR's "canonical total order for the Composer" is REAL; add a KAT: on a fixture faculty set, compose's chosen order == costlin's order (and a deliberately inverted-cost fixture flips the choice — the positive arm proven). **Branch STRIKE (only if the read shows compose already carries a total order with its own gated theorem making costlin's order redundant):** strike the ADR-6 line in its DOC with the recorded reason + costlin keeps its proposer-chain role. Either branch closes the ledger's standing FIX. Gate: corpus + run_nous_corpus green.

### W4c.3 — sanctus (29) — KEEP all; two absorbs verified

`mhash 81 (KEEP-CORE, the Crown hash) · witness 284 · kchain 146 · closure 114 · attest 113 · calculus_v1 308 · irreducibility_proof 345 · catalyst 175 · genesis 101 · promote 145 · demote 122 · observe 143 · onelang 534 · seal_resolver 206 · resolver_replay 47 (leaf-caveat row W4b-ii.5.1 covers its sibling) · legacy_artifact 142 · sovereign_witness 322 · corpus_coverage 1423 (KEEP-CORE: computes the S1 ratchets; size justified) · self_model 229 · autogenesis 226 · autogenesis_cli 218 · anchor_xii 146 · xii_antidrift 274 · xii_atm 118 · xii_curate 170 · xii_register_all 58 · xii_sml 144.`
- `mandate 143` — absorbed M22 (W0.1.2-verified; KATs 45 + 1421–1423 retargeted). `quality 397` — absorbed Q7, one Q1..Q7 organ (W0.1.2-verified; KATs 100/941 retargeted). No further actions.

### W4c.4 — forcefield (25) — KEEP all; capstone-sprawl closed; attrition flag resolved honestly

**KEEP-CORE:** `cg_autocatalyst 510 · cg_opt_rules 608 · ripple 281 · ripple_metric 257 · commit_gate 151.`
**KEEP:** `bv_dispose 239 · daemon_dream 211 · forked_walk 125 · invent_loop 241 · optinvoke 251 · pleroma 496 · pcc_gate 40 (small but THE PCC admission) · integrity 66 · ripple_apply 472 · ripple_journal 151 · ripple_loop 104 · ripple_cut 41 · ripple_unify 85 · ripple_extract 230 · ripple_search 54 · proof_ripple_unified 208 (the decider) · cg_surgical_strike 73.`
- `sovereign_optimizer 494` — absorbed ripple_synthesizer (W0.1.2-verified; KAT 1091 retargeted): ONE production facade over the self-optimization calculus, capstone-sprawl closed. `scythe_census 148` — absorbed daemon_scythe (KAT 1203 retargeted).
- [ ] **W4c.4.1 `ripple_dyn` 259 — KEEP, attrition flag RESOLVED NOT-FIRED (live evidence):** the retire-by-attrition trigger required zero-consumer proof; live grep finds `pleroma.iii` (the coherence gate, wired into the build) consuming it — a REAL organ consumer, so ripple_dyn stays. Action: record the consumer edge in ripple_dyn's header ("live consumer: forcefield/pleroma (coherence gate)") so the next audit doesn't re-litigate; the flag in the ledger is closed by this row. Comment-only; corpus green.

### W4c.5 — eidos (25) — KEEP all + THE ISLAND FLAG CLOSED WITH PRECISION

**LIB planner/display cohort (18):** `anchor 83 · canvas 230 · cli 148 · coincidence 236 · compose 244 · descriptor 145 · field 66 (the ONE unified reader) · layout 548 · memo 101 · optgate 134 · palette 67 · render 261 · ripple 127 (c79, top fan-in; leaf-caveat W4b-ii.5.1) · route 119 · temporal 185 · weave 146 · web 613 · orchestrate 118.`
**Standalone ripple-merge cohort (7):** `eidolon 194 · membrane 101 · disposer 72 · eid_plan 72 · epoch 86 · reactor 92 · ripple_eidolon 56.`
- [ ] **W4c.5.1 `orchestrate` — island flag: verify-close or wire (precision check):** the ledger recorded "nothing but a test calls orchestrate"; live word-grep now hits `eidos/cli.iii`, `aether/sealed_channel.iii`, `sanctus/xii_register_all.iii`. At execution run the PRECISE check: `grep -n "from \"orchestrate.iii\"" STDLIB/iii/eidos/cli.iii STDLIB/iii/aether/sealed_channel.iii STDLIB/iii/sanctus/xii_register_all.iii`. **If ≥1 real extern:** the island closed since the census — record the consumer chain (e.g. cli→orchestrate), update orchestrate's header to name it, close the ledger FIX. **If all hits are prose:** execute the declared wiring — eidos/cli's compose command routes through `orchestrate`'s host-adaptive composition (cli is already gated c3, so the consumer is LIVE by construction), one extern + call-site swap, KAT asserting the cli path exercises orchestrate's decision (fixture with two candidate compositions; assert the host-adapted choice). Gate: corpus + run_ripple_kats green.

### W4c.6 — W4c exit

- [ ] run_ripple_kats + run_nous_corpus + run_topo_kats (post-W2 note fix) + full spine green; append EXECUTION RECORD (ADR-6 branch taken, orchestrate branch taken, ripple_dyn header edit, nl_parse KAT numbers).

---

# WAVE 4d — katabasis 22 · intent 5 · memoria 5 · tempora 6 · sovir 77 · sovtc 54 · independence 12 (181 files, every one)

**Evidence base:** live counts verified 2026-07-02 (22/5/5/6/77/54/12 — all match ledger); forge63 copy-paste header CONFIRMED live (file opens with "zk_fused_committed.iii — P2b SCALE-UP").

### W4d.1 — katabasis (22) — KEEP all

`admit 36 · bar_layout 85 (.def-gen) · behavioral_fp 53 · behavioral_seed 69 · bricking 68 · caps 55 · census 87 (.def-gen) · cpu_census 69 · crystal_cap 66 · cycle_admit 63 · cycle_family 112 (.def-gen) · cycle_term 119 · descent_proof 49 · gate 50 · gate_verdict 81 · pci_enum 103 · quine_seal 217 (M23; label verified: Ring-0 arm never auto-run, user-mode arm gated) · ring_lattice 65 (.def-gen) · seal 63 · stage 44 · svm_layout 104 (.def-gen) · vmexit 90 (.def-gen).` The six .def-generated modules are single-sourced with build-failing drift gates — the correct pattern, no action. Gate: corpus + def-drift gates.

### W4d.2 — intent (5) — KEEP all

`lex_ontology 118 · intent_lex 61 · disambiguate 72 · synthesis_bridge 82 · intent_attest 42.` One pipeline gated at the mouth; transitive reachability green. No actions.

### W4d.3 — memoria (5) — KEEP all (the uniformity benchmark)

`arena 157 (c306, the universal consumer) · region 192 (the ONE VirtualAlloc surface) · span 148 · tempaloc 167 · seal_organ 233.` No actions. This subsystem is the bar the rest of the tree is being held to.

### W4d.4 — tempora (6) — KEEP all

`calendar 159 · instant 209 (deterministic logical counter — no OS clock) · duration 156 · deadline 128 · rfc3339 135 · duration_cert 98 (KEEP-LABEL: deliberately split so duration stays typecheck-isolated — NOT a merge candidate; verify the header states this, one line if absent).`

### W4d.5 — sovir (77) — KEEP all + ONE FIX; c0/k0 is by design (runner-compiled farm)

**Toolchain organs:** `ccsv 2075 (the completion-plan keystone) · iiisv 402 + iiisv2 279 (DDC diversity pair) · svir_verify 82 · svir_interp 184 · svir_x86 233 · svir_wasm 235 · svir_dis 78 · verify_each 51 · verify_main 11 · vdbg 66 · vdbgall 67.`
**Gate fixtures/controls:** `svir_prog 25 · svir_loop 26 · svir_fact 18 · svir_call 36 · svir_bignum 9 · svir_memtest 9 · svir_bad_br 4 · svir_bad_call 4 · svir_bad_end 4 · svir_bad_op 4 · _ve_goodmod 8 · _ve_badmod 10.`
**zkVM opcode bricks (18):** `zk_svir_add 87 · zk_svir_sub 87 · zk_svir_mul 71 · zk_svir_bitops 108 · zk_svir_cmp 106 · zk_svir_shift 93 · zk_svir_range 77 · zk_svir_control 89 · zk_svir_mem 112 · zk_svir_mem_dynamic 171 · zk_svir_call 105 · zk_svir_stack 107 · zk_svir_loop 104 · zk_svir_straightline 106 · zk_svir_exec 82 · zk_svir_prog 105 · zk_svir_vm 82 · zk_svir_vm_fused 168.`
**Ω-phase ZK ladder (34, ALL wired regression rungs per run_zk.sh line 15 — the ledger's conditional TRIM resolved KEEP):** `zk_ext2_kat 34 · zk_ext2_fri 107 · zk_ext2_friq 124 · zk_ext2_friN 142 · zk_ext2_fri256 130 · zk_ext2_live 116 · zk_ext2_live2 136 · zk_ext2_stark 87 · zk_ext2_prod 160 · zk_ext4_kat 49 · zk_ext4_probe 22 · zk_ext4_fri 154 · zk_ext4_perm 164 · zk_ext4_committed 239 · zk_ext4_stark_committed 553 · zk_ext4_prod 164 · zk_perm_oracle 122 · zk_perm_malicious 50 · zk_perm_k3prod 204 · zk_fused_committed 459 · zk_fused_prod 267 · zk_eidos_fold 77 · zk_eidos_ripple 107 · zk_gu_ripple_xii 138 · zk_here_to_there 306 · zk_federate_quorum 122 · zk_trust_cert 86 · zk_iiisv_attest 151 · zk_iiisv_local 134 · zk_svir_attest 88 · xii_proof_demo 110 · eidos_ripple_native 65 · eidos_ripple_probe 68 · eidos_ripple_r0 76.`
- [ ] **W4d.5.1 `zk_fused_forge63` 421 — FIX (defect confirmed live):** the header is a verbatim copy of zk_fused_committed's ("zk_fused_committed.iii — P2b SCALE-UP…"). Rewrite lines 1–4 to describe forge63's ACTUAL variant (read the body at execution: the 63-width forge distinction vs committed's N=64 trace — state what the body does, no invention). Gate: its sovir runner green (comment-only).

### W4d.6 — sovtc (54) — KEEP all

**Core:** `sovas 625 · sovparse 923 · sovcoff 203 · sovld 304 · sovlink_main 280 · sovlink_probe 80 · sovas_main 68 · sovld_main 53 · crt0 50.`
**Stage-gate fixtures (each pins one encoder/linker behavior):** `boot1 31 · boot2 25 · boot3 19 · boot4 20 · boot5 12 · boot6 11 · boot7 3 · boot8 14 · linklib 9 · linkmain 12 · sov_drive 22 · sov_drive2 19 · sov_drive3 20 · sov_drive4 19 · sov_drive5 18 · sov_drive6 19 · sov_drive7 19 · sov_drivel 18 · sov_drivel2 18 · sov_drivel3 19 · sov_drivel4 21 · sov_drivel5 19 · sov_drivel6 18 · sov_drivel7 20 · sov_drivel8 23 · test_branch 35 · test_call 48 · test_cmp 30 · test_encode 135 · test_io 47 · test_lea 34 · test_movzx_sib 39 · test_relax_back 44 · test_relax_cascade 30 · test_reloc 60 · test_sib 41 · test_sib_disp 31 · test_sibcall 34 · test_spine 78 · test_store 36 · test_unknown 21 (the silent-drop teeth) · prog_egraph 13 · prog_sat 12 · prog_sha256ni 26 · prog_smt 3.` No actions; gate: the sovtc stage gates.

### W4d.7 — independence (12) — KEEP all

`indep_toolchain 30 · indep_capstone 154 · indep_cap_a 37 · indep_cap_b 85 · indep_cap_c 43 · indep_cap_drive 86 · indep_notary 101 · indep_bignum 54 · indep_ops 18 · indep_recur 18 · indep_zkair 5 · indep_zkcolink 25.` Runner wiring verified by census (run_ccsv/run_ddc/run_svir/run_zk). No actions.

### W4d.8 — W4d exit

- [ ] sovir runners (run_zk + run_ccsv + run_ddc + run_svir sweep) + sovtc stage gates + subsystem gate + full spine green; append EXECUTION RECORD (forge63 header diff).

---

# WAVE 5 — corpus 1774 · corpus_reject 7 · corpus-adjacent files + THE RENUMBERING CEREMONY

**Evidence base:** live 2026-07-02: 1774 numbered KATs (2186_resultant_abi already landed — L11 applies); all 43 duplicate numbers enumerated WITH their pair names; S5 litter purge verified executed (diag_*.o.s gone; remaining: 2 vector .json + _reach_remote_e2e + _quarantine_wip/README).

### W5.1 — Import + refresh the census verdicts (every numbered KAT)

- [ ] **W5.1.1** The ledger's APPENDIX A carries the per-file row for every KAT at census time (`file|owner|verdict|extern-subjects|note`); this plan adopts those rows wholesale for the ~1731 KEEP verdicts and ADDS the post-census arrivals: `2177_resultant · 2178_refract · 2179_resultant_big · 2180_resultant_closure · 2181_arc_tangency · 2182_march_v2 · 2183_gas_compact · 2184_photon_stack · 2185_sturm_big · 2186_resultant_abi` — each: KEEP, owner run_sqrtsum_kats, registration verified (8 manifest matches at authoring; re-verify the full set at execution) + every further 2187+ arrival by L11.
- [ ] **W5.1.2** The 19 KEEP-RETARGET rows: retargets EXECUTED with the merges (`1d21c3f6`) — verify each KAT's extern now names the absorbed module (the W0.1.2 table is the checklist) and flip the rows to KEEP.
- [ ] **W5.1.3** The 6 KEEP-FIXDEP topo rows (2088–2093): unblocked by W2.1's note fix — verify run_topo green and flip to KEEP.
- [ ] **W5.1.4** `1492_mathlib_index_differential` — FIX (census-flagged): its `ident_eq from "ident.iii"` names a nonexistent module; point the `from` at the real provider (find it: `grep -rln "fn ident_eq" STDLIB/iii` — expected numera/identifier.iii); gate: the KAT green.
- [ ] **W5.1.5** The 5 hand-adjudicated anomalies stay KEEP with their census notes (238/242 `_unused.iii` decorations intentional · 1673 self-writing fixtures · 1048 raw non-UTF8 as the test). No action.

### W5.2 — THE RENUMBERING CEREMONY (one commit, L2)

**The convention discovered at authoring (formalize, don't destroy):** 6 duplicate numbers are DELIBERATE positive/negative twins mirroring the static-negative gate scripts: `262 (cap_flow_static + neg_cap_flow) · 263 (intent_kind) · 264 (k_floor) · 265 (return_kind) · 267 (call_arg) · 269 (type_alias)`.
- [ ] **W5.2.1** Formalize the twin convention: one comment block in run_corpus.sh at the EXPECTED table head ("a number may be shared by exactly one positive/negative twin pair; twins are `N_x` + `N_neg_x`") + the hygiene check in W5.2.4 exempts exactly these.
- [ ] **W5.2.2** Adjudicate the 3 ambiguous pairs by reading both files: `711 (format_sealed_builder | sovereign_neg) · 713 (inet_sealed_builder | sovflow_neg) · 714 (async_id_alias | sovflow_pos)` — sovflow pos/neg crossing 713/714 with unrelated files suggests true collisions wearing twin-like names; whichever fails the strict `N_x`+`N_neg_x` same-subject test is a collision → W5.2.3.
- [ ] **W5.2.3** Renumber the TRUE collisions (34 numbers, younger file moves; age by `git log --format=%ad -1 -- <file>`): `128 (glob | self_host_ripple) · 200 (calculus_18_primitives | slhdsa_roundtrip) · 201 (lazy_crystal_levels | pq_dispatch) · 202 (aes192_kat | memo_determinism) · 203 (hmac_sha512_rfc4231 | jit_fuse_amortized) · 204 (drbg_sp80090a | prespec_hw_offload) · 205 (drbg_hw_entropy | governance_full_loop) · 206 (observe_and_propose | xchacha20_poly1305) · 207 (aes_siv_rfc5297 | babel_wire_roundtrip) · 208 (cap_handshake | ecdsa_p256) · 209 (ecdsa_p384 | idoc_roundtrip) · 299 (bit_identity_probe | xii_FTHEN) · 394 (katabasis_bar_typing | option_specialize) · 395 (katabasis_cycle_admit | result_specialize) · 1050 (mig2_cost | sealed_channel_forge_desync) · 1051 (base64_pad_reject | mig2_sovval) · 1052 (base32_trailing_reject | sov_morphism) · 1053 (html_apos_unescape | xii_morphism) · 1054 (h9_mig2_tie | q128_ops) · 1247 (induct_wj | k0_referee) · 1400 (glyph_v3_forms | self_model) · 1401 (field_curve_vault | gap_conjecture) · 1402 (gov_charter_hexad | harmony_synth) · 1403 (kchain_json_iter | refactor_propose) · 1404 (optimize_self | scalar_result_rune) · 1405 (provenance_span_basis | theorem_grow) · 1406 (autogenesis_cycle | term_arena_xoshiro) · 1407 (autogenesis_revert | lattice_cells) · 1408 (autogenesis_attest | intent_table) · 1409 (autogenesis_charter | scalar64_sat_counters) · 1410 (autogenesis_cli | semver_uri_sha512_tp) · 2012 (seraphyte_isub | zk_air_mal_cp) · 2132 (eidolon | mod_pow2) · 2169 (gas_reversal | studio_kernel — the census-flagged one; gas_reversal moves per the ledger)` + any of 711/713/714 failing W5.2.2. New numbers from the RESERVED BLOCK **2400–2447** (clear of the marching Turing-charter increments 2185–2193 and all history; extend upward if the count exceeds the block). Per file: `git mv`, rename-in-place of its EXPECTED key in run_corpus.sh (keys are full names), family-runner list line if owned, any DOC references (`grep -rn "<oldname>" DOCS STDLIB/scripts`). ONE commit.
- [ ] **W5.2.4** Add the uniqueness teeth to run_corpus.sh (it already hard-pins EXPECTED): a preamble check — duplicate number ⇒ FATAL unless in the twin table. Prove it: seed a fake `9999_a.iii`+`9999_b.iii` locally → sweep must abort naming them → remove. Gate: `run_corpus.sh` FAIL=0 AND the dup-scan (`ls STDLIB/corpus | grep -E "^[0-9]+_" | awk -F_ '{print $1}' | sort | uniq -d` minus twin numbers) EMPTY.

### W5.3 — corpus_reject (7) + corpus-adjacent files

- [ ] `r01_unresolved_ident · r04_unknown_fn_call · r05_bad_token · r07_undeclared_assign · r08_dup_fn` + 2 more per reject_conformance.sh listing — **KEEP all 7**; gate: `reject_conformance.sh` green (build-blocking).
- [ ] `_fips205_sha2_128s_small.json` + `_fips205_slhdsa_128s.vectors.json` — location decided by W2.4.1's consumer check (vectors follow their reader; generators quarantined). Row closes when both point one way.
- [ ] `_reach_remote_e2e.iii` — KEEP-LABEL (underscore-skipped manual e2e; needs a live remote; verify the label comment exists).
- [ ] `_quarantine_wip/README.md` — KEEP (the designated quarantine anchor; W2.4.1 adds fips205/ under it).
- [ ] **W5.4 — W5 exit:** run_corpus FAIL=0 · dup-scan clean · all family runners green · append EXECUTION RECORD (renumber map old→new in full, twin table, 711/713/714 adjudication, 1492 provider).

---

# WAVE 6 — DOCS: 274 top-level files + ADR 26 + CONVERGENCE-SPECS 74 + HARDWARE 1 (fresh judgment — the census never did this)

**Verdicts used here:** KEEP-LIVE (load-bearing reference, kept current) · KEEP-HISTORICAL (immutable record of executed work; gets a one-line `STATUS:` header if absent) · KEEP-ARC (member of a complete formal program) · SUPERSEDE→X (KEEP-HISTORICAL + a `SUPERSEDED-BY: X` pointer line at top) · plus the standard rubric. **Nothing historical is deleted or merged — records are evidence; falsifying them by consolidation is forbidden. The consolidation instrument for DOCS is the POINTER, and the index is the map.**

### W6.1 — The index + the diagnosis pair (2 actions first)

- [ ] **`III-INDEX.md` — KEEP-LIVE + REGENERATE:** rebuild the index over the post-W6 doc set with one line per doc: name · class (live/historical/arc/spec) · one-hook description. The index IS the deliverable of this wave; every doc below appears in it exactly once. Gate: W6.5's link-integrity check runs over the regenerated index.
- [ ] **`III-REUNIFICATION-DIAGNOSIS.md` — KEEP-LIVE + CROSS-LINK:** the standing diagnosis this plan answers. Read at execution; add reciprocal pointers (diagnosis → this plan as the execution program; this plan already cites the diagnosis here). Any diagnosis finding NOT covered by a wave row becomes a new row under L10 — enumerate the check in the execution record.
- `III-REUNIFICATION-PLAN.md` — this document. KEEP-LIVE.

### W6.2 — KEEP-LIVE: load-bearing references and standing charters (no action beyond index rows)

`README.md · III-ABI.md · III-GRAMMAR.bnf · III-SYSTEMS-MAP.md · III-STDLIB.md · III-MODULES.md · IIIS-1-ARCHITECTURE.md · IIIS-2-ARCHITECTURE.md · III-CONFORMANCE.md · III-COMPILER-REJECT-CONFORMANCE.md · III-XII.md · XII-IMPLEMENTATION.md · XII-HORIZON-CONSTRUCT.md · XII-HORIZON-DISPATCH.md · XII_CONFLUENCE_SPECIFICATION.md · XII_CEREMONY_PROCEDURE.md · XII_RULE_REVIEW.md · XII-CRITPAIRS-NAMESPACE-ISOLATION.md · XII-CONFLUENCE-COMPLETION.md · III-XII-CONFLUENCE-CERTIFICATE-ARCH.md · TYPE_SYSTEM_SPECIFICATION.md · SPECIALIZATION_SPECIFICATION.md · SUBSYSTEM_TEST_GATE_SPECIFICATION.md · WITNESS_EPHEMERAL_SPECIFICATION.md · TRUSTED-BASE-SEAL.md · SVIR-V1-CANONICAL.md · III-TOOLCHAIN-MANIFEST.md · III-SOVEREIGN-STACK-ARCHITECTURE.md · III-SOVEREIGN-TOOLCHAIN.md · III-SOVEREIGN-CHARTER.md · III-SOVEREIGN-CALCULUS-DESIGN.md · III-SOVEREIGN-BUILD-LIVE.md · III-SOVTC-BIT-FOR-BIT-EXPLICATION.md · III-SOVAS-OPERAND-MODEL.md · III-THE-REACH-ARCHITECTURE.md · III-EIDOS-ARCHITECTURE.md · III-EIDOS-DISPLAY-ARCHITECTURE.md · III-NOUS-ARCHITECTURE.md · III-COVERAGE-LEDGER.md · MHASH-LEDGER.md · MANDATE-LEDGER.md · SOVEREIGN-LEDGER.md · III-STUDIO.md · III-EXACT-DYNAMICS-CHARTER.md · III-COMPLETION-PLAN.md (THE live master plan) · III-AETHER-LENS.md · III-CODEGEN-PATTERNS.md · III-EMIT-GENERIC-ARCHITECTURE.md · III-BV64-KERNEL-MODEL.md · III-QUOTIENT-WELD.md · III-UNIVERSAL-BLOCK.md · III-INVERSE-LIBRARY.md · III-EVENT-SUBSTRATE.md · III-INTERIOR-LOGIC-ATLAS.md · III-VERIFIABLE-ROOT-ARCHITECTURE.md · III-VERIFIED-COMPUTING-SUBSTRATE.md · III-SOVEREIGN-WITNESS-ARCHITECTURE.md · III-RIPPLE-OPTIMIZER-ARCHITECTURE.md · III-M23-QUINE-SEAL-ARCH.md · III-AFFINE-AUDIT-DESIGN.md · III-WTYPES-DESIGN.md · III-QTT-DESIGN.md · III-P5-DEPENDENT-CORE-DESIGN.md · RING-MINUS-1-I5-DESIGN.md · III_ISA_ROADMAP.md · III-SILICON-FRONTIER.md · III-GENERATIVE-FRONTIER.md · CRYPTO_PRIMITIVE_INVENTORY.md · IRPD_METHOD_AUTHORITY.md · HEXAD_COMPOSE_AUTHORITY.md · FED-ECLIPSE-QUORUM-REFERENCE.md · FED-GENESIS-DESCENT.md · FORWARD_REFERENCES.md · SOVEREIGN_FORGE.md · III-COMPONENT-AUTHORING.md · III-FRAGILE-PORT-SAFEGUARDS.md · III-DEVELOP-UP-ENCAPSULATION.md · III-H13-ONELANG-COMPLETION.md · III-HOLOGRAPHIC-CONFORMANCE.md · III-CONSENSUS.md · III-STDLIB-adjacent: BENCHMARKS-v1.0.md · III-CRYPTO-SPEEDUP-MEASUREMENTS.md · SVM-CONSTANTS-HARVEST.md.`

### W6.3 — KEEP-LIVE (subsystem reference series for the parallel C runtime stack)

`III-CYCLES.md · III-EFFECTS.md · III-ERRORS.md · III-FEDERATION.md · III-HEXAD.md · III-KATABASIS.md · III-LEXICON.md · III-LEGACY-INGESTION.md · III-OBSERVABILITY.md · III-PERFORMANCE.md · III-PHASES.md · III-PLANETARY.md · III-POLYMORPHIC-DATA.md · III-PORTABILITY.md · III-RESOLUTION.md · III-SANCTUM.md · III-SANDBOX.md · III-SOVEREIGN-WEB.md · III-TRINITY.md · III-TYPES.md · III-GHOST-CODE.md · III-GENESIS-VECTOR.md · III-CRYPTO-AGILITY.md · III-CATALYST.md · III-CATALYST-EXT.md · III-CONSTANTS.md · III-FOUNDERS-ANCHOR.md.` Verdict: KEEP-LIVE (each documents a live sibling subsystem dir). Index rows only.

### W6.4 — KEEP-ARC: the walls formal program (complete, cross-woven)

`III-COMMCOMPLEXITY-WALL-FORMAL.md · III-CONFLUENCE-WALL-FORMAL.md · III-CONSTRUCTIBILITY-WALL-FORMAL.md · III-DIOPHANTINE-WALL-FORMAL.md · III-GI-WALL-FORMAL.md · III-INDEPENDENCE-WALL-FORMAL.md · III-LATTICE-WALL-FORMAL.md · III-PARITY-WALL-FORMAL.md · III-PRIMALITY-FACTORING-WALL-FORMAL.md · III-RAMSEY-WALL-FORMAL.md · III-SAT-WALL-FORMAL.md · III-WALL-GEOMETRY.md · III-WALL-OF-ALL-WALLS.md · III-WALLS-CASHED-IN.md · III-WALLS-CROSS-SYNTHESIS.md · III-THE-PARITY-WALL-CAPSTONE.md · III-PARITY-BROADER-REACH.md · III-PARITY-IN-P-FRONTIER.md · III-PARITY-RESIDUAL-HOPES.md · III-LOGIC-GRAIL-LEDGER.md.` KEEP-ARC all. W1.2.1's relocated `III-PARITY-GAMES-RESULTS.md` joins this arc in the index.

### W6.5 — KEEP-HISTORICAL: executed campaigns, audits, crash forensics (STATUS-header sweep)

Every file below gets, if absent, ONE first-content line: `STATUS: HISTORICAL RECORD (executed <era>); superseding/live doc: <X or ->` — then is left untouched forever.
- Campaign plans (executed): `III-MODULE-2-TERNARY-PLAN.md · III-MODULE-3-HEXAD-PLAN.md · III-MODULE-4-UNCERTAINTY-PLAN.md · III-MODULE-5-SOVVAL-PLAN.md · III-MODULE-6-WITNESS-PLAN.md · III-MODULE-7-XII-PLAN.md · III-MODULE-8-SID-REVERSIBILITY-PLAN.md · III-MODULE-9-PROOF-KERNEL-PLAN.md · III-MODULE-10-CONSTITUTION-PLAN.md · III-MODULE-11-DECISION-PLAN.md · III-MODULE-12-13-CATEGORY-COST-BATCH-PLAN.md · III-MODULE-14-15-MEMO-SYNTHESIS-BATCH-PLAN.md · III-MODULE-16-PROOF-CARRYING-PLAN.md · III-ORGAN-C-WITNESSED-SENSE-PLAN.md · III-ORGAN-E-FORKED-WALK-PLAN.md · III-ORGAN-A-PROPOSER-LEARNING-FINDING.md · III-SERAPHYTE-CLOSURE-PLAN.md · III-SERAPHYTE-INTEGRATION-PLAN.md · III-EIDOS-VERIFICATION-MEMBRANE-PLAN.md · III-XII-CONFLUENCE-CERT-IMPL-PLAN.md · III-MIG4-STEP1-SPEC.md · III-AUTOPOIETIC-SEED-SYNTHESIS-PLAN.md · III-TOTAL-SWEEP-PLAN.md · III-TOTAL-SWEEP-SPECS.md · III-UNIFIED-WEAVE-MELT-PLAN.md · RING-MINUS-1-PLAN.md · RING-MINUS-1-LEDGER.md · RING-MINUS-1-MILESTONE.md · III-SVIR-ALGEBRAIC-EQUIVALENCE-PLAN.md · III-SVIR-DDC-AND-FORMALIZATION-PLAN.md · III-CLASS2-PORT-BLUEPRINT.md · III-RIPPLE-FORCEFIELD-PLAN.md · III-SELF-OPTIMIZER-PRODUCTIONIZATION.md · III-SOVEREIGN-ENHANCEMENT-COORDINATION.md · III-STRUCTURAL-AUDIT-PLAN-00-DOCTRINE.md · III-STRUCTURAL-AUDIT-PLAN-INVENTORY.md · III-STRUCTURAL-AUDIT-PLAN-1-WAVE0-PRIMITIVES.md · III-STRUCTURAL-AUDIT-PLAN-2-WAVE12-CRYPTO-KERNEL.md · III-STRUCTURAL-AUDIT-PLAN-3-WAVE3.md · III-STRUCTURAL-AUDIT-PLAN-4-WAVE4-GATES.md · III-STRUCTURAL-AUDIT-PLAN-5-WAVE56-FORGE-COMPILER.md · III-STRUCTURAL-AUDIT-PLAN-CLOSURE.md · III-STRUCTURAL-AUDIT-VERIFICATION.md · III-STRUCTURAL-AUDIT.md.`
- Audits & findings (records): `CONVERGENCE-AUDIT.md · CONVERGENCE-BUILD-LEDGER.md · III-CONVERGENCE-LIVE-AUDIT.md · III-ARCHITECTURE-AUDIT.md · III-ARCHITECTURE-REVIEW.md · III-SOUNDNESS-AUDIT.md · III-TRAJECTORY-AUDIT.md · III-WASTE-AUDIT.md · III-WASTE-AUDIT-II.md · III-WEAVE-CENSUS.md · III-WEAVE-DEAD-IMPORT-GATE.md · III-HARMONY-AUDIT-FINDINGS.md · III-FINDINGS-WAVE-W2616.md · III-FINDINGS-WAVE-W2700.md · III-FINDINGS-WAVE-W2900.md · III-FINDINGS-WAVE-W3000.md · III-F6-LEDGER-AUDIT.md · III-R3-CATALOG-WIRING-AUDIT.md · III-DIV-SITE-AUDIT.md · III-CCSV-LEX-NULL-AUDIT.md · III-CCSV-SEED-GAP-MAP.md · III-QUANTUM-PRINCIPLE-AND-MATH-AUDIT.md · III-GAP-ANALYSIS-2026-06-19.md · SEED-DDC-ANALYSIS.md · SVIR-DDC-FINDINGS.md · SVIR-DDC-RESIDUAL.md · III-SOVAS-SELFHOST-FIXLIST.md · III-SOVEREIGN-TOOLCHAIN-REVIEW.md · III-SOVEREIGN-OPTIMIZER-LEDGER.md · III-AUTOGENESIS-LEDGER.md · III-AUTOGENESIS-WAVE.md · III-CAPABILITY-PROOF-LEDGER.md · III-CAPABILITY-VERIFICATION.md · III-CAPABILITY-APOTHEOSIS.md · III-AUTHENTIC-CAPABILITY-DEMONSTRATION.md · III-CONJECTURE-FACULTY-AND-CAPABILITY-PROOF.md · III-COMPLETION-CAMPAIGN-LEDGER.md · III-NIH-ENHANCEMENT-WORKFLOW-LEDGER.md · III-SEED-FLOOR-PROGRESS.md · III-V1.0-STATE.md · MATH_LIBRARY_QUEUE.md · CHARIOT_HARVEST.md · III-EIDOS-SESSION-RETROSPECTIVE.md · III-EIDOS-EVENT-DRIVEN-AUDIT.md · III-EIDOS-OPTIMIZER-SOUNDNESS.md · III-EIDOS-SUBSTRATE-READINESS.md · III-EIDOS-BOOTSTRAP-BLOCKER.md · III-DYNAMIC-REACTOR-VERDICT.md · III-FINGER-CUTTER-VERDICT.md · III-PHYSICS-ENCODING-VERDICT.md · III-BEYOND-DETERMINISM-CONTEMPLATION.md · III-LEGACY-VS-INVERSE-STRUCTURE.md · III-ASSIMILATION-SCOPE.md · III-OPTIMIZER-PATH-C.md (live-adjacent: Path-C standing program — classify LIVE in index) · GATE-SYS-EMISSION-AUDIT.md · IOCTL-GATE-AUDIT.md · PE-DIRECT-CALL-DIVERGENCE.md.`
- Crash forensics: `CRASH-AUDIT.md · CRASH-AUDIT-BSOD-2026-06-04.md · CRASH-AUDIT-C10-r3-ioctl.md · CRASH-AUDIT-gate-resident.md · CRASH-AUDIT-gate-resident-2.md · SLH-DSA-SHA2-SIGN-CRASH-AUDIT.md · M23-9B-MISMATCH-INVESTIGATION-2026-06-04.md.`
- ZK gap records (closed by the landed fixes): `III-ZK-CONCRETE-SOUNDNESS.md · III-ZK-PERM-SEED-GAP.md · III-ZK-SOUNDNESS-GAP.md · III-ZKVM-TRACE-LDT-GAP.md · III-CG-R0-CRYPTO-DEFECT.md.`
- Exact-geometry face records: `III-CSG-UNSHATTERABLE.md · III-PHOTONIC-LATTICE-ROUTING.md · III-ZERO-DRIFT-KINEMATICS.md · III-NO-TUNNELING-COLLISION.md · III-ROBUST-PREDICATES-DELAUNAY.md · III-EXACT-ROOT-ISOLATION.md · III-EXACT-ALGEBRAIC-NUMBERS.md · III-EXACT-SUBSTRATE-INTEGRATION.md · III-DOME.md.`

### W6.6 — SUPERSEDE→X pointers (the consolidation instrument; 8 rows)

- [ ] `III-GRAND-UNIFICATION-AUDIT-AND-PLAN.md` + `III-GRAND-UNIFICATION-MASTER-PLAN.md` — SUPERSEDE→`III-COMPLETION-PLAN.md` (three master plans → ONE live; the two records keep their content).
- [ ] `III-PRODUCTION-PERFECTION-LEDGER.md` — SUPERSEDE→`III-PERFECTION-LEDGER.md` (two perfection ledgers → the census is the live one). Verify direction by dates at execution (older gets the pointer).
- [ ] `III-DISPOSITION-AUDIT.md` + `III-DISPOSITION-EXECUTION.md` — SUPERSEDE→`III-PERFECTION-LEDGER.md`.
- [ ] `III-PRODUCTION-READINESS-AUDIT.md` + `III-PRODUCTION-READINESS-COMPLETION.md` — completion supersedes audit: pointer on the audit; completion classed historical.
- [ ] `III-GAP-ANALYSIS-2026-06-19.md` — SUPERSEDE→`III-GAP-BACKLOG.md`.
- [ ] `III-APOTHEOSIS.md · III-APOTHEOSIS-IMPL-LEDGER.md · III-APOTHEOSIS-MIGRATIONS-ARCH.md · III-APOTHEOSIS-PREP.md` — the 4-doc apotheosis arc: PREP gets SUPERSEDE→APOTHEOSIS; the standing honesty label ("13 charter green, NOT systemwide; 7 migrations unbuilt") verified present in APOTHEOSIS.md — add if absent.
- [ ] `III-HARMONY-BACKLOG.md` + `III-GAP-BACKLOG.md` + `III-ENHANCEMENT-BACKLOG-W3400.md` — three live backlogs: KEEP-LIVE all three but the index marks ONE intake (GAP-BACKLOG) and the other two as domain backlogs; any entry executed by this plan's waves gets struck WITH a row-reference at execution.
- [ ] `XII_R1.mhash` — a seal artifact inside DOCS: verify its consumer (`grep -rn "XII_R1.mhash" COMPILER STDLIB DOCS | grep -v Binary`); if consumed by a gate, RELOCATE→`COMPILER/BOOT/` beside its siblings (updating the consumer path); if referenced only by docs, KEEP-LABEL in place (a pinned constant the docs cite). Record which.

### W6.7 — Subdirs + tool-managed

- `ADR/` (26) — KEEP-LIVE all; ADR-6's W4c.2.1 resolution is recorded INTO the ADR at execution (the wire-or-strike outcome). Index gains an ADR section.
- `CONVERGENCE-SPECS/` (74) — KEEP-ARC (the convergence spec corpus backing CONVERGENCE-AUDIT); index row per spec is NOT required (the dir is one arc entry) but the completeness gate counts its files (74) explicitly.
- `HARDWARE/` (1) — KEEP.
- `superpowers/` — tool-managed plan artifacts (session infrastructure); KEEP, excluded from the index body, named in the completeness gate's allowlist.

### W6.8 — W6 exit

- [ ] Link-integrity check (one-shot shell over `\[.*\]\(.*\.md\)` targets in DOCS resolving to existing files — broken links enumerated and fixed in this wave) · III-INDEX.md regenerated with every W6 row present · STATUS-header sweep applied (list in execution record) · the 8 supersession rows executed · full spine untouched-green (docs-only wave; `git diff --stat HEAD -- STDLIB COMPILER` empty).

---

# WAVE 7 — the sibling top-level dirs, per-file (KATABASIS-DEPLOY 130 · R2-GENESIS 15 · FOUNDERS-ANCHOR 5 · TOOLS-QUOTIENT 5 · root build/ 48)

**Evidence base:** live listings 2026-07-02. EXCHANGE/ verified ABSENT from the tree (the toolchain-manifest doc must not dangle — W6.8's link check covers it; recorded here).

### W7.1 — KATABASIS-DEPLOY (130) — KEEP the deploy arm, purge its build litter

- **KEEP (the arm):** `README.md` · gates `build_gate_floor.sh · build_gate_ioctl.sh · build_gate_resident.sh · build_gate_sys.sh · verify_gate_resident.sh · verify_gate_sys.sh` · deploy `get_crash.ps1 · sign_and_deploy.ps1 · sign_and_deploy_floor.ps1 · sign_and_deploy_ioctl.ps1` (PowerShell is the Windows driver-signing surface — labeled deploy-host tooling, not III build path) · `src/` (18 .iii + 2 .c + asm sources) · `crash/` (2 .dmp + forensics — evidence, KEEP) · deployed binaries `gate.sys/gate.signed.sys · gate_floor.sys/.signed.sys · gate_ioctl.sys/.signed.sys · gate_resident.sys/.signed.sys` + their .s/.dis lineage. Standing label verified: M23 Ring-0 arm is NEVER auto-run.
- [ ] **W7.1.1 DELETE build litter:** the 26 `build/*.log` session logs (build_iiis2*.log, corpus_*.log, gate_floor_i3*.log ×10, …) + `build/obj/` intermediates + stale client exes (`floor_client.exe · gate_client.exe · quine_attest_check.exe · quine_attest_client.exe` — regenerable by the gates). L5 grep each class against the .sh gates first (a gate that READS a log keeps it).
- [ ] **W7.1.2 DELETE the 2 Python files (no-Python, tree-wide):** `build/decode_rm1_hv.py` (rm1 port-era hex decoder — the port completed; outputs long committed) + `build/stackdepth.py` (one-shot stack analysis). Read each first; any live finding gets 3 lines in the KATABASIS doc before deletion. Then `grep -rn "\.py" KATABASIS-DEPLOY --include="*.sh" --include="*.ps1"` → zero invocations.
- [ ] **W7.1.3** gitignore `KATABASIS-DEPLOY/build/` regenerables (keep the signed .sys artifacts tracked — they are the deployed lineage) + hygiene-gate pattern.

### W7.2 — R2-GENESIS (15) — KEEP-PRESERVED

`_PRESERVED_BY.md` + `silicon/` (14). Preservation marker present; no action. Row: verify `_PRESERVED_BY.md` names its preserving authority and the restore path (read at execution; one-line fix if the pointer is stale).

### W7.3 — FOUNDERS-ANCHOR (5) — KEEP-CRITICAL, honesty labels verified

`README.md · anchor_pubkey.bin · SEALED_OPERATOR_SECRET · anchor_seed.TESTONLY.bin · _GENESIS_CEREMONY_PENDING.md.`
- [ ] **W7.3.1** Verify the two honesty labels: README states the ceremony is PENDING and that `anchor_seed.TESTONLY.bin` is TEST-ONLY (never the production seed). If either statement is missing or stale, fix the README — do NOT touch the bins. Gate: read-only verification recorded.

### W7.4 — TOOLS-QUOTIENT (5) — ADJUDICATE the three orphans, then REMOVE THE DIR

The staged duplicates are already purged (`4a715dae`); five files remain.
- [ ] **W7.4.1** `2274_meta_involution_orbit.iii · 2276_quotient_space_compute.iii · 2277_quotient_oracle_orbit.iii` — read each against the LANDED successors: the q23→vg_sign quotient weld (LIVE, gated) and the {BELOW,REFLECT} involution closure (2140/2141 gated). **Default (expected): DELETE as superseded** — each names its landed successor in the execution record. **Promote-instead trigger:** only if the read finds a capability the landed weld does NOT carry (then: promote to corpus with a W5-ceremony number + EXPECTED entry + gate green). No third option.
- [ ] **W7.4.2** `build_and_run.ps1` — dies with the dir (its only purpose was the staged trio). `README.md` — its adjudication summary moves into the execution record. Then `rmdir TOOLS-QUOTIENT` — the dir ceases to exist; the ledger's §15d row closes.

### W7.5 — root `build/` (48, all under `_msvcddc/`) — CONDITIONAL EMPTY

- [ ] The MSVC-DDC verification tree: check the recorded DDC state (`DOCS/SEED-DDC-ANALYSIS.md` + `SVIR-DDC-FINDINGS/RESIDUAL`) — if the MSVC-DDC re-run is recorded COMPLETE, delete `_msvcddc/` contents (48 files, regenerable by `seed_ddc_msvc.sh`); if a residual is OPEN, KEEP until that residual's own closure, and say which residual in the execution record. Either way `build/` stays gitignored (W1.2.6).

### W7.6 — W7 exit

- [ ] KATABASIS gates (`build_gate_*.sh` compile-check where runnable without deploy) green · hygiene gate green with the new patterns · `ls TOOLS-QUOTIENT` → gone · append EXECUTION RECORD (orphan adjudications with successors named, py deletions, msvcddc decision).

---

# WAVE 8 — FINALE: ratchets re-pinned, completeness proven, the whole spine green in one sweep

- [ ] **W8.1 — Ratchet re-pin (L7, DOWN only):** after W0–W7, regenerate the coverage reports; set each pin to the achieved value if LOWER than the current pin (`coverage_pin.txt ≤ 5 · coverage_gate_pin.txt ≤ 2 · coverage_reach_pin.txt ≤ 14`, `self_model_pin.txt`/`theorem_floor.txt` at their floors). A pin that cannot move down is recorded with the named residual exports.
- [ ] **W8.2 — STRICT completeness gate (the census-hole class killed):** mechanical name-diff of THIS PLAN vs the live tree: every live file (git-tracked + untracked non-ignored) under `STDLIB/ COMPILER/ COMPILED/ DOCS/ KATABASIS-DEPLOY/ R2-GENESIS/ FOUNDERS-ANCHOR/` + repo root must appear in a VERDICT ROW of this plan (waves 0–7, strict-form: name inside a wave section, appendix mentions do not count — the lesson of W4a's corrigendum). Misses = L11 arrivals or plan defects: each gets its row before W8 closes. The diff command and its zero-miss output go in the execution record verbatim.
- [ ] **W8.3 — The one-sweep final gate:** in ONE uninterrupted sequence: `build_stdlib.sh` (FAIL = 0 + ratchets green) → `run_corpus.sh` (FAIL=0, dup-scan clean) → all 13 family runners → `subsystem_test_gate.sh` → `reject_conformance.sh` → seed identity + trusted base + `build_iiis2 --check-corpus` → sovir/sovtc gates → `fast_check.sh` (hygiene teeth) → `seal_sources.sh` verify. Any red = stop, fix under the wave that owns the file, re-run the WHOLE sweep (no partial-credit finales).
- [ ] **W8.4 — Close:** append the final EXECUTION RECORD (all wave records linked, total files adjudicated EXACT, commits enumerated, deviations + L10 laws learned); update `III-INDEX.md` with this plan marked EXECUTED; one line to the ledger §17 noting the program completed; the working tree ends CLEAN (`git status --short` empty).

**Self-review against the brief (run at authoring, recorded):** (1) Every-file coverage — waves 0–7 enumerate every live file by name at authoring time, and W8.2 re-proves it mechanically at execution against the tree as it will then exist (L11 absorbs the growth in between). (2) Placeholder scan — no TBD/TODO/defer verbs in any row; every conditional is a decision procedure with both branches fully specified. (3) The requested tone mix is real: unify (seraphyte emitters, cost_lattice_synth, field demos, S8 manifest, supersession pointers), simplify/refactor (ui_exact split, xii_proof split, MODULES comment sweep), fix bugs (forge63 header, 1492 extern, self_atlas_data ghost provenance, stale volatile note, 34 number collisions), throw away (root regrowth ~170, KATABASIS logs + 2 py, TOOLS-QUOTIENT, root py ×7), gate what was ungated (morphic, destiny, tp_ sweep, symbolic_regression + nl_parse falsifiers, hygiene ratchet, dup-number teeth), and keep-with-proof for the ~3,400 files that already clear the bar — each named, each with its gate.

*This plan was authored against the live tree on 2026-07-01/02 under the session law (gate → invariant-guard → evidence per wave). It is append-only-improving: execution records and L10/L11 additions extend it; its rows are never silently rewritten.*

## L10 ADDITION (2026-07-02) — THE CIRCULATION: seals/gates/KATs re-founded for a system that outpaces them

**The problem, stated honestly (user, mid-execution):** the seals and gates in their batch form do not
fit a system that changes faster than a full sweep completes. Waiting ~40 minutes for an "okay" is not
verification, it is a stall. And a monolithic seal re-proves the expensive DDC/twin-build goodie on every
organ edit although organ edits cannot possibly break compiler-province sovereignty.

**What was actually wrong (and what was NOT):**
- NOT wrong: the DDC / twin-build BIT-IDENTICAL / GCC-independence properties themselves. Those are real
  sovereignty goodies and are PRESERVED intact.
- NOT wrong: KATs as *contract + falsifier* pins. A KAT that carries a twin-divergence or certified-refusal
  witness proves something a self-aware system cannot prove about itself by introspection — that the WRONG
  answer is actually rejected by the built binary. "The system knows the right answer" is exactly why the
  falsifier (does it reject the wrong one?) is the load-bearing half.
- WRONG: the *topology*. Assurance was BATCH and MONOLITHIC — every change waited on the whole corpus, and
  every seal re-ran the whole twin build.

**The fix (landed, commit 22c2191e):**
1. **verify_cone.sh** — the dependency graph is already fully written (externs + runner link-lines), so a
   change-set resolves to an exact dirty cone and re-verifies ONLY that, keeping a content-addressed ledger
   (VERIFIED.tsv). Circulation, not batch. Proven: `refract.iii -> {2178,2184}`, sharp vs 1796.
2. **seal_route.sh** — the seal SPLIT: organ edits get a seconds-long hash re-pin; the twin-build goodie
   fires only when COMPILER/BOOT/seed sources move (or `--audit`). The goodie is isolated, not weakened.
3. The full sweep + full twin build demote to a PERIODIC AUDIT (and W8's one-sweep finale is the
   circulation's first full-cycle cross-check — both paths must agree).

**KAT philosophy, recorded:** in-organ certificates carry *assurance* (the math is right); KATs pin
*contracts and falsifiers* (the built binary accepts the right answer and REJECTS the wrong one). A system
being smarter than a KAT is the argument FOR the falsifier, not against it — introspective confidence is
exactly what a built-binary refutation test exists to check. The two are complementary; neither replaces
the other. The remedy for "gates too slow" is the CONE (verify less, exactly), not fewer gates.
