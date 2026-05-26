# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "hexad_algebra.iiihexad_reach.iii\0"
L_str_1:
    .ascii "hexad_reach.iii\0"
    .section .rodata
L_KBAR_REGION_NONE:
    .quad 0x0
L_KBAR_REGION_BAR0:
    .quad 0x1
L_KBAR_REGION_BAR1:
    .quad 0x2
L_KBAR_REGION_BAR3:
    .quad 0x3
L_KBAR_BAR0_LO:
    .quad 0xfb000000
L_KBAR_BAR0_HI:
    .quad 0xfc000000
L_KBAR_BAR1_LO:
    .quad 0xf800000000
L_KBAR_BAR1_HI:
    .quad 0xf900000000
L_KBAR_BAR3_LO:
    .quad 0xfc00000000
L_KBAR_BAR3_HI:
    .quad 0xfc02000000
    .section .iii.ring3,"n"
    .asciz "katabasis_bar_region"
    .text
    .global katabasis_bar_region
    .seh_proc katabasis_bar_region
katabasis_bar_region:
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
    movq L_KBAR_BAR0_LO(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_1
    movl L_KBAR_REGION_NONE(%rip), %eax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_1:
    movq -16(%rbp), %rax
    pushq %rax
    movq L_KBAR_BAR0_HI(%rip), %rax
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
    movl L_KBAR_REGION_BAR0(%rip), %eax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_3:
    movq -16(%rbp), %rax
    pushq %rax
    movq L_KBAR_BAR1_LO(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_5
    movl L_KBAR_REGION_NONE(%rip), %eax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_5:
    movq -16(%rbp), %rax
    pushq %rax
    movq L_KBAR_BAR1_HI(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_7
    movl L_KBAR_REGION_BAR1(%rip), %eax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_7:
    movq -16(%rbp), %rax
    pushq %rax
    movq L_KBAR_BAR3_LO(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_9
    movl L_KBAR_REGION_NONE(%rip), %eax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_9:
    movq -16(%rbp), %rax
    pushq %rax
    movq L_KBAR_BAR3_HI(%rip), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_11
    movl L_KBAR_REGION_BAR3(%rip), %eax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_11:
    movl L_KBAR_REGION_NONE(%rip), %eax
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
    .asciz "katabasis_bar_region_hexad"
    .text
    .global katabasis_bar_region_hexad
    .seh_proc katabasis_bar_region_hexad
katabasis_bar_region_hexad:
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
    callq katabasis_bar_region
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movl L_KBAR_REGION_NONE(%rip), %eax
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
    movabsq $0x144, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_13:
    movabsq $0x2d8, %rax
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
    .asciz "katabasis_bar_write_admissible"
    .text
    .global katabasis_bar_write_admissible
    .seh_proc katabasis_bar_write_admissible
katabasis_bar_write_admissible:
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
    callq katabasis_bar_region_hexad
    addq $32, %rsp
    movzwq %ax, %rax
    pushq %rax
    movabsq $0x2d8, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq iii_hexad_compose6
    addq $32, %rsp
    movzwq %ax, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq iii_hexad_reachable
    addq $32, %rsp
    movzbq %al, %rax
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
    .asciz "katabasis_bar_cycle_admissible"
    .text
    .global katabasis_bar_cycle_admissible
    .seh_proc katabasis_bar_cycle_admissible
katabasis_bar_cycle_admissible:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movzwq -8(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq katabasis_bar_region_hexad
    addq $32, %rsp
    movzwq %ax, %rax
    pushq %rax
    movzwq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq iii_hexad_compose6
    addq $32, %rsp
    movzwq %ax, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq iii_hexad_reachable
    addq $32, %rsp
    movzbq %al, %rax
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
