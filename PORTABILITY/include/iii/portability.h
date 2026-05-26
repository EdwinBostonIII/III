/* III-PORTABILITY: hardware-abstraction layer (HAL) public interface.
 *
 * Implements the architectural mandate of DOCS/III-PORTABILITY.md:
 *   - Uniform HAL vtable across AMD-Zen / Intel-VMX / ARMv8 / RISC-V H / POWER9.
 *   - Cross-architecture closure root (architecture-independent canonical hash).
 *   - Per-architecture opcode-byte tables (NIH: handcrafted machine code, no
 *     external assembler).
 *
 * All HAL operations return iii_witness_t. A witness is a non-zero opaque
 * cookie on success; zero (IIIWITNESS_NONE) indicates failure. This mirrors
 * the III "every primitive returns a witness" discipline.
 */
#ifndef III_PORTABILITY_H
#define III_PORTABILITY_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/* §1.1, §2: enumerated supported architectures. */
typedef enum {
    IIIARCH_X86_64    = 1,   /* AMD-Zen SVM/NPT/AMD-IOMMU */
    IIIARCH_ARMV8     = 2,   /* ARMv8.2+ EL2/Stage-2/SMMU */
    IIIARCH_RISCV_H   = 3,   /* RISC-V H-extension/G-stage/IOMMU-RVI */
    IIIARCH_INTEL_VMX = 4,   /* Intel VMX/EPT/VT-d */
    IIIARCH_POWER9    = 5,   /* POWER9 hypervisor/radix/PHB */
    IIIARCH__COUNT    = 5
} iii_arch_t;

/* §13.1: the 4-ring privilege lattice (R-3 logical .. R3 user). */
typedef enum {
    IIIRING_R_MINUS_3 = -3,  /* Anchor signature gating (logical) */
    IIIRING_R_MINUS_2 = -2,  /* Software Sanctum / SECEXT */
    IIIRING_R_MINUS_1 = -1,  /* Hypervisor */
    IIIRING_R0        =  0,  /* Kernel */
    IIIRING_R3        =  3   /* User */
} iii_ring_t;

/* §3.2: intercept classes mapped per-architecture. */
typedef enum {
    IIIIC_MSR_READ   = 0,
    IIIIC_MSR_WRITE  = 1,
    IIIIC_CR_READ    = 2,
    IIIIC_CR_WRITE   = 3,
    IIIIC_IO_PORT    = 4,
    IIIIC_EXCEPTION  = 5,
    IIIIC_INTERRUPT  = 6,
    IIIIC_CPUID      = 7,
    IIIIC_RDTSC      = 8,
    IIIIC_WBINVD     = 9,
    IIIIC_INVLPG     = 10,
    IIIIC_INVLPGA    = 11,
    IIIIC_MWAIT      = 12,
    IIIIC_MONITOR    = 13,
    IIIIC_PAUSE      = 14,
    IIIIC_HLT        = 15,
    IIIIC_VMRUN      = 16,
    IIIIC_VMMCALL    = 17,
    IIIIC__COUNT     = 18
} iii_intercept_class_t;

/* §5.1: NPT-class trits abstracted across architectures. */
typedef enum {
    IIINPT_UNCLASSIFIED   = 0,
    IIINPT_REDUCTION_DATA = 1,
    IIINPT_CODE           = 2,
    IIINPT_SECEXT         = 3,
    IIINPT_READONLY       = 4,
    IIINPT_JIT_CODE       = 5,
    IIINPT_AUDIT_RING     = 6,
    IIINPT_SUB_KEY        = 7,
    IIINPT_ANCHOR_DATA    = 8,
    IIINPT__COUNT         = 9
} iii_npt_class_t;

