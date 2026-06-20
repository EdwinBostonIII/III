# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "cpufeat.iii\0"
L_str_1:
    .ascii "weave_blocks.iii\0"
    .section .rodata
L_SHA512_BLOCK_BYTES:
    .quad 0x80
    .section .bss
    .global L_SHA512_K
L_SHA512_K:
    .zero 640
    .section .data
    .global L_SHA512_K_INIT
L_SHA512_K_INIT:
    .quad 0x0
    .section .bss
    .global L_SHA512_H
L_SHA512_H:
    .zero 64
    .global L_SHA512_W
L_SHA512_W:
    .zero 640
    .global L_SHA512_BUF
L_SHA512_BUF:
    .zero 1024
    .section .data
    .global L_SHA512_BUFLEN
L_SHA512_BUFLEN:
    .quad 0x0
    .global L_SHA512_BITS_LO
L_SHA512_BITS_LO:
    .quad 0x0
    .global L_SHA512_BITS_HI
L_SHA512_BITS_HI:
    .quad 0x0
    .global L_SHA512_INIT
L_SHA512_INIT:
    .quad 0x0
    .section .bss
    .global L_SHA512_PART
L_SHA512_PART:
    .zero 32
    .section .data
    .global L_SHA512_SCHED_T
L_SHA512_SCHED_T:
    .quad 0x0
    .global L_SHA512_FORCE
L_SHA512_FORCE:
    .quad 0x0
    .global L_SHA512_AVX512
L_SHA512_AVX512:
    .quad 0x0
    .section .iii.ring3,"n"
    .asciz "sha512_rotr"
    .text
    .seh_proc L_sha512_rotr
L_sha512_rotr:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movabsq $0x40, %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq wvb_rotl64
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
    .asciz "sha512_init_k"
    .text
    .seh_proc L_sha512_init_k
