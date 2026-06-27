# III — "Encoding the Laws of Physics" : Verdict and the Real Deliverable

**Date:** 2026-06-26
**Scope:** Adjudicates the proposal to "teach III the laws of physics" by mapping physical law onto
III's compiler primitives (E-graph / SVIR / B3 amputation / the SMT guillotine), then builds the one
genuinely sound, in-domain capability the proposal points at.

This document follows the house discipline (`feedback_crosswall_prose_runs_hot`,
`feedback_test_binary_not_comment`): every claim is tagged **VERIFIED** (a corpus KAT exits 99 against
the in-tree `iiis-2`), **REFUTED** (shown false on concrete grounds), or **ANALOGY** (a motivating
picture, never a claim about what the code proves).

---

## 1. The claim, split in two

The proposal conflates two very different assertions. They must be separated to engage honestly.

### 1.1 The framing claim — *"represent physical structure as relational/causal graph data"*

**Status: LEGITIMATE, and already load-bearing in III.**

Representing a system as a graph of nodes with dependencies, then reasoning by saturation/rewriting,
is exactly what III's e-graph (`numera/egraph.iii`: bounded equality saturation + minimum-cost
extraction, with a `EGRAPH_SAT_INCOMPLETE` soundness flag) and its verification membrane already do.
The arc the proposal describes —

> observe the chaos → generalize the stable configuration → prove it over the whole state space →
> carry the proven fact instead of the chaos

— is implemented today as a closed loop:

| Phase | Module | Function |
|-------|--------|----------|
| FUZZ (observe) | `numera/ser_petri.iii` | `sp_fuzz_det` walks a transition `T`, records reached states |
| GENERALIZE | `numera/ser_antiunify.iii` | Plotkin lgg → a candidate invariant (modular / interval / bitmask) |
| PROVE | `numera/ser_kinduct_sym.iii` | `sks_prove`: the miter `P(x) & ¬P(T(x))` UNSAT over **all 2⁶⁴** |
| AMPUTATE | `numera/ser_antiunify.iii` | `au_crush_*` replaces a proven-closed-form orbit by its O(1) result |

Exercised end-to-end by corpus `2065/2066/2070` (with a *conscience line*: the prover **refuses** an
over-general candidate the samples happened to fit). Applied to **transition-system invariants and
compiler rewrite rules** — its real, sound domain.

### 1.2 The complexity claim — *"therefore physics is solved in O(1) by amputation"*

**Status: REFUTED. Building it "for real" would mean shipping a fake — the opposite of the no-stubs mandate.**

Concrete grounds:

- **"Solves reality / turbulence in O(1)" (the supersonic-wing example).** Existence-and-smoothness of
  3D Navier–Stokes is an *open Clay Millennium Problem*. Turbulence is not removable by hashing;
  "amputating the chaos" losslessly **is** the modeling error that LES/RANS/DNS exist to manage. There
  is no constant-time collapse of a turbulent flow to its minimum-energy geometry.
- **"III proves the neutron stable over 2⁶⁴ states."** Color confinement is bound to the Yang–Mills
  mass-gap problem (also open). Lattice-QCD cost is empirical, not an artifact of poor representation.
  A discrete "fractional-charge edge cancellation" does not capture SU(3) gauge structure.
- **Charge / EM / quarks as e-graph edge cancellation.** Metaphor, not Maxwell or QCD. Equality
  saturation reasons about **program equivalence under a fixed semantics** — it does not numerically
  integrate PDEs with controlled error, which is what a physics solver must do.

The category error: a compiler's e-graph proves *two programs compute the same function*. A physics
engine *integrates differential equations / solves variational problems* under an error budget. These
are not the same machine, and no amount of "ontological translation" makes one into the other.

**Conclusion of §1:** there is no new "physics engine" to build that would be real. The honest move is
to (a) refute the complexity claim to zero, and (b) extract the one sound, in-domain capability the
framing genuinely points at, and build *that* to grade.

---

## 2. The real deliverable — linear conservation invariants

Stripped of the physics mysticism, the load-bearing idea in *"the fractional charges +2/3, −1/3, −1/3
sum to exactly zero"* is a **linear conservation invariant**: a weighted sum `Σ wᵢ·xᵢ` held *constant*
across every transition — a **relation between** state components.

III's invariant generalizer previously had only **single-scalar** templates (modular / interval /
bitmask): each bounds *one* component's reached values. None can express a relation *between*
components. This is the genuine, non-redundant gap. (Sweep confirmed: "conservation" elsewhere in-tree
means *capability conservation* / *conservative soundness*, never a conserved quantity.)

### 2.1 The mathematics (sound over Z/2⁶⁴)

