# III Stage-0 Ring -2 codegen output (SANCTUM-sealed)
# Spec: SPEC.XII §S14 + DRTM (Intel TXT MLE / TCG D-RTM 1.0).
    .att_syntax
    .section .xii_sanctum.text, "ax", @progbits
    .balign 32
    .global iii_sanctum_mhash_placeholder
iii_sanctum_mhash_placeholder:
    /* D3: 32-byte zero blob; linker patches with section mhash. */
    .byte 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0
    .section .xii_sanctum.rodata, "a", @progbits
    .balign 8
L_sanctum_str_0:
    .ascii "sanctum_rt\0"
    .section .xii_sanctum.text, "ax", @progbits
    .balign 16
    .global L_sanctum_do_thing
    .type L_sanctum_do_thing, @function
L_sanctum_do_thing:
    pushq %rbp
    pushq %r15
    pushq %r14
    pushq %r13
    pushq %r12
    pushq %rbx
    movq %rsp, %rbp
    subq $1024, %rsp
    /* D12: zero local frame (1024 bytes) */
    movq %rsp, %rdi
    xorq %rax, %rax
    movq $128, %rcx
    rep stosq
    movq %rdi, -8(%rbp)
    /* D10: cap-handle verify */
    movq -8(%rbp), %rdi
    callq iii_cap_verify
    xorq %rax, %rax
    pushq %rax
