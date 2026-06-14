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

## Wave-19 — accessor-bounds OOB in bv_bits / omega_engine / sep_logic / csl (more sweep gaps) (2026-06-13)

Found by a directory-partitioned tree-wide @export accessor RE-sweep (6 slices) + a sibling-of-
recent-fix lens (15 confirmed of 15 examined, all real -- ALL in numera/; the omnia/aether/nous/
sanctus slices came back clean).  The sibling lens specifically caught sep_logic + csl -- the wave-18
CONSUMERS had their OWN unguarded accessors (the method law: a fixed module's neighbours carry the
same bug).  14 accessors guarded across 4 modules:
  - **bv_bits** (9: bb_and/or/xor/not/shl/shr/add/sub/mul): took node ids a/b and called
    bb_bit(a,i) = BB_BITVAR[a*64+i] (BB_BITVAR[8192], BB_MAX_NODES=128) with no a/b >= BB_MAX_NODES
    guard -- bb_node_alloc bounds the NEW node, never the operands.  Guard -> BB_SENT + BB_ERR.
  - **omega_engine** (omega_mem): read OMEGA_MEM[16] by an unvalidated x.  Guard -> 0.
  - **sep_logic** (sl_footprint/sl_sat): indexed SL_KIND/SL_A/SL_B[512] by an unvalidated node
    (sl_node bounds the internal counter, not the @export arg).  Guard -> 0.
  - **csl** (csl_set_a/csl_set_b): WROTE the 8-slot A_ / B_ op arrays by an unvalidated i -- OOB
    WRITE.  Guard -> -1.

