# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "refactor_propose.iii\0"
L_str_1:
    .ascii "refactor_propose.iii\0"
L_str_2:
    .ascii "refactor_propose.iii\0"
L_str_3:
    .ascii "refactor_propose.iii\0"
L_str_4:
    .ascii "refactor_propose.iii\0"
L_str_5:
    .ascii "refactor_propose.iii\0"
L_str_6:
    .ascii "refactor_propose.iii\0"
L_str_7:
    .ascii "refactor_propose.iii\0"
L_str_8:
    .ascii "refactor_propose.iii\0"
L_str_9:
    .ascii "refactor_propose.iii\0"
L_str_10:
    .ascii "refactor_propose.iii\0"
L_str_11:
    .ascii "refactor_propose.iii\0"
L_str_12:
    .ascii "refactor_propose.iii\0"
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
    callq rp_scan
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
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
    callq rp_ncand
    addq $32, %rsp
    pushq %rax
    movq -8(%rbp), %rax
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
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq rp_kind
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
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq rp_kind
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0x2, %rax
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
    movabsq $0x3e7, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq rp_kind
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
    callq rp_tg
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    subq $8, %rsp
    subq $32, %rsp
    callq rp_tf
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq rp_equiv
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
    subq $32, %rsp
    callq rp_th
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    subq $8, %rsp
    subq $32, %rsp
    callq rp_tf
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq rp_equiv
    addq $32, %rsp
    movzbq %al, %rax
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
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq rp_rule_sound
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
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq rp_rule_sound
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
    subq $32, %rsp
    callq rp_goal
    addq $32, %rsp
    movl %eax, %eax
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
    callq rp_classes
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    subq $32, %rsp
    callq rp_proof_bad
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq rp_certify
    addq $32, %rsp
    movslq %eax, %rax
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
    subq $32, %rsp
    callq rp_classes
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movl -16(%rbp), %eax
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
    subq $32, %rsp
    callq rp_proof_ok
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movl -32(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq rp_certify
    addq $32, %rsp
    movslq %eax, %rax
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
    subq $32, %rsp
    callq rp_classes
    addq $32, %rsp
    movl %eax, %eax
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
    cmpq %rcx, %rax
    setne %al
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
