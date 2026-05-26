/* ============================================================================
 * III-PHASES — epistemic_phase.c
 *
 * §6 of III-PHASES.md.  Epistemic phases: a cycle can introspect its current
 * execution ring via `phase.current()`.  In real hardware this is read from
 * a privileged register (CS.DPL on x86-64 or equivalent); in our runtime
 * model it is a per-runtime field updated when execution enters/exits a ring.
 *
 * The runtime acts as a single-CPU model.  Multi-CPU substrates would store
 * one current_ring per logical core.
 * ============================================================================
 */
#include "phases_internal.h"

void iii_phase_runtime_set_current(iii_phase_runtime_t *rt, iii_phase_ring_t r) {
    if (!rt) return;
    if ((unsigned)r >= (unsigned)III_RING_COUNT) return;
    rt->current_ring = r;
}

iii_phase_ring_t iii_phase_runtime_current(const iii_phase_runtime_t *rt) {
    return rt ? rt->current_ring : III_RING_USER;
}
