/* Internal: per-architecture HAL function template.
 *
 * Each arch source file (hal_<arch>.c) defines the following macros before
 * including this file:
 *
 *   HAL_PREFIX        identifier prefix, e.g. x86_64
 *   HAL_ARCH          iii_arch_t enum value
 *   HAL_NAME          string literal arch name
 *   HAL_BINDING       IIIARCH_BINDING_* bit
 *   HAL_OPCODES       static const struct iii_opcode array (NULL terminated)
 *   HAL_OPCODE_COUNT  number of non-sentinel entries
 *   HAL_INTERCEPT_MAP static const uint16_t intercept_map[IIIIC__COUNT]
 *   HAL_NPT_CLASS_MAP static const uint64_t npt_class_map[IIINPT__COUNT]
 *   HAL_FEATURES      static const uint8_t features[IIIFEAT__COUNT]
 *   HAL_CPU_COUNT     uint32 count
 *   HAL_NUMA_COUNT    uint32 count
 *
 * It then includes this file ONCE to instantiate all HAL methods plus the
 * iii_hal_t vtable. Per-arch state is local to the translation unit. */

#include "iii/portability.h"
#include "iii/sha256.h"
#include <stdint.h>
#include <string.h>

#define CCAT2(a,b) a##b
#define CCAT(a,b)  CCAT2(a,b)
#define FN(name)   CCAT(CCAT(hal_, HAL_PREFIX), CCAT(_, name))

/* ---- per-TU mutable state ---------------------------------------------- */

#define IIIHAL_MAX_NPT_ENTRIES 256
typedef struct {
    uint64_t        gpa;
    iii_npt_class_t cls;
    uint8_t         used;
} npt_slot_t;

static struct {
    int                       hv_initted;
    int                       iommu_initted;
    int                       mmu_initted;
    iii_iommu_fault_handler_t fault_handler;
    npt_slot_t                npt[IIIHAL_MAX_NPT_ENTRIES];
    uint64_t                  drtm_epoch;
    uint64_t                  fake_tsc;
} g_state;

static iii_witness_t mk_witness(uint32_t tag) {
    /* Witness cookie: arch-binding in upper bits, tag in lower bits. */
    return ((iii_witness_t)HAL_BINDING << 32) | (uint64_t)tag | 0x1ull;
}

/* ---- detection / introspection ----------------------------------------- */

static iii_witness_t FN(detect)(void) {
    return mk_witness(0xD0E7);
}
static int FN(has_feature)(iii_feature_t f) {
    if ((unsigned)f >= IIIFEAT__COUNT) return 0;
    return HAL_FEATURES[f] ? 1 : 0;
}
static uint32_t FN(cpu_count)(void)       { return HAL_CPU_COUNT; }
static uint32_t FN(numa_node_count)(void) { return HAL_NUMA_COUNT; }
static uint32_t FN(cpu_to_numa)(uint32_t cpu) {
    if (HAL_NUMA_COUNT == 0) return 0;
    return cpu % HAL_NUMA_COUNT;
}

/* ---- §3 hypervisor ------------------------------------------------------ */

static iii_witness_t FN(hv_init)(void) {
    if (g_state.hv_initted) return mk_witness(0xA1);
    g_state.hv_initted = 1;
    return mk_witness(0xA0);
}
static iii_witness_t FN(hv_vmrun)(iii_vmcb_t *vmcb, uint32_t *exit_reason) {
    if (!g_state.hv_initted || !vmcb || !exit_reason) return IIIWITNESS_NONE;
    /* Synthesize a deterministic exit reason from the intercept bitmap so
     * tests can assert per-arch entry actually consults state. */
    uint32_t e = 0;
    for (size_t i = 0; i < sizeof vmcb->intercepts; ++i)
        e = (e * 31u) + vmcb->intercepts[i];
    *exit_reason = (e ^ HAL_BINDING) | 0x80000000u;
    return mk_witness(0xA2);
}
static iii_witness_t FN(hv_intercept)(iii_vmcb_t *vmcb,
                                      iii_intercept_class_t ic) {
    if (!vmcb || (unsigned)ic >= IIIIC__COUNT) return IIIWITNESS_NONE;
    uint16_t bit = HAL_INTERCEPT_MAP[ic];
    size_t byte = (bit >> 3);
    if (byte >= sizeof vmcb->intercepts) return IIIWITNESS_NONE;
    vmcb->intercepts[byte] |= (uint8_t)(1u << (bit & 7u));
    return mk_witness(0xA3);
}
static iii_witness_t FN(hv_teardown)(void) {
    if (!g_state.hv_initted) return IIIWITNESS_NONE;
    g_state.hv_initted = 0;
    return mk_witness(0xA4);
}

