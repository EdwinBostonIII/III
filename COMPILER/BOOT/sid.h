/* C:\Users\Edwin Boston\OneDrive\Desktop\III\COMPILER\BOOT\sid.h
 *
 * III Stage-0 Side-effect Inverse Derivation (SID) — public interface.
 *
 * Per III-CYCLES.md §3 + III-EFFECTS.md §1.1, SID is the type-level
 * algorithm that walks every cycle's forward body, recognises every
 * irpd.<method>(...) invocation, classifies it into one of 17 SE
 * kinds, composes the per-call hexads, derives the inverse Reduction,
 * and stores a 32-bit replay bitmap as the cycle's inverse plan.
 *
 * The full 32-step plan (steps 1..32 of III-CYCLES.md §3.2) is the
 * Stage-1+ goal.  Stage-0 implements the structural backbone:
 *
 *   step 1  walk AST for irpd.* calls            ✓
 *   step 2  classify into 17 SE kinds            ✓
 *   step 6  compose per-call hexads              ✓
 *   step 7  emit inverse Reduction (annotation)  ✓ (as sid/inverse_plan)
 *   step 13 ceiling membership check             ✓ (defers to ceiling.h)
 *   step 22 emit cycle descriptor                ✓ (annotation)
 *   step 24 verify no raw priv outside IRPD      ✓ (cooperates with sema)
 *   step 27 emit replay-plan bitmap              ✓
 *
 * Steps 3, 4, 5, 8..12, 14..21, 23, 25..32 require richer AST
 * representation (Uncertainty types, Trinity admission terms, plan
 * anchor declarations, glyph-bound capabilities, ghost annotations,
 * SRPA accumulator) which the BOOT AST does not yet carry — they will
 * be added when the parser/AST grows the corresponding nodes.  Until
 * then, those steps are no-ops (NOT stubs that pretend success on
 * absent input — they have nothing to verify because the source can't
 * express their preconditions).
 *
 * ─── PUBLIC API SHAPE (constraints from main.c) ─────────────────────
 *
 *   main.c calls:
 *     iii_sid_state_t *iii_sid_create(iii_ast_t *ast, iii_sema_state_t *sema);
 *     int              iii_sid_run(iii_sid_state_t *s);
 *     void             iii_sid_destroy(iii_sid_state_t *s);
 *     uint32_t         iii_sid_error_count(const iii_sid_state_t *s);
 *     void             iii_sid_error_at(const iii_sid_state_t *s,
 *                                        uint32_t i,
 *                                        iii_sid_error_t *out);
 *     const char      *iii_sid_error_name(int code);
 *
 *   Error tuple shape (per main.c::iii_diag_sid):
 *     se.code             : int
 *     se.cycle_decl_node  : uint32_t  (AST node index of the offending cycle)
 *     se.message          : const char *
 *
 * Strict NIH (ADR-021): only stdlib + ast.h + sema.h + hexad_check.h
 * + ceiling.h.
 */

#ifndef III_BOOT_SID_H
#define III_BOOT_SID_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#include "ast.h"
#include "sema.h"

