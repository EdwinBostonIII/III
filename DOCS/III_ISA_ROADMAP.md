# III ISA Roadmap

Roadmap for the III instruction-set architecture. Grounded in the **existing**
ISA artifacts: the frozen spec at `DOCS/HARDWARE/I-INSTR-V1.0-spec.md`, the
Verilog resolver-unit RTL at `R2-GENESIS/silicon/resolver_unit.v` (preserved per
ADR-XII-002, REFERENCE-ARTIFACT per `R1-SUBSYSTEMS.md`), and the assembly
resolver units `COMPILER/BOOT/resolver_unit.s` / `resolver_unit_avx512.s`.

## Status

Roadmap only. The V1 substrate executes against the bootstrap C kernel at
`COMPILER/BOOT/`; the canonical opcode set is a V2 Phase Three commitment
(forward-reference #29). The I-INSTR-V1.0 spec + the resolver RTL are the design
substrate this roadmap consolidates; the RTL completion (tournament max-of-8,
SHA-256-keyed memo) is RITCHIE Stage 9.2 work.

## V1 → V2 → V3 progression

- **V1:** the substrate executes `.iii` modules via the `COMPILER/BOOT/` C kernel
  (lex/parse/sema/cg → native x86-64). The resolver unit exists as RTL
  (`resolver_unit.v`) + as the codegen-emitted `resolver_unit.s` paths.
- **V2 Phase Three:** the first canonical opcode set lands; the substrate's runtime
  executes it natively, with the C kernel retained as the bootstrap path.
- **V3:** the full opcode taxonomy completes; the C kernel is retired except as the
  bootstrap audit reference.

## Opcode taxonomy (design level; bit assignments are V2 P3 authority)

| Class | Operations | Operand source |
|-------|-----------|----------------|
| arithmetic | add/sub/mul/div on u8/u16/u32/u64/i8/i16/i32/i64 | register file |
| memory | load, store, allocate, deallocate | arena surface (`STDLIB/iii/numera/`, `memoria/`) |
| control flow | branch, branch-conditional, call, return | immediate / register |
| capability | forge, revoke, transit | the 7 `CAP_KIND_*` (forward-reference #19) |
| witness | publish, verify, admit | the witness fragment header (`sanctus/witness.iii`) |
| Ring transit | source→dest Ring boundary crossing | Ring field operands |
| reflection | reflect on a term (metaprogramming) | reflected term |

## Encoding discipline

Each opcode is a **32-bit word**: 6-bit primary opcode (64 distinct), 4-bit Ring
field (16 Rings — the substrate's R-3..R3 occupy 7 slots, 9 reserved for V3),
22-bit operand space (register refs, immediates, and 32-byte canonical identifiers
via a lookup table when needed). This matches the I-INSTR-V1.0 spec's layout.

## Verification gate (forward-reference #29, V2 Phase 3)

The V2 Phase 3 corpus executes a canonical instruction sequence and asserts byte-
equal output across the C-kernel reference path and the new ISA execution path —
plus the resolver-unit equivalence corpus (the 12-test set from I-INSTR §10) agrees
between `resolver_unit.v` (RTL), `resolver_unit.s` (codegen), and a hand-rolled
cycle-accurate simulator.

## Order rationale

Committed at Stage 9 because every V2 phase references the settled Ring-field width,
primary-opcode-field width, and operand space; the V2 P3 opcode set is the first
artifact depending on these commitments.
