# The e-graph IS cg_r3's optimizer — universal, proven, production-ready

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development or superpowers:executing-plans, task-by-task. Steps use checkbox (`- [ ]`) syntax. **No-subagents-on-III is a hard lock — execute in the main session, by hand.**

**Goal:** cg_r3's expression lowering BECOMES the e-graph synthesis engine. For ANY expression the compiler meets, it saturates an e-graph with algebraic + bitwise laws, extracts the cost-optimal equivalent, machine-proves it equivalent to the original over all 2^64, and emits that. Every hand-written peephole rule (`r3_mul_pow2_k`, `r3_mul_shladd_k`, `r3_div_pow2_k`, …) is deleted and SUBSUMED. The synthesizer does not "certify a law a human wrote" — the synthesizer, inside the compiler, IS the optimizer.

**The proof (operator-fixed, non-negotiable):** the operator points the compiler at ARBITRARY real code — anything, not a chosen example — and it produces optimal, correct, machine-proven lowering with every bootstrap gate green. No script in the proof loop. If it ever emits an unproven or wrong lowering, it has failed. It must work for everything, independently, perfectly.

**Architecture:** `ser_egraph` (saturation/extraction) and the equivalence prover (`bv_ring` ring fragment + `bv_bits` full bit-vector via bit-blasting + a CDCL SAT core) are LIFTED into the BOOT compiler's link set so `cg_r3` calls them at compile time. `cg_r3`'s binop/expr lowering replaces its peephole cascade with: build the e-graph term → saturate → extract min-cost form → **prove the extracted form ≡ the source term over 2^64** → emit it; on any proof failure, emit the naive form (always sound). A content-addressed *certified rule cache* memoizes proven (term-shape → form) pairs so compile time stays bounded. Both bootstrap twins are made consistent (the tracked `cg_r3.c` division divergence is fixed first).

**Tech stack:** III (`.iii`), the self-hosting BOOT compiler (`cg_r3.iii` + its `cg_r3.c` seed twin), existing `numera/ser_egraph`, `numera/bv_ring`, `numera/bv_bits`, the bootstrap drivers (`build_iiis0/1/2/3.sh`, `--check-corpus`), `run_corpus.sh`, `build_stdlib.sh`.

## Global Constraints
- **No islands.** The optimizer IS the existing `ser_egraph`; the prover IS `bv_ring`/`bv_bits`. Lifting ≠ copying — one source of truth, relocated. If a second e-graph appears anywhere, the plan has failed.
- **No script is ever the proof.** The proof is the compiler running on un-pre-shaped input with all gates green. KATs exist only to *gate regressions*, never to *demonstrate* the capability.
- **Sound for EVERYTHING or it does not emit.** Every emitted non-naive lowering is `bv`-proven ≡ source over all 2^64. Unproven ⇒ fall back to naive lowering. No unproven optimization ships, for any input.
- **Production-ready every commit.** Must pass, with zero exceptions: `iiis-2 == iiis-3` fixpoint, `iiis-0 == iiis-2` byte-equivalence (`--check-corpus`), full `run_corpus.sh`, `build_stdlib.sh` (all ratchets at pin), determinism firewall.
- **Both twins compute identically for ALL operations** (fix the div divergence; keep them lockstep or retire `.c` under a green fixpoint).
- Hard locks: no-Python, no-third-party, no-subagents-on-III, no-placeholder, no-ML, no-downscale.
- The PINNED in-tree compiler `COMPILED/iiis-2.exe --compile-only` is the only oracle for KAT runs (the stale-compiler trap, `run_corpus.sh:24-28`).

---

## Phase 0 — Production-readiness prerequisite: kill the twin divergence

The bootstrap twins disagree on unsigned u64 division (`cg_r3.c:1621` emits `cqto; idivq` for ALL division; `cg_r3.iii:2200` has the `xorl %edx; divq` unsigned fix). A self-extending compiler whose two seeds disagree is not production-ready. Fix BEFORE anything else, and install the falsifier that proves it stays fixed.

