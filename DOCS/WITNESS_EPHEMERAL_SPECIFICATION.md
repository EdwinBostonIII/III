# Witness Ephemeral Specification

Authority for the ephemeral-witness discipline. Grounded in the real witness
chain at `STDLIB/iii/sanctus/witness.iii`. This is a **forward-looking spec**
(forward-reference #26): the ephemeral module does not yet exist; this document
is the contract its eventual implementation satisfies.

## Status

Spec only; implementation pending. The real witness chain (`sanctus/witness.iii`,
`witness_append_*`) grows monotonically. The ephemeral discipline lets the
substrate elide fragments whose consumer pattern guarantees immediate single
consumption, reducing storage without weakening verification — because an elided
fragment is deterministically recomputable from its antecedent set under the W26
closure property.

## Data structures

- **Ephemeral table** of capacity `WE_MAX_EPHEMERAL` (recommend 4096; tunable).
- **Per-fragment ephemeral bit** in the fragment's metadata word in the chain.
- **Recomputation-cost field** per ephemeral fragment, enabling cost-based keep-vs-recompute decisions.

## Public functions (W-rule constraints stated for the implementation)

- `we_init() -> i32` — clears the table. W2: 0 params; W9: −1 if already inited; W14: no loops; W15: no recursion; W16: sets the inited gate.
- `we_mark_ephemeral(frag_id: *u8) -> i32` — marks the 32-byte-id fragment ephemeral. W2: 1 param; W9: −1 not inited / −2 unknown fragment / −3 already ephemeral / −4 table full; W13: ≤6 locals; W14: sentinel loops; W15: no recursion.
- `we_recompute_verify(frag_id: *u8, out_frag_mhash: *u8) -> i32` — recomputes an elided fragment from its antecedent set, writes the resulting master hash. W2: 2 params; W9: distinct codes; W13: ≤12 locals; W14: sentinel; W15: no recursion (iterative antecedent-set walk).
- `we_collect_recomputable(out_count: *u32) -> i32` — counts ephemeral fragments whose recomputation cost is below the ceiling. W2: 1 param; W9: distinct codes; W13: ≤8 locals; W14: sentinel; W15: no recursion.

## W26 closure invariant

Every ephemeral fragment's antecedent set must be **complete in the canonical
chain** (a subset of the canonical chain, never of "canonical plus other ephemeral
fragments"). This prevents cascading-elision failure where an ephemeral fragment
depends on another that was recomputed differently.

## Verification gate (forward-reference #26)

A corpus test: mark a fragment ephemeral, elide it, recompute from its antecedent
set, and assert (a) the recomputed fragment's master hash byte-equals the original,
and (b) the witness-chain master hash is byte-equal across the elide and non-elide
paths.

## Order rationale

Committed at Stage 8 because the V3 Phase 12 memoization lattice
(forward-reference #15) consumes ephemeral fragments as dedup candidates; without
the ephemeral discipline, dedup would apply indiscriminately, violating W22 (single
canonical source) since a dedup'd fragment is a non-canonical reference to a
canonical source.
