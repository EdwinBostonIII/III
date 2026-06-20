# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "corpus_coverage.iii\0"
L_str_1:
    .ascii "corpus_coverage.iii\0"
L_str_2:
    .ascii "corpus_coverage.iii\0"
L_str_3:
    .ascii "corpus_coverage.iii\0"
L_str_4:
    .ascii "corpus_coverage.iii\0"
L_str_5:
    .ascii "corpus_coverage.iii\0"
L_str_6:
    .ascii "corpus_coverage.iii\0"
L_str_7:
    .ascii "corpus_coverage.iii\0"
L_str_8:
    .ascii "corpus_coverage.iii\0"
L_str_9:
    .ascii "corpus_coverage.iii\0"
L_str_10:
    .ascii "corpus_coverage.iii\0"
L_str_11:
    .ascii "corpus_coverage.iii\0"
L_str_12:
    .ascii "fs.iii\0"
L_str_13:
    .ascii "fs.iii\0"
L_str_14:
    .ascii "fs.iii\0"
L_str_15:
    .ascii "fs.iii\0"
L_str_16:
    .ascii "fs.iii\0"
L_str_17:
    .ascii "fs.iii\0"
L_str_18:
    .ascii "fs.iii\0"
L_str_19:
    .ascii "fs.iii\0"
L_str_20:
    .ascii "capability.iii\0"
L_str_21:
    .ascii "capability.iii\0"
L_str_22:
    .ascii "cad.iii\0"
L_str_23:
    .ascii "./iii_cov_kat\0"
L_str_24:
    .ascii "/mods\0"
L_str_25:
    .ascii "/corpus\0"
L_str_26:
    .ascii "/alpha.iii\0"
L_str_27:
    .ascii "/beta.iii\0"
L_str_28:
    .ascii "/gamma.iii\0"
L_str_29:
    .ascii "/prespec.iii\0"
L_str_30:
    .ascii "/t1.iii\0"
L_str_31:
    .ascii "/t2.iii\0"
L_str_32:
    .ascii "/t3.iii\0"
L_str_33:
    .ascii "/report.txt\0"
L_str_34:
    .ascii "module alpha\0"
L_str_35:
    .ascii "/* alpha_orphan named in a comment must not cover */\0"
L_str_36:
    .ascii "extern fn beta_used() -> u32\0"
L_str_37:
    .ascii "fn alpha_used() -> u32 @export { let s : u64 = (\0"
L_str_38:
    .ascii "alpha_orphan\0"
L_str_39:
    .ascii " as u64) return beta_used() }\0"
L_str_40:
    .ascii "fn alpha_orphan() -> u32 @export { return 7u32 }\0"
L_str_41:
    .ascii "fn alpha_helper() -> u32 { return 1u32 }\0"
L_str_42:
    .ascii "fn alpha_gen<T>(v: T) -> T @specialize(u32) @export { return v }\0"
L_str_43:
    .ascii "module beta\0"
L_str_44:
    .ascii "fn beta_used() -> u32 @export { return 3u32 }\0"
L_str_45:
    .ascii "module gamma\0"
L_str_46:
    .ascii "fn gamma_orphan() -> u32 @export { return 9u32 }\0"
L_str_47:
    .ascii "module prespec\0"
L_str_48:
    .ascii "fn pre_table() -> u64 @export { return gamma_orphan as u64 }\0"
L_str_49:
    .ascii "module t1\0"
L_str_50:
    .ascii "extern fn alpha_used() -> u32\0"
L_str_51:
    .ascii "fn main() -> u64 { return alpha_used() as u64 }\0"
L_str_52:
    .ascii "alpha_orphan\0"
L_str_53:
    .ascii "gamma_orphan\0"
L_str_54:
    .ascii "module t2\0"
L_str_55:
    .ascii "extern fn alpha_orphan() -> u32\0"
L_str_56:
    .ascii "fn main() -> u64 { return alpha_orphan() as u64 }\0"
L_str_57:
    .ascii "gamma_orphan\0"
L_str_58:
    .ascii "module t3\0"
L_str_59:
    .ascii "extern fn gamma_orphan() -> u32\0"
L_str_60:
    .ascii "fn main() -> u64 { return gamma_orphan() as u64 }\0"
    .section .bss
    .global L_P_ROOT
L_P_ROOT:
    .zero 512
    .global L_P_MODS
