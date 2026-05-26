/* ============================================================================
 * III-PHASES — ring_lattice.c
 *
 * §1 of III-PHASES.md.  The four-element privilege lattice:
 *
 *      R-2 (Sanctum)   ≼   R-1 (Hypervisor)   ≼   R0 (Driver)   ≼   R3 (User)
 *
 * Privilege flows downward in the diagram (R-2 most privileged); the lattice
 * order ≼ matches the integer order on our enum encoding (R-2=0, R3=3) so
 * that "a ≼ b" is implemented as the integer "a ≤ b".
 *
 * Phase-set operations are implemented over a 4-bit bitmap.
 * ============================================================================
 */
#include "phases_internal.h"
#include <string.h>

/* ----------------------------------------------------------------------------
 * Phase-set primitives
 * ---------------------------------------------------------------------------- */

iii_phase_set_t iii_phase_set_singleton(iii_phase_ring_t r) {
    return III_PHASE_SET_BIT(r);
}

iii_phase_set_t iii_phase_set_pair(iii_phase_ring_t a, iii_phase_ring_t b) {
    return (iii_phase_set_t)(III_PHASE_SET_BIT(a) | III_PHASE_SET_BIT(b));
}

iii_phase_set_t iii_phase_set_add(iii_phase_set_t s, iii_phase_ring_t r) {
    return (iii_phase_set_t)(s | III_PHASE_SET_BIT(r));
}

iii_phase_set_t iii_phase_set_remove(iii_phase_set_t s, iii_phase_ring_t r) {
    return (iii_phase_set_t)(s & (iii_phase_set_t)~III_PHASE_SET_BIT(r));
}

iii_phase_set_t iii_phase_set_union(iii_phase_set_t a, iii_phase_set_t b) {
    return (iii_phase_set_t)(a | b);
}

iii_phase_set_t iii_phase_set_intersect(iii_phase_set_t a, iii_phase_set_t b) {
    return (iii_phase_set_t)(a & b);
}

iii_phase_set_t iii_phase_set_difference(iii_phase_set_t a, iii_phase_set_t b) {
    return (iii_phase_set_t)(a & (iii_phase_set_t)~b);
}

bool iii_phase_set_contains(iii_phase_set_t s, iii_phase_ring_t r) {
    return (s & III_PHASE_SET_BIT(r)) != 0u;
}

bool iii_phase_set_is_empty(iii_phase_set_t s) {
    return (s & III_PHASE_SET_ALL) == 0u;
}

bool iii_phase_set_equal(iii_phase_set_t a, iii_phase_set_t b) {
    return (iii_phase_set_t)(a & III_PHASE_SET_ALL) ==
           (iii_phase_set_t)(b & III_PHASE_SET_ALL);
}

bool iii_phase_set_subset(iii_phase_set_t a, iii_phase_set_t b) {
    return (iii_phase_set_t)(a & ~b & III_PHASE_SET_ALL) == 0u;
}

unsigned iii_phase_set_cardinality(iii_phase_set_t s) {
    /* Branchless 4-bit popcount via the standard lookup. */
    static const uint8_t popcount4[16] = {
        0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4
    };
    return popcount4[s & 0x0Fu];
}

iii_phase_ring_t iii_phase_set_min(iii_phase_set_t s) {
    /* Lowest set bit = most privileged ring (R-2 = 0). */
    if (s & 0x01u) return III_RING_SANCTUM;
    if (s & 0x02u) return III_RING_HYPERVISOR;
    if (s & 0x04u) return III_RING_KERNEL;
    return III_RING_USER;
}

iii_phase_ring_t iii_phase_set_max(iii_phase_set_t s) {
    /* Highest set bit = least privileged. */
    if (s & 0x08u) return III_RING_USER;
    if (s & 0x04u) return III_RING_KERNEL;
    if (s & 0x02u) return III_RING_HYPERVISOR;
    return III_RING_SANCTUM;
}

/* ----------------------------------------------------------------------------
 * Lattice
 * ---------------------------------------------------------------------------- */

