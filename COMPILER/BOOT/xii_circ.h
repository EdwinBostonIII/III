/* COMPILER/BOOT/xii_circ.h — C-side bridge to omnia/xii_circ.iii.
 *
 * Per DOCS/III-XII.md S11.
 *
 * NIH: libc only.
 */

#ifndef XII_CIRC_H
#define XII_CIRC_H

#include <stdint.h>

/* Encoding helpers. */
extern uint32_t xii_circ_encode(uint32_t target, uint32_t hw_mask, uint32_t k_bucket,
                                 uint32_t cap_class, uint32_t hexad, uint32_t fusion_budget);
extern uint32_t xii_circ_target(uint32_t circ);
extern uint32_t xii_circ_hw_mask(uint32_t circ);
extern uint32_t xii_circ_k_bucket(uint32_t circ);
extern uint32_t xii_circ_cap_class(uint32_t circ);
extern uint32_t xii_circ_hexad(uint32_t circ);
extern uint32_t xii_circ_fusion_budget(uint32_t circ);

/* Feasibility predicates (13 individual + 1 aggregate). */
extern uint8_t  xii_circ_feasible(uint32_t circ);

/* Count of feasible circumstances over the full 2^20 search space. */
extern uint32_t xii_circ_count_feasible(void);

#endif /* XII_CIRC_H */
