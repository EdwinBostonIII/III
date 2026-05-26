# III-XII Confluence-Core Certificate — Implementation Plan (R1, execution-exact)

Companion to `DOCS/III-XII-CONFLUENCE-CERTIFICATE-ARCH.md`. This is the file-by-file, step-by-step
execution order. **Every step carries a falsifiable GATE and a ROLLBACK; no step begins until the
prior step's gate is green.** That structure — not foresight — is what makes it errorproof: an error
cannot propagate because the step that introduces it cannot pass its own gate.

---

## EXECUTION STATUS — COMPLETE (2026-05-26)

All steps 0.1 → C.6 executed; every gate green. Verified by direct system observation (not assertion):

| Fact | Observed | Where |
|------|----------|-------|
| Subterm non-joins | **35 → 20** (the 15 assoc-involved pairs eliminated *by construction*, route S) | `xjn_nonjoin_count()` |
| Root confluence + termination | gate_root=1, xtm_gate=1 | `xjn`/`xtm` |
| Strategy determinism | xsd=1 | `xii_strategy_det` |
| Residual discharge | **20 route-R, 0 boundary** (boundary proven empty) | `xdc_count_route` |
| Certificate | `xcc_verify`=1, `xcc_reprove`=99; sealed rule-mhash `50222762…a132` | `xii_conf_cert` (corpus 826) |
| H12 charter | green (binds `xcc_verify` + `xsd`) | corpus 698 / 700 |
| Self-hosting determinism | **iiis-2 ≡ iiis-3 = `0a0325e2…cfd9`** (fixpoint), resealed from the pre-route-S `0ef8626a` baseline; iiis-1 unchanged (`a82dc08e`) | `COMPILER/BOOT/iiis-{2,3}.mhash` |
| Whole-system corpus | `run_corpus` **459/0**, `run_xii_corpus` **91/0**, antidrift **8/8**, nous differential GREEN | the gates |

