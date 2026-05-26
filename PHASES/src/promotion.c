/* ============================================================================
 * III-PHASES — promotion.c
 *
 * §5 of III-PHASES.md.  Dynamic phase promotion: a cycle marked
 * `@candidate_for_promotion` may climb the privilege ladder at runtime if all
 * five preconditions hold.  Promotions are rate-capped per chronos-tick
 * (XII_PHASE_PROMOTE_RATE = 4) and reversible via demote().
 *
 * Preconditions (all must hold):
 *   1. cycle->candidate_for_promotion
 *   2. target ring is *more* privileged than every ring currently in declared_phases
 *   3. hexad still admissible at target ring (caller signals this)
 *   4. trinity admission still discharged (caller signals this)
 *   5. manifold coherence ≥ floor (caller signals this)
 *
 * After successful promotion:
 *   - declared_phases gains the target ring
 *   - a synthesised lowering for the target is added (or the caller adds an
 *     explicit body before promotion)
 *   - rate counter is incremented
 *   - XII_STEP_KIND_PHASE_PROMOTE witness emitted
 * ============================================================================
 */
#include "phases_internal.h"
#include <string.h>

void iii_phase_runtime_tick(iii_phase_runtime_t *rt) {
    if (!rt) return;
    rt->promote_count_this_tick = 0;
    rt->tick_count++;
}

uint32_t iii_phase_runtime_promote_count_this_tick(const iii_phase_runtime_t *rt) {
    return rt ? rt->promote_count_this_tick : 0u;
}

iii_phase_promote_status_t iii_phase_runtime_promote(
    iii_phase_runtime_t                 *rt,
    const iii_phase_promote_request_t   *req)
{
    if (!rt || !req || !req->cycle) return III_PHASE_PROMOTE_ERR_INVALID;
    if ((unsigned)req->target_ring >= (unsigned)III_RING_COUNT) {
        return III_PHASE_PROMOTE_ERR_INVALID;
    }

    iii_phase_cycle_t *c = req->cycle;
    if (!c->candidate_for_promotion) return III_PHASE_PROMOTE_ERR_NOT_CANDIDATE;

    /* Already covered? */
    if (iii_phase_set_contains(c->declared_phases, req->target_ring)) {
        return III_PHASE_PROMOTE_ERR_ALREADY_AT_RING;
    }

    /* Promotion only climbs the lattice — the target ring must be more
     * privileged than the most-privileged ring currently in the set.
     * (Adding a *less*-privileged ring is "extending coverage", not promotion;
     * we treat it as an invalid promotion for safety.) */
    iii_phase_ring_t most_privileged = iii_phase_set_min(c->declared_phases);
    if (!iii_phase_lt(req->target_ring, most_privileged)) {
        return III_PHASE_PROMOTE_ERR_INVALID;
    }

    /* Hexad / Trinity / Coherence — caller must signal these are satisfied. */
    if (!req->hexad_admissible_at_target) return III_PHASE_PROMOTE_ERR_HEXAD_REJECT;
    if (!req->trinity_discharged)         return III_PHASE_PROMOTE_ERR_TRINITY_REJECT;
    if (req->coherence_q12 < req->coherence_floor_q12) {
        return III_PHASE_PROMOTE_ERR_COHERENCE;
    }

    /* Rate cap. */
    if (rt->promote_count_this_tick >= XII_PHASE_PROMOTE_RATE) {
        return III_PHASE_PROMOTE_ERR_RATE_CAP;
    }

    /* Apply promotion. */
    bool was_sealed = c->sealed;
    c->sealed = false;          /* temporarily un-seal to amend */
    c->declared_phases = iii_phase_set_add(c->declared_phases, req->target_ring);

    /* If no lowering exists for the target, synthesise one from the closest
     * existing body. */
    if (!iii_phase_cycle_lowering(c, req->target_ring)) {
        (void)iii_phase_cycle_synthesize(c);
    }

    if (was_sealed) {
        if (!iii_phase_cycle_seal(c)) {
            /* Roll back. */
            c->declared_phases = iii_phase_set_remove(c->declared_phases, req->target_ring);
            for (unsigned i = 0; i < c->lowering_count; ++i) {
                if (c->lowerings[i].ring == req->target_ring && c->lowerings[i].synthesized) {
                    /* Remove the trailing entry by shifting. */
                    for (unsigned j = i; j + 1 < c->lowering_count; ++j) {
                        c->lowerings[j] = c->lowerings[j + 1];
                    }
                    c->lowering_count--;
                    break;
                }
            }
            return III_PHASE_PROMOTE_ERR_INVALID;
        }
    }

    /* Witness. */
    uint8_t pred[32]; memset(pred, 0, sizeof(pred));
    iii_phases_emit_witness(rt,
                            c->cycle_id,
                            req->target_ring,
                            XII_STEP_KIND_PHASE_PROMOTE,
                            pred,
                            NULL);

    rt->promote_count_this_tick++;
    return III_PHASE_PROMOTE_OK;
}

iii_phase_promote_status_t iii_phase_runtime_demote(iii_phase_runtime_t *rt,
                                                   iii_phase_cycle_t   *cycle,
                                                   iii_phase_ring_t     ring_to_remove)
{
    if (!rt || !cycle) return III_PHASE_PROMOTE_ERR_INVALID;
    if (!iii_phase_set_contains(cycle->declared_phases, ring_to_remove)) {
        return III_PHASE_PROMOTE_ERR_INVALID;
    }
    /* Demotion preserves the cycle's least-privileged ring at minimum.  We
     * refuse to remove the *only* ring (would orphan the cycle). */
    if (iii_phase_set_cardinality(cycle->declared_phases) <= 1u) {
        return III_PHASE_PROMOTE_ERR_INVALID;
    }

    bool was_sealed = cycle->sealed;
    cycle->sealed = false;
    cycle->declared_phases = iii_phase_set_remove(cycle->declared_phases, ring_to_remove);

    /* Drop the corresponding lowering. */
    for (unsigned i = 0; i < cycle->lowering_count; ++i) {
        if (cycle->lowerings[i].ring == ring_to_remove) {
            for (unsigned j = i; j + 1 < cycle->lowering_count; ++j) {
                cycle->lowerings[j] = cycle->lowerings[j + 1];
            }
            cycle->lowering_count--;
            break;
        }
    }

    if (was_sealed) {
        cycle->sealed = true;
    }

    /* Witness. */
    uint8_t pred[32]; memset(pred, 0, sizeof(pred));
    iii_phases_emit_witness(rt,
                            cycle->cycle_id,
                            ring_to_remove,
                            XII_STEP_KIND_PHASE_DEMOTE,
                            pred,
                            NULL);

    return III_PHASE_PROMOTE_OK;
}