### Task 0.1: Falsifier first — an unsigned-u64-div program in stage1_corpus that SHOULD redden the byte-check
**Files:** Create `COMPILER/BOOT/stage1_corpus/58_udiv_highbit.iii`; Modify `COMPILER/BOOT/build_iiis1.sh` (corpus list if hardcoded).
**Interfaces:** Produces: a stage1 program exercising `u64 / u64` with a high-bit dividend.
- [ ] **Step 1:** Write `58_udiv_highbit.iii`: `fn f(a: u64, b: u64) -> u64 { return a / b }  fn main() -> u64 { return f(18446744073709551614u64, 2u64) }` (0xFFFF…FE/2 = 0x7FFF…FF; `idivq` reads it as negative → wrong).
- [ ] **Step 2:** Run `--check-corpus` (`bash COMPILER/BOOT/build_iiis2.sh --check-corpus`). Expected: **byte-check REDDENS** on `58_udiv_highbit` (iiis-0 via `cg_r3.c` ≠ iiis-2 via `cg_r3.iii`). This proves the divergence is real and the corpus now detects it.
- [ ] **Step 3:** Commit the falsifier ONLY (red gate is the expected state): `git commit -m "stage1: falsifier for cg_r3.c unsigned-div divergence (expected RED until 0.2)"`.

### Task 0.2: Back-patch cg_r3.c's division to the unsigned-aware form (twin lockstep)
**Files:** Modify `COMPILER/BOOT/cg_r3.c:1593-1594` (the `III_BIN_DIV`/`III_BIN_MOD` emission).
**Interfaces:** Consumes: `expr_is_signed` (exists, `cg_r3.c:849`). Produces: byte-identical division emission to `cg_r3.iii:2611-2612`.
- [ ] **Step 1:** Read `cg_r3.iii:2606-2612` — the exact `signed ? IDIV : DIVU` split and the `R3_STR_DIVU`/`R3_STR_DIVUMOD` byte arrays.
- [ ] **Step 2:** Replace `cg_r3.c:1593`'s `case III_BIN_DIV: emit_line(cg, "    cqto\n    idivq %%rcx"); break;` with the signed branch: `if (either_is_signed) emit_line("    cqto\n    idivq %%rcx"); else emit_line("    xorl %%edx, %%edx\n    divq %%rcx");` — byte-for-byte the strings `cg_r3.iii` emits. Mirror for `III_BIN_MOD`.
- [ ] **Step 3:** Run `bash COMPILER/BOOT/build_iiis2.sh --check-corpus`. Expected: byte-check GREEN again (incl. `58_udiv_highbit`) — the twins now agree.
- [ ] **Step 4:** Run `bash STDLIB/scripts/run_corpus.sh` (PINNED iiis-2). Expected: no regression.
- [ ] **Step 5:** Commit: `git commit -m "cg_r3.c: unsigned-div fix — twins lockstep; stage1 falsifier now GREEN"`.

### Task 0.3: Re-audit the signed-index div→shr sites the retrospective flagged unverified
**Files:** none (audit); produce `DOCS/III-DIV-SITE-AUDIT.md`.
- [ ] **Step 1:** `grep -rnE '/ (2|4|8|...)' STDLIB/iii` filtered to **signed** operands (`i32/i64`). For each, objdump the built `.o`; confirm it is NOT `shr` (signed `x/2^k ≠ x>>k`). Record each site + verdict.
- [ ] **Step 2:** If any signed site emitted `shr`, that is a soundness bug — fix the unsigned-gate in `r3_div_pow2_k` (and the e-graph cost model later must inherit the same gate). Commit the audit doc.

---

## Phase 1 — Lift the e-graph and the prover into the BOOT compiler

`grep seg_|egraph COMPILER/BOOT` = 0 today. For the synthesizer to DRIVE the compiler (not have a human transcribe its verdict), `cg_r3` must CALL it at compile time. The e-graph + prover must live where the BOOT link set can reach them — without forking a second copy (no-island).

