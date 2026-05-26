/* III-PLANETARY implementation */
#include "iii/planetary.h"
#include <stdlib.h>
#include <string.h>

extern void iii_sha256(const void *data, size_t len, uint8_t out[32]);

const char *iii_pl_level_name(iii_pl_level_t l) {
    switch (l) {
        case III_PL_CELL:      return "cell";
        case III_PL_DISTRICT:  return "district";
        case III_PL_REGION:    return "region";
        case III_PL_SUBSTRATE: return "substrate";
        default:               return "unknown";
    }
}

const char *iii_pl_attack_kind_name(iii_pl_attack_kind_t k) {
    switch (k) {
        case III_PA_WITNESS_INTEGRITY_VIOLATION:   return "witness-integrity-violation";
        case III_PA_BURST_EMISSION:                return "burst-emission";
        case III_PA_ANCHOR_ATTACK_PATTERN:         return "anchor-attack-pattern";
        case III_PA_CROSS_PEER_DIVERGENCE:         return "cross-peer-divergence";
        case III_PA_SUITE_REGRESSION:              return "suite-regression";
        case III_PA_CLOSURE_ROOT_DIVERGENCE:       return "closure-root-divergence";
        default:                                   return "none";
    }
}

const char *iii_pl_quarantine_status_name(iii_pl_quarantine_status_t s) {
    switch (s) {
        case III_PQ_OK:           return "ok";
        case III_PQ_NOT_FOUND:    return "not-found";
        case III_PQ_ALREADY:      return "already";
        case III_PQ_QUORUM_FAIL:  return "quorum-fail";
        default:                  return "unknown";
    }
}

const char *iii_pl_reconcile_status_name(iii_pl_reconcile_status_t s) {
    switch (s) {
        case III_PR_IN_SYNC:     return "in-sync";
        case III_PR_BEHIND:      return "behind";
        case III_PR_AHEAD:       return "ahead";
        case III_PR_DIVERGED:    return "diverged";
        case III_PR_PARTITIONED: return "partitioned";
        default:                 return "unknown";
    }
}

bool iii_pl_admission_check(const iii_pl_admission_cost_t *cost,
                            const uint8_t                  silicon_fp[32])
{
    if (!cost) return false;
    if (!cost->drtm_attestation_valid) return false;
    if (!cost->silicon_fingerprint_unique) return false;
    /* Verify admission_hash leading zero bits ≥ pow_difficulty_bits. */
    uint32_t bits = cost->pow_difficulty_bits;
    for (unsigned i = 0; i < 32 && bits > 0; ++i) {
        if (bits >= 8u) {
            if (cost->admission_hash[i] != 0) return false;
            bits -= 8u;
        } else {
            uint8_t mask = (uint8_t)(0xFFu << (8u - bits));
            if ((cost->admission_hash[i] & mask) != 0) return false;
            bits = 0;
        }
    }
    /* The hash should also bind to the silicon fingerprint */
    if (silicon_fp) {
        uint8_t buf[32 + 4];
        memcpy(buf, silicon_fp, 32);
        for (unsigned i = 0; i < 4; ++i) buf[32 + i] = (uint8_t)(cost->pow_nonce >> (i * 8));
        uint8_t h[32];
        iii_sha256(buf, sizeof(buf), h);
        if (memcmp(h, cost->admission_hash, 32) != 0) return false;
    }
    return true;
}

void iii_pl_assess_connectivity(const iii_pl_routing_path_t *paths, size_t n,
                                iii_pl_connectivity_t *out)
{
    if (!out) return;
    memset(out, 0, sizeof(*out));
    if (!paths || n == 0) return;

    size_t take = (n < 8u) ? n : 8u;
    for (size_t i = 0; i < take; ++i) out->paths[i] = paths[i];
    out->path_count = (unsigned)take;

    /* Disjointness: no peer appears in two different paths. */
    unsigned disjoint = 0;
    for (size_t i = 0; i < take; ++i) {
        bool ok = true;
        for (size_t j = 0; j < take; ++j) {
            if (i == j) continue;
            for (unsigned a = 0; a < paths[i].length; ++a) {
                for (unsigned b = 0; b < paths[j].length; ++b) {
                    if (paths[i].hops[a] == paths[j].hops[b] && paths[i].hops[a] != 0) {
                        ok = false;
                    }
                }
            }
        }
        if (ok) disjoint++;
    }
    out->satisfies_multipath = (disjoint >= III_PL_MULTIPATH_MIN);
}

