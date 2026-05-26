/* COMPILER/BOOT/sema_xii.c — XII semantic-check extensions (implementation).
 *
 * Per DOCS/III-XII.md S15 + S26.13.
 *
 * NIH: libc + Win32 only.
 */

#include "sema_xii.h"
#include <stdio.h>
#include <stdint.h>

/* AST/sema externs. */
extern int sema_has_annotation(uint64_t fn_node, int anno_kind);
extern uint32_t sema_get_anno_u32(uint64_t fn_node, int anno_kind, uint32_t default_val);
extern void sema_emit_error(uint64_t ast, uint64_t node, const char *fmt, ...);
extern int ast_get_kind(uint64_t ast, uint64_t node);
extern uint64_t ast_get_child(uint64_t ast, uint64_t node, int idx);
extern uint32_t ast_get_child_count(uint64_t ast, uint64_t node);

/* AST kinds */
#define XII_K_FUSION_CALL  0x80

/* ------------------------------------------------------------------ */
/* Fusion-depth measurement (DAG-depth)                                */
/* ------------------------------------------------------------------ */

uint32_t
sema_xii_measure_fusion_depth(uint64_t ast, uint64_t node)
{
    if (node == 0) return 0;
    int kind = ast_get_kind(ast, node);
    uint32_t max_child = 0;
    uint32_t nc = ast_get_child_count(ast, node);
    for (uint32_t i = 0; i < nc; ++i) {
        uint64_t c = ast_get_child(ast, node, (int)i);
        uint32_t cd = sema_xii_measure_fusion_depth(ast, c);
        if (cd > max_child) max_child = cd;
    }
    if (kind == XII_K_FUSION_CALL) return max_child + 1;
    return max_child;
}

/* ------------------------------------------------------------------ */
/* sema_xii_check_fusion_budget                                        */
/* ------------------------------------------------------------------ */

int
sema_xii_check_fusion_budget(uint64_t ast, uint64_t fn_node)
{
    uint32_t budget = sema_get_anno_u32(fn_node, ANNO_FUSION_BUDGET, 3);
    uint32_t k_max = sema_get_anno_u32(fn_node, ANNO_K_MAX_EXISTING, 16);

    if (budget > k_max) {
        sema_emit_error(ast, fn_node,
            "XII-CANON-003: @fusion_budget (%u) > @k_max (%u)",
            budget, k_max);
        return SEMA_XII_FAIL;
    }
    if (budget > 16) {
        sema_emit_error(ast, fn_node,
            "XII-CANON-003: @fusion_budget (%u) exceeds max 16",
            budget);
        return SEMA_XII_FAIL;
    }

    uint32_t observed = sema_xii_measure_fusion_depth(ast, fn_node);
    if (observed > budget) {
        sema_emit_error(ast, fn_node,
            "XII-CANON-003: observed fusion depth %u > @fusion_budget %u",
            observed, budget);
        return SEMA_XII_FAIL;
    }
    return SEMA_XII_OK;
}

/* ------------------------------------------------------------------ */
/* sema_xii_check_deployment_target                                    */
/* ------------------------------------------------------------------ */

int
sema_xii_check_deployment_target(uint64_t ast, uint64_t fn_node)
{
    uint32_t target = sema_get_anno_u32(fn_node, ANNO_DEPLOY_TARGET, XII_AUTO_TARGET);
    if (target == XII_AUTO_TARGET) return SEMA_XII_OK;
    if (target > 6) {
        sema_emit_error(ast, fn_node,
            "XII-CANON-004: unknown @deployment_target value %u (must be 0..6)",
            target);
        return SEMA_XII_FAIL;
    }
    return SEMA_XII_OK;
}

/* ------------------------------------------------------------------ */
/* Combined entry                                                      */
/* ------------------------------------------------------------------ */

int
sema_xii_check_function(uint64_t ast, uint64_t fn_node)
{
    int rc = sema_xii_check_fusion_budget(ast, fn_node);
    if (rc != SEMA_XII_OK) return rc;
    rc = sema_xii_check_deployment_target(ast, fn_node);
    if (rc != SEMA_XII_OK) return rc;
    return SEMA_XII_OK;
}
