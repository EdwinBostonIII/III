/* III-FEDERATION implementation */
#include "iii/federation.h"
#include <stdlib.h>
#include <string.h>

extern void iii_sha256(const void *data, size_t len, uint8_t out[32]);

struct iii_fed_runtime {
    iii_fed_peer_t peers[III_FED_PEER_MAX];
    unsigned       peer_count;
    uint64_t       next_peer_id;
    uint64_t       witness_count;
};

const char *iii_fed_tier_name(iii_fed_tier_t t) {
    switch (t) {
        case III_TIER_TRANSIENT:      return "transient";
        case III_TIER_HOST_FILE:      return "host_file";
        case III_TIER_FEDERATION:     return "federation";
        case III_TIER_CONSTITUTIONAL: return "constitutional";
        default:                      return "unknown";
    }
}

iii_fed_outbound_rule_t iii_fed_outbound_rule_for(iii_fed_tier_t t) {
    switch (t) {
        case III_TIER_TRANSIENT:      return III_FOB_LOCAL_ONLY;
        case III_TIER_HOST_FILE:      return III_FOB_PEER_PULL;
        case III_TIER_FEDERATION:     return III_FOB_BROADCAST;
        case III_TIER_CONSTITUTIONAL: return III_FOB_FULL_QUORUM;
        default:                      return III_FOB_LOCAL_ONLY;
    }
}

iii_quorum_spec_t iii_fed_quorum_for_tier(iii_fed_tier_t t) {
    iii_quorum_spec_t s = {0};
    switch (t) {
        case III_TIER_TRANSIENT:      s.total_peers = 0; s.min_agree = 0; break;
        case III_TIER_HOST_FILE:      s.total_peers = 3; s.min_agree = 2; break;
        case III_TIER_FEDERATION:     s.total_peers = 5; s.min_agree = 3; break;
        case III_TIER_CONSTITUTIONAL: s.unanimous = true; break;
        default:                      break;
    }
    return s;
}

iii_fed_tier_t iii_fed_min_tier(const iii_fed_tier_t *contributing, size_t count) {
    if (!contributing || count == 0) return III_TIER_TRANSIENT;
    iii_fed_tier_t m = contributing[0];
    for (size_t i = 1; i < count; ++i) {
        if (contributing[i] < m) m = contributing[i];
    }
    return m;
}

const char *iii_fed_outbound_status_name(iii_fed_outbound_status_t s) {
    switch (s) {
        case III_FOB_OK:                  return "ok";
        case III_FOB_REJECT_TIER0:        return "reject-tier0";
        case III_FOB_REJECT_NO_PEERS:     return "reject-no-peers";
        case III_FOB_REJECT_QUORUM_FAIL:  return "reject-quorum-fail";
        case III_FOB_REJECT_SIGNATURE:    return "reject-signature";
        case III_FOB_REJECT_INVALID:      return "reject-invalid";
        default:                          return "unknown";
    }
}

const char *iii_fed_witness_kind_name(iii_fed_witness_kind_t k) {
    switch (k) {
        case III_FEDW_FED_OUTBOUND:               return "FED_OUTBOUND";
        case III_FEDW_FED_OUTBOUND_REJECT_TIER0:  return "FED_OUTBOUND_REJECT_TIER0";
        case III_FEDW_FED_QUORUM_OK:              return "FED_QUORUM_OK";
        case III_FEDW_FED_QUORUM_FAIL:            return "FED_QUORUM_FAIL";
        case III_FEDW_FED_PEER_DISCOVERED:        return "FED_PEER_DISCOVERED";
        case III_FEDW_FED_PEER_LOST:              return "FED_PEER_LOST";
        case III_FEDW_FED_AMEND_APPLY:            return "FED_AMEND_APPLY";
        default:                                  return "unknown";
    }
}

iii_fed_runtime_t *iii_fed_runtime_create(void) {
    iii_fed_runtime_t *rt = (iii_fed_runtime_t *)calloc(1, sizeof(*rt));
    if (rt) rt->next_peer_id = 1;
    return rt;
}
void iii_fed_runtime_destroy(iii_fed_runtime_t *rt) { if (rt) free(rt); }

uint64_t iii_fed_register_peer(iii_fed_runtime_t *rt,
                               const char        *name,
                               const uint8_t      silicon_fp[32],
                               const uint8_t      fed_pubkey[32])
{
    if (!rt || rt->peer_count >= III_FED_PEER_MAX) return 0;
    iii_fed_peer_t *p = &rt->peers[rt->peer_count++];
    memset(p, 0, sizeof(*p));
    p->peer_id = rt->next_peer_id++;
    if (name) {
        size_t i = 0;
        for (; i < sizeof(p->name) - 1u && name[i]; ++i) p->name[i] = name[i];
        p->name[i] = '\0';
    }
    if (silicon_fp) memcpy(p->silicon_fingerprint, silicon_fp, 32);
    if (fed_pubkey) memcpy(p->federation_pubkey,   fed_pubkey, 32);
    p->live = true;
    rt->witness_count++;
    return p->peer_id;
}

