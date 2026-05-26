# ADR-RES-012 — Sixteen Meta-Patterns Frozen

## Status

FROZEN.

## Context

The user's prose mentioned "12 core Meta-Patterns." Subsequent directive added X→Y conversion (codegen-from-patterns + cross-form transformation). The added requirement implied four more meta-patterns: `mp_transform_x_to_y`, `mp_codegen_lower_node`, `mp_codegen_emit_call`, `mp_pattern_introspect`.

## Decision

The 16 meta-patterns of §2.4 are the entire population:

| # | Symbol | Slot |
|---|--------|------|
| MP-1 | `mp_form_request` | 0 |
| MP-2 | `mp_substance_alloc` | 1 |
| MP-3 | `mp_passage_send` | 2 |
| MP-4 | `mp_passage_recv` | 3 |
| MP-5 | `mp_essence_compute` | 4 |
| MP-6 | `mp_motion_seal` | 5 |
| MP-7 | `mp_compose_call` | 6 |
| MP-8 | `mp_origin_seal` | 7 |
| MP-9 | `mp_type_narrow` | 8 |
| MP-10 | `mp_cap_grant` | 9 |
| MP-11 | `mp_prove_equiv` | 10 |
| MP-12 | `mp_default_or_fail` | 11 |
| MP-13 | `mp_transform_x_to_y` | 12 |
| MP-14 | `mp_codegen_lower_node` | 13 |
| MP-15 | `mp_codegen_emit_call` | 14 |
| MP-16 | `mp_pattern_introspect` | 15 |

There is no MP-17 in this specification. A 17th requires a new specification document with a new ID.

## Consequences

- Every concrete pattern's `specialisation_of` field references one of the 16 (or 0 if itself a meta-pattern).
- The 24 transform patterns specialise MP-13.
- The 7 codegen-call patterns specialise MP-15.
- The 20 codegen-AST-kind patterns specialise MP-14.
- Slot allocation is fully determined by pattern kind.

## Alternatives Refused

### Open Meta-Pattern Set With Admission API

Refused per HC-1.

### Reduce To 12 (Drop MP-13..MP-16)

Refused: the user's binding directive added X→Y conversion; the four additional meta-patterns make the directive expressible.

### Expand To 32 To Cover Hypothetical Future Categories

Refused per HC-1 #14 (no future patterns). Closed sets are closed.

## Audit

- §2.4 of FROZEN SPEC.
- Corpus 44 verifies all 16 meta-patterns registered at boot.

## Lineage

Authored: step R0012 of §I. Closed.
