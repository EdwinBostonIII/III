# III — Universal Architecture Audit

**What this is.** A ground-truth, file-grounded audit of every structural variety in the III
system, and an adjudication of its *universal architecture*: should III converge on one
fully-dynamic event-based substrate (EIDOS), or is there a right structure per kind of thing?
Written solo (no agents — hard lock), read-first, adversarially verified, and checked against
the live tree with `iii_check_discharge`. Reconciles against `III-INTERIOR-LOGIC-ATLAS.md`
(the formal spine), `III-STRUCTURAL-AUDIT.md`, `III-RIPPLE-OPTIMIZER-ARCHITECTURE.md`,
`III-NOUS-ARCHITECTURE.md`.

**Claim tags.** `[gated]` = backed by a passing corpus/KAT witness; `[cited]` = read in source
at the named `file:line` (documented, not necessarily runtime-re-verified this pass); `[judgt]`
= architectural judgment / analogy. DOCUMENTED ≠ VERIFIED.

---

## 0. The verdict in one paragraph

III **already has** a universal architecture — it is written formally in
`III-INTERIOR-LOGIC-ATLAS.md` as a single theory where every faculty is a pair *(generator P,
disposer D)*, modules relate **only by shared symbols**, the disposer is total/decidable and
**never reads a statistic** (`D ⊥ freq/sample/param`), and the signature Σ **self-mutates under
the same D** `[cited: interior-logic-atlas.md:42-48]`. The "disjointedness" you feel is **not the
absence of an architecture — it is the realization gap** between that clean spine and a 3,200-module
body that grew in waves. The right end-state is **not "everything becomes event-based."** It is
**one law, many kinds, layered substrates**: event-fold for the *witnessed/reversible/audited*
layer, plain values/arenas for *hot transient compute*, the e-graph/XII for *equivalence*, SVIR
for *execution*, the crystal for *provenance* — all of them sealed `(P,D)` faculties carrying a
Hexad **kind** and a K-value. Event-based is genuinely superior **where state must be witnessed,
reversed, or audited**, and genuinely *wrong* on a hot inner loop. The single deepest unification
opportunity is real but **not yet built**: order+involution (`{BELOW, REFLECT}`) over
content-addressed nodes recurs in at least three engines and should become one.

**Capability corroboration (integration of the genuine-output systems map, `III-SYSTEMS-MAP.md`).**
A parallel audit measured what the system *does* unassisted. Its central finding — *only `aether`
has a standalone `main`; every other domain is pure library, called not run* — is the **empirical
confirmation of this structure**: "one law, many kinds, faculties coupled by shared symbols"
*predicts* a library-heavy body with few standalone mains. What genuinely WORKS with real output:
the self-hosting compiler, the stdlib build (735 modules → `libiii_native.a`), the XII crypto
toolchain (real ed25519 keys / manifest / MPHF / lattice), the **sovereign C→native toolchain**
(3,584-byte, 1-DLL, exit-99 binary, no gcc/ld in the trusted path — the standout), and the exact
arith/geometry math. The realization gap is now **quantified**: 119 dark exports / 56 uncovered
(build coverage ratchet RED), sovereign cross-language independence `crosslang=NO` (ccsv≠iiisv), and
the e-graph load-bearing only narrowly in `cg_r3`. The capability×structure map and the
fix/throw/refactor **disposition ledger** are §14–§16.

---

## 1. Evidence base (this pass)

Subsystem map (module counts): `numera 314` · `omnia 159` · `aether 103` · `verba 46` ·
`sanctus 31` · `nous 28` · `forcefield 27` · `katabasis 22` · `eidos 18` · `tempora 6` ·
`memoria 5` · `intent 5`; plus `sovir`+`sovtc` (131) and `COMPILER/BOOT`. **3,200 `.iii`
total.** `[cited]`

Deep-read this pass: `eidos/ripple`, `eidos/weave`, `omnia/event_substrate`, `omnia/fold`,
`omnia/crystal`, `omnia/xii_canonicalise`, `omnia/dome`, `omnia/master_logic`, `omnia/hexad`,
`numera/weave`, `numera/ser_pipeline`, `numera/ser_eidos`, `memoria/seal_organ`,
`nous/nous_charter`, `nous/nous_value`, `sanctus/self_model`, `sovir/svir_prog`, and
`III-INTERIOR-LOGIC-ATLAS.md` (§Σ, §G). Greps: ripple/weave/organ locators, no-ML scan over
`nous`, float footprint, handle-table prevalence. Checked: `evt_perceive`,
`ml_named_is_redundant`, `sm_next_gap` all DISCHARGED against the live tree. `[gated]`

---

## 2. Event-based vs object-based — what's awesome, what's trash, and WHY

### 2.1 The two storage philosophies, concretely

- **Object-based** = stored mutable cells indexed by a *handle*, in a fixed-size slot pool.
  Example: `memoria/seal_organ` (64-slot arrays + `tempaloc` handles); `numera/bigint`
  (64-slot id pool); `omnia/crystal` (256-slot table, `CRYSTAL_LIVE[]`). **466 handle-table
  sites across 30 modules** `[cited: grep _LIVE/alloc_slot/MAX_INSTANCES]`.
