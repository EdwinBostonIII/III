/* III-SANDBOX implementation */
#include "iii/sandbox.h"
#include <stdlib.h>
#include <string.h>

extern void iii_sha256(const void *data, size_t len, uint8_t out[32]);

struct iii_sandbox_runtime {
    iii_sandbox_descriptor_t  sandboxes[III_SANDBOX_MAX];
    unsigned                  count;
    iii_sandbox_id_t          next_id;
    uint64_t                  total_witness_count;
};

const char *iii_sandbox_state_name(iii_sandbox_state_t s) {
    switch (s) {
        case III_SBX_CREATED:     return "Created";
        case III_SBX_RUNNING:     return "Running";
        case III_SBX_SUSPENDED:   return "Suspended";
        case III_SBX_SNAPSHOTTED: return "Snapshotted";
        case III_SBX_TERMINATED:  return "Terminated";
        case III_SBX_DISCARDED:   return "Discarded";
        default:                  return "unknown";
    }
}

const char *iii_sbx_status_name(iii_sbx_status_t s) {
    switch (s) {
        case III_SBX_OK:                  return "ok";
        case III_SBX_E_NOT_FOUND:         return "not-found";
        case III_SBX_E_BAD_STATE:         return "bad-state";
        case III_SBX_E_RECURSION_LIMIT:   return "recursion-limit";
        case III_SBX_E_RESOURCE_LIMIT:    return "resource-limit";
        case III_SBX_E_PARENT_INVALID:    return "parent-invalid";
        case III_SBX_E_OOM:               return "oom";
        case III_SBX_E_SNAPSHOT_INVALID:  return "snapshot-invalid";
        case III_SBX_E_FULL:              return "full";
        case III_SBX_E_INVALID:           return "invalid";
        default:                          return "unknown";
    }
}

const char *iii_sbx_witness_kind_name(iii_sbx_witness_kind_t k) {
    switch (k) {
        case III_SBXW_SANDBOX_CREATE:       return "sandbox_create";
        case III_SBXW_SANDBOX_RUN:          return "sandbox_run";
        case III_SBXW_SANDBOX_SUSPEND:      return "sandbox_suspend";
        case III_SBXW_SANDBOX_RESUME:       return "sandbox_resume";
        case III_SBXW_SANDBOX_TERMINATE:    return "sandbox_terminate";
        case III_SBXW_SANDBOX_DISCARD:      return "sandbox_discard";
        case III_SBXW_SANDBOX_SNAPSHOT:     return "sandbox_snapshot";
        case III_SBXW_SANDBOX_RESTORE:      return "sandbox_restore";
        case III_SBXW_SANDBOX_FORK:         return "sandbox_fork";
        case III_SBXW_SANDBOX_DISPATCH:     return "sandbox_dispatch";
        case III_SBXW_SANDBOX_AUDIT_ANCHOR: return "sandbox_audit_anchor";
        default:                            return "unknown";
    }
}

iii_sandbox_runtime_t *iii_sandbox_runtime_create(void) {
    iii_sandbox_runtime_t *rt = (iii_sandbox_runtime_t *)calloc(1, sizeof(*rt));
    return rt;
}

void iii_sandbox_runtime_destroy(iii_sandbox_runtime_t *rt) { if (rt) free(rt); }

size_t iii_sandbox_runtime_count(const iii_sandbox_runtime_t *rt) {
    return rt ? rt->count : 0u;
}

uint64_t iii_sandbox_runtime_witness_count(const iii_sandbox_runtime_t *rt) {
    return rt ? rt->total_witness_count : 0u;
}

static iii_sandbox_descriptor_t *find_mut(iii_sandbox_runtime_t *rt, iii_sandbox_id_t id) {
    if (!rt) return NULL;
    for (unsigned i = 0; i < rt->count; ++i) {
        if (rt->sandboxes[i].sandbox_id == id) return &rt->sandboxes[i];
    }
    return NULL;
}

const iii_sandbox_descriptor_t *iii_sandbox_lookup(const iii_sandbox_runtime_t *rt, iii_sandbox_id_t id) {
    if (!rt) return NULL;
    for (unsigned i = 0; i < rt->count; ++i) {
        if (rt->sandboxes[i].sandbox_id == id) return &rt->sandboxes[i];
    }
    return NULL;
}

