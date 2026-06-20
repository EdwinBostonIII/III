# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "weave_graph.iii\0"
L_str_1:
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
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x96, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq ws_synth
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x80, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq ws_synth
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0xfe, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq ws_synth
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq ws_saturate
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xf4240, %rax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x186a0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x2710, %rax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    movq -32(%rbp), %rax
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
