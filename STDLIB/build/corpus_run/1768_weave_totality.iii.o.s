# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "bv_bits.iii\0"
L_str_1:
    .ascii "bv_bits.iii\0"
L_str_2:
    .ascii "bv_bits.iii\0"
L_str_3:
    .ascii "bv_bits.iii\0"
L_str_4:
    .ascii "bv_bits.iii\0"
L_str_5:
    .ascii "bv_bits.iii\0"
L_str_6:
    .ascii "bv_bits.iii\0"
L_str_7:
    .ascii "bv_bits.iii\0"
L_str_8:
    .ascii "bv_bits.iii\0"
L_str_9:
    .ascii "bv_bits.iii\0"
L_str_10:
    .ascii "bv_bits.iii\0"
L_str_11:
    .ascii "bv_bits.iii\0"
L_str_12:
    .ascii "bv_bits.iii\0"
L_str_13:
    .ascii "weave_blocks.iii\0"
L_str_14:
    .ascii "weave_blocks.iii\0"
L_str_15:
    .ascii "weave_blocks.iii\0"
L_str_16:
    .ascii "weave_blocks.iii\0"
L_str_17:
    .ascii "weave_blocks.iii\0"
L_str_18:
    .ascii "weave_blocks.iii\0"
    .section .iii.ring3,"n"
    .asciz "rotl_circ"
    .text
    .seh_proc L_rotl_circ
