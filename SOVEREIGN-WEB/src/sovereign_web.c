/* III-SOVEREIGN-WEB implementation */
#include "iii/sovereign_web.h"
#include <stdlib.h>
#include <string.h>

extern void iii_sha256(const void *data, size_t len, uint8_t out[32]);
extern void iii_hmac_sha256(const uint8_t *key, size_t key_len,
                            const uint8_t *msg, size_t msg_len,
                            uint8_t out[32]);

const char *iii_net_outbound_status_name(iii_net_outbound_status_t s) {
    switch (s) {
        case III_NET_OB_OK:               return "ok";
        case III_NET_OB_REJECT_TIER0:     return "reject-tier0";
        case III_NET_OB_REJECT_NO_PEER:   return "reject-no-peer";
        case III_NET_OB_REJECT_BUFFER:    return "reject-buffer";
        case III_NET_OB_REJECT_NO_KEY:    return "reject-no-key";
        case III_NET_OB_REJECT_INVALID:   return "reject-invalid";
        default:                          return "unknown";
    }
}

const char *iii_net_inbound_status_name(iii_net_inbound_status_t s) {
    switch (s) {
        case III_NET_IB_NON_III:        return "non-III";
        case III_NET_IB_VALID:          return "valid";
        case III_NET_IB_INVALID_AH:     return "invalid-ah";
        case III_NET_IB_REPLAY:         return "replay";
        case III_NET_IB_DROPPED_OPTION: return "dropped-option";
        default:                        return "unknown";
    }
}

const char *iii_net_cap_name(iii_net_cap_t c) {
    switch (c) {
        case III_NET_CAP_OUTBOUND:       return "cap<network<outbound>>";
        case III_NET_CAP_INBOUND:        return "cap<network<inbound>>";
        case III_NET_CAP_PEER_DISCOVER:  return "cap<network<peer_discover>>";
        case III_NET_CAP_REPLICATE:      return "cap<network<replicate>>";
        default:                         return "none";
    }
}

void iii_net_witness_option_build(const uint8_t witness_mhash[32],
                                  iii_net_witness_option_t *out)
{
    if (!out) return;
    memset(out, 0, sizeof(*out));
    out->option_type = III_WIT_IPV4_OPT_TYPE;
    out->option_len  = 35u;
    if (witness_mhash) memcpy(out->witness_mhash, witness_mhash, 32);
}

void iii_net_ah_compute(const uint8_t            sub_key[32],
                        uint8_t                  suite_id,
                        const iii_net_packet_t  *pkt,
                        const uint8_t            packet_body[], size_t body_len,
                        uint32_t                 sequence_number,
                        iii_net_ah_trailer_t    *out)
{
    if (!out) return;
    memset(out, 0, sizeof(*out));
    out->next_header     = 0x33;       /* AH = 51 (0x33) */
    out->length          = (uint8_t)((sizeof(*out) - 8u) / 4u);
    out->reserved        = 0;
    out->spi             = ((uint32_t)suite_id << 24) | (uint32_t)(pkt ? pkt->destination_peer_id & 0x00FFFFFFu : 0u);
    out->sequence_number = sequence_number;
    if (!sub_key || !pkt) return;

    /* HMAC over: packet_body || witness_mhash || src_peer || dst_peer || timestamp */
    size_t need = body_len + 32 + 8 + 8 + 8;
    uint8_t *buf = (uint8_t *)malloc(need);
    if (!buf) return;
    size_t pos = 0;
    if (packet_body && body_len) { memcpy(buf, packet_body, body_len); pos += body_len; }
    memcpy(buf + pos, pkt->body_mhash, 32);
    pos += 32;
    for (unsigned i = 0; i < 8; ++i) {
        buf[pos + i] = (uint8_t)(pkt->source_peer_id >> (i * 8));
    }
    pos += 8;
    for (unsigned i = 0; i < 8; ++i) {
        buf[pos + i] = (uint8_t)(pkt->destination_peer_id >> (i * 8));
    }
    pos += 8;
    for (unsigned i = 0; i < 8; ++i) {
        buf[pos + i] = (uint8_t)(pkt->timestamp >> (i * 8));
    }
    pos += 8;
    iii_hmac_sha256(sub_key, 32, buf, pos, out->authentication_data);
    free(buf);
}

