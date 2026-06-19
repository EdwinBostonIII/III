# III Stage-0 Ring-0 codegen output (Windows kernel-mode .sys)
# Output binary: iiis-0.sys
    .att_syntax
    .section .rdata,"dr"
L_str_0:
    .ascii "capability.iii\0"
    .section .rodata
L_p_KCAP_R_READMETAL:
    .quad 0x100000
L_p_KCAP_R_WRITEMETAL:
    .quad 0x200000
L_p_KCAP_R_SNAPSHOT:
    .quad 0x400000
L_p_KCAP_R_DESCEND:
    .quad 0x800000
L_p_KCAP_R_OBSERVE:
    .quad 0x1000000
L_p_KCAP_R_CAPOP:
    .quad 0x2000000
L_p_KCAP_R_COPROC:
    .quad 0x4000000
    .section .text,"xr"  /* PE/COFF Â§6 */
    /* IRQL_REQUIRES_MAX(2) */
    .global L_p_katabasis_family_required_right
L_p_katabasis_family_required_right:
    .seh_proc L_p_katabasis_family_required_right
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
    popq %rax
    movq %rax, -16(%rbp)
    movl -16(%rbp), %eax
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
    jz L_if_end_1
    movq L_p_KCAP_R_READMETAL(%rip), %rax
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
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x2, %rax
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
    movq L_p_KCAP_R_WRITEMETAL(%rip), %rax
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
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x3, %rax
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
    movq L_p_KCAP_R_READMETAL(%rip), %rax
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
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x4, %rax
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
    movq L_p_KCAP_R_SNAPSHOT(%rip), %rax
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
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x5, %rax
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
    movq L_p_KCAP_R_DESCEND(%rip), %rax
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
L_if_end_9:
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x6, %rax
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
    movq L_p_KCAP_R_OBSERVE(%rip), %rax
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
L_if_end_11:
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x7, %rax
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
    movq L_p_KCAP_R_READMETAL(%rip), %rax
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
L_if_end_13:
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x8, %rax
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
    movq L_p_KCAP_R_CAPOP(%rip), %rax
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
L_if_end_15:
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x9, %rax
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
    movq L_p_KCAP_R_COPROC(%rip), %rax
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
L_if_end_17:
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
    .global L_p_katabasis_cap_check
L_p_katabasis_cap_check:
    .seh_proc L_p_katabasis_cap_check
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
    movl -8(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movl -24(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_katabasis_family_required_right
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq -40(%rbp), %rax
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
    jz L_if_end_19
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
L_if_end_19:
    movq -32(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_cap_verify_rights
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
