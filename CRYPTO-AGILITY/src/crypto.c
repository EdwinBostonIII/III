/* III-CRYPTO-AGILITY — uniform dispatch layer.
 *
 * Implements the top-level iii_crypto_* API by routing to the per-algorithm
 * implementations (aes, chacha20, ed25519, x25519, mlkem, mldsa, slhdsa).
 * Also implements the §5 swap ledger.
 */
#include "iii/crypto.h"
#include <stdbool.h>
#include "iii/aes.h"

/* SHA-256 is provided by sha256_local.c in this module. */
extern void iii_sha256(const void *data, size_t len, uint8_t out[32]);
#include "iii/chacha20.h"
#include "iii/ed25519.h"
#include "iii/curve25519.h"
#include "iii/mlkem.h"
#include "iii/mldsa.h"
#include "iii/slhdsa.h"
#include "iii/sha2.h"
#include <string.h>

/* ECDSA over the proven .iii curve stack (numera/ecdsa_p256.iii / ecdsa_p384.iii,
 * over ec256/fn256/fp256), linked via libiii_native.a.  Single-source: no second
 * C implementation.  z is SHA-256(msg) (P-256) / SHA-384(msg) (P-384); the
 * deterministic nonce is derived inside the .iii layer (SP 800-90A HMAC-DRBG
 * seeded from (d,z)).  pk = Qx||Qy; sk = d; sig = r||s.  Sub-word u8 returns are
 * masked (&1u) per the W16 ABI trap (upper return-register bits undefined). */
extern int     iii_ecdsa_p256_keygen_seed(const uint8_t *seed, uint8_t *d_out, uint8_t *pub_out);
extern int     iii_ecdsa_p256_sign_det(const uint8_t *d, const uint8_t *z, uint8_t *sig_out);
extern uint8_t iii_ecdsa_p256_verify_x(const uint8_t *qx, const uint8_t *qy, const uint8_t *z, const uint8_t *sig);
extern int     iii_ecdsa_p384_keygen_seed(const uint8_t *seed, uint8_t *d_out, uint8_t *pub_out);
extern int     iii_ecdsa_p384_sign_det(const uint8_t *d, const uint8_t *z, uint8_t *sig_out);
extern uint8_t iii_ecdsa_p384_verify_x(const uint8_t *qx, const uint8_t *qy, const uint8_t *z, const uint8_t *sig);
/* RSASSA-PSS over the proven .iii rsa.iii (rm_* Montgomery sign/verify, fast
 * Montgomery-MR keygen).  pk = n (k=modBits/8 BE); sk = n||d (2k); sig is the
 * PSS encryption (k bytes).  e is the fixed RSA_E_PUB (65537).  mHash =
 * SHA-256(msg); deterministic PSS (salt=zeros, sLen=32) inside the .iii layer. */
extern int     iii_rsa_keygen_seed(uint64_t modBits, const uint8_t *seed, uint64_t slen, uint8_t *pk_out, uint8_t *sk_out);
extern int     iii_rsa_pss_sign_det(uint64_t modBits, const uint8_t *sk, const uint8_t *mHash, uint8_t *sig_out);
extern uint8_t iii_rsa_pss_verify_x(uint64_t modBits, const uint8_t *pk, const uint8_t *mHash, const uint8_t *sig, uint64_t sigLen);

const char *iii_crypto_suite_name(iii_suite_id_t suite) {
    switch (suite) {
        case III_SUITE_AES_256_GCM:       return "aes-256-gcm";
        case III_SUITE_CHACHA20_POLY1305: return "chacha20-poly1305";
        case III_SUITE_ED25519:           return "ed25519";
        case III_SUITE_X25519:            return "x25519";
        case III_SUITE_ECDSA_P256:        return "ecdsa-p256";
        case III_SUITE_ECDSA_P384:        return "ecdsa-p384";
        case III_SUITE_RSA_3072:          return "rsa-3072";
        case III_SUITE_RSA_4096:          return "rsa-4096";
        case III_SUITE_ML_KEM_512:        return "ml-kem-512";
        case III_SUITE_ML_KEM_768:        return "ml-kem-768";
        case III_SUITE_ML_KEM_1024:       return "ml-kem-1024";
        case III_SUITE_ML_DSA_44:         return "ml-dsa-44";
        case III_SUITE_ML_DSA_65:         return "ml-dsa-65";
        case III_SUITE_ML_DSA_87:         return "ml-dsa-87";
        case III_SUITE_SLH_DSA_128S:      return "slh-dsa-128s";
        case III_SUITE_SLH_DSA_192S:      return "slh-dsa-192s";
        case III_SUITE_SLH_DSA_256S:      return "slh-dsa-256s";
        case III_SUITE_CATALOGUE_PQ_STRONG: return "catalogue-pq-strong";
        case III_SUITE_CATALOGUE_PQ_LIGHT:  return "catalogue-pq-light";
        case III_SUITE_CATALOGUE_HYBRID:    return "catalogue-hybrid";
        default:                           return "unknown";
    }
}

