/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\jit_emit.c
 *
 * III Stage-0 NIH x86-64 instruction emitter — implementation.
 *
 * Hand-rolled binary encoder per Intel SDM Vol. 2 + AMD APM Vol. 3.
 *
 * Encoding shape:
 *   [REX] OPCODE [ModR/M] [SIB] [disp] [imm]
 *
 * REX prefix layout (per Intel SDM Vol. 2 §2.2.1, Fig. 2-3):
 *   bit 7..4: 0100 (the 0x40 magic)
 *   bit 3:    REX.W (1 = 64-bit operand)
 *   bit 2:    REX.R (extends ModR/M.reg to 4 bits)
 *   bit 1:    REX.X (extends SIB.index to 4 bits)
 *   bit 0:    REX.B (extends ModR/M.rm or opcode-encoded reg to 4 bits)
 *
 * ModR/M layout (Intel SDM Vol. 2 §2.1.5, Tables 2-1 / 2-2):
 *   bit 7..6: mod
 *   bit 5..3: reg (or opcode extension /n)
 *   bit 2..0: rm
 *
 * SIB layout (Intel SDM Vol. 2 §2.1.5, Table 2-3):
 *   bit 7..6: scale (0=1, 1=2, 2=4, 3=8)
 *   bit 5..3: index
 *   bit 2..0: base
 *
 * For Stage 0 we emit the simplest correct encoding: mod=11 for
 * register-direct; mod=10 + disp32 for [base + disp32].  No 8-bit
 * displacement shortcuts; no SIB unless required for RSP-base.
 *
 * Strict NIH per ADR-021.
 */

#include "jit_emit.h"

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <string.h>
#include <assert.h>

/* ─── Named-constant ModR/M.mod values (D3) ─────────────────────── */
#define III_MOD_INDIRECT          0  /* [reg]      (no disp)          */
#define III_MOD_INDIRECT_DISP8    1  /* [reg+disp8]                   */
#define III_MOD_INDIRECT_DISP32   2  /* [reg+disp32]                  */
#define III_MOD_REGISTER          3  /* register-direct               */

/* RSP and R12 in the rm field always escape to a SIB byte regardless
 * of mod (Intel SDM Vol. 2 §2.1.5, Table 2-2 footnotes).  We only
 * special-case RSP here because Stage 0 does not address through R12. */
#define III_RM_SIB_ESCAPE         4  /* "use SIB" sentinel in rm      */

/* SIB.index = 4 means "no index" (Intel SDM Vol. 2 Table 2-3 note). */
#define III_SIB_NO_INDEX          4

/* ─── D8 abort-on-error macro ───────────────────────────────────── *
 * Every public encoder begins with POISON_GUARD(b); on the first
 * error every subsequent emit is a no-op. */
#define POISON_GUARD(B) do { if ((B)->err) return; } while (0)

/* ─── Init / state ──────────────────────────────────────────────── */

void iii_jit_init(iii_jit_buf_t *b, uint8_t *bytes, size_t cap)
{
    b->buf = bytes; b->cap = cap; b->used = 0; b->overflow = 0;
    b->err = III_JIT_E_OK; b->last_insn_off = 0;
    b->relocs = NULL; b->reloc_cap = 0; b->reloc_used = 0;
}

void iii_jit_attach_relocs(iii_jit_buf_t *b, iii_jit_reloc_t *r, size_t cap)
{
    b->relocs = r; b->reloc_cap = cap; b->reloc_used = 0;
}

iii_jit_err_t iii_jit_error(const iii_jit_buf_t *b) { return b->err; }
void          iii_jit_clear_error(iii_jit_buf_t *b) { b->err = III_JIT_E_OK; b->overflow = 0; }

/* Internal: set err if not already poisoned, prefer first error. */
static void poison(iii_jit_buf_t *b, iii_jit_err_t e)
{
    if (b->err == III_JIT_E_OK) b->err = e;
}

/* ─── Raw emitters ──────────────────────────────────────────────── */

void iii_jit_byte(iii_jit_buf_t *b, uint8_t v)
{
    if (b->err) return;
    if (b->used >= b->cap) { b->overflow = 1; poison(b, III_JIT_E_BUF_OVERFLOW); return; }
    b->buf[b->used++] = v;
}

void iii_jit_word(iii_jit_buf_t *b, uint16_t v)
{
    iii_jit_byte(b, (uint8_t)(v & 0xFFu));
    iii_jit_byte(b, (uint8_t)((v >> 8) & 0xFFu));
}

void iii_jit_dword(iii_jit_buf_t *b, uint32_t v)
{
    iii_jit_byte(b, (uint8_t)(v & 0xFFu));
    iii_jit_byte(b, (uint8_t)((v >> 8) & 0xFFu));
    iii_jit_byte(b, (uint8_t)((v >> 16) & 0xFFu));
    iii_jit_byte(b, (uint8_t)((v >> 24) & 0xFFu));
}

void iii_jit_qword(iii_jit_buf_t *b, uint64_t v)
{
    iii_jit_dword(b, (uint32_t)(v & 0xFFFFFFFFull));
    iii_jit_dword(b, (uint32_t)((v >> 32) & 0xFFFFFFFFull));
}

size_t iii_jit_offset(const iii_jit_buf_t *b) { return b->used; }

/* ─── D4 displacement patchers ─────────────────────────────────── */

