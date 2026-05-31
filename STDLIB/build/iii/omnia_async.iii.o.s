# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "vec.iiivec.iiibound.iii\0"
L_str_1:
    .ascii "vec.iiibound.iii\0"
L_str_2:
    .ascii "bound.iii\0"
    .section .rodata
L_OMNIA_ASYNC_STATE_READY:
    .quad 0x0
L_OMNIA_ASYNC_STATE_BLOCKED:
    .quad 0x1
L_OMNIA_ASYNC_STATE_COMPLETE:
    .quad 0x2
L_OMNIA_ASYNC_STATE_CANCEL:
    .quad 0x3
L_OMNIA_ASYNC_OK:
    .quad 0x0
L_OMNIA_ASYNC_E_BADID:
    .quad 0xffffffffffffffff
L_OMNIA_ASYNC_E_FULL:
    .quad 0xfffffffffffffffe
L_OMNIA_ASYNC_E_BADSTATE:
    .quad 0xfffffffffffffffd
L_OMNIA_ASYNC_RT_MAX:
    .quad 0x10
L_OMNIA_ASYNC_TASKS_PER_RT:
    .quad 0x40
    .section .bss
    .global L_OMNIA_ASYNC_RT_LIVE
L_OMNIA_ASYNC_RT_LIVE:
    .zero 128
    .global L_OMNIA_ASYNC_RT_ARENA
L_OMNIA_ASYNC_RT_ARENA:
    .zero 128
    .global L_OMNIA_ASYNC_RT_MAX_TASKS
L_OMNIA_ASYNC_RT_MAX_TASKS:
    .zero 128
    .global L_OMNIA_ASYNC_RT_RR_HEAD
L_OMNIA_ASYNC_RT_RR_HEAD:
    .zero 128
    .global L_OMNIA_ASYNC_TASK_LIVE
L_OMNIA_ASYNC_TASK_LIVE:
    .zero 8192
    .global L_OMNIA_ASYNC_TASK_STATE
L_OMNIA_ASYNC_TASK_STATE:
    .zero 8192
    .global L_OMNIA_ASYNC_TASK_KIND
L_OMNIA_ASYNC_TASK_KIND:
    .zero 8192
    .global L_OMNIA_ASYNC_TASK_CTX
L_OMNIA_ASYNC_TASK_CTX:
    .zero 8192
    .global L_OMNIA_ASYNC_TASK_RESULT
L_OMNIA_ASYNC_TASK_RESULT:
    .zero 8192
    .section .iii.ring3,"n"
    .asciz "_async_rt_slot_of"
    .text
    .global L__async_rt_slot_of
    .seh_proc L__async_rt_slot_of
L__async_rt_slot_of:
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
    popq %rax
    movq %rax, -16(%rbp)
    movl L_OMNIA_ASYNC_RT_MAX(%rip), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bnd_index
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
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
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_1:
    leaq L_OMNIA_ASYNC_RT_LIVE(%rip), %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
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
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_3:
    movl -24(%rbp), %eax
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
    .asciz "_async_task_global_idx"
    .text
    .global L__async_task_global_idx
    .seh_proc L__async_task_global_idx
