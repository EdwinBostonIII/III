# CATALYST/ — Superseded by `STDLIB/iii/sanctus/catalyst.iii`

The C reference implementation in `CATALYST/src/` is **not** linked by
the live build chain. The active production implementation lives at:

* `STDLIB/iii/sanctus/catalyst.iii` — Catalyst causal-DAG hypothesis
  synthesis with the 8 promotion gates from R1.B1.
* `STDLIB/iii/sanctus/promote.iii` — Promotion pipeline (R-2 sealed).
* `STDLIB/iii/sanctus/demote.iii` — Inverse demotion.

## C-only surface still pending port (RITCHIE Stage 1.9 honesty amendment)

Supersession is **not yet complete**. The `.iii` `catalyst.iii` uses an
**abstract** 8-gate set (`G_STATIC / G_DYNAMIC / G_KCHAIN / G_WITNESS /
G_RIPPLE / G_DUAL_USE / G_CONSERVATIVE / G_UNIQUE`); the C reference uses the
**operational** 8-gate set (`observatory_sat / mobius_coherence / trinity /
ceiling / hexad_reach / codegen / ring_gating / deploy_flag`). This is a
genuine **semantic drift**, not a 1:1 port. **Reconciliation = RITCHIE Stage
7.28** (align the `.iii` gate set to the operational names + semantics per
R1.B1 §1). See `DOCS/CONVERGENCE-AUDIT.md`.

## What this directory still contains

| File | Role |
|---|---|
| `README.md` | R1.B1 specification narrative — keep. |
| `src/*.c` | C reference implementation — historical; will move to `_archive/` once spec parity confirmed against the `.iii` modules above. |
| `tests/*.c` | Reference test bench — historical. |

## Action policy

* **Do not** add new functionality to `src/` or `tests/`. New work goes
  into `STDLIB/iii/sanctus/catalyst.iii` (or its companions).
* **Do** keep `README.md` updated when the spec evolves; it is the
  authoritative R1.B1 prose.
* **Do** consult `DOCS/III-CATALYST.md` for the sealed specification.

## Cross-reference

* Spec: `DOCS/III-CATALYST.md` (R1.B1)
* Live impl: `STDLIB/iii/sanctus/catalyst.iii`
* Index: `R1-SUBSYSTEMS.md` (repo root) — search for `CATALYST/`
