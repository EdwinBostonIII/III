# III TYPES — type-checker for the III language

The canonical type system of III, implementing every section of
`DOCS/III-TYPES.md` (R1.A3).

## What's in here

| File                                  | Spec coverage                                |
|---------------------------------------|----------------------------------------------|
| `include/iii/types.h`                 | Public API: §2 universe, §3..§9 type rules, §10 bidir, §12 driver, §11.3 proof |
| `include/iii/types_term.h`            | §11.1 CIC kernel API + §11.2 native ternary  |
| `include/iii/types_hexad.h`           | §4 + §11.2 hexad/trit kernel                 |
| `include/iii/types_errors.h`          | TYPE-CHK-NNN unified diagnostic vocabulary   |
| `src/errors.c`                        | error code → name/message                    |
| `src/hexad.c`                         | asymmetric ternary algebra + 144-byte bitmap |
| `src/cic.c`                           | full CIC kernel (terms, β/δ/ζ/ι/η, typeof)   |
| `src/type_repr.c`                     | §2..§9 — every typing rule as a callable API |
| `src/bidir.c`                         | §10 bidir, §12 driver, §11.3 proof certs     |
| `tools/iii_types_tool.c`              | CLI: `--hash`, `--bitmap-hash`, `--self-check` |
| `tests/test_main.c`                   | 51 tests across all sections                 |

## Build

```
cd build
.\build.bat        # Windows / mingw-w64
make               # POSIX
```

Build flags (mandatory): `-std=c11 -Wall -Wextra -Werror -O2`.

The test runner reports `=== 51 passed, 0 failed ===`.

## Spec conformance — section coverage

| §  | Topic                          | Implementation |
|----|--------------------------------|----------------|
| 2  | Universe ladder Prop / Type_0..6 | `iii_universe_*`, `iii_ty_universe`, `iii_sort_*` |
| 3  | Reduction six-tuple             | `iii_ty_reduction[_proj/compose/inverse]` |
| 4  | Hexad-tagged types + Reachability | `iii_ty_hexad_tag/compose`, `iii_hexad_admitted`, 6 brick presets blocked |
| 5  | Ring/phase types + marshalling  | `iii_ty_ring_tag`, `iii_ty_phase_cross`, lattice in `iii_phase_marshal_exists` |
| 6  | Tier and Epoch tags             | `iii_ty_tier_tag/compose`, `iii_ty_epoch_tag/bridge` |
| 7  | Linear capabilities             | `iii_ty_cap`, `iii_type_env_bind_linear`, single-use enforcement |
| 8  | Epistemic / Uncertainty         | `iii_ty_uncertainty`, `iii_uncertainty_combine` |
| 9  | Constitutional / Möbius / Trinity Props | `iii_ty_prop` (12 prop-kinds at Prop) |
| 10 | Bidirectional + holes (N1) + U1 lift | `iii_synth`, `iii_check`, `iii_holes_solve`, `iii_lift_term_to_type` |
| 11 | Proof layer (CIC + native ternary) | `cic.c` (full kernel), `iii_proof_cert_create/verify` |
| 12 | Three-pass driver               | `iii_check_module` (declare → synth → discharge) |

## NIH discipline

Only `libc` + the in-tree `libiii_lex.a` and `libiii_grammar.a`. No
external proof system, no LLVM, no third-party C deps.

## R1.A3 / bitmap hashes (current)

Run `iii_types_tool.exe --hash ..\DOCS\III-TYPES.md` and
`iii_types_tool.exe --bitmap-hash` to print the canonical hashes; both
are deterministic across builds.

## Scope notes

The bidirectional inference layer recognizes the documented subset of
the GRAMMAR AST kinds that carry value-level type information
(`LITERAL`, `PRIMARY`, `PATH`, `CALL`, `FIELD_ACCESS`, `PHASE_CROSS`,
`EPOCH_BRIDGE`, `CAP_ACQUIRE_RELEASE`, `INVERSE`, `INFIX_OP`,
`PREFIX_OP`, `HOLE`, `TUPLE_LITERAL`, `BLOCK_EXPR`).  Unrecognized
kinds are walked recursively for side effects (linear-cap accounting).
Every typing rule from §2..§11 is independently callable for testing.
