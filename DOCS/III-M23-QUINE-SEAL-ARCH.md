# M23 — The Below-OS Behavioral Quine-Seal (Capability 11) · Architecture

**Goal.** Make the KATABASIS metal gate driver *attest its own identity below the OS*: before going
resident, the driver recomputes its sealed identity and refuses to load if it does not match — "a
below-OS image whose quine-seal doesn't verify → red" (III-APOTHEOSIS §M23, capability 11). Today the
driver decides *cycles* (proven on metal 2026-05-23) but never attests *itself*.

## Requirements

- **FR-1.** At `driver_entry`, recompute a master identity over the gate's sealed module closure and
  compare (bit-identical equality, no tolerance) to a baked Ring-−2 seed. On mismatch → fail-closed.
- **FR-2.** Fail-closed = return `STATUS_UNSUCCESSFUL` (0xC0000001) **before** `IoCreateDevice`/symlink,
  so a tampered/incoherent image **does not become resident** (no device, no R3 surface).
- **FR-3.** Additive + orthogonal: the on-metal-proven `gate_ioctl` cycle-decision path is untouched.
- **FR-4.** The seal engine runs **below the OS** using only the gate's own sealed crypto
  (`cad`→`sha256`/`keccak`, already in the closure) — proving the engine computes correctly at Ring 0.
- **FR-5.** The seal LOGIC is gated by a runnable corpus KAT (the metal load is operator/UAC-gated, so
  the logic is proven in user mode by the *same compiled module*; the operator step is the physical run).

**Acceptance.** Given the coherent build, `ks_verify()==1` and `driver_entry` proceeds to residency.
Given any tampered source-hash/seed byte, `ks_verify()==0` and `driver_entry` returns
`STATUS_UNSUCCESSFUL` (statically visible in the `.sys` disassembly).

## Constraints (cg_r0 Ring-0 codegen)

- 8-byte-uniform arrays (`(p as *u64)[off/8]`); per-function ceiling; no >4-arg calls without
  `kernel_abi.s` shims; **no large BSS** (rules out `witness_hook.iii`).
- The closure (`build_gate_ioctl.sh`): `hexad_*`, `xii_term`, `trit`, **`sha256`, `keccak256`,
  `keccak`, `cad`**, `capability`, `katabasis/{svm_layout,bar_layout,cycle_family,cycle_admit,
  cycle_term,seal,caps,gate_verdict,gate,admit}` + `gate_driver` + `cpufeat_kernel` +
  `witness_kernel.s` + `kernel_abi.s`. ⇒ **`cad`/`sha256`/`keccak256` are already in-kernel.**

## The central design decision (ADR-M23-1): measure the load-invariant `.text`, anchor externally

The seal must **bind to the executing code** (so a tampered self goes red) *and* be **deterministic
across loads**. Three candidates:

| Fork | Mechanism | Verdict |
|---|---|---|
| **A — source-identity fold of baked constants** | `cad`-fold of a baked `(module_id ‖ source_hash)` table vs a baked seed (a below-OS port of `quine_verifier`/617). | **REJECTED — doesn't bind to executing code** |
| **B — whole loaded-image hash** | Hash the loaded `.text`+`.data`+`.idata` vs a post-link seed. | **REJECTED — load-nondeterministic** |
| **C — `.text`-only measurement, external anchor** | `cad` over the loaded, relocation-free `.text` section; report it for comparison against an **independently-built** seed (attest-by-report), mirroring 617's *separation* of measured-thing from anchor. | **CHOSEN** |

**Why A is rejected (it was my first design; the advisor's catch).** `source_hash[i]` and `SEED` are both
baked constants living in `.data`, *independent of `.text`*. An adversary who edits `.text` (neuters the
gate) but leaves the table+seed untouched gets `ks_verify()==1` → **GREEN**. The seal would not bind to
the thing it attests, and the "tamper a baked byte → 0" falsifier only proves the fold function detects a
corrupted *input* — a green-passing test that doesn't prove the capability (the exact prove-the-negative
failure mode the project forbids). A is a *degenerate* 617, not a faithful below-OS port (617 measures
**real** boot modules against a **separately-recorded** Ring-−2 seed).

**Why B is rejected (wrong for a relocatable PE).** The loaded image ≠ the disk image: the NT loader
patches `.idata` (live `ntoskrnl` addresses) and applies `.reloc` base fixups (ASLR; `--dynamicbase` is
set) — so a whole-image self-hash is non-deterministic across loads.

