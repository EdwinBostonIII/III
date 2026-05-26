# Dependent Specialisation Specification & Status

Authority for the substrate's `@specialize_on_use` annotation and the codegen
specialisation it drives. Requested as a forward-looking specification; a survey
of the real substrate establishes that **specialisation is already implemented
and in production use**. This document records the real annotation, its semantics,
its current call sites, and the two genuine residuals (equivalence-theorem
admission and the V2 constitutional cache-invalidation clause).

## Status: IMPLEMENTED and IN USE

`@specialize_on_use` is recognized by the real compiler (`COMPILER/BOOT/`) and is
applied across **10+ STDLIB modules**:

`STDLIB/iii/aether/handle.iii`, `STDLIB/iii/memoria/region.iii`,
`STDLIB/iii/memoria/span.iii`, `STDLIB/iii/numera/bigint_div.iii`,
`STDLIB/iii/numera/q128.iii`, `STDLIB/iii/numera/scalar.iii`,
`STDLIB/iii/numera/sha256.iii`, `STDLIB/iii/omnia/iter.iii`,
`STDLIB/iii/omnia/map.iii`, `STDLIB/iii/omnia/option.iii`.

The idealized plan's `numera/specialize_table.iii` + `compiler::specialization_pass`
(a separate table-driven design) do **not** exist and are **not** needed — the
real specialisation is wired directly into the compiler and the annotated modules
compile and pass corpus today.

## Semantics (real)

A function declared `@specialize_on_use` directs the compiler to produce a
specialised body per distinct call-site argument profile rather than a single
generic body, then rewire each call site to its matching specialisation. It is
the substrate's analogue of C++ template instantiation / Rust monomorphisation,
gated by the compiler's discretion (argument profile + the function's effect
classification). Where no specialisation is profitable, the generic body is used;
the specialised body must produce byte-identical output to the generic body on
every input matching the profile (this is the correctness contract, validated by
each annotated module's own corpus tests).

## Argument-profile alphabet (canonical encoding, for any future table)

If/when a specialisation **table** is materialised (only when a consumer needs to
introspect specialisations — adding it now would be reseal churn with no caller),
the canonical per-call-site profile encoding is:
- `0x01 <len>` — u8 buffer with explicit length (W11 length discipline);
- `0x02` — u32 scalar; `0x04` — u64 scalar;
- `0x10 <struct_kind_id>` — struct pointer (the `struct_kind_id` reuses the XII
  kind-byte numbering convention from `DOCS/XII_CONFLUENCE_SPECIFICATION.md`);
- `0xFF` — terminator.

A table entry would then be: 32-byte function id (Keccak-256 of the canonical
module-qualified name) ‖ ≤64-byte profile vector ending `0xFF` ‖ 32-byte body
master hash ‖ 32-byte equivalence-theorem id.

## Equivalence theorem (for the math-library queue)

Each specialisation's equivalence is a theorem:
`id = Keccak-256(function_id ‖ profile_bytes ‖ "specialisation_equivalence")`,
statement = `(function_id, profile, body_master_hash)`, discharging tactic
`TAC_AUTO` (decidable by the corpus byte-equality test). These are candidate
math-library-queue entries pending the admission tactic (**forward-reference #10**).

## Verification gate

The gate is the existing per-module corpus: each `@specialize_on_use` module's
tests assert the specialised and generic paths produce byte-identical output. The
substrate's corpus run (`STDLIB/scripts/run_corpus.sh`) is green across the 10+
annotated modules today.

## Residuals (the only open items)

1. **Equivalence theorems → math-library queue** — blocked on the queue admission
   tactic (forward-reference #10); until then the equivalence proof lives in the
   per-module corpus, not the queue.
2. **Constitutional cache-invalidation** — V2 Phase Two should ratify a
   `cp_specialization_cache` clause making a specialisation entry invalidate when
   the constitutional clause governing the source function is amended
   (forward-reference #24). Pre-V2 there is no constitutional surface to bind, so
   this is correctly deferred.

No specialisation *implementation* work remains in V1; the annotation is live.