bool iii_fed_set_peer_live(iii_fed_runtime_t *rt, uint64_t peer_id, bool live) {
    if (!rt) return false;
    for (unsigned i = 0; i < rt->peer_count; ++i) {
        if (rt->peers[i].peer_id == peer_id) {
            rt->peers[i].live = live;
            rt->witness_count++;
            return true;
        }
    }
    return false;
}

size_t iii_fed_peer_count(const iii_fed_runtime_t *rt) {
    return rt ? rt->peer_count : 0u;
}

size_t iii_fed_live_peer_count(const iii_fed_runtime_t *rt) {
    if (!rt) return 0;
    size_t n = 0;
    for (unsigned i = 0; i < rt->peer_count; ++i) if (rt->peers[i].live) n++;
    return n;
}

const iii_fed_peer_t *iii_fed_peer_lookup(const iii_fed_runtime_t *rt, uint64_t peer_id) {
    if (!rt) return NULL;
    for (unsigned i = 0; i < rt->peer_count; ++i) {
        if (rt->peers[i].peer_id == peer_id) return &rt->peers[i];
    }
    return NULL;
}

void iii_fed_propose_outbound(iii_fed_runtime_t            *rt,
                              const iii_fed_message_t      *msg,
                              iii_fed_outbound_result_t    *out)
{
    if (!rt || !msg || !out) return;
    memset(out, 0, sizeof(*out));

    /* §2.1 — compute effective tier (min of contributing). */
    iii_fed_tier_t eff = msg->declared_tier;
    if (msg->contributing_tiers && msg->contributing_count > 0) {
        eff = iii_fed_min_tier(msg->contributing_tiers, msg->contributing_count);
        if (msg->declared_tier < eff) eff = msg->declared_tier;
    }
    out->effective_tier = eff;
    out->rule           = iii_fed_outbound_rule_for(eff);
    out->quorum         = iii_fed_quorum_for_tier(eff);

    /* Compute outbound mhash (deterministic). */
    uint8_t buf[1 + 8 + 32];
    buf[0] = (uint8_t)eff;
    for (unsigned i = 0; i < 8; ++i) buf[1 + i] = (uint8_t)(msg->source_module_id >> (i * 8));
    memcpy(buf + 9, msg->body_mhash, 32);
    iii_sha256(buf, sizeof(buf), out->outbound_mhash);

    if (eff == III_TIER_TRANSIENT) {
        out->status = III_FOB_REJECT_TIER0;
        rt->witness_count++;
        return;
    }

    /* For peer-pull, broadcast, or full-quorum we need at least the required
     * peer count to be live. */
    size_t live = iii_fed_live_peer_count(rt);
    if (out->quorum.unanimous) {
        if (live == 0) { out->status = III_FOB_REJECT_NO_PEERS; rt->witness_count++; return; }
    } else {
        if (live < out->quorum.total_peers) {
            out->status = III_FOB_REJECT_NO_PEERS;
            rt->witness_count++;
            return;
        }
    }

    out->status = III_FOB_OK;
    rt->witness_count++;
}

iii_fed_outbound_status_t iii_fed_evaluate_quorum(const iii_fed_runtime_t *rt,
                                                  const iii_quorum_spec_t *spec,
                                                  const iii_fed_vote_t    *votes,
                                                  size_t                   count)
{
    if (!rt || !spec || !votes) return III_FOB_REJECT_INVALID;

    /* Verify each vote's peer exists. */
    size_t agree = 0;
    for (size_t i = 0; i < count; ++i) {
        const iii_fed_peer_t *p = iii_fed_peer_lookup(rt, votes[i].peer_id);
        if (!p) return III_FOB_REJECT_INVALID;
        /* Signature check (simplified): sig != all-zero → valid. */
        bool valid = false;
        for (unsigned k = 0; k < 64; ++k) if (votes[i].signature[k]) { valid = true; break; }
        if (!valid) return III_FOB_REJECT_SIGNATURE;
        if (votes[i].agree) agree++;
    }

    if (spec->unanimous) {
        size_t total_live = iii_fed_live_peer_count(rt);
        return (agree == total_live && total_live > 0) ? III_FOB_OK : III_FOB_REJECT_QUORUM_FAIL;
    }
    if (count < spec->total_peers) return III_FOB_REJECT_QUORUM_FAIL;
    if (agree < spec->min_agree)   return III_FOB_REJECT_QUORUM_FAIL;
    return III_FOB_OK;
}

uint64_t iii_fed_witness_count(const iii_fed_runtime_t *rt) {
    return rt ? rt->witness_count : 0u;
}

iii_fed_tier_t iii_fed_fusion_tier(iii_fed_tier_t a, iii_fed_tier_t b, bool *requires_amend) {
    if (requires_amend) *requires_amend = (a != b);
    return (a < b) ? a : b;
}
