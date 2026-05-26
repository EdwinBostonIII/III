# KATABASIS Ring −1 (the III Floor) — the get-it-right-first-time plan

> Status: PLAN (no metal code emitted by this doc). Built from a thorough read of
> `DOCS/CHARIOT_HARVEST.md`, the working hypervisor at `C:\Users\Edwin Boston\OneDrive\Desktop\
> CHARIOT-HYPERVISOR-WORKING`, and III's own `COMPILER/BOOT/cg_rm1.iii`. Companion to
> `DOCS/III-KATABASIS.md` (§8.2 ladder, §0.6 brick class) and `DOCS/IOCTL-GATE-AUDIT.md` (Tier-3).

---

## 0. DOCTRINE — why Ring −1 is categorically different, and the prime directives

Ring 0 mistakes BSOD; the OS records a dump, you reboot, you read the dump. **Ring −1 mistakes can
wedge the machine *below* the OS** — no BSOD, no dump, possibly no clean reboot — and AMD's
`VM_CR.SVMDIS`/`SVM_LOCK` and SMM interactions mean a botched SVM-enable can leave the box in a
state only a power-cycle (or worse) clears. The KATABASIS rule "BSOD acceptable, bricking never"
becomes literal here. Therefore:

- **PD-0 (disposable guest first).** No early increment bluepills the *live* OS. We VMRUN a
  **throwaway guest** (a few instructions in our own region) and catch its VMEXIT. A fault then
  lands in a guest we created and can discard — not in Windows. This is CHARIOT's T18 pattern
  (`probe_ring2.c`: dangerous op inside a throwaway SVM guest, fault-as-data). The live-OS bluepill
  is a *separate, later, explicitly-decided* increment (I5), gated on the §0.6 three-way brick
  closure (hexad-unrepresentable + rehearsed-in-guest + NPT-CoW-reversible).
- **PD-1 (proven numbers only).** Every SVM constant, opcode, field offset, and MSR is taken from a
  source that already ran on **this** silicon (Ryzen 9 7945HX) — the CHARIOT working HV / harvest
  §2.2/§2.3 — or the AMD manual, and is *cross-checked* against both. No guessed magic numbers.
- **PD-2 (every byte gated).** Before any load: disassemble the emitted `.sys`/module and prove,
  byte-for-byte, that each privileged sequence equals the CHARIOT-proven sequence, AND that the
  Aegis machine-code invariants hold (CLGI/STGI paired, VMRUN bracketed, VMLOAD/VMSAVE balanced,
  ASID≠0, decode-clean, REX well-formed, stack balanced). No "looks right."
- **PD-3 (operator-gated, reboot-recoverable).** Demand-start only (never boot-loaded → no boot
  loop), test-signing, System Restore point, the kernel-load trigger stays with the operator. A
  worst-case wedge is recoverable by power-cycle because nothing auto-loads.
- **PD-4 (reversibility designed-in).** The driver's teardown path (VMEXIT → VMSAVE → STGI → clear
  `EFER.SVME` → free region) is written and verified *before* the enable path is ever run. SVM is
  entered only if the exit is already proven.
- **PD-5 (fault-as-data).** The VMEXIT handler treats *every* exit code as structured data written
  to a fixed diagnostic region (CHARIOT's crash-forensic ring; cg_rm1 already emits a 256-entry
  VMEXIT table + an mhash self-attest placeholder). The host never trusts the guest.
- **PD-6 (determinism + witness).** The emitted HV module + loader are byte-reproducible (III's
  determinism gate); cg_rm1 emits D8 witness entry/exit + an mhash placeholder for runtime
  `.text` self-attestation.

---

## 1. ASSET INVENTORY — what already exists (this is most of the work)

