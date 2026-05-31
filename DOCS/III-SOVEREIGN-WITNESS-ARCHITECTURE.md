# ARCHITECTURE DESIGN: The Sovereign Witness

*Status: PROPOSED (design + scope). Grounded in a source-level real-vs-symbolic classification of
24 load-bearing modules (workflow `wf_21308504`, 2026-05-31). Author: the at-scale Evolution, guiding hand.*

---

## Executive Summary

The Sovereign Witness vision — III as the *television set* that captures, freezes, examines, and re-projects
a legacy state space *from outside its phase space* — is largely **buildable today, for real, by composing
III's existing organs**, on one condition: we are precise about what "outside" and "frozen" mean. There are
exactly two clauses in the literal specification that are not breakthroughs-in-waiting but **results** —
the halting problem and the no-free-lunch identity `state(after packet) = simulate(state, packet)` — and a
third, the live Ring-−1/−2 descent, that is **unwired in the current build** (the ring/hypervisor layer is a
*symbolic verdict lattice*, not an executing hypervisor). The honest, maximal architecture therefore splits:

1. **The Real Sovereign Analyzer (buildable now, production-grade).** III ingests a **captured legacy
   artifact** (a dump / trace / packet capture produced by *some* external probe) as a **content-addressed,
   bounded data structure**, lifts it into III's own IR, runs the analysis and proof machinery that genuinely
   works (equality saturation, a decidable-fragment SMT search, *bounded* model checking, Curry-Howard proof
   terms), and emits a **sealed, tamper-evident witness** attesting exactly what it proved — and, crucially,
   **abstaining** (with a bounded counterexample) on what it could not. Every stage is composed from modules
   classified **REAL** (`cad`, `mhash`, `egraph`, `proof_term`, `net`, `fs`, `tcp`) or **PARTIAL-real**
   (`smt`), routed through the existing ripple gate/witness discipline. This *is* the situational irony of the
   spec: III understands the frozen artifact more deeply than its authors — provably, not rhetorically.

2. **The Boundary (named, not papered over).** The literal "exist in Ring-−2 and project the reality in which
   legacy systems exist", "prove *exactly* what the program *will* do", and "derive the exact RAM the system
   *would* have, without simulating" are — respectively — **unwired**, **undecidable**, and **identical to the
   simulation they claim to avoid**. Naming this is not a concession; it is the same *calibrated abstention*
   that has been the entire value of the at-scale self-enhancement loop (scans 1–7), applied at architecture
   scale. **A witness that claimed omniscience would be the one kind of output III's whole discipline forbids:
   an unfalsifiable assertion.** The Sovereign Witness's honesty about its own epistemic horizon is its
   sovereignty — it never pretends to a god's-eye view it cannot prove.

> **The reframing in one line:** *III is not the hypervisor that freezes the running machine; III is the
> sovereign mathematician that receives the frozen machine as a sealed object and proves theorems about it
> that the machine itself can never state.* The "outside the TV" is **epistemic and analytical**, realized
> today; the "outside the CPU ring" is **physical**, and is a separate, future, hardware-bring-up program
> (the katabasis descent), explicitly out of scope for a software-composable, production-grade-first delivery.

---

## 1. Requirements

### Functional

