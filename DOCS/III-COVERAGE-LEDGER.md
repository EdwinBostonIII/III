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
