# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "call_context.iii\0"
L_str_1:
    .ascii "call_context.iii\0"
L_str_2:
    .ascii "capability.iii\0"
L_str_3:
    .ascii "capability.iii\0"
L_str_4:
    .ascii "kchain.iii\0"
    .section .iii.ring3,"n"
    .asciz "_accumulate"
    .text
    .seh_proc L__accumulate
L__accumulate:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    # III_CAP_REQUIRED_CHECK (Phase 3 Step 3)
    movq -8(%rbp), %rcx
    subq $32, %rsp
    callq call_context_cap_id
    addq $32, %rsp
    movq %rax, %rcx
    movabsq $0x100, %rdx
    subq $32, %rsp
    callq cap_verify_rights
    addq $32, %rsp
    testb %al, %al
    jnz L_cap_ok_805306401
    movq $0xFFFFFFFFFFFFFFFF, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
L_cap_ok_805306401:
    # III_HEXAD_KIND_CHECK (Phase 3 Step 3)
    movq -8(%rbp), %rcx
    subq $32, %rsp
    callq call_context_hexad_kind
    addq $32, %rsp
    movzbq %al, %rax
    movabsq $0x6, %rcx
    cmpq %rcx, %rax
    je L_hexad_ok_805306401
    movq $0xFFFFFFFFFFFFFFFF, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
L_hexad_ok_805306401:
    # III_K_MAX_CHECK (Phase 3 Step 3)
    movq -8(%rbp), %rcx
    subq $32, %rsp
    callq call_context_kchain_id
    addq $32, %rsp
    movzbq %al, %rcx
    subq $32, %rsp
    callq kchain_current
    addq $32, %rsp
    movabsq $0xbebc200, %rcx
    cmpq %rcx, %rax
    jae L_kmax_ok_805306401
    movq $0xFFFFFFFFFFFFFFFF, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
L_kmax_ok_805306401:
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    shlq $1, %rax
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
    .asciz "_drive_loop"
    .text
    .seh_proc L__drive_loop
L__drive_loop:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    # III_CAP_REQUIRED_CHECK (Phase 3 Step 3)
    movq -8(%rbp), %rcx
    subq $32, %rsp
    callq call_context_cap_id
    addq $32, %rsp
    movq %rax, %rcx
    movabsq $0x300, %rdx
    subq $32, %rsp
    callq cap_verify_rights
    addq $32, %rsp
    testb %al, %al
    jnz L_cap_ok_805306423
    movq $0xFFFFFFFFFFFFFFFF, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
L_cap_ok_805306423:
    # III_HEXAD_KIND_CHECK (Phase 3 Step 3)
    movq -8(%rbp), %rcx
    subq $32, %rsp
    callq call_context_hexad_kind
    addq $32, %rsp
    movzbq %al, %rax
    movabsq $0x6, %rcx
    cmpq %rcx, %rax
    je L_hexad_ok_805306423
    movq $0xFFFFFFFFFFFFFFFF, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
L_hexad_ok_805306423:
    # III_K_MAX_CHECK (Phase 3 Step 3)
    movq -8(%rbp), %rcx
    subq $32, %rsp
    callq call_context_kchain_id
    addq $32, %rsp
    movzbq %al, %rcx
    subq $32, %rsp
    callq kchain_current
    addq $32, %rsp
    movabsq $0x2faf0800, %rcx
    cmpq %rcx, %rax
    jae L_kmax_ok_805306423
    movq $0xFFFFFFFFFFFFFFFF, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
L_kmax_ok_805306423:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
L_loop_top_0:
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
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    seta %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_3
    jmp L_loop_end_1
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_3:
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x10, %rax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq -32(%rbp), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L__accumulate
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
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
    jz L_if_end_5
    jmp L_loop_top_0
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_5:
    movq -16(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_0
L_loop_end_1:
    movq -16(%rbp), %rax
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
    subq $32, %rsp
    callq cap_env_init
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
    jz L_if_end_7
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_7:
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0x300, %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq cap_attenuate
    addq $32, %rsp
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
    jz L_if_end_9
    movabsq $0x2, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_9:
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq kchain_new
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0xffffffffffffffff, %rax
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
    movabsq $0x3, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_11:
    movabsq $0x6, %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq call_context_init_set
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq call_context_new
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
    jz L_if_end_13
    movabsq $0x4, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_13:
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L__drive_loop
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq -40(%rbp), %rax
    pushq %rax
    movabsq $0x1e0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_15
    movabsq $0x5, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_15:
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
