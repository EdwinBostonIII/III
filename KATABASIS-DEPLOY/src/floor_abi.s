# floor_abi.s -- KATABASIS Ring-1 FLOOR loader shims (#19a, teardown-first).
#
# gate_floor.sys is the DEDICATED, ISOLATED Ring-1 loader (a wedge here never touches the proven
# gate_ioctl.sys). It is a SEPARATE binary, so these shims duplicate kernel_abi.s's Io-shim PATTERN
# with FLOOR device names + an iii_kfo_ ("kernel floor i/o") prefix -- no symbol collision, full
# isolation. New for #19a: the first PRIVILEGED WRITE primitive (iii_kfo_writemsr) + per-core pinning
# (iii_kfo_pin_core/_unpin_core; SVM is per-core), used by the SVM-DISABLE teardown path.
#
# Discipline (same as kernel_abi.s): rbp-frame SEH for any shim that CALLs ntoskrnl, `andq $-16,%rsp`
# depth-independent 16-byte alignment, full Win64 marshalling; leaf shims (cpuid/rd/wrmsr) need no
# frame (no call, no callee-saved clobber except RBX in cpuid, which is saved). ntoskrnl symbols are
# referenced BARE -> ld + libntoskrnl.a synthesize the PE import directory + IAT.

    .att_syntax

# ----------------------------------------------------------------------------- names (.rdata)
    .section .rdata,"dr"
    .balign 2
g_fdevname_buf:                # L"\Device\IIIKatabasisFloor\0"  (25 chars + NUL)
    .short 0x5C,0x44,0x65,0x76,0x69,0x63,0x65,0x5C
    .short 0x49,0x49,0x49,0x4B,0x61,0x74,0x61,0x62,0x61,0x73,0x69,0x73,0x46,0x6C,0x6F,0x6F,0x72,0x00
g_flinkname_buf:               # L"\??\IIIKatabasisFloor\0"  (21 chars + NUL)
    .short 0x5C,0x3F,0x3F,0x5C
    .short 0x49,0x49,0x49,0x4B,0x61,0x74,0x61,0x62,0x61,0x73,0x69,0x73,0x46,0x6C,0x6F,0x6F,0x72,0x00
    .balign 8
g_fdevname_us:                 # UNICODE_STRING { Length=50, MaximumLength=52, pad, Buffer }
    .short 50
    .short 52
    .long 0
    .quad g_fdevname_buf
    .balign 8
g_flinkname_us:                # UNICODE_STRING { Length=42, MaximumLength=44, pad, Buffer }
    .short 42
    .short 44
    .long 0
    .quad g_flinkname_buf

# ----------------------------------------------------------------------------- Io shims (.text)
    .text

# NTSTATUS iii_kfo_create_device(PDRIVER_OBJECT drv /rcx, PDEVICE_OBJECT* out /rdx)
#   -> IoCreateDevice(drv, 0, &g_fdevname_us, FILE_DEVICE_UNKNOWN(0x22), 0, FALSE, out)
    .global L_p_iii_kfo_create_device
    .seh_proc L_p_iii_kfo_create_device
L_p_iii_kfo_create_device:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    .seh_endprologue
    andq $-16, %rsp
    subq $0x40, %rsp                # 0x20 shadow + 3 stack args (rounded to 16)
    movq %rdx, %r10                 # save out
    xorl %edx, %edx                 # arg2 DeviceExtensionSize = 0
    leaq g_fdevname_us(%rip), %r8   # arg3 DeviceName
    movl $0x22, %r9d                # arg4 DeviceType = FILE_DEVICE_UNKNOWN
    movq $0, 0x20(%rsp)             # arg5 DeviceCharacteristics = 0
    movq $0, 0x28(%rsp)             # arg6 Exclusive = FALSE
    movq %r10, 0x30(%rsp)           # arg7 DeviceObject (out)
    call IoCreateDevice
    movq %rbp, %rsp
    popq %rbp
    ret
    .seh_endproc

# NTSTATUS iii_kfo_create_symlink(void)  -> IoCreateSymbolicLink(&g_flinkname_us, &g_fdevname_us)
    .global L_p_iii_kfo_create_symlink
    .seh_proc L_p_iii_kfo_create_symlink
