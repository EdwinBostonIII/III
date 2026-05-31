# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "congruence.iiicongruence.iiiripple_metric.iiiripple_metric.iiiripple_extract.iiiripple_extract.iiiripple_extract.iiiripple_extract.iiiripple_extract.iiiripple_extract.iiiripple_extract.iii\0"
L_str_1:
    .ascii "congruence.iiiripple_metric.iiiripple_metric.iiiripple_extract.iiiripple_extract.iiiripple_extract.iiiripple_extract.iiiripple_extract.iiiripple_extract.iiiripple_extract.iii\0"
L_str_2:
    .ascii "ripple_metric.iiiripple_metric.iiiripple_extract.iiiripple_extract.iiiripple_extract.iiiripple_extract.iiiripple_extract.iiiripple_extract.iiiripple_extract.iii\0"
L_str_3:
    .ascii "ripple_metric.iiiripple_extract.iiiripple_extract.iiiripple_extract.iiiripple_extract.iiiripple_extract.iiiripple_extract.iiiripple_extract.iii\0"
L_str_4:
    .ascii "ripple_extract.iiiripple_extract.iiiripple_extract.iiiripple_extract.iiiripple_extract.iiiripple_extract.iiiripple_extract.iii\0"
L_str_5:
    .ascii "ripple_extract.iiiripple_extract.iiiripple_extract.iiiripple_extract.iiiripple_extract.iiiripple_extract.iii\0"
L_str_6:
    .ascii "ripple_extract.iiiripple_extract.iiiripple_extract.iiiripple_extract.iiiripple_extract.iii\0"
L_str_7:
    .ascii "ripple_extract.iiiripple_extract.iiiripple_extract.iiiripple_extract.iii\0"
L_str_8:
    .ascii "ripple_extract.iiiripple_extract.iiiripple_extract.iii\0"
L_str_9:
    .ascii "ripple_extract.iiiripple_extract.iii\0"
L_str_10:
    .ascii "ripple_extract.iii\0"
    .section .bss
    .global L_GA
L_GA:
    .zero 256
    .global L_GB
L_GB:
    .zero 256
    .global L_FH
L_FH:
    .zero 256
    .section .iii.ring3,"n"
    .asciz "fill32"
    .text
    .global L_fill32
    .seh_proc L_fill32
L_fill32:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
L_loop_top_0:
    movq -24(%rbp), %rax
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
    movq -8(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movzbq -16(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
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
    movabsq $0x0, %rax
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
    callq cgr_init
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    leaq L_GA(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    leaq L_GB(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    leaq L_FH(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movabsq $0x11, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_fill32
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x5, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq cgr_intern
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movabsq $0x22, %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_fill32
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x5, %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq cgr_intern
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movabsq $0x99, %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_fill32
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq rx_export_in_g
    addq $32, %rsp
    movl %eax, %eax
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
    jz L_if_end_3
    movabsq $0xa, %rax
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
    popq %rcx
    subq $32, %rsp
    callq rx_export_in_g
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
    jz L_if_end_5
    movabsq $0xb, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_5:
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0x32, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq rx_delta_j_positive
    addq $32, %rsp
    movl %eax, %eax
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
    jz L_if_end_7
    movabsq $0x14, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_7:
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq rx_delta_j_positive
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
    jz L_if_end_9
    movabsq $0x15, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_9:
    subq $32, %rsp
    callq rx_dep_reset
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq rx_add_dep
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq rx_acyclic_insert
    addq $32, %rsp
    movl %eax, %eax
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
    movabsq $0x1e, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_11:
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq rx_acyclic_insert
    addq $32, %rsp
    movl %eax, %eax
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
    jz L_if_end_13
    movabsq $0x1f, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_13:
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq rx_add_dep
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq rx_acyclic_insert
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
    jz L_if_end_15
    movabsq $0x20, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_15:
    subq $32, %rsp
    callq rm_reset
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xcafe, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq rm_add_node
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movabsq $0x64, %rax
    pushq %rax
    movabsq $0xcafe, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq rm_add_node
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xcafe, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq rm_add_node
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movl -32(%rbp), %eax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq rx_h10_blocks_remerge
    addq $32, %rsp
    movl %eax, %eax
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
    jz L_if_end_17
    movabsq $0x28, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_17:
    movl -32(%rbp), %eax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq rx_h10_blocks_remerge
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
    jz L_if_end_19
    movabsq $0x29, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_19:
    subq $8, %rsp
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq rx_certify_extract
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
    movl %eax, %eax
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
    movabsq $0x32, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_21:
    subq $8, %rsp
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq rx_certify_extract
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
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
    jz L_if_end_23
    movabsq $0x33, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_23:
    subq $8, %rsp
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq rx_certify_extract
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
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
    jz L_if_end_25
    movabsq $0x34, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_25:
    subq $8, %rsp
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq rx_certify_extract
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
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
    jz L_if_end_27
    movabsq $0x35, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_27:
    subq $8, %rsp
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq rx_certify_extract
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
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
    jz L_if_end_29
    movabsq $0x36, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_29:
    subq $8, %rsp
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq rx_certify_extract
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
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
    jz L_if_end_31
    movabsq $0x37, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_31:
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
