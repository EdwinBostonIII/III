/* III Crypto Agility — uniform API surface (DOCS/III-CRYPTO-AGILITY.md §1). */
#ifndef III_CRYPTO_H
#define III_CRYPTO_H

#include <stdint.h>
#include <stddef.h>
#include "iii/crypto_suites.h"

#ifdef __cplusplus
extern "C" {
#endif

/* ---- Status codes ------------------------------------------------------- */
typedef enum {
    III_CRYPTO_OK              = 0,
    III_CRYPTO_E_BAD_SUITE     = -1,
    III_CRYPTO_E_BAD_LEN       = -2,
    III_CRYPTO_E_VERIFY_FAIL   = -3,
    III_CRYPTO_E_TAG_MISMATCH  = -4,
    III_CRYPTO_E_INVALID_ARG   = -5,
    III_CRYPTO_E_SWAP_DENIED   = -6,
    III_CRYPTO_E_NOT_REGISTERED= -7
} iii_crypto_status_t;

/* ---- Key/IO sizing ------------------------------------------------------ */
/* Returns required buffer sizes for the given suite (any pointer may be NULL). */
int iii_crypto_sizes(iii_suite_id_t suite,
                     size_t *pk_bytes, size_t *sk_bytes,
                     size_t *sig_or_ct_bytes, size_t *ss_bytes);

const char *iii_crypto_suite_name(iii_suite_id_t suite);

/* ---- Uniform primitive operations -------------------------------------- */
/* keygen: produce (pk, sk) for sign/KEM suites. seed must be at least the
 * required entropy (32 B for classical, up to 96 B for SPHINCS+ 256s). */
int iii_crypto_keygen(iii_suite_id_t suite, const uint8_t *seed, size_t seed_len,
                      uint8_t *pk, uint8_t *sk);

/* AEAD seal/open. iv: 12 bytes (GCM/ChaCha-Poly nonce). */
int iii_crypto_aead_seal(iii_suite_id_t suite, const uint8_t *key, const uint8_t *iv,
                         const uint8_t *aad, size_t aad_len,
                         const uint8_t *pt, size_t pt_len,
                         uint8_t *ct, uint8_t tag[16]);
int iii_crypto_aead_open(iii_suite_id_t suite, const uint8_t *key, const uint8_t *iv,
                         const uint8_t *aad, size_t aad_len,
                         const uint8_t *ct, size_t ct_len,
                         const uint8_t tag[16], uint8_t *pt);

/* Generic encrypt/decrypt aliases (selects AEAD suite). */
int iii_crypto_encrypt(iii_suite_id_t suite, const uint8_t *key, const uint8_t *iv,
                       const uint8_t *aad, size_t aad_len,
                       const uint8_t *pt, size_t pt_len,
                       uint8_t *ct, uint8_t tag[16]);
int iii_crypto_decrypt(iii_suite_id_t suite, const uint8_t *key, const uint8_t *iv,
                       const uint8_t *aad, size_t aad_len,
                       const uint8_t *ct, size_t ct_len,
                       const uint8_t tag[16], uint8_t *pt);

/* Sign/verify. sig buffer must be sized via iii_crypto_sizes. */
int iii_crypto_sign(iii_suite_id_t suite, const uint8_t *sk,
                    const uint8_t *msg, size_t msglen,
                    uint8_t *sig, size_t *siglen);
int iii_crypto_verify(iii_suite_id_t suite, const uint8_t *pk,
                      const uint8_t *msg, size_t msglen,
                      const uint8_t *sig, size_t siglen);

/* KEM operations (ML-KEM). coins is 32 bytes for encaps (deterministic). */
int iii_crypto_kem_encaps(iii_suite_id_t suite, const uint8_t *pk,
                          const uint8_t coins[32], uint8_t *ct, uint8_t ss[32]);
int iii_crypto_kem_decaps(iii_suite_id_t suite, const uint8_t *sk,
                          const uint8_t *ct, uint8_t ss[32]);

/* ---- Tier-3 swap with rollback ledger (§5) ---------------------------- */
typedef struct iii_swap_entry {
    iii_suite_id_t old_suite;
    iii_suite_id_t new_suite;
    uint64_t       epoch;            /* monotonic swap counter */
    uint8_t        keymat_hash[32];  /* SHA-256 of supplied key material */
    uint8_t        founder_cosig[64];/* Ed25519 cosig over the swap directive; iii_crypto_swap rejects all-zero with E_SWAP_DENIED */
    int            committed;        /* 1 if swap committed, 0 if rolled back */
} iii_swap_entry_t;

typedef struct iii_swap_ledger {
    iii_swap_entry_t entries[64];
    size_t           count;
    iii_suite_id_t   active;
} iii_swap_ledger_t;

void iii_swap_ledger_init(iii_swap_ledger_t *L, iii_suite_id_t initial);
/* §5 swap: founder_cosig MUST be a valid Ed25519 signature, by the
 * Founder's-Anchor key `founder_pk`, over the canonical swap directive
 * "III-CRYPTO-SUITE-SWAP-V1" || old_suite_le2 || new_suite_le2 ||
 * epoch_le8 (epoch = the new entry's 1-based index).  iii_crypto_swap
 * Ed25519-verifies it and returns E_SWAP_DENIED on any verify failure
 * (was: a non-zero-byte presence check). */
int  iii_crypto_swap(iii_swap_ledger_t *L,
                     iii_suite_id_t old_suite, iii_suite_id_t new_suite,
                     const uint8_t *key_material, size_t keymat_len,
                     const uint8_t founder_pk[32],
                     const uint8_t founder_cosig[64]);
int  iii_crypto_swap_rollback(iii_swap_ledger_t *L);

#ifdef __cplusplus
}
#endif
#endif
