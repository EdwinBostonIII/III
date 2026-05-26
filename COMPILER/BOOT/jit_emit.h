/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\jit_emit.h
 *
 * III Stage-0 NIH x86-64 Instruction Emitter — public interface.
 *
 * Hand-rolled binary encoder for the AMD64 baseline (Stage 0 scope:
 * AMD64 + AVX2 are wired in this header; AVX-512 is left as a runtime-
 * detected accelerator slot per ADR-027 §11 question 3).  The
 * encoder writes raw bytes to a caller-supplied buffer; instruction
 * positions are exposed as offsets so the JIT runtime can patch
 * forward-jump targets.
 *
 * Spec source:
 *   - Intel SDM Vol. 2 (Instruction Set Reference) — opcode tables,
 *     ModR/M, SIB, displacement encoding.
 *   - AMD APM Vol. 3 (General-Purpose and System Instructions) —
 *     SVM-specific opcodes (VMRUN/VMSAVE/VMLOAD/CLGI/STGI/INVLPGA).
 *
 * Strict NIH per ADR-021: zero asmjit, zero LLVM, zero xed.  Every
 * instruction encoder here is the result of reading the SDM/APM
 * tables by hand.
 *
 * Register encoding convention (AMD64):
 *   rax=0, rcx=1, rdx=2, rbx=3, rsp=4, rbp=5, rsi=6, rdi=7,
 *   r8=8,  r9=9,  r10=10, r11=11, r12=12, r13=13, r14=14, r15=15.
 *   The high bit (8..15) requires REX.B / REX.R / REX.X depending on
 *   which slot it occupies in the encoding.
 *
 * Deepenings versus the LOGOS Stage-0 ancestor (this header is the
 * III port; binary is iiis-0):
 *   D1  Per-encoder Intel SDM citation in every encoder (mandatory).
 *   D2  Pure REX builder: iii_jit_compute_rex(W,R,X,B) — replaces
 *       inline bit math previously sprinkled across encoders.
 *   D3  Pure ModR/M and SIB builders with named-constant fields and
 *       impossibility assertions (e.g. mod=11 forbids SIB).
 *   D4  Branch-displacement patcher with overflow detection: rel8
 *       and rel32 patchers return III_JIT_E_DISP_OVERFLOW when the
 *       computed offset does not fit.
 *   D5  Golden-bytes self-test (iii_jit_self_test) re-encodes a
 *       static array of (instruction, expected_byte_seq) vectors
 *       derived from Intel SDM examples and asserts byte equality.
 *   D8  iii_jit_buf_t carries an err field with abort-on-error
 *       semantics; the first error poisons the context and every
 *       subsequent encoder short-circuits.  Eliminates per-call
 *       return-checking from callers.
 *   D9  Explicit AVX-512 stubs returning III_JIT_E_NOT_IMPLEMENTED
 *       (citation ADR-027 §11 q3) — present so the JIT runtime can
 *       detect-and-skip without conditionally including the header.
 *   D11 Canonical multi-byte NOP table (Intel SDM Vol. 2B "NOP"
 *       recommended forms) — iii_jit_emit_nop(n) is deterministic.
 *   D12 Stable symbol-relocation record struct (iii_jit_reloc_t).
 *   D14 SVM safety bracket iii_jit_emit_vm_session() emits
 *       VMSAVE → VMRUN → VMLOAD atomically per APM Vol. 3 §15.5.
 *
 * Rejected deepenings (rationale recorded for posterity):
 *   D6  Streaming SHA-256 fingerprint — ~200 lines of crypto in an
 *       encoder header is bloat; reproducibility is already proved
 *       by the golden-bytes self-test (D5).
 *   D7  Per-instruction insn-id enum + dispatcher — duplicates the
 *       per-mnemonic API which is itself the stable wire format;
 *       net effect is doubled surface area for zero new property.
 *   D10 Spectre/retpoline thunks — out of Stage-0 scope; depends on
 *       a thunk symbol contract not yet defined.
 *   D13 Per-instruction encoding witness — depends on D7 (rejected)
 *       and adds an operand_hash without proving anything D5 does
 *       not already prove.
 */

#ifndef III_BOOT_JIT_EMIT_H
#define III_BOOT_JIT_EMIT_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ─── Error codes (D8) ────────────────────────────────────────────── */
typedef enum {
    III_JIT_E_OK              = 0,
    III_JIT_E_BUF_OVERFLOW    = 1,  /* write would exceed cap          */
    III_JIT_E_DISP_OVERFLOW   = 2,  /* rel8/rel32 displacement out of range */
    III_JIT_E_BAD_OPERAND     = 3,  /* impossible operand combination  */
    III_JIT_E_BAD_PATCH_SITE  = 4,  /* patch offset outside buffer     */
    III_JIT_E_NOT_IMPLEMENTED = 5,  /* AVX-512 / future slot           */
    III_JIT_E_RELOC_FULL      = 6   /* relocation table capacity hit   */
} iii_jit_err_t;

