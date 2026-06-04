# CRASH-AUDIT C.10 — the R3 IOCTL bridge `r3_ioctl_driver.c`

**Unit:** C.10 — Katabasis descent gate & Ring-0 deploy (`DOCS/III-CAPABILITY-APOTHEOSIS.md` §C.10, lines 517-538).
**Status:** `audited` — CRASH PROTOCOL **Phase 1 (read-only evidence)** only. **No source built; no .iii/.c/.sov/.py edited; no kernel build or deploy attempted.** This is Ring-0 / BSOD territory; the live build + deploy are explicitly **trigger-gated** (see §4 Escalations).
**Date:** 2026-05-31. **Auditor worktree:** `C:\Users\Edwin Boston\OneDrive\Desktop\III\.claude\worktrees\wf_15a676f5-b21-2`.

---

## 0. Scope and method

The apex (§C.10, line 519/531) names **one wiring gap**: an *R3 IOCTL bridge* `KATABASIS-DEPLOY/src/r3_ioctl_driver.c` that connects user-mode intent to the kernel-resident gate via `cg_r0`'s `r0_emit_sym_run` kernel-import primitive, making `gate_resident.iii`'s Ring-0 `DriverEntry` selftest into a *live* admission path. This audit:

1. establishes the **verified current state** (what already exists, what is HIST-proven, what is genuinely absent);
2. enumerates **every crash path** for the proposed C driver — numbered, per CRASH PROTOCOL — as a **differential against the already-proven `.iii` driver** and its two fixed BSODs;
3. gives the **exact, ordered build plan** so the future metal session is one focused, audited step;
4. lists **escalations** — the environment/trigger blocks (kernel build toolchain present-but-untriggered, a Ring-0 test target, the BSOD-risk deploy).

Files read in full (READ-ONLY): `STDLIB/iii/katabasis/{gate,admit,cycle_family,ring_lattice,vmexit,bricking,seal}.iii`; `KATABASIS-DEPLOY/src/{gate_resident.iii,gate_driver.iii,kernel_abi.s,gate_client.c}`; `KATABASIS-DEPLOY/build_gate_ioctl.sh`; `KATABASIS-DEPLOY/crash/crash_report.txt`; `DOCS/{IOCTL-GATE-AUDIT.md,CRASH-AUDIT-gate-resident-2.md}`; `COMPILER/BOOT/cg_r0.iii` (`r0_emit_sym_run`, `r0_callee_is_kernel_import` — READ ONLY, not edited).

---

## 1. Verified current state

### 1.1 The gate decision is COMPLETE (source-audited, R0)

