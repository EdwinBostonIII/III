# III Structural Audit — Implementation Doctrine (Plan, Part 0)
> **STATUS: HISTORICAL RECORD** — an executed campaign plan/ledger, kept immutable as evidence (reunification W6).

> **For agentic workers:** This is the spine of the granular implementation plan derived from
> `DOCS/III-STRUCTURAL-AUDIT.md`. The per-finding, file-by-file, step-by-step tasks live in the
> companion parts (`-PLAN-1-COMBINATION.md` … `-PLAN-5-REMOVAL.md`), each task written in the
> `superpowers:writing-plans` format. This Part 0 fixes the invariants, the ordering, the seal
> discipline, the deferral-elimination commitments, and the surpass-only standard that *every*
> task in those parts must satisfy. Read this first; it is the contract the rest obey.

**Goal:** Turn the five-axis structural audit into an executable program of work in which *every*
finding (COMBINE-1…13, SEPARATE-1…5, RIPPLE-1…14, ENHANCE-1…23, CUT-1…16, KEEP-1…3) is realized as
concrete, ordered, dependency-correct implementation steps with **zero deferrals** and **zero
compromises**.

**Architecture:** A wave-ordered build. Shared primitives ("missing organs") land first so every
consumer inherits the corrected, faster, safer foundation; the most dangerous matter (the crypto
shadow) is excised next; the trusted base is drawn; consumers heal; gates are made load-bearing;
the forge-closure and frozen-spec artifacts are resealed in dedicated passes (the de-deferred
work); and the seal-gated compiler source is touched **last** in one `build_iiis2` pass.

**Tech stack / invariants:** III — deterministic, exact integer arithmetic, NIH (libc + `COMPILER/BOOT`
headers only), static BSS arenas, bounded loops, bit-identical replay. Proof kernel
(`numera/typecheck.iii` + `numera/ccl.iii`) is the sole arbiter of meaning.

---

## 0. Relationship to the source documents

| Document | Role |
|---|---|
| `DOCS/III-QUANTUM-PRINCIPLE-AND-MATH-AUDIT.md` (Vols I+II, 3,123 lines) | Evidence base. Defines the cited finding ids (`F-CORE-*`, `E-X-*`, levers `X1`–`X26`). |
| `DOCS/III-STRUCTURAL-AUDIT.md` (238 lines) | The plan under verification. Reorganizes the source onto five axes with local ids. |
| `DOCS/III-STRUCTURAL-AUDIT-VERIFICATION.md` (to be written) | The verification ledger: per-finding verdict (HOLDS / DRIFTED / ALREADY_FIXED / PARTIALLY_WRONG / WRONG), evidence (live `file:line`), and corrected statement. Produced from the read-only verification workflow. |
| `DOCS/III-STRUCTURAL-AUDIT-PLAN-00-DOCTRINE.md` (**this file**) | The invariants, ordering, seal discipline, deferral-elimination, and task template. |
| `DOCS/III-STRUCTURAL-AUDIT-PLAN-{1..5}-*.md` (to be written) | The granular per-finding tasks, one part per axis. |

**Calibration fact established at plan time (2026-05-29):** the audit's line counts have all
drifted upward against the live tree — `typecheck.iii` 2959→2992, `ccl.iii` 898→938,
`egraph.iii` 1628→1709, `smt.iii` 1984→2155, `sov_isa.iii` 795→869, `cg_r3.iii` 3384→3546; the
source audit is 3,123 lines (the structural audit says "3,083"). **Therefore no stated line number
is load-bearing.** Every task cites the symbol name and re-locates it by `Grep` at execution time;
line numbers in the plan are advisory and stamped with the date observed.

---

## 1. Invariants every task must preserve (non-negotiable)

These are gates, not guidelines. A task that cannot satisfy all five is not done.

- **I1 · Determinism.** Output is bit-identical across runs and machines. Any change touching an
  iteration order, a hash, an id allocation, a tie-break, or a SIMD path must prove identical bytes
  to the prior scalar/reference path on a fixed vector. Worklist drains and merges occur in a total,
  content-derived order (ascending id, then `tiebreak` authority). No `Date`, no RNG-without-seed,
  no observation-driven adaptation (that is ML in disguise — forbidden).
- **I2 · NIH.** Only libc and `COMPILER/BOOT` headers. No third-party dependency, ever. Every
  primitive is hand-rolled. A "library exists for this" is not a reason; it is the reason to build
  the better one ourselves.
- **I3 · Proof-kernel arbitration.** Anything that asserts meaning reduces to
  `typecheck`+`ccl`. No fix may widen the trusted base silently; where it does touch the reducer,
  the differential oracle (`combinator.cb_conv`) and exhaustive confluence must guard it.