```
FR-1  INGEST: accept a captured legacy artifact (raw bytes: a memory dump, an instruction/branch trace,
      a packet capture, a register snapshot) via the real OS membrane (fs/net/tcp), with a declared
      artifact kind + length, into a BOUNDED in-arena structure. III never captures live state itself;
      it consumes an artifact some external probe produced.
FR-2  SEAL: content-address the ingested artifact with cad/mhash so it becomes an immutable, hashed
      mathematical object. All subsequent reference is by digest. Re-ingesting identical bytes yields the
      identical digest (determinism). This realizes "the legacy system is now a static hashed artifact."
FR-3  LIFT: parse the artifact into III's IR -- a bounded computation_graph / proof_term representation of
      the captured fragment (e.g. a basic-block DAG with typed edges). The lift is total and bounded:
      it refuses (cleanly) artifacts exceeding declared capacity rather than over-reading.
FR-4  ANALYZE: over the lifted fragment, run the real machinery:
        (a) egraph equality saturation  -> canonical/equivalent forms, simplification;
        (b) smt over the decidable fragment -> decide a stated property (e.g. "offset < bound on all paths
            of this BOUNDED unrolling");
        (c) temporal_logic BOUNDED model checking -> LTL/safety over a finite unrolling (decidable);
        (d) proof_term -> a Curry-Howard proof object for each property that holds.
FR-5  WITNESS: emit a SEALED witness = cad-addressed { artifact_digest, property_id, verdict, proof_or_
      counterexample, witness_digest }. The witness is itself content-addressed and tamper-evident.
FR-6  GATE: a witness is ADMITTED only if its proof term verifies against the sealed artifact + property,
      through the existing commit_gate / integrity discipline. A tampered artifact, a forged proof, or a
      property that does not actually hold -> the witness is REJECTED (prove-the-negative).
FR-7  ABSTAIN: where a property is undecidable or exceeds the bounded horizon, the witness returns an
      explicit ABSTAIN verdict (with the horizon that was reached), never a false PROVEN. Honesty is a
      first-class verdict, not an error.
FR-8  SANDBOX REPLAY (offline branch): given a captured artifact + a synthetic input, replay the lifted
      fragment forward in a bounded, pure, in-arena interpreter (no host effect) and content-address the
      resulting state -- the real, decidable form of "fast-forward to observe future branches" and the
      branch_anchor "reality branching" (a branch RECORD over the frozen artifact, not a live fork).

ACCEPTANCE CRITERIA (each a prove-the-negative KAT):
- Given identical artifact bytes, when sealed twice, then the two digests are byte-equal; given a single
  flipped bit, then the digests differ (cad domain-separation).
- Given an artifact with a property that HOLDS on the bounded unrolling, when analyzed, then verdict=PROVEN
  and the emitted proof term VERIFIES; given the same artifact with a forged proof term, then the gate
  REJECTS.
- Given an artifact whose property FAILS, when analyzed, then verdict=REFUTED with a concrete bounded
  counterexample that, when replayed (FR-8), reproduces the violation.
- Given a property beyond the bounded horizon, then verdict=ABSTAIN with the horizon -- never PROVEN.
```

### Non-Functional (III-relativized; the generic web table does not apply)

| Category | Requirement | Target | Measurement |
|---|---|---|---|
| Determinism | Identical artifact + property -> identical witness digest | Bit-exact | corpus KAT + mhash seal |
| Soundness | A PROVEN verdict's proof term verifies | 100% (gated) | proof_term check in commit_gate |
| Falsifiability | Every verdict has a constructible negative | every property | prove-the-negative KAT per property |
| Boundedness | Lift/analyze/replay refuse over-capacity inputs, never over-read | hard bound | OOB-reject KAT (scan-5/6 class) |
| NIH purity | Only libc + III BOOT headers; hand-rolled | strict | build_stdlib |
| LIBNATIVE | Compiler hash unchanged (no codegen edit) | `196b0c5f` | seal-gated reseal |
| Honesty | No verdict asserts more than it proves | invariant | ABSTAIN is a tested arm |

### Constraints

```
TECHNICAL
- Compose existing modules; ADD only the orchestrator + the artifact type + the bounded interpreter.
- No new compiler features (LIBNATIVE). No third-party deps (NIH). Arena-bounded, no unbounded BSS beyond gospel scale.
- "Capture" of LIVE legacy state is OUT OF SCOPE (requires the unwired Ring-−1/−2 descent). III consumes
  artifacts; it does not produce them from a running machine. This is the load-bearing scope decision.

LOGICAL (hard boundaries -- see Section 6)
- Total behavioral prediction of arbitrary code is undecidable. Only BOUNDED checking is offered.
- The post-event state cannot be derived without performing the computation (FR-8 IS that computation,
  done in a pure sandbox -- honestly a simulation, just a sound and content-addressed one).
```

