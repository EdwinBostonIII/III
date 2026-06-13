# III — The Executable Coverage Ledger (sanctus/corpus_coverage)

2026-06-11. Born from a measured failure: `_numera_audit_findings.txt` (a hand-written
untested-export ledger, 2026-06-03) was **fully stale within 8 days** — every listed gap had
been closed by later waves ("gap #17/#65–#69" campaign + `memo_compactor_coordination`), and
nothing updated the file. Coverage claims kept in prose rot; the ledger must be a computation
the system performs on its own tree, with a gate that fails when the claim drifts.

## The organ

`STDLIB/iii/sanctus/corpus_coverage.iii` — the sibling of `sanctus/onelang` (H13's structural
self-audit), for test coverage. NIH: aether/fs + capability + cad externs only; the code-level
lexer, FNV-1a open-addressed name index, insertion sort, and walker are built from bytes.

- **pass 1 (EXTRACT)** — walk the modules root; lex every `.iii` at CODE LEVEL (nested `/* */`,
  `//`, and string literals skipped); register every exported fn: an identifier whose previous
  code token is `fn` on a non-`extern` line, whose declaration carries `@export` before the
  body `{`.
- **pass 2 (REFERENCE)** — rescan modules + walk the corpus root; every code-level identifier
  token naming a registered export marks it covered — EXCEPT the definition itself. A token
  after `fn` on an `extern` line IS a reference (a consumer's import declaration).
- **policy** (the findings-file methodology, executable): `prespec.iii` excluded from both
  passes (`&fn` dispatch tables are not tests); comment/string mentions never cover;
  `.git/.claude/build/_audit_scratch/_quarantine_wip` skipped; an over-buffer file REFUSES the
  whole certification (never half-scanned).
- **criterion (v1, fixed)** — an export is covered iff any code-level reference exists outside
  its own definition site, including same-module call sites. Tightenings (e.g. requiring
  external/selftest callers) would only raise the census; v1 already has teeth.
- **seal** — census (exports, uncovered, files×2, dups, truncations as 6×u64 LE) + the
  insertion-SORTED uncovered names through one cad stream → order-independent, reproducible,
  census-sensitive (KAT arms 5).
- **report** — `cov_report_write` emits the sorted names via the capability-gated fs organ:
  the machine-written successor of the file that rotted.

## The falsifier (corpus/1391_corpus_coverage.iii = 99)

Hermetic synthetic tree under CWD; arms: extraction exactness (unexported helper + excluded
prespec never register), orphan exactness + sorted order, comment-mention no-cover, string-
literal no-cover, extern-line covers, definition ≠ reference, the ratchet closing 2→1→0 to
COMPLETE, seal reproducibility + census sensitivity, machine report byte-exactness.
**Teeth proven by sabotage**: comments-scanned build exits 16; definitions-self-cover build
exits 16 (both must-not-be-99, both bite at the orphan-count arm).

## The real-tree census (first run, 2026-06-11)

`scripts/cov_gate_driver.iii` run from the repo root over `STDLIB/iii` + `STDLIB/corpus`:
**430 uncovered exports** (report: `_cov_report.txt`, regenerated every gated build), 0.6 s
for the full tree. Sample validated by hand (`cat_morph_eq_u64`, `arena_capacity`,
`cpufeat_has_bmi2`, `async_await` — all genuinely unreferenced outside their definitions;
the entire `async_*` surface is untested).

## The ratchet gate (build_stdlib.sh, final stage)

After a clean module build, the gate compiles + links + runs the driver and compares the
report line-count to `scripts/coverage_pin.txt` (**430**). `uncovered > pin` → **BUILD
FAIL**. The pin only goes DOWN as the census burns; raising it requires explicit, reviewed
justification. A missing report (overflow/truncation/driver failure) also fails — the gate
never passes on silence.

## The burn-down (the standing work this ledger creates)

430 exports are unproven claims. Each is either (a) tested — a falsifier KAT that exercises
it, (b) consumed — wired into the production module that should already be calling it, or
(c) culled — dead API surface removed with a proof nothing needed it. No fourth bucket.
The census ratchet enforces monotone progress; the report names the next target, sorted.

### Burn-down record

| date | tranche | KAT | closed | census | pin |
|------|---------|-----|--------|--------|-----|
| 2026-06-11 | (first census) | — | — | 430 | 430 |
| 2026-06-11 | 1: the async FSM (await/block/cancel/yield_now load-bearing; RR head motion observed) | `1392_async_fsm`=99 | 4 | — | — |
| 2026-06-11 | 2: checked-crystal provenance (5 wrappers; failure-mode codes 0xC101/02/03; site binding; crystal_set_msg/msg_byte) | `1393_checked_crystal_provenance`=99 | 7 | — | — |
| 2026-06-11 | 3: endian byte laws (8 orphans; misaligned offsets; cross-order bswap triangle) | `1394_endian_exact`=99 | 8 | 411 | 411 |
| 2026-06-11 | 4: introspection laws (arena conservation, bigint bookkeeping, builder UTF-8 widths, duration identity, cat_morph_eq_u64, ccat_set_budget live-both-ways) | `1395_introspection_sweep`=99 | 11 | 400 | — |
| 2026-06-11 | 5: call-context provenance (7: id/k_at_entry/caller_pattern/hexad/prov-root-byte/table_used/reset), capability tree (cap_parent chain, cap_drop mortal-child/immortal-root), csv lifecycle | `1396_context_cap_csv`=99 | 10 | 390 | 390 |
| 2026-06-11 | 6: dream-registry read-back (cga_entry_a/b, cga_bv_entry_b; kernel-certified pairs exact, OOB SENT), cpufeat booleans (sse41>=aesni), ct_verdict (GREEN seal nonzero+reproducible), demote ledger (reason bytes exact, seq strictly monotone), dn_count meta law + pow2 refusal, attest_eq constant-time | `1397_registry_probe_verdict`=99 | 10 | 380 | 380 |
| 2026-06-11 | 7: the sybil gate full lifecycle (fed_sybil_admit/count/revoke_by_sovereign/admission_difficulty): live-mined ≥16-bit SHA3 PoW, real ed25519 endorsement, both gates bite in order with zero state, re-admission same-slot tenure bump, endorser-bound revocation | `1398_fed_sybil_gate`=99 | 4 | 376 | 376 |
| 2026-06-11 | 8: founders directives (fa_pfs_deny/witness_inject/revoke_verify: exact byte layouts rebuilt + live-signed, every field sig-bound), erasure roots (es_n/k/root_ptr: deterministic + content-sensitive), closure+resolver (includes_resolver_seal before/after, with_resolver_byte reproducible), bb_diag_* sentinel-replacement, bws_true identity law, constants_value stability, cpe_count determinism, air_get_trace exactness, format_char_ascii width law | `1399_anchor_store_wave`=99 | 16 | 360 | 360 |
| 2026-06-11 | 9: THE GLYPH V3 FORM SYSTEM — all 16 forms (u8/u32/u64/i64/f64/str/bytes/set/map/record/recursive/proof/witness/vec/crystal/enum): round-trip, form-binding, mhash-integrity, null, 16-way form-id INJECTIVITY, every structured unpacker exact (set elements byte-exact, map key/val forms, record fields by slot, recursive mhash bytes, proof/witness fields, enum tag/variant) | `1400_glyph_v3_forms`=99 | 35 | 325 | 325 |
| 2026-06-11 | 10: the `_x` crypto export surface by FIELD LAWS (fn256/gn384 set-get-copy-eq; fp256/fq sqr==mul-self; zkf Mont round-trip + add/sub inverse + a·a⁻¹=1; zkf12 Mont-one identity; zkg1 2G==G+G; zkg2 inf edge cases), deterministic RSA-PSS sign/verify on a FIXED 544-bit vector (sLen=32 needs ≥522 bits — 1079's documented keygen wall; vector discipline like RFC/FIPS), THE VAULT full round-trip (ChaCha20+erasure 2/3+Shamir 2/3, byte-exact open at threshold, distinct Shamir x-coords). API truths pinned: zkf lazy-init only via inv; Fp12 = stride-12 Fp bases (scratch 1500+); setone = Mont one | `1401_field_curve_vault`=99 | 29 | 296 | 296 |
| 2026-06-11 | 11: governance ledger (capacity 256 pinned; propose→read→drop-once; rationale-hash bytes; mandate-7 observation NEVER auto-proposes), h13/h2 charter verdicts (GREEN seals nonzero+reproducible+null-refused), hexad algebra (eq6 reflexive/discriminating, dynamic count deterministic, bitmap sha256 reproducible), hw_offload_blob_used cap law, hip_last_token_count (real resolve tokenizes, deterministic), tv_blen exact + tv_keyshare_ptr 32-stride | `1402_gov_charter_hexad`=99 | 13 | 283 | 283 |
| 2026-06-11 | 12: kchain readmission (Q-1e9 basis-points EXACT: FULL→10000; compose×0.5→5000; readmit→FULL, counter exact, dead refuses), k0 one-way freeze latch, JSON error surface (valid→OK+nodes; malformed→E_PARSE at the EXACT byte position), iter_u8 pos+remaining==len, onelang_n_dirs exact on hermetic tree + gate_cwd totality. **SCANNER REFINEMENT**: `@specialize` generics are TEMPLATES, not ABI surface (zero symbols in the archive — nothing can link them); the scanner now excludes `fn name<T>` from the census (hermetic falsifier arm added to 1391: a generic @export does NOT register). 13 closed + 29 phantom templates removed | `1403_kchain_json_iter`=99 (+1391 re-proven) | 13+29 | 241 | 241 |
| 2026-06-11 | 13: scalar bit laws (wrap mod 2^w at boundaries, min/max/clamp order, popcount/clz/ctz exact patterns, byteswap involution, rotl/rotr inverse pair, zero-extension), result_u64 family (ok-decodes/err-refuses/drop-once), rune ascii boundaries (0x80, alnum/whitespace edges, to_upper idempotent) | `1404_scalar_result_rune`=99 | 23 | 218 | 218 |
| 2026-06-11 | 14: scalar provenance (sp_* silent on non-events, verified crystals 0x5102-05 on events), span_u8 bounds+cap laws (exact refusal codes), str_byte_len identity, XII BASIS ALGEBRA over every legal kind (origin/motion/essence partition, is_fusion_op upward-closure, term accessors are kind-functions) | `1405_provenance_span_basis`=99 | 16 | 202 | 202 |
| 2026-06-11 | 15: XII term arena (used grows exactly, capacity fixed, hexad/mpo set-get round trips, dead refusals, is_null, mhash nonzero+reproducible+term-distinct), xoshiro seeded-stream law (re-seed reproduces; fill==next stream; seeds diverge), zkf_np odd-constant law + set_limb exact | `1406_term_arena_xoshiro`=99 | 12 | 190 | 190 |
| 2026-06-11 | 16: THE XII LATTICE CELL STORE (dense allocation, payload arena advances exactly, per-byte metadata fidelity, dead-index 0-sentinels, lookup round trip + horizon/slot cap refusals, circ fold pinned exactly) | `1407_lattice_cells`=99 | 10 | 180 | 180 |
| 2026-06-11 | 17: the intent table + parent chain (reset/used exact + slot reuse, lower_call/lower_ast_node slots 0-2 + mask 0x7, compose-class hexad agreement, cap round trip, parent chain by intent id, verify refuses foreign/null) | `1408_intent_table`=99 | 7 | 173 | 173 |
| 2026-06-11 | 18: 64-bit scalar laws (wrap mod 2^64, order, popcount/clz/ctz, byteswap involution, rotl/rotr inverse, split/combine bijection) + SAT arena counters live after a real CDCL solve with the EXACT-REPLAY law | `1409_scalar64_sat_counters`=99 | 17 | 156 | 156 |
| 2026-06-11 | 19: semver field spans (pre/build off+len exact), uri parse+drop lifecycle, sha512 streaming update_byte == oneshot differential, transform table exact registered (src,dst) pairs + bad-idx refusal | `1410_semver_uri_sha512_tp`=99 | 11 | 148 | 148 |
| 2026-06-11 | 20: THE CONSTANTLY-RUNNING SOVEREIGN OPTIMIZER observed (monotone+enhancing, convergent fixpoint at the full strength space with no churn, exact tick count, deterministic same-seed fixpoint, non-impairing totals) — the "perfect system enhances itself even while working perfectly" loop proven | `1411_sovereign_optimizer`=99 | 5 | **143** | **143** |

| 2026-06-11 | 21: XII circumstance cube (hexad bit-extract + the full-2^20 feasible enumeration == 363224, **catching a stale "16,128" module comment**) + horizon manifest (count 144, construct productive→term/guard→NULL, reach bitmap len/ptr + 126-productive boundary) | `1412_circ_horizon`=99 | 9 | 137 | 137 |
| 2026-06-11 | 22: transform pack/unpack inverse + pattern_set global identity + buffer src==dst OK, sep-logic sl_pure no-footprint, taint_set_imm trusted-constant flow law, tempaloc type tags, seal_instant_id | `1413_transform_taint_seal`=99 | 10 | 128 | 128 |
| 2026-06-11 | 23: unify_lookup_var (term<<1 / 0x1 free) + export_subst_to_resolver_buf exact flatten, witness_entry_k round trip, ws_chain_root reproducible + append-evident (moves on publish+epoch-close) | `1414_unify_witness_spine`=99 | 4 | **124** | **124** |

| 2026-06-11 | 24: the XII associativity rewrite rules A1-A4 (match/apply R001-4 sound + falsifiable; smart-constructor normalization documented — LHS built via set_child re-pointing; rule_count 44) | `1415_xii_rewrite_rules`=99 | 9 | 115 | 115 |
| 2026-06-11 | 25: the uniform post-quantum c4 surface (ML-KEM-512 encaps/decaps shared-secret agreement; ML-DSA-44 sign/verify + 1-bit tamper rejection; pq_params lazy table pinned) | `1416_pq_dispatch_c4`=99 | 6 | 109 | 109 |
| 2026-06-12 | 26: option-FULL sentinel (256-slot exhaustion law; drop idempotent-on-valid), path_join one-separator law, pq peek-without-pop, regex recompile determinism, q128 rounding crystals (faithful round_dir transcription), pointer provenance split identity | `1417_option_path_pq_prov`=99 | 10 | **99** | **99** |

**Summary through tranche 26**: first census 430 → **99** (KATs 1390–1417), full corpus 957 → **1005 PASS / 0 FAIL** throughout, ratchet never regressed, scanner refined once (generics excluded), one stale module comment caught and binary-pinned (circ feasible 363224 ≠ the comment's 16,128). 331 export claims either proven by a falsifiable KAT or removed as non-surface.

Notable API truths the burn-down has already pinned: `checked_u64_*` returns checked.iii
handles (decode via `checked_u64_unwrap_or`, drop after use — never compare handle ids);
`checked_u64_drop` returns u8 (1=ok); `ccat_init()` resets the ONE category (register objects
AFTER it); `bigint_eq_u64` compares two bigints (u64-coded verdict, not bigint-vs-u64);
the env-root capability is immortal (`cap_drop` → CAP_E_DENIED).

| date | tranche | KAT | closed | census | pin |
|------|---------|-----|--------|--------|-----|
| 2026-06-12 | 27: the fixed-point family + HTTP header spans | `1418_fx_http_request`=99 | 13 | 86 | 86 |
| 2026-06-12 | 28: the XII sealed-table accessor sweep | `1419_xii_tables`=99 | 16 | 70 | 70 |
| 2026-06-12 | 29: NL lexer/parser, ini, inet6 latch, fs_tell MAX-sentinel, frq, forked-walk | `1420_nl_ini_net_walk`=99 | 12 | 58 | 58 |
| 2026-06-12 | 30: jit swap registry (exact addr/size readback, id-0 refusal), mandate constants (m22 bit 0x00200000, process mask 0x001F9CEE), map hard-cap + integrity lifecycle, cap forge split (registry finds the SAME slot; null refused), modctx arena binding, handle rights gate (set→verify admits/refuses by the CAP's rights), obs_mode stability, conjecture term f-boundary at exactly 0x10000 | `1421_jit_mandate_map_forge`=99 | 14 | 44 | 44 |
| 2026-06-12 | 31: ripple field (reset/nodes/edges exact; steepest potential deterministic), resolver self-call counter (+1 exact), memo query floor + deterministic refusal, manifest readers (producer bytes EXACT; chain-head format law E_BAD_IDX on non-manifest), joinability tallies deterministic, termination no-anomaly (first_anomaly_rid==0), provenance delta (distinct mints, IDENTICAL site bytes, cause_seq==step_no), quality lint latch | `1422_field_replay_manifest`=99 | 15 | 29 | 29 |
| 2026-06-12 | 32: THE LDIL BLOCK IR LIVE (new_function/new_block/add_block round-trip, block_parent, emit_const RETURNS THE OUT-VALUE (load-addressable), emit_load appends in order, every accessor refuses dead refs with LDIL_SENT/0), layered seal record ([0..32)=prev/[32..64)=new EXACT; pre-emit + OOB 0x100), nous charter verdict == cad(KECCAK, count_LE4) RECOMPUTED IN-KAT (the exact seal formula), lint corruption hook (set→1, inject→0, restorable), pattern proof-id u64-LE at offset 152 byte-exact + in-bounds, federation capacity 64 | `1423_ldil_seal_charter`=99 | 10 | 19 | 19 |
| 2026-06-12 | 33: VERIFIED SAT-SOLVE end-to-end (56B SatsReq; SAT unit→result 1 + 5-byte model cert independently re-verified; UNSAT pair→result 0 + 16-byte refutation; verify_len == out_cert_len EXACTLY; DENIED without SATS_RIGHT_SOLVE; null/bad-magic refused; tampered cert REJECTED), sandbox cpu quota append-only exact (300→refuse-800-commits-NOTHING→admit-700-to-exact-cap→refuse-1), sandbox_result round-trip + dropped reads 0, tcp connect/listen pure rights-gate refusals (no socket ever exists), ni_witness_sign (pre-init refused; RFC-8032 sig VERIFIES under ni_witness_pub; deterministic; tampered msg AND sig rejected; identity-role sig does NOT verify under witness pub), hc_compile_normalized (function preserved == hand-built OR(x,w) oracle, live gates strictly shrunk, underflow refused), ks_self_measure (SYNTHETIC PE walk → digest == independent cad_oneshot of the window; reproducible; one-byte flip changes it) | `1424_solve_sandbox_sign_measure`=99 | 9 | 10 | 10 |
| 2026-06-12 | 34: **THE MEMBRANE — INVERTED ANCHOR GATE FOUND AND FIXED.** `xii_sml_verify_anchor_signature` + `xii_antidrift_check_anchor_sig` mistyped crypt_ed25519's verifier `-> u32` and treated `rc != 0` as failure: VALID signatures rejected, FORGERIES accepted — never exercised positively (corpus 372 skipped the sig check). Fixed to the founders_anchor convention (`u8`, `!= 1u8`). KAT builds the FIRST fully-valid manifest (real keypair, pubkey at 0x310, detached sig over [0..0x330) at 0x330, golden sha256): xii_sml_launch==0 POSITIVE (impossible pre-fix), forged-sig-re-goldened → 4 (the gate still says no), manifest/cell tampers → 3/6, wrap-bound → 7; xii_atm_tick fires at exactly the 1024th op (intact→0, manifest→1, cell→2, restored→0); xii_antidrift_check_all == 0 with ALL NINE checks green over the REAL signature (tampers pinpoint 1/2/8/9) | `1425_membrane_launch`=99 + sml/antidrift fix | 3 | 7 | 7 |
| 2026-06-12 | 35: **THE FINAL SEVEN — CENSUS ZERO.** ripple_execute_native side table (exact (crystal,mode) readback in order, OOB 0, 1024-cap refuses -1 clobbering nothing, clear resets), proof_ripple_corpus_equiv_site_byte (stable in-range bytes on a verifier-corroborated cert; i≥32/cert-0/unverifiable → 0x100), rva_audit_and_admit ATOMIC (reversible BV pair + AMEND ctx → admitted; non-reversible → -2 admits NOTHING; null cap → -4 after passing audit), pfk_anchor_invariant_xii (matching roots ACCEPT with all system invariants green; mismatch pinpoints sub-check 5), http crystal round-trip (root → module's own hex header → parse → byte-exact readback; headerless response has no crystal; id-0/i≥32 refused) | `1426_dispatch_admit_crystal`=99 | 7 | **0** | **0** |

**THE BURN-DOWN IS COMPLETE — 2026-06-12.** First census 430 (2026-06-11) → **0** in 35
tranches (KATs `1390`–`1426`), every closure an exact falsifiable law (never a smoke call),
full corpus 957 → **1014 PASS / 0 FAIL**, the ratchet never regressed and now pins **0**:
any future `@export` without a referencing corpus KAT FAILS the build. The burn-down's
biggest catch was saved for last: the Sovereign Membrane's Founders-Anchor signature gate
was INVERTED in both organs (xii_sml + xii_antidrift) — valid signatures rejected, forgeries
accepted — found because the coverage criterion demanded the first-ever positive launch.

## Criterion v2 — the gate-outcome census (2026-06-12)

The membrane inversion proved reference-coverage insufficient for SECURITY GATES: both
anchor-sig checkers were referenced, compiled, and aggregated -- and fully inverted.
**v2**: an export whose name carries a gate stem (`verify` / `admit` / `attest` /
`launch` / `validate` / `authorize`) must be seen at CORPUS call sites whose adjacent
comparison pins **>= 2 distinct outcomes** (`op` + literal; `!= 1u8` twice counts ONCE;
a call with no comparison counts ZERO; a module-side comparison is use, not proof).
A gate that can only ever be seen saying one thing -- an always-accept stub, an inverted
polarity -- is UNDER-PROVEN and fails the new ratchet.

Mechanics: `corpus_coverage.iii` pass 3 (corpus root only) walks each gate call's
balanced argument parens (string-aware, nested-call-safe) and folds `op || outcome-token`
into a per-export FNV outcome set; `cov_gate_verdict` / `cov_n_gates` /
`cov_n_underproven` / `cov_underproven_name` / `cov_gate_report_write` expose it; the
seal binds both censuses (v2 layout: 8 u64 census + uncovered + under-proven names).
The driver writes `_cov_gate_report.txt`; build_stdlib compares it against
`scripts/coverage_gate_pin.txt` -- the same down-only ratchet discipline as v1.

Hermetic falsifier: `1427_coverage_gate_outcomes`=99 (proven/same-outcome-twice/naked-call/
module-only discrimination; the NO-ARG EXEMPTION -- a parameterless "verify" is an
observation no input can drive to refuse (h1..h13 charter arms); its falsifier is its
charter's canary-RED, so it stays under v1 reference only; sorted census + byte-checked
report; the nested-paren ratchet; seal binding).  First census: **171 gate-family exports,
105 under-proven** (negative arm proven: pin 104 -> BUILD RC=1).  Among the proven:
ed25519_verify, handle_verify, sats_verify, crystal_verify, xii_sml_launch,
rva_audit_and_admit, proof_ripple_corpus_equiv_verify, pfk_anchor_invariant_xii.

Burn-down: tranche v2-1 (`1428_gate_outcomes_glyph_membrane`=99) gave REAL reject arms to
the 13 glyph validators (one-byte mhash tampers; invalid-UTF-8; duplicate set element),
the membrane verifier quartet (wrong size / manifest tamper / forged sig / cell tamper
over the 1425 fixtures), and ks_attest (anchor flip) -- 18 closed, 105 -> 87.  The arity
refinement then exempted 34 no-arg observations: **53 remain** (pin 53), every one an
input-driven gate with a constructible refusal.

Tranche v2-2 (`1429_gate_outcomes_anchor_rsa`=99): the Founders-Anchor verifier trio
(fa_verify raw-directive tamper; fa_drtm_reset_verify with the 70-byte directive rebuilt
exactly and a wrong reason_code rejected; fa_catalyst_halt_verify with a wrong halt_until
rejected -- all live-signed, the 1399 discipline) and the 8-arg rsa_pss_verify CORE driven
directly (OS2IP replicated via the exported bigint surface over the 1401 baked 544-bit
key; flipped sig byte and wrong sigLen rejected) -- 4 closed, 53 -> **49** (pin 49).

Tranche v2-3 (`1430_gate_outcomes_constants`=99): the three tier-gated constitutional
constant validators over the REAL sealed ledger (lazy-built), every refusal code pinned
EXACTLY -- catalyst: 48>=47 OK / equal OK / 46 REGRESS(4) / AMEND-tier name WRONG_TIER(2)
/ unknown NOT_FOUND(1) / 4-byte value INVALID(5); amend: OK / WRONG_TIER / NOT_FOUND;
r2: OK / WRONG_TIER / NOT_FOUND -- 3 closed, 49 -> **46** (pin 46; corpus 1018/0).

Tranche v2-4 (`1431_gate_outcomes_referee_spine`=99): k0_verify with its FULL verdict
surface (pre-freeze distrust / bisimilar ACCEPT / single-input divergence reject / the
anchor firewall / out-of-range), pattern_set_verify (unsealed-refuse / sealed-accept /
null), instant_verify (TIME-cap-minted seal recomputes; null/dead/DROPPED refused; the
mint refuses a right-less cap), ws_chain_replay_verify (the epoch replay reproduces the
authoritative root; one-byte tamper rejected) -- 4 closed, 46 -> **42** (pin 42; corpus
1019/0).

Tranche v2-5 (`1432_gate_outcomes_proof_carrying`=99): pc_verify_vec (real Merkle
inclusion accepts; tampered leaf / tampered root / out-of-range idx rejected),
pc_verify_poly (the coefficient-Merkle opening through the FULL prover path -- bigint
coeffs -> commit -> the 64-byte open request; tampered evaluation leaf rejected),
pc_verify_proof (the 96-byte certificate binds the payload hash; one flipped payload
byte rejected; null cert refused) -- 3 closed, 42 -> **39** (pin 39; corpus 1020/0).

Tranches v2-6..9 (`1433`-`1436`, one gated cycle, corpus 1024/0, pin **27**):
v2-6 attest_self (ATTEST right both ways), cls_admit (the 14-dim lattice: equal admits,
resource-dim excess refused, K-dim DROP refused -- the no-K-decay law; K-dims are PACKED
BYTES, caught live when a raw u64 writer missed them), rva_admit direct (AMEND cap admits,
null cap E_CAP).  v2-7 mf_verify/mf_verify_by_idx over a real attached manifest fragment
(re-derivation accepts; artifact tamper / wrong length / dead index / unknown id refused).
v2-8 eg_verify_seal (the module's own fault injector flips one node bit -> detected),
es_verify_shard (direct shard tamper via es_shard_ptr caught), merkle_pack_verify_meta
(exact bit-field + mask laws as named-const outcomes -- variable/parenthesized comparisons
are invisible to the outcome capture, a discovered criterion subtlety), hs_verify_qc (a
REAL 4-peer ed25519 quorum; the sub-quorum arm FORGES the attacker-controlled n_sigs
field because the honest composer refuses to build a bad cert; tampered sig + truncation
+ pre-init refused).  v2-9 gs_shift_admit (rotation only when K0-verified AND strictly
cheaper -- both refusal causes), call_context_verify (membership: misaligned/null
refused), babel_wire_verify_crc (HEADER-only CRC by design -- header flip caught),
babel_wire_verify_seal, idoc_validate (structural facet-walk arm isolated from the CRC
arm by re-finalizing after the forge).

Tranches v2-10..12 (`1437`-`1439`, one gated cycle, corpus 1027/0, pin **19**):
v2-10 ch_verify_correspondence (tag-toggle + body equality, all four refusals),
ripple_verify (K-provenance decides: an edges_init'd crystal verifies, a K-less one is
refused), ml_revalidate (the FULL lattice vertical; codes -8/-1/-2/-7 exact; BONUS
invariant: M17 chain verification refuses unregistered chains at ADMISSION too),
mq_admit_predicate_gated (predicate-false -3 / inner-gate -6 / unknown clause -2 /
null -1 / the full end-to-end ADMIT 0).  v2-11 nous_train_admit (the poison wall),
sopt_verify_branch_dead (module-pinned crossval vectors), cg_admit (the conserving
contract admits; the leaking + minting contracts are refused by the exhaustive walk).
v2-12 sov_admit (proof-preserving descent admitted; behaviour change rejected;
proven-equal same-cost admitted).  **xcc_verify EXCLUDED with justification**: its rule
registry is read-only + force-link-registered at process start -- no input can honestly
drive the reject arm in a healthy binary (a boot self-consistency observation whose
parameter is an OUT sink); recorded as a pin-floor candidate, NOT gamed.
PROCESS FIX: a corpus FATAL recurred when a KAT file entered the glob before its
EXPECTED entry (the compose-while-gating race) -- KAT file + EXPECTED entry are now
written atomically, always.

Tranche v2-13 (`1440_gate_outcomes_carrier_library`=99, corpus 1028/0, pin **16**): the
REAL 5-module vertical at the exports -- pt_verify (a single-axiom term constructs,
finalizes, VERIFIES; an arity-violating axiom INVALID -4; unfinalized NOT_FINAL -5;
null/absent -1/-3), tc_verify (the carrier re-attests the verified term; null/absent),
lib_admit (CLAUSE_ABSENT -7 which populates the canonical label -> cons_ratify of that
exact clause -> the SAME carrier ADMITS 0 -> re-admission DUPLICATE -4 -> null -1).

Tranche v2-14 (`1441_gate_outcomes_federation_admit`=99, corpus 1029/0, pin **13**): the
planetary federation admission vertical at the exports.  fed_admit_planetary_gate_status
(pre-admission bits != ALL; after a real sybil admission -- 16-bit PoW mined live +
ed25519 sovereign endorsement, difficulty 16 -> score 16e6 == MIN_SCORE, eclipse quiet --
the bits are exactly FED_ADMIT_BIT_ALL 0x07), fed_admit_eligible (admitted peer eligible 1;
stranger + null refused), fed_admit_with_qc_proof (the hardened path: PLANETARY tier with
a ONE-TIME OFFLINE-MINED 32-bit PoW [nonce 494012290 over 0x42||31x00, baked like the RSA
key] + score>=threshold + a REAL 4-peer HotStuff QC ADMITS 0; each refusal pinned in
checked order: null qc -1, unknown tier -5, wrong nonce -4, over-threshold -6, truncated
qc -7).  3 closed, 16 -> **13**.

Tranche v2-15 (`1442_gate_outcomes_mobius_overrun`=99, corpus 1030/0, pin **11**):
iii_hexad_mobius_admits (the quality floor: q_ppm at/above the buffer floor admits 1,
below refuses 0), corh_admit (the 6-dim cost-overrun door: pre-init NOT_INITED -2; within
declared OK 0; a non-critical dim at 1.5x is a MINOR overrun E_OVERRUN -5; null E_NULL -1).
2 closed, 13 -> **11**.

## Criterion v2 burn-down COMPLETE — gate-outcome census 105 → 0 (2026-06-12)

Tranches v2-16..23 (`1443`-`1450` + the corpus-200 edit) drove the last 11 gates to **zero**:
- v2-16 (`1443`-`1446` + 200): cp_verify_segment/epoch (vacuous-true vs dead-formula-detected),
  bvd_admit (two-tier disposer: x*2==x<<1 admits, x<<1==x*3 Tier-1 vetoes, x-x==0 Tier-2
  declines), sov_pcc_verify_core (kernel translation validation: 0==0 certified, 0!=S0
  rejected), calculus_verify_completeness (a real reject arm added at its existing consumer,
  corpus 200 -- the verdict there flows through a variable so it captured NO outcome; two
  DIRECT-comparison arms fix it), ba_verify_bisimulation (THE HARD ONE: the full branch-merge
  vertical -- construct/propose/independent-re-derive/commit -- replicated through public
  witness/spine/cg/constitution APIs, plus the NOT_BISIMILAR negative).
- v2-17..22 (`1447`-`1449`): bm_verify_block (a real 8-of-12 erasure stripe via bm_write_data;
  live data + parity verify, dead/oob refused), cg_verify_graph_integrity (a kernel-proven
  obsolete pair (3,3) SAFE / (3,4) UNSAFE), symreg_verify (a real identity dataset -> finds
  y=x0, confirms it, rejects y=x0+1).
- v2-23 (`1450`): rj_verify + xcc_verify, each closed with a PRINCIPLED, minimal module hook
  (the eg_test_flip_bit / witness_inject_corruption_for_test precedent, NOT gaming):
  **rj_addr_at** -- a read-only accessor symmetric with rj_resolve, letting a corpus verifier
  reconstruct the ordered address list rj_verify recomputes over (positive + swapped-order
  negative); **xcc_test_inject_fault/clear_fault** -- perturbs the expected golden by one byte
  so xcc_verify's reject arm is drivable (the analogue of flipping an expected digest), off on
  every boot/production path.  xcc was first considered an undrivable pin-floor candidate, then
  closed honestly with the fault hook.

**THE GATE-OUTCOME BURN-DOWN IS COMPLETE.** 171 gate-stem exports, **0 under-proven** (pin 0,
the absolute floor; negative arm proven: pin -1 -> BUILD RC=1).  Every security gate
(verify/admit/attest/launch/validate/authorize) that takes input has been SEEN deciding both
ways at a corpus call site -- the exact property whose absence let the Sovereign Membrane's
anchor gate stay inverted.  The ratchet now permanently fails the build if any new gate-stem
export cannot be seen rejecting.  Two refinements made the criterion sound: the no-arg
exemption (an observation no input can drive to refuse) and direct-comparison capture (a call
whose result flows through a variable captures no outcome).  v1 coverage stayed 0 throughout.

## Criterion v2.1 — broadened to the inversion-class verdict families (2026-06-12)

The membrane lesson generalizes: an inverted `check`/`certify`/`prove` is as fatal as the
membrane's inverted `verify`.  Those families were ungated.  cv_is_gate_name now also flags
`certify` / `prove` / `check` -- but with WORD-BOUNDARY matching (cv_stem_word: the stem must
be followed by `_` or end the token).  Substring matching mis-flagged "provenance" (prove+n),
"underproven" (prove+n -- the coverage organ's OWN accessor!), "checkpoint" (check+p), and the
"checked"-arithmetic family (check+e); the word boundary cleanly excludes all of them.  49 noisy
matches -> 27 genuine verdict gates.  Producers (sign/seal/ratify -- they emit an artifact, no
accept-when-reject failure mode) stay EXCLUDED; only judgment-verb verdict gates are held to the
both-ways rule.  Establishment: pin raised 0 -> 27 (justified: broadened scope = more gates in
scope), build 578/0 (lib e25f2514), corpus 1038/0, both falsifiers (1391, 1427) still green.

## Criterion v2.1 burn-down COMPLETE — verdict-family census 27 → 0 (2026-06-12)

Tranches v2.1-1..3 (`1451`-`1453`, pin 27 -> **20**): k0_drift_check (the K_0 anchor
immutability sentinel: true fingerprint 1, perturbed golden 0), tc_check (the CIC kernel
type checker: refl against the reflexive goal 1, against zero=?succ-zero 0),
bisim_prove_equiv (mul-vs-shift of the same value proven equivalent 1; a genuinely
different pair 0), xii_antidrift_check_manifest + xii_antidrift_check_anchor_sig (the
membrane sub-checks, including THE exact gate that was inverted, both driven over a real
keypair manifest: valid 0, tampered/forged their error codes), tv_check (faithful
translation kinds validate, the diverging kind caught), lbp_one_check (affine loop bound:
fitting family safe 1, overflowing family caught 0).

Tranches v2.1-4..9 (`1454`-`1459` + `1460`-`1461`, pin 20 -> **0**) — the remaining 20
verdict gates, every recipe derived from a read-only 16-agent module fan-out then
implemented + KAT-run in-session:
- `1460` (proof vertical): prf_check_step (genuine LCF step 1, forged premise 0),
  tcom_merkle_prove (3-leaf registry, leaf 0 -> 2-step path; absent idx -> -2),
  unify_occurs_check (X in 42 safe 0; X in f(X) violation 1), cat_check_assoc
  (composable chain holds 1; ed:E->D after g:B->C refused 0).
- `1461` (joinability): xjn_check_root / xjn_check_subterm via SCAN-THEN-ASSERT (the
  live cpe table is scanned for a witness of each verdict, then the verdict is pinned
  with a direct fresh-call comparison -- survives rule-set growth): root JOIN 1 +
  cross-matched NO-WITNESS 2; subterm JOIN 1 + a documented lift-family NONJOIN 0;
  xii_antidrift_check_confluence_empirical (converges 0; the divergence verdict 4
  pinned NEVER to fire on the live algebra -- an always-4 stub or inversion caught).
- `1456` (governance/intent): governance_prove_equivalence (+_with_count) (sandboxed
  proposal mints a nonzero cert + PROVEN; unknown id refused 0), intent_prove (fresh
  table mints; 1024-capacity table refuses), mandate_check_m14_via_match (both arms).
- `1457` (aether guards): ca_check_quiescence (rising k^2 ramp projects past threshold
  -> 1; flat window 0 -- the module's KAT-2/3 driven from the corpus),
  fed_eclipse_anomaly_check (256 differing bits > 200 anomaly 1; identical 0),
  fquar_check_write (RAM safe 1; firmware ROM window refused 0).
- `1458` (LDIL/pareto): ldil_typecheck_function (well-formed 1; unterminated entry
  block 0), ldil_refine_check_function (const-anchored refinement 1; refined orphan 0),
  hdl_opt_pareto_check (2<3 dominates 1; 3==3 refused 0).
- `1454`/`1455` (concurrent-session pair, landed mid-burn via sync; verified green and
  kept): mandate_check_m14_via_match + ldil gates; sov_census_certify (classes 0/8
  certified 1, out-of-range refused 0) + fed_eclipse_anomaly_check (incl. null-pointer
  refusal) + hdl_opt_pareto_check.

**THE v2.1 BURN-DOWN IS COMPLETE.** Census: 0 v1-uncovered / 0 v2-under-proven across
all six families (verify/admit/attest/launch/validate/authorize + check/certify/prove);
pin lowered 20 -> **0** (the absolute floor).  Every judgment-verb verdict gate that
takes input has been SEEN deciding both ways at a DIRECT corpus comparison.

## Criterion v3 — transitive corpus REACHABILITY (the numera-audit lesson, 2026-06-12)

The manual numera cluster audit found 10 exports v1 called covered that no test had ever
executed: v1 counts a reference from ANYWHERE, so an export consumed only by module-side
code the corpus never runs reads as covered while being completely untested.  v3 computes
what that audit checked by hand: **an export is TESTED only if some corpus USE SITE
reaches it through the call graph.**  Implementation (sanctus/corpus_coverage.iii):
pass 3's use-site tokens seed the roots (definitions and extern decls are not use);
pass 4 walks the module tree tracking the ENCLOSING fn by brace depth and records
caller->callee edges in three forms -- a call `name(...)`, a fn-pointer take `&name`,
and III's BARE address-of-fn assignment `let f : u64 = name` (the transform_patterns
dispatch idiom; the first real-tree run mis-flagged 16 tp_* exports until this form was
captured -- callees resolve to the unique export surface first, else intern as
file-local nodes); a breadth fixpoint marks reach; the sorted unreachable exports are
the DARK SURFACE.  Statement keywords (return/if/while/else/select) are excluded as
callees; `from` is a reserved word (edge params renamed src_node/dst_node).  Census
state: ~5 MB of BSS (interned nodes, deduped edge list + FNV sets); overflow anywhere
fails LOUD (CV_OVERFLOW), never under-reports.  Driver writes _cov_reach_report.txt;
build_stdlib gained the THIRD down-only ratchet vs scripts/coverage_reach_pin.txt.
Falsifier `1464_coverage_reachability`=99: hermetic tree where v1 reads COMPLETE while
v3 flags exactly the dark export; all three edge forms proven (internal-helper bridge,
&-take, bare assignment); the ratchet (a corpus use site moves ROOTS, never edges); the
seal binds the v3 census and reproduces.

First real-tree census: 32 -> (bare-assignment fix) -> **13 genuinely dark exports**,
each verified to have zero call sites anywhere: bitops_rotr64, dij_n (declared by
topology_atlas, never called), frq_from_mont_x, hl_footprint, ini_key_base,
mp_default_or_fail_dispatch, nl_token_span_start/end, obs_observatory_value,
pattern_predicate_fn, pattern_template_set_predicate,
proof_ripple_corpus_equiv_old_pid/new_pid (declared by governance, never called).
All 13 closed in `1465_dark_surface_gaps`=99 with known-answer laws (exact rotations,
Montgomery round-trip over BLS12-381 Fr, packed-token field laws, INI key addresses,
heaplet footprint bits, real equivalence certs minted over registered dispatch pairs --
pattern slots must stay < PATTERN_REGISTRY_USED_MAX 100).  Pin established at **0**:
the dark surface starts and stays at the absolute floor; any future export no corpus
test reaches FAILS the build.

## The frontier tranche — boundary walls, refusal arms, inverse laws (2026-06-12)

A 4-lens read-only discovery (boundary-value proofs at capacity constants /
error-vocabulary completeness / inverse-law pairs / free structural audit) with
per-finding ADVERSARIAL verification: 30 claims -> 16 confirmed + 14 refuted (the
verify layer caught wrong evidence, dead-constant red herrings, and two unimplementable
closures -- and two refutations still carved out real, narrower residuals).  All 16
confirmed findings + both residuals closed in eight tests, every one green first try:

- `1466` registry caps: pattern_register USED_MAX=100 (slot 99 admits / 100 refused as
  a NON-WRITE), cat_add_object 1024 objects (deterministic slots, the 1025th SENT, the
  read gates exact at 1024), fed_seal_anchor 256 (the 257th -3 E_FULL, clear recovers);
- `1467` parser caps: csv ROW_MAX=1024 + COL_MAX=32 both ways, json MAX_NODES=2048 (a
  procedurally-built EXACTLY-2048-node document parses; 2049 refused with the table
  filled-then-refused), nl_lex LEXICON_CAP=4096 (fill, E_FULL, at-full update REFUSED
  with the packing untouched, below-cap in-place update live);
- `1468` arena caps: egraph EGRAPH_MAX_NODES=131072 (the hash-consed f-chain admits
  exactly 131071 + the leaf == CAP; SENT stably; class census exact -- 1107 had pinned
  no count, so a capacity regression to 1000 would have passed), ccl CCL_CAP=65536
  (last node 65535, then refused, reset recovers);
- `1469` FS_E_DENIED (all four mutating gates + the READ-less handle seek, plus
  NON-VACUITY under the full cap) and PT_E_ALREADY_FINAL (both sites, non-destructive);
- `1470` base32 round-trip law over encoder OUTPUT (every RFC 4648 remainder class
  0..6 + multi-block, padded-length law pinned per class) and the glyph_map pair edges
  (empty map, exact 140-byte capacity, 36 pairs -3, degenerate geometry -2, the VEC
  form through the MAP unpacker -2, the short dst -5);
- `1471` deallocation contracts: arena_drop/region_release bad-id+double-drop (-3),
  handle close-RETAINS/drop-FREES asymmetry (close idempotent by design, double drop
  -1, close-after-drop -1, slot scrubbed, neighbors untouched), fs_close null/double
  (-4).  Plus the bonus defect the verification surfaced: arena.iii's ARENA_E_BADID=-2
  documented a code NEVER produced (arena_drop forwards REG_E_BADID=-3) -- the dead
  constant is removed, the real contract pinned by the test;
- `1472` bit-width edges: rotation by width-1 (the ONLY shift that discriminates a
  wrong mask constant), width, width+1, 2*width -- hand-derived literal expectations,
  not tautological identity comparisons; next_pow2 at 2^63 / 2^63+1 / max / 0;
- `1473` the residuals: WITNESS_E_FULL actually TAKEN through both append variants at
  the exact 1024 wall (1027 pre-flighted and stopped 2 short), and the tempaloc
  REGION partition (exactly 64 live, the 65th refused, release recovers) + the three
  DISTINCT slot_of refusal arms (forged out-of-bounds raw, forged type byte, dead
  handle) each mapped to REG_E_BADID.

## Wave 2 — transition walls, layout contracts, numeric edges, and a REAL DEFECT (2026-06-12)

Second 4-lens discovery (state-machine transitions / cross-module byte layouts /
numeric edges / hostile reviewer) + adversarial verify: 19 claims -> 9 confirmed,
10 refuted.  One verifier ran MUTATION ANALYSIS: the governance-seal guard mutant
`!= GOV_ACCEPTED` -> `> GOV_ACCEPTED` (allowing PREMATURE sealing) survived the entire
corpus -- naive branch coverage looked complete because re-seal-of-SEALED exercised the
reject branch once, from the wrong side.  Closures:

- corpus 205 EDITED: four illegal-seal probes (PENDING/SANDBOXED/PROVEN/REJECTED ->
  exactly -3 GOV_E_BAD_STATE, status untouched) -- kills the premature-seal mutant;
- `1474` the governance transition matrix: promote refused -7 from all five non-PROVEN
  states (incl. no-double-promote and the REJECTED ladder where the FIRST promote is
  the -6 rejection and the SECOND is -7 -- the codes proven distinct and ordered);
  re-prove refused through both gates with the minted cert intact; bad id -1;
- `1475` quarantine rollback-after-abort refused (-3 QUAR_E_STATE, state still ABORT)
  + the bounds arm -- the selftest had aborted and rolled back only DISJOINT slots;
- `1476` the 192-byte glyph frame layout pinned from OUTSIDE: test-owned offset
  arithmetic + an independent sha256 over [0..160) byte-identical to [160..192),
  write-exactly-192 sentinels, and the last-mhash-byte negative arm -- an offset
  drift in any glyph module now FAILS a test instead of silently corrupting;
- `1477` numeric edges: q128 shifts 127 (>= 64 branch at maximal s2, discriminated
  against the >= 128 clamp) and the never-tested < 64 CROSS-LIMB arm (3 << 63);
  mod_u64_{add,mul} over m = 2^64 - 59 -- the wrap arm of mod_u64_add is REACHABLE
  ONLY for m > 2^63 and no corpus modulus had exceeded 2^61 ((m-1)^2 = 1 sweeps ~63
  wrap iterations); bigint sub-to-zero through bigint_sub's own INLINE normalize
  (distinct from the exported bigint_normalize), len observed 0 directly + near-miss;
- **THE DEFECT** -- `1478` + rscode.iii FIXED: with rs_init never called (k = 0 BSS),
  rs_encode / rs_decode_prepare / rs_decode_apply all SILENTLY returned RS_OK --
  apply's staleness guard `RS_PREP[0] != k` was VACUOUS at 0 == 0, so an
  erasure-recovery caller that forgot init received success and all-zero "recovered"
  data.  The KAT was written FIRST and FAILED against the unfixed module (exit 1);
  three k >= 1 guards added (encode/prepare -> RS_E_DIM, apply -> RS_E_SING); the KAT
  then passed (99) and the existing positive tests 1217/1223 still pass -- the fix
  refuses only the uninitialized state.

## Wave 3 — SATURATION (2026-06-12)

Third discovery wave (hostile-reviewer round 2 over crypto/witness/resolver/XII,
duplicate-implementation differentials, error-path slot leaks): 14 claims -> **0
confirmed, 14 refuted**.  Every "unchecked cad_* return" was statically unreachable
(compile-time constant suites whose only failure mode is an unknown suite; module-BSS
pointers that are never null; digests ALWAYS written), the claimed slot leaks do not
exist (acquisition/release traced balanced on all paths), and the in-tree duplicate
implementations are already differentially pinned through other corpus routes (953,
146/1055, 757...).  Verifiers explicitly marked the four optional "belt-and-suspenders"
closures as NOT defect closures; per the anti-bloat principle they are not built.

Confirmed-yield curve across the waves: 16 -> 9 -> 0.  **The test-coverage axis is
saturated at the floor**: four criteria (reference / gate-outcome both-ways /
reachability / boundary-refusal-inverse tranches) all pinned at 0 with down-only build
ratchets, three discovery waves adversarially verified, the final wave finding nothing
real.  Future coverage work should be DRIVEN by new code landing (the ratchets catch
it automatically), not by further discovery sweeps of this tree.

## W3.7 — the egraph incremental rebuild (2026-06-12)

The structural-audit re-verification (4-agent fan-out over the stale plan docs: ~40
items classified, most DONE-stale-doc, the W3.21 micro-fixes all already live) found
W3.7 genuinely open: eg_rebuild wiped all 262144 hashcons slots and re-keyed every
node on every pass.  LANDED: the egg-style parents index (1M-entry arena, O(1) splice
on union) + DIRTY worklist; eg_rebuild drains dirty nodes ascending per pass;
eg_rebuild_full keeps the original algorithm as the pressure-gated fallback and the
differential ORACLE.  Three structural proofs made byte-identity achievable: stale
entries are semantically harmless (matching re-verifies through eg_find; absorbed
roots are never canonical again), eg_union is arg-order symmetric (rank/lower-id
survivor -- the seal folds raw ranks), and clean nodes contribute no unions in either
strategy.  Falsifier `1479`: an engineered rank-boosted merge dirties a node BEHIND
the scan (asserted >= 2 drain passes), identical workloads through both strategies
must seal cad-equal; the no-dirty fast path returns 0 and mutates nothing.  All six
existing egraph consumers re-verified standalone (incl. the sovereign optimizer and
the 131072-node capacity fill); corpus 1067/0.

## W3.18 + W3.22 — AES gmul hygiene, the checked->option table fold (2026-06-12)

W3.18 (severity CORRECTED on implementation): aes_gmul's data-dependent branch is now
branch-free (the aes_xtime mask idiom) -- but tracing the call graph showed its only
live caller is the GF(2^8) inverse during S-BOX TABLE INIT (all 256 public bytes;
MixColumns uses xtime chains directly), so the old branch was never a live secret
channel.  Hygiene + robustness for future callers; FIPS-197/192 KATs byte-identical.
The real deferred constant-time item remains the S-box table lookups (APOTHEOSIS S.5).

W3.22/COMBINE-8/D-CHK-2: checked.iii's private 64-slot u64 side table DELETED --
checked u64 handles now ARE option_u64 handles (one table, identical encoding and
guard semantics; capacity 64 -> 256 shared; option's distinct table-full sentinel
maps to checked's 0-on-any-failure contract).  Falsifier `1480` pins the unity in
BOTH directions: option reads/frees checked's mints and vice versa, and a freed slot
is RE-ISSUED across the API boundary (impossible with two tables); the failure
contract pinned through all four ops.  Existing 1000/1057 lifecycle tests green
unchanged; corpus 1068/0.

## W0.6 — the dijkstra extraction + THE eg_find OOB DEFECT (2026-06-12)

eg_extract_dijkstra LANDED: the Knuth monotone-worklist extraction (a class FINALIZES
at its first heap pop -- node cost = base + sum(children) is a superior function) over
the [W3.7] parents index and the canonical omnia/pq heap (packed (cost<<32|class) keys:
a deterministic total order); the Bellman fixpoint stays as eg_extract (the pinned
default), the fallback, and the ORACLE.  Falsifier `1481` compares both extractors
BYTE-FOR-BYTE over five adversarial fixtures (union-cycle, duplicate-child diamond,
equal-cost tie with the lowest-node-id rule, a cost-table flip, the out-of-range-root
refusal) plus a ran-probe so the differential can never silently degrade to
fixpoint-vs-fixpoint.

Getting 1481 green surfaced THE DAY'S THIRD REAL DEFECT: eg_find had NO bounds check --
an out-of-range class id walked EGRAPH_CL_PAR straight off the 131072-entry array, an
OOB READ reachable through EVERY eg_find-routed export (eg_union / eg_class_size /
extraction root resolution) with an attacker-supplied id, and it segfaulted the
ORIGINAL eg_extract too.  Fixed at the source (>= MAX_CLASS -> SENT, refusing cleanly
through every downstream gate); 1481's refusal fixture is the permanent regression.
Two implementation bugs caught pre-commit by the falsifier: pq pop returns the
OPTION-ENCODED payload ((v<<1)|1 -- the raw truncation doubled class ids), and the
heap must be sized to the true offer bound (leaves + parent edges), not a constant.
All seven egraph consumers re-verified; corpus 1069/0.

## The J-contract + live-set wave — 6 findings, falsifiers 1482-1486 (2026-06-12)

Recovered the prior session's stranded tail (the CUT-8/W3.29 mask cuts built+gated but
uncommitted, and falsifier 1482 written with its fix NEVER APPLIED), then a 6-finding
batch, each old-lib/new-lib differential-proven:

**J-RESULT-1** (`omnia/result.iii`, falsifier `1482`, old-lib exit=1): result__ok's
`(v as u64) << 1` SIGN-extended a negative i8/i16/i32 and clipped bit 63 -- the
unwrapped u64 was neither extension image.  Contract fixed at source: the ok payload
is the WIDTH-truncated, ZERO-extended image (`sizeof T` mask), both unwrap_or arms;
`as T` at the call site re-sign-extends so 395's truncation law is unchanged.

**J-ITER** (`omnia/iter.iii`, falsifier `1486`, old-lib exit=2): iter__next returned
the sign-extended image for signed elements -- contract-inconsistent with J-RESULT-1.
Aligned to the one width law; the 64-bit lanes BYPASS the mask (x86 SHL masks the
shift count: 1u64<<64 == 1, the C-BV-1 lesson -- a naive mask would zero every i64).
W6.1's STDLIB half is hereby discharged AT SOURCE: 1482/1486 pass without a compiler
reseal; only the @specialize stride re-verify remains compiler-side.

**CUT-10 nous live-set** (`nous_socket/nous_policy/nous_value`, falsifier `1483`,
old-lib exit=1): all three rank tables still emitted the route-S-retired R001-R004 --
invisible to every behavioral gate BY CONSTRUCTION (a retired rule has no representable
redex), only a STRUCTURAL pin can see it.  Swept to the live set (cascade 50->46,
ascend 49->45, policy 49->45); the socket's "EXACT firing sequence" claim is true
again; 1483 pins the emitted orders element-wise against the cascade transcribed from
apply_one's text + the absence law + NOL certification + the policy's full permutation
over the live set.  Keystone differential gate stays GREEN (the behavioral identity).

**B-JN-1** (`omnia/xii_joinability.iii`, falsifier `1484`, old filter returned 20):
xjn_nj_unexpected tested the REWRITER against retired assoc ids -- no record can match,
so it flagged ALL 20 residual non-joins, contradicting its docstring (1422 only pins
determinism).  Dumped the live record (njdump probe): 10 (collapse/sort x lift) pairs
x subterm positions {cb,cc}.  Re-expressed: expected = kind SUBTERM and rewritten in
lift R005-R012 (the C.1-discharge set); a ROOT non-join is always unexpected.  Added
the XJN_NJ_K kind recorder (pos alone cannot separate root from a ca-subterm) +
xjn_njtab_k; 1484 pins the 20 records element-wise to the certified set and
demonstrates the old filter dead inline (matches 0 of 20).

**J-BIG-1** (`numera/bigint_div.iii`, falsifier `1485`, old-lib exit=7 = a WRONG-VALUE
handle escaped): the discovery-workflow survivor -- both modpow ladders never checked
per-step allocations; 64-slot handle-table exhaustion mid-ladder rode a degenerate 0
handle through every later multiply and returned a VALID handle holding GARBAGE (RSA
verify gets no error signal).  Refuse-whole on every step + leak-free failure paths
(ctx/one/b_cur/result all dropped); 1485 sweeps leftover-slot counts 0..11 on BOTH
ladder paths: refusal or the truth, never a wrong value, plus non-vacuity both ways
and post-refusal full recovery (no slot leak).

Hygiene: nous_value/cost_lattice stale labels ("49x49 selection sort", "subtractive
Euclid") corrected.  Adjudicated NOT-edited: fed_seal streaming-hash claim is a latent
cg_r0-only hazard (cg_r3 reads exactly 4 bytes; fed_seal is in no Ring-0 build) --
revisit when fed_seal joins a KATABASIS image.

Queue re-verify (verify-still-open caught five MORE already-closed items): W3.21 all
four CLOSED (merkle MERKLE-2, bv_ring C-BV-1, proof_carrying C-PC-3, nous_search
C-NS-1), COMBINE-10 murmur3 CLOSED, CUT-11 CLOSED, fold's dead extern CLOSED.  Open
perf vein: fe25519 E-FE-2/3, mldsa E-MLD-3, cost_calculus A-CC-1, pleroma A-PL-1,
math D-ML-1, uncertainty F-UNC-1, groebner F-GB-2, combinator F-CB-1, fn256/384
D-FN-1; compiler W6.2-6.5.

build_stdlib GATE PASS + FAIL=0; corpus **1074/0** + xii 92/0 + nous GREEN (incl. the
keystone differential) + bench 7/0/0.

## A-CC-1 + A-PL-1 — the two O(big) -> O(linear) walks, oracle-adjudicated (2026-06-12)

**A-CC-1** (`numera/cost_calculus.iii`, differential `1487`): register pressure's
O(n^2) peak sweep -> an O(n + dep_n) difference array over the live intervals
[m, LIVE_UNTIL[m]] (+1 at m, -1 past the clamped end, prefix-max; partial sums never
negative so u64 wrap is exact).  The sweep STAYS as the in-module ORACLE
(cc_regpressure_oracle/_fast exports); 1487 pins analytic fixtures (empty=0, single=1,
chain=2, all-live=n, past-block clamp=2 -- never oracle-vs-oracle), LCG fixtures at
n=64 and the full n=1024 block, refusal symmetry, and determinism.  The shared fill
gained a defensive producer bound (the public path was already cc_check_deps-guarded).

**A-PL-1** (`forcefield/pleroma.iii`, differential `1488`): pleroma_cohere's spanning
forest re-scanned ALL edges per popped vertex (O(V*E)) -> a CSR incidence index
(one ascending stable counting-sort pass; src-side entry = FORWARD, dst-side only when
dst != src = BACKWARD, mirroring the scan's else-guard so a self-loop stays
forward-only).  Visit sequence, gauge assignments, and obstruction choice are
byte-identical by construction; the original walk is exported as pleroma_cohere_scan
(the ORACLE).  1488 pins coherent/non-gluing/malformed/backward-edge/self-loop
fixtures with verdict + root-byte + obstruction identity and analytic verdict pins.
New shared guard: edge_count bounded (the u32 dir-bit + 2E-entry allocation), applied
to BOTH strategies so the differential covers every input.

Gates: build GATE PASS FAIL=0; corpus **1076/0**; xii 92/0; nous GREEN; bench 7/0/0.

## F-UNC-1 + F-GB-2 + F-CB-1 — memo, chain criterion, bracket optimization (2026-06-12)

**F-UNC-1** (`numera/uncertainty.iii`, falsifier `1489`, old exit=3): the provenance
walkers had NO visited memo -- a shared sub-DAG re-walked once PER PATH (a 20-layer
diamond cascade = ~2^21 pops), root_causes returned path multiplicity instead of the
root SET (the smallest diamond reported its one root twice), and -- the soundness
half -- the full-stack guard SILENTLY DROPPED subtrees, so unc_well_formed could
vouch for a branch it never visited.  The memo expands each gid once: at most
UNC_NEXT (<= the stack capacity) pushes, the drop guard structurally unreachable.
The antecedent-existence guard was already present (refuted my third-hole claim).

**F-GB-2** (`numera/groebner.iii`, differential `1490`): Buchberger's chain
criterion -- skip (i,j) when some k has LT(k) | lcm and both (i,k),(j,k) already
TREATED; the FIFO pop order is strict, so mutual citations cannot cycle.  Pruned
pairs counted (gb_c2_pruned, the non-vacuity witness); the C1-only path exported as
the ORACLE.  1490 = prune>0 + digest identity (live vs oracle, fresh sessions) +
the ANALYTIC arm (every S-poly of the output reduces to zero -- the definition, so
an agreed-wrong basis cannot pass) + the linear regression fixture.

**THE 1490 DEBUGGING SAGA (falsification discipline receipts):** the first draft
E_INV'd; hypotheses killed in order by probes gbprobe1-13: fixture-too-big ->
handle exhaustion (instrumented live-count: FAIL with only 4 live = NOT exhaustion)
-> closure handle leak -> nested-extern-call ABI defect -> ROOT CAUSE: the harness
passed a RAW prime where gb_begin expects a bigint HANDLE (raw 7 aliased slot 7 ->
garbage modulus -> E_INV deep in gfp_inv).  BOTH defect theories retracted on clean
differentials (nested and local-bound styles both pass with the correct handle).
Hardened: gb_begin now refuses p==0 + documents the handle contract (1490 pins it),
so the next caller gets E_BAD at the door instead of a deep E_INV mystery.

**F-CB-1** (`numera/combinator.iii`, differential `1491`): Curry-optimized bracket
abstraction (K-without-descent + eta, with the de-Bruijn shift-down the naive
per-var decrement provided; structural sharing -- a var-free subtree is returned
unchanged).  The naive translation tripled the term at every binder (3^k); kept as
cb_compile_naive (the ORACLE).  1491 = structural pins (compile(lambda lambda. #1)
IS K; eta yields the atom itself), the shift law applied, the MEASURED blow-up
(5 binders: naive >500 nodes vs optimized <20, reduction-equal saturated), and the
iota composition regression.

Gates: build GATE PASS FAIL=0; corpus **1079/0**; xii 92/0; nous GREEN; bench 7/0/0.

## D-ML-1 + E-FE-2 — the math-library index, the dedicated field squaring (2026-06-12)

**D-ML-1** (`numera/math_library.iii`, differential `1492`): lib_find walked ALL
65536 slots (no early exit -- the sentinel only skipped work) with a 32-byte compare
per live slot, run once per duplicate gate + once per DEPENDENCY per admission, plus
a second full walk for the free slot.  Now: a 131072-entry open-addressed id index
(first 8 bytes of the content address; load <= 0.5; the library is MONOTONE so no
tombstones), free slot == COUNT, the scan exported as lib_find_scan (the ORACLE),
the white-box selftest arms co-maintain the index, and a stale index entry is
harmless by the LIVE re-check (the egraph-hashcons property).  1492 drives the real
proof-term -> carrier -> ratify -> admit vertical with two carriers: find == scan ==
admission order, absent agreement, the indexed duplicate gate, indexed refine.

**E-FE-2** (`numera/fe25519.iii`, differential `1493`): dedicated fz_sq -- cross
products computed once and DOUBLED (+ the diagonal), ~half the limb multiplies; the
*38 fold extracted as _fz_fold38 (ONE reduction proof surface for mul and sqr);
fz_pow already routes every ladder squaring through fz_sq, so the win lands on
invert/decompress/scalar-mul (256 squarings per inversion).  1493 pins bit-identity
vs fz_mul(a,a) on edges + 64 decoded elements; a raw-limb probe extended the
differential over the UNFROZEN fold-output domain (all-0xFFFFFFFF limbs + 256
full-domain LCG cases) that fz_decode cannot reach but the ladder lives in.
KAT-craft receipts: two arm failures were MY contract violations against the
module's deliberate design (fe25519_init owns the ladder exponent; fz_encode is a
raw serializer under the DEFERRED-freeze law -- canonical bytes require fz_freeze,
exactly as fz_equal/ed_compress do).  The module needed no fixes.

Gates: build GATE PASS FAIL=0; corpus green through 1493 (the run's terminal FATAL
is the not-yet-wired 1494's EXPECTED bookkeeping, nothing failed); xii 92/0; nous
GREEN; bench 7/0/0.  Full count re-pins next cycle.

## E-MLD-3 + E-FE-3 — in-place NTT, dedicated point doubling (2026-06-12)

**E-MLD-3** (`numera/mldsa.iii`, differential `1494`): every slot transform copied
256 coefficients into MLDSA_WORK and back (512 copy-moves per NTT across keygen/
sign/verify).  The shared organ takes a base address (*u32, 4-byte stride -- the
packed layout the typed pool access uses), so the transform now runs AT the pool
slot; the copy path retained as mldsa_ntt_scratch/mldsa_invntt_scratch (the ORACLE).
1494 = the in-module differential (slot-identical forward AND inverse vs the oracle
on identical copies + the round-trip identity); FIPS-204 vectors (198/769) re-pin
the live path.

**E-FE-3** (`numera/fe25519.iii`, differential `1495`): the scalar ladder doubled
via the unified 9M add; dedicated dbl-2008-hwcd (a=-1) doubling = 4M+4S with S the
new fz_sq.  Projective consistency PROVEN symbolically (every output component of
add(p,p) is exactly -4x the dbl output -- E by -2, F/H by 2, G by -2 -- so the point
and its T-coherence are identical) and pinned empirically: 1495 compress-equality at
B/2B/3B (fixtures built via ADD ONLY from the RFC-8032 base decompression -- the
differential cannot be circular vs the dbl-routed ladder), T-coherence through
follow-on adds, identity self-doubling, and scalar_mul(4) == ((B+B)+B)+B.  RFC-8032
sign/verify vectors re-pin end-to-end in the same run.

**D-FN-1 DECLINED-as-immaterial:** fn256's 6-iteration Newton n' runs ONCE per
process at init; 4 iterations suffice (3*2^k bit doubling: 3->6->12->24->48 >= 32).
The saving is two 32-bit multiplies, once -- touching crypto init for that fails the
latent-gain triage rule.  Same verdict applies to fn384's mirror.

Gates: build GATE PASS FAIL=0; corpus **1083/0**; xii 92/0; nous GREEN; bench 7/0/0.

## W6.2-6.5 — the compiler batch: CUT-9 + G-SEMA-1, one reseal (2026-06-12)

The structural audit's last major open item, executed per the BOOTSTRAP_SEAL doctrine
(golden hash moves exactly once: 7480c725 -> **8dae39fd**).

**W6.2 CUT-9** (`COMPILER/BOOT/cg_r3.iii`): DEAD-STACK-1 R3_G_MAX_STACK_DEPTH deleted
(write-only: maintained, reset twice, read NOWHERE; decision recorded -- delete, not
wire: no consumer or failure semantics were ever defined).  DEAD-D7-1 duplicate-label
gate deleted (r3_label_already_defined/r3_label_record + four arrays ~580KB BSS +
counter + orphaned R3_MAX_LABELS): deadness proven at BOTH levels -- source (zero
callers, zero address-of, tree-wide) and binary (not @export -> absent from the
object symbol table -> no cross-TU path; intra-TU census complete).  R3_E_DUP_LABEL
kept (the C seed still raises it; the ENAME LUT stays total).  SEPARATE-4 (the cg_r3
split) DECLINED per the verification's own low-confidence recommendation -- recorded.

**W6.3 G-SEMA-1** (`COMPILER/BOOT/sema.iii`): the per-identifier decl lookups
(s_decl_table_lookup/_cstr -- full first-match scans) -> an open-addressed FNV index
(2048 entries, load <= 0.5, no tombstones), filled at s_decl_table_add
ONLY-IF-ABSENT so each name maps to its FIRST row; equality runs through the SAME
comparators the scans used.  Byte-identical resolutions BY CONSTRUCTION, proven by
the gate below.  **G-SEMA-2 (Aho-Corasick raw-opcode scan) DECLINED-as-immaterial:**
16 short patterns over rare, short metal-asm blocks.

**W6.4:** cg_rm2's C9 fix verified ALREADY DONE -- the audit's own text cites it as
the historical golden move (4e1384 -> 53ce03).  No other confirmed BOOTSTRAP_SEAL
edits remained (W6.1's STDLIB half was discharged at source by 1482/1486).

**W6.5 receipts:** seal-gated build GREEN, stage1 byte-equivalence **59/0** (the
differential for both edits); NEGATIVE ARM: a one-byte emit sabotage (pushq %rax ->
%rbx) reddened ALL 59 (exit 5) -- the gate has teeth; restore rebuilt to the
BIT-EXACT 8dae39fd (determinism); check-rm2 + cg_r0 gates green; then the full
STDLIB rebuild + corpora under the resealed compiler: GATE PASS FAIL=0, corpus
**1083/0**, xii 92/0, nous GREEN, bench 7/0/0.

## Wave-9 — @export memory-safety + crypto call-order hazards (2026-06-12)

A read-only 5-lens discovery (init-order / handle-contract / error-collision / wrap-gaps /
quadratic-scans, 28 agents, 8 survivors of 23) over fresh axes distilled from this session's
own KAT-craft lessons.  Implemented the three verified-open memory-safety + correctness
hazards (the eg_find-OOB class from last session); declined two with recorded reasoning.

**W9-K0** (`numera/k0_referee.iii`, falsifier `1496`, old exit=8): the immutable-base-kernel
referee -- the module whose entire purpose is "it trusts NOTHING" -- had an UNBOUNDED OOB
WRITE in its own setter: k0_set_behav validated x(<16) but NOT k(<32) before writing
K0_BEHAV[k*16+x], so k>=32 wrote past the 512-slot array into K0_COST.  k0_behav/k0_cost had
the symmetric OOB read.  Guarded all three (k>=K0_KMAX -> set returns -3, reads return 0).
1496 pins the BOUNDARY (k=31 slot 511 round-trips; k=32 slot 512 refused) -- a misplaced guard
reddens; the existing 1247 referee KAT proves the valid path byte-identical.

**W9-DIJ** (`numera/dijkstra.iii`, falsifier `1497`, old exit=8): the shortest-path API, whose
header invites external consumers (aether::topology_atlas weighted routing), had four unguarded
@exports: dij_edge (OOB read), dij_set_edge (OOB WRITE to DIJ_W[u*5+v]), dij_compute (OOB WRITE
to DIJ_DIST[src]), dij_dist (OOB read).  Guarded all four (out-of-range -> INF for reads, -1 for
mutators).  1497 pins the boundary + re-pins the real shortest-path computation byte-identical;
internal callers always pass valid ids so the guard never fires there.

**W9-FE** (`numera/fe25519.iii`, falsifier `1498`, old exit=1): fz_invert = fz_pow(a, FZ_PM2),
and FZ_PM2 (the p-2 Fermat exponent) is written ONLY by fe25519_init.  Called cold, FZ_PM2 is
all-zero -> a^0 = 1 for EVERY a: a SILENT cryptographic failure (the "inverse" is the constant 1,
the return code says success).  The whole module is init-dependent (FZ_P/FZ_2P/FZ_2D/...).  Fix:
a lazy-init guard (_fz_ensure_init, idempotent) at every constant-reading @export
(fz_add/sub/freeze/invert, ed_pt_add/dbl, ed_scalar_mul_pt/base, ed_compress/decompress); the pure
pseudo-Mersenne fz_mul/fz_sq and byte-shuffle fz_decode/encode stay guard-free (the hot inner
multiply).  Byte-identical for the documented "call init first" caller (init is idempotent).  1498
runs WITHOUT init: arm 1 cold-invert == warm-invert (pre-fix the cold result is enc(1), diverges);
arms 2-3 pin a*inv == 1 (mod p) absolutely so it cannot pass vacuously.

**DECLINED (recorded):** bitio bitw_bytelen u32 wrap -- BIO_WPOS has no setter; reaching
0xFFFFFFF9 needs a 512MB+ fully-written buffer, unreachable through any @export path (same verdict
as the sibling lzss/huffman wraps); no teeth-bearing falsifier exists.  cap_forge cf_slot_of_cap
reverse-index -- needs tombstone/rebuild handling under cf_deforge_cascade deletion on a SECURITY
(capability) module for a marginal gain on the rare forge path; cf_alloc USED early-exit is
byte-identical and helps only the full-table edge case.  Both risk/reward-unfavorable.

Gates: build GATE PASS FAIL=0 (carto: no @export collision; _fz_ensure_init is module-local);
the 3 falsifiers 99 vs new / fail vs old (8/8/1); xii 92/0; nous GREEN; bench 7/0/0.  Corpus delta
verified race-free: only THREE .o changed content (k0_referee/dijkstra/fe25519 -- the lib is an
archive of independent objects, so no untouched test can regress), and all 15 tests that extern
those modules (388/973/993/1247/1290/1403/1431/1436/1451/1465/1493/1495 + the 3 new) re-run
GREEN against the new lib.  Count 1083 -> **1086**.

## Wave-10 — accessor-bounds OOB guards (the 384-bit-sibling-was-guarded gap) (2026-06-12)

A read-only 5-lens discovery (reentrancy / exhaustion-degenerate / numeric-edges /
oob-guards-other / determinism-seal2; 14 agents, 6 survivors of 9 -- the reentrancy,
numeric-edge, and CIOS-carry candidates all refuted as intentional/correct) surfaced a
coherent cluster: a PRIOR audit guarded the 384-bit prime fields (fp384 fq_set/get_limb,
fn384 gn_get_limb_x all `if slot>=48 / idx>=12`) but MISSED the structurally-identical
256-bit fields and the zk/combinatorial structures.  Hardened the whole accessor family
per module to the sibling form (set -> -1, get -> 0):

- `numera/fp256.iii` -- fp_get_limb / fp_set_limb (FP[512]=64*8): slot>=64, idx>=8.
- `numera/fn256.iii` -- fn_get_limb_x / fn_set_u32_x (FN[512]=64*8): slot>=64, idx>=8.
- `numera/zk_field.iii` -- frq_set/get_limb (ZKFR[4096]=512*8: slot>=512,idx>=8) +
  zkf_set/get_limb (ZKF[49152]=4096*12: slot>=4096,idx>=12).  BLS12-381 Fr/Fp.
- `numera/knapsack.iii` -- knap_dp(cap): cap>=17 -> 0 (KNAP_DP[17], cap indexes [0..cap]).
- `numera/segment_tree.iii` -- seg_update(i): i>=8 -> -1 (SEG_VAL[8]/SEG_TREE[16]);
  seg_query(l,r): l/r>=8 -> INF.

All OOB write/read on @export with caller-supplied indices (same class as wave-9 k0/dijkstra
and the prior eg_find defect).  Falsifiers `1499` (256-bit fields), `1500` (zk-field),
`1501` (knapsack+segment-tree): boundary-pinned (last valid index round-trips, one-past
refused), gentle 1-past OOB probes, 1501 pins knap_dp==knap_brute so it cannot pass
vacuously.  Old-lib teeth: 5/3/3 (missing guards returned 0 or the OOB-computed 18).

Gates: build GATE PASS FAIL=0; the 3 falsifiers 99 vs new / fail vs old (5/3/3); corpus
delta verified race-free -- only FIVE .o changed content (fp256/fn256/zk_field/knapsack/
segment_tree), all 19 tests externing them + the 3 new re-run GREEN against the new lib.
Count 1086 -> **1089**.

## Wave-11 — the EXHAUSTIVE single-line accessor-bounds sweep (2026-06-12)

A direct tree-wide grep (faster + more complete than a fuzzy agent for this mechanical
pattern) enumerated every single-line @export accessor `ARR[param...]` lacking a leading
bounds guard.  The prior audit + waves 9-10 had covered only a fraction; this closes the
class.  Guarded 23 accessors across 12 modules to the array cap (getters -> 0, setters -> -1):
dce (set_side/live), dominators (dom_set), gvn (vn/redundant), kmp (fail), list_schedule
(start), reg_alloc (reg), rewrite_schedule (order), sccp (state/const), congruence_closure
(pcc_path/expl), taint_analysis (set_source/imm/op/sanitize/sink/tainted), threshold_vault
(tv_keyshare_x), sieve (is_prime).  A re-sweep confirms ZERO unguarded single-line
accessors remain.

Falsifier `1502`: clean old/new teeth via the SETTER guards (dce_set_side(6,..) and
taint_set_source(64) return 0 pre-fix having done the 1-past write, -1 post-fix -- arms 2/5
redden against the old lib, exit 2); every getter guard pinned on the new lib (OOB index ->
0); sieve's boundary anchored to real primality (2/47 prime, 50 composite valid, 51 guarded)
so the bound is provably not over-tight.

Gates: build GATE PASS FAIL=0; 1502 99 vs new / exit 2 vs old; corpus delta verified
race-free -- only 12 .o changed content, all 17 tests externing them + 1502 GREEN against the
new lib.  Count 1089 -> **1090**.

## Wave-13 — fix_div large-operand precision (the FIRST non-OOB find; numeric axis) (2026-06-12)

After the OOB/@export-bounds axis saturated (waves 9-11 swept it; wave-12 returned only
(ptr,len)-convention false positives, all refuted on inspection -- the length IS the contract,
unguardable), the loop PIVOTED off it.  A 5-lens fresh-axis discovery (numeric-precision /
lifecycle-leak / cross-module-misuse / seal-determinism / weak-gate) yielded one real find
(the 3 tempora lifecycle candidates refuted -- alloc-then-slot_of cannot fail, no teeth).

**W13-FIX** (`numera/fixed.iii` fix_div, falsifier `1503`, old exit=4): the Q32.32 fractional
long division maintained the invariant acc < b but computed `acc = acc << 1` unconditionally.
When acc >= 2^63 (reachable iff b > 2^63, since acc < b) the shift OVERFLOWS u64 and drops the
top bit, so the subtract-and-set never fires and the fractional part collapses toward zero:
fix_div(2^63, 2^63+1) returned 0 instead of 0xFFFFFFFF (the true ratio is just under 1.0).
Fix: capture the lost carry (`carry = acc >> 63`); when carry=1 the true 65-bit value exceeds
any u64 b so the subtract is unconditional ((true-b) reduces to (acc-b) in wrapping u64 because
true-b = 2^64+acc-b < 2^64).  For b <= 2^63 (ALL normal Q32.32 use) carry is always 0 ->
byte-identical (corpus 30/1056/1330 stay green).  1503 pins the law fix_div(b-1,b)==0xFFFFFFFF
(exact for any b > 2^32; the large-b instances exercise the overflow path) + the headline +
exact small-operand regressions.

Gates: build GATE PASS FAIL=0; 1503 99 vs new / exit 4 vs old; only fixed.iii changed content,
the 3 existing fixed.iii KATs + 1503 GREEN.  Count 1090 -> **1091**.

## Wave-14 — fs_open OS-handle leak on table-full (resource lifecycle) (2026-06-13)

A 5-lens fresh-axis discovery whose CENTERPIECE -- protocol/state-machine invariants in the
consensus/federation modules (hotstuff quorums, fed_seal tiers, branch_governance) -- came back
CLEAN (every candidate refuted as intentional-documented or teeth-less: the consensus logic is
sound under adversarial review).  The one real survivor was a resource lifecycle leak.

**W14-FIX** (`aether/fs.iii` fs_open + fs_dir_open, falsifier `1504`, old exit=4): fs_open opened
the OS file handle (CreateFileA) then returned handle_alloc(...) directly.  When the 64-slot
handle table is full handle_alloc returns 0 -- and the OS handle was LEAKED (never CloseHandle'd),
leaving the file open (locked) until process exit (reachable: onelang hit the 65th open in a deep
dir walk).  fs_dir_open had the identical leak (FindFirstFileA search handle, FindClose path).
Fix: on handle_alloc==0, CloseHandle (fs_open) / FindClose + clear FS_FIND_PENDING (fs_dir_open)
-- the standard cleanup net_tcp_connect_ipv4 already does.  Byte-identical for the success path
(all 18 fs.iii consumers stay green, incl. 1471 the lifecycle KAT).

1504 teeth (constructible + observable): fill the 64-slot table with dummy handle_alloc calls
(handle_alloc is @export, does not validate cap_id), then fs_open an EXISTING file -- handle_alloc
fails so fs_open returns 0 on both libs, but the OS handle's fate differs: opened with FS_SHARE_RW
(no FILE_SHARE_DELETE), a LEAKED handle blocks deletion, so fs_delete returns FS_E_IO pre-fix (file
still locked) and FS_OK post-fix.  fs_dir_open's fix rides the identical structural argument (its
leak is harder to observe; the verifier itself found no teeth -- so 1504 falsifies the fs_open
representative and the sibling fix is byte-identical-for-success + structurally identical).

Gates: build GATE PASS FAIL=0; 1504 99 vs new / exit 4 vs old; only fs.iii changed, all 18 fs.iii
consumers + 1504 GREEN.  Count 1091 -> **1092**.

## Wave-15 — memo update bumps FIFO seq (data-structure contract violation) (2026-06-13)

A fresh-axis discovery whose survivor was a contract/implementation divergence in the resolve()
memoization cache: `memo_insert` (omnia/resolver_memo.iii) bumped MEMO_CURRENT_SEQ unconditionally
at the START of every call, and the update-existing branch then wrote that fresh (high) value into
the entry's MEMO_SEQ.  So re-storing an already-cached key advanced its sequence to "most recent"
-- contradicting the module's own contract ("update in place, same seq", line 156) AND resolver.iii's
HOT-path note ("memo_insert ... FIFO order stable", line 622).  Because MEMO_SEQ is the eviction key
(lowest seq evicted first), the bug makes a re-stored entry survive a later overflow that should have
spared an OLDER, un-touched entry instead -- and memo_seq() (documented "read insertion sequence")
returns a demonstrably wrong rank after any update.

**W15-FIX** (`omnia/resolver_memo.iii` memo_insert, falsifier `1505`, old exit=11): bump
MEMO_CURRENT_SEQ ONLY in the new-slot and eviction branches (true fresh insertions); the update
branch leaves MEMO_SEQ untouched.  PROVABLY ZERO production drift: the sole production caller
(resolver.iii:912) only inserts on a COLD miss -- it skips memo_insert entirely on a hit (line 622)
-- so it never exercises the update path, and for any distinct-key sequence the bump fires on every
call exactly as before -> byte-identical.  The defect is reachable only by a direct caller that
re-stores a key.  Existing memo KATs stay green: 202's update arm checks slot/used/pattern/fp but
not seq; its 256-key seq loop uses only distinct keys; 943's FIFO-eviction fill uses distinct keys.

1505 teeth (arm 6, clean + deterministic): insert A,B,C (seq 1,2,3), update A -> memo_seq(A) is 1 on
the fixed lib (original rank kept) but 4 on the pre-fix lib (bumped) -> arm 6 reddens the old lib
(exit 11).  Arms 16-21 then VERIFY the fix propagates to eviction: fill the 4096-slot table and
overflow by one; the victim is A (the genuine oldest, seq 1) so A is gone and B/C/D survive -- on
the pre-fix lib A would carry seq 4 and B (seq 2) would be the wrong victim.

Gates: build GATE PASS FAIL=0; 1505 99 vs new / exit 11 vs old; only resolver_memo.iii changed,
all 4 existing memo consumers (202/230/242/943) + 1505 GREEN.  Count 1092 -> **1093**.

## Wave-16 — huff_decode untrusted code-length OOB write (deserialization memory safety) (2026-06-13)

A fresh axis -- length-field over-read/over-write in decoders -- whose survivor was a real
out-of-bounds WRITE reachable from untrusted compressed input.  (The reusable structures on the
same hunt were CLEAN: queue_u32_pop/peek and pq_*_pop_min already empty-guard before the
decrement; crt.iii:142's `crt_rng() % bigp` is a self-test with a materialized local, not the
single-use-param modulo-after-call trap -- both refuted on read.)

**W16-FIX** (`numera/huffman.iii` huff_decode, falsifier `1506`, old exit=5): huff_decode reads the
256-byte canonical code-length header straight from the (untrusted) input -- `HF_LEN[s] = ip[s]`,
range 0..255 -- with NO bound check, then calls hf_canon().  hf_canon indexes the canonical decode
tables HF_BL/HF_NEXT/HF_FIRST/HF_OFF (all `[...; 65]`, valid lengths 1..64) BY those lengths
(`HF_BL[HF_LEN[s2]] += 1`; the `while bL <= maxl` first-code loop).  A stream with any length byte
> 64 drives maxl > 64 -> OOB WRITE past the 65-entry tables into the adjacent module BSS.  The
encoder is SAFE (it returns HF_E_LEN when the built max length ml > 64, so a legitimately-produced
stream never exceeds 64); the hole is reachable only on the decode side from input the encoder never
emits.  Fix: after the read loop, reject `HF_LEN[s] > 64` -> return HF_E_LEN (the exact mirror of
the encoder's own ml>64 guard), BEFORE hf_canon.  Byte-identical for every valid stream (lengths
<= 64 never trip the guard) -- 1230_huffman + 1231_lzh (LZ+Huffman, the transitive consumer) stay
green.

1506 teeth (GENTLE, exactly-one-past -- never a wild stomp, per the crash protocol): a 260-byte
header with a SINGLE length byte = 65 (one past max) and orig=0 (so the decode loop never runs).
Fixed lib -> HF_E_LEN (-1), validated before hf_canon, NO OOB.  Pre-fix lib -> hf_canon does
exactly-one-past writes (HF_BL[65]/HF_NEXT[65]/... land in the immediately-adjacent BSS var, no
crash -- confirmed: the old lib returns cleanly) and huff_decode returns orig=0; arm 4 asserts the
return is HF_E_LEN so the old lib (0) reddens (exit 5).  Arm 3 pins the boundary the other way
(length 64 ACCEPTED, return 0 -- guard not over-tight); arms 1-2 a real 4-symbol round-trip still
decodes byte-exact; arm 5 a far-past length (200) is likewise rejected.

Gates: build GATE PASS FAIL=0; 1506 99 vs new / exit 5 vs old; only huffman.iii changed, both
huffman consumers (1230_huffman + 1231_lzh) + 1506 GREEN.  Count 1093 -> **1094**.

## Wave-17 — eg_test_flip_bit node-index OOB write (the sibling the 1481 eg_find fix missed) (2026-06-13)

A SIBLING HUNT off the most recent commit (3eaf0634, which fixed an eg_find class-id OOB via
`a >= EGRAPH_MAX_CLASS -> SENT`): the recent fix guarded the CLASS-id path through eg_find, but the
NODE-index path had an identical unguarded @export.

**W17-FIX** (`numera/egraph.iii` eg_test_flip_bit, falsifier `1507`, old exit=3): eg_test_flip_bit
computed `nb = node_idx & EGRAPH_U32MASK` -- but EGRAPH_U32MASK is 0xFFFFFFFF, a 32-bit TRUNCATION
(the iiis high-bit-garbage dodge), NOT a bound -- then did `EGRAPH_N_SYM[nb] = EGRAPH_N_SYM[nb] ^ 1`.
EGRAPH_N_SYM has 131072 slots, so any node_idx >= 131072 is an OOB read+write into adjacent module
BSS, reachable through this @export with an attacker-supplied index.  Fix: `if nb >= EGRAPH_MAX_NODES
{ return -1 }` before the access -- the exact mirror of eg_find's guard.  Byte-identical for every
in-range caller (1435 + the internal RS-self-heal fixtures flip live nodes, indices 0/1/65 << 131072).

1507 teeth (GENTLE, exactly-one-past): eg_test_flip_bit(131072) is one slot past the array.  Fixed
lib -> -1 (guard fires, NO OOB).  Pre-fix lib -> writes EGRAPH_N_SYM[131072] (one u32 into the
adjacent BSS var, no crash -- confirmed clean exit 3) and returns 0.  Arm 3 asserts -1 so the old
lib (0) reddens.  Arm 2 pins the boundary the other way (131071, the LAST valid slot, accepted);
arm 1 a normal in-range flip; arm 4 a far-past index (reached only on the fixed lib -> -1, no OOB).

This is the WHY-IT-MATTERS of the sibling-hunt method: a freshly-fixed defect class (eg_find class-id
OOB) almost always has an un-fixed sibling on the adjacent code path (the node-index @export).  All
17 egraph consumers (incl. 1481 the dijkstra falsifier + 1435 the flip_bit user) stay byte-identical.

Gates: build GATE PASS FAIL=0; 1507 99 vs new / exit 3 vs old; only egraph.iii changed, all 17
egraph consumers + 1507 GREEN.  Count 1094 -> **1095**.

## Wave-18 — accessor-bounds OOB in heaplet / liveness / matrix_ring (the wave-11 sweep gap) (2026-06-13)

Found by a read-only discovery WORKFLOW (5 lenses, adversarially refuted: 13 confirmed of 17
examined, all in these 3 modules; the other lenses came back clean).  Wave-11's "exhaustive"
single-line accessor-bounds sweep covered the analysis modules but MISSED three separation-algebra /
dataflow / ring modules whose @export accessors index a fixed internal array by an unvalidated
caller index:
  - **heaplet** (8: hl_has/get/set/footprint/size/disjoint/union/equal): hl_alloc bounds the handle
    (h >= HL_POOL -> HL_NONE) but the accessors indexed HL_FP[256] / HL_VAL[16384] by the handle h
    checking only the CELL a, never h >= HL_POOL.  hl_set is an OOB WRITE.
  - **liveness** (3: lv_in/out/live_at_out): indexed LV_IN/LV_OUT ([u32;4]) by a block b with no
    b >= LV_N guard -- an OOB read.
  - **matrix_ring** (2: mat_set/get): indexed MAT_E ([u32;32]) by s*4+i with no s >= MAT_SLOTS guard.
    mat_set is an OOB WRITE.

**W18-FIX**: each @export accessor refuses an out-of-range index up front (set -> -1, get ->
zero/sentinel), the wave-9/10/11 convention.  Byte-identical for every in-range caller (sep_logic /
csl / reg_alloc / the three module KATs all pass unchanged).

Combined falsifier 1508 (wave-11's 1502 shape -- SETTER teeth + getter pins): hl_set(HL_POOL,..) and
mat_set(MAT_SLOTS,..) each return -1 on the fixed lib and 0 on the pre-fix lib (after a bounded
1-past write) -- the heaplet setter reddens the fully-pre-fix lib (exit 20, verified), the matrix
setter additionally pins the matrix guard against a matrix-only regression.  The liveness getters
(and every getter) are PINNED on the fixed lib: their gentle 1-past READ is benign-VALUED (adjacent
BSS reads 0, verified) so they carry no value-differential of their own -- exactly the setter-teeth/
getter-pin asymmetry 1502 already used for the OOB-read getters.  Arms 1-11 pin the valid in-range
fixpoint (incl. heaplet's separation laws, the liveness {x,y}/{x,z} dataflow values, matrix slot 7).

Gates: build GATE PASS FAIL=0; 1508 99 vs new / exit 20 vs old; only heaplet/liveness/matrix_ring
changed, all 10 consumers (direct KATs + sep_logic/csl/reg_alloc/reg_alloc_liveness/transform_taint_
seal/1502) + 1508 GREEN.  Count 1095 -> **1096**.
