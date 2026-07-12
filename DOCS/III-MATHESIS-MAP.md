# III — THE MATHESIS CREATOR (Ξ, v3): concepts, theorems, and theories from the machine — creation without new axioms

> **STATUS: v3 — THE CREATOR TIER OPENED (2026-07-11; Ξ0 DISCHARGED same day).** v1 located the loop. v2 made
> it mechanically ambitious and Ξ0 closed the seed cycle (MATHESIS-THEOREM-0001 sealed + assimilated +
> measured). v3 answers the ceiling critique honestly and then breaks every ceiling that is belief rather than
> physics: v2's engine could only *find equivalences in a fixed language*. v3 gives the engine the four moves
> by which real mathematics actually grows — **new DEFINITIONS** (conservative extension: vocabulary, never
> axioms — Ξ8), **new STATEMENT KINDS** (order, nonexistence, optimality — all reduced to the one trusted
> judgment — Ξ9), **new PROOF METHODS** (deduction from the library, induction to unbounded quantifiers —
> Ξ10; verified-morphism transport — Ξ11; exact-evidence conjecture — Ξ12), and **its own QUESTIONS** (the
> measured research agenda — Ξ13). The walls that are physics stay walls (B3, Gödel, Richardson,
> transcendentals). The v2 pillars, requirements R1–R7, and phases Ξ0–Ξ7 remain in force below — v3 layers the
> creator tier on top of them, gates 2670–2699. Companions:
> `III-COMPLETION-PLAN.md` (Φ), `III-MEANING-LIFT-MAP.md` (Θ — the semantic witness this campaign consumes),
> `III-GRAND-UNIFICATION-MASTER-PLAN.md` (Ω/Σ — the skeleton this campaign completes),
> `III-GENERATIVE-FRONTIER.md`, `III-EXACT-SUBSTRATE-INTEGRATION.md`,
> `III-CONJECTURE-FACULTY-AND-CAPABILITY-PROOF.md` (the inert proposer this campaign de-inerts),
> `MATH_LIBRARY_QUEUE.md` (the vessel this campaign fills).

---

## 0. The verdict in one paragraph

Λ made III **one verified computer**; Γ a **substrate-independent organism**; Θ gave it **its own meaning as a
first-class object**; Φ closes the **trust-floor residuals**. None of them lets III **enlarge the mathematics
it is built from**. Yet the tree already contains every stage of a discover→prove→assimilate loop — and even
contains the loop itself, hard-wired, at exactly one point: `cg_r3` consults `ser_egraph::seg_mul_plan`
(`cg_r3.iii:236`, emission at `:2652`, gate `2135`), which saturates `x*v`, extracts the cheapest equivalent,
**proves it over all 2⁶⁴**, and returns a byte-faithful emit plan. A second hand-run of the same loop is
fossilised in `COMPILER/BOOT/cg_opt_rules.iii` — "the optimization the synthesizer found that the compiler
lacked" (its own words, at `cgopt_div_admit`) — a **kernel-certified rule family** (admit predicate +
parameter extractor, proven over the full range k=1..63 by `forcefield/cg_opt_cert.iii`), some rules even
**machine-emitted from descriptors** (`seraphyte_emit_rule.sh`, see the `[EMITTED]` stamp at
`cg_opt_rules.iii:87`). **Ξ — THE MATHESIS ENGINE — makes that fossilised process a standing, autonomous,
open-space faculty**: III measures how it compiles itself, conjectures theorem *schemas* it does not yet know,
proves each over the whole domain or honestly abstains, records the proven ones in a sealed replayable
library, emits them back into its own compiler as certified rule TUs, re-verifies meaning with an independent
evaluator, and measures that it got strictly smaller — while the **teach-grammar** of its optimizer climbs,
operator by operator, toward the **prove-algebra** of its own disposer. No famous-open problem claimed; every
discovery individually disposed; every admitted rule earning a measured gate.