- **Event-based** = no stored cell; an append-only, immutable, monotonic **log**, and **state
  is a deterministic fold over a prefix** of it. Canonical: `omnia/event_substrate`
  (`evt_perceive` is the *only* mutator; `evt_winner`/`evt_witness` are folds)
  `[cited: event_substrate.iii:49-147]`; matured in `eidos/field`.

### 2.2 Why object-based is "trash" — and it's not aesthetic, these are real III bugs

1. **Exhaustion → silent corruption.** A fixed pool runs out → degenerate/zero handles →
   wrong answers with no error. This is the **64-slot `bigint` handle-table** that corrupted
   last session's `isqrt` (small k passed, k=1000 exhausted mid-second-isqrt). `[cited]`
2. **Aliasing.** Two pools numbered from 1 collide — the documented `FC-COLLIDE-1`: a success
   `bigint_id i` aliased live crystal slot `i-1`, fixed only by an ad-hoc high-band offset
   `CRYSTAL_ID_BASE = 0x10000` `[cited: crystal.iii:42-47]`.
3. **Manual lifecycle.** alloc/free/drop by hand → leak or use-after-free if forgotten.
4. **No inherent witness/replay/reverse.** A stored cell has no history; provenance must be
   *bolted on* (the crystal carries a MAC + `cause` pointer precisely to compensate
   `[cited: crystal.iii:14-22]`).

### 2.3 Why event-based is "awesome" — it structurally avoids all four

