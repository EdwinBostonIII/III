/* III ZK-PRUNING — pruning engine and preservation list.
 *
 * Implements the closure-pinned preservation rules from spec §2.3 / §5.
 */
#include "iii/zk_prune.h"
#include "iii/sha256.h"

#include <stdlib.h>
#include <string.h>

/* Decode the 16-bit cycle kind from the big-endian 16-byte field
 * (low two bytes carry the kind). */
static uint16_t cycle_kind(const xii_witness_t *w) {
    return (uint16_t)((w->cycle_kind[14] << 8) | w->cycle_kind[15]);
}

int iiizk_is_preserved(const xii_witness_t *w) {
    if (!w) return 0;

    /* Flag-driven preservation. */
    if (w->flags & WITNESS_FLAGS_ANCHOR_AWARE)   return 1;
    if (w->flags & WITNESS_FLAGS_ROLLUP_WITNESS) return 1;
    if (w->flags & WITNESS_FLAGS_FIRST_OF_EPOCH) return 1;

    /* Cycle-kind-driven preservation (closure-pinned list, spec §5.1). */
    switch (cycle_kind(w)) {
        case XII_CYCLE_KIND_SUITE_SWAP:
        case XII_CYCLE_KIND_DRTM_RELAUNCH:
        case XII_CYCLE_KIND_AMENDMENT_T1:
        case XII_CYCLE_KIND_AMENDMENT_T2:
        case XII_CYCLE_KIND_AMENDMENT_T3:
        case XII_CYCLE_KIND_COMPROMISE_LOW:
        case XII_CYCLE_KIND_COMPROMISE_MEDIUM:
        case XII_CYCLE_KIND_COMPROMISE_HIGH:
        case XII_CYCLE_KIND_CATALYST_PROMOTE:
        case XII_CYCLE_KIND_EPOCH_BOUNDARY:
        case XII_CYCLE_KIND_FED_CONSTITUTIONAL:
            return 1;
        default:
            return 0;
    }
}

void iiizk_witness_mhash(const xii_witness_t *w, uint8_t out[32]) {
    iii_sha256((const uint8_t *)w, sizeof(*w), out);
}

int iiizk_chain_consistent(const xii_witness_t *stream, uint32_t n,
                           const uint8_t predecessor[32]) {
    if (!stream || n == 0) return 0;
    if (memcmp(stream[0].predecessor_mhash, predecessor, 32) != 0) return 0;
    uint8_t prev[32];
    iiizk_witness_mhash(&stream[0], prev);
    for (uint32_t i = 1; i < n; i++) {
        if (memcmp(stream[i].predecessor_mhash, prev, 32) != 0) return 0;
        iiizk_witness_mhash(&stream[i], prev);
    }
    return 1;
}

int iiizk_sidecar_build(const xii_witness_t *stream, uint32_t n,
                        const uint8_t predecessor[32],
                        iiizk_sidecar_t *out) {
    if (!stream || !out) return -2;
    if (n == 0) return -2;
    if (!iiizk_chain_consistent(stream, n, predecessor)) return -1;

    memset(out, 0, sizeof(*out));
    memcpy(out->predecessor_mhash, predecessor, 32);
    iiizk_witness_mhash(&stream[0], out->start_mhash);
    iiizk_witness_mhash(&stream[n - 1], out->end_mhash);
    out->window_count = n;

    /* Count preserved. */
    uint32_t pc = 0;
    for (uint32_t i = 0; i < n; i++) if (iiizk_is_preserved(&stream[i])) pc++;
    out->preserved_count = pc;
    out->preserved_mhashes = pc ? calloc(pc, 32) : NULL;

    uint32_t k = 0;
    for (uint32_t i = 0; i < n; i++) {
        if (iiizk_is_preserved(&stream[i])) {
            iiizk_witness_mhash(&stream[i], out->preserved_mhashes[k++]);
        }
    }

    /* Compaction ratio (Q14): how much was elided. */
    uint32_t elided = n - pc;
    uint64_t ratio  = ((uint64_t)elided << 14) / (n ? n : 1);
    if (ratio > 0xFFFF) ratio = 0xFFFF;
    out->compaction_ratio_q14 = (uint16_t)ratio;

    out->proof_system = 0;     /* default SNARK */

    iiizk_sidecar_root(out, out->body_hash);
    return 0;
}

void iiizk_sidecar_free(iiizk_sidecar_t *s) {
    if (!s) return;
    free(s->preserved_mhashes);
    s->preserved_mhashes = NULL;
    s->preserved_count   = 0;
}