L_p_iii_kfo_create_symlink:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    .seh_endprologue
    andq $-16, %rsp
    subq $0x20, %rsp
    leaq g_flinkname_us(%rip), %rcx
    leaq g_fdevname_us(%rip), %rdx
    call IoCreateSymbolicLink
    movq %rbp, %rsp
    popq %rbp
    ret
    .seh_endproc

# void iii_kfo_complete_request(PIRP irp /rcx, CCHAR boost /rdx)  -> IoCompleteRequest(irp, boost)
    .global L_p_iii_kfo_complete_request
    .seh_proc L_p_iii_kfo_complete_request
L_p_iii_kfo_complete_request:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    .seh_endprologue
    andq $-16, %rsp
    subq $0x20, %rsp
    call IoCompleteRequest          # rcx=irp, rdx=boost (preserved from entry)
    movq %rbp, %rsp
    popq %rbp
    ret
    .seh_endproc

# void iii_kfo_delete_device(PDEVICE_OBJECT dev /rcx)  -> IoDeleteDevice(dev)
    .global L_p_iii_kfo_delete_device
    .seh_proc L_p_iii_kfo_delete_device
L_p_iii_kfo_delete_device:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    .seh_endprologue
    andq $-16, %rsp
    subq $0x20, %rsp
    call IoDeleteDevice             # rcx=dev
    movq %rbp, %rsp
    popq %rbp
    ret
    .seh_endproc

# NTSTATUS iii_kfo_delete_symlink(void)  -> IoDeleteSymbolicLink(&g_flinkname_us)
    .global L_p_iii_kfo_delete_symlink
    .seh_proc L_p_iii_kfo_delete_symlink
L_p_iii_kfo_delete_symlink:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    .seh_endprologue
    andq $-16, %rsp
    subq $0x20, %rsp
    leaq g_flinkname_us(%rip), %rcx
    call IoDeleteSymbolicLink
    movq %rbp, %rsp
    popq %rbp
    ret
    .seh_endproc

# ----------------------------------------------------------------------------- probe shims (leaf)
# void iii_kfo_cpuid(u32 leaf /rcx, u32 subleaf /rdx, u64 out4 /r8)  -> out4[0..3]=EAX,EBX,ECX,EDX
    .global L_p_iii_kfo_cpuid
    .seh_proc L_p_iii_kfo_cpuid
L_p_iii_kfo_cpuid:
    pushq %rbx
    .seh_pushreg %rbx
    .seh_endprologue
    movl %ecx, %eax              # leaf
    movl %edx, %ecx              # subleaf
    cpuid
    movl %eax, 0(%r8)
    movl %ebx, 4(%r8)
    movl %ecx, 8(%r8)
    movl %edx, 12(%r8)
    popq %rbx
    retq
    .seh_endproc

# u64 iii_kfo_readmsr(u32 msr /rcx) -> RDMSR result (EDX:EAX) in RAX. Caller ensures the MSR exists.
    .global L_p_iii_kfo_readmsr
    .seh_proc L_p_iii_kfo_readmsr
L_p_iii_kfo_readmsr:
    .seh_endprologue
    movl %ecx, %ecx             # MSR number in ECX
    rdmsr                        # -> EDX:EAX
    shlq $32, %rdx
    orq  %rdx, %rax              # RAX = (EDX<<32) | EAX
    retq
    .seh_endproc

# ----------------------------------------------------------------- PRIVILEGED WRITE primitive (leaf)
# void iii_kfo_writemsr(u32 msr /rcx, u64 value /rdx)  -> WRMSR MSR[ECX] = value
#   DANGEROUS: a wrong EFER/VM_CR write can wedge the CPU. The CALLER (gate_floor.iii SVM-DISABLE) does
#   the read-modify-write so only the SVME bit (12) changes; #19a writes EFER's CURRENT value (no-op).
    .global L_p_iii_kfo_writemsr
    .seh_proc L_p_iii_kfo_writemsr
