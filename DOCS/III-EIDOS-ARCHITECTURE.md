# III — EIDOS: the Self-Describing Unified Ripple Substrate
### One geometric quantum (ripple ≡ inverse-event), self-describing by its *eidos*, modelessly self-composing, grounded reversibly at a hardware-agnostic seam
> **Date:** 2026-06-20 · **Author pass:** /architect · /deep-think · /creative-solve · advisor-reviewed · adversarial-calibrated
> **Status:** ARCHITECTURE / DESIGN. Marks EXISTS / NEW / SPECULATIVE crisply. The grounding (§9) is the **open core** — designed against KATABASIS §0.6 failure data, *not* presented as solved.
> **Leverage base (read this session):** `omnia/{ripple_field,vec,crystal,isub,event_substrate,dome,assimilate,master_logic,unravel,exec_cert}`, `numera/{reversible,logic6}`, `DOCS/III-KATABASIS.md §0`, `build_stdlib.sh`/`run_corpus.sh`, `III-INVERSE-LIBRARY.md`, `III-TRAJECTORY-AUDIT.md`, `III-DOME.md`, `III-EVENT-SUBSTRATE.md`.
> **Greek:** *εἶδος (eidos)* = the essential form/shape of a thing. Answers the directive's "numbers are too stupid; verbs, symbols, shapes are." Every ripple is known by its **eidos**, not a number.

---

## 0. EXECUTIVE SUMMARY

III today is a pile of ~660 modules with **no self-location and no self-description**. A pipeline through it does exactly one thing well and cannot reshuffle: it can't reorder for a different task shape, and it can't *not* invoke the battery-eating organ when the task is simple. That is the user's diagnosis — *"III is a mess, and because it is a mess, it is dumb."* The mess is not too few features; it is the **absence of a substrate that knows what each part is, what it costs, and where the whole thing stands on the machine.**

**EIDOS** supplies exactly that, by **leverage, not mass**. It is one move expressed five ways:

