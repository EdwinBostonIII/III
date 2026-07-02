# III Structural Audit — Traceability Matrix (Plan, Inventory)
> **STATUS: HISTORICAL RECORD** — an executed campaign plan/ledger, kept immutable as evidence (reunification W6).

> Complete map of all **79 findings** (74 axis findings + 5 synthesis claims) → cited source ids →
> primary live target file(s) → build wave (`-PLAN-00-DOCTRINE.md` §3) → seal class (§2) →
> deferral flag (§4). The **Verdict** column is filled from `III-STRUCTURAL-AUDIT-VERIFICATION.md`
> once the read-only verification workflow (`wf_17e5d483-1f5`) completes; everything else here is
> fixed at plan time. Target files and any line numbers are advisory — re-`Grep` at execution time
> (all audit line counts drifted, see doctrine §0).

**Legend — Seal class:** `STDLIB` = build_stdlib+run_corpus · `BOOT` = build_iiis2 reseal ·
`FORGE` = full content-address closure recompute · `FROZEN` = ADR refreeze · `GOLD` = the seal
itself, never edited. **Wave:** 0 primitives · 1 crypto-shadow · 2 trusted-base · 3 consumers ·
4 gates · 5 forge/frozen passes · 6 seal-gated compiler.

---

## §1 Combination (consolidation)

| ID | Cited source | Primary target file(s) | Wave | Seal | Defer | Verdict |
|---|---|---|---|---|---|---|
| COMBINE-1 | X1, E-MLK-1, E-MLD-1, F-ST-1, D-KARA-3, D-BI-2, F-CORE-5, D-MOD-2 | new `numera/ntt.iii`; mlkem/mldsa/zk_stark, bigint_karatsuba | 0 | STDLIB | — | _from ledger_ |
| COMBINE-2 | X2, F-CORE-2, D-MLC-1 | `numera/murmur3.iii`, `numera/egraph.iii`, math_library_curation | 0 | STDLIB | — | _from ledger_ |
| COMBINE-3 | X3, C-TC-3, A-RM-2, A-RL-3, F-CG-4, J-UNIFY-2, J-LRU-1, G-SEMA-1, G-AST-QPA | new shared index (exemplar `COMPILER/BOOT/ast.iii`); 9 consumers | 0 | STDLIB (+BOOT for sema consumer →W6) | — | _from ledger_ |
| COMBINE-4 | X5, X13, MONT-1, MONT-2, D-FLD-1, D-MOD-1, E-X-1, E-MLK-2, E-MLD-2 | `numera/modular_mont.iii`, field, bigint_div, modular, bigint_mod | 0 | STDLIB | — | _from ledger_ |
| COMBINE-5 | X11, F-CORE-3, A-PQ-1 | `omnia/pq.iii`, `numera/egraph.iii` | 0 | STDLIB | — | _from ledger_ |
| COMBINE-6 | X21, F-CORE-3 | `numera/tiebreak.iii` (authority) ← egraph, ripple_*, rs_argmax | 0 | STDLIB | — | _from ledger_ |
| COMBINE-7 | X6, X7, X18, X19, X22, X23, X24 (inferred) | new boundary-helper module ← http_server/client, list, pq, tp_*, many @export | 0 | STDLIB | — | _from ledger_ |
| COMBINE-8 | D-CHK-2 | `numera/checked.iii`, `omnia/option.iii` | 3 | STDLIB | — | _from ledger_ |
| COMBINE-9 | E-X-1, E-X-3 | `numera/x25519.iii` ← `numera/fe25519.iii` | 3 | STDLIB | — | _from ledger_ |
| COMBINE-10 | D-MUR-1 | `numera/murmur3.iii` ← endian helper | 3 | STDLIB | — | _from ledger_ |
| COMBINE-11 | D-SA-1 | `numera/sat_arith.iii` ← `numera/scalar.iii` | 3 | STDLIB | — | _from ledger_ |
| COMBINE-12 | II-ST-1 | `numera/safety_type.iii` header → `numera/typecheck.iii` | 3 | STDLIB | — | _from ledger_ |
| COMBINE-13 | X25, II-XCF-1 (inferred) | `xii_curated_*`, `xii_emit_gen`, numera crypto set | 1 | STDLIB/BOOT | — | _from ledger_ |

## §2 Separation (splitting)