L_rotl_circ:
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
    movq -24(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_shr
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    subq $8, %rsp
    movq -16(%rbp), %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_shl
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_or
    addq $32, %rsp
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
    .asciz "gf8_circ"
    .text
    .seh_proc L_gf8_circ
L_gf8_circ:
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
    movl -24(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movl -48(%rbp), %eax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_and
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
L_loop_top_0:
    movq -72(%rbp), %rax
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
    jz L_loop_end_1
    movl -32(%rbp), %eax
    pushq %rax
    subq $8, %rsp
    movq -72(%rbp), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_shr
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_and
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -80(%rbp)
    movl -80(%rbp), %eax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_sub
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
    movl -88(%rbp), %eax
    pushq %rax
    movl -64(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_and
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movl -56(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_xor
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movabsq $0x1, %rax
    pushq %rax
    movl -64(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_shl
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -96(%rbp)
    movl -32(%rbp), %eax
    pushq %rax
    subq $8, %rsp
    movabsq $0x7, %rax
    pushq %rax
    movl -64(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_shr
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_and
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_sub
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -104(%rbp)
    movl -48(%rbp), %eax
    pushq %rax
    subq $8, %rsp
    movl -104(%rbp), %eax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_and
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movl -96(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_xor
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_and
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movq -72(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_0
L_loop_end_1:
    movl -56(%rbp), %eax
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
    movabsq $0x40, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq bb_reset
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq bb_var
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movabsq $0x40, %rax
    pushq %rax
    movabsq $0x28, %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L_rotl_circ
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movabsq $0x123456789abcdef, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_set_input
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq bb_eval
    addq $32, %rsp
    pushq %rax
    subq $8, %rsp
    movabsq $0x28, %rax
    pushq %rax
    movabsq $0x123456789abcdef, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq wvb_rotl64
    addq $32, %rsp
    addq $8, %rsp
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
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_3:
    movabsq $0x40, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq bb_reset
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq bb_var
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq bb_var
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq bb_var
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movl -40(%rbp), %eax
    pushq %rax
    subq $8, %rsp
    movl -24(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq bb_not
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_and
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    subq $8, %rsp
    movl -32(%rbp), %eax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_and
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_xor
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movabsq $0xf0f0f0f0f0f0f0f0, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_set_input
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x123456789abcdef, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_set_input
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xfedcba9876543210, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_set_input
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movl -48(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq bb_eval
    addq $32, %rsp
    pushq %rax
    subq $8, %rsp
    movabsq $0xfedcba9876543210, %rax
    pushq %rax
    movabsq $0x123456789abcdef, %rax
    pushq %rax
    movabsq $0xf0f0f0f0f0f0f0f0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq wvb_ch64
    addq $32, %rsp
    addq $8, %rsp
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
    movabsq $0x2, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_5:
    movabsq $0x40, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq bb_reset
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq bb_var
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq bb_var
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq bb_var
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movl -72(%rbp), %eax
    pushq %rax
    movl -64(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_and
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    subq $8, %rsp
    movl -72(%rbp), %eax
    pushq %rax
    movl -56(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_and
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    subq $8, %rsp
    movl -64(%rbp), %eax
    pushq %rax
    movl -56(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_and
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_xor
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_xor
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -80(%rbp)
    movabsq $0xcccccccccccccccc, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_set_input
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xaaaaaaaaaaaaaaaa, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_set_input
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xf0f0f0f0f0f0f0f0, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_set_input
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movl -80(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq bb_eval
    addq $32, %rsp
    pushq %rax
    subq $8, %rsp
    movabsq $0xf0f0f0f0f0f0f0f0, %rax
    pushq %rax
    movabsq $0xaaaaaaaaaaaaaaaa, %rax
    pushq %rax
    movabsq $0xcccccccccccccccc, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq wvb_maj64
    addq $32, %rsp
    addq $8, %rsp
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
    movabsq $0x3, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_7:
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq bb_reset
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq bb_var
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq bb_var
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -96(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq bb_const
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -104(%rbp)
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq bb_const
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -112(%rbp)
    movabsq $0x1b, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq bb_const
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -120(%rbp)
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq bb_const
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -128(%rbp)
    movl -128(%rbp), %eax
    pushq %rax
    movl -120(%rbp), %eax
    pushq %rax
    movl -112(%rbp), %eax
    pushq %rax
    movl -104(%rbp), %eax
    pushq %rax
    movl -96(%rbp), %eax
    pushq %rax
    movl -88(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_gf8_circ
    addq $32, %rsp
    addq $16, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -136(%rbp)
    movabsq $0x57, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_set_input
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x83, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_set_input
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movl -136(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq bb_eval
    addq $32, %rsp
    pushq %rax
    subq $8, %rsp
    movabsq $0x83, %rax
    pushq %rax
    movabsq $0x57, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq wvb_gf8_mul
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
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
    movabsq $0x4, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_9:
    movabsq $0xca, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_set_input
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x53, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_set_input
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movl -136(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq bb_eval
    addq $32, %rsp
    pushq %rax
    subq $8, %rsp
    movabsq $0x53, %rax
    pushq %rax
    movabsq $0xca, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq wvb_gf8_mul
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
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
    movabsq $0x5, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_11:
    movabsq $0x20, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq bb_reset
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq bb_var
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -144(%rbp)
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq bb_var
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -152(%rbp)
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq bb_var
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -160(%rbp)
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq bb_var
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -168(%rbp)
    movl -152(%rbp), %eax
    pushq %rax
    movl -144(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_add
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -176(%rbp)
    movabsq $0x20, %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    movl -176(%rbp), %eax
    pushq %rax
    movl -168(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_xor
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L_rotl_circ
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -184(%rbp)
    movl -184(%rbp), %eax
    pushq %rax
    movl -160(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_add
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -192(%rbp)
    movabsq $0x20, %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    movl -192(%rbp), %eax
    pushq %rax
    movl -152(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_xor
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L_rotl_circ
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -200(%rbp)
    movl -200(%rbp), %eax
    pushq %rax
    movl -176(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_add
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -208(%rbp)
    movabsq $0x20, %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    movl -208(%rbp), %eax
    pushq %rax
    movl -184(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_xor
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L_rotl_circ
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -216(%rbp)
    movl -216(%rbp), %eax
    pushq %rax
    movl -192(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_add
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -224(%rbp)
    movabsq $0x20, %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    movl -224(%rbp), %eax
    pushq %rax
    movl -200(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_xor
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L_rotl_circ
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -232(%rbp)
    movabsq $0x11111111, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_set_input
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1020304, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_set_input
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x9b8d6f2a, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_set_input
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x12345678, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bb_set_input
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x7, %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x12345678, %rax
    pushq %rax
    movabsq $0x9b8d6f2a, %rax
    pushq %rax
    movabsq $0x1020304, %rax
    pushq %rax
    movabsq $0x11111111, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq wvb_arx_mix
    addq $32, %rsp
    addq $48, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movl -208(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq bb_eval
    addq $32, %rsp
    pushq %rax
    subq $8, %rsp
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq wvb_a
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
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
    movabsq $0x6, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_13:
    movl -232(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq bb_eval
    addq $32, %rsp
    pushq %rax
    subq $8, %rsp
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq wvb_a
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
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
    movabsq $0x7, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_15:
    movl -224(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq bb_eval
    addq $32, %rsp
    pushq %rax
    subq $8, %rsp
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq wvb_a
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
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
    movabsq $0x8, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_17:
    movl -216(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq bb_eval
    addq $32, %rsp
    pushq %rax
    subq $8, %rsp
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq wvb_a
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
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
    movabsq $0x9, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_19:
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
