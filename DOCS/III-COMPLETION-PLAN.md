# III — THE COMPLETION PLAN: from realized-with-residuals to a gap-free unified sovereign stack

**Authored 2026-06-24, against the LIVE tree (every claim below was *run*, not relayed).**
Discipline: the theorem-to-machine obligation — no claim without a runnable realization and a falsifier;
calibrated verdicts (PROVEN-IN-CODE / STATED-NOT-DISCHARGED / DECORATIVE); no demos, no placeholders, no
deferrals. Completion = every residual closed, every program independently functional and gated, nothing
that only "works in a script."

---

## PART 0 — VERIFIED CURRENT STATE (run, not attested)

| Claim | How verified (this session) | Verdict |
|-------|------------------------------|---------|
| Grand Unification realized end-to-end | **ran `run_grand_unification.sh` → GU_EXIT=0**; Ω.a/d+Ω.b+F2+Ω.e+Ω.f+Ω.g+Ω7 all PASS with adversary arms | **PROVEN-IN-CODE** (honest scope below) |
| Frontend DDC closed | **ran `run_ddc.sh` → rc=0**; iiisv≡iiisv2 byte-identical (toolchain 1403B / ops 934B / bignum 2901B), verifier-OK, x86+wasm=99 | **PROVEN-IN-CODE** |
| Committed GF(p⁴) zkVM (~2^-86) | Ω.e PASS inside GU (committed FRI + line-755 STARK + fused compute+memory+control, Merkle-bound, forged-LOAD/non-perm/forged-opening/corrupted-root all reject) | **PROVEN-IN-CODE** at the NQ knob (NQ=128⇒~2^-86; NQ=16 units are mechanism tests) |
| Trust anchor exists + total ISA | `svir_verify.iii` 80 lines, opcodes 0x01–0x89 (CONST/LOCAL/binops/control/CALL/DROP/typed-mem) | **PROVEN-IN-CODE** |
| Trust-closed toolchain artifact | `STDLIB/build/iii/libiii_native.a` present; `COMPILED/iiis-2.exe` present (the self-hosted compiler) | **PROVEN-IN-CODE** |
| Module corpus scale | 2730 `.iii` in STDLIB (eidos 18, aether 70, omnia 159, numera 296, sovir 72 + build/corpus) | survey fact |

**HONEST SCOPE the GU gate states about itself (not hidden):**
- XII does **not** lower to SVIR → the cross-view (EXECUTION ⊥ INTENT) binding is the **shared fold**
  (one computation, two proven views fold to the same 675673294), *not one object transformed through both
  stages*. This is sound but is a weaker unification than "one object."
- ~2^-86 is the **NQ query-count knob** (production scale on the headline gadgets; some unit gadgets stay at
  NQ=16 deliberately as mechanism tests).
- The **seed-lineage DDC** axis is an open residual (`SVIR-DDC-RESIDUAL.md`).
- **Ω0 binary-level DDC** (ccsv compiling the C seed) is the **last trust-floor residual**.

---

## PART 1 — THE RESIDUAL LEDGER (every gap, precisely, with its measurement)

These are the ONLY things standing between "realized-with-residuals" and "complete." Each is measured.

- **R1 — Ω0 / THE TRUST FLOOR (largest).** ccsv (`STDLIB/sovir/ccsv.iii`, C-subset→SVIR translator) does not
  yet compile the C seed (`COMPILER/BOOT/{lex,sema,emit,ast,cg_r3,parse}.c`) completely. **Measured this
  session: 183 verify-failures of ~659 functions** (lex17 sema34 emit4 ast36 cg37 parse55). Until this is 0,
  the iiis-0 seed can only be built by gcc → the trusted path is not sovereign at the bottom → the binary
  DDC cannot close. *This is the keystone residual: it gates the whole sovereignty claim, not just a gadget.*
