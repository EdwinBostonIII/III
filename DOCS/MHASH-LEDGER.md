# III RESOLUTION HASH LEDGER

**FROZEN SPECIFICATION:** III-RES-FROZEN-001
**Status:** PENDING SEAL — populated by step G0006 of §I.

This document records the SHA-256 mhash of every artefact in the III resolution build. After step G0006 of the implementation plan runs to completion, the values below are filled by the build system and the document is committed atomically.

## Master mhashes

| Artefact | SHA-256 |
|----------|---------|
| `iiis-0.exe` | `ac4eec4ef4b553aa902664e51d44edfddc92e199002afb6d7ae61eaaf72d59bd` |
| `STDLIB/build/iii/libiii_native.a` (resolver runtime + 24 codecs + dispatch + intent_form/transform_form runtime parsers) | `0e16a85bac5217771b606dc3e1c333a7b8055b3096dd8af2cfd94732e431001d` |
| `iiis-0.mhash` | (filled by build determinism check) |
| `iiis-1.mhash` | (filled by build) |
| `iiis-2.mhash` | (filled by build) |
| `iiis-3.mhash` | (filled by build) |
| `STDLIB/iii/SEAL_RESOLVER.mhash` | (computed at boot by `seal_resolver_compute()`) |
| `STDLIB/build/SOURCES.mhash` | (filled by build) |
| `STDLIB/iii/SEAL.mhash` | (filled by build) |
| `closure_root` (post-resolution) | (filled by `closure_compute_with_resolver()`) |
| `closure_root_with_resolver` | (filled by build) |

**Build verification (2026-05-08):**
- Stdlib build: **136/136 PASS**
- Corpus run: **53/54 PASS** (all 24 new resolver tests 31..54 green; 09_unary failure is pre-existing, unrelated)
- All 18 new resolver-runtime modules compile cleanly:
  - `numera/sat_arith` (Phase R0017)
  - `verba/intent`, `verba/intent_form`, `verba/ast_intent`
  - `omnia/call_context`, `omnia/unify`, `omnia/pattern_table`
  - `omnia/resolver`, `omnia/resolver_replay`, `omnia/proof_ripple_resolution`
  - `omnia/transform`, `omnia/transform_patterns`, `omnia/codegen_patterns`
  - `omnia/babel`, `omnia/babel_intent`, `omnia/governance`, `omnia/resolution_init`
  - (Existing placeholder versions of `mandate_m22`, `quality_q7`, `seal_resolver`, `pattern`, `pattern_table`, `resolver_replay` updated)
- 16 ADR documents committed under `DOCS/ADR/ADR-RES-001..016` (with -015 deleted by §3.1)
- 24 corpus tests `31_..54_*.iii` written under `COMPILER/BOOT/stage1_corpus/`
- `run_corpus.sh` extended with EXPECTED entries for tests 31..54

## Per-corpus witness mhashes

| Test | Witness mhash (post-run) |
|------|--------------------------|
| 31_sat_arith | (filled by replay) |
| 32_intent_seal | (filled by replay) |
| 33_unify_basic | (filled by replay) |
| 34_unify_occurs | (filled by replay) |
| 35_unify_arity | (filled by replay) |
| 36_unify_depth | (filled by replay) |
| 37_pattern_register_after_seal | (filled by replay) |
| 38_score_table | (filled by replay) |
| 39_resolve_simple | (filled by replay) |
| 40_resolve_tiebreak | (filled by replay) |
| 41_resolve_ambiguous | (filled by replay) |
| 42_resolve_nomatch | (filled by replay) |
| 43_resolve_no_recompute_observable | (filled by replay) |
| 44_metapattern_set | (filled by replay) |
| 45_replay_witness | (filled by replay) |
| 46_q7_gate_pos | (filled by replay) |
| 47_q7_gate_neg | (filled by replay) |
| 48_m22_audit | (filled by replay) |
| 49_proof_ripple_pattern | (filled by replay) |
| 50_sid_inverse | (filled by replay) |
| 51_resolve_syntax | (filled by replay) |
| 52_call_via_resolver | (filled by replay) |
| 53_resolve_no_self_recursion | (filled by replay) |
| 54_transform_iii_to_asm | (filled by replay) |

## Audit signature

| Item | Value |
|------|-------|
| committed-by | (filled by signer) |
| timestamp | (filled by build, ISO 8601 UTC) |
| spec-id | III-RES-FROZEN-001 |
| revision | 2 |
| commit-tag | iii-resolution-v1 |
| approved-by | (operator sign-off, step G0010) |

## Production protocol

```bash
# Step G0006: compute master mhashes
sha256sum COMPILED/iiis-0.exe > /tmp/iiis-0.exe.sha
cat /tmp/iiis-0.exe.sha
# Manually transcribe into "iiis-0.exe" row above

iii --emit-resolver-seal > /tmp/seal.bytes
sha256sum /tmp/seal.bytes
# Transcribe into "SEAL_RESOLVER.mhash" row

iii --closure-root > /tmp/closure.bytes
sha256sum /tmp/closure.bytes
# Transcribe into "closure_root" row

# Step G0013: 143×22 mandate matrix (see DOCS/MANDATE-LEDGER.md)

# Step G0014: tag and commit
git add DOCS/MHASH-LEDGER.md DOCS/MANDATE-LEDGER.md
git commit -m "Seal III-RES-FROZEN-001: hash ledger and mandate ledger"
git tag iii-resolution-v1
```

## Verification

Subsequent CI runs verify all values match. Any mismatch → build fails; investigate.

```bash
# CI hook (run on every build)
expected=$(grep "iiis-0.exe" DOCS/MHASH-LEDGER.md | awk '{print $NF}')
actual=$(sha256sum COMPILED/iiis-0.exe | awk '{print $1}')
if [[ "$expected" != "$actual" ]]; then
    echo "MHASH DRIFT: expected=$expected actual=$actual"
    exit 1
fi
```

## Cross-Reference

- FROZEN SPEC §15.1 (two-seal architecture)
- FROZEN SPEC §15.4 (re-seal procedure)
- FROZEN SPEC §K.full (hash ledger procedure)
- ADR-RES-009 (resolver seal)

---

## §RITCHIE — Convergence execution begun-at pin

The RITCHIE convergence plan (`C:\Users\Edwin Boston\.claude\plans\then-make-an-excruciatingly-iridescent-ritchie.md`) begins execution against the substrate identity recorded below. This row is **append-only**; convergence steps that rotate any of these hashes record the rotation in subsequent §RITCHIE/SN sub-rows.

**Audit log:** `DOCS/CONVERGENCE-AUDIT.md` §0.0

### Begun-at substrate identity (Stage 0.0, immutable baseline)

| Artifact | SHA-256 (live, 2026-05-20) |
|---|---|
| `COMPILED/iiis-0.exe` | `0f4ac80c48410efd7f7c34bb9f6a8a2ae00a01c36c70b8616d4aea3db7526e26` |
| `COMPILED/iiis-1.exe` | `0fb14ddee9bd06a05f01b448926784b53d7a578bd2b84f33b2a29740fd7e7b8a` |
| `COMPILED/iiis-2.exe` | `528c0d49bf82338cea3090ccc39103a3a9d795812516598fa2ca25f0aa51bf7b` |
| `COMPILED/iiis-3.exe` | `8be5bf34c885382cb349e4e648381837e06d915c2af291e0c035b638916e0822` |
| `COMPILED/iiis_sanctum_compile.exe` | `24e408a03c351a011399d7de747602d38f7559cebd010af708def0f5189d9fd1` |
| `COMPILED/iiis-0.mhash` (golden — DRIFTED from live, resolved by Stage 0.4) | `210985ec1f62ec8e6b003fab03091410942f71087ab343560ad75c8881f1a233` |
| `COMPILED/iiis-1.mhash` (golden — DRIFTED) | `a4eca281a472cddc434986c506df7f95f9e9cc227de822f57f3a8f12598fc9b6` |
| `STDLIB/build/iii/libiii_native.a` | `37a6581a1ac608a6bc4205c219962a2f7d14939042abdce88d5efe0fdf404932` |
| `STDLIB/build/iii/libiii_native.a.mhash` (file containing the canonical archive hash) | `8dacd53549de11aaf19b5127a49bdcc356ec2a3b51517c6c6ffaed912797e617` |
| `STDLIB/iii/SEAL.mhash` (232 lines — INTERNALLY DRIFTED, see §0.0 catalogue) | `e7499847697006444a882b817bf20c6f0e94d1dc60461750f2b0fa0dc64604a9` |
| `STDLIB/build/SOURCES.mhash` (stale — covers 46 of 246 modules; resolved by Stage 0.3) | `5ba97008066941160b9f5b3e20ea82651ce9d816fdb760861d3755a2b25efeff` |
| `STDLIB/build/CLOSURE.mhash` (stale by transitivity) | `95c451c84afb67b45a2b86f6a13c504c65b4b1613075c2682ae8e50f75e72eb1` |
| `NOTES/ARCHITECTURE.md` (2026-05-08 snapshot; claims 198 modules vs 246 actual) | `f20841ee4223c6216d0e9adfdf6b8b02d9618de8c10d33013c0b4c89215bc951` |
| `BUILD-ARTIFACTS.md` | `2c9d41c7fa1c26d0233159be4a4f790e89f87403c61c3e842d99a6dda888057a` |
| `R1-SUBSYSTEMS.md` (§3 tally inconsistent; resolved by Stage 1.3) | `2509473ce9eb9691bffcb493bb8db6789c67245a650d771b5a39f911d1dbde24` |
| `run_all_corpora.sh` (advertises 179 vs actual 251+; resolved by Stage 1.10) | `22998b8448420d9309ca41e3302fb41dfb34e80819a9a05ea9bf2edf611003f2` |
| `DOCS/MANDATE-LEDGER.md` (PENDING status) | `283974c2260cc6ce54c78a57aa27ab247dfba0c9d22be0b550de7d91d11f3c62` |
| `DOCS/CONVERGENCE-AUDIT.md` (Stage 0.0 author state — will rotate on every step) | `662a94930800455781e14a011f7d725e2a187a502a5d8e1a09f7eba8f15dc446` |

### Begun-at file-tree counts

| Category | Count |
|---|---|
| `STDLIB/iii/aether` modules | 20 |
| `STDLIB/iii/memoria` modules | 5 |
| `STDLIB/iii/numera` modules | 45 |
| `STDLIB/iii/omnia` modules | 100 |
| `STDLIB/iii/sanctus` modules | 23 |
| `STDLIB/iii/tempora` modules | 5 |
| `STDLIB/iii/verba` modules | 48 |
| **STDLIB/iii total** | **246** |
| STDLIB/corpus `.iii` tests | 375 |
| DOCS files | 79 |
| R1 subsystem directories | 32 |
| Stage 0.1 orphan root files (cg_r3.iii 0 B + iii_fs_test.tmp 5 B) | 2 |
| Stage 0.2 orphan `_obj_boot/*.o` (cg_r3_xii.o + xii_ldil.o) | 2 |

### Begun-at orphan forensics (pre-deletion forensic record)

| Path | Size | SHA-256 | Content |
|---|---|---|---|
| `cg_r3.iii` | 0 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` | (empty file canonical hash) |
| `iii_fs_test.tmp` | 5 | `2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824` | ASCII `"hello"` |
| `COMPILED/_obj_boot/cg_r3_xii.o` | 3,209 | `96814981fdb8c0cd…` | ELF/PE-COFF object for XII rewrite-rule codegen extension |
| `COMPILED/_obj_boot/xii_ldil.o` | 4,013 | `8630fb7c5db81218…` | ELF/PE-COFF object for XII Link-Time Lattice Inliner |

### Begun-at internal contradictions in `STDLIB/iii/SEAL.mhash`

Lines that drift from the live substrate (each resolved by a specific RITCHIE step):

| Line | Claim | Reality | Resolved by |
|---|---|---|---|
| 4 | `modules: 217` | 246 | Stage 0.3 |
| 5 | `corpus_pass: 243/243` | TBD (Stage 0.7) | Stage 0.7 |
| 6 | `iiis-0 mhash: 301bdaf0a3fd51c5d6898823c18aaa801d66968ca62d675f6e74184b8ff754d4` | `0f4ac80c…` live | Stage 0.4 + 3.1 |
| 7 | `iiis-1 mhash: d5814a08e9736728da9263e07cfa32053d9c702dd5980ffef72aa694121a0e1e` | `0fb14dde…` live | Stage 0.4 + 3.1 |
| 7 (cont.) | `iiis-1 ≡ iiis-2 byte-for-byte (true fixed-point)` | `0fb14dde…` ≠ `528c0d49…` | Stage 3.3 |
| 13 | `corpus_pass: 250/250` (second value, contradicts line 5) | TBD (Stage 0.7) | Stage 0.7 |
| 13 | `bit_identity: 293/293 (100%)` | TBD (Stage 0.6) | Stage 0.6 + 3.3 |
| 14 | `iiis-1 known gap: NONE` | Multiple gaps known (PE-DIRECT-CALL-DIVERGENCE etc.) | Stage 3.1 |
| also: MHASH-LEDGER.md row above (`iiis-0.exe` = `ac4eec4e…`) | drifts from `0f4ac80c…` live | this same § |

The pre-RITCHIE row at line 12 of this file (`iiis-0.exe` = `ac4eec4ef4b553aa902664e51d44edfddc92e199002afb6d7ae61eaaf72d59bd`) is a third distinct value; it is FROZEN-SPEC commitment text, not a live measurement. Stage 0.4 reconciles it.

---

**§RITCHIE/0.0 sealed at:** 2026-05-20, this commit.
**Next entry:** §RITCHIE/0.1 after deletion of two orphan root files.

---

### §RITCHIE/0.1 — Orphan root files deleted

| Path | Pre-deletion SHA-256 (forensic) | Post-state |
|---|---|---|
| `cg_r3.iii` (0 B, May 7) | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` | DELETED |
| `iii_fs_test.tmp` (5 B, May 19, content "hello") | `2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824` | DELETED |
| `COMPILER/BOOT/cg_r3.iii` (206,016 B real compiler module) | — | UNTOUCHED, verified intact |

Forensic content of `iii_fs_test.tmp` is the deterministic write-target of `STDLIB/corpus/38_fs_write_read_roundtrip.iii` (ASCII "hello"). Next corpus run recreates the file. Follow-up: §NEW-Stage-1.X-corpus-cleanup (add `fs_delete` to stdlib + move path under `STDLIB/build/corpus/`).

**§RITCHIE/0.1 sealed at:** 2026-05-20.

---

### §RITCHIE/0.2 — `_obj_boot` orphan objects catalogued (no deletion)

| Path | SHA-256 | Status |
|---|---|---|
| `COMPILED/_obj_boot/cg_r3_xii.o` (3,209 B, May 11) | `96814981fdb8c0cddabe8b1ad03e4958761a22df330c54929970890d8c84eab0` | STALE (source `cg_r3_xii.c` is May 18 — 7 days newer); will regenerate at Stage 6.11 |
| `COMPILED/_obj_boot/xii_ldil.o` (4,013 B, May 11) | `8630fb7c5db812181c27c4872454a4a9afd43cc19f87b388ba64506a4abfc65c` | STALE (source `xii_ldil.c` is 1 hour newer); will regenerate at Stage 6.11 |
| `COMPILER/BOOT/cg_r3_xii.c` (10,084 B, May 18) | `05c9f3d0e0c6c93fa2c9112542e29491e98d0ae9b9fb0b70698e7f21c14b97d3` | Active source; excluded from iiis-0 build by `! -name '*xii*.c'` filter |
| `COMPILER/BOOT/cg_r3_xii.h` (1,992 B) | `ea7d56f406540c1b42e3aadc5ff1f7f9ccdd77e765b151824fbca77cd264bd5f` | Active source |
| `COMPILER/BOOT/xii_ldil.c` (8,860 B, May 11) | `d5cf11c4e1b2b171dc1d952eb2b2fcdfa48d70aaa50ea0d72dfa95f76755b81a` | Active source |
| `COMPILER/BOOT/xii_ldil.h` (3,522 B) | `e5133cc5bb6716dddfcd715273285f5797969b05b901e309cec0c1c022b29bb6` | Active source |

PE/COFF objects verified Machine 0x8664 (AMD64). Forward integration: **Stage 6.11**.

**§RITCHIE/0.2 sealed at:** 2026-05-20.

---

### §RITCHIE/0.3 — `STDLIB/build/SOURCES.mhash` + `CLOSURE.mhash` rotated to full-coverage seal

**Driver:** New script `STDLIB/scripts/seal_sources.sh` (NIH-clean; uses sha256sum + find + sort + awk + printf + mv + mkdir + wc only). Twin-build verification supported via `--verify`.

| Artifact | OLD (pre-Stage-0.3, stale) | NEW (post-Stage-0.3) |
|---|---|---|
| `STDLIB/build/SOURCES.mhash` line count | 46 modules (covered ≈ 19% of substrate) | **246 modules** (100% coverage) |
| `STDLIB/build/SOURCES.mhash` SHA-256 | `5ba97008066941160b9f5b3e20ea82651ce9d816fdb760861d3755a2b25efeff` | `458d8f5faf5fa3aba44e128040a6a67534543a584053343974e19f954bb0050f` |
| `STDLIB/build/CLOSURE.mhash` content | `50184292fea5e2e46eabf59c578d1ef688eedf3ba787612143394a8557533b20 *build/SOURCES.mhash` | `458d8f5faf5fa3aba44e128040a6a67534543a584053343974e19f954bb0050f *build/SOURCES.mhash` |
| Determinism witness | unverified (hand-rolled, no twin-build) | `--verify` PASS (BIT-IDENTICAL twin-build) |

The new closure root `458d8f5faf5fa3aba44e128040a6a67534543a584053343974e19f954bb0050f` is the substrate's source-side composite identity at the moment of regeneration. It is **append-only**: every subsequent `.iii` add/edit rotates this value; the rotation is captured in a §RITCHIE/N.M sub-row when it occurs.

Per-namespace module counts at sealing:
- aether: 20 · memoria: 5 · numera: 45 · omnia: 100 · sanctus: 23 · tempora: 5 · verba: 48 · **total: 246**.

No external closure pin references the old `5ba97008…` / `50184292…` values (verified by grep before rotation); rotation was safe.

**Reconciled doc claims in this step:**
- `NOTES/ARCHITECTURE.md §1` ("198-module sealed stdlib") → 246.
- `NOTES/ARCHITECTURE.md §2` ("STDLIB/iii/*.iii  198 sealed stdlib modules") → 246.

**Deferred to Stage 1.2 / Stage 0.7:** `STDLIB/iii/SEAL.mhash:4` ("modules: 217") and `LATTICE-CHANGELOG.md` "189 stdlib modules" remediation — those rotations belong with the broader SEAL.mhash rewrite (Stage 0.7).

**§RITCHIE/0.3 sealed at:** 2026-05-20.

---

### §RITCHIE/0.4–0.6 — Golden mhash drift resolved; iiis-0 determinism proven

**Read-gate correction:** The §RITCHIE/0.0 baseline mislabeled two STALE ORPHAN copies as the goldens. The build scripts enforce goldens at `COMPILER/BOOT/iiis-N.mhash`, which were always correct:

| Build-enforced golden | Value | Matches live? |
|---|---|---|
| `COMPILER/BOOT/iiis-0.mhash` | `0f4ac80c48410efd7f7c34bb9f6a8a2ae00a01c36c70b8616d4aea3db7526e26` | ✓ (== live + deterministic twin-build) |
| `COMPILER/BOOT/iiis-1.mhash` | `0fb14ddee9bd06a05f01b448926784b53d7a578bd2b84f33b2a29740fd7e7b8a` | ✓ |
| `COMPILER/BOOT/iiis-2.mhash` | `528c0d49bf82338cea3090ccc39103a3a9d795812516598fa2ca25f0aa51bf7b` | ✓ |
| `COMPILER/BOOT/iiis-3.mhash` | ABSENT | gap → Stage 5.5 |

**Deleted stale orphans (forensically pinned in §RITCHIE/0.0):**
- `COMPILED/iiis-0.mhash` (`210985ec1f62ec8e…`, May 8 — referenced by zero build scripts)
- `COMPILED/iiis-1.mhash` (`a4eca281a472cddc…`, May 7 — referenced by zero build scripts)

**Determinism witness (Stage 0.6):** `build_iiis0.sh --check-deterministic` → A == B == `0f4ac80c…`, exit 0. BIT-IDENTICAL. Toolchain gcc 15.2.0 + ld 2.45 matches witness JSON.

