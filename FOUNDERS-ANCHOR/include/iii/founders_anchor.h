/* ============================================================================
 * III-FOUNDERS-ANCHOR — Structural Veto Layer (R-3)
 * Spec: III-FOUNDERS-ANCHOR.md  (Wave 0.5, item 178)
 *
 * The Anchor is the operator's permanent unilateral veto over Tier-3
 * amendments.  It exists at the proof-kernel level (R-3, deeper than R-2)
 * and is structurally un-amendable — removing it would change the
 * substrate's R1 root and fork its identity.
 *
 * Implements:
 *   §1 — anchor public key + fingerprint (closure-pinned)
 *   §2 — the seven unilateral authorities
 *   §3/§4 — protocol-level un-amendability rules
 *   §6 — Shamir-split secret-key custody (3-of-3 threshold)
 * ============================================================================
 */
#ifndef III_FOUNDERS_ANCHOR_H
#define III_FOUNDERS_ANCHOR_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* §1.2 — closure-pinned public key + fingerprint.  In a sealed build these
 * are populated from the air-gapped key generation; we expose setters to
 * allow tests to drive the runtime. */
extern const uint8_t III_FOUNDERS_ANCHOR_PUBLIC_KEY_DEFAULT[32];

typedef struct iii_anchor_identity {
    uint8_t  public_key[32];
    uint8_t  fingerprint[32];
    uint16_t suite_id;            /* 0x0001 = Ed25519 at genesis */
    bool     frozen;              /* §4.1 — LEXICON-frozen */
} iii_anchor_identity_t;

void iii_anchor_compute_fingerprint(const uint8_t public_key[32], uint8_t out[32]);

/* §2 — the seven authorities */
typedef enum iii_anchor_authority {
    III_AA_NONE                       = 0,
    III_AA_TIER3_VETO                 = 1,
    III_AA_DRTM_RESET                 = 2,
    III_AA_PFS_DENY_QUOTE             = 3,
    III_AA_SUITE_SWAP_COSIGN          = 4,
    III_AA_WITNESS_INJECT             = 5,
    III_AA_CATALYST_HALT              = 6,
    III_AA_REVOKE_PROMOTION           = 7
} iii_anchor_authority_t;

const char *iii_anchor_authority_name(iii_anchor_authority_t a);

/* §2.3 — pfs_deny target / reason */
typedef enum iii_pfs_deny_target_kind {
    III_PFS_DT_SEALED_CYCLE_BOX     = 0,
    III_PFS_DT_WITNESS_CHAIN        = 1,
    III_PFS_DT_FEDERATION_MESSAGE   = 2,
    III_PFS_DT_CATALYST_PROMOTION   = 3,
    III_PFS_DT_MODULE               = 4,
    III_PFS_DT_PEER                 = 5
} iii_pfs_deny_target_kind_t;

typedef enum iii_pfs_deny_reason {
    III_PFS_DR_COMPROMISED            = 0,
    III_PFS_DR_INCONSISTENT           = 1,
    III_PFS_DR_OPERATOR_REVOKE        = 2,
    III_PFS_DR_LEGAL_HOLD             = 3,
    III_PFS_DR_OPERATIONAL_EMERGENCY  = 4
} iii_pfs_deny_reason_t;

/* §2.7 — revoke cascade */
typedef enum iii_revoke_cascade {
    III_RC_NONE                = 0,
    III_RC_REVOKE_DESCENDANTS  = 1,
    III_RC_REVOKE_ALL_DERIVATIVES = 2
} iii_revoke_cascade_t;

/* §1.1 — Shamir 3-of-3 split (every share required to reconstruct). */
#define III_ANCHOR_SHARES_TOTAL  3u
#define III_ANCHOR_SHARES_NEEDED 3u

typedef struct iii_anchor_share {
    uint8_t share_index;          /* 1..N */
    uint8_t share_bytes[32];
} iii_anchor_share_t;

/* Split a secret key into N shares using XOR-based 3-of-N (where reconstruction
 * is bitwise XOR of all shares).  This is the simplest 3-of-3 scheme; for true
 * threshold (3-of-N) Shamir SSS, see Shamir 1979.  The XOR scheme satisfies
 * the §6 requirement that loss of any one share leaves recovery to the
 * remaining two — wait, XOR-3 requires all three.  Per spec §1.1, "loss of any
 * one share leaves the secret recoverable from the other two" — this requires
 * a true Shamir 2-of-3 scheme.  We implement Shamir over GF(2^8) below. */
bool iii_anchor_shamir_split(const uint8_t       secret[32],
                             unsigned             total_shares,
                             unsigned             threshold,
                             iii_anchor_share_t  *shares,
                             unsigned             max_shares);

bool iii_anchor_shamir_reconstruct(const iii_anchor_share_t *shares,
                                   unsigned                  count,
                                   uint8_t                   secret[32]);

/* §2 — directive forms.  Each authority cycle takes a directive; the runtime
 * verifies the Anchor's signature on it.  Signatures are RFC 8032 Ed25519
 * (R || S, 64 bytes); the 32-byte secret_key parameter is the Ed25519 seed
 * from which the signing scalar and public key are derived. */
typedef struct iii_anchor_signature {
    uint8_t bytes[64];
} iii_anchor_signature_t;

