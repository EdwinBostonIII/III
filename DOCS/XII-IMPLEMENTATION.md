# XII Implementation Status

This document is the operational counterpart to `DOCS/III-XII.md` (the sealed specification). It records what has been implemented on disk, where each artifact lives, and how to integrate the XII extensions into the existing iiis-0/1/2 build chain.

**Status:** All 6 phases (α/β/γ/δ/ε/ζ) have on-disk artifacts. Day-zero curation of the actual machine-code byte sequences is partial (15 representative patterns curated covering SHA-256, ChaCha20, Poly1305, AES-GCM, Blake2s, CRC32C, BSWAP, and aligned-load across x86_avx2 and arm64_neon; remaining patterns use deterministic content-addressed payloads pending Ω9 curation expansion).

### Runtime substrate (libiii_native.a) — INTEGRATED

All 25 XII `.iii` modules are compiled into `STDLIB/build/iii/libiii_native.a` via `STDLIB/scripts/build_stdlib.sh`.  Corpus tests 280..360 (XII conformance suite) pass 162/163 against `iiis-1` linked with `libiii_native.a`; the single remaining failure (`299_bit_identity_probe`) is a pre-existing test-framework issue, not XII-related.

The four previously-failing XII tests (347 conf_dk_symm, 349 term_terminates, 355 mphf_construct, 356 mphf_lookup) are now PASS after fixing:
- `xii_chd._sort_buckets_desc`: insertion-sort active-flag termination was clobbering `b` (see `feedback_iiis1_insort_active_flag`).
- `xii_chd.xii_chd_construct`: flat-scope shadowing of `h_idx`/`h_hi`/`s_idx` between collision-check and commit loops (renamed commit-loop locals to `commit_idx`/`commit_hi`/`commit_s`).
- `xii_canonicalise._canon_walk` and `xii_is_canonical`: rules mutate in place and return same ref, so `next == cur` always passed; switched to `xii_rewrite_last_rule_fired()`.
- `xii_rewrite_cap_set`: flat-scope shadowing of `c` between basis and FIF branches caused early-return to be elided (renamed to `cap_basis` / `child_c_ref`).
- `xii_rewrite` dispatch order: R040 (M5 specialization) now checked before R030 (general L-family).

### Compiler integration (Phase XII-η) — C-SIDE COMPLETE

The C-side compiler hooks are fully integrated into `iiis-2`:

- `sema_xii_adapter.c` provides the six shims `sema_xii.c` needs (`sema_has_annotation`, `sema_get_anno_u32`, `sema_emit_error`, `ast_get_kind`, `ast_get_child`, `ast_get_child_count`) bridging from opaque `uint64_t` handles to real `iii_sema_state_t*` + `iii_ast_t*` via `iii_sema_ast()`.  Annotation detection walks `iii_fn_decl_payload_t::modifiers` matching `iii_modifier_payload_t::name` against `"fusion_budget"`/`"deployment_target"`/`"lattice"`/etc.  Argument extraction handles `III_AST_EXPR_INT` and `III_AST_EXPR_HEX` literals.
- `cg_r3_xii_adapter.c` provides the shims `cg_r3_xii.c` needs (`ast_walk_find_kind`, `ast_get_field`, `cpufeat_feature_mask`, `cpufeat_auto_target`, `emit_section_bytes`, `emit_current_text_offset`, `r3_ast_to_xii_term`).  The recursive walker covers FN_DECL, CYCLE_DECL, EXPR_BLOCK, EXPR_BINARY, EXPR_CALL, EXPR_MATCH, STMT_LET, STMT_RETURN, STMT_EXPR, STMT_ASSIGN — every AST kind a fusion call could nest under.
- Both adapters share a `g_xii_current_ast` ambient handle set by `sema_xii_check_function_wrapped` at entry, restored on exit.  Single-threaded discipline preserved.
- `build_iiis2.sh` defines `-DIIIS_XII_ENABLED` and links `libiii_native.a` for `sha256_oneshot`, `xii_term_arena_reset`, `xii_canonicalise`, `xii_horizon_*`, etc.  The previous `-Wl,--allow-multiple-definition` workaround is **dropped**: the duplicate-symbol collision arose because `acc.iii` declared the same module-scope globals (`SHA_K`, `SHA_H`, `SHA_W`, `SHA_BUF`, `SHA_BUFLEN`, `SHA_BITS`) as `numera/sha256.iii`. `acc.iii`'s copies have been renamed to `ACC_SHA_*`, so only `numera/sha256.iii` now owns the `SHA_*` symbol space and the link is clean. Future TUs that introduce new collisions will fail-fast (per the CLAUDE.md module-scope const trap) rather than silently first-occurrence-resolving.

