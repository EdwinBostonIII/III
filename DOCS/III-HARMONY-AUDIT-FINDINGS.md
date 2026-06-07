# III — Harmony / Interconnection Audit Findings (2026-06-06)

Read-only ultracode Workflow `iii-harmony-audit` (wf_f225c7cf-10f): 47 agents, ~3.5M tokens, 10
cross-module lenses over the **mature core** (kernel, XII, cad, SovVal, category/cost, charters,
federation, nous, ripples, novel-structure), adversarially refute-by-default verified. **37 candidates →
9 confirmed, 28 refuted.** The numera compression/resilient-data frontier was excluded (a concurrent
Claude session owns it this session — see "Environment" below).

## Environment at audit time (why work is sequenced the way it is)

A **second concurrent Claude session** is actively building + committing to this OneDrive-synced repo
(`_gate_full5.log`, cwd-marker `claude-2201`; commits `317c0a2`/`8dd29a3` resolving the carto export
collisions). Two agents racing on a OneDrive-synced `.git` + shared build outputs will corrupt refs and
contend on link-locks. Therefore, per the concurrent-writer playbook:
- **No racing aggregate builds** (`build_stdlib`/`build_iiisN`) and **no racing commits** to shared paths
  while the writer is active.
- **Disjoint NEW-FILE lane only**; gate each new module STANDALONE (compile + link against a `/tmp`
  SNAPSHOT of `libiii_native.a`, no `ar` mutation, no `iiis` rebuild).
- Any change touching the **trusted base** (`ccl.iii`/`typecheck.iii`) or requiring a **reseal** is
  DEFERRED until `ps` shows the writer cleared.

The BV64/K4 wave is already committed (safepoint `81b51d7`, now ancestor of the writer's HEAD `8dd29a3`)
and authoritatively green per `DOCS/III-BV64-KERNEL-MODEL.md` (build 478/0, corpus 815/0).

---

## FINDING 0 — RETRACTED (false alarm; refuted by codegen test 2026-06-06)

> **RETRACTION.** A direct codegen probe (`/tmp/divprobe.iii` compiled by the pinned `iiis-2`, then
> disassembled) shows iiis-2 emits **unsigned `div %rcx`** (REX.W `48 f7 f1`, **no `cqto`/`idivq`**) for
> u64 `/`. The probe ran **exit=1**: `0xFFFF..FE / 0xFFFF..FF = 0` (unsigned) and a faithful replica of
> `ccl.iii:579`'s exact logic, `ovf_probe(0xFFFFFFFFFFFFFFFF, 2)`, **correctly returned overflow=1**.
> Therefore **`ccl.iii:579` is SOUND** and the `cost_lattice.iii:125-131` comment claiming a signed-`idivq`
> miscompile is **STALE** (the trap, if ever real, no longer reproduces under the current K4-sign-rigor
> compiler). The workflow's FINDING 0 rested on that comment and a *circular* verifier (it confirmed by
> reading the same comment). **Lesson: test the emitted binary; never trust a compiler-trap claim from a
> source comment.** The original (now-false) claim is struck through below for the record.

~~**The BV64 CIC kernel's `BVMULOVF` iota uses a miscompiled u64 division — it proves FALSE
overflow-safety facts.**~~ (FALSE — see retraction above.)

- `numera/ccl.iii:579` (inside the sealed trusted base): `if (prod / va) != vb { return ccl_true_c() }`.
- `numera/cost_lattice.iii:125-131` documents the exact trap: **iiis-2 miscompiles u64 `/` as a SIGNED
  `idivq` (`cqto; idivq`)**, so a dividend with bit 63 set is treated as negative.
- **Worked counterexample:** `bvmulovf(0xFFFFFFFFFFFFFFFF, 2)` → `prod = 0xFFFFFFFFFFFFFFFE` (bit 63 set);
  signed `(-2)/(-1) = 2 == vb` → returns `ccl_false_c()` ("no overflow") when it genuinely overflows.
  The kernel certifies a **false** machine-arithmetic fact.
- **Why missed:** the originating BV64 soundness audit (17 agents) and my own line-by-line `ccl.iii` audit
  both verified the iota **math** (`(prod/va)!=vb` is the correct overflow test mathematically) but not the
  **codegen** of the division on iiis-2. The current corpus (`1213`/`1214`) does not exercise a
  `bvmulovf(MAX, k)` case where `prod` has bit 63 set, so it is **uncaught** (corpus stays 815/0 green).
- **Fix (when writer clears):** `@export` `cl_mul_ovf` from `cost_lattice.iii`; extern it in `ccl.iii`
  (which already externs `cl_le_product` from cost_lattice at `ccl.iii:91`); replace the `(prod/va)!=vb`
  branch in `ccl_bv_fold`'s BVMULOVF arm with `cl_mul_ovf(va, vb, &scratch)`; add a `1213_bv_kernel`
  negative arm `bvmulovf(0xFFFFFFFFFFFFFFFF, 2) == true` (RED before, GREEN after). Edits the trusted base →
  `build_iiis2 --check-corpus` reseal + full corpus + the BV KATs mandatory before declaring done.
