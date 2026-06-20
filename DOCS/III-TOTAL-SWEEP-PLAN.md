All load-bearing facts are pinned. Producing the plan.

---

# III Total-Sweep — Ordered Execution Plan (single-commit)

**Authoritative corrections folded in (verified against the live tree this session):**
- True STDLIB/corpus max id = **1766** (`1762_weave_arx`, `1765_weave_oneeval`, `1766_weave_invent` already exist). The specs' cited ids `1762`/`1765`/`1767`×2 collide. **New contiguous block assigned: 1767→1772.** stage1_corpus next-free prefix = **58**.
- **sov_isa (#3) is NOT seal-moving.** The task header's "(cg_r3 + sov_isa) as one reseal" is the less-informed framing; spec #3's adversarial check is ground truth — the bootstrap never compiles `STDLIB/sov_isa.iii`, so #3 lands in the byte-safe Phase 1 and its compiler-golden CONFIRM is an **expected NO-OP**. A moved compiler mhash on #3 is itself a finding → STOP.
- **`COMPILED/iiis-1.exe.mhash` golden is LATENTLY RED at baseline** (committed `iiis-1.mhash` is 2-column; `build_iiis1.sh:216` tr-parses it to 74-char junk). This is pre-existing, repaired in Phase 2 by hash-only reseal + the awk-fix. Anchor all byte-safe signals on the **`.exe.mhash` sidecars**, never the golden files.
- Phase file-sets are kept **disjoint** so any red phase backs out cleanly from the one uncommitted tree.

Run all commands from III root: `/c/Users/Edwin Boston/OneDrive/Desktop/III`.

---

## Order of operations (numbered)

### Phase 0 — Baseline (record the known-good reference; the tree is dirty with in-flight weave WIP)
Every gate below is differential; capture the start state first.
```
bash STDLIB/scripts/build_stdlib.sh            # GATE: prints "FAIL = 0"
bash STDLIB/scripts/run_corpus.sh              # GATE: 0 failures; record PASS=N0
bash COMPILER/BOOT/build_iiis0.sh              # rc 0 (awk golden, tolerant)
bash COMPILER/BOOT/build_iiis1.sh || true      # PRE-EXISTING rc 5 at iiis-1 golden (2-col tr bug) — EXPECTED; iiis-1.exe still written at :200
bash COMPILER/BOOT/build_iiis2.sh --check-corpus   # GATE: corpus equivalence 59/0, do_thing=21, [cg_r0-gate] PASS
bash COMPILER/BOOT/build_iiis3.sh --check-corpus   # GATE: 59/0
diff <(cut -d' ' -f1 COMPILED/iiis-2.exe.mhash) <(cut -d' ' -f1 COMPILED/iiis-3.exe.mhash)  # GATE: empty (i2==i3)
cp COMPILED/iiis-0.exe.mhash /tmp/base_i0.mhash
cp COMPILED/iiis-2.exe.mhash /tmp/base_i2.mhash
cp COMPILED/iiis-3.exe.mhash /tmp/base_i3.mhash
cp STDLIB/build/iii/libiii_native.a.mhash /tmp/base_stdlib.mhash
```
**Proceed-gate:** build_stdlib FAIL=0 · run_corpus 0-fail (N0 recorded) · build_iiis2/3 `--check-corpus` 59/0 · i2==i3 empty · 4 sidecars saved. (iiis-1 golden red is pre-existing, not a blocker.)

### Phase 1 — Non-seal-moving STDLIB cash-ins (#3 sov_isa + #6 interval/theorem). Verify via build_stdlib; compiler golden MUST stay unmoved.
File-set (disjoint): `sov_isa.iii`, `interval_lattice.iii`, `range_check.iii`, `branch_elim.iii`, `theorem_commons.iii`, new corpus `1768/1771/1772`, `run_corpus.sh`.

**#3 sov_isa shift-combine** (spec #3 edits, as-is):
- `STDLIB/iii/numera/sov_isa.iii`: add `const SI_SHC_MAX:u32=8u32` (~:135); insert the fixed-grid loop in `sov_isa_rules()` after Rule H (after :459, before :461) using `cga_shift_certifies(2,a,b)` (NON-mutating — keeps the rule set registry-independent); add `@export fn sov_isa_shiftcombine_list_kat()` after :840.
- New `STDLIB/corpus/1768_shiftcombine_list.iii` (was "1765" in spec → **renumber 1768**); externs `sov_isa_shiftcombine_list_kat`; `main` returns 99.
- `STDLIB/scripts/run_corpus.sh`: add `[1768_shiftcombine_list]=99` (FATAL if missing).

**#6 interval_lattice + theorem_commons** (spec #6 items 1 & 3; item 2 EXCLUDED — see EXCLUDE list):
- `STDLIB/iii/numera/interval_lattice.iii`: add `IL_L6_NULL=4`, `IL_L6_ALL=5`, `var IL_BOT:[u8;1]`, classifier in `il_meet` (prefer the hoist-to-locals form: `let mx=il_max(...); let mn=il_min(...)` then set IL_BOT), `il_is_bottom()` accessor, and **`IL_BOT[0]=0` at the TOP of `il_add`/`il_mul`** (before their overflow early-returns); add `il_bottom_kat()`.
- `STDLIB/iii/numera/range_check.iii`: `rc_proven_safe` top — `if hi1<lo1 {return 0u32}` / `if hi2<lo2 {return 0u32}` (HARDENING, value-preserving, keep u32{0,1} contract). `STDLIB/iii/numera/branch_elim.iii`: `be_eliminable` top — `if hi<lo {return 0u32}`. (Included per no-decline-as-bloat; KAT-covered.)
- `STDLIB/iii/numera/value_range_prover.iii`: **NO edit** (audit-only; lo=0 operands can't reach bottom).
- `STDLIB/iii/numera/theorem_commons.iii`: add `var TCOM_PROOF:[u8;1048576]`, `var TCOM_PROOF_LEN:[u64;1024]`; in `tcom_admit` after the 32-byte copy / before `TCOM_COUNT++`, `let pl=tc_serialize(proof,(&TCOM_PROOF+TCOM_COUNT*1024) as *u8,1024)`; **guard `if pl==0xFFFFFFFFFFFFFFFFu64 {pl=0u64}`** before storing length; add `tcom_proof_bytes(slot,out)->i64` accessor; add `tcom_proof_roundtrip_kat()`.
- New `STDLIB/corpus/1771_interval_bottom.iii` (il_meet bottom/value-preservation + il_add-overflow TOP-placement arm + rc/be guard arms) and `STDLIB/corpus/1772_tcom_proof_roundtrip.iii` (call `tcom_init()` first; admit→persist→fresh-init→`tcom_receive` replay; over-cap arm asserts len 0). `run_corpus.sh`: add `[1771_interval_bottom]=99`, `[1772_tcom_proof_roundtrip]=99`.

Verify:
```
bash STDLIB/scripts/build_stdlib.sh                # GATE: FAIL = 0
bash STDLIB/scripts/run_corpus.sh                  # GATE: 1768/1771/1772 = 99; prior sov_isa (874,876,963,1207,1362,1364,1365,1737), interval (1265,1542,1752), theorem (1208,1209,636) all still 99; PASS = N0+3
bash COMPILER/BOOT/build_iiis0.sh
bash COMPILER/BOOT/build_iiis2.sh --check-corpus
bash COMPILER/BOOT/build_iiis3.sh --check-corpus
diff <(cut -d' ' -f1 COMPILED/iiis-0.exe.mhash) /tmp/base_i0.mhash   # GATE: EMPTY
diff <(cut -d' ' -f1 COMPILED/iiis-2.exe.mhash) /tmp/base_i2.mhash   # GATE: EMPTY (byte-safe: golden unmoved; libiii_native.a.mhash MAY change, that is expected)
```
**Proceed-gate:** build_stdlib FAIL=0 · full corpus green (+3) · iiis-0/iiis-2 sidecars **byte-identical to baseline**. A moved compiler mhash here ⇒ #3/#6 unexpectedly reached the compiler closure → **STOP, investigate, do NOT reseal.**

### Phase 2 — Seal-moving codegen batch (#2 cg_r3 non-pow2 mul). The ONE reseal.
File-set (disjoint): `cg_r3.c`, `cg_r3.iii`, `stage1_corpus/58_mul_strength.iii`, new `STDLIB/corpus/1767_r3_mul_strength.iii`, `run_corpus.sh`, robustness `build_iiis1.sh`/`build_xii.sh`, the 4 `COMPILER/BOOT/*.mhash`.

Edits (spec #2 with the THREE mandatory corrections):
- `COMPILER/BOOT/cg_r3.c`: `static int g_sr_a,g_sr_b;` + `mul_strength_form()` detector (after arith_identity, ~:1133); emit block after the idn block (~after :1412) — **CAPTURE `int sa=g_sr_a, sb=g_sr_b;` BEFORE `emit_expr(cg,lhs)`** (the clobber fix; the byte-identity gate cannot catch globals-after-recursion).
- `COMPILER/BOOT/cg_r3.iii`: `var R3_SR_A/R3_SR_B:u32=0u32` (after :257); `r3_mul_strength_form()` (after :888) using **`;` statement separators** (not double-space); emit block after the idn block (~after :2491) — **CAPTURE `let sa=R3_SR_A; let sb=R3_SR_B;` BEFORE `r3_emit_expr(lhs)`**. The two emit sources MUST produce byte-identical machine code.
- New `COMPILER/BOOT/stage1_corpus/58_mul_strength.iii` (triggers the new emit; makes `--check-corpus` non-vacuous; **byte-identity witness only — not run**).
- New `STDLIB/corpus/1767_r3_mul_strength.iii` (was "1762" → **renumber 1767**): spec body (k2..k5 + u32 0xFFFFFFFF + u64 wrap) **PLUS the nested clobber arm** `if (x*3u64)*7u64 != x*21u64 {return 11u64}` and `if (x*5u64)*9u64 != x*45u64 {return 12u64}`. **Confirm sema/XII does not pre-reassociate `(x*3)*7→x*21`** (compile `iiis-2 --emit-asm` on the form; if it folds, make the LHS opaque-via-param) or the teeth are vacuous. `run_corpus.sh`: add `[1767_r3_mul_strength]=99`.
- Robustness (spec #1 edit #6): `build_iiis1.sh:216` and `build_xii.sh:87` — replace the `tr -d '[:space:]'` parse with `awk '{print $1; exit}'`.

Verify = **the reseal sub-procedure below** (run verbatim), PLUS the mandatory clobber RED/GREEN:
```
# RED proof (throwaway): temporarily revert ONLY the local-capture (read R3_SR_A/B AFTER the recursion) in BOTH emit blocks,
#   rebuild stdlib, run 1767 -> MUST return non-99 (nested (x*3)*7 emits x*9). Restore local-capture -> 1767 == 99 (GREEN).
```
**Proceed-gate:** every reseal differential green (emit_gen_diff C==iii empty · build_iiis1 `--check-corpus` 59/0 · build_iiis2 `--check-corpus` 59/0 + do_thing=21 + cg_r0 PASS · i2==i3 empty · cg_seam FAIL=0) · 1767 nested arm RED-on-unfixed/GREEN-after · convergence loop settled (`libiii_native.a.mhash` stable) · `_k4gate` end-to-end green · 4 mhashes resealed. Then snapshot the new reference: `cp COMPILED/iiis-2.exe.mhash /tmp/post2_i2.mhash`.

### Phase 3 — Kernel-trust change (#4 bb_equal SAT miter as tc_conv fallback). STDLIB-only; expands trusted base — lands on the proven post-#2 compiler.
File-set (disjoint): `typecheck.iii`, `sat.iii`, `1214_bv_kernel_differential.iii`, `1355_bv_selflaws_lshr.iii`, new `1769`, `run_corpus.sh`. **ALL in this commit slice.**
- `STDLIB/iii/numera/typecheck.iii`: 12 `bb_*` externs from `bv_bits.iii` after the ccl block (~:101, NOT :55); `tc_bv_word_head`; `tc_to_bb` (refuse-sentinel 0xFFFFFFFF; var-index pre-check `k>=8 → refuse`; shift requires literal `TC_B`); `tc_conv` body rewrite (ccl first; on ccl miss + both heads BV: `bb_reset(64)`, translate, `bb_equal==1 → 1`, else fall through to ccl verdict). Width **must** be 64.
- `STDLIB/iii/numera/sat.iii`: conflict budget in `sat_solve` `while going==1` loop; on exhaustion return non-UNSAT (`SAT_E_TOO_BIG=-2`) → poison → fail-closed. **Anti-hang, not optional.**
- `STDLIB/corpus/1214_bv_kernel_differential.iii`: arm-B separation-probe hardening (snapshot/restore `RNG[0]`; red only on real `er1==0&&er2==0&&v1!=v2`).
- `STDLIB/corpus/1355_bv_selflaws_lshr.iii`: **line-59 flip** `tc_conv(tc_bvsub(xp1a,onepx),z) != 1u8` (the SAT fallback now soundly accepts `(x+1)-(1+x)==0`; omitting this is a **deterministic build break**).
- New `STDLIB/corpus/1769_tc_conv_bv_sat_fallback.iii` (was "1765/1767" → **1769**): ACCEPT `(x&y)+(x|y)==x+y` (RED-on-old), symmetry, REFUTE `lhs vs lhs+1`, extensional cross-check, udiv-refused boundary, `(x<<1)==(x+x)`, non-BV `tc_zero` regression. `run_corpus.sh`: add `[1769_tc_conv_bv_sat_fallback]=99`.

Verify:
```
bash STDLIB/scripts/build_stdlib.sh                # GATE: FAIL = 0
bash STDLIB/scripts/run_corpus.sh                  # GATE: FULL corpus. 1769=99, 1214=99, 1355=99; transitive tc_conv callers 1213,1363,1366,1444,1707,1709 still 99
# RED-on-old: revert ONLY tc_conv body, rebuild, 1769 -> non-99; restore -> 99
# TIMING (BLOCKING GATE): time 1214,1366,1444 vs Phase-0 baseline; regression to minutes = BLOCKER (the budget edit must hold the ~480 multiplier miters)
bash COMPILER/BOOT/build_iiis2.sh --check-corpus
diff <(cut -d' ' -f1 COMPILED/iiis-2.exe.mhash) /tmp/post2_i2.mhash   # GATE: EMPTY (typecheck/sat compiler-unreferenced)
```
**Proceed-gate:** FAIL=0 · full corpus green incl modified 1214/1355 + new 1769 · RED-on-old proven · timing not regressed · iiis-2 sidecar == `/tmp/post2_i2` (drift ⇒ kernel code reached the compiler → **STOP**).

### Phase 4 — Loop-closing (#5 invention engine as ag_cycle proposer). STDLIB-only; consumes the hardened #4 convertibility.
File-set (disjoint): `autogenesis.iii`, new `1770`, `run_corpus.sh`.
- `STDLIB/iii/sanctus/autogenesis.iii`: 6 externs (after :50); consts `AG_INVENT_MAXEXP=8`, `AG_INVENT_BUDGET=1`, `AG_INVENT_HOTOP=3` (after :64); `ag_invent_scan()` (after :159); fold `AG_NCAND = AG_NCAND + ag_invent_scan()` between `lf_forge()` (:173) and `vbd_open` (:174).
- New `STDLIB/corpus/1770_ag_invent_proposer.iii` (was "1765/1767" → **1770**): cap-gated `ag_cycle`/`ag_valid==99`; the (5,5) live-rule payoff via `sov_isa_descend`; apprentice-gate-bites; authorized-commit; eg_init falsifier. `run_corpus.sh`: add `[1770_ag_invent_proposer]=99`.

Verify:
```
bash STDLIB/scripts/build_stdlib.sh                # GATE: FAIL = 0 AND carto architectural-invariant gate green (new autogenesis->{egraph,cg_autocatalyst,isa_macro_synth} edges; allowlist only if a ring invariant flags them)
bash STDLIB/scripts/run_corpus.sh                  # GATE canary set: 1406,1409,1732,1748,1370,1742,1353 all 99 + new 1770=99
# If a canary reds on ag_risk crossing 64: minimal AG_RISK_THRESHOLD 64->65 + reverify (the cross is LOUD)
bash COMPILER/BOOT/build_iiis2.sh --check-corpus
diff <(cut -d' ' -f1 COMPILED/iiis-2.exe.mhash) /tmp/post2_i2.mhash   # GATE: EMPTY
```
**Proceed-gate:** FAIL=0 + carto gate green · canary set + 1770 all 99 · iiis-2 sidecar unmoved.

---

## The reseal sub-procedure (verbatim command sequence — Phase 2)

> INVARIANT: VERIFY THE DIFFERENTIALS GREEN ON THE NEW BINARIES *BEFORE* RESEALING — reseal only rewrites the EXPECTED hash, it does not re-check correctness. The C==iii differential runs in NO automation; **step 4 is mandatory** and `_k4gate` (step 9) does NOT substitute for it.

```bash
# 0. stdlib current; record baseline for the convergence check
IIIS="$PWD/COMPILED/iiis-2.exe" bash STDLIB/scripts/build_stdlib.sh        # require: FAIL = 0
cp STDLIB/build/iii/libiii_native.a.mhash /tmp/stdlib_pre.mhash

# 1. iiis-0 from cg_r3.c (writes sidecar at :298 then DIES exit 5 on the seal move — EXPECTED)
bash COMPILER/BOOT/build_iiis0.sh || true
bash COMPILER/BOOT/build_iiis0.sh --check-deterministic    # exit 6 => nondeterministic codegen -> STOP, do not reseal

# 2. PROVE C==iii GATE-INDEPENDENTLY *before* any reseal (build_iiis1 writes iiis-1.exe at :200 before it dies at :215)
bash COMPILER/BOOT/build_iiis1.sh || true
bash COMPILER/BOOT/emit_gen_diff.sh COMPILED/iiis-0.exe /tmp/eg0
bash COMPILER/BOOT/emit_gen_diff.sh COMPILED/iiis-1.exe /tmp/eg1
diff -r /tmp/eg0/r3 /tmp/eg1/r3            # MUST be empty == cg_r3.c emits byte-identically to cg_r3.iii on all 60 stage1 progs. Non-empty => revert.

# 3. reseal iiis-0 golden (awk-tolerant), reconfirm green
cp COMPILED/iiis-0.exe.mhash COMPILER/BOOT/iiis-0.mhash
bash COMPILER/BOOT/build_iiis0.sh                          # now exit 0

# 4. iiis-1 golden HASH-ONLY (NOT a cp of the 2-col sidecar) + the C-vs-iii corpus differential
cut -d' ' -f1 COMPILED/iiis-1.exe.mhash > COMPILER/BOOT/iiis-1.mhash
bash COMPILER/BOOT/build_iiis1.sh --check-corpus           # REQUIRE exit 0 AND "corpus equivalence: 60 passed, 0 failed"

# 5. iiis-2 fixpoint + Ring-2 + Ring-0 gates (no in-script golden)
bash COMPILER/BOOT/build_iiis2.sh --check-corpus           # REQUIRE 60/0 (iiis-1 vs iiis-2), do_thing(7)=21, [cg_r0-gate] PASS, [cg_r0-wgate] PASS

# 6. iiis-3 second fixpoint + QUINE SEAL
bash COMPILER/BOOT/build_iiis3.sh --check-corpus
diff <(cut -d' ' -f1 COMPILED/iiis-2.exe.mhash) <(cut -d' ' -f1 COMPILED/iiis-3.exe.mhash)   # MUST be empty (i2==i3)

# 7. reseal reference goldens (no machine consumer — record only) + emitgen baseline
cp COMPILED/iiis-2.exe.mhash COMPILER/BOOT/iiis-2.mhash ; cp COMPILED/iiis-3.exe.mhash COMPILER/BOOT/iiis-3.mhash
cp COMPILED/iiis-2.exe COMPILED/iiis-2.exe.emitgen-baseline

# 8. seam + STDLIB<->COMPILER CONVERGENCE LOOP (COMPILED/iiis-2.exe is git-tracked)
IIIS="$PWD/COMPILED/iiis-2.exe" bash COMPILER/BOOT/cg_seam_gate.sh         # REQUIRE [cg-seam] PASS=N FAIL=0
IIIS="$PWD/COMPILED/iiis-2.exe" bash STDLIB/scripts/build_stdlib.sh        # rebuild stdlib w/ NEW iiis-2; FAIL = 0
IIIS="$PWD/COMPILED/iiis-2.exe" bash STDLIB/scripts/run_corpus.sh          # PASS unchanged + 1767 KAT == 99
#   CONVERGENCE: if libiii_native.a.mhash now differs from /tmp/stdlib_pre.mhash, the codegen change altered stdlib .o ->
#   the iiis-2/3 you just sealed embed the OLD-stdlib link. Re-run steps 5-7, then rebuild stdlib once more and re-compare.
#   Repeat until libiii_native.a.mhash is stable (converges in ONE extra cycle — stdlib semantics unchanged).

# 9. one-shot end-to-end gate. NOTE: _k4gate runs build_iiis1 WITHOUT --check-corpus -> it is a fixpoint+seam smoke test,
#    NOT a substitute for step 4's C==iii proof.
bash STDLIB/_k4gate.sh
#   REQUIRE: i0 rc=0, i1 rc=0, i2 rc=0 (60/0, do_thing=21, cg_r0 PASS), i3 rc=0, stdlib FAIL=0, corpus PASS unchanged, seam FAIL=0, K4 DONE shows i2 == i3.

# snapshot the post-reseal reference for Phases 3/4
cp COMPILED/iiis-2.exe.mhash /tmp/post2_i2.mhash
```
> OneDrive relink note: `ld returned 1` with zero undefined refs ⇒ Defender/OneDrive holds the `.exe` open — `rm` the target `.exe` before relinking.

---

## EXCLUDE list

**fe25519 `*38` fold via `gilr_proves` (#6 item 2) — INFEASIBLE, DECLINE.** `gilr_proves` bit-blasts at `GILR_W=64` and `bb_reset` hard-clamps any width >64 down to 64 (~bv_bits.iii:195). The `_fz_fold38` reduction implements `2^256 ≡ 38 (mod 2^255−19)` as a multi-limb fold over the 512-bit `FZ_T[16]` product — `k=256/255` exceeds the 64-bit blaster (and the host `1u64<<255` masks to `<<63`). `gilr_proves(255,19,38)` therefore models a *different* 64-bit relation and returns a **false `0`** that would masquerade as "fold unproven." The hardcoded fold stays pinned by corpus 388/973/992, and the fe25519 source comment forbids absorbing it into Montgomery. **Optional documentation-of-decline:** add `1773_gilr_inapplicable.iii` pinning `gilr_proves(255u64,19u64,38u64)==0u8` (verify the `==0` empirically — it is an out-of-width call). A correct certificate needs a ≥256-bit blaster or the one-line number-theory proof; neither is lean. No code edit.

**Not excluded (kept, marked "hardening"):** #6's `range_check`/`branch_elim` input guards and `il_is_bottom` classifier — value-preserving, KAT-covered, defend unreachable inputs (per the no-decline-as-bloat standard). #6's `value_range_prover` is audit-only (no edit needed, not an exclusion).

---

## Final verification + commit

After all four phases land in the single uncommitted tree, run **one canonical full rebuild on the final tree** so no phase leaves a stale tracked artifact (`STDLIB/build/corpus/*.exe`, `libiii_native.a`, `COMPILED/iiis-*.exe`, all `*.mhash` are git-tracked and go in the commit):

```bash
bash STDLIB/scripts/build_stdlib.sh                                  # FAIL = 0
bash STDLIB/scripts/run_corpus.sh                                    # 0 failures; PASS = N0 + 6 (1767,1768,1769,1770,1771,1772); all canary/regression sets 99
bash COMPILER/BOOT/build_iiis0.sh                                    # rc 0 (resealed)
bash COMPILER/BOOT/build_iiis1.sh --check-corpus                     # rc 0, 60/0 (hash-only golden + awk-fix repair the latent red)
bash COMPILER/BOOT/build_iiis2.sh --check-corpus                     # rc 0, 60/0, do_thing=21, cg_r0 PASS
bash COMPILER/BOOT/build_iiis3.sh --check-corpus                     # rc 0, 60/0
diff <(cut -d' ' -f1 COMPILED/iiis-2.exe.mhash) <(cut -d' ' -f1 COMPILED/iiis-3.exe.mhash)   # empty (i2==i3 quine seal)
bash COMPILER/BOOT/emit_gen_diff.sh COMPILED/iiis-0.exe /tmp/eg0     # final C==iii proof
bash COMPILER/BOOT/emit_gen_diff.sh COMPILED/iiis-1.exe /tmp/eg1
diff -r /tmp/eg0/r3 /tmp/eg1/r3                                      # empty
IIIS="$PWD/COMPILED/iiis-2.exe" bash COMPILER/BOOT/cg_seam_gate.sh   # [cg-seam] PASS=N FAIL=0
bash STDLIB/_k4gate.sh                                               # i0..i3 rc=0; K4 DONE i2 == i3
```

**ALL of the following must be green before the single commit:**
1. `build_stdlib` → **FAIL = 0**.
2. `run_corpus` → **0 failures**, PASS = baseline N0 + 6 new; every modified KAT (1214, 1355) and every canary (1406/1409/1732/1748/1370/1742/1353, plus tc_conv transitive callers 1213/1363/1366/1444/1707/1709) at 99.
3. Bootstrap differential → `build_iiis1/2/3 --check-corpus` 60/0; **C==iii** `emit_gen_diff` empty; **i2==i3** quine seal empty; `cg_seam` FAIL=0; `_k4gate` end-to-end rc=0.
4. Coverage → the 6 new corpus ids each have a `run_corpus.sh` EXPECTED=99 entry; stage1 `58_mul_strength.iii` present and compiled by `--check-corpus`.
5. Timing → 1214/1366/1444 not regressed to minutes.

Then **one clean commit** (only after all gates green; engineer commits — currently on `master`, branch per repo convention if required) including: `cg_r3.{c,iii}`, `stage1_corpus/58_mul_strength.iii`, the 6 stdlib sources (`sov_isa`, `interval_lattice`, `range_check`, `branch_elim`, `theorem_commons`, `autogenesis`), `typecheck.iii`, `sat.iii`, the 2 modified corpus (1214, 1355) + 6 new corpus (1767–1772), `run_corpus.sh`, the `build_iiis1.sh`/`build_xii.sh` awk-fix, the 4 `COMPILER/BOOT/*.mhash`, `COMPILED/iiis-*.exe` + sidecars + emitgen-baseline, `libiii_native.a` + sidecar, and the regenerated `STDLIB/build/corpus/*.exe`. Commit trailer:
```
Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
```

**Apply-time caveat (the tree is live):** recompute STDLIB corpus `max+1` and stage1 `max+1` immediately before creating files (1762/1765 were eaten mid-audit); if new ids appeared, shift the **1767–1772** block up contiguously and update the matching `run_corpus.sh` EXPECTED entries and corpus-file module names in lockstep.
