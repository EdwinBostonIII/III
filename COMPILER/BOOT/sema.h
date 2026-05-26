/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\sema.h
 *
 * III Stage-0 Semantic Analyser — public interface.
 *
 * Purpose: walk the BOOT AST after parse, perform substantive
 * semantic analysis, and produce a queue of typed errors that main.c
 * surfaces via iii_diag_sema().  Sema is the canonical interpreter of
 * @ring(...), @hexad(...) / @safety(...), @tier(...), @epoch(...) and
 * the IRPD discipline (per parse.h §M1: the parser DELIBERATELY
 * leaves modifier semantics unresolved).
 *
 * ─── PIPELINE POSITION ──────────────────────────────────────────────
 *
 *   parse → sema → sid → walloc → cg → link → emit
 *
 * Sema runs after parse and BEFORE sid; sid relies on sema's
 * resolved binder_id side-table and on the synthesised RING_SET
 * nodes that sema emits (so main.c::iii_ring_autodetect can read
 * a normalised ring annotation per cycle).
 *
 * ─── CHECKS PERFORMED (Stage-0 substantive set) ─────────────────────
 *
 *   D-1.   Top-level declaration uniqueness (cycle/fn/type/const/extern
 *          with the same name in the same module → TYPE-DECL-001).
 *   D-2.   Identifier resolution: every EXPR_IDENT in the body of a
 *          cycle/fn must resolve to a parameter, a local let-binding,
 *          a top-level decl, or a known IRPD method.  Unresolved →
 *          TYPE-IDENT-001.
 *   D-3.   Cycle hexad presence: every CYCLE_DECL must carry an
 *          @hexad / @safety modifier whose six trits are admissible
 *          per xii_asym_reach6.  Missing → TYPE-HEXAD-001; unrep →
 *          TYPE-HEXAD-002.
 *   D-4.   Cycle ring set: every CYCLE_DECL must carry an @ring
 *          modifier whose ring set is well-formed (non-empty,
 *          subset of {R-2, R-1, R0, R3}).  Missing → TYPE-RING-002;
 *          ill-formed → TYPE-RING-001.  Sema also synthesises a
 *          III_AST_RING_SET node that main.c::iii_ring_autodetect
 *          consumes downstream.
 *   D-5.   IRPD-only privileged writes: any METAL block that contains
 *          a raw privileged opcode token (wrmsr / mov-cr / wrpkru /
 *          invlpga / invpcid / vmrun / vmload / vmsave / clgi / stgi /
 *          rdmsr-write-pair / wrmsrns / wrmsrlist) outside an
 *          irpd.<method> dispatch is PARSE-IRPD-001.
 *   D-6.   Metal block ring mask must be a subset of the cycle's
 *          ring set (per parser-recorded metal.ring_mask vs cycle's
 *          @ring mask).  Mismatch → TYPE-METAL-001.
 *   D-7.   Extern ABI must be one of {C-MSVC-X64, C-SYSV-X64,
 *          VMRUN-TRAMPOLINE, MAGIC-MSR, IOCTL}.  Out-of-range or
 *          missing → TYPE-EXTERN-001.
 *   D-8.   Sealed-call seal_id collision (within a module two methods
 *          may not share the same seal_id) → TYPE-SEAL-001.
 *   D-9.   ERROR_NODE in the AST → TYPE-ERROR-001 (parser emitted a
 *          recoverable typed error; sema surfaces it as a sema error
 *          so the pipeline does not fall through to codegen).
 *   D-10.  Invocation of a Compromise<HIGH> bricking method by name
 *          (capsule_update / microcode_load / bootorder_set /
 *          real_nvram_write / me_psp_mailbox / smram_write) →
 *          TYPE-PFS-001 (defense in depth — the hexad rule already
 *          prevents this; sema rejects on name match too).
 *
 * ─── PUBLIC API SHAPE (constraints from main.c) ─────────────────────
 *
 *   main.c calls:
 *     iii_sema_state_t *iii_sema_create(iii_ast_t *ast);
 *     int               iii_sema_run(iii_sema_state_t *s);
 *     void              iii_sema_destroy(iii_sema_state_t *s);
 *     uint32_t          iii_sema_error_count(const iii_sema_state_t *s);
 *     void              iii_sema_error_at(const iii_sema_state_t *s,
 *                                          uint32_t i,
 *                                          iii_sema_error_t *out);
 *     const char       *iii_sema_error_name(int code);
 *
 *   The error tuple shape is enforced by main.c::iii_diag_sema:
 *     se.code      : int
 *     se.line      : uint32_t  (1-based; 0 = source-position unknown)
 *     se.col       : uint32_t  (1-based; 0 = source-position unknown)
 *     se.hexad     : uint16_t  (composed/violating hexad if relevant; 0 otherwise)
 *     se.message   : const char *  (static .rdata or arena-resident)
 *
 * Strict NIH (ADR-021): only stdlib + III BOOT headers (ast, lex,
 * hexad_check).  No external type kernel, no SMT solver, no constraint
 * library.  Bidirectional inference, CIC kernel, dependent types are
 * Stage-1+ work; Stage-0 sema is structural-checks-only.
 */

