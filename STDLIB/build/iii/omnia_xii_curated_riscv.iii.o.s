# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "xii_emit_gen.iii\0"
    .section .data
    .global L_XCR_H051_RISCV
L_XCR_H051_RISCV:
    .byte 0x13
    .byte 0xd5
    .byte 0x85
    .byte 0x6b
    .byte 0x67
    .byte 0x80
    .byte 0x0
    .byte 0x0
    .global L_XCR_H058_RISCV
L_XCR_H058_RISCV:
    .byte 0x57
    .byte 0x70
    .byte 0x1
    .byte 0xcd
    .byte 0x7
    .byte 0x70
    .byte 0x5
    .byte 0x2
    .byte 0x67
    .byte 0x80
    .byte 0x0
    .byte 0x0
    .byte 0x13
    .byte 0x0
    .byte 0x0
    .byte 0x0
    .byte 0x13
    .byte 0x0
    .byte 0x0
    .byte 0x0
    .section .iii.ring3,"n"
    .asciz "xii_curated_riscv_register_all"
    .text
    .global xii_curated_riscv_register_all
    .seh_proc xii_curated_riscv_register_all
xii_curated_riscv_register_all:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movabsq $0x8, %rax
    pushq %rax
    leaq L_XCR_H051_RISCV(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x32, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq xii_emit_gen_override
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x10, %rax
    pushq %rax
    leaq L_XCR_H058_RISCV(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    movabsq $0x39, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq xii_emit_gen_override
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