iii_jit_err_t iii_jit_patch_rel32(iii_jit_buf_t *b, size_t offset, size_t target)
{
    if (offset + 4 > b->cap) { poison(b, III_JIT_E_BAD_PATCH_SITE); return III_JIT_E_BAD_PATCH_SITE; }
    int64_t rel = (int64_t)target - (int64_t)(offset + 4);
    if (rel > (int64_t)INT32_MAX || rel < (int64_t)INT32_MIN) {
        poison(b, III_JIT_E_DISP_OVERFLOW);
        return III_JIT_E_DISP_OVERFLOW;
    }
    int32_t rel32 = (int32_t)rel;
    b->buf[offset + 0] = (uint8_t)(rel32 & 0xFFu);
    b->buf[offset + 1] = (uint8_t)((rel32 >> 8) & 0xFFu);
    b->buf[offset + 2] = (uint8_t)((rel32 >> 16) & 0xFFu);
    b->buf[offset + 3] = (uint8_t)((rel32 >> 24) & 0xFFu);
    return III_JIT_E_OK;
}

iii_jit_err_t iii_jit_patch_rel8(iii_jit_buf_t *b, size_t offset, size_t target)
{
    if (offset + 1 > b->cap) { poison(b, III_JIT_E_BAD_PATCH_SITE); return III_JIT_E_BAD_PATCH_SITE; }
    int64_t rel = (int64_t)target - (int64_t)(offset + 1);
    if (rel > 127 || rel < -128) {
        poison(b, III_JIT_E_DISP_OVERFLOW);
        return III_JIT_E_DISP_OVERFLOW;
    }
    b->buf[offset] = (uint8_t)((int8_t)rel);
    return III_JIT_E_OK;
}

/* ─── D2 / D3 pure encoding-field builders ────────────────────── */

uint8_t iii_jit_compute_rex(int W, int R, int X, int B)
{
    /* Intel SDM Vol. 2 §2.2.1.  Only the LSB of each input contributes;
     * any non-zero argument is treated as "set the bit". */
    return (uint8_t)(0x40u
                  | ((W ? 1u : 0u) << 3)
                  | ((R ? 1u : 0u) << 2)
                  | ((X ? 1u : 0u) << 1)
                  | ((B ? 1u : 0u) << 0));
}

uint8_t iii_jit_compute_modrm(int mod, int reg, int rm)
{
    assert(mod >= 0 && mod <= 3);
    assert(reg >= 0 && reg <= 7);
    assert(rm  >= 0 && rm  <= 7);
    return (uint8_t)(((mod & 3) << 6) | ((reg & 7) << 3) | (rm & 7));
}

uint8_t iii_jit_compute_sib(int scale, int index, int base)
{
    assert(scale >= 0 && scale <= 3);
    assert(index >= 0 && index <= 7);
    assert(base  >= 0 && base  <= 7);
    return (uint8_t)(((scale & 3) << 6) | ((index & 7) << 3) | (base & 7));
}

/* Convenience: compute REX from operand triple, with W=1. */
static uint8_t rex_w_for_rb(iii_reg_t reg, iii_reg_t rm)
{
    int R = (reg >= III_REG_R8) ? 1 : 0;
    int B = (rm  >= III_REG_R8) ? 1 : 0;
    return iii_jit_compute_rex(1, R, 0, B);
}
static uint8_t rex_w_for_b(iii_reg_t rm)
{
    int B = (rm >= III_REG_R8) ? 1 : 0;
    return iii_jit_compute_rex(1, 0, 0, B);
}

/* Mark the start of an instruction (D8 witness aid). */
static void mark_insn(iii_jit_buf_t *b) { b->last_insn_off = b->used; }

/* Emit ModR/M for register-direct (mod=11). */
static void emit_modrm_reg_reg(iii_jit_buf_t *b, iii_reg_t reg, iii_reg_t rm)
{
    iii_jit_byte(b, iii_jit_compute_modrm(III_MOD_REGISTER, reg & 7, rm & 7));
}

/* Emit ModR/M for [base + disp32].  Handles RSP-base (which requires SIB). */
static void emit_modrm_mem(iii_jit_buf_t *b, iii_reg_t reg, iii_reg_t base, int32_t disp)
{
    if ((base & 7) == (III_REG_RSP & 7)) {
        /* RSP-base: must use SIB with no-index.  mod=10 + rm=4(escape). */
        iii_jit_byte(b, iii_jit_compute_modrm(III_MOD_INDIRECT_DISP32, reg & 7, III_RM_SIB_ESCAPE));
        iii_jit_byte(b, iii_jit_compute_sib(0, III_SIB_NO_INDEX, base & 7));
    } else {
        iii_jit_byte(b, iii_jit_compute_modrm(III_MOD_INDIRECT_DISP32, reg & 7, base & 7));
    }
    iii_jit_dword(b, (uint32_t)disp);
}

/* ─── mov  (Intel SDM Vol. 2B "MOV", Tables) ───────────────────── */

/* MOV r64, imm64 — REX.W + B8+rd io  (Intel SDM Vol. 2B "MOV", opcode B8+rd / movabs). */
void iii_jit_mov_r64_imm64(iii_jit_buf_t *b, iii_reg_t dst, uint64_t imm)
{
    POISON_GUARD(b); mark_insn(b);
    iii_jit_byte(b, iii_jit_compute_rex(1, 0, 0, (dst >= III_REG_R8) ? 1 : 0));
    iii_jit_byte(b, 0xB8u + (uint8_t)(dst & 7));
    iii_jit_qword(b, imm);
}

/* MOV r/m64, r64 — REX.W + 89 /r  (Intel SDM Vol. 2B "MOV", opcode 89 /r). */
void iii_jit_mov_r64_r64(iii_jit_buf_t *b, iii_reg_t dst, iii_reg_t src)
{
    POISON_GUARD(b); mark_insn(b);
    iii_jit_byte(b, rex_w_for_rb(src, dst));
    iii_jit_byte(b, 0x89u);
    emit_modrm_reg_reg(b, src, dst);
}