iii_pl_reconcile_status_t iii_pl_reconcile(uint64_t local_height, uint64_t remote_height,
                                           const uint8_t local_root[32],
                                           const uint8_t remote_root[32])
{
    if (memcmp(local_root, remote_root, 32) == 0 && local_height == remote_height) return III_PR_IN_SYNC;
    if (memcmp(local_root, remote_root, 32) == 0) {
        return (local_height < remote_height) ? III_PR_BEHIND : III_PR_AHEAD;
    }
    /* Roots differ — diverged or partitioned. */
    /* If heights differ greatly (>1024), classify as PARTITIONED. */
    uint64_t diff = (local_height > remote_height) ? (local_height - remote_height)
                                                    : (remote_height - local_height);
    if (diff > 1024) return III_PR_PARTITIONED;
    return III_PR_DIVERGED;
}

/* ----------------------------------------------------------------------------
 * Runtime
 * ---------------------------------------------------------------------------- */
struct iii_pl_runtime {
    iii_pl_peer_t   peers[III_PL_PEERS_MAX];
    unsigned        peer_count;
    uint64_t        next_peer_id;
    iii_pl_partition_t partition;
    uint64_t        witness_count;
};

iii_pl_runtime_t *iii_pl_runtime_create(void) {
    iii_pl_runtime_t *rt = (iii_pl_runtime_t *)calloc(1, sizeof(*rt));
    if (rt) rt->next_peer_id = 1;
    return rt;
}
void iii_pl_runtime_destroy(iii_pl_runtime_t *rt) { if (rt) free(rt); }

uint64_t iii_pl_witness_count(const iii_pl_runtime_t *rt) { return rt ? rt->witness_count : 0u; }

iii_pl_peer_id_t iii_pl_register_peer(iii_pl_runtime_t            *rt,
                                      const iii_pl_admission_cost_t *cost,
                                      const uint8_t                 silicon_fp[32],
                                      iii_pl_cell_id_t              cell,
                                      iii_pl_district_id_t          district,
                                      iii_pl_region_id_t            region)
{
    if (!rt || rt->peer_count >= III_PL_PEERS_MAX) return 0;
    if (!iii_pl_admission_check(cost, silicon_fp)) return 0;
    iii_pl_peer_t *p = &rt->peers[rt->peer_count++];
    memset(p, 0, sizeof(*p));
    p->peer_id = rt->next_peer_id++;
    if (silicon_fp) memcpy(p->silicon_fp, silicon_fp, 32);
    p->cell = cell;
    p->district = district;
    p->region = region;
    p->live = true;
    rt->witness_count++;
    return p->peer_id;
}

const iii_pl_peer_t *iii_pl_lookup_peer(const iii_pl_runtime_t *rt, iii_pl_peer_id_t id) {
    if (!rt) return NULL;
    for (unsigned i = 0; i < rt->peer_count; ++i) {
        if (rt->peers[i].peer_id == id) return &rt->peers[i];
    }
    return NULL;
}

size_t iii_pl_peer_count(const iii_pl_runtime_t *rt) {
    return rt ? rt->peer_count : 0u;
}

static iii_pl_peer_t *find_mut(iii_pl_runtime_t *rt, iii_pl_peer_id_t id) {
    for (unsigned i = 0; i < rt->peer_count; ++i) {
        if (rt->peers[i].peer_id == id) return &rt->peers[i];
    }
    return NULL;
}

void iii_pl_record_emission_rate(iii_pl_runtime_t *rt, iii_pl_peer_id_t id,
                                 uint64_t baseline, uint64_t recent)
{
    iii_pl_peer_t *p = find_mut(rt, id);
    if (!p) return;
    p->baseline_emission_rate = baseline;
    p->last_emission_rate = recent;
}

void iii_pl_record_closure_root(iii_pl_runtime_t *rt, iii_pl_peer_id_t id,
                                const uint8_t closure_root[32])
{
    iii_pl_peer_t *p = find_mut(rt, id);
    if (!p || !closure_root) return;
    memcpy(p->closure_root, closure_root, 32);
}

