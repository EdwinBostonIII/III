/* III-PORTABILITY test harness. */
#include "iii/portability.h"
#include "iii/sha256.h"

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

static int g_pass = 0, g_fail = 0;

#define CHECK(cond, msg) do { \
    if (cond) { ++g_pass; printf("  pass: %s\n", msg); } \
    else      { ++g_fail; printf("  FAIL: %s @ %s:%d\n", msg, __FILE__, __LINE__); } \
} while (0)

static const iii_arch_t k_all[] = {
    IIIARCH_X86_64, IIIARCH_ARMV8, IIIARCH_RISCV_H,
    IIIARCH_INTEL_VMX, IIIARCH_POWER9
};
#define NARCH (sizeof k_all / sizeof k_all[0])

/* ---------- HAL vtable presence ---------- */
static void test_hal_presence(void) {
    printf("[hal vtable presence]\n");
    for (size_t i = 0; i < NARCH; ++i) {
        const iii_hal_t *h = iii_hal_select(k_all[i]);
        char buf[96];
        snprintf(buf, sizeof buf, "%s vtable non-null", iii_arch_name(k_all[i]));
        CHECK(h != NULL, buf);
        if (!h) continue;
        snprintf(buf, sizeof buf, "%s every fn ptr non-null", h->name);
        CHECK(h->detect && h->has_feature && h->cpu_count &&
              h->numa_node_count && h->cpu_to_numa &&
              h->hv_init && h->hv_vmrun && h->hv_intercept && h->hv_teardown &&
              h->iommu_init && h->iommu_map_iopt && h->iommu_irte_remap &&
              h->iommu_fault_intercept &&
              h->npt_class_set && h->npt_class_get && h->npt_invalidate &&
              h->mmu_init && h->drtm_relaunch &&
              h->ipi_send && h->timer_now && h->cache_flush &&
              h->atomic_cas64 && h->atomic_add64,
              buf);
        snprintf(buf, sizeof buf, "%s arch field matches select arg", h->name);
        CHECK(h->arch == k_all[i], buf);
    }
}

/* ---------- Opcode tables ---------- */
static void test_opcodes(void) {
    printf("[opcode-byte tables]\n");
    for (size_t i = 0; i < NARCH; ++i) {
        const iii_hal_t *h = iii_hal_select(k_all[i]);
        char buf[96];
        snprintf(buf, sizeof buf, "%s has >=6 opcodes (%zu)", h->name,
                 h->opcode_count);
        CHECK(h->opcode_count >= 6, buf);
        /* Every opcode must be non-empty and have a mnemonic. */
        int ok = 1;
        for (size_t j = 0; j < h->opcode_count; ++j)
            if (!h->opcodes[j].mnemonic || !h->opcodes[j].bytes ||
                h->opcodes[j].len == 0) ok = 0;
        snprintf(buf, sizeof buf, "%s opcodes well-formed", h->name);
        CHECK(ok, buf);
    }

    /* Spot-check exact byte values (regression detection). */
    const iii_hal_t *x = iii_hal_select(IIIARCH_X86_64);
    CHECK(x->opcodes[0].len == 3 &&
          x->opcodes[0].bytes[0] == 0x0F &&
          x->opcodes[0].bytes[1] == 0x01 &&
          x->opcodes[0].bytes[2] == 0xD8,
          "x86_64 opcode[0] == VMRUN(0F 01 D8)");

    const iii_hal_t *a = iii_hal_select(IIIARCH_ARMV8);
    CHECK(a->opcodes[0].len == 4 &&
          a->opcodes[0].bytes[0] == 0xC0 &&
          a->opcodes[0].bytes[1] == 0x03 &&
          a->opcodes[0].bytes[2] == 0x9F &&
          a->opcodes[0].bytes[3] == 0xD6,
          "armv8 opcode[0] == ERET(C0 03 9F D6)");

    const iii_hal_t *r = iii_hal_select(IIIARCH_RISCV_H);
    CHECK(r->opcodes[0].len == 4 &&
          r->opcodes[0].bytes[0] == 0x73 &&
          r->opcodes[0].bytes[1] == 0x00 &&
          r->opcodes[0].bytes[2] == 0x50 &&
          r->opcodes[0].bytes[3] == 0x10,
          "riscv_h opcode[0] == WFI(73 00 50 10)");

    const iii_hal_t *v = iii_hal_select(IIIARCH_INTEL_VMX);
    CHECK(v->opcodes[0].len == 4 &&
          v->opcodes[0].bytes[0] == 0xF3 &&
          v->opcodes[0].bytes[1] == 0x0F &&
          v->opcodes[0].bytes[2] == 0xC7 &&
          v->opcodes[0].bytes[3] == 0x30,
          "intel_vmx opcode[0] == VMXON(F3 0F C7 30)");

    const iii_hal_t *p = iii_hal_select(IIIARCH_POWER9);
    CHECK(p->opcodes[0].len == 4 &&
          p->opcodes[0].bytes[0] == 0x4C &&
          p->opcodes[0].bytes[1] == 0x00 &&
          p->opcodes[0].bytes[2] == 0x02 &&
          p->opcodes[0].bytes[3] == 0x24,
          "power9 opcode[0] == hrfid(4C 00 02 24)");
}