L_sha512_init_k:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movzbq L_SHA512_K_INIT(%rip), %rax
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
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x428a2f98d728ae22, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x7137449123ef65cd, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xb5c0fbcfec4d3b2f, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0xe9b5dba58189dbbc, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x3956c25bf348b538, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x59f111f1b605d019, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0x923f82a4af194f9b, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    movabsq $0xab1c5ed5da6d8118, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    movabsq $0xd807aa98a3030242, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    movabsq $0x12835b0145706fbe, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0x243185be4ee4b28c, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    movabsq $0x550c7dc3d5ffb4e2, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    movabsq $0x72be5d74f27b896f, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    movabsq $0x80deb1fe3b1696b1, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0xe, %rax
    pushq %rax
    movabsq $0x9bdc06a725c71235, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0xf, %rax
    pushq %rax
    movabsq $0xc19bf174cf692694, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    movabsq $0xe49b69c19ef14ad2, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x11, %rax
    pushq %rax
    movabsq $0xefbe4786384f25e3, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x12, %rax
    pushq %rax
    movabsq $0xfc19dc68b8cd5b5, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x13, %rax
    pushq %rax
    movabsq $0x240ca1cc77ac9c65, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    movabsq $0x2de92c6f592b0275, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x15, %rax
    pushq %rax
    movabsq $0x4a7484aa6ea6e483, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x16, %rax
    pushq %rax
    movabsq $0x5cb0a9dcbd41fbd4, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x17, %rax
    pushq %rax
    movabsq $0x76f988da831153b5, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x18, %rax
    pushq %rax
    movabsq $0x983e5152ee66dfab, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x19, %rax
    pushq %rax
    movabsq $0xa831c66d2db43210, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x1a, %rax
    pushq %rax
    movabsq $0xb00327c898fb213f, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x1b, %rax
    pushq %rax
    movabsq $0xbf597fc7beef0ee4, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x1c, %rax
    pushq %rax
    movabsq $0xc6e00bf33da88fc2, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x1d, %rax
    pushq %rax
    movabsq $0xd5a79147930aa725, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x1e, %rax
    pushq %rax
    movabsq $0x6ca6351e003826f, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x1f, %rax
    pushq %rax
    movabsq $0x142929670a0e6e70, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x20, %rax
    pushq %rax
    movabsq $0x27b70a8546d22ffc, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x21, %rax
    pushq %rax
    movabsq $0x2e1b21385c26c926, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x22, %rax
    pushq %rax
    movabsq $0x4d2c6dfc5ac42aed, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x23, %rax
    pushq %rax
    movabsq $0x53380d139d95b3df, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x24, %rax
    pushq %rax
    movabsq $0x650a73548baf63de, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x25, %rax
    pushq %rax
    movabsq $0x766a0abb3c77b2a8, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x26, %rax
    pushq %rax
    movabsq $0x81c2c92e47edaee6, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x27, %rax
    pushq %rax
    movabsq $0x92722c851482353b, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x28, %rax
    pushq %rax
    movabsq $0xa2bfe8a14cf10364, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x29, %rax
    pushq %rax
    movabsq $0xa81a664bbc423001, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x2a, %rax
    pushq %rax
    movabsq $0xc24b8b70d0f89791, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x2b, %rax
    pushq %rax
    movabsq $0xc76c51a30654be30, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x2c, %rax
    pushq %rax
    movabsq $0xd192e819d6ef5218, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x2d, %rax
    pushq %rax
    movabsq $0xd69906245565a910, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x2e, %rax
    pushq %rax
    movabsq $0xf40e35855771202a, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x2f, %rax
    pushq %rax
    movabsq $0x106aa07032bbd1b8, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x30, %rax
    pushq %rax
    movabsq $0x19a4c116b8d2d0c8, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x31, %rax
    pushq %rax
    movabsq $0x1e376c085141ab53, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x32, %rax
    pushq %rax
    movabsq $0x2748774cdf8eeb99, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x33, %rax
    pushq %rax
    movabsq $0x34b0bcb5e19b48a8, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x34, %rax
    pushq %rax
    movabsq $0x391c0cb3c5c95a63, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x35, %rax
    pushq %rax
    movabsq $0x4ed8aa4ae3418acb, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x36, %rax
    pushq %rax
    movabsq $0x5b9cca4f7763e373, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x37, %rax
    pushq %rax
    movabsq $0x682e6ff3d6b2b8a3, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x38, %rax
    pushq %rax
    movabsq $0x748f82ee5defb2fc, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x39, %rax
    pushq %rax
    movabsq $0x78a5636f43172f60, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x3a, %rax
    pushq %rax
    movabsq $0x84c87814a1f0ab72, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x3b, %rax
    pushq %rax
    movabsq $0x8cc702081a6439ec, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x3c, %rax
    pushq %rax
    movabsq $0x90befffa23631e28, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x3d, %rax
    pushq %rax
    movabsq $0xa4506cebde82bde9, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x3e, %rax
    pushq %rax
    movabsq $0xbef9a3f7b2c67915, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x3f, %rax
    pushq %rax
    movabsq $0xc67178f2e372532b, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x40, %rax
    pushq %rax
    movabsq $0xca273eceea26619c, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x41, %rax
    pushq %rax
    movabsq $0xd186b8c721c0c207, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x42, %rax
    pushq %rax
    movabsq $0xeada7dd6cde0eb1e, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x43, %rax
    pushq %rax
    movabsq $0xf57d4f7fee6ed178, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x44, %rax
    pushq %rax
    movabsq $0x6f067aa72176fba, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x45, %rax
    pushq %rax
    movabsq $0xa637dc5a2c898a6, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x46, %rax
    pushq %rax
    movabsq $0x113f9804bef90dae, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x47, %rax
    pushq %rax
    movabsq $0x1b710b35131c471b, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x48, %rax
    pushq %rax
    movabsq $0x28db77f523047d84, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x49, %rax
    pushq %rax
    movabsq $0x32caab7b40c72493, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x4a, %rax
    pushq %rax
    movabsq $0x3c9ebe0a15c9bebc, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x4b, %rax
    pushq %rax
    movabsq $0x431d67c49c100d4c, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x4c, %rax
    pushq %rax
    movabsq $0x4cc5d4becb3e42b6, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x4d, %rax
    pushq %rax
    movabsq $0x597f299cfc657e2a, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x4e, %rax
    pushq %rax
    movabsq $0x5fcb6fab3ad6faec, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movabsq $0x4f, %rax
    pushq %rax
    movabsq $0x6c44198c4a475817, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movb %al, L_SHA512_K_INIT(%rip)
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
    .asciz "_sha512_sched4_scalar"
    .text
    .seh_proc L__sha512_sched4_scalar