| ID | Cited source | Primary target file(s) | Wave | Seal | Defer | Verdict |
|---|---|---|---|---|---|---|
| SEPARATE-1 | F-CORE-1/2/3 | `numera/egraph.iii` → extract integrity (seal+Reed-Solomon) | 2/3 | STDLIB | — | _from ledger_ |
| SEPARATE-2 | II-TC-1, II-CCL-1/2/3, II-TC-2 | `numera/typecheck.iii`, `ccl.iii`, `combinator.iii` | 2 | STDLIB | — | _from ledger_ |
| SEPARATE-3 | F-CORE-4 (inferred) | `numera/sov_isa.iii`, `microarch_model.iii` | 3 | STDLIB | — | _from ledger_ |
| SEPARATE-4 | MATCH-SLOT-1, PCC-1, C-SMT-1 (inferred, low-conf) | `COMPILER/BOOT/cg_r3.iii`, smt, typecheck | 6 | BOOT | — | _from ledger_ |
| SEPARATE-5 | X25 (inferred) | `xii_emit_gen.iii` policy vs `xii_curated_*` bodies | 1 | STDLIB | — | _from ledger_ |

## §3 Ripple (interactions)

| ID | Cited source | Primary target file(s) | Wave | Seal | Defer | Verdict |
|---|---|---|---|---|---|---|
| RIPPLE-1 | II-CCL-1/2/3, II-TC-2 | `numera/ccl.iii`+`typecheck.iii` → induct, safety_type, integrity, sov_pipeline | 2 | STDLIB | — | _from ledger_ |
| RIPPLE-2 | D-KARA-1, D-KARA-3 | `numera/bigint_karatsuba.iii`, bigint | 3 | STDLIB | — | _from ledger_ |
| RIPPLE-3 | D-SP-1, D-FC-1, FC-COLLIDE-1, D-CC-1 | `numera/crystal.iii` ← scalar_provenance, field_crystal, checked_crystal, q128_f64 | 3 | STDLIB | — | _from ledger_ |
| RIPPLE-4 | A-RX-1/2, A-RL-1, A-RC-1 | `numera/congruence.iii` (+cgr_contains) ← forcefield/ripple_* | 3 | STDLIB | — | _from ledger_ |
| RIPPLE-5 | X23, X4, A-CG-1, A-OI-2, A-RP-1 | `numera/cad.iii` ← commit_gate, reach_oracle, optinvoke, ripple | 3 | STDLIB | — | _from ledger_ |
| RIPPLE-6 | X24, II-HTTPSERVER-3, II-BASE32-1, II-FORMAT-1, II-INET-1 | builder ← http_server/client, base32, format, inet, tp_* | 3 | STDLIB | — | _from ledger_ |
| RIPPLE-7 | E-X-3 (≡COMBINE-9) | `numera/fe25519.iii` ← `x25519.iii` | 3 | STDLIB | — | _from ledger_ |
| RIPPLE-8 | D-BI-1, X17 | `numera/cpufeat.iii` ← bigint, sha256, sha512, chacha20, mlkem | 3 | STDLIB | — | _from ledger_ |
| RIPPLE-9 | J-RESULT-1, J-ITER-4, X20 | `@specialize` codegen in `COMPILER/BOOT/*` ← result, iter | 6 | BOOT | — | _from ledger_ |
| RIPPLE-10 | (seal discipline) | `COMPILER/BOOT/*.iii`, build_iiis2 scripts | 6 | BOOT | — | _from ledger_ |
| RIPPLE-11 | (forge closure) | `katabasis/census.iii`, ring_lattice, seal_resolver | 5 | FORGE/FROZEN | **YES** | _from ledger_ |
| RIPPLE-12 | X22, II-TP-MD-1, II-TP-ASTBIN-1 | transform_patterns `tp_table_call` ← tp_* | 3 | STDLIB | — | _from ledger_ |
| RIPPLE-13 | F-RFLC-2, F-RFLG-1 | reflection_constrained, reflection_governance | 4 | STDLIB | — | _from ledger_ |
| RIPPLE-14 | II-CHARTERTERMINAL-1, X26 | `sanctus/charter_terminal.iii` | 4 | STDLIB | — | _from ledger_ |

## §4 Enhancement

