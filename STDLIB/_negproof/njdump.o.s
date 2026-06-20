# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "xii_joinability.iii\0"
L_str_1:
    .ascii "xii_joinability.iii\0"
L_str_2:
    .ascii "xii_joinability.iii\0"
L_str_3:
    .ascii "xii_joinability.iii\0"
L_str_4:
    .ascii "xii_joinability.iii\0"
L_str_5:
    .ascii "kernel32\0"
L_str_6:
    .ascii "kernel32\0"
L_str_7:
    .ascii "kernel32\0"
    .section .bss
    .global L_NJD_NAME
L_NJD_NAME:
    .zero 128
    .global L_NJD_BUF
L_NJD_BUF:
    .zero 4096
    .global L_NJD_NW
L_NJD_NW:
    .zero 8
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
    callq xjn_gate
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq xjn_nonjoin_count
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    seta %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_1
    movabsq $0x14, %rax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_1:
    leaq L_NJD_NAME(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x6e, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_NJD_NAME(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x6a, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_NJD_NAME(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x64, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_NJD_NAME(%rip), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x75, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_NJD_NAME(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x6d, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_NJD_NAME(%rip), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x70, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_NJD_NAME(%rip), %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0x2e, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_NJD_NAME(%rip), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    movabsq $0x62, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_NJD_NAME(%rip), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    movabsq $0x69, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_NJD_NAME(%rip), %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    movabsq $0x6e, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_NJD_NAME(%rip), %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
L_loop_top_2:
    movq -16(%rbp), %rax
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
    jz L_loop_end_3
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq xjn_njtab_i
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq xjn_njtab_j
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq xjn_njtab_p
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x18, %rax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
L_loop_top_4:
    movq -56(%rbp), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_5
    leaq L_NJD_BUF(%rip), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    popq %rax
    shlq $3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    shrq %cl, %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_NJD_BUF(%rip), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    popq %rax
    shlq $3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    shrq %cl, %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_NJD_BUF(%rip), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    popq %rax
    shlq $3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    shrq %cl, %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
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
    jmp L_loop_top_4
L_loop_end_5:
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
    subq $8, %rsp
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x80, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x40000000, %rax
    pushq %rax
    leaq L_NJD_NAME(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq CreateFileA
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0xffffffffffffffff, %rax
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
    movabsq $0xfa, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_7:
    subq $8, %rsp
    movabsq $0x0, %rax
    pushq %rax
    leaq L_NJD_NW(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x18, %rax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    leaq L_NJD_BUF(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq WriteFile
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq CloseHandle
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq xjn_nonjoin_count
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
