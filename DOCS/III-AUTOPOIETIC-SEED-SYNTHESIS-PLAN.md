# III — AUTOPOIETIC SEED SYNTHESIS: amputating the C bootstrap into proof-carrying sovereign SVIR
> **STATUS: HISTORICAL RECORD** — an executed campaign plan/ledger, kept immutable as evidence (reunification W6).

> **For agentic workers:** REQUIRED SUB-SKILL: use `superpowers:subagent-driven-development` (recommended) or
> `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for
> tracking. **This plan touches the trusted bootstrap path** (`cg_r3.{c,iii}`, the seed `.c`, the byte-DDC gate);
> per the crash/bootstrap protocol, no trusted-path edit lands without its falsifier reddening first, then greening.

**Authored 2026-06-25 against the LIVE tree.** Every module, line count, and API named below was *read*, not relayed
(orientation log: `ser_egraph` 547L, `ser_absint` 98L, `ser_cegis` 89L, `ser_intent` 89L, `ser_kinduct_sym` 39L,
`ser_causal`, `ser_antiunify` 84L, `bv_ring` 713L, `bv_bits` 986L; seed = 15,483 L of C / ~659 fns; `ccsv.iii` 1,870 L;
`svir_verify.iii` 80 L). Discipline: the theorem-to-machine obligation — no claim without a runnable realization and a
falsifier; calibrated verdicts (PROVEN-IN-CODE / TEST-VALIDATED / NAMED-RESIDUAL); no demos, no placeholders, no
deferrals that aren't explicitly ledgered as residue.

**Goal:** Replace the human-authored C bootstrap seed (`COMPILER/BOOT/{lex,sema,emit,ast,cg_r3,parse}.c`) with a
synthesized, canonical, **proof-carrying SVIR** seed — so the trusted build path contains **no C compiler and no gcc**,
and every synthesized function is either (i) machine-proven equivalent to its translated form *and* differential-tested
faithful to its C spec, or (ii) explicitly ledgered as test-validated non-affine residue under a down-only ratchet.

**Architecture (one sentence):** Translation-Validation → Proof-Carrying Canonicalization → Monotone Amputation: the C
seed is the **specification oracle**, `ccsv` emits a *plausible* SVIR candidate (Leg B, tested), the membrane
(`ser_egraph`/`ser_absint`/`ser_cegis`/`bv_ring`/`bv_bits`/`ser_kinduct_sym` + the **Eidos Temporal Array Theory** memory
model) **proves** a synthesized canonical SVIR equivalent to that candidate (Leg A, proven) and extracts the cost-minimal
form, after which the C is removed from the trusted path and retained only as the offline Leg-B oracle.

**Tech stack:** III `.iii` (self-hosted, `COMPILED/iiis-2.exe`), SVIR (the 80-line total-ISA i64 stack machine), the
existing `bv_bits` bit-blast SAT engine + `bv_ring` 2⁶⁴ polynomial-equality engine, `event_substrate`/`eidos/field`
witnessed log, the sovereign x86 backend + wasm + gcc as **differential oracles only** (never trusted-path deps).

---

## EXECUTION STATUS — built & verified 2026-06-25 (modules EDITED IN PLACE, not new islands)

Per the operator's directive ("no POCs; final modules that can, since the current ones cant; edit the current ones;
production ready and load bearing"), the membrane modules were **lifted in place** rather than spawning `svir_denote`/
`ser_etat`/`ser_absint_aff` siblings. Each capability compiles + runs `=99` per-KAT with a **reddening falsifier
demonstrated** (mutation → RED → reverted → GREEN). Consolidated gate: **`STDLIB/sovir/run_legA.sh` → ALL GREEN (5 KATs)**.

| Plan task | Realized by EDITING | Status | Evidence |
|-----------|---------------------|--------|----------|
| A1/A2 — `sd_denote` + `seq_equiv` (SVIR↔SVIR proof, straight-line, exhaustive over 2⁶⁴) | `ser_kinduct_sym.iii` (lifted from the even/odd POC) | **PROVEN-IN-CODE** | `_seq_equiv_kat`=99; falsifier always-equal→exit 4 |
| A (widen) — signed compares `LT_S/GE_S/LE_S/GT_S` via `sd_slt` | `ser_kinduct_sym.iii` | **PROVEN-IN-CODE** | `_slt_kat`=99 (wrap edges INT_MIN/MAX + `a>ₛb≡b<ₛa`) |
| A (module) — `seq_equiv_mod` over real SVIR module format, tied to the `svir_verify` trust anchor | `ser_kinduct_sym.iii` | **PROVEN-IN-CODE** | `_seq_equiv_mod_kat`=99 (module valid AND fn0≡fn1) |
| B1 — ETAT mechanism 1: affine spatial alias domain `ai_disjoint` (sound one-sided) | `ser_absint.iii` (lifted from shift-linear only) | **PROVEN-IN-CODE** | `_aff_disjoint_kat`=99; falsifier default-disjoint→exit 3 |
| **B0 — PROVE THE PROVER**: ETAT causal-fold memory read-resolution REFINES sequential McCarthy read-over-write, **inductively** (64-bit depth-independent step over a free symbolic tail = unbounded; 8-bit depth-3 compose grounding) | `ser_causal.iii` (lifted from ripple-collapse to memory-collapse) | **PROVEN-IN-CODE** | `_etat_b0_core_kat`=99; standing teeth (wrong rule rejected) + source-mutation falsifier swap→exit 2, reverted→99; `iii_math_rigor`=PROVEN-IN-CODE |
| **B4 — `seq_equiv_mem`**: memory equivalence without McCarthy axioms; disjoint writes commute (proven over all valuations, free tail) and refute when same-index | `ser_causal.iii` (etat_write/etat_mem_equiv) | **PROVEN-IN-CODE** | `_etat_mem_kat`=99; standing teeth (unguarded reorder refuted) + reorder-equal/divergent demos |
| **B2 — CAUSAL TENSORIZATION**: the may-alias cascade `et_commute` = COMMUTE (ai_disjoint) / COLLIDE (concrete fuzz refuter) / SUPERPOSE (B0 fold = δ·serial+(1−δ)·parallel); O(1) epoch crystallization (N disjoint→1 tensor); order-independent holographic root | `ser_causal.iii` + `ser_absint.iii` (addr accessors) | **PROVEN-IN-CODE** | `_etat_b2_kat`=99 (all 3 verdicts + crystallize 1/2 + holo reorder-invariant/geometry-sensitive teeth) |
| **Control flow — IF-diamond** (Algebraic Path Superposition, `mux(C,T,F)`) | `ser_kinduct_sym.iii` (concurrent author; verified by me) | **VERIFIED** | `_if_diamond_kat`=99 (`c?10:20 ≡ (c==0)?20:10`; differing arm refuted) |
| **B3 — HOLOGRAPHIC ORBIT AMPUTATION** (loops, degree-1): fuzz (`ser_petri`) proposes the recurrence, finite differences generalize, the **symbolic guillotine** proves the loop's real step `T(s)==s+Δ` over all 2⁶⁴ → loop replaced by `cf(N)=S₀+N·Δ`; memory-stride lift → B2 tensor descriptor | `ser_antiunify.iii` (composing `ser_petri`+`bv_bits`+`ser_kinduct_sym`+`ser_absint`) | **PROVEN-IN-CODE** | `_au_b3_kat`=99; **piecewise teeth** (fuzz-arithmetic but symbolic-refuted, never amputated) + wrong-Δ refuted. Scope: affine fragment; non-affine DEFERs (CEGIS) |
| **B3 DEGREE-2 — GAUSS, MECHANIZED** (arithmetic-series sums): second finite difference → `cf(N)=S₀+b·N+c·N(N−1)/2`; the **Gauss triangular recurrence** `tri(n+1)==tri(n)+n` bit-blasted over all *representable* n | `ser_antiunify.iii` (`au_amputate_quadratic`/`au_prove_quadratic`/`au_tri_sym`) | **PROVEN-IN-CODE** | `_au_deg2_kat`=99 (triangular + general series proven, `cf(10)=45`, degree-1 not misclassified, off-by-one **refuted**). Real bug was the **induction-domain wrap** (witness `n=2^w−1`, not `tri` internals) — guarded out honestly (no `w`-bit loop runs `2^w` times); parity-correct `tri` (halve the even operand pre-product); 8-bit width (the `n·(n−1)` var·var multiplier is SAT-heavy, recurrence width-independent) |
| **THE CRUCIBLE — B3 ⊗ B2 integration** (Phase 2/3): a strided-memory loop `for k∈[0,N): mem[base+s·k]=v` **crushed to one O(1) holographic tensor hash** — loop & branch eliminated; affine scalar loop → closed form; non-affine → honest defer. Creative key: **prove-then-build** (amputate to *integer* coefficients first, then build in a fresh bit-blast context → no `bb_reset` clobber) | `ser_antiunify.iii` (`au_crucible_stride`/`au_crucible_scalar`) composing B3 + `ser_causal` B2 | **PROVEN-IN-CODE** | `_au_crucible_kat`=99 (loop crushed to nonzero hash, geometry teeth on base **and** stride, scalar `cf(10)=57`, geometric DEFERS). Fixed a real hash collision (stride now folded into the root → injective) |
| **AGNOSTIC TOPOLOGICAL EXTRACTION** (the front-end, the *right* way): the loop body is a BLACK BOX — `au_svir_exec` **executes** it (never parses), the affine δ is read off the behavioral trace (absolute **syntax immunity**), and `au_svir_step_sym`'s symbolic denotation is bit-blasted vs `acc+δ` over 2⁶⁴ (the guillotine) | `ser_antiunify.iii` (`au_svir_exec`/`au_svir_step_sym`/`au_topo_amputate`) composing `ser_petri`+`bv_bits` | **PROVEN-IN-CODE** | `_au_topo_kat`=99: `acc+=5` extracted from behavior + proven; **`acc+2+3` and `(acc+10)−5` extract identically** (syntax immunity); **`acc*2` sampled at 0 fuzzes `+0` but is REFUTED** by the symbolic step (no false crush); non-affine → DEFER. Weaponizes the halting problem: observe finite trajectory → prove infinite destiny → skip execution |
| **THE WHOLE-PROGRAM DRIVER — the ZERO-LOOP INVARIANT** (Task F1): walks a real SVIR module opcode-aware, locates each loop *structurally* (`BR_IF…BR` — trivial, not semantic), crushes its body via the agnostic extractor, asserts every loop is gone | `ser_antiunify.iii` (`au_crush_module`/`au_locate_loop_body`/`au_op_width`) | **PROVEN-IN-CODE** | `_au_crush_kat`=99: a real `while i!=0 { acc=acc+5; i=i-1 }` **crushed → zero loops remain (1)**; the geometric `acc*=2` `while` **survives → honest C-backed residue (0)** — the teeth (the driver never falsely reports an artifact gone) |
| **UNIVERSAL TOPOLOGY EXTRACTOR** (Task F2a): the locator made **nesting-aware** — tracks BLOCK/LOOP/IF/END depth, finds each loop's back-edge at its *own* structural level (not the innermost), so multiple sequential loops crush and nested ones delineate correctly | `ser_antiunify.iii` (`au_locate_loop_body` depth-tracking) | **PROVEN-IN-CODE** | `_au_crush2_kat`=99: a module with **two sequential affine `while` loops fully crushed → zero loops remain**; single-loop crush regression intact |
| **NESTED LOOPS — sound boundary** (Task F2b): the nesting-aware locator finds BOTH loops of a nest; the inner (straight-line) crushes, the outer's body holds the inner's control flow so it **honestly defers** — no false crush | `ser_antiunify.iii` (`au_crush_module`+`au_loops_total`/`au_loops_crushed`) | **PROVEN-IN-CODE** | `_au_nested_kat`=99: `while i { while k { acc+=1; k-=1 }; i-=1 }` → `total=2, crushed=1, verdict=0` |
| **THE PARTIAL-EVAL INTERPRETER** (Task F2b core): a concrete structured-control SVIR interpreter (`au_svir_exec_cf`) that **executes nested loops** — follows BR/BR_IF back-edges as real control flow, bounded steps; the inner loop is RUN, not matched | `ser_antiunify.iii` (`au_svir_exec_cf`/`tp_match_end`/`au_tp_set`/`au_tp_get`) | **PROVEN-IN-CODE** | `_au_cf_kat`=99: runs `while i { k=2; while k { acc+=3; k-=1 }; i-=1 }` (i=4) to the true result **acc=24, i drained**. (Bug found by per-op `(op,sp)` trace: binop handler omitted the `p`-advance → ADD/EQ re-ran; one-line fix.) This is the foundation the full outer-crush stands on |
| **COMPOSITIONAL AMPUTATION** (Task F2b complete): the **nested outer-crush** by iterative collapse — measure the inner's net effect (`au_svir_exec_cf`), splice `GET/CONST(net)/ADD/SET` over the inner-loop bytes, crush the now-straight-line outer (`au_topo_amputate`), differential-validate fidelity | `ser_antiunify.iii` (`au_crush_nested` composing the interpreter + the crucible) | **PROVEN ⊗ TESTED** (honest split) | `_au_nestcrush_kat`=99: `while i { k=2; while k { acc+=3; k-=1 }; i-=1 }` → **outer δ=6**; non-reset (varying-trip) inner → `AU_NONE64` (teeth). Per-iteration recurrences PROVEN/2⁶⁴; substitution fidelity TESTED (4-seed differential) — AMPUTATED_PROVEN ⊗ Leg-B, no overclaim |
| **WHOLE-PROGRAM DRIVER + SER_CRUSH_REPORT** (Task F2c operational core): walk a real SVIR module; per top-level loop dispatch nested→`au_crush_nested` / simple→`au_topo_amputate`; skip inner loops (no double-count); **log every loop in a crush/defer ledger** (offset, verdict, δ) — the honest end-state: every loop *crushed (proven)* or *witnessed (residue)* | `ser_antiunify.iii` (`au_crush_report`/`au_body_has_loop`/`au_report_*`) | **PROVEN-IN-CODE** | `_au_report_kat`=99: a 3-loop module → A affine **CRUSHED δ=5**, B nested **CRUSHED δ=6**, C non-affine **DEFERRED (residue, logged)**; `crushed=2, total=3` |
| **RESIDUE-STABILITY INVARIANT** (Task F2c advice #1): FNV-1a fingerprint of the whole ledger — same module→same hash (frozen anchor); any δ-change or verdict-flip moves the root | `ser_antiunify.iii` (`au_report_hash`) | **PROVEN-IN-CODE** | `_au_rhash_kat`=99: deterministic; reddens on delta change AND affine→residue flip |
| **THE GHOST-BUILD over REAL ccsv** (Task F2c): real C → `ccsv` (the actual C→SVIR seed) → `au_crush_svir_module` parses `[nfunc][per-fn:params,nres,blen,body]` and crushes each → the seed's own loops crush/defer | `ser_antiunify.iii` (`au_crush_svir_module`/`au_crush_walk`) + `STDLIB/sovir/run_ghost.sh` | **PROVEN-IN-CODE (real seed)** | `run_ghost.sh` GREEN: a real C file (`while(i<10){acc+=5;i++}` + `acc*=2`) → ccsv → SVIR → **affine loop CRUSHED δ=5, geometric loop DEFERRED residue**, `report_hash=327748354ab7847c`. The opcode tables align exactly (`svir_asm.mjs`: BLOCK=0x40,LOOP=0x41,…). Boundary: crushing the *full* `ccsv.c` needs ccsv's complete self-compilation (Φ1.4 nfunc-completeness) |
| **THE REFINERY — Residue-Stability RATCHET** (Task F2c #1): regenerate the crush ledger from real ccsv output every build; gate its FNV hash against a sealed golden — a `CRUSHED↔DEFERRED` flip or δ change ABORTS the build (the affine-fraction is frozen, the residue versioned) | `STDLIB/sovir/run_residue_gate.sh` (+ `au_report_hash`) + golden `_residue_manifest.golden` | **PROVEN-IN-CODE (live teeth)** | seal → golden `327748354ab7847c`; re-run → `RESIDUE STABLE` (GREEN); a corpus making `geo()` affine → profile `2 crushed/0 deferred` → hash drift → `BUILD ABORT` rc=1. A down-only truth-ratchet on the seed's crushability |
| C4-closure — the **closed synthesis loop**: `cg_synth` proposes, `seq_equiv` certifies over 2⁶⁴, refutes corruption | `ser_intent.iii` (composing `ser_cegis` + `ser_kinduct_sym`) | **PROVEN-IN-CODE** | `_synth_prove_kat`=99 (5 reductions certified, 2 corruptions refuted) |

**This makes the EIDOS-retrospective C4 ("the synthesizer drives the compiler") TRUE for the first time:** the synthesizer
(`cg_synth`) autonomously chooses a strength reduction and the SVIR↔SVIR prover (`seq_equiv`) certifies it sound over all
2⁶⁴ — the apply-half the retrospective recorded as unbuilt is now built, with the prover as the independent backstop that
refutes a corrupted proposal.

**Honest remaining work (NOT yet built — extensions + the severing):** nested-loop + non-canonical-control handling in the
driver (the canonical non-nested `while` is proven) · C0/C1 (canonical SVIR extraction) · D (Leg-B differential on real
ccsv output) · E (amputation ledger + sovereign rebuild) · **F2 — the sovereign severing** (point the driver at the ccsv
C-seed, amputate its affine shadow-stack loops, collapse its memory to epochs, emit a geometrically-static `iiis-0`,
byte-DDC vs the gcc build with no C-compiler in the trusted path; this *is* the full Φ1–Φ7 completion campaign). **DONE &
gated (`run_legA.sh` ALL GREEN, 14 KATs):** the THREE LEGACY WALLS (control flow / memory B0+B4+B2 / loops B3 deg-1 +
Gauss) · the crucible (B3⊗B2) · **agnostic topological extraction** (black-box, syntax-immune) · **the whole-program
driver** (`au_crush_module`): a real `while` loop module crushed to the **zero-loop invariant**, with non-affine loops
honestly C-backed. Tasks F0 + F1 are done; the integration is end-to-end on the canonical loop. Only F2 (the severing of
the real seed = Φ1–Φ7) remains. **Deferred-per-directive end-of-plan batch:** the
full `build_stdlib` corpus regression + determinism reseal + the single commit (the edits are additive — existing
`sks_pres_even`/`ai_route`/`in_propose_shlsub` consumers preserved — so regression risk is low, but the corpus gate is the
real arbiter and runs once at the end).

---

---

## THE CENTRAL DOCTRINE — the two legs, stated before anything is built

The single mistake this plan exists to not repeat is the one the EIDOS retrospective records as **C4 REFUTED**:
"the synthesizer drives the compiler" reached the permanent log unsupported because the *apply-half was unbuilt* and a
proof-claim was made where only a certification existed. The structural defense is to **name two legs and never let one
borrow the other's strength**:

| Leg | Claim | Strength | Discharged by | What it does NOT establish |
|-----|-------|----------|---------------|----------------------------|
| **Leg A — Canonicalization** | `SVIR_candidate ≡ SVIR_canonical` (the synthesized form *is* the translated program) | **PROVEN**, exhaustive over all 2⁶⁴ inputs / all reachable memory states | `bv_bits` miter (straight-line) · `ser_kinduct_sym` (loops) · **ETAT** (memory) · each rewrite law proven once | Says nothing about whether `ccsv` translated the C *faithfully* |
| **Leg B — Translation faithfulness** | `⟦C_fn⟧ ≈ SVIR_candidate` | **TEST-VALIDATED** (gold-standard CPU differential + author-diversity DDC), coverage-measured | objdump→CPU execution over edge battery + seeded sample; second independent translator agrees (Leg-A-proven mutual equivalence) | A *proof* of faithfulness — that needs a formal C semantics (NAMED-RESIDUAL R-AX) |

**Why Leg A cannot be C↔SVIR.** To form `⟦C_fn⟧` as a `bv_bits` circuit you need a formal C semantics. The only artifact
in this stack that turns C into a circuit is `ccsv` itself — so a "C↔SVIR" miter is either `SVIR_candidate ≡ SVIR_canonical`
(sound, but silent about translation) or `ccsv(C) ≡ ccsv(C)` (vacuous). **The proof leg is therefore SVIR↔SVIR by
construction.** Faithfulness is a *testing* obligation (Leg B), strengthened by author diversity, never a proof obligation
of this plan.

**What amputation actually buys, stated honestly.** A function's C is discarded from the trusted build path when it has
**both**: (a) a **Leg-A certificate** — its canonical SVIR is machine-proven equivalent to its `ccsv` candidate; and
(b) a **Leg-B pass** — the candidate runs bit-identical to the C reference on the differential **and** a second
independent translator's SVIR is Leg-A-proven equivalent to it. After amputation the trusted seed =
`{canonical SVIR + Leg-A certs + Leg-B battery}`; C is retained **only** as the offline Leg-B spec oracle. The defensible
claim is: *"a sovereign seed whose synthesis is mathematically proven sound and whose faithfulness to the original C is
validated to differential-plus-diversity strength"* — **not** *"mathematically proven equivalent to the C from bare metal."*
The latter is R-AX, named below, not delivered here.

**The transport (why shipping the canonical is safe even though Leg B tested the candidate).** Leg B differential-tests
the `ccsv` *candidate*; the seed ships the *canonical*. Soundness transports because Leg A proves
`candidate ≡ canonical` **exhaustively over all inputs** — so every input Leg B exercised (and every input it did not)
yields identical observable behavior on the canonical. The canonical inherits the differential pass *by the proof*, not by
re-testing. This is the one place Leg A and Leg B compose: Leg A is what lets the optimized/synthesized form ship under the
tested form's warrant.

**The two ratchets (the honest completion bar).**
- **Sovereignty ratchet — reaches 0.** `#functions still requiring C/gcc in the trusted build path → 0`. Every function
  `ccsv` translates and that passes Leg B is amputatable. Target: **0 C-backed functions in the trusted path.** *Feeder
  dependency:* a function can only enter this pipeline once `ccsv` can **translate** it — so completion-plan **Φ1.2**
  (drive the seed verify-failures 183→0, each fix behaviorally gated) is the **candidate supply** for this plan. The
  ratchet's denominator is the ccsv-translatable set; closing Φ1.2 grows that set to all ~659 functions, and this plan
  consumes it. A function `ccsv` cannot yet translate is neither amputated nor a failure here — it is upstream Φ1.2 work.
