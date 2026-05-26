/* COMPILER/BOOT/xii_term.h — C-side bridge to omnia/xii_term.iii.
 *
 * Per DOCS/III-XII.md S3 + S26.13.
 *
 * NIH: libc only.
 */

#ifndef XII_TERM_H
#define XII_TERM_H

#include <stdint.h>

/* Term node kinds. */
#define XII_K01_FORM     0u
#define XII_K02_BIND     1u
#define XII_K03_CONVEY   2u
#define XII_K04_MEAN     3u
#define XII_K05_ACT      4u
#define XII_K06_COMPOSE  5u
#define XII_K07_SEAL     6u
#define XII_K08_PROVE    7u
#define XII_K09_QUERY    8u
#define XII_K10_GRANT    9u
#define XII_K11_GOVERN   10u
#define XII_K12_THEN     11u
#define XII_K13_WITH     12u
#define XII_K14_UNDER    13u
#define XII_K15_IF       14u
#define XII_K16_LOOP     15u
#define XII_K17_LIFT     16u
#define XII_K18_REFLECT  17u
#define XII_FCOMPOSE     18u
#define XII_FTHEN        19u
#define XII_FWITH        20u
#define XII_FUNDER       21u
#define XII_FIF          22u
#define XII_FLOOP        23u

#define XII_KIND_MAX     23u
#define XII_BASIS_KIND_LAST 17u
#define XII_NULL_REF     0xFFFFFFFFu

/* Hexad values. */
#define XII_HEXAD_NONE      0u
#define XII_HEXAD_FORM      1u
#define XII_HEXAD_SUBSTANCE 2u
#define XII_HEXAD_PASSAGE   3u
#define XII_HEXAD_ESSENCE   4u
#define XII_HEXAD_MOTION    5u
#define XII_HEXAD_COMPOSE   6u
#define XII_HEXAD_ORIGIN    7u

/* Arena geometry. */
#define XII_TERM_BYTES       32u
#define XII_TERM_ARENA_BYTES 32768u
#define XII_TERM_ARENA_CAP   1024u

/* Lifecycle. */
extern int      xii_term_arena_reset(void);
extern uint32_t xii_term_arena_used(void);
extern uint32_t xii_term_arena_capacity(void);

/* Allocation. */
extern uint32_t xii_term_alloc(void);

/* Field accessors. */
extern int      xii_term_set_kind(uint32_t idx, uint8_t kind);
extern uint8_t  xii_term_get_kind(uint32_t idx);
extern int      xii_term_set_flags(uint32_t idx, uint8_t flags);
extern uint8_t  xii_term_get_flags(uint32_t idx);
extern int      xii_term_set_hexad(uint32_t idx, uint8_t hexad);
extern uint8_t  xii_term_get_hexad(uint32_t idx);
extern int      xii_term_set_subform(uint32_t idx, uint32_t sub);
extern uint32_t xii_term_get_subform(uint32_t idx);
extern int      xii_term_set_child_a(uint32_t idx, uint32_t ref);
extern uint32_t xii_term_get_child_a(uint32_t idx);
extern int      xii_term_set_child_b(uint32_t idx, uint32_t ref);
extern uint32_t xii_term_get_child_b(uint32_t idx);
extern int      xii_term_set_child_c(uint32_t idx, uint32_t ref);
extern uint32_t xii_term_get_child_c(uint32_t idx);
extern int      xii_term_set_aux(uint32_t idx, uint64_t aux);
extern uint64_t xii_term_get_aux(uint32_t idx);
extern int      xii_term_set_weight_mpo(uint32_t idx, uint32_t w);
extern uint32_t xii_term_get_weight_mpo(uint32_t idx);

/* Convenience constructors. */
extern uint32_t xii_term_make_basis(uint8_t kind, uint32_t subform);
extern uint32_t xii_term_make_fusion2(uint8_t kind, uint32_t child_a, uint32_t child_b);
extern uint32_t xii_term_make_if(uint32_t pred, uint32_t then_b, uint32_t else_b);
extern uint32_t xii_term_make_loop(uint32_t body, uint64_t count);

/* Predicates. */
extern uint8_t  xii_term_is_basis(uint32_t idx);
extern uint8_t  xii_term_is_fusion(uint32_t idx);
extern uint8_t  xii_term_is_null(uint32_t ref);
extern uint8_t  xii_term_is_kind(uint32_t idx, uint8_t kind);

/* Compute SHA-256 of a single term node's bytes. */
extern int      xii_term_mhash(uint32_t idx, uint8_t *out_32);

#endif /* XII_TERM_H */
