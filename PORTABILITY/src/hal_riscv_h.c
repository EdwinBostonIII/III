/* HAL: RISC-V H-extension. NIH-handcrafted opcode bytes per RISC-V Priv Spec.
 * Instructions are 32-bit, little-endian in memory. */
#include "iii/portability.h"

/* 0x10500073 WFI                          */
static const uint8_t op_WFI[]      = { 0x73, 0x00, 0x50, 0x10 };
/* 0x30200073 MRET                         */
static const uint8_t op_MRET[]     = { 0x73, 0x00, 0x20, 0x30 };
/* 0x10200073 SRET                         */
static const uint8_t op_SRET[]     = { 0x73, 0x00, 0x20, 0x10 };
/* 0x00000073 ECALL                        */
static const uint8_t op_ECALL[]    = { 0x73, 0x00, 0x00, 0x00 };
/* 0x00100073 EBREAK                       */
static const uint8_t op_EBREAK[]   = { 0x73, 0x00, 0x10, 0x00 };
/* 0x62000073 HFENCE.GVMA x0, x0           */
static const uint8_t op_HFGVMA[]   = { 0x73, 0x00, 0x00, 0x62 };
/* 0x22000073 HFENCE.VVMA x0, x0           */
static const uint8_t op_HFVVMA[]   = { 0x73, 0x00, 0x00, 0x22 };
/* 0x12000073 SFENCE.VMA x0, x0            */
static const uint8_t op_SFVMA[]    = { 0x73, 0x00, 0x00, 0x12 };
/* 0x60002073 CSRRS x0, hstatus, x0        */
static const uint8_t op_CSRRS_H[]  = { 0x73, 0x20, 0x00, 0x60 };
/* 0x18000073 SFENCE.W.INVAL  (Zicbom-ish; encoded as SYSTEM with funct7=0x0C) */
static const uint8_t op_FENCE_I[]  = { 0x0F, 0x10, 0x00, 0x00 };  /* fence.i */

static const struct iii_opcode k_opcodes[] = {
    { "WFI",         op_WFI,     sizeof op_WFI     },
    { "MRET",        op_MRET,    sizeof op_MRET    },
    { "SRET",        op_SRET,    sizeof op_SRET    },
    { "ECALL",       op_ECALL,   sizeof op_ECALL   },
    { "EBREAK",      op_EBREAK,  sizeof op_EBREAK  },
    { "HFENCE.GVMA", op_HFGVMA,  sizeof op_HFGVMA  },
    { "HFENCE.VVMA", op_HFVVMA,  sizeof op_HFVVMA  },
    { "SFENCE.VMA",  op_SFVMA,   sizeof op_SFVMA   },
    { "CSRRS_H",     op_CSRRS_H, sizeof op_CSRRS_H },
    { "FENCE.I",     op_FENCE_I, sizeof op_FENCE_I },
    { 0, 0, 0 }
};

/* hstatus / hedeleg / hideleg trap-bit mapping. */
static const uint16_t k_intercept[IIIIC__COUNT] = {
    400,401,402,403,404,405,406,407,408,409,410,411,412,413,414,415,416,417
};

/* §5.2: G-stage PTE encoding + PMP key per class. */
static const uint64_t k_npt_class[IIINPT__COUNT] = {
    0x0000000000000000ull,
    0x0000000000000010ull,                              /* PTE.G */
    0x0000000000000018ull,                              /* +X */
    0x0000000000000040ull,                              /* SECEXT custom */
    0x0000000000000004ull,                              /* W cleared */
    0x0000000000000018ull | 0x0000000000000080ull,     /* + PMP key */
    0x0000000000000010ull | 0x0000000000000200ull,
    0x0000000000000010ull | 0x0000000000000100ull,
    0x0000000000000004ull | 0x0000000000000400ull
};

static const uint8_t k_features[IIIFEAT__COUNT] = {
    /* HV */ 1, /* STAGE2_PT */ 1, /* IOMMU */ 1, /* SHA_ACCEL */ 1,
    /* AES_ACCEL */ 1, /* SIMD */ 1, /* BMI */ 1, /* HW_RNG */ 1,
    /* TSC */ 1, /* MPK */ 0, /* BR_CTRL */ 0
};

#define HAL_PREFIX        riscv_h
#define HAL_ARCH          IIIARCH_RISCV_H
#define HAL_NAME          "riscv_h"
#define HAL_BINDING       IIIARCH_BINDING_RISCV_H
#define HAL_OPCODES       k_opcodes
#define HAL_OPCODE_COUNT  (sizeof k_opcodes / sizeof k_opcodes[0] - 1)
#define HAL_INTERCEPT_MAP k_intercept
#define HAL_NPT_CLASS_MAP k_npt_class
#define HAL_FEATURES      k_features
#define HAL_CPU_COUNT     4u
#define HAL_NUMA_COUNT    1u

#include "hal_template.h"
