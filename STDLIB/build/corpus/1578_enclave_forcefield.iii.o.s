# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "enclave.iii\0"
L_str_1:
    .ascii "enclave.iii\0"
L_str_2:
    .ascii "enclave.iii\0"
L_str_3:
    .ascii "enclave.iii\0"
L_str_4:
    .ascii "enclave.iii\0"
L_str_5:
    .ascii "enclave.iii\0"
L_str_6:
    .ascii "enclave.iii\0"
    .section .rodata
L_KVX_OTHER:
    .quad 0x0
L_KVX_CPUID:
    .quad 0x1
L_KVX_VMMCALL:
    .quad 0x4
L_H_WITNESSED_CALL:
    .quad 0x4
L_INV_GUEST_REGS:
    .quad 0x4
L_ENC_OK:
    .quad 0x0
L_ENC_E_REFUSED:
    .quad 0xffffffffffffffff
L_OFF_SHARED:
    .quad 0x30000
L_OFF_HVSTATE:
    .quad 0x3e800
L_OFF_VMCB:
    .quad 0x500
L_OFF_OOB:
    .quad 0x50000
L_REGION_OOB:
    .quad 0x0
L_REGION_SHARED:
    .quad 0x6
L_REGION_HV_STATE:
    .quad 0x7
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
    callq enc_reset
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movl L_KVX_VMMCALL(%rip), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq enc_hypercall
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movl L_H_WITNESSED_CALL(%rip), %eax
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
    movabsq $0xa, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_1:
    movl L_KVX_OTHER(%rip), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq enc_hypercall_admitted
    addq $32, %rsp
    movl %eax, %eax
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
    jz L_if_end_3
    movabsq $0xb, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_3:
    movl L_KVX_VMMCALL(%rip), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq enc_hypercall_admitted
    addq $32, %rsp
    movl %eax, %eax
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
    jz L_if_end_5
    movabsq $0xc, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_5:
    movl L_KVX_VMMCALL(%rip), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq enc_hypercall_inverse
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movl L_INV_GUEST_REGS(%rip), %eax
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
    movabsq $0xd, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_7:
    movl L_OFF_SHARED(%rip), %eax
    pushq %rax
    movabsq $0x1000, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    movl L_OFF_SHARED(%rip), %eax
    pushq %rax
    movl L_KVX_OTHER(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq enc_declare
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    movslq L_ENC_E_REFUSED(%rip), %rax
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
    movabsq $0xe, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_9:
    movl L_OFF_SHARED(%rip), %eax
    pushq %rax
    movabsq $0x1000, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    movl L_OFF_SHARED(%rip), %eax
    pushq %rax
    movl L_KVX_CPUID(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq enc_declare
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    movslq L_ENC_E_REFUSED(%rip), %rax
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
    movabsq $0xf, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_11:
    movl L_OFF_SHARED(%rip), %eax
    pushq %rax
    movabsq $0x1000, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    movl L_OFF_SHARED(%rip), %eax
    pushq %rax
    movl L_KVX_VMMCALL(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq enc_declare
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    movslq L_ENC_OK(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_13
    movabsq $0x10, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_13:
    subq $32, %rsp
    callq enc_reset
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movl L_OFF_SHARED(%rip), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq enc_region
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movl L_REGION_SHARED(%rip), %eax
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
    movabsq $0x13, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_15:
    movl L_OFF_HVSTATE(%rip), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq enc_region
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movl L_REGION_HV_STATE(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_17
    movabsq $0x12, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_17:
    movl L_OFF_OOB(%rip), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq enc_region
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movl L_REGION_OOB(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_19
    movabsq $0x11, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_19:
    movl L_OFF_SHARED(%rip), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq enc_write_allowed
    addq $32, %rsp
    movl %eax, %eax
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
    jz L_if_end_21
    movabsq $0x14, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_21:
    movl L_OFF_HVSTATE(%rip), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq enc_write_allowed
    addq $32, %rsp
    movl %eax, %eax
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
    jz L_if_end_23
    movabsq $0x15, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_23:
    movl L_OFF_VMCB(%rip), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq enc_write_allowed
    addq $32, %rsp
    movl %eax, %eax
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
    jz L_if_end_25
    movabsq $0x16, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_25:
    movl L_OFF_OOB(%rip), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq enc_write_allowed
    addq $32, %rsp
    movl %eax, %eax
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
    jz L_if_end_27
    movabsq $0x17, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_27:
    movabsq $0x31000, %rax
    pushq %rax
    movabsq $0x30000, %rax
    pushq %rax
    movl L_KVX_VMMCALL(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq enc_declare
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    movslq L_ENC_OK(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_29
    movabsq $0x1e, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_29:
    movabsq $0x30800, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq enc_write_allowed
    addq $32, %rsp
    movl %eax, %eax
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
    jz L_if_end_31
    movabsq $0x1f, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_31:
    movabsq $0x32000, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq enc_write_allowed
    addq $32, %rsp
    movl %eax, %eax
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
    jz L_if_end_33
    movabsq $0x20, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_33:
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
