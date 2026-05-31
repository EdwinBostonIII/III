# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "xii_emit_gen.iii\0"
    .section .data
    .global L_XCE_H052_AVX2
L_XCE_H052_AVX2:
    .byte 0x48
    .byte 0x8b
    .byte 0x7
    .byte 0x48
    .byte 0x89
    .byte 0xc1
    .byte 0x48
    .byte 0xd1
    .byte 0xe8
    .byte 0x48
    .byte 0xc1
    .byte 0xe1
    .byte 0x3f
    .byte 0x48
    .byte 0x9
    .byte 0xc8
    .byte 0x48
    .byte 0x89
    .byte 0x7
    .byte 0xc3
    .byte 0x90
    .byte 0x90
    .byte 0x90
    .byte 0x90
    .global L_XCE_H052_ARM64
L_XCE_H052_ARM64:
    .byte 0x0
    .byte 0x0
    .byte 0x40
    .byte 0xf9
    .byte 0x0
    .byte 0x0
    .byte 0xc0
    .byte 0xda
    .byte 0x0
    .byte 0x0
    .byte 0x0
    .byte 0xf9
    .byte 0xc0
    .byte 0x3
    .byte 0x5f
    .byte 0xd6
    .global L_XCE_H056_AVX2
L_XCE_H056_AVX2:
    .byte 0xf0
    .byte 0x48
    .byte 0x9
    .byte 0x37
    .byte 0xc3
    .byte 0x90
    .byte 0x90
    .byte 0x90
    .global L_XCE_H056_ARM64
L_XCE_H056_ARM64:
    .byte 0x2
    .byte 0x30
    .byte 0xe1
    .byte 0xf8
    .byte 0xc0
    .byte 0x3
    .byte 0x5f
    .byte 0xd6
    .global L_XCE_H057_AVX2
L_XCE_H057_AVX2:
    .byte 0x48
    .byte 0xf7
    .byte 0xd6
    .byte 0xf0
    .byte 0x48
    .byte 0x21
    .byte 0x37
    .byte 0xc3
    .global L_XCE_H057_ARM64
L_XCE_H057_ARM64:
    .byte 0x2
    .byte 0x10
    .byte 0xe1
    .byte 0xf8
    .byte 0xc0
    .byte 0x3
    .byte 0x5f
    .byte 0xd6
    .global L_XCE_H059_AVX2
L_XCE_H059_AVX2:
    .byte 0xc5
    .byte 0xf9
    .byte 0x7f
    .byte 0x7
    .byte 0xc3
    .byte 0x90
    .byte 0x90
    .byte 0x90
    .global L_XCE_H059_ARM64
L_XCE_H059_ARM64:
    .byte 0x0
    .byte 0x0
    .byte 0x80
    .byte 0x3d
    .byte 0xc0
    .byte 0x3
    .byte 0x5f
    .byte 0xd6
    .global L_XCE_H060_AVX2
L_XCE_H060_AVX2:
    .byte 0xf
    .byte 0x18
    .byte 0xf
    .byte 0xc3
    .byte 0x90
    .byte 0x90
    .byte 0x90
    .byte 0x90
    .global L_XCE_H060_ARM64
L_XCE_H060_ARM64:
    .byte 0x0
    .byte 0x0
    .byte 0x80
    .byte 0xf9
    .byte 0xc0
    .byte 0x3
    .byte 0x5f
    .byte 0xd6
    .global L_XCE_H067_AVX2
L_XCE_H067_AVX2:
    .byte 0x48
    .byte 0x9
    .byte 0xf7
    .byte 0x48
    .byte 0x89
    .byte 0xf8
    .byte 0xc3
    .byte 0x90
    .global L_XCE_H067_ARM64
L_XCE_H067_ARM64:
    .byte 0x0
    .byte 0x0
    .byte 0x1
    .byte 0xaa
    .byte 0xc0
    .byte 0x3
    .byte 0x5f
    .byte 0xd6
    .global L_XCE_H114_AVX2
L_XCE_H114_AVX2:
    .byte 0x48
    .byte 0x39
    .byte 0xf7
    .byte 0xf
    .byte 0x94
    .byte 0xc0
    .byte 0xf
    .byte 0xb6
    .byte 0xc0
    .byte 0xc3
    .byte 0x90
    .byte 0x90
    .byte 0x90
    .byte 0x90
    .byte 0x90
    .byte 0x90
    .global L_XCE_H114_ARM64
L_XCE_H114_ARM64:
    .byte 0x1f
    .byte 0x0
    .byte 0x1
    .byte 0xeb
    .byte 0xe0
    .byte 0x17
    .byte 0x9f
    .byte 0x1a
    .byte 0xc0
    .byte 0x3
    .byte 0x5f
    .byte 0xd6
    .byte 0x0
    .byte 0x0
    .byte 0x0
    .byte 0x0
    .global L_XCE_H115_AVX2
L_XCE_H115_AVX2:
    .byte 0xff
    .byte 0xe0
    .byte 0x90
    .byte 0x90
    .byte 0x90
    .byte 0x90
    .byte 0x90
    .byte 0x90
    .global L_XCE_H115_ARM64
L_XCE_H115_ARM64:
    .byte 0x0
    .byte 0x0
    .byte 0x1f
    .byte 0xd6
    .byte 0x1f
    .byte 0x20
    .byte 0x3
    .byte 0xd5
    .section .iii.ring3,"n"
    .asciz "xii_curated_extended_register_all"
    .text
    .global xii_curated_extended_register_all
    .seh_proc xii_curated_extended_register_all
xii_curated_extended_register_all:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movabsq $0x18, %rax
    pushq %rax
    leaq L_XCE_H052_AVX2(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x33, %rax
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
    leaq L_XCE_H052_ARM64(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x33, %rax
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
    leaq L_XCE_H056_AVX2(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x37, %rax
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
    leaq L_XCE_H056_ARM64(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x37, %rax
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
    leaq L_XCE_H057_AVX2(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x38, %rax
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
    leaq L_XCE_H057_ARM64(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x38, %rax
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
    leaq L_XCE_H059_AVX2(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x3a, %rax
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
    leaq L_XCE_H059_ARM64(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x3a, %rax
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
    leaq L_XCE_H060_AVX2(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x3b, %rax
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
    leaq L_XCE_H060_ARM64(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x3b, %rax
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
    leaq L_XCE_H067_AVX2(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x42, %rax
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
    leaq L_XCE_H067_ARM64(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x42, %rax
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
    leaq L_XCE_H114_AVX2(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x71, %rax
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
    leaq L_XCE_H114_ARM64(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x71, %rax
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
    leaq L_XCE_H115_AVX2(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x72, %rax
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
    leaq L_XCE_H115_ARM64(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    movabsq $0x72, %rax
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