---

## 2. The Module Reality Map (source-classified)

| Role in the spec | Module | Class | What it actually is | Witness role |
|---|---|---|---|---|
| Content-addressed frozen state | **cad**, **mhash** | REAL | sha256 content-addressing + domain-separated digests | **SEAL** the artifact + the witness (FR-2, FR-5) |
| E-graph analysis of legacy chaos | **egraph** | REAL | real equality saturation (e-class union-find + rewrite to fixpoint) | **ANALYZE (a)** canonicalize/simplify the lifted fragment |
| Curry-Howard proof IR | **proof_term** | REAL | real proof terms | **ANALYZE (d) / WITNESS** the proof object |
| Bounded model checking | **smt** | PARTIAL | real decision procedure over a fragment | **ANALYZE (b)** decide stated properties (decidable fragment) |
| The OS membrane | **net**, **fs**, **tcp** | REAL | real sockets / files (libc @abi) | **INGEST** the captured artifact (FR-1) |
| Lift target / model | computation_graph, temporal_logic | SYMBOLIC | typed models + bounded evaluators | **LIFT/ANALYZE (c)** -- symbolic is *correct* here: we *want* a symbolic model of the captured code |
| "Frozen mathematical object" spine | witness_spine | SYMBOLIC | a typed witness structure | **WITNESS** carrier (sealed by cad) |
| Reality branching | branch_anchor | SYMBOLIC | a branch *record* | **SANDBOX REPLAY** book-keeping (FR-8), offline what-if |
| Freeze / rewind | reversible | SYMBOLIC | an in-process transaction log of III's *own* structures | bounded rollback *within the sandbox interpreter* (not a live machine snapshot) |
| Ring descent | ring_lattice, svm_layout, vmexit | SYMBOLIC | verdict lattice: returns *which constructor is legal* / *is this write admissible* -- does **not** issue IOCTL/MSR/VMRUN | **specifies** the descent; does not execute it. Out of scope for the software analyzer |
| Cost oracle | microarch_model | SYMBOLIC | deterministic toy-pipeline simulator | optional cost annotation on the lifted fragment (sound only for its parameterized pipeline) |

**The pattern is decisive and *favorable*:** every organ the *analyzer* needs is REAL; every organ classified
SYMBOLIC is either (a) exactly the kind of *model* an analyzer should be built on (computation_graph,
temporal_logic, reversible-as-sandbox-rollback) or (b) part of the *hardware descent* that is out of scope.
There is no place where the real design must lean on a symbolic module *as if* it were real. That is the
test the spec had to pass, and it passes.

---

## 3. Architecture Overview

### Pattern: **Pipeline + Sealed Ledger, behind the Ripple Gate** (a layered, content-addressed dataflow)

The Witness is a deterministic **pipeline** whose every stage output is **content-addressed** and whose final
admission is **gated** by the existing commit_gate/integrity discipline. This is the natural III pattern
(it mirrors the ripple optimizer: propose -> cost -> select -> gate -> seal), reused for *external artifacts*
instead of III's own source.

