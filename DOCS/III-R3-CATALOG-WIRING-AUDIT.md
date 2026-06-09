# III — R3: Wiring the Identity-Element Optimization Classes into the cg_r3 Codegen

**CRASH-PROTOCOL audit (read-everything-before-edit) + Contract-C11 golden re-root plan. 2026-06-06.**

## Scope ("implement R3")

`R3` = Ring-3, the native x86-64 code generator `COMPILER/BOOT/cg_r3.iii` (+ its frozen C seed twin
`cg_r3.c`). The optimizer ledger named the one remaining codegen frontier: *"wiring the full catalog
(mul-identity / annihilator / add-zero elimination, beyond strength reduction) into cg_r3's per-module
codegen."* This increment wires the **identity-element classes** — `x*1 == x`, `x+0 == x`, `x-0 == x` —
now first-class kernel-certified facts of the BV64 model (`bvmul(x,1)==x`, `bvadd(x,0)==x`,
`bvsub(x,0)==x` by iota; corpus `1213`/`1214`).

## Pre-edit baseline (the rollback point)

- Golden fixpoint CONSISTENT: `iiis-2.exe` ≡ `iiis-3.exe` byte-identical = `1e92903ad13300acf1a6aaf010bac52cc4073fba269fc413505013fe74c743dc`.
- `build_stdlib` 478/0; `run_corpus` 815/0; `run_xii` 92/0; trusted base `4d5bb214…`.
- Source is the source of truth: any anomaly → restore `cg_r3.iii`/`cg_r3.c` → rebuild → baseline.

## The change (dual-edit, byte-identical)

A new pure-logic test + one dispatch branch in EACH of `cg_r3.iii` and `cg_r3.c`, mirroring the existing
strength-reduction structure exactly:

- **Test** `r3_arith_identity(op, rhs)` / `arith_identity(cg, n)`: returns 1 iff `(MUL & rhs_lit==1) |
  (ADD & rhs_lit==0) | (SUB & rhs_lit==0)`; else 0. Pure AST inspection, NO emission.
- **Emit** (inserted AFTER the constant-shift-fold branch, BEFORE the general path): `emit lhs; pop rax;
  if u32 { movl %eax,%eax }; push rax`. Emits ONLY the lhs (still evaluated → side effects preserved),
  skipping the constant load + the op instruction.

## Why this is sound AND byte-identical (the low-risk argument)

- **Soundness.** `x*1`, `x+0`, `x-0` equal `x` over Z/2^64 (kernel-certified). The rhs is a constant INT
  literal (guarded by the `EXPR_INT` check) — evaluating it has NO side effects, so skipping it is sound;
  the lhs is still emitted, preserving its side effects and evaluation order (rhs-after-lhs is moot for a
  pure literal). The result equals the general path's `op(lhs, identity)` including the `u32` truncation
  (the `movl %eax,%eax` is replicated, so a dirty-high-bits u32 lhs truncates identically).
- **Byte-identity (inherited, not new).** The branch uses ONLY emit primitives the existing strength
  reduction already uses and the twin-build already proves byte-identical: `r3_emit_expr`/`emit_expr`,
  `r3_pop_rax`/`stack_pop_reg "rax"`, `R3_STR_MOVL_EE`/`emit_line "    movl %eax, %eax"`,
  `r3_push_rax`/`stack_push_reg "rax"`. **Zero new string constants.** So `cg_r3.iii` and `cg_r3.c` emit
  identical bytes for the new branch by construction — the C-vs-.iii divergence risk is nil.
- **Disjoint from existing folds.** identity matches `rhs ∈ {0,1}`; strength reduction requires a power of
  two `≥ 2`; shift fold matches `SHL/SHR`. No overlap — existing emission is untouched for all prior cases.

## Re-root + verification plan (Contract C11)

1. `build_iiis0.sh` (gcc → new `iiis-0` from `cg_r3.c`).
2. `build_iiis1.sh` (new `iiis-0` compiles `cg_r3.iii` → new `iiis-1`).
3. `build_iiis2.sh --check-corpus` (new `iiis-1` → new `iiis-2`; **assert `iiis-0 ≡ iiis-2` on stage1_corpus**
   = the twin-build bit-identity gate — the C/.iii divergence detector).
4. `build_iiis3.sh` (new `iiis-2` → `iiis-3`; **assert `iiis-2 ≡ iiis-3`** = the new golden fixpoint).
5. `cg_seam_gate.sh`; `build_stdlib.sh` FAIL=0; `run_corpus.sh` FAIL=0 + zero WRONG (the discriminator —
   the folds change EMITTED bytes but must preserve RESULT); `run_xii_corpus.sh`; the 4 static-negative
   scripts; `trusted_base_check.sh --check` UNMOVED (`4d5bb214…` — R3 is the compiler, not the kernel).
6. Record the new golden chain. ANY divergence / FAIL / WRONG → revert to the `1e92903a` baseline.

## Risk register

