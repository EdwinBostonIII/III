# III LEGACY-INGESTION

Implementation of the III Legacy Ingestion module per
`DOCS/III-LEGACY-INGESTION.md`. Pure C11, NIH (no `libelf`, no `libpe`,
no `LIEF`, no `libMachO`, no `libbfd`), built clean with
`-Wall -Wextra -Werror -O2`.

The module ingests **legacy** ELF / PE / Mach-O / COFF binaries, parses
them with bounded readers (no UB on misaligned or truncated input),
normalizes them to a canonical IR, classifies a *compromise level* per
spec §5, translates host syscalls between Linux / Windows NT / macOS,
and runs the resulting code in a small step interpreter that rejects
privileged operations and emits a witness ring.

## Build

```
cd LEGACY-INGESTION\build
build.bat
```

Produces:
- `build\libiii_legacy.a`           — static library
- `build\iii_legacy_tool.exe`       — CLI (`iii_legacy_tool detect|parse <file>`)
- `build\iii_legacy_test.exe`       — test runner (≥30 tests)

The library depends only on `LEXICON\build\libiii_lex.a` for `iii_sha256`.

## Format coverage

| Format        | Header      | Sections / cmds       | Symbols   | Status |
|---------------|-------------|-----------------------|-----------|--------|
| ELF64 LE      | `Ehdr`      | program + section hdrs| `.symtab` | full   |
| PE32 / PE32+  | DOS+NT+opt  | section table         | export tbl| full   |
| Mach-O 64     | `mach_64`   | LCs, `LC_SEGMENT_64`  | `LC_SYMTAB`| full  |
| Mach-O Fat    | big-endian  | per-arch slices       | n/a       | full   |
| COFF object   | file hdr    | section table         | `.symtab` | full   |

All parsers are *bounded*: every field read goes through
`iii_le_read_uXX` / `iii_be_read_u32` from `src/internal.h`, which
always zero-initialize their output and return 0 on truncation.

## Canonical IR

Each ingested module is normalized into a `iii_legacy_canonical_t`:

```
format / arch / abi / os
entry_point
section_count, sections[]   { name, vaddr, vsize, foffset, fsize, flags }
sha256
```

`flags` are a portable bitfield:
`III_CANON_F_READ / WRITE / EXEC / BSS / TLS`.

## Compromise classification (§5)

| Format        | Default              |
|---------------|----------------------|
| ELF (RELRO)   | `low`                |
| ELF (no relro)| `medium`             |
| ELF (exec stk)| `high`               |
| PE (signed)   | `low`                |
| PE (unsigned) | `medium`             |
| Mach-O (signed)| `low`               |
| Mach-O (unsigned)| `medium`          |
| COFF object   | `medium` (always, per §5.3) |

## Sandbox interpreter

- 8 general registers, 64 KiB flat memory.
- Op set: `LOAD_IMM`, `LOAD_MEM`, `STORE_MEM`, `ADD`, `SUB`,
  `SYSCALL`, `HALT`, `PRIV`.
- `PRIV` always faults and writes a `compromise.high` witness.
- Out-of-bounds memory access faults with `OOB`.
- 256-entry witness ring buffer.

## Syscall translation (§9)

Closure-pinned tables:

| OS      | Entries |
|---------|---------|
| Linux x86-64 | 25 |
| Windows NT  x64 | 10 |
| macOS BSD/Mach | 18 |

Translation maps a host syscall number → canonical action with a
compromise rating. Unsupported numbers return `III_LS_UNSUPPORTED` and
the sandbox returns `-ENOSYS`.

## Layout

```
include/iii/         elf.h pe.h macho.h coff.h legacy.h
src/                 internal.h detect.c elf.c pe.c macho.c coff.c
                     normalize.c syscall.c sandbox.c
tests/               fixtures.{h,c} test.h test_main.c
tools/               iii_legacy_tool.c
build/               build.bat
```

## Test results

```
=== 56 passed, 0 failed ===
```
