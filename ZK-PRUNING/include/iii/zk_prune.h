/* III ZK-PRUNING — pruning engine and preservation list.
 *
 * Per the III-ZK-PRUNING spec §2.3 / §5, certain witness payload kinds
 * MUST NEVER be elided by a rollup.  This header enumerates them and
 * exposes the witness-stream rollup engine.
 */
#ifndef III_ZK_PRUNE_H
#define III_ZK_PRUNE_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/* XII cycle kinds referenced by the spec.  Closure-pinned values. */
#define XII_CYCLE_KIND_NORMAL              0x0000
#define XII_CYCLE_KIND_REQUEST_PROCESS     0x0010
#define XII_CYCLE_KIND_ZK_ROLLUP           0x0240
#define XII_CYCLE_KIND_SUITE_SWAP          0x0140
#define XII_CYCLE_KIND_DRTM_RELAUNCH       0x0150
#define XII_CYCLE_KIND_AMENDMENT_T1        0x0180
#define XII_CYCLE_KIND_AMENDMENT_T2        0x0181
#define XII_CYCLE_KIND_AMENDMENT_T3        0x0182
#define XII_CYCLE_KIND_COMPROMISE_LOW      0x0190
#define XII_CYCLE_KIND_COMPROMISE_MEDIUM   0x0191
#define XII_CYCLE_KIND_COMPROMISE_HIGH     0x0192
#define XII_CYCLE_KIND_CATALYST_PROMOTE    0x01A0
#define XII_CYCLE_KIND_EPOCH_BOUNDARY      0x01B0
#define XII_CYCLE_KIND_FED_CONSTITUTIONAL  0x01C0

/* Witness flags (subset relevant to pruning). */
#define WITNESS_FLAGS_ANCHOR_AWARE         (1ull << 32)
#define WITNESS_FLAGS_ROLLUP_WITNESS       (1ull << 40)
#define WITNESS_FLAGS_FIRST_OF_EPOCH       (1ull << 48)
#define WITNESS_FLAGS_ROLLUP_PROOF_STARK   (1ull << 35)

/* Compaction-ratio threshold (Q14 fixed point), spec §7.2. */
#define XII_ZK_COMPACTION_RATIO_THRESHOLD  15564u   /* ~0.95 in Q14 */

/* 128-byte XiiWitness (spec §1.2). */
typedef struct {
    uint8_t  predecessor_mhash[32];
    uint64_t timestamp_sequence_class;
    uint8_t  cycle_kind[16];               /* big-endian; low 16 bits are kind */
    uint8_t  payload_mhash[32];
    uint64_t flags;
    uint8_t  mac[32];
} xii_witness_t;

/* Returns 1 if the witness MUST be preserved uncompressed. */
int iiizk_is_preserved(const xii_witness_t *w);

/* Compute the witness's mhash (SHA-256 of the 128-byte body). */
void iiizk_witness_mhash(const xii_witness_t *w, uint8_t out[32]);

/* Verify a witness stream's internal chain consistency:
 *   ∀ i ∈ [1..n-1]:  w[i].predecessor_mhash == mhash(w[i-1])
 * predecessor_mhash for w[0] must equal `predecessor`.
 */
int iiizk_chain_consistent(const xii_witness_t *stream, uint32_t n,
                           const uint8_t predecessor[32]);

/* Rollup sidecar — preservation list + window boundaries. */
typedef struct {
    uint8_t  start_mhash[32];
    uint8_t  end_mhash[32];
    uint8_t  predecessor_mhash[32];
    uint32_t window_count;
    uint32_t preserved_count;
    uint8_t (*preserved_mhashes)[32];      /* size preserved_count */
    uint16_t compaction_ratio_q14;
    uint8_t  proof_system;                 /* 0=SNARK, 1=STARK */
    uint8_t  body_hash[32];                /* hash over the whole sidecar body */
} iiizk_sidecar_t;

/* Build a rollup sidecar from a witness window.  Performs preservation-list
 * extraction and chain-consistency check.  On success, allocates
 * `preserved_mhashes`; caller frees with iiizk_sidecar_free.
 *
 * Returns 0 on success, non-zero on protocol violation:
 *   -1 — predecessor mismatch / chain break
 *   -2 — empty window
 */
int iiizk_sidecar_build(const xii_witness_t *stream, uint32_t n,
                        const uint8_t predecessor[32],
                        iiizk_sidecar_t *out);
void iiizk_sidecar_free(iiizk_sidecar_t *s);

/* Build a rollup witness for the given window + sidecar.  The rollup
 * witness payload_mhash is set to `sidecar.body_hash`. */
void iiizk_rollup_witness(const iiizk_sidecar_t *sc,
                          uint64_t timestamp,
                          uint8_t mac_key[32],
                          xii_witness_t *out);

/* Verify a rollup against the original window (decompression-side check).
 * Returns 0 on success.  Rejects rollups whose preservation list is
 * incomplete (per spec §5.2). */
int iiizk_rollup_verify(const xii_witness_t *rollup,
                        const iiizk_sidecar_t *sc,
                        const xii_witness_t *original_window, uint32_t n);

/* Determinism root: SHA-256 over canonically serialised sidecar body. */
void iiizk_sidecar_root(const iiizk_sidecar_t *sc, uint8_t out[32]);

#ifdef __cplusplus
}
#endif
#endif
