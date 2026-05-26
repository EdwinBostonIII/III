/* ============================================================================
 * III-SOVEREIGN-WEB — Sovereign Web Protocol
 * Spec: III-SOVEREIGN-WEB.md  (Wave 7, items 54-62)
 *
 *   §1 — IOMMU-mediated network transport
 *   §2 — witness-tagged packet formation (IPv4 option 0xCC / IPv6 hop-by-hop)
 *   §3 — AH-trailer (RFC 4302) with HMAC-SHA-256 / HMAC-SHAKE-256
 *   §4 — peer discovery
 *   §5 — Trinity-tier-gated outbound
 *   §6 — cross-peer chain replication
 *   §8 — NDIS coexistence
 *   §9 — network cap discipline
 * ============================================================================
 */
#ifndef III_SOVEREIGN_WEB_H
#define III_SOVEREIGN_WEB_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* §2.2 / §2.3 — IP option type for III witness */
#define III_WIT_IPV4_OPT_TYPE   0xCCu
#define III_WIT_IPV6_OPT_TYPE   0xCCu

/* §3.2 — suite identifiers (high byte of SPI) */
#define III_SUITE_PRE_QUANTUM   0x01u
#define III_SUITE_PQC           0x10u
#define III_SUITE_HYBRID        0x30u

/* §1.2 — buffer pool defaults */
#define III_NET_BUFFER_DEFAULT_BYTES   (64u * 1024u * 1024u)

/* §2.2 — packet formation */
typedef enum iii_net_ip_version {
    III_NET_IPV4 = 4,
    III_NET_IPV6 = 6
} iii_net_ip_version_t;

typedef struct iii_net_packet {
    iii_net_ip_version_t  ipver;
    uint32_t              src_addr_v4;
    uint32_t              dst_addr_v4;
    uint8_t               src_addr_v6[16];
    uint8_t               dst_addr_v6[16];
    uint16_t              src_port;
    uint16_t              dst_port;
    uint8_t               body_mhash[32];
    uint64_t              source_peer_id;
    uint64_t              destination_peer_id;
    uint64_t              timestamp;
    uint16_t              tier;                /* Trinity tier */
} iii_net_packet_t;

typedef struct iii_net_witness_option {
    uint8_t  option_type;        /* 0xCC */
    uint8_t  option_len;
    uint8_t  witness_mhash[32];
    uint8_t  pad;
} iii_net_witness_option_t;       /* IPv4 option layout (35-byte payload + 1 align) */

void iii_net_witness_option_build(const uint8_t witness_mhash[32],
                                  iii_net_witness_option_t *out);

/* §3 — AH trailer (RFC 4302) */
typedef struct iii_net_ah_trailer {
    uint8_t  next_header;
    uint8_t  length;
    uint16_t reserved;
    uint32_t spi;                 /* high byte = suite id; low 24 bits = SPI */
    uint32_t sequence_number;
    uint8_t  authentication_data[32];
} iii_net_ah_trailer_t;

void iii_net_ah_compute(const uint8_t            sub_key[32],
                        uint8_t                  suite_id,
                        const iii_net_packet_t  *pkt,
                        const uint8_t            packet_body[], size_t body_len,
                        uint32_t                 sequence_number,
                        iii_net_ah_trailer_t    *out);

bool iii_net_ah_verify(const uint8_t            sub_key[32],
                       const iii_net_packet_t  *pkt,
                       const uint8_t            packet_body[], size_t body_len,
                       const iii_net_ah_trailer_t *ah);

/* ----------------------------------------------------------------------------
 * Replay protection
 * ---------------------------------------------------------------------------- */
#define III_NET_REPLAY_WINDOW   64u

typedef struct iii_net_replay_window {
    uint64_t source_peer_id;
    uint64_t destination_peer_id;
    uint32_t high_seq;
    uint64_t bitmap;          /* 64-bit window */
} iii_net_replay_window_t;

void iii_net_replay_init(iii_net_replay_window_t *w, uint64_t src, uint64_t dst);
bool iii_net_replay_admit(iii_net_replay_window_t *w, uint32_t seq);

/* ----------------------------------------------------------------------------
 * §4 — peer discovery
 * ---------------------------------------------------------------------------- */
#define III_NET_PEER_MAX  64u

typedef struct iii_net_peer {
    uint64_t peer_id;
    uint32_t addr_v4;
    uint8_t  addr_v6[16];
    uint8_t  sub_key[32];
    uint16_t port;
    bool     ipv6;
    bool     discovered;
    uint64_t last_witness_seq;
} iii_net_peer_t;

typedef struct iii_net_runtime iii_net_runtime_t;