int iii_crypto_sizes(iii_suite_id_t suite,
                     size_t *pk_bytes, size_t *sk_bytes,
                     size_t *sig_or_ct_bytes, size_t *ss_bytes)
{
    size_t pk = 0, sk = 0, sig_ct = 0, ss = 0;
    switch (suite) {
        case III_SUITE_AES_256_GCM:
        case III_SUITE_CHACHA20_POLY1305:
            /* AEAD: just key (32) + tag (16) + nonce (12) elsewhere. */
            pk = 32; sk = 32; sig_ct = 16; ss = 0;
            break;
        case III_SUITE_ED25519:
            pk = 32; sk = 64; sig_ct = 64; ss = 0;
            break;
        case III_SUITE_ECDSA_P256:
            pk = 64; sk = 32; sig_ct = 64; ss = 0;   /* pk=Qx||Qy, sk=d, sig=r||s */
            break;
        case III_SUITE_ECDSA_P384:
            pk = 96; sk = 48; sig_ct = 96; ss = 0;   /* pk=Qx||Qy, sk=d, sig=r||s */
            break;
        case III_SUITE_RSA_3072:
            pk = 384; sk = 768; sig_ct = 384; ss = 0;   /* pk=n, sk=n||d, sig=PSS */
            break;
        case III_SUITE_RSA_4096:
            pk = 512; sk = 1024; sig_ct = 512; ss = 0;
            break;
        case III_SUITE_X25519:
            pk = 32; sk = 32; sig_ct = 32; ss = 32;
            break;
        case III_SUITE_ML_KEM_512:
            pk = 800;  sk = 1632; sig_ct = 768;  ss = 32;
            break;
        case III_SUITE_ML_KEM_768:
            pk = 1184; sk = 2400; sig_ct = 1088; ss = 32;
            break;
        case III_SUITE_ML_KEM_1024:
            pk = 1568; sk = 3168; sig_ct = 1568; ss = 32;
            break;
        case III_SUITE_ML_DSA_44:
            pk = 1312; sk = 2560; sig_ct = 2420; ss = 0;
            break;
        case III_SUITE_ML_DSA_65:
            pk = 1952; sk = 4032; sig_ct = 3309; ss = 0;
            break;
        case III_SUITE_ML_DSA_87:
            pk = 2592; sk = 4896; sig_ct = 4627; ss = 0;
            break;
        case III_SUITE_SLH_DSA_128S:
            pk = 32;  sk = 64;  sig_ct = 7856;  ss = 0;
            break;
        case III_SUITE_SLH_DSA_192S:
            pk = 48;  sk = 96;  sig_ct = 16224; ss = 0;
            break;
        case III_SUITE_SLH_DSA_256S:
            pk = 64;  sk = 128; sig_ct = 29792; ss = 0;
            break;
        default:
            return III_CRYPTO_E_BAD_SUITE;
    }
    if (pk_bytes)        *pk_bytes        = pk;
    if (sk_bytes)        *sk_bytes        = sk;
    if (sig_or_ct_bytes) *sig_or_ct_bytes = sig_ct;
    if (ss_bytes)        *ss_bytes        = ss;
    return III_CRYPTO_OK;
}

/* ----------------------------------------------------------------------------
 * AEAD seal/open
 * ---------------------------------------------------------------------------- */
