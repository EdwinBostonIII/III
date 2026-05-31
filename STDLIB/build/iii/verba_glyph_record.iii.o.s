# III Stage-0 Ring-3 codegen output
# Microsoft x64 ABI; gas syntax (AT&T); PE/COFF target
    .att_syntax
    .file 1 "<iii-source>"
    .section .rodata
L_str_0:
    .ascii "glyph_core.iiiglyph_core.iiiglyph_core.iiiglyph_core.iiiglyph_core.iiiglyph_core.iiiglyph_core.iiiglyph_core.iii\0"
L_str_1:
    .ascii "glyph_core.iiiglyph_core.iiiglyph_core.iiiglyph_core.iiiglyph_core.iiiglyph_core.iiiglyph_core.iii\0"
L_str_2:
    .ascii "glyph_core.iiiglyph_core.iiiglyph_core.iiiglyph_core.iiiglyph_core.iiiglyph_core.iii\0"
L_str_3:
    .ascii "glyph_core.iiiglyph_core.iiiglyph_core.iiiglyph_core.iiiglyph_core.iii\0"
L_str_4:
    .ascii "glyph_core.iiiglyph_core.iiiglyph_core.iiiglyph_core.iii\0"
L_str_5:
    .ascii "glyph_core.iiiglyph_core.iiiglyph_core.iii\0"
L_str_6:
    .ascii "glyph_core.iiiglyph_core.iii\0"
L_str_7:
    .ascii "glyph_core.iii\0"
    .section .rodata
L_GV3_FORM_RECORD:
    .quad 0x34
L_GV3_REC_MAX_FIELDS:
    .quad 0xb
    .section .iii.ring3,"n"
    .asciz "glyph_record_form_id"
    .text
    .global glyph_record_form_id
    .seh_proc glyph_record_form_id
glyph_record_form_id:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movl L_GV3_FORM_RECORD(%rip), %eax
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
    .asciz "glyph_record_max_fields"
    .text
    .global glyph_record_max_fields
    .seh_proc glyph_record_max_fields
glyph_record_max_fields:
    pushq %rbp
    .seh_pushreg %rbp
    movq %rsp, %rbp
    .seh_setframe %rbp, 0
    subq $1024, %rsp
    .seh_stackalloc 1024
    .seh_endprologue
    movl L_GV3_REC_MAX_FIELDS(%rip), %eax
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
    .asciz "glyph_record_pack_begin"
    .text
    .global glyph_record_pack_begin
    .seh_proc glyph_record_pack_begin
glyph_record_pack_begin:
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
L_if_end_1:
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq gv3_zero
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movl L_GV3_FORM_RECORD(%rip), %eax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x0, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq gv3_write_u32_le
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x8, %rax
    pushq %rax
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq gv3_write_u32_le
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
    .asciz "glyph_record_pack_field"
    .text
    .global glyph_record_pack_field
    .seh_proc glyph_record_pack_field
