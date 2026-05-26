# STAGE1-PORT-INDEX — `.c` ↔ `.iii` Port Status

This index pairs every C translation unit in the live `iiis-0` bootstrap
compiler with its `.iii` self-host port. The C side is **live** (compiled
by `build_iiis0.sh` into `COMPILED/iiis-0.exe`). The `.iii` side is the
**stage-1 mirror** — it is *not* yet linked into the live binary; it is the
in-progress self-host source intended to eventually replace the C TUs.

> Status terms used below:
> * **CARRIES** — the `.iii` port has the full surface area of the `.c`
>   counterpart.
> * **PARTIAL** — implements some of the `.c` functions; gaps documented
>   per-file.
> * **SKELETAL** — only externs/types declared; bodies are stubs.

---

## §1. The 18 paired translation units

| # | Live `.c` (in `COMPILER/BOOT/`) | Stage-1 `.iii` (in `COMPILER/BOOT/`) | Status | Notes |
|---|---|---|---|---|
| 1  | `acc.c`           | `acc.iii`           | PARTIAL | ACC Wall-Y composed-delta admit. |
| 2  | `ast.c` + `ast_impl.c` + `ast_accessors.c` | `ast.iii`         | SKELETAL | Marker file (26 LOC); bodies in `ast_impl.c`. |
| 3  | `cg_r0.c` + `cg_r0_accessors.c`   | `cg_r0.iii`         | PARTIAL | Ring-0 (kernel) codegen. ~1078 LOC. |
| 4  | `cg_r3.c` + `cg_r3_accessors.c`   | `cg_r3.iii`         | PARTIAL | Ring-3 (user-mode) codegen. ~1461 LOC. The dominant codegen TU. |
| 5  | `cg_rm1.c` + `cg_rm1_accessors.c` | `cg_rm1.iii`        | PARTIAL | Ring -1 (hypervisor) codegen. ~742 LOC. Strings inlined from `_strs_rm1.iiifrag` / `_rm1_hv.iiifrag` (now purged — sources contain the inlined arrays directly). |
| 6  | `cg_rm2.c` + `cg_rm2_accessors.c` | `cg_rm2.iii`        | PARTIAL | Ring -2 (sanctum) codegen. ~576 LOC. |
| 7  | `ceiling.c`       | `ceiling.iii`       | CARRIES | Trinity-Gate admission ledger; SHA-256 inline; module = `ceiling`. |
| 8  | `emit.c`          | `emit.iii`          | PARTIAL | Binary emission (D1..D18 determinism gates). ~1014 LOC. |
| 9  | `hexad_check.c`   | `hexad_check.iii`   | PARTIAL | Hexad reachability check (R1.A6). |
| 10 | `jit_emit.c` + `jit_emit_accessors.c` | `jit_emit.iii`    | PARTIAL | JIT instruction encoder. ~924 LOC. |
| 11 | `lex.c` + `lex_runtime.c` + `lex_impl.c`    | `lex.iii`         | PARTIAL | Lexer + 47 keywords + 19 modifiers. ~234 LOC marker; impl in C. |
| 12 | `link.c`          | `link.iii`          | PARTIAL | Linker (Tarjan closure, manifest). ~1552 LOC. |
| 13 | `main.c` + `main_impl.c`         | `main.iii`         | PARTIAL | CLI entry. |
| 14 | `parse.c` + `parse_impl.c`       | `parse.iii`        | SKELETAL | 17 LOC marker; impl entirely in `parse_impl.c`. |
| 15 | `proof.c`         | `proof.iii`         | PARTIAL | Proof certificate emitter. ~1048 LOC. |
| 16 | `sema.c` + `sema_accessors.c`    | `sema.iii`         | PARTIAL | Semantic analyzer. ~2058 LOC. |
| 17 | `sid.c`           | `sid.iii`           | PARTIAL | Side-effect Inverse Derivation. ~1225 LOC. |
| 18 | `witness_alloc.c` | `witness_alloc.iii` | PARTIAL | Witness ID allocator. ~930 LOC. |

## §2. Stage-1 boot mirrors (`COMPILER/BOOT/stage1_port/`)