L_P_MODS:
    .zero 512
    .global L_P_CORP
L_P_CORP:
    .zero 512
    .global L_P_ALPHA
L_P_ALPHA:
    .zero 512
    .global L_P_BETA
L_P_BETA:
    .zero 512
    .global L_P_GAMMA
L_P_GAMMA:
    .zero 512
    .global L_P_PRES
L_P_PRES:
    .zero 512
    .global L_P_T1
L_P_T1:
    .zero 512
    .global L_P_T2
L_P_T2:
    .zero 512
    .global L_P_T3
L_P_T3:
    .zero 512
    .global L_P_REP
L_P_REP:
    .zero 512
    .global L_KC
L_KC:
    .zero 16384
    .section .data
    .global L_KC_LEN
L_KC_LEN:
    .quad 0x0
    .section .bss
    .global L_NAMEBUF
L_NAMEBUF:
    .zero 512
    .global L_SEAL_A
L_SEAL_A:
    .zero 256
    .global L_SEAL_B
L_SEAL_B:
    .zero 256
    .global L_SEAL_C
L_SEAL_C:
    .zero 256
    .global L_REPBUF
L_REPBUF:
    .zero 2048
    .section .iii.ring3,"n"
    .asciz "setlit"
    .text
    .seh_proc L_setlit
