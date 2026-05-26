# SVM constants — harvested from CHARIOT (proven on Ryzen 9 7945HX), cross-checked vs AMD APM vol 2

> Phase-0 deliverable for `DOCS/RING-MINUS-1-PLAN.md`. Every value below is taken from the WORKING
> hypervisor `CHARIOT-HYPERVISOR-WORKING/LINK/sma_pe_emit_platform.c` (the self-emitting platform
> driver's `CMD_INIT_SVM`/`CMD_CLEANUP_SVM`) + `NATIVE/sma_x64_emit.c`, and cross-checked against the
> AMD64 Architecture Programmer's Manual vol. 2 (System Programming), ch. 15 (SVM). CHARIOT's
> `test_platform_svm.c` proved this exact sequence returns EXITCODE 0x81 on this machine.
> **No value here is guessed; each carries its source line + APM cross-ref.** (PD-1)

## SVM instruction opcodes  (sma_x64_emit.c:645-670; APM "VMRUN/VMSAVE/VMLOAD/CLGI/STGI")
| insn | bytes | operand | APM |
|---|---|---|---|
| VMRUN | `0F 01 D8` | RAX = VMCB phys | 15.5 |
| VMSAVE | `0F 01 DB` | RAX = VMCB phys | 15.5 |
| VMLOAD | `0F 01 DA` | RAX = VMCB phys | 15.5 |
| CLGI | `0F 01 DD` | — | 15.17 |
| STGI | `0F 01 DC` | — | 15.17 |
| VMMCALL | `0F 01 D9` | (guest→host hypercall) | 15.9 |

## MSRs  (sma_pe_emit_platform.c:1340-1355; APM 15.4/15.30)
| MSR | number | use |
|---|---|---|
| EFER | `0xC0000080` | bit 12 = **SVME**; MUST be set on the core before VMRUN (APM 15.4) |
| VM_HSAVE_PA | `0xC0010117` | host-state save physical address; set to `region_phys + 0x1000` before VMRUN |
| VM_CR | `0xC0010114` | bit 3 = SVM_LOCK, bit 4 = SVMDIS; **precheck**: if SVMDIS=1 and SVM_LOCK=1, SVM is BIOS-disabled → must NOT WRMSR EFER.SVME (would #GP). (APM 15.30.1) |
| (detect) | CPUID `0x80000001` | ECX bit 2 = SVM available; CPUID `0x8000000A` = SVM rev/features/NASID |

## SVM region layout  (256 KB = 0x40000; PLAT_SVM_REGION_SIZE, sma_pe_emit_platform.c:227 + harvest §2.3)
Must be **physically contiguous**; `region_phys` from MmGetPhysicalAddress.
| offset | contents |
|---|---|
| `0x00000` | **VMCB** (4 KB; control area 0x000-0x3FF + state-save 0x400-0xFFF) |
| `0x01000` | **HostSave** area (→ VM_HSAVE_PA) |
| `0x02000` | NPT **PML4** |
| `0x03000` | NPT **PDPT** |
| `0x04000` | NPT **PD0** (GB0) ... `0x05000` PD1, `0x06000` PD2, `0x07000` PD3 (4 GB identity) |
| `0x0A000` | **GuestCode** (guest RIP) ; guest RSP = `0x0AFE0` |
| `0x0B000` | MSRPM (MSR permission bitmap) |
| `0x0C000` | IOPM (I/O permission bitmap) |
| `0x10000` | ML-state / scratch |
| `0x20000` | Shared (128 KB, R3↔kernel) |
| `0x3F000` | diagnostic page (VMCB dump for fault-as-data) |

## VMCB control area  (offsets verified at sma_pe_emit_platform.c:1094-1148; APM 15.x appendix B)
| off | field | INIT_SVM value | width | note |
|---|---|---|---|---|
| `0x008` | INTERCEPT_EXCEPTIONS | `0xFFFFFFFF` | dword | intercept all 32 exception vectors |
| `0x00C` | INTERCEPT_MISC1 | `0x9906000F` | dword | intercept word 1 (INTR/NMI/SMI/INIT/IO/MSR/... per APM) |
| `0x010` | INTERCEPT_MISC2 | `0x3F` | dword | **all 6 SVM-instr intercepts**: VMRUN(0)\|VMMCALL(1)\|VMLOAD(2)\|VMSAVE(3)\|STGI(4)\|CLGI(5). VMRUN bit MUST be 1 (APM 15.9); VMMCALL bit makes the guest's VMMCALL → VMEXIT 0x81 |
| `0x040` | IOPM_BASE | `region_phys + 0xC000` | qword | I/O permission map phys — **REQUIRED** (line 1111); MISC1 intercepts IO so the base must be valid |
| `0x048` | MSRPM_BASE | `region_phys + 0xB000` | qword | MSR permission map phys — **REQUIRED** (line 1117) |
| `0x058` | GUEST_ASID | `1` | dword | **MUST be ≠ 0** (APM 15.5.1; Aegis ASID_NONZERO) |
| `0x05C` | TLB_CONTROL | `1` | dword | flush this guest's TLB on VMRUN (line 1128) — **was missing from harvest** |
| `0x070` | EXITCODE (read) | — | qword | VMEXIT reason; `0x081` = VMEXIT_VMMCALL |
| `0x090` | NP_ENABLE | `1` | qword | nested paging on |
| `0x0B0` | N_CR3 | `region_phys + 0x2000` | qword | nested CR3 = NPT PML4 phys |
| `0x0C0` | VMCB_CLEAN | `0` | dword | no clean bits (full reload) |

> **HARVEST CORRECTION (2026-05-23, re-read sma_pe_emit_platform.c:1094-1148 for #19c):** the original
> harvest OMITTED IOPM_BASE@0x040, MSRPM_BASE@0x048, TLB_CONTROL@0x05C — all written by CHARIOT and
> required. Adjacent dword fields (0x008/0x00C/0x010, 0x058/0x05C) mean the VMCB build CANNOT use cg_r0's
> 8-byte-uniform stores (an 8-byte write to 0x008 clobbers 0x00C) → the build is a hand-asm shim
> transcribing CHARIOT's exact width-precise movs. [R7]

## VMCB state-save area  (offset 0x400; verified sma_pe_emit_platform.c:1150-1253; APM appendix B)
**GUEST MODE = 32-bit PROTECTED mode, NO PAGING** (CR0.PG=0). So guest-linear = guest-physical → straight
to NPT (no guest page tables to build). NOT long mode (LME=0/LMA=0). This is why RIP=phys+0xA000 works
(it's a guest-physical addr, NPT-identity-mapped) and why the region MUST be <4GB (in the NPT id range).
| off | field | INIT_SVM value | note |
|---|---|---|---|
| `0x400` | ES | sel=`0x10` attr=`0x0C93` limit=`0xFFFFFFFF` base=0 | data seg (Type=RW/Acc,S,P,DB,G) |
| `0x410` | CS | sel=`0x08` attr=`0x0C9B` limit=`0xFFFFFFFF` base=0 | **CODE seg attr `0x0C9B` ≠ data `0x0C93`** |
| `0x420` | SS | sel=`0x10` attr=`0x0C93` limit=`0xFFFFFFFF` base=0 | data |
| `0x430` | DS | sel=`0x10` attr=`0x0C93` limit=`0xFFFFFFFF` base=0 | data |
| `0x4D0` | **EFER** | `0x00001000` | **SVME only** (LME=0/LMA=0); MUST be set or VMRUN→VMEXIT_INVALID (APM 15.5.1) |
| `0x548` | CR4 | `0x00000000` | no PAE (no paging) — **FIXED, not host CR4** |
| `0x550` | CR3 | `0x00000000` | unused (no paging) — **FIXED, not host CR3** |
| `0x558` | CR0 | `0x00000011` | **PE\|ET, no PG** — protected mode, no paging — **FIXED, not host CR0** |
| `0x560` | DR7 | `0x00000400` | |
| `0x568` | DR6 | `0xFFFF0FF0` | dword write (bit 31 set; avoid sign-extend) |
| `0x570` | RFLAGS | `0x00000002` | reserved bit 1 |
| `0x578` | **RIP** | `region_phys + 0xA000` | guest code page (= guest-phys, no paging) |
| `0x5D8` | **RSP** | `region_phys + 0xAFE0` | guest stack near end of code page |

> **HARVEST CORRECTION (2026-05-23):** the original said CR0/CR3/CR4 = "host" — WRONG. CHARIOT uses FIXED
> guest values (CR0=0x11, CR3=0, CR4=0) for a 32-bit-protected no-paging guest (lines 1212-1226), and CS
> attr is `0x0C9B` (code) not `0x0C93` (data) (line 1174). Segment/scalar fields are width-specific
> (word selectors/attrs, dword/qword scalars) → hand-asm shim, not cg_r0 8-byte stores. [R7]

## NPT entries  (sma_pe_emit_platform.c:1258-1336; cg_rm1 `rm1_hv_emit_one_pd`; APM 15.25)
- PML4[0] = `(region_phys + 0x3000) | 0x67`  (→ PDPT; `0x67` = P|RW|US|A|D, no PS) (line 1264)
- PDPT[0..3] = `(region_phys + 0x4000 + g*0x1000) | 0x67`  (→ PDg; g=0..3 covers 0-4 GB) (lines 1270-1299)
- PD[i] for i=0..2047 (ALL 4 PDs are contiguous +0x4000..+0x7FFF, filled as ONE 2048-entry loop) =
  `(i<<21) | 0xE7`  (2 MB identity leaf; `0xE7` = P|RW|US|A|D|**PS**) (lines 1301-1320: `shl rax,21; or rax,0xE7`)
  — **HARVEST CORRECTION (2026-05-23): the proven PD-leaf flag is `0xE7`, NOT `0xB7`.** cg_rm1's
  `rm1_hv_emit_one_pd` uses `0xB7` (PCD set, D clear) — a DIVERGENCE from CHARIOT-proven `0xE7` (D set,
  PCD clear). **The earlier [C6] "cg_rm1 CONFIRMED MATCH" is RETRACTED** (it compared against this harvest's
  wrong 0xB7, not the source). Use `0xE7`. Reinforces [C7]/[R3]: cg_rm1's emission is NOT the proven path.
  Note: CHARIOT fills all 2048 PD entries with a single loop `mov [rdi+rcx*8], (rcx<<21)|0xE7` — the
  `(g<<30)|(e<<21)` form collapses to a flat `i<<21` because the 4 PDs are contiguous.

## The proven host enable + VMRUN bracket  (sma_pe_emit_platform.c:1338-1393)
```
; (f) enable SVM on this core
mov ecx, 0xC0000080 ; EFER
rdmsr
or  eax, 0x1000     ; SVME (bit 12)
mov ecx, 0xC0000080
wrmsr
lea rax, [region+0x1000]    ; HostSave
mov rdx, rax ; shr rdx,32   ; EDX:EAX = HostSave phys
mov ecx, 0xC0010117 ; VM_HSAVE_PA
wrmsr
; (g) VMRUN bracket
mov rax, region_phys        ; RAX = VMCB phys
clgi                        ; 0F 01 DD
vmsave                      ; 0F 01 DB
vmrun                       ; 0F 01 D8
vmload                      ; 0F 01 DA
stgi                        ; 0F 01 DC
; (h-diag) rep movsq VMCB control(1024B) + state-save(512B) → region+0x3F000   [fault-as-data]
; (h) mov rax, [region+0x070] ; EXITCODE → SystemBuffer ; Information=8
```
Teardown (CMD_CLEANUP_SVM, :1420): `KeIpiGenericCall(ipi_svm_cleanup, 0)` — disable SVM on **all
cores** (SVM is per-core). Minimal single-core form: `rdmsr EFER; and eax, ~0x1000; wrmsr`.

## Cross-validation status (PD-1)
All opcodes, MSR numbers, the SVME bit, ASID≠0, NP_ENABLE, N_CR3, the state-save offsets, and the
NPT flag bytes match the AMD APM vol 2 ch.15 + appendix B. CHARIOT's `test_platform_svm.c` proves the
composite sequence returns EXITCODE `0x081` (VMMCALL) on this 7945HX. The NPT PD flag `0xB7` is
byte-identical between CHARIOT and III's `cg_rm1`.