For a coupled transition `x' = x + a, y' = y + b`, the functional `F(x,y) = w₀·x + w₁·y` is 1-inductive
(held constant) **iff**

```
w₀·a + w₁·b ≡ 0  (mod 2⁶⁴)
```

because `F(x+a, y+b) − F(x,y) = w₀·a + w₁·b`, which is **independent of (x,y)** — so the step preserves
`F` for *every* pair iff that constant drift is zero. The gradient `(w₀,w₁)` is the kernel of the
increment `(a,b)`; its primitive form is `(b, −a)` (since `b·a + (−a)·b = 0` exactly). This is the
relational sibling of the existing modular closed form (`sks_mod_step_linear`).

### 2.2 What was built (this turn)

Additive to the **existing** three organs (no new island, acyclic graph preserved):

- **`ser_petri.iii`** — multi-component observer: `sp_fuzz_det2` walks a *coupled* `(tx,ty)` transition
  with simultaneous update, recording `(x,y)` pairs on a parallel y-stream (`sp_obs2_*`, `sp_obs_y_at`).
- **`ser_antiunify.iii`** — relational lgg: `au_consv_w0/w1/c/found` discover the kernel from the first
  observed step and **verify it against every observed pair** before the prover is troubled. Vacuity
  (no motion / zero kernel) and spurious-fit pairs are rejected (conscience line intact).
- **`ser_kinduct_sym.iii`** — **two independent prover engines**, which must agree:
  - `sks_consv_step` — the closed form `w₀·a+w₁·b==0` (production route, no bit-blast wall);
  - `sks_consv_step_sym` — a genuine **2-variable bit-blast miter** proving `F(x+a,y+b)==F(x,y)` over
    all 2¹²⁸ pairs (`bb_equal` UNSAT), built over `bb_var(0)=x, bb_var(1)=y` with multiplier-free
    shift-add weights. It *actually quantifies over (x,y)*, so a flaw in the closed-form algebra would
    surface here as a SAT miter — this is the non-tautology guarantee, two different machines.
  - `sks_consv_drift` — the checkable counterexample-to-induction (the exact nonzero defect; 0 iff
    conserved).