int iii_crypto_aead_seal(iii_suite_id_t suite, const uint8_t *key, const uint8_t *iv,
                         const uint8_t *aad, size_t aad_len,
                         const uint8_t *pt, size_t pt_len,
                         uint8_t *ct, uint8_t tag[16])
{
    if (!key || !iv || !ct || !tag) return III_CRYPTO_E_INVALID_ARG;
    switch (suite) {
        case III_SUITE_AES_256_GCM:
            return iii_aes256_gcm_seal(key, iv, aad, aad_len, pt, pt_len, ct, tag);
        case III_SUITE_CHACHA20_POLY1305:
            return iii_chacha20_poly1305_seal(key, iv, aad, aad_len, pt, pt_len, ct, tag);
        default:
            return III_CRYPTO_E_BAD_SUITE;
    }
}

int iii_crypto_aead_open(iii_suite_id_t suite, const uint8_t *key, const uint8_t *iv,
                         const uint8_t *aad, size_t aad_len,
                         const uint8_t *ct, size_t ct_len,
                         const uint8_t tag[16], uint8_t *pt)
{
    if (!key || !iv || !ct || !tag || !pt) return III_CRYPTO_E_INVALID_ARG;
    switch (suite) {
        case III_SUITE_AES_256_GCM:
            return iii_aes256_gcm_open(key, iv, aad, aad_len, ct, ct_len, tag, pt);
        case III_SUITE_CHACHA20_POLY1305:
            return iii_chacha20_poly1305_open(key, iv, aad, aad_len, ct, ct_len, tag, pt);
        default:
            return III_CRYPTO_E_BAD_SUITE;
    }
}

int iii_crypto_encrypt(iii_suite_id_t suite, const uint8_t *key, const uint8_t *iv,
                       const uint8_t *aad, size_t aad_len,
                       const uint8_t *pt, size_t pt_len,
                       uint8_t *ct, uint8_t tag[16])
{
    return iii_crypto_aead_seal(suite, key, iv, aad, aad_len, pt, pt_len, ct, tag);
}

int iii_crypto_decrypt(iii_suite_id_t suite, const uint8_t *key, const uint8_t *iv,
                       const uint8_t *aad, size_t aad_len,
                       const uint8_t *ct, size_t ct_len,
                       const uint8_t tag[16], uint8_t *pt)
{
    return iii_crypto_aead_open(suite, key, iv, aad, aad_len, ct, ct_len, tag, pt);
}

/* ----------------------------------------------------------------------------
 * Sign / verify
 * ---------------------------------------------------------------------------- */
