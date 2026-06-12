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

**Day-1 summary (2026-06-11)**: first census 430 → **124** across twenty-three tranches (KATs 1390–1414), full corpus 957 → **1002 PASS / 0 FAIL** throughout, ratchet never regressed, scanner refined once (generics excluded), one stale module comment caught and binary-pinned (circ feasible 363224 ≠ the comment's 16,128). 306 export claims either proven by a falsifiable KAT or removed as non-surface.

Notable API truths the burn-down has already pinned: `checked_u64_*` returns checked.iii
handles (decode via `checked_u64_unwrap_or`, drop after use — never compare handle ids);
`checked_u64_drop` returns u8 (1=ok); `ccat_init()` resets the ONE category (register objects
AFTER it); `bigint_eq_u64` compares two bigints (u64-coded verdict, not bigint-vs-u64);
the env-root capability is immortal (`cap_drop` → CAP_E_DENIED).