void iii_pl_record_active_suite(iii_pl_runtime_t *rt, iii_pl_peer_id_t id, uint16_t suite) {
    iii_pl_peer_t *p = find_mut(rt, id);
    if (!p) return;
    p->active_suite = suite;
}

void iii_pl_record_anchor_attack(iii_pl_runtime_t *rt, iii_pl_peer_id_t id) {
    iii_pl_peer_t *p = find_mut(rt, id);
    if (!p) return;
    p->attack_signal_count++;
}

size_t iii_pl_detect_attacks(const iii_pl_runtime_t *rt,
                             iii_pl_peer_id_t        target,
                             const uint8_t           federation_consensus_root[32],
                             uint16_t                federation_consensus_suite,
                             iii_pl_attack_signal_t *out_buf,
                             size_t                  cap)
{
    if (!rt || !out_buf || cap == 0) return 0;
    const iii_pl_peer_t *p = iii_pl_lookup_peer(rt, target);
    if (!p) return 0;
    size_t n = 0;

    /* §2.2 Signal 2 — burst emission. */
    if (p->baseline_emission_rate > 0 &&
        p->last_emission_rate > p->baseline_emission_rate * III_PL_BURST_THRESHOLD_MULTIPLIER &&
        n < cap)
    {
        out_buf[n++] = (iii_pl_attack_signal_t){
            .kind = III_PA_BURST_EMISSION,
            .target = target,
            .severity = III_PS_MEDIUM
        };
    }

    /* §2.2 Signal 3 — anchor attack pattern. */
    if (p->attack_signal_count >= III_PL_ANCHOR_ATTACK_THRESHOLD && n < cap) {
        out_buf[n++] = (iii_pl_attack_signal_t){
            .kind = III_PA_ANCHOR_ATTACK_PATTERN,
            .target = target,
            .severity = III_PS_HIGH
        };
    }

    /* §2.2 Signal 5 — suite regression. */
    if (p->active_suite != 0 &&
        p->active_suite < federation_consensus_suite && n < cap)
    {
        out_buf[n++] = (iii_pl_attack_signal_t){
            .kind = III_PA_SUITE_REGRESSION,
            .target = target,
            .severity = III_PS_HIGH
        };
    }

    /* §2.2 Signal 6 — closure-root divergence. */
    if (federation_consensus_root) {
        bool any = false;
        for (unsigned i = 0; i < 32; ++i) if (p->closure_root[i]) { any = true; break; }
        if (any && memcmp(p->closure_root, federation_consensus_root, 32) != 0 && n < cap) {
            out_buf[n++] = (iii_pl_attack_signal_t){
                .kind = III_PA_CLOSURE_ROOT_DIVERGENCE,
                .target = target,
                .severity = III_PS_HIGH
            };
        }
    }

    return n;
}

bool iii_pl_signal_escalation_needed(const iii_pl_runtime_t *rt,
                                     iii_pl_peer_id_t        target,
                                     iii_pl_severity_t       min_severity)
{
    /* Simplified: if the target peer's attack_signal_count crosses the threshold
     * AND severity expectation matches, escalate. */
    const iii_pl_peer_t *p = iii_pl_lookup_peer(rt, target);
    if (!p) return false;
    return (p->attack_signal_count >= III_PL_ANCHOR_ATTACK_THRESHOLD)
           && (min_severity <= III_PS_HIGH);
}

iii_pl_quarantine_status_t iii_pl_quarantine(iii_pl_runtime_t *rt, iii_pl_peer_id_t id) {
    iii_pl_peer_t *p = find_mut(rt, id);
    if (!p) return III_PQ_NOT_FOUND;
    if (p->quarantined) return III_PQ_ALREADY;
    p->quarantined = true;
    p->live = false;
    rt->witness_count++;
    return III_PQ_OK;
}

iii_pl_quarantine_status_t iii_pl_unquarantine(iii_pl_runtime_t *rt, iii_pl_peer_id_t id) {
    iii_pl_peer_t *p = find_mut(rt, id);
    if (!p) return III_PQ_NOT_FOUND;
    if (!p->quarantined) return III_PQ_ALREADY;
    p->quarantined = false;
    p->live = true;
    rt->witness_count++;
    return III_PQ_OK;
}