L_p_iii_kfo_writemsr:
    .seh_endprologue
    movl %ecx, %ecx             # ECX = MSR number (RDMSR/WRMSR use ECX)
    movq %rdx, %rax             # RAX = value ; EAX = value[31:0]  (the low half WRMSR takes in EAX)
    movq %rdx, %r8
    shrq $32, %r8              # R8 = value[63:32]
    movl %r8d, %edx            # EDX = value[63:32]  (the high half WRMSR takes in EDX)
    wrmsr                        # MSR[ECX] = EDX:EAX
    retq
    .seh_endproc

# ----------------------------------------------------------------- per-core pinning ([S8] per-core SVM)
# u64 iii_kfo_pin_core(u64 affinity_mask /rcx) -> KeSetSystemAffinityThreadEx(mask); returns OLD affinity
    .global L_p_iii_kfo_pin_core
    .seh_proc L_p_iii_kfo_pin_core
L_p_iii_kfo_pin_core:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    .seh_endprologue
    andq $-16, %rsp
    subq $0x20, %rsp
    call KeSetSystemAffinityThreadEx   # rcx=mask (preserved) ; rax=old affinity
    movq %rbp, %rsp
    popq %rbp
    ret
    .seh_endproc

# void iii_kfo_unpin_core(u64 old_affinity /rcx) -> KeRevertToUserAffinityThreadEx(old)
    .global L_p_iii_kfo_unpin_core
    .seh_proc L_p_iii_kfo_unpin_core
L_p_iii_kfo_unpin_core:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    .seh_endprologue
    andq $-16, %rsp
    subq $0x20, %rsp
    call KeRevertToUserAffinityThreadEx   # rcx=old
    movq %rbp, %rsp
    popq %rbp
    ret
    .seh_endproc

# ------------------------------------------------- #19b: SVM region (contiguous, phys-addressable)
# u64 iii_kfo_alloc_contig(u64 bytes /rcx, u64 highest_phys /rdx)
#   -> MmAllocateContiguousMemory(bytes, highest); returns PVOID (0 on failure). PASSIVE_LEVEL.
#   highest_phys is a PHYSICAL_ADDRESS (LARGE_INTEGER, <=8B) -> passed by value in RDX. <4GB ensures the
#   SVM phys-addr fields (VM_HSAVE_PA, VMCB phys) can address it.
    .global L_p_iii_kfo_alloc_contig
    .seh_proc L_p_iii_kfo_alloc_contig
L_p_iii_kfo_alloc_contig:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    .seh_endprologue
    andq $-16, %rsp
    subq $0x20, %rsp
    call MmAllocateContiguousMemory   # rcx=bytes, rdx=highest
    movq %rbp, %rsp
    popq %rbp
    ret
    .seh_endproc

# u64 iii_kfo_phys_addr(u64 virt /rcx) -> MmGetPhysicalAddress(virt); PHYSICAL_ADDRESS (u64) in RAX
    .global L_p_iii_kfo_phys_addr
    .seh_proc L_p_iii_kfo_phys_addr
L_p_iii_kfo_phys_addr:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    .seh_endprologue
    andq $-16, %rsp
    subq $0x20, %rsp
    call MmGetPhysicalAddress         # rcx=virt ; returns LARGE_INTEGER (8B) in RAX
    movq %rbp, %rsp
    popq %rbp
    ret
    .seh_endproc

# void iii_kfo_free_contig(u64 virt /rcx) -> MmFreeContiguousMemory(virt). PASSIVE_LEVEL.
    .global L_p_iii_kfo_free_contig
    .seh_proc L_p_iii_kfo_free_contig
L_p_iii_kfo_free_contig:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    .seh_endprologue
    andq $-16, %rsp
    subq $0x20, %rsp
    call MmFreeContiguousMemory       # rcx=virt
    movq %rbp, %rsp
    popq %rbp
    ret
    .seh_endproc

