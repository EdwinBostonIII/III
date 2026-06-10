# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "pbkdf2.iii\0"
    .section .data
    .global L_PW
L_PW:
    .byte 0x70
    .byte 0x61
    .byte 0x73
    .byte 0x73
    .byte 0x77
    .byte 0x64
    .global L_SALT
L_SALT:
    .byte 0x73
    .byte 0x61
    .byte 0x6c
    .byte 0x74
    .section .bss
    .global L_DK
L_DK:
    .zero 512
    .section .data
    .global L_EXP
L_EXP:
    .byte 0x55
    .byte 0xac
    .byte 0x4
    .byte 0x6e
    .byte 0x56
    .byte 0xe3
    .byte 0x8
    .byte 0x9f
    .byte 0xec
    .byte 0x16
    .byte 0x91
    .byte 0xc2
    .byte 0x25
    .byte 0x44
    .byte 0xb6
    .byte 0x5
    .byte 0xf9
    .byte 0x41
    .byte 0x85
    .byte 0x21
    .byte 0x6d
    .byte 0xde
    .byte 0x4
    .byte 0x65
    .byte 0xe6
    .byte 0x8b
    .byte 0x9d
    .byte 0x57
    .byte 0xc2
    .byte 0xd
    .byte 0xac
    .byte 0xbc
    .byte 0x49
    .byte 0xca
    .byte 0x9c
    .byte 0xcc
    .byte 0xf1
    .byte 0x79
    .byte 0xb6
    .byte 0x45
    .byte 0x99
    .byte 0x16
    .byte 0x64
    .byte 0xb3
    .byte 0x9d
    .byte 0x77
    .byte 0xef
    .byte 0x31
    .byte 0x7c
    .byte 0x71
    .byte 0xb8
    .byte 0x45
    .byte 0xb1
    .byte 0xe3
    .byte 0xb
    .byte 0xd5
    .byte 0x9
    .byte 0x11
    .byte 0x20
    .byte 0x41
    .byte 0xd3
    .byte 0xa1
    .byte 0x97
    .byte 0x83
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
    subq $8, %rsp
    movabsq $0x40, %rax
    pushq %rax
    leaq L_DK(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_SALT(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    leaq L_PW(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq pbkdf2_sha256_oneshot
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movslq -8(%rbp), %rax
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
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
L_loop_top_2:
    movq -16(%rbp), %rax
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
    jz L_loop_end_3
    leaq L_DK(%rip), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    leaq L_EXP(%rip), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
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
    movabsq $0xa, %rax
    pushq %rax
    movq -16(%rbp), %rax
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
L_if_end_5:
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_2
L_loop_end_3:
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
