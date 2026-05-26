# ADR-RES-006 — Transform Patterns

## Status

FROZEN.

## Context

X→Y conversion shares structure with codegen lowering: both transform an input artefact in form X to an output artefact in form Y. Examples:

- Codegen: FORM_III → FORM_X86_ASM
- Babel encode: FORM_III → FORM_BABEL_JSON
- Disassembly: FORM_X86_BYTES → FORM_X86_ASM
- Pretty-print: FORM_AST_BINARY → FORM_III

Unifying them simplifies the implementation: one `transform()` API, one resolver, one set of provenance/witness mechanics.

## Decision

24 transform patterns occupy registry slots 16..39. Each is a `pattern_t` paired with an entry in the side-table `g_transform_attrs[24]`:

```iii
struct transform_attrs_t {
    source_form          : u32,
    target_form          : u32,
    transform_fn         : u64,
    inverse_form         : u32,
    inverse_fn           : u64,
    equivalence_proof_id : u64
}
```

The 24 entries are listed in §7B.6 of the spec. Round-trip pairs (e.g., `FORM_III ↔ FORM_BABEL_JSON`) reference each other via `inverse_*` fields with a `proof_ripple_equivalence_pattern` cert minted at boot.

`transform()` is itself a `resolve()` call against `g_transform_pattern_set` (a bitmap covering slots 16..39 only).

## Consequences

- New target form = new pattern + new spec doc. Closed set: no FORM_33 in this revision.
- Round-trip determinism testable for reversible pairs.
- Transform output mhash audited via the witness chain.
- Codegen IS a transform (FORM_III → FORM_X86_ASM): unification with the codegen pattern family in slots 40..66 is structural.

## Alternatives Refused

### Per-Format Converter Library

> "Each codec lives in its own module with its own seal."

Refused: each format would need its own seal/audit; cross-format pipelines would compose seals manually. Single mechanism is simpler and uniformly auditable.

### Plug-In System With Runtime-Loaded Codecs

Refused per HC-1 #1 (no admission post-boot).

### Codegen And Transform As Separate Subsystems

Refused: the user's directive ("codegen reading FROM patterns + X→Y rapid conversion") explicitly unifies the two. Splitting them re-introduces the problem.

## Audit

- §7B.2 carries `transform()` source.
- §7B.6 carries the 24-entry table.
- §Z.C.6.full carries `omnia/transform.iii` source.
- §Z.C.7.full carries `omnia/transform_patterns.iii` source.
- Corpus 54 verifies the canonical FORM_III → FORM_X86_ASM transform.
- §V.T0028 verifies round-trip determinism for all reversible pairs.

## Lineage

Authored: step R0006 of §I. Closed.
