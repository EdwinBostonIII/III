# III — THE IRREDUCIBLE TRUST BASE (TCB), named and measured

**What this is.** The honest floor: everything III's correctness ultimately rests on that III itself does **not**
verify — the silicon and the OS surface below its own trust anchor — stated exactly, measured, and minimised.
Completion residual **R7** of `III-COMPLETION-PLAN.md`; the R0 ring of `III-UNIFIED-ARCHITECTURE.md`. Written
against the live tree, 2026-07-07. Claim tags: `[meas]` measured this pass · `[gated]` a passing gate ·
`[cited]` read in source.

**The principle.** A trust base you cannot name, you cannot minimise. Every layer *above* R0 is trusted
*by audit* — a human can read `svir_verify.iii` (82 lines, imports nothing `[meas]`), re-run the seal chain,
and re-derive the bootstrap. The layers *at* R0 are trusted *by assertion* — there is no smaller thing inside
III to check them against. The goal is not to eliminate R0 (impossible — something must execute), but to make
it **small, named, and stable**, and to prove nothing above it is trusted-by-assertion.

---

## 1. The irreducible floor (R0) — trusted by assertion

| # | Component | Why it is irreducible | Measured surface |
|---|---|---|---|
| R0.1 | **CPU + microcode** (x86-64) | III's native code executes here; nothing in III can verify the silicon that runs the verifier. | The ISA III emits (`sovas` measured set: integer + the VEX/EVEX crypto tail); microcode is opaque. |
| R0.2 | **OS program loader** (Windows PE loader) | Maps the PE image and transfers control before any III code runs. | PE32+ console subsystem; III emits the image, the OS maps it. |
| R0.3 | **`kernel32.dll`** | The one OS DLL a fully-sovereign III binary imports — raw process/memory/IO syscalls. | **1 DLL** in the sovereign x86 binary's import table `[gated: sovereign exit-99, objdump = kernel32 only]`. |
| R0.4 | **`msvcrt` libc shim** | `malloc`/`free`/`putchar`/`_setmode` and the raw syscall shims. Every trust-floor member imports **only** this (besides each other). | The sole non-III import of all 13 floor members `[meas: floor_closure_gate.sh]`. |

**That is the whole floor.** Four items, all standard platform surface. There is no third-party library, no
runtime, no framework, no interpreter beneath III — the NIH discipline holds: only libc + the OS + the CPU.

---

## 2. Why nothing above R0 is trusted-by-assertion

Each layer above the floor is checkable, and the check is named:

- **R1 — the SVIR anchor.** `svir_verify.iii`, 82 lines, **imports nothing** `[meas]`. A human audits it in one
  sitting; every execution claim funnels through it. Enforced closed by `floor_closure_gate.sh` (green, teeth).
- **R2 — the sovereign toolchain** (`ccsv/iiisv/iiisv2/sovas/sovparse/sovcoff/sovld`). Floor-closed: imports
  only `msvcrt` + each other `[meas]`. It is what removes gcc/ld from the *trusted* build path — the sovereign
  x86 binary imports only `kernel32` `[gated]`.
- **R3–R4 — the self-hosted compiler + `libiii_native.a`.** The seed `iiis-0` is the one place foreign
  compilation is still used, and it is **byte-identity gated** on `stage1_corpus` (`iiis-2 == iiis-3`,
  seed↔self-host identity 60/60 `[gated]`). Φ1 removes even the seed's gcc dependence.
- **The seal chain.** Provenance is self-authored (`sovhash`, sovereign-primary, GNU tool only as a
  veto-witness — the basal law `[cited: commit e98e7ad7]`). A system that authors its own seals trusts no
  external hasher at the floor.

So the trusted-by-assertion set is exactly R0. Everything else is trusted-by-audit, and each audit has a gate.

---

## 3. Minimisation — what has been pushed out of the floor, and what remains

**Pushed out (already):** the *assembler* and *linker* (`gcc as`/`ld`) are out of the sovereign path —
`sovas`+`sovcoff`+`sovld` are III `[gated]`. The *hasher* is out — `sovhash` is III `[cited]`. Multi-DLL
surface is measured and minimal (a sovereign GUI/net binary adds only the specific DLLs it uses:
kernel32/user32/gdi32/ws2_32, table-driven `[gated]`).

**Still in (the honest residuals):**
- **R0.1 CPU/microcode** — irreducible by nature; cannot be removed, only trusted.
- **R0.2 OS loader** — irreducible on a hosted OS; a bare-metal/Ring−1 path (designed, deliberately uncrossed)
  would shrink it, but that is an authorization boundary, not a capability gap.
- **R0.3/R0.4 kernel32 + msvcrt** — the minimal OS/libc surface; measured at 1 DLL for the pure-compute
  sovereign binary. Reducible only by replacing libc shims with direct syscalls (a future minimisation, not a
  correctness gap).

**One known regression that touches this floor's story** (do not overstate the current sovereignty): the
sovereign COFF emitter (default since the C4 flip) does **not yet export module-`var` globals**, which breaks
the hand-asm `resolver_hot.o` link and reddens the full `run_corpus`. So "the tree rebuilds fully green from
clean via the sovereign path" is **not yet true end-to-end** — it is true for `stage1_corpus` (what bootstrap
checks) but not the full stdlib-linked corpus. Root cause, repro, and the bounded fix are in
`III-SOVEREIGN-EMIT-SYMBOL-REGRESSION.md`; the detection gate is `STDLIB/scripts/emit_symbol_consistency_gate.sh`.
Until that lands (+ its deliberate golden re-seal), the honest TCB claim is: *the sovereign path is 1-DLL and
floor-closed for programs that do not depend on cross-module data exports; the data-export path is the last
sovereign-emit feature gap.*

---

## 4. The TCB gate (how this document stays true)

This is a claim about the live tree, so it carries a re-runnable check, not just prose:

```bash
# floor closure (R1/R2 import nothing but msvcrt + each other):
bash STDLIB/sovir/floor_closure_gate.sh                    # -> PASS

# the sovereign binary's import surface is exactly kernel32 (R0.3), no gcc/ld in the path:
#   (build a pure-compute sovereign program, objdump its imports -> kernel32 only)   [run_ccsv.sh / sovtc gates]

# emitter self-consistency (guards the R2 sovereignty claim's one open gap):
bash STDLIB/scripts/emit_symbol_consistency_gate.sh        # -> currently FAIL (the R3 residual above), PASS once fixed
```

**The completion form of R7:** when `emit_symbol_consistency_gate.sh` is green, a full `run_corpus` links and
runs via the sovereign path, and every standalone program self-builds sovereignly (`run_evergreen.sh`), then
this document's §3 residual closes and the TCB is exactly R0 — silicon, loader, kernel32, msvcrt — nothing
above it trusted by assertion.
