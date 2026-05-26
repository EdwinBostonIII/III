# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "mhash.iiimhash.iiimhash.iiimhash.iiiintent.iiiintent.iii\0"
L_str_1:
    .ascii "mhash.iiimhash.iiimhash.iiiintent.iiiintent.iii\0"
L_str_2:
    .ascii "mhash.iiimhash.iiiintent.iiiintent.iii\0"
L_str_3:
    .ascii "mhash.iiiintent.iiiintent.iii\0"
L_str_4:
    .ascii "intent.iiiintent.iii\0"
L_str_5:
    .ascii "intent.iii\0"
    .section .rodata
L_CALCULUS_VERSION_MAJOR:
    .quad 0x1
L_CALCULUS_VERSION_MINOR:
    .quad 0x0
L_CALCULUS_PRIMITIVE_COUNT:
    .quad 0x13
L_CALCULUS_OK:
    .quad 0x0
L_CALCULUS_E_BAD_PID:
    .quad 0xffffffffffffffff
L_CALCULUS_E_NOT_INITED:
    .quad 0xfffffffffffffffe
L_CALCULUS_E_BAD_INTENT:
    .quad 0xfffffffffffffffd
L_CALC_HEXAD_FORM:
    .quad 0x1
L_CALC_HEXAD_SUBSTANCE:
    .quad 0x2
L_CALC_HEXAD_PASSAGE:
    .quad 0x3
L_CALC_HEXAD_ESSENCE:
    .quad 0x4
L_CALC_HEXAD_MOTION:
    .quad 0x5
L_CALC_HEXAD_COMPOSE:
    .quad 0x6
L_CALC_HEXAD_ORIGIN:
    .quad 0x7
    .section .data
    .global L_CALC_DOM_ROOT
L_CALC_DOM_ROOT:
    .byte 0x49
    .byte 0x49
    .byte 0x49
    .byte 0x5f
    .byte 0x43
    .byte 0x41
    .byte 0x4c
    .byte 0x43
    .byte 0x5f
    .byte 0x56
    .byte 0x31
    .byte 0x5f
    .byte 0x52
    .byte 0x4f
    .byte 0x4f
    .byte 0x54
    .section .bss
    .global L_CALC_HEXAD
L_CALC_HEXAD:
    .zero 152
    .global L_CALC_K_COST
L_CALC_K_COST:
    .zero 152
    .global L_CALC_ARG_MASK
L_CALC_ARG_MASK:
    .zero 152
    .global L_CALC_RING_MIN
L_CALC_RING_MIN:
    .zero 152
    .section .data
    .global L_CALC_INIT
L_CALC_INIT:
    .quad 0x0
    .section .bss
    .global L_CALC_ROOT_MHASH
L_CALC_ROOT_MHASH:
    .zero 256
    .global L_CALC_ROOT_BUF4
L_CALC_ROOT_BUF4:
    .zero 32
    .global L_CALC_ROOT_BUF8
L_CALC_ROOT_BUF8:
    .zero 64
    .section .iii.ring3,"n"
    .asciz "_calc_set"
    .text
    .global L__calc_set
    .seh_proc L__calc_set