iii_net_runtime_t *iii_net_runtime_create(size_t buffer_pool_bytes);
void               iii_net_runtime_destroy(iii_net_runtime_t *rt);

/* §4 — register a discovered peer.  In real deployments triggered by witness-
 * tagged broadcast on the local network. */
uint64_t iii_net_register_peer_v4(iii_net_runtime_t *rt,
                                  uint32_t           addr_v4,
                                  uint16_t           port,
                                  const uint8_t      sub_key[32]);
uint64_t iii_net_register_peer_v6(iii_net_runtime_t *rt,
                                  const uint8_t      addr_v6[16],
                                  uint16_t           port,
                                  const uint8_t      sub_key[32]);

const iii_net_peer_t *iii_net_lookup_peer(const iii_net_runtime_t *rt, uint64_t peer_id);
size_t iii_net_peer_count(const iii_net_runtime_t *rt);

/* §5 — outbound: validates Trinity tier, augments with witness option +
 * AH trailer.  Returns the result code; on success the augmented bytes are
 * written to `out_buf` (cap is upper-bound). */
typedef enum iii_net_outbound_status {
    III_NET_OB_OK                = 0,
    III_NET_OB_REJECT_TIER0      = 1,
    III_NET_OB_REJECT_NO_PEER    = 2,
    III_NET_OB_REJECT_BUFFER     = 3,
    III_NET_OB_REJECT_NO_KEY     = 4,
    III_NET_OB_REJECT_INVALID    = 5
} iii_net_outbound_status_t;

const char *iii_net_outbound_status_name(iii_net_outbound_status_t s);

iii_net_outbound_status_t iii_net_outbound(iii_net_runtime_t           *rt,
                                           uint64_t                     destination_peer_id,
                                           const iii_net_packet_t       *pkt,
                                           const uint8_t                *body, size_t body_len,
                                           uint8_t                       suite_id,
                                           uint32_t                      sequence_number,
                                           uint8_t                      *out_buf,
                                           size_t                        out_cap,
                                           size_t                       *out_len);

/* §1.5 — inbound: decode + verify; returns whether the packet is III-tagged. */
typedef enum iii_net_inbound_status {
    III_NET_IB_NON_III           = 0,
    III_NET_IB_VALID             = 1,
    III_NET_IB_INVALID_AH        = 2,
    III_NET_IB_REPLAY            = 3,
    III_NET_IB_DROPPED_OPTION    = 4
} iii_net_inbound_status_t;

const char *iii_net_inbound_status_name(iii_net_inbound_status_t s);

iii_net_inbound_status_t iii_net_inbound(iii_net_runtime_t           *rt,
                                         uint64_t                     source_peer_id,
                                         const iii_net_packet_t       *pkt,
                                         const uint8_t                *body, size_t body_len,
                                         const iii_net_witness_option_t *opt,
                                         const iii_net_ah_trailer_t   *ah);

/* §8 — NDIS-style passthrough: returns true iff the substrate consumes the
 * packet (witness-tagged + valid).  False = pass through to host OS. */
bool iii_net_should_consume(const iii_net_witness_option_t *opt);

/* §6 — cross-peer chain replication.  The runtime tracks the latest witness
 * sequence per peer and rejects out-of-order replicas.  Returns true iff the
 * caller should accept the replicated witness. */
bool iii_net_replicate(iii_net_runtime_t *rt, uint64_t source_peer_id,
                       uint64_t           witness_seq);

/* §9 — network-level cap discipline */
typedef enum iii_net_cap {
    III_NET_CAP_NONE         = 0,
    III_NET_CAP_OUTBOUND     = 1,
    III_NET_CAP_INBOUND      = 2,
    III_NET_CAP_PEER_DISCOVER = 3,
    III_NET_CAP_REPLICATE    = 4
} iii_net_cap_t;

const char *iii_net_cap_name(iii_net_cap_t c);

uint64_t iii_net_witness_count(const iii_net_runtime_t *rt);

/* §10 — HotStuff BFT R1 reference mirror (gospel V1 Stage 5). Byte-identical
 * block/QC formats to STDLIB/iii/aether/hotstuff.iii. */
void iii_sw_hs_block_hash(const uint8_t parent_qc[256], uint64_t view,
                          const uint8_t payload_mhash[32], uint8_t out[32]);
int  iii_sw_hs_compose_qc(const uint8_t block_mhash[32], uint64_t view,
                          const uint8_t *sigs, uint32_t n_sigs, uint8_t *out_qc);

#ifdef __cplusplus
}
#endif

#endif /* III_SOVEREIGN_WEB_H */
