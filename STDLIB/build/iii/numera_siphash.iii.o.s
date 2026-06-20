# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "weave_blocks.iii\0"
    .section .rodata
L_SIP_C0:
    .quad 0x736f6d6570736575
L_SIP_C1:
    .quad 0x646f72616e646f6d
L_SIP_C2:
    .quad 0x6c7967656e657261
L_SIP_C3:
    .quad 0x7465646279746573
    .section .data
    .global L_SIP_V0
L_SIP_V0:
    .quad 0x0
    .global L_SIP_V1
L_SIP_V1:
    .quad 0x0
    .global L_SIP_V2
L_SIP_V2:
    .quad 0x0
    .global L_SIP_V3
L_SIP_V3:
    .quad 0x0
    .section .bss
    .global L_SIP_KAT_KEY
L_SIP_KAT_KEY:
    .zero 128
    .global L_SIP_KAT_MSG
L_SIP_KAT_MSG:
    .zero 512
    .section .iii.ring3,"n"
    .asciz "sip_load_le8"
    .text
    .seh_proc L_sip_load_le8
L_sip_load_le8:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -80(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rax
    shlq $8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rax
    shlq $16, %rax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rax
    shlq $24, %rax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    popq %rax
    shlq $32, %rax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    movq -64(%rbp), %rax
    pushq %rax
    popq %rax
    shlq $40, %rax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    popq %rax
    shlq $48, %rax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    movq -80(%rbp), %rax
    pushq %rax
    popq %rax
    shlq $56, %rax
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
    .asciz "sip_round"
    .text
    .seh_proc L_sip_round
L_sip_round:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq L_SIP_V0(%rip), %rax
    pushq %rax
    movq L_SIP_V1(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, L_SIP_V0(%rip)
    movabsq $0xd, %rax
    pushq %rax
    movq L_SIP_V1(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq wvb_rotl64
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, L_SIP_V1(%rip)
    movq L_SIP_V1(%rip), %rax
    pushq %rax
    movq L_SIP_V0(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, L_SIP_V1(%rip)
    movabsq $0x20, %rax
    pushq %rax
    movq L_SIP_V0(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq wvb_rotl64
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, L_SIP_V0(%rip)
    movq L_SIP_V2(%rip), %rax
    pushq %rax
    movq L_SIP_V3(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, L_SIP_V2(%rip)
    movabsq $0x10, %rax
    pushq %rax
    movq L_SIP_V3(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq wvb_rotl64
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, L_SIP_V3(%rip)
    movq L_SIP_V3(%rip), %rax
    pushq %rax
    movq L_SIP_V2(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, L_SIP_V3(%rip)
    movq L_SIP_V0(%rip), %rax
    pushq %rax
    movq L_SIP_V3(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, L_SIP_V0(%rip)
    movabsq $0x15, %rax
    pushq %rax
    movq L_SIP_V3(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq wvb_rotl64
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, L_SIP_V3(%rip)
    movq L_SIP_V3(%rip), %rax
    pushq %rax
    movq L_SIP_V0(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, L_SIP_V3(%rip)
    movq L_SIP_V2(%rip), %rax
    pushq %rax
    movq L_SIP_V1(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, L_SIP_V2(%rip)
    movabsq $0x11, %rax
    pushq %rax
    movq L_SIP_V1(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq wvb_rotl64
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, L_SIP_V1(%rip)
    movq L_SIP_V1(%rip), %rax
    pushq %rax
    movq L_SIP_V2(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, L_SIP_V1(%rip)
    movabsq $0x20, %rax
    pushq %rax
    movq L_SIP_V2(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq wvb_rotl64
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, L_SIP_V2(%rip)
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
    .asciz "siphash24_keyed"
    .text
    .global siphash24_keyed
    .seh_proc siphash24_keyed
siphash24_keyed:
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
    movq L_SIP_C0(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, L_SIP_V0(%rip)
    movq -16(%rbp), %rax
    pushq %rax
    movq L_SIP_C1(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, L_SIP_V1(%rip)
    movq -8(%rbp), %rax
    pushq %rax
    movq L_SIP_C2(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, L_SIP_V2(%rip)
    movq -16(%rbp), %rax
    pushq %rax
    movq L_SIP_C3(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, L_SIP_V3(%rip)
    movq -32(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
L_loop_top_0:
    movq -48(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
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
    movq -48(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_sip_load_le8
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq L_SIP_V3(%rip), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, L_SIP_V3(%rip)
    subq $32, %rsp
    callq L_sip_round
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq L_sip_round
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movq L_SIP_V0(%rip), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, L_SIP_V0(%rip)
    movq -48(%rbp), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_0
L_loop_end_1:
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    shlq $56, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
L_loop_top_2:
    movq -72(%rbp), %rax
    pushq %rax
    movq -64(%rbp), %rax
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
    movq -56(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
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
    movq %rax, -56(%rbp)
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
    jmp L_loop_top_2
L_loop_end_3:
    movq L_SIP_V3(%rip), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, L_SIP_V3(%rip)
    subq $32, %rsp
    callq L_sip_round
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq L_sip_round
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movq L_SIP_V0(%rip), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, L_SIP_V0(%rip)
    movq L_SIP_V2(%rip), %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, L_SIP_V2(%rip)
    subq $32, %rsp
    callq L_sip_round
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq L_sip_round
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq L_sip_round
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq L_sip_round
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movq L_SIP_V0(%rip), %rax
    pushq %rax
    movq L_SIP_V1(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    movq L_SIP_V2(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    movq L_SIP_V3(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
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
    .asciz "siphash24"
    .text
    .global siphash24
    .seh_proc siphash24
siphash24:
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
    movabsq $0x0, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_sip_load_le8
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movabsq $0x8, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_sip_load_le8
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq siphash24_keyed
    addq $32, %rsp
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
    .asciz "siphash_selftest"
    .text
    .global siphash_selftest
    .seh_proc siphash_selftest
siphash_selftest:
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
L_loop_top_4:
    movq -8(%rbp), %rax
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
    jz L_loop_end_5
    leaq L_SIP_KAT_KEY(%rip), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
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
    jmp L_loop_top_4
L_loop_end_5:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
L_loop_top_6:
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x40, %rax
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
    leaq L_SIP_KAT_MSG(%rip), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
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
    jmp L_loop_top_6
L_loop_end_7:
    movabsq $0x0, %rax
    pushq %rax
    leaq L_SIP_KAT_MSG(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_SIP_KAT_KEY(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq siphash24
    addq $32, %rsp
    pushq %rax
    movabsq $0x726fdb47dd0e0e31, %rax
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
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_9:
    movabsq $0x1, %rax
    pushq %rax
    leaq L_SIP_KAT_MSG(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_SIP_KAT_KEY(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq siphash24
    addq $32, %rsp
    pushq %rax
    movabsq $0x74f839c593dc67fd, %rax
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
    movabsq $0x2, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_11:
    movabsq $0x8, %rax
    pushq %rax
    leaq L_SIP_KAT_MSG(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_SIP_KAT_KEY(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq siphash24
    addq $32, %rsp
    pushq %rax
    movabsq $0x93f5f5799a932462, %rax
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
    movabsq $0x3, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_13:
    movabsq $0xf, %rax
    pushq %rax
    leaq L_SIP_KAT_MSG(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_SIP_KAT_KEY(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq siphash24
    addq $32, %rsp
    pushq %rax
    movabsq $0xa129ca6149be45e5, %rax
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
    movabsq $0x4, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_15:
    movabsq $0x3f, %rax
    pushq %rax
    leaq L_SIP_KAT_MSG(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_SIP_KAT_KEY(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq siphash24
    addq $32, %rsp
    pushq %rax
    movabsq $0x958a324ceb064572, %rax
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
    movabsq $0x5, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_17:
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