**And v3 states the summit above that (the creator thesis).** An engine that only finds cheaper equivalents is
an optimizer wearing a mathematician's coat. What working mathematics actually consists of is four moves —
*define* a concept worth naming, *state* propositions in a growing language, *prove* by composing what is
already proven (not only by re-deciding from raw bits), and *choose* what to work on next — and **none of the
four requires new axioms, statistics, or undecidable territory**. Definitional extension is conservative
(vocabulary grows, the foundation's strength does not); richer statement kinds reduce by construction to the
one judgment the disposer already renders; deduction and induction are kernel-checked composition of sealed
entries; and intent is measured demand, never learned belief. So the creator tier adds **zero trusted
components** while removing the four ceilings the honest critique named: the frozen grammar (Ξ8 mints
concepts — the ISA is frozen, the *language* never was), the finite-only quantifier (Ξ10 proves ∀n∈ℕ by
induction — theorems no enumeration can reach), the single statement form (Ξ9 admits order, nonexistence, and
optimality — lower bounds proven by witness-function circuits), and the intuition ban (Ξ11/Ξ12/Ξ13 mechanize
analogy, empirical conjecture, and intent as *verified transport, exact evidence, and measured value*). III
stops being a system that has mathematics done to it and becomes the thing that does mathematics.

---

## 0a. The conscience verdict this map is written under (honest, up-front)

`iii_math_rigor` on the headline claim — *"III autonomously generates new mathematics and assimilates it as
verified compiler upgrades"*:

| Rung | State today |
|---|---|
| 1 STATEMENT | formalised in §6 (the schema + novelty + cost + witness predicate) |
| 2 HYPOTHESES | enumerated in §5 (R1 dual-disposer … R7 replay-on-disposer-growth) |
| 3 DISCHARGE | **each hypothesis has a real file:line** — `sd_denote` `numera/ser_kinduct_sym.iii:475`, `seq_equiv` `:607`; `seg_mul_plan` consult `cg_r3.iii:2652`; the certified-family mold `cg_opt_rules.iii` + `forcefield/cg_opt_cert.iii` + `STDLIB/scripts/cg_optrules_bind_gate.sh`; the meaning witness `COMPILER/BOOT/eval.iii` (`run_meaning.sh`); the fixpoint `STDLIB/sovir/run_ddc.sh` |
| 4 REALIZATION | **Ξ0 LANDED (2026-07-11)**: the door `numera/mathesis_admit.iii` (gate 2600), the disposer route `corpus/2601` (∀-schemas in one symbolic seq_equiv call + R4 + width tooth + abstain), the instrument `numera/mathesis_measure.iii` (gate 2602, census: 78 AND-chain windows / 55 real modules / stage1=0), the seal `corpus/2603` (MATHESIS-THEOREM-0001 replays from pins), the assimilated fold (`cg_svir.iii` `e_and_chain_fold`, sq08 494→484 bytes, square N≡E≡S green, golden resealed), and `run_mathesis.sh` (the never-built `run_self_improve.sh`, ADR-Ξ5). **CREATOR TIER OPENED (2026-07-12)**: Ξ8 DISCHARGED — the definition door `numera/mathesis_define.iii` (2670), ROTL64 + the whole C₆₄ Cayley table machine-proven (2671: 4160 symbolic proofs + the 49,152-check spec bridge), the rot census class (2672, phantom-armed) rendering the honest INERT verdict (c8=0 everywhere), the seal 2673 (chain genesis→…→`d18e5038…`); Ξ9 OPENED — the first NONEXISTENCE family by the witness-function method (2675: rot_k not 1-op expressible ⇒ 2 ≤ cost ≤ 3); **Ξ1's PROPOSER LIVE — `numera/mathesis_synth.iii` (2610): the whole 18,522-pair declared space swept, 183 MACHINE-SYNTHESIZED ∀-theorems sealed (`DOCS/MATHESIS-SYNTH-ROUND1.log`), 1386 mul-mul pairs frontiered with blocker named, the Ξ0 schema re-derived and REFUSED as non-novel (R3 live)**. Ξ2–Ξ7, Ξ10–Ξ13, 2611/2612/2674 remain |
| 5 FALSIFIER | live and firing: the false identity is REFUTED at 2601/2600; tamper breaks the 2603 seal; the width tooth REFUTES `(x<<32)>>32 ≡ x`; the phantom-const arm defeats byte-grep counting; a meaning change reddens `run_meaning.sh`; a determinism break reddens the fixpoint |
| 6 VERDICT | **Ξ0: DISCHARGED-IN-CODE** (first machine-discovered theorem sealed + assimilated + measured); **Ξ1–Ξ7: STATED-NOT-DISCHARGED** — the map's remaining job |

---

## 1. The gap, measured (v2: sharpened by reading the code)

| Fact (verified against the live tree this pass) | Measure | Consequence |
|---|---|---|
| The disposer's algebra is STRICTLY RICHER than the optimizer's grammar | `sd_denote` proves over {ADD 0x20, SUB 0x21, MUL 0x22, **AND 0x25, OR 0x26, XOR 0x27**, SHL 0x28, **SHR 0x29**, EQ/NE/compares, MUX, bounded loops, byte memory} (`ser_kinduct_sym.iii:506-598`); the e-graph's grammar is {VAR, CONST, ADD, SUB, MUL, SHL} (`ser_egraph.iii:25-30`) | **the gap between what III can PROVE and what III can TEACH ITSELF is four operators wide** — AND, OR, XOR, SHR (MUX behind them). This is the named, measurable open frontier |
| The conjecture faculty is sound but **inert** | XII is Knuth–Bendix-complete → a live-XII consumer is vacuous (`III-CONJECTURE-FACULTY…` §2) | the proposer has no open space — until pointed at the compiler's own algebra |
| The loop exists **fossilised**, run twice by hand | `seg_mul_plan` (e-graph synthesizer → `cg_r3.iii:2652`, sole mul path, gate `2135`); `cgopt_div/mod` ("the optimization the synthesizer found that the compiler lacked") | the mechanism is PROVEN — what is missing is the autonomous, admitted, standing form |
| The certified-rule assimilation mold is live | `cg_opt_rules.iii` (zero-dep, iiis-0-compatible, kernel-proved by `cg_opt_cert.iii`, bound by `cg_optrules_bind_gate.sh`), rules machine-emitted from descriptors (`seraphyte_emit_rule.sh`, `[EMITTED]` stamps) | assimilation = **deterministic source emission**, already proven DDC-safe — Ξ reuses it, does not invent it |
| The iiis-0-parity law binds every new arm | `r3_mod_pow2_mask` fires "ONLY on a CONSTANT pow2 modulus (**absent from stage1_corpus**…), so iiis-0 == iiis-2 on stage1 holds" (`cg_r3.iii:959-962`) | a new emission arm must be **measured no-fire on stage1_corpus** while firing on self-host TUs — MEASURE checks both corpora, by law (R6) |
| The math library is an empty vessel with no admission tactic | `DOCS/MATH_LIBRARY_QUEUE.md`: "No entries committed yet … when the math-library admission tactic is defined" | III proves things but never *records a theorem it discovered* — knowledge does not accumulate |
| Σ never closed | `verified_search/sov_isa/invent/invent_loop/xii_admission` exist; `run_self_improve.sh` does not | `run_mathesis.sh` IS that missing gate, built by Ξ0 |
| Corpus mechanics (for every Ξ gate) | every corpus test MUST be registered in `run_corpus.sh`'s `EXPECTED` map (`:-?` default never matches); tests link `libiii_native.a`; numbers 2500+ free | Ξ gates land at 2600+ with explicit registration |

**The one-sentence discriminator.** Θ answered *"does III's MEANING exist independently of its
implementation?"* Ξ answers *"can III's MATHEMATICS grow — can it originate a true ∀-proposition it did not
have, prove it against the machine, and become a smaller machine for it?"*

**Why this is the pick (Meadows-ranked).** The highest leverage in a system is the rule by which its rules
change. Ξ upgrades that rule from *human-discovered + hand-wired* (the two fossils) to *machine-discovered +
proof-gated + measured + sealed*. Everything below it exists; nothing above it does.

---

## 2. The organ census — each organ IS its role in the loop

| Loop stage | The organ that IS this stage | Verified site | Role in Ξ |
|---|---|---|---|
| **MEASURE** | the census/ratchet instruments + the SVIR emission path | `run_meaning.sh` pipeline (cg_svir → SVIR modules), the coverage ledgers | the sensor: walks REAL self-host SVIR counting collapsible windows by class — **and simultaneously certifies the stage1 no-fire condition (R6)** |
| **CONJECTURE** | the window-miner + anti-unifier + conjecture faculty | `nous/nous_conjecture{,_term,_gen,_lemma}.iii`; the triad `sp_fuzz_det`→`au_*`→`sks_*` | the proposer over the OPEN space (§3), statistic-blind (Ax D3): windows mined by *structure*, schemas by *anti-unification* |
| **GROUND** | the zkVM + sovereign PE + determinism gate | `sovir/zk_svir_vm.iii` (committed GF(p⁴), ~2⁻⁸⁶); kernel32-only PE; core-control | the witness of the electrons: both schema sides run on real silicon; traces zk-attested (Ξ2) |
| **PROVE / ABSTAIN** | the SVIR equivalence prover + CIC kernel + exact ladder | `seq_equiv` `numera/ser_kinduct_sym.iii:607` (1 PROVEN / 0 REFUTED / SEQ_TOP abstain, one shared `bb_reset` so both sides alias the same symbolic inputs); the in-`.iii` kernel `numera/typecheck.iii`+`ccl.iii`; `aether/sqrt_sum_sign.iii` | the disposer: proves the SCHEMA over all 2⁶⁴ assignments of every parameter, or honestly abstains |
| **ADMIT** | the math library + content addressing | `DOCS/MATH_LIBRARY_QUEUE.md` (format: `### <theorem_id>` + canonical statement + tactic); sha256/mhash | the theorem book: sealed, chain-hashed, **replayable** (§3a-P5) |
| **ASSIMILATE** | the certified-rule emission mold | `cg_opt_rules.iii` + `cg_opt_cert.iii` + `seraphyte_emit_rule.sh` + `cg_optrules_bind_gate.sh`; consult sites `cg_r3.iii:952/963/2652` | the teacher: an admitted schema is EMITTED as an iiis-0-compatible certified rule TU + a cg_r3 arm; the compiler never reads the library at compile time (§3a-P3) |
| **RE-VERIFY** | the meaning-lift evaluator + DDC + corpus | `COMPILER/BOOT/eval.iii` (`run_meaning.sh`); `run_ddc.sh` (iiis-2≡iiis-3); `STDLIB/scripts/run_corpus.sh` | the independent conscience: a *different* meaning-bearer confirms the assimilated compiler means the same |
| **RATCHET** | the cost meter + down-only pins | `forcefield/ripple_metric.iii`; `omnia/xii_cost_monotone.iii`; the census ratchets | the scorekeeper: strict measured decrease on real modules, or no assimilation |

**The axioms are the loop's invariants.** Ax D3 (statistic-blind): windows are mined and schemas ranked by
*structure and cost*, never frequency-as-belief; the disposer decides by proof only. The safety algebra is
what the kernel types; the K-chain is what transformation conserves. **Cryptography is the trust fabric**: zk
attestation (GROUND), sha256 theorem ids + mhash-chained library (ADMIT), sealed manifest (ASSIMILATE),
sealed-channel federation (Ξ6) — and also a target domain (Montgomery/NTT identities).

---

## 3. The invention — TWO fixed constraints broken, not one

**Break 1 (v1): "the proposer proposes into XII."** False constraint. The open space is the compiler's own
optimization algebra — `∀ x⃗ ∈ (ℤ/2⁶⁴)ᵏ. ⟦f⟧(x⃗) = ⟦g⟧(x⃗)` over SVIR fragments with arbitrary constants:
infinite signature, not finitely completable, general superoptimization undecidable (the wall, unchased). The
faculty explores freely; each candidate is soundly disposed or abstained. Open space, decidable steps.

**Break 2 (v2, from reading the code): "the assimilation grammar is fixed."** Also false — the grammar is
data. The e-graph teaches {ADD,SUB,MUL,SHL}; the disposer proves over four more operators TODAY. So the
engine's ambition has a *measured shape*:

> **THE GRAMMAR-CLOSURE RATCHET: teach-grammar → prove-algebra.**
> `gap = |ops(sd_denote)| − |ops(assimilable)|` = **4 named operators (AND, OR, XOR, SHR; MUX behind them).**
> Every Ξ round may close part of this gap and may never widen it. The engine's end-state ambition, stated as
> an invariant: **the compiler learns to emit everything its own prover can prove.**

Both breaks resolve the same four blockages at once: the inert proposer (now has room), the empty library
(now has a door, §6), the unclosed Σ (run_mathesis.sh IS run_self_improve.sh), and the human-bound PCC (the
machine originates the proposition; the kernel checks it).

---

## 3a. The five ambition pillars (v2 — each grounded, none rhetorical)

**P1 — THE GRAMMAR-CLOSURE RATCHET.** The TEACH⊆PROVE gap is a first-class, monotone, named ratchet
(`mathesis_ratchet.txt`: operators closed / remaining, schemas admitted per operator). Closing an operator
means: the e-graph (or a certified family) can represent it, ≥1 admitted schema uses it, cg_r3 emits it, and
the full re-verify chain is green. Four operators = four guaranteed-nonvacuous rounds *before* the engine even
needs deeper windows.

**P2 — SCHEMA-FIRST: the library holds ∀-theorems, not facts.** The unit of admission is the **certified rule
family** in the `cg_opt_rules` mold: `(admit predicate, parameter extractor, RHS plan)` + a proof over the
FULL parameter domain. Discharge routes (sharpened by adversarial verification):
  - *Symbolic-schema route* — constants become `seq_equiv` **parameters**: one call proves
    `∀x,c₁,c₂ : (x&c₁)&c₂ ≡ x&(c₁&c₂)` over all 2⁶⁴ assignments of ALL THREE variables. Available exactly
    where `sd_denote` is fully symbolic: {ADD,SUB,MUL,AND,OR,XOR} in any position, shifts in *value*
    position. **Restriction (S1, binding):** a parameter may NOT sit in a shift-COUNT position (`sd_denote`
    requires constant shift counts — `ser_kinduct_sym.iii:512-513`).
  - *Range-sweep route* — shift-count-parametric families discharge per-instance over the ENTIRE admissible
    range (the `cg_opt_cert` k=1..63 discipline): every instance proven, the family admitted as a schema with
    its range quantifier. Not sampling — exhaustion of the declared domain.
  - A schema proof is pinned to its width (R2): width-indexed re-proof (`bb_reset(w)` at 8/16/32/64) turns
    each schema into an honest width-family; only proven widths enter the quantifier.

**P3 — ASSIMILATION = DETERMINISTIC SOURCE EMISSION (the Path-C mold, generalised).** An admitted schema is
emitted — by `run_mathesis.sh`, deterministically, stamped like `seraphyte_emit_rule.sh`'s `[EMITTED …]`
rules — as source in a **new, mathesis-authored, iiis-0-grammar-compatible certified rule TU**
(`COMPILER/BOOT/cg_mathesis_rules.iii`: zero-dep, integer-only, the first compiler source file authored by the
loop), plus a `cg_r3` consult arm in the `r3_mod_pow2_mask` mold. The emitted source is **committed**; the
compiler never reads the library at compile time — so determinism and the DDC fixpoint are preserved *by
construction* (iiis-2 and iiis-3 both carry the arm and emit identically; the C seed stays frozen).
**R6 (binding):** the arm must be measured **no-fire on stage1_corpus** (the iiis-0≡iiis-2 parity surface) —
exactly how magic-div and mod-mask landed — while firing on self-host TUs (the measured win).

**P4 — MEASURE-FIRST: no hand-picked seeds, anywhere, including Ξ0.** The loop's first act is to look: the
MEASURE instrument walks real self-host SVIR counting collapsible windows by class; the top measured class IS
the seed schema. The same instrument certifies R6 (stage1 no-fire) and supplies the USEFUL clause's baseline.
A schema with zero real occurrences is catalogued, never assimilated (anti-bloat) — vacuity is made visible,
not papered over.

**P5 — THE LIVING LIBRARY.** Four properties beyond a log:
  - **Replayable**: every sealed entry carries statement + tactic + witness chain sufficient to RE-RUN the
    proof; `run_mathesis.sh --replay` re-proves the whole library from scratch. The library is a re-executable
    proof corpus, not a claim ledger.
  - **The frontier is a queue, not a graveyard**: SD_TOP abstentions are catalogued WITH their blocker
    (`shift-count-param`, `loop-shape`, `symbolic-address`, `width`); when the disposer grows, the frontier
    auto-retries.
  - **Disposer growth is a gated event (R7)**: any strengthening of the disposer (new opcode, new loop shape)
    must first RE-REPLAY the entire admitted library green before any new admission uses it — the prover may
    not drift under the theorems it once proved.
  - **The monograph**: `--report` renders the sealed library human-readable (statement, proof route, witness
    roots, measured effect) — III publishes its mathematics.

---

## 3b. THE CREATOR BREAKS (v3) — four ceilings, each shown to be belief, not physics

The external ceiling critique of v2 was accurate about v2. Quoted fairly, it said: *(C1)* "it can never
invent the concept of population count — it cannot invent abstractions, only arrange fixed operators";
*(C2)* "it is trapped in the discrete and finite — it does not have the language for universal mathematics";
*(C3)* "its only trick is proving A≡B — it finds equivalences, not new kinds of statements"; *(C4)* "without
statistical intuition the structural search drowns — Ax D3 is its greatest weakness." v3 breaks all four
**with organs already in the tree**, and concedes exactly what is physics:

**BREAK C1 — THE DEFINITION DOOR (Ξ8): the ISA is frozen; the language never was.** Mathematics has always
grown by *conservative definitional extension*: name a recurring structure, prove its characterizing laws,
then reason at the concept level — no new gate was ever added to reality when humans defined "group." A
minted concept is a library DEFINITION entry: a name-hash, an arity, an SVIR **definiens**, a **spec bridge**
(the definiens proven to agree with an independent abstract specification — e.g. rotation's bit-permutation
semantics), and ≥1 **proven law about it** (a lawless definition is a macro and is REFUSED — the concept-tier
anti-bloat clause). Conservativity means the door adds zero trust: every concept unfolds away. The first
minted concept is **ROTL64** — `rot_k(x) := (x<<k)|(x>>(64−k))` — absent from the ISA, absent from the
e-graph grammar, latent in every crypto inner loop the tree owns; its law family (identity, inverses, the
homomorphism `rot_a∘rot_b ≡ rot_{(a+b) mod 64}`) is the machine constructing and verifying **the cyclic
group C₆₄ acting on its own word type** — the direct, executable refutation of "it cannot invent
abstractions." POPCNT and its SWAR laws follow the same door when the census demands them.

**BREAK C2 — THE UNBOUNDED QUANTIFIER (Ξ10): induction reaches where enumeration cannot.** v2's PROVEN meant
finite discharge (symbolic 2⁶⁴ or exhausted ranges). But the tree already holds a k-induction engine
(`ser_kinduct_sym.iii` — it is in the *name*), a live CIC kernel (`numera/typecheck.iii`+`ccl.iii`, judging
program arithmetic since gate 2498), and a lemma-discovery organ (`nous_conjecture_lemma`). The deduction
organ composes **admitted entries** into new theorems by rewriting and by induction over ℕ-parameters — base
and step each discharged by the finite engines, the composition checked by the kernel, ground instances
spot-re-verified at the bit level (the two-path law). First unbounded citizens: the n-fold const-chain
`∀n≥2` (THEOREM-0001 as the inductive step) and `∀n∈ℕ: rot_1ⁿ ≡ rot_{n mod 64}` (the homomorphism law as the
step). These are **∀-statements over an infinite domain** — the first entries no enumeration could ever have
produced, and the moment the library stops being a list and becomes a *theory*.

**BREAK C3 — THE STATEMENT LATTICE (Ξ9): new statement kinds, the same one judge.** The reduction law
(binding): a statement kind may enter the library **only** by exhibiting its reduction to the standing
trusted judgment — *predicate-as-circuit ≡ const-1* through `seq_equiv`, or kernel-checked composition of
sealed entries. Under that law the language grows without the judge widening: **order theorems** (the
Boolean-lattice order `a ⊑ b :⇔ a&b ≡ a`, equationally; signed-order facts through the 0x32–0x35 compare
fragment — the compare *bit* proven ≡ 1); **NONEXISTENCE theorems by the witness-function method** — to prove
"no program of shape S(c) computes t," exhibit a witness circuit `w(c)` (mux on the special constants; total
by construction) and prove the single ∀c-statement `[S(c)(w(c)) ≠ t(w(c))] ≡ 1` — an ∀∃ lower bound
**reduced to one symbolic equivalence call**; and **OPTIMALITY certificates** — a matched admitted upper form
plus a proven lower bound closes a problem *forever* (`t requires exactly n ops in grammar G`): the Strassen
shape, machine-proven end to end, and the engine's negative knowledge feeds anti-bloat (a proven-irreducible
window is exempt from all future search — the engine now knows *why not*).

