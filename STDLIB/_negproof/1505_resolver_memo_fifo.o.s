# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "resolver_memo.iii\0"
L_str_1:
    .ascii "resolver_memo.iii\0"
L_str_2:
    .ascii "resolver_memo.iii\0"
L_str_3:
    .ascii "resolver_memo.iii\0"
L_str_4:
    .ascii "resolver_memo.iii\0"
L_str_5:
    .ascii "resolver_memo.iii\0"
L_str_6:
    .ascii "resolver_memo.iii\0"
    .section .rodata
L_NOT_FOUND:
    .quad 0xffffffff
L_KEY_A:
    .quad 0xa
L_KEY_B:
    .quad 0xb
L_KEY_C:
    .quad 0xc
L_KEY_D:
    .quad 0xd00000
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
    callq memo_reset
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq memo_used
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
    movabsq $0xa1, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movq L_KEY_A(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq memo_insert
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movabsq $0xb1, %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    movq L_KEY_B(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq memo_insert
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movabsq $0xc1, %rax
    pushq %rax
    movabsq $0x1e, %rax
    pushq %rax
    movq L_KEY_C(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq memo_insert
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq memo_used
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0x3, %rax
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
    movq L_KEY_A(%rip), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq memo_lookup
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_KEY_B(%rip), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq memo_lookup
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movq L_KEY_C(%rip), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq memo_lookup
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movl -8(%rbp), %eax
    pushq %rax
    movl L_NOT_FOUND(%rip), %eax
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
    movl -16(%rbp), %eax
    pushq %rax
    movl L_NOT_FOUND(%rip), %eax
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
    movl -24(%rbp), %eax
    pushq %rax
    movl L_NOT_FOUND(%rip), %eax
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
    movl -8(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq memo_seq
    addq $32, %rsp
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
    movl -16(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq memo_seq
    addq $32, %rsp
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
    movl -24(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq memo_seq
    addq $32, %rsp
    pushq %rax
    movabsq $0x3, %rax
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
    movabsq $0xa2, %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    movq L_KEY_A(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq memo_insert
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movl -32(%rbp), %eax
    pushq %rax
    movl -8(%rbp), %eax
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
    subq $32, %rsp
    callq memo_used
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0x3, %rax
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
    movl -32(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq memo_seq
    addq $32, %rsp
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
    movl -32(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq memo_pattern_id
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0xb, %rax
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
    movl -32(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq memo_dispatch_fp
    addq $32, %rsp
    pushq %rax
    movabsq $0xa2, %rax
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
    movabsq $0xd, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_25:
    movq L_KEY_B(%rip), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq memo_lookup
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq memo_seq
    addq $32, %rsp
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
    jz L_if_end_27
    movabsq $0xe, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_27:
    movq L_KEY_C(%rip), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq memo_lookup
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq memo_seq
    addq $32, %rsp
    pushq %rax
    movabsq $0x3, %rax
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
    movabsq $0xf, %rax
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
    popq %rax
    movq %rax, -40(%rbp)
L_loop_top_30:
    movl -40(%rbp), %eax
    pushq %rax
    movabsq $0xffd, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_31
    movabsq $0x10000, %rax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq memo_insert
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movl -40(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_30
L_loop_end_31:
    subq $32, %rsp
    callq memo_used
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0x1000, %rax
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
    movabsq $0x10, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_33:
    movabsq $0xd1, %rax
    pushq %rax
    movabsq $0x63, %rax
    pushq %rax
    movq L_KEY_D(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq memo_insert
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movl -48(%rbp), %eax
    pushq %rax
    movl L_NOT_FOUND(%rip), %eax
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
    movabsq $0x11, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_35:
    movq L_KEY_A(%rip), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq memo_lookup
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movl L_NOT_FOUND(%rip), %eax
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
    movabsq $0x12, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_37:
    movq L_KEY_B(%rip), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq memo_lookup
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movl L_NOT_FOUND(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_39
    movabsq $0x13, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_39:
    movq L_KEY_C(%rip), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq memo_lookup
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movl L_NOT_FOUND(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_41
    movabsq $0x14, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_41:
    movq L_KEY_D(%rip), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq memo_lookup
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movl L_NOT_FOUND(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_43
    movabsq $0x15, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_43:
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
