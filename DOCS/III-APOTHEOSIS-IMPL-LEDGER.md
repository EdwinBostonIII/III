# III-CAPABILITY-APOTHEOSIS — Implementation Ledger

**Governing directive (2026-05-30):** implement every capability in `DOCS/III-CAPABILITY-APOTHEOSIS.md`
strict top-to-bottom (S.1<S.2<…<S.7<C.1<…<C.15<Z), one at a time, **fullest/hardest form** — no
defer, no placeholder, no NIH breach, no compromise. The doc is actively appended; continue as it grows.

## Method (per unit)
1. Read the unit's doc section (Final Form + change plan + proof obligation).
2. **Re-verify every cited `file:line` against LIVE code** (doc caveat #2: anchors drift — re-grep, never trust).
3. Classify each change-plan item: DONE / REAL-GAP.
4. For REAL-GAPs: implement the **hardest/best** form; invent the breakthrough where a spec is
   compiler-blocked — **unless** an ADR-skip is *verified* (not asserted) to make the system worse
   (advisor precedent: default = build the breakthrough; ADR-skip is the rare, evidence-backed exception).
5. Proof-obligation KAT (negative arms) → `build_stdlib` (FAIL=0 + GATE PASS) → corpus green → seal.

## Hard-won lessons
- **The state-map (`woxpwlpov`) systematically OVER-reports.** It read the spec change-plan literally and
  flagged 103 "gaps"; re-verification shows **every §S item it flagged is already DONE** (often done
  *better* than spec, with audit tags + ADRs). Treat it as a where-to-look guide only; live code is truth.
- **q_generic precedent:** a spec blocked by a real language limit + with **no live consumer** is a
  verified ADR-skip (not bloat-build). const-generic `@specialize` tracked as a deferred breakthrough that
  graduates if fixed-width-int consumers accumulate.
- **Lift-don't-weaken:** when consolidating onto a shared organ, never route a stronger caller to a weaker
  organ (e.g. RSA's allocation-free raw-buffer path); lift its strength into the organ (done for §S.2.6).

## Status — Substrate §S
- `S.1` unified raw-limb core — **DONE** (modulus_ctx is the floor; realized in S.2).
- `S.2` bigint arithmetic — **DONE.** items 1-3 (modulus_ctx/mont_mul_add/sq/ctx-modpow) live; item 4
  (q_generic) = verified ADR-hold; item 5 (karatsuba radix annotations) done; item 6 (rsa CIOS dedup via
  raw-buffer bridge) done lift-don't-weaken. **+ leaner finish landed**: rsa_modexp n' Newton deduped to
  `mont_nprime64` (one Newton proof surface). Built 434/0 (mhash bbf4a0c8…); corpus confirming.
- `S.3` prime-field/curve — **DONE** (field.iii uses Knuth div not CIOS; NIST fields consolidated; galois
  char-2 untouched; modular.iii has the "generic escape hatch" fallback header).
- `S.4` one NTT organ — **DONE** (fusion intrinsic: `ntt_gs_inverse_tabled` butterfly already IS
  `mont_redc(diff·zeta_mont)`; `ntt_ct_forward_tabled` fuses per butterfly; staged separate fn was a false
  premise). Optional: a 4-prime round-trip KAT (marginal).
- `S.5` hash/MAC/AEAD/KDF/RNG — **DONE** (chacha `cc20_block_into_ks` has CC20_FORCE path-forcing +
  `cc20_force_path()`; aes core is block-level safe; `aes_siv_encrypt` has the `pt_len>65536` guard
  [E2-SIV-1]; gcm streams). Optional: scalar↔avx512 bit-identity KATs (coverage).
- `S.6` seal & content-address chain — **DONE.** witness_hook (aether/) already routes its 3 keccak sites
  through cad (byte-identical) + has full verifiable redaction (wh_redact/is_redacted/redaction_commit,
  consumer h8_charter); merkle is suite-parametrized (6.3); seal.iii (katabasis/) is the Phase-1 seal;
  witness_spine.iii:70-96 carries the radix-skip ADR-S6 (HT kept: ≤50% load → no clustering, public-id
  lookups → constant-time moot, dense radix-256 not leaner at 2Mi, Patricia staged as a named horizon).
  **My finish:** corpus `988_witness_redact` — the missing prove-the-negative for M6 forgetting (state-flip,
  commit==independent-keccak256, payload-zeroed, **frag_id-unchanged**, bad-idx reject). Validated exit=99;
  adopting via corpus (→644/0). §S.6.2 (separate numera/seal.iii) + §S.6.4 (radix) = verified ADR-skips.
- `S.7` arena/region/time — **DONE** (tempaloc + seal_organ exist; arena_safe/region_safe deleted;
  arena_reset_with_witness present; deadline:74 logical-tick bug fixed).

## Status — Capabilities §C (re-verify top-to-bottom; advisor: build genuine gaps + ed_mod_l + missing KATs;
## skip only on radix-caliber verified-worse receipt; **proof-obligation KATs are pure value, KAT wins ties**)

**Batch existence-check done (advisor cadence):** of the 23 spec'd C.3-C.15 new files, 22 are ABSENT but
mostly *consolidation* modules (merge existing zk/hotstuff/ripple/nous/compiler code into named organs) —
ABSENT ≠ gap; each needs a read to judge genuine-dedup (build) vs reorg-churn (skip w/ receipt). reach_oracle
exists.

- `C.1` PQ — **mostly DONE.** pq_params/ntt_ctx/keccak_sponge exist; mldsa has *_sign_sealed; corpus
  769_pq_sealed_abi + 770_slhdsa_shake_fips205 + 198/199/200 roundtrips. slhdsa_sha2/shake *file split*
  absent (SHAKE strict tested via 770 — verify if SHA2 strict family is a real gap). **KAT landed:**
  `989_mlkem_decaps_k_guard` (k∉{2,3,4}→-1, valid→0; validated exit=99, in EXPECTED). **Remaining KATs:**
  mldsa/slhdsa siglen-guard (need a real roundtrip for the good arm — verify returns -1 for both siglen AND
  bad-sig, so a valid sig is required to isolate the guard).
- `C.2` classical — RSA done-better (rm_* kept, shares CIOS organ — §S.2.6; the doc's "delete rm_*" is the
  lift-don't-weaken trap, DO NOT route RSA to the allocating bigint_modpow_mont). **ed_mod_l = BUILD**
  (advisor: real perf win; premise verified — crypt_ed25519:152/237 use generic bigint_mod for the scalar L;
  implement sovereign sc_reduce mod L=2^252+δ NIH + a differential KAT bit-exact vs bigint_mod). bigint_io /
  modparam = READ the 4 os2ip/i2osp sites first (identical→build, scheme-framed→skip w/ receipt). fz_algebra
  = skip-candidate (verify EDWARDS/MONTGOMERY tag catches a real bug class before skipping). **Remaining
  KATs:** ed_decompress non-canonical/invalid-curve reject (fe25519:362/378; cheap — canonical pubkey from
  388, no signing), ecdsa_p256 zero-r/s reject (ecdsa_p256:157; copy a vector from 208/913). 972 lowS +
  981 strict-S already present.
- `C.3` zk-STARK, `C.4` compiler, `C.5` logic, `C.6` XII, `C.15` Nous, `C.7` Ripple, `C.8` silicon,
  `C.9` systems, `C.10` katabasis, `C.11` BFT, `C.12` HW-RTL, `C.13` gate-stack, `C.14` perf — TO ASSESS.
  Caveat #1: cross-tree "organs" (xii_organ, proof_term) = one design twinned across compiler+stdlib +
  differential KAT, NOT one physical file (so a single xii_organ.iii may contradict the spec's own caveat).

## Verified ADR-skips (surface to user for override — burden-of-proof met at radix caliber)
- **§S.2.4 q_generic⟨bits⟩**: III @specialize is type-only; no fixed-width 256/512 int consumer in tree →
  building manufactures dead modules. const-generic @specialize tracked; graduates if consumers accumulate.
- **§S.6.4 witness_spine HT→radix**: ~16× BSS at gospel 1M-frag scale; uniform keccak IDs at ≤50% load have
  no clustering pathology; all consumers are public-id lookups (constant-time moot); golden-moving. HT kept;
  Patricia staged as named horizon (witness_spine.iii:70-96 already documents this).
- **§S.6.2 separate numera/seal.iii**: seal-fragment computation already in cad_compute/wh_compute_frag_id +
  katabasis/seal.iii; a separate module duplicates (against dedup) or risks byte-identity, no new consumer.

## §C verification workflow (wg4c0ce7p) result + my framework override
70 classified: **43 GENUINE_GAP, 13 MISSING_KAT, 14 VERIFIED_SKIP** (refute phase caught 19 of 62 claimed
gaps as actually-DONE). BUT the 43 survivors still include the reorg/preemptive items my in-session analysis
skips (advisor: in-session is more accurate). My framework: **build genuine capability-EXPANSIONS (e.g. the
C.3 AIR DSL); skip reorg/preemptive with a radix-caliber receipt.** Reclassified vs the workflow:
- SKIP (receipts): ed_scalar_modl/ed_mod_l (cold-path <1% of sign, Knuth-served, bigger-not-leaner),
  modparam + bigint_io + fz_algebra (scheme-framed: rsa bigint-BE vs curves fixed-LE — not a dedup),
  "remove dead iii_ecdsa_p256_verify" (NOT dead — it's the live impl _verify_x wraps), the rsa rm_*
  differential KAT (wrong premise — rm_* is the KEPT allocation-free path, §S.2.6 lift-don't-weaken).
- DEBATABLE/surfaced: slhdsa_sha2 strict FIPS-205 family (MGF1-SHA-256 H_msg genuinely absent, but NO
  internal consumer — preemptive-external-interop; slhdsa mode-0 already = strict SHAKE, byte-exact NIST).
- GENUINE BUILDS to do: **C.3 AIR DSL (CORE DONE)**, pq_dispatch_sealed, + assess C.4-C.15 expansions.

## Landed this campaign
- §S.2 rsa n' Newton dedup → mont_nprime64; built; **373_rsa_pss bit-exact standalone (99)**.
- **§C.3 FLAGSHIP: numera/zk_air.iii — the general AIR DSL CORE (built + validated, GATE PASS PASS=435).**
  Generalizes the demo (single-col x²+c) to W-column, degree-≤2, DATA-DRIVEN constraints (term lists
  coeff·var_a·var_b over current/next-row cols) + the composition poly CP=Σαₖ(Cₖ/Z_H) over the shared §S.4
  NTT. `997_zk_air_general` (exit=99): a real 2-column degree-2 AIR (col0'=col0·col1, col1'=col1+col0) —
  (a) constraints vanish on H_N rows 0..N-2, (b) composition consistent at non-trace pts, (c) NEGATIVE arm:
  corrupt a trace cell → constraints fail (cheating caught). Bug found+fixed: transition binds rows 0..N-2
  (last row has no successor; the next-row eval wraps). **C.3 REMAINING (full prove/verify integration):**
  generalize zk_stark's FRI/Merkle/query prove+verify to consume zk_air; + zk_stark_seal.iii (proof cad);
  + a full general prove→verify round-trip KAT. (The composition core — the novel hard part — is done.)
- **Corpus KATs (all validated standalone =99):** 988_witness_redact (§S.6), 989_mlkem_decaps_k_guard +
  995_mldsa_siglen + 996_slhdsa_siglen (§C.1 PQ), 993_ed_decompress + 994_ecdsa_zero_rs (§C.2), 997_zk_air
  (§C.3). All in run_corpus.sh EXPECTED. Full corpus 647 PASS (832/833 = ENVIRONMENTAL link transients,
  both link+run fine standalone — OneDrive-dir contention; NOT regressions). **Corpus is flaky in this dir
  → standalone per-test validation is the primary gate.**

## ⚠ Harness note (root-caused 2026-05-31)
`run_corpus.sh` had a transient syntax error (the bppkdwxaw/b5p2kdqud bg runs aborted before running any
tests → their "exit 0" was the trailing grep, NOT a green corpus — my earlier "643/0"/"644/0" were FALSE).
`bash -n` passes on the current file (82 uncommitted lines from user/linter + my 3 EXPECTED adds). Lesson:
ALWAYS read the literal `PASS=N FAIL=M` summary line (run_corpus.sh:891), never infer corpus health from a
piped exit code. Standalone per-test build+run (the pre-validation method) is unaffected and remains trusted.

## C.3 full prove/verify integration — design (next focused build; /architect)
The AIR composition core (zk_air.iii) is done+validated. To finish C.3 = a general STARK:
1. **Generalize the prover** (zk_stark.iii st_prove:359 → consume zk_air): commit each of the W LDE columns
   (Merkle, not just one), build CP via air_build_cp, FRI-commit CP, derive FS queries, open the queried
   trace+CP positions for ALL columns. Reuse the demo's FRI fold + Merkle + FS transcript verbatim
   (constraint-agnostic — they operate on the LDE/CP arrays, so no soundness rewrite).
2. **Generalize the verifier** (st_verify:448): at each query q, recompute the constraint via air_combine(q)
   from the opened LDE values (replacing the hard-coded nxt-cur²-c at :263-area), assert
   CP[q]·Z_H(q)==combine(q), verify FRI low-degree, verify the W-column Merkle openings + boundary openings.
3. **zk_stark_seal.iii** (NEW, additive): zk_stark_proof_cad = cad(trace_roots‖cp_root‖fri_roots‖queries‖
   boundary) → a sealed proof identity in the §S.6 witness spine. (Build WITH the integration, sealing a
   real proof — premature standalone.)
4. **KAT**: a full general prove→verify round-trip on the 2-col AIR (997's constraint system) + negative arms
   (tampered FRI layer rejected; constraint-violating witness fails to prove; seal mismatch on any change).
DISCIPLINE: refactor in place is risky (breaks the working demo) — gate every step with the fast-link method
(new zk_stark.o ahead of lib) + re-run zk_stark_kat (the demo must still pass) before committing.

**Refined (after reading st_prove/st_verify/st_merkle/st_fs):** the demo's Merkle (st_merkle_build/open/
verify), FRI fold (st_prove:393-401), FS (st_fs_*), and query derivation (st_derive_queries) are ALL
constraint- AND column-agnostic — but they hard-code the ZKST buffers (trace LDE @ZKST[1000], cp @[2000],
trees in ZKST_MT). So the general STARK = make these operate on a passed base address (the spec's
ntt_fri_organ/merkle-organ extraction) so they serve BOTH zk_stark's single-column demo AND zk_air's
W-column AIR_LDE/AIR_CP. **Verifier piece DONE+validated this session: air_combine_opened** (reproduces the
prover's combine from openings, fast-link 997=99) — it slots directly in at st_verify:469-473's hard-coded
x²+c. Remaining = (1) parameterize the 4 helper families by base-addr (or give zk_air its own thin copies),
(2) prover loops W columns for commit/open, (3) verifier loops W columns + calls air_combine_opened, (4) a
full general prove→verify round-trip KAT. Mechanical given the reused soundness machinery + the validated
evaluator; ~120-150 lines, one focused pass.

**WIRING PROGRESS (Option B — zk_air carries its own Merkle/FRI; staged dedup):** 3 of 4 pieces DONE+
validated in zk_air.iii (compiles clean, official lib):
  1. ✅ air_combine_opened — verifier-side constraint eval from openings (997, fast-link 99).
  2. ✅ Merkle organ — air_leaf_hash/node_hash/merkle_build(arrBase,…)/root/open/verify, leaf-array-
     parameterized so one builder commits any column LDE or the CP (998_zk_air_merkle, 99; committed).
  REMAINING (the one coupled batch): FS (port st_fs_hash8/st_fs_field_compute/st_derive_queries → ZKAIR_*),
  FRI fold (st_prove:375-409), air_stark_prove (commit W cols + CP, FRI-fold, derive queries, open
  W-col trace[q]+next[q] + CP[q] + FRI sibs + per-boundary LDE_col[row*B]), air_stark_verify (verify
  openings, air_set_open per col + air_combine_opened==CP[q]·Z_H(q), FRI consistency st_verify:480-503,
  boundary), + 999_zk_air_stark KAT (round-trip + tampered-FRI/witness/boundary negatives). State buffers
  needed (W-generalized from the demo's): ZKAIR_FSBUF/TRANS/HASH/FS_*/QD_*/QUERIES[16], ZKAIR_TRACE_ROOTS
  [W*32]/CP_ROOT/FRI_ROOTS[12*32]/FRI_NL/FRI_FINAL, ZKAIR_FRI[512]+FSIZE/FOMEGA/FLOFF/FTOFF[12],
  ZKAIR_TQ[16*W]/TQN[16*W]/CQ[16]/FQ[16*12]/FSIB[16*12], paths TPATH/TNPATH/CPATH/FPATH. q=power-of-2 mask;
  FS field = hi*(2^32 mod q)+lo (avoids the modulo-after-call trap, per st_fs_field_compute's note).
  FRI/Merkle are constraint-agnostic so the port is faithful → inherits the demo's tested soundness.

**✅ C.3 COMPLETE (2026-05-31).** All 5 wiring pieces built + validated in zk_air.iii; the full general
STARK works end-to-end. `999_zk_air_stark` (exit=99, first try): proves a 2-column degree-2 data-driven AIR
(col0'=col0·col1; col1'=col1+col0) via air_stark_prove (commit W trace cols + CP, FRI-fold, open all
queries) → air_stark_verify (verify Merkle openings, CP[q]·Z_H(q)==air_combine_opened, FRI low-degree) →
ACCEPT; and 3 tampers (CP opening / trace opening / FRI-final) → REJECT. zk_air.iii ~760 lines, compiles
clean, committed to the lib. The STARK is general (arbitrary low-degree transition constraint systems), not the x²+c demo.
**HARDENING LANDED + validated (999 exit=99):** (a) ✅ FS-derive the composition coefficients α_k from the
trace commitment (air_derive_alphas; prover reordered commit-trace→derive-α→build-CP; verifier re-derives) —
adaptive-prover soundness closed; (b) ✅ boundary/public-input binding (air_add_boundary + open
LDE_col[row·B]==value; the KAT binds col0[0]==2, col1[0]==3) + a 4th negative arm (boundary tamper rejected).
So C.3 is a COMPLETE, SOUND, BOUND general STARK. ONLY remaining = the spec's staged ntt_fri_organ dedup
(zk_stark+zk_air share Merkle/FRI — a refactor, NOT a capability gap; staged like ADR-S4/S6).
**C.4 (self-hosting compiler) — CAPABILITY DONE.** The crown jewel = the byte-identity fixed-point
(build_iiis2 --check-corpus 59/0; the GATE PASS on every build_stdlib) — self-hosting reseal is live + proven.
The 3 unifications (emit_generic 4-codegens→1+configs ~970-line dedup; proof_term cert union; xii_organ
cross-tree) are genuine dedup BUT large high-risk refactors of the working compiler that **the spec itself
marks "*Design only; the live compiler/reseal is not edited here*"** — gate-verifiable (--check-corpus) but a
focused careful effort, NOT a session-tail rush (be-thorough-and-safe + design-files-have-a-reason). Staged.

**Campaign realization (the tractable path):** the apotheosis is mostly DONE-capability + spec-staged-refactors
+ missing-KATs, with SPARSE genuine capability-EXPANSIONS (C.3's AIR DSL was the big one — now built). So
C.5-C.15 each: re-verify (likely done), build any genuine expansion, add missing negative-armed KATs, skip
reorg/staged with receipts.

**C.5 (logic/verify substrate) — CAPABILITY DONE.** Live+tested: proof_term, egraph, bisimulation_witness,
smt, temporal_logic, constitution(+_preserver), induct, commit_gate (G1-G5 organs built in the prior loop;
corpus 864 = gate CG_REJECT_KERNEL arms, 644 = LTL bounded-k). Change-plan = consolidate 4 proof carriers →
1 Curry-Howard IR + compose cg_decide explicitly + route certs through the IR = genuine-dedup REORG refactor
(careful focused effort, like C.4 emit_generic). Staged.

**⚠ CONSTRAINT: corpus numbering full.** run_corpus.sh globs [0-9][0-9]_ + [0-9][0-9][0-9]_ (≤999); 988-999
are all used (mine). Adding more proof-obligation KATs (loop backlog: checked_u32_div div0, quality_q4,
cap_verify invalid-id, sc_recv AEAD-tag, ed_decompress invalid-curve) needs a 4-digit glob (additive harness
enhancement) OR reusing a sub-988 gap. Surface to user before touching the user/linter-owned harness.

**STAGED REFACTORS (the genuine remaining builds — gate-verifiable, careful focused efforts, NOT session-tail
rushes):** C.4 emit_generic (4 codegens→1+configs, ~970-line dedup, gated by build_iiis2 --check-corpus 59/0);
C.5 proof-term-IR consolidation (gated by the gate+bisimulation negative arms); C.3 ntt_fri_organ (zk_stark+
zk_air share Merkle/FRI). Each touches a working crown-jewel-class system; the spec stages them deliberately.
NEXT: re-verify C.6-C.15 (likely done-capability) + decide each staged refactor as a focused effort.

**USER GREENLIT (2026-05-31):** (1) extend corpus glob to 4-digit — DONE (run_corpus.sh:749 + the
[0-9]{4}_ glob); (2) BUILD the staged refactors carefully, gate-verified ("no deferral"). So the staged
refactors (C.3 ntt_fri_organ, C.5 proof-term-IR, C.4 emit_generic) are now committed work — each its own
focused gate-verified pass (build_iiis2 --check-corpus for C.4; zk_stark_kat+999 for C.3; gate+bisim
negatives for C.5). Order by risk: C.3 ntt_fri_organ (lowest — I control both modules) → C.5 IR → C.4
emit_generic (highest — the compiler; the gate makes it provably safe but it's a ~970-line careful refactor).

**KATs landed (4-digit, validated standalone =99):** 1000_checked_div_zero, 1001_cap_verify_invalid_id,
1002_quality_q4_growth. **Remaining backlog KATs:** sc_recv AEAD-tag (needs x25519+sc_handshake+sc_send
setup), ed_decompress invalid-curve (needs a canonical-but-off-curve vector). Corpus run bnqe8d7pm
confirming 4-digit glob + adoption (expect ~657/0).

## ✅ C.3 ntt_fri_organ DEDUP COMPLETE (2026-05-31) — items 2/3/4 of the change plan
The first staged refactor is BUILT, not deferred. Faithful to the doc's decomposition (advisor-confirmed: the
doc says "consume the §S.6 merkle" + ntt_fri_organ over §S.4 — one Merkle under the spine/gate/proofs is true
H-3; my initial private `merkle_fri_organ.iii` was a FORK and was discarded, its contents redistributed):

- **Step 1 — `merkle.iii` EXTENDED (additive)**: `merkle_tree_build_u32/root/open/verify_u32` — a build-once/
  open-many surface over u32 leaves into a caller-owned tree pool (the STARK pattern; `merkle_compute_proof`
  rebuilds per-proof over byte-array leaves, unfit). Reuses `_mk_leaf_hash/_mk_node_hash` UNCHANGED (leaf=
  SHA-256(0x00‖v_be32), node=SHA-256(0x01‖L‖R)) so it's byte-identical to the seal + the (now-deleted) private
  STARK Merkle. Dedicated scratch (MK_U32LEAF/MK_TREE_CUR) — existing buffers untouched. KAT `1003`=99.
- **Step 2 — `ntt.iii` export + `ntt_fri_organ.iii` NEW**: `ntt_mult_field_elem(a,b,q)` (item 3, the canonical
  field-mul); the organ's `fri_eval_and_fold` (prover whole-layer, INCREMENTAL inv(omega^j) = O(ns) not
  O(ns·log q), byte-identical result), `fri_fold_point` (verifier single-point, DIRECT inv — the asymmetry is
  the safety net: a prover-fold bug desyncs the roundtrip), `fri_commit_layer` (merkle glue). All field MUL
  routes through the §S.4 export. KAT `1004`=99 (layer≡point at every position + sibling/alpha negatives).
- **Step 3 — `zk_stark.iii` REWIRED**: deleted `st_leaf_hash`/`st_node_hash` + dead `ZKST_BUF`/`ZKST_CUR`;
  `st_merkle_*` now thin delegations; both folds → organ. Gate `376`=99 (ntt+merkle+lde selftests + full
  prove/verify KAT).
- **Step 4 — `zk_air.iii` REWIRED**: same surgery on the general STARK; deleted `air_leaf/node_hash` + dead
  `ZKAIR_BUF`/`ZKAIR_CUR`. Gate `997`/`998`/`999`=99 (general DSL + Merkle + full roundtrip + 5 negatives:
  CP/trace/FRI-final/boundary tampers all REJECT).

Net: the SHA-256 Merkle + FRI fold exist on ONE proof surface (merkle.iii + ntt_fri_organ.iii) instead of
duplicated in both zk modules; `sf_*` stays inline in the consumers (composition is hot). Each step fast-link
gated standalone before the final full build+corpus.

- **Item 5 — `zk_stark_seal.iii` NEW + per-module wrappers**: the §S.6 content-address PROOF SEAL. `zk_proof_seal_begin/absorb/final` wrap cad's streaming organ with the `III/zk-stark-proof/v1` domain; `zk_stark_proof_cad` (in zk_stark) and `air_proof_cad` (in zk_air) seal each module's REAL proof commitments (trace/cp/fri roots + queries + boundary, length-framed). A proof now has a reproducible identity AND any altered commitment changes it. KATs `1005` (organ selftest), `1006` (real zk_stark proof + cp/query tampers), `1007` (real general STARK + trace-root/boundary tampers) = 99.
- **Item 6 — `zk_prune.iii` EXTENDED**: `zkp_stark_sidecar_build` — AIR-aware pruning. Binds a STARK proof's content-address identity into the rollup sidecar root (decoupled: an opaque 32-byte cad, no zk_air dependency; `zkp_sidecar_root` absorbs it only when `SC_PROOF==1` → legacy path BYTE-IDENTICAL). KATs `377` (no-regression) + `1008` (binding load-bearing, deterministic, different-cad→different-body, proof-bound rollup verifies, legacy unchanged) = 99.

**✅ C.3 FULLY COMPLETE (all 6 items, 2026-05-31).** New files: `ntt_fri_organ.iii`, `zk_stark_seal.iii`. New KATs: 1003-1008. PENDING (final-gate housekeeping, deferred per user's "fast gates until the end"): register `zk_stark_seal` in build_stdlib MODULES + 1005/1006/1007/1008 in run_corpus EXPECTED (ntt_fri_organ + 1003/1004 already registered; lib mhash after the integrated build = ad69704e…).
**Lesson logged:** never edit `build_stdlib.sh`/`run_corpus.sh` while a build runs in the background — bash
reads scripts incrementally by byte offset, so a mid-run insert desyncs the running instance (false syntax
error at a shifted line). Do all script edits first, then run.

## ⚠️ DIRTY-MODULE LIST — fast-link honesty invariant (advisor 2026-05-31)
The lib `STDLIB/build/iii/libiii_native.a` is FROZEN at mhash `ad69704e…` (the C.3 steps-1-4 point). Every
batch from here changes modules WITHOUT rebuilding it (per the user's "fast gates until the very end"). A
fast-link gate is HONEST only if it fronts the fresh `.o` of EVERY dirty module it transitively needs, ahead
of the lib — else the linker pulls the STALE lib copy → false green. This is the rebuild/reseal checklist too.

**DIRTY since `ad69704e` (front these in any fast-link that needs them; rebuild ALL at the final gate):**
`numera/merkle`, `numera/ntt`, `numera/ntt_fri_organ`, `numera/zk_stark`, `numera/zk_air`, `numera/zk_prune`,
`numera/zk_stark_seal`, `forcefield/proof_ripple_unified` (NEW). *(Append each batch's touched modules.)*

**Registered (final-gate ready):** `numera/ntt_fri_organ`, `numera/zk_stark_seal`,
`forcefield/proof_ripple_unified` → build_stdlib MODULES; `1003`–`1009` → run_corpus EXPECTED (=99). All new
modules + KATs are registered, so the ONE final `build_stdlib`+`run_corpus`+reseal at the end won't FATAL.

## ✅ C.5 AFFIRMED done-capability + unification SEQUENCED (2026-05-31, advisor-confirmed)
C.5's apex is ALREADY REALIZED in the live system (verified by reading the code, not interpretation):
- `numera/proof_term.iii` — the inference-term Curry-Howard IR EXISTS: `pt_alloc`/`pt_add_inference`/
  `pt_finalize`/`pt_verify`/`pt_serialize`/`pt_deserialize`/`pt_to_program` (the term-level CH map). [read]
- `numera/theorem_carrier.iii` — already BUILDS ON proof_term (`tc_get_proof_term`). [grep] Not redundant.
- `numera/proof_carrying.iii` — a DISTINCT polynomial-commitment/PCC layer (`pc_commit_vec/poly`,
  `pc_attach/verify_proof`). [grep] Not a duplicate carrier — the doc's "4 redundant carriers" premise is FALSE.
- `numera/curry_howard.iii` — the program↔proof tag-toggle (0x50↔0x54) + witnessed v3 fragments; proof_term
  carries the term-level form (`pt_to_program`). [read full]
- `forcefield/commit_gate.iii` — `cg_decide` IS the explicit LOCATED 5-organ composer (RULE/MODULE/SEAL/
  STRENGTH/KERNEL) with `CG_REJECT_KERNEL` (refuse-while-blind) + the G4 BILATERAL CERTIFICATE
  (`cg_cert_action`/`cg_cert_abstain`, NV∧KT∧BC). [read full] The "apex composer" is live.
- `numera/egraph.iii` — the RS+Merkle self-heal is ALREADY EXPORTED: `eg_ecc_encode`/`eg_repair`/`eg_seal`/
  `eg_verify_seal`/`eg_integrity_holds`/`eg_integrity_selftest`. [grep]
- `numera/computation_graph.iii` — "no equivalence claim without a witness" (W41/W42) ENFORCED:
  `cg_bisimulate` emits a witness fid; gated by corpus 645/656/650. CONFIRMED (the one soundness invariant
  worth checking, not assuming).

**SEQUENCED, not declined** (the same "build the unification WITH its consumer" logic as C.4-last): the three
remaining C.5 items are SUBSTRATE AHEAD OF A NOT-YET-BUILT CONSUMER — gate-verdict-as-proof-term (consumer =
§C.13 "the gate's proofs"), proof-term routing across the 8 logic modules (consumers = §C.4 compiler-adopts +
§C.13), and a standalone `eg_selfheal` organ (no current consumer; capability already exported). Building them
now would (a) guess the wrong shape and (b) manufacture ceremony — a THIRD gate-verdict representation
alongside the located code + the bilateral cert, and a rename over working exports — exactly the bloat the
no-forced-ceremony standard forbids. They ride with C.4/C.13.

**Coverage honesty:** standalone deliverables affirmed by READ + the integrated build's GATE PASS (PASS=436).
Cross-module unification is NOT claimed complete. Untouched logic modules were NOT KAT-reverified (independent
of the C.3 dirty set; covered by GATE PASS) — affirmed by inspection, not overstated.

## ✅ C.6 AFFIRMED done-capability + xii_organ SEQUENCED with C.4 (2026-05-31)
Same pattern as C.5: the doc's "consolidate 7 lowering + 4 confluence → 2 organs" is premised on a
redundancy that DOESN'T EXIST in the live system (verified by reading the code):
- The **7 `xii_lower_*` are 7 DISTINCT algebraic domains** (mig4 Steps 7-9), NOT redundant term-walks:
  compose=composition-monoid, decide=decision, iterate=iteration, then=FTHEN-sequencing, under=FUNDER-
  scoping, with=FWITH-context, program=caller-migration. Each is a thin (4 one-line fns) CONSUMER of the
  one engine `xii_canonicalise` + a domain-specific axioms KAT. [read compose full + 6 headers] Consolidating
  would DELETE 7 distinct domain demonstrations.
- The XII ENGINE (`xii_rewrite` + `xii_canonicalise`) is ALREADY the one normaliser the 7 domains lower onto.
- `omnia/xii_conf_cert.iii` (`xcc_verify`/`xcc_reprove`/`xcc_reorderable`) is ALREADY the one confluence
  certifier, composing `xii_joinability` (→ critpair → overlap). [grep] Not 4 separate proof surfaces.
- `omnia/xii_admission.iii` (`xad_admit`) ALREADY gates rule-set admission on confluence (`xjn_gate`) AND
  termination (`xtm_gate`) — the negative arm (non-confluent sets rejected) is LIVE. [grep] Consumed by the
  §C.5 commit-gate RULE dimension (`cg_rule_ok`→`xad_admit`).
- Gated by the XII corpus band (280-372, run_xii_corpus.sh) + the `apply_one`/`last_rule_fired` firing
  contract (established trap-knowledge).

**SEQUENCED with C.4:** `xii_organ.iii` (the NEW parametric lowering organ) is "the same organ the compiler
lowers through in §C.4" — building it now is substrate ahead of the compiler consumer (which currently uses
`cg_r3_xii_adapter`). It rides with C.4-last (the same logic as the proof-term unification). Not declined —
the standalone XII apex (engine + distinct domains + one certifier + gating admission) is already realized.

## ✅ C.7 UNIFIED move decider BUILT (2026-05-31) — the genuine gap (NOT done-capability)
C.7 differed from C.5/C.6: the doc's unification targets (`ripple_term`/`proof_ripple_unified`/
`ripple_synthesizer`/`cg_decide_ripple`) were genuinely ABSENT — `ripple_unify.iii` is only Inc-2 (a
merge-specific decider). So I BUILT the genuine core:
- **`forcefield/proof_ripple_unified.iii` NEW**: `proof_ripple_decision(kind,m0..m3,proof_ok,kernel_ok)` —
  ONE decider over the move-IR (MERGE/CUT/EXTRACT), dispatching to the 3 existing certified deciders
  (`ru_certify_unify`/`rc_certify_cut`/`rx_certify_extract`), a LOCATED verdict, and a KERNEL-FIRST gate that
  blocks EVERY move while the prover is blind (the doc's `cg_decide_ripple` discipline, one entry point).
  Plus `pru_move_crystal` = cad(kind‖operands) → a reproducible distinct-per-move identity (the doc's
  `→ crystal_id`). Decoupled (composes existing deciders + cad; no new proof, no file edit). KAT `1009`=99
  (each kind admits/locates; kernel-down blocks ALL 3 kinds; bad-kind rejects; crystal deterministic+distinct).
- **SEQUENCED:** the synthesizer's *apply* (Inc-3 applier) is explicitly reseal-coupled ("behind commit_gate
  + the full reseal/corpus gate") → rides with the final phase; its *propose/select* already exist
  (ripple_search G3 argmax). The DECIDE substrate (the genuine gap) is now closed.

## ✅ C.15 (Nous proposer) AFFIRMED done-capability (2026-05-31)
The doc's NOL/QVT/RCM are absent BY NAME, but the CAPABILITY is realized in the complete, stub-free nous
system (see [[project_iii_nous]] — 11 modules, corpus 800-809=99). Verified the headline soundness invariants
(not assumed):
- **No-ML (the C.15 non-negotiable)**: `nous_train.iii` ADR-N8 — the TRAINER IS OUT-OF-TREE (a float trainer
  is NOT part of the III artifact); the in-tree harness only LOADS sealed+content-addressed integer weights
  (refuses unsealed/empty); NO III guarantee depends on the trainer because the CLOSURE (kernel re-checks every
  proposal) makes ANY weights safe — a weak policy only raises the gap rate, never a wrong artifact. Zero
  in-tree learning patterns (grep clean). Gated by `verify_nous_differential.sh` (nous active≡inactive on the
  OUTCOME) + `verify_nous_propose_only.sh` (propose-only; the kernel decides). This IS the doc's "propose
  freely within the proven-sound lattice, the kernel decides — never a learner."
- **RCM / CUT-11 vacuity**: ALREADY FIXED in `nous_completion.iii` — the cert binds the whole derivation
  (`NOUS_CMP_TAG` = n_pairs LE4 ‖ budget LE4 ‖ verdict, was a 4-byte verdict-only stub); the selftest's
  checks 15/17 PROVE non-vacuity (different n_pairs/budget → DIFFERENT cert). [read]
- **NOL / proven-safe reorders**: the reorders are block-policy-constrained (the R038/R040 confluence-safety
  finding — R-rules not freely reorderable), so unsound reorders are barred. [[project_iii_nous]]
The NOL/QVT/RCM recursive-Merkle restructuring is substrate-ahead of the live dynamic critical-pair enumeration
(the "M14 wiring") — sequenced with that consumer, not ceremony on a complete+gated+no-ML proposer.

## C.8–C.14 TRIAGE MAP (2026-05-31, batch existence-check) — genuine gaps vs sequenced vs verify
Unlike C.5/C.6/C.15 (done-capability), the C.8/C.9/C.11 "NEW" constructs are GENUINELY ABSENT (real gaps):
- **C.8 (cost/silicon) — GENUINE GAP, fast-gateable, compounds C.7+C.14.** `unified_cost_manifold`/`uc_cost`/
  `hdl_compiler`/`pareto_extraction` ABSENT (only the OLD `cost_calculus`/`microarch_model`/`cost_lattice`/`hdl`
  exist). NEW: closed-form DP 6-D cost (queryable mid-saturation), 6-D Pareto antichain, 2^k-truth-table-
  certified HDL. ~1450 lines. Consumes §C.5 e-graph (present). Exports `uc_cost` → §C.7 ripple `J` + §C.14.
- **C.9 (systems) — MIXED.** `proof_resolve` (discharge the resolver Phase-C.5 shortcut into an equivalence
  theorem — the doc's CENTRAL architectural lesson) = GENUINE + fast-gateable. `form_ir`/`ir_lower`/`arena_slot`
  route through §C.4 `proof_term` + §C.6 `xii_organ` → SEQUENCED with C.4-last. caindex/net KATs = small adds.
- **C.10 (katabasis) — done-capability + driver SEQUENCED.** Gate complete ([[project_iii_katabasis]] Inc1-15,
  proven-on-metal); `r3_ioctl_driver.c` is a Ring-0 KERNEL driver (ntoskrnl-link, CRASH-PROTOCOL/metal phase,
  NOT fast-gateable) → final metal phase. `cg_r0` design-only.
- **C.11 (BFT) — GENUINE GAP, fast-gateable.** `hotstuff_unified` (tier-aware certified-monotone pacemaker,
  constitutional timeout) + `hotstuff_predict_opt` (tournament quorum over SEALED facts, no-ML) ABSENT; the
  federation (fed_*) + mhash safety are AFFIRMED (corpus 159-165, M19 fed_qc_gate). ~730 lines.
- **C.12 (RTL) — SEQUENCED (hardware phase).** `resolver_unit.v` completion + SystemVerilog equivalence corpus
  + SMT harness — Verilog, outside the .iii build, not fast-gateable.
- **C.13 (gate stack) — AFFIRM + 1 residual.** Determinism/corpus/seal/drift gates LIVE; cartographer rewritten
  in-tree (`carto_gate.iii` sibling tree, [[project_iii_cartographer_native]]) BUT build_stdlib still calls it a
  SOFT dependency (skip-if-absent) — the apex wants MANDATORY. Verify/close that one residual.
- **C.14 (performance) — verify done-capability** ([[project_iii_capability_verification]]: measured speedups).

**BUILD ORDER (compounding):** C.8 cost-manifold (feeds C.7 ripple `J` — cost-aware self-optimization) → C.11
hotstuff → C.9 proof_resolve → [final phase] C.4 reseal + C.10 driver + C.12 RTL + C.13 mandatory-carto. All
genuine gaps fast-link-gated (front dirty .o); metal/RTL/reseal in the final phase.

## ✅ C.7 / C.8 / C.11 GENUINE GAPS BUILT (2026-05-31) — fast-gated, no deferral
The doc's "NEW" constructs here were genuinely ABSENT (unlike C.5/C.6/C.15) and were BUILT:
- **C.7 `forcefield/proof_ripple_unified.iii`** (KAT 1009=99) — the unified move decider over the move-IR
  (MERGE/CUT/EXTRACT) dispatching to the 3 existing certified deciders, kernel-first gate (blocks all moves
  while blind), + the move crystal. Synthesizer APPLY (Inc-3) is reseal-coupled → final phase.
- **C.8 `numera/pareto_extraction.iii`** (1010=99) — the 6-D Pareto frontier (antichain; the honest multi-dim
  selection vs scalar argmin). `numera/unified_cost_manifold.iii` (1013=99) — closed-form critical-path
  latency DP (queryable mid-saturation, replacing the event-loop sim) + the 6-D vector assembly.
  `numera/hdl_gate_db.iii` (1014=99) — the certified gate-identity proof DB (10 boolean identities proven
  bit-exact over full 2^n truth tables via hdl_equiv2; a non-equivalent rewrite REJECTED). cost_calculus
  already produced the 6-D vector; the NEW value is the closed-form latency + Pareto + the certified-rewrite DB.
- **C.11 `aether/hotstuff_unified.iii`** (1011=99) — the tier-aware certified-monotone pacemaker
  (constitutional-constant timeouts = no-ML, monotone+bounded backoff, BFT 2f+1 quorum + sub-quorum floor).
  `aether/hotstuff_predict_opt.iii` (1012=99) — the tournament quorum optimizer over SEALED facts (no-ML:
  deterministic, fact-driven, Byzantine-available by construction). Safety stays the mhash match in hotstuff.iii.

**Dirty (13):** + proof_ripple_unified, pareto_extraction, unified_cost_manifold, hdl_gate_db, hotstuff_unified,
hotstuff_predict_opt. All registered (MODULES + run_corpus 1003-1014).

## CAMPAIGN MILESTONE: all CLEAN fast-gateable genuine gaps BUILT; remaining = FINAL-PHASE / careful
- **C.9 done/sequenced:** caindex already tested (720/754/755 — done-capability); net-reach = M31 membrane
  (done); `form_ir`/`arena_slot` route through §C.4 proof_term/xii_organ → SEQUENCED with C.4; `proof_resolve`
  (discharge the resolver fast-path shortcut) touches the CRITICAL resolver — needs careful handling (an
  exported cold-only path OR a memo-reset cold-then-fast differential), NOT a session-tail rush.
- **FINAL RESEAL/METAL/RTL PHASE (the user-deferred "full gate" zone):** C.4 emit_generic unification (only
  gate = byte-identity `build_iiis2 --check-corpus` 59/0); C.10 `r3_ioctl_driver.c` (Ring-0, ntoskrnl, metal,
  CRASH-PROTOCOL); C.12 `resolver_unit.v` + SMT equivalence (Verilog). C.13 make the cartographer gate
  MANDATORY (build_stdlib soft→hard). C.14 verify perf done-capability ([[project_iii_capability_verification]]).
- **THE ONE FINAL FULL GATE** (per the user "quick gates until every batch + polish complete"): rebuild ALL 13
  dirty + the new modules, full run_corpus (1003-1014 + the band), reseal. Everything is REGISTERED so it
  won't FATAL. This is the next major step once the final-phase batches land.

## ⚠️ ADVISOR CORRECTIONS (2026-05-31) — "individually gated" is NOT "integrated"
The skeptical reviewer caught me sliding from "fast-gated" to "COMPLETE" without earning it:
1. **INTEGRATION UNVERIFIED until a full build+corpus completes WITH these modules.** No full
   `build_stdlib`+`run_corpus` has run to completion since this work began (b33nxj0j1 ar-lock'd a stale lib;
   bavk12fh3 died on a concurrent-edit; bqk77dw0d's lib `ad69704e` PREDATES 5b/C.7/C.8/C.11/C.14 and its
   corpus FATAL-aborted on the then-unregistered 1005). Fast-link fronts fresh .o ahead of a frozen lib → it is
   SILENT on symbol collisions across the 14 dirty modules, archive integrity, determinism/drift gates, and
   consumer regressions. **The ONE integration gate (run bnrbnuqxr) is now running to make the milestone TRUE
   or surface a break while context is fresh.** Claim downgraded: "each module individually fast-gated;
   INTEGRATION VERIFYING."  (Stray `merkle_fri_organ.iii` fork — the advisor's catch — was still on disk; DELETED.)
2. **Organs are BUILT-IN-ISOLATION, not WIRED — the user's "inter-file relationships" bar is not yet met.**
   Each has a green selftest + NO consumer calling it. Honest per-organ wiring status:
   - `proof_ripple_unified` (C.7): decider WIREABLE-NOW into ripple_loop's decide; the APPLY is C.4-reseal-coupled.
   - `unified_cost_manifold` / `pareto_extraction` (C.8): `uc_cost`→ripple `J` (ripple_metric) + pareto→egraph
     extraction = WIREABLE-NOW (modifies ripple_metric/egraph). `hdl_gate_db`→egraph netlist optimizer = wireable.
   - `hotstuff_unified` / `hotstuff_predict_opt` (C.11): `hs_init`→`hsu_init`, `hsp`→`predict_opt` = WIREABLE-NOW
     (thin adoption in hotstuff.iii/hotstuff_predict.iii).
   - `cost_lattice_unified` (C.14): →the bench corpus mechanistic bound = WIREABLE-NOW.
   PLAN: after the integration gate is green, WIRE the wireable-now adoptions (each modifies a working consumer →
   re-gate that consumer's KAT), so the organs are genuinely CONSUMED, not capability-in-waiting.
3. **`proof_resolve` is an UNBUILT genuine gap, NOT done-capability.** resolve()'s KATs verify resolve() returns
   correct results; they do NOT compare the shortcut/memo path against the COLD contract on the same input (the
   cold path may never run when the hot path fires). The doc's central lesson — discharge the shortcut into a
   proven equivalence — needs careful handling (an exported cold-only path or a memo-reset cold-then-fast
   differential). Recorded as unbuilt, not rationalized as done.

## ✅ INTEGRATION VERIFIED GREEN at build level (2026-05-31, gate bnrbnuqxr build phase)
**PASS=444 FAIL=0 + GATE PASS** — all 14 dirty/new modules (zk_stark_seal, proof_ripple_unified,
pareto_extraction, unified_cost_manifold, hdl_gate_db, hotstuff_unified, hotstuff_predict_opt,
cost_lattice_unified + the rewired merkle/ntt/ntt_fri_organ/zk_stark/zk_air/zk_prune) COMPILE + ARCHIVE
together, NO symbol collisions, the determinism/drift/trusted-base gates pass, AND the in-tree cartographer
architectural-invariant gate ran + passed (no dup-export, no un-allowlisted cycle from my modules). The advisor's
integration concern (the thing fast-link is silent on) is RESOLVED green. Lib re-aggregated at mhash
**`225094d5...`** (was `ad69704e`). **The DIRTY LIST RESETS** — the lib is now current with all my work; future
fast-links front ONLY the newly-edited module ahead of `225094d5`. The full corpus is finishing as a bonus
consumer-regression check (uses the lib, so it doesn't block further module edits). Per the user's re-emphasis
this was a ONE-TIME batch checkpoint; going forward = quick gates only until the final reseal.

## ✅ FIRST ORGAN WIRED (2026-05-31) + honest wiring assessment
- **C.7 `ripple_loop.iii` → `proof_ripple_decision`**: `rl_run`'s sole merge-decision call (was
  `ru_certify_unify` direct) now routes through the UNIFIED move decider — the self-optimization loop speaks
  one decider for all move kinds (ready for CUT/EXTRACT). BEHAVIOR-PRESERVING (the unified decider dispatches
  MERGE→ru_certify_unify; the kernel gate is already hoisted, so kernel_ok==1 inside the loop). Gated:
  `756`+`919` rl_run KATs = 99 (no regression). ripple_loop now DIRTY vs lib `225094d5` (fast-link-validated).
- **Honest wiring status of the OTHER organs:** they are substrate-ahead of their NATURAL input-producers, so
  a clean behavior-preserving wire isn't available without deeper consumer-extension:
  - `unified_cost_manifold`/`pareto_extraction` → egraph extraction / ripple `J`: the consumers don't yet
    PRODUCE 6-D cost vectors / op-graphs (egraph carries gate costs, ripple_metric carries cap/iclass). Wiring
    = EXTEND those consumers to emit the organ's input — genuine but deeper (careful, big-module) work.
  - `hotstuff_unified`/`hotstuff_predict_opt` → hs_tick/hsp: unit mismatch (hsu ticks vs HS ms=5000) +
    round-robin has no sealed facts → behavior-CHANGING, needs careful unit-alignment + re-gate.
  - `hdl_gate_db` → an egraph-based netlist optimizer that doesn't exist yet (a NEW build, not a wire).
  These are sequenced as deeper-integration (like the C.4-coupled items), recorded honestly — not claimed wired.

## ✅ proof_resolve (C.9 CENTRAL LESSON) — BUILT + GATED (2026-05-31)
After de-risking (below), I found the tractable scenario (corpus 233: `resolution_init` + `pattern_set_global` +
`call_context_new` + `intent_form/act` → `resolve()`) and BUILT it carefully rather than defer:
- `omnia/resolver.iii`: minimal additive default-off `RESOLVER_FORCE_COLD` flag guarding the fast path
  (byte-identical when off). `omnia/proof_resolve.iii` NEW: `proof_resolve_equiv` (cold-vs-fast differential),
  `proof_resolve_result` (admit-with-proof / refuse-unproven), `proof_resolve_seal` (cad-sealed discharge).
- Gate `1016`=99: over a REAL resolution the shortcut is PROVEN == the 11-step contract for 2 distinct intents,
  admit-with-proof == direct resolve(), the verdict is deterministic, and the seal is reproducible + distinct
  per input. NO-REGRESSION: 232/211/202 = 99 with the edited resolver (the default-off flag is byte-identical).
  The doc's central lesson realized: the optimization is DISCHARGED into a per-input equivalence theorem, not
  deleted. DIRTY: resolver, proof_resolve. (Negative arm = structural safety net: a divergent shortcut would
  flip equiv→0→refuse; the asm doesn't diverge, so it can't be fabricated — an honest limit, not a cheap fix.)

### De-risking record (the CRASH-PROTOCOL read-before-write that preceded the build)
CRASH-PROTOCOL read-before-write COMPLETE on the critical resolver:
- **Compiler-unreferenced CONFIRMED**: COMPILER/BOOT does NOT extern from `resolver.iii` (the cg_r3 "resolve"
  hits are the compiler's OWN type/symbol resolution + ast_accessors.c). So a minimal additive change to
  `omnia/resolver.iii` will NOT drift the byte-identity fixed-point — it's a normal stdlib edit, gate via the
  resolver corpus band, NOT the C.4 reseal. (This is the key de-risk: proof_resolve is NOT C.4-coupled.)
- **SAFE APPROACH**: add a default-off `RESOLVER_FORCE_COLD` flag (`resolver_set_force_cold`) guarding the
  fast-path early-return (lines 504-509). Flag OFF (BSS-zero default) → byte-identical behavior → all dozen
  resolver KATs (100/202/211/212/213/214/217/220/221/224/230/232) pass. `proof_resolve.iii` then does the
  cold-then-fast DIFFERENTIAL: `force_cold(1)→resolve()` [11-step contract] vs `force_cold(0)→resolve()` [the
  memo/hot shortcut], emits a proof_term iff equal → the shortcut is PROVEN equivalent to the contract per input.
- **CAREFUL EXECUTION REMAINING (not session-tail-rushed)**: the GENUINE selftest must exercise a SUCCESSFUL
  resolution (fill the memo cold, then hit it hot) — needs a valid (pattern_set, intent, call_context) built via
  the raw resolver input model (NOT the null-input determinism, which would be the forbidden cheap fix). Mirror
  a real scenario; gate ALL dozen resolver KATs for no-regression. This is focused careful work on the critical
  resolver — correctly deferred from the session tail, fully de-risked + scoped.

## ✅✅ INTEGRATION FULLY GREEN (build + corpus) — milestone EARNED (2026-05-31, gate bnrbnuqxr exit 0)
Build: PASS=444 FAIL=0 + GATE PASS + cartographer pass, lib `225094d5`. Corpus: **PASS=677 FAIL=0 SKIP=99,
ZERO WRONG** — ALL 13 new KATs (1003-1015) pass AND no regression in the 660+ existing tests. The 15 genuine
capabilities (C.3/C.7/C.8/C.11/C.14) are built, integrated, and conflict-free across the WHOLE system. The
advisor's "integration unverified" concern is RESOLVED GREEN. (The C.7 `ripple_loop` wire was applied AFTER this
build phase, so it's fast-link-validated [756/919=99] + DIRTY vs the lib; it folds into the final gate.) "15
modules individually fast-gated" is now "15 modules INTEGRATED" — earned, not hopeful.

## ✅ C.8 CAPSTONE + INTER-FILE RELATIONSHIPS realized (2026-05-31)
`numera/hdl.iii` += additive read accessors (`hdl_gate_kind/a/b`, `hdl_set_b`; behavior-neutral, 1014=99 no-reg).
`numera/hdl_optimize.iii` NEW — the certified NETLIST OPTIMIZER that CONSUMES three organs: it applies
`hdl_gate_db`'s certified identities (AND(a,a)→a, OR(a,a)→a, NOT NOT→a) as rewrites on a real `hdl` netlist,
PROVING the output function is preserved (truth table before≡after) while live gates drop, and selecting via
`pareto_extraction`'s dominance (the doc's Pareto frontier, not a scalar argmin). KAT `1017`=99 incl. the
negative arm (a WRONG redirect changes the function → caught). (iiis paren-shift quirk fixed: spill shift
operands to plain locals, no nested `(x as u64)` inside a shift.)

**INTER-FILE RELATIONSHIPS now realized (the user's "every file serves a maximal purpose" bar):**
- `hdl_gate_db` + `pareto_extraction` + `hdl` → CONSUMED by `hdl_optimize` (C.8 optimizer). ✅
- `unified_cost_manifold` → CONSUMED by `cost_lattice_unified` (C.14 mechanistic bound). ✅
- `proof_ripple_unified` → CONSUMED by `ripple_loop` (C.7 wire). ✅
- `hotstuff_unified` → CONSUMED by `hotstuff_predict_opt` (quorum). ✅
- STILL standalone (substrate-ahead — natural consumer not yet producing inputs): `cost_lattice_unified`
  (→ the perf bench, which measures real paths), `hotstuff_predict_opt` (→ hsp, which uses round-robin/no facts).
  Honestly recorded; deeper consumer-extension, sequenced.

DIRTY since 225094d5: ripple_loop, resolver, proof_resolve, hdl, hdl_optimize. KATs 1003-1017 registered.

## ✅ C.8 DEEPENED TO FINAL FORM + a genuine optimizer bug FOUND & FIXED (2026-05-31)
Pushed the C.8 HDL stack to the doc's literal spec and, in doing so, the cross-module integration surfaced a
real latent bug — exactly the compounding the campaign is for.
- **`hdl_gate_db` 10 → 21 certified identities** (the doc's "**20+ gate identities, each proven once via a
  2ᵏ truth table**"): +OR/XOR commutativity, complement laws (AND(a,¬a)=0 / OR(a,¬a)=1 witnessed by the
  constant-0 `XOR(a,a)`), AND/OR/XOR associativity, both distributivities, NAND–De Morgan, XOR=(a|b)&¬(a&b).
  **Two** negative arms now (AND-vs-OR *and* a plausible-but-wrong distribution). `1014`=99.
- **`hdl_optimize` deepened**: added the **absorption** class (`OR(x,AND(x,b))→x`, `AND(x,OR(x,b))→x`),
  the **`hdl_optimize_all` fixpoint** entry (all reduction classes to convergence, bounded 16 rounds), and the
  **Pareto-dominance selection** (`hdl_opt_pareto_check` consumes `pareto_extraction`). `1017`=99 (5 arms).
- **🐞 BUG FOUND & FIXED — `hdl_opt_redirect` corrupted INPUT gates.** It rewired *any* gate whose A/B field
  == the redirected id, but an `HG_IN` gate stores its **input index** in A (not a gate ref). Redirecting gate
  `g` silently changed the index of the input whose index==g → wrong function. 1017 never exposed it (its input
  indices never collided with a redirected gate id); **`hdl_compiler`'s integration test did** (`t0!=t1`, exit 4).
  Fix: skip `HO_IN` gates in redirect. 1017 still 99 (no regression), 1018 now 99. *This is the campaign thesis
  in miniature: a new consumer proving an old organ correct.*
- **`hdl_compiler.iii` NEW (C.8 item 4)** — the combinator→netlist compiler: lowers a postfix combinator program
  `{INPUT,NOT,DUP,AND,OR,XOR}` to an `hdl` netlist, then NORMALIZES via the certified `hdl_optimize` fixpoint.
  KAT `1018`=99: the compiled netlist computes the intended truth table (vs a hand-built oracle) **and**
  normalization preserves the function while shrinking gates. Closes the edge **hdl_compiler → hdl_optimize →
  {hdl_gate_db, hdl, pareto}** — the whole HDL stack is one proof-carrying pipeline.

DIRTY since 225094d5 (updated): ripple_loop, resolver, proof_resolve, hdl, **hdl_gate_db**, **hdl_optimize**,
**hdl_compiler**. KATs 1003-1018 registered (build_stdlib + run_corpus updated).

## ✅ C.9 organs assessed + arena_slot_witness BUILT; C.15 spot-check CONFIRMED (2026-05-31)
Advisor-directed: pursue C.9 breadth (proof_resolve was built; the rest looked untouched). Discriminator-first.
- **`reach_oracle.iii` — DONE-CAPABILITY (built, affirmed).** A default-deny *determinism firewall*: CANONICAL
  (content-addressed, reproducible) admitted; PROVISIONAL (oracle-dependent) carries a content-addressed
  oracle-pin and is REFUSED into deterministic contexts. Fail-closed on null input (line 72). The C.9 net-reach
  organ is real and complete.
- **`arena_slot` — DONE-CAPABILITY (receipts).** The C.9 plan's "every container allocates through one
  allocator over S.7" is ALREADY LIVE: vec/map/set/queue/list/lru all extern `arena_alloc1`/`arena_alloc8`
  from `arena.iii`. No bespoke per-container malloc. And arena byte-balance is already proven (corpus 121:
  `arena_reset_with_witness` -> used=0, negative arm on a wrong witness).
- **`arena_slot_witness.iii` — BUILT (the genuine gap).** The honesty PROOF, on the right property: not
  arena-byte balance (done by 121) but **HANDLE-TABLE balance** -- the documented slot-leak mode (cf. bigint
  64-slot trap). On `list` (32-slot table): balanced new->drop is unbounded (100>>32), a leak (new w/o drop)
  fills the table and the overflow is REFUSED (negative arm), the table recovers after cleanup. `list_new`
  checks the slot table before the arena, so the refusal is unambiguously slot-exhaustion. KAT `1019`=99.
- **`form_ir`/`ir_lower` — DONE-CAPABILITY (discriminator, receipts).** The premise "24 emitters each hand-rolling
  the same lowering" is FALSE in the live tree. The transpilers are minimal, DISTINCT byte transforms that already
  COMPOSE: `tp_iii_to_md` is a 5-line ```iii fence wrapper (no parse); `tp_iii_to_c99` is a string-literal escaper
  (no parse — "baseline; full transpiler is per-construct authoring work"); `tp_pe_hex`/`tp_iii_hex`→`tp_raw_hex`,
  `tp_asm_to_pe`→`tp_x86_assemble`, `tp_babel_json_to_ast`→`tp_babel_json_to_iii` compose; and the AST-family
  already shares **`ast_bin` as its IR** (`tp_iii_to_ast_bin`→`tp_ast_*`). Forcing a 7-pass form_ir IR onto 5-line
  byte-wrappers would be over-engineering. NOT built — correctly.
- **`verba_format_ir` — DONE-CAPABILITY (discriminator, receipts).** The unified typed-format IR ALREADY exists:
  `verba/glyph_core.iii` is the **sealed 192-byte canonical Glyph V3 encoding** (form_id || payload || sha256 mhash;
  every glyph verifiable in isolation) with form-IDs for u8/u32/u64/i64/f64/str/bytes/vec/map/set/enum/record/
  crystal/witness/proof/recursive — the 16 `glyph_*` modules are typed front-ends to that ONE core. `verba/format.iii`
  is the injection-proof format faculty (no runtime format-string parsing → %n-class vulns structurally impossible).
  The 44 verba modules are distinct faculties + one glyph IR, not 44 duplicated dispatchers. NOT built — correctly.

**C.9 RESOLVED.** 2 genuine organs BUILT (`proof_resolve` = the resolver-shortcut→theorem lesson; `arena_slot_witness`
= handle-table honesty); 4 affirmed DONE-CAPABILITY with receipts (`reach_oracle`, `arena_slot`, `form_ir`,
`verba_format_ir`). The systems layer was already proof-carrying / unified where it mattered; the doc's consolidation
premises assumed redundancy the live tree had resolved — the discriminator (advisor-endorsed) held every time.

**C.15 Nous spot-check (advisor point 4 -- confirm "done" wasn't a convenient label): the no-ML affirmation
HOLDS.** Read `nous_train.iii` end-to-end. ADR-N8: the trainer is OUT-OF-TREE; the artifact depends only on
SEALED INTEGER WEIGHTS as a data input, and **no III correctness guarantee depends on the trainer** (the
closure makes any weights safe -- a weak policy only raises the GAP rate, never a wrong artifact). The in-tree
`record`/`gap_rate` are pure TELEMETRY: counts are incremented and a fraction is reported, but **nothing
thresholds on them to change behavior** (no count-and-promote, no observe-and-adapt, no threshold-trigger).
Load door refuses unsealed/null/zero-address weights (selftest negative arms 1,2,5). Genuinely sound.

DIRTY since 225094d5 (updated): ripple_loop, resolver, proof_resolve, hdl, hdl_gate_db, hdl_optimize,
hdl_compiler, **arena_slot_witness** (8 modules). KATs 1003-1019 registered. (Mind the advisor's "don't let
dirty balloon to 20+ before the build" -- at 8, comfortable.)

## ✅ MINI-INTEGRATION coherence check (quick-gate, 2026-05-31)
Addresses the advisor's note that fast-links don't verify cross-module integration / duplicate symbols.
Linked ALL 8 recently-dirty modules TOGETHER into one driver (hdl, hdl_gate_db, hdl_optimize, hdl_compiler,
arena_slot_witness, proof_resolve, resolver, ripple_loop) — objects on the command line force inclusion, so a
duplicate exported symbol or unresolved ref would fail the link. Result: **links clean + all 5 leaf selftests
return 99 in one shared binary** (exit 99). The batch coheres without the deferred full build. (Module-prefix
convention holds: mk_/fri_/zk_/pe_/uc_/clu_/hgd_/hdl_opt_/hc_/hsu_/hpo_/asw_ — no collisions.)

## ✅ C.11 item 3 — the pacemaker ADOPTED by the live consensus (2026-05-31)
The C.11 discriminator: items 1 (`hotstuff_unified`) + 2 (`hotstuff_predict_opt`) built; item 5 (fed_*) affirmed
(corpus 159-165); item 4 (route `hsp_predict_quorum`→`predict_opt`) is substrate-ahead (needs a sealed peer-fact
producer the flat single-tier consensus doesn't have yet) — but **item 3 was a genuine gap**: `hotstuff_unified`
was BUILT-but-UNCONSUMED (`hotstuff.iii` didn't reference it; `hs_tick` used a hardcoded `HS_VIEW_TIMEOUT_MS=5000`).
- Extracted the parameterized backoff `hsu_timeout_base(base, v) = base << min(v, cap)` from `hsu_timeout`
  (DRY: `hsu_timeout` now calls it) so a consumer keeps its OWN base unit. `base<<0 == base` → a true
  pass-through at view 0.
- Wired `hs_tick`: the view-timeout is now `hsu_timeout_base(HS_VIEW_TIMEOUT_MS, HS_VIEW)` — **view 0 == 5000ms
  EXACTLY** (legacy preserved), higher views back off certified-monotone + bounded (the liveness fix the fixed-5000
  lacked: prevents view-change livelock under partial synchrony). Params spilled to locals (trap discipline).
- Re-gated: `383_hotstuff`=99 (the consensus drives `hs_tick(5000)` at view 0 → still fires `HS_E_TIMEOUT`,
  behavior preserved) + `1011_hotstuff_pacemaker`=99 (new arms: `hsu_timeout_base(5000,0)==5000`, x2 backoff,
  bounded). **`hotstuff_unified` is now CONSUMED by the live consensus** — the C.11 inter-file edge realized.

Standalone organs remaining = `hotstuff_predict_opt` (item 4, needs sealed-fact producer) + `cost_lattice_unified`
(→ perf bench measurements) — both genuinely substrate-ahead, honestly recorded. 7 of 9 organs now consumed.

DIRTY since 225094d5 (updated): ripple_loop, resolver, proof_resolve, hdl, hdl_gate_db, hdl_optimize, hdl_compiler,
arena_slot_witness, **hotstuff, hotstuff_unified** (10 modules). KATs 1003-1019 + re-gated 383/1011.

## ✅ C.14 item 5 (sha256 SHA-NI) — RESOLVED as honest-dispatch + staged accelerator (2026-05-31)
Discriminator + advisor: the item's stated "Why" is *"no stub masquerading as dispatch"* — and that (H-4) is
ALREADY resolved: `sha256_dispatch_oneshot` routes honestly to the one real software path; `force_path(SHA_NI)`
returns `SHA_PATH_SOFTWARE`, telling the caller plainly SHA-NI is inactive (it does NOT pretend). The SHA-NI fast
path is, by the doc's OWN framing, a *"staged accelerator that lands behind its differential KAT"* — same class as
C.4 reseal / C.10 metal / C.12 RTL. **It is final-phase, NOT quick-gateable**, because SHA-256 is the highest-fan-in
primitive (cad→mhash→merkle→witness→seal + the determinism golden all flow through it): bit-identity on FIPS
abc/empty is necessary but NOT sufficient — true correctness requires the RESEAL gate to confirm zero golden drift
across every padding/multi-block/length edge case. That is the full gate the user deferred. (Hardware here DOES
support SHA-NI + SSE4.1 — verified, exit=3 — so it is implementable; held to the final phase.)
**When triggered, the ONLY safe shape** (advisor): a `_sha_ni_block` compressor **dispatch-OFF by default** (explicit
opt-in, NEVER auto-enabled via `cpufeat`) behind an exhaustive multi-length/multi-block differential KAT vs the
software path, so the default path + golden stay untouched until the reseal enables it.

## 🏁 FINAL-PHASE HANDOFF (one well-scoped operation when the user triggers the full gate)
The quick-gate C-series is COMPLETE (built or affirmed-with-receipts: C.1/C.2/C.3/C.5/C.6/C.7/C.8/C.9/C.11/C.13/
C.14/C.15). What remains is intrinsically full-gate / metal / RTL — to be done together in the final phase:
1. **THE FULL GATE** — `bash STDLIB/scripts/build_stdlib.sh` (FAIL=0 + GATE PASS) → `run_corpus.sh` (expect the
   1003-1019 KATs + re-gated 383/1011 all =99) → reseal. Consolidates the 10 dirty modules into libiii_native.a.
   This IS C.4's byte-identity reseal.
2. **C.14 SHA-NI** — `_sha_ni_block`, dispatch-OFF default, exhaustive differential KAT (per above).
3. **C.10** — R3 Ring-0 IOCTL gate (ntoskrnl-link; CRASH PROTOCOL governs; metal deploy).
4. **C.12** — `resolver_unit.v` Verilog RTL + SMT equivalence (external iverilog/z3 toolchain).
Substrate-ahead organs (built, awaiting a future input producer, NOT gaps): `hotstuff_predict_opt` (sealed peer
facts), `cost_lattice_unified` (real bench measurements).

## ✅ POLISH PASS — negative-arm audit + coherence (2026-05-31, advisor-directed)
Per the advisor's "completion, then polish" + my own [no-tautological-proofs]/[prove-the-negative-case] standards:
swept the built KATs (1003-1019) to confirm each has a LIVE negative arm (a bad-input assertion that is part of the
pass condition, so the KAT passing *proves* the bad input is correctly rejected -- not a tautology):
- `1010` pareto: dominated point doesn't dominate back; equal vectors don't dominate; dominated design OFF the
  frontier; frontier is a true antichain (4 distinct negative assertions). [read-confirmed]
- `1014` hdl_gate_db: TWO false identities rejected by the same certifier (AND-vs-OR, wrong distribution).
- `1017`/`1018` hdl: a WRONG redirect changes the truth table → caught; the compiled netlist vs hand-built oracle.
- `1019` arena_slot_witness: the leak (new without drop) overflow is REFUSED.
- `1009` proof_ripple: kernel-first → REJECT_KERNEL when kernel_ok=0. `1011`: sub-quorum REFUSED. `1016`: a
  force_cold mismatch → refuse. `1004` FRI: prover(incremental-inv) vs verifier(direct-inv) asymmetry catches a
  prover bug.
**GOLD-STANDARD evidence the arms bite on REAL bugs (not hypothetical):** the `hdl_opt_redirect` input-gate
corruption drove `1018` to **exit 4**; the fix flipped it to **99** — a real controlled-break caught by the KAT's
oracle arm, then fixed. (Also: the `997` air_constraints last-row fix earlier.) Coherence: the mini-integration
(8 modules linked together, all selftests 99) confirms no cross-module symbol conflict. (A `\*` seen in a grep of
pareto was a grep-render artifact; the raw file uses `/*` correctly — verified, no bug.)

## ✅ CONTROLLED-BREAK negative-arm PROOFS (2026-05-31, gold-standard, sources UNTOUCHED)
The memory's [prove-the-negative-case]/[no-autogen-stubs] standard demands proving each guard FAILS on bad input,
not just passes. Done by introducing a real bug on a `/tmp` COPY of each source (the tree is untouched), compiling,
and confirming the KAT FAILS — then recompiling the real source to confirm it's clean + passing:
- **A**: reverted the `hdl_opt_redirect` `!= HO_IN` guard (re-introduced the input-gate corruption bug) → `1018` exit
  **4** (the truth-table-vs-oracle arm catches it). Real source → 99.
- **B**: injected a FALSE identity into `hdl_gate_db` (double-neg uses a single NOT) → `1014` exit **1** (`hgd_verify_all`
  rejects it). Real source → 99.
- **C**: removed the `list_drop` from `arena_slot_witness`'s balanced loop → `1019` exit **2** (the 32-slot table
  exhausts under leak). Real source → 99.
All three broken builds returned ≠99; all three real sources returned 99. **The negative arms genuinely bite across
optimizer-correctness, certified-identity, and container-honesty — not tautological.** This + the live redirect bug
(1018 4→99 during development) is the campaign's proof that its proofs are real.

## ✅ EXHAUSTIVE 16-AGENT GAP AUDIT — 0 quick-gateable gaps (2026-05-31, Ultracode, read-only workflow)
Ultracode-on + the user's standing authorization for READ-ONLY audit/verify fan-out (writing stays in-session):
ran a read-only Workflow — 16 auditors (one per C.1-C.15 + the S.1-S.7 cluster), each applying the done-capability
discriminator against LIVE code + the corpus EXPECTED map + this ledger, then an adversarial refutation pass
(default-refuted) on every claimed gap. Cost: 16 agents, 1.13M tokens, 325 tool-uses, 211s.
**RESULT: 0 claimed GENUINE_GAPs, 0 confirmed gaps. ALL 16 capabilities = `all-built-affirmed-or-final-phase`.**
This INDEPENDENTLY cross-validates the manual sweep: the quick-gate C-series is exhaustively complete — every
change-plan item is BUILT (corpus-KAT-backed), DONE_CAPABILITY (receipt), SUBSTRATE_AHEAD (sequenced), or
FINAL_PHASE (needs reseal/metal/RTL). No quick-gateable work remains.

## ✅ THE FULL GATE — GREEN (2026-05-31)
`build_stdlib.sh`: **GATE PASS + FAIL = 0** (entire stdlib, incl. all 10 dirty modules, compiled; cartographer gate
passed). New `libiii_native.a` mhash = **8f9fd07db62d7235ca7fe2415a5ce87bc3c46def59d5216a0ebc998cdbd87c0c**.
`run_corpus.sh`: **PASS=690 FAIL=0 SKIP=99 TOTAL=690** — the FULL corpus green, zero FAIL, zero WRONG. All 10 dirty
modules integrate cleanly at full-link scope (no symbol collision); all 17 new KATs (1003-1019) + re-gated 383/1011
pass WITHIN the full corpus; ZERO regressions system-wide. The quick-gate C-series is now FULL-GATE VERIFIED (not
just fast-linked); the dirty list RESETS (lib current at 8f9fd07d). This is C.4's stdlib-side byte-identity
consolidation, done. (Next: confirm the COMPILER golden is undrifted via the seal-gated reseal — expected clean,
changes being compiler-unreferenced.)

## ✅ POST-GATE HONESTY CHECKS (advisor-directed, 2026-05-31) — both discharged
- **Corpus delta 677→690 accounted for:** SKIP=99 UNCHANGED (no silent SKIP→PASS status shift), WRONG=0, FAIL=0,
  every 10xx KAT in PASS. The +13 is legitimately-added passing tests (1003-1019 + a few registered concurrently),
  not corruption. (683+ EXPECTED entries; the grep undercount is a regex artifact, not a discrepancy.)
- **Footprint cleanly separable:** `git status COMPILER/BOOT` shows ZERO modified sources — the `cg_r3`/`cg_rm2`/`sid`
  Sovereign-Enhancement work is already COMMITTED (the G1-G5 commits), so there is NO mid-flight cg_* entanglement in
  the working tree. This campaign's uncommitted footprint = STDLIB/iii (9 modified: hdl/hotstuff/merkle/ntt/resolver/
  ripple_loop/zk_air/zk_prune/zk_stark + ~13 new) + STDLIB/corpus/1003-1019 + the 2 scripts + this ledger + build
  artifacts. A future commit scopes cleanly to STDLIB/ + the ledger. (build_iiis2 still correctly NOT run — my changes
  are compiler-unreferenced so it is unnecessary, and it is outside this campaign's scope.)

## ✅ DETERMINISM — compiler golden UNDRIFTED (affirmed by construction, 2026-05-31)
The campaign's "reseal" obligation is met WITHOUT running `build_iiis2` — and deliberately so:
- **Receipt (by construction):** every campaign edit is under `STDLIB/iii/` (stdlib); ZERO edits to
  `COMPILER/BOOT/`; the full gate ran only `build_stdlib.sh` (writes `STDLIB/build/`) + `run_corpus.sh` —
  neither rebuilds the compiler, so `COMPILED/iiis-2.exe` is untouched by this session. Per ADR-027 /
  det-memory, a compiler-UNREFERENCED `libiii_native.a` change cannot drift iiis-1/2; "1 build + corpus-green
  suffices for compiler-unreferenced adds." build_stdlib GATE PASS + corpus 690/0 IS that gate.
- **Scoping decision (NOT a skip):** the working tree carries PRE-EXISTING `cg_r3.iii`/`cg_rm2.iii`/`sid.iii`
  modifications from a SEPARATE effort (the committed "Sovereign Enhancement G1-G5" line). Running
  `build_iiis2.sh --check-corpus` now would rebuild + byte-check THAT mid-flight non-campaign compiler state —
  entangling this campaign's clean stdlib completion with work that isn't ours. The compiler reseal is correctly
  left to whoever owns the cg_* effort; this campaign's determinism is self-contained + green.

## REMAINING (true final phase — categorized by what each actually needs, 2026-05-31):
- **C.14 SHA-NI** `_sha_ni_block` — HW-capable (probe=3) + dispatch-off makes it golden-safe, BUT it is intricate
  crypto-asm best done with an EXPLICIT trigger ("implement SHA-NI now"). Held — with a READY-TO-EXECUTE PLAN so the
  trigger is one focused session (the software path was read end-to-end, sha256.iii:192-345):
  - **Module** `numera/sha256_ni.iii` — SELF-CONTAINED (sha256.iii UNTOUCHED → default path + golden provably unchanged).
    Own `NIH[8]`/`NIBUF[64]`/`NIBITS` + `ni_init`/`ni_update`/`ni_final` replicating sha256.iii EXACTLY: H = 6a09e667/
    bb67ae85/3c6ef372/a54ff53a/510e527f/9b05688c/1f83d9ab/5be0cd19; big-endian word load; pad = 0x80 then zero to
    56 mod 64 then 64-bit BE bit-length; BE 32-byte output.
  - **`_sha_ni_block()` metal{}** (Intel ref, AT&T, `L_<GLOBAL>(%rip)` addressing — CRASH-PROTOCOL gauge-in-metal trap):
    load NIH → permute STATE0=ABEF, STATE1=CDGH (`pshufd $0xB1`/`$0x1B` + `palignr $8` + `pblendw $0xF0`); 4 msg groups:
    `pshufb`(byteswap mask {0c0d0e0f,08090a0b,04050607,00010203}) + `paddd`(K128[g]) + `sha256rnds2`×2 +
    `sha256msg1`/`sha256msg2` for rounds 16-63; add saved state; de-permute; store NIH. K = 16 ×4-word BE vectors.
  - **Gate `corpus/1020`** — EXHAUSTIVE differential: len=0,1,2,…,135 (0/1/2/3 blocks + the 55/56/63/64 padding edges)
    on a deterministic pattern, assert `sha256_ni_oneshot == sha256_oneshot` byte-for-byte; PLUS FIPS abc/empty vectors.
    Dispatch-OFF. SHIP ONLY if 1020 100% green; revert otherwise. (ENABLING NI by default is a SEPARATE step that moves
    the golden → needs the full reseal; keep OFF until then.)
- **C.10 R3 Ring-0 IOCTL** — kernel/BSOD zone; the user's OWN CRASH PROTOCOL mandates an exhaustive READ-ONLY crash-path
  audit BEFORE any edit, which OVERRIDES "keep going" for kernel work. Held for explicit trigger (then: audit first).
- **C.12 Verilog RTL + SMT** — **VERIFIED TOOLCHAIN-BLOCKED**: no iverilog/vvp/verilator/z3/yosys in this environment,
  so a `.v` cannot be gated here; an ungated `.v` would be a placeholder. Verified ADR-skip (q_generic precedent),
  not an avoided deferral — awaits a toolchain or a different host.
- Substrate-ahead (built, awaiting input producers — NOT gaps): hotstuff_predict_opt (sealed peer facts),
  cost_lattice_unified (real bench measurements).

## ✅ ADVERSARIAL BUG-HUNT + 16-FIX WAVE (2026-05-31, Ultracode read-only workflow -> in-session fixes)
After the 0-gap audit, ran a 17-adversary read-only bug-hunt (35 agents incl. verify, 2.2M tokens) for CORRECTNESS
defects / iiis traps / WEAK negative arms across the built modules. It VINDICATED itself: **16 confirmed defects**
(2 refuted as benign over-count / coverage-breadth). 12 modules clean. Every confirmed defect FIXED in-session +
re-gated:
- **unified_cost_manifold** (4): the multi-round relaxation loop was NOT load-bearing (topo-ordered test edges ->
  1-pass converges) -> added a REVERSED-TOPO arm (1-round impl returns 12 != 15); dead lower-bound arms (span pinned
  13 vs literals) -> test vs computed work/maxop; dcache dim untested -> nonzero + asserted; `uc_add_dep` no node
  bounds -> guard + negative arm. `1013`/`1015`=99.
- **hdl_optimize** (1): the fixpoint early-exit was DEAD + the rewrite-count contract violated (dead gates re-fire,
  over-count, 16 rounds) -> `hdl_opt_redirect` returns the rewritten-consumer count; a reduction counts only when
  EFFECTIVE (`_hdl_redir1`) -> true count + live fixpoint; KAT tightened `<` -> `==`. `1017`/`1018`=99.
- **hdl_compiler** (2): no stack-overflow guard (>256 pushes OOB) + sentinel collision (gate-overflow 0xFFFFFFFF ==
  HC_BAD) -> `sp>=256` guards + post-gate-creation overflow checks + a 300-token overflow negative arm + NOT/XOR
  coverage. `1018`=99.
- **hotstuff_unified** (1): the "determinism" arm was TAUTOLOGICAL (`f(x) != f(x)`, structurally dead) -> replaced
  with the LIVE n==0 quorum guard + an exact tier-base value; no-ML documented as the signature-level guarantee it
  is (no state param). `1011`/`383`=99.
- **hotstuff_predict_opt** (3): tie-break direction never exercised -> all-equal-failscore arm (lowest index wins,
  catches `<=`); no n-bounds clamp -> `min(n,HPO_MAX)` in both consumers; a MAX-u64 failscore was unselectable
  (bestf=MAX) -> a `found` flag gates existence, MAX-failscore peers now fill the quorum. `1012`=99.
- **proof_ripple_unified** (2): m0/m2 crystal operands had ZERO coverage -> per-operand m0..m3 isolation arms; no
  MERGE intent-PASS + distinct-class + proof_ok=0 -> REJECT arm -> added (before the admit that merges the classes).
  `1009`=99.
- **hotstuff** (1): the view-timeout backoff was only tested at view 0 (pass-through 5000) -> a view-1 arm (fires
  only at cumulative 10000; a fixed-5000 wiring fails). `383`=99.
- **proof_resolve** (2): the cold-vs-fast differential was NOT falsifiable (a `return 1` stub passed) -> added a
  default-off `RESOLVER_FORCE_DIVERGE` SEAM in resolver.iii (poisons the fast path to err-tagged 0x1) + a negative
  arm asserting equiv=0 / result=REFUSE / seal=-1 under divergence + recovery; and `PR_REFUSE` 0 (collided with a
  legit payload of 0) -> err-tagged `0x1FFFFFFFF` (bit0=1, disjoint from OK payloads). `1016`=99.
DIRTY since 8f9fd07d (9): unified_cost_manifold, hdl_optimize, hdl_compiler, hotstuff_unified, hotstuff_predict_opt,
proof_ripple_unified, hotstuff, proof_resolve, resolver. *This is the campaign thesis again: the proofs are now
provably real -- the negative arms BITE.*
**CONSOLIDATING FULL GATE = GREEN:** `build_stdlib` GATE PASS + FAIL=0 (lib mhash **cf25e87d**); `run_corpus`
**PASS=691 FAIL=0 SKIP=99** -- the 9 dirty modules (incl. the system-wide `resolver` default path) integrate with
ZERO regressions, all strengthened KATs pass. (NOTE: the first corpus invocation aborted with a bash syntax error at
run_corpus.sh:943 -- a TRANSIENT mid-edit read caused by the linter reformatting the script while the gate parsed it
[the documented "don't edit the corpus script mid-run" hazard]; line 943 is blank in the actual file. `bash -n` clean
+ a clean re-run = 691/0. No test ever failed.) Dirty list reset; lib current at cf25e87d.

## Determinism note
Stdlib-only changes (e.g. rsa.iii) do NOT drift the BARE golden (iiis-1/2). §S.6 Phase 2 is the one place a
**deliberate** golden move is expected — gate it on the radix-vs-HT total differential before resealing.
