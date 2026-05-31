# III Structural Audit — Plan Part 5 · Wave 5 (de-deferred forge/frozen passes) + Wave 6 (seal-gated compiler)

> **AUDIT STATUS (2026-05-30):** **Wave 5 ✅ INTEGRATED** — W5.1 census OOB + forge reseal
> (K3 `cca70c89…`, descent root `b21588fb…`); W5.2 the Keccak manifest tool BUILT
> (`forge_keccak_driver.iii` + `forge_manifest_keccak.sh`, level-D root `830164ae…` recorded +
> gated); W5.3 seal_resolver refrozen (6 coefficient rows corrected, ADR-RES-009-A, corpus 951);
> W5.4 doc-confirmed. All green in `build_stdlib` 429/0 + `forge_manifest_keccak` OK.
> **Wave 6 ⛔ NOT INTEGRATED** — the seal-gated `build_iiis2` compiler pass (W6.1 @specialize
> sign-ext, W6.2 cg_r3 CUT-9, W6.3 sema hash-index, W6.4 cg_rm2, W6.5 reseal) is unimplemented;
> it moves the golden BARE hash and overlaps the user's live cg_r3 work. Boxes left unchecked.


> Read `-PLAN-00-DOCTRINE.md` + `-VERIFICATION.md` first. **This is the part that eliminates every
> deferral** (doctrine §4) and performs the seal-gated compiler edits **last**. The forge tools pin
> determinism (`LC_ALL=C`, `LANG=C`, `TZ=UTC0`, `SOURCE_DATE_EPOCH=0`, sorted seals — verified in
> `COMPILER/BOOT/forge_check.sh:26-29,97`). Where the audit said "deferred / leave it / not cleanly
> recomputable in toolset," the surpass-only resolution below is to **do the work, and where a tool
> is missing, build it** — never route around the obstacle.

---

# Wave 5 — The de-deferred forge-closure & frozen-spec passes

## W5.1 · `census` out-of-range spurious match — forge-closure reseal (RIPPLE-11 / KEEP-2) [HOLDS · FORGE_CLOSURE · deferral eliminated]

**Verified:** HOLDS. `katabasis/census.iii katabasis_census_fact_matches:63-70` lacks an index bound:
`fact_matches(16, 0)` → `census_fact(16)` returns `0u64` (the OOB masking zero, `:53-58`) → `f==v` →
`0==0` → spurious `1u8` (MATCH instead of drift). The fix is a **hand-edit** (the function is
**outside** the `BEGIN/END AUTO-GENERATED` block, so `gen_census.sh --check` does not drift). The
closure recompute tool is `COMPILER/BOOT/forge_check.sh` (`--print` recomputes level B per-citizen
seal `sha256(def||gen||census.iii||corpus603)` and level C descent root `sha256(sort(K1..K6 seals))`).
`ring_lattice` is already fixed (K6 root `77a631…`). **Key correction:** the "Keccak manifest top
root not cleanly recomputable in toolset" is because that level **does not exist as code yet** (ledger
F0 scaffold, rows 1-6 unsealed) — not because it is intractable. Per the mandate, building that tool
is a scheduled task (W5.2), not an excuse.

**Files:** `katabasis/census.iii` (`fact_matches`), `corpus/603_katabasis_census.iii` (add falsifier),
`COMPILER/BOOT/forge_check.sh` (recompute, `--print`), `DOCS/SOVEREIGN-LEDGER.md` (K3 row + descent
root). Seal class: **FORGE_CLOSURE** (levels B+C now; level D in W5.2).

- [ ] **Step 0 — Pre-state capture (read-only):** `bash COMPILER/BOOT/forge_check.sh` → must print OK
  with descent root `0330cab1e2189e63b7e111fa7ac9821be914ed6669f752ee050c7c174e77d2fb`. Record it +
  the current K3 seal.