### 1.1 III `cg_rm1.iii` (115 KB, a guarded, near-complete Ring −1 emitter)
Confirmed by read. It is a position-independent (PIC) Ring −1 codegen that emits:
- `rm1_hv_emit_bare_metal_entry` — the bare-metal HV entry.
- `rm1_hv_emit_svm_vmrun_bracket` (478 B) / `rm1_hv_emit_vmx_vmrun_bracket` (491 B, Intel) — the
  CLGI/VMLOAD/VMRUN/VMSAVE/STGI brackets (AMD + Intel).
- `rm1_hv_emit_vmx_svm_dispatch` (494 B) — vendor dispatch (AMD vs Intel).
- `rm1_hv_emit_slat_tables` → `rm1_hv_emit_one_pd(g)` — **NPT identity map**: 4 PDs × 512 × 2 MB
  pages, entry `val = ((g<<30)|(e<<21)) | 0xB7` (present|rw|user|accessed|dirty|PS) = 4 GB identity.
- `rm1_hv_emit_vmexit_table` — 256-entry VMEXIT dispatch table (default → `iii_hv_vmexit_default`).
- `rm1_hv_emit_bss_and_data`, `rm1_hv_emit_witness` (D8 entry/exit, stack-parity-correct),
  `rm1_emit_section_mhash_placeholder` (runtime self-attest), `rm1_emit_volatile_clear` (PXOR
  xmm0..15 — FP-state hygiene), full expr/stmt/metal/match/for codegen.
- **Emit-time safety guards**: `rm1_sym_is_permitted`, `rm1_guard_symbol_load`,
  `RM1_E_FORBIDDEN_TARGET`, `RM1_E_ONEWAY_READ`, `RM1_E_NON_PIC_RELOC` — the Ring −1 codegen
  *refuses* to emit forbidden targets or non-PIC relocations. This is M8/hexad-style safety baked
  into codegen.
- `.iii`-compiled into iiis-2 (the live compiler), like cg_r0.

**Implication:** III can already *emit* the bluepill core. The open work is (a) prove that emission
is correct against CHARIOT, and (b) the Ring-0 loader + the safe test harness.

### 1.2 CHARIOT working HV (`CHARIOT-HYPERVISOR-WORKING`) — the proven reference
- **`NATIVE/sma_x64_emit.c`** — the metal-proven SVM opcodes:
  `VMRUN=0F 01 D8`, `VMSAVE=0F 01 DB`, `VMLOAD=0F 01 DA`, `CLGI=0F 01 DD`, `STGI=0F 01 DC`
  (RAX = the relevant phys addr). Plus the **PIC module ABI** (`sma_x64_translate_pic`):
  entry `RCX=svm_virt, RDX=svm_phys, R8=shared_buf, R9=module_id`; callee-saved `R13=svm_virt,
  R14=svm_phys, R15=shared_buf`; 2536-byte aligned PIC frame. Built + tested (`test_platform_svm.exe`,
  `vmrun_test`, `chariot_run.exe` are present binaries).
- **`LINK/sma_pe_emit_platform.c`** (110 KB) — emits the platform `.sys`: the 256 KB SVM region +
  the 6-step incremental VMCB builder + the VMRUN loop (HV_HOIST_RUN). **The proven VMCB field
  offsets + the SVM-enable sequence live here — Phase-0 harvest target.**
- **`FOUNDATION/sma_address_map.h`** (33 KB) + harvest §2.3 — the proven SVM-region layout (256 KB):
  VMCB `0x0`, HostSave `0x1000`, NPT `0x2000` (32 KB PML4+PDPT+PD), GuestCode `0xA000`,
  MSRPM `0xB000`, IOPM `0xC000`, ML-state `0x10000`, Shared `0x20000`, HV stats `0x3E000`,
  diagnostic ring `0x3F000`.
- **harvest §2.2** — proven MSRs on this silicon: HWCR `0xC0010015`, SMM_BASE `0xC0010111`, VM_CR,
  VM_HSAVE_PA, EFER, APIC_BASE, LSTAR. (Exact AMD numbers to confirm in Phase 0: EFER `0xC0000080`
  bit 12 = SVME; VM_HSAVE_PA `0xC0010117`; VM_CR `0xC0010114` bit 4 = SVMDIS, bit 3 = SVM_LOCK.)
