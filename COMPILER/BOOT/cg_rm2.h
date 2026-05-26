/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\cg_rm2.h
 *
 * III Stage-0 Ring -2 (SANCTUM-sealed) Codegen — public interface.
 *
 * Targets the .xii_sanctum.text section linked into xii_hv.bin per
 * BUILD/xii_hv.lds.  SysV x64 ABI (same as cg_rm1) with:
 *   - Sanctum-internal stack carved at install time.
 *   - Callee-saved r12-r15 + rbp + rbx (preserved by gate trampoline
 *     in SANCTUM/sanctum_gate.S; the function body must respect
 *     these).
 *   - Witness emission via xii_sanctum_emit_cycle().
 *   - Section attribute "ax" (executable + alloc) on ELF and "xr"
 *     on PE/COFF for the sanctum code segment.
 *
 * ─── Sanctum semantics (root of trust) ────────────────────────────
 *
 *   Sanctum is the SMM-equivalent in the III architecture.  Code
 *   emitted here lives in `.xii_sanctum.text`, is measured at
 *   install time (a TPM PCR — typically PCR[17] for Intel TXT /
 *   PCR[23] under D-CRTM — is extended with the section's mhash),
 *   and is NOT modifiable post-seal.  Citations:
 *
 *     - SPEC.XII §S14 (sanctum cycles)
 *     - DRTM design (Intel TXT MLE Developer's Guide rev 17.2 §1.5;
 *       AMD SKINIT spec, AMD64 Vol 2 §15.27; TCG D-RTM Architecture
 *       Specification 1.0.0 rev 0.7).
 *     - TPM 2.0 Library Spec rev 1.59, Part 1 §34 (PCR extend).
 *     - Intel SMM transfer monitor analogue (Intel SDM Vol 3C §34).
 *
 *   The sanctum-sealed image MUST be byte-stable across builds —
 *   it is the root of trust for the III platform.  Hence this
 *   codegen is fully deterministic: no compiler-inserted padding,
 *   explicit `.balign`, no relocations.
 *
 * ─── Deepenings adopted (and their contracts) ─────────────────────
 *
 * D1  PIC-only enforcement.  Codegen REFUSES any absolute
 *     relocation; only PC-relative addressing modes (RIP-relative
 *     LEA / load / store / direct-call-to-symbol) are permitted.
 *     Every memory operand is asserted at emit time; failure sets
 *     III_CG_RM2_E_NON_PIC_RELOC.  Cite: AMD64 ABI §3.5.5
 *     (RIP-relative addressing); SysV x86_64 PSABI rev 1.0 §B.2.2.
 *
 * D2  Section emission.  Each function and rodata blob is wrapped
 *     in explicit section directives, both ELF and PE/COFF forms:
 *       ELF: `.section .xii_sanctum.text, "ax", @progbits`
 *            (cite: ELF gABI §4 — section attributes; gas info node
 *             "Section" for `"ax"` interpretation).
 *       PE : `.section .xii_sanctum.text, "xr"`
 *            (cite: PE/COFF Spec rev 11 §3.1 — IMAGE_SCN_CNT_CODE,
 *             IMAGE_SCN_MEM_EXECUTE, IMAGE_SCN_MEM_READ; gas docs
 *             on COFF section flags).
 *
 * D3  Section-mhash pre-image.  At the head of the sealed text
 *     section the codegen emits a 32-byte zero blob labeled
 *     `iii_sanctum_mhash_placeholder` aligned to 32B.  The post-link
 *     measurer (TOOLS/sanctum_seal — out-of-tree) overwrites those
 *     32 bytes with SHA-256(.xii_sanctum.text bytes excluding the
 *     placeholder window).  The same value is what gets extended
 *     into the TPM PCR.  Documented protocol: `iii_sanctum_seal v1`
 *     (cite: TCG PC Client Specific Implementation Specification
 *     for Conventional BIOS rev 1.21 §10.4.4 — measurement events).
 *
 * D4  Sanctum entry contract.  Every sealed-call method emitted is
 *     `void(__attribute__((sysv_abi)) iii_sanctum_entry)(uint64_t
 *     cap_handle)`; codegen rejects entries whose AST signature
 *     does not match (≥1 parameter, integer-class first parameter)
 *     with III_CG_RM2_E_BAD_ENTRY_SIG.  Cite: SysV AMD64 ABI rev
 *     1.0 §3.2.3 (parameter passing); SPEC.XII §S14.3.
 *
 * D5  No-touch list.  cg_rm2 REFUSES to emit instructions whose
 *     memory operand resolves to a symbol outside the permitted
 *     sanctum target sections.  Permitted targets:
 *         .xii_sanctum.text     (own code)
 *         .xii_sanctum.rodata   (own constants)
 *         .xii_sanctum.bss      (own scratch)
 *         .xii_sanctum.oneway   (write-only witness MMIO)
 *     Any other symbol reference yields
 *     III_CG_RM2_E_FORBIDDEN_TARGET.  Cite: Intel SDM Vol 3C §34.4
 *     on SMRAM isolation; SPEC.XII §S14.5 (sanctum address-space).
 *
 * D6  Constant-time discipline.  Per-cycle annotation `@const_time`
 *     (set via iii_cg_rm2_set_const_time) lowers branches over
 *     secret data to CMOVcc-based selection rather than Jcc.  Cite:
 *     FIPS 140-3 IG D.J (timing side-channels); BearSSL ct-coding
 *     guidelines; Intel optimization manual §3.4.1.2 on CMOV.
 *
 * D7  Oneway witness channel.  Witness emission uses ONLY writes to
 *     the symbol `iii_sanctum_oneway_port` (linker-mapped to the
 *     `.xii_sanctum.oneway` MMIO BAR).  Codegen rejects any read of
 *     that port with III_CG_RM2_E_ONEWAY_READ.  Cite: TCG D-RTM
 *     Architecture Spec 1.0 §3.5 (oneway primitives).
 *
 * D8  Codegen witness.  Streaming SHA-256 is updated over every
 *     emitted byte; the final digest is the canonical sanctum
 *     mhash root, retrievable via iii_cg_rm2_section_mhash().  This
 *     is the value the post-link sealer extends into the TPM PCR
 *     (D3 + D8 are the same digest by construction).
 *
 * D9  Reproducibility.  All alignment uses explicit `.balign N`;
 *     the codegen never relies on assembler-inserted padding.
 *     Determinism is verified by re-emitting and comparing the
 *     codegen-witness digest.  Cite: reproducible-builds.org spec.
 *
 * D10 Cap-handle discipline.  Every entry emits a call to
 *     `iii_cap_verify(cap_handle)` as the first non-prologue
 *     instruction.  The codegen tracks whether `iii_cap_revoke` is
 *     emitted on every control-flow path that returns; emit_module
 *     fails with III_CG_RM2_E_NO_CAP_REVOKE if not.  Cite: SPEC.XII
 *     §S6 (capability discipline); seL4 capability model.
 *
 * D11 Clear-on-exit.  Sanctum exit XOR-clears all SysV AMD64
 *     caller-saved volatile registers (rax, rcx, rdx, rsi, rdi,
 *     r8-r11, plus xmm0-xmm15).  Cite: SysV AMD64 ABI §3.2.1
 *     (volatile registers); side-channel hygiene per Intel
 *     "Speculative Execution Side Channel Mitigations" rev 3.0.
 *
 * D12 Stack-bottom invariant.  Entry zeros the entire reserved
 *     local frame (1024 bytes) and then re-establishes RBP, so
 *     stale stack contents never leak across sanctum invocations.
 *
 * D13 Spec citations on every emit helper.  See cg_rm2.c.
 *
 * D14 Lock-after-emit.  After iii_cg_rm2_module_finish() the state
 *     is sealed; further emits return III_CG_RM2_E_SEALED.
 *
 * Strict NIH (ADR-021): only stdlib + III BOOT headers.  Hand-rolled
 * mnemonic emission.  SHA-256 is NIH inline (RFC 6234).
 */
#ifndef III_BOOT_CG_RM2_H
#define III_BOOT_CG_RM2_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <stdio.h>

#include "ast.h"
#include "sema.h"
#include "sid.h"
#include "witness_alloc.h"

#ifdef __cplusplus
extern "C" {
#endif

/* ─── Error codes ─────────────────────────────────────────────────
 * Additive only.  Existing call-sites that switch on these codes
 * remain valid; new conditions extend the enum tail. */
#define III_CG_RM2_OK                  0
#define III_CG_RM2_E_NULL_ARG          1
#define III_CG_RM2_E_IO                2
#define III_CG_RM2_E_UNSUPPORTED       3
#define III_CG_RM2_E_NON_PIC_RELOC     4   /* D1 */
#define III_CG_RM2_E_FORBIDDEN_TARGET  5   /* D5 */
#define III_CG_RM2_E_BAD_ENTRY_SIG     6   /* D4 */
#define III_CG_RM2_E_ONEWAY_READ       7   /* D7 */
#define III_CG_RM2_E_NO_CAP_REVOKE     8   /* D10 */
#define III_CG_RM2_E_SEALED            9   /* D14 */
#define III_CG_RM2_E_INTERNAL          99

/* Output object-format selector for D2 (ELF vs PE/COFF section
 * directive form).  Default is ELF. */
typedef enum {
    III_CG_RM2_FMT_ELF = 0,
    III_CG_RM2_FMT_PE  = 1
} iii_cg_rm2_fmt_t;

struct iii_cg_rm2_state;
typedef struct iii_cg_rm2_state iii_cg_rm2_state_t;

/* Constructor / destructor (preserved API modulo rename). */
iii_cg_rm2_state_t *iii_cg_rm2_create(iii_ast_t          *ast,
                                       iii_sema_state_t   *sema,
                                       iii_sid_state_t    *sid,
                                       iii_walloc_state_t *walloc);
void                iii_cg_rm2_destroy(iii_cg_rm2_state_t *cg);

/* Output-format selector (D2). */
void iii_cg_rm2_set_format(iii_cg_rm2_state_t *cg, iii_cg_rm2_fmt_t fmt);

/* Per-cycle constant-time annotation (D6).  Setting true causes
 * the next emit_module to lower branches over secret values to
 * CMOV-based selection.  Reset by iii_cg_rm2_module_finish. */
void iii_cg_rm2_set_const_time(iii_cg_rm2_state_t *cg, bool on);

/* Emit the entire module to `out`.  Updates the streaming codegen
 * witness (D8) over every emitted byte.  Returns III_CG_RM2_OK or
 * one of the error codes. */
int  iii_cg_rm2_emit_module(iii_cg_rm2_state_t *cg, FILE *out);

/* Seal the codegen state (D14).  After this call any further emit
 * returns III_CG_RM2_E_SEALED.  Idempotent. */
int  iii_cg_rm2_module_finish(iii_cg_rm2_state_t *cg);

/* Retrieve the canonical sanctum mhash root (D8).  After
 * emit_module, copies 32 bytes of SHA-256 over the emitted byte
 * stream into out_mhash.  Returns III_CG_RM2_OK or III_CG_RM2_E_NULL_ARG. */
int  iii_cg_rm2_section_mhash(const iii_cg_rm2_state_t *cg,
                               uint8_t out_mhash[32]);

int          iii_cg_rm2_last_error (const iii_cg_rm2_state_t *cg);
const char  *iii_cg_rm2_error_name (int code);

#ifdef __cplusplus
}
#endif

#endif /* III_BOOT_CG_RM2_H */