### Task 1.1: Establish the BOOT optimizer link set
**Files:** Create `COMPILER/BOOT/opt/` ; Modify `COMPILER/BOOT/build_iiis2.sh`, `build_iiis3.sh` (link list).
**Interfaces:** Produces: a BOOT-visible module set `{ser_egraph, bv_ring, bv_bits, sat}` that `cg_r3` can `extern … from`.
- [ ] **Step 1:** Decide relocation, not duplication: move `STDLIB/iii/numera/ser_egraph.iii`, `bv_ring.iii`, `bv_bits.iii` to `COMPILER/BOOT/opt/` and leave a re-export shim in STDLIB (`numera/ser_egraph.iii` becomes `extern … from "opt/ser_egraph.iii"` re-exports) so STDLIB consumers and corpus KATs keep working AND there is ONE source. Verify with `grep -rl 'fn seg_intern' STDLIB COMPILER` → exactly one definition.
- [ ] **Step 2:** Add the `opt/` modules to the iiis-2/iiis-3 link list, BEFORE `cg_r3`.
- [ ] **Step 3:** `bash COMPILER/BOOT/build_iiis2.sh` — the compiler links the optimizer modules. Expected: builds. (No behavior change yet; just linkage.)
- [ ] **Step 4:** `--check-corpus` + `run_corpus.sh` green (relocation is byte-neutral). Commit.

### Task 1.2: A C twin for every lifted module OR retire the C seed under a green fixpoint
**Files:** Modify `COMPILER/BOOT/cg_r3.c` build, or author `opt/*.c` twins.
**Decision gate:** The lifted optimizer is large; hand-twinning it in C is enormous. Evaluate retiring `iiis-0` (the C seed) once `iiis-1` (built by the last good `iiis-0`) can rebuild `iiis-2` and `iiis-2 == iiis-3` holds — i.e. the self-hosted fixpoint no longer NEEDS the C twin for new code, only the frozen stage1 byte-check. If retirement is sound (stage1 byte-check still passes against a FROZEN `iiis-0`), the e-graph need only live in `.iii`.
- [ ] **Step 1:** Confirm `iiis-1` (from frozen `iiis-0`) rebuilds `iiis-2`; confirm `iiis-2 == iiis-3`. Document the bootstrap DAG and exactly what each twin still gates.
- [ ] **Step 2:** If retiring: freeze `cg_r3.c` + `iiis-0` as the stage1-only oracle; record that NEW optimizer code lives only in `.iii` and is gated by `iiis-2 == iiis-3` (self-hosted) + the FROZEN stage1 byte-check. If NOT retiring: every `opt/*.iii` gets a byte-identical `opt/*.c` twin (each its own task, TDD per function).
- [ ] **Step 3:** Whichever path: full fixpoint + byte-check + corpus green. Commit the bootstrap-DAG decision doc.

### Task 1.3: Complete `bv_bits` to a sound, complete bit-vector equivalence oracle
**Files:** Modify `COMPILER/BOOT/opt/bv_bits.iii`; Create `COMPILER/BOOT/opt/sat.iii`.
**Interfaces:** Produces: `bv_bits_equiv(t1: u32, t2: u32) -> u8` = 1 iff t1 ≡ t2 for ALL 2^64 assignments (UNSAT of the miter), 0 otherwise; `bv_bits_counterexample() -> u64` (a witness when 0).
- [ ] **Step 1 (test):** `sat_unsat` KAT — a known UNSAT clause set returns UNSAT; a known SAT set returns a model. Run, fail.
- [ ] **Step 2:** Implement `sat.iii`: CDCL — clause DB, two-watched-literal propagation, conflict analysis (1-UIP), non-chronological backjump, restarts. Run the KAT, pass.
- [ ] **Step 3 (test):** `bv_bits` miter for `x*2 ≡ x<<1` → UNSAT (equiv); `x*2 ≡ x<<2` → SAT with a counterexample. Run, fail.
- [ ] **Step 4:** Implement bit-blasting for every op `cg_r3` lowers: ripple-carry add/sub, shift-and-add `mul` (full 64×64→64), restoring `div`/`mod`, `shl`/`shr` (const + variable), `and`/`or`/`xor`, the comparisons. Each op → CNF over 64 output bits. The miter: `XOR` corresponding output bits, OR them, assert ≥1 differs, hand to SAT; UNSAT ⇒ equiv. Run, pass.
- [ ] **Step 5 (adversarial):** prove a deliberately-wrong "optimization" is REJECTED (`x/3 ≡ x>>1` → SAT/ counterexample). The oracle must default to "not equiv" on any SAT/timeout. Commit.