**Remaining COMPILED/*.mhash after cleanup (all build-generated determinism witnesses, all correct):**
- `COMPILED/iiis-0.exe.mhash` = `0f4ac80c…`
- `COMPILED/iiis-1.exe.mhash` = `0fb14dde…`
- `COMPILED/iiis-2.exe.mhash` = `528c0d49…`
- `COMPILED/iiis-3.exe.mhash` = `8be5bf34…`

**§RITCHIE/0.4–0.6 sealed at:** 2026-05-20.

---

### §RITCHIE/0.7 — Full corpus GREEN + count reconciled + benchmark defect fixed

**Conformance corpus (post-§0.7-FIX):** `PASS=254 FAIL=0 SKIP=98 TOTAL=254` (94 XII + 4 perf benchmarks delegated). **Bench corpus:** 4/4 correctness, timing host-advisory (CORRECTNESS-FAIL=0).

**Root cause of the 4 prior "failures":** NOT substrate defects — absolute RDTSCP-overhead-inclusive cycle budgets (3.6 GHz-reference-calibrated) used as hard conformance gates. Substrate correctness proven (242 PE-narrows: 2 `III_PE_DIRECT` markers == passing 232; 235/238 resolver parity; all KATs).

**Fix:** new `STDLIB/scripts/run_bench_corpus.sh` (correctness hard-gated, timing advisory); `run_corpus.sh` delegates 237/242/243/244 (SKIP, like XII); `run_all_corpora.sh` wired. Optimization-regression detection preserved via 232/235/238 in conformance corpus.

**Count drift reconciled (Contract C13) — all four sites now agree at 254:**
| Artifact | Rotation |
|---|---|
| `STDLIB/iii/SEAL.mhash` | "243/243"+"250/250"+"modules:217" → "254/254 conformance, 0 fail" + "modules:246"; iiis-mhash/fixed-point claims flagged STALE→Stage 3.3 |
| `run_all_corpora.sh` | "179 stdlib tests" → "254 correctness tests" + bench corpus wired |
| `NOTES/ARCHITECTURE.md` | reconciled in §RITCHIE/0.3 (198→246, 179→375) |

**§RITCHIE/0.7 sealed at:** 2026-05-20.

---

### §RITCHIE/0.8 — 32 R1 subsystem test baselines (all green)

34 subsystem test binaries run (32 R1 dirs; R2-GENESIS Verilog-only): **34/34 exit 0, 0 failures substrate-wide.** Notable: CONSTANTS 20911, ERRORS 2175, PHASES 120, PORTABILITY 114, GRAMMAR 97 (positive drift — audit said 89/8; the 8 GRAMMAR failures are already fixed → Stage 1.25–1.32 likely no-ops). Full table in CONVERGENCE-AUDIT.md §0.8.

**§RITCHIE/0.8 sealed at:** 2026-05-20.

---

### §RITCHIE/0.9 — Composite R1 constitutional root (FIRST AUTHORITATIVE PIN)

The substrate's constitutional identity, never before materialized (III-INDEX.md gives the formula; the value was pinned nowhere — grep-confirmed):

**R1 = `320a2b99bb5b29e7d5f7dd40941d610d748a7289d1a00585ba5b1135b593e616`**

= `SHA-256(R1.A1 ‖ R1.A2 ‖ … ‖ R1.C1 ‖ R1.IDX)` over the 480-byte concatenation of the 15 R1-sealed-doc SHA-256 hashes (canonical form = raw bytes; CR not stripped). Verified against 4 subsystem-pinned R1.X constants (A1 LEXICON, A5 CYCLES, A7 PHASES, A8 SANCTUM).

Component R1.X table:
| Slot | Doc | R1.X |
|---|---|---|
| A1 | III-LEXICON.md | `2c140927e2972a4478c397f0f6c931c241065d4a0e54db74502f79bf9324c297` |
| A2 | III-GRAMMAR.bnf | `aabc2afc0d6d6762d24ec2742ac47dbf3bde5603495124474fdb6e1667c9a272` |
| A3 | III-TYPES.md | `30d2eb52ad1b59528ec8471b0989b2f3aebba18fdc7242950c1675e0b4dcf45f` |
| A4 | III-EFFECTS.md | `7170f84bf96d6f198eff16e846368594a9a2b4d00d1af6f34d31357c2b5065d2` |
| A5 | III-CYCLES.md | `3627e2adca6f6e43a04ff3d69c35f7a2f8eaa7dc1859306ebd48b5e79acc77a9` |
| A6 | III-HEXAD.md | `941118aa87788b1d1aa916b57810a4d9c70f78978895035694020bae45f84673` |
| A7 | III-PHASES.md | `8f3ff2e175a282dd24036224a97e4d67d5f58c298ea734294b9ba0d51edee1c9` |
| A8 | III-SANCTUM.md | `8d0ba7ac9885295fa7046a3a2b0e1dfae1755e22a4fa297279b29e452fe8c548` |
| A9 | III-TRINITY.md | `9de3c34e002e79a8ca2ef3d15d6570be5eb29109d740843de683287f4e68f63c` |
| A10 | III-MODULES.md | `1c9758a6df4200ca0db5d92cbc0c0d3a1d30cd9fb6b0240da66bde7f622b65fa` |
| B1 | III-CATALYST.md | `4e1b45e807e60993ed3bc65a62120ae3418101901490814c39366f3d3f284296` |
| B2 | III-FEDERATION.md | `a464fdec1ab8d63746c3de938104133266dd3fcdc33ea971271b693ec1c455f5` |
| B3 | III-CONFORMANCE.md | `a294e9307a954375fbadd2d35b831ad603a2acfbdf480fe653009d3bce832a3f` |
| C1 | III-ABI.md | `46fda7d288c538d425a061e704794a18954f74261fee3f078570b16f398f811c` |
| IDX | III-INDEX.md | `6c7fb195ff3da49e1276e3b32c64e92afa6c151bd863fcd52e1b0623b9510b03` |

**R1-bump pending:** Stage 1.1 edits III-CONFORMANCE.md (C30→C33) → rotates R1.B3 → rotates composite R1. The post-amendment R1 will be re-pinned as §RITCHIE/1.1 with the bump rationale (III-INDEX.md §15 amendment discipline).

**§RITCHIE/0.9 sealed at:** 2026-05-20.

---

## STAGE 0 — SEALED (2026-05-20)

All §0.0–§0.9 sealed. Substrate baseline pinned, deterministic, source-sealed (246 modules), docs reconciled, conformance GREEN (254/0/98), 34 subsystem suites green, constitutional R1 materialized. RITCHIE execution proceeds to Stage 1.

---

### §RITCHIE/1.1 — CONFORMANCE C30→C33; R1.B3 + composite R1 amended

First code change of the convergence. `CONFORMANCE` extended 30→33 criteria (added Resolution group C-31/32/33 per FROZEN SPEC III-RES-FROZEN-001 §14). Test: **52 passed, 0 failed** (was 44). III-CONFORMANCE.md §0 reconciled to §6 (both now "Thirty-three").

**R1 amendment (III-INDEX.md §15 amendment discipline):**
| Hash | Before (§RITCHIE/0.9) | After (§RITCHIE/1.1) |
|---|---|---|
| R1.B3 (III-CONFORMANCE.md) | `a294e9307a954375fbadd2d35b831ad603a2acfbdf480fe653009d3bce832a3f` | `b25ec05e96225cede5eba8651cbce11c57d857b446ff6597f68caed103a48e40` |
| **Composite R1** | `320a2b99bb5b29e7d5f7dd40941d610d748a7289d1a00585ba5b1135b593e616` | **`f62f605a35e3b2204d5bf9fd03653f1a0c67754ca92129ed3c2d957e7c87db72`** |

The other 14 R1.X components are unchanged. No C constant pins R1.B3 or the composite R1 (grep-verified) → no downstream drift. The §RITCHIE/0.9 composite is the pre-amendment value (historical); **`f62f605a…` is the current composite R1.**

**§RITCHIE/1.1 sealed at:** 2026-05-20.

---

### §RITCHIE/1.20 — IRPD table dedup (BOOT compiler); chain goldens rolled

First bootstrap-compiler change. `sid.c`'s `SID_METHOD_TABLE` (17 write-side) + `sema.c`'s `SEMA_IRPD_METHODS` (20 names) deduplicated into one canonical `III_IRPD_METHODS` table in the new `COMPILER/BOOT/irpd_methods.h`. **Behavior-preserving** (corpus 254/0 twice; iiis-1 byte-identical proving iiis-0 codegen unchanged).

**Chain goldens rolled (Contract C11; all verified golden==live):**
| Artifact | Before | After |
|---|---|---|
| `COMPILER/BOOT/iiis-0.mhash` | `0f4ac80c48410efd7f7c34bb9f6a8a2ae00a01c36c70b8616d4aea3db7526e26` | `26da70adc9e1da8259b8c531ce2041b1a05331a8fa04ac45c187a2de86c1e5f2` |
| `COMPILER/BOOT/iiis-1.mhash` | `0fb14ddee9bd06a05f01b448926784b53d7a578bd2b84f33b2a29740fd7e7b8a` | unchanged (byte-identical) |
| `COMPILER/BOOT/iiis-2.mhash` | `528c0d49bf82338cea3090ccc39103a3a9d795812516598fa2ca25f0aa51bf7b` | `5e6728692e49985b894301df723b8d560fb9ea7153d010575dc81183f144d203` |
| `STDLIB/build/iii/libiii_native.a` | `37a6581a1ac608a6bc4205c219962a2f7d14939042abdce88d5efe0fdf404932` | `9f9ad9a54d0752bef6c11761d20884060145ab9c4b12f9aa60ff080c29c7864c` |

**Determinism note:** iiis-0 `--check-deterministic` BIT-IDENTICAL; iiis-2 deterministic given libiii_native.a (2 consecutive builds 0-diff). iiis-2 links the stdlib (XII-aware compiler), so `iiis-2 = f(iiis-1, libiii_native.a)` — the transient `80b934469a586e3c…` was a build-ordering artifact (iiis-2 built against the pre-rebuild stdlib), NOT non-determinism.

**iiis-3** (`8be5bf34…`, golden ABSENT) now built from the pre-§1.20 chain → doubly-stale; production rebuild + golden = Stage 3.3/5.5.

**§RITCHIE/1.20 sealed at:** 2026-05-21.

---

### §RITCHIE/1.X-corpus-cleanup — fs_delete shipped; stdlib + sources rotated

`fs_delete(cap_id, path)` added to `STDLIB/iii/aether/fs.iii` (cap-gated WRITE, MSVCRT `_unlink`). corpus 38 now exercises it + self-cleans (no repo-root residue). Stdlib rebuilt (FAIL=0), corpus 254/0.

| Artifact | Before | After |
|---|---|---|
| `STDLIB/build/SOURCES.mhash` / `CLOSURE.mhash` | (pre-§1.X) | `5fa464d05443ba76a7ab6dc5968a00d62b95b6daa83ea7b94e75c757756d6607` |
| `STDLIB/build/iii/libiii_native.a` | `353b8522…`-was-`9f9ad9a5` | `353b8522f95503c6847041585a28cd0389bd495f4225096a4ca16d862a96a7ae` |
| `COMPILER/BOOT/iiis-2.mhash` | `5e672869…` | **unchanged** (iiis-2 selective-links the stdlib; never references fs_delete) |

**Determinism:** libiii_native.a stable across 2 rebuilds + fixpoint stable (rebuild with new iiis-2 → same). iiis-2 deterministic.

**§RITCHIE/1.X sealed at:** 2026-05-21. **✅ STAGE 1 COMPLETE.**

---

### §RITCHIE/2.1 — lex.c → lex.iii full port; iiis-1 lexer swap (lex_impl.c dropped)

`lex.c` (2023 LOC C) fully ported to `lex.iii` (2317 LOC, 27 @exports) — every public lex ABI function (`iii_lex_create/destroy/next/peek/error_*/token_*/locate/span_union/register_keyword/seal/...`) plus token+stream+arena mhash, intern table, 4-pool... arena, error-message NUL-pool. Byte-equivalence proven vs lex.c: **57/57 stage1_corpus** files produce byte-identical token streams + stream-mhash + arena-mhash; per-token mhash, errors (NUL-pooled messages), and all accessors byte-identical. `build_iiis1.sh` now drops `lex_impl.c` (the byte-renamed C lexer) — lex.iii @exports the symbols. One module-const collision fixed: lex.iii `ERR_BYTES`(24) vs link.iii `ERR_BYTES`(48) → renamed lex.iii's to `LEX_ERR_BYTES` (module-const-global trap).

| Artifact | Before | After |
|---|---|---|
| `COMPILER/BOOT/iiis-1.mhash` | `0fb14ddee9bd06a05f01b448926784b53d7a578bd2b84f33b2a29740fd7e7b8a` | `eb1355d8ad9f7fe67a3cac151e264c250cfe11e4cc685267e1e6c4c51ba4c184` |

**DRIFT rationale (Contract C11):** legitimate — the lexer's machine code changed from gcc-compiled `lex_impl.c` to iiis-0-compiled `lex.iii`. Golden rolled **only after** the `--check-corpus` fixpoint (**iiis-0 ≡ iiis-1: 57 passed, 0 failed**) proved the new binary correct. **Determinism:** twin build produced `eb1355d8…` both times; golden verify OK on the confirming rebuild.

**iiis-2 / iiis-3:** NOT yet rebuilt from the new iiis-1 (full chain reconvergence is Stage 2.9 / 3.3 per plan sequencing; ast/parse/main still use their `_impl.c` until Stage 2.2-2.4). iiis-2 golden `5e672869…` unchanged on disk; run_all_corpora uses the stdlib compiler lineage, unaffected by the iiis-1 lex swap.

**§RITCHIE/2.1 sealed at:** 2026-05-21.

### §RITCHIE/2.2 — ast.c → ast.iii full port; iiis-1 ast swap (ast_impl.c dropped)

`ast.c` (2849 LOC C) fully ported to `ast.iii` (3743 LOC, ~88 @exports) — the entire AST public ABI: 4-pool Merkle DAG (create/destroy/alloc_node/pool dispatch), 79-arm canonical-bytes serializer + open-addressed hash-cons + intern (content identity), position arena (5 accessors), string/list arenas (+ open-list), get/get_mut/node_count/pool_count, kind_name (NUL-pool), binder/doc side-tables, checkpoint/rollback (>8-byte sret+by-ref struct ABI), iterate_children + walk_pre/walk_post (5-arg indirect callbacks + fn-address + forward refs/mutual recursion — all proven iiis-0 capabilities), zipper, resumable walk-state (+ serialize/deserialize, pre-order bug mirrored), diff, annotations (FNV phase-hash + interned arena + open-addressed slots — load-bearing for proof.iii/sid.iii), user-kinds, and serialize/deserialize/debug_dump (FILE* via 8 new lex_runtime wrappers). **Every sub-step (§2.2.1-2.2.24) diffed byte-for-byte against ast.c** via standalone harnesses (built with ast.c, then ast.iii.o+lex_runtime.c). One module-const collision fixed: `III_TRIT_AST_{NEG,ZERO,POS,INVALID}` (ast.iii vs hexad_check.iii) → removed from ast.iii (unused; owned by hexad_check). Systematic 299-vs-2749 cross-module audit confirmed it was the only collision.

| Artifact | Before | After |
|---|---|---|
| `COMPILER/BOOT/iiis-1.mhash` | `eb1355d8ad9f7fe67a3cac151e264c250cfe11e4cc685267e1e6c4c51ba4c184` | `e51fea450708bb30d6ef531c349096e8d2a74a291a06db38636386fb095a9d6a` |

**DRIFT rationale (Contract C11):** legitimate — the AST module's machine code changed from gcc-compiled `ast_impl.c` to iiis-0-compiled `ast.iii`. Golden rolled **only after** the `--check-corpus` fixpoint (**iiis-0 ≡ iiis-1: 57 passed, 0 failed**) proved the new binary compiles every stage1 program to byte-identical `.o`. **Determinism:** twin build produced `e51fea45…` both times; golden verify OK on the confirming rebuild.

**iiis-2 / iiis-3:** NOT yet rebuilt (full chain reconvergence is Stage 3.3 per plan sequencing; parse/main still use their `_impl.c` until Stages 2.3-2.4; build_iiis2.sh/build_iiis3.sh will need the same `ast_impl.c` drop when those stages run). iiis-2 golden `5e672869…` unchanged on disk; the STDLIB 254/0 it builds is unaffected by the iiis-1 ast swap. ast_impl.c kept on disk (deleted at plan §2.5 with parse_impl.c/main_impl.c).

**§RITCHIE/2.2 sealed at:** 2026-05-21.

### §RITCHIE/2.3 — parse.c → parse.iii full port; iiis-1 parse swap (parse_impl.c dropped)

`parse.c` (3760 LOC C) fully ported to `parse.iii` (3934 LOC, all public `iii_parse_*` functions @exported) — the entire recursive-descent + Pratt parser: parse_state + error queue + FF-recovery + breadcrumb LIFO + 2-token lookahead + witness sink + grammar-extension registries; binop table + grammar_mhash (BIG-ENDIAN fold); the expression+type+pattern+statement SCC (Pratt climb, primary/postfix/unary, hexad-trits, arg/arg_list, all stmts) ported in compile-checked forward-extern batches; all 10 decls (cycle/fn/type/const/extern/mobius/schema/sealed/var/struct) + top_decl + use_decl + module + decl_next + register/unregister. **iii_parse_expression** (7 exprs incl nested-unary recursion-safety) + **iii_parse_module** (full 37-node module) diffed byte-identical vs parse.c. Bug-classes caught + fixed across the port: global-scratch-across-recursion aliasing (6 fns → scalar pos capture), iiis-0 parser-depth limit (shallow helper extraction), module-const collisions ×3 rounds (PA_AST_/PA_UN_/PA_ABI_/PA_COMPROMISE_/PA_SCH_F_ renames), `*/`-in-comment early-close.

| Artifact | Before | After |
|---|---|---|
| `COMPILER/BOOT/iiis-1.mhash` | `e51fea450708bb30d6ef531c349096e8d2a74a291a06db38636386fb095a9d6a` | `64ebbdeb64f9a6d0410fbe91366d8ebd4388e4d2784c34836d74050fa67772af` |

**DRIFT rationale (Contract C11):** legitimate — the parser's machine code changed from gcc-compiled `parse_impl.c` to iiis-0-compiled `parse.iii`. Golden rolled **only after** the `--check-corpus` fixpoint (**iiis-0 ≡ iiis-1: 57 passed, 0 failed**) proved the new binary compiles every stage1 program to byte-identical `.o`. The fixpoint exposed (and forced the fix of) TWO bugs the 8-input harness missed: **(1)** `iii_token_raw_eq` strlen()s its literal but .iii literals aren't NUL-terminated → replaced 18 raw_eq calls with length-explicit `iiip_raw_eq` (pp_strncmp); **(2)** the .iii no-`else` double-`match` re-evaluation trap in parse_if/var_decl/const_decl → capture-once-into-flag. 25/57 → 52/57 → 57/57. **Determinism:** twin build produced `64ebbdeb…` both times; golden verify OK on the confirming rebuild.

**iiis-2 / iiis-3:** NOT yet rebuilt (full chain reconvergence is Stage 3.3; main still uses `main_impl.c` until Stage 2.4; build_iiis2.sh/build_iiis3.sh need the same `parse_impl.c` drop when those stages run). iiis-2 golden `5e672869…` unchanged. parse_impl.c kept on disk (deleted at plan §2.5 with ast_impl.c/main_impl.c).

**§RITCHIE/2.3 sealed at:** 2026-05-21. **✅ self-host front-end lex+ast+parse all ported + fixpoint-verified; only main.c (Stage 2.4) remains C.**

### §RITCHIE/2.4 — main.c → main.iii full port; iiis-1 main swap (main_impl.c dropped)

`main.c` (1315 LOC C) fully ported to `main.iii` (1262 LOC, @exports `main`+`iiip_sig_handler`) — the CLI orchestrator: private FIPS-180-4 SHA-256 (KAT-verified vs `SHA-256("abc")`), file I/O, argv-canon mhash, byte-level dec/hex/string formatting (no printf in .iii), JSON/diag emitters (lex/parse/sema/sid, text|json), ring autodetect, sorted-key build-witness JSON, signal handlers, the full lex→parse→sema→sid→walloc→link→cg→emit pipeline, run_link_only, and `main` (argv parse + link/multi-source/single dispatch + repro-check + witness + print-mhash + seal). Added 8 lex_runtime libc wrappers (fopen/fseek/stderr/stdout/getenv-SDE/clock/signal/exit). 0 symbol collisions (132 names vs 17 modules). `cmp main.c main_impl.c` IDENTICAL.

| Artifact | Before | After |
|---|---|---|
| `COMPILER/BOOT/iiis-1.mhash` | `64ebbdeb64f9a6d0410fbe91366d8ebd4388e4d2784c34836d74050fa67772af` | `410bd7340ae5e85637d45bcd62012228fd924283ed913dfcae84136f188d0886` |

**DRIFT rationale (Contract C11):** legitimate — the orchestrator's machine code changed from gcc-compiled `main_impl.c` to iiis-0-compiled `main.iii`. Golden rolled **only after** the `--check-corpus` fixpoint (**iiis-0 ≡ iiis-1: 57 passed, 0 failed**). The fixpoint exposed (and forced the fix of) a `&local`-out-param SIGSEGV: iiis-0 register-allocates locals, so `&bytes`/`&len` passed to `iii_read_file` were bogus addresses → all 57 segfaulted; fixed by routing out-params through module scratches (the discipline lex/ast/parse used implicitly). **Determinism:** twin build produced `410bd734…` both times; golden verify OK.

**iiis-2 / iiis-3:** NOT yet rebuilt (full chain reconvergence is Stage 3.3; build_iiis2.sh/build_iiis3.sh need the same lex_impl/ast_impl/parse_impl/main_impl.c drops when those stages run). iiis-2 golden `5e672869…` unchanged. The four `*_impl.c` are now byte-identical-duplicate dead code → deleted from disk at plan §2.5.

**§RITCHIE/2.4 sealed at:** 2026-05-21. **✅✅ SELF-HOST FRONT-END FULLY .iii (lex+ast+parse+main); iiis-1 = pure-.iii front-end + .iii codegen + minimal C runtime boundary (lex_runtime.c + the not-yet-ported C TUs).**

### §RITCHIE/2.5 — *_impl.c deleted + iiis-0 seed golden reconciled

Deleted the 4 byte-identical-duplicate `*_impl.c` (lex/ast/parse/main) — dead in both iiis-0 (excludes them) and iiis-1 (drops them). Rebuilding iiis-0 exposed **latent** golden drift: iiis-0 links lex_runtime.c but never calls its `.iii`-runtime helpers (dead-but-linked, no `--gc-sections`), so the FILE*/fopen/fseek/signal/exit wrappers added across §2.1–2.4 silently grew the seed binary; iiis-0 was never rebuilt during those stages. Codegen-invariance proven (iiis-1 rebuilt by new iiis-0 → 410bd734 + corpus 57/0).

| Artifact | Before | After |
|---|---|---|
| `COMPILER/BOOT/iiis-0.mhash` (seed golden) | `26da70adc9e1da8259b8c531ce2041b1a05331a8fa04ac45c187a2de86c1e5f2` | `8f7666168f9ab702c3e7b1b567b33b3aeda8e474134b9cda3180aae11acd44d2` |
| `COMPILER/BOOT/iiis-1.mhash` | `410bd734…` | **unchanged** (codegen-invariant) |

**DRIFT rationale (Contract C11):** legitimate + behavior-preserving — the seed's lex_runtime.o grew by the dead-linked .iii-runtime wrappers; iiis-0's compilation logic (lex/parse/sema/cg from the unchanged C TUs) is byte-identical, proven by iiis-1 = 410bd734 + corpus 57/0 under the new seed. `--check-deterministic` BIT-IDENTICAL (8f766616 twice); normal build verify OK. **Process lesson: rebuild + reseal iiis-0 after ANY lex_runtime.c change.**

**§RITCHIE/2.5 sealed at:** 2026-05-21. **✅ dead-duplicate *_impl.c removed; iiis-0 seed golden current (8f766616) + deterministic; iiis-0 → iiis-1 chain consistent.**

### §RITCHIE/2.6 — cg_rm1.iii → 100% R-1 parity with cg_rm1.c

Brought cg_rm1.iii (R-1 / hypervisor codegen) to byte-for-byte parity with cg_rm1.c, proven by compiling all 57 stage1_corpus programs `--ring R-1 --emit-asm-only` under both iiis-0 (cg_rm1.c) and iiis-1 (cg_rm1.iii) and diffing the `.s`: **57/57 byte-identical.** Six divergences fixed: store-slot load-suffix reuse; `L_sanctum_`→`L_hv_` mangle prefix (call/ident/field) + 7 label prefixes; **u64-div-as-signed-idiv trap** in hex emit (`0xFFFF..FF%16=-1`→`'V'`, fixed via mask+shift); wildcard/ident `cmpq %rax,%rax`; `.ascii` string pool (was `.byte` + uncalled); cycle-decl D8 witness entry/exit instrumentation.

| Artifact | Before | After |
|---|---|---|
| `COMPILER/BOOT/iiis-1.mhash` | `410bd7340ae5e85637d45bcd62012228fd924283ed913dfcae84136f188d0886` | `b1bd7903a49e077a6f24d55c95417a702669975cc78bc645f9a2a00110c797fc` |

**DRIFT rationale (Contract C11):** intentional — cg_rm1.iii.o changed (6 parity fixes). R3 corpus 57/0 (cg_r3 untouched); twin-build BIT-IDENTICAL; golden verify OK. **New compiler trap logged for Stage 3: iiis-0 compiles u64 `%`/`÷` as signed `idiv` (full-width values only; small dodge it).**

**§RITCHIE/2.6 sealed at:** 2026-05-21. **✅ cg_rm1.iii (R-1) at byte-exact parity; iiis-1 = b1bd7903.**

### §RITCHIE/2.7 — cg_rm2.iii → R-2 parity with cg_rm2.c (reachable surface)

Brought cg_rm2.iii (R-2/sanctum codegen) to byte-for-byte parity with cg_rm2.c, proven by all 57 corpus programs `--ring R-2 --emit-asm-only` diffing identical. 2 fixes: header `§` (UTF-8 C2 A7 dropped from RM2_STR_HDR2) + string pool (`.byte`/garbage [old `let mut first` flag = iiis-0 let-mut trap] → cg_rm1's proven `.ascii` read-into-`b`). **emit_function (sealed-call codegen) is unreachable** — `@seal_id` is unparseable in both parse.c+parse.iii (lexer `modifier_pending` vs parser AT+IDENT), so 57/57 covers cg_rm2's whole reachable surface; the latent store-suffix bug + the parse blocker are logged for the grammar-fix stage.

| Artifact | Before | After |
|---|---|---|
| `COMPILER/BOOT/iiis-1.mhash` | `b1bd7903a49e077a6f24d55c95417a702669975cc78bc645f9a2a00110c797fc` | `883afe992d7182a23996b55cef177c8a21a42dc2f2ab36d00cfb401eceff5367` |

**DRIFT rationale (Contract C11):** intentional — cg_rm2.iii.o changed (2 parity fixes). R3 corpus 57/0; twin-build BIT-IDENTICAL; golden verify OK.

**§RITCHIE/2.7 sealed at:** 2026-05-21. **✅ all 4 codegen rings (R3/R0 drove iiis-1; R-1 §2.6; R-2 §2.7) at parity for reachable output; iiis-1 = 883afe99.**

### §RITCHIE/2.8-2.10 — lex_runtime decision + fixpoint standing + 4 static checks → STAGE 2 COMPLETE

- **§2.8 (no rotation):** lex_runtime.c RETAINED — irreducible Contract-C2 C-runtime boundary (raw memory deref, BOOT SHA-256, libc FILE/env/signal); 33/33 exports live, no dead code. Plan's "delete" premise (dialect raw-ops + numera-in-BOOT) false for iiis-0; reconciled. SHA dedup → §4.15.
- **§2.9 (no rotation):** iiis-0 ≡ iiis-1 fixpoint STANDING 57/0 (held after every §2.x reseal).
- **§2.10:** the 4 iiis-1 static type-system checks (cap-flow/intent-kind/K-floor/return-kind) in cg_r3.iii now emit `III_*_VIOLATION` markers (byte-exact with cg_r3.c) + reject — all 4 `test_*_static_negative.sh` PASS.

| Artifact | Before | After |
|---|---|---|
| `COMPILER/BOOT/iiis-1.mhash` | `883afe992d7182a23996b55cef177c8a21a42dc2f2ab36d00cfb401eceff5367` | `6c818ec7232857733afa1174c957aad5c8ae59c4e73a0151f074af0dd1305d88` |

**DRIFT (§2.10, Contract C11):** intentional — cg_r3.iii.o changed (4 marker emissions; fire only on invalid programs, so R3 corpus 57/0 unchanged); twin-build BIT-IDENTICAL. **Stage-3 backlog:** PE-direct divergence (262-264 body, task #44/§3.1); u64-div-as-signed trap (§2.6).

**§RITCHIE/2.8-2.10 sealed at:** 2026-05-21. **✅✅✅ STAGE 2 COMPLETE — self-host front-end fully .iii; all codegen rings at parity; static type-system checks live; iiis-0≡iiis-1 fixpoint 57/0; iiis-1 = 6c818ec7.**

### §RITCHIE/3.1-3.2 — PE-direct verified closed; u32 mod-2³² truncation fixed (masks removed)

- **§3.1:** PE-DIRECT-CALL-DIVERGENCE (task #44) verified CLOSED — inline pe_hit impl byte-identical iiis-0≡iiis-1 on 100/100 omnia + ai_resolve/transform. No code change (doc reconciled).
- **§3.2:** the iiis u32 mod-2³² truncation defect — cg_r3 truncated u32 only after `shlq`, not `addq/subq/imulq`, so SHA-256's schedule adds leaked into bits 63..32 (H1 LOCAL, disassembly-proven; the plan's "cross-TU" premise was wrong). **Fix:** expr_is_u32-gated `movl %eax,%eax` after ADD/SUB/MUL in BOTH cg_r3.c + cg_r3.iii (byte-mirror of the existing SHL truncation). Removed 36 sha256 + 10 blake2s source masks. FIPS 02=186/15=227/151=99/83=80 PASS via codegen (NOT masks); 145/145 numera+omnia iiis-0≡iiis-1; corpus 254/0. **Resolves the prior FIPS-break (memory guardrail); a permanent compiler correctness fix.**

| Artifact | Before | After |
|---|---|---|
| `COMPILER/BOOT/iiis-0.mhash` (SEED) | `8f7666168f9ab702c3e7b1b567b33b3aeda8e474134b9cda3180aae11acd44d2` | `da4eb354272d7c9e3f4858e76d10d6af6a90990f67c10d187711a6818a543667` |
| `COMPILER/BOOT/iiis-1.mhash` | `6c818ec7232857733afa1174c957aad5c8ae59c4e73a0151f074af0dd1305d88` | `6a7d0d991617693e0faa81b290e1f4b8872279d2b94d1dcbc3c7adcdf16326f3` |
| `STDLIB/build/iii/libiii_native.a.mhash` | (pre-§3.2) | `02022fb4c944ad8d6c0d821e03cbf6404cc9fd846ff1748d0a23375b099c03fd` |
| `STDLIB/build/CLOSURE.mhash` | (pre-§3.2) | `14f8c3fa374d3df2c3a4e103ebfa48ae2cc1cab7753ea0fe4d0eb3dd3b3ba186` |

**DRIFT (Contract C11):** intentional — cg_r3.c (→iiis-0 SEED) + cg_r3.iii (→iiis-1) gained the ADD/SUB/MUL truncation (every u32 arith .o changes); sha256/blake2s lost their masks. Two-phase verified (Phase A movl-safe, Phase B masks-redundant); twin-build BIT-IDENTICAL both stages.

**§RITCHIE/3.1-3.2 sealed at:** 2026-05-21. **✅ PE-direct closed; u32 mod-2³² truncation is a compiler-level fix; iiis-0=da4eb354, iiis-1=6a7d0d99, lib=02022fb4. iiis-2/3 chain reconvergence → §3.3.**

### §RITCHIE/3.3 — iiis-2 ≡ iiis-3 fixed point achieved; full self-host chain converges

Rebuilding the chain on the new iiis-1 exposed a Stage-2.4 regression: main.iii's private SHA-256 emits GLOBAL L-symbols (SHA_K/SHA_W/sha_rotr/sha256_init/update/final) + RING_R0 that collide with STDLIB numera/sha256.iii at the iiis-2 link (iiis-2+ link the STDLIB; iiis-1 doesn't; main.c's SHA was static). Fixed in-place (C15): renamed main.iii's SHA-256 → MSHA_*/msha* + RING_R0 → MRING_R0. build_iiis3.sh was the vestigial clone (§0.5) — added STDLIB link + XII flag + gen/sign exclusion to match build_iiis2.sh. Result: iiis-2 ≡ iiis-3 byte-identical (the fixed point); both deterministic; corpus 254/0 via each.

| Artifact | Before | After |
|---|---|---|
| `COMPILED/iiis-1.mhash` | `6a7d0d991617693e0faa81b290e1f4b8872279d2b94d1dcbc3c7adcdf16326f3` | `e7eb1c891c3f33c5b0d2017f357d5096232e35c2ca43baf33ef9564874cce13e` |
| `COMPILED/iiis-2.mhash` | (pre-§3.3 5e672869) | `442cbb9796b75f23a770b6f0fd903767178b3d43f16cca06e119ff85d6c979f2` |
| `COMPILED/iiis-3.mhash` | (MISSING — §0.5 gap) | `442cbb9796b75f23a770b6f0fd903767178b3d43f16cca06e119ff85d6c979f2` (≡ iiis-2) |
| `COMPILER/BOOT/build_iiis3.sh` | vestigial (no STDLIB/XII) | production lift (matches build_iiis2.sh, iiis-2 compiler) |

**DRIFT (C11):** iiis-1 re-rolled (main.iii symbol rename — names not codegen; 57/0 preserved); iiis-2/3 newly sealed. All twin-build BIT-IDENTICAL.

**§RITCHIE/3.3 sealed at:** 2026-05-21. **✅✅✅✅ FOUR-STAGE SELF-HOST FIXED POINT: iiis-0(da4eb354)→iiis-1(e7eb1c89)→iiis-2(442cbb97)≡iiis-3(442cbb97). The substrate compiles itself to a byte-identical fixed point. §0.5 missing-golden closed.**

### §RITCHIE/3.4-3.5fdn — cross-fn PE verified; metal{} foundation fixed + AVX-512 proven

- **§3.4:** cross-fn escape analysis (pre-existing in iii_cg_pe_iiis1.c) verified — 272 narrows, new 273_cross_fn_dynamic_intent refuses; corpus 255/0. No reseal (corpus tests + the negative script are outside the SOURCES.mhash closure; no compiler change).
- **§3.5 prerequisite:** metal{} foundation bug fixed — cg_r3.iii read `raw_asm_str_idx` (a source offset) via the string-pool accessor instead of `source_buf+off`; now mirrors cg_r3.c (bounds-checked, +iii_ast_source_len_u32 extern). First-ever STDLIB metal{} use; latent iiis-0↔iiis-1 divergence. AVX-512 `vpxorq` KAT runs correctly (exit 250) byte-identical across iiis-0/1/2/3.

| Artifact | Before (§3.3) | After (§3.5 metal fix) |
|---|---|---|
| `COMPILED/iiis-1.mhash` | `e7eb1c891c3f33c5b0d2017f357d5096232e35c2ca43baf33ef9564874cce13e` | `09df490bfdeccbb26b6d28a9d3d685be673bdb4c3e87f0f59a72989358741f83` |
| `COMPILED/iiis-2.mhash` | `442cbb97…` | `1f9ef051029dd55fde9c986af653b87d2ccb7d9205f49397546c6a4581035cac` |
| `COMPILED/iiis-3.mhash` | `442cbb97…` | `1f9ef051029dd55fde9c986af653b87d2ccb7d9205f49397546c6a4581035cac` (≡ iiis-2) |

**DRIFT (C11):** iiis-1/2/3 rolled (cg_r3.iii metal-emit fix — only affects metal{} programs, of which the corpus has none, so 57/0 + corpus 255/0 unchanged; compiler binary changed). iiis-0 unchanged (da4eb354, uses main.c). libiii_native.a unchanged (no STDLIB metal). All twin-builds BIT-IDENTICAL; iiis-2≡iiis-3 fixed point preserved.

**§RITCHIE/3.4-3.5fdn sealed at:** 2026-05-21. **✅ metal{} foundation works + AVX-512 self-host-stable; iiis-1=09df490b, iiis-2=iiis-3=1f9ef051. The 10 EVEX crypto kernels are the §3.5 continuation.**

### §RITCHIE/3.5k1 — lexer `$` token + ChaCha20 AVX-512 kernel (first §3.5 crypto kernel)

Added `III_TOK_DOLLAR` (append-only, value 128; KIND_COUNT→129) to lex.h+lex.iii+lex.c so metal{} blocks tolerate the AT&T `$` immediate prefix (required by `vprold $N`). Landed the ChaCha20 AVX-512 block kernel (EVEX.128 4-row SIMD) + cpufeat dispatch. KAT 70=16 (AVX path matches RFC 8439); force-scalar≡force-avx512 bit-identical; corpus 255/0; chacha20.o byte-identical iiis-0/1/2/3.

| Artifact | Before | After |
|---|---|---|
| `COMPILED/iiis-0.mhash` (SEED) | `da4eb354272d7c9e3f4858e76d10d6af6a90990f67c10d187711a6818a543667` | `1190d172b209fe42f56fa67d5b0ca24f5ba63a0036ff06995ce20dcb944ab0cd` |
| `COMPILED/iiis-1.mhash` | `09df490bfdeccbb26b6d28a9d3d685be673bdb4c3e87f0f59a72989358741f83` | `7804cea49ebeb14462c68982269870882f9a877cac56fe96737fca8edb646f04` |
| `COMPILED/iiis-2.mhash` = `iiis-3.mhash` | `1f9ef051…` | `36d3ca98c58c43b6f47dbc830bdc05785f73dae583743f80a3dc0b8ddfb8dafe` |
| `STDLIB/build/iii/libiii_native.a.mhash` | `02022fb4…` | `182784d7a85ed42656a010b64440de3f1bedb31a7ba7e21c8ee6e48a389757a3` |
| `STDLIB/build/CLOSURE.mhash` | `14f8c3fa…` | `087d50fa539da99f51f374e13ad6b8abee7a88998f004ca87590bd0cea5a0d34` |

**DRIFT (C11):** lex.c+lex.iii `$` token → iiis-0/1/2/3 rolled (corpus 57/0 + 255/0 unchanged; only compiler binaries). chacha20.iii AVX kernel → libiii_native.a + SOURCES rolled; iiis-2/3 NOT re-rolled by it (unreferenced .o not linked). All twin-builds BIT-IDENTICAL; iiis-2≡iiis-3 preserved.

**§RITCHIE/3.5k1 sealed at:** 2026-05-21. **✅ metal{} foundation complete (`$` lexes); ChaCha20 AVX-512 kernel bit-identity-proven (KAT 70=16 + scalar≡avx). 1/10 §3.5 kernels; pattern established.**

**§RITCHIE/3.5k1b (ChaCha20 AVX2 path):** added `cc20_block_into_ks_avx2` (VEX.128, shift-rotates) → ChaCha20 now full 3-path (scalar/AVX2/AVX-512); 3-path bit-identity exit 88; KAT 70=16; corpus 255/0. `libiii_native.a` 182784d7→**2f8a8a7a17e06a2c8d28bf7041cb6f9ab8da193b5f18d95d59f9e8b18823d8f8**, `CLOSURE` 087d50fa→**c1e0ac182a85df65ed4b25e260b1af9e7daa41e126e166c464a34cb4b74d0f5f**. iiis-0/1/2/3 unchanged. **ChaCha20 = 1/10 fully 3-path complete.**

**§RITCHIE/3.5k2 (BLAKE2s, 3-path):** `b2s_gather_msched` (scalar sigma pre-gather → B2S_MROWS) + `b2s_rounds_avx512` (vprord/ROTR) + `b2s_rounds_avx2` (vpsrld/vpslld/vpor) + dispatcher; same 4-row skeleton as ChaCha20. KAT 83=80; 3-path bit-identity exit 88; corpus 255/0; blake2s.o iiis-0≡1≡2≡3. `libiii_native.a` 2f8a8a7a→**8d391a6c941ac1229de1fe00301c2a32e4785a8026f989301c0a4d01a9be12d6**, `CLOSURE` c1e0ac18→**901e3a01d8c7ccfec8eb5352b2ae190824f563929dadda18be186c3af5376495**. iiis-0/1/2/3 unchanged. **BLAKE2s = 2/10 fully 3-path complete.**

**§RITCHIE/3.5k7+8 (Ed25519 field-mul + X25519 ladder = bigint_mul):** NO mhash rotation. Read-gate (crypt_ed25519.iii/field.iii/x25519.iii) established that this NIH substrate has no dedicated 5×51-bit field — both Ed25519 and X25519 use `field.iii::fp_mul = bigint_mul + bigint_mod`, so their field multiply IS `bigint_mul` (vectorized in §3.5k6). Adding a dedicated 51-bit field would duplicate field arithmetic (anti-bloat) + rewrite working point code (risk), so kernels 7+8 are delivered via the shared vectorized bigint_mul. Validated by new corpus **183** (=88): X25519 RFC 7748 ladder, `bigint_force_path(1)` (scalar) ≡ `bigint_force_path(2)` (avx512) ≡ RFC vector, byte-identical. Existing KATs 59/74/75 (Ed25519) + 73 (X25519) pass via avx512 bigint_mul. corpus 259→**260/0**. lib/SOURCES/CLOSURE/iiis ALL unchanged (corpus-test-only). **Ed25519+X25519 = 8/10 §3.5 complete.**

**§RITCHIE/4.1 (Ed25519 SIGN) — STDLIB lib + CLOSURE roll, iiis UNCHANGED:** added ed25519_sign (@export) + helpers (ed_bi_to_le32, ed_pt_compress, ed_scalar_mul_ct constant-time) to crypt_ed25519.iii. PROVEN: corpus 193 = sign(RFC8032 Test1 seed) == exact RFC 64-byte signature + verifies, =99. corpus 275→**276/0**. iiis-0 f8e13620 / iiis-1 09ab1fb5 / iiis-2=3 587b6b05 UNCHANGED (no BOOT edit). libiii_native.a c06fff8b→**6f7381d2**; SOURCES=CLOSURE 9c9c7a08→**b38645de** (crypt_ed25519.iii sign added). **CRITICAL pre-existing bug surfaced:** ed25519_verify accepts FORGED sigs (eq [S]B==R+[h]A trivially true for S<L; large-scalar path likely degenerate Z → ed_pt_eq 0==0); KATs 59/74/75 only tested valid. **#1 next priority before §4.2. §4.1 verify-fix + Test2/3/1024 KATs + prespec remain.**

**§RITCHIE/4.1b (verify-forgery FIX) — STDLIB lib + CLOSURE roll, iiis UNCHANGED:** root-caused (via temp diagnostic) the verify-accepts-forgeries bug to ARENA EXHAUSTION (256 MiB bump arena overrun by verify's 2 large-scalar muls + 4 decompress modpows → arena_alloc returns 0 → degenerate Z=0 points → ed_pt_eq compares 0==0 → fail-OPEN). FIX: arena_new_call_helper 256 MiB→**1 GiB** + ed_pt_eq FAILS-CLOSED on Z=0 (null bigint). PROVEN: corpus 194_ed25519_verify_tamper (=99: valid=1, R-tamper=0, S-tamper=0); 193 now full sign→verify→tamper→reject (=99); 59/74/75 still 99. corpus 276→**277/0**. libiii_native.a 6f7381d2→**85e3024a**; SOURCES=CLOSURE b38645de→**26471845**. iiis UNCHANGED. **§4.1 sign+verify DONE; Test2/3/1024 sign KATs + prespec remain.**

**§RITCHIE/4.1c (sign RFC KATs 2/3 + long-msg + prespec registration) — full iiis chain roll + lib + CLOSURE:** sign Test2/3 exact-RFC-byte-match (corpus 195/196 =99) + long-message path (197 =99). Registered ed25519_sign_c4 (4-arg packed wrapper, keys=seed‖pk) as composition #141 in iii_compositions.def; regenerated prespec.iii + iii_compositions.h (gen_compositions.sh, 251 entries). The .h feeds cg_r3's PE table → iiis chain ROLLED. C13: corpus 218/234 cardinality 250→251. Verified: iiis-0 deterministic, iiis-0≡iiis-1 57/0, iiis-2≡iiis-3 fixed point, build_stdlib drift-gate current, corpus **280/0**.

| Artifact (golden) | Before | After |
|---|---|---|
| `COMPILER/BOOT/iiis-0.mhash` | `f8e13620…` | `4d236de306d4…` |
| `COMPILER/BOOT/iiis-1.mhash` (bare) | `09ab1fb5…` | `7bb683cfcb48…` |
| `COMPILER/BOOT/iiis-2.mhash` = `iiis-3.mhash` | `587b6b05…` | `5e6aee6a000b…` |
| `libiii_native.a` | `85e3024a…` | `efd03057…` |
| `SOURCES.mhash` = `CLOSURE.mhash` | `26471845…` | `1744b8e7…` |

**§4.1 COMPLETE (Ed25519 sign constant-time + verify-forgery fix + RFC KATs 1/2/3/long + composition registration). Next: §4.2 (Founder's-Anchor swap cosig verify).**

**§RITCHIE/4.3 (PQ round-trip tests + 2 critical impl fixes) — C-ref subsystem; lib roll, NO substrate-golden roll:** wrote round-trip tests for all 9 PQ suites; they surfaced + I root-caused & FIXED two real pre-existing bugs. **ML-KEM (mlkem.c):** zetas table was MONTGOMERY-domain but fqmul is plain → spurious R factor per butterfly, NTT∘INTT≠identity, encaps/decaps ss disagreed. Fixed: plain zetas (mont·R⁻¹, R⁻¹=169). **ML-DSA (mldsa.c):** MakeHint called with wrong operands (`-ct0, HighBits(w-cs2+ct0)` instead of `r0+ct0, w1`) → sign's hint disagreed with verify → verify rejected own sig. Fixed: `make_hint(r0+ct0, w1p)`. PROVEN: low-level probe ML-KEM ss_match=1, ML-DSA verify rc=0; **iii_crypto_test.exe 39→117 passed / 0 failed** (all 9 round-trips). libiii_crypto.a a195c561→**d54c0703**. NIST ACVP vectors (multi-MiB) not hand-transcribable offline; round-trip + FO-agreement + tamper-reject is the in-tree validation. iiis 4d236de3/7bb683cf/5e6aee6a, .iii lib efd03057, CLOSURE 1744b8e7, corpus 280/0 UNCHANGED. **§4.3 done → §4.4 (port PQ stack to .iii).**

**§RITCHIE/4.4.1 (ML-DSA native .iii) — STDLIB lib + CLOSURE roll, iiis UNCHANGED:** wrote numera/mldsa.iii (1201 lines) — full FIPS 204 keygen/sign/verify, unsigned-mod-q (no signed-ordering trap), flat-pool+WORK-poly storage, mldsa-local incremental SHAKE (arbitrary msg). Each layer (NTT, rounding/hint, packers, samplers) standalone-probe-proven; keygen EXACT-MATCH vs C-ref (full pk+sk weighted checksums); sign/verify round-trip + tamper-reject (corpus 198_mldsa_roundtrip=99). Added to build_stdlib MODULES; FAIL=0. **libiii_native.a efd03057→f6a66694; SOURCES=CLOSURE 1744b8e7→97da0bca; corpus 280→281/0.** iiis-0/1/2/3 UNCHANGED (STDLIB-only). Found+worked-around new iiis trap: `(literal<<literal)` in nested paren → partial-hexad misparse (precompute). **Substrate's first native .iii post-quantum signature. Next: §4.4.2 mlkem.iii.**

**§RITCHIE/4.4.2 (ML-KEM native .iii) — STDLIB lib + CLOSURE roll, iiis UNCHANGED:** wrote numera/mlkem.iii (715 lines) — full FIPS 203 keygen/encaps/decaps + Fujisaki-Okamoto, unsigned-mod-q (q=3329), 64-slot pool+WORK. NTT/basemul core (incomplete 7-layer + degree-2 basemul) standalone-probe-proven (poly-mult vs schoolbook negacyclic); encoding (cbd/compress/decompress) + samplers (SHAKE128 rejection / SHAKE256+cbd) + K-PKE + FO (G=SHA3-512, H=SHA3-256, re-encrypt + implicit-reject SS=SHAKE256(z‖ct)) over existing KAT-verified hashes. encaps→decaps ss-AGREEMENT + ct-tamper DIVERGENCE (corpus 199_mlkem_roundtrip=99). Added to build_stdlib MODULES; FAIL=0. **libiii_native.a f6a66694→b9b6a921; SOURCES=CLOSURE 97da0bca→546587d7; corpus 281→282/0.** iiis-0/1/2/3 UNCHANGED (STDLIB-only). **Substrate's second native .iii post-quantum primitive (KEM). Next: §4.4.3 slhdsa.iii.**

**§RITCHIE/4.4.3 (SLH-DSA native .iii) — STDLIB lib + CLOSURE roll, iiis UNCHANGED:** wrote numera/slhdsa.iii (715 lines) — full FIPS 205 keygen/sign/verify, hash-based (no NTT). SHA-256 H_n/PRF/PRF_msg + SHAKE-256 H_msg; 32-byte ADRS in 8-slot pool (slots by call-chain depth, non-re-entrant graph → no collision); WOTS+ → Merkle compute_root → FORS → XMSS → hypertree. Treehash-stack merge via `go`-flag while (trap-safe); parent-hash on stack-contiguous children (in-place). Found new trap: `((1u64<<var)-1)` nested-paren partial-hexad misparse → slh_lowmask helper (bare top-level shift). Round-trip + tamper-reject (corpus 200_slhdsa_roundtrip=99, SLH-DSA-128S, ~18s slow-sign by design). Added to build_stdlib MODULES; FAIL=0. **libiii_native.a b9b6a921→3a915495; SOURCES=CLOSURE 546587d7→50d8e566; corpus 282→283/0.** iiis-0/1/2/3 UNCHANGED (STDLIB-only). **Substrate's THIRD & FINAL native .iii PQ primitive — ALL of ML-DSA/ML-KEM/SLH-DSA now native (W1A5/W2A4 gap CLOSED). Next: §4.4.4 pq_dispatch.iii.**

**§RITCHIE/4.4.4 (PQ dispatch) — STDLIB lib + CLOSURE roll, iiis UNCHANGED:** wrote numera/pq_dispatch.iii (uniform iii_pq_keygen/sign/verify/encaps/decaps(suite,...) → 3 modules; family=suite&0xFFF0). corpus 201_pq_dispatch (3 families + KEM-sign-reject) = 99. **libiii_native.a 3a915495→b2773206; CLOSURE 50d8e566→8761caa9; corpus 283→284/0.** iiis UNCHANGED. **Next: §4.4.5 compositions register.**

**§RITCHIE/4.4.5 (PQ composition register) — FULL iiis CHAIN ROLL (first since §4.1):** added 5 PQ rows (142..146) to iii_compositions.def + 5 `_c4` 4-arg wrappers in pq_dispatch.iii (composition ABI is 4-arg u64×4→u64; sign/verify/encaps overflow args via `ext` ptr). gen_compositions.sh regenerated iii_compositions.h (256) + prespec.iii. iii_compositions.h → cg_r3.c recompile → **iiis-0 4d236de3→573ae109 (twin-build DETERMINISTIC), iiis-1 7bb683cf→718d3abb, iiis-2≡iiis-3 5e6aee6a→fe8606bf (fixed point HELD)**; goldens rolled per ADR-027 (iiis-0 cp; iiis-1/2/3 BARE-extract), rebuild-verify rc=0 each. C13: corpus 218(4)/234(2) 251→256u32. build_stdlib drift-gate PASS FAIL=0; run_corpus 284/0. **libiii_native.a b2773206→54d538b4; SOURCES=CLOSURE 8761caa9→ca2d605d; corpus 284/0.** **§4.4 COMPLETE — PQ stack fully native + composition-registered; iiis self-host re-anchored on the PQ-aware composition table. Next: §4.5 AES-192.**

**§RITCHIE/4.5-4.10 (classical crypto, STDLIB lib+CLOSURE rolls, iiis UNCHANGED):** §4.5 AES-192 (aes.iii +aes192_set_key + mid-key-SubWord bugfix; corpus 202 FIPS197-C.2) lib→4b4e35ca CLOSURE 1f18a621; §4.8 HMAC-SHA-512 KAT (corpus 203 RFC4231, impl pre-existed) corpus 286; §4.6 HMAC-DRBG-SHA-512 (drbg.iii, corpus 204 vs C-ref) lib→e82d7f1f CLOSURE 6a6cf77c; §4.7 RDRAND/RDSEED→DRBG (metal, corpus 205) lib→543148d8 CLOSURE 2a6e70d8; §4.9 XChaCha20-Poly1305 (hchacha20+xchacha20_poly1305.iii, corpus 206) lib→f543e575 CLOSURE 0fa002a3; §4.10 AES-SIV RFC5297 (aes_siv.iii, corpus 207 byte-exact) lib→af22c780 CLOSURE df9ec03f. corpus 290/0. iiis UNCHANGED throughout (all STDLIB-only). Full detail in CONVERGENCE-AUDIT §4.5-4.10.

**§RITCHIE/4.11.1 (native constant-time ECDSA-P256) — STDLIB lib+CLOSURE roll, iiis UNCHANGED:** NIH (crypto.c stubs). 4 modules: fp256.iii (const-time P-256 Montgomery field, n'[0]=1, R²-at-init, Fermat inv; self-test exit99), fn256.iii (scalar field mod n, n'[0] Newton-computed; self-test exit99), ec256.iii (RCB complete add a=-3 + const-time double-and-add-always scalar mul; SELF-TEST k=1/2/3·G x-coords NIST-byte-exact exit99), ecdsa_p256.iii (keygen/sign/verify). corpus 208_ecdsa_p256 (round-trip + sig-tamper + msg-tamper reject) = 99. Added to build_stdlib FAIL=0. **libiii_native.a af22c780→aeff5c44; SOURCES=CLOSURE df9ec03f→64fbd113; corpus 290→291/0.** iiis 573ae109/718d3abb/fe8606bf UNCHANGED. **Next: §4.11 ECDSA-P384 → numera/rsa.iii → wire crypto.c.**

**§RITCHIE/4.2 (real Ed25519 verify in swap-ledger cosig) — C-ref subsystem only; NO substrate-golden roll:** CRYPTO-AGILITY/crypto.c iii_crypto_swap now Ed25519-verifies founder_cosig over the canonical directive (added founder_pk param) instead of a byte-presence check; rejects E_SWAP_DENIED on fail. Test rewritten (valid→OK; zero/wrong-key/wrong-old→DENIED; 2nd valid→OK; rollback). Rebuilt CRYPTO-AGILITY/build: **libiii_crypto.a → a195c561**, iii_crypto_test.exe = **39 passed / 0 failed**. CRYPTO-AGILITY is a C-reference subsystem independent of the self-host: iiis-0/1/2/3 (4d236de3/7bb683cf/5e6aee6a), .iii libiii_native.a (efd03057), SOURCES=CLOSURE (1744b8e7), corpus 280/0 — ALL UNCHANGED. **§4.2 done → §4.3 (PQ round-trip KATs).**

**§RITCHIE/3.18 (module-scope const → module-LOCAL) — full iiis chain roll + lib roll; STAGE 3 SEALED:** reproduced (two modules' `L_SHARED_K` both scl 2 → collision). Disproved the plan's namespacing premise: const_decl has no modifiers field (no @export), consts aren't cross-referenced (tp_* refs are to same-named *functions*), so the minimal fix is local const symbols. Dropped `.global` for const_decl in cg_r3.c + cg_r3.iii (added r3_emit_local_decl_label); GAS L-prefixed labels become local → no symbol → no collision, intra-module RIP refs still resolve. Verified: two-module `ld -r` rc=0 no collision (test_module_const_scope.sh), corpus 192 (=99), iiis-0≡iiis-1 57/0, iiis-2≡iiis-3 fixed point, corpus 274→**275/0** no link failures.

| Artifact (golden) | Before | After |
|---|---|---|
| `COMPILER/BOOT/iiis-0.mhash` | `4027b949…` | `f8e136202112…` |
| `COMPILER/BOOT/iiis-1.mhash` (bare) | `077c1969…` | `09ab1fb593dc…` |
| `COMPILER/BOOT/iiis-2.mhash` = `iiis-3.mhash` | `1407f4df…` | `587b6b050cb4…` |
| `libiii_native.a` | `9b634869…` | `c06fff8b784a…` (const symbols now local) |

SOURCES/CLOSURE 9c9c7a08 UNCHANGED (no STDLIB source edited). **§3.18 complete — STAGE 3 SEALED (all iiis-0/1/2 traps eliminated/proven-fixed: §3.8-3.16 mostly already-fixed reconciliations, §3.11+§3.17+§3.18 real fixes). Next: Stage 4 (crypto-stack completion).**

**§RITCHIE/3.17 (local `var` declarations) — parser-only fix, full iiis chain roll:** discovery: the array-typed STMT_LET codegen already reserves slots, and `let buf:[u8;N]` already works; §3.17 was purely the `var` keyword not being dispatched in statement position. Fix (parse.c + parse.iii mirrored): iiip_parse_let accepts `let`|`var` (var ⇒ mutable); parse_stmt + stmt_is_simple route `var`. Local var arrays + scalars now work; `let` byte-identical. Verified: var array+scalar exit 99, let 123, var_probe.o byte-identical iiis-0(C)≡iiis-1(.iii) = 7135063e, iiis-0≡iiis-1 57/0, iiis-2≡iiis-3 fixed point. New corpus 191_local_var_array (=99), corpus 273→**274/0**.

| Artifact (golden) | Before | After |
|---|---|---|
| `COMPILER/BOOT/iiis-0.mhash` | `ab85ee64…` | `4027b949fb7fd1e236ad91031f17f28138170367d54df6be8fcb9ff950b2a63b` |
| `COMPILER/BOOT/iiis-1.mhash` (bare) | `220531aa…` | `077c1969bf33…` |
| `COMPILER/BOOT/iiis-2.mhash` = `iiis-3.mhash` | `2f8a40ed…` | `1407f4dfbe982d75…` |

**DRIFT (C11):** parse.{c,iii} changed → all 4 iiis rolled. **libiii_native.a 9b634869 + SOURCES/CLOSURE 9c9c7a08 UNCHANGED** (no live local `var` in STDLIB → zero STDLIB codegen change). **§3.17 complete → §3.18 (module-const scope; LAST §3 trap).**

**§RITCHIE/3.14+3.15+3.16 (multi-line fn / em-dash comment / nested comment) — ALL ALREADY FIXED, NO binary roll:** probed each post-§3.11; all gone. §3.14: multi-line fn signatures (params wrapped, `-> ret @export {` own line, 3/5-param) parse + bind correct offsets (ml3=543, ml5=55, ml_attr=7042). §3.15: U+2014 em-dash in `/* */` no longer terminates early. §3.16: `/* a /* b */ c */` depth-counted nesting works. Pinned corpus **188_multiline_fn_decl** + **189_emdash_block_comment** (real U+2014 byte) + **190_nested_block_comment**, all =99. corpus 270→**273/0**. iiis ab85ee64/220531aa/2f8a40ed, lib 9b634869, CLOSURE 9c9c7a08 UNCHANGED. **§3.14/15/16 complete → §3.17 (local var arrays — REPRODUCES, real feature gap).**

**§RITCHIE/3.13 (iiis-0 u32-pointer store width bug) — ALREADY FIXED, NO binary roll:** probe (u32 stored through *u32 ptr adjacent to preserved slots) exit 123 iiis-0 & iiis-2 (no clobber). store_u32 disasm emits `mov %edx,(%rax,%rcx,4)` (4-byte movl scale-4), not 8-byte movq. Pinned: corpus **187_u32_pointer_store_width** (=99). corpus 269→**270/0**. iiis ab85ee64/220531aa/2f8a40ed, lib 9b634869, CLOSURE 9c9c7a08 UNCHANGED. **§3.13 complete → §3.14.**

**§RITCHIE/3.12 (iiis-0 signed-i64 ordering-compare SIGSEGV) — ALREADY FIXED, NO binary roll:** probe (4 ordering ops × i64/i32, pos/neg/zero/equal, incl. `if x >= 0i64` + negatives) runs exit 123 on iiis-0 & iiis-2 — no crash. ge_zero_i64 disasm emits `cmp` + `setge` (SIGNED). Fixed by codegen maturation. Pinned: corpus **186_signed_i64_ordering** (=99; conformance range, since 280+ is XII). corpus 268→**269/0**. iiis ab85ee64/220531aa/2f8a40ed, lib 9b634869, CLOSURE 9c9c7a08 UNCHANGED. C13 follow-on: `!= -1i64` sentinel workarounds (http/http_client/http_server/nl_parse/uri) now revertable but working (Mandate 20). **§3.12 complete → §3.13.**

**§RITCHIE/3.11 Phase 3 (parser-precedence fix) — full iiis chain roll:** fixed the W3 `&GLOBAL[0] as u64` bug at its root (PARSER, not codegen): added `iiip_parse_cast` (a cast level looser than unary) in BOTH parse.c + parse.iii, removed `as` from parse_postfix, routed parse_expr_prec through parse_cast. Now `&x as T` == `(&x) as T`. Bare-form probe exit 123 (was segfault 139); no regression (letmut/arg5/paren'd all 123). New corpus 279_addr_of_index_bare (=99) + 278 (paren'd); corpus 267→**268/0**.

| Artifact (golden) | Before | After |
|---|---|---|
| `COMPILER/BOOT/iiis-0.mhash` | `783b78c6…` | `ab85ee64515216b17d455fc39d8bc807f7b64a9c2fa2b6b9d5fe0bc2fb27e190` |
| `COMPILER/BOOT/iiis-1.mhash` (bare) | `3ec441b8…` | `220531aaf18ab91a334814cdbd621ba2103a983b49155e11ee2e8a55b6221aa6` |
| `COMPILER/BOOT/iiis-2.mhash` = `iiis-3.mhash` | `5490140d…` | `2f8a40ed9001e342…` |

**DRIFT (C11):** parse.{c,iii} changed → all 4 iiis rolled. **Verified:** iiis-0 deterministic; iiis-0≡iiis-1 --check-corpus 57/0 (new C/.iii parsers agree); iiis-2≡iiis-3 fixed point. **libiii_native.a 9b634869 + SOURCES/CLOSURE 9c9c7a08 UNCHANGED** (the 2 `&[] as` matches in STDLIB are comments, not live code → zero STDLIB codegen change). W3 comment reconciliation + @export helper deprecation = tracked follow-on. **§3.11 complete → §3.12.**

**§RITCHIE/3.11 Phase 1/2 (`&GLOBAL[0]` quirk → ROOT-CAUSED as parser precedence) — NO binary roll:** CRASH-PROTOCOL reproduce: bare `&G[i] as u64` SEGFAULTS (exit 139) iiis-0+iiis-2 (REAL bug, unlike §3.8/3.9). Phase-2 disasm: emits `movzbq (base,idx,1)` (value load) not `lea` → wild addr. Root cause is PARSER PRECEDENCE (not codegen, correcting the plan premise): `as` parsed in iiip_parse_postfix (tighter than unary `&`), so `&G[0] as u64` = `&(G[0] as u64)` → `&`-of-rvalue → value load. The PAREN'D `(&G[0]) as u64` reaches the correct addr-of-index codegen (`lea (base,idx,stride)`) and works (exit 123). Pinned: corpus **278_addr_of_index_paren** (=99). corpus 266→**267/0**. iiis 783b78c6/3ec441b8/5490140d, lib 9b634869, CLOSURE 9c9c7a08 UNCHANGED. **Phase 3 (parser fix: parse_cast level, `as` looser than unary; blast radius 0 `*p as`/2 `&[] as`; full-chain reseal; bare-form corpus 279; retire W3 workarounds) is the focused continuation.**

**§RITCHIE/3.10 (5+-arg workaround "reversion" → RECONCILED as composition ABI) — lib + CLOSURE roll:** CRITICAL read-gate finding overturned the plan's premise: the 14+ packed 4-u64-arg signatures are the **composition-dispatch ABI** (registered fns are invoked via the uniform prespec `fn(a,b,c,d:u64)` trampoline), NOT pure-trap workarounds — reverting them to 5+ args would break dispatch (trampoline passes 4 u64s; extras read garbage). Per-site: 6 glyph `*_pack` + governance/hw_offload composition-registered (4-arg REQUIRED); glyph_enum/vec form-family; calculus _calc_set spill-copy now-redundant; keccak_absorb/merkle pure-trap retained (Mandate 20); json_match_keyword_5 dead C4 stub DELETED. Action: reconciled all 13 misleading "avoids the trap" comments to state the real composition/form ABI reason + do-NOT-widen + trap-fixed-§3.9; deleted the json stub. NO signature reverts (would break composition / churn working code). All affected KATs pass (json/sha3/keccak/merkle/glyph), corpus 266/0. `libiii_native.a` 83daec42→**9b634869b11e** (json deletion; comments codegen-inert), `SOURCES`=`CLOSURE` b655251e→**9c9c7a08feff33d979d3231677aa22d5f98a7e03240a7fa0b7f7d1caf2933506** (246 modules). iiis 783b78c6/3ec441b8/5490140d UNCHANGED. **§3.10 complete → §3.11 (&GLOBAL[0] quirk).**

**§RITCHIE/3.9 (iiis-0 5+-arg parameter-spill bug) — ALREADY FIXED, NO binary roll:** probe (f5/f6/relay6, single-use params, the documented worst case) runs exit 123 on iiis-0 & iiis-2; f6 disasm shows the prologue unconditionally spills all 4 register params (rcx/rdx/r8/r9 → -0x8/-0x10/-0x18/-0x20) + copies the 5th/6th caller-frame args (0x30/0x38) into local slots, use-count-independent. Reconciled: added corpus **277_arg5_param_spill** (=99). No compiler edit; iiis 783b78c6/3ec441b8/5490140d, lib 83daec42, CLOSURE b655251e UNCHANGED. corpus 265→**266/0**. §3.10 will revert the 14+ STDLIB packed-arg workarounds (lib roll then). **§3.9 complete → §3.10.**

**§RITCHIE/3.8 (iiis-0 `let mut` checkpoint-flag bug) — ALREADY FIXED, NO binary roll:** CRASH-PROTOCOL reproduction shows the documented stale-flag bug does NOT reproduce — a 4-shape probe runs exit 123 (all 10 assertions) on BOTH iiis-0 and iiis-2, and the `c1` disassembly proves `let mut` locals are memory-backed (`-0x10(%rbp)`) with store-then-reload (init store 0x1b, conditional store 0x4d same slot). Fixed by codegen maturation in §2/§3, not this step. Reconciled (C13): added corpus **276_let_mut_checkpoint_flag** (=99, permanent regression pin) + updated the stale `cg_r3.iii:846` workaround comment (codegen-inert — rebuilt iiis-1 = 3ec441b8 unchanged, --check-corpus 57/0, iiis-2=3 = 5490140d fixed point). iiis-0/1/2/3 (783b78c6/3ec441b8/5490140d), lib 83daec42, CLOSURE b655251e ALL UNCHANGED. corpus 264→**265/0**. **§3.8 complete → §3.9 (5+-arg spill: reproduce first).**

**§RITCHIE/3.7 (iii_compositions.def → prespec.iii drift gate) — NO binary roll:** added `gen_compositions.sh --check` (regenerate to temps, byte-compare iii_compositions.h + prespec.iii to on-disk, modify nothing, exit 3 on drift) + a `build_stdlib.sh` pre-build gate (drift → build fails). Proven: in-sync rc=0 (build proceeds, lib unchanged); injected-junk rc=3 ("DRIFT"); restore byte-exact. Single-source-of-truth pair pinned (rotate together when the .def changes):

| Artifact | mhash (pinned 2026-05-21) |
|---|---|
| `COMPILER/BOOT/iii_compositions.def` | `7a1c5fa72e93df39ce22e05666a0a083c7ef952d1299d1d566242975c40c35c8` |
| `STDLIB/iii/omnia/prespec.iii` | `ea28e195d42b93a62bfaa748498385d2daf69317a232ac4b4a465e8efa768470` |

Changed files = gen_compositions.sh + build_stdlib.sh (build-discipline only). iiis-0/1/2/3 (783b78c6/3ec441b8/5490140d), lib 83daec42, CLOSURE b655251e ALL UNCHANGED (no .iii/.c source touched). corpus 264/0. **§3.7 complete → §3.8 (compiler-trap eliminations begin).**

**§RITCHIE/3.6 (iiis-2 type-alias MULTI-HOP resolution) — full iiis chain roll:** first compiler-codegen change since §3.3. Replaced single-hop with a depth-8 chain walk in BOTH `cg_r3.c` (iiis-0) and `cg_r3.iii` (iiis-1+) — `type_node_extract_u64` now walks `type C=B=A @mod` to fixpoint. Bit-identical for non-multi-hop programs (associative regroup). New corpus 274 (positive 3-hop, =99) + 275_neg (distinguisher: 3-hop param vs mismatched arg → III_INTENT_KIND_VIOLATION, only multi-hop catches it) + test_type_alias_multihop_negative.sh.

| Artifact (golden) | Before | After |
|---|---|---|
| `COMPILER/BOOT/iiis-0.mhash` | `1190d172…` | `783b78c6fad3cfc80451d229290b8c92f1803ba71c967aed8999b478f10cbb56` |
| `COMPILER/BOOT/iiis-1.mhash` (bare) | `7804cea4…` | `3ec441b80ca1ce4e394360ddc390102fc7c92fc0f08cfc79696ca0586b03a16f` |
| `COMPILER/BOOT/iiis-2.mhash` = `iiis-3.mhash` | `36d3ca98…` (live; golden was stale) | `5490140d30a1b9bc2e634176f3048b3a9bc5cba80e8eed98fa83110ba4f10d07` |

**DRIFT (C11):** cg_r3.{c,iii} changed → all 4 iiis stages rolled (the build's golden-assert is the gate; rolled per ADR-027). **Verified:** iiis-0 --check-deterministic BIT-IDENTICAL; iiis-0≡iiis-1 (--check-corpus 57/0 + 274.o byte-identical ef836e1a, proving C/.iii multi-hop agree); iiis-2≡iiis-3 fixed point (5490140d); corpus 264/0; 275_neg rejected (rc=14+marker). **libiii_native.a 83daec42 + SOURCES/CLOSURE b655251e UNCHANGED** (cg_r3 is COMPILER/BOOT, not STDLIB/iii; no STDLIB module uses multi-hop aliases → STDLIB codegen unperturbed). **§3.6 complete → §3.7.**

**§RITCHIE/3.5k9+10 (SHA-256 + SHA-512 message schedule, AVX-512) — §3.5 SEALED:** vectorized the message-schedule σ0 prior-word part 4-wide (regroup so the SIMD part is dependency-free; σ1 stays scalar). sha256: `_sha_sched4_avx512` (EVEX.128 xmm: vprold/vpsrld/vpxord/vpaddd) + scalar baseline + dispatcher + `sha256_sched_force` @export; 12 groups. sha512: analogous EVEX.256 ymm (vprolq/vpsrlq/vpxorq/vpaddq), 16 groups, `sha512_sched_force` @export. New corpus 184 (SHA-256 abc) + 185 (SHA-512 abc), scalar≡avx512≡FIPS. Correct first build (regroup is provably bit-identical; integer add associative). All SHA + consumers pass (02/15/55/56/79/81/86 + 184/185=88); corpus 260→**262/0**; sha256.o 7c976ccc + sha512.o a5716aaa byte-identical iiis-0≡1≡2≡3. `libiii_native.a` 6b1dfa00→**83daec421232…**, `SOURCES`=`CLOSURE` 057151b3→**b655251e696b0d0ffcb5480e06665637439c795debfdfd89cee808ab8f628bf8** (246 modules). iiis-0/1/2/3 unchanged (compiler uses its own C SHA, not STDLIB sha256/512.iii). **§3.5 COMPLETE — 10/10 kernels (ChaCha20, BLAKE2s, GHASH, Poly1305, Keccak-χ, BigInt-mul, Ed25519=bigint_mul, X25519=bigint_mul, SHA-256, SHA-512). Next: §3.6.**

**§RITCHIE/3.5k6 (BigInt mul, AVX-512 vpmullq+vpmuludq):** vectorized the 64×64→128 partial-product (the shared hot path of both bigint_mul_u64 and bigint_mul) 8-wide: `_big_mul8_avx512` (metal: vpmullq for prod_lo, 4× vpmuludq + scalar's exact recombination for prod_hi) + `_big_mul8_scalar` baseline + dispatcher + `bigint_force_path` @export; both multiplies rerouted to a scalar group-loop (8-wide SIMD fill → unchanged scalar carry/accumulate) + scalar remainder (no large scratch, no length guard); new corpus 182 (identity anchor mul_u64(a,1)==a on the avx512 group path + scalar≡avx512). Correct first build. KAT 76=99 + 182=88; corpus 259/0; bigint.o iiis-0≡1≡2≡3 (830ca85f). `libiii_native.a` 321bcb40→**6b1dfa000f2f…**, `SOURCES`=`CLOSURE` 66800b02→**057151b33c55a815ea836af325d3c7bdc76a9c8518a3ffb842982c14721dc156** (246 modules). iiis-0/1/2/3 unchanged (1190d172/7804cea4/36d3ca98/36d3ca98 — compiler doesn't link bigint). **BigInt-mul = 6/10 complete.**

**§RITCHIE/3.5k5 (Keccak chi, AVX-512 vpternlogq):** vectorized the χ step only — the one cleanly-vectorizable Keccak step (within-row; θ/ρ/π keep the scalar's index-free form since a vector π transpose would be net-slower bloat for single-stream). `_kk_chi_scalar` (extracted baseline) + `_kk_chi_avx512` (metal: per-row 8-wide load, 2× vpermq within-row rotate, `vpternlogq $0xD2`=B^(~Brot1&Brot2), in-order stores → no k-mask) + dispatcher + `keccak_chi_force_path` @export; KK_LANE_A/B padded to [u64;32]; new corpus 181. Correct first build (provable boolean bit-identity). KAT 162=183 + 168=231 + 169=167 (FIPS oracles, auto→avx512) + 181=88 (scalar≡avx512); corpus 258/0; keccak.o iiis-0≡1≡2≡3 (7c61f31e). `libiii_native.a` b9482647→**321bcb40d3a6…**, `SOURCES`=`CLOSURE` 1e392080→**66800b02ff0aa8f63673914489ce88c3b24f00574800cfe57ac4f492e7261b1e** (246 modules). iiis-0/1/2/3 unchanged (1190d172/7804cea4/36d3ca98/36d3ca98 — compiler doesn't link keccak). **Keccak-chi = 5/10 complete.**

**§RITCHIE/3.5k4 (Poly1305, AVX-512, 2-path):** vectorized the radix-2^26 field multiply as `d_vec = Σⱼ hⱼ·colⱼ` (5 column vectors precomputed per key into POLY_COLS). `_poly_mul_scalar` (exact d_i baseline, HBUF→DBUF) + `_poly_mul_avx512` (metal: vpbroadcastq + vpmuludq + vpaddq in zmm) + `_poly_mul` dispatcher + `poly1305_force_path` @export; `_poly_block` rerouted; new corpus 180. Correct first build (no bug). KAT 71=168 + 72=99 (RFC oracles, auto→avx512) + 180=88 (scalar≡avx512 + ==RFC); corpus 257/0; poly1305.o iiis-0≡1≡2≡3 (dc44d318). `libiii_native.a` bfb93057→**b948264786d4…**, `SOURCES`=`CLOSURE` 8d8c58a9→**1e39208093a1be9e638c75e9a69d835e2a8c72f9ed06894d34ee85fe73e5c003** (246 modules). iiis-0/1/2/3 unchanged (1190d172/7804cea4/36d3ca98/36d3ca98 — compiler doesn't link poly1305). **Poly1305 = 4/10 complete.** 2-path (no clean AVX2 for 5-limb width; anti-bloat, cf. GHASH).

**§RITCHIE/3.5k3 (GHASH, PCLMULQDQ, 2-path):** `gcm_ghash_mul` → dispatcher (aesni→pclmul / GCM_FORCE); `gcm_ghash_mul_scalar` (NIST bit-serial, kept); `gcm_precompute_hp` (per-key `HP=bswap(H)<<1 mod poly`, doubling-reduce byte0^=0x01/byte15^=0xC2); `gcm_ghash_mul_pclmul` (metal: bswap + Karatsuba 3×pclmulqdq vs HP + OpenSSL 2-phase reduction + bswap back); `gcm_force_path` @export; new corpus 90 (=88). 2-path not 3 (no VPCLMULQDQ/GFNI on host → pclmul width-agnostic). KAT 62/63/69=99 (AES-128 + AES-256) + 90=88 (scalar≡pclmul + ==NIST); corpus 256/0; aes_gcm.o iiis-0≡1≡2≡3 (fd7518b7). `libiii_native.a` 8d391a6c→**bfb930572fe0…**, `SOURCES`=`CLOSURE` 901e3a01→**8d8c58a9181196c72b166fd36953b54eedcc2f6c4147a925581f6fa8aefb59b9** (246 modules). iiis-0/1/2/3 unchanged (1190d172/7804cea4/36d3ca98/36d3ca98 — compiler doesn't link aes_gcm). **GHASH = 3/10 complete.** (Bug caught pre-seal by corpus 90: doubling reduction byte was 0x87 — correct for full-bit-reversed, wrong for pshufb byte-reversed domain; fixed to the 0xc2-domain constant; AES-128 H masked it, AES-256 H exposed it.)

### §7.0 — Hexad pillar-position compose-rule fix → native STDLIB hexad subsystem + full iiis chain re-anchor (2026-05-23)

**Stage 7 (STDLIB feature extensions), gospel A3: "spec-correct pillar-position compose rule across the 3 implementations."** Two coupled changes:

**(1) Native STDLIB hexad subsystem** — 7 new `.iii` modules `omnia/{hexad_algebra,hexad_pfs,hexad_reach,hexad_epistemic,hexad_mobius,hexad_dynamic,hexad}.iii` (six pillars + umbrella integration self-test). Dialect-reconciled (no structs → byte buffers; no native f64 → scaled-ppm u32; W2 ≤4-param via packed u64; i32 traps via equality compares; numeral-first-in-parens trap via `let one`-binding). Each KAT-probed standalone; corpus test 389 (`iii_hexad_selftest`=99). `build_stdlib` 275→**282 PASS, 0 FAIL**.

**(2) Compose-rule fix (DRIFT — D8 closure-root rotation).** The §2.4 pillar-position compose was a uniform `hx_trit_compose` over all six pillars in BOTH compiler paths. Corrected to **AND on pillars 1-4 (idx 0..3) + OR on pillars 5-6 (idx 4..5)**, matching the C runtime reference `HEXAD/src/hexad_algebra.c::iii_hexad_compose6` (L127-134) and the new STDLIB `omnia/hexad_algebra.iii`:
- `COMPILER/BOOT/hexad_check.c` (iiis-0 C bootstrap): added `hxc_trit_and`/`hxc_trit_or`; split `iii_hexad_compose_packed` loop.
- `COMPILER/BOOT/hexad_check.iii` (iiis-1/2/3 ported path): added `hx_trit_and`/`hx_trit_or` (NEG=0/ZERO=1/POS=2 encoding); split loop.

| Artifact (golden) | Before | After |
|---|---|---|
| `COMPILER/BOOT/iiis-0.mhash` | `573ae109…` | `3437d73cc47640573a5681e0df9d6ec5a65dd8f23f1be456b8e6d960619da793` |
| `COMPILER/BOOT/iiis-1.mhash` | `718d3abb…` | `a2b5af10b55834a53e05d7bdc857771df965b8157d6f239a51992174fd3238a9` |
| `COMPILER/BOOT/iiis-2.mhash` = `iiis-3.mhash` (fixed point) | `fe8606bf…` | `5b1ab89dbe19fd9a55fb249cb3c7ac6acce8ab6804d905e6671ae598a4090f9c` |
| `STDLIB/build/CLOSURE.mhash` (= SOURCES, twin-build) | `08f23542…` | `228a540be489fbae8fb3c170139e0e7432db1597298d3e6cd70f287d0c5b4fab` (282 modules, +7 hexad) |
| `STDLIB/build/iii/libiii_native.a` | (prev) | `da9020fb93fcc40ae0b3049851902af6145b80d2f9d550729e41287c68fcaaf4` |

**Verified:** iiis-0 `--check-deterministic` BIT-IDENTICAL (3437d73c, twin-build A==B); iiis-1 reproduced deterministically (a2b5af10) + iiis-0≡iiis-1 `--check-corpus` 57/0; iiis-2≡iiis-3 fixed point (5b1ab89d) + `--check-corpus` 57/0 both; all 4 build scripts rc=0 vs rolled goldens; corpus **309/0**; XII corpus **93/0**; XII anti-drift **8/8** (manifest mhash + lattice byte-identical replay + reach6 bitmap/invariant + confluence + critical-pairs + MPHF collision-free + anchor signature); SOURCES/CLOSURE `--verify` BIT-IDENTICAL.

**Blast radius:** the only runtime call sites of `iii_hexad_compose_packed` are `sid.c:295` / `sid.iii:772` (sealed-ID composition). `gen_xii_lattice` does NOT compose → sealed `xii_lattice.bin` (`066e1dd3`) byte-identical replay. The **iiis-2≡iiis-3 equality is the codegen-neutrality proof**: iiis-2 (built by the OLD uniform-compose iiis-1) is byte-identical to iiis-3 (built by the NEW correct-compose iiis-2), so the compose rule is a runtime kind-check, never a compile-time codegen input; the fixed point is robust to the chain rotation. **§7.0 hexad COMPLETE.**

### §7.1 — @specialize compiler feature (generic-fn monomorphisation) → full iiis chain re-anchor (2026-05-23)

**Stage 7.1, gospel L24505/L24511: the `@specialize` modifier implemented in parse.iii + cg_r3.iii.** iii now has generic function declarations `fn f<T>(...) @specialize(types)` monomorphised into `<module>_<type>_<op>` symbols. Best-judgment (delegated): NO sema change — sema is lenient on T-typed params (sema.iii:1873-1908 pushes param NAMES, not types); monomorphisation done in cg via a per-type binding, cleaner + lower-risk than sema AST-cloning.

| Artifact (golden) | Before | After |
|---|---|---|
| `COMPILER/BOOT/iiis-0.mhash` | `3437d73c…` | `515c0b2082be53b891ccb1d79b712a650e35c63a6d3fa4d3916826004831f672` |
| `COMPILER/BOOT/iiis-1.mhash` | `a2b5af10…` | `9c536b1db8a19dea2edc18342ecfc2db0cfa86547738c12a232bed41c09bc996` |
| `COMPILER/BOOT/iiis-2.mhash` = `iiis-3.mhash` (fixed point) | `5b1ab89d…` | `5a16f2170065a37b92a26a5b6bc3196b5a2882a3d9070cd6f7455619df82c1c2` |
| `STDLIB/build/CLOSURE.mhash` (= SOURCES, twin-build) | `228a540b…` | `fa6fa6676a23b5ccea24f5701aa9f5332ddd53d562eb8d13f77e59a7db44446f` (285 modules, +1 spec_probe) |
| `STDLIB/build/iii/libiii_native.a` | `da9020fb…` | `277a522d95ef91943d180142adb5d87902678d48a5a2180e4d161ce92ddfeac4` |

**Impl (parser→AST→cg-loop):** parse.{c,iii} `iiip_parse_fn_decl` gained optional `<T[: kind][, U]>` (mirrors type_decl); `iii_fn_decl_payload_t` gained `type_params` (node-offset 40); ast.{c,iii} canonical hash `count>0`-guarded (existing fns byte-identical); sema_accessors.c `iii_ast_fn_type_param_count/at` + `iii_ast_type_param_name_off/len`; cg_r3.iii cg-loop = `r3_emit_specialized_fn` (reads @specialize args + type-param name → R3_SPEC binding) + width hook in `r3_emit_local_load_width_aware` (a TYPE_REF == type-param name resolves to the concrete type's load) + `r3_emit_spec_symbol` (`__` marker → `_<type>_`) + `r3_emit_fn_symbol` dispatcher + main-loop branch.

**Verified:** iiis-0 `--check-deterministic` BIT-IDENTICAL (515c0b20 twin A==B); iiis-0≡iiis-1 `--check-corpus` 57/0; iiis-2≡iiis-3 fixed point (5a16f217) 57/0 both; all 4 build scripts rc=0 vs rolled goldens; corpus **313/0**; XII corpus **93/0**; anti-drift **8/8**; SOURCES/CLOSURE `--verify` BIT-IDENTICAL. **KAT (corpus 393_specialize):** `spec_probe__id<T>(v: T)->u64 @specialize(u8,i8,u32)` → nm-confirmed generated symbols `spec_probe_{u8,i8,u32}_id`; the SAME 0xFF byte → 255 (u8 zero-ext) vs 0xFFFFFFFFFFFFFFFF (i8 sign-ext) → proves the per-type width/sign-aware specialization is genuine (not a rigged identity test).

**Codegen-neutrality:** all spec paths dormant when R3_SPEC_ACTIVE=0 (no existing .iii uses generics) → existing codegen byte-identical; the re-anchor rolls only the binary mhash (new compiler code) over identical generated output. cg_r3.c NOT mirrored (iiis-0 compiles zero generic .iii; gospel implements in cg_r3.iii). **§7.1 COMPLETE → §7.2 (~150 container specializations over the 17-pt alphabet).**

### §7.2 (partial) — container specializations option/result/span + cg T-in-memory hook → iiis re-anchor (2026-05-23)

**Stage 7.2 (~150 container specialisations via @specialize).** Containers split: VALUE-encoding (option, result — value packed in a u64 via tag bits) handled by the param-load width-hook; MEMORY-element (span, vec, map, set, queue, pq, lru, iter, fold, zip — *T indexing) need a cg T-in-memory hook. DONE this pass: `omnia/option` (35 syms: {u8,u16,u32,i8,i16,i32,bool}×{none,some,is_some,is_none,unwrap_or} + u64 side-table kept), `omnia/result` (42 syms + u64 side-table), `memoria/span` (28 syms: {u16,u32,u64,i8,i16,i32,i64}×{load,store,fill,find} + u8 hand-written kept — first class-B). cg_r3.iii gained the T-in-memory hook: `r3_type_ref_byte_size` resolves a TYPE_REF==type-param to the concrete byte size (`r3_spec_type_byte_size`), driving the *T stride + indexed load/store width. iiis-0 C UNCHANGED (only cg_r3.iii) → only iiis-1/2/3 roll.

| Artifact (golden) | Before | After |
|---|---|---|
| `COMPILER/BOOT/iiis-0.mhash` | `515c0b20…` | `515c0b20…` (UNCHANGED) |
| `COMPILER/BOOT/iiis-1.mhash` | `9c536b1d…` | `de6b3f21b59f129041f23d1d82ae349662e9d75dd4da033240a92265d34a6dd6` |
| `COMPILER/BOOT/iiis-2.mhash` = `iiis-3.mhash` (fixed point) | `5a16f217…` | `874a4c11ae609b7bed7d78c9f27ff04925cfb8eec06cd13641c7f105c28b4df2` |
| `STDLIB/build/CLOSURE.mhash` | `fa6fa667…` | `c268899b45fbc1ba96e14e079980addf3ed27bc59bf0056986cfae6f74b5fd7e` (287 modules) |
| `STDLIB/build/iii/libiii_native.a` | `277a522d…` | `3eb57b3f4b685432159dd072fc455bb0726d7cbc501d1681fc5fde5a972732d2` |

**Verified:** iiis-0 unchanged (golden matches, rc=0); iiis-0≡iiis-1 `--check-corpus` 57/0; iiis-2≡iiis-3 fixed point (874a4c11) 57/0; corpus **318/0** (04_span_load_store=66 hand-written u8 unperturbed; 09/394 option; 10/395 result; 396 span_specialize=99 store/load round-trip + i16 sign); XII **93/0**; SOURCES/CLOSURE `--verify` BIT-IDENTICAL. Codegen-neutral (T-in-memory hook + all spec paths dormant when R3_SPEC_ACTIVE=0). **§7.2 IN PROGRESS: option/result/span done (~105 generated syms); remaining vec/map/set/queue/pq/lru/iter/fold/zip follow the span class-B pattern (mechanical now the hook is proven).**

### §7.2 (cont.) — `*T` indexed stride/width bug fix + vec/iter generic → iiis re-anchor (2026-05-23)

**Root cause (real cg bug, found by bisection).** Under `@specialize`, a `*T` indexed load/store (`p[i]`, `p[i]=v`) defaulted to the **8-byte quad** form (SIB scale 8, `movq`) for ALL element types: `cg_r3.iii::r3_index_obj_elem_kind` mapped the pointee TYPE_REF name → element-kind (u8→1…i32→6, else→0=quad) but lacked the `R3_SPEC` type-param hook that `r3_type_ref_byte_size` already had, so the type-param name `T` matched nothing → ek=0 → quad. `sizeof T` was correct (separate path); only indexed addressing was wrong. Effect: u32 elements stored at byte stride 8 (8-byte writes); `vec`'s grow-copy (correct `cur_len*sizeof T` = stride-4 bytes) then captured only the low half → elements past the midpoint lost. span/iter KATs passed DESPITE the bug (store+load shared the wrong stride; single-index round-trips are self-consistent) — only `vec`'s grow exposed it.

**Fix.** Added `r3_spec_type_elem_kind()` (mirrors the literal name→kind map) + `if R3_SPEC_ACTIVE && name==R3_SPEC_TP_BUF return r3_spec_type_elem_kind()` in `r3_index_obj_elem_kind`. Codegen-neutral when R3_SPEC_ACTIVE=0 (every non-generic subscript unchanged). Verified in the disasm: `vec_u32_push`'s element store became `movl %edx,(%rax,%rcx,4)` (was `movq …,(…,8)`); element load `movl (%rax,%rcx,4),%eax`. Also added: `omnia/vec` generic (vec__{new,push,at,set,len,capacity,clear,drop}<T> over u16/u32/i8/i16/i32/i64 + u8/u64 hand-written kept) and `omnia/iter` generic — both now stride-correct.

| Artifact (golden) | Before | After |
|---|---|---|
| `COMPILER/BOOT/iiis-0.mhash` | `515c0b20…` | `515c0b20…` (UNCHANGED) |
| `COMPILER/BOOT/iiis-1.mhash` | `de6b3f21…` | `e0b7cb2c0b66473c8965423c704e5bcb975a23c8c166451a3c0e53a2bad2f22e` |
| `COMPILER/BOOT/iiis-2.mhash` = `iiis-3.mhash` (fixed point) | `874a4c11…` | `0ef8626a5befd2d30a34e1ea9e82e6d9b76757d648fda148d42c299b7949e4ae` |
| `STDLIB/build/iii/libiii_native.a` | `3eb57b3f…` | `2a7394d62086b72678c8562d4be930c4703758265109077f1230abeff4b37ecf` |

**Verified:** iiis-1 `verify: OK` (resealed); iiis-2≡iiis-3 fixed point (`0ef8626a`, twin-build reproduced rc=0); build_stdlib FAIL=0; KATs 393/394/395/396(+stride guard)/397/398_vec all exit 99 (direct compile+link+run); full corpus 330/0 (shared tree, zero regressions, `398_vec_specialize` EXPECTED added). cg_r3.c NOT mirrored (iiis-0 compiles zero generic .iii). The new strengthened 396 asserts byte-4 stride (adjacent u32 elements at stride 4, not 8) so the bug can never silently regress.

### §8.0 — u64-division codegen fix + bench-link reseal → new fixed point (2026-05-29)

**Context.** The last ledgered golden (§7.2, `0ef8626a…`, 2026-05-23) advanced through a large
UNCOMMITTED C→.iii port + CONVERGENCE-wave body of work to a pre-fix golden `840a528e…`. This
entry seals that cumulative state plus two corpus-blocking fixes the full *behavioral* corpus
exposed (the prior "green" had only confirmed compilation).

**Cause A — u64-division (`cg_r3.iii`).** DIV/MOD (binop op 4/5) emitted signed `cqto;idivq` for
ALL operands → unsigned `u64 ÷/%` of a high-bit value read as negative (`0xFFFF..FE/2`→MAX). FIX:
branch on the already-computed `signed` (`r3_either_is_signed`) — unsigned → `xorl %edx,%edx; divq`
(new `R3_STR_DIVU`/`R3_STR_DIVUMOD`); signed path unchanged. `COMPILER_RESEAL`.
**Cause B — bench link (`run_bench_corpus.sh` + forcefield).** `forcefield/{pleroma,ripple_dyn}`
non-`@export` `malloc`/`free` → global `L_malloc`/`L_free` collision under `--whole-archive` →
renamed `pl_*`/`dn_*`; and the bench runner's *blanket* `--whole-archive` (force-linking the
gospel-scale ~1GB BSS → `IMAGE_REL_AMD64_REL32` overflow) → switched to the selective
side-effect-set pattern every other runner already uses.

| Artifact (golden) | Before (uncommitted pre-fix) | After (this seal) |
|---|---|---|
| `iiis-1.mhash` ≡ `iiis-2.mhash` ≡ `iiis-3.mhash` (fixed point) | `840a528e…f6b3b8` | `4e1384157c1f1812fd4b1b24a43aae7e0a7a11812f5658060575742b0619fa85` |
| `STDLIB/build/iii/libiii_native.a` | `c45f1d3f…daa2cd` | `258b357980796b9613e498bd36978db1885d67fefe139c1092360ec0f828f5f8` |

**Verified:** `build_iiis2 --check-corpus` + `build_iiis3 --check-corpus` both **59/0**; build_stdlib
**419/0**; FULL corpus ALL GREEN — STDLIB **546/0**, bench **4/0** (links fixed), stage-1 **57/0**;
`890_sat_arith`=99 + `893_u64_div`=99 (genuine guarding KATs, not rigged).

**Bootstrap-state finding (pre-existing, non-blocking):** `build_iiis1` (iiis-0→iiis-1) is broken —
iiis-0 can no longer compile post-port `parse.iii` (`iii_lex_*_c` gone). The reseal correctly uses
the frozen iiis-1 seed; from-absolute-scratch bootstrap has drifted past iiis-0 (future seed-refresh).

**§8.0 sealed at:** 2026-05-29.

### §8.1 — Sovereign Pipeline: every kernel faculty unified through one disposer (2026-05-29)

The `/architect` deliverable for "everything from the kernel — superposition to inductive reasoning —
actively used through the same means." `numera/sov_pipeline.iii` (`sov_pipeline_run() @export`)
composes EVERY kernel faculty through the SAME means (the CIC kernel `tc_check` as universal
disposer), each stage carrying a falsifier so "all faculties live" is never a vacuous pass:
(1) CONVERSION `tc_conv` (1~1 / 0!~1); (2) INDUCTION `iu_kat`; (3) SUPERPOSITION `psi_of/card/collapse`;
(4) PROOF-CARRYING OPT `sov_isa_descend`+`sov_pcc_verify` (2==2 cert / 1==2 reject);
(5) KERNEL-GOVERNED ADMISSION `sov_admit_rule` (sound admit / meaning-changing reject). No new
faculty logic — composition only → additive, **compiler-UNREFERENCED** (LIBNATIVE_RESEAL).

| Artifact (golden) | Before (§8.0) | After (this seal) |
|---|---|---|
| `iiis-1 ≡ iiis-2 ≡ iiis-3` (fixed point) | `4e138415…0619fa85` | `4e1384157c1f1812fd4b1b24a43aae7e0a7a11812f5658060575742b0619fa85` (**UNCHANGED** — ADR-1 compiler-neutrality PROVEN, not assumed) |
| `STDLIB/build/iii/libiii_native.a` | `258b3579…0ec0f828f5f8` | `913a7ffc339e13837d435cbbe97cda604226ab6468e7c930babebf32ec6ae205` |

**Verified:** build_stdlib **420/0** (sov_pipeline appended last = BSS-neutral);
`build_iiis2 --check-corpus` + `build_iiis3 --check-corpus` both **59/0** (iiis-2/3 stay `4e138415`
→ the module is genuinely compiler-unreferenced); FULL STDLIB corpus **548/0**; `916_sov_pipeline`=99
(all five faculties live + kernel-disposed; every falsifier held — direct compile+link+run also EXIT 99).

**§8.1 sealed at:** 2026-05-29.

### §8.2 — Sovereign Pipeline wired into commit_gate: the kernel faculties gate III's evolution (2026-05-29)

**"Use them on III"** — the `/architect` ADR-2 production activation. `forcefield/commit_gate.iii`
(III's sound-evolution gate — the single admission decision every change to III must pass) gains a
**5th KERNEL dimension**: `cg_kernel_ok()` = `(sov_pipeline_run()==99)`, composed into `cg_decide`
as `CG_REJECT_KERNEL=5`. A change to III is now admitted only if — in addition to rule-confluence
(`xad_admit`), module-coherence (`pleroma` H^1=0), determinism-seal (`cad`), and conservativity —
III's ENTIRE proof kernel and all its faculties (conversion, induction, superposition,
proof-carrying optimization, kernel-governed admission) remain live + sound. The kernel faculties
are thus **actively used through the same means (`tc_check`) ON III's own self-governance**.
`cg_decide` stays a pure, total, located predicate; corpus 864 forces the new reject
(`kernel_sound=0 -> 5`) and the full 5-arg teeth matrix. Compiler-UNREFERENCED -> LIBNATIVE_RESEAL.

| Artifact (golden) | Before (§8.1) | After (this seal) |
|---|---|---|
| `iiis-1 == iiis-2 == iiis-3` (fixed point) | `4e138415…0619fa85` | `4e1384157c1f1812fd4b1b24a43aae7e0a7a11812f5658060575742b0619fa85` (**UNCHANGED** — LIBNATIVE; the compiler never references `commit_gate`) |
| `STDLIB/build/iii/libiii_native.a` | `913a7ffc…ec6ae205` | `501db74152065bf58b45dbf26d476a3555b250d3f4153bd98e15773d0fc55cf0` |

**Verified:** build_stdlib **420/0**; cartographer GATE **PASS** (the new `commit_gate -> sov_pipeline`
edge adds no dependency cycle — Tarjan-SCC); compiler `4e138415` unchanged (sha256, two ways);
FULL STDLIB corpus **548/0** — `864`=99 (5-dim gate + located kernel-reject 25 + teeth matrix 35)
+ `916`=99, zero regressions.

**§8.2 sealed at:** 2026-05-29.

### §8.3 — Sovereign Ripple Calculus, Inc 1: the objective made computable (2026-05-29)

`forcefield/ripple_metric.iii` (`rm_*` `@export`): the ripple objective J's four targets as
PROVABLE graph predicates -- noise (dead edges), good-complexity (load-bearing), separation
(unifiable duplicates), unification -- plus per-candidate cut/merge validity+improvement and the
aggregate `rm_j` (a graph-level MDL proxy; the decidable fragment, per
`DOCS/III-RIPPLE-OPTIMIZER-ARCHITECTURE.md`). MEASURE-ONLY (no self-editing). Standalone,
compiler-UNREFERENCED -> LIBNATIVE_RESEAL.

Corpus 917 proves it end-to-end with prove-the-negative FALSIFIERS encoding III's hard lessons:
a load-bearing edge is never noise + never cuttable (good complexity protected); a witnessed
dead edge is never cut (intent respected); a capability-equal but intent-class-DIFFERENT pair
(cpufeat userspace vs Ring-0) is never unified.

| Artifact (golden) | Before (§8.2) | After (this seal) |
|---|---|---|
| `iiis-1 == iiis-2 == iiis-3` | `4e138415…0619fa85` | `4e1384157c1f1812fd4b1b24a43aae7e0a7a11812f5658060575742b0619fa85` (**UNCHANGED** -- LIBNATIVE) |
| `STDLIB/build/iii/libiii_native.a` | `501db741…0fc55cf0` | `9853413483a956785a3120ad9c249dcf78d33bff723b86f857487aca5d669c85` |

**Verified:** build_stdlib **421/0**; cartographer GATE PASS (no new cycle/dup-export); compiler
`4e138415` unchanged; FULL corpus **549/0**; `917_ripple_metric`=99.

**§8.3 sealed at:** 2026-05-29.

### §8.4 — Sovereign Ripple Calculus, Inc 2: the first certified refactoring (unification) (2026-05-29)

`forcefield/ripple_unify.iii` (`ru_certify_unify`, `ru_survivor_cost` `@export`): the first
CERTIFIED REFACTORING, composing `ripple_metric` (the intent gate) + `congruence` (the
faithfulness-gated union-find merge) + a kernel proof. `ru_certify_unify` returns 1 IFF the pair
is a unification CANDIDATE (capability-equal, intent-equal) AND soundly mergeable (auto-congruent
on an identical content-address, or a discharged kernel proof). DECIDER ONLY (no file edits).
Compiler-UNREFERENCED -> LIBNATIVE_RESEAL.

Corpus 918 proves it with the DECISIVE falsifier (the cpufeat lesson): an intentional variation
point (capability-equal but intent-class-DIFFERENT) is REFUSED even with `proof_ok=1` --
behavioral equality is NECESSARY, NOT SUFFICIENT; intent-preservation is also required. (Plus:
no proof -> refused, no fabricated equality.)

| Artifact (golden) | Before (§8.3) | After (this seal) |
|---|---|---|
| `iiis-1 == iiis-2 == iiis-3` | `4e138415…0619fa85` | `4e1384157c1f1812fd4b1b24a43aae7e0a7a11812f5658060575742b0619fa85` (**UNCHANGED** -- LIBNATIVE) |
| `STDLIB/build/iii/libiii_native.a` | `9853413483…5d669c85` | `b430f38ff96a80d6d3d4ddaafe16fd1016bc572cf5e2350453e224809ce116c0` |

**Verified:** build_stdlib **422/0**; cartographer GATE PASS; compiler `4e138415` unchanged; FULL
corpus **550/0**; `918_ripple_unify`=99 (+ `917`=99).

**§8.4 sealed at:** 2026-05-29.

### §8.5 — Sovereign Ripple Calculus, Inc 3: the closed loop, commit_gate-gated (2026-05-29)

`forcefield/ripple_loop.iii` (`rl_run`, `rl_ring_size` `@export`): the closed LOOP -- propose ->
DECIDE (commit_gate admissibility + `ru_certify_unify` soundness) -> apply-in-model -> loop until
DRY. Composes `ripple_metric` + `ripple_unify` + `congruence` + the §8.2 `commit_gate`. Converges
to the sound dedup'd ring (monotone: each merge shrinks separation -> J up; <= n passes).
DECIDER/PLANNER only (no file edits). Compiler-UNREFERENCED -> LIBNATIVE_RESEAL.

Corpus 919 proves: the loop dedups accidental duplicates (3 capA-dups -> 2 unions), the intentional
variation stays distinct (the intent gate), ring 6 -> 4; and the DECISIVE falsifier -- with the
KERNEL dimension down (commit_gate dim 5 = 0) the loop self-edits NOTHING (ring stays 6). III
refuses to refactor itself while its own prover is broken.

| Artifact (golden) | Before (§8.4) | After (this seal) |
|---|---|---|
| `iiis-1 == iiis-2 == iiis-3` | `4e138415…0619fa85` | `4e1384157c1f1812fd4b1b24a43aae7e0a7a11812f5658060575742b0619fa85` (**UNCHANGED** -- LIBNATIVE) |
| `STDLIB/build/iii/libiii_native.a` | `b430f38f…09ce116c0` | `37049ecb7257a0042777763bbc33f8cc767e43bda2e2457fad452d63e9162fea` |

**Verified:** build_stdlib **423/0**; cartographer GATE PASS; compiler `4e138415` unchanged; FULL
corpus **551/0**; `919_ripple_loop`=99 (+ `918`=99).

**§8.5 sealed at:** 2026-05-29.

### §8.6 — Sovereign Ripple Calculus, Inc 4: the noise-cut refactoring (decision engine complete) (2026-05-29)

`forcefield/ripple_cut.iii` (`rc_certify_cut`, `rc_sweep_cuts` `@export`): the SECOND certified
refactoring -- noise removal. Composes `ripple_metric` + `commit_gate`. A cut is certified IFF
commit_gate-admissible AND capability-preserving (`rm_cut_valid` -- never a load-bearing edge) AND
improving (`rm_cut_improves` -- genuine noise: dead and not witnessed). DECIDER/SWEEP only.
Compiler-UNREFERENCED -> LIBNATIVE_RESEAL.

**With Inc 1-4 the DECISION ENGINE is complete:** III can MEASURE its ripple structure
(`ripple_metric`) and certify the sound, intent-respecting, kernel-gated refactorings on all four
objective targets -- unification (`ripple_unify`, -separation), the closed loop (`ripple_loop`),
and noise-cut (`ripple_cut`, -noise). Corpus 920 falsifiers: a load-bearing edge is never cut (good
complexity protected); a witnessed dead edge is never cut (intent); kernel down -> no cuts.

| Artifact (golden) | Before (§8.5) | After (this seal) |
|---|---|---|
| `iiis-1 == iiis-2 == iiis-3` | `4e138415…0619fa85` | `4e1384157c1f1812fd4b1b24a43aae7e0a7a11812f5658060575742b0619fa85` (**UNCHANGED** -- LIBNATIVE) |
| `STDLIB/build/iii/libiii_native.a` | `37049ecb…e9162fea` | `11defd253d636c130b40b0dec044b55357f4acc473cbe0af29ab6902a03600b8` |

**Verified:** build_stdlib **424/0**; cartographer GATE PASS; compiler `4e138415` unchanged; FULL
corpus **552/0**; `920_ripple_cut`=99 (+ `919`=99).

**§8.6 sealed at:** 2026-05-29.

### §8.7 — Sovereign Ripple Calculus, Inc 5: the gated file-editing APPLIER (the working optimizer) (2026-05-29)

`STDLIB/scripts/ripple_apply.sh` -- the execution arm. The `.iii` decision engine certifies WHAT to
refactor; the applier EXECUTES the certified edit on a real `.iii` file and proves the post-state
green through a 4-gate cascade -- GATE0 standalone-compile, GATE1 `build_stdlib` FAIL=0, GATE2
compiler-unchanged (LIBNATIVE), GATE3 full corpus -- KEEPING iff all green, else atomic REVERT
(+ rebuild lib from the good source). **Inductive safety invariant:** the tree is verified-green
BEFORE and AFTER every step, so III is never left broken; safety depends on the GATE being honest,
not on the edit being right. Two independent proofs guard each change: the `.iii` certification
(behavior-preservation, before) + this gate (the backstop).

Demonstrated **D1 (revert-safety):** a breaking edit to `ripple_cut.iii` -> REJECT @GATE0 -> reverted
BYTE-EXACTLY (`git status` clean), library untouched. The keep-path is the standard build+corpus gate
(proven green by Inc 1-4). A TOOL (no `.iii`/seal change): golden + lib UNCHANGED (`4e138415` /
`11defd25`).

**With Inc 1-5 the WORKING RIPPLE OPTIMIZER is complete:** III measures its ripple structure,
certifies sound refactorings on all four objective targets, runs the closed `commit_gate`-gated loop,
and safely applies the result to its own files (edit/merge). This is the baseline for the next two
designs -- Topological Extraction (new-file creation) and Proof-Carrying Code.

**§8.7 sealed at:** 2026-05-29.

### §8.8 — Generative Frontier B1: Topological Extraction decider (the 4 conditions) (2026-05-29)

`forcefield/ripple_extract.iii` (`rx_*` `@export`): the decider that permits writing a NEW `.iii`
file ONLY to lift out shared truth already in G (never generative synthesis). The four conditions
(`DOCS/III-GENERATIVE-FRONTIER.md`), each DECIDABLE + proven by an existing organ:
- **C1 Capability Conservation** (`rx_export_in_g`): an export is in G iff interning its `cad`
  creates no new congruence class (a hallucinated export = fresh address = new class -> reject).
- **C2 MDL Boundary Penalty** (`rx_delta_j_positive`): `saved_lines > new_file_lines + overhead`.
- **C3 Acyclic Insertion** (`rx_reaches` iterative DFS + `rx_acyclic_insert`): F must not reach a
  caller (else `caller->F` closes a cycle).
- **C4 H10 Origin Certificate** (`rx_h10_blocks_remerge`): an H10-stamped file's distinct
  intent-class makes the loop abstain from re-merging it (anti-thrashing).
`rx_certify_extract` composes all four + `commit_gate`. DECIDER only. Compiler-UNREFERENCED -> LIBNATIVE.

Corpus 921: one prove-the-negative falsifier per condition + the composed decider's full teeth
(each condition false -> reject; kernel down -> reject). (A `from`-keyword param clash -- the
`extern…from` keyword -- was caught at standalone-compile and fixed in module + KAT before sealing.)

| Artifact (golden) | Before (§8.7) | After (this seal) |
|---|---|---|
| `iiis-1 == iiis-2 == iiis-3` | `4e138415…0619fa85` | `4e1384157c1f1812fd4b1b24a43aae7e0a7a11812f5658060575742b0619fa85` (**UNCHANGED** -- LIBNATIVE) |
| `STDLIB/build/iii/libiii_native.a` | `11defd25…2a03600b8` | `3b4a85a7d244d8781e2d6c02b0d28d5e1fc6b31d52e461bc6d9de3ba6c196bbc` |

**Verified:** build_stdlib **425/0**; cartographer GATE PASS; compiler `4e138415` unchanged; FULL
corpus **553/0**; `921_ripple_extract`=99.

**§8.8 sealed at:** 2026-05-29.

### §8.9 — Generative Frontier B2: the Topological Extraction EXECUTOR (2026-05-29)

`STDLIB/scripts/ripple_extract.sh` -- writes a NEW `.iii` file (H10 Origin Certificate header +
the B1-certified payload, content-addressed via `cad`), registers it in MODULES, and proves the
post-state green through GATE0 standalone-compile + GATE1 build_stdlib + GATE2 compiler-unchanged
+ GATE3 corpus; KEEPS iff green, else atomic REVERT (rm file + unregister + rebuild). Inc 5's
inductive safety invariant extended from EDIT to CREATION: III is never left broken.

Demonstrated:
- **D1** (creation-revert, syntax): a broken new file -> REJECT @GATE0 -> removed, MODULES untouched.
- **D2** (creation-revert, registration+build): a dup-export new file -> registered -> REJECT @GATE1
  (the cartographer caught the colliding `@export`) -> reverted, build_stdlib + lib (`3b4a85a7`)
  restored byte-exactly.

The KEEP path is the standard gate (proven by Inc 1-B1). D2 also shows an extraction cannot sneak
in a colliding capability -- the cartographer's no-dup-export invariant complements B1's C1.

A TOOL (no `.iii`/seal change): golden `4e138415`, lib `3b4a85a7` unchanged. **With B1 (decider) +
B2 (executor), III can write new files for Topological Extraction -- safely, only to relocate
proven shared truth, never to invent.**

**§8.9 sealed at:** 2026-05-29.

### §8.10 — Generative Frontier C1: Proof-Carrying Code decider (kernel-checked) (2026-05-29)

`forcefield/pcc_gate.iii` (`pcc_verify`, `pcc_admit` `@export`): the ONE permitted generative
synthesis. `pcc_verify(proof, spec)` = `typecheck.iii` `tc_check(proof, spec)` -- III's CIC kernel
EVALUATES the constructive proof against the human dependent-type spec; **the kernel checks the
proof, it never runs the code**. `pcc_admit` composes `commit_gate` + the kernel verdict.
Compiler-UNREFERENCED -> LIBNATIVE_RESEAL.

Corpus 922 drives the REAL kernel on genuine dependent types -- spec Nat (`0` admits, `true`
rejects), spec Nat->Nat (`λx.x` admits, `λx.true` rejects), spec Id (`refl 0 : 0=0` admits;
`refl 0 : 0=1` **REJECTED** -- THE HEART: the kernel will not prove a falsehood, so generative code
carrying a false proof is destroyed) + the composed `pcc_admit` (proven + kernel-live -> commit;
flawed -> destroy; kernel down -> reject).

| Artifact (golden) | Before (§8.9) | After (this seal) |
|---|---|---|
| `iiis-1 == iiis-2 == iiis-3` | `4e138415…0619fa85` | `4e1384157c1f1812fd4b1b24a43aae7e0a7a11812f5658060575742b0619fa85` (**UNCHANGED** -- LIBNATIVE) |
| `STDLIB/build/iii/libiii_native.a` | `3b4a85a7…6c196bbc` | `fbfb64e8744b07a2c28293e67a7265d480d93894b5f3078f6689ea5557d2d942` |

**Verified:** build_stdlib **426/0**; cartographer GATE PASS; compiler `4e138415` unchanged; FULL
corpus **554/0**; `922_pcc_gate`=99.

**§8.10 sealed at:** 2026-05-29.

### §8.11 — Generative Frontier C2: the Proof-Carrying Code EXECUTOR (the frontier complete) (2026-05-29)

`STDLIB/scripts/pcc_synthesize.sh` -- the generative-synthesis applier. Submits the (code, proof,
spec) to the kernel (a harness calling `pcc_admit` -> `typecheck.iii` `tc_check`); commits the
generated code through the gated write (GATE0-3 + revert) ONLY if the kernel CERTIFIES, else
DESTROYS it (nothing written). The kernel checks the proof, never runs the code. **Defence-in-depth:**
the kernel proof certifies the MATH (the code satisfies the spec under all states); the gated write
certifies the INTEGRATION (build + LIBNATIVE + corpus) -- both must pass.

Demonstrated:
- **D1** (flawed proof `refl 0 : 0=1`): KERNEL REJECTED -> code DESTROYED, nothing written.
- **D2** (certified proof `0=0`, non-integrating dup-export payload): KERNEL CERTIFIED -> gated
  write -> REJECT @GATE1 (the cartographer caught the dup) -> reverted byte-exactly, lib `fbfb64e8`
  restored.

The full commit (certified + integrating) -> KEEP is the standard gate (proven Inc 1-C1). A TOOL
(no `.iii`/seal change): golden `4e138415`, lib `fbfb64e8` unchanged.

**THE GENERATIVE FRONTIER IS COMPLETE.** With C1 (kernel decider) + C2 (executor), III admits
genuine novelty -- but only when the Proposer submits a flawless constructive proof to the kernel.
Combined with the working ripple optimizer (Inc 1-5, edit/merge) and Topological Extraction (B1-B2,
new files from proven shared truth), III can now reshape its own substance in every direction --
inward (merge/cut), outward (extract), and forward (proven synthesis) -- without ever loosening the
kernel's law.

**§8.11 sealed at:** 2026-05-29.

### §8.12 — III → Silicon HW1: certified combinator → gate-netlist lowering (2026-05-29)

`numera/hdl.iii` (`hdl_*` `@export`): the certified lowering of a combinator/boolean term onto
hardware gates -- BinaryGate (`NOT/AND/OR/XOR/NAND/BUF/CONST`), TernaryGate (`TNOT/TAND/TOR` via
`trit.iii`), DFlipFlop. THE CERTIFICATION: `hdl_equiv2`/`hdl_equiv3_2` is the exhaustive TRUTH TABLE
-- a netlist is accepted only when *proven* to compute the identical function as its source (pure
algebraic translation, no heuristics). Unified `i32` gate value; topological one-pass eval.
Compiler-UNREFERENCED -> LIBNATIVE_RESEAL.

Corpus 923: XOR built directly === XOR from 4 NANDs (certified over all 4 inputs); AND != XOR
(falsifier); Kleene De Morgan `NOT(a AND b) === (NOT a) OR (NOT b)` certified over all 9 trit pairs
(+ falsifier). Design `DOCS/III-SILICON-FRONTIER.md` (math-olympiad honest scope: certified lowering
YES; NP-hard place-&-route + proprietary bitstream EXCLUDED -- III emits the certified netlist the
toolchain consumes).

| Artifact (golden) | Before (§8.11) | After (this seal) |
|---|---|---|
| `iiis-1 == iiis-2 == iiis-3` | `4e138415…0619fa85` | `4e1384157c1f1812fd4b1b24a43aae7e0a7a11812f5658060575742b0619fa85` (**UNCHANGED** -- LIBNATIVE) |
| `STDLIB/build/iii/libiii_native.a` | `fbfb64e8…57d2d942` | `d7a4a4d2c704109b3305a813e93a2f078ff664eb3606b571338a11f0a8bbba40` |

**Verified:** build_stdlib **427/0**; cartographer GATE PASS; compiler `4e138415` unchanged; FULL
corpus **555/0**; `923_hdl`=99.

**§8.12 sealed at:** 2026-05-29.

### §8.13 — III → Silicon HW2: the physical cost lattice (2026-05-29)

`numera/hdl.iii` extended (`pc_*` `@export`): the cost lattice stops costing x86/ARM cycles and
costs SILICON -- `pc_gate_count`, `pc_logic_depth` (critical-path gate-delay = longest path in the
netlist DAG), `pc_wire_count` (in-edge wire proxy), `pc_landauer_yj` (irreversible 2-input gates ×
2871 yJ = kT·ln2 at 300 K -- the thermodynamic LOWER BOUND, the universe's floor, NOT the silicon
draw), `pc_better` (fewer gates, then shallower). The e-graph selects the min-physical-cost member
of an equivalence class (every member PROVEN === by HW1). Compiler-UNREFERENCED -> LIBNATIVE.

Corpus 924: two PROVEN-equivalent XOR realizations -- 1 gate (depth 1, 2 wires, 2871 yJ) vs 4 NANDs
(depth 3, 8 wires, 11484 yJ); `pc_better` selects the 1-gate design; falsifier (the 4-NAND is not
preferred). Honest scope: gate/depth/wire/Landauer decidable; NP-hard optimal placement/routing
EXCLUDED (the toolchain's, not III's).

| Artifact (golden) | Before (§8.12) | After (this seal) |
|---|---|---|
| `iiis-1 == iiis-2 == iiis-3` | `4e138415…0619fa85` | `4e1384157c1f1812fd4b1b24a43aae7e0a7a11812f5658060575742b0619fa85` (**UNCHANGED** -- LIBNATIVE) |
| `STDLIB/build/iii/libiii_native.a` | `d7a4a4d2…a8bbba40` | `65952b7c4061f9856dc743d68aaf528e5a2a25970335084d8df0ae1a76ce8565` |

**Verified:** build_stdlib **427/0**; cartographer GATE PASS; compiler `4e138415` unchanged; FULL
corpus **556/0**; `924_phys_cost`=99 (+ `923`=99).

**§8.13 sealed at:** 2026-05-29.

### §8.14 — III → Silicon HW3: the hardware Axiom Enforcement Unit (the frontier complete) (2026-05-29)

`numera/aeu.iii` (`aeu_*` `@export`): III's foundational axioms as a PARALLEL combinational verifier
-- `aeu_lane_wellformed` (h<729) + `aeu_lane_reachable` (`iii_hexad_reachable`, the M3 axiom;
kernel-checked) evaluated together, conjoined = `aeu_check` (every datum verified against all axioms
in one pass, zero CPU instructions). `aeu_netlist_certified` builds the verifier as an AND-of-lanes
from universal NANDs and proves (`hdl_equiv2`) it === the conjunction: the silicon verifier provably
equals `aeu_check`. Compiler-UNREFERENCED -> LIBNATIVE.

Corpus 925 (on III's REAL hexad axioms): a reachable+well-formed hexad passes all lanes; an
UNREACHABLE hexad is CAUGHT (the prove-the-negative); a MALFORMED hexad (>=729) is caught; the AEU
agrees with the kernel's `safety_hexad_judge`; the NAND-built verifier netlist is certified === the
conjunction.

| Artifact (golden) | Before (§8.13) | After (this seal) |
|---|---|---|
| `iiis-1 == iiis-2 == iiis-3` | `4e138415…0619fa85` | `4e1384157c1f1812fd4b1b24a43aae7e0a7a11812f5658060575742b0619fa85` (**UNCHANGED** -- LIBNATIVE) |
| `STDLIB/build/iii/libiii_native.a` | `65952b7c…76ce8565` | `93cbaf7be9c03db61d6eb829fc3c6a6eeb50bb4cc0cd24bf8ea221301905905e` |

**Verified:** build_stdlib **428/0**; cartographer GATE PASS; compiler `4e138415` unchanged; FULL
corpus **557/0**; `925_aeu`=99.

**THE III → SILICON FRONTIER IS COMPLETE:** HW1 (certified combinator→gate lowering) + HW2 (the
physical cost lattice: gates/depth/wire/Landauer floor) + HW3 (the hardware AEU). III lowers its
proven-optimal computation onto a CERTIFIED gate netlist, costs it in silicon down to the
thermodynamic floor, and enforces its axioms in parallel hardware -- pure algebraic translation,
every step truth-table or kernel certified, the NP-hard place-&-route honestly left to the toolchain.

**§8.14 sealed at:** 2026-05-29.

### §8.15 — III → Silicon SX1: sequential circuits (the DFlipFlop made real) (2026-05-29)

`numera/hdl.iii` extended (`hdl_step`/`hdl_seq_init`/`hdl_set_a`/`hdl_dff_state`; `HG_DFF` now outputs
its held state): clocked sequential logic. III lowers STATEFUL hardware -- registers, counters, FSMs
-- not just combinational. A clock step = combinational eval (each DFF outputs `HG_STATE`) then latch
(next state = input). Bounded (N cycles), NOT the halting problem. Compiler-UNREFERENCED -> LIBNATIVE.

Corpus 926: a toggle flip-flop (DFF fed by `NOT` of its own output) traces 1,0,1,0; a self-held DFF
holds at 0 (the contrast/falsifier).

| Artifact (golden) | Before (§8.14) | After (this seal) |
|---|---|---|
| `iiis-1 == iiis-2 == iiis-3` | `4e138415…0619fa85` | `4e1384157c1f1812fd4b1b24a43aae7e0a7a11812f5658060575742b0619fa85` (**UNCHANGED** -- LIBNATIVE) |
| `STDLIB/build/iii/libiii_native.a` | `93cbaf7b…1905905e` | `dcba7871f51fc63d8babc4bd1117e51a2b046f0a3659a93b084224c2a71f89f6` |

**Verified:** build_stdlib **428/0**; cartographer GATE PASS; compiler `4e138415` unchanged; FULL
corpus **558/0**; `926_hdl_seq`=99.

**NOTE (incident, root-caused not hand-waved):** the first gate run aborted on a TRANSIENT cartographer
collision -- a stale CONCURRENT build task (pre-summary `w1a2` running `build_stdlib`+`run_corpus`)
raced this gate and momentarily left an `i32probe.iii` (`fn main @export`) in `COMPILER/BOOT`,
colliding with `main.iii`. Diagnosed via process inspection (`Get-CimInstance`), the stale task +
orphans killed, scratch removed; the clean re-run sealed. SX1 code was never at fault -- its
`.o`-linked corpus passed 558/0 even during the aborted run.

**§8.15 sealed at:** 2026-05-29.

### §8.16 — III → Silicon SX2: realistic physical cost (gate delay + wire capacitance) (2026-05-29)

`numera/hdl.iii` extended (`pc_gate_delay`/`pc_crit_delay`/`pc_fanout_cap`): the cost model gains the
literal mechanic. `pc_gate_delay` = per-gate-TYPE delay (simple boolean = 1, XOR = 2, trit AND/OR =
2, DFF/IN/const = 0). `pc_crit_delay` = the WEIGHTED critical path (finer than uniform
`pc_logic_depth`). `pc_fanout_cap` = Σ consumers² per net (quadratic capacitive load). Still a
topological proxy -- NOT NP-hard placed routing (ADR-S2 stands). Compiler-UNREFERENCED -> LIBNATIVE.

Corpus 927: an XOR-deep path (weighted delay 4) is slower than a NAND-deep path (2) at EQUAL gate
count; a net driving 3 gates has 9× the fan-out capacitance of one driving 1.

| Artifact (golden) | Before (§8.15) | After (this seal) |
|---|---|---|
| `iiis-1 == iiis-2 == iiis-3` | `4e138415…0619fa85` | `4e1384157c1f1812fd4b1b24a43aae7e0a7a11812f5658060575742b0619fa85` (**UNCHANGED** -- LIBNATIVE) |
| `STDLIB/build/iii/libiii_native.a` | `dcba7871…71f89f6` | `355462ce46509559c521f43e4c33407b515b4fabaa20ac68066e9befc06fd4b6` |

**Verified:** build_stdlib **428/0**; cartographer GATE PASS; compiler `4e138415` unchanged; FULL
corpus **559/0**; `927_phys_real`=99.

**§8.16 sealed at:** 2026-05-29.

### §8.17 — III → Silicon SX3: the certified netlist optimizer (the E-graph "select fewest gates") (2026-05-29)

`numera/hdl.iii` extended (`pc_live_gate_count` + `hdl_opt_dn` + `hdl_opt_idem`): the frontier now
OPTIMIZES, not just measures. Proven cost-reducing rewrites -- double-negation elimination
`NOT(NOT x) ⇒ x`, idempotent `AND/OR(x,x) ⇒ x` -- each truth-table-certified ===, with
`pc_live_gate_count` (gates reachable from the output) reflecting the reduction. **Honest scope: a
LOCAL min under the proven rewrite set; exact minimum-gate synthesis is the NP-hard Minimum Circuit
Size Problem, never claimed.** Compiler-UNREFERENCED -> LIBNATIVE.

Corpus 928: `NOT(NOT a)` optimizes to `a` (live gates 2 → 0), certified ===; `AND(b,b) → b` (1 → 0);
a single NOT / a non-idempotent AND is NOT spuriously reduced (the falsifier).

| Artifact (golden) | Before (§8.16) | After (this seal) |
|---|---|---|
| `iiis-1 == iiis-2 == iiis-3` | `4e138415…0619fa85` | `4e1384157c1f1812fd4b1b24a43aae7e0a7a11812f5658060575742b0619fa85` (**UNCHANGED** -- LIBNATIVE) |
| `STDLIB/build/iii/libiii_native.a` | `355462ce…c06fd4b6` | `64acaa37ff641d3f9e528419629c9c4d6a054f79045df9a8bb465fe56fe2c5ca` |

**Verified:** build_stdlib **428/0**; cartographer GATE PASS; compiler `4e138415` unchanged; FULL
corpus **560/0**; `928_hdl_opt`=99.

**§8.17 sealed at:** 2026-05-29.

### §8.18 — III → Silicon SX4: the scalable multi-axiom AEU (the bolsters complete) (2026-05-29)

`numera/aeu.iii` extended (`aeu_set_lane`/`aeu_check_n`/`aeu_and_tree_certified`): the AEU scales from
2 fixed lanes to N axioms. `aeu_check_n` = conjunction over n lane bits (any violated lane caught).
`aeu_and_tree_certified(n)` = an n-input AND-tree built from universal NANDs, `hdl_equiv2`-certified
=== a native n-way AND over all 2^n inputs -- the scalable hardware verifier, proven correct for n
axioms. Compiler-UNREFERENCED -> LIBNATIVE.

Corpus 929: 3- and 4-lane conjunction (a violation in ANY lane caught); the AND-tree certified for
n = 2, 3, 4; the n-lane machinery reproduces the existing 2-lane real-axiom verdict (consistency).

| Artifact (golden) | Before (§8.17) | After (this seal) |
|---|---|---|
| `iiis-1 == iiis-2 == iiis-3` | `4e138415…0619fa85` | `4e1384157c1f1812fd4b1b24a43aae7e0a7a11812f5658060575742b0619fa85` (**UNCHANGED** -- LIBNATIVE) |
| `STDLIB/build/iii/libiii_native.a` | `64acaa37…6fe2c5ca` | `4aa5919bd2f7adc48d660074b9a7afd9beed222d26ee7101baa59cb4fe61ca3b` |

**Verified:** build_stdlib **428/0**; cartographer GATE PASS; compiler `4e138415` unchanged; FULL
corpus **561/0**; `929_aeu_scale`=99.

**THE SILICON-FRONTIER BOLSTERS ARE COMPLETE:** SX1 (sequential / DFlipFlop) + SX2 (realistic
gate-delay + fan-out capacitance) + SX3 (the certified netlist optimizer) + SX4 (the scalable
n-axiom AEU). The III→Silicon frontier now lowers STATEFUL logic, costs it with realistic
timing/capacitance, OPTIMIZES it via proven rewrites, and enforces an arbitrary axiom set in
certified parallel hardware -- every step truth-table or kernel certified, every NP-hard boundary
(optimal placement, minimum-gate synthesis) named and left to the toolchain.

**§8.18 sealed at:** 2026-05-29.

### §8.19 — Sovereign Enhancement G2: 𝒱 certified-monotone + non-gameable (2026-05-29)

`forcefield/ripple_metric.iii` + `rm_value`: the value `𝒱` the Enhancement Theorem maximizes is bound
and certified to DISCRIMINATE — the first non-vacuity connection (`III-SOVEREIGN-ENHANCEMENT-
COORDINATION.md` G2). `𝒱 = rm_value = rm_j` is a total `u64` and a pure function of `(good, noise,
sep)`, so `ΔV>0 ⟺` a real structural gain — non-gameable by relabelling. Compiler-UNREFERENCED ->
LIBNATIVE.

Corpus 930: a noise edge strictly LOWERS `𝒱`; a load-bearing edge RAISES it; a unifiable duplicate
LOWERS it; `𝒱` is relabel-invariant (same structure, different labels → same `𝒱`).

| Artifact (golden) | Before (§8.18) | After (this seal) |
|---|---|---|
| `iiis-1 == iiis-2 == iiis-3` | `4e138415…0619fa85` | `4e1384157c1f1812fd4b1b24a43aae7e0a7a11812f5658060575742b0619fa85` (**UNCHANGED** -- LIBNATIVE) |
| `STDLIB/build/iii/libiii_native.a` | `4aa5919b…fe61ca3b` | `43387216 98f2297ba6773ba0bd22504850f017689a57e2e0b46e6da0c9aca874` |

**Verified:** build_stdlib **428/0**; cartographer GATE PASS; compiler `4e138415` unchanged; FULL
corpus **562/0**; `930_ripple_value`=99. Spec: `DOCS/III-SOVEREIGN-ENHANCEMENT-COORDINATION.md`.

**§8.19 sealed at:** 2026-05-29.

### §8.20 — Sovereign Enhancement G1: unified φ + non-vacuity falsifier ledger (2026-05-29)

`forcefield/integrity.iii` (`phi_check`, `phi_nv`): the single non-destruction predicate
`φ = ` commit-admissible (`cg_decide` 5-dim) `∧` datum-axiom-valid (`aeu`). `phi_nv` is the FALSIFIER
LEDGER — every dimension provably REJECTS a bad input AND ADMITs a good one (a gate that cannot say no
is a rubber stamp). HONEST: `φ_checked` is a sound under-approximation of `φ_true` (undecidable);
domination is a per-organ obligation, not a completeness claim. Compiler-UNREFERENCED -> LIBNATIVE.

Corpus 931: `phi_nv()==99` (commit 5 reject paths + admit; seal: unwitnessed drift rejected, witnessed
admitted; aeu: unreachable/malformed rejected); `phi_check` admits all-good + reachable, rejects any
bad commit dimension OR a bad datum.

| Artifact (golden) | Before (§8.19) | After (this seal) |
|---|---|---|
| `iiis-1 == iiis-2 == iiis-3` | `4e138415…0619fa85` | `4e1384157c1f1812fd4b1b24a43aae7e0a7a11812f5658060575742b0619fa85` (**UNCHANGED** -- LIBNATIVE) |
| `STDLIB/build/iii/libiii_native.a` | `43387216…c9aca874` | `dd7963baed75d78f7a742ab36acf7dadcec6f7e3098453f2669c78e82e2597c5` |

**Verified:** build_stdlib **429/0**; cartographer GATE PASS; compiler `4e138415` unchanged; FULL
corpus **563/0**; `931_phi_ledger`=99.

**§8.20 sealed at:** 2026-05-29.

### §8.21 — Sovereign Enhancement G3: the real argmax M-search (2026-05-29)

`forcefield/ripple_search.iii` (`rs_argmax`, `rs_strict_best`): the improver selects the
VALUE-MAXIMAL admissible candidate (the emergent `s★`), not greedily the first; and returns NONE --
the certified `s₀∈M` abstention -- when no candidate strictly beats the incumbent. Ties break by least
index (deterministic ⊑). HONEST: M is the supplied egraph FRONTIER (`s★` is frontier-local, not a
global optimum). Compiler-UNREFERENCED -> LIBNATIVE.

Corpus 932: argmax over {3,7,5} = id1 (not the first); `strict_best` abstains when all candidates <
incumbent (`s₀∈M`); tie -> least index; the BETTER of two admissibles is chosen (not greedy).

| Artifact (golden) | Before (§8.20) | After (this seal) |
|---|---|---|
| `iiis-1 == iiis-2 == iiis-3` | `4e138415…0619fa85` | `4e1384157c1f1812fd4b1b24a43aae7e0a7a11812f5658060575742b0619fa85` (**UNCHANGED** -- LIBNATIVE) |
| `STDLIB/build/iii/libiii_native.a` | `dd7963ba…e2e2597c5` | `d1db1bae89365c6ba919c7e7087d6f8398e552137d7d18412eae02cfe2d79b15` |

**Verified:** build_stdlib **430/0**; cartographer GATE PASS; compiler `4e138415` unchanged; FULL
corpus **564/0**; `932_ripple_search`=99.

**§8.21 sealed at:** 2026-05-29.

### §8.22 — Sovereign Enhancement G5: the inductive bridge (sample → ∀) (2026-05-29)

`numera/induct.iii` (`ind_forall`): lifts a sampled property to a UNIVERSAL theorem via the kernel's
Nat eliminator -- `ind_forall(P,z,s,n) = tc_check(natrec(P,z,s,n), P n)` is 1 iff base `z:P(0)` and
step `s:Πk.P(k)→P(succ k)` type-check, i.e. `∀n. P(n)`; a false universal has no well-typed step -> 0.
The sample→theorem bridge -- the kernel disposes, no sample decides. HONEST: covers
inductively-characterised properties (Nat/W/Id via natrec/wrec/J); residual sampled invariants are
named in the φ map. Compiler-UNREFERENCED -> LIBNATIVE.

Corpus 933: const-`Bool` motive + identity step -> `∀n` certified (1); a wrong-typed step (returns
`Nat`, not `Bool=P(succ k)`) -> false universal REJECTED (0).

| Artifact (golden) | Before (§8.21) | After (this seal) |
|---|---|---|
| `iiis-1 == iiis-2 == iiis-3` | `4e138415…0619fa85` | `4e1384157c1f1812fd4b1b24a43aae7e0a7a11812f5658060575742b0619fa85` (**UNCHANGED** -- LIBNATIVE) |
| `STDLIB/build/iii/libiii_native.a` | `d1db1bae…2d79b15` | `681691e9e36c759e6cc1287056cffb9c4ee37ad1b7b95e9c71ed949f1daacb75` |

**Verified:** build_stdlib **431/0**; cartographer GATE PASS; compiler `4e138415` unchanged; FULL
corpus **565/0**; `933_induct`=99.

**§8.22 sealed at:** 2026-05-29.

### §8.23 — Sovereign Enhancement G4: the bilateral certificate (coordination COMPLETE) (2026-05-29)

`forcefield/commit_gate.iii` extended (`cg_cert_action`, `cg_cert_abstain`): the commit is a kernel
theorem, not a bare verdict. An ACTION earns `cg_cert_action` (⊢ `s★⊳s₀`: φ ADMIT ∧ 𝒱 strictly up ∧
proof checks); an ABSTENTION earns `cg_cert_abstain` (⊢ `s₀∈M`: frontier searched ∧ no candidate beats
incumbent). Neither earnable vacuously -- the BC clause of `NV ∧ KT ∧ BC`. Compiler-UNREFERENCED ->
LIBNATIVE.

Corpus 934: action granted only for φ ∧ strict-gain ∧ proof (no-op / regression / φ-violation /
unproven each REFUSED); abstention granted only for searched ∧ no-better-move (improvable / unsearched
each REFUSED).

| Artifact (golden) | Before (§8.22) | After (this seal) |
|---|---|---|
| `iiis-1 == iiis-2 == iiis-3` | `4e138415…0619fa85` | `4e1384157c1f1812fd4b1b24a43aae7e0a7a11812f5658060575742b0619fa85` (**UNCHANGED** -- LIBNATIVE) |
| `STDLIB/build/iii/libiii_native.a` | `681691e9…aacb75` | `9776af672937c00037d10f3c74bd4eaa843ba0c6fa2ec96addeefa859b684124` |

**Verified:** build_stdlib **431/0**; cartographer GATE PASS; compiler `4e138415` unchanged; FULL
corpus **566/0**; `934_cert`=99.

**THE SOVEREIGN ENHANCEMENT COORDINATION IS COMPLETE:** G1 (φ unified + non-vacuous) · G2 (𝒱
certified-monotone) · G3 (real argmax M-search) · G5 (inductive sample→∀ bridge) · G4 (bilateral
certificate). Every Enhancement-Theorem symbol is bound to an organ that can say no; the improver
produces meaningful, kernel-certified enhancements -- or kernel-certified abstentions -- on III's real
source, never a rubber stamp. Spec: `DOCS/III-SOVEREIGN-ENHANCEMENT-COORDINATION.md`.

**§8.23 sealed at:** 2026-05-29.

### §8.24 — Evolution baseline: compiler reseal `4e138415` → `196b0c5f` (the `.iii` codegen fixed point moves) (2026-05-31)

BATCH 0 of the production-ready Evolution: re-establish the sealed green baseline so III's
self-enhancement engine (the Sovereign Ripple Optimizer + `commit_gate` + `ripple_apply`) is unblocked.
The live `iiis-2` had drifted from the pinned golden because the `.iii` compiler source was enhanced but
never resealed (the documented "awaiting build_iiis2 reseal" WIP state). The enhancements are functional
codegen changes, so the drift is **legitimate — proven, not assumed**:

- `cg_r3` `r3_reserve_slot()` — bounds the previously-unchecked `R3_G_LOCAL_COUNT` bumps (match
  scrutinee, loop counter, struct-field padding) that could push the local count past `R3_MAX_LOCALS`
  (64), OOB-read `R3_LOCAL_OFF/LEN[>=64]`, and overrun the emitted frame; at the cap it flags
  `R3_E_INTERNAL` and clamps (clean compile-fail, never memory corruption). Byte-identical codegen for
  every <64-local function (the entire corpus + the compiler itself).
- `cg_rm2` `RM2_CHBUF` — a dedicated 1-byte scratch so `cg_emit_ch` can never alias `RM2_NUMBUF[0]`.
- the `sid` rewrite, the PE emitter (`iii_cg_pe_iiis1`), and the compositions table.

**Convergence — the textbook two-step heal of a codegen bug-fix.** Because the *old* compiler carried
the `CHBUF` aliasing emission, the `iiis-2` it builds is a TRANSITIONAL stage, not the fixed point:
`4e138415` (old) → `7aded1aa` (transitional: old compiler emits new source) → `196b0c5f` (stable: the
new compiler re-emits itself). Verified **`iiis-2 == iiis-3 == iiis-4`** (build_iiis2 then build_iiis3
each reproduce `196b0c5f`; one extra round confirmed self-reproduction). The **joint compiler/lib fixed
point** holds: the final compiler rebuilds `libiii_native.a` byte-identically to `13fa921e`.

| Artifact (golden) | Before (§8.23) | After (this reseal) |
|---|---|---|
| `iiis-1 == iiis-2 == iiis-3` | `4e138415…0619fa85` | `196b0c5f5159329b2e419aecb561ee57980d62bcc892ea84f260559bcdfaa990` (**MOVED** — `.iii` codegen source enhanced; new fixed point proven `iiis-2≡iiis-3≡iiis-4`) |
| `STDLIB/build/iii/libiii_native.a` | `9776af67…b684124` | `13fa921e7da475a42ae06a64eaca5a181e26a4033ade7c41d60834e6273f2092` |

**Verified:** build_stdlib **434/0**; FULL corpus **652/0** (one `817_xii_lower_decide` link flake
re-ran green — an OneDrive/Defender in-place-overwrite lock on the live `.exe` (`ld returned 1`, zero
undefined refs), defeated by `rm`-before-relink; NOT a defect — it compiles+links+runs=99 standalone);
bench **7/0** correctness; stage-1 `--check-corpus` **59/0** on both `build_iiis2` and `build_iiis3`.
Golden re-pinned in the three Ripple executors (`ripple_apply` / `pcc_synthesize` / `ripple_extract`);
iiis-1 re-frozen to the new fixed point (iiis-0 can no longer re-seed from scratch — pre-existing, per
`DOCS/III-DISPOSITION-EXECUTION.md`).

**This unblocks the self-enhancement engine:** `ripple_apply`'s GATE2 (compiler byte-UNCHANGED =
LIBNATIVE) now holds against the live `iiis-2`, so III can certify + apply + gate its own refactorings
against a true, current golden.

**§8.24 sealed at:** 2026-05-31.

### §8.25 — The self-enhancement engine SHARPENED: B0.5 gate + B1 𝒱 + B2 cost_lattice + B3 multi-file + B4 capstone (all LIBNATIVE) (2026-05-31)

With the baseline resealed (§8.24, golden `196b0c5f`) and `ripple_apply`'s GATE2 holding again, five
compounding LIBNATIVE batches sharpened III's own Sovereign Ripple Optimizer -- each ordered so the
prior makes the next better-judged (the compounding mandate). **The compiler stays byte-identical to
`196b0c5f` throughout** -- every change is a `STDLIB/.iii` or `.sh` edit the compiler never references,
so it is LIBNATIVE by construction. The lib is LIBNATIVE-evolved alongside concurrent zk_air work, so
its mhash floats and is intentionally not pinned here (the corpus, not the lib hash, is the contract).

| Batch | Commit | The compounding move |
|---|---|---|
| B0.5 | `e8c1cb3` | Gates hardened (rm-before-relink + retry) vs the OneDrive/Defender lock that made GATE1/GATE3 spuriously fail with `ld returned 1` (zero undefined refs) -> would falsely REVERT a good self-edit. A gate that tolerates a hostile filesystem -- the one thing a self-enhancement loop cannot have lie to it. |
| B1 | `13d8b12` | **𝒱 (ripple_metric) is the SINGLE value authority** -- `ripple_extract`'s C2 MDL boundary verdict now DEFERS to `rm_extract_improves` (was an independent 2nd model that could diverge). KAT 954: break-even/underwater boundaries rejected; the unification invariant `rx_delta_j_positive == rm_extract_improves` holds on every case. |
| B2 | `72ac9b9` | **cost_lattice is the SINGLE cost authority across the whole generate->cost->select pipeline** -- `oi_select_costed` costs realizations via `cl_dot`; `oi_egraph_cost` sources egraph's term-extraction cost via `cl_dot`. KATs 955/956: an invalid-cheapest is pruned; the lattice genuinely drives the term choice in BOTH directions (swap the microarch vectors -> the other term wins). |
| B3 | `64a21ac` | `ripple_apply` **MULTI-FILE atomic** apply/revert -- a coordinated refactoring (new file + re-pointed callers) backs up + reverts ALL targets together on any gate failure (the old single-`$TARGET` revert stranded the rest, breaking the inductive safety invariant). Verified by a controlled fast revert test. |
| B4 | `087e743` | Capstone KAT 957: the sharpened organs COMPOSE into one certified decision (value-positive ∧ realization-valid ∧ gate-admits), prove-the-negative on each input (a real 𝒱-negative move / no valid realization / gate down -> not admitted). |

New KATs: **954** (ripple MDL), **955** (optinvoke cost-lattice), **956** (egraph cost-lattice), **957**
(engine compound). **Verified (QUICK gates, per the no-full-until-final directive):** every increment
`build_stdlib` FAIL=0 + its targeted KATs = 99 + the affected organ family unregressed; compiler
`196b0c5f` unchanged throughout. A single final full gate (full corpus + bench + stage1) closes the
Evolution.

**Principle.** B1 gave the engine ONE value lens (`𝒱`); B2 ONE cost lens (`cost_lattice`) -- so every
future self-optimization is judged by a single, principled, non-gameable standard end-to-end. That
coherence IS the compounding the batch order was built to produce: a self-improving system can only be
trusted to improve itself when it judges worth and cost each through one honest, falsifiable lens.

**§8.25 sealed at:** 2026-05-31.

### §8.26 — BATCH 4 AT-SCALE: the sharpened engine enhancing III's own body (LIBNATIVE, ongoing) (2026-05-31)

With the engine sharpened (§8.25), it was run AT SCALE over III's own source -- the user's stated method:
read-only Workflow fan-out (the engine's analysis), guiding-hand selection (MDL + live-edit respect +
prove-the-negative), in-session edit, QUICK gate, commit. Each scan = ~14 Explore agents, every candidate
adversarially verified (default-refute). The LOOP (continues until the increments are genuinely exhausted):

| # | Scan angle | Shipped self-edit | Commit |
|---|---|---|---|
| 1 | cross-module duplication | `closure_eq`/`closure_verify_against`/`attest_eq` -> all delegate to the canonical `verba/timing_safe.iii::timing_safe_eq` (3 copies -> 1 authority; ΔJ>0; −19 lines; behavior-preserving) | `015d1ae` |
| 2 | vacuous gates + unification gaps | `ecdsa_p384` `[E-EC-3]`: sign + sign_det could EMIT a degenerate (r==0/s==0) signature its own verify rejects -- mirror the proven P-256 guard + retry; new falsifier `958` (the missing P-384 prove-the-negative) | `2c71347` |
| 3 | crypto cross-variant consistency | `ecdsa_p384` `[E-EC-2]` range guard: verify ACCEPTED out-of-range/malleable r,s>=n (P-256 rejects) -- reduction-based check (single source of n = the field), falsifier `959` | `fdaef17` |

**Scan 3 CONVERGENCE (the loop is finding its frontier).** Across 6 sibling crypto families the scan
confirmed CONSISTENCY almost everywhere -- the genuine gaps were the two P-384 ECDSA checks (degenerate
`958`, range `959`); the rest is correctly ABSTAINED: the AEAD family (ChaCha20/XChaCha20-Poly1305,
AES-GCM, AES-SIV) is uniformly constant-time tag-verify + tamper-tested; the remaining "missing checks"
are by-design fixed-size contracts (XChaCha20's nonce IS the 24-byte type; SHA-256's output is fixed 32B)
or opt-in policy (P-384 low-s is BIP-62, not FIPS -- verify is correct without it). 3 scans -> 3 genuine
self-edits; the engine's value is telling the genuine gap from the intentional design.

**The honest result is the point.** A heavily-deduped, FIPS/RFC-faithful system yields FEW genuine
improvements, and the engine's value is telling the difference -- it ABSTAINED (correctly) far more than
it shipped: the GF(998244353) `sf_*` duplication is in the user's LIVE zk_air work (respect, don't
clobber); the 3-line `_xdc_in`/`_xjn_in` private helpers are MDL-below-threshold (a new boundary would not
earn itself); katabasis cross-type `*_write_admissible` was deferred (needs a parameterized generic). Scan
1 (duplications) found cosmetic redundancy; scan 2 (prove-the-negative lens) found a latent CORRECTNESS
bug -- the higher-order payoff of turning the engine's "can this gate say NO?" discipline on III itself.

New KATs: **958** (ecdsa_p384 zero-r/s falsifier). All increments QUICK-gated (build_stdlib FAIL=0 +
targeted KATs = 99); compiler `196b0c5f` unchanged (every edit LIBNATIVE). The ONE full gate (corpus +
bench + stage1) runs only when the loop concludes.

**§8.26 sealed at:** 2026-05-31 (ongoing).