#ifndef III_BOOT_SEMA_H
#define III_BOOT_SEMA_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#include "ast.h"

#ifdef __cplusplus
extern "C" {
#endif

/* ─── Stable error codes (ABI; never reused) ─────────────────────── */

#define III_SEMA_OK                  0
#define III_SEMA_E_DECL_DUPLICATE    1   /* TYPE-DECL-001 */
#define III_SEMA_E_IDENT_UNRESOLVED  2   /* TYPE-IDENT-001 */
#define III_SEMA_E_HEXAD_MISSING     3   /* TYPE-HEXAD-001 */
#define III_SEMA_E_HEXAD_UNREP       4   /* TYPE-HEXAD-002 */
#define III_SEMA_E_RING_MALFORMED    5   /* TYPE-RING-001 */
#define III_SEMA_E_RING_MISSING      6   /* TYPE-RING-002 */
#define III_SEMA_E_IRPD_RAW          7   /* PARSE-IRPD-001 */
#define III_SEMA_E_METAL_RING        8   /* TYPE-METAL-001 */
#define III_SEMA_E_EXTERN_ABI        9   /* TYPE-EXTERN-001 */
#define III_SEMA_E_SEAL_COLLISION   10   /* TYPE-SEAL-001 */
#define III_SEMA_E_ERROR_NODE       11   /* TYPE-ERROR-001 */
#define III_SEMA_E_PFS_BRICK        12   /* TYPE-PFS-001 */
#define III_SEMA_E_OOM              99

/* ─── Error record (shape matches main.c's iii_diag_sema printf) ─── */

typedef struct {
    int          code;
    uint32_t     line;
    uint32_t     col;
    uint16_t     hexad;     /* composed or violating hexad if relevant */
    uint32_t     ast_node;  /* AST node where error was detected */
    const char  *message;   /* static .rdata or sema-arena-resident */
} iii_sema_error_t;

/* ─── State ──────────────────────────────────────────────────────── */

struct iii_sema_state;
typedef struct iii_sema_state iii_sema_state_t;

/* ─── Lifecycle ──────────────────────────────────────────────────── */

iii_sema_state_t *iii_sema_create(iii_ast_t *ast);
void              iii_sema_destroy(iii_sema_state_t *s);

/* Run the analysis.  Returns 1 on success (zero errors), 0 on failure
 * (error_count > 0 OR an internal panic such as OOM).  On either
 * outcome the state retains all queued errors for inspection. */
int iii_sema_run(iii_sema_state_t *s);

/* ─── Error queue access ─────────────────────────────────────────── */

uint32_t          iii_sema_error_count(const iii_sema_state_t *s);
void              iii_sema_error_at(const iii_sema_state_t *s,
                                     uint32_t i,
                                     iii_sema_error_t *out);
const char       *iii_sema_error_name(int code);

/* ─── Side-table queries (for sid / cg consumption) ──────────────── */

/* Return the AST that sema is operating on. */
iii_ast_t        *iii_sema_ast(iii_sema_state_t *s);

/* Return the resolved cycle/fn/type/const decl node for a top-level
 * name, or 0 if none.  `name` is a NUL-terminated ASCII string. */
uint32_t          iii_sema_lookup_decl(const iii_sema_state_t *s,
                                        const char *name);

/* Return the per-cycle composed hexad sema computed (the @hexad value
 * as packed u16), or 0xFFFFu if the cycle did not pass D-3. */
uint16_t          iii_sema_cycle_hexad(const iii_sema_state_t *s,
                                        uint32_t cycle_decl_node);

/* Return the per-cycle ring set (bitmask of III_RING_R3 / III_RING_R0
 * / III_RING_RM1 / III_RING_RM2), or 0 if the cycle did not pass D-4. */
unsigned          iii_sema_cycle_ring_mask(const iii_sema_state_t *s,
                                            uint32_t cycle_decl_node);

/* F8.5 — struct layout queries (codegen consults these to lower
 * EXPR_FIELD and STMT_LET on struct-typed locals).
 *
 *   iii_sema_struct_size_slots: returns number of u64 slots the
 *     struct occupies (= field count under Stage-1 uniform-width
 *     layout).  Returns 0 for unknown struct_decl_node.
 *   iii_sema_struct_field_slot: returns the 0-based slot offset
 *     of `field_name` within the struct, or -1 if not found.
 *   iii_sema_struct_decl_for_name: lookup struct decl node id by
 *     source-name string ("Foo"); returns 0 if not found.  */
uint32_t          iii_sema_struct_size_slots(const iii_sema_state_t *s,
                                                  uint32_t struct_decl_node);
int32_t           iii_sema_struct_field_slot(const iii_sema_state_t *s,
                                                  uint32_t struct_decl_node,
                                                  const char *field_name);
uint32_t          iii_sema_struct_decl_for_name(const iii_sema_state_t *s,
                                                    const char *name);

/* ─── Phase 2 modifier annotation queries (lattice plan Steps 0002-0015 + 0028) ───
 *
 * Each query returns 0 (= unset) when the decl_node has no anno entry
 * or the modifier was not parsed onto that decl.  These are pure
 * read-only side-table accesses — they do not modify sema state.
 * Codegen / ripple / proof / emit consume these annotations to lower
 * `@dynamic` to a runtime stub (Step 0022), record `@crystal` decls
 * into the layered-seal output (Step 0024), enforce `@constant_time`
 * post-Step-0023, etc.
 *
 * For arg-bearing modifiers (`@dynamic`, `@sealed`, `@bounded`, `@k`,
 * `@provenance`, `@dynamic_impact`, `@arena_reset_safe`), the args are
 * exposed via dedicated getters returning 0/0xFF/NULL on unset. */

uint8_t           iii_sema_anno_has_crystal               (const iii_sema_state_t *s, uint32_t decl_node);
uint8_t           iii_sema_anno_has_dynamic               (const iii_sema_state_t *s, uint32_t decl_node);
uint8_t           iii_sema_anno_dynamic_ripple_mode       (const iii_sema_state_t *s, uint32_t decl_node);
uint8_t           iii_sema_anno_has_sealed                (const iii_sema_state_t *s, uint32_t decl_node);
uint32_t          iii_sema_anno_sealed_slot               (const iii_sema_state_t *s, uint32_t decl_node);
uint8_t           iii_sema_anno_sealed_provenance         (const iii_sema_state_t *s, uint32_t decl_node);
uint8_t           iii_sema_anno_has_linear                (const iii_sema_state_t *s, uint32_t decl_node);
uint8_t           iii_sema_anno_has_bounded               (const iii_sema_state_t *s, uint32_t decl_node);
uint64_t          iii_sema_anno_bounded_min               (const iii_sema_state_t *s, uint32_t decl_node);
uint64_t          iii_sema_anno_bounded_max               (const iii_sema_state_t *s, uint32_t decl_node);
uint8_t           iii_sema_anno_has_variant               (const iii_sema_state_t *s, uint32_t decl_node);
uint8_t           iii_sema_anno_has_k                     (const iii_sema_state_t *s, uint32_t decl_node);
uint64_t          iii_sema_anno_k_value_fixed             (const iii_sema_state_t *s, uint32_t decl_node);
uint8_t           iii_sema_anno_has_provenance            (const iii_sema_state_t *s, uint32_t decl_node);
uint8_t           iii_sema_anno_provenance_mode           (const iii_sema_state_t *s, uint32_t decl_node);
uint8_t           iii_sema_anno_has_constant_time         (const iii_sema_state_t *s, uint32_t decl_node);
uint8_t           iii_sema_anno_has_side_channel_resistant(const iii_sema_state_t *s, uint32_t decl_node);
uint8_t           iii_sema_anno_has_dynamic_impact        (const iii_sema_state_t *s, uint32_t decl_node);
int32_t           iii_sema_anno_dynamic_impact_perf_bp    (const iii_sema_state_t *s, uint32_t decl_node);
int32_t           iii_sema_anno_dynamic_impact_ux_bp      (const iii_sema_state_t *s, uint32_t decl_node);
uint8_t           iii_sema_anno_has_provenance_linked_error(const iii_sema_state_t *s, uint32_t decl_node);
uint8_t           iii_sema_anno_has_arena_reset_safe      (const iii_sema_state_t *s, uint32_t decl_node);
const char       *iii_sema_anno_arena_reset_safe_clear_fn (const iii_sema_state_t *s, uint32_t decl_node);
uint8_t           iii_sema_anno_has_crystal_self_attest   (const iii_sema_state_t *s, uint32_t decl_node);
uint8_t           iii_sema_anno_has_strict_length         (const iii_sema_state_t *s, uint32_t decl_node);

/* Constants returned by iii_sema_anno_dynamic_ripple_mode. */
#define III_SEMA_DYNAMIC_RIPPLE_UNSET   0u
#define III_SEMA_DYNAMIC_RIPPLE_OFF     1u
#define III_SEMA_DYNAMIC_RIPPLE_MANUAL  2u
#define III_SEMA_DYNAMIC_RIPPLE_AUTO    3u

/* Constants returned by iii_sema_anno_provenance_mode. */
#define III_SEMA_PROV_MODE_UNSET     0u
#define III_SEMA_PROV_MODE_DATAFLOW  1u
#define III_SEMA_PROV_MODE_ERROR     2u
#define III_SEMA_PROV_MODE_BOTH      3u

#ifdef __cplusplus
}
#endif

#endif /* III_BOOT_SEMA_H */