These are *different* port files — earlier/limited stage-1 explorations
that demonstrate Phase B Path A (`module stage1_*` namespace) without
matching the C TUs' full ABI. Relocated from the former `STAGE1/BOOT/`
into `COMPILER/BOOT/stage1_port/` on 2026-05-08 to keep all stage-1 work
under one roof. (Do not confuse with the §1 mirrors above, which use the
canonical `module <name>` form for ABI compatibility.)

| File | Module | Subject |
|---|---|---|
| `stage1_port/acc.iii`           | `stage1_acc`           | ACC Wall-Y exploration. |
| `stage1_port/ceiling.iii`       | `stage1_ceiling`       | Bitmap-based ledger; SHA-256 deferred. |
| `stage1_port/hexad_check.iii`   | `stage1_hexad_check`   | Reachability bitmap. |
| `stage1_port/sha256.iii`        | `stage1_sha256`        | FIPS-180-4 implementation. |
| `stage1_port/witness_alloc.iii` | `stage1_witness_alloc` | Witness ID allocator. |

## §3. C-side support TUs (no `.iii` mirror needed)

These C files are bootstrap-compiler infrastructure (accessors / impls
for the §1 TUs); they are not separately ported. They will be folded
into the corresponding `.iii` TU when the port reaches CARRIES status.

```
ast_impl.c            → folded into ast.iii eventually
ast_accessors.c       → folded into ast.iii
parse_impl.c          → folded into parse.iii
main_impl.c           → folded into main.iii
lex_impl.c            → folded into lex.iii
lex_runtime.c         → folded into lex.iii
sema_accessors.c      → folded into sema.iii
emit_accessors.c      → folded into emit.iii
jit_emit_accessors.c  → folded into jit_emit.iii
cg_r3_accessors.c     → folded into cg_r3.iii
cg_r0_accessors.c     → folded into cg_r0.iii
cg_rm1_accessors.c    → folded into cg_rm1.iii
cg_rm2_accessors.c    → folded into cg_rm2.iii
```

## §4. Smoke tests (`COMPILER/BOOT/smoke/`)

7 `.iii` files exercising compiler internals at the smoke level:

```
smoke_main.iii         smoke_modifiers.iii
smoke_r0.iii           smoke_r3.iii
smoke_rm1.iii          smoke_rm2.iii
_hp.iii                                  (hot-path probe)
```

Run via `bash run_all_corpora.sh` after the 2026-05-08 reorg
(see `STDLIB/scripts/run_corpus.sh` and `COMPILER/BOOT/stage1_corpus/run_corpus.sh`
for the existing two; `run_all_corpora.sh` is the unified driver).

## §5. Stage-1 corpus (`COMPILER/BOOT/stage1_corpus/`)

57 stage-1 `.iii` programs verifying iiis-0 language features. Driven by
`stage1_corpus/run_corpus.sh`. Expected exit codes encoded in the script.
Status as of 2026-05-08: 30/30 + 24 resolution-corpus tests in the
runnable matrix per `STAGE1/PROBE/FEATURE_MATRIX.md`.

## §6. Phase B path A — recommended progression

Per `STAGE1/PROBE/FEATURE_MATRIX.md`, the remaining stage-1 work is:

```
Phase B0  Add iiis-0 driver flags: --compile-only, --link multi-obj, multi-input
Phase B1  Patch parse_const_decl for [T; N] literals (parser fix)
Phase B2  First TU port: ceiling (158 LOC)        ← CARRIES status example
Phase B3  Iterate by size:
            acc → hexad_check → proof → witness_alloc → sid →
            jit_emit → emit → link → sema → cg_rm2 → cg_rm1 →
            cg_r0 → cg_r3 → lex → ast → parse → main
Phase B4  Behavioral equivalence corpus per ported TU
Phase B5  Stage-2 fixed point (mhash(iiis-1.o) == mhash(iiis-2.o))
Phase B6  Sanctum sealing (Stage 4) — `sanctum.compile_module` (seal_id 9)
```

## §7. Provenance

Created during the 2026-05-08 architectural refactor (item 5 of the 10-item
harmonization sequence). The file inventory reflects the pre-refactor C
TU layout and the post-refactor stage1_port relocation.