void iiizk_sidecar_root(const iiizk_sidecar_t *sc, uint8_t out[32]) {
    iii_sha256_ctx_t c;
    iii_sha256_init(&c);
    iii_sha256_update(&c, sc->start_mhash, 32);
    iii_sha256_update(&c, sc->end_mhash, 32);
    iii_sha256_update(&c, sc->predecessor_mhash, 32);
    uint8_t hdr[10];
    hdr[0] = (uint8_t)(sc->window_count >> 24);
    hdr[1] = (uint8_t)(sc->window_count >> 16);
    hdr[2] = (uint8_t)(sc->window_count >> 8);
    hdr[3] = (uint8_t)(sc->window_count);
    hdr[4] = (uint8_t)(sc->preserved_count >> 24);
    hdr[5] = (uint8_t)(sc->preserved_count >> 16);
    hdr[6] = (uint8_t)(sc->preserved_count >> 8);
    hdr[7] = (uint8_t)(sc->preserved_count);
    hdr[8] = (uint8_t)(sc->compaction_ratio_q14 >> 8);
    hdr[9] = (uint8_t)(sc->compaction_ratio_q14);
    iii_sha256_update(&c, hdr, sizeof(hdr));
    iii_sha256_update(&c, &sc->proof_system, 1);
    for (uint32_t i = 0; i < sc->preserved_count; i++) {
        iii_sha256_update(&c, sc->preserved_mhashes[i], 32);
    }
    iii_sha256_final(&c, out);
}

void iiizk_rollup_witness(const iiizk_sidecar_t *sc,
                          uint64_t timestamp,
                          uint8_t mac_key[32],
                          xii_witness_t *out) {
    memset(out, 0, sizeof(*out));
    memcpy(out->predecessor_mhash, sc->predecessor_mhash, 32);
    out->timestamp_sequence_class = timestamp;
    /* Encode XII_CYCLE_KIND_ZK_ROLLUP into low two bytes of cycle_kind. */
    out->cycle_kind[14] = (uint8_t)(XII_CYCLE_KIND_ZK_ROLLUP >> 8);
    out->cycle_kind[15] = (uint8_t)(XII_CYCLE_KIND_ZK_ROLLUP);
    memcpy(out->payload_mhash, sc->body_hash, 32);

    /* flags: ROLLUP_WITNESS set; high 7 bits (57..63) carry compaction ratio
     * shifted: store top byte of Q14 ratio. */
    uint64_t flags = WITNESS_FLAGS_ROLLUP_WITNESS;
    uint64_t ratio_top = (uint64_t)(sc->compaction_ratio_q14 >> 9) & 0x7Full;
    flags |= ratio_top << 57;
    if (sc->proof_system == 1) flags |= WITNESS_FLAGS_ROLLUP_PROOF_STARK;
    out->flags = flags;

    /* MAC: HMAC-style: SHA-256(key || body-without-mac). */
    iii_sha256_ctx_t c;
    iii_sha256_init(&c);
    iii_sha256_update(&c, mac_key, 32);
    iii_sha256_update(&c, (const uint8_t *)out, sizeof(*out) - 32);
    iii_sha256_final(&c, out->mac);
}

int iiizk_rollup_verify(const xii_witness_t *rollup,
                        const iiizk_sidecar_t *sc,
                        const xii_witness_t *original_window, uint32_t n) {
    if (!rollup || !sc || !original_window) return -1;
    /* The rollup must reference the sidecar body. */
    if (memcmp(rollup->payload_mhash, sc->body_hash, 32) != 0) return -2;
    /* Cycle kind must be ZK_ROLLUP. */
    if (cycle_kind(rollup) != XII_CYCLE_KIND_ZK_ROLLUP) return -3;
    /* ROLLUP_WITNESS flag must be set. */
    if (!(rollup->flags & WITNESS_FLAGS_ROLLUP_WITNESS)) return -4;
    /* Window count must match. */
    if (sc->window_count != n) return -5;
    /* Predecessor must match. */
    if (memcmp(rollup->predecessor_mhash, sc->predecessor_mhash, 32) != 0) return -6;
    /* Re-derive body hash and compare. */
    uint8_t recomputed[32];
    iiizk_sidecar_root(sc, recomputed);
    if (memcmp(recomputed, sc->body_hash, 32) != 0) return -7;

    /* Re-extract preservation list from original window and check identity. */
    uint32_t k = 0;
    for (uint32_t i = 0; i < n; i++) {
        if (iiizk_is_preserved(&original_window[i])) {
            if (k >= sc->preserved_count) return -8;   /* too few */
            uint8_t h[32];
            iiizk_witness_mhash(&original_window[i], h);
            if (memcmp(h, sc->preserved_mhashes[k], 32) != 0) return -9;
            k++;
        }
    }
    if (k != sc->preserved_count) return -10;          /* too many */
    return 0;
}
