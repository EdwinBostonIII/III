# III Autogenesis Wave — The Closed Structural Self-Improvement Loop

**Status:** DELIVERED & VERIFIED · build PASS=605 / FAIL=0 · coverage uncovered=0 ·
gate-outcome under-proven=0 · reachability dark-surface=0 · carto GATE PASS ·
KATs 1400–1409 = 99 · propose-only gate GREEN.

This document is the house-style architecture record for the autogenesis wave, matching
`DOCS/III-NOUS-ARCHITECTURE.md`. It describes the one wire that closes III's existing limbs into a
self-improving loop and the rails that make the loop grow like a crystal, not a tumor.

## 0. Thesis

III already contained every limb of a self-improving mind: a self-audit (`corpus_coverage`), a CIC
proof kernel (`typecheck`/`theorem_commons`), a conjecture proposer (`nous_conjecture_gen`/
`nous_search`), an equality engine (`egraph`/`congruence`), an optimize loop (`ripple_loop`) with an
analytic cost oracle (`microarch_model`), a reversible transaction (`vbd`), and a signed attestation
box (`attest_box`). What was missing was the single wire that closes them into a loop, and the rails
that keep the loop sound. This wave is that wire and those rails, authored as **seven leaf organs**,
**two capability bits**, **one charter clause**, gate scripts, ratchet pins, and corpus KATs — all
under the existing seal discipline (every organ is `STDLIB_GATE`, closed by `build_stdlib.sh` FAIL=0
plus a falsifier KAT).

## 1. Honest scope boundary (a design invariant)

The loop is certified by the CIC kernel (`tc_check`), so it cannot admit an unsound transformation,
cannot regress, and cannot drift silently. Proof gives soundness against a specification, never the
rightness of the specification. Therefore the default mode is an **apprentice**: the loop proposes,
proves, optimizes, and stages, but committing a change to the sealed source tree requires an operator
or quorum signature. Unattended commit is **built but gated** behind an ungranted capability bit
(`CAP_RIGHT_AUTOGENESIS_COMMIT`). This boundary is enforced **structurally** — the charter clause and
the canary KAT 1409 — not aspirationally.

## 2. Doctrine alignment (the execution contract)

- **I1 Determinism:** integer-only, no float, no wall-clock; content-derived order; the cost oracle
  is cycle-exact (`microarch_model`), never observed.
- **I2 NIH:** libc + COMPILER/BOOT headers only; every organ RIDES an existing engine rather than
  re-implementing it (`gap_conjecture` extends the `nous_conjecture_gen` disposer; `harmony_synth`
  routes through `certified_morphism`; `refactor_propose` rides `egraph`+`commit_gate`;
  `optimize_self` rides `ripple_loop`+`ripple_journal`; `autogenesis` rides `vbd`+`attest_box`).
- **I3 Proof-kernel arbitration:** anything asserting meaning reduces to `tc_check`; the trusted base
  never widens (the propose-only gate proves no autogenesis symbol enters TYPES/src or COMPILER/BOOT).
- **I4 No vacuity:** every gate can say no; each organ ships a falsifier KAT with a positive arm AND
  a biting negative arm.
- **I5 No placeholder/stub/partial:** completion is the only acceptable state.

## 3. The organs (dependency order)

| Ring | Organ | Role | KAT |
|------|-------|------|-----|
| R-1 | `sanctus/self_model` | content-addressed Merkle self-image; `sm_diff` is the drift substrate; `sm_next_gap` is the target | 1400 |
| — | `nous/gap_conjecture` | export-law proposer; extends the `nous_conjecture_gen` propose→dispose discipline with a structural law table, honouring the `nous_search` trichotomy (a budget timeout is GAP, never a false admission) | 1401 |
| — | `nous/harmony_synth` | composition-arrow proposer; ranks by 3-objective Pareto and admits ONLY through the `certified_morphism` kernel gate (an arrow IS a proof-carrying theorem) | 1402 |
| — | `nous/refactor_propose` | e-graph equivalence prover for whole exports (COMBINE) + dark-export cuts (CUT); `rp_certify` integrates e-graph evidence + a CIC proof through `commit_gate`, merging the congruence ring on admission | 1403 |
| — | `nous/optimize_self` | cost-gradient descent gated by the analytic cost oracle with a HARD result-equivalence gate (a cheaper move that changes an answer is rejected); journals via `ripple_journal` | 1404 |
| — | `nous/theorem_grow` | persistent, tamper-evident, re-verified theorem DAG on disk; on reload every proof is re-checked, so a false/tampered record is refused; `tg_count` is the monotone floor | 1405 |
| R-1 | `sanctus/autogenesis` | THE GATEWAY: one cap-gated cycle as a reversible `vbd` transaction with a genesis-anchored hash-chained attestation ledger | 1406–1409 |