**BREAK C4 — MECHANIZED INTUITION (Ξ11/Ξ12/Ξ13): structure and measurement, never belief.** The critique
assumed intuition must be statistical. Three statistic-clean intuition engines refute that: **analogy as a
verified functor** (Ξ11) — the rot group acts on theorems by conjugation, so one proof spawns its whole
symmetry orbit, each instance transported along a *proof-carrying map*, and width-truncation morphisms carry
bit-parallel laws across widths structurally; **the empirical telescope** (Ξ12) — Ramanujan mode on the exact
substrate: enumerate nested-radical families inside the decidable envelope, decide candidate coincidences
EXACTLY (the agreement web `Sturm ≡ Σ√ ≡ tower` is a decision procedure, not an approximation), and every
detected coincidence becomes a conjecture the exact disposer proves or refutes — machine-found **denesting
theorems** (the `√(3+2√2) = 1+√2` class); **intent as measured value** (Ξ13) — the agenda orders open work by
measured census demand × cost-delta potential × consumer KAT impact, every choice logged with its
measurement. Ax D3 stands untouched: nothing anywhere ranks by frequency-as-belief.

**What v3 still refuses to claim (the physics).** No new logics; no self-consistency claim (Gödel); no
famous-open problems (B3, pre-registered); no transcendental zero-testing (Richardson); no completeness of
any rule set or of the library; and **the conservativity law**: any candidate whose admission would require a
new *axiom* (not a definition, not a theorem) is REFUSED as a B3-class event. The creator grows vocabulary,
theorems, methods, and questions — never foundations. That is not the ceiling the critique thought it was;
it is how Bourbaki grew mathematics too.

