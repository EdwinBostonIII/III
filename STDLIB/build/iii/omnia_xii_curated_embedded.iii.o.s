# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "xii_emit_gen.iii\0"
    .section .data
    .global L_XCE_H022_CORTEX_M
L_XCE_H022_CORTEX_M:
    .byte 0x0
    .byte 0x68
    .byte 0x78
    .byte 0x40
    .byte 0x0
    .byte 0xfa
    .byte 0x87
    .byte 0xf0
    .byte 0x0
    .byte 0x68
    .byte 0x78
    .byte 0x40
    .byte 0x80
    .byte 0xbd
    .byte 0x0
    .byte 0xbf
    .global L_XCE_H051_CORTEX_M
L_XCE_H051_CORTEX_M:
    .byte 0x80
    .byte 0xba
    .byte 0x89
    .byte 0xba
    .byte 0x80
    .byte 0xbd
    .byte 0x0
    .byte 0xbf
    .global L_XCE_H058_CORTEX_M
L_XCE_H058_CORTEX_M:
    .byte 0x1e
    .byte 0xc8
    .byte 0x80
    .byte 0xbd
    .byte 0x0
    .byte 0xbf
    .byte 0x0
    .byte 0xbf
    .section .iii.ring3,"n"
    .asciz "xii_curated_embedded_register_all"
    .text
    .global xii_curated_embedded_register_all
    .seh_proc xii_curated_embedded_register_all
xii_curated_embedded_register_all:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movabsq $0x10, %rax
    pushq %rax
    leaq L_XCE_H022_CORTEX_M(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0x15, %rax
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
    movabsq $0x8, %rax
    pushq %rax
    leaq L_XCE_H051_CORTEX_M(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x6, %rax
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
    movabsq $0x8, %rax
    pushq %rax
    leaq L_XCE_H058_CORTEX_M(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x6, %rax
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
