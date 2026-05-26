#!/usr/bin/env python3
"""Generate the COMPILER/BOOT/cg_rm2.iii literal-table fragment.

Build-time helper. NOT shipped in the boot pipeline.
Run from this directory:
    python _gen_cg_rm2_lits.py > _cg_rm2_lits.iii.frag
"""
import sys

LITS = [
    ("SECT_TEXT_PE",         b'    .section .xii_sanctum.text, "xr"\n'),
    ("SECT_TEXT_ELF",        b'    .section .xii_sanctum.text, "ax", @progbits\n'),
    ("SECT_RDAT_PE",         b'    .section .xii_sanctum.rodata, "r"\n'),
    ("SECT_RDAT_ELF",        b'    .section .xii_sanctum.rodata, "a", @progbits\n'),
    ("LEAQ4",                b'    leaq '),
    ("RIP_PCT",              b'(%rip), %'),
    ("MOVQ4",                b'    movq '),
    ("MOVQ_PCTR",            b'    movq %'),
    ("COMMA_SP",             b', '),
    ("RIP_NL",               b'(%rip)\n'),
    ("L_SANCTUM_",           b'L_sanctum_'),
    ("BALIGN_32_NL",         b'    .balign 32\n'),
    ("BALIGN_16_NL",         b'    .balign 16\n'),
    ("BALIGN_8_NL",          b'    .balign 8\n'),
    ("L_SANCTUM_MHASH_",     b'L_sanctum_mhash_'),
    ("COLON_NL_DOTBYTE_SP",  b':\n    .byte '),
    ("NL",                   b'\n'),
    ("PUSHQ_PCT",            b'    pushq %'),
    ("POPQ_PCT",             b'    popq %'),
    ("CMPQ_RAX_RAX_NL",      b'    cmpq %rax, %rax\n'),
    ("CMPQ_RCX_RAX_NL",      b'    cmpq %rcx, %rax\n'),
    ("MOVABSQ_DOLR_HEX",     b'    movabsq $0x'),
    ("COMMA_PCTRCX_NL",      b', %rcx\n'),
    ("COMMA_PCTRAX_NL",      b', %rax\n'),
    ("MOVQ_DOLR",            b'    movq $'),
    ("XORQ_RAX_RAX_NL",      b'    xorq %rax, %rax\n'),
    ("MOVQ_RAX_NEG",         b'    movq %rax, -'),
    ("LP_PCT_RBP_NL",        b'(%rbp)\n'),
    ("MOVQ_LOAD_NEG",        b'    movq -'),
    ("RBP_RAX_NL",           b'(%rbp), %rax\n'),
    ("RBP_RCX_NL",           b'(%rbp), %rcx\n'),
    ("ADDQ_RCX_RAX_NL",      b'    addq %rcx, %rax\n'),
    ("SUBQ_RCX_RAX_NL",      b'    subq %rcx, %rax\n'),
    ("IMULQ_RCX_RAX_NL",     b'    imulq %rcx, %rax\n'),
    ("DIV_SEQ",              b'    cqto\n    idivq %rcx\n'),
    ("MOD_SEQ",              b'    cqto\n    idivq %rcx\n    movq %rdx, %rax\n'),
    ("ANDQ_RCX_RAX_NL",      b'    andq %rcx, %rax\n'),
    ("ORQ_RCX_RAX_NL",       b'    orq %rcx, %rax\n'),
    ("XORQ_RCX_RAX_NL",      b'    xorq %rcx, %rax\n'),
    ("SHLQ_CL_RAX_NL",       b'    shlq %cl, %rax\n'),
    ("SHRQ_CL_RAX_NL",       b'    shrq %cl, %rax\n'),
    ("FOUR_SP",              b'    '),
    ("SP_AL_NL",             b' %al\n'),
    ("MOVZBQ_AL_RAX_NL",     b'    movzbq %al, %rax\n'),
    ("LAND_SEQ",             b'    testq %rax, %rax\n    setne %al\n    movzbq %al, %rdx\n    testq %rcx, %rcx\n    setne %al\n    movzbq %al, %rax\n    andq %rdx, %rax\n'),
    ("LOR_SEQ",              b'    orq %rcx, %rax\n    testq %rax, %rax\n    setne %al\n    movzbq %al, %rax\n'),
    ("NEGQ_RAX_NL",          b'    negq %rax\n'),
    ("UN_NOT_SEQ",           b'    testq %rax, %rax\n    sete %al\n    movzbq %al, %rax\n'),
    ("NOTQ_RAX_NL",          b'    notq %rax\n'),
    ("DEREF_RAX_NL",         b'    movq (%rax), %rax\n'),
    ("SUBQ_8_RSP_NL",        b'    subq $8, %rsp\n'),
    ("ADDQ_8_RSP_NL",        b'    addq $8, %rsp\n'),
    ("CALLQ_4SP",            b'    callq '),
    ("CALLQ_STAR_RAX_NL",    b'    callq *%rax\n'),
    ("FIELD_RIP_RAX_NL",     b'(%rip), %rax\n'),
    ("INDEX_LOAD_NL",        b'    movq (%rax,%rcx,8), %rax\n'),
    ("MOVQ_DOLR_0_RAX_NL",   b'    movq $0, %rax\n'),
    ("JNE_LSKIP",            b'    jne L_sanctum_skip_'),
    ("L_SKIP",               b'L_sanctum_skip_'),
    ("L_MEND",               b'L_sanctum_match_end_'),
    ("L_FOR_TOP",            b'L_sanctum_for_top_'),
    ("L_FOR_END",            b'L_sanctum_for_end_'),
    ("L_FOR_CONT",           b'L_sanctum_for_continue_'),
    ("JMP_LMEND",            b'    jmp L_sanctum_match_end_'),
    ("JMP_LFTOP",            b'    jmp L_sanctum_for_top_'),
    ("JGE_LFEND",            b'    jge L_sanctum_for_end_'),
    ("JZ_LSKIP",             b'    jz L_sanctum_skip_'),
    ("JZ_LFCONT",            b'    jz L_sanctum_for_continue_'),
    ("TESTQ_RAX_RAX_NL",     b'    testq %rax, %rax\n'),
    ("COLON_NL",             b':\n'),
    ("XORQ_RCX_RCX_NL",      b'    xorq %rcx, %rcx\n'),
    ("XORQ_RDX_RDX_NL",      b'    xorq %rdx, %rdx\n'),
    ("XORQ_RSI_RSI_NL",      b'    xorq %rsi, %rsi\n'),
    ("XORQ_RDI_RDI_NL",      b'    xorq %rdi, %rdi\n'),
    ("XORQ_R8_NL",           b'    xorq %r8,  %r8\n'),
    ("XORQ_R9_NL",           b'    xorq %r9,  %r9\n'),
    ("XORQ_R10_NL",          b'    xorq %r10, %r10\n'),
    ("XORQ_R11_NL",          b'    xorq %r11, %r11\n'),
    ("PXOR_XMM_PRE",         b'    pxor %xmm'),
    ("COMMA_PCTXMM",         b', %xmm'),
    ("EPILOGUE",             b'    movq %rbp, %rsp\n    popq %rbx\n    popq %r12\n    popq %r13\n    popq %r14\n    popq %r15\n    popq %rbp\n    retq\n'),
    ("MOVQ_RDX_INDEX_NL",    b'    movq %rdx, (%rax,%rcx,8)\n'),
    ("MOVQ_PCTRAX_SP",       b'    movq %rax, '),
    ("MOVQ_DOLR_0_NEG",      b'    movq $0, -'),
    ("ADDQ_1_RAX_NL",        b'    addq $1, %rax\n'),
    ("DOTGLOBAL_SP",         b'    .global '),
    ("DOTTYPE_SP",           b'    .type '),
    ("AT_FUNCTION_NL",       b', @function\n'),
    ("PUSH_PROLOGUE",        b'    pushq %rbp\n    pushq %r15\n    pushq %r14\n    pushq %r13\n    pushq %r12\n    pushq %rbx\n'),
    ("MOVQ_RSP_RBP_SUBQ",    b'    movq %rsp, %rbp\n    subq $'),
    ("PCT_RSP_NL",           b', %rsp\n'),
    ("D12_PRE",              b'    /* D12: zero local frame ('),
    ("D12_POST",             b' bytes) */\n'),
    ("MOVQ_RSP_RDI_NL",      b'    movq %rsp, %rdi\n'),
    ("REP_STOSQ_NL",         b'    rep stosq\n'),
    ("MOVQ_PCTREG_NEG",      b'    movq %'),
    ("COMMA_NEG",            b', -'),
    ("D10_COMMENT",          b'    /* D10: cap-handle verify */\n'),
    ("MOVQ_M8_RBP_RDI_NL",   b'    movq -8(%rbp), %rdi\n'),
    ("CALLQ_III_CAP_VERIFY_NL", b'    callq iii_cap_verify\n'),
    ("DOTSIZE_SP",           b'    .size '),
    ("COMMA_DOT_DASH",       b', .-'),
    ("PLACEHOLDER_GLOBAL_NL",b'    .global iii_sanctum_mhash_placeholder\n'),
    ("PLACEHOLDER_LBL_NL",   b'iii_sanctum_mhash_placeholder:\n'),
    ("D3_COMMENT",           b'    /* D3: 32-byte zero blob; linker patches with section mhash. */\n'),
    ("PLACEHOLDER_BLOB_NL",  b'    .byte 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0\n'),
    ("HEADER_LINE_1",        b'# III Stage-0 Ring -2 codegen output (SANCTUM-sealed)\n'),
    ("HEADER_LINE_2",        b'# Spec: SPEC.XII \xc2\xa7S14 + DRTM (Intel TXT MLE / TCG D-RTM 1.0).\n'),
    ("ATT_SYNTAX_NL",        b'    .att_syntax\n'),
    ("L_SANCTUM_STR_",       b'L_sanctum_str_'),
    ("DOTASCII",             b'    .ascii "'),
    ("BS_N",                 b'\\n'),
    ("BS_END",               b'\\0"\n'),
    ("REG_RAX",              b'rax'),
    ("REG_RCX",              b'rcx'),
    ("REG_RDX",              b'rdx'),
    ("REG_RDI",              b'rdi'),
    ("REG_RSI",              b'rsi'),
    ("REG_R8",               b'r8'),
    ("REG_R9",               b'r9'),
    ("S_CAP_REVOKE",         b'iii_cap_revoke'),
    ("PFX_LSANC",            b'L_sanctum_'),
    ("PFX_IIISANC",          b'iii_sanctum_'),
    ("PFX_XIISANC",          b'xii_sanctum_'),
    ("PFX_IIICAP",           b'iii_cap_'),
    ("ONEWAY_PORT",          b'iii_sanctum_oneway_port'),
    ("BS_QUOTE",             b'\\"'),
    ("BS_BS",                b'\\\\'),
    ("UNDERS",               b'_'),
    ("DOUBLE_UNDERS",        b'__'),
    ("SETE",                 b'sete'),
    ("SETNE",                b'setne'),
    ("SETL",                 b'setl'),
    ("SETLE",                b'setle'),
    ("SETG",                 b'setg'),
    ("SETGE",                b'setge'),
    ("BS",                   b'\\'),
]