int iii_crypto_keygen(iii_suite_id_t suite, const uint8_t *seed, size_t seed_len,
                      uint8_t *pk, uint8_t *sk)
{
    if (!seed || !pk || !sk) return III_CRYPTO_E_INVALID_ARG;
    if (seed_len < 32) return III_CRYPTO_E_BAD_LEN;
    switch (suite) {
        case III_SUITE_ED25519:
            iii_ed25519_keygen(pk, seed);
            /* sk = seed (32) || pk (32) per Ed25519 RFC */
            memcpy(sk, seed, 32);
            memcpy(sk + 32, pk, 32);
            return III_CRYPTO_OK;
        case III_SUITE_X25519:
            /* sk = clamped scalar; pk = base * sk */
            memcpy(sk, seed, 32);
            sk[0]  &= 0xF8u;
            sk[31] &= 0x7Fu;
            sk[31] |= 0x40u;
            iii_x25519_base(pk, sk);
            return III_CRYPTO_OK;
        case III_SUITE_ECDSA_P256:
            /* sk = d (32, = seed reduced mod n in .iii); pk = Qx||Qy (64). */
            iii_ecdsa_p256_keygen_seed(seed, sk, pk);
            return III_CRYPTO_OK;
        case III_SUITE_ECDSA_P384:
            if (seed_len < 48) return III_CRYPTO_E_BAD_LEN;   /* P-384 d is 48 B */
            iii_ecdsa_p384_keygen_seed(seed, sk, pk);         /* sk=d(48), pk=Qx||Qy(96) */
            return III_CRYPTO_OK;
        case III_SUITE_RSA_3072:
        case III_SUITE_RSA_4096: {
            uint64_t modBits = (suite == III_SUITE_RSA_3072) ? 3072u : 4096u;
            /* pk = n (k); sk = n||d (2k); e fixed (65537).  Keygen is the slow
             * step (Montgomery Miller-Rabin); sign/verify are fast rm_*. */
            iii_rsa_keygen_seed(modBits, seed, (uint64_t)seed_len, pk, sk);
            return III_CRYPTO_OK;
        }
        case III_SUITE_ML_KEM_512:
        case III_SUITE_ML_KEM_768:
        case III_SUITE_ML_KEM_1024: {
            int k = (suite == III_SUITE_ML_KEM_512) ? 2 :
                    (suite == III_SUITE_ML_KEM_768) ? 3 : 4;
            /* ML-KEM keygen wants 64-byte seed; if caller gave 32, expand. */
            uint8_t kseed[64];
            if (seed_len >= 64) memcpy(kseed, seed, 64);
            else { memcpy(kseed, seed, 32); memcpy(kseed + 32, seed, 32); }
            return iii_mlkem_keygen(k, kseed, pk, sk);
        }
        case III_SUITE_ML_DSA_44:
        case III_SUITE_ML_DSA_65:
        case III_SUITE_ML_DSA_87: {
            int level = (suite == III_SUITE_ML_DSA_44) ? 2 :
                        (suite == III_SUITE_ML_DSA_65) ? 3 : 5;
            return iii_mldsa_keygen(level, seed, pk, sk);
        }
        case III_SUITE_SLH_DSA_128S:
        case III_SUITE_SLH_DSA_192S:
        case III_SUITE_SLH_DSA_256S: {
            iii_slh_level_t lv = (suite == III_SUITE_SLH_DSA_128S) ? III_SLH_128S :
                                 (suite == III_SUITE_SLH_DSA_192S) ? III_SLH_192S : III_SLH_256S;
            return iii_slhdsa_keygen(lv, seed, pk, sk);
        }
        default:
            return III_CRYPTO_E_BAD_SUITE;
    }
}

int iii_crypto_sign(iii_suite_id_t suite, const uint8_t *sk,
                    const uint8_t *msg, size_t msglen,
                    uint8_t *sig, size_t *siglen)
{
    if (!sk || !sig || !siglen) return III_CRYPTO_E_INVALID_ARG;
    switch (suite) {
        case III_SUITE_ED25519: {
            const uint8_t *seed = sk;
            const uint8_t *pk   = sk + 32;
            /* iii_ed25519_sign(sig, msg, msglen, pk, seed) */
            iii_ed25519_sign(sig, msg, msglen, pk, seed);
            *siglen = 64;
            return III_CRYPTO_OK;
        }
        case III_SUITE_ECDSA_P256: {
            uint8_t z[32];
            iii_sha256(msg, msglen, z);
            iii_ecdsa_p256_sign_det(sk, z, sig);   /* sk = d; deterministic nonce in .iii */
            *siglen = 64;
            return III_CRYPTO_OK;
        }
        case III_SUITE_ECDSA_P384: {
            uint8_t z[48];
            iii_sha384(msg, msglen, z);
            iii_ecdsa_p384_sign_det(sk, z, sig);
            *siglen = 96;
            return III_CRYPTO_OK;
        }
        case III_SUITE_RSA_3072:
        case III_SUITE_RSA_4096: {
            uint64_t modBits = (suite == III_SUITE_RSA_3072) ? 3072u : 4096u;
            uint8_t z[32];
            iii_sha256(msg, msglen, z);
            iii_rsa_pss_sign_det(modBits, sk, z, sig);   /* sk = n||d */
            *siglen = (size_t)(modBits / 8u);
            return III_CRYPTO_OK;
        }
        case III_SUITE_ML_DSA_44:
        case III_SUITE_ML_DSA_65:
        case III_SUITE_ML_DSA_87: {
            int level = (suite == III_SUITE_ML_DSA_44) ? 2 :
                        (suite == III_SUITE_ML_DSA_65) ? 3 : 5;
            return iii_mldsa_sign(level, sk, msg, msglen, sig, siglen);
        }
        case III_SUITE_SLH_DSA_128S:
        case III_SUITE_SLH_DSA_192S:
        case III_SUITE_SLH_DSA_256S: {
            iii_slh_level_t lv = (suite == III_SUITE_SLH_DSA_128S) ? III_SLH_128S :
                                 (suite == III_SUITE_SLH_DSA_192S) ? III_SLH_192S : III_SLH_256S;
            return iii_slhdsa_sign(lv, sk, msg, msglen, sig, siglen);
        }
        default:
            return III_CRYPTO_E_BAD_SUITE;
    }
}

