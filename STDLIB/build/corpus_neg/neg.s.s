# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
    .section .iii.ring3,"n"
    .asciz "_leaf_high"
    .text
    .global L__leaf_high
    .seh_proc L__leaf_high
L__leaf_high:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp /* locals reserve, 16-aligned */
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    # III_CAP_REQUIRED_CHECK (Phase 3 Step 3)
    movq -8(%rbp), %rcx
    subq $32, %rsp
    callq call_context_cap_id
    addq $32, %rsp
    movq %rax, %rcx
    movabsq $0x200, %rdx
    subq $32, %rsp
    callq cap_verify_rights
    addq $32, %rsp
    testb %al, %al
    jnz L_cap_ok_805306374
    movq $0xFFFFFFFFFFFFFFFF, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
L_cap_ok_805306374:
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movabsq $0xbbbb, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    movq $0, %rax /* implicit return */
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "_caller_low"
    .text
    .global L__caller_low
    .seh_proc L__caller_low
L__caller_low:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp /* locals reserve, 16-aligned */
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
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
    jnz L_cap_ok_805306382
    movq $0xFFFFFFFFFFFFFFFF, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
L_cap_ok_805306382:
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    # III_CAP_FLOW_VIOLATION: caller mask 0x100 insufficient for callee mask 0x200 (missing 0x200)
    leaq L_r(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    movq $0, %rax /* implicit return */
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
    subq $1024, %rsp /* locals reserve, 16-aligned */
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
    movq $0, %rax /* implicit return */
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
