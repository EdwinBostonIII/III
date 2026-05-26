/* ============================================================================
 * III-PHASES — runtime.c
 *
 * Runtime lifecycle and witness-ring accessors.  The runtime is allocated as
 * a single large structure (~few MB) so it can be statically embedded in a
 * kernel/hypervisor image without dynamic allocation if desired; the heap-
 * allocated path here is for tooling and tests only.
 * ============================================================================
 */
#include "phases_internal.h"
#include <stdlib.h>
#include <string.h>

iii_phase_runtime_t *iii_phase_runtime_create(void) {
    iii_phase_runtime_t *rt = (iii_phase_runtime_t *)calloc(1, sizeof(*rt));
    if (!rt) return NULL;
    rt->current_ring = III_RING_USER; /* default — we boot from user mode */
    return rt;
}

void iii_phase_runtime_destroy(iii_phase_runtime_t *rt) {
    if (!rt) return;
    /* Zero before free — witness data is forensically sensitive. */
    memset(rt, 0, sizeof(*rt));
    free(rt);
}

uint64_t iii_phase_runtime_witness_count(const iii_phase_runtime_t *rt) {
    return rt ? rt->witness_seq : 0u;
}

bool iii_phase_runtime_witness_at(const iii_phase_runtime_t *rt,
                                  uint64_t                   idx,
                                  iii_phase_witness_t       *out)
{
    if (!rt || !out) return false;
    if (idx == 0u || idx > rt->witness_seq) return false;

    /* The ring buffer holds the last N witnesses.  If idx is older than the
     * earliest preserved one (witness_seq - N), it has been overwritten. */
    uint64_t earliest = (rt->witness_seq > III_PHASES_MAX_WITNESSES)
                         ? rt->witness_seq - III_PHASES_MAX_WITNESSES
                         : 0u;
    if (idx <= earliest) return false;

    /* Slot mapping: witness_head holds the next slot to write; the witness
     * with seq = witness_seq lives at slot (witness_head - 1) mod N. */
    uint64_t slot;
    uint64_t age = rt->witness_seq - idx;        /* 0 = newest */
    if (rt->witness_head == 0) {
        slot = (III_PHASES_MAX_WITNESSES - 1u - age) % III_PHASES_MAX_WITNESSES;
    } else {
        slot = (rt->witness_head + III_PHASES_MAX_WITNESSES - 1u - age)
               % III_PHASES_MAX_WITNESSES;
    }

    *out = rt->witnesses[slot];
    return true;
}
