# III-SOVEREIGN-CHARTER.md — v2 (corrected, widened, facet-complete)

**Supersedes:** the v1 "Sovereign Charter" architecture draft.
**Basis:** a *verified* reading of the live substrate (see §V — every load-bearing
claim checked against the actual `.iii`), the PERFECTION-POC (base 19/19,
extended 24/24, seal `16fe0950…`), and the build harness.
**Discipline:** connect, don't add. Net-new surface is deliberately minimal; the
act is binding organs III already grew into one self-auditing body, with no
existing byte, seal, or verdict permitted to move (machine-checked, not promised).

---

## §E. Erratum — what changed from v1 and why

v1 was **substantially accurate** (its hexad/constitution/witness/xii claims
verified verbatim — §V). It is superseded only to fix five honest defects and to
widen a scope that was written against an earlier, smaller III:

1. **Modifier semantics overstated.** v1 framed `@variant`/`@provenance`/`@crystal`
   as "existing Phase-2 vocabulary." They exist as **lexer tokens + corpus tests**
   (`lex.iii:713–726`, corpus 104–118) but are largely **codegen no-ops today**.
   The semantics v1 ascribed to them are **net-new** (this doc marks them so).
2. **Reinvention of `quine_verifier`.** v1 C7 proposed a behavioral quine-seal
   fresh. `numera/quine_verifier.iii` **already exists** (corpus 617). C7 now
   *reuses* it.
3. **Omission of `constitution_preserver`.** `numera/constitution_preserver.iii`
   exists (corpus 655) and is on-point for the "constitution as conscience"; C4
   now reuses it.
4. **Scope too narrow.** v1 bound ~8 organs. III has **~22+ built** (§0). The
   "one currency, one conscience" thesis is the natural unifier for the whole
   convergence layer (SAT/SMT/Gröbner/e-graph/category/temporal/cost/memo), which
   v1 never mentioned.
5. **SovVal and the conscience were incomplete.** SovVal lacked a **cost** facet
   (III tracks cost via `cost_lattice.iii`); clauses ignored the **LTL field they
   already carry** (`temporal_logic.iii` is built); and the charter *detected*
   incoherence without a **repair** loop.

---

## §V. Verification status (do not trust a claim past its evidence)

**Verified by direct reading of the live `.iii` (high confidence):**

| Claim | Evidence |
|---|---|
| 144 of 729 hexads admitted | `omnia/hexad_reach.iii`: "Admitted count = 2⁴·3² = 144", `HXR_HEXAD_MAX=729` |
| `iii_hexad_compose6`, base-3 (0..728) | `omnia/hexad_algebra.iii:140, :16` |
| 6 bricking ops untypable (NEG in pillars 1..4) | `omnia/hexad_pfs.iii:29–34` |
| Constitution: 11-opcode VM, `cons_eval_predicate`, `Keccak256(text)` keys, `CLAUSE_RATIFICATION` | `numera/constitution.iii:11–26, 569` (verbatim) |
| `wh_publish` witness API | `aether/witness_hook.iii`, widely consumed |
| Gate verdicts `REJECT_HEXAD/SEAL/CAP` | `katabasis/gate.iii`, `gate_verdict.iii` |
| Modifiers exist as tokens | `COMPILER/BOOT/lex.iii:713–726` + corpus 104–118 |
| All cited convergence organs built + KAT'd | corpus 613/614/615/617/620/632/633/634/635/638/639/640/644/646/649/654/655 |
| Toolchain present + lib sealed | `COMPILED/iiis-2.exe`, `STDLIB/build/iii/libiii_native.a(.mhash)` |

**Verified this session (high confidence):** the *pinned* corpus
(`IIIS=COMPILED/iiis-2.exe bash STDLIB/scripts/run_corpus.sh`) ran
**PASS=376, FAIL=0, SKIP=98** — every cited charter/convergence module green
(`639_proof_carrying`, `655_constitution_preserver`, `638_groebner`,
`644_temporal_logic`, `646_memo_lattice`, `637_sat_at_scale`,
`647_theorem_carrier`, `649_reversibility_audit`, `654_memo_query`, … all
exit 99). **Caveat:** `SKIP=98` is the **XII corpus (280..372,
`run_xii_corpus.sh`) + perf benchmarks (237/242/243/244,
`run_bench_corpus.sh`)** — separate harnesses **not** executed this session, so
the rewriter subset is green-by-record, not green-by-this-run.

**Not independently recomputed (low-stakes):** the packed PFS integers (capsule
324, smram 243), `728∘0→648`, the `xii_*` file sizes. Structurally consistent;
not load-bearing for the design.