/* Register identifiers (matching AMD64 encoding).  Values 0..15. */
typedef enum {
    III_REG_RAX = 0,  III_REG_RCX = 1,  III_REG_RDX = 2,  III_REG_RBX = 3,
    III_REG_RSP = 4,  III_REG_RBP = 5,  III_REG_RSI = 6,  III_REG_RDI = 7,
    III_REG_R8  = 8,  III_REG_R9  = 9,  III_REG_R10 = 10, III_REG_R11 = 11,
    III_REG_R12 = 12, III_REG_R13 = 13, III_REG_R14 = 14, III_REG_R15 = 15
} iii_reg_t;

/* Condition codes (Intel SDM Vol. 1 §3.6 / §B.1.2). */
typedef enum {
    III_CC_O   = 0x0, III_CC_NO  = 0x1,
    III_CC_B   = 0x2, III_CC_AE  = 0x3,
    III_CC_E   = 0x4, III_CC_NE  = 0x5,
    III_CC_BE  = 0x6, III_CC_A   = 0x7,
    III_CC_S   = 0x8, III_CC_NS  = 0x9,
    III_CC_P   = 0xA, III_CC_NP  = 0xB,
    III_CC_L   = 0xC, III_CC_GE  = 0xD,
    III_CC_LE  = 0xE, III_CC_G   = 0xF
} iii_cc_t;

/* ─── Symbol-relocation record (D12) ──────────────────────────────── */
typedef enum {
    III_JIT_RELOC_NONE     = 0,
    III_JIT_RELOC_REL32    = 1,  /* call/jmp rel32 displacement       */
    III_JIT_RELOC_REL8     = 2,  /* short jcc rel8 displacement       */
    III_JIT_RELOC_ABS64    = 3   /* movabs imm64                      */
} iii_jit_reloc_kind_t;

typedef struct {
    uint32_t offset;     /* offset of the immediate field in the buffer */
    uint32_t symbol_id;  /* opaque symbol identifier (caller-defined)   */
    uint16_t kind;       /* iii_jit_reloc_kind_t                        */
    uint16_t reserved;   /* deterministic padding, must be 0            */
} iii_jit_reloc_t;

/* ─── Encoder context (D8) ────────────────────────────────────────── *
 *
 * Abort-on-error: once `err` becomes non-zero, every subsequent
 * encoder is a no-op.  Callers may drop per-call return checks and
 * inspect `b->err` once at end-of-block.  `last_insn_off` records
 * the byte-offset where the most recent instruction began (used by
 * encoders that wish to emit a witness or rewind on a late failure).
 */
typedef struct {
    uint8_t            *buf;
    size_t              cap;
    size_t              used;
    int                 overflow;       /* 1 if any emit exceeded cap (legacy) */
    iii_jit_err_t       err;            /* poisoned-context flag (D8)          */
    size_t              last_insn_off;  /* start of most recent instruction    */
    iii_jit_reloc_t    *relocs;         /* optional, may be NULL               */
    size_t              reloc_cap;
    size_t              reloc_used;
} iii_jit_buf_t;

/* Initialise an emitter buffer over `bytes[0..cap)`.  The caller owns
 * the storage; the emitter only writes.  Relocation table is empty;
 * use iii_jit_attach_relocs() to opt in. */
void iii_jit_init(iii_jit_buf_t *b, uint8_t *bytes, size_t cap);

/* Attach (or detach) a caller-owned relocation table. */
void iii_jit_attach_relocs(iii_jit_buf_t *b, iii_jit_reloc_t *r, size_t cap);

/* Inspect / clear the error.  Clearing also clears the legacy overflow flag. */
iii_jit_err_t iii_jit_error(const iii_jit_buf_t *b);
void          iii_jit_clear_error(iii_jit_buf_t *b);

/* Raw byte / word emitters. */
void iii_jit_byte (iii_jit_buf_t *b, uint8_t v);
void iii_jit_word (iii_jit_buf_t *b, uint16_t v);
void iii_jit_dword(iii_jit_buf_t *b, uint32_t v);
void iii_jit_qword(iii_jit_buf_t *b, uint64_t v);