| ID | Cited source | Primary target file(s) | Wave | Seal | Defer | Verdict |
|---|---|---|---|---|---|---|
| ENHANCE-1 | F-CORE-1, X8 | `numera/egraph.iii` (incremental rebuild) | 3 | STDLIB | — | _from ledger_ |
| ENHANCE-2 | D-KARA-3 (≡COMBINE-1) | `numera/ntt.iii`, bigint_karatsuba | 0 | STDLIB | — | _from ledger_ |
| ENHANCE-3 | F-CORE-3 (≡COMBINE-5) | `numera/egraph.iii`, `omnia/pq.iii` | 3 | STDLIB | — | _from ledger_ |
| ENHANCE-4 | F-CORE-4 (≡SEPARATE-3) | `numera/sov_isa.iii`, microarch_model | 3 | STDLIB | — | _from ledger_ |
| ENHANCE-5 | D-DIV-1 | `numera/bigint_div.iii` (Knuth Alg D) | 3 | STDLIB | — | _from ledger_ |
| ENHANCE-6 | E-X-1 (≡COMBINE-9) | `numera/x25519.iii`/`fe25519.iii` | 3 | STDLIB | — | _from ledger_ |
| ENHANCE-7 | E2-KC-1 | Keccak streaming absorb site (block-oriented) | 3 | STDLIB | — | _from ledger_ |
| ENHANCE-8 | X16, E-ED-1, E-EC-1 | `numera/crypt_ed25519.iii`, `ecdsa_p256.iii` | 3 | STDLIB | — | _from ledger_ |
| ENHANCE-9 | E2-AES-2, D-CRC-1, E2-512-1, D-FN-1, D-FN384-1, E-FE-2/3, E-MLK-2, E-MLD-2/3 | aes, crc32, sha512, fn256/384, fe25519, mlkem, mldsa | 3 | STDLIB | — | _from ledger_ |
| ENHANCE-10 | A-COSTLAT-1, A-CC-1, A-MA-1, A-PL-1, A-ML-1, A-PQ-1, D-ML-1, F-UNC-1, F-GB-2, F-CB-1, G-SEMA-1/2 | cost lattice, microarch_model, pleroma, memo lattice, pq, math lib, uncertainty, groebner, combinator, sema | 3 (sema→6) | STDLIB/BOOT | — | _from ledger_ |
| ENHANCE-11 | D-XO-2 | `numera/xoshiro.iii` (jump/long_jump) | 3 | STDLIB | — | _from ledger_ |
| ENHANCE-12 | (bv_ring ceiling) | `numera/bv_ring.iii` (column-stack >6 vars) | 3 | STDLIB | — | _from ledger_ |
| ENHANCE-13 | (latent PCC) | `numera/zk_snark.iii` → `sov_pipeline.iii` | 3 | STDLIB | — | _from ledger_ |
| ENHANCE-14 | X25 (≡COMBINE-13) | `xii_curated_*` from numera crypto | 1 | STDLIB | — | _from ledger_ |
| ENHANCE-15 | II-TRANSFORM-1/2, II-TP-ASM2PE-1 | tp_iii_to_c99/latex, tp_x86_disasm, tp_asm_to_pe, transform/_buffer | 3 | STDLIB | **YES** | _from ledger_ |
| ENHANCE-16 | II-DYNIMP-1/2/3, II-RESINIT-1, II-BASE32-2 | dynamic_impact, resolution_init, base32 | 4 | STDLIB | — | _from ledger_ |
| ENHANCE-17 | X26 | charter_terminal, proof_ripple_resolution, irreducibility_proof, quality_q7, babel_intent, resolver_memo/replay, xii_curate, mandate, pattern_set_federation | 4 | STDLIB | — | _from ledger_ |
| ENHANCE-18 | X4, A-RP-1 | `forcefield/ripple.iii` ← `numera/cad.iii` separator | 3 | STDLIB | — | _from ledger_ |
| ENHANCE-19 | X12, E-X-3, D-FP-1, E2-AES-1 | x25519, fp256, aes | 3 | STDLIB | — | _from ledger_ |
| ENHANCE-20 | X15, E-SLH-2, E-EC-2, E-FE-4 | slhdsa, ecdsa_p256, fe25519 | 3 | STDLIB | — | _from ledger_ |
| ENHANCE-21 | II-CCL (≡SEPARATE-2) | `numera/combinator.iii` cb_conv ↔ ccl | 2 | STDLIB | — | _from ledger_ |
| ENHANCE-22 | X14, E-RSA-1, E-EC-3, E-PQD-2 | rsa keygen, ecdsa, PQ dispatcher | 3 | STDLIB | — | _from ledger_ |
| ENHANCE-23 | MERKLE-2, C-BV-1, C-PC-3, C-NS-1 | merkle, bv_ring, polynomial commitment, nous_search | 3 | STDLIB | — | _from ledger_ |

## §5 Removal

