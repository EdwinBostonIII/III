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

## 14. THE ALGEBRAIC CREATOR TIER (campaign Ρ — the judge's second universe; 2026-07-13)

The seven stride rungs left iii-exact with a COMPLETE decidable theory the synthesizer had never
been given: the ordered field of real algebraic numbers (chain deg ≤ 3840, the pair-gcd equality
door, the adaptive ≤2048-prime resultant closure). Campaign Ρ hands the mathesis pattern —
*enumerate a declared space, filter by proof, admit content-addressed* — that second universe,
and turns the same engines on III's own body. Three organs, five gates, one sealed stream; every
organ a STANDALONE aether TU composed of exported engine doors — **zero archive edits, zero
reseal cascade, zero owner-family obligation** (the engines themselves are byte-unchanged).

- **`aether/mathesis_alg.iii` — THE REAL-ALGEBRAIC JUDGE** (gate 2700). A slot = (integer
  polynomial as sign/limb rows, dyadic window, ISO = root_count2 == 1 certified). Arithmetic by
  composition: SUM/PRODUCT via `rs_sum_big2`/`rs_prod_big2`, NEGATION by odd-coefficient flip,
  k-th ROOT by t → t^k re-indexing (substitution, not computation). EQUALITY total through
  `sturm2_pair_stash`/`sturm2_pair_gcd` (a gcd root in the window overlap is forced to be each
  side's unique root); ORDER by count-preserving refinement AFTER equality is decided (so
  separation exists); SIGN with the exact zero answered STRUCTURALLY (c0 == 0 ∧ 0 interior ∧
  ISO ⟹ the window's one root IS 0 — bisection alone provably cycles (−1,2] → (−2,1] around a
  zero root forever; the gate's C arm caught that spin live). Measured: √2 three ways EQUAL
  (deg 2 vs deg 6 pair), ∛2·∛4 == 2 across a degree-9 pair, √2−√2 EXACTLY ZERO, √2+√3 < √10
  both directions.
- **`aether/mathesis_radical.iii` — THE RADICAL SYNTHESIZER + THE MX04 DOOR** (gates 2701/2702/
  2703; driver `sovir/mathesis_radical_main.iii`; stream `DOCS/MATHESIS-RADICAL-ROUND1.log`,
  replay BYTE-IDENTICAL). Class D: √(a+b√c) = √m+√n over the printed box a ≤ 32, b ≤ 6, c ≤ 32 —
  the forced system (c nonsquare ⟹ m+n = a ∧ 4mn = b²c, every step integer-decidable) classifies
  ALL 5766 rows: **194 denesting theorems** (each DUAL-verified: integer system + the judge
  through the engines) of which **143 NOVEL** and 51 telescope-slice rediscoveries CONSULTED
  against the standing organ and REFUSED from the ratchet (R3 computed, two organs agreeing),
  **4828 nonexistence theorems** each carrying its failing clause, 744 c-square rows out of
  class. Class F: (u+v∛2+w∛4)³ = e∛2+f over the printed box e ≤ 9, |f| ≤ 9, |uvw| ≤ 2 — 17,500
  pairs, a SOUND cube-envelope prefilter at 2⁻¹⁴, exactly ONE survivor, judged EQUAL:
  **Ramanujan's ∛(9∛2−9) = 1−∛2+∛4 re-found by pure enumeration and proven the ONLY identity of
  its form in the whole box**. The MX04 door: the algebraic domain's 8-word descriptor grammar
  (class 1 denest / 2 nonexist / 3 cube-identity / 4 cube-refuted; provenance MACHINE only) on
  the SAME cad spine as the bit-vector door — a new domain gets its own grammar and its own
  genesis-separated chain rather than an edit to the sealed MX01 door (two doors is one more
  surface, named; the spine and the four-clause discipline are shared). **5023 theorems chained**,
  head `2a84e3b7…a7f8`, RADICAL_CERT pinned in `run_mathesis.sh` stage [9]; MATHESIS_CERT and the
  MX01 chain stand byte-unchanged.
- **`aether/charpoly.iii` — THE EXACT SPECTRAL ORGAN** (gate 2704). det(tI−A) by the engine's own
  seven-rehearsed pattern: per-prime node dets (Gauss, partial pivot) at k = 0..n, Lagrange
  recovery, per-coefficient Garner CRT in dropped arenas, delivery in the `sturm2_in_*` limb
  shape, and the mod-every-used-prime consistency recheck on the DELIVERED rows; the prime count
  ADAPTIVE from the matrix's own sound bound (n ≤ 64, |entries| ≤ 2^20 printed envelope; a P_4
  fixture uses ONE prime). What the rows prove through the chain: **char(A) == t^n ⟺ the digraph
  is a DAG** (nilpotency — the acyclicity certificate) and **multiplicity of the root 0 of
  char(Laplacian) == the number of connected components** (the connectivity certificate).
  Fixtures two-pathed against the gate's OWN Chebyshev-style recurrence (a wrong value REFUTED
  first). THE REAL ARM: III's own module graph (omnia/self_atlas_data, the machine-generated
  self-image) — the "ripple"-prefixed subsystem: **n = 12, certified DAG (exact algebra and the
  gate's own Kahn toposort agree), symmetrized Laplacian zero-multiplicity 5 == union-find 5
  components**. THE RIPPLE TIE (gate arm W): the same real subsystem fed to the standing
  `ripple_metric` — a synthetic unused edge raises rm_noise by exactly 1 (the metric PRICES
  degradation) while the reverse of a real edge flips the acyclicity certificate to NO (the
  algebra PROVES the break, the toposort agrees): the self-refactoring stack now has an exact
  spectral integrity dimension available to its deciders.

**Laws learned (paid for by red arms, kept):**
- **The structural zero test**: deciding sign of an isolated algebraic number by bisection alone
  livelocks when the number IS zero (midpoints alternate sides of 0 and never land on it); the
  ISO invariant + c0 == 0 decides it in O(1). Every refinement loop that may straddle an exact
  zero needs the structural exit.
- **The interior-bracket law**: a MULTIPLE root at a Sturm bracket endpoint vanishes every chain
  entry there (the gcd divides the whole chain) and the variation count degenerates — multiple
  roots must sit INTERIOR to the bracket. Simple roots at the closed endpoint stay correct (p′
  anchors the count). For Laplacians on ≤ 64 nodes, λ₂ ≥ 2(1−cos(π/64)) > 2⁻⁹ (the Fiedler path
  bound), so (−2⁻¹³, 2⁻¹³] brackets the zero eigenvalue with 0 interior, always.

**Honest scoping (the Eidolon discipline):** the denesting criterion and the binomial-resultant
norm forms are classical mathematics; the deliverables here are (1) the MACHINE provenance of
every row (no candidate supplied, the whole box swept, proof the only filter), (2) the exact
certificates (nothing floating anywhere in the object), (3) novelty adjudicated against III's
OWN standing library (computed, two-organ agreement — not a literature claim), and (4) the
self-referential rows (III's own subsystem spectra), which are new mathematical objects outright.
The evergreen property: `run_mathesis.sh` stage [9] re-runs the door gates and re-pins the sealed
stream on every invocation; the sweeps re-run whole through the committed driver — no session, no
LLM, anywhere in the loop (law 12 holds; the engine's process tree is unchanged).

---

## 15. CAMPAIGN Σ — UNASSISTED DISCOVERY (the answer to "old theorems are worthless"; 2026-07-13)

The Ρ critique, accepted in full: re-deriving a NAMED identity proves machinery, not discovery.
Σ pivots to hunts whose answers the author did not know, with the hunting equations themselves
machine-derived so nothing can be seeded. Two organs, three gates, two sealed streams; still zero
archive edits.

- **`aether/mathesis_ring.iii` — THE RING JUDGE + THE FRONTIER DRAIN** (gates 2705/2706; stream
  `DOCS/MATHESIS-RING-DRAIN.log`). Exact multivariate normalization over ℤ[x,c1,c2] on the synth
  RPN bodies. Soundness: ring homomorphism into EVERY ℤ/2^w — a ring-proven schema holds at ALL
  widths at once (stronger than the disposer's width-64 rows). Completeness on the fragment, and
  CONSTRUCTIVE: per-variable degree ≤ 3 with coefficients < 2¹² means the Newton finite
  differences over {0,1,2,3}³ sit far below 2⁶⁴, so grid-vanishing mod 2⁶⁴ forces the zero
  polynomial — a ring-unequal pure pair MUST have a witness IN THE GRID (an empty-handed search
  is a self-detected defect, not an abstention). Mixed boolean-mul pairs go through THE
  LIBRARY-COMPOSITION ROUTE: idempotence rewrite citing round-1's own PROVEN schemas (citations
  re-proven fresh through seq_equiv before any rewrite is trusted — theorems-from-theorems).
  **THE ROUND-1 FRONTIER — 1,386 pairs queued since the first sweep with blocker "bit-blast mul
  equality" — IS DRAINED: 2 ring-proven (both mul-associativity forms, now ∀-width theorems) +
  6 library-composed ((x&x)·x ≡ x·x and kin) + 1,378 refuted with concrete witnesses + 0
  undecided.** Every proven pair re-proven independently by the standing width-8 EXHAUSTIVE
  engine (all 2²⁴ triples — two engines, one truth). R7 honored by the exact route the frontier's
  header had named ("ring/kernel later").
- **`aether/mathesis_curve.iii` — THE SURFACE HUNTER + THE SIGMA CATALOGUE** (gate 2707; stream
  `DOCS/MATHESIS-CURVE-ROUND1.log`, MX05 chain head `07fdc686…a354`). The machine DERIVES — by
  exact quotient-ring cubing in ℤ[u,v,w][γ]/(γ³−d), no transcribed algebra — the surfaces on
  which (u+v∛d+w∛d²)³ collapses to ℤ+ℤ∛d (curve A: P2 = 0) or ℤ+ℤ∛d² (curve B: P1 = 0), with the
  completeness bridge machine-checked per d (non-cube ⟹ t³−d has no integer root ⟹ no rational
  root ⟹ irreducible ⟹ {1,γ,γ²} independent ⟹ every identity lies ON the surface). It then
  inventories ALL primitive canonical rays to height 60 for d ∈ {2,3,5,6,7} on both curves —
  7,326,700 rays — and verifies every hit end-to-end through the pair-gcd judge. **THE INVENTORY
  (pinned, every row machine-found): 21 identities in 7 complete ∛d-orbits — d=2 curve A carries
  exactly the Ramanujan orbit (the machine's independent re-find, now properly attributed);
  d=3 curve B carries SIX rows the author did not know — the seed SIGMA-d3B-1:
  (2 + 3∛3 − 4∛9)³ = 438∛9 − 919 — the first σ-identities; d=6 and d=7 carry six curve-A rows
  each (SIGMA-d6A-*, SIGMA-d7A-*, e.g. ∛(84∛6−148) = 2−2∛6+∛36); and d=5 is CERTIFIED EMPTY on
  both curves to height 60 — a nonexistence theorem.** The γ-orbit closure law
  (γ·ρ solves whenever ρ does) is machine-verified over the whole inventory: 21/21 orbits close
  inside the box. The A/B selection pattern (d=2:A, d=3:B, d=6,7:A, d=5:neither) is a
  machine-posed OPEN question, recorded with its certified evidence.
- **THE FIELD COMPLETION** (`ma_inv`, gate 2700 arm I): inverse by row reversal + unit-widened
  rational-to-dyadic windows; 2·(1/√2) ≡ √2 and 1/(√2+√3) ≡ √3−√2 decided by pair-gcd; 1/0
  refused by name. The judge now carries +, ×, −, ⁻¹, and k-th roots.

**The honesty framework for "new":** novelty against the world's literature is unfalsifiable
from inside this room and is NOT claimed. What IS claimed, and machine-certified: (1) the
surfaces were derived, not supplied; (2) the sweeps were exhaustive over printed boxes; (3) every
find carries an end-to-end exact certificate; (4) the author's own prior ignorance of the d=3/6/7
rows and of d=5's emptiness (recorded here as a fact about provenance, not a proof of global
novelty); (5) the names are minted by the catalogue (SIGMA-d<d><A|B>-<k>), and the finds are the
machine's to keep regardless of what any archive turns up. SIGMA_CERT binds the catalogue head +
the drain partition; MATHESIS_CERT and RADICAL_CERT stand unchanged beside it.

---

## 16. CAMPAIGN Τ — THE MACHINE ATTACKS ITS OWN QUESTION (2026-07-13)

The Σ critique's next rung: a researcher is measured by what it does with its OWN open question.
Τ gives the engine three instruments and points them at the A/B/empty pattern it posed (gate
2708; stream `DOCS/MATHESIS-TAU-ROUND1.log`, replay byte-identical; TAU_CERT beside the others).

- **HEIGHT ESCALATION**: d=5 swept to height 200 on BOTH curves — still EMPTY (226,980 →
  7,761,354 rays, zero hits). The nonexistence inventory extends 34-fold.
- **THE EXTENDED PATTERN**: d ∈ {10,11,12,13,17} at height 60 — **d=12 curve A carries SIX new
  identities (SIGMA-d12A-1…6, e.g. (3−3∛12+∛144)³ = 351∛12−801, every one judge-verified inside
  the hunt)**; d=10,11,13,17 empty both curves. The pattern now reads **A = {2,6,7,12},
  B = {3}, neither = {5,10,11,13,17}** — richer, sharper, still open.
- **THE GROUP ENGINE** (`mcg_*` in `aether/mathesis_curve.iii`): chord-tangent structure on the
  machine's own cubics by EXACT integer arithmetic — the line through two rational points meets
  the curve in a third, extracted from two evaluations (parity-checked; odd residue = a
  self-detected defect), every output re-checked ON the curve, every nontrivial point re-verified
  as a radical identity through the judge, heights capped at 4096 with escapes COUNTED. What the
  machine discovered with it: **the trivial triangle {(1,0,0),(0,1,0),(0,0,1)} is chord-tangent
  CLOSED and does NOT generate the Ramanujan point** (the σ-points are independent of the trivial
  configuration — machine-proven to the cap); **{trivials + Ramanujan orbit} is EXACTLY closed at
  6 points, 0 escapes** (a torsion-flavored finite configuration); **d=3 curve B's 9-point
  configuration is NOT closed — 12 constructions escape the height envelope** (the two curves
  have structurally different point configurations — machine-observed); d=5's trivial closures
  stay trivial on both curves.
- **THE LOCAL PROBE**: projective point counts mod p for the d=5 curves — **curve B mod 7 has
  EXACTLY the 3 trivial points (the bare minimum a curve with the trivial rays can have) while
  curve A mod 7 has 12** — a machine-found local asymmetry aligned precisely with the global
  emptiness pattern, recorded as certified evidence. (No small-prime obstruction kills either
  curve outright — the emptiness, if global, is a DEEP phenomenon; the question stands,
  sharpened, with the machine's evidence chained to it.)

**The verdict line the stream pins**: `THE OPEN QUESTION STANDS, SHARPENED`. That is the honest
state: the machine escalated the evidence, discovered the closure structure, found the local
asymmetry, harvested six more identities — and correctly refused to claim what it has not
proven. The named frontier out of Τ: bigint chord-tangent (the 12 escaped constructions are
computable with wider arithmetic — each would be a CONSTRUCTED identity beyond any sweep), the
Weierstrass/rank route for the emptiness proof, and the pattern law itself.

---

## 17. CAMPAIGN Υ — THE AUTONOMOUS PILOT + THE STRUCTURE FORGE (2026-07-13)

The two standing critiques, answered in code (gates 2709/2710; streams
`DOCS/MATHESIS-FORGE-ROUND1.log` + `DOCS/MATHESIS-PILOT-LEDGER.log`, replay byte-identical;
UPSILON_CERT beside the other four).

- **"You are still piloting it" → THE PILOT IS CODE** (`aether/mathesis_pilot.iii`): each
  round's experiment is a pure function of the round number — NEW-D (the canonical cube-free
  sequence), HEIGHT (a fixed escalation schedule with a NAMED refusal past its envelope), LOCAL
  (row-major (d,p) probes). The budget (PILOT_ROUNDS, environment) is the only input and selects
  nothing; the ledger head at round k is a pure function of k (tamper-evident, extendable by any
  future invocation). **The pilot's FIRST autonomous choice found what every human-piloted round
  missed: d=4 (three curve-B identities) and d=9 (six curve-A identities) — and those two holes
  exposed THE INVOLUTION LAW: d ↔ d² (mod cubes) swaps curves A and B** (γ ↔ γ² swaps the
  collapse lines; counts preserved as point-sets, not heights). The law's predictions were then
  tested: **d=18 → six curve-B points (partner of d=12), d=25 → EMPTY (partner of d=5) — both
  CONFIRMED; d=49 carries 5/6 partners inside height 60; d=36 carries six with one oversized hit
  honestly counted as verification-REFUSED** (the hunt now distinguishes judge refusal from
  judge disagreement — the conflation was itself found by the d=36 probe and fixed). The A/B
  half of the open question is thereby REDUCED: the pattern is closed under the involution, so
  the primitive question is which CUBE-FREE CLASSES {d, d²} collapse at all — {2,4}, {3,9},
  {6,36}, {7,49}, {12,18} do; {5,25}, {10,100?}, {11,121?}, {13,169?}, {17,289?} do not at the
  swept heights (the pilot's future canonical rounds will reach the partners).
- **"Beyond numbers" → THE STRUCTURE FORGE** (`aether/mathesis_forge.iii`): the objects are
  OPERATIONS. Every binary operation on 2- and 3-element carriers (16 + 19,683 tables), eleven
  laws each decided by TOTAL exhaustion, classified raw and up to isomorphism (minimum
  relabeling over the full symmetric group). **The census, triple-anchored**: group-profile
  tables = n!/|Aut(Z_n)| (2 and 3 — the independent cyclic-group closed form), iso-classes 10 at
  n=2 (Burnside, spelled out in-gate) and **3,330 at n=3**; **59 inhabited species** of the
  2,048-profile lattice, 1,989 profiles EMPTY at n ≤ 3 by exhaustion (machine-posed existence
  questions, not nonexistence claims). Exhibits minted: FORGE3-P1439 (the bounded semilattice,
  unique) and **FORGE3-P2022 — the unique maximally-lawful NON-associative species at n=3**
  (idempotent, commutative, doubly self-distributive, involutory, medial, both-cancellative;
  first representative table 14001) — the machine's own Steiner-type quasigroup, an ontology
  citizen that is not a number and was never supplied.

**Named frontier out of Υ**: n=4 (4.3·10⁹ tables — a priced sweep, not a gate), bigint
chord-tangent, the {d,d²}-class law's proof, and the pilot's unbounded ledger (every future
harness invocation may raise PILOT_ROUNDS; the head extends deterministically).

---

## 18. THE ONTOGENESIS (campaign Υ-2 — the base ontology, manipulated by III alone; 2026-07-13)

Gate 2711; stream `DOCS/MATHESIS-ONTO-ROUND1.log` (replay byte-identical, every carrier-3
citizen's Cayley table printed); stage [13]; ONTO_CERT. The base: unlabeled tokens and ONE
primitive (combination), |carrier| ≤ 3, no numbers presupposed — indices are names, never
magnitudes. What arose under the machine's own manipulation: (1) its own taxonomy (the forge's
19,699-table census re-entered as ontology); (2) its own canonical objects — citizens = species
unique up to isomorphism, a content-neutral criterion stated as code (10 at two tokens, 24 at
three); (3) **THE GAP THEOREM**: the 11-law language does NOT determine the profile of the
OPPOSITE — 40 profiles gap-witnessed at the third token (witness: tables 377 and 715 share
11-profile 1344, their opposites' profiles differ 1696 vs 1184), and at two tokens there is NO
gap — the inadequacy EMERGES with the third token; (4) the language extension the manipulation
demanded — the mirror law RINVOL ((x∘y)∘y = x) — restores closure, and **THE DUALITY LAW**
verifies over the ENTIRE universe: profile12(opposite(T)) == swap(profile12(T)) for all
16 + 19,683 tables, zero exceptions; (5) **THE PRODUCT LAW**: profile12(A×B) == profile12(A) AND
profile12(B) over every ordered citizen pair — 580 products on carriers up to 9, pair-for-pair.

---

## 19. CAMPAIGN Φ — THE FRONTIER DRAIN (2026-07-13)

Every named frontier item, attacked to the campaign standard: settled totally, constructed
exactly, or extended deterministically (gates 2712–2716; stream `DOCS/MATHESIS-PHI-ROUND1.log`,
replay byte-identical; stage [14]; PHI_CERT beside the other six).

- **Φ1 — THE ROT-2OP SETTLEMENT** (`aether/mathesis_rot2.iii`, gate 2712): the oldest frontier
  question (blocker 3, queued since Ξ9). Total width-8 exhaustion of the 2-op space over the
  FULL 8-op ALU grammar — 3,456 shapes (both nestings, leaves {x,c1,c2}) × the whole live
  constant box = **101,122,176 candidates: ZERO compute any rot_k** — while the same sweep
  pointed at −x finds 311,056 witnesses (the existence tooth; the machine also now owns the
  exact census of 2-op negation spellings). With the identity-tail subsumption and the in-grammar
  definiens, **cost₈(rot_k) = 3 EXACTLY for k = 1..7**. The evaluator is grounded in the standing
  symbolic engine (bb bridge at width 8) and the width-64 entry stays queued per the frontier law.
- **Φ2 — THE BIGINT HARVEST** (`aether/mathesis_bigcurve.iii`, gate 2713): a sign-magnitude
  limb core (exact mul, binary gcd, EXACT division with limb-checked zero residue, decimal
  rendering) replays the d=3 curve-B closure step-for-step against the standing organ (pool 9,
  escapes 12 — two implementations, one truth) and re-executes each escape in exact bigint:
  **all 12 constructions land, on-curve in bigint, as identities no sweep could reach** — the
  first: **(7497 + 8400·∛3 − 5780·∛9)³ = 3,138,045,143,940·∛9 − 6,090,322,207,527**. THE PAIR
  STRUCTURE, machine-observed: the 12 constructions yield exactly **6 distinct points, each
  constructed twice by independent routes, carrying only 3 distinct radical coefficients e**.
  All 12 exceed the judge's exact-sign envelope — counted as envelope refusals, certificate =
  bigint on-curve + the sealed 2707 derivation. The growth probe: chord passes add 6 then 9
  points (cap 24, 3 refusals) — **the d=3B configuration does NOT close** (the d=2 one closed
  at 6): the structural asymmetry now has constructed witnesses.
- **Φ4 — THE NORM INSTRUMENT** (`aether/mathesis_norm.iii`, gate 2714): N(u+vγ+wγ²) = u³+dv³+
  d²w³−3duvw, computed TWO WAYS (direct form vs det of the multiplication matrix through the
  STANDING charpoly organ) — equal on all 27 catalogue rows; **multiplicativity N(α)³ == N(α³)
  through the bigint core, 27/27; the γ-law (γα stays on-curve, N scales by exactly d), 27/27**.
  Discoveries: **the Ramanujan orbit is the norm-coincidence orbit (e == N == −f on exactly the
  d=2 rows: 9/18/36)**; the six d3B rows form two γ-orbits with **f(α) == −N(e-partner) crossed,
  six crossings exact**; **THE CROSS-ORBIT PRODUCT LAW**: pairs with γ-indices summing ≡ 0 (mod 3)
  multiply into Z + Zγ — one fundamental product (2,3,−4)×(4,6,−1) = (−73,36,0) with
  N = −249,049 = (−271)(919), the other two collapses equal to its 3-fold (−219,108,0); the unit
  censuses per d (h ≤ 20; d=2 has 18 incl. the fundamental (1,1,1) and its ring-square (5,4,3);
  d=12 only the trivial pair); and **THE UNIT-ACTION REFUTATION: 156 unit×point products, ZERO
  land on either curve** — the collapse pattern's symmetry is the γ-action, NOT the unit group;
  the machine tested the hypothesis and killed it with certificates.
- **Φ3 — THE FOURTH TOKEN** (`aether/mathesis_tetra.iii`, gate 2716): the commutative ontology
  at carrier 4, censused TOTALLY — 4¹⁰ = 1,048,576 symmetric tables, twelve laws by exhaustion:
  **25 inhabited species, 43,968 structures, 7 citizens**, TRIPLE-ANCHORED (the profile checker
  equals the standing ontogenesis checker on the whole n ≤ 3 universe; **BURNSIDE computed
  independently from the 24 relabelings' equivariant-fix counts equals the canonical census:
  43,968 == 43,968**; the n=2/3 commutative slices equal the forge's own rows 4/129). Citizens
  minted include **BOTH groups of order four — Z₄ (profile 1131, raw 12 = 24/|Aut|) and the
  Klein group V₄ (profile 3691, raw 4)** — the machine's own "exactly two commutative group
  tables on four tokens" (group-profile species carry exactly 2 structures, raw 16) — plus the
  non-associative cancellative involutory medial citizen 3682 (the Steiner exhibit's sibling).
  **THE PRODUCT LAW extends to carrier 16: 49/49 ordered citizen pairs verified.** Scope stated
  exactly: the commutative slice; the full 4¹⁶ stays priced and refused by name.
- **Φ5 — THE PILOT'S EXTENSION** (gate 2715): budget 12; rounds 6..11 purely from the schedule:
  d=14 EMPTY at 60 (**both factors 2 and 7 collapse yet 14 does not — the pattern is not
  multiplicative**), d=13/17 still empty at 120, two new local tables — and **round 9 found
  d=15: SIX curve-A identities ((−6 + 4·∛15 + ∛225)³ = 882·∛15 − 1191, …) — the pilot's third
  autonomous discovery**. The pattern now reads **A = {2,6,7,12,15}, B = {3},
  ∅ = {5,10,11,13,14,17}**. THE PREFIX LAW held in-gate (head(6) == the sealed ledger head) and
  **head(12) = 976d5689…0c7f** is pinned — the ledger extends deterministically, forever.

**Named frontier out of Φ**: the width-64 rot-2op question (2 ≤ cost₆₄ ≤ 3; width 8 says 3);
a judge for the harvested heights (the 12 constructions await an exact-sign envelope beyond
e ≈ 10⁶); the WHY of the cross-orbit product law and the d=3 entanglement; d=225 (the involution
partner of 15) and the non-multiplicativity of the collapse pattern (14 = 2·7 empty); the
non-commutative fourth token (4¹⁶, priced); the pilot's ledger past 12.

---

## 20. CAMPAIGN Χ — THE CAPABILITY LIFT (gates 2717–2720, stage [15], CHI_CERT)

The standing directive — *the most ambitious unification of preexisting systems and enhancement
of every capability-bound implementation* — answered by LIFTING each named envelope through
COMPOSITION of standing organs, the Φ4 pattern (organs → instrument) made the campaign's law.

- **Χ1 — THE BIG JUDGE** (`aether/mathesis_bigjudge.iii`, gate 2717): the bigint limb core made
  a PUBLIC organ surface (the `bc_*` doors exported from `mathesis_bigcurve`, plus `bc_neg`,
  `bc_limb`, `bge_eval`, `bg_res_h`) and a THIRD judge built on it: elements of Q(∛d) as bigint
  coefficient triples, the quotient-ring product `bj_qmul` (one door: cubes, γ-action,
  cross-orbit products), the exact norm, and **`bj_sign` — exact sign at bigint scale**: γ
  bracketed by a bit-descent integer cube root (the bracket G³ ≤ d·4^s < (G+1)³ VERIFIED each
  scale), the element evaluated as an exact interval, escalation 64→1000 bits, and TERMINATION
  A THEOREM (|α| ≥ |N(α)|/B² for nonzero in-envelope elements: a straddle past the schedule is
  a self-detected defect −8, never an abstention; the coefficient envelope, 12 limbs, refuses
  −9 BY NAME).  **The 12 harvested constructions are now JUDGED identities** (cube-and-compare
  by `bj_qmul` AND the machine-derived grids via `bge_eval` — two arithmetics inside the third
  judge), 9/9 catalogue agreement with judge #2, the perturbation tooth bites, every sign
  decided at the FIRST window rung (s = 64, the certificate printed), and **THE ORDERING**: the
  six constructed points carry an exact total order — events 1 < 2 < 3 < 0 < 4 < 5 — a
  capability neither judge had.
- **Χ2 — THE FULL FOURTH TOKEN** (the `mt4f_` tier of `aether/mathesis_tetra.iii`, gate 2718):
  the 4¹⁶ refusal DISCHARGED — all 4,294,967,296 tables, twelve laws each, by total exhaustion
  (the per-law early-exit checker TWO-PATHED against the standing `mt4_profile` over the whole
  commutative slice; ~17 minutes, the price printed by the harness, `gate_slow`).  **THE
  CENSUS: 109 inhabited species, 20,596,732 lawful tables, 860,978 lawful structures, 21
  citizens** — 14 of them NON-commutative (the right-projection `T(x,y) = y` minted at profile
  1957 with its exact seven-law set); **BURNSIDE analytic (cell-orbit product formula): n=2 →
  10, n=3 → 3,330 (the forge's own numbers), n=4 → 178,981,952** — the machine's own count of
  all binary operations on four tokens up to isomorphism; the lawless classes derived
  (178,120,974); the sym sub-census equals the sealed Φ3 rows SPECIES-FOR-SPECIES (RAWC/ISOCC
  == the standing organ's census over all 4096 profiles, zero mismatches); Z₄ raw 12 / V₄ raw
  4; and **THE CROSS-CARRIER PRODUCT LAW: ontogenesis citizens (n=3) × full-token citizens
  (n=4) at carrier 12, profile₁₂(A×B) == AND, 24 × 21 = 504 ordered pairs — the two ontology
  organs UNIFIED by a verified law.**
- **Χ3 — THE PATTERN INSTRUMENT** (`aether/mathesis_pattern.iii`, gate 2719; composes curve +
  norm + bigjudge): the 19-d box re-hunted (62 verified finds): **A = {2,6,7,9,12,15},
  B = {3,4,18,36,49,225}, ∅ = {5,10,11,13,14,17,25}** — and **d = 225, the involution partner
  of the pilot's d = 15, delivers the predicted THREE curve-B identities at height 60: with it
  H3, THE INVOLUTION CLASS LAW, is CONFIRMED over all seven in-box pairs {x, x² mod cubes}.**
  The other hypotheses die with witnesses: H1 (collapse ⟺ unit at h≤40) REFUTED — d=5 has
  units and no collapse, d=12 collapses with NO unit: after Φ's unit-action refutation, the
  second machine proof that **the unit group does not drive the pattern**; H2 refuted (d=2);
  H4 (multiplicativity) refuted at d=14, now a pinned verdict row.  **THE ORBIT LAW** —
  (γⁱα)(γʲβ) == γ^(i+j)(αβ) — verified through the big judge over every ordered pair, 324/324
  (d=3B) + 81/81 (d=2A): the mod-3 arithmetic of the cross-orbit product law is EXACT.  **THE
  γ²-CENSUS**: exactly pairs (0,2), (1,3), (4,5) of the six d=3B rows multiply into Z + Zγ —
  and AT THE HARVESTED 10¹² TIER the same census gives 3 c₂-vanishing AND 3 c₁-vanishing pairs
  of 15: the collapse structure EXTENDS to the constructed points.  **THE FIT**: 0 of 384
  signed-permutation maps relate any two rows — the entanglement is NOT a coordinate
  permutation (an honest kill).  **THE NORM LAW** (the factor door, trial division to 10⁶,
  cofactors named): the six d=3B row norms are −271, 2757, 919, −2439, −813, 8271 — **the two
  γ-orbits carry the two primes 271 and 919 of the fundamental product −249049 = 271·919**,
  scaled by exactly d = 3 per γ-step.  And **THE COMPOSITION TOOTH**: d=36's refused hit —
  counted-but-undecidable since Υ — is now RECORDED (`mcv_refrow_*`, the refusal keeps its
  coordinates) and DECIDED by the big judge (`bj_verify_raw` == 1).
- **Χ4 — THE PILOT AT 18** (gate 2720): rounds 12–17 purely from the schedule — **round 15
  found d = 19: FOUR curve-A identities, the pilot's FOURTH autonomous discovery and the first
  non-{3,6} count** (at least two orbits, partners beyond height 60); round 12 pulled d=18's
  predicted B:6 into the ledger itself; d=10/11 EMPTY at height 200; two local tables.  The
  prefix law held (head(12) == the sealed Φ head byte-for-byte) and **head(18) =
  18a0495c…67a6** pinned across two full runs.
- **ENVELOPES LIFTED, NAMED**: `mcv_derive` d ≤ 49 → **d ≤ 4096** (the soundness bound printed:
  6d² ≤ 1.01e8 coefficients, 5.2e16 eval terms at hmax 200); refused hunt hits now RECORDED
  with coordinates; the judge's exact-sign envelope e ≤ 1,008,000 → 12-limb bigint; and **THE
  STALE-TU LAW** at the harness head (a cached organ object older than its source is cleared
  before any stage can reuse it — the #1 ledger trap is dead by construction).

**Named frontier out of Χ**: d=19's missing partners (A:4 = one full orbit + a fragment — the
γ-partners live above height 60; a priced 120-sweep); the WHY of the norm-prime law (the two
orbits ↔ the two primes 271/919 — ideal/class structure, priced, not smuggled); the width-64
rot-2op question (still queued per the frontier law); the lawless iso census computed directly
(the 4.3e9-table canonical sweep, ~30 min, priced); the non-commutative product law beyond
citizens; the pilot's ledger past 18.

---

## 21. CAMPAIGN Ψ — THE UNIVERSAL REACH (gates 2721–2725, stage [16], PSI_CERT)

Every frontier item Χ named — attacked, and settled, constructed, counted, or bit-blasted with
III alone.  The Φ4/Χ pattern (compose standing organs into a new instrument) made the campaign.

- **Ψ4 — THE CENSUS BEYOND ENUMERATION** (`aether/mathesis_census.iii`, gate 2723; composes the
  `bc_*` limb core): the exact number of binary operations on n tokens up to isomorphism (and the
  commutative sub-count), for **n = 5, 6, 7**, by Burnside's lemma over Sₙ in exact bigint along
  **TWO INDEPENDENT ROUTES** that agree to the digit — route 1 the permutation FLOOD (|Fix(σ)| =
  the product over σ-orbits of the n²/symmetric grid of |Fix(σ^L)|, the exact generalization of Χ's
  `mt4f_burnside_full`), route 2 the cycle-type PARTITION ARITHMETIC (Σ size(λ)·fix(λ), no grid
  flooded).  **n=5: 2,483,527,537,094,825 (comm 254,429,900); n=6: 14,325,590,003,318,891,522,275,680
  (comm 30,468,670,170,912); n=7: 50,976,900,301,814,584,087,291,487,087,214,170,039 (comm
  91,267,244,789,189,735,259)** — n=7 full counts the iso-classes of **7⁴⁹ ≈ 2.56·10⁴¹** operations
  WITHOUT enumerating them.  TRIPLE-ANCHORED: n≤4 == the sealed paid exhaustions (10/3,330/178,981,952
  full == the live `mt4f_burnside_full`; 4/129/43,968 commutative).  The exact limb divider
  (`bc_divexact` by n!) makes a nonzero residue a self-detected defect, never a rounded answer.
- **Ψ5 — THE WIDTH-64 ROT SETTLEMENT** (`aether/mathesis_rot64.iii`, gate 2724; composes
  `numera/bv_bits` → `numera/sat` + the standing `mathesis_rot2`): the oldest frontier entry (Φ1
  kept the width-64 rot question queued) taken off the queue by BIT-BLASTING the machine word.
  **THE UPPER BOUND, MACHINE-WORD PROVEN: cost₆₄(rot_k) ≤ 3 for ALL 63 rotations** — the three
  spellings (x≪k) OR/ADD/XOR (x≫(64−k)) proven BIT-IDENTICAL at width 64 by III's own CDCL solver
  (63/63).  **THE LOWER BOUND: cost₈(rot_k) = 3 by TOTAL exhaustion** (0 rot matches, reproduced
  through TWO evaluators — this organ's native sweep AND `mr2_sweep` — with the NEG existence tooth
  firing, 311,056 spellings of −x), the NEG tooth bb-CONFIRMED at width 64, and a per-shape decision
  that **refutes 818 of the 3,456 shape-classes outright at width 64 (0 admit a 2-op rotation)**, the
  residual 2,638 two-constant classes NAMED and priced.  The first machine-word bit-blast of the
  rotation cost in the tree.
- **Ψ1 — GAMMA-ORBIT COMPLETION** (the `mp2_orbit` tier of `mathesis_pattern`, gate 2721): every
  hunt find's full γ-orbit CONSTRUCTED (γ·(u,v,w) = (dw,u,v), primitive-reduced), each verified ON
  THE CURVE in exact bigint.  **d=19 curve A: the pilot's four finds complete to exactly SIX points
  — two γ-orbits of 3 — with the TWO missing partners (coordinates beyond height 60) CONSTRUCTED and
  bigint-verified (8/8 on-curve): Χ's "d=19 partners beyond the envelope" RESOLVED.**  d=2/d=3/d=15
  are closed within height 60 (only-by-construction = 0).
- **Ψ3 — THE NORM-PRIME LAW GENERALIZED** (the `mp2_normprime` tier, gate 2721): each find's norm
  N = u³ + dv³ + d²w³ − 3duvw factored with **isqrt-certified primality** (trial division to
  ⌊√n⌋, exact, total, no probabilistic step).  d=3 curve B re-surfaces the sealed norms
  [−271, 2757, 919, −2439, −813, 8271] and the primes {271, 3, 919} through a FRESH i64 norm path
  (a two-path confirmation of Χ's 271·919 = 249049); the γ-norm law N(γα) = d·N(α) is visible as
  the per-step scaling; d=19 carries {89, 307, 9613, 19}.
- **Ψ2 — THE BOX TO 50** (the `mp2_box` tier, gate 2722): every cube-free d in [2,50] hunted at
  height 60 both curves — 42 cube-free d, 133 finds.  **NEW: d=20 (A:9, B:2) and d=50 (A:2, B:7)
  are the FIRST cube-free d to collapse on BOTH curves; d=30 carries EIGHTEEN curve-A identities**
  (the richest in the whole census); new A-collapses at 22, 26, 28, 33, 34, 35, 37, 42; new
  B-collapse at 45.
- **Ψ6 — THE PILOT AT 24** (gate 2725): rounds 18–23 purely from the schedule — **round 18 (NEW-D)
  chose d=20 and found A:9 B:2, the pilot's FIFTH autonomous discovery and the first d collapsing on
  both curves**; the prefix law held (head(18) == the sealed Χ head byte-for-byte) and head(24) =
  f6d76f99… pinned across two full runs.

**ENVELOPES LIFTED BY NAME**: the census past all possible enumeration (n≤4 exhaustion → n=5,6,7 by
analytic Burnside, two routes); the width-64 rot cost from "queued" to "≤3 machine-word-proven, ≥3
total at width 8 and decided for 818 classes at 64"; d=19's partners from "beyond the envelope" to
CONSTRUCTED; the norm-prime law from d=3 to a general isqrt-certified census; the collapse box 19→50.
**Named frontier out of Ψ**: the residual 2,638 two-constant width-64 rot classes (a SAT-synthesis
question); the WHY of the both-curve d=20/d=50 collapses; d=30's eighteen; the census at n=8 (the
partition arithmetic scales — only the anchor gets expensive); the pilot's ledger past 24.

**NEW .iii facts confirmed this campaign (2026-07-13)**: `bc_render` stores ASCII digit CHARACTERS
(48+digit), not raw digit values — `bg_digat` returns the char, print it directly; `bc_mul`/`bc_muli`
FORBID destination-aliasing (`d` must not be `a`) — accumulate through a temp then `bc_copy`; the
`numera/bv_bits` bit-blaster decides ∀-equivalence at width ≤ 64 exactly but has no ∃-synthesis door,
so a full width-64 lower bound over free constants needs a SAT model (priced, not free).

---

## 22. CAMPAIGN Ω — CLOSING THE RESIDUAL (gate 2726, stage [16b], OMEGA_CERT)

Ψ named the residual and its obstruction precisely: deciding whether a 2-op shape computes rot_k at
width 64 is `∃c1,c2 ∀x` (a Σ₂ query), and `bv_bits` decided `∀`-equivalence but had no `∃`-synthesis
door. Ω builds the door and closes the residual as far as the machine word's SAT-hardness allows.

- **THE DOOR** (`numera/bv_bits.bb_solve_zero`, ~25 lines, PURELY ADDITIVE): the dual of `bb_equal`.
  Where `bb_equal` asserts "some output bit differs" and reads UNSAT as PROVEN, this asserts "every
  bit of `node` is 0" (w unit clauses), replays the same buffered construction stream into a fresh
  `sat_init`, and reads **SAT as WITNESSED** (the model left live for `bb_witness`), UNSAT as "node
  is nonzero for all inputs." The `∃`-half `bv_bits` lacked. Existing behaviour byte-unchanged
  (verified: two-compile determinism + gate 2724 still green + unit test: `∃c:(c⊕5)=0→5`,
  `∃c:(c+3)=0→−3`, `const 5→UNSAT`). Fresh-linked into the mathesis harness only; the archive's
  `bv_bits` is untouched, so the 46 other corpus gates + the weave keep the old engine.
- **THE CEGIS ENGINE** (`mathesis_rot64`, `mr64_omega`): counterexample-guided inductive synthesis.
  SYNTH the mismatch `M = ⋁ᵢ (E(xᵢ;c) ⊕ target(xᵢ))` with the constants as `bb_var` and the samples
  as `bb_const`; `bb_solve_zero(M)` → UNSAT = **REFUTED** (no constant fits the necessary sample
  conditions, hence none works — SOUND), SAT = candidate via `bb_witness`. VERIFY `∀x` via `bb_equal`;
  a match is a genuine cost-2 witness (RED), a difference feeds `bb_witness(0)` back as a new
  distinguishing sample. Terminates (each round kills the last candidate; the constant space is
  finite). A **saturating BARREL SHIFTER** in bb primitives (6 MUX stages + an overflow mask) makes
  even variable-shift shapes — a shift by `x` or by the inner expression — bit-blastable, so every
  shape is in scope.
- **THE CERTIFICATE** (width-8 ground truth): `mr64_validate8` runs the CEGIS per-shape verdict
  against the TOTAL native oracle `mr64_brute_shape` over **all 3,456 classes, for rot AND neg** —
  **0 disagreements, 0 undecided.** The engine is sound (never false-refutes, proven where neg HAS
  solutions the finder must — and does — find them) and complete at width 8. Only then is its
  width-64 verdict trusted. This is the whole soundness proof, machine-checked; corrupt the barrel
  shifter or the door and a disagreement reddens the gate.
- **THE RESULT** (width 64, ~55 s): CEGIS **refutes 2,676 classes (0 admit a 2-op rotation)** — the
  Ψ residual **2,638 collapses to 780** — and those **780 are EXACTLY the shapes containing a
  hardware MULTIPLY** (`mr64_oundmul` == `mr64_ound` == 780). That is the classically SAT-hard 64-bit
  multiplier `bv_bits`' own header flags ("solve interactively at width 8 … SAT-hard at 64"): a
  documented, principled limit of the SAT approach, NOT an engine defect (the engine decides those
  same MUL shapes correctly at width 8). **cost₆₄(rot_k) = 3 for the 2,676 decided classes**; with
  the Ψ 63/63 machine-word definiens (≤3) and the total width-8 exhaustion (=3).

**What Ω establishes**: III's own SAT solver now SYNTHESISES-OR-REFUTES 2-op programs at the machine
word, not just checks equivalence — a capability the tree lacked. The width-64 rot lower bound goes
from "818 classes decided (Ψ)" to "2,676 decided, residual = the 780 irreducible multiply shapes,"
with the deciding engine PROVEN correct against total ground truth. **Named frontier out of Ω**: the
780 MUL shapes (a multiplier-aware decision procedure — Z/2ⁿ polynomial reasoning, or the linearity
reduction "x·c is GF(2)-linear ⟺ c is 0 or a power of two" — would close them); the same CEGIS door
now generalises to any 2-op synthesis question over the ALU at the machine word.

## 23. CAMPAIGN Ω-2 — THE FULL SETTLEMENT (gates 2727–2730, stage [17], OMEGA2_CERT)

Ω left 780 MUL shapes undecided at the machine word and named the obstruction: `bb_mul` emits its
full ~35k-clause / ~12k-var structure regardless of operand constness, so a CEGIS mismatch over a
few samples with multipliers blew the `bv_bits` stream/var caps (0xFF → undecided). Ω-2 closes the
residual **to ZERO by ENCODING, not capacity** — the caps are UNTOUCHED, because the sealed 2726
pins (2,676/780) *depend* on where they bind; lifting them would drift a sealed gate. A new tier
(`omega2`) in `mathesis_rot64`, so the sealed Ω tier stays byte-identical.

- **THE MECHANISMS** (each earns a named class of the residual):
  1. **CONST FOLDING + THE CMUL COLLAPSE** — an op with two structurally-constant operands is
     computed natively (zero clauses); mul by a CONCRETE constant m is the shift-add over m's bits
     (samples are chosen low-popcount, so mul-by-sample ≈ one ripple adder).
  2. **SHARING** — an x-independent subtree is the SAME function of (c1,c2) at every sample: built
     ONCE per CEGIS round and reused. The per-sample rebuild was the whole capacity story (each
     rebuild re-emits the multiplier's clauses). The shared INNER kills the const·const-mul shapes;
     the shared ROOT kills the x-free shapes — their mismatch OR over two distinct targets forces
     `root == t₀ ∧ root == t₁`, UNSAT by unit propagation alone, multipliers never consulted.
     Measured: the 80 x-free and 12 const·const-mul residual classes went extinct at once.
  3. **THE SHIFT BOX** — a constant whose every occurrence is a shift AMOUNT has live box {0..w}
     (≥ w saturates identically — the SVIR shift law): total exhaustion, natively, ≤ 65×65
     candidates; `bb_equal` on battery survivors costs zero clauses (concrete shifts are bit
     remaps). Subsumes the no-constant shapes (an absent constant's box is {0}).
  4. **THE HYBRID BOX** — the shift/multiply coupling (`(x⟪c)·c'`, `(x·c)⟫c'`, both nestings):
     pin the amount constant to each box value and every multiplier operand goes concrete (fold /
     cmul); the ≥ w tail is PROVABLY the constant-0 function (the saturated operand feeds an
     absorbing op — 0·y=0 — or the saturation IS the outer op), so the w representative covers the
     whole tail, data occurrences of the pinned constant included (annihilated). The last 20
     residual classes (16 `shift·mul`, 4 `mul⟫shift`) die here.
  5. **THE BUDGET** — the one class whose synth genuinely needs a FULL multiplier per sample
     (outer mul, const co-operand, an inner MIXING x and a constant) runs permanent seeds
     `{0, 2^(w−1)}` — `t(0)=0` forces the zero-divisor structure, `t(2^(w−1))=1` forces the
     multiplier constant ODD — plus one sliding refinement slot: three multipliers, the
     proven-feasible envelope of the unchanged caps. (The top-bit seed must be WIDTH-RELATIVE: a
     fixed 2⁶³ masks to 0 at width 8 and collapses the window — caught by the certificate, R 0 4.)
- **THE CERTIFICATE** (unchanged discipline): `mr64_validate8b` — the omega2 per-shape verdict
  equals the TOTAL width-8 brute oracle over all 3,456 classes, **rot AND neg: 0 disagreements,
  0 undecided**. Every mechanism above (sharing, boxes, pins, tail representative) is exercised
  against ground truth at width 8 before width 64 is trusted.
- **THE RESULT** (width 64, ~52 s — FASTER than Ω's partial sweep): **ALL 3,456 shape-classes
  REFUTED — 0 undecided, 0 matches** (`O2 omega64 refuted 3456 decided 3456 undecided 0 matches 0`).
  NO 2-op program over the full 8-op ALU grammar computes rot₁ at the machine word. With the Ψ
  63/63 definiens (≤3) and the sealed width-8 exhaustion: **cost₆₄(rot₁) = 3 EXACTLY — the question
  queued since Ξ9, settled TOTALLY at the machine word.** The undecided-sid store (`mr64_undat`, a
  refusal keeps its coordinates) is pinned EMPTY.
- **THE CENSUS AT TEN TOKENS** (`mathesis_census` envelope 7 → 10: permutation slots 8 → 12, flood
  cells 64 → 144; `bc_render` digit scratch 64 → 128 bytes; gate 2728): Burnside over Sₙ in exact
  bigint, the two independent routes (permutation flood / cycle-type partition arithmetic) agreeing
  to the digit at n = 8, 9, 10 — **n = 10 full = 2755731922398589065255809763441934634394385899578
  014939091916518138245006100594169510342419300 (94 digits): the exact iso-count of 10¹⁰⁰ binary
  operations — a googol of tables — without enumerating one** (comm = 275573192243078336761544940
  8031031255131879354330, 49 digits). The LIFTED organ is re-anchored to the sealed Ψ values first
  (n=5 exact i64 both flavors, n=7 full digit-for-digit); n=11 refuses BY NAME.
- **THE PATTERN INSTRUMENTS ON THE NEW GROUND** (gate 2729): the γ-orbits of Ψ's both-curve
  discoveries COMPLETED and bigint-verified — d=20 A: 9 finds → 12 points (4 orbits, 3 partners
  beyond height 60), d=30 A: 18 → 21 (SEVEN orbits, the richest carrier), d=50 B: 7 → 9 (3 orbits);
  the norm-prime law extends (d=20 carries {2,3,19,5,17,269,2287}, d=30 ten distinct primes incl.
  492319, d=50 {3,5,19,2,2287}) — **2287 appears on BOTH curves of the involution pair {20,50}: the
  class law's prime signature**; and **THE INVOLUTION CLASS LAW is CONFIRMED over the WHOLE [2,50]
  box — all seven pairs {x, x² mod cubes}, zero refuting witness** (`mp2_invol_box`, on top of the
  box's sealed 133 finds re-derived in-gate).
- **THE PILOT AT 30** (gate 2730, gate_slow): rounds 24–29 purely from the schedule — **round 24
  chose d=22 and found A:4: THE SIXTH AUTONOMOUS DISCOVERY** (the box sweep's independent find,
  reached by the pilot's own NEW-D schedule); round 27 d=23 EMPTY (the prime 23 joins the
  nonexistence inventory); rounds 25/28 are NAMED schedule refusals (kind 9 — a refusal keeps its
  coordinates, still a chained row). THE PREFIX LAW held (head(24) == the sealed Ψ head byte for
  byte) and **head(30) = b78b28fb… pinned across two full runs**.

**What Ω-2 establishes**: the machine-word 2-op synthesis question over the FULL ALU grammar is now
TOTALLY decided for the canonical rotation — no residual, no caveat, the deciding engine re-proven
sound + complete against total ground truth — and the encoding discipline that did it (sharing,
saturation boxes, hybrid pinning, odd-forcing seeds) is a reusable vocabulary for making SAT-hard
structure tractable WITHOUT touching solver capacity. The census now speaks to ten tokens by pure
arithmetic. **Named frontier out of Ω-2**: rot_k for k ≠ 1 at width 64 (the engine is k-generic;
63 sweeps ≈ an hour of gate_slow — priced, not run); the census at n = 11+ (the partition route
scales; only bc_render's digit pool prices it); the pilot past 30.

## 24. CAMPAIGN Ω-3 — THE UNIVERSAL ROTATION THEOREM (gates 2731–2735, stage [18], OMEGA3_CERT)

Ω-2 settled cost₆₄(rot₁) = 3 totally; the engine is k-generic. Ω-3 pays the priced frontier in
full: the theorem lifted from the canonical rotation to the WHOLE family.

- **THE EXTENDED CERTIFICATE** (gate 2731 [A]): the omega2 per-shape verdict equals the TOTAL
  width-8 brute oracle for **EVERY width-8 target — neg AND all seven rotations k = 1..7** —
  8 × 3,456 = **27,648 verdicts, 0 disagreements, 0 undecided**. Every mechanism (sharing, the
  shift box, the hybrid box, the odd-forcing budget) is certified against ground truth over the
  whole target family, not two representatives.
- **THE UNIVERSAL SWEEP** (the range door `mr64_omega3(klo,khi)` — accumulating counters that
  never average an undecided away; three gate-sized partitions, ~15 min each): 62 rotations ×
  3,456 shape-classes = **214,272 width-64 decisions — EVERY class refuted, 0 undecided,
  0 matches** (k=2..22: 72,576; k=23..43 incl. the half-word swap k=32: 72,576; k=44..63:
  69,120). NO 2-op program over the full 8-op ALU grammar computes ANY rotation at the machine
  word. With the sealed Ω-2 k=1 settlement and the Ψ 63/63 definiens (≤3):

      **cost₆₄(rot_k) = 3 EXACTLY, FOR EVERY k ∈ 1..63 — THE UNIVERSAL ROTATION THEOREM.**

  The question Ξ9 opened as "2 ≤ cost(rot_k) ≤ 3" (THEOREM-0005, one-op refutation) is CLOSED at
  the machine word, universally: a rotation costs exactly three ALU operations, and the machine
  proved both bounds itself — the upper by bit-blasting its own three spellings, the lower by
  synthesising-or-refuting every two-op candidate shape against its own SAT solver, the engine
  certified sound + complete against total ground truth at every width-8 target first.
- **THE CENSUS AT ELEVEN TOKENS** (gate 2734; the guard was the ONLY price — the standing arrays
  already held n=11: CE_M/CE_CL indices 0..11, 121 ≤ 144 flood cells, 119 digits < 128 render
  scratch): Burnside over S₁₁ in exact bigint, the two independent routes agreeing to the digit —
  **n=11 full = 2554813404371419256462759235989806049241336561476597962339572572520808268732253
  4509496712372506123634918408242423944102 (119 digits): the exact iso-count of 11¹²¹ ≈ 10¹²⁶
  binary operations** (comm: 62 digits); the n=10 anchor re-verified byte-identical against the
  sealed Ω-2 digits; n=12 refuses BY NAME (arrays 16, render 192, a 479M-permutation flood — the
  next envelope turn, priced).
- **THE PILOT AT 36** (gate 2735, gate_slow): rounds 30–35 — **round 30 chose d=25, the
  involution partner of the empty d=5, and CONFIRMED the class law's emptiness prediction from
  its own schedule**; **round 33 chose d=26 and found A:3 — THE SEVENTH AUTONOMOUS DISCOVERY**
  (2·13, the box sweep's independent find reached by the pilot's own NEW-D schedule); rounds
  31/34 named schedule refusals. THE PREFIX LAW held (head(30) == the sealed Ω-2 head) and
  **head(36) = aa4e38be… pinned across two full runs**.

**What Ω-3 establishes**: the first UNIVERSAL exact-cost theorem of the mathesis arc — not one
rotation, not a sample, but the entire family, with the deciding engine's soundness proof
extended to every target the ground-truth oracle can express. The pilot has now confirmed the
involution class law from its own schedule (d=25) — the machine's conjecture engine and its
autonomous experimenter closing a loop no human steered. **Named frontier out of Ω-3**: the
census at n=12 (the 479M-perm flood ≈ 40+ min/flavor — a priced gate_slower tier, or the
partition route alone with a stated single-route scope); 3-op cost questions (the CEGIS door
generalises: cost(rot_k ∘ rot_j)? cost of byte-swap?); the pilot past 36.

---

*Sister docs: `III-COMPLETION-PLAN.md` (Φ), `III-MEANING-LIFT-MAP.md` (Θ), `III-GRAND-UNIFICATION-MASTER-PLAN.md`
(Ω/Σ), `III-GENERATIVE-FRONTIER.md`, `III-EXACT-SUBSTRATE-INTEGRATION.md`, `III-CONJECTURE-FACULTY-AND-CAPABILITY-PROOF.md`,
`III-WALLS-CASHED-IN.md`, `III-LOGIC-GRAIL-LEDGER.md`, `DOCS/MATH_LIBRARY_QUEUE.md`, `DOCS/MATHESIS-RADICAL-ROUND1.log`,
`DOCS/MATHESIS-RING-DRAIN.log`, `DOCS/MATHESIS-CURVE-ROUND1.log`, `DOCS/MATHESIS-TAU-ROUND1.log`,
`DOCS/MATHESIS-FORGE-ROUND1.log`, `DOCS/MATHESIS-PILOT-LEDGER.log`, `DOCS/MATHESIS-ONTO-ROUND1.log`,
`DOCS/MATHESIS-PHI-ROUND1.log`, `DOCS/MATHESIS-CHI-ROUND1.log`, `DOCS/MATHESIS-PSI-ROUND1.log`.*
