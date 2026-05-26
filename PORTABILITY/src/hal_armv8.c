/* HAL: ARMv8.2+ EL2 / Stage-2 / SMMUv3.
 * NIH-handcrafted opcode bytes per ARM ARM (DDI 0487).
 * AArch64 instructions are 32-bit; little-endian byte order in memory. */
#include "iii/portability.h"

/* 0xD69F03C0 ERET                       */
static const uint8_t op_ERET[]    = { 0xC0, 0x03, 0x9F, 0xD6 };
/* 0xD4000002 HVC #0                     */
static const uint8_t op_HVC[]     = { 0x02, 0x00, 0x00, 0xD4 };
/* 0xD4000003 SMC #0                     */
static const uint8_t op_SMC[]     = { 0x03, 0x00, 0x00, 0xD4 };
/* 0xD5033F9F DSB SY                     */
static const uint8_t op_DSB[]     = { 0x9F, 0x3F, 0x03, 0xD5 };
/* 0xD5033FDF ISB SY                     */
static const uint8_t op_ISB[]     = { 0xDF, 0x3F, 0x03, 0xD5 };
/* 0xD503207F WFI                        */
static const uint8_t op_WFI[]     = { 0x7F, 0x20, 0x03, 0xD5 };
/* 0xD508831F TLBI VMALLE1IS             */
static const uint8_t op_TLBI[]    = { 0x1F, 0x83, 0x08, 0xD5 };
/* 0xD5384240 MRS X0, CurrentEL          */
static const uint8_t op_MRS_CEL[] = { 0x40, 0x42, 0x38, 0xD5 };
/* 0xD5087800 AT S1E1R, X0               */
static const uint8_t op_AT[]      = { 0x00, 0x78, 0x08, 0xD5 };
/* 0xD50B7520 IC IALLU                   */
static const uint8_t op_IC[]      = { 0x20, 0x75, 0x0B, 0xD5 };

static const struct iii_opcode k_opcodes[] = {
    { "ERET",       op_ERET,    sizeof op_ERET    },
    { "HVC#0",      op_HVC,     sizeof op_HVC     },
    { "SMC#0",      op_SMC,     sizeof op_SMC     },
    { "DSB.SY",     op_DSB,     sizeof op_DSB     },
    { "ISB.SY",     op_ISB,     sizeof op_ISB     },
    { "WFI",        op_WFI,     sizeof op_WFI     },
    { "TLBI",       op_TLBI,    sizeof op_TLBI    },
    { "MRS_CurEL",  op_MRS_CEL, sizeof op_MRS_CEL },
    { "AT_S1E1R",   op_AT,      sizeof op_AT      },
    { "IC_IALLU",   op_IC,      sizeof op_IC      },
    { 0, 0, 0 }
};

/* HCR_EL2 / VTCR_EL2 trap-bit indices (closure-pinned mapping). */
static const uint16_t k_intercept[IIIIC__COUNT] = {
    300,301,302,303,304,305,306,307,308,309,310,311,312,313,314,315,316,317
};

/* §5.2: ARMv8 Stage-2 AttrIndx + AP encoding. */
static const uint64_t k_npt_class[IIINPT__COUNT] = {
    0x0000000000000000ull,
    0x0000000000000040ull,                              /* AttrIndx[2:0]=001 << 2 */
    0x0000000000000044ull,                              /* + X (XN cleared marker) */
    0x0000000000000080ull,                              /* security extension */
    0x0000000000000020ull,                              /* AP[1]=1 read-only */
    0x0000000000000044ull | 0x0000000000004000ull,     /* + protection key */
    0x0000000000000040ull | 0x0000000000000800ull,     /* sync */
    0x0000000000000040ull | 0x0000000000008000ull,
    0x0000000000000020ull | 0x0000000000000100ull
};

static const uint8_t k_features[IIIFEAT__COUNT] = {
    /* HV */ 1, /* STAGE2_PT */ 1, /* IOMMU */ 1, /* SHA_ACCEL */ 1,
    /* AES_ACCEL */ 1, /* SIMD */ 1, /* BMI */ 0, /* HW_RNG */ 1,
    /* TSC */ 1, /* MPK */ 0, /* BR_CTRL */ 1
};

#define HAL_PREFIX        armv8
#define HAL_ARCH          IIIARCH_ARMV8
#define HAL_NAME          "armv8"
#define HAL_BINDING       IIIARCH_BINDING_ARMV8
#define HAL_OPCODES       k_opcodes
#define HAL_OPCODE_COUNT  (sizeof k_opcodes / sizeof k_opcodes[0] - 1)
#define HAL_INTERCEPT_MAP k_intercept
#define HAL_NPT_CLASS_MAP k_npt_class
#define HAL_FEATURES      k_features
#define HAL_CPU_COUNT     8u
#define HAL_NUMA_COUNT    1u

#include "hal_template.h"
