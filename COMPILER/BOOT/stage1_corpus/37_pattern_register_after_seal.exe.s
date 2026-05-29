# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "pattern_table.iiipattern_table.iiipattern_table.iii\0"
L_str_1:
    .ascii "pattern_table.iiipattern_table.iii\0"
L_str_2:
    .ascii "pattern_table.iii\0"
    .section .bss
    .global L_TMPL
L_TMPL:
    .zero 1344
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
    callq pattern_registry_seal_global
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq pattern_registry_is_sealed
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
    leaq L_TMPL(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x7d0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq pattern_register
    addq $32, %rsp
    movzbq %al, %rax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movzbq -8(%rbp), %rax
    pushq %rax
    popq %rax
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
