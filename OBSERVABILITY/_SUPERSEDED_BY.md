# OBSERVABILITY/ — Superseded by `STDLIB/iii/omnia/obs_*.iii`

The C reference implementation in `OBSERVABILITY/src/` is **not** linked
by the live build chain. The active production implementations live at:

* `STDLIB/iii/omnia/obs_log.iii` — Structured-event log; each event
  minted as a crystal_id.
* `STDLIB/iii/omnia/obs_metric.iii` — Counter / gauge / histogram
  primitives; emits to closure-pinned dashboard manifest.
* `STDLIB/iii/omnia/obs_trace.iii` — Distributed trace; W3C
  trace-context interop; ripple-aware spans.
* `STDLIB/iii/omnia/obs_observatory.iii` — OBSERVATORY collapse:
  12-family threshold rollup.

Together these implement D7 (`DOCS/III-OBSERVABILITY.md`).

## What this directory still contains

| File | Role |
|---|---|
| `README.md` | D7 specification narrative — keep. |
| `src/*.c` | C reference implementation — historical. |
| `tests/*.c` | Reference test bench — historical. |

## Action policy

* **Do not** add new functionality to `src/` or `tests/`. New work goes
  into the appropriate `STDLIB/iii/omnia/obs_*.iii` module.
* **Do** keep `README.md` updated when the spec evolves.

## Cross-reference

* Spec: `DOCS/III-OBSERVABILITY.md` (D7)
* Live impls: `STDLIB/iii/omnia/obs_log.iii`, `obs_metric.iii`, `obs_trace.iii`, `obs_observatory.iii`
* Index: `R1-SUBSYSTEMS.md` (repo root) — search for `OBSERVABILITY/`