/* ---------- Closure root determinism ---------- */
static void test_closure_empty(void) {
    printf("[closure root: empty]\n");
    uint8_t r[32];
    int rc = iii_closure_root_compute(NULL, 0, r);
    CHECK(rc == 0, "empty compute returns 0");
    /* Computed via independent reference (Python hashlib) over
     * "III/PORTABILITY/CLOSURE/v1\n" || u32_be(0). */
    static const uint8_t expect[32] = {
        0x0d,0x01,0x54,0xb4,0x77,0xca,0xac,0xe9,
        0x81,0x05,0x0c,0x05,0x8c,0xfb,0x74,0x71,
        0x5e,0xad,0xc2,0x5b,0xa5,0xba,0x44,0x40,
        0x39,0xb3,0xad,0x30,0xb0,0x44,0x15,0x5d
    };
    CHECK(memcmp(r, expect, 32) == 0, "empty closure root matches expected hex");
}

static void test_closure_synthetic(void) {
    printf("[closure root: synthetic two-module stream]\n");
    iii_module_t mods[2] = {
        { "alpha", (const uint8_t *)"AAAA", 4 },
        { "beta",  (const uint8_t *)"BB",   2 }
    };
    uint8_t r1[32], r2[32];
    int rc = iii_closure_root_compute(mods, 2, r1);
    CHECK(rc == 0, "two-module compute returns 0");
    /* Reorder input; canonical sort must yield identical root. */
    iii_module_t swapped[2] = { mods[1], mods[0] };
    rc = iii_closure_root_compute(swapped, 2, r2);
    CHECK(rc == 0, "swapped-order compute returns 0");
    CHECK(memcmp(r1, r2, 32) == 0, "closure root order-independent");

    static const uint8_t expect[32] = {
        0x57,0xd1,0xca,0x5d,0x80,0xcf,0x56,0x4e,
        0xba,0x2a,0x60,0x5a,0x75,0xb0,0x6e,0xdb,
        0x83,0xfb,0x53,0x8c,0xca,0xe5,0x25,0xdc,
        0xcc,0x76,0xfc,0x13,0x30,0x2d,0x20,0x4e
    };
    CHECK(memcmp(r1, expect, 32) == 0,
          "two-module closure root matches expected hex");
}

static void test_closure_arch_independence(void) {
    /* The closure root must NOT depend on which HAL is current. We compute
     * the root five times (one per arch context) and require all match. */
    printf("[closure root: arch-independence]\n");
    iii_module_t mods[3] = {
        { "kernel.imm",  (const uint8_t *)"\x01\x02\x03\x04\x05", 5 },
        { "anchor.cert", (const uint8_t *)"ANCHORv1",            8 },
        { "ast.bin",     (const uint8_t *)"(let x 7)",           9 }
    };
    uint8_t roots[NARCH][32];
    for (size_t i = 0; i < NARCH; ++i) {
        const iii_hal_t *h = iii_hal_select(k_all[i]);
        (void)h;  /* the closure compute is arch-independent by mandate */
        int rc = iii_closure_root_compute(mods, 3, roots[i]);
        CHECK(rc == 0, "compute under arch context");
    }
    int all_eq = 1;
    for (size_t i = 1; i < NARCH; ++i)
        if (memcmp(roots[0], roots[i], 32) != 0) all_eq = 0;
    CHECK(all_eq, "closure root identical across all 5 arch contexts");
}