/* Current write offset (used as label position for backpatching). */
size_t iii_jit_offset(const iii_jit_buf_t *b);

/* ─── D2/D3 pure encoding-field builders ──────────────────────────── *
 *
 * These are the *only* sites where REX/ModR/M/SIB bit math lives.
 * Encoders below call them; tests can call them in isolation.
 */

/* REX byte = 0100_WRXB (Intel SDM Vol. 2 §2.2.1 Fig. 2-3).
 * Each input must be 0 or 1; any other value is clamped to 1. */
uint8_t iii_jit_compute_rex(int W, int R, int X, int B);

/* ModR/M byte = mod[7:6] reg[5:3] rm[2:0] (Intel SDM Vol. 2 §2.1.5).
 * Asserts mod ∈ {0,1,2,3}; reg ∈ [0,7]; rm ∈ [0,7].
 * Note: the caller is responsible for ensuring (mod,rm) does not
 * imply a SIB when the caller has not also emitted a SIB byte. */
uint8_t iii_jit_compute_modrm(int mod, int reg, int rm);

/* SIB byte = scale[7:6] index[5:3] base[2:0] (Intel SDM Vol. 2 §2.1.5).
 * scale ∈ {0,1,2,3} encoding {1,2,4,8}; index/base ∈ [0,7].
 * Asserts 0 ≤ scale ≤ 3.  SIB is illegal when ModR/M.mod=11; the
 * encoders enforce this on their callers, not here. */
uint8_t iii_jit_compute_sib(int scale, int index, int base);

/* ─── D4 displacement patchers ────────────────────────────────────── */

/* Patch a 32-bit displacement at `offset` to point to `target`.
 * Returns III_JIT_E_DISP_OVERFLOW iff (target - (offset+4)) does not
 * fit in int32_t (the addressable rel32 range).  Sets b->err. */
iii_jit_err_t iii_jit_patch_rel32(iii_jit_buf_t *b, size_t offset, size_t target);

/* Patch an 8-bit displacement at `offset` to point to `target`.
 * Returns III_JIT_E_DISP_OVERFLOW iff (target - (offset+1)) is not
 * in [-128,127].  Sets b->err on overflow. */
iii_jit_err_t iii_jit_patch_rel8 (iii_jit_buf_t *b, size_t offset, size_t target);

/* ─── REX-prefixed register move / arithmetic ─────────────────────── */

/* mov reg, imm64  (movabs).  Always emits REX.W. */
void iii_jit_mov_r64_imm64(iii_jit_buf_t *b, iii_reg_t dst, uint64_t imm);

/* mov reg, reg.  Emits REX.W. */
void iii_jit_mov_r64_r64(iii_jit_buf_t *b, iii_reg_t dst, iii_reg_t src);

/* mov reg, [reg + disp32]. */
void iii_jit_mov_r64_mem(iii_jit_buf_t *b, iii_reg_t dst, iii_reg_t base, int32_t disp);

/* mov [reg + disp32], reg. */
void iii_jit_mov_mem_r64(iii_jit_buf_t *b, iii_reg_t base, int32_t disp, iii_reg_t src);

/* lea reg, [reg + disp32]. */
void iii_jit_lea_r64_mem(iii_jit_buf_t *b, iii_reg_t dst, iii_reg_t base, int32_t disp);

/* Arithmetic: add / sub / xor / and / or / cmp.  All r64 operands. */
void iii_jit_add_r64_r64(iii_jit_buf_t *b, iii_reg_t dst, iii_reg_t src);
void iii_jit_sub_r64_r64(iii_jit_buf_t *b, iii_reg_t dst, iii_reg_t src);
void iii_jit_xor_r64_r64(iii_jit_buf_t *b, iii_reg_t dst, iii_reg_t src);
void iii_jit_and_r64_r64(iii_jit_buf_t *b, iii_reg_t dst, iii_reg_t src);
void iii_jit_or_r64_r64 (iii_jit_buf_t *b, iii_reg_t dst, iii_reg_t src);
void iii_jit_cmp_r64_r64(iii_jit_buf_t *b, iii_reg_t left, iii_reg_t right);
void iii_jit_test_r64_r64(iii_jit_buf_t *b, iii_reg_t l, iii_reg_t r);

/* Shifts (CL register implicit; src must equal III_REG_RCX). */
void iii_jit_shl_r64_cl(iii_jit_buf_t *b, iii_reg_t dst);
void iii_jit_shr_r64_cl(iii_jit_buf_t *b, iii_reg_t dst);
void iii_jit_sar_r64_cl(iii_jit_buf_t *b, iii_reg_t dst);

