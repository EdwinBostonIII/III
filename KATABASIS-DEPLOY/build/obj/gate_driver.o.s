# III Stage-0 Ring-0 codegen output (Windows kernel-mode .sys)
# Output binary: iiis-0.sys
    .att_syntax
    .section .rdata,"dr"
L_str_0:
    .ascii "kernel_abi.skernel_abi.skernel_abi.skernel_abi.skernel_abi.skernel_abi.skernel_abi.sxii_term.iiicapability.iiicapability.iiicycle_term.iiicycle_term.iiiseal.iiiadmit.iiisha256.iiikeccak.iii\0"
L_str_1:
    .ascii "kernel_abi.skernel_abi.skernel_abi.skernel_abi.skernel_abi.skernel_abi.sxii_term.iiicapability.iiicapability.iiicycle_term.iiicycle_term.iiiseal.iiiadmit.iiisha256.iiikeccak.iii\0"
L_str_2:
    .ascii "kernel_abi.skernel_abi.skernel_abi.skernel_abi.skernel_abi.sxii_term.iiicapability.iiicapability.iiicycle_term.iiicycle_term.iiiseal.iiiadmit.iiisha256.iiikeccak.iii\0"
L_str_3:
    .ascii "kernel_abi.skernel_abi.skernel_abi.skernel_abi.sxii_term.iiicapability.iiicapability.iiicycle_term.iiicycle_term.iiiseal.iiiadmit.iiisha256.iiikeccak.iii\0"
L_str_4:
    .ascii "kernel_abi.skernel_abi.skernel_abi.sxii_term.iiicapability.iiicapability.iiicycle_term.iiicycle_term.iiiseal.iiiadmit.iiisha256.iiikeccak.iii\0"
L_str_5:
    .ascii "kernel_abi.skernel_abi.sxii_term.iiicapability.iiicapability.iiicycle_term.iiicycle_term.iiiseal.iiiadmit.iiisha256.iiikeccak.iii\0"
L_str_6:
    .ascii "kernel_abi.sxii_term.iiicapability.iiicapability.iiicycle_term.iiicycle_term.iiiseal.iiiadmit.iiisha256.iiikeccak.iii\0"
L_str_7:
    .ascii "xii_term.iiicapability.iiicapability.iiicycle_term.iiicycle_term.iiiseal.iiiadmit.iiisha256.iiikeccak.iii\0"
L_str_8:
    .ascii "capability.iiicapability.iiicycle_term.iiicycle_term.iiiseal.iiiadmit.iiisha256.iiikeccak.iii\0"
L_str_9:
    .ascii "capability.iiicycle_term.iiicycle_term.iiiseal.iiiadmit.iiisha256.iiikeccak.iii\0"
L_str_10:
    .ascii "cycle_term.iiicycle_term.iiiseal.iiiadmit.iiisha256.iiikeccak.iii\0"
L_str_11:
    .ascii "cycle_term.iiiseal.iiiadmit.iiisha256.iiikeccak.iii\0"
L_str_12:
    .ascii "seal.iiiadmit.iiisha256.iiikeccak.iii\0"
L_str_13:
    .ascii "admit.iiisha256.iiikeccak.iii\0"
L_str_14:
    .ascii "sha256.iiikeccak.iii\0"
L_str_15:
    .ascii "keccak.iii\0"
    .section .bss
    .global L_p_G_DEVOBJ
L_p_G_DEVOBJ:
    .zero 8
    .global L_p_G_SEAL
L_p_G_SEAL:
    .zero 256
    .global L_p_G_WRONG
L_p_G_WRONG:
    .zero 256
    .global L_p_G_CPUID
L_p_G_CPUID:
    .zero 16
    .section .text,"xr"  /* PE/COFF Â§6 */
    /* IRQL_REQUIRES_MAX(2) */
    .global L_p_wdm_current_stack
L_p_wdm_current_stack:
    .seh_proc L_p_wdm_current_stack
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    /* witness enter (D9, ADR-024) */
    movq $1, %rcx  /* IIIW_ENTER */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x17, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
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
    .section .text,"xr"  /* PE/COFF Â§6 */
    /* IRQL_REQUIRES_MAX(2) */
    .global L_p_wdm_ioctl_code
L_p_wdm_ioctl_code:
    .seh_proc L_p_wdm_ioctl_code
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    /* witness enter (D9, ADR-024) */
    movq $1, %rcx  /* IIIW_ENTER */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
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
    .section .text,"xr"  /* PE/COFF Â§6 */
    /* IRQL_REQUIRES_MAX(2) */
    .global L_p_wdm_system_buffer
