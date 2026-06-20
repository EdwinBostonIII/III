# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "egraph.iii\0"
L_str_1:
    .ascii "egraph.iii\0"
L_str_2:
    .ascii "egraph.iii\0"
L_str_3:
    .ascii "egraph.iii\0"
L_str_4:
    .ascii "egraph.iii\0"
L_str_5:
    .ascii "egraph.iii\0"
L_str_6:
    .ascii "egraph.iii\0"
L_str_7:
    .ascii "egraph.iii\0"
L_str_8:
    .ascii "egraph.iii\0"
L_str_9:
    .ascii "cad.iii\0"
    .section .bss
    .global L_SYM_A
L_SYM_A:
    .zero 256
    .global L_SYM_B
L_SYM_B:
    .zero 256
    .global L_SYM_X
L_SYM_X:
    .zero 256
    .global L_SYM_F
L_SYM_F:
    .zero 256
    .global L_CH
L_CH:
    .zero 16
    .global L_SEAL_A
L_SEAL_A:
    .zero 256
    .global L_SEAL_B
L_SEAL_B:
    .zero 256
    .section .data
    .global L_W_CA
L_W_CA:
    .quad 0x0
    .global L_W_CB
L_W_CB:
    .quad 0x0
    .global L_W_CX
L_W_CX:
    .quad 0x0
    .global L_W_FA
L_W_FA:
    .quad 0x0
    .global L_W_FFA
L_W_FFA:
    .quad 0x0
    .global L_W_FB
L_W_FB:
    .quad 0x0
    .global L_W_FFB
L_W_FFB:
    .quad 0x0
    .section .iii.ring3,"n"
    .asciz "fillsym"
    .text
    .seh_proc L_fillsym
L_fillsym:
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
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
L_loop_top_0:
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x20, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_1
    movq -24(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movzbq -16(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_0
L_loop_end_1:
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "build_workload"
    .text
    .seh_proc L_build_workload
L_build_workload:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    subq $32, %rsp
    callq eg_init
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xa1, %rax
    pushq %rax
    leaq L_SYM_A(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_fillsym
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0xb2, %rax
    pushq %rax
    leaq L_SYM_B(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_fillsym
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x5c, %rax
    pushq %rax
    leaq L_SYM_X(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_fillsym
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0xf0, %rax
    pushq %rax
    leaq L_SYM_F(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_fillsym
    addq $32, %rsp
    pushq %rax
    popq %rax
    leaq L_CH(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    leaq L_SYM_A(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq eg_add
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movl %eax, L_W_CA(%rip)
    movabsq $0x0, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    leaq L_SYM_B(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq eg_add
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movl %eax, L_W_CB(%rip)
    movabsq $0x0, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    leaq L_SYM_X(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq eg_add
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movl %eax, L_W_CX(%rip)
    movl L_W_CA(%rip), %eax
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
    jz L_if_end_3
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_3:
    movl L_W_CB(%rip), %eax
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
    movl L_W_CX(%rip), %eax
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
    jz L_if_end_7
    movabsq $0x3, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_7:
    leaq L_CH(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movl L_W_CA(%rip), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movabsq $0x1, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    leaq L_SYM_F(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq eg_add
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movl %eax, L_W_FA(%rip)
    leaq L_CH(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movl L_W_FA(%rip), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movabsq $0x1, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    leaq L_SYM_F(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq eg_add
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movl %eax, L_W_FFA(%rip)
    leaq L_CH(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movl L_W_CB(%rip), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movabsq $0x1, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    leaq L_SYM_F(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq eg_add
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movl %eax, L_W_FB(%rip)
    leaq L_CH(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movl L_W_FB(%rip), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movabsq $0x1, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    leaq L_SYM_F(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq eg_add
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movl %eax, L_W_FFB(%rip)
    movl L_W_FFB(%rip), %eax
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
    jz L_if_end_9
    movabsq $0x4, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_9:
    movl L_W_CX(%rip), %eax
    pushq %rax
    movl L_W_FB(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq eg_union
    addq $32, %rsp
    movl %eax, %eax
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
    jz L_if_end_11
    movabsq $0x5, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_11:
    movl L_W_CB(%rip), %eax
    pushq %rax
    movl L_W_CA(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq eg_union
    addq $32, %rsp
    movl %eax, %eax
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
    jz L_if_end_13
    movabsq $0x6, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_13:
    movabsq $0x0, %rax
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
    .asciz "check_partition"
    .text
    .seh_proc L_check_partition
L_check_partition:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movl L_W_CA(%rip), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq eg_find
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    subq $8, %rsp
    movl L_W_CB(%rip), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq eg_find
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
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_15:
    movl L_W_FA(%rip), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq eg_find
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    subq $8, %rsp
    movl L_W_FB(%rip), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq eg_find
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
    jz L_if_end_17
    movabsq $0x2, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_17:
    movl L_W_FA(%rip), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq eg_find
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    subq $8, %rsp
    movl L_W_CX(%rip), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq eg_find
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
    jz L_if_end_19
    movabsq $0x3, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_19:
    movl L_W_FFA(%rip), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq eg_find
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    subq $8, %rsp
    movl L_W_FFB(%rip), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq eg_find
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
    jz L_if_end_21
    movabsq $0x4, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_21:
    movl L_W_FFA(%rip), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq eg_find
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    subq $8, %rsp
    movl L_W_FA(%rip), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq eg_find
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
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
    movabsq $0x5, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_23:
    movl L_W_FA(%rip), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq eg_find
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    subq $8, %rsp
    movl L_W_CA(%rip), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq eg_find
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_25
    movabsq $0x6, %rax
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
    callq L_build_workload
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
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
    jz L_if_end_27
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_27:
    subq $32, %rsp
    callq eg_rebuild
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movl -16(%rbp), %eax
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
    subq $32, %rsp
    callq L_check_partition
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
    jz L_if_end_31
    movabsq $0x14, %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_31:
    subq $32, %rsp
    callq eg_rebuild
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
    jz L_if_end_33
    movabsq $0xb, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_33:
    subq $32, %rsp
    callq L_check_partition
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq -32(%rbp), %rax
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
    jz L_if_end_35
    movabsq $0x1e, %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_35:
    leaq L_SEAL_A(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq eg_seal
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
    jz L_if_end_37
    movabsq $0xc, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_37:
    subq $32, %rsp
    callq L_build_workload
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
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_39
    movabsq $0x28, %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_39:
    subq $32, %rsp
    callq eg_rebuild_full
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_41
    movabsq $0xd, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_41:
    subq $32, %rsp
    callq L_check_partition
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq -48(%rbp), %rax
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
    jz L_if_end_43
    movabsq $0x32, %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_43:
    leaq L_SEAL_B(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq eg_seal
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
    jz L_if_end_45
    movabsq $0xe, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_45:
    leaq L_SEAL_B(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_SEAL_A(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq cad_eq
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
    jz L_if_end_47
    movabsq $0xf, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_47:
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