---

## 3c. The v3 ambition pillars P6–P10 (layered on v2's P1–P5)

**P6 — CONCEPTS ARE BUNDLES, NOT NAMES.** A DEFINITION admits only as
`(definiens, spec-bridge proof, ≥1 proven law, census measurement, chain witness)` — the door's concept-tier
conjunction `SPEC-BRIDGED ∧ LAW-RICH ∧ MEASURED ∧ WITNESSED`. Zero-law concepts REFUSED; zero-occurrence
concepts admit on law-richness but are *marked inert* (assimilation stays closed until a consumer measures).

**P7 — THE REDUCTION LAW.** Every statement kind reduces to the standing judgment (circuit ≡ const /
`seq_equiv` verdict / kernel-checked composition). One judge, forever; N statement kinds; zero new provers.

**P8 — DERIVATION IS CHEAPER THAN DECISION.** The deduction organ prefers composing sealed entries (kernel
work, milliseconds) over re-deciding from raw bits (bb work); the bit-level engine remains the arbiter via
mandatory ground-instance spot checks. Knowledge accumulating = proofs getting *cheaper* over time — the
measurable signature that the library is a theory, not a cache.

**P9 — EVERY THEOREM CARRIES ITS ORBIT.** Admission computes the statement's symmetry class under the
verified transport maps (rot conjugation, width functors): the orbit is stored, not re-proved; a theorem's
id names its class representative. One proof, sixty-three siblings, zero extra trust.

**P10 — THE AUTONOMY INVARIANT (binding, gated).** The transitive process tree of
`run_mathesis.sh --standing` contains ONLY sovereign-built binaries + POSIX sh — no LLM, no network, no
operator, anywhere, ever. The engine is a program, not a prompt; a bare clone + one command reproduces the
entire library from genesis. (This was already true of Ξ0; v3 makes it a gated law — gate 2682.)

---

## 4. The unified architecture — the closed engine

```
      ┌───────────────────────────── THE MATHESIS ENGINE (Ξ v2) ──────────────────────────────┐
      │                                                                                         │
 ┌────┴─────┐ windows by class ┌──────────────┐ schema f(c⃗)≡g(c⃗) ┌───────────────┐ run both   │
 │ MEASURE  ├─────────────────►│  CONJECTURE  ├──────────────────►│    GROUND     │ on silicon │
 │ real SVIR│ (self-host TUs;  │ window-miner │ (∀-quantified,    │ zkVM + core-  │ zk-attest  │
 │ walk     │  stage1 no-fire  │ + anti-unify │  width-pinned)    │ control + det │ (Ξ2)       │
 └──────────┘  certified: R6)  └──────┬───────┘                   └───────┬───────┘            │
      ▲                               │ statistic-blind (Ax D3)           │ witnessed          │
      │ measured strict decrease      ▼                                   ▼                    │
 ┌────┴─────┐                  ┌──────────────┐  admit iff        ┌───────────────┐            │
 │ RATCHET  │◄─────────────────┤ PROVE/ABSTAIN│  PROVEN ∧ NOVEL   │ DUAL DISPOSER │            │
 │ + grammar│                  │ seq_equiv    │  ∧ USEFUL         │ (kernel/brute │            │
 │ closure  │                  │ (symbolic or │  ∧ WITNESSED      │ /exact web) + │            │
 └────┬─────┘                  │ range-sweep) │◄──────────────────┤ eval witness  │            │
      │                        └──────┬───────┘  else frontier    └───────────────┘            │
      │ census up-ratchet             │ theorem schema             (queue, blocker named)      │
 ┌────┴─────┐                  ┌──────▼───────┐ EMIT source      ┌───────────────┐ eval.iii ≡  │
 │ RE-VERIFY│◄─────────────────┤ ADMIT sealed ├─────────────────►│  ASSIMILATE   │ DDC fixpoint│
 │ eval+DDC │ meaning unchanged│ replayable   │ [EMITTED] rule TU│ cg_mathesis_  │ corpus green│
 │ +corpus  │ determinism held │ library      │ + cg_r3 arm      │ rules.iii     │ no-fire ✓   │
 └──────────┘                  └──────────────┘ (committed src)  └───────────────┘             │
      └─────────────────────────────────────────────────────────────────────────────────────────┘
 THREE-ORGAN SEPARATION: PROPOSER (miner/nous) ≠ DISPOSER (seq_equiv/kernel/Σ√) ≠ MEANING-WITNESS (eval.iii).
 GATE OVER EVERYTHING: run_mathesis.sh — one command; every stage a positive proof + a rejecting negative arm.
```

**Load-bearing edge:** the disposer (unchanged from v1 — weak disposer = safe abstention; unsound disposer =
poison; hence R1). **The flywheel:** each assimilated schema changes cg_r3's output → changes what MEASURE
sees → changes what CONJECTURE mines. Anti-thrash: H10 origin certificates + the grammar ratchet is
append-only (operators never leave).

---

## 5. The seven hard requirements (binding at every gate)

- **R1 — DUAL DISPOSER.** No admission on one prover's word: `seq_equiv` over 2⁶⁴ AND a second independent
  check (kernel proof term via `tc_check`, exhaustive small-width brute, or the exact agreement web
  `Sturm ≡ Σ√ ≡ tower`). A wrong "equal" is the one unrecoverable outcome.
- **R2 — EVERY SCHEMA CARRIES ITS DOMAIN QUANTIFIER.** Width + signedness pinned in the statement and the
  hash; parameter ranges explicit (`k ∈ 1..63`, `c₁,c₂ ∈ ℤ/2⁶⁴`); the disposer discharges at the stated
  width; the arm fires only inside the quantifier. Exact-domain: rank + magnitude envelope, else abstain.
- **R3 — THE NOVELTY GATE.** Reject what the current rule set already derives (e-graph saturation at pinned
  depth + the cgopt admit predicates). Rediscovery is XII-vacuity; admit only the unreached.
- **R4 — RED-FIRST FALSE-IDENTITY ARM at every gate.** Canonical: `a+b ≡ a|b` must be REFUTED (0, not
  SEQ_TOP) everywhere a true schema is PROVEN. The negative arm is built before the positive.
- **R5 — THE DDC FIXPOINT ABOVE CLEVERNESS.** `iiis-2 ≡ iiis-3` byte-identity re-asserted after every
  assimilation; a sound rule that breaks byte-determinism is rejected.
- **R6 — THE PARITY LAW (v2, from the mod-mask precedent).** Every new emission arm is measured **no-fire on
  stage1_corpus** (the iiis-0≡iiis-2 surface, `build_iiis2.sh --check-corpus`) and **fire>0 on self-host TUs**
  (else it is bloat). The C seed is frozen; new-arm TUs are iiis-0-grammar-compatible; compiler TUs pre-flight
  under BOTH iiis-0 and iiis-2 before landing.
- **R7 — REPLAY ON DISPOSER GROWTH (v2).** Strengthening the disposer requires `--replay` of the entire
  sealed library green FIRST; then the frontier auto-retries. The prover never drifts under its own theorems.

---

## 6. The admission tactic — the library door, schema-level

A discovered schema `S = (pattern f(x⃗,c⃗), replacement g(x⃗,c⃗), quantifier Q)` is **admissible** iff
`Ξ_ADMIT(S) = PROVEN ∧ NOVEL ∧ USEFUL ∧ WITNESSED`:

```
STATEMENT (canonical, content-addressed):
    theorem_id = sha256( canon_serialise(f) ‖ "≡" ‖ canon_serialise(g) ‖ Q )
    where canon_serialise = preorder walk of the schema descriptor (ops, param slots, const slots)
    and Q = width_tag ‖ signedness_tag ‖ per-parameter ranges.  α-equivalent schemas collapse to one id.

PROVEN    : symbolic-schema route (one seq_equiv call, constants-as-parameters — §3a-P2), OR
            range-sweep route (every instance over the declared range), never SD_TOP     [R1 primary]
          ∧ second_disposer(S) = PROVEN                                                  [R1 dual]
NOVEL     : the current rule set does not already derive S (e-graph saturation at pinned
            depth + cgopt admit predicates return no-plan on S's pattern)                [R3]
USEFUL    : cost(g) < cost(f) strict (op-count/J), AND measured occurrences on self-host
            SVIR > 0, AND stage1_corpus occurrences = 0                                  [RATCHET + R6]
WITNESSED : { the proof object (route + parameters), the discovering build's mhash,
              zk-attested silicon traces of both sides (from Ξ2 on) }                    [crypto fabric]
```