iii_sandbox_id_t iii_sandbox_create(iii_sandbox_runtime_t              *rt,
                                    const char                          *name,
                                    iii_sandbox_id_t                    parent,
                                    const iii_sandbox_resource_limits_t *limits)
{
    if (!rt || !name) return 0;
    if (rt->count >= III_SANDBOX_MAX) return 0;

    /* Validate parent exists if non-zero. */
    iii_sandbox_descriptor_t *p = NULL;
    uint32_t depth = 0;
    if (parent) {
        p = find_mut(rt, parent);
        if (!p) return 0;
        depth = p->recursion_depth + 1u;
        if (depth > XII_SANDBOX_MAX_RECURSION_DEPTH) return 0;
        if (p->child_count >= III_SANDBOX_MAX_CHILDREN) return 0;
    }

    iii_sandbox_descriptor_t *s = &rt->sandboxes[rt->count++];
    memset(s, 0, sizeof(*s));
    s->sandbox_id = ++rt->next_id;
    size_t i = 0;
    for (; i < sizeof(s->name) - 1u && name[i]; ++i) s->name[i] = name[i];
    s->name[i] = '\0';
    s->parent = parent;
    s->recursion_depth = depth;
    s->state = III_SBX_CREATED;
    if (limits) s->limits = *limits;

    /* §2.2 — assign isolation. */
    s->isolation.npt_class    = (uint32_t)s->sandbox_id + 100u;
    s->isolation.mpk_key      = (uint32_t)(s->sandbox_id & 0xFu);
    s->isolation.iommu_context= (uint32_t)s->sandbox_id;
    s->isolation.network_mediated     = true;
    s->isolation.filesystem_virtualised = true;
    s->isolation.cap_boundary_sealed  = true;

    /* Audit chain tip starts at zero. */
    /* Witness: SANDBOX_CREATE */
    rt->total_witness_count++;
    s->witness_count++;

    if (p) {
        p->children[p->child_count++] = s->sandbox_id;
    }
    return s->sandbox_id;
}

#define EMIT(rt, s) do { (rt)->total_witness_count++; (s)->witness_count++; } while (0)

iii_sbx_status_t iii_sandbox_run(iii_sandbox_runtime_t *rt, iii_sandbox_id_t id) {
    iii_sandbox_descriptor_t *s = find_mut(rt, id);
    if (!s) return III_SBX_E_NOT_FOUND;
    if (s->state != III_SBX_CREATED && s->state != III_SBX_SUSPENDED) return III_SBX_E_BAD_STATE;
    s->state = III_SBX_RUNNING;
    EMIT(rt, s);
    return III_SBX_OK;
}

iii_sbx_status_t iii_sandbox_suspend(iii_sandbox_runtime_t *rt, iii_sandbox_id_t id) {
    iii_sandbox_descriptor_t *s = find_mut(rt, id);
    if (!s) return III_SBX_E_NOT_FOUND;
    if (s->state != III_SBX_RUNNING) return III_SBX_E_BAD_STATE;
    s->state = III_SBX_SUSPENDED;
    EMIT(rt, s);
    return III_SBX_OK;
}

iii_sbx_status_t iii_sandbox_resume(iii_sandbox_runtime_t *rt, iii_sandbox_id_t id) {
    iii_sandbox_descriptor_t *s = find_mut(rt, id);
    if (!s) return III_SBX_E_NOT_FOUND;
    if (s->state != III_SBX_SUSPENDED && s->state != III_SBX_SNAPSHOTTED) return III_SBX_E_BAD_STATE;
    s->state = III_SBX_RUNNING;
    EMIT(rt, s);
    return III_SBX_OK;
}

iii_sbx_status_t iii_sandbox_terminate(iii_sandbox_runtime_t *rt, iii_sandbox_id_t id) {
    iii_sandbox_descriptor_t *s = find_mut(rt, id);
    if (!s) return III_SBX_E_NOT_FOUND;
    if (s->state == III_SBX_DISCARDED) return III_SBX_E_BAD_STATE;
    s->state = III_SBX_TERMINATED;
    EMIT(rt, s);
    return III_SBX_OK;
}

