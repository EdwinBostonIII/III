# III Stage-0 Ring-0 codegen output (Windows kernel-mode .sys)
# Output binary: iiis-0.sys
    .att_syntax
    .section .rdata,"dr"
L_str_0:
    .ascii "kernel_abi.s\0"
L_str_1:
    .ascii "kernel_abi.s\0"
L_str_2:
    .ascii "kernel_abi.s\0"
L_str_3:
    .ascii "kernel_abi.s\0"
L_str_4:
    .ascii "kernel_abi.s\0"
L_str_5:
    .ascii "kernel_abi.s\0"
L_str_6:
    .ascii "kernel_abi.s\0"
L_str_7:
    .ascii "kernel_abi.s\0"
L_str_8:
    .ascii "pci_enum.iii\0"
L_str_9:
    .ascii "pci_enum.iii\0"
L_str_10:
    .ascii "pci_enum.iii\0"
L_str_11:
    .ascii "pci_enum.iii\0"
L_str_12:
    .ascii "pci_enum.iii\0"
L_str_13:
    .ascii "pci_enum.iii\0"
L_str_14:
    .ascii "pci_enum.iii\0"
L_str_15:
    .ascii "behavioral_seed_kernel.iii\0"
L_str_16:
    .ascii "behavioral_seed_kernel.iii\0"
L_str_17:
    .ascii "behavioral_fp_kernel.iii\0"
L_str_18:
    .ascii "descent_proof_kernel.iii\0"
L_str_19:
    .ascii "descent_proof_kernel.iii\0"
L_str_20:
    .ascii "voice_kernel.iii\0"
L_str_21:
    .ascii "crystal_cap_kernel.iii\0"
L_str_22:
    .ascii "crystal_cap_kernel.iii\0"
L_str_23:
    .ascii "stage_kernel.iii\0"
L_str_24:
    .ascii "tense_kernel.iii\0"
L_str_25:
    .ascii "xii_term.iii\0"
L_str_26:
    .ascii "capability.iii\0"
L_str_27:
    .ascii "capability.iii\0"
L_str_28:
    .ascii "cycle_term.iii\0"
L_str_29:
    .ascii "cycle_term.iii\0"
L_str_30:
    .ascii "seal.iii\0"
L_str_31:
    .ascii "admit.iii\0"
L_str_32:
    .ascii "sha256.iii\0"
L_str_33:
    .ascii "keccak.iii\0"
L_str_34:
    .ascii "quine_seal.iii\0"
L_str_35:
    .ascii "quine_seal.iii\0"
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
    .global L_p_G_ATTEST
L_p_G_ATTEST:
    .zero 32
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
    movl %eax, %eax
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
    .global L_p_wdm_out_len
L_p_wdm_out_len:
    .seh_proc L_p_wdm_out_len
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
    .global L_p_wdm_in_len
L_p_wdm_in_len:
    .seh_proc L_p_wdm_in_len
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
    movabsq $0x2, %rax
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
    .global L_p_gate_validated_code
L_p_gate_validated_code:
    .seh_proc L_p_gate_validated_code
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
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movl -24(%rbp), %eax
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
    movabsq $0x8, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movabsq $0x30, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
L_if_end_1:
    movl -24(%rbp), %eax
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
    jz L_if_end_3
    movabsq $0x20, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
L_if_end_3:
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x222008, %rax
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
    movabsq $0x20, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
L_if_end_5:
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x22200c, %rax
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
    movabsq $0x38, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
L_if_end_7:
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x222010, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_9
    movabsq $0x8, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
L_if_end_9:
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x222014, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_11
    movabsq $0x10, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movabsq $0x20, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
L_if_end_11:
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x222018, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_13
    movabsq $0x20, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
L_if_end_13:
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x22201c, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_15
    movabsq $0x10, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movabsq $0x8, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
L_if_end_15:
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x222020, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_17
    movabsq $0x8, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movabsq $0x18, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
L_if_end_17:
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x222024, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_19
    movabsq $0x20, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
