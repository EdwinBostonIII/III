# III Lexicon — Reference Implementation

A complete, NIH-extreme implementation of the III lexer specification, as
defined in `../DOCS/III-LEXICON.md`.

## Provenance

This implementation conforms to **III-LEXICON.md** with R1.A1 hash:

```
R1.A1 = 0x2c140927e2972a4478c397f0f6c931c241065d4a0e54db74502f79bf9324c297
```

The `iii_lex_tool` will print this hash for any input file.  The same value is
emitted by `tests/test_self.c` when the suite is run.

## What's here

- **`include/iii/`** — public headers (token, errors, lex, canonical, sha256,
  utf8, fnv1a, intern, arena, nfc).
- **`src/`** — implementation.  Only libc is used:
  - `utf8.c`          RFC 3629 hand-rolled validator/decoder/encoder.
  - `sha256.c`        FIPS 180-4 SHA-256.
  - `fnv1a.c`         32-bit FNV-1a.
  - `arena.c`         64 KiB linked-chunk bump arena.
  - `intern.c`        open-addressed hash map (FNV-1a, 0.75 load).
  - `nfc.c`           minimal NFC checker (rejects decomposed `möbius`).
  - `canonical.c`     §2.5 canonicalization + R1 hash (validates UTF-8,
                      rejects BOM/CR/trailing-ws/forbidden-control, max 16 MiB).
  - `keywords.c`      47-keyword table with `möbius` UTF-8 special-case.
  - `modifiers.c`     19 modifiers + `@safety` synonym mapped to `@hexad` id.
  - `operators.c`     23 operators with maximal-munch double-form handling.
  - `punctuators.c`   ASCII punct + `≤` (U+2264), `≥` (U+2265).
  - `token.c`         token-kind, suffix and error-code name strings.
  - `lex.c`           the main state machine (~1500 LOC).
- **`tools/iii_lex_tool.c`** — CLI: prints token stream + R1 hash + error list.
- **`tests/`** — 77 tests across 11 areas; runner emits `PASS`/`FAIL` and
  exits non-zero on any failure.
- **`build/build.sh`**, **`build/build.bat`**, **`build/Makefile`** — three
  redundant build paths.

## Building

```
# Unix / mingw bash
bash build/build.sh

# Windows / MSVC
build\build.bat

# Cross-platform make
make -C build/.. -f build/Makefile
```

Outputs: `build/libiii_lex.a` (or `iii_lex.lib`), `build/iii_lex_tool[.exe]`,
`build/iii_lex_test[.exe]`.

## Using the CLI

```
iii_lex_tool <file.III> [--quiet]
```

`--quiet` suppresses the per-token dump and prints only the summary + R1 hash.

## Conformance criteria (mapping to spec §14)

| Criterion | Coverage                                                   |
|-----------|------------------------------------------------------------|
| C-LEX-1   | `iii_canonicalize` + R1.A1 hash printed by tool & self-test |
| C-LEX-2   | Every keyword, modifier, operator, punctuator tested        |
| C-LEX-3   | INT/MHASH/Q14/TRIT/HEXAD literal forms tested               |
| C-LEX-4   | All four string flavors tested with edge cases              |
| C-LEX-5   | Block / line / doc comments incl. nested tested             |
| C-LEX-6   | All listed error codes triggered or referenced in tests     |
| C-LEX-7   | Self-test re-canonicalizes & rehashes the spec              |

## Notes / pragmatic choices

- Column counting is in codepoints, not bytes.
- `möbius` is detected by byte-exact match `m\xC3\xB6bius`; the lexer
  otherwise allows only ASCII in identifiers.
- `NEG`, `ZERO`, `POS` (uppercase only) are recognized post-identifier-scan
  as `IIIK_TRIT_LIT` rather than as keywords (they're not in §4.1).
- Hexad lookahead saves the cursor + error count and rewinds on failure.
- For `@safety` the modifier id is set to `@hexad`'s canonical id (2);
  the surface form is preserved in `text_offset`/`text_len`.
- Spec §10.3 says `///` introduces a doc-comment; this implementation also
  recognizes `/** ... */` per the same section.
- `+` and `-` are emitted as `IIIK_PUNCT` — they're not in §7.1 but are
  required for arithmetic per §6.1's prose.  This is the only place where
  this implementation extends the punctuator table beyond the spec table.