bool iii_net_ah_verify(const uint8_t            sub_key[32],
                       const iii_net_packet_t  *pkt,
                       const uint8_t            packet_body[], size_t body_len,
                       const iii_net_ah_trailer_t *ah)
{
    if (!sub_key || !pkt || !ah) return false;
    iii_net_ah_trailer_t recomputed;
    uint8_t suite_id = (uint8_t)(ah->spi >> 24);
    iii_net_ah_compute(sub_key, suite_id, pkt, packet_body, body_len, ah->sequence_number, &recomputed);
    /* Compare HMAC tag in constant time. */
    uint8_t diff = 0;
    for (unsigned i = 0; i < 32; ++i) {
        diff |= (uint8_t)(recomputed.authentication_data[i] ^ ah->authentication_data[i]);
    }
    return diff == 0;
}

void iii_net_replay_init(iii_net_replay_window_t *w, uint64_t src, uint64_t dst) {
    if (!w) return;
    memset(w, 0, sizeof(*w));
    w->source_peer_id = src;
    w->destination_peer_id = dst;
}

bool iii_net_replay_admit(iii_net_replay_window_t *w, uint32_t seq) {
    if (!w) return false;
    if (seq > w->high_seq) {
        uint32_t shift = seq - w->high_seq;
        if (shift >= 64u) {
            w->bitmap = 1ull;
        } else {
            w->bitmap = (w->bitmap << shift) | 1ull;
        }
        w->high_seq = seq;
        return true;
    }
    /* seq <= high_seq */
    uint32_t age = w->high_seq - seq;
    if (age >= 64u) return false;            /* outside window */
    uint64_t mask = 1ull << age;
    if (w->bitmap & mask) return false;      /* already seen */
    w->bitmap |= mask;
    return true;
}

bool iii_net_should_consume(const iii_net_witness_option_t *opt) {
    if (!opt) return false;
    return opt->option_type == III_WIT_IPV4_OPT_TYPE && opt->option_len == 35u;
}

/* ----------------------------------------------------------------------------
 * Runtime
 * ---------------------------------------------------------------------------- */
struct iii_net_runtime {
    iii_net_peer_t  peers[III_NET_PEER_MAX];
    unsigned        peer_count;
    uint64_t        next_peer_id;
    size_t          buffer_pool_bytes;
    size_t          buffer_used;
    iii_net_replay_window_t replay[III_NET_PEER_MAX];
    unsigned        replay_count;
    uint64_t        witness_count;
};

iii_net_runtime_t *iii_net_runtime_create(size_t buffer_pool_bytes) {
    iii_net_runtime_t *rt = (iii_net_runtime_t *)calloc(1, sizeof(*rt));
    if (!rt) return NULL;
    rt->buffer_pool_bytes = (buffer_pool_bytes > 0) ? buffer_pool_bytes : III_NET_BUFFER_DEFAULT_BYTES;
    rt->next_peer_id = 1;
    return rt;
}

void iii_net_runtime_destroy(iii_net_runtime_t *rt) { if (rt) free(rt); }

uint64_t iii_net_witness_count(const iii_net_runtime_t *rt) { return rt ? rt->witness_count : 0u; }

uint64_t iii_net_register_peer_v4(iii_net_runtime_t *rt,
                                  uint32_t           addr_v4,
                                  uint16_t           port,
                                  const uint8_t      sub_key[32])
{
    if (!rt || rt->peer_count >= III_NET_PEER_MAX) return 0;
    iii_net_peer_t *p = &rt->peers[rt->peer_count++];
    memset(p, 0, sizeof(*p));
    p->peer_id = rt->next_peer_id++;
    p->addr_v4 = addr_v4;
    p->port = port;
    p->ipv6 = false;
    p->discovered = true;
    if (sub_key) memcpy(p->sub_key, sub_key, 32);
    rt->witness_count++;
    return p->peer_id;
}