/* MOV r64, r/m64 — REX.W + 8B /r  (Intel SDM Vol. 2B "MOV", opcode 8B /r). */
void iii_jit_mov_r64_mem(iii_jit_buf_t *b, iii_reg_t dst, iii_reg_t base, int32_t disp)
{
    POISON_GUARD(b); mark_insn(b);
    iii_jit_byte(b, iii_jit_compute_rex(1,
        (dst  >= III_REG_R8) ? 1 : 0, 0,
        (base >= III_REG_R8) ? 1 : 0));
    iii_jit_byte(b, 0x8Bu);
    emit_modrm_mem(b, dst, base, disp);
}

/* MOV r/m64, r64 (memory dest) — REX.W + 89 /r  (Intel SDM Vol. 2B "MOV"). */
void iii_jit_mov_mem_r64(iii_jit_buf_t *b, iii_reg_t base, int32_t disp, iii_reg_t src)
{
    POISON_GUARD(b); mark_insn(b);
    iii_jit_byte(b, iii_jit_compute_rex(1,
        (src  >= III_REG_R8) ? 1 : 0, 0,
        (base >= III_REG_R8) ? 1 : 0));
    iii_jit_byte(b, 0x89u);
    emit_modrm_mem(b, src, base, disp);
}

/* LEA r64, m — REX.W + 8D /r  (Intel SDM Vol. 2B "LEA", opcode 8D /r). */
void iii_jit_lea_r64_mem(iii_jit_buf_t *b, iii_reg_t dst, iii_reg_t base, int32_t disp)
{
    POISON_GUARD(b); mark_insn(b);
    iii_jit_byte(b, iii_jit_compute_rex(1,
        (dst  >= III_REG_R8) ? 1 : 0, 0,
        (base >= III_REG_R8) ? 1 : 0));
    iii_jit_byte(b, 0x8Du);
    emit_modrm_mem(b, dst, base, disp);
}

/* ─── Arithmetic: dst <op>= src ─────────────────────────────────── *
 * Common form: REX.W + OP /r:
 *   0x01 = ADD r/m64, r64  (Intel SDM Vol. 2A "ADD",  opcode 01 /r)
 *   0x29 = SUB r/m64, r64  (Intel SDM Vol. 2B "SUB",  opcode 29 /r)
 *   0x31 = XOR r/m64, r64  (Intel SDM Vol. 2B "XOR",  opcode 31 /r)
 *   0x21 = AND r/m64, r64  (Intel SDM Vol. 2A "AND",  opcode 21 /r)
 *   0x09 = OR  r/m64, r64  (Intel SDM Vol. 2B "OR",   opcode 09 /r)
 *   0x39 = CMP r/m64, r64  (Intel SDM Vol. 2A "CMP",  opcode 39 /r)
 *   0x85 = TEST r/m64, r64 (Intel SDM Vol. 2B "TEST", opcode 85 /r) */
static void emit_arith_rr(iii_jit_buf_t *b, uint8_t op, iii_reg_t dst, iii_reg_t src)
{
    POISON_GUARD(b); mark_insn(b);
    iii_jit_byte(b, rex_w_for_rb(src, dst));
    iii_jit_byte(b, op);
    emit_modrm_reg_reg(b, src, dst);
}

void iii_jit_add_r64_r64(iii_jit_buf_t *b, iii_reg_t dst, iii_reg_t src) { emit_arith_rr(b, 0x01u, dst, src); }
void iii_jit_sub_r64_r64(iii_jit_buf_t *b, iii_reg_t dst, iii_reg_t src) { emit_arith_rr(b, 0x29u, dst, src); }
void iii_jit_xor_r64_r64(iii_jit_buf_t *b, iii_reg_t dst, iii_reg_t src) { emit_arith_rr(b, 0x31u, dst, src); }
void iii_jit_and_r64_r64(iii_jit_buf_t *b, iii_reg_t dst, iii_reg_t src) { emit_arith_rr(b, 0x21u, dst, src); }
void iii_jit_or_r64_r64 (iii_jit_buf_t *b, iii_reg_t dst, iii_reg_t src) { emit_arith_rr(b, 0x09u, dst, src); }
void iii_jit_cmp_r64_r64(iii_jit_buf_t *b, iii_reg_t l, iii_reg_t r)     { emit_arith_rr(b, 0x39u, l,   r); }
void iii_jit_test_r64_r64(iii_jit_buf_t *b, iii_reg_t l, iii_reg_t r)    { emit_arith_rr(b, 0x85u, l,   r); }

/* Shifts (cl-implicit form): REX.W + D3 /n
 *   /n = 4 (SHL), 5 (SHR), 7 (SAR)  (Intel SDM Vol. 2B "SAL/SAR/SHL/SHR", opcode D3 /n). */
static void emit_shift_cl(iii_jit_buf_t *b, uint8_t op_ext, iii_reg_t dst)
{
    POISON_GUARD(b); mark_insn(b);
    iii_jit_byte(b, rex_w_for_b(dst));
    iii_jit_byte(b, 0xD3u);
    iii_jit_byte(b, iii_jit_compute_modrm(III_MOD_REGISTER, op_ext, dst & 7));
}

void iii_jit_shl_r64_cl(iii_jit_buf_t *b, iii_reg_t dst) { emit_shift_cl(b, 4, dst); }
void iii_jit_shr_r64_cl(iii_jit_buf_t *b, iii_reg_t dst) { emit_shift_cl(b, 5, dst); }
void iii_jit_sar_r64_cl(iii_jit_buf_t *b, iii_reg_t dst) { emit_shift_cl(b, 7, dst); }

