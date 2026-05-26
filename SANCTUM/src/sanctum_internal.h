#ifndef III_SANCTUM_INTERNAL_H
#define III_SANCTUM_INTERNAL_H
#include "iii/sanctum.h"

void iii_sha256(const void *data, size_t len, uint8_t out[32]);
void iii_hmac_sha256(const uint8_t *key, size_t key_len,
                     const uint8_t *msg, size_t msg_len,
                     uint8_t        out[32]);
void iii_hkdf_sha256(const uint8_t *ikm,  size_t ikm_len,
                     const uint8_t *salt, size_t salt_len,
                     const uint8_t *info, size_t info_len,
                     uint8_t       *okm,  size_t okm_len);

struct iii_sanctum_seal_binding {
    bool                   bound;
    iii_sanctum_seal_fn    fn;
    void                  *user;
    bool                   specialized;
    uint64_t               call_count;
};

struct iii_sanctum_runtime {
    /* §1 — sealed-call binding table */
    struct iii_sanctum_seal_binding seals[XII_SANCTUM_SEAL_COUNT];

    /* §4 — DRTM quote chain */
    iii_drtm_quote_t  *quotes;
    size_t             quote_count;
    size_t             quote_cap;
    uint64_t           epoch;
    uint8_t            silicon_fingerprint[32];

    /* §5 — Phantom NVRAM */
    iii_pfs_entry_t   *pfs;
    size_t             pfs_count;

    /* Phoenix bookmarks */
    iii_phoenix_bookmark_t *phoenix;
    size_t                  phoenix_count;
    uint64_t                phoenix_next_id;

    /* Cycle-table mhash field — caller updates via direct struct write (this
     * is internal) when the live cycle table commits a new entry; the next
     * DRTM relaunch incorporates it into the quote. */
    uint8_t            cycle_table_mhash[32];
    uint8_t            hexad_bitmap_mhash[32];
    uint8_t            observatory_mhash[32];
    uint8_t            federation_members_mhash[32];
    uint8_t            spec_root_R1[32];

    /* Master sub-key from which CRCC keys derive */
    uint8_t            master_subkey[32];

    /* Per-CPU sanctum frame ID counter */
    uint64_t           next_frame_id;

    /* Total dispatched calls */
    uint64_t           call_count;
};

#endif