- `katabasis_gate_admit(cycle_idx: u32, claimed_seal_addr: u64) -> u32` (`admit.iii:28`) is the fully-autonomous gate: it computes `seal_ok` (`katabasis_cycle_seal_verify`, `seal.iii:55`), `cap_ok` (`katabasis_cap_check`), then delegates to `katabasis_gate_decide_term` (`gate.iii:36`) which adds the hexad + SID-inverse checks and short-circuits in the §4.2 order **seal → cap → hexad → sid**, returning one of `KG_OK(0) / KG_REJECT_SEAL(1) / KG_REJECT_CAP(2) / KG_REJECT_HEXAD(3) / KG_REJECT_IRREVERSIBLE(4)` (`gate.iii:27-31`).
- The six descent fact-tables are `.def`-single-sourced + drift-gated + content-address-sealed and stand un-edited: `cycle_family.iii` (9 families, classes, SID inverses, dangerous-trio F2/F5/F9), `ring_lattice.iii` (R3→R0 = `KRL_C_IOCTL` is the **only** R3→R0 door, key `a*5+b`==1; no skip, no ascent), `vmexit.iii` (6 intercepted exits + total fail-closed catch-all), `svm_layout`, `bar_layout`, `census`.
- `bricking.iii` is the exhaustive unrepresentability theorem (T1: zero of 729 actions make a write to a structural-NEG brick target admissible; T2: the SAFE target preserves the action's own admissibility; T3: 144 admitted, non-vacuity). Fail-closed is a **proven total**, not a default.
- KATs `corpus 390-395, 600-609` cover gate verdicts, family/inverse, ring lattice, VMEXIT, the table reseals, and `609_katabasis_admit`.

### 1.2 The IOCTL bridge ALREADY EXISTS as `.iii` and is HIST-proven on metal

**This is the headline finding.** The apex's "one wiring gap" is, in capability terms, **already closed** — but by a *pure-.iii* driver compiled with `cg_r0`, not by the named `.c` file:

- `KATABASIS-DEPLOY/src/gate_driver.iii` is a **standing, resident** WDM driver. `driver_entry` (`:129`) forces scalar crypto, calls the hand-asm `iii_kio_create_device` shim, installs `DriverUnload@+0x68`, `MajorFunction[CREATE]@+0x70`, `[CLOSE]@+0x80`, `[DEVICE_CONTROL]@+0xE0` into the `DRIVER_OBJECT`, creates the `\??\IIIKatabasisGate` symlink, and returns `STATUS_SUCCESS` (resident).
- `gate_ioctl` (`:68`) reads `IRP.Tail.Overlay.CurrentStackLocation` (IRP+0xB8), the `IoControlCode` (IO_STACK+0x18), and `AssociatedIrp.SystemBuffer` (IRP+0x18); for `IOCTL_KATABASIS_ADMIT = 0x222000` it reads 6×u64 of intent {family, target_kind, target, action_hexad, cap_rights, seal_mode}, builds the cycle in the `xii_term` BSS arena, seals it in-kernel, runs `katabasis_gate_admit`, writes the verdict to `buf[0]`, sets `IoStatus.Status/Information` (IRP+0x30/+0x38, `info=8`), and completes the IRP. A second IOCTL `0x222004` (`IOCTL_SVM_PROBE`) is a read-only Ring-1 CPUID/RDMSR capability report.
- **The seal never leaves the kernel** — R3 supplies cycle params + `seal_mode` (0 = seal correctly; 1 = claim a different cycle's seal → `REJECT_SEAL`), not a seal. This is the §C.10 "seal stays in-kernel" invariant, honored.
- The ntoskrnl link is via `kernel_abi.s` hand-asm shims (`iii_kio_*`) calling `IoCreateDevice / IoCreateSymbolicLink / IoCompleteRequest / IoDeleteDevice / IoDeleteSymbolicLink` BARE; `ld -lntoskrnl` synthesizes the PE import directory + IAT. The shims use an `rbp` SEH-unwindable frame + `andq $-16,%rsp` (depth-independent 16-byte alignment, because `cg_r0`'s stack-depth track is unreliable across witness-hook pushes) and marshal `IoCreateDevice`'s 7 args (4 regs + 3 stack slots above the 0x20 shadow). Device/symlink names are baked as packed UTF-16 + `UNICODE_STRING` headers in `.rdata`.
- **`DOCS/IOCTL-GATE-AUDIT.md` "TESTED ON METAL (2026-05-23): PASS"**: operator ran `sign_and_deploy_ioctl.ps1`; `sc start IIIKatabasisGate` → STATE RUNNING, stayed resident; `gate_client.exe` opened `\\.\IIIKatabasisGate` and the in-kernel gate returned **all four verdicts correctly** (OK→0, REJECT_SEAL→1, REJECT_CAP→2, REJECT_HEXAD→3); `sc stop` ran `DriverUnload` cleanly; no bugcheck. `gate_ioctl.sys` sha256 `338d0d5a…`, 11-frame acyclic stack = 10,728 B = 43.7 % of the 24 KiB kernel stack, byte-reproducible.

### 1.3 The named `r3_ioctl_driver.c` is GENUINELY ABSENT — and inherits ZERO metal history

- Glob `**/r3_ioctl*` → **No files found**. The exact file `KATABASIS-DEPLOY/src/r3_ioctl_driver.c` named at §C.10 line 531 **does not exist**.
- **HIST honesty (per the apex's own labeling, line 519):** the *capability* (R3→R0 live admission) is `⟦HIST⟧`-proven via `gate_driver.iii` on 2026-05-23. A new **C** driver is a *different binary produced by a different compiler* (mingw gcc, not `cg_r0`). It inherits **none** of that metal history. The `.iii` pass must **not** launder into a "C driver proven" claim. The C driver's "proven on metal (Ring-0, Tier-2, no BSOD)" remains honestly `⟦HIST⟧`-absent until its *own* operator-triggered load.

### 1.4 Prior BSOD history (both fixed, both re-proven) — the differential baseline

Two prior bugchecks, BOTH in the **pure-.iii / `cg_r0`** path, both root-caused in machine code and re-proven on metal:

- **BSOD #1** — a dropped `if` guard (cg_r0 control-flow lowering).
- **BSOD #2** (`crash/052326-10453-01.dmp`, `crash_report.txt`, `CRASH-AUDIT-gate-resident-2.md`): **0x1E KMODE_EXCEPTION_NOT_HANDLED**, P1=0xC0000005 (AV), P3=1 (WRITE), P4=0x30 (faulting write address). Faulting RIP 0x…6fa0 = `mov [rax+rcx*8], rdx` with rax=0x30, rcx=0 inside `sha256_final`. **Root cause: `cg_r0` had NO `EXPR_CAST` lowering** — a cast node fell to `R0_E_UNSUPPORTED` and **emitted no value**, so `sha256_oneshot(&KCS_BUF as *u8, 48u64, o as *u8)` pushed only the bare literal `48u64`; the 3-arg pop shifted and the length `48 (0x30)` landed in `r8`=out_ptr → write-AV at 0x30. **Meta-bug:** internal `r0_emit_expr` recursions swallowed the `R0_E_UNSUPPORTED` return, so a broken build linked "clean." **Fix:** added `R0_K_EXPR_CAST=72` value pass-through + completed fail-loud through the whole expression tree; re-proven on metal (`sc start` → Win32 error 50; pinned `472152e3…`).

**The differential consequence (carried into §2):** both prior BSODs were **`cg_r0` codegen defects**. A mingw-compiled **C** driver is *immune to that entire defect class* (this is the strongest point in favor of the C path). But a hand-written C kernel driver introduces a *new* hazard class the `.iii` path was partly shielded from: **hand-declared WDM ABI offsets + raw pointer arithmetic + missing buffer-length validation**, none of which mingw will catch. §2 enumerates these.

---

## 2. Crash-path analysis — `r3_ioctl_driver.c` (CRASH PROTOCOL, numbered)

Every hazard below is something the C driver **must** provably guard. Each cites the corresponding `gate_driver.iii` behavior so the C realization can be diffed against the proven artifact. "GUARD" = the mandatory mitigation; "VERIFY-IN-BINARY" = the Phase-2 disassembly obligation before deploy.

### CP-1 — HEADLINE: missing IOCTL buffer-length validation (METHOD_BUFFERED OOB read/write)
**Verified gap in the proven artifact:** `gate_ioctl` in `gate_driver.iii` (`:68-119`) reads `IO_STACK.Parameters.DeviceIoControl.IoControlCode` (+0x18) but **never reads `OutputBufferLength` (IO_STACK +0x08) nor `InputBufferLength` (+0x10)**. It reads `SystemBuffer[0..5]` (48 B) and writes `SystemBuffer[0]` with `info=8` **with no length check**.
**Hazard:** under METHOD_BUFFERED, `Irp->AssociatedIrp.SystemBuffer` is a single NonPagedPool allocation sized `max(InputBufferLength, OutputBufferLength)`. A malicious or buggy R3 caller can `DeviceIoControl` with `InputBufferLength < 48` and/or `OutputBufferLength < 8`. The driver then reads up to 48 B / writes 8 B **past the end of a pool block** → pool corruption → delayed BSOD (0x19 BAD_POOL_HEADER / 0xC2) or immediate AV. The 2026-05-23 metal PASS never hit this because `gate_client.c` always sends exactly `sizeof(in)=48`, `sizeof(out)=8` — **the adversarial short-buffer case was never exercised.** This is precisely the gap CRASH PROTOCOL exists to catch.
**GUARD (C driver, mandatory):** read both lengths from the IO_STACK_LOCATION; if `InputBufferLength < 48 || OutputBufferLength < 8` → complete with `STATUS_BUFFER_TOO_SMALL (0xC0000023)`, `Information = 0`, **return early** — never touch `SystemBuffer`. Treat `SystemBuffer == NULL` (zero-length buffered request) as the same reject.
**VERIFY-IN-BINARY:** disassemble the dispatch; confirm both length loads + the compare + the early `IoCompleteRequest` precede any `SystemBuffer` deref.

### CP-2 — NIH WDM ABI: hand-declared struct offsets (no WDK headers)
**Hazard:** NIH discipline forbids WDK/`<wdm.h>` headers. The C driver must hand-declare every WDM offset it touches. A single wrong offset = wild pointer = AV/pool-corruption. The proven `.iii` offsets are the ground truth to replicate **exactly**:
- `IRP.Tail.Overlay.CurrentStackLocation` = **IRP + 0xB8** (`gate_driver.iii:46`, index 23×8).
- `IRP.AssociatedIrp.SystemBuffer` = **IRP + 0x18** (index 3×8).
- `IRP.IoStatus.Status` = **IRP + 0x30**; `IRP.IoStatus.Information` = **IRP + 0x38** (index 6,7).
- `IO_STACK_LOCATION.Parameters.DeviceIoControl.OutputBufferLength` = **IO_STACK + 0x08**; `.InputBufferLength` = **+0x10**; `.IoControlCode` = **+0x18** (the `.iii` read `[3]`=+0x18 for the code).
- `DRIVER_OBJECT.DriverUnload` = **+0x68**; `MajorFunction[0]=CREATE` = **+0x70**; `[2]=CLOSE` = **+0x80**; `[14]=DEVICE_CONTROL` = **+0xE0**.
**GUARD:** declare these as named `#define`/`enum` byte offsets with a comment citing `gate_driver.iii`; access via `*(volatile ULONG_PTR*)((char*)irp + OFF)`. **Do NOT** assume `nt`/WDK struct layouts. If the build *must* pull `<wdm.h>` for `IoCreateDevice` prototypes, that is an **escalation** (NIH deviation), not a silent dependency.
**VERIFY-IN-BINARY:** every offset constant in the disassembly must match the list above.

### CP-3 — IRP/SystemBuffer pointer-arithmetic UAF / type-confusion (the C-path's new defect class)
**Hazard (replaces the cg_r0 defect class of §1.4):** mingw eliminates the `cg_r0` cast/codegen BSODs, but C pointer arithmetic on hand-declared structs is itself unsafe: an off-by-one index, a `ULONG` vs `ULONG_PTR` width slip, or dereferencing `CurrentStackLocation` before validating it is non-NULL re-introduces the exact P3=WRITE AV class of BSOD #2 by a different door.
**GUARD:** (a) load `CurrentStackLocation` once into a local, NULL-check it; (b) use fixed-width types (`ULONG` for the 32-bit IOCTL code/lengths, `ULONG_PTR`/`PVOID` for pointers) matching the WDM ABI — never truncate a pointer to 32 bits (cf. the global "16-bit null check" / width-slip trap); (c) read each intent field into a local before use (no aliasing of `SystemBuffer` after `IoCompleteRequest`).
**VERIFY-IN-BINARY:** confirm 64-bit loads/stores for pointers (REX.W), 32-bit for the code/length compares.

### CP-4 — Use-after-complete (touching the IRP/SystemBuffer after IoCompleteRequest)
**Hazard:** once `IoCompleteRequest` is called the IRP (and its `SystemBuffer`) may be freed/reused immediately; any subsequent read/write is a UAF → AV or silent corruption. The `.iii` path is correct here: it writes the verdict + status **before** `iii_kio_complete_request` (`gate_driver.iii:95-117`).
**GUARD:** structure the C handler as: validate → compute verdict into a **local** → write `SystemBuffer[0]`, `IoStatus.Status`, `IoStatus.Information` → `IoCompleteRequest(irp, IO_NO_INCREMENT)` → `return status`. Nothing after the complete touches the IRP. Exactly one `IoCompleteRequest` on every path (including every early reject of CP-1).
**VERIFY-IN-BINARY:** every control-flow path to `ret` passes through exactly one `IoCompleteRequest`, and no `SystemBuffer` access dominates-after it.

### CP-5 — IRQL discipline (PASSIVE_LEVEL handler must not raise/block illegally)
**Hazard:** `IRP_MJ_DEVICE_CONTROL` for a buffered request arrives at **PASSIVE_LEVEL**. The gate-admit closure runs SHA-256/keccak over a 48-byte record + pure table lookups — all CPU-bound, no I/O, no waits — so PASSIVE is correct. The risk is a future edit that calls a `> DISPATCH_LEVEL`-unsafe API, or touches pageable memory at raised IRQL. Also: the BSS arena (`xii_term`, `G_SEAL`, `G_WRONG`, `KCS_BUF/KCS_TMP`) is NonPaged (driver `.bss`) — fine; do not move it to pageable.
**GUARD:** keep the handler PASSIVE, non-blocking, no allocations; document "no IRQL raise; all state in NonPaged .bss." Tie to CP-6 (no EVEX/float).
**VERIFY-IN-BINARY:** no `Ke`-raise calls; no page-faultable data refs.

### CP-6 — FPU/SIMD state in Ring 0 (EVEX/AVX without KeSaveExtendedProcessorState)
**Hazard:** a Ring-0 path that issues AVX/AVX-512 (EVEX) without `KeSaveExtendedProcessorState` corrupts user/other-thread XMM/YMM/ZMM state → corruption/BSOD. The `.iii` path pins SHA-256 + keccak to scalar GP-register paths (`sha256_sched_force(1)`, `keccak_chi_force_path(1)` at `gate_driver.iii:130-131`; `cpufeat_kernel.iii` reports `avx512f=0`).
**GUARD:** the C driver must call the **same** force-knobs in `DriverEntry` before any gate call, and must itself contain no float/SIMD (compile with `-mgeneral-regs-only` or equivalent; verify no `xmm`/`ymm`/`zmm`/`vmov*` in the C driver's own `.text`). If the linked `.iii` crypto objects are reused as-is (recommended), the existing pinning carries over — but the C `DriverEntry` must still invoke it.
**VERIFY-IN-BINARY:** `objdump` the driver `.text`; zero vector ops on the gate path.

### CP-7 — Stack budget (re-measure; the C profile differs from the .iii 10,728 B)
**Hazard:** the x64 kernel stack is **24 KiB**. The proven `.iii` driver measured 11 frames / 10,728 B / 43.7 %. The C compiler's frame layout, inlining, and the `kernel_abi.s` shim depth differ, so the budget **must be re-measured for the C build** — a regression past ~24 KiB = stack overflow → double-fault BSOD (no graceful path).
**GUARD:** after build, run the existing `KATABASIS-DEPLOY/build/stackdepth.py` (or equivalent) over the C driver's call graph; assert acyclic + peak < ~50 % of 24 KiB.
**VERIFY-IN-BINARY:** acyclic call graph; recorded peak.

### CP-8 — DriverEntry partial-init / dispatch-installed-before-ready (TOCTOU on load)
**Hazard:** if `DriverEntry` installs the `MajorFunction[DEVICE_CONTROL]` handler and creates the symlink **before** the gate state (arena, crypto force-knobs) is ready, a racing R3 open+IOCTL between symlink-create and entry-return hits an uninitialized handler. The `.iii` order is correct: force crypto → create device → install dispatch/unload → **create symlink last** (`gate_driver.iii:130-137`), so the symlink (the R3 entry point) appears only after the dispatch table is live.
**GUARD:** replicate the order exactly: scalar-force → `IoCreateDevice` → install `DriverUnload` + all `MajorFunction` slots → `IoCreateSymbolicLink` **last** → return `STATUS_SUCCESS`. If `IoCreateDevice` fails, return its NTSTATUS **without** creating the symlink and **without** returning success (else a resident-but-broken driver).
**VERIFY-IN-BINARY:** symlink creation is the last side-effect before the success return; failure path returns the error.

### CP-9 — DriverUnload teardown ordering (delete symlink before device; idempotent)
**Hazard:** on `sc stop`, `DriverUnload` must delete the symlink **before** the device object, and must not double-free or touch a never-created object. Wrong order or a stale `G_DEVOBJ` → AV on unload. The `.iii` path: `iii_kio_delete_symlink()` then `iii_kio_delete_device(G_DEVOBJ[0])` (`gate_driver.iii:122-126`).
**GUARD:** delete symlink → delete device; guard `G_DEVOBJ != NULL`; never `IoDeleteDevice` on a device with outstanding IRPs (the gate completes every IRP synchronously, so none are outstanding — preserve that synchronous-complete property).
**VERIFY-IN-BINARY:** unload calls delete-symlink then delete-device, NULL-guarded.

### CP-10 — ntoskrnl call alignment + SEH-unwind (shared with the .iii path's shims)
**Hazard:** every ntoskrnl call needs RSP 16-byte-aligned at the `call` and a valid `.pdata`/`.xdata` unwind record (else a fault inside ntoskrnl while unwinding through our frame = double fault). The `.iii` path solved this with hand-asm `andq $-16,%rsp` + `.seh_*` shims because `cg_r0` couldn't guarantee alignment. **mingw's C ABI already maintains 16-byte alignment and emits `.pdata` automatically** — so a C driver can call `IoCreateDevice` etc. *directly* (no hand-asm shim needed), which is a **simplification win** over the `.iii` path. The hazard is only if hand-asm is mixed in incorrectly.
**GUARD:** call ntoskrnl APIs directly from C (let mingw handle alignment + unwind + the 7-arg `IoCreateDevice` stack args). Keep the `UNICODE_STRING` device/symlink names as static C structs (mingw lays out contiguous `wchar_t` natively — another `.iii`-shim simplification). Link `-lntoskrnl`.
**VERIFY-IN-BINARY:** valid `.pdata` for every C function; `IoCreateDevice` call site passes 7 args correctly (4 reg + 3 stack above shadow); RSP aligned at each `call`.

### CP-11 — Seal-stays-in-kernel invariant (security, not a BSOD, but mandatory)
**Hazard:** if the C driver were to accept a *seal* from R3 (instead of computing it in-kernel), R3 could forge `REJECT_SEAL`→`OK`, defeating the gate. The `.iii` contract is correct: R3 supplies cycle params + `seal_mode` only; the kernel seals via `katabasis_cycle_seal` into `G_SEAL` and (for `seal_mode==1`) `G_WRONG`, never trusting an R3-supplied digest.
**GUARD:** the C driver's input contract is **6×u64 {family, target_kind, target, action_hexad, cap_rights, seal_mode}** — identical to `gate_driver.iii` and `gate_client.c`. No seal field. Output 1×u64 verdict.
**VERIFY:** input struct has no seal; the only seal addresses passed to `katabasis_gate_admit` are `&G_SEAL`/`&G_WRONG` (kernel BSS).

### CP-12 — Concurrent IOCTLs racing the shared BSS arena (serialization)
**Hazard:** `xii_term` arena, `KCS_BUF`, `G_SEAL`, `G_WRONG` are **process-global driver BSS**, not per-IRP. Two R3 threads issuing `IOCTL_KATABASIS_ADMIT` concurrently race `xii_term_arena_reset()` + the cycle build → interleaved arena state → wrong verdict or AV. The 2026-05-23 single-threaded `gate_client.exe` never exercised concurrency.
**GUARD:** serialize the device (one of: create the device with no concurrency and rely on a `KSPIN_LOCK`/`FAST_MUTEX` around the build-seal-admit critical section at PASSIVE; or document the device as single-instance exclusive). A `FAST_MUTEX` at PASSIVE_LEVEL is the clean fit (DEVICE_CONTROL is PASSIVE). Note: introducing a mutex adds an IRQL consideration (CP-5) — `FAST_MUTEX` raises to APC_LEVEL, which is fine for the non-paged, non-blocking gate work.
**VERIFY-IN-BINARY:** the build→seal→admit→write sequence is inside one acquire/release; release on every path.

### CP-13 — Unmodelled IOCTL code → must fail closed, not fall through
**Hazard:** an unrecognized `IoControlCode` must return `STATUS_INVALID_DEVICE_REQUEST (0xC0000010)` with `Information=0` and complete the IRP — never leave the buffer half-written or the IRP uncompleted (uncompleted IRP = hung handle / leaked IRP). The `.iii` path defaults `status=0xC0000010` and only overwrites it inside the recognized code arms (`gate_driver.iii:72`), then always completes (`:116-117`).
**GUARD:** `default`/else arm returns `STATUS_INVALID_DEVICE_REQUEST`, `Information=0`, single `IoCompleteRequest`. (This is the §C.10 "fail-closed" discipline at the IOCTL surface.)
**VERIFY-IN-BINARY:** unknown-code path completes with 0xC0000010 and Information=0.

---

## 3. Build plan (exact, ordered — so the metal session is one audited step)

> All steps below are **DESIGN ONLY** in this audit; none is executed here. The live build + deploy are trigger-gated (§4). `cg_r0` and the live compiler are **NOT** edited (the kernel-import primitive `r0_emit_sym_run` already exists, `cg_r0.iii:621`, used only by the *existing* `.iii` shims; the C driver does not need it — see CP-10).

### 3.1 The C driver `KATABASIS-DEPLOY/src/r3_ioctl_driver.c` (NIH; no WDK headers)
1. **Hand-declared WDM ABI** (per CP-2): `typedef`/`#define` the byte offsets for `DRIVER_OBJECT` (+0x68/+0x70/+0x80/+0xE0), `IRP` (+0x18/+0x30/+0x38/+0xB8), `IO_STACK_LOCATION` (+0x08/+0x10/+0x18). Hand-declare `UNICODE_STRING { USHORT Length, MaximumLength; ULONG pad; PWSTR Buffer; }`. Declare the ntoskrnl prototypes (`NTSTATUS IoCreateDevice(...)` 7 args, `IoCreateSymbolicLink`, `IoCompleteRequest`, `IoDeleteDevice`, `IoDeleteSymbolicLink`) with `__declspec(dllimport)`-free bare externs so `-lntoskrnl` binds the IAT (mirrors the `.iii` BARE-symbol convention `r0_emit_sym_run` produces).
2. **`extern` the gate-admit closure** (the *same* cg_r0-compiled `.o` set the `.iii` driver links — reuse, do not re-implement): `xii_term_arena_reset`, `cap_env_init`, `cap_attenuate`, `katabasis_cycle_act`, `katabasis_cycle_under_cap`, `katabasis_cycle_seal`, `katabasis_gate_admit`, `sha256_sched_force`, `keccak_chi_force_path`. **Critical NIH/ABI note:** these `.iii` exports use `@abi(c-msvc-x64)` and cg_r0's `L_p_` name prefix. The C driver must declare them with the matching **symbol name** the linker sees (the `L_p_…` label, or via an `.s` thunk / `--defsym` alias) — confirm the exact emitted symbol by `objdump -t` on `admit.o` before wiring (an unresolved-symbol link error is the fail-loud catch here).
3. **`DriverEntry(PDRIVER_OBJECT, PUNICODE_STRING) -> NTSTATUS`** (per CP-8): `sha256_sched_force(1); keccak_chi_force_path(1);` → `IoCreateDevice(drv, 0, &g_devname, 0x22 /*FILE_DEVICE_UNKNOWN*/, 0, FALSE, &G_DEVOBJ)`; on failure return its NTSTATUS. Then install `drv->DriverUnload`, `MajorFunction[IRP_MJ_CREATE]=GateCreate`, `[IRP_MJ_CLOSE]=GateClose`, `[IRP_MJ_DEVICE_CONTROL]=KatabasisGateIOCTL` via the hand-declared offsets. Then `IoCreateSymbolicLink(&g_linkname, &g_devname)` **last**. Return `STATUS_SUCCESS`.
4. **`KatabasisGateIOCTL(PDEVICE_OBJECT, PIRP) -> NTSTATUS`** (the forwarding handler, per CP-1/3/4/5/11/12/13): load `CurrentStackLocation` (IRP+0xB8), NULL-check; read `IoControlCode` (+0x18), `InputBufferLength` (+0x10), `OutputBufferLength` (+0x08); read `SystemBuffer` (IRP+0x18). **If code==0x222000:** if `In<48 || Out<8 || SystemBuffer==NULL` → reject `STATUS_BUFFER_TOO_SMALL` (CP-1). Else acquire the FAST_MUTEX (CP-12), read the 6 intent u64s into locals, `xii_term_arena_reset(); root=cap_env_init(); cap=cap_attenuate(root, cap_rights, 0); a=katabasis_cycle_act(family,tk,tgt,ah); c=katabasis_cycle_under_cap(a,cap); katabasis_cycle_seal(c,&G_SEAL);` choose `seal_addr=&G_SEAL` (or build the wrong-cycle seal into `&G_WRONG` when `seal_mode==1`); `verdict=katabasis_gate_admit(c, seal_addr);` write `((PULONG64)SystemBuffer)[0]=verdict`; release mutex; set `IoStatus.Status=STATUS_SUCCESS, Information=8`. **Else** (CP-13) `STATUS_INVALID_DEVICE_REQUEST, Information=0`. Single `IoCompleteRequest(irp, IO_NO_INCREMENT)`; return status. **(Optional)** mirror `0x222004 IOCTL_SVM_PROBE` only if the operator wants the read-only SVM report; it adds the CPUID/RDMSR shim surface — recommend deferring it from the first C build to keep the audited surface minimal.)
5. **`GateCreate`/`GateClose`** — set `IoStatus.Status=STATUS_SUCCESS, Information=0`; `IoCompleteRequest`; return success.
6. **`DriverUnload(PDRIVER_OBJECT)`** (per CP-9): `IoDeleteSymbolicLink(&g_linkname)`; if `G_DEVOBJ` `IoDeleteDevice(G_DEVOBJ)`.
7. **NTSTATUS mapping** (the contract): verdict u64 in `SystemBuffer[0]` ∈ {0 OK,1 SEAL,2 CAP,3 HEXAD,(4 IRREVERSIBLE)}; transport NTSTATUS = `STATUS_SUCCESS` whenever the gate *ran* (verdict carried in the buffer), `STATUS_BUFFER_TOO_SMALL`/`STATUS_INVALID_DEVICE_REQUEST` only when it could not. **Do not** overload NTSTATUS with the verdict — the verdict is data, not transport status (this matches `gate_driver.iii` and `gate_client.c`).

### 3.2 Static C names (NIH UNICODE_STRING, per CP-10)
Static `wchar_t g_devname_buf[] = L"\\Device\\IIIKatabasisGate";` + `g_linkname_buf[] = L"\\??\\IIIKatabasisGate";` and their `UNICODE_STRING` headers (`Length` = byte count w/o NUL = 48 / 40; `MaximumLength` = +2). mingw lays out contiguous `wchar_t` natively (no `.iii` packed-`.short` workaround needed).

### 3.3 Build script `KATABASIS-DEPLOY/build_r3_ioctl.sh` (mirror `build_gate_ioctl.sh`)
- `SOURCE_DATE_EPOCH=0 LC_ALL=C TZ=UTC0` (determinism).
- Compile the **same** 19-module gate-admit closure with `COMPILED/iiis-2.exe … --ring R0 --compile-only` (unchanged from `build_gate_ioctl.sh:17-30`): `omnia/{hexad_algebra,hexad_pfs,hexad_reach,xii_term} numera/{sha256,keccak256,keccak,content_addr} aether/capability katabasis/{svm_layout,bar_layout,cycle_family,cycle_admit,cycle_term,seal,caps,gate_verdict,gate,admit}`. **Reuse `cad.iii`** if `seal.iii` now routes through it (`seal.iii:21` externs `cad_oneshot`/`cad_eq` from `cad.iii` — confirm `cad` + its deps are in the closure; the older audit listed `content_addr` — VERIFY the closure matches `seal.iii`'s current externs before linking, else unresolved-symbol fail-loud).
- Compile `r3_ioctl_driver.c` with mingw: `x86_64-w64-mingw32-gcc -c -mabi=ms -ffreestanding -mgeneral-regs-only -O2 -Wall -Wextra -Werror r3_ioctl_driver.c -o r3_ioctl_driver.o` (no CRT, GP-regs-only per CP-6).
- Assemble `witness_kernel.s` (reused). **No `kernel_abi.s`** needed (CP-10: mingw C calls ntoskrnl directly) — *unless* the optional SVM probe is kept, which still needs the `iii_kio_cpuid/readmsr` asm.
- Link: `x86_64-w64-mingw32-gcc -mabi=ms -ffreestanding -shared -nostdlib -Wl,--subsystem,native -Wl,-e,DriverEntry -Wl,--exclude-all-symbols -Wl,--image-base,0x140000000 -Wl,--no-insert-timestamp -Wl,--dynamicbase -Wl,--nxcompat -o build/r3_ioctl_driver.sys r3_ioctl_driver.o <closure .o's> witness_kernel.o -lntoskrnl`.
- `sha256sum` the `.sys`; rebuild → assert byte-identical (determinism).

### 3.4 Static verification BEFORE any load (Phase-2 obligations, all CP VERIFY-IN-BINARY items)
1. `objdump -p` : PE32+ NT-native, entry == DriverEntry, real `ntoskrnl.exe` import dir (IoCreateDevice, IoCreateSymbolicLink, IoCompleteRequest, IoDeleteDevice, IoDeleteSymbolicLink), `.reloc` + valid `.pdata`.
2. `objdump -d r3_ioctl_driver.sys` for `KatabasisGateIOCTL`: confirm CP-1 length guards precede any SystemBuffer deref; CP-2 offsets match; CP-4 single `IoCompleteRequest` per path; CP-6 zero vector ops; CP-13 unknown-code fail-closed.
3. `stackdepth.py`: acyclic, peak < ~50 % of 24 KiB (CP-7).
4. Confirm the gate-admit `.o` symbols resolve (no unresolved `L_p_*`) — the NIH ABI-name catch of §3.1.2.

### 3.5 On-metal deploy (TRIGGER-GATED — see §4)
`sign_and_deploy_r3_ioctl.ps1` (mirror `sign_and_deploy_ioctl.ps1`): make a restore point; test-sign; `sc create … type= kernel`; `sc start IIIKatabasisGate` → expect STATE RUNNING (resident, no crash); run `gate_client.exe` (unchanged — same `\\.\IIIKatabasisGate`, same 4 cases incl. all 3 rejects) → expect "ALL 4 GATE VERDICTS CORRECT"; **plus** a new adversarial short-buffer case proving CP-1 returns `STATUS_BUFFER_TOO_SMALL` rather than crashing; `sc stop` → DriverUnload clean; machine stays up. Only then is the C-driver `⟦HIST⟧` honestly populated.

---

## 4. Escalations (environment / explicit-trigger blocks — NOT defers)

These cannot and must not be performed in this audited, read-only worktree session. Each requires an explicit operator/orchestrator trigger:

- **E-1 — Kernel build is reserved.** Writing `r3_ioctl_driver.c` + `build_r3_ioctl.sh` and running the mingw build is *implementation*, gated by the orchestrator. (Toolchain IS present — verified: `x86_64-w64-mingw32-gcc` 15.2.0, `ld`, and `libntoskrnl.a` at `C:\ProgramData\mingw64\mingw64\x86_64-w64-mingw32\lib\libntoskrnl.a` — so the build is *possible* once triggered; it is *not* attempted here per the C.10 read-only constraint.)
- **E-2 — Ring-0 test target.** Loading any `.sys` requires a test-signing-enabled, HVCI-off, restore-pointed machine (the operator's box, as in the 2026-05-23 run). No such target may be driven from this session.
- **E-3 — BSOD-risk deploy.** `sc start` of a kernel driver is the live BSOD-risk step (two prior BSODs on this exact gate). It is the operator's UAC-gated trigger via `sign_and_deploy_*.ps1`. Must follow CRASH PROTOCOL Phases 2-4 (verify-in-binary every CP guard, then deploy, then run the exact test incl. the new CP-1 adversarial case, then confirm the driver state).
- **E-4 — signtool absent.** `signtool.exe` was not found on PATH in this environment; the deploy script's test-signing step needs it (or an equivalent) on the metal target — an operator/environment prerequisite.
- **E-5 — Architectural choice: C driver vs. the proven `.iii` driver.** The apex §C.10 names `r3_ioctl_driver.c`, but the equivalent bridge **already exists and is metal-proven** as `gate_driver.iii` (§1.2). Whether to (a) build the C realization the apex names (immune to the cg_r0 BSOD class; adds the hand-WDM/buffer-length class), (b) keep the proven `.iii` driver and merely *retrofit* the CP-1 buffer-length guard into `gate_driver.iii` (smallest metal-risk delta; but that edits a driver source — itself a gated change), or (c) both — is an **orchestrator decision**, not the auditor's. Routed here per the task's "escalations = everything that requires an explicit trigger." Recommendation for the orchestrator's consideration only: option (a) is the apex-faithful path and the C ABI removes the entire cg_r0 codegen risk class; whichever is chosen, **CP-1 (buffer-length validation) is the one substantive gap in the currently-proven artifact and should be closed in the chosen target before the next metal load.**

---

## 5. Summary

The §C.10 gate decision is **complete and source-audited**; the R3→R0 IOCTL bridge **capability** is **HIST-proven on metal** (2026-05-23) via the pure-`.iii` `gate_driver.iii` — but the apex-named **`r3_ioctl_driver.c` is genuinely absent and inherits no metal history of its own.** This audit enumerates **13 numbered crash paths** for the proposed C driver as a differential against the proven `.iii` artifact and its two fixed (cg_r0-codegen) BSODs; the C ABI **removes the entire cg_r0 codegen defect class** but introduces a hand-WDM/pointer-arith class whose **headline hazard is CP-1: the proven `.iii` driver has no IOCTL buffer-length validation** (never exercised because the happy-path client always sized buffers correctly), a METHOD_BUFFERED OOB read/write the C driver must guard. The exact, ordered build plan (DriverEntry → KatabasisGateIOCTL forwarding the 6×u64 intent manifest to `katabasis_gate_admit` → NTSTATUS-as-transport / verdict-as-data → direct ntoskrnl link via `-lntoskrnl`) lets the future metal session be one focused, fully-audited step. **No source was built, no `.iii`/`.c`/`.sov`/`.py` edited, no kernel build or deploy attempted** — the live build + deploy are trigger-gated (E-1…E-5).
