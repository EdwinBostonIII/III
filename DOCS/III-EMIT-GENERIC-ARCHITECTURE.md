# III — emit_generic: The Ring-Agnostic Emitter (ADR-C4-REVISED)

**Frontier item 1 of 2.** Apotheosis §C.4's "one ring-agnostic emitter." This document is the
measured, falsified-premise-corrected architecture + the live campaign ledger. Authored 2026-06-03.

## 0. The premise the apotheosis got wrong (falsified empirically)

§C.4 claims: *"the four codegens differ only in register table / calling convention / reserved ranges /
opcode encoding — their `emit_block/emit_stmt/emit_expr/emit_opcode` logic is identical … cg_r3 serves
all rings by auto-detect … ~970 lines of duplicated emit bodies deleted from cg_r3 alone."*

**Measured reality (read the bodies, 2026-06-03):**
- `main.iii` `iii_ring_autodetect` dispatches `cg_<ring>` — all four codegens are **live consumers**, not
  a single auto-detecting cg_r3. The "cg_r3 serves all rings" claim is false.
- The four are **tiered**, not flat-identical:
  | ring | file | lines | lowering | status |
  |------|------|-------|----------|--------|
  | R3  | cg_r3.iii  | 3556 | ~610 lines, **richest** (all AST kinds) | LIVE (every normal program) |
  | R0  | cg_r0.iii  | 1398 | ~300 lines, **subset** of R3 | LIVE (Windows kernel .sys via KATABASIS) |
  | R-1 | cg_rm1.iii | 792  | ~60 lines sanctum + 2429-line HV table emitter | wired, **no consumer program** |
  | R-2 | cg_rm2.iii | 591  | ~60 lines sanctum | wired, **no consumer program** |
- `rm1` and `rm2` lowering (`emit_block/stmt/expr/assign/call`) is **structurally identical** — differs
  only in emitted constants: label prefix (`L_hv_` vs `L_sanctum_`), header comment, one CMP const.
- `r0` lowering is a **proper subset** of `r3` (kernel needs fewer AST kinds), not identical.

**Corrected thesis:** the shared substance is the **AST-walk + dispatch skeleton**; the differences
(register table, label prefix, header, ABI, sanctum cap-revoke, entry emission, opcode detail,
*which AST kinds are handled*) hoist into a `ring_config`. The honest deliverable is a **tiered**
config-parameterized emitter that reproduces every ring's bytes — NOT a forced flat "4→1, 970 lines"
(that number rests on the false premise).

## 1. The safety net (built FIRST — the corpus gate is vacuous for non-R3)

`--check-corpus` is **self-consistency** (iiis-1 ≡ iiis-2), and stage1_corpus is **R3-only** — so it
proves *nothing* about r0/rm1/rm2, exactly where the cleanest dedup lives (VACUOUS-GATE MAP, confirmed).
A structural dedup also changes the compiler *binary* (mhash drifts → reseal) even when output-preserving,
so output-preservation needs a **differential** gate: baseline-iiis-2 output ≡ new-iiis-2 output.

**Differential anchors captured from `COMPILED/iiis-2.exe.emitgen-baseline` (mhash `8b205524…`):**
- **R3**: `/tmp/egbase/r3/*.o` — 59 stage1_corpus `.o` (66,594 B) + the 721-test corpus + `--check-corpus`.
- **R0**: `/tmp/egbase/r0/*.s` — 24 real kernel sources (4 drivers + 20 stdlib MODS), 37,434 asm lines.
- **R-1**: `/tmp/egbase/rm1_sample.s` — rm2_sample via `--ring R-1`, 2,429 lines (HV path).
- **R-2**: `/tmp/egbase/rm2_sample.s` — rm2_sample via `--ring R-2`, 132 lines, **+ `check_rm2.sh`**
  runtime gate (`do_thing(7)==21`, passes on baseline).

## 2. The architecture — `ring_config` + `emit_generic`, built incrementally

- `ring_config.iii` (**NEW**): `ring_cfg` accessors — register table, label prefix, header bytes, ABI
  flags, sanctum-mode (cap-revoke required), opcode detail, AST-kind coverage. One config per ring.