L__sha512_sched4_scalar:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movl L_SHA512_SCHED_T(%rip), %eax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
L_loop_top_2:
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x4, %rax
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
    leaq L_SHA512_W(%rip), %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    movabsq $0xf, %rax
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
    movq %rax, -24(%rbp)
    movabsq $0x1, %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_sha512_rotr
    addq $32, %rsp
    pushq %rax
    subq $8, %rsp
    movabsq $0x8, %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_sha512_rotr
    addq $32, %rsp
    addq $8, %rsp
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rax
    shrq $7, %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    leaq L_SHA512_W(%rip), %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    movabsq $0x10, %rax
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
    movq %rax, -40(%rbp)
    leaq L_SHA512_W(%rip), %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    movabsq $0x7, %rax
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
    movq %rax, -48(%rbp)
    leaq L_SHA512_PART(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
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
    jmp L_loop_top_2
L_loop_end_3:
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
    .asciz "_sha512_sched4_avx512"
    .text
    .seh_proc L__sha512_sched4_avx512
L__sha512_sched4_avx512:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue

    leaq L_SHA512_W(%rip), %rax
    leaq L_SHA512_SCHED_T(%rip), %rcx
    movl (%rcx), %ecx
    movl %ecx, %edx
    shll $3, %edx
    addq %rdx, %rax
    vmovdqu -128(%rax), %ymm0
    vmovdqu -120(%rax), %ymm1
    vmovdqu -56(%rax), %ymm2
    vprolq $63, %ymm1, %ymm3
    vprolq $56, %ymm1, %ymm4
    vpxorq %ymm4, %ymm3, %ymm3
    vpsrlq $7, %ymm1, %ymm4
    vpxorq %ymm4, %ymm3, %ymm3
    vpaddq %ymm0, %ymm3, %ymm3
    vpaddq %ymm2, %ymm3, %ymm3
    leaq L_SHA512_PART(%rip), %rdx
    vmovdqu %ymm3, (%rdx)
    vzeroupper
    
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
    .asciz "_sha512_avx512_ok"
    .text
    .seh_proc L__sha512_avx512_ok
L__sha512_avx512_ok:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movl L_SHA512_AVX512(%rip), %eax
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
    jz L_if_end_5
    subq $32, %rsp
    callq cpufeat_has_avx512f
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
    movabsq $0x2, %rax
    pushq %rax
    popq %rax
    movl %eax, L_SHA512_AVX512(%rip)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_if_end_7
L_if_else_6:
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movl %eax, L_SHA512_AVX512(%rip)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_7:
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_5:
    movl L_SHA512_AVX512(%rip), %eax
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
    .asciz "_sha512_sched4"
    .text
    .seh_proc L__sha512_sched4
L__sha512_sched4:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movl L_SHA512_FORCE(%rip), %eax
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
    jz L_if_end_11
    subq $32, %rsp
    callq L__sha512_sched4_scalar
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
L_if_end_11:
    movl L_SHA512_FORCE(%rip), %eax
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
    jz L_if_end_13
    subq $32, %rsp
    callq L__sha512_sched4_avx512
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
L_if_end_13:
    subq $32, %rsp
    callq L__sha512_avx512_ok
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
    jz L_if_end_15
    subq $32, %rsp
    callq L__sha512_sched4_avx512
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
L_if_end_15:
    subq $32, %rsp
    callq L__sha512_sched4_scalar
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
    .asciz "sha512_sched_force"
    .text
    .global sha512_sched_force
    .seh_proc sha512_sched_force
sha512_sched_force:
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
    movl %eax, L_SHA512_FORCE(%rip)
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
    .asciz "sha512_block"
    .text
    .seh_proc L_sha512_block
L_sha512_block:
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
L_loop_top_16:
    movl -8(%rbp), %eax
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
    jz L_loop_end_17
    movl -8(%rbp), %eax
    pushq %rax
    popq %rax
    shlq $3, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    leaq L_SHA512_BUF(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    leaq L_SHA512_BUF(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    leaq L_SHA512_BUF(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    leaq L_SHA512_BUF(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    leaq L_SHA512_BUF(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    leaq L_SHA512_BUF(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    leaq L_SHA512_BUF(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    leaq L_SHA512_BUF(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -80(%rbp)
    leaq L_SHA512_W(%rip), %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rax
    shlq $56, %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rax
    shlq $48, %rax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rax
    shlq $40, %rax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rax
    shlq $32, %rax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    popq %rax
    shlq $24, %rax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    movq -64(%rbp), %rax
    pushq %rax
    popq %rax
    shlq $16, %rax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    popq %rax
    shlq $8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    movq -80(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
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
    jmp L_loop_top_16
L_loop_end_17:
    movabsq $0x10, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
L_loop_top_18:
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x50, %rax
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
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    movl %eax, L_SHA512_SCHED_T(%rip)
    subq $32, %rsp
    callq L__sha512_sched4
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
L_loop_top_20:
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_21
    leaq L_SHA512_W(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    movabsq $0x2, %rax
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
    movq %rax, -32(%rbp)
    movabsq $0x13, %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_sha512_rotr
    addq $32, %rsp
    pushq %rax
    subq $8, %rsp
    movabsq $0x3d, %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_sha512_rotr
    addq $32, %rsp
    addq $8, %rsp
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rax
    shrq $6, %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    leaq L_SHA512_W(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    leaq L_SHA512_PART(%rip), %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
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
    jmp L_loop_top_20
L_loop_end_21:
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x4, %rax
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
    leaq L_SHA512_H(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    leaq L_SHA512_H(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    leaq L_SHA512_H(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    leaq L_SHA512_H(%rip), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    leaq L_SHA512_H(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    leaq L_SHA512_H(%rip), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    leaq L_SHA512_H(%rip), %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    leaq L_SHA512_H(%rip), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -80(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
L_loop_top_22:
    movl -88(%rbp), %eax
    pushq %rax
    movabsq $0x50, %rax
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
    movabsq $0xe, %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_sha512_rotr
    addq $32, %rsp
    pushq %rax
    subq $8, %rsp
    movabsq $0x12, %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_sha512_rotr
    addq $32, %rsp
    addq $8, %rsp
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    subq $8, %rsp
    movabsq $0x29, %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_sha512_rotr
    addq $32, %rsp
    addq $8, %rsp
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -96(%rbp)
    movq -56(%rbp), %rax
    pushq %rax
    movq -64(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    popq %rax
    notq %rax
    pushq %rax
    movq -72(%rbp), %rax
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
    movq %rax, -104(%rbp)
    movq -80(%rbp), %rax
    pushq %rax
    movq -96(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    movq -104(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    leaq L_SHA512_K(%rip), %rax
    pushq %rax
    movl -88(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    leaq L_SHA512_W(%rip), %rax
    pushq %rax
    movl -88(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -112(%rbp)
    movabsq $0x1c, %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_sha512_rotr
    addq $32, %rsp
    pushq %rax
    subq $8, %rsp
    movabsq $0x22, %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_sha512_rotr
    addq $32, %rsp
    addq $8, %rsp
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    subq $8, %rsp
    movabsq $0x27, %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_sha512_rotr
    addq $32, %rsp
    addq $8, %rsp
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -120(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
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
    movq %rax, -128(%rbp)
    movq -120(%rbp), %rax
    pushq %rax
    movq -128(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -136(%rbp)
    movq -72(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -80(%rbp)
    movq -64(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movq -56(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movq -48(%rbp), %rax
    pushq %rax
    movq -112(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq -40(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq -32(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq -112(%rbp), %rax
    pushq %rax
    movq -136(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
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
    jmp L_loop_top_22
L_loop_end_23:
    leaq L_SHA512_H(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    leaq L_SHA512_H(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_H(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    leaq L_SHA512_H(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_H(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    leaq L_SHA512_H(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_H(%rip), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    leaq L_SHA512_H(%rip), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_H(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    leaq L_SHA512_H(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_H(%rip), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_SHA512_H(%rip), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movq -64(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_H(%rip), %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    leaq L_SHA512_H(%rip), %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_H(%rip), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    leaq L_SHA512_H(%rip), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movq -80(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
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
    .asciz "sha512_init"
    .text
    .global sha512_init
    .seh_proc sha512_init
sha512_init:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    subq $32, %rsp
    callq L_sha512_init_k
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    leaq L_SHA512_H(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x6a09e667f3bcc908, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_H(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xbb67ae8584caa73b, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_H(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x3c6ef372fe94f82b, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_H(%rip), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0xa54ff53a5f1d36f1, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_H(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x510e527fade682d1, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_H(%rip), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x9b05688c2b3e6c1f, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_H(%rip), %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0x1f83d9abfb41bd6b, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_SHA512_H(%rip), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    movabsq $0x5be0cd19137e2179, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, L_SHA512_BITS_LO(%rip)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, L_SHA512_BITS_HI(%rip)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movl %eax, L_SHA512_BUFLEN(%rip)
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movb %al, L_SHA512_INIT(%rip)
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
    .asciz "sha512_bits_add"
    .text
    .seh_proc L_sha512_bits_add
L_sha512_bits_add:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq L_SHA512_BITS_LO(%rip), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    movq L_SHA512_BITS_LO(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_25
    movq L_SHA512_BITS_HI(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, L_SHA512_BITS_HI(%rip)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_25:
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, L_SHA512_BITS_LO(%rip)
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
    .asciz "sha512_update"
    .text
    .global sha512_update
    .seh_proc sha512_update
sha512_update:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movzbq L_SHA512_INIT(%rip), %rax
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
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    shlq $3, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_sha512_bits_add
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
L_loop_top_28:
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    seta %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_29
    movabsq $0x80, %rax
    pushq %rax
    movl L_SHA512_BUFLEN(%rip), %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq -40(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    seta %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_31
    movq -24(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_31:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
L_loop_top_32:
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
    jz L_loop_end_33
    movl L_SHA512_BUFLEN(%rip), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    leaq L_SHA512_BUF(%rip), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    movq -8(%rbp), %rax
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
    jmp L_loop_top_32
L_loop_end_33:
    movl L_SHA512_BUFLEN(%rip), %eax
    pushq %rax
    movq -40(%rbp), %rax
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
    movl %eax, L_SHA512_BUFLEN(%rip)
    movq -32(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movl L_SHA512_BUFLEN(%rip), %eax
    pushq %rax
    movabsq $0x80, %rax
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
    subq $32, %rsp
    callq L_sha512_block
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movl %eax, L_SHA512_BUFLEN(%rip)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_35:
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_28
L_loop_end_29:
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
    .asciz "sha512_update_byte"
    .text
    .global sha512_update_byte
    .seh_proc sha512_update_byte
sha512_update_byte:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movzbq L_SHA512_INIT(%rip), %rax
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
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_sha512_bits_add
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    leaq L_SHA512_BUF(%rip), %rax
    pushq %rax
    movl L_SHA512_BUFLEN(%rip), %eax
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
    movl L_SHA512_BUFLEN(%rip), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movl %eax, L_SHA512_BUFLEN(%rip)
    movl L_SHA512_BUFLEN(%rip), %eax
    pushq %rax
    movabsq $0x80, %rax
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
    subq $32, %rsp
    callq L_sha512_block
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movl %eax, L_SHA512_BUFLEN(%rip)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_39:
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
    .asciz "sha512_finalize_internal"
    .text
    .global sha512_finalize_internal
    .seh_proc sha512_finalize_internal
sha512_finalize_internal:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movzbq L_SHA512_INIT(%rip), %rax
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
    movq L_SHA512_BITS_LO(%rip), %rax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq L_SHA512_BITS_HI(%rip), %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    leaq L_SHA512_BUF(%rip), %rax
    pushq %rax
    movl L_SHA512_BUFLEN(%rip), %eax
    pushq %rax
    movabsq $0x80, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movl L_SHA512_BUFLEN(%rip), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movl %eax, L_SHA512_BUFLEN(%rip)
    movl L_SHA512_BUFLEN(%rip), %eax
    pushq %rax
    movabsq $0x70, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    seta %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_43
L_loop_top_44:
    movl L_SHA512_BUFLEN(%rip), %eax
    pushq %rax
    movabsq $0x80, %rax
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
    leaq L_SHA512_BUF(%rip), %rax
    pushq %rax
    movl L_SHA512_BUFLEN(%rip), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movl L_SHA512_BUFLEN(%rip), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movl %eax, L_SHA512_BUFLEN(%rip)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_44
L_loop_end_45:
    subq $32, %rsp
    callq L_sha512_block
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movl %eax, L_SHA512_BUFLEN(%rip)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_43:
L_loop_top_46:
    movl L_SHA512_BUFLEN(%rip), %eax
    pushq %rax
    movabsq $0x70, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_47
    leaq L_SHA512_BUF(%rip), %rax
    pushq %rax
    movl L_SHA512_BUFLEN(%rip), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movl L_SHA512_BUFLEN(%rip), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movl %eax, L_SHA512_BUFLEN(%rip)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_46
L_loop_end_47:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
L_loop_top_48:
    movl -24(%rbp), %eax
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
    jz L_loop_end_49
    movabsq $0x38, %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    popq %rax
    shlq $3, %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    leaq L_SHA512_BUF(%rip), %rax
    pushq %rax
    movl L_SHA512_BUFLEN(%rip), %eax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    popq %rax
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
    movl L_SHA512_BUFLEN(%rip), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movl %eax, L_SHA512_BUFLEN(%rip)
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
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
L_loop_top_50:
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
    jz L_loop_end_51
    movabsq $0x38, %rax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    popq %rax
    shlq $3, %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    leaq L_SHA512_BUF(%rip), %rax
    pushq %rax
    movl L_SHA512_BUFLEN(%rip), %eax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    popq %rax
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
    movl L_SHA512_BUFLEN(%rip), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movl %eax, L_SHA512_BUFLEN(%rip)
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
    jmp L_loop_top_50
L_loop_end_51:
    subq $32, %rsp
    callq L_sha512_block
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movl %eax, L_SHA512_BUFLEN(%rip)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movb %al, L_SHA512_INIT(%rip)
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
    .asciz "sha512_final"
    .text
    .global sha512_final
    .seh_proc sha512_final
sha512_final:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    subq $32, %rsp
    callq sha512_finalize_internal
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
    jz L_if_end_53
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_53:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
L_loop_top_54:
    movl -16(%rbp), %eax
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
    jz L_loop_end_55
    leaq L_SHA512_H(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    shlq $3, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
L_loop_top_56:
    movl -40(%rbp), %eax
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
    jz L_loop_end_57
    movabsq $0x38, %rax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    popq %rax
    shlq $3, %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
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
    jmp L_loop_top_56
L_loop_end_57:
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
    jmp L_loop_top_54
L_loop_end_55:
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
    .asciz "sha512_oneshot"
    .text
    .global sha512_oneshot
    .seh_proc sha512_oneshot
sha512_oneshot:
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
    callq sha512_init
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq sha512_update
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq sha512_final
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
    .asciz "sha512_digest_byte"
    .text
    .global sha512_digest_byte
    .seh_proc sha512_digest_byte
sha512_digest_byte:
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
    movabsq $0x40, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_59
    movabsq $0x100, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_59:
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorl %edx, %edx
    divq %rcx
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    leaq L_SHA512_H(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movabsq $0x7, %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    popq %rax
    shlq $3, %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq -32(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
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
