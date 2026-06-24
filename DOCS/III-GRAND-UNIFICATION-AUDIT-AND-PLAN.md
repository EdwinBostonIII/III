# III Grand-Unification — Adversarial Audit & Perfection Plan

**Date:** 2026-06-24. **Method:** read the actual code (not the summaries), default-to-refuted, fairness-check every
harsh finding. Scope: the grand-unification arc (Ω1 zkVM, Ω2 EIDOS→SVIR, Ω3 XII proof) — the freshest and most
load-bearing "CLOSED" claims. The broader memory ledger (60+ "COMPLETE" items) is **not** audited here and warrants
the same treatment (F6).

The discipline: *"allegedly complete" ≠ "truly complete."* Each finding below cites file:line evidence.

---

## FINDINGS (what is really there vs. what was claimed)

### F1 — zkVM "production ~2⁻⁸⁶" is NOT a committed proof in the gadgets that claim it. **[HIGH]**
- **Claimed:** `zk_fused_prod` / `ZK-EXT4-PROD` deliver "PRODUCTION concrete soundness ~2⁻⁸⁶, witness-free verifier".
- **Real:** `zk_fused_prod.iii` `verify()` (lines 209–242) reads the prover's FRI layer arrays `FA[]`/`FB[]`
  **directly from shared module memory**. It never calls `air_merkle_*` and never calls `air_stark_verify`. There is
  **no Merkle commitment, no opening, no root check** of the FRI layers / CP. FRI/STARK query-soundness (~2⁻⁸⁶)
  *requires* a committed codeword the verifier samples via openings; without a commitment the prover is not bound, so a
  malicious prover controlling `FA`/`FB` is not constrained at non-query points. The negative arms forge the **trace**
  (`build_cp(1/2)`) and re-run the honest pipeline — there is **no malicious-layer-table oracle**. The trace itself is
  hand-constructed from the known program in `build_cp` (lines 103–120), not parsed from executed bytecode.
- **Fairness correction (important):** the **base-field** STARK `air_stark_prove`/`air_stark_verify` (`zk_air.iii`
  879–1079) **IS** a genuine committed IOP — Merkle-builds trace LDE + CP + every FRI layer, roots into the FS
  transcript ("commit before challenge", 896), and `air_stark_verify` **Merkle-verifies every opened point** (1022,
  1023, 1027, 1056, 1074). So gadgets that call it (ZK-SOUNDNESS/FOLD/RIPPLE/OPCODE/STACK/OMEGA-E/MEMORY, base field
  ~2⁻²⁷) are sound committed proofs. The extension-field lift raised the *bit-count* but **dropped the commitment**.
  The permutation pillar in `zk_fused_prod` IS FS-bound (its α/β derive from Merkle-committed access columns via
  `air_perm_setup`→855–862), so the k=4 permutation argument is sound-ish; it is the **transition/FRI/CP layer** that
  is uncommitted.
- **Honest status:** sound *arithmetization* + FS-bound *permutation*, at production *bit-count* — but the
  *committed-FRI* that turns the ext-field lift into a real succinct proof is **not wired**. "Production witness-free
  zkVM" is overstated for these gadgets.

### F2 — Ω2 and Ω3 do NOT operate on the same object; Ω3 does not touch R0's SVIR. **[HIGH — blocks Ω4]**
- **Claimed:** Ω3 "canonicalises R0's SVIR" and R0 is "the eidos-ripple temporal fold".
- **Real:** `xii_proof_demo.iii` `build_r0()` constructs a **hand-built XII term**
  `COMPOSE(IF(p, WITH(NULL, LOOP(LOOP(K12,2),3)), e), NULL)` with **zero** connection to Ω2's `eidos_ripple_r0.iii`
  SVIR bytes or to the real `eidos_ripple` module. The "ripple" framing is narrative only. So Ω.a (R0→SVIR) and Ω.b
  (XII canon+proof) **do not compose** — Ω4 cannot honestly chain disconnected stages.
- **Sound part:** the proof-carrying *mechanism* is real and verified — independent checker, mhash chain, 4 adversary
  arms reject. That stands.
- **Architectural note:** XII operates on the **intent algebra** (K-ops); SVIR is **execution bytecode**.
  "Canonicalise R0's SVIR" is likely a category mismatch — the faithful pipeline is
  **EIDOS → XII-term → canonicalise(+proof) → LOWER to SVIR** (the `xii_lower_*` modules already lower XII→code), not
  SVIR→canonicalise.

### F3 — Ω3's library modules are not in the build. **[MEDIUM]**
- `omnia/xii_proof.iii` and `omnia/xii_proof_check.iii` live in the library tree but are **absent from
  `build_stdlib.sh`'s explicit `MODULES` list** (it is a list, not a glob). They are never compiled into
  `libiii_native.a`, never subject to the determinism reseal, corpus regression, or the cartographer architectural
  gate (export-collision / dependency-cycle). They pass only the standalone `run_xii_proof.sh`. Integration incomplete.

