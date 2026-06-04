# III — Beyond Strict Determinism (a contemplation)

**Status: CONTEMPLATION — NOT a sealed spec.** No closure hash, no conformance criteria, no
seal slot. This explores the design space that opens *if* strict determinism is relaxed. Every
claim about what **EXISTS** is cited to a live doc/section; every **CONTEMPLATED** item is a
proposal, not a built faculty. Nothing here is implementable until a direction is chosen and a
real plan is written.

**Date:** 2026-06-03 · **Question:** *If no longer bound by strict determinism, what integrations
or adjustments would drastically enhance / realize / deepen / expand III's potential?*

---

## §0. The reframe — III already made the move

The naive reading of the question is "add nondeterminism." That reading is **wrong**, and the
code proves it. III has already separated the two halves of every act:

> **A faculty is a pair `(P, D)`** — a generator `P` and a disposer `D : 𝕋 → 𝔹`; a proposed
> `x ∈ im P` is *admitted* **iff `D(x) = 1`**. 【EXISTS: III-INTERIOR-LOGIC-ATLAS §Σ₀ Ax D1】

And the disposer is, by axiom, **statistic-blind**:

> `D = f(derivation)`, `D ⊥ (freq, sample, param)` — no disposer reads a frequency, a sample, or
> a parameter. 【EXISTS: Atlas Ax D3】

`nous` (the proposer faculty, **BUILT 2026-05-25**) already ranks candidate next-terms and "hands
the ordered list to the deterministic engine, which checks each … exactly as if a blind
enumerator produced it." Its charter redrew the Prime Directive in precisely these terms:

> "Statistical learning is forbidden on any path that DECIDES or ASSERTS, and permitted ONLY on a
> path that PROPOSES and is CHECKED." 【EXISTS: III-NOUS-ARCHITECTURE §5 `nous_charter`】

And replay-determinism is already the discipline, not a goal:

> "replay **is** determinism (Π5) made auditable"; wall-clock is *rejected at construction*
> "because it would break replay"; certified results key on `cad(input‖ruleset‖costlin)` and
> **omit the proposer's weights** — "true regardless of which `nous` found it … the certified
> commons accumulates *across retrainings*." 【EXISTS: III-APOTHEOSIS; III-NOUS §2 B-5】

**Therefore the thesis of this contemplation:**

> Determinism in III is *already* a property of three things — the **disposer** (Ax D3), the
> **replay-witness** (Π5), and the **content-address seal**. It is **not** a property of the
> computation's process. III does not need determinism *relaxed*; it needs the freedom it already
> built — the proposer/disposer split — **exercised**, where today it is exercised timidly.

Every organ below keeps all three invariants intact while freeing the interior.

---

## §1. What is still on the leash (the real frontier)

| # | Binding still in force | Where it bites |
|---|------------------------|----------------|
| L1 | The proposer is a **deterministic integer ranker** (`nous_policy`), not a trained/real-valued one — though `nous_charter` *permits* the latter | 【EXISTS: III-NOUS §6】 "a richer trained model may later reorder … but must keep the gate green" |
| L2 | **Build/bootstrap is byte-exact** — the *process*, not just the artifact, is pinned (golden BARE hash, DRIFT reseal gate) | 【EXISTS: ADR-027 / determinism gate; memory: gate caught a controlled codegen break → 0/57, EXIT 5】 |
| L3 | **Confidence is quantized** (`0.85q`); arithmetic is **float-free, equality-only** even on propose paths | 【EXISTS: III-EFFECTS §5.4; III-MODULE-4 discipline "no float, equality-only"】 |
| L4 | **Execution is closed/offline** — no live external nondeterminism is admissible (time/network/sensor/RNG all rejected to protect replay) | 【EXISTS: III-NOUS §2 "wall-clock is rejected at construction"】 |
| L5 | **Single-node** — Federation / Consensus / Planetary are *documented*, not *live* | 【EXISTS: III-CONSENSUS, III-FEDERATION, III-PLANETARY (docs only)】 |

---

## §2. The organs (reweighted: safe-radical core first)

Naming follows III's idiom ("the move is X; the illegal move is Y").

### C — **The Witnessed Sense** · live nondeterminism in, determinism on replay 〔lead〕
**Relaxes:** L4 (closed/offline). **The move:** *to admit the world.*

Today every external nondeterministic input is refused to protect replay. 【CONTEMPLATED】 Instead,
admit it through a new witness kind `NONDET_OBSERVE` capturing `{source, observed-value, epoch}`,
appended to the Persistent Audit Spine exactly as the 17 IRPD *writes* already are 【EXISTS:
III-EFFECTS §2.3】. The run is **nondeterministic live, deterministic on replay** — the witness
re-injects each observed value, so a replay of a reactive run is bit-identical. This is the dual
of what IRPD already does for writes: extend the witnessed boundary from *acts on the world* to
*observations of the world*.

