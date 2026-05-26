/* ============================================================================
 * III-PHASES — phase_poly.c
 *
 * §2 of III-PHASES.md.  Phase polymorphism: cycles can declare a phase set
 * `@ring(R-2, R-1, R0, R3)` and the compiler synthesises a distinct lowering
 * for each ring in the set.
 *
 * This translation unit owns:
 *   - cycle registration and sealing
 *   - explicit body installation per ring
 *   - synthesis of the missing rings via cross-ring constructor composition
 *   - validation against the Phase-Polymorphic judgement (§2.1)
 * ============================================================================
 */
#include "phases_internal.h"
#include <string.h>

/* ----------------------------------------------------------------------------
 * Default step kinds per ring.  Used when an explicit body is registered
 * without an override — represents the canonical "this ran on ring R" witness.
 * ---------------------------------------------------------------------------- */
static iii_phase_step_kind_t default_step_kind_for(iii_phase_ring_t r) {
    switch (r) {
        case III_RING_SANCTUM:    return XII_STEP_KIND_SANCTUM_BODY;
        case III_RING_HYPERVISOR: return XII_STEP_KIND_IRPD_MSR_READ; /* generic IRPD */
        case III_RING_KERNEL:     return XII_STEP_KIND_R0_MSR_READ;
        case III_RING_USER:       return XII_STEP_KIND_R3_MAGIC_MSR_READ;
        default:                  return XII_STEP_KIND_NONE;
    }
}

/* Synthesised step kinds reflect the cross-ring constructor used. */
static iii_phase_step_kind_t synthesised_step_kind_for(iii_phase_ring_t target,
                                                       iii_phase_ring_t source)
{
    iii_phase_constructor_t c = iii_phase_constructor_for(source, target);
    switch (c) {
        case III_XR_MAGIC_MSR:
            return (target == III_RING_USER) ? XII_STEP_KIND_MAGIC_MSR_INVOKE
                                             : XII_STEP_KIND_MAGIC_MSR_DISPATCH;
        case III_XR_IOCTL:
            return (target == III_RING_USER) ? XII_STEP_KIND_IOCTL_ISSUE
                                             : XII_STEP_KIND_IOCTL_DISPATCH;
        case III_XR_SANCTUM_GATE:
            return (target == III_RING_SANCTUM) ? XII_STEP_KIND_SANCTUM_GATE_ENTER
                                                : XII_STEP_KIND_SANCTUM_GATE_EXIT;
        case III_XR_VMRUN:
            return (target == III_RING_KERNEL) ? XII_STEP_KIND_VMRUN
                                               : XII_STEP_KIND_VMEXIT;
        case III_XR_SYSRET:
            return (target == III_RING_USER) ? XII_STEP_KIND_SYSRET
                                              : XII_STEP_KIND_SYSCALL;
        default:
            return default_step_kind_for(target);
    }
}

/* ----------------------------------------------------------------------------
 * Cycle registration
 * ---------------------------------------------------------------------------- */

iii_phase_cycle_t *iii_phase_runtime_register_cycle(iii_phase_runtime_t *rt,
                                                   const char        *name,
                                                   iii_phase_set_t    phases)
{
    if (!rt || !name) return NULL;
    if (rt->cycle_count >= III_PHASES_MAX_CYCLES) return NULL;
    if (iii_phase_set_is_empty(phases)) return NULL;
    if (phases & ~III_PHASE_SET_ALL) return NULL;

    iii_phase_cycle_t *c = &rt->cycles[rt->cycle_count++];
    memset(c, 0, sizeof(*c));
    c->cycle_id        = ++rt->next_cycle_id;
    c->declared_phases = phases & III_PHASE_SET_ALL;
    c->ghost_phases    = III_PHASE_SET_EMPTY;
    c->specialized_ring = III_RING_COUNT; /* sentinel = unspecialized */

    /* Copy the name with bounds. */
    size_t i = 0;
    for (; i < sizeof(c->name) - 1u && name[i] != '\0'; ++i) {
        c->name[i] = name[i];
    }
    c->name[i] = '\0';

    return c;
}

