# III — The Assimilation Scope: what of the stdlib can be unified into the Master Logic Web, and what cannot
### An architectural pass on "also all others" — the honest structural boundary of unification
> **Date:** 2026-06-20 · **Author pass:** /architect · advisor-disciplined
> **Grounded in (read, not recalled):** `III-LEGACY-VS-INVERSE-STRUCTURE.md`, `III-COMPONENT-AUTHORING.md`,
> `III-INVERSE-LIBRARY.md`; `omnia/assimilate.iii`, `omnia/master_logic.iii`, `omnia/enmesh.iii`;
> `numera/{logic6,voice,trit,interval_lattice,cost_lattice,reduced_product,widening}.iii`; the 672-module
> `build_stdlib.sh` MODULES manifest.

---

## 0. THE QUESTION, AND THE REFRAME THAT PRECEDES IT

"Feed `numera`, `logic6`, `forcefield`, and every other STDLIB organ into the Assimilation Loop" (Blueprint
Phase 5). Taken literally — assimilate **all 672 modules** into one web — this is the wrong goal, and III's
own source says so. `III-LEGACY-VS-INVERSE-STRUCTURE.md §0`: *"the vast majority of III is legacy
state-primary and stays that way; an event-sourced `vec` would be absurd overhead… the inverse substrate is
a specialized substrate for one region of competence."* So the architecturally honest question is not "how
do we unify everything" but **"exactly which organs share the structure the Master Logic Web is built for,
and where is the boundary?"** This document draws that boundary from the actual module shapes.

---

## 1. WHAT THE WEB STRUCTURALLY REQUIRES OF AN INGESTIBLE SYSTEM

`omnia::assimilate` is not a universal unifier — it is a **finite bounded-lattice** unifier. Its atoms are
uniform blocks `<verb ∈ {BELOW, REFLECT}, a, b>` over **bare point addresses**, and its recovered verbs are
`meet`/`join`/`complement` over that finite order. A system is **ingestible iff** it presents:

- **(R1) a partial order** (a `BELOW` relation), so `meet`/`join` are recoverable;
- **(R2) an order-reversing involution** (a `REFLECT`/complement), so `complement` is recoverable;
- **(R3) a FINITE, enumerable carrier** — the web stores points as addresses and must list them to merge by
  content-address. *This is the binding constraint.*

(R1)+(R2) = "is it a De Morgan / ortho lattice." (R3) = "is its element set finite and small." The proven
ingestions (`logic6` 6 values, `voice` 3 values) satisfy all three. Everything else fails at (R1) or (R3).

---

## 2. THE STRUCTURAL CENSUS — three tiers of the 672 modules

| Tier | Shape | Count (approx) | Examples | Assimilable? |
|------|-------|----------------|----------|--------------|
| **T1 — Finite logics** | finite bounded lattice + involution (R1+R2+R3) | ~3–6 | `logic6`, `voice`, `trit` (+ any finite multi-valued logic) | **YES — fully** (carrier + ops into the web; proven 1918/1924) |
| **T2 — Infinite lattices** | lattice ALGEBRA but **infinite/large** carrier (R1+R2, **¬R3**) | ~6–10 | `interval_lattice`, `cost_lattice`, `reduced_product`, `widening`, `range_check`, `value_range_prover` | **PARTIAL — law-level only** (see §3) |
| **T3 — Non-lattice organs** | handle-table / typed-value / stream — no order (¬R1) | ~640 | `vec`, `map`, `bigint`, `sha256`, `cad`, `crystal`, `cg_r3`, all crypto/containers/codegen | **NO — and should stay legacy** |

T3 is the bulk and is **correctly** legacy (`III-LEGACY-VS-INVERSE-STRUCTURE §0/§6`): forcing event-sourcing
or a meet/join web onto a hash table or a bigint is pure overhead with no competence gain. The realizable
unification lives entirely in **T1 (fully) and T2 (at the law level)**.

---

## 3. THE SHARP BOUNDARY — finite carrier vs infinite lattice (the new finding)

The abstract-interpretation family is genuinely lattice-structured — `interval_lattice` is literally *"a
sound lattice"* with `il_join`/`il_meet`/`il_leq`; `cost_lattice` is a *"bounded partial-order lattice"* with
`cl_join`/`cl_meet`/`cl_bottom`/`cl_top`. **But their carriers are infinite** (all integer intervals; all
6-dim cost vectors). You cannot enumerate `[3,7]`, `[3,8]`, `[2,7]`, … into a finite point-web. So:

- **T1 (finite):** assimilate the **carrier AND the ops** — every value is a web point, every op a recovered
  verb. The name dissolves into "verb @ geometry" (proven: `master_logic` subsumes `l6_and` exactly).
- **T2 (infinite):** assimilate the **LAWS, not the elements** — the web hosts the *axioms* every lattice in
  the family obeys (associativity, absorption, De Morgan, `join`/`meet` duality, widening soundness `x ⊑
  x∇y`), expressed once in verb-geometry, and each T2 domain is *certified against* that one law-set rather
  than merged element-by-element. This is unification at the **signature/law** layer — real and valuable (it
  proves interval, cost, and product domains are *the same algebra*), but it is **not** "one web of all
  their points," and claiming so would be the over-claim the trajectory-audit retraction warns against.

