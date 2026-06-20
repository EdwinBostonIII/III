# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "bitops.iii\0"
L_str_1:
    .ascii "bitops.iii\0"
L_str_2:
    .ascii "bitops.iii\0"
L_str_3:
    .ascii "bitops.iii\0"
L_str_4:
    .ascii "bitops.iii\0"
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
    movabsq $0x3f, %rax
    pushq %rax
    movabsq $0x123456789abcdef, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bitops_rotl64
    addq $32, %rsp
    pushq %rax
    movabsq $0x8091a2b3c4d5e6f7, %rax
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
    movabsq $0x3f, %rax
    pushq %rax
    movabsq $0x123456789abcdef, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bitops_rotr64
    addq $32, %rsp
    pushq %rax
    movabsq $0x2468acf13579bde, %rax
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
    movabsq $0x40, %rax
    pushq %rax
    movabsq $0x123456789abcdef, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bitops_rotl64
    addq $32, %rsp
    pushq %rax
    movabsq $0x123456789abcdef, %rax
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
    movabsq $0x40, %rax
    pushq %rax
    movabsq $0x123456789abcdef, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bitops_rotr64
    addq $32, %rsp
    pushq %rax
    movabsq $0x123456789abcdef, %rax
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
    movabsq $0x41, %rax
    pushq %rax
    movabsq $0x123456789abcdef, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bitops_rotl64
    addq $32, %rsp
    pushq %rax
    movabsq $0x2468acf13579bde, %rax
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
    movabsq $0x80, %rax
    pushq %rax
    movabsq $0x123456789abcdef, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bitops_rotl64
    addq $32, %rsp
    pushq %rax
    movabsq $0x123456789abcdef, %rax
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
    movabsq $0x1f, %rax
    pushq %rax
    movabsq $0x12345678, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bitops_rotl32
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0x91a2b3c, %rax
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
    movabsq $0x20, %rax
    pushq %rax
    movabsq $0x12345678, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bitops_rotl32
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0x12345678, %rax
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
    movabsq $0x20, %rax
    pushq %rax
    movabsq $0x12345678, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bitops_rotr32
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0x12345678, %rax
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
    movabsq $0x21, %rax
    pushq %rax
    movabsq $0x12345678, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bitops_rotl32
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0x2468acf0, %rax
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
    movabsq $0x8000000000000000, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq bitops_next_pow2_64
    addq $32, %rsp
    pushq %rax
    movabsq $0x8000000000000000, %rax
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
    movabsq $0x8000000000000001, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq bitops_next_pow2_64
    addq $32, %rsp
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
    movabsq $0xffffffffffffffff, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq bitops_next_pow2_64
    addq $32, %rsp
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
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq bitops_next_pow2_64
    addq $32, %rsp
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
