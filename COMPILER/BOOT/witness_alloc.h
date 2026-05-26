/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\witness_alloc.h
 *
 * III Stage-0 Witness Identifier Allocator — public interface.
 *
 * Per CHARIOT/INCLUDE/xii_witness.h the on-wire XiiWitness layout
 * (§ "BYTE LAYOUT") includes:
 *
 *     bytes 64..67   step_kind             (XII_STEP_KIND_*)
 *     bytes 72..79   cycle_seq             (monotonic seqlock value)
 *     bytes 94..95   plan_section_anchor   (16-bit forensic)
 *
 * The 32-bit step_kind is category-banded; the CYCLE band is
 * 0x0000_0000..0x0000_FFFF and aliases the 16-bit cycle_kind_t enum
 * defined in CHARIOT/CONSTITUTIONAL/include/cycle-types.h.
 *
 * This pass assigns deterministic identifiers to III-declared cycles
 * so that downstream codegen can emit cycle_descriptor_t records and
 * witness emission sites with stable IDs that round-trip across
 * rebuilds and across translation units.
 *
 * ALLOCATION POLICY
 * -----------------
 *   - cycle_kind:  starts at III_WALLOC_CYCLE_KIND_BASE = 0x0200
 *                  (above CHARIOT's existing allocations per
 *                  CONSTITUTIONAL/include/cycle-types.h, which presently
 *                  reach 0x01CF MNEME and 0x01D3 IOMMU); allocated in
 *                  module-decl-list source order, monotonically.
 *   - step_kind:   composes (CYCLE_CATEGORY << 16) | cycle_kind
 *                  for cycle decls; the CYCLE category is 0x0000.
 *   - plan_anchor: starts at III_WALLOC_PLAN_ANCHOR_BASE = 0x0C00
 *                  (above MNEME 0x0B07).  Per-module-unique; multiple
 *                  cycles in the same module share that module's
 *                  anchor.  Derived deterministically from the module
 *                  name string (see iii_walloc_run).
 *
 * DETERMINISM
 * -----------
 *   The allocator is a pure function of the AST it walks.  No time,
 *   no PID, no pointer identities ever influence persistent IDs.
 *   `iii_walloc_anchor_mhash` is a SHA-256 over the assignment list
 *   in allocation order — re-running this pass on the same AST yields
 *   bit-identical IDs and bit-identical mhash.
 *
 * CROSS-TU COMPOSITION
 * --------------------
 *   A single iii_walloc_state_t may be reused across multiple
 *   `iii_walloc_run` invocations to allocate IDs for several modules
 *   linked together.  The cycle_kind counter is monotonic across
 *   modules; collisions are therefore impossible by construction.
 *   Reserved-range collisions are caught regardless (see
 *   iii_walloc_reserved_ranges).
 *
 * STRICT NIH: only stdlib + III BOOT headers.  Runtime (rt/) is
 * deliberately not depended on so this pass is bootstrap-clean.
 */

#ifndef III_BOOT_WITNESS_ALLOC_H
#define III_BOOT_WITNESS_ALLOC_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#include "ast.h"

