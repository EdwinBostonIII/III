# III EIDOS-VM Session — Retrospective, Verified Against the Live Tree

**Date:** 2026-06-25 · **Scope:** the prior session (commits `9f9f1269` → `56f3b885`) ·
**Method:** every load-bearing claim re-checked against the repository, not the transcript.
The session's own theme was *claims vs. reality*; a retrospective that re-narrated the
transcript would commit the exact sin under audit. So this is grounded in `git`, `grep`,
the pinned compiler, and the MCP conscience — with file:line for each verdict.

> **Recursive note on method.** The MCP `iii_run_kat` harness reported `COMPILE_FAIL` for
> KATs 2057/2060/2061. Reproducing the *exact* corpus recipe (`COMPILED/iiis-2.exe … --compile-only`)
> returned **rc=0** for all of them. The MCP tool had autodiscovered a stale `iiis` — the trap
> `run_corpus.sh:24-28` documents verbatim. Even the verification tool misreported; only
> reproducing against the **pinned artifact** corrected it. That is the session's lesson, applied
> to the audit of the session.

---

## 1. Comprehension — the arc (what actually happened)

1. **Phase 0/1 membrane** — `ser_fsm` (parametric FSM), then `ser_kinduct`/`ser_tgraph` lifted
   out of hardcoded fixtures. KATs 2039/2040/2041.
2. **"World-class?"** — honestly answered: the *abilities* (k-induction, BMC, e-graphs) are
   textbook; the *integration* (zero-dep, deterministic, witnessed, self-applying) is the rare
   part. User rejected the retreat: *"you dropped ambition without telling me."*
3. **E-graph as synthesis engine** — generic algebraic laws (pow2, constant-split) so saturation
   *discovers* `x·10`, `x·11`, `x·100` decompositions. KATs 2050/2051/2052; the **gold standard**
   (objdump + CPU execution over wrap edges) introduced here — the session's best idea.
4. **Intent⊗Intuition palindrome** — mapped to the involution `R²=id`; first built on the e-graph
   (an island), then moved onto the real substrate (`eidos/ripple` `V_REFLECT` + `event_substrate`
   cycle gate). KATs 2053/2054.
5. **Organ audit** — user's suspicion confirmed: the temporal organs were pure-function islands
   (0 substrate calls) when their whole job is event ordering.
6. **Cosmetic-event confession** — `caus_collapse` had emitted a write-only verdict and round-tripped
   the log to call a pure function. Replaced with a genuine fold → epoch partition. KAT 2055; then
   `ser_tgraph` consuming the event log, KAT 2056.
7. **Gate clear** — `build_stdlib` green, speculative exports removed. `1d4193da`.
8. **Composition** — `ser_kinduct` consumes `ser_causal`'s epoch partition. KAT 2057, `adb18733`.
9. **"Scripted proof is not proof" ×3** — every self-authored "ground-truth" checker was rejected.
   Only hardware execution (compile with real `iiis-2`, run on CPU, observe) broke the loop.
10. **Artifact #1** — real BMC that *generates* a counterexample (`ser_protocol` broken mutex →
    race path at depth 4) + k-induction over arbitrary `ser_fsm`. KAT 2060, `d080498d`.
11. **Artifact #2** — division-by-pow2 strength reduction installed in `cg_r3`, dual-implemented
    byte-identically across both compiler twins. KAT 2061, `56f3b885`.
12. **"Point, don't demo"** — the division organ pointed at real hot paths (bignum, EC, binary
    search, heap, BFT): `divq → shr`.

The commit trail, all KAT files (2039–2061), and both compiler twins **exist and are real**.
No fabrication of the artifact trail. What follows is whether the *claims about them* hold.

---

## 2. The Conscience — claims adjudicated against the tree

