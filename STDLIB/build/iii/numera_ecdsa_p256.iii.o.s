# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "ec256.iiiec256.iiiec256.iiiec256.iiiec256.iiiec256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiidrbg.iiidrbg.iii\0"
L_str_1:
    .ascii "ec256.iiiec256.iiiec256.iiiec256.iiiec256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiidrbg.iiidrbg.iii\0"
L_str_2:
    .ascii "ec256.iiiec256.iiiec256.iiiec256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiidrbg.iiidrbg.iii\0"
L_str_3:
    .ascii "ec256.iiiec256.iiiec256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiidrbg.iiidrbg.iii\0"
L_str_4:
    .ascii "ec256.iiiec256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiidrbg.iiidrbg.iii\0"
L_str_5:
    .ascii "ec256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiidrbg.iiidrbg.iii\0"
L_str_6:
    .ascii "fn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiidrbg.iiidrbg.iii\0"
L_str_7:
    .ascii "fn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiidrbg.iiidrbg.iii\0"
L_str_8:
    .ascii "fn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiidrbg.iiidrbg.iii\0"
L_str_9:
    .ascii "fn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiidrbg.iiidrbg.iii\0"
L_str_10:
    .ascii "fn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiidrbg.iiidrbg.iii\0"
L_str_11:
    .ascii "fn256.iiifn256.iiifn256.iiifn256.iiifn256.iiifn256.iiidrbg.iiidrbg.iii\0"
L_str_12:
    .ascii "fn256.iiifn256.iiifn256.iiifn256.iiifn256.iiidrbg.iiidrbg.iii\0"
L_str_13:
    .ascii "fn256.iiifn256.iiifn256.iiifn256.iiidrbg.iiidrbg.iii\0"
L_str_14:
    .ascii "fn256.iiifn256.iiifn256.iiidrbg.iiidrbg.iii\0"
L_str_15:
    .ascii "fn256.iiifn256.iiidrbg.iiidrbg.iii\0"
L_str_16:
    .ascii "fn256.iiidrbg.iiidrbg.iii\0"
L_str_17:
    .ascii "drbg.iiidrbg.iii\0"
L_str_18:
    .ascii "drbg.iii\0"
    .section .bss
    .global L_ECDSA_RX
L_ECDSA_RX:
    .zero 256
    .global L_ECDSA_U1
L_ECDSA_U1:
    .zero 256
    .global L_ECDSA_U2
L_ECDSA_U2:
    .zero 256
    .global L_ECDSA_D
L_ECDSA_D:
    .zero 256
    .global L_ECDSA_KBUF
L_ECDSA_KBUF:
    .zero 256
    .section .iii.ring3,"n"
    .asciz "iii_ecdsa_p256_keygen"
    .text
    .global iii_ecdsa_p256_keygen
    .seh_proc iii_ecdsa_p256_keygen
iii_ecdsa_p256_keygen:
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
    movabsq $0x1e, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq ec256_scalar_mul_base
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1e, %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x20, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq ec256_affine_xy
    addq $32, %rsp
    movslq %eax, %rax
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
    .asciz "iii_ecdsa_p256_sign"
    .text
    .global iii_ecdsa_p256_sign
    .seh_proc iii_ecdsa_p256_sign
