# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "xii_term.iiixii_term.iiixii_term.iiixii_term.iiixii_term.iiixii_term.iiixii_term.iiixii_term.iiixii_term.iiixii_rewrite.iiixii_rewrite.iii\0"
L_str_1:
    .ascii "xii_term.iiixii_term.iiixii_term.iiixii_term.iiixii_term.iiixii_term.iiixii_term.iiixii_term.iiixii_rewrite.iiixii_rewrite.iii\0"
L_str_2:
    .ascii "xii_term.iiixii_term.iiixii_term.iiixii_term.iiixii_term.iiixii_term.iiixii_term.iiixii_rewrite.iiixii_rewrite.iii\0"
L_str_3:
    .ascii "xii_term.iiixii_term.iiixii_term.iiixii_term.iiixii_term.iiixii_term.iiixii_rewrite.iiixii_rewrite.iii\0"
L_str_4:
    .ascii "xii_term.iiixii_term.iiixii_term.iiixii_term.iiixii_term.iiixii_rewrite.iiixii_rewrite.iii\0"
L_str_5:
    .ascii "xii_term.iiixii_term.iiixii_term.iiixii_term.iiixii_rewrite.iiixii_rewrite.iii\0"
L_str_6:
    .ascii "xii_term.iiixii_term.iiixii_term.iiixii_rewrite.iiixii_rewrite.iii\0"
L_str_7:
    .ascii "xii_term.iiixii_term.iiixii_rewrite.iiixii_rewrite.iii\0"
L_str_8:
    .ascii "xii_term.iiixii_rewrite.iiixii_rewrite.iii\0"
L_str_9:
    .ascii "xii_rewrite.iiixii_rewrite.iii\0"
L_str_10:
    .ascii "xii_rewrite.iii\0"
    .section .rodata
L_XRP_N:
    .quad 0x2d
L_XRP_ANY:
    .quad 0xff
L_XRP_NULL_REF:
    .quad 0xffffffff
L_XRP_SENT:
    .quad 0xffffffff
L_XRP_U32MASK:
    .quad 0xffffffff
L_XRP_K01:
    .quad 0x0
L_XRP_K04:
    .quad 0x3
L_XRP_K05:
    .quad 0x4
L_XRP_K06:
    .quad 0x5
L_XRP_K07:
    .quad 0x6
L_XRP_K08:
    .quad 0x7
L_XRP_K09:
    .quad 0x8
L_XRP_K10:
    .quad 0x9
L_XRP_K11:
    .quad 0xa
L_XRP_K12:
    .quad 0xb
L_XRP_K17:
    .quad 0x10
L_XRP_K18:
    .quad 0x11
L_XRP_FCOMPOSE:
    .quad 0x12
L_XRP_FTHEN:
    .quad 0x13
L_XRP_FWITH:
    .quad 0x14
L_XRP_FUNDER:
    .quad 0x15
L_XRP_FIF:
    .quad 0x16
L_XRP_FLOOP:
    .quad 0x17
L_XRP_TVAL:
    .quad 0x18
L_XRP_TNOT:
    .quad 0x19
L_XRP_TAND:
    .quad 0x1a
L_XRP_TOR:
    .quad 0x1b
L_XRP_TSUM:
    .quad 0x1c
L_XRP_TMUL:
    .quad 0x1d
L_XRP_NULLGROUND:
    .quad 0xffffffff
L_XRP_TRIVLIFT:
    .quad 0xfffffffd
    .section .bss
    .global L_XRP_RID
L_XRP_RID:
    .zero 392
    .global L_XRP_ROOT
L_XRP_ROOT:
    .zero 392
    .global L_XRP_CA
L_XRP_CA:
    .zero 392
    .global L_XRP_CB
L_XRP_CB:
    .zero 392
    .global L_XRP_CC
L_XRP_CC:
    .zero 392
    .section .iii.ring3,"n"
    .asciz "_xrp_set"
    .text
    .global L__xrp_set
    .seh_proc L__xrp_set