iii_sbx_status_t iii_sandbox_discard(iii_sandbox_runtime_t *rt, iii_sandbox_id_t id) {
    iii_sandbox_descriptor_t *s = find_mut(rt, id);
    if (!s) return III_SBX_E_NOT_FOUND;
    if (s->state != III_SBX_TERMINATED) return III_SBX_E_BAD_STATE;
    s->state = III_SBX_DISCARDED;
    EMIT(rt, s);
    return III_SBX_OK;
}

iii_sbx_status_t iii_sandbox_snapshot(iii_sandbox_runtime_t *rt,
                                      iii_sandbox_id_t        id,
                                      const uint8_t           memory_image[32],
                                      const uint8_t           cpu_state[32],
                                      const uint8_t           cap_state[32],
                                      const uint8_t           file_state[32],
                                      const uint8_t           network_state[32],
                                      iii_sandbox_snapshot_id_t *out_id)
{
    iii_sandbox_descriptor_t *s = find_mut(rt, id);
    if (!s) return III_SBX_E_NOT_FOUND;
    if (s->snapshot_count >= III_SANDBOX_MAX_SNAPSHOTS) return III_SBX_E_FULL;
    if (s->state != III_SBX_RUNNING && s->state != III_SBX_SUSPENDED) return III_SBX_E_BAD_STATE;

    iii_sandbox_snapshot_t *sn = &s->snapshots[s->snapshot_count++];
    memset(sn, 0, sizeof(*sn));
    sn->id          = ++s->next_snapshot_id;
    sn->sandbox_id  = id;
    sn->timestamp   = (uint64_t)s->snapshot_count;
    if (memory_image)  memcpy(sn->memory_image_mhash,  memory_image, 32);
    if (cpu_state)     memcpy(sn->cpu_state_mhash,     cpu_state,    32);
    if (cap_state)     memcpy(sn->cap_state_mhash,     cap_state,    32);
    if (file_state)    memcpy(sn->file_state_mhash,    file_state,   32);
    if (network_state) memcpy(sn->network_state_mhash, network_state,32);
    memcpy(sn->audit_chain_tip, s->audit_chain_tip, 32);

    /* Composite mhash = SHA-256 over the 5 component hashes + chain tip. */
    uint8_t buf[32 * 6];
    memcpy(buf,         sn->memory_image_mhash,  32);
    memcpy(buf + 32,    sn->cpu_state_mhash,     32);
    memcpy(buf + 64,    sn->cap_state_mhash,     32);
    memcpy(buf + 96,    sn->file_state_mhash,    32);
    memcpy(buf + 128,   sn->network_state_mhash, 32);
    memcpy(buf + 160,   sn->audit_chain_tip,     32);
    iii_sha256(buf, sizeof(buf), sn->composite_mhash);

    /* SNAPSHOT may set state to SNAPSHOTTED — but we model it as additive
     * (the sandbox can keep running after snapshot).  We do not change state. */
    EMIT(rt, s);
    if (out_id) *out_id = sn->id;
    return III_SBX_OK;
}

iii_sbx_status_t iii_sandbox_restore(iii_sandbox_runtime_t *rt,
                                     iii_sandbox_id_t        id,
                                     iii_sandbox_snapshot_id_t snap_id)
{
    iii_sandbox_descriptor_t *s = find_mut(rt, id);
    if (!s) return III_SBX_E_NOT_FOUND;
    iii_sandbox_snapshot_t *sn = NULL;
    for (unsigned i = 0; i < s->snapshot_count; ++i) {
        if (s->snapshots[i].id == snap_id) { sn = &s->snapshots[i]; break; }
    }
    if (!sn) return III_SBX_E_SNAPSHOT_INVALID;
    /* Replace audit chain tip with snapshot's tip + restore witness mhash. */
    memcpy(s->audit_chain_tip, sn->composite_mhash, 32);
    EMIT(rt, s);
    return III_SBX_OK;
}