- **Proof-coverage ratchet — down-only, names its residue.** `#amputated functions whose canonical SVIR carries a Leg-A
  certificate → up`; equivalently `#functions whose synthesis is only test-validated (no Leg-A cert) → down-only`. This
  does **not** reach 0: recursive-descent (`parse.c`, 3,819 L), hash-table and pointer-chasing fragments lie **outside
  ETAT's sound affine fragment by construction**. Their retained SVIR is the candidate itself, Leg-B-validated, Leg-A only
  for their straight-line/arithmetic sub-terms. Naming this residue up front is the difference between a plan whose
  standards can be met and one that guarantees the "thrown away" outcome.

> **"No other system can do this" — calibrated.** The claim is **engineering-ecology**, not complexity-theoretic. III
> prunes the solver-killing cases (affine aliasing, commuting writes, strided loop effects) *above* the SAT solver via an
> ecology of organs, where legacy monolithic-array SMT pushes the whole memory geometry into the solver at once and hits
> the cliff. The irreducible non-affine residue still reduces to SAT, which is still NP — III does not beat that wall, it
> **routes around the cases that don't need it.**

---

## Global Constraints (every task inherits these verbatim)

- **No third-party deps in the trusted path.** Only libc + III BOOT headers. `gcc`/`node`/`wasm` are **differential
  oracles**, never sovereign-path dependencies. No Python anywhere (memory: `feedback_no_python_assess_manually`).
- **Pin the in-tree compiler.** Every harness pins `COMPILED/iiis-2.exe` (never autodiscovers `iiis`) — the EIDOS
  retrospective's MCP `COMPILE_FAIL` was a stale-compiler artifact; the corpus trap is documented at `run_corpus.sh:24-28`.
- **Determinism, integer-only, no ML.** No statistics, no trained model, no reinforcement, no count-and-promote
  (memory: `feedback_no_observational_learning`). Same input + same seed ⇒ same output on day one.
- **The gold standard is the only independent oracle.** objdump-lift → offline CPU execution over the edge battery +
  seeded random. A self-authored checker never certifies code; `bv_bits` (Leg A) and the CPU (Leg B) are the two
  independent oracles and they prove **different** things (§ doctrine).
- **Every task ends with a falsifier that reddens.** A gate that cannot be reddened by a deliberate mutation proves
  nothing (the EIDOS lesson: "a self-test that can't express the attack is no verification").
- **No trusted-path edit without RED-first.** For `cg_r3.{c,iii}` / seed / byte-DDC changes: write the falsifier, watch
  it redden, then green it. Dual-twin edits land in **both** `cg_r3.iii` and `cg_r3.c` in the same task (the C6 lesson).
- **Edit tool flips LF→CRLF on whole-LF files** — author `.sh` with `bash`/`awk`/heredoc, never the Edit tool.
- **Calibrated verdicts only.** Each banner is PROVEN-IN-CODE / TEST-VALIDATED / NAMED-RESIDUAL with a file:line or a
  command. No DECORATIVE claim survives review (this plan is itself a Φ3 conscience artifact).

---

## File Structure (what gets created / modified, and its one responsibility)