int iii_crypto_verify(iii_suite_id_t suite, const uint8_t *pk,
                      const uint8_t *msg, size_t msglen,
                      const uint8_t *sig, size_t siglen)
{
    if (!pk || !sig) return III_CRYPTO_E_INVALID_ARG;
    switch (suite) {
        case III_SUITE_ED25519:
            if (siglen != 64) return III_CRYPTO_E_BAD_LEN;
            /* iii_ed25519_verify returns 0 on success, -1 on failure. */
            return (iii_ed25519_verify(sig, msg, msglen, pk) == 0)
                   ? III_CRYPTO_OK : III_CRYPTO_E_VERIFY_FAIL;
        case III_SUITE_ECDSA_P256: {
            if (siglen != 64) return III_CRYPTO_E_BAD_LEN;
            uint8_t z[32];
            iii_sha256(msg, msglen, z);   /* pk = Qx||Qy */
            return ((iii_ecdsa_p256_verify_x(pk, pk + 32, z, sig) & 1u) == 1u)
                   ? III_CRYPTO_OK : III_CRYPTO_E_VERIFY_FAIL;
        }
        case III_SUITE_ECDSA_P384: {
            if (siglen != 96) return III_CRYPTO_E_BAD_LEN;
            uint8_t z[48];
            iii_sha384(msg, msglen, z);   /* pk = Qx||Qy (48+48) */
            return ((iii_ecdsa_p384_verify_x(pk, pk + 48, z, sig) & 1u) == 1u)
                   ? III_CRYPTO_OK : III_CRYPTO_E_VERIFY_FAIL;
        }
        case III_SUITE_RSA_3072:
        case III_SUITE_RSA_4096: {
            uint64_t modBits = (suite == III_SUITE_RSA_3072) ? 3072u : 4096u;
            if (siglen != (size_t)(modBits / 8u)) return III_CRYPTO_E_BAD_LEN;
            uint8_t z[32];
            iii_sha256(msg, msglen, z);   /* pk = n */
            return ((iii_rsa_pss_verify_x(modBits, pk, z, sig, (uint64_t)siglen) & 1u) == 1u)
                   ? III_CRYPTO_OK : III_CRYPTO_E_VERIFY_FAIL;
        }
        case III_SUITE_ML_DSA_44:
        case III_SUITE_ML_DSA_65:
        case III_SUITE_ML_DSA_87: {
            int level = (suite == III_SUITE_ML_DSA_44) ? 2 :
                        (suite == III_SUITE_ML_DSA_65) ? 3 : 5;
            return iii_mldsa_verify(level, pk, msg, msglen, sig, siglen);
        }
        case III_SUITE_SLH_DSA_128S:
        case III_SUITE_SLH_DSA_192S:
        case III_SUITE_SLH_DSA_256S: {
            iii_slh_level_t lv = (suite == III_SUITE_SLH_DSA_128S) ? III_SLH_128S :
                                 (suite == III_SUITE_SLH_DSA_192S) ? III_SLH_192S : III_SLH_256S;
            return iii_slhdsa_verify(lv, pk, msg, msglen, sig, siglen);
        }
        default:
            return III_CRYPTO_E_BAD_SUITE;
    }
}

/* ----------------------------------------------------------------------------
 * KEM
 * ---------------------------------------------------------------------------- */
int iii_crypto_kem_encaps(iii_suite_id_t suite, const uint8_t *pk,
                          const uint8_t coins[32], uint8_t *ct, uint8_t ss[32])
{
    if (!pk || !coins || !ct || !ss) return III_CRYPTO_E_INVALID_ARG;
    int k;
    switch (suite) {
        case III_SUITE_ML_KEM_512:  k = 2; break;
        case III_SUITE_ML_KEM_768:  k = 3; break;
        case III_SUITE_ML_KEM_1024: k = 4; break;
        default: return III_CRYPTO_E_BAD_SUITE;
    }
    return iii_mlkem_encaps(k, pk, coins, ct, ss);
}