def main():
    out = bytearray()
    consts = []
    seen = {}
    for name, b in LITS:
        key = bytes(b)
        if key in seen:
            off, length = seen[key]
        else:
            off = len(out)
            length = len(b)
            out.extend(b)
            seen[key] = (off, length)
        consts.append((name, off, length))

    print("/* AUTO-GENERATED by _gen_cg_rm2_lits.py - do not hand-edit. */")
    print(f"const CGM_LITS_BUF_SIZE : u32 = {len(out)}u32")
    print(f"var CGM_LITS_BUF : [u8; {len(out)}]")
    print("var CGM_LITS_INIT : u8 = 0u8")
    print()
    for name, off, length in consts:
        print(f"const CGM_O_{name} : u32 = {off}u32")
        print(f"const CGM_L_{name} : u32 = {length}u32")
    print()
    print("fn cgm_init_lits() -> u32 {")
    print("    if CGM_LITS_INIT == 1u8 { return 0u32 }")
    print("    let base : u64 = (&CGM_LITS_BUF as u64)")
    for i, b in enumerate(out):
        print(f"    iii_ast_store_u8(base + {i}u64, {b}u32)")
    print("    CGM_LITS_INIT = 1u8")
    print("    return 0u32")
    print("}")


if __name__ == "__main__":
    main()
