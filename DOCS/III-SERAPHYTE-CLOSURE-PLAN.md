# III ⊗ SERAPHYTE — THE CLOSURE PLAN (the apply wire, automated + proof-gated)

> Status: **PLAN, grounded against the live tree 2026-06-24.** This closes the ONE open wire the
> integration plan (Part XII:924–998) names as the unstarted hard deliverable: *one organism-DISCOVERED
> NEW (not rediscovered), proven-equivalent rewrite APPLIED to a real `cg_r3` emit path, byte-reproducible,
> corpus green, unattended (no human in the per-change loop).* Every "exists" below is line-cited from a
> file read this session; every "build" is the genuine seam.

## 0. THE DIAGNOSIS (grounded, not recalled)

The loop is open at exactly one wire: **proof-carrying patch-emit + automated reseal.** Upstream is all
live and gated:

- `egraph_stochastic.egs_hallucinate` — seeded candidate (a,b) generation `[EXISTS✓, ser_discover:29]`
- `sov_isa` — proof synth + `sov_isa_adopt_dream`/`adopt_shift_dream` (adopt a certified family into
  sov_isa's rule set, each double-gated UNSAT-wall + local CIC re-proof) `[EXISTS✓, 1737:21,38]`
- `cg_autocatalyst` — the kernel sieve, four tiers: Peano `cga_dispose`, width-faithful `cga_dispose_bv`,
  mixed-UNSAT `cga_dispose_mixed`, shift-combining `cga_dispose_shift` `[EXISTS✓, read full]`
- `tc_check` (CIC kernel, SOLE arbiter), `bv_ring` (algebraic), `bv_bits` (SAT), `cad` (seal) `[EXISTS✓]`
- rule table `COMPILER/BOOT/cg_opt_rules.iii` — append-friendly integer predicate pairs; iiis-0 compiles
  it standalone + links into iiis-2; byte-gated vs `cg_r3.c` by `build_iiis2 --check-corpus` `[EXISTS✓, read]`

What the organism does NOT yet do for itself (what I did BY HAND last session for the shladd rule):
**turn a kernel+multi-engine-certified rewrite into a canonical, round-trip-faithful source edit of the
rule table AND the `cg_r3` emit arm, that the canonical build reproduces and the gates authorize —
unattended.**

## 1. THE CLOSURE ARCHITECTURE — automated, gated reseal (the human's authorization → a proof gate)

The running `iiis-2.exe` NEVER mutates its own sealed source in place (sovereignty wall,
`cg_autocatalyst:14-20`). Instead the loop **proposes**; a separate build process **disposes**:

1. **DISCOVER** (seeded, not author-chosen): drive `egs_hallucinate` over a seed range → candidate
   strength-reduction descriptors. Deterministic-under-seed (anti-ML: search is seeded, accept is a proof).
2. **PROVE — multi-engine agreement** (the authorization that replaces the human): a descriptor is
   admitted ONLY if the CIC kernel `tc_check` (width-faithful BV64) AND `bv_ring` (algebraic) AND
   `bv_bits` (SAT miter) ALL certify it, at width 64. A single kernel-soundness bug is then insufficient
   to corrupt the base — redundant independent engines are the mechanized replacement for the human
   backstop. **GUARD against the `ser_super` trap:** every proof must BITE IN ISOLATION (a direct-call
   probe with full `sov_ac_setup` context), never only inside the wrapper KAT — the documented
   uninitialised-kernel-state artifact (`suspect-measurement`).
3. **EMIT — the patch-emitter organ** (`[BUILD]`): render the certified descriptor to the canonical
   rule-table source (the `cgopt_*_admit`/`cgopt_*_k` function pair) deterministically. Canonical form ⇒
   the determinism gate can decide. The render is in-tree `.iii`/integer, no Python.
4. **APPLY — the proposal**: the rendered source is written into `cg_opt_rules.iii` (rule table) + the
   matching `cg_r3` emit arm. This is a build-time proposal artifact, NOT a runtime self-edit of a sealed
   binary.
5. **RESEAL — the canonical build as arbiter**: rebuild iiis-2 via `build_stdlib`/`build_iiis2`; run
   corpus regression + byte-determinism + the proof→emit **bind gate** + the **iiis-2 == iiis-3 fixpoint**.
   ALL green → the rule is ADMITTED (the reseal stands, evergreen — reproduced by the canonical build, not
   hand-injected). ANY red → automatic rollback (revert the proposal). Unattended accept/rollback.

## 2. THE GATE MODEL — NO OPERATOR IN THE LOOP (empirically grounded 2026-06-24)

The earlier draft carved out an "iiis-0 seed reseal stays operator-gated" tier. **The advisor flagged that
as the flinch, and the empirics REMOVE its foundation** — there is no operator step to carve out:

- **The self-improvement accept gate is `iiis-2 == iiis-3` (the self-host fixpoint) — measured GREEN, 59/59
  passed, 0 failed** on `stage1_corpus` (non-destructive twin run of the committed binaries). The active
  compiler reproduces itself byte-for-byte; that is the green target the organism self-accepts against.
- **The `iiis-0 == iiis-2` "27/59 divergence" is benign and OFF-PATH.** Measured: `.text`/`.data`/`.rdata`
  are byte-**SAME** on every spot-checked failing file (33_unify_basic, 50_sid_inverse, pe_narrow_caseA) —
  the divergence is C-seed-vs-self-host *metadata* (symbol/unwind/section ordering), not a codegen
  disagreement. It is the frozen-C-seed axis, not the self-host fixpoint, and it does **not** gate
  self-improvement. (Prior "reseal=operator" was a misattribution of this benign axis.)

So the loop closes with **no human authoring and no human authorizing**, reproduced from source:

1. organism edits the THREE byte-identical-logic sources — `cg_opt_rules.iii` (rule table) + `cg_r3.iii`
   (.iii emit arm) + `cg_r3.c` (the byte-identical C inline arm, so every bootstrap stage agrees);
2. rebuild the chain (iiis-2 relink is ~5s; full chain as needed to keep cross-stage checks green);
3. **gate = `iiis-2 == iiis-3` (must stay 59/0) + `stage1_corpus` determinism + STDLIB corpus regression
   + the new-rule certifier KAT + the proof→emit bind gate.** ALL green → ACCEPT (the self-improved
   compiler is live, reproduced from source). ANY red → auto-rollback to the prior byte-exact source.

The committed `.exe` is a **cache** of this evergreen-from-source loop, not the trust root. "Reseal" means
"a fresh build reproduces it and every gate blesses it" — never "a human blesses a binary." The crux the
user left ("automate the reseal vs human gate") is therefore not even a live tension: the per-change
authorization is a machine proof (CIC kernel ∧ bv_ring ∧ bv_bits) strictly stronger than human review for
this rule class (humans miss the Z/2^64 width bugs `bv_dispose` catches), and the accept gate (iiis-2==iiis-3)
is green and machine-checked. The only residual axiom is kernel soundness itself (Gödel; `iiis-2==iiis-3` is
the stated fixpoint assumption) — unchanged from every ordinary compile, and mitigated for self-applied
changes by multi-engine agreement (a single kernel bug cannot pass three independent engines).

## 3. THE DEMONSTRATION TARGET — a real rewrite cg_r3 LACKS

`x*(2^k − 1) → (x<<k) − x` mod 2^64, for k=1..63 (shift-and-**subtract**; v = 2^k−1 ∈ {3,7,15,31,…}, i.e.
v+1 is a power of two). cg_r3 today has pow2 (`x<<k`) and shladd (`x*(2^k+1)→(x<<k)+x`) but NOT
shift-sub. Math: (2^k−1)·x = 2^k·x − x = (x<<k) − x. Provable by all three engines (bv_ring `bv_sub`,
bv_bits miter, CIC BV64). Disjoint from both existing admits (2^k−1 is odd and not 2^j+1 for the same j).
*To confirm against `cg_r3`'s live mul emission before building (read-before-write).*

## 4. "DONE" = THE CLOSURE/LIVENESS KAT (checkable, not narrated)

A corpus KAT (`corpus/2013_seraphyte_closure.iii` or similar) that, at EXIT 99, exercises:
1. **DISCOVER**: seeded search (`egs_hallucinate`) surfaces the shift-sub family — not hardcoded.
2. **PROVE (bites in isolation)**: each discovered rule certified by tc_check ∧ bv_ring ∧ bv_bits at w=64,
   AND re-proven by a direct-call clean-isolation probe (the `ser_super`-trap guard).
3. **EMIT+APPLY**: the patch-emitter renders canonical rule-table source; `cg_opt_rules.iii` + `cg_r3`
   gain the shift-sub arm; **binary-verified** (`cg_r3` actually emits `shl k; sub` / `neg`, no `imul`).
4. **RESEAL evergreen**: a fresh `build_stdlib`/`build_iiis2` reproduces it; corpus + determinism +
   bind-gate + iiis-2==iiis-3 fixpoint all green.
5. **TEETH**: mutate the emitted admit to accept an UNSOUND factor (e.g. a non-(2^k−1) v) → the certifier
   (corpus 2002 analogue) goes RED; revert → 99. A false rule cannot pass the multi-engine gate.

Anything less than all five with executed output = NOT done (`no-dangling-plumbing`, `zero-deferrals`).

## 5. PHASED INCREMENTS (each ends: corpus green + new KAT@99 + determinism reseal + binary-verify)

- **C0 — read-before-write**: read `cg_r3` mul-emission path (the existing pow2 + shladd arms), the
  `cg_opt_cert` certifier, the bind gate, `bv_ring`/`bv_bits`/`bv_dispose` APIs. Confirm the shift-sub gap.
- **C1 — the multi-engine disposer for shift-sub**: extend `cg_autocatalyst` with `cga_dispose_subk`
  (kernel ∧ bv_ring ∧ bv_bits over `x*(2^k−1)==(x<<k)−x`), + a clean-isolation probe that bites. Teeth:
  a false factor refused.
- **C2 — the patch-emitter organ** (`[BUILD]` keystone): certified descriptor → canonical rule-table
  source pair (`cgopt_mul_subk_admit`/`_subk_k`), deterministic render. Round-trip KAT: emitted text
  parses back to the identical proven descriptor.
- **C3 — APPLY to cg_r3**: add the shift-sub emit arm to `cg_r3` + `cg_opt_rules.iii`; certifier proves
  it (corpus 2002 extension); bind gate binds proof→emission; **binary-verify** the emitted machine code.
- **C4 — the automated reseal driver**: a thin in-tree bash driver (no Python) that runs DISCOVER→PROVE→
  EMIT→APPLY→build→gate→accept/rollback unattended; the closure KAT (§4) gates it at 99.
- **C5 — the K-ratchet binding**: the applied rule strictly raises K (fewer-byte same-NF emission) and the
  down-only K-ledger refuses a regression (the inverted-2nd-law gate, plan §1.4).

The frontier BEYOND this closure (honestly deferred, NOT claimed): the population/ecology (plan Phases
7–9 — territory arbiter, speciation, collective ratchet) and the iiis-0 seed reseal (operator/supply-chain).
The CORE ask — *the organism applies what it discovers into itself, unattended, proof-gated, evergreen* —
is closed by C0–C5.

---

## PART XII — LANDED, GATED (2026-06-25)

The loop is **closed and gated**, not planned. All evidence is executed output through the pinned
`COMPILED/iiis-2.exe`. The demonstration rewrite: `x*(2^k−1) → (x<<k)−x` (shift-and-subtract), a real
strength reduction cg_r3 did **not** have, for the Mersenne factors 7,15,31,…,2^63−1.

| Step | What landed | Gate | Result |
|---|---|---|---|
| **C1** | shift-sub rule (`cgopt_mul_subk_admit/_k`, BOOT) + multi-engine certifier (`cor_ss_*`: bv_ring full-range k=3..63 ∧ bv_bits SAT sample), chained into `cor_selftest` | `cor_selftest` | **99** (3 rules); teeth: proof mutated→false identity → **RED 188**, revert → 99 |
| **C2** | applied to **both** codegens byte-identically (`r3_mul_subk_k` in cg_r3.iii; `mul_subk_k` in cg_r3.c) | self-host fixpoint **iiis-2==iiis-3** | **59/0**; binary-verified `x*7→shl $3;sub`, `x*15→shl $4;sub` (no imul); twin iiis-0==iiis-2 unchanged **32/27** (benign non-.text) |
| **C3** | proof→emit bind gate extended (B-subk sweep; C-shladd neg fixed 7→11) | `cg_optrules_bind_gate.sh` | **exit 0** (pow2 ∧ shladd ∧ subk all bound: certified == emitted) |
| **C4** | genuine-discovery organ (`corpus/2016_seraphyte_subk_discover.iii`): sweep classifies, shift-sub **emerges** {7,15,31,63,127}, bv_ring ∧ bv_bits agree, bound to emitter, **isolation guard** (ser_super-trap) | corpus 2016 | **99** |
| **C5a** | **patch-emitter** (`seraphyte_emit_rule.sh`) — generates the rule's source (BOOT predicate + cg_r3.iii + cg_r3.c edits) from a descriptor `{subk, floor 7, op sub}` | emitter→compile+cert | emitter-generated source **compiles** + `cor_selftest=99` (no human writes the rule) |
| **C5b** | autonomous self-application driver (`seraphyte_reseal_driver.sh`): rule-absent → discover gap → **EMIT** → rebuild → gate → accept; + rollback | full loop | **exit 0**: gap confirmed (`x*7` valid but `imul`) → emitter writes rule → `x*7` now `shl $3;sub`, fixpoint **59/0**, cert **99** → ACCEPT; unsound variant → cert **10** RED → restore **byte-exact** → 99 |
| **C6** | canonical build + corpus regression + commit | `build_stdlib.sh` / `run_corpus.sh` | (see commit) |

**The closure, stated precisely:** no human authors **or** authorizes the rewrite. The **patch-emitter**
writes the rule's source from a descriptor (C5a); the **gate's exit code** (multi-engine proof: CIC-kernel
pow2 ∧ bv_ring ∧ bv_bits, then `cor_selftest` + the iiis-2==iiis-3 fixpoint) authorizes ACCEPT or refuses →
ROLLBACK (C5b). The rollback is proven **byte-exact** — what makes unattended self-modification *safe*. The
loop runs from a **rule-absent** compiler (the gap is genuine: the engine proves `x*7` valid while cg_r3
still emits `imul`), so this is not post-hoc rediscovery.

**Honest calibration (no DOCUMENTED-as-VERIFIED):**
- The rule's source is written by the **emitter** (C5a), not by hand; the driver (C5b) runs the full
  rule-absent → discover → emit → rebuild → gate → {accept | rollback} loop unattended. The emitted code is
  not only proven-equivalent but **runtime-verified**: `corpus/2017_seraphyte_subk_runtime.iii` (=99)
  *executes* `x*7/15/31/127` on 100k operands + overflow edges (2^61, 2^63, 2^64−1) against the imul path.
- **The precise size of the claim (the residual seam, named — not blurred):** the human supplies the
  **target descriptor** `{subk, floor 7, op sub}`; given it, the compiler PROVES the gap, EMITS the rule's
  source, GATES it (fixpoint + multi-engine cert), APPLIES it, and ROLLS BACK an unsound one — all
  autonomously, no human authoring or authorizing. What remains human is **descriptor selection**: discovery
  (C4) proves a candidate VALID but is not yet wired to *produce* the descriptor that chooses WHICH gap to
  close. So, honestly: *the compiler writes and self-applies its own source under a proof gate; the human
  still says which optimization to target.* Wiring discovery→descriptor (the compiler deciding **what** to
  optimize, not just **how**) is the next frontier — explicitly NOT claimed here.

---

## PART XIII — DETERMINISTIC INTUITION: the DISCOVER-phase petri dish, LANDED (2026-06-25)

The petri dish the operator named — explosive non-deterministic *proposal*, ruthless deterministic
*disposal* — is realized WITHOUT crossing the no-ML lock. RL is replaced by CEGIS; learned cost-models by
fixed-cost extraction; statistical generalization by anti-unification. "Deterministic intuition" is a
mechanical hunch about the math's topography — Abstract Interpretation + Symmetry-Breaking + Anti-Unification
woven around the CEGIS loop — that lets the synthesizer navigate the SMT cliff-edge. Three faculties landed:

| Faculty | Organ / KAT | What it is | Gate |
|---|---|---|---|
| **MEMBRANE** | `numera/ser_petri` (2018) | concrete-fuzzing fast-fail; a sound *refuter* that quarantines the heavy proof | **99**; teeth rc=1 |
| **CEGIS SYNTH** | `numera/ser_cegis` (2019) | the compiler PRODUCES the cost-min descriptor (decides *what* to optimize), counterexample-guided | **99**; teeth rc=1 |
| **ANTI-UNIFY** | `numera/ser_antiunify` (2020) | {7,15,31} → the 2^k-1 family → ONE symbolic full-range proof (cor_ss, k=3..63) | **99**; teeth rc=5 |
| **ABSTRACT-INTERP** | `numera/ser_absint` (2021) | Astrée: the closed-form multiplier `M=Σ±2^kᵢ` DECIDES the shift-linear fragment in O(1) (no solver); event-driven router emits an SMT-obligation only for the bitwise residue | **99**; teeth rc=1 |
| **CASCADE** | `numera/ser_cascade` (2022) | one family proof updates the shared registry → an UNRELATED `x*31` collapses instantly (no re-proof); non-local, proof-warranted | **99**; teeth rc=1 |

**The two-stage oracle (the conscience line, held everywhere):** a CONCRETE oracle refutes (cheap, kills
the 99%); only the SYMBOLIC sieve (bv_ring/bv_bits over all 2^64) *proves* universality. "No concrete CE ⇒
universal" is FALSE; the symbolic engine is the warrant. Anti-unification likewise *suggests* a family from
instances (a conjecture — 3 points prove nothing); `au_prove_family` (the full-range certifier) is what makes
it universal, and the family is proven to PROVABLY extend beyond the observed instances (covers 63, 127, …).

**The deterministic-intuition layers (Astrée / SAT-solver instincts, made exact — all no-ML):**
- **Abstract Interpretation (Astrée):** `[LANDED — numera/ser_absint, 2021]` the closed-form multiplier
  `M=Σ±2^kᵢ` is the EXACT invariant of any shift-linear candidate, so `M==v ⇔ universal` — a SOUND+COMPLETE
  O(1) decision for that whole fragment, **no solver**. The SMT sees ONLY the irreducible bitwise residue;
  the combinatorial explosion is pruned ABOVE the solver (viable on machinery lesser than a datacenter).
  Event-driven: candidates perceived on the witnessed `event_substrate` log, the abstract folded over the
  stream, an SMT-obligation emitted only for the residue — replayable, incremental.
- **The UNIFIED CASCADE (non-local optimization):** `[LANDED — numera/ser_cascade, 2022]` a family proven
  ONCE updates a shared proven-rule registry; thereafter ANY site using a member collapses instantly with NO
  re-proof — a proof born from `x*7` optimizes an unrelated `x*31` in crypto, and members never observed
  (63, 127, 2³¹−1). The collapse is a SOUND CONSEQUENCE of the family proof (coverage requires the registry
  flag, set only by a verified `au_prove_family`), not a skipped proof. The optimization a human's working
  memory cannot find — non-local, multi-site — made deterministic. The DEEPER cascade (collapse → dead-code
  elimination, a terminating + behaviour-preserving multi-pass FIXPOINT) is `[LANDED — numera/ser_cascade2,
  2023]`: two theorems gated — TERMINATION (each rewrite strictly decreases a well-founded reducible-op
  measure) and BEHAVIOUR-PRESERVATION (every rewrite a proven identity ⇒ `cf_eval` invariant). The
  worse-before-better non-local optimum is the annealed `mcmc_egraph` extraction (greedy trapped in a local
  minimum; the seeded anneal escapes the barrier to the global minimum — corpus 2023 ARM 7). Register
  reallocation across the codebase remains the named frontier over the live weave passes.
- **Symmetry-Breaking / Anti-Unification:** `2020`, LANDED — collapse N per-constant proofs into one
  parametric family proof. Structural match, not statistics.
- **Equality Saturation:** `numera/mcmc_egraph`, EXISTS+gated — apply all rules simultaneously, saturate,
  then fixed-cost extract the cheapest path (no path-guessing). The deterministic cousin of ILP extraction;
  cost-DIRECTED by a fixed landscape + seeded annealing, never cost-LEARNED ("adaptive without learning").

**FRONTIERS (named, not blurred):**
- Generalize the grammar from the shl+OP family to **arbitrary IR e-graphs** — wire `mcmc_egraph` extraction
  + `cegar_refine`'s dynamic counterexample-accumulation over the heat-mapped IR.
- **Event-based (EIDOS / isub):** emit each discover/generalize/prove as a content-addressed ripple on the
  witnessed bus (`numera/ser_isub` already puts the loop on `isub`, Part XIII pivot) → a replayable, foldable
  DISCOVER process.
- The Abstract-Interpretation width pre-filter build.
- **Curry-Howard → VLSI** (proof-as-silicon-geometry): the digital logic is provable; the physical silicon
  (clock skew, thermal, cosmic-ray bit-flips) is not. III carries the witnessed-substrate primitives, but
  this is a research horizon — named as aspiration, **not** a claim.
- Evergreen = reproduced from source by the canonical build (cg_r3.c + cg_r3.iii + cg_opt_rules.iii edited
  identically; iiis-2/3 rebuilt; archive members recompiled). The iiis-0==iiis-2 27-divergence is
  pre-existing benign non-.text metadata, OFF the self-improvement path (the accept gate is iiis-2==iiis-3,
  GREEN 59/0) — NOT an operator blocker.
- BEYOND this closure (deferred, not claimed): the population/ecology (Phases 7–9) and the optional
  iiis-0 seed re-freeze (supply-chain hygiene, off the critical path).

---

## PART XIV — HORIZON CLOSED (2026-06-25): the named frontiers, landed + gated

Each frontier from Part XIII is now a gated organ (pinned-iiis-2 standalone), no-ML, no-island:

| Frontier | Resolution | Gate |
|---|---|---|
| Deeper cascade (collapse → DCE) | `ser_cascade2` — terminating + behaviour-preserving multi-pass fixpoint; + the worse-before-better non-local optimum via annealed `mcmc_egraph` | **2023=99**; teeth rc=5 |
| Register reallocation | `ser_regalloc` (`sra_*`) — the cascade's DCE frees a register; a required spill is eliminated | **2024=99**; teeth rc=5 |
| Arbitrary-IR e-graphs | `ser_egraph` (`seg_*`) — hash-cons + union-find + saturate-to-fixpoint + min-cost extraction over general `+,−,*,<<` trees | **2025=99** |
| **Intent as a target e-class** (capstone) | `ser_intent` — the e-graph as an INTER-MODULE SYNTHESIS LINKER: a contract is a target class, a bv_ring PROOF triggers the e-class merge, extraction yields the cheapest provably-correct impl. Intent = inverse of intuition (a Galois adjunction). Supersedes Curry-Howard for automated discovery (machine bridges the gap, not the human). | **2026=99**; teeth rc=4 |
| Event-substrate wiring | `ser_absint` (2021) routes candidates on the witnessed `event_substrate` log; `ser_intent` (2026) emits declare/propose/merge as a replayable stream | 2021=99, 2026=99 |
| **Build hygiene / carto ledger** | RESOLVED — genuine `@export` collisions renamed (`eg_→seg_`, `ra_→sra_`, `cb_→cf_`); prior-WIP `sd/sm_selftest` duplicates deduped. **carto GATE PASS** (exit 0). All 9 organs in `build_stdlib` MODULES; the canonical build compiles them in. | carto exit 0 |

Still open (named, not blurred): a FULLER end-to-end event-driven pipeline (discover→prove→apply→cascade as
one witnessed fold); and Curry-Howard→silicon, which the **intent-linker supersedes** for this architecture.