- **harvest §3 / Aegis** — the machine-code invariant rule set already named: `CLI_STI_BALANCE`,
  `CLGI_STGI_PAIRED`, `VMRUN_BRACKETED`, `NO_DOUBLE_POP_RBX`, `DECODE_CLEAN`, `REX_WELLFORMED`,
  `ASID_NONZERO`, `VMRUN_COUNT_MATCHES`, `PUSHPOP_BALANCE`.
- **T18** (`probe_ring2.c`) — the throwaway-guest, fault-as-data safety pattern (PD-0).

### 1.3 III infrastructure that transfers directly (the multiplier)
- **The Tier-3 `kernel_abi.s` shim pattern** — the exact mechanism for the privileged ops cg_r0
  can't emit or align: hand-asm shims with `andq $-16,%rsp` + Win64 marshalling + bare ntoskrnl
  calls + SEH frame. Ring −1 needs the same for: `__writemsr`/`__readmsr` (WRMSR/RDMSR EFER,
  VM_HSAVE_PA), `__cpuid` (SVM detect), `MmAllocateContiguousMemory`/`MmGetPhysicalAddress`/
  `MmFreeContiguousMemory` (the contiguous SVM region + its phys addr), and the VMRUN bracket
  itself (CLGI/VMLOAD/VMRUN/VMSAVE/STGI) if we choose to host it in the loader rather than the
  cg_rm1 module.
- **The Tier-3 IOCTL gate is the control plane** — `\\.\IIIKatabasisGate` already lets R3 drive the
  kernel. Ring −1 becomes new IOCTLs on the same device: `IOCTL_SVM_PROBE`, `IOCTL_VMRUN_THROWAWAY`,
  `IOCTL_HV_TEARDOWN`. R3 orchestrates; the kernel executes; the gate observes.
- **`katabasis_gate_admit`** — the gate decision is the Ring −1 *payload*: the VMEXIT handler runs
  the gate (a cross-ring cycle admitted/refused at Ring −1). Proven correct (corpus 609 + Tier-2/3
  on metal). The cg_rm1 module's VMEXIT dispatch calls into the (cg_rm1-compiled) gate closure.
- **Witness / seal / determinism / the Aegis-rules-as-III idea** (harvest T17) — the paranoid
  verification, automated: the Aegis machine-code rules become `.iii` predicates over the
  disassembly, emitting witness receipts; the emitted HV is byte-reproducible.
- **`cg_r0` + the verified IOCTL driver** — the Ring-0 loader is a cg_r0 driver exactly like
  `gate_ioctl.sys`, plus the SVM-specific shims.

---

## 2. DEPLOYMENT ARCHITECTURE — how the pieces compose at runtime

```
 R3 client ──IOCTL──▶ Ring-0 LOADER driver (cg_r0 + kernel_abi shims)        [gate_floor.sys]
                        1. MmAllocateContiguousMemory(256KB, <4GB)  → SVM region (virt+phys)   [shim]
                        2. zero region; copy cg_rm1 HV module → GuestCode slot (0xA000)
                        3. build VMCB @0x0  (intercepts, ASID=1, N_CR3=region+0x2000, guest state)
                           build NPT  @0x2000 (cg_rm1's 4GB identity map, 0xB7 2MB pages)
                           build MSRPM@0xB000, IOPM@0xC000 (allow-all to start; tighten later)
                        4. enable SVM:  WRMSR EFER |= SVME(bit12);  WRMSR VM_HSAVE_PA = HostSave_phys  [shim/metal]
                        5. VMRUN bracket: CLGI; VMLOAD rax=vmcb_phys; VMRUN rax=vmcb_phys; VMSAVE; STGI  [proven 0F01Dx]
                        6. on VMEXIT: read exit_code/guest_rip from VMCB → diagnostic ring (fault-as-data)
                           [I3+] dispatch the exit to the cg_rm1 HV module → katabasis_gate_admit → verdict
                        7. teardown: clear EFER.SVME; MmFreeContiguousMemory; return verdict to R3
                                     ▲
                cg_rm1 HV module (PIC) ┘  — the guest/VMEXIT-handler logic; the gate-at-Ring-1 payload
```

