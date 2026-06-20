# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
    .section .bss
    .global L_CPOS
L_CPOS:
    .zero 768
    .global L_CNEG
L_CNEG:
    .zero 768
    .global L_NC
L_NC:
    .zero 8
    .global L_NVAR
L_NVAR:
    .zero 8
    .global L_RNG
L_RNG:
    .zero 8
    .global L_HBODY
L_HBODY:
    .zero 768
    .global L_HHEAD
L_HHEAD:
    .zero 768
    .global L_HHAS
L_HHAS:
    .zero 768
    .section .iii.ring3,"n"
    .asciz "rnd"
    .text
    .seh_proc L_rnd
L_rnd:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    leaq L_RNG(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movl -8(%rbp), %eax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rax
    shlq $13, %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movl -8(%rbp), %eax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rax
    shrq $17, %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movl -8(%rbp), %eax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rax
    shlq $5, %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    leaq L_RNG(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movl -8(%rbp), %eax
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
    .asciz "varmask"
    .text
    .seh_proc L_varmask
L_varmask:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movabsq $0x1, %rax
    pushq %rax
    leaq L_NVAR(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rcx
    popq %rax
    shlq %cl, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
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
    .asciz "popc"
    .text
    .seh_proc L_popc
L_popc:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
L_loop_top_0:
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x10, %rax
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
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    shlq %cl, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
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
    jz L_if_end_3
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
L_if_end_3:
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
    jmp L_loop_top_0
L_loop_end_1:
    movl -16(%rbp), %eax
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
    .asciz "satisfies"
    .text
    .seh_proc L_satisfies
L_satisfies:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    leaq L_NC(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    subq $32, %rsp
    callq L_varmask
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
L_loop_top_4:
    movl -32(%rbp), %eax
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
    jz L_loop_end_5
    movl -8(%rbp), %eax
    pushq %rax
    leaq L_CPOS(%rip), %rax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
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
    jz L_if_end_7
    leaq L_CNEG(%rip), %rax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
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
    jz L_if_end_9
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_9:
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_7:
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
    jmp L_loop_top_4
L_loop_end_5:
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
    .asciz "brute_sat"
    .text
    .seh_proc L_brute_sat
L_brute_sat:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movabsq $0x1, %rax
    pushq %rax
    leaq L_NVAR(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rcx
    popq %rax
    shlq %cl, %rax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
L_loop_top_10:
    movl -16(%rbp), %eax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_11
    movl -16(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_satisfies
    addq $32, %rsp
    movzbq %al, %rax
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
    jz L_if_end_13
    movabsq $0x1, %rax
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
    jmp L_loop_top_10
L_loop_end_11:
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
    .asciz "is_0valid"
    .text
    .seh_proc L_is_0valid
L_is_0valid:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    leaq L_NC(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
L_loop_top_14:
    movl -16(%rbp), %eax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_15
    leaq L_CNEG(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
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
    jmp L_loop_top_14
L_loop_end_15:
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
    .asciz "is_1valid"
    .text
    .seh_proc L_is_1valid
L_is_1valid:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    leaq L_NC(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
L_loop_top_18:
    movl -16(%rbp), %eax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_19
    leaq L_CPOS(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
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
    jmp L_loop_top_18
L_loop_end_19:
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
    .asciz "is_horn"
    .text
    .seh_proc L_is_horn
L_is_horn:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    leaq L_NC(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
L_loop_top_22:
    movl -16(%rbp), %eax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_23
    leaq L_CPOS(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_popc
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    seta %al
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
    jmp L_loop_top_22
L_loop_end_23:
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
    .asciz "is_dualhorn"
    .text
    .seh_proc L_is_dualhorn
L_is_dualhorn:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    leaq L_NC(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
L_loop_top_26:
    movl -16(%rbp), %eax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_27
    leaq L_CNEG(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_popc
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    seta %al
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
    jmp L_loop_top_26
L_loop_end_27:
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
    .asciz "is_bijunctive"
    .text
    .seh_proc L_is_bijunctive
L_is_bijunctive:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    leaq L_NC(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
L_loop_top_30:
    movl -16(%rbp), %eax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_31
    leaq L_CPOS(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_popc
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    subq $8, %rsp
    leaq L_CNEG(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_popc
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    movabsq $0x2, %rax
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
    jmp L_loop_top_30
L_loop_end_31:
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
    .asciz "dualhorn_sat"
    .text
    .seh_proc L_dualhorn_sat
L_dualhorn_sat:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    leaq L_NC(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
L_loop_top_34:
    movl -16(%rbp), %eax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_35
    leaq L_CNEG(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    leaq L_CPOS(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    leaq L_HBODY(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movl -24(%rbp), %eax
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
    jz L_if_else_36
    leaq L_HHAS(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_HHEAD(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_if_end_37
L_if_else_36:
    leaq L_HHAS(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
L_loop_top_38:
    movl -48(%rbp), %eax
    pushq %rax
    leaq L_NVAR(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_39
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    shlq %cl, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
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
    jz L_if_else_40
    movl -48(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    leaq L_NVAR(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_if_end_41
L_if_else_40:
    movl -48(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_41:
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_38
L_loop_end_39:
    leaq L_HHEAD(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_37:
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
    jmp L_loop_top_34
L_loop_end_35:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
L_loop_top_42:
    movzbq -32(%rbp), %rax
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
    jz L_loop_end_43
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
L_loop_top_44:
    movl -48(%rbp), %eax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_45
    leaq L_HHAS(%rip), %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
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
    jz L_if_end_47
    movl -24(%rbp), %eax
    pushq %rax
    leaq L_HBODY(%rip), %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    leaq L_HBODY(%rip), %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_49
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    leaq L_HHEAD(%rip), %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rcx
    popq %rax
    shlq %cl, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
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
    jz L_if_end_51
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    leaq L_HHEAD(%rip), %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rcx
    popq %rax
    shlq %cl, %rax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_51:
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_49:
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_47:
    movl -48(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_44
L_loop_end_45:
    movzbq -40(%rbp), %rax
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
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_53:
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_42
L_loop_end_43:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
L_loop_top_54:
    movl -40(%rbp), %eax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_55
    leaq L_HHAS(%rip), %rax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
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
    jz L_if_end_57
    movl -24(%rbp), %eax
    pushq %rax
    leaq L_HBODY(%rip), %rax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    leaq L_HBODY(%rip), %rax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_59
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_59:
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_57:
    movl -40(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_54
L_loop_end_55:
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
    .asciz "gen_class"
    .text
    .seh_proc L_gen_class
L_gen_class:
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
    leaq L_NVAR(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NC(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
L_loop_top_60:
    movl -32(%rbp), %eax
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
    jz L_loop_end_61
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
L_loop_top_62:
    movl -56(%rbp), %eax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_63
    subq $32, %rsp
    callq L_rnd
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    xorl %edx, %edx
    divq %rcx
    movq %rdx, %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    subq $32, %rsp
    callq L_rnd
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
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
    jz L_if_else_64
    movl -40(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movl -64(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    shlq %cl, %rax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_if_end_65
L_if_else_64:
    movl -48(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movl -64(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    shlq %cl, %rax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_65:
    movl -56(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_62
L_loop_end_63:
    movl -24(%rbp), %eax
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
    jz L_if_end_67
    movl -48(%rbp), %eax
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
    jz L_if_end_69
    movabsq $0x1, %rax
    pushq %rax
    subq $8, %rsp
    subq $32, %rsp
    callq L_rnd
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    xorl %edx, %edx
    divq %rcx
    movq %rdx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    shlq %cl, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_69:
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_67:
    movl -24(%rbp), %eax
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
    jz L_if_end_71
    movl -40(%rbp), %eax
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
    jz L_if_end_73
    movabsq $0x1, %rax
    pushq %rax
    subq $8, %rsp
    subq $32, %rsp
    callq L_rnd
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    xorl %edx, %edx
    divq %rcx
    movq %rdx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    shlq %cl, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_73:
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_71:
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_75
L_loop_top_76:
    movl -48(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_popc
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    seta %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_77
    subq $32, %rsp
    callq L_rnd
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    xorl %edx, %edx
    divq %rcx
    movq %rdx, %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movl -48(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movl -64(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    shlq %cl, %rax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_76
L_loop_end_77:
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_75:
    leaq L_CPOS(%rip), %rax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_CNEG(%rip), %rax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
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
    jmp L_loop_top_60
L_loop_end_61:
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
    leaq L_RNG(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x5c4aef, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
L_loop_top_78:
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0x5dc, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_79
    movabsq $0x4, %rax
    pushq %rax
    subq $8, %rsp
    subq $32, %rsp
    callq L_rnd
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorl %edx, %edx
    divq %rcx
    movq %rdx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movabsq $0x2, %rax
    pushq %rax
    subq $8, %rsp
    subq $32, %rsp
    callq L_rnd
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorl %edx, %edx
    divq %rcx
    movq %rdx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L_gen_class
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq L_is_0valid
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
    jz L_if_end_81
    movabsq $0x14, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_81:
    subq $32, %rsp
    callq L_brute_sat
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
    jz L_if_end_83
    movabsq $0x15, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_83:
    movabsq $0x1, %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L_gen_class
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq L_is_1valid
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
    jz L_if_end_85
    movabsq $0x16, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_85:
    subq $32, %rsp
    callq L_brute_sat
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
    jz L_if_end_87
    movabsq $0x17, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_87:
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_78
L_loop_end_79:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
L_loop_top_88:
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x9c4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_89
    movabsq $0x4, %rax
    pushq %rax
    subq $8, %rsp
    subq $32, %rsp
    callq L_rnd
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorl %edx, %edx
    divq %rcx
    movq %rdx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movl -40(%rbp), %eax
    pushq %rax
    subq $8, %rsp
    subq $32, %rsp
    callq L_rnd
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorl %edx, %edx
    divq %rcx
    movq %rdx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movabsq $0x2, %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L_gen_class
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq L_is_dualhorn
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
    jz L_if_end_91
    movabsq $0x1e, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_91:
    subq $32, %rsp
    callq L_brute_sat
    addq $32, %rsp
    movzbq %al, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    subq $32, %rsp
    callq L_dualhorn_sat
    addq $32, %rsp
    movzbq %al, %rax
    pushq %rax
    movzbq -56(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_93
    movabsq $0x1f, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_93:
    movzbq -56(%rbp), %rax
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
    jz L_if_else_94
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
    jmp L_if_end_95
L_if_else_94:
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
L_if_end_95:
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
    jmp L_loop_top_88
L_loop_end_89:
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x64, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_97
    movabsq $0x20, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_97:
    movl -32(%rbp), %eax
    pushq %rax
    movabsq $0x64, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_99
    movabsq $0x21, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_99:
    leaq L_NVAR(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NC(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_CPOS(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    shlq %cl, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    shlq $1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    shlq $2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_CNEG(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_CPOS(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_CNEG(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    shlq %cl, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    shlq $1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    shlq $2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    subq $32, %rsp
    callq L_is_0valid
    addq $32, %rsp
    movzbq %al, %rax
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
    jz L_if_end_101
    movabsq $0x28, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_101:
    subq $32, %rsp
    callq L_is_1valid
    addq $32, %rsp
    movzbq %al, %rax
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
    jz L_if_end_103
    movabsq $0x29, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_103:
    subq $32, %rsp
    callq L_is_horn
    addq $32, %rsp
    movzbq %al, %rax
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
    jz L_if_end_105
    movabsq $0x2a, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_105:
    subq $32, %rsp
    callq L_is_dualhorn
    addq $32, %rsp
    movzbq %al, %rax
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
    jz L_if_end_107
    movabsq $0x2b, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_107:
    subq $32, %rsp
    callq L_is_bijunctive
    addq $32, %rsp
    movzbq %al, %rax
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
    jz L_if_end_109
    movabsq $0x2c, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_109:
    subq $32, %rsp
    callq L_brute_sat
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
    jz L_if_end_111
    movabsq $0x2d, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_111:
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
