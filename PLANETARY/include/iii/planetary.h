/* ============================================================================
 * III-PLANETARY — Planetary-Scale Federation
 * Spec: III-PLANETARY.md  (Wave 9, items 79-85)
 *
 *   §1 — hierarchical federation tier (cells / districts / regions / substrate)
 *   §2 — attacker-peer detection (six signal kinds)
 *   §3 — peer isolation / quarantine
 *   §4 — Sybil resistance (DRTM-rooted identity + admission cost)
 *   §5 — eclipse-attack resistance (multi-path routing)
 *   §6 — network-partition recovery
 *   §7 — planetary witness chain reconciliation
 * ============================================================================
 */
#ifndef III_PLANETARY_H
#define III_PLANETARY_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* §1.2 — hierarchy */
typedef enum iii_pl_level {
    III_PL_CELL      = 0,
    III_PL_DISTRICT  = 1,
    III_PL_REGION    = 2,
    III_PL_SUBSTRATE = 3
} iii_pl_level_t;

const char *iii_pl_level_name(iii_pl_level_t l);

/* Each cell ~1000 peers; each district ~1000 cells; each region ~1000 districts.
 * The hierarchy is closure-pinned. */
#define III_PL_CELL_SIZE       1024u
#define III_PL_PEERS_MAX       4096u
#define III_PL_CELL_MAX         16u
#define III_PL_DISTRICT_MAX     8u
#define III_PL_REGION_MAX       4u

typedef uint64_t iii_pl_peer_id_t;
typedef uint64_t iii_pl_cell_id_t;
typedef uint64_t iii_pl_district_id_t;
typedef uint64_t iii_pl_region_id_t;

/* §1 — peer descriptor */
typedef struct iii_pl_peer {
    iii_pl_peer_id_t       peer_id;
    iii_pl_cell_id_t       cell;
    iii_pl_district_id_t   district;
    iii_pl_region_id_t     region;
    uint8_t                silicon_fp[32];
    uint8_t                drtm_attestation[32];
    uint64_t               last_seen;
    bool                   live;
    bool                   quarantined;
    bool                   leader;             /* current leader of its cell/district/region */
    /* Anomaly / attack tracking */
    uint32_t               attack_signal_count;
    uint64_t               last_emission_rate;
    uint64_t               baseline_emission_rate;
    uint8_t                closure_root[32];
    uint16_t               active_suite;
} iii_pl_peer_t;

/* §2 — attack signal kinds */
typedef enum iii_pl_attack_kind {
    III_PA_NONE                          = 0,
    III_PA_WITNESS_INTEGRITY_VIOLATION   = 1,
    III_PA_BURST_EMISSION                = 2,
    III_PA_ANCHOR_ATTACK_PATTERN         = 3,
    III_PA_CROSS_PEER_DIVERGENCE         = 4,
    III_PA_SUITE_REGRESSION              = 5,
    III_PA_CLOSURE_ROOT_DIVERGENCE       = 6
} iii_pl_attack_kind_t;

const char *iii_pl_attack_kind_name(iii_pl_attack_kind_t k);

typedef enum iii_pl_severity {
    III_PS_LOW    = 0,
    III_PS_MEDIUM = 1,
    III_PS_HIGH   = 2
} iii_pl_severity_t;

#define III_PL_BURST_THRESHOLD_MULTIPLIER  10u
#define III_PL_ANCHOR_ATTACK_THRESHOLD     3u
#define III_PL_DIVERGENCE_THRESHOLD_Q14    8192u

typedef struct iii_pl_attack_signal {
    iii_pl_attack_kind_t kind;
    iii_pl_peer_id_t     target;
    iii_pl_peer_id_t     detector;
    iii_pl_severity_t    severity;
    uint8_t              evidence_mhash[32];
} iii_pl_attack_signal_t;

/* §3 — quarantine state */
typedef enum iii_pl_quarantine_status {
    III_PQ_OK            = 0,
    III_PQ_NOT_FOUND     = 1,
    III_PQ_ALREADY       = 2,
    III_PQ_QUORUM_FAIL   = 3
} iii_pl_quarantine_status_t;

const char *iii_pl_quarantine_status_name(iii_pl_quarantine_status_t s);

/* §4 — Sybil resistance: admission cost (DRTM proof + closure-root + small PoW) */
typedef struct iii_pl_admission_cost {
    bool     drtm_attestation_valid;
    bool     silicon_fingerprint_unique;
    uint32_t pow_difficulty_bits;     /* number of leading zeros in admission hash */
    uint32_t pow_nonce;
    uint8_t  admission_hash[32];
} iii_pl_admission_cost_t;

bool iii_pl_admission_check(const iii_pl_admission_cost_t *cost,
                            const uint8_t                  silicon_fp[32]);

