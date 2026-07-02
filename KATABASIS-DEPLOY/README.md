# KATABASIS-DEPLOY — reproducible build / verify / deploy

The deploy harness for III's Ring-0 and Ring −1 work on this machine. Everything here is NIH (only libc,
the III BOOT headers, mingw `gcc`/`ld`/`objdump`/`as`, and mingw's `libntoskrnl.a`), deterministic
(byte-reproducible hashes), and operator-gated (the kernel-load trigger is always your UAC). Milestone
record: `../DOCS/RING-MINUS-1-MILESTONE.md`. Working log: `../DOCS/RING-MINUS-1-LEDGER.md`.

## 0. Prerequisites (one-time)

- Toolchain: `COMPILED/iiis-2.exe` (the self-hosting III compiler; `cg_r0` Ring-0 backend), and mingw-w64
  (`x86_64-w64-mingw32-gcc`, `ld`, `objdump`, `as`) on PATH. Build from the III root.
- Machine state for loading (NOT for building): **test-signing ON** (`bcdedit /set testsigning on` + reboot)
  and **HVCI / Memory Integrity OFF** (it rejects self-signed drivers). The deploy script checks both.
- Everything builds without admin; only the *deploy* needs the UAC.

## 1. Artifacts

| artifact | what it is | tier |
|---|---|---|
| `build/gate_resident.sys` | the gate decision running RESIDENT in Ring 0 (4-case selftest) | Tier-2 |
| `build/gate_ioctl.sys` | the gate decision as an R3-invokable service over DeviceIoControl + the I0 SVM probe | Tier-3 / I0 |
| `build/gate_floor.sys` | the Ring −1 floor: I0→I4 (probe, teardown, host-mode, VMCB, VMRUN, gate@VMEXIT, resume-loop, NPT-intercept) | Ring −1 |
| `build/floor_client.exe`, `build/gate_client.exe` | R3 clients that drive the IOCTLs and check results | — |

## 2. Build (deterministic)

From the III root (`C:\Users\Edwin Boston\OneDrive\Desktop\III`):

```bash
bash KATABASIS-DEPLOY/build_gate_floor.sh      # -> build/gate_floor.sys     (Ring -1 floor)
bash KATABASIS-DEPLOY/build_gate_ioctl.sh      # -> build/gate_ioctl.sys     (Tier-3 + I0 probe)
bash KATABASIS-DEPLOY/build_gate_resident.sh   # -> build/gate_resident.sys  (Tier-2)
x86_64-w64-mingw32-gcc -O2 -o KATABASIS-DEPLOY/build/floor_client.exe KATABASIS-DEPLOY/src/floor_client.c
x86_64-w64-mingw32-gcc -O2 -o KATABASIS-DEPLOY/build/gate_client.exe  KATABASIS-DEPLOY/src/gate_client.c
```

Each `build_*.sh` prints the sha256; it is byte-reproducible (SOURCE_DATE_EPOCH=0, no timestamps). The
floor build compiles `gate_floor.iii` + the 19-module gate-admit closure + `cpufeat_kernel.iii` via
`cg_r0`, assembles `floor_abi.s` (the SVM/Io/Mm/IRQL shims) + the witness leaf, and links a PE32+ native
driver (entry `DriverEntry`, image base `0x140000000`, ntoskrnl imports).

## 3. Verify (PD-2 — before any load)

```bash
O=KATABASIS-DEPLOY/build/obj
# imports must be ntoskrnl-only:
objdump -p KATABASIS-DEPLOY/build/gate_floor.sys | grep "DLL Name"
# stack must be acyclic and < 24 KiB (kernel stack):
python KATABASIS-DEPLOY/build/stackdepth.py L_p_floor_ioctl   # peak ~11.5 KiB, VERDICT OK
# spot-check privileged opcodes in the shims (CHARIOT byte-identical):
objdump -d -M intel "$O/floor_abi.o"   # cpuid 0f a2, rdmsr 0f 32, wrmsr 0f 30,
                                       # clgi 0f01dd / vmsave 0f01db / vmrun 0f01d8 / vmload 0f01da / stgi 0f01dc
```

The deterministic hash printed by the build must equal the `$ExpectedHash` pinned in the deploy script
(`sign_and_deploy_floor.ps1`). If you change source, rebuild, re-verify, and update the pin.

