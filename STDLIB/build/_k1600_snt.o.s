# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "entropy_monitor.iii\0"
L_str_1:
    .ascii "entropy_monitor.iii\0"
L_str_2:
    .ascii "entropy_monitor.iii\0"
L_str_3:
    .ascii "entropy_monitor.iii\0"
L_str_4:
    .ascii "entropy_monitor.iii\0"
L_str_5:
    .ascii "entropy_monitor.iii\0"
L_str_6:
    .ascii "entropy_monitor.iii\0"
L_str_7:
    .ascii "vbd.iii\0"
L_str_8:
    .ascii "vbd.iii\0"
    .section .rodata
L_SNT_OK:
    .quad 0x0
L_SNT_E:
    .quad 0xffffffffffffffff
L_SNT_COMMITTED:
    .quad 0x0
L_SNT_ROLLED_BACK:
    .quad 0x1
L_SNT_INVALID:
    .quad 0xffffffff
L_SNT_WINDOW:
    .quad 0x40
L_SNT_BASE_CAP:
    .quad 0x40
    .section .data
    .global L_SNT_SLOT
L_SNT_SLOT:
    .quad 0xffffffff
    .section .bss
    .global L_SNT_SPEC
L_SNT_SPEC:
    .zero 512
    .global L_SNT_ID
L_SNT_ID:
    .zero 256
    .section .data
    .global L_SNT_INIT
L_SNT_INIT:
    .quad 0x0
    .section .iii.ring3,"n"
    .asciz "sentinel_arm"
    .text
    .global sentinel_arm
    .seh_proc sentinel_arm
sentinel_arm:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movl L_SNT_INIT(%rip), %eax
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
    jz L_if_end_1
    subq $32, %rsp
    callq entropy_init
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movl %eax, L_SNT_INIT(%rip)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_1:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -8(%rbp)
L_loop_top_2:
    movq -8(%rbp), %rax
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
    jz L_loop_end_3
    leaq L_SNT_ID(%rip), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movzbq %al, %rax
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
    jmp L_loop_top_2
L_loop_end_3:
    leaq L_SNT_ID(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq entropy_register_path
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movl -16(%rbp), %eax
    pushq %rax
    movl L_SNT_INVALID(%rip), %eax
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
    movslq L_SNT_E(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_5:
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    movl %eax, L_SNT_SLOT(%rip)
    movslq L_SNT_OK(%rip), %rax
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
    .asciz "sentinel_observe"
    .text
    .global sentinel_observe
    .seh_proc sentinel_observe
sentinel_observe:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movl L_SNT_SLOT(%rip), %eax
    pushq %rax
    movl L_SNT_INVALID(%rip), %eax
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
    movslq L_SNT_E(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_7:
    movq -8(%rbp), %rax
    pushq %rax
    movl L_SNT_SLOT(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq entropy_sample
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
    .asciz "sentinel_seal_baseline"
    .text
    .global sentinel_seal_baseline
    .seh_proc sentinel_seal_baseline
sentinel_seal_baseline:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movl L_SNT_SLOT(%rip), %eax
    pushq %rax
    movl L_SNT_INVALID(%rip), %eax
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
    movslq L_SNT_E(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_9:
    leaq L_SNT_SPEC(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    movl L_SNT_SLOT(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq entropy_spectrum
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    movslq L_SNT_OK(%rip), %rax
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
    movslq L_SNT_E(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_11:
    movq L_SNT_BASE_CAP(%rip), %rax
    pushq %rax
    leaq L_SNT_SPEC(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    movl L_SNT_SLOT(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq entropy_set_baseline
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
    .asciz "sentinel_deviation"
    .text
    .global sentinel_deviation
    .seh_proc sentinel_deviation
sentinel_deviation:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movl L_SNT_SLOT(%rip), %eax
    pushq %rax
    movl L_SNT_INVALID(%rip), %eax
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
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_13:
    leaq L_SNT_SPEC(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    movl L_SNT_SLOT(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq entropy_spectrum
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    leaq L_SNT_SPEC(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    movl L_SNT_SLOT(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq entropy_distance
    addq $32, %rsp
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
    .asciz "sentinel_anomalous"
    .text
    .global sentinel_anomalous
    .seh_proc sentinel_anomalous
sentinel_anomalous:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movl L_SNT_SLOT(%rip), %eax
    pushq %rax
    movl L_SNT_INVALID(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_15
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_15:
    leaq L_SNT_SPEC(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    movl L_SNT_SLOT(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq entropy_spectrum
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    leaq L_SNT_SPEC(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    movl L_SNT_SLOT(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq entropy_baseline_matches
    addq $32, %rsp
    movzbq %al, %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_17
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_17:
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
    .asciz "sentinel_guard"
    .text
    .global sentinel_guard
    .seh_proc sentinel_guard
sentinel_guard:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    subq $32, %rsp
    callq sentinel_anomalous
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_19
    movl -8(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq vbd_rollback
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movslq L_SNT_ROLLED_BACK(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_19:
    movl -8(%rbp), %eax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq vbd_commit
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movslq L_SNT_COMMITTED(%rip), %rax
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
