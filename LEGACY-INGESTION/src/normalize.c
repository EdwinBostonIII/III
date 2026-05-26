/* III LEGACY-INGESTION — cross-format normalization to a canonical IR. */
#include "iii/legacy.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void copy_name(char *dst, size_t cap, const char *src) {
    size_t i = 0;
    while (i + 1 < cap && src[i] != 0) { dst[i] = src[i]; i++; }
    dst[i] = 0;
}
static void copy_two(char *dst, size_t cap, const char *a, const char *b) {
    size_t i = 0;
    while (i + 1 < cap && a[i] != 0) { dst[i] = a[i]; i++; }
    if (i + 1 < cap) dst[i++] = ',';
    size_t j = 0;
    while (i + 1 < cap && b[j] != 0) { dst[i++] = b[j++]; }
    dst[i] = 0;
}

static uint32_t flags_from_pe(uint32_t c) {
    uint32_t f = 0;
    if (c & III_PE_SCN_MEM_READ)    f |= III_CANON_F_READ;
    if (c & III_PE_SCN_MEM_WRITE)   f |= III_CANON_F_WRITE;
    if (c & III_PE_SCN_MEM_EXECUTE) f |= III_CANON_F_EXEC;
    if (c & III_PE_SCN_CNT_UNINITIALIZED_DATA) f |= III_CANON_F_BSS;
    return f;
}

static uint32_t flags_from_elf(uint64_t f, uint32_t type) {
    uint32_t r = III_CANON_F_READ;
    if (f & III_SHF_WRITE)     r |= III_CANON_F_WRITE;
    if (f & III_SHF_EXECINSTR) r |= III_CANON_F_EXEC;
    if (f & III_SHF_TLS)       r |= III_CANON_F_TLS;
    if (type == III_SHT_NOBITS) r |= III_CANON_F_BSS;
    return r;
}

static uint32_t flags_from_macho(uint32_t initprot) {
    /* VM_PROT bits: READ=1, WRITE=2, EXEC=4 (Mach defines) */
    uint32_t r = 0;
    if (initprot & 0x1) r |= III_CANON_F_READ;
    if (initprot & 0x2) r |= III_CANON_F_WRITE;
    if (initprot & 0x4) r |= III_CANON_F_EXEC;
    return r;
}

iii_legacy_status_t iii_legacy_normalize(const iii_legacy_module_t *m,
                                         iii_legacy_canonical_t *out) {
    memset(out, 0, sizeof(*out));
    out->format = m->format;
    out->arch   = m->arch;
    out->os     = m->os;

    switch (m->format) {
        case III_LF_ELF: {
            const iii_elf_module_t *e = &m->u.elf;
            out->entry_vaddr  = e->entry;
            out->section_count = e->section_count;
            out->symbol_count  = e->symbol_count;
            if (e->section_count) {
                out->sections = calloc(e->section_count, sizeof(*out->sections));
                if (!out->sections) return III_LS_NO_MEMORY;
                for (uint32_t i = 0; i < e->section_count; i++) {
                    iii_legacy_canon_section_t *cs = &out->sections[i];
                    copy_name(cs->name, sizeof(cs->name), e->sections[i].name);
                    cs->vaddr   = e->sections[i].addr;
                    cs->vsize   = e->sections[i].size;
                    cs->foffset = e->sections[i].offset;
                    cs->fsize   = e->sections[i].size;
                    cs->flags   = (e->sections[i].flags & III_SHF_ALLOC)
                                  ? flags_from_elf(e->sections[i].flags, e->sections[i].type)
                                  : 0;
                }
            }
            break;
        }
        case III_LF_PE: {
            const iii_pe_module_t *p = &m->u.pe;
            out->entry_vaddr  = p->entry_point;
            out->section_count = p->section_count;
            if (p->section_count) {
                out->sections = calloc(p->section_count, sizeof(*out->sections));
                if (!out->sections) return III_LS_NO_MEMORY;
                for (uint16_t i = 0; i < p->section_count; i++) {
                    iii_legacy_canon_section_t *cs = &out->sections[i];
                    copy_name(cs->name, sizeof(cs->name), p->sections[i].name);
                    cs->vaddr   = p->image_base + p->sections[i].virtual_address;
                    cs->vsize   = p->sections[i].virtual_size;
                    cs->foffset = p->sections[i].pointer_to_raw_data;
                    cs->fsize   = p->sections[i].size_of_raw_data;
                    cs->flags   = flags_from_pe(p->sections[i].characteristics);
                }
            }
            break;
        }
        case III_LF_MACHO:
        case III_LF_MACHO_FAT: {
            const iii_macho_module_t *mh = &m->u.macho;
            out->entry_vaddr   = mh->entry_offset; /* file-offset based */
            out->section_count = mh->section_count;
            out->symbol_count  = mh->symbol_count;
            if (mh->section_count) {
                out->sections = calloc(mh->section_count, sizeof(*out->sections));
                if (!out->sections) return III_LS_NO_MEMORY;
                for (uint32_t i = 0; i < mh->section_count; i++) {
                    iii_legacy_canon_section_t *cs = &out->sections[i];
                    /* "segname,sectname" canonical name */
                    copy_two(cs->name, sizeof(cs->name),
                             mh->sections[i].segname, mh->sections[i].sectname);
                    cs->vaddr   = mh->sections[i].addr;
                    cs->vsize   = mh->sections[i].size;
                    cs->foffset = mh->sections[i].offset;
                    cs->fsize   = mh->sections[i].size;
                    /* Find owning segment for protection */
                    uint32_t fl = III_CANON_F_READ;
                    for (uint32_t j = 0; j < mh->segment_count; j++) {
                        const iii_macho_segment_info_t *sg = &mh->segments[j];
                        if (i >= sg->section_first && i < sg->section_first + sg->nsects) {
                            fl = flags_from_macho(sg->initprot);
                            break;
                        }
                    }
                    cs->flags = fl;
                }
            }
            break;
        }
        case III_LF_COFF: {
            const iii_coff_module_t *c = &m->u.coff;
            out->entry_vaddr   = 0;
            out->section_count = c->section_count;
            out->symbol_count  = c->symbol_count;
            if (c->section_count) {
                out->sections = calloc(c->section_count, sizeof(*out->sections));
                if (!out->sections) return III_LS_NO_MEMORY;
                for (uint16_t i = 0; i < c->section_count; i++) {
                    iii_legacy_canon_section_t *cs = &out->sections[i];
                    copy_name(cs->name, sizeof(cs->name), c->sections[i].name);
                    cs->foffset = c->sections[i].pointer_to_raw_data;
                    cs->fsize   = c->sections[i].size_of_raw_data;
                    cs->flags   = flags_from_pe(c->sections[i].characteristics);
                }
            }
            break;
        }
        default:
            return III_LS_UNSUPPORTED;
    }
    return III_LS_OK;
}

void iii_legacy_canonical_free(iii_legacy_canonical_t *c) {
    if (!c) return;
    free(c->sections);
    memset(c, 0, sizeof(*c));
}
