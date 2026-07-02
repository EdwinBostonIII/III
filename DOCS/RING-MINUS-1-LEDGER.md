# Ring −1 LEDGER — living log of refinements, enhancements, safety means, certainty means
> **STATUS: HISTORICAL RECORD** — an executed campaign plan/ledger, kept immutable as evidence (reunification W6).

> Companion to `DOCS/RING-MINUS-1-PLAN.md`. Every refinement to the plan, every enhancement
> opportunity, every safety mechanism, and every certainty/verification mechanism is recorded here
> as it is discovered — dated, sourced, and tagged. Nothing is lost between increments.
> Tags: **[R]** refinement · **[E]** enhancement opportunity · **[S]** safety means ·
> **[C]** certainty/verification means · **[Q]** open question / decision pending.

---

## Standing principles (from the plan doctrine PD-0..6)
- [S] PD-0 disposable-guest-first — the live OS is never virtualized before I5.
- [S] PD-4 teardown-first — the SVM-disable path is written + disasm-verified before the enable path is ever run.
- [S] PD-3 operator-gated, demand-start, reboot-recoverable; the load trigger stays with the operator.
- [S] PD-5 fault-as-data — every VMEXIT → diagnostic ring; host never trusts guest state.
- [C] PD-1 proven-numbers-only — every constant sourced to CHARIOT (this 7945HX) AND cross-checked vs the AMD manual.
- [C] PD-2 every-byte-gated — disasm byte-equality vs CHARIOT + the Aegis machine-code rule set, before any load.
- [C] PD-6 determinism + witness — emitted HV byte-reproducible; mhash runtime self-attest.

## Discovered during exploration (2026-05-23)
- [R1] The VMRUN bracket should live in the **Ring-0 loader as a hand-asm shim** (auditable privileged loop,
  `kernel_abi`-style) for I0–I4, not inside the cg_rm1 PIC module — cg_rm1 *emits* a bracket but the
  privileged loop is safest as validated hand-asm we control byte-for-byte. (Decision pending confirm: [Q1].)
- [E1] **Aegis rule registry → III predicates** over the disassembly (harvest T17) — automate the
  crash-protocol's manual machine-code checks (CLGI_STGI_PAIRED, VMRUN_BRACKETED, ASID_NONZERO, …).
  Highest-value transfer for this work; build it as the I1 gate.
- [E2] The Tier-3 **IOCTL gate is the control plane** — Ring −1 = new IOCTLs on `\\.\IIIKatabasisGate`
  (SVM_PROBE / VMRUN_THROWAWAY / HV_TEARDOWN). R3 orchestrates, kernel executes, gate observes.
- [E3] The gate decision (`katabasis_gate_admit`) is the Ring −1 **payload** — VMEXIT → run the gate at R−1.
- [S5] cg_rm1's **emit-time guards** (`rm1_sym_is_permitted` / `RM1_E_FORBIDDEN_TARGET` / `RM1_E_ONEWAY_READ`
  / `RM1_E_NON_PIC_RELOC`) already refuse forbidden targets + non-PIC relocs at codegen — keep + lean on them.
