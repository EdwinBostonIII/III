/* III LEGACY-INGESTION — Mach-O parser (NIH).
 * Single-arch 64-bit + Fat (universal) detection, per Apple Mach-O Reference. */
#include "iii/legacy.h"
#include "internal.h"
#include "iii/sha256.h"
#include <stdlib.h>
#include <string.h>

static iii_legacy_arch_t map_macho_cpu(uint32_t cpu) {
    switch (cpu) {
        case III_MACHO_CPU_X86:    return III_LA_X86;
        case III_MACHO_CPU_X86_64: return III_LA_X86_64;
        case III_MACHO_CPU_ARM:    return III_LA_ARM;
        case III_MACHO_CPU_ARM64:  return III_LA_ARM64;
        case III_MACHO_CPU_POWERPC:
        case III_MACHO_CPU_POWERPC64: return III_LA_POWERPC;
        default: return III_LA_UNKNOWN;
    }
}

static iii_legacy_status_t parse_macho_thin(const uint8_t *b, size_t n,
                                            size_t base, size_t avail,
                                            iii_legacy_module_t *out) {
    iii_macho_module_t *mm = &out->u.macho;
    if (avail < sizeof(iii_macho_header64_t)) return III_LS_TRUNCATED;
    uint32_t magic;
    iii_le_read_u32(b, n, base, &magic);
    if (magic != III_MACHO_MAGIC64 && magic != III_MACHO_MAGIC32)
        return III_LS_BAD_MAGIC;
    int is64 = (magic == III_MACHO_MAGIC64);
    mm->is_64 = is64;
    mm->hdr.magic = magic;
    iii_le_read_u32(b, n, base + 4,  &mm->hdr.cputype);
    iii_le_read_u32(b, n, base + 8,  &mm->hdr.cpusubtype);
    iii_le_read_u32(b, n, base + 12, &mm->hdr.filetype);
    iii_le_read_u32(b, n, base + 16, &mm->hdr.ncmds);
    iii_le_read_u32(b, n, base + 20, &mm->hdr.sizeofcmds);
    iii_le_read_u32(b, n, base + 24, &mm->hdr.flags);
    if (is64) iii_le_read_u32(b, n, base + 28, &mm->hdr.reserved);

    size_t lc_off = base + (is64 ? 32 : 28);
    if (lc_off + mm->hdr.sizeofcmds > base + avail) return III_LS_BAD_OFFSET;

    /* Pre-count segments + sections to allocate */
    size_t cur = lc_off;
    uint32_t nseg = 0, nsec_total = 0;
    for (uint32_t i = 0; i < mm->hdr.ncmds; i++) {
        if (cur + 8 > base + avail) return III_LS_BAD_OFFSET;
        uint32_t cmd, cmdsize;
        iii_le_read_u32(b, n, cur + 0, &cmd);
        iii_le_read_u32(b, n, cur + 4, &cmdsize);
        if (cmdsize < 8 || cur + cmdsize > base + avail) return III_LS_BAD_FIELD;
        if (cmd == III_MACHO_LC_SEGMENT_64 && cmdsize >= sizeof(iii_macho_segment_command_64_t)) {
            nseg++;
            uint32_t nsects;
            iii_le_read_u32(b, n, cur + 64, &nsects);
            nsec_total += nsects;
        }
        cur += cmdsize;
    }
    if (nseg) {
        mm->segments = calloc(nseg, sizeof(*mm->segments));
        if (!mm->segments) return III_LS_NO_MEMORY;
    }
    if (nsec_total) {
        mm->sections = calloc(nsec_total, sizeof(*mm->sections));
        if (!mm->sections) return III_LS_NO_MEMORY;
    }

    /* Walk again, populate */
    cur = lc_off;
    uint32_t segi = 0, seci = 0;
    for (uint32_t i = 0; i < mm->hdr.ncmds; i++) {
        uint32_t cmd, cmdsize;
        iii_le_read_u32(b, n, cur + 0, &cmd);
        iii_le_read_u32(b, n, cur + 4, &cmdsize);
        if (cmd == III_MACHO_LC_SEGMENT_64) {
            iii_macho_segment_info_t *seg = &mm->segments[segi++];
            iii_copy_fixed(seg->segname, sizeof(seg->segname), (const char*)(b + cur + 8), 16);
            iii_le_read_u64(b, n, cur + 24, &seg->vmaddr);
            iii_le_read_u64(b, n, cur + 32, &seg->vmsize);
            iii_le_read_u64(b, n, cur + 40, &seg->fileoff);
            iii_le_read_u64(b, n, cur + 48, &seg->filesize);
            iii_le_read_u32(b, n, cur + 56, &seg->maxprot);
            iii_le_read_u32(b, n, cur + 60, &seg->initprot);
            iii_le_read_u32(b, n, cur + 64, &seg->nsects);
            seg->section_first = seci;
            size_t soff = cur + 72;
            for (uint32_t k = 0; k < seg->nsects; k++) {
                if (seci >= nsec_total) break;
                iii_macho_section_info_t *sec = &mm->sections[seci++];
                iii_copy_fixed(sec->sectname, sizeof(sec->sectname), (const char*)(b + soff + 0), 16);
                iii_copy_fixed(sec->segname,  sizeof(sec->segname),  (const char*)(b + soff + 16), 16);
                iii_le_read_u64(b, n, soff + 32, &sec->addr);
                iii_le_read_u64(b, n, soff + 40, &sec->size);
                iii_le_read_u32(b, n, soff + 48, &sec->offset);
                iii_le_read_u32(b, n, soff + 64, &sec->flags);
                soff += 80;
            }
        } else if (cmd == III_MACHO_LC_SYMTAB) {
            uint32_t nsyms;
            iii_le_read_u32(b, n, cur + 12, &nsyms);
            mm->symbol_count += nsyms;
        } else if (cmd == III_MACHO_LC_MAIN) {
            iii_le_read_u64(b, n, cur + 8, &mm->entry_offset);
        } else if (cmd == III_MACHO_LC_CODE_SIGNATURE) {
            mm->has_code_signature = 1;
        }
        cur += cmdsize;
    }
    mm->segment_count = segi;
    mm->section_count = seci;
    mm->lc_count = mm->hdr.ncmds;

    out->format = III_LF_MACHO;
    out->arch   = map_macho_cpu(mm->hdr.cputype);
    out->os     = III_LOS_MACOS;
    out->abi    = (out->arch == III_LA_ARM64) ? III_LABI_MACHO_ARM64 : III_LABI_MACHO_X64;
    out->image_size = n;
    iii_sha256(b, n, out->sha256);
    out->compromise = mm->has_code_signature ? III_LCT_NONE : III_LCT_MEDIUM;
    return III_LS_OK;
}

