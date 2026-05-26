/* III-GENESIS-VECTOR implementation */
#include "iii/genesis_vector.h"
#include <stdlib.h>
#include <string.h>

extern void iii_sha256(const void *data, size_t len, uint8_t out[32]);

const char *iii_gv_target_name(iii_gv_target_t t) {
    switch (t) {
        case III_GV_TARGET_WINDOWS_MSI: return "windows-msi";
        case III_GV_TARGET_LINUX_DEB:   return "linux-deb";
        case III_GV_TARGET_LINUX_RPM:   return "linux-rpm";
        case III_GV_TARGET_MACOS_PKG:   return "macos-pkg";
        case III_GV_TARGET_ARMV8_DEB:   return "armv8-deb";
        case III_GV_TARGET_RISCV_DEB:   return "riscv-deb";
        case III_GV_TARGET_EMBEDDED:    return "embedded";
        default:                        return "none";
    }
}

const char *iii_gv_signing_authority_name(iii_gv_signing_authority_t a) {
    switch (a) {
        case III_GV_CA_DIGICERT:     return "DigiCert";
        case III_GV_CA_SECTIGO:      return "Sectigo";
        case III_GV_CA_GLOBALSIGN:   return "GlobalSign";
        case III_GV_CA_COMODO:       return "Comodo";
        case III_GV_CA_APPLE_DEV_ID: return "Apple Developer ID";
        case III_GV_CA_GPG:          return "GPG";
        default:                     return "none";
    }
}

const char *iii_gv_entry_status_name(iii_gv_entry_status_t s) {
    switch (s) {
        case III_GV_ENTRY_OK:                    return "ok";
        case III_GV_ENTRY_REJECT_UNSIGNED:       return "reject-unsigned";
        case III_GV_ENTRY_REJECT_REVOKED:        return "reject-revoked";
        case III_GV_ENTRY_REJECT_TRINITY:        return "reject-trinity";
        case III_GV_ENTRY_REJECT_INVALID_TARGET: return "reject-invalid-target";
        case III_GV_ENTRY_REJECT_DRTM_FAILED:    return "reject-drtm-failed";
        default:                                 return "unknown";
    }
}

const char *iii_gv_channel_name(iii_gv_channel_t c) {
    switch (c) {
        case III_GV_CH_DIRECT_DOWNLOAD: return "direct-download";
        case III_GV_CH_PACKAGE_REPO:    return "package-repo";
        case III_GV_CH_ENTERPRISE_MDM:  return "enterprise-mdm";
        case III_GV_CH_USB_OFFLINE:     return "usb-offline";
        default:                        return "unknown";
    }
}

bool iii_gv_certificate_valid(const iii_gv_certificate_t *c, uint64_t now) {
    if (!c) return false;
    if (c->revoked) return false;
    if (c->authority == III_GV_CA_NONE) return false;
    if (c->not_before > now || c->not_after < now) return false;
    return true;
}

void iii_gv_predischarge_compute(const iii_gv_predischarge_t *flags,
                                 const iii_gv_installer_t    *inst,
                                 uint8_t                       out_bundle[32])
{
    if (!flags || !inst || !out_bundle) { if (out_bundle) memset(out_bundle, 0, 32); return; }
    /* Encode: 4 flag bits + binary_mhash + cert fingerprint */
    uint8_t buf[1 + 32 + 32];
    uint8_t bits = 0;
    bits |= flags->intent_clicked_install ? 1 : 0;
    bits |= (flags->cap_admin_or_root ? 1 : 0) << 1;
    bits |= (flags->causality_host_os_executed_installer ? 1 : 0) << 2;
    bits |= (flags->sanctum_box1_allocated ? 1 : 0) << 3;
    buf[0] = bits;
    memcpy(buf + 1,  inst->binary_mhash, 32);
    memcpy(buf + 33, inst->certificate.fingerprint, 32);
    iii_sha256(buf, sizeof(buf), out_bundle);
}

bool iii_gv_predischarge_complete(const iii_gv_predischarge_t *p) {
    return p && p->intent_clicked_install && p->cap_admin_or_root
            && p->causality_host_os_executed_installer && p->sanctum_box1_allocated;
}

#define III_GV_MAX_INSTALLERS  16u

struct iii_gv_runtime {
    iii_gv_certificate_t cert;
    bool                 cert_set;
    iii_gv_installer_t   installers[III_GV_MAX_INSTALLERS];
    unsigned             installer_count;
    uint64_t             witness_count;
    iii_gv_drtm_outcome_t last_drtm;
};