### Task 1.4: The unified prover front-end
**Files:** Create `COMPILER/BOOT/opt/bv_prove.iii`.
**Interfaces:** `bv_prove_equiv(term1: u32, term2: u32) -> u8` — try `bv_ring` (fast, ring fragment) first; on "not in fragment / unknown" fall to `bv_bits` (complete); return 1 ONLY on a real equivalence proof, else 0.
- [ ] **Step 1 (test):** `(x<<3)+(x<<1) ≡ x*10` via ring → 1; `(x>>3) ≡ x/8` (NOT a ring identity) falls to bv_bits → 1; `x/7 ≡ (x*m)>>s` for the right (m,s) → bv_bits → 1, for wrong (m,s) → 0.
- [ ] **Step 2:** Implement the dispatch + the "default to unproven" discipline. Run, pass. Commit.

---

## Phase 2 — Wire the e-graph INTO cg_r3's lowering (delete the peephole)

This is the apply-half. `cg_r3`'s `R3_K_EXPR_BINARY` arm stops calling `r3_mul_pow2_k`/`r3_div_pow2_k`/etc. and instead asks the e-graph for the optimal proven lowering of the WHOLE expression.

### Task 2.1: AST→e-graph term builder inside cg_r3
**Files:** Modify `COMPILER/BOOT/cg_r3.iii` (new `r3_build_egraph_term`); Create `COMPILER/BOOT/cg_r3_lower_test.iii` (a corpus KAT harness for lowering equivalence, gating only).
**Interfaces:** `r3_build_egraph_term(node: u32) -> u32` — recursively interns an AST expr subtree into `ser_egraph` (vars → `seg_var` keyed by AST node id; int literals → `seg_const`; binops → `seg_intern(op,…)`), returning the e-class id. Consumes existing `iii_ast_*`. Produces: the e-graph root for the source expression.
- [ ] **Step 1 (test):** build the term for `x*10`, assert `seg_eval(root, k) == 10*k` for sampled k (the term faithfully models the AST). Run, fail.
- [ ] **Step 2:** Implement `r3_build_egraph_term` (handle the op set; bail to "not modellable" for unsupported nodes → caller uses naive lowering). Run, pass. Commit.

### Task 2.2: Saturate + extract + PROVE, returning a lowering plan
**Files:** Modify `cg_r3.iii` (new `r3_synthesize_lowering`).
**Interfaces:** `r3_synthesize_lowering(node: u32) -> u32` — builds the term, `seg_saturate()`, `seg_best_cost`/extract the min-cost member, then `bv_prove_equiv(extracted, source_root)`; returns a handle to the proven optimal form, or `R3_NOOPT` (0) if extraction == source or proof fails. **No emission yet — this is the decision.**
- [ ] **Step 1 (test):** `r3_synthesize_lowering(x*10)` returns a form whose `seg_eval` == 10x AND `bv_prove_equiv` == 1; `r3_synthesize_lowering(x*11)` returns `R3_NOOPT` (imul optimal) or a proven form, never an unproven one. Run, fail.
- [ ] **Step 2:** Implement; enforce: NOTHING is returned as an optimization unless `bv_prove_equiv == 1`. Run, pass.
- [ ] **Step 3 (adversarial):** inject a deliberately-broken extraction (temporarily) and confirm `bv_prove_equiv` REJECTS it → `R3_NOOPT`. Revert the injection. Commit.

