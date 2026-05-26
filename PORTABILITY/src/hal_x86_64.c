/* HAL: AMD-Zen / x86-64 SVM. NIH-handcrafted opcode bytes per AMD APM. */
#include "iii/portability.h"

/* Opcode bytes (raw machine code, hand-encoded). */
static const uint8_t op_VMRUN[]   = { 0x0F, 0x01, 0xD8 };
static const uint8_t op_VMMCALL[] = { 0x0F, 0x01, 0xD9 };
static const uint8_t op_VMLOAD[]  = { 0x0F, 0x01, 0xDA };
static const uint8_t op_VMSAVE[]  = { 0x0F, 0x01, 0xDB };
static const uint8_t op_STGI[]    = { 0x0F, 0x01, 0xDC };
static const uint8_t op_CLGI[]    = { 0x0F, 0x01, 0xDD };
static const uint8_t op_INVLPGA[] = { 0x0F, 0x01, 0xDF };
static const uint8_t op_RDTSC[]   = { 0x0F, 0x31 };
static const uint8_t op_WBINVD[]  = { 0x0F, 0x09 };
static const uint8_t op_CPUID[]   = { 0x0F, 0xA2 };

static const struct iii_opcode k_opcodes[] = {
    { "VMRUN",   op_VMRUN,   sizeof op_VMRUN   },
    { "VMMCALL", op_VMMCALL, sizeof op_VMMCALL },
    { "VMLOAD",  op_VMLOAD,  sizeof op_VMLOAD  },
    { "VMSAVE",  op_VMSAVE,  sizeof op_VMSAVE  },
    { "STGI",    op_STGI,    sizeof op_STGI    },
    { "CLGI",    op_CLGI,    sizeof op_CLGI    },
    { "INVLPGA", op_INVLPGA, sizeof op_INVLPGA },
    { "RDTSC",   op_RDTSC,   sizeof op_RDTSC   },
    { "WBINVD",  op_WBINVD,  sizeof op_WBINVD  },
    { "CPUID",   op_CPUID,   sizeof op_CPUID   },
    { 0, 0, 0 }
};

/* §3.2: AMD-V intercept bit positions (closure-pinned). */
static const uint16_t k_intercept[IIIIC__COUNT] = {
    /* MSR_READ */   100, /* MSR_WRITE */ 101, /* CR_READ */   102,
    /* CR_WRITE */   103, /* IO_PORT */   104, /* EXCEPTION */ 105,
    /* INTERRUPT */  106, /* CPUID */     107, /* RDTSC */     108,
    /* WBINVD */     109, /* INVLPG */    110, /* INVLPGA */   111,
    /* MWAIT */      112, /* MONITOR */   113, /* PAUSE */     114,
    /* HLT */        115, /* VMRUN */     116, /* VMMCALL */   117
};

/* §5.2: AMD NPT class encoding (closure-pinned). */
static const uint64_t k_npt_class[IIINPT__COUNT] = {
    /* UNCLASSIFIED   */ 0x0000000000000000ull,
    /* REDUCTION_DATA */ 0x0100000000000000ull,                 /* bit 56 */
    /* CODE           */ 0x0100000000000000ull | 0x4ull,        /* + X */
    /* SECEXT         */ 0x0020000000000000ull,                 /* bit 53 */
    /* READONLY       */ 0x0000000000000001ull,                 /* W cleared marker */
    /* JIT_CODE       */ 0x0100000000000000ull | 0x80000000ull, /* + MPK key */
    /* AUDIT_RING     */ 0x0100000000000000ull | 0x40ull,       /* cache-aligned */
    /* SUB_KEY        */ 0x0100000000000000ull | 0x90000000ull,
    /* ANCHOR_DATA    */ 0x0100000000000000ull | 0x100ull       /* W cleared + pinned */
};

static const uint8_t k_features[IIIFEAT__COUNT] = {
    /* HV */ 1, /* STAGE2_PT */ 1, /* IOMMU */ 1, /* SHA_ACCEL */ 1,
    /* AES_ACCEL */ 1, /* SIMD */ 1, /* BMI */ 1, /* HW_RNG */ 1,
    /* TSC */ 1, /* MPK */ 1, /* BR_CTRL */ 1
};

#define HAL_PREFIX        x86_64
#define HAL_ARCH          IIIARCH_X86_64
#define HAL_NAME          "x86_64"
#define HAL_BINDING       IIIARCH_BINDING_AMD_ZEN
#define HAL_OPCODES       k_opcodes
#define HAL_OPCODE_COUNT  (sizeof k_opcodes / sizeof k_opcodes[0] - 1)
#define HAL_INTERCEPT_MAP k_intercept
#define HAL_NPT_CLASS_MAP k_npt_class
#define HAL_FEATURES      k_features
#define HAL_CPU_COUNT     16u
#define HAL_NUMA_COUNT    2u

#include "hal_template.h"
