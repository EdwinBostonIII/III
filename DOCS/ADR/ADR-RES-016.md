# ADR-RES-016 — Compiler Trap Discipline In Resolver Source

## Status

FROZEN.

## Context

CLAUDE.md documents three iiis-0 compiler traps:

1. **Signed-i64 ordering compare → SIGSEGV.** Confirmed at `aether/http_client.iii:564, 603`. Workaround: use `==`/`!=` against a sentinel; never `<`/`<=`/`>=`/`>`.
2. **u32-in-u64-slot garbage bug.** Confirmed at `aether/http_client.iii:535-537`. Workaround: explicit mask `(idx as u64) & 0xFFFFFFFFu64` before pointer arithmetic.
3. **u32 pointer store width bug.** Confirmed at `aether/http_client.iii:541-558`. Workaround: byte-by-byte stores via `*u8` pointer.

Resolver source must avoid all three. Failure to do so risks SIGSEGV in production code paths that are critical for system integrity.

## Decision

The resolver source corpus (`omnia/resolver.iii`, `omnia/unify.iii`, `omnia/pattern_table.iii`, `omnia/codegen_patterns.iii`, `omnia/transform.iii`, `omnia/transform_patterns.iii`, `omnia/babel.iii`, `omnia/babel_intent.iii`, `omnia/proof_ripple_resolution.iii`, `omnia/resolver_replay.iii`, `omnia/call_context.iii`, `verba/intent.iii`, `verba/pattern.iii`, `verba/intent_form.iii`, `sanctus/quality_q7.iii`, `sanctus/mandate_m22.iii`, `sanctus/seal_resolver.iii`) MUST satisfy:

### Signed-i64 Discipline

- No `<`, `<=`, `>`, `>=` operators on `i64` values.
- Use `==`/`!=` against a sentinel (e.g., `-1i64`).
- u8/u16/u32 ordering compares are PERMITTED (only i64 is affected).
- u64 ordering compares are PERMITTED (the bug is signed-only).

### u32-In-u64 Discipline

- Any `(x as u64)` where `x : u32` and the result is used in pointer arithmetic MUST be masked: `(x as u64) & 0xFFFFFFFFu64`.
- Common pattern: `let p : u64 = base + ((idx as u64) & 0xFFFFFFFFu64) * stride`.

### u32 Pointer Store Discipline

- No `*((p) as *u32) = value`.
- Use byte-by-byte stores via `*((p + 0u64) as *u8) = (v & 0xFFu32) as u8`, etc.
- Helpers `write_u32_le` and `read_u32_le` in `omnia/unify.iii` encapsulate the discipline.

## Enforcement

Q7 lint (build-time) verifies absence of forbidden patterns:

- `grep -E '(\<|\<=|\>=|\>) *[a-zA-Z_][a-zA-Z0-9_]* *(\<|\<=|\>=|\>) *[a-zA-Z_][a-zA-Z0-9_]* *: *i64'` should return zero hits in resolver source.
- `grep -E '\(.* as u64\) *\*' resolver-source` flagged unless preceded by ` & 0xFFFFFFFFu64`.
- `grep -E '\*\(.* as \*u32\) *=' resolver-source` should return zero hits.

Build fails if any pattern matches.

## Consequences

- Resolver source is robust to current iiis-0 codegen quirks.
- When iiis-0 fixes the underlying bugs in a future toolchain release, the lint remains as defence-in-depth.
- Authoring resolver code requires conscious attention to these three patterns; build-time enforcement catches lapses.

## Alternatives Refused

### Wait For iiis-0 Fix; Use Unfixed Patterns

Refused per HC-13 (read before write). The traps are documented; ignoring them risks production SIGSEGV.

### Local Workarounds Without Lint

Refused: workarounds drift; lint guarantees compliance.

### Move Resolver Source To A Different Toolchain

Refused per HC-3 (NIH discipline) — only iiis-0 + libc + III BOOT.

## Audit

- CLAUDE.md `KNOWN iiis-0 (.iii) COMPILER TRAPS` section.
- §0.7 of FROZEN SPEC enumerates forbidden behaviours.
- §1.3.8 cites the trap line numbers in `aether/http_client.iii`.
- Q7 lint (§Z.D.1) enforces.

## Lineage

Authored: step R0016 of §I. Closed.
