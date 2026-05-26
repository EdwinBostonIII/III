/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\proof.h
 *
 * III Stage-0 Proof Certificate Emitter — public interface.
 *
 * For every top-level declaration that participates in the witness
 * chain (cycle, fn, type, const, extern, schema, sealed_call_method,
 * mobius_candidate, ADR, conformance_claim, test_case, rationale),
 * the proof pass emits a 32-byte SHA-256 certificate over the
 * canonical byte form of the declaration.  Certificates are stored
 * as AST annotations under phase "proof/cert_mhash" so codegen and
 * link can reference them without re-deriving.
 *
 * Defense-in-depth: as a side effect of the certificate emission,
 * the proof pass re-runs the hexad admission check on every cycle
 * decl's resolved hexad (per sema_cycle_hexad).  This is the third
 * independent layer of bricking-class rejection (per III-HEXAD §4.5):
 *   1. Sema rejects @hexad outside reach6.
 *   2. Sema rejects irpd.<pfs-name>.
 *   3. Proof recomputes admission and refuses to certify if the
 *      cycle's hexad is unrep — even if (somehow) sema admitted it.
 *
 * Stage-0's proof pass is structural-only — the full CIC-fragment
 * proof kernel of III-TYPES.md §11 is Stage-1+ work
 * (TYPES/src/cic.c is the runtime mirror).  Stage-0 here:
 *
 *   - emits per-decl certificates
 *   - re-validates hexad admission on cycle decls
 *   - re-validates ring-set well-formedness
 *   - confirms the AST has no III_AST_ERROR_NODE descendants of any
 *     module decl (defense in depth vs sema's recovery)
 *
 * ─── PUBLIC API ─────────────────────────────────────────────────────
 *
 *   main.c only #includes proof.h; it does NOT call any iii_proof_*
 *   function directly.  The proof pass is invoked from sid_run() (in
 *   sid.c) right after each cycle's inverse plan is emitted, so its
 *   work happens in the same phase as sid in the pipeline.
 *
 *   Public functions are exposed for explicit invocation by tools and
 *   for the future Stage-1 self-host that wants to call proof
 *   independently of sid.
 *
 * Strict NIH (ADR-021): only stdlib + ast.h + sema.h + hexad_check.h.
 * No external CIC kernel.  Hand-rolled SHA-256 inside this TU.
 */

#ifndef III_BOOT_PROOF_H
#define III_BOOT_PROOF_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#include "ast.h"
#include "sema.h"

#ifdef __cplusplus
extern "C" {
#endif

/* ─── Stable error codes (ABI; never reused) ─────────────────────── */

#define III_PROOF_OK                     0
#define III_PROOF_E_HEXAD_UNREP          1   /* PROOF-HEXAD-001 */
#define III_PROOF_E_RING_MALFORMED       2   /* PROOF-RING-001 */
#define III_PROOF_E_ERROR_NODE           3   /* PROOF-ERROR-001 */
#define III_PROOF_E_OOM                  99

/* ─── Error record ───────────────────────────────────────────────── */

typedef struct {
    int          code;
    uint32_t     decl_node;
    const char  *message;
} iii_proof_error_t;

/* ─── State ──────────────────────────────────────────────────────── */

struct iii_proof_state;
typedef struct iii_proof_state iii_proof_state_t;

/* ─── Lifecycle ──────────────────────────────────────────────────── */

iii_proof_state_t *iii_proof_create(iii_ast_t *ast, iii_sema_state_t *sema);
void               iii_proof_destroy(iii_proof_state_t *p);

/* Run the proof pass over every top-level decl.  Returns 1 on success
 * (zero errors), 0 otherwise.  Idempotent: a re-run produces the same
 * certificates byte-identically. */
int                iii_proof_run(iii_proof_state_t *p);

/* ─── Error queue access ─────────────────────────────────────────── */

uint32_t           iii_proof_error_count(const iii_proof_state_t *p);
void               iii_proof_error_at(const iii_proof_state_t *p,
                                          uint32_t i,
                                          iii_proof_error_t *out);
const char        *iii_proof_error_name(int code);

/* ─── Certificate access ─────────────────────────────────────────── */

/* Read the 32-byte certificate for a decl.  Returns true on hit; the
 * AST annotation arena owns the bytes. */
bool               iii_proof_cert_for_decl(const iii_proof_state_t *p,
                                              uint32_t decl_node,
                                              uint8_t out[32]);

/* Aggregate proof root: SHA-256 over the concatenation of every
 * emitted certificate, in declaration order.  Suitable for inclusion
 * in the build witness JSON. */
void               iii_proof_aggregate_root(const iii_proof_state_t *p,
                                              uint8_t out[32]);

#ifdef __cplusplus
}
#endif

#endif /* III_BOOT_PROOF_H */
