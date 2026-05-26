# SANDBOX/ — Superseded by `STDLIB/iii/omnia/sandbox_*.iii`

The C reference implementation in `SANDBOX/src/` is **not** linked by the
live build chain. The active production implementations live at:

* `STDLIB/iii/omnia/sandbox_ctor.iii` — `sandbox_new(cap_set, mem_cap, cpu_cap) -> u64 @linear`.
* `STDLIB/iii/omnia/sandbox_exec.iii` — `sandbox_run(sb, fn_addr, ctx) -> u64` (**quota-bookkeeping only at present** — NOT yet OS-level process isolation; the live `.iii` and the C reference both track quotas/capabilities without invoking `clone3`/`seccomp`/`landlock`/`CreateProcess`/`posix_spawn`. **Real OS process isolation lands in RITCHIE Stage 7.25 / 8.6** — see `DOCS/CONVERGENCE-AUDIT.md`).
* `STDLIB/iii/omnia/sandbox_quota.iii` — Quota enforcement (mem, CPU, fd, net).

Together these implement D16 (`DOCS/III-SANDBOX.md`) — at the quota-bookkeeping
tier today; the process-isolation tier is the named Stage 7.25/8.6 deliverable.

## What this directory still contains

| File | Role |
|---|---|
| `README.md` | D16 specification narrative — keep. |
| `src/*.c` | C reference implementation — historical. |
| `tests/*.c` | Reference test bench — historical. |

## Action policy

* **Do not** add new functionality to `src/` or `tests/`. New work goes
  into the appropriate `STDLIB/iii/omnia/sandbox_*.iii` module.
* **Do** keep `README.md` updated when the spec evolves.

## Cross-reference

* Spec: `DOCS/III-SANDBOX.md` (D16)
* Live impls: `STDLIB/iii/omnia/sandbox_ctor.iii`, `sandbox_exec.iii`, `sandbox_quota.iii`
* Index: `R1-SUBSYSTEMS.md` (repo root) — search for `SANDBOX/`
