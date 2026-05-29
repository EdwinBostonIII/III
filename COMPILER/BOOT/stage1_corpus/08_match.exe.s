# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
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
    movabsq $0x2, %rax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movq -16(%rbp), %rax
    movabsq $0x1, %rcx
    cmpq %rcx, %rax
    jne L_skip_1
    movabsq $0xa, %rax
    pushq %rax
    jmp L_match_end_0
L_skip_1:
    movq -16(%rbp), %rax
    movabsq $0x2, %rcx
    cmpq %rcx, %rax
    jne L_skip_2
    movabsq $0x2a, %rax
    pushq %rax
    jmp L_match_end_0
L_skip_2:
    movq -16(%rbp), %rax
    cmpq %rax, %rax
    jne L_skip_3
    movabsq $0x63, %rax
    pushq %rax
    jmp L_match_end_0
L_skip_3:
    movq $0, %rax
    pushq %rax
L_match_end_0:
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
