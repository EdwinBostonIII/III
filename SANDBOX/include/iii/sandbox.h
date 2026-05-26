/* ============================================================================
 * III-SANDBOX — Perfect Sandbox primitive
 * Spec: III-SANDBOX.md  (Wave 10.1, items 86-90)
 *
 * A sandbox is a first-class substrate type providing total isolation,
 * total observation, total reproducibility, total reversibility, and total
 * decomposability for any computation hosted within.  This module implements
 * the bookkeeping: lifecycle state machine, isolation flags, snapshot/restore,
 * fork (counterfactual branch), parent-child anchoring, and witness emission.
 * ============================================================================
 */
#ifndef III_SANDBOX_H
#define III_SANDBOX_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ----------------------------------------------------------------------------
 * §6.4 — recursion limit.
 * ---------------------------------------------------------------------------- */
#define XII_SANDBOX_MAX_RECURSION_DEPTH  16u
#define III_SANDBOX_MAX                  256u
#define III_SANDBOX_MAX_SNAPSHOTS        64u
#define III_SANDBOX_MAX_NAME             64u
#define III_SANDBOX_MAX_CHILDREN         32u

/* ----------------------------------------------------------------------------
 * §1.3 — lifecycle states.
 * ---------------------------------------------------------------------------- */
typedef enum iii_sandbox_state {
    III_SBX_CREATED      = 0,
    III_SBX_RUNNING      = 1,
    III_SBX_SUSPENDED    = 2,
    III_SBX_SNAPSHOTTED  = 3,
    III_SBX_TERMINATED   = 4,
    III_SBX_DISCARDED    = 5
} iii_sandbox_state_t;

const char *iii_sandbox_state_name(iii_sandbox_state_t s);

/* ----------------------------------------------------------------------------
 * §1.1 — sandbox identity + resource limits.
 * ---------------------------------------------------------------------------- */
typedef uint64_t iii_sandbox_id_t;
typedef uint64_t iii_sandbox_snapshot_id_t;

typedef struct iii_sandbox_resource_limits {
    uint64_t memory_bytes_max;
    uint32_t cpu_threads_max;
    uint32_t fd_max;
    uint32_t network_caps_max;
    uint32_t snapshot_max;
    uint32_t recursion_depth;
} iii_sandbox_resource_limits_t;

/* §2.2 — NPT-class + MPK-key per sandbox. */
typedef struct iii_sandbox_isolation {
    uint32_t npt_class;
    uint32_t mpk_key;            /* 0..15 */
    uint32_t iommu_context;
    bool     network_mediated;
    bool     filesystem_virtualised;
    bool     cap_boundary_sealed;
} iii_sandbox_isolation_t;

/* ----------------------------------------------------------------------------
 * §3.2 — snapshot.
 * ---------------------------------------------------------------------------- */
typedef struct iii_sandbox_snapshot {
    iii_sandbox_snapshot_id_t  id;
    iii_sandbox_id_t           sandbox_id;
    uint64_t                   timestamp;
    uint8_t                    memory_image_mhash[32];
    uint8_t                    cpu_state_mhash[32];
    uint8_t                    cap_state_mhash[32];
    uint8_t                    file_state_mhash[32];
    uint8_t                    network_state_mhash[32];
    uint8_t                    audit_chain_tip[32];
    uint8_t                    composite_mhash[32];   /* SHA-256 of the above */
} iii_sandbox_snapshot_t;

/* ----------------------------------------------------------------------------
 * §1.1 — sandbox descriptor.
 * ---------------------------------------------------------------------------- */
typedef struct iii_sandbox_descriptor {
    iii_sandbox_id_t                sandbox_id;
    char                            name[III_SANDBOX_MAX_NAME];
    iii_sandbox_id_t                parent;            /* 0 if none */
    iii_sandbox_id_t                children[III_SANDBOX_MAX_CHILDREN];
    unsigned                        child_count;
    uint32_t                        recursion_depth;

    iii_sandbox_state_t             state;
    iii_sandbox_isolation_t         isolation;
    iii_sandbox_resource_limits_t   limits;

    iii_sandbox_snapshot_t          snapshots[III_SANDBOX_MAX_SNAPSHOTS];
    unsigned                        snapshot_count;
    iii_sandbox_snapshot_id_t       next_snapshot_id;

    /* Audit chain tip — anchor witness mhash for parent's chain. */
    uint8_t                         audit_chain_tip[32];
    uint64_t                        witness_count;

    /* Whether this sandbox is a counterfactual fork (different audit treatment) */
    bool                            counterfactual;
    iii_sandbox_id_t                forked_from;       /* original if counterfactual */

    /* Compromise propagation — set when a child reports a compromise */
    bool                            compromise_propagated;
} iii_sandbox_descriptor_t;

/* ----------------------------------------------------------------------------
 * §5.2 — witness flags for sandbox-emitted witnesses.
 * ---------------------------------------------------------------------------- */
#define III_SBX_FLAG_FROM_SANDBOX           (1u << 16)
#define III_SBX_FLAG_NESTED                 (1u << 17)
#define III_SBX_FLAG_RESTORED               (1u << 18)
#define III_SBX_FLAG_COUNTERFACTUAL         (1u << 19)
#define III_SBX_FLAG_AUDIT_ANCHOR           (1u << 20)

