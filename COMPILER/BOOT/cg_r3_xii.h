/* COMPILER/BOOT/cg_r3_xii.h — XII extensions to cg_r3 codegen.
 *
 * Per DOCS/III-XII.md S14.4 + S26.13.
 *
 * Provides r3_pe_canonicalise, r3_pe_lattice_emit, r3_compute_circ,
 * xii_enabled_for. These are called from cg_r3.c when a function carries
 * any fusion expression or the @lattice annotation. Integration point in
 * r3_emit_decl_fn is a 9-line insertion (see DOCS/III-XII.md S14.4).
 *
 * NIH: libc + Win32 only.
 */

#ifndef CG_R3_XII_H
#define CG_R3_XII_H

#include <stdint.h>

#define XII_R3_OK   0
#define XII_R3_FAIL 1
#define XII_R3_NOTREL 2  /* function has no XII features; fall through */

/* Annotation kind ids (matching sema.c constants). */
#define XII_ANNO_FUSION_BUDGET   0x10
#define XII_ANNO_DEPLOY_TARGET   0x11
#define XII_ANNO_LATTICE         0x12

/* Returns 1 if function should be XII-processed; 0 otherwise. */
int xii_enabled_for(uint64_t ast, uint64_t fn_node);

/* Compute the 24-bit circumstance encoding from function annotations. */
uint32_t r3_compute_circ(uint64_t ast, uint64_t fn_node);

/* XII canonicalisation pre-pass: applies the 40 reduction rules to
 * the function body's fusion subtrees, in-place. */
int r3_pe_canonicalise(uint64_t ast, uint64_t fn_node);

/* XII Lattice-driven emit: looks up canonical-form pattern in Lattice,
 * emits placeholder bytes (NOPs) + records call-site descriptor in
 * .iii_xii_calls section for later LDIL inlining. */
int r3_pe_lattice_emit(uint64_t ast, uint64_t fn_node, uint32_t circ_encoding);

/* Emit one call-site descriptor (24 bytes) to the .iii_xii_calls section. */
int r3_emit_xii_call_site(uint64_t call_site_offset,
                          uint8_t horizon_id,
                          uint8_t static_circ_flag,
                          uint32_t circ_encoding,
                          uint16_t expected_size,
                          uint8_t ct_kind,
                          uint8_t prov_xform_id,
                          uint32_t deployment_target);

#endif /* CG_R3_XII_H */