L_if_end_19:
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_21
    movl -24(%rbp), %eax
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
L_if_end_21:
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_23
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
L_if_end_23:
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_wdm_out_len
    addq $32, %rsp
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_25
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
L_if_end_25:
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_wdm_in_len
    addq $32, %rsp
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_27
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
L_if_end_27:
    movl -24(%rbp), %eax
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
    .global L_p_gate_attest_report
L_p_gate_attest_report:
    .seh_proc L_p_gate_attest_report
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
    popq %rax
    movq %rax, -16(%rbp)
    leaq L_p_G_ATTEST(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    leaq L_p_G_ATTEST(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    leaq L_p_G_ATTEST(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    leaq L_p_G_ATTEST(%rip), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -16(%rbp), %rax
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
    .global L_p_gate_self_attest
L_p_gate_self_attest:
    .seh_proc L_p_gate_self_attest
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
    popq %rax
    movq %rax, -16(%rbp)
    subq $32, %rsp
    callq L_p_ks_engine_ok
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
    jz L_if_end_29
    movabsq $0xc0000001, %rax
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
L_if_end_29:
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    leaq L_p_G_ATTEST(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_ks_self_measure
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
    .global L_p_pci_cfg
L_p_pci_cfg:
    .seh_proc L_p_pci_cfg
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
    movabsq $0x80000000, %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0xfc, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_iii_kio_pci_cfg_read
    addq $32, %rsp
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
    .global L_p_pci_probe_at
L_p_pci_probe_at:
    .seh_proc L_p_pci_probe_at
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
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_pci_cfg
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movl -16(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_pci_present
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
    jz L_if_end_31
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
L_if_end_31:
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_pci_cfg
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movl -24(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_pci_class
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
    jz L_if_end_33
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
L_if_end_33:
    movabsq $0x1, %rax
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
    .global L_p_pci_scan_bus
L_p_pci_scan_bus:
    .seh_proc L_p_pci_scan_bus
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
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
L_for_top_34:
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x20, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setl %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_for_end_35
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_37
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
L_for_top_38:
    movl -32(%rbp), %eax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setl %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_for_end_39
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_41
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    popq %rcx
    popq %rax
    shlq %cl, %rax
    movl %eax, %eax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    popq %rcx
    popq %rax
    shlq %cl, %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    shlq %cl, %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movl -40(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_pci_probe_at
    addq $32, %rsp
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
    jz L_if_end_43
    movl -40(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
L_if_end_43:
L_if_end_41:
    movl -32(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    jmp L_for_top_38
L_for_end_39:
L_if_end_37:
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    jmp L_for_top_34
L_for_end_35:
    movl -16(%rbp), %eax
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
    .global L_p_pci_find_gpu_bdf
L_p_pci_find_gpu_bdf:
    .seh_proc L_p_pci_find_gpu_bdf
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    /* witness enter (D9, ADR-024) */
    movq $1, %rcx  /* IIIW_ENTER */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
L_for_top_44:
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x100, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setl %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_for_end_45
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_47
    movl -16(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_pci_scan_bus
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_49
    movl -24(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
L_if_end_49:
L_if_end_47:
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    jmp L_for_top_44
L_for_end_45:
    movl -8(%rbp), %eax
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
    .global L_p_pci_report
L_p_pci_report:
    .seh_proc L_p_pci_report
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
    popq %rax
    movq %rax, -24(%rbp)
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_pci_cfg
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_pci_cfg
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movl -32(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_pci_vendor
    addq $32, %rsp
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    popq %rcx
    popq %rax
    shlq %cl, %rax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_pci_device
    addq $32, %rsp
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movl -40(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_pci_rev
    addq $32, %rsp
    pushq %rax
    popq %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_pci_cfg
    addq $32, %rsp
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_pci_bar_base32
    addq $32, %rsp
    pushq %rax
    popq %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_pci_cfg
    addq $32, %rsp
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0x18, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_pci_cfg
    addq $32, %rsp
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_pci_bar_base64
    addq $32, %rsp
    pushq %rax
    popq %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0x1c, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_pci_cfg
    addq $32, %rsp
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0x20, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_pci_cfg
    addq $32, %rsp
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_pci_bar_base64
    addq $32, %rsp
    pushq %rax
    popq %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movl -8(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x6, %rax
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
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_wdm_system_buffer
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movabsq $0xc0000010, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_wdm_ioctl_code
    addq $32, %rsp
    pushq %rax
    popq %r8
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_gate_validated_code
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movl -56(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_51
    movabsq $0xc0000023, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
L_if_end_51:
    movl -56(%rbp), %eax
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
    jz L_if_end_53
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -80(%rbp)
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -96(%rbp)
    movq -32(%rbp), %rax
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
    movl -64(%rbp), %eax
    pushq %rax
    movl -72(%rbp), %eax
    pushq %rax
    movq -80(%rbp), %rax
    pushq %rax
    movl -88(%rbp), %eax
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
    movl -128(%rbp), %eax
    pushq %rax
    movq -120(%rbp), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_katabasis_cycle_under_cap
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -136(%rbp)
    movl -136(%rbp), %eax
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
    jz L_if_end_55
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
    movl -152(%rbp), %eax
    pushq %rax
    movq -120(%rbp), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_katabasis_cycle_under_cap
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -160(%rbp)
    movl -160(%rbp), %eax
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
L_if_end_55:
    movl -136(%rbp), %eax
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
    movl -168(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movq -32(%rbp), %rax
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
    movq %rax, -40(%rbp)
    movabsq $0x8, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
L_if_end_53:
    movl -56(%rbp), %eax
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
    jz L_if_end_57
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
    jz L_if_end_59
    movabsq $0xc0010114, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_iii_kio_readmsr
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -200(%rbp)
L_if_end_59:
    movq -184(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -32(%rbp), %rax
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
    movq -32(%rbp), %rax
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
    movq -32(%rbp), %rax
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
    movq -32(%rbp), %rax
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
    movq %rax, -40(%rbp)
    movabsq $0x20, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
L_if_end_57:
    movl -56(%rbp), %eax
    pushq %rax
    movabsq $0x222008, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_61
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_gate_attest_report
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movabsq $0x20, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
L_if_end_61:
    movl -56(%rbp), %eax
    pushq %rax
    movabsq $0x22200c, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_63
    subq $32, %rsp
    callq L_p_pci_find_gpu_bdf
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -208(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movl -208(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_65
    movl -208(%rbp), %eax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_pci_report
    addq $32, %rsp
    pushq %rax
    popq %rax
L_if_end_65:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movabsq $0x38, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
L_if_end_63:
    movl -56(%rbp), %eax
    pushq %rax
    movabsq $0x222010, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_67
    subq $32, %rsp
    callq L_p_bfpk_compute
    addq $32, %rsp
    pushq %rax
    popq %rax
    pushq %rax
    movq -32(%rbp), %rax
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
    movq %rax, -40(%rbp)
    movabsq $0x8, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
L_if_end_67:
    movl -56(%rbp), %eax
    pushq %rax
    movabsq $0x222014, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_69
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -216(%rbp)
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -224(%rbp)
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -232(%rbp)
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -240(%rbp)
    movl -216(%rbp), %eax
    pushq %rax
    movl -224(%rbp), %eax
    pushq %rax
    movl -232(%rbp), %eax
    pushq %rax
    popq %r8
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_dpk_proof
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -248(%rbp)
    movl -216(%rbp), %eax
    pushq %rax
    movl -224(%rbp), %eax
    pushq %rax
    movl -232(%rbp), %eax
    pushq %rax
    movl -240(%rbp), %eax
    pushq %rax
    popq %r9
    popq %r8
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_dpk_admit
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -256(%rbp)
    movq -256(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movl -248(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movabsq $0x10, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
L_if_end_69:
    movl -56(%rbp), %eax
    pushq %rax
    movabsq $0x222018, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_71
    movabsq $0x1, %rax
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
    movq %rax, -264(%rbp)
    movq -264(%rbp), %rax
    pushq %rax
    movabsq $0x1f, %rax
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
    movq %rax, -272(%rbp)
    movq -272(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_cck_for
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -280(%rbp)
    movl -280(%rbp), %eax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_cck_grants
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -288(%rbp)
    movabsq $0x2, %rax
    pushq %rax
    movq -288(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %r8
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_vk_realizes
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -296(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %r8
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_vk_realizes
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -304(%rbp)
    movq -272(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movl -280(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movq -296(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movq -304(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -32(%rbp), %rax
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
    movq %rax, -40(%rbp)
    movabsq $0x20, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
L_if_end_71:
    movl -56(%rbp), %eax
    pushq %rax
    movabsq $0x22201c, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_73
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -312(%rbp)
    subq $32, %rsp
    callq L_p_bfpk_compute
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -320(%rbp)
    movl -312(%rbp), %eax
    pushq %rax
    movl -320(%rbp), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_stk_bind
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -328(%rbp)
    movl -328(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movl -320(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movabsq $0x10, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
L_if_end_73:
    movl -56(%rbp), %eax
    pushq %rax
    movabsq $0x222020, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_75
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -336(%rbp)
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -344(%rbp)
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -352(%rbp)
    movl -336(%rbp), %eax
    pushq %rax
    movl -344(%rbp), %eax
    pushq %rax
    movl -352(%rbp), %eax
    pushq %rax
    popq %r8
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_tnk_step
    addq $32, %rsp
    pushq %rax
    popq %rax
    pushq %rax
    movq -32(%rbp), %rax
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
    movq %rax, -40(%rbp)
    movabsq $0x8, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
L_if_end_75:
    movl -56(%rbp), %eax
    pushq %rax
    movabsq $0x222024, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_77
    subq $32, %rsp
    callq L_p_bsk_logic_faithful
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -360(%rbp)
    subq $32, %rsp
    callq L_p_bsk_arith_faithful
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -368(%rbp)
    movabsq $0x1, %rax
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
    movq %rax, -376(%rbp)
    movq -376(%rbp), %rax
    pushq %rax
    movabsq $0x1f, %rax
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
    movq %rax, -384(%rbp)
    movq -384(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_cck_for
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -392(%rbp)
    subq $32, %rsp
    callq L_p_bfpk_compute
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -400(%rbp)
    movabsq $0x111, %rax
    pushq %rax
    movl -400(%rbp), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_stk_bind
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -408(%rbp)
    movl -392(%rbp), %eax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_cck_grants
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -416(%rbp)
    movabsq $0x2, %rax
    pushq %rax
    movq -416(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %r8
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_vk_realizes
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -424(%rbp)
    movl -408(%rbp), %eax
    pushq %rax
    movl -392(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %r8
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_dpk_proof
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -432(%rbp)
    movl -408(%rbp), %eax
    pushq %rax
    movl -392(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movl -432(%rbp), %eax
    pushq %rax
    popq %r9
    popq %r8
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_dpk_admit
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -440(%rbp)
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %r8
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_tnk_step
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -448(%rbp)
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %r8
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_tnk_step
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -456(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -464(%rbp)
    movq -384(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_79
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rax, -464(%rbp)
L_if_end_79:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -472(%rbp)
    movq -360(%rbp), %rax
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
    jz L_if_end_81
    movq -368(%rbp), %rax
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
    jz L_if_end_83
    movq -424(%rbp), %rax
    pushq %rax
    movq -464(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_85
    movq -440(%rbp), %rax
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
    jz L_if_end_87
    movl -448(%rbp), %eax
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
    jz L_if_end_89
    movl -456(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_91
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rax, -472(%rbp)
L_if_end_91:
L_if_end_89:
L_if_end_87:
L_if_end_85:
L_if_end_83:
L_if_end_81:
    movq -472(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movl -408(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movl -432(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movl -400(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movq -32(%rbp), %rax
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
    movq %rax, -40(%rbp)
    movabsq $0x20, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
L_if_end_77:
    movq -16(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
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
    movq -40(%rbp), %rax
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
    subq $32, %rsp
    callq L_p_bsk_logic_faithful
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
    jz L_if_end_93
    movabsq $0xc0000001, %rax
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
L_if_end_93:
    subq $32, %rsp
    callq L_p_bsk_arith_faithful
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
    jz L_if_end_95
    movabsq $0xc0000001, %rax
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
L_if_end_95:
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_gate_self_attest
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq -24(%rbp), %rax
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
    jz L_if_end_97
    movq -24(%rbp), %rax
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
L_if_end_97:
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
