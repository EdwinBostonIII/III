# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "resolution_init.iii\0"
L_str_1:
    .ascii "arena.iii\0"
L_str_2:
    .ascii "transform.iii\0"
L_str_3:
    .ascii "call_context.iii\0"
L_str_4:
    .ascii "call_context.iii\0"
L_str_5:
    .ascii "call_context.iii\0"
L_str_6:
    .ascii "transform_form.iii\0"
L_str_7:
    .ascii "transform_form.iii\0"
L_str_8:
    .ascii "transform_form.iii\0"
    .section .data
    .global L_SPEC
L_SPEC:
    .byte 0x73
    .byte 0x72
    .byte 0x63
    .byte 0x3d
    .byte 0x31
    .byte 0x2c
    .byte 0x20
    .byte 0x64
    .byte 0x73
    .byte 0x74
    .byte 0x3d
    .byte 0x33
    .byte 0x2c
    .byte 0x20
    .byte 0x69
    .byte 0x6e
    .byte 0x70
    .byte 0x75
    .byte 0x74
    .byte 0x3d
    .byte 0x30
    .byte 0x78
    .byte 0x43
    .byte 0x41
    .byte 0x46
    .byte 0x45
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
    callq resolution_init
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x10000, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq arena_new
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq transform_pattern_set_init
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0x2, %rax
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
    callq call_context_init_set
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq call_context_init_set_extras
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq call_context_new
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x1a, %rax
    pushq %rax
    leaq L_SPEC(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq transform_form_invoke
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    subq $32, %rsp
    callq transform_form_src_form
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
    jz L_if_end_1
    movabsq $0xa, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_1:
    subq $32, %rsp
    callq transform_form_dst_form
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0x3, %rax
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
    movabsq $0x14, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_3:
    movabsq $0x1, %rax
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