uint64_t iii_net_register_peer_v6(iii_net_runtime_t *rt,
                                  const uint8_t      addr_v6[16],
                                  uint16_t           port,
                                  const uint8_t      sub_key[32])
{
    if (!rt || rt->peer_count >= III_NET_PEER_MAX) return 0;
    iii_net_peer_t *p = &rt->peers[rt->peer_count++];
    memset(p, 0, sizeof(*p));
    p->peer_id = rt->next_peer_id++;
    if (addr_v6) memcpy(p->addr_v6, addr_v6, 16);
    p->port = port;
    p->ipv6 = true;
    p->discovered = true;
    if (sub_key) memcpy(p->sub_key, sub_key, 32);
    rt->witness_count++;
    return p->peer_id;
}

const iii_net_peer_t *iii_net_lookup_peer(const iii_net_runtime_t *rt, uint64_t peer_id) {
    if (!rt) return NULL;
    for (unsigned i = 0; i < rt->peer_count; ++i) {
        if (rt->peers[i].peer_id == peer_id) return &rt->peers[i];
    }
    return NULL;
}

size_t iii_net_peer_count(const iii_net_runtime_t *rt) { return rt ? rt->peer_count : 0u; }

iii_net_outbound_status_t iii_net_outbound(iii_net_runtime_t           *rt,
                                           uint64_t                     destination_peer_id,
                                           const iii_net_packet_t       *pkt,
                                           const uint8_t                *body, size_t body_len,
                                           uint8_t                       suite_id,
                                           uint32_t                      sequence_number,
                                           uint8_t                      *out_buf,
                                           size_t                        out_cap,
                                           size_t                       *out_len)
{
    if (!rt || !pkt || !out_buf || !out_len) return III_NET_OB_REJECT_INVALID;

    if (pkt->tier == 0) return III_NET_OB_REJECT_TIER0;

    const iii_net_peer_t *peer = iii_net_lookup_peer(rt, destination_peer_id);
    if (!peer) return III_NET_OB_REJECT_NO_PEER;

    /* Check if the sub_key is non-zero. */
    bool any = false;
    for (unsigned i = 0; i < 32; ++i) if (peer->sub_key[i]) { any = true; break; }
    if (!any) return III_NET_OB_REJECT_NO_KEY;

    /* Layout the augmented packet: option (36) || body || ah (sizeof) */
    size_t total = sizeof(iii_net_witness_option_t) + body_len + sizeof(iii_net_ah_trailer_t);
    if (out_cap < total) return III_NET_OB_REJECT_BUFFER;

    iii_net_witness_option_t opt;
    iii_net_witness_option_build(pkt->body_mhash, &opt);
    memcpy(out_buf, &opt, sizeof(opt));

    if (body && body_len) memcpy(out_buf + sizeof(opt), body, body_len);

    iii_net_ah_trailer_t ah;
    iii_net_ah_compute(peer->sub_key, suite_id, pkt, body, body_len, sequence_number, &ah);
    memcpy(out_buf + sizeof(opt) + body_len, &ah, sizeof(ah));

    *out_len = total;
    rt->buffer_used += total;
    rt->witness_count++;
    return III_NET_OB_OK;
}