bool iii_phase_leq(iii_phase_ring_t a, iii_phase_ring_t b) {
    return (unsigned)a <= (unsigned)b;
}

bool iii_phase_lt(iii_phase_ring_t a, iii_phase_ring_t b) {
    return (unsigned)a <  (unsigned)b;
}

iii_phase_ring_t iii_phase_meet(iii_phase_ring_t a, iii_phase_ring_t b) {
    /* Greatest lower bound = the more-privileged of the two (lower index). */
    return ((unsigned)a < (unsigned)b) ? a : b;
}

iii_phase_ring_t iii_phase_join(iii_phase_ring_t a, iii_phase_ring_t b) {
    /* Least upper bound = the less-privileged (higher index). */
    return ((unsigned)a > (unsigned)b) ? a : b;
}

bool iii_phase_adjacent(iii_phase_ring_t a, iii_phase_ring_t b) {
    int diff = (int)a - (int)b;
    return (diff == 1) || (diff == -1);
}

/* ----------------------------------------------------------------------------
 * Names
 * ---------------------------------------------------------------------------- */

const char *iii_phase_ring_name(iii_phase_ring_t r) {
    switch (r) {
        case III_RING_SANCTUM:    return "R-2";
        case III_RING_HYPERVISOR: return "R-1";
        case III_RING_KERNEL:     return "R0";
        case III_RING_USER:       return "R3";
        default:                  return "R?";
    }
}

const char *iii_phase_ring_long_name(iii_phase_ring_t r) {
    switch (r) {
        case III_RING_SANCTUM:    return "Sanctum";
        case III_RING_HYPERVISOR: return "Hypervisor";
        case III_RING_KERNEL:     return "Kernel";
        case III_RING_USER:       return "User";
        default:                  return "Unknown";
    }
}

size_t iii_phase_set_format(iii_phase_set_t s, char *buf, size_t cap) {
    /* Produces "{R-2,R-1,R0,R3}" or "{}" form, deterministic order most→least
     * privileged.  Returns total bytes that would have been written (not
     * counting NUL).  Truncates safely if cap is small. */
    if (cap == 0) return 0;
    size_t   out  = 0;
    char    *p    = buf;
    size_t   left = cap;

    #define EMIT_CH(ch) do {                          \
        if (left > 1) { *p++ = (char)(ch); --left; }  \
        ++out;                                        \
    } while (0)

    EMIT_CH('{');

    bool first = true;
    static const iii_phase_ring_t order[4] = {
        III_RING_SANCTUM, III_RING_HYPERVISOR, III_RING_KERNEL, III_RING_USER
    };
    for (unsigned i = 0; i < 4; ++i) {
        iii_phase_ring_t r = order[i];
        if (!iii_phase_set_contains(s, r)) continue;
        if (!first) EMIT_CH(',');
        first = false;
        const char *nm = iii_phase_ring_name(r);
        for (const char *c = nm; *c; ++c) EMIT_CH(*c);
    }

    EMIT_CH('}');

    if (cap > 0) {
        size_t z = (out < cap) ? out : (cap - 1);
        buf[z] = '\0';
    }

    #undef EMIT_CH
    return out;
}

/* ----------------------------------------------------------------------------
 * Cross-ring constructor table — §3.6.
 *
 *   R3 ↔ R-1   :  Magic-MSR
 *   R3 ↔ R0    :  IOCTL  (also legacy SYSRET — we surface the modern one)
 *   R0 ↔ R-1   :  VMRUN-trampoline
 *   R-1 ↔ R-2  :  Sanctum-Gate
 *
 * Anything else (e.g. R3 ↔ R-2, R0 ↔ R-2) is *not* directly connected — the
 * caller must compose constructors via next-hop traversal.
 *
 * Symmetric: src ↔ dst yields the same constructor as dst ↔ src.
 * ---------------------------------------------------------------------------- */

