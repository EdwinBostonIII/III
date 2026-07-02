# Module 7 — XII, the one engine: file-by-file lean implementation plan
> **STATUS: HISTORICAL RECORD** — an executed campaign plan/ledger, kept immutable as evidence (reunification W6).

## Gate cleared

Written only because **Module 6 (the Witness & Commons) is verified fully + perfectly**: full
gate `PASS=390 FAIL=0`, `382_witness_hook=99` (codes 1–23: existing + provable-forgetting 16–22
+ the code-23 independent-recompute frag-id falsifier proving the cad-routing byte-identical),
`380_content_addr`/`13_mhash`/`219_witness_chain` all green. No placeholder/deferral/flaw.

## Context

**Why this change.** Module 7 of `DOCS/III-APOTHEOSIS.md` is **XII — the universal evaluator**.
The engine is *already complete and the most rigorous subsystem in III*: `xii_term` (the term
arena — `kind` ∈ K01–K18 Sovereign forms + F-fusions, `subform`, `child_a/b/c`, `aux`;
constructors `make_basis`/`make_fusion2`/`make_if`/`make_loop`), `xii_rewrite` (**40 sealed
reduction rules**, each a `match_RNNN`/`apply_RNNN` pair, fired R001..R040, **every rule strictly
decreasing MPO weight** → termination CRY-XII-TERM-001), `xii_critpairs` (**all 117 critical
pairs converge across 7 classes** → confluence by Newman's lemma, CRY-XII-CONF-001),
`xii_canonicalise` (normal form), `xii_curated_*` (pre-proven kernels), `xii_horizon` (144
patterns), `xii_emit_gen` (machine-code back-end). Sealed (`xii_rewrite.mhash`), K=1.0. Gated by
its **own** harness `run_xii_corpus.sh` (rc=0 = pass; tests 280–299+; `run_corpus` SKIPs them).

**The apotheosis M7 act.** "Make XII the evaluator of *everything*" — trit (M2), gap (M4),
`sv_op` (M5), kernel β/ι (M9), cost (M13), transforms (M17) all become rewrite rules over one
arena. The **one concrete, bounded keystone the apotheosis names** is the debt M2 opened: *"the
five trit ops become XII rules, so their laws are confluence-checked by `xii_critpairs` (the
promise made in Module 2, now paid)."* This anchors M7's critical-pair machinery on a tiny,
total, provably-confluent rule set. The full "evaluate everything" (gap/`sv_op`/kernel/cost/
transform) is a **systemwide migration** that lands with those modules (M4/M5/M9/M13/M17) — not
a single .iii increment.

**The T4 hazard (governs the whole plan).** Confluence is **not modular**: adding rules can break
*existing* critical pairs, so every rule family added forces re-proving **117+N** pairs. This is
the Premise Ledger's named "likeliest single collapse." Therefore **no edit touches the sealed
engine until Step 0's deep read of the MPO weight function + the `xii_critpairs` pair-enumeration
is complete** — the discipline for the one engine the entire determinism theorem rests on.

## ADR-1 — The M7 increment is the M2-debt keystone (trit ops as XII rules), confluence-re-proven

- **Decision.** Extend the XII arena with a **trit value sub-domain** (NEG/ZERO/POS as terms) and
  the **five trit ops** (`not`/`and`/`or`/`sum`/`mul`) as `match`/`apply` rewrite rules that
  reduce a trit-op term to its trit-value normal form, each strictly MPO-decreasing; re-run
  `xii_critpairs` so **all 117+N pairs converge**; prove the XII normal form of each op equals
  M2's `iii_trit_*` (correctness). This pays the M2-Final debt and anchors M7.
- **Why this and not "evaluate everything" now.** The keystone is bounded (5 total ops, a finite
  3×3 domain → finitely many ground critical pairs), so its confluence is *exhaustively*
  re-provable — the safest possible first extension of the sealed engine. The wider migration is
  unbounded and threads through future modules.
- **Rejected — leave XII untouched, only document the migration.** Fails M7-Final ("extended to
  evaluate trit/…") and pays no debt. A compromise; rejected.

## ADR-2 — Trit representation in `xii_term` (decide at Step 0 from the real arena)

Two candidate encodings; Step 0's read of `xii_term`/`xii_basis` decides:
- **(A) `aux`-encoded basis terms** — a trit value is `make_basis(K_TRIT, sub)` with the
  trit ∈ {-1,0,1} carried in `aux`/`subform`; a trit op is `make_fusion2(K_TRIT_AND, a, b)`.
  Minimal new kinds; reuses the arena. **Preferred** if `aux` is free for value payloads.
- **(B) new dedicated kinds** — `XRW_TRIT_VAL`, `XRW_TRIT_AND`, … added to the kind enum
  (mirrored in `xii_term`, `xii_rewrite`, `xii_basis`). Cleaner typing; larger kind-space change
  (touches the MPO weight table + every kind-cased switch).
- **Constraint either way:** the trit op terms must receive an **MPO weight strictly greater than
  their reduct** (a trit-op node outweighs a trit-value node) so every op rule decreases MPO.

## ADR-3 — Also prove the confluence falsifier's *negative* (the M3-style gap)

`xii_critpairs` proves the 117 pairs *converge* (positive). M7 additionally wires the **negative**:
a deliberately non-confluent toy rule, or a non-MPO-decreasing rule, must be **rejected** by the
gate (the critical-pair check returns "diverged" / the MPO check returns "non-decreasing"). This
makes "a rule that breaks any critical pair or fails to decrease MPO → red" *executable*, not
asserted — the M7 Final falsifier proven on the negative, per the standing "prove-the-negative"
discipline.

---

## Files (create / modify)

| Action | File | What |
|--------|------|------|
| **MODIFY** | `STDLIB/iii/omnia/xii_term.iii` | the trit sub-domain (kinds/encoding per ADR-2) + MPO weights for the new nodes |
| **MODIFY** | `STDLIB/iii/omnia/xii_rewrite.iii` | the 5 trit-op rules (`match`/`apply` pairs, MPO-decreasing), registered in `xii_rewrite_apply_one`; re-seal `xii_rewrite.mhash` |
| **MODIFY** | `STDLIB/iii/omnia/xii_critpairs.iii` | enumerate + verify the new critical pairs (117+N converge); the negative-rejection check (ADR-3) |
| **CREATE** | `STDLIB/corpus/NNN_xii_trit.iii` | XII-evaluates each trit op over the full 3×3 domain == `iii_trit_*` (M2); registered in `run_xii_corpus.sh` (rc=0) |
| **MODIFY** | `STDLIB/scripts/run_xii_corpus.sh` | add the new test(s) to its EXPECTED discipline |

---

## Step 0 — Deep pre-flight (read-only; MANDATORY before any edit — the T4 discipline)
0.1 Read `xii_term.iii` fully: the node layout, `aux`/`subform` semantics, the **MPO weight
function** (how each kind/node is weighted — the termination metric the new rules must decrease).
0.2 Read `xii_rewrite.iii`'s rule shape end-to-end: a representative `match_RNNN`/`apply_RNNN`
pair, `xii_rewrite_apply_one` (the R001..R040 firing order), and how a rule is added without
disturbing the existing 40.
0.3 Read `xii_critpairs.iii`'s machinery: how it *enumerates* overlaps between rule LHSs, how it
checks each pair converges, and where N new rules plug in (the 117→117+N extension point). This is
the load-bearing read — the confluence proof's structure.
0.4 Establish the XII baseline: run `bash STDLIB/scripts/run_xii_corpus.sh` → record it GREEN
(every test rc as EXPECTED). This is the golden the extension must not perturb (except additively).
0.5 Decide ADR-2 (A vs B) from 0.1, and the exact MPO weights (0.1) so each op rule provably
decreases. Prefix-check `XRW_TRIT_*` / `xii_trit_*`. Pick the corpus number (XII range).

## Step 1 — `xii_term.iii`: the trit sub-domain + MPO weights
Add the trit value + op representation (ADR-2) and their MPO weights (op-node weight > reduct
weight). Compile-only. **Gate:** the XII baseline (0.4) still GREEN — additive kinds must not
perturb existing terms.

## Step 2 — `xii_rewrite.iii`: the five trit-op rules
For each of NOT/AND/OR/SUM/MUL: a `match` (LHS = the op node with value children) + `apply`
(RHS = the trit-value reduct, computed exactly as M2's spec table). Register in
`xii_rewrite_apply_one` after R040 (R041..R045). Each strictly MPO-decreasing (Step-1 weights).
Re-seal `xii_rewrite.mhash`. Compile-only.

## Step 3 — `xii_critpairs.iii`: re-prove confluence (117+N) + the negative (ADR-3)
Enumerate the new critical pairs (the 5 trit rules among themselves + against any existing rule
whose LHS overlaps — likely none, since trit kinds are disjoint from K01–K18, so N is small and
the pairs are trivial/ground). Verify **all 117+N converge**. Add the negative check: a toy
non-confluent rule diverges (caught) and a non-MPO rule is rejected. **Gate:** `xii_critpairs`
reports 117+N converged + the negatives rejected.

## Step 4 — `NNN_xii_trit.iii`: the correctness falsifier
Build each trit-op term, `xii_rewrite`/`xii_canonicalise` it to normal form, extract the trit
value, and assert it equals `iii_trit_*(a,b)` (M2) over the **full 3×3 domain** (+ NOT/weight).
Register in `run_xii_corpus.sh` (rc=0). This proves the XII-evaluated algebra ≡ the M2 algebra —
the keystone's correctness.

## Step 5 — Verify (the gate, no-compromise)
1. compile-only each touched XII file. 2. `build_stdlib` → `FAIL=0`, the XII modules OK.
3. `run_xii_corpus.sh` → all GREEN incl. `NNN_xii_trit` + the 117+N critical-pair test +
   the negative-rejection. 4. `run_corpus.sh` → `FAIL=0` (the main corpus unaffected — XII is
   SKIPed there, but the build/seal must stay coherent; `666_trit` (M2) still 99). 5. re-seal
   determinism: `xii_rewrite.mhash` moves by exactly the added rules (expected); the DRIFT-gated
   build decides. 6. manual hand-check: every new rule's MPO strictly decreases (re-derive the
   weights); every new critical pair converges by hand for the finite trit domain.

**Single falsifier:** any critical pair (117+N) diverging, any new rule non-MPO-decreasing, the
XII-evaluated trit op ≠ `iii_trit_*`, or any trit term reducing to two normal forms → red, revert,
diagnose. **The XII baseline (Step 0.4) regressing is an absolute stop** — the engine's confluence
is the determinism theorem; it may not weaken.

## Standards checklist
NIH (libc only — XII is self-contained); determinism (the *theorem*: confluence + termination ⇒
order-independent evaluation); W-laws (the existing rule discipline); K=1.0. The keystone pays the
M2-Final debt (trit ops confluence-checked, not merely unit-tested) + anchors M7. The
**falsifier is proven on the negative** (ADR-3). Apotheosis: realizes the first bounded slice of
M7-Final ("extended to evaluate trit/…"); gap/`sv_op`/kernel/cost/transform evaluation = the
systemwide migration with M4/M5/M9/M13/M17; `xii_curated_*` constitutional gating = M10; every
rewrite witnessed (G-family) = already present.

## Risks
| Risk | Impact | Mitigation |
|------|--------|------------|
| **T4: a new rule breaks an existing critical pair** | confluence proof collapses — the engine's determinism theorem fails | trit kinds are disjoint from K01–K18 → overlaps are minimal/none; Step 3 re-runs ALL 117+N; Step 0.3 reads the enumerator first |
| a trit-op rule not strictly MPO-decreasing | termination lost (non-terminating rewrite) | Step 1 assigns op-node weight > reduct weight; Step 5.6 re-derives each by hand |
| re-sealing churns consumers of `xii_rewrite.mhash` | seal drift | the seal moves additively by the new rules (expected); DRIFT-gated build decides (ADR-027 family) |
| trit encoding (ADR-2) collides with arena assumptions | arena corruption | Step 0.1 reads `xii_term` fully; choose the encoding the arena already supports |
| touching the 3425-line `xii_critpairs` introduces a bug | false confluence pass | additive enumeration only; the negative check (ADR-3) proves the gate still REJECTS divergence |

## Roadmap
1. Step 0: deep XII read + baseline GREEN (no edits).
2. Steps 1–2: trit sub-domain + 5 rules (MPO-decreasing) → compile-clean, baseline still green.
3. Step 3: confluence re-proof (117+N) + negative → `xii_critpairs` green.
4. Steps 4–5: correctness KAT + full gates green; re-seal.
Then M7-Final's wider reach (gap/`sv_op`/kernel/cost/transform as XII rules) lands incrementally
with **M4/M5/M9/M13/M17**, each paying its own debt into the one engine, each re-proving 117+N.

---
**Execution note (no-compromise sequencing).** M7 extends the one sealed engine whose 117-pair
confluence proof *is* III's determinism guarantee. Per the standing "no compromises" + "never
leave a state where progress can't continue" mandates, execution begins with Step 0's deep read
(termination + confluence machinery) **before any edit to the sealed engine**, and each step is
independently gated against the XII baseline. The build + XII gate remain green until Step 0 is
complete and the first additive step is proven — the engine is never left in a half-extended,
unproven state.