`event_substrate` is append-only (no exhaustion-*corruption*, only a growable bound),
content-addressed (no aliasing), immutable (no free), **witnessed** by a replayable rolling
hash, **reversible** (fold a shorter prefix), and **deterministic** (a *logical* tick; "a wall
clock would break determinism") `[cited: event_substrate.iii:24-27]`. It even encodes the
no-ML law inline: "every fold is a FIXED pure function of the log; no counting-to-adapt, no
threshold, no policy" `[cited: event_substrate.iii:24]`. The `dome` adds the **society** —
many event-primary twins on one shared reversible log, with *provenance-carrying deliberation*:
"choose, live the butterfly-effect, observe the recurrent outcome, and if it is bad, REWIND and
re-choose — abandoned branch retained as provenance" `[cited: dome.iii:8-16]`.

### 2.4 The honest counter — event-based is NOT universally superior `[judgt]`

A fold is **O(prefix length) per read**. On a hot inner loop (bigint multiply, the Tier-1
interval sign) recomputing state by folding a log every access is catastrophic. Event-fold is
right for the *witnessed/audited/reversible* layer (commits, proofs, self-edits, provenance) —
where reads are infrequent and the log is bounded by *decisions*, not by inner-loop iterations.
For hot transient compute, plain values / arenas win. **Adversarial refinement (survived):** at
gospel scale even the witnessed layer must use **incremental / Merkle folds** (re-address only
changed nodes, as `self_model` does `[cited: self_model.iii:5-10]`) — `event_substrate`'s
`evt_witness` re-folds the whole prefix O(n)/call, a POC pattern that will not scale.

---

## 3. Seraphytes vs organs

- **Organ** = a sealed, deterministic, single-capability module: one Hexad kind, a Ring, K≈1.00,
  one exported faculty. A **noun** — a capability the system *has*. `memoria/seal_organ` is the
  archetype (sealed-time witness; kind_essence, R0, K 1.00) `[cited: seal_organ.iii:23]`. Organs
  may legitimately use object storage internally.
- **Seraphyte** (`ser_*`, 30 modules in `numera`) = a *species* of organ: "the Seraphyte as a
  **witnessed, foldable process**" `[cited: ser_pipeline.iii:320]` — a *living* organ in the
  autopoietic **discover → prove → apply → gate → accept/rollback** loop
  `[cited: ser_pipeline.iii:1-21]`. A **verb** — it acts over the event log and *changes the
  system*, but only behind a kernel-first proof gate. **Every Seraphyte is an organ; not every
  organ is a Seraphyte.**

**What was awesome about Seraphytes.** The loop is genuinely rare: the compiler *synthesizes
what to optimize* (CEGIS, no human), a *real CIC kernel* proves it, the change is applied
non-locally, temporal safety+liveness is k-induction-proven, and the accept/rollback is
**witnessed byte-exact on the real `eidos/field` with provenance retained** — unattended, integer-
deterministic, no learning `[cited: ser_pipeline.iii:1-21; ser_eidos.iii:1-21]`. Kernel-first: a
blind prover blocks *every* self-edit `[cited: proof_ripple_unified.iii:52-55]`. The system
improves itself and *cannot* emit wrong code while doing so.

**The honest scar.** The full autopoietic wave is **un-runnable as one binary (~1.25 GB BSS)**
`[cited: ser_pipeline.iii:142]`; the pieces are runtime-proven (e.g. conservation 2073=99 `[gated]`)
but the whole-loop wiring is *structural*, not runtime-verified. This is the single least-complete
part of the realization.

---

## 4. The ripples — do they still matter, and should they be done better?

There are **multiple distinct "ripples"**, and the name is overloaded:

1. **`eidos/ripple`** — the substrate atom. Proves the *spatial* ripple (a gradient on a
   dependency edge, `omnia::ripple_field`) and the *temporal* event (a content-addressed
   `<verb,a,b>` on the `omnia::isub` bus) are **one block read two ways: SPATIAL = gradient
   "now", TEMPORAL = event log, state = fold** `[cited: eidos/ripple.iii:3-33]`. EVENT-primary /
   STATE=fold is *realized here*, by encapsulation (K 1.00, no island).
2. **`forcefield/ripple*`** — a *change* calculus: proof-gated MERGE/CUT/EXTRACT moves on the
   system's own e-graph; each admitted move earns a content-addressed crystal
   `[cited: proof_ripple_unified.iii:1-18]`. This is the system *editing itself*.
3. **`omnia/ripple_field` + `omnia/isub`** — the underlying spatial/temporal mechanisms #1
   encapsulates.

**Do they still matter? Yes — they are load-bearing,** not vestigial: #1 is the EIDOS atom, #3
is what it folds, #2 is the self-optimizer's edit unit, and `eidos/field` already unifies
ripple_field + event_substrate `[cited: ser_eidos.iii:5-6]`. The network "relay/distance-field"
(the wavefront demo) is the *spatial* fold of #3.

**Should they be done better? Yes — by unification, not rework `[judgt]`.** #1 (substrate atom)
and #2 (self-edit move) are the **same pattern at different layers**: a self-modification *move*
**is** an event that mutates a graph, and its move-crystal **is** an event payload. They are
currently **unwired** — two ripple vocabularies. The right move is to make a `forcefield` ripple
*emit onto the same event substrate* `eidos/field` carries, so there is **one ripple concept**
(a witnessed, content-addressed change-event) with two consumers (planner + self-optimizer).

---

## 5. The weaves — and "the weave is the one primitive"

**Three genuinely different "weaves"** share the name `[cited]`:

1. `numera/weave` — the **don't-care optimization bridge**: lift a binary computation into the
   6-valued logic where don't-cares are first-class, collapse *through* the freedom, lower back
   with a `bv_bits` proof on the care-set. "lift → collapse-on-don't-cares → lower-with-proof…
   unified by PROCEDURE, not by one formula" `[cited: weave.iii:1-13]`. A *technique*.
2. `eidos/weave` — the **ripple-quanta planner**: compose real ripples into a plan, cost derived
   from real geometry, execute as witnessed ripples `[cited: eidos/weave.iii:3-9]`. A *planner*.
3. `numera/weave_graph` · `weave_self` · `weave_interfile` — the **dependency/connection graph**
   (import-vs-call, dead-import gate). The system's *self-structure*.

**Adjudication.** The *weaving principle* — **compose existing faculties; author nothing III
already discovers; wire into a live path** — IS a genuine universal meta-primitive (it is the
`no-islands` law `[cited: standards one-substrate]`). But the *noun* "weave" naming three
different concrete things is a real smell and part of the disjointedness. **Recommendation:**
keep the principle, **disambiguate the names** (e.g. `dontcare_bridge`, `ripple_planner`,
`dep_graph`).

---

## 6. The numbers — is the "living math between the logs" real?

- **`omnia/crystal`** — a provenance-sealed value: `cause` = prior crystal id (a **causal DAG**),
  `k_fixed` = K at mint, MAC-sealed against forgery `[cited: crystal.iii:14-22]`. A value that
  knows where it came from. (Object-stored, hence the FC-COLLIDE scar — a perfect microcosm of
  §2: an *event-shaped* value forced into a *handle table*.)
- **The lazy exact-real** (last session): Tier-1 i64 interval → Tier-2 e-graph/canonicalization
  → Tier-3 separation-bound bigint, bigint *demoted to last resort*. The **named limit holds**:
  e-graph Tier-2 must be **opt-in** or its overhead defeats Tier-1 — the same layering law as §2.4.
- **The Atlas** literally types the e-graph as the number's home: `[t]` an ≡-class under rules R,
  with min-cost extraction; superposition `|[t]| ≥ 2` `[cited: interior-logic-atlas.md:274-301]`.

So the "living number" is real **for the witnessed/exact layer** (crystals, e-classes,
separation-bound predicates) and correctly **absent from the hot layer** (plain i64/bigint
limbs). That is the right answer, not a compromise.

---

## 7. The substrates, layered (the actual shape of III)

III is not one substrate; it is **one law over five substrates**, each the right tool for its job:

| Substrate | Realization | Job | Right for |
|---|---|---|---|
| **Faculty law (P,D)** | the Atlas spine | admission: `D(x)=1` to admit; `D ⊥ statistic` | *every* deciding module |
| **Event log / fold** | `event_substrate`, `eidos/field`, `dome` | history, witness, reverse | commits, proofs, self-edits, provenance |
| **E-graph / XII** | `congruence`, `omnia/xii_*` (40 rules), `ser_egraph`, `verb_geom` | equivalence, optimization, superposition | "what is equal / cheapest" |
| **SVIR** | `sovir/*`, `sovtc/*` | portable execution + zk-proof of execution | running + proving runs, no gcc |
| **Crystal** | `crystal`, numera provenance | sealed provenance-carrying value | errors, audited values |

The **e-graph is genuinely load-bearing in the live compiler — narrowly (verified this pass).**
`cg_r3` calls `ser_egraph`'s sealed plans at real codegen sites: `seg_mul_plan` (`cg_r3.iii:2563`,
multiply strength-reduction) and `seg_div_plan`/`seg_div_magic_m`/`seg_div_shift`
(`cg_r3.iii:2684-2687`, division-by-constant), where per `cg_r3.iii:229` "the e-graph saturates
x*v, extracts the cost-optimal equivalent, PROVES it." `verb_geom` extracts *geometry* from the
same engine; `forcefield` mutates it with proof-gated ripples; SVIR is the common lowering target.
So "program + optimizer + proof = one e-graph object" is **realized narrowly** (arithmetic strength
reduction *is* live in the compiler) and **aspirational broadly** (general equality saturation as
*the* optimizer is not yet the codegen path). `[gated: cg_r3.iii:2563,2684-2687]` *(This corrects
two over-statements: my own earlier "connective tissue" overstated breadth; the parallel systems
map's "cg_r3 calls the e-graph zero times" was an error — it checked the general `eg_*` API and
missed the `seg_*` plan calls.)*