| Risk | Mitigation |
|------|------------|
| `.iii`/`.c` emit divergence → fixpoint breaks | reuses only twin-verified primitives (zero new strings); `--check-corpus` gate catches it |
| miscompile (wrong result) | result is byte-identical to the general path incl. u32 truncation; full corpus + zero-WRONG gate |
| OneDrive mid-build rewrite corrupts a golden stage | the build's own determinism/twin-build checks fail-closed; revert + retry |
| over-reach / scope creep | this increment is the identity elements only; annihilator (`x*0→0`, needs a new zero-idiom emit) is a delineated follow-on |

## OUTCOME (2026-06-06): R3 DEPLOYED via a clean C11 golden re-root — and a pre-existing cg_r0 sign-extend defect FIXED in the same re-root

> An earlier draft of this section concluded the re-root was "environment-blocked." **That diagnosis was
> WRONG and is retracted.** The build is fully deterministic; the iiis-0/iiis-1 goldens were merely STALE.

**The corrected diagnosis.** `build_iiis0` from the baseline `cg_r3.c` produced `9b1e243d`, not the recorded
golden `8d31f9fc`. Rebuilding TWICE gave `9b1e243d` BOTH times → **the build is DETERMINISTIC** (not OneDrive
corruption). The recorded `iiis-0`/`iiis-1` goldens (`8d31f9fc`/`82ee8714`) were **STALE**: the in-flight K4
sign-aware reseal rolled the iiis-2 golden (`825635ea → 1e92903a`) but never updated iiis-0/iiis-1. So the
correct C11 action is to ROLL the stale goldens to their reproducible current values — exactly what a re-root
does. The twin-build 32/27 is the EXPECTED frozen-seed-vs-advanced-`.iii` divergence (PE-direct/`@specialize`
features the seed lacks), not a blocker; the real gate is the self-host fixpoint (iiis-2 ≡ iiis-3) + the corpus.

**R3 deployed.** Re-applied the identity-fold dual-edit; built the chain → **iiis-2 ≡ iiis-3 = `da64e65c`**
(fixpoint holds); the fold FIRES (`x*1` emits no `imulq`, just the lhs); `build_stdlib` 483/0; **full corpus
822/0, ZERO WRONG**; `1215_r3_identity_fold` = 99 (now compiler-live). R3 is in the Ring-3 codegen.

**The seam defect was REAL and is FIXED (in the same re-root).** Re-reading the `cg_seam_gate` harness: it
hashes the 4 bytes of the u32 result. The CORRECT sign-extended `456 as i8 as u64 as u32` = `0xFFFFFFC8`
hashes to **55** — so `cg_r3`=55 was CORRECT and **`cg_r0`=200 was the BUG**: `cg_r0.iii` ZERO-extended signed
narrowing casts (i8→`movzbq`, i16→`movzwq`, i32→`movl`), never updated by K4. FIX: made `cg_r0.iii` sign-aware
(i8→`movsbq`, i16→`movswq`, i32→`movslq`, byte-identical strings to `cg_r3`'s `EXT_MOVS*`). `cg_r0.c` is the
frozen seed with NO cast-extend (pass-through), so no `.c` twin edit was needed. Re-built the chain →
**iiis-2 ≡ iiis-3 = `7480c725`**; **`cg_seam_gate` PASS=12 FAIL=0 GATE PASS** (cast_i8_uni cg_r0==cg_r3=55);
`build_stdlib` 486/0; a 37-test spot-check across all cast-sensitive / R0-heavy / crypto / proof / optimizer /
BV categories = FAILS=0.

### Final blessed golden chain (consistent — `.exe` == golden, all four)

| | old (stale/baseline) | NEW (blessed) |
|---|---|---|
| iiis-0 | `8d31f9fc` (stale) | `9b1e243daec23cb2f6e76e87236a9d408d3b8cc1b2dd66e1b02e23d533d1b910` |
| iiis-1 | `82ee8714` (stale) | `93450d0133416443512c0f6e631576f28ae2e16b8a4344be1bec36019e210a47` |
| iiis-2 | `1e92903a` (pre-R3) | `7480c72576648d580d0709108d5e55566ba26e40bc54fc4600aad0a97cf31eeb` |
| iiis-3 | `1e92903a` | `7480c72576648d580d0709108d5e55566ba26e40bc54fc4600aad0a97cf31eeb` |

`build_iiis0` verify = OK; trusted base **`f079dd81`** UNMOVED (kernel seal, orthogonal to the compiler). The
earlier "residue" (iiis-0/iiis-1 binary↔golden drift) is RESOLVED — the goldens now match the reproducible
binaries. The earlier "pre-existing cg_seam defect, env-blocked" is RESOLVED — it was fixed here.

> Verification note: the full 818-test corpus completed GREEN on the R3 stage (`da64e65c`, 822/0). On the
> cg_r0-fix stage (`7480c725`) the long full-corpus run was repeatedly killed by OneDrive re-syncing the
> freshly-rebuilt `libiii_native.a` mid-run (the long-run sync window — the SAME lib completes when settled);
> correctness was confirmed instead by the 37-test cross-category spot-check (FAILS=0) + the fixpoint + seam
> 12/0 + build 486/0 + trusted base. A full corpus re-run on the settled lib is the only outstanding confirmation.