1. **One quantum (`eidos/ripple`).** The legacy spatial ripple (`ripple_field` gradient) and its inverse-form twin (the `isub`/`event_substrate`/`dome` WAVE-event) become **the same object** — a content-addressed `<verb, a, b>` geometric block that is *simultaneously* a spatial field-magnitude (read now) and a temporal logged event (folded over time). *Ripple and inverse-event are one thing.* **[PROVEN 2026-06-21 — corpus `1931_eidos_ripple_unify` + `1932_eidos_ripple_teeth` both EXIT 99; organ `eidos/ripple` sealed + wired. §11.]**
2. **Self-description (`eidos/descriptor` — the *eidos*).** Every ripple carries its **purpose + granular capability as verb-geometry** (via `assimilate`/`master_logic`/`logic6`), not a scalar. This is the "master representation system across individual ripples" — the system's self-knowledge, deterministic, **no ML, no neuro**.
3. **Modeless dynamic composition (`eidos/compose`).** A **provably-terminating, cost-bounded** deterministic planner folds a *minimal, task-specific* pipeline by reading descriptors — reordering per task shape and **pruning the battery-eating ripples when a cheap geometry suffices** (cost-Pareto), then trying/witnessing/**rewinding** via the inverse log. No fixed pipeline; no modes. **[PROVEN 2026-06-21 — corpus `1933_eidos_compose_modeless` + `1934_eidos_compose_teeth` both EXIT 99; planner mechanism on a cost fixture; nous deferred; §11.]**
4. **Reversible grounding (`eidos/anchor` — OPEN CORE).** Ground not at a fixed ring but at the one invariant every machine has — its **deterministic behavioral/silicon fingerprint** (identity, PROVEN) — then **descend the ring lattice opportunistically and reversibly** (placement, OPEN), melting deeper only where each rung *verifies*. Designed against the KATABASIS BSOD scar tissue: bricking writes are **type-unrepresentable**, every touch is **NPT-CoW reversible**, deeper rings are **observe-first**.
5. **Capitalize the network.** The ripple network + `aether` federation (`topology_atlas`, `fed_*`, `pq_quorum`) becomes the **distributed ripple field** — content-addressed so ripples dedup/merge across nodes for free. The "TON of work" pays off as the distribution layer.

**The leanness contract (falsifiable success metric).** EIDOS is *"perfectly lean, not sparse"* iff: **capability strictly up, module count flat-or-down.** The genuinely-new tissue is three folds — `descriptor`, `compose`, `anchor` — each a **fold/wrapper over existing organs, never a reimplementation**; the unification (`eidos/ripple`) lets the *split* legacy machinery (`omnia/ripple` ∥ `ripple_field` ∥ `forcefield/ripple` ∥ the isub event) **retire by attrition** (the `master_logic` `ml_named_is_redundant` mechanism, proven before deletion). If the module count goes *up*, the design has failed its own NFR.

---

## 1. REQUIREMENTS

### 1.1 Functional

```
FR-1  UNIFY: a single quantum is BOTH a spatial ripple (gradient) and a temporal inverse-event (fold),
      with one content-address binding the two views.                                  [Slice 0 proves]
FR-2  DESCRIBE: every quantum carries an eidos — its purpose + granular capability as verb-geometry —
      readable by the system without executing it.                                     [NEW: descriptor]
FR-3  COMPOSE: given a task (expressed as a target geometry), deterministically fold the minimal
      cost-optimal pipeline of quanta to reach it — reorderable per task, prunable per cost.  [NEW: compose]
FR-4  PRUNE: a simple task must NOT invoke a high-cost ("battery-eating") quantum when a low-cost
      geometry reaches the target.                                                      [cost-Pareto gate]
FR-5  REVERSE: any composition is tried on the inverse log and rewound if it is not cost-optimal,
      the abandoned branch retained as provenance.                                      [WRAPS dome/reverse_search]
FR-6  GROUND: latch onto a hardware/firmware-agnostic reliable point and descend reversibly to the
      deepest ring that VERIFIES on THIS host; never write what it can only witness.    [OPEN CORE: anchor]
FR-7  LINK: a quantum links to complementary modules systemwide via shared content-address (identical
      geometry ⇒ same address ⇒ automatic linkage).                                     [WRAPS assimilate]
FR-8  DISTRIBUTE: quanta flow across the existing federation, content-addressed + witnessed.  [WRAPS aether]
FR-9  RETIRE: the unification deprecates the split legacy ripple machinery by attrition, proven
      redundant before deletion.                                                        [WRAPS master_logic]
```

**Acceptance criteria (gated, exit-99 KATs):**
- *Given* a ripple between modules A→B, *when* read spatially (`gradient`) and temporally (`fold`), *then* both derive from the **same** content-addressed block and the witness binds them. (FR-1, Slice 0.)
- *Given* a simple task and a complex task over the same module set, *when* the Composer plans each, *then* the simple plan **omits** the high-cost quanta the complex plan includes, **reorders** as the task shape demands, and **both produce the witnessed-identical answer** a hand-pipeline would. (FR-3/4, Slice 0.)
- *Given* the Composer on any task, *when* it plans, *then* it terminates in ≤ |quanta| steps with a stated cost bound (§5.4). (FR-3 termination.)
- *Given* a melt-in touch at any ring, *when* it is wrong, *then* it rewinds with **zero persistent host damage** (reboot-survivable / NPT-CoW swap-back). (FR-6, §9.)

### 1.2 Non-Functional

| Category | Requirement | Target | Measurement |
|----------|-------------|--------|-------------|
| **Leanness** | module count vs capability | capability ↑, modules **flat-or-down** | `MODULES` count before/after; deprecation ledger |
| **Determinism** | reproducibility | bit-identical | `mhash` + corpus re-run |
| **No-ML** | learning | **zero** count-to-adapt / threshold / weight | source audit (Mandate 7) |
| **Composer cost** | planning bound | ≤ O(\|quanta\|² × cost-dims), terminating | proven bound + KAT |
| **Energy** | simple-task cost | strictly ≤ the fixed-pipeline cost | `cost_lattice`/`microarch_model` vector |
| **Reversibility** | melt-in safety | every touch rewindable; reboot-survivable | NPT-CoW snapshot/rollback KAT |
| **Agnosticism** | host coverage | latch on ANY x86-64; never #GP on vendor | explicit vendor/feature gate (census) |
| **Integrity** | witness | content-addressed chain (`cad` sha256) | `exec_cert` ROOT |
| **Authority** | no ambient power | every privileged touch capability-gated | capability token + hexad-unrepresentable |

### 1.3 Constraints
- **Language/NIH:** III `.iii` only, `iiis-2`, libc + III BOOT headers; hand-rolled; **no third-party** (`feedback_nih_strict`). New primitives built from the **granular uniform `<verb,a,b>` block** — III's most granular uniform expression.
- **No subsphere sprawl:** at most ONE new subsphere (`eidos/`); every new module justified against the leanness contract.
- **Encapsulate, don't reimplement** (`III-INVERSE-LIBRARY.md §2`): wrap real organs; the answer comes from the real faculty, the new tissue only *folds/witnesses/composes*.
- **Keep the network** (directive): no deletion of the federation; capitalize it.
- **Grounding is plan-only** (`III-KATABASIS.md` is ARCHITECTURE-ONLY); EIDOS schedules its proof, never assumes it.

---

## 2. THE PATTERN

**Selected: Event-Sourcing + CQRS + Content-Addressed Transparency-Log, with a cost-directed deterministic planner over a self-describing geometric quantum.** (`III-INVERSE-LIBRARY.md §2` — *"established-sound; the novelty is the inversion, not the cryptography."*)

| Pattern | Role in EIDOS | Fit |
|---------|---------------|-----|
| **Event Sourcing** | the Field is an append-only log of ripple-events; state = fold | ✅ the temporal half of FR-1 |
| **CQRS** | answer-view (the real faculty's result) ∥ audit/plan-view (descriptor + cost + witness) | ✅ FR-2/3 |
| **Content-Addressed (Merkle/transparency)** | identity = `sha256(geometry)`; witness = chain; dedup = merge | ✅ FR-7/8 (`isub`/`assimilate`) |
| **Gradient descent (deterministic)** | the Composer plans by steepest-descent over the ripple field | ✅ FR-3 (`ripple_field`) |
| **Pareto cost selection** | prune the battery-eaters; pick the cheap-sufficient | ✅ FR-4 (`pareto_frontier`/`cost_lattice`) |
| **Reversible search (evade-by-living)** | try a plan, witness, rewind, retain provenance | ✅ FR-5 (`dome`/`reverse_search`) |
| **Capability descent** | latch + melt-in, each rung gated + reversible | ✅ FR-6 (`katabasis`) — OPEN |

### 2.1 The stack
```
            ┌────────────────────── EIDOS ──────────────────────┐
 TASK ─────►│  eidos/compose   the modeless deterministic planner │  reads descriptors,
 (a target  │   (steepest-descent + cost-Pareto + try/rewind)     │  folds a minimal plan
  geometry) │        │                         ▲                  │
            │        ▼                         │ witness/rewind   │
            │  eidos/field     ONE append-only, content-addressed │  state = fold;
            │   ┌──────────────────────────────────────────────┐ │  gradient = spatial read,
            │   │  ripple-events <verb,a,b> + their eidos       │ │  event = temporal read
            │   └──────────────────────────────────────────────┘ │
            │        │  read spatial (gradient)   read temporal   │
            │        ▼                            (fold)          │
            │  eidos/ripple    THE quantum (ripple ≡ inverse-event)│  one block, two views
            │  eidos/descriptor  each quantum's eidos (verb-geometry)│ purpose + capability + cost
            ├────────────────────────────────────────────────────┤
            │  eidos/anchor    grounding: identity (census) +     │  OPEN CORE
            │                  reversible ring descent (katabasis) │  §9
            └────────────────────────────────────────────────────┘
                 ▲                              ▲
        WRAPS existing organs          WRAPS aether federation
   (ripple_field, isub, dome,         (topology_atlas, fed_*, pq_quorum)
    assimilate, master_logic,            = the distributed ripple field
    cost_lattice, pareto, nous, xii,
    exec_cert, cad, reversible,
    snapshot_lattice, observe,
    katabasis/*)
```

---

## 3. COMPONENTS — marked EXISTS / NEW / WRAPS

### 3.1 `eidos/ripple` — the unified quantum **[NEW: a fold over EXISTING atoms]**
```
RESPONSIBILITY: be ONE object that is simultaneously a spatial ripple and a temporal inverse-event.
BUILT FROM (granular, NIH):
  - the isub uniform block  <verb∈{V_BELOW,V_REFLECT}, a, b>       [EXISTS: omnia/isub]
  - logic6 6-valued De Morgan values for verb/symbol nuance       [EXISTS: numera/logic6]  (not numbers)
  - cad sha256 content-address = the block's identity             [EXISTS: numera/cad / exec_cert]
TWO VIEWS OF THE SAME BLOCK:
  - SPATIAL  : ripple_gradient(a,b) = rf_edge_field-style signed magnitude over the dependency edge a→b
               [WRAPS omnia/ripple_field rf_edge_field / rf_node_potential]
  - TEMPORAL : ripple_event(a,b)    = the same block appended to the Field log; state = fold over it
               [WRAPS omnia/event_substrate / omnia/isub emit]
INVARIANT (FR-1 / Slice 0): both views share ONE content-address; the witness chain binds them.
```
*Why it can be one thing:* `ripple_field`'s edge is `sign(rank_to − rank_from) · dK(a,b)` — a **pure function of two sealed addresses**; the isub event is `<verb,a,b>` with `verb` = the order/reflect code and `a,b` = those same addresses. The spatial *sign* is the `verb` (BELOW = climbs, REFLECT = the order-reversing involution); the spatial *magnitude* `dK` is a fold over the temporal events between `a` and `b`. **The gradient is a read of the log.** Slice 0 makes this a gated fact, not prose.

### 3.2 `eidos/descriptor` — the *eidos* (capability-as-geometry) **[NEW: a fold over assimilate/master_logic]**
```
RESPONSIBILITY: give every quantum (and, by extension, every module it taps) a self-description the
  Composer can read WITHOUT executing it — its purpose, granular capability, and cost — as verb-geometry.
SCHEMA (all verb-geometry, no scalar names):
  - PURPOSE   : the transformation it embodies, as a <verb,a,b> shape over the assimilate web
                [WRAPS omnia/assimilate meet/join/complement — the executable web]
  - CAPABILITY: the set of target-geometries it can reach (what it CAN do, granularly)
  - COST      : a Pareto vector (latency, energy/battery, memory, privilege-depth, …)
                [WRAPS numera/cost_lattice + pareto_frontier + microarch_model]
  - PRECONDITION: the input-geometry it requires (content-addressed; dangling-proof)
SELF-INTELLIGENCE (no ML): the descriptor IS the system's knowledge of itself; master_logic proves a
  named primitive is "redundant" (a geometric fold) → the descriptor is the *certified* meaning.
                [WRAPS omnia/master_logic ml_named_is_redundant]
```

### 3.3 `eidos/field` — the unified spatial+temporal field **[WRAPS isub/event_substrate/ripple_field/dome]**
```
RESPONSIBILITY: be the ONE append-only, content-addressed, witnessed log over which quanta live —
  readable as a SPATIAL gradient (where the system wants to grow) AND a TEMPORAL fold (where it has been).
STATE = a fold (never a stored cell); reversibility = a prefix/active-fold; witness = the cad chain.
  - spatial read  : steepest-descent / node-potential   [WRAPS ripple_field rf_steepest]
  - temporal read : finite + infinitary folds, lasso     [WRAPS event_substrate evt_* / dome]
  - rewind        : branch-retaining (abandoned span kept as provenance)  [WRAPS dome dome_rewind]
```

### 3.4 `eidos/compose` — the modeless deterministic planner **[NEW: folds ripple_field+cost+nous+xii]**
```
RESPONSIBILITY: fold the minimal, cost-optimal, task-specific pipeline of quanta — modelessly.
INPUT : a task as a TARGET geometry (a <verb,a,b> shape to reach).
ALGORITHM (deterministic, NO ML):
  1. PROPOSE next quantum: rank by descriptor-fit toward the target  [WRAPS nous — see §3.4.1]
  2. DIRECTION: ripple_field steepest-descent picks the gradient that reduces distance-to-target
                [WRAPS ripple_field]
  3. PRUNE: among quanta that reach the sub-goal, pick the cost-Pareto-minimal (skip battery-eaters)
                [WRAPS pareto_frontier / cost_lattice / microarch_model]
  4. TRY + WITNESS + REWIND: run the candidate on the Field; if a cheaper completion exists, rewind,
     recording the trap as ANTI-GEOMETRY so it is never re-lived  [WRAPS dome / reverse_search Phase 4]
  5. CANONICALISE the chosen plan                                 [WRAPS omnia/xii_canonicalise]
OUTPUT: a witnessed plan; the answer comes from the REAL faculties the quanta tap (encapsulation).
```
**§3.4.1 — the nous composability question, RESOLVED (2026-06-21, by reading nous's source).** nous has **two faces**, and the Slice-0 deferral conflated them:
- **nous-the-proposer** (`nous_value`/`nous_policy`): a *deterministic, integer-only, content-addressed* ranker (no online ML — fixed sealed weights), but it ranks **XII rewrite rules/terms** by *rewrite-specific* features (trit/fusion bonuses, `nous_value`'s "linear block-reorder over the live **rule set**") toward a **normal form**. Its features and objective are the rewriting domain's. Forcing it to rank cost-graph quanta — by encoding quanta as XII terms — would make it rank things it was not built for: a **wrong-faculty island** (failure mode #4). So nous-the-proposer is **not** the cost-graph Composer's proposer; the deterministic cost-argmin (Bellman-Ford) is, and that is correct. nous-the-proposer is the right proposer only for a *rewrite-domain* Composer (composing a rewrite/normalization strategy), which arrives at integration — **not deferred for lack of an encoding, but correctly scoped to a different domain.**
- **`nous_costlin`** (the faithful integration point): it linearizes the **same** `numera/cost_lattice` 6-dim partial order the Composer uses into a canonical, **versioned**, content-address-tiebroken **total order** (`nous_cost_compare`), built precisely because *"a certified search cannot claim optimality without a total order."* This is the genuine nous⇄Composer composition — it grounds the Composer's "optimal" in a *total* order (resolving `cl_dot_slot` dot-ties canonically + reproducibly across registration orders). **Identified, not yet wired:** deferred to integration (when the cost structure is real, not fixture-shaped) per the review — wiring it now would polish a disconnected mechanism. *(`ripple_field`∘`cost_lattice` composability is moot: the planner uses a quantum graph + `cl_dot_slot`, not `ripple_field`'s gradient — also an integration-phase concern.)*

### 3.5 `eidos/anchor` — grounding **[OPEN CORE — §9]** **[WRAPS katabasis census + NPT-CoW]**
See §9. Identity is PROVEN (the census crystal); placement is the hard, plan-only descent, designed against KATABASIS §0.6.

### 3.6 The distributed field **[WRAPS aether — no new module]**
The federation already linked (`topology_atlas`, `fed_tier/sybil/eclipse/admit/genesis/seal`, `pq_quorum`) carries quanta between nodes. Content-address means a quantum minted on node X is **recognized and merged** on node Y (`assimilate` cross-domain), witnessed trustlessly by `pq_quorum`. **This is how the "TON of work" on the network gets cashed in** — it becomes EIDOS's distribution substrate with zero new federation code.

---

## 4. DATA ARCHITECTURE — one datum

| Entity | The single datum | Storage | Identity |
|--------|------------------|---------|----------|
| **quantum (ripple-event)** | `<verb, a, b>` + its eidos | the append-only Field log (BSS array, `ISUB_CAP`-style) | `sha256(footprint)` (content-address) |
| **the Field** | the chain of quanta | append-only, witnessed (`ROOT = sha256(ROOT_prev‖CAV)`) | the witness ROOT |
| **a plan** | a fold over a prefix (the chosen quanta) | derived, never stored | the plan's own content-address |

**Consistency:** within a node — the fold is the single source of truth (deterministic). Across nodes — eventual, content-addressed dedup/merge (federation). No mutable shared state cell anywhere (the inverse-form invariant, `III-LEGACY-VS-INVERSE-STRUCTURE.md`).

---

## 5. CROSS-CUTTING

- **Integrity:** every quantum's identity *is* its content-address; the Field witness *is* the chain. `cad` sha256 for resistance, not FNV (the `III-TRAJECTORY-AUDIT.md §3` detection-vs-resistance discipline).
- **Authority (no ambient power):** every privileged touch (anything below R3) is **capability-gated** (`aether/capability`) AND **type-shaped so a bricking write is unrepresentable** (the hexad / `numera/reversible` H9 trichotomy: REVERSIBLE / TYPED-IRREVERSIBLE / UNREPRESENTABLE). KATABASIS's thesis: bricking is *unrepresentable*, not merely guarded.
- **Reversibility:** the inverse Field (branch-retaining) + `numera/reversible` (undo for legacy effects) + `aether/snapshot_lattice` + (at the metal) NPT-CoW (`III-KATABASIS.md §0.3`). Every touch carries its own undo.
- **Observability:** `sanctus/observe` (witnessed sense) + `aether/witness_hook`; the Composer's every plan is a witnessed trajectory (a Divergence Signature, `III-TRAJECTORY-AUDIT.md §2`).
- **No-ML guarantee (Mandate 7):** the Composer's "intelligence" is **deterministic geometry + cost folds** — descriptor-fit, gradient descent, Pareto argmin. Zero counting-to-adapt, zero thresholds, zero weights. Re-choices change only because a recorded anti-geometry is replayed (`reverse_search`).

### 5.4 The Composer's termination + cost bound (NFR — answers the planner-as-battery-eater risk)
- **Termination:** the planner is steepest-descent over a **finite** set of content-addressed quanta with a **visited-set** (content-address dedup) and **anti-geometry** (a trap is never re-lived, `reverse_search` Phase 4). No quantum is expanded twice ⇒ ≤ |quanta| expansions ⇒ **terminates**.
- **Cost:** each expansion is a Pareto argmin over available quanta's descriptors: O(|available| × cost-dims). Worst case **O(|quanta|² × dims)**, polynomial and bounded. *(Contrast: `III-TRAJECTORY-AUDIT.md §0` retracted an unproven O(active) bound — EIDOS states and gates its bound, learning that lesson.)*

---

## 6. THE INTERFACE (how a quantum links systemwide — FR-7)

Linkage is **not** a registry or a call graph; it is **content-address coincidence**. Two quanta whose geometries share a sub-shape share a content-address for that sub-shape (`assimilate` recognize-and-merge), so they are **already linked** — the Composer discovers complementary modules by walking shared addresses, not by a lookup table. *"Systemwide functionality to link to complementary modules dynamically"* is therefore an **emergent property of content-addressing**, authored once in `eidos/descriptor`, not wired per pair.

---

## 7. KEEP & CAPITALIZE THE NETWORK (directive)

The ripple network and federation are **not** replaced. `eidos/field` *is* the ripple network elevated to carry eidos; `aether` federation *is* the distribution layer. The payoff the directive demands: a quantum minted anywhere is content-addressed, so the network's existing trust machinery (`pq_quorum`, `fed_seal`) now secures a **useful, self-describing** payload instead of opaque blobs — the work compounds instead of sitting idle.

---

## 8. DECISION LOG (ADRs)

- **ADR-1 — Encapsulate, never reimplement.** The new tissue folds/wraps real organs; the answer comes from the real faculty. *Rationale:* `III-INVERSE-LIBRARY.md §1` retracted every grand reimplementation; encapsulation is the only form that held all three of breadth/inverse/realness. *Consequence:* `eidos/*` adds folds, deletes duplicates.
- **ADR-2 — Eidos is verb-geometry, not numbers.** Purpose/capability are `<verb,a,b>` shapes over the `logic6`/`assimilate` web; numbers appear **only** as Pareto cost tie-breakers. *Rationale:* the directive (*"numbers are too stupid for real nuance"*) + `master_logic`'s proof that named primitives reduce to geometry. *Consequence:* the planner reasons over shape first, cost second.
- **ADR-3 — Modeless planner with a proven bound.** No modes/profiles; one descriptor-driven planner, terminating + cost-bounded (§5.4). *Rationale:* the user's "reshuffle, don't invoke battery-eaters" + the retracted-bound lesson. *Alternative rejected:* task-type modes (a switch) — that is the rigidity being removed.
- **ADR-4 — Grounding is a discovered, reversible descent, not a fixed ring.** Identity (census) is fixed; placement is per-host, staged, reversible, observe-first. *Rationale:* KATABASIS §0.6 BSODs from fixed wrong constants; agnosticism demands discovery. *Consequence:* §9 is the open core, scheduled not assumed.
- **ADR-5 — Retire by attrition, proven first.** The split legacy ripple machinery is deprecated only after `ml_named_is_redundant`-style proof it is a geometric fold of `eidos/ripple`. *Rationale:* `feedback_no_compromise` + the leanness contract; never delete working code on faith.
- **ADR-6 — The Composer's proposer is domain-specific; nous is split into two faces (2026-06-21).** The cost-graph Composer's proposer is the deterministic cost-argmin (Bellman-Ford), not nous. *Rationale (from nous's source, §3.4.1):* `nous_value`/`nous_policy` rank **rewrite rules/terms** by rewrite-domain features toward a normal form — faithful only to a *rewrite-domain* Composer, not a cost-graph one; forcing them onto quanta is a wrong-faculty island. The faithful nous⇄Composer link is **`nous_costlin`** (the canonical, versioned total order over the shared `cost_lattice`), which grounds optimality in a total order — **identified as the integration-phase wiring, not done now** (deferred per review: wiring it onto today's fixture would polish a disconnected mechanism and be re-designed when the cost model is real). *Consequence:* the "nous deferred" note is corrected to "nous-proposer correctly scoped to the rewrite domain; `nous_costlin` is the total-order integration point." *Alternative rejected:* encode quanta as XII terms so nous-the-proposer ranks them (the wrong-faculty island).

---

## 9. THE GROUNDING — the OPEN CORE (designed against KATABASIS §0.6)

> The directive's hardest clause: *"grounded in the best place on the computer … agnostic to hardware/firmware … latch onto a reliable point and melt into any given system to its maximal potential … least disruptively (or even improving performance) … I didn't implement it in either and there were consequences."*

**The consequences, named (so we design against them, not in a vacuum):** `III-KATABASIS.md §0.6` — a write to the AMD **Host Save Area** (SVM `0x1000`) → `BugCheck 0x1 APC_INDEX_MISMATCH`, reboot; `IMAGE_BASE=0x10000` (user-mode VA) → idle `0x50 PAGE_FAULT_IN_NONPAGED_AREA`. **A wrong constant at the metal reboots the machine.** Separately, even at R3, residence in a OneDrive-synced / Defender-watched folder causes transient locks, exec-scan stalls, ENOEXEC (`III-DISPOSITION-EXECUTION.md`, cited in the build scripts). *Placement has consequences at every scale.*

### 9.1 Two questions the directive fuses — split them
- **IDENTITY — "what machine am I on?"** → **SOLVED / PROVEN.** The silicon/behavioral census (`katabasis/cpu_census`, `behavioral_seed`, `behavioral_fp`; KATABASIS §0.5 *"silicon census, PROVEN methodology"*) mints a content-addressed identity crystal from **unprivileged, vendor-explicit** CPUID/MSR/self-test probes. *Agnosticism mechanism:* "AMD-only MSRs are NEVER loaded on Intel and vice versa; the vendor check is explicit so the driver cannot #GP into a BSOD on mistaken vendor." This is the **reliable point to latch onto** — present on every x86-64 machine, needs no privilege.
- **PLACEMENT — "where do I stand to reap the benefit?"** → **OPEN.** This is the plan-only descent, and the hard part.

### 9.2 The answer: there is no single best place — placement is *discovered, per-host, and reversible*
"The best place" is **relative to what THIS host verifies**, so EIDOS applies its own no-modes/dynamic principle to grounding itself:
```
LATCH  (R3, universal)  : mint the identity crystal (census). Needs nothing. Always succeeds.
DESCEND (opportunistic) : attempt each deeper rung ONLY if it VERIFIES against the crystal:
   R0  kernel presence  — if a driver loads (KATABASIS §0.4 surface)
   R-1 hypervisor       — if SVM/VMX present + free; else NESTED-L1 under an existing hypervisor
   R-2/R-4              — OBSERVE-ONLY by principle ("witness Ring-4, never write it")
EACH RUNG, BEFORE ANY WRITE:
   (a) bricking-write UNREPRESENTABLE   — hexad/H9 type forbids constructing the dangerous touch
   (b) NPT-CoW snapshot                 — the pre-image is a witnessed shadow; rollback = swap-back
   (c) capability-gated                 — a 32-byte token, never ambient authority
   (d) safe-write-in-guest             — WRMSR/mem-write run in a throwaway guest so a #GP is a VMEXIT,
                                          the host never faults (KATABASIS §0.4 HV_MSR_WRITE_PROBE, PROVEN)
   (e) self-attest                      — HV_LIVE_VERIFY hashes own .text (PatchGuard/HVCI/tamper detect)
```
**Agnostic** because the *descent procedure* is identical everywhere; only *how deep it reaches* varies, decided by verification. **Least-disruptive** because every touch is observe-first + reversible + capability-gated + type-safe — the KATABASIS thesis: *"CHARIOT could take the machine. III can take it and always give it back, with a proof."* The depth reached is the "maximal potential on this system" — maximal *and safe*.

### 9.3 The "improve performance after" clause — demoted to north-star, honestly
Optimizing the *host's* hot-paths from a melted-in layer (via `xii_canonicalise`/`weave`/`jit_fuse`/`hw_offload`/the `cg_r3` sov-calc optimizer) is **binary-optimizer-grade** and is **NOT** claimed as a near-term feature. The **defensible near-term claim is: non-disruptive** (observe-first, reversible, reboot-survivable). Performance-improvement is a flagged **north-star with burden-of-proof** — to be earned by a gated benchmark, never asserted. *(This is the `crosswall_prose_runs_hot` / no-toy discipline applied to the single most over-reachy clause in the directive.)*

### 9.4 Why not implementing this made III "dumb"
Without an anchor, III has **no self-location** — it cannot know which capabilities are reachable here, so it cannot reshuffle around them; and without descriptors it has **no self-description** — so it cannot know what to invoke for what. **Grounding (anchor) + self-description (eidos) = the self-awareness that makes dynamic composition possible.** That is why the two halves of this design are one design.

---

## 10. RISKS

| Risk | Impact | Likelihood | Mitigation |
|------|--------|-----------|------------|
| **Unification stays prose** (FR-1 a conjecture) | the whole thesis is vapor | HIGH if skipped | **Slice 0** gates morph=ripple+event on a real case before anything generalizes (§11) |
| **New surface instead of leverage** | violates leanness; another retracted synthesis | MED | the leanness contract (capability↑, modules flat-or-down) as a hard gate; ADR-1/5 |
| **Composer is an undecidable/expensive planner** | the new battery-eater | MED | proven termination + O(\|quanta\|²×dims) bound (§5.4), gated |
| **nous/ripple_field/cost composability assumed** | Composer is a toy at scale | MED | §3.4.1 — named as assumptions; Slice 0 tests the actual composition |
| **Grounding bricks a host** | reboot / persistent damage | HIGH if rushed | §9: unrepresentable bricking + NPT-CoW + observe-first + safe-write-in-guest; staged, never assumed |
| **Over-claim "makes host faster"** | the hot-prose trap | MED | §9.3 demotes it to a burden-of-proof north-star |
| **Descriptor-authoring burden** (every module needs an eidos) | adoption stalls | MED | bootstrap via `assimilate`/`unravel` auto-deriving eidos from real traces; descriptors are folds, not hand-tags |

---

## 11. ROADMAP — front-loaded on the ONE proving slice

**Slice 0 — THE PROOF (do this first; everything else waits on it).** Two gated KATs, exit-99 + teeth:
1. **Unification (FR-1) — ✅ DONE (2026-06-21).** Organ `eidos/ripple.iii` (a pure fold driving the REAL `ripple_field` + REAL `isub`); KAT `1931_eidos_ripple_unify` proves a live-scanned ripple edge's `direction`+`gradient` (spatial) and its emitted `<verb,a,b>` event (temporal) share ONE `sha256(geometry)` content-address, with the witness ROOT = the independent hash-chain of those addresses — across direction-binding, one-identity, spatial==temporal, witness-binding, co-movement, dedup, the order-reversing involution, determinism, and the **lossless flat boundary** — a flat/equal-rank edge is the *absence* of a ripple (`V_NONE`: no quantum, no address), so `isub`'s two verbs cover the two real ripple directions exactly with **no 3→2 loss** and no flat edge ever aliased onto a climb block (code 19) (**EXIT 99**). Teeth `1932_eidos_ripple_teeth` constructs the decoupled (constant-verb) binding and proves it diverges — wrong direction ⇒ wrong content-address (**EXIT 99**). Sealed into `libiii_native.a`; wired into `MODULES` + `EXPECTED`; `isub`/`xii_isub` consumers regression-clean. *(Caveat: surgically `ar`-sealed; the canonical full-build mhash re-aggregates on the next clean build — the env's `forge_check` hang precludes it now. No green-washing.)*
2. **Modeless composition (FR-3/4) — ✅ DONE (2026-06-21).** Organ `eidos/compose.iii` — a bounded **Bellman-Ford** planner (strict-`<` relaxation in registration order ⇒ deterministic predecessor; overflow-guarded) whose edge weight is the REAL `cl_dot_slot(order, cost)` and whose plan executes as witnessed `isub` blocks. KAT `1933_eidos_compose_modeless`: one planner, two cost orders over one quantum graph → two **different** optimal plans; the **lowpower** plan provably consumes strictly less energy (the measured battery-skip) than the **realtime** plan; **each plan's achieved cost == an independently-computed `cl_dot_slot` argmin over the candidate routes** (the non-toy optimality cross-check, not a typed answer); terminates below the round bound; reproducible + task-distinct witness (**EXIT 99**). Teeth `1934_eidos_compose_teeth`: the planner prefers a cheaper **2-hop indirect** route over a costlier **1-hop direct** edge under lowpower and flips to the direct edge under realtime — a genuine cost optimiser, **not** a hop counter (**EXIT 99**). Optimality `1935_eidos_compose_optimal`: a greedy *cheapest-first-edge* **trap** (q0 cheap → a 100-weight wall, vs a 2+1 detour) — the planner returns the **global** optimum (cost 3, not greedy's 101), proving **Bellman-Ford relaxation is load-bearing**, not greedy; an unreachable target yields the empty plan (**EXIT 99**). Sealed + wired (`MODULES` + `EXPECTED`); `isub`/`xii_isub`/`cost_lattice` consumers regression-clean. **Composability resolved (§3.4.1 / ADR-6):** `cost_lattice` composes natively; the proposer is the sanctioned deterministic cost-argmin (no ML). **nous split into two faces:** nous-the-proposer ranks XII rewrite *rules* (a wrong-faculty island here — correctly scoped to the rewrite domain, not "deferred for lack of an encoding"); **`nous_costlin`** (the canonical total order over the shared `cost_lattice`) is the *faithful* nous link, identified for the integration phase (not yet wired). **Scope (honest):** this proves the planner *mechanism* on a cost **fixture**, NOT "III reshuffles its real pipelines" — that is **Phase 3**, whose first real instance is **routing binary production** (`tp_iii_to_asm → tp_x86_assemble → tp_asm_to_pe` vs the C path) under a *trust-root-vs-speed* order. **Integration — ✅ DONE (2026-06-21): the two halves are now connected** by `eidos/weave.iii` — the planner plans **and executes over real `eidos/ripple` quanta** whose costs are **derived from real geometry** (`|rf_edge_field|` magnitude + `rf_rank`-derived verb, *not* hand-assigned) and whose plans **execute as real witnessed ripples**. KAT `1936_eidos_weave_real`: a real 2-ripple composition (`S→M→T`), each quantum's cost proven **== the `rf_edge_field` geometry recomputed in-KAT** (the *faithful-copy* gate — weave carries the real sealed geometry, not a hand-assigned fixture; both call `rf_edge_field`, so weaker than 1931's *independent* `cad`), executed + witnessed, cost-faithful on the route (**EXIT 99**). **What 1936 does NOT exercise — stated plainly:** optimization-*among-alternatives*. Phase 1 has a single route, and Phase 2's direct edge dominates under both orders, so the optimizer (proven load-bearing on *fixtures* in 1933/1935) is never decisive here — not a gap in the test but a **property of the real geometry**. **Honest finding, now durably gated by `1937_eidos_weave_subadditive` (probed first, then retained):** the real `xii_savings` table is **sub-additive** (no anti-triangle triple exists), so over real geometry the shortest/direct plan is optimal under **every** monotone order ⇒ the optimal plan is **order-invariant** — the modeless reshuffle *capability* is proven abstractly (1933) but is **degenerate on the savings geometry alone**, needing trade-off cost dimensions the savings table doesn't carry (a richer per-ripple cost model is future). **Scope:** a planner over a ripple **fixture** (node=prim with per-edge hexads; the general object is node=`(prim,hexad)`); not yet `eidos/compose` over III's *real module graph* or the `tp_*` routing (Phase 3); `eidos/descriptor` remains unbuilt. The remaining gaps are now *the real graph and the real task*, not the connection itself.

> If Slice 0 fails, the architecture is refuted here — at one KAT's cost — not after building `eidos/`.

**Phase 1 — `eidos/ripple` + `eidos/descriptor` (NEW folds).** Build the quantum and the eidos schema as folds over isub/assimilate/logic6/cost_lattice. Auto-derive descriptors from real `unravel` traces (no hand-tagging). Gate; seal; corpus-green.

**Phase 2 — `eidos/field` (WRAP).** Unify the spatial (`ripple_field`) and temporal (`event_substrate`/`dome`) reads behind one log. **Retire-by-attrition begins:** prove (via `ml_named_is_redundant`) that `omnia/ripple` ∥ `ripple_field` ∥ `forcefield/ripple` are geometric folds of `eidos/ripple`; deprecate the redundant ones. *Leanness gate: module count must not rise.*

**Phase 3 — wire the planner to real III work (the no-island endpoint).** Two desiderata, two targets: **Task A — battery-skip** (✅ DONE, `eidos/optgate` + corpus `1938`): the *cost-selection half* (`cl_dot_slot` + named orders) wakes the **dormant** SAT reducer `invent/gil_forge` only when an order's cost favors it — skip measured, correctness `bb_equal`-proven, golden-safe (faculties absent from `COMPILER/`); honestly one-bit (`is_pow2`) discernment that over-invokes on irreducible `k` (gated). **Task B — topology routing** (✅ DONE as a *capability*, `eidos/route` + corpus `1939`): the *shortest-path half* (Bellman-Ford) routes `topology_atlas`'s REAL typed-edge graph — returns the **path** (not just distance), subsumes BFS, weighted cheaper-indirect, per-edge-kind, ≤64 nodes. **But the probe falsified B's original premise:** III has **no live multi-dim-cost routing substrate** (topology stores typed edges + hop-count + a single hardcoded `u32` weight). So B is **single-weight plan-output routing**, an **output-island** (nothing live calls it), and the "modeless reshuffle by cost order on real data" was **not** achieved — it doesn't exist to achieve yet. **Honest Phase-3 status:** both Composer halves are proven as **capabilities reading real III structure** (A = the dormant optimizer's real microarch costs; B = topology's real adjacency), with honest gates — but **neither is consumed by a live III path, and modeless-on-real-data is unexercised** because no multi-dim-cost substrate exists in III. Real, non-inflated progress; "EIDOS reshuffles III" is *not* yet true. The one remaining real-consumer candidate is the `tp_*` binary-production routing decision — itself a probe (does it carry real multi-dim costs?), not an assumption.

**Phase 4 — `eidos/anchor` (OPEN CORE, staged).** Identity crystal first (PROVEN census, immediately). Then the reversible descent, **R0 → R-1 → observe-only below**, each rung its own gated proof, NPT-CoW reversible, against KATABASIS §0.6. *Never assume a rung; schedule its proof.* Performance-improvement (§9.3) only if a gated benchmark earns it.

**Phase 5 — Distribute (WRAP).** Quanta over the federation; content-addressed dedup/merge across nodes; `pq_quorum`-witnessed. Capitalize the network.

---

## 12. EXISTS / NEW / SPECULATIVE LEDGER (the honest map)

| Element | Status |
|---------|--------|
| isub `<verb,a,b>` content-addressed bus, exec_cert witness, cad sha256 | **EXISTS** (sealed, KAT-green) |
| event_substrate folds + lasso, dome rewind/provenance, reverse_search anti-geometry | **EXISTS** |
| assimilate executable web, master_logic `ml_named_is_redundant`, unravel geometry, logic6 | **EXISTS** |
| ripple_field gradient, cost_lattice/pareto_frontier/microarch_model, nous, xii_canonicalise | **EXISTS** (composability **ASSUMED — Slice 0 verifies**) |
| aether federation (topology_atlas, fed_*, pq_quorum), reversible, snapshot_lattice, observe | **EXISTS** |
| katabasis identity census (cpu/behavioral) | **EXISTS / PROVEN** (KATABASIS §0.5) |
| katabasis ring descent (R0 driver, R-1 HV, NPT-CoW, safe-write-in-guest) | **DESIGNED / PLAN-ONLY** (KATABASIS) |
| `eidos/ripple` (ripple ≡ inverse-event, one block) | **NEW — PROVEN** (corpus `1931` unify + `1932` teeth = EXIT 99; sealed + wired) |
| `eidos/descriptor` (eidos = capability-geometry; the JOIN) | **NEW — PROVEN** (corpus `1940` EXIT 99: a THIN FOLD over `assimilate`'s real web — each block self-describing (content-address + verb + 1-bit capability ORDER/COMPLEMENT), the BELOW order bridged into `compose` for goal-directed routing; descriptors DERIVED not hand-tagged. `1941` EXIT 99: **trace-derived PROVEN end-to-end** — a real `xii_rewrite` execution shattered via `unravel`/`ingest` into the web, descriptor folds the real trace blocks. ENCAPSULATES assimilate (no rebuild) — the reconciliation of the two tracks; gives EIDOS a real trace-fed INPUT. **Honest:** still no live CONSUMER (that's tp_*); `desc_count` == current bus contents. Sealed + wired) |
| `eidos/field` (unified spatial+temporal log) | **NEW** (wrap; enables retire-by-attrition) |
| `eidos/compose` (modeless terminating planner) | **NEW — PROVEN** (corpus `1933` modeless + `1934` teeth = EXIT 99; sealed + wired; bound proven §5.4) |
| `eidos/weave` (the integration: compose over real ripple quanta) | **NEW — PROVEN** (corpus `1936` real costs + composition + witnessed execution, EXIT 99 — optimization-among-routes NOT exercised, degenerate by sub-additivity; `1937` sub-additivity gated, EXIT 99; sealed + wired) |
| `eidos/optgate` (Phase 3 Task A: cost-ordered battery-skip) | **NEW — PROVEN** (corpus `1938` EXIT 99: wakes the DORMANT SAT reducer `invent/gil_forge` cost-optimally; skip MEASURED on the power-of-two simple case, correctness `bb_equal`-proven; **gated limitation** — one-bit `is_pow2` discernment under an optimistic G-bound over-invokes on irreducible `k`; validates the **cost-selection half**, not Bellman-Ford; sealed + wired) |
| `eidos/route` (Phase 3 Task B: the Composer as topology router) | **NEW — PROVEN as a CAPABILITY** (corpus `1939` EXIT 99: the Bellman-Ford half routes `topology_atlas`'s REAL typed-edge graph — returns the **PATH** (not just distance), subsumes BFS hop-count, takes the weighted cheaper-indirect with the route, per-edge-kind, ≤64 nodes (loud-capped, 12× dijkstra's 5); reads real adjacency (input-consumer). **Honest:** single-weight, **output-island** (nothing live calls it), and **NOT** the modeless capstone — III has **no live multi-dim-cost routing substrate** (the probe), so "reshuffle by cost order on real data" remains unexercised; per-edge-kind is *generality*, not modeless. Sealed + wired) |
| `eidos/anchor` placement descent | **OPEN CORE** (§9; staged, reversible, never assumed) |
| "melt in → host runs faster" | **SPECULATIVE / NORTH-STAR** (§9.3, burden-of-proof) |

---

## 13. ONE-PARAGRAPH SUMMARY

III is dumb because it has no self-knowledge: no module knows what another is, what it costs, or where the whole stands on the machine, so a pipeline can only do its one hardwired thing. **EIDOS** fixes this by **leverage, not mass** — it makes computation a single self-describing geometric quantum (the **ripple**, now identical to its inverse-form event), tags every quantum with its **eidos** (purpose + capability + cost as verb-geometry, *not numbers*), and lets one **terminating, cost-bounded, ML-free planner** fold a minimal task-specific pipeline that *reshuffles per task and skips the battery-eaters* — trying, witnessing, and rewinding on one append-only content-addressed field that **unifies the spatial ripple gradient with the temporal inverse-event fold**. It **grounds** at the one hardware-agnostic invariant (the machine's own deterministic fingerprint) and **descends the rings only as far as each host reversibly verifies** — bricking-writes type-unrepresentable, every touch NPT-CoW-reversible, deeper rings observe-only — designed against the real BSOD scar tissue, claiming *non-disruptive* now and *host-faster* only when a benchmark earns it. It keeps and **capitalizes the federation** as its distribution layer. And it is *lean made falsifiable*: **capability up, module count flat-or-down**, the split legacy ripple machinery retired by attrition only after it is *proven* a geometric fold of the one new quantum — every bit of III finally cashed in, because for the first time III knows what every bit is.
