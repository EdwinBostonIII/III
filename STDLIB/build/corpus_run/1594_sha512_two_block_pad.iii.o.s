# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "msvcrt\0"
L_str_1:
    .ascii "msvcrt\0"
L_str_2:
    .ascii "sha512.iii\0"
L_str_3:
    .ascii "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu\0"
    .section .bss
    .global L_EXP
L_EXP:
    .zero 512
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
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x8e, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x95, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x9b, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x75, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0xda, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0xe3, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0x13, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    movabsq $0xda, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    movabsq $0x8c, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    movabsq $0xf4, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0xf7, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    movabsq $0x28, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    movabsq $0xfc, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0xe, %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0xf, %rax
    pushq %rax
    movabsq $0x3f, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    movabsq $0x8f, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x11, %rax
    pushq %rax
    movabsq $0x77, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x12, %rax
    pushq %rax
    movabsq $0x79, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x13, %rax
    pushq %rax
    movabsq $0xc6, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    movabsq $0xeb, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x15, %rax
    pushq %rax
    movabsq $0x9f, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x16, %rax
    pushq %rax
    movabsq $0x7f, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x17, %rax
    pushq %rax
    movabsq $0xa1, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x18, %rax
    pushq %rax
    movabsq $0x72, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x19, %rax
    pushq %rax
    movabsq $0x99, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x1a, %rax
    pushq %rax
    movabsq $0xae, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x1b, %rax
    pushq %rax
    movabsq $0xad, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x1c, %rax
    pushq %rax
    movabsq $0xb6, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x1d, %rax
    pushq %rax
    movabsq $0x88, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x1e, %rax
    pushq %rax
    movabsq $0x90, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x1f, %rax
    pushq %rax
    movabsq $0x18, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x20, %rax
    pushq %rax
    movabsq $0x50, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x21, %rax
    pushq %rax
    movabsq $0x1d, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x22, %rax
    pushq %rax
    movabsq $0x28, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x23, %rax
    pushq %rax
    movabsq $0x9e, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x24, %rax
    pushq %rax
    movabsq $0x49, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x25, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x26, %rax
    pushq %rax
    movabsq $0xf7, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x27, %rax
    pushq %rax
    movabsq $0xe4, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x28, %rax
    pushq %rax
    movabsq $0x33, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x29, %rax
    pushq %rax
    movabsq $0x1b, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x2a, %rax
    pushq %rax
    movabsq $0x99, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x2b, %rax
    pushq %rax
    movabsq $0xde, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x2c, %rax
    pushq %rax
    movabsq $0xc4, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x2d, %rax
    pushq %rax
    movabsq $0xb5, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x2e, %rax
    pushq %rax
    movabsq $0x43, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x2f, %rax
    pushq %rax
    movabsq $0x3a, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x30, %rax
    pushq %rax
    movabsq $0xc7, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x31, %rax
    pushq %rax
    movabsq $0xd3, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x32, %rax
    pushq %rax
    movabsq $0x29, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x33, %rax
    pushq %rax
    movabsq $0xee, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x34, %rax
    pushq %rax
    movabsq $0xb6, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x35, %rax
    pushq %rax
    movabsq $0xdd, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x36, %rax
    pushq %rax
    movabsq $0x26, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x37, %rax
    pushq %rax
    movabsq $0x54, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x38, %rax
    pushq %rax
    movabsq $0x5e, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x39, %rax
    pushq %rax
    movabsq $0x96, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x3a, %rax
    pushq %rax
    movabsq $0xe5, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x3b, %rax
    pushq %rax
    movabsq $0x5b, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x3c, %rax
    pushq %rax
    movabsq $0x87, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x3d, %rax
    pushq %rax
    movabsq $0x4b, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x3e, %rax
    pushq %rax
    movabsq $0xe9, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_EXP(%rip), %rax
    pushq %rax
    movabsq $0x3f, %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_str_3(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movabsq $0x40, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq malloc
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x70, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq sha512_oneshot
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
L_loop_top_0:
    movq -24(%rbp), %rax
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
    jz L_loop_end_1
    movq -16(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    leaq L_EXP(%rip), %rax
    pushq %rax
    movq -24(%rbp), %rax
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
    jz L_if_end_3
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq free
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0xa, %rax
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
L_if_end_3:
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
    jmp L_loop_top_0
L_loop_end_1:
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq free
    addq $32, %rsp
    pushq %rax
    popq %rax
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
