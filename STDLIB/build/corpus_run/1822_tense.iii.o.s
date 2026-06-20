# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "tense.iii\0"
L_str_1:
    .ascii "tense.iii\0"
L_str_2:
    .ascii "tense.iii\0"
    .section .rodata
L_TENSE_AORIST:
    .quad 0x0
L_TENSE_PERFECT:
    .quad 0x1
L_TENSE_PRESENT:
    .quad 0x2
L_TST_FRESH:
    .quad 0x0
L_TST_BOUND:
    .quad 0x1
L_TST_USED:
    .quad 0x2
L_TOP_WRITE:
    .quad 0x0
L_TOP_READ:
    .quad 0x1
L_TOP_BIND:
    .quad 0x2
L_TOP_CONSUME:
    .quad 0x3
L_T_REJECT:
    .quad 0xffffffff
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
    movl L_TOP_WRITE(%rip), %eax
    pushq %rax
    movl L_TST_FRESH(%rip), %eax
    pushq %rax
    movl L_TENSE_PERFECT(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq tense_step
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movl L_T_REJECT(%rip), %eax
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
    movabsq $0xb, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_1:
    movl L_TOP_BIND(%rip), %eax
    pushq %rax
    movl L_TST_FRESH(%rip), %eax
    pushq %rax
    movl L_TENSE_PERFECT(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq tense_step
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movl -8(%rbp), %eax
    pushq %rax
    movl L_T_REJECT(%rip), %eax
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
    movabsq $0xc, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_3:
    movl -8(%rbp), %eax
    pushq %rax
    movl L_TST_BOUND(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
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
    jz L_if_end_5
    movabsq $0xd, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_5:
    movl L_TOP_WRITE(%rip), %eax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    movl L_TENSE_PERFECT(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq tense_step
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movl L_T_REJECT(%rip), %eax
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
    movabsq $0xe, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_7:
    movl L_TOP_READ(%rip), %eax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    movl L_TENSE_PERFECT(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq tense_step
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movl L_T_REJECT(%rip), %eax
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
    movabsq $0xf, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_9:
    movl L_TOP_WRITE(%rip), %eax
    pushq %rax
    movl L_TST_FRESH(%rip), %eax
    pushq %rax
    movl L_TENSE_AORIST(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq tense_step
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movl L_T_REJECT(%rip), %eax
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
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_11:
    movl L_TOP_CONSUME(%rip), %eax
    pushq %rax
    movl L_TST_FRESH(%rip), %eax
    pushq %rax
    movl L_TENSE_AORIST(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq tense_step
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movl -16(%rbp), %eax
    pushq %rax
    movl L_T_REJECT(%rip), %eax
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
    movabsq $0x11, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_13:
    movl -16(%rbp), %eax
    pushq %rax
    movl L_TST_USED(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
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
    jz L_if_end_15
    movabsq $0x12, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_15:
    movl L_TOP_CONSUME(%rip), %eax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    movl L_TENSE_AORIST(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq tense_step
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movl L_T_REJECT(%rip), %eax
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
    movabsq $0x13, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_17:
    movl L_TOP_READ(%rip), %eax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    movl L_TENSE_AORIST(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq tense_step
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movl L_T_REJECT(%rip), %eax
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
    movabsq $0x14, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_19:
    movl L_TOP_WRITE(%rip), %eax
    pushq %rax
    movl L_TST_BOUND(%rip), %eax
    pushq %rax
    movl L_TST_USED(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    movl L_TENSE_PRESENT(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq tense_step
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movl L_T_REJECT(%rip), %eax
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
    movabsq $0x15, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_21:
    movl L_TOP_CONSUME(%rip), %eax
    pushq %rax
    movl L_TST_BOUND(%rip), %eax
    pushq %rax
    movl L_TST_USED(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    movl L_TENSE_PRESENT(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq tense_step
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movl L_T_REJECT(%rip), %eax
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
    movabsq $0x16, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_23:
    movabsq $0x1, %rax
    pushq %rax
    movl L_TENSE_PERFECT(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq tense_can_write
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
    jz L_if_end_25
    movabsq $0x17, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_25:
    movabsq $0x0, %rax
    pushq %rax
    movl L_TENSE_PERFECT(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq tense_can_write
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
    jz L_if_end_27
    movabsq $0x18, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_27:
    movabsq $0x1, %rax
    pushq %rax
    movl L_TENSE_AORIST(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq tense_can_reuse
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
    jz L_if_end_29
    movabsq $0x19, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_29:
    movabsq $0x1, %rax
    pushq %rax
    movl L_TENSE_PRESENT(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq tense_can_reuse
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
    jz L_if_end_31
    movabsq $0x1a, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_31:
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