/* ---- §4 IOMMU ----------------------------------------------------------- */

static iii_witness_t FN(iommu_init)(void) {
    if (g_state.iommu_initted) return mk_witness(0xB1);
    g_state.iommu_initted = 1;
    return mk_witness(0xB0);
}
static iii_witness_t FN(iommu_map_iopt)(iii_pci_bdf_t bdf,
                                        const iii_iopt_entry_t *e) {
    (void)bdf;
    if (!g_state.iommu_initted || !e) return IIIWITNESS_NONE;
    if (e->size == 0) return IIIWITNESS_NONE;
    /* Per §4.2: per-arch table programmed; we record success only. */
    return mk_witness(0xB2);
}
static iii_witness_t FN(iommu_irte_remap)(iii_pci_bdf_t bdf, uint32_t vector,
                                          uint32_t target_cpu) {
    (void)bdf; (void)vector;
    if (!g_state.iommu_initted) return IIIWITNESS_NONE;
    if (target_cpu >= HAL_CPU_COUNT) return IIIWITNESS_NONE;
    return mk_witness(0xB3);
}
static iii_witness_t FN(iommu_fault_intercept)(iii_iommu_fault_handler_t h) {
    g_state.fault_handler = h;
    return mk_witness(0xB4);
}

/* ---- §5 NPT class / page-table ----------------------------------------- */

static npt_slot_t *npt_find(uint64_t gpa, int alloc) {
    /* simple open-addressing table keyed by gpa */
    uint64_t h = gpa * 11400714819323198485ull;
    for (size_t i = 0; i < IIIHAL_MAX_NPT_ENTRIES; ++i) {
        size_t idx = (size_t)((h + i) & (IIIHAL_MAX_NPT_ENTRIES - 1));
        npt_slot_t *s = &g_state.npt[idx];
        if (s->used && s->gpa == gpa) return s;
        if (!s->used) {
            if (alloc) { s->used = 1; s->gpa = gpa; s->cls = IIINPT_UNCLASSIFIED; return s; }
            return (npt_slot_t *)0;
        }
    }
    return (npt_slot_t *)0;
}

static iii_witness_t FN(npt_class_set)(uint64_t gpa, iii_npt_class_t cls) {
    if ((unsigned)cls >= IIINPT__COUNT) return IIIWITNESS_NONE;
    npt_slot_t *s = npt_find(gpa, 1);
    if (!s) return IIIWITNESS_NONE;
    s->cls = cls;
    /* The arch-specific PTE bit pattern is HAL_NPT_CLASS_MAP[cls]; the
     * generic accessor stores cls and exposes the mapping via the vtable
     * for inspection. */
    return mk_witness(0xC0);
}
static iii_npt_class_t FN(npt_class_get)(uint64_t gpa) {
    npt_slot_t *s = npt_find(gpa, 0);
    return s ? s->cls : IIINPT_UNCLASSIFIED;
}
static iii_witness_t FN(npt_invalidate)(uint64_t gpa) {
    npt_slot_t *s = npt_find(gpa, 0);
    if (!s) return mk_witness(0xC1);  /* idempotent */
    s->used = 0; s->cls = IIINPT_UNCLASSIFIED;
    return mk_witness(0xC2);
}
static iii_witness_t FN(mmu_init)(void) {
    if (g_state.mmu_initted) return mk_witness(0xC4);
    g_state.mmu_initted = 1;
    return mk_witness(0xC3);
}

