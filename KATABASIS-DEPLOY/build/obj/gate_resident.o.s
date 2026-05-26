# III Stage-0 Ring-0 codegen output (Windows kernel-mode .sys)
# Output binary: iiis-0.sys
    .att_syntax
    .section .rdata,"dr"
L_str_0:
    .ascii "xii_term.iiicapability.iiicapability.iiicycle_term.iiicycle_term.iiiseal.iiiadmit.iiisha256.iiikeccak.iii\0"
L_str_1:
    .ascii "capability.iiicapability.iiicycle_term.iiicycle_term.iiiseal.iiiadmit.iiisha256.iiikeccak.iii\0"
L_str_2:
    .ascii "capability.iiicycle_term.iiicycle_term.iiiseal.iiiadmit.iiisha256.iiikeccak.iii\0"
L_str_3:
    .ascii "cycle_term.iiicycle_term.iiiseal.iiiadmit.iiisha256.iiikeccak.iii\0"
L_str_4:
    .ascii "cycle_term.iiiseal.iiiadmit.iiisha256.iiikeccak.iii\0"
L_str_5:
    .ascii "seal.iiiadmit.iiisha256.iiikeccak.iii\0"
L_str_6:
    .ascii "admit.iiisha256.iiikeccak.iii\0"
L_str_7:
    .ascii "sha256.iiikeccak.iii\0"
L_str_8:
    .ascii "keccak.iii\0"
    .section .bss
    .global L_p_G_SEAL
L_p_G_SEAL:
    .zero 256
    .global L_p_G_WRONG
L_p_G_WRONG:
    .zero 256
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
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_sha256_sched_force
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_keccak_chi_force_path
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq L_p_xii_term_arena_reset
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq L_p_cap_env_init
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x200000, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %r8
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_cap_attenuate
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x800000, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %r8
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_cap_attenuate
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x20000, %rax
    pushq %rax
    movabsq $0x2d8, %rax
    pushq %rax
    popq %r9
    popq %r8
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_katabasis_cycle_act
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq -48(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_katabasis_cycle_under_cap
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq -56(%rbp), %rax
    pushq %rax
    leaq L_p_G_SEAL(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_katabasis_cycle_seal
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -56(%rbp), %rax
    pushq %rax
    leaq L_p_G_SEAL(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_katabasis_gate_admit
    addq $32, %rsp
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_1
    movabsq $0xc00000e1, %rax
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
L_if_end_1:
    movabsq $0x9, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xfb000000, %rax
    pushq %rax
    movabsq $0x2d8, %rax
    pushq %rax
    popq %r9
    popq %r8
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_katabasis_cycle_act
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movq -64(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_katabasis_cycle_under_cap
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movq -72(%rbp), %rax
    pushq %rax
    leaq L_p_G_WRONG(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_katabasis_cycle_seal
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -56(%rbp), %rax
    pushq %rax
    leaq L_p_G_WRONG(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_katabasis_gate_admit
    addq $32, %rsp
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_3
    movabsq $0xc00000e2, %rax
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
L_if_end_3:
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x20000, %rax
    pushq %rax
    movabsq $0x2d8, %rax
    pushq %rax
    popq %r9
    popq %r8
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_katabasis_cycle_act
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -80(%rbp)
    movq -80(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_katabasis_cycle_under_cap
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
    movq -88(%rbp), %rax
    pushq %rax
    leaq L_p_G_SEAL(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_katabasis_cycle_seal
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -88(%rbp), %rax
    pushq %rax
    leaq L_p_G_SEAL(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_katabasis_gate_admit
    addq $32, %rsp
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_5
    movabsq $0xc00000e3, %rax
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
L_if_end_5:
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x1000, %rax
    pushq %rax
    movabsq $0x2d8, %rax
    pushq %rax
    popq %r9
    popq %r8
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_katabasis_cycle_act
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -96(%rbp)
    movq -96(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_katabasis_cycle_under_cap
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -104(%rbp)
    movq -104(%rbp), %rax
    pushq %rax
    leaq L_p_G_SEAL(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_katabasis_cycle_seal
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -104(%rbp), %rax
    pushq %rax
    leaq L_p_G_SEAL(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_katabasis_gate_admit
    addq $32, %rsp
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_7
    movabsq $0xc00000e4, %rax
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
L_if_end_7:
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