L_p_wdm_system_buffer:
    .seh_proc L_p_wdm_system_buffer
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    /* witness enter (D9, ADR-024) */
    movq $1, %rcx  /* IIIW_ENTER */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
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
    .section .text,"xr"  /* PE/COFF Â§6 */
    /* IRQL_REQUIRES_MAX(2) */
    .global L_p_wdm_set_status
L_p_wdm_set_status:
    .seh_proc L_p_wdm_set_status
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movq %r8, -24(%rbp)
    /* witness enter (D9, ADR-024) */
    movq $1, %rcx  /* IIIW_ENTER */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movq -24(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x0, %rax
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
    .section .text,"xr"  /* PE/COFF Â§6 */
    /* IRQL_REQUIRES_MAX(2) */
    .global L_p_gate_create
L_p_gate_create:
    .seh_proc L_p_gate_create
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
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %r8
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_wdm_set_status
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_iii_kio_complete_request
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
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
    .section .text,"xr"  /* PE/COFF Â§6 */
    /* IRQL_REQUIRES_MAX(2) */
    .global L_p_gate_close
L_p_gate_close:
    .seh_proc L_p_gate_close
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
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %r8
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_wdm_set_status
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_iii_kio_complete_request
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
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
    .section .text,"xr"  /* PE/COFF Â§6 */
    /* IRQL_REQUIRES_MAX(2) */
    .global L_p_gate_ioctl
L_p_gate_ioctl:
    .seh_proc L_p_gate_ioctl
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
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_wdm_current_stack
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_wdm_ioctl_code
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_wdm_system_buffer
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movabsq $0xc0000010, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x222000, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_1
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -80(%rbp)
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -96(%rbp)
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -104(%rbp)
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
    movq %rax, -112(%rbp)
    movq -112(%rbp), %rax
    pushq %rax
    movq -96(%rbp), %rax
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
    movq %rax, -120(%rbp)
    movq -64(%rbp), %rax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    movq -80(%rbp), %rax
    pushq %rax
    movq -88(%rbp), %rax
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
    movq %rax, -128(%rbp)
    movq -128(%rbp), %rax
    pushq %rax
    movq -120(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_katabasis_cycle_under_cap
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -136(%rbp)
    movq -136(%rbp), %rax
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
    leaq L_p_G_SEAL(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -144(%rbp)
    movq -104(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_3
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
    movq %rax, -152(%rbp)
    movq -152(%rbp), %rax
    pushq %rax
    movq -120(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_katabasis_cycle_under_cap
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -160(%rbp)
    movq -160(%rbp), %rax
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
    leaq L_p_G_WRONG(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -144(%rbp)
L_if_end_3:
    movq -136(%rbp), %rax
    pushq %rax
    movq -144(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_katabasis_gate_admit
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -168(%rbp)
    movq -168(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movabsq $0x8, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
L_if_end_1:
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x222004, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_5
    movabsq $0x80000001, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    leaq L_p_G_CPUID(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %r8
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_iii_kio_cpuid
    addq $32, %rsp
    pushq %rax
    popq %rax
    leaq L_p_G_CPUID(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -176(%rbp)
    movq -176(%rbp), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    shrq %cl, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -184(%rbp)
    movabsq $0xc0000080, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_iii_kio_readmsr
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -192(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -200(%rbp)
    movq -184(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_7
    movabsq $0xc0010114, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_iii_kio_readmsr
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -200(%rbp)
L_if_end_7:
    movq -184(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movq -192(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movq -200(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movq -176(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movabsq $0x20, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
L_if_end_5:
    movq -16(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    popq %r8
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_wdm_set_status
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_iii_kio_complete_request
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -48(%rbp), %rax
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
    .section .text,"xr"  /* PE/COFF Â§6 */
    /* IRQL_REQUIRES_MAX(2) */
    .global L_p_gate_unload
L_p_gate_unload:
    .seh_proc L_p_gate_unload
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    /* witness enter (D9, ADR-024) */
    movq $1, %rcx  /* IIIW_ENTER */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    subq $32, %rsp
    callq L_p_iii_kio_delete_symlink
    addq $32, %rsp
    pushq %rax
    popq %rax
    leaq L_p_G_DEVOBJ(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_iii_kio_delete_device
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
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
    movq -8(%rbp), %rax
    pushq %rax
    leaq L_p_G_DEVOBJ(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_iii_kio_create_device
    addq $32, %rsp
    pushq %rax
    popq %rax
    leaq L_p_gate_unload(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    leaq L_p_gate_create(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0xe, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    leaq L_p_gate_close(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    leaq L_p_gate_ioctl(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x1c, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    subq $32, %rsp
    callq L_p_iii_kio_create_symlink
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
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