/* IMUL r64, r/m64 — REX.W + 0F AF /r  (Intel SDM Vol. 2A "IMUL", opcode 0F AF /r). */
void iii_jit_imul_r64_r64(iii_jit_buf_t *b, iii_reg_t dst, iii_reg_t src)
{
    POISON_GUARD(b); mark_insn(b);
    iii_jit_byte(b, rex_w_for_rb(dst, src));
    iii_jit_byte(b, 0x0Fu);
    iii_jit_byte(b, 0xAFu);
    emit_modrm_reg_reg(b, dst, src);
}

/* CQO — REX.W + 99  (Intel SDM Vol. 2A "CWD/CDQ/CQO", opcode REX.W 99). */
void iii_jit_cqto(iii_jit_buf_t *b)
{
    POISON_GUARD(b); mark_insn(b);
    iii_jit_byte(b, 0x48u);
    iii_jit_byte(b, 0x99u);
}

/* IDIV r/m64 — REX.W + F7 /7  (Intel SDM Vol. 2A "IDIV", opcode F7 /7). */
void iii_jit_idiv_r64(iii_jit_buf_t *b, iii_reg_t divisor)
{
    POISON_GUARD(b); mark_insn(b);
    iii_jit_byte(b, rex_w_for_b(divisor));
    iii_jit_byte(b, 0xF7u);
    iii_jit_byte(b, iii_jit_compute_modrm(III_MOD_REGISTER, 7, divisor & 7));
}

/* PUSH r64 — 50+rd (Intel SDM Vol. 2B "PUSH", opcode 50+rd, REX.B for r8..r15). */
void iii_jit_push_r64(iii_jit_buf_t *b, iii_reg_t r)
{
    POISON_GUARD(b); mark_insn(b);
    if (r >= III_REG_R8) iii_jit_byte(b, iii_jit_compute_rex(0, 0, 0, 1));
    iii_jit_byte(b, 0x50u + (uint8_t)(r & 7));
}

/* POP r64 — 58+rd  (Intel SDM Vol. 2B "POP", opcode 58+rd). */
void iii_jit_pop_r64(iii_jit_buf_t *b, iii_reg_t r)
{
    POISON_GUARD(b); mark_insn(b);
    if (r >= III_REG_R8) iii_jit_byte(b, iii_jit_compute_rex(0, 0, 0, 1));
    iii_jit_byte(b, 0x58u + (uint8_t)(r & 7));
}

/* ADD/SUB r/m64, imm32 — REX.W + 81 /0 (ADD) or /5 (SUB)
 * (Intel SDM Vol. 2A "ADD" 81 /0 id, "SUB" 81 /5 id). */
void iii_jit_add_r64_imm32(iii_jit_buf_t *b, iii_reg_t dst, int32_t imm)
{
    POISON_GUARD(b); mark_insn(b);
    iii_jit_byte(b, rex_w_for_b(dst));
    iii_jit_byte(b, 0x81u);
    iii_jit_byte(b, iii_jit_compute_modrm(III_MOD_REGISTER, 0, dst & 7));
    iii_jit_dword(b, (uint32_t)imm);
}

void iii_jit_sub_r64_imm32(iii_jit_buf_t *b, iii_reg_t dst, int32_t imm)
{
    POISON_GUARD(b); mark_insn(b);
    iii_jit_byte(b, rex_w_for_b(dst));
    iii_jit_byte(b, 0x81u);
    iii_jit_byte(b, iii_jit_compute_modrm(III_MOD_REGISTER, 5, dst & 7));
    iii_jit_dword(b, (uint32_t)imm);
}

/* SETcc r/m8 — 0F 90+cc /0  (Intel SDM Vol. 2B "SETcc", opcode 0F 90+cc /0).
 * REX is required to access SPL/BPL/SIL/DIL/R8L..R15L byte forms. */
void iii_jit_setcc_r8(iii_jit_buf_t *b, iii_cc_t cc, iii_reg_t dst)
{
    POISON_GUARD(b); mark_insn(b);
    int B = (dst >= III_REG_R8) ? 1 : 0;
    if (B || dst >= III_REG_RSP) iii_jit_byte(b, iii_jit_compute_rex(0, 0, 0, B));
    iii_jit_byte(b, 0x0Fu);
    iii_jit_byte(b, 0x90u + (uint8_t)(cc & 0xFu));
    iii_jit_byte(b, iii_jit_compute_modrm(III_MOD_REGISTER, 0, dst & 7));
}

/* MOVZX r64, r/m8 — REX.W + 0F B6 /r  (Intel SDM Vol. 2B "MOVZX", opcode 0F B6 /r). */
void iii_jit_movzbq_r64_r8(iii_jit_buf_t *b, iii_reg_t dst, iii_reg_t src8)
{
    POISON_GUARD(b); mark_insn(b);
    iii_jit_byte(b, iii_jit_compute_rex(1,
        (dst  >= III_REG_R8) ? 1 : 0, 0,
        (src8 >= III_REG_R8) ? 1 : 0));
    iii_jit_byte(b, 0x0Fu);
    iii_jit_byte(b, 0xB6u);
    emit_modrm_reg_reg(b, dst, src8);
}

/* JMP rel32 — E9 cd  (Intel SDM Vol. 2A "JMP", opcode E9 cd). */
size_t iii_jit_jmp_rel32(iii_jit_buf_t *b)
{
    if (b->err) return 0;
    mark_insn(b);
    iii_jit_byte(b, 0xE9u);
    size_t off = b->used;
    iii_jit_dword(b, 0u);
    return off;
}