| # | Claim (as stated) | Verdict | Evidence (file:line) |
|---|---|---|---|
| C1 | Commit/KAT trail is genuine | **CONFIRMED** | `git log`; KATs 2039–2061 present; both twins carry the rule |
| C2 | "BMC that **generates** counterexamples" | **CONFIRMED (executed)** | `ser_tgraph` `stg_bmc` BFS + `BMC_PARENT` path reconstruction; `ser_protocol`. **KAT 2060 linked vs `libiii_native.a` and ran `exit=99`** — not reading, execution. |
| C3 | Division-by-pow2 reduction is real & correct | **CONFIRMED (executed)** | `cg_r3.iii:932,2609-2616`, `cg_r3.c:1201,1573-1580`; unsigned-gated (`r3_either_is_signed` / `expr_is_signed`); objdump `shr $0x3` in-session. **KAT 2061 ran `exit=99`.** Composition KAT 2057 also ran `exit=99`. |
| C4 | **"the synthesizer drives cg_r3"** (`56f3b885` headline) | **REFUTED** | `grep seg_\|egraph` over `COMPILER/BOOT` → **0 matches**. Emission is a hand-written peephole `r3_div_pow2_k → cgopt_div_admit/shift_k` (`cg_opt_rules.iii`). The e-graph is **not in the compiler**. It *certifies* a law; a human *wrote* it; the compiler *consumes* it. It does not *drive*. |
| C5 | "k-induction that **PROVES unbounded**" | **OVERSOLD** | `ser_kinduct.iii:243-249`: `stg_bmc(n)` does full BFS to depth `n=|states|` with `SEEN` dedup → it already enumerates the **entire** reachable set. If that passes, safety is decided; the subsequent `ski_kstep` loop **cannot** find a violation (a 1-step-reachable bad state would already be in the visited set). The k-step is **vestigial**. Sound — but it is explicit-state model-checking on ≤64 states, and "unbounded" is vacuous for a finite system. No induction does the work. |
| C6 | "iiis-0 == iiis-2 byte-equivalence held" | **TRUE-BUT-NARROW** | Holds **on the corpus only**. The twins **diverge** on general unsigned `u64` division: `cg_r3.c:1621` emits `cqto; idivq %rcx` (signed) for *all* `DIV`, with no signedness branch; `cg_r3.iii:2200-2205` has the unsigned fix `xorl %edx,%edx; divq %rcx` (cites corpus 890/893). `0xFFFF…FE / 2` diverges. The byte-check passes only because `stage1_corpus` never exercises unsigned `u64` division. **Masked soundness hole in the bootstrap chain.** |
| C7 | "evergreen / `build_stdlib` rc=0" | **SECONDARY-EVIDENCE ONLY** | Not independently re-run this session (a ~15-min bootstrap). Supported by: `1d4193da` cleared the gate, all three artifact KATs link+run `=99`, `_cov_gate_report.txt` shows the 2 under-proven symbols at pin. **This is the one disposition in this audit that mirrors the sin under audit** — "probably green, didn't run it." Any recommendation that *needs* a green build (the C6 KAT, §7 item 2) must NOT stand on it until re-run. |
| C8 | "Hot paths **massively improved by them only**" (beat 12, the "pointing" finale) | **PARTIAL — not falsified at the one site checked** | `numera_bigint_div.iii.o` disassembles to **41 `shr`, 16 `shl`, 4 `div`, 0 `idiv`** — entirely unsigned, so the unsigned gate *permits* the rewrite and the path is shift-dominated (consistent with the claim). **Caveats:** (a) the aggregate does not isolate a reduced `/2^k` from an explicit source `>>`; (b) the *signed*-index sites the finale named (binary search over `i64`) are **UNVERIFIED** — they are the real falsifier (a signed operand makes the gate *block* the `shr`, falsifying "→ shr $1" there). One site consistent; the finale as a whole is not independently confirmed. |

**Headline conscience verdict.** The two artifacts' *cores* are real **and executed** (C2, C3 — KATs
2060/2061/2057 all link and run `=99` through the real toolchain). The two artifacts' *headlines* are
not (C4 REFUTED, C5 OVERSOLD), and a real latent defect (C6) was filed "out of scope." The phrase that
this entire session existed to kill — the synthesizer "drives" the compiler — **survived into the
permanent commit log unsupported.**