# ---------------------------------------------- #19c-i: build the VMCB + NPT + guest code (NO VMRUN)
# void iii_kfo_build_vmcb(u64 region_virt /rcx, u64 region_phys /rdx)
#   Transcribes CHARIOT sma_pe_emit_platform.c CMD_INIT_SVM:1088-1335 (proven on this 7945HX), width-PRECISE
#   (dword/word/byte/qword) -- the reason this is hand-asm not cg_r0 (8-byte-uniform clobbers adjacent dword
#   fields). r15=region_virt (VMCB store base), r14=region_phys (computed phys values). NO SVM enable, NO
#   VMRUN -- only writes the region. Guest = 32-bit protected, NO paging (guest-linear=guest-phys -> NPT).
    .global L_p_iii_kfo_build_vmcb
    .seh_proc L_p_iii_kfo_build_vmcb
L_p_iii_kfo_build_vmcb:
    pushq %r14
    .seh_pushreg %r14
    pushq %r15
    .seh_pushreg %r15
    pushq %rdi
    .seh_pushreg %rdi
    .seh_endprologue
    movq %rcx, %r15                  # r15 = region_virt (store base)
    movq %rdx, %r14                  # r14 = region_phys

    # (a) zero the whole 256KB region ([S17] >= CHARIOT's 4KB; no garbage in MSRPM/IOPM/unused-NPT)
    movq %r15, %rdi
    xorl %eax, %eax
    movl $32768, %ecx                # 32768 qwords = 256 KB
    cld
    rep stosq

    # (b) VMCB control area (width-precise per [C15])
    movl $0xFFFFFFFF, 0x008(%r15)    # INTERCEPT_EXCEPTIONS
    movl $0x9906000F, 0x00C(%r15)    # INTERCEPT_MISC1
    movl $0x3F, 0x010(%r15)          # INTERCEPT_MISC2 (all 6 SVM instr incl VMRUN+VMMCALL)
    leaq 0xC000(%r14), %rax          # IOPM_BASE = phys + 0xC000
    movq %rax, 0x040(%r15)
    leaq 0xB000(%r14), %rax          # MSRPM_BASE = phys + 0xB000
    movq %rax, 0x048(%r15)
    movl $1, 0x058(%r15)             # GUEST_ASID = 1 (MUST be != 0)
    movl $1, 0x05C(%r15)             # TLB_CONTROL = 1
    movq $1, 0x090(%r15)             # NP_ENABLE = 1 (qword)
    leaq 0x2000(%r14), %rax          # N_CR3 = phys + 0x2000 (NPT PML4)
    movq %rax, 0x0B0(%r15)
    movl $0, 0x0C0(%r15)             # VMCB_CLEAN = 0

    # (c) state-save segments (32-bit protected; flat 4GB; CS attr 0x0C9B != data 0x0C93)
    movw $0x0010, 0x400(%r15)        # ES sel
    movw $0x0C93, 0x402(%r15)        # ES attr (data)
    movl $0xFFFFFFFF, 0x404(%r15)    # ES limit
    movw $0x0008, 0x410(%r15)        # CS sel
    movw $0x0C9B, 0x412(%r15)        # CS attr (CODE)
    movl $0xFFFFFFFF, 0x414(%r15)    # CS limit
    movw $0x0010, 0x420(%r15)        # SS sel
    movw $0x0C93, 0x422(%r15)        # SS attr
    movl $0xFFFFFFFF, 0x424(%r15)    # SS limit
    movw $0x0010, 0x430(%r15)        # DS sel
    movw $0x0C93, 0x432(%r15)        # DS attr
    movl $0xFFFFFFFF, 0x434(%r15)    # DS limit

    # (c) state-save scalars
    movq $0x1000, 0x4D0(%r15)        # EFER = SVME only (LME=0 -> 32-bit protected, not long mode)
    movq $0, 0x548(%r15)             # CR4 = 0 (no PAE)
    movq $0, 0x550(%r15)             # CR3 = 0 (no paging)
    movq $0x11, 0x558(%r15)          # CR0 = PE|ET (protected, no paging)
    movq $0x400, 0x560(%r15)         # DR7
    movl $0xFFFF0FF0, 0x568(%r15)    # DR6 (dword)
    movq $2, 0x570(%r15)             # RFLAGS (reserved bit 1)
    leaq 0xA000(%r14), %rax          # RIP = phys + 0xA000 (guest code)
    movq %rax, 0x578(%r15)
    leaq 0xAFE0(%r14), %rax          # RSP = phys + 0xAFE0
    movq %rax, 0x5D8(%r15)

    # (d) NPT identity map (first 4 GB, 2 MB pages)
    leaq 0x3000(%r14), %rax          # PML4[0] = (phys+0x3000) | 0x67
    orq $0x67, %rax
    movq %rax, 0x2000(%r15)
    leaq 0x4000(%r14), %rax          # PDPT[0] (0-1GB)
    orq $0x67, %rax
    movq %rax, 0x3000(%r15)
    leaq 0x5000(%r14), %rax          # PDPT[1] (1-2GB)
    orq $0x67, %rax
    movq %rax, 0x3008(%r15)
    leaq 0x6000(%r14), %rax          # PDPT[2] (2-3GB)
    orq $0x67, %rax
    movq %rax, 0x3010(%r15)
    leaq 0x7000(%r14), %rax          # PDPT[3] (3-4GB)
    orq $0x67, %rax
    movq %rax, 0x3018(%r15)
    leaq 0x4000(%r15), %rdi          # PD0 base (PD0..PD3 contiguous = 2048 entries)
    xorl %ecx, %ecx