- `emit_generic.iii` (**NEW**): the ONE `gen_emit_block/stmt/expr/assign/call`, parameterized by the
  active `ring_cfg`, reproducing each ring's exact bytes.
- `cg_<ring>.iii` (**REFACTOR**): keep ring-specific **entry emission** (+ rm1 HV tables, r0 DriverEntry,
  r3 staged pipeline) and the ring's config; **delegate lowering** to `emit_generic`.

**Build order (each step differential-gated before the next):**
1. **Tier A — sanctum pair (rm1/rm2):** the cleanest. Extract shared sanctum lowering into `emit_generic`
   under `sanctum` config (label-prefix/header/CMP as config). Gate: R-2 `.s` differential + `check_rm2.sh`
   + R-1 `.s` differential. *Proves the methodology on the provably-identical case.*
2. **Tier B — r0 folds in:** add the R0 config (kernel ABI, AST-kind subset). Gate: 24-source R0 `.s`
   differential.
3. **Tier C — r3 folds in (the host):** add the R3 config (full coverage). Gate: stage1 `.o` differential
   + `--check-corpus 59/0` + full 721 corpus.

## 3. Proof obligations (ALL required; conflating them = a vacuous green)

- **Self-consistency:** `build_iiis2.sh --check-corpus` = 59/0 (fixed point holds).
- **Output-preservation (the real gate):** for every ring, baseline `.s`/`.o` **byte-≡** new `.s`/`.o`
  on its differential anchor. A single differing byte = the dedup changed emission = STOP.
- **Runtime:** `check_rm2.sh` `do_thing(7)==21`; full corpus green.
- **Reseal:** the compiler binary changed (structure) but its output did not — a deliberate, differential-
  proven mhash reseal (ADR-027), NOT an output change.
- **Falsifiability:** a deliberate `emit_generic` perturbation must redden a differential anchor
  (demonstrated per tier).

## 3a. Tier A — the sanctum merge, precise design (verified 2026-06-03)

**Build mechanics (verified):** `cg_r0/cg_rm1/cg_rm2` are all in `PORTED_TUS` (both build_iiis1.sh and
build_iiis2.sh) — their `.iii` IS the live compiler (the `.c` seeds are excluded via `PORTED_RE`). A new
shared module must be ADDED to `PORTED_TUS` in both scripts (no `.c` to exclude). `build_iiis2.sh` already
runs `check_rm2.sh` in-build (lines 260-267) → the R-2 gate is wired into the reseal. Refactoring the
`.iii` drifts iiis-1/iiis-2 mhash (→ reseal) but NOT iiis-0 (from `.c`, untouched). The `.c` seeds stay as
frozen bootstrap (apotheosis C.4 scopes the `.iii`); a separate later task may unify them.

**The differential gate (durable, validated):** `COMPILER/BOOT/emit_gen_diff.sh <bin> <outdir>` regenerates
all 4 rings' codegen output (R0=24 kernel `.s`, R-1/R-2 rm2_sample `.s`, R3=59 stage1 `.o`) for any
compiler. Proof: `bash emit_gen_diff.sh COMPILED/iiis-2.exe.emitgen-baseline /tmp/eg_base` then after each
step `bash emit_gen_diff.sh COMPILED/iiis-2.exe /tmp/eg_new && diff -r /tmp/eg_base /tmp/eg_new` MUST be
empty. Validated 2026-06-03: deterministic (0 diffs, 39,995 asm lines + 59 `.o`) + falsifiable (catches a
1-line tamper). Baseline binary `COMPILED/iiis-2.exe.emitgen-baseline` (mhash `8b205524…`) is the anchor.