L_setlit:
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
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
L_loop_top_0:
    movq -48(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_1
    movq -32(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movq -48(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_0
L_loop_end_1:
    movq -32(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "catlit"
    .text
    .seh_proc L_catlit
L_catlit:
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
    movq %r9, -32(%rbp)
    movq -8(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
L_loop_top_2:
    movzbq -64(%rbp), %rax
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
    jz L_loop_end_3
    movq -56(%rbp), %rax
    pushq %rax
    movabsq $0x3f, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_else_4
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_if_end_5
L_if_else_4:
    movq -48(%rbp), %rax
    pushq %rax
    movq -56(%rbp), %rax
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
    jz L_if_else_6
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_if_end_7
L_if_else_6:
    movq -56(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_7:
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_5:
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_2
L_loop_end_3:
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
L_loop_top_8:
    movq -72(%rbp), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_9
    movq -40(%rbp), %rax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movq -72(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_8
L_loop_end_9:
    movq -24(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -80(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
L_loop_top_10:
    movq -88(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_11
    movq -40(%rbp), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    movq -88(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    movq -80(%rbp), %rax
    pushq %rax
    movq -88(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movq -88(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -88(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_10
L_loop_end_11:
    movq -40(%rbp), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "kc_reset"
    .text
    .seh_proc L_kc_reset
L_kc_reset:
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
    movq %rax, L_KC_LEN(%rip)
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "kc_lit"
    .text
    .seh_proc L_kc_lit
L_kc_lit:
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
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
L_loop_top_12:
    movq -32(%rbp), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setb %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_loop_end_13
    leaq L_KC(%rip), %rax
    pushq %rax
    movq L_KC_LEN(%rip), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movq -32(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_12
L_loop_end_13:
    movq L_KC_LEN(%rip), %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, L_KC_LEN(%rip)
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "kc_byte"
    .text
    .seh_proc L_kc_byte
L_kc_byte:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    leaq L_KC(%rip), %rax
    pushq %rax
    movq L_KC_LEN(%rip), %rax
    pushq %rax
    movzbq -8(%rbp), %rax
    pushq %rax
    popq %rdx
    popq %rcx
    popq %rax
    movb %dl, (%rax,%rcx,1)
    movq L_KC_LEN(%rip), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, L_KC_LEN(%rip)
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "kc_nl"
    .text
    .seh_proc L_kc_nl
L_kc_nl:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movabsq $0xa, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_kc_byte
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq $0, %rax
    pushq %rax
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    .seh_endproc
    .section .iii.ring3,"n"
    .asciz "kc_write"
    .text
    .seh_proc L_kc_write
L_kc_write:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    movq %rdx, -16(%rbp)
    movabsq $0x2, %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq fs_open
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    movq -24(%rbp), %rax
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
    jz L_if_end_15
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    negq %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_15:
    movq L_KC_LEN(%rip), %rax
    pushq %rax
    leaq L_KC(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq fs_write
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq fs_close
    addq $32, %rsp
    movslq %eax, %rax
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
    .section .iii.ring3,"n"
    .asciz "name_is"
    .text
    .seh_proc L_name_is
L_name_is:
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
    leaq L_NAMEBUF(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq cov_uncovered_name
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -32(%rbp)
    movq -32(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
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
    leaq L_NAMEBUF(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq -16(%rbp), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
L_loop_top_18:
    movzbq -72(%rbp), %rax
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
    jz L_loop_end_19
    movq -56(%rbp), %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_else_20
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_if_end_21
L_if_else_20:
    movq -40(%rbp), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    movq -56(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_else_22
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_if_end_23
L_if_else_22:
    movq -56(%rbp), %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_23:
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_21:
    movq $0, %rax
    pushq %rax
    popq %rax
    jmp L_loop_top_18
L_loop_end_19:
    movzbq -64(%rbp), %rax
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
    .asciz "teardown"
    .text
    .seh_proc L_teardown
L_teardown:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movq %rcx, -8(%rbp)
    leaq L_P_ALPHA(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fs_delete
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    leaq L_P_BETA(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fs_delete
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    leaq L_P_GAMMA(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fs_delete
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    leaq L_P_PRES(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fs_delete
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    leaq L_P_T1(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fs_delete
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    leaq L_P_T2(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fs_delete
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    leaq L_P_T3(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fs_delete
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    leaq L_P_REP(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fs_delete
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    leaq L_P_MODS(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fs_rmdir
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    leaq L_P_CORP(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fs_rmdir
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    leaq L_P_ROOT(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -8(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fs_rmdir
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
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
    movabsq $0x0, %rax
    pushq %rax
    movabsq $0xe, %rax
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
    movabsq $0xd, %rax
    pushq %rax
    leaq L_str_23(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_P_ROOT(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L_setlit
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x5, %rax
    pushq %rax
    leaq L_str_24(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_P_ROOT(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_P_MODS(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_catlit
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x7, %rax
    pushq %rax
    leaq L_str_25(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_P_ROOT(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_P_CORP(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_catlit
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0xa, %rax
    pushq %rax
    leaq L_str_26(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_P_MODS(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_P_ALPHA(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_catlit
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x9, %rax
    pushq %rax
    leaq L_str_27(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_P_MODS(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_P_BETA(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_catlit
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0xa, %rax
    pushq %rax
    leaq L_str_28(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_P_MODS(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_P_GAMMA(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_catlit
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_29(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_P_MODS(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_P_PRES(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_catlit
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x7, %rax
    pushq %rax
    leaq L_str_30(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_P_CORP(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_P_T1(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_catlit
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x7, %rax
    pushq %rax
    leaq L_str_31(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_P_CORP(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_P_T2(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_catlit
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x7, %rax
    pushq %rax
    leaq L_str_32(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_P_CORP(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_P_T3(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_catlit
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0xb, %rax
    pushq %rax
    leaq L_str_33(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_P_ROOT(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_P_REP(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    popq %r9
    subq $32, %rsp
    callq L_catlit
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_teardown
    addq $32, %rsp
    pushq %rax
    popq %rax
    leaq L_P_ROOT(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fs_mkdir
    addq $32, %rsp
    movslq %eax, %rax
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
    movabsq $0x1, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_25:
    leaq L_P_MODS(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fs_mkdir
    addq $32, %rsp
    movslq %eax, %rax
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
    movabsq $0x2, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_27:
    leaq L_P_CORP(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq fs_mkdir
    addq $32, %rsp
    movslq %eax, %rax
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
    jz L_if_end_29
    movabsq $0x3, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_29:
    subq $32, %rsp
    callq L_kc_reset
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_34(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_kc_lit
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq L_kc_nl
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x34, %rax
    pushq %rax
    leaq L_str_35(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_kc_lit
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq L_kc_nl
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x1c, %rax
    pushq %rax
    leaq L_str_36(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_kc_lit
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq L_kc_nl
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x30, %rax
    pushq %rax
    leaq L_str_37(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_kc_lit
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x22, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_kc_byte
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_38(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_kc_lit
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x22, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_kc_byte
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x1d, %rax
    pushq %rax
    leaq L_str_39(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_kc_lit
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq L_kc_nl
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x30, %rax
    pushq %rax
    leaq L_str_40(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_kc_lit
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq L_kc_nl
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x28, %rax
    pushq %rax
    leaq L_str_41(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_kc_lit
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq L_kc_nl
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x40, %rax
    pushq %rax
    leaq L_str_42(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_kc_lit
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq L_kc_nl
    addq $32, %rsp
    pushq %rax
    popq %rax
    leaq L_P_ALPHA(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_kc_write
    addq $32, %rsp
    movslq %eax, %rax
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
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_teardown
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_31:
    subq $32, %rsp
    callq L_kc_reset
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0xb, %rax
    pushq %rax
    leaq L_str_43(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_kc_lit
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq L_kc_nl
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x2d, %rax
    pushq %rax
    leaq L_str_44(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_kc_lit
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq L_kc_nl
    addq $32, %rsp
    pushq %rax
    popq %rax
    leaq L_P_BETA(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_kc_write
    addq $32, %rsp
    movslq %eax, %rax
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
    jz L_if_end_33
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_teardown
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x5, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_33:
    subq $32, %rsp
    callq L_kc_reset
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_45(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_kc_lit
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq L_kc_nl
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x30, %rax
    pushq %rax
    leaq L_str_46(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_kc_lit
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq L_kc_nl
    addq $32, %rsp
    pushq %rax
    popq %rax
    leaq L_P_GAMMA(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_kc_write
    addq $32, %rsp
    movslq %eax, %rax
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
    jz L_if_end_35
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_teardown
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x6, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_35:
    subq $32, %rsp
    callq L_kc_reset
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0xe, %rax
    pushq %rax
    leaq L_str_47(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_kc_lit
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq L_kc_nl
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x3c, %rax
    pushq %rax
    leaq L_str_48(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_kc_lit
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq L_kc_nl
    addq $32, %rsp
    pushq %rax
    popq %rax
    leaq L_P_PRES(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_kc_write
    addq $32, %rsp
    movslq %eax, %rax
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
    jz L_if_end_37
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_teardown
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x7, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_37:
    subq $32, %rsp
    callq L_kc_reset
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x9, %rax
    pushq %rax
    leaq L_str_49(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_kc_lit
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq L_kc_nl
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x1d, %rax
    pushq %rax
    leaq L_str_50(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_kc_lit
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq L_kc_nl
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x2f, %rax
    pushq %rax
    leaq L_str_51(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_kc_lit
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq L_kc_nl
    addq $32, %rsp
    pushq %rax
    popq %rax
    leaq L_P_T1(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_kc_write
    addq $32, %rsp
    movslq %eax, %rax
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
    jz L_if_end_39
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_teardown
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_39:
    leaq L_P_CORP(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_P_MODS(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq cov_audit
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -24(%rbp)
    subq $32, %rsp
    callq cov_overflow
    addq $32, %rsp
    movzbq %al, %rax
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
    jz L_if_end_41
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_teardown
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0xa, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_41:
    subq $32, %rsp
    callq cov_n_trunc
    addq $32, %rsp
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
    jz L_if_end_43
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_teardown
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0xb, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_43:
    subq $32, %rsp
    callq cov_n_exports
    addq $32, %rsp
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_45
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_teardown
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0xc, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_45:
    subq $32, %rsp
    callq cov_n_files
    addq $32, %rsp
    pushq %rax
    movabsq $0x3, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_47
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_teardown
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0xd, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_47:
    subq $32, %rsp
    callq cov_n_reffiles
    addq $32, %rsp
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_49
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_teardown
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0xe, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_49:
    subq $32, %rsp
    callq cov_n_dup
    addq $32, %rsp
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
    jz L_if_end_51
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_teardown
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0xf, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_51:
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_53
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_teardown
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x10, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_53:
    subq $32, %rsp
    callq cov_n_uncovered
    addq $32, %rsp
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_55
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_teardown
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x11, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_55:
    subq $32, %rsp
    callq cov_verdict
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_57
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_teardown
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x12, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_57:
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_52(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L_name_is
    addq $32, %rsp
    movzbq %al, %rax
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
    jz L_if_end_59
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_teardown
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x13, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_59:
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_53(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x1, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L_name_is
    addq $32, %rsp
    movzbq %al, %rax
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
    jz L_if_end_61
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_teardown
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x14, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_61:
    leaq L_SEAL_A(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq cov_seal
    addq $32, %rsp
    movslq %eax, %rax
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
    jz L_if_end_63
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_teardown
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x15, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_63:
    leaq L_P_REP(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq cov_report_write
    addq $32, %rsp
    movslq %eax, %rax
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
    jz L_if_end_65
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_teardown
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x16, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_65:
    movabsq $0x1, %rax
    pushq %rax
    leaq L_P_REP(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq fs_open
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
    jz L_if_end_67
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_teardown
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x17, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_67:
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq fs_size
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movq -40(%rbp), %rax
    pushq %rax
    leaq L_REPBUF(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq fs_read
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq -32(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq fs_close
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movq -48(%rbp), %rax
    pushq %rax
    movabsq $0x1a, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_69
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_teardown
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x18, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_69:
    leaq L_REPBUF(%rip), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    movabsq $0x61, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_71
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_teardown
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x19, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_71:
    leaq L_REPBUF(%rip), %rax
    pushq %rax
    movabsq $0xd, %rax
    pushq %rax
    popq %rcx
    popq %rax
    movzbq (%rax,%rcx,1), %rax
    pushq %rax
    movabsq $0x67, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_73
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_teardown
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x1a, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_73:
    subq $32, %rsp
    callq L_kc_reset
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x9, %rax
    pushq %rax
    leaq L_str_54(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_kc_lit
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq L_kc_nl
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x1f, %rax
    pushq %rax
    leaq L_str_55(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_kc_lit
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq L_kc_nl
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x31, %rax
    pushq %rax
    leaq L_str_56(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_kc_lit
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq L_kc_nl
    addq $32, %rsp
    pushq %rax
    popq %rax
    leaq L_P_T2(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_kc_write
    addq $32, %rsp
    movslq %eax, %rax
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
    jz L_if_end_75
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_teardown
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x1e, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_75:
    leaq L_P_CORP(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_P_MODS(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq cov_audit
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq -56(%rbp), %rax
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
    jz L_if_end_77
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_teardown
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x1f, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_77:
    movabsq $0xc, %rax
    pushq %rax
    leaq L_str_57(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq L_name_is
    addq $32, %rsp
    movzbq %al, %rax
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
    jz L_if_end_79
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_teardown
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x20, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_79:
    subq $32, %rsp
    callq cov_verdict
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movabsq $0x2, %rax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setne %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_81
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_teardown
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x21, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_81:
    subq $32, %rsp
    callq L_kc_reset
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x9, %rax
    pushq %rax
    leaq L_str_58(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_kc_lit
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq L_kc_nl
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x1f, %rax
    pushq %rax
    leaq L_str_59(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_kc_lit
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq L_kc_nl
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x31, %rax
    pushq %rax
    leaq L_str_60(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_kc_lit
    addq $32, %rsp
    pushq %rax
    popq %rax
    subq $32, %rsp
    callq L_kc_nl
    addq $32, %rsp
    pushq %rax
    popq %rax
    leaq L_P_T3(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq L_kc_write
    addq $32, %rsp
    movslq %eax, %rax
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
    jz L_if_end_83
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_teardown
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x28, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_83:
    leaq L_P_CORP(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_P_MODS(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq cov_audit
    addq $32, %rsp
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
    movq -64(%rbp), %rax
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
    jz L_if_end_85
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_teardown
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x29, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_85:
    subq $32, %rsp
    callq cov_verdict
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
    jz L_if_end_87
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_teardown
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x2a, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_87:
    leaq L_SEAL_B(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq cov_seal
    addq $32, %rsp
    movslq %eax, %rax
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
    jz L_if_end_89
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_teardown
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x2b, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_89:
    leaq L_P_CORP(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_P_MODS(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rdx
    popq %r8
    subq $32, %rsp
    callq cov_audit
    addq $32, %rsp
    pushq %rax
    popq %rax
    leaq L_SEAL_C(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq cov_seal
    addq $32, %rsp
    movslq %eax, %rax
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
    jz L_if_end_91
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_teardown
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x2c, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_91:
    leaq L_SEAL_C(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_SEAL_B(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq cad_eq
    addq $32, %rsp
    movzbq %al, %rax
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
    jz L_if_end_93
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_teardown
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x2d, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_93:
    leaq L_SEAL_B(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    leaq L_SEAL_A(%rip), %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq cad_eq
    addq $32, %rsp
    movzbq %al, %rax
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
    jz L_if_end_95
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_teardown
    addq $32, %rsp
    pushq %rax
    popq %rax
    movabsq $0x2e, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_95:
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq L_teardown
    addq $32, %rsp
    pushq %rax
    popq %rax
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
