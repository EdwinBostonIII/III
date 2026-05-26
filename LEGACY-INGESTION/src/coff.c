/* III LEGACY-INGESTION — COFF object parser (NIH). */
#include "iii/legacy.h"
#include "internal.h"
#include "iii/sha256.h"
#include <stdlib.h>
#include <string.h>

static iii_legacy_arch_t map_coff_machine(uint16_t m) {
    switch (m) {
        case III_COFF_MACHINE_I386:  return III_LA_X86;
        case III_COFF_MACHINE_AMD64: return III_LA_X86_64;
        case III_COFF_MACHINE_ARM:   return III_LA_ARM;
        case III_COFF_MACHINE_ARM64: return III_LA_ARM64;
        default: return III_LA_UNKNOWN;
    }
}

iii_legacy_status_t iii_legacy_parse_coff(const uint8_t *b, size_t n,
                                          iii_legacy_module_t *out) {
    memset(out, 0, sizeof(*out));
    iii_coff_module_t *cm = &out->u.coff;
    if (n < 20) return III_LS_TRUNCATED;
    iii_le_read_u16(b, n, 0,  &cm->file.machine);
    iii_le_read_u16(b, n, 2,  &cm->file.number_of_sections);
    iii_le_read_u32(b, n, 4,  &cm->file.time_date_stamp);
    iii_le_read_u32(b, n, 8,  &cm->file.pointer_to_symbol_table);
    iii_le_read_u32(b, n, 12, &cm->file.number_of_symbols);
    iii_le_read_u16(b, n, 16, &cm->file.size_of_optional_header);
    iii_le_read_u16(b, n, 18, &cm->file.characteristics);

    if (map_coff_machine(cm->file.machine) == III_LA_UNKNOWN) return III_LS_BAD_MAGIC;

    cm->section_count = cm->file.number_of_sections;
    cm->symbol_count  = cm->file.number_of_symbols;

    size_t sec_off = 20 + cm->file.size_of_optional_header;
    if (cm->section_count) {
        if (sec_off + (size_t)cm->section_count * 40 > n) return III_LS_BAD_OFFSET;
        cm->sections = calloc(cm->section_count, sizeof(*cm->sections));
        if (!cm->sections) return III_LS_NO_MEMORY;
        for (uint16_t i = 0; i < cm->section_count; i++) {
            size_t o = sec_off + (size_t)i * 40;
            iii_coff_section_info_t *sec = &cm->sections[i];
            for (int k = 0; k < 8; k++) sec->name[k] = (char)b[o + k];
            sec->name[8] = 0;
            iii_le_read_u32(b, n, o + 16, &sec->size_of_raw_data);
            iii_le_read_u32(b, n, o + 20, &sec->pointer_to_raw_data);
            iii_le_read_u32(b, n, o + 36, &sec->characteristics);
        }
    }

    out->format = III_LF_COFF;
    out->arch   = map_coff_machine(cm->file.machine);
    out->abi    = III_LABI_COFF_X86;
    out->os     = III_LOS_WINDOWS;
    out->image_size = n;
    iii_sha256(b, n, out->sha256);
    /* Per spec §5.3: COFF flagged compromise.medium by default. */
    out->compromise = III_LCT_MEDIUM;
    return III_LS_OK;
}
