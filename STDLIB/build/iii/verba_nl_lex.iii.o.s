# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
    .section .rodata
L_NL_TOK_VOID:
    .quad 0x0
L_NL_TOK_VERB:
    .quad 0x1
L_NL_TOK_NOUN:
    .quad 0x2
L_NL_TOK_ADJ:
    .quad 0x3
L_NL_TOK_ADV:
    .quad 0x4
L_NL_TOK_PREP:
    .quad 0x5
L_NL_TOK_DET:
    .quad 0x6
L_NL_TOK_NUMBER:
    .quad 0x7
L_NL_TOK_STRING_LIT:
    .quad 0x8
L_NL_TOK_IDENT:
    .quad 0x9
L_NL_TOK_ROLE:
    .quad 0xa
L_NL_TOK_PUNCT:
    .quad 0xb
L_NL_TOK_EOL:
    .quad 0xc
L_NL_LEXICON_CAP:
    .quad 0x1000
L_NL_LEXICON_MASK:
    .quad 0xfff
L_NL_FNV_OFFSET:
    .quad 0xcbf29ce484222325
L_NL_FNV_PRIME:
    .quad 0x100000001b3
L_NL_LEX_OK:
    .quad 0x0
L_NL_LEX_E_NULL:
    .quad 0xffffffffffffffff
L_NL_LEX_E_FULL:
    .quad 0xfffffffffffffffe
L_NL_LEX_E_OVERFLOW:
    .quad 0xfffffffffffffffd
    .section .bss
    .global L_NL_LEX_HASH
L_NL_LEX_HASH:
    .zero 32768
    .global L_NL_LEX_TYPE
L_NL_LEX_TYPE:
    .zero 32768
    .global L_NL_LEX_WORD_ID
L_NL_LEX_WORD_ID:
    .zero 32768
    .section .data
    .global L_NL_LEX_USED
L_NL_LEX_USED:
    .quad 0x0
    .global L_NL_LEX_INITED
L_NL_LEX_INITED:
    .quad 0x0
    .section .iii.ring3,"n"
    .asciz "_nl_to_lower"
    .text
    .seh_proc L__nl_to_lower
L__nl_to_lower:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movzbq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movzbq -16(%rbp), %rax
    pushq %rax
    movabsq $0x41, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_1
    movzbq -16(%rbp), %rax
    pushq %rax
    movabsq $0x5a, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setbe %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_3
    movzbq -16(%rbp), %rax
    pushq %rax
    movabsq $0x20, %rax
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
    popq %rax
L_if_end_3:
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_1:
    movzbq -16(%rbp), %rax
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
    .asciz "_nl_is_digit"
    .text
    .seh_proc L__nl_is_digit
L__nl_is_digit:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movzbq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movzbq -16(%rbp), %rax
    pushq %rax
    movabsq $0x30, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_5
    movzbq -16(%rbp), %rax
    pushq %rax
    movabsq $0x39, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setbe %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_7
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_7:
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
    .section .iii.ring3,"n"
    .asciz "_nl_is_alpha"
    .text
    .seh_proc L__nl_is_alpha
L__nl_is_alpha:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movzbq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movzbq -16(%rbp), %rax
    pushq %rax
    movabsq $0x41, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_9
    movzbq -16(%rbp), %rax
    pushq %rax
    movabsq $0x5a, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setbe %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_11
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_11:
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_9:
    movzbq -16(%rbp), %rax
    pushq %rax
    movabsq $0x61, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_13
    movzbq -16(%rbp), %rax
    pushq %rax
    movabsq $0x7a, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setbe %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_15
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_15:
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_13:
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
    .asciz "_nl_is_word_char"
    .text
    .seh_proc L__nl_is_word_char
L__nl_is_word_char:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movzbq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movzbq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L__nl_is_alpha
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
    jz L_if_end_17
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_17:
    movzbq -16(%rbp), %rax
    pushq %rax
    movabsq $0x5f, %rax
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
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_19:
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
    .asciz "_nl_is_space"
    .text
    .seh_proc L__nl_is_space
L__nl_is_space:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movzbq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movzbq -16(%rbp), %rax
    pushq %rax
    movabsq $0x20, %rax
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
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_21:
    movzbq -16(%rbp), %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_23
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_23:
    movzbq -16(%rbp), %rax
    pushq %rax
    movabsq $0xd, %rax
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
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_25:
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
    .asciz "_nl_is_punct"
    .text
    .seh_proc L__nl_is_punct
L__nl_is_punct:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movzbq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movzbq -16(%rbp), %rax
    pushq %rax
    movabsq $0x2e, %rax
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
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_27:
    movzbq -16(%rbp), %rax
    pushq %rax
    movabsq $0x2c, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_29
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_29:
    movzbq -16(%rbp), %rax
    pushq %rax
    movabsq $0x3b, %rax
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
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_31:
    movzbq -16(%rbp), %rax
    pushq %rax
    movabsq $0x3a, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_33
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_33:
    movzbq -16(%rbp), %rax
    pushq %rax
    movabsq $0x21, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_35
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_35:
    movzbq -16(%rbp), %rax
    pushq %rax
    movabsq $0x3f, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_37
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_37:
    movzbq -16(%rbp), %rax
    pushq %rax
    movabsq $0x28, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_39
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_39:
    movzbq -16(%rbp), %rax
    pushq %rax
    movabsq $0x29, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_41
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_41:
    movzbq -16(%rbp), %rax
    pushq %rax
    movabsq $0x5b, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_43
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_43:
    movzbq -16(%rbp), %rax
    pushq %rax
    movabsq $0x5d, %rax
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
    movzbq -16(%rbp), %rax
    pushq %rax
    movabsq $0x7b, %rax
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
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_47:
    movzbq -16(%rbp), %rax
    pushq %rax
    movabsq $0x7d, %rax
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
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_49:
    movzbq -16(%rbp), %rax
    pushq %rax
    movabsq $0x2d, %rax
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
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_51:
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
    .asciz "_nl_fnv_lower"
    .text
    .seh_proc L__nl_fnv_lower
