# III Stage-0 Ring-0 codegen output (Windows kernel-mode .sys)
# Output binary: iiis-0.sys
    .att_syntax
    .section .rdata,"dr"
L_str_0:
    .ascii "ntoskrnlntoskrnl\0"
L_str_1:
    .ascii "ntoskrnl\0"
    .section .text,"xr"  /* PE/COFF Â§6 */
    /* IRQL_REQUIRES_MAX(2) */
    .global L_p_driver_entry
    .global DriverEntry
L_p_driver_entry:
DriverEntry:
    .seh_proc L_p_driver_entry
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    /* witness enter (D9, ADR-024) */
    movq $1, %rcx  /* IIIW_ENTER */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq IoDeleteSymbolicLink
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq IoDeleteDevice
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0xc00000bb, %rax
    pushq %rax
    popq %rax
    pushq %rax
    pushq %rax
    movq $2, %rcx  /* IIIW_EXIT */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    popq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .rdata,"dr"  /* D2: IRP dispatch */
    .global _iii_IrpDispatchTable
_iii_IrpDispatchTable:
    .quad _iii_IrpNotImplemented  /* IRP_MJ=0x0 */
    .quad _iii_IrpNotImplemented  /* IRP_MJ=0x1 */
    .quad _iii_IrpNotImplemented  /* IRP_MJ=0x2 */
    .quad _iii_IrpNotImplemented  /* IRP_MJ=0x3 */
    .quad _iii_IrpNotImplemented  /* IRP_MJ=0x4 */
    .quad _iii_IrpNotImplemented  /* IRP_MJ=0x5 */
    .quad _iii_IrpNotImplemented  /* IRP_MJ=0x6 */
    .quad _iii_IrpNotImplemented  /* IRP_MJ=0x7 */
    .quad _iii_IrpNotImplemented  /* IRP_MJ=0x8 */
    .quad _iii_IrpNotImplemented  /* IRP_MJ=0x9 */
    .quad _iii_IrpNotImplemented  /* IRP_MJ=0xa */
    .quad _iii_IrpNotImplemented  /* IRP_MJ=0xb */
    .quad _iii_IrpNotImplemented  /* IRP_MJ=0xc */
    .quad _iii_IrpNotImplemented  /* IRP_MJ=0xd */
    .quad _iii_IrpNotImplemented  /* IRP_MJ=0xe */
    .quad _iii_IrpNotImplemented  /* IRP_MJ=0xf */
    .quad _iii_IrpNotImplemented  /* IRP_MJ=0x10 */
    .quad _iii_IrpNotImplemented  /* IRP_MJ=0x11 */
    .quad _iii_IrpNotImplemented  /* IRP_MJ=0x12 */
    .quad _iii_IrpNotImplemented  /* IRP_MJ=0x13 */
    .quad _iii_IrpNotImplemented  /* IRP_MJ=0x14 */
    .quad _iii_IrpNotImplemented  /* IRP_MJ=0x15 */
    .quad _iii_IrpNotImplemented  /* IRP_MJ=0x16 */
    .quad _iii_IrpNotImplemented  /* IRP_MJ=0x17 */
    .quad _iii_IrpNotImplemented  /* IRP_MJ=0x18 */
    .quad _iii_IrpNotImplemented  /* IRP_MJ=0x19 */
    .quad _iii_IrpNotImplemented  /* IRP_MJ=0x1a */
    .quad _iii_IrpNotImplemented  /* IRP_MJ=0x1b */
    .section .text
    .weak _iii_IrpNotImplemented  /* D12 */
_iii_IrpNotImplemented:
    movabsq $0xC00000BB, %rax  /* STATUS_NOT_SUPPORTED */
    retq
