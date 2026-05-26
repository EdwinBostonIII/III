/* HAL: Intel VMX. NIH-handcrafted opcode bytes per Intel SDM Vol 3C/4. */
#include "iii/portability.h"

/* VMX-class instructions (most use 0F 01 Cx or 0F 78/79 / 0F 38). */
static const uint8_t op_VMXON[]    = { 0xF3, 0x0F, 0xC7, 0x30 };
static const uint8_t op_VMXOFF[]   = { 0x0F, 0x01, 0xC4 };
static const uint8_t op_VMCLEAR[]  = { 0x66, 0x0F, 0xC7, 0x30 };
static const uint8_t op_VMPTRLD[]  = { 0x0F, 0xC7, 0x30 };
static const uint8_t op_VMPTRST[]  = { 0x0F, 0xC7, 0x38 };
static const uint8_t op_VMLAUNCH[] = { 0x0F, 0x01, 0xC2 };
static const uint8_t op_VMRESUME[] = { 0x0F, 0x01, 0xC3 };
static const uint8_t op_VMREAD[]   = { 0x0F, 0x78 };
static const uint8_t op_VMWRITE[]  = { 0x0F, 0x79 };
static const uint8_t op_INVEPT[]   = { 0x66, 0x0F, 0x38, 0x80 };
static const uint8_t op_INVVPID[]  = { 0x66, 0x0F, 0x38, 0x81 };
static const uint8_t op_VMCALL[]   = { 0x0F, 0x01, 0xC1 };

static const struct iii_opcode k_opcodes[] = {
    { "VMXON",    op_VMXON,    sizeof op_VMXON    },
    { "VMXOFF",   op_VMXOFF,   sizeof op_VMXOFF   },
    { "VMCLEAR",  op_VMCLEAR,  sizeof op_VMCLEAR  },
    { "VMPTRLD",  op_VMPTRLD,  sizeof op_VMPTRLD  },
    { "VMPTRST",  op_VMPTRST,  sizeof op_VMPTRST  },
    { "VMLAUNCH", op_VMLAUNCH, sizeof op_VMLAUNCH },
    { "VMRESUME", op_VMRESUME, sizeof op_VMRESUME },
    { "VMREAD",   op_VMREAD,   sizeof op_VMREAD   },
    { "VMWRITE",  op_VMWRITE,  sizeof op_VMWRITE  },
    { "INVEPT",   op_INVEPT,   sizeof op_INVEPT   },
    { "INVVPID",  op_INVVPID,  sizeof op_INVVPID  },
    { "VMCALL",   op_VMCALL,   sizeof op_VMCALL   },
    { 0, 0, 0 }
};

/* §3.2: VMX VM-exit-control mappings (closure-pinned). */
static const uint16_t k_intercept[IIIIC__COUNT] = {
    200,201,202,203,204,205,206,207,208,209,210,211,212,213,214,215,216,217
};

/* §5.2: EPT class encoding. */
static const uint64_t k_npt_class[IIINPT__COUNT] = {
    0x0000000000000000ull,
    0x0100000000000000ull,
    0x0100000000000000ull | 0x4ull,
    0x0020000000000000ull,
    0x0000000000000002ull,
    0x0100000000000000ull | 0x80000000ull,
    0x0100000000000000ull | 0x40ull,
    0x0100000000000000ull | 0x90000000ull,
    0x0100000000000000ull | 0x200ull
};

static const uint8_t k_features[IIIFEAT__COUNT] = {
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
};

#define HAL_PREFIX        intel_vmx
#define HAL_ARCH          IIIARCH_INTEL_VMX
#define HAL_NAME          "intel_vmx"
#define HAL_BINDING       IIIARCH_BINDING_INTEL_VMX
#define HAL_OPCODES       k_opcodes
#define HAL_OPCODE_COUNT  (sizeof k_opcodes / sizeof k_opcodes[0] - 1)
#define HAL_INTERCEPT_MAP k_intercept
#define HAL_NPT_CLASS_MAP k_npt_class
#define HAL_FEATURES      k_features
#define HAL_CPU_COUNT     32u
#define HAL_NUMA_COUNT    2u

#include "hal_template.h"
