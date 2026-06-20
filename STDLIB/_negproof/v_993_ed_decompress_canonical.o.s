# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "fe25519.iii\0"
L_str_1:
    .ascii "fe25519.iii\0"
    .section .rodata
L_ADMIT:
    .quad 0x0
L_REJ:
    .quad 0x1
    .section .bss
    .global L_PKE
L_PKE:
    .zero 256
    .global L_BAD
L_BAD:
    .zero 256
    .global L_PTR
L_PTR:
    .zero 256
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
    callq fe25519_init
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    leaq L_PKE(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0xd7, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_PKE(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x5a, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_PKE(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x98, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_PKE(%rip), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_PKE(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x82, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_PKE(%rip), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0xb1, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_PKE(%rip), %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_PKE(%rip), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    movabsq $0xb7, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_PKE(%rip), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    movabsq $0xd5, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_PKE(%rip), %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    movabsq $0x4b, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_PKE(%rip), %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0xfe, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_PKE(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    movabsq $0xd3, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_PKE(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    movabsq $0xc9, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_PKE(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    movabsq $0x64, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_PKE(%rip), %rax
    pushq %rax
    movabsq $0xe, %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_PKE(%rip), %rax
    pushq %rax
    movabsq $0xf, %rax
    pushq %rax
    movabsq $0x3a, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_PKE(%rip), %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    movabsq $0xe, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_PKE(%rip), %rax
    pushq %rax
    movabsq $0x11, %rax
    pushq %rax
    movabsq $0xe1, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_PKE(%rip), %rax
    pushq %rax
    movabsq $0x12, %rax
    pushq %rax
    movabsq $0x72, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_PKE(%rip), %rax
    pushq %rax
    movabsq $0x13, %rax
    pushq %rax
    movabsq $0xf3, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_PKE(%rip), %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    movabsq $0xda, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_PKE(%rip), %rax
    pushq %rax
    movabsq $0x15, %rax
    pushq %rax
    movabsq $0xa6, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_PKE(%rip), %rax
    pushq %rax
    movabsq $0x16, %rax
    pushq %rax
    movabsq $0x23, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_PKE(%rip), %rax
    pushq %rax
    movabsq $0x17, %rax
    pushq %rax
    movabsq $0x25, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_PKE(%rip), %rax
    pushq %rax
    movabsq $0x18, %rax
    pushq %rax
    movabsq $0xaf, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_PKE(%rip), %rax
    pushq %rax
    movabsq $0x19, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_PKE(%rip), %rax
    pushq %rax
    movabsq $0x1a, %rax
    pushq %rax
    movabsq $0x1a, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_PKE(%rip), %rax
    pushq %rax
    movabsq $0x1b, %rax
    pushq %rax
    movabsq $0x68, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_PKE(%rip), %rax
    pushq %rax
    movabsq $0x1c, %rax
    pushq %rax
    movabsq $0xf7, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_PKE(%rip), %rax
    pushq %rax
    movabsq $0x1d, %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_PKE(%rip), %rax
    pushq %rax
    movabsq $0x1e, %rax
    pushq %rax
    movabsq $0x51, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_PKE(%rip), %rax
    pushq %rax
    movabsq $0x1f, %rax
    pushq %rax
    movabsq $0x1a, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
L_loop_top_0:
    movq -8(%rbp), %rax
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
    leaq L_BAD(%rip), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_0
L_loop_end_1:
    leaq L_PTR(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_PKE(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq ed_decompress
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    movslq L_ADMIT(%rip), %rax
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
    leaq L_PTR(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_BAD(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq ed_decompress
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    movslq L_REJ(%rip), %rax
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
