# III Stage-0 Ring-0 codegen output (Windows kernel-mode .sys)
# Output binary: iiis-0.sys
    .att_syntax
    .section .rdata,"dr"
L_str_0:
    .ascii "cpufeat.iii\0"
    .section .rodata
L_p_KK_OK:
    .quad 0x0
L_p_KK_E_NULL:
    .quad 0xffffffffffffffff
L_p_KK_E_BADRATE:
    .quad 0xfffffffffffffffe
    .section .bss
    .global L_p_KK_RND_CONST
L_p_KK_RND_CONST:
    .zero 192
    .section .data
    .global L_p_KK_RND_INIT
L_p_KK_RND_INIT:
    .quad 0x0
    .section .bss
    .global L_p_KK_RHO_OFF
L_p_KK_RHO_OFF:
    .zero 200
    .section .data
    .global L_p_KK_RHO_INIT
L_p_KK_RHO_INIT:
    .quad 0x0
    .section .bss
    .global L_p_KK_LANE_A
L_p_KK_LANE_A:
    .zero 256
    .global L_p_KK_LANE_B
L_p_KK_LANE_B:
    .zero 256
    .global L_p_KK_PAR_C
L_p_KK_PAR_C:
    .zero 40
    .global L_p_KK_PAR_D
L_p_KK_PAR_D:
    .zero 40
    .global L_p_KK_CHI_IDX1
L_p_KK_CHI_IDX1:
    .zero 64
    .global L_p_KK_CHI_IDX2
L_p_KK_CHI_IDX2:
    .zero 64
    .section .data
    .global L_p_KK_CHI_FORCE
L_p_KK_CHI_FORCE:
    .quad 0x0
    .global L_p_KK_CHI_INIT
L_p_KK_CHI_INIT:
    .quad 0x0
    .section .text,"xr"  /* PE/COFF Â§6 */
    /* IRQL_REQUIRES_MAX(2) */
    .global L_p__kk_init_rc