iii_ecdsa_p256_sign:
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
    subq $32, %rsp
    callq fn256_boot
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x1e, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq ec256_scalar_mul_base
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1e, %rax
    pushq %rax
    leaq L_ECDSA_RX(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq ec256_affine_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    leaq L_ECDSA_RX(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fn_set_bytes_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq fn_reduce_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fn_get_bytes_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fn_set_bytes_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq fn_reduce_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fn_set_bytes_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fn_set_bytes_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fn_to_mont_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fn_to_mont_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fn_to_mont_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fn_to_mont_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq fn_mul_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x8, %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq fn_add_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x7, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fn_inv_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x9, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq fn_mul_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xb, %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fn_from_mont_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xc, %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x20, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fn_get_bytes_x
    addq $32, %rsp
    movslq %eax, %rax
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
    .asciz "iii_ecdsa_p256_verify"
    .text
    .global L_iii_ecdsa_p256_verify
    .seh_proc L_iii_ecdsa_p256_verify
L_iii_ecdsa_p256_verify:
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
    subq $32, %rsp
    callq fn256_boot
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fn_set_bytes_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x20, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fn_set_bytes_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq fn_is_zero_x
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
    jz L_if_end_1
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_1:
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq fn_is_zero_x
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
    jz L_if_end_3
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_3:
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fn_set_bytes_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq fn_reduce_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fn_to_mont_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fn_inv_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fn_to_mont_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fn_to_mont_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq fn_mul_x
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
    callq fn_from_mont_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x8, %rax
    pushq %rax
    leaq L_ECDSA_U1(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fn_get_bytes_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq fn_mul_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x7, %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fn_from_mont_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x9, %rax
    pushq %rax
    leaq L_ECDSA_U2(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fn_get_bytes_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    leaq L_ECDSA_U1(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1e, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq ec256_scalar_mul_base
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x21, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq ec256_set_affine
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x21, %rax
    pushq %rax
    leaq L_ECDSA_U2(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x24, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq ec256_scalar_mul_pt
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x24, %rax
    pushq %rax
    movabsq $0x1e, %rax
    pushq %rax
    movabsq $0x27, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq ec256_add_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x27, %rax
    pushq %rax
    leaq L_ECDSA_RX(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq ec256_affine_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    leaq L_ECDSA_RX(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fn_set_bytes_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0xa, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq fn_reduce_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fn_eq_x
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
    jz L_if_end_5
    movabsq $0x1, %rax
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
    .section .iii.ring3,"n"
    .asciz "iii_ecdsa_p256_verify_x"
    .text
    .global iii_ecdsa_p256_verify_x
    .seh_proc iii_ecdsa_p256_verify_x
iii_ecdsa_p256_verify_x:
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
    callq L_iii_ecdsa_p256_verify
    addq $32, %rsp
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
    .asciz "iii_ecdsa_p256_keygen_seed"
    .text
    .global iii_ecdsa_p256_keygen_seed
    .seh_proc iii_ecdsa_p256_keygen_seed
iii_ecdsa_p256_keygen_seed:
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
    subq $32, %rsp
    callq fn256_boot
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fn_set_bytes_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq fn_reduce_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    leaq L_ECDSA_D(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq fn_is_zero_x
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
    jz L_if_else_6
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
L_loop_top_8:
    movq -40(%rbp), %rax
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
    jz L_loop_end_9
    movq -32(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
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
    jmp L_loop_top_8
L_loop_end_9:
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x1f, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_if_end_7
L_if_else_6:
    movabsq $0x0, %rax
    pushq %rax
    leaq L_ECDSA_D(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fn_get_bytes_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_7:
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
L_loop_top_10:
    movq -48(%rbp), %rax
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
    jz L_loop_end_11
    movq -40(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
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
    jmp L_loop_top_10
L_loop_end_11:
    movq -24(%rbp), %rax
    pushq %rax
    leaq L_ECDSA_D(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq iii_ecdsa_p256_keygen
    addq $32, %rsp
    movslq %eax, %rax
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
    .asciz "iii_ecdsa_p256_sign_det"
    .text
    .global iii_ecdsa_p256_sign_det
    .seh_proc iii_ecdsa_p256_sign_det
iii_ecdsa_p256_sign_det:
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
    subq $32, %rsp
    callq fn256_boot
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x20, %rax
    pushq %rax
    movq -16(%rbp), %rax
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
    callq iii_drbg_instantiate
    addq $32, %rsp
    addq $16, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
L_loop_top_12:
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
    jz L_loop_end_13
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x20, %rax
    pushq %rax
    leaq L_ECDSA_KBUF(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq iii_drbg_generate
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    leaq L_ECDSA_KBUF(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fn_set_bytes_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq fn_reduce_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq fn_is_zero_x
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
    jz L_if_end_15
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_15:
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
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x40, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    seta %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_17
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_17:
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_12
L_loop_end_13:
    movabsq $0x0, %rax
    pushq %rax
    leaq L_ECDSA_KBUF(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fn_get_bytes_x
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movq -24(%rbp), %rax
    pushq %rax
    leaq L_ECDSA_KBUF(%rip), %rax
    pushq %rax
    popq %rax
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
    callq iii_ecdsa_p256_sign
    addq $32, %rsp
    movslq %eax, %rax
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
