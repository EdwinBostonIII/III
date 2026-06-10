# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "pattern.iii\0"
L_str_1:
    .ascii "pattern.iii\0"
L_str_2:
    .ascii "pattern.iii\0"
L_str_3:
    .ascii "pattern.iii\0"
L_str_4:
    .ascii "pattern.iii\0"
L_str_5:
    .ascii "pattern.iii\0"
L_str_6:
    .ascii "pattern.iii\0"
L_str_7:
    .ascii "pattern.iii\0"
L_str_8:
    .ascii "pattern.iii\0"
L_str_9:
    .ascii "pattern.iii\0"
L_str_10:
    .ascii "pattern.iii\0"
L_str_11:
    .ascii "pattern_table.iii\0"
L_str_12:
    .ascii "codegen_dispatch.iii\0"
L_str_13:
    .ascii "codegen_dispatch.iii\0"
    .section .rodata
L_HEXAD_COMPOSE:
    .quad 0x6
L_RING_R0:
    .quad 0x2
    .section .bss
    .global L_CG_MODULE_MHASH
L_CG_MODULE_MHASH:
    .zero 256
    .global L_CG_TEMPLATE_BUF
L_CG_TEMPLATE_BUF:
    .zero 1344
    .global L_CG_NAME_BUF
L_CG_NAME_BUF:
    .zero 256
    .section .data
    .global L_CG_REG_FAIL
L_CG_REG_FAIL:
    .quad 0x0
    .section .iii.ring3,"n"
    .asciz "_cg_register"
    .text
    .seh_proc L__cg_register