typedef enum iii_sbx_witness_kind {
    III_SBXW_NONE              = 0,
    III_SBXW_SANDBOX_CREATE    = 0x0A01,
    III_SBXW_SANDBOX_RUN       = 0x0A02,
    III_SBXW_SANDBOX_SUSPEND   = 0x0A03,
    III_SBXW_SANDBOX_RESUME    = 0x0A04,
    III_SBXW_SANDBOX_TERMINATE = 0x0A05,
    III_SBXW_SANDBOX_DISCARD   = 0x0A06,
    III_SBXW_SANDBOX_SNAPSHOT  = 0x0A07,
    III_SBXW_SANDBOX_RESTORE   = 0x0A08,
    III_SBXW_SANDBOX_FORK      = 0x0A09,
    III_SBXW_SANDBOX_DISPATCH  = 0x0A0A,
    III_SBXW_SANDBOX_AUDIT_ANCHOR = 0x0A0B
} iii_sbx_witness_kind_t;

const char *iii_sbx_witness_kind_name(iii_sbx_witness_kind_t k);

/* ----------------------------------------------------------------------------
 * Runtime
 * ---------------------------------------------------------------------------- */

typedef struct iii_sandbox_runtime iii_sandbox_runtime_t;

iii_sandbox_runtime_t *iii_sandbox_runtime_create(void);
void iii_sandbox_runtime_destroy(iii_sandbox_runtime_t *rt);

/* §1.2 — lifecycle */
iii_sandbox_id_t iii_sandbox_create(iii_sandbox_runtime_t              *rt,
                                    const char                          *name,
                                    iii_sandbox_id_t                    parent,
                                    const iii_sandbox_resource_limits_t *limits);

typedef enum iii_sbx_status {
    III_SBX_OK                           = 0,
    III_SBX_E_NOT_FOUND                  = 1,
    III_SBX_E_BAD_STATE                  = 2,
    III_SBX_E_RECURSION_LIMIT            = 3,
    III_SBX_E_RESOURCE_LIMIT             = 4,
    III_SBX_E_PARENT_INVALID             = 5,
    III_SBX_E_OOM                        = 6,
    III_SBX_E_SNAPSHOT_INVALID           = 7,
    III_SBX_E_FULL                       = 8,
    III_SBX_E_INVALID                    = 9
} iii_sbx_status_t;

const char *iii_sbx_status_name(iii_sbx_status_t s);

iii_sbx_status_t iii_sandbox_run(iii_sandbox_runtime_t *rt, iii_sandbox_id_t id);
iii_sbx_status_t iii_sandbox_suspend(iii_sandbox_runtime_t *rt, iii_sandbox_id_t id);
iii_sbx_status_t iii_sandbox_resume(iii_sandbox_runtime_t *rt, iii_sandbox_id_t id);
iii_sbx_status_t iii_sandbox_terminate(iii_sandbox_runtime_t *rt, iii_sandbox_id_t id);
iii_sbx_status_t iii_sandbox_discard(iii_sandbox_runtime_t *rt, iii_sandbox_id_t id);

/* §3 — snapshots. */
iii_sbx_status_t iii_sandbox_snapshot(iii_sandbox_runtime_t *rt,
                                      iii_sandbox_id_t        id,
                                      const uint8_t           memory_image[32],
                                      const uint8_t           cpu_state[32],
                                      const uint8_t           cap_state[32],
                                      const uint8_t           file_state[32],
                                      const uint8_t           network_state[32],
                                      iii_sandbox_snapshot_id_t *out_id);

iii_sbx_status_t iii_sandbox_restore(iii_sandbox_runtime_t *rt,
                                     iii_sandbox_id_t        id,
                                     iii_sandbox_snapshot_id_t snap_id);

iii_sbx_status_t iii_sandbox_fork(iii_sandbox_runtime_t      *rt,
                                  iii_sandbox_id_t            id,
                                  iii_sandbox_snapshot_id_t   snap_id,
                                  iii_sandbox_id_t           *out_new_id);

const iii_sandbox_descriptor_t *iii_sandbox_lookup(const iii_sandbox_runtime_t *rt,
                                                   iii_sandbox_id_t              id);

size_t iii_sandbox_runtime_count(const iii_sandbox_runtime_t *rt);

/* §4 — sandbox-as-cycle-host: dispatch a cycle inside the sandbox. */
iii_sbx_status_t iii_sandbox_dispatch(iii_sandbox_runtime_t *rt,
                                      iii_sandbox_id_t        id,
                                      uint16_t                cycle_kind,
                                      uint8_t                 out_witness_mhash[32]);

/* §4.4 — anchor sandbox audit chain into parent. */
iii_sbx_status_t iii_sandbox_anchor_audit(iii_sandbox_runtime_t *rt,
                                          iii_sandbox_id_t        id);

/* §5.5 — propagate a compromise from this sandbox upward. */
iii_sbx_status_t iii_sandbox_propagate_compromise(iii_sandbox_runtime_t *rt,
                                                  iii_sandbox_id_t        id);

/* Total witness count emitted across all sandboxes in this runtime. */
uint64_t iii_sandbox_runtime_witness_count(const iii_sandbox_runtime_t *rt);

#ifdef __cplusplus
}
#endif

#endif /* III_SANDBOX_H */