### Task 2.3: Emit the proven form; delete the peephole cascade
**Files:** Modify `cg_r3.iii:2519-2605` (the binary arm) and `cg_r3.c` twin (or frozen per 1.2).
**Interfaces:** the binary arm becomes: `let plan = r3_synthesize_lowering(node); if plan != R3_NOOPT { r3_emit_egraph_form(plan); return } /* else naive */`. `r3_emit_egraph_form` walks the extracted e-graph form and emits the asm (shl/add/sub/shr/mul/mov sequence) for each node, reusing the existing byte-array emit primitives.
- [ ] **Step 1 (test):** the EXISTING strength-reduction corpus KATs (2037/2038/2050-2061 etc.) still pass — the e-graph path must reproduce every form the peephole produced (subsumption). Run against the rebuilt iiis-2.
- [ ] **Step 2:** Implement `r3_emit_egraph_form` (the form→asm walk). DELETE `r3_mul_pow2_k`, `r3_mul_shladd_k`, `r3_mul_subk_k`, `r3_mul_2sh_*`, `r3_mul_2ss_*`, `r3_div_pow2_k` and their `cgopt_*` law calls from the binary arm (the e-graph subsumes them). Keep `cgopt_*`/the law module ONLY if the cache (Phase 3) reuses it; otherwise delete.
- [ ] **Step 3:** Rebuild iiis-2. objdump `x*10 → shl shl add`, `x/8 → shr`, `x*11 → imul` — produced by the e-graph now, not the peephole.
- [ ] **Step 4:** `--check-corpus`, `run_corpus.sh`, `build_stdlib.sh` ALL green. **This is the moment the synthesizer drives cg_r3.** Commit.

### Task 2.4: Compile-time budget + the certified rule cache
**Files:** Create `COMPILER/BOOT/opt/rule_cache.iii`.
**Interfaces:** content-addressed `(canonical-term-shape) → (proven form | NOOPT)`. `r3_synthesize_lowering` consults the cache first; on miss, saturate+prove, then insert. Bounds compile time so the e-graph runs on EVERY expression without blowing up build time.
- [ ] **Step 1 (test):** compiling a file with N identical `x*10` sites saturates+proves ONCE (cache hit count == N-1). Measure build time of `build_stdlib.sh` before/after; assert within an acceptable factor (record it — no silent regression).
- [ ] **Step 2:** Implement the cache (canonicalize by op-structure + constants; key = a stable hash). Run, pass.
- [ ] **Step 3:** Full gates green; build-time delta recorded in the commit. Commit.

---

## Phase 3 — Universality: it works for EVERYTHING

The peephole only knew mul/div by a constant. The e-graph must lower the FULL op set optimally, for any expression, or honestly emit naive (still correct). "Works for everything" = for every expression class, the compiler either improves it (proven) or leaves it correct.

### Task 3.1: Complete the law set
**Files:** Modify `opt/ser_egraph.iii` (the saturation laws).
**Interfaces:** add generic, always-sound rewrite laws covering: associativity/commutativity (add, mul, and, or, xor), distributivity (mul over add), identity/annihilator (`x*1`, `x+0`, `x*0`, `x&0`, `x|0`, `x^0`, `x&x`, `x|x`, `x^x=0`), constant folding, the additive AND subtractive shift decompositions, `x/2^k → x>>k` (unsigned), `x%2^k → x&(2^k-1)` (unsigned), strength reductions for mul/div by general constants where a proven cheaper form exists.
- [ ] **Step 1 (test):** for a battery of expression shapes (`x*6`, `x/4`, `x%8`, `(x<<2)+(x<<1)`, `x*1`, `x&x`, `x^x`, `x*0`, `a*4+a*2`), `r3_synthesize_lowering` returns the expected proven-optimal form or NOOPT — EVERY result `bv_prove_equiv`-checked. Run, fail.
- [ ] **Step 2:** Add the laws incrementally; after each, the corpus stays green (no law may break correctness — the proof gate catches an unsound law, but laws should be sound by construction). Run, pass. Commit per coherent law group.

### Task 3.2: Unsigned `x % 2^k → x & (2^k-1)` and other modulo/bitwise reductions, end-to-end
**Files:** `opt/ser_egraph.iii`, `cg_r3.iii` emit.
- [ ] **Step 1 (test):** `x % 8u64` (unsigned) → emits `and $0x7` (objdump), proven ≡ via bv_bits, runs identically to a real `divq`-remainder over edges. Run, fail.
- [ ] **Step 2:** Add the law + the `and`-immediate emission. Rebuild. objdump + corpus green. Commit.

