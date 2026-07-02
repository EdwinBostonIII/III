# SVIR Algebraic Equivalence — Implementation Plan
> **STATUS: HISTORICAL RECORD** — an executed campaign plan/ledger, kept immutable as evidence (reunification W6).

> **For agentic workers:** implement task-by-task; each task ends in a corpus KAT (EXIT=99) and a clean `build_stdlib`. Steps use `- [ ]` tracking.

**Goal:** Extend `seq_equiv`/`sd_denote` (STDLIB/iii/numera/ser_kinduct_sym.iii) so SVIR↔SVIR equivalence handles **control flow, loops, and memory** by *algebra*, never by SAT path-explosion — the three opcode classes `sd_denote` currently punts to `SD_TOP`.

**Architecture:** `sd_denote` lifts a SVIR body to a bv_bits node — the denotation `[[·]]` over Z/2^64. Three extensions, each replacing a legacy SAT trap with a deterministic algebraic form, each **provably sound** and gated so an undecidable case yields `SD_TOP` (never a silent "equal"):
1. **IF/ELSE/END → bitwise-select MUX** (branch-free, no multiplier).
2. **LOOP/BR_IF → proven closed-form recurrence** (fuzz→anti-unify→k-induction, then emit `x₀ + N·Δ`).
3. **LOAD8/STORE8 → causal memory epoch** (writes as events; `ai_disjoint` commute-fold; compare structural e-class IDs).

**Tech stack:** `.iii` (self-hosted), `bv_bits` (Tseitin+CDCL), `ser_absint` (O(1) abstract domain: `ai_decide`/`ai_route`/`aff_of`/`ai_disjoint`), the synthesis triad (`sp_fuzz_det`→`au_*`→`sks_*`), `eidos`/`field` event log, `ser_causal`.

## Global Constraints

- **SVIR v1 opcodes are FIXED** (DOCS/SVIR-V1-CANONICAL.md §2): `IF=0x42 ELSE=0x43 END=0x44 BLOCK=0x40 LOOP=0x41 BR=0x50 BR_IF=0x51 LOAD8=0x80 STORE8=0x81`. We add **denotation**, never new opcodes.
- **Soundness is non-negotiable.** Every extension either returns a node whose `bb_eval` equals the SVIR-v1 reference semantics for *all* inputs, or returns `SD_TOP`. A wrong "equal" is a defect; a conservative `SD_TOP` is acceptable.
- **No multipliers in the miter.** The control MUX is the bitwise select `(Cm & T) | (~Cm & F)`, `Cm = 0 − (C & 1)` — NOT the arithmetic `C·T + (1−C)·F` (that injects a 64×64 multiplier → SAT-infeasible, the very wall we amputate).
- **NO-ML.** Recurrence discovery is deterministic anti-unification + a deductive k-induction discharge; same body ⇒ same verdict.
- Every public addition is `@export`, covered by a corpus KAT, and survives `build_stdlib` carto + coverage gates.

---

## Amputation 1 — Control Flow (IF/ELSE/END → MUX)

**Files:** Modify `STDLIB/iii/numera/ser_kinduct_sym.iii` (`sd_denote`); Test `STDLIB/corpus/2071_svir_branch_equiv.iii`.

**Interfaces produced:** `sd_denote` gains IF/ELSE/END handling; `sd_mux(c,t,f)` helper → bitwise select node.

**Semantics (SVIR v1):** `<c> IF <then> ELSE <else> END`. Stack: `<c>` leaves C; IF pops C; the THEN block net-pushes one value T; ELSE; the ELSE block net-pushes one value F; END pushes the chosen value. Value-if requires the ELSE arm; `IF…END` (no value, side-effecting) stays `SD_TOP` until Amputation 3.

**Denotation:**
- `sd_mux(C,T,F)`: `Cm = bb_sub(bb_const(0), bb_and(C, bb_const(1)))` (broadcast bit0 to all 64), return `bb_or(bb_and(Cm,T), bb_and(bb_not(Cm),F))`. Sound: C∈{0,1} ⇒ Cm∈{0,0xFFFF…F} ⇒ exact select. No multiplier.
- **Abstract prune first (O(1)):** if C is a known constant (`SD_IC`), collapse to T-arm (C≠0) or F-arm (C==0) — the false path is erased, zero MUX nodes.
- Symbolic C: scan to the matching ELSE/END (nesting-depth counter over BLOCK/LOOP/IF…END), denote each arm via the existing stack loop into an if-frame, push `sd_mux`.

