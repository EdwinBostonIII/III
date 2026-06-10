# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "cad.iii\0"
L_str_1:
    .ascii "cad.iii\0"
L_str_2:
    .ascii "cad.iii\0"
L_str_3:
    .ascii "cad.iii\0"
    .section .rodata
L_MHASH_OK:
    .quad 0x0
L_MHASH_E_NULL:
    .quad 0xffffffffffffffff
L_MHASH_SHA_SUITE:
    .quad 0x0
L_DOM_RESOLVE_OK_LEN:
    .quad 0x10
L_DOM_RESOLVE_FAIL_LEN:
    .quad 0x10
L_DOM_RESOLVE_AMBIG_LEN:
    .quad 0x10
L_DOM_RESOLVE_KUF_LEN:
    .quad 0x10
L_DOM_RESOLVE_TAMPER_LEN:
    .quad 0x10
    .section .data
    .global L_DOM_RESOLVE_OK
L_DOM_RESOLVE_OK:
    .byte 0x49
    .byte 0x49
    .byte 0x49
    .byte 0x5f
    .byte 0x52
    .byte 0x45
    .byte 0x53
    .byte 0x4f
    .byte 0x4c
    .byte 0x56
    .byte 0x45
    .byte 0x5f
    .byte 0x4f
    .byte 0x4b
    .byte 0x0
    .byte 0x0
    .global L_DOM_RESOLVE_FAIL
L_DOM_RESOLVE_FAIL:
    .byte 0x49
    .byte 0x49
    .byte 0x49
    .byte 0x5f
    .byte 0x52
    .byte 0x45
    .byte 0x53
    .byte 0x4f
    .byte 0x4c
    .byte 0x56
    .byte 0x45
    .byte 0x5f
    .byte 0x46
    .byte 0x41
    .byte 0x49
    .byte 0x4c
    .global L_DOM_RESOLVE_AMBIG
L_DOM_RESOLVE_AMBIG:
    .byte 0x49
    .byte 0x49
    .byte 0x49
    .byte 0x5f
    .byte 0x52
    .byte 0x45
    .byte 0x53
    .byte 0x4f
    .byte 0x4c
    .byte 0x56
    .byte 0x45
    .byte 0x5f
    .byte 0x41
    .byte 0x4d
    .byte 0x42
    .byte 0x47
    .global L_DOM_RESOLVE_KUF
L_DOM_RESOLVE_KUF:
    .byte 0x49
    .byte 0x49
    .byte 0x49
    .byte 0x5f
    .byte 0x52
    .byte 0x45
    .byte 0x53
    .byte 0x4f
    .byte 0x4c
    .byte 0x56
    .byte 0x45
    .byte 0x5f
    .byte 0x4b
    .byte 0x55
    .byte 0x46
    .byte 0x0
    .global L_DOM_RESOLVE_TAMPER
L_DOM_RESOLVE_TAMPER:
    .byte 0x49
    .byte 0x49
    .byte 0x49
    .byte 0x5f
    .byte 0x52
    .byte 0x45
    .byte 0x53
    .byte 0x4f
    .byte 0x4c
    .byte 0x56
    .byte 0x45
    .byte 0x5f
    .byte 0x54
    .byte 0x41
    .byte 0x4d
    .byte 0x50
    .section .rodata
L_DOM_BABEL_ENV_V1_LEN:
    .quad 0x10
    .section .data
    .global L_DOM_BABEL_ENV_V1
L_DOM_BABEL_ENV_V1:
    .byte 0x42
    .byte 0x41
    .byte 0x42
    .byte 0x45
    .byte 0x4c
    .byte 0x5f
    .byte 0x45
    .byte 0x4e
    .byte 0x56
    .byte 0x5f
    .byte 0x56
    .byte 0x31
    .byte 0x0
    .byte 0x0
    .byte 0x0
    .byte 0x0
    .global L_DOM_PAT_ID
L_DOM_PAT_ID:
    .byte 0x49
    .byte 0x49
    .byte 0x49
    .byte 0x5f
    .byte 0x50
    .byte 0x41
    .byte 0x54
    .byte 0x5f
    .byte 0x49
    .byte 0x44
    .byte 0x0
    .byte 0x0
    .byte 0x0
    .byte 0x0
    .byte 0x0
    .byte 0x0
    .global L_DOM_RESOLVE_BIND
L_DOM_RESOLVE_BIND:
    .byte 0x49
    .byte 0x49
    .byte 0x49
    .byte 0x5f
    .byte 0x52
    .byte 0x45
    .byte 0x53
    .byte 0x4f
    .byte 0x4c
    .byte 0x56
    .byte 0x45
    .byte 0x5f
    .byte 0x42
    .byte 0x49
    .byte 0x4e
    .byte 0x44
    .global L_DOM_RESOLVE_MSG
