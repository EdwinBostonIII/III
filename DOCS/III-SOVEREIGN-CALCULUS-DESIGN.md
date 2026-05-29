# III — The Natively Differentiable Sovereign Calculus (architecture)

*Post-QTT, post-pleroma. The next evolutionary leap: the "soul" stops being an
external oracle and becomes a **continuous semantic cost-field draped over the
discrete syntactic spine** — the file optimizes its own physical realization
without ever touching what it proves. This document is the /architect pass:
the leanest, no-bloat realization in the full context of what III already is.*

## 0. The interpretation gate (load-bearing — read first)

The vision's vocabulary is ML: "weights," "learned heuristics," "attention,"
"the files learn," "differentiable." **III's axioms forbid all of it** — no ML,
no observational/statistical learning, no floats, no statistics (pleroma's own
header; the convergence plan §0; a standing law). And the vision's OWN constraint
is decisive: *"optimizes its physical realization without ever violating its
formal proof."* A learned float field that changed behaviour would violate the
proof. Therefore the faithful realization is **not** machine learning. It is:

> a **deterministic, exact cost-field** over the AST, whose "differential" is the
> exact cost-gradient across the **proven-equivalent class**, descended to the
> cost-optimum by III's existing equality-saturation + cost-extraction engine,
> coherence-bound by pleroma, propagated by ripple — proof-preserving by
> construction, integer-exact, no floats, no learning.

The leap is real; "differentiable" means *the cost function admits an exact
descent direction among realizations that are provably equal*, not gradient
descent on observed data. "The files learn" means *the file carries its
cost-optimal realization and re-descends deterministically when a ripple
arrives* — not statistics. This is the only reading consistent with III's
soundness, and it is exactly what the existing organs already compute.

## 1. The Three Layers → III organs (everything reused, nothing invented)

| Vision layer | Faithful meaning | III organ (EXISTS) |
|---|---|---|
| **Discrete Spine** (logic) | the proven AST + dependent types + the conversion oracle | `numera/typecheck` (MLTT + QTT + W) + `numera/ccl` (singular oracle) |
| **Continuous Field** (semantics) | a deterministic exact **cost** per AST node + its proven-equivalent class | `cost_lattice` (cost) + `egraph` (`eg_saturate`/`eg_extract`, the class) + QTT multiplicities (resource cost) + `cad` (content-address of the node) |
| **Pleroma Binder** (coherence) | the field's chosen realizations don't contradict (H¹=0); changes propagate coherently | `forcefield/pleroma` (`pleroma_cohere`) + the ripple network (`forcefield/ripple` publish/resolve) + the P6 commit gate |

There is **no new ML/float machinery**. The "field" is `cost_lattice` values +
`cad` addresses attached to AST nodes by a parallel array (exactly the `TC_MULT`
pattern from QTT). The "soul" is that field; the "navigation" is cost-extraction.

## 2. The differential, made exact (the math — no floats)

Let `c : AST → ℕ` be the cost (from `cost_lattice`; for the kernel, derived from
node count + QTT multiplicities — ω-used subterms cost more, **0**-used (erased)
subterms cost **0**). A rewrite `r : t ↦ t'` is **admissible** iff it is
proof-preserving: `ccl_conv(t, t') = 1` (the singular CCL oracle certifies `t ≡ t'`).

- **The gradient** is the (finite, exact) set of admissible cost-*decreasing*
  rewrites at `t`. The "descent direction" is the one that decreases `c` most.
