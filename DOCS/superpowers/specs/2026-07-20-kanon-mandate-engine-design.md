# THE MANDATE ENGINE — design spec

> Turning prose disciplines into refusable law, with AI admitted only as a scrutinized proposer.
> Date: 2026-07-20. Status: design, pre-implementation.

## 0. The finding

A **skill** is prose read by a model. Its compliance is *unobservable*: the model can say "I used TDD"
and nothing in the world contradicts it. That is why the CRASH DEBUGGING PROTOCOL in `CLAUDE.md` ends
with an enforcement clause that delegates to a **human** — "the user MUST reject the change." The
protocol is correct and it still failed five times, because exhortation has no refusal.

III is the opposite kind of thing: nothing stands unless proven; the law refuses. So the gap was never
"III needs more skills." It is:

> **Process compliance is currently an unwitnessed claim — and III already refuses unwitnessed claims.
> It has simply never been pointed at itself-in-use.**

### The ONE law

> **A claim stands only if the witnessed trace DETERMINES it. A claim that adds rank to its own
> evidence is a claim the work never established — a forgery — and is REFUSED.**

This is not a new law. It is the law already proven in four places:

| Where | The same law, in that substrate |
|---|---|
| `omnia/kanon.iii` | `x ∈ Fold(G) ⟺ rank(G ∪ {x}) = rank(G)`; the **defect** is the non-derivable remnant |
| `omnia/eidolos.iii` | `eol_judge_claim` = membership filter; `[x < x]` refused |
| `omnia/elenchos.iii` | ZK under-constraint: `rank < vars` ⇒ forgery |
| `zk-hunt/determined.js` | a signal not forced by the constraints is UNDER-CONSTRAINED |
| `omnia/ontos.iii` | `image ≤ domain`; progress from nothing is impossible |

**A process claim is an R1CS.** The pinned events are constraints; "this work is done/correct/verified"
is the output signal. If the trace admits a second witness in which the work was *not* done, the claim
is under-constrained. `defect(T ∪ {C}) − defect(T)` is then not a metaphor — it is the **measured size
of the unearned assertion, in bits.**

### The one thing that is genuinely new

`kanon.iii` proves the rank realization and the EIDOLOS entailment realization are one theorem. Process
traces are **directed** — RED-before-GREEN is a `<` relation — so process mandates ride the **EIDOLOS
twin**, not the rank meter. Applying the undirected matroid closure to a directed order is the exact
category error already recorded (SYMPLOKE: undirected matroid on directed order, 3≠4), re-founded
event-primary by ANAMNESIS. This spec inherits that correction rather than re-earning it.

---

## 1. What "mandate" means, precisely

Three targets, and each is achievable at a different depth. Stated honestly, including where the
mathematics says stop.

### 1.1 Mandate FUNCTIONS — what a thing does

Every `@export` carries a **ὅρος** (horos: a boundary-stone; in logic, a *term/definition*): a contract
of pre/post conditions as EIDOLOS scrolls, plus a being-signature from ONTOS (`=` FLAT / `~` REFLECT /
`<` BELOW). The ratchet already exists in practice ("arm-cover new exports or cut", RATCHET-DELTA-ZERO).
The mandate elevates it from gate-time to **link-time**: an export whose obligation is not discharged
does not link. The compiler refuses.

*The AI's role:* MANTIS **proposes** the contract by reading the function; III **decides** by discharging
it exactly. The muse never writes law.

### 1.2 Mandate COMPLEXITIES — three senses, all real

- **Cost.** III is bit-deterministic, so step counts are *exact and reproducible* — not benchmarks. An
  organ declares an envelope `T(n) ≤ c·f(n)`; the gate measures at several `n` and REFUSES on violation.
  **Honest boundary:** inferring asymptotic complexity in general is undecidable. A *measured envelope
  with a refusal* is not — and it is what a mandate actually needs.