iii_phase_constructor_t iii_phase_constructor_for(iii_phase_ring_t src,
                                                  iii_phase_ring_t dst)
{
    if (src == dst) return III_XR_NONE;

    iii_phase_ring_t lo = iii_phase_meet(src, dst);
    iii_phase_ring_t hi = iii_phase_join(src, dst);

    /* Direct adjacencies in the lattice. */
    if (lo == III_RING_SANCTUM    && hi == III_RING_HYPERVISOR) return III_XR_SANCTUM_GATE;
    if (lo == III_RING_HYPERVISOR && hi == III_RING_KERNEL)     return III_XR_VMRUN;
    if (lo == III_RING_KERNEL     && hi == III_RING_USER)       return III_XR_IOCTL;
    /* §3.1 — Magic-MSR is a non-adjacent direct constructor (R3 ↔ R-1). */
    if (lo == III_RING_HYPERVISOR && hi == III_RING_USER)       return III_XR_MAGIC_MSR;

    return III_XR_NONE;
}

bool iii_phase_directly_connected(iii_phase_ring_t a, iii_phase_ring_t b) {
    return iii_phase_constructor_for(a, b) != III_XR_NONE;
}

iii_phase_ring_t iii_phase_next_hop(iii_phase_ring_t src, iii_phase_ring_t dst) {
    if (src == dst) return src;
    if (iii_phase_directly_connected(src, dst)) return dst;

    /* The only non-direct pairs are R3↔R-2 and R0↔R-2.
     * R3 ↔ R-2: hop via R-1 (Magic-MSR then Sanctum-Gate).
     * R0 ↔ R-2: hop via R-1 (VMRUN then Sanctum-Gate). */
    if (src == III_RING_USER   && dst == III_RING_SANCTUM)    return III_RING_HYPERVISOR;
    if (src == III_RING_KERNEL && dst == III_RING_SANCTUM)    return III_RING_HYPERVISOR;
    if (src == III_RING_SANCTUM && dst == III_RING_USER)      return III_RING_HYPERVISOR;
    if (src == III_RING_SANCTUM && dst == III_RING_KERNEL)    return III_RING_HYPERVISOR;

    /* Default: step toward the destination by one ring. */
    if ((unsigned)src < (unsigned)dst) return (iii_phase_ring_t)((unsigned)src + 1u);
    return (iii_phase_ring_t)((unsigned)src - 1u);
}

unsigned iii_phase_chain_length(iii_phase_ring_t src, iii_phase_ring_t dst) {
    if (src == dst) return 0;
    if (iii_phase_directly_connected(src, dst)) return 1u;
    /* The lattice is small enough that any indirect pair takes exactly 2 hops. */
    return 2u;
}

const char *iii_phase_constructor_name(iii_phase_constructor_t c) {
    switch (c) {
        case III_XR_NONE:           return "none";
        case III_XR_MAGIC_MSR:      return "magic-msr";
        case III_XR_IOCTL:          return "ioctl";
        case III_XR_SANCTUM_GATE:   return "sanctum-gate";
        case III_XR_VMRUN:          return "vmrun";
        case III_XR_SYSRET:         return "sysret";
        default:                    return "unknown";
    }
}