**`reduced_product` is the convergence point worth naming.** It already *"lets two abstract domains tracking
the same value refine each other"* — i.e. it is the **legacy, state-primary precursor of `enmesh`**: combine
two lattices by their shared information. `enmesh` (content-addressed, witnessed, in the inverse form) is the
general form `reduced_product` is a hand-wired instance of. That is the genuine bridge between the optimizer's
existing lattice machinery and the Master Logic Web — not "replace reduced_product," but "recognize it as one
point on the line the web generalizes."

---

## 4. THE REALIZABLE ROADMAP (priority-ordered, each gated like Phases 0–5)

1. **T1 completion — `trit`, and the canonical-mapper depth it exposes.** `trit` (`iii_trit_and`=min /
   `iii_trit_or`=max / `iii_trit_not`=negate, values NEG/ZERO/POS) is confirmed the **same 3-valued Kleene
   algebra as `voice`**, only signed-encoded. The architecturally important finding: under the **current**
   `enmesh` mapper (frame-aligned via a fresh-address counter), `voice`'s middle → point 2 but `trit`'s
   middle → point 3, so they would share only the **frame** (bottom/top + the bottom↔top involution merge)
   and `trit` would still add its middle as 3 distinct blocks. **They are NOT recognized as the same algebra**
   — because the mapper aligns by FRAME ROLE only, not by full STRUCTURAL role. To make the web *know* `voice`
   and `trit` are identical (the "intrinsic knowledge of exactly what they share" claim at full strength), the
   canonical mapper must assign addresses by **structural role** — e.g. *the self-complementary middle*
   (`not(m)=m`) → one canonical slot — which is precisely `logos`'s `st_fits` footprint-matching, now owed in
   the inverse/content-addressed form. So roadmap #1 is really **two** gated steps: (1a) `enmesh_trit`
   frame-level (proves trit assimilates, shares the frame — the smallest increment); (1b) a **structural-role
   canonical mapper** so two differently-encoded copies of the same algebra fully coincide (the deeper, more
   valuable result). #1b is the honest frontier of "recognize what systems share."
2. **T2 law-web — the abstract-domain axiom set.** Express the lattice laws (absorption, De Morgan, widening
   soundness) once as verb-geometry, and certify `interval_lattice` + `cost_lattice` against that one law-set
   (a `master_logic`-style subsumption at the LAW level, over sampled elements, honestly scoped as
   "law-conformance," not carrier-merge).
3. **The `reduced_product` ↔ `enmesh` bridge.** Prove `enmesh`-of-two-finite-domains reproduces
   `reduced_product`'s refinement on a finite instance — making the convergence a gated fact, not a remark.
4. **STOP at T3.** Do **not** assimilate containers/crypto/codegen. The architectural law: *a module enters
   the web only if it satisfies R1+R2+R3 (full) or R1+R2 (law-level); otherwise it stays legacy and the
   inverse substrate at most ENCAPSULATES it* (à la `xii_isub` over `xii_rewrite`) when reversibility/
   provenance is the actual need.

---

## 5. DECISION LOG

- **ADR-1: SELECTIVE assimilation, not universal.** The web unifies T1 fully and T2 at the law level; T3
  stays legacy. *Consequence:* "one master logic of ALL of III" is reframed as "one master logic of III's
  LATTICE/LOGIC family," which is the honest, achievable, still-significant unification (it unifies the
  verifier's and the multi-valued-logic family's algebra). *Alternative rejected:* event-source everything —
  refuted by the source as absurd overhead with no competence gain.
- **ADR-2: carrier-merge for finite, law-conformance for infinite.** Do not pretend an infinite lattice's
  elements enter a finite point-web. *Consequence:* T2 produces a certified shared law-set, not a merged
  carrier. *This is the line that keeps the claim honest.*
- **ADR-3: `enmesh` is the general `reduced_product`.** Treat the optimizer's domain-combination machinery
  as the same idea at a different point on the generality line; bridge, don't replace.

---

## 6. RISKS

| Risk | Mitigation |
|------|-----------|
| "Unify everything" pressure → forcing T3 into the web (the toy-lattice relapse) | The R1+R2+R3 gate is the law; a non-lattice has no `BELOW`/`REFLECT` to shatter — it simply cannot enter, and the coverage gate would flag a dead unwired organ |
| Claiming an infinite domain is "in the web" (over-claim) | ADR-2: T2 is law-conformance over sampled elements, labeled as such, never "the carrier was merged" |
| Re-deriving `reduced_product`/`interval_lattice` instead of bridging (no-islands) | Shatter their REAL behavior (the `enmesh`/`master_logic` discipline), never hand-author; bridge to the existing organ, prove subsumption |
| Treating this as "the inverse form supersedes the optimizer" | It does not — `III-LEGACY-VS-INVERSE-STRUCTURE`: different competence, encapsulation not replacement; T3 and the determinist keep their turf |

---

## 7. ONE-PARAGRAPH SUMMARY

"Unify the stdlib" resolves, on inspection of the actual 672 modules, to a **bounded** program: the Master
Logic Web ingests **finite bounded lattices** (T1 — `logic6`/`voice`/`trit`) *fully* (carrier + ops, the name
dissolved), and the **infinite abstract-interpretation lattices** (T2 — `interval`/`cost`/`reduced_product`/
`widening`) only at the **law level** (one shared axiom-set they all conform to), with `reduced_product`
recognized as the legacy precursor of `enmesh`; the **~640 non-lattice organs** (T3 — containers, crypto,
codegen) are *not* assimilable and correctly stay legacy, encapsulated only where reversibility/provenance is
the real need. The honest unification is "one master logic of III's **lattice/logic family**," not of all of
III — significant, achievable, and already proven for T1.