/* Multiply / divide (signed 64-bit). */
void iii_jit_imul_r64_r64(iii_jit_buf_t *b, iii_reg_t dst, iii_reg_t src);
void iii_jit_cqto(iii_jit_buf_t *b);
void iii_jit_idiv_r64(iii_jit_buf_t *b, iii_reg_t divisor);

/* Push / pop. */
void iii_jit_push_r64(iii_jit_buf_t *b, iii_reg_t r);
void iii_jit_pop_r64 (iii_jit_buf_t *b, iii_reg_t r);

/* Stack-pointer adjust.  dst should be RSP. */
void iii_jit_add_r64_imm32(iii_jit_buf_t *b, iii_reg_t dst, int32_t imm);
void iii_jit_sub_r64_imm32(iii_jit_buf_t *b, iii_reg_t dst, int32_t imm);

/* Set-cc: stores 1 or 0 in the LOW byte of `dst`. */
void iii_jit_setcc_r8(iii_jit_buf_t *b, iii_cc_t cc, iii_reg_t dst);

/* movzbq r64, r8 (zero-extend low byte of dst into dst). */
void iii_jit_movzbq_r64_r8(iii_jit_buf_t *b, iii_reg_t dst, iii_reg_t src8);

/* Control flow.  Forward jumps emit the displacement field unpatched
 * (returning the offset of the disp32 for later iii_jit_patch_rel32);
 * backward jumps take the absolute target offset and emit a fixed disp32. */
size_t iii_jit_jmp_rel32(iii_jit_buf_t *b);              /* unpatched */
size_t iii_jit_jcc_rel32(iii_jit_buf_t *b, iii_cc_t cc); /* unpatched */
/* Short-form variants (return offset of the rel8 byte). */
size_t iii_jit_jmp_rel8 (iii_jit_buf_t *b);              /* unpatched, opcode EB */
size_t iii_jit_jcc_rel8 (iii_jit_buf_t *b, iii_cc_t cc); /* unpatched, opcode 70+cc */

void   iii_jit_call_rel32(iii_jit_buf_t *b, int32_t rel32);
void   iii_jit_call_r64(iii_jit_buf_t *b, iii_reg_t target);
void   iii_jit_ret(iii_jit_buf_t *b);

/* ─── D12 relocation recording ────────────────────────────────────── *
 *
 * Append a relocation record describing a pending fixup.  Returns
 * III_JIT_E_RELOC_FULL if no table is attached or capacity is hit.
 */
iii_jit_err_t iii_jit_record_reloc(iii_jit_buf_t *b,
                                   uint32_t offset,
                                   iii_jit_reloc_kind_t kind,
                                   uint32_t symbol_id);

/* Privileged / SVM instructions (used by IRPD-promoted JIT bodies).
 * All are direct opcode-byte emissions per AMD APM Vol. 3 §B.4. */
void iii_jit_rdmsr(iii_jit_buf_t *b);
void iii_jit_wrmsr(iii_jit_buf_t *b);
void iii_jit_clgi (iii_jit_buf_t *b);
void iii_jit_stgi (iii_jit_buf_t *b);
void iii_jit_vmsave(iii_jit_buf_t *b);
void iii_jit_vmload(iii_jit_buf_t *b);
void iii_jit_vmrun (iii_jit_buf_t *b);  /* AMD APM Vol. 3 §15.5: 0F 01 D8 */

/* ─── D14 SVM safety bracket ─────────────────────────────────────── *
 *
 * Per AMD APM Vol. 3 §15.5 ("VMRUN Instruction"), a host that wishes
 * to preserve its own segment / system state across a guest entry
 * must execute VMSAVE prior to VMRUN and VMLOAD upon return.  This
 * helper emits the canonical bracket as a single atomic encoder
 * call.  RAX must already hold the host save-area physical address
 * for VMSAVE / VMLOAD; RAX must hold the guest VMCB physical address
 * at VMRUN — these register-loads are the caller's responsibility.
 *
 * Asserts that exactly 9 bytes were emitted (3 × 3 byte SVM ops).
 * On an emit-time error the context is poisoned per D8 and used
 * is rewound to the pre-call value so the caller's basic block
 * does not contain a half-emitted SVM bracket.
 */
iii_jit_err_t iii_jit_emit_vm_session(iii_jit_buf_t *b);

/* Memory fence. */
void iii_jit_mfence(iii_jit_buf_t *b);
void iii_jit_lfence(iii_jit_buf_t *b);
void iii_jit_sfence(iii_jit_buf_t *b);