L_bv_npt:
    movq %rcx, %rax
    shlq $21, %rax                   # i * 2 MB
    orq $0xE7, %rax                  # 2 MB leaf: P|RW|US|A|D|PS  (CHARIOT-proven, NOT 0xB7)
    movq %rax, (%rdi,%rcx,8)
    incl %ecx
    cmpl $2048, %ecx
    jb L_bv_npt

    # (e) guest code @ +0xA000: VMMCALL (0F 01 D9) + HLT (F4)
    movb $0x0F, 0xA000(%r15)
    movb $0x01, 0xA001(%r15)
    movb $0xD9, 0xA002(%r15)
    movb $0xF4, 0xA003(%r15)

    popq %rdi
    popq %r15
    popq %r14
    ret
    .seh_endproc

# ---------------------------------------------- #19c-ii: enable + the VMRUN bracket + EXITCODE (THE RUN)
# u64 iii_kfo_svm_vmrun(u64 region_virt /rcx, u64 region_phys /rdx) -> EXITCODE (VMCB control +0x070) in rax
#   Transcribes CHARIOT sma_pe_emit_platform.c:1338-1393 BYTE-IDENTICAL (proven -> EXITCODE 0x81 on this
#   7945HX). PRECONDITIONS (caller): the VMCB is already built (iii_kfo_build_vmcb) AND we are on a pinned
#   core (per-core SVM). r14=region_phys, r15=region_virt -- == CHARIOT's regs; both SURVIVE VMRUN because
#   the 1-instruction VMMCALL guest touches no GPR [Q2]. CLGI masks ALL interrupts (incl NMI) across the
#   bracket -> no preemption during VMRUN. The 5 SVM ops are raw .byte for byte-exactness vs CHARIOT.
    .global L_p_iii_kfo_svm_vmrun
    .seh_proc L_p_iii_kfo_svm_vmrun
L_p_iii_kfo_svm_vmrun:
    pushq %r14
    .seh_pushreg %r14
    pushq %r15
    .seh_pushreg %r15
    .seh_endprologue
    movq %rdx, %r14                  # r14 = region_phys (VMCB phys)
    movq %rcx, %r15                  # r15 = region_virt (VMCB virt; EXITCODE read after VMRUN)

    # (f) enable SVM on THIS core
    movl $0xC0000080, %ecx           # EFER
    rdmsr                            # EDX:EAX = EFER
    orl  $0x1000, %eax               # set SVME (bit 12)
    movl $0xC0000080, %ecx
    wrmsr
    # VM_HSAVE_PA = region_phys + 0x1000 (the HostSave area)
    leaq 0x1000(%r14), %rax
    movq %rax, %rdx
    shrq $32, %rdx                   # EDX = high32 ; EAX = low32 (phys+0x1000)
    movl $0xC0010117, %ecx           # VM_HSAVE_PA
    wrmsr

    # (g) the VMRUN bracket -- CHARIOT byte-identical (RAX = VMCB phys for vmsave/vmrun/vmload)
    movq %r14, %rax
    .byte 0x0F, 0x01, 0xDD           # CLGI   (mask all interrupts incl NMI)
    .byte 0x0F, 0x01, 0xDB           # VMSAVE rax  (save host extra-state)
    .byte 0x0F, 0x01, 0xD8           # VMRUN  rax  (run guest; #VMEXIT returns here)
    .byte 0x0F, 0x01, 0xDA           # VMLOAD rax  (restore host extra-state)
    .byte 0x0F, 0x01, 0xDC           # STGI   (unmask)

    # (h) read EXITCODE (VMCB control area + 0x070); 0x081 = VMEXIT_VMMCALL
    movq 0x070(%r15), %rax
    popq %r15
    popq %r14
    ret
    .seh_endproc