- **R2 — SEED-LINEAGE DDC + author-diversity.** `SVIR-DDC-RESIDUAL.md`: the frontend is byte-DDC-closed
  (R-verified), but the *seed* (gcc→iiis-0) and *author-diversity* axes are open. A second, independently-
  authored frontend must emit byte-identical SVIR for the seed lineage.
- **R3 — F6 BROAD-LEDGER SWEEP (the conscience pass).** The grand-unification ledger has been audited twice
  (F1, F2 corrected from HIGH overclaims). F6 = sweep *every remaining* "CLOSED/PROVEN" banner across the
  tree and re-render the calibrated verdict; strike or build anything DECORATIVE.
- **R4 — build_stdlib COVERAGE RATCHET (F8).** The full `build_stdlib` gate exits non-zero on down-only
  coverage ratchets: **uncovered=39, dark=58, under-proven=2** (recorded). Completion ⇒ every exported
  symbol KAT-proven AND reachable (uncovered→0, dark→0). The project currently runs `run_corpus`, not the
  full gate, *because* of this — closing it makes the full gate the standard.
- **R5 — XII→SVIR LOWERING (elective true-unification).** Today XII canonicalises + emits a re-checkable
  proof but does not lower to SVIR; the GU binds the two views by the shared fold. To make the binding *one
  object through both stages* (the strong form), XII must lower its canonical term to SVIR and the zkVM must
  attest *that* SVIR. Elective: the shared-fold binding is already sound.
- **R6 — PRODUCTION-SCALE EVERYWHERE.** Headline gadgets are NQ=128 (~2^-86). The remaining unit/mechanism
  gadgets (NQ=16) + any base-field legacy paths must be lifted or explicitly retired so no "sound" claim
  anywhere is below the stated production bit-count.
- **R7 — IRREDUCIBLE TCB, DOCUMENTED + MINIMISED.** CPU/microcode + OS loader remain outside III's trust
  closure. Completion ⇒ this floor is *named, measured, and minimised* (kernel32-only sovereign x86 already;
  document the exact irreducible set as the honest TCB).

---

## PART 2 — THE COMPLETION PHASES (ordered; each closes named residuals)

Ordering rationale: R1 (trust floor) is the keystone and the longest pole — it unblocks R2 and is the
substance of "sovereign." R3/R4 are conscience/coverage hygiene that can proceed in parallel. R5 is elective.
R6/R7 are hardening. Each phase states its **exit gate** (the runnable proof) and its **falsifier** (the
mutation that reddens that gate) — a phase is not "done" until both exist and pass.

### Φ1 — CLOSE THE TRUST FLOOR (R1): ccsv compiles the full C seed, soundly
**Goal:** 183 → 0 seed verify-failures, then a *sovereign* rebuild of iiis-0 from ccsv-emitted SVIR that
byte-matches the reference, closing the binary DDC.
**Method (the proven loop, now with the corrected methodology):**
1. **fn70-class first (the struct-field width/DROP family).** Use the *reliable instrument harness* proven
   this session: instrument the `eload` choke point (`ccsv.iii:316`) + a per-function marker, **positive-
   control on the known-good minimal case (dj4) before trusting lex.c**, and never conclude from a print's
   absence. Confirmed symptom: `st->arena.total_bytes` emits LD4 in lex.c vs LD8 isolated; the responsible
   handler is narrowed to 5 candidate `eload` sites by elimination. Pin it, fix it, gate it.
2. **Heterogeneous tail by Pareto class.** Re-run the batch classifier (`classify.mjs`), fix the highest-
   frequency root each cycle (the method that cleared cg_r3's 256-local cap, −58, and the arrow-dot store,
   −12). Each fix: reproduce (RED) → fix → verify (GREEN) → gate.
3. **CALL_INDIRECT.** The ~4 function-pointer call sites need a SVIR indirect-call opcode (verifier + x86 +
   wasm). Build it only when the seed's leverage warrants (it is the last structural construct).
