# KATABASIS Ring −1 — Milestone Record (I0 → I4, proven on metal)
> **STATUS: HISTORICAL RECORD** — an executed campaign plan/ledger, kept immutable as evidence (reunification W6).

> The polished record of III's descent into Ring −1 of live Windows. The working log is
> `DOCS/RING-MINUS-1-LEDGER.md`; the proven SVM recipe is `DOCS/SVM-CONSTANTS-HARVEST.md`; the
> reproducible build/deploy guide is `KATABASIS-DEPLOY/README.md`. This file is the synthesis: what was
> achieved, how, the proof, the honest status, and the boundary not crossed.
>
> Machine: ASUS Zephyrus Duo — AMD Ryzen 9 7945HX (Zen 4), 32 logical CPUs. Windows 11 Pro,
> test-signing ON, HVCI OFF. All work on the operator's own machine, operator-gated by UAC, reversible.

---

## 1. The claim, precisely

III — a sovereign, NIH language whose Ring-0 backend `cg_r0` emits PE32+ native drivers, plus hand-written
ntoskrnl-marshalling assembly shims, with **zero third-party code** (only libc, the III BOOT headers, and
mingw's `libntoskrnl.a` import library) — has, in Ring 0/−1 of **live, running** Windows:

1. detected AMD-V/SVM, enabled it, allocated an NPT-addressable contiguous region;
2. built a complete, byte-correct AMD **VMCB** + nested page tables + a guest;
3. executed **VMRUN** to take the hypervisor seat (Ring −1) and run a guest;
4. run its **full capability + content-address-seal + hexad-admissibility gate decision at the guest's
   VMEXIT**, returning the correct verdict for OK and all three rejections;
5. **adjudicated, written the verdict back, and resumed** the guest, which carried the verdict onward;
6. **intercepted a guest nested page fault**, mapped the page, and resumed the guest transparently.

Every step was demonstrated with a **disposable guest** (a few bytes of throwaway code), so a fault could
only ever lose the throwaway — never the host. Each artifact is byte-verified against its disassembly,
deterministic (reproducible hash), and was loaded only behind the operator's UAC with a System Restore
checkpoint and demand-start (never boot-loaded; worst case is one reboot).

This is the descent — III beneath Windows — **real at Ring 0 (the gate decision) and Ring −1 (the
hypervisor)**, proven on hardware.

---

## 2. Proven silicon ground truth (this 7945HX)

Read in Ring 0 by the I0 probe and re-read by every floor build:

| fact | value | meaning |
|---|---|---|
| `CPUID(0x80000001).ECX[2]` | 1 (ECX=`0x75c237ff`) | AMD-V/SVM present |
| `EFER` (MSR `0xC0000080`) | `0x4d01` = SCE\|LME\|LMA\|NXE\|FFXSR | SVME(b12)=0; the exact bits the teardown WRMSR must preserve |
| `VM_CR` (MSR `0xC0010114`) | `0x8` = SVM_LOCK(b3)=1, SVMDIS(b4)=0 | SVM **enable-capable** — `WRMSR EFER.SVME` will not `#GP` |
| `MmAllocateContiguousMemory(256KB, <4GB)` | virt `0xffffe18…`, phys `0xa9f75000` | <4GB phys → inside the NPT identity range |

Every VMCB/NPT constant came from CHARIOT's working hypervisor (`sma_pe_emit_platform.c` CMD_INIT_SVM),
re-read line-by-line and cross-checked vs the AMD APM vol.2 ch.15 before use (PD-1).

---

## 3. Architecture & doctrine (why it worked the first time)

- **NIH, two-layer.** Cleverness lives in `.iii` (the driver logic, the gate closure); the dumb,
  width-precise, privileged metal lives in hand-asm shims (`floor_abi.s`). `cg_r0` is 8-byte-uniform, so
  anything with packed sub-qword fields (the VMCB) or privileged opcodes (CLGI/VMRUN/WRMSR) is hand-asm,
  byte-identical to CHARIOT's proven sequence.
- **The ladder (one new privileged op per rung).** Each rung added exactly one unproven operation and
  proved it on metal before the next. By the VMRUN rung, *every surrounding primitive was already proven*,
  so the riskiest instruction was tested in maximal isolation.
- **Disposable-guest-first [PD-0].** Every guest is a throwaway (`vmmcall;hlt` or `mov;vmmcall;vmmcall`).
  The *mechanism* (VMRUN, gate, resume, NPT-intercept) is de-risked completely without ever pointing it at
  the live OS.
- **Teardown-first [PD-4].** The SVM-disable path was written and proven (as a safe no-op) before the
  enable path existed.
- **Every byte gated [PD-2].** Each `.sys` is disassembled and every privileged field/opcode checked vs
  CHARIOT + the AMD APM, and the deterministic hash is pinned in the deploy script, before any load.
- **Operator-gated + reversible [PD-3].** Demand-start, test-signed, System Restore checkpoint, self-
  unloading; the kernel-load trigger is always the operator's UAC.
- **The gate fusion.** The same `katabasis_gate_admit` closure proven in Ring 0 (Tier-2/3) runs at the
  Ring −1 VMEXIT — the two halves of KATABASIS made one.

---

## 4. The rungs (each proven on metal)

All in the isolated `gate_floor.sys` (separate from the proven `gate_ioctl.sys`), via IOCTLs on
`\\.\IIIKatabasisFloor`. Hashes are the final deterministic build for that rung.

| rung | IOCTL | proves | key verification |
|---|---|---|---|
| **I0** probe | `0x222000` | SVM present + usable | VM_CR read gated behind the SVM CPUID bit → no `#GP` on non-SVM CPUs |
| **#19a** teardown | `0x222004` | first privileged `WRMSR EFER` + per-core pin | no-op write (`0x4d01→0x4d01`), `cleared-bit12-only` |
| **#19b** host-mode | `0x222008` | enable SVM + region + VM_HSAVE_PA, fully reversed | EFER `0x4d01→0x5d01→0x4d01`, region phys <4GB |
| **#19c-i** VMCB | `0x22200C` | build a CHARIOT-correct VMCB (memory-only) | every field read back == CHARIOT (incl. PD flag `0xE7`, the 4 harvest corrections) |
| **I2** VMRUN | `0x222010` | run a disposable guest in Ring −1 | `EXITCODE=0x81` (VMMCALL), guest RIP = phys+0xA000 |
| **I3-i** gate@VMEXIT | `0x222014` | the full gate decides at the VMEXIT | 4/4 verdicts (OK/SEAL/CAP/HEXAD) |
| **I3-ii** resume-loop | `0x222018` | adjudicate → write verdict → resume; guest echoes it | echo==verdict 4/4 (the I5 loop) |
| **I4** NPT-intercept | `0x22201C` | mediate guest memory | `NPF=0x400`, mapped, resumed, guest ran; faulting GPA byte-exact |

Final `gate_floor.sys` (all IOCTLs): `129cc06d…`. Stack acyclic, peak 11.5 KiB / 24 KiB. Imports: ntoskrnl
only (Io×5, Ke×4, Mm×3). Build: `KATABASIS-DEPLOY/build_gate_floor.sh`; deploy: `sign_and_deploy_floor.ps1`.

Tier-2 (`gate_resident.sys`, the gate decision resident in Ring 0) and Tier-3 (`gate_ioctl.sys`, the
R3-invokable gate over DeviceIoControl) were proven on metal earlier; this milestone is the Ring −1 floor.

---

## 5. The §0.6 three-way brick closure — all three mechanisms proven

The descent's safety thesis: the brick-class operations (e.g., a write to the SVM HSAVE area) that can
permanently wedge a machine are closed three independent ways. As of I4, each *mechanism* is proven:

1. **Hexad-unrepresentable.** The gate refuses brick-class actions: their hexad is non-reachable, so the
   gate returns REJECT_HEXAD. Proven in Ring 0 (Tier-2/3) **and at the Ring −1 VMEXIT** (I3-i, the
   `REJECT_HEXAD` case = an HSAVE-brick target).
2. **Rehearsed-in-guest.** Dangerous operations are rehearsed in a disposable guest before the live OS
   would do them. I2–I4 *are* that rehearsal, end to end.
3. **NPT-CoW-reversible.** Guest memory writes are interceptable and therefore reversible. I4 proved the
   interception primitive (catch NPF → decide → map/copy/observe → resume); CoW is its direct extension.

I5 (live bluepill) would *compose* these three; their mechanisms are now individually de-risked.

---

## 6. Honest status — proven vs designed

**PROVEN ON METAL:** the gate decision in Ring 0 (Tier-2); the R3-invokable gate (Tier-3); the entire
Ring −1 capability ladder I0→I4 with disposable guests; the three brick-closure mechanisms.

**DESIGNED, NOT BUILT:** I3-iii (guest supplies its own request), the full VMCB diag-copy, multi-core SVM
(Chunk B will build these — still disposable-guest).

**DELIBERATELY GATED, UNTOUCHED:** **I5 — bluepilling the live OS.** It is categorically different from
every rung above: it points the proven mechanism at *running Windows itself* (the §0.6 brick-RISK), not a
disposable guest. Per [PD-0] it requires the operator's **explicit decision** and the three-way closure
**composed**. The disposable-guest ladder existed precisely to de-risk I5's mechanism first — and now has —
but I5 is not approached without that explicit go. Chunk C designs its safety architecture; it does not
execute it.

---

## 7. Reusable findings (paid forward)

- **CHARIOT-harvest corrections (caught by re-reading the source before #19c).** NPT PD-leaf flag is `0xE7`
  not `0xB7`; IOPM_BASE@0x040 / MSRPM_BASE@0x048 / TLB_CONTROL@0x05C were missing; the guest is 32-bit
  protected, NO paging (CR0=0x11, CR3=0, CR4=0), not "host CR0/3/4"; CS attr `0x0C9B` (code) ≠ `0x0C93`
  (data). Building from the un-corrected harvest would have produced a wrong VMCB. `TLB_CONTROL=1` later
  became the linchpin of I4 (flushes the NPT so a re-map takes effect).
- **cg_r0 traps.** (a) No `EXPR_CAST` / incomplete fail-loud caused two early BSODs — fixed by total error
  propagation. (b) **Per-function local-slot LIMIT**: a large function (`floor_ioctl` with 6+ IOCTL
  branches) overflows it and spills the latest locals to *global* refs (link error
  `undefined reference L_p_<local>`); fix = extract large handlers into their own functions. (c) The VMCB's
  packed dword fields cannot be written by cg_r0's 8-byte-uniform stores → hand-asm.
- **The verdict round-trips through the VMCB RAX slot, not shared memory** — because a paging-off guest
  can't address the runtime-varying `region_phys`; the VMCB state-save that VMRUN already manages carries it.

---

## 8. Reproducibility

See `KATABASIS-DEPLOY/README.md` for the exact rebuild → disasm-verify → operator-gated deploy procedure
for `gate_floor.sys` (the floor), `gate_ioctl.sys` (Tier-3), and `gate_resident.sys` (Tier-2), plus the
IOCTL map and the safety envelope. Every build is deterministic; every hash is pinned in its deploy script.
