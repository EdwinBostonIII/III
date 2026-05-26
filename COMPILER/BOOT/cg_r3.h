/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\cg_r3.h
 *
 * III Stage-0 Ring 3 Codegen — public interface.
 *
 * Emits gas-syntax x86_64 assembly for the Microsoft x64 calling
 * convention (Windows PE).  The Stage-0 codegen uses a simple
 * stack-machine strategy: every expression's value is pushed onto
 * the runtime stack; every operator pops its arguments and pushes
 * the result.  This sacrifices speed for simplicity and correctness;
 * Stage 1+ self-host can replace this with a register-allocated
 * codegen written in III itself.
 *
 * Strict NIH (ADR-021): only stdlib + III BOOT headers.  No libgccjit,
 * no LLVM, no asmjit.  Hand-rolled mnemonic emission.
 *
 * The codegen consumes the AST plus sema's resolved metadata, sid's
 * inverse plans, and walloc's witness IDs.  It does NOT include
 * cross-language type marshalling (the parser's `extern @abi` form
 * provides that for `c-msvc-x64`).
 *
 * ─── Deepenings adopted (and their contracts) ─────────────────────
 *
 * D1  ABI-conformance assertion sites (MS x64 ABI §6.4):
 *     codegen tracks an 8-byte stack-slot counter `stack_depth` and
 *     asserts `(stack_depth + 1) % 2 == 0` immediately before every
 *     emitted CALL (so that rsp ≡ 0 (mod 16) at the call boundary;
 *     pushq return addr makes rsp ≡ 8 (mod 16) inside the callee,
 *     which the callee's own prologue normalises).  Failure aborts
 *     the module emit with III_CG_R3_E_ABI_ALIGN.
 *
 * D2  Shadow-space discipline (MS x64 ABI §6.4.4):
 *     32 bytes of shadow space allocated by every CALL helper.  The
 *     prologue allocates exactly `(stack_locals_bytes + 8 alignment)`
 *     bytes; shadow space is per-call, not per-frame.  Documented in
 *     the iii_cg_r3_emit_call() helper.
 *
 * D3  Volatile / non-volatile register table (MS x64 ABI §6.1):
 *     iii_cg_r3_is_volatile(reg) → bool.  The Stage-0 stack machine
 *     uses only volatile registers (rax, rcx, rdx, r8, r9), so the
 *     prologue saves no non-volatiles; future register-allocator
 *     passes consult this table and emit .seh_pushreg / .seh_savereg
 *     for every saved non-volatile they touch.
 *
 * D4  SEH unwind-info emission (Windows x64 unwind spec):
 *     every emitted function is bracketed by `.seh_proc / .seh_endproc`,
 *     with `.seh_pushreg %rbp`, `.seh_stackalloc <N>`, `.seh_setframe
 *     %rbp, 0`, and `.seh_endprologue`.  Without this, exceptions,
 *     profilers, and Windows ETW unwinders break.
 *
 * D5  Codegen witness (canonical fingerprint):
 *     a streaming SHA-256 is computed over every byte the codegen
 *     emits, in emission order.  Retrievable via
 *     iii_cg_r3_get_witness().  This is the canonical answer to
 *     "what did the codegen produce", independent of any whitespace
 *     reformatting or tooling that re-prints the .s file.
 *
 * D6  Stable opcode emit table:
 *     iii_cg_r3_emit(cg, op, operands) is a typed alternative to
 *     ad-hoc fprintf.  Backed by an internal opcode-info table
 *     (mnemonic, src/dst class, side-effects).  Co-exists with the
 *     legacy fprintf paths during the Stage-0 transition; both feed
 *     the witness sponge.
 *
 * D7  Forward-jump label allocation policy:
 *     labels are `.L<class>_<n>` where <n> is drawn from a strictly
 *     monotonically-increasing per-function counter.  Duplicate
 *     emission of the same defining label within a function is
 *     detected and rejected (III_CG_R3_E_DUP_LABEL).
 *
 * D8  Per-cycle witness markers:
 *     every III cycle (not plain fn) emits a deterministic witness
 *     marker `# III_CYCLE_WITNESS{ENTER,EXIT} <name>` after the
 *     prologue and before the epilogue.  These markers sit after
 *     the stack frame is established, so they cannot be elided by
 *     any later peephole or scheduler — they are pure asm comments
 *     and the witness sponge captures them.
 *
 * D9  Ring-wall verification:
 *     every emitted function is preceded by a `.section .iii.ring3`
 *     note carrying the function's name and its declared ring (3).
 *     A linker-stage tool can check that no .iii.ring3 reference
 *     resolves into a .iii.ring0 symbol; cross-ring transitions
 *     must go through documented gateways.
 *
 * D10 Source-line directives:
 *     `.file 1 "<source>"` is emitted once at module head; per-stmt
 *     `.loc 1 <line>` directives are emitted when AST position info
 *     is available, so PE PDBs / mingw addr2line can map back.
 *
 * D11 Error recovery:
 *     a single broken expression no longer aborts the translation
 *     unit.  iii_cg_r3_emit_module() records the first error in
 *     last_error and counts subsequent errors in error_count, but
 *     keeps walking the module so the operator sees as many
 *     diagnostics as possible.  Caller checks both fields.
 *
 * D12 Spec citations: helper functions carry one-line ABI/PE
 *     citations in their leading comment.
 *
 * D13 Debug-only stack-depth tracker:
 *     when III_CG_R3_DEBUG is defined, after every statement the
 *     codegen asserts `stack_depth == 0` (every push paired with a
 *     pop) and emits `# stack_depth=N` comments into the asm.
 *     Compiled out in release builds.
 *
 * D14 Per-emit reproducibility audit:
 *     iii_cg_r3_set_expected_witness(cg, mh32) installs a 32-byte
 *     reference; iii_cg_r3_emit_module() returns
 *     III_CG_R3_E_WITNESS_MISMATCH if the streaming SHA-256 differs.
 */

#ifndef III_BOOT_CG_R3_H
#define III_BOOT_CG_R3_H

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

/* ─── Error codes (stable wire ids) ───────────────────────────────── */

#define III_CG_R3_OK                  0
#define III_CG_R3_E_NULL_ARG          1
#define III_CG_R3_E_IO                2
#define III_CG_R3_E_UNSUPPORTED       3
#define III_CG_R3_E_ABI_ALIGN         4   /* D1: pre-CALL alignment off */
#define III_CG_R3_E_DUP_LABEL         5   /* D7: same label emitted twice */
#define III_CG_R3_E_WITNESS_MISMATCH  6   /* D14: golden mhash differs */
#define III_CG_R3_E_INTERNAL          99

struct iii_cg_r3_state;
typedef struct iii_cg_r3_state iii_cg_r3_state_t;

/* ─── Lifecycle ───────────────────────────────────────────────────── */

iii_cg_r3_state_t *iii_cg_r3_create(iii_ast_t *ast,
                                    iii_sema_state_t *sema,
                                    iii_sid_state_t *sid,
                                    iii_walloc_state_t *walloc);

void iii_cg_r3_destroy(iii_cg_r3_state_t *cg);

/* Emit the entire module's assembly to `out`.
 *
 * Returns III_CG_R3_OK on success.  On a per-expression failure the
 * codegen records the first error in last_error / increments
 * error_count and continues walking the module (D11).  The function
 * returns the first non-OK code observed, but the .s output remains
 * the best-effort partial emission. */
int iii_cg_r3_emit_module(iii_cg_r3_state_t *cg, FILE *out);

/* ─── D5/D14: codegen witness ─────────────────────────────────────── */

/* Read the streaming SHA-256 of all bytes emitted so far.
 * `out32` receives 32 bytes.  Returns III_CG_R3_OK on success. */
int iii_cg_r3_get_witness(const iii_cg_r3_state_t *cg, uint8_t out32[32]);

/* Install an expected witness; iii_cg_r3_emit_module() will return
 * III_CG_R3_E_WITNESS_MISMATCH if the produced witness differs.
 * Call with NULL to disable. */
void iii_cg_r3_set_expected_witness(iii_cg_r3_state_t *cg,
                                    const uint8_t expected_mh32[32]);

/* ─── D3: register classification ─────────────────────────────────── */

/* Returns true iff `reg` is a volatile (caller-saved) register under
 * the Microsoft x64 ABI (§6.1).  `reg` is a lowercase mnemonic
 * without the % prefix, e.g. "rax", "rcx", "r10", "xmm0". */
bool iii_cg_r3_is_volatile(const char *reg);

/* ─── D6: stable opcode emit API ──────────────────────────────────── */

/* Emit `mnemonic operands` as one assembly line, feeding both the
 * output stream and the witness sponge.  `operands` may be NULL.
 * The mnemonic is validated against the internal opcode-info table;
 * unknown mnemonics return III_CG_R3_E_UNSUPPORTED. */
int iii_cg_r3_emit(iii_cg_r3_state_t *cg,
                   const char *mnemonic,
                   const char *operands);

/* ─── Error info ──────────────────────────────────────────────────── */

int  iii_cg_r3_last_error(const iii_cg_r3_state_t *cg);
int  iii_cg_r3_error_count(const iii_cg_r3_state_t *cg);
const char *iii_cg_r3_error_name(int code);

#ifdef __cplusplus
}
#endif

#endif /* III_BOOT_CG_R3_H */