**Route S** made associativity (R001–R004) structural at `xii_term.make_fusion2`; the assoc rules were
retired from the engine, the rule table shrank 49→45, and every B.0-enumerated dependency was
re-derived (selftests xrp/xro/cpe/xjn/xtm/xad/xdc + the per-rule tests 304–307/349 + 820/823 +
`xii_antidrift` repointed to the structural gates). `xii_critpairs` (the hand-117 enumeration, 54/122
broken by route S) is **retired** (out of the build, corpus 344/371 retired, antidrift + the manifest
generator's CONF_SEAL crystal repointed to the certificate).

**Manifest trust-root re-seal — COMPLETED (2026-05-26, on `/goal`).** `seal_xii_final.sh` was run (with
backups + revert-on-failure): the live manifest now carries the certificate (the `CRY-XII-CONF-001`
crystal hashes `xii_conf_cert.iii`) AND resyncs the route-S source crystals (REWRITE_SEAL etc. that B.6
had left stale). New sealed values: manifest mhash **`75bb9861…`** (was `0779269f`), XII_R1
**`92bc8c13…`**, lattice byte-identical (route-S-neutral). The Founders-Anchor was re-signed with the
**same deterministic keypair** — pubkey unchanged **`32d4f9de…`** (re-derived from the unchanged sealed
seed; only its mtime was touched to force the regen), so the trust root is stable. All gates green
after: manifest mhash gate PASS, antidrift **8/8** (incl. the anchor-signature verify), iiis-2 unchanged
(`0a0325e2` — the ceremony does not touch the compiler), corpus **459/0**, XII corpus **91/0**. The
certificate (corpus 826) is the live, re-checkable confluence proof, now also sealed into the manifest.
**No deferral remains — the plan is complete with nothing outstanding.**

## Invariants that hold for every step

- **Pinned compiler:** `COMPILED/iiis-2.exe` (never an autodiscovered `iiis`).
- **Additive-module recipe (Phases A, C):** create `.iii` → targeted-link KAT (`iiis-2 --compile-only`
  + `gcc` with `--whole-archive` side-effect objs + `libiii_native.a` + `-lws2_32 -lkernel32`, /tmp
  staging) → `ar` into the live archive (`printf %s\\0 "${OBJS[@]}" | xargs -0 "$AR" qcD <lib>` then
  `"$AR" sD <lib>`) → register in `build_stdlib.sh MODULES` + `run_corpus.sh EXPECTED` → full
  `build_stdlib.sh` (grep `FAIL = 0`) → `run_corpus.sh` (FAIL=0) → `run_xii_corpus.sh` (FAIL=0).
- **Determinism law:** a step is "seal-neutral" iff `COMPILED/iiis-2.exe` byte-hash is unchanged after
  it. Phases A and C are seal-neutral by construction (compiler-unreferenced stdlib adds). Phase B is
  the *only* determinism-critical phase; it owns the full `build_iiis*` → fixpoint → reseal protocol.
- **Rollback discipline:** before any edit to an existing file, copy it to `*.bak`; before Phase B,
  back up `COMPILED/iiis-{0,1,2,3}.exe` + `COMPILER/BOOT/iiis-1.mhash` + `libiii_native.a` to `/tmp`.
  A failed gate ⇒ restore from backup, never "fix forward."
- **No comment-only rebuild churn:** comment edits are determinism-neutral; never reseal for them.
- **Corpus-dir hygiene:** throwaway probes live in `STDLIB/build/`, never `STDLIB/corpus/` (the
  `run_corpus` glob would FATAL on an unregistered non-`_neg` file).

---

## PHASE 0 — Pre-flight baseline (read-only; the anchor every later gate compares against)

**Step 0.1 — Capture the determinism + correctness baseline.**
- Files touched: none (write a log to `STDLIB/build/cert-baseline.txt`).
- Operation: record `sha256sum COMPILED/iiis-{0,1,2,3}.exe`, `sha256sum libiii_native.a`,
  `head -1 COMPILER/BOOT/iiis-1.mhash`, `run_corpus.sh` PASS/FAIL tally, `run_xii_corpus.sh`
  PASS/FAIL, and the joinability tally via a one-shot probe (`xjn_gate(); xjn_nonjoin_count()` ⇒
  **35**, `xjn_join_count()` ⇒ 50, `xjn_nowit_count()` ⇒ 133).
- Gate: all three suites green at baseline; non-join count == 35. (If not, STOP — the tree is not at
  the known-good state this plan assumes.)
- Rollback: n/a (read-only).

---

## PHASE A — Additive floor + grader (seal-neutral, fully reversible, immediate value)

### Step A.1 — Tier 1: the strategy-determinism proof object
- Files:
  - CREATE `STDLIB/iii/omnia/xii_strategy_det.iii` (`xsd_`). Content: prove, as a KAT, that
    `xii_canonicalise` is a function — for a battery of constructed terms, canonicalise twice and
    assert `xii_rewrite_struct_eq(nf1, nf2)==1` (idempotent determinism), plus the *load-bearing*
    structural fact: assert `xjn_gate_root()==1` (root overlaps all join ⇒ rule-priority is never
    correctness-load-bearing) AND that the walk is bottom-up (a witness term whose only redex is a
    subterm reduces that subterm — confirming inner-first). Export `xsd_strategy_is_deterministic()
    -> u8` (the H12-consumable predicate) + `xsd_selftest() -> u64` (99 = pass, distinct code per
    failed check incl. prove-the-negative: two genuinely distinct NFs do NOT compare equal).
  - CREATE `STDLIB/corpus/NNN_xii_strategy_det.iii` (NNN = next free; externs `xsd_selftest`, `main`
    returns it). 
  - EDIT `STDLIB/scripts/build_stdlib.sh`: add `"omnia/xii_strategy_det"` to MODULES (after the XII
    block, BSS-safe end).
  - EDIT `STDLIB/scripts/run_corpus.sh`: add `[NNN_xii_strategy_det]=99` to EXPECTED.
- Operation: additive module per the recipe.
- Gate: targeted-link KAT ⇒ 99; `ar`-add; `build_stdlib.sh` `FAIL = 0`; `run_corpus.sh` FAIL=0 with
  `NNN_xii_strategy_det=99`; **`COMPILED/iiis-2.exe` hash UNCHANGED vs 0.1** (seal-neutral check).
- Rollback: `git`-less ⇒ delete the two new files; revert the two script edits from `*.bak`;
  `ar d` the object; rebuild stdlib; confirm baseline restored.
- Yield: H12 may now read **"deterministic by fixed strategy"** truthfully. Banked.

### Step A.2 — Tier 2a: the discharge grader (read-only analysis over the live 35)
- Files:
  - CREATE `STDLIB/iii/omnia/xii_discharge.iii` (`xdc_`). Content (analysis only — no engine change):
    for each non-joining pair `k` (from `xjn_njtab_{i,j,p}`), classify by the route lattice:
    `XDC_S` if rule_i or rule_j ∈ {R001–R004} (assoc-involved ⇒ structural-elimination-eligible);
    else `XDC_R_CANDIDATE` (reachability — to be discharged in C.1); a residual bucket for `XDC_C`.
    Export `xdc_grade(k) -> u8`, `xdc_count_grade(g) -> u64`, `xdc_selftest()` asserting the partition
    (S-eligible == 15; the 20 residual are all `j ∈ R005–R012` per §1; total == 35; prove-the-negative:
    a fabricated joining pair is never graded S/R/C).
  - CREATE `STDLIB/corpus/MMM_xii_discharge.iii` + EDIT `build_stdlib.sh` MODULES + `run_corpus.sh`
    EXPECTED.
- Gate: KAT ⇒ 99 with `xdc_count_grade(XDC_S)==15` and residual==20; full + XII corpus FAIL=0;
  iiis-2 hash UNCHANGED.
- Rollback: as A.1.
- Yield: the 35 are graded; the route-S target set (15) is named in code, not prose.

---

## PHASE B — Route S: structural elimination of the 15 assoc pairs (determinism-critical; isolated)

> This is the only phase that mutates the engine. It is gated behind a blast-radius enumeration and an
> empirical drift decision. Back up `COMPILED/iiis-{0,1,2,3}.exe`, `COMPILER/BOOT/iiis-1.mhash`,
> `libiii_native.a`, and every file edited in B.1–B.3 to `/tmp` BEFORE B.1.

### Step B.0 — Blast-radius enumeration (READ-ONLY; the errorproofing gate of the whole phase)
- Files touched: none (write `STDLIB/build/route-s-blast.txt`).
- Operation — resolve every dependency on the XII canonical form, decisively:
  1. **Dual-XII reach:** `nm COMPILED/iiis-2.exe | grep -i xii_term` (and `xii_rewrite`,
     `xii_canon`). Determine whether the compiler binary's `xii_term_make_fusion2`/`xii_canonicalise`
     resolve from the **BOOT C objects** (`cg_r3_xii.c` + `xii_term.h`) or from the **`.iii` archive**
     (`omnia/xii_term.iii.o`). Cross-check `COMPILED/iiis-2.exe.witness.json` `source_files` (it lists
     `cg_r3_xii.c`, `xii_ldil.c`, `sema_xii.c` — the C XII) and confirm whether `omnia/xii_*.iii.o`
     symbols are *referenced* by the compiler (archive objects are pulled only if referenced).
     **DECISION:** if the compiler uses its own C XII and does not reference the `.iii` symbols, route
     S is stdlib-only (compiler seal-neutral). If it references the `.iii` XII, route S must also
     update the BOOT C XII (`xii_term.h` + `cg_r3_xii.c`) to keep the two in lock-step, and reseal the
     compiler. **The empirical confirmer is B.6's iiis-2 hash check — B.0 predicts, B.6 proves.**
  2. **@lattice dormancy:** confirm `r3_decl_has_lattice` returns 0 for all live source (no `.iii`
     file uses `@lattice`), so the compiler's XII path is dormant and a canonical-form shift cannot
     change emitted code today. `grep -rn "@lattice" STDLIB/ COMPILER/` ⇒ expect zero non-comment hits.
  3. **Sealed artifacts:** inspect `gen_xii_manifest.c`, `gen_xii_lattice.c`, `gen_xii_horizons.c` and
     `COMPILED/xii_lattice.bin` / `xii_lattice.mhash.golden` / `xii_horizons.mhash.golden` — determine
     whether any Horizon pattern or lattice cell encodes a *left-nested* compose (route S would shift
     it). Expect: Horizon patterns are over basis-kernel chains; verify they are nesting-agnostic or
     already right-canonical. Any artifact that IS canonical-form-dependent ⇒ added to the B.5
     re-derive list.
  4. **Canonical-form-dependent corpus goldens:** `grep -ln "make_fusion2(18\|make_fusion2(19\|
     make_fusion2(20\|make_fusion2(21" STDLIB/corpus/*.iii` cross-referenced with tests that
     `struct_eq` a canonicalised result against a hard-coded left-nested expectation. Each such test
     ⇒ B.5 golden-update list.
  5. **Rule-count consumers:** confirm `xii_rule_overlap`, `xii_critpair_enum`, `xii_joinability`,
     `xii_termination`, `nous_policy` all read the rule count dynamically via `xrp_rule_count()` (they
     do) so a 49→45 table needs no edit in them — they auto-adjust.
- Gate: the enumeration is COMPLETE — every file/artifact that references `xii_term`/`xii_rewrite`/the
  canonical form is classified **affected** (with a B.5 re-derive entry) or **unaffected** (with the
  reason). No "unknown." If any item cannot be classified, STOP and investigate; do not proceed to B.1.
- Rollback: n/a (read-only). **This step's completeness IS the phase's safety.**

### Step B.1 — Canonical associativity at the constructor
- File: EDIT `STDLIB/iii/omnia/xii_term.iii`.
- Operation: replace `xii_term_make_fusion2`'s raw body with a canonicalising one. Add a module-scope
  spine buffer `var XT_SPINE : [u8.. no -> u32; 1024]` (bounded by the 1024-term arena cap, so it
  cannot overflow a valid arena). Keep a private raw builder `_xt_make_fusion2_raw` (the old body:
  alloc + set kind + set child_a + set child_b) and make `xii_term_make_fusion2` dispatch:
  - right-assoc kinds (FCOMPOSE=18, FTHEN=19, FWITH=20): if `kind(a) != K` → `_raw(K,a,b)`. Else walk
    a's right spine collecting `child_a`s into `XT_SPINE` while `kind(cur)==K`, ending at the non-K
    tail `cur`; then `acc=_raw(K,cur,b)`; for `i=cnt-1 downto 0`: `acc=_raw(K,XT_SPINE[i],acc)`;
    return `acc`. (Pure iteration; no recursion; the invariant guarantees each `child_a` is non-K.)
  - left-assoc kind (FUNDER=21): mirror — if `kind(b)!=FUNDER` → `_raw`; else collect b's left spine.
  - all other kinds: `_raw` unchanged.
  Single-line `fn` decls; equality-only kind compares; `while` loops; overflow guard (`cnt>=1024` ⇒
  `_raw` fallback, which cannot occur in a valid arena but is a defined floor).
- Gate (local, before any build): `./COMPILED/iiis-2.exe STDLIB/iii/omnia/xii_term.iii --compile-only
  --out /tmp/t.o` ⇒ exit 0 (syntax/codegen valid). Then a /tmp probe: build a left-nested
  `FCOMPOSE(FCOMPOSE(F1,F2),F3)` *through* `make_fusion2` and assert the result's `child_a` kind is
  NOT FCOMPOSE (invariant holds) and the leaf multiset is preserved (F1,F2,F3 present, in order) —
  for all four kinds, both directions. ⇒ 99.
- Rollback: restore `xii_term.iii.bak`.

### Step B.2 — Retire R001–R004 from the rewrite engine
- File: EDIT `STDLIB/iii/omnia/xii_rewrite.iii`.
- Operation: remove R001–R004 from the `xii_rewrite_apply_one` cascade dispatch (so they never fire);
  delete (or `// dead under route S — associativity is structural, see xii_term.make_fusion2`) the
  `match_R001..R004` / `apply_R001..R004` functions. Confirm no other function calls them.
- Gate: `iiis-2 --compile-only xii_rewrite.iii` ⇒ exit 0; grep confirms zero residual references to
  `match_R001..R004`/`apply_R001..R004`.
- Rollback: restore `xii_rewrite.iii.bak`.

### Step B.3 — Shrink the declarative rule table 49 → 45
- File: EDIT `STDLIB/iii/omnia/xii_rule_patterns.iii`.
- Operation: remove the four `_xrp_set` rows for R001–R004 (slots 0–3); renumber the remaining slots
  0..44 contiguously; update `XRP_N` 49→45 and the `xrp_selftest` index assertions (first rid now 5,
  count 45, the array bounds). The downstream gates read `xrp_rule_count()` so need no edit (B.0 #5).
- Gate: `iiis-2 --compile-only` ⇒ exit 0; `xrp_selftest` (via its corpus test) ⇒ 99 with count 45.
- Rollback: restore `xii_rule_patterns.iii.bak`.

### Step B.4 — Aggregate compile-check (pre-build audit; [[feedback_audit_before_rebuild]])
- Files: none (read the three edited files line-by-line by hand; compile each via iiis-2).
- Gate: all three compile exit 0; manual review confirms B.1 invariant code, B.2 no dangling refs, B.3
  contiguous table. **No build yet** — this catches errors before the expensive reseal.
- Rollback: restore the relevant `*.bak`.

### Step B.5 — Re-derive every B.0-enumerated canonical-form dependency
- Files: exactly the affected list from B.0 (corpus goldens with hard-coded left-nested expectations;
  any canonical-form-dependent Horizon/lattice/manifest artifact; and — only if B.0 #1 found the
  compiler references the `.iii` XII — the BOOT `xii_term.h` + `cg_r3_xii.c` C twins, edited to match
  B.1).
- Operation: for each, re-derive against the NEW right-canonical form (update the expected golden /
  regenerate the sealed artifact). Each gets its own micro-gate (the test/artifact re-verifies).
- Gate: every affected item re-derived and individually green. Zero items from B.0 left untouched.
- Rollback: restore each from its `*.bak`.

### Step B.6 — The reseal protocol (the one determinism-critical build)
- Files: produces `COMPILED/iiis-{1,2,3}.exe` + `libiii_native.a` + possibly `COMPILER/BOOT/iiis-1.mhash`.
- Operation, in order:
  1. `build_stdlib.sh` ⇒ `FAIL = 0`; record new `libiii_native.a` hash.
  2. **Drift decision (confirms B.0 #1):** rebuild the chain only if needed — first check: does iiis-2
     reference the changed `.iii` XII? Run `build_iiis1.sh`→`build_iiis2.sh`; compare new
     `COMPILED/iiis-2.exe` hash to the 0.1 baseline.
     - If **unchanged** ⇒ route S is compiler-seal-neutral (B.0 #1's "stdlib-only" branch confirmed);
       no `iiis-1.mhash` reseal; skip to B.7.
     - If **changed** ⇒ the compiler embeds the `.iii` XII; this is intended only if B.5 also updated
       the BOOT C twins. Reseal `COMPILER/BOOT/iiis-1.mhash` (per the recipe: build_iiis1 dies exit5 on
       drift → copy `iiis-1.exe.mhash` hex into the golden → rerun exit0), then `build_iiis2.sh` →
       `build_iiis3.sh --check-corpus` ⇒ **fixpoint iiis-2 ≡ iiis-3** (bit-identical) + stage1 corpus
       equivalence green.
  3. Re-derive `xii_lattice.bin` / Horizon goldens IF B.0 #3 flagged them (regenerate via the
     `gen_xii_*` tools; reseal `*.mhash.golden`).
- Gate: `build_iiis*` chain exit 0; fixpoint holds (if the chain ran); `libiii_native.a` rebuilt
  cleanly. Record all new hashes to the baseline log.
- Rollback: restore `COMPILED/iiis-{0,1,2,3}.exe`, `iiis-1.mhash`, `libiii_native.a` from /tmp backups;
  restore the three edited `.iii` from `*.bak`; rebuild; confirm 0.1 baseline restored exactly.

### Step B.7 — Verify the elimination achieved its purpose
- Files: none (run probes + suites).
- Gate (ALL must hold):
  - `xjn_nonjoin_count()` ⇒ **20** (down from 35; the 15 assoc pairs gone).
  - `xtm_gate()` ⇒ 1 (termination still holds on the 45-rule set; note the `assoc_penalty` component
    is now inert — record whether it can be retired as a later simplification, do NOT change it now).
  - R032 + R042 spine-sort KATs green (the FORM-sort still produces the ascending right-nested spine).
  - `run_corpus.sh` FAIL=0; `run_xii_corpus.sh` FAIL=0.
  - `xdc_count_grade(XDC_S)` now resolves to "discharged-by-construction" for the 15 (re-run the
    grader against the 45-rule engine ⇒ S-set is empty in the live non-joins; the 15 are recorded as
    structurally discharged).
- Rollback: full Phase-B rollback (B.6 rollback) if any gate fails.
- Yield: **boundary 35 → 20, by construction, verified.**

---

## PHASE C — Discharge the residual 20, seal the certificate, wire consumers, retire the old

### Step C.1 — Discharge the residual 20 (reachability, then cost)
- File: EDIT `STDLIB/iii/omnia/xii_discharge.iii` (extend `xdc_`).
- Operation: for each of the 20 `lift × non-assoc` pairs, attempt **route R**: prove the divergent
  overlap (a branch whose suffix an inner rule rewrites, breaking the lift's `struct_eq`) lies outside
  the image of `xii_canonicalise` — concretely, that a bottom-up walk reduces the branch's inner redex
  before the lift is tried, so the lift only ever sees already-normal branches (the overlap shape is
  non-normal-reachable). Where R cannot be shown, attempt **route C** (the two NFs extract to equal
  `numera/cost_lattice` representatives); record any residual as **boundary** with a §8 response tag.
  Export `xdc_route_of(k) -> u8` (S/R/C/boundary) and a per-pair proof handle.
- Gate: KAT ⇒ 99: every one of the 20 carries R, C, or an explicit boundary tag; prove-the-negative
  (a deliberately cost-divergent fabricated pair is graded boundary, never C); corpus FAIL=0;
  iiis-2 seal-neutral.
- Rollback: restore `xii_discharge.iii.bak`.

### Step C.2 — The sealed certificate object
- Files: CREATE `STDLIB/iii/omnia/xii_conf_cert.iii` (`xcc_`) + `STDLIB/corpus/PPP_xii_conf_cert.iii`
  + EDIT `build_stdlib.sh` MODULES + `run_corpus.sh` EXPECTED.
- Operation: assemble the certificate as a content-addressed witnessed object via `numera/cad`:
  - **rule-semantics mhash** = `cad` over the *behavioural* rule set, NOT the structural table — hash
    the `xii_rewrite` rule object bytes (or the manifest rule crystals) so a guard/RHS change is
    caught (ADR-C4). Export `xcc_rule_mhash(out_32)`.
  - the graded non-join partition (from `xdc_`), the per-pair proof tags, and the **confluence
    equivalence-class partition** (two rules share a class iff they have no overlap OR every pair
    between them joins; trit block = its own class by disjointness; R-discharged lift pairs place their
    rules per the discharge).
  - Export `xcc_verify(out_live_mhash) -> u8` (1 iff the sealed rule mhash equals a freshly computed
    live rule mhash) — the boot fast-path; and `xcc_reprove() -> u64` — the deep path that re-runs the
    grader+joinability and asserts the grades still hold (the Key-Move re-check; must agree with the
    seal).
- Gate: KAT ⇒ 99 (the cert verifies against the live rules; a fabricated rule-mhash mismatch ⇒
  `xcc_verify`==0; `xcc_reprove` agrees with the sealed grades); corpus FAIL=0; seal-neutral.
- Rollback: delete the two files; revert script edits.

### Step C.3 — nous: consume the equivalence classes; fix the over-claim
- File: EDIT `STDLIB/iii/nous/nous_policy.iii`.
- Operation: (a) reword the header — replace "certified-reorderable rules (R001–R044 + trit)" with the
  accurate "kind-aware block reorder: the LHS-disjoint trit block, freely movable, relative to the
  R-block whose cascade order is preserved (ADR-N11)"; (b) where the policy references the reorderable
  set, source it from `xcc_` equivalence classes (so an ADR-N2 within-class reorderer is constrained
  to permute within a class, never across — R001/R008 in different classes). Current block-swap
  behaviour is unchanged (it is already safe); this binds the *future* reorderer to proof.
- Gate: `nous_policy` selftest + the nous differential gate (`verify_nous_differential.sh`) green —
  behaviour unchanged, wording honest, equivalence-class source wired; corpus FAIL=0; seal-neutral.
- Rollback: restore `nous_policy.iii.bak`.

### Step C.4 — H12 charter clause body
- File: EDIT `STDLIB/iii/numera/h12_charter.iii`.
- Operation: extend the H12 clause to verify, as its bound fact, `xcc_verify(live) == 1` AND
  `xsd_strategy_is_deterministic() == 1` — i.e. "deterministic by fixed strategy (A.1) AND the
  confluence-core certificate's rule mhash matches the live rules (C.2)." Keep the verify-arm +
  falsify-arm + canary discipline (a deliberately wrong rule-mhash ⇒ the clause's falsify index).
- Gate: `h12_charter` corpus test (699 family) ⇒ 99; `run_charter` terminal gate (700) folds H12
  green; corpus FAIL=0; seal-neutral.
- Rollback: restore `h12_charter.iii.bak`.

### Step C.5 — Manifest carries the certificate; retire `xii_critpairs`
- Files: EDIT `STDLIB/scripts/build_stdlib.sh` (remove `"omnia/xii_critpairs"` from MODULES; the
  joinability gate is its honest replacement); DELETE `STDLIB/iii/omnia/xii_critpairs.iii` and any
  `STDLIB/corpus/*critpairs*.iii`; EDIT the manifest generator (`gen_xii_manifest.c`) to record the
  `xcc_` certificate mhash in place of the retired `CRY-XII-CONF-001` confluence crystal (if B.0 #3
  found the manifest carries that crystal).
- Operation: `ar d libiii_native.a omnia_xii_critpairs.iii.o`; rebuild.
- Gate: `build_stdlib.sh` FAIL=0 (xii_critpairs gone, nothing references it — grep confirms zero
  consumers first); `run_corpus.sh` + `run_xii_corpus.sh` FAIL=0; the manifest regenerates + its
  golden reseals cleanly; `verify_sha256_dedup.sh`-style absence check for xii_critpairs.
- Rollback: restore `build_stdlib.sh.bak` + `xii_critpairs.iii` (re-create from `*.bak`); rebuild.

### Step C.6 — Final whole-system gate
- Files: none (run everything).
- Gate (the definition-of-done, all green): `build_stdlib.sh` FAIL=0; `run_corpus.sh` FAIL=0;
  `run_xii_corpus.sh` FAIL=0; `xjn_nonjoin_count()`==20; every residual pair carries S(by-construction)
  /R/C/boundary; `xcc_verify`==1; `xcc_reprove` agrees; `run_charter` H12 green; the determinism chain
  resealed-or-seal-neutral and recorded; the deep re-prover wired (a CI hook calling `xcc_reprove`).
- Rollback: n/a (terminal verification).

---

## Ordering rationale (why this order has no room for error)

1. **Phase A before B** — bank the unconditional H12 floor and the grader while the engine is
   pristine; both are seal-neutral and reversible, so the risky phase starts from a *richer* known-good
   state (the grader already names the 15).
2. **B.0 before any B cut** — the enumeration converts every canonical-form dependency from unknown to
   classified; the cut cannot orphan a seal because every seal is on the re-derive list before it moves.
3. **B.4 (compile-check) before B.6 (build)** — errors are caught at compile, before the expensive
   reseal, per audit-before-rebuild.
4. **B.6 drift-decision is empirical** — B.0 predicts compiler-reach; B.6's iiis-2 hash *proves* it,
   and the plan branches on the proof, not the prediction.
5. **C after B** — the certificate (C.2) binds the *post-elimination* 45-rule mhash and grades only the
   residual 20, so it never seals a claim route S is about to invalidate.
6. **Retire `xii_critpairs` last (C.5)** — only after `xii_joinability`+`xii_conf_cert` fully subsume
   it, so the honest gate exists before the false one is removed.

## Risk register (each maps to a step's rollback)

| Risk | Step | Catch | Response |
|---|---|---|---|
| `make_fusion2` mis-canonicalises (wrong leaf order / lost leaf) | B.1 | B.1 invariant+multiset probe | restore `.bak` |
| A non-R001–R004 path builds left-nested (missed in obligation #1) | B.7 | corpus / joinability ≠ 20 | full Phase-B rollback; re-audit construction sites |
| Compiler embeds `.iii` XII (route S not seal-neutral) | B.6 | iiis-2 hash drift | reseal chain + update BOOT C twins (B.5) OR rollback if twins not handled |
| A Horizon/lattice golden was canonical-form-dependent, unlisted | B.0/B.6 | B.0 enumeration; B.6 golden reseal fails | add to B.5; if found late, rollback |
| Termination breaks on the 45-rule set | B.7 | `xtm_gate()`≠1 | rollback; the lex-triple should only *simplify* — investigate |
| A residual-20 pair is a true soundness hole | C.1 | grader tags it boundary | §8 response (eject / Tier-3 / widen-cost), recorded in the cert |
| Certificate binds the pattern table not semantics | C.2 | C.2 prove-the-negative (guard change undetected) | hash `xii_rewrite` behaviour, not `xii_rule_patterns` |

## Definition of done
Phase C.6 all-green: 20 graded boundary pairs, 15 structurally discharged, certificate sealed +
re-provable, H12 reads the calibrated sentence (`ARCH §10`), `xii_critpairs` retired, determinism
chain resealed-or-proven-neutral. The boundary the certificate draws is complete and accurate; the
engine claims exactly what it can witness.
