# III Grammar — Wave 2 Reference Implementation

A pure-C11, freestanding-friendly recursive-descent parser for the III
language.  Consumes the LEXICON token stream and produces a sealed,
canonicalisable AST.  No third-party dependencies; depends only on
`LEXICON/` (sibling directory).

R1.A2 hash of the grammar specification this parser targets
(`DOCS/III-GRAMMAR.bnf`):

```
aabc2afc0d6d6762d24ec2742ac47dbf3bde5603495124474fdb6e1667c9a272
```

(Computed via `LEXICON/build/iii_lex_tool.exe hash DOCS/III-GRAMMAR.bnf`.)

---

## 1. Overview

This wave delivers the front end for the III compiler tool-chain:

* a recursive-descent parser over the LEXICON token stream,
* an arena-allocated AST with a sealed kind enumeration (§14, C-GRAM-5),
* a canonical AST serialiser that yields a stable, modifier-sorted byte
  stream (§10.6) and the SHA-256-based 32-byte module hash `mhash`,
* a human-readable AST dumper (`iii_ast_dump`),
* a CLI tool `iii_parse_tool` (`hash | dump | errors | tokens | full`),
* a self-contained C unit-test suite (10 files, 97 cases).

The implementation is consciously **NIH-by-design** (C-GRAM-NIH): no
parser generators, no third-party libraries.  Everything inside
`GRAMMAR/` is hand-written C11 compiled with
`-std=c11 -Wall -Wextra -Werror -O2`.

## 2. Architecture

```
                +----------------------+
                |   LEXICON (Wave 1)   |   tokens, intern table
                +----------+-----------+
                           | iii_lex_*
                           v
+--------------------+  +--------------------+
| parse_state.c      |  | parse_arena.c      |
| (P / token cursor) |  | (bump arena)       |
+----+---------------+  +-----+--------------+
     |                        |
     v                        v
+----------------------------------+      +--------------------+
| parse_module.c   parse_decl.c    |----->|  ast.c / ast.h     |
| parse_type.c     parse_stmt.c    |      |  (sealed kinds)    |
| parse_expr.c     parse_pat.c     |      +-----+--------------+
| parse_modifier.c parse_kw_table  |            |
+-----------------+----------------+            v
                                         +-------------------+
                                         | ast_print.c       |
                                         | ast_canonical.c   |
                                         +---------+---------+
                                                   |
                                                   v
                                             iii_parse_tool
                                             iii_grammar_test
```

* `parse_state.c` owns the parser handle (`P`), the token cursor, and
  the diagnostic ring buffer (`P_E_*`).
* `parse_arena.c` is a 64 KiB bump allocator with geometric child-array
  growth (cap 4 → 8 → …).  Nothing is freed until
  `iii_arena_destroy_impl`.
* `parse_*.c` walk the BNF productions one-to-one; entry point is
  `iii_parse_module()`.
* `ast_canonical.c` writes the kind tag, packed integers, interned text,
  and **modifier-sorted** children to a byte buffer; `iii_ast_mhash`
  feeds that buffer through SHA-256 to produce the 32-byte digest.

## 3. Build

The build depends on a built `LEXICON/build/libiii_lex.a`.  Build that
first (`cd ..\LEXICON && build\build.bat` on Windows).  Then any of:

| Platform     | Command                              |
|--------------|--------------------------------------|
| POSIX shell  | `bash build/build.sh`                |
| Windows cmd  | `build\build.bat`                    |
| GNU make     | `make -C build`                      |

All three produce the same artifacts in `build/`:

* `libiii_grammar.a`  — static library (parser + AST + canonical/print)
* `iii_parse_tool[.exe]` — CLI tool
* `iii_grammar_test[.exe]` — unit-test runner

Strict flags (`-std=c11 -Wall -Wextra -Werror -O2`) are enforced.

### Why `-Wl,--allow-multiple-definition`?

