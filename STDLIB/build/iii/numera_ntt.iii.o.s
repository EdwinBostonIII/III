# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "modular_mont.iiimodular_mont.iii\0"
L_str_1:
    .ascii "modular_mont.iii\0"
    .section .rodata
L_NTT_MAXN:
    .quad 0x2000
    .section .bss
    .global L_NTT_W
L_NTT_W:
    .zero 65536
    .global L_NTT_SAVE
L_NTT_SAVE:
    .zero 65536
    .global L_NTT_B
L_NTT_B:
    .zero 65536
    .section .iii.ring3,"n"
    .asciz "ntt_add"
    .text
    .global L_ntt_add
    .seh_proc L_ntt_add
L_ntt_add:
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
    movl -8(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movl -24(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq -32(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_1
    movq -32(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_1:
    movq -32(%rbp), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
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
    .asciz "ntt_sub"
    .text
    .global L_ntt_sub
    .seh_proc L_ntt_sub
L_ntt_sub:
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
    movl -8(%rbp), %eax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_3
    movl -8(%rbp), %eax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    movl %eax, %eax
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
    popq %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
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
    .asciz "ntt_mul"
    .text
    .global L_ntt_mul
    .seh_proc L_ntt_mul
L_ntt_mul:
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
    movl -8(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq -32(%rbp), %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorl %edx, %edx
    divq %rcx
    movq %rdx, %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
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
    .asciz "ntt_pow"
    .text
    .global L_ntt_pow
    .seh_proc L_ntt_pow
L_ntt_pow:
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
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movl -8(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
L_loop_top_4:
    movq -48(%rbp), %rax
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
    jz L_loop_end_5
    movq -48(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
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
    movl -40(%rbp), %eax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L_ntt_mul
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_7:
    movl -24(%rbp), %eax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L_ntt_mul
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq -48(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    shrq %cl, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_4
L_loop_end_5:
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
    .asciz "ntt_inv"
    .text
    .global L_ntt_inv
    .seh_proc L_ntt_inv
L_ntt_inv:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movl -16(%rbp), %eax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L_ntt_pow
    addq $32, %rsp
    movl %eax, %eax
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
    .asciz "ntt_set"
    .text
    .global ntt_set
    .seh_proc ntt_set
ntt_set:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    leaq L_NTT_W(%rip), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movl -16(%rbp), %eax
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
    .asciz "ntt_get"
    .text
    .global ntt_get
    .seh_proc ntt_get
ntt_get:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    leaq L_NTT_W(%rip), %rax
    pushq %rax
    movq -8(%rbp), %rax
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
    .asciz "ntt_set_b"
    .text
    .global ntt_set_b
    .seh_proc ntt_set_b
ntt_set_b:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    leaq L_NTT_B(%rip), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movl -16(%rbp), %eax
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
    .asciz "ntt_bitrev_at"
    .text
    .global L_ntt_bitrev_at
    .seh_proc L_ntt_bitrev_at
L_ntt_bitrev_at:
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
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
L_loop_top_8:
    movq -40(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_9
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    shrq %cl, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
L_loop_top_10:
    movq -32(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
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
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_11
    movq -32(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq -48(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    shrq %cl, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_10
L_loop_end_11:
    movq -32(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq -40(%rbp), %rax
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
    jz L_if_end_13
    movq -24(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movq -24(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movl -56(%rbp), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_13:
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_8
L_loop_end_9:
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
    .asciz "ntt_forward_at"
    .text
    .global ntt_forward_at
    .seh_proc ntt_forward_at
ntt_forward_at:
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
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_ntt_bitrev_at
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
L_loop_top_14:
    movq -48(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setbe %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_15
    movl -24(%rbp), %eax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorl %edx, %edx
    divq %rcx
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L_ntt_pow
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq -48(%rbp), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorl %edx, %edx
    divq %rcx
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
L_loop_top_16:
    movq -72(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_17
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rax, -80(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
L_loop_top_18:
    movq -88(%rbp), %rax
    pushq %rax
    movq -64(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_19
    movq -40(%rbp), %rax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    movq -88(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    movq %rax, -96(%rbp)
    movl -24(%rbp), %eax
    pushq %rax
    movl -80(%rbp), %eax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    movq -88(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    movq -64(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L_ntt_mul
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -104(%rbp)
    movq -40(%rbp), %rax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    movq -88(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    movl -104(%rbp), %eax
    pushq %rax
    movl -96(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L_ntt_add
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movq -40(%rbp), %rax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    movq -88(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    movq -64(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    movl -104(%rbp), %eax
    pushq %rax
    movl -96(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L_ntt_sub
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movl -24(%rbp), %eax
    pushq %rax
    movl -56(%rbp), %eax
    pushq %rax
    movl -80(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L_ntt_mul
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -80(%rbp)
    movq -88(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_18
L_loop_end_19:
    movq -72(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_16
L_loop_end_17:
    movq -48(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    shlq %cl, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_14
L_loop_end_15:
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
    .asciz "ntt_inverse_at"
    .text
    .global ntt_inverse_at
    .seh_proc ntt_inverse_at
ntt_inverse_at:
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
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movl -24(%rbp), %eax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_ntt_inv
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movl -48(%rbp), %eax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq ntt_forward_at
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movl -24(%rbp), %eax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_ntt_inv
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
L_loop_top_20:
    movq -64(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_21
    movq -40(%rbp), %rax
    pushq %rax
    movq -64(%rbp), %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    movl -56(%rbp), %eax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movq -64(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L_ntt_mul
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
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
    jmp L_loop_top_20
L_loop_end_21:
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
    .asciz "ntt_ct_forward_tabled"
    .text
    .global ntt_ct_forward_tabled
    .seh_proc ntt_ct_forward_tabled
ntt_ct_forward_tabled:
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
    movq 48(%rbp), %rax
    movq %rax, -40(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq -32(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq mont_n_inv_neg
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    shrq %cl, %rax
    pushq %rax
    popq %rax
    movq %rax, -80(%rbp)
L_loop_top_22:
    movq -80(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_23
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
L_loop_top_24:
    movq -88(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
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
    movq -56(%rbp), %rax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -96(%rbp)
    movq -72(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movq -88(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -104(%rbp)
L_loop_top_26:
    movq -104(%rbp), %rax
    pushq %rax
    movq -88(%rbp), %rax
    pushq %rax
    movq -80(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_27
    movq -48(%rbp), %rax
    pushq %rax
    movq -104(%rbp), %rax
    pushq %rax
    movq -80(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -112(%rbp)
    movq -64(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movq -112(%rbp), %rax
    pushq %rax
    movq -96(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq mont_redc
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -120(%rbp)
    movq -48(%rbp), %rax
    pushq %rax
    movq -104(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -128(%rbp)
    movq -128(%rbp), %rax
    pushq %rax
    movq -120(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -136(%rbp)
    movq -136(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_29
    movq -136(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -136(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_29:
    movq -128(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    movq -120(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -144(%rbp)
    movq -144(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_31
    movq -144(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -144(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_31:
    movq -48(%rbp), %rax
    pushq %rax
    movq -104(%rbp), %rax
    pushq %rax
    movq -136(%rbp), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movq -48(%rbp), %rax
    pushq %rax
    movq -104(%rbp), %rax
    pushq %rax
    movq -80(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    movq -144(%rbp), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movq -104(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -104(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_26
L_loop_end_27:
    movq -104(%rbp), %rax
    pushq %rax
    movq -80(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_24
L_loop_end_25:
    movq -80(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    shrq %cl, %rax
    pushq %rax
    popq %rax
    movq %rax, -80(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_22
L_loop_end_23:
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
    .asciz "ntt_gs_inverse_tabled"
    .text
    .global ntt_gs_inverse_tabled
    .seh_proc ntt_gs_inverse_tabled
ntt_gs_inverse_tabled:
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
    movq 48(%rbp), %rax
    movq %rax, -40(%rbp)
    movq 56(%rbp), %rax
    movq %rax, -48(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq -32(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq mont_n_inv_neg
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movq -48(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -80(%rbp)
    movq -40(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    shrq %cl, %rax
    pushq %rax
    popq %rax
    movq %rax, -96(%rbp)
L_loop_top_32:
    movq -88(%rbp), %rax
    pushq %rax
    movq -96(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setbe %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_33
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -104(%rbp)
L_loop_top_34:
    movq -104(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_35
    movq -64(%rbp), %rax
    pushq %rax
    movq -80(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -112(%rbp)
    movq -80(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -80(%rbp)
    movq -104(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -120(%rbp)
L_loop_top_36:
    movq -120(%rbp), %rax
    pushq %rax
    movq -104(%rbp), %rax
    pushq %rax
    movq -88(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_37
    movq -56(%rbp), %rax
    pushq %rax
    movq -120(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -128(%rbp)
    movq -56(%rbp), %rax
    pushq %rax
    movq -120(%rbp), %rax
    pushq %rax
    movq -88(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -136(%rbp)
    movq -128(%rbp), %rax
    pushq %rax
    movq -136(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -144(%rbp)
    movq -144(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
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
    movq -144(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -144(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_39:
    movq -56(%rbp), %rax
    pushq %rax
    movq -120(%rbp), %rax
    pushq %rax
    movq -144(%rbp), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movq -136(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    movq -128(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -152(%rbp)
    movq -152(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_41
    movq -152(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -152(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_41:
    movq -56(%rbp), %rax
    pushq %rax
    movq -120(%rbp), %rax
    pushq %rax
    movq -88(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movq -152(%rbp), %rax
    pushq %rax
    movq -112(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq mont_redc
    addq $32, %rsp
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movq -120(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -120(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_36
L_loop_end_37:
    movq -120(%rbp), %rax
    pushq %rax
    movq -88(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -104(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_34
L_loop_end_35:
    movq -88(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    shlq %cl, %rax
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_32
L_loop_end_33:
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
    .asciz "ntt_bitrev"
    .text
    .global L_ntt_bitrev
    .seh_proc L_ntt_bitrev
L_ntt_bitrev:
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
    leaq L_NTT_W(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_ntt_bitrev_at
    addq $32, %rsp
    movslq %eax, %rax
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
    .asciz "ntt_forward"
    .text
    .global ntt_forward
    .seh_proc ntt_forward
ntt_forward:
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
    movl -24(%rbp), %eax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    leaq L_NTT_W(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq ntt_forward_at
    addq $32, %rsp
    movslq %eax, %rax
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
    .asciz "ntt_inverse"
    .text
    .global ntt_inverse
    .seh_proc ntt_inverse
ntt_inverse:
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
    movl -24(%rbp), %eax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    leaq L_NTT_W(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq ntt_inverse_at
    addq $32, %rsp
    movslq %eax, %rax
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
    .asciz "ntt_selftest"
    .text
    .global ntt_selftest
    .seh_proc ntt_selftest
ntt_selftest:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movabsq $0x3b800001, %rax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movabsq $0x8, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movabsq $0x3, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movl -8(%rbp), %eax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorl %edx, %edx
    divq %rcx
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L_ntt_pow
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
L_loop_top_42:
    movq -40(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
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
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    leaq L_NTT_W(%rip), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NTT_SAVE(%rip), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_42
L_loop_end_43:
    movl -32(%rbp), %eax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq ntt_forward
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movl -32(%rbp), %eax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq ntt_inverse
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
L_loop_top_44:
    movq -48(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
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
    leaq L_NTT_W(%rip), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    leaq L_NTT_SAVE(%rip), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
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
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_47:
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
    jmp L_loop_top_44
L_loop_end_45:
    leaq L_NTT_W(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
L_loop_top_48:
    movq -56(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_49
    leaq L_NTT_W(%rip), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movq -56(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_48
L_loop_end_49:
    movl -32(%rbp), %eax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq ntt_forward
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
L_loop_top_50:
    movq -64(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
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
    leaq L_NTT_W(%rip), %rax
    pushq %rax
    movq -64(%rbp), %rax
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
    jz L_if_end_53
    movabsq $0x2, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_53:
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
    jmp L_loop_top_50
L_loop_end_51:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
L_loop_top_54:
    movq -72(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
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
    leaq L_NTT_W(%rip), %rax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movq -72(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_54
L_loop_end_55:
    movl -32(%rbp), %eax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq ntt_forward
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    leaq L_NTT_W(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
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
    jz L_if_end_57
    movabsq $0x3, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_57:
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
    .section .iii.ring3,"n"
    .asciz "ntt_convolve"
    .text
    .global ntt_convolve
    .seh_proc ntt_convolve
ntt_convolve:
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
    movl -24(%rbp), %eax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq ntt_forward
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
L_loop_top_58:
    movq -32(%rbp), %rax
    pushq %rax
    movq -8(%rbp), %rax
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
    leaq L_NTT_SAVE(%rip), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    leaq L_NTT_W(%rip), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
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
    jmp L_loop_top_58
L_loop_end_59:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
L_loop_top_60:
    movq -40(%rbp), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_61
    leaq L_NTT_W(%rip), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    leaq L_NTT_B(%rip), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_60
L_loop_end_61:
    movl -24(%rbp), %eax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq ntt_forward
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
L_loop_top_62:
    movq -48(%rbp), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_63
    movl -16(%rbp), %eax
    pushq %rax
    leaq L_NTT_W(%rip), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    leaq L_NTT_SAVE(%rip), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L_ntt_mul
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    leaq L_NTT_W(%rip), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    movl -56(%rbp), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
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
    jmp L_loop_top_62
L_loop_end_63:
    movl -24(%rbp), %eax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq ntt_inverse
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
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
    .asciz "ntt_conv_selftest"
    .text
    .global ntt_conv_selftest
    .seh_proc ntt_conv_selftest
ntt_conv_selftest:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movabsq $0x3b800001, %rax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movabsq $0x8, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movabsq $0x3, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movl -8(%rbp), %eax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorl %edx, %edx
    divq %rcx
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L_ntt_pow
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
L_loop_top_64:
    movq -40(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_65
    leaq L_NTT_W(%rip), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NTT_B(%rip), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_64
L_loop_end_65:
    leaq L_NTT_W(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NTT_W(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NTT_W(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NTT_W(%rip), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NTT_B(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NTT_B(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NTT_B(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NTT_B(%rip), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movl -32(%rbp), %eax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq ntt_convolve
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    leaq L_NTT_W(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
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
    jz L_if_end_67
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_67:
    leaq L_NTT_W(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_69
    movabsq $0x2, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_69:
    leaq L_NTT_W(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    movabsq $0x22, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_71
    movabsq $0x3, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_71:
    leaq L_NTT_W(%rip), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    movabsq $0x3c, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_73
    movabsq $0x4, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_73:
    leaq L_NTT_W(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    movabsq $0x3d, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_75
    movabsq $0x5, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_75:
    leaq L_NTT_W(%rip), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    movabsq $0x34, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_77
    movabsq $0x6, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_77:
    leaq L_NTT_W(%rip), %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    movabsq $0x20, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_79
    movabsq $0x7, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_79:
    leaq L_NTT_W(%rip), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
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
    jz L_if_end_81
    movabsq $0x8, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_81:
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