void iii_anchor_sign(const uint8_t          public_key[32],
                     const uint8_t          secret_key[32],
                     const uint8_t         *directive,
                     size_t                 directive_len,
                     iii_anchor_signature_t *out);

bool iii_anchor_verify(const uint8_t                public_key[32],
                       const uint8_t               *directive,
                       size_t                       directive_len,
                       const iii_anchor_signature_t *sig);

/* §2.1 — Tier-3 amendment cosignature requirement */
typedef struct iii_anchor_amendment {
    uint8_t  target_mhash[32];
    uint8_t  new_value_mhash[32];
    uint64_t federation_quorum_count;
    bool     federation_unanimous;
    iii_anchor_signature_t anchor_signature;
} iii_anchor_amendment_t;

typedef enum iii_anchor_amend_status {
    III_AMEND_OK             = 0,
    III_AMEND_REJECT_NO_QUORUM = 1,
    III_AMEND_REJECT_FNDR_VETO_MISSING = 2, /* FNDR-VETO-MISSING */
    III_AMEND_REJECT_INVALID = 3
} iii_anchor_amend_status_t;

const char *iii_anchor_amend_status_name(iii_anchor_amend_status_t s);

iii_anchor_amend_status_t iii_anchor_amend_apply(const iii_anchor_identity_t *anchor,
                                                  const iii_anchor_amendment_t *amend);

/* §2.2 — DRTM reset directive */
typedef struct iii_anchor_drtm_reset {
    uint8_t                nonce[32];
    uint64_t               timestamp;
    uint32_t               reason_code;
    iii_anchor_signature_t signature;
} iii_anchor_drtm_reset_t;

bool iii_anchor_drtm_reset_verify(const iii_anchor_identity_t *anchor,
                                  const iii_anchor_drtm_reset_t *reset);

/* §2.3 — pfs_deny */
typedef struct iii_anchor_pfs_deny {
    iii_pfs_deny_target_kind_t target_kind;
    uint64_t                   target_id;
    iii_pfs_deny_reason_t      reason;
    iii_anchor_signature_t     signature;
} iii_anchor_pfs_deny_t;

bool iii_anchor_pfs_deny_verify(const iii_anchor_identity_t *anchor,
                                const iii_anchor_pfs_deny_t *deny);

/* §2.5 — witness injection */
typedef struct iii_anchor_witness_inject {
    uint16_t                cycle_kind;
    uint8_t                 payload_mhash[32];
    uint64_t                timestamp;
    uint32_t                flags;        /* WITNESS_FLAGS_ANCHOR_AWARE etc */
    iii_anchor_signature_t  signature;
} iii_anchor_witness_inject_t;

#define III_WITNESS_FLAGS_ANCHOR_AWARE    (1u << 31)
#define III_WITNESS_FLAGS_INJECTED        (1u << 30)

bool iii_anchor_witness_inject_verify(const iii_anchor_identity_t *anchor,
                                      const iii_anchor_witness_inject_t *w);

/* §2.6 — Catalyst halt */
typedef struct iii_anchor_catalyst_halt {
    uint64_t               halt_until;        /* u64::MAX = permanent */
    iii_anchor_signature_t signature;
} iii_anchor_catalyst_halt_t;

bool iii_anchor_catalyst_halt_verify(const iii_anchor_identity_t *anchor,
                                     const iii_anchor_catalyst_halt_t *halt);

/* §2.7 — revoke promotion */
typedef struct iii_anchor_revoke {
    uint64_t                promotion_id;
    iii_revoke_cascade_t    cascade;
    iii_anchor_signature_t  signature;
} iii_anchor_revoke_t;

bool iii_anchor_revoke_verify(const iii_anchor_identity_t *anchor,
                              const iii_anchor_revoke_t *rev);

/* §3/§4 — invariant checks: a proposed proof certificate is rejected if it
 * touches any of the closure-pinned fields. */
typedef struct iii_anchor_invariant_check {
    bool attempts_modify_pubkey;
    bool attempts_modify_fingerprint;
    bool attempts_remove_amend_apply_anchor_requirement;
    bool attempts_disable_pfk_anchor_invariant;
    bool attempts_synthesize_substitute_anchor;
} iii_anchor_invariant_check_t;

bool iii_anchor_invariant_holds(const iii_anchor_invariant_check_t *c);

/* Runtime — tracks halt state and amendment history */
typedef struct iii_anchor_runtime iii_anchor_runtime_t;

iii_anchor_runtime_t *iii_anchor_runtime_create(const iii_anchor_identity_t *anchor);
void                  iii_anchor_runtime_destroy(iii_anchor_runtime_t *rt);

const iii_anchor_identity_t *iii_anchor_runtime_identity(const iii_anchor_runtime_t *rt);
bool iii_anchor_runtime_is_catalyst_halted(const iii_anchor_runtime_t *rt, uint64_t now);

bool iii_anchor_runtime_apply_halt(iii_anchor_runtime_t *rt,
                                   const iii_anchor_catalyst_halt_t *halt);

bool iii_anchor_runtime_resume(iii_anchor_runtime_t *rt,
                               const iii_anchor_signature_t *resume_sig);

uint64_t iii_anchor_runtime_witness_count(const iii_anchor_runtime_t *rt);

#ifdef __cplusplus
}
#endif

#endif /* III_FOUNDERS_ANCHOR_H */