- **Descriptive (anti-bloat, mandate #9).** ONTOS's injectivity meter generalizes: if a module's
  behavior table is a lossy shadow of an existing one, it is `[dup < origin]` — **redundant by
  measurement, not by opinion.** This makes the capability-redundancy audit machine-decidable.
- **Proof.** A certificate must be checkable in bounded time (proof-carrying, SLIP=0 — already built).

### 1.3 Mandate MENTAL MODELS — the interesting one

A mental model is not a mood. Operationally it is a **typed lens**: a transformation on a claim-graph
with an exact **discharge predicate**. Prose says "use first principles" and is unfalsifiable. The
mandate form is checkable:

| Lens | Discharge predicate (exact) |
|---|---|
| First-principles | every leaf of the decomposition is either an EIDOLOS-standing axiom scroll **or** a pinned measurement. One unpinned assertion ⇒ REFUSED. |
| Pre-mortem | every named failure cause carries a *runnable* falsifier, the falsifiers were RUN, none fired. A cause with no falsifier is an unfalsifiable hedge ⇒ REFUSED. |
| Pareto / leverage | the ranking is over **pinned measurements**, never self-assigned weights. (Kills self-grading directly.) |
| Inversion | ¬C's strongest case exists and is refuted by a pin — an ELENCHOS refutation certificate. |
| Adversarial verify | the verifiers are **provably distinct** (§2.3). |
| Calibrated confidence | the number derives from a pinned frequency (DOXA, DERIVED-only evidence) or it is not a number. |

---

## 2. The seats

Reuse-first. Four of the six already exist on disk; two are new.

| Seat | Greek | Status | Role |
|---|---|---|---|
| **KANON** | κανών, measuring-rod | **exists** (`omnia/kanon.iii`, 164 lines) | the filter: is the claim inside the fold of its evidence? defect = the unearned bits |
| **PRAXIS** | πρᾶξις, the deed | **new, thin** | the pinned trace; rides `omnia/exec_cert.iii` (incremental sha256, O(1)/event, tamper-evident, bit-identical) |
| **DOKIMASIA** | δοκιμασία, the scrutiny of officials before office; δοκιμάζω = to assay metal for purity | **new** | the oracle assay — measures whether an AI verdict carries information *before* it may count as evidence |
| **HOROS** | ὅρος, boundary-stone / definition | new, Tier 2 | function contracts at link-time |
| **METRON** | μέτρον, measure | new, Tier 2 | cost envelopes + descriptive redundancy |
| **PHRONESIS** | φρόνησις, practical judgment | new, Tier 2 | lenses as first-class values with discharge |

Adoption of *new* mandates rides `omnia/governance.iii` unchanged — its state machine is already
PENDING → SANDBOXED → PROVEN → ACCEPTED → SEALED with quorum, equivalence proof, and witness chain.

### 2.1 The binding — the actual missing tooth

`.claude/settings.json` currently contains only `enabledPlugins`. **There are no hooks.** Twenty-one
gates exist and every one of them runs only when someone remembers to run it.

The load-bearing edge is the **Stop hook** — the single point where "the agent claims done" crosses into
the user's belief. Binding:

- `PreToolUse` → `iii praxis step` records the intent (and enforces phase order, e.g. refusing `Edit`
  on `.sov`/`.iii` while the CRASH PROTOCOL is in Phase 1).
- `PostToolUse` → the **hook**, not the agent, appends the pin (digest, exit code, git hash).
- `Stop` → `iii kanon judge` refuses completion when the claim is not in the fold of the trace.

Every other intervention is upstream noise.

### 2.2 The non-negotiable requirement: the agent may not author its own pins

The killer attack on this whole design is that **the trace is self-reported** — an agent that writes its
own trace can write a compliant trace with the work undone. Therefore:

> **The agent may append CLAIMS. Only the harness/OS may append PINS.**

Pins are things no model can author: file content digests, process exit codes, git object hashes, gate
stdout. This is the `anchor-never-yardstick` law applied to process. A mandate whose leaves are
agent-authored strings is theatre.

### 2.3 DOKIMASIA — the purification of AI

Admitting an LM's judgment as evidence *because it sounds right* builds a sycophancy machine with a
Greek name. The assay is exact and it already has a meter:

> A verifier `v: Claims → Verdicts` that always answers "pass" has **image 1**, therefore `log₂(1) = 0`
> bits, therefore its verdict is **independent of its input** and carries no information. ONTOS's image
> meter detects this today.

So: before any oracle (MANTIS, an LM reviewer, a judge panel member) may serve as evidence, it is run
against a **pinned probe set containing known-bad mutants**, and its verdict-map's image is measured.
Image 1 ⇒ rubber stamp ⇒ evidential mass 0 ⇒ faded to the void ⇒ **REFUSED as evidence**. This is a
mathematical anti-sycophancy law, not a vibe.

Two consequences fall out for free:

- **Lens diversity becomes measurable.** Three verifiers whose verdict-tables are FLAT-equal are one
  verifier consulted three times. Genuine diversity = the joint image exceeds any single member's.
- **TDD's RED step *is* a mutation probe.** A test that has never failed does not determine that it
  tests anything — it could pass with the feature absent. Mutation-GREEN, RED-before-GREEN, and
  determinedness are one law wearing three hats.

---

## 3. The exhaustive inventory — harness surface → III law

What was asked: *what here can be reimagined and instilled?* Everything below is present in this
environment today.

### 3.1 Process skills → mandates

| Harness skill | III seat | What becomes mandatory |
|---|---|---|
| brainstorming | HERMENEUS / PROBOLE | no edit without a standing design scroll (propose/decide wall) |
| writing-plans | KANON | every task carries its cheapest falsifier; a task without one is a defect |
| executing-plans | PRAXIS | checkpoints are pins, not narration |
| test-driven-development | DOKIMASIA | RED-first = the mutation probe; a never-failed test carries 0 bits |
| systematic-debugging | PRAXIS + PreToolUse | CRASH PROTOCOL phase order enforced mechanically, not by the user rejecting changes |
| verification-before-completion | **KANON @ Stop** | the load-bearing mandate: pin before claim |
| requesting/receiving-code-review | DOKIMASIA | a reviewer must pass the assay before its verdict counts |
| refactor | `aether/bisimulation_witness.iii` | behavior preservation is *witnessed*, not asserted |
| transform-ontological | ONTOS | the being-signature is measured |
| deep-think | PHRONESIS | the battery's lenses each carry a discharge predicate |
| architect / systems-map | METRON | leverage ranked over measured couplings |
| creative-solve | KANON | "the constraint you assumed was fixed" = an unpinned axiom; III can *enumerate* them |
| qa-verify / code-review | DOXA | confidence is a modal type with derived-only evidence |
| math-olympiad | EIDOLOS | calibrated abstention = the REFUSED verdict, already native |
| explore-codebase | ERGON census | re-derives live; no stored expectations |

### 3.2 Harness mechanisms → III organs

| Mechanism | III counterpart | Note |
|---|---|---|
| **Hooks** | — | **the enforcement arm III lacks; currently unused** |
| Workflow: adversarial verify, judge panel, diverse lenses | PHRONESIS + DOKIMASIA | diversity becomes measurable, not assumed |
| Workflow: `no silent caps` | NAMED-DEFICIT LAW | already III law — exact convergence |
| Workflow: loop-until-dry, completeness critic | AUXESIS / the six-day loop | built (`zk-hunt/loop.sh`) |
| Structured output schemas | XENIA / XENOS transduction | prose never crosses the membrane; only scrolls |
| Effort / token budget | NOESIS | overrun is a refusal, not a silent continuation |
| Memory (typed frontmatter) | KARDIA | claims go **DUE when their pin drifts** — already the law; wire agent memory into it |
| Permissions / allowlists / ToolSearch | `capability.iii`, `cap_forge.iii` | least-privilege by **attenuation from a root cap**, with proof |
| Plan mode / ExitPlanMode | HERMENEUS | the propose/decide wall, at harness level |
| Cron / loop / schedule | the six-day gene | built |
| Artifacts | HENOSIS | externalization → sealed standing |
| MCP | XENIA membrane | foreign tools transduced, never trusted |
| Subagent worktree isolation | rank condition | parallel writers must have provably disjoint write-sets |

### 3.3 The `iii-master` MCP — the highest-leverage single move

Eleven tools already exist and are already reached for: `iii_deep_think`, `iii_sequential_think`,
`iii_adversarial_verify`, `iii_proof_obligations`, `iii_check_discharge`, `iii_invariant_guard`,
`iii_math_rigor`, `iii_gate`, `iii_run_kat`, `iii_standards`, `iii_session_law`. The server already has
process-spawn capability (7 call sites).

**Swap their guts from reasoning-scaffold to real III verbs and every existing call site becomes
unlieable — with zero new UX.** `iii_check_discharge` stops being a prompt that asks the model to
reflect, and becomes `iii kanon discharge <obligation>` returning an exit code.

---

## 4. Tiering

| Tier | Content | Depth |
|---|---|---|
| **0 — wire what exists** | PRAXIS over `exec_cert` + KANON's EIDOLOS twin; hooks in `settings.json`; `@export` the ONTOS meters | days |
| **0b — the MCP swap** | the eleven `iii-master` tools → thin clients over real III verbs. **Separate plan: different repo** (`Desktop/iii-master-mcp`), therefore a different subsystem | days |
| **1 — first mandates** | DOKIMASIA + 6–10 mandates (RED-first, read-before-edit, gate-after-edit, claim-has-pin, no-self-grading, crash-phase-order) | 1–2 weeks |
| **2 — the depth** | HOROS (link-time contracts), METRON (cost envelopes + redundancy), PHRONESIS (lens algebra) | weeks |
| **3 — mandate learning** | MANTIS proposes a predicate from prose skill text; it is scored on the repo's **own history** (reverted/fixed commits = labeled bad traces); adopted via `governance.iii` **only if measured separation clears a threshold** | research |

Tier 0 is not merely first in value — it is the **data-generating step**. Tier 3's corpus does not exist
until traces accumulate.

## 5. Honest boundaries

1. **Sound, not complete.** Deciding "did the agent truly follow the discipline" is not decidable in
   general. The achievable guarantee is the one already chosen for `determined.js`: **no false
   negatives** — refuse unless determined. Over-refusal is the cost, and **idiom certifiers** are the
   cure, exactly as `Num2Bits` is certified so range checks do not false-flag.
2. **`determined.js` is a script, not a library** (`process.argv[2]`, no exports). Generalizing it to
   trace-R1CS requires a real library extraction — small, but not free.
3. **ONTOS's meters are not exported.** Only the selfprove arms and `ont_show` are `@export`. DOKIMASIA
   needs `ont_table_verb` / `ont_image`; each new export must arrive with its arm (the ratchet).
4. **A Stop hook that mis-refuses makes a session unstoppable.** Every refusal must print the *named*
   missing pin, and override must be **recorded, never silent** (NAMED-DEFICIT LAW).
5. **The theology is load-bearing but not proven.** ONTOS's ground-state claim is a wager with
   structural warrant; the mandate engine depends only on the theorem half (exact identity, determined
   traces), not the metaphysical half.

## 6. Kill-switches

- If Stop-hook refusals are **>30% false** after two weeks, the predicate set is wrong. Stop adding
  mandates; fix separation — or this becomes another disabled linter.
- If DOKIMASIA finds MANTIS's verdict-map image is ~1 on real probes, **the AI is not admissible as a
  verifier at all**, and Tiers 1–3 shrink to III-exact checks only. That is a legitimate outcome and
  must be reported, not engineered around.
- If Tier 3's learned predicates cannot beat a hand-written baseline on separation, mandate-learning is
  vapor and gets cut.