**Unlocks:** real I/O, interaction, reactive/real-time III, hardware RNG, a *witnessed* clock
(distinct from the rejected wall-clock — `at_advance` stays the logical clock; the wall reading
becomes a witnessed observation, not a control input). Auditability is **strengthened**, not
weakened: nothing nondeterministic happens unwitnessed.

**Safety machinery that already exists:** the audit spine + from-seed replay verifier + the
`SovVal.witness = frag_id` "record-and-produce-are-one-act" rule 【EXISTS: III-APOTHEOSIS M10】.

### E — **The Forked Walk** · speculative-parallel execution, deterministic result 〔lead〕
**Relaxes:** L2 (process pinning), partially. **The move:** *to try many roads and keep one.*

SID already derives a perfect inverse for every effect (PIP blobs, **sub-5-cycle rollback**)
【EXISTS: III-EFFECTS §3】; the worktree fan-out infrastructure already exists 【EXISTS: recent
commit "substrate baseline checkpoint for worktree fan-out"】. 【CONTEMPLATED】 Compose them:
explore many branches of a walk (proof search, e-graph extraction, lowering choice, build paths)
**in parallel**, commit the first/best to certify, and **roll the losers back via SID**. The
*schedule* is nondeterministic; the *committed result* is the unique disposer-admitted one.