bool iii_phase_cycle_add_body(iii_phase_cycle_t *c,
                              iii_phase_ring_t   ring,
                              uint64_t           body_hash,
                              iii_phase_step_kind_t step_kind)
{
    if (!c) return false;
    if (c->sealed) return false;
    if ((unsigned)ring >= (unsigned)III_RING_COUNT) return false;
    if (!iii_phase_set_contains(c->declared_phases, ring)) return false;

    /* Look for an existing slot for this ring. */
    for (unsigned i = 0; i < c->lowering_count; ++i) {
        if (c->lowerings[i].ring == ring) {
            c->lowerings[i].explicit_body = true;
            c->lowerings[i].synthesized   = false;
            c->lowerings[i].body_hash     = body_hash;
            c->lowerings[i].step_kind     = (step_kind == XII_STEP_KIND_NONE)
                                             ? default_step_kind_for(ring)
                                             : step_kind;
            return true;
        }
    }

    if (c->lowering_count >= III_PHASE_MAX_LOWERINGS) return false;

    iii_phase_lowering_t *lw = &c->lowerings[c->lowering_count++];
    lw->ring             = ring;
    lw->explicit_body    = true;
    lw->synthesized      = false;
    lw->body_hash        = body_hash;
    lw->step_kind        = (step_kind == XII_STEP_KIND_NONE)
                            ? default_step_kind_for(ring)
                            : step_kind;
    lw->invocation_count = 0;
    return true;
}

bool iii_phase_cycle_mark_ghost(iii_phase_cycle_t *c, iii_phase_set_t ghosts) {
    if (!c) return false;
    if (c->sealed) return false;
    /* Ghosts must be a subset of declared phases. */
    if (!iii_phase_set_subset(ghosts, c->declared_phases)) return false;
    c->ghost_phases = ghosts;
    return true;
}

void iii_phase_cycle_mark_candidate(iii_phase_cycle_t *c) {
    if (!c) return;
    c->candidate_for_promotion = true;
}

/* ----------------------------------------------------------------------------
 * Synthesis: for every ring in declared_phases that has no explicit body,
 * derive a synthesised lowering by composing cross-ring constructors from
 * the closest explicit body.
 *
 * Algorithm:
 *   1. If no explicit body exists at all, fail (untypable).
 *   2. For each declared ring R with no body:
 *      - Find the explicit body whose ring B has the shortest constructor
 *        chain to R (per iii_phase_chain_length).
 *      - Compute the step kind from the constructor used at the *final hop*
 *        landing on R (synthesised_step_kind_for(R, prev_hop)).
 *      - Inherit body_hash from the source so identity is preserved.
 *
 * Returns the number of synthesised lowerings, or -1 if no explicit body
 * exists in the cycle.
 * ---------------------------------------------------------------------------- */

static const iii_phase_lowering_t *find_explicit(const iii_phase_cycle_t *c,
                                                 iii_phase_ring_t ring)
{
    for (unsigned i = 0; i < c->lowering_count; ++i) {
        if (c->lowerings[i].ring == ring && c->lowerings[i].explicit_body) {
            return &c->lowerings[i];
        }
    }
    return NULL;
}

static const iii_phase_lowering_t *closest_explicit(const iii_phase_cycle_t *c,
                                                    iii_phase_ring_t target,
                                                    unsigned         *out_dist)
{
    const iii_phase_lowering_t *best      = NULL;
    unsigned                    best_dist = UINT32_MAX;
    for (unsigned i = 0; i < c->lowering_count; ++i) {
        if (!c->lowerings[i].explicit_body) continue;
        unsigned d = iii_phase_chain_length(c->lowerings[i].ring, target);
        if (d < best_dist) {
            best_dist = d;
            best      = &c->lowerings[i];
        }
    }
    if (out_dist) *out_dist = best_dist;
    return best;
}