L__nl_fnv_lower:
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
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq L_NL_FNV_OFFSET(%rip), %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
L_loop_top_52:
    movl -48(%rbp), %eax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_53
    movq -32(%rbp), %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq -56(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L__nl_to_lower
    addq $32, %rsp
    movzbq %al, %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movq -40(%rbp), %rax
    pushq %rax
    movzbq -64(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq -40(%rbp), %rax
    pushq %rax
    movq L_NL_FNV_PRIME(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
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
    jmp L_loop_top_52
L_loop_end_53:
    movq -40(%rbp), %rax
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
    .asciz "nl_lex_register_hash"
    .text
    .global nl_lex_register_hash
    .seh_proc nl_lex_register_hash
nl_lex_register_hash:
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
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movzbq -16(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movl -24(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq -32(%rbp), %rax
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
    jz L_if_end_55
    movslq L_NL_LEX_E_NULL(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_55:
    movl L_NL_LEX_USED(%rip), %eax
    pushq %rax
    movl L_NL_LEXICON_CAP(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_57
    movslq L_NL_LEX_E_FULL(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_57:
    movq -32(%rbp), %rax
    pushq %rax
    movq L_NL_LEXICON_MASK(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
L_loop_top_58:
    movl -64(%rbp), %eax
    pushq %rax
    movl L_NL_LEXICON_CAP(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_59
    leaq L_NL_LEX_HASH(%rip), %rax
    pushq %rax
    movl -56(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
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
    jz L_if_end_61
    leaq L_NL_LEX_HASH(%rip), %rax
    pushq %rax
    movl -56(%rbp), %eax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NL_LEX_TYPE(%rip), %rax
    pushq %rax
    movl -56(%rbp), %eax
    pushq %rax
    movzbq -40(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_NL_LEX_WORD_ID(%rip), %rax
    pushq %rax
    movl -56(%rbp), %eax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movl L_NL_LEX_USED(%rip), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movl %eax, L_NL_LEX_USED(%rip)
    movslq L_NL_LEX_OK(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_61:
    leaq L_NL_LEX_HASH(%rip), %rax
    pushq %rax
    movl -56(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_63
    leaq L_NL_LEX_TYPE(%rip), %rax
    pushq %rax
    movl -56(%rbp), %eax
    pushq %rax
    movzbq -40(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_NL_LEX_WORD_ID(%rip), %rax
    pushq %rax
    movl -56(%rbp), %eax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movslq L_NL_LEX_OK(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_63:
    movl -56(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    movabsq $0xfff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movl -64(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_58
L_loop_end_59:
    movslq L_NL_LEX_E_FULL(%rip), %rax
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
    .asciz "nl_lex_lookup_hash"
    .text
    .global nl_lex_lookup_hash
    .seh_proc nl_lex_lookup_hash
nl_lex_lookup_hash:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movq -16(%rbp), %rax
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
    jz L_if_end_65
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_65:
    movq -16(%rbp), %rax
    pushq %rax
    movq L_NL_LEXICON_MASK(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
L_loop_top_66:
    movl -32(%rbp), %eax
    pushq %rax
    movl L_NL_LEXICON_CAP(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_67
    leaq L_NL_LEX_HASH(%rip), %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq -40(%rbp), %rax
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
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_69:
    movq -40(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
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
    leaq L_NL_LEX_TYPE(%rip), %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    leaq L_NL_LEX_WORD_ID(%rip), %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq -48(%rbp), %rax
    pushq %rax
    popq %rax
    shlq $24, %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_71:
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    movabsq $0xfff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
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
    jmp L_loop_top_66
L_loop_end_67:
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
    .asciz "nl_lex_used"
    .text
    .global nl_lex_used
    .seh_proc nl_lex_used
nl_lex_used:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movl L_NL_LEX_USED(%rip), %eax
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
    .asciz "nl_lex_capacity"
    .text
    .global nl_lex_capacity
    .seh_proc nl_lex_capacity
nl_lex_capacity:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movl L_NL_LEXICON_CAP(%rip), %eax
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
    .asciz "nl_lex_reset"
    .text
    .global nl_lex_reset
    .seh_proc nl_lex_reset
nl_lex_reset:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
L_loop_top_72:
    movl -8(%rbp), %eax
    pushq %rax
    movl L_NL_LEXICON_CAP(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_73
    leaq L_NL_LEX_HASH(%rip), %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_NL_LEX_TYPE(%rip), %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_NL_LEX_WORD_ID(%rip), %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
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
    jmp L_loop_top_72
L_loop_end_73:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movl %eax, L_NL_LEX_USED(%rip)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movb %al, L_NL_LEX_INITED(%rip)
    movslq L_NL_LEX_OK(%rip), %rax
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
    .asciz "nl_token_pack"
    .text
    .global nl_token_pack
    .seh_proc nl_token_pack
nl_token_pack:
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
    movzbq -8(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    shlq $8, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movl -24(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    shlq $32, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movl -32(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    shlq $48, %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movq -40(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    movq -64(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
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
    .asciz "nl_token_type"
    .text
    .global nl_token_type
    .seh_proc nl_token_type
nl_token_type:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq -8(%rbp), %rax
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
    .asciz "nl_token_word_id"
    .text
    .global nl_token_word_id
    .seh_proc nl_token_word_id
nl_token_word_id:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    shrq $8, %rax
    pushq %rax
    movabsq $0xffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
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
    .asciz "nl_token_span_start"
    .text
    .global nl_token_span_start
    .seh_proc nl_token_span_start
nl_token_span_start:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    shrq $32, %rax
    pushq %rax
    movabsq $0xffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
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
    .asciz "nl_token_span_end"
    .text
    .global nl_token_span_end
    .seh_proc nl_token_span_end
nl_token_span_end:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    shrq $48, %rax
    pushq %rax
    movabsq $0xffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
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
    .asciz "_nl_emit"
    .text
    .seh_proc L__nl_emit
L__nl_emit:
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
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movl -24(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movl -48(%rbp), %eax
    pushq %rax
    movl -56(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_75
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_75:
    movq -40(%rbp), %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    shlq $3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movq -64(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
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
    .asciz "_nl_scan_string"
    .text
    .seh_proc L__nl_scan_string
L__nl_scan_string:
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
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movl -24(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
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
    movq %rax, -48(%rbp)
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
L_loop_top_76:
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
    jz L_loop_end_77
    movl -48(%rbp), %eax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_else_78
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_if_end_79
L_if_else_78:
    movq -32(%rbp), %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movq -64(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    movabsq $0x22, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_else_80
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_if_end_81
L_if_else_80:
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
L_if_end_81:
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_79:
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_76
L_loop_end_77:
    movl -48(%rbp), %eax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_83
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
L_if_end_83:
    movl -48(%rbp), %eax
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
    .asciz "_nl_scan_number"
    .text
    .seh_proc L__nl_scan_number
L__nl_scan_number:
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
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movl -24(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
L_loop_top_84:
    movzbq -64(%rbp), %rax
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
    jz L_loop_end_85
    movl -48(%rbp), %eax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_else_86
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_if_end_87
L_if_else_86:
    movq -32(%rbp), %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movq -72(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    movq %rax, -80(%rbp)
    movzbq -80(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L__nl_is_digit
    addq $32, %rsp
    movzbq %al, %rax
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
    jz L_if_else_88
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_if_end_89
L_if_else_88:
    movl -56(%rbp), %eax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    movzbq -80(%rbp), %rax
    pushq %rax
    movabsq $0x30, %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
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
L_if_end_89:
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_87:
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_84
L_loop_end_85:
    movl -48(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movl -56(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    shlq $32, %rax
    pushq %rax
    popq %rax
    movq %rax, -80(%rbp)
    movq -72(%rbp), %rax
    pushq %rax
    movq -80(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
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
    .asciz "_nl_scan_word"
    .text
    .seh_proc L__nl_scan_word
L__nl_scan_word:
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
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movl -24(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
L_loop_top_90:
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
    jz L_loop_end_91
    movl -48(%rbp), %eax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_else_92
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_if_end_93
L_if_else_92:
    movq -32(%rbp), %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movq -64(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L__nl_is_word_char
    addq $32, %rsp
    movzbq %al, %rax
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
    jz L_if_else_94
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_if_end_95
L_if_else_94:
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
L_if_end_95:
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_93:
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_90
L_loop_end_91:
    movl -48(%rbp), %eax
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
    .asciz "nl_lex_tokenize"
    .text
    .global nl_lex_tokenize
    .seh_proc nl_lex_tokenize
nl_lex_tokenize:
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
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq -48(%rbp), %rax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq -48(%rbp), %rax
    pushq %rax
    popq %rax
    shrq $32, %rax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movq -32(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -80(%rbp)
    movq -40(%rbp), %rax
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
    jz L_if_end_97
    movslq L_NL_LEX_E_NULL(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_97:
    movq -72(%rbp), %rax
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
    jz L_if_end_99
    movslq L_NL_LEX_E_NULL(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_99:
    movq -80(%rbp), %rax
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
    jz L_if_end_101
    movslq L_NL_LEX_E_NULL(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_101:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -96(%rbp)
L_loop_top_102:
    movl -88(%rbp), %eax
    pushq %rax
    movl -56(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_103
    movq -40(%rbp), %rax
    pushq %rax
    movl -88(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -104(%rbp)
    movq -104(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    movq %rax, -112(%rbp)
    movzbq -112(%rbp), %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_else_104
    movl -88(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    movl -88(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movzbq L_NL_TOK_EOL(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq nl_token_pack
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -120(%rbp)
    movq -120(%rbp), %rax
    pushq %rax
    movl -64(%rbp), %eax
    pushq %rax
    movl -96(%rbp), %eax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__nl_emit
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -96(%rbp)
    movl -96(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
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
    movslq L_NL_LEX_E_OVERFLOW(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_107:
    movl -88(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_if_end_105
L_if_else_104:
    movzbq -112(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L__nl_is_space
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
    jz L_if_else_108
    movl -88(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_if_end_109
L_if_else_108:
    movzbq -112(%rbp), %rax
    pushq %rax
    movabsq $0x22, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_else_110
    movl -88(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -120(%rbp)
    movl -56(%rbp), %eax
    pushq %rax
    movl -88(%rbp), %eax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L__nl_scan_string
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -128(%rbp)
    movl -128(%rbp), %eax
    pushq %rax
    movl -120(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movzbq L_NL_TOK_STRING_LIT(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq nl_token_pack
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -136(%rbp)
    movq -136(%rbp), %rax
    pushq %rax
    movl -64(%rbp), %eax
    pushq %rax
    movl -96(%rbp), %eax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__nl_emit
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -96(%rbp)
    movl -96(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_113
    movslq L_NL_LEX_E_OVERFLOW(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_113:
    movl -128(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_if_end_111
L_if_else_110:
    movzbq -112(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L__nl_is_punct
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
    jz L_if_else_114
    movl -88(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    movl -88(%rbp), %eax
    pushq %rax
    movzbq -112(%rbp), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    movzbq L_NL_TOK_PUNCT(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq nl_token_pack
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -120(%rbp)
    movq -120(%rbp), %rax
    pushq %rax
    movl -64(%rbp), %eax
    pushq %rax
    movl -96(%rbp), %eax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__nl_emit
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -96(%rbp)
    movl -96(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_117
    movslq L_NL_LEX_E_OVERFLOW(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_117:
    movl -88(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_if_end_115
L_if_else_114:
    movzbq -112(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L__nl_is_digit
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
    jz L_if_else_118
    movl -88(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -120(%rbp)
    movl -56(%rbp), %eax
    pushq %rax
    movl -88(%rbp), %eax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L__nl_scan_number
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -128(%rbp)
    movq -128(%rbp), %rax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -136(%rbp)
    movq -128(%rbp), %rax
    pushq %rax
    popq %rax
    shrq $32, %rax
    pushq %rax
    movabsq $0xffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -144(%rbp)
    movl -136(%rbp), %eax
    pushq %rax
    movl -120(%rbp), %eax
    pushq %rax
    movl -144(%rbp), %eax
    pushq %rax
    movzbq L_NL_TOK_NUMBER(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq nl_token_pack
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -152(%rbp)
    movq -152(%rbp), %rax
    pushq %rax
    movl -64(%rbp), %eax
    pushq %rax
    movl -96(%rbp), %eax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__nl_emit
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -96(%rbp)
    movl -96(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_121
    movslq L_NL_LEX_E_OVERFLOW(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_121:
    movl -136(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_if_end_119
L_if_else_118:
    movzbq -112(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L__nl_is_word_char
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
    jz L_if_else_122
    movl -88(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -120(%rbp)
    movl -56(%rbp), %eax
    pushq %rax
    movl -88(%rbp), %eax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L__nl_scan_word
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -128(%rbp)
    movl -128(%rbp), %eax
    pushq %rax
    movl -120(%rbp), %eax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L__nl_fnv_lower
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -136(%rbp)
    movq -136(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq nl_lex_lookup_hash
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -144(%rbp)
    movzbq L_NL_TOK_IDENT(%rip), %rax
    pushq %rax
    popq %rax
    movq %rax, -152(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -160(%rbp)
    movq -144(%rbp), %rax
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
    jz L_if_end_125
    movq -144(%rbp), %rax
    pushq %rax
    popq %rax
    shrq $24, %rax
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
    popq %rax
    movq %rax, -152(%rbp)
    movq -144(%rbp), %rax
    pushq %rax
    movabsq $0xffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -160(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_125:
    movl -128(%rbp), %eax
    pushq %rax
    movl -120(%rbp), %eax
    pushq %rax
    movl -160(%rbp), %eax
    pushq %rax
    movzbq -152(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq nl_token_pack
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -168(%rbp)
    movq -168(%rbp), %rax
    pushq %rax
    movl -64(%rbp), %eax
    pushq %rax
    movl -96(%rbp), %eax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__nl_emit
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -96(%rbp)
    movl -96(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_127
    movslq L_NL_LEX_E_OVERFLOW(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_127:
    movl -128(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_if_end_123
L_if_else_122:
    movl -88(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_123:
L_if_end_119:
L_if_end_115:
L_if_end_111:
L_if_end_109:
L_if_end_105:
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_102
L_loop_end_103:
    movl -56(%rbp), %eax
    pushq %rax
    movl -56(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movzbq L_NL_TOK_EOL(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq nl_token_pack
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -104(%rbp)
    movq -104(%rbp), %rax
    pushq %rax
    movl -64(%rbp), %eax
    pushq %rax
    movl -96(%rbp), %eax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__nl_emit
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -112(%rbp)
    movl -112(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_129
    movl -112(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -96(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_129:
    movq -80(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -120(%rbp)
    movq -120(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movl -96(%rbp), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movslq L_NL_LEX_OK(%rip), %rax
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
    .asciz "nl_lex_pack_lens"
    .text
    .global nl_lex_pack_lens
    .seh_proc nl_lex_pack_lens
nl_lex_pack_lens:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movl -8(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    shlq $32, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
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
    .asciz "nl_lex_init_all"
    .text
    .global nl_lex_init_all
    .seh_proc nl_lex_init_all
nl_lex_init_all:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movzbq L_NL_LEX_INITED(%rip), %rax
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
    jz L_if_end_131
    movslq L_NL_LEX_OK(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_131:
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x2d1ff318d40c162f, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xd4e26318faaa79f7, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x77f370195699cdee, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x4ce6531fbfddd605, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xb93a12b0d06caefc, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x44ee54ad76b0bd8e, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x7, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xce0eecad70f271e9, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x8, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x740cb4d2322f6882, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x9, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x4c5f6d0e704b8dda, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x2e3d9ecc741a7811, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xb, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x4e0f7f18e637a364, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xc, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x2d582147c78edbe4, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xd, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xeb0e9ed12f553762, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xe, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xf84f97b4633670e9, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xf, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x9ec2699513c0f9c3, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x10, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x54cb3aded715c1b9, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x11, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x5926cb82738c446b, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x12, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xdc8acb313473c026, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x13, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x7e5f7abe09509b09, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x14, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xc4e87a7a1f6fd8c, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x15, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x64db608eefff5c72, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x16, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x56d12ea086274034, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x17, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xbf903911984eee4, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x18, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xd0f17a2c3f687b4, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x19, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xf3fe6b5fdb85d50a, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1a, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xf74e5feadea773fd, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1b, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x2fce30cb8e3c8185, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1c, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x2d08d918d3f90b20, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1d, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x3cba013d62284d47, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1e, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x32bc902977d5212d, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1f, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x20ca489515cc42f3, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x20, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xf94d91246d8f61dd, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x21, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xb1068f146c4596c3, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x22, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x62836442b3557916, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x23, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x247a08a06a19f5f3, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x24, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x95d7d72cdaba594a, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x25, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xdec34c9bd0b6d2ee, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x26, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x42612761674dd4d, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x27, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x42f406a2e307ef94, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x28, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xe723b5190545606b, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x29, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x7f625478d788e11b, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x2a, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x6828a99c1e3216ff, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x2b, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x2f2ec0474f1c4fe4, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x2c, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xd86c0af0b398153b, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x2d, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xb45b6cbd15f67d33, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x2e, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xaad01178f02a6a23, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x2f, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x546401b5d2a8d2a4, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x30, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x3dc94a19365b10ec, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x31, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x484cd7c41eb765cd, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x32, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x7c0ea75a95a79411, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x33, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x4f6a36d8e8907985, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x34, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xa5013e9ad5caeda4, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x35, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x10f2dcb841372d0c, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x36, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xc7f597ea639b1b59, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x38, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xd053586f9c8e048b, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x39, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xb7a1e4bea695f89, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x3a, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x226447d5a36b55e5, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x3b, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x76f15bd2d85da389, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x3c, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xac4a61ac2e59cbcc, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x3d, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x15d8d7b6a4c553c8, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x3e, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x8b7dc019093cd0e1, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x3f, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xc755a623f50a24dd, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x40, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x1dabe85903dc59a, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x41, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x59561bcb7e9336b1, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x42, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x62852288e56b3e53, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x43, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x5055c58f7a753b55, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x44, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x1d6a0ae1de6b2ca1, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x45, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x89f6c11960ff5191, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x46, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0xca52bf90e851d814, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x47, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x541119134fd259, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x48, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x7d6ce172e098998c, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x49, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0xef5a4a7916c5f26f, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x4a, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x6a771318f6fe2cb8, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x4b, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0xe5660aeee07403d0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x4c, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x9829d5caf45f3d03, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x4d, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x7d0cfe94310960b1, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x4e, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x2be5705c42a81bd0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x4f, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x852d008f993513d3, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x50, %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x742b119a079a292b, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x51, %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x958ba0ff4a1d393f, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x52, %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x9397d330d95b9e17, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x53, %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x1c343869047769a1, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x54, %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x2d210bd352ea42dc, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x55, %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0xf7c4a6dffaf7e544, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x56, %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0xcbd8031e3d026dc9, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x57, %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0xa7826ad9e25cf5a1, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x58, %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x7f845078d7a5c0b5, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x59, %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x8c83907b56ac0a4, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x5a, %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0xa66b06f655a0c2e9, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x5b, %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x8b06007b5567108, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x5c, %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x8b73807b55c4bbe, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x5d, %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0xf5a6c8c57a9061a3, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x5e, %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x8b05807b5566370, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x5f, %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x89c4e07b545a968, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x60, %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x8a64b07b54df8d4, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x61, %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0xdcb27818fed9da90, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x62, %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x3ef0bdadda0c0a00, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x63, %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x79fa8d97ac77625a, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x64, %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x13f5793e33ebda4f, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x65, %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x19f79b1921bbcfff, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x66, %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0xf13ca4a2c837616a, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x67, %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0x56f5c9194461d57c, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x68, %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0xaf63dc4c8601ec8c, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x69, %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0x89c3807b5458406, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x6a, %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0x2587bcef32493841, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x6b, %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0x256cadef3232570c, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x6c, %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0xeaf1ba725db4c0c8, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x6d, %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0x418338728eb9a12a, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x6e, %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0x8a94307b5502113, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x6f, %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0xd3470d49a88be12a, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x70, %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0x337323193006782b, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x71, %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0x334a1a192fe363cc, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x72, %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0x19f7991921bbcc99, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x73, %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0xeb06b1725dc70d87, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x74, %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0x6035dc18f0bbd4d1, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x75, %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0xe6f7b419052023cd, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x76, %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0xe6f09b190519daa4, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x77, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0xd02d8a15c0f8e1e6, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x78, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0x1a5072758fdfbf3e, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x79, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0x76dbdc228f782db8, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x7a, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0xde3699178fd9f0bf, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x7b, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0x16f3e46051eee3e8, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x7c, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0x13cd72b1567d0710, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x7d, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0x6a351a3ecc6275f6, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x7e, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0x41c171b52673603c, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x7f, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xce14f5ad70f6ece2, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x80, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x782e6ca8b0d19235, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x81, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xdd1d0d790c2f1881, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x82, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x4328f78ab20e1f98, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x83, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x5e81a4f62c27eaa0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x84, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x5062cd8f7a7fd349, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x85, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x14e5faab9ce0e362, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x86, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xa63d4c9b882b10fe, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x87, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x47e83eaa4b387e3b, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x88, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x809788a9c1b27c3d, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x89, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xefc7af8dac33976c, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x8a, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x4592850c14d1d82b, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x8b, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x8c2cdb0da8933fa6, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x8c, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x1737f69e334c12b3, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x8d, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xfb9b5fb7a890a1fc, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x8e, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xb11e8b146c5a21d8, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x90, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xd60f473f93ff64a4, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x91, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x7cbbbe9dc702277d, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x92, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x9ffabb14f1b96c80, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x93, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x29338b6c39286b02, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x94, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x112b8c0079b0649f, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x95, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xbed8c20dc4e85ed9, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x96, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x39e433069cce324b, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x97, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x8b74507b55c61d5, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x98, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xe756c8190570da4d, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x99, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xf5e2f1190ce47dc5, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x9a, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xdc33f56761e466d0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x9b, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x8915907b53bb494, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x9c, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xa6190af6555abf8d, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x9d, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xa5f5dafcaa01716a, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x9e, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xb1ecd68e447facbe, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x9f, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x7aa8ee5e8b93b862, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xa0, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x354140628d05e768, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xa1, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x80f5019176d1e46, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xa2, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x335813192fef9543, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xa3, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x2e47c5cc74230edb, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xa4, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x5eade819487cb532, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xa5, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x3db3f1f61a19018c, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xaf, %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x83e1ead99b5801bb, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xb0, %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0xce87a3885811296e, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xb1, %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x8b73007b55c3e26, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xb2, %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0xe6f79719051ff286, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xb3, %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x8b05407b5565ca4, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xb4, %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x611e19135a72cc, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xb5, %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x2579c7ef323d0d96, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xca, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xca29c5e7d9e4dee2, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xcb, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x9b129e5d747a2a36, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xcc, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xc8d2072e7dc27646, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xcd, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x56769bf5181a61e9, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xce, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xf8deac21c8238342, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xcf, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xbf30e00dc53307a9, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xd0, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x3f82ce2f7bf75687, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xd1, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x3127fb469f19ebde, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xd2, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x1e65942e132f4f7a, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xd3, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xf1a2a766dcd55bac, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xd4, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xf7f50b364fa74fd, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xd5, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xc5a8f9e7c9642c1b, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xd6, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xaf951f534e9cc321, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xd7, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xc22cc76c12e7e854, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xd8, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x6f7bfbe4cb63b0ea, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xd9, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xdff7710dd73b9849, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xda, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xca14be67576694a3, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xdb, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xce02fabd24666a7c, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xdc, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x31ab1e1fcc28efe6, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xdd, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x7176e8904d2d565d, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xde, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xd140ac90e5927857, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xdf, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xc9162d52fe5b14c6, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xe0, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xad995c323f2f38de, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xe1, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x6ae3c01ef4feb47d, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xe2, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x983ad12fc0272970, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xe3, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xc88bce25446069d, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xe4, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x85aac62a460aa5e5, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xe5, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x163ca1f2c427ff19, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xe6, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x8ed8bca89377d4f7, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xe7, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x5b2e048b0099bd71, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xe8, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x212bc21925670c8c, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xe9, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xf91e91246d67f11b, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xea, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xe79981f33b2890e2, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xeb, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x35f71de13238ab42, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xec, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xf3f9755a0eea145f, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xed, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xdaa890758bf3eca3, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xee, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x9e62eed8ae1350ac, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xef, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x5db5d08f1efa5086, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xf0, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xb1da6b214500bf17, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xf1, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x38fa8bcdfda6f3a9, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xf2, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x8c18cf0da8828238, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xf3, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xfc6abdd11949714d, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xf4, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xac89001b7d96b89c, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xfb, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x1aaab1563505f90b, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xfc, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x24eb88339bb9218f, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xfd, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x995f3c87c56779fd, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xfe, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xbd76100bd58c9c0d, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xff, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xac167f3e17fae47e, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x100, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x41def2de29651139, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x101, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xdc57e42946f6e08c, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x102, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x5629fa3b509e87c8, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x103, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x83cf8e8f9081468b, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x104, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xc906da0a2f3e31d2, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x105, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xe6f720d6bec59784, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x106, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x6e308f493acb8a0b, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x107, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x9468996aba3e709, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x108, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xcbd94d6698379dad, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x109, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x9a848d5e6672b3de, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x10a, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x7da7727ca39ddcdc, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x10b, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x3f7f062d618bda39, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x10c, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xebe90009bda2153c, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x10d, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x9f79221341cfcb18, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x10e, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x565a3fdfd862a0a3, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x10f, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xf927453fbe6252ef, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x110, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xb8e2e36bdf267bf0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x111, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xc175dd4a02cce6d3, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x112, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x5b41d51752ea63ec, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x113, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x570411a086526886, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x114, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x6495b2dd1624a597, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x115, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xfa4a7ae3f75aae2, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x116, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xd9b482ebf58b2bfe, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x117, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x3ea2330771aa8bcc, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x118, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xf6f03821316e44c4, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x125, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x3e7fe942f71f1e61, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x126, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x2cfad818d3eccc11, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x127, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xfa48fcef19cf1ae2, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x129, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xda793c193643e93a, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x12a, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x1f573f5f6e8fdd53, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x12b, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xbf4b9bad694f4809, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x12c, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xa8548c33c7356014, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x12d, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x3e8c7e7610927412, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x12e, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x2c37327605e6eec6, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x12f, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xd558292ed4fdc7a, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x130, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x85ac46db6dbb602b, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x131, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x663afaa8a67896b2, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x132, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xaefd5a191d95e3f7, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x133, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x88adb2193921fcb4, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x134, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xb8eaa574819a7ff8, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x135, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x77dfa1348bae30df, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x136, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x7e6283be0952e02b, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x137, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x2b2751cd06cf643e, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x138, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x7d8fa30fca4c2181, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x145, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x4b2d077a4b387c2c, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x146, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xfe2abcf82cc72030, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x147, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x907bd39a08f34aac, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x14d, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x81e60b71d65a9676, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x14e, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x75cb2f53173bd8a, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x150, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xed4df38cf0d47908, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x151, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x880d59a733d283f9, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x152, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x9e7483c41fd1e772, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x153, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xea87658f8458aad2, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x154, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x2e3c6336da5a2a44, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x155, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x7ecc5a61e15573d1, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x156, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x2eb897ddc36753e5, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x157, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x9b2faff1a19bd4e0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x158, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xd42389c26929ffe5, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x159, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xf0895dff89f6182c, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x15a, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xb45e88d8d2f386ff, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x15b, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xdcd0020c0e22f4a8, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x15c, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x25b61c2b8fce2245, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x15d, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x96d557afab859ce9, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x15e, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x34f3857fa0d173e1, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x15f, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xbb8ba3f5d04f72c5, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x160, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x5c4e7260c8aacb9e, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x161, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x5aae932e27c1ae23, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x162, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xfbfed12d43216d8, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x169, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x164cacbef85eb87d, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x16b, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xc8f31246af8d829f, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x16c, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xb0577b29135f0bb1, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x16d, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xab39ffb7f3064afe, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x16f, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x4e4baec80fe39a67, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x170, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x732d1afa284ec2b5, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x171, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x78821e9b0c3452b4, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x172, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xc96fab8b04583b78, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x173, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xf74a76a458bf1fbb, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x174, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xeadd6394f6b31a63, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x175, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x93e4cd644f65cef2, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x176, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xee59b5ad45a96f42, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x177, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x13b30adcb67b5b87, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x178, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x880412efcf955079, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x179, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x919ec0f651278ba5, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x17a, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x501527249ec1fa77, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x17b, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xf3b9ad9fcd1d72ce, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x17c, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xfbfc79022fdbe01c, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x17d, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x4cf0781fbfe66969, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x17e, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x64bde8e4857adf2f, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x17f, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x13baf414d0d45ae6, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x180, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xf88358cffa436c67, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x187, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xd8d4335628b35226, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x188, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x6b0b6207e62dfb7e, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x189, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x862234eda24ea906, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x18a, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x3a506cb501761960, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x18b, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xcfb8a9d063b5e9e5, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x18d, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x335f20192ff5ca08, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x18e, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x9d2717bfe2cfa019, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x190, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xa0bc8eb4d76a3890, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x191, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x2a5bc800dfe8609c, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x192, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xe4b1a989d16d1fa8, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x193, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x1f375fa2ce7b1849, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x195, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xbfa17c01c2fa7ab0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x196, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xba8821b572531e29, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x197, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xbb0ecd6aede4a10c, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x198, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xa0dba500590b7544, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x199, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x4590274951cb0811, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x19a, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x9cdc3637e7ce0390, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x19b, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x33140a192fb5b92c, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x19c, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x7361ffdf75a113bc, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x19d, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xaa93248c32e711e8, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1a4, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x8a0bc1196111ad9b, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1a5, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x5f531287628bf287, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1a6, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x77203729b376a83f, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1a8, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x758d17ff764667b6, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1a9, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xf9928605e9a2ddd8, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1aa, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x853bb343610d9a4b, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1ad, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xf854f07310c52127, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1af, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x125073191daf5431, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1b0, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x380681e886cb2118, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1b1, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xbea01422b5f77185, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1b2, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x8f75c61dfd19093f, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1b3, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x1010a9eeee1ee669, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1b4, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xd6808830af3ece2c, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1b5, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xaa38aca481f528a8, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1b6, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xfe46f400c6b86658, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1b7, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x1166d9472f12eb82, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1b8, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x9123e5d0c6b648d1, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1b9, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x275e9f272c4022f9, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1ba, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x7b4c91363aa63b83, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1bb, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x5eadfb19487cd57b, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1bc, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x1f334da471217a08, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1bd, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x51a9737555bd5532, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1be, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x6b3ad3149ad2458, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1bf, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x7bf7df9dac60aced, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1c2, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x30e8a03a749583f8, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1c3, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x26c4b17d50b3c152, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1c5, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x432d22cedbc70e19, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1c7, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x55c474c8ec8f35d0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1c9, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xab23f0eec020c951, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1ca, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x97f5318bf97c581, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1cb, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x73a94c71d60dc0d8, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1cc, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x80f6619176d43a8, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1cd, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x56d7ab194448a4f3, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1cf, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xbfe9e4a0d3aa473f, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1d0, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x6292d59034c493c6, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1d1, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x2d7831feca432f9d, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1d2, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x3fb6db940e18f80f, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1d3, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x1bc813c95f74d71, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1d4, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xbbeb99cff9688969, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1d5, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x8950c6f3060a50d0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1d6, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x464d92ea3b21da22, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1d7, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xa2a05aaa108d6f4c, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1e0, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x37a5088f65df2240, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1e1, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xc73aaa4e183cea6d, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1e2, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x8986007b541df27, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1e3, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x9cc9eb61b98c200, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1e5, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x21cde1e8e13cf0cf, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1e6, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xabb697f29ac547aa, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1e8, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xde57d8eedce983cf, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1ea, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x72bd87d332d5304d, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1ee, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x5be5db62e943799, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1ef, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xc4b1f4eb0734a1a8, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1f0, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xaf33177cdfa85f9d, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1f1, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x96f6a06438719795, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1f2, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x79b6a9af7a07f29b, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1f3, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xad90b24c904b7f0f, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1f4, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xb0a35479d12bca8, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1f5, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x268b0f8129435ca, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1f6, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x4cc15c81538ca2e3, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1f7, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xa692f75ab08b8cf4, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1f8, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xd3deba2c41dadb2, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1f9, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x5eea961f9a171ded, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1fc, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x9eed1eec38392a7d, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x202, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xd88061d4eab33056, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x203, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x2d724c55c2f97f22, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x204, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xd9603bef07a9524c, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x205, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x1359777fe7032881, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x207, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x754a0a8c81da6c6b, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x208, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x60c0968b60f5f3b1, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x209, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xc6bb91769dfb1856, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x20a, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x23fa7a31f566ce26, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x20b, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xc7c79f98d1016379, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x20c, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xa51a677d5b590177, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x20d, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xa3e66bbb9ba9c7fa, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x20e, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xca8b48b8d4043b7c, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x20f, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x3c1856807823c952, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x210, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x8af203ac9dd3208d, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x211, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x4abbaca40bb6fe75, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x212, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x60827e549de65488, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x213, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xaebb18f16a62e878, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x214, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xfc9697d1196e6ba6, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x215, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x1e7683ef2ebc7684, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x216, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x46e670f93e615b51, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x217, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x75e7429b95100805, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x218, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x528080b48ef9464, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x219, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xff4d966bc22ed3b8, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x21a, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x5ddc92338ef53403, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x21b, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x5c83d5694e9ab882, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x21c, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xa7cf666efcba93f, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x21d, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xff29a08298a13117, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x21e, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x9e8c579513934bbd, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x21f, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xe4b480e7ff6ed680, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x220, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xb78ce49735cd209e, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x221, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x2584e9e765c2f420, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x222, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0xa26817d891ff02e8, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x223, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x30bce31147310a1, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x224, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x74770d66bf7310b8, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x225, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x1ff35e9ba24d70a0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x226, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x4d3a96aa6195bdfe, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x227, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x39ffe6865f96a237, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x228, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0xe0e2c14637b2f9c6, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x229, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x9d937c1ee8185a7, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x22a, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x87a0f9b00a91be1f, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x22b, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x7268f9bc90cbb82f, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x22d, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x4b9802c1f6edbb7e, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x22e, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0xdaa0cdc174d05c22, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x22f, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x437d9ad903da32f, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x230, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x25476753c8fed56b, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x232, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0xe6a89add94696e23, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x233, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0xd3ac3c45566efde9, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x234, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x294cf801edb925df, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x235, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x9575f08fb5a48f0d, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x236, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x18f456fc28bceb20, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x237, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0xe7d26541441cb9d, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x238, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x11ab14eb0a16bbec, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x239, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x4f56ded6f9e56456, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x23a, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0xaa7b14b81abbff91, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x23b, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x72e73f9193bbcc4e, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x23c, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0xa4cb121f9ce4c4c0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x23d, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x3b84ace629c111a0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x23e, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0xdcbc48dde2aa1342, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x23f, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0xdcc7d1d73cc94cfb, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x240, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x80a026ee7d87df4, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x244, %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0xccdc8cf36112db5, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x245, %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x827b4ba8fc12da7a, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x246, %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x3e7a7b3c9a5a917e, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x249, %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0xdb064bce756460df, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x24a, %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0xee5e58eecb4ba24, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x24b, %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0xd0de8495c39a2713, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x24c, %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x85098434b100ad3a, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x24d, %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x9fa57a2c45387d1d, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x24e, %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x9c3438e46fed322a, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x24f, %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x813e465a434a0b57, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x250, %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0xa26803d891fee0ec, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x251, %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0xf528f3c03c7de903, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x252, %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x74ebd93576ff140d, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x253, %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0xfeb779a7606d6d9a, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x254, %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x618e7dfce338699d, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x255, %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x1e62b527024928e1, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x256, %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x26af9bbf6456e062, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x257, %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0xb804ec8277b10f43, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x258, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0xeee30ba769e2c027, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x259, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0x7a84fcbd27678ac9, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x25a, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0x889e2518da4747a4, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x25b, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0x5e1ad671457ea90, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x25c, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0x9d24b27ac6ddeae4, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x25d, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0x93276c3e4e6f3f27, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x25e, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0xbf31137ff783e939, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x25f, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0xd7fbc18fbdaa00d1, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x260, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0xef86a020455be6f3, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x262, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0x6a15b4158aa383d7, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x263, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0xd683b0e24e05d843, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x264, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0x1ae6a30eed204c9f, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x265, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0xc47ea73e7986f3de, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x266, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0x7294d77db181ded2, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x267, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0x4077f8cc7eaf4d6f, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x268, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0xceadb82265a0b7f3, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x269, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0xe7b67755395b0a6a, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x26a, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0x554667f2165fec5d, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x26b, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0x1c2058c7ec7c8835, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x26c, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0xd8d69c51bf35f745, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x26d, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0xc12c4d89efa76351, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x26e, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xc8beca9cc149b9f3, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x26f, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x7f1b75eac4f51095, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x270, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x2e3c6336da5a2a44, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x271, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xfad06255a6acaf5b, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x272, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xaa3f4d29d02d54dd, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x273, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x3f546529170319f5, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x274, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x86c8946e5047dea7, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x275, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xeb246e5cabc40ca8, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq nl_lex_register_hash
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movb %al, L_NL_LEX_INITED(%rip)
    movslq L_NL_LEX_OK(%rip), %rax
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