size_t iii_pl_quarantined_count(const iii_pl_runtime_t *rt) {
    if (!rt) return 0;
    size_t n = 0;
    for (unsigned i = 0; i < rt->peer_count; ++i) if (rt->peers[i].quarantined) n++;
    return n;
}

void iii_pl_rotate_leaders(iii_pl_runtime_t *rt, uint64_t epoch) {
    if (!rt) return;
    /* Deterministic rotation: leader_idx = (epoch + cell_id) mod cell_size. */
    /* For each cell pick one leader, similarly for districts and regions. */
    uint64_t   selected_cell[III_PL_CELL_MAX] = {0};
    uint64_t   selected_dist[III_PL_DISTRICT_MAX] = {0};
    uint64_t   selected_region[III_PL_REGION_MAX] = {0};
    bool       has_cell[III_PL_CELL_MAX] = {0};
    bool       has_dist[III_PL_DISTRICT_MAX] = {0};
    bool       has_region[III_PL_REGION_MAX] = {0};
    /* Find the i-th eligible peer in each grouping. */
    for (unsigned c = 0; c < III_PL_CELL_MAX; ++c) {
        unsigned k = 0;
        for (unsigned i = 0; i < rt->peer_count; ++i) {
            if (rt->peers[i].cell == c && !rt->peers[i].quarantined && rt->peers[i].live) {
                if (k == ((epoch + c) & 0x07u)) { selected_cell[c] = rt->peers[i].peer_id; has_cell[c] = true; break; }
                k++;
            }
        }
    }
    for (unsigned d = 0; d < III_PL_DISTRICT_MAX; ++d) {
        unsigned k = 0;
        for (unsigned i = 0; i < rt->peer_count; ++i) {
            if (rt->peers[i].district == d && !rt->peers[i].quarantined && rt->peers[i].live) {
                if (k == ((epoch + d) & 0x07u)) { selected_dist[d] = rt->peers[i].peer_id; has_dist[d] = true; break; }
                k++;
            }
        }
    }
    for (unsigned r = 0; r < III_PL_REGION_MAX; ++r) {
        unsigned k = 0;
        for (unsigned i = 0; i < rt->peer_count; ++i) {
            if (rt->peers[i].region == r && !rt->peers[i].quarantined && rt->peers[i].live) {
                if (k == ((epoch + r) & 0x07u)) { selected_region[r] = rt->peers[i].peer_id; has_region[r] = true; break; }
                k++;
            }
        }
    }

    for (unsigned i = 0; i < rt->peer_count; ++i) {
        rt->peers[i].leader = false;
    }
    for (unsigned c = 0; c < III_PL_CELL_MAX; ++c) {
        if (has_cell[c]) {
            iii_pl_peer_t *p = find_mut(rt, selected_cell[c]);
            if (p) p->leader = true;
        }
    }
    for (unsigned d = 0; d < III_PL_DISTRICT_MAX; ++d) {
        if (has_dist[d]) {
            iii_pl_peer_t *p = find_mut(rt, selected_dist[d]);
            if (p) p->leader = true;
        }
    }
    for (unsigned r = 0; r < III_PL_REGION_MAX; ++r) {
        if (has_region[r]) {
            iii_pl_peer_t *p = find_mut(rt, selected_region[r]);
            if (p) p->leader = true;
        }
    }
    rt->witness_count++;
}

size_t iii_pl_leader_count(const iii_pl_runtime_t *rt, iii_pl_level_t level) {
    if (!rt) return 0;
    (void)level;
    size_t n = 0;
    for (unsigned i = 0; i < rt->peer_count; ++i) if (rt->peers[i].leader) n++;
    return n;
}

void iii_pl_set_partitioned(iii_pl_runtime_t *rt, bool partitioned, uint32_t affected_regions) {
    if (!rt) return;
    rt->partition.partitioned = partitioned;
    rt->partition.affected_region_count = affected_regions;
    if (partitioned) rt->partition.timestamp_detected = ++rt->witness_count;
    else             rt->partition.timestamp_recovered = ++rt->witness_count;
}

const iii_pl_partition_t *iii_pl_partition_state(const iii_pl_runtime_t *rt) {
    return rt ? &rt->partition : NULL;
}
