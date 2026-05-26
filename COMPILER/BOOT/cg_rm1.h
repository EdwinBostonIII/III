/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\cg_rm1.h
 *
 * III Stage-0 Ring -1 (bare-metal hypervisor) Codegen — public interface.
 *
 * Targets the freestanding iiis-0 hypervisor blob (iii_hv.bin / iii_hv.efi).
 * Calling convention is **System V AMD64** (gcc -mabi=sysv) because this is
 * a bare-metal target driven by GAS / clang / mingw cross-toolchains under
 * the SysV ABI — *not* the Windows-hosted MS x64 ABI of cg_r3.
 *   Citation: "System V Application Binary Interface — AMD64 Architecture
 *              Processor Supplement (Draft v1.0)" §3.2  Function Calling
 *              Sequence.  Integer args 1..6 → rdi, rsi, rdx, rcx, r8, r9.
 *              Callee-saved: rbp, rbx, r12, r13, r14, r15.
 *
 * Identity-mapped paging; no host libc; no host CRT.  Witness emission
 * writes directly to the per-CPU forward ring pinned at HV bring-up.
 *
 * Coexists with jit_emit.{h,c} for raw-byte SVM/VMX opcode emission
 * (VMRUN/VMSAVE/VMLOAD/VMLAUNCH/VMRESUME/VMREAD/VMWRITE/CLGI/STGI/INVLPGA).
 *
 * Strict NIH per ADR-021: no LLVM, no asmjit, no host libc dependencies in
 * the *emitted* image.  Determinism per ADR-008 §4.
 *
 * ─── Deepenings adopted (vs. LOGOS Stage-0 ancestor) ────────────────────
 *
 * D1  ABI invariant: SysV x64.  Codegen asserts (stack_depth & 1) == 0
 *     before every CALL boundary (rsp ≡ 16-byte aligned at the call
 *     instruction; SysV AMD64 §3.2.2).  Failure → III_CG_RM1_E_ABI_ALIGN.
 *
 * D2  Bare-metal startup contract: the emitted entry symbol
 *     `iii_hv_entry` receives control with **no usable stack**.  cg_rm1
 *     emits stack pointer setup as the first instruction of the entry
 *     thunk:
 *           leaq __iii_hv_stack_top(%rip), %rsp
 *           xorq %rbp, %rbp
 *           jmp  iii_hv_main
 *     The linker must export `__iii_hv_stack_top` at the high end of a
 *     16 KiB BSS region (64-byte aligned).
 *
 * D3  VMX/SVM detection emission: `iii_cg_rm1_emit_vmx_svm_dispatch` emits
 *     a CPUID leaf 1 ECX[5] (VMX) and CPUID leaf 0x80000001 ECX[2] (SVM)
 *     feature probe followed by a branch to the appropriate path.
 *     Citation: Intel SDM Vol. 2A "CPUID — CPU Identification" Table 3-10.
 *               AMD APM Vol. 3 §3.3 (CPUID 8000_0001h ECX, bit 2 SVM).
 *
 * D4  VMCS / VMCB layout offset constants (see III_HV_VMCS_*, III_HV_VMCB_*
 *     enums below).  Replaces magic-number offsets in emitted asm.
 *     Intel SDM Vol. 3 Appendix A "VMX Capability and VMCS Field Encodings".
 *     AMD   APM  Vol. 2 §15.5 "VMCB Layout".
 *
 * D5  EPT (Intel) / NPT (AMD) page-table emission: identity-mapped 4 GiB
 *     using 4-level paging with 2 MiB large pages.  Emits the PML4, PDPT
 *     and 4× PD tables into `.rodata.iii_hv_slat`.
 *     Intel SDM Vol. 3 §28 "VMX Support for Address Translation".
 *     AMD   APM  Vol. 2 §15.25 "Nested Paging".
 *
 * D6  Ring-wall: cg_rm1 REFUSES to emit any direct CALL whose target name
 *     starts with `ring0_` or `ring3_` unless the call site is itself
 *     within an authorized gateway cycle (name starts with `vmexit_`,
 *     `hcall_`, or `vmrun_`).  Violation → III_CG_RM1_E_RING_WALL.
 *
 * D7  VM-exit dispatch table: codegen emits `iii_hv_vmexit_table` indexed
 *     by exit reason, populated from cycles whose name starts with
 *     `vmexit_NN_` (Intel SDM Vol. 3 Appendix C "VMX Basic Exit Reasons";
 *     AMD APM Vol. 2 §15.7 "Intercepts").
 *
 * D8  Witness call discipline: every cycle entry and exit emits a call to
 *     `iii_witness_emit_hv` with the cycle's witness ID.  The witness ring
 *     buffer is a fixed `__iii_hv_witness_ring[4096]` allocated in BSS at
 *     link time — NO malloc, NO heap.
 *
 * D9  Codegen witness: SHA-256 over the entire emitted-asm byte stream is
 *     accumulated as cg_rm1 writes; the final digest is emitted as a
 *     comment trailer `# III_CG_RM1_ASM_SHA256: <64 hex>` and queried via
 *     iii_cg_rm1_asm_sha256().
 *
 * D10 Reproducibility: NOP padding uses a deterministic single-byte 0x90
 *     pattern; .align directives are emitted with explicit fill byte 0x90.
 *
 * D11 Stack-canary emission for cycles whose name starts with `canary_`
 *     (or whose AST attribute set contains `@canary`, when the AST exposes
 *     attribute lists in a future revision): prologue stores
 *     `__iii_hv_canary_seed` into the highest local slot; epilogue compares
 *     and jumps to `__iii_hv_canary_fail` on mismatch.
 *
 * D12 SVM safety bracket: `iii_cg_rm1_emit_svm_vmrun_bracket` emits the
 *     full sequence `clgi; vmload; vmrun; vmsave; stgi;` atomically.  An
 *     internal counter rejects unbalanced brackets.
 *     Citation: AMD APM Vol. 3 §15.5 "VMRUN Instruction".
 *
 * D13 VMX safety bracket: `iii_cg_rm1_emit_vmx_vmrun_bracket` selects
 *     VMLAUNCH vs VMRESUME based on a per-VCPU 1-byte `launched` flag
 *     stored at `__iii_hv_vcpu_launched(%rip)`.
 *     Citation: Intel SDM Vol. 3 §26.1 "VMLAUNCH/VMRESUME Operation".
 *
 * D14 Every emit helper carries an inline spec citation in its definition
 *     comment.
 */