- **The optimum** is computed not by greedy descent but by the **egraph**:
  `eg_saturate` closes `t` under the admissible rewrite set into an e-class of
  provably-equal forms; `eg_extract` returns the **exact** cost-minimum of that
  class (`cost_lattice`). This is the global optimum *within the saturated class*
  (the Rice/NP ceiling: min within the class, tree-cost-exact — P3's recorded bound).
- **Termination**: the cost is well-founded (ℕ), and — crucially — the egraph here
  saturates the **optimization** rewrites (algebraic/ISA laws like `mul(x,2)≡shl(x,1)`,
  dead-erased-elimination), which are finite and terminating. It does **NOT**
  saturate β (β duplicates → blow-up; that is exactly why conversion was moved to
  the *directed* CCL reducer in B16–B18). The two roles are kept separate:
  **CCL oracle = equality**; **egraph = optimization**. This division is the whole
  reason the calculus is total.

So the "natively differentiable" calculus = `eg_saturate`(admissible rewrites) →
`eg_extract`(cost-min) → the realization `t*` with `ccl_conv(t,t*)=1` ∧ `c(t*) ≤ c(t)`.

## 3. The Sovereign morphism (the one invariant that makes it sound)

> **PROOF-PRESERVATION.** For every realization `t*` the field selects,
> `ccl_conv(t, t*) = 1`. The optimizer can only ever move within a CCL-equality
> class. The discrete spine (what is proven) is therefore **invariant** under all
> field activity; only the physical realization changes.

This is the formal content of "the weights never contradict the logic." It is
discharged *per optimization* by the CCL oracle — not asserted. It composes with
P6: a field re-optimization is admitted by the commit gate iff (rules confluent)
∧ (modules cohere, pleroma) ∧ (sealed, cad) ∧ (conservative) — and proof-
preservation is the strengthening of "conservative" for the realization layer.

## 4. The lean implementation (one thin module; no bloat)

`numera/sovereign.iii` — a **thin orchestration** over existing organs, exporting:

- `sov_cost(t) → u32`: the exact cost of a kernel AST `t` (node count weighted by
  QTT multiplicity — erased=0, linear=1, ω=k; reuses `tc_var_usage`/`TC_MULT`).
- `sov_descend(t) → t*`: compile `t`→CCL, `eg_saturate` the admissible optimization
  rewrites over the e-class, `eg_extract` the cost-min, read back to a kernel AST `t*`.
- `sov_admit(t, t*) → u8`: the Sovereign morphism check — `tc_conv(t,t*)==1`
  (proof preserved; `tc_conv` is the TC-level oracle — compile→reduce→struct-eq via
  the singular CCL reducer, *not* raw `ccl_conv` which takes CCL nodes) ∧
  `sov_cost(t*) ≤ sov_cost(t)` (cost improved-or-equal). The gate.
- the **field** itself: `var SOV_COST : [u32; …]` + `var SOV_ADDR : [u8; …]`
  (cad per node) — parallel arrays over the AST arena, BSS, exactly the `TC_MULT`
  pattern. Content-addressed, ripple-publishable, pleroma-coherent.

Total new surface: one module that *composes* `egraph` + `cost_lattice` + `cad` +
`ccl_conv` + `tc_var_usage` + `pleroma_cohere` + ripple. Nothing reinvented.

## 5. The KAT (positive AND negative — the falsifier)

`p5_kat_sovereign` (corpus 870):
- **descent improves**: a cost-suboptimal term `t` (e.g. an erasable mult-0
  redex, or `mul(x,2)`) → `sov_descend(t) = t*` with `sov_cost(t*) < sov_cost(t)`.
- **proof preserved**: `ccl_conv(t, t*) == 1` (the optimized form is provably the
  original) — and the **negative**: a *non*-equivalent "optimization" is REJECTED
  by `sov_admit` (e.g. `t* := wrong` → `ccl_conv(t,wrong)=0` → admit fails). This
  is the load-bearing falsifier: the optimizer cannot smuggle in a behaviour change.
- **monotone**: re-descending `t*` is a fixpoint (`sov_descend(t*) = t*`,
  cost-minimum reached) — the descent terminates at the optimum.
- **coherence**: the field over a small cover passes `pleroma_cohere` (H¹=0); an
  incoherent field is rejected (reuse the pleroma negative).

## 6. Ceiling (honest)

- Optimality is **bounded** (Rice: global optimum uncomputable; min *within the
  saturated class* under a tree-cost model — P3's recorded ceiling). Not "the
  optimal program," but "the cost-min of the proven-equivalent class explored."
- Proof-preservation is exact (CCL oracle) and total (the oracle is total).
- No floats, no ML, no statistics, no observation — the "field" is integer cost +
  content-address; the "learning" is deterministic re-descent on ripple. The
  vision is realized *as physics*, not as guessing.

## 7. Implementation log (what is built)

- **Brick 1 — DONE (gated).** The **Sovereign morphism**. `sov_cost` (exact node
  count, VAR/SORT early-return as their `A` is a payload not a child), `sov_best`
  (cost-min of `{t, nf}` — never blindly normalizes, since β is not size-monotone),
  `sov_admit` (`tc_conv ∧ cost↓` — the TC-level oracle, *not* raw `ccl_conv`). KAT
  `870`: proof-preserved descent, monotone fixpoint, the **falsifier** (a
  behaviour-changing `true→false` is REJECTED — proven non-vacuous: disabling the
  conv guard makes `870` fail *at the falsifier arm*). A real trap closed: `ccl_conv`
  takes CCL nodes; passing TC nodes reduces garbage — the wrapper is `tc_conv`.

- **Brick 2 — the weighted field (the vision's literal "Continuous Field").** The
  flat node count is replaced/augmented by the **erasure-aware runtime cost**
  `sov_cost_q`: type-formers (`Π/Σ/Id/Sum/W/U/Bool/Nat/Unit/Empty`) and
  type/proof-irrelevant *positions* (LAM domain `:A`, ANN type, every eliminator
  **motive** — `NATREC/CASE/J/TRANSP/ABSURD/WREC` `TC_A`) weigh **0**; runtime
  structure weighs 1. This is exactly the per-tag runtime/erased split `tc_var_usage`
  already computes — reused, inference-free. It is the literal "weights attached to
  specific AST nodes": the proof rides free, only the *physical realization* is
  costed. The field is **materialized** over the spine as `var SOV_COST : [u32;
  16384]` (parallel to the arena, the `TC_MULT` pattern) via `sov_field_fill(t)`.
  KAT `871`: (+) a big type-annotation / a motive / a type-former costs strictly
  less under `sov_cost_q` than the flat `sov_cost` (and a pure type costs 0); (−)
  **pure runtime data** (`pair(true,false)`) costs the *same* under both — the
  discount is type-specific, not a blanket reduction (the falsifier against a
  degenerate "everything-is-cheaper" field); and `SOV_COST[t]` equals the recomputed
  `sov_cost_q(t)` after fill (the field is faithfully draped over the spine).

- **Brick 3 — descent over the field: DONE (`numera/sov_isa`, gated KAT 874).** The
  analysis stands: for the **pure MLTT kernel** the proven-equal class under β is the
  reduction orbit, whose cost-min is always an endpoint (`sov_best`, brick 1, already
  extracts it) — a richer descent needs **non-β algebraic laws** (`mul(x,2)≡shl(x,1)`,
  identity elimination) that live one layer *below* the kernel. So rather than a
  contrived pure-kernel brick, the descent is realized over a **minimal arithmetic/ISA
  term layer**, which finally **wires the two organs `forcefield/optinvoke`'s header
  named as "the next brick"** (unbuilt until now):
  - **`numera/egraph`** — bounded equality saturation → the proven-equal class, then
    minimum-cost extraction (was self-tested but un-wired);
  - **`numera/cost_lattice`** — the 6-dim microarch cost-field (latency, throughput,
    regs, icache, dcache, energy) scalarized by a chosen order (was un-wired).
  `sov_isa_descend` saturates a term under SOUND algebraic rules and extracts the
  **min-cost proven-equal realization** — the **Sovereign morphism at the ISA layer**:
  the result is in the input's e-class (proof preserved — equal *modulo the sound
  rules*; the optimizer can only move within a rule-justified class, it NEVER fabricates
  an equality) AND cost-minimal. KAT `874`: a two-rule compose `add(mul(x,2),0) →
  shl(x,1)` (strict cost drop), the cost-field ranking `mul > shl`, and the
  **faithfulness falsifier** — *no rules ⇒ no descent*. The "differential" is the exact
  cost-gradient over the e-class; "descent" is min-cost extraction. Integer-exact,
  deterministic (bit-identical replay), no floats/ML. **The Sovereign morphism now spans
  both layers: kernel (CCL-equality, brick 1) and ISA (e-class-equality, brick 3).**

## 8. The three layers — completeness (honest)

The vision's three layers are realized; layer 3 needs no new brick:

- **Layer 1 — Discrete Spine (logic).** `numera/typecheck` (MLTT + QTT + W) +
  `numera/ccl` (the singular CCL oracle). Complete.
- **Layer 2 — Continuous Field (weights).** Brick 2: `sov_cost_q` + the materialized
  `SOV_COST` field. The literal "weights attached to AST nodes." Complete.
- **Layer 3 — Pleroma Binder (coherence).** *Already bound — by composition of organs
  that exist, not a new brick:*
  - **Proof-coherence is automatic.** The Sovereign morphism (`sov_admit`, brick 1)
    enforces `tᵢ*≡tᵢ` *per site*. By **transitivity of `≡`**, every realization of a
    shared subterm is mutually convertible — the field's sections agree on overlaps by
    construction (a coboundary; **H¹=0 holds, it is not merely checked**). Local
    soundness ⟹ global coherence is a *theorem*, discharged per-site by the oracle. A
    pleroma H¹ gate over convertibility-transitions would be **vacuous** (always
    identity) for any sound field — so it is correctly *omitted*, not added as bloat.
  - **Evolution-coherence is the P6 commit gate.** `forcefield/commit_gate` already
    composes `pleroma` (H¹=0) + `cad` (content-address seal) + `xii_admission`
    (conservativity) — the gate that admits a *field re-optimization* iff it coheres
    and is sealed. That IS "the H¹=0 forcefield managing how changes propagate," at the
    module/evolution granularity where holonomy is non-trivial (subsystem bridges, the
    original pleroma use-case) rather than the vacuous per-term granularity.

  Net: the "soul never contradicts the logic" is a **theorem** (per-site morphism,
  global by transitivity), and propagation/coherence of *changes* is the **P6 gate**.
  The Natively Differentiable Sovereign Calculus is complete on the pure kernel at
  bricks 1+2 + these existing organs, and its differential **descent is now built**
  (brick 3, `numera/sov_isa`) over a minimal ISA layer — all three layers realized.

## 9. Next enhancements (investigated; honest scoping)

With the Sovereign Calculus complete on the pure kernel, the next kernel evolution was
scoped. Two "obvious" η-completions were investigated and found **correctly absent**
(deliberate design, not oversights):

- **Σ-η (surjective pairing, `⟨fst p, snd p⟩ ≡ p`)** would break **confluence** —
  SP + β is the **Klop** non-confluence counterexample (`numera/ccl` header: *"we need
  exponential eta, not product eta; SP is the Klop-nonconfluence culprit"*). The singular
  oracle's soundness rests on its 14-critical-pair confluence certificate (`ccl_conf_cert`);
  adding SP-η would unsound the conversion engine. **REJECTED** (a regression, not a feature).
- **Unit-η (`u ≡ tt` for `u : Unit`)** is irreducibly **type-directed** (a neutral
  `x : Unit` must η-expand to `tt`, impossible without the type), mismatching the
  deliberately **untyped** singular oracle (B16–B18). It would require reintroducing
  type-directed conversion, conflicting with the consolidated single-engine design.
  **DEFERRED** (would need a typed conversion layer atop the oracle).

The kernel is otherwise complete for its scope (MLTT + cumulative `U` + Π-η + QTT + W +
the Sovereign field): transparent definitions are already the **DAG arena** (shared
node ids), and opaque constants are already **context entries** — neither is a new
capability. The genuine next arcs are each substantial (not quick bricks), confluent-safe,
and each deserves a focused start:

- **Sub-kernel ISA / arithmetic layer — DONE (minimal).** Built as `numera/sov_isa`
  (brick 3 above): const/var/add/mul/shl symbols + sound algebraic rules + the
  cost-field, reviving `egraph` + `cost_lattice`. The next increments on it (each lean,
  confluent-safe): a **richer sound rule set** (`x*1≡x`, `x*0≡0`, `x+x≡x<<1`, reassoc,
  constant folding) → a genuine peephole/algebraic optimizer; and eventually **wiring
  the descent into the codegen** (`cg_r3`) so emitted machine code is descended to its
  cost-min proven-equal realization (the largest difference, the most invasive).
- **Universe polymorphism** — level-parametric definitions. Confluent-safe (no reduction
  change); invasive in the sort representation + `tc_infer`/`tc_subtype` level arithmetic.
- **Indexed inductive families / coinduction (M-types, the dual of W)** — beyond the
  current inductive fragment; M-type conversion needs productivity + bisimulation.

## 10. Self-application — III certifies III (the optimizer's rules are kernel-proven)

*"How the III system itself can be used to enhance things": the Sovereign ISA descent's
one **asserted** premise was "the rewrite rules are sound." That assertion is now
**discharged by III's own kernel** — no premise, a theorem.*

- **The certificate.** Each ISA rule `lhs ≡ rhs` is modelled with the ops as Nat
  functions (`add a b = iter(a, succ, b)`, `shl1 a = a+a`, `mul a b = iter(0, λacc.add a
  acc, b)`), and proven by checking `λx:Nat. refl(lhs)` against `Π(x:Nat). Id Nat (lhs x)
  (rhs x)`. This type-checks **iff** `lhs` and `rhs` share a normal form — decided by the
  singular CCL oracle — so a free `x` (a neutral) certifies the *universally-quantified*
  identity (conversion is stable under substitution). KAT `875` certifies `x+0=x`,
  `x*1=x`, `x*0=0`, `x*2=x<<1`; the **falsifier** — a non-identity `x*2≡x*3` — is
  REJECTED by the kernel. The enriched optimizer (`876`) then uses exactly these
  kernel-certified rules to collapse `(x*1)+(x*0)` to a single leaf `x`.
- **The loop closes on itself.** The certificate is checked *through the bidirectional
  bricks* (LAM↦Π pushes the `Id`-Π into the `λx.refl` body; REFL↦Id verifies `lhs ≡ rhs`).
  III's proof-checker (brick 1) certifies III's optimizer (brick 3), via III's own
  recently-built checker rules (872/873).
- **The enhancement hardened the enhancer.** Building the certificate exposed a **latent
  soundness bug**: `tc_whnf` is `ccl_normalize` (full nf, misnamed), so the constructor
  rules' `tc_whnf(ty)` *normalized the expected type's open subterms*, and the CCL
  read-back **mangled a free variable under an inner λ** (so `whnf(t) ≢ t` for such `t`).
  Fix: **syntactic-first dispatch** in all six constructor rules (PAIR↦Σ, INL/INR↦Sum,
  SUP↦W, LAM↦Π, REFL↦Id) — `whnf` only to expose a *reducible* head; an already-formed
  type keeps its original components. Strictly more correct (whnf is for reducing a
  neutral head, not re-normalizing a formed type), and it removes the mangling. Gate-
  verified: full corpus green, no regression.

## 11. Proof-carrying optimization — egraph proposes, kernel disposes (nous, leashed)

*The synthesis of the codegen/nous direction: the optimizer becomes **proof-carrying**
by translation validation. The fast heuristic proposer (the egraph — "nous") is
**confined** by the trusted kernel, which independently re-derives `input ≡ output` as
a theorem and rejects anything it cannot prove. Nous gets full liberty precisely
because the proof system leashes it.*

- **`sov_lower(out_skeleton) → kernel Nat-term`.** Maps the egraph's extracted preorder
  (symbol slots) to the kernel Nat-model (`add=iter+succ`, `mul=iter+λstep` with the
  binder shift, `shl1=x+x`, `x=#0`, `cₖ=numeral`). The bridge from the untrusted
  optimizer's output to the trusted kernel's language.
- **`sov_pcc(input_egraph, input_model) → (output, certified)`.** Descend `input_egraph`
  (egraph, untrusted) → `output`; `sov_lower(output)` → `output_model`; **kernel-verify**
  `input_model ≡ output_model` (the 875 cert mechanism: `λx.refl` against `Id Nat
  input_model output_model`). Accept the optimization **iff** the kernel certifies it.
- **The discipline.** The egraph may be arbitrarily aggressive (heuristic, fast,
  *fallible*); soundness does **not** depend on the egraph being correct — only on the
  kernel's independent verification. This is **translation validation** / proof-carrying
  code at the algebraic-optimization layer. KAT: a real descent (`(x*1)+(x*0) → x`,
  `x*2 → x<<1`) is accepted *with its kernel proof*; a **tampered** output (an egraph
  that "optimized" to a non-equivalent term) is **REJECTED** by the kernel — the
  load-bearing falsifier (the leash holds even if nous lies).
- **Standards.** Stays off `cg_r3` (no bootstrap byte-drift). The lift of *emitted
  machine code* into this validator is the next increment, built **on** this foundation,
  behind the determinism seal — not before it.

## 12. `psi` — deterministic superposition (the no-downsides quantum-like invocation)

*Quantum computing needs hardware we lack; literal quantum software in III would be a
waste. But the **pattern** — superpose, interfere, measure — has a no-downsides
deterministic realization that III already has: **the e-graph**. `psi` makes it
first-class.*

| Quantum primitive | Deterministic `psi` realization | III organ |
|---|---|---|
| superposition (states at once) | the **e-class**: all proven-equal realizations, compact (exp-many in poly structure) | `egraph` (saturated) |
| simultaneous exploration | `eg_saturate` (whole class in one pass) | `egraph` |
| measurement / collapse | `psi_collapse` = cost-min `eg_extract` — **deterministic**, no probability | `egraph` + `cost_lattice` (the observable) |
| interference | min-cost DP + congruence (paths merge / prune) | `egraph` |
| entanglement | shared sub-e-classes | `egraph` congruence |
| **no decoherence** | the kernel **proves** every superposed state equal (coherence) | `typecheck`/PCC |

- `psi_of(root)`: register the (kernel-certified) rules + saturate → the superposition.
- `psi_card(psi)`: cardinality — how many realizations are held at once (`eg_class_size`,
  a new egraph export). `> 1` ⇒ a genuine superposition.
- `psi_collapse(psi)`: deterministic measurement → the cost-optimal realization. The
  cost-field/order is the observable; the collapse is reproducible (no probability).
- `psi_interfere(r1, r2, m1, m2)`: coherent merge — **only** if the kernel proves
  `m1 ≡ m2` (`sov_pcc_verify`); then `eg_union` + rebuild (constructive interference).
  A non-equal merge is **REJECTED** — superpositions never decohere into contradiction.
- `psi_coherent`: the no-decoherence guarantee = `sov_pcc` (the collapse is kernel-proven
  equal to the input).

**Honest ceiling.** This is the quantum *pattern* (superpose-equivalents → interfere →
measure-optimal), deterministic + coherent — **not** a quantum *complexity* speedup
(√N/Shor require amplitude interference in Hilbert space = hardware). The e-graph's
compression is classical sharing. But the pattern is exactly what a deterministic
optimizing/proving system wants, with the kernel guaranteeing coherence — the "no
downsides." No floats, no probability, no observation, no ML.

## 13. The contingent evolution driver — self-optimizing, change-propagating files

*The capstone: the Three-Layer file's vision realized end-to-end — files optimize their
physical realization and changes propagate, deterministically and coherently. Reuses
`psi` + the revived **ripple network** (`forcefield/ripple`, previously un-wired).*

- **self-optimize**: `psi_collapse` → the optimized form (deterministic measurement).
- **content-address**: `rn_publish` the optimized form → its address. Equal optima
  **converge** to one address (content-addressed dedup); a different optimum → a new
  address. `rn_resolve` retrieves it, tamper-checked.
- **propagate**: a computed cell's address = `H(input cells' addresses)`; `rn_ripple`
  recomputes to a fixpoint over the dependency DAG.
- **determinism (no drift)**: re-optimizing a source is deterministic — same optimum →
  same content-address → `rn_ripple` produces **no change** in dependents. The files do
  not drift on re-evaluation (no observation, no statistics — the design's §0 law).
- **propagation**: a genuinely different optimum → a new address → the change ripples to
  every dependent. 
- **coherence**: every optimized form is kernel-certified equal to its source (the
  certified rules, §10, + `sov_pcc`, §11) — evolution never changes meaning.

KAT `879` (`sov_evolve_kat`): publish+resolve; the cell-graph ripple; **determinism**
(re-optimize → identical address → dependent unchanged); **propagation** (different
optimum → dependent changes). Static buffers, no malloc; the ripple network brought up
to speed and intertwined with the optimizer.

**This completes the Natively Differentiable Sovereign Calculus end-to-end**: Discrete
Spine (kernel) → Continuous Field (`sov_cost_q`) → morphism (`sov_admit`) → ISA descent
(egraph+cost_lattice) → self-certification (the kernel proves the rules) → proof-carrying
validation (egraph proposes, kernel disposes) → superposition (`psi`) → evolution driver
(self-optimize + propagate). Every layer deterministic, coherence-bound by the kernel,
with no ML, no floats, no observation — and no asserted premise left standing.

## 14. Inductive reasoning — induction proposes, deduction disposes

*Can a deductively-perfect system reason INDUCTIVELY without breaking its mandates (no
ML, no observation, no statistics, no floats)? Yes — the same propose/dispose pattern,
lifted from optimization to **law-discovery**.*

- **Induction proposes (deterministically).** `iu_au` — **anti-unification**, the
  least-general generalization of a set of instances: identical → keep; same head →
  recurse; differing value-pair → a *shared* generalization variable (`iu_var_for`, so a
  law's lhs and rhs share their universals). A fixed algorithm — no statistics, no
  observation. The genuinely *ampliative* step (the conjecture has more content than the
  instances — the inductive leap).
- **Deduction disposes.** The conjectured universal `Π(x). Id A (L x) (R x)` is checked
  by the **kernel** (the §10 cert mechanism). Only kernel-**proven** conjectures are
  accepted; a false conjecture (from a coincidental/bad instance set) is **refuted**.
- KAT `880`: (a) anti-unification soundness (the generalization instantiates back to the
  instances, via `tc_subst0`); (b) from `{add(0,0)=0, add(1,0)=1}` III generalizes to
  `∀x. add(x,0) = x` and the kernel **proves** it — the right-identity *discovered and
  proven*; (c) the **falsifier** — a bad instance yields `∀x. add(x,0)=0`, **refuted**.
- **Searle, honestly.** "Syntax isn't semantics" objects that symbol-shuffling carries no
  meaning. In III, **Curry-Howard makes the syntax *be* the semantics**: a proof term's
  meaning *is* its proposition (type). Each inductively-discovered law is **grounded in
  its proof** — not a meaningless rewrite. III's inductive leaps are *meant* because they
  are *proven*. The honest claim is a concrete capability — **sound, ampliative
  law-discovery grounded in proofs**, beyond pure deduction (checking given laws) — not
  consciousness. III reasons inductively AND deductively at once; every leap kernel-verified.
- **Completion — discover → prove → USE, and MULTI-VARIABLE (KAT `881`, `iu_kat2`).**
  (1) **Learn→use**: the discovered `∀x. add(x,0)=x` is *proven*, ascribed as a usable
  **lemma** (`tc_ann(cert, conj)`), and **applied** — `tc_app(lemma, 2)` instantiates the
  universal (dependent-APP inference substitutes via `tc_subst0`) to prove the specific
  `add(2,0)=2`, while *rejecting* the false `add(2,0)=1`. The inductive leap feeds back
  into deduction: a learned general law becomes machinery for new goals. (2) **Multi-var**:
  from instances varying two arguments *independently* `{(0,succ 1),(1,succ 0)}`, `iu_au`
  introduces two distinct pair-keyed universals (shared across lhs/rhs), and the kernel
  proves the genuine 2-variable law `∀p q. add(p, succ q) = succ(add p q)`; the false
  variant (drop the `succ`) is refuted. The au-vars take the **natural** de-Bruijn
  assignment (`var_k = #k`) under the nested Π's — for a fully-quantified equation that is
  the correct, provable law (any consistent variable↔binder bijection preserves truth), so
  *no* index-remap is needed. (A speculative `iu_remap` was built then **removed as
  provably vacuous**: it cannot change the truth of a closed equation, and the only case
  where binder-assignment matters — au-vars *under* the term's own binders — is foreclosed
  upstream by `iu_var_for` anyway.) **Honest scope**: the engine generalizes at the term's
  **top level** (the natural locus of algebraic identities); generalizing *under* a term's
  own binders is a distinct capability (needs an au-var namespace disjoint from de-Bruijn
  indices) and is not claimed.

## 15. The singular oracle's read-back boundary (whnf-mangling) — sound-safe, characterized

*Found by dogfooding III on III (building the §10 certificate): `ccl_normalize` of an
**open** term whose free variable is processed under an inner λ can read that variable
back at a **shifted** de-Bruijn index — `conv(ccl_normalize(t), t) = 0` for such `t`.*

- **Root cause (precise).** The CCL engine reduces **combinators over a fixed ambient
  environment** — its design domain is *closed* terms. The read-back `ccl_to_tc` recovers a
  variable's de-Bruijn index from the **Fst-count** of its `Snd∘Fst^k` form
  (`ccl_rb_varidx`); `ccl_reduce` can leave that count shifted when a free variable flows
  through an inner binder that β-reduction consumes and the result is *neutral* (stuck), so
  the `Fst` that should have cancelled survives into the normal form. The read-back is
  faithful to the (shifted) combinator; the shift is the reducer's, on open input.
- **Why soundness is NOT affected (the load-bearing fact).** Conversion — `ccl_conv` →
  reduce both sides, then **`ccl_struct_eq`** — compares **CCL structure directly and never
  calls the read-back**. So `tc_conv` / `tc_subtype` / every typing equality is *immune*:
  both sides traverse the identical reduce+compare path, so equal terms compare equal
  regardless of any read-back shift. The mangling touches only `ccl_to_tc`'s callers:
  `tc_whnf` (head-exposure — now **syntactic-first-guarded** in `tc_check`'s six
  constructor rules, §10, so an already-formed type keeps its original components) and
  `tc_subst0` (exercised correctly across the whole corpus). No kernel judgment depends on
  standalone open-term read-back. The worked-around state is **sound and complete** for the
  type-checker.
- **Fix direction, assessed.** A reducer-free `close → normalize → strip` (wrap `t`'s
  `depth` free vars in λ-binders, normalize the closed term, peel the wrappers) was
  considered and rejected: `tc_to_ccl` compiles `#0 → Snd` *structurally* (depth-agnostic),
  so an outer wrapper-`Cur` does not interact with the *internal* β-reductions where the
  `Fst`-shift originates — the wrapped normal form is `λ̄. (same-shifted body)`, and
  stripping recovers the same shift. The shift is **wrap-invariant**. A genuine fix would
  require reducer surgery (cancelling a free variable's surviving `Fst` when its enclosing
  binder is β-consumed but the result is neutral) — a deep, high-risk change to the
  *singular* oracle for an issue that is **latent, sound-safe, and already worked around**.
  Per the kernel-change discipline, that is not warranted.
- **The deliverable (KAT `882`, `ccl_open_conv_kat`).** Rather than paper over or risk the
  oracle, the soundness boundary is **guarded by a falsifiable test**: `tc_conv` is proven
  *correct* on the exact open terms (free var under an inner λ) that mangle standalone
  read-back — `conv(mul·x·2, shl1·x) = 1` (equal, both `2·x`, *identified despite* the
  read-back boundary) and `conv(mul·x·2, mul·x·3) = 0` (unequal, *distinguished*). This
  proves the soundness-critical path (`ccl_struct_eq`, no read-back) is robust where the
  read-back is not, is non-vacuous (positive + negative), and would **fail if conversion
  ever regressed to route through `ccl_to_tc`** — a permanent guard on the §15 invariant
  that does not bake in the bug (it survives a future reducer fix unchanged).

## 16. Kernel-governed rule admission — the system subject to itself (no new machinery)

*The directive's deepest push: stop turning III's reasoning on *models* of III in self-contained
KATs; make III itself **subject to** its own reasoning. The realization came from **inventory,
not invention**: sound rule admission **already exists** — `omnia/xii_admission` (a
Knuth-Bendix-style gate: a rule set is admitted iff **root-confluent AND terminating**). What it
lacks is the one thing III's proof kernel uniquely provides.*

- **The gap.** `xii_admission` gates **operation, not meaning**: it admits *any*
  confluent + terminating rule — including a **meaning-changing** one (e.g. `add(x,0) → succ(x)`
  is a perfectly terminating, confluent rewrite, and `xad_decide(1,1)` admits it). Nothing in the
  admission stack checks that a rule **preserves meaning**.
- **The composition (no reinvention).** `xad_decide` (the existing operational decision, now
  exported) ⊕ `sov_pcc_verify` (the existing §11 kernel mechanism: the two sides are
  kernel-**proven** equal). `sov_admit_rule` admits a rule **iff** it is operationally admissible
  *and* kernel-proven meaning-preserving. III's rule admission is thereby made **subject to III's
  own proof kernel** — the rewrite engine can never adopt a rule the kernel cannot prove sound.
- **Both gates load-bearing (KAT `883`, two-sided).** The kernel **rejects** `add(x,0)→succ(x)`
  — which `xii_admission` *alone* admits (the gap, closed); the operational gate **rejects** a
  non-confluent / non-terminating rule the kernel proves sound. Each gate catches precisely what
  the other cannot see — the composition is non-vacuous.
- **What this is, honestly.** The *mechanism* — III's kernel governing rule admission — is
  complete and gated, demonstrated on the optimizer's Nat-model rules (`sov_lower`/`sov_m_*`).
  Extending the kernel-semantic gate to XII's *own* term algebra (the fusion/trit rules) needs an
  XII-term → kernel-model bridge — a distinct, larger capability, honestly scoped, not claimed
  here. But the principle is realized and wired from existing organs: **`xii_admission` ⊕ the
  kernel**, the Knuth-Bendix admission gate now answerable to the proof checker.

## 17. The bridge, BUILT for the trit fragment — verification on III's LIVE engine (KAT 884)

*§16 deferred "extending the semantic gate to XII's own term algebra." That deferral is
now retired for the fragment that has a finite semantic model. The verification is no
longer run on a Nat-model toy inside a KAT — it is run on **III's actual rewrite engine**,
the one `cg_r3` invokes.*

- **The strike (`omnia/xii_rule_verify.iii`, `xrv_verify`, corpus 884).** It drives the
  LIVE engine — `xii_term_make_fusion2` → `xii_canonicalise` (`xii_rewrite`'s real rule
  cascade) — over the entire trit ground domain (NOT/AND/OR/SUM/MUL), and verifies each
  rewrite against an **INDEPENDENT Kleene spec** (hardcoded ground-truth tables, *not* the
  `iii_trit_*` ops the engine calls).
- **Why it is the real thing, and corpus 670 was not.** `670_xii_trit` compared the
  engine's output to `iii_trit_*` — the very functions `apply_TRIT_*` invoke — so it was
  **tautological**: break `iii_trit_and` (return `a+b` instead of `min`) and 670 stayed
  green, both sides breaking together. 884's authority is *independent of the ops*, so that
  same break turns **884 red**. It verifies the soundness 670 structurally could not see —
  the live engine ≡ the independent semantic authority, end to end. **670 is now RETIRED**
  (corpus consolidation): its tautological per-op checks are strictly subsumed by 884's
  arms 1–10 (independent spec), and its one unique witness — the nested-reduction
  termination check `AND(AND(-1,1),0) → a single TRIT_VAL` — is folded into 884 as arm
  18/19, verified against the independent `XRV_AND_EXP` value, not `iii_trit_*`. The corpus
  now carries exactly one, non-tautological, trit gate — not a tautological one beside it.
- **Teeth (proven, not asserted).** Corrupting one independent-spec entry was shown to turn
  884 red at the AND arm (exit 2) — the gate genuinely checks the engine, not a constant.
  Plus: the engine computes AND *specifically* (its output at a cell differs from the OR
  spec); the rule's `TRIT_VAL` guard genuinely refuses an ill-formed operand (`AND(VAL, FORM)`
  does not reduce to a value); and `apply_one` confirms the live trit rule (id 102) fired.
- **Standards.** Additive, seal-neutral (a stdlib verification module over the live engine;
  `cg_r3` codegen untouched, no bootstrap byte-drift). The semantic-soundness half of
  `sov_admit_rule`, now applied to XII's *real* rules — III's verified authority governing
  III's real optimizer.
- **Honest scope + next.** The trit fragment is the rule family with a finite semantic
  model. The fusion/algebraic rules (associativity, IF-lift, identity/null) are governed by
  the confluence certificate (`xii_conf_cert`) + the K/cap/hexad/provenance preservation
  theorems — extending an *independent* semantic authority to them is the next strike.
