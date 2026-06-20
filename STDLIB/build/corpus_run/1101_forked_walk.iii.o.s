# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "forked_walk.iii\0"
L_str_1:
    .ascii "forked_walk.iii\0"
L_str_2:
    .ascii "forked_walk.iii\0"
L_str_3:
    .ascii "forked_walk.iii\0"
L_str_4:
    .ascii "forked_walk.iii\0"
L_str_5:
    .ascii "commit_gate.iii\0"
L_str_6:
    .ascii "reversible.iii\0"
L_str_7:
    .ascii "reversible.iii\0"
    .section .rodata
L_CG_CERT:
    .quad 0x63
L_CG_CERT_UNSEARCHED:
    .quad 0xe
L_FW_CAP:
    .quad 0x1
L_REV_TAG_MEM_RESTORE_U64:
    .quad 0x2
L_REV_SLOT_NONE:
    .quad 0xffffffff
    .section .bss
    .global L_FW_DUMMY
L_FW_DUMMY:
    .zero 8
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
    movabsq $0x64, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq fw_init
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x96, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq fw_explore
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x96, %rax
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
    subq $32, %rsp
    callq fw_cell_value
    addq $32, %rsp
    pushq %rax
    movabsq $0x64, %rax
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
    movabsq $0x2, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_3:
    movabsq $0x12c, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq fw_explore
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0xc8, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq fw_explore
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq fw_best
    addq $32, %rsp
    pushq %rax
    movabsq $0x12c, %rax
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
    movabsq $0x3, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_5:
    subq $32, %rsp
    callq fw_cell_value
    addq $32, %rsp
    pushq %rax
    movabsq $0x64, %rax
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
    movabsq $0x4, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_7:
    subq $32, %rsp
    callq fw_commit
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movl L_CG_CERT(%rip), %eax
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
    movabsq $0x5, %rax
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
    callq fw_cell_value
    addq $32, %rsp
    pushq %rax
    movabsq $0x12c, %rax
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
    movabsq $0x6, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_11:
    movabsq $0x64, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq fw_init
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xc8, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq fw_explore
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x12c, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq fw_explore
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x96, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq fw_explore
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq fw_best
    addq $32, %rsp
    pushq %rax
    movabsq $0x12c, %rax
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
    movabsq $0x7, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_13:
    subq $32, %rsp
    callq fw_commit
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movl L_CG_CERT(%rip), %eax
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
    movabsq $0x8, %rax
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
    callq fw_cell_value
    addq $32, %rsp
    pushq %rax
    movabsq $0x12c, %rax
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
    movabsq $0x9, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_17:
    movabsq $0x1f4, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq fw_init
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x96, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq fw_explore
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x12c, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq fw_explore
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0xc8, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq fw_explore
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq fw_commit
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movl L_CG_CERT(%rip), %eax
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
    movabsq $0xa, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_19:
    subq $32, %rsp
    callq fw_cell_value
    addq $32, %rsp
    pushq %rax
    movabsq $0x1f4, %rax
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
    movabsq $0xb, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_21:
    movabsq $0x1f4, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq cg_cert_abstain
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movl L_CG_CERT_UNSEARCHED(%rip), %eax
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
    movabsq $0xc, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_23:
    movabsq $0xdeadbeef, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq fw_init
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x11111111, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq fw_explore
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq fw_cell_value
    addq $32, %rsp
    pushq %rax
    movabsq $0xdeadbeef, %rax
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
    movabsq $0xd, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_25:
    movabsq $0x64, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq fw_init
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movq L_FW_CAP(%rip), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq rev_begin
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movl -16(%rbp), %eax
    pushq %rax
    movl L_REV_SLOT_NONE(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_27
    movabsq $0xe, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_27:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
L_loop_top_28:
    movzbq -24(%rbp), %rax
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
    jz L_loop_end_29
    movabsq $0x0, %rax
    pushq %rax
    leaq L_FW_DUMMY(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movl L_REV_TAG_MEM_RESTORE_U64(%rip), %eax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq rev_record
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movslq -40(%rbp), %rax
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
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_31:
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
    movl -32(%rbp), %eax
    pushq %rax
    movabsq $0x4e20, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_33
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_33:
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_28
L_loop_end_29:
    movl -32(%rbp), %eax
    pushq %rax
    movabsq $0x3e8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_35
    movabsq $0xf, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_35:
    movabsq $0x309, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq fw_explore
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x64, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_37
    movabsq $0x10, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_37:
    subq $32, %rsp
    callq fw_cell_value
    addq $32, %rsp
    pushq %rax
    movabsq $0x64, %rax
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
    movabsq $0x11, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_39:
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