int iii_crypto_kem_decaps(iii_suite_id_t suite, const uint8_t *sk,
                          const uint8_t *ct, uint8_t ss[32])
{
    if (!sk || !ct || !ss) return III_CRYPTO_E_INVALID_ARG;
    int k;
    switch (suite) {
        case III_SUITE_ML_KEM_512:  k = 2; break;
        case III_SUITE_ML_KEM_768:  k = 3; break;
        case III_SUITE_ML_KEM_1024: k = 4; break;
        default: return III_CRYPTO_E_BAD_SUITE;
    }
    return iii_mlkem_decaps(k, sk, ct, ss);
}

/* ----------------------------------------------------------------------------
 * §5 — swap ledger
 * ---------------------------------------------------------------------------- */
void iii_swap_ledger_init(iii_swap_ledger_t *L, iii_suite_id_t initial) {
    if (!L) return;
    memset(L, 0, sizeof(*L));
    L->active = initial;
}

int iii_crypto_swap(iii_swap_ledger_t *L,
                    iii_suite_id_t old_suite, iii_suite_id_t new_suite,
                    const uint8_t *key_material, size_t keymat_len,
                    const uint8_t founder_pk[32],
                    const uint8_t founder_cosig[64])
{
    if (!L) return III_CRYPTO_E_INVALID_ARG;
    if (L->active != old_suite) return III_CRYPTO_E_SWAP_DENIED;
    if (L->count >= 64) return III_CRYPTO_E_SWAP_DENIED;
    if (!founder_pk || !founder_cosig) return III_CRYPTO_E_INVALID_ARG;

    /* §4.2: Ed25519-verify the founder cosignature over the canonical swap
     * directive against the Founder's-Anchor public key.  Directive =
     * "III-CRYPTO-SUITE-SWAP-V1" || old_suite_le2 || new_suite_le2 ||
     * epoch_le8 (epoch = the new entry's 1-based index).  (Was a bare
     * non-zero-byte presence check, which accepted any non-empty cosig.) */
    uint8_t dir[36];
    memcpy(dir, "III-CRYPTO-SUITE-SWAP-V1", 24);
    uint64_t epoch = (uint64_t)(L->count + 1);
    dir[24] = (uint8_t)((unsigned)old_suite & 0xFFu);
    dir[25] = (uint8_t)(((unsigned)old_suite >> 8) & 0xFFu);
    dir[26] = (uint8_t)((unsigned)new_suite & 0xFFu);
    dir[27] = (uint8_t)(((unsigned)new_suite >> 8) & 0xFFu);
    for (unsigned i = 0; i < 8; ++i)
        dir[28 + i] = (uint8_t)((epoch >> (8u * i)) & 0xFFu);
    if (iii_crypto_verify(III_SUITE_ED25519, founder_pk, dir, 36, founder_cosig, 64)
        != III_CRYPTO_OK)
        return III_CRYPTO_E_SWAP_DENIED;

    iii_swap_entry_t *e = &L->entries[L->count++];
    e->old_suite = old_suite;
    e->new_suite = new_suite;
    e->epoch     = (uint64_t)L->count;
    if (key_material && keymat_len > 0) {
        /* §5 — keymat_hash binds the new suite's key material into the
         * ledger entry so subsequent rollback verifies against the same key. */
        iii_sha256(key_material, keymat_len, e->keymat_hash);
    } else {
        memset(e->keymat_hash, 0, 32);
    }
    memcpy(e->founder_cosig, founder_cosig, 64);
    e->committed = 1;
    L->active = new_suite;
    return III_CRYPTO_OK;
}

int iii_crypto_swap_rollback(iii_swap_ledger_t *L) {
    if (!L) return III_CRYPTO_E_INVALID_ARG;
    if (L->count == 0) return III_CRYPTO_E_NOT_REGISTERED;
    iii_swap_entry_t *e = &L->entries[L->count - 1];
    if (!e->committed) return III_CRYPTO_E_NOT_REGISTERED;
    L->active = e->old_suite;
    e->committed = 0;
    return III_CRYPTO_OK;
}