4. **Completeness, not just count.** Every *source* function must be EMITTED and verify (the dropped-function
   bugs — bare-type returns, `T**`, `(**)[N]` — proved the count understates; assert `nfunc == source fns`).
**Exit gate:** a new `run_seed_sovereign.sh` — ccsv compiles all 6 seed modules to SVIR; svir_verify accepts
every function; the SVIR runs x86(sovereign)+wasm == reference; the sovereign-built iiis-0 is **byte-identical**
to the gcc-built iiis-0 on `stage1_corpus`.
**Falsifier:** flip one emitted opcode in any seed function → svir_verify reddens; perturb one seed source
byte → the byte-DDC reddens. (No self-grading: the two independent builders must agree byte-for-byte.)

### Φ2 — CLOSE SEED-LINEAGE DDC + AUTHOR-DIVERSITY (R2)
**Goal:** the seed (gcc→iiis-0) and a *second independently-authored* frontend emit byte-identical SVIR for
the seed lineage — the DDC closes on the axis `SVIR-DDC-RESIDUAL.md` names open.
**Method:** with Φ1's sovereign seed-builder in hand, run the seed through *both* iiisv (precedence-climbing)
and a second emitter (shunting-yard already exists for the frontend DDC) extended to the seed constructs;
diff byte-for-byte. Where they diverge, the canonical SVIR form is under-specified → tighten the SVIR
canonicalisation spec until they converge.
**Exit gate:** `run_ddc.sh` extended with a `seed` axis that asserts byte-identity on the seed lineage,
rc=0. **Falsifier:** a one-byte divergence in either emitter reddens.

### Φ3 — F6 BROAD-LEDGER SWEEP — THE CONSCIENCE PASS (R3)
**Goal:** every "CLOSED/PROVEN/PRODUCTION" banner in the tree carries a *runnable* realization and a
falsifier, or is struck. No DECORATIVE claims survive.
**Method:** enumerate every `run_*.sh` gate and every `✅` banner in the ledgers; for each, descend the six
rungs (statement→hypotheses→discharge→realization→falsifier→verdict) and **check, don't attest** — run the
gate, point discharge to file:line. Downgrade any rung that cannot be filled; strike or build the gap.
**Exit gate:** `DOCS/III-F6-LEDGER-AUDIT.md` lists every claim with its verdict and the command that proves
it; a `run_conscience.sh` meta-gate runs the full set and any DECORATIVE claim is removed from the banners.
**Falsifier:** a banner with no gate line in `run_conscience.sh` fails the meta-gate.

