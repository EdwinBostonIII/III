# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
    .section .bss
    .global L_NIK
L_NIK:
    .zero 512
    .global L_NIMASK
L_NIMASK:
    .zero 32
    .global L_NIH
L_NIH:
    .zero 64
    .global L_NIBUF
L_NIBUF:
    .zero 512
    .section .data
    .global L_NIBUFLEN
L_NIBUFLEN:
    .quad 0x0
    .global L_NIBITS
L_NIBITS:
    .quad 0x0
    .global L_NIINIT
L_NIINIT:
    .quad 0x0
    .section .iii.ring3,"n"
    .asciz "ni_init_k"
    .text
    .seh_proc L_ni_init_k
L_ni_init_k:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x428a2f98, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x71374491, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0xb5c0fbcf, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0xe9b5dba5, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x3956c25b, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x59f111f1, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0x923f82a4, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    movabsq $0xab1c5ed5, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    movabsq $0xd807aa98, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    movabsq $0x12835b01, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    movabsq $0x243185be, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    movabsq $0x550c7dc3, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    movabsq $0x72be5d74, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    movabsq $0x80deb1fe, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0xe, %rax
    pushq %rax
    movabsq $0x9bdc06a7, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0xf, %rax
    pushq %rax
    movabsq $0xc19bf174, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    movabsq $0xe49b69c1, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x11, %rax
    pushq %rax
    movabsq $0xefbe4786, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x12, %rax
    pushq %rax
    movabsq $0xfc19dc6, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x13, %rax
    pushq %rax
    movabsq $0x240ca1cc, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    movabsq $0x2de92c6f, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x15, %rax
    pushq %rax
    movabsq $0x4a7484aa, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x16, %rax
    pushq %rax
    movabsq $0x5cb0a9dc, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x17, %rax
    pushq %rax
    movabsq $0x76f988da, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x18, %rax
    pushq %rax
    movabsq $0x983e5152, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x19, %rax
    pushq %rax
    movabsq $0xa831c66d, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x1a, %rax
    pushq %rax
    movabsq $0xb00327c8, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x1b, %rax
    pushq %rax
    movabsq $0xbf597fc7, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x1c, %rax
    pushq %rax
    movabsq $0xc6e00bf3, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x1d, %rax
    pushq %rax
    movabsq $0xd5a79147, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x1e, %rax
    pushq %rax
    movabsq $0x6ca6351, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x1f, %rax
    pushq %rax
    movabsq $0x14292967, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x20, %rax
    pushq %rax
    movabsq $0x27b70a85, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x21, %rax
    pushq %rax
    movabsq $0x2e1b2138, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x22, %rax
    pushq %rax
    movabsq $0x4d2c6dfc, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x23, %rax
    pushq %rax
    movabsq $0x53380d13, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x24, %rax
    pushq %rax
    movabsq $0x650a7354, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x25, %rax
    pushq %rax
    movabsq $0x766a0abb, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x26, %rax
    pushq %rax
    movabsq $0x81c2c92e, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x27, %rax
    pushq %rax
    movabsq $0x92722c85, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x28, %rax
    pushq %rax
    movabsq $0xa2bfe8a1, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x29, %rax
    pushq %rax
    movabsq $0xa81a664b, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x2a, %rax
    pushq %rax
    movabsq $0xc24b8b70, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x2b, %rax
    pushq %rax
    movabsq $0xc76c51a3, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x2c, %rax
    pushq %rax
    movabsq $0xd192e819, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x2d, %rax
    pushq %rax
    movabsq $0xd6990624, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x2e, %rax
    pushq %rax
    movabsq $0xf40e3585, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x2f, %rax
    pushq %rax
    movabsq $0x106aa070, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x30, %rax
    pushq %rax
    movabsq $0x19a4c116, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x31, %rax
    pushq %rax
    movabsq $0x1e376c08, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x32, %rax
    pushq %rax
    movabsq $0x2748774c, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x33, %rax
    pushq %rax
    movabsq $0x34b0bcb5, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x34, %rax
    pushq %rax
    movabsq $0x391c0cb3, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x35, %rax
    pushq %rax
    movabsq $0x4ed8aa4a, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x36, %rax
    pushq %rax
    movabsq $0x5b9cca4f, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x37, %rax
    pushq %rax
    movabsq $0x682e6ff3, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x38, %rax
    pushq %rax
    movabsq $0x748f82ee, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x39, %rax
    pushq %rax
    movabsq $0x78a5636f, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x3a, %rax
    pushq %rax
    movabsq $0x84c87814, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x3b, %rax
    pushq %rax
    movabsq $0x8cc70208, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x3c, %rax
    pushq %rax
    movabsq $0x90befffa, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x3d, %rax
    pushq %rax
    movabsq $0xa4506ceb, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x3e, %rax
    pushq %rax
    movabsq $0xbef9a3f7, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIK(%rip), %rax
    pushq %rax
    movabsq $0x3f, %rax
    pushq %rax
    movabsq $0xc67178f2, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIMASK(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x10203, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIMASK(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x4050607, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIMASK(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x8090a0b, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIMASK(%rip), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0xc0d0e0f, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
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
    .asciz "_sha_ni_block"
    .text
    .seh_proc L__sha_ni_block
L__sha_ni_block:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue

    /* spill the four Win64 nonvolatile xmm we use (balanced; restored below) */
    subq $64, %rsp
    movdqu %xmm6, 0(%rsp)
    movdqu %xmm7, 16(%rsp)
    movdqu %xmm8, 32(%rsp)
    movdqu %xmm9, 48(%rsp)

    /* --- load state ABCD / EFGH and permute to ABEF / CDGH --- */
    leaq L_NIH(%rip), %rax
    movdqu 0(%rax), %xmm6        /* xmm6 = DCBA (mem order [A,B,C,D]) */
    movdqu 16(%rax), %xmm7       /* xmm7 = HGFE (mem order [E,F,G,H]) */
    pshufd $0xB1, %xmm6, %xmm6   /* CDAB */
    pshufd $0x1B, %xmm7, %xmm7   /* EFGH */
    movdqu %xmm6, %xmm5          /* TMP = CDAB */
    palignr $8, %xmm7, %xmm5     /* TMP = ABEF  (high=CDAB, low=EFGH, >>8) */
    pblendw $0xF0, %xmm6, %xmm7  /* STATE1 = CDGH (blend TMP(CDAB) hi into EFGH) */
    movdqu %xmm5, %xmm6          /* STATE0 = ABEF */

    /* save state for the post-add */
    movdqu %xmm6, %xmm8          /* ABEF_SAVE */
    movdqu %xmm7, %xmm9          /* CDGH_SAVE */

    /* load message base + the byteswap mask source */
    leaq L_NIBUF(%rip), %rax
    leaq L_NIK(%rip), %rcx

    /* --- Rounds 0-3 --- */
    movdqu 0(%rax), %xmm1            /* MSG0 raw */
    movdqu L_NIMASK(%rip), %xmm0     /* mask into reg (movdqu: no align req) */
    pshufb %xmm0, %xmm1             /* MSG0 = big-endian words */
    movdqu 0(%rcx), %xmm0            /* K0..3 */
    paddd %xmm1, %xmm0             /* xmm0 = MSG0 + K0..3 */
    sha256rnds2 %xmm0, %xmm6, %xmm7  /* STATE1 = rnds2(STATE1, STATE0) */
    pshufd $0x0E, %xmm0, %xmm0       /* bring high 2 wk-words down */
    sha256rnds2 %xmm0, %xmm7, %xmm6  /* STATE0 = rnds2(STATE0, STATE1) */

    /* --- Rounds 4-7 --- */
    movdqu 16(%rax), %xmm2
    movdqu L_NIMASK(%rip), %xmm0
    pshufb %xmm0, %xmm2             /* MSG1 */
    movdqu 16(%rcx), %xmm0
    paddd %xmm2, %xmm0
    sha256rnds2 %xmm0, %xmm6, %xmm7
    pshufd $0x0E, %xmm0, %xmm0
    sha256rnds2 %xmm0, %xmm7, %xmm6
    sha256msg1 %xmm2, %xmm1         /* MSG0 = msg1(MSG0, MSG1) */

    /* --- Rounds 8-11 --- */
    movdqu 32(%rax), %xmm3
    movdqu L_NIMASK(%rip), %xmm0
    pshufb %xmm0, %xmm3             /* MSG2 */
    movdqu 32(%rcx), %xmm0
    paddd %xmm3, %xmm0
    sha256rnds2 %xmm0, %xmm6, %xmm7
    pshufd $0x0E, %xmm0, %xmm0
    sha256rnds2 %xmm0, %xmm7, %xmm6
    sha256msg1 %xmm3, %xmm2         /* MSG1 = msg1(MSG1, MSG2) */

    /* --- Rounds 12-15 --- */
    movdqu 48(%rax), %xmm4
    movdqu L_NIMASK(%rip), %xmm0
    pshufb %xmm0, %xmm4             /* MSG3 */
    movdqu 48(%rcx), %xmm0
    paddd %xmm4, %xmm0
    movdqu %xmm4, %xmm5             /* TMP = MSG3 */
    palignr $4, %xmm3, %xmm5        /* TMP = msg3:msg2 >> 4 (4 bytes) */
    paddd %xmm5, %xmm1             /* MSG0 += TMP */
    sha256msg2 %xmm4, %xmm1         /* MSG0 = msg2(MSG0, MSG3) */
    sha256rnds2 %xmm0, %xmm6, %xmm7
    pshufd $0x0E, %xmm0, %xmm0
    sha256rnds2 %xmm0, %xmm7, %xmm6
    sha256msg1 %xmm4, %xmm3         /* MSG2 = msg1(MSG2, MSG3) */

    /* --- Rounds 16-19 --- (MSG0 holds W16..19 schedule) */
    movdqu 64(%rcx), %xmm0
    paddd %xmm1, %xmm0
    movdqu %xmm1, %xmm5
    palignr $4, %xmm4, %xmm5        /* TMP = MSG0:MSG3 >> 4 */
    paddd %xmm5, %xmm2
    sha256msg2 %xmm1, %xmm2         /* MSG1 = msg2(MSG1, MSG0) */
    sha256rnds2 %xmm0, %xmm6, %xmm7
    pshufd $0x0E, %xmm0, %xmm0
    sha256rnds2 %xmm0, %xmm7, %xmm6
    sha256msg1 %xmm1, %xmm4         /* MSG3 = msg1(MSG3, MSG0) */

    /* --- Rounds 20-23 --- */
    movdqu 80(%rcx), %xmm0
    paddd %xmm2, %xmm0
    movdqu %xmm2, %xmm5
    palignr $4, %xmm1, %xmm5
    paddd %xmm5, %xmm3
    sha256msg2 %xmm2, %xmm3
    sha256rnds2 %xmm0, %xmm6, %xmm7
    pshufd $0x0E, %xmm0, %xmm0
    sha256rnds2 %xmm0, %xmm7, %xmm6
    sha256msg1 %xmm2, %xmm1

    /* --- Rounds 24-27 --- */
    movdqu 96(%rcx), %xmm0
    paddd %xmm3, %xmm0
    movdqu %xmm3, %xmm5
    palignr $4, %xmm2, %xmm5
    paddd %xmm5, %xmm4
    sha256msg2 %xmm3, %xmm4
    sha256rnds2 %xmm0, %xmm6, %xmm7
    pshufd $0x0E, %xmm0, %xmm0
    sha256rnds2 %xmm0, %xmm7, %xmm6
    sha256msg1 %xmm3, %xmm2

    /* --- Rounds 28-31 --- */
    movdqu 112(%rcx), %xmm0
    paddd %xmm4, %xmm0
    movdqu %xmm4, %xmm5
    palignr $4, %xmm3, %xmm5
    paddd %xmm5, %xmm1
    sha256msg2 %xmm4, %xmm1
    sha256rnds2 %xmm0, %xmm6, %xmm7
    pshufd $0x0E, %xmm0, %xmm0
    sha256rnds2 %xmm0, %xmm7, %xmm6
    sha256msg1 %xmm4, %xmm3

    /* --- Rounds 32-35 --- */
    movdqu 128(%rcx), %xmm0
    paddd %xmm1, %xmm0
    movdqu %xmm1, %xmm5
    palignr $4, %xmm4, %xmm5
    paddd %xmm5, %xmm2
    sha256msg2 %xmm1, %xmm2
    sha256rnds2 %xmm0, %xmm6, %xmm7
    pshufd $0x0E, %xmm0, %xmm0
    sha256rnds2 %xmm0, %xmm7, %xmm6
    sha256msg1 %xmm1, %xmm4

    /* --- Rounds 36-39 --- */
    movdqu 144(%rcx), %xmm0
    paddd %xmm2, %xmm0
    movdqu %xmm2, %xmm5
    palignr $4, %xmm1, %xmm5
    paddd %xmm5, %xmm3
    sha256msg2 %xmm2, %xmm3
    sha256rnds2 %xmm0, %xmm6, %xmm7
    pshufd $0x0E, %xmm0, %xmm0
    sha256rnds2 %xmm0, %xmm7, %xmm6
    sha256msg1 %xmm2, %xmm1

    /* --- Rounds 40-43 --- */
    movdqu 160(%rcx), %xmm0
    paddd %xmm3, %xmm0
    movdqu %xmm3, %xmm5
    palignr $4, %xmm2, %xmm5
    paddd %xmm5, %xmm4
    sha256msg2 %xmm3, %xmm4
    sha256rnds2 %xmm0, %xmm6, %xmm7
    pshufd $0x0E, %xmm0, %xmm0
    sha256rnds2 %xmm0, %xmm7, %xmm6
    sha256msg1 %xmm3, %xmm2

    /* --- Rounds 44-47 --- */
    movdqu 176(%rcx), %xmm0
    paddd %xmm4, %xmm0
    movdqu %xmm4, %xmm5
    palignr $4, %xmm3, %xmm5
    paddd %xmm5, %xmm1
    sha256msg2 %xmm4, %xmm1
    sha256rnds2 %xmm0, %xmm6, %xmm7
    pshufd $0x0E, %xmm0, %xmm0
    sha256rnds2 %xmm0, %xmm7, %xmm6
    sha256msg1 %xmm4, %xmm3

    /* --- Rounds 48-51 --- */
    movdqu 192(%rcx), %xmm0
    paddd %xmm1, %xmm0
    movdqu %xmm1, %xmm5
    palignr $4, %xmm4, %xmm5
    paddd %xmm5, %xmm2
    sha256msg2 %xmm1, %xmm2
    sha256rnds2 %xmm0, %xmm6, %xmm7
    pshufd $0x0E, %xmm0, %xmm0
    sha256rnds2 %xmm0, %xmm7, %xmm6
    sha256msg1 %xmm1, %xmm4

    /* --- Rounds 52-55 --- */
    movdqu 208(%rcx), %xmm0
    paddd %xmm2, %xmm0
    movdqu %xmm2, %xmm5
    palignr $4, %xmm1, %xmm5
    paddd %xmm5, %xmm3
    sha256msg2 %xmm2, %xmm3
    sha256rnds2 %xmm0, %xmm6, %xmm7
    pshufd $0x0E, %xmm0, %xmm0
    sha256rnds2 %xmm0, %xmm7, %xmm6

    /* --- Rounds 56-59 --- */
    movdqu 224(%rcx), %xmm0
    paddd %xmm3, %xmm0
    movdqu %xmm3, %xmm5
    palignr $4, %xmm2, %xmm5
    paddd %xmm5, %xmm4
    sha256msg2 %xmm3, %xmm4
    sha256rnds2 %xmm0, %xmm6, %xmm7
    pshufd $0x0E, %xmm0, %xmm0
    sha256rnds2 %xmm0, %xmm7, %xmm6

    /* --- Rounds 60-63 --- */
    movdqu 240(%rcx), %xmm0
    paddd %xmm4, %xmm0
    sha256rnds2 %xmm0, %xmm6, %xmm7
    pshufd $0x0E, %xmm0, %xmm0
    sha256rnds2 %xmm0, %xmm7, %xmm6

    /* --- add saved state back --- */
    paddd %xmm8, %xmm6          /* STATE0 += ABEF_SAVE */
    paddd %xmm9, %xmm7          /* STATE1 += CDGH_SAVE */

    /* --- de-permute ABEF/CDGH back to ABCD/EFGH and store --- */
    pshufd $0x1B, %xmm6, %xmm6   /* FEBA */
    pshufd $0xB1, %xmm7, %xmm7   /* DCHG */
    movdqu %xmm6, %xmm5          /* TMP = FEBA */
    pblendw $0xF0, %xmm7, %xmm5  /* TMP = DCBA (ABCD mem order) */
    palignr $8, %xmm6, %xmm7     /* STATE1 = HGFE (EFGH mem order) */
    leaq L_NIH(%rip), %rax
    movdqu %xmm5, 0(%rax)        /* state[0..3] = A B C D */
    movdqu %xmm7, 16(%rax)       /* state[4..7] = E F G H */

    /* restore nonvolatile xmm + unwind the spill */
    movdqu 0(%rsp), %xmm6
    movdqu 16(%rsp), %xmm7
    movdqu 32(%rsp), %xmm8
    movdqu 48(%rsp), %xmm9
    addq $64, %rsp
    
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
    .asciz "sha256_ni_init"
    .text
    .global sha256_ni_init
    .seh_proc sha256_ni_init
sha256_ni_init:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    subq $32, %rsp
    callq L_ni_init_k
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    leaq L_NIH(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x6a09e667, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIH(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0xbb67ae85, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIH(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movabsq $0x3c6ef372, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIH(%rip), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0xa54ff53a, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIH(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    movabsq $0x510e527f, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIH(%rip), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x9b05688c, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIH(%rip), %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0x1f83d9ab, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_NIH(%rip), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    movabsq $0x5be0cd19, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, L_NIBITS(%rip)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movl %eax, L_NIBUFLEN(%rip)
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movb %al, L_NIINIT(%rip)
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
    .asciz "sha256_ni_update"
    .text
    .global sha256_ni_update
    .seh_proc sha256_ni_update
sha256_ni_update:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movzbq L_NIINIT(%rip), %rax
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
    movq L_NIBITS(%rip), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    shlq $3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, L_NIBITS(%rip)
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
L_loop_top_2:
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
    jz L_loop_end_3
    movabsq $0x40, %rax
    pushq %rax
    movl L_NIBUFLEN(%rip), %eax
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
    jz L_if_end_5
    movq -24(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_5:
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
    movl L_NIBUFLEN(%rip), %eax
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
    leaq L_NIBUF(%rip), %rax
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
    jmp L_loop_top_6
L_loop_end_7:
    movl L_NIBUFLEN(%rip), %eax
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
    movl %eax, L_NIBUFLEN(%rip)
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
    movl L_NIBUFLEN(%rip), %eax
    pushq %rax
    movabsq $0x40, %rax
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
    subq $32, %rsp
    callq L__sha_ni_block
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movl %eax, L_NIBUFLEN(%rip)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_9:
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
    .asciz "sha256_ni_final"
    .text
    .global sha256_ni_final
    .seh_proc sha256_ni_final
sha256_ni_final:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movzbq L_NIINIT(%rip), %rax
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
    movq L_NIBITS(%rip), %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    leaq L_NIBUF(%rip), %rax
    pushq %rax
    movl L_NIBUFLEN(%rip), %eax
    pushq %rax
    movabsq $0x80, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movl L_NIBUFLEN(%rip), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movl %eax, L_NIBUFLEN(%rip)
    movl L_NIBUFLEN(%rip), %eax
    pushq %rax
    movabsq $0x38, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    seta %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_13
L_loop_top_14:
    movl L_NIBUFLEN(%rip), %eax
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
    jz L_loop_end_15
    leaq L_NIBUF(%rip), %rax
    pushq %rax
    movl L_NIBUFLEN(%rip), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movl L_NIBUFLEN(%rip), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movl %eax, L_NIBUFLEN(%rip)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_14
L_loop_end_15:
    subq $32, %rsp
    callq L__sha_ni_block
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movl %eax, L_NIBUFLEN(%rip)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_13:
L_loop_top_16:
    movl L_NIBUFLEN(%rip), %eax
    pushq %rax
    movabsq $0x38, %rax
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
    leaq L_NIBUF(%rip), %rax
    pushq %rax
    movl L_NIBUFLEN(%rip), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movl L_NIBUFLEN(%rip), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movl %eax, L_NIBUFLEN(%rip)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_16
L_loop_end_17:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
L_loop_top_18:
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
    jz L_loop_end_19
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
    popq %rax
    movq %rax, -40(%rbp)
    leaq L_NIBUF(%rip), %rax
    pushq %rax
    movl L_NIBUFLEN(%rip), %eax
    pushq %rax
    movzbq -40(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movl L_NIBUFLEN(%rip), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movl %eax, L_NIBUFLEN(%rip)
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
    jmp L_loop_top_18
L_loop_end_19:
    subq $32, %rsp
    callq L__sha_ni_block
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movl %eax, L_NIBUFLEN(%rip)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
L_loop_top_20:
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
    jz L_loop_end_21
    leaq L_NIH(%rip), %rax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movl -32(%rbp), %eax
    pushq %rax
    popq %rax
    shlq $2, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    movl -40(%rbp), %eax
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
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movq -8(%rbp), %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    popq %rax
    shrq $16, %rax
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
    movq -8(%rbp), %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    popq %rax
    shrq $8, %rax
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
    movq -8(%rbp), %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    movl -40(%rbp), %eax
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
    jmp L_loop_top_20
L_loop_end_21:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movb %al, L_NIINIT(%rip)
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
    .asciz "sha256_ni_oneshot"
    .text
    .global sha256_ni_oneshot
    .seh_proc sha256_ni_oneshot
sha256_ni_oneshot:
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
    callq sha256_ni_init
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
    callq sha256_ni_update
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq sha256_ni_final
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
