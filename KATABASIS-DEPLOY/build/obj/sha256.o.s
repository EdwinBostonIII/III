# III Stage-0 Ring-0 codegen output (Windows kernel-mode .sys)
# Output binary: iiis-0.sys
    .att_syntax
    .section .rdata,"dr"
L_str_0:
    .ascii "cpufeat.iii\0"
L_str_1:
    .ascii "weave_blocks.iii\0"
L_str_2:
    .ascii "weave_blocks.iii\0"
L_str_3:
    .ascii "weave_blocks.iii\0"
    .section .bss
    .global L_p_SHA_K
L_p_SHA_K:
    .zero 512
    .global L_p_SHA_H
L_p_SHA_H:
    .zero 64
    .global L_p_SHA_W
L_p_SHA_W:
    .zero 512
    .global L_p_SHA_BUF
L_p_SHA_BUF:
    .zero 512
    .section .data
    .global L_p_SHA_BUFLEN
L_p_SHA_BUFLEN:
    .quad 0x0
    .global L_p_SHA_BITS
L_p_SHA_BITS:
    .quad 0x0
    .global L_p_SHA_INIT
L_p_SHA_INIT:
    .quad 0x0
    .section .bss
    .global L_p_SHA_PART
L_p_SHA_PART:
    .zero 32
    .section .data
    .global L_p_SHA_SCHED_T
L_p_SHA_SCHED_T:
    .quad 0x0
    .global L_p_SHA_FORCE
L_p_SHA_FORCE:
    .quad 0x0
    .section .text,"xr"  /* PE/COFF Â§6 */
    /* IRQL_REQUIRES_MAX(2) */
    .global L_p_sha_init_k
L_p_sha_init_k:
    .seh_proc L_p_sha_init_k
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    /* witness enter (D9, ADR-024) */
    movq $1, %rcx  /* IIIW_ENTER */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    movabsq $0x428a2f98, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x71374491, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0xb5c0fbcf, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0xe9b5dba5, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x3956c25b, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x59f111f1, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x923f82a4, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0xab1c5ed5, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0xd807aa98, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x12835b01, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x243185be, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x550c7dc3, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x72be5d74, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x80deb1fe, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x9bdc06a7, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0xe, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0xc19bf174, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0xf, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0xe49b69c1, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0xefbe4786, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x11, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0xfc19dc6, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x12, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x240ca1cc, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x13, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x2de92c6f, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x4a7484aa, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x15, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x5cb0a9dc, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x16, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x76f988da, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x17, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x983e5152, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x18, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0xa831c66d, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x19, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0xb00327c8, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x1a, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0xbf597fc7, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x1b, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0xc6e00bf3, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x1c, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0xd5a79147, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x1d, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x6ca6351, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x1e, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x14292967, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x1f, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x27b70a85, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x20, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x2e1b2138, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x21, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x4d2c6dfc, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x22, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x53380d13, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x23, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x650a7354, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x24, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x766a0abb, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x25, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x81c2c92e, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x26, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x92722c85, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x27, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0xa2bfe8a1, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x28, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0xa81a664b, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x29, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0xc24b8b70, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x2a, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0xc76c51a3, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x2b, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0xd192e819, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x2c, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0xd6990624, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x2d, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0xf40e3585, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x2e, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x106aa070, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x2f, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x19a4c116, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x30, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x1e376c08, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x31, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x2748774c, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x32, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x34b0bcb5, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x33, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x391c0cb3, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x34, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x4ed8aa4a, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x35, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x5b9cca4f, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x36, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x682e6ff3, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x37, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x748f82ee, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x38, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x78a5636f, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x39, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x84c87814, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x3a, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x8cc70208, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x3b, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x90befffa, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x3c, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0xa4506ceb, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x3d, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0xbef9a3f7, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x3e, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0xc67178f2, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movabsq $0x3f, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    pushq %rax
    pushq %rax
    movq $2, %rcx  /* IIIW_EXIT */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    popq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .text,"xr"  /* PE/COFF Â§6 */
    /* IRQL_REQUIRES_MAX(2) */
    .global L_p_sha_rotr