L__xrp_set:
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
    leaq L_XRP_RID(%rip), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_XRP_ROOT(%rip), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_XRP_CA(%rip), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_XRP_CB(%rip), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_XRP_CC(%rip), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
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
    .asciz "_xrp_add"
    .text
    .global L__xrp_add
    .seh_proc L__xrp_add
L__xrp_add:
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
    movq -48(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_set
    addq $32, %rsp
    addq $16, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
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
    .section .iii.ring3,"n"
    .asciz "_xrp_fill"
    .text
    .global L__xrp_fill
    .seh_proc L__xrp_fill
L__xrp_fill:
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
    movq L_XRP_FTHEN(%rip), %rax
    pushq %rax
    movq L_XRP_FTHEN(%rip), %rax
    pushq %rax
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_FIF(%rip), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_FTHEN(%rip), %rax
    pushq %rax
    movq L_XRP_FTHEN(%rip), %rax
    pushq %rax
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_FIF(%rip), %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_FCOMPOSE(%rip), %rax
    pushq %rax
    movq L_XRP_FCOMPOSE(%rip), %rax
    pushq %rax
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_FIF(%rip), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_FCOMPOSE(%rip), %rax
    pushq %rax
    movq L_XRP_FCOMPOSE(%rip), %rax
    pushq %rax
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_FIF(%rip), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_FWITH(%rip), %rax
    pushq %rax
    movq L_XRP_FWITH(%rip), %rax
    pushq %rax
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_FIF(%rip), %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_FWITH(%rip), %rax
    pushq %rax
    movq L_XRP_FWITH(%rip), %rax
    pushq %rax
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_FIF(%rip), %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_FUNDER(%rip), %rax
    pushq %rax
    movq L_XRP_FUNDER(%rip), %rax
    pushq %rax
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_FIF(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_FUNDER(%rip), %rax
    pushq %rax
    movq L_XRP_FUNDER(%rip), %rax
    pushq %rax
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_FIF(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_FLOOP(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_FLOOP(%rip), %rax
    pushq %rax
    movq L_XRP_FLOOP(%rip), %rax
    pushq %rax
    movabsq $0xe, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_FCOMPOSE(%rip), %rax
    pushq %rax
    movq L_XRP_FLOOP(%rip), %rax
    pushq %rax
    movabsq $0xf, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_K06(%rip), %rax
    pushq %rax
    movq L_XRP_FWITH(%rip), %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_K06(%rip), %rax
    pushq %rax
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_FCOMPOSE(%rip), %rax
    pushq %rax
    movabsq $0x11, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_K01(%rip), %rax
    pushq %rax
    movq L_XRP_FIF(%rip), %rax
    pushq %rax
    movabsq $0x12, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_K01(%rip), %rax
    pushq %rax
    movq L_XRP_FIF(%rip), %rax
    pushq %rax
    movabsq $0x13, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_K10(%rip), %rax
    pushq %rax
    movq L_XRP_FUNDER(%rip), %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_K12(%rip), %rax
    pushq %rax
    movq L_XRP_FTHEN(%rip), %rax
    pushq %rax
    movabsq $0x15, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_K12(%rip), %rax
    pushq %rax
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_FTHEN(%rip), %rax
    pushq %rax
    movabsq $0x16, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_K10(%rip), %rax
    pushq %rax
    movq L_XRP_K10(%rip), %rax
    pushq %rax
    movq L_XRP_FCOMPOSE(%rip), %rax
    pushq %rax
    movabsq $0x17, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_K17(%rip), %rax
    pushq %rax
    movq L_XRP_K17(%rip), %rax
    pushq %rax
    movq L_XRP_FTHEN(%rip), %rax
    pushq %rax
    movabsq $0x18, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_K17(%rip), %rax
    pushq %rax
    movabsq $0x19, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_K07(%rip), %rax
    pushq %rax
    movq L_XRP_K06(%rip), %rax
    pushq %rax
    movq L_XRP_FTHEN(%rip), %rax
    pushq %rax
    movabsq $0x1a, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_K08(%rip), %rax
    pushq %rax
    movq L_XRP_K07(%rip), %rax
    pushq %rax
    movq L_XRP_FCOMPOSE(%rip), %rax
    pushq %rax
    movabsq $0x1b, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_K05(%rip), %rax
    pushq %rax
    movq L_XRP_K05(%rip), %rax
    pushq %rax
    movq L_XRP_FCOMPOSE(%rip), %rax
    pushq %rax
    movabsq $0x1c, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_K05(%rip), %rax
    pushq %rax
    movq L_XRP_K05(%rip), %rax
    pushq %rax
    movq L_XRP_FTHEN(%rip), %rax
    pushq %rax
    movabsq $0x1d, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_FIF(%rip), %rax
    pushq %rax
    movabsq $0x1e, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_K04(%rip), %rax
    pushq %rax
    movq L_XRP_K04(%rip), %rax
    pushq %rax
    movq L_XRP_FTHEN(%rip), %rax
    pushq %rax
    movabsq $0x1f, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_K01(%rip), %rax
    pushq %rax
    movq L_XRP_K01(%rip), %rax
    pushq %rax
    movq L_XRP_FCOMPOSE(%rip), %rax
    pushq %rax
    movabsq $0x20, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_K09(%rip), %rax
    pushq %rax
    movq L_XRP_K09(%rip), %rax
    pushq %rax
    movq L_XRP_FCOMPOSE(%rip), %rax
    pushq %rax
    movabsq $0x21, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_K18(%rip), %rax
    pushq %rax
    movq L_XRP_K18(%rip), %rax
    pushq %rax
    movq L_XRP_FCOMPOSE(%rip), %rax
    pushq %rax
    movabsq $0x22, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_K11(%rip), %rax
    pushq %rax
    movq L_XRP_K11(%rip), %rax
    pushq %rax
    movq L_XRP_FTHEN(%rip), %rax
    pushq %rax
    movabsq $0x23, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_K06(%rip), %rax
    pushq %rax
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_FWITH(%rip), %rax
    pushq %rax
    movabsq $0x24, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_K06(%rip), %rax
    pushq %rax
    movq L_XRP_FCOMPOSE(%rip), %rax
    pushq %rax
    movabsq $0x25, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_K06(%rip), %rax
    pushq %rax
    movq L_XRP_K06(%rip), %rax
    pushq %rax
    movq L_XRP_FCOMPOSE(%rip), %rax
    pushq %rax
    movabsq $0x26, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_K06(%rip), %rax
    pushq %rax
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_FUNDER(%rip), %rax
    pushq %rax
    movabsq $0x27, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_K06(%rip), %rax
    pushq %rax
    movq L_XRP_K06(%rip), %rax
    pushq %rax
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_FIF(%rip), %rax
    pushq %rax
    movabsq $0x28, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_K06(%rip), %rax
    pushq %rax
    movq L_XRP_FLOOP(%rip), %rax
    pushq %rax
    movabsq $0x29, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_FCOMPOSE(%rip), %rax
    pushq %rax
    movq L_XRP_K01(%rip), %rax
    pushq %rax
    movq L_XRP_FCOMPOSE(%rip), %rax
    pushq %rax
    movabsq $0x2a, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_K17(%rip), %rax
    pushq %rax
    movq L_XRP_FTHEN(%rip), %rax
    pushq %rax
    movabsq $0x2b, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_K17(%rip), %rax
    pushq %rax
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_FTHEN(%rip), %rax
    pushq %rax
    movabsq $0x2c, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_TVAL(%rip), %rax
    pushq %rax
    movq L_XRP_TNOT(%rip), %rax
    pushq %rax
    movabsq $0x65, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_TVAL(%rip), %rax
    pushq %rax
    movq L_XRP_TVAL(%rip), %rax
    pushq %rax
    movq L_XRP_TAND(%rip), %rax
    pushq %rax
    movabsq $0x66, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_TVAL(%rip), %rax
    pushq %rax
    movq L_XRP_TVAL(%rip), %rax
    pushq %rax
    movq L_XRP_TOR(%rip), %rax
    pushq %rax
    movabsq $0x67, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_TVAL(%rip), %rax
    pushq %rax
    movq L_XRP_TVAL(%rip), %rax
    pushq %rax
    movq L_XRP_TSUM(%rip), %rax
    pushq %rax
    movabsq $0x68, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_XRP_ANY(%rip), %rax
    pushq %rax
    movq L_XRP_TVAL(%rip), %rax
    pushq %rax
    movq L_XRP_TVAL(%rip), %rax
    pushq %rax
    movq L_XRP_TMUL(%rip), %rax
    pushq %rax
    movabsq $0x69, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L__xrp_add
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "_xrp_ensure"
    .text
    .global L__xrp_ensure
    .seh_proc L__xrp_ensure
L__xrp_ensure:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    leaq L_XRP_RID(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
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
    jz L_if_end_1
    subq $32, %rsp
    callq L__xrp_fill
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_1:
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "_xrp_slot"
    .text
    .global L__xrp_slot
    .seh_proc L__xrp_slot
L__xrp_slot:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    subq $32, %rsp
    callq L__xrp_ensure
    addq $32, %rsp
    pushq %rax
    popq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movq L_XRP_U32MASK(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
L_loop_top_2:
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x31, %rax
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
    leaq L_XRP_RID(%rip), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
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
    jz L_if_end_5
    movq -24(%rbp), %rax
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
    popq %rax
L_if_end_5:
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
    jmp L_loop_top_2
L_loop_end_3:
    movl L_XRP_SENT(%rip), %eax
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
    .asciz "_xrp_child_ok"
    .text
    .global L__xrp_child_ok
    .seh_proc L__xrp_child_ok
L__xrp_child_ok:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    movq L_XRP_ANY(%rip), %rax
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
    movl -8(%rbp), %eax
    pushq %rax
    movl L_XRP_NULL_REF(%rip), %eax
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
    movl -8(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq xii_term_get_kind
    addq $32, %rsp
    movzbq %al, %rax
    pushq %rax
    popq %rax
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
    .asciz "xrp_struct_match"
    .text
    .global xrp_struct_match
    .seh_proc xrp_struct_match
xrp_struct_match:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movl -16(%rbp), %eax
    pushq %rax
    movl L_XRP_NULL_REF(%rip), %eax
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
    movl -8(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L__xrp_slot
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movl -24(%rbp), %eax
    pushq %rax
    movl L_XRP_SENT(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
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
    movl -24(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movq L_XRP_U32MASK(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movl -16(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq xii_term_get_kind
    addq $32, %rsp
    movzbq %al, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_XRP_ROOT(%rip), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
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
    leaq L_XRP_CA(%rip), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    subq $8, %rsp
    movl -16(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq xii_term_get_child_a
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L__xrp_child_ok
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
    leaq L_XRP_CB(%rip), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    subq $8, %rsp
    movl -16(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq xii_term_get_child_b
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L__xrp_child_ok
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
    leaq L_XRP_CC(%rip), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    subq $8, %rsp
    movl -16(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq xii_term_get_child_c
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L__xrp_child_ok
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
    .asciz "xrp_rule_count"
    .text
    .global xrp_rule_count
    .seh_proc xrp_rule_count
xrp_rule_count:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    subq $32, %rsp
    callq L__xrp_ensure
    addq $32, %rsp
    pushq %rax
    popq %rax
    movl L_XRP_N(%rip), %eax
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
    .asciz "xrp_rid_at"
    .text
    .global xrp_rid_at
    .seh_proc xrp_rid_at
xrp_rid_at:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    subq $32, %rsp
    callq L__xrp_ensure
    addq $32, %rsp
    pushq %rax
    popq %rax
    movl -8(%rbp), %eax
    pushq %rax
    movl L_XRP_N(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_25
    movl L_XRP_SENT(%rip), %eax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_25:
    leaq L_XRP_RID(%rip), %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movq L_XRP_U32MASK(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movq L_XRP_U32MASK(%rip), %rax
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
    .asciz "xrp_root_at"
    .text
    .global xrp_root_at
    .seh_proc xrp_root_at
xrp_root_at:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    subq $32, %rsp
    callq L__xrp_ensure
    addq $32, %rsp
    pushq %rax
    popq %rax
    movl -8(%rbp), %eax
    pushq %rax
    movl L_XRP_N(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_27
    movl L_XRP_SENT(%rip), %eax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_27:
    leaq L_XRP_ROOT(%rip), %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movq L_XRP_U32MASK(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movq L_XRP_U32MASK(%rip), %rax
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
    .asciz "xrp_ca_at"
    .text
    .global xrp_ca_at
    .seh_proc xrp_ca_at
xrp_ca_at:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    subq $32, %rsp
    callq L__xrp_ensure
    addq $32, %rsp
    pushq %rax
    popq %rax
    movl -8(%rbp), %eax
    pushq %rax
    movl L_XRP_N(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_29
    movl L_XRP_SENT(%rip), %eax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_29:
    leaq L_XRP_CA(%rip), %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movq L_XRP_U32MASK(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movq L_XRP_U32MASK(%rip), %rax
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
    .asciz "xrp_cb_at"
    .text
    .global xrp_cb_at
    .seh_proc xrp_cb_at
xrp_cb_at:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    subq $32, %rsp
    callq L__xrp_ensure
    addq $32, %rsp
    pushq %rax
    popq %rax
    movl -8(%rbp), %eax
    pushq %rax
    movl L_XRP_N(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_31
    movl L_XRP_SENT(%rip), %eax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_31:
    leaq L_XRP_CB(%rip), %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movq L_XRP_U32MASK(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movq L_XRP_U32MASK(%rip), %rax
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
    .asciz "xrp_cc_at"
    .text
    .global xrp_cc_at
    .seh_proc xrp_cc_at
xrp_cc_at:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    subq $32, %rsp
    callq L__xrp_ensure
    addq $32, %rsp
    pushq %rax
    popq %rax
    movl -8(%rbp), %eax
    pushq %rax
    movl L_XRP_N(%rip), %eax
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
    movl L_XRP_SENT(%rip), %eax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_33:
    leaq L_XRP_CC(%rip), %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movq L_XRP_U32MASK(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movq L_XRP_U32MASK(%rip), %rax
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
    .asciz "_xrp_check"
    .text
    .global L__xrp_check
    .seh_proc L__xrp_check
L__xrp_check:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movl -16(%rbp), %eax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xrp_struct_match
    addq $32, %rsp
    movzbq %al, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movl -16(%rbp), %eax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xii_rewrite_apply_specific
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq xii_rewrite_last_rule_fired
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movl -8(%rbp), %eax
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
    movabsq $0x2, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_35:
    movzbq -24(%rbp), %rax
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
    jz L_if_end_37
    movabsq $0x3, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_37:
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
    .asciz "_xrp_make_kind"
    .text
    .global L__xrp_make_kind
    .seh_proc L__xrp_make_kind
L__xrp_make_kind:
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
    movabsq $0x11, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setbe %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_39
    movabsq $0x0, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xii_term_make_basis
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_39:
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x18, %rax
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
    movabsq $0x18, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xii_term_make_basis
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_41:
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x16, %rax
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
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xii_term_make_basis
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    subq $8, %rsp
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xii_term_make_basis
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xii_term_make_basis
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq xii_term_make_if
    addq $32, %rsp
    movl %eax, %eax
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
    movabsq $0x17, %rax
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
    movabsq $0x0, %rax
    pushq %rax
    subq $8, %rsp
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xii_term_make_basis
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xii_term_make_loop
    addq $32, %rsp
    movl %eax, %eax
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
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xii_term_make_basis
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    subq $8, %rsp
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xii_term_make_basis
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq xii_term_make_fusion2
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
    .asciz "_xrp_child_or_leaf"
    .text
    .global L__xrp_child_or_leaf
    .seh_proc L__xrp_child_or_leaf
L__xrp_child_or_leaf:
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
    movq L_XRP_ANY(%rip), %rax
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
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xii_term_make_basis
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_47:
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L__xrp_make_kind
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
    .asciz "_xrp_shape_term"
    .text
    .global L__xrp_shape_term
    .seh_proc L__xrp_shape_term
L__xrp_shape_term:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    leaq L_XRP_ROOT(%rip), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x11, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setbe %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_49
    movabsq $0x0, %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xii_term_make_basis
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_49:
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x18, %rax
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
    movabsq $0x18, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xii_term_make_basis
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_51:
    leaq L_XRP_CA(%rip), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L__xrp_child_or_leaf
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    leaq L_XRP_CB(%rip), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L__xrp_child_or_leaf
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x16, %rax
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
    leaq L_XRP_CC(%rip), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L__xrp_child_or_leaf
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq xii_term_make_if
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_53:
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x17, %rax
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
    movabsq $0x0, %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xii_term_make_loop
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_55:
    movl -32(%rbp), %eax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq xii_term_make_fusion2
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
    .asciz "xrp_selftest"
    .text
    .global xrp_selftest
    .seh_proc xrp_selftest
xrp_selftest:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    subq $32, %rsp
    callq L__xrp_ensure
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq xrp_rule_count
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0x2d, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_57
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_57:
    leaq L_XRP_RID(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_59
    movabsq $0x2, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_59:
    leaq L_XRP_RID(%rip), %rax
    pushq %rax
    movabsq $0x27, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movabsq $0x2c, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_61
    movabsq $0x3, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_61:
    leaq L_XRP_RID(%rip), %rax
    pushq %rax
    movabsq $0x2c, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movabsq $0x69, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_63
    movabsq $0x4, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_63:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
L_loop_top_64:
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x2d, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_65
    leaq L_XRP_ROOT(%rip), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movabsq $0x1d, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    seta %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_67
    movabsq $0x5, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_67:
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_64
L_loop_end_65:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
L_loop_top_68:
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x2d, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_69
    subq $32, %rsp
    callq xii_term_arena_reset
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    leaq L_XRP_RID(%rip), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movq L_XRP_U32MASK(%rip), %rax
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
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L__xrp_shape_term
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xrp_struct_match
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
    jz L_if_end_71
    movabsq $0x28, %rax
    pushq %rax
    movq -16(%rbp), %rax
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
L_if_end_71:
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_68
L_loop_end_69:
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    subq $32, %rsp
    callq xii_term_arena_reset
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movl L_XRP_NULLGROUND(%rip), %eax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xii_term_make_basis
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    subq $8, %rsp
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xii_term_make_basis
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0x12, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq xii_term_make_fusion2
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movl -32(%rbp), %eax
    pushq %rax
    movabsq $0x11, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L__xrp_check
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
    jz L_if_end_73
    movabsq $0xb, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_73:
    subq $32, %rsp
    callq xii_term_arena_reset
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xii_term_make_basis
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    subq $8, %rsp
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xii_term_make_basis
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0x12, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq xii_term_make_fusion2
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movl -40(%rbp), %eax
    pushq %rax
    movabsq $0x20, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L__xrp_check
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
    jz L_if_end_75
    movabsq $0xc, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_75:
    subq $32, %rsp
    callq xii_term_arena_reset
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x7, %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xii_term_make_basis
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    subq $8, %rsp
    movabsq $0x7, %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xii_term_make_basis
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0x12, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq xii_term_make_fusion2
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movl -48(%rbp), %eax
    pushq %rax
    movabsq $0x21, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L__xrp_check
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
    jz L_if_end_77
    movabsq $0xd, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_77:
    subq $32, %rsp
    callq xii_term_arena_reset
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xii_term_make_basis
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    subq $8, %rsp
    movl L_XRP_NULLGROUND(%rip), %eax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xii_term_make_basis
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0x12, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq xii_term_make_fusion2
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movl -56(%rbp), %eax
    pushq %rax
    movabsq $0x25, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L__xrp_check
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
    jz L_if_end_79
    movabsq $0xe, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_79:
    subq $32, %rsp
    callq xii_term_arena_reset
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movl L_XRP_NULLGROUND(%rip), %eax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xii_term_make_basis
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    subq $8, %rsp
    movl L_XRP_NULLGROUND(%rip), %eax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xii_term_make_basis
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0x12, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq xii_term_make_fusion2
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movl -64(%rbp), %eax
    pushq %rax
    movabsq $0x26, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L__xrp_check
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
    movabsq $0xf, %rax
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
    callq xii_term_arena_reset
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xii_term_make_basis
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    subq $8, %rsp
    movl L_XRP_NULLGROUND(%rip), %eax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xii_term_make_basis
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0x13, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq xii_term_make_fusion2
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movl -72(%rbp), %eax
    pushq %rax
    movabsq $0x15, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L__xrp_check
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
    movabsq $0x10, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_83:
    subq $32, %rsp
    callq xii_term_arena_reset
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movl L_XRP_TRIVLIFT(%rip), %eax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xii_term_make_basis
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    subq $8, %rsp
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xii_term_make_basis
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0x13, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq xii_term_make_fusion2
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -80(%rbp)
    movl -80(%rbp), %eax
    pushq %rax
    movabsq $0x2c, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L__xrp_check
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
    movabsq $0x11, %rax
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
    callq xii_term_arena_reset
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1, %rax
    pushq %rax
    subq $8, %rsp
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xii_term_make_basis
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xii_term_make_loop
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
    movl -88(%rbp), %eax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L__xrp_check
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
    movabsq $0x12, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_87:
    subq $32, %rsp
    callq xii_term_arena_reset
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x18, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xii_term_make_basis
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    subq $8, %rsp
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x18, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xii_term_make_basis
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0x19, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq xii_term_make_fusion2
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -96(%rbp)
    movl -96(%rbp), %eax
    pushq %rax
    movabsq $0x65, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L__xrp_check
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
    jz L_if_end_89
    movabsq $0x13, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_89:
    subq $32, %rsp
    callq xii_term_arena_reset
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x18, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xii_term_make_basis
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    subq $8, %rsp
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x18, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xii_term_make_basis
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0x1a, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq xii_term_make_fusion2
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -104(%rbp)
    movl -104(%rbp), %eax
    pushq %rax
    movabsq $0x66, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L__xrp_check
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
    movabsq $0x14, %rax
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
    callq xii_term_arena_reset
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x18, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xii_term_make_basis
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -112(%rbp)
    movl -112(%rbp), %eax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xrp_struct_match
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
    jz L_if_end_93
    movabsq $0x1e, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_93:
    movl -112(%rbp), %eax
    pushq %rax
    movabsq $0x66, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xrp_struct_match
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
    jz L_if_end_95
    movabsq $0x1f, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_95:
    subq $32, %rsp
    callq xii_term_arena_reset
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xii_term_make_basis
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    subq $8, %rsp
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xii_term_make_basis
    addq $32, %rsp
    addq $8, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0x12, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq xii_term_make_fusion2
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -120(%rbp)
    movl -120(%rbp), %eax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xrp_struct_match
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
    movl -120(%rbp), %eax
    pushq %rax
    movabsq $0x11, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xrp_struct_match
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
    movl -120(%rbp), %eax
    pushq %rax
    movabsq $0x309, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq xrp_struct_match
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
    jz L_if_end_101
    movabsq $0x22, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_101:
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
