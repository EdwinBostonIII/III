# KATABASIS Tier-3: R3-invokable IOCTL gate (2026-05-23)

The Tier-2 gate decision (proven on metal, Win32 err 50) made a STANDING kernel service queryable
from Ring 3 over DeviceIoControl. Built chunk-by-chunk; every chunk verified in the binary.

## Chunks
- **1 (cg_r0 ntoskrnl imports):** cg_r0 emits BARE symbols for PascalCase EXTERN_DECL callees
  (NT export convention; .iii is snake_case -> stays L_p_). r0_emit_sym_run + r0_callee_is_kernel_import.
  Verified: probe .sys has a real ntoskrnl.exe import dir; the live cap-gate hash 472152e3 UNCHANGED
  (inert); corpus 57/0 + 330/0; iiis-2 mhash 84880e83 (determinism OK).
- **1b (kernel-ABI shims, src/kernel_abi.s):** cg_r0 can't guarantee 16-byte call alignment
  (witness-hook pushes corrupt R0_G_STACK_DEPTH) nor pass >4 args. Hand-asm shims fill the gap:
  rbp frame (SEH-unwindable) + `andq $-16,%rsp` (depth-independent) + full Win64 marshalling incl.
  IoCreateDevice's 7 args. Fixed device/symlink names baked as packed UTF-16 + UNICODE_STRINGs
  (cg_r0's 8-byte-uniform arrays can't lay out contiguous wchars). Shims: create_device,
  create_symlink, complete_request, delete_device, delete_symlink.
- **2 (WDM accessors):** pure-.iii via cg_r0's 8-byte-uniform `(ptr as *u64)[off/8]` -- the IRP/
  IO_STACK_LOCATION fields needed are 8-aligned, so index*8 hits the exact WDK offset. Verified:
  wdm_current_stack -> `[irp+0xB8]` (CurrentStackLocation).
- **3 (gate_driver.iii):** DriverEntry forces scalar crypto, creates the device (-> G_DEVOBJ),
  installs DriverUnload@0x68 + MajorFunction[CREATE]@0x70 / [CLOSE]@0x80 / [DEVICE_CONTROL]@0xE0
  (verified: handler leaqs + index stores), creates the symlink, returns STATUS_SUCCESS (resident).
  gate_ioctl reads the request (IOCTL 0x222000 -- verified `movabs 0x222000;cmp;sete`), builds the
  cycle in the xii_term arena, seals it, runs katabasis_gate_admit, writes the verdict, completes
  the IRP. seal stays in-kernel (cg_r0's self-consistent hash); R3 drives verdicts via cycle params
  + seal_mode.
- **4 (build + client):** build_gate_ioctl.sh links the 19-module closure + driver + cpufeat shim
  + witness + kernel_abi + libntoskrnl.a -> gate_ioctl.sys.

## gate_ioctl.sys verification (sha256 338d0d5a8fe3d617528582a9fb66e3965a7fe0415379ccd34a69493f903c0709)
- compiles with ZERO R0_E_UNSUPPORTED (fail-loud clean).
- PE32+ NT-native; entry == DriverEntry (0x140001737); .reloc + .idata + valid .pdata unwind.
- **ntoskrnl.exe import directory**: IoCompleteRequest, IoCreateDevice, IoCreateSymbolicLink,
  IoDeleteDevice, IoDeleteSymbolicLink (the shims; ld + libntoskrnl.a synthesized the IAT).
- kernel stack (rooted at gate_ioctl, the deep handler): acyclic, 11 frames, 10,728 B = 43.7% of
  the 24 KiB x64 kernel stack.
- byte-reproducible (rebuild -> identical hash).

## R3 contract  (\\.\IIIKatabasisGate, IOCTL_KATABASIS_ADMIT = 0x222000, METHOD_BUFFERED)
Input (6 u64): family, target_kind, target, action_hexad, cap_rights, seal_mode.
Output (1 u64): verdict (0 OK / 1 REJECT_SEAL / 2 REJECT_CAP / 3 REJECT_HEXAD).
gate_client.exe drives the four canonical cases (incl. all THREE rejects -- proving the negative,
not just OK): {2,1,0x20000,728,0x200000,0}->0, {...,1}->1, {...,0x800000,0}->2, {2,1,0x1000,...}->3.

## STATUS
Built + statically verified; deploy-ready. The on-metal LOAD is the operator's UAC-gated trigger
(sign_and_deploy_ioctl.ps1: load resident -> run gate_client.exe -> sc stop = DriverUnload).
Success = client prints "ALL 4 GATE VERDICTS CORRECT" -- the gate decision answered Ring 3 from Ring 0.

## TESTED ON METAL (2026-05-23): PASS
Operator ran sign_and_deploy_ioctl.ps1 (signature Valid, checksum 0x24dbd, test-signing on, HVCI off,
restore point made). `sc start IIIKatabasisGate` -> **STATE RUNNING, exit 0** -- the driver loaded and
STAYED RESIDENT (DriverEntry created \Device\IIIKatabasisGate + \??\IIIKatabasisGate, installed the
dispatch table + DriverUnload, returned STATUS_SUCCESS; no crash). gate_client.exe opened
\\.\IIIKatabasisGate and the in-kernel gate returned **all four verdicts correctly**:
OK->0, REJECT_SEAL->1, REJECT_CAP->2, REJECT_HEXAD->3. `sc stop` ran DriverUnload (symlink + device
deleted) cleanly; machine stayed up; no bugcheck. The hand-asm ntoskrnl shims (IoCreateDevice's 7-arg
call + the `andq $-16` alignment), the WDM IRP/IO_STACK accessors, the MajorFunction/DriverUnload
install, and the METHOD_BUFFERED IOCTL dispatch ALL worked first try on hardware. **The KATABASIS gate
decision is now a standing kernel service, queryable from Ring 3.**
