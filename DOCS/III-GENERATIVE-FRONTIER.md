# III — The Generative Frontier: Topological Extraction & Proof-Carrying Code

*Design for the two enhancements that extend III's self-modification from "edit/merge existing
files" (the working Sovereign Ripple Optimizer, Inc 1–5, sealed §8.3–§8.7) to "create new files"
— safely. `/architect` + `/math-olympiad` rigor, 2026-05-29.*

---

## 0 · The unifying principle (why both are safe)

The optimizer so far compresses *inward* (merge/cut). Left there, it would eventually crush III
into unreadable monoliths. To achieve true modularity it must push logic *outward* — create new
files, new boundaries. But creation is where hallucination lives. The single principle that makes
creation safe is the same one that governs everything else in III:

> **The kernel never TRUSTS the Proposer; it CHECKS.** Creation is permitted only when the new
> file's capability is *proven* against `Cap(G)`.

Two regimes, two proofs:

| Regime | What may be created | The kernel proves |
|---|---|---|
| **Topological Extraction** (Phase B) | a new file holding logic that ALREADY EXISTS in G | the new file's capability is a strict **subset** of `Cap(G)` — *zero new capability* |
| **Proof-Carrying Code** (Phase C) | a new file with GENUINELY NEW logic | the new code **exactly inhabits** a human-supplied dependent-type spec — *exactly the specified capability* |

Extraction is *reorganization* (a relocation of proven truth). PCC is the *one* rigorous
exception that admits genuine novelty — and only by forcing the generator to submit a constructive
proof to `typecheck.iii`. **Generative Synthesis without a proof is forbidden, always.**

---

## PHASE B · Topological Extraction

The Proposer (untrusted, may be an LLM heuristic) suggests: *"pull this shared routine out of
`crypto.iii` and `network.iii` into a new file."* The Decider must permit the physical write of a
new `.iii` ONLY when all four conditions hold. Each is **decidable** and maps onto an organ III
already has — no undecidable gap, no test, only proof.

### Condition 1 — Capability Conservation  `rx_cap_conserved`
The exported functions of the new file `F` must be a **strict subset** of `Cap(G)`: the extraction
introduces *exactly zero* new capabilities.
- **Proof.** Every export `fᵢ` of `F` is interned by its content-address (`cad`) into the
  `congruence` ring built from G's existing functions. `fᵢ` must intern to an **existing class**
  (an address already present) — i.e. `F` is byte-identical reused logic. If the Proposer slips in
  a hallucinated function, its `cad` is *fresh* → `cgr_intern` creates a NEW class → C1 detects "new
  capability" → **reject** instantly.
- **Organ:** `cad` + `congruence`.  **Decidable:** address-set membership.
- **Falsifier (KAT):** an `F` carrying one fresh-address (hallucinated) export → rejected.

### Condition 2 — MDL Boundary-Penalty Threshold  `rx_delta_j`
A new file costs structural overhead: header, imports, pointer indirection. The extraction is
permitted only if the deduplication dividend strictly outweighs it.
- **Proof.** `ΔJ = (redundant lines deleted from A + B) − (lines in F + import overhead)`. Write the
  file iff `ΔJ > 0` (strict). This extends `ripple_metric`'s J with a file-overhead term — III will
  not spawn a file to share two lines; it does so only when the mathematical gravity of the shared
  logic earns its own boundary.
- **Organ:** `ripple_metric` (new `rx_delta_j`).  **Decidable:** integer arithmetic.
- **Falsifier (KAT):** an extraction whose overhead ≥ dividend (`ΔJ ≤ 0`) → rejected.