- [S6] cg_rm1 emits **PXOR xmm0..15 volatile-clear** — FP/vector-state hygiene across the VMRUN boundary.
- [S7] **VM_CR.SVMDIS / SVM_LOCK precheck** — never WRMSR EFER.SVME if SVM is locked-disabled (would #GP / wedge).
- [C1] **Byte-equal vs CHARIOT proven** opcodes (VMRUN=0F01D8, VMSAVE=0F01DB, VMLOAD=0F01DA, CLGI=0F01DD, STGI=0F01DC).
- [C4] cg_rm1's **mhash placeholder** → runtime `.text` self-attestation (harvest T3).

## Open questions / decisions
- [Q1] VMRUN bracket: loader-hosted hand-asm (lean: yes, for I0–I4) vs cg_rm1-module. Resolve in Phase 0 by
  decoding cg_rm1's `RM1_HV_SVM_VMRUN_BRACKET` and judging auditability.
- [Q2] Guest GPR save/restore around VMRUN: VMRUN only round-trips RAX/RSP/RIP via the VMCB; the host must
  push/pop the other 13 guest GPRs itself. Confirm which side (cg_rm1 bracket or loader) does it. (CHARIOT proven.)
- [Q3] Contiguous-memory ceiling: MmAllocateContiguousMemory highest-acceptable-address for the VMCB/NPT
  (must be addressable by the SVM phys-addr fields). Confirm CHARIOT's value.

## Phase 0 findings (proven SVM constants) — DONE → DOCS/SVM-CONSTANTS-HARVEST.md + STDLIB/iii/katabasis/svm_const.iii
The COMPLETE proven recipe is captured (CHARIOT `sma_pe_emit_platform.c` CMD_INIT_SVM:1047-1407 +
`sma_x64_emit.c` opcodes + `test_platform_svm.c` proof, all cross-checked vs AMD APM vol 2 ch.15).
New entries this phase:
- [Q2 RESOLVED] The proven VMRUN bracket is `mov rax,vmcb_phys; CLGI; VMSAVE; VMRUN; VMLOAD; STGI`
  with **NO explicit guest-GPR save/restore** — correct *only because* the throwaway VMMCALL guest
  inherits the host GPRs at VMRUN, executes one VMMCALL (touches no GPR), and exits, so r14/r15
  survive. **A full/long-running guest (I5) MUST add the 13-GPR push/pop around VMRUN.** Pinned to I2.
- [S8] SVM is **per-core**. CHARIOT's CLEANUP_SVM does `KeIpiGenericCall` to disable on ALL cores.
  III must **pin the thread to one core** (`KeSetSystemAffinityThread`) for enable→VMRUN→disable, OR
  IPI-teardown. Pinning is simplest + safest for I2 (enable, VMRUN, disable all on the same core).
- [S9] **Guest VMCB EFER.SVME (0x4D0 = 0x1000) MUST be set** or VMRUN → VMEXIT_INVALID (APM 15.5.1).
  A proven gotcha; svm_const.iii pins `SVM_VMCB_EFER_SVME = 0x1000`.
- [S7→exact] VM_CR (`0xC0010114`) precheck before enabling: bit 4 SVMDIS + bit 3 SVM_LOCK. If
  SVMDIS=1 & SVM_LOCK=1 → BIOS-disabled → WRMSR EFER.SVME would #GP → must refuse (I0 reports this).
- [C6] cg_rm1's NPT PD flag `0xB7` is **byte-identical** to CHARIOT's proven 2 MB-page entry — the
  FIRST confirmed cg_rm1↔CHARIOT match. Strengthens "validate-not-invent."
- [E4] The diagnostic VMCB copy (control 1024 B + state-save 512 B → region+0x3F000 via rep movsq) is
  the fault-as-data forensic capture (PD-5) — adopt it verbatim in the III loader.
- [Q4] Single-source mechanism for `svm_const.iii` → the (cg_r0) loader: re-declare-with-cite vs
  Forge-generate vs same-module. Decide at the loader-skeleton increment (#19).
- [Q5] `INTERCEPT_MISC1 = 0x9906000F` (0x00C) — confirm the exact bit meanings vs APM appendix B
  before the live-OS bluepill (for the throwaway guest, the 0x010=0x3F SVM-instr intercepts are what
  matter; MISC1 governs INTR/NMI/IO/MSR/etc., over-broad-is-safe for a contained guest).

## I1 findings (decode + diff cg_rm1 HV emission vs CHARIOT proven) — decoder: KATABASIS-DEPLOY/build/decode_rm1_hv.py
- [C7 — CRITICAL] **cg_rm1's `RM1_HV_SVM_VMRUN_BRACKET` DIVERGES from CHARIOT proven + is incorrect for
  a Windows-host HV.** cg_rm1 emits `pushq rbx; rbx=rdi(host); rax=rsi(guest); clgi; vmload rbx; vmrun rax;
  vmsave rbx; stgi; popq rbx; ret`. CHARIOT proven = `mov rax,vmcb; clgi; vmsave rax; vmrun rax; vmload rax;
  stgi`. Problems: (1) **order inverted** — cg_rm1 vmload-before/vmsave-after vs proven vmsave-before/vmload-
  after; (2) it `vmload`s the host area before anything `vmsave`d it → loads UNINITIALIZED FS/GS/TR (the
  per-thread regs Windows depends on); (3) it never restores host extra-state AFTER the guest → host resumes
  with the guest's FS/GS/TR → wedge; (4) **SysV ABI (rdi/rsi)**, not Win64. The `RM1_HV_BARE_METAL_ENTRY`
  (`iii_hv_entry`, `leaq __iii_hv_stack_top(%rip),%rsp`, `jmp iii_hv_main`) confirms cg_rm1 targets a
  **bare-metal / Linux** Ring −1, NOT a Windows-kernel-loaded HV.
- [R3 — ARCHITECTURE] The **Windows Ring −1 path** (`gate_floor.sys`, loaded by Windows like `gate_ioctl.sys`)
  uses a **cg_r0 loader + Win64 hand-asm shims that host CHARIOT's PROVEN bracket** (`clgi; vmsave guest;
  vmrun guest; vmload guest; stgi`, Win64), NOT cg_rm1's bracket/entry. cg_rm1's reusable parts for the
  Windows path: the **NPT data** ([C6] byte-match) and (later) the **gate-at-R−1 logic**; its privileged
  bracket + bare-metal entry are NOT used. cg_rm1's bracket is filed for a separate fix (align to proven +
  add the host-restore vmload + Win64) IFF a bare-metal Ring −1 is later pursued. [R1]/[R2] now firmly decided.
- [S12] The PD-2 disasm-vs-proven gate **CAUGHT cg_rm1's wrong-ABI, host-corrupting bracket before any load** —
  the paranoid gate functioning exactly as designed. "cg_rm1 emits ~80% of it" is REFINED: cg_rm1 emits the
  *structure for a bare-metal target*; the Windows path takes only its NPT data + (later) gate logic, and owns
  every privileged byte itself, validated == CHARIOT.
- [E5] cg_rm1's CPUID dispatch is correct + reusable: VMX = CPUID(1).ECX[5], SVM = CPUID(0x80000001).ECX[2]
  — matches svm_const.iii; lift the logic for I0 (the capability probe).
- [C8 pending] still to decode/diff: cg_rm1's NPT PD bytes already confirmed [C6]; the VMEXIT-table + the
  VMX bracket are bare-metal-targeted too → not on the Windows critical path; defer their diff.

## I0 findings (read-only SVM capability probe) — built + byte-verified 2026-05-23
Implemented as two hand-asm shims in `kernel_abi.s` (`iii_kio_cpuid`, `iii_kio_readmsr`) + one IOCTL
branch (`IOCTL_SVM_PROBE = 0x222004`) in `gate_driver.iii`, on the EXISTING gate device. R3 reads it
via the extended `gate_client.exe`. No SVM enable, no VMRUN — pure capability read.
- [S13 — SAFETY, PROVEN IN MACHINE CODE] The AMD-only `VM_CR` (`0xC0010114`) RDMSR is gated behind the
  SVM CPUID bit so it can NEVER `#GP` on a non-SVM CPU. Disasm proof (gate_driver.o):
  `755: cmp rax,rcx` / `761: test rax,rax` / `764: je 788` / `766: movabs rax,0xc0010114` /
  `777: call iii_kio_readmsr` — the VM_CR read sits AFTER the `je 788`, so `svm_avail==0` jumps past it.
  `EFER` (`0xC0000080`, `70b`) is read unconditionally — universal on x86-64, always safe. RDMSR of an
  invalid MSR `#GP`s → bugchecks; this gate makes that structurally impossible. (CPUID can't fault.)
- [C9 — CERTAINTY] I0 byte-gated (PD-2): `gate_ioctl.sys` deterministic hash
  `a9dc84031cf29237408274eb2e337077674a3588d6bdef9cdc3d2650cacfb727` (was `338d0d5a` pre-probe; pinned in
  `sign_and_deploy_ioctl.ps1`). Shim opcodes verified: `cpuid=0f a2`, `rdmsr=0f 32`, `shl rdx,0x20`,
  `push rbx` (CPUID clobbers RBX → saved). Handler verified: `222004` compare → `cpuid(0x80000001)` →
  mask/shift → EFER read → `svm_avail==1` gate → VM_CR read. Client builds clean (PE32+).
- [E6 — ENHANCEMENT] The probe is now a PERMANENT capability of the gate device — the [E2] control plane
  gains ground-truth capability reporting; R3 can query SVM status before ANY privileged increment.
- [R4 — REFINEMENT] I0 extends the EXISTING gate (plan §3) not a new driver: minimal surface, reuses the
  proven Io shims, read-only → safe to co-reside with the proven gate. The DANGEROUS increments (I2+ SVM
  enable / VMRUN) get the dedicated, isolated `gate_floor.sys` (#19) per [R3]. Probe-in-gate ≠ HV-in-gate.
- [Q6 — RESOLVED-ON-DEPLOY] Whether SVM is currently BIOS-ENABLED on this 7945HX (SVMDIS/SVM_LOCK) is an
  empirical unknown CHARIOT's old runs don't settle (firmware may have changed). I0's deploy ANSWERS it:
  the client prints SVMDIS/SVM_LOCK + a PROCEED/BLOCKED verdict. This is the gate to I2 — I2 must not run
  if SVMDIS&SVM_LOCK. Deploy is operator-gated (UAC); the .sys + client are deploy-ready (hash pinned).

## I0 METAL PROOF (2026-05-23, operator ran sign_and_deploy_ioctl.ps1, UAC accepted)
`sc start` exit 0 (STATE RUNNING, resident, no crash); gate 4-case still 4/4 PASS (a9dc8403 rebuild
clean); `sc stop` DriverUnload clean. The probe read, in Ring 0 of live Windows:
- **SVM present: YES** — CPUID(0x80000001).ECX = `0x75c237ff`, bit 2 = 1.
- **EFER = `0x4d01`** = SCE(b0)|LME(b8)|LMA(b10)|NXE(b11)|FFXSR(b14); **SVME(b12)=0** (SVM not yet enabled).
  → [C10] the EXACT preserve-mask for #19's teardown: enable ⇒ `0x4d01|0x1000=0x5d01`; teardown ⇒
  `&~0x1000` back to `0x4d01`, demonstrably keeping long mode (LME/LMA) + NXE + FFXSR. No longer a guess.
- **VM_CR = `0x8`** = SVM_LOCK(b3)=1, **SVMDIS(b4)=0** → [C11] SVM is **enable-capable**: WRMSR EFER.SVME
  will NOT #GP. State is "locked-ENABLED" (firmware enabled SVM + locked SVMDIS at 0 — the ideal config;
  the only blocking config is SVMDIS=1&SVM_LOCK=1).
- [Q6 ANSWERED — GREEN] The metal can host Ring −1. The proven-numbers gate to I2 is OPEN.
- [R5 — REFINEMENT] client wording "not BIOS-locked" is loose (SVM_LOCK IS 1); precise = "locked-ENABLED,
  SVM usable." Verdict logic correct (only SVMDIS&LOCK blocks). Tighten the print when next touching the client.

## #19 → I2 GRANULAR DECOMPOSITION (deep-think, proven-numbers-derived)
The dangerous Ring −1 work lives in a NEW, ISOLATED driver `gate_floor.sys` [R3]/[R4] (a wedge there
never touches the proven gate_ioctl.sys). Built teardown-first (PD-4), one dangerous primitive per rung,
each metal-verifiable + reversible:
- **#19a (THIS rung) — loader skeleton + the teardown primitive.** floor device + dispatch + unload; new
  shims `iii_kio_writemsr` (WRMSR — the first privileged WRITE), `iii_kio_pin_core`/`_unpin_core`
  (KeSetSystemAffinityThreadEx/KeRevertToUserAffinityThreadEx — [S8] SVM is per-core). IOCTL_SVM_DISABLE
  = pin core → rdmsr EFER → `&~0x1000` → wrmsr EFER → unpin → report old/new EFER. **Safe NO-OP now**
  (SVME already 0 ⇒ writes 0x4d01→0x4d01, can't change anything ⇒ can't wedge) — proves the WRMSR+pin
  path + the exact RMW mask BEFORE any enable. Re-probe IOCTL confirms the floor reads the same numbers.
- **#19b — contiguous SVM region + ENABLE + VMCB build, NO VMRUN.** MmAllocateContiguousMemory(256KB,
  highest=0xFFFFFFFF) + MmGetPhysicalAddress; SVM-enable (WRMSR EFER|=0x1000 → expect 0x5d01 read-back;
  WRMSR VM_HSAVE_PA=hostsave_phys); build the VMCB + NPT identity map per the CHARIOT-proven recipe
  (SVM-CONSTANTS-HARVEST.md), byte-gated vs CHARIOT (PD-2). STOP before VMRUN — prove enable↔disable
  round-trips (0x4d01→0x5d01→0x4d01) on metal without running a guest. Region freed on teardown.
- **#19c / I2 — the VMRUN moment.** The loader-hosted Win64 bracket `mov rax,vmcb_phys; CLGI; VMSAVE rax;
  VMRUN rax; VMLOAD rax; STGI` (CHARIOT-proven order, [C7] NOT cg_rm1's). One-VMMCALL throwaway guest
  ([Q2-RESOLVED] no GPR save/restore needed for it); on VMEXIT read VMCB.EXITCODE@0x070, expect
  0x81 (VMMCALL); diag-copy the VMCB (PD-5 [E4]); teardown. The first contained Ring −1 moment.
- [S14] every rung: pin core for the whole enable→…→disable window (per-core SVM state); operator-gated
  load; reboot-recoverable (demand-start); teardown path proven before the matching enable.

## #19a BUILT + BYTE-VERIFIED (2026-05-23) — gate_floor.sys deploy-ready, awaiting operator metal proof
The isolated floor driver (NEW, separate from gate_ioctl.sys). Files: src/floor_abi.s (floor Io shims +
the 3 privileged shims), src/gate_floor.iii (driver), build_gate_floor.sh, src/floor_client.c,
sign_and_deploy_floor.ps1. **gate_floor.sys deterministic sha256
`fb4d2883d5e136575e65af465d6a18d9a575f4b818f1c624381374dd4e3cd502`** (hash-pinned in the deployer).
- [C12 — CERTAINTY, PD-2] Every dangerous byte verified in machine code:
  - WRMSR shim opcode `0f 30`; value→EDX:EAX split byte-perfect (`mov rax,rdx`→EAX=lo; `mov r8,rdx;
    shr r8,0x20; mov edx,r8d`→EDX=hi; `wrmsr`). cpuid `0f a2`, rdmsr `0f 32` (copies of the I0 shims).
  - SVM-DISABLE handler order: `pin_core(1)` → `readmsr(EFER 0xc0000080)` → mask `movabs 0xffffffffffffefff`
    (clears ONLY bit 12) → `writemsr(EFER)` → `readmsr(EFER)` → `unpin_core`. The mask preserves
    LME/LMA/NXE/FFXSR/SCE → long mode never disturbed.
  - PROBE branch: VM_CR (0xc0010114) gated behind a `je` on svm_avail (same [S13] as I0).
  - DriverEntry: `create_device(drv,&G_FDEVOBJ)` + 4 dispatch stores PROVEN `[driver_object + i*8]=&handler`
    for i=13/14/16/28 (movabs 0xd/0xe/0x10/0x1c → offsets 0x68 DriverUnload / 0x70 CREATE / 0x80 CLOSE /
    0xE0 DEVICE_CONTROL) + `create_symlink`. Stack-machine push/pop is verbose but correct (== gate pattern).
  - Imports: ntoskrnl.exe ONLY — Io{Create,Delete}{Device,SymbolicLink}, IoCompleteRequest,
    KeSetSystemAffinityThreadEx, KeRevertToUserAffinityThreadEx. PE32+ native, entry=DriverEntry.
  - Call graph ACYCLIC (no recursion; all calls → leaf shims/accessors/witness-leaf, 18 witness calls);
    shallow (~3 frames) << 24 KiB.
- [S15 — SAFETY] On THIS machine the disable is a PROVABLE NO-OP: EFER=0x4d01, SVME(b12)=0, so
  `0x4d01 & ~0x1000 = 0x4d01` — WRMSR writes EFER's OWN value ⇒ cannot change processor state ⇒ cannot
  wedge. Pinned to CPU 0. Proves the first privileged WRMSR + the per-core pin path BEFORE any enable.
- [R6 — REFINEMENT for #19b/c] #19a is safe at PASSIVE+affinity-pin (a preemption between rdmsr/wrmsr is
  harmless — no other code writes the core's EFER). But #19b's real ENABLE and #19c's VMRUN window need
  interrupt/preemption protection: VMRUN uses CHARIOT's CLGI/STGI bracket (clears GIF); the enable→VMCB
  setup should also KeRaiseIrql to DISPATCH_LEVEL. Pin to the SAME core enable used (per-core SVM).
- DEPLOY: `sign_and_deploy_floor.ps1` (UAC). Success = `sc start` exit 0 (RUNNING) + floor_client.exe
  prints "teardown primitive PROVEN" (before==written==after EFER, long-mode-intact) exit 0 ⇒ a Ring-0
  WRMSR EFER executed on a pinned core, preserved long mode, machine stayed up. The gate to #19b.

### #19a PROVEN ON METAL (2026-05-23, operator ran sign_and_deploy_floor.ps1, UAC accepted)
`sc start` exit 0 (RUNNING, no crash); clean DriverUnload. floor_client.exe:
`[probe] SVM=1 EFER=0x4d01 VM_CR=0x8 ECX=0x75c237ff` (floor reads the SAME truth as I0 — two independent
drivers agree) and `[disable] EFER before=0x4d01 written=0x4d01 after=0x4d01 / cleared-bit12-only:YES /
no-op:YES / long-mode-intact:YES => PASS`. **A privileged WRMSR EFER executed in Ring 0 on a pinned core,
preserved long mode, no wedge.** The isolated floor loader + the WRMSR + per-core-pin mechanism are proven
on this silicon. Gate to #19b: GREEN.

## #19b/c GRANULAR (refined post-#19a; the dangerous transfer is isolated to the last rung)
- **#19b (THIS rung) — SVM host-mode enter/exit round-trip + contiguous region. NO VMCB, NO VMRUN.**
  New floor shims: `iii_kfo_alloc_contig` (MmAllocateContiguousMemory), `iii_kfo_free_contig`
  (MmFreeContiguousMemory), `iii_kfo_phys_addr` (MmGetPhysicalAddress). IOCTL_SVM_HOSTMODE: alloc 256KB
  (<4GB) → pin core 0 → rdmsr EFER (e0) → **WRMSR EFER|=0x1000 (ENABLE — the first state-changing SVM op;
  expect e1=0x5d01)** → WRMSR VM_HSAVE_PA(0xC0010117)=region_phys+0x1000 → clear VM_HSAVE_PA=0 → WRMSR
  EFER&=~0x1000 (disable; expect e2=0x4d01) → unpin → free. Reports {e0,e1,e2,region_virt,region_phys}.
  Proof: e1=0x5d01 (SVME set), e2=0x4d01 (reversed), region_phys nonzero & <4GB. Reversible, no guest.
  Safe: enable→…→disable on a pinned core, SVM enabled-but-unused for µs; SVMDIS=0 ⇒ no #GP; VM_HSAVE_PA
  set without VMRUN just stores a pointer; reboot-recoverable. [S16] alloc/free at PASSIVE outside the pin;
  SVM ops inside the pin.
- **#19c / I2 — the VMCB build + NPT identity + the VMRUN bracket + the one-VMMCALL throwaway guest.** The
  ONLY rung that transfers control to a guest. CHARIOT-proven Win64 bracket [C7] + VMCB byte-gated vs
  CHARIOT (PD-2). On VMEXIT read EXITCODE@0x070 (expect 0x81 VMMCALL), diag-copy (PD-5 [E4]), teardown.
  [R6] this rung needs CLGI/STGI (GIF mask) + KeRaiseIrql(DISPATCH) around VMRUN, not just affinity-pin.

### #19b BUILT + BYTE-VERIFIED (2026-05-23) — gate_floor.sys re-pinned, deploy-ready
gate_floor.sys deterministic sha256 `927a854fd096a798cc405f25b9a49e24dec2df74f88a023e8f46d664ae2c2bbc`
(was fb4d2883 at #19a). Re-pinned in sign_and_deploy_floor.ps1; floor_client.exe + the deployer header
updated to disclose the transient SVM-enable.
- [C13 — CERTAINTY, PD-2] Every privileged write verified in machine code (objdump -dr):
  - **ENABLE writes `e0 | 0x1000`** — `768 mov [rbp-0x98],rax`(save e0) → `77a` reload → `782 movabs 0x1000`
    → **`78f: or rax,rcx`** → `793 pop rdx`(value=0x5d01) `794 pop rcx`(msr=0xc0000080) → writemsr. It is
    `0x5d01` NOT bare `0x1000` — the catastrophic LME/LMA-clear (triple-fault) is provably absent.
  - **DISABLE ANDs the ENABLED value** — `853 mov rax,[rbp-0xa0]`(hm_e1=0x5d01) → `85b movabs
    0xffffffffffffefff` → **`868: and rax,rcx`** → writemsr(EFER, 0x4d01). Reverses the enable.
  - VM_HSAVE_PA (0xc0010117) = region_phys+0x1000 (`80c add rax,rcx`) then 0 — both gated behind
    `7ea: je 848` (`if hm_rp != 0`). Inert without VMRUN.
  - Mm shims → MmAllocateContiguousMemory (256KB=0x40000, highest=0xFFFFFFFF<4GB) / MmGetPhysicalAddress
    / MmFreeContiguousMemory. Slots distinct (hm_e0@-0x98, hm_e1@-0xa0, hm_rp@-0x88) — no aliasing.
  - Imports ntoskrnl.exe ONLY: Io(5) + Ke(2) + Mm(3). PE32+ native, entry=DriverEntry.
- DEPLOY: `sign_and_deploy_floor.ps1` (UAC). Success = `sc start` exit 0 + floor_client.exe exit 0 with
  the host-mode PASS (EFER 0x4d01→0x5d01→0x4d01, SVME toggled+reversed, long-mode intact, region<4GB) ⇒
  III entered + left AMD SVM host mode in Ring 0 of live Windows, machine up. The gate to #19c/I2 (VMRUN).

### #19b PROVEN ON METAL (2026-05-23, operator deploy)
`sc start` exit 0 (RUNNING); clean unload. floor_client.exe:
`[hostmode] EFER before=0x4d01 enabled=0x5d01 after=0x4d01 / region virt=0xffffe1813320d000 phys=0xa9f95000
/ SVM-enabled(SVME set)=YES long-mode-kept=YES reversed=YES region<4GB=YES => PASS`. **III ENABLED AMD SVM
(SVME=1, EFER 0x5d01) in Ring 0 of live Windows, allocated a 256KB contiguous region at phys 0xa9f95000
(~2.65GB, <4GB), set VM_HSAVE_PA, and FULLY REVERSED — no wedge.** The HOST SIDE of Ring −1 (enable +
region + VM_HSAVE_PA + teardown) is proven on metal. [C14] proven-runtime fact: MmAllocateContiguousMemory
returns a kernel-VA (0xffffe18133…) with a <4GB phys (0xa9f95000) — confirms the alloc strategy; #19c must
compute VMCB/NPT/HostSave phys from MmGetPhysicalAddress at runtime (the addr varies per load), NOT hardcode.
Only ONE rung remains: #19c/I2, the VMRUN moment.

## #19c EVIDENCE PHASE (2026-05-23, re-read CHARIOT sma_pe_emit_platform.c:1088-1410 before building)
Re-reading the proven source against DOCS/SVM-CONSTANTS-HARVEST.md caught MULTIPLE harvest errors — exactly
why PD-1/PD-2 mandate reading the source before the riskiest rung. Harvest now CORRECTED.
- [C15 — CORRECTIONS] (1) **NPT PD-leaf flag is `0xE7`** (P|RW|US|A|D|PS), NOT `0xB7` (line 1311). (2) THREE
  control fields were MISSING: IOPM_BASE@0x040=phys+0xC000, MSRPM_BASE@0x048=phys+0xB000, TLB_CONTROL@0x05C=1
  (all required). (3) **Guest = 32-bit PROTECTED mode, NO paging**: CR0=0x11(PE|ET), CR3=0, CR4=0,
  EFER=0x1000(SVME, LME=0) — FIXED values, NOT "host CR0/3/4" as the harvest wrongly said (lines 1204-1226).
  (4) CS attr=`0x0C9B` (code) ≠ ES/SS/DS `0x0C93` (data) (line 1174). Guest-linear=guest-phys→NPT (no guest
  page tables); RIP=phys+0xA000 works because region<4GB is in the NPT identity range.
- [C6 RETRACTED] cg_rm1's NPT flag `0xB7` does NOT match CHARIOT's proven `0xE7` — the earlier "CONFIRMED
  MATCH" compared against the harvest's wrong value. cg_rm1's emission diverges (reinforces [C7]/[R3]).
- [R7 — ARCHITECTURE] The VMCB has PACKED dword fields (0x008/0x00C/0x010 adjacent; 0x058/0x05C). cg_r0 is
  8-byte-uniform → an 8-byte store to 0x008 would CLOBBER 0x00C. So the VMCB build MUST be a hand-asm shim
  (`iii_kfo_build_vmcb`) transcribing CHARIOT's width-precise movs (dword/word/byte), NOT cg_r0 stores. The
  VMRUN bracket is hand-asm anyway (cg_r0 can't emit CLGI/VMRUN/etc.).

## #19c GRANULAR (the VMRUN rung, split build-then-run)
- **#19c-i (THIS rung) — build the VMCB + NPT + guest code, NO VMRUN. SAFE (only memory writes).**
  `iii_kfo_build_vmcb(region_virt /rcx, region_phys /rdx)` hand-asm: zero the region (256KB [S17], ⊇ CHARIOT's
  4KB) → VMCB control (0x008..0x0C0 per [C15]) → state-save (segments + CR0=0x11/CR3=0/CR4=0/EFER=0x1000/
  RIP=phys+0xA000/RSP=phys+0xAFE0) → NPT (PML4[0]|0x67, PDPT[0..3]|0x67, PD[0..2047]=(i<<21)|0xE7 one loop) →
  guest code 0F 01 D9 F4 @ +0xA000. IOCTL_VMCB_BUILD: alloc → build → READ BACK ~8 critical fields → free.
  Verified BOTH ways: disasm byte-gate (shim's field writes == CHARIOT) AND on-metal readback (the client
  checks INTERCEPT_MISC2/ASID/NP_ENABLE/N_CR3/EFER/CR0/RIP/PD[0]). NO SVM enable, NO VMRUN — cannot wedge.
- **#19c-ii / I2 — add the run.** `iii_kfo_svm_vmrun(region_virt /rcx, region_phys /rdx) -> u64 exitcode`:
  enable (EFER|=0x1000) + VM_HSAVE_PA=phys+0x1000 + the CHARIOT-proven Win64 bracket
  `mov rax,phys; CLGI; VMSAVE; VMRUN; VMLOAD; STGI` (verbatim [C7]; no guest-GPR save needed for the VMMCALL
  guest [Q2]) + read EXITCODE@0x070. .iii handler (pinned): build_vmcb → svm_vmrun → disable → unpin → free.
  Success = EXITCODE 0x081 (VMMCALL) ⇒ the guest ran in Ring −1 and exited cleanly. + diag-copy [E4].

### #19c-i BUILT + BYTE-VERIFIED (2026-05-23) — gate_floor.sys re-pinned `d64739b2`, deploy-ready
[C16 — PD-2] `iii_kfo_build_vmcb` (call-free → no new imports) transcribes CHARIOT 1088-1335; EVERY field
byte-gated in the disasm vs CHARIOT: `0x008`=0xFFFFFFFF, `0x00C`=0x9906000F, `0x010`=0x3F, IOPM=phys+0xC000,
MSRPM=phys+0xB000, ASID=1@`0x058`, TLB_CONTROL=1@`0x05C`, NP_ENABLE=1@`0x090`, N_CR3=phys+0x2000,
VMCB_CLEAN=0; ES/SS/DS sel=0x10/attr=0x0C93, CS sel=0x08/attr=**0x0C9B**; EFER=0x1000@`0x4D0`, CR4=0/CR3=0/
**CR0=0x11**, DR7=0x400, DR6=0xFFFF0FF0, RFLAGS=2, RIP=phys+0xA000, RSP=phys+0xAFE0; PML4|0x67, PDPT[0..3]|
0x67, PD=`(i<<21)|0xE7` (`shl rax,0x15; or rax,0xE7` — the CORRECTED flag), guest code `0F 01 D9 F4`@0xA000.
IOCTL_VMCB_BUILD (0x22200C) builds in a fresh region, reads back 11 fields + region_phys; client verifies
each == CHARIOT-proven. Imports ntoskrnl-only (10). **NO SVM enable, NO VMRUN — memory-only, cannot wedge.**
Deploy-ready (operator UAC). The VMCB construction is proven correct BEFORE the run; only #19c-ii remains.

### #19c-i PROVEN ON METAL (2026-05-23, operator deploy)
`[vmcb] region_phys=0xa9f95000 / INTERCEPT_EXC=0xffffffff MISC1=0x9906000f MISC2=0x3f ASID=1 TLB=1 NP=1 /
N_CR3=0xa9f97000(=phys+0x2000) EFER=0x1000 CR0=0x11 RIP=0xa9f9f000(=phys+0xA000) / PML4[0]=0xa9f98067
(=(phys+0x3000)|0x67) PD[0]=0xe7 guestcode=0xf4d9010f => PASS`. **III built a complete CHARIOT-correct VMCB
in Ring 0** — every field (incl. the 4 corrected harvest values) verified by readback on metal. The VMCB
construction is PROVEN. The only unproven operation left in the entire descent is the VMRUN instruction.

### #19c-ii BUILT + BYTE-VERIFIED (2026-05-23) — gate_floor.sys re-pinned `42fe1ec6`, deploy-ready — THE VMRUN
[C17 — PD-2] `iii_kfo_svm_vmrun` (call-free → no new imports) transcribes CHARIOT 1338-1393 BYTE-IDENTICAL,
verified in disasm: enable `mov ecx,0xC0000080; rdmsr; or eax,0x1000; wrmsr`; VM_HSAVE_PA `lea rax,[r14+
0x1000]; shr rdx,32; mov ecx,0xC0010117; wrmsr`; bracket `mov rax,r14; clgi(0f01dd); vmsave(0f01db);
vmrun(0f01d8); vmload(0f01da); stgi(0f01dc)`; EXITCODE `mov rax,[r15+0x70]`. r14=phys/r15=virt SURVIVE VMRUN
(the VMMCALL guest touches no GPR — CHARIOT relied on the same). IOCTL_SVM_VMRUN (0x222010): alloc →
build_vmcb → pin core 0 → svm_vmrun → read EXITINFO1@0x078 + guest RIP@0x578 → disable EFER (&~0x1000) +
clear VM_HSAVE_PA → unpin → free → report {exitcode, exitinfo1, rip, phys}. Imports ntoskrnl-only (10).
**Every preceding piece is independently proven on metal** (VMCB build #19c-i, enable/disable #19b, region
#19b); the bracket is CHARIOT-proven byte-identical → the VMRUN instruction is the ONE new operation under
test. Success = EXITCODE `0x081` (VMEXIT_VMMCALL); `0xFFFF...FFFF` = VMEXIT_INVALID (VMCB rejected). The
guest is confined by NPT, CLGI-masked, on a pinned core, fully torn down, reboot-recoverable. Operator UAC.
This is the I5-exclusion boundary respected: a DISPOSABLE guest (PD-0), NOT the live OS bluepilled.

## ★ I2 PROVEN ON METAL (2026-05-23) — III HELD THE HYPERVISOR SEAT IN RING −1
`sc start` exit 0; clean unload. floor_client.exe full run:
`[vmrun] EXITCODE=0x81 (VMEXIT_VMMCALL) EXITINFO1=0x0 / guest RIP(post-#VMEXIT)=0xa9f9f000 (=phys+0xA000)
region_phys=0xa9f95000 => PASS`. **III — code it emitted from .iii (cg_r0) + hand-asm shims, NIH,
ntoskrnl-only, byte-verified, deterministic — enabled AMD-V, built a VMCB, executed VMRUN to enter Ring −1
as a hypervisor, ran a disposable guest (one VMMCALL), fielded VMEXIT_VMMCALL, and tore SVM down — all in
Ring 0/−1 of live Windows, no wedge.** The guest RIP landing exactly on phys+0xA000 confirms it ran where
the VMCB directed, NPT-confined. The FULL Ring −1 round-trip (host-setup → VMRUN → guest → #VMEXIT →
host-resume → teardown) is proven on this 7945HX with III-emitted code. The Ring −1 increment ladder
I0→#19a→#19b→#19c-i→I2 is COMPLETE.

## DEEP-THINK (2026-05-23, post-I2): what is proven, and the path beyond
**(1) The precise claim.** III can take the hypervisor seat (Ring −1) under live Windows, run a guest, and
field its exits — proven with a CONTAINED, DISPOSABLE guest. The descent is real at both Ring 0 (gate
decision, Tier-2/3) and Ring −1 (I2). NOT yet: gate-at-VMEXIT (I3), NPT memory interception (I4), live-OS
bluepill (I5, gated).
**(2) Why the ladder worked first-try.** One new privileged op per rung, each metal-proven before the next,
teardown proven before enable (PD-4) → at I2 the VMRUN was the ONLY unproven operation, tested in maximal
isolation. The evidence-first re-read of CHARIOT (PD-1/PD-2) caught 4 harvest errors pre-build; the #19c-i
on-metal readback proved the VMCB field-perfect before the run. The hand-asm-shim split ([R7]) kept every
privileged byte == CHARIOT.
**(3) The mechanism/target separation (the core safety insight).** I2 (disposable guest) and I5 (live-OS
bluepill) share the VMRUN MECHANISM but differ in the TARGET: I2's guest is a throwaway (nothing to lose);
I5's "guest" is all of Windows. I2 de-risks the MECHANISM before it is ever pointed at the live OS. This is
why disposable-guest-first (PD-0) is correct: prove VMRUN safe in isolation, defer the dangerous target.
**(4) I3 — the natural next rung (gate-at-Ring−1).** Replace the trivial VMEXIT handler (read EXITCODE) with
a dispatch that RUNS katabasis_gate_admit on the exit → the VMEXIT becomes a gate-cycle. Fuses Tier-2/3 (the
gate, proven) with I2 (Ring −1, proven). Still a disposable guest; the gate is pure compute in the host
context (no new privileged op). New work: a VMEXIT dispatch loop + guest-resume (advance guest RIP past the
VMMCALL via nRIP/+3 before re-VMRUN) vs teardown; pass the gate the exit context. [S18] KeRaiseIrql(DISPATCH)
across the active-SVM window matters more once the handler does real work with a paused guest.
**(5) I4 — NPT intercept (deferred after I3).** Mark a guest page not-present → guest access → VMEXIT_NPF →
host handles (the §0.6 NPT-CoW-reversible defense). Contained to the guest's NPT; higher complexity (NPF
decode).
**(6) I5 — live bluepill (DEFERRED, own explicit gate, NOT in scope).** Capture the running OS state into the
VMCB + VMRUN with host=live-OS. The §0.6 brick class. Gated behind the three-way closure (hexad-unrepresentable
+ rehearsed-in-guest + NPT-CoW-reversible). I2 is its foundation; I5 is a separate future decision.
**(7) Refinements/enhancements logged.** [R8] I3 needs a real VMEXIT dispatch loop + RIP-advance for resume
(the current handler is one-shot teardown). [E7] adopt CHARIOT's full VMCB diag-copy (control 1024B + state
512B → diag page, R3-readable) for I3+ forensics (PD-5; I2 read only EXITINFO1+RIP). [S18] raise IRQL across
the active-SVM/paused-guest window in I3+. Guest-RIP-not-advanced on VMMCALL intercept confirmed (=phys+0xA000)
→ I3 resume must advance it.
**(8) Honest status (PROVEN vs DESIGNED).** PROVEN ON METAL: the full Ring −1 round-trip, disposable guest
(I0→I2); the gate decision in Ring 0 (Tier-2) + R3-invokable (Tier-3). DESIGNED (not built): I3, I4, I5.
III now has a working, NIH, byte-verified, reversible, contained Ring −1 hypervisor capability on this
machine. The KATABASIS descent — III beneath Windows — is real at Ring 0 and Ring −1.

## I3-i BUILT + VERIFIED (2026-05-23) — gate_floor.sys re-pinned `eb498f8d`, deploy-ready — THE GATE AT RING −1
[C18 — PD-2] gate_floor.sys now links the FULL 19-module gate-admit closure (identical to gate_ioctl.sys) +
cpufeat_kernel alongside the SVM machinery — the ISOLATED floor binary fusing the proven gate with the proven
VMRUN. IOCTL_GATE_AT_VMEXIT (0x222014) verified in disasm: `0x222014` compare → `iii_kfo_svm_vmrun` →
`movabs rax,0x81` (the `if exit==0x81` gate) → `xii_term_arena_reset` → `cap_env_init` → `cap_attenuate` →
`cycle_act` → `under_cap` → `cycle_seal` → [smode==1: 2nd cycle_act+cycle_seal = wrong seal] → `gate_admit`.
driver_entry forces scalar crypto (`sha256_sched_force(1)`+`keccak_chi_force_path(1)`). Imports ntoskrnl ONLY
(the pure-.iii closure adds none). **Stack ACYCLIC, peak 10728 B = 10.5 KiB = 43.7% of 24 KiB** (stackdepth.py
root L_p_floor_ioctl; deepest path through katabasis_gate_admit == gate_ioctl's proven 10.7KB). The gate runs
AFTER full SVM teardown (pure BSS-arena compute) → the privileged window stays exactly I2-small. Client runs 4
cases (OK/REJECT_SEAL/REJECT_CAP/REJECT_HEXAD), each a VMRUN→#VMEXIT 0x81→gate verdict; checks exitcode==0x81
AND verdict==expected (rejects too [[feedback_no_autogen_stub_prove_negative]]). Deploy-ready (operator UAC).
Success = 4/4 {exit 0x81, verdict==expected} ⇒ the Tier-2/3 gate FUSED with Ring −1.
[R8] I3-ii (guest SUPPLIES the request + host writes the verdict back + resume loop, advancing guest RIP past
the VMMCALL) DEFERRED; I3-i is R3-driven (the guest's VMMCALL is the trigger; R3 supplies the cycle). [E7] full
VMCB diag-copy + [S18] KeRaiseIrql(DISPATCH) across the active-SVM window also deferred to I3-ii/I4.

### ★ I3-i PROVEN ON METAL (2026-05-23, operator deploy)
`[gate@VMEXIT]` 4 cases, ALL `VMEXIT=0x81  verdict==expect  PASS`: OK(0)/REJECT_SEAL(1)/REJECT_CAP(2)/
REJECT_HEXAD(3). **III ran a guest in Ring −1 AND ran its full capability/seal/hexad GATE DECISION at the
VMEXIT, returning the correct verdict for all 4 cases (incl. 3 rejects), in Ring 0/−1 of live Windows.** The
Tier-2/3 gate is FUSED with Ring −1. region_phys=0xa9f75000 this run (varies per load); all derived fields
tracked (proves runtime phys-addr computation is allocator-placement-independent). The descent is real AND
USEFUL at Ring −1 — not just "VMRUN works" but "the hypervisor seat makes the sovereign admission decision."

## I3-ii DESIGN (the resume-loop = the I5-mechanism rehearsal; RISKIEST rung — design locked pre-build)
**Claim:** the host RESUMES a guest after adjudicating its exit, and the guest CONTINUES to a 2nd exit — a
full guest↔host gate protocol. This rehearses I5's core loop (guest runs → #VMEXIT → gate adjudicates →
resume → guest continues) with a DISPOSABLE guest [PD-0], de-risking the I5 MECHANISM (separate from the I5
target). **New shims (floor_abi.s):** (a) `iii_kfo_vmrun_once(virt,phys)->exitcode` = the bracket ONLY
(mov rax,phys; clgi; vmsave; vmrun; vmload; stgi; read EXITCODE) — NO enable, so the loop re-VMRUNs without
re-enabling; (b) `iii_kfo_write_guest_loop(virt)` = write the 2-VMMCALL guest at +0xA000: `mov eax,0;
vmmcall; mov eax,[0x20030]; vmmcall; hlt` (32-bit: B8 imm32 / 0F01D9 / A1 disp32 / 0F01D9 / F4) — the guest
requests, READS the host's verdict from the shared area, echoes it back; (c) `iii_kfo_raise_dispatch()->old`
= KeRaiseIrqlToDpcLevel; (d) `iii_kfo_lower_irql(old)` = KeLowerIrql. **Handler (IOCTL_GATE_LOOP 0x222018):**
read req → alloc → build_vmcb → write_guest_loop → pin → **raise DISPATCH** → enable (writemsr EFER|0x1000 +
VM_HSAVE_PA) → **BOUNDED loop (max 4 iters [S19]):** `exitcode=vmrun_once; if !=0x81 break; if iter==0 {gate
on req → verdict; write verdict to [region+0x20030]; [region+0x578]+=3 (advance RIP past VMMCALL, [C-I2]:
saved RIP = the VMMCALL addr, NOT advanced)} else {echoed=[region+0x5F8]&0xFFFFFFFF (guest eax = verdict it
read); break}` → disable (writemsr EFER&~0x1000 + clear VM_HSAVE_PA) → **lower IRQL** → unpin → free → report
{iters, exitcode, verdict, echoed}. Success = verdict==expected AND echoed==verdict (the guest READ the host's
verdict — a full bidirectional Ring−1 round-trip). **NEW RISKS + mitigations:** (R-a) the gate runs with SVM
ACTIVE + a paused guest between VMEXITs → [S18] DISPATCH IRQL prevents preemption; gate is pure non-paged BSS
compute (safe at DISPATCH). (R-b) RIP-advance wrong → guest runs wrong code → [C-I2] confirms VMMCALL=3 bytes,
saved-RIP=VMMCALL-addr, so +3 is exact. (R-c) runaway loop → [S19] hard iteration bound. (R-d) alloc/free are
PASSIVE-only → done OUTSIDE the IRQL-raise. Every other piece (enable/disable/bracket/gate/build_vmcb) is
metal-proven. This is the highest-risk rung; design is locked before building.

### I3-ii BUILT + VERIFIED (2026-05-23) — gate_floor.sys re-pinned `c7c3c101`, deploy-ready — THE RESUME LOOP
[C19 — PD-2] 4 new shims byte-verified: `iii_kfo_vmrun_once` (bracket-only, NO enable — for the loop),
`iii_kfo_write_guest_loop` (`mov eax,0; vmmcall; vmmcall; hlt` = `B8 00000000 0F01D9 0F01D9 F4` @0xA000),
`iii_kfo_raise_dispatch` (KeRaiseIrqlToDpcLevel), `iii_kfo_lower_irql` (KeLowerIrql). The loop lives in its
OWN function `floor_gate_loop` (see [C-cgr0-locals]). Loop verified in disasm: `while run==1 { vmrun_once;
if exit!=0x81 stop; iter0: gate→verdict, [rv+0x5f8]=verdict (idx 0xbf), buf[1]=verdict, [rv+0x578]=[rv+0x578]+3
(idx 0xaf — read/add 3/store, proven base+idx*8 pattern), iter=1; else: buf[2]=[rv+0x5f8]&0xFFFFFFFF, stop }`;
backjump `91e→59f`; gate chain cap_env_init/cycle_act/gate_admit present; IRQL raise BEFORE / lower AFTER the
loop. Imports ntoskrnl ONLY (+KeRaiseIrqlToDpcLevel,KeLowerIrql). **Stack ACYCLIC peak 11800 B = 11.5 KiB =
48% of 24 KiB** (root floor_ioctl→floor_gate_loop→gate_admit). Client: 4 cases, each checks `exit==0x81 AND
verdict==expected AND echoed==verdict` (echo = the verdict the guest carried back = the host→guest→host
round-trip). Deploy-ready (operator UAC).
- [C-cgr0-locals — NEW cg_r0 TRAP] cg_r0 has a per-FUNCTION local-slot LIMIT. floor_ioctl (6 IOCTL branches)
  overflowed it once I3-ii's locals were added inline → the LATEST locals spilled to GLOBAL refs (link error
  `undefined reference to L_p_g4_verdict / L_p_g4_e`). The IDENTICAL let-mut pattern compiled fine in I3-i
  (fewer locals) — proving it's a count limit, not a scope bug. FIX: extract large handlers into their own
  functions (fresh local table per fn). General rule: keep cg_r0 functions' local counts modest; extract.
- [R-I3iii deferred] a guest that SUPPLIES its own request (vs R3-supplied); the full VMCB diag-copy [E7].
  I3-ii's guest is R3-parameterized; the resume MECHANISM (adjudicate→write-verdict→advance-RIP→re-VMRUN→
  read-echo) is the I5-critical part and is what's proven here.

### ★ I3-ii PROVEN ON METAL (2026-05-23, operator deploy)
`[resume-loop]` 4 cases, ALL `VMEXIT=0x81  verdict==expect  echoed==verdict  PASS`. **III adjudicated the
guest's 1st VMMCALL with the full gate, wrote the verdict into the guest's RAX, advanced RIP, RESUMED the
guest, and the guest carried the verdict back to its 2nd VMMCALL where the host read it (echo==verdict).**
The I5 adjudicate-AND-RESUME loop is proven on metal with a disposable guest. The full chain on this run:
probe→disable→hostmode→vmcb→vmrun→gate@VMEXIT(4/4)→resume-loop(4/4). The MECHANISM I5 needs is de-risked.

## I4 DESIGN (NPT page-fault interception — the §0.6 NPT-CoW / observe brick-defense basis)
**Claim:** III intercepts a guest MEMORY access via NPT, reads the fault, maps the page, and RESUMES — the
foundation of the §0.6 NPT-CoW reversible-brick defense. **Reuses** the PROVEN resume loop (I3-ii): vmrun_once,
IRQL, pin, build_vmcb, enable/disable. **NO new shims, NO new guest** — the default `vmmcall;hlt` guest's own
INSTRUCTION-FETCH is the fault. **New (in new fn `floor_npt_loop`, own local table per [C-cgr0-locals]):**
(1) before VMRUN, clear the PRESENT bit of the NPT PD entry covering the guest CODE page: idx=(rp+0xA000)>>21;
`(rv)[2048+idx] = (rv)[2048+idx] & ~1` (2048 = 0x4000/8 = PD base qword index; entry = (idx<<21)|0xE7 →
clear bit0 → (idx<<21)|0xE6 = not-present). (2) the resume loop dispatches on exit: **NPF (0x400)** → read
the faulting GPA from `VMCB.EXITINFO2 @0x080` (idx 16; EXITINFO1@0x078=NPF err code), MAP it
`(rv)[2048+((gpa>>21)&0x7FF)] = (fidx<<21)|0xE7` (present), **NO RIP advance** (re-execute the fetch), resume;
**VMMCALL (0x81)** → the guest RAN after the page was mapped → stop. TLB_CONTROL=1 (already set) flushes the
NPT on each VMRUN so the re-map takes effect. Report {npf_exit=0x400, faulting_gpa≈rp+0xA000, vmmcall_exit=
0x81, npf_count}. **Safety:** the vmmcall;hlt guest makes NO arbitrary memory access (its ONLY fault is its
own code-fetch); failures are DETECTABLE not wedges (no-NPF → buf default; recurring-NPF → iteration bound);
contained + reboot-recoverable. This proves III can MEDIATE guest memory — the basis for CoW-reversible bricks.

### I4 BUILT + VERIFIED (2026-05-23) — gate_floor.sys re-pinned `129cc06d`, deploy-ready — NPT INTERCEPTION
[C20 — PD-2] `floor_npt_loop` (own fn, no new shims, no new guest). Verified in disasm: the **NPT-CLEAR** is a
correct base+index*8 RMW — cidx=(rp+0xA000)>>21 (`b25 add` rp+0xA000, `b29 0x15` shift 21), index 2048+cidx
(`b44 0x800`, `b56 add`), `b5c mov rax,[rax+rcx*8]` (read PD[cidx], base=rv/index=2048+cidx), `b61 0xff..fe`
`b6e and` (clear present bit0), `b92 mov [rax+rcx*8],rdx` (write back). **NPF handler:** `0x400` dispatch,
gpa=[rv+16] (EXITINFO2@0x080), fidx=(gpa>>21)&0x7ff, map `(rv)[2048+fidx]=(fidx<<21)|0xE7` (shl cl + 0xe7),
**NO RIP advance**. VMMCALL `0x81` → stop. iteration bound `iter>3`. **TLB_CONTROL=1** (set in build_vmcb,
carried from CHARIOT) flushes the NPT on each VMRUN so the remap takes effect — the linchpin that prevents a
re-fault loop. Imports ntoskrnl ONLY; stack ACYCLIC 11.5 KiB (48%); hash `129cc06d`; deploy-ready (UAC).
Client checks NPF==0x400 AND VMMCALL==0x81 AND faulting-GPA in the code page's 2MB. Proves III MEDIATES guest
memory from Ring −1 → the §0.6 NPT-CoW / observe brick-defense foundation.
**Ring −1 capabilities BUILT+VERIFIED (most proven on metal): I0 probe · #19a teardown-primitive · #19b
host-mode · #19c-i VMCB · I2 VMRUN · I3-i gate@VMEXIT · I3-ii resume-loop · I4 NPT-intercept. The only rung
left is I5 (live-OS bluepill) — DEFERRED behind its own explicit gate + the §0.6 three-way brick closure.**

### ★★ I4 PROVEN ON METAL (2026-05-23) — THE RING −1 CAPABILITY LADDER IS COMPLETE
`[npt-intercept] iter=2  faulting GPA=0xa9f7f000  NPF=0x400  VMMCALL=0x81  region_phys=0xa9f75000 /
NPF-caught=YES guest-ran-after-map=YES faulting-GPA-in-code-page=YES => PASS`. The faulting GPA =
`0xa9f7f000` = **exactly** region_phys+0xA000 (the code-page fetch) — EXITINFO2 byte-precise. **III caught a
guest NESTED PAGE FAULT from Ring −1, read the faulting GPA, mapped the page, and resumed the guest, which
then ran — guest memory MEDIATED from the hypervisor seat, on metal.** The §0.6 NPT-CoW/observe basis is real.

## ★★★ MILESTONE: THE RING −1 CAPABILITY LADDER IS COMPLETE (I0→I4, all proven on metal)
Every privileged primitive the descent needs is demonstrated on this 7945HX, with III-emitted code (cg_r0
.iii + hand-asm, NIH, ntoskrnl-only, byte-verified, deterministic, reversible, operator-gated), each rung a
disposable/contained guest:
- I0 SVM probe · #19a teardown-primitive (WRMSR+pin) · #19b host-mode (enable+region+VM_HSAVE_PA) ·
  #19c-i VMCB build · I2 VMRUN (disposable guest) · I3-i gate@VMEXIT (the full gate adjudicating in Ring −1) ·
  I3-ii resume-loop (adjudicate→write-verdict→resume, the I5 loop rehearsed) · I4 NPT-intercept (mediate memory).
- The three §0.6 brick-closure MECHANISMS are each independently proven: **hexad-unrepresentable** (the gate
  rejects brick-class actions — Tier-2/3 + I3-i at the VMEXIT), **rehearsed-in-guest** (I2–I4 are exactly that),
  **NPT-CoW-reversible** (I4 = the interception basis).
- **The ONLY rung left is I5: bluepilling the LIVE OS.** It is categorically different from every prior rung —
  it points the proven mechanism at the LIVE Windows (the §0.6 brick-RISK), not a disposable guest. Per [PD-0]
  it is DEFERRED behind the operator's EXPLICIT decision + the three-way closure COMPOSED. I will NOT approach
  I5 autonomously; the disposable-guest ladder was built precisely to de-risk it first, and now has.

## CHUNK B (harden the proven rungs) — in progress
### B1 [E7] VMCB diag-copy BUILT+VERIFIED+★PROVEN ON METAL (2026-05-23) — gate_floor.sys re-pinned `850c115f`
Metal: `[vmcb-diag] dumped 1536 VMCB bytes to R3: EXITCODE=0x81 guest RIP=0xa9f7f000 guest CR0=0x11 => PASS`
(all 8 prior blocks still PASS). The full post-VMRUN VMCB is readable from R3.
### B2 I3-iii (guest authors its own request) BUILT+VERIFIED, deploy-ready (2026-05-23) — gate_floor.sys `187444ea`
New: guest blob `g_i3iii_guest` (49B: writes a 6-value cycle request to [eax]=shared GPA, 2×vmmcall, hlt) +
`iii_kfo_write_guest_request` (rep movsb). `floor_gate_decide(rv)` (the gate, reading the request from the
shared area — ONE pointer param) + `floor_gate_self(buf)`: set guest RAX@0x5F8 = rp+0x20000 (shared GPA) →
write_guest_request → resume loop {iter0: floor_gate_decide(rv) on the GUEST's request, verdict→RAX, advance
RIP; iter1: echo}. IOCTL_GATE_SELF `0x222024`. Verified: RAX-set (idx 0xbf), request reads (idx 0x4000..0x4005),
gate_decide call, ntoskrnl-only imports, stack 11.5 KiB. The guest authors the OK case (family=2) → verdict 0,
echoed back. **NEW cg_r0 TRAP: functions support <=4 PARAMETERS** (rcx/rdx/r8/r9); the 5th+ stack params spill
to GLOBAL refs (`undefined reference L_p_<param>`) — found via floor_gate_decide(6 params)→L_p_crts/L_p_smode.
FIX: <=4 params; pass aggregates by POINTER (floor_gate_decide(rv) reads the 6-value request from memory).
Remaining Chunk B (DEFERRED per operator pivot to Chunk C / the I5 design): multi-core SVM, suite consolidation.

## CHUNK C — THE EXHAUSTIVE I5 DESIGN (DESIGN ONLY; no execution) → DOCS/RING-MINUS-1-I5-DESIGN.md
The full safety-first architecture for bluepilling the LIVE OS, prime directive = the live OS survives every
failure mode (≤1 reboot, ideally none). Key INVENTIONS (the safety crown):
- **[I5-a] capture-rehearsal** — the keystone: VMRUN the REAL captured live-CPU state (CR0-4/CR3/EFER/segs)
  with a THROWAWAY RIP first; a bad capture wedges only the throwaway, not the OS. Converts the irreducible
  T1 risk ("bet the machine on the capture") into "test the throwaway." No CHARIOT precedent; this is new.
- **[un-bluepill] reversibility** — III can release the OS at any VMEXIT (restore guest→CPU, STGI, clear
  SVME, return un-virtualized); the OS keeps running, III steps out from underneath. Never a trap.
- **[watchdog/deadman]** — an un-bluepilled sibling core releases the OS if its heartbeat stalls (a hang is
  recoverable, not fatal).
- **[shadow-rehearsal]** — the §0.6 "rehearsed-in-guest" applied LIVE: replay a live-OS dangerous op in a
  disposable guest first; refuse the live op if the throwaway bricks. Third brick-closure made dynamic.
- **fail-safe-default** — any HV fault / unmodelled exit → release, never guess. **minimal-intercept** — only
  the brick-class VMEXITs (near-native OS speed, smallest handler surface). **single-core first** (blast radius
  = 1 thread; 31 cores untouched + free for the watchdog).
The §0.6 three-way closure is COMPOSED + applied live as AND (refused[hexad, I3-i] AND reversible[NPT-CoW, I4]
AND rehearsed[shadow]). I5 is itself a rehearsal ladder I5-a(capture)→b(release+watchdog)→c(full-GPR handler)
→**d(the bluepill, single core, ONLY after a/b/c PASS + a 9-point GO/NO-GO + the operator's explicit go)**→
e(gate-protects-live)→f(SMP, deferred). Threat model T1-T8 each answered. Execution plan §12 (step 1 = the
read-only live-state capture harvest). **The live OS is bluepilled exactly once (I5-d), behind its own gate,
releasable the instant after. NOT executed — awaits the operator's explicit go.**
New shim `iii_kfo_copy_qwords(dst,src,nq)` (rep movsq; rdi/rsi saved). New fn `floor_vmrun_diag(buf)`:
build_vmcb → pin → DISPATCH → enable → `vmrun_once` → `copy_qwords(buf, rv, 192)` (VMCB control 128q +
state-save 64q = 1536 B → R3) → disable → unpin → free. IOCTL_VMRUN_DIAG `0x222020`. Verified: rep movsq
shim byte-correct (`mov rdi,rcx`/`mov rsi,rdx`/`mov rcx,r8`/`cld`/`rep movsq`); copy count 0xc0=192; imports
ntoskrnl-ONLY (rep movsq adds none); stack 11.5 KiB acyclic. Client reads the dump: EXITCODE@0x70==0x81,
guest CR0@0x558==0x11. Fault-as-data forensics [E7] — any guest exit now fully inspectable from R3.
Remaining Chunk B: I3-iii (guest supplies its own request), multi-core SVM, consolidate into a clean Ring-1
suite + KATs.

