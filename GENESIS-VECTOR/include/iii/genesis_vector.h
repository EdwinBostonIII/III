/* ============================================================================
 * III-GENESIS-VECTOR — Polymorphic Deployment Installer
 * Spec: III-GENESIS-VECTOR.md  (Wave 10.2, item 177)
 *
 *   §1 — legitimate signing model (operator-owned certs)
 *   §2 — polymorphic packaging per platform
 *   §3 — Trinity-gated entry into the substrate
 *   §4 — software-only DRTM relaunch
 *   §5 — pre-discharge bundle (intent × cap × causality × sanctum-state)
 *   §6 — per-architecture installer variants
 *   §7 — deployment channels
 *   §8 — post-install verification
 * ============================================================================
 */
#ifndef III_GENESIS_VECTOR_H
#define III_GENESIS_VECTOR_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* §2.1 — supported packaging targets */
typedef enum iii_gv_target {
    III_GV_TARGET_NONE          = 0,
    III_GV_TARGET_WINDOWS_MSI   = 1,
    III_GV_TARGET_LINUX_DEB     = 2,
    III_GV_TARGET_LINUX_RPM     = 3,
    III_GV_TARGET_MACOS_PKG     = 4,
    III_GV_TARGET_ARMV8_DEB     = 5,
    III_GV_TARGET_RISCV_DEB     = 6,
    III_GV_TARGET_EMBEDDED      = 7
} iii_gv_target_t;

const char *iii_gv_target_name(iii_gv_target_t t);

/* §1 — signing CA / certificate */
typedef enum iii_gv_signing_authority {
    III_GV_CA_NONE          = 0,
    III_GV_CA_DIGICERT      = 1,
    III_GV_CA_SECTIGO       = 2,
    III_GV_CA_GLOBALSIGN    = 3,
    III_GV_CA_COMODO        = 4,
    III_GV_CA_APPLE_DEV_ID  = 5,
    III_GV_CA_GPG           = 6
} iii_gv_signing_authority_t;

const char *iii_gv_signing_authority_name(iii_gv_signing_authority_t a);

typedef struct iii_gv_certificate {
    iii_gv_signing_authority_t authority;
    char                       subject_cn[128];      /* operator legal name */
    uint8_t                    fingerprint[32];
    uint64_t                   not_before;
    uint64_t                   not_after;
    bool                       revoked;
    bool                       air_gapped_keystore;
} iii_gv_certificate_t;

bool iii_gv_certificate_valid(const iii_gv_certificate_t *c, uint64_t now);

/* §2 — installer descriptor */
typedef struct iii_gv_installer {
    iii_gv_target_t            target;
    char                       package_name[64];     /* "III-Substrate-v1.0.0.msi" */
    char                       file_description[128];/* "III - Sovereign Computational Substrate" */
    char                       operator_name[64];
    char                       license[32];
    char                       source_url[128];
    char                       revocation_contact[128];
    iii_gv_certificate_t       certificate;
    uint8_t                    binary_mhash[32];
    uint8_t                    closure_root[32];
} iii_gv_installer_t;

/* §3 — Trinity pre-discharge bundle */
typedef struct iii_gv_predischarge {
    bool     intent_clicked_install;
    bool     cap_admin_or_root;
    bool     causality_host_os_executed_installer;
    bool     sanctum_box1_allocated;
    uint8_t  bundle_mhash[32];
} iii_gv_predischarge_t;

/* Compute the bundle mhash from the four flags + installer + cert. */
void iii_gv_predischarge_compute(const iii_gv_predischarge_t *flags,
                                 const iii_gv_installer_t    *inst,
                                 uint8_t                       out_bundle[32]);

bool iii_gv_predischarge_complete(const iii_gv_predischarge_t *p);

/* §3 — entry into the substrate */
typedef enum iii_gv_entry_status {
    III_GV_ENTRY_OK                       = 0,
    III_GV_ENTRY_REJECT_UNSIGNED          = 1,
    III_GV_ENTRY_REJECT_REVOKED           = 2,
    III_GV_ENTRY_REJECT_TRINITY           = 3,
    III_GV_ENTRY_REJECT_INVALID_TARGET    = 4,
    III_GV_ENTRY_REJECT_DRTM_FAILED       = 5
} iii_gv_entry_status_t;

const char *iii_gv_entry_status_name(iii_gv_entry_status_t s);

/* §4 — software-only DRTM relaunch outcome */
typedef struct iii_gv_drtm_outcome {
    bool     relaunched;
    uint64_t epoch;
    uint8_t  drtm_quote_mhash[32];
} iii_gv_drtm_outcome_t;

/* ----------------------------------------------------------------------------
 * Runtime
 * ---------------------------------------------------------------------------- */
typedef struct iii_gv_runtime iii_gv_runtime_t;

iii_gv_runtime_t *iii_gv_runtime_create(void);
void              iii_gv_runtime_destroy(iii_gv_runtime_t *rt);

/* §1 — configure operator certificate */
bool iii_gv_runtime_set_certificate(iii_gv_runtime_t *rt,
                                    const iii_gv_certificate_t *cert);

/* §2 — register an installer descriptor (one per target). */
bool iii_gv_runtime_register_installer(iii_gv_runtime_t       *rt,
                                       const iii_gv_installer_t *inst);

const iii_gv_installer_t *iii_gv_runtime_installer_for(const iii_gv_runtime_t *rt,
                                                       iii_gv_target_t          target);
size_t iii_gv_runtime_installer_count(const iii_gv_runtime_t *rt);

/* §3 — first-execution entry: validates cert + Trinity bundle, then performs
 * the software-only DRTM relaunch. */
iii_gv_entry_status_t iii_gv_enter(iii_gv_runtime_t            *rt,
                                   iii_gv_target_t              target,
                                   const iii_gv_predischarge_t  *predischarge,
                                   iii_gv_drtm_outcome_t        *out_drtm);

/* §8 — post-install verification: confirms the installed binary matches the
 * operator's published closure root and that the certificate is still valid. */
typedef struct iii_gv_verify_result {
    bool binary_mhash_matches;
    bool closure_root_matches;
    bool certificate_valid;
    bool drtm_chain_consistent;
    bool overall_pass;
} iii_gv_verify_result_t;

void iii_gv_verify(const iii_gv_runtime_t   *rt,
                   iii_gv_target_t            target,
                   const uint8_t              expected_binary_mhash[32],
                   const uint8_t              expected_closure_root[32],
                   uint64_t                   now,
                   iii_gv_verify_result_t    *out);

/* §7 — deployment channel */
typedef enum iii_gv_channel {
    III_GV_CH_DIRECT_DOWNLOAD    = 0,
    III_GV_CH_PACKAGE_REPO       = 1,
    III_GV_CH_ENTERPRISE_MDM     = 2,
    III_GV_CH_USB_OFFLINE        = 3
} iii_gv_channel_t;

const char *iii_gv_channel_name(iii_gv_channel_t c);

uint64_t iii_gv_witness_count(const iii_gv_runtime_t *rt);

#ifdef __cplusplus
}
#endif

#endif /* III_GENESIS_VECTOR_H */
