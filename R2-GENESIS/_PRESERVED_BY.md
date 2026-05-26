# R2-GENESIS — PRESERVED ARTIFACT

**Classification:** REFERENCE-ARTIFACT (NOT a deletion candidate).
**Reclassified:** RITCHIE Convergence Stage 1.4 (2026-05-20). Prior `R1-SUBSYSTEMS.md`
classification ("EMPTY-PLACEHOLDER … Throw out") was incorrect — this directory
holds a real, load-bearing hardware artifact.

## What this is

`silicon/resolver_unit.v` — a **484-LOC Verilog RTL** implementation of the III
resolver unit (the hardware realization of `STDLIB/iii/omnia/resolver.iii`'s
11-step FROZEN-SPEC resolution primitive). It is the silicon-target reference
for the I-INSTR instruction-set architecture.

## Why it is preserved (not deleted)

- **ADR-XII-002** mandates preservation of the resolver-unit RTL as the
  hardware-conformance reference.
- **`DOCS/HARDWARE/I-INSTR-V1.0-spec.md`** is the ISA spec this RTL implements;
  §10 of that spec defines a 12-test equivalence corpus the RTL must satisfy.

## Completion status

The RTL is preserved but **not yet complete** (per the forensic audit, W2A10):
- Score reduction currently picks slot 0 rather than the spec-mandated
  tournament-max-of-8.
- Memo hash is XOR rather than SHA-256-truncated-to-128.
- The memo insert path is absent.

**Completion is RITCHIE Convergence Stage 9.2**, which implements the real
tournament reduction + SHA-256-keyed memo + insert path, adds a Verilog
testbench (`tb_resolver_unit.sv`), and validates the RTL against a hand-rolled
cycle-accurate simulator (`numera/iii_simulator.iii`) over the I-INSTR §10
12-test equivalence corpus.

## Pointers

| To learn… | Read |
|---|---|
| …why this is preserved | `DOCS/ADR/ADR-XII-002.md` |
| …the ISA it implements | `DOCS/HARDWARE/I-INSTR-V1.0-spec.md` |
| …the software resolver it mirrors | `STDLIB/iii/omnia/resolver.iii` |
| …the completion plan | `DOCS/CONVERGENCE-AUDIT.md` Stage 9.2 |