The build scripts pass `-Wl,--allow-multiple-definition` to the linker
to work around the duplicate-symbol issue described in §7 ("Known
Issues") below.  This flag is intentional and limited to the final
link step.

## 4. CLI tool

```text
iii_parse_tool <verb> <file.III>

  hash     — print the 32-byte canonical mhash (hex) of the AST
  dump     — print a human-readable AST tree to stdout
  errors   — print P_E_* diagnostics (one per line) to stderr
  tokens   — print the LEXICON token stream
  full     — dump + errors + hash combined
```

Exit code is non-zero when invocation arguments are wrong or the input
file cannot be read; parse-error counts surface through the `errors`
verb and via `iii_parser_error_count()` programmatically.

## 5. File listing (Wave 2 deliverables)

| File | LoC | Owner |
|---|---:|---|
| `include/iii/ast.h`              | 211 | Foundation |
| `include/iii/ast_print.h`        |  28 | Foundation |
| `include/iii/parse_arena.h`      |  40 | Foundation |
| `include/iii/parser.h`           |  55 | Foundation |
| `src/ast.c`                      | 160 | Foundation |
| `src/ast_canonical.c`            | 250 | Agent D    |
| `src/ast_print.c`                | 176 | Agent D    |
| `src/parse_arena.c`              | 112 | Foundation |
| `src/parse_state.c`              | 248 | Foundation |
| `src/parse_internal.h`           | 371 | Foundation |
| `src/parse_kw_table.c`           | 136 | Foundation |
| `src/parse_modifier.c`           | 261 | Agent C    |
| `src/parse_type.c`               | 509 | Agent C    |
| `src/parse_pat.c`                | 303 | Agent C    |
| `src/parse_expr.c`               | 754 | Agent C    |
| `src/parse_stmt.c`               | 584 | Agent C    |
| `src/parse_decl.c`               | 487 | Agent C    |
| `src/parse_module.c`             | 205 | Agent C    |
| `tools/iii_parse_tool.c`         | 197 | Agent D    |
| `tests/test.h`                   | 112 | Agent E    |
| `tests/test_main.c`              |  66 | Agent E    |
| `tests/test_module.c`            |  89 | Agent E    |
| `tests/test_decl.c`              | 154 | Agent E    |
| `tests/test_type.c`              |  77 | Agent E    |
| `tests/test_stmt.c`              | 123 | Agent E    |
| `tests/test_expr.c`              | 129 | Agent E    |
| `tests/test_pat.c`               |  99 | Agent E    |
| `tests/test_modifier.c`          | 118 | Agent E    |
| `tests/test_canonical.c`         |  81 | Agent E    |
| `tests/test_errors.c`            |  76 | Agent E    |
| `tests/test_self.c`              | 106 | Agent E    |
| `build/build.sh`                 |  74 | Agent E    |
| `build/build.bat`                |  55 | Agent E    |
| `build/Makefile`                 |  51 | Agent E    |
| **Total (parser+tests+build)**   | **6,500** | |

## 6. Test results

`build\iii_grammar_test.exe`:

```
=== 97 passed, 0 failed ===
```

**Pin updated RITCHIE Stage 1.24 (2026-05-21):** all 97 cases pass. The 8
cases that were failing at the prior pin (schema field counting, match-arm
counting, field access + ⟲/⟲⟲ prefixes, bare-ident pattern, @safety/@hexad
alias canonicalization, module-name-in-mhash) have since been fixed — they are
now green. (This makes RITCHIE plan steps §1.25–§1.32, which were written to
fix those 8, confirmed-already-done no-ops.)

| Group       | Pass | Fail | Notes                          |
|-------------|-----:|-----:|--------------------------------|
| module      |  8   |  0   | clean                          |
| decl        | 11   |  0   | schema field counting — FIXED  |
| type        | 10   |  0   | clean                          |
| stmt        | 13   |  0   | match-arm counting — FIXED     |
| expr        | 15   |  0   | field access, ⟲ / ⟲⟲ — FIXED  |
| pat         | 11   |  0   | bare ident pattern — FIXED     |
| modifier    | 11   |  0   | @safety/@hexad alias — FIXED   |
| canonical   |  6   |  0   | module name in mhash — FIXED   |
| errors      |  7   |  0   | clean                          |
| self        |  5   |  0   | clean                          |
| **Total**   | **97** | **0** |                              |

## 7. §14 Conformance mapping

| Criterion       | Where exercised                                 |
|-----------------|-------------------------------------------------|
| **C-GRAM-1** *(well-formed III parses without errors)*    | `test_module`, `test_decl`, `test_type`, `test_self`, `test_errors::err_clean_source_zero_errors` |
| **C-GRAM-2** *(precise diagnostics on malformed input)*   | `test_errors` (7 cases over `P_E_*` codes, recovery) |
| **C-GRAM-3** *(operator precedence respected)*            | `test_expr::expr_precedence_arithmetic` and the doubled-operator cases |
| **C-GRAM-4** *(disambiguation: `{...}` block vs record)*  | `test_expr::expr_record_literal`, `test_pat::pat_record` |
| **C-GRAM-5** *(sealed AST kind enum)*                     | All shape assertions are written against the public `III_AST_*` enum in `include/iii/ast.h`; no opaque or private kinds are leaked |
| **C-GRAM-FROZEN** *(R1.A2 hash matches DOCS)*             | Inline at top of this README; verified via `iii_lex_tool hash` |
| **C-GRAM-NIH** *(no third-party deps)*                    | `build/*.{sh,bat}` and `Makefile` link only against `libiii_lex.a` and libc; no autotools/cmake/yacc/lex |
| **C-GRAM-SELF** *(round-trip stability of canonical AST)* | `test_canonical::canonical_idempotent`, `test_self::self_realistic_round_trip_hash`, `test_modifier::mod_canonical_sort_invariance` |

## 8. Known issues

These items were discovered by the unit tests during Wave 2 integration
and are documented here so future waves can address them.  They do **not**
block the deliverables — the parser, AST, canonical serialiser, tool
and test suite all build cleanly with strict flags and the test runner
returns a deterministic pass/fail total.

1. **Duplicate symbol `iiip_parse_qualified_name`.**
   Both `src/parse_module.c` and `src/parse_type.c` (Agent C territory)
   provide an external definition of `iiip_parse_qualified_name`.  The
   build scripts pass `-Wl,--allow-multiple-definition` to the linker
   so the first definition wins.  The two implementations should be
   unified into `parse_internal.h` + a single `.c` (suggested home:
   `parse_module.c`, since qualified names appear at module/import
   level and are referenced from type parsing only as a sub-routine).

2. **`@safety` is not canonicalised as an alias of `@hexad`** (§5.1).
   `ast_canonical.c` should normalise `@safety(...)` → `@hexad(...)` so
   that the two surface spellings produce identical `mhash`.  The
   failing test `mod_safety_alias_of_hexad` documents the requirement.

3. **Module name not folded into canonical mhash.**
   Two modules with different names (`module foo` vs `module bar`),
   identical otherwise, currently hash to the same `mhash`.  See
   failing test `canonical_module_name_changes_hash`.  The fix is in
   `ast_canonical.c`: emit the interned module-name string into the
   canonical buffer before walking children.

4. **Field-access expression `obj.field`** is not yielding either
   `III_AST_FIELD_ACCESS` or `III_AST_PATH` in the expression
   precedence ladder of `parse_expr.c`.

5. **Inverse operators `⟲ x` and `⟲⟲ x`** as prefix unary expressions
   are not surfacing in the AST.  The grammar (§4.4) lists ⟲ and ⟲⟲
   among the prefix expression operators.

6. **`match` arm enumeration.**  Multi-arm `match` statements are
   producing `III_AST_MATCH_ARM` count 0; arms are likely being
   collapsed into a single block child.

7. **Bare-identifier match pattern** `name => …` should yield
   `III_AST_IDENT_PATTERN` (or a length-1 `III_AST_PATH_PATTERN`).

8. **Schema fields**: `schema S = OBSERVATORY { f: T, g: U }` does not
   produce `III_AST_SCHEMA_FIELD` children.

## 9. Foundation arena symbol rename

The lexicon's internal arena (in `LEXICON/src/arena.c`) and the
grammar's parser arena both originally exported
`iii_arena_alloc` / `iii_arena_destroy`.  Because both static
archives end up on the same link line, the symbols clashed.

The grammar's foundation file `src/parse_arena.c` now defines them as
`iiip_arena_alloc_impl` / `iiip_arena_destroy_impl`, and
`include/iii/parse_arena.h` exposes the public spellings as
`static inline` wrappers.  Callers (tests, `iii_parse_tool.c`,
internal AST helpers) compile unchanged because the public API names
are preserved in the header.  Lexicon's identically-named symbols are
left untouched and remain bound to lexicon-internal callers via its
own header.

---

*Wave 2 delivered.  Grammar parses III; AST is sealed; canonical is
stable; tests are reproducible; tool is wired; build is hermetic.*