/* Jcc rel32 — 0F 80+cc cd  (Intel SDM Vol. 2A "Jcc", opcode 0F 80+cc cd). */
size_t iii_jit_jcc_rel32(iii_jit_buf_t *b, iii_cc_t cc)
{
    if (b->err) return 0;
    mark_insn(b);
    iii_jit_byte(b, 0x0Fu);
    iii_jit_byte(b, 0x80u + (uint8_t)(cc & 0xFu));
    size_t off = b->used;
    iii_jit_dword(b, 0u);
    return off;
}

/* JMP rel8 — EB cb  (Intel SDM Vol. 2A "JMP", opcode EB cb). */
size_t iii_jit_jmp_rel8(iii_jit_buf_t *b)
{
    if (b->err) return 0;
    mark_insn(b);
    iii_jit_byte(b, 0xEBu);
    size_t off = b->used;
    iii_jit_byte(b, 0u);
    return off;
}

/* Jcc rel8 — 70+cc cb  (Intel SDM Vol. 2A "Jcc", opcode 70+cc cb). */
size_t iii_jit_jcc_rel8(iii_jit_buf_t *b, iii_cc_t cc)
{
    if (b->err) return 0;
    mark_insn(b);
    iii_jit_byte(b, 0x70u + (uint8_t)(cc & 0xFu));
    size_t off = b->used;
    iii_jit_byte(b, 0u);
    return off;
}

/* CALL rel32 — E8 cd  (Intel SDM Vol. 2A "CALL", opcode E8 cd). */
void iii_jit_call_rel32(iii_jit_buf_t *b, int32_t rel32)
{
    POISON_GUARD(b); mark_insn(b);
    iii_jit_byte(b, 0xE8u);
    iii_jit_dword(b, (uint32_t)rel32);
}

/* CALL r/m64 — FF /2  (Intel SDM Vol. 2A "CALL", opcode FF /2). */
void iii_jit_call_r64(iii_jit_buf_t *b, iii_reg_t target)
{
    POISON_GUARD(b); mark_insn(b);
    if (target >= III_REG_R8) iii_jit_byte(b, iii_jit_compute_rex(0, 0, 0, 1));
    iii_jit_byte(b, 0xFFu);
    iii_jit_byte(b, iii_jit_compute_modrm(III_MOD_REGISTER, 2, target & 7));
}

/* RET — C3  (Intel SDM Vol. 2B "RET", opcode C3, near return). */
void iii_jit_ret(iii_jit_buf_t *b)
{
    POISON_GUARD(b); mark_insn(b);
    iii_jit_byte(b, 0xC3u);
}

/* ─── D12 relocation recording ─────────────────────────────────── */

iii_jit_err_t iii_jit_record_reloc(iii_jit_buf_t *b,
                                   uint32_t offset,
                                   iii_jit_reloc_kind_t kind,
                                   uint32_t symbol_id)
{
    if (!b->relocs || b->reloc_used >= b->reloc_cap) {
        poison(b, III_JIT_E_RELOC_FULL);
        return III_JIT_E_RELOC_FULL;
    }
    iii_jit_reloc_t *r = &b->relocs[b->reloc_used++];
    r->offset    = offset;
    r->symbol_id = symbol_id;
    r->kind      = (uint16_t)kind;
    r->reserved  = 0;
    return III_JIT_E_OK;
}

/* ─── Privileged opcode bytes (per AMD APM Vol. 3 §B.4 / §15.5) ── */

/* RDMSR — 0F 32  (Intel SDM Vol. 2B "RDMSR", opcode 0F 32). */
void iii_jit_rdmsr(iii_jit_buf_t *b)
{
    POISON_GUARD(b); mark_insn(b);
    iii_jit_byte(b, 0x0Fu); iii_jit_byte(b, 0x32u);
}
/* WRMSR — 0F 30  (Intel SDM Vol. 2B "WRMSR", opcode 0F 30). */
void iii_jit_wrmsr(iii_jit_buf_t *b)
{
    POISON_GUARD(b); mark_insn(b);
    iii_jit_byte(b, 0x0Fu); iii_jit_byte(b, 0x30u);
}
/* CLGI  — 0F 01 DD  (AMD APM Vol. 3 §B.4 / "CLGI"). */
void iii_jit_clgi(iii_jit_buf_t *b)
{
    POISON_GUARD(b); mark_insn(b);
    iii_jit_byte(b, 0x0Fu); iii_jit_byte(b, 0x01u); iii_jit_byte(b, 0xDDu);
}
/* STGI  — 0F 01 DC  (AMD APM Vol. 3 §B.4 / "STGI"). */
void iii_jit_stgi(iii_jit_buf_t *b)
{
    POISON_GUARD(b); mark_insn(b);
    iii_jit_byte(b, 0x0Fu); iii_jit_byte(b, 0x01u); iii_jit_byte(b, 0xDCu);
}
/* VMSAVE — 0F 01 DB  (AMD APM Vol. 3 §B.4 / §15.5 "VMSAVE"). */
void iii_jit_vmsave(iii_jit_buf_t *b)
{
    POISON_GUARD(b); mark_insn(b);
    iii_jit_byte(b, 0x0Fu); iii_jit_byte(b, 0x01u); iii_jit_byte(b, 0xDBu);
}
/* VMLOAD — 0F 01 DA  (AMD APM Vol. 3 §B.4 / §15.5 "VMLOAD"). */
void iii_jit_vmload(iii_jit_buf_t *b)
{
    POISON_GUARD(b); mark_insn(b);
    iii_jit_byte(b, 0x0Fu); iii_jit_byte(b, 0x01u); iii_jit_byte(b, 0xDAu);
}
/* VMRUN — 0F 01 D8  (AMD APM Vol. 3 §B.4 / §15.5 "VMRUN"). */
void iii_jit_vmrun(iii_jit_buf_t *b)
{
    POISON_GUARD(b); mark_insn(b);
    iii_jit_byte(b, 0x0Fu); iii_jit_byte(b, 0x01u); iii_jit_byte(b, 0xD8u);
}

