/* COMPILER/BOOT/xii_horizon.h — C-side bridge to omnia/xii_horizon.iii.
 *
 * Per DOCS/III-XII.md S10 + S26.8.
 *
 * NIH: libc only.
 */

#ifndef XII_HORIZON_H
#define XII_HORIZON_H

#include <stdint.h>

#define XII_HORIZON_COUNT 144
#define XII_HORIZON_PRODUCTIVE_COUNT 126

/* Initialise the Horizon metadata + template tables. Called once at boot. */
extern int xii_horizon_init(void);

/* Metadata accessors. */
extern uint8_t  xii_horizon_hexad(uint32_t id);
extern uint8_t  xii_horizon_primary_op(uint32_t id);
extern uint32_t xii_horizon_k_cost(uint32_t id);
extern uint8_t  xii_horizon_cap_class(uint32_t id);
extern uint8_t  xii_horizon_ct_kind(uint32_t id);
extern uint8_t  xii_horizon_is_productive(uint32_t id);
extern uint8_t  xii_horizon_template_kind(uint32_t id);
extern uint32_t xii_horizon_count(void);
extern uint32_t xii_horizon_productive_count(void);

/* Build the algebra term for a given pattern id. Returns term_ref or
 * XII_TERM_NULL_REF on guard cell / reserved. */
extern uint32_t xii_horizon_construct(uint32_t id);

#endif /* XII_HORIZON_H */