**Why C is correct, and *measured* feasible (the decisive finding).** Disassembly of the live
`gate_ioctl.sys` shows **`.text` carries zero base relocations** — both `.reloc` blocks target `.data`
only (PageRVAs `0x15000`,`0x16000`; all entries in `.data` `[0x15000,0x16620)`; `.text` is
`[0x1000,0x14e00)`). Therefore the executing `.text` bytes are **byte-identical on disk and in memory,
every load**, so `cad(.text)` is simultaneously (i) deterministic across loads and (ii) causally bound to
the code the CPU runs. The seed is computed **outside the image** (by III's own `cad` over the linked
`.sys`'s `.text`) and held by the challenger — sound even against an image-controlling adversary, because
the anchor isn't in the thing being measured. The "executed behavior" half is completed by
**triple-bit-identity** (H12/cap-12, proven live: source ⇒ byte-identical binary), giving the full chain
**this source ⇒ this `.text` ⇒ this attestation** (III-APOTHEOSIS L1359).

## Components

```
   build time (III's own cad, no external hashers)        run time (Ring 0, below OS)
   gate_ioctl.sys ──parse PE──► .text bytes               driver_entry
                  └──cad──► SEED (held by challenger)        ├─ ks_selftest engine check (cad"abc"==FIPS)
                                                             │     └─ broken? → STATUS_UNSUCCESSFUL (fail-closed)
   gate_client / corpus ── compares ──┐                     └─ go resident
                                       │                   IOCTL_ATTEST (0x222008):
   reported measurement  ◄────────────┴──────────────────── ks_self_measure(DriverStart) = cad(loaded .text)
       == SEED ?  (attest-by-report; anchor is EXTERNAL)
```

- **`STDLIB/iii/katabasis/quine_seal.iii`** (new, cg_r0-safe; dep: `cad.iii` only → `sha256.iii`, both
  in-closure). API:
  - `ks_measure(base, len, out)` — `cad`(SHA-256) over `[base, base+len)` → 32-byte measurement.
  - `ks_self_measure(image_base, out)` — measure `[image_base + KS_TEXT_RVA, + KS_TEXT_LEN)` using the
    baked **layout** constants (the *range*, never the content) → the running `.text` measurement.
  - `ks_attest(base, len, expected) -> u8` — `ks_measure` then `cad_eq` vs the **externally supplied**
    `expected`. 1 = matches the challenger's seed.
  - `ks_engine_ok() -> u8` — `cad`("abc") == FIPS-180-2 vector: the sealed hasher is real below the OS.
  - `ks_selftest() -> u64` — **99** iff: (a) reproducible: same bytes ⇒ same measurement; (b) **binds to
    content (the real negative)**: flip ONE byte of the measured buffer ⇒ a DIFFERENT measurement
    (`cad_eq`==0) — a measurement that ignored its input would tie here; (c) `ks_engine_ok()`==1.
- **`gate_driver.iii`** (edit, additive): (1) `driver_entry` calls `ks_engine_ok()`; if 0 →
  `return 0xC0000001u64` **before** `IoCreateDevice` (fail-closed: refuse to run with a broken sealer).
  (2) a new `IOCTL_ATTEST` (0x222008) calls `ks_self_measure(DriverStart)` (DriverStart =
  `(driver_object as *u64)[3]`) and writes the 32-byte measurement to the SystemBuffer →
  **attest-by-report** for external comparison. The `gate_ioctl` cycle path is untouched.
- **`STDLIB/corpus/NNN_quine_seal.iii`** (new): `ks_selftest()==99`; EXPECTED entry; run by `run_corpus`
  (same compiled module the kernel uses — user-mode proof of the measurement logic).

## Seed provenance (the external anchor) — computed by III, not an external hasher

A small III tool (`.iii`, compiled by iiis-2) reads `gate_ioctl.sys`, parses the PE section table, finds
`.text`, and `cad`s it → `SEED`. III computes its own anchor; no `sha256sum`/openssl. The challenger
(`gate_client` / the corpus build-twice harness) holds `SEED` and compares the reported measurement.

## Falsifier (prove-the-negative) — "different source ⇒ different attestation"

1. **Content-binding (corpus, user-mode):** `ks_selftest` flips one byte of the measured buffer and
   requires a DIFFERENT measurement — proves the measurement is bound to the bytes, not a constant.
2. **Source ⇒ measurement (build-twice, the capability proof):** build `gate_ioctl.sys` normally → `cad`
   its `.text` = `M_good`; build it again from **one-byte-tampered `gate_driver.iii`** → `cad` its `.text`
   = `M_bad`; require `M_bad ≠ M_good` and `M_good == SEED`. Demonstrates "this source ⇒ this executed
   `.text` ⇒ this attestation," which folding baked constants can never show. (Chains with cap-12's
   already-proven source⇒byte-identical-binary determinism.)
3. **Static (binary):** in the rebuilt `gate_ioctl.sys`, disasm shows `driver_entry`'s `ks_engine_ok`
   fail-closed branch and the `IOCTL_ATTEST` path computing `cad` over `[DriverStart+KS_TEXT_RVA, …]`.

## Risks