### Task 3.3: The "point at anything" gate — compile the whole tree and an external corpus
**Files:** Create `COMPILER/BOOT/opt/universality_gate.sh` (a GATE harness, not a proof — it runs the real compiler on un-pre-shaped inputs and checks correctness + gate-greenness).
**Interfaces:** compiles ALL of `STDLIB/iii` + ALL of `COMPILER/BOOT` (the compiler compiling itself) + every `corpus/*.iii`, and for each: (a) it builds, (b) its KAT/exit behavior is unchanged vs the pre-e-graph baseline (correctness preserved), (c) objdump shows the e-graph reductions where applicable.
- [ ] **Step 1:** Snapshot the pre-e-graph baseline behavior (every corpus exit code) into `opt/_baseline.txt`.
- [ ] **Step 2:** Run the universality gate. Expected: 100% of programs build AND match baseline behavior (correctness is preserved for EVERYTHING) — any divergence is a soundness bug, fixed before proceeding.
- [ ] **Step 3:** Add a few *adversarial* inputs the operator did NOT pre-shape (random expression generators producing arbitrary nested arithmetic/bitwise/div expressions, compiled + run vs an interpreter reference) — the compiler must produce correct results for ALL of them. This is the closest standing analog to "point it at anything." Commit the gate + baseline.

---

## Phase 4 — Production hardening + the standing proof

### Task 4.1: All five gates wired into one production check, run on every change henceforth
**Files:** `COMPILER/BOOT/opt/production_gate.sh`.
- [ ] **Step 1:** Compose: `build_iiis2 --check-corpus` (byte-equiv incl. the udiv falsifier) → `build_iiis3` (`iiis-2 == iiis-3` fixpoint) → `run_corpus.sh` → `build_stdlib.sh` (all ratchets at pin) → determinism firewall → the universality gate (3.3). ALL must be green.
- [ ] **Step 2:** Run it. Fix anything red. Commit only when fully green.

### Task 4.2: Soundness invariant — the compiler can NEVER emit an unproven optimization
**Files:** `cg_r3.iii` (assert), `opt/production_gate.sh`.
- [ ] **Step 1 (adversarial):** temporarily weaken `r3_synthesize_lowering` to skip the proof; confirm the universality gate (3.3) REDDENS (a wrong lowering reaches a program and diverges from baseline). Revert.
- [ ] **Step 2:** Make the proof-gate structurally unbypassable (single choke point; `r3_emit_egraph_form` is only reachable through a `bv_prove_equiv == 1` branch). Commit.

### Task 4.3: The retrospective — replace the inflated headlines with the executed truth
**Files:** `DOCS/III-EIDOS-SESSION-RETROSPECTIVE.md`, memory `project_iii_verification_membrane_real.md`.
- [ ] **Step 1:** Record, with `objdump`/gate evidence: "the e-graph drives cg_r3" is now LITERALLY TRUE (`grep seg_ COMPILER/BOOT` > 0; the peephole is deleted; emission flows through `seg_saturate` + `bv_prove_equiv`). No headline ahead of the artifact. Commit.

---

## Phase 5 — Open-ended self-improvement (the part that is actually new)

With Phase 2-4, the compiler's optimizer is a proving e-graph. Now make it DISCOVER optimizations no human encoded — including magic-number division — purely from the law set + the prover, and have them appear with zero new hand-written rules.