const char *iii_phase_step_kind_name(iii_phase_step_kind_t k) {
    switch (k) {
        case XII_STEP_KIND_NONE:                  return "none";
        case XII_STEP_KIND_MAGIC_MSR_INVOKE:      return "magic-msr-invoke";
        case XII_STEP_KIND_MAGIC_MSR_DISPATCH:    return "magic-msr-dispatch";
        case XII_STEP_KIND_MAGIC_MSR_PROMOTE:     return "magic-msr-promote";
        case XII_STEP_KIND_IOCTL_ISSUE:           return "ioctl-issue";
        case XII_STEP_KIND_IOCTL_DISPATCH:        return "ioctl-dispatch";
        case XII_STEP_KIND_SANCTUM_INTENT_MINT:   return "sanctum-intent-mint";
        case XII_STEP_KIND_SANCTUM_GATE_ENTER:    return "sanctum-gate-enter";
        case XII_STEP_KIND_SANCTUM_PKRU_REWRITE:  return "sanctum-pkru-rewrite";
        case XII_STEP_KIND_SANCTUM_DISPATCH:      return "sanctum-dispatch";
        case XII_STEP_KIND_SANCTUM_BODY:          return "sanctum-body";
        case XII_STEP_KIND_SANCTUM_GATE_EXIT:     return "sanctum-gate-exit";
        case XII_STEP_KIND_SANCTUM_MSR_READ:      return "sanctum-msr-read";
        case XII_STEP_KIND_VMRUN:                 return "vmrun";
        case XII_STEP_KIND_VMEXIT:                return "vmexit";
        case XII_STEP_KIND_SYSRET:                return "sysret";
        case XII_STEP_KIND_SYSCALL:               return "syscall";
        case XII_STEP_KIND_R0_MSR_READ:           return "r0-msr-read";
        case XII_STEP_KIND_R3_MAGIC_MSR_READ:     return "r3-magic-msr-read";
        case XII_STEP_KIND_IRPD_MSR_READ:         return "irpd-msr-read";
        case XII_STEP_KIND_PHASE_PROMOTE:         return "phase-promote";
        case XII_STEP_KIND_PHASE_DEMOTE:          return "phase-demote";
        case XII_STEP_KIND_GHOST_OBSERVE:         return "ghost-observe";
        case XII_STEP_KIND_PIP_SPECIALIZE:        return "pip-specialize";
        case XII_STEP_KIND_PIP_DESPECIALIZE:      return "pip-despecialize";
        default:                                  return "unknown";
    }
}

const char *iii_phase_marshal_status_name(iii_phase_marshal_status_t s) {
    switch (s) {
        case III_PHASE_MARSHAL_OK:                  return "ok";
        case III_PHASE_MARSHAL_ERR_NO_CONSTRUCTOR:  return "no-constructor";
        case III_PHASE_MARSHAL_ERR_GLYPH_DRIFT:     return "glyph-drift";
        case III_PHASE_MARSHAL_ERR_UNCERTAINTY:     return "uncertainty-gate";
        case III_PHASE_MARSHAL_ERR_COHERENCE:       return "coherence-below-floor";
        case III_PHASE_MARSHAL_ERR_INVALID_RING:    return "invalid-ring";
        case III_PHASE_MARSHAL_ERR_RATE_CAP:        return "rate-cap";
        default:                                    return "unknown";
    }
}

const char *iii_phase_promote_status_name(iii_phase_promote_status_t s) {
    switch (s) {
        case III_PHASE_PROMOTE_OK:                   return "ok";
        case III_PHASE_PROMOTE_ERR_NOT_CANDIDATE:    return "not-candidate";
        case III_PHASE_PROMOTE_ERR_HEXAD_REJECT:     return "hexad-reject";
        case III_PHASE_PROMOTE_ERR_TRINITY_REJECT:   return "trinity-reject";
        case III_PHASE_PROMOTE_ERR_COHERENCE:        return "coherence-below-floor";
        case III_PHASE_PROMOTE_ERR_RATE_CAP:         return "rate-cap";
        case III_PHASE_PROMOTE_ERR_ALREADY_AT_RING:  return "already-at-ring";
        case III_PHASE_PROMOTE_ERR_INVALID:          return "invalid";
        default:                                     return "unknown";
    }
}

const char *iii_phase_err_name(iii_phase_err_t e) {
    switch (e) {
        case III_PHASE_OK:                          return "ok";
        case III_PHASE_E_TYPE_RING_001:             return "TYPE-RING-001 no marshalling constructor";
        case III_PHASE_E_PANIC_GLYPH_DRIFT:         return "PANIC-GLYPH-DRIFT";
        case III_PHASE_E_RUNTIME_MARSHALL_001:      return "RUNTIME-MARSHALL-001 coherence below threshold";
        case III_PHASE_E_INVARIANT:                 return "invariant-violation";
        case III_PHASE_E_UNDECLARED_RING:           return "undeclared-ring";
        case III_PHASE_E_SEALED:                    return "cycle-sealed";
        case III_PHASE_E_RATE_CAP:                  return "rate-cap-exceeded";
        case III_PHASE_E_OOM:                       return "out-of-memory";
        default:                                    return "unknown";
    }
}
