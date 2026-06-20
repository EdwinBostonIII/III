# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
    .section .rodata
L_GVN_N:
    .quad 0x7
L_GVN_LEAF:
    .quad 0x0
L_GVN_ADD:
    .quad 0x1
L_GVN_MUL:
    .quad 0x2
    .section .bss
    .global L_GVN_OP
L_GVN_OP:
    .zero 56
    .global L_GVN_A
L_GVN_A:
    .zero 56
    .global L_GVN_B
L_GVN_B:
    .zero 56
    .global L_GVN_VN
L_GVN_VN:
    .zero 56
    .global L_GVN_RED
L_GVN_RED:
    .zero 56
    .global L_GVN_TOP
L_GVN_TOP:
    .zero 56
    .global L_GVN_TA
L_GVN_TA:
    .zero 56
    .global L_GVN_TB
L_GVN_TB:
    .zero 56
    .global L_GVN_TVN
L_GVN_TVN:
    .zero 56
    .global L_GVN_TSZ
L_GVN_TSZ:
    .zero 8
    .section .iii.ring3,"n"
    .asciz "gvn_setup"
    .text
    .global gvn_setup
    .seh_proc gvn_setup
gvn_setup:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    leaq L_GVN_OP(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movl L_GVN_LEAF(%rip), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_GVN_A(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_GVN_B(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_GVN_OP(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movl L_GVN_LEAF(%rip), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_GVN_A(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_GVN_B(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_GVN_OP(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movl L_GVN_ADD(%rip), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_GVN_A(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_GVN_B(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_GVN_OP(%rip), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movl L_GVN_ADD(%rip), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_GVN_A(%rip), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_GVN_B(%rip), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_GVN_OP(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movl L_GVN_MUL(%rip), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_GVN_A(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_GVN_B(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_GVN_OP(%rip), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movl L_GVN_MUL(%rip), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_GVN_A(%rip), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_GVN_B(%rip), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_GVN_OP(%rip), %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movl L_GVN_ADD(%rip), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_GVN_A(%rip), %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_GVN_B(%rip), %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
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
    .asciz "gvn_number"
    .text
    .global gvn_number
    .seh_proc gvn_number
gvn_number:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    leaq L_GVN_TSZ(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
L_loop_top_0:
    movl -16(%rbp), %eax
    pushq %rax
    movl L_GVN_N(%rip), %eax
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
    leaq L_GVN_OP(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    movl L_GVN_LEAF(%rip), %eax
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
    leaq L_GVN_VN(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    leaq L_GVN_RED(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
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
L_if_end_3:
    leaq L_GVN_OP(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    movl L_GVN_LEAF(%rip), %eax
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
    leaq L_GVN_VN(%rip), %rax
    pushq %rax
    leaq L_GVN_A(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    leaq L_GVN_VN(%rip), %rax
    pushq %rax
    leaq L_GVN_B(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    leaq L_GVN_TSZ(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
L_loop_top_6:
    movl -64(%rbp), %eax
    pushq %rax
    movl -56(%rbp), %eax
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
    leaq L_GVN_TOP(%rip), %rax
    pushq %rax
    movl -64(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    leaq L_GVN_OP(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
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
    leaq L_GVN_TA(%rip), %rax
    pushq %rax
    movl -64(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    movl -24(%rbp), %eax
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
    leaq L_GVN_TB(%rip), %rax
    pushq %rax
    movl -64(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    movl -32(%rbp), %eax
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
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    leaq L_GVN_TVN(%rip), %rax
    pushq %rax
    movl -64(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_13:
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_11:
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_9:
    movl -64(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_6
L_loop_end_7:
    movl -40(%rbp), %eax
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
    jz L_if_end_15
    leaq L_GVN_VN(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_GVN_RED(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
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
L_if_end_15:
    movl -40(%rbp), %eax
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
    leaq L_GVN_VN(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_GVN_RED(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_GVN_TOP(%rip), %rax
    pushq %rax
    movl -56(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_GVN_OP(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_GVN_TA(%rip), %rax
    pushq %rax
    movl -56(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_GVN_TB(%rip), %rax
    pushq %rax
    movl -56(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_GVN_TVN(%rip), %rax
    pushq %rax
    movl -56(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_GVN_TSZ(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movl -56(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_17:
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_5:
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
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_0
L_loop_end_1:
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
    .asciz "gvn_vn"
    .text
    .global gvn_vn
    .seh_proc gvn_vn
gvn_vn:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movl -8(%rbp), %eax
    pushq %rax
    movl L_GVN_N(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_19
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_19:
    leaq L_GVN_VN(%rip), %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
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
    .asciz "gvn_redundant"
    .text
    .global gvn_redundant
    .seh_proc gvn_redundant
gvn_redundant:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movl -8(%rbp), %eax
    pushq %rax
    movl L_GVN_N(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_21
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_21:
    leaq L_GVN_RED(%rip), %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
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
    .asciz "gvn_redundant_count"
    .text
    .global gvn_redundant_count
    .seh_proc gvn_redundant_count
gvn_redundant_count:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
L_loop_top_22:
    movl -16(%rbp), %eax
    pushq %rax
    movl L_GVN_N(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_23
    movl -8(%rbp), %eax
    pushq %rax
    leaq L_GVN_RED(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
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
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_22
L_loop_end_23:
    movl -8(%rbp), %eax
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
    .asciz "gvn_kat"
    .text
    .global gvn_kat
    .seh_proc gvn_kat
gvn_kat:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    subq $32, %rsp
    callq gvn_setup
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq gvn_number
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq gvn_vn
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    subq $8, %rsp
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq gvn_vn
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
    jz L_if_end_25
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_25:
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq gvn_vn
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    subq $8, %rsp
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq gvn_vn
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
    jz L_if_end_27
    movabsq $0x2, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_27:
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq gvn_vn
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    subq $8, %rsp
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq gvn_vn
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
    jz L_if_end_29
    movabsq $0x3, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_29:
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq gvn_vn
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    subq $8, %rsp
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq gvn_vn
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
    jz L_if_end_31
    movabsq $0x4, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_31:
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq gvn_redundant
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
    jz L_if_end_33
    movabsq $0x5, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_33:
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq gvn_redundant
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
    jz L_if_end_35
    movabsq $0x6, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_35:
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq gvn_redundant
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
    jz L_if_end_37
    movabsq $0x7, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_37:
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq gvn_redundant
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
    jz L_if_end_39
    movabsq $0x8, %rax
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
    callq gvn_redundant_count
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0x2, %rax
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
    movabsq $0x9, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_41:
    movabsq $0x6, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq gvn_redundant
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
    jz L_if_end_43
    movabsq $0xa, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_43:
    movabsq $0x6, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq gvn_vn
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    subq $8, %rsp
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq gvn_vn
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
    jz L_if_end_45
    movabsq $0xb, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_45:
    movabsq $0x6, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq gvn_vn
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    subq $8, %rsp
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq gvn_vn
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
    jz L_if_end_47
    movabsq $0xc, %rax
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