**New modules (the synthesis-equivalence kernel):**
- `STDLIB/sovir/svir_denote.iii` — **denotation**: lift one SVIR function → a `bv_bits` circuit (`⟦SVIR⟧`), straight-line
  fragment. The foundation of Leg A.
- `STDLIB/sovir/svir_equiv.iii` — **Leg-A core**: `seq_equiv(a,b)` builds the miter `⟦a⟧ ≠ ⟦b⟧` and checks UNSAT;
  emits/serializes a Leg-A certificate.
- `STDLIB/iii/numera/ser_etat.iii` — **Eidos Temporal Array Theory**: memory-as-causal-fold (the model-soundness lemma +
  the three mechanisms); the only memory theory Leg A is allowed to use.
- `STDLIB/iii/numera/ser_absint_aff.iii` — **affine spatial index domain** (interval+stride+congruence) extending
  `ser_absint`'s shift-linear abstract with `ai_disjoint`.
- `STDLIB/sovir/svir_egraph.iii` — **SVIR e-graph**: `ser_egraph` lifted from arithmetic terms to SVIR programs (control +
  memory e-nodes); proof-carrying rewrite laws.
- `STDLIB/sovir/seed_synth.iii` — **the per-function synthesis driver**: candidate → denote → saturate → extract canonical
  → `seq_equiv`-prove → certificate.
- `STDLIB/sovir/seed_ledger.iii` — **the amputation ledger + two ratchets** (per-function status, down-only enforcement).

**New harnesses (gates; `bash`/`awk`, pinned compiler):**
- `STDLIB/sovir/run_seed_autopoiesis.sh` — the phase meta-gate (Leg A certs verify + Leg B differential + ratchets +
  sovereign rebuild byte-DDC).
- `STDLIB/sovir/run_etat_soundness.sh` — the prove-the-prover gate for ETAT (B0) and its wrong-resolution falsifier.
- `STDLIB/sovir/run_legA_teeth.sh` / `run_legB_diff.sh` — the two legs' standalone teeth + differential.

**Modified (trusted-path; dual-twin discipline):**
- `STDLIB/sovir/ccsv.iii` — completeness fixes from Φ1 (every source fn EMITTED), `CALL_INDIRECT` support; the candidate
  emitter for Leg B.
- `STDLIB/sovir/svir_verify.iii` — `CALL_INDIRECT` opcode acceptance (structural).
- `COMPILER/BOOT/cg_r3.{iii,c}` — **only** the C6 unsigned-division twin-divergence fix (the standing soundness hole), and
  only with the unsigned-`u64`-div KAT added to `stage1_corpus` as its falsifier.
- `DOCS/III-COMPLETION-PLAN.md` — Φ1 exit gate upgraded from "translate + byte-DDC" to "synthesize + Leg-A cert + Leg-B
  + byte-DDC"; this doc referenced as the R1-deep realization.
- `DOCS/III-TCB.md` (new, Φ7) — the honest trust floor incl. Leg B's test-validated status and R-AX.

---

# PART I — FOUNDATIONS: the SVIR↔SVIR proof kernel (Leg A, straight-line)

### Task A0 — Formalize the A/B split as a machine artifact, not prose