/* ─── D14 SVM safety bracket  (AMD APM Vol. 3 §15.5) ───────────── */

iii_jit_err_t iii_jit_emit_vm_session(iii_jit_buf_t *b)
{
    if (b->err) return b->err;
    size_t snap = b->used;
    iii_jit_vmsave(b);
    iii_jit_vmrun (b);
    iii_jit_vmload(b);
    if (b->err) {
        b->used = snap;          /* rewind half-emitted bracket          */
        return b->err;
    }
    /* Each SVM op is exactly 3 bytes: 3 × 3 = 9. */
    if (b->used - snap != 9) {
        b->used = snap;
        poison(b, III_JIT_E_BAD_OPERAND);
        return III_JIT_E_BAD_OPERAND;
    }
    return III_JIT_E_OK;
}

/* Fences (Intel SDM Vol. 2A "MFENCE/LFENCE/SFENCE"). */
void iii_jit_mfence(iii_jit_buf_t *b)
{
    POISON_GUARD(b); mark_insn(b);
    iii_jit_byte(b, 0x0Fu); iii_jit_byte(b, 0xAEu); iii_jit_byte(b, 0xF0u);
}
void iii_jit_lfence(iii_jit_buf_t *b)
{
    POISON_GUARD(b); mark_insn(b);
    iii_jit_byte(b, 0x0Fu); iii_jit_byte(b, 0xAEu); iii_jit_byte(b, 0xE8u);
}
void iii_jit_sfence(iii_jit_buf_t *b)
{
    POISON_GUARD(b); mark_insn(b);
    iii_jit_byte(b, 0x0Fu); iii_jit_byte(b, 0xAEu); iii_jit_byte(b, 0xF8u);
}

/* PAUSE — F3 90  (Intel SDM Vol. 2B "PAUSE"). */
void iii_jit_pause(iii_jit_buf_t *b)
{
    POISON_GUARD(b); mark_insn(b);
    iii_jit_byte(b, 0xF3u); iii_jit_byte(b, 0x90u);
}

/* ─── D11 canonical NOP padding ─────────────────────────────────
 *
 * Intel SDM Vol. 2B "NOP — No Operation" recommends the following
 * multi-byte sequences (stable across families):
 *   1: 90
 *   2: 66 90
 *   3: 0F 1F 00
 *   4: 0F 1F 40 00
 *   5: 0F 1F 44 00 00
 *   6: 66 0F 1F 44 00 00
 *   7: 0F 1F 80 00 00 00 00
 *   8: 0F 1F 84 00 00 00 00 00
 *   9: 66 0F 1F 84 00 00 00 00 00
 * For n > 9 we emit floor(n/9) copies of the 9-byte form followed
 * by the n%9 tail.  Output is a deterministic function of n. */
static const uint8_t k_nop1[1] = { 0x90 };
static const uint8_t k_nop2[2] = { 0x66, 0x90 };
static const uint8_t k_nop3[3] = { 0x0F, 0x1F, 0x00 };
static const uint8_t k_nop4[4] = { 0x0F, 0x1F, 0x40, 0x00 };
static const uint8_t k_nop5[5] = { 0x0F, 0x1F, 0x44, 0x00, 0x00 };
static const uint8_t k_nop6[6] = { 0x66, 0x0F, 0x1F, 0x44, 0x00, 0x00 };
static const uint8_t k_nop7[7] = { 0x0F, 0x1F, 0x80, 0x00, 0x00, 0x00, 0x00 };
static const uint8_t k_nop8[8] = { 0x0F, 0x1F, 0x84, 0x00, 0x00, 0x00, 0x00, 0x00 };
static const uint8_t k_nop9[9] = { 0x66, 0x0F, 0x1F, 0x84, 0x00, 0x00, 0x00, 0x00, 0x00 };

static const uint8_t *const k_nop_tab[10] = {
    NULL, k_nop1, k_nop2, k_nop3, k_nop4, k_nop5, k_nop6, k_nop7, k_nop8, k_nop9
};

static void emit_nop_run(iii_jit_buf_t *b, size_t n)
{
    if (n == 0 || n > 9) return;
    const uint8_t *p = k_nop_tab[n];
    for (size_t i = 0; i < n; ++i) iii_jit_byte(b, p[i]);
}

void iii_jit_emit_nop(iii_jit_buf_t *b, size_t n)
{
    if (b->err || n == 0) return;
    mark_insn(b);
    while (n >= 9) { emit_nop_run(b, 9); n -= 9; }
    if (n) emit_nop_run(b, n);
}

/* ─── D9 AVX-512 stubs ─────────────────────────────────────────── *
 *
 * AVX-512 (EVEX prefix) is intentionally not yet wired.  Per
 * ADR-027 §11 q3 it is a runtime-detected accelerator slot.  These
 * stubs always poison the context and return III_JIT_E_NOT_IMPLEMENTED. */
iii_jit_err_t iii_jit_avx512_vmovdqa64_stub(iii_jit_buf_t *b)
{
    poison(b, III_JIT_E_NOT_IMPLEMENTED);
    return III_JIT_E_NOT_IMPLEMENTED;
}
iii_jit_err_t iii_jit_avx512_vpaddq_stub(iii_jit_buf_t *b)
{
    poison(b, III_JIT_E_NOT_IMPLEMENTED);
    return III_JIT_E_NOT_IMPLEMENTED;
}

