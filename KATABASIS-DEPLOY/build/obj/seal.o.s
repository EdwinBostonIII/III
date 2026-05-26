# III Stage-0 Ring-0 codegen output (Windows kernel-mode .sys)
# Output binary: iiis-0.sys
    .att_syntax
    .section .rdata,"dr"
L_str_0:
    .ascii "sha256.iiicontent_addr.iiicycle_term.iiicycle_term.iiicycle_term.iiicycle_term.iiicycle_term.iii\0"
L_str_1:
    .ascii "content_addr.iiicycle_term.iiicycle_term.iiicycle_term.iiicycle_term.iiicycle_term.iii\0"
L_str_2:
    .ascii "cycle_term.iiicycle_term.iiicycle_term.iiicycle_term.iiicycle_term.iii\0"
L_str_3:
    .ascii "cycle_term.iiicycle_term.iiicycle_term.iiicycle_term.iii\0"
L_str_4:
    .ascii "cycle_term.iiicycle_term.iiicycle_term.iii\0"
L_str_5:
    .ascii "cycle_term.iiicycle_term.iii\0"
L_str_6:
    .ascii "cycle_term.iii\0"
    .section .bss
    .global L_p_KCS_BUF
L_p_KCS_BUF:
    .zero 48
    .global L_p_KCS_TMP
L_p_KCS_TMP:
    .zero 256
    .section .text,"xr"  /* PE/COFF Â§6 */
    /* IRQL_REQUIRES_MAX(2) */
    .global L_p_katabasis_cycle_seal
L_p_katabasis_cycle_seal:
    .seh_proc L_p_katabasis_cycle_seal
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
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_katabasis_cycle_family
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_katabasis_cycle_target_kind
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_katabasis_cycle_action_hexad
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_katabasis_cycle_target
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_katabasis_cycle_cap
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movabsq $0x4b41544142534c31, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KCS_BUF(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movq -40(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KCS_BUF(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movq -48(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KCS_BUF(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movq -56(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KCS_BUF(%rip), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movq -64(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KCS_BUF(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movq -72(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KCS_BUF(%rip), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    leaq L_p_KCS_BUF(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x30, %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %r8
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_sha256_oneshot
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
    .global L_p_katabasis_cycle_seal_verify
L_p_katabasis_cycle_seal_verify:
    .seh_proc L_p_katabasis_cycle_seal_verify
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
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    leaq L_p_KCS_TMP(%rip), %rax
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
    leaq L_p_KCS_TMP(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_ca_eq
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