**Files:**
- Create: `STDLIB/sovir/seed_ledger.iii`
- Create: `DOCS/III-SEED-AMPUTATION-DOCTRINE.md` (the doctrine table above, as the gate's spec)
- Test: `STDLIB/build/sovir/_ledger_kat.iii`

**Interfaces — Produces:**
- `fn sl_status(fn_id: u64) -> u32` → `{0=C_BACKED, 1=AMPUTATED_TESTED, 2=AMPUTATED_PROVEN}`
- `fn sl_set(fn_id: u64, status: u32) -> u32` — **rejects** any transition that raises the proof-residue (down-only) or
  un-amputates a sovereign fn (sovereignty down-only); returns 0 on rejected, 1 on accepted.
- `fn sl_ratchet_sovereign() -> u32` (count still C-backed) · `fn sl_ratchet_residue() -> u32` (count amputated-but-tested)

- [ ] **Step 1 — failing test:** assert `sl_set` rejects a residue-raising transition (PROVEN→TESTED) and a
  sovereignty regression (AMPUTATED→C_BACKED).

```
/* _ledger_kat.iii (excerpt) */
sl_set(7u64, 2u32)                     /* prove fn 7 */
let bad : u32 = sl_set(7u64, 1u32)     /* try to downgrade proof -> must be REJECTED */
let regr: u32 = sl_set(7u64, 0u32)     /* try to un-amputate -> must be REJECTED   */
if bad == 0u32 { if regr == 0u32 { return 99u32 } }   /* both rejected => pass */
return 1u32
```

- [ ] **Step 2 — run, expect FAIL** (`sl_set` not yet down-only): `COMPILED/iiis-2.exe … _ledger_kat.iii` → exit≠99.
- [ ] **Step 3 — implement** the two monotone guards (a status array + the rejection logic).
- [ ] **Step 4 — run, expect 99.**
- [ ] **Step 5 — gate** `run_legA_teeth.sh` records the ledger KAT. (No commit — single end-of-plan commit per directive.)

**Exit gate:** the ledger enforces both ratchets monotonically in code (not in a comment).
**Falsifier:** delete the down-only guard → the KAT's rejected transitions succeed → exit≠99.

---

### Task A1 — `svir_denote`: lift a straight-line SVIR function to a `bv_bits` circuit

This is the foundation: to miter two SVIR programs you must denote each as a `bv_bits` formula. Straight-line first
(no loops, no memory) — the fragment that covers token classification, opcode selection, struct-field width arithmetic.

**Files:**
- Create: `STDLIB/sovir/svir_denote.iii`
- Test: `STDLIB/build/sovir/_denote_kat.iii`

**Interfaces — Consumes** (`bv_bits.iii`, read & confirmed real): `bb_reset(w:u64)`, `bb_var(v:u32)->u32`,
`bb_const(c:u64)->u32`, `bb_and/bb_xor/bb_add(a:u32,b:u32)->u32`, `bb_equal(a:u32,b:u32)->u8`. **Extend `bv_bits` with the
missing straight-line ops it does not yet expose** (`bb_or`, `bb_sub`, `bb_mul`, `bb_shl/shr`, `bb_eq`/`bb_ne` producing a
1-bit result, `bb_select` for IF) — each with its own UNSAT-identity KAT.
**Produces:** `fn sd_denote(svir_ptr: *u8, len: u64, nparam: u32) -> u32` → the `bv_bits` node id of the function's return
value as a formula over symbolic params `bb_var(0..nparam)`. Returns `SD_TOP` (0xFFFFFFFF) if the function leaves the
straight-line fragment (any loop/memory/call opcode) — caller must route those to A-later phases, never silently denote.

- [ ] **Step 1 — failing test:** denote a 3-opcode SVIR `fn add(a,b){return a+b}` and assert its formula equals
  `bb_add(bb_var0, bb_var1)` via `bb_equal == 1`; denote `sub` and assert `bb_equal(add_form, sub_form) == 0`.

```
/* _denote_kat.iii (excerpt) — SVIR bytes hand-assembled: LOCAL_GET 0; LOCAL_GET 1; ADD; RETURN */
let add_svir : [u8;6] = [16u8,0u8, 16u8,1u8, 32u8, 96u8]   /* 0x10 0 0x10 1 0x20 0x60 */
let f : u32 = sd_denote(&add_svir as *u8, 6u64, 2u32)
bb_reset(64u64)
let ref : u32 = bb_add(bb_var(0u32), bb_var(1u32))
if bb_equal(f, ref) == 1u8 { return 99u32 }    /* denotation matches the spec circuit */
return 1u32
```

- [ ] **Step 2 — run, expect FAIL** (denote unimplemented).
- [ ] **Step 3 — implement** `sd_denote` as an abstract stack interpreter over SVIR opcodes that pushes `bv_bits` node ids
  instead of values: CONST→`bb_const`, LOCAL_GET→the param's `bb_var`, ADD/SUB/MUL/EQ/NE→the matching `bb_*`, IF/END→
  `bb_select` over a phi of the two arms (straight-line diamond only), RETURN→the top of stack. LOCAL_SET writes a
  slot-indexed register file of node ids. Any LOAD/STORE/CALL/back-edge → return `SD_TOP`.
- [ ] **Step 4 — run, expect 99.**
- [ ] **Step 5 — gate.**

**Exit gate:** every straight-line SVIR function denotes to a `bv_bits` formula; non-straight-line returns `SD_TOP`
(never a silent wrong denotation).
**Falsifier:** mutate `sd_denote`'s ADD case to emit `bb_xor` → the `add`/`sub` KAT's positive arm reddens (the formula no
longer matches `bb_add`).

---

### Task A2 — `svir_equiv`: the Leg-A miter + certificate (straight-line)

**Files:**
- Create: `STDLIB/sovir/svir_equiv.iii`
- Test: `STDLIB/build/sovir/_equiv_kat.iii` · Create: `STDLIB/sovir/run_legA_teeth.sh`

**Interfaces — Consumes:** `sd_denote` (A1), `bb_equal`. **Produces:**
- `fn seq_equiv(a:*u8, la:u64, b:*u8, lb:u64, nparam:u32) -> u32` → `1` iff `bb_equal(⟦a⟧, ⟦b⟧)==1` (UNSAT miter, proven
  equal over all 2⁶⁴ valuations of every param); `0` if a counterexample exists; `SEQ_TOP` if either side is `SD_TOP`
  (out of the straight-line fragment — **not** "equal", route onward).
- `fn seq_cert(a,la,b,lb,nparam) -> u64` → a certificate handle = a content hash of `(⟦a⟧, ⟦b⟧, miter, UNSAT-witness)`
  on the witnessed `event_substrate` log, so a verifier can replay the discharge independently.

- [ ] **Step 1 — failing test (teeth, both arms):**

```
/* _equiv_kat.iii (excerpt) */
/* POSITIVE: x+x  ==  x<<1 , proven over all 2^64 */
let lhs : [u8;5] = [16u8,0u8, 16u8,0u8, 32u8]       /* LOCAL_GET0; LOCAL_GET0; ADD  -> x+x   */
let rhs : [u8;? ] = /* LOCAL_GET0; CONST 1; SHL */    /* x<<1                                  */
if seq_equiv(&lhs,5u64,&rhs,?,1u32) != 1u32 { return 1u32 }   /* must PROVE equal */
/* NEGATIVE: x+x  !=  x<<2 ; the miter MUST be SAT (gate has teeth) */
let bad : [u8;?] = /* LOCAL_GET0; CONST 2; SHL */
if seq_equiv(&lhs,5u64,&bad,?,1u32) != 0u32 { return 2u32 }   /* must REFUTE */
return 99u32
```

- [ ] **Step 2 — run, expect FAIL.**
- [ ] **Step 3 — implement** `seq_equiv` = `bb_equal(sd_denote(a), sd_denote(b))`, with `SD_TOP` propagation; `seq_cert`
  hashes the miter and `evt_perceive`s it.
- [ ] **Step 4 — run, expect 99** (positive proven, negative refuted).
- [ ] **Step 5 — gold-standard cross-check:** assemble both sides to x86 via the sovereign backend, run over the edge
  battery, confirm the CPU agrees with the proof (the proof says equal ⇒ CPU shows identical outputs; the negative pair
  shows a divergent input). Record in `run_legA_teeth.sh`.

**Exit gate:** `seq_equiv` proves the straight-line fragment exhaustively and its negative arm is SAT-reddenable.
**Falsifier:** replace the miter with `return 1u32` (always-equal) → the negative arm stops reddening → gate fails;
**and** the gold-standard CPU run on the negative pair shows divergence the always-true stub hid.

---

# PART II — THE EIDOS TEMPORAL ARRAY THEORY (ETAT): the memory leg of Leg A

> ETAT is the operator's architecture, adopted as Leg A's **only** sanctioned memory theory. It models memory not as a
> McCarthy read-over-write matrix (which forces the SAT solver to branch on every alias and dies on the first loop) but as
> a **causal event stream folded over time** on `eidos/field` — pruning the solver-killers *above* the solver. **Every
> ETAT proof is gated on the B0 model-soundness lemma; no equivalence may use ETAT until B0 is green.**

### Task B0 — PROVE THE PROVER: ETAT model-soundness lemma (gates all of Part II)

The causal-fold read-resolution — *"a read fetches the value from the most recent epoch that mutated this spatial
index"* — must be proven to **refine sequential read-over-write** (the McCarthy semantics) as a **program-independent
meta-theorem**, *before any equivalence built on ETAT counts*. Otherwise every Part-II proof rests on an unproven memory
model. This is the advisor's obligation #1 and the EIDOS retrospective's lesson applied to the prover itself.

**Files:**
- Create: `STDLIB/iii/numera/ser_etat.iii` (the model + the lemma)
- Create: `STDLIB/sovir/run_etat_soundness.sh`
- Test: `STDLIB/build/sovir/_etat_lemma_kat.iii`

**Interfaces — Produces:**
- `fn et_write(epoch:u64, idx_aff:u64, val:u32) -> u64` — append a write event (val = a `bv_bits` node id) to the fold.
- `fn et_read(idx_aff:u64) -> u32` — resolve via "most-recent-mutating-epoch"; returns the `bv_bits` node id.
- `fn et_refines_row_step() -> u8` — **the inductive base+step lemma check** (the soundness-critical form, per the
  adversarial pass): the causal fold must refine McCarthy read-over-write **for a single symbolic write/read step over all
  2⁶⁴ index/value valuations** (`bv_bits` UNSAT miter), and `fn et_refines_compose() -> u8` proves the **composition
  lemma** — if the fold refines ROW after epoch *k*, it refines ROW after epoch *k+1*. Base ∧ step ⇒ refinement for
  **unbounded** traces by induction (discharged via `ser_kinduct_sym`'s inductive-step miter). A *bounded* `nsteps` miter
  is **insufficient** — a long seed function would escape the proven depth; the refinement MUST be inductive so it covers
  every trace length. `fn et_refines_row(unused:u32) -> u8` returns `et_refines_row_step() & et_refines_compose()`.

- [ ] **Step 1 — failing test (the lemma + its wrong-resolution falsifier):**

```
/* _etat_lemma_kat.iii (excerpt) */
/* POSITIVE: the causal fold refines McCarthy read-over-write for a symbolic 3-write/2-read trace */
if et_refines_row(3u32) != 1u8 { return 1u32 }
/* NEGATIVE (prove-the-prover has teeth): a deliberately wrong resolution that returns the
 * OLDEST epoch instead of the most-recent must FAIL to refine ROW (miter SAT). */
et_force_wrong_resolution(1u32)
if et_refines_row(3u32) != 0u8 { return 2u32 }   /* wrong model MUST be rejected by the lemma */
et_force_wrong_resolution(0u32)
return 99u32
```

- [ ] **Step 2 — run, expect FAIL.**
- [ ] **Step 3 — implement** `et_read`/`et_write` as the fold over `eidos/field` write events. `et_refines_row_step` is the
  single-step `bv_bits` miter `et_read(write(σ,i,v), j) XOR mccarthy_row(write(σ,i,v), j)` checked `bb_equal(.,0)` over
  symbolic `σ,i,v,j`; `et_refines_compose` is the inductive-step miter (refines after epoch k ⇒ refines after k+1) via
  `ser_kinduct_sym`. McCarthy ROW is a *local* reference (a `bb_select` chain `i==j ? v : read(rest,j)`) — sound as the
  **spec** because it is the textbook semantics; the lemma proves the *fold* refines it, **inductively over all depths**.
- [ ] **Step 4 — run, expect 99** (base ∧ step ⇒ unbounded refinement; the wrong-resolution model is rejected).
- [ ] **Step 5 — gate** `run_etat_soundness.sh`; this gate is a **precondition** of every Part-II and Part-III task.

**Exit gate:** the causal-fold memory model is machine-proven to refine sequential read-over-write **for unbounded trace
length (base + inductive step, not a fixed depth)**, and a deliberately wrong resolution is rejected by the same check.
**Falsifier:** weaken `et_refines_row` to ignore the index (return 1 always) → the wrong-resolution negative arm stops
reddening → gate fails.

---

### Task B1 — Affine spatial index domain (`ser_absint_aff`): O(1) disjointness, mechanism 1

`ser_absint` today decides only the **shift-linear multiplier** fragment (`ai_mult`/`ai_decide`, read & confirmed). ETAT
mechanism 1 needs an **affine index domain**: map an SVIR address expression to `base + stride·k + c (mod 2^w)` with an
interval on `k`, and decide disjointness of two such addresses in O(1) **without the solver**. The residue (non-affine)
falls to `bv_bits`.

**Files:**
- Create: `STDLIB/iii/numera/ser_absint_aff.iii`
- Test: `STDLIB/build/sovir/_aff_disjoint_kat.iii`

**Interfaces — Produces:**
- `fn aff_of(base:u64, stride:u64, lo:u64, hi:u64, c:u64) -> u64` — pack an affine index descriptor.
- `fn ai_disjoint(p:u64, q:u64) -> u32` → `{0=MAY_ALIAS (defer to bv_bits), 1=PROVEN_DISJOINT}`. **Sound one-sided:** it
  returns 1 only when it can prove non-intersection (e.g. disjoint intervals; equal stride with incongruent residues —
  `i` even / `j` odd; base+range separation). It returns 0 (defer) whenever unsure — it **never** falsely claims disjoint.

- [ ] **Step 1 — failing test (both arms + the residue):**

```
/* _aff_disjoint_kat.iii (excerpt) */
let evens : u64 = aff_of(0u64, 2u64, 0u64, 99u64, 0u64)   /* 2k     */
let odds  : u64 = aff_of(0u64, 2u64, 0u64, 99u64, 1u64)   /* 2k+1   */
if ai_disjoint(evens, odds) != 1u32 { return 1u32 }       /* PROVEN disjoint, O(1)  */
let lo : u64 = aff_of(0u64, 1u64, 0u64, 49u64, 0u64)      /* [0,49] */
let hi : u64 = aff_of(0u64, 1u64, 50u64, 99u64, 0u64)     /* [50,99]*/
if ai_disjoint(lo, hi) != 1u32 { return 2u32 }            /* PROVEN disjoint        */
let ov1: u64 = aff_of(0u64, 1u64, 0u64, 60u64, 0u64)
let ov2: u64 = aff_of(0u64, 1u64, 40u64, 99u64, 0u64)     /* overlap [40,60]        */
if ai_disjoint(ov1, ov2) != 0u32 { return 3u32 }          /* MUST defer, not falsely disjoint */
return 99u32
```

- [ ] **Step 2 — run, expect FAIL.**
- [ ] **Step 3 — implement** the three sound disjointness rules (interval separation; stride-congruence incompatibility;
  base+span separation), defaulting to MAY_ALIAS.
- [ ] **Step 4 — run, expect 99.**
- [ ] **Step 5 — soundness cross-check (teeth on the dangerous direction):** for the overlap case, build the `bv_bits`
  residue miter `∃k1,k2: addr(p,k1)==addr(q,k2)` and confirm it is **SAT** — i.e., the cases `ai_disjoint` defers on are
  genuinely the ones the solver must see. Record in `run_etat_soundness.sh`.

**Exit gate:** `ai_disjoint` is sound one-sided (proven-disjoint ⇒ truly disjoint; everything else defers).
**Falsifier:** make `ai_disjoint` return 1 for the overlap case → the `bv_bits` residue miter (SAT) contradicts it → the
soundness cross-check reddens. *This is the load-bearing falsifier: a false "disjoint" is the one bug that would make all
of ETAT unsound, and the solver residue catches it.*

---

### Task B2 — Causal epoch collapse over memory (`ser_etat` + `ser_causal`): mechanism 2

Two writes that `ai_disjoint`-prove non-aliasing **commute**; `ser_causal` (whose epoch-partition fold is the EIDOS-
retrospective-confirmed-real organ, KAT 2055) collapses commuting writes into **one unordered Memory Epoch** — so the
e-graph models one epoch, not N! interleavings. **The gates (advisor obligation, made explicit, not prose):**
write-write to the **same** location does **not** commute (last-writer-wins matters); **read-write does not commute**.

**Files:**
- Modify: `STDLIB/iii/numera/ser_etat.iii` (add the collapse) · Consumes `ser_causal` `caus_collapse`/epoch API.
- Test: `STDLIB/build/sovir/_etat_epoch_kat.iii`

**Interfaces — Produces:**
- `fn et_commute(w1:u64, w2:u64) -> u32` → 1 iff both are writes **and** `ai_disjoint(idx1,idx2)==1` (never for RW, never
  for same-idx WW).
- `fn et_collapse() -> u64` — fold the pending write stream into epochs (a new epoch boundary at every proven-NON-commuting
  pair); returns the epoch count.

- [ ] **Step 1 — failing test:** three writes `A[2k]=u`, `A[2k+1]=v` (commute), then `A[2k]=w` (same index as #1 ⇒ does
  NOT commute ⇒ new epoch). Assert `et_collapse()` yields exactly 2 epochs, and `et_read(2k)` returns `w` (newest), not
  `u`.

```
/* _etat_epoch_kat.iii (excerpt) */
et_write(0u64, even_idx, U) et_write(0u64, odd_idx, V)   /* commute -> epoch 0 */
et_write(0u64, even_idx, W)                              /* WW same idx -> epoch 1 */
if et_collapse() != 2u64 { return 1u32 }
if bb_equal(et_read(even_idx), W) != 1u8 { return 2u32 } /* newest-epoch wins */
return 99u32
```

- [ ] **Step 2 — run, expect FAIL.**
- [ ] **Step 3 — implement** `et_commute` (gated on B1) and `et_collapse` (epoch boundary on non-commute), reusing
  `ser_causal`'s epoch fold as the partition substrate (no reinvented log).
- [ ] **Step 4 — run, expect 99.**
- [ ] **Step 5 — gate** (precondition: B0 + B1 green).

**Exit gate:** commuting writes collapse to one epoch; same-index WW and any RW force an epoch boundary; reads resolve to
the newest mutating epoch (B0 guarantees this refines ROW).
**Falsifier:** drop the same-index guard from `et_commute` (let same-index WW "commute") → `et_read(2k)` returns the wrong
(older) value → KAT exit 2.

---

### Task B3 — Strided-affine loop-invariant synthesis (`ser_petri`+`ser_antiunify`+`bv_ring`): mechanism 3

The holy grail **for the affine-strided fragment** (and only it). `for i in 0..N: A[i]=f(A[i])` is bypassed without
unrolling: **fuzz** (`ser_petri` runs k=1,2,3, emitting a concrete memory trace on the event log) → **generalize**
(`ser_antiunify` extracts the strided-affine family) → **PROVE** (`bv_ring`/`ser_kinduct_sym` discharge the closed form
∀k<N). **CEGIS discipline (advisor obligation #2, the hard rule):** fuzz+anti-unify only **propose**; a candidate that the
symbolic sieve does **not** discharge means the function **stays C-backed** — never "assume the affine form."

**Files:**
- Modify: `STDLIB/iii/numera/ser_etat.iii` (the loop-effect synthesizer) · Consumes `ser_petri` (sp_emit/sp_edge_*),
  `ser_antiunify`, `bv_ring`, `ser_kinduct_sym` (the inductive-step miter).
- Test: `STDLIB/build/sovir/_etat_loop_kat.iii`

**Interfaces — Produces:**
- `fn et_loop_effect(body_svir:*u8, len:u64) -> u64` → a closed-form **memory-effect descriptor** (∀k<N: `A[k]' = expr(k,
  A[k])`) **iff** `bv_ring`+k-induction discharge it; else `ET_NONE` (stays C-backed).
- `fn et_loop_proven(desc:u64) -> u8` → 1 iff the descriptor carries a discharged ∀N certificate.

- [ ] **Step 1 — failing test (both the grail and its discipline):**

```
/* _etat_loop_kat.iii (excerpt) */
/* AFFINE: A[i] = A[i] + 1  -> closed form discharges, descriptor proven */
let inc_body : [u8; ?] = /* SVIR of A[i]=A[i]+1 */
let d : u64 = et_loop_effect(&inc_body, ?)
if et_loop_proven(d) != 1u8 { return 1u32 }
/* NON-AFFINE: A[i] = A[i-1] + A[i] (prefix-sum, data-dependent) -> MUST return ET_NONE,
 * NOT a false affine descriptor. The discipline: unproven => C-backed. */
let pre_body : [u8; ?] = /* SVIR of A[i]=A[i-1]+A[i] */
if et_loop_effect(&pre_body, ?) != ET_NONE { return 2u32 }
return 99u32
```

- [ ] **Step 2 — run, expect FAIL.**
- [ ] **Step 3 — implement** the three stages; the discharge is `bv_ring` polynomial equality of the proposed closed form
  vs the one-step transition, lifted to ∀N by `ser_kinduct_sym`'s inductive-step miter (UNSAT ⇒ holds for all N). A failed
  discharge returns `ET_NONE`.
- [ ] **Step 4 — run, expect 99** (affine proven; prefix-sum correctly refused).
- [ ] **Step 5 — gate** (precondition: B0–B2 green).

**Exit gate:** strided-affine loop effects are synthesized **and proven for all N**; non-affine loops are **refused**
(returned to the C-backed residue), never falsely amputated.
**Falsifier:** make `et_loop_effect` skip the `bv_ring` discharge and trust the anti-unified guess → the prefix-sum
negative arm returns a (wrong) descriptor instead of `ET_NONE` → KAT exit 2. *This falsifier guards the exact failure mode
the doctrine forbids: a proposer's guess masquerading as a proof.*

---

### Task B4 — ETAT-backed array-equivalence: extend `seq_equiv` to memory-effecting functions

**Files:**
- Modify: `STDLIB/sovir/svir_equiv.iii` (memory path) · `STDLIB/sovir/svir_denote.iii` (denote LOAD/STORE via ETAT).
- Test: `STDLIB/build/sovir/_equiv_mem_kat.iii`

**Interfaces — Produces:** `fn seq_equiv_mem(a:*u8,la:u64,b:*u8,lb:u64,nparam:u32) -> u32` — denote both functions' memory
effects through ETAT (epochs for straight-line memory, `et_loop_effect` descriptors for affine loops), then miter the
**observable post-states** (the set of `(idx, value)` over the proven write-set) **and** the return value. `SEQ_TOP` if any
loop returns `ET_NONE`.

- [ ] **Step 1 — failing test:** two SVIR functions that both zero `A[0..n)` by different strides (e.g. one ascending, one
  descending) → `seq_equiv_mem == 1` (same affine write-set, same values, proven); a third that zeroes `A[0..n-1)` (off-by-
  one) → `seq_equiv_mem == 0` (the missed index is the counterexample).
- [ ] **Step 2 — run, expect FAIL.**
- [ ] **Step 3 — implement** the memory-effect miter atop B0–B3.
- [ ] **Step 4 — run, expect 99.**
- [ ] **Step 5 — gold-standard cross-check:** assemble all three to x86, run, confirm the off-by-one pair diverges on the
  CPU exactly where the proof's counterexample points.

**Exit gate:** memory-effecting straight-line + affine-loop functions are provably equivalence-checked; non-affine →
`SEQ_TOP` (honest, not "equal").
**Falsifier:** drop the boundary index from the observable post-state set → the off-by-one pair stops reddening → KAT
fails; the CPU run still shows the divergence the weakened miter hid.

---

# PART III — SYNTHESIS / CANONICALIZATION: the "newly synthesized pure-math implementation" (Leg A)

### Task C0 — `svir_egraph`: lift the e-graph from arithmetic terms to SVIR programs

`ser_egraph` (read: `seg_reset/seg_var/seg_const/seg_intern/seg_union/seg_best_cost/seg_saturate`) is an **arithmetic**
term e-graph. Synthesis over whole functions needs e-nodes for SVIR **control and memory** (IF-diamonds, CALL, the ETAT
epoch/loop-effect descriptors), and rewrite laws that are **proof-carrying** — each law a SVIR↔SVIR identity discharged
**once** by `seq_equiv`/`seq_equiv_mem` and thereafter trusted.

**Files:**
- Create: `STDLIB/sovir/svir_egraph.iii` (extends/wraps `ser_egraph`)
- Create: `STDLIB/sovir/svir_laws.iii` (the proof-carrying law table)
- Test: `STDLIB/build/sovir/_svir_law_kat.iii`

**Interfaces — Produces:** `fn sve_intern_fn(svir:*u8,len:u64)->u64` (intern a function as an e-class);
`fn sve_law_add(lhs:*u8,ll:u64,rhs:*u8,rl:u64,nparam:u32)->u32` — **admits a rewrite law only if `seq_equiv` proves
lhs≡rhs**, returns 0 (rejected) / 1 (admitted+recorded with its certificate); `fn sve_saturate(class:u64)->u64`
(apply admitted laws to fixpoint).

- [ ] **Step 1 — failing test:** `sve_law_add` **rejects** an unsound law (`x+x ⇒ x<<2`, refuted by A2) and **admits** a
  sound one (`x+x ⇒ x<<1`); after `sve_saturate`, the `x+x` class contains the `x<<1` form.
- [ ] **Step 2 — run, expect FAIL.**
- [ ] **Step 3 — implement** the SVIR e-node kinds + the `seq_equiv`-gated `sve_law_add` + saturation.
- [ ] **Step 4 — run, expect 99** (unsound law rejected, sound law admitted & applied).
- [ ] **Step 5 — gate.**

**Exit gate:** no rewrite law enters the e-graph without a `seq_equiv` certificate — the synthesis is **proof-carrying by
construction**.
**Falsifier:** bypass the `seq_equiv` gate in `sve_law_add` → the unsound `x<<2` law is admitted → the saturated class
contains a non-equivalent form → a downstream `seq_equiv(original, extracted)` reddens (Task C1's invariant).

---

### Task C1 — Cost-minimal extraction = the synthesized canonical SVIR (`ser_intent` lifted)

`ser_intent` (read: contract-as-target-e-class; merge only on a `bv_ring` proof; extract the cheapest fulfilling path) is
**exactly** the synthesis linker — lifted here from the `x*v` contract to **the candidate SVIR's denotation as the
contract**. Extraction yields the cost-minimal **proven-equivalent** SVIR: the "newly synthesized pure-math
implementation."

**Files:**
- Create: `STDLIB/sovir/seed_synth.iii` (the extractor + the per-function invariant)
- Test: `STDLIB/build/sovir/_synth_canon_kat.iii`

**Interfaces — Produces:** `fn syn_canonical(cand:*u8,len:u64,nparam:u32, out:*u8) -> u64` → writes the cost-minimal
extracted SVIR to `out`, returns its length; **post-condition asserted in code:** `seq_equiv(cand, out) == 1` (or
`seq_equiv_mem` for memory functions) — extraction that breaks equivalence is a hard error, never emitted.

- [ ] **Step 1 — failing test:** feed a candidate with a redundant `x*8` (imul) → `syn_canonical` emits `x<<3`; assert
  `seq_equiv(cand, canon)==1` **and** `seg_best_cost(canon) < seg_best_cost(cand)` (cheaper **and** proven-equal).
- [ ] **Step 2 — run, expect FAIL.**
- [ ] **Step 3 — implement** extraction via `seg_best_cost` over the saturated class, with the `seq_equiv` post-condition
  as a runtime assert.
- [ ] **Step 4 — run, expect 99.**
- [ ] **Step 5 — gate.**

**Exit gate:** the synthesized canonical form is cost-minimal **and** carries a `seq_equiv` certificate against the
candidate.
**Falsifier:** corrupt one opcode of the extracted form before the post-condition → `seq_equiv(cand, canon)` reddens →
`syn_canonical` raises the hard error (no silent emission of a non-equivalent "canonical" form).

---

### Task C2 — The per-function synthesis driver (assemble Leg A end-to-end)

**Files:**
- Modify: `STDLIB/sovir/seed_synth.iii` (the driver) · `STDLIB/sovir/seed_ledger.iii` (record AMPUTATED_PROVEN).
- Test: `STDLIB/build/sovir/_synth_driver_kat.iii`

**Interfaces — Produces:** `fn syn_function(fn_id:u64, c_src_region:..., out:*u8) -> u32` →
{`0=FAIL`, `1=AMPUTATED_TESTED` (Leg B passed, Leg A=`SEQ_TOP`/non-affine), `2=AMPUTATED_PROVEN` (Leg A cert + Leg B pass)};
records status in the ledger; writes the retained SVIR to `out`.

- [ ] **Step 1 — failing test:** drive a known straight-line seed function (a `lex.c` token-class fn) end-to-end → status
  `2` (PROVEN); drive a recursive `parse.c` fn → status `1` (TESTED, since Leg A returns `SEQ_TOP`), **never** a false `2`.
- [ ] **Step 2 — run, expect FAIL.**
- [ ] **Step 3 — implement** the pipeline: `ccsv`→candidate (Leg B harness, Part IV) → `syn_canonical` (Leg A) → ledger.
- [ ] **Step 4 — run, expect 99.**
- [ ] **Step 5 — gate.**

**Exit gate:** each seed function lands in exactly one ledger state, the proven/tested distinction is mechanical (a
`SEQ_TOP` can never be recorded PROVEN).
**Falsifier:** force `syn_function` to record `2` when Leg A returned `SEQ_TOP` → the ledger's proof-residue ratchet's
audit (Task E0) finds a PROVEN fn with no certificate on the log → reddens.

---

# PART IV — LEG B: translation faithfulness (test-validated, made rigorous)

### Task D0 — The gold-standard differential harness (candidate SVIR vs C reference)

**Files:**
- Create: `STDLIB/sovir/run_legB_diff.sh` · `STDLIB/build/sovir/_legB_battery.iii` (the edge battery + seeded sampler).
- Reuses the existing 4-oracle `run4`/`r4` gate (ccsv→SVIR→{verify, sovereign-x86 RUN, wasm RUN, gcc RUN}=99).

**Interfaces — Produces:** `run_legB_diff.sh <module>` → per-function: assemble candidate SVIR to sovereign x86, run over
the edge battery + N seeded inputs, diff against the gcc-built C reference; emit `PASS`/`FAIL(input)` + a coverage number.

- [ ] **Step 1 — failing test:** a deliberately mistranslated candidate (one opcode flipped) must FAIL the differential on
  some battery input (teeth).
- [ ] **Step 2 — run, expect the mutant FAILs and the true candidate PASSes.**
- [ ] **Step 3 — implement** the harness (objdump-lift → offline CPU execute, per memory `feedback_machinecode_verify`).
- [ ] **Step 4 — run, confirm PASS/FAIL arms.**
- [ ] **Step 5 — gate.**

**Exit gate:** Leg B is the **only** thing that licenses removing a function's C, and it has teeth (a mistranslation
reddens).
**Falsifier:** shrink the battery to the empty set → the mistranslation mutant passes → the teeth check (Step 1) reddens.

---

### Task D1 — Author-diversity DDC for the seed lineage (strengthen Leg B beyond single-translator test)

A single translator + a test is the weakest faithfulness. **Two independently-authored translators** whose SVIR is
**Leg-A-proven mutually equivalent** make a faithfulness bug have to be replicated independently in both — the standard
"trusting trust" mitigation, and it connects this plan to completion-plan **Φ2**.

**Files:**
- Reuses: `ccsv.iii` (precedence-climbing) + the existing shunting-yard frontend emitter, extended to the seed constructs.
- Create: `STDLIB/sovir/run_seed_ddc.sh` (the seed-lineage axis of `run_ddc.sh`).
- Test: `STDLIB/build/sovir/_seed_ddc_kat.iii`

**Interfaces — Produces:** `run_seed_ddc.sh` → for each seed fn, `seq_equiv(ccsv_svir, shunting_svir) == 1` (proven mutual
equivalence) **or** a byte-identity check where the canonical forms coincide.

- [ ] **Step 1 — failing test:** a one-byte divergence injected into one translator's emission for a seed fn → the mutual-
  equivalence check reddens.
- [ ] **Step 2–4** as the RED→GREEN cycle.
- [ ] **Step 5 — gate** (the `seed` axis of `run_ddc.sh`, Φ2).

**Exit gate:** the two independent emitters agree (proven) on the seed lineage — Leg B faithfulness is diversity-backed.
**Falsifier:** a one-byte emission divergence reddens the seed-DDC axis.

---

### Task D2 — Leg-B coverage measurement + the down-only coverage ratchet

**Files:**
- Modify: `STDLIB/sovir/seed_ledger.iii` (per-fn coverage field) · `run_legB_diff.sh` (emit coverage).
- Test: `STDLIB/build/sovir/_legB_cov_kat.iii`

**Interfaces — Produces:** `fn sl_cov(fn_id:u64) -> u32` (input-space coverage class for the fn's Leg-B validation);
`fn sl_cov_ratchet() -> u32` (count of under-covered amputated fns; down-only).

- [ ] **Steps 1–5:** RED (a fn amputated below the coverage floor is flagged) → GREEN (raise its battery) → gate; the
  ratchet rejects any change that *lowers* aggregate coverage.

**Exit gate:** Leg B's testing strength is **measured**, not assumed; under-covered amputations are a tracked, shrinking
debt.
**Falsifier:** lower a fn's battery below the floor → `sl_cov_ratchet` increments → the gate reddens.

---

# PART V — AMPUTATION + AUTOPOIESIS: discard C, close the loop

### Task E0 — The amputation ledger audit (two ratchets, enforced against the proof log)

**Files:**
- Modify: `STDLIB/sovir/seed_ledger.iii` · Test: `STDLIB/build/sovir/_amputation_audit_kat.iii`

**Interfaces — Produces:** `fn sl_audit() -> u32` → 99 iff: every `AMPUTATED_PROVEN` fn has a replayable Leg-A certificate
on the `event_substrate` log **and** a Leg-B PASS; every `AMPUTATED_TESTED` fn has a Leg-B PASS; no fn claims PROVEN
without a certificate; both ratchets are monotone since the last snapshot.

- [ ] **Step 1 — failing test:** plant a PROVEN fn with no certificate → `sl_audit != 99`.
- [ ] **Steps 2–4** RED→GREEN.
- [ ] **Step 5 — gate.**

**Exit gate:** the ledger's claims are cross-checked against the independent proof log — no self-graded "proven."
**Falsifier:** remove a certificate from the log but leave the PROVEN status → `sl_audit` reddens.

---

### Task E1 — The sovereign seed rebuild (assemble canonical SVIR → iiis-0, byte-DDC vs reference)

**Files:**
- Create: `STDLIB/sovir/run_seed_sovereign.sh` (Φ1.5 of the completion plan, now over the **synthesized** seed).
- Reuses: the sovereign x86 backend; `stage1_corpus` as the byte-DDC fixture.

**Interfaces — Produces:** `run_seed_sovereign.sh` → assemble every retained canonical SVIR to x86 via the sovereign
backend → link iiis-0' → assert iiis-0' is **byte-identical** to the gcc-built iiis-0 on `stage1_corpus` (two independent
builders must agree byte-for-byte — no self-grading).

- [ ] **Step 1 — failing test:** perturb one seed SVIR opcode → the byte-DDC reddens (teeth).
- [ ] **Steps 2–4** RED→GREEN: the synthesized seed builds an iiis-0' that matches.
- [ ] **Step 5 — gate.** **Precondition:** close the C6 unsigned-division twin divergence first (see Task E1a) — otherwise
  the byte-DDC is masking a real soundness hole the corpus doesn't exercise.

**Exit gate:** the synthesized SVIR seed builds a byte-identical iiis-0 with **no C compiler in the trusted path**.
**Falsifier:** one perturbed seed byte reddens the byte-DDC.

#### Task E1a — Close the C6 soundness hole (prerequisite, dual-twin)

`cg_r3.c` emits signed `idivq` for **all** `DIV`; `cg_r3.iii` has the unsigned fix. They diverge on `u64` division; the
byte-check passes only because `stage1_corpus` never exercises it. Per the dual-twin rule, fix **both** twins in one task
and add the unsigned-`u64`-div KAT to `stage1_corpus` **as the falsifier** (it reddens the byte-check until the seed is
fixed — that is the point).
- [ ] Add `58_udiv_highbit.iii`-class KAT to `stage1_corpus` → confirm it **reddens** the current byte-DDC.
- [ ] Back-patch `cg_r3.c` `DIV`/`MOD` to branch on signedness (mirror `cg_r3.iii:2200-2205` `xorl %edx; divq`).
- [ ] Confirm the byte-DDC **greens** and the unsigned KAT runs `=99` on both twins.

---

### Task E2 — `ser_autopoiesis` wires the self-regeneration loop

**Files:**
- Modify: `STDLIB/iii/numera/ser_autopoiesis.iii` (the loop) · Test: `STDLIB/build/sovir/_autopoiesis_kat.iii`

**Interfaces — Produces:** `fn ap_regenerate() -> u32` → 99 iff III, starting from `{retained canonical SVIR + Leg-A certs
+ Leg-B battery}` and **no C**, reproduces a byte-identical seed (the fixpoint), with `sl_audit==99` throughout. This is the
autopoiesis claim: the system synthesizes its own bootstrap seed from its retained mathematical artifacts.

- [ ] **Step 1 — failing test:** run `ap_regenerate` with the C source directory **unavailable** → must still reach 99
  (proves C is not in the trusted path); with a corrupted certificate → must FAIL (proves the loop checks, not assumes).
- [ ] **Steps 2–4** RED→GREEN.
- [ ] **Step 5 — gate.**

**Exit gate:** the seed regenerates from math alone, with C absent, and the loop rejects a corrupted certificate.
**Falsifier:** corrupt one Leg-A certificate → `ap_regenerate` fails (the loop is checked, not cosmetic — the C5/cosmetic-
event lesson).

---

### Task E3 — Move C to the offline oracle; prove no C/gcc in the trusted build

**Files:**
- Move: `COMPILER/BOOT/*.c` → `COMPILER/BOOT/oracle/` (retained, **untrusted**, Leg-B spec only).
- Create: `STDLIB/sovir/run_no_c_scan.sh` (Φ7 evergreen tie-in) · Modify build scripts to forbid `gcc`/`.c` in the
  trusted seed build.

**Interfaces — Produces:** `run_no_c_scan.sh` → fails on any `gcc`/`cc`/`.c`-compile invocation in the **trusted** seed
build path; passes only when the seed builds from SVIR alone.

- [ ] **Step 1 — failing test:** inject a `gcc` call into the trusted build → the scan reddens.
- [ ] **Steps 2–4** RED→GREEN.
- [ ] **Step 5 — gate.**

**Exit gate:** the trusted seed build is C-free and gcc-free; C survives only as the offline oracle.
**Falsifier:** a `gcc`/`.c` invocation in the trusted path reddens the scan.

---

# PART VI — INTEGRATION WITH THE COMPLETION INVARIANT

### Task F0 — `run_seed_autopoiesis.sh`: the phase meta-gate

Composes, in order, with every preceding falsifier live: `run_etat_soundness.sh` (B0–B1) → `run_legA_teeth.sh` (A2/B4/C0–
C2) → `run_legB_diff.sh` + `run_seed_ddc.sh` (D0–D2) → `sl_audit` (E0) → `run_seed_sovereign.sh` (E1) → `ap_regenerate`
(E2) → `run_no_c_scan.sh` (E3). Exit 0 iff every leg is green **and** both ratchets are at their target/snapshot.
- [ ] Author the meta-gate; confirm each component's falsifier still reddens the whole.
**Falsifier:** any single component falsifier reddens `run_seed_autopoiesis.sh`.

### Task F1 — Fold into `run_completion.sh` (supersede the translate-only Φ1)

Replace the completion invariant's `run_seed_sovereign.sh` (translate-only) line with `run_seed_autopoiesis.sh`
(synthesize + Leg-A cert + Leg-B + amputation). Update `DOCS/III-COMPLETION-PLAN.md` Φ1's exit gate text to the two-leg
standard and reference this doc as the R1-deep realization.
- [ ] Edit the invariant; confirm `run_completion.sh` still composes (every other phase gate unchanged).

### Task F2 — `DOCS/III-TCB.md`: the honest trust floor

State the irreducible TCB: CPU/microcode + OS loader (silicon is the only trusted thing left); **Leg B is test-validated,
not proven** (diversity-backed); **R-AX** (formal C semantics → per-construct `ccsv` soundness lemmas → a real C↔SVIR
proof) is the named, undelivered residual that would raise Leg B from TEST-VALIDATED to PROVEN. Nothing above the silicon
is trusted-by-assertion; everything is either proven (Leg A), diversity-tested (Leg B), or ledgered residue.
- [ ] Author `III-TCB.md`; the placeholder scanner (Φ7) confirms no `TODO`/`stub` in the load-bearing synthesis modules.

---

## ARCHITECTURE DECISION RECORDS

**ADR-1 — The proof leg is SVIR↔SVIR, never C↔SVIR.** *Status:* Accepted. *Context:* denoting `⟦C_fn⟧` needs a formal C
semantics this stack does not have; the only C→circuit path is `ccsv`, making any C↔SVIR miter vacuous or self-referential.
*Decision:* Leg A proves `candidate ≡ canonical` exhaustively; Leg B tests `C ≈ candidate`. *Consequence:* the headline
claim is "synthesis proven sound + faithfulness diversity-tested," not "proven equivalent to the C." *Alternative
rejected:* claim full C↔SVIR proof — this is exactly the C4 overclaim, refutable by `grep`. *Precision (adversarial-pass
sharpening, hypothesis H8):* "PROVEN" means proven at the **SVIR-denotation level** (`sd_denote` opcode semantics). The
binary-level guarantee additionally rests on (i) `sd_denote` faithfully modeling each opcode and (ii) the sovereign x86
backend assembling each opcode faithfully — both are **Leg-B-tested** (the CPU differential runs the *real* assembled
binary), not Leg-A-proven. So the certificate transports to the binary exactly to the strength of Leg B's coverage of the
backend; a backend bug on an untested input is the same residual class as any Leg-B faithfulness gap (R-AX would close it
by a verified backend + formal opcode semantics). This is named, not hidden.

**ADR-2 — Memory is a causal fold (ETAT), not a McCarthy matrix.** *Status:* Accepted. *Context:* read-over-write forces
the SAT solver to branch on every alias → cliff on the first loop. *Decision:* affine spatial partitioning (B1) →
commuting-write epoch collapse (B2) → strided-affine loop-effect synthesis (B3), solver only on the non-affine residue.
*Consequence:* the affine fragment (arena bumps, struct copies, array fills — the compiler's actual memory behavior) is
tractable and proven; the non-affine residue (pointer-chasing, hash tables) is named and stays test-validated. *Gated by:*
the B0 model-soundness lemma (prove the prover) — no ETAT proof counts until B0 is green.

**ADR-3 — Two ratchets, not "0 C-backed."** *Status:* Accepted. *Context:* recursive-descent and pointer-chasing fragments
are outside ETAT's sound fragment by construction. *Decision:* sovereignty ratchet → 0 (C fully removed from the trusted
path); proof-coverage ratchet down-only with the non-affine residue named. *Consequence:* the completion bar is reachable;
the residue is explicit, not hidden — the standard the user set ("standards met or thrown away") can actually be met.

**ADR-4 — Proof-carrying laws only.** *Status:* Accepted. *Decision:* no rewrite enters the SVIR e-graph without a
`seq_equiv` certificate (C0); extraction asserts the certificate against the candidate (C1). *Consequence:* synthesis is
correct by construction, not by post-hoc audit.

---

## RISKS

| Risk | Impact | Mitigation |
|------|--------|------------|
| **Leg A↔Leg B seam re-blurs into a C↔SVIR overclaim** | The C4 failure recurs in the permanent log | The doctrine table is a machine artifact (A0 ledger); `sl_audit` (E0) mechanically forbids "PROVEN without certificate"; iii_math_rigor/iii_adversarial_verify run against the seam (below) |
| **ETAT model unsound** (a false `ai_disjoint`) | every memory proof is hollow | B0 prove-the-prover lemma gates all of Part II; B1's load-bearing falsifier is the `bv_bits` residue catching a false "disjoint" |
| **`bv_bits` blows up on a non-affine residue** | a real seed fn neither proves nor refutes in time | bounded miter depth + a timeout that routes to `SEQ_TOP` (TESTED), never a false "equal"; the fn stays in the proof-residue ratchet |
| **Anti-unification guess trusted as proof** (mechanism 3) | a wrong closed-form amputates a fn unsoundly | the CEGIS hard rule (B3): no discharge ⇒ `ET_NONE` ⇒ C-backed; the prefix-sum falsifier guards exactly this |
| **Dual-twin drift** (`cg_r3.c`/`.iii`) | a fix lands in one twin (the C6 hole) | E1a fixes both twins in one task + the unsigned KAT as the standing falsifier in `stage1_corpus` |
| **Scale** (15,483 L / ~659 fns) | the campaign stalls | Pareto by fragment: arithmetic + affine-memory first (highest proof yield), recursive-descent last (test-validated); the two ratchets show monotone progress every cycle |
| **A green build assumed, not run** (the C7 sin) | a claim stands on an unrun bootstrap | per the directive, ONE rebuild/test at the end — but `run_seed_autopoiesis.sh` is that test, and no banner in this doc is marked green until it runs |

---

## THE COMPLETION INVARIANT FOR THIS PLAN

This plan is **complete** when `run_seed_autopoiesis.sh` is green and is itself built by the sovereign toolchain:

```
run_seed_autopoiesis.sh  ⇐  ALL of:
  run_etat_soundness.sh        (B0–B1: the prover is proven sound; false-disjoint reddens)
  run_legA_teeth.sh            (A2/B4/C0–C2: SVIR≡SVIR proven; every law & canonical form certified)
  run_legB_diff.sh             (D0/D2: candidate≈C tested, coverage-measured, mistranslation reddens)
  run_seed_ddc.sh              (D1/Φ2: two independent emitters agree, proven)
  sl_audit                     (E0: ledger cross-checked vs the proof log; no self-graded PROVEN)
  run_seed_sovereign.sh        (E1: synthesized SVIR builds byte-identical iiis-0, C6 closed)
  ap_regenerate                (E2: seed regenerates from math with C absent; corrupt cert reddens)
  run_no_c_scan.sh             (E3/Φ7: trusted build is C-free and gcc-free)
  run_corpus.sh                (determinism + corpus regression green — E1a touches both cg_r3 twins)
  [ratchets] sl_ratchet_sovereign()==0  AND  sl_ratchet_residue() at-or-below snapshot
```

**Campaign sequencing (the Pareto order — highest proof-yield and lowest risk first):** (1) **`emit.c`** (913 L, the
smallest, mostly straight-line opcode emission — fastest Leg-A wins, shakes out A1/A2/D0); (2) **`cg_r3.c`** arithmetic
fragment (3,940 L but the densest strength-reduction surface — where the existing e-graph/absint/cegis already prove laws,
so the highest Leg-A-certificate yield) — and E1a's C6 fix lands here; (3) **`lex.c`/`sema.c`** (token/type logic — mixed
straight-line + affine-memory, exercises ETAT B1–B2); (4) **`ast.c`** (2,853 L — node construction, arena-bump memory, the
heart of ETAT B3's strided-affine fragment); (5) **`parse.c`** LAST (3,819 L recursive-descent — the largest non-affine
residue; amputated on Leg B, Leg-A only for its straight-line sub-terms). Each module is a sub-campaign with its own
`sl_ratchet` snapshot, so progress is monotone and visible every cycle.

When this is green, the bootstrap seed is a **synthesized, canonical, proof-carrying SVIR organism**: its synthesis is
machine-proven sound (Leg A, exhaustive over 2⁶⁴ + ETAT memory), its faithfulness to the original C is validated to
differential-plus-author-diversity strength (Leg B), the C language is removed from the trusted path (retained only as the
offline oracle), and the only trusted thing left below it is the silicon — with the single honest residual (R-AX, formal C
semantics) named, not hidden. **This is the amputation the operator described, built to the strength the mathematics
actually licenses — no more, and no less.**

---

## SELF-REVIEW (run against the doctrine + the spec)

1. **Spec coverage** — operator's five phrases each map to a task: "point ser_egraph+ser_absint at the C-seed" → C0/B1;
   "ingest the semantic intent" → Leg B candidate + the contract-as-denotation (C1); "prove equivalent to a synthesized
   pure-math SVIR" → Leg A (A2/B4/C1, **SVIR↔SVIR, the honest form**); "discard the human artifact" → E3; "sovereign,
   proven from bare metal" → E1/E2/F2 (with R-AX naming the ceiling). ETAT's three mechanisms → B1/B2/B3, gated by B0.
2. **Placeholder scan** — the `[u8;?]`/`?` markers in test excerpts are byte-length-to-be-assembled, not logic
   placeholders; every task has concrete signatures, an exit gate, and a reddening falsifier. No "add error handling,"
   no "similar to Task N," no undefined types.
3. **Type/seam consistency** — `seq_equiv`/`seq_equiv_mem` return `{0,1,SEQ_TOP}` uniformly; `SD_TOP`/`ET_NONE`/`SEQ_TOP`
   propagate (never collapse to a false "equal"); ledger states `{C_BACKED, AMPUTATED_TESTED, AMPUTATED_PROVEN}` are used
   identically in A0/C2/E0. The Leg A/B split is crisp from the doctrine table through every claim.
4. **The seam** — flagged for the conscience pass: iii_math_rigor + iii_adversarial_verify run specifically against
   "could an AMPUTATED_PROVEN ever be recorded without a real SVIR↔SVIR certificate, or could Leg B's TEST be narrated as
   a proof?" — the exact place the overclaim wants to creep back in.

## THE FOUR EPOCHS — cores built one-at-a-time (2026-06-26), full + gated, no stubs

| Epoch | What it IS (core, gated) | Realization | Verdict | Falsifier (live) |
|---|---|---|---|---|
| **I — Immutable Substrate** (Merkle-Sealed TCB) | binary hash tree over the crush certificates; genesis root; leaf membership proof; admission gate refusing drift | `ser_antiunify.iii` (`au_report_merkle_root`/`au_merkle_open`/`au_merkle_check`/`au_tcb_seal`/`au_tcb_admits`) | **PROVEN-IN-CODE** | `_au_tcb_kat`=99: tampered leaf REJECTED; drifted report admission REFUSED |
| **II — Autopoietic Annealing** (proof-carrying minimizer) | constant-propagate the netlist via EXACT algebraic folds (CEGIS-safe: no likelihood, no ML); ratchet circuit toward minimal | `ser_antiunify.iii` (`au_netlist_fold`/`au_netlist_live`) | **PROVEN-IN-CODE** | `_au_fold_kat`=99: `(2*3)+5` cools to ONE wire, eval preserved; `i*(2+3)` folds, `i*5` preserved |
| **III — Constraint Crystallization** | define intent → synthesizer proposes → SVIR↔SVIR prover certifies over 2⁶⁴, refutes corruption | `ser_intent.iii` (`in_certify`, = `cg_synth` ⊗ `seq_equiv`) — **already realized** | **PROVEN-IN-CODE** | `_synth_prove_kat`=99 (5 certified, 2 corruptions refuted) |
| **IV — Morphic Resonance** (SVIR→hardware) | crushed straight-line SVIR → combinational gate DAG → real Verilog (clockless; the algebra IS the circuit) | `ser_antiunify.iii` (`au_svir_to_netlist`/`au_netlist_eval`/`au_nl_*`) + `crushed_fn.v` | **PROVEN-IN-CODE** | `_au_nl_kat`=99: netlist computes the SAME function as the code over every input |

**Honest scope of the Epochs (cores only — the frontiers above them are named, not faked):** Epoch I's bare-metal
**loader enforcement** (the runtime hook that refuses an un-admitted binary) is not wired; Epoch II's **continuous
background daemon + residue-rewrite proposers** (MCMC-over-residue = the open synthesis problem) is not built — only the
exact-fold minimizer is; Epoch III's **constraint-language front-end** (the UI to *state* invariants) is not built — the
synthesis+certify engine underneath it is; Epoch IV today covers the **combinational/crushed fragment** (a full
SVIR→synthesizable-Verilog for sequential/memory ops remains). Each core is real, gated, and reddens under mutation;
each frontier is a genuine campaign, not a toggle. `run_legA.sh` = **26 KATs ALL GREEN** (the loop-crush family
through the geometric and quadratic rungs + the symbolic-freedom soundness gate; aggregated by `run_membrane_gates.sh`).

## SOUNDNESS AUDIT 2026-07-04 — the frozen-local false crush (found, demonstrated, closed)

**The hole (au_svir_step_sym):** the symbolic denoter pinned every non-accum local to `bb_const(0)`
while the concrete fuzz (au_topo_amputate) samples only 4 passes with locals EVOLVING from 0.  A body
whose accum update depends on another local — invisibly at the sampled window AND at the pinned point —
passed both filters:  `acc = acc + 5 + (i & ~3); i = i + 1` fuzzes 7,12,17,22,27 (affine, delta 5) and
symbolically reduces to `s + 5` at `i := 0`, so `bb_equal` PROVED the affine conjecture.  The real orbit
adds `5 + (i&~3)` from i=4 on: acc(5) = 36 against the "proven" cf(5) = 32.  This violated the module's
central claim ("a fuzz mis-extraction is REFUTED, never crushed").

**Demonstrated by execution (pre-fix):** `_au_symfree_kat` exit **1** — its orbit-truth check (0) passed
(36, the divergence is real) and check (1) caught `au_topo_amputate(ADV) == 1` (FALSE CRUSH).

**The fix:** the denoter now materialises each first-READ local as a FRESH `bb_var` (accum = var 0,
others lazily 1..7) — the guillotine quantifies over ALL entry states of every local the body reads
(bv_bits carries `BB_MAX_INPUTS = 8` shared input words).  More than 7 non-accum read locals → honest
DEFER (capacity is never a verdict); a poisoned `bb_equal` (0xFF) also maps to DEFER, never to
"refuted", never to a crush.  Affine crushes whose accum cone ignores the other locals are UNCHANGED
(the extra vars appear on neither side of the miter), so the residue ledger fingerprint
`327748354ab7847c` must remain byte-identical after this fix — verified by `run_residue_gate.sh`.

**Post-fix gate:** `_au_symfree_kat` = 99 (orbit truth; ADV refuted; affine-with-counter still crushes;
9-local body defers), joined to `run_legA.sh`.

## THE GEOMETRIC RUNG 2026-07-04 — loop@geo moves from DEFER(residue) to CRUSHED(mul), with proof

The crush ladder gains its multiplicative rung.  The seed's `geo()` loop (`acc = acc * 2`), carried as
DEFER(residue) in every ghost/ratchet report since F2c, is now CRUSHED on real ccsv output —
`loop@131 CRUSHED(mul) r=2` — and a new `chaotic()` seed function (`acc = acc*acc + 1`, a quadratic
map with no low-degree closed form) keeps the DEFER path witnessed (`loop@218`).  Ledger entries carry
a crush KIND (ADD delta / MUL ratio), folded into both the FNV fingerprint and the Merkle leaves.

**The theorem-to-machine obligation (iii_math_rigor), discharged:**
- *Statement*: for all S₀, r, N in Z/2^64: if the loop's one-step transition satisfies T(s) = s·r for
  ALL s (mod 2^64), then acc_N = S₀·r^N (mod 2^64), r^N by binary exponentiation in the wrap ring.
- *Hypotheses*: (H1) T(s) = s·r over ALL 2^64 states of the accumulator AND all entry states of every
  other read local; (H2) r constant across iterations; (H3) multiplication mod 2^64 is the associative/
  commutative ring product (Z → Z/2^64 ring homomorphism), so induction acc_{k+1} = acc_k·r composes
  exactly — no wrap-edge exclusion (contrast au_tri's parity split).
- *Discharge*: H1 = the SAT miter `bb_equal(step2, bb_mul(v02, bb_const(r)))` over the DENOTED body
  with every read local a fresh bb_var — ser_antiunify.iii:725 (svir path) and :520-526
  (au_prove_recurrence_mul, toy path); H2 = r is one compile-time constant proposed once
  (:498-517, au_is_geometric/au_geo_r — proposal only, never trusted); H3 = au_pow_wrap :483-496
  computes the same ring product (`*` is the machine's mod-2^64 multiply).
- *Realization*: au_closed_geometric :518 (cf evaluator), au_amputate_geometric :528 (toy pipeline),
  au_topo_amputate rung 2 :715-729 (black-box pipeline), au_crucible_scalar MUL arm.
- *Falsifier (all executed green 2026-07-04)*: `_au_crucible_kat` pins cf(10) = 1·3¹⁰ = 59049 (=99);
  `_au_topo_kat` pins acc*2@seed1 → CRUSHED kind-MUL ratio-2, acc*2@seed0 → REFUTED (the aliased
  +0 proposal dies at the miter), acc^=7 → DEFER (=99); `_au_rhash_kat` pins the PURE-KIND teeth —
  affine acc+=2 vs geometric acc*=2 at identical offsets with the same parameter hash APART (=99);
  the residue ratchet DRIFT-ABORTED on the strengthened recipe (rc=1 against golden 327748354ab7847c)
  and was resealed by the authorized act to 91470249305de7af.
- *Verdict*: PROVEN-IN-CODE.

**Charter guards (honesty preserved):** au_conform_bound defers on a MUL-kind crush
(ser_antiunify.iii:1349 — the conformance intersect is the affine fragment by charter; a ratio is
never misread as an additive delta; `_au_conform_kat` case 3 is the live regression); au_crush_nested
requires an ADD-kind flattened outer (:960 — its splice is additive by construction).

## THE QUADRATIC RUNG 2026-07-04 — the second-difference guillotine (arithmetic sums crush on real ccsv output)

Two more ladder steps, same day, same conscience line:

**Constant shifts denote** (`597ea602`): the symbolic stack carries a shadow const-flag; SHL/SHR by a
DIRECT constant lower to bv_bits' zero-clause remaps (`amount & 63`, the concrete interpreter's exact
semantics), so `acc <<= 1` now crushes by the CROSS-FORM miter (shl circuit == mul circuit over 2^64,
kind MUL ratio 2 — syntax immunity across shift/multiply spelling).  Variable shift amounts stay out of
the fragment (defer).  `_au_topo_kat` B6/B7/B8 pin crush / no-fit-defer / fragment-defer.

**The quadratic rung** — an arithmetic-sum loop's step depends on a coupled local (`acc += i; i += 1`),
so no single-pass law `acc' = f(acc)` exists.  The discharge avoids identifying the coupled local
entirely: denote the body TWICE over one carried symbolic state (`au_sym_pass` composed) and prove

    A2(X) + acc(X) == 2*A1(X) + c        for ALL entry states X  (every read local a fresh bb_var)

— the accumulator's second difference is state-invariant.  Then along any orbit
diff_{k+1} − diff_k = c (each reachable state satisfies the proven identity), so
**acc_N = acc_0 + d1·N + c·tri(N)** exactly over Z/2^64: d1 = the entry state's first increment (ONE
concrete body pass, O(body) not O(N)); tri(N) = N(N−1)/2 exact by the parity-safe halving whose Gauss
recurrence `au_prove_quadratic_gen` already gates (width-independent).  The trace only PROPOSES c
(`au_quad_c`); the miter disposes.  Realization: `au_topo_amputate` rung 3 (ser_antiunify.iii, RUNG 3
block), kind `AU_K_QUAD` = 2 in the ledger (hash + Merkle leaves fold kind, so a QUAD certificate is
distinct from ADD/MUL at the same offset/parameter).

*Falsifier (executed green)*: `_au_quadwalk_kat` = 99 — TRI crushes (kind QUAD, proven c = 1); the
MASKED adversary `acc += (i & 3)` fits the sampled window (2nd diffs 1,1,1 at i = 0..3) but the miter
finds i = 3 (((i+1)&3) − (i&3) is not state-invariant) → REFUTED, never crushed — the same
sampled-window blindness the symfree audit closed, now defeated on the quadratic rung too; TRIDOWN
(`acc += i; i -= 1`) records kind QUAD with wrap-ring curvature c = 2^64−1 in the ledger.
On REAL ccsv output the ghost report reads: `add d=5 / mul r=2 / qad q=1 / DEFER(residue)` —
loops=4 crushed=3 deferred=1; the ratchet DRIFT-ABORTED (rc=1 against 91470249305de7af) and was
resealed by the authorized act to **accfc05092d3597c**.  Verdict: PROVEN-IN-CODE.

## THE STORE RUNG 2026-07-04 — the memory fragment's first rung; the real-seed ratchet fires

The at-scale map said the real seed's loops are MEMORY loops; same day, the first memory rung landed.
A body whose sole memory effect is ONE store per iteration, address advancing by a constant stride,
value constant, IS the affine constant-write family — B2's `aff_of` geometry, behaviorally extracted
(a 64KB zeroed fuzz heap in the concrete interpreter, width-faithful loads incl. sign-extension,
per-pass store capture) and symbolically discharged over ALL entry states by three miters on the
twice-composed denotation:  ADDR2(X) == ADDR1(X) + S,  VAL1(X) == V,  VAL2(X) == V.
cf: N iterations from entry X write exactly { A(X) + S·k : k < N } with value V.

**The honesty gate**: a body that stores can NEVER crush on a scalar rung — a scalar certificate says
nothing about the memory effect (without this gate, executing stores would have let the counter orbit
"crush" store-loops).  Loads are past this rung: the denoter defers on them, so a copy-shaped body
whose zeroed-heap fuzz LOOKS like a constant store still defers (`_au_storewalk_kat` case 6 pins it).

*Falsifiers (executed green)*: `_au_storewalk_kat` = 99 (memset family crushes, certificate components
+ digest binding pinned; sampled-window value AND address adversaries REFUTED at the miters; no-fit /
two-store / load-boundary defers).  legA 27/27.  **The payoff, measured**: on real ccsv(sha256.c) the
`M[i]=0` loop flipped — `loop@458 CRUSHED(sto)` (stride 4, value 0, width 4) — the real-seed ratchet
DRIFT-ABORTED (rc=1 against 45b11a82e112591e) exactly as built, and the authorized reseal moved the
golden to **d82d059e9b1ca497**.  Toy ratchet + ghost byte-stable (no stores in the toy corpus).
Remaining real residue: the `W[t]=M[t]` copy (the load boundary — the named next rung: affine copy)
and the data-dependent schedule/rounds loops (honest residue).

## THE COPY RUNG 2026-07-04 — the pass-through copy certificate; half the real seed's loops carry certs

Rung 5, same day.  A body whose sole memory effect is ONE unsigned load + ONE store per iteration, same
element width, is the AFFINE PASS-THROUGH COPY family when five miters discharge over the twice-composed
denotation — each loaded value denoted as a FRESH input var (quantified over ALL heap contents):
SADDR2==SADDR1+S, LADDR2==LADDR1+S, SADDR1−LADDR1==D, and the pass-through **mod the store width**
(SVAL ≡ LDVAR mod 2^{8W}, both passes).  cf: N iterations copy { L(X)+S·k → L(X)+D+S·k : k<N }, width W.
The honest B2 split: this certifies per-iteration geometry; bulk equivalence for a concrete N needs
region non-overlap, discharged by the CONSUMER via ai_disjoint over the aff_of extents — recorded as
(S, D, W), never claimed past it.

**Two root-causes closed mid-stroke, both measured**: (1) the twice-composed copy denotation built FOUR
64-bit multiplier circuits (~140K clauses) and overflowed BB_STREAM_CAP → 0xFF → false defers; fix: the
denoter encodes mul-by-2^k as bb_shl — bit-identical mod 2^64, ZERO clauses (ccsv's element strides are
always 1/2/4/8), and the geometric miter becomes the already-demonstrated cross-form shl-vs-mul shape.
(2) hexdump of the REAL loop@604 body showed ccsv's assignment normalization inserts `& 0xFFFFFFFF`
before STORE32, so a raw pass-through miter rejects a semantically verbatim copy; fix: both memory
rungs' value miters now compare modulo the store width — the certificate speaks EXACTLY about the
written bytes (a store truncates; higher bits are not an observable effect).

*Falsifiers (executed green)*: `_au_copywalk_kat` = 99 (uniform strided copy crushes, S=4 D=1000 W=4 +
digest binding; window-source-address adversary REFUTED; gather (unequal strides) defers; module walk
records kind COPY); `_au_storewalk_kat` strengthened = 99 (the stride-0 copy body now CRUSHES with its
certificate — case 6's old defer was the rung's own boundary; a TRANSFORMED value (+1) REFUTED; a
sign-extending load DEFERS — the rung's honest boundary).  legA **28/28**.  **The measured payoff**:
real ccsv(sha256.c) `loop@604 CRUSHED(cpy) c=4770580737139109271` — the ratchet DRIFT-ABORTED (rc=1
against d82d059e9b1ca497), authorized reseal → **2a822ee9954efc29**.  The real seed now reads:
`sto / cpy / DEFER / DEFER` — 2 of 4 loops certified; the schedule and rounds loops are data-dependent
honest residue (the recurrence/reduction frontier, a genuine campaign).

## THE BINARY MAP RUNG 2026-07-04 — the multi-effect class opens; 12 of 33 real loops certified

The census named the multi-effect class (5 loops) as the next rung; the SHAPE probe (au_probe_* +
au_fz_* instrumentation) measured it: three of the five are the SAME shape -- 1 store, TWO loads per
pass (aes@2201/2333 byte-width, chacha@1287 32-bit).  That is a BINARY MAP  dst[k] = g(src0[k], src1[k])
(AES AddRoundKey / XOR, chacha add).

Rung 6 (au_map2_guillotine): the geometry is proven affine over the twice-composed denotation (store
addr +Sd, each load addr +S0/S1, all entry states); the value law is a PURITY CERTIFICATE -- the store
value's dependence cone (new bv_bits query bb_cone_var_mask: bit i set iff input var i is in the node's
transitive fan-in) touches ONLY the two load vars, never the induction/accumulator var.  That positional
independence is exactly the map-vs-arbitrary-computation line: dst[k]=src0[k]^k reads the index -> k in
the cone -> REFUSED (never a false map).  g itself is unconstrained; its STRUCTURE is fingerprinted
(bb_struct_into -> FNV) so XOR-map and ADD-map carry distinct certs (the teeth).  Kind AU_K_MAP2=5,
cert (Sd, S0, S1, W, gstruct).  Bulk src/dst disjointness stays the CONSUMER's ai_disjoint obligation.

*Falsifiers (executed green)*: `_au_mapwalk_kat` = 99 -- XOR-map crushes (Sd=S0=S1=4 W=4); ADD-map same
geometry, DIFFERENT g-digest (structure teeth); IDXMAP (value reads i) DEFER[memfit] via the cone;
GATHER (unequal strides) defers; module walk records kind MAP.  legA **30/30**.  **The measured payoff**:
real ccsv output -- aes128 loop@2201 and chacha20 loop@1287 both CRUSHED(map); aes128 loop@2333 (same
shape) HONESTLY REFUTED -- one of its three address families is not affine over all symbolic states
though the 4-sample fuzz proposed a stride (the conscience line at population scale).  The real-seed
ratchet DRIFT-ABORTED (aes+chacha ledgers moved), authorized reseal -> aes128 edcfddbd967f0557,
chacha20 5fa4195c2ac15d0a.  Toy + ghost byte-stable.  **Population now 12 of 33 loops certified**
(add/mul/qad scalar + sto/cpy/map memory).  Remaining multi: hmac@3844 (4-store/4-load) and
ceiling@1487 (4-load/1-store byte-pack) -- distinct shapes, separately evidenced when built.

## THE PACK GENERALIZATION 2026-07-04 — one pure-map law for k sources; 13 of 33 real loops certified

The binary MAP was the nl=2 instance of a general law: ONE affine store whose value is a pure function
of `nl` affinely-addressed loads.  au_map2_guillotine is generalized to au_puremap_guillotine(.., nl):
per-slot affine geometry (each of nl load addresses advances by its own stride, all proven over the
twice-composed denotation) + the same purity cone (store value depends ONLY on the nl load vars) + the
same g-structure fingerprint.  The nl=2 cert digest is byte-identical to the original MAP2 (FNV order
Sd, s0, s1, W, g), so the sealed aes/chacha goldens do NOT move -- verified.  Routing dispatches by the
per-pass load count: 0->STORE, 1->COPY, k>=2->the pure map/pack.

MEASURED ROOT-CAUSE (dbg=4, not theorized): the twice-composed proof allocates 2*nl load vars, so a 4-
load pack (8 load vars + the address locals ~= 10) overran bv_bits' 8-input budget at pass 2's second
load.  Fix: BB_MAX_INPUTS 8 -> 16 (BB_INBASE[16]; the two denoter budget checks -> 16) -- a bounded
capacity bump, no soundness change (more input words, same encoding for the low indices).  The
frozen-local capacity KAT moved with it (_au_symfree WIDE now reads 17 locals to exceed 16).

*Falsifiers (executed green)*: `_au_packwalk_kat` = 99 -- a 3-source XOR map crushes (nloads=3, per-slot
strides pinned); a 4-source XOR map crushes (nloads=4, needs the 16-budget) with a g-digest DISTINCT
from the 3-way (structure teeth); a value XOR'd with the index DEFER[memfit] via the cone.
`_au_mapwalk_kat` (nl=2) still 99; `_au_symfree_kat` capacity teeth re-pinned at 16.  legA **31/31**.
**The measured payoff**: real ccsv ceiling_sha_core.c loop@1487 -- a big-endian byte pack
w = (b0<<24)|(b1<<16)|(b2<<8)|b3 -- CRUSHED(map) nloads=4; the real-seed ratchet DRIFT-ABORTED
(ceiling ledger 1->2 crushed; aes/chacha/toy/ghost byte-stable), authorized reseal ->
ceiling d4a1f4a95816a212.  **Population now 13 of 33 loops certified.**  The last multi shape --
hmac@3844 (4-store/4-load) -- is a multi-STORE body (not the single-store family); a genuinely distinct
rung, evidenced when built.

## THE MULTI-STORE SCATTER RUNG 2026-07-05 — the last multi shape; 14 of 33 real loops certified

hmac@3844 (measured, hexdumped) is a word->bytes big-endian UNPACK: word = src32[818+4L]; then four
byte-stores out[2738+4L+j] = (word >> (24-8j)) & 0xff (ccsv re-loads the word once per byte -> 4 loads,
4 stores).  The inverse of ceiling's PACK, and a multi-STORE body the single-store family does not cover.

Rung 7 (au_scatter_guillotine): a body of ns stores + nl loads per iteration is certified an AFFINE
SCATTER  { dst_s[k] = g_s(src0[k], .., src{nl-1}[k]) : s<ns }  when EVERY store address is affine (its
own stride), EVERY load address is affine, and EVERY store value is a PURE function of the nl loaded
values (each value's dependence cone touches only the load vars, never the induction var).  The ns=1
family (STORE/COPY/MAP/PACK) is untouched -- this is the ns>=2 generalization, added additively so the
sealed ns=1 goldens do not move.  Each g_s is unconstrained; the ns structures are folded (per-store
separator) into ONE digest, so a different scatter (byte order, op) carries a different cert.  Routing
dispatches by per-pass store count: ns>=2 -> scatter, ns==1 -> the load-count dispatch.

*Falsifiers (executed green)*: `_au_scatterwalk_kat` = 99 -- a 4-store word->bytes unpack crushes
(ns=4, nl=1, store strides 4); a 2-store big-endian unpack and its shift-swapped variant crush with
DISTINCT digests (structure teeth); a 2-store constant scatter crushes (ns=2, nl=0); a store value
that reads the index DEFER[memfit] via the purity cone.  `_au_storewalk_kat` updated: its two-store
body now correctly ROUTES to the scatter rung (constant addrs = stride 0 -> a degenerate-but-valid
affine scatter, CRUSHED kind SCATTER) -- multi-store is no longer residue.  legA **32/32**.
**The measured payoff**: real ccsv hmac_sha256.c loop@3844 -> CRUSHED(sca) ns=4 nl=4; the ratchet
DRIFT-ABORTED (hmac 3->4 crushed; every other file byte-stable), authorized reseal ->
hmac bc45d06c85c73db5.  **Population now 14 of 33 loops certified.**  The residue that remains is the
data-dependent compute/rounds class -- the permanent honest residue (cryptographic diffusion), witnessed
by the census (refut / frag / nest), not a rung waiting to be built.