#ifdef __cplusplus
extern "C" {
#endif

/* ─── Allocation bases ─────────────────────────────────────────────── */

#define III_WALLOC_CYCLE_KIND_BASE       0x0200u
#define III_WALLOC_PLAN_ANCHOR_BASE      0x0C00u
#define III_WALLOC_STEP_CATEGORY_CYCLE   0x0000u

/* Hard cap: a 16-bit cycle_kind has 0x10000 - BASE allocatable values. */
#define III_WALLOC_MAX_CYCLES            (0x10000u - III_WALLOC_CYCLE_KIND_BASE)

/* ─── Stable error codes ───────────────────────────────────────────── */

#define III_WALLOC_OK                     0
#define III_WALLOC_E_NULL_ARG            -1
#define III_WALLOC_E_INVALID_AST         -2
#define III_WALLOC_E_RESERVED_RANGE      -3
#define III_WALLOC_E_EXHAUSTED           -4
#define III_WALLOC_E_DUPLICATE           -5
#define III_WALLOC_E_OOM                 -6
#define III_WALLOC_E_SEALED              -7
#define III_WALLOC_E_MISMATCH            -8

/* ─── Records ──────────────────────────────────────────────────────── */

typedef struct {
    uint32_t  decl_node;        /* AST node index of the cycle decl */
    uint32_t  name_off;         /* offset into AST source_buf */
    uint32_t  name_len;         /* length of name in source_buf */
    uint16_t  cycle_kind;       /* mirrored to cycle_descriptor_t.kind */
    uint16_t  plan_anchor;      /* per-module witness anchor */
    uint32_t  step_kind;        /* (category<<16) | cycle_kind */
} iii_walloc_record_t;

/* Reserved-range table entry: an inclusive [lo, hi] that the
 * allocator MUST refuse to issue.  Cited from
 * CHARIOT/CONSTITUTIONAL/include/cycle-types.h. */
typedef struct {
    uint16_t    lo;
    uint16_t    hi;
    const char *what;            /* documentary tag, e.g. "PAGE", "MSR" */
} iii_walloc_reserved_range_t;

/* Read-only view of the static reserved-range table.  Stable for the
 * lifetime of the program. */
const iii_walloc_reserved_range_t *iii_walloc_reserved_ranges(uint32_t *out_count);

/* Per-allocation audit sink.  Off by default.  Called synchronously
 * during iii_walloc_run for each cycle decl that receives an ID. */
typedef void (*iii_walloc_audit_fn)(void                *user,
                                    uint16_t             cycle_kind,
                                    uint16_t             plan_anchor,
                                    uint32_t             name_off,
                                    uint32_t             name_len,
                                    uint32_t             source_span_start,
                                    uint32_t             source_span_end);

/* ─── Lifecycle ────────────────────────────────────────────────────── */

struct iii_walloc_state;
typedef struct iii_walloc_state iii_walloc_state_t;

iii_walloc_state_t *iii_walloc_create(void);
void                iii_walloc_destroy(iii_walloc_state_t *st);

void iii_walloc_set_audit(iii_walloc_state_t *st,
                          iii_walloc_audit_fn fn, void *user);

/* ─── Allocation ───────────────────────────────────────────────────── */

/* Walk the module decl list and assign IDs to every CYCLE_DECL,
 * MOBIUS_CANDIDATE_DECL and SEALED_CALL_METHOD_DECL in declaration
 * order.  May be called multiple times with different ASTs to
 * compose a cross-TU allocation; the cycle_kind counter is preserved
 * across calls.  Returns III_WALLOC_OK on success or one of the
 * negative III_WALLOC_E_* codes. */
int iii_walloc_run(iii_walloc_state_t *st, iii_ast_t *ast);

/* After seal, further iii_walloc_run calls return III_WALLOC_E_SEALED.
 * Read-back APIs remain available; this is the codegen handover. */
int  iii_walloc_seal(iii_walloc_state_t *st);
bool iii_walloc_is_sealed(const iii_walloc_state_t *st);

/* ─── Read-back ────────────────────────────────────────────────────── */

const iii_walloc_record_t *iii_walloc_lookup(const iii_walloc_state_t *st,
                                             uint32_t decl_node);

uint32_t iii_walloc_record_count(const iii_walloc_state_t *st);
const iii_walloc_record_t *iii_walloc_record_at(const iii_walloc_state_t *st,
                                                uint32_t i);

/* ─── Witness emission ─────────────────────────────────────────────── */

/* Emit a deterministic, line-oriented manifest sorted ascending by
 * cycle_kind.  Format (one record per line):
 *
 *     "<hex4-cycle_kind> <hex8-step_kind> <hex4-plan_anchor> <name>\n"
 *
 * If buf is NULL or cap is too small, returns the number of bytes
 * that *would* be written excluding the trailing NUL.  On success
 * returns the same count and writes a NUL-terminator (when cap > 0).
 * Requires the same AST that was passed to iii_walloc_run for name
 * resolution. */
size_t iii_walloc_emit_manifest(const iii_walloc_state_t *st,
                                const iii_ast_t          *ast,
                                char                     *buf,
                                size_t                    cap);

/* Streaming SHA-256 over the (cycle_kind, name_off, name_len, name_bytes)
 * tuples in allocation order.  Witness for "the IDs assigned by THIS
 * compilation".  out must point to 32 writable bytes. */
void iii_walloc_anchor_mhash(const iii_walloc_state_t *st,
                             const iii_ast_t          *ast,
                             uint8_t                   out[32]);

/* Re-derive plan_anchor for the given AST's root module from its name
 * and assert it matches the recorded module_plan_anchor.  Also
 * re-walks the decl list and asserts that each lookup returns the
 * same (cycle_kind, plan_anchor, step_kind) we'd assign now.  Used
 * as a golden-bytes invariant gate.  Returns III_WALLOC_OK or
 * III_WALLOC_E_MISMATCH. */
int iii_walloc_verify(const iii_walloc_state_t *st, const iii_ast_t *ast);

#ifdef __cplusplus
}
#endif

#endif /* III_BOOT_WITNESS_ALLOC_H */