# ---------------------------------------------- #19c-ii-extra / I3-ii: the resume-loop primitives
# u64 iii_kfo_vmrun_once(u64 region_virt /rcx, u64 region_phys /rdx) -> EXITCODE in rax
#   The VMRUN bracket ONLY (NO enable, NO VM_HSAVE_PA -- the caller enables ONCE before the loop). For the
#   I3-ii resume loop: re-VMRUN repeatedly. r15=virt survives VMRUN (the guest touches no GPR). Bracket is
#   CHARIOT byte-identical (== iii_kfo_svm_vmrun's bracket).
    .global L_p_iii_kfo_vmrun_once
    .seh_proc L_p_iii_kfo_vmrun_once
L_p_iii_kfo_vmrun_once:
    pushq %r15
    .seh_pushreg %r15
    .seh_endprologue
    movq %rcx, %r15                  # r15 = region_virt (for EXITCODE)
    movq %rdx, %rax                  # rax = VMCB phys
    .byte 0x0F, 0x01, 0xDD           # CLGI
    .byte 0x0F, 0x01, 0xDB           # VMSAVE rax
    .byte 0x0F, 0x01, 0xD8           # VMRUN  rax
    .byte 0x0F, 0x01, 0xDA           # VMLOAD rax
    .byte 0x0F, 0x01, 0xDC           # STGI
    movq 0x070(%r15), %rax           # EXITCODE
    popq %r15
    retq
    .seh_endproc

# void iii_kfo_write_guest_loop(u64 region_virt /rcx)
#   Overwrite the guest code @ +0xA000 with the 2-VMMCALL resume-protocol guest (12 bytes):
#     mov eax,0 (B8 00000000) ; vmmcall (0F 01 D9) ; vmmcall (0F 01 D9) ; hlt (F4)
#   The verdict round-trips via the VMCB guest-RAX slot: host writes it after the 1st VMMCALL, VMRUN reloads
#   it on resume, the guest carries it (NO instruction between the two VMMCALLs) to the 2nd VMMCALL, host
#   reads it back. Avoids the guest having to address the runtime-varying region_phys-relative shared area.
    .global L_p_iii_kfo_write_guest_loop
    .seh_proc L_p_iii_kfo_write_guest_loop
L_p_iii_kfo_write_guest_loop:
    .seh_endprologue
    movb $0xB8, 0xA000(%rcx)         # mov eax, imm32
    movb $0x00, 0xA001(%rcx)
    movb $0x00, 0xA002(%rcx)
    movb $0x00, 0xA003(%rcx)
    movb $0x00, 0xA004(%rcx)
    movb $0x0F, 0xA005(%rcx)         # vmmcall
    movb $0x01, 0xA006(%rcx)
    movb $0xD9, 0xA007(%rcx)
    movb $0x0F, 0xA008(%rcx)         # vmmcall
    movb $0x01, 0xA009(%rcx)
    movb $0xD9, 0xA00A(%rcx)
    movb $0xF4, 0xA00B(%rcx)         # hlt
    retq
    .seh_endproc

# u64 iii_kfo_raise_dispatch() -> old IRQL  (KeRaiseIrqlToDpcLevel: prevents preemption across the loop)
    .global L_p_iii_kfo_raise_dispatch
    .seh_proc L_p_iii_kfo_raise_dispatch
