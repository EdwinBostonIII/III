/* ============================================================================
 * III-FEDERATION — Tier-Gated Outbound & Replication
 * Spec: III-FEDERATION.md  (Doc-ID B2, R1.B2)
 *
 * Four tiers: transient < host_file < federation < constitutional.
 * Outbound discipline: a federation message's effective tier is the
 * MINIMUM tier of every module that contributed a witness to it.
 * Quorum disciplines: 3/2, 5/3, unanimous.
 * ============================================================================
 */
#ifndef III_FEDERATION_H
#define III_FEDERATION_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* §1 — Tiers */
typedef enum iii_fed_tier {
    III_TIER_TRANSIENT       = 0,
    III_TIER_HOST_FILE       = 1,
    III_TIER_FEDERATION      = 2,
    III_TIER_CONSTITUTIONAL  = 3
} iii_fed_tier_t;

const char *iii_fed_tier_name(iii_fed_tier_t t);

/* §1 — outbound rule per tier */
typedef enum iii_fed_outbound_rule {
    III_FOB_LOCAL_ONLY       = 0,    /* transient */
    III_FOB_PEER_PULL        = 1,    /* host_file */
    III_FOB_BROADCAST        = 2,    /* federation */
    III_FOB_FULL_QUORUM      = 3     /* constitutional */
} iii_fed_outbound_rule_t;

iii_fed_outbound_rule_t iii_fed_outbound_rule_for(iii_fed_tier_t t);

/* §4 — Quorum specifications */
typedef struct iii_quorum_spec {
    uint32_t total_peers;
    uint32_t min_agree;
    bool     unanimous;
} iii_quorum_spec_t;

iii_quorum_spec_t iii_fed_quorum_for_tier(iii_fed_tier_t t);

/* §2.1 — minimum-tier computation over the contributing modules */
iii_fed_tier_t iii_fed_min_tier(const iii_fed_tier_t *contributing,
                                size_t                count);

/* §2 — outbound decision */
typedef enum iii_fed_outbound_status {
    III_FOB_OK                  = 0,
    III_FOB_REJECT_TIER0        = 1,    /* transient */
    III_FOB_REJECT_NO_PEERS     = 2,
    III_FOB_REJECT_QUORUM_FAIL  = 3,
    III_FOB_REJECT_SIGNATURE    = 4,
    III_FOB_REJECT_INVALID      = 5
} iii_fed_outbound_status_t;

const char *iii_fed_outbound_status_name(iii_fed_outbound_status_t s);

/* §7 — witness step kinds */
typedef enum iii_fed_witness_kind {
    III_FEDW_NONE                       = 0,
    III_FEDW_FED_OUTBOUND               = 0x00D0,
    III_FEDW_FED_OUTBOUND_REJECT_TIER0  = 0x00D1,
    III_FEDW_FED_QUORUM_OK              = 0x00D2,
    III_FEDW_FED_QUORUM_FAIL            = 0x00D3,
    III_FEDW_FED_PEER_DISCOVERED        = 0x00D4,
    III_FEDW_FED_PEER_LOST              = 0x00D5,
    III_FEDW_FED_AMEND_APPLY            = 0x00D6
} iii_fed_witness_kind_t;

const char *iii_fed_witness_kind_name(iii_fed_witness_kind_t k);

/* ----------------------------------------------------------------------------
 * Federation runtime: peer table + quorum vote tracking.
 * ---------------------------------------------------------------------------- */
#define III_FED_PEER_MAX           32u
#define III_FED_PEER_NAME_MAX      64u

typedef struct iii_fed_peer {
    uint64_t  peer_id;
    char      name[III_FED_PEER_NAME_MAX];
    uint8_t   silicon_fingerprint[32];
    uint8_t   federation_pubkey[32];      /* DRTM-rooted */
    bool      live;
    uint64_t  last_seen;
} iii_fed_peer_t;

typedef struct iii_fed_runtime iii_fed_runtime_t;

iii_fed_runtime_t *iii_fed_runtime_create(void);
void               iii_fed_runtime_destroy(iii_fed_runtime_t *rt);

uint64_t iii_fed_register_peer(iii_fed_runtime_t *rt,
                               const char        *name,
                               const uint8_t      silicon_fp[32],
                               const uint8_t      fed_pubkey[32]);

bool iii_fed_set_peer_live(iii_fed_runtime_t *rt, uint64_t peer_id, bool live);
size_t iii_fed_peer_count(const iii_fed_runtime_t *rt);
size_t iii_fed_live_peer_count(const iii_fed_runtime_t *rt);
const iii_fed_peer_t *iii_fed_peer_lookup(const iii_fed_runtime_t *rt, uint64_t peer_id);

/* §2 — propose an outbound message; returns the verdict and the witness mhash. */
typedef struct iii_fed_message {
    iii_fed_tier_t   declared_tier;            /* tier of the message */
    const iii_fed_tier_t *contributing_tiers;  /* min-tier walk */
    size_t                contributing_count;
    uint64_t              source_module_id;
    uint8_t               body_mhash[32];
} iii_fed_message_t;

typedef struct iii_fed_outbound_result {
    iii_fed_outbound_status_t status;
    iii_fed_tier_t            effective_tier;
    iii_fed_outbound_rule_t   rule;
    iii_quorum_spec_t         quorum;
    uint8_t                   outbound_mhash[32];
} iii_fed_outbound_result_t;

void iii_fed_propose_outbound(iii_fed_runtime_t            *rt,
                              const iii_fed_message_t      *msg,
                              iii_fed_outbound_result_t    *out);

/* §4 — record a peer's vote on a pending message, then evaluate quorum. */
typedef struct iii_fed_vote {
    uint64_t peer_id;
    bool     agree;
    uint8_t  signature[64];
} iii_fed_vote_t;

iii_fed_outbound_status_t iii_fed_evaluate_quorum(const iii_fed_runtime_t *rt,
                                                  const iii_quorum_spec_t *spec,
                                                  const iii_fed_vote_t    *votes,
                                                  size_t                   count);

uint64_t iii_fed_witness_count(const iii_fed_runtime_t *rt);

/* §3 — fusion tier rule: returns the resulting tier of fusing two modules
 * with the supplied tiers; constitutional fusion across tiers requires
 * `amend.apply` and is reflected by `requires_amend` set true. */
iii_fed_tier_t iii_fed_fusion_tier(iii_fed_tier_t a, iii_fed_tier_t b, bool *requires_amend);

#ifdef __cplusplus
}
#endif

#endif /* III_FEDERATION_H */