**Correctly net-new (do not exist; this doc creates them):** `omnia/sovval.iii`,
`@sovereign`, the SovVal **cost** facet, temporal clauses, the dependent-kernel
layer, the repair arm.

---

## §0. The finding (widened) — III is one organism; the nervous system is unconnected

| Charter property | Lives in III as… | Status |
|---|---|---|
| Hexad safety / REP / compose | `hexad_algebra/reach/pfs/epistemic/mobius/dynamic.iii` | richer than POC |
| Reversibility (SID) + audit | `omnia/sid.iii`, `numera/reversible.iii`, `aether/reversibility_audit.iii` | live |
| Confluence + strong normalization | `omnia/xii_rewrite/critpairs/canonicalise.iii` (Knuth–Bendix) | live, beyond POC |
| Proof-carrying + terms | `numera/proof_carrying/proof_term/theorem_carrier.iii` | live (carrying); normalizing *checker* is the gap |
| Content addressing + NIH hash | `numera/sha256.iii`, `keccak256.iii` | live |
| Witness commons + self-audit | `numera/witness_spine.iii`, `aether/witness_hook.iii` (`wh_publish`) | live; *forgetting* is the gap |
| Charter engine | `numera/constitution.iii` (+ `constitution_preserver.iii`) | **already a charter engine** |
| Determinism + conservative-extension gate | `build_stdlib.sh`, seal-gated `build_iiisN.sh`, `SEAL.mhash`, closure meta-gate | live |
| verify ∧ falsify | positive corpus + `NNN_neg_*` rejections | both axes run, judged separately |
| **Unified typed gap + provenance** | pieces only (`either.iii`, `checked.iii`, `hexad_epistemic.iii`) | **genuine new connective work** |
| **— widened (v2) —** | | |
| Decision procedures | `numera/sat.iii`, `smt.iii`, `groebner.iii`, `egraph.iii` | **built; v1 ignored** |
| Categorical composition | `numera/category.iii` | **built; v1 ignored** |
| Temporal logic (LTL) | `numera/temporal_logic.iii` + the clause LTL field | **built; v1 ignored** |
| Cost | `numera/cost_lattice.iii`, `cost_calculus.iii` | **built; SovVal lacked the facet** |
| Provable memoization | `numera/memo_lattice.iii`, `memo_query.iii` | **built; an emergent already realized** |
| Self quine-verification | `numera/quine_verifier.iii` | **built; v1 proposed it fresh** |
| Computation provenance / branch | `numera/computation_graph.iii`, `branch_anchor.iii`, `aether/snapshot_lattice.iii` | built |

---

## §1. Requirements (delta from v1)

Carried from v1: FR-1 Sovereign currency; FR-2 unified uncertainty; FR-3
constitution-as-self-audit; FR-4 provable forgetting; FR-5 behavioral quine-seal;
FR-6 gate on SovVal; FR-7 proof anchor. **Revised / added:**

- **FR-1′ — SovVal carries four facets.** `SovVal = { payload: Known|Gap, hexad:
  u16, witness: frag_id, cost: cost_lattice_pt }`. `sv_op` composes payload
  (sound gap arithmetic), hexad (`iii_hexad_compose6`, refuse non-reachable),
  witness (`wh_publish`), **and cost (`cost_calculus` join)** — so the K-floor
  (≥0.85; gate ≥0.99) becomes a property the value *carries*, checked at every op.