L_p_iii_kfo_raise_dispatch:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    .seh_endprologue
    andq $-16, %rsp
    subq $0x20, %rsp
    call KeRaiseIrqlToDpcLevel       # -> old KIRQL in AL
    movzbl %al, %eax                 # zero-extend to RAX
    movq %rbp, %rsp
    popq %rbp
    ret
    .seh_endproc

# void iii_kfo_lower_irql(u64 old_irql /rcx) -> KeLowerIrql(old)
    .global L_p_iii_kfo_lower_irql
    .seh_proc L_p_iii_kfo_lower_irql
L_p_iii_kfo_lower_irql:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    .seh_endprologue
    andq $-16, %rsp
    subq $0x20, %rsp
    call KeLowerIrql                 # rcx=old (CL)
    movq %rbp, %rsp
    popq %rbp
    ret
    .seh_endproc

# ---------------------------------------------- Chunk B / [E7]: fault-as-data VMCB diag-copy
# void iii_kfo_copy_qwords(u64 dst /rcx, u64 src /rdx, u64 nq /r8)  -> rep movsq (nq qwords src->dst)
#   Used to copy the post-VMRUN VMCB (control 128q + state 64q = 1536 B) to R3 for forensics. RDI/RSI are
#   Win64 callee-saved -> saved/restored. No alignment needed (no call).
    .global L_p_iii_kfo_copy_qwords
    .seh_proc L_p_iii_kfo_copy_qwords
L_p_iii_kfo_copy_qwords:
    pushq %rdi
    .seh_pushreg %rdi
    pushq %rsi
    .seh_pushreg %rsi
    .seh_endprologue
    movq %rcx, %rdi                  # dst
    movq %rdx, %rsi                  # src
    movq %r8, %rcx                   # count (qwords)
    cld
    rep movsq
    popq %rsi
    popq %rdi
    retq
    .seh_endproc

# ---------------------------------------------- Chunk B / I3-iii: the guest AUTHORS its own request
# The 49-byte guest (32-bit protected, no paging). EAX = the shared-area GPA (the host sets it in the VMCB
# RAX before VMRUN). The guest writes its 6-value cycle request there (the OK case: family=2, target_kind=1,
# target=0x20000, action_hexad=728, cap_rights=0x200000, seal_mode=0), at 8-byte spacing (low dword; the
# host pre-zeroed the area so the high dwords are 0), then VMMCALL (request) / VMMCALL (done) / HLT.
    .section .rdata,"dr"
    .balign 16
g_i3iii_guest:
    .byte 0xC7,0x40,0x00,0x02,0x00,0x00,0x00     # mov dword [eax+0],  2          family
    .byte 0xC7,0x40,0x08,0x01,0x00,0x00,0x00     # mov dword [eax+8],  1          target_kind
    .byte 0xC7,0x40,0x10,0x00,0x00,0x02,0x00     # mov dword [eax+16], 0x20000    target
    .byte 0xC7,0x40,0x18,0xD8,0x02,0x00,0x00     # mov dword [eax+24], 728        action_hexad
    .byte 0xC7,0x40,0x20,0x00,0x00,0x20,0x00     # mov dword [eax+32], 0x200000   cap_rights
    .byte 0xC7,0x40,0x28,0x00,0x00,0x00,0x00     # mov dword [eax+40], 0          seal_mode
    .byte 0x0F,0x01,0xD9                          # vmmcall  (request)
    .byte 0x0F,0x01,0xD9                          # vmmcall  (done; RAX=verdict)
    .byte 0xF4                                    # hlt

    .text
# void iii_kfo_write_guest_request(u64 region_virt /rcx)  -> copy the 49-byte guest to region+0xA000
    .global L_p_iii_kfo_write_guest_request
    .seh_proc L_p_iii_kfo_write_guest_request
L_p_iii_kfo_write_guest_request:
    pushq %rdi
    .seh_pushreg %rdi
    pushq %rsi
    .seh_pushreg %rsi
    .seh_endprologue
    leaq 0xA000(%rcx), %rdi          # dst = region+0xA000 (guest code page)
    leaq g_i3iii_guest(%rip), %rsi   # src = the guest blob
    movl $49, %ecx                   # 49 bytes
    cld
    rep movsb
    popq %rsi
    popq %rdi
    retq
    .seh_endproc