iii_legacy_status_t iii_legacy_parse_macho(const uint8_t *b, size_t n,
                                           iii_legacy_module_t *out) {
    memset(out, 0, sizeof(*out));
    if (n < 8) return III_LS_TRUNCATED;
    uint32_t be_magic;
    iii_be_read_u32(b, n, 0, &be_magic);
    if (be_magic == III_MACHO_FAT_MAGIC || be_magic == III_MACHO_FAT_MAGIC_64) {
        /* Fat: parse header + first slice */
        uint32_t nfat;
        iii_be_read_u32(b, n, 4, &nfat);
        if (nfat == 0 || nfat > 32) return III_LS_BAD_FIELD;
        size_t entry_size = (be_magic == III_MACHO_FAT_MAGIC_64) ? 32 : 20;
        if (8 + (size_t)nfat * entry_size > n) return III_LS_BAD_OFFSET;
        /* Use first slice to populate primary module */
        uint32_t cputype, off32;
        iii_be_read_u32(b, n, 8, &cputype);
        iii_be_read_u32(b, n, 8 + 8, &off32);  /* offset is field 3 in arch */
        uint32_t size32;
        iii_be_read_u32(b, n, 8 + 12, &size32);
        if ((size_t)off32 + size32 > n) return III_LS_BAD_OFFSET;
        iii_legacy_status_t s = parse_macho_thin(b, n, off32, size32, out);
        if (s != III_LS_OK) return s;
        out->format = III_LF_MACHO_FAT;
        out->u.macho.is_fat = 1;
        out->u.macho.fat_count = nfat;
        out->arch = map_macho_cpu(cputype);  /* reflect first slice */
        return III_LS_OK;
    }
    return parse_macho_thin(b, n, 0, n, out);
}