/* §5 — eclipse-attack resistance: multi-path connectivity. */
#define III_PL_MULTIPATH_MIN  3u    /* require ≥ 3 disjoint paths */

typedef struct iii_pl_routing_path {
    iii_pl_peer_id_t hops[8];
    unsigned         length;
} iii_pl_routing_path_t;

typedef struct iii_pl_connectivity {
    iii_pl_routing_path_t paths[8];
    unsigned              path_count;
    bool                  satisfies_multipath;
} iii_pl_connectivity_t;

void iii_pl_assess_connectivity(const iii_pl_routing_path_t *paths, size_t n,
                                iii_pl_connectivity_t *out);

/* §6 — network partition recovery */
typedef struct iii_pl_partition {
    bool partitioned;
    uint32_t affected_region_count;
    uint64_t timestamp_detected;
    uint64_t timestamp_recovered;
} iii_pl_partition_t;

/* §7 — witness chain reconciliation */
typedef enum iii_pl_reconcile_status {
    III_PR_IN_SYNC          = 0,
    III_PR_BEHIND           = 1,
    III_PR_AHEAD            = 2,
    III_PR_DIVERGED         = 3,
    III_PR_PARTITIONED      = 4
} iii_pl_reconcile_status_t;

const char *iii_pl_reconcile_status_name(iii_pl_reconcile_status_t s);

/* §1 — runtime */
typedef struct iii_pl_runtime iii_pl_runtime_t;

iii_pl_runtime_t *iii_pl_runtime_create(void);
void              iii_pl_runtime_destroy(iii_pl_runtime_t *rt);

iii_pl_peer_id_t iii_pl_register_peer(iii_pl_runtime_t            *rt,
                                      const iii_pl_admission_cost_t *cost,
                                      const uint8_t                 silicon_fp[32],
                                      iii_pl_cell_id_t              cell,
                                      iii_pl_district_id_t          district,
                                      iii_pl_region_id_t            region);

const iii_pl_peer_t *iii_pl_lookup_peer(const iii_pl_runtime_t *rt, iii_pl_peer_id_t id);
size_t iii_pl_peer_count(const iii_pl_runtime_t *rt);

/* §2 — record peer behaviour observation */
void iii_pl_record_emission_rate(iii_pl_runtime_t *rt, iii_pl_peer_id_t id,
                                 uint64_t baseline, uint64_t recent);
void iii_pl_record_closure_root(iii_pl_runtime_t *rt, iii_pl_peer_id_t id,
                                const uint8_t closure_root[32]);
void iii_pl_record_active_suite(iii_pl_runtime_t *rt, iii_pl_peer_id_t id,
                                uint16_t suite);

void iii_pl_record_anchor_attack(iii_pl_runtime_t *rt, iii_pl_peer_id_t id);

size_t iii_pl_detect_attacks(const iii_pl_runtime_t *rt,
                             iii_pl_peer_id_t        target,
                             const uint8_t           federation_consensus_root[32],
                             uint16_t                federation_consensus_suite,
                             iii_pl_attack_signal_t *out_buf,
                             size_t                  cap);

/* §2.4 — quorum aggregation: how many cell peers reported high-severity? */
bool iii_pl_signal_escalation_needed(const iii_pl_runtime_t *rt,
                                     iii_pl_peer_id_t        target,
                                     iii_pl_severity_t       min_severity);

/* §3 — quarantine */
iii_pl_quarantine_status_t iii_pl_quarantine(iii_pl_runtime_t *rt, iii_pl_peer_id_t id);
iii_pl_quarantine_status_t iii_pl_unquarantine(iii_pl_runtime_t *rt, iii_pl_peer_id_t id);
size_t                     iii_pl_quarantined_count(const iii_pl_runtime_t *rt);

/* §1.4 — leader rotation */
void iii_pl_rotate_leaders(iii_pl_runtime_t *rt, uint64_t epoch);
size_t iii_pl_leader_count(const iii_pl_runtime_t *rt, iii_pl_level_t level);

/* §6 — partition */
void iii_pl_set_partitioned(iii_pl_runtime_t *rt, bool partitioned, uint32_t affected_regions);
const iii_pl_partition_t *iii_pl_partition_state(const iii_pl_runtime_t *rt);

/* §7 — reconcile */
iii_pl_reconcile_status_t iii_pl_reconcile(uint64_t local_height, uint64_t remote_height,
                                           const uint8_t local_root[32],
                                           const uint8_t remote_root[32]);

uint64_t iii_pl_witness_count(const iii_pl_runtime_t *rt);

#ifdef __cplusplus
}
#endif

#endif /* III_PLANETARY_H */