| ID | Cited source | Primary target file(s) | Wave | Seal | Defer | Verdict |
|---|---|---|---|---|---|---|
| CUT-1 | C-TL-2 | `tempora/temporal_logic.iii` (TL_VAL_FILLED 4MB) | 3 | STDLIB | — | _from ledger_ |
| CUT-2 | A-CLS-4 | cost-lattice synth (CLS_DIM_RESERVED, CLS_DESC_BYTES) | 3 | STDLIB | — | _from ledger_ |
| CUT-3 | A-MA-1 | `numera/microarch_model.iii` (ma_in_flight) | 3 | STDLIB | — | _from ledger_ |
| CUT-4 | A-RU-1 | `forcefield/ripple_unify.iii` | 3 | STDLIB | — | _from ledger_ |
| CUT-5 | B-JN-2 | xii_joinability (XJN_NJ) | 3 | STDLIB | — | _from ledger_ |
| CUT-6 | D-FX-4 | `numera/fixed_extra.iii` (FX*_SCALE) | 3 | STDLIB | — | _from ledger_ |
| CUT-7 | D-GAL-2 | `numera/galois.iii` (Massey) | 3 | STDLIB | — | _from ledger_ |
| CUT-8 | X9, D-SC-2, D-CHK-4, D-MUR-2 | scalar, checked, murmur3, fold, either, sha256_dispatch | 3 | STDLIB | — | _from ledger_ |
| CUT-9 | DEAD-D7-1, DEAD-STACK-1 | `COMPILER/BOOT/cg_r3.iii` | 6 | BOOT | — | _from ledger_ |
| CUT-10 | B-JN-1 | fold, nous_value, nous_socket, xii_joinability (dead refs) | 3 | STDLIB | — | _from ledger_ |
| CUT-11 | (cert binds nothing) | nous_completion | 4 | STDLIB | — | _from ledger_ |
| CUT-12 | X25, II-XCF-1, II-XICX-2 | `xii_curated_*` crypto stubs (most urgent) | 1 | STDLIB | — | _from ledger_ |
| CUT-13 | II-XICP-3, H002 | curated bodies (embedded return, float field) | 1 | STDLIB | — | _from ledger_ |
| CUT-14 | (historical) | "append two NOPs" non-fix — note only | 1 | — | — | _from ledger_ |
| CUT-15 | X26 (≡ENHANCE-17) | vacuous gates as removal candidates (quality_q7) | 4 | STDLIB | — | _from ledger_ |
| CUT-16 | (forward-looking) | `xii_emit_gen_produce` | 4 | STDLIB | **YES** | _from ledger_ |
| KEEP-1 | ADR-RES-009 | `katabasis/seal_resolver.iii` coefficient table | 5 | FROZEN | **YES** | _from ledger_ |
| KEEP-2 | (forge closure) | `katabasis/census.iii` + closure | 5 | FORGE | **YES** | _from ledger_ |
| KEEP-3 | (golden seal) | `COMPILED/iiis-2.exe` + mhash + witness | — | GOLD | — (doc only) | _from ledger_ |

## §6 Synthesis (architectural conclusions)

| ID | Claim | Implied cross-cutting task | Verdict |
|---|---|---|---|
| SYNTH-1 | Missing-primitive layer is the largest structural debt | Wave 0 (the organ layer) | _from ledger_ |
| SYNTH-2 | The boundary is where III is least like itself | COMBINE-7 boundary layer (Wave 0) | _from ledger_ |
| SYNTH-3 | Trusted base larger than narrative; only place soundness hides | SEPARATE-2 + ENHANCE-21 (Wave 2) | _from ledger_ |
| SYNTH-4 | Two implementations, the shadow wins → generate from one source | Wave 1 + single-source-of-truth discipline | _from ledger_ |
| SYNTH-5 | Vacuous-gate epidemic is a lifecycle bug; prove-the-negative is the cure | Wave 4 (gates + falsifiers) | _from ledger_ |

---

**Counts:** 13 + 5 + 14 + 23 + 16 + 3 + 5 = **79** rows. Deferral findings to eliminate (§4):
RIPPLE-11, ENHANCE-15, CUT-16, KEEP-1, KEEP-2 → all scheduled (none survive). Pure-duplicate
restatements (verified once, cross-referenced): ENHANCE-2≡COMBINE-1, ENHANCE-3≡COMBINE-5,
ENHANCE-4≡SEPARATE-3, ENHANCE-6≡COMBINE-9, ENHANCE-14≡COMBINE-13, ENHANCE-21≡SEPARATE-2,
RIPPLE-7≡COMBINE-9, CUT-15≡ENHANCE-17.