On admission the entry appends to the sealed library exactly per `MATH_LIBRARY_QUEUE.md` format
(`### <theorem_id>` + canonical statement + discharging tactic) **plus** the witness-chain hash; the file is
mhash-chained (`H_i = sha256(H_{i-1} ‖ entry_i)`) — append-only, tamper-evident, **replayable** (P5).
Sound-but-known → rejected (vacuity). Sound-but-useless → catalogued, never assimilated (bloat).
Unprovable → the frontier queue with its blocker named. *"More complete mathematics," honestly:* strictly
more proven schemas, monotone, frontier always printed — never a completeness claim.

---

## 7. The phased plan Ξ0 → Ξ7

Each phase: objective · verified state · gap · tasks (files + gates) · acceptance · falsifier. No phase
closes without RED→GREEN + rejecting negative arms + R1–R7.

### Ξ0 — THE SEED CYCLE: close the engine ONCE, measure-first, end-to-end
**Objective.** The smallest complete traversal, in the loop's own order: MEASURE real self-host SVIR → the
data picks the seed schema → dispose (dual) → admit through the §6 door → assimilate by source emission →
re-verify (corpus + DDC + meaning) → measure the strict decrease. Builds `run_mathesis.sh`, the admission
tactic, and the library; de-inerts the proposer.
**Tasks.**
- Ξ0-T1 — `STDLIB/iii/numera/mathesis_admit.iii`: the §6 predicate + `mathesis_theorem_id` (canonical
  serialise + sha256) + chain hashing + chain verifier. *Gate:* corpus `2600_mathesis_admit` — the four
  clauses individually FALSE ⇒ rejected (four negative arms); tamper breaks the chain; ids are
  deterministic + statement-sensitive. Registered in `build_stdlib.sh` + `EXPECTED[…]=99`.
- Ξ0-T2 — the MEASURE instrument: walk real self-host SVIR (the cg_svir path) counting collapsible const-chain
  windows by class (AND/OR/XOR-chain, SHL/SHR-chain, SHR-SHL align, SHL-SHR mask); same walk over
  stage1_corpus SVIR certifies R6. *Gate:* `2602_mathesis_measure` — counts are deterministic, non-zero on a
  seeded body, zero on a clean body; the emitted census names the seed class. The top measured class IS Ξ0's
  schema — no hand-pick.
- Ξ0-T3 — dispose: corpus `2601_mathesis_dispose` — the seed schema's SVIR bodies (constants-as-parameters)
  through `seq_equiv` ⇒ 1 PROVEN; **R4** `a+b ≡ a|b` ⇒ 0 REFUTED; an undenotable body ⇒ SEQ_TOP lands on the
  frontier, never admits (the honest-abstain arm). Dual disposer: exhaustive brute at width 8 (all 2²⁴
  assignments of 3 bytes) as the second engine.
- Ξ0-T4 — assimilate: emit the admitted schema as `COMPILER/BOOT/cg_mathesis_rules.iii` (`[EMITTED]`-stamped,
  zero-dep, iiis-0-compatible) + the `cg_r3` consult arm (the `r3_mod_pow2_mask` mold); pre-flight the TU
  under BOTH iiis-0 + iiis-2; rebuild stdlib→iiis1→iiis2→iiis3; `--check-corpus` (R6), `run_corpus.sh` FAIL=0,
  `run_ddc.sh` fixpoint (R5), `run_meaning.sh` non-regressing. A 2135-style encode→emit soundness gate
  (`2603_mathesis_emit`) emulates the arm's decoded semantics against direct computation.
- Ξ0-T5 — `STDLIB/sovir/run_mathesis.sh`: one command orchestrating T1–T4 + the sealed library append + the
  measured strict decrease on a real module (op-count/bytes before vs after), + every negative arm.
**Acceptance.** `run_mathesis.sh` exit 0: one ∀-schema in the sealed library, one emitted rule TU cg_r3
consults, all chains green, a measured real reduction. **Falsifier.** The false identity anywhere ⇒ REFUSED;
meaning mutation ⇒ `run_meaning.sh` red; determinism break ⇒ DDC red; stage1 fire ⇒ `--check-corpus` red.

### Ξ1 — THE OPEN PROPOSER: autonomous schema generation over the ℤ/2⁶⁴ algebra
**Objective.** Replace Ξ0's single measured class with the standing miner: harvest N-opcode windows from real
SVIR; anti-unify surviving-equal structural mutations into ∀-schemas (`au_*` + `nous_conjecture_gen/_lemma`);
novelty-filter (R3); dual-dispose; frontier the rest. *Gates:* `2610_mathesis_propose` (re-derives a known
schema + emits ≥1 novel one; a frequency-ranked proposer is a build-time reject — Ax D3), `2611_mathesis_novel`
(a current cgopt/e-graph rule is rejected as non-novel), `2612_mathesis_frontier` (unprovable ⇒ queued with
blocker, count printed). **Falsifier:** a non-novel schema in the library reddens 2611.

### Ξ2 — THE GROUNDING: every theorem bound to witnessed silicon execution
**Objective.** Both schema sides compiled and run on the sovereign PE under core-control + determinism across
the disposer's witness vector; traces zk-attested (`zk_svir_vm.iii`); attestation roots fold into WITNESSED.
*Gates:* `2620_mathesis_ground` (honest traces agree + attest; a forged/tampered trace is REJECTED),
determinism binding (two runs byte-identical; a perturbed run reddens). **Falsifier:** tampered trace ⇒ not
admitted.

### Ξ3 — THE EXACT FACE: new mathematics in the Σ√ / bounded-rank / 4D domain
**Objective.** The engine's second domain: discover exact-sign tier-shortcuts and separation-bound theorems
(the `2157`/`2159` *family*, machine-grown), disposed by the agreement web (`Sturm ≡ Σ√ ≡ tower`, R1's exact
form), abstaining out-of-envelope (R2), with a live geometry/physics consumer whose decision changes.
*Gates:* `2630_mathesis_exact` (a true shortcut admits; a wrong one fails the 19/39 overflow set ⇒ REFUSED),
consumer re-green + float-divergence proof. **Falsifier:** magnitude guard removed ⇒ overflow regression red.

### Ξ4 — THE LIBRARY LIVES: kernel-checked, queryable, replayable, published
**Objective.** Every entry carries a kernel proof term (`tc_check`) as the upgraded R1 dual; dedup by
theorem_id; provenance chain; `--replay` re-proves everything from the sealed entries alone; `--report`
renders the monograph; seal to `MATH_LIBRARY_QUEUE_V1_SEALED.md` per its charter. *Gates:*
`2640_mathesis_certify` (flawed/wrong-spec term ⇒ REJECTED), `2641_mathesis_library` (duplicate folded; tamper
breaks the chain; replay green from a cold start). **Falsifier:** an unchecked term in the sealed library ⇒
2640 red.

### Ξ5 — THE STANDING ENGINE: rounds until dry, the grammar ratchet climbing
**Objective.** `--standing`: repeat MEASURE→…→RATCHET until K dry rounds; each round may close ≥0 grammar-gap
operators (P1: AND, OR, XOR, SHR, then MUX); H10-stamp every assimilated rule (never un-done); the aggregate
ratchet `{schemas_in_library ↑, ops_gap ↓, selfhost_cost ↓}` is down/up-only pinned. *Gates:*
`2650_mathesis_loop` (≥M measured improvements then convergence; the H10 arm proves no revert),
`2651_mathesis_ratchet` (deleting a theorem, widening the gap, or regressing cost reddens). **Falsifier:**
oscillation ⇒ 2650 red.

### Ξ6 — FEDERATION: mathematics propagates by proof, never by trust
**Objective.** Theorem bundles `{id, statement, proof term, witness chain}` ship over the sealed channel
(x25519+ChaCha20-Poly1305); receivers re-run `tc_check` + the zk verifier before adopting; 2f+1 ML-DSA BFT
quorum canonicalises. *Gates:* `2660_mathesis_federate` (honest adopted; forged REJECTED), quorum arms (f=1
tolerated, f=2 rejected). **Falsifier:** a peer adopts an unverified bundle ⇒ 2660 red.

### Ξ7 — THE SEAL: fold into completion; trust-neutral; the end certificate
**Objective.** `run_mathesis.sh --standing` joins `run_completion.sh`; `DOCS/III-TCB.md` extended with the
zero-new-trust argument (proposer untrusted-checked; disposer/kernel/zkVM already in the TCB);
`run_mathesis_tcb.sh` asserts every sealed theorem has kernel term + zk witness + novelty proof;
`MATHESIS_CERT = sha256(library_root ‖ emitted_rules_root ‖ selfhost_cost ‖ ddc_fixpoint_mhash)` —
reproducible, tamper-sensitive. **Falsifier:** a theorem missing any leg reddens the TCB gate; any
perturbation changes the cert.

---

## 7b. THE CREATOR TIER Ξ8 → Ξ13 (v3; gates 2670–2699)