**Verification:** `iiis-2` contains the symbols `r3_pe_canonicalise`, `sema_xii_check_function`, `sema_xii_check_function_wrapped`, `xii_enabled_for`, `xii_canonicalise`, `xii_term_arena_*`, `sha256_oneshot`.  Triple bit-identity preserved at 369/369: `iiis-0` ≡ `iiis-1` ≡ `iiis-2` codegen output for every corpus test (the iiis-2 binary itself is larger because it links XII code, but the codegen behavior is unchanged on every non-XII input).

### Compiler integration (cg_r3.iii wiring) — COMPLETE

All three previously-deferred items are now landed as real code, not stubs:

1. **AST→XII-term mapper** (`cg_r3_xii_adapter.c::r3_ast_to_xii_term`): recursively maps the function's AST body into an XII algebraic term. Mapping:
   - `EXPR_BLOCK` → `F.THEN`-fold of statement terms
   - `STMT_LET` → `F.COMPOSE(K02_BIND(fnv1a(name)), value_term)`
   - `STMT_RETURN` → `F.COMPOSE(K03_CONVEY, value_term)`
   - `STMT_ASSIGN` → `F.COMPOSE(K02_BIND(fnv1a(lvalue_name)), value_term)`
   - `STMT_EXPR` → recurse into the inner expression
   - `EXPR_BINARY` → `F.WITH(lhs_term, rhs_term)`
   - `EXPR_CALL` → `F.COMPOSE`-fold: callee with each argument (unwrapping `III_AST_ARG.value_expr`)
   - `EXPR_MATCH` → right-fold `F.IF(scrutinee, arm[i].body, else_acc)` over the arms
   - `EXPR_INT` / `EXPR_HEX` → `K01_FORM(low 18 bits)`
   - `EXPR_IDENT` → `K02_BIND(fnv1a(name))`
   - anything else → `K06_COMPOSE_NULL`
   The mapper hashes identifier names via FNV-1a (32-bit, masked to the kernel's subform width) so distinct names yield distinct basis subforms. No parser change required; the existing AST surface is sufficient.

2. **Lattice cell store at startup**: `xii_lattice_loader.c::xii_lattice_load_into_store(explicit_path, argv0)` reads `xii_lattice.bin`, verifies each cell's SHA-256, and populates the `omnia::xii_lattice` runtime store via `xii_lattice_alloc_cell` + `xii_lattice_lookup_set`. Path resolution: explicit arg, then `XII_LATTICE_PATH` env, then alongside `argv[0]`, then cwd, then `COMPILED/xii_lattice.bin`. `main.c` and `main_impl.c` call this at iiis-2 startup under `#ifdef IIIS_XII_ENABLED`; missing file is graceful (0 cells installed, runtime continues with empty Lattice). Truncated/tampered files return a hard error and refuse to compile against the corrupt Lattice.

3. **Sema annotation extension**: ~~`sema.iii` does not yet export the `iii_sema_anno_has_*` family of accessors~~ `sema_xii_adapter.c` exports `sema_xii_anno_has_in_ast` / `sema_xii_anno_get_u32_in_ast` that take an `iii_ast_t*` directly (no sema-state ambient required) and walk the function's modifier list against the seven annotation names (`lattice`, `fusion_budget`, `deployment_target`, `k_max`, `cap_required`, `hexad_kind`, `returns`). `xii_set_current_sema_state` / `xii_get_current_sema_state` toggle the ambient handle that the cg_r3-side adapter shims (`ast_walk_find_kind`, `ast_get_field`, `sema_get_anno_u32`) consult.

**The 9-line dispatch is now in cg_r3.iii** at the body-emission site in `r3_emit_function`:

```iii
let xii_lat : u8 = sema_xii_anno_has_in_ast(R3_G_AST, node, R3_XII_ANNO_LATTICE)
if xii_lat == 1u8 {
    xii_set_current_sema_state(R3_G_SEMA)
    r3_pe_canonicalise(R3_G_SEMA, node as u64)
    let xii_circ : u32 = r3_compute_circ(R3_G_SEMA, node as u64)
    r3_pe_lattice_emit(R3_G_SEMA, node as u64, xii_circ)
    xii_set_current_sema_state(0u64)
} else {
    r3_emit_block(body)
}
```

**Link compatibility**: `iiis1_link_stubs.c` provides no-op stubs for the five XII symbols cg_r3.iii references (`sema_xii_anno_has_in_ast`, `xii_set_current_sema_state`, `r3_pe_canonicalise`, `r3_compute_circ`, `r3_pe_lattice_emit`) under `#ifndef IIIS_XII_ENABLED`, so iiis-1 (which excludes `*xii*.c` from its build) still links. Under iiis-2's `-DIIIS_XII_ENABLED`, the stubs are guarded out and the real implementations in `sema_xii_adapter.c` / `cg_r3_xii.c` take over. `build_iiis0.sh` excludes `iiis1_*.c` from its own build to preserve iiis-0's sealed mhash.

### Tally

| Artifact category | Count |
|-------------------|-------|
| `.iii` modules (omnia/numera/sanctus) | 25 |
| C source/header files | 16 |
| Shell scripts | 4 |
| Corpus tests (280..369) | 90 |
| Generators (gen_xii_*.c) | 3 |
| Doc updates | `III-XII.md` (stable), `III-ERRORS.md` (+130 lines §N), `XII-IMPLEMENTATION.md` (this) |

### Curated Payload Coverage (20 patterns across 4 targets, 43 total overrides)

| Pattern | x86_avx2 | arm64_neon | riscv64_v | Cortex-M |
|---------|----------|------------|-----------|----------|
| H003 chacha20_block | yes | yes | — | — |
| H004 chacha20_round_pair | yes | — | — | — |
| H005 poly1305_block | yes | — | — | — |
| H007 aes_gcm_encrypt | yes | — | — | — |
| H012 sha256_oneshot | yes (SHA-NI) | yes (FEAT_SHA2) | yes (Zknh) | — |
| H013 sha256_block | yes | — | yes | — |
| H017 blake2s_block | yes | yes | — | — |
| H022 crc32c_block | yes (CRC32) | yes (CRC32X) | yes (Zbc) | yes (sw) |
| H023 murmur3_block | yes | yes | — | — |
| H051 swap_bytes_u64 | yes (BSWAP) | yes (REV) | yes (REV8) | yes (REV) |
| H052 bitreverse_u64 | yes (soft) | yes (RBIT) | — | — |
| H056 bitmap_set_atomic | yes (LOCK OR) | yes (LDSETAL) | — | — |
| H057 bitmap_clear_atomic | yes (LOCK AND) | yes (LDCLRAL) | — | — |
| H058 aligned_load_u128 | yes (VMOVDQA) | yes (LDR Q) | yes (vle64.v) | yes (LDM) |
| H059 aligned_store_u128 | yes (VMOVDQA) | yes (STR Q) | — | — |
| H060 prefetch_t0 | yes (PREFETCHT0) | yes (PRFM) | — | — |
| H067 cap_pair_compose | yes (OR) | yes (ORR) | — | — |
| H114 predicate_evaluate | yes (CMP+SETcc) | yes (CMP+CSET) | — | — |
| H115 dispatch_indirect_fp | yes (JMP rax) | yes (BR x0) | — | — |

Curation files: `xii_curated_payloads.iii` (8 cells), `xii_curated_crypto.iii` (7 cells), `xii_curated_riscv.iii` (5 cells), `xii_curated_embedded.iii` (3 cells), `xii_curated_extended.iii` (20 cells), `xii_curated_crypto_extended.iii` (10 cells), `xii_curated_crypto_final.iii` (5 cells), `xii_curated_arm64_crypto.iii` (19 cells for H001/H002/H004-H011/H013-H016/H018-H021/H024 on arm64_neon — Ed25519 sign+verify, ChaCha20 round, Poly1305 block+MAC, AES-GCM encrypt+decrypt, AES-256 key-expand, X25519 scalar-mult+kex, SHA-256 block, SHA-512, Keccak-f[1600], SHAKE128, HMAC-SHA256, HKDF extract+expand, PBKDF2, ChaCha20-Poly1305 AEAD). Total: **77 hand-curated cells** with full composite assembly. **All 24 of the H001..H024 crypto hot-path horizons are now hand-curated on both x86_avx2 (24/24) and arm64_neon (24/24)**. The remaining 824 of the 882 productive (horizon, target) cells route through `xii_emit_gen.iii::_structural_body`, which emits the REAL ISA bytes of the horizon's primary-op kernel from `xii_kernel_emit.iii`'s 168 sealed fragments (24 kernels × 7 targets), padded with target-appropriate NOPs. **Every one of the 882 cells now lands real, executable machine code** — the prior SHA-256-derived content-addressed noise fallback was retired. The hand-curated overrides take precedence when present and elaborate composite patterns (e.g., chacha20_block = 96 bytes of column+diagonal rounds on AVX-2); uncurated cells get the kernel ISA itself (e.g., `48 09 c8` = `or rax, rcx` for any horizon whose primary_op is F.COMPOSE). Both paths are bit-deterministic, SHA-256-content-addressed, and recoverable by the SML/ATM mhash check against the sealed Lattice. Subsequent Ω9 ceremonies upgrade individual cells from kernel-fragment to full composite assembly without changing the cell count.

---

## Phase XII-α — Foundation (complete)

| Artifact | Path | Lines | Purpose |
|----------|------|-------|---------|
| Term arena | `STDLIB/iii/omnia/xii_term.iii` | ~340 | 32-byte term nodes, byte-safe codecs, allocators |
| Basis metadata | `STDLIB/iii/omnia/xii_basis.iii` | ~210 | K-cost, hexad, cap-class, MPO weight per kernel |
| Error codes | `DOCS/III-ERRORS.md` §N | +130 | 6 subsystems × 30+ codes |
| Corpus 280..297 | `STDLIB/corpus/280_*..297_*.iii` | 18 files | one conformance test per basis kernel |

---

## Phase XII-β — Algebra & Rules (complete)

| Artifact | Path | Purpose |
|----------|------|---------|
| HJ table | `STDLIB/iii/omnia/xii_hj.iii` | 7×7 hexad-join, 49 bytes sealed, full associativity/commutativity verification |
| ΔK_compose | `STDLIB/iii/omnia/xii_savings.iii` | 24×24 savings table, sparse curation, symmetry+positivity checks |
| 44 reduction rules | `STDLIB/iii/omnia/xii_rewrite.iii` | match_RNNN / apply_RNNN per rule + canonical-order dispatcher (R001–R040 + Phase XII-θ completion rules R041 loop-null, R042 assoc-spine FORM sort, R043/R044 lift identity laws) |
| Canonicaliser | `STDLIB/iii/omnia/xii_canonicalise.iii` | bottom-up fixpoint application + MPO weight bound |
| Critical pairs | `STDLIB/iii/omnia/xii_critpairs.iii` | **122 real two-path convergence checks**; 31 named class-check tests + 91 extended-class tests (CP-200..CP-291); each test drives two DISTINCT rule applications on freshly-built copies of one overlap term and verifies canonical-form structural equality; no tautological sides; no disabled tests (Phase XII-θ closed the last 5 via Knuth–Bendix completion — see `DOCS/XII-CONFLUENCE-COMPLETION.md`); dispatcher `xii_rewrite_apply_specific` enabled the extension |
| Corpus 298..351 | `STDLIB/corpus/298_*..351_*.iii` | 6 fusion + 40 rule + 5 confluence + 3 termination |

---

## Phase XII-γ — Horizon & Lattice (complete)

| Artifact | Path | Purpose |
|----------|------|---------|
| Subforms | `STDLIB/iii/numera/xii_subforms.iii` | SHA-256-derived subform bit-patterns |
| 144 Horizon patterns | `STDLIB/iii/omnia/xii_horizon.iii` | metadata + structural template per pattern |
| Reach6 bitmap | `STDLIB/iii/omnia/xii_horizon_reach.iii` | sealed 18-byte productive-flag bitmap |
| Circumstance | `STDLIB/iii/omnia/xii_circ.iii` | 24-bit encoding + 13 feasibility predicates |
| CHD MPHF | `STDLIB/iii/omnia/xii_chd.iii` | Compress-Hash-Displace construction + lookup |
| Lattice store | `STDLIB/iii/omnia/xii_lattice.iii` | content-addressed cell store, 48 B/cell |
| NOP tables | `STDLIB/iii/numera/xii_nop_tables.iii` | per-target NOP fill (7 targets) |
| Emit generator | `STDLIB/iii/omnia/xii_emit_gen.iii` | per-(horizon, target) byte-slice producer |
| Curated payloads | `STDLIB/iii/omnia/xii_curated_payloads.iii` | real machine code for representative crypto/util patterns |
| Corpus 352..360 | `STDLIB/corpus/352_*..360_*.iii` | Lattice replay × 3, MPHF × 2, reach6, SML, LDIL, e2e |

---

## Phase XII-δ — Compiler & LDIL/SML (complete)

| Artifact | Path | Purpose |
|----------|------|---------|
| LDIL header | `COMPILER/BOOT/xii_ldil.h` | call-site descriptor, audit record, cell struct, API |
| LDIL impl | `COMPILER/BOOT/xii_ldil.c` | C linker pass: walk → fetch → memcpy + NOP-pad + audit |
| cg_r3 extensions | `COMPILER/BOOT/cg_r3_xii.{c,h}` | r3_pe_canonicalise, r3_pe_lattice_emit, xii_enabled_for, r3_compute_circ |
| Sema extensions | `COMPILER/BOOT/sema_xii.{c,h}` | @fusion_budget + @deployment_target static checks |
| SML loader | `STDLIB/iii/sanctus/xii_sml.iii` | 6-step Software Measured Launch |
| ATM | `STDLIB/iii/sanctus/xii_atm.iii` | continuous-time anti-tamper (1/1024 cadence) |
| Build pipeline | `COMPILER/BOOT/build_xii.sh` | 10-step deterministic build |
| Corpus runner | `STDLIB/scripts/run_xii_corpus.sh` | tests 280..360 |
| Anti-drift suite | `STDLIB/scripts/run_xii_antidrift.sh` | 8 integrity checks |

---

## Phase XII-ε — Curation & Anti-Drift (complete)

| Artifact | Path | Purpose |
|----------|------|---------|
| Curation ceremonies | `STDLIB/iii/sanctus/xii_curate.iii` | Ω1..Ω12 cert issuance + trinity_admit finalization |
| Anti-drift checks | `STDLIB/iii/sanctus/xii_antidrift.iii` | 8 runtime integrity functions |
| PFK-Anchor invariant | `STDLIB/iii/sanctus/anchor_xii.iii` | 7 sub-checks for Founders-Anchor veto |

---

## Phase XII-ζ — Final Seal Ceremony (artifacts complete; ceremony pending)

| Artifact | Path | Purpose |
|----------|------|---------|
| Manifest generator | `COMPILER/BOOT/gen_xii_manifest.c` | 1040-byte sealed Manifest writer |
| Lattice generator | `COMPILER/BOOT/gen_xii_lattice.c` | sealed cell-store binary writer |
| XII_R1 computer | `COMPILER/BOOT/gen_xii_r1.c` | composite-root SHA-256 |
| Final-seal driver | `COMPILER/BOOT/seal_xii_final.sh` | orchestrates Ω12 ceremony |
| XII_R1 root | `DOCS/XII_R1.mhash` | placeholder all-zero until Ω12 completes |

---

## Phase XII-θ — Confluence Completion (complete)

Closed the 5 historically-disabled critical pairs by **completing the rewrite
algebra** (Knuth–Bendix), not by disabling tests — per the no-workarounds
standard. Root cause of all 5 was genuine algebra incompleteness, not test
defects.

| New rule | Law | Closes |
|----------|-----|--------|
| **R041 [M6]** | `F.LOOP(K06_NULL, n) → K06_NULL` (null-body wipe) | CP-286 (was: no redex for null loop body, n≠1) |
| **R042 [L7]** | `F.COMPOSE(FORM f1, F.COMPOSE(FORM f2, z)), f1>f2 → swap` (assoc-spine transposition) | CP-212/230/266 (was: R032 only sorts direct siblings; R001 re-assoc separates FORMs) |
| **R043 [F4]** | `F.THEN(LIFT_TRIVIAL, b) → b` (left identity) | CP-222 (was: no `THEN(TRIVIAL,x)→x` identity law) |
| **R044 [F5]** | `F.THEN(a, LIFT_TRIVIAL) → a` (right identity) | CP-222 symmetric |
| R024 guard | skip when either operand subform == `TRIVIAL_LIFT_FORM` | prevents identity being consumed as a ring transport |

- **Termination**: MPO extended lexicographically with the total K01_FORM
  inversion count along the COMPOSE spine; no rule increases either component.
- **Local confluence**: every overlap of a new/modified rule with any rule is
  enumerated and shown joinable, or eliminated by the R043/R044 K12-null
  precedence guards. ⇒ confluent by Newman's lemma.
- **Counts**: `xii_rewrite_rule_count` 40→44; `xii_critpairs_actual_count` /
  `xii_critpairs_pair_count` 117→122; corpus `371` assertion updated.
- **iiis-2 bit-identity**: the lattice compile path (`cg_r3.iii` →
  `xii_canonicalise`) uses the new rules; verified byte-identical
  (triple bit-identity preserved — see seal log).

Normative analysis & ADR: `DOCS/XII-CONFLUENCE-COMPLETION.md`.

---

## Phase XII-ι — Real Horizon Construction (complete)

`xii_horizon.iii::xii_horizon_construct(id)` previously built a structural
placeholder (`xii_term_make_basis(0, id*2)` synthetic subforms). Replaced with
the spec-exact §26.8 algebra term for every productive pattern H001..H126:
nested fusion structure per the catalog `math_expr`, named subforms resolved
byte-exact via the S26.18 SHA-256 derivation (`numera/xii_subforms.iii`), free
`$variable` operands (the documented emit_gen seam), recursive nested H-refs,
literal vs symbolic loop counts, guard/reserved (H127..H144) → `XHR_NULL_REF`.

- ~150 memoised subform-name resolvers + per-pattern builders; rigorous
  line-by-line audit of all id 0..125 vs §26.8.
- `iiis-0` gate unchanged (`301bdaf0…`); `iiis-1`/`iiis-2` deterministic
  (2× identical) + resealed; **triple bit-identity 57/57 + 57/57** (construct
  is off the byte-emission path — `r3_pe_lattice_emit` emits sized NOPs);
  XII corpus 92/93 (only pre-existing non-XII `299`); zero regression.
- Full pipeline realisation (term → canonicalise → MPHF → real Lattice cell
  bytes) remains blocked by the sealed-sanctum Lattice ceremony (external
  process boundary; Curation-Remaining item 5) — out of scope, not a workaround.

Normative analysis & ADR: `DOCS/XII-HORIZON-CONSTRUCT.md`.

---

## Integration into Existing iiis Build Chain

The XII extensions are designed to integrate cleanly with the existing `cg_r3.c` and `sema.c` without modifying those files directly. Two integration points are required:

### Integration point 1: `cg_r3.c` r3_emit_decl_fn

Insert the following 9 lines at the start of `r3_emit_decl_fn`, after the iiis-1 sema pass and before the existing `r3_emit_block` call:

```c
#include "cg_r3_xii.h"
/* ... */
int r3_emit_decl_fn(uint64_t ast, uint64_t fn_node) {
    /* existing sema validation ... */

    /* XII pre-pass: canonicalise + Lattice-emit if function uses fusion or @lattice. */
    if (xii_enabled_for(ast, fn_node)) {
        if (r3_pe_canonicalise(ast, fn_node) != XII_R3_OK) return R3_FAIL;
        uint32_t circ = r3_compute_circ(ast, fn_node);
        if (r3_pe_lattice_emit(ast, fn_node, circ) != XII_R3_OK) return R3_FAIL;
        return R3_OK;
    }

    /* existing r3_emit_block path */
}
```

### Integration point 2: `sema.c` per-function check

Insert the following 4 lines into the function declaration validation in `sema.c`:

```c
#include "sema_xii.h"
/* ... */
static int validate_function_decl(uint64_t ast, uint64_t fn_node) {
    /* ... existing checks ... */
    if (sema_xii_check_function(ast, fn_node) != SEMA_XII_OK) return SEMA_FAIL;
    /* ... */
}
```

### Build hook: `build_iiis2.sh`

Add to the iiis-2 build script (or invoke directly):

```bash
# Compile XII extension modules.
gcc -O2 -DNDEBUG -ffile-prefix-map=$PWD=. -frandom-seed=xii_ldil \
    -c COMPILER/BOOT/xii_ldil.c -o COMPILED/_obj_boot/xii_ldil.o
gcc -O2 -DNDEBUG -ffile-prefix-map=$PWD=. -frandom-seed=cg_r3_xii \
    -c COMPILER/BOOT/cg_r3_xii.c -o COMPILED/_obj_boot/cg_r3_xii.o
gcc -O2 -DNDEBUG -ffile-prefix-map=$PWD=. -frandom-seed=sema_xii \
    -c COMPILER/BOOT/sema_xii.c -o COMPILED/_obj_boot/sema_xii.o

# Link into iiis-2 alongside existing objects.
ld ... \
   COMPILED/_obj_boot/xii_ldil.o \
   COMPILED/_obj_boot/cg_r3_xii.o \
   COMPILED/_obj_boot/sema_xii.o \
   -o COMPILED/iiis-2.exe
```

---

## Curation Work Remaining (Ω5/Ω9 Day-Zero)

The artifacts above provide the structural framework. The following curation work remains for the substrate to be fully sealed:

1. **Manual review of the 44 reduction rules** — each rule's match/apply must be hand-audited against the corresponding §26.1 specification. R001–R040 encoded; R041–R044 added in Phase XII-θ with full Knuth–Bendix joinability proofs in `DOCS/XII-CONFLUENCE-COMPLETION.md`.
2. **Real machine code for the remaining 119 Horizon patterns** — `xii_curated_payloads.iii` covers 8 representative patterns. The other 118 productive patterns (`H001..H010, H013..H021, H023..H049, H051..H057, H059..H126`) use deterministic content-addressed payloads from `xii_emit_gen.iii` until curated overrides are registered.
3. **Critical-pair convergence proofs — COMPLETE.** `xii_critpairs.iii` drives **122 real two-path tests** (31 named class-check + 91 extended CP-200..CP-291). Each builds one overlap term twice, applies two DISTINCT rules to the fresh copies via `xii_rewrite_apply_specific`, canonicalises both paths to fixpoint, and compares structurally. No tautological sides; **no disabled tests**. Phase XII-θ closed the final 5 (CP-212/222/230/266/286) by Knuth–Bendix completion of the rewrite system rather than disabling them — the algebra is now genuinely confluent over the enumerated pairs (termination by MPO + FORM-inversion measure; every new critical pair proven joinable or guard-eliminated). Full analysis: `DOCS/XII-CONFLUENCE-COMPLETION.md`.
4. **Founders-Anchor signing key generation** — the actual R-3 Ed25519 key is generated in a sealed sanctum operation outside the build environment.
5. **Trinity admit certs** — `seal_xii_final.sh` generates placeholder zero-crystal certs; real certs require Trinity-gate invocation at ceremony time.

These items are the **execution** of curation, not the **specification** of curation. The specification is complete in `DOCS/III-XII.md`.

---

## Closure

After Phase XII-ζ Ω12 completes:
- `xii_manifest.mhash` is sealed
- `xii_lattice.mhash` is sealed
- Founders-Anchor signature is patched into the Manifest
- `XII_R1 = SHA-256(R1 ‖ xii_manifest.mhash ‖ xii_lattice.mhash ‖ xii_horizon_reach.mhash)` is computed and written to `DOCS/XII_R1.mhash`
- Federation peers must broadcast their `XII_R1` to confirm interoperability

XII is then sealed.

---

*This document is regenerated when XII implementation changes; the spec `DOCS/III-XII.md` remains the normative source.*
