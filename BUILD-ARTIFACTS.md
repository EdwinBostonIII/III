# BUILD-ARTIFACTS — What Should Never Be Committed

This file is the .gitignore-equivalent discipline doc for the III repo.
It exists because the repo is **not** under git but still benefits from a
single source of truth on what is *generated* vs *source*. Every entry here
is fully regenerable by re-running the corresponding build script; deleting
it does not lose information.

A one-shot purge command is given at the bottom of this file. Run it
whenever the source tree feels cluttered.

---

## §1. Generated, never source

These directories are output sinks for build scripts. Everything inside
them can be deleted at any time. The corresponding build script will
regenerate it.

| Path | Generator | Notes |
|---|---|---|
| `STDLIB/build/iii/*.iii.o` | `STDLIB/scripts/build_stdlib.sh` | Per-module object files. Deleting forces a full rebuild on next `build_stdlib.sh`. |
| `STDLIB/build/iii/*.iii.o.s` | iiis emit-asm side effect | Pure debug aid (assembly listings). Never consumed by the build chain. |
| `STDLIB/build/iii/libiii_native.a` | `STDLIB/scripts/build_stdlib.sh` | Aggregate archive linked into corpus tests. |
| `STDLIB/build/iii/libiii_native.a.mhash` | `build_stdlib.sh` | Sha256 of the archive. Determinism witness. |
| `STDLIB/build/corpus/*.iii.o`, `*.exe`, `*.exe.s`, `*.iii.o.s`, `*.log` | `STDLIB/scripts/run_corpus.sh` | Per-test build + run output. Test harness regenerates on each run. |
| `COMPILED/iiis-0.exe` | `COMPILER/BOOT/build_iiis0.sh` | The bootstrap compiler. Must be present for any `.iii` work. |
| `COMPILED/iiis-0.exe.mhash` | `build_iiis0.sh` | Determinism witness for the compiler binary. |
| `COMPILED/iiis-0.exe.witness.json` | `build_iiis0.sh` | Build provenance sidecar. |
| `COMPILED/_obj_boot/*.o` | `build_iiis0.sh` | Per-TU C object files for the bootstrap compiler. |
| `STAGE1/PROBE/*.exe`, `*.exe.s`, `*.exe.o`, `*.exe.witness.json`, `*.o`, `*.o.s` | iiis-0 invocation | Build artifacts emitted next to source. Should be relocated under `STAGE1/PROBE/build/` on a future cleanup pass. |
| `STAGE1/BOOT/*.exe`, `*.exe.s`, `*.exe.o`, `*.exe.witness.json`, `*.sealed.o.s` | iiis-0 invocation | Same pattern as PROBE — artifacts adjacent to sources. |

## §2. Generator intermediates (regenerable from `_gen_*.py`)

| Path | Regenerator |
|---|---|
| `COMPILER/BOOT/_strs.iiifrag` | `_gen_cg_rm1_strings.py` |
| `COMPILER/BOOT/_strs_rm1.iiifrag` | `_gen_cg_rm1_strings.py` |
| `COMPILER/BOOT/_rm1_hv.iiifrag` | `_gen_rm1_hv.py` |
| `COMPILER/BOOT/_cg_rm2_lits.iii.frag` | `_gen_cg_rm2_lits.py` |

These are byte-array string tables that get *inlined* into `cg_rm1.iii`
and `cg_rm2.iii` via a copy-paste step. Once inlined into the `.iii`
source, the `.iiifrag` is redundant. Delete it; if you need to re-inline,
re-run the generator.

## §3. Scratch / temporary files

Any file matching the patterns below is scratch and can be deleted on sight:

* `*.tmp`
* `*.bak`
* `*.old`
* `*.orig`
* `core` / `core.*`

## §4. What is **not** an artifact (do NOT delete)

These are sources / canonical state — never delete:

* `STDLIB/iii/**/*.iii` — production stdlib modules
* `STDLIB/iii/SEAL.mhash` — sealed module hashes (the closure root)
* `STDLIB/corpus/[0-9]*_*.iii` — conformance tests
* `COMPILER/BOOT/*.c`, `*.h` — bootstrap compiler source
* `COMPILER/BOOT/*.iii` — stage-1 self-host port (parallel to the C sources)
* `COMPILER/BOOT/build_iiis0.sh` — bootstrap build
* `COMPILER/BOOT/iiis-0.mhash` — golden hash for the bootstrap binary
* `COMPILER/BOOT/stage1_corpus/*.iii` — stage-1 corpus
* `COMPILER/BOOT/smoke/*.iii` — smoke tests
* `STDLIB/scripts/*.sh` — build / corpus drivers
* `DOCS/*.md`, `NOTES/*.md` — specification + operational documentation
* `STAGE1/PROBE/*.iii`, `STAGE1/PROBE/FEATURE_MATRIX.md` — feature probes
* `STAGE1/BOOT/*.iii` — stage-1 boot mirrors (relocated under `COMPILER/BOOT/stage1_port/` after the 2026-05-08 reorg)
* All `*.c` / `*.h` / `README.md` / `tests/*.c` under the 32 R1 subsystem
  directories (ABI, HEXAD, CYCLES, ...)

## §5. One-shot purge command (POSIX bash)

```bash
cd "<III repo root>"

# Generated build outputs
find STDLIB/build -name '*.iii.o.s' -delete
find STDLIB/build/corpus -name '*.exe.s' -delete
find STDLIB/build/corpus -name '*.log'   -delete

# Stage-1 / probe artifacts living next to source
find STAGE1/PROBE -maxdepth 1 \( -name '*.exe' -o -name '*.exe.o' \
  -o -name '*.exe.s' -o -name '*.exe.witness.json' \
  -o -name '*.o' -o -name '*.o.s' \) -delete
find STAGE1/BOOT  -maxdepth 1 \( -name '*.exe' -o -name '*.exe.o' \
  -o -name '*.exe.s' -o -name '*.exe.witness.json' \
  -o -name '*.sealed.o.s' \) -delete

# Stale generator intermediates
rm -f COMPILER/BOOT/_strs.iiifrag \
      COMPILER/BOOT/_strs_rm1.iiifrag \
      COMPILER/BOOT/_rm1_hv.iiifrag \
      COMPILER/BOOT/_cg_rm2_lits.iii.frag

# Scratch
find . -name '*.tmp' -delete
find . -name '*.bak' -delete
find . -name '*.old' -delete

# Bootstrap-compiler clean (uses the script's own --clean)
bash COMPILER/BOOT/build_iiis0.sh --clean

# Stdlib clean (added 2026-05-08)
bash STDLIB/scripts/build_stdlib.sh --clean
```

## §6. Audit reference

This file was created during the 2026-05-08 architectural refactor (item 2
of the 10-item harmonization sequence). See `NOTES/ARCHITECTURE.md` for the
full repo snapshot at that date.
