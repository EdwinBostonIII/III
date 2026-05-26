/* COMPILER/BOOT/sema_xii.h — XII semantic-check extensions to sema.c.
 *
 * Per DOCS/III-XII.md S15 + S26.13.
 *
 * Adds two static checks:
 *   @fusion_budget validation against @k_max.
 *   @deployment_target legality (must be one of the 7 commodity targets or AUTO).
 *
 * NIH: libc + Win32 only.
 */

#ifndef SEMA_XII_H
#define SEMA_XII_H

#include <stdint.h>

#define SEMA_XII_OK   0
#define SEMA_XII_FAIL 1

/* New annotation kind ids (extend the sema.c annotation namespace). */
#define ANNO_FUSION_BUDGET      0x10
#define ANNO_DEPLOY_TARGET      0x11
#define ANNO_LATTICE            0x12
#define ANNO_K_MAX_EXISTING     0x05  /* must match existing sema.c */
#define ANNO_CAP_REQ_EXISTING   0x06
#define ANNO_HEXAD_EXISTING     0x07
#define ANNO_RETURNS_EXISTING   0x08

#define XII_AUTO_TARGET         0xFFFFFFFFu

/* Validate @fusion_budget annotation against @k_max + observed fusion depth.
 * Returns SEMA_XII_OK on success; SEMA_XII_FAIL on violation (emits diagnostic
 * XII-CANON-003). */
int sema_xii_check_fusion_budget(uint64_t ast, uint64_t fn_node);

/* Validate @deployment_target value is in {0..6} or AUTO.
 * Returns SEMA_XII_OK on success; SEMA_XII_FAIL on violation (XII-CANON-004). */
int sema_xii_check_deployment_target(uint64_t ast, uint64_t fn_node);

/* Combined entry: run both checks on a function declaration. */
int sema_xii_check_function(uint64_t ast, uint64_t fn_node);

/* AST-walker helper: count maximum nesting depth of fusion-call nodes
 * within `node`'s subtree. */
uint32_t sema_xii_measure_fusion_depth(uint64_t ast, uint64_t node);

/* ------------------------------------------------------------------ */
/* Explicit-AST annotation accessors for cg_r3.iii.                   */
/*                                                                    */
/* Take an iii_ast_t* directly (cast to uint64_t) and the AST node id */
/* for the function declaration.  No sema state needed, no ambient    */
/* required.  Used by the cg_r3 XII gate (`r3_emit_function` 9-line   */
/* insertion) to decide whether to invoke XII codegen on a function.  */
/*                                                                    */
/* anno_kind values: ANNO_LATTICE, ANNO_FUSION_BUDGET,                */
/*                   ANNO_DEPLOY_TARGET, ANNO_K_MAX_EXISTING,         */
/*                   ANNO_CAP_REQ_EXISTING, ANNO_HEXAD_EXISTING.      */
/* ------------------------------------------------------------------ */

uint8_t  sema_xii_anno_has_in_ast(uint64_t ast_raw, uint32_t fn_node, int anno_kind);
uint32_t sema_xii_anno_get_u32_in_ast(uint64_t ast_raw, uint32_t fn_node, int anno_kind, uint32_t default_val);

/* Set/restore the ambient sema-state handle that cg_r3_xii_adapter's
 * `g_xii_current_ast`-based shims consult.  cg_r3.iii wraps its XII
 * dispatch with set(R3_G_SEMA) ... set(0) so the ambient is only live
 * during XII-pipeline calls. */
void     xii_set_current_sema_state(uint64_t sema_state_handle);
uint64_t xii_get_current_sema_state(void);

#endif /* SEMA_XII_H */
