# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "msvcrt\0"
L_str_1:
    .ascii "msvcrt\0"
L_str_2:
    .ascii "msvcrt\0"
L_str_3:
    .ascii "msvcrt\0"
L_str_4:
    .ascii "keccak.iii\0"
L_str_5:
    .ascii "keccak.iii\0"
L_str_6:
    .ascii "keccak.iii\0"
L_str_7:
    .ascii "keccak.iii\0"
    .section .bss
    .global L_KKD_STATE
L_KKD_STATE:
    .zero 1600
    .global L_KKD_IN
L_KKD_IN:
    .zero 65536
    .global L_KKD_DIG
L_KKD_DIG:
    .zero 256
    .global L_KKD_HEX
L_KKD_HEX:
    .zero 512
    .section .data
    .global L_KKD_PATH_IN
L_KKD_PATH_IN:
    .byte 0x66
    .byte 0x6f
    .byte 0x72
    .byte 0x67
    .byte 0x65
    .byte 0x5f
    .byte 0x6b
    .byte 0x65
    .byte 0x63
    .byte 0x63
    .byte 0x61
    .byte 0x6b
    .byte 0x5f
    .byte 0x69
    .byte 0x6e
    .byte 0x2e
    .byte 0x74
    .byte 0x6d
    .byte 0x70
    .byte 0x0
    .global L_KKD_PATH_OUT
L_KKD_PATH_OUT:
    .byte 0x66
    .byte 0x6f
    .byte 0x72
    .byte 0x67
    .byte 0x65
    .byte 0x5f
    .byte 0x6b
    .byte 0x65
    .byte 0x63
    .byte 0x63
    .byte 0x61
    .byte 0x6b
    .byte 0x5f
    .byte 0x6f
    .byte 0x75
    .byte 0x74
    .byte 0x2e
    .byte 0x74
    .byte 0x6d
    .byte 0x70
    .byte 0x0
    .global L_KKD_MODE_RB
L_KKD_MODE_RB:
    .byte 0x72
    .byte 0x62
    .byte 0x0
    .global L_KKD_MODE_WB
L_KKD_MODE_WB:
    .byte 0x77
    .byte 0x62
    .byte 0x0
    .global L_KKD_HEXCH
L_KKD_HEXCH:
    .byte 0x30
    .byte 0x31
    .byte 0x32
    .byte 0x33
    .byte 0x34
    .byte 0x35
    .byte 0x36
    .byte 0x37
    .byte 0x38
    .byte 0x39
    .byte 0x61
    .byte 0x62
    .byte 0x63
    .byte 0x64
    .byte 0x65
    .byte 0x66
    .section .iii.ring3,"n"
    .asciz "_kkd_hex"
    .text
    .seh_proc L__kkd_hex
L__kkd_hex:
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
L_loop_top_0:
    movl -8(%rbp), %eax
    pushq %rax
    movabsq $0x20, %rax
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
    leaq L_KKD_DIG(%rip), %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    movabsq $0xff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    shrq %cl, %rax
    pushq %rax
    movabsq $0xf, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movl -16(%rbp), %eax
    pushq %rax
    movabsq $0xf, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    leaq L_KKD_HEX(%rip), %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rax
    shlq $1, %rax
    movl %eax, %eax
    pushq %rax
    leaq L_KKD_HEXCH(%rip), %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_KKD_HEX(%rip), %rax
    pushq %rax
    movl -8(%rbp), %eax
    pushq %rax
    popq %rax
    shlq $1, %rax
    movl %eax, %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    leaq L_KKD_HEXCH(%rip), %rax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
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
    leaq L_KKD_MODE_RB(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_KKD_PATH_IN(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fopen
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
    movq -8(%rbp), %rax
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
    jz L_if_end_3
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_3:
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x2000, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    leaq L_KKD_IN(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq fread
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq fclose
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    leaq L_KKD_STATE(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq keccak_state_zero
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1, %rax
    pushq %rax
    movabsq $0x88, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq keccak_pack_rate_dom
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    leaq L_KKD_IN(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_KKD_STATE(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq keccak_absorb
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x88, %rax
    pushq %rax
    movabsq $0x20, %rax
    pushq %rax
    leaq L_KKD_DIG(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_KKD_STATE(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq keccak_squeeze
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq L__kkd_hex
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    leaq L_KKD_MODE_WB(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_KKD_PATH_OUT(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fopen
    addq $32, %rsp
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
    jz L_if_end_5
    movabsq $0x2, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_5:
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x40, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    leaq L_KKD_HEX(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq fwrite
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq fclose
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