glyph_record_pack_field:
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
    movq %rax, -40(%rbp)
    movl -16(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movl -24(%rbp), %eax
    pushq %rax
    popq %rax
    movq %rax, -56(%rbp)
    movq -32(%rbp), %rax
    pushq %rax
    popq %rax
    movq %rax, -64(%rbp)
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
    jz L_if_end_3
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
L_if_end_3:
    movl -48(%rbp), %eax
    pushq %rax
    movl L_GV3_REC_MAX_FIELDS(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_5
    movabsq $0x2, %rax
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
L_if_end_5:
    movabsq $0x10, %rax
    pushq %rax
    movl -48(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -72(%rbp)
    movl -56(%rbp), %eax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq gv3_write_u32_le
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movq -64(%rbp), %rax
    pushq %rax
    movq -40(%rbp), %rax
    pushq %rax
    movq -72(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq gv3_write_u64_le
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
    .asciz "glyph_record_pack_finalise"
    .text
    .global glyph_record_pack_finalise
    .seh_proc glyph_record_pack_finalise
glyph_record_pack_finalise:
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
    jz L_if_end_7
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
L_if_end_7:
    movl -32(%rbp), %eax
    pushq %rax
    movl L_GV3_REC_MAX_FIELDS(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    seta %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_9
    movabsq $0x2, %rax
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
L_if_end_9:
    movl -32(%rbp), %eax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq gv3_write_u32_le
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movabsq $0x8, %rax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    movl %eax, %eax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rdx
    subq $32, %rsp
    callq gv3_write_u32_le
    addq $32, %rsp
    movslq %eax, %rax
    pushq %rax
    popq %rax
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq gv3_compute_mhash
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
    .asciz "glyph_record_unpack_count"
    .text
    .global glyph_record_unpack_count
    .seh_proc glyph_record_unpack_count
glyph_record_unpack_count:
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
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq gv3_form_id
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movl L_GV3_FORM_RECORD(%rip), %eax
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
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq gv3_validate
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
    jz L_if_end_15
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_15:
    movq -16(%rbp), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq gv3_read_u32_le
    addq $32, %rsp
    movl %eax, %eax
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
    .asciz "glyph_record_unpack_field_id"
    .text
    .global glyph_record_unpack_field_id
    .seh_proc glyph_record_unpack_field_id
glyph_record_unpack_field_id:
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
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq gv3_form_id
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movl L_GV3_FORM_RECORD(%rip), %eax
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
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_19:
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq gv3_validate
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
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq gv3_read_u32_le
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movl -40(%rbp), %eax
    pushq %rax
    movl L_GV3_REC_MAX_FIELDS(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    seta %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_23
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_23:
    movl -32(%rbp), %eax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_25
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_25:
    movabsq $0x10, %rax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq gv3_read_u32_le
    addq $32, %rsp
    movl %eax, %eax
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
    .asciz "glyph_record_unpack_field_value"
    .text
    .global glyph_record_unpack_field_value
    .seh_proc glyph_record_unpack_field_value
glyph_record_unpack_field_value:
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
    jz L_if_end_27
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_27:
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq gv3_form_id
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movl L_GV3_FORM_RECORD(%rip), %eax
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
    movq -24(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq gv3_validate
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
    jz L_if_end_31
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_31:
    movq -24(%rbp), %rax
    pushq %rax
    movabsq $0x8, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq gv3_read_u32_le
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    popq %rax
    movq %rax, -40(%rbp)
    movl -40(%rbp), %eax
    pushq %rax
    movl L_GV3_REC_MAX_FIELDS(%rip), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    seta %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_33
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_33:
    movl -32(%rbp), %eax
    pushq %rax
    movl -40(%rbp), %eax
    pushq %rax
    popq %rcx
    popq %rax
    cmpq %rcx, %rax
    setae %al
    movzbq %al, %rax
    pushq %rax
    popq %rax
    testq %rax, %rax
    jz L_if_end_35
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_35:
    movabsq $0x10, %rax
    pushq %rax
    movl -32(%rbp), %eax
    pushq %rax
    popq %rax
    pushq %rax
    movabsq $0xc, %rax
    pushq %rax
    popq %rcx
    popq %rax
    imulq %rcx, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    movabsq $0x4, %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rax
    movq %rax, -48(%rbp)
    movq -24(%rbp), %rax
    pushq %rax
    movq -48(%rbp), %rax
    pushq %rax
    popq %rcx
    popq %rax
    addq %rcx, %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq gv3_read_u64_le
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
    .asciz "glyph_record_validate"
    .text
    .global glyph_record_validate
    .seh_proc glyph_record_validate
glyph_record_validate:
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
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq gv3_form_id
    addq $32, %rsp
    movl %eax, %eax
    pushq %rax
    movl L_GV3_FORM_RECORD(%rip), %eax
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
    movabsq $0x0, %rax
    pushq %rax
    popq %rax
    movq %rbp, %rsp
    popq %rbp
    retq
    movq $0, %rax
    pushq %rax
    popq %rax
L_if_end_39:
    movq -16(%rbp), %rax
    pushq %rax
    popq %rcx
    subq $32, %rsp
    callq gv3_validate
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