L__calc_set:
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
    movl -8(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movzbq -16(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movq -32(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movzbq -40(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -80(%rbp)
    leaq L_CALC_HEXAD(%rip), %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    movzbq -56(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_CALC_K_COST(%rip), %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    movq -64(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_CALC_ARG_MASK(%rip), %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_CALC_RING_MIN(%rip), %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    movzbq -80(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movslq L_CALCULUS_OK(%rip), %rax
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
    .asciz "_calc_compute_root"
    .text
    .global L__calc_compute_root
    .seh_proc L__calc_compute_root
L__calc_compute_root:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    subq $32, %rsp
    callq mhash_begin
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x10, %rax
    pushq %rax
    leaq L_CALC_DOM_ROOT(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq mhash_domain
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movl L_CALCULUS_PRIMITIVE_COUNT(%rip), %eax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    leaq L_CALC_ROOT_BUF4(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movl -8(%rbp), %eax
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
    leaq L_CALC_ROOT_BUF4(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0x8, %rax
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
    leaq L_CALC_ROOT_BUF4(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0x10, %rax
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
    leaq L_CALC_ROOT_BUF4(%rip), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0x18, %rax
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
    movabsq $0x4, %rax
    pushq %rax
    leaq L_CALC_ROOT_BUF4(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq mhash_payload
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x13, %rax
    pushq %rax
    leaq L_CALC_HEXAD(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq mhash_payload
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
L_loop_top_0:
    movl -16(%rbp), %eax
    pushq %rax
    movl L_CALCULUS_PRIMITIVE_COUNT(%rip), %eax
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
    leaq L_CALC_K_COST(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
L_loop_top_2:
    movl -32(%rbp), %eax
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
    jz L_loop_end_3
    leaq L_CALC_ROOT_BUF8(%rip), %rax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    movl %eax, %eax
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
    movl -32(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_2
L_loop_end_3:
    movabsq $0x8, %rax
    pushq %rax
    leaq L_CALC_ROOT_BUF8(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq mhash_payload
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_0
L_loop_end_1:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
L_loop_top_4:
    movl -16(%rbp), %eax
    pushq %rax
    movl L_CALCULUS_PRIMITIVE_COUNT(%rip), %eax
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
    leaq L_CALC_ARG_MASK(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
L_loop_top_6:
    movl -32(%rbp), %eax
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
    jz L_loop_end_7
    leaq L_CALC_ROOT_BUF8(%rip), %rax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    movl %eax, %eax
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
    movl -32(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_6
L_loop_end_7:
    movabsq $0x8, %rax
    pushq %rax
    leaq L_CALC_ROOT_BUF8(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq mhash_payload
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_4
L_loop_end_5:
    movabsq $0x13, %rax
    pushq %rax
    leaq L_CALC_RING_MIN(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq mhash_payload
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    leaq L_CALC_ROOT_MHASH(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq mhash_final
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movslq L_CALCULUS_OK(%rip), %rax
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
    .asciz "calculus_init"
    .text
    .global calculus_init
    .seh_proc calculus_init
calculus_init:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movzbq L_CALC_INIT(%rip), %rax
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
    jz L_if_end_9
    movslq L_CALCULUS_OK(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_9:
    subq $8, %rsp
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x3a699d00, %rax
    pushq %rax
    movzbq L_CALC_HEXAD_FORM(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__calc_set
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x389fd980, %rax
    pushq %rax
    movzbq L_CALC_HEXAD_SUBSTANCE(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__calc_set
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    movabsq $0x35a4e900, %rax
    pushq %rax
    movzbq L_CALC_HEXAD_PASSAGE(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__calc_set
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x3b9aca00, %rax
    pushq %rax
    movzbq L_CALC_HEXAD_ESSENCE(%rip), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__calc_set
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x35a4e900, %rax
    pushq %rax
    movzbq L_CALC_HEXAD_MOTION(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__calc_set
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x3a699d00, %rax
    pushq %rax
    movzbq L_CALC_HEXAD_COMPOSE(%rip), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__calc_set
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x3b9aca00, %rax
    pushq %rax
    movzbq L_CALC_HEXAD_ORIGIN(%rip), %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__calc_set
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x3b9aca00, %rax
    pushq %rax
    movzbq L_CALC_HEXAD_ESSENCE(%rip), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__calc_set
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x3b9aca00, %rax
    pushq %rax
    movzbq L_CALC_HEXAD_ESSENCE(%rip), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__calc_set
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x389fd980, %rax
    pushq %rax
    movzbq L_CALC_HEXAD_ORIGIN(%rip), %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__calc_set
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x389fd980, %rax
    pushq %rax
    movzbq L_CALC_HEXAD_ORIGIN(%rip), %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__calc_set
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x3b9aca00, %rax
    pushq %rax
    movzbq L_CALC_HEXAD_COMPOSE(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__calc_set
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x3b9aca00, %rax
    pushq %rax
    movzbq L_CALC_HEXAD_COMPOSE(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__calc_set
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x3b9aca00, %rax
    pushq %rax
    movzbq L_CALC_HEXAD_COMPOSE(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__calc_set
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x3b9aca00, %rax
    pushq %rax
    movzbq L_CALC_HEXAD_COMPOSE(%rip), %rax
    pushq %rax
    movabsq $0xe, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__calc_set
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    movabsq $0x389fd980, %rax
    pushq %rax
    movzbq L_CALC_HEXAD_COMPOSE(%rip), %rax
    pushq %rax
    movabsq $0xf, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__calc_set
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x35a4e900, %rax
    pushq %rax
    movzbq L_CALC_HEXAD_ORIGIN(%rip), %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__calc_set
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x3b9aca00, %rax
    pushq %rax
    movzbq L_CALC_HEXAD_ESSENCE(%rip), %rax
    pushq %rax
    movabsq $0x11, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__calc_set
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x3b9aca00, %rax
    pushq %rax
    movzbq L_CALC_HEXAD_COMPOSE(%rip), %rax
    pushq %rax
    movabsq $0x12, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__calc_set
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq L__calc_compute_root
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movb %al, L_CALC_INIT(%rip)
    movslq L_CALCULUS_OK(%rip), %rax
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
    .asciz "calculus_primitive_hexad"
    .text
    .global calculus_primitive_hexad
    .seh_proc calculus_primitive_hexad
calculus_primitive_hexad:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movl -8(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movzbq L_CALC_INIT(%rip), %rax
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
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_11:
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_13
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_13:
    movl -16(%rbp), %eax
    pushq %rax
    movl L_CALCULUS_PRIMITIVE_COUNT(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    seta %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_15
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_15:
    leaq L_CALC_HEXAD(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
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
    .asciz "calculus_primitive_k_cost"
    .text
    .global calculus_primitive_k_cost
    .seh_proc calculus_primitive_k_cost
calculus_primitive_k_cost:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movl -8(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movzbq L_CALC_INIT(%rip), %rax
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
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_17:
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_19
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_19:
    movl -16(%rbp), %eax
    pushq %rax
    movl L_CALCULUS_PRIMITIVE_COUNT(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    seta %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_21
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_21:
    leaq L_CALC_K_COST(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
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
    .asciz "calculus_primitive_param_schema"
    .text
    .global calculus_primitive_param_schema
    .seh_proc calculus_primitive_param_schema
calculus_primitive_param_schema:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movl -8(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movzbq L_CALC_INIT(%rip), %rax
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
    jz L_if_end_23
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_23:
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_25
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_25:
    movl -16(%rbp), %eax
    pushq %rax
    movl L_CALCULUS_PRIMITIVE_COUNT(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    seta %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_27
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_27:
    leaq L_CALC_ARG_MASK(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
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
    .asciz "calculus_primitive_ring_min"
    .text
    .global calculus_primitive_ring_min
    .seh_proc calculus_primitive_ring_min
calculus_primitive_ring_min:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movl -8(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movzbq L_CALC_INIT(%rip), %rax
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
    jz L_if_end_29
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_29:
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_31
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_31:
    movl -16(%rbp), %eax
    pushq %rax
    movl L_CALCULUS_PRIMITIVE_COUNT(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    seta %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_33
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_33:
    leaq L_CALC_RING_MIN(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
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
    .asciz "calculus_primitive_count"
    .text
    .global calculus_primitive_count
    .seh_proc calculus_primitive_count
calculus_primitive_count:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movl L_CALCULUS_PRIMITIVE_COUNT(%rip), %eax
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
    .asciz "calculus_version_major"
    .text
    .global calculus_version_major
    .seh_proc calculus_version_major
calculus_version_major:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movl L_CALCULUS_VERSION_MAJOR(%rip), %eax
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
    .asciz "calculus_version_minor"
    .text
    .global calculus_version_minor
    .seh_proc calculus_version_minor
calculus_version_minor:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movl L_CALCULUS_VERSION_MINOR(%rip), %eax
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
    .asciz "calculus_root_mhash"
    .text
    .global calculus_root_mhash
    .seh_proc calculus_root_mhash
calculus_root_mhash:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movzbq L_CALC_INIT(%rip), %rax
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
    jz L_if_end_35
    movslq L_CALCULUS_E_NOT_INITED(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_35:
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
L_loop_top_36:
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
    jz L_loop_end_37
    movq -16(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    leaq L_CALC_ROOT_MHASH(%rip), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
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
    jmp L_loop_top_36
L_loop_end_37:
    movslq L_CALCULUS_OK(%rip), %rax
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
    .asciz "calculus_root_mhash_byte"
    .text
    .global calculus_root_mhash_byte
    .seh_proc calculus_root_mhash_byte
calculus_root_mhash_byte:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movzbq L_CALC_INIT(%rip), %rax
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
    jz L_if_end_39
    movabsq $0x100, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_39:
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0x20, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_41
    movabsq $0x100, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_41:
    leaq L_CALC_ROOT_MHASH(%rip), %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
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
    .asciz "calculus_verify_completeness"
    .text
    .global calculus_verify_completeness
    .seh_proc calculus_verify_completeness
calculus_verify_completeness:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movzbq L_CALC_INIT(%rip), %rax
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
    jz L_if_end_43
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_43:
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_45
    movl -16(%rbp), %eax
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
    jz L_if_end_47
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_47:
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_45:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
L_loop_top_48:
    movl -24(%rbp), %eax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_49
    movl -24(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq intent_verify
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
    jz L_if_end_51
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_51:
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq intent_goal_kind
    addq $32, %rsp
    movzbq %al, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movzbq -56(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_53
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_53:
    movzbq -56(%rbp), %rax
    pushq %rax
    movabsq $0x13, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    seta %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_55
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_55:
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_48
L_loop_end_49:
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
    .section .iii.ring3,"n"
    .asciz "calculus_is_initialised"
    .text
    .global calculus_is_initialised
    .seh_proc calculus_is_initialised
calculus_is_initialised:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movzbq L_CALC_INIT(%rip), %rax
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
