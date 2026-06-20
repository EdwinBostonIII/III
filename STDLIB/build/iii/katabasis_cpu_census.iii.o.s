# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "sha256.iii\0"
L_str_1:
    .ascii "cpufeat.iii\0"
L_str_2:
    .ascii "cpufeat.iii\0"
L_str_3:
    .ascii "cpufeat.iii\0"
L_str_4:
    .ascii "cpufeat.iii\0"
L_str_5:
    .ascii "cpufeat.iii\0"
L_str_6:
    .ascii "cpufeat.iii\0"
L_str_7:
    .ascii "cpufeat.iii\0"
L_str_8:
    .ascii "cpufeat.iii\0"
    .section .bss
    .global L_KCPU_FACTS
L_KCPU_FACTS:
    .zero 64
    .section .data
    .global L_KCPU_INIT
L_KCPU_INIT:
    .quad 0x0
    .section .iii.ring3,"n"
    .asciz "katabasis_cpu_census_build"
    .text
    .global katabasis_cpu_census_build
    .seh_proc katabasis_cpu_census_build
katabasis_cpu_census_build:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movzbq L_KCPU_INIT(%rip), %rax
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
    leaq L_KCPU_FACTS(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    subq $32, %rsp
    callq cpufeat_vendor_ebx
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_KCPU_FACTS(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    subq $32, %rsp
    callq cpufeat_vendor_edx
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_KCPU_FACTS(%rip), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    subq $32, %rsp
    callq cpufeat_vendor_ecx
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_KCPU_FACTS(%rip), %rax
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    subq $32, %rsp
    callq cpufeat_fms
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_KCPU_FACTS(%rip), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    subq $32, %rsp
    callq cpufeat_logical_count
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_KCPU_FACTS(%rip), %rax
    pushq %rax
    movabsq $0x5, %rax
    pushq %rax
    subq $32, %rsp
    callq cpufeat_hypervisor_present
    addq $32, %rsp
    movzbq %al, %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_KCPU_FACTS(%rip), %rax
    pushq %rax
    movabsq $0x6, %rax
    pushq %rax
    subq $32, %rsp
    callq cpufeat_hv_ebx
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    leaq L_KCPU_FACTS(%rip), %rax
    pushq %rax
    movabsq $0x7, %rax
    pushq %rax
    subq $32, %rsp
    callq cpufeat_summary
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movq %rdx, (%rax,%rcx,8)
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movb %al, L_KCPU_INIT(%rip)
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
    .asciz "katabasis_cpu_census_reset"
    .text
    .global katabasis_cpu_census_reset
    .seh_proc katabasis_cpu_census_reset
katabasis_cpu_census_reset:
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
    movb %al, L_KCPU_INIT(%rip)
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
    .asciz "katabasis_cpu_census_count"
    .text
    .global katabasis_cpu_census_count
    .seh_proc katabasis_cpu_census_count
katabasis_cpu_census_count:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movabsq $0x8, %rax
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
    .asciz "katabasis_cpu_census_fact"
    .text
    .global katabasis_cpu_census_fact
    .seh_proc katabasis_cpu_census_fact
katabasis_cpu_census_fact:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    subq $32, %rsp
    callq katabasis_cpu_census_build
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movq -8(%rbp), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_3
    leaq L_KCPU_FACTS(%rip), %rax
    pushq %rax
    movq -8(%rbp), %rax
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
L_if_end_3:
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
    .asciz "katabasis_cpu_census_hash"
    .text
    .global katabasis_cpu_census_hash
    .seh_proc katabasis_cpu_census_hash
katabasis_cpu_census_hash:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    subq $32, %rsp
    callq katabasis_cpu_census_build
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -16(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x40, %rax
    pushq %rax
    leaq L_KCPU_FACTS(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq sha256_oneshot_packed
    addq $32, %rsp
    movl %eax, %eax
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