- [ ] **Step 1 — Falsifier KAT first** in `corpus/603_katabasis_census.iii` (the negative arm the
  current KAT lacks): `if katabasis_census_fact_matches(16u64, 0u64) != 0u8 { return 18u64 }` and
  `if katabasis_census_fact_matches(16u64, 1u64) != 0u8 { return 19u64 }`. Build + run; confirm it
  **FAILS** today (the OOB-with-value-0 case returns a spurious 1).
- [ ] **Step 2 — Code fix (hand-edit, outside the AUTO-GENERATED block):** in
  `katabasis_census_fact_matches`, before the `let f` line, insert
  `if i >= katabasis_census_fact_count() { return 0u8 }` (single-source-of-truth on the count, which
  `gen_census.sh:99-101` already pins; or the literal `16u64` mirroring `census_fact`). Now an
  out-of-range index can never match regardless of measured value — the gate can say *no*.
- [ ] **Step 3 — Rebuild + behaviour verify:** `bash STDLIB/scripts/build_stdlib.sh` (expect
  `FAIL = 0`; `gen_census.sh --check` stays green — edit is outside its block); `bash
  STDLIB/scripts/run_corpus.sh` → `603`=99 incl. the new negative arms.
- [ ] **Step 4 — Recompute levels B+C and reseal:** `bash COMPILER/BOOT/forge_check.sh --print` →
  read the new K3 full-spec seal (the consumer `census.iii` + the edited `corpus603` both feed it) and
  the new SHA-256 descent sub-closure root. Update the K3 row and the "Current closure" descent-root
  line in `DOCS/SOVEREIGN-LEDGER.md` to the printed values. Re-run `forge_check.sh` (no `--print`) →
  must print OK against the updated ledger (the RED-until-resealed gate is now GREEN).
- [ ] **Step 5 — Confirm the gate fires both ways:** `subsystem_test_gate.sh` GREEN; a throwaway
  revert of the census edit must redden `forge_check` (proves the closure binds the source). Restore.
  Commit: `fix(census): RIPPLE-11/KEEP-2 close OOB spurious-match + falsifier; reseal forge levels B+C (K3 + descent root) — deferral eliminated`.

## W5.2 · Build the Keccak manifest closure-root tool (RIPPLE-11 level D) [FORGE_CLOSURE · the missing tool]

**Verified:** the Keccak manifest top-root "is not cleanly recomputable in toolset" because **the
recompute step does not exist** (`subsystem_test_gate.sh:78-86` only invokes the SHA-256 `forge_check`;
ledger says the Keccak level "remains uncomputed while citizens rows 1-6 are unsealed, scaffold stage
F0"). **Surpass-only (build the tool, do not defer):** implement the Keccak manifest closure-root
recompute as a hand-rolled step over the existing `numera/keccak.iii` (NIH — no new dep), so the third
closure level becomes a live, recomputable gate the moment rows 1-6 are sealed.

**Files:** new `COMPILER/BOOT/forge_manifest_keccak.sh` (or extend `forge_check.sh`), wire into
`subsystem_test_gate.sh`; `DOCS/SOVEREIGN-LEDGER.md` (manifest root row). Seal class: **FORGE_CLOSURE**.

- [ ] **Step 1 — Specify the manifest root exactly:** Keccak-256 over the sorted set of the six
  citizen seals (the same level-C input the SHA-256 descent root uses) — define the byte order +
  separator to match the descent-root convention (sorted, `LC_ALL=C`, no trailing newline), so the
  two levels are consistent.
- [ ] **Step 2 — Implement the recompute** using the in-tree Keccak (`keccak256_oneshot` via a tiny
  driver, or a shell pipe to a `keccak256` built from `numera/keccak.iii`). Pin determinism
  (`LC_ALL=C/LANG=C/TZ=UTC0/SOURCE_DATE_EPOCH=0`). Add a `--print` mode mirroring `forge_check.sh`.
- [ ] **Step 3 — Falsifier:** flipping one citizen seal must change the manifest root (and redden the
  gate); a throwaway edit proves it. Restore.
- [ ] **Step 4 — Wire into `subsystem_test_gate.sh`** as the third closure level (after `forge_check`'s
  SHA-256 descent root); record the manifest root in the ledger. Now editing any forge citizen
  recomputes **all three** levels in one pass — the half-sealed-manifest hazard is structurally
  impossible. Commit: `feat(forge): RIPPLE-11 build the Keccak manifest closure-root recompute tool (level D now live; no more uncomputable top root)`.

## W5.3 · `seal_resolver` coefficient table — frozen-spec refreeze (KEEP-1) [DRIFTED · FROZEN_SPEC · deferral eliminated]

**Verified:** DRIFTED on path — the file is **`STDLIB/iii/sanctus/seal_resolver.iii`** (not katabasis).
The coefficient byte array **is** the frozen seal definition (ADR-RES-009, FROZEN); its decoded values
do not match ADR-RES-009's documented magnitudes (and ADR-RES-001 says the seal hashes
`omnia/resolver.iii`'s source bytes, which the implementation does not). **Surpass-only (the refreeze
*is* the step, "do not edit as code" means "edit via the ADR channel"):** author the superseding ADR,
recompute the correct coefficient bytes, reissue the seal, update dependents, re-verify.