**Unlocks:** order-of-magnitude search/build throughput; genuine speculation; the `nous` Search
Trichotomy 【EXISTS: III-NOUS §2】 driven by a *fan-out* of proposers instead of one. Soundness is
free: confluence already guarantees the normal form is unique regardless of path ("determinism is
a *theorem* about the one engine" 【EXISTS: III-APOTHEOSIS】), and SID guarantees the losers leave
no trace.

### B — **The Real Interior** · float on propose, discretized at the seal
**Relaxes:** L3 (float-free). **The move:** *to reason in the continuum, seal in the discrete.*

【CONTEMPLATED】 Admit real/interval/floating arithmetic **inside the propose layer only**: the
typed gap (M4) carries a **distribution or confidence interval**, not just `KNOWN`/`GAP`; epistemic
confidence becomes a real, not the quantized `0.85q`; numerical optimization and interval bounds
become expressible. This deepens the *existing* typed-gap DAG 【EXISTS: III-MODULE-4】 and epistemic
effects 【EXISTS: III-EFFECTS §5】 into genuine probabilistic reasoning.

> **⚠ IRON CAVEAT.** Float is *itself* a replay-breaker — rounding differs across hardware, so a
> float that reaches a sealed or replayed path destroys Π5. B is sound **iff a float value never
> crosses undiscretized into any sealed or replayed path.** The disposer and the witness capture
> the **discretized** result (a rational/`q`/integer), never the float. Float is a *search tool*;
> the seal is over its discretization. State this as a typed boundary or B quietly violates replay.

### D — **The Many** · distributed / consensus / planetary
**Relaxes:** L5 (single-node). **The move:** *to agree across nodes that disagree.*

【CONTEMPLATED, building on EXISTS docs】 Many nondeterministic nodes **propose**; a **witnessed
consensus** disposes; the agreed log **replays deterministically** on every node. Network ordering,
races, and failures enter through `NONDET_OBSERVE` boundaries (organ C); the agreed-upon seal is
the content-address of the committed log. This makes III-CONSENSUS / III-FEDERATION /
III-PLANETARY *live*: a planetary-scale **verifiable** computer whose global state is a replayable,
content-addressed log. Depends on C.

### F — **Many Roads, One Seal** · nondeterministic build, content-addressed artifact ⚠ MOST DANGEROUS
**Relaxes:** L2 (byte-exact bootstrap) — **fully, and at real cost.** **The move:** *to seal what,
not how.*

The principle is already proven *in the small*: certified `nous` results "omit the proposer's
weights — true regardless of which `nous` found it" 【EXISTS: III-NOUS §2 B-5】. 【CONTEMPLATED】
Generalize it to the whole build: let compilation be parallel/speculative/nondeterministic and seal
the **artifact** by content-address + a **semantic** equivalence certificate, not by byte-identity.

> **⚠ THE COST (do not gloss).** Byte-exact bootstrap is **not** determinism-as-purity — it is a
> *proven drift/codegen-break safety gate*: a codegen change shows up as a hash change (memory:
> caught a controlled break → 0/57, EXIT 5). Content-addressing a *nondeterministic* artifact does
> **not** recover drift detection — the artifact differs run-to-run by design. Relaxing L2 means
> **replacing byte-equivalence with a weaker semantic seal**, and that replacement's soundness
> (does it still catch a codegen regression?) is an **open obligation**, not a given. This organ is
> listed for completeness; it should move last, if at all.

### A — **The Trained Eye** · a learned proposer 〔a FORK, not a recommendation〕
**Relaxes:** *nothing* — the disposer stays deterministic (Ax D3). It exercises an
already-*granted* freedom rather than relaxing determinism. **The move:** *to rank by experience.*

The certified commons is a perfect, ever-growing, ground-truth-labeled corpus (every
`SATURATED`/`REFUTED` is a labeled example; the key "accumulates across retrainings" 【EXISTS:
III-NOUS §2】). The constitution **permits** training `nous` on it (float weights, real ranking),
disposer untouched.

> **THE GENUINE DECISION.** `nous_charter` *permits* a trained proposer; your standing practice
> *refuses* statistical learning anywhere ("no observational/statistical learning **ever**",
> reaffirmed). **Permitting ≠ wanting.** A coherent reading is that the charter line was drawn to
> *bound* learning (if it ever happens, this is the only safe place) — which is exactly why
> `nous_policy` is a finished deterministic integer ranker, **not** a stub awaiting weights. So
> this is not "the intelligence is stubbed." It is a values question only you can answer:
> **permitted-but-unwanted, or not-yet?**

---

## §3. The unifying principle — the Witnessed Boundary

All of C/D/E (and the safe reading of B) are one idea: **move the determinism boundary inward.**
Determinism stops being a property of the *whole process* and becomes a property of *every
boundary the process crosses*. Inside the boundary: free (parallel, real-valued, reactive,
speculative). At the boundary: a witness makes the crossing **replayable and sealable**.

This has an exact mirror in III's existing design. The six PFS bricking operations are not
*forbidden* — their hexads are unreachable, so they are **structurally inexpressible**
【EXISTS: III-EFFECTS §1.3】. The contemplated iron rule is the same shape:

> **No seal without a complete replay-witness.** Nondeterminism that cannot be witnessed for
> replay is the **new bricking-class** — structurally inexpressible at the sealed boundary, exactly
> as the six PFS operations are. Unwitnessable nondeterminism `@safety(UNREPLAYABLE)` is an
> uninhabited type.

This is why the reframe *grounds* ambition rather than capping it: the more of the interior you
free, the more the witnessed boundary is doing — and it is the part that was already built.

---

## §4. Soundness ledger

| Organ | Relaxes | Existing machinery that makes it safe | Residual risk / open obligation |
|-------|---------|----------------------------------------|----------------------------------|
| **C** Witnessed Sense | L4 closed | audit spine, from-seed replay, `SovVal.witness=frag_id` | new witness kind must be *total* (every observation witnessed) — same shape as IRPD-Only |
| **E** Forked Walk | L2 (process) | SID inverses (sub-5-cycle), confluence uniqueness, worktree fan-out | committed-branch selection must be a *disposer* decision, not a race |
| **B** Real Interior | L3 float | typed gap DAG, epistemic effects | **float must never cross undiscretized into a sealed/replayed path** (§2-B caveat) |
| **D** The Many | L5 single-node | (depends on C) witnessed consensus, content-addressed log | consensus protocol itself must be replay-witnessed end to end |
| **F** Many Roads | L2 (fully) | B-5 weights-omission precedent | **drift detection must be recovered by a proven semantic seal** — open |
| **A** Trained Eye | none | Ax D3 disposer-blindness, `nous_charter` verify∧falsify+canary | **values question** (permitted-but-unwanted vs not-yet), not a soundness one |

---

## §5. The recommended path

1. **Lead with C + E.** They are the safe-radical core: they genuinely relax determinism, every
   soundness primitive they need (record-replay, SID inverses, fan-out) **already exists**, and
   they touch neither the ML line nor the bootstrap gate. Together they make III **reactive and
   speculative** while remaining fully witnessed.
2. **Then B**, with the discretize-at-the-boundary caveat formalized as a type — unlocking real
   probabilistic reasoning in the gap/epistemic layers.
3. **Then D**, once C exists — III as a planetary verifiable computer.
4. **A and F are decisions, not tasks.** A is a *values* fork (yours alone). F is the *dangerous*
   one (must first prove a semantic seal recovers drift detection). Neither should be built on
   momentum.

## §6. What III becomes (the crescendo)

If C+E+B+D land, III is no longer an offline, single-node, byte-frozen evaluator. It is a
**reactive, speculative, real-valued, planetary substrate that is nondeterministic in its living
and deterministic in its witness** — every sense witnessed, every speculation reversible, every
node in agreement, every continuous inference sealed at the discrete boundary. The determinism was
never in the process. It was always in the disposer, the replay, and the seal — and those only get
*stronger* as the interior is freed.

*Contemplation only. Written uncommitted (the working tree is mid-reseal). Choose a direction and a
real plan follows.*
