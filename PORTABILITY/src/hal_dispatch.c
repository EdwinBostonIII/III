/* HAL dispatch / arch-name helpers. */
#include "iii/portability.h"
#include <string.h>

const iii_hal_t *iii_hal_select(iii_arch_t arch) {
    switch (arch) {
        case IIIARCH_X86_64:    return &iii_hal_x86_64;
        case IIIARCH_ARMV8:     return &iii_hal_armv8;
        case IIIARCH_RISCV_H:   return &iii_hal_riscv_h;
        case IIIARCH_INTEL_VMX: return &iii_hal_intel_vmx;
        case IIIARCH_POWER9:    return &iii_hal_power9;
        default:                return (const iii_hal_t *)0;
    }
}

const iii_hal_t *iii_hal_default(void) {
#if defined(__x86_64__) || defined(_M_X64)
    return &iii_hal_x86_64;
#elif defined(__aarch64__)
    return &iii_hal_armv8;
#elif defined(__riscv) && (__riscv_xlen == 64)
    return &iii_hal_riscv_h;
#elif defined(__powerpc64__) || defined(__ppc64__)
    return &iii_hal_power9;
#else
    return &iii_hal_x86_64;
#endif
}

const char *iii_arch_name(iii_arch_t a) {
    switch (a) {
        case IIIARCH_X86_64:    return "x86_64";
        case IIIARCH_ARMV8:     return "armv8";
        case IIIARCH_RISCV_H:   return "riscv_h";
        case IIIARCH_INTEL_VMX: return "intel_vmx";
        case IIIARCH_POWER9:    return "power9";
        default:                return "unknown";
    }
}

int iii_arch_parse(const char *s, iii_arch_t *out) {
    if (!s || !out) return -1;
    if (!strcmp(s, "x86_64") || !strcmp(s, "amd_zen") || !strcmp(s, "x86-64"))
        { *out = IIIARCH_X86_64; return 0; }
    if (!strcmp(s, "armv8") || !strcmp(s, "aarch64") || !strcmp(s, "arm64"))
        { *out = IIIARCH_ARMV8; return 0; }
    if (!strcmp(s, "riscv_h") || !strcmp(s, "riscv64") || !strcmp(s, "rv64h"))
        { *out = IIIARCH_RISCV_H; return 0; }
    if (!strcmp(s, "intel_vmx") || !strcmp(s, "vmx") || !strcmp(s, "intel"))
        { *out = IIIARCH_INTEL_VMX; return 0; }
    if (!strcmp(s, "power9") || !strcmp(s, "ppc64") || !strcmp(s, "ppc64le"))
        { *out = IIIARCH_POWER9; return 0; }
    return -1;
}
