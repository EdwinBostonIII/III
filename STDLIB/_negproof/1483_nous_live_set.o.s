# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "nous_socket.iii\0"
L_str_1:
    .ascii "nous_socket.iii\0"
L_str_2:
    .ascii "nous_policy.iii\0"
L_str_3:
    .ascii "nous_lattice.iii\0"
    .section .bss
    .global L_NLS_ORD
L_NLS_ORD:
    .zero 512
    .global L_NLS_EXP
L_NLS_EXP:
    .zero 512
    .global L_NLS_SEEN
L_NLS_SEEN:
    .zero 1024
    .section .iii.ring3,"n"
    .asciz "_nls_fill_expected"
    .text
    .seh_proc L__nls_fill_expected
L__nls_fill_expected:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x26, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x28, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0x29, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    movabsq $0xe, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    movabsq $0xf, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0xe, %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0xf, %rax
    pushq %rax
    movabsq $0x11, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    movabsq $0x12, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x11, %rax
    pushq %rax
    movabsq $0x13, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x12, %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x13, %rax
    pushq %rax
    movabsq $0x15, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    movabsq $0x16, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x15, %rax
    pushq %rax
    movabsq $0x17, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x16, %rax
    pushq %rax
    movabsq $0x2b, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x17, %rax
    pushq %rax
    movabsq $0x2c, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x18, %rax
    pushq %rax
    movabsq $0x18, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x19, %rax
    pushq %rax
    movabsq $0x19, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x1a, %rax
    pushq %rax
    movabsq $0x1a, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x1b, %rax
    pushq %rax
    movabsq $0x1b, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x1c, %rax
    pushq %rax
    movabsq $0x1c, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x1d, %rax
    pushq %rax
    movabsq $0x1d, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x1e, %rax
    pushq %rax
    movabsq $0x1e, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x1f, %rax
    pushq %rax
    movabsq $0x1f, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x20, %rax
    pushq %rax
    movabsq $0x20, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x21, %rax
    pushq %rax
    movabsq $0x2a, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x22, %rax
    pushq %rax
    movabsq $0x21, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x23, %rax
    pushq %rax
    movabsq $0x22, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x24, %rax
    pushq %rax
    movabsq $0x23, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x25, %rax
    pushq %rax
    movabsq $0x24, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x26, %rax
    pushq %rax
    movabsq $0x25, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x27, %rax
    pushq %rax
    movabsq $0x27, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x28, %rax
    pushq %rax
    movabsq $0x28, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x29, %rax
    pushq %rax
    movabsq $0x65, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x2a, %rax
    pushq %rax
    movabsq $0x66, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x2b, %rax
    pushq %rax
    movabsq $0x67, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x2c, %rax
    pushq %rax
    movabsq $0x68, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movabsq $0x2d, %rax
    pushq %rax
    movabsq $0x69, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
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
    callq L__nls_fill_expected
    addq $32, %rsp
    pushq %rax
    popq %rax
    leaq L_NLS_ORD(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq nous_set_order_mode
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x40, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x1a, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq nous_rank
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x2e, %rax
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
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
L_loop_top_2:
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x2e, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_3
    leaq L_NLS_ORD(%rip), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    leaq L_NLS_EXP(%rip), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
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
    movabsq $0x2, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_5:
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_2
L_loop_end_3:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
L_loop_top_6:
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x2e, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_7
    leaq L_NLS_ORD(%rip), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_9
    leaq L_NLS_ORD(%rip), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setbe %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_11
    movabsq $0x3, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_11:
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_9:
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_6
L_loop_end_7:
    movl -16(%rbp), %eax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq nol_certify_order
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
    jz L_if_end_13
    movabsq $0x4, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_13:
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq nous_set_order_mode
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x40, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x1a, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq nous_rank
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movl -32(%rbp), %eax
    pushq %rax
    movabsq $0x2d, %rax
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
    movabsq $0x5, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_15:
    leaq L_NLS_ORD(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movabsq $0x5, %rax
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
    movabsq $0x6, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_17:
    leaq L_NLS_ORD(%rip), %rax
    pushq %rax
    movabsq $0x27, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movabsq $0x2c, %rax
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
    movabsq $0x7, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_19:
    leaq L_NLS_ORD(%rip), %rax
    pushq %rax
    movabsq $0x28, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movabsq $0x65, %rax
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
    movabsq $0x8, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_21:
    leaq L_NLS_ORD(%rip), %rax
    pushq %rax
    movabsq $0x2c, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movabsq $0x69, %rax
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
    movabsq $0x9, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_23:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
L_loop_top_24:
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x2d, %rax
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
    leaq L_NLS_ORD(%rip), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_27
    leaq L_NLS_ORD(%rip), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setbe %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_29
    movabsq $0xa, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_29:
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_27:
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_24
L_loop_end_25:
    movl -32(%rbp), %eax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq nol_certify_order
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
    movabsq $0xb, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_31:
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq nous_set_order_mode
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x40, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq nous_policy_rank
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movl -40(%rbp), %eax
    pushq %rax
    movabsq $0x2d, %rax
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
    movabsq $0xc, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_33:
    leaq L_NLS_ORD(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movabsq $0x26, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_35
    movabsq $0xd, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_35:
    leaq L_NLS_ORD(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movabsq $0x28, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_37
    movabsq $0xe, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_37:
    leaq L_NLS_ORD(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_39
    movabsq $0xf, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_39:
    leaq L_NLS_ORD(%rip), %rax
    pushq %rax
    movabsq $0x28, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movabsq $0x65, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_41
    movabsq $0x10, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_41:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
L_loop_top_42:
    movq -48(%rbp), %rax
    pushq %rax
    movabsq $0x80, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_43
    leaq L_NLS_SEEN(%rip), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movq -48(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_42
L_loop_end_43:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
L_loop_top_44:
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x2d, %rax
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
    leaq L_NLS_ORD(%rip), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq -56(%rbp), %rax
    pushq %rax
    movabsq $0x80, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_47
    movabsq $0x11, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_47:
    leaq L_NLS_SEEN(%rip), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
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
    movabsq $0x12, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_49:
    leaq L_NLS_SEEN(%rip), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_44
L_loop_end_45:
    movabsq $0x5, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
L_loop_top_50:
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x2d, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_51
    leaq L_NLS_SEEN(%rip), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
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
    jz L_if_end_53
    movabsq $0x13, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_53:
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_50
L_loop_end_51:
    movabsq $0x65, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
L_loop_top_54:
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x6a, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_55
    leaq L_NLS_SEEN(%rip), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
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
    jz L_if_end_57
    movabsq $0x14, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_57:
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_54
L_loop_end_55:
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
L_loop_top_58:
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_59
    leaq L_NLS_SEEN(%rip), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
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
    movabsq $0x15, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_61:
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_58
L_loop_end_59:
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
