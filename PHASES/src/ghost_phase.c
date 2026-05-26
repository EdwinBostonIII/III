/* ============================================================================
 * III-PHASES — ghost_phase.c
 *
 * §7 of III-PHASES.md.  Ghost phases: a cycle marked `@ghost(R)` produces a
 * full witness when invoked at ring R but performs no privileged work — it
 * returns the default value of its return type, while still emitting a hash-
 * chained witness so the federation, the operator, and the audit trail all
 * see the cycle was *observed* at R, not *performed* at R.
 *
 * Used for:
 *   - pre-flight simulation (run in ghost mode at R3 to verify the witness
 *     chain, then execute for real at R0)
 *   - federated audit (peers replicate ghost witnesses without local effect)
 *   - operator dry-run ("what would happen if this cycle ran?")
 * ============================================================================
 */
#include "phases_internal.h"
#include <string.h>

bool iii_phase_runtime_ghost_observe(iii_phase_runtime_t          *rt,
                                     iii_phase_cycle_t            *cycle,
                                     iii_phase_ring_t              ring,
                                     const uint8_t                 predecessor_mhash[32],
                                     iii_phase_ghost_witness_t    *out_witness)
{
    if (!rt || !cycle) return false;
    if ((unsigned)ring >= (unsigned)III_RING_COUNT) return false;

    /* The ring must be in the cycle's declared phases — you can't observe a
     * cycle at a ring it doesn't claim to inhabit.  However, the ring need
     * not be in `ghost_phases`; ghost-observe is also legal at non-ghost
     * rings as a pure simulation primitive (the witness is just labelled as
     * a ghost step kind so consumers know no privileged work occurred). */
    if (!iii_phase_set_contains(cycle->declared_phases, ring)) {
        return false;
    }

    uint8_t mhash[32];
    iii_phases_emit_witness(rt,
                            cycle->cycle_id,
                            ring,
                            XII_STEP_KIND_GHOST_OBSERVE,
                            predecessor_mhash,
                            mhash);

    if (out_witness) {
        out_witness->cycle_id  = cycle->cycle_id;
        out_witness->ring      = ring;
        out_witness->step_kind = XII_STEP_KIND_GHOST_OBSERVE;
        memcpy(out_witness->predecessor_mhash, predecessor_mhash, 32);
        memcpy(out_witness->ghost_mhash,       mhash,             32);
    }

    return true;
}
