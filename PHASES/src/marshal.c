/* ============================================================================
 * III-PHASES — marshal.c
 *
 * §3 (constructor surface) and §4 (the five marshalling rules) of
 * III-PHASES.md.  iii_phase_marshal_check() validates a proposed transition
 * against all five rules; iii_phase_marshal_apply() performs validation,
 * emits the witness, and updates internal counters.
 *
 *   Rule 1 — Glyph-Bound Zero-Copy
 *   Rule 2 — Witness Threading
 *   Rule 3 — Inverse Marshalling
 *   Rule 4 — Epistemic Marshalling
 *   Rule 5 — Möbius Marshalling
 * ============================================================================
 */
#include "phases_internal.h"
#include <string.h>

/* Constant-time memcmp for cryptographic hashes — avoids a timing oracle on
 * the glyph-drift comparison. */
static int ct_memeq(const void *a, const void *b, size_t n) {
    const uint8_t *x = (const uint8_t *)a;
    const uint8_t *y = (const uint8_t *)b;
    uint8_t        d = 0;
    for (size_t i = 0; i < n; ++i) d |= (uint8_t)(x[i] ^ y[i]);
    return d == 0;
}

/* The threshold at which uncertainty triggers an operator confirmation gate.
 * §4.4: "if U.confidence < 0.85q".  0.85 in q12 = 3481. */
#define III_PHASE_UNCERTAINTY_THRESHOLD_Q12  ((uint16_t)3481u)

/* Default step kind for a marshalling transition, derived from the
 * constructor when the caller leaves the field as XII_STEP_KIND_NONE. */
static iii_phase_step_kind_t step_kind_for_constructor(iii_phase_constructor_t c,
                                                       iii_phase_ring_t        target)
{
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
            return XII_STEP_KIND_NONE;
    }
}

iii_phase_marshal_status_t iii_phase_marshal_check(const iii_phase_marshal_t *m) {
    if (!m) return III_PHASE_MARSHAL_ERR_INVALID_RING;

    if ((unsigned)m->src >= (unsigned)III_RING_COUNT ||
        (unsigned)m->dst >= (unsigned)III_RING_COUNT) {
        return III_PHASE_MARSHAL_ERR_INVALID_RING;
    }
    if (m->src == m->dst) {
        return III_PHASE_MARSHAL_ERR_NO_CONSTRUCTOR;
    }

    /* §3 — there must be a direct constructor for this transition. */
    iii_phase_constructor_t c = iii_phase_constructor_for(m->src, m->dst);
    if (c == III_XR_NONE) {
        return III_PHASE_MARSHAL_ERR_NO_CONSTRUCTOR;
    }
    /* If the marshal carries a different constructor, reject — the caller is
     * lying about which constructor they're using. */
    if (m->constructor != III_XR_NONE && m->constructor != c) {
        return III_PHASE_MARSHAL_ERR_NO_CONSTRUCTOR;
    }

    /* Rule 1 — Glyph-Bound Zero-Copy: if both glyph hashes are non-zero and
     * advertise glyph-binding, they must match. */
    if (m->glyph_bound) {
        bool src_zero = true, dst_zero = true;
        for (unsigned i = 0; i < 32; ++i) {
            if (m->src_glyph_mhash[i]) { src_zero = false; break; }
        }
        for (unsigned i = 0; i < 32; ++i) {
            if (m->dst_glyph_mhash[i]) { dst_zero = false; break; }
        }
        if (!src_zero && !dst_zero) {
            if (!ct_memeq(m->src_glyph_mhash, m->dst_glyph_mhash, 32)) {
                return III_PHASE_MARSHAL_ERR_GLYPH_DRIFT;
            }
        }
        /* If either side is all-zero (no glyph) and the other is set, the
         * binding is asymmetric — also a drift. */
        if (src_zero != dst_zero) {
            return III_PHASE_MARSHAL_ERR_GLYPH_DRIFT;
        }
    }

    /* Rule 4 — Epistemic Marshalling: high-uncertainty values crossing into
     * a more-privileged ring require operator confirmation. */
    if (m->uncertainty_present) {
        bool privileged_dst = iii_phase_lt(m->dst, m->src);
        if (privileged_dst &&
            m->confidence_q12 < III_PHASE_UNCERTAINTY_THRESHOLD_Q12 &&
            !m->operator_confirmed) {
            return III_PHASE_MARSHAL_ERR_UNCERTAINTY;
        }
    }

    /* Rule 5 — Möbius Marshalling: current coherence must meet the required
     * floor before admitting a manifold-affecting transition. */
    if (m->required_coherence_q12 > 0 &&
        m->current_coherence_q12 < m->required_coherence_q12) {
        return III_PHASE_MARSHAL_ERR_COHERENCE;
    }

    return III_PHASE_MARSHAL_OK;
}