| Risk | Impact | Mitigation |
|---|---|---|
| In-kernel fold reads OOB / wrong addr → BSOD | High | Fold only **baked module-scope constants** (no IRP/image pointers); no loaded-image walk (Fork B rejected). |
| Adding a module to the closure breaks a baked table | Med | `ks_selftest` recomputes the fold from the table at runtime and checks vs `SEED` — a stale table reddens the corpus gate before any metal load. |
| cg_r0 ceiling / unsupported construct | Med | Mirror the cg_r0-proven idioms already in `seal.iii`/`gate_driver.iii`; compile with `--ring R0` and require zero `R0_E_UNSUPPORTED`. |
| Can't prove on metal autonomously | Expected | Implement + static-verify (disasm) + corpus-gate the logic; the one UAC load is the operator's `! ` step. |

## Roadmap

1. Write `quine_seal.iii` (cg_r0-safe) + the corpus KAT; gate `ks_selftest==99` via `run_corpus` (user-mode, same compiled module).
2. Wire `driver_entry` fail-closed; rebuild `gate_ioctl.sys`; **disasm** `driver_entry` to prove the attest-or-refuse dominates device creation.
3. Hand the operator one UAC step (`sign_and_deploy_ioctl.ps1`) — below-OS attestation on metal.

---

## STATUS: M23 COMPLETE (autonomous portion) — verification ledger

| Step | Evidence | Result |
|---|---|---|
| `.text` load-invariance | `.reloc` decode of `gate_ioctl.sys`: both blocks → PageRVA `0x16000`/`0x17000` (in `.data`); **none in `.text` `[0x1000,0x15df0)`** | PASS — `.text` relocation-free |
| Measurement logic | `1047_quine_seal` (`run_corpus`): reproducible + **binds-to-content** (flip 1 byte ⇒ different) + engine-real (`cad("abc")==FIPS`) + attest accept/reject (distinct external-seed buffer — non-tautological after review fix) | **=99** |
| Driver wiring (machine code) | `objdump -d`: `DriverEntry` → `call gate_self_attest`; `att!=0` ⇒ `ret` **before** `iii_kio_create_device`; `gate_self_attest` → `call ks_engine_ok`, `!=1` ⇒ `movabs $0xc0000001`; success ⇒ reads `(DriverObject)[3]` (DriverStart) → `call ks_self_measure` | PASS — fail-closed dominates residency |
| Measured range (machine code) | `ks_self_measure` loads `.rodata` consts `0x1000` (`+0x558`) and `0x14e00` (`+0x560`), computes `base+RVA`, `call ks_measure→cad_oneshot` | PASS — hashes exactly the full `.text` |
| Two-pass convergence | pass-1 → pass-2 `.text SizeOfRawData` stayed `0x14e00` (const value lives in `.rodata`, outside `.text`) | PASS |
| **Build-twice falsifier** | `quine_attest_check` (pure III): builds genuine `g.sys` + one-byte-tampered-source `b.sys`; measures each `.text` via `ks_measure`; requires good reproducible **and** good≠tampered | **=99** ("this source ⇒ this `.text` ⇒ this attestation") |
| Live attest client | `quine_attest_client.iii` compiles+links (resolves `ks_measure`/`cad_eq` + `kernel32`) | built (operator-run) |

Final `gate_ioctl.sys` sha256 `b7dac294fcbd0aeb457722db4b875eb14a7377c28685a4776476b276bc9abb76`.

**Honest scope.** The runtime self-measure covers `.text` (the executing code). `.rodata`/`.data`
integrity is covered by the **on-disk signature** (Authenticode, checked by the loader) +
**triple-bit-identity** (cap 12: source ⇒ byte-identical binary), not the in-band self-hash — because
`.data` is mutable and `.idata` is loader-patched. Measuring `.text` alone is the load-invariant,
behavior-binding choice; extending to `.rodata`/`.rdata` (also relocation-free) is a possible future
deepening, but `.text` is what executes and is the agreed scope (ADR-M23-1).

## Operator handoff (the one UAC-gated step I cannot perform autonomously)

A kernel driver load requires Administrator/UAC + test-signing; I cannot do it headless. To complete the
*physical* below-OS attestation:

1. `pwsh KATABASIS-DEPLOY/sign_and_deploy_ioctl.ps1` — signs + `sc start IIIKatabasisGate` (loads resident).
   - If the image is incoherent (broken sealer), `DriverEntry` returns `STATUS_UNSUCCESSFUL` and the load
     fails — fail-closed, by design.
2. From `KATABASIS-DEPLOY/build/`: run `quine_attest_client.exe` (built from `quine_attest_client.iii`).
   - It queries `IOCTL_ATTEST` (the driver's below-OS measurement of its own `.text`) and independently
     recomputes `cad(.text)` from the on-disk `gate_ioctl.sys`. **Exit 99 = the running code IS exactly
     the sealed binary** — the behavioral quine-seal verified live at Ring 0.
3. `sc stop IIIKatabasisGate` — `DriverUnload` tears down cleanly.

Everything above the physical load is proven autonomously (logic gate + machine-code verification +
the build-twice falsifier). The metal load is the operator's trusted action.
