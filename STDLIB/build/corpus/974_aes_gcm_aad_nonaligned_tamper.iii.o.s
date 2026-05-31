# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "aes_gcm.iiiaes_gcm.iiiaes_gcm.iiiaes_gcm.iii\0"
L_str_1:
    .ascii "aes_gcm.iiiaes_gcm.iiiaes_gcm.iii\0"
L_str_2:
    .ascii "aes_gcm.iiiaes_gcm.iii\0"
L_str_3:
    .ascii "aes_gcm.iii\0"
    .section .data
    .global L_K
L_K:
    .byte 0xfe
    .byte 0xff
    .byte 0xe9
    .byte 0x92
    .byte 0x86
    .byte 0x65
    .byte 0x73
    .byte 0x1c
    .byte 0x6d
    .byte 0x6a
    .byte 0x8f
    .byte 0x94
    .byte 0x67
    .byte 0x30
    .byte 0x83
    .byte 0x8
    .global L_IV
L_IV:
    .byte 0xca
    .byte 0xfe
    .byte 0xba
    .byte 0xbe
    .byte 0xfa
    .byte 0xce
    .byte 0xdb
    .byte 0xad
    .byte 0xde
    .byte 0xca
    .byte 0xf8
    .byte 0x88
    .global L_A
L_A:
    .byte 0xfe
    .byte 0xed
    .byte 0xfa
    .byte 0xce
    .byte 0xde
    .byte 0xad
    .byte 0xbe
    .byte 0xef
    .byte 0xfe
    .byte 0xed
    .byte 0xfa
    .byte 0xce
    .byte 0xde
    .byte 0xad
    .byte 0xbe
    .byte 0xef
    .byte 0xab
    .byte 0xad
    .byte 0xda
    .byte 0xd2
    .global L_P
L_P:
    .byte 0xd9
    .byte 0x31
    .byte 0x32
    .byte 0x25
    .byte 0xf8
    .byte 0x84
    .byte 0x6
    .byte 0xe5
    .byte 0xa5
    .byte 0x59
    .byte 0x9
    .byte 0xc5
    .byte 0xaf
    .byte 0xf5
    .byte 0x26
    .byte 0x9a
    .byte 0x86
    .byte 0xa7
    .byte 0xa9
    .byte 0x53
    .byte 0x15
    .byte 0x34
    .byte 0xf7
    .byte 0xda
    .byte 0x2e
    .byte 0x4c
    .byte 0x30
    .byte 0x3d
    .byte 0x8a
    .byte 0x31
    .byte 0x8a
    .byte 0x72
    .byte 0x1c
    .byte 0x3c
    .byte 0xc
    .byte 0x95
    .byte 0x95
    .byte 0x68
    .byte 0x9
    .byte 0x53
    .byte 0x2f
    .byte 0xcf
    .byte 0xe
    .byte 0x24
    .byte 0x49
    .byte 0xa6
    .byte 0xb5
    .byte 0x25
    .byte 0xb1
    .byte 0x6a
    .byte 0xed
    .byte 0xf5
    .byte 0xaa
    .byte 0xd
    .byte 0xe6
    .byte 0x57
    .byte 0xba
    .byte 0x63
    .byte 0x7b
    .byte 0x39
    .global L_CEXP
L_CEXP:
    .byte 0x42
    .byte 0x83
    .byte 0x1e
    .byte 0xc2
    .byte 0x21
    .byte 0x77
    .byte 0x74
    .byte 0x24
    .byte 0x4b
    .byte 0x72
    .byte 0x21
    .byte 0xb7
    .byte 0x84
    .byte 0xd0
    .byte 0xd4
    .byte 0x9c
    .byte 0xe3
    .byte 0xaa
    .byte 0x21
    .byte 0x2f
    .byte 0x2c
    .byte 0x2
    .byte 0xa4
    .byte 0xe0
    .byte 0x35
    .byte 0xc1
    .byte 0x7e
    .byte 0x23
    .byte 0x29
    .byte 0xac
    .byte 0xa1
    .byte 0x2e
    .byte 0x21
    .byte 0xd5
    .byte 0x14
    .byte 0xb2
    .byte 0x54
    .byte 0x66
    .byte 0x93
    .byte 0x1c
    .byte 0x7d
    .byte 0x8f
    .byte 0x6a
    .byte 0x5a
    .byte 0xac
    .byte 0x84
    .byte 0xaa
    .byte 0x5
    .byte 0x1b
    .byte 0xa3
    .byte 0xb
    .byte 0x39
    .byte 0x6a
    .byte 0xa
    .byte 0xac
    .byte 0x97
    .byte 0x3d
    .byte 0x58
    .byte 0xe0
    .byte 0x91
    .global L_TEXP
L_TEXP:
    .byte 0x5b
    .byte 0xc9
    .byte 0x4f
    .byte 0xbc
    .byte 0x32
    .byte 0x21
    .byte 0xa5
    .byte 0xdb
    .byte 0x94
    .byte 0xfa
    .byte 0xe9
    .byte 0x5a
    .byte 0xe7
    .byte 0x12
    .byte 0x1a
    .byte 0x47
    .section .bss
    .global L_CT
L_CT:
    .zero 480
    .global L_TAG
L_TAG:
    .zero 128
    .global L_PTOUT
L_PTOUT:
    .zero 480
    .section .iii.ring3,"n"
    .asciz "cmp"
    .text
    .global L_cmp
    .seh_proc L_cmp
L_cmp:
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
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
L_loop_top_0:
    movq -32(%rbp), %rax
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
    movq -8(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
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
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_3:
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
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_0
L_loop_end_1:
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
    leaq L_K(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    leaq L_IV(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    leaq L_A(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    leaq L_P(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    leaq L_CT(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    leaq L_TAG(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    leaq L_PTOUT(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    leaq L_TEXP(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movabsq $0xc, %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq aes_gcm_init
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x14, %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq aes_gcm_aad
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movq -48(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x3c, %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq aes_gcm_seal
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x3c, %rax
    pushq %rax
    leaq L_CEXP(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_CT(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L_cmp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movq -72(%rbp), %rax
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
    jz L_if_end_5
    movq -72(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_5:
    movabsq $0x10, %rax
    pushq %rax
    leaq L_TEXP(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_TAG(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L_cmp
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -80(%rbp)
    movq -80(%rbp), %rax
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
    jz L_if_end_7
    movabsq $0x3c, %rax
    pushq %rax
    movq -80(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_7:
    movabsq $0xc, %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq aes_gcm_init
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x14, %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq aes_gcm_aad
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movq -64(%rbp), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    movabsq $0x3c, %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq aes_gcm_open
    addq $32, %rsp
    movzbq %al, %rax
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
    movzbq -88(%rbp), %rax
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
    movabsq $0x5a, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_9:
    leaq L_A(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    leaq L_A(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movabsq $0xc, %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq aes_gcm_init
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x14, %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq aes_gcm_aad
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movq -64(%rbp), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    movabsq $0x3c, %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq aes_gcm_open
    addq $32, %rsp
    movzbq %al, %rax
    pushq %rax
    popq %rax
    movq %rax, -96(%rbp)
    leaq L_A(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    leaq L_A(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    xorq %rcx, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movzbq -96(%rbp), %rax
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
    jz L_if_end_11
    movabsq $0x5b, %rax
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