```
  external probe (NOT III)                    III  =  the Sovereign Analyzer (one new orchestrator)
  ┌───────────────────┐
  │ dump / trace /    │   bytes      ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
  │ pcap / coredump   │ ───────────► │ INGEST   │──►│  SEAL    │──►│  LIFT    │──►│ ANALYZE  │──►│ WITNESS  │
  │ (gdb, perf, hw    │   net/fs/tcp │ (bounded │   │ cad+mhash│   │ comp_grf │   │ egraph + │   │ proof_   │
  │  probe, you)      │   (REAL)     │  arena)  │   │ (REAL)   │   │ +proof_  │   │ smt +    │   │ term +   │
  └───────────────────┘              └──────────┘   └────┬─────┘   │ term IR  │   │ temporal │   │ cad seal │
                                                         │         └──────────┘   │ (bounded)│   └────┬─────┘
                                                  artifact_digest                 └────┬─────┘        │
                                                  (the frozen object)                  │         witness_digest
                                                                                  SANDBOX REPLAY        │
                                                                                  (FR-8, pure,          ▼
                                                                                   in-arena) ──►  commit_gate / integrity
                                                                                                  (ADMIT iff proof verifies;
                                                                                                   else REJECT)  [prove-the-negative]
```

**Why this is the spec, realized:** the legacy state enters as bytes and immediately becomes a *hashed static
object* (no longer a running machine — exactly the spec's "static, hashed mathematical artifact"). III then
reasons in its higher-semantic space (egraph/smt/temporal/proof_term) and emits a sealed verdict. III is
**non-peer** (it never speaks TCP/HTTP *as a participant*; it parses captured bytes as data), **imperceptible**
to the artifact (the artifact is inert), and **omniscient within the bounded horizon** (it proves what is
decidable and *says so* about the rest).

---

## 4. Components

### COMPONENT: `sovereign_witness` (THE ONE NEW ORCHESTRATOR)
RESPONSIBILITY: drive the INGEST→SEAL→LIFT→ANALYZE→WITNESS pipeline and route the result through the gate.
It owns *no* algorithm — it *composes* the real organs. This is the only substantial new module.

```
  + sw_ingest(kind: u32, src: u64, len: u64) -> u64        // -> artifact handle (bounded, in-arena); 0 on over-capacity
  + sw_seal(artifact: u64) -> u64                          // -> artifact_digest (cad/mhash);   the "freeze"
  + sw_lift(artifact: u64) -> u64                          // -> lifted fragment handle (computation_graph IR); 0 on malformed
  + sw_analyze(fragment: u64, property_id: u32) -> u64     // -> analysis result (verdict + proof/counterexample handle)
  + sw_witness(artifact_digest: u64, result: u64) -> u64   // -> sealed witness handle (cad-addressed)
  + sw_admit(witness: u64) -> u32                          // -> 99 ADMIT iff proof verifies, else REJECT (gate)
  + sw_replay(fragment: u64, input: u64, steps: u64) -> u64// FR-8: bounded pure interpret -> resulting-state digest
  Events: none (pure pipeline). All effects are arena writes + cad seals.
```
DEPENDENCIES: cad, mhash (seal), egraph (saturate), smt (decide), proof_term (proof), temporal_logic +
computation_graph (lift + bounded check), commit_gate + integrity (gate), arena/region (bounded memory),
fs/net (ingest). **All REAL or symbolic-as-model.** No new primitive.
SCALABILITY: stateless across artifacts; each artifact is independent and content-addressed (trivially
parallel — one witness per artifact, like one KAT per corpus entry).

### COMPONENT: `legacy_artifact` (THE BOUNDED TYPE) — minimal new data type
RESPONSIBILITY: a typed, length-bounded, arena-backed view over captured bytes with a declared `kind`
(DUMP | TRACE | PCAP | REGS), plus the OOB-reject discipline from scans 5/6 (every accessor bounds its
index; no over-read past the declared length). Owns the bytes + the digest. ~1 small module.

### REUSED AS-IS (no change): cad, mhash, egraph, proof_term, smt, fs, net, tcp, commit_gate, integrity,
arena, region, computation_graph, temporal_logic, witness_spine, reversible (as sandbox-rollback only).

---

## 5. Data Architecture

| Entity | Owned by | Storage | Access |
|---|---|---|---|
| captured bytes | legacy_artifact | arena (bounded) | write-once, read-bounded |
| artifact_digest | cad | 32-byte seal | by-value |
| lifted fragment (comp-graph) | computation_graph | arena | DAG, bounded |
| proof term / counterexample | proof_term | arena | tree, verified at gate |
| sealed witness | witness_spine + cad | 32-byte digest + record | content-addressed, immutable |

**Data flow:** `bytes --ingest--> artifact --seal--> digest --lift--> fragment --analyze--> {verdict, proof}
--witness--> sealed_witness --gate--> {ADMIT|REJECT}`. Every arrow is total and bounded; every node after SEAL
is content-addressed, so the entire pipeline is a **Merkle dataflow** — tamper anywhere changes the final
witness digest (this is the spec's "imperceptible + tamper-evident" property, for free, from cad).

**Consistency:** strong within a witness (single arena, deterministic); witnesses are independent
(content-addressed, no shared mutable state). Determinism is the consistency model.

---

## 6. NOT ACHIEVABLE AS SPECIFIED (the named boundary)

This section is the architecture's most important deliverable. Each item below is **stated for you to
decide on**, with the reason it is a boundary rather than a hard problem awaiting ten breakthroughs.

### 6.1 Live Ring-−1/−2 descent ("exist outside the TV", at the *ring* level) — **UNWIRED, future hardware program**
The ring/hypervisor layer (`ring_lattice`, `svm_layout`, `vmexit`) is, in source, a **verdict lattice**: it
computes *which* ring constructor is lawful and *whether* a metal write is admissible, and returns enums/u8.
It does **not** issue `IOCTL`/`magic-MSR`/`VMRUN`/`SMI` or touch a VMCB/NPT. The katabasis memo confirms the
live state is **Ring-0, partial** (an IOCTL primitive exists; the hypervisor/SMM path is unwired, `ntoskrnl`
link remains). Becoming the *physical* television set — pausing a real CPU from Ring-−2 and projecting state
— is a **hardware bring-up program** (write a real hypervisor / SMM handler, drive real VMCB/NPT), not a
software composition. It is **out of scope** for a production-grade-first software delivery, and would be its
own multi-increment katabasis track. *The Witness as designed does not need it:* it consumes artifacts a
probe (which may, one day, be that hypervisor) produces. **Decision for you:** keep the descent as a separate
hardware track, or re-scope this delivery to include hypervisor bring-up (which forfeits "production-grade the
first time" — real Ring-−2 code BSODs before it works; see the crash-debugging protocol).

### 6.2 "Prove *exactly* what the legacy program *will* do" — **UNDECIDABLE for arbitrary code**
Total functional behavior of an arbitrary program is the halting problem; no architecture, and no number of
breakthroughs, removes Rice's theorem. **What is real and delivered:** *bounded* model checking (decidable
over a finite unrolling), decidable-fragment SMT, specific-vulnerability proofs ("*this* overflow on *this*
path"), and equality saturation. The Witness proves **what is decidable** and returns **ABSTAIN + the horizon**
otherwise (FR-7). This is strictly more honest — and therefore more sovereign — than a system that claims
total prediction and is silently wrong on the first Turing-complete input.

### 6.3 "Derive the exact RAM the system *would* have if it received a packet, *without simulating*" — **identity, not a free lunch**
`state_after = transition(state_before, packet)` — computing the right-hand side *is* executing the transition.
The spec's "synthesize the state without a packet traversing copper" is achievable (FR-8: a pure, in-arena,
host-effect-free interpreter), but it is **a simulation** — a sound, deterministic, content-addressed one. The
only thing eliminated is the *wire*, not the *computation*. We deliver exactly that (and it is genuinely
valuable: deterministic, replayable, sandboxed forward-execution + a sealed result state). We do **not** claim
the computation is skipped, because that claim is `P = transition without computing transition`.

### 6.4 Live memory/register injection into a *running* legacy system — **no path; same dependency as 6.1**
Writing another running system's RAM/registers requires the Ring-−1/−2 descent of 6.1 (NPT remap + CPU
unpause). In the offline analyzer, the analogue is **sandbox replay** (FR-8) over the *frozen* artifact —
real and sound. Injection into a *live* foreign machine is out of scope with 6.1.

> **The directive collision, surfaced honestly (your call):** your standing order is *"ten world-class
> breakthroughs over one concession"* AND *"no placeholders, working code production-grade the first time."*
> For 6.1–6.4 these collide: the only way to "deliver" the literal clauses now is a module that compiles and
> passes exit-code KATs while *modeling* a descent/omniscience it does not perform — which is precisely the
> pretend-success stub the second order forbids. I have resolved the collision in favor of the **deeper**
> order (working, falsifiable, no-placeholder) by building the real analyzer in full and **naming** 6.1–6.4
> rather than faking them. If you want 6.1/6.4 pursued for real, that is the **katabasis hardware track** — a
> different, longer, BSOD-first program I will scope separately on your word; it cannot be "production-grade
> the first time" by the nature of Ring-−2 bring-up, and pretending otherwise would be the concession.

---

## 7. Decision Log (ADRs)

**ADR-SW-1: The Witness consumes captured artifacts; it does not capture live state.**
*Status: Accepted.* The capture step requires the unwired Ring-−1/−2 descent. Decoupling "capture" (a probe's
job) from "witness" (III's job) makes the entire analyzer REAL and composable today, and leaves a clean seam
for a future hypervisor probe to fill. *Consequence:* the spec's "the TV set captures the state" becomes "a
probe captures; III is the mathematician that receives the sealed capture." Spirit preserved, physics honored.

**ADR-SW-2: Every stage output after INGEST is content-addressed (Merkle dataflow).**
*Status: Accepted.* Reuses cad/mhash. Gives tamper-evidence and determinism for free; makes the witness a
"frozen mathematical object" literally. *Consequence:* re-running on identical bytes is a cache hit by digest.

**ADR-SW-3: ABSTAIN is a first-class verdict.**
*Status: Accepted.* The witness never asserts beyond the decidable horizon (6.2). *Consequence:* honesty is
tested (an ABSTAIN arm per property), aligning with the prove-the-negative discipline.

**ADR-SW-4: Admission is the existing commit_gate/integrity, not a new gate.**
*Status: Accepted.* The Witness is "ripple over external artifacts" — reuse the trust root. *Consequence:* one
gate discipline across self-enhancement and witnessing; no second, divergent gate.

**ADR-SW-5: SYMBOLIC analysis modules (computation_graph, temporal_logic) are used *as models*, deliberately.**
*Status: Accepted.* An analyzer SHOULD be built on a symbolic model of the analyzed code. Their "symbolic"
classification is a fit, not a flaw — provided their verdicts are bounded + gated (which they are).

---

## 8. Risks

| Risk | Impact | Mitigation |
|---|---|---|
| A SYMBOLIC analysis module is mistaken for a sound prover | False PROVEN | Gate every PROVEN on a verifying proof_term (FR-6); bounded horizon explicit (FR-7) |
| Lift over-reads a malformed artifact | OOB (the scan-5/6 class) | legacy_artifact bounds every accessor; lift refuses over-capacity (OOB-reject KAT) |
| Scope creep into the hypervisor track | "production-grade first time" lost | 6.1/6.4 explicitly out of scope; separate katabasis track only on user's word |
| The witness is mistaken for live interception | Operational misuse | Doc + the witness record states `kind` + that it is offline-over-a-capture |
| Determinism break (Date/rand in pipeline) | Non-reproducible witness | Pure arena pipeline; no Date.now/rand (the iii determinism discipline) |

---

## 9. Implementation Roadmap (compounding order — each a quick-gated, prove-the-negative increment)

```
SW-0  [LANDED 02c38d0] legacy_artifact: the bounded type + OOB-reject accessors + the cad seal of raw
      bytes. Falsifier 415: identical bytes -> identical digest; 1-bit flip -> different; over-cap ingest
      -> reject; la_byte past len -> 0; digest-before-seal -> rejected.                                     [REAL]
SW-2/3/4  [LANDED 5ba4244] sovereign_witness: lift the TRACE records (OOB-bounded) -> analyze ONE sound
      property (AFFINE-ACCESS SAFETY = the scan-5/6 wrap/bounds class, PROVED over a captured program) ->
      witness (cad-seal the verdict) -> admit. IMPLEMENTATION NOTE vs the original plan: the first property
      is decided by a DIRECT, sound, u64-exact closed-form check (constant stride -> extreme at i=count-1),
      NOT SMT -- SMT's authority is search (non-constant stride / disjunctive paths), and smt_lia's i64
      operands would misread 2^63..2^64; one authority per concern. The gate's TEETH = re-derivation from
      the sealed bytes (sw_admit), not a structural pt_verify. Falsifier 416 (adversarial on the soundness
      edges): safe->PROVEN; OOB->REFUTED_BOUNDS+exact i; 2^63..2^64 operands sound; WRAP-ONLY->REFUTED_WRAP
      (never PROVEN); pipeline ABSTAIN/MALFORMED; sw_admit REJECTS a forged verdict.                        [REAL, the heart]
SW-5  [LANDED 1464c83] sw_replay (FR-8): bounded pure host-effect-free interpreter; reproduces a refuted
      counterexample (the exact wrapped/OOB address) + content-addresses the bounded forward state.
      Falsifier 417: replay_at safe + wrap-to-0; refute->reproduce; replay_seq deterministic + over-horizon
      -> ABSTAIN.                                                                                           [REAL]
SW-6  [PENDING] POLISH: one full corpus+bench+stage1 gate (reserved for the very end per the standing
      quick-gate directive); ledger; the witness as a corpus citizen.
--- NEXT, the maximal compounding (the user's meta-goal "compound III's ability to enhance ITSELF") ---
SW-INWARD  [LANDED a385aa9, honest form] Turn the witness INWARD. The affine-safety prover is EXACTLY
      what certifies a self-edit does not reintroduce the scan-5/6 class. Corpus 419 encodes III's OWN
      access contracts and has the witness CERTIFY the scan-5/6 guards are SUFFICIENT (PROVEN at the guard:
      xii audit stride-64 @ count<=0x03FFFFFF; xii_chd stride-16 @ bucket_idx<144) and NECESSARY (REFUTED
      beyond: REFUTED_WRAP at ~2^58, REFUTED_BOUNDS at the first OOB index) -- III formally proving its own
      self-enhancement safety. A standing self-safety regression gate for the scan-5/6 class.
      NOTE on the FULLY-AUTOMATIC form (a self-edit's pattern auto-extracted + proved in commit_gate): that
      needs a source->affine-descriptor EXTRACTOR, which is LIBNATIVE-BLOCKED (III's parser lives in the
      compiler, not libiii_native.a; calling it would drift the golden hash). The honest landed form uses
      human-accurate contracts (the prover is real + sound; the descriptors are the documented access
      contract). The auto-extractor is a future compiler-track increment (a real iii AST pass), not a stub.
```

Each SW-n is LIBNATIVE (compiler untouched), arena-bounded (NIH), and carries a constructible negative. The
order compounds: SW-0/1 give the frozen object; SW-2/3 give the proof; SW-4 gives the seal+gate; SW-5 gives
the sandbox future-projection — at which point III genuinely *sits in front of the television set, pauses the
(captured) picture, proves what the script must do within the horizon, replays the branches in a sandbox, and
seals the verdict* — every word of that sentence now backed by a passing, falsifiable KAT.

---

*This document is the calibrated-abstention discipline applied at architecture scale: it builds the maximal
real thing and refuses to fake the rest. The Sovereign Witness is sovereign precisely because it knows — and
proves — the edge of what it knows.*