**v3 execution order.** The creator tier does not wait behind Ξ1–Ξ7: Ξ8→Ξ9 run first (they change what the
Ξ1 proposer can even *say*), then Ξ1 proposes over the concept-enriched language, then Ξ10→Ξ11→Ξ12, with
Ξ2 (zk grounding) and Ξ13 folding into Ξ5's standing engine and Ξ6/Ξ7 sealing last. Every phase keeps the
v2 skeleton: objective · verified state · gap · tasks (files + gates) · acceptance · falsifier, R1–R7 + the
reduction/conservativity/autonomy laws binding throughout.

### Ξ8 — THE DEFINITION DOOR: the language grows (concept minting) ← IN EXECUTION
**Objective.** The library admits DEFINITIONS under the concept-tier door
`SPEC-BRIDGED ∧ LAW-RICH ∧ MEASURED ∧ WITNESSED` (P6); the first minted concept is ROTL64 with its C₆₄ law
family — the executable refutation of "it cannot invent abstractions."
**Verified state.** The chain is entry-kind-agnostic (`mx_entry_hash`→`mx_chain_step`); `sd_denote` covers
the full rot fragment (shift counts constant, saturating at 64 — `ser_kinduct_sym.iii:512-513`); locals
0x10/0x11 let a rot compose with itself; the 2601 mold drives thousands of `seq_equiv` calls in one gate.
**Gap.** No DEFINITION descriptor kind; no concept door; no rot census class; no concept seal.
**Tasks.**
- Ξ8-T1 — `STDLIB/iii/numera/mathesis_define.iii`: the MXD1 **concept descriptor** (name-hash, arity,
  definiens shape, width, k-range) + the MX02 **concept-law theorem descriptor** (concept id + law kind +
  law parameters) + validity + canonical serialise + content-addressed ids; the concept-tier door
  `mxd_admit(spec_bridged, law_rich, measured, witnessed)` strict-1 conjunction; chain reuse from
  `mathesis_admit`. *Gate:* `2670_mathesis_define` — malformed descriptors get NO id; a law descriptor
  referencing an invalid concept id is REJECTED; a **lawless definition is REJECTED** (the macro arm);
  ids deterministic + statement-sensitive; the concept chain extends without disturbing the 0001 head.
- Ξ8-T2 — THE ROT CONCEPT through the real disposer, R4-first: the **false law**
  `rot_a(rot_b(x)) ≡ x  at a+b=63` must be REFUTED before anything positive; the **spec bridge** — the
  definiens agrees with the independent bit-permutation semantics (bit i of rot_k(x) = bit (i−k) mod 64 of
  x) natively over all k × a diverse vector (engine 2, R1 dual); **identity** `rot_0 ≡ x` (1 call);
  **inverses** `rot_k∘rot_{64−k} ≡ x`, k=1..63 (63 calls); **the homomorphism**
  `rot_a∘rot_b ≡ rot_{(a+b) mod 64}` over ALL (a,b) ∈ 0..63² (4096 calls — exhaustion of the declared
  domain, not sampling). *Gate:* `2671_mathesis_rot`. EXIT=99.
- Ξ8-T3 — the census learns the concept's shape: `mathesis_measure` gains the opcode-synchronous rot-window
  class (`[0x10 s][0x01 a][0x28][0x10 s][0x01 b][0x29][0x26]`, same slot, a+b=64) + the phantom-const
  negative arm (a byte-perfect fake window inside a CONST immediate must count ZERO). *Gate:*
  `2672_mathesis_rot_census`; the corpus-wide run prints the real occurrence count + the stage1 no-fire.
- Ξ8-T4 — the seal: MATHESIS-CONCEPT-0001 (ROTL64: definiens + spec-bridge + laws) and
  MATHESIS-THEOREM-0002/0003/0004 (homomorphism family / identity / inverses) appended to
  `MATH_LIBRARY_QUEUE.md`, chain extended from the 0001 head. *Gate:* `2673_mathesis_concept_seal` —
  descriptors re-hash to the pinned ids; the chain replays genesis→…→new head; tamper breaks it.
  `run_mathesis.sh` gains the `--concepts` stage.