/* §2: feature bits used with hal->has_feature. */
typedef enum {
    IIIFEAT_HV         = 0,   /* hypervisor mode (SVM/VMX/EL2/H/HV) */
    IIIFEAT_STAGE2_PT  = 1,   /* NPT/EPT/Stage-2/G-stage/radix */
    IIIFEAT_IOMMU      = 2,
    IIIFEAT_SHA_ACCEL  = 3,   /* SHA-NI / ARM SHA-2 / Zksh / NX */
    IIIFEAT_AES_ACCEL  = 4,
    IIIFEAT_SIMD       = 5,   /* AVX-512 / NEON-SVE2 / Zvkn / VSX */
    IIIFEAT_BMI        = 6,
    IIIFEAT_HW_RNG     = 7,
    IIIFEAT_TSC        = 8,
    IIIFEAT_MPK        = 9,
    IIIFEAT_BR_CTRL    = 10,
    IIIFEAT__COUNT     = 11
} iii_feature_t;

/* §7.4: arch-binding flag bits embedded in witness chain `flags`. */
#define IIIARCH_BINDING_AMD_ZEN    0x01u
#define IIIARCH_BINDING_INTEL_VMX  0x02u
#define IIIARCH_BINDING_ARMV8      0x04u
#define IIIARCH_BINDING_RISCV_H    0x08u
#define IIIARCH_BINDING_POWER9     0x10u

/* Witness cookies (opaque to higher layers). */
typedef uint64_t iii_witness_t;
#define IIIWITNESS_NONE  ((iii_witness_t)0)

/* PCI BDF (bus/device/function) packed. */
typedef uint32_t iii_pci_bdf_t;

/* §3.2: VmCb — opaque architecture-agnostic state-save area. */
typedef struct {
    uint8_t  state_save[1024];
    uint8_t  intercepts[256];
    uint32_t asid;
    int64_t  tsc_offset;
    uint64_t npt_root;
} iii_vmcb_t;

/* §4.2: IOPT entry. */
#define IIIIOPT_R   0x1u
#define IIIIOPT_W   0x2u
#define IIIIOPT_X   0x4u
#define IIIIOPT_UC  0x8u   /* uncacheable */
typedef struct {
    uint64_t iova;
    uint64_t gpa;
    uint64_t size;
    uint32_t flags;
} iii_iopt_entry_t;

/* IOMMU fault delivered to higher layers. */
typedef struct {
    iii_pci_bdf_t bdf;
    uint64_t      iova;
    uint32_t      reason;
} iii_iommu_fault_t;
typedef void (*iii_iommu_fault_handler_t)(const iii_iommu_fault_t *);

/* DRTM (§8.4) relaunch result. */
typedef struct {
    uint8_t  measurement[32];   /* SHA-256 of relaunch surface */
    uint64_t epoch;
} iii_drtm_result_t;