**Tasks:**
- [ ] Add `sd_mux` + an if-frame stack (`SD_IFC/SD_IFsp0/SD_IFT`, depth 64); handle 0x42/0x43/0x44 in `sd_denote`; const-collapse path.
- [ ] KAT 2071: `f(c,a,b)= if c!=0 {a+1} else {a+2}` vs a body that computes the same via MUX/arithmetic; prove **equal**; prove a deliberately-different branch **refuted**; a const-true condition collapses (equal to the THEN body alone). EXIT=99.
- [ ] Register in `run_corpus.sh`; `build_stdlib` green.

## Amputation 2 — Loops (LOOP/BR_IF → closed-form recurrence)

**Files:** Modify `ser_kinduct_sym.iii` (`sd_denote` LOOP); Test `STDLIB/corpus/2072_svir_loop_equiv.iii`.

**Semantics:** `while c { b }` → `BLOCK LOOP <c> CONST 0 EQ BR_IF 1 <b> BR 0 END END`. The accumulator state evolves per iteration.

**Denotation (sound recurrence synthesis):**
- Recognize the `BLOCK LOOP … BR_IF 1 … BR 0 END END` idiom; identify the loop-carried local(s) and the trip count N (symbolic input or bound).
- Build the body as a circuit parameterized by the carried state; `sp_fuzz_det` executes it for n=1,2,3; `au_*` anti-unifies the per-step delta Δ (linear: `xₙ₊₁ = xₙ + Δ`).
- **Prove, don't trust:** discharge `xₙ₊₁ = xₙ + Δ` by `sks_prove` (base+step). Only on PROVEN does `sd_denote` push the closed form `x₀ + N·Δ` (Δ constant ⇒ `N·Δ` is a strength-reduced shift/add, SAT-cheap). Non-linear / unproven ⇒ `SD_TOP`.

**Tasks:**
- [ ] LOOP idiom recognizer + carried-state extraction; compose `sp_fuzz_det`/`au_modulus`-style delta read/`sks_prove`; emit `x₀ + N·Δ`.
- [ ] KAT 2072: `sum=0; i=0; while i<N { sum+=4; i+=1 }` proven equal to `sum = N*4` (closed form); a non-constant-stride loop ⇒ `SD_TOP` (honest). EXIT=99.
- [ ] Register; `build_stdlib` green.

## Amputation 3 — Memory (LOAD8/STORE8 → causal epoch)

**Files:** Modify `ser_kinduct_sym.iii` (`sd_denote` mem ops + `seq_equiv_mem`); compose `ser_causal`/`eidos`/`field`; Test `STDLIB/corpus/2073_svir_mem_equiv.iii`.

**Denotation (causal epoch cryptography):**
- Each STORE8 emits a structural write-event `(addr, value)` to the epoch (not a giant state vector). LOAD8 resolves against the current epoch.
- **Commute-fold:** `aff_of` abstracts each write's address region; `ai_disjoint` proves two writes don't alias ⇒ they commute ⇒ fold into an unordered epoch. Aliasing writes keep order.
- **Equivalence:** canonicalize each program's final epoch and compare the **structural e-class ID** (absolutely sound — structural equality in the e-graph), falling back to a sha256 Merkle root only as a cryptographic check. Equal IDs ⇒ memory-equivalent; the SAT solver never sees a McCarthy ITE chain.

**Tasks:**
- [ ] STORE8/LOAD8 → epoch events; `aff_of`+`ai_disjoint` commute-fold; canonical epoch ID; `seq_equiv_mem`.
- [ ] KAT 2073: two functions writing the same disjoint cells in different orders ⇒ equal IDs; an aliasing reorder that changes the result ⇒ refuted. EXIT=99.
- [ ] Register; `build_stdlib` green.

## Verification & Self-Review

- Each amputation pinned by a **positive** (proven-equal), a **negative** (refuted), and a **prune/limit** (collapse or honest `SD_TOP`) case — never negative-only.
- Soundness teeth: a KAT that would force a *wrong* "equal" must instead yield `SD_TOP` or refute (the conscience line: synthesis proposes, the prover/structural-ID disposes).
- Math-conscience (`iii_math_rigor`/`iii_adversarial_verify`) on the MUX-select identity and the recurrence discharge before commit.
- Final `build_stdlib`: carto PASS, run_corpus incl. 2071–2073, coverage non-regressing.