## 4. Deploy (operator-gated; reversible)

```
powershell -ExecutionPolicy Bypass -File KATABASIS-DEPLOY\sign_and_deploy_floor.ps1
```

It self-elevates (one UAC), confirms test-signing + HVCI-off, makes a System Restore checkpoint, verifies
the byte-hash against the pin, self-signs a copy, repairs the PE checksum, `sc create type=kernel
start=demand`, `sc start` (resident), runs `floor_client.exe`, then `sc stop` (DriverUnload) + `sc delete`.
SUCCESS = `sc start` exit 0 + the client's `[npt-intercept] … => PASS` and the full chain green.

**Safety envelope:** `start=demand` ⇒ never boot-loaded (a worst-case bugcheck is fixed by one normal
reboot); the driver is resident only between load and stop (seconds); SVM is enabled only transiently on a
pinned core and disabled before each IOCTL returns; all guests are disposable. **Recovery:** reboot, then
`… sign_and_deploy_floor.ps1 -Uninstall` (removes the service + test cert + signed copy).

## 5. `\\.\IIIKatabasisFloor` IOCTL map (gate_floor.sys)

| code | name | effect | output |
|---|---|---|---|
| `0x222000` | FLOOR_PROBE | read SVM capability (read-only) | svm, EFER, VM_CR, ECX |
| `0x222004` | SVM_DISABLE | WRMSR-EFER teardown primitive (no-op while SVME=0) | EFER before/written/after |
| `0x222008` | SVM_HOSTMODE | enable SVM + region + VM_HSAVE_PA, fully reversed | EFER 0x4d01→0x5d01→0x4d01, region |
| `0x22200C` | VMCB_BUILD | build the VMCB+NPT+guest, read back, free (no VMRUN) | 11 VMCB fields + phys |
| `0x222010` | SVM_VMRUN | build → VMRUN a disposable guest → teardown | exitcode (0x81), guest RIP |
| `0x222014` | GATE_AT_VMEXIT | VMRUN → run the full gate on the exit (6-tuple req in) | exitcode, verdict |
| `0x222018` | GATE_LOOP | adjudicate → write verdict → resume; guest echoes it | exitcode, verdict, echoed |
| `0x22201C` | NPT_INTERCEPT | mark code page not-present → catch NPF → map → resume | iter, faulting GPA, NPF, VMMCALL, phys |

Input for the gate IOCTLs (6×u64): `family, target_kind, target, action_hexad, cap_rights, seal_mode`.

`\\.\IIIKatabasisGate` (gate_ioctl.sys): `0x222000` IOCTL_KATABASIS_ADMIT (the gate decision),
`0x222004` IOCTL_SVM_PROBE (the I0 read-only probe).

## 6. Source map

`src/floor_abi.s` — the floor's hand-asm shims (Io device + cpuid/rdmsr/wrmsr + per-core pin + Mm contiguous
+ build_vmcb + svm_vmrun + vmrun_once + write_guest_loop + IRQL). `src/gate_floor.iii` — the cg_r0 driver
(dispatch + the I0→I4 handlers + the extracted `floor_gate_loop`/`floor_npt_loop`). `src/kernel_abi.s` +
`src/gate_driver.iii` — the Tier-3 gate. `src/gate_resident.iii` — the Tier-2 selftest. `src/witness_kernel.s`,
`src/cpufeat_kernel.iii` — the kernel leaf + the scalar-crypto-forcing shim.

## Purged build litter (reunification W7.1, 2026-07-02)

Two one-shot Python analysis tools were removed under the no-Python law; their findings are
long-committed and their outputs frozen:
- `build/decode_rm1_hv.py` — decoded cg_rm1.iii's RM1_HV_* asm-text arrays to diff against the
  Phase-0 CHARIOT sequence; the cg_rm1 port to `.iii` is complete, so the decoder is retired.
- `build/stackdepth.py` — one-shot kernel stack-depth bound from `objdump -dr` over the linked
  `.o` set; the gate_resident bound it computed is baked into the resident selftest.
Also removed: 26 session `build/*.log`, `build/obj/` intermediates, and 4 regenerable client exes
(floor_client, gate_client, quine_attest_check, quine_attest_client) — all reproduced by the gates.