**Design — `emit_sanctum.iii` (NEW), shared by cg_rm1 (R-1 HV) + cg_rm2 (R-2 sanctum):**
- **Shared** (written once): the ~120 byte-identical instruction constants (`SV_STR_MOVQ`/`ADDQ`/regs/…),
  the sanctum state (`SV_G_AST/LOCAL_COUNT/STACK_DEPTH/…` replacing `RM{1,2}_G_*`), the helpers
  (`sv_cg_emit_*`, `sv_local_*`, `sv_push_rax`, `sv_pop_reg`, `sv_emit_load/store_slot`, `sv_emit_mangled`,
  `sv_emit_section_text`, …), the lowering (`sv_emit_expr/stmt/block/assign/call`), the entry
  (`sv_emit_function`) — all config-driven.
- **Config** (module globals the per-ring `create` sets): `SV_CFG_MANGLE_PFX{,_LEN}` (`L_hv_`/`L_sanctum_`),
  `SV_CFG_SEC_TEXT_PE/ELF`, `SV_CFG_SEC_RODATA_PE/ELF`, `SV_CFG_HDR1/HDR2`, `SV_CFG_PFX_{FORTOP,FOREND,
  FORCONT,MATCHEND,SKIP,STR,MHASH}` — the only places rm1/rm2 bytes differ (prefix/section/header/labels).
- **cg_rm2.iii** → thin: keep the RM2-specific label/section/header constants + `iii_cg_rm2_create`
  (points `SV_CFG_*` at them, `SV_MODE=sanctum`) + run/finish/error; delete the duplicated lowering+vocab.
- **cg_rm1.iii** → keep the RM1-specific constants + the 2429-line HV table emitters (`rm1_hv_*`) + create
  (points `SV_CFG_*` at RM1 constants, `SV_MODE=hv`); delete the duplicated sanctum lowering+vocab.

**Refinement 1 — config collapses to ~6 fields (label = prefix + shared suffix).** The 7 label prefixes
(`PFX_FORTOP/FOREND/FORCONT/MATCHEND/SKIP/STR/MHASH`) are NOT independent: `RM2_STR_PFX_FORTOP` =
`"L_sanctum_for_top_"`, `RM1` = `"L_hv_for_top_"` — both `<label_pfx>+"for_top_"`. The engine reconstructs
each as `SV_CFG_LABEL_PFX + <shared-suffix-const>`. So `SV_CFG_*` = just: `LABEL_PFX` (`L_sanctum_`/`L_hv_`,
drives symbol-mangle AND all labels), `SEC_TEXT_PE/ELF`, `SEC_RODATA_PE/ELF`, `HDR1`, `HDR2`. (Confirm cg_rm1's
permitted-symbol prefixes `iii_sanctum_`/`xii_sanctum_`/`iii_cap_` vs rm1's during impl — add to config only
if they differ.)

