/* III LEGACY-INGESTION — PE / PE32+ parser (NIH).
 * Per Microsoft PE/COFF Specification v8.3+. */
#include "iii/legacy.h"
#include "internal.h"
#include "iii/sha256.h"
#include <stdlib.h>
#include <string.h>

static iii_legacy_arch_t map_pe_machine(uint16_t m) {
    switch (m) {
        case III_PE_MACHINE_I386:  return III_LA_X86;
        case III_PE_MACHINE_AMD64: return III_LA_X86_64;
        case III_PE_MACHINE_ARM:   return III_LA_ARM;
        case III_PE_MACHINE_ARM64: return III_LA_ARM64;
        default: return III_LA_UNKNOWN;
    }
}

iii_legacy_status_t iii_legacy_parse_pe(const uint8_t *b, size_t n,
                                        iii_legacy_module_t *out) {
    memset(out, 0, sizeof(*out));
    iii_pe_module_t *pm = &out->u.pe;

    if (n < 64) return III_LS_TRUNCATED;
    if (b[0] != 'M' || b[1] != 'Z') return III_LS_BAD_MAGIC;
    /* DOS header — only e_lfanew matters */
    pm->dos.e_magic = 0x5A4D;
    uint32_t lfa;
    iii_le_read_u32(b, n, 60, &lfa);
    pm->dos.e_lfanew = lfa;
    if (lfa + 4 + sizeof(iii_pe_file_header_t) > n) return III_LS_TRUNCATED;
    uint32_t sig;
    iii_le_read_u32(b, n, lfa, &sig);
    if (sig != III_PE_NT_MAGIC) return III_LS_BAD_MAGIC;
    pm->nt_signature = sig;

    /* COFF file header at lfa+4 */
    size_t fhoff = lfa + 4;
    iii_le_read_u16(b, n, fhoff + 0,  &pm->file.machine);
    iii_le_read_u16(b, n, fhoff + 2,  &pm->file.number_of_sections);
    iii_le_read_u32(b, n, fhoff + 4,  &pm->file.time_date_stamp);
    iii_le_read_u32(b, n, fhoff + 8,  &pm->file.pointer_to_symbol_table);
    iii_le_read_u32(b, n, fhoff + 12, &pm->file.number_of_symbols);
    iii_le_read_u16(b, n, fhoff + 16, &pm->file.size_of_optional_header);
    iii_le_read_u16(b, n, fhoff + 18, &pm->file.characteristics);

    /* Optional header */
    size_t ohoff = fhoff + 20;
    if (pm->file.size_of_optional_header == 0) return III_LS_BAD_FIELD;
    if (ohoff + pm->file.size_of_optional_header > n) return III_LS_TRUNCATED;
    uint16_t magic;
    iii_le_read_u16(b, n, ohoff, &magic);

    uint32_t entry_rva = 0;
    uint32_t num_dirs = 0;
    size_t   dirs_off = 0;
    if (magic == III_PE_OPT_MAGIC_PE32PLUS) {
        pm->is_pe32_plus = 1;
        iii_le_read_u16(b, n, ohoff + 0,  &pm->opt64.magic);
        iii_le_read_u32(b, n, ohoff + 4,  &pm->opt64.size_of_code);
        iii_le_read_u32(b, n, ohoff + 16, &entry_rva);
        pm->opt64.address_of_entry_point = entry_rva;
        iii_le_read_u64(b, n, ohoff + 24, &pm->opt64.image_base);
        iii_le_read_u32(b, n, ohoff + 56, &pm->opt64.size_of_image);
        iii_le_read_u32(b, n, ohoff + 60, &pm->opt64.size_of_headers);
        iii_le_read_u16(b, n, ohoff + 68, &pm->opt64.subsystem);
        iii_le_read_u16(b, n, ohoff + 70, &pm->opt64.dll_characteristics);
        iii_le_read_u32(b, n, ohoff + 108, &num_dirs);
        pm->opt64.number_of_rva_and_sizes = num_dirs;
        dirs_off = ohoff + 112;
        pm->image_base  = pm->opt64.image_base;
        out->arch = map_pe_machine(pm->file.machine);
        out->abi  = III_LABI_WINDOWS_X64;
    } else if (magic == III_PE_OPT_MAGIC_PE32) {
        pm->is_pe32_plus = 0;
        iii_le_read_u16(b, n, ohoff + 0,  &pm->opt32.magic);
        iii_le_read_u32(b, n, ohoff + 4,  &pm->opt32.size_of_code);
        iii_le_read_u32(b, n, ohoff + 16, &entry_rva);
        pm->opt32.address_of_entry_point = entry_rva;
        iii_le_read_u32(b, n, ohoff + 28, &pm->opt32.image_base);
        iii_le_read_u32(b, n, ohoff + 56, &pm->opt32.size_of_image);
        iii_le_read_u32(b, n, ohoff + 60, &pm->opt32.size_of_headers);
        iii_le_read_u16(b, n, ohoff + 68, &pm->opt32.subsystem);
        iii_le_read_u16(b, n, ohoff + 70, &pm->opt32.dll_characteristics);
        iii_le_read_u32(b, n, ohoff + 92, &num_dirs);
        pm->opt32.number_of_rva_and_sizes = num_dirs;
        dirs_off = ohoff + 96;
        pm->image_base = pm->opt32.image_base;
        out->arch = map_pe_machine(pm->file.machine);
        out->abi  = III_LABI_WINDOWS_X86;
    } else {
        return III_LS_UNSUPPORTED;
    }
    pm->entry_point = pm->image_base + entry_rva;

    /* Data directories */
    if (num_dirs > III_PE_NUM_DIRECTORY_ENTRIES) num_dirs = III_PE_NUM_DIRECTORY_ENTRIES;
    if (dirs_off + (size_t)num_dirs * 8 > n) return III_LS_BAD_OFFSET;
    for (uint32_t i = 0; i < num_dirs; i++) {
        uint32_t va, sz;
        iii_le_read_u32(b, n, dirs_off + i * 8, &va);
        iii_le_read_u32(b, n, dirs_off + i * 8 + 4, &sz);
        if (pm->is_pe32_plus) {
            pm->opt64.data_directory[i].virtual_address = va;
            pm->opt64.data_directory[i].size = sz;
        } else {
            pm->opt32.data_directory[i].virtual_address = va;
            pm->opt32.data_directory[i].size = sz;
        }
        if (i == III_PE_DIR_SECURITY && sz != 0) pm->has_authenticode = 1;
        if (i == III_PE_DIR_TLS && sz != 0)      pm->has_tls_callbacks = 1;
        if (i == III_PE_DIR_DEBUG && sz != 0)    pm->has_debug = 1;
    }

    /* Section headers */
    size_t sec_off = ohoff + pm->file.size_of_optional_header;
    pm->section_count = pm->file.number_of_sections;
    if (pm->section_count) {
        if (sec_off + (size_t)pm->section_count * 40 > n) return III_LS_BAD_OFFSET;
        pm->sections = calloc(pm->section_count, sizeof(*pm->sections));
        if (!pm->sections) return III_LS_NO_MEMORY;
        for (uint16_t i = 0; i < pm->section_count; i++) {
            size_t o = sec_off + (size_t)i * 40;
            iii_pe_section_info_t *sec = &pm->sections[i];
            for (int k = 0; k < 8; k++) sec->name[k] = (char)b[o + k];
            sec->name[8] = 0;
            iii_le_read_u32(b, n, o + 8,  &sec->virtual_size);
            iii_le_read_u32(b, n, o + 12, &sec->virtual_address);
            iii_le_read_u32(b, n, o + 16, &sec->size_of_raw_data);
            iii_le_read_u32(b, n, o + 20, &sec->pointer_to_raw_data);
            iii_le_read_u32(b, n, o + 36, &sec->characteristics);
        }
    }

    out->format = III_LF_PE;
    out->os     = III_LOS_WINDOWS;
    out->image_size = n;
    iii_sha256(b, n, out->sha256);

    out->compromise = III_LCT_NONE;
    if (!pm->has_authenticode) out->compromise = III_LCT_MEDIUM;
    if (pm->has_tls_callbacks && out->compromise < III_LCT_MEDIUM)
        out->compromise = III_LCT_MEDIUM;
    return III_LS_OK;
}