**Files:** `STDLIB/iii/sanctus/seal_resolver.iii` (coefficient table), a new ADR superseding
ADR-RES-009 (and reconciling ADR-RES-001), the seal-issue tool, dependents. Seal class: **FROZEN_SPEC**.

- [ ] **Step 1 — Decide the canonical truth:** determine whether the *bytes* or the *documented
  magnitudes* are correct (read ADR-RES-009 + ADR-RES-001 + the resolver seal derivation). Whichever
  is canonical, the other is corrected to match. Resolve the ADR-RES-001 claim ("seal hashes
  `resolver.iii` source bytes") against the implementation — they must agree post-refreeze.
- [ ] **Step 2 — Author the superseding ADR** (`ADR-RES-009` → successor): state the corrected
  coefficient definition + the corrected seal-derivation, mark ADR-RES-009 Superseded.
- [ ] **Step 3 — Recompute the coefficient bytes** per the new ADR; replace the frozen array in
  `seal_resolver.iii`.
- [ ] **Step 4 — Reissue the seal + update dependents;** add a manifest-verify KAT asserting the
  reissued seal matches the new ADR's derivation (falsifier: a coefficient byte flip → seal mismatch).
- [ ] **Step 5 — Re-verify** the resolver corpus + the seal gate GREEN. Commit: `spec(seal_resolver): KEEP-1 ADR-RES-009 successor — refreeze the coefficient table + reissue the seal (deferral eliminated, edited via the ADR channel not as code)`.

## W5.4 · KEEP-3 — the golden bootstrap hashes (documented, not actioned) [HOLDS · GOLD]

**Verified:** HOLDS; the directive is justified. Correction: strike "the per file mhashes" — there are
**no per-source-file mhash artifacts**; the seal is the golden BARE hash of the compiler binary
(`COMPILED/iiis-2.exe` + `.mhash` + `.witness.json`), reset only as the *output* of `build_iiis2`.
- [ ] **No code action.** Ensure doctrine §2 (GOLDEN_SEAL row) and the audit's KEEP-3 carry the
  corrected wording, so a future reader sweeping for "magic constants" never hand-edits these. The
  only way they move is Wave 6's `build_iiis2` reseal. (Already patched into the audit's verification
  banner + this plan.)

---

# Wave 6 — The seal-gated compiler pass (LAST, one dedicated `build_iiis2`)

> **RIPPLE-10 discipline:** any edit under `COMPILER/BOOT/*.iii` drifts the iiis-2 seal and must pass
> the seal-gated `build_iiis2` (byte-equivalence on `stage1_corpus`, then reseal to the golden BARE
> hash). Do these **together, last**, in one reseal so the golden hash moves exactly once. The
> determinism gate decides the reseal — never hand-edit `.mhash`. **RIPPLE-10 correction:** `B-LDIL-1`
> (xii_ldil STORE typecheck OOB) was misattributed to COMPILER/BOOT — it lives in `STDLIB/iii/...`, so
> it is a **STDLIB_GATE** fix and is **not** part of this bootstrap pass (do it in Wave 3 timing).

