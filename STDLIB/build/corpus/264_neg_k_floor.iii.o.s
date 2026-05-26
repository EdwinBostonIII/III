# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
    .section .iii.ring3,"n"
    .asciz "_leaf_high_k"
    .text
    .global L__leaf_high_k
    .seh_proc L__leaf_high_k
L__leaf_high_k:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
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
    jae L_kmax_ok_805306374
    movq $0xFFFFFFFFFFFFFFFF, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
L_kmax_ok_805306374:
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movabsq $0xdddd, %rax
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
    .asciz "_caller_low_k"
    .text
    .global L__caller_low_k
    .seh_proc L__caller_low_k
L__caller_low_k:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    # III_K_MAX_CHECK (Phase 3 Step 3)
    movq -8(%rbp), %rcx
    subq $32, %rsp
    callq call_context_kchain_id
    addq $32, %rsp
    movzbq %al, %rcx
    subq $32, %rsp
    callq kchain_current
    addq $32, %rsp
    movabsq $0x17d78400, %rcx
    cmpq %rcx, %rax
    jae L_kmax_ok_805306382
    movq $0xFFFFFFFFFFFFFFFF, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
L_kmax_ok_805306382:
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    # III_K_FLOOR_VIOLATION: caller floor 400000000 below callee floor 800000000 (deficit 400000000)
    popq %rax
    movq %rax, -24(%rbp)
    movq -24(%rbp), %rax
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
