# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "q128.iiiq128.iiicrystal.iii\0"
L_str_1:
    .ascii "q128.iiicrystal.iii\0"
L_str_2:
    .ascii "crystal.iii\0"
    .section .rodata
L_F64_POS_ZERO_BITS:
    .quad 0x0
L_F64_POS_INF_BITS:
    .quad 0x7ff0000000000000
L_Q128_F64_MAX_INSTANCES:
    .quad 0x40
    .section .bss
    .global L_Q128_F64_LAST_DIR
L_Q128_F64_LAST_DIR:
    .zero 512
    .section .iii.ring3,"n"
    .asciz "q128f_msb"
    .text
    .global L_q128f_msb
    .seh_proc L_q128f_msb
L_q128f_msb:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movq -8(%rbp), %rax
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
    movabsq $0x40, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movabsq $0x80, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
L_loop_top_2:
    movzbq -40(%rbp), %rax
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
    jz L_loop_end_3
    movl -24(%rbp), %eax
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
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_5:
    movzbq -40(%rbp), %rax
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
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    popq %rax
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
    movq %rax, -56(%rbp)
    movq -56(%rbp), %rax
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
    jz L_if_end_9
    movl -48(%rbp), %eax
    pushq %rax
    movabsq $0x40, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_9:
    movq -56(%rbp), %rax
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
    jz L_if_end_11
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_11:
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_7:
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_2
L_loop_end_3:
    movl -32(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_1:
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
    jz L_if_end_13
    movabsq $0x80, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_13:
    movabsq $0x40, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movabsq $0x80, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
L_loop_top_14:
    movzbq -40(%rbp), %rax
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
    jz L_loop_end_15
    movl -24(%rbp), %eax
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
    jz L_if_end_17
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_17:
    movzbq -40(%rbp), %rax
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
    jz L_if_end_19
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    popq %rax
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
    movq %rax, -56(%rbp)
    movq -56(%rbp), %rax
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
    jz L_if_end_21
    movl -48(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_21:
    movq -56(%rbp), %rax
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
    jz L_if_end_23
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_23:
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_19:
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_14
L_loop_end_15:
    movl -32(%rbp), %eax
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
    .section .iii.ring3,"n"
    .asciz "q128f_extract"
    .text
    .global L_q128f_extract
    .seh_proc L_q128f_extract
L_q128f_extract:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movq %r8, -24(%rbp)
    movq %r9, -32(%rbp)
    movl -24(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movl -32(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
L_loop_top_24:
    movq -64(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_25
    movq -40(%rbp), %rax
    pushq %rax
    movq -64(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -80(%rbp)
    movq -72(%rbp), %rax
    pushq %rax
    movabsq $0x40, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_else_26
    movq -16(%rbp), %rax
    pushq %rax
    movq -72(%rbp), %rax
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
    movq %rax, -80(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_if_end_27
L_if_else_26:
    movq -72(%rbp), %rax
    pushq %rax
    movabsq $0x40, %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    movq -88(%rbp), %rax
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
    movq %rax, -80(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_27:
    movq -56(%rbp), %rax
    pushq %rax
    movq -80(%rbp), %rax
    pushq %rax
    movq -64(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    shlq %cl, %rax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq -64(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_24
L_loop_end_25:
    movq -56(%rbp), %rax
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
    .section .iii.ring3,"n"
    .asciz "q128_to_f64_bits"
    .text
    .global q128_to_f64_bits
    .seh_proc q128_to_f64_bits
q128_to_f64_bits:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
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
    jz L_if_end_29
    movq L_F64_POS_ZERO_BITS(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_29:
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq q128_hi
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq q128_lo
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq -24(%rbp), %rax
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
    jz L_if_end_31
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
    jz L_if_end_33
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    movabsq $0x3f, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    leaq L_Q128_F64_LAST_DIR(%rip), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movq L_F64_POS_ZERO_BITS(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_33:
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_31:
    movq -32(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_q128f_msb
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movl -40(%rbp), %eax
    pushq %rax
    movabsq $0x80, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_35
    movq L_F64_POS_ZERO_BITS(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_35:
    movl -40(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x3ff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movl -40(%rbp), %eax
    pushq %rax
    movabsq $0x35, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_37
    movabsq $0x34, %rax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -80(%rbp)
    movq -32(%rbp), %rax
    pushq %rax
    movl -80(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    shlq %cl, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq -56(%rbp), %rax
    pushq %rax
    movabsq $0xfffffffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_37:
    movl -40(%rbp), %eax
    pushq %rax
    movabsq $0x35, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_39
    movl -40(%rbp), %eax
    pushq %rax
    movabsq $0x34, %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -80(%rbp)
    movabsq $0x35, %rax
    pushq %rax
    movl -80(%rbp), %eax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_q128f_extract
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
    movq -88(%rbp), %rax
    pushq %rax
    movabsq $0xfffffffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movl -80(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    seta %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_41
    movabsq $0x1, %rax
    pushq %rax
    movl -80(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_q128f_extract
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movl -80(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    seta %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_43
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -96(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -104(%rbp)
L_loop_top_44:
    movl -96(%rbp), %eax
    pushq %rax
    movl -80(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_45
    movabsq $0x1, %rax
    pushq %rax
    movl -96(%rbp), %eax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_q128f_extract
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -112(%rbp)
    movq -104(%rbp), %rax
    pushq %rax
    movq -112(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -104(%rbp)
    movl -96(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -96(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_44
L_loop_end_45:
    movq -104(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_43:
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_41:
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_39:
    movq -48(%rbp), %rax
    pushq %rax
    movabsq $0x34, %rax
    pushq %rax
    popq %rcx
    popq %rax
    shlq %cl, %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -80(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    movabsq $0x3f, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
    movq -72(%rbp), %rax
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
    jz L_if_end_47
    movq -56(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -96(%rbp)
    movq -64(%rbp), %rax
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
    jz L_if_end_49
    movq -80(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -80(%rbp)
    leaq L_Q128_F64_LAST_DIR(%rip), %rax
    pushq %rax
    movq -88(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_49:
    movq -64(%rbp), %rax
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
    movq -96(%rbp), %rax
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
    jz L_if_end_53
    movq -80(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -80(%rbp)
    leaq L_Q128_F64_LAST_DIR(%rip), %rax
    pushq %rax
    movq -88(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_53:
    movq -96(%rbp), %rax
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
    jz L_if_end_55
    leaq L_Q128_F64_LAST_DIR(%rip), %rax
    pushq %rax
    movq -88(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_55:
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_51:
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_47:
    movq -72(%rbp), %rax
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
    jz L_if_end_57
    movq -64(%rbp), %rax
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
    jz L_if_end_59
    leaq L_Q128_F64_LAST_DIR(%rip), %rax
    pushq %rax
    movq -88(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_59:
    movq -64(%rbp), %rax
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
    jz L_if_end_61
    leaq L_Q128_F64_LAST_DIR(%rip), %rax
    pushq %rax
    movq -88(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    negq %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_61:
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_57:
    movq -80(%rbp), %rax
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
    .section .iii.ring3,"n"
    .asciz "q128_to_f64_round_dir"
    .text
    .global q128_to_f64_round_dir
    .seh_proc q128_to_f64_round_dir
q128_to_f64_round_dir:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq -8(%rbp), %rax
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
    jz L_if_end_63
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_63:
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    movabsq $0x3f, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    leaq L_Q128_F64_LAST_DIR(%rip), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movslq (%rax,%rcx,4), %rax
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
    .section .iii.ring3,"n"
    .asciz "q128_to_f64_crystal"
    .text
    .global q128_to_f64_crystal
    .seh_proc q128_to_f64_crystal
q128_to_f64_crystal:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
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
    jz L_if_end_65
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_65:
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq q128_to_f64_round_dir
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movslq -24(%rbp), %rax
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
    jz L_if_end_67
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_67:
    movslq -24(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    negq %rax
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
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_69:
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq crystal_mint
    addq $32, %rsp
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