int iii_phase_cycle_synthesize(iii_phase_cycle_t *c) {
    if (!c) return -1;
    if (c->sealed) return -1;

    /* Are there any explicit bodies? */
    bool any_explicit = false;
    for (unsigned i = 0; i < c->lowering_count; ++i) {
        if (c->lowerings[i].explicit_body) { any_explicit = true; break; }
    }
    if (!any_explicit) return -1;

    int synthesised = 0;
    for (unsigned r = 0; r < III_RING_COUNT; ++r) {
        iii_phase_ring_t ring = (iii_phase_ring_t)r;
        if (!iii_phase_set_contains(c->declared_phases, ring)) continue;
        if (find_explicit(c, ring) != NULL) continue;

        unsigned                    dist = 0;
        const iii_phase_lowering_t *src  = closest_explicit(c, ring, &dist);
        if (!src) return -1; /* untypable */

        /* Determine the previous hop on the path src -> ring. */
        iii_phase_ring_t prev = src->ring;
        iii_phase_ring_t walk = src->ring;
        while (walk != ring) {
            iii_phase_ring_t next = iii_phase_next_hop(walk, ring);
            prev = walk;
            walk = next;
            if (walk == prev) break; /* paranoia */
        }

        iii_phase_step_kind_t sk = synthesised_step_kind_for(ring, prev);

        /* Add the synthesised entry. */
        if (c->lowering_count >= III_PHASE_MAX_LOWERINGS) return -1;
        iii_phase_lowering_t *lw = &c->lowerings[c->lowering_count++];
        lw->ring             = ring;
        lw->explicit_body    = false;
        lw->synthesized      = true;
        lw->body_hash        = src->body_hash;
        lw->step_kind        = sk;
        lw->invocation_count = 0;
        ++synthesised;
    }

    return synthesised;
}

bool iii_phase_cycle_seal(iii_phase_cycle_t *c) {
    if (!c) return false;
    if (!iii_phase_cycle_validate(c)) return false;
    c->sealed = true;
    return true;
}

iii_phase_lowering_t *iii_phase_cycle_lowering(iii_phase_cycle_t *c,
                                               iii_phase_ring_t   ring)
{
    if (!c) return NULL;
    for (unsigned i = 0; i < c->lowering_count; ++i) {
        if (c->lowerings[i].ring == ring) return &c->lowerings[i];
    }
    return NULL;
}

/* ----------------------------------------------------------------------------
 * Validation: the cycle is valid iff every ring in declared_phases has either
 * an explicit body or a synthesised lowering, and every reachable cross-ring
 * pair has a constructor (true by construction in our 4-element lattice).
 * ---------------------------------------------------------------------------- */

bool iii_phase_cycle_validate(const iii_phase_cycle_t *c) {
    if (!c) return false;
    if (iii_phase_set_is_empty(c->declared_phases)) return false;

    iii_phase_set_t covered = III_PHASE_SET_EMPTY;
    for (unsigned i = 0; i < c->lowering_count; ++i) {
        const iii_phase_lowering_t *lw = &c->lowerings[i];
        if ((unsigned)lw->ring >= (unsigned)III_RING_COUNT) return false;
        covered = iii_phase_set_add(covered, lw->ring);
    }
    if (!iii_phase_set_equal(covered, c->declared_phases)) return false;

    /* Every pair in declared_phases must have a constructor or be reachable.
     * Since the 4-element lattice is fully connected via at most 2 hops, this
     * is satisfied by construction; we still verify for safety. */
    for (unsigned a = 0; a < III_RING_COUNT; ++a) {
        if (!iii_phase_set_contains(c->declared_phases, (iii_phase_ring_t)a)) continue;
        for (unsigned b = 0; b < III_RING_COUNT; ++b) {
            if (a == b) continue;
            if (!iii_phase_set_contains(c->declared_phases, (iii_phase_ring_t)b)) continue;
            unsigned d = iii_phase_chain_length((iii_phase_ring_t)a, (iii_phase_ring_t)b);
            if (d > 2u) return false;
        }
    }

    /* Ghost phases must be subset of declared phases. */
    if (!iii_phase_set_subset(c->ghost_phases, c->declared_phases)) return false;

    return true;
}
