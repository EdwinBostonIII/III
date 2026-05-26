/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\cg_r0.h
 *
 * III Stage-0 Ring 0 (Windows kernel-mode .sys) Codegen — public interface.
 *
 * Same MS x64 ABI as cg_r3 (Windows kernel mode and user mode share the
 * same call discipline) but with these Ring-0-specific behaviours:
 *
 *   - DriverEntry contract (D1).  An III function or cycle named
 *     `driver_entry` (or carrying @entry) is emitted with a global
 *     `DriverEntry` alias and the canonical NTSTATUS signature
 *       NTSTATUS DriverEntry(PDRIVER_OBJECT, PUNICODE_STRING)
 *     Codegen REJECTS the module with III_CG_R0_E_SIG_MISMATCH if the
 *     entry symbol does not have exactly two pointer-sized parameters.
 *     Cite: WDK §"Writing a DriverEntry routine".
 *
 *   - IRP dispatch table (D2).  Cycles annotated with
 *     `@irp_handler(IRP_MJ_<x>)` are wired into a static
 *     `_iii_IrpDispatchTable[IRP_MJ_MAXIMUM_FUNCTION + 1]` emitted in
 *     the `.rdata` section, then installed by DriverEntry through
 *     `DriverObject->MajorFunction[i] = _iii_IrpDispatchTable[i]`.
 *     The contract: only IRP_MJ_* values 0..0x1B (IRP_MJ_MAXIMUM_
 *     FUNCTION) are wired; unknown majors fall through to a default
 *     `_iii_IrpNotImplemented` returning STATUS_NOT_SUPPORTED.
 *     Cite: WDK §"Writing Dispatch Routines".
 *
 *   - IRQL discipline (D3).  Each emitted helper carries an
 *     `IRQL_REQUIRES_MAX(...)` comment header derived from the
 *     `@irql_max(N)` modifier (default DISPATCH_LEVEL, i.e. 2).
 *     Codegen consults a static table of high-IRQL-only kernel APIs
 *     (e.g. `MmAllocateNonCachedMemory`, `KeStallExecutionProcessor`)
 *     and REJECTS any CALL from a cycle whose declared max IRQL is
 *     lower than the API's required IRQL (III_CG_R0_E_IRQL_VIOLATION).
 *     Cite: WDK §"Managing Hardware Priorities".
 *
 *   - .sys section emission (D4).  PE/COFF Spec §6 ("Section Table"):
 *       INIT  : DriverEntry body — discardable post-init.
 *       PAGE  : functions carrying `@paged` — paged code.
 *       .text : everything else — non-paged.
 *     Each function is bracketed with `.section <NAME>` directives.
 *
 *   - Ring-wall (D5).  Codegen REFUSES to emit a CALL to a symbol
 *     declared `@ring(R3)` or `@ring(Rm1)` from this Ring-0 unit.
 *     Returns III_CG_R0_E_RING_WALL.
 *
 *   - SAL passthrough (D6).  `@sal("_In_")` modifiers attached to a
 *     parameter's type are emitted as "(* _In_ *)"-style C comments
 *     next to that parameter slot, allowing post-build SDV/CodeQL to consume
 *     the annotations from debug info / source listings.
 *
 *   - NTSTATUS return discipline (D7).  Every emitted exit path
 *     returns an explicit NTSTATUS; codegen falls back to
 *     STATUS_SUCCESS (0x00000000) at fall-through and asserts no
 *     return-less control-flow leaves a function.  Mismatched returns
 *     produce III_CG_R0_E_RETURN_DISCIPLINE.
 *
 *   - SEH unwind (D8).  Every function emits `.seh_proc` / `.seh_endproc`
 *     brackets so the linker (link.exe /DRIVER) builds a valid .pdata
 *     section.  Cite: MS x64 ABI §"Exception Handling".
 *
 *   - Witness emission (D9).  Each cycle entry/exit emits a call to
 *     `iii_witness_emit_kernel(cycle_id, IIIW_ENTER|IIIW_EXIT)`.
 *     The contract on this routine, owned by the substrate:
 *       * non-blocking (no KeWaitForSingleObject / no spinlock),
 *       * IRQL-safe up to and including HIGH_LEVEL,
 *       * no allocator entry,
 *       * preserves all volatile registers (caller-saved by ABI but
 *         the stub spills them defensively per ADR-024).
 *
 *   - Codegen witness (D10).  Streaming SHA-256 over the emitted asm
 *     stream is exposed via iii_cg_r0_get_witness(); the .sys signing
 *     prep step uses this as the build-input hash.
 *
 *   - Reproducibility flags (D12).  `.no_dead_strip` is emitted only
 *     for the IRP dispatch table and DriverEntry; `.weak_definition`
 *     is reserved for `_iii_IrpNotImplemented` so a driver may
 *     override it.  All other symbols use plain `.global`.
 *
 *   - Stack-budget tracker (D13).  Kernel stack on x64 is 12 KB per
 *     thread.  Each emitted function carries an inline `.if/.warning`
 *     check on its frame size; codegen warns at >2048 bytes.
 *
 *   - Side-channel wrapper (D14).  Cycles annotated `@secmem` are
 *     bracketed with `sfence; mfence` and stores into the wrapped
 *     range are emitted via `movntiq` to bypass the cache (avoid
 *     sibling-LP residue on hyperthreaded cores).
 *
 *   - Sealed-call methods compile as the body of `XII_SANCTUM_SEAL_*`
 *     dispatch entries; R3 omits these symbols entirely (see cg_r3.c)
 *     since R3 sema rejects sealed-call invocations.
 *
 * Public API is preserved modulo nomenclature (LOGOS→III, lgs→iii).
 * Header changes are additive only.
 */

#ifndef III_BOOT_CG_R0_H
#define III_BOOT_CG_R0_H

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

#define III_CG_R0_OK                  0
#define III_CG_R0_E_NULL_ARG          1
#define III_CG_R0_E_IO                2
#define III_CG_R0_E_UNSUPPORTED       3
#define III_CG_R0_E_INTERNAL          99

/* New error codes introduced by the deepenings (additive). */
#define III_CG_R0_E_SIG_MISMATCH      10  /* D1 */
#define III_CG_R0_E_IRP_DUP           11  /* D2 */
#define III_CG_R0_E_IRQL_VIOLATION    12  /* D3 */
#define III_CG_R0_E_RING_WALL         13  /* D5 */
#define III_CG_R0_E_RETURN_DISCIPLINE 14  /* D7 */
#define III_CG_R0_E_STACK_OVER        15  /* D13 (warning escalation only) */

struct iii_cg_r0_state;
typedef struct iii_cg_r0_state iii_cg_r0_state_t;

iii_cg_r0_state_t *iii_cg_r0_create(iii_ast_t *ast,
                                    iii_sema_state_t *sema,
                                    iii_sid_state_t *sid,
                                    iii_walloc_state_t *walloc);
void               iii_cg_r0_destroy(iii_cg_r0_state_t *cg);

int  iii_cg_r0_emit_module(iii_cg_r0_state_t *cg, FILE *out);

/* D10: codegen witness — SHA-256 over the emitted asm stream.
 * Returns III_CG_R0_OK on success and writes 32 bytes to out32. */
int  iii_cg_r0_get_witness(const iii_cg_r0_state_t *cg, uint8_t out32[32]);

int  iii_cg_r0_last_error(const iii_cg_r0_state_t *cg);
const char *iii_cg_r0_error_name(int code);

#ifdef __cplusplus
}
#endif

#endif /* III_BOOT_CG_R0_H */
