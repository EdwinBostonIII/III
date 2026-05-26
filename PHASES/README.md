# III-PHASES — The Cross-Ring Lattice

**Document Identity:** A7 / The Phase System / One Source, Four Worlds
**Canonical Hash Slot:** R1.A7 = `8f3ff2e175a282dd24036224a97e4d67d5f58c298ea734294b9ba0d51edee1c9`
**Spec:** `DOCS/III-PHASES.md`

The PHASES module implements the runtime semantics of III's four-ring
privilege lattice (R-2 / R-1 / R0 / R3), the five cross-ring constructors,
and the four novel inventions specified in the document:

1. **§5 — Dynamic Phase Promotion** (rate-capped at `XII_PHASE_PROMOTE_RATE = 4`).
2. **§6 — Epistemic Phases** (`phase.current()`).
3. **§7 — Ghost Phases** (audit-only execution).
4. **§8 — Predictive Phase Specialisation** (PIP).

The actual cross-ring code emission lives in the SELF compiler; this module
owns the abstract semantics — lattice operations, constructor lookup, witness
emission, marshalling validation, promotion rate-capping, and hot-path
tracking.

## Layout

```
PHASES/
├── README.md                     This file.
├── include/iii/phases.h          Public API. ~340 lines.
├── src/
│   ├── phases_internal.h         Shared private state.
│   ├── mhash.c                   Self-contained SHA-256 + chain-mhash.
│   ├── ring_lattice.c            §1 — lattice ops, constructor table, names.
│   ├── phase_poly.c              §2 — cycle registration + synthesis.
│   ├── marshal.c                 §3 + §4 — five marshalling rules.
│   ├── promotion.c               §5 — dynamic phase promotion.
│   ├── epistemic_phase.c         §6 — phase.current().
│   ├── ghost_phase.c             §7 — ghost-observe.
│   ├── predictive.c              §8 — PIP decision + witness.
│   ├── runtime.c                 Lifecycle and witness ring.
│   └── r1_a7.c                   Closure-identity constant.
├── tests/test_phases.c           120 assertions across all eight sections + SHA-256 vectors.
├── tools/iii_phases_tool.c       CLI: info / constructor / chain / hash / demo.
└── build/build.bat               Windows + MinGW build script.
```

## Build

```sh
cd PHASES
gcc -std=c11 -Wall -Wextra -Werror -O2 -Iinclude -Isrc -c src/*.c
ar rcs build/libiii_phases.a *.o
gcc tests/test_phases.c build/libiii_phases.a -o build/iii_phases_test
gcc tools/iii_phases_tool.c build/libiii_phases.a -o build/iii_phases_tool
```

(or `build\build.bat` on Windows.)

## Test

```
$ ./build/iii_phases_test
…
=== 120 passed, 0 failed ===
```

## Tool

```
$ ./build/iii_phases_tool info
III-PHASES (Doc-ID A7, R1.A7)
  Ring lattice (most → least privileged): R-2 ≼ R-1 ≼ R0 ≼ R3
  Cross-ring constructors: Magic-MSR, IOCTL, Sanctum-Gate, VMRUN, SYSRET
  Promotion rate cap (per chronos-tick): 4
  R1.A7: 8f3ff2e175a282dd24036224a97e4d67d5f58c298ea734294b9ba0d51edee1c9

$ ./build/iii_phases_tool constructor R3 R0
R3 ↔ R0 : ioctl

$ ./build/iii_phases_tool chain R3 R-2
Path R3 -> R-2 (length 2):
  R3  --[magic-msr]--> R-1
  R-1 --[sanctum-gate]--> R-2

$ ./build/iii_phases_tool demo
Cycle 'demo_read_msr' @ring{R-2,R-1,R0,R3}
  synthesised 3 lowerings
    R-1 : explicit (step=irpd-msr-read)
    R-2 : synth (step=sanctum-gate-enter)
    R0  : synth (step=vmrun)
    R3  : synth (step=magic-msr-invoke)
```

## Conformance (per spec §12)

| Criterion | Status |
| --- | --- |
| C-PH-1 — N distinct lowerings per phase set | ✅ `iii_phase_cycle_synthesize()` |
| C-PH-2 — Witness-chain continuity across BCWL | ✅ `iii_phases_chain_mhash()` |
| C-PH-3 — Glyph-bound zero-copy when mhash matches | ✅ `iii_phase_marshal_check()` Rule 1 |
| C-PH-4 — `XII_STEP_KIND_PHASE_PROMOTE` rate-capped | ✅ `iii_phase_runtime_promote()` |
| C-PH-5 — Ghost-phase witnesses without privileged op | ✅ `iii_phase_runtime_ghost_observe()` |
| C-PH-6 — Predictive specialisation at sub-5-cycle hot path | ✅ decision logic; emission is SELF's job |

## Dependencies

This module is self-contained — no link-time dependencies on other III
modules.  It exposes pure abstract semantics that other modules can plug into
when they need to model phase-polymorphic behaviour.