/* The HAL vtable. Each architecture provides one of these. */
typedef struct iii_hal {
    /* Identity / detection. */
    iii_arch_t  arch;
    const char *name;
    uint32_t    arch_binding;             /* IIIARCH_BINDING_* */
    iii_witness_t (*detect)(void);
    int           (*has_feature)(iii_feature_t f);
    uint32_t      (*cpu_count)(void);
    uint32_t      (*numa_node_count)(void);
    uint32_t      (*cpu_to_numa)(uint32_t cpu);

    /* §3 hypervisor / virtualization entry. */
    iii_witness_t (*hv_init)(void);
    iii_witness_t (*hv_vmrun)(iii_vmcb_t *vmcb, uint32_t *exit_reason);
    iii_witness_t (*hv_intercept)(iii_vmcb_t *vmcb, iii_intercept_class_t ic);
    iii_witness_t (*hv_teardown)(void);

    /* §4 IOMMU. */
    iii_witness_t (*iommu_init)(void);
    iii_witness_t (*iommu_map_iopt)(iii_pci_bdf_t bdf, const iii_iopt_entry_t *e);
    iii_witness_t (*iommu_irte_remap)(iii_pci_bdf_t bdf, uint32_t vector,
                                      uint32_t target_cpu);
    iii_witness_t (*iommu_fault_intercept)(iii_iommu_fault_handler_t h);

    /* §5 NPT-class / page-table ops. */
    iii_witness_t (*npt_class_set)(uint64_t gpa, iii_npt_class_t cls);
    iii_npt_class_t (*npt_class_get)(uint64_t gpa);
    iii_witness_t (*npt_invalidate)(uint64_t gpa);

    /* MMU / IOMMU init split (mmu_init = stage-1 host page tables). */
    iii_witness_t (*mmu_init)(void);

    /* §8.4 DRTM software-only relaunch. */
    iii_witness_t (*drtm_relaunch)(iii_drtm_result_t *out);

    /* IPI / timer / cache. */
    iii_witness_t (*ipi_send)(uint32_t target_cpu, uint32_t vector);
    uint64_t      (*timer_now)(void);     /* TSC / CNTPCT / RDTIME / TB */
    iii_witness_t (*cache_flush)(const void *addr, size_t len);

    /* Atomic primitives (architecture-portable abstraction). */
    int           (*atomic_cas64)(volatile uint64_t *p, uint64_t expect,
                                  uint64_t desired);
    uint64_t      (*atomic_add64)(volatile uint64_t *p, int64_t delta);

    /* Opcode-byte tables (NIH: handcrafted machine code).
     * Each entry is {name, bytes, len}. NULL-name terminated. */
    const struct iii_opcode {
        const char    *mnemonic;
        const uint8_t *bytes;
        size_t         len;
    } *opcodes;
    size_t opcode_count;

    /* §3.2 InterceptClass -> arch-specific bit index (closure-pinned). */
    const uint16_t *intercept_map;        /* indexed by iii_intercept_class_t */

    /* §5.2 NPT class -> arch-specific PTE bit pattern (closure-pinned). */
    const uint64_t *npt_class_map;        /* indexed by iii_npt_class_t */
} iii_hal_t;

/* §1.1: select the HAL for a given architecture. Returns NULL if unknown. */
const iii_hal_t *iii_hal_select(iii_arch_t arch);
const iii_hal_t *iii_hal_default(void);   /* compile-host default */
const char      *iii_arch_name(iii_arch_t a);
int              iii_arch_parse(const char *s, iii_arch_t *out);

/* All five HAL vtables, exported for direct linkage / testing. */
extern const iii_hal_t iii_hal_x86_64;
extern const iii_hal_t iii_hal_armv8;
extern const iii_hal_t iii_hal_riscv_h;
extern const iii_hal_t iii_hal_intel_vmx;
extern const iii_hal_t iii_hal_power9;

/* §7: cross-architecture closure root.
 *
 * Each module is identified by a name (UTF-8) and an opaque byte image.
 * Canonical serialization (architecture-independent):
 *
 *   "III/PORTABILITY/CLOSURE/v1\n"             (26 ASCII bytes, fixed prefix)
 *   u32_be(module_count)
 *   for each module sorted lexicographically by name:
 *       u32_be(name_len) || name_bytes
 *       u64_be(byte_len) || byte_bytes
 *
 * The closure root is SHA-256 of the resulting byte stream.
 */
typedef struct {
    const char    *name;
    const uint8_t *bytes;
    size_t         len;
} iii_module_t;

/* Compute the closure root over `n` modules into out[32]. Returns 0 on
 * success, negative on error. Modules are sorted internally; caller need
 * not pre-sort. */
int iii_closure_root_compute(const iii_module_t *modules, size_t n,
                             uint8_t out[32]);

/* Canonicalize-only (for debugging / tooling): writes the canonical byte
 * stream to a caller-provided buffer; returns the number of bytes written
 * (or required, if buf==NULL). */
size_t iii_closure_canonical_serialize(const iii_module_t *modules, size_t n,
                                       uint8_t *buf, size_t cap);

#ifdef __cplusplus
}
#endif
#endif
