/* ============================================================================
 * III-PHASES — internal definitions
 * Shared private state used across the implementation translation units.
 * ============================================================================
 */
#ifndef III_PHASES_INTERNAL_H
#define III_PHASES_INTERNAL_H

#include "iii/phases.h"
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

/* ----------------------------------------------------------------------------
 * Capacity bounds — sized for a single substrate; bounded so the entire phase
 * runtime fits comfortably in the kernel's static arena.
 * ---------------------------------------------------------------------------- */

#define III_PHASES_MAX_CYCLES        4096u
#define III_PHASES_MAX_WITNESSES     65536u

/* Hot ring threshold (§8): a ring is "hot" when its share of invocations
 * exceeds this fraction (q12 fixed-point). 70% of total invocations chosen as
 * the conservative trigger. */
#define III_PHASE_HOT_THRESHOLD_Q12  ((uint16_t)2867u)  /* 0.70 * 4096 ≈ 2867 */

/* Minimum total invocations before specialization is considered. */
#define III_PHASE_MIN_INVOCATIONS    8u

/* ----------------------------------------------------------------------------
 * iii_phase_runtime_t — the opaque runtime handle exposed in the public API.
 * ---------------------------------------------------------------------------- */
struct iii_phase_runtime {
    /* Cycle table */
    iii_phase_cycle_t   cycles[III_PHASES_MAX_CYCLES];
    unsigned            cycle_count;
    uint64_t            next_cycle_id;

    /* Witness ring (oldest-overwrite for forensics; the BCWL elsewhere keeps
     * the durable copy).  The ring stores the most recent N witnesses. */
    iii_phase_witness_t witnesses[III_PHASES_MAX_WITNESSES];
    uint64_t            witness_seq;        /* total emitted */
    uint64_t            witness_head;       /* next slot to write */

    /* Per-tick rate cap counter for promotion. */
    uint32_t            promote_count_this_tick;
    uint64_t            tick_count;

    /* Current ring (per-runtime; in real systems would be per-CPU). */
    iii_phase_ring_t    current_ring;
};

/* ----------------------------------------------------------------------------
 * Internal helpers (witness emission, mhash computation)
 * ---------------------------------------------------------------------------- */

/* SHA-256 of an arbitrary buffer.  Self-contained — implemented in mhash.c. */
void iii_phases_sha256(const void *data, size_t len, uint8_t out[32]);

/* Compute a successor mhash from predecessor + canonical event encoding.
 *   mhash = SHA-256( predecessor || cycle_id_le || step_kind_byte || ring_byte )
 * Deterministic — replayable across federation peers. */
void iii_phases_chain_mhash(const uint8_t          predecessor[32],
                            uint64_t               cycle_id,
                            iii_phase_step_kind_t  step_kind,
                            iii_phase_ring_t       ring,
                            uint8_t                out_mhash[32]);

/* Emit a witness into the ring; returns the assigned seq number. */
uint64_t iii_phases_emit_witness(iii_phase_runtime_t   *rt,
                                 uint64_t               cycle_id,
                                 iii_phase_ring_t       ring,
                                 iii_phase_step_kind_t  step_kind,
                                 const uint8_t          predecessor[32],
                                 uint8_t                out_mhash[32]);

#endif /* III_PHASES_INTERNAL_H */
