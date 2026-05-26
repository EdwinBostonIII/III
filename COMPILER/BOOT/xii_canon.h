/* COMPILER/BOOT/xii_canon.h — C-side bridge to omnia/xii_canonicalise.iii.
 *
 * Per DOCS/III-XII.md S9 + S26.13.
 *
 * NIH: libc only.
 */

#ifndef XII_CANON_H
#define XII_CANON_H

#include <stdint.h>

#define XII_TERM_NULL_REF 0xFFFFFFFFu

/* Canonicalise the term subtree rooted at `term_ref`. Returns the (possibly
 * new) canonical-form term ref. Side-effecting: may mutate the term arena. */
extern uint32_t xii_canonicalise(uint32_t term_ref);

/* Check if a term is already in canonical form. */
extern uint8_t xii_is_canonical(uint32_t term_ref);

/* Number of rule applications performed in the last canonicalisation. */
extern uint32_t xii_canonicalise_last_steps(void);

/* Compute MPO weight (termination bound). */
extern uint32_t xii_canon_weight(uint32_t term_ref);

#endif /* XII_CANON_H */
