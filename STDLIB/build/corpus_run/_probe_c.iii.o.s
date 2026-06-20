# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "weave_graph.iii\0"
L_str_1:
    .ascii "weave_graph.iii\0"
L_str_2:
    .ascii "weave_graph.iii\0"
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
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq ws_secondkind_naive_cost
    addq $32, %rsp
    pushq %rax
    movabsq $0x3e8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    pushq %rax
    subq $8, %rsp
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq ws_secondkind_fold_cost
    addq $32, %rsp
    addq $8, %rsp
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    subq $8, %rsp
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq ws_secondkind_proven
    addq $32, %rsp
    addq $8, %rsp
    movzbq %al, %rax
    pushq %rax
    popq %rax
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
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