L_p__kk_init_rc:
    .seh_proc L_p__kk_init_rc
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
    movq L_p_KK_RND_INIT(%rip), %rax
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
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RND_CONST(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x8082, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RND_CONST(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x800000000000808a, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RND_CONST(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x8000000080008000, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RND_CONST(%rip), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x808b, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RND_CONST(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x80000001, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RND_CONST(%rip), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x8000000080008081, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RND_CONST(%rip), %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x8000000000008009, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RND_CONST(%rip), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x8a, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RND_CONST(%rip), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x88, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RND_CONST(%rip), %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x80008009, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RND_CONST(%rip), %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x8000000a, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RND_CONST(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x8000808b, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RND_CONST(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x800000000000008b, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RND_CONST(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x8000000000008089, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RND_CONST(%rip), %rax
    pushq %rax
    movabsq $0xe, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x8000000000008003, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RND_CONST(%rip), %rax
    pushq %rax
    movabsq $0xf, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x8000000000008002, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RND_CONST(%rip), %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x8000000000000080, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RND_CONST(%rip), %rax
    pushq %rax
    movabsq $0x11, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x800a, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RND_CONST(%rip), %rax
    pushq %rax
    movabsq $0x12, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x800000008000000a, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RND_CONST(%rip), %rax
    pushq %rax
    movabsq $0x13, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x8000000080008081, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RND_CONST(%rip), %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x8000000000008080, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RND_CONST(%rip), %rax
    pushq %rax
    movabsq $0x15, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x80000001, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RND_CONST(%rip), %rax
    pushq %rax
    movabsq $0x16, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x8000000080008008, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RND_CONST(%rip), %rax
    pushq %rax
    movabsq $0x17, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rax, L_p_KK_RND_INIT(%rip)
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
    .global L_p__kk_init_rho
L_p__kk_init_rho:
    .seh_proc L_p__kk_init_rho
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
    movq L_p_KK_RHO_INIT(%rip), %rax
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
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RHO_OFF(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RHO_OFF(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x3e, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RHO_OFF(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x1c, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RHO_OFF(%rip), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x1b, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RHO_OFF(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x24, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RHO_OFF(%rip), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x2c, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RHO_OFF(%rip), %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x6, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RHO_OFF(%rip), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x37, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RHO_OFF(%rip), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x14, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RHO_OFF(%rip), %rax
    pushq %rax
    movabsq $0x9, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x3, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RHO_OFF(%rip), %rax
    pushq %rax
    movabsq $0xa, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0xa, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RHO_OFF(%rip), %rax
    pushq %rax
    movabsq $0xb, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x2b, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RHO_OFF(%rip), %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x19, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RHO_OFF(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x27, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RHO_OFF(%rip), %rax
    pushq %rax
    movabsq $0xe, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x29, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RHO_OFF(%rip), %rax
    pushq %rax
    movabsq $0xf, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x2d, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RHO_OFF(%rip), %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0xf, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RHO_OFF(%rip), %rax
    pushq %rax
    movabsq $0x11, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x15, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RHO_OFF(%rip), %rax
    pushq %rax
    movabsq $0x12, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x8, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RHO_OFF(%rip), %rax
    pushq %rax
    movabsq $0x13, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x12, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RHO_OFF(%rip), %rax
    pushq %rax
    movabsq $0x14, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x2, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RHO_OFF(%rip), %rax
    pushq %rax
    movabsq $0x15, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x3d, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RHO_OFF(%rip), %rax
    pushq %rax
    movabsq $0x16, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x38, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RHO_OFF(%rip), %rax
    pushq %rax
    movabsq $0x17, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0xe, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_RHO_OFF(%rip), %rax
    pushq %rax
    movabsq $0x18, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rax, L_p_KK_RHO_INIT(%rip)
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
    .global L_p__kk_init_chi_idx
L_p__kk_init_chi_idx:
    .seh_proc L_p__kk_init_chi_idx
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
    movq L_p_KK_CHI_INIT(%rip), %rax
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
L_if_end_5:
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_CHI_IDX1(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x2, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_CHI_IDX1(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x3, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_CHI_IDX1(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x4, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_CHI_IDX1(%rip), %rax
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
    leaq L_p_KK_CHI_IDX1(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x5, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_CHI_IDX1(%rip), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x6, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_CHI_IDX1(%rip), %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x7, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_CHI_IDX1(%rip), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x2, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_CHI_IDX2(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x3, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_CHI_IDX2(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x4, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_CHI_IDX2(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_CHI_IDX2(%rip), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_CHI_IDX2(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x5, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_CHI_IDX2(%rip), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x6, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_CHI_IDX2(%rip), %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x7, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_CHI_IDX2(%rip), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rax, L_p_KK_CHI_INIT(%rip)
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
    .global L_p_keccak_rotl64
L_p_keccak_rotl64:
    .seh_proc L_p_keccak_rotl64
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
    movabsq $0x3f, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
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
    jz L_if_end_7
    movq -24(%rbp), %rax
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
    movq -24(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    shlq %cl, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x40, %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    shrq %cl, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq -40(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    orq %rcx, %rax
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
    .global L_p__kk_load_lane
L_p__kk_load_lane:
    .seh_proc L_p__kk_load_lane
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
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
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
    movq %rax, -40(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
L_for_top_8:
    movq -56(%rbp), %rax
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
    jz L_for_end_9
    movq -40(%rbp), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movq -48(%rbp), %rax
    pushq %rax
    movq -64(%rbp), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    movabsq $0x8, %rax
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
    movq %rax, -48(%rbp)
    movq -56(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    jmp L_for_top_8
L_for_end_9:
    movq -48(%rbp), %rax
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
    .global L_p__kk_store_lane
L_p__kk_store_lane:
    .seh_proc L_p__kk_store_lane
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
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq -32(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
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
    movq %rax, -56(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
L_for_top_10:
    movq -64(%rbp), %rax
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
    jz L_for_end_11
    movq -48(%rbp), %rax
    pushq %rax
    movq -64(%rbp), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
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
    movq -56(%rbp), %rax
    pushq %rax
    movq -64(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movq -64(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    jmp L_for_top_10
L_for_end_11:
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
    .global L_p_keccak_state_zero
L_p_keccak_state_zero:
    .seh_proc L_p_keccak_state_zero
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
    jz L_if_end_13
    movq L_p_KK_E_NULL(%rip), %rax
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
L_if_end_13:
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
L_for_top_14:
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0xc8, %rax
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
    movq -24(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    jmp L_for_top_14
L_for_end_15:
    movq L_p_KK_OK(%rip), %rax
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
    .global L_p__kk_chi_scalar
L_p__kk_chi_scalar:
    .seh_proc L_p__kk_chi_scalar
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
L_for_top_16:
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
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
    movq %rax, -16(%rbp)
L_for_top_18:
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
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
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setge %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_21
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
L_if_end_21:
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setge %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_23
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
L_if_end_23:
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movq -8(%rbp), %rax
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
    movq %rax, -40(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movq -8(%rbp), %rax
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
    movq %rax, -48(%rbp)
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movq -8(%rbp), %rax
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
    movq %rax, -56(%rbp)
    leaq L_p_KK_LANE_B(%rip), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    leaq L_p_KK_LANE_B(%rip), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    leaq L_p_KK_LANE_B(%rip), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -80(%rbp)
    movq -64(%rbp), %rax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    movabsq $0xffffffffffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    movq -80(%rbp), %rax
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
    pushq %rax
    leaq L_p_KK_LANE_A(%rip), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
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
    jmp L_for_top_18
L_for_end_19:
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
    jmp L_for_top_16
L_for_end_17:
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
    .global L_p__kk_chi_avx512
L_p__kk_chi_avx512:
    .seh_proc L_p__kk_chi_avx512
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
    .global L_p__kk_chi
L_p__kk_chi:
    .seh_proc L_p__kk_chi
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
    movq L_p_KK_CHI_FORCE(%rip), %rax
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
    jz L_if_end_25
    subq $32, %rsp
    callq L_p__kk_chi_scalar
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
L_if_end_25:
    movq L_p_KK_CHI_FORCE(%rip), %rax
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
    jz L_if_end_27
    subq $32, %rsp
    callq L_p__kk_chi_avx512
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
L_if_end_27:
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
    jz L_if_end_29
    subq $32, %rsp
    callq L_p__kk_chi_avx512
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
L_if_end_29:
    subq $32, %rsp
    callq L_p__kk_chi_scalar
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
    .global L_p_keccak_chi_force_path
L_p_keccak_chi_force_path:
    .seh_proc L_p_keccak_chi_force_path
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
    movq %rax, L_p_KK_CHI_FORCE(%rip)
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
    .global L_p_keccak_f1600
L_p_keccak_f1600:
    .seh_proc L_p_keccak_f1600
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
    jz L_if_end_31
    movq L_p_KK_E_NULL(%rip), %rax
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
L_if_end_31:
    subq $32, %rsp
    callq L_p__kk_init_rc
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq L_p__kk_init_rho
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq L_p__kk_init_chi_idx
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
L_for_top_32:
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x19, %rax
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
    movq -16(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p__kk_load_lane
    addq $32, %rsp
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_LANE_A(%rip), %rax
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
    jmp L_for_top_32
L_for_end_33:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
L_for_top_34:
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x18, %rax
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
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
L_for_top_36:
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
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
    leaq L_p_KK_LANE_A(%rip), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    leaq L_p_KK_LANE_A(%rip), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
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
    movq %rax, -56(%rbp)
    leaq L_p_KK_LANE_A(%rip), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0xa, %rax
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
    movq %rax, -64(%rbp)
    leaq L_p_KK_LANE_A(%rip), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0xf, %rax
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
    movq %rax, -72(%rbp)
    leaq L_p_KK_LANE_A(%rip), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x14, %rax
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
    movq %rax, -80(%rbp)
    movq -48(%rbp), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    movq -64(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    movq -80(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_PAR_C(%rip), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
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
    jmp L_for_top_36
L_for_end_37:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
L_for_top_38:
    movq -88(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setl %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_for_end_39
    movq -88(%rbp), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -96(%rbp)
    movq -96(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setge %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_41
    movq -96(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -96(%rbp)
L_if_end_41:
    movq -88(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -104(%rbp)
    movq -104(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setge %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_43
    movq -104(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -104(%rbp)
L_if_end_43:
    leaq L_p_KK_PAR_C(%rip), %rax
    pushq %rax
    movq -96(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    leaq L_p_KK_PAR_C(%rip), %rax
    pushq %rax
    movq -104(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_keccak_rotl64
    addq $32, %rsp
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_PAR_D(%rip), %rax
    pushq %rax
    movq -88(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movq -88(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
    jmp L_for_top_38
L_for_end_39:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -112(%rbp)
L_for_top_44:
    movq -112(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setl %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_for_end_45
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -120(%rbp)
L_for_top_46:
    movq -120(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setl %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_for_end_47
    movq -120(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movq -112(%rbp), %rax
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
    movq %rax, -128(%rbp)
    leaq L_p_KK_LANE_A(%rip), %rax
    pushq %rax
    movq -128(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    leaq L_p_KK_PAR_D(%rip), %rax
    pushq %rax
    movq -120(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_LANE_A(%rip), %rax
    pushq %rax
    movq -128(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movq -120(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -120(%rbp)
    jmp L_for_top_46
L_for_end_47:
    movq -112(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -112(%rbp)
    jmp L_for_top_44
L_for_end_45:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -136(%rbp)
L_for_top_48:
    movq -136(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setl %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_for_end_49
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -144(%rbp)
L_for_top_50:
    movq -144(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setl %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_for_end_51
    movq -144(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movq -136(%rbp), %rax
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
    movq %rax, -152(%rbp)
    movq -144(%rbp), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movq -136(%rbp), %rax
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
    movq %rax, -160(%rbp)
    movq -160(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setge %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_53
    movq -160(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -160(%rbp)
L_if_end_53:
    movq -160(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setge %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_55
    movq -160(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -160(%rbp)
L_if_end_55:
    movq -160(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setge %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_57
    movq -160(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -160(%rbp)
L_if_end_57:
    movq -144(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -168(%rbp)
    movq -160(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movq -168(%rbp), %rax
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
    movq %rax, -176(%rbp)
    leaq L_p_KK_LANE_A(%rip), %rax
    pushq %rax
    movq -176(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    leaq L_p_KK_RHO_OFF(%rip), %rax
    pushq %rax
    movq -176(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p_keccak_rotl64
    addq $32, %rsp
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_LANE_B(%rip), %rax
    pushq %rax
    movq -152(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movq -144(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -144(%rbp)
    jmp L_for_top_50
L_for_end_51:
    movq -136(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -136(%rbp)
    jmp L_for_top_48
L_for_end_49:
    subq $32, %rsp
    callq L_p__kk_chi
    addq $32, %rsp
    pushq %rax
    popq %rax
    leaq L_p_KK_LANE_A(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    leaq L_p_KK_RND_CONST(%rip), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_p_KK_LANE_A(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    jmp L_for_top_34
L_for_end_35:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -184(%rbp)
L_for_top_58:
    movq -184(%rbp), %rax
    pushq %rax
    movabsq $0x19, %rax
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
    movq -16(%rbp), %rax
    pushq %rax
    movq -184(%rbp), %rax
    pushq %rax
    leaq L_p_KK_LANE_A(%rip), %rax
    pushq %rax
    movq -184(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %r8
    popq %rdx
    popq %rcx
    subq $32, %rsp
    callq L_p__kk_store_lane
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -184(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -184(%rbp)
    jmp L_for_top_58
L_for_end_59:
    movq L_p_KK_OK(%rip), %rax
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
    .global L_p_keccak_absorb
L_p_keccak_absorb:
    .seh_proc L_p_keccak_absorb
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movq %r8, -24(%rbp)
    movq %r9, -32(%rbp)
    /* witness enter (D9, ADR-024) */
    movq $1, %rcx  /* IIIW_ENTER */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq -32(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movq -64(%rbp), %rax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movq -64(%rbp), %rax
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
    jz L_if_end_61
    movq L_p_KK_E_NULL(%rip), %rax
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
    jz L_if_end_63
    movq L_p_KK_E_BADRATE(%rip), %rax
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
L_if_end_63:
    movq -72(%rbp), %rax
    pushq %rax
    movabsq $0xc8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setg %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_65
    movq L_p_KK_E_BADRATE(%rip), %rax
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
L_if_end_65:
    movq -40(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
    movq -48(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -96(%rbp)
    movq -72(%rbp), %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -104(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -112(%rbp)
L_for_top_66:
    movq -112(%rbp), %rax
    pushq %rax
    movq -104(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setle %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_for_end_67
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -120(%rbp)
L_for_top_68:
    movq -120(%rbp), %rax
    pushq %rax
    movq -104(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setl %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_for_end_69
    movq -88(%rbp), %rax
    pushq %rax
    movq -120(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movq -96(%rbp), %rax
    pushq %rax
    movq -112(%rbp), %rax
    pushq %rax
    movq -120(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -88(%rbp), %rax
    pushq %rax
    movq -120(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movq -120(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -120(%rbp)
    jmp L_for_top_68
L_for_end_69:
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_keccak_f1600
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -112(%rbp), %rax
    pushq %rax
    movq -104(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -112(%rbp)
    jmp L_for_top_66
L_for_end_67:
    movq -56(%rbp), %rax
    pushq %rax
    movq -112(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -128(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -136(%rbp)
L_for_top_70:
    movq -136(%rbp), %rax
    pushq %rax
    movq -128(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setl %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_for_end_71
    movq -88(%rbp), %rax
    pushq %rax
    movq -136(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movq -96(%rbp), %rax
    pushq %rax
    movq -112(%rbp), %rax
    pushq %rax
    movq -136(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -88(%rbp), %rax
    pushq %rax
    movq -136(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movq -136(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -136(%rbp)
    jmp L_for_top_70
L_for_end_71:
    movq -88(%rbp), %rax
    pushq %rax
    movq -128(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movq -80(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -88(%rbp), %rax
    pushq %rax
    movq -128(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movq -88(%rbp), %rax
    pushq %rax
    movq -104(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    movabsq $0x80, %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -88(%rbp), %rax
    pushq %rax
    movq -104(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_keccak_f1600
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq L_p_KK_OK(%rip), %rax
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
    .global L_p_keccak_pack_rate_dom
L_p_keccak_pack_rate_dom:
    .seh_proc L_p_keccak_pack_rate_dom
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
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq -16(%rbp), %rax
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
    .global L_p_keccak_squeeze
L_p_keccak_squeeze:
    .seh_proc L_p_keccak_squeeze
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movq %r8, -24(%rbp)
    movq %r9, -32(%rbp)
    /* witness enter (D9, ADR-024) */
    movq $1, %rcx  /* IIIW_ENTER */
    subq $32, %rsp
    callq iii_witness_emit_kernel
    addq $32, %rsp
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq -32(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
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
    jz L_if_end_73
    movq L_p_KK_E_NULL(%rip), %rax
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
L_if_end_73:
    movq -48(%rbp), %rax
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
    jz L_if_end_75
    movq L_p_KK_E_NULL(%rip), %rax
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
L_if_end_75:
    movq -64(%rbp), %rax
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
    jz L_if_end_77
    movq L_p_KK_E_BADRATE(%rip), %rax
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
L_if_end_77:
    movq -64(%rbp), %rax
    pushq %rax
    movabsq $0xc8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setg %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_79
    movq L_p_KK_E_BADRATE(%rip), %rax
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
L_if_end_79:
    movq -40(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movq -48(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -80(%rbp)
    movq -64(%rbp), %rax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -96(%rbp)
L_for_top_80:
    movq -96(%rbp), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setl %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_for_end_81
    movq -56(%rbp), %rax
    pushq %rax
    movq -96(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    subq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -104(%rbp)
    movq -104(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -112(%rbp)
    movq -104(%rbp), %rax
    pushq %rax
    movq -88(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setge %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_83
    movq -88(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -112(%rbp)
L_if_end_83:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -120(%rbp)
L_for_top_84:
    movq -120(%rbp), %rax
    pushq %rax
    movq -112(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setl %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_for_end_85
    movq -72(%rbp), %rax
    pushq %rax
    movq -120(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -80(%rbp), %rax
    pushq %rax
    movq -96(%rbp), %rax
    pushq %rax
    movq -120(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    popq %rdx
    movq %rdx, (%rax,%rcx,8)
    movq -120(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -120(%rbp)
    jmp L_for_top_84
L_for_end_85:
    movq -96(%rbp), %rax
    pushq %rax
    movq -112(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -96(%rbp)
    movq -96(%rbp), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setl %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_87
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_p_keccak_f1600
    addq $32, %rsp
    pushq %rax
    popq %rax
L_if_end_87:
    jmp L_for_top_80
L_for_end_81:
    movq L_p_KK_OK(%rip), %rax
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
