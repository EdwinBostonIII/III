/* COMPILER/BOOT/iiis1_link_stubs.c
 *
 * Link-compatibility stubs for iiis-1 builds.
 *
 * iiis-1 is the bit-identity iiis-0-self-host intermediate, built
 * WITHOUT -DIIIS_XII_ENABLED.  build_iiis1.sh excludes all `*xii*.c`
 * sources from compilation (line "! -name '*xii*.c'") so iiis-1 has
 * none of the XII C-side surface.  However, cg_r3.iii contains the
 * Phase-XII-eta dispatch gate which references several XII symbols
 * unconditionally (.iii has no #ifdef).  Without definitions, iiis-1
 * fails to link.
 *
 * This file provides no-op stubs for those symbols when XII is OFF.
 * Under -DIIIS_XII_ENABLED (iiis-2), every function below is guarded
 * out and the real implementations in sema_xii_adapter.c /
 * cg_r3_xii.c take over.  Triple bit-identity (iiis-0 = iiis-1 =
 * iiis-2 codegen for every non-@lattice input) is preserved because
 * sema_xii_anno_has_in_ast() always returns 0 in iiis-1, so the
 * cg_r3.iii gate always falls through to the legacy block emitter.
 *
 * NIH: libc only.  No #include "sema_xii.h" or "cg_r3_xii.h" -- we
 * declare the prototypes locally to avoid pulling in headers that
 * have their own IIIS_XII_ENABLED gating.
 */

#ifndef IIIS_XII_ENABLED

#include <stdint.h>

/* sema_xii_adapter.c surface (annotation queries). */

uint8_t
sema_xii_anno_has_in_ast(uint64_t ast_raw, uint32_t fn_node, int anno_kind)
{
    (void)ast_raw; (void)fn_node; (void)anno_kind;
    return 0u;   /* "no XII annotation" -> gate falls through */
}

uint32_t
sema_xii_anno_get_u32_in_ast(uint64_t ast_raw, uint32_t fn_node, int anno_kind, uint32_t default_val)
{
    (void)ast_raw; (void)fn_node; (void)anno_kind;
    return default_val;
}

void
xii_set_current_sema_state(uint64_t sema_state_handle)
{
    (void)sema_state_handle;
}

uint64_t
xii_get_current_sema_state(void)
{
    return 0;
}

/* cg_r3_xii.c surface (XII codegen entry points).  These are never
 * called in iiis-1 because the cg_r3.iii gate short-circuits to the
 * legacy path on the sema_xii_anno_has_in_ast == 0 above.  They
 * exist only as link-time symbols. */

int32_t
r3_pe_canonicalise(uint64_t ast, uint64_t fn_node)
{
    (void)ast; (void)fn_node;
    return 0;
}

uint32_t
r3_compute_circ(uint64_t ast, uint64_t fn_node)
{
    (void)ast; (void)fn_node;
    return 0u;
}

int32_t
r3_pe_lattice_emit(uint64_t ast, uint64_t fn_node, uint32_t circ)
{
    (void)ast; (void)fn_node; (void)circ;
    return 0;
}

/* g_xii_current_ast: declared by sema_xii_adapter.c when XII is on.
 * Provide the global storage here for iiis-1 to satisfy any code
 * that references it (none currently, but defensive). */
uint64_t g_xii_current_ast = 0;

#endif /* !IIIS_XII_ENABLED */