- **I4 · No vacuity.** Every gate, guard, and certificate must be able to say **no**. A fix is
  incomplete until a *falsifier* — a KAT that drives a bad input to a rejection — exists and is
  shown to fail on the bad input and pass on the good one. (`feedback_no_autogen_stub_prove_negative`,
  `feedback_prove_positive_arms`.)
- **I5 · No placeholder, no stub, no partial.** No `TODO`, no "implement later", no constant-return
  pretending success, no relabel-instead-of-build. Completion is the only acceptable state.

---

## 2. The seal-gating taxonomy (what verification each task ends with)

Every finding's target file falls into exactly one seal class. The class dictates the closing gate
of its task. **Misclassifying the seal class is the single most expensive mistake** (it is how a
content-address closure gets left half-sealed), so every task states its class explicitly.

| Class | Where | Editable as code? | Closing gate of the task |
|---|---|---|---|
| **STDLIB_GATE** | leaf modules under `STDLIB/iii/**` not referenced by the compiler | Yes | `bash STDLIB/scripts/build_stdlib*.sh` → grep `FAIL = 0`; `bash STDLIB/.../run_corpus.sh` GREEN; add the feature's new corpus KAT. (`feedback_corpus_regression`, `feedback_buildstdlib_fail_masks_stale_lib`.) |
| **BOOTSTRAP_SEAL** | any `COMPILER/BOOT/*.iii` | Yes, but drifts the iiis-2 seal | Edit → run the seal-gated `build_iiis2` → byte-equivalence on `stage1_corpus` → reseal to golden BARE hash. The gate decides the reseal; never hand-edit `.mhash`. (`feedback_determinism`, RIPPLE-10.) |
| **FORGE_CLOSURE** | forge-sealed descent artifacts whose whole-file SHA feeds a multi-level content-address closure (`katabasis/census.iii`, `ring_lattice`, `seal_resolver` rows) | Only via a *complete* closure recompute | Edit → recompute **every** closure level (per-row seal → SHA-256 sub-closure root → Keccak manifest root) → manifest re-verify K1…K6. A partial reseal is a hard-invariant breach; **never land one.** (RIPPLE-11; de-deferred in §4.) |
| **FROZEN_SPEC** | byte arrays that *are* a frozen seal definition (`seal_resolver` coefficient table, ADR-RES-009) | Only via spec refreeze | New ADR superseding the frozen one → reissue the seal → update all dependents → manifest re-verify. (KEEP-1; de-deferred in §4.) |
| **GOLDEN_SEAL** | `COMPILED/iiis-2.exe` + `*.mhash` + `*.witness.json` | **No — these are the seal, not code** | Never edited directly; they move only as the *output* of a BOOTSTRAP_SEAL reseal. (KEEP-3 — documented, not actioned.) |

---

## 3. Dependency-ordered build waves

Derived from the audit's own ripple analysis (§3) and the §6 synthesis ("the missing primitive
layer is the highest-leverage move"). Earlier waves are foundations later waves stand on; a finding
appears in the *earliest* wave that satisfies its prerequisites. Within a wave, tasks are
independent unless an explicit `blockedBy` is noted.

