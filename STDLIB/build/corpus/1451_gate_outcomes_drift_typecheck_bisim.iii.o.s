# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "k0_referee.iii\0"
L_str_1:
    .ascii "k0_referee.iii\0"
L_str_2:
    .ascii "typecheck.iii\0"
L_str_3:
    .ascii "typecheck.iii\0"
L_str_4:
    .ascii "typecheck.iii\0"
L_str_5:
    .ascii "typecheck.iii\0"
L_str_6:
    .ascii "typecheck.iii\0"
L_str_7:
    .ascii "typecheck.iii\0"
L_str_8:
    .ascii "typecheck.iii\0"
L_str_9:
    .ascii "typecheck.iii\0"
L_str_10:
    .ascii "typecheck.iii\0"
L_str_11:
    .ascii "proof_bisimulation.iii\0"
    .section .iii.ring3,"n"
    .asciz "main"
    .text
    .global main
    .seh_proc main
main:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    subq $32, %rsp
    callq k0_fingerprint
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq k0_drift_check
    addq $32, %rsp
    movl %eax, %eax
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
    jz L_if_end_1
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_1:
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq k0_drift_check
    addq $32, %rsp
    movl %eax, %eax
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
    jz L_if_end_3
    movabsq $0x2, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_3:
    subq $32, %rsp
    callq tc_reset
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq tc_zero
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movl -16(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq tc_succ
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movl -16(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq tc_refl
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    subq $8, %rsp
    subq $32, %rsp
    callq tc_nat
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq tc_lam
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movl -16(%rbp), %eax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    subq $32, %rsp
    callq tc_nat
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq tc_id
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    subq $8, %rsp
    subq $32, %rsp
    callq tc_nat
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq tc_pi
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movl -24(%rbp), %eax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    subq $32, %rsp
    callq tc_nat
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq tc_id
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    subq $8, %rsp
    subq $32, %rsp
    callq tc_nat
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq tc_pi
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movl -40(%rbp), %eax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq tc_check
    addq $32, %rsp
    movzbq %al, %rax
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
    jz L_if_end_5
    movabsq $0x3, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_5:
    movl -48(%rbp), %eax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq tc_check
    addq $32, %rsp
    movzbq %al, %rax
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
    jz L_if_end_7
    movabsq $0x4, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_7:
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bisim_prove_equiv
    addq $32, %rsp
    movzbq %al, %rax
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
    jz L_if_end_9
    movabsq $0x5, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_9:
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bisim_prove_equiv
    addq $32, %rsp
    movzbq %al, %rax
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
    jz L_if_end_11
    movabsq $0x6, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_11:
    movabsq $0x63, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
