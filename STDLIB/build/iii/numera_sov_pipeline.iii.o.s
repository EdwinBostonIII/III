# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "egraph.iiicost_lattice.iiisov_isa.iiisov_isa.iiisov_isa.iiisov_isa.iiisov_isa.iiisov_isa.iiisov_isa.iiisov_isa.iiisov_isa.iiitypecheck.iiitypecheck.iiitypecheck.iiitypecheck.iiitypecheck.iiitypecheck.iii\0"
L_str_1:
    .ascii "cost_lattice.iiisov_isa.iiisov_isa.iiisov_isa.iiisov_isa.iiisov_isa.iiisov_isa.iiisov_isa.iiisov_isa.iiisov_isa.iiitypecheck.iiitypecheck.iiitypecheck.iiitypecheck.iiitypecheck.iiitypecheck.iii\0"
L_str_2:
    .ascii "sov_isa.iiisov_isa.iiisov_isa.iiisov_isa.iiisov_isa.iiisov_isa.iiisov_isa.iiisov_isa.iiisov_isa.iiitypecheck.iiitypecheck.iiitypecheck.iiitypecheck.iiitypecheck.iiitypecheck.iii\0"
L_str_3:
    .ascii "sov_isa.iiisov_isa.iiisov_isa.iiisov_isa.iiisov_isa.iiisov_isa.iiisov_isa.iiisov_isa.iiitypecheck.iiitypecheck.iiitypecheck.iiitypecheck.iiitypecheck.iiitypecheck.iii\0"
L_str_4:
    .ascii "sov_isa.iiisov_isa.iiisov_isa.iiisov_isa.iiisov_isa.iiisov_isa.iiisov_isa.iiitypecheck.iiitypecheck.iiitypecheck.iiitypecheck.iiitypecheck.iiitypecheck.iii\0"
L_str_5:
    .ascii "sov_isa.iiisov_isa.iiisov_isa.iiisov_isa.iiisov_isa.iiisov_isa.iiitypecheck.iiitypecheck.iiitypecheck.iiitypecheck.iiitypecheck.iiitypecheck.iii\0"
L_str_6:
    .ascii "sov_isa.iiisov_isa.iiisov_isa.iiisov_isa.iiisov_isa.iiitypecheck.iiitypecheck.iiitypecheck.iiitypecheck.iiitypecheck.iiitypecheck.iii\0"
L_str_7:
    .ascii "sov_isa.iiisov_isa.iiisov_isa.iiisov_isa.iiitypecheck.iiitypecheck.iiitypecheck.iiitypecheck.iiitypecheck.iiitypecheck.iii\0"
L_str_8:
    .ascii "sov_isa.iiisov_isa.iiisov_isa.iiitypecheck.iiitypecheck.iiitypecheck.iiitypecheck.iiitypecheck.iiitypecheck.iii\0"
L_str_9:
    .ascii "sov_isa.iiisov_isa.iiitypecheck.iiitypecheck.iiitypecheck.iiitypecheck.iiitypecheck.iiitypecheck.iii\0"
L_str_10:
    .ascii "sov_isa.iiitypecheck.iiitypecheck.iiitypecheck.iiitypecheck.iiitypecheck.iiitypecheck.iii\0"
L_str_11:
    .ascii "typecheck.iiitypecheck.iiitypecheck.iiitypecheck.iiitypecheck.iiitypecheck.iii\0"
L_str_12:
    .ascii "typecheck.iiitypecheck.iiitypecheck.iiitypecheck.iiitypecheck.iii\0"
L_str_13:
    .ascii "typecheck.iiitypecheck.iiitypecheck.iiitypecheck.iii\0"
L_str_14:
    .ascii "typecheck.iiitypecheck.iiitypecheck.iii\0"
L_str_15:
    .ascii "typecheck.iiitypecheck.iii\0"
L_str_16:
    .ascii "typecheck.iii\0"
    .section .rodata
L_P_X:
    .quad 0xc
L_P_C0:
    .quad 0x14
L_P_C1:
    .quad 0x15
L_P_C2:
    .quad 0x16
L_P_ADD:
    .quad 0x1e
L_P_MUL:
    .quad 0x1f
L_P_SHL:
    .quad 0x20
L_P_SENT:
    .quad 0xffffffff
    .section .bss
    .global L_PL_OUT
L_PL_OUT:
    .zero 2048
    .global L_PL_OUTN
L_PL_OUTN:
    .zero 8
    .section .iii.ring3,"n"
    .asciz "sov_pipeline_run"
    .text
    .global sov_pipeline_run
    .seh_proc sov_pipeline_run
sov_pipeline_run:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    leaq L_PL_OUT(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    leaq L_PL_OUTN(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
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
    popq %rcx
    subq $32, %rsp
    callq tc_succ
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    subq $8, %rsp
    subq $32, %rsp
    callq tc_zero
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq tc_succ
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq tc_conv
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
    subq $32, %rsp
    callq tc_zero
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq tc_succ
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    subq $8, %rsp
    subq $32, %rsp
    callq tc_zero
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq tc_conv
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
    callq iu_kat
    addq $32, %rsp
    pushq %rax
    movabsq $0x63, %rax
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
    subq $32, %rsp
    callq eg_init
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq cl_init
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movzbq L_P_X(%rip), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq si_leaf
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movzbq L_P_C1(%rip), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq si_leaf
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movzbq L_P_C0(%rip), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq si_leaf
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movzbq L_P_C2(%rip), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq si_leaf
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movl -32(%rbp), %eax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    movzbq L_P_MUL(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq si_node2
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movl -40(%rbp), %eax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    movzbq L_P_MUL(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq si_node2
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movl -64(%rbp), %eax
    pushq %rax
    movl -56(%rbp), %eax
    pushq %rax
    movzbq L_P_ADD(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq si_node2
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movl -32(%rbp), %eax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    movzbq L_P_SHL(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq si_node2
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -80(%rbp)
    movl -80(%rbp), %eax
    pushq %rax
    movl L_P_SENT(%rip), %eax
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
    movl -72(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq psi_of
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
    movl -88(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq psi_card
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
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
    movq -16(%rbp), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movl -88(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq psi_collapse
    addq $32, %rsp
    movslq %eax, %rax
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
    leaq L_PL_OUTN(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
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
    jz L_if_end_13
    movabsq $0x7, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_13:
    leaq L_PL_OUT(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    subq $8, %rsp
    movzbq L_P_X(%rip), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq si_slot
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_15
    movabsq $0x8, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_15:
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
    popq %rcx
    subq $32, %rsp
    callq tc_succ
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq tc_succ
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -96(%rbp)
    subq $32, %rsp
    callq tc_zero
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq tc_succ
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq tc_succ
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movl -96(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq sov_pcc_verify
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
    jz L_if_end_17
    movabsq $0x9, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_17:
    movl -96(%rbp), %eax
    pushq %rax
    subq $8, %rsp
    subq $32, %rsp
    callq tc_zero
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq tc_succ
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq sov_pcc_verify
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
    jz L_if_end_19
    movabsq $0xa, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_19:
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    subq $32, %rsp
    callq tc_zero
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq tc_succ
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq tc_succ
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movl -96(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq sov_admit_rule
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
    jz L_if_end_21
    movabsq $0xb, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_21:
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movl -96(%rbp), %eax
    pushq %rax
    subq $8, %rsp
    subq $32, %rsp
    callq tc_zero
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq tc_succ
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq sov_admit_rule
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
    jz L_if_end_23
    movabsq $0xc, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_23:
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
