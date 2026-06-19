# III Stage-0 Ring-0 codegen output (Windows kernel-mode .sys)
# Output binary: iiis-0.sys
    .att_syntax
    .section .bss
    .global L_p_NIK
L_p_NIK:
    .zero 512
    .global L_p_NIMASK
L_p_NIMASK:
    .zero 32
    .global L_p_NIH
L_p_NIH:
    .zero 64
    .global L_p_NIBUF
L_p_NIBUF:
    .zero 512
    .section .data
    .global L_p_NIBUFLEN
L_p_NIBUFLEN:
    .quad 0x0
    .global L_p_NIBITS
L_p_NIBITS:
    .quad 0x0
    .global L_p_NIINIT
L_p_NIINIT:
    .quad 0x0
    .section .text,"xr"  /* PE/COFF Â§6 */
    /* IRQL_REQUIRES_MAX(2) */
    .global L_p_ni_init_k
L_p_ni_init_k:
    .seh_proc L_p_ni_init_k
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
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
    leaq L_p_NIK(%rip), %rax
    pushq %rax
    movabsq $0x3f, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x10203, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_NIMASK(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x4050607, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_NIMASK(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x8090a0b, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_NIMASK(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0xc0d0e0f, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_NIMASK(%rip), %rax
    pushq %rax
    movabsq $0x3, %rax
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
    .global L_p__sha_ni_block
L_p__sha_ni_block:
    .seh_proc L_p__sha_ni_block
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
    .global L_p_sha256_ni_init
L_p_sha256_ni_init:
    .seh_proc L_p_sha256_ni_init
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
    callq L_p_ni_init_k
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x6a09e667, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_NIH(%rip), %rax
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
    leaq L_p_NIH(%rip), %rax
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
    leaq L_p_NIH(%rip), %rax
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
    leaq L_p_NIH(%rip), %rax
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
    leaq L_p_NIH(%rip), %rax
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
    leaq L_p_NIH(%rip), %rax
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
    leaq L_p_NIH(%rip), %rax
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
    leaq L_p_NIH(%rip), %rax
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
    movq %rax, L_p_NIBITS(%rip)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, L_p_NIBUFLEN(%rip)
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rax, L_p_NIINIT(%rip)
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
    .global L_p_sha256_ni_update
L_p_sha256_ni_update:
    .seh_proc L_p_sha256_ni_update
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
    movq L_p_NIINIT(%rip), %rax
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
L_if_end_1:
    movq L_p_NIBITS(%rip), %rax
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
    movq %rax, L_p_NIBITS(%rip)
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
L_for_top_2:
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
    jz L_for_end_3
    movabsq $0x40, %rax
    pushq %rax
    movq L_p_NIBUFLEN(%rip), %rax
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
L_if_end_5:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
L_for_top_6:
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
    jz L_for_end_7
    movq L_p_NIBUFLEN(%rip), %rax
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
    leaq L_p_NIBUF(%rip), %rax
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
    jmp L_for_top_6
L_for_end_7:
    movq L_p_NIBUFLEN(%rip), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, L_p_NIBUFLEN(%rip)
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
    movq L_p_NIBUFLEN(%rip), %rax
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
    callq L_p__sha_ni_block
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, L_p_NIBUFLEN(%rip)
L_if_end_9:
    jmp L_for_top_2
L_for_end_3:
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
    .global L_p_sha256_ni_final
L_p_sha256_ni_final:
    .seh_proc L_p_sha256_ni_final
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
    movq L_p_NIINIT(%rip), %rax
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
L_if_end_11:
    movq L_p_NIBITS(%rip), %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movabsq $0x80, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_NIBUF(%rip), %rax
    pushq %rax
    movq L_p_NIBUFLEN(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movq L_p_NIBUFLEN(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, L_p_NIBUFLEN(%rip)
    movq L_p_NIBUFLEN(%rip), %rax
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
    jz L_if_end_13
L_for_top_14:
    movq L_p_NIBUFLEN(%rip), %rax
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
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_NIBUF(%rip), %rax
    pushq %rax
    movq L_p_NIBUFLEN(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movq L_p_NIBUFLEN(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, L_p_NIBUFLEN(%rip)
    jmp L_for_top_14
L_for_end_15:
    subq $32, %rsp
    callq L_p__sha_ni_block
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, L_p_NIBUFLEN(%rip)
L_if_end_13:
L_for_top_16:
    movq L_p_NIBUFLEN(%rip), %rax
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
    jz L_for_end_17
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_NIBUF(%rip), %rax
    pushq %rax
    movq L_p_NIBUFLEN(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movq L_p_NIBUFLEN(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, L_p_NIBUFLEN(%rip)
    jmp L_for_top_16
L_for_end_17:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
L_for_top_18:
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
    jz L_for_end_19
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
    movq %rax, -40(%rbp)
    movq -40(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_NIBUF(%rip), %rax
    pushq %rax
    movq L_p_NIBUFLEN(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movq L_p_NIBUFLEN(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, L_p_NIBUFLEN(%rip)
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
    jmp L_for_top_18
L_for_end_19:
    subq $32, %rsp
    callq L_p__sha_ni_block
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, L_p_NIBUFLEN(%rip)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
L_for_top_20:
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
    jz L_for_end_21
    leaq L_p_NIH(%rip), %rax
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
    jmp L_for_top_20
L_for_end_21:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, L_p_NIINIT(%rip)
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
    .global L_p_sha256_ni_oneshot
L_p_sha256_ni_oneshot:
    .seh_proc L_p_sha256_ni_oneshot
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
    callq L_p_sha256_ni_init
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
    callq L_p_sha256_ni_update
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_sha256_ni_final
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