## W6.1 · `@specialize` sign-extension / stride at the codegen site (RIPPLE-9) [HOLDS · BOOTSTRAP_SEAL]

**Verified:** HOLDS (defect confirmed in machine code). For signed element types the generic
specialization widens by sign-extension, so a shift-based tagged payload fails to recover negatives
(J-RESULT-1 in `result`, J-ITER-4 in `iter`, plus a stride default, X20). Fix once at the
specialization codegen site → a whole family of latent container bugs closes. Note: `J-ITER-4` is the
bundled `J-ITER-1..5` set, not a standalone id.
- [ ] **Step 1 — Falsifier KATs first (STDLIB, run before the compiler edit):** a `@specialize`d
  signed `result`/`iter` storing and recovering a **negative** value (today fails); a stride round-trip
  KAT (today wrong stride). These live in `STDLIB/corpus` and FAIL against the current iiis-2.
- [ ] **Step 2 — Fix the widening at the specialization codegen site** (`COMPILER/BOOT`, Grep
  `@specialize`/`R3_SPEC`/the widening): use the element type's signedness to choose sign- vs
  zero-extension and the correct stride. (Recall the prior `@specialize *T` stride bug class — assert
  byte layout, do not rely on single-index round-trips.)
- [ ] **Step 3 — Seal gate:** `build_iiis2` (the reseal) — see W6.5. The STDLIB falsifier KATs now
  pass against the resealed compiler.

## W6.2 · `cg_r3` dead bookkeeping (CUT-9) + the `cg_r3` split question (SEPARATE-4) [BOOTSTRAP_SEAL]

**Verified:** CUT-9 HOLDS (`DEAD-D7-1` duplicate-label gate, `DEAD-STACK-1`
`R3_G_MAX_STACK_DEPTH` dead — `cg_r3.iii` now 3546 ln). SEPARATE-4 HOLDS but **low-confidence** —
listed as a candidate to revisit, not a mandate; `cg_r3` is inherently large and otherwise clean.
- [ ] **CUT-9** — confirm dead by tree-wide + disassembly ref check (it is a sealed file — verify in
  the binary, not just source, per the CRASH protocol spirit); delete `DEAD-D7-1`'s duplicate-label
  gate and `DEAD-STACK-1`; **or** wire `R3_G_MAX_STACK_DEPTH` if it was meant to bound stack depth
  (decide explicitly — it is dead either way until decided).
- [ ] **SEPARATE-4** — **decline the split** unless maintenance friction demands it (the verification's
  recommendation: low-confidence, the file is otherwise clean, codegen is inherently large). Record the
  decision explicitly so it is not a lingering "maybe." If pursued later, split the PCC self-attestation
  (PCC-1, confirmed-correct SHA-256 emit witness) from the lowering concern (MATCH-SLOT-1) — but only
  behind the same `build_iiis2` gate.
- [ ] **Seal gate:** rides W6.5.

## W6.3 · `sema` hash-index + Aho-Corasick (G-SEMA-1/2, the COMBINE-3/ENHANCE-10 compiler consumers) [BOOTSTRAP_SEAL]

**Verified:** the `sema` name-resolution O(N²·L) → hash-index (G-SEMA-1) and the opcode scan →
Aho-Corasick (G-SEMA-2) are the COMPILER/BOOT consumers of the Wave-0 content-address-index idea.
**RIPPLE-10 note:** even an *output-identical* optimization "still changes `sema.iii` source, so still
gate via `build_iiis2`" — the seal covers source identity.
- [ ] **Step 1 — Falsifier/equivalence KAT first (STDLIB corpus):** name-resolution on a large symbol
  set returns **identical** resolutions to the current O(N²·L) scan (byte-identical), and the
  Aho-Corasick opcode scan matches the current scan on a fixed opcode stream. FAIL first only if the
  current behaviour is wrong; otherwise these are equivalence guards.
