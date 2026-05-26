#!/usr/bin/env python3
"""Generate cg_rm1 (.iii) Stage-0 Ring -1 codegen string-table.

Output format mirrors _gen_cg_rm2_strings.py:

    var <NAME> : [u8; <LEN>] = [b0u8, b1u8, ...]
    const <NAME>_LEN : u64 = <LEN>u64

Run:  python _gen_cg_rm1_strings.py > _strs_rm1.iiifrag
"""
import sys

STRS = [
    # ── Section / .att_syntax ────────────────────────────────────────
    ("RM1_STR_HDR1",         "# III Stage-0 Ring -1 codegen output (iiis-0 freestanding HV)\n"),
    ("RM1_STR_HDR2",         "# SysV AMD64 ABI; bare-metal; no host CRT.\n"),
    ("RM1_STR_ATTSYNTAX",    "    .att_syntax\n"),
    ("RM1_STR_TEXT",         "    .section .text, \"ax\", @progbits\n"),
    ("RM1_STR_RODATA",       "    .section .rodata, \"a\", @progbits\n"),
    ("RM1_STR_DATA",         "    .section .data, \"aw\", @progbits\n"),
    ("RM1_STR_BSS",          "    .section .bss, \"aw\", @nobits\n"),
    ("RM1_STR_BAL16",        "    .balign 16\n"),
    ("RM1_STR_BAL8",         "    .balign 8\n"),
    ("RM1_STR_BAL4096",      "    .balign 4096\n"),
    ("RM1_STR_GLOBAL",       "    .global "),
    ("RM1_STR_TYPE",         "    .type "),
    ("RM1_STR_TYPEFUNC",     ", @function\n"),
    ("RM1_STR_TYPEOBJ",      ", @object\n"),
    ("RM1_STR_SIZE",         "    .size "),
    ("RM1_STR_DOTMINUS",     ", .-"),
    ("RM1_STR_NL",           "\n"),
    ("RM1_STR_COLONNL",      ":\n"),
    ("RM1_STR_BYTE",         "    .byte "),
    ("RM1_STR_QUAD",         "    .quad "),
    ("RM1_STR_QUAD0X",       "    .quad 0x"),
    ("RM1_STR_LONG",         "    .long "),
    ("RM1_STR_ZERO",         "    .zero "),

    # ── Label prefixes ──────────────────────────────────────────────
    ("RM1_PFX_LHV",          "L_hv_"),
    ("RM1_PFX_HV",           "iii_hv_"),
    ("RM1_STR_PFX_STR",      "L_hv_str_"),
    ("RM1_STR_PFX_MHASH",    "L_hv_mhash_"),
    ("RM1_STR_PFX_FORTOP",   "L_hv_for_top_"),
    ("RM1_STR_PFX_FOREND",   "L_hv_for_end_"),
    ("RM1_STR_PFX_FORCONT",  "L_hv_for_continue_"),
    ("RM1_STR_PFX_MATCHEND", "L_hv_match_end_"),
    ("RM1_STR_PFX_SKIP",     "L_hv_skip_"),

    # ── Gateway / cross-target prefixes (D6 ring wall) ──────────────
    ("RM1_PFX_VMEXIT",       "vmexit_"),
    ("RM1_PFX_HCALL",        "hcall_"),
    ("RM1_PFX_VMRUN",        "vmrun_"),
    ("RM1_PFX_RING0",        "ring0_"),
    ("RM1_PFX_RING3",        "ring3_"),
    ("RM1_PFX_CANARY",       "canary_"),

    # ── Common emit chunks ──────────────────────────────────────────
    ("RM1_STR_LEAQ",         "    leaq "),
    ("RM1_STR_RIPCM_PCT",    "(%rip), %"),
    ("RM1_STR_MOVQ_LD",      "    movq "),
    ("RM1_STR_MOVQ_PRAX_C",  "    movq %rax, "),
    ("RM1_STR_MOVQ_PCT",     "    movq %"),
    ("RM1_STR_COMMA_SP",     ", "),
    ("RM1_STR_RIP_PAREN",    "(%rip)\n"),

    # ── SysV registers ──────────────────────────────────────────────
    ("RM1_REG_RDI",          "rdi"),
    ("RM1_REG_RSI",          "rsi"),
    ("RM1_REG_RDX",          "rdx"),
    ("RM1_REG_RCX",          "rcx"),
    ("RM1_REG_R8",           "r8"),
    ("RM1_REG_R9",           "r9"),
    ("RM1_REG_RAX",          "rax"),

    # ── Function prologue / epilogue (SysV) ─────────────────────────
    ("RM1_STR_PROLOG",       "    pushq %rbp\n    movq %rsp, %rbp\n    subq $1024, %rsp\n    .balign 16, 0x90\n"),
    ("RM1_STR_EPILOGUE",     "    movq %rbp, %rsp\n    popq %rbp\n    retq\n"),
    ("RM1_STR_XORRAX",       "    xorq %rax, %rax\n"),
    ("RM1_STR_RETQ",         "    retq\n"),
    ("RM1_STR_PUSHRAX",      "    pushq %rax\n"),
    ("RM1_STR_POPRAX",       "    popq %rax\n"),
    ("RM1_STR_POPRCX",       "    popq %rcx\n"),
    ("RM1_STR_POPRDX",       "    popq %rdx\n"),
    ("RM1_STR_POPRDI",       "    popq %rdi\n"),
    ("RM1_STR_POPRSI",       "    popq %rsi\n"),
    ("RM1_STR_POPR8",        "    popq %r8\n"),
    ("RM1_STR_POPR9",        "    popq %r9\n"),

    # ── ALU ─────────────────────────────────────────────────────────
    ("RM1_STR_MOVABSQ_OPEN", "    movabsq $0x"),
    ("RM1_STR_COMMA_RAX_NL", ", %rax\n"),
    ("RM1_STR_COMMA_RCX_NL", ", %rcx\n"),
    ("RM1_STR_DOL_DASH",     ", -"),
    ("RM1_STR_PCT_RBP_NL",   "(%rbp)\n"),
    ("RM1_STR_DASH_OPEN",    "    movq -"),
    ("RM1_STR_BPCMA_RAX",    "(%rbp), %rax\n"),
    ("RM1_STR_BPCMA_RCX",    "(%rbp), %rcx\n"),
    ("RM1_STR_ADDQ",         "    addq %rcx, %rax\n"),
    ("RM1_STR_SUBQ",         "    subq %rcx, %rax\n"),
    ("RM1_STR_IMULQ",        "    imulq %rcx, %rax\n"),
    ("RM1_STR_IDIV",         "    cqto\n    idivq %rcx\n"),
    ("RM1_STR_IDIVMOD",      "    cqto\n    idivq %rcx\n    movq %rdx, %rax\n"),
    ("RM1_STR_ANDQ",         "    andq %rcx, %rax\n"),
    ("RM1_STR_ORQ",          "    orq %rcx, %rax\n"),
    ("RM1_STR_XORQ",         "    xorq %rcx, %rax\n"),
    ("RM1_STR_SHLQ",         "    shlq %cl, %rax\n"),
    ("RM1_STR_SHRQ",         "    shrq %cl, %rax\n"),
    ("RM1_STR_NEGQ",         "    negq %rax\n"),
    ("RM1_STR_NOTQ",         "    notq %rax\n"),
    ("RM1_STR_DEREF_RAX",    "    movq (%rax), %rax\n"),
    ("RM1_STR_TESTRSTNE",    "    testq %rax, %rax\n    setne %al\n    movzbq %al, %rax\n"),
    ("RM1_STR_TESTRSTE",     "    testq %rax, %rax\n    sete %al\n    movzbq %al, %rax\n"),
    ("RM1_STR_LAND_P1",      "    testq %rax, %rax\n    setne %al\n    movzbq %al, %rdx\n"),
    ("RM1_STR_LAND_P2",      "    testq %rcx, %rcx\n    setne %al\n    movzbq %al, %rax\n"),
    ("RM1_STR_LAND_AND",     "    andq %rdx, %rax\n"),
    ("RM1_STR_LOR_LINE",     "    orq %rcx, %rax\n    testq %rax, %rax\n    setne %al\n    movzbq %al, %rax\n"),
    ("RM1_STR_CMP_RCX_RAX",  "    cmpq %rcx, %rax\n"),
    ("RM1_STR_SETE",         "    sete %al\n    movzbq %al, %rax\n"),
    ("RM1_STR_SETNE",        "    setne %al\n    movzbq %al, %rax\n"),
    ("RM1_STR_SETL",         "    setl %al\n    movzbq %al, %rax\n"),
    ("RM1_STR_SETLE",        "    setle %al\n    movzbq %al, %rax\n"),
    ("RM1_STR_SETG",         "    setg %al\n    movzbq %al, %rax\n"),
    ("RM1_STR_SETGE",        "    setge %al\n    movzbq %al, %rax\n"),
    ("RM1_STR_INDEX_LD",     "    movq (%rax,%rcx,8), %rax\n"),
    ("RM1_STR_INDEX_ST",     "    movq %rdx, (%rax,%rcx,8)\n"),
    ("RM1_STR_CALLQ",        "    callq "),
    ("RM1_STR_CALL_INDIR",   "    callq *%rax\n"),
    ("RM1_STR_SUB8RSP",      "    subq $8, %rsp\n"),
    ("RM1_STR_ADD8RSP",      "    addq $8, %rsp\n"),
    ("RM1_STR_MOVQRAX_DASH", "    movq %rax, -"),
    ("RM1_STR_JMP_SP",       "    jmp "),
    ("RM1_STR_JNE_SP",       "    jne "),
    ("RM1_STR_JZ_SP",        "    jz "),
    ("RM1_STR_JGE_SP",       "    jge "),
    ("RM1_STR_MOVQ0RAX",     "    movq $0, %rax\n"),
    ("RM1_STR_MOVQ1RAX",     "    movq $1, %rax\n"),
    ("RM1_STR_DOL_0_DASH",   "    movq $0, -"),
    ("RM1_STR_ADD1RAX",      "    addq $1, %rax\n"),

    # ── Witness call (D8) ───────────────────────────────────────────
    ("RM1_STR_WITN_CMT",     "    # D8 witness call\n"),
    ("RM1_STR_MOVQDOL_RDI",  "    movq $0x"),
    ("RM1_STR_RDI_NL",       ", %rdi\n"),
    ("RM1_STR_LEA_WITN",     "    leaq iii_hv_witness_"),
    ("RM1_STR_PRIPSI",       "(%rip), %rsi\n"),
    ("RM1_STR_CALL_WITNESS", "    callq iii_hv_witness_emit\n"),
    ("RM1_WITN_ENTRY",       "entry"),
    ("RM1_WITN_EXIT",        "exit"),
    ("RM1_STR_WITN_LBL_PFX", "iii_hv_witness_"),

    # ── Canary (D11) ────────────────────────────────────────────────
    ("RM1_STR_CANARY_INST",  "    # D11 canary install\n"),
    ("RM1_STR_CANARY_LD",    "    movq __iii_hv_canary_seed(%rip), %rax\n"),
    ("RM1_STR_CANARY_ST_DSH","    movq %rax, -"),
    ("RM1_STR_CANARY_ST_TL", "(%rbp)\n"),
    ("RM1_STR_CANARY_CHK",   "    # D11 canary check (fall-through)\n"),
    ("RM1_STR_CANARY_LDR",   "    movq -"),
    ("RM1_STR_CANARY_LDR_TL","(%rbp), %rcx\n"),
    ("RM1_STR_CANARY_SEED2", "    movq __iii_hv_canary_seed(%rip), %rdx\n"),
    ("RM1_STR_CANARY_CMP",   "    cmpq %rdx, %rcx\n"),
    ("RM1_STR_CANARY_JNE",   "    jne  __iii_hv_canary_fail\n"),
    ("RM1_SYM_CANARY_SEED",  "__iii_hv_canary_seed"),
    ("RM1_SYM_CANARY_FAIL",  "__iii_hv_canary_fail"),
    ("RM1_STR_CANARY_DATA",  "    .quad 0x3141592653589793\n"),
    ("RM1_STR_CANARY_TRAMP", "    cli\n1:  hlt\n    jmp 1b\n"),

    # ── Bare-metal entry (D2) ───────────────────────────────────────
    ("RM1_SYM_ENTRY",        "iii_hv_entry"),
    ("RM1_STR_ENTRY_CMT",    "    # D2 bare-metal entry thunk\n"),
    ("RM1_STR_ENTRY_BODY",   "    leaq __iii_hv_stack_top(%rip), %rsp\n    xorq %rbp, %rbp\n    cld\n    callq iii_hv_dispatch\n1:  hlt\n    jmp 1b\n"),
    ("RM1_SYM_STACK",        "__iii_hv_stack"),
    ("RM1_SYM_STACK_TOP",    "__iii_hv_stack_top"),
    ("RM1_STR_STACK_BSS",    "    .zero 65536\n"),

    # ── VMX/SVM CPUID dispatch (D3) ─────────────────────────────────
    ("RM1_SYM_DISPATCH",     "iii_hv_dispatch"),
    ("RM1_STR_DISP_CMT",     "    # D3 VMX/SVM CPUID dispatch\n"),
    ("RM1_STR_DISP_BODY",    "    movl $0x80000001, %eax\n    cpuid\n    btl $2, %ecx\n    jc iii_hv_svm_init\n    movl $1, %eax\n    cpuid\n    btl $5, %ecx\n    jc iii_hv_vmx_init\n    movq $1, %rax\n    retq\n"),
    ("RM1_SYM_VMX_INIT",     "iii_hv_vmx_init"),
    ("RM1_SYM_SVM_INIT",     "iii_hv_svm_init"),

    # ── VMRUN brackets (D12 / D13) ──────────────────────────────────
    ("RM1_SYM_SVM_BRACKET",  "iii_hv_svm_vmrun_bracket"),
    ("RM1_STR_SVM_BRK_CMT",  "    # D12/D13 SVM VMRUN bracket\n"),
    ("RM1_STR_SVM_BRK_BODY", "    pushq %rbp\n    movq %rsp, %rbp\n    movq %rdi, %rax\n    vmload %rax\n    vmrun  %rax\n    vmsave %rax\n    movq %rbp, %rsp\n    popq %rbp\n    retq\n"),
    ("RM1_SYM_VMX_BRACKET",  "iii_hv_vmx_vmrun_bracket"),
    ("RM1_STR_VMX_BRK_CMT",  "    # D12/D13 VMX VMLAUNCH/VMRESUME bracket\n"),
    ("RM1_STR_VMX_BRK_BODY", "    pushq %rbp\n    movq %rsp, %rbp\n    vmlaunch\n    jc 1f\n    movq %rbp, %rsp\n    popq %rbp\n    retq\n1:  vmresume\n    movq %rbp, %rsp\n    popq %rbp\n    retq\n"),

    # ── VMEXIT dispatch table (D7) ──────────────────────────────────
    ("RM1_SYM_VMEXIT_TBL",   "iii_hv_vmexit_table"),
    ("RM1_SYM_VMEXIT_DEF",   "iii_hv_vmexit_default"),
    ("RM1_STR_VMEXIT_CMT",   "    # D7 vmexit dispatch table (256 entries)\n"),
    ("RM1_STR_VMEXIT_DEF_B", "    movq $99, %rax\n    retq\n"),

    # ── SLAT (D5) ───────────────────────────────────────────────────
    ("RM1_SYM_SLAT_PML4",    "iii_hv_slat_pml4"),
    ("RM1_SYM_SLAT_PDPT",    "iii_hv_slat_pdpt"),
    ("RM1_SYM_SLAT_PD",      "iii_hv_slat_pd_"),
    ("RM1_STR_SLAT_CMT",     "    # D5 SLAT identity-map (4 PDs covering 0..4 GiB)\n"),
    ("RM1_STR_PML4_ENT0",    "    .quad iii_hv_slat_pdpt + 0x07\n"),
    ("RM1_STR_PML4_FILL",    "    .zero 4088\n"),
    ("RM1_STR_PDPT_FILL",    "    .zero 4064\n"),
    ("RM1_STR_PD_FILL",      "    .zero 0\n"),

    # ── Witness ring (D8) BSS ──────────────────────────────────────
    ("RM1_SYM_WITN_RING",    "__iii_hv_witness_ring"),
    ("RM1_STR_WITN_BSS",     "    .zero 4096\n"),
    ("RM1_SYM_WITN_HEAD",    "__iii_hv_witness_head"),
    ("RM1_STR_WITN_HEAD_BSS","    .zero 8\n"),

    # ── SHA trailer (D9) ────────────────────────────────────────────
    ("RM1_STR_SHA_TRAIL",    "# III_CG_RM1_ASM_SHA256: "),
    ("RM1_STR_HEX_TBL",      "0123456789abcdef"),

    # ── Error names (8 + unknown) ───────────────────────────────────
    ("RM1_ENAME_OK",          "OK"),
    ("RM1_ENAME_NULL_ARG",    "NULL_ARG"),
    ("RM1_ENAME_IO",          "IO"),
    ("RM1_ENAME_UNSUPPORTED", "UNSUPPORTED"),
    ("RM1_ENAME_ABI_ALIGN",   "ABI_ALIGN"),
    ("RM1_ENAME_RING_WALL",   "RING_WALL"),
    ("RM1_ENAME_BRACKET",     "BRACKET"),
    ("RM1_ENAME_INTERNAL",    "INTERNAL"),
    ("RM1_ENAME_UNKNOWN",     "<unknown>"),
]


def emit():
    out = []
    for name, s in STRS:
        b = s.encode("utf-8")
        n = len(b)
        bytes_str = ", ".join(f"{x}u8" for x in b)
        out.append(f"var {name} : [u8; {n}] = [{bytes_str}]")
        out.append(f"const {name}_LEN : u64 = {n}u64")
    return "\n".join(out) + "\n"


if __name__ == "__main__":
    sys.stdout.write(emit())
