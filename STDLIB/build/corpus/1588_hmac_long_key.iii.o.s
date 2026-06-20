# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "hmac.iii\0"
L_str_1:
    .ascii "hmac.iii\0"
L_str_2:
    .ascii "hmac.iii\0"
L_str_3:
    .ascii "hmac.iii\0"
L_str_4:
    .ascii "Test Using Larger Than Block-Size Key - Hash Key First\0"
L_str_5:
    .ascii "This is a test using a larger than block-size key and a larger than block-size data. The key needs to be hashed before being used by the HMAC algorithm.\0"
L_str_6:
    .ascii "This is a test using a larger than block-size key and a larger than block-size data. The key needs to be hashed before being used by the HMAC algorithm.\0"
    .section .bss
    .global L_KEY
L_KEY:
    .zero 1048
    .global L_OUT32
L_OUT32:
    .zero 256
    .global L_OUT64
L_OUT64:
    .zero 512
    .section .data
    .global L_EXP_TC6_256
L_EXP_TC6_256:
    .byte 0x60
    .byte 0xe4
    .byte 0x31
    .byte 0x59
    .byte 0x1e
    .byte 0xe0
    .byte 0xb6
    .byte 0x7f
    .byte 0xd
    .byte 0x8a
    .byte 0x26
    .byte 0xaa
    .byte 0xcb
    .byte 0xf5
    .byte 0xb7
    .byte 0x7f
    .byte 0x8e
    .byte 0xb
    .byte 0xc6
    .byte 0x21
    .byte 0x37
    .byte 0x28
    .byte 0xc5
    .byte 0x14
    .byte 0x5
    .byte 0x46
    .byte 0x4
    .byte 0xf
    .byte 0xe
    .byte 0xe3
    .byte 0x7f
    .byte 0x54
    .global L_EXP_TC7_256
L_EXP_TC7_256:
    .byte 0x9b
    .byte 0x9
    .byte 0xff
    .byte 0xa7
    .byte 0x1b
    .byte 0x94
    .byte 0x2f
    .byte 0xcb
    .byte 0x27
    .byte 0x63
    .byte 0x5f
    .byte 0xbc
    .byte 0xd5
    .byte 0xb0
    .byte 0xe9
    .byte 0x44
    .byte 0xbf
    .byte 0xdc
    .byte 0x63
    .byte 0x64
    .byte 0x4f
    .byte 0x7
    .byte 0x13
    .byte 0x93
    .byte 0x8a
    .byte 0x7f
    .byte 0x51
    .byte 0x53
    .byte 0x5c
    .byte 0x3a
    .byte 0x35
    .byte 0xe2
    .global L_EXP_TC7_512
L_EXP_TC7_512:
    .byte 0xe3
    .byte 0x7b
    .byte 0x6a
    .byte 0x77
    .byte 0x5d
    .byte 0xc8
    .byte 0x7d
    .byte 0xba
    .byte 0xa4
    .byte 0xdf
    .byte 0xa9
    .byte 0xf9
    .byte 0x6e
    .byte 0x5e
    .byte 0x3f
    .byte 0xfd
    .byte 0xde
    .byte 0xbd
    .byte 0x71
    .byte 0xf8
    .byte 0x86
    .byte 0x72
    .byte 0x89
    .byte 0x86
    .byte 0x5d
    .byte 0xf5
    .byte 0xa3
    .byte 0x2d
    .byte 0x20
    .byte 0xcd
    .byte 0xc9
    .byte 0x44
    .byte 0xb6
    .byte 0x2
    .byte 0x2c
    .byte 0xac
    .byte 0x3c
    .byte 0x49
    .byte 0x82
    .byte 0xb1
    .byte 0xd
    .byte 0x5e
    .byte 0xeb
    .byte 0x55
    .byte 0xc3
    .byte 0xe4
    .byte 0xde
    .byte 0x15
    .byte 0x13
    .byte 0x46
    .byte 0x76
    .byte 0xfb
    .byte 0x6d
    .byte 0xe0
    .byte 0x44
    .byte 0x60
    .byte 0x65
    .byte 0xc9
    .byte 0x74
    .byte 0x40
    .byte 0xfa
    .byte 0x8c
    .byte 0x6a
    .byte 0x58
    .section .iii.ring3,"n"
    .asciz "eq_n"
    .text
    .seh_proc L_eq_n
L_eq_n:
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
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
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
L_loop_top_0:
    movq -48(%rbp), %rax
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
    movq -32(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
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
    jmp L_loop_top_0
L_loop_end_1:
    movabsq $0x1, %rax
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
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
L_loop_top_4:
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x83, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_5
    leaq L_KEY(%rip), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0xaa, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
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
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_4
L_loop_end_5:
    leaq L_KEY(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movabsq $0x36, %rax
    pushq %rax
    leaq L_str_4(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x83, %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq hmac_sha256
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    leaq L_OUT32(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq hmac_sha256_tag
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x20, %rax
    pushq %rax
    leaq L_EXP_TC6_256(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_OUT32(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L_eq_n
    addq $32, %rsp
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
    jz L_if_end_7
    movabsq $0xa, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_7:
    movabsq $0x98, %rax
    pushq %rax
    leaq L_str_5(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x83, %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq hmac_sha256
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    leaq L_OUT32(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq hmac_sha256_tag
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x20, %rax
    pushq %rax
    leaq L_EXP_TC7_256(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_OUT32(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L_eq_n
    addq $32, %rsp
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
    jz L_if_end_9
    movabsq $0x14, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_9:
    movabsq $0x98, %rax
    pushq %rax
    leaq L_str_6(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x83, %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq hmac_sha512
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    leaq L_OUT64(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq hmac_sha512_tag
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x40, %rax
    pushq %rax
    leaq L_EXP_TC7_512(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_OUT64(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L_eq_n
    addq $32, %rsp
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
    jz L_if_end_11
    movabsq $0x1e, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_11:
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
