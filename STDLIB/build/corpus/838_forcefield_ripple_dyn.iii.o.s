# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "msvcrt\0"
L_str_1:
    .ascii "crypt_ed25519.iii\0"
L_str_2:
    .ascii "crypt_ed25519.iii\0"
L_str_3:
    .ascii "ripple.iii\0"
L_str_4:
    .ascii "ripple.iii\0"
L_str_5:
    .ascii "ripple.iii\0"
L_str_6:
    .ascii "ripple_dyn.iii\0"
L_str_7:
    .ascii "ripple_dyn.iii\0"
L_str_8:
    .ascii "ripple_dyn.iii\0"
L_str_9:
    .ascii "ripple_dyn.iii\0"
L_str_10:
    .ascii "ripple_dyn.iii\0"
L_str_11:
    .ascii "ripple_dyn.iii\0"
    .section .iii.ring3,"n"
    .asciz "kfill"
    .text
    .seh_proc L_kfill
L_kfill:
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
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
L_loop_top_0:
    movq -40(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
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
    movq -8(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
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
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_0
L_loop_end_1:
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
    .asciz "keqn"
    .text
    .seh_proc L_keqn
L_keqn:
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
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
L_loop_top_2:
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
    jz L_loop_end_3
    movq -8(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
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
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_5:
    movq -48(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
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
    jmp L_loop_top_2
L_loop_end_3:
    movzbq -56(%rbp), %rax
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
    .asciz "kcopy"
    .text
    .seh_proc L_kcopy
L_kcopy:
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
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
L_loop_top_6:
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
    jz L_loop_end_7
    movq -8(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movq -48(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
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
    jmp L_loop_top_6
L_loop_end_7:
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
    .asciz "ksign"
    .text
    .seh_proc L_ksign
L_ksign:
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
    movq -48(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq dn_build_msg
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movq -56(%rbp), %rax
    pushq %rax
    movabsq $0x48, %rax
    pushq %rax
    movq -48(%rbp), %rax
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
    callq ed25519_sign
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
    movzbq %al, %rax
    pushq %rax
    popq %rax
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
    movabsq $0x20, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq malloc
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movabsq $0x20, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq malloc
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movabsq $0x20, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq malloc
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movabsq $0x48, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq malloc
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x20, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_kfill
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq ed25519_pubkey
    addq $32, %rsp
    movzbq %al, %rax
    pushq %rax
    popq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq dn_key_addr
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x20, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq malloc
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movabsq $0x40, %rax
    pushq %rax
    popq %rax
    shlq $6, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq malloc
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movabsq $0x10000, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq malloc
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movabsq $0x10000, %rax
    pushq %rax
    movabsq $0x40, %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq rn_store_init
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x40, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq malloc
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movabsq $0x20, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq malloc
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movabsq $0x20, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq malloc
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -80(%rbp)
    movabsq $0x20, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq malloc
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
    movabsq $0x7, %rax
    pushq %rax
    movabsq $0x28, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -64(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_kfill
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    movabsq $0x28, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -64(%rbp), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq rn_publish
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x8, %rax
    pushq %rax
    movabsq $0x28, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -64(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_kfill
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -80(%rbp), %rax
    pushq %rax
    movabsq $0x28, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -64(%rbp), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq rn_publish
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x9, %rax
    pushq %rax
    movabsq $0x28, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -64(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_kfill
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -88(%rbp), %rax
    pushq %rax
    movabsq $0x28, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -64(%rbp), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq rn_publish
    addq $32, %rsp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x40, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq malloc
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -96(%rbp)
    movabsq $0x40, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq malloc
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -104(%rbp)
    movabsq $0x40, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq malloc
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -112(%rbp)
    movabsq $0x40, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq malloc
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -120(%rbp)
    subq $8, %rsp
    movq -96(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movq -72(%rbp), %rax
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
    callq L_ksign
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movq -104(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movq -80(%rbp), %rax
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
    callq L_ksign
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movq -112(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movq -88(%rbp), %rax
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
    callq L_ksign
    addq $32, %rsp
    addq $8, %rsp
    addq $24, %rsp
    pushq %rax
    popq %rax
    movabsq $0x20, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq malloc
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -128(%rbp)
    movabsq $0x20, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq malloc
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -136(%rbp)
    movabsq $0x20, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq malloc
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -144(%rbp)
    movabsq $0x20, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq malloc
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -152(%rbp)
    movabsq $0x40, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq malloc
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -160(%rbp)
    movabsq $0x20, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq malloc
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -168(%rbp)
    movabsq $0x10, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq malloc
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -176(%rbp)
    movabsq $0x40, %rax
    pushq %rax
    movabsq $0xc0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq malloc
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -184(%rbp)
    movabsq $0x10, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq malloc
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -192(%rbp)
    movabsq $0x40, %rax
    pushq %rax
    movabsq $0xc0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq malloc
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -200(%rbp)
    movabsq $0x10, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq malloc
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -208(%rbp)
    movabsq $0x40, %rax
    pushq %rax
    movabsq $0xc0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq malloc
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -216(%rbp)
    movabsq $0x10, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq malloc
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -224(%rbp)
    movabsq $0x40, %rax
    pushq %rax
    movabsq $0xc0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq malloc
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -232(%rbp)
    movabsq $0x10, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq malloc
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -240(%rbp)
    movabsq $0x40, %rax
    pushq %rax
    movabsq $0xc0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq malloc
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -248(%rbp)
    movabsq $0x40, %rax
    pushq %rax
    movq -184(%rbp), %rax
    pushq %rax
    movq -176(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq dn_init
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -96(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -184(%rbp), %rax
    pushq %rax
    movq -176(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq dn_apply
    addq $32, %rsp
    addq $16, %rsp
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
    movabsq $0xa, %rax
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
    movq -128(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movq -184(%rbp), %rax
    pushq %rax
    movq -176(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq dn_resolve
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
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
    jz L_if_end_11
    movabsq $0xb, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_11:
    subq $8, %rsp
    movabsq $0x20, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -128(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_keqn
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
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
    jz L_if_end_13
    movabsq $0xc, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_13:
    subq $8, %rsp
    movq -168(%rbp), %rax
    pushq %rax
    movabsq $0x40, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -160(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -128(%rbp), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq rn_resolve
    addq $32, %rsp
    addq $8, %rsp
    addq $40, %rsp
    pushq %rax
    popq %rax
    movq %rax, -256(%rbp)
    movq -256(%rbp), %rax
    pushq %rax
    movabsq $0x28, %rax
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
    movabsq $0xd, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_15:
    movabsq $0x7, %rax
    pushq %rax
    movabsq $0x28, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -64(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_kfill
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x28, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -64(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -160(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_keqn
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
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
    jz L_if_end_17
    movabsq $0xe, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_17:
    movq -104(%rbp), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movq -80(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -184(%rbp), %rax
    pushq %rax
    movq -176(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq dn_apply
    addq $32, %rsp
    addq $16, %rsp
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
    jz L_if_end_19
    movabsq $0xf, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_19:
    subq $8, %rsp
    movq -128(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movq -184(%rbp), %rax
    pushq %rax
    movq -176(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq dn_resolve
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x20, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -80(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -128(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_keqn
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
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
    movabsq $0x10, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_21:
    movq -96(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -184(%rbp), %rax
    pushq %rax
    movq -176(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq dn_apply
    addq $32, %rsp
    addq $16, %rsp
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
    movabsq $0x11, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_23:
    subq $8, %rsp
    movq -128(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movq -184(%rbp), %rax
    pushq %rax
    movq -176(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq dn_resolve
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x20, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -80(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -128(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_keqn
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
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
    jz L_if_end_25
    movabsq $0x12, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_25:
    subq $8, %rsp
    movabsq $0x40, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -112(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -120(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_kcopy
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
    pushq %rax
    popq %rax
    movq -120(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -120(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movq -120(%rbp), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movq -88(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -184(%rbp), %rax
    pushq %rax
    movq -176(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq dn_apply
    addq $32, %rsp
    addq $16, %rsp
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
    jz L_if_end_27
    movabsq $0x13, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_27:
    subq $8, %rsp
    movq -128(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movq -184(%rbp), %rax
    pushq %rax
    movq -176(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq dn_resolve
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x20, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -80(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -128(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_keqn
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
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
    jz L_if_end_29
    movabsq $0x14, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_29:
    movabsq $0x40, %rax
    pushq %rax
    movq -200(%rbp), %rax
    pushq %rax
    movq -192(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq dn_init
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -112(%rbp), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movq -88(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -200(%rbp), %rax
    pushq %rax
    movq -192(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq dn_apply
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq -96(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -200(%rbp), %rax
    pushq %rax
    movq -192(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq dn_apply
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq -104(%rbp), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movq -80(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -200(%rbp), %rax
    pushq %rax
    movq -192(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq dn_apply
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movq -136(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movq -200(%rbp), %rax
    pushq %rax
    movq -192(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq dn_resolve
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
    pushq %rax
    popq %rax
    movabsq $0x40, %rax
    pushq %rax
    movq -216(%rbp), %rax
    pushq %rax
    movq -208(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq dn_init
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -104(%rbp), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movq -80(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -216(%rbp), %rax
    pushq %rax
    movq -208(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq dn_apply
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq -112(%rbp), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movq -88(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -216(%rbp), %rax
    pushq %rax
    movq -208(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq dn_apply
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq -96(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -216(%rbp), %rax
    pushq %rax
    movq -208(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq dn_apply
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movq -144(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movq -216(%rbp), %rax
    pushq %rax
    movq -208(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq dn_resolve
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x20, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -88(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -136(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_keqn
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
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
    jz L_if_end_31
    movabsq $0x15, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_31:
    subq $8, %rsp
    movabsq $0x20, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -144(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -136(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_keqn
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
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
    jz L_if_end_33
    movabsq $0x16, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_33:
    movabsq $0x40, %rax
    pushq %rax
    movq -232(%rbp), %rax
    pushq %rax
    movq -224(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq dn_init
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -96(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -232(%rbp), %rax
    pushq %rax
    movq -224(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq dn_apply
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movabsq $0x40, %rax
    pushq %rax
    movq -248(%rbp), %rax
    pushq %rax
    movq -240(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq dn_init
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -112(%rbp), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movq -88(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -248(%rbp), %rax
    pushq %rax
    movq -240(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq dn_apply
    addq $32, %rsp
    addq $16, %rsp
    pushq %rax
    popq %rax
    movq -248(%rbp), %rax
    pushq %rax
    movq -240(%rbp), %rax
    pushq %rax
    movq -232(%rbp), %rax
    pushq %rax
    movq -224(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq dn_merge
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movq -152(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movq -232(%rbp), %rax
    pushq %rax
    movq -224(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq dn_resolve
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x20, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -88(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -152(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_keqn
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
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
    jz L_if_end_35
    movabsq $0x17, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_35:
    movq -232(%rbp), %rax
    pushq %rax
    movq -224(%rbp), %rax
    pushq %rax
    movq -248(%rbp), %rax
    pushq %rax
    movq -240(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq dn_merge
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movq -152(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movq -248(%rbp), %rax
    pushq %rax
    movq -240(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq dn_resolve
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
    pushq %rax
    popq %rax
    subq $8, %rsp
    movabsq $0x20, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -88(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -152(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_keqn
    addq $32, %rsp
    addq $8, %rsp
    addq $8, %rsp
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
    jz L_if_end_37
    movabsq $0x18, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_37:
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