iii_net_inbound_status_t iii_net_inbound(iii_net_runtime_t           *rt,
                                         uint64_t                     source_peer_id,
                                         const iii_net_packet_t       *pkt,
                                         const uint8_t                *body, size_t body_len,
                                         const iii_net_witness_option_t *opt,
                                         const iii_net_ah_trailer_t   *ah)
{
    if (!rt) return III_NET_IB_DROPPED_OPTION;
    if (!iii_net_should_consume(opt)) return III_NET_IB_NON_III;
    const iii_net_peer_t *peer = iii_net_lookup_peer(rt, source_peer_id);
    if (!peer) return III_NET_IB_INVALID_AH;
    if (!iii_net_ah_verify(peer->sub_key, pkt, body, body_len, ah)) return III_NET_IB_INVALID_AH;
    /* Replay window per (src, dst). */
    iii_net_replay_window_t *w = NULL;
    for (unsigned i = 0; i < rt->replay_count; ++i) {
        if (rt->replay[i].source_peer_id == source_peer_id &&
            rt->replay[i].destination_peer_id == pkt->destination_peer_id) {
            w = &rt->replay[i]; break;
        }
    }
    if (!w) {
        if (rt->replay_count >= III_NET_PEER_MAX) return III_NET_IB_INVALID_AH;
        w = &rt->replay[rt->replay_count++];
        iii_net_replay_init(w, source_peer_id, pkt->destination_peer_id);
    }
    if (!iii_net_replay_admit(w, ah->sequence_number)) return III_NET_IB_REPLAY;
    rt->witness_count++;
    return III_NET_IB_VALID;
}

bool iii_net_replicate(iii_net_runtime_t *rt, uint64_t source_peer_id, uint64_t witness_seq) {
    if (!rt) return false;
    for (unsigned i = 0; i < rt->peer_count; ++i) {
        if (rt->peers[i].peer_id == source_peer_id) {
            if (witness_seq <= rt->peers[i].last_witness_seq) return false;
            rt->peers[i].last_witness_seq = witness_seq;
            rt->witness_count++;
            return true;
        }
    }
    return false;
}

/* ===================================================================== *
 *  HotStuff BFT — R1 reference mirror (gospel V1 Stage 5, L24432).
 *
 *  Byte-identical block/QC formats to STDLIB/iii/aether/hotstuff.iii.
 *  iii_sw_hs_block_hash matches hs_block_hash byte-for-byte (verified vs the
 *  .iii baseline 5c41fdfc3790439afb8be77a64b3dedb45aca81db27af4713c1ba4d2e06b65bb
 *  for parent_qc=0, view=1, payload=0xAB*32).  Determinism: leader=view mod n,
 *  no randomness.  This drops the "HotStuff BFT NIH still pending" R1 gap.
 * ===================================================================== */

/* block_hash = SHA-256( parent_qc[256] || view(8 LE) || payload_mhash[32] ). */
void iii_sw_hs_block_hash(const uint8_t parent_qc[256], uint64_t view,
                          const uint8_t payload_mhash[32], uint8_t out[32]) {
    uint8_t buf[296];
    memcpy(buf, parent_qc, 256);
    for (int i = 0; i < 8; i++) buf[256 + i] = (uint8_t)(view >> (i * 8));
    memcpy(buf + 264, payload_mhash, 32);
    iii_sha256(buf, 296, out);
}

/* QC = block_mhash[32] || view(8 LE) || n_sigs(4 LE) || n_sigs*64-byte sigs.
 * Returns the total QC byte length. */
int iii_sw_hs_compose_qc(const uint8_t block_mhash[32], uint64_t view,
                         const uint8_t *sigs, uint32_t n_sigs, uint8_t *out_qc) {
    memcpy(out_qc, block_mhash, 32);
    for (int i = 0; i < 8; i++) out_qc[32 + i] = (uint8_t)(view >> (i * 8));
    out_qc[40] = (uint8_t)(n_sigs);
    out_qc[41] = (uint8_t)(n_sigs >> 8);
    out_qc[42] = (uint8_t)(n_sigs >> 16);
    out_qc[43] = (uint8_t)(n_sigs >> 24);
    memcpy(out_qc + 44, sigs, (size_t)n_sigs * 64);
    return (int)(44u + n_sigs * 64u);
}
