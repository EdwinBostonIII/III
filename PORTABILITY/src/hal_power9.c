/* HAL: POWER9 hypervisor / radix / PHB.
 * NIH-handcrafted opcode bytes per Power ISA v3.0B.
 * Instructions are 32-bit; we store them big-endian (the architectural
 * encoding form). PPC64LE memory layout is byte-reversed at load. */
#include "iii/portability.h"

/* 0x4C000224 hrfid                          */
static const uint8_t op_HRFID[]   = { 0x4C, 0x00, 0x02, 0x24 };
/* 0x4C000024 rfid                           */
static const uint8_t op_RFID[]    = { 0x4C, 0x00, 0x00, 0x24 };
/* 0x4C00012C isync                          */
static const uint8_t op_ISYNC[]   = { 0x4C, 0x00, 0x01, 0x2C };
/* 0x7C0004AC sync 0 (hwsync)                */
static const uint8_t op_SYNC[]    = { 0x7C, 0x00, 0x04, 0xAC };
/* 0x7C0006AC eieio                          */
static const uint8_t op_EIEIO[]   = { 0x7C, 0x00, 0x06, 0xAC };
/* 0x7C0003E4 slbia                          */
static const uint8_t op_SLBIA[]   = { 0x7C, 0x00, 0x03, 0xE4 };
/* 0x7C0000A6 mfmsr r0                       */
static const uint8_t op_MFMSR[]   = { 0x7C, 0x00, 0x00, 0xA6 };
/* 0x7C000164 mtmsrd r0                      */
static const uint8_t op_MTMSRD[]  = { 0x7C, 0x00, 0x01, 0x64 };
/* 0x7C000124 mtmsr r0                       */
static const uint8_t op_MTMSR[]   = { 0x7C, 0x00, 0x01, 0x24 };
/* 0x7C00046C tlbsync                        */
static const uint8_t op_TLBSYNC[] = { 0x7C, 0x00, 0x04, 0x6C };

static const struct iii_opcode k_opcodes[] = {
    { "hrfid",   op_HRFID,   sizeof op_HRFID   },
    { "rfid",    op_RFID,    sizeof op_RFID    },
    { "isync",   op_ISYNC,   sizeof op_ISYNC   },
    { "sync",    op_SYNC,    sizeof op_SYNC    },
    { "eieio",   op_EIEIO,   sizeof op_EIEIO   },
    { "slbia",   op_SLBIA,   sizeof op_SLBIA   },
    { "mfmsr",   op_MFMSR,   sizeof op_MFMSR   },
    { "mtmsrd",  op_MTMSRD,  sizeof op_MTMSRD  },
    { "mtmsr",   op_MTMSR,   sizeof op_MTMSR   },
    { "tlbsync", op_TLBSYNC, sizeof op_TLBSYNC },
    { 0, 0, 0 }
};

/* LPCR / HSR trap-bit mapping. */
static const uint16_t k_intercept[IIIIC__COUNT] = {
    500,501,502,503,504,505,506,507,508,509,510,511,512,513,514,515,516,517
};

/* §5.2: hypervisor radix PTE + HSR class encoding. */
static const uint64_t k_npt_class[IIINPT__COUNT] = {
    0x0000000000000000ull,
    0x0000000000000080ull,                              /* HSR class */
    0x0000000000000088ull,                              /* +X */
    0x0000000000000200ull,                              /* SECEXT custom */
    0x0000000000000040ull,                              /* W cleared */
    0x0000000000000088ull | 0x0000000000001000ull,
    0x0000000000000080ull | 0x0000000000002000ull,
    0x0000000000000080ull | 0x0000000000004000ull,
    0x0000000000000040ull | 0x0000000000008000ull
};

static const uint8_t k_features[IIIFEAT__COUNT] = {
    /* HV */ 1, /* STAGE2_PT */ 1, /* IOMMU */ 1, /* SHA_ACCEL */ 1,
    /* AES_ACCEL */ 1, /* SIMD */ 1, /* BMI */ 0, /* HW_RNG */ 1,
    /* TSC */ 1, /* MPK */ 0, /* BR_CTRL */ 1
};

#define HAL_PREFIX        power9
#define HAL_ARCH          IIIARCH_POWER9
#define HAL_NAME          "power9"
#define HAL_BINDING       IIIARCH_BINDING_POWER9
#define HAL_OPCODES       k_opcodes
#define HAL_OPCODE_COUNT  (sizeof k_opcodes / sizeof k_opcodes[0] - 1)
#define HAL_INTERCEPT_MAP k_intercept
#define HAL_NPT_CLASS_MAP k_npt_class
#define HAL_FEATURES      k_features
#define HAL_CPU_COUNT     24u
#define HAL_NUMA_COUNT    2u

#include "hal_template.h"