---

## 8. The Hexad — "is there a perfect structure per module, or one for all?"

III already answers this. The **Hexad** is a 6-dimensional ternary "kind" algebra (3⁶ = 729
possible, **144 admitted**) and **every module declares its kind** (`kind_essence`,
`kind_compose`, `kind_form`, `kind_cognition`, `kind_mobius`, `kind_sensitivity`)
`[cited: hexad.iii:1-17]`. The answer is therefore neither "one rigid structure for all" nor "a
bespoke structure per module." It is:

> **One law, many kinds.** Every module is the *same kind of thing* — a sealed `(P,D)` faculty
> with a Hexad kind, a Ring (R-1/R0/…), a K-value, and (if it decides or asserts) a falsifier.
> Its **kind** names its nature/sphere; its **internal representation** (fold-over-log vs
> handle-table vs plain value) is chosen by **one question: must this state be witnessed,
> reversed, or audited?** If yes → event-fold; if it's hot transient → plain values; if it's an
> equivalence → e-graph. The uniformity is the *law*; the diversity is the *kind* and the
> *representation it earns*. `[judgt]`

There is **no "perfect language" beyond III itself** lowering through SVIR `[judgt]`. The
verb-geometry surface (last session) is the *human-facing* dialect over this same spine; it is
not a different architecture.

---

## 9. The one primitive — a target, not yet a fact (a refuted over-claim, corrected)

It is tempting to declare a single universal primitive: the content-addressed **`{BELOW,
REFLECT}` block** — a dominance order plus its order-reversing involution. It appears in
`eidos/ripple` (V_BELOW/V_REFLECT/V_NONE, direction from `rf_rank`)
`[cited: eidos/ripple.iii:55-68]`, in `omnia/master_logic` (the assimilation web that *provably
subsumes* `logic6` into `{BELOW, REFLECT}` blocks; `ml_named_is_redundant` is the deprecation
gate) `[cited: master_logic.iii:16-22,110]`, and in the `isub` bus.