/* ─── D5 golden-bytes self-test ────────────────────────────────── *
 *
 * Each vector below is hand-derived from the Intel SDM Vol. 2 / AMD
 * APM Vol. 3 opcode tables cited in the per-encoder comments above.
 * The runtime re-encodes each vector and asserts byte equality.
 * Returns 0 on success, or 1-based vector index of the first
 * failure.  Used as a reproducibility gate at boot of iiis-0. */

typedef int (*iii_golden_emit_fn)(iii_jit_buf_t *b);

typedef struct {
    const char         *label;
    iii_golden_emit_fn  emit;
    const uint8_t      *expected;
    size_t              expected_len;
} iii_golden_vec_t;

/* Emitters used by the golden vectors. */
static int g_emit_mov_rax_imm(iii_jit_buf_t *b)
{
    iii_jit_mov_r64_imm64(b, III_REG_RAX, 0x1122334455667788ull);
    return 0;
}
static int g_emit_mov_rax_rax(iii_jit_buf_t *b) { iii_jit_mov_r64_r64(b, III_REG_RAX, III_REG_RAX); return 0; }
static int g_emit_add_rax_rax(iii_jit_buf_t *b) { iii_jit_add_r64_r64(b, III_REG_RAX, III_REG_RAX); return 0; }
static int g_emit_xor_r8_r8  (iii_jit_buf_t *b) { iii_jit_xor_r64_r64(b, III_REG_R8,  III_REG_R8 ); return 0; }
static int g_emit_push_rbx   (iii_jit_buf_t *b) { iii_jit_push_r64   (b, III_REG_RBX); return 0; }
static int g_emit_push_r15   (iii_jit_buf_t *b) { iii_jit_push_r64   (b, III_REG_R15); return 0; }
static int g_emit_pop_rbx    (iii_jit_buf_t *b) { iii_jit_pop_r64    (b, III_REG_RBX); return 0; }
static int g_emit_ret        (iii_jit_buf_t *b) { iii_jit_ret        (b); return 0; }
static int g_emit_mfence     (iii_jit_buf_t *b) { iii_jit_mfence     (b); return 0; }
static int g_emit_pause      (iii_jit_buf_t *b) { iii_jit_pause      (b); return 0; }
static int g_emit_vmrun      (iii_jit_buf_t *b) { iii_jit_vmrun      (b); return 0; }
static int g_emit_vmsave     (iii_jit_buf_t *b) { iii_jit_vmsave     (b); return 0; }
static int g_emit_nop9       (iii_jit_buf_t *b) { iii_jit_emit_nop   (b, 9); return 0; }
static int g_emit_nop1       (iii_jit_buf_t *b) { iii_jit_emit_nop   (b, 1); return 0; }
static int g_emit_lea_rax_rsp_8(iii_jit_buf_t *b)
{
    iii_jit_lea_r64_mem(b, III_REG_RAX, III_REG_RSP, 8);
    return 0;
}

/* Expected byte sequences. */
static const uint8_t E_mov_rax_imm[]   = { 0x48, 0xB8, 0x88, 0x77, 0x66, 0x55, 0x44, 0x33, 0x22, 0x11 };
static const uint8_t E_mov_rax_rax[]   = { 0x48, 0x89, 0xC0 };
static const uint8_t E_add_rax_rax[]   = { 0x48, 0x01, 0xC0 };
static const uint8_t E_xor_r8_r8[]     = { 0x4D, 0x31, 0xC0 };
static const uint8_t E_push_rbx[]      = { 0x53 };
static const uint8_t E_push_r15[]      = { 0x41, 0x57 };
static const uint8_t E_pop_rbx[]       = { 0x5B };
static const uint8_t E_ret[]           = { 0xC3 };
static const uint8_t E_mfence[]        = { 0x0F, 0xAE, 0xF0 };
static const uint8_t E_pause[]         = { 0xF3, 0x90 };
static const uint8_t E_vmrun[]         = { 0x0F, 0x01, 0xD8 };
static const uint8_t E_vmsave[]        = { 0x0F, 0x01, 0xDB };
static const uint8_t E_nop9[]          = { 0x66, 0x0F, 0x1F, 0x84, 0x00, 0x00, 0x00, 0x00, 0x00 };
static const uint8_t E_nop1[]          = { 0x90 };
/* lea rax, [rsp + 8]:  REX.W=48 + 8D + ModRM(mod=10,reg=000,rm=100) + SIB(00,100,100) + disp32 */
static const uint8_t E_lea_rax_rsp_8[] = { 0x48, 0x8D, 0x84, 0x24, 0x08, 0x00, 0x00, 0x00 };

#define V(label, fn, exp) { label, fn, exp, sizeof(exp) }

static const iii_golden_vec_t k_golden_vecs[] = {
    V("mov rax, imm64",        g_emit_mov_rax_imm,    E_mov_rax_imm),
    V("mov rax, rax",          g_emit_mov_rax_rax,    E_mov_rax_rax),
    V("add rax, rax",          g_emit_add_rax_rax,    E_add_rax_rax),
    V("xor r8,  r8",           g_emit_xor_r8_r8,      E_xor_r8_r8),
    V("push rbx",              g_emit_push_rbx,       E_push_rbx),
    V("push r15",              g_emit_push_r15,       E_push_r15),
    V("pop rbx",               g_emit_pop_rbx,        E_pop_rbx),
    V("ret",                   g_emit_ret,            E_ret),
    V("mfence",                g_emit_mfence,         E_mfence),
    V("pause",                 g_emit_pause,          E_pause),
    V("vmrun",                 g_emit_vmrun,          E_vmrun),
    V("vmsave",                g_emit_vmsave,         E_vmsave),
    V("nop(9) canonical",      g_emit_nop9,           E_nop9),
    V("nop(1) canonical",      g_emit_nop1,           E_nop1),
    V("lea rax, [rsp+8]",      g_emit_lea_rax_rsp_8,  E_lea_rax_rsp_8)
};