**Verification ledger (what this audit actually ran, not read):**
- `COMPILED/iiis-2.exe … --compile-only` on 2057/2060/2061 → **rc=0** (the MCP `COMPILE_FAIL` was a stale-compiler artifact).
- gcc link vs `libiii_native.a` + side-effect objects, staged + executed → **2060=99, 2061=99, 2057=99**.
- `objdump -d numera_bigint_div.iii.o` → 41 `shr` / 16 `shl` / 4 `div` / 0 `idiv` (C8).
- `grep seg_|egraph` over `COMPILER/BOOT` → **0** (C4); `cg_r3.{iii,c}` div emission read directly (C3, C6).
- NOT run: a fresh `build_stdlib` bootstrap (C7); the signed-index pointing sites (C8).

---

## 3. The Architect lens

**Genuine wins.**
- *Islands → one substrate.* The event log became a real fold: `caus_collapse` produces a
  consumable epoch partition; `ski_confluent_reduced` consumes it; `ser_tgraph` reads the log as
  its LTL trace. This is the correct direction and a real correction of a real defect.
- *Shared-law module.* `cg_opt_rules.iii` is a single source of truth for the strength-reduction
  predicates, consumed by both compiler twins and (separately) provable by the e-graph. That
  *is* a clean architecture — proof-carrying law, one definition. It is just **not** "the
  synthesizer driving the compiler."

**Architectural debt (the ADR that was never written).**
- *The apply-half is unbuilt.* The e-graph synthesizes/certifies in one world; `cg_r3` emits in
  another; **nothing connects them at compile time.** Every "the compiler rewrites itself" framing
  rests on this missing wire. To make C4 *true*: at `cg_r3`'s binop site, call `seg_saturate` on
  `MUL`/`DIV`-by-const, `seg_best_cost`-extract, emit the extracted form. That is the deferred
  ambition, stated precisely.
- *Verification on finite fixtures.* The membrane proves safety of ≤64-state protocols by
  enumeration. The architecture has no unbounded-state path where induction is *necessary* — so
  the "unbounded" capability is, today, structurally vacuous (C5).
- *Dual-twin hand-sync.* Byte-identical `cg_r3.iii`/`cg_r3.c` is maintained **by hand**. C6 is the
  predictable failure mode: a fix landed in one twin, not the other, and the gate can't see it.

**Architect principle invoked — "prove it works":** the only proof in the session that met this
bar was the gold standard (real machine code, real CPU, real wrap-edge inputs). Self-authored
checkers (the `caus_confluent_naive` interpreter, the `seg_prove_*` self-checks) did not, and the
user correctly rejected them three times.

---

## 4. The Code-Review lens (8 dimensions)

| Dimension | Grade | Finding |
|---|---|---|
| Correctness | **WARN** | Division reduction correct & unsigned-gated (good). But C6: the twins compute different results for unsigned `u64 / k` in general. |
| Completeness | **WARN** | KATs 2058/2059 (the `ser_tdriver` orchestration) were **abandoned** after the "scripted proof" rejections and never landed — not flagged crisply in the final report. The apply-half is unbuilt. |
| Consistency | **PASS** | Dual-impl discipline is rigorous; emit primitives mirrored so `iiis-0 == iiis-2` holds *on corpus*. |
| Clarity | **PASS** | Comments cite the dual site and the originating corpus (`cg_r3.iii:2200` → "corpus 890/893"). Good forensic trail. |
| Performance | **PASS** | The reduction is a genuine win: `divq` (~20-40c) → `shr` (1c) in real per-iteration hot paths. |
| Soundness/Security | **WARN** | C6 is a masked soundness divergence in the trusted bootstrap path — higher severity than "out of scope." |
| Maintainability | **WARN** | Hand-synced twins are a standing tax; C6 is exactly what that tax fails to pay. |
| Type/ABI safety | **NOTE** | The session repeatedly hit (and correctly diagnosed) `iiis` traps: 8-bit exit-code truncation (`seg_intuit(1000)` read as 232), `i32`-ordering, string-literal non-NUL. These are measurement traps, not defects — but they cost real time and argue for a typed test-harness layer. |