**Refinement 1b — config is exactly 7 ptr+len pairs (verified against cg_rm1's bytes).** `SV_CFG_OWN_PFX`
(`L_hv_`=5B / `L_sanctum_`=10B — drives `emit_mangled`+`build_mangled`+labels+the extra permit check),
`SV_CFG_SEC_TEXT_PE/ELF`, `SV_CFG_SEC_RODATA_PE/ELF`, `SV_CFG_HDR1`, `SV_CFG_HDR2` (rm1=54/61B, rm2=54/63B —
rm2's HDR2 has the `§` section-sign). **Shared engine constants** (byte-identical rm1↔rm2, NOT config): the
4 permit-prefixes `L_sanctum_`/`iii_sanctum_`/`xii_sanctum_`/`iii_cap_`, all instruction templates, label
suffixes (`for_top_`…). Engine `sv_sym_is_permitted` = `match(OWN_PFX) || match(L_sanctum_) ||
match(iii_sanctum_) || match(xii_sanctum_) || match(iii_cap_)` — reproduces rm2 (OWN=L_sanctum_, redundant
but output-identical) and rm1 (OWN=L_hv_ extra) exactly. TODO at impl: confirm `RM1_STR_CMP_RAX_RAX` (rm1-only)
is used solely by the `rm1_hv_*` tables (stays in cg_rm1), not the shared lowering.

**Refinement 2 — engine API (@export from emit_sanctum, called by the thin cg_rm1/cg_rm2 public API):**
`sv_begin(ast,sema,sid,walloc)`, `sv_reset()`, `sv_set_format(fmt)`, `sv_set_const_time(on)`,
`sv_cfg(label_pfx,label_len, sec_text_pe,...,hdr1,hdr2, mode)` (one configure call),
`sv_emit_module(out)` (drives `emit_function`+`emit_string_pool`), `sv_module_finish()`,
`sv_section_mhash(out)`, `sv_last_error()`. cg_rm2's `iii_cg_rm2_create` = `sv_begin`+`sv_cfg(RM2 consts,
SANCTUM)`; `iii_cg_rm2_emit_module` = `sv_emit_module`; etc. cg_rm1 mirrors with RM1 consts + `HV` mode +
its `rm1_hv_*` table emitters retained. Engine state (`SV_G_*`) is module-local to `sanctum`; cross-module
writes go through these @export setters (III has no extern-var).

**Gate sequence per step (build green at each landed step):** (1) add `emit_sanctum` to PORTED_TUS,
build → green (unused). (2) convert cg_rm2 → delegate; build (runs check_rm2.sh) + `emit_gen_diff` R-2
diff empty. (3) convert cg_rm1 → delegate; build + R-1 diff empty. (4) `--check-corpus 59/0` + full corpus
+ reseal iiis-1/iiis-2 (output-preserved, binary-changed).

## 4. Live campaign ledger

- [2026-06-03] Ground truth established; apotheosis premise falsified (tiered, not flat 4→1). Safety net
  **built + validated + durable** (emit_gen_diff.sh: all 4 rings, deterministic + falsifiable; baseline
  binary frozen). Duplication measured: 357 dup constants (~700 lines) + lowering. Architecture + Tier-A
  design fixed (config = 7 ptr+len pairs; engine API; permitted-set logic). Build mechanics verified.
- [2026-06-03] **CRITICAL finding — the rm1/rm2 lowering is NOT byte-identical.** `rm1_emit_pattern_compare`
  (cg_rm1.iii:535) emits `CMP_RAX_RAX` for wildcard/ident patterns; cg_rm2 lacks that constant → its pattern
  handling differs. rm2 "was never exercised end-to-end" (cg_rm2.iii:26) and had drifted node-kind constants
  → it may carry **latent bugs** vs rm1's reference logic. So Tier A is NOT a flat "extract identical lowering"
  — it is **function-by-function diff rm1↔rm2, then for each difference: parametrize (config/mode flag) to
  reproduce BOTH byte streams exactly**. DISCIPLINE: the dedup stays output-preserving (differential-green by
  reproducing both streams); any rm2 *bug-fix* is a SEPARATE, explicit, documented change with its own
  reseal — NOT bundled into the dedup (keeps each change atomic + gated). This is precisely the advisor's
  "rm1≡rm2 is not a literal collapse; the merge must reproduce both byte streams."
  **NEXT: (a) full function-by-function diff of rm1↔rm2 lowering (~12 fns: emit_expr/stmt/block/assign/call/
  match/pattern_compare/pattern_bind + helpers) → enumerate every genuine difference; (b) design the engine
  to reproduce both via config/mode; (c) build emit_sanctum.iii; (d) convert cg_rm2 → gate (check_rm2.sh +
  R-2 diff); (e) convert cg_rm1 → gate (R-1 diff); (f) --check-corpus + corpus + reseal.** The differential
  gate (emit_gen_diff.sh vs /tmp/eg_base) is the unforgiving arbiter at every step.
- [2026-06-03] **Function-diff done — the merge is BOUNDED.** rm1 and rm2 have the SAME 37 lowering functions
  (emit_expr/stmt/block/assign/call/match_expr/match_stmt/pattern_compare/pattern_bind/for/bool_setcc +
  helpers + cg_emit_* + section/mangle/sym + load/store/movabs + pack_hexad). No function in one but not the
  other. Engine = these 37 once, parameterized; within-body differences are (a) the 7 config ptr+len pairs +
  (b) a few genuine logic diffs to enumerate at impl (known: pattern_compare/CMP_RAX_RAX). **ASCERTAINMENT
  PHASE COMPLETE.** Implementation = next sustained coding effort: byte-diff the 37 fns rm1↔rm2 (normalize
  config away) to enumerate (b) → write emit_sanctum.iii reproducing both streams → convert cg_rm2 then
  cg_rm1, gate each → reseal. All durable: this doc + emit_gen_diff.sh + frozen baseline + tasks #6-9.
- [2026-06-03] **✅✅ TIER A COMPLETE — sanctum pair (cg_rm1 R-1 HV + cg_rm2 R-2 sanctum) UNIFIED, GATED,
  RESEALED.** Both codegens now delegate to one shared `emit_sanctum.iii` engine (849 lines, module
  `sanctum`), driven by `SV_MODE` ∈ {SANCTUM=0, HV=1} + config pointers (`SV_CUR_PFX`/`SV_CUR_WILDCMP`).
  cg_rm1: 792→31 lines, cg_rm2: 592→31 lines. **Net ~473 lines deduplicated**; the sanctum lowering
  (emit_block/stmt/expr/assign/call/match/pattern) lives ONCE. The HV path (bare-metal entry, VMX/SVM
  dispatch, VMRUN brackets, VMEXIT/SLAT/BSS tables, witness, HV entry, SHA trailer) promoted verbatim
  into the engine. **5 genuine SV_MODE branches reproduce BOTH byte streams exactly:** OWN_PFX mangling
  (L_hv_/L_sanctum_), pattern_compare wildcard (CMP_RAX_RAX vs 4-space), STMT_RETURN epilogue (HV_EPILOG
  vs sanctum cap-revoke+epilogue), string_pool prefix, label prefixes (reconstructed OWN_PFX+suffix via
  emit_label_pfx/build_label_name), and the SHA trailer (HV feeds cgsha — the engine's inlined sv_sha gives
  a different digest, so HV mode routes cg_emit_bytes→cgsha to match the baseline byte-for-byte).
  **Verified:** emit_gen_diff byte-exact across ALL 4 rings (R-1 HV + R-2 + R-3) on the EXTENDED gate
  (rm2_sample + rm_match_sample + rm_str_sample — covering pattern_compare + string_pool both rings),
  `--check-corpus` 59/0, check_rm2 do_thing(7)=21, reseal determinism-verified (build_iiis1 + build_iiis2
  re-run rc=0; goldens iiis-1=`7d871e7c…` iiis-2=`efc256ca…`; iiis-0 untouched). The cleanest tier of
  emit_generic is DONE. **NEXT: Tier B/C — measure r0↔r3 genuinely-shared lowering, fold into the engine
  (or a sibling) where byte-exact-reproducible; gate via the 24-source R0 .s diff + stage1 .o diff.**
- [2026-06-03] **✅ TIER B/C MEASURED — r0/r3 are genuinely DISTINCT; emit_generic honest deliverable = 4→3.**
  Empirical (not assumed): r0 shares 22 emit-fn NAMES with r3 but (a) `r0_emit_expr` (155L) vs `r3_emit_expr`
  (292L) differ by **321 normalized lines** with DIFFERENT instruction emission per AST kind (not subset —
  genuinely different lowering); (b) the base `emit_bytes` differs — r3 hashes output (sha_update) + different
  state/sealed handling, r0 doesn't; every "identical" helper routes through this differing base, so NONE are
  cleanly shareable; (c) r3 has 32 r3-only fns (richness). Unifying would either need a config-soup monster
  (worse than 2 clear codegens) or change a ring's OUTPUT (not output-preserving). **CONCLUSION: r0 (kernel)
  and r3 (userspace) STAY distinct — forcing them together is the compromise the advisor warned of; the
  apotheosis "4→1 / cg_r3 serves all rings" premise is FALSIFIED by measurement.** emit_generic's genuine,
  no-compromise, output-preserving dedup is **Tier A (sanctum pair 4→3, ~473 lines, DONE)**. Frontier 1
  COMPLETE. Trusted codegen surface shrunk 4→3, the honest realization of the apotheosis's *intent*.
- [2026-06-03] **Byte-diff COMPLETE — engine fully specified, zero ambiguity.** The 37 fns reduce to exactly
  **4 `SV_MODE` (HV=rm1 / SANCTUM=rm2) branches**; all else is shared logic + the 7 `SV_CFG_*` constants:
  1. `emit_pattern_compare` WILDCARD/IDENT: HV→`cg_emit_arr(CMP_RAX_RAX,20)`; SANCTUM→`cg_emit_arr(CMP_RCX_RAX,4)`
     (= 4 spaces — **rm2 BUG**, emits whitespace not a compare). LITERAL/HEXAD arms identical.
  2. `emit_string_pool`: SANCTUM prepends `emit_section_rodata()`+`cg_emit_arr(BAL8)`; HV omits (emits section
     elsewhere in its HV preamble).
  3. `emit_stmt` STMT_RETURN: HV→`cg_emit_arr((&HV_EPILOG_FULL)+20,43)`; SANCTUM→`if IN_ENTRY{if !CAP_REVOKE
     {err}}`+`emit_sanctum_epilogue()`.
  4. `emit_function` frame-zero: HV→`cg_emit_arr(FRAMEZ,FRAMEZ_LEN)` fixed; SANCTUM→`cg_emit_arr(FRAMEZ,95)`+
     `cg_emit_dec(128-pc)`+`cg_emit_arr((&FRAMEZ)+98,21)`.
  **Output-identical (engine uses the clean/correct form, no mode):** `pop_reg` (rm1's 2 dead 0-byte emits
  dropped), EXPR_STR/MHASH (rm2's checked-return is correct; rm1's stale `return K_G_LAST_ERROR` is the same
  bytes on success — keep rm2's checked form). **Separate gated fixes (post-dedup, each its own reseal):**
  (F1) rm2 pattern_compare wildcard/ident → real `cmpq %rax,%rax` like HV; (F2) rm1 EXPR_STR/MHASH unchecked
  return. Engine = 37 shared fns + `SV_CFG_*`(7) + `SV_MODE`∈{HV,SANCTUM} driving the 4 branches above.
  **Implementation is now mechanical: write emit_sanctum.iii to this spec; reproduce both streams; gate.**
- [2026-06-03] **✅ STEP DONE — emit_sanctum.iii engine LANDED + cg_rm2 converted + RESEALED.** Created
  `emit_sanctum.iii` (module `sanctum`, 591 lines) = the canonical cg_rm2 sanctum emitter promoted verbatim
  (clean mechanical rename RM2_→SV_, iii_cg_rm2_→sv_; 0 stray prefixes). Thinned `cg_rm2.iii` 592→30 lines
  (9 public entry points delegate to the engine's `sv_*` @exports via the proven `@abi(c-msvc-x64)` extern
  pattern). Added `emit_sanctum` to PORTED_TUS in build_iiis1/2.sh (LC_ALL=C sorted). **Verified:** iiis-1
  built (rc drift→resealed), iiis-2 built rc=0, `check_rm2` do_thing(7)=21, `--check-corpus` 59/0,
  **emit_gen_diff vs frozen baseline = ZERO diffs across all 4 rings** (output byte-exact), reseal
  determinism-verified (build_iiis1 + build_iiis2 re-run rc=0, mhash matches new goldens iiis-1=`99be51ce…`
  iiis-2=`2f75d2dd…`; iiis-0 untouched). The cg_rm2→engine merge is output-preserving + gated. **NEXT:
  generalize the engine for HV (config SV_CFG_* + SV_MODE + the 4 branches + HV consts CMP_RAX_RAX/
  HV_EPILOG_FULL) and convert cg_rm1 (keep its rm1_hv_* tables + HV entry; delegate the shared LOWERING to
  the engine's @export primitives) → gate R-1 diff → reseal. THAT realizes the dedup (deletes cg_rm1's ~590
  sanctum-lowering lines).** Baseline frozen at iiis-2.exe.emitgen-baseline; gate regenerates from it.