#undef V

int iii_jit_self_test(void)
{
    uint8_t  scratch[64];
    iii_jit_buf_t b;
    const size_t n = sizeof(k_golden_vecs) / sizeof(k_golden_vecs[0]);
    for (size_t i = 0; i < n; ++i) {
        iii_jit_init(&b, scratch, sizeof(scratch));
        memset(scratch, 0xCC, sizeof(scratch));
        k_golden_vecs[i].emit(&b);
        if (b.err != III_JIT_E_OK) return (int)(i + 1);
        if (b.used != k_golden_vecs[i].expected_len) return (int)(i + 1);
        if (memcmp(scratch, k_golden_vecs[i].expected, b.used) != 0) return (int)(i + 1);
    }
    return 0;
}

/* ════════════════════════════════════════════════════════════════════
 * Lattice plan Step 0023 — Zero-downtime crystal hot-swap.
 *
 * Trampoline table: 256 slots × 32 bytes = 8 KiB.
 * Pool: 64 KiB code arena.
 *
 * Discipline: every public function is single-threaded reentrant
 * w.r.t. swaps on DIFFERENT crystal_ids; concurrent swaps on the
 * SAME crystal_id are serialized by the caller (Stage-0 has no
 * cross-thread coordination).
 * ════════════════════════════════════════════════════════════════════ */

typedef struct {
    uint64_t code_ptr;       /* current pointer into G_JIT_POOL (or 0) */
    uint32_t code_size;
    uint32_t version;
    uint32_t linear_outstanding;  /* @linear references (Stage-0: always 0) */
    uint8_t  reserved[12];
} iii_jit_trampoline_slot_t;

static iii_jit_trampoline_slot_t G_JIT_TRAMPOLINE[III_JIT_TRAMPOLINE_SLOTS];
static uint8_t                   G_JIT_POOL[III_JIT_TRAMPOLINE_POOL];
static uint32_t                  G_JIT_POOL_USED = 0;

/* Compute slot index from crystal_id.  Stage-0: low 8 bits as index
 * (collisions are caller's responsibility — Step 0086 introduces
 * a hashed table with chaining).  */
static inline uint32_t iii_jit_slot_of(uint64_t crystal_id)
{
    return (uint32_t)(crystal_id & 0xFFu);
}

iii_jit_swap_err_t iii_jit_swap_crystal(uint64_t       old_crystal_id,
                                              const uint8_t *new_machine_code,
                                              uint32_t       new_size)
{
    if (!new_machine_code) return III_JIT_SWAP_E_NULL_ARG;
    if (new_size == 0)    return III_JIT_SWAP_E_NULL_ARG;
    if (new_size > III_JIT_TRAMPOLINE_POOL) return III_JIT_SWAP_E_SIZE_OVERFLOW;

    /* Allocate page-aligned region in the pool.  Stage-0 uses a 16-byte
     * alignment (matches typical x86 SIMD); Stage-1 will switch to
     * per-OS page granularity once VirtualAlloc/mmap wiring lands. */
    uint32_t aligned = (G_JIT_POOL_USED + 15u) & ~15u;
    if (aligned + new_size > III_JIT_TRAMPOLINE_POOL) {
        return III_JIT_SWAP_E_OOM;
    }
    /* Copy new code into the freshly allocated region. */
    memcpy(G_JIT_POOL + aligned, new_machine_code, new_size);
    uint64_t new_ptr = (uint64_t)(uintptr_t)(G_JIT_POOL + aligned);

    /* Atomic 8-byte store of the new pointer (single aligned MOV on
     * x86-64 is naturally atomic w.r.t. other 8-byte aligned reads). */
    uint32_t slot = iii_jit_slot_of(old_crystal_id);
    iii_jit_trampoline_slot_t *t = &G_JIT_TRAMPOLINE[slot];
    /* Bump version BEFORE pointer swap so concurrent readers see a
     * monotone version, even briefly, that's >= the version they
     * observed under the OLD code_ptr. */
    t->version = t->version + 1u;
    /* The pointer write is the linearisation point. */
    t->code_ptr = new_ptr;
    t->code_size = new_size;
    /* Don't touch linear_outstanding — that's the GC's responsibility. */
    G_JIT_POOL_USED = aligned + new_size;
    return III_JIT_SWAP_OK;
}

uint32_t iii_jit_linear_owned_check(uint64_t crystal_id)
{
    uint32_t slot = iii_jit_slot_of(crystal_id);
    return G_JIT_TRAMPOLINE[slot].linear_outstanding;
}

uint64_t iii_jit_trampoline_code_ptr(uint64_t crystal_id)
{
    uint32_t slot = iii_jit_slot_of(crystal_id);
    return G_JIT_TRAMPOLINE[slot].code_ptr;
}

uint32_t iii_jit_trampoline_code_size(uint64_t crystal_id)
{
    uint32_t slot = iii_jit_slot_of(crystal_id);
    return G_JIT_TRAMPOLINE[slot].code_size;
}

uint32_t iii_jit_trampoline_version(uint64_t crystal_id)
{
    uint32_t slot = iii_jit_slot_of(crystal_id);
    return G_JIT_TRAMPOLINE[slot].version;
}

void iii_jit_trampoline_reset(void)
{
    memset(G_JIT_TRAMPOLINE, 0, sizeof G_JIT_TRAMPOLINE);
    memset(G_JIT_POOL,       0, sizeof G_JIT_POOL);
    G_JIT_POOL_USED = 0;
}