- [ ] **Step 2 — Implement the hash index in `sema.iii`** (reuse the W0.2 `caindex` *design*; the
  compiler may need its own copy if it cannot link the STDLIB organ — keep it byte-for-byte the same
  algorithm) and the Aho-Corasick opcode scanner.
- [ ] **Step 3 — Seal gate:** rides W6.5. The resolutions must be byte-identical (the corpus
  byte-equivalence on `stage1_corpus` is the proof).

## W6.4 · Any remaining genuinely-BOOTSTRAP_SEAL items (`cg_rm2`, etc.) [BOOTSTRAP_SEAL]

**Verified:** RIPPLE-10's named compiler items: `cg_rm2` (C9 digit-corruption-class), and any other
`COMPILER/BOOT` finding confirmed bootstrap-sealed (NOT `B-LDIL-1`, which is STDLIB). Batch all
remaining BOOTSTRAP_SEAL edits here so the golden hash moves once.
- [ ] Gather every confirmed `COMPILER/BOOT/*.iii` edit from W6.1-W6.3 + `cg_rm2` into one changeset.
- [ ] Seal gate: W6.5.

## W6.5 · The one dedicated `build_iiis2` reseal [BOOTSTRAP_SEAL · the wave's closer]

- [ ] **Step 1 — Pre-state:** record the current golden BARE mhash (`COMPILED/iiis-2.exe.mhash`).
- [ ] **Step 2 — Run the seal-gated build:** `bash COMPILER/BOOT/build_iiis2*.sh --check-corpus`
  (the seal gate): it must (a) byte-equivalence-check `stage1_corpus` (iiis-1 vs iiis-2 outputs), then
  (b) reseal to the new golden BARE hash. **Let the gate decide the reseal** (DRIFT-driven, ADR-027) —
  never hand-edit the `.mhash`.
- [ ] **Step 3 — Verify the gate catches breakage:** confirm a deliberately broken codegen edit
  reddens the corpus byte-equivalence (the gate's negative arm — proven previously at
  `iii-safepoint-T6.4`); restore.
- [ ] **Step 4 — Full corpus GREEN:** `run_corpus.sh` all PASS incl. the W6.1/W6.3 STDLIB falsifier +
  equivalence KATs; capture the new golden BARE mhash + `.witness.json`. Commit (one commit for the
  whole compiler pass): `feat(compiler): Wave-6 RIPPLE-9/CUT-9/G-SEMA-1/2/cg_rm2 — seal-gated build_iiis2 reseal (golden hash moves once; stage1_corpus byte-equivalent)`.

---

### Wave-5/6 completeness check — and the deferral-elimination ledger
**Every deferral the audit contained is now a scheduled, executable task:**
| Audit deferral | Eliminated by | Mechanism |
|---|---|---|
| RIPPLE-11 / KEEP-2 — census "leave it until a forge reseal pass" | W5.1 | hand-edit + falsifier + `forge_check.sh --print` reseal of levels B+C |
| RIPPLE-11 — Keccak top root "not recomputable in toolset" | W5.2 | **build** the missing Keccak manifest recompute tool (NIH, over `keccak.iii`) |
| KEEP-1 — seal_resolver "spec-level refreeze, not a code edit" | W5.3 | author the superseding ADR + reissue the seal (the refreeze *is* the step) |
| KEEP-3 — golden hashes "do not touch" | W5.4 / W6.5 | documented; they move only as `build_iiis2` output |
| ENHANCE-15 — transform slots "design decision per slot" | PLAN-3-adjacent / doctrine §4 | build the **real** transform per slot (relabel rejected) |
| CUT-16 — "forward looking, decide the question" | PLAN-4 W4.5 | decided: keep (live caller) + coverage KAT |
| SEPARATE-2 — confluence "B18d future step" | PLAN-2 W2.3 | CCL-native exhaustive critical-pair enumerator + falsifier |
| SEPARATE-3 — "parks work in ENHANCE-4" | PLAN-3 W3.8 | wire `cc_evaluate` now (no parking) |

No deferral survives. The compiler edits are batched into one seal-gated reseal (Wave 6), done last.
This completes the five-wave program. **The plan is closed by the final verification pass below.**