**Acceptance.** All four gates green with negative arms firing; the library holds its first DEFINITION and
first theorems-about-a-concept; the C₆₄ Cayley homomorphism verified whole. **Falsifier.** A lawless
definition admitted ⇒ 2670 red; the false law proven ⇒ 2671 red; a phantom window counted ⇒ 2672 red;
tamper ⇒ 2673 red. **No compiler TU is touched in this phase** (rot has no cheaper in-ISA form — see Ξ9's
lower bound — so anti-bloat correctly keeps assimilation closed; the phase's value is the language).

### Ξ9 — THE STATEMENT LATTICE: order, nonexistence, optimality
**Objective.** New statement kinds under the reduction law (P7): order theorems, witness-function
nonexistence theorems, optimality certificates.
**Tasks.**
- Ξ9-T1 — order theorems: the lattice order equationally (`x&m ⊑ x` as `(x&m)&x ≡ x&m`, one symbolic call)
  and signed-order facts via the compare fragment (`∀x: (x & 0x7FF…F) ≥s 0` — the 0x33 bit proven ≡ const
  1). R4-order arm: `∀x: x ≥s 0` must be REFUTED. *Gate:* `2674_mathesis_order`.
- Ξ9-T2 — THE FIRST NONEXISTENCE THEOREMS: for k∈1..63, op∈{ADD,SUB,MUL,AND,OR,XOR}:
  `∀c ∃x: (x op c) ≠ rot_k(x)`, proven as ONE symbolic call per (op,k) — the witness circuit `w(c)` (mux on
  the special constant, total by construction) with the NE-bit proven ≡ 1. SHL/SHR excluded per-count over
  the saturating range c∈0..64 (the semantics' own clamp exhausts the behaviour classes). R4 arm: the
  method must FAIL on a *satisfiable* claim (a shape that DOES compute the target must yield NOT-PROVEN).
  *Gate:* `2675_mathesis_nonexist`. Corollary sealed with Ξ8's definiens: **rot_k requires ≥2 ALU ops** —
  the library's first negative knowledge; the 2-op frontier is the standing engine's named next rung.
- Ξ9-T3 — optimality certificates as first-class entries (upper form id + lower bound id ⇒ CLOSED-OPTIMAL
  marker); proven-irreducible census classes become search-exempt (measured search savings printed).
**Acceptance.** ≥3 statement kinds live in the library, each with a rejecting negative arm; the first
nonexistence family sealed. **Falsifier.** A witness circuit with a hole cannot exist by construction (mux
totality); the R4 satisfiable arm proves the method refuses false nonexistence; an order claim whose bit is
not constant-1 lands REFUTED/frontier, never admitted.

### Ξ10 — THE DEDUCTION ORGAN: theorems from theorems; ∀n∈ℕ
**Objective.** New entries proven by composing sealed entries — rewriting with library equations, induction
over ℕ-parameters — kernel-checked (`tc_check`), ground-instance spot-verified (two-path law, P8).
**First derived theorems.** `∀n≥2`: the n-fold const-chain collapse (THEOREM-0001 as step);
`∀n∈ℕ: rot_1ⁿ ≡ rot_{n mod 64}` (THEOREM-0002 as step) — the library's first unbounded quantifiers.
**Gates.** `2676_mathesis_derive` (a valid derivation admits; citing a tampered/absent entry REJECTED; a
conclusion failing its bit-level ground spot check REJECTED); `2677_mathesis_induct` (base+step+conclusion
checked; a step-gap arm reddens). **Falsifier.** A derivation from a deleted premise ⇒ 2676 red; induction
with an unproven step ⇒ 2677 red.

### Ξ11 — SYMMETRY TRANSPORT: one proof, an orbit of theorems
**Objective.** Verified structure-preserving maps as theorem transporters (P9): rot-conjugation orbits over
the bit-parallel fragment; width-truncation functors 64→32/16/8. Equivariance is a checked precondition —
statements bearing shift counts or width-crossing constants are REFUSED transport (the negative arm), the
width-64 tooth `(x<<32)>>32 ≢ x` pinned as the non-transportable witness. **Gates.** `2678_mathesis_orbit`
(transport + spot-verify; non-equivariant REFUSED), `2679_mathesis_width` (a width-64 truth does NOT
transport downward unchecked; the functor direction enforced). **Falsifier.** A transported instance whose
spot check fails ⇒ red; the tooth transported ⇒ red.

### Ξ12 — THE EMPIRICAL TELESCOPE: machine-found denesting theorems (the exact face, armed)
**Objective.** Ramanujan mode on the decidable exact substrate: enumerate structured nested-radical
families (rank ≤ 3, the 19/39 magnitude envelope); detect candidate equalities EXACTLY (the agreement web
IS the decision procedure); every coincidence → conjecture → the exact disposer proves or refutes →
machine-found **denesting theorems** (`√(a+2√b) = √m+√n` classes and beyond) sealed with dual-web receipts.
Subsumes v2-Ξ3 (which had the disposer but no discovery engine). **Gates.** `2680_mathesis_denest` (a
seeded known denesting re-discovered end-to-end; a proven-non-denestable radical lands frontier, never
library), `2681_mathesis_envelope` (out-of-envelope ABSTAINS; guard removed ⇒ the overflow regression
reddens). **Falsifier.** A wrong denesting must be REFUTED by the web's second member; envelope breach ⇒
red.

### Ξ13 — THE RESEARCH AGENDA: intent, the standing creator, no operator anywhere
**Objective.** The engine chooses its own next problem by measured value: agenda = frontier queue ∪
grammar-gap operators ∪ census hot classes ∪ consumer KAT inner loops, ordered by measured cost-delta
potential; every choice logged with its measurement (auditable intent, Ax D3-clean). `--standing` runs the
full creator loop (define / state / deduce / transport / telescope as rounds) to K-dry convergence; the
aggregate ratchet gains `{concepts ↑, statement kinds live ↑, unbounded theorems ↑}`. **THE AUTONOMY
INVARIANT gated (P10):** `2682_mathesis_autonomy` — the process-tree audit (sovereign binaries + sh only) +
a bare-clone cold-start replay reproduces the library from genesis; `2683_mathesis_agenda` — the agenda
ordering is reproducible from the printed measurements (a shuffled agenda reddens). **Falsifier.** Any
non-sovereign process in the tree ⇒ 2682 red; an agenda choice without its measurement ⇒ 2683 red.

---

## 8. Flagship theorem targets (v2 — honest about what is already taken)

Already fossilised (NOT novel, the novelty gate rejects them): mul-by-constant plans (`seg_mul_plan`),
div-by-pow2 + magic division (`cgopt_div_*`, `seg_div_plan`), mod-by-pow2 (`cgopt_mod_*`), shift-const,
identity elements (`x*1`, `x+0`). The open targets:

| Domain | The schema family III discovers | Discharge route |
|---|---|---|
| **const-chain collapse** | `(x◇c₁)◇c₂ ≡ x◇(c₁ fold c₂)` for ◇ ∈ {AND,OR,XOR} (associativity/composition schemas — symbolic-schema route, one call each); shift-chains `(x<<a)<<b ≡ x<<(a+b)` per-instance over `a+b≤63` | symbolic seq_equiv / range-sweep + brute dual |
| **align/mask idioms** | `(x>>k)<<k ≡ x & ¬(2ᵏ−1)` (align-down), `(x<<k)>>k ≡ x & (2⁶⁴⁻ᵏ−1)` (low-keep) — with the imm32-encodable sub-range as the USEFUL quantifier | range-sweep k=1..63 + brute dual |
| **two-op windows** | machine-mined `f(x) ≡ g(x)` where g is strictly cheaper, à la superoptimizer discoveries but proven + admitted + emitted | symbolic/sweep + kernel term |
| **crypto arithmetic** | Montgomery/NTT/field-reduction identities shortening a real KAT-gated inner loop | `seq_equiv_mod` + KAT cross-check |
| **exact Σ√ / bounded-rank** | new tier-shortcuts + separation bounds (the 2157/2159 family, machine-grown) | the agreement web (R1 exact) |
| **4D exact geometry** | orientation/incidence predicates in ℚ(√…) deciding what floats get wrong | exact ladder + IDENTIFY⟺DECIDE |
| **minted concepts (v3)** | ROTL64 + the C₆₄ law family (Ξ8); POPCNT/SWAR laws when the census demands | spec bridge + symbolic/sweep + dual engine |
| **nonexistence / optimality (v3)** | `rot_k is not 1-op expressible` (the first lower-bound family); matched-bound CLOSED-OPTIMAL certificates | witness-function circuits (∀∃→∀) + count-sweep |
| **derived / unbounded (v3)** | `∀n≥2` n-fold chain collapse; `∀n∈ℕ: rot_1ⁿ ≡ rot_{n mod 64}` | kernel-checked deduction/induction + ground spot checks |
| **denesting (v3)** | machine-found `√(a+2√b) = √m+√n`-class identities in the rank-≤3 envelope | the telescope + the agreement web |
| **orbit families (v3)** | every admitted bit-parallel theorem × its rot-conjugation + width-functor orbit | verified transport + spot checks |

**Pre-registered abstentions (B3 + v2 additions).** P vs NP; poly parity/μ; general superoptimization
completeness; a complete rule set; decidable confluence for general TRS; transcendental zero-testing; **and
the engine never claims its own consistency or the completeness of its own library (the Gödel wall)** — the
loop proves *theorems*, never *itself*. Any artifact appearing to settle a B3 problem is a fabrication,
rejected and re-audited.

---

## 9. Honesty guardrails (the walls, enforced in the engine)

- **Stay on the island by construction**: bounded-width bv, bounded-rank exact, declared ranges, terminating
  rules; superoptimization completeness unchased; prove-or-abstain at every boundary.
- **SD_TOP is honourable**: the frontier queue is a first-class output; silence is the only dishonest abstain.
- **No self-grading**: propose ≠ dispose ≠ meaning-witness, structurally (three organs); `eval.iii` gates
  every assimilation.
- **No islands**: acceptance = a change in real cg_r3 output on real modules, measured; zero-occurrence
  schemas never assimilate.
- **No bloat**: strict cost decrease + occurrence>0, or catalogued-only.
- **Determinism above cleverness**: R5/R6; the C seed frozen; emitted source committed; the compiler never
  reads the library at compile time.
- **No grandiosity**: §8's table is the claimable universe; B3 + Gödel abstentions pre-registered.
- **Conservativity (v3)**: definitions add vocabulary, never axioms; any candidate needing a new axiom is
  REFUSED as a B3-class event. The creator grows language, theorems, methods, questions — never foundations.
- **The reduction law (v3)**: statement kinds enter only by reduction to the standing judgment or
  kernel-checked composition — one judge forever, zero new provers.
- **Derivation never outruns decision (v3)**: every deduced/transported entry carries mandatory bit-level
  ground-instance spot checks; the finite engines stay the arbiter of last resort.

---

## 10. Campaign laws (non-negotiable, every increment)

1. **KAT RED→GREEN only** — negative arm built first; a never-red green proves nothing.
2. **Every gate ships a rejecting negative arm** (false identity, forged trace, flawed term, forged bundle,
   tampered chain, stage1 fire).
3. **R1–R7 on every admitted schema** — no exceptions.
4. **The `eval.iii` meaning-witness gates every assimilation.**
5. **Corpus mechanics**: every new gate registered in `EXPECTED` (`run_corpus.sh` has no default-99); numbers
   2600–2699 reserved for Ξ; stdlib modules registered in `build_stdlib.sh`.
6. **Compiler-TU law**: pre-flight under BOTH iiis-0 + iiis-2; probes emit through cg_svir before landing;
   eval/cg_svir/cg_r3 changes re-embed the chain BEFORE commit; rebuild order stdlib→iiis1→iiis2→iiis3.
7. **NIH / no-Python / no-subagents-on-III / no-placeholders / no-ML (Ax D3)** — hard locks.
8. **No deferral** — a named gap is built this cycle or lands on the printed frontier with its blocker.
9. **Count landed schemas + measured bytes, not intentions.**
10. **THE REDUCTION LAW (v3)** — no statement kind without its exhibited reduction to the standing judgment.
11. **THE CONSERVATIVITY LAW (v3)** — definitions only; a needed axiom is a REFUSED B3-class event.
12. **THE AUTONOMY INVARIANT (v3)** — sovereign binaries + sh only in the engine's process tree; a bare
    clone + one command reproduces the library from genesis. No LLM operates any stage, ever.
13. **THE PROVENANCE LAW (v3, binding since the creator tier opened)** — every library entry names its
    conjecture source: `MACHINE` (synthesized by enumeration/mining — the only kind that counts toward the
    engine's discovery ratchet) vs `human-conjectured / machine-proven` (method exhibits and
    infrastructure). Hand-picked demos may never masquerade as discoveries; the synthesizer receives no
    candidate lists, only space bounds — and its bounds are printed, its remainders frontiered with
    blockers named.

---

## 11. The completion invariant — when is Ξ done?

```
run_mathesis.sh --standing --federated ∈ run_completion.sh, AND:
  Ξ0  seed cycle        one closed loop, measured reduction, door + library live       ← DISCHARGED 2026-07-11
  Ξ1  open proposer     183 machine ∀-theorems (round-1) + round-2 shift tier swept     ← DISCHARGED 2026-07-12
                        (2610 propose · 2611 computed-novelty+dedup · 2612 frontier-queue+R7 retry)
  Ξ2  grounding         theorem sides zk-AIR-constrained + attested; forgery rejected   ← DISCHARGED 2026-07-12 (2620)
  Ξ3  exact face        subsumed by Ξ12 (the telescope arms the exact disposer)         ← DISCHARGED via Ξ12
  Ξ4  library lives     kernel-certified (2640) + content-addressed + REPLAYABLE        ← DISCHARGED 2026-07-12
  Ξ5  standing engine   grammar gap 4→0 (2613 teach); round-2 DRY; ratchet executable   ← DISCHARGED 2026-07-12
                        (2650 loop · 2651 ratchet · DOCS/MATHESIS-RATCHET.txt)
  Ξ6  federation        propagate-by-proof, forged rejected, ML-DSA BFT-canonical       ← DISCHARGED 2026-07-12 (2660)
  Ξ7  seal              chain-v2 → HEAD_v2; MATHESIS_CERT binds math↔streams↔ratchet     ← DISCHARGED 2026-07-12 (2684)
  --- the creator tier (v3) ---
  Ξ8  definition door   ROTL64 + C₆₄ sealed, spec-bridged, law-rich, INERT-honest        ← DISCHARGED 2026-07-12
  Ξ9  statement lattice nonexistence (2675) + order + CLOSED-OPTIMAL (2674)              ← DISCHARGED 2026-07-12
  Ξ10 deduction organ   theorems from theorems; the first ∀n∈ℕ entries; kernel-judged   ← DISCHARGED 2026-07-12 (2676/2677)
  Ξ11 symmetry transport orbits + width functors; equivariance-gated; tooth pinned      ← DISCHARGED 2026-07-12 (2678/2679)
  Ξ12 empirical telescope 1024 machine denesting theorems, web-certified, envelope-honest ← DISCHARGED 2026-07-12 (2680/2681)
  Ξ13 research agenda   measured intent + the autonomy invariant gated                  ← DISCHARGED 2026-07-12 (2682/2683)
```

**ALL PHASES Ξ0–Ξ13 DISCHARGED-IN-CODE (2026-07-12).** `run_mathesis.sh` runs the whole creator tier
end-to-end (exit 0): the seed cycle, the four ceiling breaks, and every completion gate — 25 mathesis
corpus gates, each RED→GREEN with its rejecting negative arm. The library holds 18 sealed entries (6
MACHINE-synthesized by the PROVENANCE law), replays genesis→HEAD_v2, and the MATHESIS_CERT binds the
sealed head to the sealed discovery streams. What remains is not a phase but the *standing frontier*: the
mul-mul wall at width 64 (receded to width 8), the rot 2-op question (cost ∈ {2,3}), the MUX operator, and
the annihilation-teach awaiting measured demand — all queued with blockers named, none deferred silently.

End state: the first system whose **mathematics is a growing, sealed, kernel-checked, replayable library
mined from its own compilation, proven against the silicon that runs it, and folded back into that silicon as
measured upgrades — its optimizer's grammar closed to its prover's algebra**. The longest pole is Ξ0; Ξ0's
first move is the library door (`mathesis_admit.iii`), because everything else writes through it.

---

## 12. Risk register

| Risk | L | Impact | Mitigation |
|---|---|---|---|
| Poison rule admitted (miscompiles III) | Low | **Critical** | R1 dual + R4 arms + R5 DDC + eval witness; only a false-"equal" is fatal; SD_TOP is safe |
| MEASURE finds zero collapsible windows in self-host TUs | Med | Med | honest outcome: the census prints zero, the family switches to what the data DOES show (two-op windows); the frontier records it; Ξ0 still closes on a provable, occurring schema |
| A wanted schema is undenotable (SD_TOP) | Med | Med | the kill-switch: it lands on the frontier with blocker named; the seed switches to a denotable schema; R7 retries it when the disposer grows |
| stage1_corpus fire (parity break) | Med | High | R6 measured BEFORE the arm lands (the MEASURE instrument checks both corpora); the mod-mask precedent is the navigation proof |
| Grandiosity / overclaim | Med | High | §8 is the claimable universe; B3 + Gödel pre-registered; the sealed entry is the whole claim |
| Island (KAT-only, no consumer) | Med | High | acceptance = measured real cg_r3 delta + census ratchet |
| Assimilation thrash | Med | Med | H10 stamps + append-only grammar + Ξ5 convergence gate (both arms) |
| Rebuild-chain cost per rule | Med | Med | batch admission: the library accumulates; assimilation batches N schemas per rebuild |
| OneDrive/AV contamination | Med | Med | repo-local probes, /tmp staging (the corpus runner's own pattern), rm-first relinks |
| Concept noise (macro-minting inflates the library) (v3) | Med | Med | P6: lawless ⇒ REFUSED; zero-occurrence ⇒ marked inert; compression measured |
| Witness-function subtlety (a hole in the mux cases) (v3) | Low | High | totality by construction (mux covers all c); the R4 satisfiable arm proves the method refuses false nonexistence |
| Homomorphism sweep timing (4096 calls > gate budget) (v3) | Med | Low | timing probe first; kill-switch: split the (a,b) plane across two gates; never sample |
| Deduction unsoundness (derive from a wrong premise) (v3) | Low | **Critical** | premises are sealed chain entries only; kernel checks the composition; mandatory bit-level ground spot checks (two-path) |
| Transport unsoundness (non-equivariant statement moved) (v3) | Low | High | equivariance is a checked precondition; the width-64 tooth pinned as the refusing witness |
| Telescope cost explosion (radical family enumeration) (v3) | Med | Med | rank/magnitude envelope caps; enumeration bounded per round; frontier the remainder |

---

## 13. Architecture Decision Records

- **ADR-Ξ1 (v1, held)** — the open space is the compiler's own algebra; no new formal system.
- **ADR-Ξ2 (v1, held)** — discovery untrusted; soundness = disposer + three-organ separation.
- **ADR-Ξ3 (v1, held)** — admit only PROVEN ∧ NOVEL ∧ USEFUL ∧ WITNESSED.
- **ADR-Ξ4 (v1, held)** — the library is the admission tactic, sealed + kernel-checked.
- **ADR-Ξ5 (v1, held)** — Ξ completes Σ (`run_mathesis.sh` IS `run_self_improve.sh`).
- **ADR-Ξ6 (v1, held)** — Θ is consumed, not duplicated (`eval.iii` is the third organ).
- **ADR-Ξ7 (v2, NEW)** — **assimilation is deterministic source emission** into committed, iiis-0-compatible,
  kernel-certified rule TUs (the Path-C/seraphyte mold), never a compile-time library consult. Preserves DDC
  by construction; the alternative (runtime rule loading) rejected as a determinism hole.
- **ADR-Ξ8 (v2, NEW)** — **schema-first admission**: the unit is the certified rule family
  (admit/extract/plan + full-domain proof), matching the mold cg_r3 already consumes; ground facts are
  corollaries. Alternative (per-constant facts) rejected as unbounded bloat with no emission shape.
- **ADR-Ξ9 (v2, NEW)** — **the grammar-closure ratchet is the campaign's measured ambition**: teach-grammar
  climbs to prove-algebra (4 named operators). Alternative (open-ended "find identities") rejected as
  unfalsifiable ambition; this one has a number that must go to zero.
- **ADR-Ξ10 (v3, NEW)** — **creation = conservative definitional extension.** Concepts are minted as
  definitions (unfoldable, zero new trust), never as axioms or ISA changes. Alternative (extend the formal
  system / add opcodes) rejected: the first is an unsound door, the second confuses language with hardware.
- **ADR-Ξ11 (v3, NEW)** — **the reduction law.** New statement kinds reduce to the standing judgment
  (circuit ≡ const / kernel composition). Alternative (a bespoke prover per kind) rejected: N provers = N
  soundness frontiers; here the judge never widens.
- **ADR-Ξ12 (v3, NEW)** — **lower bounds by witness-function circuits** (∀∃ → ∀ via a constructed total
  witness map, one symbolic call). Alternative (a QBF engine) rejected: a new trusted engine + an
  undecidability pull, for no gain at this shape class.
- **ADR-Ξ13 (v3, NEW)** — **intuition = verified transport + exact evidence + measured value.** Analogy is a
  proof-carrying functor; conjecture comes from exactly-decided coincidences; intent from printed
  measurements. Learned/frequency heuristics stay banned (Ax D3) — the search is guided by structure the
  library itself proves.
- **ADR-Ξ14 (v3, NEW)** — **the creator tier changes the library's language, never the compiler's trusted
  path.** Assimilation remains schema-only through P3's emission mold; a concept reaches the compiler only
  as a proven fold/unfold rule with a measured consumer. The DDC fixpoint outranks every clever idea,
  including v3's.

---

*Sister docs: `III-COMPLETION-PLAN.md` (Φ), `III-MEANING-LIFT-MAP.md` (Θ), `III-GRAND-UNIFICATION-MASTER-PLAN.md`
(Ω/Σ), `III-GENERATIVE-FRONTIER.md`, `III-EXACT-SUBSTRATE-INTEGRATION.md`, `III-CONJECTURE-FACULTY-AND-CAPABILITY-PROOF.md`,
`III-WALLS-CASHED-IN.md`, `III-LOGIC-GRAIL-LEDGER.md`, `DOCS/MATH_LIBRARY_QUEUE.md`.*