### F4 — Ω2's "content-address" is a homomorphic stand-in, not isub's real one. **[MEDIUM]**
- R0 (and the native cross-check driver) fold `enc = verb·65536 + a·256 + b`. The **real** eidos-ripple content-address
  is `sha256(verb‖a‖b)` (isub `cav`). The byte-match therefore certifies the **verb derivation** (cross-checked against
  live `rf_rank`) + a homomorphic fold — **not** the real inverse-form identity. "event→fold→**inverse**" — the inverse
  (true content-address) is a stand-in. Defensible scope, but the content-address-fidelity claim is loose.

### F5 — Ω2 scope. **[LOW]** R0 doesn't exercise the isub witness machinery, and the geometry is a fixed synthetic
gradient. (The verb-derivation cross-check against the live organ is genuine; this is a coverage note.)

### F6 — The broad ledger is un-audited. **[PROCESS]** 60+ memory "COMPLETE/DONE" items were not re-checked here.
The template that found F1–F4 (Is the verifier independent of the prover's memory? Is there a commitment? Does the
negative arm test the *real* adversary, or a forged input through the honest pipeline?) should be run across them.

---

## PRIORITIZED PLAN (Pareto: the 20% that earns the unification)

The unification's value is "one proven pipeline." The two findings that block it are **F1** (the zk attestation isn't a
committed proof at the claimed bits) and **F2** (Ω2/Ω3 don't compose). Those are the 20%.

- **P1 — Honesty pass FIRST (no new code).** Correct the gate banners + DOCS + memory to the REAL status: relabel
  `zk_fused_prod`/`ZK-EXT*` as "sound arithmetization + FS-bound permutation at production bit-count; committed-FRI lift
  PENDING (verify reads shared arrays, not Merkle openings)"; relabel Ω3 as "proof-carrying canonicalisation of a
  representative XII term — mechanism complete; R0-connection PENDING". *The asterisk is the honest word.* Cheapest,
  highest-integrity move; do it before building.
- **P2 — F1: the committed extension-field STARK.**
  - **✅ P2a DONE (gate `run_ext4_committed.sh`, `sovir/zk_ext4_committed.iii`):** the COMMITTED, succinct, witness-free
    GF(p⁴) FRI low-degree test — each layer's full 4-limb GF(p⁴) elements Merkle-committed (16-byte leaves, SHA-256);
    the fold challenge = `keccak(root_L)` and queries = `keccak(final root)`, so they bind BOTH limbs (fixes the
    FA-only defect); the verifier OPENS queried leaves and `merkle_verify_proof`s them against the committed roots
    before fold-consistency (witness-free, O(log n)). Adversary-verified: honest degree-15 accepts; flipped claimed
    leaf rejected (opening binds the value); corrupted committed root rejected (root binds the proof); degree-63
    rejected (low-degree). The soundness-bearing core that was missing now exists, the project's staged way (build the
    dangerous core in isolation with adversary arms, then integrate).
  - **P2b NEXT:** migrate `zk_fused_prod`'s `build_layers`+`verify` (and the `zk_ext*` gadgets) onto this committed
    path — route the CP + the line-755 consistency through committed openings too, so the full compute+memory+control
    STARK is a committed witness-free proof. Only then is "~2⁻⁸⁶ committed production zkVM" earned end-to-end.
- **P3 — F2: compose Ω2 and Ω3 on R0.** Adopt the faithful architecture **EIDOS → XII-term → canonicalise(+Ω3 proof)
  → LOWER to SVIR (Ω2) → run/attest**. Make Ω2's R0 SVIR the LOWERING of the canonicalised XII term (use `xii_lower_*`),
  so the same object flows through Ω.b then Ω.a. **Teeth:** the lowered SVIR's result must equal the XII term's
  denotation, and the Ω3 proof must be over the term that lowers to R0.
- **P4 — F3: integrate.** Add `xii_proof`/`xii_proof_check` to `build_stdlib` MODULES; clear cartographer
  export-collision/cycle; reseal; corpus-regress.
- **P5 — F4 (optional fidelity):** compute the real `sha256(verb‖a‖b)` content-address inside R0's fold (sha256 is pure
  arithmetic, SVIR-lowerable) so R0 attests the genuine inverse-form identity. Larger lift, lower priority.
- **P6 — Ω4 keystone (after P2+P3):** `run_grand_unification.sh` composing the now-connected + committed stages on R0,
  with the five negative arms (forged SVIR, broken sig, non-reproducible, divergent back-ends, forged trace).
- **P7 — F6:** run the adversarial template across the rest of the ledger; demote every claim that fails it.

**Verdict:** the grand-unification organs are real and the *mechanisms* are sound, but two headline "CLOSED" claims are
overstated in exactly the way the project's own discipline warns about — a verifier that shares the prover's memory
(F1) and a narrative connection standing in for a structural one (F2). The honesty pass (P1) is the first deliverable.