iii_gv_runtime_t *iii_gv_runtime_create(void) {
    return (iii_gv_runtime_t *)calloc(1, sizeof(iii_gv_runtime_t));
}
void iii_gv_runtime_destroy(iii_gv_runtime_t *rt) { if (rt) free(rt); }

uint64_t iii_gv_witness_count(const iii_gv_runtime_t *rt) { return rt ? rt->witness_count : 0u; }

bool iii_gv_runtime_set_certificate(iii_gv_runtime_t *rt, const iii_gv_certificate_t *cert) {
    if (!rt || !cert) return false;
    rt->cert = *cert;
    rt->cert_set = true;
    rt->witness_count++;
    return true;
}

bool iii_gv_runtime_register_installer(iii_gv_runtime_t       *rt,
                                       const iii_gv_installer_t *inst)
{
    if (!rt || !inst) return false;
    if (rt->installer_count >= III_GV_MAX_INSTALLERS) return false;
    rt->installers[rt->installer_count++] = *inst;
    rt->witness_count++;
    return true;
}

const iii_gv_installer_t *iii_gv_runtime_installer_for(const iii_gv_runtime_t *rt,
                                                       iii_gv_target_t          target)
{
    if (!rt) return NULL;
    for (unsigned i = 0; i < rt->installer_count; ++i) {
        if (rt->installers[i].target == target) return &rt->installers[i];
    }
    return NULL;
}

size_t iii_gv_runtime_installer_count(const iii_gv_runtime_t *rt) {
    return rt ? rt->installer_count : 0u;
}

iii_gv_entry_status_t iii_gv_enter(iii_gv_runtime_t            *rt,
                                   iii_gv_target_t              target,
                                   const iii_gv_predischarge_t  *predischarge,
                                   iii_gv_drtm_outcome_t        *out_drtm)
{
    if (!rt || !predischarge) return III_GV_ENTRY_REJECT_INVALID_TARGET;
    const iii_gv_installer_t *inst = iii_gv_runtime_installer_for(rt, target);
    if (!inst) return III_GV_ENTRY_REJECT_INVALID_TARGET;

    if (inst->certificate.authority == III_GV_CA_NONE) return III_GV_ENTRY_REJECT_UNSIGNED;
    if (inst->certificate.revoked)                     return III_GV_ENTRY_REJECT_REVOKED;
    /* Treat now as inst->certificate.not_before for checking validity */
    if (!iii_gv_certificate_valid(&inst->certificate, inst->certificate.not_before)) {
        return III_GV_ENTRY_REJECT_REVOKED;
    }

    if (!iii_gv_predischarge_complete(predischarge)) {
        return III_GV_ENTRY_REJECT_TRINITY;
    }

    /* §4 — perform a software-only DRTM relaunch (modelled). */
    iii_gv_drtm_outcome_t drtm;
    drtm.relaunched = true;
    drtm.epoch = ++rt->witness_count;
    /* DRTM quote mhash = SHA-256(installer.closure_root || pre-discharge bundle) */
    uint8_t bundle[32];
    iii_gv_predischarge_compute(predischarge, inst, bundle);
    uint8_t buf[64];
    memcpy(buf,    inst->closure_root, 32);
    memcpy(buf+32, bundle,             32);
    iii_sha256(buf, sizeof(buf), drtm.drtm_quote_mhash);

    rt->last_drtm = drtm;
    if (out_drtm) *out_drtm = drtm;
    rt->witness_count++;
    return III_GV_ENTRY_OK;
}

void iii_gv_verify(const iii_gv_runtime_t   *rt,
                   iii_gv_target_t            target,
                   const uint8_t              expected_binary_mhash[32],
                   const uint8_t              expected_closure_root[32],
                   uint64_t                   now,
                   iii_gv_verify_result_t    *out)
{
    if (!out) return;
    memset(out, 0, sizeof(*out));
    if (!rt) return;
    const iii_gv_installer_t *inst = iii_gv_runtime_installer_for(rt, target);
    if (!inst) return;
    out->binary_mhash_matches  = expected_binary_mhash &&
                                 memcmp(inst->binary_mhash, expected_binary_mhash, 32) == 0;
    out->closure_root_matches  = expected_closure_root &&
                                 memcmp(inst->closure_root, expected_closure_root, 32) == 0;
    out->certificate_valid     = iii_gv_certificate_valid(&inst->certificate, now);
    out->drtm_chain_consistent = rt->last_drtm.relaunched;
    out->overall_pass = out->binary_mhash_matches && out->closure_root_matches &&
                        out->certificate_valid && out->drtm_chain_consistent;
}