## 4. The cycle (`ag_cycle`)

1. Gate on `CAP_RIGHT_AUTOGENESIS` + single-cycle-in-flight invariant (the `develop_up` pattern).
2. Anchor the ledger to the federation closure root (`fed_genesis`), or a deterministic genesis tag.
3. Refresh the self-model target (`sm_next_gap`); GATHER ranked candidates from the three proposers
   and the cost optimizer — each PROPOSES, its own kernel/gates DISPOSE.
4. Open a reversible `vbd` transaction; capture the BEFORE state root (`ab_state_root`).
5. Stage the change-manifest into `vbd` blocks (record-before-mutate); capture the AFTER state root
   and the admitted-theorem root (`tg_root`).
6. Validate; extend the cad hash-chained ledger: `ledger' = cad(ledger ‖ before ‖ after ‖ thm)`.
7. EITHER `ag_commit` (apprentice-gated) OR `ag_rollback` to the **byte-exact** pre-cycle state.

## 5. Anti-cancer rails (mapped to enforcement)

| Rail | Enforcement |
|------|-------------|
| Propose-and-checked | generative organs return ranked candidates; the kernel/gates dispose (charter clause + KAT 1409 canary) |
| Proof-gated admission | every arrow/theorem/refactor passes `tc_check` before any mutation (the `cmorph_add` order) |
| Monotone ratchet | `self_model_pin.txt`, `theorem_floor.txt` (floors hold or improve); coverage/gate-outcome/reach ratchets pinned at 0 |
| Reversible transaction | each cycle is a `vbd` envelope; a forced fail triggers `vbd_rollback` (KAT 1407: state byte-identical) |
| Capability-gated + attestable | gated by `CAP_RIGHT_AUTOGENESIS`; each cycle signs before/after roots (`ab_attest`); KAT 1408 |
| Genesis-anchored | the ledger hash-chain is anchored to `fed_genesis`, so a self-modified III still proves lawful descent |

## 6. Gates and evidence

- `STDLIB/scripts/run_autogenesis_corpus.sh` — runs KATs 1400–1409 against the live archive plus the
  propose-only gate; GREEN.
- `STDLIB/scripts/verify_autogenesis_propose_only.sh` — trust-root isolation (no autogenesis symbol in
  TYPES/src or COMPILER/BOOT) + the `ag_commit` chokepoint (referenced only from the corpus).
- The gate-stem exports (`hs_admit`, `rp_certify`, `ag_attest`) each pin ≥2 distinct corpus outcomes
  (admit AND refuse), so they cannot raise the gate-outcome ratchet.

## 7. ADR decision log

- **A1 — Apprentice default.** Unattended commit is built but gated behind an ungranted bit; the
  charter clause + KAT 1409 make the gate structural, not aspirational.
- **A2 — Pareto/dominance inline.** `harmony_synth` applies the 3-objective dominance relation to its
  own candidate vectors rather than abusing `pareto_frontier`'s fixed 6-point benchmark; the relation
  is the doctrinal sibling, not an island.
- **A3 — Equivalence vs cost split.** `refactor_propose` owns equivalence (e-graph); `optimize_self`
  owns cost (microarch). The result-equivalence gate in `optimize_self` is hard and comes FIRST.
- **A4 — Re-verified persistence.** `theorem_grow` re-checks every proof on reload; nothing on disk is
  trusted (KAT 1405: a false/tampered record is refused).
- **A5 — cad ledger, optional signature.** The ledger is a cad hash-chain (identity-free, always
  available); `ag_attest` adds an Ed25519 signature when a node identity is present (KAT 1408).