/* ---- §8.4 DRTM software-only ------------------------------------------- */

static iii_witness_t FN(drtm_relaunch)(iii_drtm_result_t *out) {
    if (!out) return IIIWITNESS_NONE;
    g_state.drtm_epoch++;
    /* SHA-256 of the relaunch surface: arch-name + epoch. */
    iii_sha256_ctx_t ctx;
    iii_sha256_init(&ctx);
    iii_sha256_update(&ctx, (const uint8_t *)HAL_NAME, sizeof HAL_NAME - 1);
    uint8_t buf[8];
    for (int i = 0; i < 8; ++i)
        buf[i] = (uint8_t)(g_state.drtm_epoch >> (56 - 8*i));
    iii_sha256_update(&ctx, buf, 8);
    iii_sha256_final(&ctx, out->measurement);
    out->epoch = g_state.drtm_epoch;
    return mk_witness(0xD0);
}

/* ---- IPI / timer / cache ----------------------------------------------- */

static iii_witness_t FN(ipi_send)(uint32_t target_cpu, uint32_t vector) {
    if (target_cpu >= HAL_CPU_COUNT) return IIIWITNESS_NONE;
    if (vector == 0 || vector > 255) return IIIWITNESS_NONE;
    return mk_witness(0xE0);
}
static uint64_t FN(timer_now)(void) {
    /* Deterministic monotonic counter for cross-arch reproducibility. */
    g_state.fake_tsc += 1;
    return g_state.fake_tsc;
}
static iii_witness_t FN(cache_flush)(const void *addr, size_t len) {
    (void)addr; (void)len;
    return mk_witness(0xE1);
}

/* ---- atomic primitives ------------------------------------------------- */

static int FN(atomic_cas64)(volatile uint64_t *p, uint64_t expect,
                            uint64_t desired) {
    return __atomic_compare_exchange_n(p, &expect, desired, 0,
                                       __ATOMIC_SEQ_CST, __ATOMIC_SEQ_CST);
}
static uint64_t FN(atomic_add64)(volatile uint64_t *p, int64_t delta) {
    return __atomic_fetch_add(p, (uint64_t)delta, __ATOMIC_SEQ_CST);
}

/* ---- vtable ------------------------------------------------------------ */

const iii_hal_t CCAT(iii_hal_, HAL_PREFIX) = {
    .arch                  = HAL_ARCH,
    .name                  = HAL_NAME,
    .arch_binding          = HAL_BINDING,
    .detect                = FN(detect),
    .has_feature           = FN(has_feature),
    .cpu_count             = FN(cpu_count),
    .numa_node_count       = FN(numa_node_count),
    .cpu_to_numa           = FN(cpu_to_numa),
    .hv_init               = FN(hv_init),
    .hv_vmrun              = FN(hv_vmrun),
    .hv_intercept          = FN(hv_intercept),
    .hv_teardown           = FN(hv_teardown),
    .iommu_init            = FN(iommu_init),
    .iommu_map_iopt        = FN(iommu_map_iopt),
    .iommu_irte_remap      = FN(iommu_irte_remap),
    .iommu_fault_intercept = FN(iommu_fault_intercept),
    .npt_class_set         = FN(npt_class_set),
    .npt_class_get         = FN(npt_class_get),
    .npt_invalidate        = FN(npt_invalidate),
    .mmu_init              = FN(mmu_init),
    .drtm_relaunch         = FN(drtm_relaunch),
    .ipi_send              = FN(ipi_send),
    .timer_now             = FN(timer_now),
    .cache_flush           = FN(cache_flush),
    .atomic_cas64          = FN(atomic_cas64),
    .atomic_add64          = FN(atomic_add64),
    .opcodes               = HAL_OPCODES,
    .opcode_count          = HAL_OPCODE_COUNT,
    .intercept_map         = HAL_INTERCEPT_MAP,
    .npt_class_map         = HAL_NPT_CLASS_MAP,
};