L__cg_register:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movq %r8, -24(%rbp)
    movq %r9, -32(%rbp)
    movq 48(%rbp), %rax
    movq %rax, -40(%rbp)
    movq 56(%rbp), %rax
    movq %rax, -48(%rbp)
    movq 64(%rbp), %rax
    movq %rax, -56(%rbp)
    leaq L_CG_TEMPLATE_BUF(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq pattern_template_zero
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    leaq L_CG_NAME_BUF(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movzbq -32(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_CG_NAME_BUF(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movzbq -40(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_CG_NAME_BUF(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movzbq -48(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_CG_NAME_BUF(%rip), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movzbq -56(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_CG_NAME_BUF(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movabsq $0x4, %rax
    pushq %rax
    leaq L_CG_NAME_BUF(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_CG_MODULE_MHASH(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_CG_TEMPLATE_BUF(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq pattern_template_set_id
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x3b9aca00, %rax
    pushq %rax
    leaq L_CG_TEMPLATE_BUF(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq pattern_template_set_activation_base
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movzbq L_HEXAD_COMPOSE(%rip), %rax
    pushq %rax
    leaq L_CG_TEMPLATE_BUF(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq pattern_template_set_hexad_kind
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movzbq L_RING_R0(%rip), %rax
    pushq %rax
    leaq L_CG_TEMPLATE_BUF(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq pattern_template_set_ring
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x389fd980, %rax
    pushq %rax
    leaq L_CG_TEMPLATE_BUF(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq pattern_template_set_k_value
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movq -16(%rbp), %rax
    pushq %rax
    leaq L_CG_TEMPLATE_BUF(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq pattern_template_set_specialisation_of
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    leaq cg_dispatch_default(%rip), %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movq -64(%rbp), %rax
    pushq %rax
    leaq L_CG_TEMPLATE_BUF(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq pattern_template_set_dispatch
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movzbq -24(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    leaq L_CG_TEMPLATE_BUF(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq pattern_template_set_binding_kind
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movzbq -24(%rbp), %rax
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
    leaq cg_unify_astkind(%rip), %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movq -72(%rbp), %rax
    pushq %rax
    leaq L_CG_TEMPLATE_BUF(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq pattern_template_set_unify
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_1:
    leaq L_CG_TEMPLATE_BUF(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq pattern_register
    addq $32, %rsp
    movzbq %al, %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movzbq -72(%rbp), %rax
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
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movb %al, L_CG_REG_FAIL(%rip)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_3:
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
    .asciz "codegen_register_all"
    .text
    .global codegen_register_all
    .seh_proc codegen_register_all
codegen_register_all:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movabsq $0x5, %rax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movb %al, L_CG_REG_FAIL(%rip)
    subq $8, %rsp
    movabsq $0x30, %rax
    pushq %rax
    movabsq $0x31, %rax
    pushq %rax
    movabsq $0x63, %rax
    pushq %rax
    movabsq $0x63, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x2a, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__cg_register
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x31, %rax
    pushq %rax
    movabsq $0x31, %rax
    pushq %rax
    movabsq $0x63, %rax
    pushq %rax
    movabsq $0x63, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x2b, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__cg_register
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x32, %rax
    pushq %rax
    movabsq $0x31, %rax
    pushq %rax
    movabsq $0x63, %rax
    pushq %rax
    movabsq $0x63, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x2c, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__cg_register
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x33, %rax
    pushq %rax
    movabsq $0x31, %rax
    pushq %rax
    movabsq $0x63, %rax
    pushq %rax
    movabsq $0x63, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x2d, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__cg_register
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x34, %rax
    pushq %rax
    movabsq $0x31, %rax
    pushq %rax
    movabsq $0x63, %rax
    pushq %rax
    movabsq $0x63, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x2e, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__cg_register
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x35, %rax
    pushq %rax
    movabsq $0x31, %rax
    pushq %rax
    movabsq $0x63, %rax
    pushq %rax
    movabsq $0x63, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x2f, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__cg_register
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x36, %rax
    pushq %rax
    movabsq $0x31, %rax
    pushq %rax
    movabsq $0x63, %rax
    pushq %rax
    movabsq $0x63, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x30, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__cg_register
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x31, %rax
    pushq %rax
    movabsq $0x30, %rax
    pushq %rax
    movabsq $0x61, %rax
    pushq %rax
    movabsq $0x63, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x31, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__cg_register
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x32, %rax
    pushq %rax
    movabsq $0x30, %rax
    pushq %rax
    movabsq $0x61, %rax
    pushq %rax
    movabsq $0x63, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x32, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__cg_register
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x33, %rax
    pushq %rax
    movabsq $0x30, %rax
    pushq %rax
    movabsq $0x61, %rax
    pushq %rax
    movabsq $0x63, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x33, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__cg_register
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x34, %rax
    pushq %rax
    movabsq $0x30, %rax
    pushq %rax
    movabsq $0x61, %rax
    pushq %rax
    movabsq $0x63, %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x34, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__cg_register
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x35, %rax
    pushq %rax
    movabsq $0x30, %rax
    pushq %rax
    movabsq $0x61, %rax
    pushq %rax
    movabsq $0x63, %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x35, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__cg_register
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x36, %rax
    pushq %rax
    movabsq $0x30, %rax
    pushq %rax
    movabsq $0x61, %rax
    pushq %rax
    movabsq $0x63, %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x36, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__cg_register
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x37, %rax
    pushq %rax
    movabsq $0x30, %rax
    pushq %rax
    movabsq $0x61, %rax
    pushq %rax
    movabsq $0x63, %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x37, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__cg_register
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x38, %rax
    pushq %rax
    movabsq $0x30, %rax
    pushq %rax
    movabsq $0x61, %rax
    pushq %rax
    movabsq $0x63, %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x38, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__cg_register
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x39, %rax
    pushq %rax
    movabsq $0x30, %rax
    pushq %rax
    movabsq $0x61, %rax
    pushq %rax
    movabsq $0x63, %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x39, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__cg_register
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x30, %rax
    pushq %rax
    movabsq $0x31, %rax
    pushq %rax
    movabsq $0x61, %rax
    pushq %rax
    movabsq $0x63, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x3a, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__cg_register
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x31, %rax
    pushq %rax
    movabsq $0x31, %rax
    pushq %rax
    movabsq $0x61, %rax
    pushq %rax
    movabsq $0x63, %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x3b, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__cg_register
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x32, %rax
    pushq %rax
    movabsq $0x31, %rax
    pushq %rax
    movabsq $0x61, %rax
    pushq %rax
    movabsq $0x63, %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x3c, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__cg_register
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x33, %rax
    pushq %rax
    movabsq $0x31, %rax
    pushq %rax
    movabsq $0x61, %rax
    pushq %rax
    movabsq $0x63, %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x3d, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__cg_register
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x34, %rax
    pushq %rax
    movabsq $0x31, %rax
    pushq %rax
    movabsq $0x61, %rax
    pushq %rax
    movabsq $0x63, %rax
    pushq %rax
    movabsq $0xe, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x3e, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__cg_register
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x35, %rax
    pushq %rax
    movabsq $0x31, %rax
    pushq %rax
    movabsq $0x61, %rax
    pushq %rax
    movabsq $0x63, %rax
    pushq %rax
    movabsq $0xf, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x3f, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__cg_register
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x36, %rax
    pushq %rax
    movabsq $0x31, %rax
    pushq %rax
    movabsq $0x61, %rax
    pushq %rax
    movabsq $0x63, %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x40, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__cg_register
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x37, %rax
    pushq %rax
    movabsq $0x31, %rax
    pushq %rax
    movabsq $0x61, %rax
    pushq %rax
    movabsq $0x63, %rax
    pushq %rax
    movabsq $0x11, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x41, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__cg_register
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x38, %rax
    pushq %rax
    movabsq $0x31, %rax
    pushq %rax
    movabsq $0x61, %rax
    pushq %rax
    movabsq $0x63, %rax
    pushq %rax
    movabsq $0x12, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x42, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__cg_register
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x39, %rax
    pushq %rax
    movabsq $0x31, %rax
    pushq %rax
    movabsq $0x61, %rax
    pushq %rax
    movabsq $0x63, %rax
    pushq %rax
    movabsq $0x13, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x43, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__cg_register
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x30, %rax
    pushq %rax
    movabsq $0x32, %rax
    pushq %rax
    movabsq $0x61, %rax
    pushq %rax
    movabsq $0x63, %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x44, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__cg_register
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movzbq L_CG_REG_FAIL(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_5
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    negq %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_5:
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
