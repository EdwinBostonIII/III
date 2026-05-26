/* iii/legacy detection + status helpers (NIH). */
#include "iii/legacy.h"
#include <string.h>
#include <stdlib.h>

const char *iii_legacy_status_str(iii_legacy_status_t s) {
    switch (s) {
        case III_LS_OK:          return "ok";
        case III_LS_TRUNCATED:   return "truncated";
        case III_LS_BAD_MAGIC:   return "bad_magic";
        case III_LS_UNSUPPORTED: return "unsupported";
        case III_LS_OVERFLOW:    return "overflow";
        case III_LS_BAD_OFFSET:  return "bad_offset";
        case III_LS_BAD_FIELD:   return "bad_field";
        case III_LS_NO_MEMORY:   return "no_memory";
        case III_LS_INVALID:     return "invalid";
    }
    return "?";
}

iii_legacy_format_t iii_legacy_detect(const uint8_t *b, size_t n) {
    if (!b || n < 4) return III_LF_UNKNOWN;
    /* ELF: 7f 45 4c 46 */
    if (b[0] == 0x7f && b[1] == 'E' && b[2] == 'L' && b[3] == 'F') {
        return III_LF_ELF;
    }
    /* Mach-O fat (big-endian on disk) */
    if (n >= 4) {
        uint32_t m = ((uint32_t)b[0] << 24) | ((uint32_t)b[1] << 16) |
                     ((uint32_t)b[2] << 8) | (uint32_t)b[3];
        if (m == III_MACHO_FAT_MAGIC || m == III_MACHO_FAT_MAGIC_64) {
            return III_LF_MACHO_FAT;
        }
    }
    /* Mach-O thin (little-endian magic on x86/arm64 hosts) */
    if (n >= 4) {
        uint32_t m = (uint32_t)b[0] | ((uint32_t)b[1] << 8) |
                     ((uint32_t)b[2] << 16) | ((uint32_t)b[3] << 24);
        if (m == III_MACHO_MAGIC32 || m == III_MACHO_MAGIC64) {
            return III_LF_MACHO;
        }
    }
    /* PE: starts with MZ then has PE\0\0 at e_lfanew */
    if (n >= 64 && b[0] == 'M' && b[1] == 'Z') {
        uint32_t lfa = (uint32_t)b[60] | ((uint32_t)b[61] << 8) |
                       ((uint32_t)b[62] << 16) | ((uint32_t)b[63] << 24);
        if (lfa + 4 <= n && b[lfa] == 'P' && b[lfa+1] == 'E' &&
            b[lfa+2] == 0 && b[lfa+3] == 0) {
            return III_LF_PE;
        }
    }
    /* COFF: leading 16-bit machine field equals known machine.
     * Only consider when not PE/ELF/Mach-O. */
    if (n >= 20) {
        uint16_t m = (uint16_t)b[0] | ((uint16_t)b[1] << 8);
        if (m == III_COFF_MACHINE_I386 || m == III_COFF_MACHINE_AMD64 ||
            m == III_COFF_MACHINE_ARM || m == III_COFF_MACHINE_ARM64) {
            return III_LF_COFF;
        }
    }
    return III_LF_RAW;
}

iii_legacy_status_t iii_legacy_parse_auto(const uint8_t *b, size_t n,
                                          iii_legacy_module_t *out) {
    iii_legacy_format_t f = iii_legacy_detect(b, n);
    switch (f) {
        case III_LF_ELF:        return iii_legacy_parse_elf(b, n, out);
        case III_LF_PE:         return iii_legacy_parse_pe(b, n, out);
        case III_LF_MACHO:      return iii_legacy_parse_macho(b, n, out);
        case III_LF_MACHO_FAT:  return iii_legacy_parse_macho(b, n, out);
        case III_LF_COFF:       return iii_legacy_parse_coff(b, n, out);
        default:
            memset(out, 0, sizeof(*out));
            out->format = f;
            return III_LS_UNSUPPORTED;
    }
}

void iii_legacy_module_free(iii_legacy_module_t *m) {
    if (!m) return;
    switch (m->format) {
        case III_LF_ELF:
            free(m->u.elf.sections); free(m->u.elf.segments); free(m->u.elf.symbols);
            break;
        case III_LF_PE:
            free(m->u.pe.sections);
            break;
        case III_LF_MACHO:
        case III_LF_MACHO_FAT:
            free(m->u.macho.segments); free(m->u.macho.sections);
            break;
        case III_LF_COFF:
            free(m->u.coff.sections);
            break;
        default: break;
    }
    memset(m, 0, sizeof(*m));
}
