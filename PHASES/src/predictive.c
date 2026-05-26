/* ============================================================================
 * III-PHASES — predictive.c
 *
 * §8 of III-PHASES.md.  Predictive phase specialisation: SRPA observes which
 * ring a phase-polymorphic cycle is invoked at most often and the runtime
 * specialises that ring's lowering for the hot path.
 *
 * "Hot" is determined by the cycle's invocation distribution.  When one
 * ring's share of invocations exceeds III_PHASE_HOT_THRESHOLD_Q12 (default
 * 70%) and the cycle has at least III_PHASE_MIN_INVOCATIONS total samples,
 * specialisation is recommended.
 *
 * The actual code-emission pre-materialisation (PIP per III-EFFECTS.md §3)
 * is the SELF compiler's job; this translation unit owns the *decision* and
 * the *witness* — deciding whether to specialise, which ring to specialise
 * to, and emitting XII_STEP_KIND_PIP_SPECIALIZE when the decision is made.
 * ============================================================================
 */
#include "phases_internal.h"
#include <string.h>

void iii_phase_runtime_observe_invocation(iii_phase_runtime_t *rt,
                                          iii_phase_cycle_t   *cycle,
                                          iii_phase_ring_t     ring)
{
    (void)rt;
    if (!cycle) return;
    if ((unsigned)ring >= (unsigned)III_RING_COUNT) return;

    iii_phase_lowering_t *lw = iii_phase_cycle_lowering(cycle, ring);
    if (!lw) return; /* invocation at a ring we don't have a lowering for */

    if (lw->invocation_count != UINT32_MAX) {
        lw->invocation_count++;
    }
    if (cycle->total_invocations != UINT64_MAX) {
        cycle->total_invocations++;
    }
}

bool iii_phase_cycle_hottest_ring(const iii_phase_cycle_t *cycle,
                                  iii_phase_ring_t        *out_ring)
{
    if (!cycle) return false;
    if (cycle->total_invocations < (uint64_t)III_PHASE_MIN_INVOCATIONS) return false;

    /* Find the lowering with the highest invocation count.  Compare against
     * the q12 threshold of total invocations. */
    uint32_t              best_count = 0;
    iii_phase_ring_t      best_ring  = III_RING_COUNT;
    for (unsigned i = 0; i < cycle->lowering_count; ++i) {
        if (cycle->lowerings[i].invocation_count > best_count) {
            best_count = cycle->lowerings[i].invocation_count;
            best_ring  = cycle->lowerings[i].ring;
        }
    }
    if (best_ring == III_RING_COUNT) return false;

    /* threshold = total * (HOT_THRESHOLD_Q12 / 4096) */
    uint64_t threshold = (cycle->total_invocations * (uint64_t)III_PHASE_HOT_THRESHOLD_Q12) >> 12;
    if ((uint64_t)best_count <= threshold) return false;

    if (out_ring) *out_ring = best_ring;
    return true;
}

iii_phase_specialize_status_t iii_phase_runtime_specialize(iii_phase_runtime_t *rt,
                                                           iii_phase_cycle_t   *cycle,
                                                           iii_phase_ring_t     ring)
{
    if (!rt || !cycle) return III_PHASE_SPECIALIZE_ERR_INVALID;
    if ((unsigned)ring >= (unsigned)III_RING_COUNT) return III_PHASE_SPECIALIZE_ERR_INVALID;
    if (!iii_phase_set_contains(cycle->declared_phases, ring)) {
        return III_PHASE_SPECIALIZE_ERR_INVALID;
    }
    if (cycle->specialized_ring == ring) return III_PHASE_SPECIALIZE_ALREADY;

    cycle->specialized_ring = ring;

    uint8_t pred[32]; memset(pred, 0, sizeof(pred));
    iii_phases_emit_witness(rt,
                            cycle->cycle_id,
                            ring,
                            XII_STEP_KIND_PIP_SPECIALIZE,
                            pred,
                            NULL);
    return III_PHASE_SPECIALIZE_OK;
}

iii_phase_specialize_status_t iii_phase_runtime_despecialize(iii_phase_runtime_t *rt,
                                                             iii_phase_cycle_t   *cycle)
{
    if (!rt || !cycle) return III_PHASE_SPECIALIZE_ERR_INVALID;
    if (cycle->specialized_ring == III_RING_COUNT) return III_PHASE_SPECIALIZE_ERR_NO_HOT_RING;

    iii_phase_ring_t prior = cycle->specialized_ring;
    cycle->specialized_ring = III_RING_COUNT;

    uint8_t pred[32]; memset(pred, 0, sizeof(pred));
    iii_phases_emit_witness(rt,
                            cycle->cycle_id,
                            prior,
                            XII_STEP_KIND_PIP_DESPECIALIZE,
                            pred,
                            NULL);
    return III_PHASE_SPECIALIZE_OK;
}