/* ---------- HAL behaviors ---------- */
static void test_hal_behavior(void) {
    printf("[hal behavior]\n");
    for (size_t i = 0; i < NARCH; ++i) {
        const iii_hal_t *h = iii_hal_select(k_all[i]);
        char buf[96];
        snprintf(buf, sizeof buf, "%s hv_init witness", h->name);
        CHECK(h->hv_init() != IIIWITNESS_NONE, buf);

        iii_vmcb_t vmcb; memset(&vmcb, 0, sizeof vmcb);
        snprintf(buf, sizeof buf, "%s hv_intercept VMRUN", h->name);
        CHECK(h->hv_intercept(&vmcb, IIIIC_VMRUN) != IIIWITNESS_NONE, buf);

        uint32_t exit_reason = 0;
        snprintf(buf, sizeof buf, "%s hv_vmrun consumes VMCB", h->name);
        CHECK(h->hv_vmrun(&vmcb, &exit_reason) != IIIWITNESS_NONE &&
              exit_reason != 0, buf);

        snprintf(buf, sizeof buf, "%s hv_teardown", h->name);
        CHECK(h->hv_teardown() != IIIWITNESS_NONE, buf);

        snprintf(buf, sizeof buf, "%s iommu_init+map+irte", h->name);
        iii_iopt_entry_t e = { .iova=0x1000, .gpa=0x2000, .size=0x1000,
                               .flags=IIIIOPT_R|IIIIOPT_W };
        int ok = (h->iommu_init() != IIIWITNESS_NONE) &&
                 (h->iommu_map_iopt(0x1234, &e) != IIIWITNESS_NONE) &&
                 (h->iommu_irte_remap(0x1234, 33, 0) != IIIWITNESS_NONE);
        CHECK(ok, buf);

        snprintf(buf, sizeof buf, "%s npt class set/get round-trip", h->name);
        h->npt_class_set(0xDEAD0000ull, IIINPT_CODE);
        CHECK(h->npt_class_get(0xDEAD0000ull) == IIINPT_CODE, buf);
        h->npt_invalidate(0xDEAD0000ull);

        snprintf(buf, sizeof buf, "%s timer monotonic", h->name);
        uint64_t t0 = h->timer_now();
        uint64_t t1 = h->timer_now();
        CHECK(t1 > t0, buf);

        snprintf(buf, sizeof buf, "%s atomic CAS succeeds then fails", h->name);
        uint64_t v = 7;
        int s1 = h->atomic_cas64(&v, 7, 9);
        int s2 = h->atomic_cas64(&v, 7, 11);
        CHECK(s1 && !s2 && v == 9, buf);

        snprintf(buf, sizeof buf, "%s drtm relaunch produces measurement", h->name);
        iii_drtm_result_t dr; memset(&dr, 0, sizeof dr);
        int sum = 0; for (int j = 0; j < 32; ++j) sum |= dr.measurement[j];
        CHECK(sum == 0, "(scratch dr zero)");
        CHECK(h->drtm_relaunch(&dr) != IIIWITNESS_NONE, buf);
        sum = 0; for (int j = 0; j < 32; ++j) sum |= dr.measurement[j];
        CHECK(sum != 0 && dr.epoch >= 1, "drtm measurement non-zero");
    }
}

/* ---------- Closure-pinned mappings ---------- */
static void test_mappings_distinct(void) {
    printf("[closure-pinned mappings]\n");
    /* All 18 intercept slots must map to distinct bit positions per arch. */
    for (size_t i = 0; i < NARCH; ++i) {
        const iii_hal_t *h = iii_hal_select(k_all[i]);
        int dup = 0;
        for (int a = 0; a < IIIIC__COUNT; ++a)
            for (int b = a + 1; b < IIIIC__COUNT; ++b)
                if (h->intercept_map[a] == h->intercept_map[b]) dup = 1;
        char buf[96];
        snprintf(buf, sizeof buf, "%s intercept_map entries distinct", h->name);
        CHECK(!dup, buf);

        /* npt_class_map: UNCLASSIFIED is 0, all others non-zero & distinct. */
        int npt_ok = (h->npt_class_map[IIINPT_UNCLASSIFIED] == 0);
        for (int a = 1; a < IIINPT__COUNT; ++a) {
            if (h->npt_class_map[a] == 0) npt_ok = 0;
            for (int b = a + 1; b < IIINPT__COUNT; ++b)
                if (h->npt_class_map[a] == h->npt_class_map[b]) npt_ok = 0;
        }
        snprintf(buf, sizeof buf, "%s npt_class_map well-formed", h->name);
        CHECK(npt_ok, buf);
    }
}

/* ---------- arch parse / bindings ---------- */
static void test_arch_parse(void) {
    printf("[arch parse]\n");
    iii_arch_t a;
    CHECK(iii_arch_parse("x86_64", &a) == 0 && a == IIIARCH_X86_64, "parse x86_64");
    CHECK(iii_arch_parse("aarch64", &a) == 0 && a == IIIARCH_ARMV8, "parse aarch64");
    CHECK(iii_arch_parse("riscv64", &a) == 0 && a == IIIARCH_RISCV_H, "parse riscv64");
    CHECK(iii_arch_parse("intel", &a) == 0 && a == IIIARCH_INTEL_VMX, "parse intel");
    CHECK(iii_arch_parse("ppc64le", &a) == 0 && a == IIIARCH_POWER9, "parse ppc64le");
    CHECK(iii_arch_parse("zilog", &a) != 0, "parse rejects unknown arch");

    /* arch-binding bits are distinct. */
    uint32_t bits[NARCH];
    for (size_t i = 0; i < NARCH; ++i)
        bits[i] = iii_hal_select(k_all[i])->arch_binding;
    int distinct = 1;
    for (size_t i = 0; i < NARCH; ++i)
        for (size_t j = i + 1; j < NARCH; ++j)
            if (bits[i] == bits[j]) distinct = 0;
    CHECK(distinct, "arch_binding bits distinct across all 5 archs");
}

int main(void) {
    test_hal_presence();
    test_opcodes();
    test_closure_empty();
    test_closure_synthetic();
    test_closure_arch_independence();
    test_hal_behavior();
    test_mappings_distinct();
    test_arch_parse();

    printf("\n=== %d passed, %d failed ===\n", g_pass, g_fail);
    return g_fail == 0 ? 0 : 1;
}