/* PAUSE — for spin loops.  Encodes as F3 90. */
void iii_jit_pause(iii_jit_buf_t *b);

/* ─── D11 canonical NOP padding ──────────────────────────────────── *
 *
 * Emits exactly `n` bytes of canonical multi-byte NOP padding using
 * the Intel SDM Vol. 2B "NOP — No Operation" recommended sequences
 * (see "Recommended Multi-Byte Sequence of NOP Instruction").
 * For n > 9 the encoder emits the maximum 9-byte NOP repeatedly
 * plus a tail.  The output is a deterministic function of `n` —
 * required for reproducible PE/ELF section padding.
 */
void iii_jit_emit_nop(iii_jit_buf_t *b, size_t n);

/* ─── D9 AVX-512 stubs ──────────────────────────────────────────── *
 *
 * AVX-512 (EVEX prefix) is intentionally not yet wired.  Per
 * ADR-027 §11 q3 it is a runtime-detected accelerator slot.  These
 * stubs always return III_JIT_E_NOT_IMPLEMENTED and poison the
 * context.  They exist so the JIT runtime can detect-and-skip
 * without conditionally including the header.
 */
iii_jit_err_t iii_jit_avx512_vmovdqa64_stub(iii_jit_buf_t *b);
iii_jit_err_t iii_jit_avx512_vpaddq_stub  (iii_jit_buf_t *b);

/* ─── D5 self-test ──────────────────────────────────────────────── *
 *
 * Re-encodes a static array of (instruction, expected_byte_seq)
 * vectors derived from Intel SDM examples.  Returns 0 on success
 * or 1-based vector index of the first failure.  Used as a
 * reproducibility gate at boot of the iiis-0 binary.
 */
int iii_jit_self_test(void);

/* ─── Lattice plan Step 0023 — zero-downtime crystal hot-swap ────────
 *
 * jit_swap_crystal replaces a live function's machine-code bytes with
 * a new implementation while preserving any @linear resources owned
 * by callers.  The transition is atomic via a single 8-byte aligned
 * write to the trampoline pointer table; in-flight calls into the
 * old code see consistent (read-only) bytes for their entire
 * execution because the old slot remains live until
 * jit_linear_owned_check(crystal_id) returns 0.
 *
 * Trampoline layout (per crystal_id):
 *   slot[0..7]   : current code pointer (8-byte aligned, atomically swapped)
 *   slot[8..15]  : current code size (informational)
 *   slot[16..23] : version counter (incremented on every swap)
 *   slot[24..31] : @linear outstanding-reference count (decrements
 *                  back to zero before the old slot can be freed)
 *
 * Stage-0: 256-slot static trampoline table (32 bytes per slot = 8 KiB).
 * Stage-1: dynamic + per-arena trampoline pools.
 *
 * jit_swap_crystal copies new_machine_code into a freshly allocated
 * page-aligned region within the trampoline pool, then atomically
 * stores the new pointer at slot.code_ptr.  Old code is NOT freed
 * here; jit_linear_release_old runs the GC pass.
 */

#define III_JIT_TRAMPOLINE_SLOTS  256u
#define III_JIT_TRAMPOLINE_POOL   65536u   /* 64 KiB per pool */

typedef enum {
    III_JIT_SWAP_OK              = 0,
    III_JIT_SWAP_E_BAD_ID        = 1,
    III_JIT_SWAP_E_OOM           = 2,      /* trampoline pool exhausted */
    III_JIT_SWAP_E_NULL_ARG      = 3,
    III_JIT_SWAP_E_SIZE_OVERFLOW = 4
} iii_jit_swap_err_t;

iii_jit_swap_err_t iii_jit_swap_crystal(uint64_t       old_crystal_id,
                                              const uint8_t *new_machine_code,
                                              uint32_t       new_size);

/* Returns the count of outstanding @linear references against the
 * given crystal_id.  Stage-0 returns 0 (linear tracking lands in
 * Step 0086 / Phase 11); Stage-1 wires real refcounting from cap
 * issue/revoke. */
uint32_t           iii_jit_linear_owned_check(uint64_t crystal_id);

/* Read accessors for the trampoline slot. */
uint64_t           iii_jit_trampoline_code_ptr(uint64_t crystal_id);
uint32_t           iii_jit_trampoline_code_size(uint64_t crystal_id);
uint32_t           iii_jit_trampoline_version(uint64_t crystal_id);

/* Reset the trampoline table (for tests; production: never called). */
void               iii_jit_trampoline_reset(void);

#ifdef __cplusplus
}
#endif

#endif /* III_BOOT_JIT_EMIT_H */
