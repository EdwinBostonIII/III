#include "iii/genesis_vector.h"
#include <stdio.h>
#include <string.h>

static int g_pass = 0, g_fail = 0;
#define TEST(c) do { if (c) { g_pass++; printf("  PASS %s\n", #c); } \
    else { g_fail++; printf("  FAIL %s @ %s:%d\n", #c, __FILE__, __LINE__); } } while (0)
#define SECTION(s) printf("\n[%s]\n", s)

static void make_installer(iii_gv_installer_t *inst, iii_gv_target_t target,
                           iii_gv_signing_authority_t auth, bool revoked) {
    memset(inst, 0, sizeof(*inst));
    inst->target = target;
    {
        const char *desc = "III - Sovereign Computational Substrate";
        size_t i = 0;
        for (; i < sizeof(inst->file_description) - 1u && desc[i]; ++i) inst->file_description[i] = desc[i];
        inst->file_description[i] = '\0';
    }
    {
        const char *op = "Edwin Boston";
        size_t i = 0;
        for (; i < sizeof(inst->operator_name) - 1u && op[i]; ++i) inst->operator_name[i] = op[i];
        inst->operator_name[i] = '\0';
    }
    inst->certificate.authority = auth;
    inst->certificate.not_before = 1000;
    inst->certificate.not_after  = 1000000000;
    inst->certificate.revoked = revoked;
    inst->certificate.air_gapped_keystore = true;
    for (unsigned i = 0; i < 32; ++i) inst->certificate.fingerprint[i] = (uint8_t)i;
    for (unsigned i = 0; i < 32; ++i) inst->binary_mhash[i] = (uint8_t)(0x80 + i);
    for (unsigned i = 0; i < 32; ++i) inst->closure_root[i] = (uint8_t)(0xC0 + i);
}

static void make_predischarge(iii_gv_predischarge_t *p, bool all_ok) {
    memset(p, 0, sizeof(*p));
    p->intent_clicked_install = all_ok;
    p->cap_admin_or_root      = all_ok;
    p->causality_host_os_executed_installer = all_ok;
    p->sanctum_box1_allocated = all_ok;
}

static void test_certificates(void) {
    SECTION("§1 certificate validity");
    iii_gv_certificate_t c = {0};
    c.authority = III_GV_CA_DIGICERT;
    c.not_before = 100;
    c.not_after  = 2000;
    TEST(iii_gv_certificate_valid(&c, 500));
    TEST(!iii_gv_certificate_valid(&c, 50));   /* before */
    TEST(!iii_gv_certificate_valid(&c, 3000)); /* after */
    c.revoked = true;
    TEST(!iii_gv_certificate_valid(&c, 500));
    c.revoked = false;
    c.authority = III_GV_CA_NONE;
    TEST(!iii_gv_certificate_valid(&c, 500));
}

static void test_predischarge(void) {
    SECTION("§5 pre-discharge bundle");
    iii_gv_predischarge_t p;
    make_predischarge(&p, true);
    TEST(iii_gv_predischarge_complete(&p));

    p.intent_clicked_install = false;
    TEST(!iii_gv_predischarge_complete(&p));

    /* Bundle hash binds installer + cert + flags. */
    iii_gv_installer_t inst;
    make_installer(&inst, III_GV_TARGET_WINDOWS_MSI, III_GV_CA_DIGICERT, false);
    make_predischarge(&p, true);
    uint8_t b1[32], b2[32];
    iii_gv_predischarge_compute(&p, &inst, b1);
    p.intent_clicked_install = false;
    iii_gv_predischarge_compute(&p, &inst, b2);
    TEST(memcmp(b1, b2, 32) != 0);
}

static void test_register_installer(void) {
    SECTION("§2 register installer");
    iii_gv_runtime_t *rt = iii_gv_runtime_create();
    iii_gv_installer_t inst;
    make_installer(&inst, III_GV_TARGET_WINDOWS_MSI, III_GV_CA_DIGICERT, false);
    TEST(iii_gv_runtime_register_installer(rt, &inst));
    TEST(iii_gv_runtime_installer_count(rt) == 1);
    TEST(iii_gv_runtime_installer_for(rt, III_GV_TARGET_WINDOWS_MSI) != NULL);
    TEST(iii_gv_runtime_installer_for(rt, III_GV_TARGET_LINUX_DEB) == NULL);
    iii_gv_runtime_destroy(rt);
}

static void test_enter(void) {
    SECTION("§3 entry");
    iii_gv_runtime_t *rt = iii_gv_runtime_create();
    iii_gv_installer_t inst;
    make_installer(&inst, III_GV_TARGET_WINDOWS_MSI, III_GV_CA_DIGICERT, false);
    iii_gv_runtime_register_installer(rt, &inst);

    iii_gv_predischarge_t p;
    make_predischarge(&p, true);
    iii_gv_drtm_outcome_t drtm;
    TEST(iii_gv_enter(rt, III_GV_TARGET_WINDOWS_MSI, &p, &drtm) == III_GV_ENTRY_OK);
    TEST(drtm.relaunched);
    TEST(drtm.epoch != 0);

    /* Trinity incomplete */
    make_predischarge(&p, false);
    TEST(iii_gv_enter(rt, III_GV_TARGET_WINDOWS_MSI, &p, &drtm) == III_GV_ENTRY_REJECT_TRINITY);

    /* Revoked certificate */
    make_predischarge(&p, true);
    iii_gv_installer_t bad;
    make_installer(&bad, III_GV_TARGET_LINUX_DEB, III_GV_CA_GPG, true);
    iii_gv_runtime_register_installer(rt, &bad);
    TEST(iii_gv_enter(rt, III_GV_TARGET_LINUX_DEB, &p, &drtm) == III_GV_ENTRY_REJECT_REVOKED);

    /* Unknown target */
    TEST(iii_gv_enter(rt, III_GV_TARGET_EMBEDDED, &p, &drtm) == III_GV_ENTRY_REJECT_INVALID_TARGET);

    /* Unsigned: cert.authority = NONE */
    iii_gv_installer_t un;
    make_installer(&un, III_GV_TARGET_MACOS_PKG, III_GV_CA_NONE, false);
    iii_gv_runtime_register_installer(rt, &un);
    TEST(iii_gv_enter(rt, III_GV_TARGET_MACOS_PKG, &p, &drtm) == III_GV_ENTRY_REJECT_UNSIGNED);

    iii_gv_runtime_destroy(rt);
}

static void test_verify(void) {
    SECTION("§8 post-install verify");
    iii_gv_runtime_t *rt = iii_gv_runtime_create();
    iii_gv_installer_t inst;
    make_installer(&inst, III_GV_TARGET_WINDOWS_MSI, III_GV_CA_DIGICERT, false);
    iii_gv_runtime_register_installer(rt, &inst);

    iii_gv_predischarge_t p;
    make_predischarge(&p, true);
    iii_gv_drtm_outcome_t drtm;
    iii_gv_enter(rt, III_GV_TARGET_WINDOWS_MSI, &p, &drtm);

    iii_gv_verify_result_t v;
    iii_gv_verify(rt, III_GV_TARGET_WINDOWS_MSI, inst.binary_mhash, inst.closure_root, 5000, &v);
    TEST(v.binary_mhash_matches);
    TEST(v.closure_root_matches);
    TEST(v.certificate_valid);
    TEST(v.drtm_chain_consistent);
    TEST(v.overall_pass);

    /* Tampered binary_mhash */
    uint8_t bad[32]; memset(bad, 0xFF, 32);
    iii_gv_verify(rt, III_GV_TARGET_WINDOWS_MSI, bad, inst.closure_root, 5000, &v);
    TEST(!v.overall_pass);

    iii_gv_runtime_destroy(rt);
}

int main(void) {
    test_certificates();
    test_predischarge();
    test_register_installer();
    test_enter();
    test_verify();
    printf("\n=== %d passed, %d failed ===\n", g_pass, g_fail);
    return g_fail == 0 ? 0 : 1;
}