L__async_task_global_idx:
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
    popq %rax
    movq %rax, -24(%rbp)
    movl L_OMNIA_ASYNC_TASKS_PER_RT(%rip), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq bnd_index
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movl -32(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
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
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_5:
    movl -8(%rbp), %eax
    pushq %rax
    movl L_OMNIA_ASYNC_TASKS_PER_RT(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movl -40(%rbp), %eax
    pushq %rax
    movabsq $0x400, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_7
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_7:
    leaq L_OMNIA_ASYNC_TASK_LIVE(%rip), %rax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
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
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_9:
    movl -40(%rbp), %eax
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
    .asciz "async_runtime_new"
    .text
    .global async_runtime_new
    .seh_proc async_runtime_new
async_runtime_new:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movl -32(%rbp), %eax
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
    jz L_if_end_11
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_11:
    movl -32(%rbp), %eax
    pushq %rax
    movl L_OMNIA_ASYNC_TASKS_PER_RT(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    seta %al
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
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
L_loop_top_14:
    movl -40(%rbp), %eax
    pushq %rax
    movl L_OMNIA_ASYNC_RT_MAX(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_15
    leaq L_OMNIA_ASYNC_RT_LIVE(%rip), %rax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
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
    jz L_if_end_17
    movl -48(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
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
    movl -40(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_19:
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_17:
    movl -40(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_14
L_loop_end_15:
    movl -48(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_21
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_21:
    leaq L_OMNIA_ASYNC_RT_LIVE(%rip), %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_OMNIA_ASYNC_RT_ARENA(%rip), %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_OMNIA_ASYNC_RT_MAX_TASKS(%rip), %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_OMNIA_ASYNC_RT_RR_HEAD(%rip), %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
L_loop_top_22:
    movl -56(%rbp), %eax
    pushq %rax
    movl L_OMNIA_ASYNC_TASKS_PER_RT(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_23
    movl -48(%rbp), %eax
    pushq %rax
    movl L_OMNIA_ASYNC_TASKS_PER_RT(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    movl -56(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    leaq L_OMNIA_ASYNC_TASK_LIVE(%rip), %rax
    pushq %rax
    movl -64(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_OMNIA_ASYNC_TASK_STATE(%rip), %rax
    pushq %rax
    movl -64(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_OMNIA_ASYNC_TASK_KIND(%rip), %rax
    pushq %rax
    movl -64(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_OMNIA_ASYNC_TASK_CTX(%rip), %rax
    pushq %rax
    movl -64(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_OMNIA_ASYNC_TASK_RESULT(%rip), %rax
    pushq %rax
    movl -64(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    movl -56(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_22
L_loop_end_23:
    movl -48(%rbp), %eax
    pushq %rax
    popq %rax
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
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "async_runtime_free"
    .text
    .global async_runtime_free
    .seh_proc async_runtime_free
async_runtime_free:
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
    popq %rax
    movq %rax, -16(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L__async_rt_slot_of
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_25
    movslq L_OMNIA_ASYNC_E_BADID(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_25:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
L_loop_top_26:
    movl -32(%rbp), %eax
    pushq %rax
    movl L_OMNIA_ASYNC_TASKS_PER_RT(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_27
    movl -24(%rbp), %eax
    pushq %rax
    movl L_OMNIA_ASYNC_TASKS_PER_RT(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    leaq L_OMNIA_ASYNC_TASK_LIVE(%rip), %rax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_OMNIA_ASYNC_TASK_STATE(%rip), %rax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_OMNIA_ASYNC_TASK_KIND(%rip), %rax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_OMNIA_ASYNC_TASK_CTX(%rip), %rax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_OMNIA_ASYNC_TASK_RESULT(%rip), %rax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    movl -32(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_26
L_loop_end_27:
    leaq L_OMNIA_ASYNC_RT_LIVE(%rip), %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_OMNIA_ASYNC_RT_ARENA(%rip), %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_OMNIA_ASYNC_RT_MAX_TASKS(%rip), %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_OMNIA_ASYNC_RT_RR_HEAD(%rip), %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movslq L_OMNIA_ASYNC_OK(%rip), %rax
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
    .asciz "async_spawn"
    .text
    .global async_spawn
    .seh_proc async_spawn
async_spawn:
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
    movq %rax, -32(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L__async_rt_slot_of
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movl -56(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_29
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_29:
    leaq L_OMNIA_ASYNC_RT_MAX_TASKS(%rip), %rax
    pushq %rax
    movl -56(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rax
    movq %rax, -80(%rbp)
L_loop_top_30:
    movl -72(%rbp), %eax
    pushq %rax
    movl -64(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_31
    movl -56(%rbp), %eax
    pushq %rax
    movl L_OMNIA_ASYNC_TASKS_PER_RT(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    movl -72(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
    leaq L_OMNIA_ASYNC_TASK_LIVE(%rip), %rax
    pushq %rax
    movl -88(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
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
    jz L_if_end_33
    movl -80(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_35
    movl -72(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -80(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_35:
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_33:
    movl -72(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_30
L_loop_end_31:
    movl -80(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_37
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_37:
    movl -56(%rbp), %eax
    pushq %rax
    movl L_OMNIA_ASYNC_TASKS_PER_RT(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    movl -80(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
    leaq L_OMNIA_ASYNC_TASK_LIVE(%rip), %rax
    pushq %rax
    movl -88(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    leaq L_OMNIA_ASYNC_TASK_STATE(%rip), %rax
    pushq %rax
    movl -88(%rbp), %eax
    pushq %rax
    movl L_OMNIA_ASYNC_STATE_READY(%rip), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    leaq L_OMNIA_ASYNC_TASK_KIND(%rip), %rax
    pushq %rax
    movl -88(%rbp), %eax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_OMNIA_ASYNC_TASK_CTX(%rip), %rax
    pushq %rax
    movl -88(%rbp), %eax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_OMNIA_ASYNC_TASK_RESULT(%rip), %rax
    pushq %rax
    movl -88(%rbp), %eax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    movl -80(%rbp), %eax
    pushq %rax
    popq %rax
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
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "async_task_state"
    .text
    .global async_task_state
    .seh_proc async_task_state
async_task_state:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L__async_rt_slot_of
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movl -40(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_39
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_39:
    movq -32(%rbp), %rax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L__async_task_global_idx
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movl -48(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_41
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_41:
    leaq L_OMNIA_ASYNC_TASK_STATE(%rip), %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
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
    .asciz "async_task_kind"
    .text
    .global async_task_kind
    .seh_proc async_task_kind
async_task_kind:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L__async_rt_slot_of
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movl -40(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_43
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_43:
    movq -32(%rbp), %rax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L__async_task_global_idx
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movl -48(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_45
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_45:
    leaq L_OMNIA_ASYNC_TASK_KIND(%rip), %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
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
    .asciz "async_task_ctx"
    .text
    .global async_task_ctx
    .seh_proc async_task_ctx
async_task_ctx:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L__async_rt_slot_of
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movl -40(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_47
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_47:
    movq -32(%rbp), %rax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L__async_task_global_idx
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movl -48(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_49
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_49:
    leaq L_OMNIA_ASYNC_TASK_CTX(%rip), %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
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
    .asciz "async_task_result"
    .text
    .global async_task_result
    .seh_proc async_task_result
async_task_result:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L__async_rt_slot_of
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movl -40(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_51
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_51:
    movq -32(%rbp), %rax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L__async_task_global_idx
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movl -48(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_53
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_53:
    leaq L_OMNIA_ASYNC_TASK_RESULT(%rip), %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
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
    .asciz "async_set_state"
    .text
    .global async_set_state
    .seh_proc async_set_state
async_set_state:
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
    movq %rax, -32(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movl -24(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L__async_rt_slot_of
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movl -56(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_55
    movslq L_OMNIA_ASYNC_E_BADID(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_55:
    movq -40(%rbp), %rax
    pushq %rax
    movl -56(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L__async_task_global_idx
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movl -64(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_57
    movslq L_OMNIA_ASYNC_E_BADID(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_57:
    movl -48(%rbp), %eax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    seta %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_59
    movslq L_OMNIA_ASYNC_E_BADSTATE(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_59:
    leaq L_OMNIA_ASYNC_TASK_STATE(%rip), %rax
    pushq %rax
    movl -64(%rbp), %eax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movslq L_OMNIA_ASYNC_OK(%rip), %rax
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
    .asciz "async_complete"
    .text
    .global async_complete
    .seh_proc async_complete
async_complete:
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
    movq %rax, -32(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L__async_rt_slot_of
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movl -56(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_61
    movslq L_OMNIA_ASYNC_E_BADID(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_61:
    movq -40(%rbp), %rax
    pushq %rax
    movl -56(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L__async_task_global_idx
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movl -64(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_63
    movslq L_OMNIA_ASYNC_E_BADID(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_63:
    leaq L_OMNIA_ASYNC_TASK_RESULT(%rip), %rax
    pushq %rax
    movl -64(%rbp), %eax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_OMNIA_ASYNC_TASK_STATE(%rip), %rax
    pushq %rax
    movl -64(%rbp), %eax
    pushq %rax
    movl L_OMNIA_ASYNC_STATE_COMPLETE(%rip), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movslq L_OMNIA_ASYNC_OK(%rip), %rax
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
    .asciz "async_block"
    .text
    .global async_block
    .seh_proc async_block
async_block:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movl L_OMNIA_ASYNC_STATE_BLOCKED(%rip), %eax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq async_set_state
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
    .asciz "async_cancel"
    .text
    .global async_cancel
    .seh_proc async_cancel
async_cancel:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movl L_OMNIA_ASYNC_STATE_CANCEL(%rip), %eax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq async_set_state
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
    .asciz "async_yield_now"
    .text
    .global async_yield_now
    .seh_proc async_yield_now
async_yield_now:
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
    popq %rax
    movq %rax, -16(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L__async_rt_slot_of
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_65
    movslq L_OMNIA_ASYNC_E_BADID(%rip), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_65:
    leaq L_OMNIA_ASYNC_RT_MAX_TASKS(%rip), %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    leaq L_OMNIA_ASYNC_RT_RR_HEAD(%rip), %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movl -40(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movl -48(%rbp), %eax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_67
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_67:
    leaq L_OMNIA_ASYNC_RT_RR_HEAD(%rip), %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movslq L_OMNIA_ASYNC_OK(%rip), %rax
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
    .asciz "async_next_ready"
    .text
    .global async_next_ready
    .seh_proc async_next_ready
async_next_ready:
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
    popq %rax
    movq %rax, -16(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L__async_rt_slot_of
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_69
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_69:
    leaq L_OMNIA_ASYNC_RT_MAX_TASKS(%rip), %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    leaq L_OMNIA_ASYNC_RT_RR_HEAD(%rip), %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movl -40(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
L_loop_top_70:
    movl -48(%rbp), %eax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_71
    movl -24(%rbp), %eax
    pushq %rax
    movl L_OMNIA_ASYNC_TASKS_PER_RT(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    movl -56(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    leaq L_OMNIA_ASYNC_TASK_LIVE(%rip), %rax
    pushq %rax
    movl -64(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
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
    jz L_if_end_73
    leaq L_OMNIA_ASYNC_TASK_STATE(%rip), %rax
    pushq %rax
    movl -64(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    movl L_OMNIA_ASYNC_STATE_READY(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_75
    movl -56(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movl -72(%rbp), %eax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_77
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_77:
    leaq L_OMNIA_ASYNC_RT_RR_HEAD(%rip), %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    movl -72(%rbp), %eax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movl %edx, (%rax,%rcx,4)
    movl -56(%rbp), %eax
    pushq %rax
    popq %rax
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
L_if_end_75:
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_73:
    movl -56(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movl -56(%rbp), %eax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_79
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_79:
    movl -48(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_70
L_loop_end_71:
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
    .asciz "async_await"
    .text
    .global async_await
    .seh_proc async_await
async_await:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L__async_rt_slot_of
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movl -40(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_81
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_81:
    movq -32(%rbp), %rax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L__async_task_global_idx
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movl -48(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_83
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_83:
    leaq L_OMNIA_ASYNC_TASK_STATE(%rip), %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    movl L_OMNIA_ASYNC_STATE_COMPLETE(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_85
    leaq L_OMNIA_ASYNC_TASK_RESULT(%rip), %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movq (%rax,%rcx,8), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_85:
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
    .asciz "async_select"
    .text
    .global async_select
    .seh_proc async_select
async_select:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L__async_rt_slot_of
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movl -40(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_87
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_87:
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq vec_u64_count
    addq $32, %rsp
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    andq %rcx, %rax
    pushq %rax
    popq %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
L_loop_top_88:
    movl -56(%rbp), %eax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_89
    movl -56(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq vec_u64_at
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movq -64(%rbp), %rax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L__async_task_global_idx
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movl -72(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_91
    leaq L_OMNIA_ASYNC_TASK_STATE(%rip), %rax
    pushq %rax
    movl -72(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    movl L_OMNIA_ASYNC_STATE_COMPLETE(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_93
    movq -64(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_93:
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_91:
    movl -56(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_88
L_loop_end_89:
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
    .asciz "async_alive_count"
    .text
    .global async_alive_count
    .seh_proc async_alive_count
async_alive_count:
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
    popq %rax
    movq %rax, -16(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L__async_rt_slot_of
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movl -24(%rbp), %eax
    pushq %rax
    movabsq $0xffffffff, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    sete %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_95
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_95:
    leaq L_OMNIA_ASYNC_RT_MAX_TASKS(%rip), %rax
    pushq %rax
    movl -24(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movl (%rax,%rcx,4), %eax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
L_loop_top_96:
    movl -48(%rbp), %eax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_97
    movl -24(%rbp), %eax
    pushq %rax
    movl L_OMNIA_ASYNC_TASKS_PER_RT(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    leaq L_OMNIA_ASYNC_TASK_LIVE(%rip), %rax
    pushq %rax
    movl -56(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
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
    jz L_if_end_99
    movl -40(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_99:
    movl -48(%rbp), %eax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_96
L_loop_end_97:
    movl -40(%rbp), %eax
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
