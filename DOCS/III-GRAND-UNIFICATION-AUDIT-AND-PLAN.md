# III Grand-Unification — Adversarial Audit & Perfection Plan
> **SUPERSEDED-BY: III-COMPLETION-PLAN.md** — this document is a HISTORICAL RECORD of its campaign era; the pointer target is the live doc (reunification W6, 2026-07-02).

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

### F7 — `build_stdlib`'s cartographer gate was RED (pre-existing). **[FIXED 2026-06-24]**
Running `build_stdlib.sh` (for P4) surfaced that its architectural gate FAILED on duplicate `@export` symbols
`svir_ptr`/`svir_len`. Root cause: these are the per-program data-buffer entry points of the ~20 STANDALONE SVIR
programs in `STDLIB/sovir/` (svir_prog/svir_loop/svir_fact/iiisv/…) — each compiled to its own `.exe`, linked against
the lib INDIVIDUALLY, NEVER co-linked — i.e. exactly the benign "separate link trees" class already allowlisted for
`cpufeat_has_*`. Since the 2026-06-17 carto walk fix (skip `build/`, raise MAXF → it now sees `sovir/`), the gate has
been red on this whenever `build_stdlib` runs its full path (the project's routine gate is `run_corpus.sh`, which
doesn't invoke carto). **Not** caused by the new `xii_proof*` modules (their exports are uniquely `xii_proof_*`).
**Fix:** added `svir_ptr`,`svir_len` to `III-CARTOGRAPHER/gate_allow.json` `exports` with rationale; carto gate → PASS.

### F8 — `build_stdlib`'s coverage ratchets are RED (pre-existing drift). **[NOTED, pre-existing]**
With the carto gate fixed, `build_stdlib` compiled all modules (PASS=698, FAIL=0, lib aggregated) but exited 3 on three
DOWN-ONLY coverage ratchets: `uncovered=39 > 0`, `dark-surface=58 > 0`, `under-proven=2 > 0` (every `@export` must be
KAT-proven + reachable from the corpus). Since `uncovered=39` far exceeds the ~22 exports of the two new `xii_proof*`
modules, the ratchets were already red BEFORE this session (the project's routine gate is `run_corpus.sh`, which does
not run these ratchets; the full `build_stdlib` path is run rarely). A separate pre-existing cleanup (out of this
audit's scope) = drive the corpus coverage of the drifted exports back to the pinned 0. **This session does NOT worsen
it:** the `xii_proof*` modules were intentionally left OUT of `build_stdlib` MODULES (see P4) so the ratchet is not
pushed further from its pin by un-coverable test-hook exports.

### F9 — `numera/zk_ext2`,`numera/zk_ext4` were missing from `build_stdlib` MODULES. **[FIXED 2026-06-24]**
`zk_air.iii`'s GF(p⁴) composition-polynomial path (`air_combine_ext4`/`air_build_cp_ext4`) references
`ext2_*`/`e2pack`/`e2lo`/`e2hi` and the GF(p⁴) ops, so `libiii_native.a` is INCOMPLETE without `numera/zk_ext2` +
`numera/zk_ext4` — yet neither was in the MODULES list (the old lib carried them via a manual `ar`; a clean rebuild
drops them, leaving every extension-field zk gadget — including `run_zk.sh`'s — un-linkable: `undefined reference to
ext2_mul` etc., even from `numera_zk_air.iii.o` itself). Surfaced when the P4 rebuild produced a lib without them.
**Fix:** added both to MODULES (leaf arithmetic, appended at end, BSS-safe) and restored them into the lib; the
extension-field gadgets (incl. the new committed ones) link again.

### F10 — The committed VERIFIER gadgets are gcc-linked, not sovereign-linked. **[NAMED RESIDUAL, verified 2026-06-24]**
Turning the lens on the trust story Ω7 certifies: the GU's EXECUTION artifact IS genuinely sovereign-built — in
`run_eidos_svir.sh`, R0's SVIR is translated to `.s`, then `sovas_main` (sovereign assembler) → `sovlink_main`
(sovereign linker) + `crt0_sov` produce `r0.x86.exe`, and the gate verifies it is **kernel32-only** (objdump DLL
check). gcc only builds the translator/verifier *tooling*, not the trusted artifact — so "no gcc/ld in the trusted
path" holds for the execution leg. HOWEVER the committed-proof VERIFIER gadgets (Ω.e/f/g: `zk_fused_committed`,
`zk_here_to_there`, `zk_federate_quorum`) are `.iii→.o` (sovereign iiis-2 frontend) then **gcc-linked** — their LINK
step is gcc/ld, so those binaries are not yet sovereign. Honest scope: the EXECUTION proof's binary is sovereign; the
verifier binaries are gcc-linked dev artifacts. Closing it = sovereign-link them via `sovld` over `libiii_native.a` +
kernel32 (a larger sovereign-linker exercise than the single R0 PE — the gadgets pull keccak/merkle/zk_air/zk_ext*).
This is now named in `run_trust_certificate.sh`'s honest-scope line, not hidden.

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
  - **✅ P2b CORE DONE (same gate, `sovir/zk_ext4_stark_committed.iii`):** a COMMITTED, WITNESS-FREE GF(p⁴) STARK on a
    REAL constraint (`next=cur²`, N=16, D=64) on the proven `zk_air` LDE+CP machinery — the trace LDE is Merkle-committed,
    α is FS-derived from the committed trace root (sound commit-before-challenge), the CP is committed as FRI layer 0,
    and the verifier OPENS `f(q)`,`f(q+B)` from the trace commitment, **recomputes `combine=α·(f_next−f²)` itself**
    (witness-free — never reads the whole trace), opens `CP(q)`, and checks the construction-exact line-755
    `CP·Z_H == combine·(x−ω^{n-1})` + the GF(p⁴) FRI fold-consistency. Adversary-verified: honest accepts; a violating
    trace is rejected (CP not low-degree); a forged trace opening is rejected (Merkle); a corrupted root is rejected.
    **This is the committed line-755 `zk_fused_prod` did over shared memory, now done against commitments.**
  - **✅ P2b FULL DONE — F1 CLOSED (same gate, `sovir/zk_fused_committed.iii`):** the WHOLE compute+memory+control
    fused zkVM (32 STORE + 32 LOAD, one N=64 trace, W=19, 20 transition constraints + a k=4 grand-product permutation)
    verified as a COMMITTED GF(p⁴) proof. The 19 trace-column LDEs are Merkle-committed; the combination α is
    **FS-derived from the committed trace roots** (fixes `zk_fused_prod`'s FIXED-α binding gap); the CP + every FRI
    layer are committed; per FS-derived query the verifier OPENS + `merkle_verify_proof`s all 19 columns at q and q+B
    (binding air's `combine`), opens CP(q), checks the line-755 `CP·Z_H==combine·(x−ω^{n-1})` + the GF(p⁴) FRI fold,
    and checks the k=4 permutation boundary at OPENED accumulator leaves. Adversary-verified: honest accepts; forged
    LOAD rejected (line-755); non-permutation rejected (k=4 boundary); forged opening rejected (Merkle); corrupted root
    rejected. **F1 is closed** — the ext-field "production" verifier no longer reads shared memory or uses a fixed α;
    it is commitment-bound. The query count `NQ=16` is the demo knob (production = 128 → ~2⁻⁸⁶).
- **P3 — F2: ✅ CLOSED (one computation, two views).** XII does NOT lower to SVIR (no such lowering exists — checked
  `xii_lower_program`/`xii_kernel_emit`), so "one object through XII→SVIR" is not a wiring task. The faithful binding
  realised instead: the SAME ripple event stream is proven in BOTH views — `zk_gu_ripple_xii` lifts the events to an
  XII term (flat/no-ripple edges = THEN-identities), canonicalises it with the re-checkable Ω3 proof (flats provably
  dropped), and its canonical form FOLDS to `675673294` — exactly R0's SVIR fold (Ω.a) and the committed-zk value
  (Ω.e). The cross-view agreement on one fold IS the composition. Gate `run_grand_unification.sh` (Ω4 single-node) is
  green. Remaining: a true XII→SVIR lowering would make it one transformed object (a larger compiler effort, optional).
- **P4 — F3: PARTIAL.** The carto-gate blocker (F7) is FIXED and the full `build_stdlib` compiles
  `xii_proof`/`xii_proof_check` cleanly into the lib (FAIL=0). But they are kept OUT of MODULES on purpose: they carry
  test-tamper `@export` hooks (`set_rid`/`flip_ahash`) unsuitable for library export, and adding un-corpus-covered
  exports worsens the down-only coverage ratchets (F8). Clean closure = split the library API from the test
  scaffolding (move tamper hooks into the demo) + add a corpus KAT, then list them. For now Ω3 is gated standalone
  (`run_xii_proof.sh`) — proof-gadget support, the right home until that split.
- **P5 — F4 (optional fidelity):** compute the real `sha256(verb‖a‖b)` content-address inside R0's fold (sha256 is pure
  arithmetic, SVIR-lowerable) so R0 attests the genuine inverse-form identity. Larger lift, lower priority.
- **P6 — Ω4 keystone (after P2+P3):** `run_grand_unification.sh` composing the now-connected + committed stages on R0,
  with the five negative arms (forged SVIR, broken sig, non-reproducible, divergent back-ends, forged trace).
- **P7 — F6:** run the adversarial template across the rest of the ledger; demote every claim that fails it.

**Verdict:** the grand-unification organs are real and the *mechanisms* are sound, but two headline "CLOSED" claims are
overstated in exactly the way the project's own discipline warns about — a verifier that shares the prover's memory
(F1) and a narrative connection standing in for a structural one (F2). The honesty pass (P1) is the first deliverable.
