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
| 2026-06-11 | 8: founders directives (fa_pfs_deny/witness_inject/revoke_verify: exact byte layouts rebuilt + live-signed, every field sig-bound), erasure roots (es_n/k/root_ptr: deterministic + content-sensitive), closure+resolver (includes_resolver_seal before/after, with_resolver_byte reproducible), bb_diag_* sentinel-replacement, bws_true identity law, constants_value stability, cpe_count determinism, air_get_trace exactness, format_char_ascii width law | `1399_anchor_store_wave`=99 | 16 | **360** | **360** |

Notable API truths the burn-down has already pinned: `checked_u64_*` returns checked.iii
handles (decode via `checked_u64_unwrap_or`, drop after use — never compare handle ids);
`checked_u64_drop` returns u8 (1=ok); `ccat_init()` resets the ONE category (register objects
AFTER it); `bigint_eq_u64` compares two bigints (u64-coded verdict, not bigint-vs-u64);
the env-root capability is immortal (`cap_drop` → CAP_E_DENIED).