### Task 5.1: General-constant division/mod via discovered magic, proven by bv_bits
**Files:** `opt/ser_egraph.iii` (the multiply-high + magic law as a GENERIC saturation rule, NOT a hand-coded `magicu`), `cg_r3.iii` (mulhi emission).
**Interfaces:** add the law `x / d ≡ MULHU(x, m) >> s` as a *search* the e-graph performs over candidate (m,s) with the bound checked by `bv_prove_equiv` — the e-graph proposes, bv_bits disposes. The point: the magic is FOUND + PROVEN by the organ, never transcribed by a human.
- [ ] **Step 1 (test):** `x/7u64` (a real codebase divisor) lowers to a `mulq; shr` sequence whose result `bv_prove_equiv` == 1 vs `x/7`, and runs identically to a real `divq` over `{0,1,2^63,2^64-1, random×1000}`. Run, fail.
- [ ] **Step 2:** Implement the magic law as a bounded e-graph search proposing (m,s) (e.g. derived from the divisor's bit-length) and ACCEPTING only on `bv_prove_equiv`. Emit `MULHU` (the `mulq`/`%rdx` path) + the correction (the SRA "add" case) ONLY when proven. Rebuild.
- [ ] **Step 3:** objdump `x/7 → mulq …; shr …` (no `divq`); the universality gate stays green (every other division still correct). The magic was discovered + proven + emitted by the organ — `grep magicu` = 0. Commit.

### Task 5.2: Point it at the whole codebase's divisions and let it eliminate them
- [ ] **Step 1:** Recompile all of STDLIB; count `div`/`idiv` in the archive before/after. Every CONSTANT divisor (pow2 and non-pow2) is now reduced; only variable/signed divisions remain, each proven-or-naive.
- [ ] **Step 2:** Universality gate + production gate green. Record the count delta with objdump evidence. Commit.

### Task 5.3: A second un-encoded optimization class, to prove generality (not a one-off)
- [ ] **Step 1:** Pick a class NOT hand-anticipated (e.g. `(x*a) + (x*b) → x*(a+b)` fusion, or `((x<<k)>>k)` masking, or reciprocal-mod). Confirm the existing law set + prover ALREADY produce it (or add ONE generic law, never a special case). Run on real code, objdump, gate-green. Commit.

---

## Phase 6 — Self-verification (the membrane verifies the optimizer, honestly)

The verification membrane's HONEST role (the retrospective: it is complete explicit-state MC on ≤64 states, no real induction): use it for what it genuinely is — verify a finite-state invariant of the optimizer's own control, not "unbounded" anything.

### Task 6.1: Model the lowering decision as a transition system; prove the soundness invariant
- [ ] **Step 1:** Encode "lowering state": {built-term, saturated, extracted, proved, emitted}. Invariant P: emitted ⇒ proved. Feed to `ser_tgraph.stg_bmc` over the (small, finite) decision FSM; BMC must find NO reachable `emitted ∧ ¬proved` state (the structural soundness choke point of 4.2, machine-checked).
- [ ] **Step 2:** Honestly label it: "finite-state safety of the lowering pipeline," not "unbounded proof." Commit.

---

## Self-Review

- **Spec coverage:** the operator's standard — drives the real compiler (Ph2), for everything (Ph3, 3.3 universality), no script in the proof loop (the proof is the production+universality gates on un-pre-shaped code, Ph3.3/4.1), both twins consistent (Ph0), production-ready every commit (4.1), can't choose/rig the proof (3.3 compiles ALL code + random adversarial inputs), works independently (the e-graph is IN the compiler, Ph2). Covered.
- **No-island check:** Ph1.1 relocates the single `ser_egraph`/`bv_*`; an explicit `grep` asserts one definition. The plan FAILS if a second e-graph appears.
- **No-rigged-proof check:** every emitted optimization passes `bv_prove_equiv` over 2^64 (1.4, 2.2, 4.2); KATs only gate regressions; the standing proof is "compile everything + adversarial randoms, all correct, all gates green" (3.3) — the operator picks the input, not me.
- **Honesty check:** Ph0 fixes the real twin-divergence defect; Ph4.3/Ph6 replace inflated headlines with executed truth and label the membrane honestly. No "revolutionary" claim ahead of an objdump+gate artifact.
- **Hard-parts named (not hidden):** the CDCL SAT engine (1.3) and bit-blasted dividers are real work and the e-graph compile-time budget (2.4) is a genuine risk — both have explicit tasks and measured gates, no placeholder.

## Execution Handoff

Plan saved to `docs/superpowers/plans/2026-06-25-egraph-drives-cg_r3.md`. Two execution options:
1. **Inline, main session (required by no-subagents-on-III)** — execute Phase 0 → 6 in order, each task TDD, each commit behind the full production gate (4.1) once it exists; before then, behind `--check-corpus` + `run_corpus.sh`.
2. The terminal state of this plan is the operator pointing the rebuilt `iiis-2` at ANY code and it producing optimal, proven, correct lowering with every gate green. That — not a KAT — is the proof.

**Phase 0 is the first executable task and has no dependencies. Start there.**