**Key design choice — RESOLVED by I1 (ledger [C7]/[R3]).** The VMRUN bracket lives in **the cg_r0
loader as a Win64 hand-asm shim** byte-validated == CHARIOT's proven `clgi; vmsave; vmrun; vmload;
stgi`. NOT in cg_rm1: the I1 decode found cg_rm1's `RM1_HV_SVM_VMRUN_BRACKET` is (a) order-inverted
vs proven (vmload-before/vmsave-after — loads uninitialized FS/GS/TR, never restores host
extra-state after the guest → host wedge), and (b) **SysV ABI (rdi/rsi) with a bare-metal entry**
(`iii_hv_entry`/`__iii_hv_stack_top`) — cg_rm1 targets a *bare-metal/Linux* Ring −1, not a
Windows-kernel-loaded HV. So for the Windows KATABASIS path, the loader owns every privileged byte
(validated == CHARIOT); cg_rm1 contributes only its **NPT data** (byte-match [C6]) and, later, the
gate-at-R−1 logic. cg_rm1's bracket is filed for a separate fix iff a bare-metal Ring −1 is pursued.
This keeps the privileged loop in auditable hand-asm and uses cg_rm1 for the (verifiable) HV logic.

---

## 3. THE INCREMENTAL LADDER — smallest verifiable first; each operator-gated

| Inc | What it proves | Live-OS risk | Gate |
|---|---|---|---|
| **I0** SVM capability probe | SVM present (CPUID 8000_0001 ECX bit2), EFER readable, `VM_CR.SVMDIS=0`, `SVM_LOCK` state | none (read-only RDMSR/CPUID) | matches CHARIOT `probe_svm_virt` output |
| **I1** cg_rm1 emit + disasm | the emitted SVM bytes == CHARIOT proven; Aegis rules hold | none (no load) | byte-equal + Aegis-green |
| **I2** throwaway-guest VMRUN | VMRUN works on metal: enter a 1-instruction guest (`VMMCALL`), take one `VMEXIT_VMMCALL`, tear down | **disposable guest only** | exit_code==0x81 (VMMCALL); host alive; SVM disabled after |
| **I3** gate-at-Ring−1 | the VMEXIT handler runs `katabasis_gate_admit`; verdict returned to R3 | disposable guest | verdict correct; host alive |
| **I4** NPT-protected guest | NPT intercept (guest write to a protected page → `VMEXIT_NPF`) caught + handled | disposable guest | NPF caught; fault-as-data |
| **I5** live-OS bluepill | virtualize the running Windows (guest = current OS) | **THE dangerous one** | DEFERRED — needs §0.6 closure + a separate explicit decision |

Increments I0–I4 never put the live OS in a guest, so a fault is contained. I5 is a different
project (NPT-CoW reversibility, rehearsed-in-guest, hexad-unrepresentable refusal) and is out of
scope until I0–I4 are rock-solid.

---

## 4. PHASE-0 HARVEST (read-only, before any code) — the proven numbers

Pull these from CHARIOT and pin them in an III reference module (`STDLIB/iii/katabasis/svm_const.iii`,
or a `.def`-forged table per the Sovereign Forge), each cross-checked vs the AMD manual:
1. **VMCB field offsets** (from `sma_pe_emit_platform.c`'s 6-step builder): intercept-CR/DR/exception
   vectors, `intercept_instr1/2` (VMRUN/VMMCALL/CPUID bits), `GUEST_ASID` offset, `N_CR3` (nested CR3)
   offset, `EXITCODE`/`EXITINFO1/2` offsets, the guest-state-save area base (VMCB+0x400) and the
   guest CS/SS/RIP/RSP/RAX/RFLAGS/CR0/CR3/CR4/EFER slots.
2. **The 6-step incremental VMCB build sequence** (HV_VMCB_* IOCTLs) — exact order CHARIOT proved.
3. **The SVM-enable sequence** — exact MSR writes + the EFER.SVME / VM_HSAVE_PA dance + the
   `VM_CR.SVMDIS`/`SVM_LOCK` precheck.
4. **The minimal throwaway-guest VMCB** — what `vmrun_test.c` sets to get a clean VMMCALL exit
   (guest RIP → a `VMMCALL` byte; ASID=1; intercept VMMCALL; NPT or paged-real-mode minimal).
5. **The VMRUN bracket bytes** — confirm cg_rm1's `RM1_HV_SVM_VMRUN_BRACKET` decodes to exactly
   CHARIOT's CLGI/VMLOAD/VMRUN/VMSAVE/STGI + the guest-GPR save/restore around VMRUN (VMRUN only
   saves/restores RAX/RSP/RIP via VMCB; the host must push/pop the other guest GPRs itself — a
   classic bluepill correctness point; verify cg_rm1 does it).
6. **The contiguous-memory constraint** — VMCB/HostSave/NPT must be *physically* contiguous and
   < the addressing limit; confirm CHARIOT's allocation (MmAllocateContiguousMemory, highest
   acceptable address) and the phys-addr derivation.

Deliverable: `DOCS/SVM-CONSTANTS-HARVEST.md` (the proven values, each with its CHARIOT source line
+ AMD-manual cross-ref) + the III reference module. **No magic number enters III un-sourced.**

---

## 5. VERIFICATION GATES — the automated paranoia (per increment, all must pass before load)

1. **Byte-equality vs proven.** Disassemble the emitted module/driver; assert every privileged
   instruction's bytes == the CHARIOT-proven bytes (VMRUN `0F01D8`, etc.) and the VMCB writes hit
   the harvested offsets.
2. **Aegis machine-code rule registry, ported to III** (harvest T17 → `.iii` predicates over the
   disasm): `CLGI_STGI_PAIRED`, `VMRUN_BRACKETED` (every VMRUN flanked by VMLOAD/VMSAVE inside
   CLGI/STGI), `VMLOAD_VMSAVE_BALANCED`, `ASID_NONZERO`, `CLI_STI_BALANCE`, `PUSHPOP_BALANCE`,
   `NO_DOUBLE_POP_RBX`, `DECODE_CLEAN`, `REX_WELLFORMED`. Each emits a witness receipt; the build
   gate fails red on any violation. **This automates the CRASH-PROTOCOL's manual machine-code
   checks — the single highest-value CHARIOT transfer for this work.**
3. **Stack/alignment.** rsp 16-aligned at VMRUN and every call; the cg_rm1 PIC frame (2536) and the
   shim `andq $-16` both proven (the Tier-3 lesson: cg's depth tracking is unreliable → shims align
   robustly).
4. **Determinism.** Emitted HV module + loader byte-reproducible across two builds; iiis-2 seal gate.
5. **Reversibility dry-run.** The teardown path is disassembled + proven to clear EFER.SVME and free
   the region on *every* exit path (including the error paths) before the enable path is run.
6. **Fault-as-data.** The VMEXIT handler writes {exit_code, guest_rip, exit_info} to the diagnostic
   ring for *every* exit; no exit path trusts guest state or jumps to a guest-controlled address.
7. **Operator gate (PD-3).** test-signing on, HVCI off, restore point, demand-start, signed copy;
   the load is the operator's UAC trigger; the doc states the exact recovery (power-cycle).

---

## 6. THE GAPS, AND HOW CHARIOT + III FILL THEM

| Gap (for a deployable safe Ring −1) | Filler |
|---|---|
| Allocate physically-contiguous SVM region + get its phys addr | `kernel_abi` shims: `Mm{AllocateContiguous,GetPhysicalAddress,FreeContiguous}Memory` (Tier-3 shim pattern, exact) |
| Privileged WRMSR/RDMSR/CPUID (enable SVM, probe) | `kernel_abi` shims `__writemsr`/`__readmsr`/`__cpuid` (1–2 args, trivially aligned) OR a tiny metal block; bytes validated |
| The exact VMCB field offsets + build order | harvest from `sma_pe_emit_platform.c` (§4.1/4.2); CHARIOT proved them on this silicon |
| The SVM-enable + VMRUN sequence | CHARIOT proven opcodes (§1.2) + cg_rm1's emitted bracket, cross-validated (§4.5) |
| The throwaway guest (safe test) | CHARIOT `vmrun_test.c`/`probe_ring2.c` (T18) — the proven minimal VMMCALL guest |
| Guest GPR save/restore around VMRUN | confirm cg_rm1 does it (§4.5); else add to the loader bracket (CHARIOT shows the pattern) |
| The VMEXIT-handler logic / the gate payload | cg_rm1's VMEXIT table + the (cg_rm1-compiled) `katabasis_gate_admit` closure |
| Automated paranoid verification | Aegis rules → III predicates over `tp_x86_disasm` (T17) |
| Reversibility / bricking-never | PD-0 (disposable guest) for I0–I4; §0.6 three-way closure for I5 |

**The thesis: this is "infinitely more doable" because** (a) cg_rm1 already emits ~80% of the
bluepill (entry, brackets, NPT, VMEXIT table, guards), so we *validate*, not *invent*; (b) CHARIOT
gives a hypervisor that already ran on this exact 7945HX, so every number is *proven*, not guessed;
(c) the T18 disposable-guest pattern makes the first on-metal step *contained* (a faulting guest,
not a wedged host); (d) III's determinism + the Aegis-rules-as-III turn "hope" into "every byte
machine-checked against a known-good reference, reproducibly." Current III helps maximally: the
Tier-3 shim pattern + IOCTL control plane + the gate payload are all directly reusable.

---

## 7. EXECUTION ORDER (the granular task list — each is a chunk, verified, then the next)

0. **Phase 0 harvest** → `DOCS/SVM-CONSTANTS-HARVEST.md` + `katabasis/svm_const.iii` (read-only).
1. **Decode + diff** cg_rm1's `RM1_HV_SVM_VMRUN_BRACKET` / NPT / VMEXIT-table emission vs CHARIOT
   proven bytes; write the byte-equality + Aegis-rule checks. Fix cg_rm1 if it diverges (bootstrap
   change → full rebuild + determinism + corpus per the standing discipline). No load.
2. **I0**: SVM-probe shim + an IOCTL on the existing gate device; R3 reads SVM capability. (Read-only
   metal; the safest possible first touch.)
3. **The loader skeleton**: `gate_floor.sys` (cg_r0 + Mm/ MSR shims) — alloc region, build VMCB+NPT
   (harvested offsets), enable SVM, **teardown-first** (prove the disable path), no VMRUN yet.
4. **I2**: add the throwaway-guest VMRUN bracket (validated bytes); catch one VMMCALL VMEXIT;
   tear down. Disasm-gate, then operator-gated load. The first real Ring −1 moment — contained.
5. **I3**: wire the VMEXIT to `katabasis_gate_admit`; R3 gets a Ring −1 verdict.
6. **I4**: NPT intercept (protected-page guest write → NPF caught).
7. **I5 (separate decision)**: the live-OS bluepill, only after §0.6 closure.

Each step: emit → disasm-gate (byte-equal + Aegis) → determinism → operator-gated load (demand-start,
restore point, reboot-recovery) → fault-as-data result → record in audit + memory. Never two steps
before a metal verification. Never the live OS in a guest before I5's deliberate decision.