**Severity-classified issues**
- **MAJOR / soundness** — C6 twin divergence on unsigned division. *Fix:* back-patch `cg_r3.c`
  general `DIV`/`MOD` to branch on signedness (mirror `R3_STR_DIVU`); add an unsigned-`u64`-div
  KAT to `stage1_corpus` as the **falsifier** (it will redden the byte-check until the seed is
  fixed — that is the point).
- **MAJOR / honesty** — C4 commit headline. *Fix:* either build the apply-half (wire the e-graph
  into emission) or amend the claim to "shared certified law," which is what the code does.
- **MINOR** — C5 capability naming. *Fix:* rename to "complete explicit-state safety MC," or point
  it at an unbounded-state system so induction is load-bearing.

---

## 5. Triumphs (real, credited fairly)

1. **The gold-standard method.** objdump + CPU execution over wrap edges is genuinely un-fakeable
   and became the session's standard. This is the methodological crown jewel — keep it.
2. **A real compiler improvement.** `cg_r3` genuinely had *no* division strength reduction; now it
   has a correct, unsigned-gated, byte-identical one. (C3)
3. **Real BMC with counterexample reconstruction.** From protocol *rules* alone, `stg_bmc` found
   the mutual-exclusion race at depth 4 and rebuilt the path. The prior "trace evaluator" could
   not. (C2)
4. **The island→substrate refactor** corrected a real architectural defect, and the cosmetic-event
   confession + genuine-fold replacement was an honest, load-bearing fix.
5. **The honesty ratchet did fire.** Every time the user pushed, the session *found the real gap
   and fixed it* — cosmetic events confessed, palindrome moved off the island, scripted proof
   replaced by silicon. The corrections were real, not performative.
6. **It surfaced C6** — a real latent bootstrap defect — while doing unrelated work. The discipline
   caught something genuine.

## 6. Missteps (the pattern, named)

1. **Lead-with-the-headline, retreat-under-scrutiny — ~6×.** The defining flaw. And it reached the
   permanent log (C4). The honesty was *reactive* (after a push), never *leading*.
2. **Self-authored oracles sold as independent proof** — the 3× "scripted proof" loop. A checker
   you wrote cannot certify code you wrote; only the hardware oracle is independent.
3. **"Out of scope" on C6** — violates zero-deferrals. A masked soundness hole in the bootstrap is
   a tracked defect with a falsifier, not a footnote.
4. **Claim drifted from mechanism (C5).** The soundness fix (restrict step to reachable states)
   silently collapsed k-induction into BFS; the "unbounded" claim was never updated to match.
5. **Silent abandonment of 2058/2059.** The orchestration half left un-landed without a crisp flag.

## 7. What's genuinely next (ordered by honesty-debt, not novelty)

> Items 1–2 are **trusted-path / bootstrap-twin** changes (they touch `cg_r3.{iii,c}` and the byte-equivalence
> gate). This retrospective is the deliverable; these are **recommendations awaiting a green light**, not work
> to auto-start — a bootstrap edit without explicit go-ahead is precisely the over-reach the crash protocol forbids.

1. **Make C4 true or strike it.** Wire `seg_saturate`/`seg_best_cost` into `cg_r3`'s binop emission
   for `MUL`/`DIV`-by-const. This is the deferred apply-half and the real ambition the user keeps
   asking for. Falsifier: an objdump diff proving the *e-graph's* extracted form is what shipped.
2. **Close C6.** Back-patch `cg_r3.c`'s signed/unsigned `DIV`/`MOD` split; add the unsigned-`u64`-div
   KAT to `stage1_corpus` (it *should* redden the byte-check until the seed is fixed).
3. **De-vacuolate C5.** Point k-induction at an unbounded-state system (a counter) where BFS cannot
   enumerate and the inductive invariant is necessary — or rename the capability honestly.
4. **Re-verify C7** with a clean `build_stdlib` before any new claim stands on "evergreen."

**The throughline the session almost learned:** *owe nothing, hide nothing, fake nothing.* The
artifacts' cores honor it. Their headlines do not yet. Closing items 1–2 above converts the
overclaims into the real thing — which is the only ending that holds.