### Condition 3 — Acyclic Insertion Guarantee  `rx_acyclic`
Writing `F` and re-pointing `A`, `B` at it mutates the ripple dependency graph. `F` must be
strictly **lower on the dependency ladder** than its callers — a pure provider — and must introduce
no cycle that did not previously exist.
- **Proof.** Run Tarjan-SCC (the cartographer's algorithm) on the *proposed* graph `G' = G ∪ {F} ∪
  {A→F, B→F} − (extracted edges)`. `F` must sit in its own singleton SCC with only inbound edges. A
  new cycle ⇒ **reject** as unsound.
- **Organ:** Tarjan-SCC (cartographer; mirrored as an `.iii` check).  **Decidable:** poly-time SCC.
- **Falsifier (KAT):** a proposed `F` that imports one of its callers (closes a cycle) → rejected.

### Condition 4 — The H10 Origin Certificate (anti-thrashing)  `rx_h10`
Unification (merge) + Separation (extract) together risk an infinite loop: Pass 1 extracts `F` to
save space; Pass 2 merges `F` back because it is capability-equal to its parents; repeat forever.
- **Proof / mechanism.** Every newly-written file is stamped with an **H10 Constitutional
  Certificate** in its header — the *witnessed-intent marker*. It carries the exact proof of *why*
  the file was extracted: the `ΔJ`, the congruence pair, the pass number, and the payload's `cad`
  (e.g. `H10: extracted pass 420, cross-module congruence {crypto, network}, ΔJ = +45,
  cad = 9f3a…`). On the next loop, the Decider reads the cert: because the intent is witnessed and
  mathematically verifiable, it **explicitly abstains** from merging `F` back into its parents.
  This is exactly `ripple_metric`'s intent gate (§8.3/§8.4 — the cpufeat lesson) applied to
  extracted files: an H10 file gets a distinct *intent-class* that makes `rm_unifiable` return 0
  against its parents.
- **Organ:** `cad` (seal the cert) + `ripple_metric` intent gate.  **Decidable:** marker check.
- **Falsifier (KAT):** WITHOUT the H10 marker the loop WOULD re-merge `F` (thrashing); WITH it the
  loop abstains. The KAT shows both arms — convergence, not oscillation.

### The Final Polish — Naming
Anti-unification strips human meaning to find algebraic structure, so the kernel has no idea what
to *name* `F`. **Leverage the Proposer.** The untrusted heuristic is handed the extracted payload
and guesses a human-readable name (`math_utils.iii`). The Decider does **not** care what the string
says — it attaches the guessed name to the *mathematically-proven payload*, content-addresses the
payload via `cad`, and commits. The name is cosmetic metadata; the `cad` is the truth.

### `commit_gate` extension
`cg_decide` gains a **6th dimension — EXTRACTION** (`CG_REJECT_EXTRACT = 6`): when a change creates
a file, admit only if `rx_certify_extract` = (C1 ∧ C2 ∧ C3 ∧ C4) holds. The applier (`ripple_apply`)
gains a write-new-file mode that emits `F` (H10 header + Proposer name + payload), re-points the
callers, and runs the same GATE0–3 cascade + atomic revert.

---

## PHASE C · Proof-Carrying Code (the only permitted Generative Synthesis)

There is exactly one mathematically rigorous way to admit genuinely-new logic without breaking the
kernel: **you do not test the code — you force the generator to PROVE it.**

1. **The Human Specification.** The human provides a strict formal spec as a *dependent type* — e.g.
   `sort : Π(a : Array Int). Σ(b : Array Int). (Sorted b) × (Perm a b)` ("returns a sorted array
   that is a permutation of the input"). The type *is* the intent; nothing weaker is accepted.
2. **The Generative Struggle.** The untrusted Proposer (wildly creative, in a staging area) writes
   the code `C` **and** a constructive mathematical **proof** `P` that `C` inhabits the spec type.
3. **The Kernel's Verdict.** `C` + `P` + spec `S` are submitted to `typecheck.iii`. The kernel does
   **not** run unit tests — it *evaluates the proof*: `tc_check(P, S)`. If `P` is flawless, `C` is
   mathematically guaranteed to satisfy the human's intent **under all possible states in the
   universe** → committed. If the proof fails by even one axiom → `C` is destroyed.

- **Organ:** `typecheck.iii` (`tc_check`, the CIC dependent-type kernel — already III's trust root).
- **`commit_gate` extension:** a **7th dimension — PCC** (`CG_REJECT_PCC = 7`): a generative commit
  is admitted only if `pcc_verify(code_cad, proof, spec)` = `tc_check(proof, spec) ∧ proof binds
  code_cad`. The Proposer's creativity is unbounded in staging; not one new line reaches disk until
  it submits to the kernel's law.
- **Falsifier (KAT) — the heart of it:** a flawed proof (a missing axiom / a proof of the *wrong*
  spec) → `tc_check` rejects → code destroyed. The kernel admits *only* a flawless proof — never
  code that merely "passes tests." Proving the negative here is proving that III cannot be tricked
  into committing unproven novelty.

---

## ADRs

- **ADR-B1 — Creation is proof-gated, never trusted.** No file is written on the Proposer's say-so;
  C1–C4 (extraction) or `tc_check` (PCC) must discharge first. Same propose-and-check charter.
- **ADR-B2 — Extraction is decidable; PCC is semi-decidable but SOUND.** C1–C4 are all decidable
  (address membership, arithmetic, SCC, marker). PCC's *proof search* (the Proposer's job) is
  undecidable in general — but proof *checking* (`tc_check`, the Decider's job) is decidable and
  total. So the kernel always terminates with a correct verdict; only the Proposer may fail to find
  a proof (in which case: honest abstain, nothing committed). Soundness never depends on the
  Proposer succeeding.
- **ADR-B3 — H10 = intent, reusing the existing gate.** Anti-thrashing is not new machinery; it is
  the §8.3 intent gate with an H10-stamped intent-class. One mechanism, two uses (cpufeat + H10).
- **ADR-B4 — The applier writes through the same GATE0–3 + revert.** New-file creation is just
  another edit class behind Inc 5's inductive safety invariant: the tree is green before and after,
  or the write is reverted byte-exactly.
- **ADR-C1 — The kernel checks proofs, never runs code.** PCC's safety is `tc_check`, not execution.
  A correct proof ⇒ correctness under *all* inputs (stronger than any test suite).

## Risks

| Risk | Mitigation |
|---|---|
| Hallucinated "extracted" function | C1 (`cad` membership) rejects any fresh-address export |
| Extraction thrashing (extract↔merge loop) | C4 H10 certificate → intent gate abstains; loop converges |
| New file closes a dependency cycle | C3 Tarjan-SCC on the proposed graph rejects |
| Writing new `.iii` miscompiles III | the applier's GATE0–3 + atomic revert (Inc 5 invariant) |
| PCC proof proves the *wrong* spec | `tc_check` binds proof to the human spec `S` exactly; wrong-spec proof fails |
| PCC generator hallucinates a "proof" | the kernel evaluates it; a non-proof fails `tc_check` and the code is destroyed |

## Roadmap (one part at a time, each sealed like Inc 1–5)

- **B1 — `ripple_extract.iii`:** C1–C4 as provable predicates + `rx_certify_extract` (compose all
  four + `commit_gate`). KAT with four falsifiers (one per condition) + the H10 anti-thrashing arm.
- **B2 — `commit_gate` 6th dimension (EXTRACTION)** + the applier's write-new-file mode
  (`ripple_apply` extension), demonstrated on a controlled, reversible extraction.
- **C1 — `pcc_gate.iii`:** `pcc_verify` = `tc_check(proof, spec)` ∧ proof-binds-code. KAT: a flawless
  proof admits; a flawed/wrong-spec proof is rejected (the negative is the whole point).
- **C2 — `commit_gate` 7th dimension (PCC)** + the generative staging→kernel-gated-commit applier,
  demonstrated on a spec with a correct proof (admit) and a flawed proof (destroy).

Each increment: write → adversarial KAT (prove the negative) → `build_stdlib` 4xx/0 → cartographer
GATE PASS → compiler `4e138415` unchanged (LIBNATIVE) → full corpus green → seal in MHASH-LEDGER →
commit. The frontier extends III's power without ever loosening the kernel's law.