### Φ4 — DRIVE THE COVERAGE RATCHET TO ZERO (R4)
**Goal:** uncovered=0, dark=0, under-proven=0 → the *full* `build_stdlib` gate (not just `run_corpus`)
becomes the standard green.
**Method:** for each of the 39 uncovered + 58 dark exports, add a corpus KAT that *exercises* it
(RED-without → GREEN-with) and a reachability edge so the cartographer sees it; split the test-scaffolding
exports (e.g. xii_proof's `set_rid`/`flip_ahash`) into a separate lib API + corpus KAT (the F3 task) so they
stop worsening the ratchet.
**Exit gate:** `build_stdlib --check-corpus` exits 0 with the ratchet at all-zeros. **Falsifier:** delete one
KAT → its export goes uncovered → the gate reddens.

### Φ5 — XII → SVIR LOWERING — THE STRONG UNIFICATION (R5, elective)
**Goal:** upgrade the cross-view binding from "shared fold" to "one object through both stages": XII lowers
its canonical term to SVIR, and the committed zkVM attests *that* SVIR.
**Method:** implement `xii_lower_to_svir` (canonical XII term → SVIR opcodes); route R0's canonical form
through it; the GU's Ω.b output becomes an SVIR object the Ω.e zkVM attests, so EXECUTION and INTENT are the
*same* artifact, not two folds that agree.
**Exit gate:** `run_grand_unification.sh` upgraded so F2 binds *one lowered object* (the XII canonical SVIR ==
the executed SVIR), adversary arm = a divergent lowering reddens. **Falsifier:** mutate the lowering →
the single-object identity breaks.

### Φ6 — PRODUCTION-SCALE EVERYWHERE (R6)
**Goal:** no "sound" claim anywhere below the stated production bit-count; legacy base-field paths retired.
**Method:** lift every NQ=16 unit gadget that makes a *production* claim to NQ=128; for the deliberately-
minimal mechanism units, label them "MECHANISM, not production" in the gate text (they already are); sweep
for any remaining base-field (30-bit) `air_stark_verify` callers and migrate them to the GF(p⁴) committed
verifier (the path `zk_fused_committed` already proves).
**Exit gate:** a `run_zk_audit.sh` that asserts every gadget's claimed bit-count matches its NQ/field knobs.
**Falsifier:** down-scale any production gadget's NQ → the audit reddens.

### Φ7 — THE EVERGREEN GUARANTEE (R7 + the meta-invariant)
**Goal:** every program/tool is *independently and completely functional* — no demos, no placeholders, no
"works only inside its script." The irreducible TCB is named and minimised.
**Method:** (a) a `run_evergreen.sh` meta-gate that, for every standalone sovir/ program, builds it from
source via the *sovereign* path and runs it to its real exit code — no gcc/ld in the trusted build of the
trusted programs; (b) a placeholder-scanner that fails on any `TODO`/`stub`/`unimplemented`/`placeholder` in
load-bearing modules; (c) `DOCS/III-TCB.md` enumerating the exact irreducible trust floor (CPU/microcode +
OS loader) with the measured sovereign surface (kernel32-only) and the argument that nothing above it is
trusted-by-assertion.
**Exit gate:** `run_evergreen.sh` rc=0 (every program self-builds sovereignly + runs) AND the placeholder
scanner is clean. **Falsifier:** introduce a placeholder or a gcc-dependency in a trusted program → reddens.

---

## PART 3 — THE COMPLETION INVARIANT (when is it DONE?)

III's unified sovereign stack is **complete** when a single meta-gate, `run_completion.sh`, is green and is
itself sovereign-built:

```
run_completion.sh  ⇐  ALL of:
  run_grand_unification.sh        (Ω.a/d+b+F2+e+f+g+Ω7)         = the unified pipeline
  run_seed_sovereign.sh           (Φ1: ccsv builds iiis-0,DDC)  = the trust floor closed
  run_ddc.sh  [+ seed axis]       (Φ2)                          = DDC closed incl. lineage
  run_conscience.sh               (Φ3: every banner runnable)   = no DECORATIVE claims
  build_stdlib --check-corpus     (Φ4: ratchet all-zero)        = full coverage
  run_zk_audit.sh                 (Φ6: bit-counts match knobs)  = production everywhere
  run_evergreen.sh                (Φ7: self-build + no stubs)   = evergreen, independent
```

with `run_grand_unification.sh` optionally upgraded by Φ5 to the one-object binding. Every line is a real
exit code; every line has a falsifier that reddens it. When `run_completion.sh` is green AND is built by the
sovereign toolchain whose floor Φ1 closed, the stack is **complete**: a real EIDOS computation, compiled by
a sovereign frontend whose seed reproduces itself bit-for-bit with no foreign compiler in the trusted path,
canonicalised with a re-checkable proof, attested by a ~2^-86 committed zero-knowledge proof over its whole
ISA, shipped cross-node without re-execution, federated Byzantine-tolerantly, and bound to its own toolchain
by a tamper-sensitive provenance certificate — every organ sound, committed, adversary-gated, and the only
trusted thing left is the silicon.

**The single longest pole, and therefore the first move, is Φ1 — and Φ1's first move is the reliable `eload`
choke-point instrument with a dj4 positive control to pin the fn70 struct-field-width root.**