- **Status:** RETRACTED — no fix needed; `ccl.iii:579` is sound. cost_lattice's divide-free
  `cl_mul_ovf`/`cl_udiv` are now-redundant-but-correct (a low-priority *cleanup*, NOT a bug).

---

## Confirmed harmony compounds (ranked)

Legend: **[SAFE-NOW]** = disjoint NEW module, standalone-gateable now; **[NEEDS-CLEAR]** = edits an
existing/sealed module or needs a reseal → wait for the writer.

| # | Pri | Title | Modules | Lane |
|---|-----|-------|---------|------|
| 0 | ~~74~~ | ~~BVMULOVF divide-free overflow fix~~ — **RETRACTED** (codegen test: u64 `/` → unsigned `div`; ccl.iii:579 sound) | — | N/A |
| 1 | 74 | H4 + XII-rule **semantic** soundness fold (`H4_KIND_RULE_SOUND`) | h4_charter ⊗ xii_rule_verify | [NEEDS-CLEAR] |
| 2 | 58 | **`certified_morphism.iii`** — proof-gated morphism admission (arrow enters category only if a CIC-kernel proof clears `tc_check`, registered in theorem_commons by content-address) | category ⊗ typecheck ⊗ theorem_commons | **[SAFE-NOW]** |
| 3 | 50 | **`tp_planner.iii`** — Pareto-frontier format-transform planner (BFS over the tp_* morphism graph; non-dominated routes by composed 6-vector cost) | tp_morphism ⊗ category ⊗ pareto_extraction ⊗ cost_lattice | **[SAFE-NOW]** |
| 4 | 50 | **`ripple_journal.iii`** — content-addressed, order-sealed run-history for the ripple optimizer (rn_publish each move crystal; order-sensitive Merkle run-root; resolve-by-address) | ripple ⊗ ripple_synthesizer ⊗ cad | **[SAFE-NOW]** |
| 5 | 42 | **`costed_cat.iii`** — sequentially-accumulating (saturating-add) cost on category composition + over-budget refusal + cost-in-content-address | category ⊗ cost_lattice ⊗ cad | **[SAFE-NOW]** |
| 6 | 34 | hotstuff BFT block hash → `cad_oneshot` + tamper-evidence KAT | hotstuff ⊗ cad | [NEEDS-CLEAR] |
| 7 | 32 | `bkey_discover` — XII-complete behavioral-lemma discovery (replaces bounded ntm_joins oracle) | nous_behavioral_key ⊗ nous_conjecture_lemma ⊗ xii_canonicalise | [NEEDS-CLEAR] (nous lane, separate runner) |
| 8 | 30 | H8 falsify-arm independence (pre-redaction is-NOT-redacted check) | h8_charter ⊗ witness_hook | [NEEDS-CLEAR] |

**Note (second division-trap site):** candidate #5's analysis also flags `cost_lattice_synth.iii:190`
(`prodraw / CLS_K_FP_ONE`) as carrying the same u64-division miscompile — to verify + fix in the
post-writer-clear trusted-arithmetic sweep alongside FINDING 0.

## Refuted (28) — rigor evidence (representative)

The verifiers were genuinely adversarial; the strongest refutation patterns:
- **byte-identical `cad_oneshot` reroutes** (census/smt/fed_eclipse/hexad_reach): `cad_oneshot(SHA256)` ≡
  `sha256_oneshot`, so the routing changes no byte — cosmetic; the only real gain (a tamper KAT) is
  independent of the routing and several were uncompilable (private non-exported vars).
- **already-implemented**: REACH∧LEK conjunction (`p5_kat_mig2_cert`), BVADDOVF certification (`tc_bv_kat`),
  cat_compose_xii (`cat_add_morphism_xii` + `xii_term_make_fusion2`), cost-based equivalent selection
  (`egraph.iii eg_extract` + `optinvoke oi_select_costed`).
- **API-mismatch vapor**: every `sv_*` SovVal-witness candidate — `sv_make` recomputes the witness as
  `cad(payload‖hexad‖cost)` and takes no external witness, so "witness == external addr" is structurally
  impossible.
- **misunderstood primitive**: `cat_pullback` is a universal-cone SEARCH over registered arrows, not a BFT
  agreement decision.

## Execution plan

1. **NOW (disjoint, standalone-gated):** #2 `certified_morphism.iii` → #4 `ripple_journal.iii` → #3
   `tp_planner.iii` → #5 `costed_cat.iii`. Each: new module + falsifiable KAT (positive + negative arms),
   compile + link vs a `/tmp` snapshot of `libiii_native.a`, commit explicit paths only.
2. **WHEN WRITER CLEARS (`ps` quiet):** charter folds #1 (H4), #8 (H8); then #6 (hotstuff cad).
   (FINDING 0 RETRACTED — no trusted-base fix; the `cost_lattice_synth.iii:190` "second site" is the same
   now-stale division concern, verify-only.) Wire all new modules into `build_stdlib` MODULES +
   `run_corpus` EXPECTED; run the full gate (build_iiis0-3 + build_stdlib FAIL=0 + corpus + xii + nous +
   seam + structural); reseal; commit.