- **`ser_pipeline.iii`** — `svp_conservation()` **structurally gated** in `svp_autopoietic_wave`
  (remove it and the wave's verdict changes). NOTE (no overclaim): the wave *binary* is un-runnable here
  (pre-existing ~1.25 GB BSS, `exit 126`), so the wave's **runtime** load-bearingness is **UNVERIFIED** —
  the conservation *engine* is runtime-proven (`2073`=99); the wave wiring is structural only.

**Non-tautology note (locked):** the *discovered* kernel `(b,−a)` satisfies `w₀·a+w₁·b≡0` by
construction, so the closed-form check is trivially true for it. The **teeth** are therefore in the
arms that use **explicit** weights `(1,1)` with *differing* increments — the bit-blast engine proves
`x+y` conserved under `(+1,−1)` and **refuses** it under `(+1,−2)` with a nonzero drift. Two arms,
different verdicts, different engines.

### 2.3 Runtime verification

- Corpus **`2073_invsynth_conservation`** drives the full loop: fuzz `x'=x+1,y'=y−1` → discover
  `x+y` conserved → prove by both engines → refuse the non-conserving `(+1,−2)` candidate (drift = −1)
  → vacuity guard → a hand-supplied coupled trace → **and the end-to-end prover `sks_consv_prove`
  exhibits BOTH outcomes** (accept the true law, refuse the non-conserving candidate). Registered `=99`.
- Corpus **`2036_seraphyte_pipeline`** transitively exercises `svp_conservation` via the wave.

> **RUNTIME STATUS — VERIFIED (2026-06-26, in-tree `iiis-2`, linked against `libiii_native.a`):**
> - `2073_invsynth_conservation` → **EXIT 99** (the 2-variable bit-blast miter `sks_consv_step_sym`
>   actually executes and agrees with the closed form; the conscience refusal and vacuity guard fire).
> - Regression — the **entire blast radius** (every corpus test linking the four edited modules
>   `ser_petri`/`ser_antiunify`/`ser_kinduct_sym`/`ser_pipeline`) green: `2018/2020/2031/2032/2033/2034/
>   2037/2038/2057/2060/2064/2065/2066/2067/2068/2069/2070/2071/2072` → **EXIT 99** each (21 consumers).
>   The edits are purely additive, so the ~580 tests that do not link these modules are unaffected by
>   construction. (The full ~600-test corpus run is killed by the pre-existing BSS commit-pressure, not
>   a logic failure — so the blast-radius set is the authoritative regression here.)
> - `svp_conservation` (the wave gate) is verified **by equivalence** — it calls exactly the primitives
>   `2073` proves on the same conserved example. The full-pipeline binary `2036` cannot be exit-checked
>   in this environment due to the **pre-existing** ~1.25 GB-BSS commit-starvation (`exit 126`, see
>   `feedback_corpus_commit_starvation_not_defect`) — a *load* failure of the gospel-scale pipeline,
>   not a logic defect, and unrelated to the one-line gate added here.

---

## 3. The memory integration — capacity conservation (precise scope)

The follow-on direction: wire conservation into the memory-reasoning layer (the "B2 causal
tensorization" membrane) so an allocator's `Size(free) + Size(used) = capacity` becomes a *proven*
invariant, tagging the block **Conservatively Sealed**.

### 3.1 What it is — and is NOT (locked scope)

- **IS:** a proof that the allocator's **count bookkeeping never drifts** across the transition —
  every alloc/free moves exactly one unit between the free and used tallies, so `free+used` is
  invariant over all 2¹²⁸ states. This catches an **uncompensated** leak/double-count (count *drift*).
  It does **not**, by itself, catch a count-*preserving* identity swap (lose cell 3, spuriously gain
  cell 8 → sum still `cap`); that corruption is caught by the **spatial** half — `heaplet.hl_disjoint`
  + `sep_logic`'s frame rule (`sl_frame_holds`) proving the free/used regions do not overlap and that an
  allocated write is framed off the free region. The two halves together are the seal; neither alone.
- **IS NOT (ANALOGY only — "death of the borrow checker"):** it does **not** prove temporal safety
  (use-after-free), and even with disjointness it is **not** Rust's guarantee (Rust forbids *holding a
  reference across a free*). Capacity conservation is **complementary** to aliasing discipline, not a
  replacement. The "death of the borrow checker" phrasing is the proposer's framing, retained here as
  analogy and **never** asserted in code, comment, or as a verified property.

### 3.2 The soundness spine (non-negotiable)

The seal is only meaningful if the abstract counters are **tied to the actual heap**. Two disconnected
true facts ("counts conserve" + "sizes match at one instant") wearing one badge is exactly the
"test that cannot express the attack" failure (cf. the zkVM-LDT audit). Therefore the KAT must:

1. perform an **actual** `hl_` move (a cell from the free heaplet to the used heaplet),
2. recompute `hl_size(free)` and `hl_size(used)` and confirm the sum **matches the conserved
   prediction**, and
3. include a **conscience case** where the counts conserve but the heaplets **overlap** (or their sizes
   diverge from the counters) — and that case must make the seal **FAIL**.

n-ary conservation (`free+used+reserved`, and the 3-component "neutrality" base-eval — the
`2·u − d − d = 0` quark picture as **ANALOGY**) is bounded to a fixed module array (n ≤ 8), kept in
`ser_kinduct_sym` over raw `u64` (bv_bits only — no upward dependency, so the cartographer cycle gate
stays green); the heaplet/sep_logic composition lives in the KAT and the `svp_` apex.

> **STATUS — BUILT & VERIFIED (2026-06-26):** corpus **`2074_consv_memory_seal`** → **EXIT 99**.
> It drives: pointer-offset conservation (two cursors, the gap `x−y` invariant); n-ary capacity
> conservation `free+used+reserved=cap` with a **leak refused** (drift ≠ 0); the quark-neutrality
> base-eval (ANALOGY); the seal on a **real heap** — `hl_disjoint` ∧ `hl_size` sum = cap ∧
> `sl_frame_holds` — then a **real `hl_` free→used move** whose recomputed sizes match the conserved
> prediction (count↔heap spine); and the two conscience cases — **overlap** (`hl_disjoint=0`) and
> **leak** (size sum ≠ cap) — that **break** the seal. `svp_mem_seal` (the apex/wave gate) is verified
> by equivalence (it calls those exact primitives + the same masks); like `svp_conservation` it cannot
> be exit-checked through the ~1.25 GB-BSS pipeline binary (`2036` → `exit 126`, pre-existing).

---

## 4. Files touched

- `STDLIB/iii/numera/ser_petri.iii` — `sp_obs2_reset/push`, `sp_obs_y_at`, `sp_fuzz_det2`
- `STDLIB/iii/numera/ser_antiunify.iii` — `au_consv_dx/dy/w0/w1/c/found`
- `STDLIB/iii/numera/ser_kinduct_sym.iii` — `sks_consv_step/base/prove/drift`, `sks_wmul`,
  `sks_consv_func`, `sks_consv_step_sym`; **n-ary**: `sks_consv_set/combine/step_vec` (bounded `[u64;8]`)
- `STDLIB/iii/numera/ser_pipeline.iii` — `svp_conservation`; **memory seal** `svp_mem_build`/
  `svp_mem_state_sealed`/`svp_mem_seal`; both wired into `svp_autopoietic_wave`
- `STDLIB/corpus/2073_invsynth_conservation.iii`, `STDLIB/corpus/2074_consv_memory_seal.iii`
  (+ both registered `=99` in `run_corpus.sh`)

### 4.0 Build & coverage status (honest)

- **Module compilation: `FAIL = 0`** — all 742 stdlib modules (incl. the four edited) compile under the
  in-tree `iiis-2`; `libiii_native.a` aggregates.
- **A transient build-script failure was diagnosed, not coded around:** OneDrive corrupted
  `build_stdlib.sh` *mid-run* (a syntax error at a syntactically-valid line, no CRLF, git-clean, after
  742 successful compiles — `feedback_onedrive_build_corruption_freshcopy`). Re-run from an
  OneDrive-immune fresh copy: clean.
- **The coverage ratchets are RED on PRE-EXISTING uncommitted WIP, not this work.** `uncovered=58`,
  `dark-surface=130` contain **none** of the conservation symbols (verified against `_cov_report.txt` /
  `_cov_reach_report.txt`); they are `au_netlist_*`/`au_conform_*`/`aff_*`/… in files `git status`
  showed modified *before* this session. The **one** in-scope item — `sks_consv_prove` flagged
  under-proven (only its accept arm was exercised) — is **fixed**: `2073` now also drives its refuse
  arm. The whole-tree ratchet remains red on the pre-existing surface (out of scope to burn down here;
  touching those live-WIP files would risk clobbering uncommitted edits).

---

## 4a. Rigor descent (iii-math-conscience) — theorem-to-machine

Per the six-rung obligation (statement → hypotheses → discharge → realization → falsifier → verdict):

1. **Statement.** `∀ w₀,w₁,a,b ∈ ℤ/2⁶⁴ :  (∀ x,y : w₀(x+a)+w₁(y+b) ≡ w₀x+w₁y  (mod 2⁶⁴))  ⟺  w₀a+w₁b ≡ 0 (mod 2⁶⁴)`. Proof: the step difference `w₀a+w₁b` is independent of `(x,y)`, so the universally-quantified equality holds iff that constant is 0.
2. **Hypotheses.** (i) the transition is additive with **constant** increments `(a,b)`; (ii) arithmetic is mod 2⁶⁴ (wrapping); (iii) weights are constants; (iv) for the bit-blast engine, the weights' shift-add stays within bv_bits node capacity.
3. **Discharge.** (i) `au_consv_found` (ser_antiunify) verifies the first-step delta holds for **every** observed pair — a non-constant-increment trace fails it; (ii) all ops are `u64` wrapping in `sks_consv_*`; (iii) parameters; (iv) `sks_consv_step_sym` maps the `bb_equal` capacity-poison (`0xFF`) to `0` — never a false "conserved".
4. **Realization.** `sks_consv_step` (closed form), `sks_consv_step_sym` (2-var bv_bits miter), corpus `2073`.
5. **Falsifier (teeth).** Inverting the closed-form comparison reddens `2073` arm (c)/(d); mutating **one** engine is caught by the dual-engine cross-check arm (the two must agree on a true and a false case). The seal's teeth are the conscience negatives: overlap → `hl_disjoint=0` → seal 0; size-mismatch → seal 0 (corpus `2074`).
6. **Verdict.** **PROVEN-IN-CODE** for the conservation theorem and the memory seal: `2073` → 99 and `2074` → 99 against the in-tree `iiis-2` (the binary shown it, not self-attested), with the dual-engine cross-check executing and the conscience/leak/overlap negatives firing. The two **apex wave gates** (`svp_conservation`, `svp_mem_seal`) are **PROVEN-BY-EQUIVALENCE** (identical primitives + examples as `2073`/`2074`); their only-via-`2036` exit-check is blocked by the pre-existing ~1.25 GB-BSS `exit 126` load failure — an environment limit, not an undischarged hypothesis.

**Unstated hypothesis (adversarial pass, recorded):** the seal proves conservation **of the designated
free/used partition** — it does not *discover which* cells are truly the freelist. A human/harness
points the observer at the quantities; the candidate is then verified and proven. This is the same
"propose → dispose" scoping as every lgg here, made explicit.

## 5. One-line verdict

> The proposal's *physics-in-O(1)* is refuted to zero on first principles. Its sound core — a **linear
> conservation invariant**, discovered by fuzzing and proven over the whole state space by two
> independent engines — is a real, non-redundant extension to III's invariant synthesizer, built into
> the existing loop and gated by a non-tautological KAT. Its memory image is a **capacity-conservation
> seal** that proves bookkeeping consistency (a genuine, complementary guarantee — *not* the borrow
> checker).
