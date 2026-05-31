# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "xii_horizon.iiixii_savings.iiixii_rewrite.iiixii_curated_payloads.iiixii_curated_riscv.iiixii_curated_embedded.iiixii_curated_extended.iii\0"
L_str_1:
    .ascii "xii_savings.iiixii_rewrite.iiixii_curated_payloads.iiixii_curated_riscv.iiixii_curated_embedded.iiixii_curated_extended.iii\0"
L_str_2:
    .ascii "xii_rewrite.iiixii_curated_payloads.iiixii_curated_riscv.iiixii_curated_embedded.iiixii_curated_extended.iii\0"
L_str_3:
    .ascii "xii_curated_payloads.iiixii_curated_riscv.iiixii_curated_embedded.iiixii_curated_extended.iii\0"
L_str_4:
    .ascii "xii_curated_riscv.iiixii_curated_embedded.iiixii_curated_extended.iii\0"
L_str_5:
    .ascii "xii_curated_embedded.iiixii_curated_extended.iii\0"
L_str_6:
    .ascii "xii_curated_extended.iii\0"
    .section .data
    .global L_XII_REGISTER_DONE
L_XII_REGISTER_DONE:
    .quad 0x0
    .section .iii.ring3,"n"
    .asciz "xii_register_all"
    .text
    .global xii_register_all
    .seh_proc xii_register_all
xii_register_all:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movzbq L_XII_REGISTER_DONE(%rip), %rax
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
    jz L_if_end_1
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_1:
    subq $32, %rsp
    callq xii_horizon_init
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq xii_savings_init
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq xii_rewrite_tables_reset
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq xii_curated_payloads_register_all
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq xii_curated_riscv_register_all
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq xii_curated_embedded_register_all
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq xii_curated_extended_register_all
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movb %al, L_XII_REGISTER_DONE(%rip)
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
    .asciz "xii_register_done"
    .text
    .global xii_register_done
    .seh_proc xii_register_done
xii_register_done:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movzbq L_XII_REGISTER_DONE(%rip), %rax
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