#ifndef III_BOOT_CG_RM1_H
#define III_BOOT_CG_RM1_H

#include <stdint.h>
#include <stddef.h>
#include <stdio.h>

#include "ast.h"
#include "sema.h"
#include "sid.h"
#include "witness_alloc.h"

#ifdef __cplusplus
extern "C" {
#endif

/* ─── Error codes ──────────────────────────────────────────────────── */

#define III_CG_RM1_OK              0
#define III_CG_RM1_E_NULL_ARG      1
#define III_CG_RM1_E_IO            2
#define III_CG_RM1_E_UNSUPPORTED   3
#define III_CG_RM1_E_ABI_ALIGN     4   /* SysV §3.2.2 16-byte rsp violation */
#define III_CG_RM1_E_RING_WALL     5   /* D6 ring-0/3 cross-call refused    */
#define III_CG_RM1_E_BRACKET       6   /* D12 unbalanced VMRUN bracket      */
#define III_CG_RM1_E_INTERNAL      99

/* ─── D4: VMCS field encodings (Intel SDM Vol. 3 Appendix A) ───────── */

enum {
    /* Guest-state area (Appendix A.4). */
    III_HV_VMCS_FIELD_GUEST_ES_SELECTOR        = 0x0800,
    III_HV_VMCS_FIELD_GUEST_CS_SELECTOR        = 0x0802,
    III_HV_VMCS_FIELD_GUEST_SS_SELECTOR        = 0x0804,
    III_HV_VMCS_FIELD_GUEST_DS_SELECTOR        = 0x0806,
    III_HV_VMCS_FIELD_GUEST_TR_SELECTOR        = 0x080E,
    III_HV_VMCS_FIELD_GUEST_CR0                = 0x6800,
    III_HV_VMCS_FIELD_GUEST_CR3                = 0x6802,
    III_HV_VMCS_FIELD_GUEST_CR4                = 0x6804,
    III_HV_VMCS_FIELD_GUEST_RSP                = 0x681C,
    III_HV_VMCS_FIELD_GUEST_RIP                = 0x681E,
    III_HV_VMCS_FIELD_GUEST_RFLAGS             = 0x6820,

    /* Host-state area (Appendix A.5). */
    III_HV_VMCS_FIELD_HOST_CR0                 = 0x6C00,
    III_HV_VMCS_FIELD_HOST_CR3                 = 0x6C02,
    III_HV_VMCS_FIELD_HOST_CR4                 = 0x6C04,
    III_HV_VMCS_FIELD_HOST_RSP                 = 0x6C14,
    III_HV_VMCS_FIELD_HOST_RIP                 = 0x6C16,

    /* VM-execution control fields (Appendix A.3). */
    III_HV_VMCS_FIELD_PIN_BASED_CTLS           = 0x4000,
    III_HV_VMCS_FIELD_PROC_BASED_CTLS          = 0x4002,
    III_HV_VMCS_FIELD_PROC_BASED_CTLS2         = 0x401E,
    III_HV_VMCS_FIELD_EPT_POINTER              = 0x201A,

    /* VM-exit information (Appendix A.6). */
    III_HV_VMCS_FIELD_EXIT_REASON              = 0x4402,
    III_HV_VMCS_FIELD_EXIT_QUALIFICATION       = 0x6400,
    III_HV_VMCS_FIELD_GUEST_LINEAR_ADDR        = 0x640A,
    III_HV_VMCS_FIELD_GUEST_PHYSICAL_ADDR      = 0x2400
};

/* ─── D4: VMCB byte offsets (AMD APM Vol. 2 §15.5 Tables 15-9 / 15-10) ── */

enum {
    /* Control area (low 1024 bytes). */
    III_HV_VMCB_OFF_INTERCEPT_CR_RW            = 0x000,
    III_HV_VMCB_OFF_INTERCEPT_DR_RW            = 0x004,
    III_HV_VMCB_OFF_INTERCEPT_EXCEPTIONS       = 0x008,
    III_HV_VMCB_OFF_INTERCEPT_INSTR1           = 0x00C,
    III_HV_VMCB_OFF_INTERCEPT_INSTR2           = 0x010,
    III_HV_VMCB_OFF_TSC_OFFSET                 = 0x050,
    III_HV_VMCB_OFF_GUEST_ASID                 = 0x058,
    III_HV_VMCB_OFF_TLB_CONTROL                = 0x05C,
    III_HV_VMCB_OFF_VMCB_CLEAN                 = 0x0C0,
    III_HV_VMCB_OFF_NRIP                       = 0x0C8,
    III_HV_VMCB_OFF_NCR3                       = 0x0B0,   /* nested page-table CR3 */
    III_HV_VMCB_OFF_EXITCODE                   = 0x070,
    III_HV_VMCB_OFF_EXITINFO1                  = 0x078,
    III_HV_VMCB_OFF_EXITINFO2                  = 0x080,

    /* State save area (begins at offset 0x400). */
    III_HV_VMCB_OFF_GUEST_CR0                  = 0x548,
    III_HV_VMCB_OFF_GUEST_CR3                  = 0x550,
    III_HV_VMCB_OFF_GUEST_CR4                  = 0x558,
    III_HV_VMCB_OFF_GUEST_RFLAGS               = 0x570,
    III_HV_VMCB_OFF_GUEST_RIP                  = 0x578,
    III_HV_VMCB_OFF_GUEST_RSP                  = 0x5D8,
    III_HV_VMCB_OFF_GUEST_RAX                  = 0x5F8,
    III_HV_VMCB_OFF_GUEST_EFER                 = 0x540
};

/* ─── State + public API ───────────────────────────────────────────── */

struct iii_cg_rm1_state;
typedef struct iii_cg_rm1_state iii_cg_rm1_state_t;

iii_cg_rm1_state_t *iii_cg_rm1_create(iii_ast_t          *ast,
                                       iii_sema_state_t   *sema,
                                       iii_sid_state_t    *sid,
                                       iii_walloc_state_t *walloc);
void                iii_cg_rm1_destroy(iii_cg_rm1_state_t *cg);
int                 iii_cg_rm1_emit_module(iii_cg_rm1_state_t *cg, FILE *out);
int                 iii_cg_rm1_last_error(const iii_cg_rm1_state_t *cg);
const char         *iii_cg_rm1_error_name(int code);

/* D9 — codegen witness: SHA-256 over the emitted asm byte stream.
 * Returns a pointer to a 32-byte digest, valid until next emit_module
 * call.  Returns NULL if no module has been emitted. */
const uint8_t      *iii_cg_rm1_asm_sha256(const iii_cg_rm1_state_t *cg);

#ifdef __cplusplus
}
#endif

#endif /* III_BOOT_CG_RM1_H */