**Adversarial verdict: REFUTED as "the single primitive, realized identically."** They share the
*two-verb pattern* but are **separate engines with separate address spaces** (`isub`'s
`sha256(verb‖a‖b)` vs `assimilate`'s value-code addresses). So this is a **recurring pattern and
a unification target**, not an existing single primitive — and that duplication is itself part of
the disjointedness. **Recommendation:** build the one `{BELOW, REFLECT}` content-addressed
order+involution engine and route ripple, master-logic, and isub through it. *Then* it is the
one primitive. `[judgt]`

---

## 10. What sucks / needs to go — the kill / fix list

Ranked by leverage. None requires abandoning anything excellent; all are *convergence*.

1. **Object-storage on witnessed/identity paths → migrate to event-fold or content-address.**
   The handle-table family (bigint 64-slot, crystal 256-slot) is the source of the real
   exhaustion + aliasing bugs (§2.2). Keep handle tables for *hot transient* pools; move
   *identity-bearing* state (crystals, the self-model, commit frontiers) to content-addressed
   event-fold. `[judgt]`
2. **POC scale caps → gospel scale with incremental folds.** `event_substrate` 256,
   `dome` 512 are POC; the full wave is un-runnable at ~1.25 GB. Adopt `self_model`'s Merkle/
   re-address pattern so the witnessed layer scales and the autopoietic loop runs whole. `[judgt]`
3. **Duplicate vocabularies → unify.** One ripple (merge `forcefield` change-ripple onto the
   `eidos/field` event substrate); one `{BELOW,REFLECT}` engine (§9); disambiguate the three
   `weave` names (§5).
4. **`dome` → supersede-and-absorb, not delete.** Build on `eidos/field`, never `dome`
   `[cited: ser_eidos.iii:5-6]`; migrate the *society of twins* concept into `field`, then retire
   the `dome` module.
5. **Float at non-boundary sites → sweep.** Float is well-contained (57 sites; mostly
   `glyph_f64`/`q128_f64` interop bridges, which are justified). Audit the few core-ish uses
   (`omnia/resolver`, `verba/nl_lex`) and replace with exact/integer where they are not true
   interop boundaries. `[cited: grep f64]`
6. **`nous` — keep, but watch the line.** It is no-ML *compliant* (propose-and-checked; trainer
   out-of-tree; certified results survive a retrain) `[cited: nous_charter.iii:6-10;
   nous_train.iii:3; nous_value.iii]`. But it *redrew* "no learning" → "no learning on a deciding
   path." That is principled and the closest III comes to the line; it must stay strictly
   propose-only, and any path where a `nous` rank *decides* without a deterministic check is a
   breach. `[judgt]`
7. **The formal spine doesn't yet cover the peripheries.** The Atlas §G formalizes the
   reasoning/compiler/self-mod core; `aether` (exact geometry), `verba` (serialization),
   `katabasis` (metal), `tempora` are realized but not folded into the shared-symbol theory.
   Extending §G to them is the long-horizon convergence. `[cited: interior-logic-atlas.md:972-996]`
8. **Build coverage ratchet is RED** — 119 dark / 56 uncovered / 8 under-proven, over the pins
   (5/14/2). The system honestly flags its own islands; the fix is *cut the dark or wire it*, not
   move the pins. `[gated: _cov_reach_report.txt; build_stdlib rc=3]`
9. **Sovereign cross-language independence is broken** — `crosslang=NO`: `ccsv`'s SVIR no longer
   matches the independent `iiisv` front-end on `indep_toolchain.iii` (likely the recent ccsv
   typed-memory ABI change not mirrored in `iiisv`). This is the DDC/supply-chain *independence*
   guarantee — substantive. Fix = mirror the ABI change into `iiisv`. `[cited: III-SYSTEMS-MAP.md A5]`
10. **Stale broken `debug_sha256_empty.exe`** prints a WRONG hash (`7548d587…`) while production
    SHA256 is FIPS-correct. THROW the stale intermediate so it cannot be mistaken for live.
    `[cited: III-SYSTEMS-MAP.md B]`
11. **The cartographer is not native, not NIH → THROW from the sovereign capability ledger** (user
    directive). Detail + the capability gap it leaves: §16.

**The consolidated, prioritized actions live in §15 (Disposition Ledger).**

---

## 11. Could III be a system unlike any ever built — and must it be?

**Could it? Yes, and it largely already is `[judgt]`.** The *combination* is unusual to the point
of unique: a self-hosting language whose every faculty is a `(P,D)` pair with a decidable disposer
that may not read a statistic; modules coupled *only by shared symbols*; state-as-fold-over-an-
append-only-witnessed-log with reversible provenance-carrying deliberation; a self-model Merkle
DAG the system aims its own proof-gated self-modification at; a sovereign IR with zk-provable
execution and no gcc in the trusted path; and a deprecation engine that *proves a primitive
redundant* before deleting its name. No mainstream system has that shape.

**Must it be unique to be maximally special? No — and chasing uniqueness is the wrong target
`[judgt]`.** Uniqueness is a *consequence*, not a goal. The goal is **the law holding
system-wide**: every module a sealed faculty, every decision falsifiable, every change witnessed
and reversible, every name earned. A system that achieves that *will* look unlike anything else,
because almost nothing else pays that price. Pursue the law; the uniqueness follows.

**Can it keep breaking ground? Yes — the autopoietic loop is the ground-breaking engine itself**
(`self_model.sm_next_gap` → `nous` proposes → Seraphytes prove → `forcefield` ripples apply →
`eidos/field` witnesses) `[cited: self_model.iii:10,191; ser_pipeline.iii]`. Its ceiling today is
**scale** (the 1.25 GB whole-loop) and **proposer quality** (`nous`). Close those and the loop
compounds. The effort is large; the direction is sound.

---

## 12. The universal architecture (the recommendation)

> **One law (the Atlas `(P,D)` faculty over shared symbols, `D ⊥ statistic`, Σ self-mutating
> under the same D). Many kinds (the Hexad). Five substrates, each earned by a single question —
> must this state be witnessed/reversed/audited? Event-fold if yes; plain values if hot; e-graph
> if it's an equivalence; SVIR to execute; crystal to carry provenance. Unify the duplicated
> atoms (one ripple, one `{BELOW,REFLECT}` engine, disambiguated weaves). Scale the witnessed
> layer with incremental Merkle folds. Extend the formal spine from the core to the peripheries.**

Migration order (highest leverage first): (1) unify `forcefield` ripple onto `eidos/field`;
(2) move identity-bearing object state to content-addressed event-fold; (3) incremental-fold the
witnessed layer to retire the POC caps and run the whole autopoietic loop; (4) build the one
`{BELOW,REFLECT}` engine; (5) extend Atlas §G to `aether`/`verba`/`katabasis`.

---

## 13. Named limits & adversarial residue (honest)

- **"Every module is a (P,D) faculty" is overstated** — data structures (`list/map/vec/queue`)
  are *carriers*, not faculties. The law governs deciding/generating modules. `[adversary]`
- **The Atlas covers the core, not the whole** — peripheries are realized but not yet in §G. `[adversary]`
- **The "one primitive" is a target, not a fact** — `{BELOW,REFLECT}` is duplicated across
  separate engines (§9). `[adversary]`
- **Event-fold scales only with incremental/Merkle folds** — naive full-prefix folds
  (`evt_witness`) are O(n)/call. `[adversary]`
- **The whole autopoietic loop is unverified at scale** (~1.25 GB) — components proven, the union
  structural. `[cited: ser_pipeline.iii:142]`
- This audit re-read ~26 modules of 3,200; subsystem-level claims are sampled, not exhaustive.
  `cg_r3`'s e-graph call sites WERE re-read and verified this pass (`cg_r3.iii:2563,2684-2687`); its
  remaining internals are taken from the prior session + Atlas §G. `[judgt]`

---

## 14. Capability × Structure — what each substrate actually DOES (integrated)

The genuine-output audit (`III-SYSTEMS-MAP.md`) and this structural audit are dual views of one
system. Mapping its verdicts onto the five substrates of §7:

| Substrate | Genuine-output status | Evidence |
|---|---|---|
| **Faculty law (P,D)** | shape confirmed *empirically* | only `aether` has a standalone `main`; all else is called-not-run — exactly what "many kinds coupled by shared symbols" predicts |
| **Event log / fold** | WORKS (POC scale) | `eidos/field` accept/rollback runs (`ser_eidos`); caps 256/512; whole autopoietic wave un-runnable ~1.25 GB |
| **E-graph / XII** | WORKS — *narrowly* load-bearing in the live compiler | `cg_r3` calls `seg_mul_plan`/`seg_div_plan` (`cg_r3.iii:2563,2684-2687`); `verb_geom` interns `√8≡2√2`; general saturation not yet the optimizer |
| **SVIR / sovereign toolchain** | WORKS, with a broken independence guarantee | 3,584-byte 1-DLL exit-99 native binary; **but `crosslang=NO`** (ccsv≠iiisv) |
| **Crystal / provenance** | WORKS via real consumers | bigint, e-graph, crypto, arena consumed by genuine runs; SHA256 = FIPS vectors |

**The corroboration is the headline.** Two independent audits — one of structure, one of capability —
converged: III is *library-heavy by design* because it is *faculties coupled by shared symbols*, not
standalone programs. That is not a defect; it is the architecture showing through. The genuine
**standalone** surface (compiler, build, XII crypto, sovereign toolchain, exact math) sits mostly at
the *edges* (execution + sovereignty + geometry) — exactly the substrates that *must* emit external
artifacts. The *interior* (numera/omnia/nous/forcefield/eidos/sanctus) is correctly library: it is
*called*.

The islands (`au_*` autopoietic-crush, `aff_*` affine-audit) are the realization gap made concrete —
and the SAME gap the structural audit named: the autopoietic loop is both un-runnable at scale *and*
its crush-surface unreached (`au_svir_to_netlist`, `au_conform_*`, `au_merkle_*`, `au_crucible_*` all
dark per the build's own `_cov_reach_report`). Double-confirmed by both audits independently.

---

## 15. Disposition Ledger — fix / throw / refactor / merge / split

Judgment delegated by the user. Status: `applied` · `ready` (safe, specified, awaiting greenlight) ·
`session` (needs its own disciplined session on load-bearing/sovereign code). The high-leverage
substantive fixes are **decided and specified, not executed mid-audit** (load-bearing / sovereign /
OneDrive-sync hazard). Throw decisions were adversarially checked for non-obvious consumers.

**KEEP (works; don't touch the core):**
- `iiis-2` self-hosting compiler — the flagship. *(cosmetic FIX `ready`: banner self-IDs as "iiis-0".)*
- `nous` proposer — no-ML *compliant* (propose-checked; trainer out-of-tree). **WATCH**: stay strictly
  propose-only; a `nous` rank that *decides* without a deterministic check is a breach.
- exact arith/geometry (bigint/isqrt/e-graph/lazy-real/fractal-dim) — real, cross-checked to closed form.
- SHA256 + XII crypto toolchain — FIPS-correct; real keys/manifest/MPHF/lattice.

**FIX (real, worth it):**
- **e-graph → cg_r3: extend narrow → general** `[session]`. `seg_mul_plan`/`seg_div_plan` are wired
  (mul/div strength reduction); the one-object thesis becomes fully real when general saturation drives
  more of codegen. Highest structural leverage.
- **Sovereign `crosslang=NO`** `[session]` — mirror the ccsv typed-memory ABI change into `iiisv` so the
  two front-ends agree; restores the DDC independence guarantee.
- **Build coverage RED** `[session]` — drive 119 dark / 56 uncovered under the pins by *cut or wire*
  (see THROW / WIRE rows), not by moving the pins.
- **POC scale caps** `[session]` — event 256 / dome 512 / the 1.25 GB wave → incremental Merkle folds
  (the `self_model` pattern) so the witnessed layer scales and the whole autopoietic loop runs.
- **`run_ccsv.sh` backtick noise** `[ready]` — escape the 44 log-string backticks (verified all 44 are
  in log strings). A prior in-place edit didn't survive OneDrive sync; apply in a clean step.
- **Float at non-boundary sites** `[session]` — sweep `omnia/resolver`, `verba/nl_lex`; replace with
  exact/integer unless a true interop boundary (`glyph_f64`/`q128_f64` are legit boundaries — keep).

**THROW (remove; zero capability loss — consumer-checked):**
- **Cartographer** `[applied-in-doc]` — non-native, non-NIH (user). Out of the sovereign ledger. §16.
- **Stale `debug_sha256_empty.exe`** `[ready]` — a broken intermediate printing a wrong hash; `rm`.

**WIRE-or-SHELVE (dark, but real in-progress — do NOT blind-throw):**
- **`au_*` autopoietic-SVIR-crush family** `[session]` — the autopoietic-seed-synthesis surface
  (amputate the C seed → proof-carrying SVIR). Dark per `_cov_reach`, and `ser_antiunify` references it
  (a blind throw breaks that compile). **Verify each is healthy (compiles + KAT green), then finish the
  Leg-B wiring or explicitly shelve with a dated note** — don't leave dark indefinitely (no-islands).
- **`aff_*` affine-audit family** `[session]` — real alias/affine analysis with a prior `--affine-audit`
  CLI. Dark now; restore the entry (WIRE) or THROW if truly orphaned.
- **`bb_render` / `eg_render` / `eg_window_main`** `[session]` — visualization surfaces in the dark
  list; confirm whether they are the (now-thrown) carto-adjacent UI render or a real native view —
  WIRE if native+used, THROW if carto-tail.

**REFACTOR / MERGE / SPLIT (structural convergence — all `[session]`):**
- **MERGE the two ripples** — wire `forcefield`'s self-edit ripple (MERGE/CUT/EXTRACT + move-crystal)
  onto the `eidos/field` event substrate, so a self-edit *is* a witnessed event. One ripple concept.
- **MERGE the `{BELOW,REFLECT}` engines** — `isub` (sha256) and `assimilate` (value-codes) are the same
  order+involution pattern on two address spaces; build one content-addressed engine, route both
  through it. *Then* it is the one primitive (§9).
- **MERGE `dome` → `eidos/field`** — supersede-and-absorb the society-of-twins; retire `dome` (build on
  field, never dome).
- **SPLIT-by-rename the three weaves** — `numera/weave`→`dontcare_bridge`, `eidos/weave`→`ripple_planner`,
  `weave_graph/weave_self`→`dep_graph`. Keep the *weaving principle*; kill the *name collision*. (Touches
  consumers' `extern…from` — one mechanical sweep.)
- **SPLIT-by-rename the `au_*` collision** — the UI/geometry crush and the autopoietic-SVIR crush share
  the `au_` prefix; disambiguate so the dark surface is unambiguous.

---

## 16. The cartographer — thrown (non-native, non-NIH), and the gap it leaves

Per user directive: the cartographer (`III-CARTOGRAPHER/`, `carto.exe`) is **not native and not NIH**,
so it is **removed from III's genuine-capability ledger.** It may still be *used* as an external aid,
but it is outside the trusted/sovereign base and is not one of III's own faculties. Consequently the
systems map's `1101 nodes / 2136 edges / iii-atlas.html` figures are **external-sourced, not
native-verified** — demoted to "external tool output" wherever cited. (This audit's own subsystem
counts — 3,200 `.iii`, the 12-domain split — came from native `find`/`ls`, not carto, and the 119-dark
figure is from the build's own `_cov_reach_report`, so they stand.)

**The gap this leaves (named, not hand-waved).** III's *native* self-map is `sanctus/self_model.iii` —
a Merkle DAG of its own **export call graph** (16,384-node cap, one root, `sm_next_gap` the proposer's
target) `[gated: self_model.iii:191]`; its *native* reachability is `_cov_reach_report` (from
`build_stdlib`, bash + `iiis-2`). These cover the **proven export graph** — but NOT what carto did: the
**file-level** `extern…from`/`#include` edge map, cross-language/cross-tool structure, basename-dups
across the whole repo. So throwing carto leaves a real hole: **III lacks a native file-level
cartographer.** Disposition: either build one in `.iii` (promote `self_model` from export-graph to
file-edge-graph), or accept file-level cartography as out-of-base external tooling. The in-base map of
*what III proves about itself* exists (`self_model`); the file-level map does not. `[judgt]`

---

## 17. Execution log (live)

Working the ledger top-down, read-first, each verified in the artifact before being called done.

**DONE + VERIFIED (gated):**
- **E1 — stale binary thrown.** `rm STDLIB/build/debug_sha256_empty.exe` (the May-7 binary printing the
  wrong empty-SHA256 `7548d587…`). Verified gone. `[gated]`
- **E3 — sovereign cross-language DDC restored (`crosslang=NO → YES`).** Root cause (verified, *not* the
  typed-ABI hypothesis): `iiisv.iii:359` emitted an unconditional trailing `CONST 0; RETURN` on every
  function — its own comment admitted "an explicit `return e` makes this dead code" — so iiisv's SVIR ran
  20 bytes longer than ccsv's for the identical algorithm. Fix: a last-opcode tracker (`SV_LAST_OP`) emits
  the default epilogue only on fall-through, matching ccsv. `run_ccsv.sh` full gate **exit=0**,
  `ccsv(C)==iiisv(.iii)=YES`, all 40 verdicts pass — no regression. `[gated: run_ccsv exit=0]`
- **E2 — run_ccsv log-noise eliminated.** The real defect was ONE line (`run_ccsv.sh:104`, three unescaped
  backtick-pairs `` `goto fail` `` / `` `goto L` `` / `` `L:` ``), not the "44" the systems map estimated.
  Escaped them; re-run gate: `command not found` noise = 0 (was 3), goto verdict intact, exit=0. `[gated]`
- **E9 — au_*/aff_* resolved (verified; neither thrown nor fake-wired).** `aff_*` is **live**:
  `iiis-2 --affine-audit` runs (exit=0, report `AA P=0 A=0 R=0`); `affine_audit` is in the compiler's
  `PORTED_TUS` and `main.iii`'s `--affine-audit` dispatch (`main.iii:670,884,1161`). `au_*` (the
  crush/conform family in `ser_antiunify.iii`) is **sound + KAT-gated**: `run_topo_kats.sh` **PASS=6/0**,
  with `2092`/`2093` running real SVIR + a bit-blast `step==acc+delta` proof over 2^64. Both are *reached*
  (CLI / KAT), just not by another **library** export — a blind throw would break `ser_antiunify`'s compile;
  fake plumbing is the scaffolding to avoid. `[gated: --affine-audit exit=0; run_topo_kats PASS=6/0]`
  *(Also retracts the ledger's "au_ collision split": au_* is ONE crush engine in `ser_antiunify`, serving
  raster/pixel/SVIR crush — no UI-vs-autopoietic name collision exists.)*

**REFINED BY EVIDENCE (the "dark surface" is not what the count implied):**
- The 119 "dark" exports are largely **NOT dead code.** Verified: `eg_render`/`bb_render`/`eg_window_main`
  are **native e-graph UI** (`aether/ui_egraph.iii`) consumed by `ui_egraph_app`/`ui_zoom` — standalone-app
  entry points, dark only because the *library* doesn't call its own apps. `aff_*` is the compiler's
  **affine-audit, CLI-wired via `--affine-audit`** (`COMPILER/BOOT/main.iii` + `affine_audit*.iii`) — *not*
  an island. So **E5's correct fix is the coverage gate's classification** (exempt declared app/CLI entry
  points), not "cut 119." The genuine residual island is the **`au_*` autopoietic-seed surface** (E9) — a
  documented in-progress plan, to finish (Leg B) or shelve with a dated note, never blind-thrown
  (`ser_antiunify` references it). This corrects the systems map's "119 dark = islands."

**REMAINING [each its own verified cycle — load-bearing, scoped, not faked]:**
- **E4** e-graph narrow→general in `cg_r3`: a live-compiler codegen change → full bootstrap (iiis-0→3) +
  corpus regression + iiis-2==iiis-3 byte-fixpoint. Highest leverage, highest risk.
- **E5** coverage-gate entry-point classification + wire/shelve the true residual → build_stdlib to rc=0.
- **E6** event_substrate/dome flat-array caps → Merkle/incremental folds (scale re-architecture).
- **E7** rename the weave trio + `au_` split: a ~17-consumer `extern…from` sweep + full rebuild.
- **E8** merge the two ripples / the two `{BELOW,REFLECT}` engines / dome→field: deep structural refactor.
- **E5 ⚠ FINAL-CALL POINT (premise refuted).** Evidence (E9 + the UI/CLI samples) shows the 119 "dark"
  are overwhelmingly *terminal surfaces* — CLI features (`aff_*`), app entry points (aether UI), and
  KAT-gated capabilities (`au_*`) — **not dead code.** So the ledger's "cut-or-wire the 119" rests on a
  false premise: *cutting* them deletes live features; *wiring* them to library callers is exactly the
  fake plumbing to avoid. The correct fix is the coverage gate's **reachability definition** (count
  CLI/app/KAT reach, not only intra-library calls) — which is **not** "moving the pins" (the ≤14 threshold
  is untouched); it corrects a miscount. Only the genuine residual orphans after that correction are true
  cut-or-wire candidates. This needs your final call: **gate-measurement-fix** vs **literal cut-119**.

(E9 — DONE, above. au_* and aff_* verified sound/live; neither thrown nor fake-wired.)

None deferred for convenience; none claimed done without a green gate. Each remaining item is a dedicated
read→edit→build→regression cycle — the discipline the CRASH-protocol requires on load-bearing/self-host code.

---

*Method: `iii_session_law` → `iii_deep_think` → `iii_gate`/`iii_invariant_guard` → read-first
audit → `iii_adversarial_verify` (3 load-bearing claims; one refuted-and-corrected) →
`iii_check_discharge` (3 constructs DISCHARGED). No agents. No edits to `.iii`/`.py` this pass.*
