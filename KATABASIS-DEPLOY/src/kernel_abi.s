# kernel_abi.s -- KATABASIS hand-asm ntoskrnl marshalling shims + fixed device names (Chunk 1b/3).
#
# The .iii gate (cg_r0) calls these via L_p_iii_kio_* (snake_case -> cg_r0 L_p_ prefix). Each shim:
#   * rbp frame -> SEH-unwindable (valid .pdata/.xdata),
#   * `andq $-16,%rsp` -> robust, DEPTH-INDEPENDENT 16-byte alignment (cg_r0's stack-depth track
#     is unreliable: witness-hook pushes bypass it),
#   * full Win64 marshalling incl. IoCreateDevice's 7 args (rcx/rdx/r8/r9 + 3 stack args above
#     the 0x20 shadow), then calls ntoskrnl, then restores rsp from rbp.
#
# The device + symlink NAMES are baked here as packed UTF-16 (.short, contiguous) + their
# UNICODE_STRING headers, because cg_r0's 8-byte-uniform arrays cannot lay out contiguous 2-byte
# chars. Fixed names -> the .iii driver passes no strings. Pure dumb metal; gate logic stays .iii.
#
# Only rbp is touched of the callee-saved set (saved/restored). ntoskrnl symbols referenced BARE
# -> ld + libntoskrnl.a synthesize the PE import directory + IAT.

    .att_syntax

# ----------------------------------------------------------------------------- names (.rdata)
    .section .rdata,"dr"
    .balign 2
g_devname_buf:                 # L"\Device\IIIKatabasisGate\0"  (24 chars + NUL)
    .short 0x5C,0x44,0x65,0x76,0x69,0x63,0x65,0x5C
    .short 0x49,0x49,0x49,0x4B,0x61,0x74,0x61,0x62,0x61,0x73,0x69,0x73,0x47,0x61,0x74,0x65,0x00
g_linkname_buf:                # L"\??\IIIKatabasisGate\0"  (20 chars + NUL)
    .short 0x5C,0x3F,0x3F,0x5C
    .short 0x49,0x49,0x49,0x4B,0x61,0x74,0x61,0x62,0x61,0x73,0x69,0x73,0x47,0x61,0x74,0x65,0x00
    .balign 8
g_devname_us:                  # UNICODE_STRING { Length=48, MaximumLength=50, pad, Buffer }
    .short 48
    .short 50
    .long 0
    .quad g_devname_buf
    .balign 8
g_linkname_us:                 # UNICODE_STRING { Length=40, MaximumLength=42, pad, Buffer }
    .short 40
    .short 42
    .long 0
    .quad g_linkname_buf

# ----------------------------------------------------------------------------- shims (.text)
    .text

# NTSTATUS iii_kio_create_device(PDRIVER_OBJECT drv /rcx, PDEVICE_OBJECT* out /rdx)
#   -> IoCreateDevice(drv, 0, &g_devname_us, FILE_DEVICE_UNKNOWN(0x22), 0, FALSE, out)
    .global L_p_iii_kio_create_device
    .seh_proc L_p_iii_kio_create_device
L_p_iii_kio_create_device:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    .seh_endprologue
    andq $-16, %rsp
    subq $0x40, %rsp                # 0x20 shadow + 3 stack args (rounded to 16)
    movq %rdx, %r10                 # save out
    # rcx = drv (arg1, keep)
    xorl %edx, %edx                 # arg2 DeviceExtensionSize = 0
    leaq g_devname_us(%rip), %r8    # arg3 DeviceName
    movl $0x22, %r9d                # arg4 DeviceType = FILE_DEVICE_UNKNOWN
    movq $0, 0x20(%rsp)             # arg5 DeviceCharacteristics = 0
    movq $0, 0x28(%rsp)             # arg6 Exclusive = FALSE
    movq %r10, 0x30(%rsp)           # arg7 DeviceObject (out)
    call IoCreateDevice
    movq %rbp, %rsp
    popq %rbp
    ret
    .seh_endproc

# NTSTATUS iii_kio_create_symlink(void)  -> IoCreateSymbolicLink(&g_linkname_us, &g_devname_us)
    .global L_p_iii_kio_create_symlink
    .seh_proc L_p_iii_kio_create_symlink
L_p_iii_kio_create_symlink:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    .seh_endprologue
    andq $-16, %rsp
    subq $0x20, %rsp
    leaq g_linkname_us(%rip), %rcx
    leaq g_devname_us(%rip), %rdx
    call IoCreateSymbolicLink
    movq %rbp, %rsp
    popq %rbp
    ret
    .seh_endproc

# void iii_kio_complete_request(PIRP irp /rcx, CCHAR boost /rdx)  -> IoCompleteRequest(irp, boost)
    .global L_p_iii_kio_complete_request
    .seh_proc L_p_iii_kio_complete_request
L_p_iii_kio_complete_request:
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

# void iii_kio_delete_device(PDEVICE_OBJECT dev /rcx)  -> IoDeleteDevice(dev)
    .global L_p_iii_kio_delete_device
    .seh_proc L_p_iii_kio_delete_device
L_p_iii_kio_delete_device:
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

# NTSTATUS iii_kio_delete_symlink(void)  -> IoDeleteSymbolicLink(&g_linkname_us)
    .global L_p_iii_kio_delete_symlink
    .seh_proc L_p_iii_kio_delete_symlink
L_p_iii_kio_delete_symlink:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    .seh_endprologue
    andq $-16, %rsp
    subq $0x20, %rsp
    leaq g_linkname_us(%rip), %rcx
    call IoDeleteSymbolicLink
    movq %rbp, %rsp
    popq %rbp
    ret
    .seh_endproc

# ---- Ring-1 I0 read-only probe shims (no SVM state change) ----
# void iii_kio_cpuid(u32 leaf /rcx, u32 subleaf /rdx, u64 out4 /r8)
#   out4[0..3] (packed u32) = EAX,EBX,ECX,EDX. CPUID is unprivileged + cannot fault. Saves RBX.
    .global L_p_iii_kio_cpuid
    .seh_proc L_p_iii_kio_cpuid
L_p_iii_kio_cpuid:
    pushq %rbx
    .seh_pushreg %rbx
    .seh_endprologue
    movl %ecx, %eax              # leaf
    movl %edx, %ecx              # subleaf  (set EAX from ECX first, then overwrite ECX)
    cpuid                        # -> EAX,EBX,ECX,EDX ; R8 (out ptr) preserved
    movl %eax, 0(%r8)
    movl %ebx, 4(%r8)
    movl %ecx, 8(%r8)
    movl %edx, 12(%r8)
    popq %rbx
    retq
    .seh_endproc

# u64 iii_kio_readmsr(u32 msr /rcx) -> RDMSR result (EDX:EAX) in RAX.
#   PRIVILEGED (Ring 0). The CALLER must ensure the MSR exists (RDMSR #GPs on an invalid MSR):
#   the I0 handler reads only EFER (always present) and, gated behind the SVM CPUID bit, VM_CR.
    .global L_p_iii_kio_readmsr
    .seh_proc L_p_iii_kio_readmsr
L_p_iii_kio_readmsr:
    .seh_endprologue
    movl %ecx, %ecx             # MSR number in ECX (RDMSR reads ECX)
    rdmsr                        # -> EDX:EAX  (writing EAX zero-extends RAX)
    shlq $32, %rdx
    orq  %rdx, %rax              # RAX = (EDX<<32) | EAX
    retq
    .seh_endproc