- **Wave 0 — The missing primitive layer (build the shared organs first).**
  COMBINE-7 (boundary-contract helpers), COMBINE-3 (content-address index, copying the proven
  `COMPILER/BOOT/ast.iii` hashcons), COMBINE-6 (route ad-hoc tie-breaks through `numera/tiebreak.iii`),
  COMBINE-4 (unified Montgomery/Barrett/special-form reduction with MONT-1/MONT-2 fixed at source),
  COMBINE-5 prerequisite (`omnia/pq` hole-sift, A-PQ-1), COMBINE-1/ENHANCE-2 (the `numera/ntt.iii`
  convolution organ), COMBINE-2 (one fast bucketing hash).
  *Rationale:* every consumer inherits the corrected foundation; fixing here heals many call sites
  at once (§6 synthesis #1).

- **Wave 1 — Excise the dangerous shadow (security-critical removal).**
  CUT-12 + CUT-13 + CUT-14 + COMBINE-13 + SEPARATE-5 + ENHANCE-14: remove the `xii_curated_*`
  crypto override so emission falls back to the proven `numera` crypto, *or* regenerate the inlines
  from it with per-horizon equality KATs; make the override **policy** a single auditable file.
  *Rationale:* a tautological `ed25519_verify` on the live signature path is the most urgent defect
  in the system (§5B). This precedes everything that could touch crypto emission.

- **Wave 2 — Draw the trusted base.**
  SEPARATE-2 (isolate reducer+translation as a sealed certified unit), RIPPLE-1 (confirm the four
  II-CCL/II-TC soundness fixes are landed and gated; re-prove if drift found), ENHANCE-21 (commit
  `combinator.cb_conv` as a *permanent* differential oracle), wire `xii_critpair_enum`+`xii_conf_cert`
  to the CCL rule set so confluence is a theorem (II-CCL-3).
  *Rationale:* the trusted base is the one place a mistake is unbounded; it must be legible and
  defended before consumers are reshaped (§6 synthesis #3).

- **Wave 3 — Consumers heal, modules sharpen.**
  RIPPLE-2 (NTT heals the silent large-multiply break), RIPPLE-3 (crystal minting band),
  RIPPLE-4 (`cgr_contains` read-only query), RIPPLE-5/RIPPLE-6/ENHANCE-18 (cad/builder error-contract
  sweep + domain-separated Merkle), RIPPLE-7/COMBINE-9/ENHANCE-6 (x25519→fe25519), RIPPLE-8 (cpufeat
  forced-path KATs), ENHANCE-5/7/8/9/10 (the performance sweep), ENHANCE-11/12/13 (new primitives),
  ENHANCE-19/20/22/23 (soundness hardening), and the dead-matter removals CUT-1…CUT-8, CUT-10, CUT-11.

- **Wave 4 — Make the gates load-bearing.**
  ENHANCE-16, ENHANCE-17, RIPPLE-13, RIPPLE-14, CUT-15: every vacuous gate gains the capability to
  reject and a falsifier KAT, or is removed where no check was ever intended. Resolve CUT-16
  (`xii_emit_gen_produce`) explicitly.
  *Rationale:* I4 made systemic (§6 synthesis #5).

- **Wave 5 — The de-deferred forge-closure & frozen-spec passes** (see §4). RIPPLE-11, KEEP-2
  (census forge reseal), KEEP-1 (seal_resolver spec refreeze). FORGE_CLOSURE / FROZEN_SPEC gates.

- **Wave 6 — The seal-gated compiler pass, LAST.**
  RIPPLE-9 (`@specialize` sign-extension/stride at the codegen site), RIPPLE-10 discipline,
  COMBINE-3's `sema` consumer (G-SEMA-1) + G-SEMA-2, CUT-9 (`cg_r3` dead bookkeeping), SEPARATE-4
  (decline or perform the `cg_r3` split), `cg_rm2`/`xii_ldil` items. One dedicated `build_iiis2`
  reseal closes the wave. (RIPPLE-10: "compiler files must be done last.")

---

## 4. Deferral-elimination commitments (the user's hard requirement)

The audit contains deferrals and "decide-later" choice-points. **Per the directive, no deferral
survives.** Each is hereby converted into a concrete pass scheduled in the waves above. The
granular byte-level procedure for each is harvested by the verification workflow (it specifically
instructs agents to produce the executable conversion); the commitments below are the schedule.

1. **RIPPLE-11 / KEEP-2 — `katabasis/census.iii` out-of-range index (was: "leave it until a
   dedicated forge reseal pass").** → **Wave 5, FORGE_CLOSURE task.** Fix the index bound in
   `census.iii`, then recompute the *full* three-level closure in one pass: (a) per-row seal,
   (b) SHA-256 descent sub-closure root, (c) Keccak manifest closure root; then re-verify manifest
   keys K1…K6. The "Keccak top root not cleanly recomputable in toolset" obstacle is itself a work
   item: if no tool recomputes it, **build the recompute tool** (NIH, hand-rolled over the existing
   `numera/keccak.iii`) — that is the surpass-only resolution, not an excuse to defer.

2. **RIPPLE-11 / KEEP-1 — `katabasis/seal_resolver.iii` coefficient table (was: "spec-level
   refreeze, not a code edit").** → **Wave 5, FROZEN_SPEC task.** If the bytes are wrong vs the
   documented magnitudes, author the superseding ADR (ADR-RES-009 → successor), recompute the
   correct coefficient bytes, reissue the seal, update dependents, re-verify the manifest. The
   refreeze *is* the step; "do not edit as code" means "edit via the ADR channel", not "never edit".

3. **ENHANCE-15 — transform slots (was: "deliberate design decision per slot: build the real
   transform OR rename it").** → **Wave 3 tasks, surpass-only.** Relabeling is a compromise and is
   rejected. Each slot gets the *real* implementation: a genuine x86 instruction decoder for
   `tp_x86_disasm`; a valid, loadable PE32+ with populated optional header and sections for
   `tp_asm_to_pe`; real III→C99 lowering for `tp_iii_to_c99`; real III→LaTeX for `tp_iii_to_latex`;
   `transform`/`transform_buffer` made to convert the full input, not 0/8 bytes. Each ships a
   round-trip / format-validity KAT.

4. **CUT-16 — `xii_emit_gen_produce` (was: "forward looking… decide the question").** →
   **Wave 4 decision task.** Verification determines whether a real caller is intended-and-missing
   (then wire it + KAT the emitted catalog) or it is dead (then remove it). The question is answered,
   not left open.

5. **ENHANCE-17 / CUT-15 — vacuous gates (was: per-gate "complete OR remove" binary left open).** →
   **Wave 4.** Each of the ten named gates is resolved explicitly: load-bearing + falsifier where a
   check is intended (the default, surpass-only); removal only where verification confirms no check
   was ever intended (`quality_q7`'s bare boolean is the prime candidate). No gate is left in
   superposition.

6. **KEEP-3 — bootstrap golden hashes.** Not a deferral: these are the seal, edited only as the
   *output* of a reseal. Documented in §2 (GOLDEN_SEAL) so a future reader does not "clean up magic
   constants". No action item; the discipline is the deliverable.

---

## 5. The surpass-only / no-compromise standard

Applied to every task. The audit frequently recommends the *adequate* fix; this plan accepts only
the **best-possible** one. Concretely, each task's design step answers:

- **Is there a structurally superior approach** that subsumes the audit's recommendation? If the
  audit says "add a guard", ask whether the guard belongs at a shared chokepoint that closes the
  whole class (e.g., COMBINE-7's boundary layer subsumes dozens of per-file guards). Prefer the
  organ over the patch.
- **Does the approach create a single source of truth?** Two implementations where the shadow can
  win is the recurring root cause (§6 #4). The fix must *generate* specialized forms (inlines, SIMD
  paths) from the one proven source, never duplicate.
- **Is anything a workaround?** Workarounds are rejected outright. If the obstacle is "no tool
  exists" (e.g., Keccak manifest recompute), the resolution is to build the tool, not route around
  the obstacle.
- **Does it preserve I1–I5?** A faster path that risks determinism is not faster; it is wrong.

When the audit's recommendation already is best-possible, the task says so and why; otherwise it
records the superior approach (the verification workflow's adversarial stage surfaces these).

---

## 6. The per-finding task template

Every task in Parts 1–5 is written in this shape (the `superpowers:writing-plans` format), with
**complete code in every code step** — no "similar to above", no prose-only code steps.

````markdown
### <LOCAL-ID> · <one-line title>   [Wave N · seal class · verdict from ledger]

**Verified:** <HOLDS / DRIFTED(→corrected fact) / ALREADY_FIXED(close as no-op) / WRONG(struck)>.
Evidence: `file:line` (observed 2026-05-29).
**Source ids:** <X-lever / F-CORE-* …>  — confirmed present in source audit: <yes/no>.
**Surpass note:** <audit's fix vs the best-possible approach adopted here>.

**Files:**
- Modify: `STDLIB/iii/<sub>/<file>.iii` — <symbol(s), re-Grep at exec time>
- Create:  `STDLIB/iii/<sub>/<newfile>.iii` — <responsibility>
- Test:   `STDLIB/.../corpus/<NNN_name>.iii` (new falsifier KAT)

- [ ] **Step 1 — Write the failing falsifier KAT first** (I4). <full KAT source; drives the bad
      input and asserts rejection/correct value>.
- [ ] **Step 2 — Run it; confirm it FAILS** against current code. Command + expected failure.
- [ ] **Step 3 — Implement the change.** <full source of the edit/new file>.
- [ ] **Step 4 — Run the KAT; confirm PASS**; run the positive-arm KAT; confirm PASS.
- [ ] **Step 5 — Close the seal gate** for this file's class (§2): STDLIB_GATE corpus-green /
      BOOTSTRAP_SEAL build_iiis2 / FORGE_CLOSURE full recompute / FROZEN_SPEC ADR refreeze.
- [ ] **Step 6 — Determinism proof** (I1) where applicable: identical bytes vs reference path.
- [ ] **Step 7 — Commit** with the finding id in the message.
````

**Ordering of steps is itself a gate:** the falsifier is written and shown to fail *before* the fix
(prove-the-negative), and the seal gate closes *after* the KAT passes, never before.

---

## 7. Plan completeness contract

This plan is "done" only when, for **all 79 findings**:
1. a verification verdict is recorded in the ledger (Part: VERIFICATION);
2. every `HOLDS`/`DRIFTED`/`PARTIALLY_WRONG` finding has a full task in its axis part;
3. every `ALREADY_FIXED`/`WRONG` finding is explicitly closed with the evidence that retired it;
4. every deferral in §4 is a scheduled task, none surviving;
5. each task carries its wave, seal class, falsifier KAT, and surpass note.

No finding is skipped, summarized-away, or deferred. The five synthesis claims (§6 of the audit) are
verified as architectural conclusions and, where they imply a cross-cutting task (the boundary
layer, the single-source-of-truth generation discipline), that task is the Wave-0 / Wave-1 organ
already scheduled above.