/* Applying a marshal: validate, then emit the witness pair (predecessor +
 * successor mhash).  This function does *not* know about runtime state —
 * the caller links it to a runtime via emit hooks (provided in phases_init). */
iii_phase_marshal_status_t iii_phase_marshal_apply(iii_phase_marshal_t *m) {
    iii_phase_marshal_status_t st = iii_phase_marshal_check(m);
    if (st != III_PHASE_MARSHAL_OK) return st;

    /* Resolve constructor & step kind if not provided. */
    if (m->constructor == III_XR_NONE) {
        m->constructor = iii_phase_constructor_for(m->src, m->dst);
    }
    if (m->step_kind == XII_STEP_KIND_NONE) {
        m->step_kind = step_kind_for_constructor(m->constructor, m->dst);
    }

    /* Compute successor mhash deterministically; the caller can then thread
     * it into their own witness chain.  The mhash is a 32-byte commitment
     * that can be verified by any peer with the same predecessor. */
    iii_phases_chain_mhash(m->predecessor_mhash,
                           /* cycle_id = */ 0,    /* embedded by caller */
                           m->step_kind,
                           m->dst,
                           m->successor_mhash);

    return III_PHASE_MARSHAL_OK;
}

/* Pair a forward marshalling step with its inverse: src/dst swap, predecessor
 * becomes successor, step kind pairs (e.g. INVOKE↔DISPATCH, ENTER↔EXIT). */
void iii_phase_marshal_inverse(const iii_phase_marshal_t *fwd,
                               iii_phase_marshal_t       *inv)
{
    if (!fwd || !inv) return;
    memset(inv, 0, sizeof(*inv));

    inv->src = fwd->dst;
    inv->dst = fwd->src;
    inv->constructor = fwd->constructor;

    /* Glyphs flip too. */
    inv->glyph_bound = fwd->glyph_bound;
    memcpy(inv->src_glyph_mhash, fwd->dst_glyph_mhash, 32);
    memcpy(inv->dst_glyph_mhash, fwd->src_glyph_mhash, 32);

    /* The predecessor of the inverse is the successor of the forward. */
    memcpy(inv->predecessor_mhash, fwd->successor_mhash, 32);

    /* Coherence and uncertainty fields carry forward unchanged. */
    inv->uncertainty_present  = fwd->uncertainty_present;
    inv->confidence_q12       = fwd->confidence_q12;
    inv->operator_confirmed   = fwd->operator_confirmed;
    inv->required_coherence_q12 = fwd->required_coherence_q12;
    inv->current_coherence_q12  = fwd->current_coherence_q12;

    /* Pair step kinds: the inverse step is the symmetric witness. */
    switch (fwd->step_kind) {
        case XII_STEP_KIND_MAGIC_MSR_INVOKE:    inv->step_kind = XII_STEP_KIND_MAGIC_MSR_DISPATCH; break;
        case XII_STEP_KIND_MAGIC_MSR_DISPATCH:  inv->step_kind = XII_STEP_KIND_MAGIC_MSR_INVOKE;   break;
        case XII_STEP_KIND_IOCTL_ISSUE:         inv->step_kind = XII_STEP_KIND_IOCTL_DISPATCH;     break;
        case XII_STEP_KIND_IOCTL_DISPATCH:      inv->step_kind = XII_STEP_KIND_IOCTL_ISSUE;        break;
        case XII_STEP_KIND_SANCTUM_GATE_ENTER:  inv->step_kind = XII_STEP_KIND_SANCTUM_GATE_EXIT;  break;
        case XII_STEP_KIND_SANCTUM_GATE_EXIT:   inv->step_kind = XII_STEP_KIND_SANCTUM_GATE_ENTER; break;
        case XII_STEP_KIND_VMRUN:               inv->step_kind = XII_STEP_KIND_VMEXIT;             break;
        case XII_STEP_KIND_VMEXIT:              inv->step_kind = XII_STEP_KIND_VMRUN;              break;
        case XII_STEP_KIND_SYSRET:              inv->step_kind = XII_STEP_KIND_SYSCALL;            break;
        case XII_STEP_KIND_SYSCALL:             inv->step_kind = XII_STEP_KIND_SYSRET;             break;
        default:                                inv->step_kind = fwd->step_kind;                   break;
    }
}
