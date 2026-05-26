/* COMPILER/BOOT/xii_rewrite.h — C-side bridge to omnia/xii_rewrite.iii.
 *
 * Per DOCS/III-XII.md S9.1 + S26.1.
 *
 * NIH: libc only.
 */

#ifndef XII_REWRITE_H
#define XII_REWRITE_H

#include <stdint.h>

/* Apply the first matching rule at the root of `term_ref`.
 * Returns the (possibly new) term ref. If no rule matched, returns `term_ref` unchanged. */
extern uint32_t xii_rewrite_apply_one(uint32_t term_ref);

/* Returns the rule number (1..40) of the most-recently fired rule, or 0
 * if no rule fired on the last apply_one call. */
extern uint32_t xii_rewrite_last_rule_fired(void);

/* Cap-set computation for side-condition checks. */
extern uint32_t xii_rewrite_cap_set(uint32_t term_ref);
extern uint8_t  xii_rewrite_cap_disjoint(uint32_t a_ref, uint32_t b_ref);

/* Structural equality (deep). */
extern uint8_t  xii_rewrite_struct_eq(uint32_t t1, uint32_t t2);

/* Curated commutativity / composition tables for K05 ACT (R028/R029). */
extern int      xii_rewrite_tables_reset(void);
extern int      xii_rewrite_commute_set(uint8_t t1, uint8_t t2);
extern uint8_t  xii_rewrite_commute_get(uint8_t t1, uint8_t t2);
extern int      xii_rewrite_compose_set(uint8_t t1, uint8_t t2, uint8_t result);
extern uint8_t  xii_rewrite_compose_get(uint8_t t1, uint8_t t2);

/* Ground form sentinels. */
extern uint32_t xii_rewrite_null_form(void);
extern uint32_t xii_rewrite_noop_grant_form(void);
extern uint32_t xii_rewrite_trivial_lift_form(void);
extern uint32_t xii_rewrite_pe_const_true_form(void);
extern uint32_t xii_rewrite_pe_const_false_form(void);

/* Rule count. */
extern uint32_t xii_rewrite_rule_count(void);

#endif /* XII_REWRITE_H */