L_DOM_RESOLVE_MSG:
    .byte 0x49
    .byte 0x49
    .byte 0x49
    .byte 0x5f
    .byte 0x52
    .byte 0x45
    .byte 0x53
    .byte 0x4f
    .byte 0x4c
    .byte 0x56
    .byte 0x45
    .byte 0x5f
    .byte 0x4d
    .byte 0x53
    .byte 0x47
    .byte 0x0
    .global L_DOM_CTX_ID
L_DOM_CTX_ID:
    .byte 0x49
    .byte 0x49
    .byte 0x49
    .byte 0x5f
    .byte 0x43
    .byte 0x43
    .byte 0x54
    .byte 0x58
    .byte 0x5f
    .byte 0x49
    .byte 0x44
    .byte 0x0
    .byte 0x0
    .byte 0x0
    .byte 0x0
    .byte 0x0
    .global L_DOM_CTX_DIG
L_DOM_CTX_DIG:
    .byte 0x49
    .byte 0x49
    .byte 0x49
    .byte 0x5f
    .byte 0x43
    .byte 0x43
    .byte 0x54
    .byte 0x58
    .byte 0x5f
    .byte 0x44
    .byte 0x49
    .byte 0x47
    .byte 0x0
    .byte 0x0
    .byte 0x0
    .byte 0x0
    .global L_DOM_ARENA_INTENT
L_DOM_ARENA_INTENT:
    .byte 0x49
    .byte 0x49
    .byte 0x49
    .byte 0x5f
    .byte 0x41
    .byte 0x52
    .byte 0x45
    .byte 0x4e
    .byte 0x41
    .byte 0x5f
    .byte 0x49
    .byte 0x4e
    .byte 0x54
    .byte 0x45
    .byte 0x4e
    .byte 0x54
    .global L_DOM_TX_SITE
L_DOM_TX_SITE:
    .byte 0x49
    .byte 0x49
    .byte 0x49
    .byte 0x5f
    .byte 0x54
    .byte 0x58
    .byte 0x46
    .byte 0x5f
    .byte 0x53
    .byte 0x49
    .byte 0x54
    .byte 0x45
    .byte 0x0
    .byte 0x0
    .byte 0x0
    .byte 0x0
    .global L_DOM_PAT_TABLE
L_DOM_PAT_TABLE:
    .byte 0x49
    .byte 0x49
    .byte 0x49
    .byte 0x5f
    .byte 0x50
    .byte 0x41
    .byte 0x54
    .byte 0x5f
    .byte 0x54
    .byte 0x41
    .byte 0x42
    .byte 0x4c
    .byte 0x45
    .byte 0x0
    .byte 0x0
    .byte 0x0
    .global L_DOM_SEAL_RESOLVER
L_DOM_SEAL_RESOLVER:
    .byte 0x53
    .byte 0x45
    .byte 0x41
    .byte 0x4c
    .byte 0x5f
    .byte 0x52
    .byte 0x45
    .byte 0x53
    .byte 0x4f
    .byte 0x4c
    .byte 0x56
    .byte 0x45
    .byte 0x52
    .byte 0x0
    .byte 0x0
    .byte 0x0
    .global L_DOM_RIPPLE_EQ_PTN
L_DOM_RIPPLE_EQ_PTN:
    .byte 0x72
    .byte 0x69
    .byte 0x70
    .byte 0x70
    .byte 0x6c
    .byte 0x65
    .byte 0x5f
    .byte 0x65
    .byte 0x71
    .byte 0x75
    .byte 0x69
    .byte 0x76
    .byte 0x5f
    .byte 0x70
    .byte 0x74
    .byte 0x6e
    .section .iii.ring3,"n"
    .asciz "mhash_begin"
    .text
    .global mhash_begin
    .seh_proc mhash_begin
mhash_begin:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movl L_MHASH_SHA_SUITE(%rip), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq cad_begin
    addq $32, %rsp
    movslq %eax, %rax
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
    .asciz "mhash_domain"
    .text
    .global mhash_domain
    .seh_proc mhash_domain
mhash_domain:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq cad_domain
    addq $32, %rsp
    movslq %eax, %rax
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
    .asciz "mhash_payload"
    .text
    .global mhash_payload
    .seh_proc mhash_payload
mhash_payload:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq cad_payload
    addq $32, %rsp
    movslq %eax, %rax
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
    .asciz "mhash_final"
    .text
    .global mhash_final
    .seh_proc mhash_final
mhash_final:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq cad_final
    addq $32, %rsp
    movslq %eax, %rax
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