- **FR-3′ — clauses may be temporal.** A clause's predicate is either the
  instantaneous 11-opcode bytecode (today) **or** an LTL formula over the witness
  chain (`temporal_logic.iii`), so the charter can assert *liveness* ("a red build
  eventually quarantines") and *safety* ("the seal is always reproducible"), not
  only point-in-time `verify ∧ falsify`.
- **FR-5′ — quine-seal reuses `quine_verifier.iii`** (no new module).
- **FR-7′ — the kernel dispatches to decision procedures.** Π2 (decidable
  checking) and proof obligations may be discharged by `sat.iii`/`smt.iii`/
  `groebner.iii`/`egraph.iii` (already built), with XII as the reduction engine
  and `category.iii` supplying `sv_op`'s associativity/identity laws.
- **FR-8 — detection→repair.** A red charter verdict is an input to the immune
  layer (quarantine + regen), closing the loop from *detecting* incoherence to
  *restoring* it. (Repair modules are spec-staged; this FR is the seam.)

NFRs unchanged (determinism, NIH, zero-downside, conservative-extension,
ring-safety, anti-bricking, K-floor, density). Constraints unchanged (monomorphic,
equality-only trit compares, Trap-7 scratch, W-laws, no statistical learning).

---

## §2. Conviction (unchanged, now broader)

> "No compromise" is satisfiable because the integration is itself the charter's
> flagship theorem (Π8, conservative extension), and III already owns the gate
> that proves it. A regression is not a risk to mitigate — it is a red build.

Widened: this now also holds for the convergence organs. Binding SAT/SMT/cost/
temporal under the Sovereign Value + Constitution is admitted only if `SEAL.mhash`,
`libiii_native.a.mhash`, and the full verdict vector reproduce.

---

## §3. Pattern (unchanged): Sovereign-Value Bus + Constitutional Self-Audit

The only thing that crosses a boundary is a Sovereign Value; the only thing that
blesses a build is the constitutional seal. Non-interference and gap-containment
are structural. Rejected alternatives (parallel charter subsystem — Anti-Bloat
violation + two-of-everything drift; runtime policy engine — ordering
non-determinism) stand as in v1.

---

## §4. Components (corrected + widened; net-new is small)

- **C1 — `omnia/sovval.iii` (net-new): the four-facet spine.** `{payload, hexad,
  witness, cost}`; total `sv_op`; refuses non-reachable hexads. Reuses
  `hexad_algebra/reach`, `witness_hook`, `sha256`, **`cost_calculus`**.
- **C2 — `numera/uncertainty.iii` (net-new): the one genuine new organ.** Single
  typed gap + content-addressed provenance DAG; total/sound/precise arithmetic
  (`÷0→gap`, `0·unknown→Known(0)`); `root_causes`/`explain`. Supersedes the ad-hoc
  paths in `either`/`checked` (their APIs delegate, unchanged — corpus proves no
  regression).
- **C3 — Hexad lattice: reuse verbatim** (`hexad_*`). `is_representable :=
  iii_hexad_reachable`.
- **C4 — Constitution conscience (extend `constitution.iii` + reuse
  `constitution_preserver.iii`).** Add a `falsifier` per clause; add the
  **temporal** predicate kind (LTL over the chain); `run_charter()` fuses positive
  corpus + `NNN_neg_*` + drift gates + closure meta-gate into one **charter seal**;
  becomes the build's terminal gate.
- **C5 — Witness commons + provable forgetting (extend `witness_spine.iii`).**
  `redact(frag,reason)` + `proves_forgetting` (integrity ∧ continuity ∧
  blast-radius), reusing SID inverses + the unified gap. (Check `witness_compactor`
  spec for overlap before building.)
- **C6 — Proof kernel on XII (`numera/kernel.iii`, net-new checker).** Inductive
  types + structural recursion + SN (Π21), strict positivity (Π22), `False`
  uninhabited (Π1), decidable checking (Π2). Reuses XII as normalizer,
  `proof_term`/`theorem_carrier` for terms, the hexad lattice for propositions,
  **and `sat`/`smt`/`groebner`/`egraph` as decision procedures**; **`category.iii`**
  supplies `sv_op` composition laws. Frontier: dependent Π-types + universes.
- **C7 — Behavioral quine-seal: reuse `quine_verifier.iii`** + extend the closure
  seal to commit to source *and* emitted machine code (instance-check; Gödel-safe).
- **C8 — Gate re-founded (`katabasis/*`): consume SovVal**, so HEXAD-inadmissibility
  is *unrepresentable*, not runtime-rejected. Four-verdict self-test reproduces.
- **C9 — Cost (`cost_lattice.iii`/`cost_calculus.iii`): reuse.** Supplies SovVal's
  cost facet and the K-floor join. **Net-new: none** beyond the SovVal field.
- **C10 — Memoization (`memo_lattice.iii`/`memo_query.iii`): reuse.** Determinism +
  content-address ⇒ provably-correct caching; the charter *claims* it as a held
  property (cache-hit ≡ recompute is a clause).
- **C11 — Repair arm (immune layer; spec-staged).** Charter-red → quarantine +
  regen. Net-new: the seam from verdict to repair; the repair modules are
  spec-staged and built incrementally.

---

## §5. Data flow — the life of a four-facet value

```
 literal/input ─► sv_lift(bits, hexad, cost)               ── born sovereign
   └─► sv_op(op,a,b): payload(gap-sound) · hexad(compose6) · cost(join) · witness
        ├─ reachable(hexad)? ── no ─► Refused              [bricking impossible]
        ├─ cost ≤ K-floor?   ── no ─► Refused              [over-budget impossible]
        └─ yes ─► SovVal' ─► wh_publish ─► witness_spine (append / forgettable)
 build terminal gate ─► constitution.run_charter():
   each clause: (verify ∧ falsify)  |  LTL over the chain  ─► verdict vector
        └─ seal == golden ∧ all hold ─► GREEN  + quine_verifier over src+emitted-code
           else ─► RED ─► (C11) quarantine + regen
```

---

## §6. Language deepening (honest about current state)

The `@`-modifiers `@variant @provenance @crystal @linear @sealed @constant_time`
are **lexer tokens with corpus tests but are codegen no-ops today** (verified).
The deepening *gives them teeth*, within the monomorphic discipline:

- **`@variant` → a real exhaustive tagged union** (`payload: Known | Gap`), lowered
  by kind-tag + `when`-cascade (no fn-pointers); exhaustiveness statically checked
  (new `III_VARIANT_NONEXHAUSTIVE` negative test — a falsifier).
- **`@provenance` → a type-level DAG edge**; **`@sovereign fn` (net-new token)** →
  asserts a function only consumes/produces Sovereign Values (new
  `III_NONSOVEREIGN_BOUNDARY` falsifier).
- Everything else is ordinary III. Deeper (stronger static guarantees), never wider.

---

## §7–§8. Cross-cutting & ADRs (carried from v1, plus)

- **ADR-7 — Reuse the convergence layer; do not rebuild it.** Quine-seal ←
  `quine_verifier`; conscience ← `constitution_preserver`; kernel decisions ←
  `sat/smt/groebner/egraph`; composition laws ← `category`; cost ← `cost_lattice`;
  memo ← `memo_lattice`. *Consequence:* the net-new surface stays the unified
  uncertainty value + the kernel checker + the wiring — nothing else.
- **ADR-8 — Cost is a value facet, not a side computation.** *Consequence:* the
  K-floor rides every value; over-budget compositions are `Refused` like bricking.
- **ADR-9 — The conscience is temporal.** Reuse the clause LTL field + the built
  `temporal_logic.iii`. *Consequence:* liveness/safety are charter-checkable.
- **ADR-10 — Detection implies repair.** *Consequence:* a red verdict is an event
  the immune layer consumes; the system restores, not just refuses.

---

## §9. Roadmap (deepest-first; each phase gated by the charter)

0. **Currency.** `sovval.iii` (4 facets) + `uncertainty.iii`; paired-falsifier
   corpus; prove Π8 (base seal unchanged) before anything moves.
1. **Conscience.** Extend `constitution.iii` (falsifier field + temporal kind),
   reuse `constitution_preserver`; `run_charter()`; pin the charter seal in the
   harness; fuse positive/negative/drift/closure gates.
2. **Commons.** Provable forgetting in `witness_spine`; quine-seal via
   `quine_verifier` over src + emitted code.
3. **Anchor.** `kernel.iii` on XII, dispatching to `sat/smt/groebner/egraph`;
   `category.iii` composition laws for `sv_op`; register as clauses.
4. **Gate.** Re-currency `katabasis/*` on SovVal; HEXAD-reject becomes type-level.
5. **Cost & memo.** SovVal cost facet (`cost_lattice`); claim provable memoization
   (`memo_lattice`) as a clause.
6. **Systemwide + repair.** Mandatory `@sovereign` boundaries; wire charter-red →
   quarantine/regen.
- **Frontier (open):** dependent Π-types + universes toward full CIC in `TYPES`.

---

## §10. What III becomes able to do (widened payoff)

Carried from v1: (1) refuse to ship an incoherent self; (2) make bricking
unsayable; (3) attest its running self below the OS; (4) forget with proof; (5)
compute soundly on the unknown; (6) explain its own ignorance; (7) proof-carrying
ordinary computation; (8) be picked up by a second human. **Widened:**

9. **Solve with proof.** SAT/SMT/Gröbner results become Sovereign Values whose
   witness carries the certificate — III doesn't just *find* an answer, it hands
   you a re-checkable proof of it.
10. **Compute under a budget it cannot exceed.** The cost facet makes over-K
    compositions `Refused` by construction — "zero-cost-creativity, physics
    boundary only" becomes a *type rule*, not a guideline.
11. **Guarantee behavior over time.** Temporal clauses let III assert liveness and
    safety of its own evolution, not just instantaneous correctness.
12. **Heal what it detects.** A red verdict triggers quarantine + regeneration —
    the organism not only knows when it is incoherent, it repairs.

> Net: the v1 charter was right and now is *complete to III's actual size*. The
> same two ideas — the Sovereign Value and the Constitutional self-audit — bind
> not 8 organs but the whole body: value, uncertainty, hexad, reversibility,
> proof, witness, gate, **and** the convergence layer (solve, cost, memo, time,
> category), with detection closing into repair. Nothing III does today is lost;
> all of it becomes provable — and the gate that admits this design is III itself.

*Prepared by direct verification of the live substrate (§V) and the
PERFECTION-POC. Every reused module is cited; net-new surface is the unified
uncertainty value, the kernel checker, the SovVal cost facet, and the wiring.
Admissible only if III's seals reproduce.*