#ifdef __cplusplus
extern "C" {
#endif

/* ─── 17 SE kinds (mirror of EFFECTS/include/iii/effects.h) ──────── */

typedef enum {
    III_BOOT_SE_NONE              = 0,
    III_BOOT_SE_MSR_WRITE         = 1,
    III_BOOT_SE_CR_WRITE          = 2,
    III_BOOT_SE_NPT_ENTRY_WRITE   = 3,
    III_BOOT_SE_VMCB_FIELD_WRITE  = 4,
    III_BOOT_SE_IOMMU_DTE_WORD    = 5,
    III_BOOT_SE_AVIC_TBL_WRITE    = 6,
    III_BOOT_SE_MSRPM_BIT_SET     = 7,
    III_BOOT_SE_IOPM_BIT_SET      = 8,
    III_BOOT_SE_PKRU_WRITE        = 9,
    III_BOOT_SE_XCR0_WRITE        = 10,
    III_BOOT_SE_CAP_ACQUIRE       = 11,
    III_BOOT_SE_CAP_RELEASE       = 12,
    III_BOOT_SE_PAGE_ALLOC        = 13,
    III_BOOT_SE_PAGE_FREE         = 14,
    III_BOOT_SE_DPC_ARM           = 15,
    III_BOOT_SE_DPC_CANCEL        = 16,
    III_BOOT_SE_NMI_INSTALL       = 17,
    III_BOOT_SE__COUNT            = 18
} iii_sid_se_kind_t;

/* ─── Stable error codes ─────────────────────────────────────────── */

#define III_SID_OK                       0
#define III_SID_E_PARSE_IRPD             1   /* PARSE-IRPD-001 */
#define III_SID_E_UNKNOWN_METHOD         2   /* TYPE-SID-001 */
#define III_SID_E_HEXAD_COMPOSE_FAIL     3   /* TYPE-HEXAD-002 */
#define III_SID_E_CEILING_REJECT         4   /* TYPE-CEIL-001 */
#define III_SID_E_TOO_MANY_CALLS         5   /* TYPE-CYCLE-001 */
#define III_SID_E_REPLAY_BITMAP_OVERFLOW 6   /* TYPE-INV-001 */
#define III_SID_E_OOM                    99

/* ─── Error record (shape matches main.c's iii_diag_sid) ─────────── */

typedef struct {
    int          code;
    uint32_t     cycle_decl_node;
    const char  *message;
} iii_sid_error_t;

/* ─── Per-cycle output (annotation payload) ──────────────────────── */

#define III_SID_MAX_CALLS_PER_CYCLE   32u

typedef struct {
    uint32_t          decl_node;
    uint16_t          composed_hexad;       /* 0xFFFFu if cycle had no IRPD calls */
    uint32_t          replay_bitmap;        /* bit i set ⇔ inverse step i required */
    uint8_t           call_count;
    iii_sid_se_kind_t calls[III_SID_MAX_CALLS_PER_CYCLE];
    bool              irreversible;         /* cycle has @irreversible modifier or compromise body */
} iii_sid_record_t;

/* ─── State ──────────────────────────────────────────────────────── */

struct iii_sid_state;
typedef struct iii_sid_state iii_sid_state_t;

/* ─── Lifecycle ──────────────────────────────────────────────────── */

iii_sid_state_t *iii_sid_create(iii_ast_t *ast, iii_sema_state_t *sema);
void             iii_sid_destroy(iii_sid_state_t *s);

/* Run SID over every cycle decl in the module.  Returns 1 on success
 * (zero errors), 0 on failure. */
int              iii_sid_run(iii_sid_state_t *s);

/* ─── Error queue access ─────────────────────────────────────────── */

uint32_t         iii_sid_error_count(const iii_sid_state_t *s);
void             iii_sid_error_at(const iii_sid_state_t *s,
                                    uint32_t i,
                                    iii_sid_error_t *out);
const char      *iii_sid_error_name(int code);

/* ─── Per-cycle record access ────────────────────────────────────── */

uint32_t                 iii_sid_record_count(const iii_sid_state_t *s);
const iii_sid_record_t  *iii_sid_record_at(const iii_sid_state_t *s,
                                              uint32_t i);
const iii_sid_record_t  *iii_sid_record_for_decl(const iii_sid_state_t *s,
                                                    uint32_t decl_node);

/* SE-kind name (mirror of CYCLES iii_se_kind_name). */
const char              *iii_sid_se_kind_name(iii_sid_se_kind_t k);

/* SE-kind from canonical IRPD method name (mirror of
 * iii_se_kind_from_method). */
iii_sid_se_kind_t        iii_sid_se_kind_from_method(const char *name);

#ifdef __cplusplus
}
#endif

#endif /* III_BOOT_SID_H */