iii_sbx_status_t iii_sandbox_fork(iii_sandbox_runtime_t      *rt,
                                  iii_sandbox_id_t            id,
                                  iii_sandbox_snapshot_id_t   snap_id,
                                  iii_sandbox_id_t           *out_new_id)
{
    iii_sandbox_descriptor_t *s = find_mut(rt, id);
    if (!s) return III_SBX_E_NOT_FOUND;
    iii_sandbox_snapshot_t *sn = NULL;
    for (unsigned i = 0; i < s->snapshot_count; ++i) {
        if (s->snapshots[i].id == snap_id) { sn = &s->snapshots[i]; break; }
    }
    if (!sn) return III_SBX_E_SNAPSHOT_INVALID;

    char fork_name[III_SANDBOX_MAX_NAME];
    /* Build "<name>-fork-<snap_id>" */
    size_t pos = 0;
    for (size_t j = 0; pos < sizeof(fork_name) - 1u && s->name[j]; ++j, ++pos) fork_name[pos] = s->name[j];
    const char *suffix = "-fork-";
    for (size_t j = 0; pos < sizeof(fork_name) - 1u && suffix[j]; ++j, ++pos) fork_name[pos] = suffix[j];
    /* append snap_id as decimal */
    char tmp[24]; int tlen = 0;
    uint64_t v = snap_id;
    if (v == 0) { tmp[tlen++] = '0'; }
    else { char rev[24]; int rl = 0; while (v) { rev[rl++] = (char)('0' + (v % 10u)); v /= 10u; } while (rl) tmp[tlen++] = rev[--rl]; }
    for (int j = 0; pos < sizeof(fork_name) - 1u && j < tlen; ++j, ++pos) fork_name[pos] = tmp[j];
    fork_name[pos] = '\0';

    iii_sandbox_id_t new_id = iii_sandbox_create(rt, fork_name, s->parent, &s->limits);
    if (new_id == 0) return III_SBX_E_FULL;
    iii_sandbox_descriptor_t *nn = find_mut(rt, new_id);
    nn->counterfactual = true;
    nn->forked_from = id;
    /* Copy snapshot composite into the new sandbox's audit chain tip. */
    memcpy(nn->audit_chain_tip, sn->composite_mhash, 32);
    EMIT(rt, nn);
    if (out_new_id) *out_new_id = new_id;
    return III_SBX_OK;
}

iii_sbx_status_t iii_sandbox_dispatch(iii_sandbox_runtime_t *rt,
                                      iii_sandbox_id_t        id,
                                      uint16_t                cycle_kind,
                                      uint8_t                 out_witness_mhash[32])
{
    iii_sandbox_descriptor_t *s = find_mut(rt, id);
    if (!s) return III_SBX_E_NOT_FOUND;
    if (s->state != III_SBX_RUNNING) return III_SBX_E_BAD_STATE;

    /* Compute a deterministic witness mhash chained into the sandbox's audit. */
    uint8_t buf[32 + 8 + 2];
    memcpy(buf, s->audit_chain_tip, 32);
    for (unsigned i = 0; i < 8; ++i) buf[32 + i] = (uint8_t)(s->witness_count >> (i * 8));
    buf[40] = (uint8_t)cycle_kind;
    buf[41] = (uint8_t)(cycle_kind >> 8);
    iii_sha256(buf, sizeof(buf), s->audit_chain_tip);
    if (out_witness_mhash) memcpy(out_witness_mhash, s->audit_chain_tip, 32);
    EMIT(rt, s);
    return III_SBX_OK;
}

iii_sbx_status_t iii_sandbox_anchor_audit(iii_sandbox_runtime_t *rt,
                                          iii_sandbox_id_t        id)
{
    iii_sandbox_descriptor_t *s = find_mut(rt, id);
    if (!s) return III_SBX_E_NOT_FOUND;
    if (!s->parent) return III_SBX_OK;     /* nothing to anchor */
    iii_sandbox_descriptor_t *p = find_mut(rt, s->parent);
    if (!p) return III_SBX_E_PARENT_INVALID;

    uint8_t buf[32 + 32];
    memcpy(buf,    p->audit_chain_tip, 32);
    memcpy(buf+32, s->audit_chain_tip, 32);
    iii_sha256(buf, sizeof(buf), p->audit_chain_tip);
    EMIT(rt, p);
    return III_SBX_OK;
}

iii_sbx_status_t iii_sandbox_propagate_compromise(iii_sandbox_runtime_t *rt,
                                                  iii_sandbox_id_t        id)
{
    iii_sandbox_descriptor_t *s = find_mut(rt, id);
    if (!s) return III_SBX_E_NOT_FOUND;
    s->compromise_propagated = true;
    if (s->parent) {
        iii_sandbox_descriptor_t *p = find_mut(rt, s->parent);
        if (p) p->compromise_propagated = true;
    }
    EMIT(rt, s);
    return III_SBX_OK;
}