Combined falsifier 1509 (setter-teeth + sentinel-teeth + read-pin): csl_set_a(8,..)/csl_set_b(8,..)
return -1 fixed / 0 pre-fix (after a bounded 1-past WRITE) -- T1 reddens the fully-pre-fix lib (exit
30).  bb_and(BB_MAX_NODES, n0) returns BB_SENT fixed / a fresh NODE id pre-fix -- a LAYOUT-INDEPENDENT
sentinel differential (the op returns its error sentinel; the incidental OOB read of BB_BITVAR[8192..]
is bounded) -- T3 + the bb_or/xor/not/shl/shr/add/sub/mul pins protect the bv_bits guards against a
bv_bits-only regression.  The omega/sep_logic getters are PINNED (benign-valued 1-past read).  Arms
1-7 pin valid in-range use (a real bb_and node, sl_pt's footprint 1<<3, csl slots 0/7).

NOTE -- the bv_bits SENTINEL teeth is a new shape: an OOB-READ accessor that returns a distinct ERROR
SENTINEL on guard (vs a computed result pre-fix) IS falsifiable even when the read value is benign,
because the differential is the sentinel, not the read.  (liveness/omega/sep_logic getters return the
read value directly, so they stay benign-pinned.)

Gates: build GATE PASS FAIL=0; 1509 99 vs new / exit 30 vs old; only bv_bits/omega_engine/sep_logic/
csl changed, 12 representative consumers (4 module KATs + bv_dispose/cg_autocatalyst/bvd_rule_gate/
mixed_dispose/transform_taint_seal/gate_outcomes_bv_dispose) + 1509 GREEN.  Count 1096 -> **1097**.

## Wave-20 — temporal_logic tl_trace_set/holds BYTE-INDEX OOB (a new sub-class) (2026-06-13)

A finer numera re-sweep + sibling lens (2 confirmed of 6 examined -- the yield is dropping as numera
saturates).  ONE real find (temporal_logic); the other candidate (ripple_search rs_strict_best) was a
WORKFLOW FALSE POSITIVE -- refuted on read: rs_add bounds RS_N to RS_MAX(4096), so rs_argmax passes
count<=4096 to tb_max_by_u64 and the returned index is always < 4096, making RS_V[b] in-bounds (the
fn's own line-44 comment "best < n <= 4096" confirms it).  verify-still-open caught it.

**W20-FIX** (`numera/temporal_logic.iii` tl_val_set + tl_val_get, falsifier `1510`, old exit=5): the
LTL explicit-trace accessors tl_trace_set(atom,pos)->tl_val_set (WRITE) and tl_trace_holds(node,pos)->
tl_val_get (READ -- the method-law sibling) compute idx = s*TLOGIC_MAX_SEG+p and access TL_VAL through
a BYTE pointer ((&TL_VAL as u64 + idx) as *u8; bp[0]).  TL_VAL is [u64;524288] = 4194304 BYTES, so the
bound is the array's BYTE size TLOGIC_MAX_SUBF*TLOGIC_MAX_SEG (=1024*4096=4194304), NOT its element
count -- a NEW sub-class (byte-pointer addressing of a typed array).  Neither accessor checked it; the
@export trace API took untrusted s/p.  Fix: idx >= TLOGIC_MAX_SUBF*TLOGIC_MAX_SEG -> set -1, get 0.
Byte-identical for the internal LTL evaluator (always in-range s<1024, p<4096).

1510 teeth (clean WRITE, gentle exactly-1-past BYTE): tl_trace_set(TLOGIC_MAX_SUBF,0,1) -> idx=4194304
= one byte past.  Fixed -> -1 (NO OOB); pre-fix -> writes byte 4194304 (one byte into adjacent BSS,
no crash) + returns 0 -> arm 5 reddens the old lib (exit 5).  Arm 1 a real round-trip; arm 2 the LAST
valid byte (idx 4194303 = (1023,4095), accepted -> not over-tight); arm 4 pins the read sibling.

Gates: build GATE PASS FAIL=0; 1510 99 vs new / exit 5 vs old; only temporal_logic.iii changed, 10
representative consumers (temporal KAT + constitution/constitution_preserver/constitution_holds/
cons_run_charter/hotstuff/hotstuff_safety/hotstuff_liveness/gate_outcomes_constitution_preserver) +
1510 GREEN.  Count 1097 -> **1098**.

## Wave-21 — governance_vote missing terminal-state guard (a state-machine invariant gap) (2026-06-13)

THE PIVOT PAID OFF: after the memory-safety + arithmetic-correctness axes saturated (W21-byte-ptr=0,
W22-correctness=0 real), a fresh PROTOCOL-INVARIANT discovery (5 lifecycle lenses: governance/sandbox-
cap/resource/federation/intent, hunting "an illegal state transition wrongly ACCEPTED") found a real
state-machine gap on its first run.

**W21-FIX** (`omnia/governance.iii` governance_vote, falsifier `1511`, old exit=30): every governance
transition checks its exact precondition state -- sandbox requires PENDING, prove requires SANDBOXED,
promote requires PROVEN, seal requires ACCEPTED -- EXCEPT governance_vote, which checked only the slot
id, then incremented the tally and returned GOV_OK for ANY state.  So a vote on a PENDING/SANDBOXED
proposal (premature, before the proof) or on an ACCEPTED/REJECTED/SEALED proposal (closed, after
promotion) was wrongly accepted, mutating the tally of a terminal proposal.  Fix: GOV_STATUS[s] !=
GOV_PROVEN -> GOV_E_BAD_STATE before the tally (PROVEN is the voting window: prove -> [vote*] ->
promote).  Byte-identical for every legitimate vote -- 205 + 1474 both vote ONLY in PROVEN, never after
promote (verified by reading both).

1511 teeth (clean state differential): arm 3 votes on a PENDING proposal -> fixed GOV_E_BAD_STATE (-3)
/ pre-fix GOV_OK (0) -> reddens (exit 30).  Arm 1-2 prove a legitimate PROVEN vote still tallies (guard
not over-tight, with the resolution_init()+governance_reset() setup the proof-cert needs); arm 4-5 pin
the TERMINAL wall (after promote drives the proposal to REJECTED, a further vote is refused).

Note: the same W23 run flagged sandbox_exec use-after-drop and a region/bigint cross-arena reuse; those
are triaged separately (the region/bigint one is likely the DOCUMENTED arena-ABA caller contract --
the arena WITNESS guards realloc, not a plain reset; refuted-on-read like the ripple_search/R029 FPs).

Gates: build GATE PASS FAIL=0; 1511 99 vs new / exit 30 vs old; only governance.iii changed, all 7
governance consumers (205/1474/1456/1402/206/229) + 1511 GREEN.  Count 1098 -> **1099**.

## Wave-22 — use-before-init: *_to_mont cold-call + hotstuff false-safety (a FRESH, rich axis) (2026-06-13)

After the protocol axis thinned, a USE-BEFORE-INIT discovery (the fe25519 fz_invert class, generalized:
an @export reads an init-only global with no lazy guard -> WRONG cold result) found a rich coherent
vein -- proving the bug supply was not exhausted, just the axes I'd tried.

**W22-FIX** (fp256/fn256/fp384/fn384 *_to_mont + *_from_mont, hotstuff x2; falsifiers 1512+1513):
  - The Montgomery conversion entries *_to_mont read the init-only R^2 table (FP_R2/FN_R2/FQ_R2/GN_R2,
    populated only by *_init), and *_from_mont call *_mul (init-only modulus/n').  The *_inv siblings
    ALREADY guard with *_init() -- the to_mont/from_mont entries did not (a sibling gap, like wave-10's
    384/256).  COLD (before *_boot / fresh process), R^2=0 so to_mont(a) = a*0 = 0 instead of a*R.  Fix:
    *_init() (idempotent) at the top of each, matching *_inv.  Guarded the O(1) conversion ENTRIES, NOT
    the hot internal *_mul (which fp_inv/ec scalar-mult loop -- a per-mul init-check would tax the
    hottest crypto path; the conversion entries are O(1) per operation).
  - hotstuff hs_quorum_safety_verify (reads HS_FAULT) + hs_verify_vote_count_bounds (reads HS_PEER_COUNT)
    omitted the HS_INITED check that every OTHER hs @export has.  COLD they read 0 and bq_safe(0)==1
    FALSELY ASSERTS Byzantine safety for an unconfigured engine (verified: 1513 old exit 30 -> cold
    returns 1).  Fix: HS_INITED==0 -> return 0 (not verified).

1512 teeth (cold differential): set slot1=1, to_mont into slot0 WITHOUT booting, check the low limbs of
the result are not all 0 (the Montgomery form of 1 is R, nonzero).  Fixed -> lazy-init -> R; pre-fix ->
R^2=0 -> 0 -> arm 1 (fp256) reddens (exit 30).  Arms 2-4 pin/protect the fn256/fp384/fn384 siblings
(each module has its own init flag -> each conversion is independently cold).  1513 teeth: cold
hs_quorum_safety_verify -> fixed 0 / pre-fix 1 (false safety) -> exit 30; arms 3-5 pin the configured
path (hs_init 4 peers -> both verdicts 1, byte-identical).

Byte-identical for every inited caller (ec256/ec384/ecdsa_p256/ecdsa_p384 + 760_field_mont_organ +
1401_field_curve_vault + the hotstuff safety KAT all boot first).

Gates: build GATE PASS FAIL=0; 1512 99/exit30, 1513 99/exit30 vs old; only the 5 modules changed, 11
representative consumers (field_mont_organ/field_curve_vault/field256_accessor_bounds/383_hotstuff/
hotstuff_safety/liveness/fed_qc_gate/seal_quorum/federation_admit) + 1512 + 1513 GREEN.  Count 1099 ->
**1101**.

## Wave-23 — scalar-field reduce cold-init (fn_reduce/gn_reduce); the W22 completion + caller-decides-scope (2026-06-13)

A round-2 init-order discovery (sibling-of-W22 lens) proved W22 was scoped too narrowly: the OTHER
modular @exports in fp256/fn256/fp384/fn384 (mul/add/sub/reduce) also read the init-only modulus/order
cold.  But the SCOPE is decided by the CALLER, not the finding:

  - **fn256 fn_reduce / fn384 gn_reduce** -- read the curve order FN_N/GN_N (init-only).  A reduce is a
    NATURAL cold FIRST call: a caller reduces a raw scalar mod n with NO to_mont before it (ecdsa's r,s).
    Cold the order reads 0, so the conditional-subtract takes "x - 0 = x" -> NO reduction -> a residue
    >= n is returned (a wrong/forgeable signature scalar).  O(1) per use (one reduce per signature), and
    the worker has ZERO internal callers (only the _x wrapper) -> FIX: idempotent fn256_init()/fn384_init()
    at the top of the worker.  Sole in-tree callers ecdsa_p256/ecdsa_p384 already fn256_boot() first
    (line 52/…), so the guard is a no-op there and protective for every other caller.

  - **fp_mul/add/sub + fn/fq/gn mul/add/sub (the hot primitives) -- DELIBERATELY NOT guarded.**  ec256
    boots the field (fp256_boot at ec256.iii:40) BEFORE its scalar-mult loop, and an external caller
    reaches them only AFTER to_mont (W22 made to_mont auto-init).  So they are always reached WARM; a
    per-mul init-check would be pure tax on the hottest crypto path for a state that cannot occur.  The
    caller decides the scope: guard the O(1) entries reachable cold-first (to_mont/from_mont/reduce), not
    the warm hot primitives.

1514 teeth (all-FF differential): set slot0 = all-FF (= 2^k-1, which lies in [n, 2n) so ONE csub yields
the canonical residue), reduce COLD, read limb0.  Pre-fix order=0 -> no subtract -> limb0 stays
0xFFFFFFFF -> arm 1 (fn256) reddens (verified exit 30 vs the pre-W23 lib).  Post-fix limb0 = 0xFFFFFFFF
- n[0] = 0x039CDAAE (fn256) / 0x333AD68C (fn384).  Arms 3-4 re-pin the exact residue after an explicit
boot (both libs agree).

Byte-identical for ecdsa_p256/ecdsa_p384 (both boot the scalar field before any reduce).

Gates: build GATE PASS FAIL=0; 1514 teeth exit 30 vs old lib, 99 vs new; only fn256/fn384 changed.
Count 1101 -> **1102**.  The init-order axis is now SATURATED for the field/curve modules
(to_mont/from_mont W22 + reduce W23 done; hot primitives principled-skip; precomputed-tables and
other-curve lenses came up dry) -> the next wave switches axis.

## Wave-24 — bigint_new cap*8 u64-overflow guard (a FRESH axis: integer-overflow in size math) (2026-06-13)

Init-order saturated -> switched the discovery axis to integer-overflow / error-swallow / off-by-one /
signed-sentinel.  One real find of three confirmed (the ~2/3 false-positive rate held).

**W24-FIX** (bigint.iii bigint_new; falsifier 1515): the backing byte size is computed as `cap_limbs *
8u64` (line 147) with NO overflow check.  For cap_limbs >= 2^61 the product WRAPS mod 2^64 --
0x2000000000000001 * 8 = 0x10000000000000008 -> low64 = 0x8.  arena_alloc1 then returns a real 8-byte
block (the `p == 0` guard at line 148 passes), and the zero-init loop `while i < cap` (line 151) runs
~2^61 iterations writing 8 bytes each FAR past the 8-byte block -> a massive OOB write (heap corruption
+ crash).  FIX: `if cap > 0x1FFFFFFFFFFFFFFFu64 { return BIGINT_INVALID }` before allocating
(0x1FFFFFFFFFFFFFFF * 8 = 0xFFFFFFFFFFFFFFF8 is the largest non-wrapping product).

1515 teeth (crash-class -- the standard falsifier for a memory-safety guard): a small 16KB arena, then
bigint_new(arena, 0x2000000000000001).  Pre-fix the wrapped 8-byte alloc + OOB zero-loop SEGFAULTS
within a few thousand writes -> exit 139 (verified vs the pre-W24 lib).  Post-fix the overflow guard
returns BIGINT_INVALID (0) before allocating -> the arm sees bad==0 and continues -> exit 99.  Arm 2
pins the wrap-to-zero boundary (cap=0x2000000000000000, also rejected); the sanity arm proves a normal
small cap still allocates (guard not over-tight).  Contained userland probe, not a kernel crash.

W27 triage (read-only Explore fan-out): (1) this = real.  (2) irreducibility_proof off-by-one =
FALSE POSITIVE (the verifier read a stale "18*18=324" comment; calculus_primitive_count()=19 is the
source of truth, the code loops 1..19 correctly) -- fixed the 4 stale comments to 19*19=361 in a
separate doc commit; the code was always right.  (3) mldsa iii_mldsa_verify swallowing keccak_absorb's
KK_E_NULL = DECLINED (latent NULL-precondition on load-bearing PQ crypto; document-and-separate).

Gates: build GATE PASS FAIL=0; 1515 teeth exit 139 vs old lib, 99 vs new; only bigint.iii changed
(+ the irreducibility_proof.iii comment-only doc commit).  Count 1102 -> **1103**.

## Wave-25 — option double-free + threshold_vault kkey OOB (fresh axes 2: double-free + missing-validation) (2026-06-13)

W28 (double-free/UAF / TOCTOU / aliasing / error-swallow round 2) surfaced a rich vein; the two with
the cleanest GENTLE teeth land here, the rest queue.

**W25-FIX-A REFUTED by the corpus gate (a FALSE POSITIVE I implemented, then reverted).**  W28 flagged
option_u64_drop returning 1u8 unconditionally (no LIVE re-check, unlike is_some/unwrap_or) as a double-
free.  I implemented `if OPT_U64_LIVE[si]==0u8 { return 0u8 }` + falsifier 1516 (teeth proven 30->99) --
but the full corpus REDDENED: 1417_option_path_pq_prov exit 8.  Line 64 of 1417 is `if option_u64_drop(o1)
!= 1u8 { return 8 }  /* drop is IDEMPOTENT on valid handles */`, and the header says "drop is drop-once".
The unconditional 1u8 is the DOCUMENTED, contract-tested semantics: the return signals handle VALIDITY
(none/FULL/out-of-range -> 0; any valid slot handle -> 1, safe to call twice), NOT liveness -- the slot is
cleared once (drop-once) but a re-drop of a valid handle still returns 1.  My sibling-gap reasoning was
wrong: is_some/unwrap_or guard LIVE because they answer "is there a live VALUE?"; drop answers "is this a
valid HANDLE?".  REVERTED option.iii; deleted 1516.  **LESSON: before "fixing" a missing guard, grep the
existing corpus for that function -- a contract test encodes the INTENDED behavior.**  (W22-24 + the
threshold_vault fix were all corpus-validated; only this one violated a contract -- the gate is why.)

**W25-FIX-B** (numera/threshold_vault.iii tv_seal + tv_open; falsifier 1517): tv_seal validates nkey
(line 73) but NOT kkey, and stores kkey into TV_PN[2] (line 76) BEFORE shamir_split (line 88) can fail.
tv_open reads that kkey as a loop bound (`while t < kkey`) and writes TV_PKXS[t] (a [u8;16]) + TV_PKS[
t*32+b] (a [u8;512]) -- a stored kkey of 100 writes TV_PKXS[0..99]/TV_PKS[0..3199], corrupting adjacent
globals (reachable via a caller that ignores tv_seal's failure and calls tv_open, since the bad kkey
persists on a failed seal).  FIX: `if kkey > TV_MAX_NK { return TV_E_DIM }` in tv_seal (before storing
TV_PN) + the same defensive recheck at the top of tv_open.  1517 teeth (GENTLE -- no OOB triggered):
tv_seal(kkey=100) pre-fix stores it then shamir(thr=100>n=16) fails -> TV_E_SUB(-3); post-fix the guard
returns TV_E_DIM(-1) -> arm 1 asserts -1, the pre-fix -3 reddens (exit 30).  Arm 2 (kkey=16==TV_MAX_NK)
proves the guard is not over-tight.

W25-FIX-B has a clean VALUE-differential teeth at the ENTRY (no crash, no OOB triggered) -- prove the
guard rejects the dangerous input before the unsafe code downstream runs.  Lands as ONE commit (only
threshold_vault.iii; the option half was reverted as a false positive).

W28 remaining (queued for W26+, pending verification): error-swallow trio fed_seal_compute_chain_root /
reach_emit / wh_compute_frag_id (discard mhash/cad/backend i32 returns -> report success on a corrupted
seal -- need failure-inducibility check); identifier ident_copy forward-copy aliasing (need an in-tree
aliased caller, else it's a must-not-alias contract).

Gates: build GATE PASS FAIL=0; 1517 teeth exit 30 vs old lib, 99 vs new; the option false-positive caught
by 1417 (the gate doing its job) and reverted.  Count 1103 -> **1104** (only 1517 added).

## Wave-26 — crt_solve zero-modulus + rn_graph_root cell-count overflow (W29 missing-validation vein) (2026-06-13)

W29 (div/mod-by-zero / unchecked count->loop / unsigned-underflow / capacity-overflow) found 3; 2 land,
es_reconstruct declined.  Both fixes CONTRACT-PRE-CHECKED first (the option lesson): grep the existing
corpus + in-tree callers before guarding.

**W26-FIX-A** (numera/crt.iii crt_solve; falsifier 1518): crt_solve validates each modulus `>= CRT_2P32
-> reject` (lines 70, 76) but NOT `== 0`.  A zero modulus reaches a `%`/`/`: line 71 `rp[0] % mp[0]`
traps (SIGFPE) when mp[0]=0; the loop's line 77 `bigp > (CRT_U64MAX / mi)` traps when mi=0.  FIX: reject
`== 0` alongside the too-large check (both the head modulus and the loop modulus).  Pre-check: NO corpus
test calls crt_solve; the only in-tree callers are crt's own self-test (lines 149/163) with nonzero RSA-CRT
moduli -> guard is a no-op for them.  1518 teeth: mp[0]=0 -> pre-fix SIGFPE (exit 127, process dies);
post-fix CRT_E_DIM(-1).  Arm 2 = loop modulus zero; arm 3 = valid coprime moduli not rejected.

**W26-FIX-B** (forcefield/ripple.iii rn_graph_root; falsifier 1519): the "holographic root" hashes
`ncells * 32u64` bytes with no range check.  For ncells >= 2^59 the product WRAPS mod 2^64
(0x0800000000000001*32 -> 0x20), so rn_hash commits to only 32 bytes -- the root silently collapses to
the hash of one cell and different address lists collide (integrity break).  FIX: `if ncells >
0x07FFFFFFFFFFFFFFu64 { return RN_GAP }` before hashing.  Pre-check: corpus 837 + ripple_journal call it
with ncells=6 / RJ_N[0] (small) -> guard is a no-op.  1519 teeth (GENTLE value differential): pre-fix
returns 0 (RN_OK) with a truncated root -> arm asserts RN_GAP, the 0 reddens (exit 30); post-fix RN_GAP.

es_reconstruct DECLINED: es_encode validates `k > ES_MAX_K` (line 87) BEFORE storing ES_PN[1] (line 91)
-- validate-then-store, so ES_PN[1]<=16 always; the missing guard is unfalsifiable defense-in-depth (the
discriminator vs threshold_vault's store-then-validate, which WAS reachable).

Gates: build GATE PASS FAIL=0; 1518 teeth exit 127 vs old lib, 1519 exit 30 vs old lib, both 99 vs new.
Count 1104 -> **1106**.

## Wave-27 — rms_ceil_div + sf_rou div-by-zero, temporal_logic s*4096 overflow (W30; a W20 completion) (2026-06-13)

W30 (store-then-validate / div-by-zero-2 / unsigned-underflow / capacity-overflow) found 3, all
landing.  Each contract-pre-checked (existing KATs use safe inputs -> guards are no-ops).

**W27-FIX-A** (numera/rms.iii rms_ceil_div; 1520): `((a+b)-1)/b` @export with no b==0 guard -> SIGFPE.
FIX `if b == 0u32 { return 0u32 }`.  KAT (rms_kat) tests divisor 4 only; internal callers pass RMS_T
{4,6,8}.  1520 teeth: rms_ceil_div(5,0) SIGFPE(127) -> 0.

**W27-FIX-B** (numera/ntt_fri_organ.iii sf_rou; 1521): `frm_pow(3, 998244352 / n, p)` @export with no
n==0 guard -> SIGFPE.  FIX `if n == 0u32 { return 1u32 }` (0th root of unity undefined -> identity).
Selftest uses powers of 2; zk_stark/zk_air callers use AIR_N/AIR_B (nonzero).  1521 teeth: sf_rou(0)
SIGFPE(127) -> 1.

**W27-FIX-C** (numera/temporal_logic.iii tl_val_set + tl_val_get; 1522) -- a W20 COMPLETION.  W20 added
the byte-bound guard `idx >= MAX_SUBF*MAX_SEG` on idx = s*TLOGIC_MAX_SEG + p.  But `s * TLOGIC_MAX_SEG`
WRAPS u64 for huge s (0x10000000000001*4096 -> 4096), so a nonsense s yields a SMALL idx that PASSES the
W20 guard and writes/reads a wrong-but-in-range slot.  FIX: bound s and p BEFORE the multiply (the true
contract s<MAX_SUBF, p<MAX_SEG) in both accessors.  tl_kat callers use s in {0,1,2}, p<8.  1522 teeth
(GENTLE): tl_trace_set(huge_s,0,1) pre-fix writes the wrapped slot + returns 0 -> arm asserts -1, the 0
reddens (exit 30); post-fix -1.  Same lesson as W23/W24/W25: validate the INPUTS, not the derived
quantity -- a guard placed AFTER an overflowing computation is structurally blind.

Gates: build GATE PASS FAIL=0; 1520/1521 teeth exit 127 vs old lib, 1522 exit 30, all 99 vs new.
Count 1106 -> **1109**.

## Wave-28 — governance_drop ACCEPTED-state guard + csl_lens count-bound (W32 fresh axes; NOT saturated) (2026-06-13)

W31 was all-declined (its leak cluster was UNREACHABLE), but W32's FRESH lenses (state-machine /
paired-validation / inducible-error-swallow, with a `reachable_via_api` gate) found 3 reachable -- the
"switch the axis" method holds.  2 land; pattern_template_set_id declined.

**W28-FIX-A** (omnia/governance.iii governance_drop; 1523) -- a W21 sibling.  governance_drop erases a
proposal slot after only an id check -- NO GOV_STATUS gate, unlike every peer (sandbox/vote/promote/seal).
The header contract (line 9) is "every promotion is sealed": an ACCEPTED(3) proposal MUST be
governance_seal'd (-> SEALED(5), witness emitted) before its slot is freed; dropping it un-sealed loses
the promotion with no witness.  FIX: `if GOV_STATUS[s] == GOV_ACCEPTED { return GOV_E_BAD_STATE }`.
Reachable: propose->sandbox->prove->vote(4y/1n)->promote->drop.  1523 teeth (GENTLE): drop on ACCEPTED
pre-fix returns 0 + erases -> arm asserts -3, the 0 reddens (exit 30); post-fix -3, proposal stays
ACCEPTED, and seal-then-drop still works (SEALED is droppable -- guard is ACCEPTED-specific).  205/1402
drop only PENDING/SEALED -> unaffected.

**W28-FIX-B** (numera/csl.iii csl_lens + csl_footprints_disjoint; 1524) -- a W19 sibling.  csl_lens(na,nb)
stores the counts with NO bound, and csl_footprints_disjoint loops `while i<na { hl_set(ha, A_CELL[i]..) }`
over A_CELL/B_CELL[8] -> a count of 100 OOB-reads the cell arrays.  csl_set_a/csl_set_b already guard
`i>=8` (W19); the COUNT path did not.  FIX: `if na>8 / nb>8 { return -1 }` in csl_lens + a defensive guard
in csl_footprints_disjoint.  1524 teeth (GENTLE): csl_lens(100,50) pre-fix stores it + returns 0 -> arm
asserts -1, the 0 reddens (exit 30); post-fix -1; boundary na=nb=8 accepted (not over-tight).  Existing
csl tests use na/nb<=4 -> unaffected.

pattern_template_set_id DECLINED: its mhash_payload error-swallow only triggers on symbol_name=0 (NULL)
with name_len>0 -- a contract-violating NULL+len no real caller passes (the mldsa NULL-pk decline class).

Gates: build GATE PASS FAIL=0; 1523/1524 teeth exit 30 vs old lib, 99 vs new.  Count 1109 -> **1111**.

## Wave-29 — cad cross-module-init error-swallow: a silently-wrong digest when un-begun (W35) (2026-06-13)

After 3/4 dry rounds (W31/33/34), W35's fresh axes (stale-buffer / cross-module-init / narrow-int) still
hit 2 reachable -- the supply thins but isn't gone.  1 lands; nl_parse deferred.

**W29-FIX** (numera/cad.iii cad_payload + cad_domain + cad_final; falsifier 1525): cad_begin(suite) records
CAD_ACTIVE and inits the backend.  But `var CAD_ACTIVE = 0` COINCIDES with `CAD_SUITE_SHA256 = 0`, so a
cad_payload called WITHOUT cad_begin (fresh process) takes the SHA256 branch and calls
sha256_dispatch_update on an UN-INIT'd backend, which DETECTS it (SHA_INIT==0 -> returns 1) -- but cad
SWALLOWED the return and reported CAD_OK, computing a silently-WRONG (empty) digest.  An INTEGRITY bug: a
seal/witness/content-address that commits to the wrong data but reports success (reachable cold via e.g.
zk_proof_seal_absorb without zk_proof_seal_begin).  FIX: propagate the sha256 backend return as
CAD_E_BAD_SUITE in all three SHA256 branches.  Byte-identical for BEGUN callers (SHA_INIT==1 -> backend
returns 0 -> CAD_OK) -- which is why the load-bearing mhash->cad->everything path stays green.

A standalone probe (cold cad_payload+final -> OUT) CONFIRMED sha256 is genuinely COLD at a corpus-test
entry (the side-effect objects do not warm it) -- so the teeth is feasible: 1525 cold cad_payload pre-fix
returns CAD_OK (exit 30) / post-fix CAD_E_BAD_SUITE; arms 3-6 pin the begun cycle + a NONZERO digest.

nl_parse _np_pack_rhq DEFERRED (real: head-token index masked `& 0xFFFF` where the record spec is u32 ->
indices > 65535 truncate; fix trivial `0xFFFFFFFF`, but the teeth needs a 65536+-token parse + grammar
knowledge -- revisit when constructible).

Gates: build GATE PASS FAIL=0; 1525 teeth exit 30 vs old lib, 99 vs new; corpus (the load-bearing gate --
many mhash/seal/witness tests) green.  Count 1111 -> **1112**.

## Wave-30 — merkle_tree_build_u32 power-of-2 precondition guard (silent wrong root) (W36) (2026-06-13)

W36 (cad-inspired zero-flag-collision / cross-module-init-2 / tree-index) found 1: a merkle tree-index bug.

**W30-FIX** (numera/merkle.iii merkle_tree_build_u32; falsifier 1526): the builder is documented "n a power
of two" (line 374/391) but does NOT enforce it.  Its 1-indexed tree-index math (node i -> children 2i/2i+1,
leaf i at node n+i) is correct ONLY for a power-of-two leaf count; for n=3 it computes node2=hash(L1,L2)
then node1=hash(node2, L0) -- mixing a RAW leaf with a parent hash -> a WRONG merkle root, returned MK_OK.
An integrity bug (a commitment to the wrong tree shape, reported success), reachable via the @export with a
plausible non-power-of-2 count.  The general sibling merkle_compute_root DUPLICATES the last leaf on odd
counts (lines 148/240) -- so build is the power-of-2-only fast path, compute the general one.  FIX: enforce
build's documented precondition -- reject n==0 and (n & (n-1))!=0 with MK_E_BADLEN.  (Enforce the contract,
NOT extend it -- duplication is compute's job.)  In-tree callers (ntt_fri_organ/zk_air/zk_stark/1003) all
use power-of-2 (STARK/FRI domains, n=8) -> byte-identical.  1526 teeth: n=3/6/0 pre-fix MK_OK -> reddens
(exit 30) / post-fix MK_E_BADLEN; sanity n=8/4/1 still build (guard not over-tight).

Gates: build GATE PASS FAIL=0; 1526 teeth exit 30 vs old lib, 99 vs new; corpus green (zk-STARK/merkle
load-bearing).  Count 1112 -> **1113**.

## Wave-31 — ad_aligned non-power-of-2 width: bitmask != modulo (W39; the W30 pattern again) (2026-06-13)

W37 dry, W38 deferred (vacuous), but W39's documented-precondition lens (the merkle vein) hit again.

**W31-FIX** (numera/align_domain.iii ad_aligned; falsifier 1527): ad_aligned(x,w) computes `(x & (w-1))
== 0`.  Its doc is "is x aligned to width w?  (x mod w == 0, via mask since w is a power of two)" -- so the
STATED semantics is x mod w == 0, and the mask is a power-of-2 optimization.  For a non-power-of-2 w the
mask is WRONG (a real, non-vacuous wrong boolean BOTH ways): ad_aligned(1,3) -> (1&2)=0 -> 1 (aligned) but
1 mod 3 = 1; ad_aligned(6,3) -> (6&2)=2 -> 0 (not aligned) but 6 mod 3 = 0.  Reachable @export.  FIX: honor
the stated modulo semantics -- use real `x % w` for a non-power-of-2 w; keep the bitmask fast path for
power-of-2 (and w==0/1/2 stay on it -> the modulo path only runs for w>=3 -> no div-by-zero).  NOT a
contract extension -- the doc already says "x mod w == 0".  In-tree callers (align_domain:52/53) pass a
power-of-2 w from ad_max_vector_width (the SIMD width = lowest set bit of gcd) -> byte-identical.

1527 teeth: ad_aligned(1,3)!=0 (pre-fix 1 -> exit 30) + ad_aligned(6,3)!=1 (pre-fix 0); sanity 8/4, 5/4,
0/8, 3/1 on the unchanged power-of-2 path.

**SIBLING (same commit): vectorizer.iii vz_covers** -- a targeted grep `& \(X - 1\)` for the same bitmask-
modulo pattern found vz_covers(n,w) "n is a multiple of the width W (W power of two)" with the IDENTICAL
`(n & (w-1)) == 0` bug.  Same fix (modulo for non-power-of-2 w); in-tree callers pass a power-of-2
ad_max_vector_width -> byte-identical.  Falsifier 1528 (vz_covers(1,3)!=0 / (6,3)!=1).  (The other grep
hits were correct power-of-2 CHECKS `(x & (x-1))==0` or STARK power-of-2 FRI domains -- not bugs.)

Gates: build GATE PASS FAIL=0; 1527 + 1528 teeth exit 30 vs old lib, 99 vs new; corpus green.  Count
1113 -> **1115**.

## Wave-32 — ad_loop_aligned_scan (the W31 miss) + bitio bitr_get OOB read (W40) (2026-06-13)

W40 (other-doc-precondition / unit-mismatch / sibling-disagreement) found 3; 2 land, 1 deferred.

**W32-FIX-A** (numera/align_domain.iii ad_loop_aligned_scan; falsifier 1529) -- a W31 COMPLETION.  W31's
grep EXCLUDED align_domain (I wrongly treated it as "done"), missing the THIRD bitmask-modulo instance:
the "ground truth" exhaustive scan tests `(base+i*stride) & (w-1)` unconditionally.  After W31 ad_loop_
aligned uses ad_aligned's modulo, so for a non-power-of-2 w the scan DISAGREED with its own sibling
(ad_loop_aligned(0,3,3)=1 but scan(0,3,3,3)=0 -- all of 0,3,6 are 3-aligned).  align_domain_kat only
exercises power-of-2 widths, so it never caught the divergence.  FIX: hoisted pow2-dispatch + real modulo
for non-power-of-2 (matches ad_aligned).  LESSON: do NOT exclude a module from the sibling-sweep grep just
because one of its functions was fixed -- sweep the WHOLE module.

**W32-FIX-B** (numera/bitio.iii bitr_get; falsifier 1530) -- a writer/reader bounds ASYMMETRY.  bitr_get
reads `bp[byte]` (byte = pos>>3) with NO `byte < BIO_RLEN` check, so requesting more bits than the
len-byte buffer holds reads OOB; the symmetric writer bitw guards `byte >= cap -> BIO_E_OVF` (line 54),
the reader did not.  FIX: `if byte >= BIO_RLEN[0] { return v }` (stop at the buffer end, return bits read
so far).  1530 teeth (controlled OOB byte): bitr_init(BUF,10) then bitr_get(81) -- bit 80 is in byte 10
(0xFF); pre-fix reads it -> v low bit 1 (exit 30) / post-fix stops -> 0.

rscode rs_decode_apply DEFERRED: a present_sym/present_idx ORDERING contract between two @exports
(rs_decode_prepare/apply); violating it corrupts data, but it is a caller-protocol precondition (the
fix is an API redesign or a cross-call order check) -- not a clean single-function teeth.  REVISIT.

Gates: build GATE PASS FAIL=0; 1529 + 1530 teeth exit 30 vs old lib, 99 vs new; corpus green (align_domain
KAT + bitio roundtrip).  Count 1115 -> **1117**.

## Wave-33 — ntt_forward_at/inverse_at power-of-2 guard (the last documented-pow2 precondition) (2026-06-13)

After W41 + W42 dry rounds on fresh axes, I converted the deferred ntt power-of-2 precondition (the last
merkle/W30-pattern instance) -- and on close reading it was a CLEAN fix, not the "complex" I'd assumed.

**W33-FIX** (numera/ntt.iii ntt_forward_at + ntt_inverse_at; falsifier 1531): both @exports are documented
"n must be a power of two" (line 296) but did not enforce it.  The radix-2 DIT butterfly
(`while len <= n { len <<= 1 }` + `w[i+k+half]`) is power-of-two-only: for n=3 it runs ONE stage (len=2)
and at i=2 reads/writes w[3] -- PAST the logical [0..n) range -> a WRONG NTT result AND it corrupts w[3..]
(adjacent NTT_W data), returning 0 (OK).  ntt_inverse_at calls forward_at but IGNORES its return, so it
needs its own guard.  FIX: reject n==0 and (n & (n-1))!=0 with -1 in both.  In-tree callers (zk-STARK,
poly-mult) use power-of-2 n -> byte-identical.  1531 teeth: ntt_forward/inverse(3/6/0) pre-fix run the
partial butterfly + return 0 (exit 30) / post-fix -1; sanity n=8/4/1 accepted.

(The tabled FIPS NTT family ntt_ct_forward_tabled/ntt_gs_inverse_tabled is a SEPARATE core -- n tied to a
caller zeta table, mlkem/mldsa use fixed pow2 n -- left for a separate wave with a tabled teeth.)

Gates: build GATE PASS FAIL=0; 1531 teeth exit 30 vs old lib, 99 vs new; corpus green (ntt_selftest +
zk-STARK pipeline).  Count 1117 -> **1118**.

## Wave-34 — tabled FIPS NTT (mlkem/mldsa) power-of-2 guard -- completes the NTT-family hardening (2026-06-13)

The W33 sibling on the OTHER NTT core: the tabled FIPS family (Kyber/Dilithium, post-quantum).

**W34-FIX** (numera/ntt.iii ntt_ct_forward_tabled + ntt_gs_inverse_tabled; falsifier 1532): same
documented-power-of-2 class.  The tabled CT/GS levels (len=n>>1 down to min_len / min_len up to n>>1) +
the per-block zeta-index advance are power-of-two-only; a non-pow2 n (e.g. 6) runs a len=3 level that
butterflies w[j+3] past [0..6) (w[6..8]) AND over-reads the zeta table -> wrong/OOB, returned 0.  FIX:
reject n==0 and (n & (n-1))!=0 with -1 at entry of both.  In-tree mlkem/mldsa use fixed pow2 n (256) ->
byte-identical.  1532 teeth (dummy zeta table + base[16], q=8380417 mldsa prime): ct/gs(6/0) pre-fix run
the wrong level + return 0 (exit 30) / post-fix -1; sanity n=8 accepted.

The NTT family is now FULLY power-of-2-guarded (DIT core W33 + tabled FIPS W34), and the documented-power-
of-2 vein is COMPLETE: merkle(W30), ad_aligned+vz_covers(W31), ad_loop_aligned_scan(W32), ntt DIT(W33),
ntt tabled(W34) -- plus the already-enforced ripple/ripple_dyn + fixed-pow2-const modules.

Gates: build GATE PASS FAIL=0; 1532 teeth exit 30 vs old lib, 99 vs new; corpus green (mlkem/mldsa
roundtrips).  Count 1118 -> **1119**.

## Wave-35 — reduced_product::rp_count empty-interval cardinality wrap (a FRESH axis: algebraic-law / corner-input oracles) (2026-06-13)

The documented-power-of-2 vein (W30-34) was mined to the floor, so the discovery AXIS switched from
guard-presence (~2/3 FP, each candidate needs a contract judgment) to **algebraic-law / round-trip oracles**
on the numerics core -- self-validating (a concrete law holds on a concrete corner input or it does not, no
judgment), so structurally near-zero FP.  Read-only Workflow w7fey1eqr fanned out over ~70 numera files
(6 groups: asym crypto / pq / bigint-field / ntt-zk / codes / dp-algo) on three angles -- law_or_roundtrip,
overflow_before_use, unenforced_precondition -- with an adversarial REFUTE stage.  6 raw candidates -> 1
confirmed; the 5 refuted were barrett (k=limbs(m) physically bounded, 2^57 corner unconstructable),
crt_modinv (documented [0,m) contract + the m=0 SIGFPE already pinned by 1518), gf_poly (len>=1 is the
representation invariant -> len-0 vacuous/unreachable), and fenwick x3 (uniform caller-honors-precondition,
contract-only delta = NOT a wrong-value defect).  The verifier independently re-derived the same
"vacuous / documented-contract / unreachable" triage my own prior notes had on crt + reduced_product.

**W35-FIX** (numera/reduced_product.iii rp_count; falsifier 1533): rp_count(lo,hi,p) is documented as
"the exact number of concrete values in [lo,hi] with parity p".  Its parity branches (RP_EVEN/RP_ODD)
collapse an EMPTY interval (lo>hi) to 0 via the `rlo > rhi` guard (line 57) -- and rp_reduce_hi's own
comment (line 48) RELIES on rp_count doing so.  But the RP_ANY branch (line 54) computed `(hi - lo) + 1u32`
with no `hi < lo` guard, so rp_count(10,5,RP_ANY) = (5-10)+1 in u32 = **4294967292** -- a wrong, ~4.29e9
cardinality (a caller sizing a loop/alloc from it over-runs).  A same-FUNCTION asymmetry, not a uniform
precondition: the tell of a real defect vs. a hardening nicety.  FIX: `if hi < lo { return 0u32 }` at the
top of rp_count -- unifies all three modes (parity branches already return 0 for lo>hi; this makes RP_ANY
consistent).  In-tree callers (the module KAT lines 97-98; sovereign_optimizer uses only rp_reduce_lo/hi)
all pass lo<=hi -> reduced_product_kat + 1272 + 1313 byte-unchanged.

1533 teeth (value differential): rp_count(10,5,RP_ANY) / (5,3,RP_ANY) pre-fix return 4294967292 / 4294967295
(exit 30) -> post-fix 0; sanity non-empty (RP_ANY=8, RP_EVEN=4, singleton=1) and empty-in-parity (=0,
already correct) unchanged.

Gates: build GATE PASS FAIL=0, all three ratchets OK; 1533 teeth exit 30 vs old lib, 99 vs new; corpus
green.  Count 1119 -> **1120**.

## Wave-36 — loop_optimizer empty-loop safety disagreement (the same-function-asymmetry lens extends to cross-witness disagreement) (2026-06-13)

W35's algebraic-law axis continued onto the numera groups it had not reached (symmetric crypto, compiler-opt
x2, proof-logic x2, deeper codes/dp/misc), with the **same-function-asymmetry** lens (the rp_count fingerprint)
promoted to highest priority + a WRONG-VALUE-not-contract-only hard gate to pre-filter the fenwick-class noise.
Read-only Workflow wp0kswzyq: 1 confirmed of 2 raw; the refuted one was shake256_oneshot (its NULL-with-len>0
"deref" is guarded at the ROOT by keccak_absorb line 377, so the shake128/shake256 asymmetry is redundant
defense-in-depth, contract-only -- a correct kill).

**W36-FIX** (numera/loop_optimizer.iii lo_safe_interval; falsifier 1534): loop_optimizer's contract is that
TWO independent analyses agree (doc lines 11-12: "a disagreement would itself be a bug signal") -- an interval
abstraction and the exhaustive affine scan.  lo_safe_interval used `lo_access_max(a,b,n) < size`.  For an EMPTY
loop (n=0) lo_access_max returns the SENTINEL 0 ("no address touched"), but `0 < size` conflates that with
"address 0 is touched": for size>=1 it is accidentally correct (0<size -> safe), but for size=0 it returns 0
(UNSAFE).  The affine ground truth ac_in_bounds(a,b,0,size) correctly returns 1 (SAFE -- `while i<0` never
runs) for ANY size.  So at (1,0,0,0) interval=0 disagrees with affine=1 -> lo_analyses_agree=0 (the module's
own false bug-signal about itself).  An empty loop touches no memory and is safe.  FIX: `if n == 0u32
{ return 1u32 }` at the top of lo_safe_interval -- matches the affine empty-loop semantics, restores agreement
for all (a,b,size).  n>0 unchanged; KAT (n=5,n=8) byte-identical.

1534 teeth (via @export, with the affine cross-witness as oracle): ac_in_bounds(1,0,0,0)==1 proves the empty
loop is safe; lo_safe(1,0,0,0)/lo_analyses_agree(1,0,0,0) pre-fix return 0 (exit 30/31) -> post-fix 1.  Sanity:
n>0 verdicts (safe 2,1,5,16; unsafe 3,2,8,16) unchanged, AND the crucial non-empty-loop-into-size-0-array case
(1,0,3,0) STAYS unsafe -- the fix is empty-LOOP (n=0), not empty-ARRAY (size=0).

The same-function-asymmetry lens generalizes to CROSS-WITNESS disagreement: when a module ships two analyses
that must agree, the corner where they diverge is a self-certified defect.  Gates: build GATE PASS FAIL=0, all
three ratchets OK; 1534 teeth exit 30 vs old lib, 99 vs new; corpus green.  Count 1120 -> **1121**.

## Wave-37/38 — defect-axis SATURATION (honest negative) + ec256/ec384 group-law coverage enhancement (2026-06-13)

**W37 (differential divergence, 0 confirmed):** Workflow over ~70 dual-path modules (a fast/abstract path +
a reference/exhaustive path documented to agree) found ZERO divergence -- not even a raw candidate survived
the self-gate.  loop_optimizer (W36) was the lone outlier; the rest agree on their corners.

**Saturation sweep (this session, all CLEAN after W35/W36 landed 1 bug each):** the cheap teeth-bearing
defect fingerprints are mined to the floor --
 - i32 signed-ordering sign-test (`>=0i32` on a maybe-negative i32): only a comment + two CORRECT avoidances
   (theorem_commons uses `!= -1i32` and documents the trap).  Clean.
 - accessor underflow (`[l_pid - 1]` etc.): calculus_v1's 4 CALC_* accessors all guard `l_pid==0` first.  Clean.
 - string last-byte underflow (`p[len-1]`): path/ini/onelang/corpus_coverage all guard (`a_len>0`, `e<=start`
   early-out, `len<2`, `len<4`).  Clean.
 - inclusive-`<=` loop bound (off-by-one write): the 87 hits are the correct DP/Fenwick N+1-sized-table idiom.
 - bigint_div (the hardest, most corner-bug-prone module): corpus 757 ALREADY ships a deep differential
   (Knuth-D vs bit-serial reference) + invariant KAT INCLUDING the D6 add-back trigger across 300 random pairs.
The III stdlib is genuinely mature: coverage ratchets at 0/0/0, deep differential KATs, external RFC/FIPS
vectors, exception-free RCB crypto, systematic guards.  Honest conclusion: the easy-to-medium defect veins are
saturated; the loop pivots from defect-hunting to externally-anchored coverage ENHANCEMENT.

**W38 ENHANCEMENT (1535 ec256 + 1536 ec384 group laws):** the two NIST EC modules had only a single ECDSA
vector each (208/209) -- their GROUP LAWS were never asserted against ground truth.  RCB Alg.4 (~12 mults
across temp slots) is transcription-bug-prone in paths one ECDSA (u1*G+u2*Q) vector may not exercise.  Each
KAT pairs (1) an EXTERNAL ANCHOR -- 1*G affine == the NIST published base point (Gx,Gy), pinning the whole
field/point/Montgomery pipeline to ground truth -- with (2) INTERNAL DIFFERENTIALS on the complete-add formula
through different operand sequences: homomorphism 2G+3G==5G, commutativity 3G+2G==5G, doubling-as-add
2G+2G==4G; plus pairwise-distinct non-vacuity.  Both pass =99 (the RCB add + ladder are correct); they are now
permanent externally-anchored regression oracles on the most security-critical modules.  (1536 first hit the
documented `*/`-in-comment trap -- `fq_*/384` closed the block comment; fixed.)

No source change -> no rebuild; corpus green with both KATs + 208/209 unchanged.  Count 1121 -> **1123**.

## Wave-39/40 — non-numera defect saturation (GLOBAL) + x25519 RFC7748 DH-agreement coverage (2026-06-13)

**W39 (non-numera sweep, 0 confirmed):** a 9-group / ~335-module workflow over EVERY non-numera subsystem
(verba parse/codecs, sanctus fs, aether net/wire, tempora date/time, omnia, forcefield, nous, katabasis,
memoria) with the full lens battery found 0 confirmed of 3 raw.  The 3 refuted were all correct kills:
nl_lex _nl_scan_number (the value lives in a doc'd 24-bit word_id field; the u32 overflow is subsumed by the
documented mask -- contract-only), ripple_metric rm_extract_improves (overflow needs ~2^64 source LINE counts
-- physically unreachable), lru lru_new (the capacity*8 overflow is pre-empted by the capacity*1 `occ`
allocation failing region's bounds check FIRST -> returns sentinel 0; unreachable).  Conclusion: the defect
saturation is GLOBAL, not numera-local -- across W37 (70 dual-path modules), W39 (335 non-numera modules),
4 grep-axes, and bigint_div's pre-existing deep differential, the whole stdlib is corner-clean on the
teeth-bearing defect axes.  Also verified: ALL crypto verifiers (ed25519/mldsa/slhdsa/rsa_pss/chacha-poly/
aes-gcm) ALREADY ship tamper-rejection arms (194/198/199/200/373/72/974) -- the "prove-the-negative" gap is
already closed.  The loop stays in coverage-ENHANCEMENT mode (W38 opened it).

**W40 ENHANCEMENT (1537 x25519 RFC7748 Section 6.1 DH):** 73_x25519_rfc7748_test1 covers only Section 5.2
Test 1 (one scalar-mult vector); the DIFFIE-HELLMAN AGREEMENT -- the security-DEFINING property -- was
unasserted.  1537 adds three EXTERNAL published-vector anchors (Alice pub = X25519(a,9), Bob pub = X25519(b,9),
shared K = X25519(a,Bpub) = X25519(b,Apub)) pinning the Montgomery ladder + clamping to RFC ground truth, PLUS
the agreement K1==K2 (both sides derive the same secret) and non-vacuity (distinct pubs, K != a pub).  Passes
=99 (the ladder is RFC-correct); a permanent externally-anchored oracle on the DH property.

No source change -> no rebuild; corpus green.  Count 1123 -> **1124**.

## Wave-41/42 — crypto coverage-gap audit + the hash/MAC/XOF KAT-strengthening batch (2026-06-13)

**W41 (crypto defining-property audit):** a 5-group workflow (KDF/AEAD/sig/hash-XOF/PQ) over every
security-critical primitive, with a confirm-stage ruling out already-covered, found 20 confirmed
published-vector/defining-property gaps.  The PQ keygen-from-seed gaps (mlkem/mldsa/slhdsa) need external
NIST ACVP files -> DEFERRED.  The self-contained hash/MAC/XOF gaps were filled as W42.

**W42 (6 KATs landed; corpus 1124 -> 1127):** all run-before-register, each anchored to an authoritative
published vector.
- **STRENGTHENED 3 weak existing KATs (test-strengthening -- the prior versions would pass even with a bug
  in the unchecked bytes):** 79_hmac_sha256_rfc4231 (was 9 of 32 tag bytes -> all 32, RFC4231 TC1);
  157_shake128_kat_empty (was 4 of 32 -> full 32 + XOF prefix-stability SHAKE128("",16)==first16 of ",32");
  158_shake256_kat_empty (was 4 of 32 -> full 64 + prefix-stability across the rate boundary).
- **NEW:** 1538 SHA3-512("") (FIPS202, full 64 bytes -- 156 covered only "abc"); 1540 SHA3-256(0xA3 x 200)
  (the NIST 1600-bit example -- the MULTI-BLOCK path 155/169 never reach, >rate 136); 1539 BLAKE2s("")
  (full 32 + the published "abc" vector as the anchor arm).
- **THE BLAKE2s CONSTANT-CORRECTION (run-before-register earned its keep):** 1539 first FAILED at byte 4 --
  the W41 audit's recalled empty-digest constant (69217a3049cfe7e8...) was WRONG past the 4-byte prefix.
  Disambiguated by DUMPING III's actual output: III's BLAKE2s("abc") is BYTE-EXACT to the published
  canonical (508c5e8c...), proving III's blake2s spec-faithful; therefore its empty output
  (69217a3079908094e11121d042354a7c1f55b6482ca1a51e1b250dfd1ed0eef9) IS the canonical empty digest, and the
  AUDIT CONSTANT was the error -- NOT a III bug.  Corrected 1539 to the verified bytes + kept the "abc"
  published-vector anchor so the test is non-circular.  **LESSON: a discovery-agent's recalled published
  CONSTANT is as fallible as a recalled code-fact -- run-before-register + dump-the-actual-output + an
  independent spec-correctness anchor (abc) distinguishes a bad constant from a real impl bug.  The agent
  ITSELF flagged its first sha3-512 recall as wrong and self-corrected; the blake2s one slipped through to
  the KAT, where the gate caught it.**

No source change -> no rebuild; corpus 1127/0 with 83/155/156/169 (the pre-existing hash KATs) unchanged.
Count 1124 -> **1127**.

## Wave-43/44 — AEAD AAD-binding negative + PQ keygen determinism/seed-dependence (the W41 residual, hand-filtered) (2026-06-13)

The W41 residual gaps were hand-verified to avoid duplicating existing coverage (the blake2s-constant lesson):
all 3 AEADs already tamper-reject (72 tag / 206 tag+hchacha-cross-check / 207 IV); 913 ecdsa already does
det-sign + msg-tamper; the chacha20 keystream is externally anchored via 72's 114-byte RFC8439 ciphertext.
Two GENUINE, self-contained, non-redundant properties remained:

**W43 (72 strengthen):** added an AAD-TAMPER-rejection arm to 72_chacha20_poly1305.  Distinct from the
existing tag-tamper: it flips one AAD bit (keeping the correct ct+tag) and asserts open() REJECTS -- proving
the AAD is bound into the Poly1305 authentication (RFC 8439 2.8: AAD is authenticated though not encrypted),
a separate code path from the ciphertext/tag.  Behavioral, no external constant; III passes (AAD authenticated).
EXPECTED 99 unchanged.

**W44 (1541 NEW):** PQ keygen DETERMINISM + SEED-DEPENDENCE for ML-KEM-512 / ML-DSA-44 / SLH-DSA-128s (the
913-ecdsa-determinism pattern).  GAP: 198/199/200 call keygen ONCE then round-trip; a seed-IGNORING or
non-deterministic keygen would STILL pass the round-trip (the keypair is internally consistent regardless of
the seed) -- a catastrophic class the round-trip structurally cannot catch.  1541 asserts, per scheme, (1)
keygen(seed) twice -> byte-identical (pk,sk), and (2) keygen(seed') -> a DIFFERENT pk (the seed is consumed).
Pre-zeroed whole-buffer compares, no external vector.  All 3 pass.

**NON-GAP verified (read-before-fetch avoided a wrong KAT):** the W41 "ecdsa RFC6979 exact-bytes" item is NOT
applicable -- III's iii_ecdsa_p256_sign_det derives its nonce via SP800-90A HMAC-DRBG seeded from (d,z) (the
comment says "RFC6979-STYLE"), NOT RFC6979's exact int2octets/bits2octets construction, so III's deterministic
signature legitimately differs from the RFC6979 published vector; an exact-bytes KAT would mis-fire on a
non-bug.  913 already covers determinism + (d,z)-dependence + tamper comprehensively.

DEFERRED (genuinely): the PQ keygen-from-seed FIPS-EXACT pk/sk/ct/sig vectors (NIST ACVP) -- kilobyte-scale,
impractical to hand-transcribe + unfetchable here; rsa_pss / drbg exact-vector KATs (need the modulus/seed).

No source change -> no rebuild; corpus green, 198/199/200 + 72 unchanged.  Count 1127 -> **1128**.

## Wave-45 — weak-KAT audit: strengthen partial spot-check crypto KATs to full-output (2026-06-13)

The W42 lesson (79/157/158 verified only 4-9 of N output bytes -> a bug in the unchecked bytes survives)
generalized into a build-free META-vein: audit the corpus for crypto/hash KATs that spot-check a few indexed
bytes with NO full-loop verify.  10 candidates found; the 3 cleanest hash KATs strengthened (all dump-verified
against III's actual output via a putchar probe, then asserted against the published vector):
- **155 SHA3-256("abc")**: 8 -> full 32 bytes (FIPS 202).
- **156 SHA3-512("abc")**: 8 -> full 64 bytes.
- **83 BLAKE2s("abc")**: 7 -> full 32 bytes (RFC 7693).
III dump byte-exact to the published vectors (sha3-256 3a985da7...11431532, sha3-512 b751850b...eec53f0,
blake2s 508c5e8c...86675982) -> III's hashes are fully correct, now the WHOLE digest is pinned (a future
regression in any byte reddens it, where before only the spot-checked prefix did).  EXPECTED unchanged
(155/156=99, 83=80, no table edit).  No source change -> no rebuild.  Count 1128 (unchanged -- these
strengthen existing tests, not add new ones).

**W46 follow-on (81/86):** strengthened the two genuinely-weak KDF KATs to full-output -- 81 HKDF-SHA256
RFC5869 TC1 OKM (9 -> full 42 bytes), 86 PBKDF2-HMAC-SHA256 RFC7914 DK (7 -> full 64 bytes).  Both
dump-verified vs III (OKM 3cb25f25...5865, DK 55ac046e...d3a19783).  Re-audit findings: 71_poly1305 was a
FALSE POSITIVE (check_tag already verifies all 16 tag bytes, just via a helper fn not a loop); 60_aes128
already verifies all 16 ciphertext bytes; 62_aes_gcm is adequately covered.  **DUMP CAVEAT learned:**
putchar-to-stdout on Windows is TEXT mode -> 0x0a output bytes get a spurious 0x0d prepended (CRLF
translation); the HKDF OKM's 0x0a at byte 18 exposed it.  Read dumps modulo this artifact (or fwrite binary);
the digests without 0x0a bytes (sha3/blake2s/pbkdf2-DK) dumped cleanly.  EXPECTED unchanged (81=60, 86=85).
The weak-KAT audit is now COMPLETE (all 10 candidates addressed: 6 strengthened, 4 were already-full).

## Wave-47/48 — algorithmic perf-headroom hunt: vein CLOSED TREE-WIDE (0 wins) (2026-06-13)

After defects + coverage saturated, opened the measured-perf vein.  Two read-only workflows over the whole
algorithm surface (W47 numera/omnia ~70 modules; W48 aether/sanctus/forcefield/verba/nous ~70 modules), each
gating on REAL + byte-IDENTICAL output + genuinely HOT (caller-controllable large n) + KAT-anchored, with
adversarial refute.  Result: **0 confirmed wins tree-wide.**  Every candidate refuted on a designed gate:
- **NOT HOT (the dominant kill):** the loop bound traces to a tiny fixed constant -- huffman hf_build_tree
  (n=distinct bytes <=256, called once per <=4KB compress), witness_compactor wc_mark_retain (zero production
  callers; only selftests n<=3), corpus_coverage cv_finalize (bound = CV_NUNCOV, ratcheted to 0 by the build
  -- runs zero iterations at the real call site).
- **BYTE-IDENTITY FALSE:** huffman's heap would change the (freq,index) tie-break -> different code-length
  multiset -> different compressed bytes, SILENTLY (only round-trip is KAT'd, not the stream).
- **ALREADY-OPTIMAL / mis-read:** pleroma's quadratic scan is already replaced by the CSR build in the live
  path (the scan is retained only as the differential oracle).
- **NAIVE LOAD-BEARING:** pleroma's exhaustive edge check is the independent-verification half of a
  build-then-verify trust gate; cv_finalize's insertion-sort is shaped to dodge the iiis-1 compiler trap.

CONCLUSION: the tree is algorithmically optimal where it is hot.  Its hot loops are crypto/compiler (already
instruction-optimized) or bounded by small fixed constants / ratcheted-to-zero; its quadratic forms are either
non-hot by-design (spec-documented), the slow half of a differential oracle, or load-bearing verification.  The
perf vein joins defects + coverage as EXHAUSTED.  The III stdlib is comprehensively mature across every
autonomous-discoverable axis this session probed.  [SUPERSEDED by W49 -- the spec/precision axis was NOT yet
probed when this was written, and it found a real defect; saturation is per-LENS, never global.]

## Wave-49 — interval_lattice il_add/il_mul OVERFLOW UNSOUNDNESS (the fresh spec/precision axis re-opened the vein) (2026-06-13)

The "all axes exhausted" claim above was PREMATURE -- written before probing the spec-conformance /
numerical-precision axis, which the corner-input/coverage/perf lenses never touched.  A fresh-axis workflow
(W49: spec_incomplete + precision_loss + doc_vs_code over the math/numeric core) found a REAL soundness defect
on round 1 -- the THIRD time this session that switching the AXIS re-opened a "saturated" vein (after W22
use-before-init).  LESSON RE-CONFIRMED: saturation is per-LENS, never global.

**W49-FIX (numera/interval_lattice.iii il_add + il_mul; falsifier 1542):** the interval abstract-domain transfer
functions are documented SOUND ("the abstract result contains every concrete result", line 53) but computed the
bounds with raw u32 `+`/`*`.  Under u32 OVERFLOW the upper bound WRAPS to a small value, INVERTING the interval
so it no longer contains the concrete (wrapped) results -- exactly what the module's own witnesses
il_add_sound / il_mul_sound reject.  Witness: il_add(2^31,2^31,0,0) -> IL_HI=(2^32)mod 2^32=0 -> [2^31,0]
inverted; concrete 2^31 not contained.  Reachable: loop_optimizer's il_mul(a,a,0,n-1) overflows for large
strides (a~n~70000 -> ~4.9e9 > 2^32) -> an unsound array-bound -> the optimizer could admit an unsafe rewrite.
FIX: detect overflow (carry-out `(h1+h2)<h1` for add; u64 product `(h1 as u64)*(h2 as u64) > 0xFFFFFFFF` for
mul) and saturate to TOP [0, 0xFFFFFFFF], which soundly contains every u32.  Non-overflowing inputs are
byte-identical -> 1265 + loop_optimizer/affine consumers stay green.

1542 teeth (soundness via @export): il_add(4294967290,4294967295,0,5) -- concrete (4294967290,0)=4294967290
must lie in [il_lo,il_hi]; pre-fix [4294967290,4] excludes it (exit 30) / post-fix TOP contains it.  Mul analog
il_mul(65535,65536,65535,65536) (exit 31).  Sanity: non-overflow add/mul unchanged.  Count 1128 -> **1129**.

## Wave-51 — elias_gamma_put/elias_delta_put swallow bitio's overflow error (error-state axis; the cad-W29 class) (2026-06-13)

Continued the fresh-axis rotation (W49 vindicated it).  W51 axes: error-state-half-write + boundary-exactness.
Found 1 real defect (3 refuted: knapsack/coin_change/catalan all already-guarded or out-of-domain-unreachable
-- the knapsack candidate was the W10-era guard ITSELF, pinned by 1501, with cause/effect inverted).

**W51-FIX (numera/elias.iii elias_gamma_put + elias_delta_put; falsifier 1543):** both declare `-> i32` but
DISCARDED the bitw_put return and hardcoded `return 0i32`.  bitw_put returns BIO_E_OVF (-1) when the codeword
does not fit the bit-buffer (bitio's own KAT honors this channel) -- elias was the lone consumer that DROPPED
it.  So encoding into an undersized buffer TRUNCATED the codeword yet reported SUCCESS (0); the caller then
decodes a corrupt stream and the documented ROUND-TRIP IDENTITY breaks SILENTLY.  The cad-W29 error-swallow
class, on the bitio substrate.  FIX: return bitw_put's code (-1 on overflow).  Success path byte-identical
(all puts return 0 -> same return 0) -> 1228 elias_kat (2048-byte buffer, never overflows) stays green.

1543 teeth: bitw_init(2-byte buf); elias_gamma_put(1500) [bitlen 11 -> 21 bits > 16] / elias_delta_put(1500)
[17 bits > 16] -- pre-fix swallow -> 0 (exit 30/31), post-fix -> -1.  Sanity: a fitting codeword returns 0
(guard not over-tight) + a large-buffer round-trip is unchanged.  Count 1129 -> **1130**.

## Wave-53 — affine_check ac_max_access overflow -> UNSOUND bounds-check ELIMINATION (the W49 sibling the sibling-hunt MISSED; highest-value find) (2026-06-13)

The prover-verdict-soundness lens (a prover returning a FALSE-POSITIVE SAFE verdict -- the highest-value
soundness hole) found a real one, and it is the interval_lattice (W49) SIBLING that the W49 sibling-hunt missed
(I treated affine_check as the exhaustive WITNESS, not a closed-form-bound PRODUCER -- but it ships both).
The W49 lesson re-applies (W31/W32): a sibling-hunt can miss an instance; the FRESH LENS caught it.

**W53-FIX (numera/affine_check.iii ac_max_access; falsifier 1544):** ac_max_access(a,b,n) computed the closed
form a*(n-1)+b in raw u32 -- WRAPS on overflow, reporting a small max for a stream that wraps high.  The
CONSUMER makes it a memory-safety hole: numera::bce (VERIFIED bounds-check ELIMINATION, doc "an eliminated
check provably never fires") eliminates a check when `ac_max_access(a,b,n) < size` (bce_redundant, bce.iii:44).
For a=2, b=0xFFFFFFFE, n=3, size=3: ac_max_access wraps to 2 -> bce_redundant=1 (REDUNDANT -> STRIP the check),
but i=0 touches A[0xFFFFFFFE] >= 3 -> the stripped check was NEEDED -> a bce-driven pass produces memory-unsafe
code.  The module's exhaustive witness ac_in_bounds=0 (UNSAFE) DISAGREES; bce's own two-sided invariant breaks.
FIX (same as W49): compute in u64, on overflow report MAX (0xFFFFFFFF) so `< size` fails CLOSED (keep the
check).  This ALSO aligns ac_max_access with the W49-fixed lo_access_max (which already saturates to MAX) ->
lo_analyses_agree stays consistent on overflow inputs (it would otherwise have silently diverged).  KATs use
small values (bce_setup max 38) -> byte-identical; bce_kat/affine_check_kat/loop_optimizer_kat green.

1544 teeth (oracle ac_in_bounds==0): ac_max_access(2,0xFFFFFFFE,3) pre-fix 2 / post-fix 0xFFFFFFFF (exit 30);
bce_redundant(2,0xFFFFFFFE,3,3) pre-fix 1 (unsound eliminate) / post-fix 0 (keep) (exit 31).  Sanity: non-
overflow ac_max_access/bce_redundant unchanged.  Count 1130 -> **1131**.

**THE W49+W53 PAIR is the complete overflow-soundness fix for the bounds-analysis stack:** interval_lattice
il_add/il_mul (W49) + affine_check ac_max_access (W53) are the TWO closed-form-bound producers both consumed by
loop_optimizer (lo_safe = lo_access_max AND ac_in_bounds) and bce (ac_max_access).  Both now saturate-to-TOP on
overflow; both ground-truth scans (ac_in_bounds) already did -> the whole stack is sound under overflow.

## Wave-59 — hardcoded lookup-table correctness: BLAKE2s SIGMA all-entries self-consistency oracle (the spot-vector blind spot) (2026-06-13)

After SIX consecutive clean defect-lens sweeps (W52/54/55/56/57/58), a user-hinted FRESH lens ("audit the
twiddle tables") reopened a real gap class: a hardcoded lookup table can have a WRONG ENTRY the spot-vector
KATs never exercise (AES encrypting one block hits ~30 of 256 S-box entries).  W59 verified every table's VALUES
against its generating identity (all CORRECT: AES S-box/Rcon, GCM_BSWAP=15-i, ML-KEM KZ=17^bitrev(i) mod 3329,
SHA/keccak constants, BLAKE2s SIGMA vs RFC7693) -- so NO wrong entry.  But it found one table that lacks an
all-entries oracle and is NOT differentially pinned by a published vector.

**W59-FIX (numera/blake2s.iii + falsifier 1545): the BLAKE2s SIGMA coverage blind spot.**  AES Rcon / GCM_BSWAP
/ ML-KEM KZ are each differentially pinned by a FIPS KAT (a wrong entry flips the ciphertext/tag -> the KAT
fails).  But BLAKE2s SIGMA (160-entry message schedule) is NOT: the only digest KATs are "abc" (M[0] nonzero,
rest 0) and "" (all 0), so a wrong SIGMA entry among the ZERO-word indices is differentially INVISIBLE to the
digest.  Added b2s_sigma_selfcheck() @export -- verifies each of the 10 rounds is a PERMUTATION of {0..15}
(out-of-range / duplicate / missing), exercising ALL 160 entries -- and 1545 asserts it ==0 (99).

RIGOROUS TEETH PROOF (the gap is real + the oracle bites): temporarily corrupted round-9 pos-1 (2 -> 8, a
duplicate-8/missing-2) and rebuilt -> 1545 returned 10 (round 9 malformed, CAUGHT) while corpus 83 ("abc"=80)
and 1539 (""=99) BOTH stayed GREEN (M[2]=M[8]=0 -> the corruption is invisible to those digests).  Reverted ->
clean.  This proves the new oracle covers a real wrong-entry class the existing suite misses.  The table is
currently CORRECT (1545==99 on the real table); this is a permanent regression guard on all 160 entries.

No defect to fix (tables correct); a genuine coverage closure on the one un-pinned table.  Count 1131 -> **1132**.

## Wave-62 — lzss_decompress malformed-stream REJECTION oracle (untrusted-input negative paths) (2026-06-14)

Two clean defect-lens sweeps (W60 aliasing/overlap, W61 unsigned-subtraction underflow) returned 0 confirmed --
the autonomous code-defect surface is mined out (last code defect was W53/affine_check).  Rotated to the W59
NEGATIVE-PATH COVERAGE idiom on an @export that parses UNTRUSTED input: `lzss_decompress`.  Its only test,
1224_lzss, drives lzss_kat() = ROUNDTRIP identity decompress(compress(x))==x on VALID streams only -- so a stream
compress() never emits (a MALFORMED one) is never fed to the decoder, leaving two distinct REJECTION CLASSES
entirely unexercised:
  (A) back-reference UNDERFLOW (lzss.iii:115 `if off > outp { return -1 }`): a crafted match offset pointing
      before the output start.  Without the guard, `src = outp - off` underflows u32 to ~0xFFFFFFFF and
      `op[src+c]` reads ~4 GiB out of bounds -- a security-relevant OOB READ on attacker-controlled bytes.
  (B) capacity OVERFLOW (lzss.iii:125 `if outp >= out_cap { return -1 }`): more decoded bytes than out_cap ->
      OOB WRITE past the caller's buffer.

**W62-FIX (falsifier 1546_lzss_reject): a two-class rejection oracle.**  (A) ctrl=0x01,b0=0x01,b1=0x00 ->
off=1 while outp=0 -> must return -1.  (B) ctrl=0x00 + 3 literals into out_cap=2 -> 3rd literal trips
outp>=out_cap -> must return -1.  99 = both rejected.

RIGOROUS TEETH PROOF (each guard independently load-bearing + the suite misses both classes):
  - removed line 115, rebuilt -> 1546 = **139 (SIGSEGV** on the ~4 GiB OOB read) while 1224 stayed **99**; reverted.
  - removed line 125, rebuilt -> 1546 = **20** (sub-case B returns 3 not -1) while 1224 stayed **99** (a valid
    decompress fills exactly out_cap and never trips the guard); reverted.
lzss.iii is byte-identical to HEAD (git diff empty, no TEETH residue).  Passes the 3-gate admission test: the gap
is real (grepped: no malformed-stream test exists), the teeth are proven (each guard reddens its sub-case while
the valid KAT stays green), and it is non-tautological (a concrete OOB the entire suite waves through).

No defect to fix (both guards are present + correct); a negative-path coverage closure on an untrusted-input
decompressor.  Count 1132 -> **1133**.

## Wave-63 — huff_decode malformed-stream REJECTION oracle (the DEFLATE-class untrusted parser; W62 sibling) (2026-06-14)

Sibling-hunt of W62 across the other untrusted-input codec.  huff_decode is @export and parses UNTRUSTED
input, but its only test (1230_huffman) is roundtrip identity huff_decode(huff_encode(x))==x on VALID streams
only -- so FOUR rejection guards are unexercised: truncated header (huffman.iii:195 in_len<260 -> HF_E_DEC),
HOSTILE code-length (206 cl>64 -> HF_E_LEN), capacity (211 orig>out_cap -> HF_E_CAP), undecodable bitstream
(236 found==0 -> HF_E_DEC).  Covered the two highest-value cleanly-craftable distinct CLASSES (per the
distinct-class-not-every-line discipline):

**W63-FIX (falsifier 1547_huff_reject):**
  (A) TRUNCATED HEADER: in_len=10 (<260) -> must return HF_E_DEC (-3).
  (B) HOSTILE CODE-LENGTH: in_len=280 with byte[0]=0xFF (code length 255 > 64) -> must return HF_E_LEN (-1).
      The module comment is explicit: hf_canon indexes HF_BL/HF_NEXT/HF_FIRST/HF_OFF (all [;65]) by these
      lengths, so a byte > 64 drives an OUT-OF-BOUNDS WRITE -- the guard is a real memory-safety gate.

RIGOROUS TEETH (each guard independently load-bearing + the suite misses both):
  - removed line 195, rebuilt -> 1547 = **10** (an all-zero length table decodes to empty output, returns 0
    not -3) while 1230 stayed **99**; reverted.
  - removed line 206, rebuilt -> 1547 = **20** (hf_canon OOB-writes its [;65] tables at index 255, returns a
    non-HF_E_LEN value) while 1230 stayed **99** (separate process; a valid stream never carries cl>64);
    reverted.
huffman.iii is byte-identical to HEAD (git diff empty, no TEETH residue).  3-gate: gap real (1230 roundtrip-only),
teeth proven, non-tautological (a concrete OOB the suite waves through).

NOTE: lzss_decompress (W62) covers the LZ layer; lzh_decompress composes a Huffman pre-pass (now W63) + lzss
(W62), so the DEFLATE recipe's untrusted-input rejection is covered at both primitive layers.

No defect to fix (all guards present + correct); a negative-path coverage closure on the Huffman decoder.
Count 1133 -> **1134**.

## Wave-64..67 — systematic negative-coverage sweep: hex / leb128 / lzh decoder rejection oracles (2026-06-14)

W64 was a 20-agent discovery sweep for the W62/W63 idiom generalized: an untrusted-input @export
decoder/parser/verifier whose ENTIRE rejection surface is untested (positive/roundtrip KAT only, ZERO
negative test, grep-confirmed).  The adversarial-refute stage was the workhorse -- it KILLED six teeth-less
candidates (ed25519_verify line 277: the SHA-512(R||A||M) hash-binding makes the decompress guard
unobservable; rsa_pss_verify: 1429 ALREADY tests sigLen!=k; mldsa 1172/1173: shadowed by the final
Fiat-Shamir c_check so guard-removal can't flip the verdict; erasure_store es_repair_shard line 191:
redundant with the es_reconstruct line-158 guard; lzh line 77: forwards a value lzss masks back to -1) and
CORRECTED two oracles whose naive craft was tautological (leb128, mldsa-1180).  Confirmed gaps landed as
W65/66/67 (the trivial-craft codec decoders; mldsa-1180/1190 deferred to W68):

**W65 (1548_hex_reject) -- hex_decode (hex.iii:61).**  Two untested reject classes: odd src_len (line 66
-> HEX_E_BAD_LEN -3) and bad nibble (lines 79-80, hex_char_to_nibble==0xFF -> HEX_E_BAD_CHAR -2).  grep
HEX_E_BAD over corpus = 0 files; the 3 callers (16/1401/1429) feed valid even-length hex only.

**W66 (1549_leb128_overflow_reject) -- leb128_decode_u64 (verba/leb128.iii:46).**  The shift>=64 overflow
guard (line 60).  89_leb128 tests only the *i64* truncation guard.  CRAFT IS DELIBERATE: ten 0x80 + a 0x01
terminator at index 10 (src_len=11) so shift hits 70 at index 9 BEFORE the terminator -- a 10-byte craft
returns 0 with OR without the guard (length backstop) and is tautological; the terminator isolates line 60.

**W67 (1550_lzh_reject) -- lzh_decompress (lzh.iii:63).**  Empty-stream (line 64 in_len<1 -> LZH_E_SUB -1)
and mode-0 capacity (line 70 n>out_cap -> LZH_E_CAP -2).  1231_lzh is roundtrip-only (out_cap=1024).
Completes the DEFLATE-recipe untrusted-input coverage (lzss=W62, huffman=W63, lzh-orchestration=W67).

RIGOROUS TEETH -- all FIVE guards proven independently load-bearing in TWO rebuilds (disjoint guard-sets,
each reddening a different oracle's sub-case):
  - rebuild 1 (disable hex:66 + leb128:60 + lzh:64) -> 1548=10, 1549=10, 1550=10; positives 16/89/1231=99.
  - rebuild 2 (disable hex:79-80 + lzh:70) -> 1548=20, 1550=20, 1549=99; positives 16/89/1231=99.
All three modules byte-identical to HEAD afterward (git diff empty, no TEETH residue).  3-gate per finding:
gap real (grep-confirmed zero negative tests), teeth proven, non-tautological.

No defect to fix (all guards present + correct); three negative-path coverage closures on untrusted-input
codec decoders.  Count 1134 -> **1137**.

## Wave-68 — ML-DSA (FIPS 204) verify anti-malleability / canonical-encoding hint guards (the deepest W64 gap) (2026-06-14)

The highest-value W64-confirmed gap: iii_mldsa_verify decodes an UNTRUSTED signature, and FIPS 204
HintBitUnpack mandates two canonical-encoding / anti-malleability invariants that NO test exercised --
strictly-increasing hint indices within each polynomial (mldsa.iii:1180 `cur<=prv`) and zero padding bytes
(mldsa.iii:1190 `sp[hoff+j2]!=0`).  The 3 verify tests (198/769 tamper sig[0]=c_seed; 995 tampers siglen)
never touch the hint section [hoff, hoff+omega+k).  ML-DSA-44: hoff = 32 + l*pzp = 32 + 4*576 = 2336,
omega = 80, k = 4; counts at sig[2416..2420), index bytes at sig[2336..2416), total count sig[2419].

**W68-FIX (falsifier 1551_mldsa_hint_reject): a SET-PRESERVING craft** (the discriminator from W64's refute --
an arbitrary overwrite changes the hint bit-SET so verify still returns -1 via the final Fiat-Shamir c_check,
leaving the guard unfalsified = tautological).  keygen->sign a genuine ML-DSA-44 sig, then:
  (1180) REORDER two genuine strictly-increasing ADJACENT index bytes in one poly (located by a runtime scan
         for the first poly with >=2 hints).  Decode sets MLDSA_POOL membership order-independently (line
         1182), so the hint set H is BYTE-IDENTICAL -- only the strict-increase guard differs.  Accepting a
         reordered encoding of the SAME signature IS signature malleability.
  (1190) corrupt ONE padding byte at sig[hoff+idx_total] (never read by the decode loop, which reads only
         [0,idx_total)) -- so H is identical; only the padding-zero guard sees it.
Both tampers are restored before the next (isolation).  A probe (STDLIB/build/_w68_probe, exit 99) first
confirmed the 0x42 seed yields a poly with >=2 hints AND padding (idx_total<omega), so the craft is
constructible.

RIGOROUS TEETH (each guard independently load-bearing; the set-preserving craft is what gives them teeth):
  - removed line 1190, rebuilt -> 1551 = **10** (the padding-tampered sig ACCEPTS, verify==0) while
    198/995 stayed **99**; reverted.
  - removed line 1180, rebuilt -> 1551 = **20** (the reordered-hint sig ACCEPTS) while 198/995 stayed **99**;
    reverted.
mldsa.iii is byte-identical to HEAD (git diff empty, no TEETH residue).  3-gate: gap real (grep: no hint-
section negative test), teeth proven, non-tautological (the reorder/padding accept-without-guard is a real
malleability/non-canonical-encoding acceptance the suite waves through).

No defect to fix (both guards present + correct); a negative-path coverage closure on the ML-DSA verifier's
FIPS 204 anti-malleability surface.  Count 1137 -> **1138**.

## Wave-69..71 — SYSTEMS-LAYER untrusted-parser rejection oracles (HTTP / JSON / decimal) (2026-06-14)

W69 was a 36-agent discovery sweep on the systems-layer parsers (HTTP/JSON/INI/inet/URI) for the W62/63/65-68
negcoverage idiom.  The adversarial-refute stage KILLED the teeth-less candidates (http cursor>=raw_len guards
233/273 redundant; https_parse_decimal_u64 418/423 subsumed by the body bound-check at 588; http_client
status-digit 275 caught by sibling 276; inet truncation guards memory-safety-only, backstopped by the bounded
octet parser; json unterminated-string 570 backstopped by the trailing-garbage guard) and CORRECTED several
crafts.  Seven teeth-bearing gaps confirmed and landed (W70 http + W71 json/parse):

**W70 (1552_http_reject) -- http_parse_request (http_server.iii:602), 3 request-line/header guards:**
  (235) EMPTY METHOD (method_len==0): craft " /index.html HTTP/1.1\r\n\r\n" (leading SP).
  (256) EMPTY TARGET (target_len==0): craft "GET<SP><SP>HTTP/1.1\r\n\r\n" (TWO spaces -- one space hits the
        line-249 CR-in-target guard instead).
  (300) EMPTY HEADER NAME (name_len==0): craft "GET / HTTP/1.1\r\n: value\r\n\r\n".
  Assert on the PARSE RETURN (req==0), never a *_len readback (teeth-less).

**W71 (1553_json_reject) -- json_parse (json.iii:850), 2 guards:**
  (272) NUMBER WITH NO DIGITS (digits==0): craft "[-]" (without the guard parses to a bogus 1-element NUM(0)
        array).
  (861) TRAILING GARBAGE after root: craft "42 x" (the SPACE is load-bearing -- "42x" rejects inside the
        number parser's exponent path, teeth-less).

**W71 (1554_parse_decimal_reject) -- parse_decimal_u32 (parse.iii:114), 2 guards:**
  (143) ZERO DIGITS: craft "abc".  (144) U32 OVERFLOW: craft "99999999999".  Reject asserted on parse_is_ok==0.

RIGOROUS TEETH -- all SEVEN guards proven independently load-bearing in THREE rebuilds (cross-module disjoint
guard-sets, each reddening a different oracle's sub-case):
  rebuild 1 (disable http:235 + json:272 + parse:143) -> 1552=10 1553=10 1554=10;
  rebuild 2 (disable http:256 + json:861 + parse:144) -> 1552=20 1553=20 1554=20;
  rebuild 3 (disable http:300)                         -> 1552=40 1553=99 1554=99.
  positives 64_http_parse_request / 52_json_parse_primitives / 32_parse_decimal stayed 99 in all three.
All three modules byte-identical to HEAD afterward (git diff empty, no TEETH residue).  3-gate per finding:
gap real (grep-confirmed zero negative test), teeth proven, non-tautological (each malformed input is ACCEPTED
without its guard -- a real over-acceptance the suite waves through).

No defect to fix (all guards present + correct); three negative-path coverage closures on untrusted-input
systems-layer parsers.  Count 1138 -> **1141**.