L_p_sha_rotr:
    .seh_proc L_p_sha_rotr
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    /* witness enter (D9, ADR-024) */
    movq $1, %rcx  /* IIIW_ENTER */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0x20, %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_wvb_rotl32
    addq $32, %rsp
    pushq %rax
    popq %rax
    pushq %rax
    pushq %rax
    movq $2, %rcx  /* IIIW_EXIT */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    popq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .text,"xr"  /* PE/COFF Â§6 */
    /* IRQL_REQUIRES_MAX(2) */
    .global L_p__sha_sched4_scalar
L_p__sha_sched4_scalar:
    .seh_proc L_p__sha_sched4_scalar
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    /* witness enter (D9, ADR-024) */
    movq $1, %rcx  /* IIIW_ENTER */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    movq L_p_SHA_SCHED_T(%rip), %rax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
L_for_top_0:
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setl %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_for_end_1
    leaq L_p_SHA_W(%rip), %rax
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
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_sha_rotr
    addq $32, %rsp
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x12, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_sha_rotr
    addq $32, %rsp
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    shrq %cl, %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    leaq L_p_SHA_W(%rip), %rax
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
    leaq L_p_SHA_W(%rip), %rax
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
    movl -40(%rbp), %eax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_PART(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
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
    jmp L_for_top_0
L_for_end_1:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    pushq %rax
    pushq %rax
    movq $2, %rcx  /* IIIW_EXIT */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    popq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .text,"xr"  /* PE/COFF Â§6 */
    /* IRQL_REQUIRES_MAX(2) */
    .global L_p__sha_sched4_avx512
L_p__sha_sched4_avx512:
    .seh_proc L_p__sha_sched4_avx512
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    /* witness enter (D9, ADR-024) */
    movq $1, %rcx  /* IIIW_ENTER */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp

    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    pushq %rax
    pushq %rax
    movq $2, %rcx  /* IIIW_EXIT */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    popq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .text,"xr"  /* PE/COFF Â§6 */
    /* IRQL_REQUIRES_MAX(2) */
    .global L_p__sha_sched4
L_p__sha_sched4:
    .seh_proc L_p__sha_sched4
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    /* witness enter (D9, ADR-024) */
    movq $1, %rcx  /* IIIW_ENTER */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    movq L_p_SHA_FORCE(%rip), %rax
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
    subq $32, %rsp
    callq L_p__sha_sched4_scalar
    addq $32, %rsp
    pushq %rax
    popq %rax
    pushq %rax
    pushq %rax
    movq $2, %rcx  /* IIIW_EXIT */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    popq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
L_if_end_3:
    movq L_p_SHA_FORCE(%rip), %rax
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
    jz L_if_end_5
    subq $32, %rsp
    callq L_p__sha_sched4_avx512
    addq $32, %rsp
    pushq %rax
    popq %rax
    pushq %rax
    pushq %rax
    movq $2, %rcx  /* IIIW_EXIT */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    popq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
L_if_end_5:
    subq $32, %rsp
    callq L_p_cpufeat_has_avx512f
    addq $32, %rsp
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
    jz L_if_end_7
    subq $32, %rsp
    callq L_p__sha_sched4_avx512
    addq $32, %rsp
    pushq %rax
    popq %rax
    pushq %rax
    pushq %rax
    movq $2, %rcx  /* IIIW_EXIT */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    popq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
L_if_end_7:
    subq $32, %rsp
    callq L_p__sha_sched4_scalar
    addq $32, %rsp
    pushq %rax
    popq %rax
    pushq %rax
    pushq %rax
    movq $2, %rcx  /* IIIW_EXIT */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    popq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .text,"xr"  /* PE/COFF Â§6 */
    /* IRQL_REQUIRES_MAX(2) */
    .global L_p_sha256_sched_force
L_p_sha256_sched_force:
    .seh_proc L_p_sha256_sched_force
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    /* witness enter (D9, ADR-024) */
    movq $1, %rcx  /* IIIW_ENTER */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    movl -8(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, L_p_SHA_FORCE(%rip)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    pushq %rax
    pushq %rax
    movq $2, %rcx  /* IIIW_EXIT */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    popq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .text,"xr"  /* PE/COFF Â§6 */
    /* IRQL_REQUIRES_MAX(2) */
    .global L_p_sha_block
L_p_sha_block:
    .seh_proc L_p_sha_block
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    /* witness enter (D9, ADR-024) */
    movq $1, %rcx  /* IIIW_ENTER */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
L_for_top_8:
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setl %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_for_end_9
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    leaq L_p_SHA_BUF(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    leaq L_p_SHA_BUF(%rip), %rax
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
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    leaq L_p_SHA_BUF(%rip), %rax
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
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    leaq L_p_SHA_BUF(%rip), %rax
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
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x18, %rax
    pushq %rax
    popq %rcx
    popq %rax
    shlq %cl, %rax
    movl %eax, %eax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    popq %rcx
    popq %rax
    shlq %cl, %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    shlq %cl, %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_W(%rip), %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
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
    jmp L_for_top_8
L_for_end_9:
    movabsq $0x10, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
L_for_top_10:
    movl -56(%rbp), %eax
    pushq %rax
    movabsq $0x40, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setl %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_for_end_11
    movl -56(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, L_p_SHA_SCHED_T(%rip)
    subq $32, %rsp
    callq L_p__sha_sched4
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
L_for_top_12:
    movl -64(%rbp), %eax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setl %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_for_end_13
    leaq L_p_SHA_W(%rip), %rax
    pushq %rax
    movl -56(%rbp), %eax
    pushq %rax
    movl -64(%rbp), %eax
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
    movq %rax, -72(%rbp)
    movl -72(%rbp), %eax
    pushq %rax
    movabsq $0x11, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_sha_rotr
    addq $32, %rsp
    pushq %rax
    movl -72(%rbp), %eax
    pushq %rax
    movabsq $0x13, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_sha_rotr
    addq $32, %rsp
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    movl -72(%rbp), %eax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    popq %rcx
    popq %rax
    shrq %cl, %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -80(%rbp)
    leaq L_p_SHA_PART(%rip), %rax
    pushq %rax
    movl -64(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movl -80(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_W(%rip), %rax
    pushq %rax
    movl -56(%rbp), %eax
    pushq %rax
    movl -64(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
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
    jmp L_for_top_12
L_for_end_13:
    movl -56(%rbp), %eax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    jmp L_for_top_10
L_for_end_11:
    leaq L_p_SHA_H(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
    leaq L_p_SHA_H(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -96(%rbp)
    leaq L_p_SHA_H(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -104(%rbp)
    leaq L_p_SHA_H(%rip), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -112(%rbp)
    leaq L_p_SHA_H(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -120(%rbp)
    leaq L_p_SHA_H(%rip), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -128(%rbp)
    leaq L_p_SHA_H(%rip), %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -136(%rbp)
    leaq L_p_SHA_H(%rip), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -144(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -152(%rbp)
L_for_top_14:
    movl -152(%rbp), %eax
    pushq %rax
    movabsq $0x40, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setl %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_for_end_15
    movl -120(%rbp), %eax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_sha_rotr
    addq $32, %rsp
    pushq %rax
    movl -120(%rbp), %eax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_sha_rotr
    addq $32, %rsp
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    movl -120(%rbp), %eax
    pushq %rax
    movabsq $0x19, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_sha_rotr
    addq $32, %rsp
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -160(%rbp)
    movl -120(%rbp), %eax
    pushq %rax
    movl -128(%rbp), %eax
    pushq %rax
    movl -136(%rbp), %eax
    pushq %rax
    popq %r8
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_wvb_ch32
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -168(%rbp)
    leaq L_p_SHA_K(%rip), %rax
    pushq %rax
    movl -152(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -176(%rbp)
    leaq L_p_SHA_W(%rip), %rax
    pushq %rax
    movl -152(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -184(%rbp)
    movl -144(%rbp), %eax
    pushq %rax
    movl -160(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    movl -168(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    movl -176(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    movl -184(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -192(%rbp)
    movl -88(%rbp), %eax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_sha_rotr
    addq $32, %rsp
    pushq %rax
    movl -88(%rbp), %eax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_sha_rotr
    addq $32, %rsp
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    movl -88(%rbp), %eax
    pushq %rax
    movabsq $0x16, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_sha_rotr
    addq $32, %rsp
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -200(%rbp)
    movl -88(%rbp), %eax
    pushq %rax
    movl -96(%rbp), %eax
    pushq %rax
    movl -104(%rbp), %eax
    pushq %rax
    popq %r8
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_wvb_maj32
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -208(%rbp)
    movl -200(%rbp), %eax
    pushq %rax
    movl -208(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -216(%rbp)
    movl -136(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -144(%rbp)
    movl -128(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -136(%rbp)
    movl -120(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -128(%rbp)
    movl -112(%rbp), %eax
    pushq %rax
    movl -192(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -120(%rbp)
    movl -104(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -112(%rbp)
    movl -96(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -104(%rbp)
    movl -88(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -96(%rbp)
    movl -192(%rbp), %eax
    pushq %rax
    movl -216(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
    movl -152(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -152(%rbp)
    jmp L_for_top_14
L_for_end_15:
    leaq L_p_SHA_H(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movl -88(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_H(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    leaq L_p_SHA_H(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movl -96(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_H(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    leaq L_p_SHA_H(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movl -104(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_H(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    leaq L_p_SHA_H(%rip), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movl -112(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_H(%rip), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    leaq L_p_SHA_H(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movl -120(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_H(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    leaq L_p_SHA_H(%rip), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movl -128(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_H(%rip), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    leaq L_p_SHA_H(%rip), %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movl -136(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_H(%rip), %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    leaq L_p_SHA_H(%rip), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movl -144(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_H(%rip), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    pushq %rax
    pushq %rax
    movq $2, %rcx  /* IIIW_EXIT */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    popq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .text,"xr"  /* PE/COFF Â§6 */
    /* IRQL_REQUIRES_MAX(2) */
    .global L_p_sha256_init
L_p_sha256_init:
    .seh_proc L_p_sha256_init
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    /* witness enter (D9, ADR-024) */
    movq $1, %rcx  /* IIIW_ENTER */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    subq $32, %rsp
    callq L_p_sha_init_k
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x6a09e667, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_H(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0xbb67ae85, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_H(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x3c6ef372, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_H(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0xa54ff53a, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_H(%rip), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x510e527f, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_H(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x9b05688c, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_H(%rip), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x1f83d9ab, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_H(%rip), %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x5be0cd19, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_H(%rip), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, L_p_SHA_BITS(%rip)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, L_p_SHA_BUFLEN(%rip)
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rax, L_p_SHA_INIT(%rip)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    pushq %rax
    pushq %rax
    movq $2, %rcx  /* IIIW_EXIT */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    popq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .text,"xr"  /* PE/COFF Â§6 */
    /* IRQL_REQUIRES_MAX(2) */
    .global L_p_sha256_update
L_p_sha256_update:
    .seh_proc L_p_sha256_update
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    /* witness enter (D9, ADR-024) */
    movq $1, %rcx  /* IIIW_ENTER */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    movq L_p_SHA_INIT(%rip), %rax
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
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    pushq %rax
    pushq %rax
    movq $2, %rcx  /* IIIW_EXIT */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    popq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
L_if_end_17:
    movq L_p_SHA_BITS(%rip), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, L_p_SHA_BITS(%rip)
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
L_for_top_18:
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
    jz L_for_end_19
    movabsq $0x40, %rax
    pushq %rax
    movq L_p_SHA_BUFLEN(%rip), %rax
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
    jz L_if_end_21
    movq -24(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
L_if_end_21:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
L_for_top_22:
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
    jz L_for_end_23
    movq L_p_SHA_BUFLEN(%rip), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
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
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_BUF(%rip), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
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
    jmp L_for_top_22
L_for_end_23:
    movq L_p_SHA_BUFLEN(%rip), %rax
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
    movq %rax, L_p_SHA_BUFLEN(%rip)
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
    movq L_p_SHA_BUFLEN(%rip), %rax
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
    jz L_if_end_25
    subq $32, %rsp
    callq L_p_sha_block
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, L_p_SHA_BUFLEN(%rip)
L_if_end_25:
    jmp L_for_top_18
L_for_end_19:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    pushq %rax
    pushq %rax
    movq $2, %rcx  /* IIIW_EXIT */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    popq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .text,"xr"  /* PE/COFF Â§6 */
    /* IRQL_REQUIRES_MAX(2) */
    .global L_p_sha256_final
L_p_sha256_final:
    .seh_proc L_p_sha256_final
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    /* witness enter (D9, ADR-024) */
    movq $1, %rcx  /* IIIW_ENTER */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    movq L_p_SHA_INIT(%rip), %rax
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
    pushq %rax
    pushq %rax
    movq $2, %rcx  /* IIIW_EXIT */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    popq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
L_if_end_27:
    movq L_p_SHA_BITS(%rip), %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movabsq $0x80, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_BUF(%rip), %rax
    pushq %rax
    movq L_p_SHA_BUFLEN(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movq L_p_SHA_BUFLEN(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, L_p_SHA_BUFLEN(%rip)
    movq L_p_SHA_BUFLEN(%rip), %rax
    pushq %rax
    movabsq $0x38, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setg %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_29
L_for_top_30:
    movq L_p_SHA_BUFLEN(%rip), %rax
    pushq %rax
    movabsq $0x40, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setl %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_for_end_31
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_BUF(%rip), %rax
    pushq %rax
    movq L_p_SHA_BUFLEN(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movq L_p_SHA_BUFLEN(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, L_p_SHA_BUFLEN(%rip)
    jmp L_for_top_30
L_for_end_31:
    subq $32, %rsp
    callq L_p_sha_block
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, L_p_SHA_BUFLEN(%rip)
L_if_end_29:
L_for_top_32:
    movq L_p_SHA_BUFLEN(%rip), %rax
    pushq %rax
    movabsq $0x38, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setl %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_for_end_33
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_BUF(%rip), %rax
    pushq %rax
    movq L_p_SHA_BUFLEN(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movq L_p_SHA_BUFLEN(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, L_p_SHA_BUFLEN(%rip)
    jmp L_for_top_32
L_for_end_33:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
L_for_top_34:
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setl %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_for_end_35
    movabsq $0x38, %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
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
    movq -40(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_BUF(%rip), %rax
    pushq %rax
    movq L_p_SHA_BUFLEN(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movq L_p_SHA_BUFLEN(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, L_p_SHA_BUFLEN(%rip)
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
    jmp L_for_top_34
L_for_end_35:
    subq $32, %rsp
    callq L_p_sha_block
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, L_p_SHA_BUFLEN(%rip)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
L_for_top_36:
    movl -48(%rbp), %eax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setl %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_for_end_37
    leaq L_p_SHA_H(%rip), %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movl -48(%rbp), %eax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movl -56(%rbp), %eax
    pushq %rax
    movabsq $0x18, %rax
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
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movl -64(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movl -56(%rbp), %eax
    pushq %rax
    movabsq $0x10, %rax
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
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movl -64(%rbp), %eax
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
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movl -56(%rbp), %eax
    pushq %rax
    movabsq $0x8, %rax
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
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movl -64(%rbp), %eax
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
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movl -56(%rbp), %eax
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
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movl -64(%rbp), %eax
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
    popq %rdx
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
    movq %rax, -48(%rbp)
    jmp L_for_top_36
L_for_end_37:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, L_p_SHA_INIT(%rip)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    pushq %rax
    pushq %rax
    movq $2, %rcx  /* IIIW_EXIT */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    popq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .text,"xr"  /* PE/COFF Â§6 */
    /* IRQL_REQUIRES_MAX(2) */
    .global L_p_sha256_oneshot
L_p_sha256_oneshot:
    .seh_proc L_p_sha256_oneshot
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movq %r8, -24(%rbp)
    /* witness enter (D9, ADR-024) */
    movq $1, %rcx  /* IIIW_ENTER */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    subq $32, %rsp
    callq L_p_sha256_init
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_sha256_update
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_sha256_final
    addq $32, %rsp
    pushq %rax
    popq %rax
    pushq %rax
    pushq %rax
    movq $2, %rcx  /* IIIW_EXIT */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    popq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .text,"xr"  /* PE/COFF Â§6 */
    /* IRQL_REQUIRES_MAX(2) */
    .global L_p_sha256_feed_packed
L_p_sha256_feed_packed:
    .seh_proc L_p_sha256_feed_packed
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    /* witness enter (D9, ADR-024) */
    movq $1, %rcx  /* IIIW_ENTER */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    shrq %cl, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
L_for_top_38:
    movq -40(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_for_end_39
    movq -24(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq -48(%rbp), %rax
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
    popq %rcx
    subq $32, %rsp
    callq L_p_sha256_update_byte
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -48(%rbp), %rax
    pushq %rax
    movabsq $0x8, %rax
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
    popq %rcx
    subq $32, %rsp
    callq L_p_sha256_update_byte
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -48(%rbp), %rax
    pushq %rax
    movabsq $0x10, %rax
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
    popq %rcx
    subq $32, %rsp
    callq L_p_sha256_update_byte
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -48(%rbp), %rax
    pushq %rax
    movabsq $0x18, %rax
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
    popq %rcx
    subq $32, %rsp
    callq L_p_sha256_update_byte
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -48(%rbp), %rax
    pushq %rax
    movabsq $0x20, %rax
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
    popq %rcx
    subq $32, %rsp
    callq L_p_sha256_update_byte
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -48(%rbp), %rax
    pushq %rax
    movabsq $0x28, %rax
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
    popq %rcx
    subq $32, %rsp
    callq L_p_sha256_update_byte
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -48(%rbp), %rax
    pushq %rax
    movabsq $0x30, %rax
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
    popq %rcx
    subq $32, %rsp
    callq L_p_sha256_update_byte
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -48(%rbp), %rax
    pushq %rax
    movabsq $0x38, %rax
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
    popq %rcx
    subq $32, %rsp
    callq L_p_sha256_update_byte
    addq $32, %rsp
    pushq %rax
    popq %rax
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
    jmp L_for_top_38
L_for_end_39:
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movq -56(%rbp), %rax
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
    jz L_if_end_41
    movq -24(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
L_if_end_41:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
L_for_top_42:
    movq -72(%rbp), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_for_end_43
    movq -64(%rbp), %rax
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
    popq %rcx
    subq $32, %rsp
    callq L_p_sha256_update_byte
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -64(%rbp), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    shrq %cl, %rax
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
    jmp L_for_top_42
L_for_end_43:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    pushq %rax
    pushq %rax
    movq $2, %rcx  /* IIIW_EXIT */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    popq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .text,"xr"  /* PE/COFF Â§6 */
    /* IRQL_REQUIRES_MAX(2) */
    .global L_p_sha256_oneshot_packed
L_p_sha256_oneshot_packed:
    .seh_proc L_p_sha256_oneshot_packed
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movq %r8, -24(%rbp)
    /* witness enter (D9, ADR-024) */
    movq $1, %rcx  /* IIIW_ENTER */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    subq $32, %rsp
    callq L_p_sha256_init
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_sha256_feed_packed
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_sha256_final
    addq $32, %rsp
    pushq %rax
    popq %rax
    pushq %rax
    pushq %rax
    movq $2, %rcx  /* IIIW_EXIT */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    popq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .text,"xr"  /* PE/COFF Â§6 */
    /* IRQL_REQUIRES_MAX(2) */
    .global L_p_sha256_emit_bp
L_p_sha256_emit_bp:
    .seh_proc L_p_sha256_emit_bp
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    /* witness enter (D9, ADR-024) */
    movq $1, %rcx  /* IIIW_ENTER */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
L_for_top_44:
    movq -24(%rbp), %rax
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
    jz L_for_end_45
    leaq L_p_SHA_H(%rip), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    leaq L_p_SHA_H(%rip), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x18, %rax
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
    movq %rax, -48(%rbp)
    movq -48(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x10, %rax
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
    movabsq $0x8, %rax
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
    movq %rax, -48(%rbp)
    movq -48(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x8, %rax
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
    movabsq $0x10, %rax
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
    movq %rax, -48(%rbp)
    movq -48(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    movabsq $0x18, %rax
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
    movq %rax, -48(%rbp)
    movq -48(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x18, %rax
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
    movabsq $0x20, %rax
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
    movq %rax, -48(%rbp)
    movq -48(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x10, %rax
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
    movabsq $0x28, %rax
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
    movq %rax, -48(%rbp)
    movq -48(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x8, %rax
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
    movabsq $0x30, %rax
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
    movq %rax, -48(%rbp)
    movq -48(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    movabsq $0x38, %rax
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
    movq %rax, -48(%rbp)
    movq -48(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
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
    jmp L_for_top_44
L_for_end_45:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    pushq %rax
    pushq %rax
    movq $2, %rcx  /* IIIW_EXIT */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    popq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .text,"xr"  /* PE/COFF Â§6 */
    /* IRQL_REQUIRES_MAX(2) */
    .global L_p_sha256_oneshot_packed_bp
L_p_sha256_oneshot_packed_bp:
    .seh_proc L_p_sha256_oneshot_packed_bp
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movq %r8, -24(%rbp)
    /* witness enter (D9, ADR-024) */
    movq $1, %rcx  /* IIIW_ENTER */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    subq $32, %rsp
    callq L_p_sha256_init
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_sha256_feed_packed
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq L_p_sha256_finalize_internal
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_sha256_emit_bp
    addq $32, %rsp
    pushq %rax
    popq %rax
    pushq %rax
    pushq %rax
    movq $2, %rcx  /* IIIW_EXIT */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    popq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .text,"xr"  /* PE/COFF Â§6 */
    /* IRQL_REQUIRES_MAX(2) */
    .global L_p_sha256_update_byte
L_p_sha256_update_byte:
    .seh_proc L_p_sha256_update_byte
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    /* witness enter (D9, ADR-024) */
    movq $1, %rcx  /* IIIW_ENTER */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    movq L_p_SHA_INIT(%rip), %rax
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
    jz L_if_end_47
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    pushq %rax
    pushq %rax
    movq $2, %rcx  /* IIIW_EXIT */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    popq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
L_if_end_47:
    movq L_p_SHA_BITS(%rip), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, L_p_SHA_BITS(%rip)
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
    popq %rax
    pushq %rax
    leaq L_p_SHA_BUF(%rip), %rax
    pushq %rax
    movq L_p_SHA_BUFLEN(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movq L_p_SHA_BUFLEN(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, L_p_SHA_BUFLEN(%rip)
    movq L_p_SHA_BUFLEN(%rip), %rax
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
    jz L_if_end_49
    subq $32, %rsp
    callq L_p_sha_block
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, L_p_SHA_BUFLEN(%rip)
L_if_end_49:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    pushq %rax
    pushq %rax
    movq $2, %rcx  /* IIIW_EXIT */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    popq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .text,"xr"  /* PE/COFF Â§6 */
    /* IRQL_REQUIRES_MAX(2) */
    .global L_p_sha256_finalize_internal
L_p_sha256_finalize_internal:
    .seh_proc L_p_sha256_finalize_internal
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    /* witness enter (D9, ADR-024) */
    movq $1, %rcx  /* IIIW_ENTER */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    movq L_p_SHA_INIT(%rip), %rax
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
    jz L_if_end_51
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    pushq %rax
    pushq %rax
    movq $2, %rcx  /* IIIW_EXIT */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    popq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
L_if_end_51:
    movq L_p_SHA_BITS(%rip), %rax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movabsq $0x80, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_BUF(%rip), %rax
    pushq %rax
    movq L_p_SHA_BUFLEN(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movq L_p_SHA_BUFLEN(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, L_p_SHA_BUFLEN(%rip)
    movq L_p_SHA_BUFLEN(%rip), %rax
    pushq %rax
    movabsq $0x38, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setg %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_53
L_for_top_54:
    movq L_p_SHA_BUFLEN(%rip), %rax
    pushq %rax
    movabsq $0x40, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setl %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_for_end_55
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_BUF(%rip), %rax
    pushq %rax
    movq L_p_SHA_BUFLEN(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movq L_p_SHA_BUFLEN(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, L_p_SHA_BUFLEN(%rip)
    jmp L_for_top_54
L_for_end_55:
    subq $32, %rsp
    callq L_p_sha_block
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, L_p_SHA_BUFLEN(%rip)
L_if_end_53:
L_for_top_56:
    movq L_p_SHA_BUFLEN(%rip), %rax
    pushq %rax
    movabsq $0x38, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setl %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_for_end_57
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_BUF(%rip), %rax
    pushq %rax
    movq L_p_SHA_BUFLEN(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movq L_p_SHA_BUFLEN(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, L_p_SHA_BUFLEN(%rip)
    jmp L_for_top_56
L_for_end_57:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
L_for_top_58:
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setl %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_for_end_59
    movabsq $0x38, %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    movl -24(%rbp), %eax
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
    movq %rax, -32(%rbp)
    movq -32(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_SHA_BUF(%rip), %rax
    pushq %rax
    movq L_p_SHA_BUFLEN(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movq L_p_SHA_BUFLEN(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, L_p_SHA_BUFLEN(%rip)
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
    jmp L_for_top_58
L_for_end_59:
    subq $32, %rsp
    callq L_p_sha_block
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, L_p_SHA_BUFLEN(%rip)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, L_p_SHA_INIT(%rip)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    pushq %rax
    pushq %rax
    movq $2, %rcx  /* IIIW_EXIT */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    popq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .text,"xr"  /* PE/COFF Â§6 */
    /* IRQL_REQUIRES_MAX(2) */
    .global L_p_sha256_digest_byte
L_p_sha256_digest_byte:
    .seh_proc L_p_sha256_digest_byte
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    /* witness enter (D9, ADR-024) */
    movq $1, %rcx  /* IIIW_ENTER */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0x20, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setge %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_61
    movabsq $0x100, %rax
    pushq %rax
    popq %rax
    pushq %rax
    pushq %rax
    movq $2, %rcx  /* IIIW_EXIT */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    popq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
L_if_end_61:
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cqto
    idivq %rcx
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    leaq L_p_SHA_H(%rip), %rax
    pushq %rax
    movl -16(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movabsq $0x3, %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movl -32(%rbp), %eax
    pushq %rax
    movl -40(%rbp), %eax
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
    pushq %rax
    pushq %rax
    movq $2, %rcx  /* IIIW_EXIT */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    popq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
